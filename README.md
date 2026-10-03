# Premium-Homepage-Pipeline

Eine Agenten-Pipeline für **hochwertige, exklusive Websites**: Sie analysiert die Konkurrenz, wertet aus, was gerade
gefragt ist, holt alle Informationen per Fragebogen ein (oder leitet sie aus einer bestehenden Website ab, nur per Link)
und führt zwölf spezialisierte Agenten durch Briefing, Positionierung, Architektur, Text, Design-System, Motion-Konzept,
Build und Qualitätssicherung. Kein Einheitsbrei: Jede Website braucht eine Signature Idea, jede Entscheidung eine
Begründung, jede Animation eine Funktion.

## Schnellstart (Claude Code)

```bash
git clone <dieses-repo> && cd Website-pipeline
cd scripts && npm install && cd ..        # Playwright für Screenshots/Crawls
claude                                     # Claude Code im Projektordner starten
```

Dann in Claude Code:

| Befehl | Was passiert |
|---|---|
| `/homepage-neu meinprojekt` | Fragebogen → Briefing → Konkurrenz + Trends → Positionierung (3 Richtungen) → IA, Copy, Design-System, Motion → Unikat-Prüfung → Build → QA → Übergabe |
| `/homepage-verbessern https://beispiel.de` | Bestehende Seite komplett analysieren, Briefing ableiten, ≤ 8 Rückfragen, dann dieselbe Pipeline als Redesign mit Vorher-Nachher-Vergleich |
| `/fragebogen meinprojekt` | Nur den Fragebogen interaktiv durchführen und ein Briefing erzeugen |
| `/konkurrenzanalyse "Steuerberatung" "Köln" --mit-trends` | Nur Wettbewerber und Nachfrage analysieren |
| `/audit https://beispiel.de` | Nur die Ist-Analyse einer Website |

Optionen: `--auto` (Gates mit Empfehlung passieren, Rückfragen durch markierte Annahmen ersetzen), `--bis <phase>`
(z. B. `--bis konzept`). Headless: `claude -p "/homepage-verbessern https://beispiel.de --auto --bis konzept"`.

Ohne Claude Code: `prompts/MASTER-PROMPT.md` ist ein eigenständiger Prompt mit derselben Methodik für jede
Claude-Oberfläche.

## Was drin ist

```
.claude/agents/        12 Subagenten (je ein Spezialist mit eigenem Prompt, Werkzeugen, Modell)
.claude/skills/        5 Skills, die die Agenten orchestrieren (/homepage-neu, /homepage-verbessern, /fragebogen, /konkurrenzanalyse, /audit)
.claude/settings.json  Freigaben für WebSearch/WebFetch, Skripte, npm
CLAUDE.md              Regeln für den Orchestrator (Gates, Qualitätsmaßstab, Verbote)
prompts/               MASTER-PROMPT.md (eigenständig nutzbar)
fragebogen/            Vollständiger Fragebogen, Kurzfragebogen (URL-Modus), JSON-Schema des Briefings
pipeline/              PIPELINE.md (Phasen, Gates, Schleifen) und Vorlagen aller 14 Artefakte
checklisten/           Anti-Einheitsbrei (Rote Liste + Bewertung), QA/Launch, Barrierefreiheit & Bewegung
referenzen/            Tech-Stack, Animations-Patterns, Trend-Baseline 2026 (vom Trend-Scout zu verifizieren)
scripts/               Playwright-Screenshots, Crawler, Design-Token-Extraktion, Lighthouse, Komplettanalyse
projekte/<slug>/       entsteht pro Projekt: rohdaten/, artefakte/, design/tokens.css, build/
analyse/<slug>/        Messdaten (Screenshots, crawl.json, tokens.json, Lighthouse), nicht versioniert
```

## Die Agenten

| Agent | Aufgabe | Artefakt |
|---|---|---|
| `briefing-agent` | Antworten/Audit → strukturiertes Briefing mit Annahmen und offenen Fragen | 01 |
| `website-auditor` | Bestandsseite messen und bewerten (8 Dimensionen, Einheitsbrei-Index) | 04 |
| `konkurrenz-analyst` | Wettbewerber finden, crawlen, Vergleichsmatrix, Einheitsbrei-Landkarte, Lücken | 02 |
| `trend-scout` | Nutzerfragen, Branchenverschiebungen, Design-/Tech-Trends mit Urteil relevant/Mode/schadet | 03 |
| `markenstratege` | Positionierung, Tonalität, Personas, drei Konzeptrichtungen mit Signature Idea | 05 |
| `ux-architekt` | Sitemap, Section-Flows, Pfade, Navigation, Mobile, Komponenten-Inventar | 06 |
| `texter` | Alle Texte, Headline-Varianten, Microcopy, Meta, Schema.org, floskelfrei, mit Beweisen | 07 |
| `art-director` | Typografie, Farbe, Raster, Bild, Komponenten, Tokens, jede Entscheidung begründet | 08 + tokens.css |
| `motion-designer` | Bewegungscharakter, Signature-Moments, Scroll-Choreografie, Reduced Motion, Budget | 09 |
| `frontend-entwickler` | Astro + Tailwind + GSAP Build nach Artefakten, SEO, A11y, Performance, Fixes | 10 + Code, 12 |
| `qa-reviewer` | Lighthouse, WCAG 2.2, Reduced Motion, Responsiv, Inhalte, Links, Sicherheit, Fehlerliste | 11 |
| `unikat-pruefer` | Bewertung 0–100 gegen Rote Liste und Einheitsbrei-Landkarte; < 80 = Rückgabe | 13 |

## Skripte (auch einzeln nutzbar)

```bash
cd scripts
node screenshot.mjs https://beispiel.de --dark          # Desktop/Tablet/Mobile, Fold + Full, hell/dunkel
node crawl.mjs https://beispiel.de --max 20             # Struktur, Inhalte, SEO, Stack, Fonts, Farben, Animations-Libs
node tokens.mjs https://beispiel.de                     # Design-Tokens: Farben, Typo-Skala, Radien, Breakpoints
bash audit.sh https://beispiel.de                       # Lighthouse mobil + Desktop mit Kurzfassung
bash analyse.sh https://beispiel.de                     # alles zusammen → ../analyse/<slug>/
```

Voraussetzungen: Node ≥ 18, Chromium (Playwright lädt es mit `npx playwright install chromium`, falls nicht vorhanden).
Hinter einem Proxy werden `HTTPS_PROXY` und `NO_PROXY` berücksichtigt; lokale Preview-Server laufen immer direkt.

## Qualitätsmaßstab

Lighthouse mobil ≥ 90 / Barrierefreiheit ≥ 95 / SEO ≥ 95 · LCP ≤ 2,0 s · CLS ≤ 0,05 · INP ≤ 150 ms · WCAG 2.2 AA
(BFSG-konform) · `prefers-reduced-motion` immer respektiert · Unikat-Punktzahl ≥ 80 · keine Templates, keine
Floskeln, keine Animation ohne Funktion.

## Anpassen

- Modelle je Agent in `.claude/agents/*.md` (`model: opus|sonnet|haiku`).
- Eigene Branchen-Checklisten in `checklisten/`, eigener Stack in `referenzen/tech-stack.md`.
- Trend-Baseline fortschreiben in `referenzen/trends-baseline-2026.md`.
- Der Masterprompt in `prompts/` lässt sich für Kunden-Workshops kürzen oder in andere Werkzeuge kopieren.
