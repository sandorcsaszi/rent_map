import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  bool _loading = false;
  String? _error;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isIOS && state == AppLifecycleState.resumed) {
      if (_loading && mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _signIn(OAuthProvider provider) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await supabase.auth.signInWithOAuth(
        provider,
        redirectTo: 'com.albiterkep.app://auth-callback/',
        authScreenLaunchMode: Platform.isIOS
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      );

      if (!result && mounted) {
        setState(() {
          _error = 'A bejelentkezés megszakadt';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Bejelentkezési hiba: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Albitérkép',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Jelentkezz be a folytatáshoz',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_loading) const CircularProgressIndicator(),
                if (!_loading)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LoginButton(
                        label: 'Google',
                        icon: const Icon(Icons.g_mobiledata),
                        onPressed: () => _signIn(OAuthProvider.google),
                      ),
                      const SizedBox(width: 16),
                      _LoginButton(
                        label: 'GitHub',
                        icon: const Icon(Icons.code),
                        onPressed: () => _signIn(OAuthProvider.github),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  const _LoginButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: Colors.black12,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
