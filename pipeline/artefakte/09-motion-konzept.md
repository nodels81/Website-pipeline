# 09 · Motion-Konzept: {{Unternehmen}}

Stand: {{Datum}} · Bewegungsintensität (Briefing): {{1–5}} · Richtung: {{Name}} · Signature Idea: {{Satz}}

## 1. Bewegungscharakter (3 Sätze)
- Tempo · Gewicht · Easing-Familie · Räumlichkeit · Verhältnis Scroll-gesteuert / zeitgesteuert:

## 2. Signature-Moments (3–5)
### SM1: {{Name}}
- Ort · Funktion (Orientierung / Hierarchie / Feedback / Erzählung):
- Ablauf Bild für Bild (Start → Verlauf → Ende):
- Auslöser · Dauer oder Scroll-Strecke · Technik:
- Reduced-Motion-Alternative · Mobile-Variante:
- Performance-Kosten (Layer, Assets in KB) · Risiko:
- Bricht Muster (aus 02): …
*(je Moment wiederholen)*

## 3. Scroll-Choreografie je Section
| Seite / Section | Eintritt (nichts / Übergang / choreografiert) | Bewegt sich | Ruht bewusst | Stagger | Dauer-Token | Easing-Token | Auslösepunkt | Reduced Motion |
|---|---|---|---|---|---|---|---|---|

## 4. Micro-Interactions
| Element | Zustand → Reaktion | Dauer | Easing | Zweck |
|---|---|---|---|---|

## 5. Seitenübergänge und Lade-Sequenz
- Technik (View Transitions / Overlay), was bleibt, was wechselt, Dauer, Fallback:
- Hero-Sequenz (≤ 1,2 s), LCP-Element sofort sichtbar, Preloader (nur wenn nötig, ≤ 800 ms):

## 6. Motion-Tokens (ergänzt in `design/tokens.css`)
```css
:root {
  --dur-fast: ; --dur-base: ; --dur-slow: ; --dur-story: ;
  --ease-out: ; --ease-in-out: ; --ease-signature: ;
  --stagger-base: ; --scroll-start: ;
}
```
```js
// GSAP-Defaults und ScrollTrigger-Konfiguration
```

## 7. Technische Umsetzungsvorgabe
- Bibliotheken mit Begründung · Dateistruktur `src/motion/` · Initialisierungsreihenfolge · Lenis ja/nein · resize /
  visibilitychange / Hydration / Cleanup · Performance-Budget (Layer, Assets, nur transform/opacity):

## 8. Prüfplan für QA
- [ ] Reduced-Motion-Durchlauf: …
- [ ] Tastatur: …
- [ ] 60 fps auf Mittelklasse-Smartphone: …
- [ ] LCP nicht durch Animation verzögert: …
- [ ] Signature-Moments vorhanden: SM1 … SM5

## 9. Offene Punkte
