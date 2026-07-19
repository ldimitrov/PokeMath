import 'dart:math';

import 'package:flutter/material.dart';

import '../data/pokedex.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../widgets/fancy_progress.dart';
import '../widgets/pokemon_image.dart';

class TeamScreen extends StatefulWidget {
  final Profile profile;
  const TeamScreen({super.key, required this.profile});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<OwnedPokemon>? _team;
  Set<int> _discovered = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final team = await DatabaseHelper.instance.getTeam(widget.profile.id);
    final discovered =
        await DatabaseHelper.instance.getDiscovered(widget.profile.id);
    if (mounted) {
      setState(() {
        _team = team;
        _discovered = discovered;
      });
    }
  }

  OwnedPokemon? get _active {
    final team = _team;
    if (team == null) return null;
    for (final p in team) {
      if (p.id == widget.profile.activePokemonId) return p;
    }
    return null;
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
    // Die neue Stufe zählt ab jetzt dauerhaft als entdeckt.
    await DatabaseHelper.instance.markDiscovered(widget.profile.id, newId);
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

  /// Artenkarte: Beschreibung, Typen, Entwicklungskette und alle Exemplare.
  Future<void> _showSpecies(Species species, List<OwnedPokemon> copies) async {
    final scheme = Theme.of(context).colorScheme;
    final chain = evolutionChain(species.id);

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
              Center(child: PokemonImage(speciesId: species.id, size: 130)),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${species.name}  ·  #${species.id.toString().padLeft(3, '0')}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final type in species.types) _TypeBadge(type: type),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                species.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.4),
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
              const SizedBox(height: 16),
              if (copies.isEmpty)
                Text(
                  'Schon entdeckt, aber gerade nicht in deinem Team.\nFange oder entwickle es wieder!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                )
              else ...[
                Text(
                  copies.length == 1
                      ? 'Dein Exemplar:'
                      : 'Deine ${copies.length} Exemplare:',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                for (final copy in copies) _copyRow(ctx, species, copy),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _copyRow(BuildContext sheetCtx, Species species, OwnedPokemon copy) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = copy.id == widget.profile.activePokemonId;
    final canEvolve =
        species.canEvolve && copy.energy >= (species.evolvesAtEnergy ?? 0);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? scheme.primaryContainer.withValues(alpha: 0.5)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${isActive ? '⭐ ' : ''}⚡ ${copy.energy}'
              '${species.evolvesAtEnergy != null ? ' / ${species.evolvesAtEnergy}' : ''}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          if (canEvolve)
            FilledButton(
              onPressed: () {
                Navigator.pop(sheetCtx);
                _evolve(copy);
              },
              child: const Text('Entwickeln!'),
            ),
          if (!isActive)
            TextButton(
              onPressed: () {
                _setActive(copy);
                Navigator.pop(sheetCtx);
              },
              child: const Text('Auswählen'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final team = _team;
    final scheme = Theme.of(context).colorScheme;
    final active = _active;

    // Exemplare pro Art gruppieren.
    final bySpecies = <int, List<OwnedPokemon>>{};
    for (final p in team ?? const <OwnedPokemon>[]) {
      bySpecies.putIfAbsent(p.speciesId, () => []).add(p);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Pokémon')),
      body: SafeArea(
        child: team == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (active != null) ...[
                    Text(
                      'Dein Begleiter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Card(
                      color: scheme.primaryContainer,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showSpecies(
                          speciesById(active.speciesId),
                          bySpecies[active.speciesId]!,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              PokemonImage(
                                  speciesId: active.speciesId, size: 80),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      speciesById(active.speciesId).name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (speciesById(active.speciesId)
                                            .evolvesAtEnergy !=
                                        null) ...[
                                      FancyProgressBar(
                                        value: (active.energy /
                                                speciesById(active.speciesId)
                                                    .evolvesAtEnergy!)
                                            .clamp(0.0, 1.0),
                                        colors: const [
                                          Color(0xFFFFD54F),
                                          Color(0xFFFFA000),
                                        ],
                                        height: 12,
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    Text(
                                      '⚡ ${active.energy}'
                                      '${speciesById(active.speciesId).evolvesAtEnergy != null ? ' / ${speciesById(active.speciesId).evolvesAtEnergy}' : ''}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Entdeckt: ${_discovered.union(bySpecies.keys.toSet()).length} von ${pokedex.length}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.82,
                    children: [
                      for (final species in pokedex)
                        _SpeciesTile(
                          species: species,
                          copies: bySpecies[species.id] ?? const [],
                          discovered: _discovered.contains(species.id) ||
                              bySpecies.containsKey(species.id),
                          isActiveSpecies: active?.speciesId == species.id,
                          onTap: () {
                            final copies = bySpecies[species.id];
                            final discovered =
                                _discovered.contains(species.id) ||
                                    copies != null;
                            if (!discovered) {
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(const SnackBar(
                                    content: Text(
                                        'Dieses Pokémon hast du noch nicht entdeckt!')));
                            } else {
                              _showSpecies(species, copies ?? const []);
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _SpeciesTile extends StatelessWidget {
  final Species species;
  final List<OwnedPokemon> copies;
  final bool discovered;
  final bool isActiveSpecies;
  final VoidCallback onTap;

  const _SpeciesTile({
    required this.species,
    required this.copies,
    required this.discovered,
    required this.isActiveSpecies,
    required this.onTap,
  });

  /// Entsättigt das Artwork für "entdeckt, aber nicht im Team".
  static const _greyscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 0.55, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final owned = copies.isNotEmpty;
    return Material(
      color: discovered
          ? scheme.surfaceContainerHighest
              .withValues(alpha: owned ? 0.6 : 0.35)
          : const Color(0xFF2E2E3E),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (owned)
                    PokemonImage(speciesId: species.id, size: 64)
                  else if (discovered)
                    ColorFiltered(
                      colorFilter: _greyscale,
                      child: PokemonImage(speciesId: species.id, size: 64),
                    )
                  else
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                          Color(0xFF1A1A26), BlendMode.srcIn),
                      child: PokemonImage(speciesId: species.id, size: 64),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    discovered ? species.name : '???',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: !discovered
                          ? Colors.white38
                          : owned
                              ? scheme.onSurface
                              : scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (copies.length > 1)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '×${copies.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (isActiveSpecies)
              const Positioned(
                top: 6,
                left: 6,
                child: Text('⭐', style: TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final PokeType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: type.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
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
