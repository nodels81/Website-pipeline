#!/usr/bin/env bash
# deploy.sh — Veröffentlicht den Build eines Projekts auf dem konfigurierten Ziel.
#
# Nutzung: bash scripts/deploy.sh <slug> [--prod]
#
# Ziel: pipeline.config.json → deploy.ziel (netlify | vercel | cloudflare) oder Umgebungsvariable DEPLOY_ZIEL.
# Zugangsdaten ausschließlich über Umgebungsvariablen:
#   netlify:    NETLIFY_AUTH_TOKEN, NETLIFY_SITE_ID
#   vercel:     VERCEL_TOKEN
#   cloudflare: CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID, CF_PAGES_PROJECT
# Ohne --prod wird eine Vorschau (Draft/Preview) erzeugt. Hinweis: in der Entwicklungs-Sandbox ungetestet,
# die Aufrufe entsprechen der Dokumentation der jeweiligen CLI.
set -euo pipefail
cd "$(dirname "$0")/.."
SLUG="${1:-}"; PROD=0
[[ -z "$SLUG" ]] && { echo "Nutzung: bash scripts/deploy.sh <slug> [--prod]" >&2; exit 1; }
[[ "${2:-}" == "--prod" ]] && PROD=1

DIST="projekte/$SLUG/build/dist"
[[ -d "$DIST" ]] || { echo "Kein Build gefunden: $DIST (erst 'npm run build' im Projekt)." >&2; exit 1; }

ZIEL="${DEPLOY_ZIEL:-}"
if [[ -z "$ZIEL" && -f pipeline.config.json ]]; then
  ZIEL=$(node -e 'const c=require("./pipeline.config.json"); console.log((c.deploy&&c.deploy.ziel)||"none")')
fi
[[ -n "$ZIEL" ]] || ZIEL=none

echo "Deploy-Ziel: $ZIEL · Modus: $([[ $PROD == 1 ]] && echo Produktion || echo Vorschau) · Quelle: $DIST"
case "$ZIEL" in
  netlify)
    : "${NETLIFY_AUTH_TOKEN:?NETLIFY_AUTH_TOKEN fehlt}" "${NETLIFY_SITE_ID:?NETLIFY_SITE_ID fehlt}"
    ARGS=(deploy --dir "$DIST" --site "$NETLIFY_SITE_ID" --message "Pipeline $SLUG"); [[ $PROD == 1 ]] && ARGS+=(--prod)
    npx --yes netlify-cli "${ARGS[@]}"
    ;;
  vercel)
    : "${VERCEL_TOKEN:?VERCEL_TOKEN fehlt}"
    ARGS=(deploy "$DIST" --yes --token "$VERCEL_TOKEN"); [[ $PROD == 1 ]] && ARGS+=(--prod)
    npx --yes vercel "${ARGS[@]}"
    ;;
  cloudflare)
    : "${CLOUDFLARE_API_TOKEN:?CLOUDFLARE_API_TOKEN fehlt}" "${CLOUDFLARE_ACCOUNT_ID:?CLOUDFLARE_ACCOUNT_ID fehlt}" "${CF_PAGES_PROJECT:?CF_PAGES_PROJECT fehlt}"
    ARGS=(pages deploy "$DIST" --project-name "$CF_PAGES_PROJECT")
    if [[ $PROD == 1 ]]; then ARGS+=(--branch main); else ARGS+=(--branch "vorschau-$SLUG"); fi
    npx --yes wrangler "${ARGS[@]}"
    ;;
  none|"")
    echo "Kein Deploy-Ziel konfiguriert. Setzen Sie deploy.ziel in pipeline.config.json oder DEPLOY_ZIEL."
    echo "Alternativ: Inhalt von $DIST (bzw. ausgang/$SLUG/website/) manuell auf den Host laden."
    exit 2
    ;;
  *)
    echo "Unbekanntes Ziel: $ZIEL" >&2; exit 1;;
esac
