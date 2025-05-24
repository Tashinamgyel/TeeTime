import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';


class Config {
  static const String USER_DB_URL = 'https://teetimedatabase-default-rtdb.firebaseio.com/';
  static const String BOOKING_DB_URL = 'https://godlink-cf6b6-default-rtdb.firebaseio.com/';
  static const String INVITATION_DB_URL = 'https://open-invitation-bee72-default-rtdb.firebaseio.com/';
  static const String NOTIFICATION_DB_URL = 'https://notification-fff1b-default-rtdb.asia-southeast1.firebasedatabase.app/';
}

class DatabaseHelper {
  // ----- User methods -----
  Future<String?> insertUser(Map<String, dynamic> user) async {
    final url = Uri.parse('${Config.USER_DB_URL}users.json');
    try {
      final response = await http.post(url, body: json.encode(user));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['name'];
      } else {
        print('Failed to insert user: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error inserting user: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    final url = Uri.parse('${Config.USER_DB_URL}users.json?orderBy="email"&equalTo="$email"');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.isNotEmpty) {
          final key = data.keys.first;
          Map<String, dynamic> user = data[key];
          user['id'] = key;
          return user;
        }
      } else {
        print('Failed to get user: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error getting user: $e');
    }
    return null;
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> updatedData) async {
    final url = Uri.parse('${Config.USER_DB_URL}users/$userId.json');
    try {
      final response = await http.patch(url, body: json.encode(updatedData));
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user: $e');
    }
    return false;
  }

  Future<void> saveLikedCourses(String userId, List<String> likedIds) async {
    final url = Uri.parse('${Config.USER_DB_URL}users/$userId/likedCourses.json');
    try {
      await http.put(url, body: json.encode(likedIds));
    } catch (e) {
      print('Error saving liked courses: $e');
    }
  }

  Future<Set<String>> getLikedCourses(String email) async {
    final user = await getUser(email);
    if (user == null) return {};
    final liked = user['likedCourses'];
    if (liked is List) {
      return Set<String>.from(liked);
    }
    return {};
  }

  Future<void> updateLikedCourses(String email, Set<String> likedIds) async {
    final user = await getUser(email);
    if (user == null) return;
    final url = Uri.parse('${Config.USER_DB_URL}users/${user['id']}.json');
    try {
      await http.patch(url, body: json.encode({'likedCourses': likedIds.toList()}));
    } catch (e) {
      print('Error updating liked courses: $e');
    }
  }

  // ----- Booking methods -----
  Future<List<Map<String, dynamic>>> getPublicBookings(String courseId) async {
    final url = Uri.parse('${Config.BOOKING_DB_URL}bookings.json?orderBy="courseId"&equalTo="$courseId"');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> bookings = [];
        if (data != null) {
          data.forEach((key, value) {
            if (value['isPublic'] == true) {
              Map<String, dynamic> booking = Map<String, dynamic>.from(value);
              booking['id'] = key;
              bookings.add(booking);
            }
          });
        }
        return bookings;
      } else {
        print('Failed to get public bookings: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching public bookings: $e');
    }
    return [];
  }


  Future<bool> saveBooking(Map<String, dynamic> booking) async {
    final courseId = booking["courseId"];
    final bookingDate = booking["date"];
    final bookingTime = booking["time"];
    String sanitizedTime = bookingTime.replaceAll(":", "-").replaceAll(" ", "");
    String bookingId = "BKG_${courseId}_${bookingDate}_$sanitizedTime";
    final url = Uri.parse('${Config.BOOKING_DB_URL}bookings/$bookingId.json');
    try {
      // Check if booking already exists.
      final checkResponse = await http.get(url);
      if (checkResponse.statusCode == 200 && checkResponse.body != "null") {
        print("Booking conflict detected for id: $bookingId");
        return false;
      }
      final response = await http.put(url, body: json.encode(booking));
      if (response.statusCode == 200) {
        print("Booking saved with id: $bookingId");
        return true;
      } else {
        print('Failed to save booking: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error saving booking: $e');
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getReservations(String userEmail) async {
    final url = Uri.parse('${Config.BOOKING_DB_URL}bookings.json?orderBy="userEmail"&equalTo="$userEmail"');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> reservations = [];
        if (data != null) {
          data.forEach((key, value) {
            Map<String, dynamic> booking = Map<String, dynamic>.from(value);
            booking['id'] = key;
            reservations.add(booking);
          });
        }
        return reservations;
      } else {
        print('Failed to get reservations: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching reservations: $e');
    }
    return [];
  }

  // ----- Invitation methods -----
  Future<bool> saveInvitation(Map<String, dynamic> invitation) async {
    var uuid = Uuid();
    String invitationId = uuid.v4();
    final courseId = invitation["courseId"];
    final url = Uri.parse('${Config.INVITATION_DB_URL}invitations/$courseId/$invitationId.json');
    try {
      final response = await http.put(url, body: json.encode(invitation));
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to save invitation: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error saving invitation: $e');
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getOpenInvitations(String courseId) async {
    final url = Uri.parse('${Config.INVITATION_DB_URL}invitations/$courseId.json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> invitations = [];
        if (data != null) {
          data.forEach((key, value) {
            Map<String, dynamic> invitation = Map<String, dynamic>.from(value);
            invitation['id'] = key;
            invitations.add(invitation);
          });
        }
        return invitations;
      } else {
        print('Failed to get open invitations: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching open invitations: $e');
    }
    return [];
  }

  // ----- Notification methods -----
  Future<bool> sendNotification(Map<String, dynamic> notification) async {
    final url = Uri.parse('${Config.NOTIFICATION_DB_URL}notifications.json');
    try {
      final response = await http.post(url, body: json.encode(notification));
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to send notification: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getNotifications(String toUser) async {
    final url = Uri.parse('${Config.NOTIFICATION_DB_URL}notifications.json?orderBy="toUser"&equalTo="$toUser"');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> notifications = [];
        if (data != null) {
          data.forEach((key, value) {
            Map<String, dynamic> notif = Map<String, dynamic>.from(value);
            notif['id'] = key;
            notifications.add(notif);
          });
        }
        return notifications;
      } else {
        print('Failed to get notifications: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
    return [];
  }

  Future<bool> updateNotification(String notificationId, Map<String, dynamic> updatedData) async {
    final url = Uri.parse('${Config.NOTIFICATION_DB_URL}notifications/$notificationId.json');
    try {
      final response = await http.patch(url, body: json.encode(updatedData));
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to update notification: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error updating notification: $e');
    }
    return false;
  }
}
