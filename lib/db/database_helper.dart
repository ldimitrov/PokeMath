import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/models.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  /// Nur für Tests überschreibbar, damit sie nicht die echte DB anfassen.
  static String dbName = 'pokemath.db';

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      join(dir, dbName),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            grade INTEGER NOT NULL,
            points INTEGER NOT NULL DEFAULT 0,
            ball_progress INTEGER NOT NULL DEFAULT 0,
            pokeballs INTEGER NOT NULL DEFAULT 0,
            active_pokemon_id INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE owned_pokemon (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
            species_id INTEGER NOT NULL,
            energy INTEGER NOT NULL DEFAULT 0,
            caught_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // --- Profile ---

  Future<List<Profile>> getProfiles() async {
    final rows = await (await db).query('profiles', orderBy: 'name');
    return rows.map(Profile.fromMap).toList();
  }

  Future<Profile> createProfile(String name, int grade) async {
    final id = await (await db)
        .insert('profiles', {'name': name, 'grade': grade});
    return Profile(id: id, name: name, grade: grade);
  }

  Future<void> updateProfile(Profile p) async {
    await (await db)
        .update('profiles', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> deleteProfile(int id) async {
    final d = await db;
    await d.delete('owned_pokemon', where: 'profile_id = ?', whereArgs: [id]);
    await d.delete('profiles', where: 'id = ?', whereArgs: [id]);
  }

  // --- Pokémon ---

  Future<List<OwnedPokemon>> getTeam(int profileId) async {
    final rows = await (await db).query('owned_pokemon',
        where: 'profile_id = ?', whereArgs: [profileId], orderBy: 'caught_at');
    return rows.map(OwnedPokemon.fromMap).toList();
  }

  Future<OwnedPokemon> addPokemon(int profileId, int speciesId) async {
    final id = await (await db).insert('owned_pokemon', {
      'profile_id': profileId,
      'species_id': speciesId,
      'energy': 0,
      'caught_at': DateTime.now().toIso8601String(),
    });
    return OwnedPokemon(id: id, profileId: profileId, speciesId: speciesId);
  }

  Future<void> updatePokemon(OwnedPokemon p) async {
    await (await db).update(
        'owned_pokemon', {'species_id': p.speciesId, 'energy': p.energy},
        where: 'id = ?', whereArgs: [p.id]);
  }
}
