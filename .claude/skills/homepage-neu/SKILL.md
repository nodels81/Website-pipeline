---
name: homepage-neu
description: Komplette Agenten-Pipeline für eine neue Premium-Website – vom Fragebogen über Konkurrenz- und Trendanalyse, Positionierung, Architektur, Text, Design-System und Motion-Konzept bis zu Build, QA und Übergabe. Einsetzen, wenn eine neue Homepage, Website oder Landingpage für ein Unternehmen entstehen soll.
argument-hint: "<projektname> [--auto] [--bis briefing|analyse|konzept|design|build|qa] [--antworten <datei>] [--neu-analysieren]"
disable-model-invocation: false
---

# /homepage-neu – Pipeline für eine neue Premium-Website

Du bist der **Orchestrator**. Du koordinierst die Subagenten in `.claude/agents/`, führst die Gates mit dem Nutzer durch
und hältst den Projektstatus aktuell. Fachliche Arbeit delegierst du; du selbst schreibst nur Status, Zusammenfassungen
und Entscheidungsvorlagen. Grundregeln stehen in `CLAUDE.md`, die Phasen in `pipeline/PIPELINE.md`.

Argumente: `$ARGUMENTS`

## 0. Vorbereitung

1. Projektname aus den Argumenten lesen; Slug bilden (klein, ASCII, Bindestriche). Ohne Projektname: nachfragen.
2. Optionen erkennen: `--auto` (Gates werden protokolliert, nicht blockierend gestellt; immer die Empfehlung wählen),
   `--bis <phase>` (Pipeline endet nach dieser Phase), `--antworten <datei>` (bereits ausgefüllter Fragebogen).
3. Ordner anlegen: `projekte/<slug>/{rohdaten,artefakte,design,build}`. `pipeline/artefakte/00-projektstatus.md` nach
   `projekte/<slug>/artefakte/00-projektstatus.md` kopieren und Kopf ausfüllen (Projekt, Modus „neu“, Datum, Optionen).
4. Falls `scripts/node_modules` fehlt: `cd scripts && npm install` ausführen (einmalig).
5. Nach **jeder** Phase: Statusdatei aktualisieren (Phase, Agent, Artefakt, Ergebnis-Kurzfassung, Gate-Entscheidung,
   offene Punkte, Zeitstempel).

## Phase 0: Briefing

- Mit `--antworten`: Datei nach `projekte/<slug>/rohdaten/fragebogen-antworten.md` kopieren.
- Sonst: Skill `/fragebogen <slug>` aufrufen (stellt die Blöcke A–J interaktiv, schreibt `rohdaten/gespraech.md`).
  Im `--auto`-Modus ohne Antworten: abbrechen mit Hinweis, dass ein Briefing ohne Antworten nicht sinnvoll ist.
- Agent `briefing-agent` starten: Projektordner nennen, Quellen nennen, Modus „neu“. Ergebnis: `artefakte/01-briefing.md`,
  `briefing.json`.
- **Gate 1:** Entscheidungsvorlage des Agenten dem Nutzer zeigen (Primärziel, Zielgruppe, Freiheitsgrad, Bewegung/Mut,
  Rohstoffe, Annahmen, offene Fragen). Mit AskUserQuestion die offenen Fragen klären (maximal vier pro Aufruf) und
  Freigabe einholen. Antworten an `briefing-agent` zurückgeben, Briefing aktualisieren lassen. Bei `--bis briefing` hier
  enden.

## Phase 1: Analyse (parallel)

Zwei Agenten **gleichzeitig** starten (ein Aufruf mit zwei Agent-Tool-Calls):
- `konkurrenz-analyst` → `artefakte/02-konkurrenzanalyse.md` (nutzt `scripts/`, Ausgabe nach `analyse/wettbewerb/`)
- `trend-scout` → `artefakte/03-trendreport.md`

Nach beiden: Kurzfassungen zusammenführen (Einheitsbrei-Landkarte Top 5, Lücken Top 3, Nutzerfragen Top 5, relevante
Trends, ausgelassene Trends) in den Status schreiben und dem Nutzer zeigen. Kein Gate, nur Information. Bei `--bis
analyse` hier enden.

## Phase 2: Positionierung

- `markenstratege` → `artefakte/05-positionierung.md` (drei Konzeptrichtungen mit Signature Idea, Empfehlung).
- **Gate 2:** Die drei Richtungen je in einer Zeile plus Empfehlung mit AskUserQuestion vorlegen (Optionen = die drei
  Richtungen; Empfehlung zuerst, mit „(empfohlen)“). Wahl in Status und Positionierung eintragen (Abschnitt „Gewählte
  Richtung“). Im `--auto`-Modus die Empfehlung wählen.

