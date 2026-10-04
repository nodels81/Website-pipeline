#!/usr/bin/env node
/**
 * profil.mjs — Liest das aktive Sparprofil aus pipeline.config.json und gibt es aus.
 *
 * Nutzung:
 *   node scripts/profil.mjs                 aktives Profil als Übersicht (für Orchestrator und Menschen)
 *   node scripts/profil.mjs sparsam         bestimmtes Profil
 *   node scripts/profil.mjs --json [name]   Profil als JSON
 *   node scripts/profil.mjs --wert screenshots [name]   einzelner Wert (für Shell-Skripte)
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const cfg = JSON.parse(fs.readFileSync(path.join(root, 'pipeline.config.json'), 'utf8'));
const args = process.argv.slice(2);
const json = args.includes('--json');
const wertIdx = args.indexOf('--wert');
const wert = wertIdx >= 0 ? args[wertIdx + 1] : null;
const rest = args.filter((a, i) => !a.startsWith('--') && !(wertIdx >= 0 && i === wertIdx + 1));
const name = rest[0] || process.env.PIPELINE_PROFIL || cfg.profil || 'standard';
const p = cfg.profile?.[name];
if (!p) {
  console.error(`Unbekanntes Profil "${name}". Verfügbar: ${Object.keys(cfg.profile || {}).join(', ')}`);
  process.exit(1);
}
if (wert) {
  const v = p[wert];
  console.log(typeof v === 'object' ? JSON.stringify(v) : String(v ?? ''));
} else if (json) {
  console.log(JSON.stringify({ name, ...p }, null, 2));
} else {
  console.log(`Profil: ${name} — ${p.beschreibung}`);
  console.log(`Wettbewerber ${p.wettbewerber} (+${p.bestInClass} Best-in-Class), je ${p.seitenJeWettbewerber} Seiten, Lighthouse für ${p.lighthouseWettbewerber}`);
  console.log(`Screenshots: ${p.screenshots}${p.dunkelmodusScreenshots ? ' + Dunkelmodus' : ''} · Crawl max. ${p.maxSeitenCrawl} Seiten · QA-Viewports ${p.qaViewports}`);
  console.log(`Kurzfassungen zwischen Agenten: ${p.kurzfassungen ? 'ja' : 'nein (Volltext)'} · Unikat-Runden ${p.unikatRunden} · QA-Runden ${p.qaRunden}`);
  console.log('Modelle: ' + Object.entries(p.modelle).map(([a, m]) => `${a}=${m}`).join(', '));
}
