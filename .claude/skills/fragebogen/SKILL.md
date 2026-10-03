---
name: fragebogen
description: Führt den Premium-Website-Fragebogen interaktiv und blockweise durch (höchstens vier Fragen pro Schritt, mit Antwortvorschlägen), speichert die Antworten als Gesprächsprotokoll und lässt daraus vom briefing-agent das Briefing erzeugen. Einsetzen, wenn ein Kunde oder Nutzer die Informationen für eine neue Website liefern soll.
argument-hint: "[projektname] [--datei <pfad-zu-ausgefuelltem-fragebogen>] [--kurz]"
disable-model-invocation: false
---

# /fragebogen – Briefing-Gespräch

Argumente: `$ARGUMENTS`

## Ablauf

1. **Projekt bestimmen:** Projektname aus den Argumenten (Slug bilden) oder nachfragen. Ordner
   `projekte/<slug>/rohdaten/` anlegen.
2. **Weg wählen:** Dem Nutzer zwei Optionen anbieten (AskUserQuestion): „Im Gespräch beantworten (ca. 10 Schritte)“
   oder „Fragebogen als Datei ausfüllen“ (dann `fragebogen/fragebogen.md` nach
   `projekte/<slug>/rohdaten/fragebogen-antworten.md` kopieren, Pfad nennen, und darauf hinweisen, dass die Pipeline mit
   `/homepage-neu <slug> --antworten projekte/<slug>/rohdaten/fragebogen-antworten.md` fortgesetzt wird; Skill endet).
   Mit `--datei`: Datei übernehmen und direkt zu Schritt 5.
3. **Gespräch führen:** `fragebogen/fragebogen.md` lesen (mit `--kurz`: `fragebogen/fragebogen-kurz.md`). Die Blöcke A
   bis J in Reihenfolge stellen, pro AskUserQuestion-Aufruf **höchstens vier Fragen**, jede mit zwei bis vier konkreten
   Antwortvorschlägen (plus freie Antwort), die aus bisherigen Antworten abgeleitet sind, wo möglich. Skalenfragen (H1,
   H2) mit den fünf Stufen als Optionen. Fragen, die durch frühere Antworten bereits beantwortet sind, überspringen und
   die Ableitung notieren.
4. **Nachfassen:** Bei vagen Antworten („Qualität“, „modern“, „alles“) einmal konkret nachfragen: „Woran würde man das
   auf der Website erkennen?“ oder „Nennen Sie ein Beispiel.“ Nicht mehr als einmal pro Frage.
5. **Protokoll schreiben:** `projekte/<slug>/rohdaten/gespraech.md` mit Datum, Teilnehmer, allen Fragen und Antworten
   (wörtlich, nicht geglättet), Markierung übersprungener Fragen und abgeleiteter Antworten.
6. **Briefing erzeugen:** Agent `briefing-agent` mit Projektordner und Quelle beauftragen → `artefakte/01-briefing.md`,
   `briefing.json`.
7. **Rückmeldung:** Entscheidungsvorlage des Briefing-Agenten zeigen und fragen, ob mit `/homepage-neu <slug>` fortgesetzt
   werden soll (wenn der Skill nicht bereits aus `/homepage-neu` heraus aufgerufen wurde; dann einfach zurückgeben).

## Regeln

- Sie-Form gegenüber Kunden, es sei denn, der Nutzer duzt.
- Nie alle Fragen auf einmal. Nie Antworten erfinden oder „für den Kunden“ ausfüllen; Lücken bleiben Lücken.
- Antwortvorschläge sind Hilfen, keine Lenkung: immer eine neutrale Option und freie Eingabe ermöglichen.
