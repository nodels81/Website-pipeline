# Eingang

Hier kommt rein, was die Pipeline braucht. Eine Datei pro Projekt. Drei Formen sind möglich:

| Datei | Wann | Vorlage |
|---|---|---|
| `meinprojekt.md` mit Kurzbrief | Sie haben zehn Minuten und die wichtigsten Fakten | `VORLAGE-kurzbrief.md` |
| `meinprojekt.md` mit ausgefülltem Fragebogen | Sie wollen maximale Kontrolle | `../fragebogen/fragebogen.md` kopieren und ausfüllen |
| `meinprojekt.md` mit einer URL | Eine bestehende Website soll komplett neu gemacht werden | `VORLAGE-url.md` |

Start:

```bash
bash run.sh eingang/meinprojekt.md          # eine Datei
bash run.sh https://beispiel.de             # direkt eine URL
bash run.sh --alle                          # alle Dateien hier, die noch kein Ergebnis haben
.\run.ps1 eingang\meinprojekt.md           # Windows / PowerShell, Optionen als -Bis, -Ab, -Deploy …
```

Ergebnis: `ausgang/<projekt>/` mit `ERGEBNIS.md`, `website/` (fertiger Build), `quellcode/`, `dokumentation/`,
`vorschau/` und `<projekt>.zip`.

Was fehlt, ergänzt die Pipeline als gekennzeichnete Annahme (Standardwerte in `pipeline.config.json`). Je mehr Sie
angeben, desto weniger muss sie raten. Dateien in diesem Ordner (außer den Vorlagen) werden nicht versioniert, weil
sie Kundendaten enthalten können.
