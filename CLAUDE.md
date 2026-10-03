# Premium-Homepage-Pipeline

Dieses Repository ist eine **Agenten-Pipeline für hochwertige, exklusive Websites**. Sie wird in Claude Code
ausgeführt: Skills orchestrieren spezialisierte Subagenten, die nacheinander Briefing, Konkurrenz- und Trendanalyse,
Positionierung, UX-Architektur, Text, Design-System, Motion-Konzept, Umsetzung, Qualitätsprüfung und Paketierung
liefern. Jede Website entsteht von null: keine Templates, keine Themes, keine übernommenen Bestandsseiten.

## Vollautomatik: vorne rein, hinten raus

```bash
bash run.sh eingang/<projekt>.md     # Kurzbrief oder Fragebogen → fertige Website in ausgang/<projekt>/
bash run.sh https://beispiel.de      # Neubau aus einer URL (alte Seite wird nur analysiert)
bash run.sh --alle                   # alles in eingang/, was noch kein Ergebnis hat
```

`run.sh` startet Claude Code headless mit `--auto`. Dann gibt es keine Rückfragen: Gates werden mit der Empfehlung
passiert, Lücken werden zu gekennzeichneten Annahmen, Schleifen haben Limits (`pipeline.config.json`), und am Ende
liegt immer ein Paket in `ausgang/<slug>/` (Build, Quellcode, Dokumentation, Vorschau, `ERGEBNIS.md`, ZIP).

Interaktive Einstiege in Claude Code:

| Befehl | Zweck |
|---|---|
| `/homepage-neu <projektname>` | Komplette Pipeline für eine neue Website (startet mit dem Fragebogen) |
| `/homepage-verbessern <url>` | Bestehende Website per Link analysieren und komplett neu bauen |
| `/fragebogen` | Nur den Fragebogen interaktiv durchführen und ein Briefing erzeugen |
| `/konkurrenzanalyse <branche> <region> [urls…]` | Nur Wettbewerber und Nachfrage analysieren |
| `/audit <url>` | Nur die technische und gestalterische Ist-Analyse einer URL |

Phasen, Gates und Artefakte: `pipeline/PIPELINE.md`. Phasennamen für `--bis`/`--ab`: `briefing`, `analyse`,
`positionierung`, `konzept`, `build`, `qa`, `paket` (Modus URL zusätzlich `audit`).

## Grundhaltung: kein Einheitsbrei

Jede Website aus dieser Pipeline muss eine **eigene, begründete Formsprache** haben. Die Checkliste
`checklisten/anti-einheitsbrei.md` ist verbindlich. Verboten sind insbesondere: Standard-Hero mit Farbverlauf-Blob,
Drei-Spalten-Icon-Features ohne Anlass, Inter/Roboto als Headline-Schrift ohne Begründung, lila-blaue Verläufe,
Stockfotos mit Handschlag, Floskeln wie „Willkommen auf unserer Website“ oder „Wir sind ein junges, dynamisches Team“.
Der Agent `unikat-pruefer` lehnt Entwürfe unter 80 von 100 Punkten ab.

## Arbeitsweise für den Orchestrator (Hauptsession)

1. **Projektordner anlegen:** `projekte/<slug>/` mit `rohdaten/`, `artefakte/`, `design/`, `build/`. Jede Phase schreibt
   genau ein Artefakt (Vorlagen in `pipeline/artefakte/`). Nachfolgende Agenten lesen die Artefakte der Vorphasen.
2. **Agenten delegieren, nicht selbst machen.** Die Hauptsession koordiniert, fasst zusammen, entscheidet an Gates und
   schreibt am Ende `ERGEBNIS.md`. Fachliche Arbeit erledigen die Subagenten in `.claude/agents/`. Unabhängige Agenten
   (Konkurrenz-Analyst und Trend-Scout; Texter und Art Director) parallel starten.
