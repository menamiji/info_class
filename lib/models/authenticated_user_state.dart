import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../shared/models/backend_user.dart';

/// Represents the complete authentication state including both Firebase and backend user data
@immutable
class AuthenticatedUserState {
  final User? firebaseUser;
  final BackendUser? backendUser;
  final UserRole role;
  final bool isAuthenticated;

  const AuthenticatedUserState._({
    this.firebaseUser,
    this.backendUser,
    required this.role,
    required this.isAuthenticated,
  });

  /// Create state for unauthenticated user
  const AuthenticatedUserState.notAuthenticated()
      : firebaseUser = null,
        backendUser = null,
        role = UserRole.guest,
        isAuthenticated = false;

  /// Create state for authenticated user with role
  const AuthenticatedUserState.authenticated(
    this.firebaseUser,
    this.backendUser,
  )   : role = UserRole.guest,
        isAuthenticated = true;

  /// Create state with specific role
  AuthenticatedUserState.withRole(
    this.firebaseUser,
    this.backendUser,
    this.role,
  ) : isAuthenticated = firebaseUser != null && backendUser != null;

  /// Get display name from available user data
  String get displayName {
    if (backendUser?.name != null && backendUser!.name!.isNotEmpty) {
      return backendUser!.name!;
    }
    if (firebaseUser?.displayName != null && firebaseUser!.displayName!.isNotEmpty) {
      return firebaseUser!.displayName!;
    }
    return backendUser?.email ?? firebaseUser?.email ?? '사용자';
  }

  /// Get email from available user data
  String? get email => backendUser?.email ?? firebaseUser?.email;

  /// Get profile picture URL
  String? get photoURL => firebaseUser?.photoURL ?? backendUser?.picture;

  /// Check if user has admin privileges
  bool get isAdmin => role.isAdmin;

  /// Check if user is a student
  bool get isStudent => role.isStudent;

  /// Check if user is from school domain
  bool get isSchoolUser => backendUser?.isSchoolUser ?? false;

  /// Create copy with updated fields
  AuthenticatedUserState copyWith({
    User? firebaseUser,
    BackendUser? backendUser,
    UserRole? role,
    bool? isAuthenticated,
  }) {
    return AuthenticatedUserState.withRole(
      firebaseUser ?? this.firebaseUser,
      backendUser ?? this.backendUser,
      role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthenticatedUserState &&
        other.firebaseUser?.uid == firebaseUser?.uid &&
        other.backendUser?.uid == backendUser?.uid &&
        other.role == role &&
        other.isAuthenticated == isAuthenticated;
  }

  @override
  int get hashCode => Object.hash(
        firebaseUser?.uid,
        backendUser?.uid,
        role,
        isAuthenticated,
      );

  @override
  String toString() =>
      'AuthenticatedUserState(firebaseUser: ${firebaseUser?.uid}, backendUser: ${backendUser?.uid}, role: $role, isAuthenticated: $isAuthenticated)';
}