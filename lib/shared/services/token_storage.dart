import 'package:shared_preferences/shared_preferences.dart';

/// Service for securely storing and retrieving JWT tokens
///
/// Handles JWT token persistence across app restarts and provides
/// methods for token lifecycle management
class TokenStorage {
  static const String _jwtTokenKey = 'jwt_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userRoleKey = 'user_role';
  static const String _userEmailKey = 'user_email';

  /// Save JWT token with expiry information
  static Future<void> saveToken({
    required String jwtToken,
    required String userRole,
    required String userEmail,
    DateTime? expiryTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_jwtTokenKey, jwtToken);
    await prefs.setString(_userRoleKey, userRole);
    await prefs.setString(_userEmailKey, userEmail);

    if (expiryTime != null) {
      await prefs.setInt(_tokenExpiryKey, expiryTime.millisecondsSinceEpoch);
    }
  }

  /// Retrieve stored JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if token is expired
    if (await isTokenExpired()) {
      await clearToken();
      return null;
    }

    return prefs.getString(_jwtTokenKey);
  }

  /// Get stored user role
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  /// Get stored user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Check if the stored token is expired
  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTimestamp = prefs.getInt(_tokenExpiryKey);

    if (expiryTimestamp == null) {
      // No expiry set, assume token is valid
      return false;
    }

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
    return DateTime.now().isAfter(expiryTime);
  }

  /// Check if a valid token exists
  static Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored token data
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      prefs.remove(_jwtTokenKey),
      prefs.remove(_tokenExpiryKey),
      prefs.remove(_userRoleKey),
      prefs.remove(_userEmailKey),
    ]);
  }

  /// Get all stored auth data as a map
  static Future<Map<String, String?>> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'token': prefs.getString(_jwtTokenKey),
      'role': prefs.getString(_userRoleKey),
      'email': prefs.getString(_userEmailKey),
    };
  }
}