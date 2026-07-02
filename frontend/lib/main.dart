import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sports_screen.dart';
import 'screens/batches_screen.dart';
import 'screens/coaches_screen.dart';
import 'screens/students_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/student_profile_screen.dart';

import 'services/api_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ace Sports Academy',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
          secondary: Colors.tealAccent,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/sports': (context) => const SportsScreen(),
        '/batches': (context) => const BatchesScreen(),
        '/coaches': (context) => const CoachesScreen(),
        '/students': (context) => const StudentsScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/student-profile': (context) => const StudentProfileScreen(),
      },
    );
  }
}
