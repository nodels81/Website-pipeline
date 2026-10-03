# Premium-Homepage-Pipeline

Dieses Repository ist eine **Agenten-Pipeline für hochwertige, exklusive Websites**. Sie wird in Claude Code
ausgeführt: Skills orchestrieren spezialisierte Subagenten, die nacheinander Briefing, Konkurrenz- und Trendanalyse,
Positionierung, UX-Architektur, Text, Design-System, Motion-Konzept, Umsetzung und Qualitätsprüfung liefern.

Zwei Einstiege:

| Befehl | Zweck |
|---|---|
| `/homepage-neu <projektname>` | Komplette Pipeline für eine neue Website (startet mit dem Fragebogen) |
| `/homepage-verbessern <url>` | Bestehende Website nur per Link analysieren und als Premium-Redesign neu konzipieren |
| `/fragebogen` | Nur den Fragebogen interaktiv durchführen und ein Briefing erzeugen |
| `/konkurrenzanalyse <branche> <region> [urls…]` | Nur Wettbewerber und Nachfrage analysieren |
| `/audit <url>` | Nur die technische und gestalterische Ist-Analyse einer URL |

Die vollständige Beschreibung der Phasen, Gates und Artefakte steht in `pipeline/PIPELINE.md`.

## Grundhaltung: kein Einheitsbrei

Jede Website aus dieser Pipeline muss eine **eigene, begründete Formsprache** haben. Die Checkliste
`checklisten/anti-einheitsbrei.md` ist verbindlich. Verboten sind insbesondere: Standard-Hero mit Farbverlauf-Blob,
Drei-Spalten-Icon-Features ohne Anlass, Inter/Roboto als Headline-Schrift ohne Begründung, lila-blaue Verläufe,
Stockfotos mit Handschlag, Floskeln wie „Willkommen auf unserer Website“ oder „Wir sind ein junges, dynamisches Team“.
Der Agent `unikat-pruefer` lehnt Entwürfe ab, die diese Muster zeigen.

## Arbeitsweise für den Orchestrator (Hauptsession)

1. **Projektordner anlegen:** `projekte/<slug>/` mit Unterordner `artefakte/`. Jede Phase schreibt genau ein Artefakt
   (Vorlagen in `pipeline/artefakte/`). Nachfolgende Agenten lesen die Artefakte der Vorphasen aus dem Projektordner.
2. **Agenten delegieren, nicht selbst machen.** Die Hauptsession koordiniert, fasst zusammen und entscheidet an Gates.
   Fachliche Arbeit erledigen die Subagenten in `.claude/agents/`. Unabhängige Agenten (z. B. Konkurrenz-Analyst und
   Trend-Scout) parallel starten.
3. **Gates einhalten.** Nach Briefing, nach Positionierung, nach Design-System und vor Launch wird dem Nutzer eine kurze
   Entscheidungsvorlage gezeigt. Bei „Weiter ohne Rückfrage“-Modus (`--auto`) werden die Gates protokolliert, aber nicht
   blockierend gestellt.
4. **Recherche ist Pflicht, nicht Option.** Konkurrenz und Nachfrage werden live mit WebSearch/WebFetch und den
   Skripten in `scripts/` untersucht. Keine erfundenen Wettbewerber, keine erfundenen Zahlen. Was nicht verifizierbar ist,
   wird als Annahme gekennzeichnet.
5. **Sprache:** Artefakte und Kundenkommunikation auf Deutsch (Sie-Form gegenüber Kunden, es sei denn das Briefing sagt
   etwas anderes). Code, Dateinamen und Kommentare im Build auf Englisch.
6. **Ehrlichkeit über Ergebnisse.** Wenn ein Skript fehlschlägt oder eine Quelle nicht erreichbar ist, steht das im
   Artefakt. Keine stillen Lücken.

## Technische Werkzeuge

- `scripts/analyse.sh <url>` führt Screenshots, Crawl, Design-Token-Extraktion und Lighthouse in einem Lauf aus.
  Einzelskripte: `screenshot.mjs`, `crawl.mjs`, `tokens.mjs`, `audit.sh`. Ausgabe nach `analyse/<slug>/`.
- Vor dem ersten Lauf: `cd scripts && npm install`. Lighthouse wird bei Bedarf über `npx` geladen.
- Stack-Empfehlungen für den Build stehen in `referenzen/tech-stack.md`. Standard: Astro + Tailwind + GSAP (ScrollTrigger)
  + Lenis, optional Three.js/Spline für 3D. Abweichungen werden im Artefakt `10-build-spezifikation.md` begründet.

## Qualitätsmaßstab (verbindlich für `qa-reviewer`)

- Lighthouse mobil: Performance ≥ 90, Barrierefreiheit ≥ 95, SEO ≥ 95. LCP ≤ 2,0 s, CLS ≤ 0,05, INP ≤ 150 ms.
- WCAG 2.2 AA (BFSG-konform, siehe `checklisten/barrierefreiheit-motion.md`). `prefers-reduced-motion` immer respektiert.
- Jede Animation hat einen Zweck (Orientierung, Hierarchie, Feedback, Erzählung). Dekoration ohne Funktion wird gestrichen.
- Responsiv von 320 px bis 1920 px ohne horizontales Scrollen, getestet in drei Viewports.

## Was der Orchestrator nie tut

- Keine Wettbewerber oder Trends erfinden, wenn Recherche fehlschlägt. Stattdessen Lücke benennen.
- Keine Templates oder Themes als Basis verwenden.
- Kein Build ohne vorher freigegebenes Design-System und Motion-Konzept.
- Keine Inhalte des Kunden (Texte, Bilder, Daten) an externe Dienste schicken, die nicht im Briefing freigegeben sind.
