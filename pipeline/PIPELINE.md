# Die Pipeline

Eine Agenten-Pipeline in Claude Code für Websites, die **exklusiv, begründet und messbar gut** sind. Vorne eine
Eingabe (Kurzbrief, Fragebogen oder URL), hinten ein fertiges Paket. Zwölf Spezialagenten, sechs Phasen, vier Gates,
fünfzehn Artefakte.

## Vollautomatik

```bash
bash run.sh eingang/<projekt>.md      # Kurzbrief oder Fragebogen
bash run.sh https://beispiel.de       # Neubau aus URL
bash run.sh --alle                    # alles in eingang/ ohne Ergebnis
```

`run.sh` ruft `claude -p "/homepage-neu <slug> --auto --antworten <datei>"` bzw. `/homepage-verbessern <url> --auto`
auf, schreibt ein Log nach `ausgang/<slug>/pipeline.log` und stellt am Ende sicher, dass `ausgang/<slug>/` mit
`ERGEBNIS.md`, `website/`, `quellcode/`, `dokumentation/`, `vorschau/` und ZIP existiert.

Im Automatik-Modus gibt es keine Rückfragen: Lücken werden zu gekennzeichneten Annahmen (Standardwerte in
`pipeline.config.json`), Gates werden mit der Empfehlung beantwortet, Schleifen haben Limits, jede Entscheidung steht
mit Alternative in `ERGEBNIS.md`. Ein abgebrochener Lauf wird mit demselben Befehl fortgesetzt (fertige Artefakte
werden übernommen). `--ab <phase>` rechnet ab einer Phase neu, `--richtung B` wählt eine andere Konzeptrichtung,
`--deploy`/`--deploy-prod` veröffentlicht nach der QA.

## Überblick

```
EINGANG  eingang/<projekt>.md (Kurzbrief / Fragebogen)          eingang/<projekt>.md mit URL  oder  URL direkt
                    │                                                        │
                    │                                              website-auditor → 04-audit-bericht
                    │                                              Kurzfragebogen (Antworten aus Datei oder ≤ 8 Fragen)
                    ▼                                                        │
            briefing-agent ◄─────────────────────────────────────────────────┘
            01-briefing + briefing.json            ═══ GATE 1: Briefing / Annahmen ═══
                    ├──────────────┬───────────────┐
                    ▼              ▼               │   (parallel)
          konkurrenz-analyst   trend-scout         │
          02-konkurrenzanalyse 03-trendreport      │
                    └──────┬───────┘
                           ▼
                    markenstratege ────────────────► 05-positionierung (3 Richtungen, Signature Idea)
                                             ═══ GATE 2: Richtung (Empfehlung / --richtung) ═══
                           ▼
                    ux-architekt ──────────────────► 06-informationsarchitektur
                           ├──────────────┐           (parallel)
                           ▼              ▼
                        texter       art-director ──► 07-copy-deck, 08-design-system + tokens.css
                           └──────┬───────┘
                                  ▼
                          motion-designer ─────────► 09-motion-konzept
                                  ▼
                          unikat-pruefer (1) ──────► 13-unikat-pruefung-1   ◄── < 80: zurück (max. unikatRunden)
                                             ═══ GATE 3: Design & Motion ═══
                                  ▼
                        frontend-entwickler ───────► 10-build-spezifikation + Code (projekte/<slug>/build)
                                  ▼
                           qa-reviewer ────────────► 11-qa-protokoll  ◄──► frontend-entwickler (max. qaRunden)
                                  ▼
                          unikat-pruefer (2) ──────► 13-unikat-pruefung-2
                                  ▼
                        frontend-entwickler ───────► 12-uebergabe
                                             ═══ GATE 4: Launch (nie automatisch; --deploy-prod) ═══
                                  ▼
                        Orchestrator ──────────────► ERGEBNIS.md, scripts/paketieren.sh
AUSGANG  ausgang/<slug>/ {ERGEBNIS.md, website/, quellcode/, dokumentation/, vorschau/, <slug>.zip}
```

## Phasen

| # | Name (`--bis`/`--ab`) | Agent(en) | Modell | Eingaben | Artefakt | Gate |
|---|---|---|---|---|---|---|
| 0a | `audit` (nur URL-Modus) | `website-auditor` | sonnet | URL, `scripts/analyse.sh` | `04-audit-bericht.md`, `analyse/<slug>/` | – |
| 0b | `briefing` | `/fragebogen` oder Eingabedatei, dann `briefing-agent` | opus | Antworten, Audit, `pipeline.config.json` | `01-briefing.md`, `briefing.json` | **1** |
| 1 | `analyse` | `konkurrenz-analyst` ∥ `trend-scout` | opus | 01 | `02-konkurrenzanalyse.md`, `03-trendreport.md`, `analyse/wettbewerb/` | – |
| 2 | `positionierung` | `markenstratege` | opus | 01, 02, 03 | `05-positionierung.md` | **2** |
| 3 | `konzept` | `ux-architekt` → (`texter` ∥ `art-director`) → `motion-designer` → `unikat-pruefer` | opus | 01–06 | `06`, `07`, `08` + `design/tokens.css`, `09`, `13-…-1` | **3** |
| 4 | `build` | `frontend-entwickler` | opus | 06–09 | `10-build-spezifikation.md`, `build/`, `analyse/<slug>-build/` | – |
| 5 | `qa` | `qa-reviewer` ⇄ `frontend-entwickler`, `unikat-pruefer`, `frontend-entwickler` | sonnet/opus | Build, 07, 09, Checklisten | `11-qa-protokoll.md`, `13-…-2`, `12-uebergabe.md`, `analyse/<slug>-qa/` | **4** |
| 6 | `paket` | Orchestrator, `scripts/paketieren.sh`, optional `scripts/deploy.sh` | – | alles | `ERGEBNIS.md`, `ausgang/<slug>/`, ZIP | – |

