import 'dart:math';

import 'package:flutter/material.dart';

/// Die 18 Pokémon-Typen mit deutschem Namen und Anzeigefarbe.
enum PokeType {
  normal('Normal', Color(0xFF8A8A6D)),
  feuer('Feuer', Color(0xFFF08030)),
  wasser('Wasser', Color(0xFF6890F0)),
  pflanze('Pflanze', Color(0xFF60A03E)),
  elektro('Elektro', Color(0xFFC7A008)),
  eis('Eis', Color(0xFF45B5C4)),
  kampf('Kampf', Color(0xFFC03028)),
  gift('Gift', Color(0xFFA040A0)),
  boden('Boden', Color(0xFFA98C4C)),
  flug('Flug', Color(0xFFA890F0)),
  psycho('Psycho', Color(0xFFF85888)),
  kaefer('Käfer', Color(0xFFA8B820)),
  gestein('Gestein', Color(0xFFB8A038)),
  geist('Geist', Color(0xFF705898)),
  drache('Drache', Color(0xFF7038F8)),
  unlicht('Unlicht', Color(0xFF705848)),
  stahl('Stahl', Color(0xFF9797B5)),
  fee('Fee', Color(0xFFE87A9C));

  final String label;
  final Color color;
  const PokeType(this.label, this.color);
}

/// Statische Pokédex-Daten. Die Bild-Dateien liegen unter `assets/pokemon/<id>.png`.
class Species {
  final int id; // Nationaldex-Nummer = Dateiname des Bildes
  final String name; // deutscher Name
  final String description; // kurze kindgerechte Beschreibung
  final List<PokeType> types;
  final int? evolvesAtEnergy; // Energie, ab der entwickelt werden kann
  final List<int> evolvesTo; // mehrere Einträge = zufällige Entwicklung (Evoli)
  final int catchWeight; // 0 = nicht fangbar (nur durch Entwicklung erhältlich)

  const Species(
    this.id,
    this.name,
    this.description, {
    required this.types,
    this.evolvesAtEnergy,
    this.evolvesTo = const [],
    this.catchWeight = 0,
  });

  bool get canEvolve => evolvesTo.isNotEmpty;
}

