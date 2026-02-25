import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../providers/group_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/group_card.dart';
import '../theme/app_colors.dart';

/// Home Dashboard screen — the main hub of the app.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final groups = ref.watch(groupsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: user?.avatarColor ?? AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              user?.initials ?? '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, ${user?.displayName ?? 'there'} 👋',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              Text(
                                'Here\'s your expense summary',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.push('/settings'),
                          icon: Icon(
                            Icons.settings_outlined,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildOverallBalanceCard(context, ref, groups),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Your Groups',
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text(
                          '${groups.length} group${groups.length != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Groups List ───────────────────────────
            if (groups.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final group = groups[index];
                    final total = ref.watch(groupTotalProvider(group.id));
                    final balance = ref.watch(userGroupBalanceProvider(
                      (userId: user?.id ?? '', groupId: group.id),
                    ));
                    return GroupCard(
                      group: group,
                      totalSpent: total,
                      userBalance: balance,
                      currency: group.currency,
                      onTap: () => context.push('/group/${group.id}'),
                    );
                  },
                  childCount: groups.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-group'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Group'),
      ),
    );
  }

  Widget _buildOverallBalanceCard(
      BuildContext context, WidgetRef ref, List groups) {
    final user = ref.watch(currentUserProvider);
    double totalOwed = 0;
    double totalOwing = 0;

    for (final group in groups) {
      final balance = ref.watch(userGroupBalanceProvider(
        (userId: user?.id ?? '', groupId: group.id),
      ));
      if (balance > 0) {
        totalOwed += balance;
      } else {
        totalOwing += balance.abs();
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1D29), Color(0xFF2D3142)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overall Balance',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            '₹${(totalOwed - totalOwing).toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _balanceRow(
                icon: Icons.arrow_downward_rounded, iconColor: AppColors.moneyOwedTo,
                label: 'You are owed', amount: '₹${totalOwed.toStringAsFixed(0)}',
              )),
              Container(height: 36, width: 1, color: Colors.white24),
              Expanded(child: _balanceRow(
                icon: Icons.arrow_upward_rounded, iconColor: AppColors.moneyOwed,
                label: 'You owe', amount: '₹${totalOwing.toStringAsFixed(0)}',
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceRow({
    required IconData icon, required Color iconColor,
    required String label, required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
              Text(amount, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_add_outlined, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('No groups yet', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Create a group to start splitting\nexpenses with friends',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }
}
