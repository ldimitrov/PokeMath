import 'dart:math';

/// Aufgabentypen. Vorschule rechnet im Zahlenraum bis 10, Klasse 1 bis 20.
enum ExerciseType {
  plusMinus('Plus und Minus', 'Rechne bis 20', '➕➖'),
  partner('Partnerzahlen', 'Wie viel fehlt bis zur 10?', '🔵'),
  vergleich('Anzahlen vergleichen', 'Kleiner, gleich oder größer?', '🐊'),
  zehner('Zehnerübergang', 'Rechne bis 10 und dann weiter', '🔟'),
  fehlend('Fehlende Zahlen', 'Welche Zahl fehlt?', '🔍'),
  zerlegen('Zahlen zerlegen', 'Fülle das Zahlenhaus!', '🏠'),
  mauer('Zahlenmauern', 'Baue die Zahlenmauer!', '🧱'),
  kette('Kettenaufgaben', 'Rechne die ganze Kette', '🔗'),
  korrektFalsch('Korrekt oder falsch?', 'Stimmt die Rechnung?', '⚖️'),
  nachbar('Nachbarzahlen', 'Finde die Nachbarn!', '🏘️'),
  folge('Zahlenfolgen', 'Welche Zahl fehlt in der Reihe?', '➡️');

  final String title;
  final String subtitle;
  final String emoji;
  const ExerciseType(this.title, this.subtitle, this.emoji);

  /// Untertitel passend zur Klassenstufe.
  String subtitleFor(int grade) =>
      this == ExerciseType.plusMinus && grade == 0 ? 'Rechne bis 10' : subtitle;
}

/// Welche Aufgabentypen es für eine Klassenstufe gibt (0 = Vorschule).
List<ExerciseType> typesForGrade(int grade) => grade == 0
    ? const [
        ExerciseType.plusMinus,
        ExerciseType.partner,
        ExerciseType.vergleich,
        ExerciseType.fehlend,
        ExerciseType.korrektFalsch,
        ExerciseType.folge,
      ]
    : [
        for (final t in ExerciseType.values)
          if (t != ExerciseType.partner && t != ExerciseType.vergleich) t
      ];

/// Ein Baustein einer Aufgabenzeile: entweder fester Text (Zahl, Operator)
/// oder ein Eingabefeld (Index in [Exercise.answers]).
class Token {
  final String? text;
  final int? blank;
  const Token.text(this.text) : blank = null;
  const Token.blank(this.blank) : text = null;
  bool get isBlank => blank != null;
}

Token t(String s) => Token.text(s);
Token b(int i) => Token.blank(i);

class Exercise {
  /// Optionale Frage über den Rechenzeilen.
  final String? prompt;

  /// Rechenzeilen aus Text-Tokens und Eingabefeldern.
  final List<List<Token>> lines;

  /// Erwartete Werte der Eingabefelder, indexiert über [Token.blank].
  final List<int> answers;

  /// Nur für Korrekt/Falsch-Aufgaben: stimmt die gezeigte Rechnung?
  final bool? isTrue;

  /// Erklärung bei falscher Antwort (z.B. die richtige Rechnung).
  final String? solution;

  /// Partnerzahlen: so viele von 10 Punkten sind ausgemalt.
  final int? dots;

  /// Zahlenhaus: die Dachzahl — jede Zeile (Etage) ergibt diese Summe.
  final int? houseSum;

  /// Zahlenmauer: [lines] sind die Reihen von der Spitze zur Basis, jeder
  /// Stein ist die Summe der beiden Steine direkt darunter.
  final bool pyramid;

  /// Auswahl-Modus: diese Optionen erscheinen als Buttons statt des
  /// Ziffernblocks; [answers] enthält dann den Index der richtigen Option.
  final List<String>? choices;

  Exercise(
      {this.prompt,
      required this.lines,
      this.answers = const [],
      this.isTrue,
      this.solution,
      this.dots,
      this.houseSum,
      this.pyramid = false,
      this.choices});

  bool get isTrueFalse => isTrue != null;

  bool get isChoice => choices != null;
}

