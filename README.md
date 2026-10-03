# Premium-Homepage-Pipeline

Eine Agenten-Pipeline für **hochwertige, exklusive Websites**: Sie analysiert die Konkurrenz, wertet aus, was gerade
gefragt ist, holt alle Informationen per Fragebogen oder Kurzbrief ein (oder analysiert eine bestehende Website nur per
Link) und führt zwölf spezialisierte Agenten durch Briefing, Positionierung, Architektur, Text, Design-System,
Motion-Konzept, Build, Qualitätssicherung und Paketierung. Jede Website entsteht von null. Kein Einheitsbrei: Jede
Website braucht eine Signature Idea, jede Entscheidung eine Begründung, jede Animation eine Funktion.

## Vorne rein, hinten raus

```bash
git clone <dieses-repo> && cd Website-pipeline
npm install -g @anthropic-ai/claude-code     # falls noch nicht installiert, dann einmal `claude` zum Anmelden
cd scripts && npm install && cd ..           # Playwright für Screenshots/Crawls

cp eingang/VORLAGE-kurzbrief.md eingang/meinprojekt.md   # ausfüllen (10 Minuten)
bash run.sh eingang/meinprojekt.md                        # läuft ohne Rückfragen durch
```

Am Ende liegt in `ausgang/meinprojekt/`:

| Inhalt | Beschreibung |
|---|---|
| `ERGEBNIS.md` | Signature Idea, Kennzahlen, automatisch getroffene Entscheidungen, Annahmen, offene Punkte, nächste Schritte |
| `website/` | fertiger Produktionsbuild, auf jeden statischen Host hochladbar |
| `quellcode/` | Astro-Projekt (`npm install && npm run dev`) |
| `dokumentation/` | alle 14 Artefakte (Briefing, Konkurrenzanalyse, Trendreport, Positionierung, IA, Copy-Deck, Design-System, Motion-Konzept, Build-Spezifikation, QA-Protokoll, Übergabe, Unikat-Prüfungen) |
| `vorschau/` | Screenshots aller Viewports, hell/dunkel, mit und ohne Reduced Motion |
| `meinprojekt.zip` | alles zusammen |

Weitere Startformen: `bash run.sh https://beispiel.de` (Neubau aus URL), `bash run.sh --alle` (alle Dateien in
`eingang/`). Optionen: `--bis <phase>`, `--ab <phase>` (ab einer Phase neu rechnen), `--richtung B` (andere
Konzeptrichtung), `--deploy` / `--deploy-prod` (nach QA veröffentlichen, Ziel in `pipeline.config.json`), `--neu`,
`--voll` (Claude ohne Berechtigungsabfragen, für CI), `--trocken` (nur anzeigen).

Was in der Eingabe fehlt, wird als gekennzeichnete Annahme ergänzt (Standardwerte in `pipeline.config.json`). Die
Entscheidungen an den Gates stehen mit Alternativen in `ERGEBNIS.md`; eine andere Richtung ist ein Befehl entfernt
(`bash run.sh eingang/meinprojekt.md --ab konzept --richtung B`).

## Interaktiv in Claude Code

| Befehl | Was passiert |
|---|---|
| `/homepage-neu meinprojekt` | Fragebogen im Gespräch → Briefing → Konkurrenz + Trends → Positionierung (3 Richtungen zur Wahl) → IA, Copy, Design-System, Motion → Unikat-Prüfung → Build → QA → Übergabe → Paket, mit vier Gates |
| `/homepage-verbessern https://beispiel.de` | Bestehende Seite analysieren, Briefing ableiten, ≤ 8 Rückfragen, dann dieselbe Pipeline als Neubau mit Vorher-Nachher-Vergleich |
| `/fragebogen meinprojekt` | Nur den Fragebogen interaktiv durchführen und ein Briefing erzeugen |
| `/konkurrenzanalyse "Steuerberatung" "Köln" --mit-trends` | Nur Wettbewerber und Nachfrage analysieren |
| `/audit https://beispiel.de` | Nur die Ist-Analyse einer Website |

Ohne Claude Code: `prompts/MASTER-PROMPT.md` ist ein eigenständiger Prompt mit derselben Methodik.

## Was drin ist

