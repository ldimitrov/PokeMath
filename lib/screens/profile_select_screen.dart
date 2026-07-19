import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/models.dart';
import 'home_screen.dart';
import 'profile_create_screen.dart';

class ProfileSelectScreen extends StatefulWidget {
  const ProfileSelectScreen({super.key});

  @override
  State<ProfileSelectScreen> createState() => _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends State<ProfileSelectScreen> {
  List<Profile>? _profiles;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profiles = await DatabaseHelper.instance.getProfiles();
    if (mounted) setState(() => _profiles = profiles);
  }

  Future<void> _openProfile(Profile p) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => HomeScreen(profile: p)));
    _load();
  }

  Future<void> _createProfile() async {
    final created = await Navigator.of(context).push<Profile>(
        MaterialPageRoute(builder: (_) => const ProfileCreateScreen()));
    if (created != null) _openProfile(created);
  }

  Future<void> _confirmDelete(Profile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${p.name} löschen?'),
        content: const Text(
            'Alle Punkte und Pokémon dieses Profils gehen verloren!'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.deleteProfile(p.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _profiles;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Icon(Icons.catching_pokemon,
                  size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text('PokeMath',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Text('Rechnen und Pokémon fangen!',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              Expanded(
                child: profiles == null
                    ? const Center(child: CircularProgressIndicator())
                    : profiles.isEmpty
                        ? const Center(
                            child: Text('Noch kein Profil.\nLeg eins an!',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20)))
                        : ListView(
                            children: [
                              for (final p in profiles)
                                Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 8),
                                    leading: CircleAvatar(
                                        radius: 24,
                                        child: Text(p.name.characters.first
                                            .toUpperCase())),
                                    title: Text(p.name,
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        '${p.gradeName} · ${p.points} Punkte'),
                                    trailing:
                                        const Icon(Icons.arrow_forward_ios),
                                    onTap: () => _openProfile(p),
                                    onLongPress: () => _confirmDelete(p),
                                  ),
                                ),
                            ],
                          ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createProfile,
                  icon: const Icon(Icons.add),
                  label: const Text('Neues Profil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
