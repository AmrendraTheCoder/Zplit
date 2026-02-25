import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/database.dart';
import '../db/daos.dart';

/// Global database instance provider.
final databaseProvider = Provider<ZplitDatabase>((ref) {
  final db = ZplitDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// DAO providers — derived from the database.
final userDaoProvider = Provider<UserDao>((ref) {
  return UserDao(ref.watch(databaseProvider));
});

final groupDaoProvider = Provider<GroupDao>((ref) {
  return GroupDao(ref.watch(databaseProvider));
});

final expenseDaoProvider = Provider<ExpenseDao>((ref) {
  return ExpenseDao(ref.watch(databaseProvider));
});

final splitDaoProvider = Provider<SplitDao>((ref) {
  return SplitDao(ref.watch(databaseProvider));
});
