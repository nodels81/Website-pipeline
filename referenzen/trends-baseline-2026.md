# Trend-Baseline (Stand: Oktober 2026)

Ausgangspunkt für den `trend-scout`. **Nicht übernehmen, sondern verifizieren und aktualisieren**: Jeder Punkt braucht
im Trendreport zwei aktuelle Quellen und ein Urteil (relevant / Mode / schadet) für das konkrete Projekt.

## 1. Was Nutzer von Websites erwarten (Nachfrage)

- **Geschwindigkeit und Klarheit zuerst.** Core Web Vitals als Standard: LCP ≤ 2,5 s, INP ≤ 200 ms, CLS ≤ 0,1 am
  75. Perzentil (Google-Schwellen); Premium-Seiten zielen auf LCP ≤ 2,0 s, INP ≤ 150 ms, CLS ≤ 0,05. Dokumentierte
  Zusammenhänge zwischen LCP-Verbesserung und Conversion (zweistellige Prozentwerte in Fallstudien).
- **Transparenz:** Preise oder Preisbeispiele, Ablauf, Dauer, Verfügbarkeit, Antwortzeit. Fehlende Preisinformation ist
  in vielen Dienstleistungsbranchen der häufigste Absprunggrund.
- **Beweise statt Behauptungen:** echte Zahlen, benannte Fälle, Zitate mit Namen, Bewertungen (Google, Branchenportale),
  Zertifikate. Stockfotos und Floskeln senken Glaubwürdigkeit.
- **Selbstbedienung:** Online-Termin, Rückruf in einem Schritt, WhatsApp/Chat mit echter Antwortzeit, Downloads.
- **Mobil zuerst:** Mehrheit der Erstbesuche mobil, oft unterwegs oder abends; Daumenbedienung, kurze Formulare.
- **Barrierefreiheit als Erwartung und Pflicht:** BFSG seit 28.06.2025 (EN 301 549, WCAG 2.1 AA; Ausnahme
  Kleinstunternehmen < 10 Mitarbeitende und ≤ 2 Mio. € Umsatz; Übergangsfristen für Bestand bis 2030). WCAG 2.2 ist
  der sinnvolle Arbeitsstandard.
- **Datenschutz-Sensibilität:** Cookie-Banner nerven; cookielose Analyse und keine Google-Fonts von Google-Servern sind
  Qualitätsmerkmale.
- **KI-Suche verändert Sichtbarkeit:** Antwortmaschinen zitieren klar strukturierte, faktenreiche Seiten (FAQ, Schema.org,
  eindeutige Aussagen). „Answer Engine Optimization“ ergänzt klassisches SEO.

## 2. Design (was ausgezeichnete Websites 2026 prägt)

- **Rückkehr der visuellen Persönlichkeit** als Gegenbewegung zur KI-Gleichförmigkeit: charakterstarke Typografie,
  eigene Bildwelten, Haltung statt Template. Branchenpresse spricht von „Template-Müdigkeit“ und „AI slop“ (Inter, lila
  Verlauf, runde Karten).
- **Kinetische, großformatige Typografie:** Variable Fonts, Schrift, die auf Scroll und Hover reagiert, Text als
  Interface-Architektur. Oversized Headlines, Mischung von Serif und Grotesk, Layering.
- **Gebrochene Raster und Asymmetrie:** bewusste Überlappungen, Rasterbrüche, redaktionelle Layouts statt Karten-Grids.
- **Bewegung mit Zweck:** Backlash gegen „alles faded ein“. Erwartet werden Scroll-Choreografie, Seitenübergänge und
  Micro-Interactions, die Orientierung geben oder erzählen. Motion gilt als Kernkompetenz, nicht als Extra.
- **3D und Immersion selektiv:** WebGL/Three.js-Szenen, Produkt-Viewer, Scroll-Erzählungen (Awwwards-Gewinner 2026
  zeigen browserbasierte 3D-Welten). Für B2B- und Dienstleistungsseiten nur als Akzent, mit Performance-Budget.
