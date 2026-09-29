class Team {
  final int id;
  final String name;
  final String shortName;
  final int? captain;
  final int? viceCaptain;
  final String homeGround;
  final String? logo; // relative path, e.g. /media/team_logos/csk.jpg
  final String ownerName;
  final String coachName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    this.captain,
    this.viceCaptain,
    this.homeGround = '',
    this.logo,
    this.ownerName = '',
    this.coachName = '',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Full logo URL. Pass your server base, e.g. 'http://127.0.0.1:8000'
  /// (use 10.0.2.2 instead of 127.0.0.1 on the Android emulator).
  String? logoUrl(String baseUrl) {
    if (logo == null || logo!.isEmpty) return null;
    return logo!.startsWith('http') ? logo : '$baseUrl$logo';
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int,
      name: json['name'] ?? '',
      shortName: json['short_name'] ?? '',
      captain: json['captain'] as int?,
      viceCaptain: json['vice_captain'] as int?,
      homeGround: json['home_ground'] ?? '',
      logo: json['logo'] as String?,
      ownerName: json['owner_name'] ?? '',
      coachName: json['coach_name'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? ''),
    );
  }
}

class TeamPageResult {
  final int count;
  final String? next;
  final String? previous;
  final List<Team> results;

  TeamPageResult({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory TeamPageResult.fromJson(Map<String, dynamic> json) {
    return TeamPageResult(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => Team.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}