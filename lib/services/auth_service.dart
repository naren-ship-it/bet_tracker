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

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
      },
    );

    debugPrint('Login response: ${response.data}', wrapWidth: 1024);

    final authResponse = AuthResponse.fromJson(response.data);

    if (!authResponse.status) {
      throw Exception(authResponse.message);
    }

    if (authResponse.token.isEmpty) {
      throw Exception('Token was not returned by server');
    }

    // Save both tokens
    await SecureStorage.saveToken(authResponse.token);
    final refreshToken = authResponse.data?.tokens.refresh ?? '';
    if (refreshToken.isNotEmpty) {
      await SecureStorage.saveToken(refreshToken);
    }

    return authResponse;
  }

  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _dio.post(
      ApiConstants.signup,
      data: {
        'username': name,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      },
    );

    debugPrint('Signup response: ${response.data}', wrapWidth: 1024);

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
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}