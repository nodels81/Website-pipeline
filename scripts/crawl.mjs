#!/usr/bin/env node
/**
 * crawl.mjs — Crawlt eine Website (same-origin, BFS) und extrahiert pro Seite
 * Struktur, Inhalte, SEO-Signale, Technik-Stack, Fonts, Farben, Animations-Bibliotheken.
 * Grundlage für Website-Audit (Bestandsseite) UND Konkurrenzanalyse (Wettbewerber-URLs).
 *
 * Nutzung:
 *   node crawl.mjs <url> [--max 20] [--out ./analyse/<slug>] [--depth 2] [--viewport desktop|mobile]
 *
 * Ausgabe:
 *   <out>/crawl.json          — Rohdaten aller Seiten
 *   <out>/crawl-summary.md    — Lesbare Zusammenfassung für die Agenten
 */
import path from 'node:path';
import {
  parseArgs, normalizeUrl, slugFromUrl, ensureDir, writeJson, writeText,
  launchBrowser, newContext, autoScroll, dismissCookieBanner, gotoSafe,
} from './_lib.mjs';

const args = parseArgs(process.argv.slice(2));
if (!args._[0]) {
  console.error('Nutzung: node crawl.mjs <url> [--max 20] [--out dir] [--depth 2] [--viewport desktop|mobile]');
  process.exit(1);
}

const startUrl = normalizeUrl(args._[0]);
const origin = new URL(startUrl).origin;
const maxPages = Number(args.max || 20);
const maxDepth = Number(args.depth || 2);
const slug = slugFromUrl(startUrl);
const outDir = ensureDir(path.resolve(args.out || path.join('analyse', slug)));
const viewport = args.viewport || 'desktop';

