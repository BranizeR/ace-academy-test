import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sports_screen.dart';
import 'screens/batches_screen.dart';
import 'screens/coaches_screen.dart';
import 'screens/students_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/student_profile_screen.dart';
import 'screens/signup_screen.dart';

import 'services/api_service.dart';
import 'services/websocket_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  final bool authenticated = await ApiService.isAuthenticated();
  if (authenticated) {
    WebSocketService.connect();
  }
  runApp(MyApp(authenticated: authenticated));
}

class MyApp extends StatelessWidget {
  final bool authenticated;
  const MyApp({super.key, required this.authenticated});

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
      initialRoute: authenticated
          ? (ApiService.userRole == 'student' ? '/student-profile' : '/dashboard')
          : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/sports': (context) => const SportsScreen(),
        '/batches': (context) => const BatchesScreen(),
        '/coaches': (context) => const CoachesScreen(),
        '/students': (context) => const StudentsScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/student-profile': (context) => const StudentProfileScreen(),
        '/signup': (context) => const SignupScreen(),
      },
    );
  }
}
