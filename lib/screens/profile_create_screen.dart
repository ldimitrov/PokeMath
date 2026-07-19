import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/models.dart';

class ProfileCreateScreen extends StatefulWidget {
  const ProfileCreateScreen({super.key});

  @override
  State<ProfileCreateScreen> createState() => _ProfileCreateScreenState();
}

class _ProfileCreateScreenState extends State<ProfileCreateScreen> {
  final _nameController = TextEditingController();
  int _grade = 1;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final profile =
        await DatabaseHelper.instance.createProfile(name, _grade);
    if (mounted) Navigator.of(context).pop<Profile>(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Neues Profil')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Wie heißt du?', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(fontSize: 24),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Dein Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),
              const Text('In welche Klasse gehst du?',
                  style: TextStyle(fontSize: 22)),
              const SizedBox(height: 12),
              _GradeButton(
                label: 'Vorschule',
                selected: _grade == 0,
                enabled: true,
                onTap: () => setState(() => _grade = 0),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var g = 1; g <= 4; g++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _GradeButton(
                          label: '$g',
                          selected: _grade == g,
                          // Aufgaben gibt es bisher für Vorschule und Klasse 1.
                          enabled: g == 1,
                          onTap: () => setState(() => _grade = g),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Klasse 2 bis 4 kommen bald!',
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5))),
              const Spacer(),
              ElevatedButton(
                onPressed: _nameController.text.trim().isEmpty ? null : _save,
                child: const Text('Los geht\'s!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _GradeButton(
      {required this.label,
      required this.selected,
      required this.enabled,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primary
          : enabled
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: label.length > 2 ? 22 : 28,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? scheme.onPrimary
                          : enabled
                              ? scheme.onSurface
                              : scheme.onSurface.withValues(alpha: 0.3))),
              if (!enabled)
                Icon(Icons.lock, size: 16,
                    color: scheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
