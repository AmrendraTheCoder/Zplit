import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../providers/group_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/group_card.dart';
import '../theme/app_colors.dart';

/// Home Dashboard — inspired by Splitwise layout.
///
/// Green header with ZPLIT branding, user avatar, balance summary,
/// and scrollable group list.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final groups = ref.watch(groupsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    // Calculate overall balances
    double totalOwed = 0;
    double totalOwing = 0;
    for (final group in groups) {
      final balance = ref.watch(
        userGroupBalanceProvider((userId: user?.id ?? '', groupId: group.id)),
      );
      if (balance > 0) {
        totalOwed += balance;
      } else {
        totalOwing += balance.abs();
      }
    }
    final netBalance = totalOwed - totalOwing;

    return Scaffold(
      body: Column(
        children: [
          // ── Green Header (Splitwise-style) ──────────────
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
                  // App bar row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'ZPLIT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.push('/scan'),
                          icon: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // User avatar
                  const SizedBox(height: 8),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: netBalance >= 0
                            ? AppColors.moneyOwedTo
                            : AppColors.moneyOwed,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user?.initials ?? '?',
                        style: TextStyle(
                          color: accent,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.displayName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Balance Summary Card ────────────────────────
          Transform.translate(
            offset: const Offset(0, -1),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _balanceColumn(
                    context,
                    label: 'You are owed',
                    amount: '₹ ${totalOwed.toStringAsFixed(0)}',
                    color: AppColors.moneyOwedTo,
                  ),
                  Container(
                    height: 36,
                    width: 1,
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                  ),
                  _balanceColumn(
                    context,
                    label: 'You owe',
                    amount: '₹ ${totalOwing.toStringAsFixed(0)}',
                    color: AppColors.moneyOwed,
                  ),
                  Container(
                    height: 36,
                    width: 1,
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                  ),
                  _balanceColumn(
                    context,
                    label: 'Total Balance',
                    amount: '₹ ${netBalance.toStringAsFixed(0)}',
                    color: netBalance >= 0
                        ? AppColors.moneyOwedTo
                        : AppColors.moneyOwed,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Section Label ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'GROUPS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${groups.length} group${groups.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // ── Groups List ────────────────────────────────
          Expanded(
            child: groups.isEmpty
                ? _buildEmptyState(context, accent)
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final total = ref.watch(groupTotalProvider(group.id));
                      final balance = ref.watch(
                        userGroupBalanceProvider((
                          userId: user?.id ?? '',
                          groupId: group.id,
                        )),
                      );
                      return GroupCard(
                        group: group,
                        totalSpent: total,
                        userBalance: balance,
                        currency: group.currency,
                        onTap: () => context.push('/group/${group.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-group'),
        backgroundColor: accent,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _balanceColumn(
    BuildContext context, {
    required String label,
    required String amount,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.group_add_outlined, size: 40, color: accent),
            ),
            const SizedBox(height: 20),
            Text(
              'No groups yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group to start splitting\nexpenses with friends',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
