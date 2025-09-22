import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';
import '../shared/data/api_client.dart';
import '../shared/services/token_storage.dart';
import '../shared/models/backend_user.dart';
import '../shared/models/user_info_response.dart';
import '../models/authenticated_user_state.dart';

part 'auth_provider.g.dart';

/// Authentication state management using Riverpod
///
/// Provides reactive authentication state with proper loading/error handling
/// while preserving the critical Google Sign-In session cleanup logic
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<User?> build() async {
    // Set up automatic state synchronization with Firebase auth state changes
    ref.listen(authStateStreamProvider, (previous, next) {
      next.when(
        data: (user) {
          // Only update if the user actually changed to avoid unnecessary rebuilds
          if (state.value != user) {
            state = AsyncData(user);
          }
        },
        loading: () {
          // Keep current state during stream loading
        },
        error: (error, stack) {
          state = AsyncError(error, stack);
        },
      );
    });

    // Return initial authentication state
    return AuthService.currentUser;
  }

  /// Sign in with Google and exchange for JWT token
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();

    try {
      // Step 1: Firebase authentication
      final user = await AuthService.signInWithGoogle();
      if (user == null) {
        // User cancelled the sign-in
        state = AsyncError(
          Exception('로그인이 취소되었습니다.'),
          StackTrace.current,
        );
        return;
      }

      // Step 2: Get Firebase ID token for backend exchange
      final firebaseToken = await user.getIdToken();
      if (firebaseToken == null) {
        state = AsyncError(
          Exception('Firebase 토큰을 가져올 수 없습니다.'),
          StackTrace.current,
        );
        return;
      }

      // Step 3: Exchange Firebase token for JWT
      final jwtResponse = await ApiClient.exchangeFirebaseToken(firebaseToken);

      if (!jwtResponse.ok || jwtResponse.data == null) {
        // Backend authentication failed
        await AuthService.signOut(); // Clean up Firebase auth
        state = AsyncError(
          Exception(jwtResponse.error?.message ?? '백엔드 인증에 실패했습니다.'),
          StackTrace.current,
        );
        return;
      }

      // Step 4: Store JWT token and user data
      final tokenData = jwtResponse.data!;
      await TokenStorage.saveToken(
        jwtToken: tokenData.jwtToken,
        userRole: tokenData.user.role.value,
        userEmail: tokenData.user.email,
        expiryTime: tokenData.expiresAt,
      );

      // Step 5: Update state with successful authentication
      state = AsyncData(user);

    } on FirebaseAuthException catch (e) {
      state = AsyncError(
        Exception('Firebase 인증 오류: ${e.message}'),
        StackTrace.current,
      );
    } catch (e) {
      state = AsyncError(
        Exception('로그인 처리 중 오류 발생: $e'),
        StackTrace.current,
      );
    }
  }

  /// Sign out from all authentication providers and clear tokens
  Future<void> signOut() async {
    state = const AsyncLoading();

    try {
      // Clear JWT token and backend auth data
      await TokenStorage.clearToken();

      // Sign out from Firebase
      await AuthService.signOut();

      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(
        Exception('로그아웃 처리 중 오류 발생: $e'),
        StackTrace.current,
      );
    }
  }
}

/// Stream provider for Firebase auth state changes
/// This enables automatic synchronization with Firebase authentication state
@riverpod
Stream<User?> authStateStream(Ref ref) {
  return AuthService.authStateChanges;
}

/// Computed provider for current user
/// Returns null if not authenticated, loading, or error state
@riverpod
User? currentUser(Ref ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
}

/// Computed provider for authentication status
/// Returns true only when user is authenticated and state is loaded
@riverpod
bool isAuthenticated(Ref ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
}

/// Computed provider for loading state
/// Returns true when authentication operations are in progress
@riverpod
bool isAuthLoading(Ref ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isLoading;
}

/// Computed provider for error state
/// Returns error message if authentication failed, null otherwise
@riverpod
String? authError(Ref ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.when(
    data: (_) => null,
    loading: () => null,
    error: (error, _) => error.toString(),
  );
}

/// Provider for backend user information with role
/// Returns null if not authenticated or JWT not available
@riverpod
Future<BackendUser?> backendUser(Ref ref) async {
  // Watch authentication state to trigger refresh when user changes
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (firebaseUser) async {
      if (firebaseUser == null) return null;

      // Check if we have valid JWT token
      final hasToken = await TokenStorage.hasValidToken();
      if (!hasToken) return null;

      try {
        // Get current user info from backend
        final response = await ApiClient.getCurrentUser();
        if (response.ok && response.data != null) {
          return response.data!;
        }
        return null;
      } catch (e) {
        // If backend call fails, return null (will trigger re-authentication)
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
}

/// Provider for user role
/// Returns UserRole.guest if not authenticated or role not available
@riverpod
Future<UserRole> userRole(Ref ref) async {
  final backendUserData = await ref.watch(backendUserProvider.future);
  return backendUserData?.role ?? UserRole.guest;
}

/// Provider for JWT token validity
/// Returns true if valid JWT token exists
@riverpod
Future<bool> hasValidJwt(Ref ref) async {
  // Watch auth state to trigger refresh when user changes
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (firebaseUser) async {
      if (firebaseUser == null) return false;
      return await TokenStorage.hasValidToken();
    },
    loading: () => false,
    error: (_, __) => false,
  );
}

/// Provider for checking if user has admin privileges
@riverpod
Future<bool> isAdmin(Ref ref) async {
  final role = await ref.watch(userRoleProvider.future);
  return role.isAdmin;
}

/// Provider for checking if user is a student
@riverpod
Future<bool> isStudent(Ref ref) async {
  final role = await ref.watch(userRoleProvider.future);
  return role.isStudent;
}

/// Combined authentication state provider
///
/// Provides a single point of truth for authentication and role state,
/// eliminating the need for nested async handling in UI components
@riverpod
Future<AuthenticatedUserState> authenticatedUserState(Ref ref) async {
  try {
    // Get Firebase authentication state
    final firebaseUser = await ref.watch(authNotifierProvider.future);

    if (firebaseUser == null) {
      return const AuthenticatedUserState.notAuthenticated();
    }

    // Check if we have valid JWT token
    final hasValidToken = await ref.watch(hasValidJwtProvider.future);
    if (!hasValidToken) {
      // Firebase user exists but no valid JWT - should trigger re-authentication
      return const AuthenticatedUserState.notAuthenticated();
    }

    // Get backend user information with role
    final backendUser = await ref.watch(backendUserProvider.future);
    final userRole = await ref.watch(userRoleProvider.future);

    if (backendUser == null) {
      // JWT exists but backend user fetch failed - treat as guest
      return AuthenticatedUserState.withRole(
        firebaseUser,
        null,
        UserRole.guest,
      );
    }

    return AuthenticatedUserState.withRole(
      firebaseUser,
      backendUser,
      userRole,
    );
  } catch (e) {
    // On any error, treat as not authenticated
    return const AuthenticatedUserState.notAuthenticated();
  }
}