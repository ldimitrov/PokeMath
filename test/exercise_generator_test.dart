import 'package:flutter_test/flutter_test.dart';
import 'package:pokemath/logic/exercise_generator.dart';

/// Löst eine Rechenzeile aus Tokens auf: Blanks werden durch die erwarteten
/// Antworten ersetzt, dann wird links vom '=' gerechnet und mit rechts
/// verglichen. Gibt (links, rechts) zurück.
(int, int) evalLine(List<Token> line, List<int> answers) {
  final parts = [
    for (final tok in line) tok.isBlank ? '${answers[tok.blank!]}' : tok.text!
  ];
  final eq = parts.indexOf('=');
  var value = int.parse(parts[0]);
  for (var i = 1; i < eq; i += 2) {
    final n = int.parse(parts[i + 1]);
    value = parts[i] == '+' ? value + n : value - n;
  }
  return (value, int.parse(parts[eq + 1]));
}

void main() {
  group('Aufgaben-Generator Klasse 1', () {
    test('Plus/Minus: Gleichung stimmt, Zahlenraum 1-20', () {
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.plusMinus);
        expect(e.answers.length, 1);
        final (lhs, rhs) = evalLine(e.lines.single, e.answers);
        expect(lhs, rhs);
        expect(e.answers[0], inInclusiveRange(1, 20));
      }
    });

    test('Zehnerübergang: Zerlegung über die 10 stimmt', () {
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.zehner);
        expect(e.answers.length, 4);
        expect(e.lines.length, 2);
        for (final line in e.lines) {
          final (lhs, rhs) = evalLine(line, e.answers);
          expect(lhs, rhs);
        }
        // Beide Zeilen haben dasselbe Ergebnis.
        expect(e.answers[0], e.answers[3]);
        expect(e.answers[0], inInclusiveRange(1, 19));
        // Der erste Zwischenschritt landet genau auf der 10.
        final a = int.parse(e.lines[0].first.text!);
        final op = e.lines[0][1].text!;
        expect(op == '+' ? a + e.answers[1] : a - e.answers[1], 10,
            reason: 'Zwischenschritt muss auf 10 landen');
        expect(e.answers[1], greaterThan(0));
        expect(e.answers[2], greaterThan(0));
      }
    });

    test('Fehlende Zahlen: eingesetzte Zahl macht die Gleichung wahr', () {
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.fehlend);
        expect(e.answers.length, 1);
        final (lhs, rhs) = evalLine(e.lines.single, e.answers);
        expect(lhs, rhs);
        expect(e.answers[0], inInclusiveRange(1, 20));
      }
    });

    test('Kettenaufgaben: 4-5 Zahlen, Summe stimmt und bleibt <= 20', () {
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.kette);
        final numbers = [
          for (final tok in e.lines.single)
            if (!tok.isBlank && int.tryParse(tok.text!) != null)
              int.parse(tok.text!)
        ];
        expect(numbers.length, inInclusiveRange(4, 5));
        expect(numbers.every((n) => n >= 1), isTrue);
        final (lhs, rhs) = evalLine(e.lines.single, e.answers);
        expect(lhs, rhs);
        expect(e.answers[0], lessThanOrEqualTo(20));
      }
    });

    test('Korrekt oder falsch: isTrue passt zur gezeigten Rechnung', () {
      var seenTrue = false, seenFalse = false;
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.korrektFalsch);
        expect(e.isTrueFalse, isTrue);
        final (lhs, rhs) = evalLine(e.lines.single, e.answers);
        expect(lhs == rhs, e.isTrue);
        e.isTrue! ? seenTrue = true : seenFalse = true;
      }
      expect(seenTrue && seenFalse, isTrue);
    });

    test('Nachbarzahlen: Häuser-Tripel oder drei Nachbaraufgaben', () {
      var seenHaus = false, seenAufgaben = false;
      var seenErgebnis = false, seenZahl = false, seenTricky = false;
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.nachbar);
        if (e.lines.length == 1) {
          // Häuser: drei aufeinanderfolgende Zahlen, eine vorgegeben.
          seenHaus = true;
          expect(e.answers.length, 2);
          final values = [
            for (final tok in e.lines.single)
              tok.isBlank ? e.answers[tok.blank!] : int.parse(tok.text!)
          ];
          expect(values.length, 3);
          expect(values[1], values[0] + 1);
          expect(values[2], values[1] + 1);
          expect(values[0], greaterThanOrEqualTo(0));
          expect(values[2], lessThanOrEqualTo(20));
        } else {
          // Nachbaraufgaben: drei Plusaufgaben, Ergebnis steigt um 1.
          seenAufgaben = true;
          expect(e.lines.length, 3);
          final results = <int>[];
          for (final line in e.lines) {
            final (lhs, rhs) = evalLine(line, e.answers);
            expect(lhs, rhs);
            results.add(lhs);
          }
          expect(results[1], results[0] + 1);
          expect(results[2], results[1] + 1);
          expect(results[2], lessThanOrEqualTo(20));
          expect(results[0], greaterThanOrEqualTo(2));
          // Ausfüll-Varianten: Ergebnisse (3 Lücken rechts), wechselnde Zahl
          // (3 Lücken links, Ergebnisse sichtbar) oder tricky (4 Lücken).
          if (e.answers.length == 4) {
            seenTricky = true;
            // Mittlere Zeile hat zwei Lücken.
            expect(e.lines[1].where((tok) => tok.isBlank).length, 2);
          } else {
            expect(e.answers.length, 3);
            if (e.lines[0].last.isBlank) {
              seenErgebnis = true;
            } else {
              seenZahl = true;
            }
          }
        }
      }
      expect(seenHaus && seenAufgaben, isTrue);
      expect(seenErgebnis && seenZahl && seenTricky, isTrue,
          reason: 'alle drei Ausfüll-Varianten sollen vorkommen');
    });

    test('Zahlenfolgen: fehlende Zahl passt in die Reihe, alles <= 20', () {
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.folge);
        final numbers = [
          for (final tok in e.lines.single)
            tok.isBlank ? e.answers[0] : int.parse(tok.text!)
        ];
        expect(numbers.length, 5);
        final step = numbers[1] - numbers[0];
        expect(step == 1 || step == 2, isTrue);
        for (var j = 1; j < 5; j++) {
          expect(numbers[j] - numbers[j - 1], step);
          expect(numbers[j], lessThanOrEqualTo(20));
        }
      }
    });
  });
}
