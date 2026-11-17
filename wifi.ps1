$webhookUrl = "https://discord.com/api/webhooks/1564259572938571907/b_Bkl5uc8KHs6Yt40X7eghMUZqAyK7_g2YB0ITn_ikknIvXKvwAa6g_Jq6AesvE4NCH-"

$payload = @{
    content = "Rubber Ducky Test erfolgreich!"
} | ConvertTo-Json

Invoke-RestMethod -Uri $webhookUrl -Method POST -ContentType "application/json" -Body $payload
