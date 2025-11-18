import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/PlaceService.dart';
import '../services/SettingsService.dart';

class ProfileScreen extends StatefulWidget {
  final Session session;
  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeModeChanged;
  final bool showBkkStops;
  final ValueChanged<bool> onBkkToggle;

  const ProfileScreen({
    super.key,
    required this.session,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.showBkkStops,
    required this.onBkkToggle,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _placeService = PlaceService();
  final _nameController = TextEditingController();
  bool _loadingProfile = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _error = null;
    });

    try {
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession == null) {
        if (mounted) {
          setState(() {
            _error = 'Session lejárt. Kérlek jelentkezz be újra.';
            _loadingProfile = false;
          });
        }
        return;
      }

      String currentName = widget.session.user.userMetadata?['full_name'] as String?
          ?? widget.session.user.email
          ?? 'Felhasználó';

      try {
        final profile = await _placeService.fetchProfile();
        if (profile != null && profile['full_name'] != null) {
          currentName = profile['full_name'] as String;
        }
      } catch (profileError) {
      }

      if (mounted) {
        _nameController.text = currentName;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Nem sikerült betölteni a profilt: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession == null) {
        if (mounted) {
          setState(() {
            _error = 'Session lejárt. Kérlek jelentkezz be újra.';
            _saving = false;
          });
        }
        return;
      }

      await _placeService.updateProfileName(_nameController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil név frissítve')),
        );
      }
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('oauth_client_id') || errorMessage.contains('AuthRetryableFetchException')) {
        if (mounted) {
          setState(() {
            _error = 'Session lejárt. Kérlek jelentkezz be újra.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Session lejárt'),
              action: SnackBarAction(
                label: 'Kijelentkezés',
                onPressed: _logout,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Nem sikerült menteni: $e';
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'Felhasználói adatok',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Profil név',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Mentés...' : 'Mentés'),
                      onPressed: _saving ? null : _saveProfile,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(widget.session.user.email ?? 'Nincs email'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('User ID'),
                      subtitle: Text(widget.session.user.id),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Beállítások',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildThemeSwitch(),
                  _buildBkkSwitch(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Kijelentkezés'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildThemeSwitch() {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('Dark mode'),
      subtitle: const Text('Világos / sötét mód váltása'),
      trailing: DropdownButton<AppThemeMode>(
        value: widget.themeMode,
        onChanged: (mode) {
          if (mode != null) {
            widget.onThemeModeChanged(mode);
          }
        },
        items: const [
          DropdownMenuItem(
            value: AppThemeMode.system,
            child: Text('Rendszer alapú'),
          ),
          DropdownMenuItem(
            value: AppThemeMode.light,
            child: Text('Világos'),
          ),
          DropdownMenuItem(
            value: AppThemeMode.dark,
            child: Text('Sötét'),
          ),
        ],
      ),
    );
  }

  Widget _buildBkkSwitch() {
    return SwitchListTile(
      secondary: const Icon(Icons.directions_transit),
      title: const Text('BKK megállók'),
      subtitle: const Text('Megállók megjelenítése a térképen'),
      value: widget.showBkkStops,
      onChanged: widget.onBkkToggle,
    );
  }
}