final _rng = Random();

/// [progress] ist der Fortschritt in der Runde (0.0 bis 1.0). Der
/// Zehnerübergang beginnt mit Plus und wechselt am Ende zu Minus.
/// [grade] 0 = Vorschule (Zahlenraum bis 10), sonst Klasse 1 (bis 20).
Exercise generateExercise(ExerciseType type,
    {double progress = 0, int grade = 1}) {
  final maxN = grade == 0 ? 10 : 20;
  switch (type) {
    case ExerciseType.plusMinus:
      return _plusMinus(maxN);
    case ExerciseType.partner:
      return _partner();
    case ExerciseType.vergleich:
      return _vergleich();
    case ExerciseType.zehner:
      return _zehner(plus: progress < 0.7);
    case ExerciseType.fehlend:
      return _fehlend(maxN);
    case ExerciseType.zerlegen:
      return _zerlegen();
    case ExerciseType.mauer:
      return _mauer(progress: progress);
    case ExerciseType.kette:
      return _kette(progress: progress);
    case ExerciseType.korrektFalsch:
      return _korrektFalsch(maxN);
    case ExerciseType.nachbar:
      return _nachbar();
    case ExerciseType.folge:
      return _folge(maxN);
  }
}

/// Zufällige Plus- oder Minus-Zahlen im Zahlenraum bis [maxN] (Ergebnis >= 1).
(int a, int b, int result, String op) _randomPlusMinus(int maxN) {
  if (_rng.nextBool()) {
    final a = _rng.nextInt(maxN - 1) + 1; // 1..maxN-1
    final bb = _rng.nextInt(maxN - a) + 1; // Summe <= maxN
    return (a, bb, a + bb, '+');
  } else {
    final a = _rng.nextInt(maxN - 1) + 2; // 2..maxN
    final bb = _rng.nextInt(a - 1) + 1; // Ergebnis >= 1
    return (a, bb, a - bb, '−');
  }
}

/// Partnerzahlen: n ausgemalte Punkte, wie viele fehlen bis zur 10?
/// Bewusst ohne Rechenzeile — die Kinder sollen die Punkte zählen.
Exercise _partner() {
  final n = _rng.nextInt(9) + 1; // 1..9
  return Exercise(
    prompt: 'Wie viel fehlt bis zur 10?',
    dots: n,
    lines: [
      [b(0)]
    ],
    answers: [10 - n],
  );
}

/// Anzahlen vergleichen: 7 [_] 5 — kleiner, gleich oder größer?
Exercise _vergleich() {
  final a = _rng.nextInt(10) + 1;
  // Etwa jedes dritte Mal sind beide Zahlen gleich.
  final bb = _rng.nextInt(3) == 0 ? a : _rng.nextInt(10) + 1;
  const symbols = ['<', '=', '>'];
  final correct = a < bb ? '<' : (a > bb ? '>' : '=');
  return Exercise(
    prompt: 'Vergleiche die Zahlen!',
    lines: [
      [t('$a'), b(0), t('$bb')]
    ],
    choices: symbols,
    answers: [symbols.indexOf(correct)],
  );
}

Exercise _plusMinus(int maxN) {
  final (a, bb, result, op) = _randomPlusMinus(maxN);
  return Exercise(
    lines: [
      [t('$a'), t(op), t('$bb'), t('='), b(0)]
    ],
    answers: [result],
  );
}

