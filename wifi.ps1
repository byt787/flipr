$profiles = netsh wlan show profiles

$result = foreach ($line in $profiles) {
    if ($line -match ':\s*(.+)$') {
        $name = $Matches[1].Trim()

        if ($name -and $name -notmatch '^(All User Profile|Benutzerprofile|Profiles)$') {
            [PSCustomObject]@{
                SSID = $name
            }
        }
    }
}

$result | Format-Table -AutoSize |
    Out-File "$env:USERPROFILE\Desktop\wifi-log.txt"
