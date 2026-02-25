import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/group_model.dart';

/// Premium group card for the home screen list.
///
/// Features: glassmorphism card, gradient avatar with emoji,
/// staggered animation entrance, and animated tap feedback.
class GroupCard extends StatefulWidget {
  final GroupModel group;
  final double totalSpent;
  final double userBalance;
  final String currency;
  final VoidCallback onTap;
  final int index;

  const GroupCard({
    super.key,
    required this.group,
    required this.totalSpent,
    required this.userBalance,
    required this.currency,
    required this.onTap,
    this.index = 0,
  });

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  static const _groupEmojis = ['🏖️', '🍕', '🎉', '✈️', '🏠', '🎮', '📚', '🎵'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientIndex = widget.group.name.hashCode.abs() % _gradientPairs.length;
    final gradient = _gradientPairs[gradientIndex];
    final emoji = _groupEmojis[widget.group.name.hashCode.abs() % _groupEmojis.length];

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _tapController.forward(),
        onTapUp: (_) {
          _tapController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _tapController.reverse(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardDark.withValues(alpha: 0.7)
                : AppColors.cardLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // ── Gradient Avatar with Emoji ──────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),

              // ── Group Info ────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_outline_rounded, size: 14,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.group.memberCount}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.receipt_long_outlined, size: 14,
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.currency}${widget.totalSpent.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Balance Pill ──────────────────────
              _buildBalancePill(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalancePill(BuildContext context) {
    if (widget.userBalance == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.settled.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 14, color: AppColors.settled),
            const SizedBox(width: 4),
            Text(
              'settled',
              style: TextStyle(
                color: AppColors.settled,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final isOwed = widget.userBalance > 0;
    final color = isOwed ? AppColors.moneyOwedTo : AppColors.moneyOwed;
    final label = isOwed
        ? '+${widget.currency}${widget.userBalance.toStringAsFixed(0)}'
        : '-${widget.currency}${widget.userBalance.abs().toStringAsFixed(0)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  static const _gradientPairs = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo→Violet
    [Color(0xFFF59E0B), Color(0xFFF97316)], // Amber→Orange
    [Color(0xFF10B981), Color(0xFF06B6D4)], // Emerald→Cyan
    [Color(0xFFEC4899), Color(0xFFF43F5E)], // Pink→Rose
    [Color(0xFF3B82F6), Color(0xFF6366F1)], // Blue→Indigo
    [Color(0xFFF97316), Color(0xFFEF4444)], // Orange→Red
    [Color(0xFF14B8A6), Color(0xFF10B981)], // Teal→Emerald
    [Color(0xFF8B5CF6), Color(0xFFEC4899)], // Violet→Pink
  ];
}
