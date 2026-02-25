import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

/// Provider for the current user's profile.
///
/// Initially null — set after onboarding when the user
/// enters their name and picks an avatar.
final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, UserModel?>((ref) {
  return CurrentUserNotifier();
});

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  CurrentUserNotifier() : super(null);

  /// Sets up the user profile (called from onboarding).
  void setupUser({
    required String username,
    required String displayName,
    String? avatarRef,
    required int avatarColorIndex,
    required String deviceId,
  }) {
    state = UserModel.create(
      username: username,
      displayName: displayName,
      avatarRef: avatarRef,
      avatarColorIndex: avatarColorIndex,
      deviceId: deviceId,
    );
  }

  /// Updates the user profile.
  void updateUser({String? username, String? displayName, int? avatarColorIndex}) {
    if (state == null) return;
    state = state!.copyWith(
      username: username,
      displayName: displayName,
      avatarColorIndex: avatarColorIndex,
    );
  }

  /// Clears the user (logout equivalent).
  void clear() => state = null;
}

/// Provider for all known users (group members encountered via P2P).
final allUsersProvider =
    StateNotifierProvider<AllUsersNotifier, List<UserModel>>((ref) {
  return AllUsersNotifier();
});

class AllUsersNotifier extends StateNotifier<List<UserModel>> {
  AllUsersNotifier() : super([]);

  /// Adds a user discovered via P2P sync.
  void addUser(UserModel user) {
    if (state.any((u) => u.id == user.id)) return;
    state = [...state, user];
  }

  /// Updates a known user's info.
  void updateUser(UserModel user) {
    state = [
      for (final u in state)
        if (u.id == user.id) user else u,
    ];
  }

  /// Gets a user by ID, or null.
  UserModel? getUserById(String id) {
    try {
      return state.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }
}
