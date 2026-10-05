#!/usr/bin/env node
/**
 * bilder.mjs — Bildbestand einer Website (oder eines lokalen Ordners) einsammeln und als Kontaktbogen zeigen.
 *
 * Eigene Fotos des Kunden (Menschen, Werkstatt, Arbeiten, Orte) sind Kundenmaterial und dürfen auf die neue Website.
 * Dieses Skript lädt sie herunter, listet sie und erzeugt Kontaktbögen (bis zu 36 Fotos pro Bild), damit Agenten den
 * ganzen Bestand mit wenigen Bildern ansehen können.
 *
 * Nutzung:
 *   node bilder.mjs <url> --out projekte/<slug>/assets/bestand [--max 15] [--min 200]
 *   node bilder.mjs --ordner projekte/<slug>/rohdaten/fotos --out projekte/<slug>/assets/kunde
 *
 * Ausgabe in --out:
 *   NNN-<name>.<ext>   heruntergeladene Bilder (nur URL-Modus)
 *   bilder.json        Inventar (Datei, Quelle, Maße, Alt-Text, Seite, Kontext, Position)
 *   bilder.md          Inventar als Tabelle mit leerer Spalte „Motiv“ zum Ausfüllen durch den Agenten
 *   kontaktbogen-1.png … Übersicht, Nummern entsprechen bilder.md
 */
import fs from 'node:fs';
import path from 'node:path';
import {
  parseArgs, normalizeUrl, ensureDir, writeJson, writeText,
  launchBrowser, newContext, autoScroll, dismissCookieBanner, gotoSafe,
} from './_lib.mjs';

const args = parseArgs(process.argv.slice(2));
const outDir = args.out ? path.resolve(args.out) : null;
if (!outDir || (!args._[0] && !args.ordner)) {
  console.error('Nutzung: node bilder.mjs <url> --out <dir> [--max 15] [--min 200]\n       node bilder.mjs --ordner <dir> --out <dir>');
  process.exit(1);
}
ensureDir(outDir);
const MIN = Number(args.min || 200);
const MAX_PAGES = Number(args.max || 15);
const MAX_IMAGES = Number(args['max-bilder'] || 120);
const IMG_EXT = /\.(jpe?g|png|webp|avif|gif)$/i;
const MIME_EXT = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp', 'image/avif': 'avif', 'image/gif': 'gif' };

const COLLECT = (min) => {
  const out = [];
  const pick = (srcset) => {
    if (!srcset) return null;
    const c = srcset.split(',').map((s) => s.trim().split(/\s+/)).filter((p) => p[0]);
    c.sort((a, b) => (parseFloat(b[1]) || 0) - (parseFloat(a[1]) || 0));
    return c[0] ? new URL(c[0][0], location.href).href : null;
  };
  const ctx = (el) => {
    let n = el;
    for (let i = 0; i < 6 && n; i++) {
      const h = n.querySelector && n.querySelector('h1,h2,h3');
      if (h && h.textContent.trim()) return h.textContent.replace(/\s+/g, ' ').trim().slice(0, 80);
      n = n.parentElement;
    }
    return '';
  };
  for (const img of document.querySelectorAll('img')) {
    const r = img.getBoundingClientRect();
    const src = pick(img.getAttribute('srcset') || img.closest('picture')?.querySelector('source')?.getAttribute('srcset')) || img.currentSrc || img.src;
    if (!src || src.startsWith('data:')) continue;
    if ((img.naturalWidth || r.width) < min && (img.naturalHeight || r.height) < min) continue;
    out.push({ src, art: 'img', alt: img.getAttribute('alt') || '', w: img.naturalWidth, h: img.naturalHeight, top: Math.round(r.top + scrollY), kontext: ctx(img) });
  }
  for (const el of document.querySelectorAll('body *')) {
    const bg = getComputedStyle(el).backgroundImage;
    if (!bg || bg === 'none' || !bg.includes('url(')) continue;
    const r = el.getBoundingClientRect();
    if (r.width < min || r.height < min * 0.5) continue;
    for (const m of bg.matchAll(/url\(["']?([^"')]+)["']?\)/g)) {
      if (m[1].startsWith('data:')) continue;
      out.push({ src: new URL(m[1], location.href).href, art: 'hintergrund', alt: el.getAttribute('aria-label') || '', w: Math.round(r.width), h: Math.round(r.height), top: Math.round(r.top + scrollY), kontext: ctx(el) });
    }
  }
  const og = document.querySelector('meta[property="og:image"]')?.content;
  if (og) out.push({ src: new URL(og, location.href).href, art: 'og:image', alt: '', w: 0, h: 0, top: -1, kontext: 'Teilen-Vorschau' });
  const links = [...document.querySelectorAll('a[href]')].map((a) => a.href);
  return { bilder: out, links };
};

