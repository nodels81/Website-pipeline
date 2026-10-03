---
name: konkurrenzanalyse
description: Eigenständige Wettbewerbs- und Nachfrageanalyse für eine Branche und Region (optional mit konkreten Wettbewerber-URLs) – Vergleichsmatrix, Einheitsbrei-Landkarte, Lücken, Benchmarks und auf Wunsch Trendreport. Einsetzen, wenn jemand wissen will, wie die Konkurrenz im Web aufgestellt ist und was gerade gefragt ist, ohne gleich eine ganze Website zu bauen.
argument-hint: "<branche> <region> [url ...] [--mit-trends] [--projekt <slug>]"
disable-model-invocation: false
---

# /konkurrenzanalyse – Wettbewerb und Nachfrage

Argumente: `$ARGUMENTS`

## Ablauf

1. **Argumente lesen:** Branche/Leistung, Region, optionale URLs, `--mit-trends`, `--projekt <slug>`. Fehlt Branche oder
   Region: nachfragen (eine AskUserQuestion mit beiden Feldern als freie Eingabe).
2. **Projektkontext:**
   - Mit `--projekt`: bestehendes `projekte/<slug>/artefakte/01-briefing.md` nutzen.
   - Ohne: Slug aus Branche und Region bilden (`konkurrenz-<branche>-<region>`), Ordner
     `projekte/<slug>/{artefakte,rohdaten}` anlegen und ein **Minimal-Briefing** `artefakte/01-briefing.md` schreiben
     (Abschnitte: Leistung, Region, genannte Wettbewerber, Zielgruppe „unbekannt – aus Markt ableiten“, Modus
     „analyse“). Alles als Annahme markieren.
3. **Agenten starten:** `konkurrenz-analyst` (immer) und bei `--mit-trends` **parallel** `trend-scout`. Auftrag mit
   Projektordner, Vorlagenpfaden und dem Hinweis, dass kein Design-Projekt folgt (Empfehlungen also allgemein für die
   Branche formulieren).
4. **Ergebnis zeigen:** Kurzfassung (Anzahl Wettbewerber, Einheitsbrei-Landkarte Top 5 mit Prozent, Lücken Top 3,
   Benchmarks, Empfehlung; bei Trends: Nutzerfragen Top 5, relevante Trends) und Pfade der Artefakte
   (`02-konkurrenzanalyse.md`, ggf. `03-trendreport.md`, `analyse/wettbewerb/`).
5. Hinweis, dass mit `/homepage-neu <slug>` oder `/homepage-verbessern <url>` auf dieser Analyse aufgebaut werden kann
   (die Pipeline erkennt vorhandene Artefakte und überspringt Phase 1, wenn sie jünger als 30 Tage sind).

## Regeln

- Keine erfundenen Wettbewerber oder Zahlen; Lücken benennen.
- Deutsch, knapp, mit Pfaden.
