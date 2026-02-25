import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'database_provider.dart';

/// Provider for the current user's profile.
/// Loads from DB on first read, persists changes.
final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, UserModel?>((ref) {
  return CurrentUserNotifier(ref);
});

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  final Ref _ref;
  CurrentUserNotifier(this._ref) : super(null) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final dao = _ref.read(userDaoProvider);
    final users = await dao.getAllUsers();
    // The first user is the current/local user
    if (users.isNotEmpty) {
      state = users.first;
    }
  }

  /// Sets up the user profile (called from onboarding).
  Future<void> setupUser({
    required String username,
    required String displayName,
    String? avatarRef,
    required int avatarColorIndex,
    required String deviceId,
  }) async {
    final user = UserModel.create(
      username: username,
      displayName: displayName,
      avatarRef: avatarRef,
      avatarColorIndex: avatarColorIndex,
      deviceId: deviceId,
    );
    state = user;
    await _ref.read(userDaoProvider).upsertUser(user);
  }

  /// Updates the user profile.
  Future<void> updateUser({
    String? username,
    String? displayName,
    int? avatarColorIndex,
  }) async {
    if (state == null) return;
    state = state!.copyWith(
      username: username,
      displayName: displayName,
      avatarColorIndex: avatarColorIndex,
    );
    await _ref.read(userDaoProvider).upsertUser(state!);
  }

  void clear() => state = null;
}

/// Provider for all known users (group members encountered via P2P).
final allUsersProvider =
    StateNotifierProvider<AllUsersNotifier, List<UserModel>>((ref) {
  return AllUsersNotifier(ref);
});

class AllUsersNotifier extends StateNotifier<List<UserModel>> {
  final Ref _ref;
  AllUsersNotifier(this._ref) : super([]) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final dao = _ref.read(userDaoProvider);
    state = await dao.getAllUsers();
  }

  Future<void> addUser(UserModel user) async {
    if (state.any((u) => u.id == user.id)) return;
    state = [...state, user];
    await _ref.read(userDaoProvider).upsertUser(user);
  }

  void updateUser(UserModel user) {
    state = [
      for (final u in state)
        if (u.id == user.id) user else u,
    ];
  }

  UserModel? getUserById(String id) {
    try {
      return state.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }
}
