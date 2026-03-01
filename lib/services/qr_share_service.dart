import 'dart:convert';
import '../models/group_model.dart';
import '../models/user_model.dart';

/// Data structure for a group invite shared via QR code.
class GroupInvite {
  final String groupId;
  final String groupName;
  final String currency;
  final String inviterId;
  final String inviterName;
  final DateTime createdAt;

  const GroupInvite({
    required this.groupId,
    required this.groupName,
    required this.currency,
    required this.inviterId,
    required this.inviterName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'v': 1, // version for future compatibility
    'type': 'zplit_invite',
    'groupId': groupId,
    'groupName': groupName,
    'currency': currency,
    'inviterId': inviterId,
    'inviterName': inviterName,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    if (json['type'] != 'zplit_invite') {
      throw const FormatException('Not a valid Zplit invite');
    }
    return GroupInvite(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      currency: json['currency'] as String? ?? 'INR',
      inviterId: json['inviterId'] as String,
      inviterName: json['inviterName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Service for encoding/decoding group invite data for QR sharing.
class QrShareService {
  const QrShareService();

  /// Encodes a group invite into a JSON string for QR code display.
  String encodeGroupInvite(GroupModel group, UserModel inviter) {
    final invite = GroupInvite(
      groupId: group.id,
      groupName: group.name,
      currency: group.currency,
      inviterId: inviter.id,
      inviterName: inviter.displayName,
      createdAt: DateTime.now(),
    );
    return jsonEncode(invite.toJson());
  }

  /// Decodes a scanned QR string back into a GroupInvite.
  /// Throws [FormatException] on invalid data.
  GroupInvite decodeGroupInvite(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return GroupInvite.fromJson(json);
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Invalid invite data: $e');
    }
  }

  /// Validates that an invite is well-formed.
  bool isValidInvite(String data) {
    try {
      decodeGroupInvite(data);
      return true;
    } catch (_) {
      return false;
    }
  }
}
