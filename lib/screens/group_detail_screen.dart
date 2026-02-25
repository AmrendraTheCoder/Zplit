import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../providers/group_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_tile.dart';
import '../widgets/balance_chip.dart';
import '../theme/app_colors.dart';

/// Group Detail screen — shows members, expenses, and balances.
class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupsProvider).where((g) => g.id == groupId).firstOrNull;
    final expenses = ref.watch(groupExpensesProvider(groupId));
    final user = ref.watch(currentUserProvider);
    final allUsers = ref.watch(allUsersProvider);
    final total = ref.watch(groupTotalProvider(groupId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (group == null) {
      return Scaffold(appBar: AppBar(title: const Text('Group')), body: const Center(child: Text('Group not found')));
    }

    final userBalance = ref.watch(userGroupBalanceProvider((userId: user?.id ?? '', groupId: groupId)));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180, pinned: true,
            leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_rounded)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withValues(alpha: 0.9), AppColors.primaryDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${group.memberCount} members · ${group.currency}${total.toStringAsFixed(0)} total',
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        const Spacer(),
                        BalanceChip(balance: userBalance, currency: group.currency),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Members', style: Theme.of(context).textTheme.headlineSmall),
          )),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: group.memberIds.length,
                itemBuilder: (context, index) {
                  final memberId = group.memberIds[index];
                  final member = allUsers.where((u) => u.id == memberId).firstOrNull;
                  final isCurrentUser = memberId == user?.id;
                  final displayName = isCurrentUser ? 'You' : (member?.displayName ?? 'Member');
                  final balance = ref.watch(userGroupBalanceProvider((userId: memberId, groupId: groupId)));

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isCurrentUser
                                ? (user?.avatarColor ?? AppColors.primary)
                                : AppColors.avatarColors[index % AppColors.avatarColors.length],
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(displayName, style: Theme.of(context).textTheme.labelMedium,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(
                            balance == 0 ? '✓' : '${balance > 0 ? '+' : ''}${group.currency}${balance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: balance == 0 ? AppColors.settled : (balance > 0 ? AppColors.moneyOwedTo : AppColors.moneyOwed),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Expenses', style: Theme.of(context).textTheme.headlineSmall),
                Text('${expenses.length} expense${expenses.length != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          )),

          if (expenses.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                    const SizedBox(height: 12),
                    Text('No expenses yet', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Add your first expense', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              )),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final expense = expenses[index];
                  final payer = expense.payerId == user?.id
                      ? 'You'
                      : (allUsers.where((u) => u.id == expense.payerId).firstOrNull?.displayName ?? 'Someone');
                  return ExpenseTile(
                    expense: expense,
                    payerName: payer,
                    currency: group.currency,
                    onTap: () => context.push('/group/$groupId/edit-expense/${expense.id}'),
                  );
                },
                childCount: expenses.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/group/$groupId/add-expense'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
    );
  }
}
