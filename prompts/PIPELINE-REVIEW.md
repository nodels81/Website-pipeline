# Prompt: Review und Überarbeitung der Website-Pipeline

> Nutzung: In einer **neuen** Claude-Code-Sitzung im Repository `Website-pipeline` den Befehl `/pipeline-review`
> eingeben, oder diesen Text als erste Nachricht einfügen. Empfohlen: Opus, hohe Denktiefe, keine anderen Aufgaben in
> derselben Sitzung. Phase A ändert nichts, Phase B erst nach Freigabe.

---

## Rolle

Du bist Principal Engineer für LLM-Agentensysteme mit Erfahrung in Kostenoptimierung (Token, Modellwahl, Caching),
Prompt-Design und Qualitätssicherung von Agenten-Workflows. Zugleich hast du das Urteil eines Agenturleiters, der weiß,
was eine Website für einen kleinen Betrieb wirklich verkaufen muss. Du bist dem System gegenüber **unvoreingenommen**:
Es wurde schnell gebaut, vieles ist plausibel formuliert, aber nicht gemessen. Deine Aufgabe ist, Nutzen von
Aufwand zu trennen.

## Ziel

Die Pipeline soll **mindestens gleich gute, eher bessere Websites** liefern und dabei **deutlich weniger Tokens, Zeit
und Geld** verbrauchen. Ergebnis ist ein belegter Review-Bericht mit einer schlanken Zielarchitektur und einem
umsetzbaren Migrationsplan.

## Kontext (Stand bei Erstellung dieses Prompts)

- Das Repository enthält: 13 Subagenten (`.claude/agents/`, zusammen ca. 70 KB Anweisungen), 5 Skills
  (`.claude/skills/`, Orchestrierung), 15 Artefakt-Vorlagen (`pipeline/artefakte/`, ca. 35 KB), Checklisten
  (`checklisten/`), Referenzen (`referenzen/`), Sparprofile (`pipeline.config.json`, `pipeline/LESEREGELN.md`),
  Skripte (`scripts/`: Screenshots, Crawl, Design-Tokens, Lighthouse, Bildbestand, Paketierung, Deploy, Kosten) und
  Startskripte (`run.sh`, `run.ps1`). Überblick: `README.md`, `CLAUDE.md`, `pipeline/PIPELINE.md`.
- **Erfahrung aus dem ersten echten Lauf (DELATEC, Kfz-Smart-Repair, Modus „verbessern“):**
  - Konzeptphase rund 2 Stunden, Build und QA weitere Stunden, mit Unterbrechung und Fortsetzung. Fast alle Agenten
    liefen auf Opus, 8 Wettbewerber, 3 Best-in-Class, Dunkelmodus-Screenshots.
  - Formal gut: QA ohne Blocker, Unikat-Prüfung 86/100.
  - **Inhaltlich enttäuschend:** Die Seite wirkte kühl und wenig vertrauenswürdig, zu wenige Fotos der beiden Inhaber,
    zu wenig Persönlichkeit. Darauf wurden nachträglich Bildbestand, „Menschen zuerst“, eine Vertrauens-Dimension und
    der Agent `kundentester` ergänzt. Prüfe, ob diese Ergänzungen das Problem an der Wurzel lösen oder nur ein weiteres
    Prüf-Pflaster sind.
  - 30 Annahmen im Briefing, Schriftlizenz ungeprüft, Formular-Endpunkt fehlte, Kundenlieferungen offen.
- Verbrauchsdaten: Falls vorhanden, `ausgang/*/kosten.json` und `ausgang/*/pipeline.log` auswerten. Sie erfassen
  bisher nur die Gesamtkosten eines Laufs, nicht die Kosten je Agent.
- Preise (API-Gegenwert je 1 Mio. Tokens): Opus Eingabe 4 $, Ausgabe 20 $, Cache-Lesen 0,20 $; Sonnet 2 $ / 10 $ /
  0,20 $. Ausgabe-Tokens kosten das Fünffache der Eingabe. Der Nutzer hat Claude Max, zahlt also mit Kontingent und
  Wartezeit statt mit Euro. Beides soll sinken.

## Arbeitsweise

- **Phase A: nur lesen, messen, bewerten.** Nichts ändern. Jede Aussage mit Fundstelle (`datei:zeile`) oder Messwert.
- Lies die Dateien selbst. Starte höchstens drei Subagenten und nur für klar abgegrenzte Lesearbeit. Der Review soll
  selbst nicht teuer sein.
