import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import '../models/split_model.dart';

import '../theme/app_colors.dart';

/// Settle Up — Payment Method Screen.
///
/// Shows transfer visualization (avatar → arrow → avatar),
/// payment method choices, and Settle Up button.
/// Actually records a settlement expense on confirm.
class SettleUpPaymentScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String memberId;

  const SettleUpPaymentScreen({
    super.key,
    required this.groupId,
    required this.memberId,
  });

  @override
  ConsumerState<SettleUpPaymentScreen> createState() =>
      _SettleUpPaymentScreenState();
}

class _SettleUpPaymentScreenState
    extends ConsumerState<SettleUpPaymentScreen> {
  int _selectedMethod = -1;

  static const _paymentMethods = [
    _PaymentMethod(
      icon: Icons.account_balance_wallet_rounded,
      title: 'UPI',
      subtitle: 'Pay Via UPI',
      color: Color(0xFF5F259F),
    ),
    _PaymentMethod(
      icon: Icons.g_mobiledata_rounded,
      title: 'GPay',
      subtitle: 'Pay Via Google Pay',
      color: Color(0xFF4285F4),
    ),
    _PaymentMethod(
      icon: Icons.credit_card_rounded,
      title: 'Card',
      subtitle: 'Pay Via Debit/Credit Card',
      color: Color(0xFFFF9800),
    ),
    _PaymentMethod(
      icon: Icons.receipt_long_rounded,
      title: 'Record',
      subtitle: 'Record Other Payment Method',
      color: Color(0xFF795548),
    ),
  ];

  void _settleUp() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Get the pairwise balance
    final pairBalance = ref.read(pairwiseBalanceProvider((
      userId: user.id,
      otherUserId: widget.memberId,
      groupId: widget.groupId,
    )));

    final amount = pairBalance.abs();
    if (amount < 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to settle!'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Determine who pays whom
    // Negative pairBalance = user owes member → user pays member
    // Positive pairBalance = member owes user → member pays user
    final payerId = pairBalance < 0 ? user.id : widget.memberId;
    final debtorId = pairBalance < 0 ? widget.memberId : user.id;

    // Create a settlement expense (category: other, description: Settlement)
    final expense = ExpenseModel.create(
      groupId: widget.groupId,
      description: 'Settlement',
      totalAmount: amount,
      currency: '₹',
      payerId: payerId,
      createdBy: user.id,
      category: ExpenseCategory.other,
      splitMode: SplitMode.exact,
      deviceId: user.deviceId,
    );

    // Create a single split where the debtor owes the full amount
    final split = SplitModel.create(
      transactionId: expense.id,
      debtorId: debtorId,
      rawInput: amount,
      owedShare: amount,
    );

    ref.read(expensesProvider.notifier).addExpense(expense);
    ref.read(splitsProvider.notifier).addSplits([split]);

    // Navigate to success
    context.go('/group/${widget.groupId}/settle-up/${widget.memberId}/success');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final allUsers = ref.watch(allUsersProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final member =
        allUsers.where((u) => u.id == widget.memberId).firstOrNull;
    final memberName = member?.displayName ?? 'Member';
    final memberInitial =
        memberName.isNotEmpty ? memberName[0].toUpperCase() : '?';
    final userInitial = user?.initials ?? '?';

    // Use PAIRWISE balance
    final pairBalance = ref.watch(pairwiseBalanceProvider((
      userId: user?.id ?? '',
      otherUserId: widget.memberId,
      groupId: widget.groupId,
    )));

    final isUserOwing = pairBalance < 0;
    final oweSummary = isUserOwing
        ? 'You owe $memberName'
        : '$memberName owes you';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_rounded, color: accent),
        ),
        title: Text(
          'Settle Up',
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // "You owe X ₹500"
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(text: '$oweSummary '),
                TextSpan(
                  text: '₹${pairBalance.abs().toStringAsFixed(0)}.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Transfer visualization
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: isUserOwing
                    ? AppColors.avatarColors[0]
                    : AppColors.moneyOwed,
                child: Text(
                  isUserOwing ? userInitial : memberInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.arrow_forward_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  size: 28),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 26,
                backgroundColor: isUserOwing
                    ? AppColors.moneyOwed
                    : AppColors.avatarColors[0],
                child: Text(
                  isUserOwing ? memberInitial : userInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text(
            'Choose a payment method',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 16),

          // Payment methods list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                final isSelected = _selectedMethod == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedMethod = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? accent
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.06)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Radio circle
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? accent
                                  : AppColors.textTertiaryLight,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),

                        // Icon and label
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: method.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(method.icon,
                              color: method.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              method.subtitle,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Settle Up button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedMethod >= 0 ? _settleUp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      isDark ? AppColors.cardDark : Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Settle Up'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethod {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _PaymentMethod({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
