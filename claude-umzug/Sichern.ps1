# Claude-Umzug: SICHERN (auf dem ALTEN Rechner ausfuehren)
# Kopiert Claude-Code-/Claude-Desktop-Einstellungen und alle Projekte in den
# Ordner "Claude-Umzug" direkt neben diesem Skript (also auf die Wechselplatte).

$Home_  = $env:USERPROFILE
$Ziel   = Join-Path $PSScriptRoot 'Claude-Umzug'
# Ordner, die sich neu installieren lassen und nur Platz kosten
$SkipDirs  = 'node_modules', '.venv', 'venv', '__pycache__', '.next', '.cache'
$SkipRegex = '\\(' + (($SkipDirs | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\\'

function Info($t, $c = 'White') { Write-Host $t -ForegroundColor $c }

Info "`n=== Claude-Umzug: Sichern ===`n" Cyan

if ($PSScriptRoot.Substring(0, 2) -ieq $env:SystemDrive) {
    Info "ACHTUNG: Dieses Skript liegt auf $env:SystemDrive (der Systemplatte)." Yellow
    Info "Kopiere den Ordner 'claude-umzug' auf die Wechselplatte und starte es dort." Yellow
    if ((Read-Host 'Trotzdem hierhin sichern? (j/N)') -ne 'j') { return }
}

while (Get-Process -Name 'claude' -ErrorAction SilentlyContinue) {
    Info 'Claude bzw. Claude Code laeuft noch. Bitte alle Claude-Fenster schliessen.' Yellow
    if ((Read-Host 'Enter = erneut pruefen, w = trotzdem weiter') -eq 'w') { break }
}

# --- 1) Was wird gesichert? -------------------------------------------------
$items = New-Object System.Collections.Generic.List[object]
function Add-Item($name, $quelle, $ziel, [switch]$Projekt) {
    if (Test-Path -LiteralPath $quelle) {
        $items.Add([pscustomobject]@{ Name = $name; Quelle = $quelle; Ziel = $ziel; Projekt = [bool]$Projekt })
    }
}
Add-Item 'Claude Code (Ordner .claude)'  "$Home_\.claude"      'Benutzerordner\.claude'
Add-Item 'Claude Code (.claude.json)'    "$Home_\.claude.json" 'Benutzerordner\.claude.json'
Add-Item 'Claude Desktop (Einstellungen)' "$env:APPDATA\Claude\claude_desktop_config.json" 'AppData-Claude\claude_desktop_config.json'

# Projekte: alle Ordner, in denen Claude Code benutzt wurde, plus alle Git-Projekte
$kandidaten = New-Object System.Collections.Generic.List[string]
if (Test-Path "$Home_\.claude.json") {
    try {
        $cj = Get-Content "$Home_\.claude.json" -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cj.projects) { $cj.projects.PSObject.Properties.Name | ForEach-Object { $kandidaten.Add(($_ -replace '/', '\')) } }
    } catch { Info 'Hinweis: .claude.json konnte nicht gelesen werden, suche nur nach Git-Projekten.' Yellow }
}
Info 'Suche Projektordner ... (kann ein paar Minuten dauern)'
Get-ChildItem $Home_ -Directory -Recurse -Depth 6 -Force -Filter '.git' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\(AppData|node_modules|\.claude)\\' } |
    ForEach-Object { $kandidaten.Add($_.Parent.FullName) }

$imHome = $false
$projekte = @($kandidaten | ForEach-Object { $_.TrimEnd('\') } | Where-Object {
        if ($_ -ieq $Home_) { $script:imHome = $true; return $false }
        $_.Length -gt 3 -and $_ -notlike "$Home_\AppData\*" -and (Test-Path -LiteralPath $_ -PathType Container)
    } | Sort-Object -Unique)
# Unterordner weglassen, wenn der Oberordner schon dabei ist
$projekte = @($projekte | Where-Object { $p = $_; -not ($projekte | Where-Object { $p.StartsWith($_ + '\', 'OrdinalIgnoreCase') }) })

foreach ($p in $projekte) {
    if ($p.StartsWith($Home_ + '\', 'OrdinalIgnoreCase')) { $rel = 'Benutzerordner\' + $p.Substring($Home_.Length + 1) }
    else { $rel = 'Andere\' + ($p -replace ':', '') }
    Add-Item "Projekt: $p" $p $rel -Projekt
}

# --- 2) Groesse messen --------------------------------------------------------
Info "`nMesse Groesse ...`n"
$summe = 0
foreach ($e in $items) {
    $gi = Get-Item -LiteralPath $e.Quelle -Force
    if ($gi.PSIsContainer) {
        $s = (Get-ChildItem -LiteralPath $e.Quelle -Recurse -File -Force -ErrorAction SilentlyContinue |
                Where-Object { -not $e.Projekt -or $_.FullName -notmatch $SkipRegex } |
                Measure-Object Length -Sum).Sum
    } else { $s = $gi.Length }
    $e | Add-Member MB ([math]::Round(($s + 0) / 1MB, 1))
    $summe += $e.MB
    Info ('{0,10:N1} MB  {1}' -f $e.MB, $e.Name)
}
$frei = [math]::Round((Get-PSDrive $Ziel.Substring(0, 1)).Free / 1MB, 1)
Info ("`nGESAMT: {0:N2} GB    Frei auf {1}: {2:N1} GB" -f ($summe / 1024), $Ziel.Substring(0, 2), ($frei / 1024)) Cyan
if ($imHome) { Info 'Hinweis: Claude wurde auch direkt im Benutzerordner benutzt - der wird NICHT komplett mitkopiert.' Yellow }
if ($summe -gt $frei -and -not (Test-Path $Ziel)) { Info 'FEHLER: Nicht genug Platz auf der Platte. Abbruch.' Red; return }

if ((Read-Host "`nJetzt nach $Ziel kopieren? (J/n)") -eq 'n') { return }

# --- 3) Kopieren --------------------------------------------------------------
New-Item -ItemType Directory -Force $Ziel | Out-Null
$log = Join-Path $Ziel 'kopier-log.txt'
$fehler = @()
foreach ($e in $items) {
    Info "Kopiere $($e.Name) ..."
    $dst = Join-Path $Ziel $e.Ziel
    if (-not (Get-Item -LiteralPath $e.Quelle -Force).PSIsContainer) {
        New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
        try { Copy-Item -LiteralPath $e.Quelle $dst -Force -ErrorAction Stop } catch { $fehler += $e.Name }
        continue
    }
    $extra = if ($e.Projekt) { @('/XD') + $SkipDirs } else { @('/XF', '.credentials.json') }
    robocopy $e.Quelle $dst /E /R:1 /W:1 /NFL /NDL /NP /NJH /NJS "/LOG+:$log" @extra | Out-Null
    if ($LASTEXITCODE -ge 8) { $fehler += $e.Name }
}

# Info fuer das Wiederherstellen-Skript
[pscustomobject]@{
    Datum          = (Get-Date -Format s)
    Rechner        = $env:COMPUTERNAME
    Benutzerordner = $Home_
    Projekte       = @($items | Where-Object Projekt | ForEach-Object { [pscustomobject]@{ Original = $_.Quelle; Ordner = $_.Ziel } })
} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $Ziel 'umzug-info.json') -Encoding UTF8

Info "`n=== FERTIG ===" Green
Info "Gesichert in: $Ziel"
if ($fehler) {
    Info "`nBei diesen Eintraegen gab es Fehler (meist: Datei war geoeffnet):" Red
    $fehler | ForEach-Object { Info "  - $_" Red }
    Info 'Programme schliessen und Sichern.bat noch einmal starten - bereits Kopiertes wird uebersprungen.' Yellow
} else {
    Info 'Alles ohne Fehler kopiert. Die Platte kann jetzt an den neuen Rechner.' Green
}
