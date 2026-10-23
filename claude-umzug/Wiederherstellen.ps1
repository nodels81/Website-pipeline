# Claude-Umzug: WIEDERHERSTELLEN (auf dem NEUEN Rechner ausfuehren)
# Holt alles aus dem Ordner "Claude-Umzug" neben diesem Skript zurueck.
# Vorhandenes wird nicht ueberschrieben: neuere Dateien bleiben, Einstellungen
# werden zusammengefuehrt, und vorher wird eine Sicherung angelegt.

$Quelle = Join-Path $PSScriptRoot 'Claude-Umzug'
$Neu    = $env:USERPROFILE
$Stempel = Get-Date -Format 'yyyyMMdd-HHmm'

function Info($t, $c = 'White') { Write-Host $t -ForegroundColor $c }

Info "`n=== Claude-Umzug: Wiederherstellen ===`n" Cyan

if (-not (Test-Path "$Quelle\umzug-info.json")) {
    Info "FEHLER: $Quelle\umzug-info.json nicht gefunden. Erst auf dem alten Rechner Sichern.bat ausfuehren." Red
    return
}
$info = Get-Content "$Quelle\umzug-info.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$Alt  = $info.Benutzerordner
Info "Sicherung vom $($info.Datum) von Rechner $($info.Rechner)"
if ($Alt -ine $Neu) { Info "Benutzerordner alt: $Alt  ->  neu: $Neu (Pfade werden angepasst)" Yellow }

while (Get-Process -Name 'claude' -ErrorAction SilentlyContinue) {
    Info 'Claude bzw. Claude Code laeuft noch. Bitte alle Claude-Fenster schliessen.' Yellow
    if ((Read-Host 'Enter = erneut pruefen, w = trotzdem weiter') -eq 'w') { break }
}
if ((Read-Host "Jetzt wiederherstellen nach $Neu ? (J/n)") -eq 'n') { return }