- **Taktile, materialhafte Oberflächen:** Körnung, Papier, Metall, „Tactile Brutalism“; getönte Neutrale statt
  Reinweiß; Dark Mode nur mit Markenbezug.
- **Redaktionelle Struktur:** Startseiten erzählen (Problem, Haltung, Beweis, Weg) statt Feature-Listen.
- **Barrierefreiheit und Reduced Motion** als Qualitätsmerkmal sichtbar (Schalter, Erklärung).

## 3. Technik (Browser-Features und Werkzeuge)

- **View Transitions API** (same-document breit, cross-document in Chrome und Safari), **CSS Scroll-Driven Animations**
  (`animation-timeline`), **Container Queries**, **`:has()`**, **Popover**, **Anchor Positioning**, **`text-wrap:
  balance`**: Verbreitung vom `trend-scout` aktuell prüfen (caniuse).
- **GSAP vollständig kostenlos** (alle Plugins) seit der Übernahme durch Webflow 2025: SplitText, ScrollSmoother,
  MorphSVG, Flip für kommerzielle Projekte nutzbar.
- **Astro** als Standard für inhaltsgetriebene Marken-Websites; Next.js/SvelteKit für App-Logik; Webflow/Framer als
  No-Code-Option mit eigenem Design.
- **Bildformate:** AVIF breit unterstützt, WebP als Fallback; `fetchpriority="high"` für LCP-Bild.
- **INP ersetzt FID** seit 2024 als Core Web Vital; Long Tasks > 50 ms und Drittskripte sind die häufigsten INP-Killer.

## 4. Was aus der Mode fällt (Einheitsbrei-Kandidaten)

- Zentrierter Hero mit Verlaufs-Blob und zwei Buttons; Drei-Spalten-Icon-Grids; Glassmorphism; lila-blaue Verläufe;
  isometrische Lila-Illustrationen; Sticky-Stapel-Karten überall; Marquee-Laufbänder; Zahlen-Counter;
  Typewriter-Headlines; Cursor-Follower ohne Funktion; „Bento-Grids“ als Standardlayout; Preloader über 1 s.

## 5. Quellen (Abruf Oktober 2026; vom `trend-scout` zu aktualisieren)

- Figma Resource Library: Top Web Design Trends 2026 — https://www.figma.com/resource-library/web-design-trends/
- Envato Elements: Web design trends 2026 (kinetic type, broken grids, visual personality) — https://elements.envato.com/learn/web-design-trends
- MotionKit: Web Animation Trends 2026 — https://motionkit.io/blog/web-animation-trends-2026
- Fireart Studio: Web Design Trends 2026 (Tactile Brutalism) — https://fireart.studio/blog/the-best-web-design-trends/
- Hon Tran: Best Award-Winning Websites of 2026 — https://www.hontran.dev/blog/best-award-winning-websites-2026
- Shuffle: Why do most AI-generated websites look the same? — https://shuffle.dev/blog/2026/01/why-do-most-ai-generated-websites-look-the-same/
- 925 Studios: AI Slop Web Design Guide 2026 — https://www.925studios.co/blog/ai-slop-web-design-guide
- web.dev: Web Vitals — https://web.dev/articles/vitals
- Wettbewerbszentrale: BFSG gilt ab 28. Juni 2025 — https://www.wettbewerbszentrale.de/barrierefreiheitsstaerkungsgesetz-gilt-ab-28-juni-2025-was-unternehmen-jetzt-wissen-muessen/
- svaerm: Barrierefreie Website Pflicht 2025 (BFSG, EAA, WCAG) — https://svaerm.com/barrierefreie-website-pflicht-2025-bfsg-eaa-wcag/
- Awwwards: Websites mit Motion — https://www.awwwards.com/websites/motion/
