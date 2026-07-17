#!/usr/bin/env bash
# Downloads the Pokémon artwork used by the app into assets/pokemon/.
# These images are intentionally NOT committed (public repo, copyrighted art).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p assets/pokemon
for id in 1 2 3 4 5 6 7 8 9 25 26 39 40 50 51 52 53 133 134 135 136 143 150; do
  [ -f "assets/pokemon/$id.png" ] && continue
  echo "Fetching $id..."
  curl -sfL -o "assets/pokemon/$id.png" \
    "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png"
done
echo "Done: $(ls assets/pokemon | wc -l | tr -d ' ') sprites."
