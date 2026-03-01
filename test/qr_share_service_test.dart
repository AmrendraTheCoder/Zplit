import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zplit/models/group_model.dart';
import 'package:zplit/models/user_model.dart';
import 'package:zplit/services/qr_share_service.dart';

void main() {
  const service = QrShareService();

  GroupModel makeGroup() => GroupModel(
    id: 'group-123',
    name: 'Trip to Goa',
    currency: 'INR',
    memberIds: ['user-a', 'user-b'],
    createdBy: 'user-a',
    createdAt: DateTime(2026, 2, 25),
    updatedAt: DateTime(2026, 2, 25),
  );

  UserModel makeUser() => UserModel(
    id: 'user-a',
    username: 'amrendra',
    displayName: 'Amrendra Singh',
    avatarColorIndex: 0,
    deviceId: 'device-1',
    createdAt: DateTime(2026, 2, 25),
  );

  group('QrShareService', () {
    test('encodeGroupInvite produces valid JSON', () {
      final group = makeGroup();
      final user = makeUser();
      final data = service.encodeGroupInvite(group, user);
      expect(() => jsonDecode(data), returnsNormally);

      final parsed = jsonDecode(data) as Map<String, dynamic>;
      expect(parsed['type'], 'zplit_invite');
      expect(parsed['groupId'], 'group-123');
      expect(parsed['groupName'], 'Trip to Goa');
      expect(parsed['inviterName'], 'Amrendra Singh');
    });

    test('encode → decode roundtrip', () {
      final group = makeGroup();
      final user = makeUser();
      final data = service.encodeGroupInvite(group, user);
      final invite = service.decodeGroupInvite(data);

      expect(invite.groupId, 'group-123');
      expect(invite.groupName, 'Trip to Goa');
      expect(invite.currency, 'INR');
      expect(invite.inviterId, 'user-a');
      expect(invite.inviterName, 'Amrendra Singh');
    });

    test('decodeGroupInvite throws on invalid JSON', () {
      expect(
        () => service.decodeGroupInvite('not json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('decodeGroupInvite throws on wrong type', () {
      final badData = jsonEncode({'type': 'not_zplit', 'groupId': '123'});
      expect(
        () => service.decodeGroupInvite(badData),
        throwsA(isA<FormatException>()),
      );
    });

    test('isValidInvite returns true for valid data', () {
      final group = makeGroup();
      final user = makeUser();
      final data = service.encodeGroupInvite(group, user);
      expect(service.isValidInvite(data), true);
    });

    test('isValidInvite returns false for invalid data', () {
      expect(service.isValidInvite('garbage'), false);
      expect(service.isValidInvite('{"type":"other"}'), false);
    });
  });

  group('GroupInvite', () {
    test('toJson → fromJson roundtrip', () {
      final invite = GroupInvite(
        groupId: 'g1',
        groupName: 'Test',
        currency: 'USD',
        inviterId: 'u1',
        inviterName: 'Alice',
        createdAt: DateTime(2026, 3, 1),
      );

      final json = invite.toJson();
      final restored = GroupInvite.fromJson(json);

      expect(restored.groupId, invite.groupId);
      expect(restored.groupName, invite.groupName);
      expect(restored.currency, invite.currency);
      expect(restored.inviterId, invite.inviterId);
      expect(restored.inviterName, invite.inviterName);
    });

    test('fromJson defaults currency to INR', () {
      final json = {
        'type': 'zplit_invite',
        'groupId': 'g1',
        'groupName': 'Test',
        'inviterId': 'u1',
        'inviterName': 'Alice',
        'createdAt': DateTime(2026, 3, 1).toIso8601String(),
      };
      final invite = GroupInvite.fromJson(json);
      expect(invite.currency, 'INR');
    });
  });
}
