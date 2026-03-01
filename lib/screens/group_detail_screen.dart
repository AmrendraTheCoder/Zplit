import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../providers/group_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/expense_filter_provider.dart';
import '../widgets/expense_tile.dart';
import '../widgets/expense_filter_bar.dart';

import '../theme/app_colors.dart';

/// Group Detail screen — Splitwise-inspired layout.
///
/// Green header with group icon + name, balance summary,
/// Settle Up / Balances action buttons, and card-based expense list.
class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref
        .watch(groupsProvider)
        .where((g) => g.id == groupId)
        .firstOrNull;
    final expenses = ref.watch(filteredGroupExpensesProvider(groupId));
    final user = ref.watch(currentUserProvider);
    final allUsers = ref.watch(allUsersProvider);
    final _ = ref.watch(groupTotalProvider(groupId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group')),
        body: const Center(child: Text('Group not found')),
      );
    }

    final userBalance = ref.watch(
      userGroupBalanceProvider((userId: user?.id ?? '', groupId: groupId)),
    );

    // Determine who the user owes / is owed by
    String balanceText;
    if (userBalance.abs() < 0.01) {
      balanceText = 'All settled up!';
    } else if (userBalance > 0) {
      balanceText = 'You are owed';
    } else {
      balanceText = 'You owe';
    }

    return Scaffold(
      body: Column(
        children: [
          // ── Green Header ──────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.85)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Nav bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'ZPLIT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _showGroupOptions(context, ref, groupId),
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Group icon
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.groups_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Balance row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          balanceText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₹ ${userBalance.abs().toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            label: 'Settle Up',
                            icon: Icons.handshake_outlined,
                            accent: accent,
                            filled: true,
                            onTap: () =>
                                context.push('/group/$groupId/settle-up'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            label: 'Balances',
                            icon: Icons.bar_chart_rounded,
                            accent: accent,
                            filled: false,
                            onTap: () => context.push('/group/$groupId/stats'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Members Row ─────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: group.memberIds.length,
                itemBuilder: (context, index) {
                  final memberId = group.memberIds[index];
                  final member = allUsers
                      .where((u) => u.id == memberId)
                      .firstOrNull;
                  final isCurrentUser = memberId == user?.id;
                  final displayName = isCurrentUser
                      ? 'You'
                      : (member?.displayName ?? 'Member');

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isCurrentUser
                              ? accent
                              : AppColors.avatarColors[index %
                                    AppColors.avatarColors.length],
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Filter Bar + Expenses List ─────────────────
          ExpenseFilterBar(groupId: groupId),

          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No expenses yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to add your first expense',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      final payer = expense.payerId == user?.id
                          ? 'You'
                          : (allUsers
                                    .where((u) => u.id == expense.payerId)
                                    .firstOrNull
                                    ?.displayName ??
                                'Someone');
                      return ExpenseTile(
                        expense: expense,
                        payerName: payer,
                        currency: group.currency,
                        onTap: () => context.push(
                          '/group/$groupId/edit-expense/${expense.id}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/group/$groupId/add-expense'),
        backgroundColor: accent,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color accent,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: filled ? accent : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: filled ? accent : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showGroupOptions(
    BuildContext context,
    WidgetRef ref,
    String groupId,
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
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Group'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.person_add_outlined),
              title: const Text('Add Member'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Group'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/group/$groupId/share');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static void _showBalances(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    String currentUserId,
    List allUsers,
    List<String> memberIds,
    Color accent,
    bool isDark,
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
            Text('Balances', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...memberIds.where((id) => id != currentUserId).map((memberId) {
              final member = allUsers
                  .where((u) => u.id == memberId)
                  .firstOrNull;
              final name = member?.displayName ?? 'Member';
              final balance = ref.read(
                pairwiseBalanceProvider((
                  userId: currentUserId,
                  otherUserId: memberId,
                  groupId: groupId,
                )),
              );
              final isOwed = balance > 0;
              final color = balance.abs() < 0.01
                  ? (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)
                  : (isOwed ? AppColors.moneyOwedTo : AppColors.moneyOwed);
              final label = balance.abs() < 0.01
                  ? 'settled up'
                  : (isOwed ? 'owes you' : 'you owe');

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      AppColors.avatarColors[memberIds.indexOf(memberId) %
                          AppColors.avatarColors.length],
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(name),
                subtitle: Text(
                  label,
                  style: TextStyle(color: color, fontSize: 12),
                ),
                trailing: Text(
                  '₹${balance.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
