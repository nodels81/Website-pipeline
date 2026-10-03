# Tech-Stack-Referenz

Standard der Pipeline und begründete Alternativen. Der `frontend-entwickler` wählt in `10-build-spezifikation.md` und
begründet jede Abweichung vom Standard aus Betrieb, Pflege oder Funktion, nie aus Gewohnheit.

## Standard-Stack

| Schicht | Wahl | Warum |
|---|---|---|
| Framework | **Astro 5** | Statische Auslieferung (schnellste LCP), Islands für Interaktion, Content Collections für pflegbare Inhalte, View Transitions eingebaut, Bildoptimierung (`astro:assets`, sharp), kein Client-JS, das nicht gebraucht wird |
| Styling | **Tailwind 4** auf Basis von `design/tokens.css` | Tokens als CSS-Variablen sind die Wahrheit, Tailwind-Theme wird daraus abgeleitet; Default-Palette, -Schatten und -Radien werden **nicht** benutzt (Einheitsbrei-Falle) |
| Choreografie | **GSAP 3 + ScrollTrigger** (seit 2025 inkl. aller Plugins kostenlos, auch kommerziell) | Präzise Timelines, Scrub, Pin, SplitText für Typografie, stabil auf allen Browsern, gutes Cleanup |
| Smooth Scroll | **Lenis** (nur Desktop, nur ohne Reduced Motion) | Leicht, respektiert native Geschwindigkeit, kein Hijacking; auf Touch nativ lassen |
| Seitenübergänge | **View Transitions API** über Astro `<ClientRouter />` | Nativ, performant, einfacher Reduced-Motion-Fallback |
| UI-Micro-Motion | CSS Transitions/Animations mit Tokens; **Motion** (motion.dev) nur, wenn React-Inseln im Einsatz | Kleinste Kosten für Feedback-Animationen |
| 3D / WebGL (Stufe 4–5) | **Three.js** (direkt oder via Threlte/R3F in Inseln), **Spline** für kuratierte Szenen, **Rive** für interaktive Vektor-Animation | Nur mit Asset-Budget und Fallback-Bild; lazy nach LCP |
| Bilder | AVIF + WebP, `srcset`/`sizes`, Dimensionen reserviert, LQIP oder dominante Farbe als Platzhalter | CLS 0, LCP < 2 s |
| Schriften | Selbst gehostet (WOFF2, Subsets, `font-display: swap`, Preload der Display-Schrift) | Datenschutz (keine Google-Server), Performance, Lizenzkontrolle |
| Formulare | Astro Actions oder serverlose Funktion + Transaktions-E-Mail (Resend, Postmark, Brevo) + Honeypot + Zeitprüfung | Funktioniert ohne JS, kein CAPTCHA |
| Analyse | **Plausible**, **Umami** oder **Matomo** (cookielos konfiguriert) | Datenschutzfreundlich, oft ohne Consent-Banner nutzbar (Rechtsprüfung je Fall) |
| Consent (falls Tracking/Drittmedien) | **Klaro** (Open Source) oder Usercentrics/Cookiebot bei Kundenwunsch | Blockiert Skripte bis Zustimmung |
| Hosting | **Cloudflare Pages**, **Netlify**, **Vercel**; bei Datenhoheit: Hetzner + Coolify/Caddy | Git-Deploy, Preview-URLs, CDN, Header-Konfiguration |
| Qualität | `astro check`, ESLint, Prettier, Lighthouse CI (`scripts/audit.sh`), Playwright-Screenshots (`scripts/screenshot.mjs`) | Reproduzierbare QA |

## Wann abweichen?