async function kontaktbogen(browser, eintraege) {
  const proSeite = 36;
  const dateien = [];
  for (let s = 0; s < eintraege.length; s += proSeite) {
    const teil = eintraege.slice(s, s + proSeite);
    const kacheln = teil.map((e) => {
      const p = path.join(outDir, e.datei);
      const ext = path.extname(p).slice(1).toLowerCase().replace('jpg', 'jpeg');
      let inhalt = '<div class="leer">nicht darstellbar</div>';
      try { if (/^(jpeg|png|webp|avif|gif)$/.test(ext)) inhalt = `<img src="data:image/${ext};base64,${fs.readFileSync(p).toString('base64')}">`; } catch { /* fehlt */ }
      return `<figure>${inhalt}<figcaption><b>${e.nr}</b> ${e.w && e.h ? e.w + '×' + e.h : ''} ${String(e.alt || '').slice(0, 28).replace(/</g, '')}</figcaption></figure>`;
    }).join('');
    const html = `<!doctype html><meta charset="utf-8"><style>
      body{margin:0;padding:12px;background:#fff;font:12px/1.2 system-ui,sans-serif;color:#111}
      .g{display:grid;grid-template-columns:repeat(6,200px);gap:8px}
      figure{margin:0;border:1px solid #ddd}
      img,.leer{width:200px;height:150px;object-fit:cover;display:block;background:#eee}
      .leer{display:flex;align-items:center;justify-content:center;color:#888}
      figcaption{padding:3px 4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
      b{background:#111;color:#fff;padding:0 4px;margin-right:4px}</style><div class="g">${kacheln}</div>`;
    const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1 });
    const page = await ctx.newPage();
    await page.setContent(html, { waitUntil: 'load' });
    const datei = path.join(outDir, `kontaktbogen-${dateien.length + 1}.png`);
    await page.screenshot({ path: datei, fullPage: true });
    await ctx.close();
    dateien.push(path.basename(datei));
  }
  return dateien;
}

function inventarMd(titel, eintraege, boegen) {
  const md = [`# Bildbestand: ${titel}`, '', `Stand: ${new Date().toISOString()} · Bilder: ${eintraege.length} · Kontaktbögen: ${boegen.join(', ') || '—'}`, '',
    'Spalte **Motiv** füllt der sichtende Agent nach Ansicht der Kontaktbögen aus: `Person: <Name/Rolle>`, `Team`, `Werkstatt/Ort`, `Arbeit/Ergebnis`, `Vorher/Nachher`, `Produkt`, `Logo/Grafik`, `Stock (nicht verwenden)`, `unbrauchbar`.', '',
    '| Nr | Datei | Maße | Alt-Text | Seite | Kontext | Position | Motiv |', '|---|---|---|---|---|---|---|---|'];
  for (const e of eintraege) md.push(`| ${e.nr} | ${e.datei} | ${e.w && e.h ? e.w + '×' + e.h : '?'} | ${String(e.alt || '').replace(/\|/g, '/').slice(0, 60)} | ${e.seite || ''} | ${String(e.kontext || '').replace(/\|/g, '/')} | ${e.top >= 0 && e.top < 900 ? 'oben/Hero' : e.top >= 0 ? 'weiter unten' : e.art || ''} | |`);
  return md.join('\n');
}

