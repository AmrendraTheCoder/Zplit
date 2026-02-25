import 'package:equatable/equatable.dart';
import 'expense_model.dart';
import 'split_model.dart';

/// The atomic unit of P2P synchronization (Image 7).
///
/// In Zplit, we don't sync the entire database. Instead, we sync
/// "Bundles" — each containing ONE expense plus ALL its related splits.
///
/// This ensures transactional consistency during P2P transfer:
/// either the entire expense (with all debt breakdowns) is received,
/// or nothing is. Partial data (an expense without splits) is never
/// persisted.
///
/// ## Transfer Flow
/// ```
/// ┌──────────────────────────────────────────────────┐
/// │                  SYNC UNIT                       │
/// │                                                  │
/// │  ┌──────────────────────────────┐                │
/// │  │     ExpenseModel             │                │
/// │  │  "Dinner at Pizza Place"     │                │
/// │  │  Total: ₹3000               │                │
/// │  │  VectorClock: {"A":2,"B":1}  │                │
/// │  └──────────────────────────────┘                │
/// │                                                  │
/// │  ┌──────────┐ ┌──────────┐ ┌──────────┐         │
/// │  │ Split #1  │ │ Split #2  │ │ Split #3  │       │
/// │  │ User A    │ │ User B    │ │ User C    │       │
/// │  │ 50% →1500 │ │ 30% →900  │ │ 20% →600  │      │
/// │  └──────────┘ └──────────┘ └──────────┘         │
/// │                                                  │
/// │  Metadata:                                       │
/// │    originDeviceId: "device-abc-123"               │
/// │    timestamp: "2026-02-25T16:30:00Z"             │
/// │    signature: "sha256:..."                        │
/// └──────────────────────────────────────────────────┘
/// ```
class SyncUnit extends Equatable {
  /// The expense (transaction header).
  final ExpenseModel expense;

  /// All splits (debt breakdowns) for this expense.
  final List<SplitModel> splits;

  /// The device that created/last-modified this sync unit.
  final String originDeviceId;

  /// When this sync unit was bundled for transfer.
  final DateTime timestamp;

  /// Cryptographic signature for authenticity verification.
  /// Will be implemented with Secure Storage in Phase 2.
  final String? signature;

  const SyncUnit({
    required this.expense,
    required this.splits,
    required this.originDeviceId,
    required this.timestamp,
    this.signature,
  });

  /// Creates a [SyncUnit] bundle ready for P2P transfer.
  factory SyncUnit.bundle({
    required ExpenseModel expense,
    required List<SplitModel> splits,
    required String deviceId,
  }) {
    return SyncUnit(
      expense: expense,
      splits: splits,
      originDeviceId: deviceId,
      timestamp: DateTime.now(),
    );
  }

  /// Serializes the entire sync unit to a JSON-compatible map.
  /// This is the "Transfer String" for P2P communication.
  Map<String, dynamic> toJson() => {
        'expense': expense.toJson(),
        'splits': splits.map((s) => s.toJson()).toList(),
        'originDeviceId': originDeviceId,
        'timestamp': timestamp.toIso8601String(),
        'signature': signature,
      };

  /// Deserializes a sync unit from a received JSON map.
  factory SyncUnit.fromJson(Map<String, dynamic> json) => SyncUnit(
        expense: ExpenseModel.fromJson(json['expense'] as Map<String, dynamic>),
        splits: (json['splits'] as List)
            .map((s) => SplitModel.fromJson(s as Map<String, dynamic>))
            .toList(),
        originDeviceId: json['originDeviceId'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        signature: json['signature'] as String?,
      );

  @override
  List<Object?> get props =>
      [expense, splits, originDeviceId, timestamp, signature];
}
