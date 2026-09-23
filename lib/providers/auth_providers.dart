import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;

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

  String _extractError(Object error) {
    return error.toString().replaceFirst(
          'Exception: ',
          '',
        );
  }
}