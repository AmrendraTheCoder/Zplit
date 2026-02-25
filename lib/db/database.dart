import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ═══════════════════════════════════════════════════════
// TABLE DEFINITIONS — matching official PR schema (Images 3-5)
// ═══════════════════════════════════════════════════════

/// Users table (Image 5: user_id PK, username, display_name, avatar_ref)
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get username => text()();
  TextColumn get displayName => text()();
  TextColumn get avatarRef => text().nullable()();
  IntColumn get avatarColorIndex => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Groups table
class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  /// Stored as JSON array of user IDs
  TextColumn get memberIds => text()();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Expenses/Transactions table (Image 3 schema, exact column match)
///
/// | Column          | Type      | Notes                              |
/// |-----------------|-----------|------------------------------------|
/// | id              | UUID/TEXT | Primary Key                        |
/// | group_id        | UUID/TEXT | Links to Group                     |
/// | payer_id        | UUID/TEXT | Who paid                           |
/// | created_by      | UUID/TEXT | Who created the record             |
/// | total_amount    | REAL      | The total value                    |
/// | currency        | TEXT      | "INR", "USD"                       |
/// | description     | TEXT      | "Dinner at Taj"                    |
/// | category        | TEXT      | Enum string                        |
/// | split_mode      | TEXT      | EQUAL, PERCENT, EXACT (Image 3)    |
/// | date            | DATETIME  | When the expense occurred           |
/// | vector_clock    | JSON/TEXT | Crucial for Sync (Image 3)          |
/// | last_modified_by| UUID/TEXT | For LWW conflict resolution         |
/// | is_deleted      | BOOLEAN   | Soft delete for sync                |
/// | has_conflict    | BOOLEAN   | Sync conflict flag                  |
/// | conflict_details| TEXT      | Human-readable conflict info        |
/// | created_at      | DATETIME  | Record creation time                |
/// | updated_at      | DATETIME  | Last update time                    |
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get payerId => text().references(Users, #id)();
  TextColumn get createdBy => text()();
  RealColumn get totalAmount => real()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get description => text()();
  TextColumn get category => text().withDefault(const Constant('other'))();
  TextColumn get splitMode => text().withDefault(const Constant('equal'))();
  DateTimeColumn get date => dateTime()();
  /// Vector clock stored as JSON: {"A": 2, "B": 1}
  TextColumn get vectorClock => text().withDefault(const Constant('{}'))();
  TextColumn get lastModifiedBy => text()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get hasConflict => boolean().withDefault(const Constant(false))();
  TextColumn get conflictDetails => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Splits table (Image 4: id PK, transaction_id FK, debtor_id FK,
/// owed_share, raw_input) + Image 5 additions (version, is_deleted)
class Splits extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(Expenses, #id)();
  TextColumn get debtorId => text().references(Users, #id)();
  RealColumn get owedShare => real()();
  RealColumn get rawInput => real().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ═══════════════════════════════════════════════════════
// DATABASE
// ═══════════════════════════════════════════════════════

@DriftDatabase(tables: [Users, Groups, Expenses, Splits])
class ZplitDatabase extends _$ZplitDatabase {
  ZplitDatabase() : super(_openConnection());

  /// For testing with an in-memory database
  ZplitDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'zplit.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
