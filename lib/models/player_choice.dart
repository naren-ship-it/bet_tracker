class PlayerChoice {
  final int id;
  final String name;

  const PlayerChoice({required this.id, required this.name});

  factory PlayerChoice.fromJson(Map<String, dynamic> json) => PlayerChoice(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
      );
}