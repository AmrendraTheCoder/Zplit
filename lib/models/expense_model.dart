import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../utils/vector_clock.dart';

/// How an expense is split among participants.
///
/// From Image 3 (Transaction table schema):
/// `split_mode` is an Enum: EQUAL, PERCENT, EXACT
/// NOTE: This lives on the EXPENSE level (Image 3 & 4), not per-split.
/// All splits within one expense share the same mode.
enum SplitMode {
  equal,
  percent,
  exact;

  String get label => name[0].toUpperCase() + name.substring(1);
}

/// Expense categories for filtering and visualization.
enum ExpenseCategory {
  food,
  transport,
  entertainment,
  shopping,
  utilities,
  rent,
  health,
  other;

  /// Display-friendly name.
  String get label => name[0].toUpperCase() + name.substring(1);

  /// Icon for UI display.
  String get emoji {
    switch (this) {
      case ExpenseCategory.food:
        return '🍕';
      case ExpenseCategory.transport:
        return '🚗';
      case ExpenseCategory.entertainment:
        return '🎬';
      case ExpenseCategory.shopping:
        return '🛍️';
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.rent:
        return '🏠';
      case ExpenseCategory.health:
        return '🏥';
      case ExpenseCategory.other:
        return '📦';
    }
  }
}

/// The "Transaction" / "Expense" from the official schema images.
///
/// Field mapping from all images:
///
/// | Our Field        | Image 3 (Table)     | Image 4 (ER)       | Image 5 (Final)   |
/// |------------------|---------------------|--------------------|--------------------|
/// | id               | id (UUID/TEXT, PK)  | id (PK)            | expense_id         |
/// | groupId          | group_id            | group_id           | —                  |
/// | payerId          | payer_id            | payer_id (FK)      | payer_id           |
/// | createdBy        | —                   | —                  | created_by         |
/// | totalAmount      | total_amount (REAL) | total_amount       | total_amount       |
/// | currency         | currency (TEXT)     | currency           | currency           |
/// | description      | description (TEXT)  | description        | description        |
/// | category         | —                   | —                  | category           |
/// | splitMode        | split_mode (TEXT)   | split_mode         | —                  |
/// | vectorClock      | vector_clock (JSON) | vector_clock       | version            |
/// | lastModifiedBy   | last_modified_by    | last_modified_by   | —                  |
/// | isDeleted        | is_deleted (BOOL)   | is_deleted         | is_deleted         |
/// | date             | —                   | —                  | date               |
/// | createdAt        | —                   | —                  | created_at         |
/// | updatedAt        | —                   | —                  | updated_at         |
class ExpenseModel extends Equatable {
  /// Primary key — unique across all devices (UUID).
  final String id;

  /// Links to a specific Trip or Group (Image 3).
  final String groupId;

  /// The user who paid the bill (Image 3: payer_id).
  final String payerId;

  /// The user who created this expense record (Image 5: created_by).
  /// May differ from payerId (e.g., someone else logs the expense).
  final String createdBy;

  final String description;

  /// The total value (e.g., 3000.0) — Image 3: REAL type.
  final double totalAmount;

  /// Currency code, e.g., "INR", "USD" (Image 3).
  final String currency;

  final ExpenseCategory category;

  /// How this expense is split: EQUAL, PERCENT, or EXACT (Image 3).
  /// This lives at the expense level, not per-split.
  final SplitMode splitMode;

  final DateTime date;

  /// Vector Clock for sync — Image 3: "Crucial for Sync".
  /// Stores version state as JSON, e.g., {"A": 2, "B": 1}.
  /// Replaces simple integer versions to handle multi-user edits.
  final VectorClock vectorClock;

  /// ID of the user who made the last edit — for LWW
  /// (Last-Writer-Wins) conflict resolution (Image 3).
  final String lastModifiedBy;

  /// Soft delete flag — required for syncing deletions (Image 3).
  /// When true, this expense is logically deleted but kept for sync.
  final bool isDeleted;



  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpenseModel({
    required this.id,
    required this.groupId,
    required this.payerId,
    required this.createdBy,
    required this.description,
    required this.totalAmount,
    required this.currency,
    required this.category,
    required this.splitMode,
    required this.date,
    required this.vectorClock,
    required this.lastModifiedBy,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a new expense with auto-generated ID, timestamp,
  /// and an initial vector clock tick for the creating device.
  factory ExpenseModel.create({
    required String groupId,
    required String description,
    required double totalAmount,
    String currency = 'INR',
    required String payerId,
    required String createdBy,
    ExpenseCategory category = ExpenseCategory.other,
    SplitMode splitMode = SplitMode.equal,
    DateTime? date,
    required String deviceId,
  }) {
    final now = DateTime.now();
    return ExpenseModel(
      id: const Uuid().v4(),
      groupId: groupId,
      payerId: payerId,
      createdBy: createdBy,
      description: description,
      totalAmount: totalAmount,
      currency: currency,
      category: category,
      splitMode: splitMode,
      date: date ?? now,
      vectorClock: const VectorClock().increment(deviceId),
      lastModifiedBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Returns a copy with an incremented vector clock for the given device.
  /// Call this whenever the expense is edited locally.
  ExpenseModel withClockTick(String deviceId, String modifiedBy) {
    return copyWith(
      vectorClock: vectorClock.increment(deviceId),
      lastModifiedBy: modifiedBy,
      updatedAt: DateTime.now(),
    );
  }



  /// Soft-deletes this expense (Image 3: is_deleted).
  ExpenseModel softDelete(String deviceId, String modifiedBy) {
    return copyWith(
      isDeleted: true,
      vectorClock: vectorClock.increment(deviceId),
      lastModifiedBy: modifiedBy,
      updatedAt: DateTime.now(),
    );
  }

  ExpenseModel copyWith({
    String? description,
    double? totalAmount,
    String? currency,
    String? payerId,
    String? createdBy,
    ExpenseCategory? category,
    SplitMode? splitMode,
    DateTime? date,
    VectorClock? vectorClock,
    String? lastModifiedBy,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id,
      groupId: groupId,
      payerId: payerId ?? this.payerId,
      createdBy: createdBy ?? this.createdBy,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      splitMode: splitMode ?? this.splitMode,
      date: date ?? this.date,
      vectorClock: vectorClock ?? this.vectorClock,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'payerId': payerId,
        'createdBy': createdBy,
        'description': description,
        'totalAmount': totalAmount,
        'currency': currency,
        'category': category.name,
        'splitMode': splitMode.name,
        'date': date.toIso8601String(),
        'vectorClock': vectorClock.clock,
        'lastModifiedBy': lastModifiedBy,
        'isDeleted': isDeleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
        id: json['id'] as String,
        groupId: json['groupId'] as String,
        payerId: json['payerId'] as String,
        createdBy: json['createdBy'] as String,
        description: json['description'] as String,
        totalAmount: (json['totalAmount'] as num).toDouble(),
        currency: json['currency'] as String,
        category: ExpenseCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ExpenseCategory.other,
        ),
        splitMode: SplitMode.values.firstWhere(
          (e) => e.name == json['splitMode'],
          orElse: () => SplitMode.equal,
        ),
        date: DateTime.parse(json['date'] as String),
        vectorClock: VectorClock(
          (json['vectorClock'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v as int)),
        ),
        lastModifiedBy: json['lastModifiedBy'] as String,
        isDeleted: json['isDeleted'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  @override
  List<Object?> get props => [
        id, groupId, payerId, createdBy, description, totalAmount,
        currency, category, splitMode, date, vectorClock, lastModifiedBy,
        isDeleted, createdAt, updatedAt,
      ];
}
