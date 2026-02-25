import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// A group of users sharing expenses.
///
/// Maps to the group concept from Images 1 & 2 — groups
/// contain members and own a collection of expenses.
class GroupModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String currency;
  final List<String> memberIds;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.currency,
    required this.memberIds,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a new group with auto-generated ID and timestamps.
  factory GroupModel.create({
    required String name,
    String? description,
    String currency = '₹',
    required List<String> memberIds,
    required String createdBy,
  }) {
    final now = DateTime.now();
    return GroupModel(
      id: const Uuid().v4(),
      name: name,
      description: description,
      currency: currency,
      memberIds: memberIds,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Number of members in the group.
  int get memberCount => memberIds.length;

  /// Returns a copy with an additional member.
  GroupModel addMember(String memberId) {
    if (memberIds.contains(memberId)) return this;
    return copyWith(memberIds: [...memberIds, memberId]);
  }

  /// Returns a copy without the specified member.
  GroupModel removeMember(String memberId) {
    return copyWith(memberIds: memberIds.where((id) => id != memberId).toList());
  }

  GroupModel copyWith({
    String? name,
    String? description,
    String? currency,
    List<String>? memberIds,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      memberIds: memberIds ?? this.memberIds,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'currency': currency,
        'memberIds': memberIds,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        currency: json['currency'] as String,
        memberIds: List<String>.from(json['memberIds'] as List),
        createdBy: json['createdBy'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  @override
  List<Object?> get props =>
      [id, name, description, currency, memberIds, createdBy, createdAt, updatedAt];
}
