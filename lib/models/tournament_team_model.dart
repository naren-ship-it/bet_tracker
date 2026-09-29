// models/tournament_team_model.dart
class TournamentTeam {
  final int id;             // allocation id
  final int tournament;
  final int team;           // team id
  final String teamName;
  final String teamShortName;
  final String? teamLogo;   // absolute URL from the API
  final String groupName;
  final int points;
  final int matchesPlayed;
  final bool isActive;

  TournamentTeam({
    required this.id,
    required this.tournament,
    required this.team,
    this.teamName = '',
    this.teamShortName = '',
    this.teamLogo,
    this.groupName = '',
    this.points = 0,
    this.matchesPlayed = 0,
    this.isActive = true,
  });

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is Map) return _asInt(v['id']);
    return int.tryParse('$v') ?? 0;
  }

  factory TournamentTeam.fromJson(Map<String, dynamic> json) {
    final logo = json['team_logo'] as String?;
    return TournamentTeam(
      id: _asInt(json['id']),
      tournament: _asInt(json['tournament']),
      team: _asInt(json['team']),
      teamName: (json['team_name'] ?? '').toString(),
      teamShortName: (json['team_short_name'] ?? '').toString(),
      teamLogo: (logo == null || logo.isEmpty) ? null : logo,
      groupName: (json['group_name'] ?? '').toString(),
      points: _asInt(json['points']),
      matchesPlayed: _asInt(json['matches_played']),
      isActive: json['is_active'] ?? true,
    );
  }
}


class BulkAllocateResult {
  final int requestedTournaments;
  final int requestedTeams;
  final int totalPairsRequested;
  final int createdCount;
  final int skippedExistingCount;
  final List<TournamentTeam> created;

  BulkAllocateResult({
    required this.requestedTournaments,
    required this.requestedTeams,
    required this.totalPairsRequested,
    required this.createdCount,
    required this.skippedExistingCount,
    required this.created,
  });

  factory BulkAllocateResult.fromJson(Map<String, dynamic> json) {
    return BulkAllocateResult(
      requestedTournaments: json['requested_tournaments'] ?? 0,
      requestedTeams: json['requested_teams'] ?? 0,
      totalPairsRequested: json['total_pairs_requested'] ?? 0,
      createdCount: json['created_count'] ?? 0,
      skippedExistingCount: json['skipped_existing_count'] ?? 0,
      created: (json['created'] as List<dynamic>? ?? [])
          .map((e) => TournamentTeam.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Response of POST /tournament-teams/bulk-deallocate/
class BulkDeallocateResult {
  final int deletedCount;

  BulkDeallocateResult({required this.deletedCount});

  factory BulkDeallocateResult.fromJson(Map<String, dynamic> json) {
    return BulkDeallocateResult(deletedCount: json['deleted_count'] ?? 0);
  }
}