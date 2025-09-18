import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';

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

  /// Sign in with Google - preserves critical session cleanup logic
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();

    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) {
        // User cancelled the sign-in
        state = AsyncError(
          Exception('로그인이 취소되었습니다.'),
          StackTrace.current,
        );
      } else {
        state = AsyncData(user);
      }
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

  /// Sign out from all authentication providers
  Future<void> signOut() async {
    state = const AsyncLoading();

    try {
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