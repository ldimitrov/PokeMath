#!/usr/bin/env bash
# Installiert die App als UPDATE auf das per USB verbundene Handy.
# Wichtig: nutzt `adb install -r`, das die App-Daten (Profile, Pokémon)
# IMMER erhält. Anders als `flutter install` deinstalliert es NIEMALS
# automatisch — schlägt das Update fehl, bricht es einfach ab.
set -euo pipefail
cd "$(dirname "$0")/.."
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
APK="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK" ]; then
  echo "APK fehlt — erst bauen: flutter build apk --release"
  exit 1
fi
"$ADB" install -r "$APK"
echo "Fertig — Update installiert, alle Spielstände bleiben erhalten."
