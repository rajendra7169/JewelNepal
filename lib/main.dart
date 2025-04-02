import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Global theme controller
class ThemeController with ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _savePreference();
    notifyListeners();
  }

  Future<void> loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");

    // Use a real reCAPTCHA key for web
    if (kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider('{your_recaptcha_v3_site_key}'),
      );
    } else {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.appAttest,
      );
    }
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  // Load theme preference
  await ThemeController().loadPreference();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  final bool isFirebaseInitialized;

  const MyApp({super.key, this.isFirebaseInitialized = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeController _themeController = ThemeController();

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        // Just trigger a rebuild, don't reload auth state
      });
    }
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JewelNepal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
      ),
      themeMode: _themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthStateProvider extends InheritedWidget {
  final bool isLoading;
  final User? currentUser;

  const AuthStateProvider({
    required Widget child,
    required this.isLoading,
    required this.currentUser,
    Key? key,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(AuthStateProvider oldWidget) {
    return isLoading != oldWidget.isLoading ||
        currentUser != oldWidget.currentUser;
  }

  static AuthStateProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthStateProvider>();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else {
          User? user = snapshot.data;
          return AuthStateProvider(
            isLoading: snapshot.connectionState == ConnectionState.waiting,
            currentUser: user,
            child: const AppHomeWrapper(),
          );
        }
      },
    );
  }
}

class AppHomeWrapper extends StatelessWidget {
  const AppHomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = AuthStateProvider.of(context);

    if (authState == null || authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.currentUser == null) {
      return const LoginScreen();
    }

    return const HomeScreen();
  }
}