Modelle stehen in den Agentendateien (`model:`) und können dort geändert werden. Jeder Agent liest seine Vorlage aus
`pipeline/artefakte/` und schreibt genau ein Artefakt nach `projekte/<slug>/artefakte/`.

## Die vier Gates

| Gate | Interaktiv | Automatik |
|---|---|---|
| 1 Briefing | Annahmen bestätigen, offene Fragen beantworten (AskUserQuestion, max. vier je Aufruf) | Annahmen übernehmen, protokollieren |
| 2 Richtung | Eine von drei Konzeptrichtungen wählen | Empfehlung des Markenstrategen oder `--richtung` |
| 3 Design & Motion | Design-System und Motion-Konzept freigeben (inkl. Schriftlizenzen) | Freigegeben, wenn Unikat-Prüfung ≥ 80 oder Runden erschöpft (dokumentiert) |
| 4 Launch | Entscheidung des Nutzers | Nie automatisch; `--deploy` erzeugt eine Vorschau, `--deploy-prod` veröffentlicht |

## Projektordner

```
projekte/<slug>/
├── briefing.json                 strukturierte Fassung des Briefings (Schema: fragebogen/fragebogen.schema.json)
├── ERGEBNIS.md                   Abschlussbericht (Vorlage 14), wird nach ausgang/ kopiert
├── rohdaten/                     Eingabedatei, Gesprächsprotokoll, Kundenmaterial
├── artefakte/
│   ├── 00-projektstatus.md       Orchestrator-Log: Phasen, Gates, Entscheidungen, Lücken, offene Punkte
│   ├── 01 … 12                   Briefing bis Übergabe (siehe Tabelle)
│   ├── 13-unikat-pruefung-1.md / -2.md
│   └── _alt/<datum>/             durch --ab / --neu verdrängte Artefakte (nicht versioniert)
├── design/tokens.css             Design- und Motion-Tokens
└── build/                        Code (Astro-Projekt)

analyse/<slug>/                   Ist-Zustand (URL-Modus) · analyse/wettbewerb/<wb>/ · analyse/<slug>-build/ · analyse/<slug>-qa/
ausgang/<slug>/                   Paket: ERGEBNIS.md, website/, quellcode/, dokumentation/, vorschau/, pipeline.log · ausgang/<slug>.zip
```

## Qualitätsschleifen und Limits

- **Unikat-Schleife (Phase 3):** `unikat-pruefer` < 80 → Änderungsliste an `art-director`, `texter`,
  `motion-designer`; erneute Prüfung; Limit `automatik.unikatRunden` (Standard 3).
- **QA-Schleife (Phase 5):** Blocker/Muss → `frontend-entwickler` → `qa-reviewer` (offene Punkte + Lighthouse); Limit
  `automatik.qaRunden` (Standard 5). Die Ergebnis-Prüfung des `unikat-pruefer` zählt gegen dasselbe Limit.
- Nach erschöpftem Limit geht es im Automatik-Modus mit dem besten Stand weiter; die Abweichung steht in `ERGEBNIS.md`.
  Interaktiv entscheidet der Nutzer.

## Fehler, Lücken, Wiederverwendung

Scheitert ein Skript (Bot-Schutz, kein Chrome, Netzwerk) oder eine Recherche, steht die Lücke im Artefakt, im Status
und in `ERGEBNIS.md`. Nichts wird geschätzt oder erfunden. Fertige Artefakte werden bei erneutem Start übernommen;
ein Audit jünger als 7 Tage und eine Konkurrenzanalyse jünger als 30 Tage gelten auch projektübergreifend als aktuell.

## Headless und CI

```bash
claude -p "/homepage-verbessern https://beispiel.de --auto --bis konzept" --permission-mode acceptEdits
bash run.sh eingang/projekt.md --voll          # bypassPermissions, für unbeaufsichtigte Läufe
```

`.github/workflows/pipeline.yml` führt `run.sh` in GitHub Actions aus (Push nach `eingang/` oder manueller Start);
das Paket erscheint als Workflow-Artefakt. Benötigt `ANTHROPIC_API_KEY` als Secret, optional Deploy-Secrets.

## Erweiterung

- Neuer Agent: Datei in `.claude/agents/` (Frontmatter `name`, `description`, `tools`, `model`), Vorlage in
  `pipeline/artefakte/`, Aufruf in den Skills ergänzen.
- Branchen-Spezialisierung: zusätzliche Checkliste in `checklisten/` und Verweis im `briefing-agent`.
- Anderer Stack: `referenzen/tech-stack.md` erweitern; `frontend-entwickler` begründet die Wahl.
- Standardwerte, Limits, Deploy-Ziel: `pipeline.config.json`.

## Dauer (Erfahrungswerte, grob)

| Lauf | Dauer |
|---|---|
| `--bis audit` | 5–15 min |
| `--bis analyse` (6 Wettbewerber) | 30–60 min |
| `--bis konzept` | 1–3 h |
| komplett bis Paket | 2–6 h, abhängig von Seitenzahl, Signature-Moments und Fix-Runden |

Die Pipeline ersetzt kein Fotoshooting, keine Rechtsberatung und keine Entscheidung des Kunden. Sie macht alles davor
und danach schneller, belegter und unverwechselbarer.
