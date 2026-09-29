// models/tournament_type_model.dart

class TournamentType {
  final int id;
  final String name;
  final bool isActive;

  TournamentType({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  factory TournamentType.fromJson(Map<String, dynamic> json) {
    return TournamentType(
      id: json['id'] as int,
      name: json['name'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'is_active': isActive,
      };
}