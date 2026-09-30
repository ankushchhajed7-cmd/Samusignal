# ==================================================================
#  SamuSignal VPS Helper - INSTALL (ek baar)
#  VPS pe PowerShell kholo aur ye ek line chalao:
#
#  [Net.ServicePointManager]::SecurityProtocol='Tls12';iex(iwr https://raw.githubusercontent.com/ankushchhajed7-cmd/samusignal/main/vps-helper/install.ps1 -UseBasicParsing).Content
#
#  Kya karta hai: C:\SamuVpsHelper me helper rakhta hai aur Windows
#  Task Scheduler me "SamuVpsHelper" task banata hai (har 2 min,
#  chhupa hua). Phir ek baar turant chala ke result dikhata hai.
# ==================================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'
$Base = 'C:\SamuVpsHelper'
$Raw  = 'https://raw.githubusercontent.com/ankushchhajed7-cmd/samusignal/main/vps-helper/'

Write-Host ''
Write-Host '=== SamuSignal VPS Helper install ===' -ForegroundColor Yellow
New-Item -ItemType Directory -Path $Base -Force | Out-Null

Write-Host '1/3  Helper download ho raha hai...'
Invoke-WebRequest -Uri ($Raw + 'SamuVpsHelper.ps1') -OutFile (Join-Path $Base 'SamuVpsHelper.ps1') -UseBasicParsing

# chhupa chalane ke liye (PowerShell ki kaali window har 2 min na aaye)
$vbs = 'CreateObject("WScript.Shell").Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\SamuVpsHelper\SamuVpsHelper.ps1""", 0, False'
Set-Content -Path (Join-Path $Base 'run.vbs') -Value $vbs -Encoding ASCII

Write-Host '2/3  Task Scheduler me task ban raha hai (har 2 min)...'
$act = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument ('"' + (Join-Path $Base 'run.vbs') + '"')
$trg = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1)) -RepetitionInterval (New-TimeSpan -Minutes 2) -RepetitionDuration (New-TimeSpan -Days 3650)
$usr = $env:USERNAME
if ($env:USERDOMAIN) { $usr = $env:USERDOMAIN + '\' + $env:USERNAME }
$pr  = New-ScheduledTaskPrincipal -UserId $usr -LogonType Interactive -RunLevel Limited
$set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 15) -StartWhenAvailable
Register-ScheduledTask -TaskName 'SamuVpsHelper' -Action $act -Trigger $trg -Principal $pr -Settings $set -Force | Out-Null

Write-Host '3/3  Pehli baar chal raha hai (EA files download + compile, 1-3 min)...'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base 'SamuVpsHelper.ps1')

Write-Host ''
Write-Host 'HO GAYA. Ab ye window band kar sakte ho.' -ForegroundColor Green
Write-Host 'App me COPY tab -> "VPS Helper" card (Bridge v1.02 lagne ke baad).'
