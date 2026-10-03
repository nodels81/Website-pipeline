# Anti-Einheitsbrei-Checkliste

Verbindlich für `art-director`, `motion-designer`, `texter`, `frontend-entwickler` und Grundlage der Bewertung durch
`unikat-pruefer`. Ziel: Die Website ist **ohne Logo erkennbar** und unterscheidet sich nachweisbar von der
Einheitsbrei-Landkarte aus `02-konkurrenzanalyse.md`.

## Teil 1: Rote Liste (Ausschluss ohne schriftliche Begründung im Design-System)

### Layout und Komposition
- [ ] Hero: zentrierte Headline + Subline + zwei Buttons + Verlaufs-Blob, Stockfoto oder abstraktes 3D-Rendering ohne Bezug
- [ ] Drei- oder Vier-Spalten-Grid „Icon, Titel, zwei Zeilen“ als Standardbaustein
- [ ] Logo-Leiste „Vertrauen uns“ ohne echten Kontext
- [ ] Testimonial-Karussell mit Sternchen und runden Porträts als einzige Beweisform
- [ ] Identische Section-Höhen und -Abstände über die ganze Seite (kein Rhythmus)
- [ ] Alles in Karten mit gleichem Radius, gleichem Schatten, gleichem Innenabstand
- [ ] Zentrierter Text überall; keine bewusste Asymmetrie, kein Raster-Bruch

### Typografie
- [ ] Inter, Roboto, Open Sans, Montserrat, Poppins, Lato oder Arial als Headline-Schrift
- [ ] Nur eine Schriftfamilie in zwei Gewichten ohne Haltung
- [ ] Headlines unter 48 px auf Desktop im Hero (zu wenig Präsenz) oder ohne typografisches Konzept (Laufweite, Zeilenfall,
      Ausrichtung, Mischung)
- [ ] Standard-Laufweite und -Zeilenhöhe des Frameworks unverändert

