import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tee_time/Helper/databaseHelperPage.dart';
import 'package:tee_time/Helper/localDataHelper.dart';
import 'package:tee_time/Helper/utils.dart';
import 'package:tee_time/user_state.dart';
import 'package:tee_time/Screens/landingPage.dart';
import 'package:tee_time/Screens/reservationsPage.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  final LocalDataHelper localHelper = LocalDataHelper();
  int _selectedIndex = 2; // Notifications index

  @override
  void initState() {
    super.initState();
    loadLocalNotifications();
    refreshNotifications();
  }

  // Load cached notifications from SharedPreferences
  Future<void> loadLocalNotifications() async {
    final userEmail =
    normalizeEmail(Provider.of<UserState>(context, listen: false).email);
    final localData = await localHelper.getCachedNotifications(userEmail);
    setState(() {
      notifications = List<Map<String, dynamic>>.from(localData);
    });
  }

  // Refresh notifications from Firebase and update local cache
  Future<void> refreshNotifications() async {
    final userEmail =
    normalizeEmail(Provider.of<UserState>(context, listen: false).email);
    final fetched = await DatabaseHelper().getNotifications(userEmail);
    setState(() {
      notifications = fetched;
    });
    await localHelper.cacheNotifications(userEmail);
  }

  Future<void> acceptRequest(Map<String, dynamic> notif) async {
    bool updated = await DatabaseHelper()
        .updateNotification(notif['id'], {'status': 'accepted'});
    if (updated) {
      final currentUser =
      normalizeEmail(Provider.of<UserState>(context, listen: false).email);
      final newNotif = {
        'type': 'invitation_accepted',
        'title': 'Invitation Accepted',
        'message':
        'Your request for ${notif['courseName'] ?? 'the invitation'} was accepted. Tap to proceed to booking.',
        'fromUser': currentUser,
        'toUser': notif['fromUser'],
        'invitationId': notif['invitationId'],
        'courseId': notif['courseId'],
        'courseName': notif['courseName'],
        'coursePrice': notif['coursePrice'],
        'date': notif['date'],
        'time': notif['time'],
        'holes': notif['holes'],
        'corner': notif['corner'],
        'status': 'pending',
        'timestamp': DateTime.now().toIso8601String(),
      };
      bool sent = await DatabaseHelper().sendNotification(newNotif);
      if (sent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request accepted and notification sent.")),
        );

        setState(() {
          notifications.removeWhere((element) => element['id'] == notif['id']);
        });

        final userEmail =
        normalizeEmail(Provider.of<UserState>(context, listen: false).email);
        await localHelper.cacheNotifications(userEmail);
      }
    }
  }

  void handleNotificationTap(Map<String, dynamic> notif) {
    if (notif['type'] == 'invitation_accepted') {
      Navigator.pushNamed(context, '/checkout', arguments: {
        'courseId': notif['courseId'],
        'courseName': notif['courseName'] ?? 'Course',
        'coursePrice': notif['coursePrice'] ?? 0,
        'bookingDate': notif['date'],
        'bookingTime': notif['time'],
        'selectedHole': notif['holes'],
        'selectedCorner': notif['corner'],
        'players': 1,
        'isPublic': false,
      });
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const LandingPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const ReservationsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
        break;
      case 2:
      // Already on NotificationsPage.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFF252A2E),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(37, 42, 46, 1),
              Color.fromRGBO(50, 60, 68, 1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: refreshNotifications,
          child: notifications.isEmpty
              ? const Center(
            child: Text(
              "No notifications",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return GestureDetector(
                onTap: () => handleNotificationTap(notif),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey[200]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      title: Text(
                        notif['title'] ?? "Notification",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          notif['message'] ?? "",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      trailing: notif['type'] == 'invitation_request' && notif['status'] == 'pending'
                          ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF252A2E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => acceptRequest(notif),
                        child: const Text(
                          "Accept",
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      )
                          : const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromRGBO(37, 42, 46, 1),
        selectedItemColor: Colors.amber.shade700,
        unselectedItemColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Reservations"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notifications"),
        ],
      ),
    );
  }
}
