import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/MapScreen.dart';
import '../screens/ProfileScreen.dart';

class NavBar extends StatefulWidget {
  final Session session;

  const NavBar({super.key, required this.session});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      Mapscreen(session: widget.session),
      ProfileScreen(session: widget.session),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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

