import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _userName;
  bool _isOffline = false;

  bool get isLoggedIn => _token != null || _isOffline;
  bool get isOffline  => _isOffline;
  String get userName => _userName ?? 'Student';

  AuthService() {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    _token    = prefs.getString('auth_token');
    _userName = prefs.getString('user_name');
    _isOffline = prefs.getBool('offline_mode') ?? false;
    notifyListeners();
  }

  /// Returns true on success.
  /// Replace the mock below with a real API call for production.
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // simulate network
    if (email.isNotEmpty && password.length >= 6) {
      _token    = 'token_${email.hashCode}';
      _userName = email.split('@').first;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_name', _userName!);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String email, String password) async {
    // Same mock — swap for real API
    return login(email, password);
  }

  Future<void> continueOffline() async {
    _isOffline = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', true);
    notifyListeners();
  }

  Future<void> logout() async {
    _token     = null;
    _userName  = null;
    _isOffline = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('offline_mode');
    notifyListeners();
  }
}