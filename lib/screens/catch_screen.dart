import 'dart:math';

import 'package:confetti/confetti.dart';
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
    with TickerProviderStateMixin {
  late final AnimationController _wobble; // sanftes Schaukeln im Leerlauf
  late final AnimationController _rays; // rotierender Strahlenkranz
  late final ConfettiController _confetti;
  Species? _caught;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _wobble = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _rays = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    _confetti =
        ConfettiController(duration: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    _wobble.dispose();
    _rays.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_opening) return;
    _opening = true;

    // Wildes Zappeln, bevor der Ball aufgeht.
    _wobble.duration = const Duration(milliseconds: 90);
    _wobble.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 800));
    _wobble.stop();

    final profile = widget.profile;
    final species = randomCatch(Random());
    profile.pokeballs--;
    final owned =
        await DatabaseHelper.instance.addPokemon(profile.id, species.id);
    // Erstes Pokémon wird automatisch Begleiter.
    profile.activePokemonId ??= owned.id;
    await DatabaseHelper.instance.updateProfile(profile);

    if (mounted) {
      setState(() => _caught = species);
      _confetti.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final caught = _caught;
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Center(
              child: caught == null ? _buildBall() : _buildReveal(caught),
            ),
            ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 35,
              maxBlastForce: 30,
              minBlastForce: 10,
              gravity: 0.2,
              colors: const [
                Color(0xFFEE1515),
                Color(0xFFFFC107),
                Color(0xFF1E88E5),
                Color(0xFF43A047),
                Colors.white,
              ],
            ),
          ],
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
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Tippe darauf, um ihn zu öffnen!',
            style: TextStyle(fontSize: 18, color: Colors.white70)),
        const SizedBox(height: 48),
        GestureDetector(
          onTap: _open,
          child: AnimatedBuilder(
            animation: _wobble,
            builder: (_, child) => Transform.rotate(
              angle: (_wobble.value - 0.5) * (_opening ? 0.7 : 0.35),
              child: Transform.scale(
                scale: 1 + (_wobble.value - 0.5).abs() * 0.12,
                child: child,
              ),
            ),
            child: const Icon(Icons.catching_pokemon,
                size: 190, color: Color(0xFFEE1515)),
          ),
        ),
      ],
    );
  }

  Widget _buildReveal(Species species) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotierender Strahlenkranz hinter dem Pokémon.
              AnimatedBuilder(
                animation: _rays,
                builder: (_, _) => Transform.rotate(
                  angle: _rays.value * 2 * pi,
                  child: CustomPaint(
                    size: const Size(300, 300),
                    painter: _SunburstPainter(
                      color: species.id == 150
                          ? const Color(0x66E1BEE7)
                          : const Color(0x33FFFFFF),
                    ),
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: PokemonImage(speciesId: species.id, size: 230),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('${species.name}!',
            style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 8),
        Text(
            species.id == 150
                ? 'WOW! Ein legendäres Pokémon!! ✨✨✨'
                : 'ist aus dem Pokéball gekommen! ✨',
            style: const TextStyle(fontSize: 18, color: Colors.white70)),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Toll!'),
        ),
      ],
    );
  }
}

/// Zwölf weiche Lichtstrahlen, die hinter dem gefangenen Pokémon kreisen.
class _SunburstPainter extends CustomPainter {
  final Color color;
  _SunburstPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final paint = Paint()..color = color;
    const rayCount = 12;
    for (var i = 0; i < rayCount; i++) {
      final angle = i * 2 * pi / rayCount;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + radius * cos(angle - 0.12),
            center.dy + radius * sin(angle - 0.12))
        ..lineTo(center.dx + radius * cos(angle + 0.12),
            center.dy + radius * sin(angle + 0.12))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SunburstPainter oldDelegate) =>
      oldDelegate.color != color;
}
