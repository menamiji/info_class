// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authStateStreamHash() => r'3577d018db2a850d01ea4d8b0930c07522c4bcdf';

/// Stream provider for Firebase auth state changes
/// This enables automatic synchronization with Firebase authentication state
///
/// Copied from [authStateStream].
@ProviderFor(authStateStream)
final authStateStreamProvider = AutoDisposeStreamProvider<User?>.internal(
  authStateStream,
  name: r'authStateStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authStateStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateStreamRef = AutoDisposeStreamProviderRef<User?>;
String _$currentUserHash() => r'c7a7405c5966b0f2186bbf2959a1a525b7d78608';

/// Computed provider for current user
/// Returns null if not authenticated, loading, or error state
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeProvider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeProviderRef<User?>;
String _$isAuthenticatedHash() => r'2fd89c95365db63a54ed93bd8c36237830ad4ddf';

/// Computed provider for authentication status
/// Returns true only when user is authenticated and state is loaded
///
/// Copied from [isAuthenticated].
@ProviderFor(isAuthenticated)
final isAuthenticatedProvider = AutoDisposeProvider<bool>.internal(
  isAuthenticated,
  name: r'isAuthenticatedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isAuthenticatedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsAuthenticatedRef = AutoDisposeProviderRef<bool>;
String _$isAuthLoadingHash() => r'6b44e6ef1eaa7696ce769a35558374e2a7ba96a9';

/// Computed provider for loading state
/// Returns true when authentication operations are in progress
///
/// Copied from [isAuthLoading].
@ProviderFor(isAuthLoading)
final isAuthLoadingProvider = AutoDisposeProvider<bool>.internal(
  isAuthLoading,
  name: r'isAuthLoadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isAuthLoadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsAuthLoadingRef = AutoDisposeProviderRef<bool>;
String _$authErrorHash() => r'bd245c523d0d45b09171b8d3661a02793809e71c';

/// Computed provider for error state
/// Returns error message if authentication failed, null otherwise
///
/// Copied from [authError].
@ProviderFor(authError)
final authErrorProvider = AutoDisposeProvider<String?>.internal(
  authError,
  name: r'authErrorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authErrorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthErrorRef = AutoDisposeProviderRef<String?>;
String _$backendUserHash() => r'0df187aa00b3025d9edbc06e94c6962a07dc6382';

/// Provider for backend user information with role
/// Returns null if not authenticated or JWT not available
///
/// Copied from [backendUser].
@ProviderFor(backendUser)
final backendUserProvider = AutoDisposeFutureProvider<BackendUser?>.internal(
  backendUser,
  name: r'backendUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$backendUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BackendUserRef = AutoDisposeFutureProviderRef<BackendUser?>;
String _$userRoleHash() => r'3d31cd951c45dfb7da181aae3a30574a99d8dc02';

/// Provider for user role
/// Returns UserRole.guest if not authenticated or role not available
///
/// Copied from [userRole].
@ProviderFor(userRole)
final userRoleProvider = AutoDisposeFutureProvider<UserRole>.internal(
  userRole,
  name: r'userRoleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userRoleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserRoleRef = AutoDisposeFutureProviderRef<UserRole>;
String _$hasValidJwtHash() => r'453752d9bf02f648418bd1b66fe8813e35f378c0';

/// Provider for JWT token validity
/// Returns true if valid JWT token exists
///
/// Copied from [hasValidJwt].
@ProviderFor(hasValidJwt)
final hasValidJwtProvider = AutoDisposeFutureProvider<bool>.internal(
  hasValidJwt,
  name: r'hasValidJwtProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$hasValidJwtHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasValidJwtRef = AutoDisposeFutureProviderRef<bool>;
String _$isAdminHash() => r'49af6c22d6d7bffade9bf704d76577144acabb2e';

/// Provider for checking if user has admin privileges
///
/// Copied from [isAdmin].
@ProviderFor(isAdmin)
final isAdminProvider = AutoDisposeFutureProvider<bool>.internal(
  isAdmin,
  name: r'isAdminProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isAdminHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsAdminRef = AutoDisposeFutureProviderRef<bool>;
String _$isStudentHash() => r'd4bf71a6e5a899744f1916ad0a9f4d63ca0ed8c6';

/// Provider for checking if user is a student
///
/// Copied from [isStudent].
@ProviderFor(isStudent)
final isStudentProvider = AutoDisposeFutureProvider<bool>.internal(
  isStudent,
  name: r'isStudentProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isStudentHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsStudentRef = AutoDisposeFutureProviderRef<bool>;
String _$authenticatedUserStateHash() =>
    r'0038fc52234beb11f84ea13401caac9bc1e64610';

/// Combined authentication state provider
///
/// Provides a single point of truth for authentication and role state,
/// eliminating the need for nested async handling in UI components
///
/// Copied from [authenticatedUserState].
@ProviderFor(authenticatedUserState)
final authenticatedUserStateProvider =
    AutoDisposeFutureProvider<AuthenticatedUserState>.internal(
      authenticatedUserState,
      name: r'authenticatedUserStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authenticatedUserStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthenticatedUserStateRef =
    AutoDisposeFutureProviderRef<AuthenticatedUserState>;
String _$authNotifierHash() => r'65186e2146a94aeab65ed243d98819c7401905df';

/// Authentication state management using Riverpod
///
/// Provides reactive authentication state with proper loading/error handling
/// while preserving the critical Google Sign-In session cleanup logic
///
/// Copied from [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AuthNotifier, User?>.internal(
      AuthNotifier.new,
      name: r'authNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthNotifier = AutoDisposeAsyncNotifier<User?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
