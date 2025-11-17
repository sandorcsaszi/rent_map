import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String status = 'not started';

  try {
    status = 'loading .env';
    await dotenv.load(fileName: ".env");

    status = 'initializing supabase';
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    status = 'ok';
  } catch (e, st) {
    debugPrint('Startup error: $e');
    debugPrint('Stack: $st');
    status = 'error: $e';
  }

  runApp(MyApp(startupStatus: status));
}

class MyApp extends StatelessWidget {
  final String startupStatus;
  const MyApp({super.key, required this.startupStatus});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('Startup status: $startupStatus')),
      ),
    );
  }
}
