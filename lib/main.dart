import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rent_map/screens/LoginScreen.dart';
import 'package:rent_map/widgets/NavBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/SettingsService.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _settings = SettingsService();
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _showBkkStops = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = await _settings.loadThemeMode();
    final bkk = await _settings.loadBkkStopsEnabled();
    if (mounted) {
      setState(() {
        _themeMode = theme;
        _showBkkStops = bkk;
        _ready = true;
      });
    }
  }

  ThemeMode get _materialThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> _updateTheme(AppThemeMode mode) async {
    await _settings.saveThemeMode(mode);
    if (mounted) {
      setState(() => _themeMode = mode);
    }
  }

  Future<void> _updateBkk(bool value) async {
    await _settings.saveBkkStopsEnabled(value);
    if (mounted) {
      setState(() => _showBkkStops = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Albitérkép',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _materialThemeMode,
      home: AuthGate(
        showBkkStops: _showBkkStops,
        onBkkToggle: _updateBkk,
        themeMode: _themeMode,
        onThemeModeChanged: _updateTheme,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.showBkkStops,
    required this.onBkkToggle,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final bool showBkkStops;
  final ValueChanged<bool> onBkkToggle;
  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeModeChanged;

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
    _session = supabase.auth.currentSession;
    supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _session = data.session;
          _initialized = true;
        });
      }
    });
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session == null) {
      return const LoginScreen();
    }

    return NavBar(
      session: _session!,
      showBkkStops: widget.showBkkStops,
      onBkkToggle: widget.onBkkToggle,
      themeMode: widget.themeMode,
      onThemeModeChanged: widget.onThemeModeChanged,
    );
  }
}
