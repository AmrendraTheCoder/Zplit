import 'package:flutter_test/flutter_test.dart';
import 'package:zplit/models/split_model.dart';
import 'package:zplit/models/expense_model.dart';
import 'package:zplit/services/split_calculator_service.dart';

void main() {
  const service = SplitCalculatorService();

  /// Helper to create a split.
  SplitModel makeSplit({
    required String debtorId,
    double rawInput = 0,
  }) {
    return SplitModel(
      id: 'split-$debtorId',
      transactionId: 'expense-1',
      debtorId: debtorId,
      rawInput: rawInput,
      owedShare: 0,
    );
  }

  group('Equal splits', () {
    test('splits evenly among 3 people', () {
      final splits = [
        makeSplit(debtorId: 'A'),
        makeSplit(debtorId: 'B'),
        makeSplit(debtorId: 'C'),
      ];

      final result = service.calculateSplits(3000, splits, SplitMode.equal);

      expect(result.length, 3);
      final total = result.fold<double>(0, (s, e) => s + e.owedShare);
      expect(total, closeTo(3000, 0.02));
    });

    test('handles indivisible amounts (rounding)', () {
      final splits = [
        makeSplit(debtorId: 'A'),
        makeSplit(debtorId: 'B'),
        makeSplit(debtorId: 'C'),
      ];

      final result = service.calculateSplits(100, splits, SplitMode.equal);

      // 100 / 3 = 33.33... → first person gets remainder
      final total = result.fold<double>(0, (s, e) => s + e.owedShare);
      expect(total, closeTo(100, 0.02));
    });

    test('splits between 2 people', () {
      final splits = [
        makeSplit(debtorId: 'A'),
        makeSplit(debtorId: 'B'),
      ];

      final result = service.calculateSplits(200, splits, SplitMode.equal);

      expect(result[0].owedShare, 100);
      expect(result[1].owedShare, 100);
    });

    test('single person gets full amount', () {
      final splits = [makeSplit(debtorId: 'A')];
      final result = service.calculateSplits(500, splits, SplitMode.equal);
      expect(result[0].owedShare, 500);
    });
  });

  group('Percent splits (Image 3: PERCENT)', () {
    test('50/30/20 split on ₹3000', () {
      final splits = [
        makeSplit(debtorId: 'A', rawInput: 50),
        makeSplit(debtorId: 'B', rawInput: 30),
        makeSplit(debtorId: 'C', rawInput: 20),
      ];

      final result = service.calculateSplits(3000, splits, SplitMode.percent);

      expect(result[0].owedShare, 1500); // 50% of 3000
      expect(result[1].owedShare, 900);  // 30% of 3000
      expect(result[2].owedShare, 600);  // 20% of 3000
    });

    test('recalculates when total changes (raw_input intent preservation)', () {
      final splits = [
        makeSplit(debtorId: 'A', rawInput: 50),
        makeSplit(debtorId: 'B', rawInput: 30),
        makeSplit(debtorId: 'C', rawInput: 20),
      ];

      // Original total: 3000
      final original = service.calculateSplits(3000, splits, SplitMode.percent);
      expect(original[0].owedShare, 1500);

      // Total changes to 4000 → A's share should update to 2000
      final recalculated = service.recalculateOnTotalChange(4000, splits, SplitMode.percent);
      expect(recalculated[0].owedShare, 2000);
      expect(recalculated[1].owedShare, 1200);
      expect(recalculated[2].owedShare, 800);
    });

    test('preserves rawInput during recalculation', () {
      final splits = [
        makeSplit(debtorId: 'A', rawInput: 50),
      ];

      final result = service.recalculateOnTotalChange(10000, splits, SplitMode.percent);
      expect(result[0].rawInput, 50); // Intent preserved!
      expect(result[0].owedShare, 5000);
    });
  });

  group('Exact splits (Image 3: EXACT)', () {
    test('uses rawInput directly as owedShare', () {
      final splits = [
        makeSplit(debtorId: 'A', rawInput: 800),
        makeSplit(debtorId: 'B', rawInput: 1200),
        makeSplit(debtorId: 'C', rawInput: 1000),
      ];

      final result = service.calculateSplits(3000, splits, SplitMode.exact);

      expect(result[0].owedShare, 800);
      expect(result[1].owedShare, 1200);
      expect(result[2].owedShare, 1000);
    });
  });

  group('Validation', () {
    test('validateSplits passes when sum equals total', () {
      final splits = [
        makeSplit(debtorId: 'A').copyWith(owedShare: 500),
        makeSplit(debtorId: 'B').copyWith(owedShare: 500),
      ];
      expect(service.validateSplits(1000, splits), true);
    });

    test('validateSplits fails when sum does not equal total', () {
      final splits = [
        makeSplit(debtorId: 'A').copyWith(owedShare: 500),
        makeSplit(debtorId: 'B').copyWith(owedShare: 300),
      ];
      expect(service.validateSplits(1000, splits), false);
    });

    test('validatePercentages passes at 100%', () {
      final splits = [
        makeSplit(debtorId: 'A', rawInput: 60),
        makeSplit(debtorId: 'B', rawInput: 40),
      ];
      expect(service.validatePercentages(splits), true);
    });

    test('validatePercentages fails when not 100%', () {
      final splits = [
        makeSplit(debtorId: 'A', rawInput: 60),
        makeSplit(debtorId: 'B', rawInput: 30),
      ];
      expect(service.validatePercentages(splits), false);
    });
  });

  group('Edge cases', () {
    test('empty splits list returns empty', () {
      final result = service.calculateSplits(1000, [], SplitMode.equal);
      expect(result, isEmpty);
    });

    test('zero total amount', () {
      final splits = [
        makeSplit(debtorId: 'A'),
        makeSplit(debtorId: 'B'),
      ];
      final result = service.calculateSplits(0, splits, SplitMode.equal);
      expect(result[0].owedShare, 0);
      expect(result[1].owedShare, 0);
    });
  });

  group('Penny-rounding fairness', () {
    test('distributes remainder cents round-robin (3 people, ₹100)', () {
      final splits = [
        makeSplit(debtorId: 'A'),
        makeSplit(debtorId: 'B'),
        makeSplit(debtorId: 'C'),
      ];
      final result = service.calculateSplits(100, splits, SplitMode.equal);
      // 100 / 3 = 33.33 each, remainder = 1 cent → person A gets it
      expect(result[0].owedShare, closeTo(33.34, 0.01));
      expect(result[1].owedShare, closeTo(33.33, 0.01));
      expect(result[2].owedShare, closeTo(33.33, 0.01));
      // Total should still be 100
      final total = result.fold<double>(0, (s, e) => s + e.owedShare);
      expect(total, closeTo(100, 0.01));
    });

    test('distributes multiple remainder cents (6 people, ₹100)', () {
      final splits = List.generate(6, (i) => makeSplit(debtorId: 'P$i'));
      final result = service.calculateSplits(100, splits, SplitMode.equal);
      // 100 / 6 = 16.66 each, 10000 cents / 6 = 1666 each, remainder = 4 cents
      // First 4 people get 16.67, last 2 get 16.66
      final total = result.fold<double>(0, (s, e) => s + e.owedShare);
      expect(total, closeTo(100, 0.01));
    });
  });

  group('recalculateOnMemberChange', () {
    test('adding a member redistributes equal splits', () {
      final existing = [
        makeSplit(debtorId: 'A'),
        makeSplit(debtorId: 'B'),
      ];
      final result = service.recalculateOnMemberChange(
        totalAmount: 300,
        currentSplits: existing,
        newMemberIds: ['A', 'B', 'C'],
        transactionId: 'expense-1',
        splitMode: SplitMode.equal,
      );
      expect(result.length, 3);
      expect(result[0].owedShare, 100);
      expect(result[1].owedShare, 100);
      expect(result[2].owedShare, 100);
    });

    test('removing a member redistributes equal splits', () {
      final existing = [
        makeSplit(debtorId: 'A'),
        makeSplit(debtorId: 'B'),
        makeSplit(debtorId: 'C'),
      ];
      final result = service.recalculateOnMemberChange(
        totalAmount: 300,
        currentSplits: existing,
        newMemberIds: ['A', 'B'],
        transactionId: 'expense-1',
        splitMode: SplitMode.equal,
      );
      expect(result.length, 2);
      expect(result[0].owedShare, 150);
      expect(result[1].owedShare, 150);
    });

    test('adding member to percent splits starts at 0%', () {
      final existing = [
        makeSplit(debtorId: 'A', rawInput: 60),
        makeSplit(debtorId: 'B', rawInput: 40),
      ];
      final result = service.recalculateOnMemberChange(
        totalAmount: 1000,
        currentSplits: existing,
        newMemberIds: ['A', 'B', 'C'],
        transactionId: 'expense-1',
        splitMode: SplitMode.percent,
      );
      expect(result.length, 3);
      expect(result[0].owedShare, 600); // 60%
      expect(result[1].owedShare, 400); // 40%
      expect(result[2].owedShare, 0);   // 0% — user must adjust
    });
  });
}
