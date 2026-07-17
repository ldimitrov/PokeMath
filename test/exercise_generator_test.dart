import 'package:flutter_test/flutter_test.dart';
import 'package:pokemath/logic/exercise_generator.dart';

void main() {
  group('Aufgaben-Generator Klasse 1', () {
    test('Plus/Minus bleibt im Zahlenraum 1-20', () {
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.plusMinus);
        expect(e.answer, inInclusiveRange(1, 20), reason: e.question);
        final m = RegExp(r'(\d+) ([+−]) (\d+)').firstMatch(e.question)!;
        final a = int.parse(m.group(1)!);
        final b = int.parse(m.group(3)!);
        expect(m.group(2) == '+' ? a + b : a - b, e.answer);
        expect(a, inInclusiveRange(1, 20));
        expect(b, inInclusiveRange(1, 20));
      }
    });

    test('Zehnerübergang kreuzt immer die 10, Summe max 19', () {
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.zehner);
        final m = RegExp(r'(\d+) \+ (\d+)').firstMatch(e.question)!;
        final a = int.parse(m.group(1)!);
        final b = int.parse(m.group(2)!);
        expect(a, lessThan(10));
        expect(b, lessThan(10));
        expect(a + b, greaterThan(10), reason: 'muss die 10 kreuzen');
        expect(a + b, lessThanOrEqualTo(19));
        expect(e.answer, a + b);
        expect(e.hint, isNotNull);
      }
    });

    test('Nachbarzahlen: Antwort zwischen 0 und 21', () {
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.nachbar);
        final n = int.parse(RegExp(r'(\d+)\?').firstMatch(e.question)!.group(1)!);
        if (e.question.contains('nach')) {
          expect(e.answer, n + 1);
        } else {
          expect(e.answer, n - 1);
        }
        expect(e.answer, inInclusiveRange(1, 20));
      }
    });

    test('Zahlenfolgen: fehlende Zahl passt in die Reihe, alles <= 20', () {
      for (var i = 0; i < 500; i++) {
        final e = generateExercise(ExerciseType.folge);
        final row = e.question.split('\n')[1];
        final parts = row.split(RegExp(r'\s+'));
        expect(parts.length, 5);
        final numbers = [
          for (final p in parts) p == '★' ? e.answer : int.parse(p)
        ];
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
