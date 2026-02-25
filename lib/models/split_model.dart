import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// A single participant's debt within an expense.
///
/// Field mapping from official schema images:
///
/// | Our Field     | Image 2 (Handwritten) | Image 4 (ER)      | Image 5 (Final)  |
/// |---------------|----------------------|--------------------|-------------------|
/// | id            | Split_ID             | id (PK)            | split_id          |
/// | transactionId | Tr_ID                | transaction_id(FK) | expense_id        |
/// | debtorId      | Debtor_ID            | debtor_id (FK)     | debtor_id         |
/// | owedShare     | Debt_Amount          | owed_share         | amount            |
/// | rawInput      | —                    | raw_input          | —                 |
/// | version       | —                    | —                  | version           |
/// | isDeleted     | —                    | —                  | is_deleted        |
///
/// Key design from Image 4:
/// - `raw_input` stores the user's intent (e.g., 50 for 50%)
/// - `owed_share` is the calculated result
/// - The split_mode lives on the parent Expense, not here
class SplitModel extends Equatable {
  /// Primary key.
  final String id;

  /// FK to the parent expense/transaction (Image 4: transaction_id).
  final String transactionId;

  /// FK to the user who owes money (Image 4: debtor_id).
  /// Note: This is the DEBTOR, not just any user.
  final String debtorId;

  /// The calculated amount this debtor owes (Image 4: owed_share).
  final double owedShare;

  /// The user's original input intent (Image 4: raw_input).
  ///
  /// Interpretation depends on the parent Expense's splitMode:
  /// - EQUAL: Ignored (set to 0)
  /// - PERCENT: The percentage (e.g., 50.0 = 50%)
  /// - EXACT: The exact amount (e.g., 800.0)
  final double rawInput;

  /// Version counter for sync (Image 5).
  final int version;

  /// Soft delete flag for sync (Image 5).
  final bool isDeleted;

  /// Whether this split has been settled/paid.
  final bool isPaid;

  const SplitModel({
    required this.id,
    required this.transactionId,
    required this.debtorId,
    required this.owedShare,
    required this.rawInput,
    this.version = 1,
    this.isDeleted = false,
    this.isPaid = false,
  });

  /// Creates a new split with auto-generated ID.
  factory SplitModel.create({
    required String transactionId,
    required String debtorId,
    required double owedShare,
    double rawInput = 0,
  }) {
    return SplitModel(
      id: const Uuid().v4(),
      transactionId: transactionId,
      debtorId: debtorId,
      owedShare: owedShare,
      rawInput: rawInput,
    );
  }

  SplitModel copyWith({
    double? owedShare,
    double? rawInput,
    int? version,
    bool? isDeleted,
    bool? isPaid,
  }) {
    return SplitModel(
      id: id,
      transactionId: transactionId,
      debtorId: debtorId,
      owedShare: owedShare ?? this.owedShare,
      rawInput: rawInput ?? this.rawInput,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transactionId': transactionId,
        'debtorId': debtorId,
        'owedShare': owedShare,
        'rawInput': rawInput,
        'version': version,
        'isDeleted': isDeleted,
        'isPaid': isPaid,
      };

  factory SplitModel.fromJson(Map<String, dynamic> json) => SplitModel(
        id: json['id'] as String,
        transactionId: json['transactionId'] as String,
        debtorId: json['debtorId'] as String,
        owedShare: (json['owedShare'] as num).toDouble(),
        rawInput: (json['rawInput'] as num).toDouble(),
        version: json['version'] as int? ?? 1,
        isDeleted: json['isDeleted'] as bool? ?? false,
        isPaid: json['isPaid'] as bool? ?? false,
      );

  @override
  List<Object?> get props =>
      [id, transactionId, debtorId, owedShare, rawInput, version, isDeleted, isPaid];
}
