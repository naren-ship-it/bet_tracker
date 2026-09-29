// models/tournament_model.dart

class Tournament {
  final int id;
  final String name;
  final int tournamentType;
  final String tournamentTypeName;
  final String bettingOn;
  final String description;
  final String year;
  final String startDate;
  final String endDate;
  final String status;
  final int? maxTeams;
  final int teamCount;
  final bool isActive;
  final int? createdBy;

  Tournament({
    required this.id,
    required this.name,
    required this.tournamentType,
    required this.tournamentTypeName,
    required this.bettingOn,
    required this.description,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.maxTeams,
    required this.teamCount,
    required this.isActive,
    required this.createdBy,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as int,
      name: json['name'] ?? '',
      tournamentType: json['tournament_type'] as int,
      tournamentTypeName: json['tournament_type_name'] ?? '',
      bettingOn: json['betting_on'] ?? '',
      description: json['description'] ?? '',
      year: json['year']?.toString() ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? 'upcoming',
      maxTeams: json['max_teams'] as int?,
      teamCount: (json['current_team_count'] ?? json['team_count'] ?? 0) as int,
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'] as int?,
    );
  }

  /// Builds the request body for create/update calls.
  static Map<String, dynamic> toFields({
    required String name,
    required int tournamentType,
    required String bettingOn,
    required String description,
    required String year,
    required String startDate,
    required String endDate,
    required String status,
    int? maxTeams,
    required bool isActive,
  }) {
    return {
      'name': name,
      'tournament_type': tournamentType,
      'betting_on': bettingOn,
      'description': description,
      'year': year,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
      if (maxTeams != null) 'max_teams': maxTeams,
      'is_active': isActive,
    };
  }
}