import 'package:flutter_test/flutter_test.dart';
import 'package:zplit/models/group_model.dart';

void main() {
  GroupModel makeGroup({
    String id = 'group-1',
    List<String> memberIds = const ['user-a', 'user-b'],
  }) {
    return GroupModel(
      id: id,
      name: 'Trip to Goa',
      description: 'Beach vacation',
      currency: 'INR',
      memberIds: memberIds,
      createdBy: 'user-a',
      createdAt: DateTime(2026, 2, 25),
      updatedAt: DateTime(2026, 2, 25),
    );
  }

  group('GroupModel.create', () {
    test('generates unique ID and timestamps', () {
      final group = GroupModel.create(
        name: 'Test Group',
        memberIds: ['user-a'],
        createdBy: 'user-a',
      );

      expect(group.id, isNotEmpty);
      expect(group.name, 'Test Group');
      expect(group.currency, '₹');
      expect(group.memberIds, ['user-a']);
      expect(group.createdAt, isNotNull);
    });

    test('uses provided currency', () {
      final group = GroupModel.create(
        name: 'USD Group',
        currency: 'USD',
        memberIds: ['user-a'],
        createdBy: 'user-a',
      );

      expect(group.currency, 'USD');
    });
  });

  group('addMember', () {
    test('adds a new member', () {
      final group = makeGroup(memberIds: ['user-a']);
      final updated = group.addMember('user-b');

      expect(updated.memberIds, ['user-a', 'user-b']);
      expect(updated.memberCount, 2);
    });

    test('does not duplicate existing members', () {
      final group = makeGroup(memberIds: ['user-a', 'user-b']);
      final updated = group.addMember('user-a');

      expect(updated.memberIds, ['user-a', 'user-b']);
      expect(updated, group); // same instance since no change
    });
  });

  group('removeMember', () {
    test('removes an existing member', () {
      final group = makeGroup(memberIds: ['user-a', 'user-b', 'user-c']);
      final updated = group.removeMember('user-b');

      expect(updated.memberIds, ['user-a', 'user-c']);
      expect(updated.memberCount, 2);
    });

    test('handles removing non-existent member gracefully', () {
      final group = makeGroup(memberIds: ['user-a']);
      final updated = group.removeMember('user-z');

      expect(updated.memberIds, ['user-a']);
    });
  });

  group('memberCount', () {
    test('returns correct count', () {
      expect(makeGroup(memberIds: []).memberCount, 0);
      expect(makeGroup(memberIds: ['a']).memberCount, 1);
      expect(makeGroup(memberIds: ['a', 'b', 'c']).memberCount, 3);
    });
  });

  group('copyWith', () {
    test('creates copy with changed fields', () {
      final group = makeGroup();
      final copy = group.copyWith(name: 'New Name', currency: 'USD');

      expect(copy.id, group.id);
      expect(copy.name, 'New Name');
      expect(copy.currency, 'USD');
      expect(copy.description, group.description);
    });
  });

  group('JSON serialization', () {
    test('toJson → fromJson roundtrip', () {
      final group = makeGroup();
      final json = group.toJson();
      final restored = GroupModel.fromJson(json);

      expect(restored.id, group.id);
      expect(restored.name, group.name);
      expect(restored.description, group.description);
      expect(restored.currency, group.currency);
      expect(restored.memberIds, group.memberIds);
      expect(restored.createdBy, group.createdBy);
    });
  });

  group('Equatable', () {
    test('identical groups are equal', () {
      final a = makeGroup();
      final b = makeGroup();
      expect(a, equals(b));
    });

    test('different groups are not equal', () {
      final a = makeGroup(id: 'g1');
      final b = makeGroup(id: 'g2');
      expect(a, isNot(equals(b)));
    });
  });
}