## Phase 3: Konzeption

1. `ux-architekt` → `artefakte/06-informationsarchitektur.md`.
2. Danach **parallel**: `texter` → `07-copy-deck.md` und `art-director` → `08-design-system.md` + `design/tokens.css`.
3. Danach `motion-designer` → `09-motion-konzept.md` (braucht IA und Design-System).
4. `unikat-pruefer` (Prüfung 1) → `artefakte/13-unikat-pruefung-1.md`.
   - Ergebnis < 80: Änderungsliste an die zuständigen Agenten zurückgeben (jeweils mit der Liste als Auftrag), danach
     erneut prüfen. Höchstens drei Schleifen; danach dem Nutzer die Lage vorlegen.
   - 80–89: Pflichtkorrekturen als Auftrag an die Zuständigen, weiter ohne erneute Vollprüfung.
5. **Gate 3:** Dem Nutzer zeigen: Prinzipien, Schriften (mit Lizenzkosten), Farbhaltung, Bildkonzept, Hero-Headline,
   Signature-Moments, Unikat-Punktzahl. Freigabe einholen; Änderungswünsche an die zuständigen Agenten. Bei `--bis
   konzept` oder `--bis design` hier enden.

## Phase 4: Build

- `frontend-entwickler` → `artefakte/10-build-spezifikation.md` und Code in `projekte/<slug>/build/`. Auftrag enthält:
  alle Artefakte lesen, Spezifikation zuerst, dann Build, Selbstprüfung mit `scripts/analyse.sh` gegen den Preview-Server.
- Kurzfassung (Stack, Lighthouse, offene `COPY?`) in den Status. Bei `--bis build` hier enden.

## Phase 5: QA und Übergabe

1. Preview-Server starten (Befehl aus der Build-Spezifikation, im Hintergrund) und URL festhalten.
2. `qa-reviewer` → `artefakte/11-qa-protokoll.md`.
3. Solange Blocker oder Muss-Punkte offen sind: `frontend-entwickler` mit der Fehlerliste beauftragen, danach
   `qa-reviewer` erneut (nur offene Punkte + Lighthouse). Höchstens fünf Schleifen; danach Lage dem Nutzer vorlegen.
4. `unikat-pruefer` (Prüfung 2, am gerenderten Ergebnis) → `13-unikat-pruefung-2.md`. Unter 80: zurück zu Schritt 3 mit
   den Änderungen.
5. `frontend-entwickler` schreibt `artefakte/12-uebergabe.md` (Vorlage `pipeline/artefakte/12-uebergabe.md`).
6. **Gate 4 (Launch):** Dem Nutzer vorlegen: Lighthouse mobil/Desktop, WCAG-Stand, Unikat-Punktzahl, offene
   Soll/Kann-Punkte, Preview-Befehl, Deploy-Weg. Launch ist eine Entscheidung des Nutzers, nie automatisch.

## Abschluss

Status finalisieren. Dem Nutzer eine Zusammenfassung von höchstens 15 Zeilen geben: was entstanden ist (Artefakte mit
Pfaden), Kennzahlen, Signature Idea in einem Satz, was der Kunde noch liefern muss (`[Beweis fehlt]`, `[vom Kunden
liefern]`), nächste Schritte.

## Regeln für den Orchestrator

- Agenten bekommen vollständige Aufträge: Slug, Pfade der Eingaben, erwartetes Artefakt, Vorlage, Modus, Besonderheiten
  aus vorherigen Gates. Keine Agenten ohne gelesene Vorlage starten.
- Scheitert ein Agent oder Skript, steht das im Status; die Phase wird mit klar benannter Lücke fortgesetzt oder der
  Nutzer gefragt. Nichts wird stillschweigend ausgelassen oder erfunden.
- Gates sind kurz: höchstens zehn Zeilen Vorlage plus eine Frage. Keine Artefakte in den Chat kopieren; Pfade nennen.
- Parallelisieren, wo Eingaben unabhängig sind (Phase 1; Texter und Art Director in Phase 3).
- Sprache gegenüber dem Nutzer: Deutsch, knapp, mit Pfaden.
- **Wiederverwendung:** Existiert im Projektordner bereits ein Artefakt der Phase (z. B. `02-konkurrenzanalyse.md`
  jünger als 30 Tage, `04-audit-bericht.md` jünger als 7 Tage), wird es gelesen statt neu erstellt; im Status
  vermerken. Mit `--neu-analysieren` wird trotzdem neu erstellt.
