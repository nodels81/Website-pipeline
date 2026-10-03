#!/usr/bin/env node
/**
 * tokens.mjs — Extrahiert Design-Tokens einer Live-Website:
 * Farbpalette, Typografie-Skala, Abstände, Radien, Schatten, Breakpoints, CSS-Custom-Properties.
 * Dient als Ist-Analyse (Bestandsseite) und als Vergleichsbasis gegen Wettbewerber ("sieht alles gleich aus?").
 *
 * Nutzung:
 *   node tokens.mjs <url> [--out ./analyse/<slug>] [--viewport desktop|mobile]
 *
 * Ausgabe:
 *   <out>/tokens.json, <out>/tokens.md
 */
import path from 'node:path';
import {
  parseArgs, normalizeUrl, slugFromUrl, ensureDir, writeJson, writeText,
  launchBrowser, newContext, autoScroll, dismissCookieBanner, gotoSafe,
} from './_lib.mjs';

const args = parseArgs(process.argv.slice(2));
if (!args._[0]) {
  console.error('Nutzung: node tokens.mjs <url> [--out dir] [--viewport desktop|mobile]');
  process.exit(1);
}
const url = normalizeUrl(args._[0]);
const slug = slugFromUrl(url);
const outDir = ensureDir(path.resolve(args.out || path.join('analyse', slug)));

