---
name: homepage-verbessern
description: Bestehende Website nur anhand ihrer URL analysieren (Inhalt, UX, Gestaltung, Technik, SEO, Barrierefreiheit, Einheitsbrei-Grad), Briefing daraus ableiten, höchstens acht Rückfragen stellen und dann die komplette Premium-Pipeline als Neubau durchlaufen – die alte Seite wird nur analysiert, nie kopiert. Einsetzen, wenn eine vorhandene Homepage komplett neu gemacht werden soll und eine URL vorliegt; mit --auto ohne Rückfragen.
argument-hint: "<url> [--profil sparsam|standard|premium] [--auto] [--antworten <datei>] [--slug <slug>] [--bis <phase>] [--ab <phase>] [--richtung A|B|C] [--deploy|--deploy-prod] [--nur-audit] [--neu]"
disable-model-invocation: false
---

# /homepage-verbessern – Neubau aus einer URL

Du bist der **Orchestrator** (Regeln in `CLAUDE.md`, Phasen in `pipeline/PIPELINE.md`, Limits in
`pipeline.config.json`). Unterschied zu `/homepage-neu`: Das Briefing entsteht aus der **Analyse der bestehenden
Website** plus höchstens acht Rückfragen (oder deren Antworten aus `--antworten`). Die alte Website liefert Fakten,
Stärken und Messwerte. Konzept, Text, Design, Bewegung und Code entstehen **vollständig neu**; nichts wird übernommen,
was nicht durch `texter`, `art-director` und `ux-architekt` begründet neu entschieden wurde.

Argumente: `$ARGUMENTS`

## Optionen

Wie in `/homepage-neu` (`--profil`, `--auto`, `--bis`, `--ab`, `--richtung`, `--deploy`, `--deploy-prod`, `--neu`), zusätzlich.
Der Abschnitt „Sparprofil“ aus `/homepage-neu` gilt hier genauso (Modell je Agent, Lese-Regeln, Grenzen aus dem Profil):

| Option | Wirkung |
|---|---|
| `<url>` | Pflicht. Wird normalisiert (`https://`). Slug aus der Domain ohne `www.`, falls `--slug` fehlt |
| `--slug <slug>` | Projektname vorgeben (z. B. Name der Eingabedatei) |
| `--antworten <datei>` | Vorab-Antworten zum Kurzfragebogen (`eingang/VORLAGE-url.md`); ersetzt die Rückfragen |
| `--nur-audit` | Entspricht `--bis audit` |

Phasenname ↔ Nummer: `audit` 0a · `briefing` 0b · `analyse` 1 · `positionierung` 2 · `konzept` 3 · `build` 4 · `qa` 5 ·
`paket` 6.

## Vollautomatik (`--auto`), Fortsetzen, Neuberechnen

Dieselben Regeln wie in `/homepage-neu` (keine AskUserQuestion, Gates mit Empfehlung, Rundenlimits aus
dem Sparprofil, Phase 6 immer, Fortsetzen anhand vorhandener Artefakte, `--ab`/`--neu` verschieben nach
`_alt/`). Rückfragen des Kurzfragebogens werden im Automatik-Modus aus `--antworten` gelesen; fehlende Antworten
ersetzt der `briefing-agent` durch begründete Annahmen aus dem Audit und den Standardwerten.

## 0. Vorbereitung

1. URL normalisieren, Slug bestimmen, Optionen lesen. Ordner anlegen:
   `projekte/<slug>/{rohdaten,artefakte,design,build}`, Statusdatei aus `pipeline/artefakte/00-projektstatus.md`
   (Modus „verbessern“, URL, Datum, Optionen, Automatik ja/nein).
2. `scripts/node_modules` prüfen, sonst `cd scripts && npm install`.

## Phase 0a: Ist-Analyse

- Agent `website-auditor` mit URL, Projektordner und Profil starten (`scripts/analyse.sh --profil <profil>`, Ausgabe `analyse/<slug>/`) →
  `artefakte/04-audit-bericht.md` inklusive „Abgeleitetes Briefing-Material“ und „Was bleibt“.
- Kurzfassung in den Status. Bei `--bis audit` / `--nur-audit`: Phase 6 ausführen (Paket enthält dann nur Audit) und
  enden.

## Phase 0b: Rückfragen und Briefing

- Mit `--antworten`: Datei nach `rohdaten/kurzfragebogen-antworten.md` kopieren.
- Ohne `--antworten` und ohne `--auto`: `fragebogen/fragebogen-kurz.md` lesen und die acht Fragen in **zwei
  AskUserQuestion-Aufrufen** (je vier) stellen, mit Antwortoptionen aus dem Audit (vermutete Zielgruppe, Stoßrichtung)
  plus „Anders“. Antworten nach `rohdaten/kurzfragebogen-antworten.md`.
- Ohne `--antworten` mit `--auto`: Datei mit „nicht gefragt (Automatik)“ anlegen.
- `briefing-agent` (Modus „verbessern“, Quellen: Audit + Kurzfragebogen-Antworten) → `01-briefing.md`, `briefing.json`.
- **Gate 1** wie in `/homepage-neu`.

## Phase 1: Analyse (parallel)

- `konkurrenz-analyst` → `02-konkurrenzanalyse.md`. Zusatz: die bestehende Website als „Ausgangspunkt“ in die
  Vergleichsmatrix aufnehmen (Daten aus `analyse/<slug>/`), damit sichtbar wird, wo sie heute im Einheitsbrei steht.
- `trend-scout` → `03-trendreport.md`. Zusatz: Welche Nutzerfragen beantwortet die bestehende Seite heute nicht?

## Phase 2: Positionierung

- `markenstratege` → `05-positionierung.md`. Zusatz: Stärken aus „Was bleibt“ in allen drei Richtungen bewahren oder
  begründet aufgeben. **Gate 2** wie in `/homepage-neu`.

## Phase 3: Konzeption

Wie in `/homepage-neu`. Zusätze: `ux-architekt` erstellt die Weiterleitungstabelle alte → neue URLs aus `crawl.json`
des Audits und sichert den SEO-Bestand; `art-director` erhält `analyse/<slug>/tokens.md` als Ist-Zustand und
begründet in der Begründungstabelle, was vom Bestand bleibt und warum; `texter` übernimmt keine Alt-Texte ungeprüft.
**Gate 3** wie in `/homepage-neu`.

## Phase 4: Build

Wie in `/homepage-neu`. Zusatz: 301-Weiterleitungen aus der IA implementieren; Formulare und Integrationen aus dem
Bestand laut Briefing neu umsetzen.

## Phase 5: QA

Wie in `/homepage-neu`. Zusatz für `12-uebergabe.md`: **Vorher-Nachher-Tabelle** (Lighthouse mobil/Desktop, LCP, CLS,
Transfer, Einheitsbrei-Index, Unikat-Punktzahl, beantwortete Nutzerfragen) aus `analyse/<slug>/` (vorher) und
`analyse/<slug>-qa/` (nachher), sowie Launch-Plan mit DNS-Umstellung, Weiterleitungen und Search-Console-Schritten.

## Phase 6: Paketieren

Wie in `/homepage-neu`; `ERGEBNIS.md` enthält zusätzlich die Vorher-Nachher-Tabelle.

## Regeln

- Keine Inhalte der bestehenden Seite ungeprüft übernehmen. Was bleibt, bleibt begründet.
- Der Audit nennt Stärken zuerst, dann Probleme.
- Alle übrigen Orchestrator-Regeln aus `/homepage-neu` gelten.
