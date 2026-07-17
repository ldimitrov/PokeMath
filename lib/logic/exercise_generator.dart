import 'dart:math';

/// Aufgabentypen für Klasse 1 (Zahlenraum bis 20).
enum ExerciseType {
  plusMinus('Plus und Minus', 'Rechne bis 20', '➕➖'),
  zehner('Zehnerübergang', 'Rechne bis 10 und dann weiter', '🔟'),
  nachbar('Nachbarzahlen', 'Welche Zahl kommt davor oder danach?', '🔢'),
  folge('Zahlenfolgen', 'Welche Zahl fehlt in der Reihe?', '➡️');

  final String title;
  final String subtitle;
  final String emoji;
  const ExerciseType(this.title, this.subtitle, this.emoji);
}

class Exercise {
  final String question;
  final int answer;
  final String? hint;

  Exercise({required this.question, required this.answer, this.hint});
}

final _rng = Random();

Exercise generateExercise(ExerciseType type) {
  switch (type) {
    case ExerciseType.plusMinus:
      return _plusMinus();
    case ExerciseType.zehner:
      return _zehner();
    case ExerciseType.nachbar:
      return _nachbar();
    case ExerciseType.folge:
      return _folge();
  }
}

/// Plus- oder Minusaufgabe im Zahlenraum bis 20.
Exercise _plusMinus() {
  if (_rng.nextBool()) {
    final a = _rng.nextInt(19) + 1; // 1..19
    final b = _rng.nextInt(20 - a) + 1; // Summe <= 20
    return Exercise(question: '$a + $b = ?', answer: a + b);
  } else {
    final a = _rng.nextInt(19) + 2; // 2..20
    final b = _rng.nextInt(a - 1) + 1; // Ergebnis >= 1
    return Exercise(question: '$a − $b = ?', answer: a - b);
  }
}

/// Addition mit Zehnerübergang: a + b mit a < 10 und a + b > 10.
Exercise _zehner() {
  final a = _rng.nextInt(4) + 6; // 6..9
  final toTen = 10 - a;
  final b = toTen + _rng.nextInt(9 - toTen) + 1; // kreuzt die 10, Summe <= 19
  final rest = b - toTen;
  return Exercise(
    question: '$a + $b = ?',
    answer: a + b,
    hint: 'Rechne bis 10 und dann weiter:\n$a + $toTen = 10 und 10 + $rest = ${10 + rest}',
  );
}

/// Vorgänger oder Nachfolger einer Zahl.
Exercise _nachbar() {
  if (_rng.nextBool()) {
    final n = _rng.nextInt(19) + 1; // 1..19
    return Exercise(
        question: 'Welche Zahl kommt direkt nach $n?', answer: n + 1);
  } else {
    final n = _rng.nextInt(19) + 2; // 2..20
    return Exercise(
        question: 'Welche Zahl kommt direkt vor $n?', answer: n - 1);
  }
}

/// Zahlenfolge mit Schrittweite 1 oder 2, eine Zahl fehlt.
Exercise _folge() {
  final step = _rng.nextBool() ? 1 : 2;
  final start = _rng.nextInt(20 - 4 * step) + 1;
  final numbers = List.generate(5, (i) => start + i * step);
  final missing = _rng.nextInt(5);
  final shown = [
    for (var i = 0; i < 5; i++) i == missing ? '★' : '${numbers[i]}'
  ].join('  ');
  return Exercise(
    question: 'Welche Zahl gehört auf den Stern?\n$shown',
    answer: numbers[missing],
  );
}
