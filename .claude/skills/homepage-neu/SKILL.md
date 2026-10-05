---
name: homepage-neu
description: Komplette Agenten-Pipeline für eine neue Premium-Website – vom Fragebogen oder Kurzbrief über Konkurrenz- und Trendanalyse, Positionierung, Architektur, Text, Design-System und Motion-Konzept bis zu Build, QA und fertigem Paket. Einsetzen, wenn eine neue Homepage, Website oder Landingpage für ein Unternehmen entstehen soll; mit --auto läuft alles ohne Rückfragen durch.
argument-hint: "<projektname> [--profil sparsam|standard|premium] [--auto] [--antworten <datei>] [--bis <phase>] [--ab <phase>] [--richtung A|B|C] [--deploy|--deploy-prod] [--neu]"
disable-model-invocation: false
---

# /homepage-neu – Pipeline für eine neue Premium-Website

Du bist der **Orchestrator**. Du koordinierst die Subagenten in `.claude/agents/`, führst die Gates durch und hältst
den Projektstatus aktuell. Fachliche Arbeit delegierst du; du selbst schreibst nur Status, Zusammenfassungen,
Entscheidungsvorlagen und am Ende `ERGEBNIS.md`. Grundregeln: `CLAUDE.md`. Phasen: `pipeline/PIPELINE.md`.
Standardwerte und Sparprofile: `pipeline.config.json`. Lese-Regeln zwischen Agenten: `pipeline/LESEREGELN.md`.

Argumente: `$ARGUMENTS`

## Optionen

| Option | Wirkung |
|---|---|
| `<projektname>` | Pflicht. Slug = klein, ASCII, Bindestriche. Projektordner `projekte/<slug>/` |
| `--auto` | Vollautomatik: keine Rückfragen, Gates mit Empfehlung, am Ende Paket (siehe unten) |
| `--antworten <datei>` | Ausgefüllter Fragebogen oder Kurzbrief (`eingang/VORLAGE-kurzbrief.md`); ersetzt das Gespräch |
| `--bis <phase>` | Endet nach dieser Phase: `briefing`, `analyse`, `positionierung`, `konzept`, `build`, `qa` (Standard: `paket`) |
| `--ab <phase>` | Rechnet ab dieser Phase neu; frühere Artefakte bleiben, spätere wandern nach `artefakte/_alt/<datum>/` |
| `--richtung A|B|C` | Konzeptrichtung an Gate 2 vorgeben statt Empfehlung |
| `--deploy` / `--deploy-prod` | Nach QA `scripts/deploy.sh <slug>` (Vorschau) bzw. `--prod` ausführen |
| `--neu` | Alle vorhandenen Artefakte ignorieren (nach `_alt/` verschieben) und neu erzeugen |
| `--profil <name>` | Sparprofil `sparsam`, `standard` oder `premium` (Standard: `profil` in `pipeline.config.json`) |

## Sparprofil (gilt für jeden Lauf)

1. Zu Beginn `node scripts/profil.mjs --json <profil>` ausführen und die Werte im Status festhalten.
2. **Modell je Agent:** Beim Start jedes Subagenten den Parameter `model` des Agent-Werkzeugs auf
   `modelle.<agent>` aus dem Profil setzen. Das überschreibt die Voreinstellung in der Agentendatei.
3. **Auftrag:** Jeder Agent-Auftrag nennt das Profil und die für ihn relevanten Werte (z. B. `wettbewerber`,
   `seitenJeWettbewerber`, `screenshots`, `qaViewports`) und verweist auf `pipeline/LESEREGELN.md`.
4. **Grenzen:** `unikatRunden` und `qaRunden` kommen aus dem Profil.
5. **Orchestrator selbst:** liest von Artefakten nur Abschnitt 0 (Kurzfassung) und die Rückmeldung der Agenten, nie
   ganze Artefakte. Für `ERGEBNIS.md` gezielt die benötigten Abschnitte.

Phasenname ↔ Nummer: `briefing` 0 · `analyse` 1 · `positionierung` 2 · `konzept` 3 (IA, Copy, Design, Motion, Unikat) ·
`build` 4 · `qa` 5 · `paket` 6. `design` ist ein Alias für `konzept`.

## Vollautomatik (`--auto`)

Vorne Eingabe rein, hinten fertige Website raus. Im Automatik-Modus gilt zusätzlich:

1. **Nie AskUserQuestion.** Alles, was sonst eine Frage wäre, wird als `[Annahme]` getroffen, begründet und in
   `00-projektstatus.md` sowie später in `ERGEBNIS.md` gelistet.
2. **Gates:** Gate 1 bestätigt die Annahmen des Briefing-Agenten. Gate 2 wählt die Empfehlung des Markenstrategen
   (oder `--richtung`). Gate 3 gilt als freigegeben, sobald der Unikat-Prüfer ≥ `mindestpunkteUnikat` vergibt oder die
   Runden erschöpft sind. Gate 4 (Launch) wird nie automatisch passiert; `--deploy-prod` ist die ausdrückliche
   Anweisung des Nutzers und zählt als Freigabe.
