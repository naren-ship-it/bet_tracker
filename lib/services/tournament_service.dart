// services/tournament_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:bet_tracker/core/network/api_client.dart';
import 'package:bet_tracker/models/tournament_model.dart';
import 'package:bet_tracker/models/tournament_team_model.dart';

class TournamentPageResult {
  final int count;
  final String? next;
  final String? previous;
  final List<Tournament> results;

  TournamentPageResult({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory TournamentPageResult.fromJson(Map<String, dynamic> json) {
    return TournamentPageResult(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => Tournament.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TournamentServiceException implements Exception {
  final String message;
  TournamentServiceException(this.message);
  @override
  String toString() => message;
}

class TournamentService {
  final ApiClient _client = ApiClient();

  // ───────────────────────── Tournaments ─────────────────────────

  Future<TournamentPageResult> fetchTournaments({
    int page = 1,
    int pageSize = 10,
    String? search,
    int? tournamentTypeId,
    String? status,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (tournamentTypeId != null) 'tournament_type': '$tournamentTypeId',
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final res = await _client.get('/tournaments/', query: query);
    final body = _decode(res);
    return TournamentPageResult.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Tournament> createTournament(Map<String, dynamic> fields) async {
    final res = await _client.post('/tournaments/', body: fields);
    final body = _decode(res);
    return Tournament.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Tournament> updateTournament(int id, Map<String, dynamic> fields) async {
    final res = await _client.patch('/tournaments/$id/', body: fields);
    final body = _decode(res);
    return Tournament.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTournament(int id) async {
    final res = await _client.delete('/tournaments/$id/');
    _decode(res);
  }

  // ───────────────────────── Tournament Teams ─────────────────────────

  /// GET the teams currently allocated to a tournament.
/// Teams allocated to one tournament.
Future<List<TournamentTeam>> fetchTournamentTeams(int tournamentId) async {
  // 1) tournament-scoped route: /tournament-teams/<tournamentId>/
  try {
    final res = await _client.get('/tournament-teams/$tournamentId/');
    final body = _decode(res);
    final list = _asList(body['data']);
    if (list != null) {
      return list
          .map((e) => TournamentTeam.fromJson(e as Map<String, dynamic>))
          .where((t) => t.tournament == tournamentId)
          .toList();
    }
    // a single object means this route is "by allocation id" -> fall through
  } catch (_) {}

  // 2) fallback: list route, follow every page, keep only this tournament
  final out = <TournamentTeam>[];
  var page = 1;
  while (page <= 50) {
    final res = await _client.get('/tournament-teams/', query: {
      'tournament': '$tournamentId',
      'page': '$page',
    });
    final body = _decode(res);
    final data = body['data'];
    final list = _asList(data) ?? const [];
    out.addAll(list
        .map((e) => TournamentTeam.fromJson(e as Map<String, dynamic>))
        .where((t) => t.tournament == tournamentId));
    final next = data is Map<String, dynamic> ? data['next'] : null;
    if (next == null || list.isEmpty) break;
    page++;
  }
  return out;
}

/// Returns the list from `{results: [...]}` or a bare list, else null.
List<dynamic>? _asList(dynamic data) {
  if (data is List) return data;
  if (data is Map<String, dynamic> && data['results'] is List) {
    return data['results'] as List<dynamic>;
  }
  return null;
}
  /// POST /tournament-teams/bulk-allocate/
  Future<Map<String, dynamic>> bulkAllocateTeams({
    required List<int> tournamentIds,
    required List<int> teamIds,
    String groupName = '',
    bool isActive = true,
  }) async {
    final res = await _client.post(
      '/tournament-teams/bulk-allocate/',
      body: {
        'tournament_ids': tournamentIds,
        'team_ids': teamIds,
        if (groupName.isNotEmpty) 'group_name': groupName,
        'is_active': isActive,
      },
    );
    final body = _decode(res);
    return (body['data'] as Map<String, dynamic>?) ?? {};
  }

  /// POST /tournament-teams/bulk-deallocate/
  Future<Map<String, dynamic>> bulkDeallocateTeams({
    required List<int> tournamentIds,
    required List<int> teamIds,
  }) async {
    final res = await _client.post(
      '/tournament-teams/bulk-deallocate/',
      body: {
        'tournament_ids': tournamentIds,
        'team_ids': teamIds,
      },
    );
    final body = _decode(res);
    return (body['data'] as Map<String, dynamic>?) ?? {};
  }

  // ───────────────────────── helpers ─────────────────────────

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      debugPrint('DECODE FAILED — status ${res.statusCode}, body: ${res.body}');
      throw TournamentServiceException('Unexpected server response (${res.statusCode}).');
    }

    final status = body['status'];
    final ok = res.statusCode >= 200 && res.statusCode < 300 && status != false;

    if (!ok) {
      final message = body['message']?.toString() ?? 'Request failed (${res.statusCode}).';
      throw TournamentServiceException(message);
    }
    return body;
  }
}