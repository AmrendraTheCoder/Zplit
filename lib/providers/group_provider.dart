import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';
import 'database_provider.dart';

/// Provider for all groups.
final groupsProvider =
    StateNotifierProvider<GroupsNotifier, List<GroupModel>>((ref) {
  return GroupsNotifier(ref);
});

class GroupsNotifier extends StateNotifier<List<GroupModel>> {
  final Ref _ref;
  GroupsNotifier(this._ref) : super([]) {
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final dao = _ref.read(groupDaoProvider);
    state = await dao.getAllGroups();
  }

  Future<void> createGroup({
    required String name,
    String? description,
    String currency = 'INR',
    required List<String> memberIds,
    required String createdBy,
  }) async {
    final group = GroupModel.create(
      name: name,
      description: description,
      currency: currency,
      memberIds: memberIds,
      createdBy: createdBy,
    );
    state = [...state, group];
    await _ref.read(groupDaoProvider).upsertGroup(group);
  }

  Future<void> addMember(String groupId, String memberId) async {
    state = [
      for (final g in state)
        if (g.id == groupId) g.addMember(memberId) else g,
    ];
    final updated = state.firstWhere((g) => g.id == groupId);
    await _ref.read(groupDaoProvider).upsertGroup(updated);
  }

  Future<void> removeMember(String groupId, String memberId) async {
    state = [
      for (final g in state)
        if (g.id == groupId) g.removeMember(memberId) else g,
    ];
    final updated = state.firstWhere((g) => g.id == groupId);
    await _ref.read(groupDaoProvider).upsertGroup(updated);
  }

  Future<void> deleteGroup(String groupId) async {
    state = state.where((g) => g.id != groupId).toList();
    await _ref.read(groupDaoProvider).deleteGroup(groupId);
  }
}
