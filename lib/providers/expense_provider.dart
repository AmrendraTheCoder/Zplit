import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../models/split_model.dart';
import '../providers/group_provider.dart';
import 'database_provider.dart';

/// Provider for all expenses across all groups.
final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, List<ExpenseModel>>((ref) {
  return ExpensesNotifier(ref);
});

/// Provider for all splits across all expenses.
final splitsProvider =
    StateNotifierProvider<SplitsNotifier, List<SplitModel>>((ref) {
  return SplitsNotifier(ref);
});

/// Derived provider: expenses for a specific group.
/// Filters out soft-deleted expenses (Image 3: is_deleted).
final groupExpensesProvider =
    Provider.family<List<ExpenseModel>, String>((ref, groupId) {
  final expenses = ref.watch(expensesProvider);
  return expenses
      .where((e) => e.groupId == groupId && !e.isDeleted)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
});

/// Derived provider: splits for a specific expense.
final expenseSplitsProvider =
    Provider.family<List<SplitModel>, String>((ref, transactionId) {
  final splits = ref.watch(splitsProvider);
  return splits
      .where((s) => s.transactionId == transactionId && !s.isDeleted)
      .toList();
});

/// Derived provider: total balance for a user in a group.
final userGroupBalanceProvider =
    Provider.family<double, ({String userId, String groupId})>((ref, params) {
  final expenses = ref.watch(groupExpensesProvider(params.groupId));
  final allSplits = ref.watch(splitsProvider);

  double balance = 0;

  for (final expense in expenses) {
    final splits =
        allSplits.where((s) => s.transactionId == expense.id).toList();

    if (expense.payerId == params.userId) {
      final userSplit = splits.where((s) => s.debtorId == params.userId);
      final ownShare =
          userSplit.isNotEmpty ? userSplit.first.owedShare : 0.0;
      balance += expense.totalAmount - ownShare;
    } else {
      final userSplit = splits.where((s) => s.debtorId == params.userId);
      if (userSplit.isNotEmpty) {
        balance -= userSplit.first.owedShare;
      }
    }
  }

  return double.parse(balance.toStringAsFixed(2));
});

/// Derived provider: pairwise balance between two users in a group.
///
/// Positive = [userId] is owed by [otherUserId] (they owe you).
/// Negative = [userId] owes [otherUserId] (you owe them).
final pairwiseBalanceProvider = Provider.family<double,
    ({String userId, String otherUserId, String groupId})>((ref, params) {
  final expenses = ref.watch(groupExpensesProvider(params.groupId));
  final allSplits = ref.watch(splitsProvider);

  double balance = 0;

  for (final expense in expenses) {
    final splits =
        allSplits.where((s) => s.transactionId == expense.id && !s.isDeleted).toList();

    if (expense.payerId == params.userId) {
      // User paid — otherUser owes their share to user
      final otherSplit = splits.where((s) => s.debtorId == params.otherUserId);
      if (otherSplit.isNotEmpty) {
        balance += otherSplit.first.owedShare;
      }
    } else if (expense.payerId == params.otherUserId) {
      // OtherUser paid — user owes their share to otherUser
      final userSplit = splits.where((s) => s.debtorId == params.userId);
      if (userSplit.isNotEmpty) {
        balance -= userSplit.first.owedShare;
      }
    }
  }

  return double.parse(balance.toStringAsFixed(2));
});

/// Derived provider: all pairwise balances for a user in a group.
/// Returns a Map of (memberId -> balance) for all other members.
final groupMemberBalancesProvider = Provider.family<Map<String, double>,
    ({String userId, String groupId})>((ref, params) {
  final group = ref.watch(
    Provider<List<String>>((r) {
      final groups = r.watch(groupsProvider);
      final g = groups.where((g) => g.id == params.groupId).firstOrNull;
      return g?.memberIds ?? [];
    }),
  );

  final Map<String, double> balances = {};
  for (final memberId in group) {
    if (memberId == params.userId) continue;
    balances[memberId] = ref.watch(pairwiseBalanceProvider((
      userId: params.userId,
      otherUserId: memberId,
      groupId: params.groupId,
    )));
  }
  return balances;
});

/// Derived provider: total group spending.
final groupTotalProvider = Provider.family<double, String>((ref, groupId) {
  final expenses = ref.watch(groupExpensesProvider(groupId));
  return expenses.fold<double>(0, (sum, e) => sum + e.totalAmount);
});

class ExpensesNotifier extends StateNotifier<List<ExpenseModel>> {
  final Ref _ref;
  ExpensesNotifier(this._ref) : super([]) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final dao = _ref.read(expenseDaoProvider);
    state = await dao.getAllExpenses();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    state = [...state, expense];
    await _ref.read(expenseDaoProvider).upsertExpense(expense);
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    state = [
      for (final e in state)
        if (e.id == expense.id) expense else e,
    ];
    await _ref.read(expenseDaoProvider).upsertExpense(expense);
  }

  Future<void> softDeleteExpense(
      String expenseId, String deviceId, String modifiedBy) async {
    state = [
      for (final e in state)
        if (e.id == expenseId) e.softDelete(deviceId, modifiedBy) else e,
    ];
    await _ref.read(expenseDaoProvider).softDeleteExpense(expenseId);
  }

  ExpenseModel? getExpenseById(String id) {
    try {
      return state.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

class SplitsNotifier extends StateNotifier<List<SplitModel>> {
  final Ref _ref;
  SplitsNotifier(this._ref) : super([]) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final dao = _ref.read(splitDaoProvider);
    state = await dao.getAllSplits();
  }

  Future<void> addSplits(List<SplitModel> splits) async {
    state = [...state, ...splits];
    await _ref.read(splitDaoProvider).upsertSplits(splits);
  }

  Future<void> replaceSplitsForTransaction(
      String transactionId, List<SplitModel> newSplits) async {
    state = [
      ...state.where((s) => s.transactionId != transactionId),
      ...newSplits,
    ];
    await _ref.read(splitDaoProvider).upsertSplits(newSplits);
  }

  Future<void> softDeleteSplitsForTransaction(String transactionId) async {
    state = [
      for (final s in state)
        if (s.transactionId == transactionId)
          s.copyWith(isDeleted: true)
        else
          s,
    ];
    await _ref.read(splitDaoProvider)
        .softDeleteSplitsForTransaction(transactionId);
  }

  void markPaid(String splitId) {
    state = [
      for (final s in state)
        if (s.id == splitId) s.copyWith(isPaid: true) else s,
    ];
  }
}
