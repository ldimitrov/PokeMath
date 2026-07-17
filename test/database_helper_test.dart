import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:pokemath/db/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    DatabaseHelper.dbName = 'pokemath_test.db';
    final dir = await databaseFactory.getDatabasesPath();
    await databaseFactory.deleteDatabase(join(dir, DatabaseHelper.dbName));
  });

  final db = DatabaseHelper.instance;

  test('Profil anlegen und wiederfinden', () async {
    final p = await db.createProfile('Anna', 1);
    expect(p.id, greaterThan(0));

    final profiles = await db.getProfiles();
    expect(profiles.map((x) => x.name), contains('Anna'));
    final anna = profiles.firstWhere((x) => x.name == 'Anna');
    expect(anna.grade, 1);
    expect(anna.points, 0);
    expect(anna.pokeballs, 0);
  });

  test('Profil-Änderungen werden gespeichert', () async {
    final p = await db.createProfile('Ben', 1);
    p
      ..addPoints(150)
      ..activePokemonId = null;
    await db.updateProfile(p);

    final reloaded =
        (await db.getProfiles()).firstWhere((x) => x.id == p.id);
    expect(reloaded.points, 150);
    expect(reloaded.ballProgress, 50);
    expect(reloaded.pokeballs, 1);
  });

  test('Pokémon fangen, Energie speichern', () async {
    final p = await db.createProfile('Carla', 1);
    final mon = await db.addPokemon(p.id, 4); // Glumanda
    expect(mon.speciesId, 4);
    expect(mon.energy, 0);

    mon
      ..energy = 80
      ..speciesId = 5; // entwickelt zu Glutexo
    await db.updatePokemon(mon);

    final team = await db.getTeam(p.id);
    expect(team.length, 1);
    expect(team.single.speciesId, 5);
    expect(team.single.energy, 80);
  });

  test('Profil löschen entfernt auch seine Pokémon', () async {
    final p = await db.createProfile('Timo', 1);
    await db.addPokemon(p.id, 25);
    await db.addPokemon(p.id, 7);
    expect((await db.getTeam(p.id)).length, 2);

    await db.deleteProfile(p.id);
    expect((await db.getProfiles()).any((x) => x.id == p.id), isFalse);
    expect(await db.getTeam(p.id), isEmpty);
  });

  test('Teams verschiedener Profile bleiben getrennt', () async {
    final a = await db.createProfile('Duo1', 1);
    final b = await db.createProfile('Duo2', 1);
    await db.addPokemon(a.id, 1);
    await db.addPokemon(b.id, 133);

    expect((await db.getTeam(a.id)).single.speciesId, 1);
    expect((await db.getTeam(b.id)).single.speciesId, 133);
  });
}
