import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:tee_time/Screens/courseCardPage.dart';
import 'package:tee_time/Helper/databaseHelperPage.dart';
import 'package:tee_time/user_state.dart';
import 'bookingPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'customDrawer.dart';
import 'package:tee_time/Helper/mapHandler.dart';
import 'package:tee_time/Screens/reservationsPage.dart';
import 'package:tee_time/Screens/notificationsPage.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  List<Map<String, dynamic>> golfCourses = [];
  List<Map<String, dynamic>> filteredCourses = [];
  final Set<String> likedCourseIds = {};
  final ScrollController _scrollController = ScrollController();
  bool _showTopFade = false;
  bool _showBottomFade = true;
  late final String currentUserEmail;
  int _selectedIndex = 0;
  String? profileImagePath;
  bool _isDrawerOpen = false;
  String fetchedUserName = "";
  String fetchedUserHandicap = "";

  @override
  void initState() {
    super.initState();
    currentUserEmail = Provider.of<UserState>(context, listen: false).email;
    loadGolfCourses();
    loadLikedCourses();
    loadProfileImage();
    loadUserDetails();
    _scrollController.addListener(() {
      setState(() {
        _showTopFade = _scrollController.offset > 10;
        if (_scrollController.hasClients) {
          _showBottomFade =
              _scrollController.offset < _scrollController.position.maxScrollExtent - 10;
        }
      });
    });
  }

  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profileImagePath = prefs.getString("profileImage_$currentUserEmail");
    });
  }

  Future<void> loadGolfCourses() async {
    try {
      final String response = await rootBundle.loadString('assets/data/golf.json');
      final Map<String, dynamic> data = json.decode(response);
      setState(() {
        golfCourses = data.entries.map<Map<String, dynamic>>((entry) {
          final courseData = Map<String, dynamic>.from(entry.value);
          courseData["id"] = entry.key;
          return courseData;
        }).toList();
        filteredCourses = List.from(golfCourses);
      });
    } catch (e) {
      debugPrint("Error loading golf courses: $e");
    }
  }

  Future<void> loadLikedCourses() async {
    final liked = await DatabaseHelper().getLikedCourses(currentUserEmail);
    setState(() {
      likedCourseIds.addAll(liked);
    });
  }

  Future<void> loadUserDetails() async {
    final user = await DatabaseHelper().getUser(currentUserEmail);
    if (user != null) {
      setState(() {
        fetchedUserName = user['name'] ?? "";
        fetchedUserHandicap = user['handicap'] ?? "";
      });
    }
  }

  Future<void> updateLikes() async {
    await DatabaseHelper().updateLikedCourses(currentUserEmail, likedCourseIds);
  }

  Future<void> _refresh() async {
    await loadGolfCourses();
    await loadLikedCourses();
    await loadUserDetails();
  }

  void _filterCourses(String query) {
    setState(() {
      filteredCourses = query.isEmpty
          ? List.from(golfCourses)
          : golfCourses
          .where((course) => course["Name"].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _logout() async {
    await Provider.of<UserState>(context, listen: false).clearEmail();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ReservationsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const NotificationsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider profileImage;
    if (profileImagePath != null && profileImagePath!.isNotEmpty) {
      profileImage = FileImage(File(profileImagePath!));
    } else {
      profileImage = const AssetImage('assets/img/profile.png');
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tee Time",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Anton',
            fontSize: 45,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/profileEdit',
                  arguments: currentUserEmail,
                );
              },
              child: CircleAvatar(
                backgroundImage: profileImage,
              ),
            ),
          ),
        ],
        backgroundColor: const Color.fromRGBO(37, 42, 46, 1),
      ),
      drawer: CustomDrawer(
        currentUserEmail: currentUserEmail,
        profileImagePath: profileImagePath,
        userName: fetchedUserName,
        userHandicap: fetchedUserHandicap,
        onLogout: _logout,
      ),
      onDrawerChanged: (isOpen) {
        setState(() {
          _isDrawerOpen = isOpen;
        });
      },
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromRGBO(37, 42, 46, 1),
                  Color.fromRGBO(50, 60, 68, 1),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          onChanged: _filterCourses,
                          decoration: InputDecoration(
                            hintText: "Search golf courses...",
                            hintStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Map container remains unchanged.
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[700],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: const MapHandler(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Choose Course",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/showAll');
                        },
                        child: Text(
                          "Show All >",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: _refresh,
                          child: GridView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            cacheExtent: 1000,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: filteredCourses.length,
                            itemBuilder: (context, index) {
                              final course = filteredCourses[index];
                              final bool isLiked = likedCourseIds.contains(course["id"]);
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingPage(course: course),
                                    ),
                                  );
                                },
                                child: CourseCard(
                                  course: course,
                                  isLiked: isLiked,
                                  onLikeToggle: () {
                                    setState(() {
                                      if (isLiked) {
                                        likedCourseIds.remove(course["id"]);
                                      } else {
                                        likedCourseIds.add(course["id"]);
                                      }
                                    });
                                    updateLikes();
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              opacity: _showTopFade ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                height: 30,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color.fromRGBO(37, 42, 46, 1),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              opacity: _showBottomFade ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                height: 30,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Color.fromRGBO(50, 60, 68, 1),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isDrawerOpen)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromRGBO(37, 42, 46, 1),
        selectedItemColor: Colors.amber.shade700,
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Reservations",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notifications",
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}
