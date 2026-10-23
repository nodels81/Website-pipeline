# Gemeinsame Hilfsfunktionen fuer Inventur.ps1, Sichern.ps1 und Wiederherstellen.ps1.
# Wird per Dot-Sourcing geladen, nicht direkt starten.

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
$script:Utf8OhneBom = New-Object System.Text.UTF8Encoding($false)
$script:IstPs7 = $PSVersionTable.PSVersion.Major -ge 7
$script:Schnell = $false   # true = keine Rueckfragen, immer die Standardantwort

# Ordner, die sich neu installieren/erzeugen lassen und standardmaessig nicht kopiert werden
$script:NeuInstallierbar = @('node_modules', '.venv', 'venv', '__pycache__', '.next', '.nuxt', '.turbo',
    '.parcel-cache', '.pytest_cache', '.mypy_cache', '.ruff_cache', '.tox', 'bower_components')

# Dateinamen, die typischerweise Geheimnisse enthalten
$script:GeheimMuster = @('.env', '.env.*', '*.pem', '*.key', '*.pfx', '*.p12', 'id_rsa*', 'id_ed25519*', 'id_ecdsa*',
    'credentials.json', '.credentials.json', 'secrets.json', '*.secret', '*.secrets', '.npmrc', '.pypirc',
    'service-account*.json', '.netrc', '_netrc')
$script:GeheimAusnahmen = @('.env.example', '.env.sample', '.env.template', '.env.dist', '*.pub')

# Ordnernamen in Claude Desktop (Electron), die reiner Cache/Log sind
$script:DesktopCaches = @('Cache', 'Code Cache', 'GPUCache', 'DawnCache', 'DawnGraphiteCache', 'DawnWebGPUCache',
    'GrShaderCache', 'ShaderCache', 'Crashpad', 'logs', 'blob_storage', 'Service Worker', 'Network', 'Shared Dictionary',
    'SharedStorage', 'SharedStorage-wal', 'sentry', 'Trust Tokens', 'Trust Tokens-journal', 'TransportSecurity',
    'Network Persistent State', 'Cookies', 'Cookies-journal', 'Local State', 'vm_bundles', 'claude-code-vm', 'claude-code',
    'Session Storage', 'WebStorage', 'Dictionaries', 'component_crx_cache', 'extensions_crx_cache', 'Crash Reports')

class JsonNum {
    [string]$Raw
    JsonNum([string]$r) { $this.Raw = $r }
}

function Write-TextNoBom([string]$Pfad, [string]$Text) {
    $dir = Split-Path -Parent $Pfad
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($Pfad, $Text, $script:Utf8OhneBom)
}

function Read-Text([string]$Pfad) { [System.IO.File]::ReadAllText($Pfad) }   # erkennt und entfernt ein BOM

function Format-Size([double]$b) {
    if ($b -ge 1GB) { return ('{0:N2} GB' -f ($b / 1GB)) }
    if ($b -ge 1MB) { return ('{0:N1} MB' -f ($b / 1MB)) }
    if ($b -ge 1KB) { return ('{0:N0} KB' -f ($b / 1KB)) }
    return ('{0:N0} B' -f $b)
}

function Test-NameMatch([string]$Name, [string[]]$Muster) {
    foreach ($m in $Muster) { if ($Name -like $m) { return $true } }
    return $false
}

function Test-GeheimName([string]$Name) {
    (Test-NameMatch $Name $script:GeheimMuster) -and -not (Test-NameMatch $Name $script:GeheimAusnahmen)
}

