# Schritt 1: Bestandsaufnahme. Liest nur, kopiert und veraendert nichts.
# Ergebnis: Inventur\Bericht.txt (zum Lesen) und Inventur\inventur-roh.json (fuer Sichern.ps1)
param([string]$Ziel = $PSScriptRoot)

. (Join-Path $PSScriptRoot 'Gemeinsam.ps1')

$prof = $env:USERPROFILE.TrimEnd('\')
$desktopDir = Get-DesktopDataDir
$claudeDir = Join-Path $prof '.claude'
$zielLaufwerk = (Split-Path -Qualifier $Ziel).ToUpper()
$E = New-Object System.Collections.ArrayList
$fehlendeProjekte = New-Object System.Collections.ArrayList
$uebersprungen = New-Object System.Collections.ArrayList

function Write-Schritt([string]$t) { Write-Host "  ... $t" -ForegroundColor DarkGray }

function Add-Entry {
    param([string]$Gruppe, [string]$Titel, [string]$Pfad, [string]$Empfehlung = 'mit', [string]$Hinweis = '',
        [string[]]$AusschlussOrdner = @(), [switch]$Geheim, [string]$Spezial = '')
    if (-not $Pfad -or -not (Test-Path -LiteralPath $Pfad)) { return $null }
    $Pfad = $Pfad.TrimEnd('\')
    foreach ($x in $E) { if ((Test-IsUnder $Pfad $x.Pfad) -or (Test-IsUnder $x.Pfad $Pfad)) { return $null } }
    $item = Get-Item -LiteralPath $Pfad -Force
    $m = Measure-Tree $Pfad $AusschlussOrdner -Geheim
    if ((Test-IsUnder $Pfad $desktopDir) -and $Pfad -ine $desktopDir) { $basis = 'Desktop'; $rel = $Pfad.Substring($desktopDir.Length + 1) }
    elseif (Test-IsUnder $Pfad $prof) { $basis = 'Profil'; $rel = if ($Pfad -ieq $prof) { '' } else { $Pfad.Substring($prof.Length + 1) } }
    else { $basis = 'Absolut'; $rel = '' }
    $geheimnisse = @($m.Geheimnisse | Select-Object -First 50)
    $o = [pscustomobject]@{
        Nr = $E.Count + 1; Gruppe = $Gruppe; Titel = $Titel; Pfad = $Pfad
        Art = $(if ($item.PSIsContainer) { 'Ordner' } else { 'Datei' })
        Basis = $basis; Rel = $rel; Sicherung = (Get-BackupRel $Pfad)
        Bytes = $m.Bytes; Dateien = $m.Dateien; ExclBytes = $m.ExclBytes; ExclDateien = $m.ExclDateien; Lesefehler = $m.Fehler
        AusschlussOrdner = @($AusschlussOrdner); Empfehlung = $Empfehlung; Mitnehmen = ($Empfehlung -eq 'mit' -or $Empfehlung -eq 'optional')
        Geheim = ($Geheim.IsPresent -or $geheimnisse.Count -gt 0); Geheimnisse = $geheimnisse
        Hinweis = $Hinweis; Spezial = $Spezial; NeuInstallieren = @()
    }
    if ($Empfehlung -eq 'nein') { $o.Mitnehmen = $false }
    [void]$E.Add($o)
    return $o
}

function Get-KeyValues($Knoten, [string]$Schluessel) {
    $res = @()
    if ($Knoten -is [System.Collections.IDictionary]) {
        foreach ($k in @($Knoten.PSBase.Keys)) {
            if ($k -eq $Schluessel -and $Knoten[$k] -is [string]) { $res += $Knoten[$k] }
            else { $res += @(Get-KeyValues $Knoten[$k] $Schluessel) }
        }
    }
    elseif ($Knoten -is [System.Array]) { foreach ($x in $Knoten) { $res += @(Get-KeyValues $x $Schluessel) } }
    return $res
}

function Hide-Secrets([string]$s) {
    $s = [regex]::Replace($s, '(?i)((?:key|token|secret|password|passwd|pat|auth)[\w-]*[=:]\s*)\S+', '$1***')
    [regex]::Replace($s, '\b(sk-[A-Za-z0-9_-]{8})[A-Za-z0-9_-]+|\b(gh[pousr]_)[A-Za-z0-9]{10,}|\b(xox[a-z]-)[A-Za-z0-9-]+', '$1$2$3***')
}

Write-Host ''
Write-Host '=== Claude-Umzug: Bestandsaufnahme (liest nur, kopiert nichts) ===' -ForegroundColor Cyan
Write-Host "Benutzer: $env:USERNAME   Profil: $prof   Rechner: $env:COMPUTERNAME"
Write-Host "Sicherungsziel: $Ziel"
if ($zielLaufwerk -eq (Split-Path -Qualifier $prof).ToUpper()) {
    Write-Host "ACHTUNG: Der Ordner mit den Skripten liegt auf $zielLaufwerk, nicht auf der Wechselplatte. Kopiere den Ordner nach D:\Claude-Umzug und starte von dort." -ForegroundColor Yellow
}

# ---------- 1. Claude Code: %USERPROFILE%\.claude ----------
Write-Schritt 'Claude Code (.claude)'
$ccMit = @('settings.json', 'settings.local.json', 'CLAUDE.md', 'CLAUDE.local.md', 'keybindings.json', 'agents', 'commands', 'skills',
    'hooks', 'output-styles', 'plugins', 'plans', 'todos', 'tasks', 'teams', 'history.jsonl', 'projects', 'memory', 'rules',
    'agent-memory', 'statusline*', '*.ps1', '*.sh', '*.py', '*.js', '*.mjs', '*.md', '*.json', '*.txt')
$ccOptional = @('file-history', 'backups')
$ccNein = @('shell-snapshots', 'statsig', 'ide', 'debug', 'telemetry', 'cache', 'logs', 'session-env', 'paste-cache',
    'image-cache', 'local', 'downloads', '*.lock', 'stats-cache.json', '*.tmp')
$ccTexte = @{
    'settings.json' = 'globale Einstellungen (wird beim Wiederherstellen zusammengefuehrt)'
    'settings.local.json' = 'lokale Einstellungen (wird zusammengefuehrt)'
    'CLAUDE.md' = 'deine globalen Anweisungen an Claude'
    'projects' = 'Sitzungsverlaeufe + automatisches Memory je Projekt'
    'history.jsonl' = 'Verlauf deiner Eingaben (Pfeil-hoch)'
    'plugins' = 'installierte Plugins und Marktplaetze'
    'skills' = 'eigene Skills'; 'agents' = 'eigene Subagents'; 'commands' = 'eigene Slash-Commands'; 'hooks' = 'Hook-Skripte'
    'todos' = 'Aufgabenlisten der Sitzungen'; 'plans' = 'Plaene aus dem Plan-Modus'
    'file-history' = 'Datei-Schnappschuesse fuer "Zurueckspulen" alter Sitzungen'
    'shell-snapshots' = 'temporaer, wird neu erzeugt'; 'statsig' = 'Cache'; 'ide' = 'Sperrdateien der IDE-Verbindung'
    'debug' = 'Debug-Logs'; 'telemetry' = 'Telemetrie-Puffer'; 'local' = 'alte lokale Claude-Code-Installation (neu installieren)'
    'session-env' = 'temporaer'; 'downloads' = 'Installer-Downloads'
}
if (Test-Path -LiteralPath $claudeDir) {
    foreach ($c in (Get-ChildItem -LiteralPath $claudeDir -Force | Sort-Object Name)) {
        $n = $c.Name
        $titel = ".claude\$n" + $(if ($ccTexte.ContainsKey($n)) { ' - ' + $ccTexte[$n] } else { '' })
        if ($n -eq '.credentials.json') {
            [void](Add-Entry 'Claude Code' '.claude\.credentials.json - Anmeldetoken' $c.FullName 'nein' 'Geheimnis. Auf dem neuen Rechner einfach neu anmelden (/login).' -Geheim)
            continue
        }
        $spez = switch ($n) { 'settings.json' { 'settings-merge' } 'settings.local.json' { 'settings-merge' } 'projects' { 'projects' } default { '' } }
        if (Test-NameMatch $n $ccNein) { [void](Add-Entry 'Claude Code' $titel $c.FullName 'nein' 'nicht noetig') }
        elseif (Test-NameMatch $n $ccOptional) { [void](Add-Entry 'Claude Code' $titel $c.FullName 'optional' '') }
        elseif (Test-NameMatch $n $ccMit) { [void](Add-Entry 'Claude Code' $titel $c.FullName 'mit' '' -Spezial $spez) }
        else { [void](Add-Entry 'Claude Code' "$titel (unbekannt)" $c.FullName 'optional' 'unbekannter Eintrag, sicherheitshalber dabei') }
    }
}
else { Write-Host "  .claude nicht gefunden: $claudeDir" -ForegroundColor Yellow }

# Einstellungen auf Geheimnisse pruefen (env-Block)
foreach ($s in @('settings.json', 'settings.local.json')) {
    $x = $E | Where-Object { $_.Pfad -ieq (Join-Path $claudeDir $s) }
    $js = Read-JsonFile (Join-Path $claudeDir $s)
    if ($x -and $js -is [System.Collections.IDictionary] -and (Test-JsonKey $js 'env')) {
        $namen = @($js['env'].PSBase.Keys | Where-Object { $_ -match '(?i)key|token|secret|pass|auth' })
        if ($namen.Count) { $x.Geheim = $true; $x.Hinweis += " Enthaelt env-Werte: $($namen -join ', ')" }
    }
}

# ---------- 2. %USERPROFILE%\.claude.json ----------
Write-Schritt '.claude.json'
$cjPfad = Join-Path $prof '.claude.json'
$cj = Read-JsonFile $cjPfad
$cjEintrag = Add-Entry 'Claude Code' '.claude.json - MCP-Server, Projekt-Einstellungen, Konto-Status' $cjPfad 'mit' 'wird beim Wiederherstellen zusammengefuehrt' -Spezial 'claudejson'
if ((Test-Path -LiteralPath $cjPfad) -and $null -eq $cj) { Write-Host '  .claude.json konnte nicht gelesen werden (wird trotzdem gesichert).' -ForegroundColor Yellow }
foreach ($b in @(Get-ChildItem -LiteralPath $prof -Force -Filter '.claude.json.*' -ErrorAction SilentlyContinue)) {
    [void](Add-Entry 'Claude Code' "$($b.Name) - automatische Sicherungskopie" $b.FullName 'nein' 'alte Sicherung von .claude.json')
}

# ---------- 3. Claude Desktop ----------
Write-Schritt 'Claude Desktop'
$desktopTexte = @{
    'claude_desktop_config.json' = 'MCP-Server von Claude Desktop (wird zusammengefuehrt)'
    'config.json' = 'App-Einstellungen (wird ohne Anmeldedaten zusammengefuehrt)'
    'Claude Extensions' = 'installierte Desktop-Erweiterungen'
    'Claude Extensions Settings' = 'Einstellungen der Erweiterungen (evtl. API-Schluessel)'
    'local-agent-mode-sessions' = 'lokale Cowork-Sitzungen'
    'Local Storage' = 'App-Zustand der Oberflaeche (Anmeldung darin ist verschluesselt und auf dem neuen Rechner wertlos)'
    'IndexedDB' = 'App-Zustand der Oberflaeche'
}
$desktopOrte = @($desktopDir)
if ($desktopDir -ine (Join-Path $env:APPDATA 'Claude') -and (Test-Path -LiteralPath (Join-Path $env:APPDATA 'Claude'))) { $desktopOrte += (Join-Path $env:APPDATA 'Claude') }
foreach ($ort in $desktopOrte) {
    if (-not (Test-Path -LiteralPath $ort)) { continue }
    $kurz = $ort.Replace($prof, '%USERPROFILE%')
    foreach ($c in (Get-ChildItem -LiteralPath $ort -Force | Sort-Object Name)) {
        $n = $c.Name
        $titel = "$kurz\$n" + $(if ($desktopTexte.ContainsKey($n)) { ' - ' + $desktopTexte[$n] } else { '' })
        $spez = switch ($n) { 'claude_desktop_config.json' { 'desktopconfig' } 'config.json' { 'desktopappconfig' } default { '' } }
        if (Test-NameMatch $n $script:DesktopCaches) { [void](Add-Entry 'Claude Desktop' $titel $c.FullName 'nein' 'Cache/Log/verschluesselte Anmeldung') }
        elseif ($n -in @('Local Storage', 'IndexedDB', 'Preferences', 'Partitions', 'WebStorage')) { [void](Add-Entry 'Claude Desktop' $titel $c.FullName 'optional' 'App-Zustand; meist nicht noetig' ) }
        elseif ($n -eq 'Claude Extensions Settings') { [void](Add-Entry 'Claude Desktop' $titel $c.FullName 'mit' '' -Geheim) }
        else { [void](Add-Entry 'Claude Desktop' $titel $c.FullName 'mit' '' -Spezial $spez) }
    }
    # Optional-Eintraege standardmaessig abwaehlen
    foreach ($x in $E) { if ($x.Gruppe -eq 'Claude Desktop' -and $x.Empfehlung -eq 'optional') { $x.Mitnehmen = $false } }
}
$dcfg = Read-JsonFile (Join-Path $desktopDir 'claude_desktop_config.json')
$erweiterungen = @()
$extDir = Join-Path $desktopDir 'Claude Extensions'
if (Test-Path -LiteralPath $extDir) {
    foreach ($d in (Get-ChildItem -LiteralPath $extDir -Directory -Force)) {
        $man = Read-JsonFile (Join-Path $d.FullName 'manifest.json')
        $name = if ($man -is [System.Collections.IDictionary] -and (Test-JsonKey $man 'display_name')) { $man['display_name'] } elseif ($man -is [System.Collections.IDictionary] -and (Test-JsonKey $man 'name')) { $man['name'] } else { $d.Name }
        $erweiterungen += [pscustomobject]@{ Id = $d.Name; Name = [string]$name }
    }
}

# ---------- 4. Weitere Claude-Programme/Daten (nur zur Info, meist neu installieren) ----------
Write-Schritt 'weitere Claude-Ordner'
$infoOrte = @(
    @{ P = (Join-Path $env:LOCALAPPDATA 'AnthropicClaude'); T = 'Programmdateien Claude Desktop'; H = 'ist auf dem neuen Rechner schon installiert' },
    @{ P = (Join-Path $env:LOCALAPPDATA 'claude-cli-nodejs'); T = 'Cache/Logs von Claude Code'; H = 'nicht noetig' },
    @{ P = (Join-Path $prof '.local\bin\claude.exe'); T = 'Claude-Code-Programm'; H = 'ist schon installiert' },
    @{ P = (Join-Path $prof '.local\share\claude'); T = 'Claude-Code-Programmversionen'; H = 'ist schon installiert' },
    @{ P = (Join-Path $prof '.local\state\claude'); T = 'Claude-Code-Zustand (Sperren/Updates)'; H = 'nicht noetig' },
    @{ P = (Join-Path $env:APPDATA 'npm\node_modules\@anthropic-ai'); T = 'Claude Code per npm'; H = 'neu installieren' }
)
foreach ($o in $infoOrte) { [void](Add-Entry 'Programme (neu installieren)' $o.T $o.P 'nein' $o.H) }
foreach ($p in @(Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA 'Packages') -Directory -Filter 'Claude*' -ErrorAction SilentlyContinue)) {
    $ls = Join-Path $p.FullName 'LocalCache\Roaming\Claude'
    foreach ($c in @(Get-ChildItem -LiteralPath $p.FullName -Force -ErrorAction SilentlyContinue)) {
        if ($c.Name -ne 'LocalCache') { [void](Add-Entry 'Programme (neu installieren)' "Store-Paket $($p.Name)\$($c.Name)" $c.FullName 'nein' 'Paketdaten, werden neu erzeugt') }
    }
}
foreach ($m in @((Join-Path $env:ProgramFiles 'ClaudeCode'), (Join-Path $env:ProgramData 'ClaudeCode'))) {
    if (Test-Path -LiteralPath $m) { [void](Add-Entry 'Claude Code' "Verwaltete Einstellungen ($m)" $m 'mit' 'Wiederherstellen braucht Admin-Rechte') }
}

# ---------- 5. Projekte ----------
Write-Schritt 'Projekte aus .claude.json und Sitzungsordnern'
$kandidaten = [ordered]@{}
function Add-Kandidat([string]$p, [string]$quelle) {
    if (-not $p) { return }
    $p = ($p -replace '/', '\').TrimEnd('\')
    if ($p -match '^[A-Za-z]:$') { $p += '\' }
    if ($p -match '^[a-z]:') { $p = $p.Substring(0, 1).ToUpper() + $p.Substring(1) }
    $k = $p.ToLowerInvariant()
    if (-not $kandidaten.Contains($k)) { $kandidaten[$k] = [pscustomobject]@{ Pfad = $p; Quellen = New-Object System.Collections.ArrayList; Sitzungsordner = @() } }
    if (-not $kandidaten[$k].Quellen.Contains($quelle)) { [void]$kandidaten[$k].Quellen.Add($quelle) }
}
if ($cj -is [System.Collections.IDictionary] -and (Test-JsonKey $cj 'projects')) {
    foreach ($k in @($cj['projects'].PSBase.Keys)) { Add-Kandidat $k '.claude.json' }
}
$sitzungsordner = @()
$projDir = Join-Path $claudeDir 'projects'
if (Test-Path -LiteralPath $projDir) {
    foreach ($d in (Get-ChildItem -LiteralPath $projDir -Directory -Force)) {
        $cwd = $null
        $jsonl = @(Get-ChildItem -LiteralPath $d.FullName -Filter '*.jsonl' -File -Force -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
        foreach ($f in ($jsonl | Select-Object -First 5)) {
            foreach ($l in @(Get-Content -LiteralPath $f.FullName -TotalCount 50 -Encoding UTF8 -ErrorAction SilentlyContinue)) {
                if ($l -match '"cwd"\s*:\s*"((?:[^"\\]|\\.)*)"') { $cwd = $matches[1] -replace '\\\\', '\'; break }
            }
            if ($cwd) { break }
        }
        $m = Measure-Tree $d.FullName
        $sitzungsordner += [pscustomobject]@{
            Ordner = $d.Name; Projekt = $cwd; Sitzungen = $jsonl.Count; Bytes = $m.Bytes
            Memory = (Test-Path -LiteralPath (Join-Path $d.FullName 'memory'))
            Zuletzt = $(if ($jsonl.Count) { $jsonl[0].LastWriteTime.ToString('yyyy-MM-dd') } else { '' })
        }
        if ($cwd) { Add-Kandidat $cwd 'Sitzungen' }
    }
}

Write-Schritt 'Git-Repositories suchen (kann einige Minuten dauern)'
$skip = @('AppData', 'node_modules', '.venv', 'venv', '$Recycle.Bin', 'System Volume Information', 'Windows', 'Program Files',
    'Program Files (x86)', 'ProgramData', 'Recovery', 'PerfLogs', '.claude', '.cache', '.npm', '.nuget', '.cargo', '.rustup',
    '.gradle', '.m2', 'scoop', '.vscode', '.vscode-insiders', '.local', 'Config.Msi', 'MSOCache', '$WinREAgent', '$SysReset',
    'OneDriveTemp', 'Windows.old', '.git', '.pyenv', '.conda', 'anaconda3', 'miniconda3', '.docker', '.android', 'go')
function Find-GitRepos([string]$Start, [int]$MaxTiefe, [string[]]$ZusatzSkip = @()) {
    $res = New-Object System.Collections.ArrayList
    $q = New-Object System.Collections.Queue
    $q.Enqueue(@($Start, 0))
    while ($q.Count -gt 0) {
        $e = $q.Dequeue(); $dir = $e[0]; $t = $e[1]
        if (Test-Path -LiteralPath (Join-Path $dir '.git')) { [void]$res.Add($dir.TrimEnd('\')); continue }
        if ($t -ge $MaxTiefe) { continue }
        $kinder = $null
        try { $kinder = Get-ChildItem -LiteralPath $dir -Directory -Force -ErrorAction Stop } catch { continue }
        foreach ($k in $kinder) {
            if ($k.Attributes -band [System.IO.FileAttributes]::ReparsePoint) { continue }
            if ($skip -contains $k.Name -or ($t -eq 0 -and $ZusatzSkip -contains $k.Name)) { continue }
            $q.Enqueue(@($k.FullName, $t + 1))
        }
    }
    return $res
}
foreach ($r in (Find-GitRepos $prof 6)) { Add-Kandidat $r 'Git' }
$sysLw = (Split-Path -Qualifier $env:SystemRoot).ToUpper()
$laufwerke = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction SilentlyContinue | ForEach-Object { $_.DeviceID.ToUpper() } | Where-Object { $_ -ne $zielLaufwerk })
foreach ($lw in $laufwerke) {
    Write-Schritt "  Laufwerk $lw"
    $zs = if ($lw -eq $sysLw) { @('Users') } else { @() }
    foreach ($r in (Find-GitRepos "$lw\" 5 $zs)) { Add-Kandidat $r 'Git' }
}

# Sitzungsordner ohne lesbares cwd ueber den kodierten Namen zuordnen
foreach ($s in $sitzungsordner) {
    if (-not $s.Projekt) {
        foreach ($k in $kandidaten.Values) { if ((Get-EncodedProjectName $k.Pfad) -ieq $s.Ordner) { $s.Projekt = $k.Pfad; break } }
    }
    if ($s.Projekt) {
        $kk = ($s.Projekt -replace '/', '\').TrimEnd('\').ToLowerInvariant()
        if ($kandidaten.Contains($kk)) { $kandidaten[$kk].Sitzungsordner += $s.Ordner }
    }
}

function Get-NeuInstallHinweise([string]$p) {
    $h = @()
    if (Test-Path -LiteralPath (Join-Path $p 'node_modules')) {
        if (Test-Path -LiteralPath (Join-Path $p 'pnpm-lock.yaml')) { $h += 'pnpm install' }
        elseif (Test-Path -LiteralPath (Join-Path $p 'yarn.lock')) { $h += 'yarn install' }
        elseif ((Test-Path -LiteralPath (Join-Path $p 'bun.lockb')) -or (Test-Path -LiteralPath (Join-Path $p 'bun.lock'))) { $h += 'bun install' }
        else { $h += 'npm install' }
    }
    foreach ($v in @('.venv', 'venv')) {
        if (Test-Path -LiteralPath (Join-Path $p $v)) {
            if (Test-Path -LiteralPath (Join-Path $p 'uv.lock')) { $h += 'uv sync' }
            elseif (Test-Path -LiteralPath (Join-Path $p 'poetry.lock')) { $h += 'poetry install' }
            elseif (Test-Path -LiteralPath (Join-Path $p 'requirements.txt')) { $h += "python -m venv $v; $v\Scripts\pip install -r requirements.txt" }
            else { $h += "Python-Umgebung $v neu anlegen" }
        }
    }
    return $h
}

$gitDa = [bool](Get-Command git -CommandType Application -ErrorAction SilentlyContinue)
Write-Schritt 'Projekte vermessen'
foreach ($k in ($kandidaten.Values | Sort-Object { $_.Pfad.Length })) {
    $p = $k.Pfad
    $quellen = ($k.Quellen -join ', ')
    if (-not (Test-Path -LiteralPath $p)) { [void]$fehlendeProjekte.Add([pscustomobject]@{ Pfad = $p; Quellen = $quellen; Sitzungsordner = @($k.Sitzungsordner) }); continue }
    if ((Split-Path -Qualifier $p).ToUpper() -eq $zielLaufwerk) { [void]$uebersprungen.Add("$p (liegt schon auf $zielLaufwerk)"); continue }
    if ((Test-IsUnder $p (Join-Path $prof 'AppData')) -or (Test-IsUnder $p $claudeDir) -or $p -match '\\(Temp|tmp)(\\|$)') {
        [void]$uebersprungen.Add("$p (temporaerer/Programm-Ordner)"); continue
    }
    if ($p -ieq $prof -or $p -match '^[A-Za-z]:\\$') {
        foreach ($f in @('CLAUDE.md', 'CLAUDE.local.md', '.mcp.json')) {
            [void](Add-Entry 'Projekte' "$p\$f (Claude im Benutzerordner/Laufwerk gestartet)" (Join-Path $p $f) 'mit' '' -Spezial 'projektdatei')
        }
        continue
    }
    $o = Add-Entry 'Projekte' $p $p 'mit' '' $script:NeuInstallierbar -Spezial 'projekt'
    if (-not $o) { continue }
    $h = @()
    if ($k.Sitzungsordner.Count) { $h += 'Claude-Sitzungen' }
    foreach ($f in @('.claude', 'CLAUDE.md', '.mcp.json')) { if (Test-Path -LiteralPath (Join-Path $p $f)) { $h += $f } }
    if ($gitDa -and (Test-Path -LiteralPath (Join-Path $p '.git'))) {
        $remote = Invoke-Tool git @('-C', $p, 'remote', 'get-url', 'origin')
        $offen = @((Invoke-Tool git @('-C', $p, 'status', '--porcelain')) -split "`n" | Where-Object { $_ }).Count
        $ungepusht = Invoke-Tool git @('-C', $p, 'rev-list', '--count', '--branches', '--not', '--remotes')
        if ($remote) { $h += "Git: $(Hide-Secrets $remote)" } else { $h += 'Git ohne Remote (nur lokal!)' }
        if ($offen) { $h += "$offen ungesicherte Aenderungen" }
        if ($ungepusht -and $ungepusht -ne '0') { $h += "$ungepusht nicht gepushte Commits" }
    }
    if ($p -match '\\OneDrive') { $h += 'liegt in OneDrive (wird evtl. ohnehin synchronisiert)' }
    $o.Hinweis = ($h -join '; ')
    $o.NeuInstallieren = @(Get-NeuInstallHinweise $p)
    if ($o.Bytes -gt 5GB) { $o.Empfehlung = 'optional'; $o.Hinweis += '; SEHR GROSS' }
}

# ---------- 6. MCP-Server und Hooks: Abhaengigkeiten ----------
Write-Schritt 'MCP-Server und Hooks'
$mcp = New-Object System.Collections.ArrayList
function Add-McpServers($Dict, [string]$Quelle) {
    if (-not ($Dict -is [System.Collections.IDictionary])) { return }
    foreach ($name in @($Dict.PSBase.Keys)) {
        $c = $Dict[$name]
        if (-not ($c -is [System.Collections.IDictionary])) { continue }
        $befehl = if (Test-JsonKey $c 'command') { [string]$c['command'] } else { '' }
        $argList = if (Test-JsonKey $c 'args') { @($c['args'] | ForEach-Object { [string]$_ }) } else { @() }
        $url = if (Test-JsonKey $c 'url') { [string]$c['url'] } else { '' }
        $typ = if (Test-JsonKey $c 'type') { [string]$c['type'] } elseif ($url) { 'http' } else { 'stdio' }
        $envNamen = if ((Test-JsonKey $c 'env') -and $c['env'] -is [System.Collections.IDictionary]) { @($c['env'].PSBase.Keys) } else { @() }
        $headerNamen = if ((Test-JsonKey $c 'headers') -and $c['headers'] -is [System.Collections.IDictionary]) { @($c['headers'].PSBase.Keys) } else { @() }
        [void]$mcp.Add([pscustomobject]@{
                Quelle = $Quelle; Name = $name; Typ = $typ; Befehl = $befehl; Args = $argList; Url = $url
                EnvNamen = $envNamen; HeaderNamen = $headerNamen
                Geheim = [bool](@($envNamen + $headerNamen) | Where-Object { $_ -match '(?i)key|token|secret|pass|auth' })
            })
    }
}
if ($cj -is [System.Collections.IDictionary]) {
    if (Test-JsonKey $cj 'mcpServers') { Add-McpServers $cj['mcpServers'] '.claude.json (global)' }
    if (Test-JsonKey $cj 'projects') {
        foreach ($pk in @($cj['projects'].PSBase.Keys)) {
            $pc = $cj['projects'][$pk]
            if ($pc -is [System.Collections.IDictionary] -and (Test-JsonKey $pc 'mcpServers')) { Add-McpServers $pc['mcpServers'] ".claude.json (Projekt $pk)" }
        }
    }
}
if ($dcfg -is [System.Collections.IDictionary] -and (Test-JsonKey $dcfg 'mcpServers')) { Add-McpServers $dcfg['mcpServers'] 'Claude Desktop' }
$settingsDateien = @((Join-Path $claudeDir 'settings.json'), (Join-Path $claudeDir 'settings.local.json'))
foreach ($x in @($E | Where-Object { $_.Spezial -eq 'projekt' -or $_.Spezial -eq 'projektdatei' })) {
    $basisDir = if ($x.Spezial -eq 'projekt') { $x.Pfad } else { Split-Path -Parent $x.Pfad }
    $mj = Read-JsonFile (Join-Path $basisDir '.mcp.json')
    if ($mj -is [System.Collections.IDictionary] -and (Test-JsonKey $mj 'mcpServers')) { Add-McpServers $mj['mcpServers'] "$basisDir\.mcp.json" }
    $settingsDateien += (Join-Path $basisDir '.claude\settings.json'), (Join-Path $basisDir '.claude\settings.local.json')
}
$befehle = New-Object System.Collections.ArrayList
foreach ($s in $mcp) { if ($s.Befehl) { [void]$befehle.Add([pscustomobject]@{ Quelle = "MCP $($s.Name)"; Befehl = (@($s.Befehl) + $s.Args) -join ' '; Programm = $s.Befehl; Args = $s.Args }) } }
foreach ($sd in $settingsDateien) {
    $js = Read-JsonFile $sd
    foreach ($c in @(Get-KeyValues $js 'command')) { [void]$befehle.Add([pscustomobject]@{ Quelle = "Hook/Statuszeile in $sd"; Befehl = $c; Programm = (($c.Trim() -split '\s+')[0].Trim('"')); Args = @() }) }
}

function Get-PathsFromCommand([string]$Befehl) {
    $res = @()
    $x = [Environment]::ExpandEnvironmentVariables($Befehl)
    $x = $x.Replace('$env:USERPROFILE', $prof).Replace('${env:USERPROFILE}', $prof).Replace('$HOME', $prof)
    $x = [regex]::Replace($x, '(^|[\s"''=])~(?=[\\/])', { param($m) $m.Groups[1].Value + $prof })
    foreach ($m in [regex]::Matches($x, '[A-Za-z]:[\\/][^"''|<>*?\r\n]*')) {
        $kand = $m.Value.Trim()
        while ($kand) {
            $k2 = $kand.TrimEnd(' ', ',', ';', ')') -replace '/', '\'
            if (Test-Path -LiteralPath $k2) { $res += $k2; break }
            $i = $kand.LastIndexOf(' ')
            if ($i -lt 3) { break }
            $kand = $kand.Substring(0, $i)
        }
    }
    return $res
}
function Get-DepRoot([string]$p) {
    $item = Get-Item -LiteralPath $p -Force
    $cur = if ($item.PSIsContainer) { $item.FullName } else { $item.DirectoryName }
    for ($i = 0; $i -lt 4 -and $cur; $i++) {
        if ($cur -ieq $prof -or $cur -match '^[A-Za-z]:\\?$') { break }
        foreach ($mk in @('package.json', 'pyproject.toml', 'requirements.txt', 'setup.py', '.git', 'go.mod', 'Cargo.toml')) {
            if (Test-Path -LiteralPath (Join-Path $cur $mk)) { return $cur }
        }
        $cur = Split-Path -Parent $cur
    }
    return $p
}
$programmOrte = @($env:SystemRoot, $env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:ProgramData,
    (Join-Path $env:LOCALAPPDATA 'Programs'), (Join-Path $env:APPDATA 'npm'), (Join-Path $env:LOCALAPPDATA 'Microsoft'),
    (Join-Path $prof '.local\bin'), (Join-Path $prof 'scoop'), (Join-Path $prof '.cargo'), (Join-Path $prof '.bun')) | Where-Object { $_ }
$werkzeuge = [ordered]@{}
$npxPakete = New-Object System.Collections.ArrayList
foreach ($b in $befehle) {
    $prog = ''
    try { $prog = [System.IO.Path]::GetFileNameWithoutExtension(($b.Programm -replace '/', '\')) } catch { }
    if ($prog) { if (-not $werkzeuge.Contains($prog.ToLower())) { $werkzeuge[$prog.ToLower()] = $b.Quelle } }
    if ($prog -in @('npx', 'uvx', 'bunx', 'pnpx') -and $b.Args.Count) {
        $pk = @($b.Args | Where-Object { $_ -notmatch '^-' }) | Select-Object -First 1
        if ($pk) { [void]$npxPakete.Add("$prog $pk") }
    }
    foreach ($pfad in (Get-PathsFromCommand $b.Befehl)) {
        $istProgramm = $false
        foreach ($po in $programmOrte) { if (Test-IsUnder $pfad $po) { $istProgramm = $true } }
        if ($istProgramm) { continue }
        $wurzel = Get-DepRoot $pfad
        $o = Add-Entry 'MCP/Hook-Abhaengigkeiten' "$wurzel (benutzt von: $($b.Quelle))" $wurzel 'mit' '' $script:NeuInstallierbar -Spezial 'abhaengigkeit'
        if ($o -and (Test-Path -LiteralPath $wurzel -PathType Container)) { $o.NeuInstallieren = @(Get-NeuInstallHinweise $wurzel) }
    }
}

# ---------- 7. Exporte, Downloads, Artefakte ----------
Write-Schritt 'Downloads, Desktop, Dokumente nach Claude-Dateien durchsuchen'
$downloads = $prof + '\Downloads'
try { $dl = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' -ErrorAction Stop).'{374DE290-123F-4565-9164-39C4925E467B}'; if ($dl) { $downloads = $dl } } catch { }
$suchOrte = @($downloads, [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('MyDocuments')) | Select-Object -Unique
$muster = '(?i)claude|anthropic|\.dxt$|\.mcpb$|^data-\d{4}-\d{2}-\d{2}.*\.zip$|^conversations\.json$'
foreach ($o in $suchOrte) {
    if (-not $o -or -not (Test-Path -LiteralPath $o)) { continue }
    $treffer = @(Get-ChildItem -LiteralPath $o -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $muster -and $_.FullName -notmatch '\\(node_modules|\.git|\.venv|venv|\.claude)\\' -and
            $_.Name -notmatch '^Claude-Umzug' -and -not (Test-IsUnder $_.FullName $PSScriptRoot) } |
        Sort-Object { $_.FullName.Length })
    foreach ($t in $treffer) { [void](Add-Entry 'Exporte/Downloads' $t.FullName $t.FullName 'optional' '') }
}

# ---------- 8. Sonstiges, an das man leicht nicht denkt ----------
Write-Schritt 'Sonstiges'
[void](Add-Entry 'Sonstiges' '.gitconfig - Git-Name/E-Mail/Einstellungen' (Join-Path $prof '.gitconfig') 'mit' '')
[void](Add-Entry 'Sonstiges' '.ssh - SSH-Schluessel (z. B. fuer GitHub)' (Join-Path $prof '.ssh') 'optional' 'Geheimnis. Alternativ auf dem neuen Rechner neu erzeugen.' -Geheim)
[void](Add-Entry 'Sonstiges' '.npmrc - npm-Einstellungen' (Join-Path $prof '.npmrc') 'optional' 'kann Tokens enthalten' -Geheim)
[void](Add-Entry 'Sonstiges' '.config\gh - GitHub-CLI-Anmeldung' (Join-Path $prof '.config\gh') 'nein' 'besser neu anmelden: gh auth login' -Geheim)
$fang = @(
    @{ P = $prof; T = 'Benutzerordner' }, @{ P = $env:APPDATA; T = 'AppData\Roaming' }, @{ P = $env:LOCALAPPDATA; T = 'AppData\Local' },
    @{ P = $env:ProgramData; T = 'ProgramData' }, @{ P = (Join-Path $prof '.config'); T = '.config' },
    @{ P = (Join-Path $prof '.local\share'); T = '.local\share' }, @{ P = (Join-Path $prof '.local\state'); T = '.local\state' }
)
foreach ($f in $fang) {
    if (-not $f.P -or -not (Test-Path -LiteralPath $f.P)) { continue }
    foreach ($c in @(Get-ChildItem -LiteralPath $f.P -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '(?i)claude|anthropic|^\.mcp' })) {
        [void](Add-Entry 'Sonstiges' "$($c.FullName) (gefunden in $($f.T))" $c.FullName 'optional' 'Claude-bezogen, nicht genau bekannt')
    }
}
foreach ($x in $E) { if ($x.Gruppe -eq 'Sonstiges' -and $x.Empfehlung -eq 'optional' -and $x.Geheim) { $x.Mitnehmen = $false } }
foreach ($x in $E) { if ($x.Bytes -gt 1GB -and $x.Hinweis -notmatch 'GROSS') { $x.Hinweis = ($x.Hinweis + '; SEHR GROSS').TrimStart('; ') } }

# ---------- 9. Software, Umgebung, Prozesse, Aufgaben ----------
Write-Schritt 'installierte Werkzeuge'
$tools = [ordered]@{}
foreach ($t in @(@('node', '--version'), @('npm', '--version'), @('python', '--version'), @('py', '--version'), @('pip', '--version'),
        @('pipx', '--version'), @('uv', '--version'), @('git', '--version'), @('gh', '--version'), @('docker', '--version'),
        @('bun', '--version'), @('deno', '--version'), @('claude', '--version'), @('winget', '--version'), @('pwsh', '--version'))) {
    $v = Invoke-Tool $t[0] @($t[1])
    $tools[$t[0]] = if ($v) { ($v -split "`n")[0] } else { $null }
}
$npmGlobal = @()
$npmJson = Invoke-Tool npm @('ls', '-g', '--depth=0', '--json')
if ($npmJson) { try { $nj = $npmJson | ConvertFrom-Json; if ($nj.dependencies) { $npmGlobal = @($nj.dependencies.PSObject.Properties | ForEach-Object { "$($_.Name)@$($_.Value.version)" }) } } catch { } }
$pyListe = Invoke-Tool py @('-0p')
$uvTools = @((Invoke-Tool uv @('tool', 'list')) -split "`n" | Where-Object { $_ -and $_ -notmatch '^\s*-' -and $_ -notmatch '^No tools' })
$pipxListe = @((Invoke-Tool pipx @('list', '--short')) -split "`n" | Where-Object { $_ })

$umgebung = @()
$uv = [Environment]::GetEnvironmentVariables('User')
foreach ($n in ($uv.Keys | Sort-Object)) {
    if ($n -in @('Path', 'TEMP', 'TMP') -or $n -like 'OneDrive*') { continue }
    $umgebung += [pscustomobject]@{ Name = $n; Geheim = ($n -match '(?i)key|token|secret|pass|auth|cred') }
}
foreach ($n in @('ANTHROPIC_API_KEY', 'ANTHROPIC_BASE_URL', 'CLAUDE_CONFIG_DIR', 'CLAUDE_CODE_GIT_BASH_PATH')) {
    $mv = [Environment]::GetEnvironmentVariable($n, 'Machine')
    if ($mv) { $umgebung += [pscustomobject]@{ Name = "$n (systemweit)"; Geheim = ($n -match 'KEY') } }
}
$prozesse = @(Get-ClaudeProcesses)
$aufgaben = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
        $_.TaskPath -notlike '\Microsoft\*' -and (($_.TaskName -match '(?i)claude|anthropic') -or
            ((@($_.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -join ' ') -match '(?i)claude|anthropic|mcp'))
    } | ForEach-Object { [pscustomobject]@{ Name = $_.TaskName; Pfad = $_.TaskPath } })

# ---------- Bericht ----------
$frei = $null
try { $frei = ([System.IO.DriveInfo]::new($zielLaufwerk)).AvailableFreeSpace } catch { }
$summeMit = ($E | Where-Object { $_.Mitnehmen } | Measure-Object Bytes -Sum).Sum
$summeAlle = ($E | Measure-Object Bytes -Sum).Sum
$summeExcl = ($E | Measure-Object ExclBytes -Sum).Sum

$L = New-Object System.Collections.ArrayList
function L([string]$t = '') { [void]$L.Add($t) }
L "CLAUDE-UMZUG - BESTANDSAUFNAHME   $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
L "Rechner: $env:COMPUTERNAME   Benutzer: $env:USERNAME   Profil: $prof"
L "Claude-Desktop-Daten: $desktopDir"
L ''
L 'Legende: [x] = wird vorgeschlagen   [ ] = nicht vorgeschlagen   G = enthaelt Geheimnisse'
L '         Groesse = was kopiert wuerde (ohne node_modules/.venv usw.); "+ X neu installierbar" = weggelassen'
foreach ($g in @('Claude Code', 'Claude Desktop', 'Projekte', 'MCP/Hook-Abhaengigkeiten', 'Exporte/Downloads', 'Sonstiges', 'Programme (neu installieren)')) {
    $grp = @($E | Where-Object { $_.Gruppe -eq $g })
    if (-not $grp.Count) { continue }
    L ''
    L "== $g =="
    foreach ($x in $grp) {
        $mark = if ($x.Mitnehmen) { '[x]' } else { '[ ]' }
        $gz = if ($x.Geheim) { 'G' } else { ' ' }
        L ("{0,3} {1} {2} {3,10} {4,8} Dat.  {5}" -f $x.Nr, $mark, $gz, (Format-Size $x.Bytes), $x.Dateien, $x.Titel)
        $zusatz = @()
        if ($x.Titel -ne $x.Pfad -and $x.Gruppe -ne 'Projekte') { $zusatz += $x.Pfad }
        if ($x.Hinweis) { $zusatz += $x.Hinweis }
        if ($x.ExclBytes -gt 0) { $zusatz += "+ $(Format-Size $x.ExclBytes) neu installierbar (node_modules/.venv ...)" }
        if ($x.NeuInstallieren.Count) { $zusatz += "danach: $($x.NeuInstallieren -join ' / ')" }
        if ($x.Geheimnisse.Count) { $zusatz += "Geheimnis-Dateien: $(($x.Geheimnisse | Select-Object -First 8) -join ', ')$(if ($x.Geheimnisse.Count -gt 8) { ' ...' })" }
        if ($x.Lesefehler) { $zusatz += "$($x.Lesefehler) Ordner nicht lesbar" }
        foreach ($z in $zusatz) { L ("                                      {0}" -f $z) }
    }
}
L ''
L '== Sitzungsordner unter .claude\projects =='
foreach ($s in ($sitzungsordner | Sort-Object Bytes -Descending)) {
    $p = if ($s.Projekt) { $s.Projekt } else { '(Projektpfad unbekannt)' }
    L ("  {0,10}  {1,4} Sitzungen  zuletzt {2}  {3}{4}" -f (Format-Size $s.Bytes), $s.Sitzungen, $s.Zuletzt, $p, $(if ($s.Memory) { '  [Memory]' } else { '' }))
}
if ($fehlendeProjekte.Count) {
    L ''
    L '== Projekte, die Claude kennt, die es aber nicht mehr gibt (nur Sitzungsverlauf vorhanden) =='
    foreach ($f in $fehlendeProjekte) { L "  $($f.Pfad)   ($($f.Quellen))" }
}
if ($uebersprungen.Count) { L ''; L '== Bewusst uebersprungen =='; foreach ($u in $uebersprungen) { L "  $u" } }
L ''
L '== MCP-Server =='
if (-not $mcp.Count) { L '  keine gefunden' }
foreach ($s in $mcp) {
    $was = if ($s.Url) { "$($s.Typ) $(Hide-Secrets $s.Url)" } else { Hide-Secrets ((@($s.Befehl) + $s.Args) -join ' ') }
    $envText = if ($s.EnvNamen.Count) { "  env: $($s.EnvNamen -join ', ')" } else { '' }
    L ("  {0}  [{1}]  {2}{3}{4}" -f $s.Name, $s.Quelle, $was, $envText, $(if ($s.Geheim) { '  G' } else { '' }))
}
if ($npxPakete.Count) { L "  per npx/uvx geladen (braucht nur Node/uv): $(@($npxPakete | Select-Object -Unique) -join ', ')" }
if ($erweiterungen.Count) { L ''; L '== Claude-Desktop-Erweiterungen =='; foreach ($x in $erweiterungen) { L "  $($x.Name)  ($($x.Id))" } }
L ''
L '== Von MCP-Servern/Hooks benutzte Programme =='
foreach ($k in $werkzeuge.Keys) { L "  $k   ($($werkzeuge[$k]))" }
L ''
L '== Installierte Werkzeuge (auf dem neuen Rechner nachinstallieren) =='
foreach ($k in $tools.Keys) { L ("  {0,-8} {1}" -f $k, $(if ($tools[$k]) { $tools[$k] } else { '-' })) }
if ($npmGlobal.Count) { L "  npm global: $($npmGlobal -join ', ')" }
if ($pyListe) { L "  Python-Versionen (py -0p): $(($pyListe -split "`n" | ForEach-Object { $_.Trim() }) -join ' | ')" }
if ($uvTools.Count) { L "  uv tools: $($uvTools -join ', ')" }
if ($pipxListe.Count) { L "  pipx: $($pipxListe -join ', ')" }
L ''
L '== Benutzer-Umgebungsvariablen (nur Namen) =='
if (-not $umgebung.Count) { L '  keine besonderen' }
foreach ($u in $umgebung) { L "  $($u.Name)$(if ($u.Geheim) { '   G' })" }
if ($aufgaben.Count) { L ''; L '== Windows-Aufgabenplanung mit Claude-Bezug =='; foreach ($a in $aufgaben) { L "  $($a.Pfad)$($a.Name)" } }
L ''
L '== Laufende Claude-Prozesse (werden vor dem Sichern nur nach Rueckfrage beendet) =='
if (-not $prozesse.Count) { L '  keine' }
foreach ($p in $prozesse) { L "  $($p.Name)  PID $($p.Id)  $($p.Pfad)" }
L ''
L '== SUMME =='
L ("  Vorgeschlagen [x]:            {0}" -f (Format-Size $summeMit))
L ("  Alles zusammen:               {0}" -f (Format-Size $summeAlle))
L ("  Weggelassen (neu installierbar): {0}" -f (Format-Size $summeExcl))
L ("  Frei auf {0}                  {1}" -f $zielLaufwerk, $(if ($null -ne $frei) { Format-Size $frei } else { 'unbekannt (Platte angeschlossen?)' }))
if ($null -ne $frei -and $summeMit -gt $frei) { L '  ACHTUNG: Der Platz reicht nicht fuer die Vorschlaege!' }
L ''
L 'Geheimnisse (G): API-Schluessel, Tokens, .env-Dateien, SSH-Schluessel. Wenn sie mitkommen, die Platte danach'
L 'sicher aufbewahren und den Ordner Daten nach dem Umzug loeschen.'
L ''
L 'WEITER: Sag Claude, was mit soll und was nicht (z. B. "ohne 12 und 15, mit 30"), oder starte Sichern.bat -'
L 'dort kannst du die Auswahl ebenfalls aendern.'

New-Item -ItemType Directory -Path (Join-Path $Ziel 'Inventur') -Force | Out-Null
$bericht = Join-Path $Ziel 'Inventur\Bericht.txt'
Write-TextNoBom $bericht (($L -join "`r`n") + "`r`n")
$roh = [pscustomobject]@{
    Erstellt = (Get-Date).ToString('s'); Rechner = $env:COMPUTERNAME; Benutzername = $env:USERNAME; Profil = $prof
    AppData = $env:APPDATA; LocalAppData = $env:LOCALAPPDATA; DesktopDaten = $desktopDir
    Eintraege = @($E); Sitzungsordner = @($sitzungsordner); FehlendeProjekte = @($fehlendeProjekte)
    Mcp = @($mcp); NpxPakete = @($npxPakete | Select-Object -Unique); Werkzeuge = @($werkzeuge.Keys); Erweiterungen = @($erweiterungen)
    Tools = $tools; NpmGlobal = @($npmGlobal); UvTools = @($uvTools); Pipx = @($pipxListe); Umgebung = @($umgebung); Aufgaben = @($aufgaben)
}
Write-TextNoBom (Join-Path $Ziel 'Inventur\inventur-roh.json') (ConvertTo-Json -InputObject $roh -Depth 8)

Write-Host ''
$L | ForEach-Object { Write-Host $_ }
Write-Host ''
Write-Host "Bericht gespeichert: $bericht" -ForegroundColor Green
Write-Host 'Der Bericht enthaelt Pfade und Projektnamen, aber keine Inhalte von Geheimnissen.' -ForegroundColor Green