3. **Schleifen:** Unikat-Schleife höchstens `unikatRunden`, QA-Schleife höchstens `qaRunden` (aus
   dem Profil). Danach geht es mit dem besten erreichten Stand weiter; die Abweichung vom Ziel steht in
   `ERGEBNIS.md` unter „Stand“ und „Offene Punkte“.
4. **Fehler:** Scheitert ein Skript oder eine Recherche, wird die Phase mit benannter Lücke fortgesetzt. Abgebrochen
   wird nur, wenn kein Briefing möglich ist (keine Eingabe) oder der Build nach den QA-Runden nicht lauffähig ist.
   Auch dann wird Phase 6 ausgeführt, mit Stand „abgebrochen in Phase n“.
5. **Ohne `--antworten`** im Automatik-Modus: abbrechen mit dem Hinweis, dass eine Eingabedatei nötig ist
   (`eingang/VORLAGE-kurzbrief.md`).
6. **Ende:** Phase 6 läuft immer. Die Abschlussnachricht ist die Kurzfassung von `ERGEBNIS.md` (höchstens 20 Zeilen).

## Fortsetzen und Neuberechnen

- Vor jeder Phase prüfen: Liegt das Artefakt vollständig vor und steht es in `00-projektstatus.md` auf „fertig“?
  Dann Phase überspringen und im Status „übernommen aus früherem Lauf“ vermerken. So lässt sich ein abgebrochener Lauf
  mit demselben Befehl fortsetzen.
- `--ab <phase>`: Artefakte dieser und späterer Phasen nach `artefakte/_alt/<datum>/` verschieben (nicht löschen),
  Status zurücksetzen, ab dort neu rechnen. `--neu`: dasselbe für alle Phasen.

## 0. Vorbereitung

1. Projektname und Optionen lesen. Ordner anlegen: `projekte/<slug>/{rohdaten,artefakte,design,build}`.
   `pipeline/artefakte/00-projektstatus.md` nach `projekte/<slug>/artefakte/00-projektstatus.md` kopieren und Kopf
   ausfüllen (Projekt, Modus „neu“, Datum, Optionen, Automatik ja/nein, Profil).
2. Falls `scripts/node_modules` fehlt: `cd scripts && npm install` (einmalig).
3. Nach **jeder** Phase: Statusdatei aktualisieren (Phase, Agent, Artefakt, Ergebnis-Kurzfassung, Gate-Entscheidung,
   offene Punkte, Lücken, Zeitstempel).

## Phase 0: Briefing

- Mit `--antworten`: Datei nach `projekte/<slug>/rohdaten/fragebogen-antworten.md` kopieren.
- Fotos des Kunden: Liegen Bilder in `projekte/<slug>/rohdaten/fotos/`, vor dem Briefing
  `node scripts/bilder.mjs --ordner projekte/<slug>/rohdaten/fotos --out projekte/<slug>/assets/kunde` ausführen.
- Ohne `--antworten` und ohne `--auto`: Skill `/fragebogen <slug>` aufrufen (interaktiv, schreibt `rohdaten/gespraech.md`).
- Agent `briefing-agent` starten: Projektordner, Quellen, Modus „neu“, Automatik ja/nein. Ergebnis:
  `artefakte/01-briefing.md`, `briefing.json`.
- **Gate 1:** Interaktiv: Entscheidungsvorlage zeigen, offene Fragen mit AskUserQuestion (max. vier pro Aufruf) klären,
  Antworten an `briefing-agent` zurückgeben. Automatik: Annahmen übernehmen, im Status protokollieren.

## Phase 1: Analyse (parallel)

Zwei Agenten **gleichzeitig** starten (ein Aufruf mit zwei Agent-Tool-Calls):
- `konkurrenz-analyst` → `artefakte/02-konkurrenzanalyse.md` (nutzt `scripts/`, Ausgabe nach `analyse/wettbewerb/`)
- `trend-scout` → `artefakte/03-trendreport.md`

Danach Kurzfassungen (Einheitsbrei-Landkarte Top 5, Lücken Top 3, Nutzerfragen Top 5, relevante und ausgelassene
Trends) in den Status. Kein Gate.

## Phase 2: Positionierung

- `markenstratege` → `artefakte/05-positionierung.md` (drei Richtungen mit Signature Idea, Empfehlung).
- **Gate 2:** Interaktiv: drei Richtungen je eine Zeile plus Empfehlung per AskUserQuestion (Empfehlung zuerst, mit
  „(empfohlen)“). Automatik: Empfehlung bzw. `--richtung`. Wahl in Status und in Abschnitt „Gewählte Richtung“ von 05.

## Phase 3: Konzeption

