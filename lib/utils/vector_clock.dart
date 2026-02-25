import 'dart:convert';
import 'package:equatable/equatable.dart';

/// The result of comparing two [VectorClock] instances.
///
/// In a decentralized system without a global clock, this enum
/// tells us the causal relationship between two events:
///
/// - [before] – Local happened strictly before remote (safe to update)
/// - [after] – Local happened strictly after remote (remote is outdated)
/// - [concurrent] – Neither dominates → CONFLICT detected
/// - [identical] – Clocks are exactly the same (no change)
enum ClockRelation {
  /// Local ≤ Remote on ALL keys, and < on at least one.
  /// The remote version is a direct successor. Safe to accept.
  before,

  /// Local ≥ Remote on ALL keys, and > on at least one.
  /// The local version is ahead. Remote is outdated.
  after,

  /// Neither clock dominates the other.
  /// Two nodes made independent edits offline → CONFLICT.
  concurrent,

  /// All entries are equal. No divergence.
  identical,
}

/// A Vector Clock implementation for causal ordering in Zplit's
/// decentralized sync layer.
///
/// Each node (device) maintains its own counter. When an edit is made
/// on device "A", we call `increment("A")`. When syncing, we compare
/// clocks to detect conflicts and `merge()` to reconcile.
///
/// ## Example
/// ```dart
/// var local = VectorClock({'A': 2, 'B': 1});
/// var remote = VectorClock({'A': 2, 'B': 3});
///
/// local.compare(remote); // ClockRelation.before (safe to update)
///
/// var merged = local.merge(remote);
/// // merged.clock == {'A': 2, 'B': 3}
/// ```
///
/// ## Conflict Detection (Image 5 & 7)
/// ```dart
/// var local = VectorClock({'A': 3, 'B': 1});
/// var remote = VectorClock({'A': 2, 'B': 2});
///
/// local.compare(remote); // ClockRelation.concurrent → CONFLICT!
/// ```
class VectorClock extends Equatable {
  /// The underlying clock state: `{ nodeId: counter }`.
  final Map<String, int> clock;

  /// Creates a [VectorClock] from a map of `{ nodeId: counter }`.
  const VectorClock([this.clock = const {}]);

  /// Creates a [VectorClock] from a JSON string.
  factory VectorClock.fromJson(String json) {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return VectorClock(decoded.map((k, v) => MapEntry(k, v as int)));
  }

  /// Returns a new [VectorClock] with the given [nodeId]'s counter
  /// incremented by 1.
  ///
  /// This should be called whenever the local device creates or
  /// edits a Sync Unit (Expense + Splits).
  VectorClock increment(String nodeId) {
    final newClock = Map<String, int>.from(clock);
    newClock[nodeId] = (newClock[nodeId] ?? 0) + 1;
    return VectorClock(newClock);
  }

  /// Compares this clock against [other] to determine causal
  /// ordering.
  ///
  /// Algorithm:
  /// 1. Collect all keys from both clocks.
  /// 2. For each key, compare values (missing = 0).
  /// 3. If local ≤ remote everywhere → `before`
  /// 4. If local ≥ remote everywhere → `after`
  /// 5. Otherwise → `concurrent` (conflict)
  /// 6. If exactly equal → `identical`
  ClockRelation compare(VectorClock other) {
    final allKeys = {...clock.keys, ...other.clock.keys};

    bool localBehind = false; // local < remote on at least one key
    bool localAhead = false;  // local > remote on at least one key

    for (final key in allKeys) {
      final localVal = clock[key] ?? 0;
      final remoteVal = other.clock[key] ?? 0;

      if (localVal < remoteVal) {
        localBehind = true;
      } else if (localVal > remoteVal) {
        localAhead = true;
      }

      // Early exit: once we've seen both directions, it's concurrent
      if (localBehind && localAhead) {
        return ClockRelation.concurrent;
      }
    }

    if (localBehind && !localAhead) return ClockRelation.before;
    if (localAhead && !localBehind) return ClockRelation.after;
    return ClockRelation.identical;
  }

  /// Merges this clock with [other] by taking the element-wise
  /// maximum of all counters.
  ///
  /// This should be called after accepting a remote Sync Unit so
  /// that subsequent edits will causally follow both local and
  /// remote histories.
  VectorClock merge(VectorClock other) {
    final allKeys = {...clock.keys, ...other.clock.keys};
    final merged = <String, int>{};

    for (final key in allKeys) {
      final localVal = clock[key] ?? 0;
      final remoteVal = other.clock[key] ?? 0;
      merged[key] = localVal > remoteVal ? localVal : remoteVal;
    }

    return VectorClock(merged);
  }

  /// Returns the counter value for a given [nodeId], defaulting to 0.
  int operator [](String nodeId) => clock[nodeId] ?? 0;

  /// Serializes this clock to a JSON string for storage/transfer.
  String toJson() => jsonEncode(clock);

  /// Returns a human-readable representation.
  @override
  String toString() => 'VectorClock($clock)';

  @override
  List<Object?> get props => [clock];
}
