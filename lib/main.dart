import 'package:flutter/material.dart';
import 'login.dart';
import 'welcome.dart';
import 'intro_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'noti.dart';

late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await Firebase.initializeApp();
  channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
      'This channel is used for important notifications.', // description
      importance: Importance.high);

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await NotificationService.init();
  tz.initializeTimeZones();
  // Run background every 1 minute (adjust ID and interval)
  await AndroidAlarmManager.periodic(
    const Duration(seconds: 5),
    999, // unique ID
    routineBackgroundCheck,
    wakeup: true,
    exact: true,
    rescheduleOnReboot: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // 👈 This replaces LoginScreen
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _hasSeenIntro = false;

  @override
  void initState() {
    super.initState();
    _checkIntroStatus();
  }

  Future<void> _checkIntroStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool('intro_seen') ?? false;
    setState(() {
      _hasSeenIntro = seen;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If intro not seen, show guide screen
    if (!_hasSeenIntro) {
      return const IntroductionScreens();
    }
        // Otherwise, check Firebase auth state
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance.authStateChanges(), // 🔄 Listens to auth state
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While checking, show loading
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // User is logged in ✅
          return WelcomeScreen(userEmail: snapshot.data!.email ?? 'Email');
        } else {
          // User is NOT logged in ❌
          return const LoginScreen();
        }
      },
    );
  }
}
