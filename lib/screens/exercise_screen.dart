import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../data/pokedex.dart';
import '../db/database_helper.dart';
import '../logic/exercise_generator.dart';
import '../models/models.dart';
import '../widgets/category_style.dart';
import '../widgets/fancy_progress.dart';
import '../widgets/numpad.dart';
import '../widgets/pokemon_image.dart';

const int questionsPerRound = 10;

class ExerciseScreen extends StatefulWidget {
  final Profile profile;
  final ExerciseType type;
  final OwnedPokemon? active;

  /// Nur für Tests: liefert feste Aufgaben statt zufälliger.
  final Exercise Function()? exerciseFactory;

  const ExerciseScreen({
    super.key,
    required this.profile,
    required this.type,
    this.active,
    this.exerciseFactory,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  late Exercise _exercise;
  late List<String> _inputs;
  int _active = 0;
  Set<int> _wrong = {};
  int _questionNr = 1;
  int _tries = 0;
  int _roundPoints = 0;
  int _correctCount = 0;
  String? _feedback;
  bool _feedbackGood = false;
  bool _locked = false; // Aufgabe gelöst/aufgegeben, wartet auf nächste
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _newExercise();
  }

  void _newExercise() {
    _exercise =
        widget.exerciseFactory?.call() ??
        generateExercise(
          widget.type,
          progress: (_questionNr - 1) / questionsPerRound,
          grade: widget.profile.grade,
        );
    _inputs = List.filled(_exercise.answers.length, '');
    _active = 0;
    _wrong = {};
    _tries = 0;
    _feedback = null;
    _locked = false;
  }

  int get _firstEmpty => _inputs.indexWhere((s) => s.isEmpty);

  void _onDigit(int d) {
    if (_locked || _inputs[_active].length >= 2) return;
    setState(() => _inputs[_active] += '$d');
  }

  void _onDelete() {
    if (_locked) return;
    setState(() {
      if (_inputs[_active].isNotEmpty) {
        _inputs[_active] = _inputs[_active].substring(
          0,
          _inputs[_active].length - 1,
        );
      } else if (_active > 0) {
        _active--;
      }
    });
  }

  /// OK springt zum nächsten leeren Feld; sind alle gefüllt, wird geprüft.
  void _onSubmit() {
    if (_locked) return;
    final empty = _firstEmpty;
    if (empty >= 0) {
      if (_inputs[_active].isEmpty) return;
      setState(() => _active = empty);
      return;
    }
    final wrong = <int>{
      for (var i = 0; i < _exercise.answers.length; i++)
        if (int.tryParse(_inputs[i]) != _exercise.answers[i]) i,
    };
    if (wrong.isEmpty) {
      _solved(_tries == 0 ? 10 : 5);
    } else {
      _tries++;
      if (_tries >= 2) {
        setState(() {
          // Richtige Werte zeigen, falsche Felder markieren.
          for (final i in wrong) {
            _inputs[i] = '${_exercise.answers[i]}';
          }
          _wrong = wrong;
          _feedback = 'Schau, so ist es richtig. 🧐';
          _feedbackGood = false;
          _locked = true;
        });
        _nextAfterDelay(const Duration(milliseconds: 2600));
      } else {
        setState(() {
          for (final i in wrong) {
            _inputs[i] = '';
          }
          _wrong = wrong;
          _active = wrong.reduce((a, c) => a < c ? a : c);
          _feedback = 'Fast! Probier es noch einmal. 💪';
          _feedbackGood = false;
        });
      }
    }
  }

  /// Auswahl-Aufgaben (z.B. <, =, >): zwei Versuche wie beim Ziffernblock.
  void _onChoice(int idx) {
    if (_locked) return;
    setState(() => _inputs[0] = _exercise.choices![idx]);
    if (idx == _exercise.answers[0]) {
      _solved(_tries == 0 ? 10 : 5);
    } else {
      _tries++;
      if (_tries >= 2) {
        setState(() {
          _inputs[0] = _exercise.choices![_exercise.answers[0]];
          _wrong = {0};
          _feedback = 'Schau, so ist es richtig. 🧐';
          _feedbackGood = false;
          _locked = true;
        });
        _nextAfterDelay(const Duration(milliseconds: 2600));
      } else {
        setState(() {
          _wrong = {0};
          _feedback = 'Fast! Probier es noch einmal. 💪';
          _feedbackGood = false;
        });
      }
    }
  }

  /// Korrekt/Falsch-Aufgaben: nur ein Versuch.
  void _onTrueFalse(bool guess) {
    if (_locked) return;
    if (guess == _exercise.isTrue) {
      _solved(10);
    } else {
      setState(() {
        _feedback = 'Leider nicht. ${_exercise.solution ?? ''}';
        _feedbackGood = false;
        _locked = true;
      });
      _nextAfterDelay(const Duration(milliseconds: 2600));
    }
  }

  void _solved(int earned) {
    setState(() {
      _roundPoints += earned;
      _correctCount++;
      _feedback = earned == 10
          ? 'Super! +$earned Punkte 🎉'
          : 'Richtig! +$earned Punkte 👍';
      _feedbackGood = true;
      _wrong = {};
      _locked = true;
    });
    _nextAfterDelay(const Duration(milliseconds: 1600));
  }

  void _nextAfterDelay(Duration delay) {
    Future.delayed(delay, () {
      if (!mounted) return;
      if (_questionNr >= questionsPerRound) {
        _finishRound();
      } else {
        setState(() {
          _questionNr++;
          _newExercise();
        });
      }
    });
  }

  Future<void> _finishRound() async {
    final profile = widget.profile;
    profile.addPoints(_roundPoints);
    await DatabaseHelper.instance.updateProfile(profile);

    final active = widget.active;
    if (active != null) {
      active.energy += _roundPoints ~/ 2;
      await DatabaseHelper.instance.updatePokemon(active);
    }
    if (mounted) setState(() => _finished = true);
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Runde beenden?'),
        content: Text(
          _roundPoints > 0
              ? 'Bist du sicher? Deine ⭐ $_roundPoints Punkte aus dieser Runde gehen verloren!'
              : 'Bist du sicher?',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Weiterüben!'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Beenden'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _SummaryView(state: this);

    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: widget.type.tileColor,
          foregroundColor: widget.type.color,
          title: Text(
            widget.type.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '⭐ $_roundPoints',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FancyProgressBar(
                  value: (_questionNr - 1) / questionsPerRound,
                  colors: [
                    widget.type.color.withValues(alpha: 0.55),
                    widget.type.color,
                  ],
                  height: 12,
                ),
                const SizedBox(height: 4),
                Text('Aufgabe $_questionNr von $questionsPerRound'),
                // Aufgabenbereich: zentriert, scrollt bei wenig Platz
                // (z.B. dreistöckiges Zahlenhaus auf kleinen Displays).
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_exercise.prompt != null) ...[
                            Text(
                              _exercise.prompt!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_exercise.dots != null) ...[
                            _DotsRow(
                                key: const ValueKey('dots'),
                                filled: _exercise.dots!),
                            const SizedBox(height: 20),
                          ],
                          if (_exercise.houseSum != null)
                            _HouseView(
                              sum: _exercise.houseSum!,
                              floors: [
                                for (final line in _exercise.lines)
                                  _buildLine(line, windowed: true),
                              ],
                            )
                          else if (_exercise.pyramid)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 16),
                              decoration: BoxDecoration(
                                color: widget.type.tileColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var i = 0;
                                      i < _exercise.lines.length;
                                      i++) ...[
                                    if (i > 0) const SizedBox(height: 10),
                                    _buildLine(_exercise.lines[i],
                                        windowed: true),
                                  ],
                                ],
                              ),
                            )
                          else
                            for (final line in _exercise.lines) ...[
                              _buildLine(line),
                              const SizedBox(height: 16),
                            ],
                          SizedBox(
                            height: 64,
                            child: Center(
                              child: _feedback != null
                                  ? Text(
                                      _feedback!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: _feedbackGood
                                            ? Colors.green
                                            : scheme.error,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_exercise.isTrueFalse)
                  _buildTrueFalseButtons()
                else if (_exercise.isChoice)
                  _buildChoiceButtons()
                else
                  Numpad(
                    onDigit: _onDigit,
                    onDelete: _onDelete,
                    onSubmit: _onSubmit,
                    submitEnabled:
                        !_locked &&
                        (_inputs[_active].isNotEmpty || _firstEmpty < 0),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [windowed]: feste Zahlen bekommen ebenfalls einen Kasten (Fenster im
  /// Zahlenhaus), damit "2 1" nicht wie "21" aussieht.
  Widget _buildLine(List<Token> line, {bool windowed = false}) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final token in line)
          if (token.isBlank)
            _BlankBox(
              value: _inputs[token.blank!],
              active:
                  !_locked && !_exercise.isTrueFalse && _active == token.blank,
              wrong: _wrong.contains(token.blank),
              solved: _locked && _feedbackGood,
              onTap: _locked
                  ? null
                  : () => setState(() => _active = token.blank!),
            )
          else if (windowed)
            Container(
              width: 62,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD7B58C), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                token.text!,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold),
              ),
            )
          else
            Text(
              token.text!,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
      ],
    );
  }

  Widget _buildChoiceButtons() {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < _exercise.choices!.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.surfaceContainerHighest,
                foregroundColor: scheme.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onPressed: _locked ? null : () => _onChoice(i),
              child: Text(
                _exercise.choices![i],
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrueFalseButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: _locked ? null : () => _onTrueFalse(true),
            icon: const Icon(Icons.check, size: 28),
            label: const Text('Korrekt'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: _locked ? null : () => _onTrueFalse(false),
            icon: const Icon(Icons.close, size: 28),
            label: const Text('Falsch'),
          ),
        ),
      ],
    );
  }
}

