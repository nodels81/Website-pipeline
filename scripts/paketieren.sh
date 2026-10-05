#!/usr/bin/env bash
# paketieren.sh — Schnürt das fertige Paket für ein Projekt: ausgang/<slug>/ (website, quellcode, dokumentation,
# vorschau, ERGEBNIS.md) plus ZIP. Wird am Ende der Pipeline vom Orchestrator aufgerufen, kann aber jederzeit
# manuell laufen.
#
# Nutzung: bash scripts/paketieren.sh <slug>
set -euo pipefail
cd "$(dirname "$0")/.."
SLUG="${1:-}"
[[ -z "$SLUG" ]] && { echo "Nutzung: bash scripts/paketieren.sh <slug>" >&2; exit 1; }
[[ "$SLUG" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { echo "Ungültiger Slug: $SLUG" >&2; exit 1; }

PROJ="projekte/${SLUG:?}"
OUT="ausgang/${SLUG:?}"
[[ -d "$PROJ" ]] || { echo "Projektordner $PROJ fehlt." >&2; exit 1; }

# Altes Paket entfernen (nur unterhalb von ausgang/)
[[ -d "$OUT" ]] && find "ausgang/${SLUG:?}" -mindepth 1 -delete
[[ -f "ausgang/${SLUG:?}.zip" ]] && unlink "ausgang/${SLUG:?}.zip"
[[ -f "ausgang/${SLUG:?}.tar.gz" ]] && unlink "ausgang/${SLUG:?}.tar.gz"
mkdir -p "$OUT"

copy_dir () { # $1 Quelle, $2 Ziel, $3.. Ausschlüsse
  local src="$1" dst="$2"; shift 2
  [[ -d "$src" ]] || return 0
  mkdir -p "$dst"
  if command -v rsync >/dev/null; then
    local ex=(); for e in "$@"; do ex+=(--exclude "$e"); done
    rsync -a "${ex[@]}" "$src/" "$dst/"
  else
    local tarex=(); for e in "$@"; do tarex+=(--exclude "./$e"); done
    (cd "$src" && tar -cf - "${tarex[@]}" .) | (cd "$dst" && tar -xf -)
  fi
}

echo "══ Paket für $SLUG"
# 1. Fertige Website (Build-Ausgabe)
if [[ -d "$PROJ/build/dist" ]]; then copy_dir "$PROJ/build/dist" "$OUT/website"; echo "   ✓ website/ (dist)";
else echo "   – kein Build vorhanden ($PROJ/build/dist fehlt)"; fi

# 2. Quellcode ohne Abhängigkeiten und Build-Reste
if [[ -d "$PROJ/build" ]]; then copy_dir "$PROJ/build" "$OUT/quellcode" node_modules dist .astro .git .vercel .netlify; echo "   ✓ quellcode/"; fi

# 3. Dokumentation
mkdir -p "$OUT/dokumentation"
if [[ -d "$PROJ/artefakte" ]]; then find "$PROJ/artefakte" -maxdepth 1 -name '*.md' -exec cp {} "$OUT/dokumentation/" \; ; fi
[[ -f "$PROJ/briefing.json" ]] && cp "$PROJ/briefing.json" "$OUT/dokumentation/"
[[ -f "$PROJ/design/tokens.css" ]] && cp "$PROJ/design/tokens.css" "$OUT/dokumentation/"
echo "   ✓ dokumentation/ ($(ls "$OUT/dokumentation" | wc -l) Dateien)"

# 4. Vorschau-Screenshots (QA-Lauf bevorzugt, sonst Build-Selbstprüfung, sonst Ist-Analyse)
for src in "analyse/$SLUG-qa/screenshots" "analyse/$SLUG-build/screenshots" "analyse/$SLUG/screenshots"; do
  if [[ -d "$src" ]]; then mkdir -p "$OUT/vorschau"; find "$src" -maxdepth 1 -name '*.png' -exec cp {} "$OUT/vorschau/" \; ; echo "   ✓ vorschau/ (aus $src)"; break; fi
done

# 5. Ergebnisbericht
if [[ -f "$PROJ/ERGEBNIS.md" ]]; then cp "$PROJ/ERGEBNIS.md" "$OUT/ERGEBNIS.md"; echo "   ✓ ERGEBNIS.md";
elif [[ -f "$PROJ/artefakte/14-ergebnis.md" ]]; then cp "$PROJ/artefakte/14-ergebnis.md" "$OUT/ERGEBNIS.md"; echo "   ✓ ERGEBNIS.md (aus 14-ergebnis.md)";
else echo "   – ERGEBNIS.md fehlt (Orchestrator schreibt sie am Ende der Pipeline)"; fi

# 5b. Starter zum Ansehen (Doppelklick unter Windows, bash unter macOS/Linux)
if [[ -d "$OUT/website" ]]; then
  printf '%s\r\n' '@echo off' \
    'rem Doppelklick: startet einen lokalen Webserver fuer diese Website und oeffnet den Browser.' \
    'rem Voraussetzung: Node.js (https://nodejs.org). Beenden: dieses Fenster schliessen.' \
    'cd /d "%~dp0"' \
    'start "" cmd /c "timeout /t 4 >nul & start http://localhost:4321"' \
    'npx --yes serve website -l 4321' > "$OUT/Website-ansehen.cmd"
  printf '%s\n' '#!/usr/bin/env bash' 'cd "$(dirname "$0")"' \
    '( sleep 3; (open http://localhost:4321 || xdg-open http://localhost:4321) >/dev/null 2>&1 ) &' \
    'exec npx --yes serve website -l 4321' > "$OUT/website-ansehen.sh"
  chmod +x "$OUT/website-ansehen.sh"
  echo "   ✓ Website-ansehen.cmd / website-ansehen.sh"
fi

# 6. Archiv
# ZIP: zip (Linux/macOS) > PowerShell (Windows/Git Bash) > Python > tar.gz als letzte Möglichkeit
if command -v zip >/dev/null; then
  (cd ausgang && zip -qr "$SLUG.zip" "$SLUG"); echo "   ✓ ausgang/$SLUG.zip"
elif PS=$(command -v powershell.exe || command -v pwsh); then
  (cd ausgang && "$PS" -NoProfile -NonInteractive -Command "Compress-Archive -Path '$SLUG' -DestinationPath '$SLUG.zip' -Force") \
    && echo "   ✓ ausgang/$SLUG.zip (PowerShell)"
elif PY=$(command -v python3 || command -v python); then
  (cd ausgang && "$PY" -m zipfile -c "$SLUG.zip" "$SLUG") && echo "   ✓ ausgang/$SLUG.zip (Python)"
else
  (cd ausgang && tar -czf "$SLUG.tar.gz" "$SLUG"); echo "   ✓ ausgang/$SLUG.tar.gz (kein ZIP-Werkzeug gefunden)"
fi

echo
echo "Paket: $OUT"
du -sh "$OUT" 2>/dev/null | awk '{print "Größe: " $1}'