const SKIP_EXT = /\.(pdf|jpe?g|png|gif|webp|avif|svg|zip|rar|mp4|mp3|webm|docx?|xlsx?|pptx?|ics|xml|json|css|js)(\?|#|$)/i;
const SKIP_PATH = /\/(wp-admin|wp-login|cart|checkout|login|logout|account|feed|tag|author)(\/|$)/i;

function shouldVisit(href, depth) {
  try {
    const u = new URL(href, startUrl);
    if (u.origin !== origin) return false;
    if (SKIP_EXT.test(u.pathname) || SKIP_PATH.test(u.pathname)) return false;
    if (depth > maxDepth) return false;
    return true;
  } catch { return false; }
}

function canonicalKey(href) {
  const u = new URL(href, startUrl);
  u.hash = '';
  // Tracking-Parameter entfernen
  for (const p of [...u.searchParams.keys()]) if (/^(utm_|fbclid|gclid|ref$)/i.test(p)) u.searchParams.delete(p);
  let s = u.toString();
  if (s.endsWith('/') && u.pathname !== '/') s = s.slice(0, -1);
  return s;
}

/** Wird im Browser-Kontext ausgeführt: extrahiert alles Relevante aus dem DOM. */
const EXTRACT = () => {
  const q = (sel) => Array.from(document.querySelectorAll(sel));
  const txt = (el) => (el?.textContent || '').replace(/\s+/g, ' ').trim();
  const meta = (name) => document.querySelector(`meta[name="${name}"]`)?.content
    || document.querySelector(`meta[property="${name}"]`)?.content || null;

  const visible = (el) => {
    const r = el.getBoundingClientRect();
    const cs = getComputedStyle(el);
    return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none' && cs.opacity !== '0';
  };

  // Textkörper
  const main = document.querySelector('main') || document.body;
  const bodyText = txt(main);
  const words = bodyText.split(/\s+/).filter(Boolean).length;

  // Überschriften
  const headings = {};
  for (const h of ['h1', 'h2', 'h3']) headings[h] = q(h).map(txt).filter(Boolean).slice(0, 40);

  // CTAs / Buttons
  const ctaSel = 'a.btn, a.button, button, [role="button"], a[class*="btn"], a[class*="button"], a[class*="cta"], input[type="submit"]';
  const ctas = q(ctaSel).filter(visible).map((el) => txt(el) || el.value || el.getAttribute('aria-label') || '').filter((t) => t && t.length < 60);
  const ctaCounts = {};
  for (const c of ctas) ctaCounts[c] = (ctaCounts[c] || 0) + 1;

  // Navigation
  const navLinks = q('nav a, header a').filter(visible).map((a) => ({ text: txt(a), href: a.href })).filter((l) => l.text).slice(0, 60);

  // Bilder & Alt-Texte
  const imgs = q('img');
  const imgsWithAlt = imgs.filter((i) => (i.getAttribute('alt') || '').trim().length > 0).length;
  const lazyImgs = imgs.filter((i) => i.loading === 'lazy').length;
  const modernFormats = imgs.filter((i) => /\.(webp|avif)(\?|$)/i.test(i.currentSrc || i.src || '')).length
    + q('picture source[type="image/webp"], picture source[type="image/avif"]').length;
  const videos = q('video').length;
  const svgInline = q('svg').length;

  // Formulare
  const forms = q('form').map((f) => ({
    action: f.getAttribute('action'),
    fields: q('input, select, textarea').filter((i) => f.contains(i) && i.type !== 'hidden').length,
  }));

  // Links
  const allLinks = q('a[href]').map((a) => a.href).filter(Boolean);
  const internal = allLinks.filter((h) => { try { return new URL(h).origin === location.origin; } catch { return false; } });
  const external = allLinks.filter((h) => { try { const u = new URL(h); return u.origin !== location.origin && /^https?:/.test(u.protocol); } catch { return false; } });

  // Strukturierte Daten
  const jsonLdTypes = q('script[type="application/ld+json"]').flatMap((s) => {
    try {
      const d = JSON.parse(s.textContent);
      const arr = Array.isArray(d) ? d : (d['@graph'] || [d]);
      return arr.map((x) => x['@type']).flat().filter(Boolean);
    } catch { return ['(ungültiges JSON-LD)']; }
  });

  // Technik-Erkennung
  const html = document.documentElement.outerHTML;
  const scripts = q('script[src]').map((s) => s.src);
  const scriptHosts = [...new Set(scripts.map((s) => { try { return new URL(s).hostname; } catch { return null; } }).filter(Boolean))];
  const thirdParty = scriptHosts.filter((h) => h !== location.hostname && !h.endsWith('.' + location.hostname.replace(/^www\./, '')));
  const gen = meta('generator');
  const tech = [];
  const has = (re) => re.test(html) || scripts.some((s) => re.test(s));
  if (gen) tech.push(`generator: ${gen}`);
  if (has(/wp-content|wp-includes/i)) tech.push('WordPress');
  if (has(/elementor/i)) tech.push('Elementor');
  if (has(/divi|et_pb_/i)) tech.push('Divi');
  if (has(/wix\.com|wixstatic/i)) tech.push('Wix');
  if (has(/webflow/i)) tech.push('Webflow');
  if (has(/squarespace/i)) tech.push('Squarespace');
  if (has(/shopify|cdn\.shopify/i)) tech.push('Shopify');
  if (has(/jimdo/i)) tech.push('Jimdo');
  if (has(/typo3/i)) tech.push('TYPO3');
  if (has(/joomla/i)) tech.push('Joomla');
  if (has(/_next\/static|__NEXT_DATA__/i)) tech.push('Next.js');
  if (has(/_nuxt\//i)) tech.push('Nuxt');
  if (has(/astro-island|data-astro/i)) tech.push('Astro');
  if (has(/__sveltekit|svelte/i)) tech.push('Svelte/SvelteKit');
  if (has(/_gatsby|gatsby/i)) tech.push('Gatsby');
  if (has(/framer\.com|framerusercontent/i)) tech.push('Framer');
  if (has(/hubspot/i)) tech.push('HubSpot');
  if (window.jQuery || has(/jquery/i)) tech.push('jQuery');
  if (has(/bootstrap/i)) tech.push('Bootstrap');
  if (has(/tailwind/i) || q('[class*="flex "][class*="items-"]').length > 5) tech.push('Tailwind (vermutlich)');
  if (window.React || has(/react/i)) tech.push('React');
  if (window.Vue || has(/vue/i)) tech.push('Vue');

  // Animations-/Interaktions-Bibliotheken
  const anim = [];
  if (window.gsap || has(/gsap/i)) anim.push('GSAP');
  if (window.ScrollTrigger || has(/ScrollTrigger/i)) anim.push('GSAP ScrollTrigger');
  if (has(/framer-motion|motion\.dev|@motionone/i)) anim.push('Framer Motion / Motion');
  if (window.Lenis || has(/lenis/i)) anim.push('Lenis (Smooth Scroll)');
  if (has(/locomotive-scroll/i)) anim.push('Locomotive Scroll');
  if (window.THREE || has(/three(\.min)?\.js|three\//i)) anim.push('Three.js / WebGL');
  if (has(/lottie|bodymovin/i)) anim.push('Lottie');
  if (has(/swiper/i)) anim.push('Swiper');
  if (has(/slick/i)) anim.push('Slick Slider');
  if (has(/aos\.js|data-aos/i)) anim.push('AOS');
  if (has(/wow\.js|class="wow/i)) anim.push('WOW.js');
  if (has(/splitting|SplitText/i)) anim.push('SplitText/Splitting');
  if (has(/barba/i)) anim.push('Barba.js');
  if (has(/@studio-freight|hamo/i)) anim.push('Studio Freight Stack');
  if (has(/spline/i)) anim.push('Spline 3D');
  if (has(/rive/i)) anim.push('Rive');
  const cssAnimations = q('*').filter((el) => { const cs = getComputedStyle(el); return cs.animationName !== 'none' || (cs.transitionDuration !== '0s' && cs.transitionProperty !== 'all'); }).length;
  let reducedMotion = false;
  try {
    for (const ss of document.styleSheets) {
      try { for (const r of ss.cssRules) if (r.media && /prefers-reduced-motion/.test(r.media.mediaText)) { reducedMotion = true; break; } } catch { /* cross-origin */ }
      if (reducedMotion) break;
    }
  } catch { /* ok */ }
  if (!reducedMotion && /prefers-reduced-motion/.test(html)) reducedMotion = true;

  // Fonts
  const fontOf = (sel) => { const el = document.querySelector(sel); return el ? getComputedStyle(el).fontFamily.split(',')[0].replace(/["']/g, '').trim() : null; };
  const fonts = { heading: fontOf('h1') || fontOf('h2'), body: fontOf('p') || fontOf('body'), button: fontOf('button, a.btn, a.button') };
  const fontFaces = [...new Set(Array.from(document.fonts || []).map((f) => f.family))];
  const googleFonts = q('link[href*="fonts.googleapis.com"]').length > 0;

  // Farben (Häufigkeit sichtbarer Hintergrund-/Textfarben)
  const colorCount = {};
  const addColor = (c) => { if (!c || c === 'rgba(0, 0, 0, 0)' || c === 'transparent') return; colorCount[c] = (colorCount[c] || 0) + 1; };
  for (const el of q('body *').slice(0, 2500)) {
    if (!visible(el)) continue;
    const cs = getComputedStyle(el);
    addColor(cs.backgroundColor); addColor(cs.color);
  }
  const palette = Object.entries(colorCount).sort((a, b) => b[1] - a[1]).slice(0, 14).map(([c, n]) => ({ color: c, count: n }));

  // Layout-Signale
  const sections = q('section, main > div, .section').filter(visible).length;
  const gridLike = q('*').filter((el) => { const cs = getComputedStyle(el); return cs.display === 'grid' && el.children.length >= 3; }).length;
  const cardLike = q('[class*="card"]').filter(visible).length;
  const heroH1 = q('h1')[0];
  const heroSize = heroH1 ? parseFloat(getComputedStyle(heroH1).fontSize) : null;
  const maxWidths = [...new Set(q('main > *, .container, [class*="container"], [class*="wrapper"]').map((el) => getComputedStyle(el).maxWidth).filter((m) => m !== 'none'))].slice(0, 5);
  const cookieBanner = !!document.querySelector('[id*="cookie" i], [class*="cookie" i], #onetrust-banner-sdk, #CybotCookiebotDialog, #usercentrics-root, .borlabs-cookie');
  const chatWidget = !!document.querySelector('[id*="intercom" i], [class*="crisp" i], [id*="tidio" i], [id*="hubspot-messages" i], [class*="chat-widget" i]');

  return {
    title: document.title || null,
    lang: document.documentElement.lang || null,
    metaDescription: meta('description'),
    canonical: document.querySelector('link[rel="canonical"]')?.href || null,
    robots: meta('robots'),
    viewportMeta: meta('viewport'),
    og: { title: meta('og:title'), description: meta('og:description'), image: meta('og:image'), type: meta('og:type') },
    headings,
    h1Count: q('h1').length,
    words,
    textExcerpt: bodyText.slice(0, 1200),
    ctas: Object.entries(ctaCounts).sort((a, b) => b[1] - a[1]).slice(0, 15).map(([text, count]) => ({ text, count })),
    navLinks,
    images: { total: imgs.length, withAlt: imgsWithAlt, lazy: lazyImgs, modernFormat: modernFormats, videos, svgInline },
    forms,
    links: { internal: [...new Set(internal)], externalCount: external.length, externalHosts: [...new Set(external.map((h) => new URL(h).hostname))].slice(0, 20) },
    jsonLdTypes: [...new Set(jsonLdTypes)],
    tech: [...new Set(tech)],
    animationLibs: [...new Set(anim)],
    cssAnimatedElements: cssAnimations,
    reducedMotionSupport: reducedMotion,
    thirdPartyScriptHosts: thirdParty.slice(0, 30),
    scriptCount: scripts.length,
    fonts, fontFaces: fontFaces.slice(0, 12), googleFonts,
    palette,
    layout: { sections, gridLike, cardLike, heroH1: txt(heroH1) || null, heroH1FontSizePx: heroSize, maxWidths, cookieBanner, chatWidget },
    pageHeight: Math.max(document.body.scrollHeight, document.documentElement.scrollHeight),
  };
};

const browser = await launchBrowser(startUrl);
const ctx = await newContext(browser, viewport);
const page = await ctx.newPage();
page.setDefaultTimeout(30000);

const queue = [{ url: startUrl, depth: 0 }];
const seen = new Set([canonicalKey(startUrl)]);
const pages = [];
const errors = [];
let robotsTxt = null, sitemap = null;

try {
  // robots.txt & sitemap.xml
  try {
    const r = await ctx.request.get(new URL('/robots.txt', origin).toString(), { timeout: 10000 });
    robotsTxt = r.ok() ? (await r.text()).slice(0, 2000) : `HTTP ${r.status()}`;
  } catch (e) { robotsTxt = `Fehler: ${e.message}`; }
  try {
    const s = await ctx.request.get(new URL('/sitemap.xml', origin).toString(), { timeout: 10000 });
    sitemap = s.ok() ? { status: s.status(), urls: ((await s.text()).match(/<loc>/g) || []).length } : { status: s.status() };
  } catch (e) { sitemap = { error: e.message }; }

  while (queue.length && pages.length < maxPages) {
    const { url, depth } = queue.shift();
    const t0 = Date.now();
    try {
      const resp = await gotoSafe(page, url);
      if (pages.length === 0) await dismissCookieBanner(page);
      await autoScroll(page, 800, 60);
      const data = await page.evaluate(EXTRACT);
      const finalUrl = page.url();
      const perf = await page.evaluate(() => {
        const nav = performance.getEntriesByType('navigation')[0];
        const res = performance.getEntriesByType('resource');
        const bytes = res.reduce((a, r) => a + (r.transferSize || 0), 0);
        return nav ? { ttfbMs: Math.round(nav.responseStart), domContentLoadedMs: Math.round(nav.domContentLoadedEventEnd), loadMs: Math.round(nav.loadEventEnd), resources: res.length, transferKB: Math.round(bytes / 1024) } : null;
      });
      pages.push({ url, finalUrl, depth, status: resp ? resp.status() : null, contentType: resp ? resp.headers()['content-type'] : null, perf, ...data, ms: Date.now() - t0 });
      console.log(`✓ [${pages.length}/${maxPages}] ${url} (${resp?.status()}, ${data.words} Wörter, ${Date.now() - t0} ms)`);

      for (const href of data.links.internal) {
        if (!shouldVisit(href, depth + 1)) continue;
        const key = canonicalKey(href);
        if (seen.has(key)) continue;
        seen.add(key);
        queue.push({ url: key, depth: depth + 1 });
      }
    } catch (err) {
      errors.push({ url, error: String(err.message || err) });
      console.error(`✗ ${url}: ${err.message || err}`);
    }
  }
} finally {
  await browser.close();
}

// Aggregation
const agg = {
  pagesCrawled: pages.length,
  pagesQueuedNotVisited: queue.length,
  tech: [...new Set(pages.flatMap((p) => p.tech))],
  animationLibs: [...new Set(pages.flatMap((p) => p.animationLibs))],
  reducedMotionAnywhere: pages.some((p) => p.reducedMotionSupport),
  fonts: pages[0]?.fonts || null,
  googleFonts: pages.some((p) => p.googleFonts),
  palette: pages[0]?.palette || [],
  thirdPartyHosts: [...new Set(pages.flatMap((p) => p.thirdPartyScriptHosts))],
  jsonLdTypes: [...new Set(pages.flatMap((p) => p.jsonLdTypes))],
  pagesWithoutMetaDescription: pages.filter((p) => !p.metaDescription).map((p) => p.url),
  pagesWithMultipleH1: pages.filter((p) => p.h1Count > 1).map((p) => p.url),
  pagesWithoutH1: pages.filter((p) => p.h1Count === 0).map((p) => p.url),
  altCoverage: (() => { const t = pages.reduce((a, p) => a + p.images.total, 0); const w = pages.reduce((a, p) => a + p.images.withAlt, 0); return t ? Math.round((w / t) * 100) : null; })(),
  avgWords: pages.length ? Math.round(pages.reduce((a, p) => a + p.words, 0) / pages.length) : 0,
  avgTransferKB: pages.length ? Math.round(pages.reduce((a, p) => a + (p.perf?.transferKB || 0), 0) / pages.length) : null,
  avgTtfbMs: pages.length ? Math.round(pages.reduce((a, p) => a + (p.perf?.ttfbMs || 0), 0) / pages.length) : null,
  topCtas: Object.entries(pages.flatMap((p) => p.ctas).reduce((m, c) => { m[c.text] = (m[c.text] || 0) + c.count; return m; }, {})).sort((a, b) => b[1] - a[1]).slice(0, 12),
  cookieBanner: pages.some((p) => p.layout.cookieBanner),
  chatWidget: pages.some((p) => p.layout.chatWidget),
};

const result = { startUrl, origin, slug, crawledAt: new Date().toISOString(), viewport, robotsTxt, sitemap, summary: agg, pages, errors };
writeJson(path.join(outDir, 'crawl.json'), result);

const md = [];
md.push(`# Crawl-Zusammenfassung: ${origin}`);
md.push(`Stand: ${result.crawledAt} · Seiten: ${agg.pagesCrawled} (nicht besucht: ${agg.pagesQueuedNotVisited}) · Viewport: ${viewport}`);
md.push('');
md.push('## Technik & Stack');
md.push(`- Erkannt: ${agg.tech.join(', ') || 'nichts Eindeutiges'}`);
md.push(`- Animations-Bibliotheken: ${agg.animationLibs.join(', ') || 'keine erkannt'}`);
md.push(`- prefers-reduced-motion berücksichtigt: ${agg.reducedMotionAnywhere ? 'ja' : 'nein'}`);
md.push(`- Drittanbieter-Skripte: ${agg.thirdPartyHosts.join(', ') || 'keine'}`);
md.push(`- Cookie-Banner: ${agg.cookieBanner ? 'ja' : 'nein'} · Chat-Widget: ${agg.chatWidget ? 'ja' : 'nein'}`);
md.push(`- Ø Transfer: ${agg.avgTransferKB ?? '?'} KB · Ø TTFB: ${agg.avgTtfbMs ?? '?'} ms`);
md.push('');
md.push('## Design-Signale (Startseite)');
md.push(`- Fonts: Überschrift „${agg.fonts?.heading}“, Fließtext „${agg.fonts?.body}“, Button „${agg.fonts?.button}“ · Google Fonts: ${agg.googleFonts ? 'ja' : 'nein'}`);
md.push(`- Häufigste Farben: ${agg.palette.slice(0, 8).map((p) => p.color).join(' · ')}`);
if (pages[0]) md.push(`- Hero-H1: „${pages[0].layout.heroH1 || '—'}“ (${pages[0].layout.heroH1FontSizePx ? Math.round(pages[0].layout.heroH1FontSizePx) + 'px' : '?'}) · Sections: ${pages[0].layout.sections} · Grids: ${pages[0].layout.gridLike} · Cards: ${pages[0].layout.cardLike}`);
md.push('');
md.push('## Inhalt & Conversion');
md.push(`- Ø Wörter/Seite: ${agg.avgWords}`);
md.push(`- Häufigste CTAs: ${agg.topCtas.map(([t, n]) => `„${t}“ (${n}×)`).join(', ') || '—'}`);
md.push(`- Formulare: ${pages.reduce((a, p) => a + p.forms.length, 0)}`);
md.push('');
md.push('## SEO-Hygiene');
md.push(`- Alt-Text-Abdeckung: ${agg.altCoverage ?? '?'} %`);
md.push(`- Seiten ohne Meta-Description: ${agg.pagesWithoutMetaDescription.length}`);
md.push(`- Seiten ohne H1: ${agg.pagesWithoutH1.length} · mit mehreren H1: ${agg.pagesWithMultipleH1.length}`);
md.push(`- Strukturierte Daten (JSON-LD): ${agg.jsonLdTypes.join(', ') || 'keine'}`);
md.push(`- robots.txt: ${robotsTxt ? (robotsTxt.startsWith('HTTP') || robotsTxt.startsWith('Fehler') ? robotsTxt : 'vorhanden') : '—'} · sitemap.xml: ${sitemap?.urls != null ? sitemap.urls + ' URLs' : JSON.stringify(sitemap)}`);
md.push('');
md.push('## Seiten');
for (const p of pages) {
  md.push(`### ${p.url}`);
  md.push(`- Status ${p.status} · ${p.words} Wörter · ${p.perf?.transferKB ?? '?'} KB · Tiefe ${p.depth}`);
  md.push(`- Title: ${p.title || '—'}`);
  md.push(`- Description: ${p.metaDescription || '—'}`);
  md.push(`- H1: ${p.headings.h1.join(' | ') || '—'}`);
  if (p.headings.h2.length) md.push(`- H2: ${p.headings.h2.slice(0, 10).join(' | ')}`);
  if (p.ctas.length) md.push(`- CTAs: ${p.ctas.slice(0, 6).map((c) => c.text).join(' | ')}`);
  md.push('');
}
if (errors.length) {
  md.push('## Fehler');
  for (const e of errors) md.push(`- ${e.url}: ${e.error}`);
}
writeText(path.join(outDir, 'crawl-summary.md'), md.join('\n'));
console.log(`\nErgebnis: ${path.join(outDir, 'crawl.json')} und crawl-summary.md`);
