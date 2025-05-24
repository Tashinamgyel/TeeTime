import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tee_time/Screens/courseCardPage.dart';
import 'package:tee_time/Helper/databaseHelperPage.dart';
import 'package:tee_time/Screens/bookingPage.dart';
import 'package:provider/provider.dart';
import 'package:tee_time/user_state.dart';

class ShowAllCoursesPage extends StatefulWidget {
  const ShowAllCoursesPage({super.key});
  @override
  _ShowAllCoursesPageState createState() => _ShowAllCoursesPageState();
}

class _ShowAllCoursesPageState extends State<ShowAllCoursesPage> {
  List<Map<String, dynamic>> golfCourses = [];
  final Set<String> likedCourseIds = {};
  final ScrollController _scrollController = ScrollController();
  late final String userEmail;

  @override
  void initState() {
    super.initState();
    userEmail = Provider.of<UserState>(context, listen: false).email;
    loadGolfCourses();
    loadLikedCourses();
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
      });
    } catch (e) {
      debugPrint("Error loading golf courses: $e");
    }
  }

  Future<void> loadLikedCourses() async {
    final liked = await DatabaseHelper().getLikedCourses(userEmail);
    setState(() {
      likedCourseIds.addAll(liked);
    });
  }

  Future<void> updateLikes() async {
    await DatabaseHelper().updateLikedCourses(userEmail, likedCourseIds);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Golf Courses", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(37, 42, 46, 1),
      ),
      body: Container(
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
        child: golfCourses.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: golfCourses.length,
          itemBuilder: (context, index) {
            final course = golfCourses[index];
            final bool isLiked = likedCourseIds.contains(course["id"]);
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingPage(course: course),
                ),
              ),
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
    );
  }
}
