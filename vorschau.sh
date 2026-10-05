#!/usr/bin/env bash
# vorschau.sh — startet einen lokalen Webserver für ein fertiges Projekt (macOS/Linux/Git Bash).
# Nutzung: bash vorschau.sh <slug> [port]
set -euo pipefail
cd "$(dirname "$0")"
SLUG="${1:-}"; PORT="${2:-4321}"
[[ -z "$SLUG" ]] && { echo "Nutzung: bash vorschau.sh <projekt> [port]"; ls ausgang 2>/dev/null | grep -v -E '\.(zip|tar\.gz)$' || true; exit 1; }
DIR="ausgang/$SLUG/website"
[[ -f "$DIR/index.html" ]] || DIR="projekte/$SLUG/build/dist"
[[ -f "$DIR/index.html" ]] || { echo "Keine fertige Website für $SLUG gefunden."; exit 1; }
echo "Vorschau von $DIR → http://localhost:$PORT (Beenden: Strg+C)"
( sleep 3; command -v open >/dev/null && open "http://localhost:$PORT" || command -v xdg-open >/dev/null && xdg-open "http://localhost:$PORT" ) >/dev/null 2>&1 &
exec npx --yes serve "$DIR" -l "$PORT"
