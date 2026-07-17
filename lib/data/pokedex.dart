/// Statische Pokédex-Daten. Die Bild-Dateien liegen unter assets/pokemon/<id>.png.
class Species {
  final int id; // Nationaldex-Nummer = Dateiname des Bildes
  final String name; // deutscher Name
  final int? evolvesAtEnergy; // Energie, ab der entwickelt werden kann
  final List<int> evolvesTo; // mehrere Einträge = zufällige Entwicklung (Evoli)
  final int catchWeight; // 0 = nicht fangbar (nur durch Entwicklung erhältlich)

  const Species(this.id, this.name,
      {this.evolvesAtEnergy, this.evolvesTo = const [], this.catchWeight = 0});

  bool get canEvolve => evolvesTo.isNotEmpty;
}

const List<Species> pokedex = [
  Species(1, 'Bisasam', evolvesAtEnergy: 100, evolvesTo: [2], catchWeight: 15),
  Species(2, 'Bisaknosp', evolvesAtEnergy: 200, evolvesTo: [3]),
  Species(3, 'Bisaflor'),
  Species(4, 'Glumanda', evolvesAtEnergy: 100, evolvesTo: [5], catchWeight: 15),
  Species(5, 'Glutexo', evolvesAtEnergy: 200, evolvesTo: [6]),
  Species(6, 'Glurak'),
  Species(7, 'Schiggy', evolvesAtEnergy: 100, evolvesTo: [8], catchWeight: 15),
  Species(8, 'Schillok', evolvesAtEnergy: 200, evolvesTo: [9]),
  Species(9, 'Turtok'),
  Species(25, 'Pikachu', evolvesAtEnergy: 150, evolvesTo: [26], catchWeight: 15),
  Species(26, 'Raichu'),
  Species(39, 'Pummeluff', evolvesAtEnergy: 120, evolvesTo: [40], catchWeight: 12),
  Species(40, 'Knuddeluff'),
  Species(50, 'Digda', evolvesAtEnergy: 100, evolvesTo: [51], catchWeight: 12),
  Species(51, 'Digdri'),
  Species(52, 'Mauzi', evolvesAtEnergy: 120, evolvesTo: [53], catchWeight: 12),
  Species(53, 'Snobilikat'),
  Species(133, 'Evoli',
      evolvesAtEnergy: 120, evolvesTo: [134, 135, 136], catchWeight: 8),
  Species(134, 'Aquana'),
  Species(135, 'Blitza'),
  Species(136, 'Flamara'),
  Species(143, 'Relaxo', catchWeight: 5),
  Species(150, 'Mewtu', catchWeight: 1),
];

Species speciesById(int id) => pokedex.firstWhere((s) => s.id == id);

List<Species> get catchableSpecies =>
    pokedex.where((s) => s.catchWeight > 0).toList();
