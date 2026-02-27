import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplit/models/expense_model.dart';
import 'package:zplit/models/split_model.dart';
import 'package:zplit/models/sync_unit_model.dart';
import 'package:zplit/services/sync_unit_service.dart';
import 'package:zplit/utils/vector_clock.dart';

void main() {
  const service = SyncUnitService();

  /// Creates a test expense with a given vector clock.
  ExpenseModel makeExpense({
    String id = 'exp-1',
    VectorClock clock = const VectorClock({'A': 1}),
  }) {
    return ExpenseModel(
      id: id,
      groupId: 'group-1',
      payerId: 'user-a',
      createdBy: 'user-a',
      description: 'Test Dinner',
      totalAmount: 3000,
      currency: 'INR',
      category: ExpenseCategory.food,
      splitMode: SplitMode.percent,
      date: DateTime(2026, 2, 25),
      vectorClock: clock,
      lastModifiedBy: 'user-a',
      createdAt: DateTime(2026, 2, 25),
      updatedAt: DateTime(2026, 2, 25),
    );
  }

  /// Creates test splits using official schema field names.
  List<SplitModel> makeSplits({String transactionId = 'exp-1'}) {
    return [
      SplitModel(
        id: 'split-1',
        transactionId: transactionId,
        debtorId: 'user-a',
        rawInput: 50,
        owedShare: 1500,
      ),
      SplitModel(
        id: 'split-2',
        transactionId: transactionId,
        debtorId: 'user-b',
        rawInput: 30,
        owedShare: 900,
      ),
      SplitModel(
        id: 'split-3',
        transactionId: transactionId,
        debtorId: 'user-c',
        rawInput: 20,
        owedShare: 600,
      ),
    ];
  }

  group('SyncUnitService - Bundling', () {
    test('bundles expense + splits into a SyncUnit', () {
      final expense = makeExpense();
      final splits = makeSplits();

      final unit = service.bundle(
        expense: expense,
        splits: splits,
        deviceId: 'device-123',
      );

      expect(unit.expense.id, 'exp-1');
      expect(unit.splits.length, 3);
      expect(unit.originDeviceId, 'device-123');
    });

    test('serialize → deserialize roundtrip', () {
      final expense = makeExpense();
      final splits = makeSplits();
      final unit = service.bundle(
        expense: expense,
        splits: splits,
        deviceId: 'device-abc',
      );

      final json = service.serialize(unit);
      final restored = service.deserialize(json);

      expect(restored.expense.id, unit.expense.id);
      expect(restored.expense.description, 'Test Dinner');
      expect(restored.expense.totalAmount, 3000);
      expect(restored.expense.payerId, 'user-a');
      expect(restored.expense.createdBy, 'user-a');
      expect(restored.expense.splitMode, SplitMode.percent);
      expect(restored.expense.lastModifiedBy, 'user-a');
      expect(restored.expense.isDeleted, false);
      expect(restored.expense.vectorClock.clock, {'A': 1});
      expect(restored.splits.length, 3);
      expect(restored.splits[0].debtorId, 'user-a');
      expect(restored.splits[0].rawInput, 50);
      expect(restored.splits[0].owedShare, 1500);
      expect(restored.originDeviceId, 'device-abc');
    });

    test('serialized JSON is valid JSON', () {
      final unit = service.bundle(
        expense: makeExpense(),
        splits: makeSplits(),
        deviceId: 'device-x',
      );

      final json = service.serialize(unit);
      expect(() => jsonDecode(json), returnsNormally);
    });

    test('deserialize throws on invalid JSON', () {
      expect(
        () => service.deserialize('not valid json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('expense records splitMode correctly in JSON', () {
      final unit = service.bundle(
        expense: makeExpense(),
        splits: makeSplits(),
        deviceId: 'device-x',
      );

      final json = service.serialize(unit);
      final map = jsonDecode(json) as Map<String, dynamic>;
      final expenseMap = map['expense'] as Map<String, dynamic>;
      expect(expenseMap['splitMode'], 'percent');
      expect(expenseMap['lastModifiedBy'], 'user-a');
      expect(expenseMap['isDeleted'], false);
    });

    test('split records transactionId and debtorId in JSON', () {
      final unit = service.bundle(
        expense: makeExpense(),
        splits: makeSplits(),
        deviceId: 'device-x',
      );

      final json = service.serialize(unit);
      final map = jsonDecode(json) as Map<String, dynamic>;
      final splitMap = (map['splits'] as List).first as Map<String, dynamic>;
      expect(splitMap['transactionId'], 'exp-1');
      expect(splitMap['debtorId'], 'user-a');
    });
  });

  group('SyncUnitService - Apply (Vector Clock Comparison)', () {
    test('new entry (no local expense) → newEntry', () {
      final incoming = SyncUnit.bundle(
        expense: makeExpense(clock: const VectorClock({'B': 1})),
        splits: makeSplits(),
        deviceId: 'device-B',
      );

      final outcome = service.apply(incoming: incoming, localExpense: null);
      expect(outcome.result, SyncResult.newEntry);
    });

    test('remote is ahead (local before) → updated', () {
      final localExpense = makeExpense(
        clock: const VectorClock({'A': 1, 'B': 1}),
      );
      final incoming = SyncUnit.bundle(
        expense: makeExpense(clock: const VectorClock({'A': 2, 'B': 1})),
        splits: makeSplits(),
        deviceId: 'device-A',
      );

      final outcome = service.apply(
        incoming: incoming,
        localExpense: localExpense,
      );
      expect(outcome.result, SyncResult.updated);
    });

    test('local is ahead (remote outdated) → ignored', () {
      final localExpense = makeExpense(
        clock: const VectorClock({'A': 3, 'B': 2}),
      );
      final incoming = SyncUnit.bundle(
        expense: makeExpense(clock: const VectorClock({'A': 2, 'B': 1})),
        splits: makeSplits(),
        deviceId: 'device-old',
      );

      final outcome = service.apply(
        incoming: incoming,
        localExpense: localExpense,
      );
      expect(outcome.result, SyncResult.ignored);
    });

    test('identical clocks → ignored', () {
      final localExpense = makeExpense(
        clock: const VectorClock({'A': 2, 'B': 1}),
      );
      final incoming = SyncUnit.bundle(
        expense: makeExpense(clock: const VectorClock({'A': 2, 'B': 1})),
        splits: makeSplits(),
        deviceId: 'device-X',
      );

      final outcome = service.apply(
        incoming: incoming,
        localExpense: localExpense,
      );
      expect(outcome.result, SyncResult.ignored);
    });

    test('concurrent edits → LWW remote wins (more recent)', () {
      final localExpense = ExpenseModel(
        id: 'exp-1',
        groupId: 'group-1',
        payerId: 'user-a',
        createdBy: 'user-a',
        description: 'Test Dinner',
        totalAmount: 3000,
        currency: 'INR',
        category: ExpenseCategory.food,
        splitMode: SplitMode.percent,
        date: DateTime(2026, 2, 25),
        vectorClock: const VectorClock({'A': 3, 'B': 1}),
        lastModifiedBy: 'user-a',
        createdAt: DateTime(2026, 2, 25),
        updatedAt: DateTime(2026, 2, 25, 10, 0), // 10:00 AM
      );
      final remoteExpense = ExpenseModel(
        id: 'exp-1',
        groupId: 'group-1',
        payerId: 'user-a',
        createdBy: 'user-a',
        description: 'Test Dinner',
        totalAmount: 3000,
        currency: 'INR',
        category: ExpenseCategory.food,
        splitMode: SplitMode.percent,
        date: DateTime(2026, 2, 25),
        vectorClock: const VectorClock({'A': 2, 'B': 2}),
        lastModifiedBy: 'user-b',
        createdAt: DateTime(2026, 2, 25),
        updatedAt: DateTime(2026, 2, 25, 11, 0), // 11:00 AM — more recent
      );
      final incoming = SyncUnit.bundle(
        expense: remoteExpense,
        splits: makeSplits(),
        deviceId: 'device-B',
      );

      final outcome = service.apply(
        incoming: incoming,
        localExpense: localExpense,
      );

      expect(outcome.result, SyncResult.autoResolved);
    });

    test('concurrent edits → LWW local wins (local more recent)', () {
      final localExpense = ExpenseModel(
        id: 'exp-1',
        groupId: 'group-1',
        payerId: 'user-a',
        createdBy: 'user-a',
        description: 'Test Dinner',
        totalAmount: 3000,
        currency: 'INR',
        category: ExpenseCategory.food,
        splitMode: SplitMode.percent,
        date: DateTime(2026, 2, 25),
        vectorClock: const VectorClock({'A': 3, 'B': 1}),
        lastModifiedBy: 'user-a',
        createdAt: DateTime(2026, 2, 25),
        updatedAt: DateTime(2026, 2, 25, 12, 0), // noon — more recent
      );
      final remoteExpense = ExpenseModel(
        id: 'exp-1',
        groupId: 'group-1',
        payerId: 'user-a',
        createdBy: 'user-a',
        description: 'Test Dinner',
        totalAmount: 3000,
        currency: 'INR',
        category: ExpenseCategory.food,
        splitMode: SplitMode.percent,
        date: DateTime(2026, 2, 25),
        vectorClock: const VectorClock({'A': 2, 'B': 2}),
        lastModifiedBy: 'user-b',
        createdAt: DateTime(2026, 2, 25),
        updatedAt: DateTime(2026, 2, 25, 9, 0), // 9 AM — older
      );
      final incoming = SyncUnit.bundle(
        expense: remoteExpense,
        splits: makeSplits(),
        deviceId: 'device-B',
      );

      final outcome = service.apply(
        incoming: incoming,
        localExpense: localExpense,
      );

      expect(outcome.result, SyncResult.ignored);
    });
  });

  group('SyncUnitService - Soft Delete Sync', () {
    test('soft-deleted expense syncs with isDeleted flag', () {
      final deletedExpense = makeExpense().softDelete('device-A', 'user-a');
      expect(deletedExpense.isDeleted, true);
      expect(deletedExpense.lastModifiedBy, 'user-a');

      final unit = service.bundle(
        expense: deletedExpense,
        splits: makeSplits(),
        deviceId: 'device-A',
      );

      final json = service.serialize(unit);
      final restored = service.deserialize(json);
      expect(restored.expense.isDeleted, true);
    });
  });

  group('SyncUnitService - Merge Clocks', () {
    test('merges clocks after accepting update', () {
      const local = VectorClock({'A': 2, 'B': 1});
      const remote = VectorClock({'A': 2, 'B': 3});

      final merged = service.mergeClocks(local, remote);
      expect(merged.clock, {'A': 2, 'B': 3});
    });
  });
}
