import 'dart:convert';
import 'package:drift/drift.dart';
import 'database.dart';
import '../models/user_model.dart' as model;
import '../models/group_model.dart' as model;
import '../models/expense_model.dart' as model;
import '../models/split_model.dart' as model;
import '../utils/vector_clock.dart';

// ═══════════════════════════════════════════════════════
// USER DAO
// ═══════════════════════════════════════════════════════

class UserDao {
  final ZplitDatabase _db;
  UserDao(this._db);

  /// Watch all users as a reactive stream.
  Stream<List<model.UserModel>> watchAllUsers() {
    return _db.select(_db.users).watch().map(
          (rows) => rows.map(_userFromRow).toList(),
        );
  }

  /// Get all users.
  Future<List<model.UserModel>> getAllUsers() async {
    final rows = await _db.select(_db.users).get();
    return rows.map(_userFromRow).toList();
  }

  /// Get user by ID.
  Future<model.UserModel?> getUserById(String id) async {
    final query = _db.select(_db.users)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _userFromRow(row) : null;
  }

  /// Insert or update a user.
  Future<void> upsertUser(model.UserModel user) async {
    await _db.into(_db.users).insertOnConflictUpdate(
          UsersCompanion.insert(
            id: user.id,
            username: user.username,
            displayName: user.displayName,
            avatarRef: Value(user.avatarRef),
            avatarColorIndex: Value(user.avatarColorIndex),
            deviceId: user.deviceId,
            createdAt: user.createdAt,
          ),
        );
  }

  model.UserModel _userFromRow(User row) {
    return model.UserModel(
      id: row.id,
      username: row.username,
      displayName: row.displayName,
      avatarRef: row.avatarRef,
      avatarColorIndex: row.avatarColorIndex,
      deviceId: row.deviceId,
      createdAt: row.createdAt,
    );
  }
}

// ═══════════════════════════════════════════════════════
// GROUP DAO
// ═══════════════════════════════════════════════════════

class GroupDao {
  final ZplitDatabase _db;
  GroupDao(this._db);

  Stream<List<model.GroupModel>> watchAllGroups() {
    return _db.select(_db.groups).watch().map(
          (rows) => rows.map(_groupFromRow).toList(),
        );
  }

  Future<List<model.GroupModel>> getAllGroups() async {
    final rows = await _db.select(_db.groups).get();
    return rows.map(_groupFromRow).toList();
  }

  Future<model.GroupModel?> getGroupById(String id) async {
    final query = _db.select(_db.groups)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _groupFromRow(row) : null;
  }

  Future<void> upsertGroup(model.GroupModel group) async {
    await _db.into(_db.groups).insertOnConflictUpdate(
          GroupsCompanion.insert(
            id: group.id,
            name: group.name,
            description: Value(group.description),
            currency: Value(group.currency),
            memberIds: jsonEncode(group.memberIds),
            createdBy: group.createdBy,
            createdAt: group.createdAt,
          ),
        );
  }

  Future<void> deleteGroup(String id) async {
    await (_db.delete(_db.groups)..where((t) => t.id.equals(id))).go();
  }

  model.GroupModel _groupFromRow(Group row) {
    final memberIds = (jsonDecode(row.memberIds) as List).cast<String>();
    return model.GroupModel(
      id: row.id,
      name: row.name,
      description: row.description,
      currency: row.currency,
      memberIds: memberIds,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
      updatedAt: row.createdAt, // Groups table uses createdAt as proxy
    );
  }
}

// ═══════════════════════════════════════════════════════
// EXPENSE DAO
// ═══════════════════════════════════════════════════════

class ExpenseDao {
  final ZplitDatabase _db;
  ExpenseDao(this._db);