- Unterscheide strikt: **gemessen**, **aus dem Code abgeleitet**, **Schätzung** (mit Rechenweg).
- Kein Schönreden der bisherigen Arbeit, aber auch kein Abriss um des Abrisses willen. Was nachweislich trägt, bleibt.

## Prüfaufträge

### 1. Inventar und Datenfluss
Liste jeden Baustein (Agent, Skill, Skript, Vorlage, Checkliste, Referenz, Konfiguration) mit Zweck, Ein- und
Ausgaben, Modell und Aufrufhäufigkeit pro Lauf. Zeichne den tatsächlichen Datenfluss: Wer liest was, wer schreibt was,
was liest danach niemand mehr?

### 2. Kostenmodell
Schätze für einen typischen Lauf je Phase und je Agent: Eingabe-, Cache- und Ausgabe-Tokens, Bilder, Laufzeit,
Wiederholungen durch Schleifen. Begründe den Rechenweg (Größe der Anweisungen, gelesene Artefakte, geschriebene
Artefakte, Zahl der Tool-Aufrufe, Bildanzahl). Benenne die fünf größten Kostentreiber mit Anteil am Gesamtverbrauch.

### 3. Nutzen je Baustein
Bewerte jeden Baustein: Welchen Einfluss hat er nachweisbar auf die Qualität der fertigen Website (Vertrauen,
Verständlichkeit, Conversion, Eigenständigkeit, Technik)? Was würde fehlen, wenn man ihn streicht? Ordne ein:
**behalten**, **verkleinern**, **zusammenlegen**, **durch Skript ersetzen**, **nur auf Wunsch**, **streichen**, **fehlt**.

### 4. Hypothesen, die du prüfen sollst (nicht übernehmen, belegen oder widerlegen)
1. **Ein langer Orchestrator-Lauf ist das teuerste Muster.** Ein einziger `claude -p`-Aufruf trägt über Stunden einen
   wachsenden Kontext. Phasen als getrennte, zustandslose Aufrufe (Zustand nur in Dateien, gesteuert von
   `run.sh`/`run.ps1`) wären billiger, robuster und leichter fortzusetzen.
2. **Zu viel Prosa, zu viele Tabellen.** Die Vorlagen erzeugen sehr lange Artefakte. Ausgabe-Tokens sind teuer, und
   vieles davon liest später niemand. Prüfe je Abschnitt, ob ein Folgeagent ihn nutzt.
3. **Drei voll ausgearbeitete Konzeptrichtungen** sind im Automatik-Modus Verschwendung, weil nur eine gebaut wird.
   Skizzen von wenigen Zeilen könnten reichen.
4. **Drei Headline-Varianten pro Section** im Copy-Deck verdreifachen die teuerste Ausgabe ohne klaren Nutzen.
5. **Zu viele Prüfinstanzen mit Überschneidung:** `unikat-pruefer` (zweimal), `kundentester` (zweimal), `qa-reviewer`
   (mehrere Runden). Prüfe, ob eine kombinierte Prüfung mit klaren Kriterien reicht und wo Prüfungen billiger als
   Skript laufen können (Platzhalter-Scan, Copy-Abgleich, Links, Lighthouse, Kontraste, horizontales Scrollen).
6. **Design-Trends werden pro Projekt neu recherchiert**, obwohl sie für alle Projekte gleich sind. Eine monatlich
   gepflegte Trend-Basis plus projektbezogene Nachfrage-Recherche wäre günstiger.
7. **Die Konkurrenzanalyse ist überdimensioniert** (Crawls, Screenshots, Lighthouse je Wettbewerber). Prüfe, welche
   Messwerte in Entscheidungen einfließen und welche nur Tabellen füllen.
8. **`motion-designer` und `art-director`** könnten ein Agent sein; ebenso `briefing-agent` als Teil des Orchestrators.
9. **Die Grundhaltung „anders als alle“ hat das Vertrauensproblem verursacht.** Prüfe, ob Positionierung, Rote Liste
   und Unikat-Raster eigenständige, aber kühle Ergebnisse systematisch begünstigen, und ob die neuen Vertrauensregeln
   früh genug greifen (bei der Positionierung statt erst in der Prüfung).
10. **Sparprofile und Lese-Regeln sind schwer durchsetzbar.** Agenten können sie ignorieren, und niemand misst es.
    Prüfe, ob einfachere, harte Mechanismen besser wären (kürzere Vorlagen, Kurzfassung als eigene Datei,
    Modellvorgabe im Skript statt im Prompt).
