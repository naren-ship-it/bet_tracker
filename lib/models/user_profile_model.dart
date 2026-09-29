class UserProfile {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String avatar;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatar = '',
  });

  static int _int(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _str(dynamic v) => v?.toString() ?? '';

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: _int(j['id']),
        name: _str(j['name']),
        email: _str(j['email']),
        phone: _str(j['phone']),
        avatar: _str(j['avatar']),
      );

  static Map<String, String> toFields({
    required String name,
    required String email,
    required String phone,
  }) =>
      {
        'name': name,
        'email': email,
        'phone': phone,
      };
}