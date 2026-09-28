// lib/services/player_service.dart

import 'package:bet_tracker/models/player_choice.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage.dart';
import '../models/player.dart';
import 'dart:io';

class PlayerService {
  late final Dio _dio;

  PlayerService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Token $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  // ─── LIST ──────────────────────────────────────────────────────────────────

  Future<List<Player>> getPlayers() async {
    try {
      final List<Player> allPlayers = [];
      String? nextUrl = ApiConstants.players;

      while (nextUrl != null) {
        final response = await _dio.get(nextUrl);
        final body = response.data as Map<String, dynamic>;
        if (body['status'] == false) throw Exception(body['message']);

        final inner = body['data'] as Map<String, dynamic>;
        final List raw = inner['results'] as List? ?? [];
        allPlayers.addAll(
          raw.map((e) => Player.fromJson(e as Map<String, dynamic>)),
        );

        // next is a full URL like http://192.168.1.23:8000/api/players/?page=2
        // strip the base URL to get just the path+query
        final next = inner['next'] as String?;
        if (next != null) {
          nextUrl = next.replaceFirst(ApiConstants.baseUrl, '');
        } else {
          nextUrl = null;
        }
      }

      return allPlayers;
    } on DioException catch (e) {
      debugPrint('getPlayers error: ${e.response?.statusCode} ${e.response?.data}');
      throw Exception(_extractDioMessage(e));
    }
  }



  // ─── CREATE ────────────────────────────────────────────────────────────────

  Future<Player> createPlayer(Player player, {File? photo}) async {
    try {
      FormData formData = FormData.fromMap({
        ...player.toJson(),
        if (photo != null)
          'photo': await MultipartFile.fromFile(
            photo.path,
            filename: photo.path.split('/').last,
          ),
      });

      final response = await _dio.post(
        ApiConstants.players,
        data: photo != null ? formData : player.toJson(),
        options: photo != null
            ? Options(contentType: 'multipart/form-data')
            : null,
      );
      final body = response.data as Map<String, dynamic>;
      if (body['status'] == false) throw Exception(body['message']);
      return Player.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('createPlayer error: ${e.response?.statusCode} ${e.response?.data}');
      throw Exception(_extractDioMessage(e));
    }
  }

  // ─── GET BY ID ─────────────────────────────────────────────────────────────

  Future<Player> getPlayer(int id) async {
    try {
      final response = await _dio.get(ApiConstants.playerById(id));
      final body = response.data as Map<String, dynamic>;
      if (body['status'] == false) throw Exception(body['message']);
      return Player.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('getPlayer error: ${e.response?.statusCode} ${e.response?.data}');
      throw Exception(_extractDioMessage(e));
    }
  }

  // ─── UPDATE (PUT) ──────────────────────────────────────────────────────────

  Future<Player> updatePlayer(int id, Player player, {File? photo}) async {
    try {
      FormData formData = FormData.fromMap({
        ...player.toJson(),
        if (photo != null)
          'photo': await MultipartFile.fromFile(
            photo.path,
            filename: photo.path.split('/').last,
          ),
      });

      final response = await _dio.put(
        ApiConstants.playerById(id),
        data: photo != null ? formData : player.toJson(),
        options: photo != null
            ? Options(contentType: 'multipart/form-data')
            : null,
      );
      final body = response.data as Map<String, dynamic>;
      if (body['status'] == false) throw Exception(body['message']);
      return Player.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('updatePlayer error: ${e.response?.statusCode} ${e.response?.data}');
      throw Exception(_extractDioMessage(e));
    }
  }

  // ─── PARTIAL UPDATE (PATCH) ────────────────────────────────────────────────

  Future<Player> patchPlayer(int id, Map<String, dynamic> fields) async {
    try {
      final response = await _dio.patch(
        ApiConstants.playerById(id),
        data: fields,
      );
      final body = response.data as Map<String, dynamic>;
      if (body['status'] == false) throw Exception(body['message']);
      return Player.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('patchPlayer error: ${e.response?.statusCode} ${e.response?.data}');
      throw Exception(_extractDioMessage(e));
    }
  }

  // ─── DELETE ────────────────────────────────────────────────────────────────

  Future<void> deletePlayer(int id) async {
    try {
      final response = await _dio.delete(ApiConstants.playerById(id));
      if (response.data is Map<String, dynamic>) {
        final body = response.data as Map<String, dynamic>;
        if (body['status'] == false) throw Exception(body['message']);
      }
    } on DioException catch (e) {
      debugPrint('deletePlayer error: ${e.response?.statusCode} ${e.response?.data}');
      throw Exception(_extractDioMessage(e));
    }
  }

  // ─── CHOICES ───────────────────────────────────────────────────────────────

  Future<List<PlayerChoice>> getPlayerRoles() async {
    try {
      final response = await _dio.get(ApiConstants.playerRoles);
      return _parseChoices(response.data);
    } on DioException catch (e) {
      debugPrint('getPlayerRoles error: ${e.response?.statusCode} ${e.response?.data}');
      throw Exception(_extractDioMessage(e));
    }
  }

  Future<List<PlayerChoice>> getBattingStyles() async {
    try {
      final response = await _dio.get(ApiConstants.battingStyles);
      return _parseChoices(response.data);
    } on DioException catch (e) {
      debugPrint('getBattingStyles error: ${e.response?.statusCode} ${e.response?.data}');
      throw Exception(_extractDioMessage(e));
    }
  }

  Future<List<PlayerChoice>> getBowlingStyles() async {
    try {
      final response = await _dio.get(ApiConstants.bowlingStyles);
      return _parseChoices(response.data);
    } on DioException catch (e) {
      debugPrint('getBowlingStyles error: ${e.response?.statusCode} ${e.response?.data}');
      throw Exception(_extractDioMessage(e));
    }
  }

  // ─── PARSE CHOICES ─────────────────────────────────────────────────────────

  List<PlayerChoice> _parseChoices(dynamic data) {
    List raw;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) {
        raw = inner['results'] as List? ?? [];
      } else if (inner is List) {
        raw = inner;
      } else {
        raw = [];
      }
    } else if (data is List) {
      raw = data;
    } else {
      raw = [];
    }
    return raw
        .map((e) => PlayerChoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── ERROR EXTRACTION ──────────────────────────────────────────────────────

  String _extractDioMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }
      final detail = data['detail'];
      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString().trim();
      }
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          return value.first.toString().trim();
        }
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to the server. Check your connection.';
      case DioExceptionType.cancel:
        return 'Request was cancelled. Please try again.';
      default:
        if (error.response?.statusCode != null) {
          return 'Server error (${error.response!.statusCode}).';
        }
        return 'Something went wrong. Please try again.';
    }
  }
}