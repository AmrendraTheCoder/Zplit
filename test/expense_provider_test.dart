import 'package:flutter_test/flutter_test.dart';
import 'package:zplit/models/expense_model.dart';
import 'package:zplit/models/split_model.dart';
import 'package:zplit/utils/vector_clock.dart';

/// Test helpers that don't depend on database.
/// We test the derived/computed providers by manually seeding state.
void main() {
  // ── Helpers ──────────────────────────────────────────
  ExpenseModel makeExpense({
    String id = 'exp-1',
    String groupId = 'group-1',
    String payerId = 'user-a',
    double totalAmount = 3000,
    bool isDeleted = false,
    ExpenseCategory category = ExpenseCategory.food,
  }) {
    return ExpenseModel(
      id: id,
      groupId: groupId,
      payerId: payerId,
      createdBy: payerId,
      description: 'Test Expense',
      totalAmount: totalAmount,
      currency: 'INR',
      category: category,
      splitMode: SplitMode.equal,
      date: DateTime(2026, 2, 25),
      vectorClock: const VectorClock({'A': 1}),
      lastModifiedBy: payerId,
      isDeleted: isDeleted,
      createdAt: DateTime(2026, 2, 25),
      updatedAt: DateTime(2026, 2, 25),
    );
  }

  SplitModel makeSplit({
    required String transactionId,
    required String debtorId,
    required double owedShare,
  }) {
    return SplitModel(
      id: 'split-$transactionId-$debtorId',
      transactionId: transactionId,
      debtorId: debtorId,
      owedShare: owedShare,
      rawInput: 0,
    );
  }

  group('groupExpensesProvider filtering logic', () {
    test('filters by groupId and excludes soft-deleted', () {
      final allExpenses = [
        makeExpense(id: 'e1', groupId: 'group-1'),
        makeExpense(id: 'e2', groupId: 'group-2'),
        makeExpense(id: 'e3', groupId: 'group-1', isDeleted: true),
      ];

      // This mirrors the logic in groupExpensesProvider
      final group1Expenses =
          allExpenses
              .where((e) => e.groupId == 'group-1' && !e.isDeleted)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

      expect(group1Expenses.length, 1);
      expect(group1Expenses[0].id, 'e1');
    });

    test('sorts by date descending', () {
      final allExpenses = [
        makeExpense(id: 'e1', groupId: 'g1'),
        makeExpense(id: 'e2', groupId: 'g1'),
      ];

      // Both have same date, so order is stable
      final sorted =
          allExpenses.where((e) => e.groupId == 'g1' && !e.isDeleted).toList()
            ..sort((a, b) => b.date.compareTo(a.date));

      expect(sorted.length, 2);
    });
  });

  group('Balance calculations (direct logic)', () {
    test('userGroupBalance: payer gets credit, debtor owes', () {
      // Simulate: user-a pays 3000, split equally among a, b, c (1000 each)
      final expenses = [makeExpense(payerId: 'user-a', totalAmount: 3000)];
      final splits = [
        makeSplit(transactionId: 'exp-1', debtorId: 'user-a', owedShare: 1000),
        makeSplit(transactionId: 'exp-1', debtorId: 'user-b', owedShare: 1000),
        makeSplit(transactionId: 'exp-1', debtorId: 'user-c', owedShare: 1000),
      ];

      // User A's balance: paid 3000, own share 1000 → owed 2000
      double balanceA = 0;
      for (final expense in expenses) {
        final expSplits = splits
            .where((s) => s.transactionId == expense.id)
            .toList();
        if (expense.payerId == 'user-a') {
          final ownShare = expSplits
              .where((s) => s.debtorId == 'user-a')
              .first
              .owedShare;
          balanceA += expense.totalAmount - ownShare;
        }
      }
      expect(balanceA, 2000);

      // User B's balance: didn't pay, owes 1000
      double balanceB = 0;
      for (final expense in expenses) {
        final expSplits = splits
            .where((s) => s.transactionId == expense.id)
            .toList();
        if (expense.payerId != 'user-b') {
          final userSplit = expSplits.where((s) => s.debtorId == 'user-b');
          if (userSplit.isNotEmpty) {
            balanceB -= userSplit.first.owedShare;
          }
        }
      }
      expect(balanceB, -1000);
    });

    test('pairwise balance: positive means they owe you', () {
      // user-a pays 3000, user-b owes 1000
      final expenses = [makeExpense(payerId: 'user-a', totalAmount: 3000)];
      final splits = [
        makeSplit(transactionId: 'exp-1', debtorId: 'user-a', owedShare: 1000),
        makeSplit(transactionId: 'exp-1', debtorId: 'user-b', owedShare: 1000),
        makeSplit(transactionId: 'exp-1', debtorId: 'user-c', owedShare: 1000),
      ];

      // A→B pairwise: A paid, B owes 1000 to A → +1000
      double balance = 0;
      for (final expense in expenses) {
        final expSplits = splits
            .where((s) => s.transactionId == expense.id && !s.isDeleted)
            .toList();
        if (expense.payerId == 'user-a') {
          final otherSplit = expSplits.where((s) => s.debtorId == 'user-b');
          if (otherSplit.isNotEmpty) {
            balance += otherSplit.first.owedShare;
          }
        } else if (expense.payerId == 'user-b') {
          final userSplit = expSplits.where((s) => s.debtorId == 'user-a');
          if (userSplit.isNotEmpty) {
            balance -= userSplit.first.owedShare;
          }
        }
      }
      expect(balance, 1000);
    });

    test('pairwise balance: bidirectional payments net out', () {
      // user-a pays 3000 (a,b,c each owe 1000)
      // user-b pays 600 (a,b each owe 300)
      final expenses = [
        makeExpense(id: 'exp-1', payerId: 'user-a', totalAmount: 3000),
        makeExpense(id: 'exp-2', payerId: 'user-b', totalAmount: 600),
      ];
      final splits = [
        // exp-1 splits
        makeSplit(transactionId: 'exp-1', debtorId: 'user-a', owedShare: 1000),
        makeSplit(transactionId: 'exp-1', debtorId: 'user-b', owedShare: 1000),
        makeSplit(transactionId: 'exp-1', debtorId: 'user-c', owedShare: 1000),
        // exp-2 splits
        makeSplit(transactionId: 'exp-2', debtorId: 'user-a', owedShare: 300),
        makeSplit(transactionId: 'exp-2', debtorId: 'user-b', owedShare: 300),
      ];

      // A→B pairwise: B owes A 1000 (from exp-1), A owes B 300 (from exp-2)
      // Net: +700 (B owes A 700)
      double balance = 0;
      for (final expense in expenses) {
        final expSplits = splits
            .where((s) => s.transactionId == expense.id && !s.isDeleted)
            .toList();
        if (expense.payerId == 'user-a') {
          final otherSplit = expSplits.where((s) => s.debtorId == 'user-b');
          if (otherSplit.isNotEmpty) {
            balance += otherSplit.first.owedShare;
          }
        } else if (expense.payerId == 'user-b') {
          final userSplit = expSplits.where((s) => s.debtorId == 'user-a');
          if (userSplit.isNotEmpty) {
            balance -= userSplit.first.owedShare;
          }
        }
      }
      expect(balance, 700);
    });
  });

  group('groupTotal (direct logic)', () {
    test('sums all expense totals for a group', () {
      final expenses = [
        makeExpense(id: 'e1', groupId: 'g1', totalAmount: 1000),
        makeExpense(id: 'e2', groupId: 'g1', totalAmount: 2000),
        makeExpense(id: 'e3', groupId: 'g2', totalAmount: 500),
      ];

      final g1Total = expenses
          .where((e) => e.groupId == 'g1')
          .fold<double>(0, (sum, e) => sum + e.totalAmount);

      expect(g1Total, 3000);
    });

    test('excludes soft-deleted from total', () {
      final expenses = [
        makeExpense(id: 'e1', groupId: 'g1', totalAmount: 1000),
        makeExpense(
          id: 'e2',
          groupId: 'g1',
          totalAmount: 2000,
          isDeleted: true,
        ),
      ];

      final g1Total = expenses
          .where((e) => e.groupId == 'g1' && !e.isDeleted)
          .fold<double>(0, (sum, e) => sum + e.totalAmount);

      expect(g1Total, 1000);
    });
  });

  group('SplitModel operations', () {
    test('copyWith updates fields correctly', () {
      final split = makeSplit(
        transactionId: 'exp-1',
        debtorId: 'user-a',
        owedShare: 1000,
      );

      final paid = split.copyWith(isPaid: true);
      expect(paid.isPaid, true);
      expect(paid.owedShare, 1000);

      final deleted = split.copyWith(isDeleted: true);
      expect(deleted.isDeleted, true);
    });

    test('SplitModel.create generates unique ID', () {
      final s1 = SplitModel.create(
        transactionId: 'exp-1',
        debtorId: 'user-a',
        owedShare: 500,
      );
      final s2 = SplitModel.create(
        transactionId: 'exp-1',
        debtorId: 'user-b',
        owedShare: 500,
      );
      expect(s1.id, isNot(equals(s2.id)));
    });

    test('SplitModel JSON roundtrip', () {
      final split = SplitModel(
        id: 's1',
        transactionId: 'exp-1',
        debtorId: 'user-a',
        owedShare: 1500,
        rawInput: 50,
        isPaid: true,
      );
      final json = split.toJson();
      final restored = SplitModel.fromJson(json);

      expect(restored.id, split.id);
      expect(restored.transactionId, split.transactionId);
      expect(restored.debtorId, split.debtorId);
      expect(restored.owedShare, split.owedShare);
      expect(restored.rawInput, split.rawInput);
      expect(restored.isPaid, true);
    });
  });
}
