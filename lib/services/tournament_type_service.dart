// services/tournament_type_service.dart
import 'dart:convert';

import 'package:bet_tracker/core/network/api_client.dart';
import 'package:bet_tracker/models/tournament_type_model.dart';

class TournamentTypeServiceException implements Exception {
  final String message;
  TournamentTypeServiceException(this.message);
  @override
  String toString() => message;
}

class TournamentTypeService {
  final ApiClient _client = ApiClient();

  Future<List<TournamentType>> fetchTournamentTypes() async {
    final res = await _client.get('/tournament-types/');
    final body = _decode(res);
    final data = body['data'];
    final list = data is Map<String, dynamic> ? data['results'] : data;
    return (list as List<dynamic>? ?? [])
        .map((e) => TournamentType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TournamentType> createTournamentType(String name) async {
    final res = await _client.post('/tournament-types/', body: {'name': name});
    final body = _decode(res);
    return TournamentType.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<TournamentType> updateTournamentType(int id, Map<String, dynamic> fields) async {
    final res = await _client.patch('/tournament-types/$id/', body: fields);
    final body = _decode(res);
    return TournamentType.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTournamentType(int id) async {
    final res = await _client.delete('/tournament-types/$id/');
    _decode(res);
  }

  Map<String, dynamic> _decode(dynamic res) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw TournamentTypeServiceException('Unexpected server response (${res.statusCode}).');
    }
    final status = body['status'];
    final ok = res.statusCode >= 200 && res.statusCode < 300 && status != false;
    if (!ok) {
      throw TournamentTypeServiceException(body['message']?.toString() ?? 'Request failed (${res.statusCode}).');
    }
    return body;
  }
}