const browser = await launchBrowser(args._[0] ? normalizeUrl(args._[0]) : null);
try {
  let eintraege = [];
  let titel;
  if (args.ordner) {
    const dir = path.resolve(args.ordner);
    titel = dir;
    const files = fs.readdirSync(dir).filter((f) => IMG_EXT.test(f) || /\.heic$/i.test(f)).sort();
    eintraege = files.map((f, i) => ({ nr: i + 1, datei: path.relative(outDir, path.join(dir, f)), quelle: path.join(dir, f), alt: f, w: 0, h: 0, top: -1, art: 'datei' }));
    // Für den Kontaktbogen relative Pfade auf outDir beziehen
  } else {
    const start = normalizeUrl(args._[0]);
    titel = start;
    const origin = new URL(start).origin;
    const ctx = await newContext(browser, 'desktop');
    const page = await ctx.newPage();
    const queue = [start];
    const seen = new Set([start.replace(/#.*$/, '')]);
    const gefunden = new Map();
    let seiten = 0;
    while (queue.length && seiten < MAX_PAGES) {
      const url = queue.shift();
      try {
        await gotoSafe(page, url);
        if (seiten === 0) await dismissCookieBanner(page);
        await autoScroll(page, 700, 80);
        const { bilder, links } = await page.evaluate(COLLECT, MIN);
        seiten++;
        for (const b of bilder) if (!gefunden.has(b.src)) gefunden.set(b.src, { ...b, seite: new URL(url).pathname });
        for (const l of links) {
          try {
            const u = new URL(l); u.hash = '';
            if (u.origin !== origin || /\.(pdf|zip|jpe?g|png|webp|svg|mp4)$/i.test(u.pathname)) continue;
            const k = u.toString();
            if (!seen.has(k)) { seen.add(k); queue.push(k); }
          } catch { /* ungültig */ }
        }
        console.log(`✓ ${url}: ${bilder.length} Bilder`);
      } catch (e) { console.error(`✗ ${url}: ${e.message}`); }
    }
    let nr = 0;
    for (const b of [...gefunden.values()].slice(0, MAX_IMAGES)) {
      try {
        const r = await ctx.request.get(b.src, { timeout: 20000 });
        if (!r.ok()) continue;
        const ct = (r.headers()['content-type'] || '').split(';')[0];
        if (!ct.startsWith('image/') || ct.includes('svg')) continue;
        const buf = await r.body();
        if (buf.length < 2500) continue; // Icons, Platzhalter, Tracking-Pixel
        nr++;
        const base = path.basename(new URL(b.src).pathname).replace(/\.[a-z0-9]+$/i, '').replace(/[^a-z0-9-]+/gi, '-').slice(0, 40) || 'bild';
        const ext = MIME_EXT[ct] || 'jpg';
        const datei = `${String(nr).padStart(3, '0')}-${base}.${ext}`;
        fs.writeFileSync(path.join(outDir, datei), buf);
        eintraege.push({ nr, datei, quelle: b.src, alt: b.alt, w: b.w, h: b.h, seite: b.seite, kontext: b.kontext, top: b.top, art: b.art, bytes: buf.length });
      } catch { /* Download fehlgeschlagen */ }
    }
    await ctx.close();
    console.log(`Seiten: ${seiten} · Bilder gespeichert: ${eintraege.length}`);
  }
  const boegen = eintraege.length ? await kontaktbogen(browser, eintraege) : [];
  writeJson(path.join(outDir, 'bilder.json'), { quelle: titel, erstellt: new Date().toISOString(), bilder: eintraege, kontaktboegen: boegen });
  writeText(path.join(outDir, 'bilder.md'), inventarMd(titel, eintraege, boegen));
  console.log(`Inventar: ${path.join(outDir, 'bilder.md')} · Kontaktbögen: ${boegen.join(', ') || 'keine'}`);
} finally {
  await browser.close();
}
