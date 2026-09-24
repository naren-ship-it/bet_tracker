class ApiConstants {
  ApiConstants._();

  // TODO:
  static const String baseUrl = 'http://192.168.1.23:8000/api';

  static const String login = '/auth/login/';
  static const String signup = '/auth/register/';
  static const String forgotPasswordRequest = '/auth/forget-password/';
  static const String forgotPasswordVerifyOtp = '/auth/verify-otp/';
  static const String forgotPasswordReset = '/auth/reset-password/';
}