const EXTRACT = () => {
  const q = (sel) => Array.from(document.querySelectorAll(sel));
  const visible = (el) => { const r = el.getBoundingClientRect(); const cs = getComputedStyle(el); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none'; };
  const count = (map, key, w = 1) => { if (!key) return; map[key] = (map[key] || 0) + w; };
  const top = (map, n = 12) => Object.entries(map).sort((a, b) => b[1] - a[1]).slice(0, n).map(([value, weight]) => ({ value, weight }));

  // Farben nach Fläche gewichten (große Hintergründe zählen mehr)
  const bg = {}, fg = {}, border = {}, accent = {};
  const typo = {};
  const radii = {}, shadows = {}, spacings = {}, maxWidths = {}, letterSpacings = {};
  const transparent = (c) => !c || c === 'rgba(0, 0, 0, 0)' || c === 'transparent';
  const els = q('body *').filter(visible).slice(0, 4000);
  for (const el of els) {
    const cs = getComputedStyle(el);
    const r = el.getBoundingClientRect();
    const area = Math.max(1, Math.min(r.width * r.height, 2_000_000)) / 10000;
    if (!transparent(cs.backgroundColor)) count(bg, cs.backgroundColor, area);
    count(fg, cs.color, 1);
    if (cs.borderTopStyle !== 'none' && !transparent(cs.borderTopColor)) count(border, cs.borderTopColor, 1);
    if (/^(a|button)$/i.test(el.tagName) || el.getAttribute('role') === 'button') {
      if (!transparent(cs.backgroundColor)) count(accent, cs.backgroundColor, 3);
      count(accent, cs.color, 1);
    }
    if (cs.borderTopLeftRadius !== '0px') count(radii, cs.borderTopLeftRadius);
    if (cs.boxShadow !== 'none') count(shadows, cs.boxShadow);
    if (cs.maxWidth !== 'none' && r.width > 300) count(maxWidths, cs.maxWidth);
    if (/^(section|main|article|header|footer)$/i.test(el.tagName) || /section|container|wrapper/i.test(el.className || '')) {
      count(spacings, `${cs.paddingTop} / ${cs.paddingBottom}`);
    }
    if (cs.letterSpacing !== 'normal' && /^h[1-6]$/i.test(el.tagName)) count(letterSpacings, cs.letterSpacing);
  }

  // Typografie-Skala
  for (const sel of ['h1', 'h2', 'h3', 'h4', 'p', 'li', 'a', 'button', 'small', 'blockquote', 'label']) {
    const el = q(sel).find(visible);
    if (!el) continue;
    const cs = getComputedStyle(el);
    typo[sel] = {
      family: cs.fontFamily.split(',')[0].replace(/["']/g, '').trim(),
      sizePx: Math.round(parseFloat(cs.fontSize) * 10) / 10,
      weight: cs.fontWeight,
      lineHeight: cs.lineHeight,
      letterSpacing: cs.letterSpacing,
      transform: cs.textTransform,
      sample: (el.textContent || '').trim().slice(0, 60),
    };
  }

  // Custom Properties auf :root
  const rootVars = {};
  const breakpoints = new Set();
  const fontFaces = new Set();
  const keyframes = [];
  let reducedMotion = false;
  const walk = (rules) => {
    for (const rule of rules) {
      try {
        if (rule.type === CSSRule.STYLE_RULE && /:root|^html$|^body$/.test(rule.selectorText || '')) {
          for (const prop of rule.style) if (prop.startsWith('--')) rootVars[prop] = rule.style.getPropertyValue(prop).trim();
        } else if (rule.type === CSSRule.MEDIA_RULE) {
          const m = rule.media.mediaText;
          const mm = m.match(/\((?:min|max)-width:\s*([\d.]+(?:px|em|rem))\)/g);
          if (mm) mm.forEach((x) => breakpoints.add(x));
          if (/prefers-reduced-motion/.test(m)) reducedMotion = true;
          walk(rule.cssRules);
        } else if (rule.type === CSSRule.FONT_FACE_RULE) {
          fontFaces.add(rule.style.getPropertyValue('font-family').replace(/["']/g, '').trim());
        } else if (rule.type === CSSRule.KEYFRAMES_RULE) {
          keyframes.push(rule.name);
        } else if (rule.cssRules) {
          walk(rule.cssRules);
        }
      } catch { /* cross-origin */ }
    }
  };
  for (const ss of document.styleSheets) { try { walk(ss.cssRules); } catch { /* cross-origin */ } }

  // Dark Mode?
  const darkMode = q('meta[name="color-scheme"]').some((m) => /dark/.test(m.content)) || /prefers-color-scheme:\s*dark/.test(Array.from(document.styleSheets).map((s) => { try { return Array.from(s.cssRules).map((r) => r.cssText).join(''); } catch { return ''; } }).join(''));

  // Bildsprache grob
  const imgs = q('img').filter(visible);
  const bigImgs = imgs.filter((i) => i.getBoundingClientRect().width > 400).length;
  const hasHeroMedia = !!document.querySelector('video, canvas, [class*="hero"] img, header + section img, main > section:first-child img');

  return {
    colors: { background: top(bg), text: top(fg, 8), border: top(border, 6), interactive: top(accent, 8) },
    typography: typo,
    letterSpacingsHeadings: top(letterSpacings, 5),
    radii: top(radii, 6),
    shadows: top(shadows, 5),
    sectionPaddings: top(spacings, 6),
    maxWidths: top(maxWidths, 5),
    rootCustomProperties: rootVars,
    customPropertyCount: Object.keys(rootVars).length,
    breakpoints: [...breakpoints].sort(),
    fontFaces: [...fontFaces],
    keyframes: [...new Set(keyframes)].slice(0, 30),
    reducedMotionSupport: reducedMotion,
    darkModeSupport: darkMode,
    imagery: { visibleImages: imgs.length, largeImages: bigImgs, heroMedia: hasHeroMedia, canvas: q('canvas').length, video: q('video').length },
    viewport: { width: innerWidth, height: innerHeight },
  };
};

const browser = await launchBrowser(url);
try {
  const ctx = await newContext(browser, args.viewport || 'desktop');
  const page = await ctx.newPage();
  await gotoSafe(page, url);
  await dismissCookieBanner(page);
  await autoScroll(page, 800, 60);
  const data = await page.evaluate(EXTRACT);
  const result = { url, slug, extractedAt: new Date().toISOString(), ...data };
  writeJson(path.join(outDir, 'tokens.json'), result);

  const md = [];
  md.push(`# Design-Tokens (Ist-Zustand): ${url}`);
  md.push(`Stand: ${result.extractedAt}`);
  md.push('');
  md.push('## Farben');
  md.push(`- Hintergründe (flächengewichtet): ${data.colors.background.slice(0, 6).map((c) => c.value).join(' · ') || '—'}`);
  md.push(`- Text: ${data.colors.text.slice(0, 5).map((c) => c.value).join(' · ') || '—'}`);
  md.push(`- Interaktiv (Buttons/Links): ${data.colors.interactive.slice(0, 5).map((c) => c.value).join(' · ') || '—'}`);
  md.push(`- Rahmen: ${data.colors.border.slice(0, 4).map((c) => c.value).join(' · ') || '—'}`);
  md.push('');
  md.push('## Typografie');
  md.push('| Element | Schrift | Größe | Gewicht | Zeilenhöhe | Laufweite | Beispiel |');
  md.push('|---|---|---|---|---|---|---|');
  for (const [sel, t] of Object.entries(data.typography)) md.push(`| ${sel} | ${t.family} | ${t.sizePx}px | ${t.weight} | ${t.lineHeight} | ${t.letterSpacing} | ${t.sample.replace(/\|/g, '/')} |`);
  md.push(`- @font-face Familien: ${data.fontFaces.join(', ') || 'keine (Systemfonts oder extern)'}`);
  md.push('');
  md.push('## Form & Raum');
  md.push(`- Radien: ${data.radii.map((r) => r.value).join(', ') || 'keine'}`);
  md.push(`- Schatten: ${data.shadows.length} Varianten${data.shadows[0] ? ` (häufigste: ${data.shadows[0].value})` : ''}`);
  md.push(`- Section-Paddings (oben/unten): ${data.sectionPaddings.map((s) => s.value).join(' · ') || '—'}`);
  md.push(`- Max-Breiten: ${data.maxWidths.map((m) => m.value).join(', ') || '—'}`);
  md.push(`- Breakpoints: ${data.breakpoints.join(', ') || 'keine in erreichbarem CSS'}`);
  md.push('');
  md.push('## System-Reife');
  md.push(`- CSS Custom Properties auf :root: ${data.customPropertyCount}${data.customPropertyCount ? ` (z. B. ${Object.keys(data.rootCustomProperties).slice(0, 8).join(', ')})` : ''}`);
  md.push(`- Keyframe-Animationen: ${data.keyframes.length}${data.keyframes.length ? ` (${data.keyframes.slice(0, 8).join(', ')})` : ''}`);
  md.push(`- prefers-reduced-motion: ${data.reducedMotionSupport ? 'ja' : 'nein'} · Dark Mode: ${data.darkModeSupport ? 'ja' : 'nein'}`);
  md.push(`- Bildsprache: ${data.imagery.visibleImages} sichtbare Bilder (${data.imagery.largeImages} groß), Hero-Medium: ${data.imagery.heroMedia ? 'ja' : 'nein'}, Canvas/WebGL: ${data.imagery.canvas}, Video: ${data.imagery.video}`);
  writeText(path.join(outDir, 'tokens.md'), md.join('\n'));
  console.log(md.join('\n'));
  console.log(`\nGespeichert: ${path.join(outDir, 'tokens.json')} / tokens.md`);
} finally {
  await browser.close();
}
