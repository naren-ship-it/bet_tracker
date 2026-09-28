class ApiConstants {
  ApiConstants._();

  // TODO:
  static const String baseUrl = 'http://192.168.1.23:8000/api';

  static const String login = '/auth/login/';
  static const String signup = '/auth/register/';
  static const String forgotPasswordRequest = '/auth/forget-password/';
  static const String forgotPasswordVerifyOtp = '/auth/verify-otp/';
  static const String forgotPasswordReset = '/auth/reset-password/';

  // ─── Player Endpoints ───────────────────────────────────────────────────────
  static const String players = '/players/';
  static String playerById(int id) => '/players/$id/';
  static const String playerRoles    = '/player-roles/';
  static const String battingStyles  = '/batting-styles/';
  static const String bowlingStyles  = '/bowling-styles/';
  static const String baseImageUrl = 'http://192.168.1.23:8000';
}