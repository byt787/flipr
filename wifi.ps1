$log = "$env:USERPROFILE\Desktop\log.txt"

Test-Path $log

if (Test-Path $log) {
    Get-Item $log | Select-Object Length
    Get-Content $log
}
