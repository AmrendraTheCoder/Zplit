import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/stats_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

/// Group Statistics screen with pie, bar, and line charts.
class GroupStatsScreen extends ConsumerWidget {
  final String groupId;
  const GroupStatsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = ref.watch(groupTotalProvider(groupId));
    final average = ref.watch(averageExpenseProvider(groupId));
    final categoryData = ref.watch(categoryBreakdownProvider(groupId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Statistics'),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: accent,
            labelColor: accent,
            unselectedLabelColor: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            tabs: const [
              Tab(text: 'Categories'),
              Tab(text: 'Members'),
              Tab(text: 'Timeline'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Summary cards
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  _summaryCard(
                    context,
                    label: 'Total Spent',
                    value: '₹${total.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_rounded,
                    color: accent,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _summaryCard(
                    context,
                    label: 'Avg Expense',
                    value: '₹${average.toStringAsFixed(0)}',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.moneyOwedTo,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _summaryCard(
                    context,
                    label: 'Top Category',
                    value: categoryData.isNotEmpty
                        ? categoryData.entries
                              .reduce((a, b) => a.value > b.value ? a : b)
                              .key
                              .emoji
                        : '—',
                    icon: Icons.category_rounded,
                    color: AppColors.moneyOwed,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  _CategoryTab(groupId: groupId),
                  _MemberTab(groupId: groupId),
                  _TimelineTab(groupId: groupId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Pie Chart Tab ─────────────────────────────

class _CategoryTab extends ConsumerWidget {
  final String groupId;
  const _CategoryTab({required this.groupId});

  static const _chartColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(categoryBreakdownProvider(groupId));
    final total = ref.watch(groupTotalProvider(groupId));

    if (data.isEmpty) {
      return const Center(child: Text('No expenses yet'));
    }

    final sections = data.entries.toList().asMap().entries.map((entry) {
      final idx = entry.key;
      final cat = entry.value.key;
      final amount = entry.value.value;
      final pct = total > 0 ? (amount / total * 100) : 0.0;

      return PieChartSectionData(
        value: amount,
        title: '${pct.toStringAsFixed(0)}%',
        color: _chartColors[idx % _chartColors.length],
        radius: 90,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        badgeWidget: Text(cat.emoji, style: const TextStyle(fontSize: 18)),
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: data.entries.toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value.key;
              final amount = entry.value.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _chartColors[idx % _chartColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${cat.emoji} ${cat.label}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Member Bar Chart Tab ──────────────────────────────

class _MemberTab extends ConsumerWidget {
  final String groupId;
  const _MemberTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spending = ref.watch(memberSpendingProvider(groupId));
    final allUsers = ref.watch(allUsersProvider);
    final accent = Theme.of(context).colorScheme.primary;

    if (spending.isEmpty) {
      return const Center(child: Text('No expenses yet'));
    }

    final entries = spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.first.value;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who spent the most?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '₹${rod.toY.toStringAsFixed(0)}',
                        TextStyle(color: accent, fontWeight: FontWeight.w700),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= entries.length) return const SizedBox();
                        final memberId = entries[idx].key;
                        final user = allUsers
                            .where((u) => u.id == memberId)
                            .firstOrNull;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            user?.displayName.split(' ').first ?? 'User',
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                        '₹${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                barGroups: entries.asMap().entries.map((entry) {
                  final idx = entry.key;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: AppColors
                            .avatarColors[idx % AppColors.avatarColors.length],
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline Line Chart Tab ───────────────────────────

class _TimelineTab extends ConsumerWidget {
  final String groupId;
  const _TimelineTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(spendingOverTimeProvider(groupId));
    final accent = Theme.of(context).colorScheme.primary;

    if (data.isEmpty) {
      return const Center(child: Text('No expenses yet'));
    }

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.amount);
    }).toList();

    final maxY = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Over Time',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                maxY: maxY * 1.2,
                minY: 0,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final date = data[idx].date;
                        return LineTooltipItem(
                          '${date.day}/${date.month}\n₹${spot.y.toStringAsFixed(0)}',
                          TextStyle(color: accent, fontWeight: FontWeight.w700),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (data.length / 5).ceilToDouble().clamp(1, 100),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= data.length || idx < 0) {
                          return const SizedBox();
                        }
                        final date = data[idx].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                        '₹${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: accent,
                    barWidth: 3,
                    dotData: FlDotData(show: data.length < 15),
                    belowBarData: BarAreaData(
                      show: true,
                      color: accent.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
