import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tee_time/Helper/utils.dart';

class UserState extends ChangeNotifier {
  String _email = '';
  String get email => _email;

  Future<void> loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString('userEmail') ?? '';
    notifyListeners();
  }

  Future<void> setEmail(String email) async {
    final normalized = normalizeEmail(email);
    if (_isValidEmail(normalized)) {
      _email = normalized;
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('userEmail', normalized);
      notifyListeners();
    } else {
      throw Exception("Invalid email format");
    }
  }

  Future<void> clearEmail() async {
    _email = '';
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userEmail');
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");
    return regex.hasMatch(email);
  }
}
