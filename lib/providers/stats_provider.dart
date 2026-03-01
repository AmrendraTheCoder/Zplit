import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import 'expense_provider.dart';

/// Category breakdown: total spending per category in a group.
final categoryBreakdownProvider =
    Provider.family<Map<ExpenseCategory, double>, String>((ref, groupId) {
      final expenses = ref.watch(groupExpensesProvider(groupId));
      final Map<ExpenseCategory, double> breakdown = {};
      for (final expense in expenses) {
        breakdown[expense.category] =
            (breakdown[expense.category] ?? 0) + expense.totalAmount;
      }
      return breakdown;
    });

/// Member spending: total amount paid by each member in a group.
final memberSpendingProvider = Provider.family<Map<String, double>, String>((
  ref,
  groupId,
) {
  final expenses = ref.watch(groupExpensesProvider(groupId));
  final Map<String, double> spending = {};
  for (final expense in expenses) {
    spending[expense.payerId] =
        (spending[expense.payerId] ?? 0) + expense.totalAmount;
  }
  return spending;
});

/// Spending over time: daily aggregate spending in a group.
/// Returns a sorted list of (date, amount) pairs.
final spendingOverTimeProvider =
    Provider.family<List<({DateTime date, double amount})>, String>((
      ref,
      groupId,
    ) {
      final expenses = ref.watch(groupExpensesProvider(groupId));
      final Map<DateTime, double> daily = {};
      for (final expense in expenses) {
        final day = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        );
        daily[day] = (daily[day] ?? 0) + expense.totalAmount;
      }
      final entries =
          daily.entries.map((e) => (date: e.key, amount: e.value)).toList()
            ..sort((a, b) => a.date.compareTo(b.date));
      return entries;
    });

/// Average expense amount in a group.
final averageExpenseProvider = Provider.family<double, String>((ref, groupId) {
  final expenses = ref.watch(groupExpensesProvider(groupId));
  if (expenses.isEmpty) return 0;
  final total = expenses.fold<double>(0, (sum, e) => sum + e.totalAmount);
  return total / expenses.length;
});
