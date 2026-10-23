# Schritt 2 + 3: Sichern und Pruefen. Liest Inventur\inventur-roh.json (von Inventur.ps1),
# laesst dich die Auswahl bestaetigen, kopiert mit robocopy und vergleicht danach Original und Sicherung.
param([string]$Ziel = $PSScriptRoot, [switch]$Schnell)

. (Join-Path $PSScriptRoot 'Gemeinsam.ps1')
$script:Schnell = $Schnell.IsPresent

$invPfad = Join-Path $Ziel 'Inventur\inventur-roh.json'
if (-not (Test-Path -LiteralPath $invPfad)) {
    Write-Host 'Zuerst die Bestandsaufnahme starten (Inventur.bat).' -ForegroundColor Yellow
    return
}
$inv = (Read-Text $invPfad) | ConvertFrom-Json
if ($inv.Profil -ine $env:USERPROFILE.TrimEnd('\')) {
    Write-Host "Die Bestandsaufnahme stammt von $($inv.Profil), du bist $env:USERPROFILE. Bitte auf dem ALTEN Rechner als derselbe Benutzer starten." -ForegroundColor Red
    return
}
$alter = [datetime]::Parse($inv.Erstellt)
if ((Get-Date) - $alter -gt [timespan]::FromDays(2)) {
    Write-Host "Hinweis: Die Bestandsaufnahme ist vom $($alter.ToString('dd.MM.yyyy')). Ggf. Inventur.bat neu starten." -ForegroundColor Yellow
}
$E = @($inv.Eintraege)
foreach ($e in $E) { $e | Add-Member -NotePropertyName AusschlussDateien -NotePropertyValue @() -Force }
$zielLaufwerk = (Split-Path -Qualifier $Ziel).ToUpper()

function Get-Frei { try { return ([System.IO.DriveInfo]::new($zielLaufwerk)).AvailableFreeSpace } catch { return $null } }

function Show-Auswahl {
    Write-Host ''
    $gruppe = ''
    foreach ($x in $E) {
        if ($x.Gruppe -ne $gruppe) { $gruppe = $x.Gruppe; Write-Host "== $gruppe ==" -ForegroundColor Cyan }
        $mark = if ($x.Mitnehmen) { '[x]' } else { '[ ]' }
        $gz = if ($x.Geheim) { 'G' } else { ' ' }
        $t = $x.Titel; if ($t.Length -gt 95) { $t = $t.Substring(0, 92) + '...' }
        $farbe = if ($x.Mitnehmen) { 'White' } else { 'DarkGray' }
        Write-Host ("{0,3} {1} {2} {3,10}  {4}" -f $x.Nr, $mark, $gz, (Format-Size $x.Bytes), $t) -ForegroundColor $farbe
    }
    $summe = ($E | Where-Object { $_.Mitnehmen } | Measure-Object Bytes -Sum).Sum
    $frei = Get-Frei
    Write-Host ''
    Write-Host ("Ausgewaehlt: {0}   Frei auf {1} {2}" -f (Format-Size $summe), $zielLaufwerk, $(if ($null -ne $frei) { Format-Size $frei } else { '?' })) -ForegroundColor Green
    return $summe
}

Write-Host ''
Write-Host '=== Claude-Umzug: Sichern ===' -ForegroundColor Cyan
Write-Host "Ziel: $Ziel"
if ($Schnell) {
    # Alles mitnehmen ausser Caches/Programmen; auch Schluessel und Anmeldedaten (SSH, GitHub-CLI, Erweiterungen)
    foreach ($x in $E) {
        if ($x.Gruppe -eq 'Programme (neu installieren)') { continue }
        if ($x.Empfehlung -ne 'nein' -or $x.Titel -match '\.config\\gh|credentials') { $x.Mitnehmen = $true }
        if ($x.Gruppe -eq 'Claude Desktop' -and $x.Empfehlung -eq 'optional') { $x.Mitnehmen = $false }
    }
    $s = ($E | Where-Object { $_.Mitnehmen } | Measure-Object Bytes -Sum).Sum
    $f = Get-Frei
    if ($null -ne $f -and $s -gt $f) { Write-Host 'Der Platz auf der Platte reicht nicht fuer alles - bitte unten auswaehlen.' -ForegroundColor Red; $script:Schnell = $false; $Schnell = $false }
}
while (-not $Schnell) {
    $summe = Show-Auswahl
    Write-Host 'Nummern umschalten, z. B. "3 7 12-15"  ("+5" = an, "-5" = aus).  Enter = weiter,  q = abbrechen'
    $in = Read-Host 'Auswahl'
    if ($in -match '^\s*q\s*$') { Write-Host 'Abgebrochen, nichts kopiert.'; return }
    if ([string]::IsNullOrWhiteSpace($in)) {
        $frei = Get-Frei
        if ($null -ne $frei -and $summe -gt $frei) { Write-Host 'Der Platz reicht nicht. Bitte weniger auswaehlen.' -ForegroundColor Red; continue }
        break
    }
    foreach ($tok in ($in -split '[\s,;]+' | Where-Object { $_ })) {
        $modus = 'umschalten'
        if ($tok.StartsWith('+')) { $modus = 'an'; $tok = $tok.Substring(1) }
        elseif ($tok.StartsWith('-')) { $modus = 'aus'; $tok = $tok.Substring(1) }
        $nummern = @()
        if ($tok -match '^(\d+)-(\d+)$') { $nummern = [int]$matches[1]..[int]$matches[2] }
        elseif ($tok -match '^\d+$') { $nummern = @([int]$tok) }
        else { Write-Host "  '$tok' nicht verstanden" -ForegroundColor Yellow; continue }
        foreach ($n in $nummern) {
            $x = $E | Where-Object { $_.Nr -eq $n }
            if (-not $x) { continue }
            $x.Mitnehmen = switch ($modus) { 'an' { $true } 'aus' { $false } default { -not $x.Mitnehmen } }
        }
    }
}

$auswahl = @($E | Where-Object { $_.Mitnehmen })
if (-not $auswahl.Count) { Write-Host 'Nichts ausgewaehlt.'; return }

$mitExcl = @($auswahl | Where-Object { $_.ExclBytes -gt 0 })
if ($mitExcl.Count) {
    $s = ($mitExcl | Measure-Object ExclBytes -Sum).Sum
    Write-Host ''
    Write-Host "In $($mitExcl.Count) Ordnern liegen $(Format-Size $s) node_modules/.venv/Caches, die sich neu installieren lassen."
    if (-not (Read-JaNein 'Diese weglassen (empfohlen)?' $true)) { foreach ($x in $mitExcl) { $x.AusschlussOrdner = @() } }
}
$mitGeheim = @($auswahl | Where-Object { $_.Geheim })
$geheimeMit = $true
if ($mitGeheim.Count) {
    Write-Host ''
    Write-Host 'Diese Auswahl enthaelt Geheimnisse (API-Schluessel, Tokens, .env, SSH-Schluessel):' -ForegroundColor Yellow
    foreach ($x in $mitGeheim) {
        $was = if ($x.Geheimnisse.Count) { ($x.Geheimnisse | Select-Object -First 5) -join ', ' } else { 'ganzer Eintrag' }
        Write-Host ("  {0,3} {1}  ->  {2}" -f $x.Nr, $x.Titel, $was)
    }
    Write-Host 'Mitnehmen heisst: Sie liegen unverschluesselt auf der Platte. Danach sicher aufbewahren und loeschen.'
    $geheimeMit = Read-JaNein 'Geheimnisse mitnehmen?' $true
    if (-not $geheimeMit) {
        foreach ($x in $mitGeheim) {
            if ($x.Spezial) { continue }   # .claude.json/settings.json werden gebraucht
            if ($x.Geheimnisse.Count -eq 0 -or $x.Art -eq 'Datei') { $x.Mitnehmen = $false }
            else { $x.AusschlussDateien = $script:GeheimMuster }
        }
        $auswahl = @($E | Where-Object { $_.Mitnehmen })
    }
}

if (-not (Stop-ClaudeProcesses 'vor dem Sichern')) { Write-Host 'Abgebrochen, nichts kopiert.'; return }

# ---------- Kopieren ----------
$logDir = Join-Path $Ziel 'Logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$ergebnisse = New-Object System.Collections.ArrayList
$i = 0
foreach ($x in $auswahl) {
    $i++
    Write-Progress -Activity 'Sichern' -Status $x.Titel -PercentComplete ([int](100 * $i / $auswahl.Count))
    Write-Host ("[{0}/{1}] {2}" -f $i, $auswahl.Count, $x.Titel)
    $dst = Join-Path $Ziel $x.Sicherung
    $log = Join-Path $logDir ('sichern-{0:000}.log' -f [int]$x.Nr)
    Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
    if (-not (Test-Path -LiteralPath $x.Pfad)) {
        [void]$ergebnisse.Add([pscustomobject]@{ E = $x; Code = -1; Fehler = @('Quelle existiert nicht mehr'); Quelle = $null; Kopie = $null; Abweichungen = @() })
        continue
    }
    $xd = @($x.AusschlussOrdner); $xf = @($x.AusschlussDateien)
    if ($x.Art -eq 'Ordner') {
        $r = Invoke-Robocopy $x.Pfad $dst -AusschlussOrdner $xd -AusschlussDateien $xf -Log $log
        $l = Invoke-Robocopy $x.Pfad $dst -AusschlussOrdner $xd -AusschlussDateien $xf -Nurliste
        $mq = Measure-Tree $x.Pfad $xd $xf
    }
    else {
        $r = Invoke-Robocopy (Split-Path -Parent $x.Pfad) (Split-Path -Parent $dst) -Datei (Split-Path -Leaf $x.Pfad) -Log $log
        $l = Invoke-Robocopy (Split-Path -Parent $x.Pfad) (Split-Path -Parent $dst) -Datei (Split-Path -Leaf $x.Pfad) -Nurliste
        $mq = Measure-Tree $x.Pfad
    }
    $mk = Measure-Tree $dst
    $abw = @($l.Ausgabe | ForEach-Object { "$_".Trim() } | Where-Object { $_ -match '^[A-Za-z]:\\|^\\\\' })
    $fehler = @(Get-RobocopyErrors $log)
    if ($r.Code -ge 8 -and -not $fehler.Count) { $fehler = @("robocopy meldet Fehler (Code $($r.Code)), siehe $log") }
    [void]$ergebnisse.Add([pscustomobject]@{ E = $x; Code = $r.Code; Fehler = $fehler; Quelle = $mq; Kopie = $mk; Abweichungen = $abw })
    if ($fehler.Count) { Write-Host "      $($fehler.Count) Fehler, siehe Logs" -ForegroundColor Red }
}
Write-Progress -Activity 'Sichern' -Completed

# ---------- Software, Umgebung, Aufgaben ----------
Write-Host ''
Write-Host 'Software-Liste erstellen (winget export kann eine Minute dauern) ...'
$sw = New-Object System.Collections.ArrayList
function S([string]$t = '') { [void]$sw.Add($t) }
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
S "SOFTWARE AUF DEM ALTEN RECHNER ($env:COMPUTERNAME, $(Get-Date -Format 'yyyy-MM-dd'))"
S "Windows: $($os.Caption) $($os.Version)"
S ''
S '== Versionen =='
$tools = [ordered]@{}
foreach ($t in @('node', 'npm', 'python', 'py', 'pip', 'pipx', 'uv', 'git', 'gh', 'docker', 'bun', 'deno', 'claude', 'winget', 'pwsh')) {
    $v = Invoke-Tool $t @('--version'); $tools[$t] = if ($v) { ($v -split "`n")[0] } else { $null }
    S ("  {0,-8} {1}" -f $t, $(if ($tools[$t]) { $tools[$t] } else { '-' }))
}
$npmGlobal = @()
$npmJson = Invoke-Tool npm @('ls', '-g', '--depth=0', '--json')
if ($npmJson) { try { $nj = $npmJson | ConvertFrom-Json; if ($nj.dependencies) { $npmGlobal = @($nj.dependencies.PSObject.Properties | ForEach-Object { "$($_.Name)@$($_.Value.version)" }) } } catch { } }
S ''; S '== npm global (npm install -g <name>) =='; foreach ($n in $npmGlobal) { S "  $n" }
$pyVers = Invoke-Tool py @('-0p'); S ''; S '== Python-Versionen (py -0p) =='; if ($pyVers) { foreach ($z in ($pyVers -split "`n")) { S "  $($z.Trim())" } }
$pip = Invoke-Tool python @('-m', 'pip', 'list', '--format=freeze')
S ''; S '== pip-Pakete der Standard-Python-Installation =='; if ($pip) { foreach ($z in ($pip -split "`n")) { S "  $($z.Trim())" } }
if ($pip) { Write-TextNoBom (Join-Path $Ziel 'pip-pakete.txt') ($pip + "`r`n") }
$pipx = @((Invoke-Tool pipx @('list', '--short')) -split "`n" | Where-Object { $_ })
S ''; S '== pipx (pipx install <name>) =='; foreach ($z in $pipx) { S "  $z" }
$uvTools = @((Invoke-Tool uv @('tool', 'list')) -split "`n" | Where-Object { $_ -and $_ -notmatch '^\s*-' -and $_ -notmatch '^No tools' })
S ''; S '== uv tools (uv tool install <name>) =='; foreach ($z in $uvTools) { S "  $z" }
$uvPy = Invoke-Tool uv @('python', 'list', '--only-installed')
S ''; S '== uv Python-Versionen =='; if ($uvPy) { foreach ($z in ($uvPy -split "`n")) { S "  $($z.Trim())" } }
$wingetDatei = Join-Path $Ziel 'winget-export.json'
$wingetPakete = @()
if (Get-Command winget -ErrorAction SilentlyContinue) {
    & winget export -o $wingetDatei --accept-source-agreements 2>&1 | Out-Null
    if (Test-Path -LiteralPath $wingetDatei) {
        try { $wj = (Read-Text $wingetDatei) | ConvertFrom-Json; $wingetPakete = @($wj.Sources | ForEach-Object { $_.Packages } | ForEach-Object { $_.PackageIdentifier }) } catch { }
    }
}
S ''; S "== winget-Programme ($($wingetPakete.Count); neu installieren mit: winget import -i winget-export.json --ignore-unavailable) =="
foreach ($z in ($wingetPakete | Sort-Object)) { S "  $z" }
S ''; S '== Von MCP-Servern/Hooks benutzte Programme =='; foreach ($z in @($inv.Werkzeuge)) { S "  $z" }
if (@($inv.NpxPakete).Count) { S ''; S '== Per npx/uvx geladene MCP-Pakete (laden sich selbst, brauchen nur Node bzw. uv) =='; foreach ($z in $inv.NpxPakete) { S "  $z" } }
Write-TextNoBom (Join-Path $Ziel 'software.txt') (($sw -join "`r`n") + "`r`n")

$umgebung = [ordered]@{}
$uvars = [Environment]::GetEnvironmentVariables('User')
foreach ($n in ($uvars.Keys | Sort-Object)) {
    if ($n -in @('Path', 'TEMP', 'TMP') -or $n -like 'OneDrive*') { continue }
    $geheim = $n -match '(?i)key|token|secret|pass|auth|cred'
    if ($geheim -and -not $geheimeMit) { continue }
    $umgebung[$n] = [string]$uvars[$n]
}
Write-TextNoBom (Join-Path $Ziel 'Daten\umgebung.json') (ConvertTo-JsonText $umgebung)

$aufgabenDateien = @()
foreach ($a in @($inv.Aufgaben)) {
    try {
        $xml = Export-ScheduledTask -TaskName $a.Name -TaskPath $a.Pfad -ErrorAction Stop
        $datei = Join-Path $Ziel ("Daten\Aufgabenplanung\{0}.xml" -f ($a.Name -replace '[\\/:*?"<>|]', '_'))
        Write-TextNoBom $datei $xml
        $aufgabenDateien += [pscustomobject]@{ Name = $a.Name; Pfad = $a.Pfad; Datei = $datei.Substring($Ziel.TrimEnd('\').Length + 1) }
    } catch { }
}

# ---------- inventar.json ----------
$eintraege = foreach ($r in $ergebnisse) {
    $x = $r.E
    [pscustomobject]@{
        Nr = $x.Nr; Gruppe = $x.Gruppe; Titel = $x.Titel; Original = $x.Pfad; Art = $x.Art; Basis = $x.Basis; Rel = $x.Rel
        Sicherung = $x.Sicherung; Spezial = $x.Spezial; AusschlussOrdner = @($x.AusschlussOrdner); AusschlussDateien = @($x.AusschlussDateien)
        NeuInstallieren = @($x.NeuInstallieren); Geheim = $x.Geheim
        QuelleDateien = $(if ($r.Quelle) { $r.Quelle.Dateien } else { 0 }); QuelleBytes = $(if ($r.Quelle) { $r.Quelle.Bytes } else { 0 })
        SicherungDateien = $(if ($r.Kopie) { $r.Kopie.Dateien } else { 0 }); SicherungBytes = $(if ($r.Kopie) { $r.Kopie.Bytes } else { 0 })
        Fehler = @($r.Fehler); Abweichungen = @($r.Abweichungen).Count
    }
}
$nichtMit = @($E | Where-Object { -not $_.Mitnehmen } | ForEach-Object {
        [pscustomobject]@{ Nr = $_.Nr; Titel = $_.Titel; Original = $_.Pfad; Empfehlung = $_.Empfehlung; Hinweis = $_.Hinweis } })
$inventar = [pscustomobject]@{
    Erstellt = (Get-Date).ToString('s'); Rechner = $env:COMPUTERNAME
    AlterBenutzername = $env:USERNAME; AltesProfil = $env:USERPROFILE.TrimEnd('\'); AltesAppData = $env:APPDATA
    AltesLocalAppData = $env:LOCALAPPDATA; AlteDesktopDaten = $inv.DesktopDaten
    GeheimnisseMitgenommen = $geheimeMit
    Eintraege = @($eintraege); NichtMitgenommen = $nichtMit; FehlendeProjekte = @($inv.FehlendeProjekte)
    Mcp = @($inv.Mcp); NpxPakete = @($inv.NpxPakete); Werkzeuge = @($inv.Werkzeuge); Erweiterungen = @($inv.Erweiterungen)
    Software = [pscustomobject]@{ Tools = $tools; NpmGlobal = @($npmGlobal); Pipx = @($pipx); UvTools = @($uvTools); WingetPakete = @($wingetPakete) }
    Umgebung = 'Daten\umgebung.json'; Aufgaben = @($aufgabenDateien)
}
Write-TextNoBom (Join-Path $Ziel 'inventar.json') (ConvertTo-Json -InputObject $inventar -Depth 8)

# Restore-Dateien neben die Sicherung legen, falls woanders hin gesichert wurde
if ($Ziel.TrimEnd('\') -ine $PSScriptRoot.TrimEnd('\')) {
    foreach ($f in @('Gemeinsam.ps1', 'Wiederherstellen.ps1', 'Wiederherstellen.bat', 'LIESMICH.txt')) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $f) -Destination $Ziel -Force -ErrorAction SilentlyContinue
    }
}

# ---------- Pruefung ----------
$P = New-Object System.Collections.ArrayList
function P([string]$t = '') { [void]$P.Add($t) }
P "PRUEFUNG DER SICHERUNG   $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
P 'Vergleich Original (ohne weggelassene Ordner) <-> Sicherung'
P ''
$ok = 0; $probleme = 0
foreach ($r in $ergebnisse) {
    $x = $r.E
    if ($r.Code -lt 0) { P ("FEHLT    {0}  - {1}" -f $x.Titel, ($r.Fehler -join '; ')); $probleme++; continue }
    $gleich = ($r.Quelle.Dateien -eq $r.Kopie.Dateien -and $r.Quelle.Bytes -eq $r.Kopie.Bytes -and -not $r.Fehler.Count -and -not $r.Abweichungen.Count)
    $status = if ($gleich) { 'OK      ' } elseif ($r.Fehler.Count) { 'FEHLER  ' } else { 'ABWEICH.' }
    if ($gleich) { $ok++ } else { $probleme++ }
    P ("{0} {1,7} / {2,7} Dateien  {3,10} / {4,10}  {5}" -f $status, $r.Quelle.Dateien, $r.Kopie.Dateien, (Format-Size $r.Quelle.Bytes), (Format-Size $r.Kopie.Bytes), $x.Titel)
    foreach ($f in ($r.Fehler | Select-Object -First 10)) { P "           $f" }
    if ($r.Abweichungen.Count) {
        P "           $($r.Abweichungen.Count) Dateien unterscheiden sich (meist waehrend der Sicherung geaendert, z. B. laufende Sitzung):"
        foreach ($a in ($r.Abweichungen | Select-Object -First 10)) { P "             $a" }
    }
    if ($r.Quelle.Fehler) { P "           $($r.Quelle.Fehler) Ordner im Original nicht lesbar (Rechte/zu lange Pfade)" }
}
$empfohlenFehlt = @($E | Where-Object { -not $_.Mitnehmen -and $_.Empfehlung -eq 'mit' })
if ($empfohlenFehlt.Count) { P ''; P 'Empfohlen, aber abgewaehlt:'; foreach ($x in $empfohlenFehlt) { P "  $($x.Nr) $($x.Titel)" } }
if (@($inv.FehlendeProjekte).Count) { P ''; P 'Projekte, die es auf diesem Rechner nicht mehr gibt (nur ihre Sitzungsverlaeufe sind gesichert):'; foreach ($f in $inv.FehlendeProjekte) { P "  $($f.Pfad)" } }
if (-not $geheimeMit) { P ''; P 'Geheimnis-Dateien (.env, Schluessel) wurden bewusst NICHT gesichert.' }
P ''
P "Ergebnis: $ok in Ordnung, $probleme mit Hinweisen.  Logs: $logDir"
P "Sicherung: $Ziel   Belegt: $(Format-Size (($ergebnisse | Where-Object { $_.Kopie } | ForEach-Object { $_.Kopie.Bytes } | Measure-Object -Sum).Sum))"
Write-TextNoBom (Join-Path $Ziel 'pruefung.txt') (($P -join "`r`n") + "`r`n")

Write-Host ''
$P | ForEach-Object { Write-Host $_ }
Write-Host ''
Write-Host "Fertig. Pruefbericht: $(Join-Path $Ziel 'pruefung.txt')" -ForegroundColor Green
Write-Host 'Auf dem neuen Rechner: Platte anschliessen, Wiederherstellen.bat doppelklicken.' -ForegroundColor Green