# Ersetzt den alten Benutzerordner im JSON-Text durch den neuen (C:\\Users\\x und C:/Users/x)
function Pfade-Anpassen([string]$text) {
    if ($Alt -ieq $Neu) { return $text }
    foreach ($paar in @(@($Alt.Replace('\', '\\'), $Neu.Replace('\', '\\')), @(($Alt -replace '\\', '/'), ($Neu -replace '\\', '/')))) {
        $text = [regex]::Replace($text, [regex]::Escape($paar[0]), $paar[1].Replace('$', '$$'), 'IgnoreCase')
    }
    $text
}
function Lies-Json($pfad) { Pfade-Anpassen (Get-Content -LiteralPath $pfad -Raw -Encoding UTF8) | ConvertFrom-Json }
function Speichere-Json($obj, $pfad) {
    # ohne BOM, sonst kann Claude die Datei nicht lesen
    [IO.File]::WriteAllText($pfad, ($obj | ConvertTo-Json -Depth 100), (New-Object Text.UTF8Encoding $false))
}
# Uebernimmt aus $von.$schluessel alle Eintraege, die in $nach.$schluessel noch fehlen
function Ergaenze($nach, $von, $schluessel) {
    if (-not $von.$schluessel) { return }
    if (-not $nach.$schluessel) { $nach | Add-Member -NotePropertyName $schluessel -NotePropertyValue ([pscustomobject]@{}) -Force }
    $vorhanden = @($nach.$schluessel.PSObject.Properties.Name)
    foreach ($p in $von.$schluessel.PSObject.Properties) {
        if ($vorhanden -notcontains $p.Name) { $nach.$schluessel | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value }
    }
}
$fehler = @()

# --- 1) Ordner .claude ----------------------------------------------------------
$src = "$Quelle\Benutzerordner\.claude"
if (Test-Path $src) {
    Info 'Claude Code: Ordner .claude ...'
    if (Test-Path "$Neu\.claude") {
        robocopy "$Neu\.claude" "$Neu\.claude-vor-umzug-$Stempel" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
        Info "  Bisheriger Stand gesichert in .claude-vor-umzug-$Stempel"
    }
    # /XO: auf dem neuen Rechner neuere Dateien bleiben unangetastet
    robocopy $src "$Neu\.claude" /E /XO /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { $fehler += '.claude' }

    # Sitzungsverlaeufe liegen unter projects\<Pfad mit - statt Sonderzeichen>
    if ($Alt -ine $Neu -and (Test-Path "$Neu\.claude\projects")) {
        $kA = $Alt -replace '[^A-Za-z0-9]', '-'
        $kN = $Neu -replace '[^A-Za-z0-9]', '-'
        Get-ChildItem "$Neu\.claude\projects" -Directory | Where-Object { $_.Name.StartsWith($kA, 'OrdinalIgnoreCase') } | ForEach-Object {
            $neuName = $kN + $_.Name.Substring($kA.Length)
            $neuPfad = Join-Path $_.Parent.FullName $neuName
            if (Test-Path $neuPfad) {
                robocopy $_.FullName $neuPfad /E /XO /NFL /NDL /NJH /NJS /NP | Out-Null
                Remove-Item $_.FullName -Recurse -Force
            } else { Rename-Item $_.FullName $neuName }
        }
    }
}

# --- 2) .claude.json (MCP-Server, Projekt-Einstellungen) -------------------------
$src = "$Quelle\Benutzerordner\.claude.json"
if (Test-Path $src) {
    Info 'Claude Code: .claude.json ...'
    try {
        $alt = Lies-Json $src
        $ziel = "$Neu\.claude.json"
        if (Test-Path $ziel) {
            Copy-Item $ziel "$ziel.vor-umzug-$Stempel"
            $neu = Get-Content $ziel -Raw -Encoding UTF8 | ConvertFrom-Json
        } else {
            # Kein Login und keine Geraete-ID vom alten Rechner uebernehmen
            $neu = $alt | Select-Object * -ExcludeProperty oauthAccount, userID, projects, mcpServers
        }
        Ergaenze $neu $alt 'mcpServers'
        Ergaenze $neu $alt 'projects'
        Speichere-Json $neu $ziel
    } catch { $fehler += ".claude.json ($($_.Exception.Message))" }
}

# --- 3) Claude Desktop ----------------------------------------------------------
$src = "$Quelle\AppData-Claude\claude_desktop_config.json"
if (Test-Path $src) {
    Info 'Claude Desktop: Einstellungen ...'
    try {
        $alt = Lies-Json $src
        $ziel = "$env:APPDATA\Claude\claude_desktop_config.json"
        New-Item -ItemType Directory -Force (Split-Path $ziel) | Out-Null
        if (Test-Path $ziel) {
            Copy-Item $ziel "$ziel.vor-umzug-$Stempel"
            $neu = Get-Content $ziel -Raw -Encoding UTF8 | ConvertFrom-Json
            Ergaenze $neu $alt 'mcpServers'
        } else { $neu = $alt }
        Speichere-Json $neu $ziel
    } catch { $fehler += "claude_desktop_config.json ($($_.Exception.Message))" }
}

# --- 4) Projekte ----------------------------------------------------------------
foreach ($p in @($info.Projekte)) {
    if ($p.Ordner -like 'Benutzerordner\*') {
        $dst = Join-Path $Neu $p.Ordner.Substring('Benutzerordner\'.Length)
    } elseif (Test-Path ($p.Original.Substring(0, 3))) {
        $dst = $p.Original            # z.B. D:\Projekte\x - Laufwerk gibt es auch hier
    } else {
        $dst = Join-Path "$Neu\Projekte-vom-alten-Rechner" ($p.Original -replace ':', '')
    }
    Info "Projekt -> $dst"
    robocopy (Join-Path $Quelle $p.Ordner) $dst /E /XO /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { $fehler += $dst }
}

Info "`n=== FERTIG ===" Green
if ($fehler) {
    Info 'Bei diesen Eintraegen gab es Probleme:' Red
    $fehler | ForEach-Object { Info "  - $_" Red }
} else { Info 'Alles uebernommen.' Green }
Info "`nJetzt Claude starten und ggf. neu anmelden."
Info 'In Projekten mit Node/Python die Abhaengigkeiten neu installieren (npm install / pip install ...).'
