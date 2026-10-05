#!/usr/bin/env node
/**
 * kosten.mjs — Wertet die JSON-Ausgabe von `claude -p --output-format json` aus: gibt das Ergebnis lesbar aus und
 * schreibt Tokens, Dauer und API-Gegenwert ins Log und in ausgang/<slug>/kosten.json.
 * Mit Claude Max/Pro entstehen keine Zusatzkosten; der Dollarwert zeigt den Gegenwert zu API-Preisen.
 *
 * Nutzung: node scripts/kosten.mjs <claude-json-datei> <slug> [eurokurs]
 */
import fs from 'node:fs';
import path from 'node:path';

const [datei, slug, kursArg] = process.argv.slice(2);
const kurs = Number(kursArg || process.env.EUR_PRO_USD || 0.9);
const raw = fs.readFileSync(datei, 'utf8');
let j;
try {
  const start = raw.indexOf('{');
  j = JSON.parse(raw.slice(start));
} catch {
  process.stdout.write(raw);
  console.error('\n(Kostenauswertung: keine JSON-Ausgabe erkannt)');
  process.exit(0);
}
if (j.result) console.log(j.result);
const u = j.usage || {};
const fmt = (n) => (n || 0).toLocaleString('de-DE');
const usd = Number(j.total_cost_usd ?? j.cost_usd ?? 0);
const zeilen = [
  '',
  '── Verbrauch dieses Laufs ─────────────────────────',
  `Eingabe: ${fmt(u.input_tokens)} · aus Cache gelesen: ${fmt(u.cache_read_input_tokens)} · in Cache geschrieben: ${fmt(u.cache_creation_input_tokens)}`,
  `Ausgabe: ${fmt(u.output_tokens)} Tokens`,
  `Dauer: ${Math.round((j.duration_ms || 0) / 60000)} min · Runden: ${j.num_turns ?? '?'}`,
  `API-Gegenwert: ${usd.toFixed(2)} $ ≈ ${(usd * kurs).toFixed(2)} € (Kurs ${kurs}; mit Claude Max keine Zusatzkosten, zählt aufs Kontingent)`,
  'Hinweis: Tokens der Subagenten sind im Gegenwert enthalten; die Token-Zeilen zeigen nur die Hauptsession.',
];
console.log(zeilen.join('\n'));
if (slug) {
  const out = path.join('ausgang', slug);
  fs.mkdirSync(out, { recursive: true });
  const f = path.join(out, 'kosten.json');
  const bisher = fs.existsSync(f) ? JSON.parse(fs.readFileSync(f, 'utf8')) : { laeufe: [] };
  bisher.laeufe.push({ datum: new Date().toISOString(), usd, eur: +(usd * kurs).toFixed(2), dauerMin: Math.round((j.duration_ms || 0) / 60000), usage: u, istFehler: !!j.is_error });
  bisher.summeUsd = +bisher.laeufe.reduce((a, l) => a + (l.usd || 0), 0).toFixed(2);
  bisher.summeEur = +(bisher.summeUsd * kurs).toFixed(2);
  fs.writeFileSync(f, JSON.stringify(bisher, null, 2));
  console.log(`Summe aller Läufe für ${slug}: ${bisher.summeUsd} $ ≈ ${bisher.summeEur} € (ausgang/${slug}/kosten.json)`);
}
