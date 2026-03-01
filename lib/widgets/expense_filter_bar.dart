import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_filter.dart';
import '../models/expense_model.dart';
import '../providers/expense_filter_provider.dart';
import '../theme/app_colors.dart';

/// A filter/sort bar widget with chips and sort dropdown.
class ExpenseFilterBar extends ConsumerWidget {
  final String groupId;
  const ExpenseFilterBar({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(expenseFilterProvider(groupId));
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search bar (shown when search is active or tapped)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search expenses...',
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: accent),
              suffixIcon: filter.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () =>
                          ref
                              .read(expenseFilterProvider(groupId).notifier)
                              .state = filter.copyWith(
                            searchQuery: '',
                          ),
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: accent),
              ),
            ),
            onChanged: (value) =>
                ref.read(expenseFilterProvider(groupId).notifier).state = filter
                    .copyWith(searchQuery: value),
          ),
        ),

        // Category chips + sort
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              // Sort chip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ActionChip(
                  avatar: Icon(
                    filter.sortOrder == SortOrder.descending
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 16,
                  ),
                  label: Text(filter.sortBy.label),
                  onPressed: () =>
                      _showSortPicker(context, ref, groupId, filter),
                ),
              ),

              // Clear filters
              if (filter.hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    avatar: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Clear'),
                    onPressed: () =>
                        ref
                                .read(expenseFilterProvider(groupId).notifier)
                                .state =
                            const ExpenseFilter(),
                  ),
                ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: VerticalDivider(
                  width: 1,
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                ),
              ),

              // Category filter chips
              ...ExpenseCategory.values.map((cat) {
                final isSelected = filter.categoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text('${cat.emoji} ${cat.label}'),
                    selectedColor: accent.withValues(alpha: 0.15),
                    checkmarkColor: accent,
                    onSelected: (selected) {
                      ref
                          .read(expenseFilterProvider(groupId).notifier)
                          .state = selected
                          ? filter.copyWith(categoryFilter: cat)
                          : filter.copyWith(clearCategory: true);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showSortPicker(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    ExpenseFilter filter,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            ...ExpenseSortField.values.map(
              (field) => RadioListTile<ExpenseSortField>(
                value: field,
                groupValue: filter.sortBy,
                title: Text(field.label),
                onChanged: (value) {
                  ref.read(expenseFilterProvider(groupId).notifier).state =
                      filter.copyWith(sortBy: value);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Ascending'),
              value: filter.sortOrder == SortOrder.ascending,
              onChanged: (value) {
                ref
                    .read(expenseFilterProvider(groupId).notifier)
                    .state = filter.copyWith(
                  sortOrder: value ? SortOrder.ascending : SortOrder.descending,
                );
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
