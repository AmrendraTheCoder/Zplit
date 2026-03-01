import 'package:flutter_test/flutter_test.dart';
import 'package:zplit/models/expense_model.dart';
import 'package:zplit/utils/vector_clock.dart';

void main() {
  /// Reusable test expense.
  ExpenseModel makeExpense({
    String id = 'exp-1',
    String groupId = 'group-1',
    VectorClock clock = const VectorClock({'A': 1}),
    bool isDeleted = false,
  }) {
    return ExpenseModel(
      id: id,
      groupId: groupId,
      payerId: 'user-a',
      createdBy: 'user-a',
      description: 'Test Dinner',
      totalAmount: 3000,
      currency: 'INR',
      category: ExpenseCategory.food,
      splitMode: SplitMode.equal,
      date: DateTime(2026, 2, 25),
      vectorClock: clock,
      lastModifiedBy: 'user-a',
      isDeleted: isDeleted,
      createdAt: DateTime(2026, 2, 25),
      updatedAt: DateTime(2026, 2, 25),
    );
  }

  group('ExpenseModel.create', () {
    test('generates unique ID and initial vector clock', () {
      final expense = ExpenseModel.create(
        groupId: 'g1',
        description: 'Lunch',
        totalAmount: 500,
        payerId: 'user-a',
        createdBy: 'user-a',
        deviceId: 'device-1',
      );

      expect(expense.id, isNotEmpty);
      expect(expense.vectorClock['device-1'], 1);
      expect(expense.lastModifiedBy, 'user-a');
      expect(expense.isDeleted, false);
      expect(expense.category, ExpenseCategory.other);
      expect(expense.splitMode, SplitMode.equal);
    });

    test('uses provided category and splitMode', () {
      final expense = ExpenseModel.create(
        groupId: 'g1',
        description: 'Movie',
        totalAmount: 800,
        payerId: 'user-a',
        createdBy: 'user-a',
        category: ExpenseCategory.entertainment,
        splitMode: SplitMode.percent,
        deviceId: 'device-1',
      );

      expect(expense.category, ExpenseCategory.entertainment);
      expect(expense.splitMode, SplitMode.percent);
    });
  });

  group('copyWith', () {
    test('creates copy with changed fields', () {
      final original = makeExpense();
      final copy = original.copyWith(
        description: 'Updated Dinner',
        totalAmount: 5000,
      );

      expect(copy.id, original.id);
      expect(copy.groupId, original.groupId);
      expect(copy.description, 'Updated Dinner');
      expect(copy.totalAmount, 5000);
      expect(copy.payerId, original.payerId);
    });

    test('preserves unchanged fields', () {
      final original = makeExpense();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.description, original.description);
      expect(copy.totalAmount, original.totalAmount);
      expect(copy.category, original.category);
    });
  });

  group('softDelete', () {
    test('sets isDeleted and bumps vector clock', () {
      final expense = makeExpense();
      final deleted = expense.softDelete('device-1', 'user-b');

      expect(deleted.isDeleted, true);
      expect(deleted.lastModifiedBy, 'user-b');
      expect(deleted.vectorClock['device-1'], 1);
      expect(deleted.id, expense.id);
    });
  });

  group('withClockTick', () {
    test('increments vector clock for device', () {
      final expense = makeExpense(clock: const VectorClock({'A': 2}));
      final ticked = expense.withClockTick('A', 'user-b');

      expect(ticked.vectorClock['A'], 3);
      expect(ticked.lastModifiedBy, 'user-b');
    });

    test('adds new device entry to clock', () {
      final expense = makeExpense(clock: const VectorClock({'A': 1}));
      final ticked = expense.withClockTick('B', 'user-b');

      expect(ticked.vectorClock['A'], 1);
      expect(ticked.vectorClock['B'], 1);
    });
  });

  group('JSON serialization', () {
    test('toJson → fromJson roundtrip', () {
      final expense = makeExpense();
      final json = expense.toJson();
      final restored = ExpenseModel.fromJson(json);

      expect(restored.id, expense.id);
      expect(restored.groupId, expense.groupId);
      expect(restored.payerId, expense.payerId);
      expect(restored.createdBy, expense.createdBy);
      expect(restored.description, expense.description);
      expect(restored.totalAmount, expense.totalAmount);
      expect(restored.currency, expense.currency);
      expect(restored.category, expense.category);
      expect(restored.splitMode, expense.splitMode);
      expect(restored.isDeleted, expense.isDeleted);
      expect(restored.lastModifiedBy, expense.lastModifiedBy);
      expect(restored.vectorClock, expense.vectorClock);
    });

    test('fromJson handles unknown category gracefully', () {
      final json = makeExpense().toJson();
      json['category'] = 'unknown_category';
      final restored = ExpenseModel.fromJson(json);
      expect(restored.category, ExpenseCategory.other);
    });

    test('fromJson handles unknown splitMode gracefully', () {
      final json = makeExpense().toJson();
      json['splitMode'] = 'weird_mode';
      final restored = ExpenseModel.fromJson(json);
      expect(restored.splitMode, SplitMode.equal);
    });
  });

  group('ExpenseCategory', () {
    test('all categories have non-empty emoji', () {
      for (final cat in ExpenseCategory.values) {
        expect(cat.emoji, isNotEmpty);
      }
    });

    test('all categories have a label starting with uppercase', () {
      for (final cat in ExpenseCategory.values) {
        expect(cat.label[0], equals(cat.label[0].toUpperCase()));
      }
    });
  });

  group('SplitMode', () {
    test('label capitalizes first letter', () {
      expect(SplitMode.equal.label, 'Equal');
      expect(SplitMode.percent.label, 'Percent');
      expect(SplitMode.exact.label, 'Exact');
    });
  });

  group('Equatable', () {
    test('identical expenses are equal', () {
      final a = makeExpense();
      final b = makeExpense();
      expect(a, equals(b));
    });

    test('different expenses are not equal', () {
      final a = makeExpense(id: 'exp-1');
      final b = makeExpense(id: 'exp-2');
      expect(a, isNot(equals(b)));
    });
  });
}
