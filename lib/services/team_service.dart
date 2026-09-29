import 'dart:convert';
import 'package:bet_tracker/core/network/api_client.dart';
import 'package:bet_tracker/models/team_model.dart';

class TeamServiceException implements Exception {
  final String message;
  TeamServiceException(this.message);
  @override
  String toString() => message;
}

class TeamService {
  final ApiClient _client = ApiClient();

  Future<TeamPageResult> fetchTeams({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool? isActive,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (isActive != null) 'is_active': isActive.toString(),
    };

    final res = await _client.get('/teams/', query: query);
    final body = _decode(res);
    final data = body['data'];

    if (data is Map<String, dynamic>) {
      return TeamPageResult.fromJson(data);
    }
    final list = (data as List<dynamic>? ?? [])
        .map((e) => Team.fromJson(e as Map<String, dynamic>))
        .toList();
    return TeamPageResult(count: list.length, next: null, previous: null, results: list);
  }

  Future<Team> createTeam({
    required String name,
    required String shortName,
    bool isActive = true,
  }) async {
    final res = await _client.post('/teams/', body: {
      'name': name,
      'short_name': shortName,
      'is_active': isActive,
    });
    return Team.fromJson(_decode(res)['data'] as Map<String, dynamic>);
  }

  Future<Team> updateTeam(int id, Map<String, dynamic> fields) async {
    final res = await _client.patch('/teams/$id/', body: fields);
    return Team.fromJson(_decode(res)['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTeam(int id) async {
    final res = await _client.delete('/teams/$id/');
    _decode(res);
  }

  Map<String, dynamic> _decode(dynamic res) {
    Map<String, dynamic> json;
    try {
      final raw = res.body as String;
      json = raw.isEmpty ? {} : Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      throw TeamServiceException('Unexpected server response (${res.statusCode}).');
    }
    final ok = res.statusCode >= 200 && res.statusCode < 300 && json['status'] != false;
    if (!ok) {
      throw TeamServiceException(json['message']?.toString() ?? 'Request failed (${res.statusCode}).');
    }
    return json;
  }
  Future<Team> createTeamWithFields(Map<String, dynamic> fields) async {
  final res = await _client.post('/teams/', body: fields);
  return Team.fromJson(_decode(res)['data'] as Map<String, dynamic>);
}
}