/// Zehnerübergang mit Zerlegung zum Ausfüllen, Plus und Minus:
///   7 + 9 = [16]          13 − 7 = [6]
///   7 + [3] + [6] = [16]  13 − [3] − [4] = [6]
Exercise _zehner({required bool plus}) {
  if (plus) {
    final a = _rng.nextInt(4) + 6; // 6..9
    final toTen = 10 - a;
    final bb = toTen + _rng.nextInt(9 - toTen) + 1; // kreuzt die 10, Summe <= 19
    final rest = bb - toTen;
    return Exercise(
      lines: [
        [t('$a'), t('+'), t('$bb'), t('='), b(0)],
        [t('$a'), t('+'), b(1), t('+'), b(2), t('='), b(3)],
      ],
      answers: [a + bb, toTen, rest, a + bb],
    );
  } else {
    final a = _rng.nextInt(8) + 11; // 11..18
    final toTen = a - 10; // erst bis zur 10 abziehen
    final bb = toTen + _rng.nextInt(9 - toTen) + 1; // kreuzt die 10 nach unten
    final rest = bb - toTen;
    return Exercise(
      lines: [
        [t('$a'), t('−'), t('$bb'), t('='), b(0)],
        [t('$a'), t('−'), b(1), t('−'), b(2), t('='), b(3)],
      ],
      answers: [a - bb, toTen, rest, a - bb],
    );
  }
}

/// Fehlende Zahl in der Gleichung: 4 + [_] = 12, [_] + 5 = 11, 13 − [_] = 9 ...
Exercise _fehlend(int maxN) {
  final (a, bb, result, op) = _randomPlusMinus(maxN);
  final missingFirst = _rng.nextBool();
  return Exercise(
    lines: [
      [
        missingFirst ? b(0) : t('$a'),
        t(op),
        missingFirst ? t('$bb') : b(0),
        t('='),
        t('$result'),
      ]
    ],
    answers: [missingFirst ? a : bb],
  );
}

/// Zahlen zerlegen (Zahlenhaus): jede Etage ergibt zusammen die Dachzahl.
/// 1-3 Etagen mit je 2-3 Fenstern, pro Etage fehlt genau eine Zahl.
Exercise _zerlegen() {
  final sum = _rng.nextInt(6) + 5; // Dachzahl 5..10
  final floors = _rng.nextInt(3) + 1;
  final cells = _rng.nextInt(2) + 2; // Fenster pro Etage
  final lines = <List<Token>>[];
  final answers = <int>[];
  for (var f = 0; f < floors; f++) {
    // Zerlegung der Dachzahl in `cells` Teile, jeder mindestens 1.
    final parts = <int>[];
    var rest = sum;
    for (var c = 0; c < cells; c++) {
      final remaining = cells - c - 1;
      final v = remaining == 0 ? rest : _rng.nextInt(rest - remaining) + 1;
      parts.add(v);
      rest -= v;
    }
    final blankIdx = _rng.nextInt(cells);
    lines.add([
      for (var c = 0; c < cells; c++)
        if (c == blankIdx) b(answers.length) else t('${parts[c]}'),
    ]);
    answers.add(parts[blankIdx]);
  }
  return Exercise(
    prompt: 'Jedes Stockwerk ergibt zusammen die Zahl im Dach!',
    houseSum: sum,
    lines: lines,
    answers: answers,
  );
}

/// Baut eine Zahlenmauer von der Basis aus: jede Reihe darüber enthält die
/// Summen benachbarter Steine. Rückgabe: index 0 = Basis, letzter = Spitze.
List<List<int>> _pyramidRows(List<int> base) {
  final rows = [base];
  var current = base;
  while (current.length > 1) {
    final next = [
      for (var i = 0; i < current.length - 1; i++) current[i] + current[i + 1]
    ];
    rows.add(next);
    current = next;
  }
  return rows;
}

/// Zufällige Basissteine, klein genug, dass die Spitze nie über 20 kommt.
List<int> _randomBase(int size) => size == 3
    ? [for (var i = 0; i < 3; i++) _rng.nextInt(5) + 1]
    : [
        _rng.nextInt(3) + 1,
        _rng.nextInt(2) + 1,
        _rng.nextInt(2) + 1,
        _rng.nextInt(3) + 1,
      ];