  /// Watch expenses for a group (excluding soft-deleted).
  Stream<List<model.ExpenseModel>> watchGroupExpenses(String groupId) {
    return (_db.select(_db.expenses)
          ..where((t) => t.groupId.equals(groupId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch()
        .map((rows) => rows.map(_expenseFromRow).toList());
  }

  Future<List<model.ExpenseModel>> getAllExpenses() async {
    final rows = await _db.select(_db.expenses).get();
    return rows.map(_expenseFromRow).toList();
  }

  Future<model.ExpenseModel?> getExpenseById(String id) async {
    final query = _db.select(_db.expenses)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _expenseFromRow(row) : null;
  }

  Future<void> upsertExpense(model.ExpenseModel expense) async {
    await _db.into(_db.expenses).insertOnConflictUpdate(
          ExpensesCompanion.insert(
            id: expense.id,
            groupId: expense.groupId,
            payerId: expense.payerId,
            createdBy: expense.createdBy,
            totalAmount: expense.totalAmount,
            currency: Value(expense.currency),
            description: expense.description,
            category: Value(expense.category.name),
            splitMode: Value(expense.splitMode.name),
            date: expense.date,
            vectorClock: Value(jsonEncode(expense.vectorClock.clock)),
            lastModifiedBy: expense.lastModifiedBy,
            isDeleted: Value(expense.isDeleted),
            createdAt: expense.createdAt,
            updatedAt: expense.updatedAt,
          ),
        );
  }

  Future<void> softDeleteExpense(String id) async {
    await (_db.update(_db.expenses)..where((t) => t.id.equals(id)))
        .write(const ExpensesCompanion(isDeleted: Value(true)));
  }

  model.ExpenseModel _expenseFromRow(Expense row) {
    return model.ExpenseModel(
      id: row.id,
      groupId: row.groupId,
      payerId: row.payerId,
      createdBy: row.createdBy,
      description: row.description,
      totalAmount: row.totalAmount,
      currency: row.currency,
      category: model.ExpenseCategory.values.firstWhere(
        (e) => e.name == row.category,
        orElse: () => model.ExpenseCategory.other,
      ),
      splitMode: model.SplitMode.values.firstWhere(
        (e) => e.name == row.splitMode,
        orElse: () => model.SplitMode.equal,
      ),
      date: row.date,
      vectorClock: VectorClock(
        (jsonDecode(row.vectorClock) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int)),
      ),
      lastModifiedBy: row.lastModifiedBy,
      isDeleted: row.isDeleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

// ═══════════════════════════════════════════════════════
// SPLIT DAO
// ═══════════════════════════════════════════════════════

class SplitDao {
  final ZplitDatabase _db;
  SplitDao(this._db);

  /// Watch splits for a transaction (excluding soft-deleted).
  Stream<List<model.SplitModel>> watchTransactionSplits(String transactionId) {
    return (_db.select(_db.splits)
          ..where((t) =>
              t.transactionId.equals(transactionId) &
              t.isDeleted.equals(false)))
        .watch()
        .map((rows) => rows.map(_splitFromRow).toList());
  }

  Future<List<model.SplitModel>> getSplitsForTransaction(
      String transactionId) async {
    final query = _db.select(_db.splits)
      ..where((t) => t.transactionId.equals(transactionId));
    final rows = await query.get();
    return rows.map(_splitFromRow).toList();
  }

  Future<List<model.SplitModel>> getAllSplits() async {
    final rows = await _db.select(_db.splits).get();
    return rows.map(_splitFromRow).toList();
  }

  Future<void> upsertSplits(List<model.SplitModel> splits) async {
    await _db.batch((batch) {
      for (final split in splits) {
        batch.insert(
          _db.splits,
          SplitsCompanion.insert(
            id: split.id,
            transactionId: split.transactionId,
            debtorId: split.debtorId,
            owedShare: split.owedShare,
            rawInput: Value(split.rawInput),
            version: Value(split.version),
            isDeleted: Value(split.isDeleted),
            isPaid: Value(split.isPaid),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> softDeleteSplitsForTransaction(String transactionId) async {
    await (_db.update(_db.splits)
          ..where((t) => t.transactionId.equals(transactionId)))
        .write(const SplitsCompanion(isDeleted: Value(true)));
  }

  model.SplitModel _splitFromRow(Split row) {
    return model.SplitModel(
      id: row.id,
      transactionId: row.transactionId,
      debtorId: row.debtorId,
      owedShare: row.owedShare,
      rawInput: row.rawInput,
      version: row.version,
      isDeleted: row.isDeleted,
      isPaid: row.isPaid,
    );
  }
}
