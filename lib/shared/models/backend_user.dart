import 'package:flutter/foundation.dart';

/// User role enumeration matching backend roles
enum UserRole {
  admin('admin'),
  student('student'),
  guest('guest');

  const UserRole(this.value);
  final String value;

  /// Create UserRole from string value
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'student':
        return UserRole.student;
      case 'guest':
        return UserRole.guest;
      default:
        return UserRole.guest; // Default to guest for unknown roles
    }
  }

  /// Get display name for the role
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return '관리자';
      case UserRole.student:
        return '학생';
      case UserRole.guest:
        return '게스트';
    }
  }

  /// Check if this role has admin privileges
  bool get isAdmin => this == UserRole.admin;

  /// Check if this role is a student
  bool get isStudent => this == UserRole.student;
}

/// Backend user model with role and permissions information
@immutable
class BackendUser {
  final String uid;
  final String email;
  final String? name;
  final String? picture;
  final bool emailVerified;
  final UserRole role;
  final List<String> permissions;

  const BackendUser({
    required this.uid,
    required this.email,
    this.name,
    this.picture,
    required this.emailVerified,
    required this.role,
    required this.permissions,
  });

  /// Create BackendUser from JSON map
  factory BackendUser.fromJson(Map<String, dynamic> json) {
    return BackendUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      picture: json['picture'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      role: UserRole.fromString(json['role'] as String),
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'picture': picture,
      'email_verified': emailVerified,
      'role': role.value,
      'permissions': permissions,
    };
  }

  /// Create a copy with updated fields
  BackendUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? picture,
    bool? emailVerified,
    UserRole? role,
    List<String>? permissions,
  }) {
    return BackendUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      picture: picture ?? this.picture,
      emailVerified: emailVerified ?? this.emailVerified,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
    );
  }

  /// Check if user has a specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  /// Check if user has any of the given permissions
  bool hasAnyPermission(List<String> permissions) {
    return permissions.any((permission) => hasPermission(permission));
  }

  /// Check if user has all of the given permissions
  bool hasAllPermissions(List<String> permissions) {
    return permissions.every((permission) => hasPermission(permission));
  }

  /// Get display name (name or email fallback)
  String get displayName => name ?? email;

  /// Get user initials for avatar display
  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        return name![0].toUpperCase();
      }
    } else {
      return email[0].toUpperCase();
    }
  }

  /// Check if user is from the allowed school domain
  bool get isSchoolUser => email.endsWith('@pocheonil.hs.kr');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackendUser &&
        other.uid == uid &&
        other.email == email &&
        other.name == name &&
        other.picture == picture &&
        other.emailVerified == emailVerified &&
        other.role == role &&
        listEquals(other.permissions, permissions);
  }

  @override
  int get hashCode => Object.hash(
        uid,
        email,
        name,
        picture,
        emailVerified,
        role,
        Object.hashAll(permissions),
      );

  @override
  String toString() =>
      'BackendUser(uid: $uid, email: $email, name: $name, role: $role, permissions: $permissions)';
}