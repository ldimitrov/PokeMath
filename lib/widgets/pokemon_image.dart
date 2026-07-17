import 'package:flutter/material.dart';

/// Zeigt das Artwork eines Pokémon; Fallback-Icon, falls das Bild fehlt
/// (z.B. wenn tool/fetch_sprites.sh noch nicht gelaufen ist).
class PokemonImage extends StatelessWidget {
  final int speciesId;
  final double size;

  const PokemonImage({super.key, required this.speciesId, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/pokemon/$speciesId.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(Icons.catching_pokemon,
          size: size, color: Theme.of(context).colorScheme.primary),
    );
  }
}
