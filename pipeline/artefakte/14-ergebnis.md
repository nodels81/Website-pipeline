# Ergebnis: {{Unternehmen}} ({{slug}})

Modus: neu / verbessern · Gestartet: {{}} · Fertig: {{}} · Dauer: {{}} · Automatik: ja / nein

## Das Wichtigste in fünf Zeilen
- **Signature Idea:** …
- **Positionierung:** …
- **Gewählte Richtung:** {{A/B/C: Name}} (automatisch gewählt, Alternativen: …)
- **Qualität:** Lighthouse mobil {{Perf}}/{{A11y}}/{{SEO}} · LCP {{}} · CLS {{}} · Unikat {{}}/100 · Kundentest {{}}/10 · QA-Durchläufe {{}}
- **Stand:** fertig gebaut und geprüft / gebaut mit offenen Punkten / abgebrochen in Phase {{}}

## Was im Paket liegt (`ausgang/{{slug}}/`)
| Ordner / Datei | Inhalt |
|---|---|
| `website/` | Produktionsbuild, direkt auf jeden statischen Host hochladbar |
| `quellcode/` | Astro-Projekt (ohne node_modules), `npm install && npm run dev` |
| `dokumentation/` | alle Artefakte 00–13, `briefing.json`, `tokens.css` |
| `vorschau/` | Screenshots aller Viewports (hell/dunkel, mit/ohne Reduced Motion) |
| `{{slug}}.zip` | alles zusammen |

## Ansehen und veröffentlichen
```bash
cd projekte/{{slug}}/build && npm install && npm run preview     # lokal ansehen
bash scripts/deploy.sh {{slug}}            # Vorschau-Deploy (Ziel in pipeline.config.json / Umgebungsvariablen)
bash scripts/deploy.sh {{slug}} --prod     # Produktion
```
Oder `website/` manuell hochladen. Launch-Plan in `dokumentation/12-uebergabe.md`. Deploy-URL (falls erfolgt): {{}}

## Entscheidungen, die automatisch getroffen wurden
| Gate | Entscheidung | Alternativen | So ändern Sie es |
|---|---|---|---|
| 1 Briefing | Annahmen übernommen ({{n}}) | – | Eingabedatei ergänzen, `bash run.sh … --ab briefing` |
| 2 Richtung | {{}} | {{}} | `bash run.sh … --ab konzept --richtung B` |
| 3 Design & Motion | freigegeben nach Unikat-Prüfung {{}}/100 | – | 08/09 anpassen, dann `--ab build` |
| 4 Launch | nicht automatisch | – | `bash scripts/deploy.sh {{slug}} --prod` |

## Annahmen (weil keine Rückfragen möglich waren)
1. …

## Offene Punkte
- QA Soll/Kann: …
- `[Beweis fehlt]`: …
- `[vom Kunden liefern]`: …
- Schriftlizenzen zu kaufen: …
- Shooting-Briefing: siehe `dokumentation/08-design-system.md`

## Verbrauch
- Siehe `kosten.json` im Paket (Tokens, Dauer, API-Gegenwert je Lauf und Summe). Mit Claude Max entstehen keine Zusatzkosten.

## Lücken und Fehler im Lauf
- (Skripte oder Quellen, die nicht erreichbar waren; Phasen, die mit Einschränkung endeten)
