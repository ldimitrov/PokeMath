// Entwickler-Werkzeug: holt Daten neuer Pokémon von PokeAPI und druckt
// fertige Species-Einträge für lib/data/pokedex.dart.
//
//   dart run tool/fetch_pokemon_data.dart 54 104 151
//
// Danach: die neuen IDs in tool/fetch_sprites.sh ergänzen und ausführen.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

const typeDe = {
  'normal': 'normal',
  'fire': 'feuer',
  'water': 'wasser',
  'grass': 'pflanze',
  'electric': 'elektro',
  'ice': 'eis',
  'fighting': 'kampf',
  'poison': 'gift',
  'ground': 'boden',
  'flying': 'flug',
  'psychic': 'psycho',
  'bug': 'kaefer',
  'rock': 'gestein',
  'ghost': 'geist',
  'dragon': 'drache',
  'dark': 'unlicht',
  'steel': 'stahl',
  'fairy': 'fee',
};

Future<Map<String, dynamic>> fetchJson(HttpClient client, String url) async {
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
  if (response.statusCode != 200) {
    throw 'HTTP ${response.statusCode} für $url';
  }
  return jsonDecode(await response.transform(utf8.decoder).join())
      as Map<String, dynamic>;
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('Benutzung: dart run tool/fetch_pokemon_data.dart <dex-id> ...');
    exit(1);
  }
  final client = HttpClient();
  for (final arg in args) {
    final id = int.parse(arg);
    final pokemon = await fetchJson(
      client,
      'https://pokeapi.co/api/v2/pokemon/$id',
    );
    final species = await fetchJson(
      client,
      'https://pokeapi.co/api/v2/pokemon-species/$id',
    );

    final types = [
      for (final t in pokemon['types'] as List)
        typeDe[t['type']['name']] ?? '/* unbekannt: ${t['type']['name']} */',
    ];
    final nameDe = ((species['names'] as List).firstWhere(
      (n) => n['language']['name'] == 'de',
      orElse: () => {'name': pokemon['name']},
    ))['name'];
    final flavorDe = ((species['flavor_text_entries'] as List).firstWhere(
      (f) => f['language']['name'] == 'de',
      orElse: () => {'flavor_text': 'TODO: Beschreibung schreiben'},
    ))['flavor_text'].toString().replaceAll(RegExp(r'\s+'), ' ').trim();

    print('''
  Species($id, '$nameDe',
      types: [${types.map((t) => 'PokeType.$t').join(', ')}],
      // Vorschlag (Spieltext, bitte kindgerecht umformulieren!):
      // $flavorDe
      'TODO',
      catchWeight: 10),''');
  }
  client.close();
}
