import 'package:flutter/material.dart';

import '../data/pokedex.dart';
import '../db/database_helper.dart';
import '../logic/exercise_generator.dart';
import '../models/models.dart';
import '../widgets/numpad.dart';
import '../widgets/pokemon_image.dart';

const int questionsPerRound = 10;

class ExerciseScreen extends StatefulWidget {
  final Profile profile;
  final ExerciseType type;
  final OwnedPokemon? active;

  const ExerciseScreen(
      {super.key, required this.profile, required this.type, this.active});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  late Exercise _exercise;
  int _questionNr = 1;
  String _input = '';
  int _tries = 0;
  int _roundPoints = 0;
  int _correctCount = 0;
  bool _showHint = false;
  String? _feedback;
  bool _feedbackGood = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _exercise = generateExercise(widget.type);
  }

  void _submit() {
    if (_input.isEmpty) return;
    final given = int.parse(_input);
    if (given == _exercise.answer) {
      final earned = _tries == 0 ? 10 : 5;
      setState(() {
        _roundPoints += earned;
        _correctCount++;
        _feedback = _tries == 0
            ? 'Super! +$earned Punkte 🎉'
            : 'Richtig! +$earned Punkte 👍';
        _feedbackGood = true;
      });
      _nextAfterDelay();
    } else {
      _tries++;
      if (_tries >= 2) {
        setState(() {
          _feedback = 'Die richtige Antwort ist ${_exercise.answer}.';
          _feedbackGood = false;
        });
        _nextAfterDelay();
      } else {
        setState(() {
          _feedback = 'Fast! Probier es noch einmal. 💪';
          _feedbackGood = false;
          _input = '';
        });
      }
    }
  }

  void _nextAfterDelay() {
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      if (_questionNr >= questionsPerRound) {
        _finishRound();
      } else {
        setState(() {
          _questionNr++;
          _exercise = generateExercise(widget.type);
          _input = '';
          _tries = 0;
          _showHint = false;
          _feedback = null;
        });
      }
    });
  }

  Future<void> _finishRound() async {
    final profile = widget.profile;
    profile.points += _roundPoints;
    profile.ballProgress += _roundPoints;
    while (profile.ballProgress >= 100) {
      profile.ballProgress -= 100;
      profile.pokeballs++;
    }
    await DatabaseHelper.instance.updateProfile(profile);

    final active = widget.active;
    if (active != null) {
      active.energy += _roundPoints ~/ 2;
      await DatabaseHelper.instance.updatePokemon(active);
    }
    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _SummaryView(state: this);

    final scheme = Theme.of(context).colorScheme;
    final answering = _feedback == null || (!_feedbackGood && _tries < 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.title),
        actions: [
          Center(
              child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('⭐ $_roundPoints',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
          )),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_questionNr - 1) / questionsPerRound,
                minHeight: 10,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 4),
              Text('Aufgabe $_questionNr von $questionsPerRound'),
              const Spacer(),
              Text(
                _exercise.question,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                width: 140,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.primary, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(_input.isEmpty ? '?' : _input,
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 64,
                child: Center(
                  child: _feedback != null
                      ? Text(_feedback!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _feedbackGood
                                  ? Colors.green
                                  : scheme.error))
                      : _exercise.hint != null
                          ? _showHint
                              ? Text(_exercise.hint!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 15))
                              : TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _showHint = true),
                                  icon: const Icon(Icons.lightbulb_outline),
                                  label: const Text('Tipp anzeigen'))
                          : null,
                ),
              ),
              const Spacer(),
              Numpad(
                onDigit: (d) {
                  if (!answering || _input.length >= 2) return;
                  setState(() => _input += '$d');
                },
                onDelete: () {
                  if (_input.isNotEmpty) {
                    setState(
                        () => _input = _input.substring(0, _input.length - 1));
                  }
                },
                onSubmit: _submit,
                submitEnabled: answering && _input.isNotEmpty,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  final _ExerciseScreenState state;
  const _SummaryView({required this.state});

  @override
  Widget build(BuildContext context) {
    final profile = state.widget.profile;
    final active = state.widget.active;
    final gotBall = profile.pokeballs > 0;
    return Scaffold(
      body: SafeArea(
        child: Padding(
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
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                    child:
                        PokemonImage(speciesId: active.speciesId, size: 120)),
              ],
              if (gotBall) ...[
                const SizedBox(height: 16),
                const Text('Du hast einen Pokéball verdient! 🎊',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange)),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(gotBall ? 'Zum Pokéball!' : 'Weiter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
