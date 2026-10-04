#!/usr/bin/env bash
# analyse.sh — Komplette technische Ist-Analyse einer URL in einem Lauf:
# Screenshots, Crawl, Design-Tokens, Lighthouse. Umfang nach Sparprofil (pipeline.config.json).
#
# Nutzung:
#   bash analyse.sh <url> [out-dir] [--max-pages N] [--skip-lighthouse] [--profil sparsam|standard|premium]
set -euo pipefail
cd "$(dirname "$0")"

URL="${1:-}"
[[ -z "$URL" ]] && { echo "Nutzung: bash analyse.sh <url> [out-dir] [--max-pages N] [--skip-lighthouse] [--profil name]" >&2; exit 1; }
case "$URL" in http://*|https://*) ;; *) URL="https://$URL";; esac
shift || true

OUT=""; MAX=""; SKIP_LH=0; PROFIL="${PIPELINE_PROFIL:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-pages) MAX="$2"; shift 2;;
    --skip-lighthouse) SKIP_LH=1; shift;;
    --profil) PROFIL="$2"; shift 2;;
    --*) echo "Unbekannte Option: $1" >&2; exit 1;;
    *) OUT="$1"; shift;;
  esac
done

SLUG=$(echo "$URL" | sed -E 's#^https?://##; s#^www\.##; s#[^A-Za-z0-9]+#-#g; s#^-+|-+$##g' | tr '[:upper:]' '[:lower:]')
OUT="${OUT:-../analyse/$SLUG}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

[[ -d node_modules/playwright ]] || { echo "→ npm install (Playwright) …"; npm install --no-audit --no-fund >/dev/null; }

# Profilwerte
PROFIL="${PROFIL:-$(node -e 'console.log(require("../pipeline.config.json").profil||"standard")')}"
SHOTS=$(node profil.mjs --wert screenshots "$PROFIL")
DARK=$(node profil.mjs --wert dunkelmodusScreenshots "$PROFIL")
[[ -z "$MAX" ]] && MAX=$(node profil.mjs --wert maxSeitenCrawl "$PROFIL")
SHOT_ARGS=(--viewports desktop,mobile)
CRAWL_ARGS=()
if [[ "$SHOTS" == "fold" ]]; then SHOT_ARGS+=(--fold-only --dpr 1); CRAWL_ARGS+=(--kompakt); fi
if [[ "$SHOTS" == "fold+full" ]]; then SHOT_ARGS=(--viewports desktop,tablet,mobile); fi
[[ "$DARK" == "true" ]] && SHOT_ARGS+=(--dark)
echo "Profil: $PROFIL · Screenshots: $SHOTS · Crawl max. $MAX Seiten"

echo "══ 1/4 Screenshots"; node screenshot.mjs "$URL" --out "$OUT" "${SHOT_ARGS[@]}" || echo "   (Screenshots fehlgeschlagen)"
echo "══ 2/4 Crawl";       node crawl.mjs "$URL" --out "$OUT" --max "$MAX" ${CRAWL_ARGS[@]+"${CRAWL_ARGS[@]}"} || echo "   (Crawl fehlgeschlagen)"
echo "══ 3/4 Design-Tokens"; node tokens.mjs "$URL" --out "$OUT" >/dev/null && echo "   ✓ tokens.md" || echo "   (Tokens fehlgeschlagen)"
if [[ "$SKIP_LH" == "1" ]]; then echo "══ 4/4 Lighthouse übersprungen"; else echo "══ 4/4 Lighthouse"; bash audit.sh "$URL" "$OUT" >/dev/null && echo "   ✓ lighthouse-summary.md" || echo "   (Lighthouse fehlgeschlagen)"; fi

echo
echo "Fertig. Analyse-Ordner: $OUT"
ls -1 "$OUT"
