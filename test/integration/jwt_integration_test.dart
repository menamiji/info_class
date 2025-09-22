// JWT Integration Test for Flutter Frontend
// Tests the complete authentication flow from Flutter perspective

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:info_class/main.dart';
import 'package:info_class/firebase_options.dart';
import 'package:info_class/auth_service.dart';
import 'package:info_class/shared/data/api_client.dart';
import 'package:info_class/shared/services/token_storage.dart';
import 'package:info_class/providers/auth_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('JWT Authentication Integration Tests', () {
    setUpAll(() async {
      // Initialize Firebase for testing
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    });

    tearDown(() async {
      // Clean up after each test
      await AuthService.signOut();
      await TokenStorage.clearToken();
    });

    testWidgets('1. Backend Connectivity Test', (WidgetTester tester) async {
      // Test if backend is reachable
      final isConnected = await ApiClient.testConnection();
      expect(isConnected, isTrue,
          reason: 'Backend should be reachable at ${ApiClient.baseUrl}');
    });

    testWidgets('2. AuthService Basic Functionality', (WidgetTester tester) async {
      // Test AuthService currentUser getter
      final initialUser = AuthService.currentUser;
      expect(initialUser, isNull,
          reason: 'User should be null initially');

      // Test authStateChanges stream
      final authStream = AuthService.authStateChanges;
      expect(authStream, isNotNull,
          reason: 'Auth state stream should be available');
    });

    testWidgets('3. TokenStorage Functionality', (WidgetTester tester) async {
      // Test token storage when no token exists
      final initialToken = await TokenStorage.getToken();
      expect(initialToken, isNull,
          reason: 'No token should exist initially');

      final hasValidToken = await TokenStorage.hasValidToken();
      expect(hasValidToken, isFalse,
          reason: 'Should not have valid token initially');

      // Test saving and retrieving token
      const testToken = 'test_jwt_token_12345';
      const testRole = 'student';
      const testEmail = 'test@pocheonil.hs.kr';
      final expiryTime = DateTime.now().add(Duration(hours: 1));

      await TokenStorage.saveToken(
        jwtToken: testToken,
        userRole: testRole,
        userEmail: testEmail,
        expiryTime: expiryTime,
      );

      final savedToken = await TokenStorage.getToken();
      expect(savedToken, equals(testToken),
          reason: 'Saved token should be retrievable');

      final hasValidAfterSave = await TokenStorage.hasValidToken();
      expect(hasValidAfterSave, isTrue,
          reason: 'Should have valid token after saving');

      // Clean up
      await TokenStorage.clearToken();
      final tokenAfterClear = await TokenStorage.getToken();
      expect(tokenAfterClear, isNull,
          reason: 'Token should be null after clearing');
    });

    testWidgets('4. ApiClient Firebase Token Exchange (Mock)', (WidgetTester tester) async {
      // Test with invalid token to verify error handling
      final response = await ApiClient.exchangeFirebaseToken('invalid_token');

      expect(response.ok, isFalse,
          reason: 'Exchange should fail with invalid token');
      expect(response.error, isNotNull,
          reason: 'Error details should be provided');
      expect(response.error!.code, isNotNull,
          reason: 'Error code should be present');
    });

    testWidgets('5. ApiClient getCurrentUser (Unauthenticated)', (WidgetTester tester) async {
      // Test getting user info without authentication
      final response = await ApiClient.getCurrentUser();

      expect(response.ok, isFalse,
          reason: 'Should fail without authentication');
      expect(response.error?.code, equals('NO_TOKEN'),
          reason: 'Should indicate missing token');
    });

    testWidgets('6. AuthNotifier State Management', (WidgetTester tester) async {
      final container = ProviderContainer();

      // Test initial state
      final initialState = container.read(authNotifierProvider);
      expect(initialState, isA<AsyncData<User?>>(),
          reason: 'Initial state should be AsyncData');
      expect(initialState.value, isNull,
          reason: 'Initial user should be null');

      // Test authentication status
      final isAuth = container.read(isAuthenticatedProvider);
      expect(isAuth, isFalse,
          reason: 'Should not be authenticated initially');

      final isLoading = container.read(isAuthLoadingProvider);
      expect(isLoading, isFalse,
          reason: 'Should not be loading initially');

      container.dispose();
    });

    testWidgets('7. Complete Authentication Flow (Mock)', (WidgetTester tester) async {
      // This test simulates the complete flow with mock data
      // In a real test, you would need valid Firebase credentials

      final container = ProviderContainer();

      try {
        // Test sign out functionality
        final authNotifier = container.read(authNotifierProvider.notifier);
        await authNotifier.signOut();

        final stateAfterSignOut = container.read(authNotifierProvider);
        expect(stateAfterSignOut.value, isNull,
            reason: 'User should be null after sign out');

        // Verify token is cleared
        final tokenAfterSignOut = await TokenStorage.getToken();
        expect(tokenAfterSignOut, isNull,
            reason: 'Token should be cleared after sign out');

      } catch (e) {
        // Sign out should not fail even if not signed in
        expect(e, isNull, reason: 'Sign out should not throw errors');
      }

      container.dispose();
    });

    testWidgets('8. Error Handling in AuthNotifier', (WidgetTester tester) async {
      final container = ProviderContainer();

      // Test error state when sign in fails
      final authNotifier = container.read(authNotifierProvider.notifier);

      // Attempt sign in (will fail without proper setup)
      try {
        await authNotifier.signInWithGoogle();
      } catch (e) {
        // Expected to fail in test environment
      }

      // Check if error state is handled properly
      final authState = container.read(authNotifierProvider);

      if (authState.hasError) {
        expect(authState.error, isNotNull,
            reason: 'Error should be captured in state');

        final errorMessage = container.read(authErrorProvider);
        expect(errorMessage, isNotNull,
            reason: 'Error message should be available');
      }

      container.dispose();
    });

    testWidgets('9. Role-based Providers', (WidgetTester tester) async {
      final container = ProviderContainer();

      // Test role providers with no authentication
      final userRole = await container.read(userRoleProvider.future);
      expect(userRole.name, equals('guest'),
          reason: 'Should default to guest role when not authenticated');

      final isAdmin = await container.read(isAdminProvider.future);
      expect(isAdmin, isFalse,
          reason: 'Should not be admin when not authenticated');

      final isStudent = await container.read(isStudentProvider.future);
      expect(isStudent, isFalse,
          reason: 'Should not be student when not authenticated');

      container.dispose();
    });

    testWidgets('10. JWT Token Validation', (WidgetTester tester) async {
      final container = ProviderContainer();

      // Test JWT validation with no token
      final hasValidJwt = await container.read(hasValidJwtProvider.future);
      expect(hasValidJwt, isFalse,
          reason: 'Should not have valid JWT when not authenticated');

      container.dispose();
    });
  });

  group('Edge Cases and Error Scenarios', () {
    testWidgets('Network Error Handling', (WidgetTester tester) async {
      // Test behavior when backend is unreachable
      // This would require mocking network calls or using a test backend

      // For now, test that the app doesn't crash with network errors
      final isConnected = await ApiClient.testConnection();
      // Should return false if backend is down, true if up
      expect(isConnected, isA<bool>(),
          reason: 'Connection test should return boolean');
    });

    testWidgets('Invalid Token Scenarios', (WidgetTester tester) async {
      // Save an expired token
      final expiredTime = DateTime.now().subtract(Duration(hours: 1));
      await TokenStorage.saveToken(
        jwtToken: 'expired_token',
        userRole: 'student',
        userEmail: 'test@pocheonil.hs.kr',
        expiryTime: expiredTime,
      );

      final hasValidToken = await TokenStorage.hasValidToken();
      expect(hasValidToken, isFalse,
          reason: 'Expired token should not be considered valid');

      await TokenStorage.clearToken();
    });

    testWidgets('Malformed Data Handling', (WidgetTester tester) async {
      // Test that the app handles malformed responses gracefully
      final response = await ApiClient.exchangeFirebaseToken('');

      expect(response.ok, isFalse,
          reason: 'Empty token should be rejected');
      expect(response.error, isNotNull,
          reason: 'Error should be provided for empty token');
    });
  });
}