3. **Gates einhalten.** Nach Briefing, nach Positionierung, nach Design-System und vor Launch wird dem Nutzer eine kurze
   Entscheidungsvorlage gezeigt. Mit `--auto` werden die Gates protokolliert und mit der Empfehlung beantwortet; Gate 4
   (Launch) wird nie automatisch passiert, `--deploy-prod` ist die ausdrückliche Anweisung dafür.
4. **Recherche ist Pflicht, nicht Option.** Konkurrenz und Nachfrage werden live mit WebSearch/WebFetch und den
   Skripten in `scripts/` untersucht. Keine erfundenen Wettbewerber, keine erfundenen Zahlen. Was nicht verifizierbar ist,
   wird als Annahme gekennzeichnet.
5. **Fortsetzen statt wiederholen.** Vorhandene, fertige Artefakte werden übernommen (Status prüfen). Neu gerechnet wird
   nur mit `--ab <phase>` oder `--neu`; verdrängte Artefakte wandern nach `artefakte/_alt/<datum>/`.
6. **Sprache:** Artefakte und Kundenkommunikation auf Deutsch (Sie-Form gegenüber Kunden, es sei denn das Briefing sagt
   etwas anderes). Code, Dateinamen und Kommentare im Build auf Englisch.
7. **Ehrlichkeit über Ergebnisse.** Wenn ein Skript fehlschlägt oder eine Quelle nicht erreichbar ist, steht das im
   Artefakt, im Status und in `ERGEBNIS.md`. Keine stillen Lücken.

## Technische Werkzeuge

- `scripts/analyse.sh <url>` führt Screenshots, Crawl, Design-Token-Extraktion und Lighthouse in einem Lauf aus.
  Einzelskripte: `screenshot.mjs` (auch `--sizes`, `--dark`, `--reduced-motion`), `crawl.mjs`, `tokens.mjs`, `audit.sh`.
  Ausgabe nach `analyse/<slug>/`.
- `scripts/paketieren.sh <slug>` schnürt `ausgang/<slug>/` und ZIP; `scripts/deploy.sh <slug> [--prod]` veröffentlicht
  auf dem in `pipeline.config.json` konfigurierten Ziel (Zugangsdaten nur über Umgebungsvariablen).
- Vor dem ersten Lauf: `cd scripts && npm install`. Lighthouse wird bei Bedarf über `npx` geladen.
- Stack-Empfehlungen: `referenzen/tech-stack.md`. Standard: Astro + Tailwind + GSAP (ScrollTrigger) + Lenis, optional
  Three.js/Spline für 3D. Abweichungen werden in `10-build-spezifikation.md` begründet.

## Qualitätsmaßstab (verbindlich für `qa-reviewer`)

- Lighthouse mobil: Performance ≥ 90, Barrierefreiheit ≥ 95, SEO ≥ 95. LCP ≤ 2,0 s, CLS ≤ 0,05, INP ≤ 150 ms.
- WCAG 2.2 AA (BFSG-konform, siehe `checklisten/barrierefreiheit-motion.md`). `prefers-reduced-motion` immer respektiert.
- Jede Animation hat einen Zweck (Orientierung, Hierarchie, Feedback, Erzählung). Dekoration ohne Funktion wird gestrichen.
- Responsiv von 320 px bis 1920 px ohne horizontales Scrollen, getestet in allen Viewports.

## Was der Orchestrator nie tut

- Keine Wettbewerber oder Trends erfinden, wenn Recherche fehlschlägt. Stattdessen Lücke benennen.
- Keine Templates, Themes oder Bestandsseiten als Basis verwenden.
- Kein Build ohne vorher freigegebenes (oder im Automatik-Modus geprüftes) Design-System und Motion-Konzept.
- Keine Inhalte des Kunden (Texte, Bilder, Daten) an externe Dienste schicken, die nicht im Briefing freigegeben sind.
- Kein Produktions-Deploy ohne `--deploy-prod` oder ausdrückliche Freigabe an Gate 4.
