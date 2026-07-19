import 'package:flutter/material.dart';

import '../data/pokedex.dart';
import '../db/database_helper.dart';
import '../logic/exercise_generator.dart';
import '../models/models.dart';
import '../widgets/category_style.dart';
import '../widgets/fancy_progress.dart';
import '../widgets/pokemon_image.dart';
import 'catch_screen.dart';
import 'exercise_screen.dart';
import 'team_screen.dart';

class HomeScreen extends StatefulWidget {
  final Profile profile;
  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OwnedPokemon? _active;

  Profile get profile => widget.profile;

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  Future<void> _loadActive() async {
    final team = await DatabaseHelper.instance.getTeam(profile.id);
    OwnedPokemon? active;
    for (final p in team) {
      if (p.id == profile.activePokemonId) active = p;
    }
    // Fallback: erstes Pokémon als Begleiter wählen.
    if (active == null && team.isNotEmpty) {
      active = team.first;
      profile.activePokemonId = active.id;
      await DatabaseHelper.instance.updateProfile(profile);
    }
    if (mounted) setState(() => _active = active);
  }

  Future<void> _startExercise(ExerciseType type) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ExerciseScreen(profile: profile, type: type, active: _active)));
    _loadActive();
    setState(() {});
  }

  Future<void> _openBall() async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CatchScreen(profile: profile)));
    _loadActive();
    setState(() {});
  }

  Future<void> _openTeam() async {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TeamScreen(profile: profile)));
    _loadActive();
    setState(() {});
  }

  /// Klassenstufe wechseln — jederzeit, auch zurück zum Auffrischen.
  Future<void> _switchGrade() async {
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('In welcher Klasse möchtest du üben?'),
        children: [
          for (final (g, name, enabled) in [
            (0, 'Vorschule (bis 10)', true),
            (1, 'Klasse 1 (bis 20)', true),
            (2, 'Klasse 2', false),
            (3, 'Klasse 3', false),
            (4, 'Klasse 4', false),
          ])
            SimpleDialogOption(
              onPressed: enabled ? () => Navigator.pop(ctx, g) : null,
              child: Row(
                children: [
                  if (profile.grade == g)
                    const Icon(Icons.check, size: 20)
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 8),
                  Text(
                    enabled ? name : '$name — kommt bald!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: profile.grade == g
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: enabled
                          ? null
                          : Theme.of(ctx)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (choice != null && choice != profile.grade) {
      profile.grade = choice;
      await DatabaseHelper.instance.updateProfile(profile);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = _active;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hallo, ${profile.name}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.school),
            tooltip: 'Klassenstufe wechseln',
            onPressed: _switchGrade,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('⭐ ${profile.points}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Begleiter-Karte
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openTeam,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (active != null)
                        PokemonImage(speciesId: active.speciesId, size: 90)
                      else
                        Icon(Icons.catching_pokemon,
                            size: 90,
                            color: scheme.primary.withValues(alpha: 0.3)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: active == null
                            ? const Text(
                                'Noch kein Pokémon.\nSammle Punkte für einen Pokéball!',
                                style: TextStyle(fontSize: 16))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(speciesById(active.speciesId).name,
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  const Text('Dein Begleiter'),
                                  const SizedBox(height: 8),
                                  _EnergyBar(pokemon: active),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Pokéball-Fortschritt
            Card(
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.catching_pokemon),
                        const SizedBox(width: 8),
                        Text(
                            profile.pokeballs > 0
                                ? 'Du hast ${profile.pokeballs} Pokéball${profile.pokeballs == 1 ? '' : 'e'}!'
                                : 'Nächster Pokéball:',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FancyProgressBar(
                      value: profile.ballProgress / 100,
                      colors: const [Color(0xFFFF7043), Color(0xFFEE1515)],
                    ),
                    const SizedBox(height: 4),
                    Text('${profile.ballProgress} / 100 Punkte'),
                    if (profile.pokeballs > 0) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openBall,
                          icon: const Icon(Icons.catching_pokemon),
                          label: const Text('Pokéball öffnen!'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Wähle deine Aufgaben:',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(profile.gradeName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                for (final type in typesForGrade(profile.grade))
                  Material(
                    color: type.tileColor,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _startExercise(type),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(type.emoji,
                                style: const TextStyle(fontSize: 34)),
                            const SizedBox(height: 8),
                            Text(type.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: type.color)),
                            const SizedBox(height: 4),
                            Text(type.subtitleFor(profile.grade),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openTeam,
              icon: const Icon(Icons.pets),
              label: const Text('Meine Pokémon',
                  style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergyBar extends StatelessWidget {
  final OwnedPokemon pokemon;
  const _EnergyBar({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final species = speciesById(pokemon.speciesId);
    final target = species.evolvesAtEnergy;
    if (target == null) {
      return Text('⚡ ${pokemon.energy} Energie');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FancyProgressBar(
          value: (pokemon.energy / target).clamp(0.0, 1.0),
          colors: const [Color(0xFFFFD54F), Color(0xFFFFA000)],
          height: 12,
        ),
        const SizedBox(height: 2),
        Text('⚡ ${pokemon.energy} / $target bis zur Entwicklung',
            style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
