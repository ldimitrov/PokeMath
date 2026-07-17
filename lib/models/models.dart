class Profile {
  final int id;
  String name;
  int grade; // Klasse 1-4
  int points; // Gesamtpunkte (nur Anzeige)
  int ballProgress; // 0-99, bei 100 gibt es einen Pokéball
  int pokeballs; // ungeöffnete Pokébälle
  int? activePokemonId; // OwnedPokemon.id des Begleiters

  Profile({
    required this.id,
    required this.name,
    required this.grade,
    this.points = 0,
    this.ballProgress = 0,
    this.pokeballs = 0,
    this.activePokemonId,
  });

  /// Verbucht Rundenpunkte; je 100 Fortschrittspunkte werden ein Pokéball.
  void addPoints(int pts) {
    points += pts;
    ballProgress += pts;
    while (ballProgress >= 100) {
      ballProgress -= 100;
      pokeballs++;
    }
  }

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as int,
        name: m['name'] as String,
        grade: m['grade'] as int,
        points: m['points'] as int,
        ballProgress: m['ball_progress'] as int,
        pokeballs: m['pokeballs'] as int,
        activePokemonId: m['active_pokemon_id'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'grade': grade,
        'points': points,
        'ball_progress': ballProgress,
        'pokeballs': pokeballs,
        'active_pokemon_id': activePokemonId,
      };
}

class OwnedPokemon {
  final int id;
  final int profileId;
  int speciesId;
  int energy;

  OwnedPokemon({
    required this.id,
    required this.profileId,
    required this.speciesId,
    this.energy = 0,
  });

  factory OwnedPokemon.fromMap(Map<String, dynamic> m) => OwnedPokemon(
        id: m['id'] as int,
        profileId: m['profile_id'] as int,
        speciesId: m['species_id'] as int,
        energy: m['energy'] as int,
      );
}
