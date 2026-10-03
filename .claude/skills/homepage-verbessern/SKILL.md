---
name: homepage-verbessern
description: Bestehende Website nur anhand ihrer URL analysieren (Inhalt, UX, Gestaltung, Technik, SEO, Barrierefreiheit, Einheitsbrei-Grad), Briefing daraus ableiten, höchstens acht Rückfragen stellen und dann die komplette Premium-Redesign-Pipeline durchlaufen. Einsetzen, wenn eine vorhandene Homepage verbessert, modernisiert oder neu gemacht werden soll und eine URL vorliegt.
argument-hint: "<url> [--auto] [--bis audit|briefing|analyse|konzept|design|build|qa] [--nur-audit] [--neu-analysieren]"
disable-model-invocation: false
---

# /homepage-verbessern – Redesign-Pipeline aus einer URL

Du bist der **Orchestrator** (Regeln in `CLAUDE.md`, Phasen in `pipeline/PIPELINE.md`). Unterschied zu `/homepage-neu`:
Das Briefing entsteht aus der **Analyse der bestehenden Website** plus höchstens acht Rückfragen. Alles, was die Seite
selbst verrät, wird nicht gefragt, sondern als Annahme vorgelegt.

Argumente: `$ARGUMENTS`

## 0. Vorbereitung

1. URL aus den Argumenten lesen und normalisieren (`https://` ergänzen). Slug aus der Domain bilden (ohne `www.`).
   Ohne URL: nachfragen.
2. Optionen: `--auto` (Gates nicht blockierend, Empfehlungen wählen, Rückfragen durch Annahmen ersetzen), `--bis
   <phase>`, `--nur-audit` (entspricht `--bis audit`).
3. Ordner anlegen: `projekte/<slug>/{rohdaten,artefakte,design,build}`, Statusdatei aus
   `pipeline/artefakte/00-projektstatus.md` anlegen (Modus „verbessern“, URL, Datum, Optionen).
4. `scripts/node_modules` prüfen, sonst `cd scripts && npm install`.

## Phase 0a: Ist-Analyse

- Agent `website-auditor` mit URL und Projektordner starten. Er führt `scripts/analyse.sh` aus (Screenshots, Crawl,
  Tokens, Lighthouse) und schreibt `artefakte/04-audit-bericht.md` inklusive „Abgeleitetes Briefing-Material“.
- Kurzfassung (Gesamtnote, Einheitsbrei-Index, drei schwerste Probleme, drei Stärken, Lighthouse mobil, Stoßrichtung)
  in den Status und dem Nutzer zeigen. Bei `--bis audit` / `--nur-audit` hier enden.

## Phase 0b: Rückfragen und Briefing

- Ohne `--auto`: `fragebogen/fragebogen-kurz.md` lesen und die acht Fragen in **zwei AskUserQuestion-Aufrufen** (je vier
  Fragen) stellen. Für jede Frage Antwortoptionen anbieten, die aus dem Audit abgeleitet sind (z. B. die vermutete
  Zielgruppe, die vermutete Stoßrichtung), plus „Anders“. Antworten nach `rohdaten/kurzfragebogen-antworten.md`.
- Mit `--auto`: Datei `rohdaten/kurzfragebogen-antworten.md` mit „nicht gefragt (auto)“ anlegen; Annahmen trifft der
  Briefing-Agent aus dem Audit.
- `briefing-agent` (Modus „verbessern“, Quellen: Audit-Bericht + Kurzfragebogen) → `01-briefing.md`, `briefing.json`.
- **Gate 1:** Entscheidungsvorlage zeigen; Annahmen bestätigen lassen (AskUserQuestion, maximal vier Fragen). Bei `--bis
  briefing` hier enden.

## Phase 1: Analyse (parallel)

- `konkurrenz-analyst` → `02-konkurrenzanalyse.md`. Zusatz im Auftrag: Die bestehende Website des Kunden als
  „Ausgangspunkt“ in die Vergleichsmatrix aufnehmen (Daten aus `analyse/<slug>/`), damit sichtbar wird, wo sie heute im
  Einheitsbrei steht.
- `trend-scout` → `03-trendreport.md`. Zusatz: Welche Nutzerfragen beantwortet die bestehende Seite heute nicht?
- Kurzfassung in den Status, dem Nutzer zeigen. Bei `--bis analyse` hier enden.

## Phase 2: Positionierung

- `markenstratege` → `05-positionierung.md`. Zusatz im Auftrag: Stärken aus dem Audit („Was bleibt“) in allen drei
  Richtungen bewahren oder bewusst begründet aufgeben; eine Richtung darf „Redesign auf Bestand“ sein, wenn der Audit
  das nahelegt.
- **Gate 2:** Richtung wählen (AskUserQuestion; Empfehlung zuerst). `--auto`: Empfehlung.

## Phase 3: Konzeption

Wie in `/homepage-neu`: `ux-architekt` (Zusatz: Weiterleitungstabelle alte → neue URLs aus `crawl.json` des Audits,
SEO-Bestand sichern), dann parallel `texter` und `art-director` (Zusatz: `analyse/<slug>/tokens.md` als Ist-Zustand;
was vom Bestand bleibt, steht in der Begründungstabelle), dann `motion-designer`, dann `unikat-pruefer` (Prüfung 1) mit
Schleife (< 80 → Änderungen, maximal drei Runden). **Gate 3** wie in `/homepage-neu`. Bei `--bis konzept`/`--bis
design` hier enden.

## Phase 4: Build

`frontend-entwickler` → `10-build-spezifikation.md` + Code. Zusatz: 301-Weiterleitungen aus der IA implementieren,
Formulare und Integrationen aus dem Bestand übernehmen (laut Briefing), Inhalte aus dem Bestand nur über das Copy-Deck.
Bei `--bis build` hier enden.

## Phase 5: QA, Vergleich, Übergabe

Wie in `/homepage-neu` (QA-Schleife, Unikat-Prüfung 2, Übergabe, Gate 4). Zusatz für `12-uebergabe.md`:
**Vorher-Nachher-Tabelle** (Lighthouse mobil/Desktop, LCP, CLS, Transfer, Einheitsbrei-Index, Unikat-Punktzahl, Anzahl
beantworteter Nutzerfragen) aus `analyse/<slug>/` (vorher) und `analyse/<slug>-qa/` (nachher), sowie Launch-Plan mit
DNS-Umstellung, Weiterleitungen und Search-Console-Schritten.

## Abschluss

Status finalisieren; Zusammenfassung an den Nutzer (höchstens 15 Zeilen) mit Vorher-Nachher-Kennzahlen, Signature Idea,
Pfaden der Artefakte, offenen Lieferungen des Kunden und nächsten Schritten.

## Regeln

- Keine Inhalte der bestehenden Seite ungeprüft übernehmen: Texte gehen durch `texter`, Gestaltung durch
  `art-director`, Struktur durch `ux-architekt`. Was bleibt, bleibt begründet.
- Die alte Website wird nicht herabgewürdigt; der Audit nennt Stärken zuerst, dann Probleme.
- Alle übrigen Orchestrator-Regeln aus `/homepage-neu` gelten.
- **Wiederverwendung:** Ein Audit (`04`) jünger als 7 Tage und eine Konkurrenzanalyse (`02`) jünger als 30 Tage
  werden gelesen statt neu erstellt; im Status vermerken. Mit `--neu-analysieren` wird trotzdem neu erstellt.
