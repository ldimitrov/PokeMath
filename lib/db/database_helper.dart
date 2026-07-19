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

  /// Nur für Tests: schließt die Verbindung, damit eine andere DB-Datei
  /// geöffnet werden kann.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  static const _discoveredTable = '''
    CREATE TABLE discovered (
      profile_id INTEGER NOT NULL,
      species_id INTEGER NOT NULL,
      discovered_at TEXT NOT NULL,
      PRIMARY KEY (profile_id, species_id)
    )
  ''';

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      join(dir, dbName),
      version: 2,
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
        await db.execute(_discoveredTable);
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await db.execute(_discoveredTable);
          // Bestehende Pokémon als entdeckt übernehmen.
          await db.execute('''
            INSERT OR IGNORE INTO discovered (profile_id, species_id, discovered_at)
            SELECT DISTINCT profile_id, species_id, caught_at FROM owned_pokemon
          ''');
        }
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
    await d.delete('discovered', where: 'profile_id = ?', whereArgs: [id]);
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
    await markDiscovered(profileId, speciesId);
    return OwnedPokemon(id: id, profileId: profileId, speciesId: speciesId);
  }

  // --- Pokédex (dauerhaft entdeckte Arten) ---

  Future<void> markDiscovered(int profileId, int speciesId) async {
    await (await db).insert(
      'discovered',
      {
        'profile_id': profileId,
        'species_id': speciesId,
        'discovered_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Set<int>> getDiscovered(int profileId) async {
    final rows = await (await db).query('discovered',
        columns: ['species_id'],
        where: 'profile_id = ?',
        whereArgs: [profileId]);
    return {for (final r in rows) r['species_id'] as int};
  }

  Future<void> updatePokemon(OwnedPokemon p) async {
    await (await db).update(
        'owned_pokemon', {'species_id': p.speciesId, 'energy': p.energy},
        where: 'id = ?', whereArgs: [p.id]);
  }
}
