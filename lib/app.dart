import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/firestore_service.dart';
import 'screens/admin_panel_screen.dart';

class RukunApp extends StatelessWidget {
  const RukunApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2563EB); // Biru utama
    const background = Color(0xFFF9FAFB); // Putih bersih

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: Colors.white,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Rukun.ID',
      debugShowCheckedModeBanner: false,
      routes: {
        '/admin': (_) => const _AdminGate(),
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: background,
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: primary,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Color(0x1A000000), // black12
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Color(0x14000000), // black08
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: primary.withOpacity(0.06),
          selectedColor: primary.withOpacity(0.12),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary.withOpacity(0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      home: const _RootGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) {
          return const AuthScreen();
        }
        return const HomeScreen();
      },
    );
  }
}

class _RootGate extends StatefulWidget {
  const _RootGate();
  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool? _seenOnboarding;

  @override
  void initState() {
    super.initState();
    _loadFlag();
  }

  Future<void> _loadFlag() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _seenOnboarding = prefs.getBool('onboarding_done') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_seenOnboarding == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_seenOnboarding == false) {
      return OnboardingScreen(onDone: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_done', true);
        if (!mounted) return;
        setState(() => _seenOnboarding = true);
      });
    }
    return const AuthGate();
  }
}

class _AdminGate extends StatelessWidget {
  const _AdminGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FirestoreAuthBridge.streamIsAdmin(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final isAdmin = snap.data == true;
        if (!isAdmin) {
          return const Scaffold(body: Center(child: Text('Akses ditolak')));
        }
        return const _AdminPanelLoader();
      },
    );
  }
}

class _AdminPanelLoader extends StatelessWidget {
  const _AdminPanelLoader();
  @override
  Widget build(BuildContext context) {
    // Lazy import to avoid circular dep in route table
    return const _AdminPanelEmbed();
  }
}

// Small bridge to avoid direct import at top
class FirestoreAuthBridge {
  static Stream<bool> streamIsAdmin() => FirestoreService.instance.streamIsAdmin();
}

// Indirection widget to import the admin screen
class _AdminPanelEmbed extends StatelessWidget {
  const _AdminPanelEmbed();
  @override
  Widget build(BuildContext context) {
    return const AdminPanelScreen();
  }
}
