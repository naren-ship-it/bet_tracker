import 'package:bet_tracker/models/player_choice.dart';

import '../core/constants/api_constants.dart';

class Player {
  final int? id;
  final String firstName;
  final String lastName;
  final String dob;
  final String country;
  final int? role;
  final int? battingStyle;
  final int? bowlingStyle;
  final int jerseyNumber;
  final String? photo;
  final bool isActive;
  String? get photoUrl {
    if (photo == null || photo!.isEmpty) return null;
    if (photo!.startsWith('http')) return photo; // already full URL
    return '${ApiConstants.baseImageUrl}$photo';     // prepend base URL
}

  const Player({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.country,
    required this.role,
    required this.battingStyle,
    required this.bowlingStyle,
    required this.jerseyNumber,
    this.photo,
    this.isActive = true,
  });

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as int?,
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        dob: json['dob'] as String? ?? '',
        country: json['country'] as String? ?? '',
        role: (json['role'] as num?)?.toInt() ?? 1,
        battingStyle: (json['batting_style'] as num?)?.toInt() ?? 1,
        bowlingStyle: (json['bowling_style'] as num?)?.toInt() ?? 1,
        jerseyNumber: (json['jersey_number'] as num?)?.toInt() ?? 0,
        photo: json['photo'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'dob': dob,
        'country': country,
        if (role != null) 'role': role,
        if (battingStyle != null) 'batting_style': battingStyle,
        if (bowlingStyle != null) 'bowling_style': bowlingStyle,
        if (jerseyNumber != 0) 'jersey_number': jerseyNumber,
        if (photo != null) 'photo': photo,
        'is_active': isActive,
      };

  Player copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? dob,
    String? country,
    int? role,
    int? battingStyle,
    int? bowlingStyle,
    int? jerseyNumber,
    String? photo,
    bool? isActive,
  }) =>
      Player(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        dob: dob ?? this.dob,
        country: country ?? this.country,
        role: role ?? this.role,
        battingStyle: battingStyle ?? this.battingStyle,
        bowlingStyle: bowlingStyle ?? this.bowlingStyle,
        jerseyNumber: jerseyNumber ?? this.jerseyNumber,
        photo: photo ?? this.photo,
        isActive: isActive ?? this.isActive,
      );

  String get fullName => '$firstName $lastName';

  // Adjust these int→label mappings to match your backend enum values
  // static const Map<int, String> roleLabels = {
  //   0: 'Batsman',
  //   1: 'Bowler',
  //   2: 'All-Rounder',
  //   3: 'Wicket-Keeper',
  // };

  // static const Map<int, String> battingStyleLabels = {
  //   0: 'Right Hand',
  //   1: 'Left Hand',
  // };

  // static const Map<int, String> bowlingStyleLabels = {
  //   0: 'Right Arm Fast',
  //   1: 'Right Arm Medium',
  //   2: 'Right Arm Spin',
  //   3: 'Left Arm Fast',
  //   4: 'Left Arm Medium',
  //   5: 'Left Arm Spin',
  // };

  // String get roleLabel => roleLabels[role] ?? 'Unknown';
  // String get battingStyleLabel => battingStyleLabels[battingStyle] ?? 'Unknown';
  // String get bowlingStyleLabel => bowlingStyleLabels[bowlingStyle] ?? 'Unknown';

  String roleName(List<PlayerChoice> choices) =>
    choices.firstWhere((c) => c.id == role,
        orElse: () => PlayerChoice(id: 0, name: '—')).name;

  String battingName(List<PlayerChoice> choices) =>
    choices.firstWhere((c) => c.id == battingStyle,
        orElse: () => PlayerChoice(id: 0, name: '—')).name;

  String bowlingName(List<PlayerChoice> choices) =>
    choices.firstWhere((c) => c.id == bowlingStyle,
        orElse: () => PlayerChoice(id: 0, name: '—')).name;
}