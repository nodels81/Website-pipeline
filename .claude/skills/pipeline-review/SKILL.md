---
name: pipeline-review
description: Durchleuchtet die gesamte Website-Pipeline (Agenten, Skills, Vorlagen, Skripte, Profile) auf Nutzen, Token-Verbrauch und Kosten und schreibt einen belegten Review-Bericht mit schlanker Zielarchitektur und Migrationsplan. Ändert erst nach Freigabe etwas. Nur auf ausdrücklichen Aufruf einsetzen.
disable-model-invocation: true
argument-hint: "[--umsetzen]"
---

Lies `prompts/PIPELINE-REVIEW.md` vollständig und führe ihn aus.

- Ohne Argument: nur **Phase A** (lesen, messen, bewerten, Bericht schreiben), danach anhalten.
- Mit `--umsetzen`: Es muss bereits ein `pipeline/REVIEW-*.md` existieren. Dann **Phase B** für die Schritte, die der
  Nutzer im Chat freigegeben hat; bei Unklarheit zuerst nachfragen, welche Schritte gemeint sind.

Argumente: `$ARGUMENTS`
