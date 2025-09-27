import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isLandlord => _user?.isLandlord ?? false;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    _user = await ApiService.getCurrentUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.login(email: email, password: password);
      
      if (result['success']) {
        _user = User.fromJson(result['data']['user']);
        notifyListeners();
        return true;
      } else {
        _setError(result['data']['error'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Network error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    bool isLandlord = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.register(
        email: email,
        password: password,
        name: name,
        isLandlord: isLandlord,
      );
      
      if (result['success']) {
        _user = User.fromJson(result['data']['user']);
        notifyListeners();
        return true;
      } else {
        _setError(result['data']['error'] ?? 'Registration failed');
        return false;
      }
    } catch (e) {
      _setError('Network error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await ApiService.logout();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}