/// Zahlenmauer rückwärts: alle Reihen zwischen Basis und Spitze sind
/// vollständig gegeben, aber die Spitze selbst fehlt — und genau ein
/// Basisstein fehlt ebenfalls. Jede Lücke ist über eine einzige Addition
/// bzw. Subtraktion mit der Reihe direkt darüber/darunter lösbar,
/// unabhängig davon, welcher Basisstein fehlt. Funktioniert für 3er- und
/// 4er-Basen gleichermaßen.
Exercise _mauerBackward() {
  final baseSize = _rng.nextBool() ? 3 : 4;
  final base = _randomBase(baseSize);
  final rows = _pyramidRows(base); // rows[0] = Basis ... rows.last = Spitze
  final hideBaseIdx = _rng.nextInt(baseSize);
  final answers = <int>[];
  Token cell(int value, bool blank) {
    if (!blank) return t('$value');
    answers.add(value);
    return b(answers.length - 1);
  }

  final lines = <List<Token>>[];
  for (var r = rows.length - 1; r >= 0; r--) {
    final isApex = r == rows.length - 1;
    final isBase = r == 0;
    lines.add([
      for (var i = 0; i < rows[r].length; i++)
        cell(rows[r][i], isApex || (isBase && i == hideBaseIdx)),
    ]);
  }
  return Exercise(
    prompt: 'Jeder Stein ist die Summe der zwei Steine darunter!',
    pyramid: true,
    lines: lines,
    answers: answers,
  );
}

/// Zahlenmauer: jeder Stein ist die Summe der zwei Steine direkt darunter.
/// Wird die Runde schwerer: erst 3er-Basis, dann 4er-Basis (nur addieren),
/// zum Schluss rückwärts: Spitze und ein Basisstein fehlen (3er oder 4er).
Exercise _mauer({required double progress}) {
  if (progress >= 0.8) {
    return _mauerBackward();
  }

  final baseSize = progress < 0.5 ? 3 : 4;
  final base = _randomBase(baseSize);
  final rows = _pyramidRows(base); // rows[0] = Basis ... rows.last = Spitze
  final lines = <List<Token>>[];
  final answers = <int>[];
  for (var r = rows.length - 1; r >= 0; r--) {
    final isBase = r == 0;
    final rowTokens = <Token>[];
    for (final v in rows[r]) {
      if (isBase) {
        rowTokens.add(t('$v'));
      } else {
        rowTokens.add(b(answers.length));
        answers.add(v);
      }
    }
    lines.add(rowTokens);
  }
  return Exercise(
    prompt: 'Jeder Stein ist die Summe der zwei Steine darunter!',
    pyramid: true,
    lines: lines,
    answers: answers,
  );
}

/// Kettenaufgabe mit steigender Schwierigkeit über die Runde:
/// erst 3 Zahlen, dann 4, dann 5 — und am Ende gemischt mit Plus und Minus
/// (z.B. 8 + 5 − 3 + 2 − 4 = [_]).
Exercise _kette({required double progress}) {
  final count = progress < 0.3
      ? 3
      : progress < 0.6
          ? 4
          : 5;
  final mixed = progress >= 0.8;

  if (!mixed) {
    final numbers = <int>[];
    var sum = 0;
    for (var i = 0; i < count; i++) {
      final maxNext = min(6, 20 - sum - (count - i - 1));
      final n = _rng.nextInt(maxNext) + 1;
      numbers.add(n);
      sum += n;
    }
    return Exercise(
      lines: [
        [
          for (var i = 0; i < numbers.length; i++) ...[
            if (i > 0) t('+'),
            t('${numbers[i]}'),
          ],
          t('='),
          b(0),
        ]
      ],
      answers: [sum],
    );
  }

  // Gemischte Kette: Zwischenergebnisse bleiben in 0..20,
  // Plus und Minus kommen beide mindestens einmal vor.
  while (true) {
    final tokens = <Token>[];
    var value = _rng.nextInt(10) + 1;
    tokens.add(t('$value'));
    var hasPlus = false, hasMinus = false;
    for (var i = 1; i < count; i++) {
      final canPlus = value <= 19;
      final canMinus = value >= 1;
      final plus = canPlus && canMinus ? _rng.nextBool() : canPlus;
      final n = plus
          ? _rng.nextInt(min(6, 20 - value)) + 1
          : _rng.nextInt(min(6, value)) + 1;
      plus ? hasPlus = true : hasMinus = true;
      value += plus ? n : -n;
      tokens
        ..add(t(plus ? '+' : '−'))
        ..add(t('$n'));
    }
    if (!hasPlus || !hasMinus) continue;
    tokens
      ..add(t('='))
      ..add(b(0));
    return Exercise(lines: [tokens], answers: [value]);
  }
}

