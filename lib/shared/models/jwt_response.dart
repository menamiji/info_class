import 'package:flutter/foundation.dart';
import 'backend_user.dart';

/// Response model for JWT token exchange from backend /auth/exchange endpoint
@immutable
class JwtResponse {
  final bool ok;
  final JwtTokenData? data;
  final ApiError? error;

  const JwtResponse({
    required this.ok,
    this.data,
    this.error,
  });

  /// Create JwtResponse from JSON map
  factory JwtResponse.fromJson(Map<String, dynamic> json) {
    final bool ok = json['ok'] as bool? ?? false;

    if (ok && json['data'] != null) {
      return JwtResponse(
        ok: ok,
        data: JwtTokenData.fromJson(json['data'] as Map<String, dynamic>),
      );
    } else if (!ok && json['error'] != null) {
      return JwtResponse(
        ok: ok,
        error: ApiError.fromJson(json['error'] as Map<String, dynamic>),
      );
    } else {
      return JwtResponse(
        ok: ok,
        error: ApiError(
          code: 'UNKNOWN_ERROR',
          message: 'Invalid response format',
        ),
      );
    }
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'ok': ok};

    if (data != null) {
      json['data'] = data!.toJson();
    }
    if (error != null) {
      json['error'] = error!.toJson();
    }

    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JwtResponse &&
        other.ok == ok &&
        other.data == data &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(ok, data, error);

  @override
  String toString() => 'JwtResponse(ok: $ok, data: $data, error: $error)';
}

/// Token and user data from successful JWT exchange
@immutable
class JwtTokenData {
  final String jwtToken;
  final BackendUser user;
  final DateTime expiresAt;

  const JwtTokenData({
    required this.jwtToken,
    required this.user,
    required this.expiresAt,
  });

  /// Create JwtTokenData from JSON map
  factory JwtTokenData.fromJson(Map<String, dynamic> json) {
    return JwtTokenData(
      jwtToken: json['jwt_token'] as String,
      user: BackendUser.fromJson(json['user'] as Map<String, dynamic>),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'jwt_token': jwtToken,
      'user': user.toJson(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  /// Check if the token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if the token expires within the given duration
  bool expiresWithin(Duration duration) {
    return DateTime.now().add(duration).isAfter(expiresAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JwtTokenData &&
        other.jwtToken == jwtToken &&
        other.user == user &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode => Object.hash(jwtToken, user, expiresAt);

  @override
  String toString() =>
      'JwtTokenData(jwtToken: ${jwtToken.substring(0, 20)}..., user: $user, expiresAt: $expiresAt)';
}

/// API error information
@immutable
class ApiError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  const ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  /// Create ApiError from JSON map
  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String,
      message: json['message'] as String,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'code': code,
      'message': message,
    };

    if (details != null) {
      json['details'] = details;
    }

    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiError &&
        other.code == code &&
        other.message == message &&
        other.details == details;
  }

  @override
  int get hashCode => Object.hash(code, message, details);

  @override
  String toString() => 'ApiError(code: $code, message: $message)';
}