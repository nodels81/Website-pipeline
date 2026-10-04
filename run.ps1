<#
.SYNOPSIS
  Vollautomatische Pipeline (PowerShell-Variante von run.sh): vorne Eingabe rein, hinten fertige Website raus.

.DESCRIPTION
  Startet Claude Code headless mit /homepage-neu bzw. /homepage-verbessern im Automatik-Modus, schreibt ein Log nach
  ausgang\<slug>\pipeline.log und stellt sicher, dass am Ende ausgang\<slug>\ mit ERGEBNIS.md, website\, quellcode\,
  dokumentation\, vorschau\ und ZIP existiert.

.EXAMPLE
  .\run.ps1 eingang\meinprojekt.md
  Neue Website aus Kurzbrief oder Fragebogen (enthält die Datei "URL: https://…", wird die Seite neu gemacht).

.EXAMPLE
  .\run.ps1 https://beispiel.de -Bis konzept
  Neubau aus einer URL, endet nach den Konzeptdokumenten.

.EXAMPLE
  .\run.ps1 -Alle -Voll
  Alle Dateien in eingang\, die noch kein Ergebnis haben, ohne Berechtigungsabfragen.

.NOTES
  Optionen: -Profil sparsam|standard|premium -Bis <phase> -Ab <phase> -Richtung A|B|C -Deploy -DeployProd -Neu -Voll -Modell <id> -Trocken
  Phasen: audit, briefing, analyse, positionierung, konzept, build, qa, paket
  Falls PowerShell Skripte blockiert:  powershell -ExecutionPolicy Bypass -File .\run.ps1 eingang\meinprojekt.md
  Claude Code braucht unter Windows Git für Windows (Git Bash); darüber laufen auch die Skripte in scripts\.
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)] [string] $Eingabe,
  [switch] $Alle,
  [ValidateSet('audit', 'briefing', 'analyse', 'positionierung', 'konzept', 'design', 'build', 'qa', 'paket')] [string] $Bis,
  [ValidateSet('audit', 'briefing', 'analyse', 'positionierung', 'konzept', 'design', 'build', 'qa', 'paket')] [string] $Ab,
  [ValidateSet('A', 'B', 'C')] [string] $Richtung,
  [switch] $Deploy,
  [switch] $DeployProd,
  [switch] $Neu,
  [switch] $Voll,
  [ValidateSet('sparsam', 'standard', 'premium')] [string] $Profil,
  [string] $Modell,
  [switch] $Trocken
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

if (-not $Eingabe -and -not $Alle) { Get-Help $PSCommandPath -Examples; exit 1 }

# Voraussetzungen
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Write-Host 'Claude Code CLI fehlt. Installation: npm install -g @anthropic-ai/claude-code' -ForegroundColor Red; exit 1
}
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { Write-Host 'Node.js >= 18 fehlt.' -ForegroundColor Red; exit 1 }
$bash = Get-Command bash -ErrorAction SilentlyContinue
if (-not $bash) {
  Write-Host 'Hinweis: Kein "bash" gefunden. Claude Code benötigt unter Windows Git für Windows (Git Bash): https://git-scm.com/download/win' -ForegroundColor Yellow
}
if (-not (Test-Path -LiteralPath 'scripts\node_modules\playwright')) {
  Write-Host '→ Installiere Analyse-Skripte (einmalig) …'
  Push-Location scripts
  try { npm install --no-audit --no-fund | Out-Null } finally { Pop-Location }
}
if (-not $Voll) {
  Write-Host "Hinweis: Die Freigaben aus .claude\settings.json gelten erst, wenn Claude Code diesem Ordner vertraut (einmal 'claude' hier starten und den Dialog bestätigen). Unbeaufsichtigt: -Voll."
}

function ConvertTo-Slug([string] $s) {
  $s = $s -replace '^https?://', '' -replace '^www\.', '' -replace '/.*$', ''
  $s = $s.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
  return $s.Trim('-')
}
function Test-IsUrl([string] $s) {
  return ($s -match '^https?://') -or ($s -match '^[a-z0-9.-]+\.[a-z]{2,}(/.*)?$')
}