### Farbe und Oberfläche
- [ ] Lila-blau, türkis-blau oder pink-orange Verlauf als Markenfarbe
- [ ] Reinweiß (#fff) auf Reinschwarz (#000) ohne Tonung, oder umgekehrt
- [ ] Glassmorphism-Karten, Neon-Glow, Border-Gradients als Hauptstil
- [ ] 8 px / 16 px Radius auf jedem Element, Standard-Schatten `0 4px 6px rgba(0,0,0,.1)`
- [ ] Dark Mode als Selbstzweck ohne Markenbezug

### Bild und Medien
- [ ] Stockfotografie: Handschlag, lachende Menschen am Laptop, Großraumbüro mit Pflanzen, Zahnräder, Weltkugel,
      Glühbirne, Zielscheibe
- [ ] KI-Bilder mit erkennbarem „KI-Look“ (Hochglanz, perfekte Symmetrie, sinnlose Details) ohne Nachbearbeitung
- [ ] Isometrische Illustrationen in Lila/Blau
- [ ] Bilder ohne gemeinsame Bearbeitung (Farbe, Korn, Beschnitt) über die ganze Seite

### Bewegung
- [ ] Alles faded beim Scrollen von unten ein (`fade-up` auf jedem Element)
- [ ] Hover-Effekte ohne Bedeutung (Karten heben sich, weil sie es können)
- [ ] Parallax auf allen Bildern
- [ ] Zahlen-Counter, Typewriter-Headline, Konfetti, Partikel-Hintergrund
- [ ] Preloader über 1 s ohne Funktion
- [ ] Bewegung, die bei `prefers-reduced-motion: reduce` nicht abgeschaltet wird

### Text
- [ ] „Willkommen auf unserer Website“, „Herzlich willkommen bei …“
- [ ] „Wir sind ein junges, dynamisches Team“, „Ihr Partner für …“, „Ihr zuverlässiger Partner“
- [ ] „Qualität, Zuverlässigkeit, Kompetenz“, „Innovative Lösungen“, „ganzheitlich“, „maßgeschneidert“, „360 Grad“
- [ ] „Mehr erfahren“ oder „Jetzt starten“ als einziger oder wichtigster CTA
- [ ] Headlines, die die Branche beschreiben statt den Nutzen („Ihre Steuerberatung in Köln“)
- [ ] Substantivketten („Umsetzung von Digitalisierungsstrategien“), Passiv, Füllwörter
- [ ] Behauptungen ohne Beweis (keine Zahl, kein Name, kein Fall, kein Zitat)

### Technik
- [ ] Page-Builder-Layout (Elementor, Divi, WPBakery) oder gekauftes Theme als Grundlage
- [ ] Standard-Tailwind-Look (Default-Farben `slate`/`indigo`, `rounded-xl shadow-lg`, `max-w-7xl mx-auto px-4`)
- [ ] Cookie-Banner, der die Seite blockiert, Chat-Widget, das sich nach drei Sekunden öffnet

## Teil 2: Pflichtmerkmale (müssen nachweisbar vorhanden sein)

- [ ] **Signature Idea** in einem Satz, in `05-positionierung.md` dokumentiert, in Design, Motion und Text wiedererkennbar
- [ ] **Typografische Haltung:** mindestens eine charakterstarke Schrift (eigene Lizenz oder begründete freie Schrift),
      Skala mit Kontrast (Hero ≥ 64 px Desktop oder bewusst gegenteilige Zurückhaltung mit Begründung)
- [ ] **Farbhaltung:** eine dominante Markenfarbe mit Rolle, getönte Neutrale, nachgewiesene Kontraste (≥ 4,5:1 Text,
      ≥ 3:1 UI), Begründung aus Marke und Abgrenzung
- [ ] **Eigenes Raster und Rhythmus:** bewusste Variation von Section-Höhe, Dichte, Ausrichtung; mindestens ein Rasterbruch
- [ ] **Bildkonzept:** definierter Stil (Fotografie, Illustration, 3D, Typografie als Bild), Bearbeitungsregeln,
      Shooting-Briefing falls nötig
- [ ] **Drei bis fünf Signature-Moments** in der Bewegung, jeder mit Funktion (Orientierung, Hierarchie, Feedback,
      Erzählung) und Reduced-Motion-Alternative
- [ ] **Konkrete Beweise** auf der Startseite: Zahlen, Namen, Fälle, Zitate, Auszeichnungen, Prozesse
- [ ] **Spezifische Sprache:** Headlines mit Nutzen oder Haltung, Verben, Beispiele; Tonalität aus drei Adjektiven
      hörbar
- [ ] **Mindestens eine unerwartete, aber begründete Entscheidung** (Navigation, Hero, Interaktion, Struktur), die
      kein Wettbewerber hat

## Teil 3: Bewertung durch `unikat-pruefer` (0–100)

| Dimension | Gewicht | Frage |
|---|---|---|
| Unterscheidbarkeit | 25 | Ohne Logo erkennbar? Weicht von ≥ 80 % der Einheitsbrei-Landkarte ab? |
| Konsistenz zur Signature Idea | 20 | Ziehen Typografie, Farbe, Layout, Bewegung und Text am selben Strang? |
| Begründungstiefe | 15 | Hat jede Hauptentscheidung einen Grund aus Marke, Zielgruppe oder Abgrenzung? |
| Bewegungsqualität | 15 | Funktion statt Dekoration? Signature-Moments vorhanden? Reduced Motion gelöst? |
| Sprachqualität | 15 | Keine Floskeln, konkrete Beweise, hörbare Tonalität? |
| Handwerk | 10 | Typografische Details, Kontraste, Rhythmus, Zustände, Fehlerfälle? |

- **≥ 90:** Freigabe.
- **80–89:** Freigabe mit benannten Pflichtkorrekturen im nächsten Schritt.
- **< 80:** Zurück in die Überarbeitung mit konkreter Änderungsliste (was, warum, Vorschlag).

Jeder Abzug wird mit Fundstelle (Datei, Abschnitt, Zitat) und konkretem Gegenvorschlag dokumentiert.
