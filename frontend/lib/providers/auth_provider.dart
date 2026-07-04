import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api);

  final ApiService _api;
  AppUser? _user;
  String? _token;
  bool _loading = true;

  AppUser? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get loading => _loading;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userJson = prefs.getString('user');
    if (_token != null && userJson != null) {
      _api.token = _token;
      _user = AppUser.fromJson(json.decode(userJson) as Map<String, dynamic>);
      try {
        _user = await _api.getMe();
      } catch (_) {
        await logout();
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String phone, String password) async {
    final result = await _api.login(phone, password);
    await _persist(result['access_token'] as String, result['user'] as Map<String, dynamic>);
  }

  Future<String> registerSendOtp({
    required String phone,
    required String password,
    required String fullName,
    String? email,
  }) async {
    final result = await _api.registerSendOtp(
      phone: phone,
      password: password,
      fullName: fullName,
      email: email,
    );
    return result['phone'] as String;
  }

  Future<void> registerVerify(String phone, String code) async {
    final result = await _api.registerVerify(phone, code);
    await _persist(result['access_token'] as String, result['user'] as Map<String, dynamic>);
  }

  Future<String> forgotPasswordSendOtp(String phone) async {
    final result = await _api.forgotPasswordSendOtp(phone);
    return result['phone'] as String;
  }

  Future<void> resetPassword(String phone, String code, String newPassword) async {
    await _api.resetPassword(phone: phone, code: code, newPassword: newPassword);
  }

  Future<AppUser> updateProfile({String? fullName, String? email}) async {
    final updated = await _api.updateProfile(fullName: fullName, email: email);
    _user = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(updated.toJson()));
    notifyListeners();
    return updated;
  }

  Future<void> _persist(String token, Map<String, dynamic> userJson) async {
    _token = token;
    _user = AppUser.fromJson(userJson);
    _api.token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', json.encode(userJson));
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _api.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }
}
