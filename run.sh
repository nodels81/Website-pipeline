#!/usr/bin/env bash
# run.sh — Vollautomatische Pipeline: vorne Eingabe rein, hinten fertige Website raus.
#
# Nutzung:
#   bash run.sh eingang/<projekt>.md [Optionen]    Neue Website aus Kurzbrief oder Fragebogen
#                                                  (enthält die Datei "URL: https://…", wird die Seite neu gemacht)
#   bash run.sh https://beispiel.de [Optionen]     Redesign direkt aus einer URL
#   bash run.sh --alle [Optionen]                  Alle Dateien in eingang/, die noch kein Ergebnis haben
#
# Optionen:
#   --bis <phase>    audit|briefing|analyse|konzept|design|build|qa  (Standard: komplett bis zum Paket)
#   --ab <phase>     ab dieser Phase neu rechnen, frühere Artefakte behalten
#   --richtung A|B|C Konzeptrichtung vorgeben statt Empfehlung (Gate 2)
#   --deploy         nach QA als Vorschau veröffentlichen (scripts/deploy.sh)
#   --deploy-prod    nach QA in Produktion veröffentlichen
#   --neu            vorhandene Artefakte des Projekts ignorieren, alles neu erzeugen
#   --voll           Claude ohne Berechtigungsabfragen laufen lassen (für CI / unbeaufsichtigt)
#   --profil <name>  Sparprofil: sparsam | standard | premium (Standard aus pipeline.config.json)
#   --modell <id>    Modell der Hauptsession (Subagenten bekommen ihr Modell aus dem Profil)
#   --trocken        nur anzeigen, was ausgeführt würde
#
# Ergebnis: ausgang/<slug>/ERGEBNIS.md, website/, quellcode/, dokumentation/, vorschau/, <slug>.zip
# Windows:  .\run.ps1 ist die PowerShell-Variante mit denselben Optionen (-Bis, -Ab, -Richtung, -Deploy, -Voll, -Trocken).
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$(pwd)"

usage () { sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
[[ $# -eq 0 ]] && usage 1

PROFIL=""; EINGABE=""; ALLE=0; BIS=""; AB=""; RICHTUNG=""; DEPLOY=""; NEU=0; VOLL=0; MODELL=""; TROCKEN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --alle) ALLE=1; shift;;
    --bis) BIS="$2"; shift 2;;
    --ab) AB="$2"; shift 2;;
    --richtung) RICHTUNG="$2"; shift 2;;
    --deploy) DEPLOY="--deploy"; shift;;
    --deploy-prod) DEPLOY="--deploy-prod"; shift;;
    --neu) NEU=1; shift;;
    --voll) VOLL=1; shift;;
    --modell|--model) MODELL="$2"; shift 2;;
    --profil) PROFIL="$2"; shift 2;;
    --trocken|--dry-run) TROCKEN=1; shift;;
    -h|--help) usage 0;;
    --*) echo "Unbekannte Option: $1" >&2; usage 1;;
    *) EINGABE="$1"; shift;;
  esac
done

# Voraussetzungen
if ! command -v claude >/dev/null; then
  echo "Claude Code CLI fehlt. Installation: npm install -g @anthropic-ai/claude-code" >&2; exit 1
fi
command -v node >/dev/null || { echo "Node.js >= 18 fehlt." >&2; exit 1; }
if [[ ! -d scripts/node_modules/playwright ]]; then
  echo "→ Installiere Analyse-Skripte (einmalig) …"; (cd scripts && npm install --no-audit --no-fund >/dev/null)
fi

if [[ "$VOLL" == 0 ]]; then
  echo "Hinweis: Die Freigaben aus .claude/settings.json gelten erst, wenn Claude Code diesem Ordner vertraut (einmal 'claude' hier starten und den Dialog bestätigen). Unbeaufsichtigt: --voll."
fi

