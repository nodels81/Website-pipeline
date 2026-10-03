#!/usr/bin/env bash
# analyse.sh — Komplette technische Ist-Analyse einer URL in einem Lauf:
# Screenshots (3 Viewports, hell/dunkel), Crawl (bis 20 Seiten), Design-Tokens, Lighthouse.
#
# Nutzung:
#   bash analyse.sh <url> [out-dir] [--max-pages 20] [--skip-lighthouse]
set -euo pipefail
cd "$(dirname "$0")"

URL="${1:-}"
[[ -z "$URL" ]] && { echo "Nutzung: bash analyse.sh <url> [out-dir] [--max-pages N] [--skip-lighthouse]" >&2; exit 1; }
case "$URL" in http://*|https://*) ;; *) URL="https://$URL";; esac
shift || true

OUT=""
MAX=20
SKIP_LH=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-pages) MAX="$2"; shift 2;;
    --skip-lighthouse) SKIP_LH=1; shift;;
    --*) echo "Unbekannte Option: $1" >&2; exit 1;;
    *) OUT="$1"; shift;;
  esac
done

SLUG=$(echo "$URL" | sed -E 's#^https?://##; s#^www\.##; s#[^A-Za-z0-9]+#-#g; s#^-+|-+$##g' | tr '[:upper:]' '[:lower:]')
OUT="${OUT:-../analyse/$SLUG}"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

[[ -d node_modules/playwright ]] || { echo "→ npm install (Playwright) …"; npm install --no-audit --no-fund >/dev/null; }

echo "══ 1/4 Screenshots"; node screenshot.mjs "$URL" --out "$OUT" --dark || echo "   (Screenshots fehlgeschlagen)"
echo "══ 2/4 Crawl";       node crawl.mjs "$URL" --out "$OUT" --max "$MAX" || echo "   (Crawl fehlgeschlagen)"
echo "══ 3/4 Design-Tokens"; node tokens.mjs "$URL" --out "$OUT" >/dev/null && echo "   ✓ tokens.md" || echo "   (Tokens fehlgeschlagen)"
if [[ "$SKIP_LH" == "1" ]]; then echo "══ 4/4 Lighthouse übersprungen"; else echo "══ 4/4 Lighthouse"; bash audit.sh "$URL" "$OUT" >/dev/null && echo "   ✓ lighthouse-summary.md" || echo "   (Lighthouse fehlgeschlagen)"; fi

echo
echo "Fertig. Analyse-Ordner: $OUT"
ls -1 "$OUT"
