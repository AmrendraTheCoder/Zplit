import 'package:drift/drift.dart';

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

/// Expenses/Transactions table (Image 3 schema)
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get payerId => text()();
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

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Splits table (Image 4 + Image 5)
class Splits extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text()();
  TextColumn get debtorId => text()();
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
  ZplitDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
