import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/MapScreen.dart';
import '../screens/ProfileScreen.dart';
import '../services/SettingsService.dart';

class NavBar extends StatefulWidget {
  final Session session;
  final bool showBkkStops;
  final ValueChanged<bool> onBkkToggle;
  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeModeChanged;

  const NavBar({
    super.key,
    required this.session,
    required this.showBkkStops,
    required this.onBkkToggle,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      Mapscreen(
        session: widget.session,
        showBkkStops: widget.showBkkStops,
      ),
      ProfileScreen(
        session: widget.session,
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        showBkkStops: widget.showBkkStops,
        onBkkToggle: widget.onBkkToggle,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Térkép',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