function Invoke-Pipeline([string] $eingabe) {
  $modus = ''; $url = ''; $slug = ''; $prompt = ''
  if (Test-IsUrl $eingabe) {
    $modus = 'verbessern'; $url = $eingabe
    if ($url -notmatch '^https?://') { $url = "https://$url" }
    $slug = ConvertTo-Slug $url
    $prompt = "/homepage-verbessern $url --auto"
  }
  else {
    if (-not (Test-Path -LiteralPath $eingabe)) { Write-Host "Eingabedatei nicht gefunden: $eingabe" -ForegroundColor Red; return 1 }
    $full = (Resolve-Path -LiteralPath $eingabe).Path
    $rel = $full.Substring($PSScriptRoot.Length).TrimStart('\', '/') -replace '\\', '/'
    $slug = ConvertTo-Slug ([IO.Path]::GetFileNameWithoutExtension($eingabe))
    $m = Select-String -LiteralPath $eingabe -Pattern '^\s*\**URL\**:?\s*(https?://[^\s)]+)' | Select-Object -First 1
    if ($m) {
      $url = $m.Matches[0].Groups[1].Value; $modus = 'verbessern'
      $prompt = "/homepage-verbessern $url --auto --antworten $rel --slug $slug"
    }
    else {
      $modus = 'neu'
      $prompt = "/homepage-neu $slug --auto --antworten $rel"
    }
  }
  if ($Bis) { $prompt += " --bis $Bis" }
  if ($Ab) { $prompt += " --ab $Ab" }
  if ($Richtung) { $prompt += " --richtung $Richtung" }
  if ($DeployProd) { $prompt += ' --deploy-prod' } elseif ($Deploy) { $prompt += ' --deploy' }
  if ($Neu) { $prompt += ' --neu' }
  if ($Profil) { $prompt += " --profil $Profil" }

  $claudeArgs = @('-p', $prompt)
  if ($Voll) { $claudeArgs += @('--permission-mode', 'bypassPermissions') } else { $claudeArgs += @('--permission-mode', 'acceptEdits') }
  if ($Modell) { $claudeArgs += @('--model', $Modell) }

  $outDir = Join-Path 'ausgang' $slug
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
  $log = Join-Path $outDir 'pipeline.log'
  Write-Host '══════════════════════════════════════════════════════════'
  Write-Host " Projekt: $slug · Modus: $modus · Eingabe: $eingabe"
  Write-Host " Befehl:  claude $($claudeArgs -join ' ')"
  Write-Host " Log:     $log"
  Write-Host '══════════════════════════════════════════════════════════'
  if ($Trocken) { return 0 }

  $start = Get-Date
  "Start: $($start.ToString('s'))" | Set-Content -LiteralPath $log
  $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  & claude @claudeArgs 2>&1 | Tee-Object -FilePath $log -Append
  $rc = $LASTEXITCODE
  $ErrorActionPreference = $prev
  $ende = Get-Date
  "Ende: $($ende.ToString('s')) · Dauer: $([int](($ende - $start).TotalMinutes)) min · Exit: $rc" | Tee-Object -FilePath $log -Append | Write-Host

  $ergebnis = Join-Path $outDir 'ERGEBNIS.md'
  if (-not (Test-Path -LiteralPath $ergebnis) -and (Test-Path -LiteralPath (Join-Path 'projekte' $slug)) -and $bash) {
    & bash scripts/paketieren.sh $slug 2>&1 | Add-Content -LiteralPath $log
  }
  Write-Host ''
  if (Test-Path -LiteralPath $ergebnis) {
    Write-Host "✓ Fertig: $outDir\" -ForegroundColor Green
    Get-Content -LiteralPath $ergebnis -TotalCount 25
  }
  else {
    Write-Host "✗ Kein ERGEBNIS.md. Status: projekte\$slug\artefakte\00-projektstatus.md · Log: $log" -ForegroundColor Red
    return 1
  }
  return $rc
}

if ($Alle) {
  $found = $false; $fails = 0
  Get-ChildItem -Path 'eingang' -Filter '*.md' -File | Where-Object { $_.Name -notlike 'VORLAGE-*' -and $_.Name -ne 'README.md' } | ForEach-Object {
    $slug = ConvertTo-Slug $_.BaseName
    if ((Test-Path -LiteralPath (Join-Path (Join-Path 'ausgang' $slug) 'ERGEBNIS.md')) -and -not $Neu) {
      Write-Host "– $($_.Name): Ergebnis vorhanden, übersprungen (-Neu erzwingt)"; return
    }
    $found = $true
    $code = Invoke-Pipeline $_.FullName
    if ($code -ne 0) { $fails++ }
  }
  if (-not $found) { Write-Host 'Nichts zu tun: keine neuen Dateien in eingang\.' }
  exit $fails
}
else {
  $code = Invoke-Pipeline $Eingabe
  exit $code
}
