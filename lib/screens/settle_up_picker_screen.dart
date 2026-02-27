import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../providers/group_provider.dart';
import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';

/// Settle Up — Member Picker.
///
/// "Who do you want to settle up with?"
/// Lists all members with their owed/owing amounts.
class SettleUpPickerScreen extends ConsumerWidget {
  final String groupId;
  const SettleUpPickerScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupsProvider)
        .where((g) => g.id == groupId)
        .firstOrNull;
    final user = ref.watch(currentUserProvider);
    final allUsers = ref.watch(allUsersProvider);
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settle Up')),
        body: const Center(child: Text('Group not found')),
      );
    }

    // Build list of other members with balances
    final otherMemberIds =
        group.memberIds.where((id) => id != user?.id).toList();

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
          Text(
            'Who do you want to settle up with?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: otherMemberIds.length,
              itemBuilder: (context, index) {
                final memberId = otherMemberIds[index];
                final member = allUsers
                    .where((u) => u.id == memberId)
                    .firstOrNull;
                final displayName = member?.displayName ?? 'Member';
                final initial = displayName.isNotEmpty
                    ? displayName[0].toUpperCase()
                    : '?';
                final balance = ref.watch(userGroupBalanceProvider(
                  (userId: user?.id ?? '', groupId: groupId),
                ));

                // Determine relationship
                final isOwed = balance > 0;
                final balanceLabel =
                    isOwed ? 'Owes you' : 'You owe';
                final balanceColor =
                    isOwed ? AppColors.moneyOwedTo : AppColors.moneyOwed;

                return GestureDetector(
                  onTap: () => context.push(
                    '/group/$groupId/settle-up/$memberId',
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
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
                        // Avatar
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.avatarColors[
                              index % AppColors.avatarColors.length],
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Name + subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                member?.username ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),

                        // Amount
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              balanceLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: balanceColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹ ${balance.abs().toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: balanceColor,
                              ),
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
        ],
      ),
    );
  }
}
