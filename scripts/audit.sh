#!/usr/bin/env bash
# audit.sh — Lighthouse-Audit (Mobile + Desktop) einer URL. Ergebnis: JSON + HTML + Kurzfassung.
#
# Nutzung:
#   bash audit.sh <url> [out-dir]
#
# Voraussetzung: Node >= 18, Chrome/Chromium. Pfad optional via CHROME_PATH.
set -euo pipefail

URL="${1:-}"
if [[ -z "$URL" ]]; then
  echo "Nutzung: bash audit.sh <url> [out-dir]" >&2
  exit 1
fi
case "$URL" in http://*|https://*) ;; *) URL="https://$URL";; esac

SLUG=$(echo "$URL" | sed -E 's#^https?://##; s#^www\.##; s#[^A-Za-z0-9]+#-#g; s#^-+|-+$##g' | tr '[:upper:]' '[:lower:]')
OUT="${2:-analyse/$SLUG}"
mkdir -p "$OUT/lighthouse"

# Chrome finden: CHROME_PATH > Playwright-Chromium (Linux/macOS/Windows) > System
if [[ -z "${CHROME_PATH:-}" ]]; then
  PW_DIRS=("${PLAYWRIGHT_BROWSERS_PATH:-}" "$HOME/.cache/ms-playwright" "$HOME/Library/Caches/ms-playwright" "${LOCALAPPDATA:-}/ms-playwright")
  for d in "${PW_DIRS[@]}"; do
    [[ -n "$d" && -d "$d" ]] || continue
    for c in "$(ls -d "$d"/chromium-*/chrome-linux/chrome 2>/dev/null | sort -V | tail -1)" \
             "$(ls -d "$d"/chromium-*/chrome-mac*/Chromium.app/Contents/MacOS/Chromium 2>/dev/null | sort -V | tail -1)" \
             "$(ls -d "$d"/chromium-*/chrome-win*/chrome.exe 2>/dev/null | sort -V | tail -1)"; do
      if [[ -n "$c" && -x "$c" ]]; then export CHROME_PATH="$c"; break 2; fi
    done
  done
fi
if [[ -z "${CHROME_PATH:-}" ]]; then
  for c in "$(command -v google-chrome || true)" "$(command -v chromium || true)" "$(command -v chromium-browser || true)" \
           "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
           "${PROGRAMFILES:-/c/Program Files}/Google/Chrome/Application/chrome.exe"; do
    if [[ -n "$c" && -x "$c" ]]; then export CHROME_PATH="$c"; break; fi
  done
fi
echo "Chrome: ${CHROME_PATH:-<nicht gefunden – Lighthouse sucht selbst>}"

FLAGS="--headless=new --no-sandbox --disable-dev-shm-usage --disable-gpu"
# Proxy nur für externe Ziele (lokale Preview-Server laufen direkt)
if [[ -n "${HTTPS_PROXY:-}" && ! "$URL" =~ ^https?://(localhost|127\.|0\.0\.0\.0|10\.|192\.168\.|\[::1\]) ]]; then
  FLAGS="$FLAGS --proxy-server=${HTTPS_PROXY} --proxy-bypass-list=localhost,127.0.0.1"
fi

run_lh () {
  local preset="$1" name="$2"
  echo "→ Lighthouse ($name) …"
  npx --yes lighthouse@12 "$URL" \
    --quiet --output=json --output=html \
    --output-path="$OUT/lighthouse/$name" \
    --chrome-flags="$FLAGS" \
    --only-categories=performance,accessibility,best-practices,seo \
    $preset || echo "   (Lighthouse $name fehlgeschlagen)"
}

run_lh "" "mobile"
run_lh "--preset=desktop" "desktop"

summarize () {
  local f="$1" name="$2"
  [[ -f "$f" ]] || { echo "| $name | – | – | – | – | – | – | – |"; return; }
  node -e '
    const r = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
    const c = r.categories, a = r.audits;
    const pct = (k) => c[k] ? Math.round(c[k].score * 100) : "–";
    const v = (k) => a[k]?.displayValue || "–";
    console.log(`| ${process.argv[2]} | ${pct("performance")} | ${pct("accessibility")} | ${pct("best-practices")} | ${pct("seo")} | ${v("largest-contentful-paint")} | ${v("cumulative-layout-shift")} | ${v("total-blocking-time")} |`);
  ' "$f" "$name"
}

{
  echo "# Lighthouse-Audit: $URL"
  echo "Stand: $(date -Iseconds)"
  echo
  echo "| Gerät | Performance | Barrierefreiheit | Best Practices | SEO | LCP | CLS | TBT |"
  echo "|---|---|---|---|---|---|---|---|"
  summarize "$OUT/lighthouse/mobile.report.json" "Mobile"
  summarize "$OUT/lighthouse/desktop.report.json" "Desktop"
  echo
  echo "Zielwerte Premium: Performance ≥ 90 (mobil), Barrierefreiheit ≥ 95, LCP ≤ 2,0 s, CLS ≤ 0,05, TBT ≤ 150 ms."
  echo
  echo "## Wichtigste Befunde (Mobile)"
  if [[ -f "$OUT/lighthouse/mobile.report.json" ]]; then
    node -e '
      const r = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
      const fails = Object.values(r.audits)
        .filter(x => x.score !== null && x.score < 0.9 && x.scoreDisplayMode !== "informative" && x.scoreDisplayMode !== "notApplicable")
        .sort((x, y) => (x.score ?? 0) - (y.score ?? 0)).slice(0, 15);
      for (const f of fails) console.log(`- **${f.title}** (${Math.round((f.score ?? 0) * 100)}) ${f.displayValue ? "– " + f.displayValue : ""}`);
      if (!fails.length) console.log("- Keine Audits unter 90 Punkten.");
    ' "$OUT/lighthouse/mobile.report.json"
  else
    echo "- Kein Mobile-Report vorhanden."
  fi
  echo
  echo "Vollständige Berichte: $OUT/lighthouse/mobile.report.html, $OUT/lighthouse/desktop.report.html"
} > "$OUT/lighthouse-summary.md"

cat "$OUT/lighthouse-summary.md"
