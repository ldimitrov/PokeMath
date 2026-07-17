import 'dart:math';

/// Statische Pokédex-Daten. Die Bild-Dateien liegen unter `assets/pokemon/<id>.png`.
class Species {
  final int id; // Nationaldex-Nummer = Dateiname des Bildes
  final String name; // deutscher Name
  final String description; // kurze kindgerechte Beschreibung
  final int? evolvesAtEnergy; // Energie, ab der entwickelt werden kann
  final List<int> evolvesTo; // mehrere Einträge = zufällige Entwicklung (Evoli)
  final int catchWeight; // 0 = nicht fangbar (nur durch Entwicklung erhältlich)

  const Species(this.id, this.name, this.description,
      {this.evolvesAtEnergy, this.evolvesTo = const [], this.catchWeight = 0});

  bool get canEvolve => evolvesTo.isNotEmpty;
}

const List<Species> pokedex = [
  Species(1, 'Bisasam',
      'Ein Pflanzen-Pokémon mit einer Knospe auf dem Rücken, die mit ihm wächst.',
      evolvesAtEnergy: 100, evolvesTo: [2], catchWeight: 15),
  Species(2, 'Bisaknosp',
      'Seine Knospe ist zu einer großen Blüte geworden, die in der Sonne Kraft tankt.',
      evolvesAtEnergy: 200, evolvesTo: [3]),
  Species(3, 'Bisaflor',
      'Die riesige Blume auf seinem Rücken duftet wunderbar — die stärkste Stufe von Bisasam.'),
  Species(4, 'Glumanda',
      'Ein Feuer-Pokémon. Die Flamme an seinem Schwanz zeigt, wie es sich fühlt.',
      evolvesAtEnergy: 100, evolvesTo: [5], catchWeight: 15),
  Species(5, 'Glutexo',
      'Größer und wilder als Glumanda — seine Flamme brennt jetzt richtig heiß.',
      evolvesAtEnergy: 200, evolvesTo: [6]),
  Species(6, 'Glurak',
      'Ein mächtiger Feuerdrache, der hoch fliegen und Feuer speien kann.'),
  Species(7, 'Schiggy',
      'Ein kleines Wasser-Pokémon, das sich in seinen Panzer zurückziehen kann.',
      evolvesAtEnergy: 100, evolvesTo: [8], catchWeight: 15),
  Species(8, 'Schillok',
      'Mit buschigem Schwanz und hartem Panzer schwimmt es blitzschnell.',
      evolvesAtEnergy: 200, evolvesTo: [9]),
  Species(9, 'Turtok',
      'Aus seinem Panzer schießen starke Wasserkanonen — die stärkste Stufe von Schiggy.'),
  Species(25, 'Pikachu',
      'Das berühmteste Elektro-Pokémon! In seinen Backen speichert es Blitze.',
      evolvesAtEnergy: 150, evolvesTo: [26], catchWeight: 15),
  Species(26, 'Raichu',
      'Die Entwicklung von Pikachu — sein langer Schwanz leitet starke Blitze.'),
  Species(39, 'Pummeluff',
      'Es singt so schön, dass alle einschlafen — pass gut auf!',
      evolvesAtEnergy: 120, evolvesTo: [40], catchWeight: 12),
  Species(40, 'Knuddeluff',
      'Groß, weich und zum Knuddeln — aber ein richtig starker Sänger.'),
  Species(50, 'Digda',
      'Es gräbt Tunnel unter der Erde und schaut nur mit dem Kopf heraus.',
      evolvesAtEnergy: 100, evolvesTo: [51], catchWeight: 12),
  Species(51, 'Digdri',
      'Drei Digda zusammen! Sie graben blitzschnell tiefe Tunnel.'),
  Species(52, 'Mauzi',
      'Eine schlaue Katze, die glänzende Münzen über alles liebt.',
      evolvesAtEnergy: 120, evolvesTo: [53], catchWeight: 12),
  Species(53, 'Snobilikat',
      'Elegant und flink — die Entwicklung von Mauzi mit dem Juwel auf der Stirn.'),
  Species(133, 'Evoli',
      'Ein besonderes Pokémon: Niemand weiß vorher, zu was es sich entwickelt!',
      evolvesAtEnergy: 120, evolvesTo: [134, 135, 136], catchWeight: 8),
  Species(134, 'Aquana',
      'Die Wasser-Entwicklung von Evoli — es schwimmt elegant wie eine Meerjungfrau.'),
  Species(135, 'Blitza',
      'Die Elektro-Entwicklung von Evoli — sein Fell knistert vor Strom.'),
  Species(136, 'Flamara',
      'Die Feuer-Entwicklung von Evoli — sein Fell ist herrlich warm.'),
  Species(143, 'Relaxo',
      'Es schläft fast den ganzen Tag und ist trotzdem riesig stark.',
      catchWeight: 5),
  Species(150, 'Mewtu',
      'Ein legendäres Pokémon mit gewaltigen Psycho-Kräften. Extrem selten!',
      catchWeight: 1),
];

/// Entwicklungskette der Familie eines Pokémon, als Stufen von der Grundform
/// aus (z.B. [[Glumanda], [Glutexo], [Glurak]] oder
/// [[Evoli], [Aquana, Blitza, Flamara]]).
List<List<Species>> evolutionChain(int id) {
  var root = speciesById(id);
  var searching = true;
  while (searching) {
    searching = false;
    for (final s in pokedex) {
      if (s.evolvesTo.contains(root.id)) {
        root = s;
        searching = true;
        break;
      }
    }
  }
  final levels = [
    [root]
  ];
  while (levels.last.any((s) => s.evolvesTo.isNotEmpty)) {
    levels.add([
      for (final s in levels.last) ...s.evolvesTo.map(speciesById)
    ]);
  }
  return levels;
}

Species speciesById(int id) => pokedex.firstWhere((s) => s.id == id);

List<Species> get catchableSpecies =>
    pokedex.where((s) => s.catchWeight > 0).toList();

/// Zieht ein zufälliges fangbares Pokémon, gewichtet nach [Species.catchWeight].
Species randomCatch(Random rng) {
  final pool = catchableSpecies;
  final total = pool.fold<int>(0, (sum, s) => sum + s.catchWeight);
  var roll = rng.nextInt(total);
  for (final s in pool) {
    roll -= s.catchWeight;
    if (roll < 0) return s;
  }
  return pool.first;
}