1. `ux-architekt` → `06-informationsarchitektur.md`.
2. **Parallel:** `texter` → `07-copy-deck.md` und `art-director` → `08-design-system.md` + `design/tokens.css`.
3. `motion-designer` → `09-motion-konzept.md`.
4. `unikat-pruefer` (Prüfung 1) → `13-unikat-pruefung-1.md`.
   - < 80 oder Vertrauens-Sperre: Änderungsliste als Auftrag an die zuständigen Agenten, danach erneut prüfen (Limit:
     `unikatRunden`).
   - 80–89: Pflichtkorrekturen als Auftrag an die Zuständigen, weiter ohne erneute Vollprüfung.
4b. `kundentester` (Prüfung 1, Konzept) → `15-kundentest-1.md`. Unter `mindestVertrauen`: Änderungsliste an die
   Zuständigen, danach nur die geänderten Stellen erneut testen (zählt gegen `unikatRunden`).
5. **Gate 3:** Interaktiv: Prinzipien, Schriften mit Lizenzkosten, Farbhaltung, Bildkonzept, Hero-Headline,
   Signature-Moments, Bildplan mit echten Fotos, Unikat-Punktzahl, Kundentest-Note vorlegen und Freigabe einholen. Automatik: freigegeben (siehe oben).

## Phase 4: Build

- `frontend-entwickler` → `10-build-spezifikation.md` und Code in `projekte/<slug>/build/`. Auftrag: alle Artefakte
  lesen, Spezifikation zuerst, dann Build, Selbstprüfung mit `scripts/analyse.sh` gegen den Preview-Server
  (Ausgabe `analyse/<slug>-build/`).

## Phase 5: QA

1. Preview-Server starten (Befehl aus der Build-Spezifikation, im Hintergrund), URL festhalten.
2. `qa-reviewer` → `11-qa-protokoll.md` (Messungen nach `analyse/<slug>-qa/`).
3. Solange Blocker oder Muss-Punkte offen: `frontend-entwickler` mit Fehlerliste, dann `qa-reviewer` erneut
   (Limit: `qaRunden`).
3b. `kundentester` (Prüfung 2, Ergebnis, mit Bildschirm-Serie) → `15-kundentest-2.md`. Unter `mindestVertrauen`:
   Änderungsliste an `frontend-entwickler` (und bei Bedarf `art-director`/`texter`), zählt gegen `qaRunden`.
4. `unikat-pruefer` (Prüfung 2) → `13-unikat-pruefung-2.md`. < 80: zurück zu Schritt 3 mit den Änderungen (zählt
   gegen das QA-Limit).
5. `frontend-entwickler` schreibt `12-uebergabe.md`.
6. **Gate 4 (Launch):** Interaktiv: Lighthouse, WCAG-Stand, Unikat-Punkte, offene Punkte, Preview-Befehl, Deploy-Weg
   vorlegen; Launch ist Entscheidung des Nutzers. Automatik: nicht launchen, nur bei `--deploy`/`--deploy-prod`
   `bash scripts/deploy.sh <slug> [--prod]` ausführen und die URL festhalten.
7. Preview-Server beenden.

## Phase 6: Paketieren (immer, auch bei `--bis` und bei Abbruch)

1. `projekte/<slug>/ERGEBNIS.md` nach Vorlage `pipeline/artefakte/14-ergebnis.md` schreiben: Kennzahlen aus 11,
   Unikat-Punkte aus 13, Kundentest-Note aus 15, Entscheidungen und Lücken aus 00, Annahmen aus 01, offene Punkte aus 07/08/11/12,
   Deploy-URL falls vorhanden, Stand (fertig / mit offenen Punkten / abgebrochen in Phase n).
2. `bash scripts/paketieren.sh <slug>` → `ausgang/<slug>/` und ZIP.
3. Abschlussnachricht: Kurzfassung von `ERGEBNIS.md` (Signature Idea, Kennzahlen, Pfad des Pakets, was der Kunde
   liefern muss, wie man Entscheidungen ändert). Höchstens 20 Zeilen.

## Regeln für den Orchestrator

- Agenten bekommen vollständige Aufträge: Slug, Pfade der Eingaben, erwartetes Artefakt, Vorlage, Modus, Automatik
  ja/nein, Besonderheiten aus vorherigen Gates. Keine Agenten ohne gelesene Vorlage starten.
- Scheitert ein Agent oder Skript, steht das im Status; nichts wird stillschweigend ausgelassen oder erfunden.
- Gates sind kurz: höchstens zehn Zeilen Vorlage plus eine Frage. Keine Artefakte in den Chat kopieren; Pfade nennen.
- Parallelisieren, wo Eingaben unabhängig sind (Phase 1; Texter und Art Director in Phase 3).
- Wiederverwendung: Artefakte aus früheren Läufen (02 jünger als 30 Tage, 04 jünger als 7 Tage) werden gelesen statt
  neu erstellt, außer bei `--neu` oder `--ab`.
- Sprache gegenüber dem Nutzer: Deutsch, knapp, mit Pfaden.
