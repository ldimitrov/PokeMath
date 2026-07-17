# PokeMath

Mathe-Lernspiel (auf Deutsch) für die Klassen 1–4: Aufgaben lösen, Punkte
sammeln, Pokébälle verdienen und Pokémon fangen und entwickeln.
Privates Hobby-Projekt, nur für den Eigengebrauch — keine Distribution.

## Setup

Die Pokémon-Bilder sind **nicht** im Repo enthalten (Copyright — das Repo ist
öffentlich). Vor dem ersten Build einmal lokal herunterladen:

```sh
./tool/fetch_sprites.sh
```

Dann wie gewohnt:

```sh
flutter pub get
flutter build apk --release   # Android-APK für das eigene Handy
```

Unterstützte Plattformen: Android (primär), iOS, macOS.

## Spielprinzip

- Profile pro Kind, Fortschritt wird lokal in SQLite gespeichert (sqflite).
- Klasse 1 (Zahlenraum bis 20): Plus/Minus, Zehnerübergang („Rechne bis 10
  und dann weiter"), Nachbarzahlen, Zahlenfolgen. Klassen 2–4 folgen.
- Richtige Antwort: 10 Punkte (5 beim zweiten Versuch). Alle 100 Punkte gibt
  es einen Pokéball, aus dem ein zufälliges Pokémon kommt.
- Das aktive Begleiter-Pokémon sammelt Energie und kann sich entwickeln
  (z.B. Glumanda → Glutexo → Glurak). Mewtu ist die ultra-seltene Belohnung.
