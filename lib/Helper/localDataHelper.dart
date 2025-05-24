import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tee_time/Helper/databaseHelperPage.dart';

class LocalDataHelper {
  static const String reservationsKeyPrefix = "cachedReservations_";
  static const String notificationsKeyPrefix = "cachedNotifications_";

  Future<void> cacheReservations(String userEmail) async {
    try {
      final dbHelper = DatabaseHelper();
      final reservations = await dbHelper.getReservations(userEmail);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(reservationsKeyPrefix + userEmail, json.encode(reservations));
    } catch (e) {
      print("Error caching reservations: $e");
    }
  }

  Future<List<dynamic>> getCachedReservations(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(reservationsKeyPrefix + userEmail);
    if (data != null) {
      try {
        return json.decode(data);
      } catch (e) {
        print("Error decoding cached reservations: $e");
        return [];
      }
    }
    return [];
  }

  Future<void> cacheNotifications(String userEmail) async {
    try {
      final dbHelper = DatabaseHelper();
      final notifications = await dbHelper.getNotifications(userEmail);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(notificationsKeyPrefix + userEmail, json.encode(notifications));
    } catch (e) {
      print("Error caching notifications: $e");
    }
  }

  Future<List<dynamic>> getCachedNotifications(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(notificationsKeyPrefix + userEmail);
    if (data != null) {
      try {
        return json.decode(data);
      } catch (e) {
        print("Error decoding cached notifications: $e");
        return [];
      }
    }
    return [];
  }
}
