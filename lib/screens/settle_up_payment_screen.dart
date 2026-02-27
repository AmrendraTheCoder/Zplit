import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';

import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';

/// Settle Up — Payment Method Screen.
///
/// Shows transfer visualization (avatar → arrow → avatar),
/// payment method choices, and Settle Up button.
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

    final balance = ref.watch(userGroupBalanceProvider(
      (userId: user?.id ?? '', groupId: widget.groupId),
    ));

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
                const TextSpan(text: 'You owe '),
                TextSpan(
                  text: memberName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: ' ₹${balance.abs().toStringAsFixed(0)}.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Transfer visualization: User → arrow → Member
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.avatarColors[0],
                child: Text(
                  userInitial,
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
                backgroundColor: AppColors.moneyOwed,
                child: Text(
                  memberInitial,
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
                              color: isSelected ? accent : AppColors.textTertiaryLight,
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
                onPressed: _selectedMethod >= 0
                    ? () => context.push(
                          '/group/${widget.groupId}/settle-up/${widget.memberId}/success',
                        )
                    : null,
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
