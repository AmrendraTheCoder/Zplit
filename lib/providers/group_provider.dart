import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';

/// Provider for all groups the user belongs to.
final groupsProvider =
    StateNotifierProvider<GroupsNotifier, List<GroupModel>>((ref) {
  return GroupsNotifier();
});

class GroupsNotifier extends StateNotifier<List<GroupModel>> {
  GroupsNotifier() : super([]);

  /// Creates a new group and adds it to the list.
  void createGroup({
    required String name,
    String? description,
    String currency = '₹',
    required List<String> memberIds,
    required String createdBy,
  }) {
    final group = GroupModel.create(
      name: name,
      description: description,
      currency: currency,
      memberIds: memberIds,
      createdBy: createdBy,
    );
    state = [...state, group];
  }

  /// Adds an existing group (e.g., received via P2P invite).
  void addGroup(GroupModel group) {
    if (state.any((g) => g.id == group.id)) return;
    state = [...state, group];
  }

  /// Updates a group's properties.
  void updateGroup(GroupModel group) {
    state = [
      for (final g in state)
        if (g.id == group.id) group else g,
    ];
  }

  /// Adds a member to a group.
  void addMember(String groupId, String userId) {
    state = [
      for (final g in state)
        if (g.id == groupId && !g.memberIds.contains(userId))
          g.copyWith(memberIds: [...g.memberIds, userId])
        else
          g,
    ];
  }

  /// Removes a member from a group.
  void removeMember(String groupId, String userId) {
    state = [
      for (final g in state)
        if (g.id == groupId)
          g.copyWith(memberIds: g.memberIds.where((id) => id != userId).toList())
        else
          g,
    ];
  }

  /// Deletes a group.
  void deleteGroup(String groupId) {
    state = state.where((g) => g.id != groupId).toList();
  }

  /// Gets a group by ID, or null.
  GroupModel? getGroupById(String id) {
    try {
      return state.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
