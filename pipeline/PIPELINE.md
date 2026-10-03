# Die Pipeline

Eine Agenten-Pipeline in Claude Code für Websites, die **exklusiv, begründet und messbar gut** sind. Zwei Einstiege
(`/homepage-neu`, `/homepage-verbessern <url>`), zwölf Spezialagenten, vier Gates, vierzehn Artefakte.

## Überblick

```
MODUS A: neue Website                          MODUS B: bestehende Website (nur URL)
─────────────────────                          ─────────────────────────────────────
/fragebogen  (Blöcke A–J, interaktiv)          website-auditor  → 04-audit-bericht
      │                                        Kurzfragebogen (≤ 8 Fragen)
      ▼                                                │
briefing-agent ──────────────────────────────► 01-briefing + briefing.json
      │                                  ═══ GATE 1: Briefing bestätigen ═══
      ├──────────────┬───────────────┐
      ▼              ▼               │   (parallel)
konkurrenz-analyst   trend-scout     │
02-konkurrenzanalyse 03-trendreport  │
      └──────┬───────┘
             ▼
      markenstratege ─────────────────► 05-positionierung (3 Richtungen, Signature Idea)
                                 ═══ GATE 2: Richtung wählen ═══
             ▼
      ux-architekt ───────────────────► 06-informationsarchitektur
             ├──────────────┐           (parallel)
             ▼              ▼
          texter       art-director ──► 07-copy-deck, 08-design-system + tokens.css
             └──────┬───────┘
                    ▼
            motion-designer ──────────► 09-motion-konzept
                    ▼
            unikat-pruefer (1) ───────► 13-unikat-pruefung-1   ◄── < 80: zurück an Zuständige
                                 ═══ GATE 3: Design & Motion freigeben ═══
                    ▼
          frontend-entwickler ────────► 10-build-spezifikation + Code (projekte/<slug>/build)
                    ▼
             qa-reviewer ─────────────► 11-qa-protokoll  ◄──► frontend-entwickler (Fix-Schleife)
                    ▼
            unikat-pruefer (2) ───────► 13-unikat-pruefung-2
                    ▼
          frontend-entwickler ────────► 12-uebergabe
                                 ═══ GATE 4: Launch ═══
```

## Phasen im Detail

| Phase | Agent(en) | Modell | Eingaben | Artefakt | Gate |
|---|---|---|---|---|---|
| 0a (nur B) | `website-auditor` | sonnet | URL, `scripts/analyse.sh` | `04-audit-bericht.md`, `analyse/<slug>/` | – |
| 0b | Skill `/fragebogen` (A) oder Kurzfragebogen (B), dann `briefing-agent` | opus | Antworten, Audit | `01-briefing.md`, `briefing.json` | **1** |
| 1 | `konkurrenz-analyst` ∥ `trend-scout` | opus | 01 | `02-konkurrenzanalyse.md`, `03-trendreport.md`, `analyse/wettbewerb/` | – |
| 2 | `markenstratege` | opus | 01, 02, 03 | `05-positionierung.md` | **2** |
| 3 | `ux-architekt` → (`texter` ∥ `art-director`) → `motion-designer` → `unikat-pruefer` | opus | 01–06 | `06`, `07`, `08` + `design/tokens.css`, `09`, `13-…-1` | **3** |
| 4 | `frontend-entwickler` | opus | 06–09 | `10-build-spezifikation.md`, `build/` | – |
| 5 | `qa-reviewer` ⇄ `frontend-entwickler`, `unikat-pruefer`, `frontend-entwickler` | sonnet/opus | Build, 07, 09, Checklisten | `11-qa-protokoll.md`, `13-…-2`, `12-uebergabe.md` | **4** |

Modelle sind Empfehlungen in den Agentendateien (`model:`) und können dort geändert werden (`sonnet` für Tempo,
`opus` für Urteil). Jeder Agent liest seine Vorlage aus `pipeline/artefakte/` und schreibt genau ein Artefakt nach
`projekte/<slug>/artefakte/`.

## Die vier Gates

Gates sind Entscheidungspunkte für den Nutzer. Der Orchestrator legt eine Vorlage von höchstens zehn Zeilen vor und
stellt genau eine Frage (AskUserQuestion). Mit `--auto` werden Gates protokolliert und mit der Empfehlung beantwortet.

| Gate | Frage | Was danach feststeht |
|---|---|---|
| 1 | Stimmt das Briefing, sind die Annahmen richtig, Antworten auf die offenen Fragen? | Ziel, Zielgruppe, Freiheitsgrad, Bewegung/Mut, Funktionen |
| 2 | Welche der drei Konzeptrichtungen? | Signature Idea, Tonalität, Positionierung |
| 3 | Design-System und Motion-Konzept freigeben (inkl. Schriftlizenzen)? | Alles, was gebaut wird |
| 4 | Launch? | Live-Gang ist immer eine Entscheidung des Nutzers |

