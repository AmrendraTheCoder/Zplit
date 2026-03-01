import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_filter.dart';
import '../models/expense_model.dart';
import 'expense_provider.dart';

/// Filter state per group.
/// Key: groupId, Value: ExpenseFilter
final expenseFilterProvider = StateProvider.family<ExpenseFilter, String>((
  ref,
  groupId,
) {
  return const ExpenseFilter();
});

/// Filtered + sorted expenses for a group.
/// Applies the filter from expenseFilterProvider on top of groupExpensesProvider.
final filteredGroupExpensesProvider =
    Provider.family<List<ExpenseModel>, String>((ref, groupId) {
      final filter = ref.watch(expenseFilterProvider(groupId));
      var expenses = ref.watch(groupExpensesProvider(groupId)).toList();

      // Category filter
      if (filter.categoryFilter != null) {
        expenses = expenses
            .where((e) => e.category == filter.categoryFilter)
            .toList();
      }

      // Payer filter
      if (filter.payerFilter != null) {
        expenses = expenses
            .where((e) => e.payerId == filter.payerFilter)
            .toList();
      }

      // Search query
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        expenses = expenses
            .where((e) => e.description.toLowerCase().contains(query))
            .toList();
      }

      // Sort
      expenses.sort((a, b) {
        int cmp;
        switch (filter.sortBy) {
          case ExpenseSortField.date:
            cmp = a.date.compareTo(b.date);
          case ExpenseSortField.amount:
            cmp = a.totalAmount.compareTo(b.totalAmount);
          case ExpenseSortField.category:
            cmp = a.category.name.compareTo(b.category.name);
        }
        return filter.sortOrder == SortOrder.descending ? -cmp : cmp;
      });

      return expenses;
    });
