import 'package:flutter_test/flutter_test.dart';
import 'package:zplit/utils/vector_clock.dart';

void main() {
  group('VectorClock', () {
    group('increment', () {
      test('increments a new node from 0 to 1', () {
        const clock = VectorClock();
        final result = clock.increment('A');
        expect(result.clock, {'A': 1});
      });

      test('increments an existing node', () {
        const clock = VectorClock({'A': 2, 'B': 1});
        final result = clock.increment('A');
        expect(result.clock, {'A': 3, 'B': 1});
      });

      test('does not mutate the original clock', () {
        const original = VectorClock({'A': 1});
        final incremented = original.increment('A');
        expect(original.clock, {'A': 1});
        expect(incremented.clock, {'A': 2});
      });
    });

    group('compare', () {
      test('identical clocks → identical', () {
        const a = VectorClock({'A': 2, 'B': 1});
        const b = VectorClock({'A': 2, 'B': 1});
        expect(a.compare(b), ClockRelation.identical);
      });

      test('empty clocks → identical', () {
        const a = VectorClock();
        const b = VectorClock();
        expect(a.compare(b), ClockRelation.identical);
      });

      test('local strictly behind remote → before', () {
        const local = VectorClock({'A': 1, 'B': 1});
        const remote = VectorClock({'A': 2, 'B': 1});
        expect(local.compare(remote), ClockRelation.before);
      });

      test('local behind on all keys → before', () {
        const local = VectorClock({'A': 1, 'B': 1});
        const remote = VectorClock({'A': 2, 'B': 3});
        expect(local.compare(remote), ClockRelation.before);
      });

      test('local behind (missing key) → before', () {
        const local = VectorClock({'A': 1});
        const remote = VectorClock({'A': 1, 'B': 2});
        expect(local.compare(remote), ClockRelation.before);
      });

      test('local strictly ahead of remote → after', () {
        const local = VectorClock({'A': 3, 'B': 2});
        const remote = VectorClock({'A': 2, 'B': 1});
        expect(local.compare(remote), ClockRelation.after);
      });

      test('local ahead (remote missing key) → after', () {
        const local = VectorClock({'A': 1, 'B': 2});
        const remote = VectorClock({'A': 1});
        expect(local.compare(remote), ClockRelation.after);
      });

      test('concurrent edits (A ahead on one, B ahead on other) → concurrent', () {
        const local = VectorClock({'A': 3, 'B': 1});
        const remote = VectorClock({'A': 2, 'B': 2});
        expect(local.compare(remote), ClockRelation.concurrent);
      });

      test('concurrent edits (disjoint keys) → concurrent', () {
        const local = VectorClock({'A': 1});
        const remote = VectorClock({'B': 1});
        expect(local.compare(remote), ClockRelation.concurrent);
      });

      test('concurrent (complex case with 3 nodes)', () {
        const local = VectorClock({'A': 3, 'B': 1, 'C': 2});
        const remote = VectorClock({'A': 2, 'B': 4, 'C': 2});
        expect(local.compare(remote), ClockRelation.concurrent);
      });
    });

    group('merge', () {
      test('merge takes element-wise maximum', () {
        const a = VectorClock({'A': 3, 'B': 1});
        const b = VectorClock({'A': 2, 'B': 4});
        final merged = a.merge(b);
        expect(merged.clock, {'A': 3, 'B': 4});
      });

      test('merge with disjoint keys includes all', () {
        const a = VectorClock({'A': 1});
        const b = VectorClock({'B': 2});
        final merged = a.merge(b);
        expect(merged.clock, {'A': 1, 'B': 2});
      });

      test('merge with empty clock', () {
        const a = VectorClock({'A': 1, 'B': 2});
        const b = VectorClock();
        final merged = a.merge(b);
        expect(merged.clock, {'A': 1, 'B': 2});
      });

      test('merge is commutative', () {
        const a = VectorClock({'A': 3, 'B': 1, 'C': 5});
        const b = VectorClock({'A': 2, 'B': 4, 'D': 1});
        expect(a.merge(b).clock, b.merge(a).clock);
      });
    });

    group('serialization', () {
      test('toJson → fromJson roundtrip', () {
        const original = VectorClock({'A': 2, 'B': 5, 'C': 1});
        final json = original.toJson();
        final restored = VectorClock.fromJson(json);
        expect(restored, original);
      });

      test('empty clock roundtrip', () {
        const original = VectorClock();
        final json = original.toJson();
        final restored = VectorClock.fromJson(json);
        expect(restored.clock, isEmpty);
      });
    });

    group('operator []', () {
      test('returns counter for existing key', () {
        const clock = VectorClock({'A': 5});
        expect(clock['A'], 5);
      });

      test('returns 0 for missing key', () {
        const clock = VectorClock({'A': 5});
        expect(clock['B'], 0);
      });
    });

    group('equality', () {
      test('equal clocks are equal', () {
        const a = VectorClock({'A': 1, 'B': 2});
        const b = VectorClock({'A': 1, 'B': 2});
        expect(a, b);
      });

      test('different clocks are not equal', () {
        const a = VectorClock({'A': 1, 'B': 2});
        const b = VectorClock({'A': 1, 'B': 3});
        expect(a, isNot(b));
      });
    });
  });
}
