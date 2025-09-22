import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/jwt_response.dart';
import '../services/token_storage.dart';

/// API client for communicating with the Info Class backend
///
/// Handles JWT token management, automatic token inclusion in requests,
/// and provides methods for authentication and API communication
class ApiClient {
  static const String _developmentUrl = 'http://localhost:8000';
  static const String _productionUrl = 'https://info.pocheonil.hs.kr/info_class/api';

  /// Get the appropriate base URL based on build mode
  static String get baseUrl {
    if (kDebugMode) {
      return _developmentUrl;
    } else {
      return _productionUrl;
    }
  }

  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Exchange Firebase ID token for JWT token from backend
  ///
  /// [firebaseToken] - Firebase ID token from authenticated user
  /// Returns [JwtResponse] with JWT token and user data on success
  static Future<JwtResponse> exchangeFirebaseToken(String firebaseToken) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/exchange');
      final body = json.encode({'firebase_token': firebaseToken});

      debugPrint('🔄 Exchanging Firebase token for JWT');
      debugPrint('📍 URL: $uri');

      final response = await http
          .post(
            uri,
            headers: _defaultHeaders,
            body: body,
          )
          .timeout(_defaultTimeout);

      debugPrint('📨 Response status: ${response.statusCode}');

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        debugPrint('✅ JWT exchange successful');
        return JwtResponse.fromJson(responseData);
      } else {
        debugPrint('❌ JWT exchange failed: ${response.statusCode}');
        return JwtResponse.fromJson(responseData);
      }
    } on SocketException catch (e) {
      debugPrint('🌐 Network error during JWT exchange: $e');
      return JwtResponse(
        ok: false,
        error: ApiError(
          code: 'NETWORK_ERROR',
          message: '서버에 연결할 수 없습니다. 인터넷 연결을 확인해주세요.',
          details: {'original_error': e.toString()},
        ),
      );
    } on http.ClientException catch (e) {
      debugPrint('📡 HTTP client error during JWT exchange: $e');
      return JwtResponse(
        ok: false,
        error: ApiError(
          code: 'HTTP_CLIENT_ERROR',
          message: '요청 처리 중 오류가 발생했습니다.',
          details: {'original_error': e.toString()},
        ),
      );
    } catch (e) {
      debugPrint('💥 Unexpected error during JWT exchange: $e');
      return JwtResponse(
        ok: false,
        error: ApiError(
          code: 'UNKNOWN_ERROR',
          message: '알 수 없는 오류가 발생했습니다.',
          details: {'original_error': e.toString()},
        ),
      );
    }
  }

  /// Get current user information using stored JWT token
  ///
  /// Returns [JwtResponse] with current user data or error
  static Future<JwtResponse> getCurrentUser() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return JwtResponse(
          ok: false,
          error: ApiError(
            code: 'NO_TOKEN',
            message: '인증 토큰이 없습니다. 다시 로그인해주세요.',
          ),
        );
      }

      final uri = Uri.parse('$baseUrl/auth/me');
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      debugPrint('👤 Getting current user info');
      debugPrint('📍 URL: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(_defaultTimeout);

      debugPrint('📨 Response status: ${response.statusCode}');

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        debugPrint('✅ User info retrieved successfully');
        return JwtResponse.fromJson(responseData);
      } else {
        debugPrint('❌ Failed to get user info: ${response.statusCode}');

        // If token is invalid or expired, clear it
        if (response.statusCode == 401 || response.statusCode == 403) {
          await TokenStorage.clearToken();
        }

        return JwtResponse.fromJson(responseData);
      }
    } on SocketException catch (e) {
      debugPrint('🌐 Network error getting user info: $e');
      return JwtResponse(
        ok: false,
        error: ApiError(
          code: 'NETWORK_ERROR',
          message: '서버에 연결할 수 없습니다. 인터넷 연결을 확인해주세요.',
          details: {'original_error': e.toString()},
        ),
      );
    } catch (e) {
      debugPrint('💥 Unexpected error getting user info: $e');
      return JwtResponse(
        ok: false,
        error: ApiError(
          code: 'UNKNOWN_ERROR',
          message: '사용자 정보를 가져오는 중 오류가 발생했습니다.',
          details: {'original_error': e.toString()},
        ),
      );
    }
  }

  /// Refresh JWT token using stored token
  ///
  /// Returns [JwtResponse] with new JWT token or error
  static Future<JwtResponse> refreshToken() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return JwtResponse(
          ok: false,
          error: ApiError(
            code: 'NO_TOKEN',
            message: '갱신할 토큰이 없습니다. 다시 로그인해주세요.',
          ),
        );
      }

      final uri = Uri.parse('$baseUrl/auth/refresh');
      final headers = Map<String, String>.from(_defaultHeaders);
      headers['Authorization'] = 'Bearer $token';

      debugPrint('🔄 Refreshing JWT token');
      debugPrint('📍 URL: $uri');

      final response = await http
          .post(uri, headers: headers)
          .timeout(_defaultTimeout);

      debugPrint('📨 Response status: ${response.statusCode}');

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        debugPrint('✅ Token refresh successful');
        return JwtResponse.fromJson(responseData);
      } else {
        debugPrint('❌ Token refresh failed: ${response.statusCode}');

        // If refresh fails, clear the token
        if (response.statusCode == 401 || response.statusCode == 403) {
          await TokenStorage.clearToken();
        }

        return JwtResponse.fromJson(responseData);
      }
    } on SocketException catch (e) {
      debugPrint('🌐 Network error refreshing token: $e');
      return JwtResponse(
        ok: false,
        error: ApiError(
          code: 'NETWORK_ERROR',
          message: '서버에 연결할 수 없습니다. 인터넷 연결을 확인해주세요.',
          details: {'original_error': e.toString()},
        ),
      );
    } catch (e) {
      debugPrint('💥 Unexpected error refreshing token: $e');
      return JwtResponse(
        ok: false,
        error: ApiError(
          code: 'UNKNOWN_ERROR',
          message: '토큰 갱신 중 오류가 발생했습니다.',
          details: {'original_error': e.toString()},
        ),
      );
    }
  }

  /// Test backend connectivity
  ///
  /// Returns true if backend is reachable, false otherwise
  static Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('$baseUrl/healthz');

      debugPrint('🏥 Testing backend connection');
      debugPrint('📍 URL: $uri');

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(Duration(seconds: 10));

      final isHealthy = response.statusCode == 200;
      debugPrint(isHealthy ? '✅ Backend is healthy' : '❌ Backend is unhealthy');

      return isHealthy;
    } catch (e) {
      debugPrint('💥 Backend connection test failed: $e');
      return false;
    }
  }

  /// Generic authenticated GET request
  ///
  /// [endpoint] - API endpoint path (without base URL)
  /// Returns response body as Map or throws exception
  static Future<Map<String, dynamic>> authenticatedGet(String endpoint) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
    }

    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = Map<String, String>.from(_defaultHeaders);
    headers['Authorization'] = 'Bearer $token';

    final response = await http
        .get(uri, headers: headers)
        .timeout(_defaultTimeout);

    if (response.statusCode == 401 || response.statusCode == 403) {
      await TokenStorage.clearToken();
      throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
    }

    if (response.statusCode != 200) {
      throw Exception('API 요청 실패: ${response.statusCode}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Generic authenticated POST request
  ///
  /// [endpoint] - API endpoint path (without base URL)
  /// [body] - Request body data
  /// Returns response body as Map or throws exception
  static Future<Map<String, dynamic>> authenticatedPost(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
    }

    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = Map<String, String>.from(_defaultHeaders);
    headers['Authorization'] = 'Bearer $token';

    final response = await http
        .post(
          uri,
          headers: headers,
          body: json.encode(body),
        )
        .timeout(_defaultTimeout);

    if (response.statusCode == 401 || response.statusCode == 403) {
      await TokenStorage.clearToken();
      throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('API 요청 실패: ${response.statusCode}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }
}