# Wiederherstellen auf dem NEUEN Rechner. Start per Doppelklick auf Wiederherstellen.bat.
# - sichert vorhandene Claude-Daten vorher als *.vor-umzug-DATUM
# - ueberschreibt nichts Neueres (robocopy /XO), fuehrt settings.json, .claude.json und
#   claude_desktop_config.json zusammen (UTF-8 ohne BOM)
# - passt Pfade an, wenn der Benutzername anders ist (auch die Ordnernamen unter .claude\projects)
# - legt Projekte an dieselben Pfade zurueck und zeigt am Ende eine Checkliste
param([string]$Quelle = $PSScriptRoot)

. (Join-Path $PSScriptRoot 'Gemeinsam.ps1')

$invPfad = Join-Path $Quelle 'inventar.json'
if (-not (Test-Path -LiteralPath $invPfad)) { Write-Host "inventar.json nicht gefunden in $Quelle. Wurde Sichern.bat ausgefuehrt?" -ForegroundColor Red; return }
$inv = (Read-Text $invPfad) | ConvertFrom-Json

$datum = Get-Date -Format 'yyyyMMdd-HHmm'
$suffix = ".vor-umzug-$datum"
$neuProf = $env:USERPROFILE.TrimEnd('\')
$neuDesktop = Get-DesktopDataDir
$altProf = ([string]$inv.AltesProfil).TrimEnd('\')
$altDesktop = ([string]$inv.AlteDesktopDaten).TrimEnd('\')
$logDir = Join-Path $Quelle 'Logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$log = Join-Path $logDir "wiederherstellen-$datum.log"

$erledigt = New-Object System.Collections.ArrayList
$probleme = New-Object System.Collections.ArrayList
$konfliktText = New-Object System.Collections.ArrayList
$uebersprungen = New-Object System.Collections.ArrayList
$nachInstall = New-Object System.Collections.ArrayList
$umbenannt = 0

Write-Host ''
Write-Host '=== Claude-Umzug: Wiederherstellen ===' -ForegroundColor Cyan
Write-Host "Sicherung vom $($inv.Erstellt) von Rechner $($inv.Rechner)"
Write-Host "Alter Benutzerordner: $altProf"
Write-Host "Neuer Benutzerordner: $neuProf"
Write-Host "Claude-Desktop-Daten: $neuDesktop"
if ($env:COMPUTERNAME -eq $inv.Rechner -and $altProf -ieq $neuProf) {
    Write-Host 'Das sieht nach dem ALTEN Rechner aus.' -ForegroundColor Yellow
    if (-not (Read-JaNein 'Wirklich hier wiederherstellen?' $false)) { return }
}
if (-not (Test-Path -LiteralPath (Join-Path $neuProf '.claude.json'))) {
    Write-Host 'Tipp: Claude Code wurde hier wohl noch nie gestartet. Besser vorher einmal "claude" starten, anmelden, beenden.' -ForegroundColor Yellow
    if (-not (Read-JaNein 'Trotzdem jetzt fortfahren?' $true)) { return }
}
Write-Host ''
Write-Host 'Es werden vorhandene Claude-Daten gesichert und dann die Daten vom alten Rechner eingespielt.'
if (-not (Read-JaNein 'Los geht''s?' $true)) { return }
if (-not (Stop-ClaudeProcesses 'Claude muss beim Einspielen geschlossen sein')) { return }

# ---------- Pfad-Zuordnungen ----------
$zu = New-Object System.Collections.ArrayList
if ($altDesktop -and $altDesktop -ine $neuDesktop) { [void]$zu.Add(@{ Alt = $altDesktop; Neu = $neuDesktop }) }
if ($altProf -ine $neuProf) { [void]$zu.Add(@{ Alt = $altProf; Neu = $neuProf }) }

$eintraege = @($inv.Eintraege)
$lwZiel = @{}
foreach ($e in ($eintraege | Where-Object { $_.Basis -eq 'Absolut' })) {
    $lw = (Split-Path -Qualifier $e.Original).ToUpper()
    if ($lwZiel.ContainsKey($lw)) { continue }
    if (Test-Path -LiteralPath "$lw\") { $lwZiel[$lw] = "$lw\"; continue }
    Write-Host ''
    Write-Host "Laufwerk $lw gibt es hier nicht. Betroffen:" -ForegroundColor Yellow
    $eintraege | Where-Object { $_.Basis -eq 'Absolut' -and $_.Original -like "$lw*" } | ForEach-Object { Write-Host "  $($_.Original)" }
    $a = Read-Host "Neuer Basisordner dafuer (z. B. C:\Laufwerk-$($lw.TrimEnd(':'))), Enter = ueberspringen"
    $lwZiel[$lw] = if ([string]::IsNullOrWhiteSpace($a)) { $null } else { $a.Trim().Trim('"').TrimEnd('\') + '\' }
}
function Get-Target($e) {
    switch ($e.Basis) {
        'Profil' { return (Join-Rel $neuProf $e.Rel) }
        'Desktop' { return (Join-Rel $neuDesktop $e.Rel) }
        default {
            $lw = (Split-Path -Qualifier $e.Original).ToUpper()
            $b = $lwZiel[$lw]
            if (-not $b) { return $null }
            return ($b + $e.Original.Substring(3)).TrimEnd('\')
        }
    }
}
foreach ($e in ($eintraege | Where-Object { $_.Basis -eq 'Absolut' })) {
    $t = Get-Target $e
    if ($t -and $t -ine $e.Original) { [void]$zu.Add(@{ Alt = $e.Original; Neu = $t }) }
}
$zu = @($zu | Sort-Object { $_.Alt.Length } -Descending)
if ($zu.Count) {
    Write-Host ''
    Write-Host 'Pfade werden angepasst:'
    foreach ($z in $zu) { Write-Host "  $($z.Alt)  ->  $($z.Neu)" }
}

# ---------- 1. Vorhandenes sichern ----------
Write-Host ''
Write-Host "Vorhandene Claude-Daten sichern (*$suffix) ..."
$vorher = @(
    @{ P = (Join-Path $neuProf '.claude'); X = @() },
    @{ P = (Join-Path $neuProf '.claude.json'); X = @() },
    @{ P = $neuDesktop; X = $script:DesktopCaches }
)
if ((Join-Path $env:APPDATA 'Claude') -ine $neuDesktop) { $vorher += @{ P = (Join-Path $env:APPDATA 'Claude'); X = $script:DesktopCaches } }
$sicherungen = @()
foreach ($v in $vorher) {
    if (-not (Test-Path -LiteralPath $v.P)) { continue }
    $b = $v.P + $suffix
    if ((Get-Item -LiteralPath $v.P -Force).PSIsContainer) {
        $r = Invoke-Robocopy $v.P $b -AusschlussOrdner $v.X -AusschlussDateien $v.X -Log $log
    }
    else {
        $r = [pscustomobject]@{ Code = 0 }
        try { Copy-Item -LiteralPath $v.P -Destination $b -Force -ErrorAction Stop } catch { $r.Code = 8 }
    }
    if ($r.Code -ge 8) { [void]$probleme.Add("Vorab-Sicherung von $($v.P) unvollstaendig (robocopy $($r.Code))") }
    $sicherungen += $b
    Write-Host "  $b"
}
if ($sicherungen.Count -and ($probleme.Count) -and -not (Read-JaNein 'Die Vorab-Sicherung hatte Fehler. Trotzdem weiter?' $false)) { return }

# ---------- 2. Einspielen ----------
$claudeJsonAusschluss = '^(oauthAccount|userID|anonymousId|primaryApiKey|customApiKeyResponses|installMethod|autoUpdates|firstStartTime|' +
'claudeCodeFirstTokenDate|numStartups|lastOnboardingVersion|hasCompletedOnboarding|lastReleaseNotesSeen|changelogLastFetched|' +
'cachedChangelog|isQualifiedForDataSharing|subscriptionNoticeCount|hasAvailableSubscription|recommendedSubscription|' +
'fallbackAvailableWarningThreshold|migrationVersion|statsig.*|cached.*|.*Cache|s1m.*|passesEligibility.*|.*[Mm]igrat.*|' +
'officialMarketplaceAutoInstall.*|lastPlanModeUse)$'
$desktopAppAusschluss = '(?i)token|oauth|secret|cookie|session|account|user.?id|device|anonymous|install|update'

function Merge-JsonFile([string]$Src, [string]$Dst, [string]$Ausschluss, [string]$Name) {
    $altText = Convert-PathsInText (Read-Text $Src) $zu
    $neuText = if (Test-Path -LiteralPath $Dst) { Read-Text $Dst } else { '{}' }
    if ([string]::IsNullOrWhiteSpace($neuText)) { $neuText = '{}' }
    $alt = $null; $neu = $null
    try { $alt = ConvertFrom-JsonText $altText; $neu = ConvertFrom-JsonText $neuText } catch { }
    if (-not ($alt -is [System.Collections.IDictionary]) -or -not ($neu -is [System.Collections.IDictionary])) {
        $neben = "$Dst.vom-alten-rechner"
        Write-TextNoBom $neben $altText
        [void]$probleme.Add("$Name konnte nicht zusammengefuehrt werden. Alte Fassung liegt als $neben daneben - Inhalte bei Bedarf von Hand uebernehmen.")
        return
    }
    $konf = New-Object System.Collections.ArrayList
    $res = Merge-JsonValue $neu $alt '' $konf $Ausschluss
    Write-TextNoBom $Dst ((ConvertTo-JsonText $res) + "`n")
    [void]$erledigt.Add("$Name zusammengefuehrt$(if ($konf.Count) { " ($($konf.Count) Werte vom neuen Rechner behalten)" })")
    if ($konf.Count) {
        [void]$konfliktText.Add("${Name}:")
        foreach ($k in ($konf | Select-Object -First 25)) { [void]$konfliktText.Add("    $k") }
        if ($konf.Count -gt 25) { [void]$konfliktText.Add("    ... und $($konf.Count - 25) weitere") }
    }
}

$umschreiben = New-Object System.Collections.ArrayList   # @{ P = Pfad; Rekursiv = bool }
$i = 0
foreach ($e in $eintraege) {
    $i++
    Write-Progress -Activity 'Wiederherstellen' -Status $e.Titel -PercentComplete ([int](100 * $i / $eintraege.Count))
    $src = Join-Path $Quelle $e.Sicherung
    if (-not (Test-Path -LiteralPath $src)) { [void]$uebersprungen.Add("$($e.Titel) (nicht in der Sicherung)"); continue }
    $dst = Get-Target $e
    if (-not $dst) { [void]$uebersprungen.Add("$($e.Titel) (Laufwerk uebersprungen)"); continue }
    Write-Host "  $($e.Titel)"
    try {
        switch ($e.Spezial) {
            'settings-merge' { Merge-JsonFile $src $dst '' (Split-Path -Leaf $dst) }
            'claudejson' { Merge-JsonFile $src $dst $claudeJsonAusschluss '.claude.json' }
            'desktopconfig' { Merge-JsonFile $src $dst '' 'claude_desktop_config.json' }
            'desktopappconfig' { Merge-JsonFile $src $dst $desktopAppAusschluss 'Claude-Desktop config.json' }
            'projects' {
                New-Item -ItemType Directory -Path $dst -Force | Out-Null
                foreach ($d in (Get-ChildItem -LiteralPath $src -Directory -Force)) {
                    $neuName = Convert-ProjectFolderName $d.Name $zu
                    if ($neuName -ne $d.Name) { $script:umbenannt++ }
                    $r = Invoke-Robocopy $d.FullName (Join-Path $dst $neuName) -NurNeuere -Log $log
                    if ($r.Code -ge 8) { [void]$probleme.Add("Sitzungsordner $($d.Name): robocopy-Fehler $($r.Code)") }
                }
                $r = Invoke-Robocopy $src $dst -Datei '*.*' -NurNeuere -Log $log
                [void]$erledigt.Add('Sitzungsverlaeufe (.claude\projects) eingespielt')
            }
            default {
                if ($e.Art -eq 'Ordner') { $r = Invoke-Robocopy $src $dst -NurNeuere -Log $log }
                else { $r = Invoke-Robocopy (Split-Path -Parent $src) (Split-Path -Parent $dst) -Datei (Split-Path -Leaf $src) -NurNeuere -Log $log }
                if ($r.Code -ge 8) { [void]$probleme.Add("$($e.Titel): robocopy-Fehler $($r.Code) (z. B. fehlende Rechte), Ziel $dst") }
                else { [void]$erledigt.Add("$($e.Titel) -> $dst") }
            }
        }
    }
    catch { [void]$probleme.Add("$($e.Titel): $($_.Exception.Message)") }
    if ($e.Spezial -eq 'projekt' -or $e.Spezial -eq 'abhaengigkeit') {
        foreach ($f in @('.claude', '.mcp.json', 'CLAUDE.md', 'CLAUDE.local.md')) { [void]$umschreiben.Add(@{ P = (Join-Path $dst $f); Rekursiv = $true }) }
        foreach ($h in @($e.NeuInstallieren)) { if ($h) { [void]$nachInstall.Add("cd `"$dst`"; $h") } }
    }
    elseif ($e.Spezial -eq 'projektdatei') { [void]$umschreiben.Add(@{ P = $dst; Rekursiv = $false }) }
    elseif ($e.Basis -eq 'Desktop' -and $e.Art -eq 'Ordner' -and $e.Rel -eq 'Claude Extensions Settings') { [void]$umschreiben.Add(@{ P = $dst; Rekursiv = $true }) }
}
Write-Progress -Activity 'Wiederherstellen' -Completed

# ---------- 3. Pfade in Dateien anpassen ----------
$umgeschrieben = 0
if ($zu.Count) {
    Write-Host ''
    Write-Host 'Pfade in Claude-Dateien anpassen ...'
    $endungen = @('.json', '.jsonl', '.md', '.txt', '.ps1', '.psm1', '.bat', '.cmd', '.sh', '.py', '.js', '.mjs', '.cjs', '.ts', '.toml', '.yaml', '.yml', '.ini', '.cfg')
    [void]$umschreiben.Add(@{ P = (Join-Path $neuProf '.claude'); Rekursiv = $true })
    foreach ($f in @(Get-ChildItem -LiteralPath $neuDesktop -File -Filter '*.json' -Force -ErrorAction SilentlyContinue)) { [void]$umschreiben.Add(@{ P = $f.FullName; Rekursiv = $false }) }
    foreach ($u in $umschreiben) {
        if (-not (Test-Path -LiteralPath $u.P)) { continue }
        $it = Get-Item -LiteralPath $u.P -Force
        $dateien = if ($it.PSIsContainer) {
            Get-ChildItem -LiteralPath $u.P -Recurse -File -Force -ErrorAction SilentlyContinue |
                Where-Object { $endungen -contains $_.Extension.ToLower() -and $_.FullName -notmatch '\\(file-history|shell-snapshots|node_modules|\.git)\\' }
        } else { @($it) }
        foreach ($d in $dateien) { if (Update-FileText $d.FullName $zu) { $umgeschrieben++ } }
    }
    [void]$erledigt.Add("Pfade in $umgeschrieben Dateien angepasst, $umbenannt Sitzungsordner umbenannt")
}

# ---------- 4. Umgebungsvariablen ----------
$umgPfad = Join-Path $Quelle 'Daten\umgebung.json'
if (Test-Path -LiteralPath $umgPfad) {
    $umg = (Read-Text $umgPfad) | ConvertFrom-Json
    $fehlend = @()
    foreach ($p in @($umg.PSObject.Properties)) {
        if (-not [Environment]::GetEnvironmentVariable($p.Name, 'User')) { $fehlend += $p }
    }
    if ($fehlend.Count) {
        Write-Host ''
        Write-Host 'Diese Benutzer-Umgebungsvariablen fehlen hier:'
        foreach ($p in $fehlend) { Write-Host "  $($p.Name)" }
        if (Read-JaNein 'Setzen?' $true) {
            foreach ($p in $fehlend) { [Environment]::SetEnvironmentVariable($p.Name, (Convert-PathsInText ([string]$p.Value) $zu), 'User') }
            [void]$erledigt.Add("$($fehlend.Count) Umgebungsvariablen gesetzt")
        }
    }
}

foreach ($f in (Get-RobocopyErrors $log)) { [void]$probleme.Add("robocopy: $f") }

# ---------- 5. Checkliste ----------
$C = New-Object System.Collections.ArrayList
function C([string]$t = '') { [void]$C.Add($t) }
C "CHECKLISTE NACH DEM UMZUG   $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
C ''
C '1. PROGRAMME NACHINSTALLIEREN'
$wingetIds = @{ node = 'OpenJS.NodeJS.LTS'; git = 'Git.Git'; gh = 'GitHub.cli'; uv = 'astral-sh.uv'; docker = 'Docker.DockerDesktop';
    bun = 'Oven-sh.Bun'; deno = 'DenoLand.Deno'; pwsh = 'Microsoft.PowerShell'; python = 'Python.Python.3.12'; py = 'Python.Python.3.12' }
$fehltWas = $false
$toolsAlt = $inv.Software.Tools
foreach ($p in @($toolsAlt.PSObject.Properties)) {
    if (-not $p.Value -or $p.Name -in @('winget', 'claude', 'npm', 'pip')) { continue }
    if (Invoke-Tool $p.Name @('--version')) { continue }   # leere Ausgabe = fehlt (auch Store-Platzhalter fuer python)
    $id = $wingetIds[$p.Name]
    if ($p.Name -in @('python', 'py') -and $p.Value -match '(\d+)\.(\d+)') { $id = "Python.Python.$($matches[1]).$($matches[2])" }
    if ($p.Name -eq 'pipx') { C "   [ ] pipx fehlt (alt: $($p.Value))  ->  python -m pip install --user pipx" }
    else { C "   [ ] $($p.Name) fehlt (alt: $($p.Value))  ->  winget install $id" }
    $fehltWas = $true
}
foreach ($w in @($inv.Werkzeuge)) {
    if (-not $w -or $w -in @('cmd', 'powershell', 'pwsh', 'wsl')) { continue }
    if (-not (Get-Command $w -ErrorAction SilentlyContinue)) { C "   [ ] '$w' wird von MCP-Servern/Hooks benutzt, ist hier aber nicht zu finden"; $fehltWas = $true }
}
$npmNeu = @()
$nj = Invoke-Tool npm @('ls', '-g', '--depth=0', '--json')
if ($nj) { try { $o = $nj | ConvertFrom-Json; if ($o.dependencies) { $npmNeu = @($o.dependencies.PSObject.Properties.Name) } } catch { } }
foreach ($pk in @($inv.Software.NpmGlobal)) {
    if (-not $pk) { continue }
    $name = $pk -replace '(?<=.)@[^@]*$', ''
    if ($name -in @('npm', 'corepack') -or $npmNeu -contains $name) { continue }
    if ($name -eq '@anthropic-ai/claude-code' -and (Get-Command claude -ErrorAction SilentlyContinue)) { continue }
    C "   [ ] npm install -g $pk"; $fehltWas = $true
}
$uvNeu = @((Invoke-Tool uv @('tool', 'list')) -split "`n" | ForEach-Object { ($_ -split '\s+')[0] })
foreach ($t in @($inv.Software.UvTools)) { $n = ($t -split '\s+')[0]; if ($n -and $uvNeu -notcontains $n) { C "   [ ] uv tool install $n"; $fehltWas = $true } }
$pipxNeu = @((Invoke-Tool pipx @('list', '--short')) -split "`n" | ForEach-Object { ($_ -split '\s+')[0] })
foreach ($t in @($inv.Software.Pipx)) { $n = ($t -split '\s+')[0]; if ($n -and $pipxNeu -notcontains $n) { C "   [ ] pipx install $n"; $fehltWas = $true } }
if (-not $fehltWas) { C '   Alle Werkzeuge, die MCP-Server und Hooks brauchen, sind vorhanden.' }
C "   [ ] Weitere Programme vom alten Rechner (Liste: software.txt): winget import -i `"$(Join-Path $Quelle 'winget-export.json')`" --ignore-unavailable"
if (Test-Path -LiteralPath (Join-Path $Quelle 'pip-pakete.txt')) { C "   [ ] Python-Pakete bei Bedarf: python -m pip install -r `"$(Join-Path $Quelle 'pip-pakete.txt')`"" }
if ($nachInstall.Count) {
    C '   Abhaengigkeiten in Projekten neu installieren (wurden nicht mitkopiert):'
    foreach ($n in $nachInstall) { C "   [ ] $n" }
}
C '   [ ] Claude-Erweiterung fuer VS Code/JetBrains bei Bedarf neu installieren'
C ''
C '2. NEU ANMELDEN'
C '   [ ] Claude Desktop starten und anmelden (Chats, Projekte, Konnektoren kommen mit dem Konto)'
C '   [ ] Claude Code: im Terminal "claude" starten, ggf. /login'
$remote = @($inv.Mcp | Where-Object { $_.Typ -in @('http', 'sse', 'streamable-http') -or $_.Url })
foreach ($s in $remote) { C "   [ ] MCP-Server '$($s.Name)' ($($s.Quelle)): in Claude Code /mcp -> authentifizieren" }
if (-not $inv.GeheimnisseMitgenommen) {
    foreach ($s in @($inv.Mcp | Where-Object { $_.Geheim })) { C "   [ ] API-Schluessel fuer MCP-Server '$($s.Name)' neu eintragen ($(@($s.EnvNamen + $s.HeaderNamen) -join ', '))" }
    C '   [ ] .env-Dateien und Schluessel wurden NICHT mitgenommen - in den Projekten neu anlegen'
}
if (@($inv.Erweiterungen).Count) {
    C "   [ ] Claude Desktop -> Einstellungen -> Erweiterungen pruefen: $(@($inv.Erweiterungen | ForEach-Object { $_.Name }) -join ', ')"
}
C '   [ ] Git: beim ersten Push/Pull fragt der Git Credential Manager nach der GitHub-Anmeldung'
if ($inv.Software.Tools.gh) { C '   [ ] GitHub CLI: gh auth login' }
if (-not (Test-Path -LiteralPath (Join-Path $neuProf '.ssh'))) { C '   [ ] SSH-Schluessel fehlen: neu erzeugen (ssh-keygen -t ed25519) und bei GitHub eintragen, falls du SSH nutzt' }
C ''
C '3. ERLEDIGT'
foreach ($x in $erledigt) { C "   - $x" }
if ($sicherungen.Count) { C '   Fruehere Daten dieses Rechners gesichert unter:'; foreach ($s in $sicherungen) { C "     $s" } }
if ($konfliktText.Count) {
    C ''
    C '4. ZUSAMMENFUEHREN: hier war auf beiden Rechnern etwas anderes eingestellt - der Wert des NEUEN Rechners ist geblieben'
    C '   (die alte Fassung steht in der Sicherung unter Daten\ ... falls du etwas davon willst)'
    foreach ($k in $konfliktText) { C "   $k" }
}
if ($uebersprungen.Count) { C ''; C '5. UEBERSPRUNGEN'; foreach ($u in $uebersprungen) { C "   - $u" } }
if ($probleme.Count) { C ''; C '6. PROBLEME'; foreach ($p in $probleme) { C "   ! $p" }; C "   Log: $log" }
if (@($inv.Aufgaben).Count) {
    C ''
    C '7. WINDOWS-AUFGABENPLANUNG'
    foreach ($a in $inv.Aufgaben) { C "   [ ] $($a.Name): bei Bedarf in der Aufgabenplanung -> Aufgabe importieren: $(Join-Path $Quelle $a.Datei)" }
}
C ''
C 'ZUM SCHLUSS'
C '   [ ] Claude Desktop und Claude Code starten, MCP-Server pruefen (Claude Code: /mcp), alte Sitzung testen (claude --resume)'
C '   [ ] Wenn alles laeuft: die *.vor-umzug-*-Ordner loeschen'
if ($inv.GeheimnisseMitgenommen) { C '   [ ] Die Sicherung enthaelt Geheimnisse: Wechselplatte sicher verwahren oder den Ordner Daten loeschen' }

$cl = Join-Path $Quelle "Checkliste-$datum.txt"
Write-TextNoBom $cl (($C -join "`r`n") + "`r`n")
$desk = [Environment]::GetFolderPath('Desktop')
if ($desk) { Copy-Item -LiteralPath $cl -Destination (Join-Path $desk 'Claude-Umzug-Checkliste.txt') -Force -ErrorAction SilentlyContinue }
Write-Host ''
$C | ForEach-Object { Write-Host $_ }
Write-Host ''
Write-Host "Checkliste gespeichert: $cl (und auf dem Desktop)" -ForegroundColor Green
if (Read-JaNein 'Programme vom alten Rechner jetzt per winget nachinstallieren? (dauert, fragt evtl. nach Admin-Rechten)' $false) {
    & winget import -i (Join-Path $Quelle 'winget-export.json') --ignore-unavailable --accept-package-agreements --accept-source-agreements
}
Start-Process notepad.exe -ArgumentList "`"$cl`"" -ErrorAction SilentlyContinue