/// Zahlenhaus: Dreiecksdach mit der Zielzahl, darunter die Etagen.
class _HouseView extends StatelessWidget {
  final int sum;
  final List<Widget> floors;
  const _HouseView({required this.sum, required this.floors});

  @override
  Widget build(BuildContext context) {
    const width = 290.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: 82,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _RoofPainter(Color(0xFFE05B4B))),
              ),
              Positioned(
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$sum',
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFFDEBD3),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < floors.length; i++) ...[
                if (i > 0)
                  Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color(0xFFD7B58C)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: floors[i],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RoofPainter extends CustomPainter {
  final Color color;
  const _RoofPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RoofPainter oldDelegate) => oldDelegate.color != color;
}

/// Zehn Punkte wie im Rechenheft: die ersten [filled] sind ausgemalt,
/// mit einer Lücke nach dem fünften Punkt (Kraft der Fünf).
class _DotsRow extends StatelessWidget {
  final int filled;
  const _DotsRow({super.key, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 10; i++)
          Container(
            width: 30,
            height: 30,
            margin: EdgeInsets.only(left: i == 0 ? 0 : (i == 5 ? 14 : 4)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? const Color(0xFF2196F3) : Colors.white,
              border: Border.all(
                color: i < filled
                    ? const Color(0xFF1976D2)
                    : Colors.grey.shade400,
                width: 2,
              ),
            ),
          ),
      ],
    );
  }
}