const List<Species> pokedex = [
  Species(
    1,
    'Bisasam',
    types: [PokeType.pflanze, PokeType.gift],
    'Ein Pflanzen-Pokémon mit einer Knospe auf dem Rücken, die mit ihm wächst.',
    evolvesAtEnergy: 100,
    evolvesTo: [2],
    catchWeight: 15,
  ),
  Species(
    2,
    'Bisaknosp',
    types: [PokeType.pflanze, PokeType.gift],
    'Seine Knospe ist zu einer großen Blüte geworden, die in der Sonne Kraft tankt.',
    evolvesAtEnergy: 200,
    evolvesTo: [3],
  ),
  Species(
    3,
    'Bisaflor',
    types: [PokeType.pflanze, PokeType.gift],
    'Die riesige Blume auf seinem Rücken duftet wunderbar — die stärkste Stufe von Bisasam.',
  ),
  Species(
    4,
    'Glumanda',
    types: [PokeType.feuer],
    'Ein Feuer-Pokémon. Die Flamme an seinem Schwanz zeigt, wie es sich fühlt.',
    evolvesAtEnergy: 100,
    evolvesTo: [5],
    catchWeight: 15,
  ),
  Species(
    5,
    'Glutexo',
    types: [PokeType.feuer],
    'Größer und wilder als Glumanda — seine Flamme brennt jetzt richtig heiß.',
    evolvesAtEnergy: 200,
    evolvesTo: [6],
  ),
  Species(
    6,
    'Glurak',
    types: [PokeType.feuer, PokeType.flug],
    'Ein mächtiger Feuerdrache, der hoch fliegen und Feuer speien kann.',
  ),
  Species(
    7,
    'Schiggy',
    types: [PokeType.wasser],
    'Ein kleines Wasser-Pokémon, das sich in seinen Panzer zurückziehen kann.',
    evolvesAtEnergy: 100,
    evolvesTo: [8],
    catchWeight: 15,
  ),
  Species(
    8,
    'Schillok',
    types: [PokeType.wasser],
    'Mit buschigem Schwanz und hartem Panzer schwimmt es blitzschnell.',
    evolvesAtEnergy: 200,
    evolvesTo: [9],
  ),
  Species(
    9,
    'Turtok',
    types: [PokeType.wasser],
    'Aus seinem Panzer schießen starke Wasserkanonen — die stärkste Stufe von Schiggy.',
  ),
  Species(
    172,
    'Pichu',
    types: [PokeType.elektro],
    'Ein winziges Elektro-Baby. Es kann noch nicht viel Strom speichern und erschreckt sich manchmal selbst.',
    evolvesAtEnergy: 100,
    evolvesTo: [25],
    catchWeight: 10,
  ),
  Species(
    25,
    'Pikachu',
    types: [PokeType.elektro],
    'Das berühmteste Elektro-Pokémon! In seinen Backen speichert es Blitze.',
    evolvesAtEnergy: 150,
    evolvesTo: [26],
  ),
  Species(
    26,
    'Raichu',
    types: [PokeType.elektro],
    'Die Entwicklung von Pikachu — sein langer Schwanz leitet starke Blitze.',
  ),
  Species(
    39,
    'Pummeluff',
    types: [PokeType.normal, PokeType.fee],
    'Es singt so schön, dass alle einschlafen — pass gut auf!',
    evolvesAtEnergy: 120,
    evolvesTo: [40],
    catchWeight: 12,
  ),
  Species(
    40,
    'Knuddeluff',
    types: [PokeType.normal, PokeType.fee],
    'Groß, weich und zum Knuddeln — aber ein richtig starker Sänger.',
  ),
  Species(
    50,
    'Digda',
    types: [PokeType.boden],
    'Es gräbt Tunnel unter der Erde und schaut nur mit dem Kopf heraus.',
    evolvesAtEnergy: 100,
    evolvesTo: [51],
    catchWeight: 12,
  ),
  Species(
    51,
    'Digdri',
    types: [PokeType.boden],
    'Drei Digda zusammen! Sie graben blitzschnell tiefe Tunnel.',
  ),
  Species(
    52,
    'Mauzi',
    types: [PokeType.normal],
    'Eine schlaue Katze, die glänzende Münzen über alles liebt.',
    evolvesAtEnergy: 120,
    evolvesTo: [53],
    catchWeight: 12,
  ),
  Species(
    53,
    'Snobilikat',
    types: [PokeType.normal],
    'Elegant und flink — die Entwicklung von Mauzi mit dem Juwel auf der Stirn.',
  ),
  Species(
    54,
    'Enton',
    types: [PokeType.wasser],
    'Es hat ständig Kopfschmerzen. Werden sie zu stark, setzt es geheimnisvolle Kräfte frei.',
    evolvesAtEnergy: 120,
    evolvesTo: [55],
    catchWeight: 10,
  ),
  Species(
    55,
    'Entoron',
    types: [PokeType.wasser],
    'Ein eleganter, blitzschneller Schwimmer — die Entwicklung von Enton.',
  ),
  Species(
    58,
    'Fukano',
    types: [PokeType.feuer],
    'Ein treuer Feuer-Welpe, der seine Freunde mutig beschützt.',
    evolvesAtEnergy: 130,
    evolvesTo: [59],
    catchWeight: 10,
  ),
  Species(
    59,
    'Arkani',
    types: [PokeType.feuer],
    'Ein majestätischer Feuerhund, der schneller rennt, als man schauen kann.',
  ),
  Species(
    129,
    'Karpador',
    types: [PokeType.wasser],
    'Es zappelt nur herum und kann fast nichts — aber wer geduldig ist, erlebt eine riesige Überraschung!',
    evolvesAtEnergy: 300,
    evolvesTo: [130],
    catchWeight: 15,
  ),
  Species(
    130,
    'Garados',
    types: [PokeType.wasser, PokeType.flug],
    'Aus dem schwachen Karpador wird ein gewaltiger Seedrache. Geduld zahlt sich aus!',
  ),
  Species(
    133,
    'Evoli',
    types: [PokeType.normal],
    'Ein besonderes Pokémon: Niemand weiß vorher, zu was es sich entwickelt!',
    evolvesAtEnergy: 120,
    evolvesTo: [134, 135, 136],
    catchWeight: 8,
  ),
  Species(
    134,
    'Aquana',
    types: [PokeType.wasser],
    'Die Wasser-Entwicklung von Evoli — es schwimmt elegant wie eine Meerjungfrau.',
  ),
  Species(
    135,
    'Blitza',
    types: [PokeType.elektro],
    'Die Elektro-Entwicklung von Evoli — sein Fell knistert vor Strom.',
  ),
  Species(
    136,
    'Flamara',
    types: [PokeType.feuer],
    'Die Feuer-Entwicklung von Evoli — sein Fell ist herrlich warm.',
  ),
  Species(
    143,
    'Relaxo',
    types: [PokeType.normal],
    'Es schläft fast den ganzen Tag und ist trotzdem riesig stark.',
  ),
  Species(
    147,
    'Dratini',
    types: [PokeType.drache],
    'Ein seltenes Drachen-Pokémon, das in tiefen Gewässern lebt und ständig wächst.',
    evolvesAtEnergy: 150,
    evolvesTo: [148],
    catchWeight: 4,
  ),
  Species(
    148,
    'Dragonir',
    types: [PokeType.drache],
    'Sein schlanker Körper gleitet elegant durch die Luft. Man sagt, es kann das Wetter ändern.',
    evolvesAtEnergy: 250,
    evolvesTo: [149],
  ),
  Species(
    149,
    'Dragoran',
    types: [PokeType.drache, PokeType.flug],
    'Ein freundlicher, mächtiger Drache, der übers Meer fliegt und Schiffbrüchigen hilft.',
  ),
  Species(
    150,
    'Mewtu',
    types: [PokeType.psycho],
    'Ein legendäres Pokémon mit gewaltigen Psycho-Kräften. Extrem selten!',
    catchWeight: 1,
  ),
  Species(
    151,
    'Mew',
    types: [PokeType.psycho],
    'Ein geheimnisvolles, verspieltes Pokémon. Nur ganz wenige haben es je gesehen!',
    catchWeight: 1,
  ),
  Species(
    446,
    'Mampfaxo',
    types: [PokeType.normal],
    'Es futtert den ganzen Tag — und wächst irgendwann zu einem riesigen Relaxo heran.',
    evolvesAtEnergy: 150,
    evolvesTo: [143],
    catchWeight: 6,
  ),
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
    [root],
  ];
  while (levels.last.any((s) => s.evolvesTo.isNotEmpty)) {
    levels.add([for (final s in levels.last) ...s.evolvesTo.map(speciesById)]);
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
