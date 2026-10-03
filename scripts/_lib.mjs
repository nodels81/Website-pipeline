// Gemeinsame Helfer für alle Pipeline-Skripte (ESM, Node >= 18)
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

export const VIEWPORTS = {
  desktop: { width: 1440, height: 900, isMobile: false, deviceScaleFactor: 1 },
  tablet:  { width: 834,  height: 1112, isMobile: true,  deviceScaleFactor: 2, hasTouch: true },
  mobile:  { width: 390,  height: 844,  isMobile: true,  deviceScaleFactor: 3, hasTouch: true },
};

export function parseArgs(argv) {
  const args = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      const next = argv[i + 1];
      if (next === undefined || next.startsWith('--')) { args[key] = true; }
      else { args[key] = next; i++; }
    } else {
      args._.push(a);
    }
  }
  return args;
}

export function normalizeUrl(input) {
  let u = String(input || '').trim();
  if (!u) throw new Error('Keine URL angegeben.');
  if (!/^https?:\/\//i.test(u)) u = 'https://' + u;
  return new URL(u).toString();
}

export function slugFromUrl(url) {
  const { hostname, pathname } = new URL(url);
  const base = (hostname.replace(/^www\./, '') + pathname)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
  return base || 'site';
}

export function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function writeJson(file, data) {
  ensureDir(path.dirname(file));
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
}

export function writeText(file, text) {
  ensureDir(path.dirname(file));
  fs.writeFileSync(file, text, 'utf8');
}

/** Lokale/private Ziele (Preview-Server) werden nie über einen Proxy geladen. */
export function isLocalUrl(url) {
  try {
    const h = new URL(url).hostname.replace(/^\[|\]$/g, '');
    return h === 'localhost' || h === '::1' || h === '0.0.0.0'
      || /^127\./.test(h) || /^10\./.test(h) || /^192\.168\./.test(h)
      || /^172\.(1[6-9]|2\d|3[01])\./.test(h) || h.endsWith('.local');
  } catch { return false; }
}

/**
 * Startet Chromium. Respektiert HTTPS_PROXY (nur für externe Ziele) und PW_EXECUTABLE_PATH.
 * `targetUrl` entscheidet, ob der Proxy gesetzt wird. PW_NO_PROXY=1 erzwingt Direktverbindung.
 */
export async function launchBrowser(targetUrl = null, extra = {}) {
  const proxyServer = process.env.HTTPS_PROXY || process.env.https_proxy;
  const useProxy = !!proxyServer && !(targetUrl && isLocalUrl(targetUrl)) && process.env.PW_NO_PROXY !== '1';
  const executablePath = process.env.PW_EXECUTABLE_PATH || undefined;
  return chromium.launch({
    headless: true,
    executablePath,
    proxy: useProxy ? { server: proxyServer, bypass: 'localhost,127.0.0.1' } : undefined,
    args: ['--disable-dev-shm-usage', '--no-sandbox'],
    ...extra,
  });
}

export async function newContext(browser, viewportName = 'desktop', opts = {}) {
  const vp = VIEWPORTS[viewportName] || VIEWPORTS.desktop;
  return browser.newContext({
    viewport: { width: vp.width, height: vp.height },
    deviceScaleFactor: vp.deviceScaleFactor,
    isMobile: vp.isMobile,
    hasTouch: !!vp.hasTouch,
    locale: 'de-DE',
    timezoneId: 'Europe/Berlin',
    userAgent: vp.isMobile
      ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
      : undefined,
    ignoreHTTPSErrors: false,
    ...opts,
  });
}

/** Scrollt einmal komplett durch die Seite, damit Lazy-Loading und Scroll-Animationen auslösen. */
export async function autoScroll(page, step = 600, delayMs = 120) {
  await page.evaluate(async ({ step, delayMs }) => {
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const max = () => Math.max(document.body.scrollHeight, document.documentElement.scrollHeight);
    let y = 0;
    let guard = 0;
    while (y < max() && guard < 400) {
      y += step;
      window.scrollTo(0, y);
      await sleep(delayMs);
      guard++;
    }
    window.scrollTo(0, 0);
    await sleep(300);
  }, { step, delayMs });
}

/** Versucht gängige Cookie-Banner wegzuklicken (nur für Screenshots/Analyse). */
export async function dismissCookieBanner(page) {
  const selectors = [
    'button:has-text("Alle akzeptieren")', 'button:has-text("Akzeptieren")', 'button:has-text("Zustimmen")',
    'button:has-text("Einverstanden")', 'button:has-text("Accept all")', 'button:has-text("Accept")',
    'button:has-text("I agree")', 'button:has-text("OK")',
    '#onetrust-accept-btn-handler', '.cc-btn.cc-dismiss', '[data-cookiefirst-action="accept"]',
    '#CybotCookiebotDialogBodyLevelButtonLevelOptinAllowAll', '.borlabs-cookie-preference button._brlbs-btn-accept-all',
    '#usercentrics-root button[data-testid="uc-accept-all-button"]',
  ];
  for (const sel of selectors) {
    try {
      const el = page.locator(sel).first();
      if (await el.isVisible({ timeout: 400 })) {
        await el.evaluate((node) => node.click()); // JS-Klick: scrollt nicht, kein Timeout
        await page.waitForTimeout(500);
        return sel;
      }
    } catch { /* weiter */ }
  }
  return null;
}

export async function gotoSafe(page, url, timeout = 45000) {
  const resp = await page.goto(url, { waitUntil: 'domcontentloaded', timeout });
  try { await page.waitForLoadState('networkidle', { timeout: 10000 }); } catch { /* ok */ }
  return resp;
}

export function timestamp() {
  return new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
}
