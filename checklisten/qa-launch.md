# QA- und Launch-Checkliste

Verbindlich für `qa-reviewer`. Jeder Punkt wird mit Ergebnis (bestanden / nicht bestanden / nicht prüfbar) und Beleg
(Messwert, Screenshot, Fundstelle) in `11-qa-protokoll.md` dokumentiert. Nicht bestandene Punkte gehen als Fehlerliste an
`frontend-entwickler`. Launch erst, wenn alle Pflichtpunkte bestanden sind.

## 1. Performance (Pflicht)

| Kennzahl | Ziel mobil | Ziel Desktop | Messung |
|---|---|---|---|
| Lighthouse Performance | ≥ 90 | ≥ 95 | `bash scripts/audit.sh <preview-url>` |
| LCP | ≤ 2,0 s | ≤ 1,5 s | Lighthouse, Web Vitals im Browser |
| CLS | ≤ 0,05 | ≤ 0,05 | Lighthouse |
| INP / TBT | INP ≤ 150 ms, TBT ≤ 150 ms | TBT ≤ 100 ms | Lighthouse (TBT), manuelle Interaktion |
| Transfer Startseite | ≤ 1,2 MB (ohne Video) | ≤ 1,5 MB | `node scripts/crawl.mjs` |
| JavaScript gesamt | ≤ 250 KB komprimiert | ≤ 300 KB | Build-Ausgabe |

- [ ] Hero-Bild/-Video preloaded, Größen reserviert (`width`/`height` oder `aspect-ratio`)
- [ ] Bilder als AVIF/WebP mit `srcset` und `sizes`, unterhalb des Folds `loading="lazy"`
- [ ] Schriften selbst gehostet, `font-display: swap` oder `optional`, Subsets, `preload` für Hauptschrift
- [ ] Kritisches CSS inline, Rest nicht blockierend
- [ ] Animationen nur über `transform`/`opacity` auf dem Hauptpfad, `will-change` sparsam, keine Layout-Trigger im Scroll
- [ ] Drittskripte minimiert, nach Consent geladen, `async`/`defer`
- [ ] Keine Long Tasks > 50 ms beim Laden und Scrollen (Performance-Panel stichprobenartig)

## 2. Barrierefreiheit WCAG 2.2 AA (Pflicht, Details in `barrierefreiheit-motion.md`)

- [ ] Lighthouse Accessibility ≥ 95, axe-core ohne kritische Fehler
- [ ] Kontraste: Text ≥ 4,5:1, großer Text und UI ≥ 3:1, auch auf Bildern und in Dark Mode
- [ ] Vollständige Tastaturbedienung, sichtbarer Fokus (≥ 3:1, nicht nur Farbe), logische Reihenfolge, Skip-Link
- [ ] Alle Bilder mit sinnvollem Alt-Text oder `alt=""` bei Dekoration; Icons mit Label
- [ ] Formulare: Labels, Fehlermeldungen in Text, Autocomplete-Attribute, keine reine Platzhalter-Beschriftung
- [ ] Überschriftenhierarchie korrekt (eine H1 pro Seite), Landmarks (`header`, `nav`, `main`, `footer`)
- [ ] `prefers-reduced-motion` reduziert oder ersetzt jede Animation; kein Autoplay-Video ohne Pause-Möglichkeit
- [ ] Zielgrößen ≥ 24×24 px (WCAG 2.5.8), Abstände zwischen Zielen
- [ ] Zoom auf 200 % ohne Inhaltsverlust, Textabstände anpassbar
- [ ] Sprache im `<html lang>` korrekt, Sprachwechsel markiert
- [ ] Barrierefreiheitserklärung verlinkt, wenn BFSG zutrifft

## 3. Responsivität und Browser

- [ ] Screenshots 320, 390, 768, 1024, 1440, 1920 px: kein horizontales Scrollen, keine abgeschnittenen Inhalte
- [ ] Touch-Ziele, Hover-Zustände haben Touch-Äquivalent, keine hover-only Information
- [ ] Browser: aktuelle Chrome, Safari (macOS/iOS), Firefox, Edge; Safari-spezifisch: `100vh`, Scroll-Snapping,
      Backdrop-Filter, Video-Autoplay
