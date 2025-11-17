import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rent_map/screens/LoginScreen.dart';
import 'package:rent_map/widgets/NavBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      // iOS-en automatikusan kezelje a deep link-eket
      autoRefreshToken: true,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Albitérkép',
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    final supabase = Supabase.instance.client;

    // Initial session (after app start or cold start)
    _session = supabase.auth.currentSession;

    // Listen to auth state changes
    supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _session = data.session;
          _initialized = true;
        });
      }
    });

    // Mark as initialized after setting up listener
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session == null) {
      return const LoginScreen();
    } else {
      return NavBar(session: _session!);
    }
  }
}
