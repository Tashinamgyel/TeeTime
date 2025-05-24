import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tee_time/user_state.dart';
import 'package:tee_time/Screens/loginPage.dart';
import 'package:tee_time/Screens/registrationPage.dart';
import 'package:tee_time/Screens/landingPage.dart';
import 'package:tee_time/Screens/profileEdit.dart';
import 'package:tee_time/Screens/showAllPage.dart';
import 'package:tee_time/Screens/reservationsPage.dart';
import 'package:tee_time/Screens/notificationsPage.dart';
import 'package:tee_time/Screens/checkOutpage.dart';

import 'Screens/likedCoursesPage.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tee Time',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromRGBO(37, 42, 46, 1),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(250, 21, 35, 37),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      supportedLocales: const [
        Locale('en', ''),
        Locale('th', ''), // thai
        Locale('zh', ''), // chinese
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(title: 'Tee Time'),
        '/register': (context) => const RegistrationPage(title: 'Registration'),
        '/landing': (context) => const LandingPage(),
        '/profileEdit': (context) => const ProfileEditPage(),
        '/showAll': (context) => const ShowAllCoursesPage(),
        '/reservations': (context) => const ReservationsPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/likedCourses': (context) => const LikedCoursesPage(),
        '/checkout': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return CheckoutPage(
            course: {
              'id': args['courseId'],
              'Name': args.containsKey('courseName') ? args['courseName'] : 'Course',
              'Price': args.containsKey('coursePrice') ? args['coursePrice'] : 0,
            },
            players: args['players'] ?? 1,
            bookingDate: args['bookingDate'],
            bookingTime: args['bookingTime'],
            selectedHole: args['selectedHole'],
            selectedCorner: args['selectedCorner'],
            isPublic: args['isPublic'] ?? false,
          );
        },
      },
    );
  }
}
