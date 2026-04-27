import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'viewmodels/timetable_viewmodel.dart';
import 'viewmodels/free_slots_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'services/notification_service.dart';
import 'views/splash.dart';
import 'views/dashboard.dart';
import 'views/profile_settings.dart';
import 'views/timetable_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set sstem UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF001F3F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).catchError((error) {
    debugPrint('Firebase initialization error: $error');
  });

  // Initialize local notifications
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // App-level ViewModels (long-lived, created once)
        ChangeNotifierProvider(create: (_) => TimetableViewModel()),
        ChangeNotifierProvider(create: (_) => FreeSlotsViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        // SectionDetailsViewModel & TeacherDetailsViewModel are created
        // locally at navigation time (they require a section/teacher ID).
      ],
      child: MaterialApp(
        title: 'CUI Timetable',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF001F3F),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0074D9),
            primary: const Color(0xFF001F3F),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF001F3F),
            foregroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF9FAFB),
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          primaryColor: const Color(0xFF001F3F),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0074D9),
            primary: const Color(0xFF001F3F),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF001F3F),
            foregroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          scaffoldBackgroundColor: const Color(0xFF1A202C),
          fontFamily: 'Roboto',
        ),
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/timetable': (context) => const TimetableScreen(),
          '/settings': (context) => const ProfileSettingsScreen(),
        },
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}