# SAMUSIGNAL AI AUTO — VPS Scanner

App (SAMUSIGNAL AI) wala engine + Gemini AI VPS par 24×5 chalata hai. "AI सहमत" signal Firebase `/samuai/auto/sig` me jaata hai, aur MT5 ka **SAMUSIGNAL AI AUTO** EA us par LIMIT order lagata hai.

## Install (VPS par ek baar)
PowerShell kholo aur ye ek line chalao:
```
[Net.ServicePointManager]::SecurityProtocol='Tls12';iex(iwr https://raw.githubusercontent.com/ankushchhajed7-cmd/samusignal/main/vps-scanner/install.ps1 -UseBasicParsing).Content
```
Notepad khulega: `YAHAN_GEMINI_KEY` aur `YAHAN_FIREBASE_AUTH` ki jagah apni keys daalo → Save → Notepad band karo. Keys sirf VPS par rehti hain.

Phir MT5 (**DEMO**) me `SAMUSIGNAL AI AUTO v1.00` EA kisi bhi ek chart par lagao (FirebaseAuth input me wahi daalo).

## Dekhna
- Log: `C:\SamuScanner\scanner.log`
- Test: `C:\SamuScanner\node\node.exe C:\SamuScanner\scanner.mjs --test` (EA ko signal NAHI jaata)
- Hatana: `Unregister-ScheduledTask -TaskName SamuScanner -Confirm:$false`