## Projektordner

```
projekte/<slug>/
├── briefing.json                 strukturierte Fassung des Briefings (Schema: fragebogen/fragebogen.schema.json)
├── rohdaten/                     Fragebogen-Antworten, Gesprächsprotokoll, Kundenmaterial
├── artefakte/
│   ├── 00-projektstatus.md       Orchestrator-Log: Phasen, Gates, Entscheidungen, offene Punkte
│   ├── 01-briefing.md
│   ├── 02-konkurrenzanalyse.md
│   ├── 03-trendreport.md
│   ├── 04-audit-bericht.md       (Modus B)
│   ├── 05-positionierung.md
│   ├── 06-informationsarchitektur.md
│   ├── 07-copy-deck.md
│   ├── 08-design-system.md
│   ├── 09-motion-konzept.md
│   ├── 10-build-spezifikation.md
│   ├── 11-qa-protokoll.md
│   ├── 12-uebergabe.md
│   └── 13-unikat-pruefung-1.md / -2.md
├── design/tokens.css             Design- und Motion-Tokens
└── build/                        Code (Astro-Projekt)

analyse/<slug>/                   Screenshots, crawl.json, tokens.json, Lighthouse (Ist-Zustand, Modus B)
analyse/wettbewerb/<wb-slug>/     dasselbe pro Wettbewerber
analyse/<slug>-qa/                Messungen des Builds
```

## Qualitätsschleifen

- **Unikat-Schleife (Phase 3):** `unikat-pruefer` < 80 → Änderungsliste an `art-director`, `texter`, `motion-designer`;
  erneute Prüfung; höchstens drei Runden, dann Entscheidung des Nutzers.
- **QA-Schleife (Phase 5):** `qa-reviewer` findet Blocker/Muss → `frontend-entwickler` behebt → `qa-reviewer` prüft
  offene Punkte + Lighthouse; höchstens fünf Runden.
- **Ergebnis-Prüfung:** `unikat-pruefer` (2) am gerenderten Build; < 80 → zurück in die QA-Schleife.

## Fehler und Lücken

Scheitert ein Skript (Bot-Schutz, kein Chrome, Netzwerk) oder eine Recherche, steht die Lücke im Artefakt und im Status.
Nichts wird geschätzt oder erfunden. Der Orchestrator entscheidet, ob die Phase mit Lücke weitergeht oder der Nutzer
gefragt wird. Wiederverwendung: Ein Audit jünger als 7 Tage und eine Konkurrenzanalyse jünger als 30 Tage werden nicht
neu erstellt, sondern gelesen.

## Headless / automatisiert

Die Pipeline läuft auch ohne interaktive Sitzung, zum Beispiel für einen ersten Entwurf über Nacht:

```bash
claude -p "/homepage-verbessern https://beispiel.de --auto --bis konzept" --permission-mode acceptEdits
claude -p "/audit https://beispiel.de" --output-format json
claude -p "/konkurrenzanalyse 'Steuerberatung' 'Köln' --mit-trends"
```

`--auto` ersetzt Gates durch Empfehlungen und Rückfragen durch markierte Annahmen. Gate 4 (Launch) wird nie automatisch
passiert; `--bis qa` ist das Maximum im Auto-Modus.

## Erweiterung

- Neuer Agent: Datei in `.claude/agents/` mit Frontmatter (`name`, `description`, `tools`, `model`), Vorlage in
  `pipeline/artefakte/`, Aufruf in den Skills ergänzen.
- Branchen-Spezialisierung: zusätzliche Checkliste in `checklisten/` (z. B. Heilmittelwerbegesetz für Praxen) und
  Verweis im `briefing-agent`.
- Anderer Stack: `referenzen/tech-stack.md` erweitern; `frontend-entwickler` begründet die Wahl in der Build-Spezifikation.
- Eigene Trend-Baseline: `referenzen/trends-baseline-2026.md` fortschreiben (der `trend-scout` verifiziert sie ohnehin).

## Kosten und Dauer (Erfahrungswerte, grob)

| Lauf | Dauer | Hinweis |
|---|---|---|
| `/audit` | 5–15 min | abhängig von Seitenzahl und Lighthouse |
| `/konkurrenzanalyse` mit 6 Wettbewerbern | 20–40 min | Crawls und Screenshots dominieren |
| `/homepage-neu` bis Gate 3 | 1–3 h | plus Antwortzeiten an den Gates |
| Build + QA | 1–4 h | abhängig von Seitenzahl, Signature-Moments, Fix-Runden |

Die Pipeline ersetzt kein Fotoshooting, keine Rechtsberatung und keine Entscheidung des Kunden. Sie macht alles davor
und danach schneller, belegter und unverwechselbarer.
