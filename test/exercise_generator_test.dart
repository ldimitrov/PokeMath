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
  group('Klassenstufen', () {
    test('Vorschule hat 6 Aufgabentypen inkl. Partnerzahlen und Vergleich',
        () {
      final types = typesForGrade(0);
      expect(types, hasLength(6));
      expect(types, contains(ExerciseType.partner));
      expect(types, contains(ExerciseType.vergleich));
      expect(types, isNot(contains(ExerciseType.zehner)));
      expect(types, isNot(contains(ExerciseType.kette)));
      expect(types, isNot(contains(ExerciseType.nachbar)));
    });

    test('Klasse 1 hat 9 Aufgabentypen ohne Partnerzahlen', () {
      final types = typesForGrade(1);
      expect(types, hasLength(9));
      expect(types, contains(ExerciseType.zerlegen));
      expect(types, contains(ExerciseType.mauer));
      expect(types, isNot(contains(ExerciseType.partner)));
      expect(types, isNot(contains(ExerciseType.vergleich)));
    });
  });

  group('Aufgaben-Generator Vorschule (Zahlenraum bis 10)', () {
    test('Partnerzahlen: Punkte und Antwort ergänzen sich zu 10', () {
      for (var i = 0; i < 200; i++) {
        final e = generateExercise(ExerciseType.partner, grade: 0);
        expect(e.dots, isNotNull);
        expect(e.dots, inInclusiveRange(1, 9));
        expect(e.answers.single, 10 - e.dots!);
        // Nur ein Eingabefeld, keine sichtbare Rechenzeile.
        expect(e.lines.single.single.isBlank, isTrue);
      }
    });

    test('Anzahlen vergleichen: richtiges Symbol, alle drei kommen vor', () {
      var seenLt = false, seenEq = false, seenGt = false;
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.vergleich, grade: 0);
        expect(e.choices, ['<', '=', '>']);
        final line = e.lines.single;
        final a = int.parse(line[0].text!);
        final bb = int.parse(line[2].text!);
        expect(line[1].isBlank, isTrue);
        expect(a, inInclusiveRange(1, 10));
        expect(bb, inInclusiveRange(1, 10));
        final correct = e.choices![e.answers.single];
        if (a < bb) {
          expect(correct, '<');
          seenLt = true;
        } else if (a > bb) {
          expect(correct, '>');
          seenGt = true;
        } else {
          expect(correct, '=');
          seenEq = true;
        }
      }
      expect(seenLt && seenEq && seenGt, isTrue);
    });

    test('alle Vorschul-Rechnungen bleiben im Zahlenraum bis 10', () {
      for (final type in [
        ExerciseType.plusMinus,
        ExerciseType.fehlend,
        ExerciseType.korrektFalsch,
        ExerciseType.folge,
      ]) {
        for (var i = 0; i < 300; i++) {
          final e = generateExercise(type, grade: 0);
          for (final line in e.lines) {
            for (final tok in line) {
              final n = tok.isBlank
                  ? e.answers[tok.blank!]
                  : int.tryParse(tok.text!);
              if (n != null) {
                expect(n, inInclusiveRange(0, 10),
                    reason: '$type: $n über 10');
              }
            }
          }
        }
      }
    });
  });

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

    test('Zehnerübergang: erst Plus, am Ende der Runde Minus', () {
      for (var i = 0; i < 200; i++) {
        // Anfang der Runde: nur Plus; Ende der Runde: nur Minus.
        expect(generateExercise(ExerciseType.zehner, progress: 0)
            .lines[0][1].text, '+');
        expect(generateExercise(ExerciseType.zehner, progress: 0.9)
            .lines[0][1].text, '−');
      }
    });

    test('Zehnerübergang: Zerlegung über die 10 stimmt', () {
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.zehner,
            progress: i.isEven ? 0.0 : 0.9);
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

    test('Kettenaufgaben: werden über die Runde länger (3 → 4 → 5 Zahlen)',
        () {
      for (final (progress, expectedCount) in [(0.0, 3), (0.4, 4), (0.65, 5)]) {
        for (var i = 0; i < 300; i++) {
          final e =
              generateExercise(ExerciseType.kette, progress: progress);
          final numbers = [
            for (final tok in e.lines.single)
              if (!tok.isBlank && int.tryParse(tok.text!) != null)
                int.parse(tok.text!)
          ];
          expect(numbers.length, expectedCount, reason: 'progress $progress');
          expect(numbers.every((n) => n >= 1), isTrue);
          expect(e.lines.single.any((tok) => tok.text == '−'), isFalse,
              reason: 'vor dem Rundenende nur Plus');
          final (lhs, rhs) = evalLine(e.lines.single, e.answers);
          expect(lhs, rhs);
          expect(e.answers[0], lessThanOrEqualTo(20));
        }
      }
    });

    test('Kettenaufgaben am Rundenende: Plus und Minus gemischt, Zwischen'
        'ergebnisse bleiben in 0..20', () {
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.kette, progress: 0.9);
        final line = e.lines.single;
        final ops = [
          for (final tok in line)
            if (tok.text == '+' || tok.text == '−') tok.text
        ];
        expect(ops.length, 4); // 5 Zahlen
        expect(ops, contains('+'));
        expect(ops, contains('−'));
        final (lhs, rhs) = evalLine(line, e.answers);
        expect(lhs, rhs);
        // Zwischenergebnisse Schritt für Schritt prüfen.
        final parts = [
          for (final tok in line.takeWhile((tok) => tok.text != '='))
            tok.text!
        ];
        var value = int.parse(parts[0]);
        for (var j = 1; j < parts.length; j += 2) {
          value = parts[j] == '+'
              ? value + int.parse(parts[j + 1])
              : value - int.parse(parts[j + 1]);
          expect(value, inInclusiveRange(0, 20));
        }
        expect(value, e.answers[0]);
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

    test('Zahlen zerlegen: jede Etage ergibt die Dachzahl', () {
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.zerlegen);
        expect(e.houseSum, inInclusiveRange(5, 10));
        expect(e.lines.length, inInclusiveRange(1, 3));
        expect(e.answers.length, e.lines.length,
            reason: 'genau eine Lücke pro Etage');
        for (final line in e.lines) {
          expect(line.length, inInclusiveRange(2, 3));
          expect(line.where((tok) => tok.isBlank).length, 1);
          var sum = 0;
          for (final tok in line) {
            final n =
                tok.isBlank ? e.answers[tok.blank!] : int.parse(tok.text!);
            expect(n, greaterThanOrEqualTo(1));
            sum += n;
          }
          expect(sum, e.houseSum);
        }
      }
    });

    /// Löst eine Zahlenmauer auf: alle Zeilen (Spitze zuerst, Basis
    /// zuletzt), Blanks durch [answers] ersetzt, prüft die Summenregel.
    void checkPyramid(Exercise e) {
      final rows = [
        for (final line in e.lines)
          [for (final tok in line) tok.isBlank ? e.answers[tok.blank!] : int.parse(tok.text!)]
      ]; // Spitze zuerst ... Basis zuletzt
      for (var r = 0; r < rows.length - 1; r++) {
        final upper = rows[r]; // näher an der Spitze, kürzer
        final lower = rows[r + 1]; // näher an der Basis, länger
        expect(lower.length, upper.length + 1);
        for (var i = 0; i < upper.length; i++) {
          expect(upper[i], lower[i] + lower[i + 1],
              reason: 'Stein muss Summe der zwei Steine darunter sein');
        }
      }
      for (final row in rows) {
        for (final v in row) {
          expect(v, inInclusiveRange(1, 20));
        }
      }
    }

    test('Zahlenmauern: 3er-Basis am Rundenanfang, nur Addition', () {
      for (var i = 0; i < 300; i++) {
        final e = generateExercise(ExerciseType.mauer, progress: 0.2);
        expect(e.pyramid, isTrue);
        expect(e.lines.last.length, 3); // Basis vollständig gegeben
        expect(e.lines.last.every((tok) => !tok.isBlank), isTrue);
        checkPyramid(e);
      }
    });

    test('Zahlenmauern: 4er-Basis in der Rundenmitte, nur Addition', () {
      for (var i = 0; i < 300; i++) {
        final e = generateExercise(ExerciseType.mauer, progress: 0.6);
        expect(e.lines.last.length, 4);
        expect(e.lines.last.every((tok) => !tok.isBlank), isTrue);
        checkPyramid(e);
      }
    });

    test(
        'Zahlenmauern: am Rundenende gibt es zwei Rückwärts-Varianten '
        'unterschiedlicher Schwierigkeit', () {
      var seenEasy = false, seenHard = false;
      for (var i = 0; i < 300; i++) {
        final e = generateExercise(ExerciseType.mauer, progress: 0.9);
        expect(e.lines[1].every((tok) => !tok.isBlank), isTrue); // Mitte
        checkPyramid(e);

        if (e.answers.length == 1) {
          // Einfache Variante: Spitze gegeben, ein Basisstein fehlt.
          seenEasy = true;
          expect(e.lines.first.single.isBlank, isFalse);
          expect(e.lines.last.where((tok) => tok.isBlank).length, 1);
        } else {
          // Schwere Variante: nur die Mitte gegeben, Spitze und zwei
          // Basissteine fehlen — genau ein Basisstein bleibt als Anker.
          seenHard = true;
          expect(e.answers.length, 3);
          expect(e.lines.first.single.isBlank, isTrue);
          expect(e.lines.last.where((tok) => tok.isBlank).length, 2);
          expect(e.lines.last.where((tok) => !tok.isBlank).length, 1);
        }
      }
      expect(seenEasy && seenHard, isTrue);
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
