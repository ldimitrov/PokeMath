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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Wow!'),
          ),
        ],
      ),
    );
    _load();
  }

  Future<void> _showDetails(OwnedPokemon p) async {
    final scheme = Theme.of(context).colorScheme;
    final species = speciesById(p.speciesId);
    final chain = evolutionChain(p.speciesId);
    final isActive = p.id == widget.profile.activePokemonId;
    final canEvolve =
        species.canEvolve && p.energy >= (species.evolvesAtEnergy ?? 0);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: PokemonImage(speciesId: species.id, size: 140)),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  species.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isActive)
                const Center(
                  child: Text(
                    'Dein Begleiter ⭐',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                species.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  species.evolvesAtEnergy != null
                      ? '⚡ ${p.energy} / ${species.evolvesAtEnergy} Energie bis zur Entwicklung'
                      : '⚡ ${p.energy} Energie',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Entwicklung:',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < chain.length; i++) ...[
                      if (i > 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.arrow_forward, size: 24),
                        ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final stage in chain[i])
                            _EvolutionStage(
                              species: stage,
                              current: stage.id == species.id,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (canEvolve)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _evolve(p);
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Entwickeln!'),
                ),
              if (!isActive) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    _setActive(p);
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('Als Begleiter wählen'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
                  final isActive = p.id == widget.profile.activePokemonId;
                  final canEvolve =
                      species.canEvolve &&
                      p.energy >= (species.evolvesAtEnergy ?? 0);
                  return Card(
                    color: isActive ? scheme.primaryContainer : null,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showDetails(p),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            PokemonImage(speciesId: p.speciesId, size: 72),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    species.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    species.evolvesAtEnergy != null
                                        ? '⚡ ${p.energy} / ${species.evolvesAtEnergy}'
                                        : '⚡ ${p.energy}',
                                  ),
                                  if (isActive)
                                    const Text(
                                      'Dein Begleiter ⭐',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                if (canEvolve)
                                  FilledButton(
                                    onPressed: () => _evolve(p),
                                    child: const Text('Entwickeln!'),
                                  ),
                                if (!isActive)
                                  TextButton(
                                    onPressed: () => _setActive(p),
                                    child: const Text('Auswählen'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _EvolutionStage extends StatelessWidget {
  final Species species;
  final bool current;

  const _EvolutionStage({required this.species, required this.current});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: current
          ? BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              border: Border.all(color: scheme.primary, width: 2.5),
              borderRadius: BorderRadius.circular(14),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PokemonImage(speciesId: species.id, size: 56),
          Text(
            species.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: current ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