function Get-LongPath([string]$p) {
    if (-not $script:IstPs7 -and $p -match '^[A-Za-z]:\\' ) { return '\\?\' + $p }
    return $p
}

# Zaehlt Dateien und Bytes. Ordner aus -AusschlussOrdner werden getrennt gezaehlt (ExclBytes).
# Junctions/Symlinks werden nicht verfolgt. -Geheim sammelt Dateinamen, die nach Geheimnissen aussehen.
function Measure-Tree {
    param([string]$Pfad, [string[]]$AusschlussOrdner = @(), [string[]]$AusschlussDateien = @(), [switch]$Geheim)
    $r = [pscustomobject]@{ Dateien = 0; Bytes = [int64]0; ExclDateien = 0; ExclBytes = [int64]0; Fehler = 0; Geheimnisse = @() }
    if (-not (Test-Path -LiteralPath $Pfad)) { return $r }
    $item = Get-Item -LiteralPath $Pfad -Force -ErrorAction SilentlyContinue
    if ($item -and -not $item.PSIsContainer) {
        $r.Dateien = 1; $r.Bytes = $item.Length
        if ($Geheim -and (Test-GeheimName $item.Name)) { $r.Geheimnisse = @($item.Name) }
        return $r
    }
    $basis = $Pfad.TrimEnd('\')
    $geheimListe = New-Object System.Collections.ArrayList
    $stack = New-Object System.Collections.Stack
    $stack.Push(@($basis, $false))
    while ($stack.Count -gt 0) {
        $e = $stack.Pop(); $dir = $e[0]; $excl = $e[1]
        $items = $null
        try { $items = Get-ChildItem -LiteralPath (Get-LongPath $dir) -Force -ErrorAction Stop }
        catch {
            try { $items = Get-ChildItem -LiteralPath $dir -Force -ErrorAction Stop } catch { $r.Fehler++; continue }
        }
        foreach ($i in $items) {
            $voll = $i.FullName -replace '^\\\\\?\\', ''
            if ($i.PSIsContainer) {
                if ($i.Attributes -band [System.IO.FileAttributes]::ReparsePoint) { continue }
                $stack.Push(@($voll, ($excl -or (Test-NameMatch $i.Name $AusschlussOrdner))))
            }
            else {
                if ($excl -or (Test-NameMatch $i.Name $AusschlussDateien)) { $r.ExclDateien++; $r.ExclBytes += $i.Length }
                else {
                    $r.Dateien++; $r.Bytes += $i.Length
                    if ($Geheim -and (Test-GeheimName $i.Name)) { [void]$geheimListe.Add($voll.Substring($basis.Length).TrimStart('\')) }
                }
            }
        }
    }
    $r.Geheimnisse = @($geheimListe)
    return $r
}

# Ort in der Sicherung, relativ zum Sicherungsordner; Struktur relativ zum Benutzerordner
function Get-BackupRel([string]$Abs, [string]$Profil = $env:USERPROFILE) {
    $prof = $Profil.TrimEnd('\')
    if ($Abs -ieq $prof) { return 'Daten\Benutzerordner' }
    if ($Abs.StartsWith($prof + '\', [StringComparison]::OrdinalIgnoreCase)) { return 'Daten\Benutzerordner\' + $Abs.Substring($prof.Length + 1) }
    if ($Abs -match '^([A-Za-z]):\\?(.*)$') { return ('Daten\Laufwerk_' + $matches[1].ToUpper() + '\' + $matches[2]).TrimEnd('\') }
    if ($Abs -match '^\\\\([^\\]+)\\(.*)$') { return 'Daten\Netzwerk\' + $matches[1] + '\' + $matches[2] }
    return 'Daten\Sonstiges\' + ($Abs -replace '[:\\/]', '_')
}

function Join-Rel([string]$Basis, [string]$Rel) {
    if ([string]::IsNullOrEmpty($Rel)) { return $Basis.TrimEnd('\') }
    return ($Basis.TrimEnd('\') + '\' + $Rel.TrimStart('\'))
}

function Test-IsUnder([string]$Pfad, [string]$Basis) {
    $p = $Pfad.TrimEnd('\'); $b = $Basis.TrimEnd('\')
    ($p -ieq $b) -or $p.StartsWith($b + '\', [StringComparison]::OrdinalIgnoreCase)
}

# Claude Desktop: MSIX-Installation (Store) leitet AppData\Roaming\Claude in den Paketordner um
function Get-DesktopDataDir {
    $pkgs = Join-Path $env:LOCALAPPDATA 'Packages'
    if (Test-Path -LiteralPath $pkgs) {
        foreach ($p in (Get-ChildItem -LiteralPath $pkgs -Directory -Filter 'Claude*' -ErrorAction SilentlyContinue)) {
            $d = Join-Path $p.FullName 'LocalCache\Roaming\Claude'
            if (Test-Path -LiteralPath $d) { return $d }
        }
    }
    return (Join-Path $env:APPDATA 'Claude')
}

# So benennt Claude Code die Ordner unter .claude\projects
function Get-EncodedProjectName([string]$Pfad) { $Pfad -replace '[^A-Za-z0-9]', '-' }

function Invoke-Tool([string]$Exe, [string[]]$Argumente = @()) {
    $c = Get-Command $Exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $c) { return $null }
    try { $o = & $c.Source @Argumente 2>$null; return (@($o) -join "`n").Trim() } catch { return $null }
}

function Read-JaNein([string]$Frage, [bool]$Standard = $true) {
    if ($script:Schnell) { Write-Host "$Frage -> $(if ($Standard) { 'Ja' } else { 'Nein' })"; return $Standard }
    $hinweis = if ($Standard) { '[J/n]' } else { '[j/N]' }
    while ($true) {
        $a = Read-Host "$Frage $hinweis"
        if ([string]::IsNullOrWhiteSpace($a)) { return $Standard }
        if ($a -match '^(j|ja|y|yes)$') { return $true }
        if ($a -match '^(n|nein|no)$') { return $false }
    }
}

# ---------- JSON: verlustarm lesen/schreiben (Gross-/Kleinschreibung der Schluessel bleibt erhalten) ----------

function Convert-JsonElement($el) {
    switch ($el.ValueKind.ToString()) {
        'Object' {
            $d = [System.Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
            foreach ($p in $el.EnumerateObject()) { $d[$p.Name] = Convert-JsonElement $p.Value }
            return , $d
        }
        'Array' {
            $l = New-Object System.Collections.ArrayList
            foreach ($x in $el.EnumerateArray()) { [void]$l.Add((Convert-JsonElement $x)) }
            return , $l.ToArray()
        }
        'String' { return $el.GetString() }
        'Number' { return [JsonNum]::new($el.GetRawText()) }
        'True' { return $true }
        'False' { return $false }
        default { return $null }
    }
}

function ConvertFrom-JsonText([string]$Text) {
    if ($script:IstPs7) {
        $opt = [System.Text.Json.JsonDocumentOptions]::new()
        $opt.AllowTrailingCommas = $true
        $opt.CommentHandling = [System.Text.Json.JsonCommentHandling]::Skip
        $opt.MaxDepth = 1000
        $doc = [System.Text.Json.JsonDocument]::Parse($Text, $opt)
        try { return , (Convert-JsonElement $doc.RootElement) } finally { $doc.Dispose() }
    }
    Add-Type -AssemblyName System.Web.Extensions
    $s = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $s.MaxJsonLength = [int]::MaxValue
    $s.RecursionLimit = 1000
    return , $s.DeserializeObject($Text)
}

function Read-JsonFile([string]$Pfad) {
    if (-not (Test-Path -LiteralPath $Pfad)) { return $null }
    try { return , (ConvertFrom-JsonText (Read-Text $Pfad)) } catch { return $null }
}

function Write-JsonString([System.Text.StringBuilder]$sb, [string]$s) {
    $e = $s.Replace('\', '\\').Replace('"', '\"').Replace("`n", '\n').Replace("`r", '\r').Replace("`t", '\t')
    if ([regex]::IsMatch($e, '[\x00-\x1f]')) {
        $e = [regex]::Replace($e, '[\x00-\x1f]', { param($m) '\u{0:x4}' -f [int][char]$m.Value })
    }
    [void]$sb.Append('"').Append($e).Append('"')
}

function Write-JsonValue([System.Text.StringBuilder]$sb, $v, [int]$Ebene, [bool]$Schoen) {
    if ($null -eq $v) { [void]$sb.Append('null'); return }
    if ($v -is [string]) { Write-JsonString $sb $v; return }
    if ($v -is [bool]) { [void]$sb.Append($(if ($v) { 'true' } else { 'false' })); return }
    if ($v -is [JsonNum]) { [void]$sb.Append($v.Raw); return }
    if ($v -is [datetime]) { Write-JsonString $sb $v.ToString('o'); return }
    if ($v -is [System.Collections.IDictionary]) {
        $keys = @($v.PSBase.Keys)
        if ($keys.Count -eq 0) { [void]$sb.Append('{}'); return }
        [void]$sb.Append('{')
        for ($i = 0; $i -lt $keys.Count; $i++) {
            if ($i -gt 0) { [void]$sb.Append(',') }
            if ($Schoen) { [void]$sb.Append("`n").Append('  ' * ($Ebene + 1)) }
            Write-JsonString $sb ([string]$keys[$i])
            [void]$sb.Append($(if ($Schoen) { ': ' } else { ':' }))
            Write-JsonValue $sb $v[$keys[$i]] ($Ebene + 1) $Schoen
        }
        if ($Schoen) { [void]$sb.Append("`n").Append('  ' * $Ebene) }
        [void]$sb.Append('}'); return
    }
    if ($v -is [System.Collections.IEnumerable]) {
        $arr = @($v)
        if ($arr.Count -eq 0) { [void]$sb.Append('[]'); return }
        [void]$sb.Append('[')
        for ($i = 0; $i -lt $arr.Count; $i++) {
            if ($i -gt 0) { [void]$sb.Append(',') }
            if ($Schoen) { [void]$sb.Append("`n").Append('  ' * ($Ebene + 1)) }
            Write-JsonValue $sb $arr[$i] ($Ebene + 1) $Schoen
        }
        if ($Schoen) { [void]$sb.Append("`n").Append('  ' * $Ebene) }
        [void]$sb.Append(']'); return
    }
    [void]$sb.Append([Convert]::ToString($v, [System.Globalization.CultureInfo]::InvariantCulture))
}

function ConvertTo-JsonText($Wert, [switch]$Kompakt) {
    $sb = New-Object System.Text.StringBuilder
    Write-JsonValue $sb $Wert 0 (-not $Kompakt)
    return $sb.ToString()
}

function Test-JsonKey($d, [string]$k) { ([System.Collections.IDictionary]$d).Contains($k) }

# Fuehrt $Alt in $Neu zusammen: fehlende Schluessel kommen dazu, Listen werden vereinigt,
# bei unterschiedlichen Einzelwerten bleibt der Wert von $Neu (neuer Rechner) und der Pfad landet in $Konflikte.
# $Ausschluss: Regex fuer Schluessel der obersten Ebene, die nie uebernommen werden (Anmeldung, Caches).
function Merge-JsonValue($Neu, $Alt, [string]$Pfad, [System.Collections.ArrayList]$Konflikte, [string]$Ausschluss = '', [int]$Tiefe = 0) {
    if ($Neu -is [System.Collections.IDictionary] -and $Alt -is [System.Collections.IDictionary]) {
        foreach ($k in @($Alt.PSBase.Keys)) {
            if ($Tiefe -eq 0 -and $Ausschluss -and ($k -match $Ausschluss)) { continue }
            if (-not (Test-JsonKey $Neu $k)) { $Neu[$k] = $Alt[$k] }
            else { $Neu[$k] = Merge-JsonValue $Neu[$k] $Alt[$k] "$Pfad.$k" $Konflikte $Ausschluss ($Tiefe + 1) }
        }
        return , $Neu
    }
    if ($Neu -is [System.Array] -and $Alt -is [System.Array]) {
        $liste = New-Object System.Collections.ArrayList
        $gesehen = New-Object 'System.Collections.Generic.HashSet[string]'
        foreach ($x in $Neu) { [void]$liste.Add($x); [void]$gesehen.Add((ConvertTo-JsonText $x -Kompakt)) }
        foreach ($x in $Alt) { if ($gesehen.Add((ConvertTo-JsonText $x -Kompakt))) { [void]$liste.Add($x) } }
        return , $liste.ToArray()
    }
    if ((ConvertTo-JsonText $Neu -Kompakt) -cne (ConvertTo-JsonText $Alt -Kompakt)) { [void]$Konflikte.Add($Pfad.TrimStart('.')) }
    return , $Neu
}

# ---------- Pfade umschreiben (alter -> neuer Benutzerordner, verschobene Laufwerke) ----------

# $Zuordnungen: Liste von @{ Alt = 'C:\Users\alt'; Neu = 'C:\Users\neu' }
function Convert-PathsInText([string]$Text, $Zuordnungen) {
    foreach ($z in $Zuordnungen) {
        $o = $z.Alt.TrimEnd('\'); $n = $z.Neu.TrimEnd('\')
        $formen = @(
            @($o.Replace('\', '\\'), $n.Replace('\', '\\'), '(?![A-Za-z0-9_.\-])'),   # JSON-maskiert
            @($o.Replace('\', '/'), $n.Replace('\', '/'), '(?![A-Za-z0-9_.\-])'),     # Schraegstriche
            @($o, $n, '(?![A-Za-z0-9_.\-])'),                                         # normal
            @((Get-EncodedProjectName $o), (Get-EncodedProjectName $n), '(?![A-Za-z0-9])')  # .claude\projects-Ordnername
        )
        foreach ($f in $formen) {
            $Text = [regex]::Replace($Text, [regex]::Escape($f[0]) + $f[2], $f[1].Replace('$', '$$'),
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        }
    }
    return $Text
}

function Convert-ProjectFolderName([string]$Name, $Zuordnungen) {
    foreach ($z in $Zuordnungen) {
        $a = Get-EncodedProjectName $z.Alt.TrimEnd('\')
        if ($Name.StartsWith($a, [StringComparison]::OrdinalIgnoreCase) -and ($Name.Length -eq $a.Length -or $Name[$a.Length] -eq '-')) {
            return (Get-EncodedProjectName $z.Neu.TrimEnd('\')) + $Name.Substring($a.Length)
        }
    }
    return $Name
}

# Schreibt Pfade in einer Datei um, Aenderungszeit bleibt erhalten (wichtig fuer die Sitzungsliste)
function Update-FileText([string]$Datei, $Zuordnungen) {
    try {
        $fi = Get-Item -LiteralPath $Datei -Force
        if ($fi.Length -gt 300MB) { return $false }
        $t = Read-Text $Datei
        $treffer = $false
        foreach ($z in $Zuordnungen) {
            $blatt = Split-Path -Leaf $z.Alt.TrimEnd('\')
            if (-not $blatt) { $blatt = $z.Alt }
            if ($t.IndexOf((Get-EncodedProjectName $blatt), [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                $t.IndexOf($blatt, [StringComparison]::OrdinalIgnoreCase) -ge 0) { $treffer = $true; break }
        }
        if (-not $treffer) { return $false }
        $n = Convert-PathsInText $t $Zuordnungen
        if ($n -ceq $t) { return $false }
        $zeit = $fi.LastWriteTimeUtc
        Write-TextNoBom $Datei $n
        [System.IO.File]::SetLastWriteTimeUtc($Datei, $zeit)
        return $true
    }
    catch { return $false }
}

# robocopy: Exitcode 0-7 = ok, ab 8 = Fehler
function Invoke-Robocopy {
    param([string]$Quelle, [string]$Ziel, [string]$Datei = '', [string[]]$AusschlussOrdner = @(), [string[]]$AusschlussDateien = @(),
        [switch]$NurNeuere, [switch]$Nurliste, [string]$Log)
    $a = New-Object System.Collections.ArrayList
    [void]$a.Add($Quelle); [void]$a.Add($Ziel)
    if ($Datei) { [void]$a.Add($Datei) } else { [void]$a.Add('/E') }
    foreach ($x in @('/COPY:DAT', '/DCOPY:T', '/R:1', '/W:1', '/XJ', '/FFT', '/NP', '/NDL', '/NJH')) { [void]$a.Add($x) }
    if ($NurNeuere) { [void]$a.Add('/XO') }
    if ($Nurliste) { foreach ($x in @('/L', '/NJS', '/NS', '/NC', '/FP')) { [void]$a.Add($x) } }
    if ($AusschlussOrdner.Count) { [void]$a.Add('/XD'); foreach ($x in $AusschlussOrdner) { [void]$a.Add($x) } }
    if ($AusschlussDateien.Count) { [void]$a.Add('/XF'); foreach ($x in $AusschlussDateien) { [void]$a.Add($x) } }
    if ($Log -and -not $Nurliste) { [void]$a.Add("/UNILOG+:$Log"); [void]$a.Add('/NFL') }
    $ausgabe = & robocopy.exe @a 2>&1
    return [pscustomobject]@{ Code = $LASTEXITCODE; Ausgabe = @($ausgabe) }
}

function Get-RobocopyErrors([string]$Log) {
    if (-not $Log -or -not (Test-Path -LiteralPath $Log)) { return @() }
    @(Get-Content -LiteralPath $Log -Encoding Unicode -ErrorAction SilentlyContinue |
        Where-Object { $_ -match '(FEHLER|ERROR)\s+\d+\s+\(0x' } | Select-Object -Unique)
}

function Get-ClaudeProcesses {
    $liste = @()
    foreach ($p in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
        $cl = [string]$p.CommandLine
        if ($p.Name -match '^claude' -or ($p.Name -match '^(node|bun)\.exe$' -and $cl -match 'claude-code|@anthropic-ai|mcp')) {
            $liste += [pscustomobject]@{ Name = $p.Name; Id = $p.ProcessId; Pfad = $p.ExecutablePath; Befehl = $cl }
        }
    }
    return $liste
}

function Stop-ClaudeProcesses {
    param([string]$Anlass)
    $procs = @(Get-ClaudeProcesses | Where-Object { $_.Id -ne $PID })
    if (-not $procs.Count) { return $true }
    Write-Host ''
    Write-Host "Diese Claude-Prozesse laufen gerade ($Anlass):" -ForegroundColor Yellow
    foreach ($p in $procs) { Write-Host ("  {0,-14} PID {1,-7} {2}" -f $p.Name, $p.Id, $p.Pfad) }
    Write-Host 'Wenn du dieses Fenster aus Claude Code heraus gestartet hast: abbrechen und in einer normalen PowerShell starten.'
    if (Read-JaNein 'Sollen sie jetzt beendet werden? (Vorher offene Arbeit in Claude speichern)' $true) {
        foreach ($p in $procs) {
            try {
                $gp = Get-Process -Id $p.Id -ErrorAction Stop
                if ($gp.MainWindowHandle -ne 0) { [void]$gp.CloseMainWindow() }
            } catch { }
        }
        Start-Sleep -Seconds 4
        foreach ($p in $procs) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
        Start-Sleep -Seconds 1
        return $true
    }
    return (Read-JaNein 'Trotzdem weitermachen? Dateien koennen dann gesperrt oder unvollstaendig sein.' $false)
}
