import 'package:equatable/equatable.dart';
import 'expense_model.dart';

/// Sort field options for expenses.
enum ExpenseSortField {
  date,
  amount,
  category;

  String get label => name[0].toUpperCase() + name.substring(1);
}

/// Sort order.
enum SortOrder {
  ascending,
  descending;

  String get label => this == ascending ? '↑' : '↓';
}

/// Filter/sort configuration for expense lists.
class ExpenseFilter extends Equatable {
  final ExpenseSortField sortBy;
  final SortOrder sortOrder;
  final ExpenseCategory? categoryFilter;
  final String? payerFilter;
  final String searchQuery;

  const ExpenseFilter({
    this.sortBy = ExpenseSortField.date,
    this.sortOrder = SortOrder.descending,
    this.categoryFilter,
    this.payerFilter,
    this.searchQuery = '',
  });

  ExpenseFilter copyWith({
    ExpenseSortField? sortBy,
    SortOrder? sortOrder,
    ExpenseCategory? categoryFilter,
    bool clearCategory = false,
    String? payerFilter,
    bool clearPayer = false,
    String? searchQuery,
  }) {
    return ExpenseFilter(
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      categoryFilter: clearCategory
          ? null
          : (categoryFilter ?? this.categoryFilter),
      payerFilter: clearPayer ? null : (payerFilter ?? this.payerFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters =>
      categoryFilter != null || payerFilter != null || searchQuery.isNotEmpty;

  @override
  List<Object?> get props => [
    sortBy,
    sortOrder,
    categoryFilter,
    payerFilter,
    searchQuery,
  ];
}
