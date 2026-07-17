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

## Neue Pokémon hinzufügen

Die Pokémon-Daten (Name, Typen, Beschreibung, Entwicklungen, Fang-Gewicht)
liegen statisch in `lib/data/pokedex.dart` — die App braucht zur Laufzeit
keine Internetverbindung. Neue Einträge generiert man mit dem Dev-Skript,
das Name, Typen und einen Beschreibungs-Vorschlag (Deutsch) von
[PokeAPI](https://pokeapi.co) holt:

```sh
dart run tool/fetch_pokemon_data.dart 54 104 151   # Nationaldex-Nummern
```

Der Ablauf:

1. Skript ausführen und die ausgegebenen `Species(...)`-Einträge in die
   `pokedex`-Liste in `lib/data/pokedex.dart` einfügen.
2. Beschreibung kindgerecht umformulieren (der PokeAPI-Text ist nur ein
   Vorschlag), `catchWeight` festlegen (0 = nur per Entwicklung erhältlich)
   und ggf. `evolvesTo`/`evolvesAtEnergy` setzen.
3. Die neuen IDs in `tool/fetch_sprites.sh` ergänzen und das Skript
   ausführen, damit die Bilder lokal landen.
4. `flutter test` — die Pokédex-Tests prüfen automatisch, dass jeder neue
   Eintrag Typen, Beschreibung, gültige Entwicklungsziele und ein Bild hat.

Alle 18 Typen (`PokeType`) sind bereits mit deutschen Namen und Farben
angelegt; Entwicklungen sollen mindestens einen Typ mit ihrer Vorstufe
teilen (Ausnahme: Evoli).

## Spielprinzip

- Profile pro Kind, Fortschritt wird lokal in SQLite gespeichert (sqflite).
- Klasse 1 (Zahlenraum bis 20): Plus/Minus, Zehnerübergang („Rechne bis 10
  und dann weiter"), Nachbarzahlen, Zahlenfolgen. Klassen 2–4 folgen.
- Richtige Antwort: 10 Punkte (5 beim zweiten Versuch). Alle 100 Punkte gibt
  es einen Pokéball, aus dem ein zufälliges Pokémon kommt.
- Das aktive Begleiter-Pokémon sammelt Energie und kann sich entwickeln
  (z.B. Glumanda → Glutexo → Glurak). Mewtu ist die ultra-seltene Belohnung.
