#!/usr/bin/env node
/**
 * screenshot.mjs — Screenshots einer Website in mehreren Viewports (Desktop/Tablet/Mobile oder freie Größen),
 * jeweils "above the fold" und Full-Page, optional Dark-Mode und Reduced-Motion-Modus (für QA-Vergleiche).
 *
 * Nutzung:
 *   node screenshot.mjs <url> [--out ./analyse/<slug>] [--viewports desktop,tablet,mobile]
 *                             [--sizes 320x568,1920x1080] [--dark] [--reduced-motion] [--no-cookie-dismiss]
 *                             [--fold-only] [--dpr 1]
 *
 * Sparsam für Agenten: --fold-only (keine Ganzseiten-Bilder) und --dpr 1 (einfache Auflösung) reduzieren die
 * Bildgröße und damit den Token-Verbrauch, wenn Agenten die Screenshots ansehen.
 *
 * Ausgabe:
 *   <out>/screenshots/<viewport>[-dark][-rm]-fold.png, …-full.png, manifest.json
 */
import path from 'node:path';
import {
  parseArgs, normalizeUrl, slugFromUrl, ensureDir, writeJson, launchBrowser, newContext,
  autoScroll, dismissCookieBanner, gotoSafe, VIEWPORTS,
} from './_lib.mjs';

const args = parseArgs(process.argv.slice(2));
if (!args._[0]) {
  console.error('Nutzung: node screenshot.mjs <url> [--out dir] [--viewports desktop,tablet,mobile] [--sizes 320x568,1920x1080] [--dark] [--reduced-motion]');
  process.exit(1);
}

const url = normalizeUrl(args._[0]);
const slug = slugFromUrl(url);
const outDir = ensureDir(path.resolve(args.out || path.join('analyse', slug)));
const shotDir = ensureDir(path.join(outDir, 'screenshots'));

// Viewports: benannte Presets und/oder freie Größen "BREITExHÖHE"
const targets = [];
for (const v of String(args.viewports || (args.sizes ? '' : 'desktop,tablet,mobile')).split(',').map((s) => s.trim()).filter(Boolean)) {
  if (VIEWPORTS[v]) targets.push({ name: v, preset: v });
}
for (const s of String(args.sizes || '').split(',').map((x) => x.trim()).filter(Boolean)) {
  const m = s.match(/^(\d+)x(\d+)$/i);
  if (m) targets.push({ name: `w${m[1]}`, preset: Number(m[1]) < 700 ? 'mobile' : 'desktop', width: Number(m[1]), height: Number(m[2]) });
}
if (!targets.length) { console.error('Keine gültigen Viewports.'); process.exit(1); }

const schemes = args.dark ? ['light', 'dark'] : ['light'];
const foldOnly = !!args['fold-only'];
const dpr = args.dpr ? Number(args.dpr) : null;
const motions = args['reduced-motion'] ? ['no-preference', 'reduce'] : ['no-preference'];

const browser = await launchBrowser(url);
const manifest = { url, slug, capturedAt: new Date().toISOString(), shots: [] };

try {
  for (const motion of motions) {
    for (const scheme of schemes) {
      for (const t of targets) {
        const opts = { colorScheme: scheme, reducedMotion: motion };
        if (t.width) opts.viewport = { width: t.width, height: t.height };
        if (dpr) opts.deviceScaleFactor = dpr;
        const ctx = await newContext(browser, t.preset, opts);
        const page = await ctx.newPage();
        const t0 = Date.now();
        let status = null;
        const suffix = (scheme === 'dark' ? '-dark' : '') + (motion === 'reduce' ? '-rm' : '');
        try {
          const resp = await gotoSafe(page, url);
          status = resp ? resp.status() : null;
          if (!args['no-cookie-dismiss']) await dismissCookieBanner(page);
          await page.evaluate(() => window.scrollTo(0, 0)); // Klicks können scrollen
          await page.waitForTimeout(800);

          const foldFile = path.join(shotDir, `${t.name}${suffix}-fold.png`);
          await page.screenshot({ path: foldFile, fullPage: false });

          await autoScroll(page);
          await page.waitForTimeout(500);
          let fullFile = null;
          if (!foldOnly) {
            fullFile = path.join(shotDir, `${t.name}${suffix}-full.png`);
            await page.screenshot({ path: fullFile, fullPage: true });
          }

          const pageHeight = await page.evaluate(() => Math.max(document.body.scrollHeight, document.documentElement.scrollHeight));
          const hasHorizontalScroll = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1);
          manifest.shots.push({ viewport: t.name, width: t.width || VIEWPORTS[t.preset].width, scheme, reducedMotion: motion === 'reduce', status, fold: path.relative(outDir, foldFile), full: fullFile ? path.relative(outDir, fullFile) : null, pageHeight, hasHorizontalScroll, ms: Date.now() - t0 });
          console.log(`✓ ${t.name}${suffix}: ${status} (${pageHeight}px hoch${hasHorizontalScroll ? ', HORIZONTALES SCROLLEN!' : ''}, ${Date.now() - t0} ms)`);
        } catch (err) {
          manifest.shots.push({ viewport: t.name, scheme, reducedMotion: motion === 'reduce', status, error: String(err.message || err) });
          console.error(`✗ ${t.name}${suffix}: ${err.message || err}`);
        } finally {
          await ctx.close();
        }
      }
    }
  }
} finally {
  await browser.close();
}

writeJson(path.join(shotDir, 'manifest.json'), manifest);
console.log(`\nScreenshots gespeichert in: ${shotDir}`);
