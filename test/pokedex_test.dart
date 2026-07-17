import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemath/data/pokedex.dart';

void main() {
  group('Pokédex-Daten', () {
    test('IDs sind eindeutig', () {
      final ids = pokedex.map((s) => s.id).toSet();
      expect(ids.length, pokedex.length);
    });

    test('Entwicklungsziele existieren und entwickeln nicht zu sich selbst',
        () {
      for (final s in pokedex) {
        for (final target in s.evolvesTo) {
          expect(pokedex.any((p) => p.id == target), isTrue,
              reason: '${s.name} entwickelt zu unbekannter ID $target');
          expect(target, isNot(s.id));
        }
      }
    });

    test('evolvesAtEnergy ist genau dann gesetzt, wenn es eine Entwicklung gibt',
        () {
      for (final s in pokedex) {
        expect(s.evolvesAtEnergy != null, s.evolvesTo.isNotEmpty,
            reason: s.name);
        if (s.evolvesAtEnergy != null) {
          expect(s.evolvesAtEnergy, greaterThan(0));
        }
      }
    });

    test('es gibt fangbare Pokémon und Mewtu ist das seltenste', () {
      expect(catchableSpecies, isNotEmpty);
      final mewtu = speciesById(150);
      for (final s in catchableSpecies) {
        expect(s.catchWeight, greaterThanOrEqualTo(mewtu.catchWeight));
      }
    });

    test('randomCatch liefert nur fangbare Pokémon, alle kommen vor', () {
      final rng = Random(42);
      final drawn = <int, int>{};
      for (var i = 0; i < 10000; i++) {
        final s = randomCatch(rng);
        expect(s.catchWeight, greaterThan(0));
        drawn[s.id] = (drawn[s.id] ?? 0) + 1;
      }
      for (final s in catchableSpecies) {
        expect(drawn.containsKey(s.id), isTrue,
            reason: '${s.name} wurde in 10000 Ziehungen nie gezogen');
      }
      // Mewtu (Gewicht 1 von 110) bleibt selten.
      expect(drawn[150]!, lessThan(300));
    });

    test('für jedes Pokémon liegt ein Bild in assets/pokemon', () {
      for (final s in pokedex) {
        expect(File('assets/pokemon/${s.id}.png').existsSync(), isTrue,
            reason:
                'assets/pokemon/${s.id}.png fehlt — tool/fetch_sprites.sh ausführen');
      }
    });
  });
}
