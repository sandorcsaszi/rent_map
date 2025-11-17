import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Mapscreen extends StatelessWidget {
  final Session session;

  const Mapscreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final user = session.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Albitérkép'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Logged in as:\n${user.email ?? user.id}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
