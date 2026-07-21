import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_service.dart';

String hashPassword(String plain) {
  final bytes = utf8.encode(plain);
  return sha256.convert(bytes).toString();
}

class AuthService extends ChangeNotifier {
  String? _email;
  String? _userName;
  bool    _isOffline = false;

  bool   get isLoggedIn => _email != null || _isOffline;
  bool   get isOffline  => _isOffline;
  String get userName   => _userName ?? 'Student';
  String get email      => _email ?? '';

  AuthService() { _restore(); }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    _email     = prefs.getString('user_email');
    _userName  = prefs.getString('user_name');
    _isOffline = prefs.getBool('offline_mode') ?? false;
    notifyListeners();
  }

  Future<String?> register(String name, String email, String password) async {
    if (name.trim().isEmpty)  return 'Name is required';
    if (!email.contains('@')) return 'Invalid email address';
    if (password.length < 6)  return 'Password must be at least 6 characters';

    final ok = await DBService.instance.registerUser(
        name.trim(), email.trim().toLowerCase(), hashPassword(password));
    if (!ok) return 'Email already registered. Please sign in.';

    await _saveSession(name.trim(), email.trim().toLowerCase());
    return null;
  }

  Future<String?> login(String email, String password) async {
    if (email.isEmpty)    return 'Email is required';
    if (password.isEmpty) return 'Password is required';

    final user = await DBService.instance.loginUser(
        email.trim().toLowerCase(), hashPassword(password));
    if (user == null) return 'Incorrect email or password';

    await _saveSession(user['name'] as String, email.trim().toLowerCase());
    return null;
  }

  Future<void> _saveSession(String name, String email) async {
    _userName  = name;
    _email     = email;
    _isOffline = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('user_name',  name);
    await prefs.remove('offline_mode');
    notifyListeners();
  }

  Future<void> continueOffline() async {
    _isOffline = true;
    _email     = 'guest@offline';
    _userName  = 'Guest';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', true);
    notifyListeners();
  }

  Future<void> logout() async {
    if (_email != null && !_isOffline) {
      await DBService.instance.logActivity(_email!, 'LOGOUT', 'Signed out');
    }
    _email     = null;
    _userName  = null;
    _isOffline = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('offline_mode');
    notifyListeners();
  }
}