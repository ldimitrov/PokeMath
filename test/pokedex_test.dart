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

    test('jedes Pokémon hat eine Beschreibung', () {
      for (final s in pokedex) {
        expect(s.description.trim(), isNotEmpty, reason: s.name);
      }
    });

    test('jedes Pokémon hat mindestens einen Typ', () {
      for (final s in pokedex) {
        expect(s.types, isNotEmpty, reason: s.name);
      }
      // Stichproben.
      expect(speciesById(6).types, [PokeType.feuer, PokeType.flug]);
      expect(speciesById(25).types, [PokeType.elektro]);
      expect(speciesById(150).types, [PokeType.psycho]);
    });

    test('Entwicklungen behalten den Grundtyp der Familie', () {
      // Erste Stufe und Entwicklung teilen mindestens einen Typ —
      // Ausnahme Evoli, dessen Entwicklungen den Typ wechseln.
      for (final s in pokedex) {
        if (s.id == 133) continue;
        for (final target in s.evolvesTo) {
          expect(
              speciesById(target)
                  .types
                  .toSet()
                  .intersection(s.types.toSet()),
              isNotEmpty,
              reason: '${s.name} → ${speciesById(target).name}');
        }
      }
    });

    test('evolutionChain findet die ganze Familie von jeder Stufe aus', () {
      // Von der Mitte der Glumanda-Familie aus.
      final glumanda = evolutionChain(5);
      expect(glumanda.map((l) => l.map((s) => s.id).toList()).toList(), [
        [4],
        [5],
        [6],
      ]);
      // Auch von der letzten Stufe aus dieselbe Kette.
      expect(evolutionChain(6).first.single.id, 4);
      // Evoli verzweigt sich in drei Entwicklungen.
      final evoli = evolutionChain(134);
      expect(evoli.first.single.id, 133);
      expect(evoli.last.map((s) => s.id), containsAll([134, 135, 136]));
      // Mew hat keine Entwicklung.
      expect(evolutionChain(151), [
        [speciesById(151)]
      ]);
      // Relaxo hat eine Vorstufe: Mampfaxo.
      expect(evolutionChain(143).map((l) => l.single.id), [446, 143]);
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
