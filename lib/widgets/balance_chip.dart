import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A colored chip showing balance status.
///
/// - Green: "You are owed ₹X"
/// - Red: "You owe ₹X"
/// - Gray: "All settled"
class BalanceChip extends StatelessWidget {
  final double balance;
  final String currency;

  const BalanceChip({super.key, required this.balance, required this.currency});

  @override
  Widget build(BuildContext context) {
    if (balance.abs() < 0.01) {
      return _buildChip(
        label: 'All settled ✓',
        color: AppColors.settled,
        context: context,
      );
    }

    if (balance > 0) {
      return _buildChip(
        label: 'You are owed $currency${balance.toStringAsFixed(2)}',
        color: AppColors.moneyOwedTo,
        context: context,
      );
    }

    return _buildChip(
      label: 'You owe $currency${balance.abs().toStringAsFixed(2)}',
      color: AppColors.moneyOwed,
      context: context,
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
