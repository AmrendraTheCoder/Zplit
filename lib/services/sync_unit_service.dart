import 'dart:convert';
import '../models/expense_model.dart';
import '../models/split_model.dart';
import '../models/sync_unit_model.dart';
import '../utils/vector_clock.dart';

/// Result of applying an incoming Sync Unit against local state.
enum SyncResult {
  /// Remote is newer — local state should be updated.
  updated,

  /// Local is newer — remote is outdated, ignore it.
  ignored,

  /// Concurrent edit — auto-resolved via Last-Writer-Wins (latest updatedAt).
  autoResolved,

  /// First time seeing this expense — insert it.
  newEntry,
}

/// Detailed result from applying a sync operation.
class SyncOutcome {
  final SyncResult result;
  final SyncUnit syncUnit;

  const SyncOutcome({
    required this.result,
    required this.syncUnit,
  });
}

/// Service for bundling, unbundling, and applying Sync Units.
///
/// This is the core P2P transfer logic. A Sync Unit is the atomic
/// unit of data exchange between devices:
///
/// ```
/// Device A ──── JSON Transfer String ────► Device B
///              (1 Expense + N Splits)
/// ```
///
/// The service handles:
/// 1. **Bundling**: Package an expense + splits into a JSON string
/// 2. **Unbundling**: Parse a received JSON string back into models
/// 3. **Applying**: Compare vector clocks and decide: update, ignore, or LWW
class SyncUnitService {
  const SyncUnitService();

  /// Bundles an expense and its splits into a [SyncUnit] ready for
  /// P2P transfer.
  SyncUnit bundle({
    required ExpenseModel expense,
    required List<SplitModel> splits,
    required String deviceId,
  }) {
    return SyncUnit.bundle(
      expense: expense,
      splits: splits,
      deviceId: deviceId,
    );
  }

  /// Serializes a [SyncUnit] to a JSON "Transfer String" for P2P.
  String serialize(SyncUnit syncUnit) {
    return jsonEncode(syncUnit.toJson());
  }

  /// Deserializes a received JSON string back into a [SyncUnit].
  SyncUnit deserialize(String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return SyncUnit.fromJson(map);
    } catch (e) {
      throw FormatException(
        'Failed to deserialize Sync Unit: $e',
        json,
      );
    }
  }

  /// Applies an incoming [SyncUnit] against the local state.
  ///
  /// Uses Vector Clock comparison for causal ordering, with
  /// **Last-Writer-Wins (LWW)** auto-resolution for concurrent edits:
  ///
  /// | Local Clock vs Remote Clock | Action |
  /// |---|---|
  /// | No local expense exists | Accept (new entry) |
  /// | Local `before` Remote | Update local with remote |
  /// | Local `after` Remote | Ignore (remote is outdated) |
  /// | `concurrent` | LWW: latest `updatedAt` wins |
  /// | `identical` | No-op (already synced) |
  SyncOutcome apply({
    required SyncUnit incoming,
    ExpenseModel? localExpense,
  }) {
    // Case 1: No local expense — this is a new entry
    if (localExpense == null) {
      return SyncOutcome(
        result: SyncResult.newEntry,
        syncUnit: incoming,
      );
    }

    // Case 2: Compare vector clocks
    final relation = localExpense.vectorClock.compare(
      incoming.expense.vectorClock,
    );

    switch (relation) {
      case ClockRelation.before:
        // Remote is ahead — update local
        return SyncOutcome(
          result: SyncResult.updated,
          syncUnit: incoming,
        );

      case ClockRelation.after:
        // Local is ahead — ignore remote
        return SyncOutcome(
          result: SyncResult.ignored,
          syncUnit: incoming,
        );

      case ClockRelation.identical:
        // Already in sync — ignore
        return SyncOutcome(
          result: SyncResult.ignored,
          syncUnit: incoming,
        );

      case ClockRelation.concurrent:
        // LWW: most recent updatedAt wins automatically.
        // No conflict flags, no manual resolution needed.
        if (incoming.expense.updatedAt.isAfter(localExpense.updatedAt)) {
          // Remote is more recent — accept it
          return SyncOutcome(
            result: SyncResult.autoResolved,
            syncUnit: incoming,
          );
        } else {
          // Local is more recent (or equal) — keep local
          return SyncOutcome(
            result: SyncResult.ignored,
            syncUnit: incoming,
          );
        }
    }
  }

  /// Merges vector clocks after accepting a remote update.
  VectorClock mergeClocks(VectorClock local, VectorClock remote) {
    return local.merge(remote);
  }
}