- [ ] Landscape auf Mobil, Tablet-Querformat
- [ ] Dark Mode (falls vorgesehen) in beiden Schemata vollständig

## 4. Inhalt und Konsistenz

- [ ] Alle Texte entsprechen `07-copy-deck.md` (Stichprobe: alle Headlines, alle CTAs, alle Meta-Daten)
- [ ] Keine Platzhalter (Lorem ipsum, „TODO“, Beispielbilder, Dummy-Telefonnummern)
- [ ] Rechtschreibung und Typografie: Anführungszeichen „…“, Gedankenstriche, Apostrophe, geschützte Leerzeichen bei
      Einheiten, keine Trennfehler in Headlines
- [ ] Alle Links funktionieren, externe Links mit `rel="noopener"`, Downloads mit Format und Größe
- [ ] 404-Seite gestaltet, hilfreich, mit Navigation
- [ ] Impressum, Datenschutz, ggf. AGB, Widerruf, Barrierefreiheitserklärung vorhanden und von jeder Seite erreichbar
- [ ] Formulare: Versand getestet, Bestätigung, Fehlerfälle, Spam-Schutz ohne CAPTCHA-Hürde (Honeypot, Zeitprüfung,
      serverseitig), Datenschutzhinweis am Formular

## 5. SEO und Teilen

- [ ] Lighthouse SEO ≥ 95
- [ ] Jede Seite: einzigartiger Title (≤ 60 Zeichen), Description (≤ 155), Canonical, eine H1
- [ ] Strukturierte Daten (Organization/LocalBusiness, Breadcrumb, ggf. Service, FAQ, Product) valide
- [ ] OpenGraph und Twitter-Card mit gestaltetem Bild (1200×630) je Seitentyp
- [ ] `sitemap.xml`, `robots.txt`, keine `noindex` auf Live-Seiten, Staging mit `noindex`
- [ ] Weiterleitungen alter URLs (Modus B): 301-Tabelle vollständig, geprüft
- [ ] Favicon-Set, `manifest.webmanifest`, Theme-Color

## 6. Sicherheit, Datenschutz, Betrieb

- [ ] HTTPS erzwungen, HSTS, Security-Header (CSP mindestens report-only, X-Content-Type-Options, Referrer-Policy,
      Permissions-Policy)
- [ ] Consent-Management vor jedem Tracking; cookielose Analyse bevorzugt; keine Google-Fonts-Einbindung von Google-Servern
- [ ] Keine Secrets im Repository, Umgebungsvariablen dokumentiert
- [ ] Build reproduzierbar (`npm ci && npm run build`), Node-Version festgelegt
- [ ] Monitoring: Uptime, Core Web Vitals (CrUX/Search Console), Formular-Eingänge geprüft
- [ ] Backup- und Rollback-Weg dokumentiert in `12-uebergabe.md`

## 7. Unikat-Prüfung am Ergebnis

- [ ] `unikat-pruefer` bewertet die gerenderte Seite (Screenshots aller Viewports) mit ≥ 80 Punkten
- [ ] Signature-Moments sind im Build vorhanden und funktionieren mit und ohne Reduced Motion
- [ ] Einheitsbrei-Landkarte aus `02-konkurrenzanalyse.md`: kein Muster mit ≥ 60 % Verbreitung ohne Begründung übernommen

## 8. Übergabe

- [ ] `12-uebergabe.md`: Hosting, Deployment, Umgebungsvariablen, Pflegeanleitung, Content-Regeln (Bildgrößen,
      Textlängen, Tonalität), Erweiterungsregeln (neue Section = welche Komponente), Ansprechpartner
- [ ] Kunde hat Zugänge (Hosting, Domain, CMS, Analyse) und eine Einführung erhalten
- [ ] Launch-Plan: Zeitpunkt, DNS-Umstellung, Cache, Suchkonsole, Weiterleitungen, Erfolgskontrolle nach 2 und 6 Wochen
