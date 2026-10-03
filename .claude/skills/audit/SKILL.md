---
name: audit
description: Technische und gestalterische Ist-Analyse einer Website per URL (Screenshots in drei Viewports, Crawl, Design-Tokens, Lighthouse, acht Bewertungsdimensionen, Einheitsbrei-Index, priorisierte Maßnahmen) als Audit-Bericht. Einsetzen, wenn eine Website bewertet werden soll, ohne gleich ein Redesign zu starten.
argument-hint: "<url> [--max-pages 20] [--skip-lighthouse]"
disable-model-invocation: false
---

# /audit – Website-Audit

Argumente: `$ARGUMENTS`

## Ablauf

1. URL normalisieren, Slug aus der Domain bilden, `projekte/<slug>/artefakte/` anlegen (falls nicht vorhanden).
   `scripts/node_modules` prüfen, sonst `cd scripts && npm install`.
2. Agent `website-auditor` mit URL, Projektordner und Optionen (`--max-pages`, `--skip-lighthouse`) starten.
3. Kurzfassung zeigen: Gesamtnote, Einheitsbrei-Index, Lighthouse mobil (Performance, Barrierefreiheit, SEO, LCP, CLS),
   drei schwerste Probleme, drei Stärken, Quick Wins, empfohlene Stoßrichtung. Pfade: `artefakte/04-audit-bericht.md`,
   `analyse/<slug>/` (Screenshots, `crawl-summary.md`, `tokens.md`, `lighthouse-summary.md`).
4. Anbieten, mit `/homepage-verbessern <url>` fortzusetzen (der Audit wird dann wiederverwendet, wenn er jünger als
   7 Tage ist).

## Regeln

- Nichts beschönigen, nichts erfinden; nicht messbare Punkte als solche benennen.
- Deutsch, knapp, mit Pfaden.
