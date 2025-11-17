import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  final Session session;

  const ProfileScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final user = session.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Felhasználói adatok',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(user.email ?? 'Nincs email'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text('User ID'),
                subtitle: Text(user.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

