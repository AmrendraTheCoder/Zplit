import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A local user in the Zplit system.
///
/// Schema from Images:
/// - Image 1: user_id, name, username
/// - Image 2: User_ID, User_name, username, User pfp (base64)
/// - Image 5: user_id (PK), username, display_name, avatar_ref
///
/// We use Image 5's final schema as the canonical version.
class UserModel extends Equatable {
  /// Primary key — unique across all devices.
  final String id;

  /// Unique username handle (e.g., "@amrendra").
  final String username;

  /// Display name shown in the UI (e.g., "Amrendra Singh").
  final String displayName;

  /// Reference to the user's avatar.
  /// Can be a base64-encoded image (Image 2: "User pfp (base64)")
  /// or a color index for in-app generated avatars.
  final String? avatarRef;

  /// Fallback avatar color index when no avatarRef is set.
  final int avatarColorIndex;

  /// Device ID for P2P sync — ties this user to a specific device.
  final String deviceId;

  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarRef,
    required this.avatarColorIndex,
    required this.deviceId,
    required this.createdAt,
  });

  /// Creates a new user with auto-generated ID and timestamp.
  factory UserModel.create({
    required String username,
    required String displayName,
    String? avatarRef,
    required int avatarColorIndex,
    required String deviceId,
  }) {
    return UserModel(
      id: const Uuid().v4(),
      username: username,
      displayName: displayName,
      avatarRef: avatarRef,
      avatarColorIndex: avatarColorIndex,
      deviceId: deviceId,
      createdAt: DateTime.now(),
    );
  }

  /// The avatar color for this user.
  Color get avatarColor =>
      AppColors.avatarColors[avatarColorIndex % AppColors.avatarColors.length];

  /// The initials for the avatar display.
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  UserModel copyWith({
    String? username,
    String? displayName,
    String? avatarRef,
    int? avatarColorIndex,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarRef: avatarRef ?? this.avatarRef,
      avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
      deviceId: deviceId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'avatarRef': avatarRef,
        'avatarColorIndex': avatarColorIndex,
        'deviceId': deviceId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        avatarRef: json['avatarRef'] as String?,
        avatarColorIndex: json['avatarColorIndex'] as int,
        deviceId: json['deviceId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  List<Object?> get props =>
      [id, username, displayName, avatarRef, avatarColorIndex, deviceId, createdAt];
}