/// Korrekt oder falsch: "5 + 10 = 14"?
Exercise _korrektFalsch(int maxN) {
  final (a, bb, result, op) = _randomPlusMinus(maxN);
  final isTrue = _rng.nextBool();
  var shown = result;
  if (!isTrue) {
    while (shown == result) {
      shown = max(0, min(maxN, result + _rng.nextInt(7) - 3));
    }
  }
  return Exercise(
    prompt: 'Ist diese Rechnung korrekt?',
    lines: [
      [t('$a'), t(op), t('$bb'), t('='), t('$shown')]
    ],
    isTrue: isTrue,
    solution: 'Richtig ist: $a $op $bb = $result',
  );
}

/// Zwei Formate:
///  - Nachbarzahlen-Häuser: drei aufeinanderfolgende Zahlen, eine vorgegeben,
///    die beiden anderen werden eingetragen (z.B. [8] 9 [10]).
///  - Nachbaraufgaben: drei verwandte Plusaufgaben, bei denen sich eine Zahl
///    jeweils um 1 unterscheidet (z.B. 4+2, 4+3, 4+4).
Exercise _nachbar() {
  if (_rng.nextBool()) {
    final middle = _rng.nextInt(19) + 1; // Tripel bleibt in 0..20
    final given = _rng.nextInt(3);
    final values = [middle - 1, middle, middle + 1];
    final tokens = <Token>[];
    final answers = <int>[];
    for (var i = 0; i < 3; i++) {
      if (i == given) {
        tokens.add(t('${values[i]}'));
      } else {
        tokens.add(b(answers.length));
        answers.add(values[i]);
      }
    }
    return Exercise(
      prompt: 'Wie heißen die Nachbarzahlen? 🏠🏠🏠',
      lines: [tokens],
      answers: answers,
    );
  } else {
    final varyFirst = _rng.nextBool();
    final fixed = _rng.nextInt(9) + 1; // 1..9
    final base = _rng.nextInt(min(9, 19 - fixed) - 1) + 2; // 2.., Summe+1 <= 20
    // Was wird ausgefüllt? 0: die Ergebnisse, 1: die wechselnde Zahl,
    // 2: die wechselnde Zahl und in der Mitte zusätzlich das Ergebnis.
    final mode = _rng.nextInt(3);
    final lines = <List<Token>>[];
    final answers = <int>[];

    Token cell(int value, bool blank) {
      if (!blank) return t('$value');
      answers.add(value);
      return b(answers.length - 1);
    }

    for (var i = -1; i <= 1; i++) {
      final vary = base + i;
      final a = varyFirst ? vary : fixed;
      final bb = varyFirst ? fixed : vary;
      final blankVary = mode >= 1;
      final blankResult = mode == 0 || (mode == 2 && i == 0);
      lines.add([
        cell(a, blankVary && varyFirst),
        t('+'),
        cell(bb, blankVary && !varyFirst),
        t('='),
        cell(a + bb, blankResult),
      ]);
    }
    return Exercise(
      prompt: 'Rechne die Nachbaraufgaben!',
      lines: lines,
      answers: answers,
    );
  }
}

/// Zahlenfolge mit Schrittweite 1 oder 2, eine Zahl fehlt.
Exercise _folge(int maxN) {
  final step = _rng.nextBool() ? 1 : 2;
  final start = _rng.nextInt(maxN - 4 * step) + 1;
  final numbers = List.generate(5, (i) => start + i * step);
  final missing = _rng.nextInt(5);
  return Exercise(
    prompt: 'Welche Zahl fehlt in der Reihe?',
    lines: [
      [
        for (var i = 0; i < 5; i++)
          i == missing ? b(0) : t('${numbers[i]}'),
      ]
    ],
    answers: [numbers[missing]],
  );
}
