import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:tee_time/Screens/courseCardPage.dart';
import 'package:tee_time/Helper/databaseHelperPage.dart';
import 'package:tee_time/user_state.dart';

class LikedCoursesPage extends StatefulWidget {
  const LikedCoursesPage({super.key});

  @override
  State<LikedCoursesPage> createState() => _LikedCoursesPageState();
}

class _LikedCoursesPageState extends State<LikedCoursesPage> {
  List<Map<String, dynamic>> likedCourses = [];
  final Set<String> likedCourseIds = {};
  bool _isLoading = true;
  late final String currentUserEmail;

  @override
  void initState() {
    super.initState();
    currentUserEmail = Provider.of<UserState>(context, listen: false).email;
    loadLikedCourses();
  }

  Future<void> loadLikedCourses() async {
    try {
      // Load all courses from local JSON file.
      final String response = await rootBundle.loadString('assets/data/golf.json');
      final Map<String, dynamic> data = json.decode(response);
      final allCourses = data.entries.map<Map<String, dynamic>>((entry) {
        final courseData = Map<String, dynamic>.from(entry.value);
        courseData["id"] = entry.key;
        return courseData;
      }).toList();

      final liked = await DatabaseHelper().getLikedCourses(currentUserEmail);
      setState(() {
        likedCourseIds.addAll(liked);
        likedCourses = allCourses.where((course) => likedCourseIds.contains(course["id"])).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading liked courses: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> updateLikes() async {
    await DatabaseHelper().updateLikedCourses(currentUserEmail, likedCourseIds);
    await loadLikedCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liked Courses"),
        backgroundColor: const Color.fromRGBO(37, 42, 46, 1),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : likedCourses.isEmpty
            ? const Center(child: Text("No liked courses", style: TextStyle(fontSize: 16, color: Colors.white)))
            : GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: likedCourses.length,
          itemBuilder: (context, index) {
            final course = likedCourses[index];
            return GestureDetector(
              onTap: () {

              },
              child: CourseCard(
                course: course,
                isLiked: true,
                onLikeToggle: () {
                  setState(() {
                    likedCourseIds.remove(course["id"]);
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
