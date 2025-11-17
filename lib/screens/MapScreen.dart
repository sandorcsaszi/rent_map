import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'AddPlaceScreen.dart';

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bejelentkezve mint:\n${user.email ?? user.id}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Teszt: új hely hozzáadása'),
              onPressed: () async {
                const lat = 47.4979;
                const lng = 19.0402;

                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const AddPlaceScreen(lat: lat, lng: lng),
                  ),
                );

                if (result == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hely sikeresen hozzáadva')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
