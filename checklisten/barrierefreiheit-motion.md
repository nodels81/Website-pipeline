# Barrierefreiheit und Bewegung

Premium bedeutet: Bewegung, die alle nutzen können. Diese Checkliste gilt für `motion-designer`, `frontend-entwickler`
und `qa-reviewer`. Rechtlicher Rahmen in Deutschland: **BFSG** (seit 28.06.2025, B2C-Dienstleistungen, Ausnahme
Kleinstunternehmen) verlangt EN 301 549, also mindestens **WCAG 2.1 AA**; wir arbeiten nach **WCAG 2.2 AA**.

## Grundregeln für Bewegung

1. **Jede Animation hat genau eine Funktion:** Orientierung (wo bin ich, woher komme ich), Hierarchie (was ist
   wichtig), Feedback (was habe ich ausgelöst), Erzählung (was passiert als Nächstes). Dekoration ohne Funktion wird
   gestrichen.
2. **`prefers-reduced-motion: reduce` wird immer respektiert.** Für jede Animation existiert eine ruhige Alternative:
   Opacity-Wechsel statt Bewegung, Sofortzustand statt Übergang, Standbild statt Video, kein Smooth Scroll, keine
   Parallaxe, keine automatischen Karussells.
3. **Keine Bewegung über 5 Sekunden ohne Pause-/Stopp-Möglichkeit** (WCAG 2.2.2). Autoplay-Video stumm, pausierbar,
   mit Standbild-Alternative.
4. **Kein Blitzen** über 3 Mal pro Sekunde (WCAG 2.3.1). Keine großflächigen Flashes, Strobe, schnelle Farbwechsel.
5. **Scroll-Hijacking ist verboten.** Smooth Scroll (Lenis) nur mit nativer Scrollgeschwindigkeit, abschaltbar, nicht
   bei Reduced Motion, nie mit „Snap“, das die Nutzerin festhält. Scrollbare Bereiche bleiben mit Tastatur erreichbar.
6. **Bewegung darf Lesbarkeit nicht stören:** Text animiert nur beim Erscheinen, nicht während des Lesens.
   Hintergrundbewegung hinter Text ist zu reduzieren (Kontrast ≥ 4,5:1 in jedem Zustand).
7. **Dauer und Easing:** UI-Feedback 120–200 ms, Zustandswechsel 200–350 ms, Section-Einblendung 400–800 ms,
   Erzähl-Sequenzen länger, aber durch Scroll gesteuert (Nutzer bestimmt Tempo). Easing aus einer Familie, dokumentiert
   als Tokens.
8. **Performance ist Barrierefreiheit:** Ruckelnde Animation ist schlechter als keine. Nur `transform` und `opacity`
   animieren, GPU-Layer sparsam, keine Layout-Animationen, 60 fps auf einem Mittelklasse-Smartphone.

## Implementierungsmuster

```css
/* Standard: Bewegung an. Reduced Motion: Dauer auf Null, Endzustände bleiben erhalten. */
:root {
  --dur-fast: 160ms;
  --dur-base: 280ms;
  --dur-slow: 600ms;
  --ease-out: cubic-bezier(.2, .7, .2, 1);
  --ease-in-out: cubic-bezier(.65, 0, .35, 1);
}
@media (prefers-reduced-motion: reduce) {
  :root { --dur-fast: 0ms; --dur-base: 0ms; --dur-slow: 0ms; }
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

```js
// GSAP: Reduced Motion zentral behandeln
const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
gsap.defaults({ duration: reduce ? 0 : 0.8, ease: 'power3.out' });
// Jede Timeline: if (reduce) { gsap.set(targets, endState); return; }
```

- Lenis/Smooth Scroll nur initialisieren, wenn `!reduce` und kein Touch-Gerät mit nativer Scroll-Physik.
- View Transitions: `@media (prefers-reduced-motion: reduce) { ::view-transition-group(*) { animation: none; } }`.
- Scroll-Driven Animations (CSS `animation-timeline`) als progressive Verbesserung mit `@supports`.
- Fokus darf durch Animation nie verschwinden: Fokus-Ring über `outline` (nicht `box-shadow` allein), nicht animiert
  ausblenden.
- Bewegte Elemente mit `aria-hidden="true"`, wenn sie rein dekorativ sind; Inhalt bleibt im DOM zugänglich.
- Zustände (geöffnet/geschlossen) über ARIA-Attribute, nicht nur über Position oder Opacity.
- Das LCP-Element startet nie mit `opacity: 0` (sonst verzögert sich LCP um die Animationsdauer).

## Prüfschritte für `qa-reviewer`

- [ ] Browser mit `prefers-reduced-motion: reduce` (Chrome DevTools → Rendering, oder Playwright `reducedMotion:
      'reduce'`) durchscrollen: keine Bewegung außer Opacity, Inhalte vollständig sichtbar, keine leeren Bereiche, die
      auf Scroll-Trigger warten
- [ ] Tastatur-Durchlauf (Tab/Shift+Tab/Enter/Esc): alle animierten Komponenten (Menü, Akkordeon, Modal, Slider)
      bedienbar, Fokus sichtbar, Fokusfalle bei Modal, Esc schließt
- [ ] Screenreader-Stichprobe (VoiceOver/NVDA): animierte Inhalte werden vorgelesen, dekorative nicht
- [ ] Autoplay-Medien: pausierbar, stumm, Standbild-Alternative
- [ ] Performance-Panel: Scroll über die gesamte Startseite ohne Long Tasks, keine Layout-Shifts durch Animation
- [ ] Mobil: keine Hover-only-Zustände, Touch-Scroll nicht gekapert, Lenis deaktiviert oder nativ
- [ ] Kontraste in allen Animationszuständen (Start, Mitte, Ende) ≥ 4,5:1 für Text
