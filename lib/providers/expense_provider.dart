import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../models/split_model.dart';

/// Provider for all expenses across all groups.
final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, List<ExpenseModel>>((ref) {
  return ExpensesNotifier();
});

/// Provider for all splits across all expenses.
final splitsProvider =
    StateNotifierProvider<SplitsNotifier, List<SplitModel>>((ref) {
  return SplitsNotifier();
});

/// Derived provider: expenses for a specific group.
/// Filters out soft-deleted expenses (Image 3: is_deleted).
final groupExpensesProvider =
    Provider.family<List<ExpenseModel>, String>((ref, groupId) {
  final expenses = ref.watch(expensesProvider);
  return expenses
      .where((e) => e.groupId == groupId && !e.isDeleted)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date)); // newest first
});

/// Derived provider: splits for a specific expense.
/// Uses transactionId to match (Image 4: transaction_id FK).
final expenseSplitsProvider =
    Provider.family<List<SplitModel>, String>((ref, transactionId) {
  final splits = ref.watch(splitsProvider);
  return splits
      .where((s) => s.transactionId == transactionId && !s.isDeleted)
      .toList();
});

/// Derived provider: total balance for a user in a group.
/// Positive = they are owed money. Negative = they owe money.
///
/// Uses the renamed fields:
/// - expense.payerId (was paidBy)
/// - split.debtorId (was userId)
/// - split.transactionId (was expenseId)
final userGroupBalanceProvider =
    Provider.family<double, ({String userId, String groupId})>((ref, params) {
  final expenses = ref.watch(groupExpensesProvider(params.groupId));
  final allSplits = ref.watch(splitsProvider);

  double balance = 0;

  for (final expense in expenses) {
    final splits =
        allSplits.where((s) => s.transactionId == expense.id).toList();

    if (expense.payerId == params.userId) {
      // This user paid — they are owed the total minus their own share
      final userSplit = splits.where((s) => s.debtorId == params.userId);
      final ownShare =
          userSplit.isNotEmpty ? userSplit.first.owedShare : 0.0;
      balance += expense.totalAmount - ownShare;
    } else {
      // This user didn't pay — they owe their share
      final userSplit = splits.where((s) => s.debtorId == params.userId);
      if (userSplit.isNotEmpty) {
        balance -= userSplit.first.owedShare;
      }
    }
  }

  return double.parse(balance.toStringAsFixed(2));
});

/// Derived provider: total group spending.
final groupTotalProvider = Provider.family<double, String>((ref, groupId) {
  final expenses = ref.watch(groupExpensesProvider(groupId));
  return expenses.fold<double>(0, (sum, e) => sum + e.totalAmount);
});

class ExpensesNotifier extends StateNotifier<List<ExpenseModel>> {
  ExpensesNotifier() : super([]);

  /// Adds a new expense.
  void addExpense(ExpenseModel expense) {
    state = [...state, expense];
  }

  /// Updates an expense (with vector clock tick).
  void updateExpense(ExpenseModel expense) {
    state = [
      for (final e in state)
        if (e.id == expense.id) expense else e,
    ];
  }

  /// Soft-deletes an expense (Image 3: is_deleted flag).
  void softDeleteExpense(String expenseId, String deviceId, String modifiedBy) {
    state = [
      for (final e in state)
        if (e.id == expenseId) e.softDelete(deviceId, modifiedBy) else e,
    ];
  }

  /// Gets an expense by ID, or null.
  ExpenseModel? getExpenseById(String id) {
    try {
      return state.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

class SplitsNotifier extends StateNotifier<List<SplitModel>> {
  SplitsNotifier() : super([]);

  /// Adds splits for a new expense.
  void addSplits(List<SplitModel> splits) {
    state = [...state, ...splits];
  }

  /// Replaces all splits for a given transaction.
  void replaceSplitsForTransaction(
      String transactionId, List<SplitModel> newSplits) {
    state = [
      ...state.where((s) => s.transactionId != transactionId),
      ...newSplits,
    ];
  }

  /// Soft-deletes all splits for a transaction.
  void softDeleteSplitsForTransaction(String transactionId) {
    state = [
      for (final s in state)
        if (s.transactionId == transactionId)
          s.copyWith(isDeleted: true)
        else
          s,
    ];
  }

  /// Marks a split as paid.
  void markPaid(String splitId) {
    state = [
      for (final s in state)
        if (s.id == splitId) s.copyWith(isPaid: true) else s,
    ];
  }
}
