
# wifi.ps1
# WLAN-Profilübersicht für Windows PowerShell 5.1

$log = "$env:USERPROFILE\Desktop\wifi-log.txt"

Write-Host "[+] Suche WLAN-Profile..."

$profiles = netsh wlan show profiles

$result = foreach ($line in $profiles) {
    if ($line -match ':\s*(.+)$') {
        $name = $Matches[1].Trim()

        if ($name) {
            [PSCustomObject]@{
                SSID = $name
            }
        }
    }
}

$result |
    Sort-Object SSID -Unique |
    Format-Table -AutoSize |
    Out-File -FilePath $log -Encoding UTF8

Write-Host "[+] Fertig!"
Write-Host "[+] Gespeichert unter: $log"
