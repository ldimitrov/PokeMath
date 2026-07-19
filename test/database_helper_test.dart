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

  test('Fangen markiert die Art dauerhaft als entdeckt', () async {
    final p = await db.createProfile('Dex1', 1);
    await db.addPokemon(p.id, 4); // Glumanda
    expect(await db.getDiscovered(p.id), {4});

    // Doppelt fangen ändert nichts (kein Fehler, kein Duplikat).
    await db.addPokemon(p.id, 4);
    expect(await db.getDiscovered(p.id), {4});
  });

  test('Entdeckungen bleiben nach Entwicklung erhalten', () async {
    final p = await db.createProfile('Dex2', 1);
    final mon = await db.addPokemon(p.id, 4);
    // Entwicklung: Art wechselt, neue Art wird zusätzlich entdeckt.
    mon.speciesId = 5;
    await db.updatePokemon(mon);
    await db.markDiscovered(p.id, 5);

    expect(await db.getDiscovered(p.id), {4, 5});
  });

  test('Profil löschen entfernt auch die Entdeckungen', () async {
    final p = await db.createProfile('Dex3', 1);
    await db.addPokemon(p.id, 25);
    await db.deleteProfile(p.id);
    expect(await db.getDiscovered(p.id), isEmpty);
  });

  test('Teams verschiedener Profile bleiben getrennt', () async {
    final a = await db.createProfile('Duo1', 1);
    final b = await db.createProfile('Duo2', 1);
    await db.addPokemon(a.id, 1);
    await db.addPokemon(b.id, 133);

    expect((await db.getTeam(a.id)).single.speciesId, 1);
    expect((await db.getTeam(b.id)).single.speciesId, 133);
  });

  test('Migration v1 → v2 übernimmt vorhandene Pokémon als entdeckt',
      () async {
    // Alte v1-Datenbank (ohne discovered-Tabelle) von Hand anlegen.
    await db.close();
    DatabaseHelper.dbName = 'pokemath_migration_test.db';
    final dir = await databaseFactory.getDatabasesPath();
    final path = join(dir, DatabaseHelper.dbName);
    await databaseFactory.deleteDatabase(path);
    final v1 = await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (d, _) async {
            await d.execute('''
              CREATE TABLE profiles (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL, grade INTEGER NOT NULL,
                points INTEGER NOT NULL DEFAULT 0,
                ball_progress INTEGER NOT NULL DEFAULT 0,
                pokeballs INTEGER NOT NULL DEFAULT 0,
                active_pokemon_id INTEGER
              )
            ''');
            await d.execute('''
              CREATE TABLE owned_pokemon (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                profile_id INTEGER NOT NULL,
                species_id INTEGER NOT NULL,
                energy INTEGER NOT NULL DEFAULT 0,
                caught_at TEXT NOT NULL
              )
            ''');
          },
        ));
    final profileId = await v1.insert('profiles', {'name': 'Alt', 'grade': 1});
    for (final species in [4, 4, 25]) {
      await v1.insert('owned_pokemon', {
        'profile_id': profileId,
        'species_id': species,
        'energy': 0,
        'caught_at': DateTime.now().toIso8601String(),
      });
    }
    await v1.close();

    // Öffnen über den Helper löst das Upgrade auf v2 aus.
    expect(await db.getDiscovered(profileId), {4, 25});
    expect((await db.getTeam(profileId)).length, 3);
  });
}