```
run.sh                 Vollautomatik: eine Eingabe, ein Paket
eingang/               Vorlagen für Kurzbrief und URL-Eingabe; eigene Dateien werden nicht versioniert
ausgang/               Ergebnisse (nicht versioniert)
pipeline.config.json   Standardwerte für fehlende Angaben, Rundenlimits, Deploy-Ziel
.claude/agents/        12 Subagenten (je ein Spezialist mit eigenem Prompt, Werkzeugen, Modell)
.claude/skills/        5 Skills, die die Agenten orchestrieren
.claude/settings.json  Freigaben für Recherche, Skripte, npm
CLAUDE.md              Regeln für den Orchestrator (Gates, Qualitätsmaßstab, Verbote)
prompts/               MASTER-PROMPT.md (eigenständig nutzbar)
fragebogen/            Vollständiger Fragebogen, Kurzfragebogen (URL-Modus), JSON-Schema des Briefings
pipeline/              PIPELINE.md (Phasen, Gates, Schleifen) und Vorlagen aller Artefakte
checklisten/           Anti-Einheitsbrei (Rote Liste + Bewertung), QA/Launch, Barrierefreiheit & Bewegung
referenzen/            Tech-Stack, Animations-Patterns, Trend-Baseline 2026 (vom Trend-Scout zu verifizieren)
scripts/               Screenshots, Crawler, Design-Tokens, Lighthouse, Komplettanalyse, Paketieren, Deploy
projekte/<slug>/       entsteht pro Projekt: rohdaten/, artefakte/, design/tokens.css, build/, ERGEBNIS.md
analyse/<slug>/        Messdaten (Screenshots, crawl.json, tokens.json, Lighthouse), nicht versioniert
.github/workflows/     optional: Pipeline in GitHub Actions (Datei in eingang/ pushen → Paket als Artefakt)
```

## Die Agenten

| Agent | Aufgabe | Artefakt |
|---|---|---|
| `briefing-agent` | Antworten, Kurzbrief oder Audit → strukturiertes Briefing; schließt Lücken mit gekennzeichneten Annahmen | 01 |
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
node screenshot.mjs https://beispiel.de --dark --reduced-motion --sizes 320x568,1920x1080
node crawl.mjs https://beispiel.de --max 20             # Struktur, Inhalte, SEO, Stack, Fonts, Farben, Animations-Libs
node tokens.mjs https://beispiel.de                     # Design-Tokens: Farben, Typo-Skala, Radien, Breakpoints
bash audit.sh https://beispiel.de                       # Lighthouse mobil + Desktop mit Kurzfassung
bash analyse.sh https://beispiel.de                     # alles zusammen → ../analyse/<slug>/
bash paketieren.sh <slug>                               # ausgang/<slug>/ + ZIP
bash deploy.sh <slug> [--prod]                          # Netlify / Vercel / Cloudflare Pages
```

Voraussetzungen: Node ≥ 18, Chromium (Playwright lädt es mit `npx playwright install chromium`, falls nicht vorhanden),
Claude Code CLI mit Anmeldung oder `ANTHROPIC_API_KEY`. Hinter einem Proxy werden `HTTPS_PROXY`/`NO_PROXY` berücksichtigt.

## Qualitätsmaßstab

Lighthouse mobil ≥ 90 / Barrierefreiheit ≥ 95 / SEO ≥ 95 · LCP ≤ 2,0 s · CLS ≤ 0,05 · INP ≤ 150 ms · WCAG 2.2 AA
(BFSG-konform) · `prefers-reduced-motion` immer respektiert · Unikat-Punktzahl ≥ 80 · keine Templates, keine
Floskeln, keine Animation ohne Funktion.

## Anpassen

- Standardwerte, Rundenlimits und Deploy-Ziel in `pipeline.config.json`.
- Modelle je Agent in `.claude/agents/*.md` (`model: opus|sonnet|haiku`).
- Eigene Branchen-Checklisten in `checklisten/`, eigener Stack in `referenzen/tech-stack.md`.
- Trend-Baseline fortschreiben in `referenzen/trends-baseline-2026.md`.

## Hinweise

- Ein kompletter Lauf dauert je nach Umfang ein bis mehrere Stunden und verbraucht entsprechend Kontingent. `--bis
  konzept` liefert in deutlich kürzerer Zeit alle Konzeptdokumente zur Prüfung, bevor gebaut wird.
- Die Pipeline ersetzt kein Fotoshooting, keine Rechtsberatung und keine Schriftlizenz. Was der Kunde liefern muss, steht
  in `ERGEBNIS.md`.
