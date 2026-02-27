import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../theme/app_colors.dart';
import 'package:intl/intl.dart';

/// Expense tile — Splitwise-inspired card layout.
///
/// Shows category emoji, description, "Added by" subtitle,
/// date, You Owe amount, and soft-delete indicator.
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
    final dateStr = DateFormat('MMMM d, y').format(expense.date);
    final categoryColor = AppColors.categoryColors[expense.category.name] ??
        AppColors.textTertiaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  expense.category.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Description + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        'Added by $payerName',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (expense.isDeleted) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.delete_outline,
                            color: AppColors.textTertiaryLight, size: 14),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Amount + date column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currency ${expense.totalAmount.toStringAsFixed(expense.totalAmount == expense.totalAmount.roundToDouble() ? 0 : 2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