slugify () { echo "$1" | sed -E 's#^https?://##; s#^www\.##; s#/.*$##' | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'; }
is_url () { [[ "$1" =~ ^https?:// || "$1" =~ ^[a-z0-9.-]+\.[a-z]{2,}(/.*)?$ ]]; }

run_one () {
  local eingabe="$1" modus url slug prompt log start ende
  if is_url "$eingabe"; then
    modus="verbessern"; url="$eingabe"; [[ "$url" =~ ^https?:// ]] || url="https://$url"; slug="$(slugify "$url")"
    prompt="/homepage-verbessern $url --auto"
  else
    [[ -f "$eingabe" ]] || { echo "Eingabedatei nicht gefunden: $eingabe" >&2; return 1; }
    slug="$(slugify "$(basename "${eingabe%.*}")")"
    url="$( { grep -iE '^\s*\**URL\**:?\s*https?://' "$eingabe" || true; } | head -1 | sed -E 's/^[^h]*(https?:\/\/[^ )]+).*/\1/')"
    if [[ -n "$url" ]]; then modus="verbessern"; prompt="/homepage-verbessern $url --auto --antworten $eingabe --slug $slug"
    else modus="neu"; prompt="/homepage-neu $slug --auto --antworten $eingabe"; fi
  fi
  [[ -n "$BIS" ]] && prompt="$prompt --bis $BIS"
  [[ -n "$AB" ]] && prompt="$prompt --ab $AB"
  [[ -n "$RICHTUNG" ]] && prompt="$prompt --richtung $RICHTUNG"
  [[ -n "$DEPLOY" ]] && prompt="$prompt $DEPLOY"
  [[ "$NEU" == 1 ]] && prompt="$prompt --neu"
  [[ -n "$PROFIL" ]] && prompt="$prompt --profil $PROFIL"

  local args=(-p "$prompt")
  if [[ "$VOLL" == 1 ]]; then args+=(--permission-mode bypassPermissions); else args+=(--permission-mode acceptEdits); fi
  [[ -n "$MODELL" ]] && args+=(--model "$MODELL")

  mkdir -p "ausgang/$slug"
  log="ausgang/$slug/pipeline.log"
  echo "══════════════════════════════════════════════════════════"
  echo " Projekt: $slug · Modus: $modus · Eingabe: $eingabe"
  echo " Befehl:  claude ${args[*]}"
  echo " Log:     $log"
  echo "══════════════════════════════════════════════════════════"
  [[ "$TROCKEN" == 1 ]] && return 0

  start=$(date +%s)
  echo "Start: $(date -Iseconds)" > "$log"
  set +e
  claude "${args[@]}" 2>&1 | tee -a "$log"
  local rc=${PIPESTATUS[0]}
  set -e
  ende=$(date +%s)
  echo "Ende: $(date -Iseconds) · Dauer: $(( (ende-start)/60 )) min · Exit: $rc" | tee -a "$log"

  # Paket sicherstellen (falls der Orchestrator vor dem Paketieren endete)
  if [[ ! -f "ausgang/$slug/ERGEBNIS.md" && -d "projekte/$slug" ]]; then
    bash scripts/paketieren.sh "$slug" >> "$log" 2>&1 || true
  fi
  echo
  if [[ -f "ausgang/$slug/ERGEBNIS.md" ]]; then
    echo "✓ Fertig: ausgang/$slug/"; sed -n '1,25p' "ausgang/$slug/ERGEBNIS.md"
  else
    echo "✗ Kein ERGEBNIS.md. Status: projekte/$slug/artefakte/00-projektstatus.md · Log: $log"
    return 1
  fi
  return $rc
}

if [[ "$ALLE" == 1 ]]; then
  found=0; fails=0
  for f in eingang/*.md; do
    [[ -e "$f" ]] || continue
    case "$(basename "$f")" in VORLAGE-*|README.md) continue;; esac
    slug="$(slugify "$(basename "${f%.*}")")"
    if [[ -f "ausgang/$slug/ERGEBNIS.md" && "$NEU" == 0 ]]; then echo "– $f: Ergebnis vorhanden, übersprungen (--neu erzwingt)"; continue; fi
    found=1; run_one "$f" || fails=$((fails+1))
  done
  [[ "$found" == 0 ]] && echo "Nichts zu tun: keine neuen Dateien in eingang/."
  exit $fails
else
  [[ -n "$EINGABE" ]] || usage 1
  run_one "$EINGABE"
fi
