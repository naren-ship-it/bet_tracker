// models/auth_response.dart

class AuthResponse {
  final bool status;
  final String message;
  final AuthData? data;

  AuthResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        'data': data?.toJson(),
      };

  /// Convenience getter — returns the access token or empty string
  String get token => data?.tokens.access ?? '';
}

// ─────────────────────────────────────────────

class AuthData {
  final UserModel user;
  final AuthTokens tokens;

  AuthData({required this.user, required this.tokens});

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      user: UserModel.fromJson(json['user']),
      tokens: AuthTokens.fromJson(json['tokens']),
    );
  }

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'tokens': tokens.toJson(),
      };
}

// ─────────────────────────────────────────────

class AuthTokens {
  final String refresh;
  final String access;

  AuthTokens({required this.refresh, required this.access});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      refresh: json['refresh'] ?? '',
      access: json['access'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'refresh': refresh,
        'access': access,
      };
}

// ─────────────────────────────────────────────

class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final UserProfile profile;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profile: UserProfile.fromJson(json['profile'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'profile': profile.toJson(),
      };

  String get fullName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : username;
  }
}

// ─────────────────────────────────────────────

class UserProfile {
  final int id;
  final String profileImage;

  UserProfile({required this.id, required this.profileImage});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      profileImage: json['profile_image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_image': profileImage,
      };
}