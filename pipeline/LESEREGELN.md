# Lese-Regeln zwischen den Agenten

Jedes Artefakt 01–09 beginnt mit **„0. Kurzfassung (für Folgeagenten)“** (höchstens 15 Zeilen). Wenn das aktive Profil
`kurzfassungen: true` hat (sparsam, standard), lesen Agenten vorgelagerte Artefakte nach dieser Tabelle. Im Profil
`premium` wird alles vollständig gelesen.

**V** = vollständig lesen · **K** = nur Abschnitt 0 · **G** = gezielt per Grep/Abschnitt, wenn konkret gebraucht · – = nicht lesen

| Agent ↓ liest → | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 |
|---|---|---|---|---|---|---|---|---|---|
| konkurrenz-analyst | V | – | – | K | – | – | – | – | – |
| trend-scout | V | K | – | K | – | – | – | – | – |
| markenstratege | V | V | V | K | – | – | – | – | – |
| ux-architekt | K | K | V | G | V | – | – | – | – |
| texter | K | G | V | – | V | V | – | – | – |
| art-director | K | V | K | G | V | V | – | – | – |
| motion-designer | K | K | K | – | V | V | – | V | – |
| unikat-pruefer | – | V | – | – | V | K | V | V | V |
| kundentester | K | – | – | – | V | G | G | G | – |
| frontend-entwickler | K | – | – | G | K | V | V | V | V |
| qa-reviewer | – | – | – | – | – | V | V | K | V |

Bildbestand: `assets/bestand/bilder.md` und `assets/kunde/bilder.md` lesen alle gestaltenden Agenten (art-director,
ux-architekt, texter, frontend-entwickler, kundentester); Bilder werden über die Kontaktbögen angesehen, nicht einzeln.

Weitere Spar-Regeln für alle Agenten:

1. **Analyse-Dateien:** Immer zuerst `crawl-summary.md` und `tokens.md` lesen. `crawl.json` nie vollständig, nur gezielt
   per Grep.
2. **Screenshots:** Nur die Bilder öffnen, die für das Urteil nötig sind. Im Sparprofil sind das die Fold-Bilder
   (`desktop-fold.png`, `mobile-fold.png`). Ganzseiten-Bilder nur im Profil `premium`.
3. **Websuche:** Erst Suchergebnisse auswerten, dann nur die aussagekräftigsten Seiten abrufen. Keine Seite zweimal.
4. **Artefakte schreiben:** Tabellen statt Fließtext, keine Wiederholung von Inhalten anderer Artefakte, stattdessen
   Verweis („siehe 02, Abschnitt 4“). Die Kurzfassung zuletzt schreiben, wenn der Rest steht.
5. **Rückmeldung an den Orchestrator:** höchstens die im Agenten genannte Zeilenzahl. Keine Artefakte in die Antwort
   kopieren.
