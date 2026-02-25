import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/split_model.dart';
import '../models/expense_model.dart';

/// Service for calculating split amounts from rawInput + splitMode.
///
/// The split mode now lives on the [ExpenseModel] (Image 3), not per-split.
/// This service takes the expense's split mode and applies it to all splits.
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
  ///
  /// [splitMode] comes from the parent Expense (Image 3).
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

  // ── Private Calculators ─────────────────────────────

  List<SplitModel> _calculateEqual(
    double totalAmount,
    List<SplitModel> splits,
  ) {
    final count = splits.length;
    final shareEach = totalAmount / count;
    final roundedShare =
        (shareEach * 100).floorToDouble() / 100; // Round down to 2dp
    final remainder = totalAmount - (roundedShare * count);

    return splits.asMap().entries.map((entry) {
      final isFirst = entry.key == 0;
      return entry.value.copyWith(
        owedShare: isFirst ? roundedShare + remainder : roundedShare,
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
