# 10 · Build-Spezifikation: {{Unternehmen}}

Stand: {{Datum}} · Code: `projekte/<slug>/build/` · Preview: `npm run preview` → {{URL}}

## 1. Stack und Begründung
| Baustein | Wahl | Version | Begründung (Betrieb, Pflege, Performance, Motion) | Alternative verworfen weil |
|---|---|---|---|---|
| Framework | Astro | | | |
| Styling | Tailwind + tokens.css | | | |
| Motion | GSAP + ScrollTrigger, Lenis, (Three.js) | | | |
| Inhalte | Content Collections / CMS | | | |
| Formulare | | | | |
| Hosting / Deploy | | | | |
| Analyse / Consent | | | | |

## 2. Projektstruktur
```
build/
├── src/{layouts,components,sections,pages,motion,styles,content,lib}
├── public/{fonts,images,favicons}
└── …
```

## 3. Komponenten ↔ IA-Sections
| Komponente | Datei | Verwendet in (Seite/Section) | Zustände umgesetzt |
|---|---|---|---|

## 4. Datenquellen und Pflege
- Was liegt wo (Markdown, JSON, CMS), wer pflegt was, wie:

## 5. Formular-Backend und Integrationen
- Endpunkt, Dienst, Validierung, Spam-Schutz, E-Mail-Versand, Datenschutz:

## 6. Umgebungsvariablen (`.env.example`)
| Variable | Zweck | Pflicht |
|---|---|---|

## 7. Befehle
```bash
npm ci
npm run dev        # Entwicklung
npm run build      # Produktion → dist/
npm run preview    # lokaler Preview-Server
npm run check      # Astro/TypeScript
npm run qa         # Analyse-Skripte gegen Preview
```

## 8. Performance-Budget und Browser-Matrix
| Budget | Wert | Stand |
|---|---|---|
| JS gesamt (komprimiert) | ≤ 250 KB | |
| Transfer Startseite | ≤ 1,2 MB | |
| Lighthouse mobil | ≥ 90 / A11y ≥ 95 / SEO ≥ 95 | |
- Browser: Chrome, Safari (macOS/iOS), Firefox, Edge (jeweils aktuelle und Vorversion)

## 9. SEO, Rechtliches, Weiterleitungen
- Meta-Komponente, Schema.org, Sitemap, robots, OG-Bilder, 404, Impressum/Datenschutz, 301-Tabelle (Modus B):

## 10. Stand nach Selbstprüfung
| Prüfung | Ergebnis | Datum |
|---|---|---|
| Lighthouse mobil (Perf/A11y/BP/SEO) | | |
| Reduced-Motion-Durchlauf | | |
| Tastatur-Durchlauf | | |
| Konsolenfehler | | |
| Offene `COPY?` | | |

## 11. Bekannte Einschränkungen
