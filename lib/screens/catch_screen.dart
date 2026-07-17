import 'dart:math';

import 'package:flutter/material.dart';

import '../data/pokedex.dart';
import '../db/database_helper.dart';
import '../models/models.dart';
import '../widgets/pokemon_image.dart';

class CatchScreen extends StatefulWidget {
  final Profile profile;
  const CatchScreen({super.key, required this.profile});

  @override
  State<CatchScreen> createState() => _CatchScreenState();
}

class _CatchScreenState extends State<CatchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;
  Species? _caught;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Species _randomSpecies() {
    final pool = catchableSpecies;
    final total = pool.fold<int>(0, (sum, s) => sum + s.catchWeight);
    var roll = Random().nextInt(total);
    for (final s in pool) {
      roll -= s.catchWeight;
      if (roll < 0) return s;
    }
    return pool.first;
  }

  Future<void> _open() async {
    if (_opening) return;
    _opening = true;
    _shake.stop();

    final profile = widget.profile;
    final species = _randomSpecies();
    profile.pokeballs--;
    final owned =
        await DatabaseHelper.instance.addPokemon(profile.id, species.id);
    // Erstes Pokémon wird automatisch Begleiter.
    profile.activePokemonId ??= owned.id;
    await DatabaseHelper.instance.updateProfile(profile);

    if (mounted) setState(() => _caught = species);
  }

  @override
  Widget build(BuildContext context) {
    final caught = _caught;
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Center(
          child: caught == null ? _buildBall() : _buildReveal(caught),
        ),
      ),
    );
  }

  Widget _buildBall() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Ein Pokéball!',
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Tippe darauf, um ihn zu öffnen!',
            style: TextStyle(fontSize: 18, color: Colors.white70)),
        const SizedBox(height: 48),
        GestureDetector(
          onTap: _open,
          child: AnimatedBuilder(
            animation: _shake,
            builder: (_, child) => Transform.rotate(
                angle: (_shake.value - 0.5) * 0.5, child: child),
            child: const Icon(Icons.catching_pokemon,
                size: 180, color: Color(0xFFEE1515)),
          ),
        ),
      ],
    );
  }

  Widget _buildReveal(Species species) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: PokemonImage(speciesId: species.id, size: 220),
        ),
        const SizedBox(height: 24),
        Text('${species.name}!',
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 8),
        Text(
            species.id == 150
                ? 'WOW! Ein legendäres Pokémon!! ✨✨✨'
                : 'ist aus dem Pokéball gekommen! ✨',
            style: const TextStyle(fontSize: 18, color: Colors.white70)),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Toll!'),
        ),
      ],
    );
  }
}