| Situation | Alternative | Hinweis |
|---|---|---|
| Kunde will Inhalte täglich selbst pflegen, viele Redakteure, Workflows | Headless CMS: **Sanity**, **Storyblok**, **Payload**, **Directus**; Astro bleibt Frontend | Kein Page-Builder-Layout; Komponenten bleiben Design-System-gebunden |
| Bestehendes WordPress mit viel Inhalt muss bleiben | WordPress headless (WPGraphQL) + Astro, oder sauberes Block-Theme ohne Builder | Elementor/Divi als Grundlage ist ausgeschlossen |
| Komplexe App-Logik, Login, Dashboard | **Next.js** oder **SvelteKit** | Nur, wenn echte Anwendungsfälle vorliegen; Marketing-Seiten bleiben statisch |
| Shop | **Shopify** (Hydrogen/Headless) oder **Medusa**, Marketing-Seiten in Astro | Checkout nie selbst bauen |
| Kunde besteht auf No-Code-Pflege ohne Entwickler | **Webflow** mit eigenem Design (keine Templates), GSAP via Custom Code | Performance-Budget und A11y bleiben Pflicht; Einschränkungen dokumentieren |
| Mehrsprachig mit Übersetzungsworkflow | Astro i18n-Routing + CMS mit Locale-Unterstützung | Hreflang, Sprachwechsel barrierefrei |

## Browser-Features (progressive Verbesserung, Verbreitung vom `trend-scout` verifizieren lassen)

- **View Transitions** (same-document breit verfügbar, cross-document in Chrome/Safari): Fallback = sofortiger Wechsel.
- **Scroll-Driven Animations** (CSS `animation-timeline: scroll()/view()`): Fallback = statischer Endzustand oder GSAP.
- **Container Queries**, **`:has()`**, **Popover API**, **Anchor Positioning**, **`text-wrap: balance/pretty`**,
  **`clamp()`-Typografie**, **`color-mix()`/OKLCH**: mit `@supports` absichern.

## Schriftquellen

- Kommerziell mit Charakter: Klim, Grilli Type, Dinamo, Colophon, Commercial Type, Pangram Pangram, Displaay, ABC Dinamo,
  Fontwerk, TypeMates, Schick Toikka, Swiss Typefaces. Web-Lizenz nach Seitenaufrufen oder Domains prüfen.
- Frei mit Charakter (immer selbst hosten): Fontshare (Satoshi, General Sans, Clash), Google Fonts selektiv (Fraunces,
  Instrument Serif, Bricolage Grotesque, Space Grotesk, Syne, Unbounded, Newsreader, Cormorant), Velvetyne, Collletttivo,
  Open Foundry, The League of Moveable Type.
- Nie als Headline ohne Begründung: Inter, Roboto, Open Sans, Montserrat, Poppins, Lato, Arial (siehe Rote Liste).

## Performance-Regeln für Motion im Build

1. LCP-Element (Hero-Headline oder Hero-Bild) wird nie mit `opacity: 0` oder außerhalb des Viewports initialisiert.
2. Nur `transform` und `opacity` im Scroll-Pfad; `will-change` gezielt und wieder entfernen.
3. GSAP erst nach `DOMContentLoaded`, Three.js/Spline erst nach `load` oder bei Sichtbarkeit (`IntersectionObserver`),
   mit Poster-Bild als Fallback.
4. Bildsequenzen: WebP-Frames, ≤ 60 Frames, ≤ 1,5 MB gesamt, oder Video mit `scrub`.
5. Lenis nur bei `(pointer: fine)` und ohne Reduced Motion; `lerp` ≥ 0,1, damit sich Scrollen nicht „schwimmend“ anfühlt.
6. Jede Timeline wird bei View Transition / Navigation aufgeräumt (`ScrollTrigger.getAll().forEach(t => t.kill())`).

## Minimal-Setup (Astro)

```bash
npm create astro@latest build -- --template minimal --typescript strict --no-git --install
cd build
npx astro add tailwind sitemap
npm i gsap lenis
npm i -D prettier prettier-plugin-astro eslint
```

Projektstruktur: `src/styles/tokens.css` (Kopie aus `design/tokens.css`), `src/layouts/Base.astro` (Landmarks, Skip-Link,
Meta-Komponente, Fonts), `src/sections/*` (eine Datei pro IA-Section), `src/components/*` (Inventar aus 06),
`src/motion/{index.ts, reduce.ts, signature-*.ts}`, `src/content/*` (Collections für pflegbare Inhalte),
`public/fonts`, `public/favicons`.
