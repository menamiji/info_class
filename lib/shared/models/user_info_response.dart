import 'package:flutter/foundation.dart';
import 'backend_user.dart';
import 'jwt_response.dart';

/// Response model for /auth/me endpoint
@immutable
class UserInfoResponse {
  final bool ok;
  final BackendUser? data;
  final ApiError? error;

  const UserInfoResponse({
    required this.ok,
    this.data,
    this.error,
  });

  /// Create UserInfoResponse from JSON map
  factory UserInfoResponse.fromJson(Map<String, dynamic> json) {
    final bool ok = json['ok'] as bool? ?? false;

    if (ok && json['data'] != null) {
      return UserInfoResponse(
        ok: ok,
        data: BackendUser.fromJson(json['data'] as Map<String, dynamic>),
      );
    } else if (!ok && json['error'] != null) {
      return UserInfoResponse(
        ok: ok,
        error: ApiError.fromJson(json['error'] as Map<String, dynamic>),
      );
    } else {
      return UserInfoResponse(
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
    return other is UserInfoResponse &&
        other.ok == ok &&
        other.data == data &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(ok, data, error);

  @override
  String toString() => 'UserInfoResponse(ok: $ok, data: $data, error: $error)';
}