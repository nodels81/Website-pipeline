# Plan v2: unter 10 € pro Website, sichtbar hochwertiger

Stand: 2026-10-05 · Status: **Vorschlag, nicht umgesetzt** · Anlass: erster echter Lauf (DELATEC) war zu teuer für das
Ergebnis und wirkte kühl. Vor der Umsetzung `/pipeline-review` laufen lassen oder diesen Plan direkt freigeben.

## Diagnose v1
- Rund drei Viertel des Verbrauchs flossen in Analysen, 14 lange Dokumente und Prüfberichte, nicht in die Website.
- Zwölf Agenten reichen sich Zusammenfassungen weiter; bei jeder Übergabe geht Gefühl verloren.
- Hochwertige Effekte (WebGL-Überblendungen, Scroll-Erzählungen) werden pro Projekt neu erfunden: teuer, fehleranfällig.
- Kaum Arbeit „mit den Augen“: Prüfer vergeben Punkte, statt die gerenderte Seite gezielt zu verbessern.
- Ein stundenlanger Orchestrator-Lauf schleppt einen wachsenden Verlauf mit.

## Streichen oder stark kürzen
| Baustein | Neu |
|---|---|
| Trend-Recherche pro Projekt | monatlich gepflegte gemeinsame Trend-Basis |
| Konkurrenzanalyse mit Crawls/Lighthouse | 3 Wettbewerber per Suche |
| 3 ausgearbeitete Konzeptrichtungen | 3 Skizzen à 5 Zeilen |
| 3 Headline-Varianten je Section | 1 Text, Varianten nur für den Hero |
| Motion-Konzept als Dokument | Bewegung aus dem Baukasten |
| Unikat-Prüfer + Kundentester + QA-Agent | eine Sichtprüfung auf Screenshots; Technik per Skript |
| Sparprofile, Lese-Regeln, Kurzfassungen | entfallen mit weniger Agenten |

## Zielbild v2
1. **Effekt-Baukasten** (einmalig bauen, testen): WebGL-Bildüberblendungen, verschwimmende Scroll-Übergänge,
   Textenthüllungen, angeheftete Scroll-Geschichten, horizontale Galerien, Vorher-Nachher-Regler, Seitenwechsel.
   Pro Projekt nur mit Schrift, Farbe, Fotos und Texten bestückt. **Offene Entscheidung des Nutzers:** Ist ein eigener
   Baukasten mit der Vorgabe „nichts Vorgefertigtes“ vereinbar? (Eigenes Werkzeug, keine fremden Vorlagen.)
2. **Fotos zuerst:** Kunde liefert Fotos; Skript bearbeitet sie einheitlich (Farbe, Licht, Format).
3. **Ein Gestalter statt zwölf Spezialisten:** ein Opus-Durchgang schreibt ein Konzept von zwei Seiten und baut daraus.
4. **Mit den Augen nachbessern:** Screenshots der eigenen Seite ansehen, zwei Runden verbessern.
5. **Ein menschlicher Entscheidungspunkt:** Vorschau ansehen, drei Sätze Feedback, ein Korrekturdurchgang.
6. **Phasen als getrennte Aufrufe** aus `run.sh`/`run.ps1`, Zustand nur in Dateien, Kosten je Phase in `kosten.json`.

## Budget je Website (Schätzung, API-Gegenwert)
| Schritt | Modell | Gegenwert |
|---|---|---|
| Kurz-Recherche (3 Wettbewerber, Nachfrage) | Sonnet | 0,50 € |
| Konzept (2 Seiten inkl. Startseiten-Texte) | Opus | 1–2 € |
| Bau aus Baukasten, Fotos, Konzept | Opus | 3–4 € |
| 2 Runden Sichtprüfung und Nachbesserung | Opus | 1–2 € |
| Nutzer-Feedback, 1 Korrekturdurchgang | Sonnet | 0,50–1 € |
| **Summe** | | **etwa 6–10 €** |

Einmalig: Aufbau des Baukastens, etwa so viel wie zwei bis drei v1-Läufe.

## Nächste Schritte
1. Entscheidung zum Baukasten (siehe oben).
2. Optional `/pipeline-review` zur Bestätigung der Diagnose mit Belegen.
3. Umsetzung in Schritten; Vergleichslauf v1 gegen v2 am DELATEC-Projekt (Kosten, Dauer, Kundentest-Note, Blindvergleich).