class _BlankBox extends StatelessWidget {
  final String value;
  final bool active;
  final bool wrong;
  final bool solved;
  final VoidCallback? onTap;

  const _BlankBox({
    required this.value,
    required this.active,
    required this.wrong,
    required this.solved,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = wrong
        ? scheme.error
        : solved
        ? Colors.green
        : active
        ? scheme.primary
        : scheme.outline;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? scheme.primaryContainer.withValues(alpha: 0.5)
              : scheme.surface,
          border: Border.all(
            color: borderColor,
            width: active || wrong ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value.isEmpty ? '' : value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: wrong ? scheme.error : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SummaryView extends StatefulWidget {
  final _ExerciseScreenState state;
  const _SummaryView({required this.state});

  @override
  State<_SummaryView> createState() => _SummaryViewState();
}

class _SummaryViewState extends State<_SummaryView> {
  late final ConfettiController _confetti;

  _ExerciseScreenState get state => widget.state;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(
      duration: const Duration(milliseconds: 1800),
    );
    if (state._correctCount >= 5) _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = state.widget.profile;
    final active = state.widget.active;
    final gotBall = profile.pokeballs > 0;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: state._correctCount >= 8 ? 40 : 20,
              maxBlastForce: 25,
              minBlastForce: 8,
              gravity: 0.25,
              shouldLoop: false,
              colors: const [
                Color(0xFFEE1515),
                Color(0xFFFFC107),
                Color(0xFF1E88E5),
                Color(0xFF43A047),
                Color(0xFF8E24AA),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    state._correctCount >= 8
                        ? 'Fantastisch! 🏆'
                        : state._correctCount >= 5
                        ? 'Gut gemacht! 🎉'
                        : 'Weiter üben! 💪',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${state._correctCount} von $questionsPerRound richtig\n'
                    '⭐ ${state._roundPoints} Punkte verdient'
                    '${active != null ? '\n⚡ ${state._roundPoints ~/ 2} Energie für ${speciesById(active.speciesId).name}' : ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, height: 1.6),
                  ),
                  if (active != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: PokemonImage(
                        speciesId: active.speciesId,
                        size: 120,
                      ),
                    ),
                  ],
                  if (gotBall) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Du hast einen Pokéball verdient! 🎊',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(gotBall ? 'Zum Pokéball!' : 'Weiter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
