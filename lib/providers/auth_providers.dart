import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isPasswordResetLoading = false;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  bool get isPasswordResetLoading => _isPasswordResetLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _init();   // ← call on construction
  }
  Future<void> _init() async {
    _isLoggedIn = await _authService.isLoggedIn();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> checkAuthentication() async {
    _isLoggedIn = await _authService.isLoggedIn();

    notifyListeners();
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      await _authService.login(
        username: username,
        password: password,
      );

      _isLoggedIn = true;

      return true;
    } catch (e) {
      _errorMessage = _extractError(e);

      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,

  }) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final response = await _authService.signup(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      _isLoggedIn = response.token.isNotEmpty;

      return true;
    } catch (e) {
      _errorMessage = _extractError(e);

      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();

    _isLoggedIn = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD — REQUEST OTP
// ───────────────────────────────────────────────────────────────────────────

Future<bool> requestPasswordReset({
  required String identifier,
}) async {
  _setPasswordResetLoading(true);

  try {
    _errorMessage = null;

    await _authService.requestPasswordReset(
      identifier: identifier,
    );

    return true;
  } catch (e) {
    _errorMessage = _extractError(e);
    return false;
  } finally {
    _setPasswordResetLoading(false);
    notifyListeners();
  }
}

// ───────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD — VERIFY OTP
// ───────────────────────────────────────────────────────────────────────────

Future<bool> verifyPasswordResetOtp({
  required String identifier,
  required String otp,
}) async {
  _setPasswordResetLoading(true);

  try {
    _errorMessage = null;

    await _authService.verifyPasswordResetOtp(
      identifier: identifier,
      otp: otp,
    );

    return true;
  } catch (e) {
    _errorMessage = _extractError(e);
    return false;
  } finally {
    _setPasswordResetLoading(false);
    notifyListeners();
  }
}

// ───────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD — RESET PASSWORD
// ───────────────────────────────────────────────────────────────────────────

  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setPasswordResetLoading(true);

    try {
      _errorMessage = null;

      await _authService.resetPassword(
       
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      return true;
    } catch (e) {
      _errorMessage = _extractError(e);
      return false;
    } finally {
      _setPasswordResetLoading(false);
      notifyListeners();
    }
  }

  void _setPasswordResetLoading(bool value) {
    _isPasswordResetLoading = value;
    notifyListeners();
  }

  String _extractError(Object error) {
    return error.toString().replaceFirst(
          'Exception: ',
          '',
        );
  }


  
}