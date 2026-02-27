import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/split_model.dart';
import '../models/expense_model.dart';

/// Service for calculating split amounts from rawInput + splitMode.
///
/// The split mode lives on the [ExpenseModel] (Image 3), not per-split.
///
/// The key innovation (Image 4: raw_input pattern):
/// ```
/// When total changes:     ₹3000 → ₹4000
/// User A (rawInput=50%):  ₹1500 → ₹2000  ← automatic
/// User B (rawInput=30%):  ₹900  → ₹1200  ← automatic
/// ```
class SplitCalculatorService {
  const SplitCalculatorService();

  /// Calculates owed_share for each split based on the expense's splitMode.
  List<SplitModel> calculateSplits(
    double totalAmount,
    List<SplitModel> splits,
    SplitMode splitMode,
  ) {
    if (splits.isEmpty) return [];

    switch (splitMode) {
      case SplitMode.equal:
        return _calculateEqual(totalAmount, splits);
      case SplitMode.percent:
        return _calculatePercent(totalAmount, splits);
      case SplitMode.exact:
        return _calculateExact(splits);
    }
  }

  /// Recalculates when the expense total changes.
  /// Preserves rawInput (user intent) and recomputes owedShare.
  List<SplitModel> recalculateOnTotalChange(
    double newTotal,
    List<SplitModel> splits,
    SplitMode splitMode,
  ) {
    return calculateSplits(newTotal, splits, splitMode);
  }

  /// Recalculates splits when a member is added or removed.
  ///
  /// **Adding**: Creates a new split for the new member and redistributes.
  /// **Removing**: Removes the member's split and redistributes.
  ///
  /// For EQUAL mode: recalculates fair shares.
  /// For PERCENT mode: new members get 0% initially (user must reassign).
  /// For EXACT mode: new members get ₹0 initially.
  List<SplitModel> recalculateOnMemberChange({
    required double totalAmount,
    required List<SplitModel> currentSplits,
    required List<String> newMemberIds,
    required String transactionId,
    required SplitMode splitMode,
  }) {
    // Build new split list: keep existing, add new, remove departed
    final existingById = {
      for (final s in currentSplits) s.debtorId: s,
    };

    final updatedSplits = newMemberIds.map((memberId) {
      if (existingById.containsKey(memberId)) {
        return existingById[memberId]!;
      }
      // New member — default rawInput based on mode
      return SplitModel.create(
        transactionId: transactionId,
        debtorId: memberId,
        rawInput: 0,
        owedShare: 0,
      );
    }).toList();

    // For EQUAL mode, recalculate regardless (fair share changes)
    if (splitMode == SplitMode.equal) {
      return calculateSplits(totalAmount, updatedSplits, splitMode);
    }

    // For PERCENT/EXACT, preserve existing rawInput values
    // New members start at 0 — user must adjust manually
    return calculateSplits(totalAmount, updatedSplits, splitMode);
  }

  // ── Private Calculators ─────────────────────────────

  /// **Penny-rounding fairness**: Distributes remainder cents
  /// round-robin instead of dumping them all on person #1.
  ///
  /// Example: ₹100 / 3 = ₹33.33 each, with ₹0.01 remainder.
  /// → Person at index 0 gets ₹33.34, others get ₹33.33.
  /// If ₹100 / 6 = ₹16.666..., remainder = ₹0.04:
  /// → Persons 0,1,2,3 each get ₹16.67, persons 4,5 get ₹16.66.
  List<SplitModel> _calculateEqual(
    double totalAmount,
    List<SplitModel> splits,
  ) {
    final count = splits.length;
    // Round each share down to 2 decimal places
    final baseShare = (totalAmount * 100).floor() ~/ count;
    final remainderCents = (totalAmount * 100).floor() - (baseShare * count);

    return splits.asMap().entries.map((entry) {
      final extraCent = entry.key < remainderCents ? 1 : 0;
      final finalCents = baseShare + extraCent;
      return entry.value.copyWith(
        owedShare: finalCents / 100.0,
      );
    }).toList();
  }

  List<SplitModel> _calculatePercent(
    double totalAmount,
    List<SplitModel> splits,
  ) {
    return splits.map((s) {
      return s.copyWith(
        owedShare: totalAmount * s.rawInput / 100,
      );
    }).toList();
  }

  List<SplitModel> _calculateExact(List<SplitModel> splits) {
    return splits.map((s) {
      return s.copyWith(owedShare: s.rawInput);
    }).toList();
  }

  // ── Validation ──────────────────────────────────────

  /// Validates that all splits sum to the total.
  bool validateSplits(double totalAmount, List<SplitModel> splits) {
    final sum = splits.fold<double>(0, (s, e) => s + e.owedShare);
    return (sum - totalAmount).abs() < 0.01;
  }

  /// Validates that percentage rawInputs sum to 100.
  bool validatePercentages(List<SplitModel> splits) {
    final sum = splits.fold<double>(0, (s, e) => s + e.rawInput);
    return (sum - 100).abs() < 0.01;
  }
}

/// Riverpod provider for the SplitCalculatorService.
final splitCalculatorProvider = Provider<SplitCalculatorService>((ref) {
  return const SplitCalculatorService();
});
