# ==================================================================
#  SAMUSIGNAL AI AUTO - VPS Scanner INSTALL (ek baar)
#  VPS pe PowerShell kholo aur ye ek line chalao:
#
#  [Net.ServicePointManager]::SecurityProtocol='Tls12';iex(iwr https://raw.githubusercontent.com/ankushchhajed7-cmd/samusignal/main/vps-scanner/install.ps1 -UseBasicParsing).Content
#
#  Kya karta hai:
#   1. C:\SamuScanner me Node.js (portable, admin nahi chahiye) + scanner.mjs
#   2. config.json Notepad me kholta hai -> aap Gemini key + FirebaseAuth daalo, Save, band karo
#   3. Task Scheduler me "SamuScanner" task (har 1 min, chhupa) - har nayi 15m candle par 1 scan
#   4. Ek test scan chala ke result dikhata hai (test me EA ko signal NAHI jaata)
#  Hatana ho to:  Unregister-ScheduledTask -TaskName SamuScanner -Confirm:$false
# ==================================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'
$Base = 'C:\SamuScanner'
$Raw  = 'https://raw.githubusercontent.com/ankushchhajed7-cmd/samusignal/main/vps-scanner/'
$NodeVer = 'v22.11.0'
$NodeDir = Join-Path $Base 'node'
$Node = Join-Path $NodeDir 'node.exe'

Write-Host ''
Write-Host '=== SAMUSIGNAL AI AUTO - VPS Scanner install ===' -ForegroundColor Yellow
New-Item -ItemType Directory -Path $Base -Force | Out-Null

if (-not (Test-Path $Node)) {
    Write-Host "1/5  Node.js $NodeVer download ho raha hai (~30 MB)..."
    $zip = Join-Path $env:TEMP 'samu-node.zip'
    Invoke-WebRequest -Uri "https://nodejs.org/dist/$NodeVer/node-$NodeVer-win-x64.zip" -OutFile $zip -UseBasicParsing
    $tmp = Join-Path $env:TEMP 'samu-node'
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Expand-Archive -Path $zip -DestinationPath $tmp -Force
    if (Test-Path $NodeDir) { Remove-Item $NodeDir -Recurse -Force }
    Move-Item (Join-Path $tmp "node-$NodeVer-win-x64") $NodeDir
    Remove-Item $zip -Force
} else { Write-Host '1/5  Node.js pehle se hai.' }

Write-Host '2/5  scanner.mjs download...'
Invoke-WebRequest -Uri ($Raw + 'scanner.mjs') -OutFile (Join-Path $Base 'scanner.mjs') -UseBasicParsing

$cfg = Join-Path $Base 'config.json'
if (-not (Test-Path $cfg)) {
    $tpl = @'
{
  "gKey": "YAHAN_GEMINI_KEY",
  "fbAuth": "YAHAN_FIREBASE_AUTH",
  "fbUrl": "https://forexdiagnosis-default-rtdb.asia-southeast1.firebasedatabase.app",
  "minConf": 70,
  "topN": 5,
  "aiPerDay": 300,
  "exclude": ["XAUUSD", "BTCUSD"]
}
'@
    Set-Content -Path $cfg -Value $tpl -Encoding ASCII
}
Write-Host '3/5  config.json Notepad me khul rahi hai:' -ForegroundColor Cyan
Write-Host '     YAHAN_GEMINI_KEY  -> SamuSignal app wali Gemini key'
Write-Host '     YAHAN_FIREBASE_AUTH -> News Pusher / Data Feed EA wala FirebaseAuth'
Write-Host '     Save (Ctrl+S) karke Notepad BAND karo - phir install aage chalega.'
Start-Process notepad.exe -ArgumentList $cfg -Wait

$vbs = 'CreateObject("WScript.Shell").Run """' + $Node + '"" ""' + (Join-Path $Base 'scanner.mjs') + '""", 0, False'
Set-Content -Path (Join-Path $Base 'run.vbs') -Value $vbs -Encoding ASCII

Write-Host '4/5  Task Scheduler me task (har 1 min)...'
$act = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument ('"' + (Join-Path $Base 'run.vbs') + '"') -WorkingDirectory $Base
$trg = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1)) -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Days 3650)
$usr = $env:USERNAME
if ($env:USERDOMAIN) { $usr = $env:USERDOMAIN + '\' + $env:USERNAME }
$pr  = New-ScheduledTaskPrincipal -UserId $usr -LogonType Interactive -RunLevel Limited
$set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 10) -StartWhenAvailable
Register-ScheduledTask -TaskName 'SamuScanner' -Action $act -Trigger $trg -Principal $pr -Settings $set -Force | Out-Null

Write-Host '5/5  Test scan (EA ko signal NAHI jaata, sirf dikhata hai)...'
Push-Location $Base
& $Node (Join-Path $Base 'scanner.mjs') --test
Pop-Location

Write-Host ''
Write-Host 'HO GAYA. Log: C:\SamuScanner\scanner.log' -ForegroundColor Green
Write-Host 'Ab MT5 (DEMO) me "SAMUSIGNAL AI AUTO v1.00" EA kisi bhi ek chart pe lagao.'
