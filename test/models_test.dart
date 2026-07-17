import 'package:flutter_test/flutter_test.dart';
import 'package:pokemath/models/models.dart';

void main() {
  group('Profile.addPoints', () {
    Profile fresh() => Profile(id: 1, name: 'Test', grade: 1);

    test('zählt Punkte und Fortschritt', () {
      final p = fresh()..addPoints(60);
      expect(p.points, 60);
      expect(p.ballProgress, 60);
      expect(p.pokeballs, 0);
    });

    test('bei 100 Fortschritt gibt es einen Pokéball', () {
      final p = fresh()
        ..addPoints(60)
        ..addPoints(60);
      expect(p.points, 120);
      expect(p.ballProgress, 20);
      expect(p.pokeballs, 1);
    });

    test('mehrere Bälle auf einmal sind möglich', () {
      final p = fresh()..addPoints(250);
      expect(p.pokeballs, 2);
      expect(p.ballProgress, 50);
    });

    test('genau 100 setzt den Fortschritt auf 0', () {
      final p = fresh()..addPoints(100);
      expect(p.pokeballs, 1);
      expect(p.ballProgress, 0);
    });
  });

  group('Profile Map-Roundtrip', () {
    test('toMap/fromMap erhalten alle Felder', () {
      final p = Profile(
          id: 7,
          name: 'Mia',
          grade: 1,
          points: 230,
          ballProgress: 30,
          pokeballs: 2,
          activePokemonId: 5);
      final copy = Profile.fromMap(p.toMap());
      expect(copy.id, 7);
      expect(copy.name, 'Mia');
      expect(copy.grade, 1);
      expect(copy.points, 230);
      expect(copy.ballProgress, 30);
      expect(copy.pokeballs, 2);
      expect(copy.activePokemonId, 5);
    });
  });
}