11. **Die Agentenanweisungen sind lang und teils redundant** (Regeln wiederholt in CLAUDE.md, Skills, Agenten,
    Checklisten). Prüfe, was gemeinsame Bausteine sein können und was aktuelle Modelle ohnehin richtig machen.
12. **Gates im Automatik-Modus sind Formsache.** Prüfe, ob ein einziger menschlicher Entscheidungspunkt (z. B. Richtung
    und Bildauswahl vor dem Build) mehr Qualität pro Euro bringt als jede automatische Prüfschleife.
13. **Es fehlt Messung je Agent.** Schlage vor, wie Tokens und Dauer pro Agent erfasst werden (z. B. Ausgabe im Format
    `stream-json` mit Zuordnung zu Subagenten, oder ein Aufruf pro Phase).

### 5. Qualität des Ergebnisses
Wo entscheidet sich, ob eine Website vertrauenswürdig, persönlich und verkaufsstark wird? Welche Eingaben fehlen dafür
systematisch (echte Fotos, Zitate, Preise, Belege), und wie holt die Pipeline sie früher und billiger ein (z. B. eine
gezielte Liste an den Kunden statt 30 Annahmen)? Ist der Kurzbrief der richtige Eingang?

### 6. Robustheit und Bedienung
Windows/PowerShell, Fortsetzen nach Abbruch, parallele Läufe, Fehlermeldungen, Zeit bis zum ersten sichtbaren
Ergebnis. Was hat beim echten Lauf Reibung erzeugt?

## Ergebnis von Phase A

Schreibe `pipeline/REVIEW-<JJJJ-MM-TT>.md` mit:

1. **Kurzfassung** (höchstens 15 Zeilen): Kernbefund, größte Hebel, erwartete Einsparung, Qualitätseffekt.
2. **Inventar und Datenfluss** (Tabelle, ein Diagramm in Text).
3. **Kostenmodell** (Tabelle je Phase und Agent, Rechenweg, Top-5-Kostentreiber).
4. **Bewertung je Baustein** (Tabelle: Baustein · Nutzen · Kosten · Urteil · Begründung mit Fundstelle).
5. **Hypothesen 1–13** je mit Urteil *bestätigt / teilweise / widerlegt* und Beleg.
6. **Zielarchitektur v2**: Agenten, Phasen, Modelle, Artefakte, Prüfungen, menschliche Entscheidungspunkte. So schlank
   wie möglich, so viel Skript wie sinnvoll.
7. **Migrationsplan** in einzeln umsetzbaren Schritten, sortiert nach Einsparung pro Aufwand. Je Schritt: was, welche
   Dateien, erwartete Einsparung (Spanne), Qualitätsrisiko, wie geprüft wird.
8. **Prüfverfahren für v2**: ein Vergleichslauf v1 gegen v2 auf demselben Projekt (z. B. DELATEC, nur Konzeptphase),
   gemessen an Kosten, Dauer, Kundentest-Note und einem Blindvergleich der Startseiten.

Dann im Chat höchstens 20 Zeilen: Kernbefund, Top-5-Maßnahmen mit erwarteter Einsparung, offene Fragen an den Nutzer.
**Danach anhalten und auf Freigabe warten.**

## Phase B (nur nach ausdrücklicher Freigabe)

Setze die freigegebenen Schritte des Migrationsplans um, einen nach dem anderen, jeweils mit eigenem Commit. Nach
jedem Schritt: Skripte mit einem lokalen Testprojekt prüfen, Trockenlauf von `run.sh` und `run.ps1`, README, CLAUDE.md
und PIPELINE.md aktualisieren. Keine Kundendaten committen (`projekte/`, `eingang/`, `ausgang/` sind ignoriert).
Zum Schluss den Vergleichslauf aus Abschnitt 8 vorbereiten und den Befehl dafür nennen.

## Regeln

- Deutsch, knapp, Tabellen statt Fließtext, keine Floskeln.
- Keine erfundenen Messwerte. Schätzungen kennzeichnen.
- Qualität der fertigen Website geht vor Einsparung. Jede Kürzung braucht eine Begründung, warum sie das Ergebnis nicht
  verschlechtert, oder ein ehrliches „Risiko: …“.
- Nichts an Kundenprojekten ändern, nichts deployen.
