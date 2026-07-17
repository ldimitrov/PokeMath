import 'dart:math';

import 'package:flutter/material.dart';

import '../data/pokedex.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../widgets/pokemon_image.dart';

class TeamScreen extends StatefulWidget {
  final Profile profile;
  const TeamScreen({super.key, required this.profile});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<OwnedPokemon>? _team;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final team = await DatabaseHelper.instance.getTeam(widget.profile.id);
    if (mounted) setState(() => _team = team);
  }

  Future<void> _setActive(OwnedPokemon p) async {
    widget.profile.activePokemonId = p.id;
    await DatabaseHelper.instance.updateProfile(widget.profile);
    setState(() {});
  }

  Future<void> _evolve(OwnedPokemon p) async {
    final species = speciesById(p.speciesId);
    final targets = species.evolvesTo;
    final newId = targets[Random().nextInt(targets.length)];
    p.speciesId = newId;
    p.energy = 0;
    await DatabaseHelper.instance.updatePokemon(p);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entwicklung! ✨'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PokemonImage(speciesId: newId, size: 160),
            Text(
              '${species.name} hat sich zu ${speciesById(newId).name} entwickelt!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Wow!')),
        ],
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final team = _team;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Meine Pokémon')),
      body: SafeArea(
        child: team == null
            ? const Center(child: CircularProgressIndicator())
            : team.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Du hast noch keine Pokémon.\n\nLöse Aufgaben, sammle Punkte und verdiene Pokébälle!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: team.length,
                    itemBuilder: (_, i) {
                      final p = team[i];
                      final species = speciesById(p.speciesId);
                      final isActive =
                          p.id == widget.profile.activePokemonId;
                      final canEvolve = species.canEvolve &&
                          p.energy >= (species.evolvesAtEnergy ?? 0);
                      return Card(
                        color: isActive ? scheme.primaryContainer : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              PokemonImage(speciesId: p.speciesId, size: 72),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(species.name,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    Text(species.evolvesAtEnergy != null
                                        ? '⚡ ${p.energy} / ${species.evolvesAtEnergy}'
                                        : '⚡ ${p.energy}'),
                                    if (isActive)
                                      const Text('Dein Begleiter ⭐',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  if (canEvolve)
                                    FilledButton(
                                        onPressed: () => _evolve(p),
                                        child: const Text('Entwickeln!')),
                                  if (!isActive)
                                    TextButton(
                                        onPressed: () => _setActive(p),
                                        child: const Text('Auswählen')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
