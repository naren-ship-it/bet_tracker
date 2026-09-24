// services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage.dart';
import '../models/auth_response.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // ───────────────────────────────────────────────────────────────────────────
  // LOGIN
  // ───────────────────────────────────────────────────────────────────────────

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      debugPrint(
        'Login response: ${response.data}',
        wrapWidth: 1024,
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (!authResponse.status) {
        throw Exception(authResponse.message);
      }

      if (authResponse.token.isEmpty) {
        throw Exception('Token was not returned by server');
      }

      // Save access token
      await SecureStorage.saveToken(authResponse.token);

      // Save refresh token
      final refreshToken = authResponse.data?.tokens.refresh ?? '';

      if (refreshToken.isNotEmpty) {
        await SecureStorage.saveToken(refreshToken);
      }

      return authResponse;
    } on DioException catch (e) {
      debugPrint(
        'Login Dio error: ${e.response?.statusCode} ${e.response?.data}',
        wrapWidth: 1024,
      );

      throw Exception(_extractDioMessage(e));
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SIGNUP
  // ───────────────────────────────────────────────────────────────────────────

  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.signup,
        data: {
          'username': name,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        },
      );

      debugPrint(
        'Signup response: ${response.data}',
        wrapWidth: 1024,
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (!authResponse.status) {
        throw Exception(authResponse.message);
      }

      if (authResponse.token.isNotEmpty) {
        await SecureStorage.saveToken(authResponse.token);

        final refreshToken = authResponse.data?.tokens.refresh ?? '';

        if (refreshToken.isNotEmpty) {
          await SecureStorage.saveToken(refreshToken);
        }
      }

      return authResponse;
    } on DioException catch (e) {
      debugPrint(
        'Signup Dio error: ${e.response?.statusCode} ${e.response?.data}',
        wrapWidth: 1024,
      );

      throw Exception(_extractDioMessage(e));
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // EXTRACT BACKEND ERROR MESSAGE
  // ───────────────────────────────────────────────────────────────────────────

  // ───────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD — REQUEST OTP
// ───────────────────────────────────────────────────────────────────────────

Future<Map<String, dynamic>> requestPasswordReset({
  required String identifier,
}) async {
  try {
    final response = await _dio.post(
      ApiConstants.forgotPasswordRequest,
      data: {
        'identifier': identifier.trim(),
      },
    );

    debugPrint(
      'Password reset request response: ${response.data}',
      wrapWidth: 1024,
    );

    if (response.data is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(response.data);

      if (data['status'] == false) {
        throw Exception(
          data['message']?.toString() ??
              'Unable to start password reset.',
        );
      }

      return data;
    }

    throw Exception('Invalid server response.');
  } on DioException catch (e) {
    debugPrint(
      'Password reset request error: '
      '${e.response?.statusCode} ${e.response?.data}',
      wrapWidth: 1024,
    );

    throw Exception(_extractDioMessage(e));
  }
}

// ───────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD — VERIFY OTP
// ───────────────────────────────────────────────────────────────────────────

Future<Map<String, dynamic>> verifyPasswordResetOtp({
  required String identifier,
  required String otp,
}) async {
  try {
    final response = await _dio.post(
      ApiConstants.forgotPasswordVerifyOtp,
      data: {
        'identifier': identifier.trim(),
        'otp': otp.trim(),
      },
    );

    debugPrint(
      'OTP verification response: ${response.data}',
      wrapWidth: 1024,
    );

    if (response.data is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(response.data);

      if (data['status'] == false) {
        throw Exception(
          data['message']?.toString() ??
              'Invalid verification code.',
        );
      }

      return data;
    }

    throw Exception('Invalid server response.');
  } on DioException catch (e) {
    debugPrint(
      'OTP verification error: '
      '${e.response?.statusCode} ${e.response?.data}',
      wrapWidth: 1024,
    );

    throw Exception(_extractDioMessage(e));
  }
}

// ───────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD — RESET PASSWORD
// ───────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPasswordReset,
        data: {
          'identifier': identifier.trim(),
          'otp': otp.trim(),
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      debugPrint(
        'Password reset response: ${response.data}',
        wrapWidth: 1024,
      );

      if (response.data is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(response.data);

        if (data['status'] == false) {
          throw Exception(
            data['message']?.toString() ??
                'Unable to reset password.',
          );
        }

        return data;
      }

      throw Exception('Invalid server response.');
    } on DioException catch (e) {
      debugPrint(
        'Password reset error: '
        '${e.response?.statusCode} ${e.response?.data}',
        wrapWidth: 1024,
      );

      throw Exception(_extractDioMessage(e));
    }
  }

  String _extractDioMessage(DioException error) {
    final data = error.response?.data;

    // Backend returned JSON such as:
    //
    // {
    //   "status": false,
    //   "message": "Invalid username or password."
    // }
    if (data is Map<String, dynamic>) {
      final message = data['message'];

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }

      // Some Django APIs may return:
      //
      // {
      //   "detail": "..."
      // }
      final detail = data['detail'];

      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString().trim();
      }

      // Handle Django validation errors:
      //
      // {
      //   "email": ["This email is already registered."]
      // }
      final validationMessage = _extractValidationMessage(data);

      if (validationMessage != null) {
        return validationMessage;
      }
    }

    // No useful backend message
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';

      case DioExceptionType.connectionError:
        return 'Unable to connect to the server. Please check your connection.';

      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please try again.';

      case DioExceptionType.cancel:
        return 'Request was cancelled. Please try again.';

      default:
        if (error.response?.statusCode != null) {
          return 'Server returned an error (${error.response!.statusCode}).';
        }

        return 'Something went wrong. Please try again.';
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // EXTRACT DJANGO VALIDATION ERROR
  // ───────────────────────────────────────────────────────────────────────────

  String? _extractValidationMessage(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final value = entry.value;

      if (value is List && value.isNotEmpty) {
        final first = value.first;

        if (first != null && first.toString().trim().isNotEmpty) {
          return first.toString().trim();
        }
      }

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LOGOUT
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await SecureStorage.deleteToken();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // AUTH STATUS
  // ───────────────────────────────────────────────────────────────────────────

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getToken();

    return token != null && token.isNotEmpty;
  }
}