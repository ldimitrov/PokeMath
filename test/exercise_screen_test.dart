import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemath/logic/exercise_generator.dart';
import 'package:pokemath/models/models.dart';
import 'package:pokemath/screens/exercise_screen.dart';
import 'package:pokemath/widgets/numpad.dart';

Profile testProfile() => Profile(id: 1, name: 'Testi', grade: 1);

Widget wrap(Exercise Function() factory) => MaterialApp(
      home: ExerciseScreen(
        profile: testProfile(),
        type: ExerciseType.plusMinus,
        exerciseFactory: factory,
      ),
    );

Exercise simple() => Exercise(
      lines: [
        [t('2'), t('+'), t('3'), t('='), b(0)]
      ],
      answers: [5],
    );

Future<void> tapDigit(WidgetTester tester, String digit) async {
  await tester.tap(
      find.descendant(of: find.byType(Numpad), matching: find.text(digit)));
  await tester.pump();
}

Future<void> tapOk(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.check));
  await tester.pump();
}

void main() {
  testWidgets('richtige Antwort im ersten Versuch gibt 10 Punkte',
      (tester) async {
    await tester.pumpWidget(wrap(simple));
    expect(find.text('⭐ 0'), findsOneWidget);

    await tapDigit(tester, '5');
    await tapOk(tester);

    expect(find.text('Super! +10 Punkte 🎉'), findsOneWidget);
    expect(find.text('⭐ 10'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text('Aufgabe 2 von 10'), findsOneWidget);
  });

  testWidgets('zweiter Versuch gibt 5 Punkte', (tester) async {
    await tester.pumpWidget(wrap(simple));

    await tapDigit(tester, '9');
    await tapOk(tester);
    expect(find.text('Fast! Probier es noch einmal. 💪'), findsOneWidget);

    await tapDigit(tester, '5');
    await tapOk(tester);
    expect(find.text('Richtig! +5 Punkte 👍'), findsOneWidget);
    expect(find.text('⭐ 5'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1700));
  });

  testWidgets('nach zwei Fehlversuchen wird die Lösung gezeigt',
      (tester) async {
    await tester.pumpWidget(wrap(simple));

    await tapDigit(tester, '9');
    await tapOk(tester);
    await tapDigit(tester, '8');
    await tapOk(tester);

    expect(find.text('Schau, so ist es richtig. 🧐'), findsOneWidget);
    expect(find.text('⭐ 0'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2700));
    expect(find.text('Aufgabe 2 von 10'), findsOneWidget);
  });

  testWidgets('OK springt durch mehrere Felder, dann wird geprüft',
      (tester) async {
    await tester.pumpWidget(wrap(() => Exercise(
          lines: [
            [b(0), t('+'), b(1), t('='), t('10')]
          ],
          answers: [4, 6],
        )));

    await tapDigit(tester, '4');
    await tapOk(tester); // springt zum zweiten Feld, prüft noch nicht
    expect(find.text('Super! +10 Punkte 🎉'), findsNothing);

    await tapDigit(tester, '6');
    await tapOk(tester);
    expect(find.text('Super! +10 Punkte 🎉'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1700));
  });

  testWidgets('Korrekt/Falsch: ein Versuch, falsche Antwort zeigt Lösung',
      (tester) async {
    Exercise trueFalse() => Exercise(
          prompt: 'Ist diese Rechnung korrekt?',
          lines: [
            [t('5'), t('+'), t('10'), t('='), t('14')]
          ],
          isTrue: false,
          solution: 'Richtig ist: 5 + 10 = 15',
        );

    await tester.pumpWidget(wrap(trueFalse));
    expect(find.byType(Numpad), findsNothing);

    await tester.tap(find.text('Korrekt')); // falsche Wahl
    await tester.pump();
    expect(find.textContaining('Richtig ist: 5 + 10 = 15'), findsOneWidget);
    expect(find.text('⭐ 0'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2700));
    expect(find.text('Aufgabe 2 von 10'), findsOneWidget);

    await tester.tap(find.text('Falsch')); // richtige Wahl
    await tester.pump();
    expect(find.text('Super! +10 Punkte 🎉'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
  });

  testWidgets('Vergleich: Auswahl-Buttons, zweiter Versuch gibt 5 Punkte',
      (tester) async {
    Exercise vergleich() => Exercise(
          prompt: 'Vergleiche die Zahlen!',
          lines: [
            [t('7'), b(0), t('5')]
          ],
          choices: const ['<', '=', '>'],
          answers: [2],
        );

    await tester.pumpWidget(wrap(vergleich));
    expect(find.byType(Numpad), findsNothing);

    await tester.tap(find.text('<')); // falsch
    await tester.pump();
    expect(find.text('Fast! Probier es noch einmal. 💪'), findsOneWidget);

    await tester.tap(find.text('>')); // richtig
    await tester.pump();
    expect(find.text('Richtig! +5 Punkte 👍'), findsOneWidget);
    expect(find.text('⭐ 5'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1700));
  });

  testWidgets('Zurück fragt nach, Weiterüben bleibt, Beenden verlässt',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExerciseScreen(
                    profile: testProfile(),
                    type: ExerciseType.plusMinus,
                    exerciseFactory: simple,
                  ),
                ),
              ),
              child: const Text('Start'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Aufgabe 1 von 10'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Runde beenden?'), findsOneWidget);

    await tester.tap(find.text('Weiterüben!'));
    await tester.pumpAndSettle();
    expect(find.text('Aufgabe 1 von 10'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beenden'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
  });
}
