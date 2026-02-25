import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';

/// List tile widget for displaying an expense in the group detail screen.
class ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  final String payerName;
  final String currency;
  final VoidCallback? onTap;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.payerName,
    required this.currency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('MMM d').format(expense.date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (AppColors.categoryColors[expense.category.name] ??
                        AppColors.textTertiaryLight)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(expense.category.emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(expense.description,
                      style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (expense.hasConflict) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                    ],
                    if (expense.isDeleted) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.delete_outline, color: AppColors.textTertiaryLight, size: 18),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text('paid by $payerName · $dateStr',
                    style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              '$currency${expense.totalAmount.toStringAsFixed(expense.totalAmount == expense.totalAmount.roundToDouble() ? 0 : 2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
