# Animations-Patterns: Werkzeugkasten, keine Vorlage

Jedes Muster hier ist neutral. Es wird erst durch die Signature Idea zu etwas Eigenem oder es wird verworfen. Pro Muster:
Funktion, Signature-Potenzial, Einheitsbrei-Risiko, Kosten, Reduced-Motion-Alternative, Technik.

| Muster | Funktion | Signature-Potenzial | Einheitsbrei-Risiko | Kosten | Reduced Motion | Technik |
|---|---|---|---|---|---|---|
| **Text-Reveal zeilenweise (Maske)** | Hierarchie | hoch, wenn Easing und Zeilenfall markenhaft sind | mittel (häufig) | gering | sofort sichtbar | GSAP SplitText + clip-path/overflow |
| **Kinetische Typografie** (Gewicht, Breite, Laufweite reagiert auf Scroll/Hover, Variable Font) | Erzählung, Hierarchie | sehr hoch | gering | gering–mittel | statischer Endzustand | CSS `font-variation-settings` + GSAP/Scroll-Timeline |
| **Bild-Reveal (clip-path, Maske, Vorhang)** | Hierarchie, Erzählung | hoch (Form der Maske = Marke) | mittel | gering | sofort sichtbar | GSAP `clipPath`, CSS |
| **Gepinnte Scroll-Sequenz** (Section bleibt stehen, Inhalt wechselt) | Erzählung | sehr hoch | mittel | mittel (Pin-Spacing) | gestapelte Sections ohne Pin | ScrollTrigger `pin` + `scrub` |
| **Horizontale Scroll-Strecke** (Projekte, Prozess) | Erzählung, Orientierung | hoch | mittel | mittel | vertikale Liste | ScrollTrigger pin + x-Translate; Tastatur-Alternative! |
| **Sticky-Stapel (Karten/Abschnitte schieben sich übereinander)** | Hierarchie, Erzählung | mittel | hoch (2023–25 sehr verbreitet) | gering | normale Sections | CSS `position: sticky` + Scale |
| **Scroll-gesteuerte Bild-/Videosequenz** (Produkt dreht, Prozess läuft) | Erzählung | sehr hoch | gering | hoch (Assets) | Standbild + Beschriftung | Canvas-Frames oder `<video>` mit `currentTime`-Scrub |
| **Abschnittsweiser Farb-/Themewechsel beim Scrollen** | Orientierung, Erzählung | hoch | mittel | gering | harte Wechsel | ScrollTrigger `toggleClass` / CSS-Variablen |
| **Parallax (sparsam, 1–2 Ebenen, kleine Amplitude)** | Hierarchie (Tiefe) | gering | sehr hoch | gering | keine | GSAP `yPercent` scrub oder CSS Scroll-Timeline |
| **Seitenübergang** (Element bleibt stehen, Rest wechselt; oder markenhafter Vorhang) | Orientierung | hoch | mittel | gering | sofortiger Wechsel | View Transitions API, `view-transition-name` |
| **Lade-Sequenz / Intro** (≤ 1,2 s, LCP sofort) | Orientierung, Erzählung | hoch | hoch bei Preloadern | gering | keine | GSAP Timeline beim Laden |
| **Menü-Reveal** (Vollbild, gestaffelt, mit Bild) | Orientierung | hoch | mittel | gering | sofort offen | GSAP stagger, `inert` für Rest |
| **Magnetische Buttons / Cursor-Follower** | Feedback | mittel | hoch (Agentur-Klischee) | gering | kein Effekt | pointer-Events, nur `(pointer: fine)` |
| **Eigener Cursor** | Feedback (nur mit Funktion: Zustand „ziehen“, „ansehen“) | mittel | hoch | gering | nativer Cursor | nur Desktop, `cursor: none` vermeiden ohne Ersatz |
| **Hover-Bildspur / Bildwechsel in Listen** (Projektliste zeigt Bild beim Hover) | Hierarchie, Feedback | hoch | mittel | gering–mittel | Bilder statisch sichtbar | GSAP quickTo, Preload |
| **Marquee / Laufband** | Hierarchie (Rhythmus) | gering | sehr hoch | gering | statisch, pausierbar (WCAG 2.2.2) | CSS animation, `animation-play-state` |
| **SVG-Linienzeichnung** (Logo, Plan, Weg) | Erzählung | hoch, wenn Motiv eigen | mittel | gering | fertig gezeichnet | `stroke-dashoffset`, GSAP DrawSVG |
| **Akkordeon / Offenlegung mit Höhe + Inhalt gestaffelt** | Feedback | gering | gering | gering | sofort | GSAP `height: auto` oder CSS `grid-template-rows` |
| **Formular-Feedback** (Fokus-Linie, Erfolgs-Haken, Fehler-Shake sparsam) | Feedback | mittel | gering | gering | Farbe/Text | CSS, kleine GSAP-Timeline |
| **Zahlen-Counter, Typewriter, Partikel, Konfetti** | keine | keine | extrem | – | – | **nicht verwenden** (Rote Liste) |
| **WebGL-Hero** (Shader-Verzerrung, Flüssigkeit, Korn, Material) | Erzählung, Hierarchie | sehr hoch | mittel (Agentur-Look) | hoch | Poster-Bild | Three.js / OGL, lazy nach LCP, Fallback Pflicht |
| **3D-Objekt / Produkt interaktiv** | Erzählung | sehr hoch | gering | hoch | Bilderserie | Three.js, Spline, `<model-viewer>` |
| **Grid-Morph / Layout-Wechsel mit FLIP** | Orientierung | hoch | gering | mittel | sofort | GSAP Flip, View Transitions |
| **Scroll-Fortschritt / Kapitelnavigation** | Orientierung | mittel | gering | gering | statische Navigation | ScrollTrigger `onUpdate`, `IntersectionObserver` |
| **Ton (Toggle, aus per Default)** | Erzählung | hoch | gering | gering | aus | nur mit sichtbarem Schalter |

## Regeln für den Einsatz

1. Pro Website **3–5 Signature-Moments**, der Rest ist ruhig oder nutzt nur Feedback-Muster.
2. Jedes gewählte Muster wird **an die Signature Idea angepasst** (Form der Maske, Richtung, Tempo, Material). Ein
   Standard-Text-Reveal ist noch keine Gestaltung.
3. Muster mit Risiko „hoch/sehr hoch“ brauchen eine schriftliche Begründung im Motion-Konzept oder entfallen.
4. Jedes Muster hat eine Reduced-Motion-Alternative, die **denselben Inhalt** zeigt.
5. Performance zuerst: Scroll-Pfad nur `transform`/`opacity`, Assets budgetiert, LCP nie verzögert.

## Easing-Familien als Charakter

| Charakter | Easing (GSAP) | CSS |
|---|---|---|
| präzise, technisch | `expo.out`, `power4.out` | `cubic-bezier(.16,1,.3,1)` |
| weich, organisch | `power2.inOut`, `sine.inOut` | `cubic-bezier(.45,0,.55,1)` |
| schwer, materialhaft | `power3.out` mit längerer Dauer | `cubic-bezier(.2,.7,.2,1)` |
| lebendig, verspielt | `back.out(1.4)`, `elastic.out(1,.6)` sparsam | `cubic-bezier(.34,1.56,.64,1)` |
| ruhig, redaktionell | `power1.out`, kurze Dauern | `ease-out` |

Eine Familie pro Website, als Tokens dokumentiert (`--ease-out`, `--ease-in-out`, `--ease-signature`).
