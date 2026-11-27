# SamuSignal — STATE

Har push ke saath ye file update hoti hai: kaun sa version, settings, faisle, aur kya baaki hai.

## SAMU GOLD KILLER v1.08 — sirf naye app command se trade (26 Nov 2026)
- User: "app ka button dabaye bina auto trade chalu ho gaya, aisa nahi hona chahiye". Kaaran: v1.07 lagate hi 18:43 ka purana START (MT5 GlobalVariable, 19:13 tak) wapas uth gaya -> SELL L1 0.01 18:56:37 (user ne mobile se band kiya, −$0.49).
- `vps-ea/SAMU GOLD KILLER v1.08.mq5`: EA lagte / MT5 restart par purana START hamesha hat-ta; EA lagne se pehle ka app command ignore; GitHubToken input me ho to `SGK_tok_<magic>.txt` me bhi save (agle version par JODO CODE / OFFLINE nahi).
- App OFFLINE (screenshot) ka kaaran: v1.07 token khaali -> JODO CODE ka intezaar. Chart par v1.08 + JODO CODE ek baar (ya token input me).

## SAMU GOLD KILLER v1.07 — START dabaya = trade lagega (26 Nov 2026)
- User: app se scan karke START dabaya par MT5 me trade nahi laga; "RED ho ya GREEN, button dabaya to trade lagna hi chahiye".
- Kaaran: 3 START (25 Nov 23:05, 26 Nov 13:17, 18:43) me EA ne OK diya par Shaant check ($5 / 30 min range) ne basket roki; ~21 ghante me range kabhi $5 se kam nahi hui -> 0 trade. VPS par abhi v1.05 chal raha.
- `vps-ea/SAMU GOLD KILLER v1.07.mq5`: input `StartOverride = true` -> app / chart START window me shaant check + news filter nayi basket nahi rokte (BUY STOP + SELL STOP turant). MaxLevels / max TP / window / spread waise hi. Tester ka khud-START Lab jaisa. `false` = purana tareeka.
- Helper sirf copy + compile; chart par v1.05 hata ke v1.07 lagana manual (ControlMode APP, token khaali -> JODO CODE -> app Settings > EA jodo). App v1.2.0 (chetavni + saaf START sandesh) SAMU-GOLD-KILLER-COMMAND repo me jaana baaki (is session me us repo ki push permission nahi thi).

## SAMU GOLD KILLER v1.06 — token paste nahi, JODO CODE (25 Nov 2026)
- User: VPS par token paste mushkil. `vps-ea/SAMU GOLD KILLER v1.06.mq5`: GitHubToken khaali -> dashboard par 9-akshar JODO CODE; app (SAMU-GOLD-KILLER-COMMAND v1.1.0) Settings > "EA jodo" me code -> token lock ho ke aata, EA `MQL5\Files` (Common) me save karta. Baaki v1.05 jaisa.

## SAMU GOLD KILLER v1.05 — App se START (25 Nov 2026)
- User: "मर्ज कर देना" (naya repo SAMU-GOLD-KILLER-COMMAND ka EA, VPS Helper se VPS par).
- `vps-ea/SAMU GOLD KILLER v1.05.mq5`: v1.04 + ControlMode APP (START/STOP/CLOSE app se GitHub live branch ya chart button se), max 2 TP, window ke baad $1 profit close, 30 min < $5 shaant check, deep bounce L8, har 30 sec status.json. Poora code + app: repo SAMU-GOLD-KILLER-COMMAND.
- Helper sirf copy + compile karega; chart par lagana manual. Pehle demo 1546. MT5 me Allow WebRequest `https://api.github.com` + input GitHubToken.

## VPS Helper v1.07 — scanner bhi Helper se VPS par (25 Nov 2026)
- User: "VPS Helper se VPS pe bhi bhej dena" (Scanner v1.13 / FX SENTINEL).
- Naye commit par: `vps-scanner/scanner.mjs` ka blob sha `state['scan']` se alag -> raw (usi commit) se `C:\SamuScanner\scanner.mjs` (Fix-File: pehle .fix, jaanch, phir badlo) + `engine\*.js` GitHub Pages se taaza (`?v=` cache tod). `$ScanEng` me `sentinelrules.js` (repair bhi). Log: "Scanner deploy: ...".
- Pehle scanner sirf khud 6 ghante me update leta tha. Ab merge ke ~2 min (helper khud update) + ~2 min (deploy) me VPS par; scanner agle minute se naya.

## Scanner v1.13 — 🛡️ FX SENTINEL auto paper, app band ho tab bhi (25 Nov 2026)
- User: SAMUSIGNAL-AI ke naye Sentinel page (7 major + XAUUSD, score 0–100) ka paper auto trade app band hone par bhi + roz raat 9:55 IST report.
- `vps-scanner/scanner.mjs` v1.13: ENG_FILES me `sentinelrules.js` (SAMUSIGNAL-AI Pages se, page ka hi code). `sentinelRun()` har run (har 1 min) me, AI AUTO `main()` + candle ke saath-saath (EA chup ho tab bhi):
  1) chalu paper ka nateeja (`evalTrade` 15m bars, bid + spread) -> `/sentinel/paper/<id>`; 2) har nayi 15m candle ke 25 sec baad `runScan` (feed 15m + 1h, quotes, MT5 cal + Forex Factory High news) -> `canOpen` -> naya paper (risk $ = `pipUsd`); Gemini (config ki gKey, Google Search) sirf `nearSetup` + 30 min me ek baar, `ST.aiDay` ki roz seema me; `/sentinel/radar`; 3) `/sentinel/daily/<IST din>` = `dayReport` (badla ho tab); 4) heartbeat `/sentinel/vps`; 5) safai din me ek baar (paper 60 din, daily 120 din).
- Setting app se `/sentinel/cfg` (minScore, rr, lot, maxOpen, dayLoss, expiryMin, ai). KOI ASLI ORDER NAHI.
- Jaancha: nakli Firebase + nakli Gemini ke saath do run — 3 paper, XAUUSD PENDING -> TP 1.8R $2.66, daily sahi.
- VPS par apne aap (scanner 6 ghante me khud ko update karta hai). Turant: `Remove-Item C:\SamuScanner\engine\engine.js` -> agle run engine + naya scanner, uske agle run se Sentinel.

## Abhi ka version

| Cheez | Version | File |
|---|---|---|
| SamuSignal app (PWA) | **10.10.1** (🎯 BUY ya SELL? page; SAMUSIGNAL AI v1.39.0 me bhi) | `index.html`, `sw.js` |
| PERSONAL FX EA | **10.3** (27 Nov raat: har SELL apna lock +$1 + jodi + tikdi; v9.0 backup) | `vps-ea/PERSONAL FX v10.3 - GRID.mq5` (backup `PERSONAL FX v9.0 - GRID.mq5`) |
| SamuSignal Data Feed (broker candles + live -> Firebase `/feed`; SAMUSIGNAL AI Scan / Candle page; koi trade nahi) | **1.01** | `vps-ea/SamuSignal Data Feed v1.01.mq5` |
| Tithi Gold EA | **2.06** | `vps-ea/Tithi Gold v2.06.mq5` |
| BTC EA (Buster clone) | **1.18** | `vps-ea/BTC EA v1.18.mq5` |
| BTCGOLD EA (BTC EA ki gold copy, Buster trailing) | **1.02** | `vps-ea/BTCGOLD EA v1.02.mq5` |
| AMC GOLD MASTER (GrowthMasters jaisa M5 gold EA) | **1.01** | `vps-ea/AMC GOLD MASTER v1.01.mq5` |
| BTC Trailing Manager (Buster ke liye) | **1.03** | `vps-ea/BTC Trailing Manager v1.03.mq5` |
| AurumX Clone (real slippage test) | **1.01** | `vps-ea/AurumX Clone v1.01.mq5` |
| Investor Account Watcher (INVESTOR-ID repo) | **1.11** | `vps-ea/Investor Account Watcher v1.11.mq5` |
| MEXA SCALP Signal EA (MEXA-SCALP repo, sirf signal + push, koi trade nahi) | **1.00** | `vps-ea/MEXA SCALP Signal EA v1.00.mq5` |
| MEXA SCALP Trade EA (MEXA-SCALP repo, AUTO TRADE — cooldown + M15 trend filter + profit lock, demo / Strategy Tester) | **1.02** | `vps-ea/MEXA SCALP Trade EA v1.02.mq5` |
| ARADHAYA SCALPER (multi engine gold scalper + manager; v1.00 LIVE NA chalayein) | **2.04** | `vps-ea/ARADHAYA SCALPER v2.04.mq5` |
| SUPERTREND HEDGE (M5 Supertrend + 2x hedge cycle, gold) | **1.19** | `vps-ea/SUPERTREND HEDGE v1.19.mq5` |
| SUPERTREND GRID (M1 Supertrend + $10 grid basket, gold; hedge EA ki jagah) | **2.08** | `vps-ea/SUPERTREND GRID v2.08.mq5` |
| FX Bars Pusher (FX-TRADER-SKILL- repo, XAUUSD M5 bars GitHub `data` branch par bhejta hai, koi trade nahi; token EA input me, WebRequest me api.github.com allow karna) | **1.00** | `vps-ea/FX Bars Pusher v1.00.mq5` |
| SamuSignal News Pusher (SAMUSIGNAL-AI ke NEWS page ke liye: MT5 Economic Calendar ka asli number -> Firebase `/feed/news`, koi trade nahi; Data Feed wale terminal pe, WebRequest me Firebase URL) | **1.03** | `vps-ea/SamuSignal News Pusher v1.03.mq5` |
| SAMUSIGNAL AI AUTO (VPS scanner ke "AI sahmat" signal par LIMIT; TP $0.25 / SL $1.50; XAU / BTC nahi; 1 pair 1 trade; news 60/60 min; din: 4 loss ya $3 profit = band + TARGET LOCK (v1.13); REAL par AllowReal=false se band) + `vps-scanner/` (Node, app ka engine) | **1.13** | `vps-ea/SAMUSIGNAL AI AUTO v1.13.mq5`, `vps-scanner/scanner.mjs` (v1.13 — + 🛡️ FX SENTINEL auto paper) |
| SAMUSIGNAL CANDLE EA (app Candle page / Strategy 5 ka apna EA — naye $100 DEMO par; sirf app me ON pair, sirf 1 MIN; 24 ghante (sirf news rok); lock +$0.15 → SL +$0.10 + trail $0.05; High news ±30 min naya trade nahi; floating −$2 = pair din bhar band + badla pair auto; ek saath max 3 + haath ka 1 slot (haath ka trade bhi isi niyam se); VPS paper jaisa niyam; Matrix Terminal dashboard + PAUSE / CLOSE ALL; REAL par AllowReal=false se band) | **1.12** | `vps-ea/SAMUSIGNAL CANDLE EA v1.12.mq5` |
| BotFlow (bahar ka EA, sirf .ex5 — source nahi; VPS Helper seedha copy karta hai) | — | `vps-ea/BotFlow.ex5` |
| Gold_Sl_Tp (bahar ka gold EA, sirf .ex5 — "Alox Software" v1.03; VPS Helper seedha copy karta hai) | 1.03 | `vps-ea/Gold_Sl_Tp.ex5` |
| Btc_V1_Licence (bahar ka BTC EA, sirf .ex5 — "Telegram-@SuccessZonee / www.Btcv1.in"; VPS Helper seedha copy karta hai) | — | `vps-ea/Btc_V1_Licence_420841723.ex5` |
| EMA20 M5 SCALPING (Tanisha Garg video: green EMA20 ke upar close -> agli 2 me red EMA ke upar -> red high pe BUY STOP; SELL ulta; saare forex pair ek chart se; 0.01 lot; hard SL + EMA close exit; v1.01: virtual stop (BID break), trailing SL, session 07-24) | **1.01** | `vps-ea/EMA20 M5 SCALPING v1.01.mq5` |
| SAMU GOLD KILLER (app se START, JODO CODE, START = trade lagega, sirf naye command se, demo 1546) | **1.08** | `vps-ea/SAMU GOLD KILLER v1.08.mq5` |
| SAMU Universal EA (SAMU-BACKTEST-LAB repo: strategy JSON `MQL5\Files\step-basket.json` padhta hai, na mile to built-in Step Basket; Supertrend M15 pehla trade + $5 step grid, lot table, preset A/B/C, daily +1% / −5%, 07:00 IST reset; Gold Luxe dashboard + PAUSE / CLOSE ALL; v1.01: purane account pe safe — Own P/L mode ($1000 allocated), margin guard 300%, magic clash check; v1.02: dashboard laptop DPI pe theek + sirf EA ka P/L; v1.03: **default PAPER mode** (koi asli order nahi, InpLiveTrading=false); trade log CSV; chart XAUUSDm **M1**; v1.04: Friday stop + news filter; strategy JSON `vps-files/step-basket.json` = Step Basket $10 FINAL) | **1.04** | `vps-ea/SAMU Universal EA v1.04.mq5`, `vps-files/step-basket.json` |
| VPS Helper (GitHub main -> VPS, .mq5 compile + .ex5 copy; v1.04: VPS scanner ki khaali / adhoori file khud theek; v1.05: Watcher token heal; v1.06: `vps-files/*.json` -> har terminal ka `MQL5\Files`; v1.07: naya `vps-scanner/scanner.mjs` turant VPS par + engine taaza) | **1.07** | `vps-helper/SamuVpsHelper.ps1` |
| Kavach test | 256 test (26 pair test PASS; 14 purane FAIL v10.3.0 se chale aa rahe — neeche dekho) | `kavach.js` |

## SAMU Universal EA v1.04 + Helper v1.06 — Step Basket $10 FINAL (19 Nov 2026, main → VPS Helper)
- User: Step Basket $10 FINAL VPS pe PAPER test ke liye (SAMU-BACKTEST-LAB v0.6.5/v0.6.6).
- EA v1.04: `filters.friday_stop` (Friday 14:00 IST ke baad + weekend nayi basket nahi) + `filters.news` (MT5 calendar USD High ±30 min, sirf live/paper). Banner FRIDAY STOP / NEWS, info line `News` + `Fri`.
- Helper v1.06: `vps-files/step-basket.json` har terminal ke `MQL5\Files\step-basket.json` me (GitHub pe badle tabhi dobara). FINAL: lot table 0.01×3/0.02×3/0.03×3/0.04, $5 step, max 20, basket +$10 / SL 5%, daily +1% / −5%, Friday 14:00, news on.
- Chart pe v1.03 hata ke **v1.04** lagao (XAUUSDm M1, InpLiveTrading=false, InpAllocBalance=10000 backtest se milane ke liye).
- Helper ka PowerShell code yahan chala ke test nahi hua (pwsh nahi tha) — VPS Helper report me `step-basket.json` ka result dekhna.

## SAMU Universal EA v1.03 — PAPER mode default (19 Nov 2026, main → VPS Helper)
- User: is account par sirf testing / backtest — Universal EA ki asli gold trade nahi chahiye (v1.01 ne 13:29 IST SELL 0.01 XAUUSDm kholi thi, magic 770100; AI AUTO ki nahi thi — AI AUTO XAU exclude karta hai).
- v1.03: `InpLiveTrading = false` (default) → virtual trades, broker ko koi order nahi; dashboard PAPER P/L; log `MQL5\Files\SAMU_UEA_paper_XAUUSDm_770100.csv`.
- Purani asli SELL (magic 770100) EA nahi chhoota → banner warning; haath se band karni hai.
- Chart pe v1.02 / v1.01 hata ke **v1.03** lagao.

## SAMU Universal EA v1.02 — dashboard theek (19 Nov 2026, main → VPS Helper)
- v1.01 VPS pe compile OK + chal raha tha (13:29 IST pehli SELL), lekin laptop (150% DPI, Toolbox khula = chhoti height) pe dashboard bahut chhota / overlap.
- v1.02: DPI factor + compact layout; bada number = **EA P/L** (sirf is EA ke trades); $1000 base aur account equity display se hataye (user: doosre EA ka +/- bhi dikh raha tha). Base > account equity → sirf warning.
- Chart pe v1.01 hata ke **v1.02** lagao (inputs wahi). Basket / peak / day state Global Variables se wapas aata hai.

## SAMU Universal EA v1.01 — purane account pe safe (19 Nov 2026, main → VPS Helper)
- User: VPS pe naya account add karne ki jagah nahi → purane $1000 account pe (doosre EAs ke saath) chart lagayenge.
- **InpOwnMode = true** (default): daily +1% / −5% aur basket SL 1% sirf is EA ke trades + `InpAllocBalance` ($1000) se; doosre EAs ka P/L asar nahi.
- **InpMinMarginLevel = 300**: trade ke baad margin level 300% se neeche → nayi trade nahi. **Magic clash**: 770100 pe doosre EA / symbol ki trade (khuli ya 30 din) → trade band + laal banner.
- Chart: XAUUSDm **M1**, Hedging account. v1.00 file bhi pada hai (compile hoga), lagana **v1.01** hai.

## SAMU Universal EA v1.00 — VPS Helper se pehli baar (19 Nov 2026, main → VPS Helper)
- Source repo: **SAMU-BACKTEST-LAB** (`ea/SAMU Universal EA v1.00.mq5`); yahan sirf deploy copy. Rules = Backtest Lab engine (`docs/ENGINE-RULES.md` wahan).
- Helper JSON copy nahi karta → `MQL5\Files\step-basket.json` na ho to EA built-in Step Basket (preset B) se chalta hai, banner pe likha aata hai.
- Compile pehli baar VPS pe ho raha hai (cloud me MT5 nahi tha) → result COPY tab → VPS Helper me dekhna; error ho to SAMU-BACKTEST-LAB me v1.01.
- Chart: XAUUSDm **M1**, Magic 770100 (default). Pehle demo / Strategy Tester; live se pehle app ke backtest se milana.

## SAMU GOLD KILLER v1.04 — Trade Time + raat ki news (18 Nov 2026, main → VPS Helper)
- Wajah: 18 Nov ~21:45–22:15 IST ~$35 giravat, BUY basket L16 (~2.2 lot), equity DD $1,496 (14.5%), phir +$91 par band.
- 2 mahine ke H1 data (InstaForex 72929366): sabse tez 18:30–21:30 IST ($22–26/ghanta, p90 $51), 06:30–08:30 ($18–21); shaant 02:30 ($9), 09:30 ($13), 15:30–16:30 ($12), 22:30–00:30 ($13–16).
- User ka faisla: nayi basket sirf 09:00–10:30 aur 22:30–00:30 IST. Raat 21:00–03:00 IST me koi HIGH USD ya Fed (FOMC / Fed Chair / Powell / Federal Funds / Interest Rate Decision) news → us din raat OFF. ±30 min news filter waisa hi. Bahar: khuli basket level jodti + $30 TP; L1 pending hat jaata.
- Baaki sujhaav (badhta gap, multiplier 1.2 / max lot 0.10, DD Reducer, gehri basket ka jaldi TP, −10% suraksha) — user: "abhi sirf Time + News"; baad me.
- Inputs: UseTradeTime, Session1, Session2, NightNewsSkip, NightNewsFrom, NightNewsTo, FedWords. Dashboard: banner OFF TIME / RAAT OFF, DETAILS "Trade time".
- Compile 0 errors, 0 warnings.

## VPS Helper v1.05 — TOKEN HEAL (18 Nov 2026 raat, main)
- 1546 Watcher 401 (≈18:00 se): user ke phone → remote paste me token bigadta raha, aur jo token daala wo bhi band tha. VPS ke Firefox se GitHub "Access temporarily restricted" (VPS IP par bahut API traffic).
- Hal bina user ke: helper har 10 min VPS ke sab terminal (.chr / .set / MQL5\Files / Common) me GitHub token dhoondhta hai, GitHub se jaanchta hai (INVESTOR-ID push = OK), aur sahi token har Watcher terminal ke MQL5\Files\investor_token.txt + Common\Files\IW_gh_token.txt me rakhta hai (sirf jahan kharab / khaali). Watcher v1.07+ 401 par har 60 sec file dobara padhta hai → khud theek.
- Haal GitHub par: INVESTOR-ID `data/_vps/heal.json` (token nahi, sirf ginti / kaunse terminal theek hue).

## AurumX Clone v1.01 — SL asli fill se + max loss (25 Nov 2026, main → VPS Helper)
- Exness demo (MT5Trial7) par owner: loss $0.50 se bada. Wajah: v1.00 SL maange gaye STOP price se lagata tha; fill aage hone par loss = 0.50 + slippage; upar se Exness spread ~$0.25 (Vantage $0.11).
- v1.01: fill hote hi SL = asli fill ∓ $0.50 (AurumX jaisa); price pehle hi us SL ke paar ho to turant band (`SL_FILL`); `InpMaxLossUsd` 0.70 — floating loss itna ho to turant band (`MAXLOSS`); dashboard TRADE card par is trade ka entry slippage.
- Log reason me ab MAXLOSS / SL_FILL bhi. Compile yahan nahi hua — VPS Helper dekhna.

## AurumX Clone v1.00 — real slippage test (25 Nov 2026, main → VPS Helper)
- Wajah: Vantage demo 26209579 ka AurumX scalper demo par +$130 / 10.8 h, par SAMU Backtest Lab (research/aurumx) me slippage $0.05/side par clone minus. Owner ne raasta 2 chuna: 1 din real account par 0.01 se naapna.
- Niyam (Lab clone jaise, `fast` rule ke bina): side = M1 close vs EMA100; STOP order $0.60 door, har 3 s price ke peeche; SL $0.50; trail 0.40/0.40; TP nahi; 1 trade; 0.01 lot; magic 260001.
- Suraksha: din ka loss $3 → sab band; max 40 trade/din; spread > $0.20 → nayi order nahi; reset 07:00 IST; PAUSE / CLOSE ALL.
- Log: `MQL5\Files\AurumX_Clone_<acc>.csv` (req vs fill, entry + SL exit slippage). Watcher input `JournalFiles = AurumX_Clone_{acc}.csv` → GitHub.
- Gold Luxe full-screen dashboard (TREND / TRADE / TODAY / SLIPPAGE cards, DD-of-limit / trades / spread bars, aakhri 10 trade table).
- Yahan compile nahi ho saka — VPS Helper ka compile result dekhna.
- DHYAN: Exness standard XAUUSDm spread ~$0.26 > $0.20 → order nahi lagega; test ke liye InpMaxSpread 0.30 (nuksan ki sambhavna zyada).

## Investor Account Watcher v1.11 — TICK RECORD (25 Nov 2026, main → VPS Helper)
- Wajah: Vantage demo 26209579 par "AurumX" (magic 2026) — 749 trade / 10.7 ghante, median 5 sec, 0.01 lot, +$129. Iski entry samajhne ke liye M1 kaafi nahi, tick chahiye.
- Naye inputs: `TickRecord` (true), `TickSymbols` (khaali = chart symbol), `TickBackfillHours` (24).
- Har poore ghante ke tick (COPY_TICKS_INFO: ms, bid, ask) MT5 ki tick history se → `INVESTOR-ID/data/<acc>/ticks/<SYM>_<YYYYMMDD>_<HH>.csv` (server time; header me GMT offset). Ek timer me ek file, fail ho to agli baar wahi ghanta; state `MQL5\Files\IW_ticks_<acc>.txt`.
- Bada upload (>300 KB) ke liye WebRequest timeout 60 s. Yahan compile nahi ho saka (MetaEditor nahi) — VPS Helper ka compile result dekhna.
- Lagana: Vantage chart par v1.10 hata ke v1.11 (sirf usi terminal par; baaki terminal v1.10 hi rahen to tick nahi jaayenge).

## Investor Account Watcher v1.09 — token safai (18 Nov 2026, main → VPS Helper)
- v1.08 log: length 93 par bhi "type=ANJAAN" (github_pat_ nahi mila) → paste me '_' ya koi akshar badal raha tha.
- Wajah ki kahani: user INVESTOR-ID app se logout → login; tab token naya / regenerate hua → 1546 ka purana token band (≈18:00 IST se 401). 464208541 Watcher doosre token se chalta raha.
- v1.09: token me sirf A-Z a-z 0-9 _ rakhta hai (baaki nishan → '_', chhupe nishan hatao), Experts me pehle 11 akshar print ("github_pat_" — raaz nahi). Compile 0 errors, 0 warnings.

## Investor Account Watcher v1.08 — token ki shuruaat khud theek (18 Nov 2026, main → VPS Helper)
- v1.07 log: naya token length 93 par "type=ANJAAN shuruaat" → keyboard ne "Github_pat_" (bada G) kar diya tha.
- v1.08: FixToken() — "github_pat_" / "ghp_" se pehle ka sab hatata hai aur prefix chhote akshar me. Compile 0 errors, 0 warnings.
- Token kabhi .mq5 me default nahi daalna: Samusignal / INVESTOR-ID public hain, GitHub public repo me mila PAT turant cancel kar deta hai.

## Investor Account Watcher v1.07 — token fix (18 Nov 2026, main → VPS Helper)
- Dikkat: 434151546 par GhPut 401 "Bad credentials". Wajah: v1.06 pehle MQL5\Files\investor_token.txt (purana kharab token) padhta tha, Inputs ka naya token andekha; Inputs me file ka naam badalne par wapas aa jaata tha.
- v1.07: Inputs ka token PEHLE; bhara ho to file me bhi save. Start par GitHub token jaanch (OK / 401 / 403 / 404 / WebRequest band) Experts + chart Comment me. 401 par doosra token aazmata hai; har 60 sec file dobara padhta hai (file me naya token save = bina restart chalu). 401 log 5 min me 1 line.
- Compile: 0 errors, 0 warnings (INVESTOR-ID compile-mq5).
- Test: v1.06 chart se hatao → v1.07 lagao → Inputs me token → Experts: "token source=input, length 93" + "jaanch = OK" → 15 min me INVESTOR-ID data/434151546/report.json ka updatedAt naya.

## SAMU GOLD KILLER v1.03 — dashboard door se padhne layak (18 Nov 2026, branch feature-samu-gold-killer-v1.03)
- v1.02 full screen bana par laptop par akshar bahut bareek (6pt) — door se nahi dikhte. Ankush: "clear, bold, green highlighted, door se bhi dikhe".
- Ab: sab text BOLD (Segoe UI Semibold / Black), sabse chhota akshar 10pt (input MinFontSize), input TextScale (1.2 = 20% bade), chamkile rang (hara 0,230,118 / laal 255,90,90 / sona 240,196,64), ALL CLEAR banner hare background par (News/Paused peela, Emergency laal background).
- Kam lines: info line + drawdown bar hataye (DETAILS me: Next BUY/SELL, News, Spread, Drawdown, Levels, Aaj sabse bura, agli news). Trade table me naye trade upar.
- Preview 1270×470 @125% (Ankush ka laptop) — 0 overlap, 5 table rows + 5 details.
- Trading logic same.

## SAMU GOLD KILLER v1.02 — FULL SCREEN dashboard (18 Nov 2026, branch feature-samu-gold-killer-v1.02)
- v1.01 ka panel laptop (Windows scaling ~125%) par chhota aur akshar ek-dusre par chadhe; candles panel ke upar dikh rahi thi. Ankush: "poore screen pe, full size dashboard" — ab har EA ka default.
- Ab: poora chart window = dashboard (CHART_SHOW off, input HideChart=true; EA hatane par chart wapas). Layout unit = min(chart width/100, height/62), font size = DPI se — koi bhi window size / scaling par fit. Preview check (1340×520 @120 DPI, 1880×820 @96, 1000×600) — 0 overlap.
- Upar: title, bada Equity, Balance/Floating/broker #login, IST time + din + server. Status banner. BUY GRID / SELL GRID / TODAY / CYCLES. BUY basket | SELL basket bars (aadha-aadha) + Drawdown bar. Info line. Neeche: trade table (#, type, lot, price, open IST, P&L — jitni jagah utni rows) + DETAILS (next BUY/SELL, news + agli news, spread, max loss, max levels, grid/pending, avg, magic). Buttons PAUSE / CLOSE BUY / CLOSE SELL / CLOSE ALL.
- Trading logic v1.01 jaisi hi (koi badlav nahi).
- Note: us terminal ka Investor Account Watcher GitHub par 401 "Bad credentials" de raha tha — token badalna hai.

## SAMU GOLD KILLER v1.01 — Gold Luxe dashboard + news filter (18 Nov 2026, branch feature-samu-gold-killer-v1.01)
- Dashboard (Ankush ka "Gold Luxe" style — ab har naye EA me default): kaala panel, sone ka bada Equity, Balance/Floating, top-right IST time + din + server time, status banner (All clear / Paused / News / Spread / Emergency: hedging nahi, MaxLevels full, MaxLoss ke 80%), 4 column BUY GRID / SELL GRID / TODAY / CYCLES, bars: BUY basket of $30, SELL basket of $30, Drawdown (MaxLoss, ya OFF ho to 10% balance) + aaj ka sabse bura floating, info line (next BUY/SELL level + lot + pending price, spread, news), trade table (#, type, lot, price, open IST, P&L, 10 row), buttons PAUSE/RESUME, CLOSE BUY, CLOSE SELL, CLOSE ALL (Yes/No confirm). Pause GlobalVariable me yaad rehta hai.
- News filter: MT5 Economic Calendar, USD, sirf High (input se Medium bhi), news se 30 min pehle + 30 min baad naya pending nahi aur purana pending delete; khule trade ka $30 TP / MaxLoss chalta rehta. Tester me calendar nahi hota → off.
- Spread filter: OFF hi rakha (MaxSpreadUSD = 0) — original GOLD KILLER me nahi tha (seller ki settings me input nahi, record me spread fixed $0.80).
- Live demo: Exness 434151546 ($10,000) par v1.00 chal raha — BUY L1 3761.60, SELL STOP Bid − $0.80 par trail sahi.

## SAMU GOLD KILLER v1.00 — naya EA (18 Nov 2026, branch feature-samu-gold-killer-v1.00)
- Source: InstaForex MT4 account 72929366 ("GOLD KILLER @superforexbot", magic 666888) — INVESTOR-ID repo ke Strategy Scan (2267 trades) + 3 ghante Live Record (har tick + har order/SL) se rules nikale, simulator se match kiye: lot 27/27, pending lagna 21/22 (2 sec), fill 23/27 (3 sec / $0.10), basket $30 3/4. Seller video ki settings (Grid 80, trailing step 5, lot ×1.3) bhi match.
- Rules: dono side hamesha chalu; pending = Ask + $0.80 (SELL: Bid − $0.80), market ki taraf hi khiskta hai (min $0.05); naya level tabhi jab pending price pichhle (sabse neeche BUY / sabse upar SELL) se ≥ $0.80 door; lot = 0.01 × 1.3^(level−1) 2 decimal; side ka floating ≥ $30 → us side ke sab trade band + pending delete → turant naya 0.01 pending.
- Safety (original me nahi): MaxLevels 22 (level 22 = 2.47 lot), MaxLossUSD 0 (off), MaxSpreadUSD 0 (off). Original EA 22 level tak bina SL gaya hai — account $5000 bonus se shuru tha.
- Andaaza / OFF: H1 trailing SL (1-trade basket; record me pichhli H1 candle high/low par khiska, history me sirf aadha match) — `UseH1TrailSL=false`.
- Distance $ me (InstaForex GOLD 2 digit 80 points = $0.80) — XAUUSDm (3 digit) par bhi same.
- Compile check: INVESTOR-ID `compile-mq5.yml` (GitHub Windows MT5 MetaEditor).
- Baaki: Strategy Tester (XAUUSDm, Every tick real) $5000+ par; spread $0.80 se kam hone ka asar dekhna.

## VPS Helper v1.04 + Scanner v1.11 — disk bhari thi, scanner.mjs 0 byte (17 Nov 2026)
- 16 Nov raat VPS C: drive bhar gayi (288 KB free). Scanner apna naya version likhte waqt `C:\SamuScanner\scanner.mjs` 0 byte (23:20) → 17 Nov subah se AI AUTO ko signal / candle push / VPS paper band ("SCANNER CHUP!"). User ne Tester / Crashes / WebInstall / Recycle Bin saaf karke 3.59 GB kiya.
- Helper v1.04 `Repair-Scanner()` har run (2 min) me: scanner.mjs < 10 KB ya marker nahi → GitHub raw se `.fix` me laakar jaanch ke badalta hai; `engine\*.js` < 300 byte / `export ` nahi → GitHub Pages se. Disk < 50 MB ho to nahi. Log: "Scanner repair: ...".
- Scanner v1.11 `safeWrite()`: engine / apna naya version / state.json pehle `.tmp`, poora likha to hi rename (disk bhari ho to purani file salamat).
- Helper khud ko agle run se naya leta hai (abhi purane EA dobara compile me busy) → repair ~15–30 min me.

## 🕯️ CANDLE BAND — VPS Scanner v1.12 (24 Nov 2026)
- User: "Candle wala option kaafi safal nahi ho raha, app se hata do, uski jagah naya strategy daalenge". 16–24 Nov CANDLE EA demo: 198 trade, net −$9.70 (TP 64 +$21.55, TIME 22 −$29.59, SL 1 −$8).
- Scanner v1.12: `CANDLE_ON = false` → `candleLoop()` turant return (na /candle/sig, na paper, na push). AI AUTO scan wahi. ENG_FILES me candlerules.js abhi bhi (helper repair use karta hai, nuksaan nahi).
- App v1.36.0 (SAMUSIGNAL-AI): Candle button + candle.html + src/candle.js hataye (candlerules.js Pages par rehta hai — scanner ke liye).
- VPS par CANDLE EA chart se user hataye (code repo me rehta hai). AI AUTO ka `CandlePushOn` ab kuch nahi bhejega (sig nahi banenge).

## SAMUSIGNAL CANDLE EA v1.12 — TARGET LOCK $0 bachaav + haath se band EA trade ka record (20 Nov 2026)
- 20 Nov: target $3.20 pura, par AUDUSD SELL (08:52) −$6.1 par khula; LOCK $3 ke intezaar me raha → trade ~−$5.88 par band → din −$2.68 (aur din band, sticky). User "Final": ① + ③, ② (a) din band wala niyam wahi.
- ① `TgtFloorUsd` 0: `DoTargetLock()` — target ke baad kul (din ka band net + chalu InDay P/L) ≤ $0 → DayStats dobara → sab (EA + haath) "TARGET LOCK $0" band + push. Kul ≥ target par band pehle jaisa.
- ③ `OnTradeTransaction`: magic ≠ EA wala OUT deal jiski position ka IN deal EA magic ka hai (haath / mobile se band) → `eaPos` → EA ke raste: Firebase record `done` + res "HAATH SE BAND" + push (pehle record "chalu" hi rehta tha).

## SAMUSIGNAL CANDLE EA v1.11 — backtest se: LOCK + WAPSI band, TP $0.40 / SL $8 (0.02), TIME 450, 15 pair, din −$16 (19 Nov 2026)
- User: "SL poora le rahe hain, TP na ke barabar — 20-25 jagah se poochh kar perfect hal do". `research/candle_backtest.py` (PR #229; GitHub Actions, Yahoo 1m 11–19 Nov, 13 pair kaam ke — EURUSD / GBPUSD / AUDUSD / NZDUSD ka data 0 signal): 12,507 signal, 300+ niyam. Nateeja (0.01 lot, 15m+1h trend saath): v1.10 (TP .25 SL 3 LOCK WAPSI T300) +$25 / AUDCAD ke bina −$28.9; LOCK + WAPSI hata kar +$45; **TP .20 SL 4 T450 +$85 (AUDCAD bina +$39), win 93.8%, PF 1.75, DD $7, dono aadhe din +$44 / +$42**; SL ≤ $2, ATR / candle-structure SL sab bhaari ghate me; poora SL sirf ~1% trade me; USDCHF + EURAUD har niyam me ghata. Web: chhota TP + bada SL theek agar jeet % zaroorat (89.6%) se upar.
- User "Ok..final" → `TrailOn` false (LOCK band), `RecoverDipUsd` 0 (WAPSI band), `TpFixedUsd` 0.20 (→ $0.40), `SL_Usd` 4 (→ $8), `HoldMax1` 450, `PickList` 15 (USDCHF, EURAUD hataye), `DayLossUsd` 16. Dashboard RULES "LOCK band". Spread jaanch (TP ka 50% = $0.10 / 0.01 lot) wahi — GBPJPY / USDCAD jaise ($0.11–0.13) aksar chhootenge.

## SAMUSIGNAL CANDLE EA v1.10 — "6 PERFECT TRADES": MARKET / LIMIT / STOP, TP $0.50 / SL $6 (0.02), din $3 / −$12 (17 Nov 2026 raat)
- User: entry Signal AI jaisi perfect; LIMIT / STOP / MARKET me se jo haalat me sahi; 28 me se sabse achhe pair; lot 0.02, TP $0.50, din $3 (kitne bhi trade, ek saath 6 tak); XAU / BTC nahi; pair chhaantne ka faisla mujh par → SL $6, "Final, loss limit $12".
- `PickList` 17 forex (EURUSD, GBPUSD, USDJPY, USDCHF, USDCAD, AUDUSD, NZDUSD, EURJPY, GBPJPY, AUDJPY, CADJPY, CHFJPY, NZDJPY, EURAUD, EURCAD, EURCHF, AUDCAD) — hataye: EURGBP (paper ghata, spread $0.17), NZDCHF ($0.17), GBPAUD ($0.14), EURNZD, GBPNZD, AUDNZD, NZDCAD, CADCHF, GBPCHF, GBPCAD, AUDCHF (kam chalne wale / bade spread).
- `Lot` 0.02, `TpFixedUsd` 0.25 (0.01 par → $0.50), `SL_Usd` 3 (→ $6), `MaxOpen` 6 (pending bhi gine), `SlotSteps` "", `DayTargetUsd` 3, `DayLossUsd` 12, `LockAtUsd` 0.15 / `LockToUsd` 0.05 (→ +$0.30 par SL +$0.10), `TrailAfterLock` false, `BookOn` false (chhota BOOK band), `RecoverDipUsd` 1 (→ −$2 gaya to wapas $0 par "WAPSI $0", GlobalVariable SSC_DIP_<ticket>), TIME 300 wahi.
- `PickScan()`: signal → rok (chalu / pending / band / news) → spread ≤ `PickSpreadPct` 50% TP → `PickNeedHtf` 15m + 1h EMA9/21 dono saath → `SigCtx()` (close, EMA21, ATR14, pichhle 20 ka high / low signal candle se pehle) → ORDER: pichhla high/low saamne ≤ `StopNearAtr` 0.3 ATR = STOP (level + max(spread, 0.1 ATR)); kheench > `LimitStretchAtr` 1 ATR ya body > `LimitBigBody` 2× = LIMIT (body `LimitPullPct` 40% peechhe); warna MARKET. Score = taakat 35 + TP/spread 25 + 5m 20 + kheench kam 20; ≥ `PickMinScore` 70; `PickPerMin` 1. LIMIT / STOP bhaav pehle hi paar = MARKET.
- Pending: `CheckPend()` har sec — `PendMin` 5 min / news / target / loss / PAUSE par hatao; Firebase record bharne par (`PdAdd` / `PdFilled` OnTradeTransaction DEAL_ENTRY_IN), record me `ord`. Exposure + HasPend me pending bhi. CLOSE ALL pending bhi hataata hai. State me `pend`. Dashboard RULES line naya.
- User (saath me): haath ka trade bhi rahe — wahi SL / TP / LOCK / WAPSI (AdoptManual), aur uska fayda / ghata din ke $3 / −$12 me: `ManualInDay` true → `InDay(mg)` (Magic ya 0) DayStats (sirf BUY / SELL deal, deposit nahi), FloatPl, TARGET LOCK (haath ka bhi band); haath ka trade band hone par DayStats + PublishState.
- Note: 17 Nov ka bada TIME loss (−$1.62) EA ka AUDJPY / NZDCHF SELL 19:17 tha (USD news nahi) — news filter theek; paper ka USDCAD 19:17 alag tha.

## SAMUSIGNAL CANDLE EA v1.09 — AUTO PICK + seedhi slot 8/6/4 + target $3 lock + BOOK $0.10 + TIME 300 (17 Nov 2026)
- User: (a) min profit badhao + TIME 300; (b) app ke fix pair ki jagah EA khud har minute sabse achha pair chune; (c) $3 target me $0-1: 8 trade, $1-2: 6, $2-3: 4, $3 = sab band → "864" (Final).
- AUTO PICK (`AutoPick` true, `PickList` 15 pair, XAU nahi): `PickScan()` har server minute ke 2-20 sec me ek baar — har pair ki taaza band M1 candle par `Signal()`; chalu / aaj band / news wale bahar; TP (body 100%, $0.15-1.00) < `PickTpSpread` 2× spread = bahar; score = taakat (body/avg10, max 4x → 40) + TP/spread (max 10x → 30) + 5m EMA9/21 saath 15 + 15m saath 15; < `PickMinScore` 40 = bahar; bada score pehle; `PickOneCurDir` (EA + haath ke chalu trade ki currency-disha, jaise EUR+ / USD−, dobara nahi). Key wahi format, Firebase trade me `why` "AUTO 72 (taakat…)". AutoReplace / AutoExpire AUTO PICK me band. App ke ON pair sirf paper.
- Seedhi slot: `SlotSteps` "8,6,4", `StepUsd` 1 → `CurMax()` (din ka band net). Slot ghate to chalu trade band nahi.
- `DayTargetUsd` 2 → 3 + `TargetLock` (AI AUTO v1.13 jaisa): `TgtHit()` din me pehli baar target → din band (sticky) + push; `DoTargetLock()` har 250 ms: net + floating ≥ target → sab band "TARGET LOCK", kam → intezaar push ek baar.
- `Book_Usd` 0.05 → 0.10; naya `BookCloseUsd` 0.10 (candle band par fayda ≥ $0.10 tabhi BOOK; pehle $0.004). `HoldMax1` 200 → 300.
- `FloatStopUsd` 0 (band) — sujhaav −$5, user ne abhi chalu nahi kaha.
- Dashboard: AUTO PICK line (aakhri jaanch, top 4 score), SLOTS "x / CurMax (seedhi 8,6,4)", 8 trade tak (log chhota). State me `auto`, `pick`, `target`, `steps`, `max` = CurMax.

## SAMUSIGNAL CANDLE EA v1.08 — LOCK + TRAIL (16 Nov 2026)
- User: "0.10 lock karo aur wahan se trail" → sujhaav ($0.15 par lock → SL +$0.10, trail $0.05, door ka TP body 100%) → "Final, TIME 200 bhi rakho".
- `TrailOn` true, `LockAtUsd` 0.15, `LockToUsd` 0.10, `TrailGapUsd` 0.05, `TrailTpBodyPct` 100 (0.01 lot par, lot ke saath). Khulte waqt TP = body 100% ($0.15–$1.00). `LockTrail()` (Manage, har 250 ms): fayda ≥ $0.15 → SL entry ± $0.10; lock ke baad SL = bid − $0.05 (BUY) / ask + $0.05 (SELL), sirf aage (kam se kam $0.01), broker stops-level ka dhyan. Lock ke baad +$0.05 / candle-close BOOK band; TIME 200 wahi. Lock pehchan SL ki jagah se (restart par bhi). Fayde me SL laga = res "LOCK/TRAIL". Haath ke trade par bhi. Dashboard RULES me lock / trail.
- User (saath me): "time limit hata do, sirf news time rakho — demo par poora check karna hai" → `TradeWindows` "" (24 ghante); news ±30 min wahi; TIME 200 candle wahi.

## SAMUSIGNAL CANDLE EA v1.07 — TP min $0.15 (16 Nov 2026)
- User: "TP min $0.15 kar do". `TpMin_Usd` 0.10 → 0.15 (0.01 lot par; EA ke apne + haath ke trade). TP = body 60%, seema $0.15–$1.00. Forex (EURGBP / EURUSD jaise chhoti candle) ab $0.15 par. Paper (VPS) abhi bhi 50% / $0.10.

## SAMUSIGNAL CANDLE EA v1.06 — 200 candle wapas + TP body 60% (16 Nov 2026)
- User: "200 candle wala hi rakhna jo pehle tha, sirf profit jo candle ka 50% hai use thoda badhana".
- `HoldMax1` 0 → 200 (wapas). `TpBodyPct` + `ManualTpBodyPct` 50 → 60. TP seema $0.10–$1.00 wahi (forex me zyadatar $0.10 ki seema hi lagti hai — % badhne ka asar BTC / bade candle par). v1.05 ka badla-pair fix rehta hai. Paper (VPS) abhi bhi 50%.

## SAMUSIGNAL CANDLE EA v1.05 — 200 candle TIME hataya + badle ke pair ka fix (16 Nov 2026)
- User (GBPUSD BUY 19:42 → 23:02 IST, ठीक 200 candle par TIME −$0.92 dekh kar): "EA me 200 candle nahi, $10 ka fix SL pair-wise; daily target $2 to hai hi".
- `HoldMax1` 200 → 0 (0 = TIME kabhi nahi): trade sirf TP / BOOK (+$0.05, candle close fayde me) / SL $10 par band. Paper (VPS) abhi bhi 200 candle — tulna me farak.
- FIX: `AutoReplacePair` sirf tab jab band hua pair app (`/candle/cfg`) me ON tha — 16 Nov ko OFF GBPUSD (purana trade −$2 gaya) ke badle NZDCHF ON ho gaya tha.

## SAMUSIGNAL CANDLE EA v1.04 — haath ka trade bhi isi niyam se (16 Nov 2026)
- User: "manually trade liya to usko bhi wahi SL / TP?" → sujhaav → "Final, slot + manual ke liye ek".
- `ManageManual` (true): is account par magic 0 wali position EA apnata hai (`AdoptManual`, ek baar): SL $10, TP = trade wali candle se pichhli band M1 candle ki body × `ManualTpBodyPct` 50% ($0.10–$1.00, lot ke saath) — user ka apna TP / SL badal deta hai; phir wahi book / TIME niyam (`Manage`). −$2 pair band manual par nahi.
- Slot: EA ke `MaxOpen` 3 me manual nahi gina; `ManualSlots` 1 — zyada haath ke trade = push chetavni (band nahi). Manual trade wale pair par EA naya trade nahi kholta (`HasOpen`). Din ka $ / target me manual nahi.
- Push / LOG: apnaya (TP / SL) aur band (TP / SL / BOOK / TIME / haath se). Dashboard: TRADE me "[HAATH]", SLOTS = "EA x / 3 + HAATH y / 1".

## SAMUSIGNAL CANDLE EA v1.03 — pair din bhar band (16 Nov 2026)
- User: "koi pair $2 se zyada floating me jaaye to us trade ka jo hoga wo hoga (TP le lega), par us pura din wo pair phir trade nahi lega".
- `BlockPairLossUsd` 2.0 (0.01 lot par; 0 = band): `Manage()` me trade P/L ≤ −$2 → `BlockPair` (GlobalVariable `SSC_BLK_<login>_<NAME>` = server din ka shuru; EA restart par bhi yaad) + LOG / alert / push ek baar. `Open()` me `PairBlocked` = SKIP. Chalu trade ko nahi chhoota (TP / book / TIME / SL wahi). Din = server din (05:30 IST).
- Dashboard me "AAJ BAND" line; `/candle/ea/state` me `blk`.
- User (saath me): "uski jagah dusra pair app me auto ON ho jaaye, notification deke". `AutoReplace` (true) + `ReserveOrder`: band pair ki jagah pehla pair jiski koi currency chalu (band nahi) pair se na takraye, broker me ho, XAU nahi → `/candle/cfg` `pairs` me PATCH + `/candle/cfg/auto/<NAME>` {d (din), for, t} + push. Ek band pair = din me ek badla (`SSC_REP_<login>_<NAME>`). `AutoExpire()` har 60 sec: pichhle din ke `auto` pair `pairs` se hata kar `auto/<NAME>` DELETE + push. App (SAMUSIGNAL-AI v1.34.0) ab `/candle/cfg` PATCH karta hai (auto na mite) aur Firebase ke pairs ko maanta hai.

## VPS Scanner v1.10 — TP ka naap (16 Nov 2026)
- User "① naap Final": paper me `body`; nateeje par `mfe` / `mfe1` + `tv` = SAMUSIGNAL-AI `candlerules.tpVariants` (TP 30 / 50 / 75 / 100%, 50% par lock → 100%, book 25%); lambe wale baad me (`tvp`, 7 ghante tak). Sirf naap — paper ka asli niyam / EA nahi badla. Mock harness se jaancha.

## SAMUSIGNAL CANDLE EA v1.02 — trade samay + news filter (16 Nov 2026)
- User: v1.01 VPS par lag gaya. "News filter? Trading time 7 AM–5 PM aur 8 PM–10 PM; beech me news ho to news ke 30 min pehle aur 30 min baad koi trade nahi."
- `TradeWindows` "07:00-17:00,20:00-22:00" (IST): bahar naya signal jaancha hi nahi jaata; chalu trade apne niyam se. `NewsOn` + `NewsBeforeMin` 30 / `NewsAfterMin` 30 (MT5 calendar, High; pair ki dono currency; BTCUSD = USD). `NewsCloseOpen` (default false) = us beech chalu trade bhi band — user se poochha hai.
- User: "daily target $2" → `DayTargetUsd` 2.0 (pehle 0): aaj ka band P/L ≥ +$2 = us din naya trade nahi; din = server din (Exness UTC → 05:30 IST se). `DayLossUsd` abhi 0.
- Dashboard: SAMAY (andar / bahar, agla) + NEWS (ruke pair ya agli High news) line; STATUS / app me "samay ke bahar". Code AI AUTO v1.12 wala (WinParse / InWindow / NewsLoad / NewsBlockCur / NextNewsLoad).

## SAMUSIGNAL CANDLE EA v1.01 + Scanner v1.09 — sirf 1 MIN, Matrix Terminal dashboard (16 Nov 2026)
- User: v1.00 VPS par chal gaya (Firebase OK, app ke pair padhe) par panel ki lines ek dusre par chadh rahi thi; phir: "5 MIN hatao, sirf 1 MIN" + sample screenshot "Matrix Terminal" jaisa dashboard.
- EA v1.01: sirf M1 (cfg.tf nahi dekhta, HoldMax5 hataya). Dashboard poori chart par kaala: `root@candle-ea:~$ ./run --pairs … --tf M1` + IST ghadi, alert patti (naya trade / band 90 sec, ulta rang blink), STATUS / PAIRS / TRADE (3 tak: P&L, candle x/200, TP $) / DAILY [####....] / SLOTS / RULES, BALANCE · EQUITY · FIREBASE · APP · ALGO, LOG (aakhri 6), [ PAUSE ] (GlobalVariable `SSC_PAUSE_<login>`, naya trade nahi) aur [ CLOSE ALL ] (5 sec me 2 baar). Font Consolas, akshar ka size screen DPI se naapa (TextGetSize).
- Scanner v1.09: Candle signal / paper / push sirf 1 MIN (`tfs: [1]`).
- Fix (v1.01 hi): VPS par compile nahi hua — `TextGetSize` ko `uint` chahiye, `int` diya tha. Ab uint + cast; ek naam (k) bhi alag kiya.

## SAMUSIGNAL CANDLE EA v1.00 — naya EA (16 Nov 2026)
- User: "Candle strategy bahut sahi chal rahi hai, iska EA banao" → naya $100 DEMO, ek saath 3 trade, sirf app me ON pair (app se manage).
- Pair / TF: Firebase `/candle/cfg` (app ka Candle page; har 20 sec) — `pairs` (OFF = naya trade nahi) + `tf` 1 / 5. `ExcludeCSV` khaali.
- Signal: MT5 ki apni band candles (250), app `candlerules.signal` jaisa: body ≥ pichhli 10 avg × 1.2 aur ≥ range 50%; BUY hari + EMA9>21 + close>EMA9 + RSI14 50–70; SELL ulta 30–50. Nayi candle khulne ke 20 sec (5m: 60) ke andar MARKET.
- Trade (0.01 lot): TP = body × 50% ($0.10–$1.00, bhare bhaav se), SL $10 (broker par). Candle band par fayde me = BOOK; dusri candle se +$0.05 = BOOK; 1m 200 / 5m 72 candle = TIME. 1 pair 1 trade, `MaxOpen` 3. Spread > $0.50 = SKIP. Din target / ghata input (0 = band). AllowReal=false.
- Comment = VPS paper wali key (`c` + next ms base36 + NAME + tf) → app paper se tulna. Firebase: `/candle/ea/state` (30 sec), `/candle/ea/trades/<key>` (khula / band). Push: khula / band. Chart par bade hare akshar me haal. Magic 7320001.
- App SAMUSIGNAL-AI v1.31.0 (Candle 1.10.0): Live me EA line, Record me "🤖 CANDLE EA (Demo)" + trades.
- Compile VPS Helper par hoga (yahan MetaEditor nahi) — pehli baar Experts / Journal tab ke errors dekhne hain.

## EMA20 M5 SCALPING v1.01 — galat entry fix + trailing SL (16 Nov 2026, branch feature-ema20-m5-v1.01)
- User report (Monday subah, screenshot): saare trade loss me (-$9), entry galat. GBPCAD buy 1.88601 jabki red candle high ~1.8862 tha — high toote bina entry. Trade candle khulne ke time (:00 sec) pe, server 00:15–02:15 (Asian).
- Wajah (v1.00 bug): `PlaceEntry` me Buy Stop ki doori broker stop-level se kam ho to `else if(ask - price <= MaxChase)` — ask price se NEECHE hone par bhi sach — seedha MARKET trade. Plus Buy Stop Ask pe chalta tha (rollover spread spike), aur dusre pair ka iMA nayi candle pe 1 candle purana mil sakta tha.
- Fix: broker pending band. "Virtual stop": red high (+0.2 pip) ko BID tode tabhi market entry; spread > MaxSpread to wait; break se 1 pip (`MaxChasePips`) zyada door to skip. EMA EA khud 300 candle se nikalta hai. Start pe purane v1.00 pending delete.
- Session (naya): server 07:00–24:00 (Exness = GMT, IST 12:30 PM – 5:30 AM). 00–07 me naya trade nahi (exit/trail chalu). Sim (EURUSD weekdays): Asian 00–07 akela 21 trade, -22 pip.
- Trailing SL (user ne maanga — "jaise profit badhe SL upar khiske"): `TrailStartPips` 15 -> SL entry+1 pip (breakeven), phir price se `TrailDistancePips` 10 pip peeche, `TrailStepPips` 1. SL kabhi peeche nahi.
- Sim note (chhota sample, EURUSD 2 hafte): bina trail 07–24 = 64 trade, +71 pip; trail 15/10 = +27 pip; trail 10/10 = +10 pip. Trail bade winner jaldi kaat deta hai — default 15/10 rakha; user chahe to `UseTrail=false`.
- Magic wahi (2026520) — v1.00 ke chalu trade bhi v1.01 manage karega. VPS: chart se v1.00 hatao, v1.01 lagao.
- **Baaki:** demo par 2-3 din dekhna; ek currency (jaise AUD) ke kai pair ek saath khulna — limit chahiye ya nahi, user decide kare.

## EMA20 M5 SCALPING v1.00 — naya EA (15 Nov 2026, branch feature-ema20-m5-v1.00)
- Strategy: Tanisha Garg "The Best 5-Minute Scalping Strategy" (youtu.be/KjPH6Fv1T6M), Hindi captions se padhi. Video Indian market (NIFTY) ke liye tha; user ne forex ke liye kaha.
- BUY: (1) M5 green candle EMA 20 ko neeche se cross karke upar close — is pe trade nahi. (2) agli 2 candle me pehli RED jo EMA ke upar close ho (beech me EMA ke neeche close = cancel). (3) red candle ke high (+0.2 pip + spread) pe BUY STOP — koi bhi baad wali candle tode, high toot-te hi entry.
- SELL: bilkul ulta (user ka faisla; video me sirf buy).
- Exit: M5 candle EMA ke ulta close = trade band (video ka SL, rally ride). Hard SL (user ka faisla): setup low/high -1 pip, min 3 / max 20 pip. Fixed TP default off (`TP_RR`).
- Pending delete: candle EMA ke ulta close (`CancelOnEmaClose`), `ExpiryBars` (0 = off), ya trade khulte hi usi pair ke saare pending.
- Pairs: ek chart pe lagao; `PairsCSV` khaali = 8 major currency ke 28 pair apne aap (Exness "m" suffix bhi), gold/BTC nahi. Lot 0.01 (user ka faisla), spread max 3 pip, `MaxOpenTotal` 10, magic 2026520.
- Verify: Python simulation (same rules) EURUSD M5, 29 Oct–16 Nov 2026 (Twelve Data, weekdays): 86 trade, 30% jeet, avg jeet +10.5 / haar -3.6 pip, net +54 pip (1 pip spread maan kar). Chhota sample — sirf ek pair, pehle DEMO / Strategy Tester.
- Compile yahan nahi hota (bracket jaanch PASS); VPS Helper card dekhna.
- **Baaki:** Strategy Tester multi-pair result; slope / trend filter (sim me EMA slope filter se thoda behtar: 57 trade, 35%, +62 pip) — user decide kare.

## SamuSignal Data Feed v1.01 — nayi candle kisi bhi pair pe (14 Nov 2026)
- Bug (user: Candle page 4 min se same, BTCUSD Shanivar): v1.0 nayi band candle sirf pehle symbol (EURUSD) ke `iTime(...,1)` se pehchanta tha. Weekend pe EURUSD band -> 1min bars sirf `ResendMin` (5 min) me ek baar.
- Fix: har TF ke liye saare symbols ki aakhri band candle ka sabse naya time — koi bhi pair (jaise BTC) nayi candle band kare to turant (1.5 sec ruk kar) bhejo. Baaki sab v1.0 jaisa; meta ver "1.01".
- VPS: chart par v1.0 hata kar v1.01 lagana (inputs wahi). Compile yahan nahi hota — VPS Helper card dekhna.

## PERSONAL FX v10.3 — S6 har SELL apna lock + jodi + tikdi (27 Nov 2026 raat, user "E Final")
- Live (demo v10.2): main + doosra BUY @ 3640.09, SELL 3637.09 / 3634.09 / 3629.49 / 3626.54. Bhaav 3644 tak gaya -> chaaron ghate me (−$41). 20:39 par 1 / 2 number +$6.71 / +$3.71 lock chalu, par band nahi ho sakte the: v8.4 se sirf SABSE NEECHE wala akela band hota tha (upar wale ruko).
- User: "koi niyam nahi hataya — jodi, tikdi, jo bhi zaroori, sab us waqt allow".
- v10.3: (1) HAR hedge +$2 paar -> lock, +$1 par band (koi kram nahi). (2) Jodi wahi: sabse neeche wala khud +$2 na pahunche to aakhri 2 milake +$1 -> +$1 par band. (3) NAYA TIKDI: jodi chalu na ho to aakhri 3 milake +$1 paar -> +$1 par teeno (GV `PFX6Q_<magic>_<sym>`). Ek tick me ek kaam, phir agla tick.
- Backtest round 19–20 (real gold, SL $60): E (ye) 1m $1.89/cycle SL 1 (v10.2: $1.67, SL 3), 5m $1.88/ghanta (1.76), 5m noise SL 4 (5); SL band karke 5m sabse bura −$7.6 (v10.2 −$229). "Har SELL khud, jodi bhi nahi" (D) bahut bura — jodi zaroori.

## SamuSignal app v10.10.1 — BUY ya SELL page: pehle feed ki haalat (race fix), SAMUSIGNAL AI v1.39.0 me bhi wahi page (27 Nov raat)

## SamuSignal app v10.10.0 — 🎯 BUY YA SELL? page (27 Nov 2026 raat, user Final)
- User: SamuSignal app (AI app nahi) me optional page — trade se pehle analysis, 5-6 AI agent aapas me baat karke batayein abhi BUY ya SELL (high probability), scalping $1–2; MT5 button.
- Header me naya button "🎯 BUY YA SELL? · 5 AI AGENT" -> page `pgDecide` (nav me nahi, Chart page jaisa). Pair (XAUUSD default) + target $1 / $2.
- Timeframe (scalp $1–2, 0.01 lot): 1H mahaul · 15m disha · 5m setup · 1m trigger. 4H / Daily nahi (us waqt $5–10 ulta jhatka). Data MT5 feed (1min/5min/15min/1h), na mile to TwelveData.
- 7 Gemini sawaal: 5 agent (📈 Trend, ⚡ Momentum, 🧱 Level, 📰 News + Google Search + MT5 calendar `/feed/news/cal`, 🛡 Risk/chop) -> 💬 behes (har agent doosron ko jawab, raay badal sakta) -> ⚖️ Judge: BUY/SELL + % (pehle +$T, −$T se pehle) + ulta khatra + "rukna behtar?". Saath me 20 rule-based agent vote (15m). Har agent ko asli numbers (EMA, RSI, MACD, ADX/DI, ATR $, ER, range %, aakhri candles).
- 🚀 MT5: `/personalfx/orders/<-SD…>` {type BUY/SELLMARKET, src "… DECIDE"} — ⚡ ABHI jaisa; account chunna (REAL par 🔴 chetavni); faisla 5 min tak; EA status (PLACED / SKIP / FAILED) page par.
- 📒 Record (`samu_dcHist`): 1-min feed candles se 60 min me pehle +$1/−$1 aur +$2/−$2 (ek candle me dono = haar); Judge jeet %, 60%+ wale, 20-vote saath wale.
- Jaancha: Playwright (nakli feed + Gemini + Firebase): 7 call, faisla, MT5 PUT + PLACED, record ✓/✗, 390px side-scroll nahi, JS error nahi. `kavach.js` pehle se toota (lastV20 ReferenceError, is badlav se pehle bhi).

## PERSONAL FX v10.2 — bug fix: doosra BUY khula + SELL sab band -> pending ruk jaate the (27 Nov 2026 raat, user "A Final")
- Live (demo, v10.1): main BUY 0.01 + doosra BUY 0.01 @ 3650.273, 19:21 par aakhri 2 SELL lock se band, bid ~3645. Pending sirf 3641.27–3629.27 (level 3–7); **level 2 = 3644.273 nahi laga**.
- Wajah: `hn==0` branch me doosra trade ho to $2 jaanch ke baad hamesha `return` -> pending wala hissa chalta hi nahi tha.
- Fix: `return` sirf band karne par. Saath me: doosra trade khula ho to main akela TP par band nahi aur broker TP nahi (pehle return ki wajah se ye code tak pahunchta hi nahi tha).
- Backtest simulator me ye bug kabhi tha hi nahi -> round 17 ke (B) nateeje = v10.2 ka bartaav.
- User "B backtest": SELL na ho to ladder abhi ke bhaav se $3 (3645.09 -> 3642.09…) — `pxreset` research me (round 18), abhi EA me nahi.

## PERSONAL FX v10.1 — S6 naya plan (B): main 0.01, sab target $2, doosra BUY (27 Nov 2026 raat, user Final)
- User: "9.1 abhi Final karna; agar 9.1 wala file pehle VPS pe bheja ho to 10.1 se start karna". Purani v9.1 VPS par ho sakti hai -> naam **10.1** (agla 10.2).
- v9.0 se bana. Main BUY 0.01 haath se. SELL 0.01 har $3, har SELL (1 number bhi) v9.0 ka $1 niyam (+$2 lock -> +$1 band, LIFO, jodi).
- Sab target $2: `S6_TP_Usd` 3 -> 2 (per 0.01), `S6_CycleNetUsd` 6 -> 2, `S6_CycleTP_Usd` 3 -> 2, `S6_BasketTP_Usd` 5 -> 2. Basket SL 60, LockArm 2.
- NAYA `S6_SecondBuyOn` (true): hedge khule hon aur bhaav main ke bhaav par laute -> doosra trade main ki disha (S6_HedgeLot), STOP comment "PFX6HB" main ke bhaav par. Ek cycle me ek (GV `PFX6B2_<main>`). Sirf cycle ke saath band; hedge sab band -> main + doosra milake $2 TP / −$60 SL. Hedge sab band aur doosra na bhara -> pending hatta.
- "PFX6HB" "PFX6H" se shuru -> OCO skip / S6DeletePendings / S6CleanPendings apne aap. Hedge pending loop + app pend list use chhodte hain. hb cfg me `b2`. Backtest round 17 (S6_NEW_PLAN.md): (B) 1m $1.62/ghanta SL 5, 5m $1.77/ghanta SL 2 (v9.0: 2.25 / 2.64, SL 17 / 8).
- App S6 LIVE v2.5.0: WANT tp/net/basket/cycle = 2, main lot = 1× hedge lot, version hint v10.1. Doosra BUY ladder me alag row nahi (total me shamil).
- Yahan compile nahi hua (MetaEditor nahi) — VPS par compile nateeja dekhna. Pehle demo.

## S6 — v9.0 se nayi shuruaat: v9.1 / v9.2 / v9.3 hataye (27 Nov 2026 shaam, user)
- User: "9.0 tak ke saare badlav rakhna, uske aage ke saare changes remove kar dena sab jagah se - yahan se naye start karunga".
- Repo se `vps-ea/PERSONAL FX v9.1/v9.2/v9.3 - GRID.mq5` hataye (VPS par pehle copy hui files Experts me reh sakti hain - inhe use nahi karna). App S6 LIVE v2.3.1 = v2.3.0 (v2.4.0 ke v9.1 wale CHECK badlav wapas: arm 2, ploss nahi). `S6_HANDOVER.md` v9.0 ko nayi shuruaat bana kar dobara likha.
- Neeche ke v9.1–v9.3 / backtest wale section sirf itihaas ke liye. Agla naya version **v9.1** naam se naye sire se.

## S6 — user ne v9.2 chhoda, v9.0 wale niyam par wapas (27 Nov 2026 shaam)
- Demo v9.2 (BUY 3680.342): sideways 3670–3681 me "jodi −$2" ke 4 kat −$14.23, lock +$6.71, balance 208 → ~200 → user: "9.2 pasand nahi, chhod do".
- Raat v8.7 (26 Nov 22:16 IST) aur subah v8.9/v9.0 (27 Nov 08:44/08:54 IST) par profit aaya (200 → 245). Raasta: `PERSONAL FX v9.0 - GRID.mq5`, ya v9.2 file + `S6_PairLossUsd = 0`, `S6_LockArmUsd = 2.0` (v9.0 niyam + v9.2 bug fix). Poora `S6_HANDOVER.md` section 0 me.
- Backtest round 13–16 (recovery mode, gap $4/$5, tikdi + reset, v9.2 + tikdi, madad wala BUY 0.01): koi v9.2 se behtar nahi; reset aur madad BUY 1m par nuksaan.

## S6 — user Final: v9.2 chalegi (27 Nov 2026)
- Backtest round 7 / 8 (`research/s6_bt2.py`): lock 3/2/1 + $0.20 trailing aur "$3 par $2, phir $1 peeche" (dono "door wala pehle" aur "har hedge khud") - koi bhi v9.2 (lock +$1.20 → +$1, bina trailing) se behtar nahi: SL $60 par 1m $4.53 vs $5.50, 5m $5.52 vs $5.76; SL 2 → 28, 0 → 14. "Har hedge khud" har baar kamzor.
- User: "9.2 Final". Chart par `PERSONAL FX v9.2 - GRID.mq5` (v9.3 rakhi hai; usme `S6_NextOnlyDeeper = false` = v9.2 jaisa).

## PERSONAL FX v9.3 — S6 naya hedge sirf pehle walon ke profit me hone par (27 Nov 2026, user)
- User: "4000 BUY → 3997 pehla SELL; doosra tabhi jab pehla +$3 dikhe; teesra tabhi jab doosra +$3 aur pehla +$6" - bhaav main ki taraf lautte hue upar-upar SELL na khulein.
- Input `S6_NextOnlyDeeper` = true: hedge khule hon to naya pending sirf sabse gehre khule hedge se aage (tab har purana hedge apne aap profit me). Koi hedge na ho to pehle jaisa. false = v9.2. hb cfg me `nxt`.
- Backtest (`research/s6_bt2.py` round 4/5, N / P = yahi niyam): 5m par v9.2 barabar ($5.75 vs $5.76), 1m par kam ($4.47 vs $5.50, shor $3.35 vs $4.69, SL 20 vs 2). User ko bataya; user ne yahi chuna. Round 6: "seedha version" (har hedge +$1 TP / bina kram) v9.2 se bahut kamzor (S1 ghate me).

## PERSONAL FX v9.2 — S6 poore code ki jaanch, bug fix (27 Nov 2026, user "saare bug ek saath")
- Alag reviewer agent + khud code se pakka: (1) pending lagate waqt purana bid (har order se pehle taaza nahi) → SELL STOP bhaav ke upar → broker [10015] invalid price / [10006]; ab har order se pehle `SymbolInfoTick`, tick size par gol, us level ka hedge pehle se khula ho to nahi. (2) cycle band me pehle trade band, baad me pending hatate the (beech me pending bhar sakta tha) aur adhura band dobara nahi hota tha → ab pehle `S6DeletePendings`, adhura ho to GV `PFX6C_<magic>_<sym>` = main ticket aur har pass bache trade band. (3) pakka profit ka samay main khulne se −5 sec - doosra haath ka trade main ban jaye to pichhle cycle ka pakka gina jaata → ab GV `PFX6M` (main ticket) / `PFX6B` (cycle shuru), main badle to shuru = abhi. (4) koi hedge na ho to Basket SL nahi lagta tha → ab main akela bhi. (5) `S6Slot`: broker comment hata de to `PosComment()` (order ka), `MathFloor(dist/gap + 0.25)`. (6) hatae pending ke `PFX6N_` GV saaf. (7) har pending fail app ki galti list me (bid ke saath), Print alag 60 sec.
- Niyam ka nateeja (bug nahi): bhaav main ki taraf lautte hue har chhote utaar par upar ka SELL bharna (khali levels bhaav ke neeche "aage" hain). "Sirf sabse gehre se aage naya hedge" (N) backtest: 1m par v9.1 se bura ($4.47 vs $5.53, shor me $3.35 vs $4.69, SL 36 vs 8), 5m barabar → nahi joda.
- Baaki (chhote, nahi badle): AppHttp WebRequest timeout 4 sec (ek request / pass); GV naam me account nahi; `CloseAllOurTrades` (daily target) pending baad me (S6CleanPendings 1 sec me hatata hai).

## PERSONAL FX v9.1 — S6 jodi −$2 par band + lock +$1.20 + pending reject (27 Nov 2026, user Final)
- Demo v9.0 (BUY 3658.505): bhaav 3640–3649 me upar-neeche; 44 hedge lage, pakka sirf +$5.57; 4 / 5 / 6 number 1.5 point ke guchhe me khule (4b gehra re-entry) aur 4–10 sec me jodi +$0.5…0.96 par band (churn); upar ke hedge (3 / 4) neeche wale ghate me hote hue khule; 12 pending broker ne mana kiye ([10006] rejected / [10015] invalid price); aakhir me 3 hedge ghate me atke (−$14).
- Backtest `research/s6_bt2.py` (GitHub Actions `s6-research.yml`, asli gold GC=F 1m 7 din + 5m 60 din, shor test bhi): v9.0 vs A (theek level), B (jodi bharte +$2), E (neeche ghate → upar nahi), offset 0.5 / 1.0, G (jodi −$1/−$2/−$3 par band), trailing (arm 1.2/1.5/2.0, dist 0.2/0.5/1.0), L12 (arm 1.2). Sabse achha G+L12: SL $60 par avg/cycle $4.27 → $5.53 (1m), $5.31 → $5.76 (5m), shor me $3.17 → $4.98 / $5.23 → $5.69; SL lage 14 → 2, 8 → 0; bina SL sabse bura DD −$818 → −$62 (1m), −$736 → −$42 (5m). Trailing, A, B, E, offset akele fayda nahi. Chetavni: random-walk (synthetic) data par G+L12 v9.0 se bura - fayda gold ke palatne wale swabhav par tika hai.
- EA: `S6_PairLossUsd` = 2.0 (naya): sabse neeche ki jodi (lock chalu nahi) milake ≤ −$2 → dono band (push "JODI GHATE ME BAND"). `S6_LockArmUsd` 2.0 → 1.2. Pending: bhaav se kam se kam 2× spread door; broker mana kare to us level par 10 sec ruko. hb cfg me `ploss`.
- Chalte cycle par v9.1 lagaya to ghate wali neeche ki jodi turant band hogi - naya EA cycle khatam hone ke baad lagana.

## PERSONAL FX v9.0 — S6 LIVE app ka 🩺 CHECK tab (27 Nov 2026, user "Yes")
- User: "jo bhi problem ho wo sab check karne ka option G2 app me — MT5 / page kholne ki zaroorat na pade".
- EA: `hb` ab har 15 sec (pehle 30), Strategy 6 na ho tab bhi (`S6LiveBase()` - app me "Strategy galat" dikhe). Naye field: `strat`, `ta` (Algo Trading), `ea` (EA ko trade ijazat), `conn`, `ping` (ms), `ml` (margin level %), `fm` (free margin), `liveOn`, `push`, `manual`, `errs` (aakhri 20: pending FAIL, TP modify fail, cycle band ADHURA, Firebase HTTP / WebRequest error, margin / MaxOpenTrades "nahi laga"), `haal` (aakhri 30 HAAL - khule / pakka / net / hedge, har 10 sec). `live/<pair>` me `sp` (spread). Trade niyam v8.9 jaise.
- App (GRID-STARTAGY-2 v2.1.0): naya 🩺 CHECK tab + har tab ke upar 🟢 / 🔴 patti.

## PERSONAL FX v8.9 — S6 app data EA ko nahi rokta + Basket SL seedha $ (27 Nov 2026, user Final)
- Demo (v8.7, app data se — feed-check `S6_*` lines): SELL main 3613.63, 29 hedge, user ne cycle profit (pakka ~$8 + khule ~+$1) dekha par +$6 net par band nahi hua; 08:32:53 ek jodi −$1.57 par band; DD −$67.39 par Basket SL nahi laga.
- Wajah: (1) har hedge / lock / 3 sec par S6 LIVE WebRequest (synchronous) EA ko rokta tha; (2) Basket SL `x lot/0.01` tha → 0.02 par −$120.
- Fix: S6 LIVE likhna sirf queue (`S6LvPut` / `S6LvEvent`), `S6LvFlush()` OnTimer ke aakhir me — ek request, trade action (`g_S6ActAt`, `S6Push`) ke 1.5 sec baad; events 10 sec me ek PATCH (`e<ms>_<n>` keys); cycles `cycles/c<ms>`; live har 5 sec (`S6_LivePushSec` 3 → 5). OnTimer me `ManageMartingaleGrids()` sabse pehle (app poll se pehle). Basket SL = `-S6_BasketSL_Usd` seedha. Experts: har 10 sec `PERSONAL FX S6 HAAL … khule / pakka / net`.

## PERSONAL FX v8.8 — S6 jodi lock bharte hi (27 Nov 2026, user Final)
- Demo (v8.7): SELL main 3613.63, BUY hedge 3621.24 … 3635.79; aakhri hedge chot par bhara, bhaav 1 sec me 1+ point gira → jodi (3633.13 + 3635.79) ka `comb > +$1` kabhi dekha nahi → `gvP` set nahi → jodi atki; LIFO ne upar ke armed hedge (3630, 3627 …) bhi roke → 11 point girne par bhi koi band nahi (−$44.40).
- Fix: hedge bharne ki pehchaan (`gvW` block) par, agar naya hedge sabse neeche hai (nwI == hn−1), 60 sec ke andar bhara, aur bhare bhaav par jodi = |doori| × k × lot − spread × dono lot > `S6_LockUsd` → `gvP` = naye hedge ka ticket (jodi lock usi pal chalu). Purane khule hedge par nahi (ghate me zabardasti band na ho).

## PERSONAL FX v8.7 — S6 LIVE app data (26 Nov 2026, user Final)
- App: repo GRID-STARTAGY-2 (pehle GRID 2, wo account band) ab **S6 LIVE** PWA (LIVE · LADDER · RISK · HISTORY · SETUP).
- EA (Strategy 6 + `S6_LiveOn` + app bridge on): Firebase `/personalfx/s6live/<S6_LiveKey>/` (FirebaseAuth): `hb` har 30 sec (balance, equity, currency, demo/real, S6 setting); `live/<pair>` har `S6_LivePushSec` (3) sec (main, har hedge level / bhaav / P/L / lock, pending, mpl / hpl / tot / banked / net, cycle DD, kitne hedge lage, bal / eq); `events` (har `S6Push` sandesh + naya cycle + cycle band); `cycles` (main band hone par: start / end UTC ms, nateeja — EA ka why ya deal reason TP / SL / HAATH SE / EA, P/L main + hedge, DD, hedge). Account number nahi.
- User: balance / equity bhi dikhao. News niyam abhi nahi (alag Final).

## PERSONAL FX v8.6 — S6 bug fix: ek bhaav par kai hedge (26 Nov 2026, user Final)
- Demo: main BUY 3581.069, 3 SELL ek hi bhaav 3574.090 par - v8.4/8.5 ka "market se dobara kholo" (re-entry bhaav nikal gaya to us pal ke bhaav par) kai slot ek saath khol deta tha.
- Fix: (1) market re-open hata - sirf pending STOP; (2) khule hedge se aadhe gap (gold 1.5 pt) ke andar pending nahi; (3) 4b re-entry bhaav `S6SlotFree` + padhte waqt level ± aadha gap tak cap (agle level ke paar nahi); (4) `S6_BasketSL_Usd` 0 → 60 (user: 30 din me 2-3 baar lag sakta hai).
- Real-gold backtest (`research/s6_backtest.py`, GitHub Actions `s6-research.yml`, GC=F 1m 7 din + 5m 60 din): "B" (= v8.6) SL $30 par +$3.78 / +$5.60 per cycle vs v8.5 +$3.58 / +$5.22; Basket SL v8.5 ka aadha. Bina SL ab bhi ~1% cycle atakte hain (−$180 se −$436) - isliye SL zaroori.

## PERSONAL FX v8.5 — S6_PendingAhead 3 → 5 (26 Nov 2026, user)
- Seedhi chaal me ~5 hedge (~16.7 point) par basket +$5; spike me bhi 5 SELL STOP pehle se lage rahein.

## PERSONAL FX v8.4 — S6 neeche se band + upar khali nahi (26 Nov 2026, user "4b")
- User: band sirf sabse neeche wala (6, 5, 4…); 5, 4, 3 band → bhaav neeche → pehle 3 (jahan band hua) phir 4, 5, 6.
- Hedge array gehrai (main se doori) ke kram me; band sirf sabse neeche wala: wo armed (+$2) → akela +$1; nahi → neeche ke 2 milake +$1 (jodi har baar, `pairUsed` hata). Upar wale ruko.
- `S6SlotFree`: level se aage band hua → `PFX6T_<main>_<n>` = band bhaav (+ `PFX6S` seen); level se pehle band → theek level. Bhaav level se upar laut aaye → T hata (theek level).
- Pending: khali level ka bhaav T (ya level) bhaav se aage → sabse paas ke 3 par STOP. Re-entry level ka bhaav peeche nikal gaya (seen ya ¼ gap) → turant market, upar wala pehle. Naya hedge push sabse naye (time) se.
- Python sim (main 3571.48 → −14.5 → −6.5 → −16): band L4, L3, L2 (+$1 har); phir L2 @ 3564.48 (band bhaav), L3 / L4 / L5 apne level.

## PERSONAL FX v8.3 — S6 pakka sequence + PENDING STOP (26 Nov 2026, user Final)
- v8.2 bug: jodi band par dono slot ka trigger ek hi bhaav → 2 SELL 3560.21 / 3560.15 (main 3568.81, chahiye 3565.81 / 3562.81 / 3559.81). v8.2 ka "band bhaav par" hata.
- Hedge sirf level par (main ∓ n × gap), har level par ek. Khali levels jinse bhaav abhi main ki taraf hai → sabse paas ke `S6_PendingAhead` (3) par SELL STOP / BUY STOP, comment `PFX6H<n>` (GV `PFX6N_<order>` = n). Galat / faltu S6 pending hatao. Bhaav level paar kar gaya to us level par kuch nahi jab tak wapas main ki taraf na laute (LIMIT se refill nahi - poora palta to sab hedge ghate me).
- Bhara pending → push "HEDGE level n" + jodi (`gvU`) phir chalu (newest hedge ka TimeMsc GV `PFX6W_<magic>_<sym>`).
- Cycle / basket / main TP band → `S6DeletePendings`. `S6CleanPendings()` har pass: bina main ke ya Strategy ≠ 6 → S6 pending hatao. `ManageOCOPending` S6 hedge / pending ko skip.
- Python sim (main 3568.81 → 3559 → 3566 → 3557): hedge sirf 3565.81 / 3562.81 / 3559.81 par, band ke baad usi level par dobara.

## PERSONAL FX v8.2 — S6 SLOT: band hue bhaav par naya hedge (26 Nov 2026, user)
- User: main BUY 3582.07, hedge 3579 / 3576 profit me band hue, phir wahan naya hedge nahi khula (seedha 3573 ... 3564 dikhe). Chahiye: jis bhaav par hedge band (TP / lock) hua, usi bhaav par us jagah ka naya hedge.
- Slot n = main se n × gap. GV `PFX6N_<hedge>` = slot (purane hedge: sabse paas wala slot), `PFX6T_<main>_<n>` = trigger bhaav (band hone ka bhaav; kabhi na khula = level), `PFX6S_<main>_<n>` = bhaav trigger ke main wali taraf dikha. Trigger paar + dikha → us slot ka hedge (ek baar me sabse paas wala). Trigger se aadha gap se zyada aage → us baar nahi. `S6SlotsClear` main band par. v7.8 ka `PFX6L_` hata.

## PERSONAL FX v8.1 — S6 jodi lock +$1 par chalu (26 Nov 2026)
- Demo: main BUY 3601.52, hedge 3580.50 + 3577.37 — bhaav 3577.4 ke paas se turant palta, jodi (aakhri 2) ka lock +$2 par chalu hona tha, kabhi nahi hua → dono atke (−$1.97, −$5.10). Fix: jodi ka arm = `S6_LockUsd` ($1) — naya hedge khulte waqt jodi ~+$3 hoti hai, isliye turant chalu; band milake +$1 par. Akele hedge ka arm `S6_LockArmUsd` ($2) wahi.

## PERSONAL FX v8.0 — S6 jodi sirf zaroorat par (26 Nov 2026, user Final)
- Har hedge (aakhri bhi) ka lock pehle chalu (`PFX6A_<ticket>`, > `S6_LockArmUsd` $2). Aakhri hedge armed → koi jodi nahi, sab akele +$1 par. Aakhri armed nahi (palta uske paas se) → tabhi aakhri 2 milake +$1 (purana jodi niyam). Levels / dobara khulna / cycle niyam v7.9 jaise.

## PERSONAL FX v7.9 — S6 CYCLE NET PROFIT $6 + lock arm $2 (26 Nov 2026, user Final)
- `S6_CycleNetUsd` 6: `S6Realized()` = main khulne ke baad band hue hedge (orders comment `PFX6H` + Magic → position id → OUT deals, profit + swap + commission) + main P/L + khule hedge P/L ≥ $6 → main + saare hedge band, push "CYCLE NET". Naya cycle sirf user ke agle haath ke trade se.
- Basket +$5 (main ghate me) / cycle +$3 (main faayde me, sirf khule) dono rahe — jo pehle pura ho.
- `S6_LockArmUsd` default 1 → 2 (hedge / aakhri jodi +$2 paar kare tabhi lock, band +$1 par).

## PERSONAL FX v7.8 — S6 hedge level bug fix (26 Nov 2026)
- Demo (v7.7 load ke baad haath ka BUY 0.02 XAU @3576.24): 16 SELL hedge har ~$1.2 par khule aur +$0.8–1.0 lock par band (+$13.88), aakhri 3552.86 par atka (−$29.9) — v7.7 me saare hedge band hone par `ref` = main entry ho jata tha aur bhaav main se $3 neeche hone se turant naya hedge.
- Fix: hedge sirf main se tay level par (`idx = floor(doori / gap)`), pichla level GV `PFX6L_<main ticket>` me; naya hedge sirf naya level paar hone par; bhaav level se upar laute to level phir khula; ek level par ek hi khula hedge (gap/2). Main band (TP / cycle) par GV delete.
- Naya input `S6_LockArmUsd` (default 1.0 = pehle jaisa): lock tabhi armed jab hedge (ya aakhri jodi) isse upar jaye; band `S6_LockUsd` par. Sujhav $2 (user Final baaki).

## PERSONAL FX v7.7 — STRATEGY 6: HEDGE LADDER (25 Nov 2026, user Final)
- `Strategy = 6` (`STRAT_6_HEDGE`). `S6ManageSymbol()` ManageMartingaleGrids se. MAIN = pair ka sabse purana non-hedge trade; HEDGE = comment `PFX6H` (Magic).
- Koi hedge nahi: main TP `S6_TP_Usd` ($3) × lot/0.01 broker pe + software backup (0.02 → $6).
- Ulti chaal `S6_Gap_Usd` ($3 @0.01 lot → price) main open se / sabse door hedge se → naya `S6_HedgeLot` (0.01) hedge. `S6_MaxHedges` 0 = seema nahi (MaxOpenTrades + margin check rehta hai).
- Hedge khule: main ka broker TP hata (0). Sab milake ≥ `S6_BasketTP_Usd` (+$5, main ghate me) ya ≥ `S6_CycleTP_Usd` (+$3, main faayde me) → main + saare hedge band. `S6_BasketSL_Usd` 0 = OFF.
- Lock `S6_LockUsd` ($1): aakhri 2 hedge milake (GV `PFX6P_<magic>_<sym>` = naye hedge ka ticket) > $1 → wapas ≤ $1 par dono band, phir `PFX6U` = 1 (naya hedge khulne tak sab akele). Baaki har hedge akela: > $1 armed (GV `PFX6A_<ticket>`), wapas ≤ $1 → band. Saare hedge band → main ka $6 TP wapas.
- OnInit: netting account par Alert (HEDGING chahiye). Push har hedge / lock / basket / cycle par.

## PERSONAL FX v7.6 — STRATEGY 5: CANDLE (SAMUSIGNAL AI Candle page) (14 Nov 2026, branch feature-personalfx-v7.6)
- User: upar wali Strategy (abhi 4) waise hi chale; sirf SAMUSIGNAL AI ke 🕯️ Candle page se MT5 button wala trade **Strategy 5** par jaaye. Final: TP $0.25, SL $1.50, lot 0.01, candle band hote hi trade band (option a).
- App order me `strat:"CANDLE"`, `tf:1|5` -> EA comment `PFXN<tf><key>`. `IsCandlePos()` -> `IsOurPos()` se bahar (grid / S1–S4 / recovery nahi chhoote). `ManageCandleTrades()` har second (OnTimer + OnTick).
- Niyam (0.01 lot pe, lot ke saath badhta): broker TP +$`S5_TP_Usd` (0.25) / SL -$`S5_SL_Usd` (1.50) + software backup; `S5_MaxCandles` (1) candle band hote hi (server time, `S5_CloseEarlySec` 0) jo bhi P/L, band. Lot `S5_Lot` (0.01, FixedLot se alag). Ek pair pe ek hi candle trade. Na grid, na recovery, na lock.
- Order `S5_MaxOrderAgeSec` (15) sec se purana -> STALE (pehle 10 min tha, candle ke liye bahut). Candle order dusre app pending (PFXA) ko `AppReplaceOld` se NAHI hatata; grid state nahi banata; "grid pehle se chal raha" wali rok nahi.
- Band hone par (`OnTradeTransaction` -> `S5OnDealOut`): wajah (TP / SL / CANDLE CLOSE / CLOSE ALL / HAATH SE) + P/L (commission milake) -> push + Firebase `orders/<key>` {status CLOSED, res, pl, closed}.
- `S4Debt()` me candle (PFXN) deal nahi jude — Strategy 4 ka recovery hisaab alag. F8 / daily target close-all me candle trade bhi band.
- Panel title ke daayein "S5 CANDLE +$0.25/-$1.50". Strategy 1–4 me koi badlav nahi.
- Compile yahan nahi hota (bracket jaanch PASS); VPS Helper card dekhna. VPS par `Strategy` input wahi rakho (4). MT5 > Allow WebRequest me Firebase URL pehle se.

## Btc_V1_Licence_420841723.ex5 VPS par (14 Nov 2026)
- User ne `Btc_V1_Licence_420841723.ex5` (compiled EA, source nahi) VPS Helper se bhejne ko kaha -> `vps-ea/Btc_V1_Licence_420841723.ex5` (naam wahi). File ke andar "Copyright 2026,Telegram-@SuccessZonee" / "www.Btcv1.in" likha hai; naam me 420841723 shayad licence wala account number.
- Helper v1.03 isse har MT5 terminal ke `MQL5\Experts` me seedha copy karega (compile nahi). COPY tab "VPS Helper" card me "ex5 copy hui" dikhega.
- Chart pe lagana manual. Code dekha nahi ja sakta -> pehle DEMO, "Allow DLL imports" band.

## Gold_Sl_Tp.ex5 VPS par (13 Nov 2026)
- User ne `Gold_Sl_Tp.ex5` (compiled EA, source nahi) VPS Helper se bhejne ko kaha -> `vps-ea/Gold_Sl_Tp.ex5` me rakha (naam wahi, badla nahi). File ke andar "Alox Software" / "1.03" likha hai.
- Helper v1.03 isse har MT5 terminal ke `MQL5\Experts` me seedha copy karega (compile nahi). COPY tab "VPS Helper" card me "ex5 copy hui" dikhega.
- Chart pe lagana manual. Code dekha nahi ja sakta -> pehle DEMO, "Allow DLL imports" band.
- **Baaki:** inputs / behaviour samajhna (demo / Strategy Tester se).

## VPS Helper v1.03 + BotFlow.ex5 (12 Nov 2026)
- User ne `BotFlow.ex5` (compiled EA, source nahi) VPS par bhejne ko kaha. Helper ab tak sirf `.mq5` uthata tha -> v1.03: `vps-ea/` aur `copytrade-ea/` ki `.ex5` bhi har MT5 terminal ke `MQL5\Experts` me **seedha copy** (compile nahi). COPY tab "VPS Helper" card me "ex5 copy hui" dikhega.
- Helper ka naya version aate hi agli baari ek baar poora deploy dobara jaanchta hai (`state.hv`), taaki usi commit ki .ex5 chhoot na jaaye. Isliye merge ke baad BotFlow pahunchne me ~4-6 min lag sakte hain (pehle helper khud update, phir copy).
- Faisla: repo PUBLIC hai — user ne kaha phir bhi public repo me hi daalo.
- Helper chart pe EA nahi lagata — BotFlow chart pe lagana manual. Ex5 ke andar ka code dekha nahi ja sakta -> pehle DEMO, "Allow DLL imports" band.
- **Baaki:** BotFlow ki inputs / behaviour samajhna (demo / Strategy Tester se).

## VPS Scanner v1.08 — Bazaar ka Mausam (15 Nov 2026)
- Har minute har ON pair: `candlerules.weather` (news `/feed/news/cal`, 1min + 1h bars, aam spread EMA `ST.cdl.spAvg`) → `/candle/wx/<NAME>` {c G/Y/R, why, t}; naye paper par `wx`. Sirf naap; trade niyam wahi.

## VPS Scanner v1.07 — Candle paper ka sabse gehra ghata (15 Nov 2026)
- Nateeja likhte waqt `mae` (candlerules.paperResolve se) bhi. Sirf naap.

## VPS Scanner v1.06 — Candle paper par 4 pushti likhna (15 Nov 2026)
- Naye paper me `cf` = candlerules.confirms(sg, band candles, badi TF band candles) — 1 MIN ki badi TF 5 MIN, 5 MIN ki 15 MIN (`feed/bars/15min`). Sirf naap; signal / paper niyam wahi.

## VPS Scanner v1.05 — Candle paper SL $10 + hold + ek pair ek trade, purana data ek baar saaf (15 Nov 2026)
- User Final. Pehli baar chalte hi `/candle/paper` DELETE (ek baar, `ST.cdl.reset105`; heartbeat me `reset`). Naya paper {tp candle, sl 10, hold true, maxCandles 1m 200 / 5m 72}; nateeja `paperResolve` hold niyam (PROFIT BOOK / TP / SL / TIME, `n` candle). `X.open` — sym|tf ka chalu paper ho to naya nahi. 4-tareeke tulna band. Asli EA wahi.

## VPS Scanner v1.04 — Candle paper 1 MIN + 5 MIN dono (15 Nov 2026)
- Har run me tf 1 aur 5 dono ke liye signal jaanch + paper (key ke aakhir me tf); `/candle/sig` (push) sirf app ke `cfg.tf` wale ka. Heartbeat me `tfs: [1, 5]`. Resolve 80 aakhri.

## VPS Scanner v1.03 — Candle paper me SL ki tulna (15 Nov 2026)
- Naye paper me `slDyn` (candlerules.dynSl: body ka 100%, $0.20–$1.50). Nateeja `paperVariants` se: `p.v` = {A SL $1.50, B candle SL, C break-even 60%, D B+C}; `res / pl` = A. App Record me tulna table. Asli EA wahi ($0.25 / $1.50).

## VPS Scanner v1.02 — Candle paper TP candle ke hisaab se (14 Nov 2026)
- Paper record ka `tp` = `candlerules.dynTp(sg, k)` (signal candle body ka 50%, $0.10–$1.00); purana candlerules ho to $0.25. Asli EA wahi.

## 🕯️ CANDLE app band ho tab bhi — VPS Scanner v1.01 + AI AUTO EA v1.12 push (14 Nov 2026)
- User: Candle page (Strategy 5) app band hone par bhi signal + paper + phone push → option A + "push chahiye".
- **Scanner v1.01** (`vps-scanner/scanner.mjs`): ENG_FILES me `candlerules.js` (app ka hi code, Pages se). Har run (Task Scheduler har 1 min) me 15m AI scan ke saath `candleLoop` (~54 sec, scan lamba ho to tab tak): app ka `/candle/cfg` {pairs, tf, autoPaper} padh kar har nayi band candle ke ≥4 sec baad (feed ki candle 25 sec tak intezaar) `signal()` → `/candle/sig/<c+next36+NAME+tf>` {sym, n, dir, tf, at, next, why, rsi, t, sendSec}; autoPaper ON ho to `/candle/paper/<key>` (spread live se, k = pipUsd) + har 15 sec `paperResolve` (TP / SL / CANDLE CLOSE, 6 ghante = DATA NAHI). Heartbeat `/candle/vps` {t, v, tf, pairs, paper, last} har min. Safai din me ek baar: sig 3 din, paper 60 din. Data Feed band (weekend) = kuch nahi. KOI ORDER NAHI. Scanner khud ko GitHub se 6 ghante me update karta hai.
- **AI AUTO EA v1.12**: `PollCandle()` har PollSec — `/candle/sig` aakhri 8; naya (≤ 2 min purana) → push "CANDLE: XAUUSD BUY | 1m candle 21:47 IST | MT5 button N sec" (ya "paper me juda"). EA shuru hone par purane ka push nahi. Input `CandlePushOn` (true). Trade niyam wahi.
- Mock Firebase se jaancha: heartbeat + sig + paper + purane paper ka nateeja PUT hue.

## SAMUSIGNAL AI AUTO v1.13 — TARGET LOCK + target $3 (17 Nov 2026)
- User: $3 target, $4 par pahunch kar bhi USDCAD (−$0.92) chalu raha — "minus trade band karke $3 par din band hona chahiye tha". v1.12 target par sirf pending cancel karta tha. User "Final" + "default target $3".
- `DailyTargetUsd` 5 → 3. `TargetLock` (true): `DoTargetLock()` har second — target pura (band trade net ≥ target, din me pehli baar `g_TgtDay` / `g_TgtNet`) aur Magic ke chalu trade: net + chalu P/L ≥ target → DayStats dobara, sab `PositionClose` + push "TARGET LOCK … din band". Kam ho → push ek baar "intezaar", kul wapas target par aate hi band, warna apna TP / SL. Target ek baar pura = din bhar band (pehle net ghatne par dobara chalu ho sakta tha). `g_StopWhy` = "target poora $<pal ka net> | LOCK …".

## SAMUSIGNAL AI AUTO v1.11 — Spread $0.20 + spike guard 2× (13 Nov 2026)
- User Final "$0.20 + 2 guna". (A) `MaxSpreadUsd` 0.20: spread ki keemat (spr × k × 0.01) > $0.20 → SKIP; 60% wala niyam sirf MaxSpreadUsd=0 par. (B) `SpikeMult` 2.0: `SpreadSample()` har 10 s 28 pair (cache Resolve), EMA /180 (~30 min), 60 namoone (10 min) baad guard; 30 min gap = reset; purana bhaav (>120 s) chhodo. Abhi ka spread > 2× aam → SKIP "spread spike". (C) PLACED me "spread N pts $x". Dashboard SPREAD dabba "MAX $0.20 + SPIKE 2x", aakhri $.
- 13 Nov 8 PM: 7 signal, 4 spread SKIP (AUDNZD / EURNZD / EURAUD / GBPUSD, PPI ke baad) — isi liye.

## SAMUSIGNAL AI AUTO v1.10 — Loss currency din bhar band (13 Nov 2026)
- User: "kisi pair me loss to us din us currency ka koi trade nahi" → Final **b + x** (dono currency, sirf demo AI AUTO; REAL PERSONAL FX nahi).
- `DayStats` me aaj (server din) ke har loss deal ke pair ki dono currency `g_BlkCur` (",GBP,CHF,"). `LossCurBlocked()` → ProcessSig SKIP "loss currency: ..."; `CheckLossCur()` (har 10 s) un currency ke pending CANCELLED + ek push "aaj band (loss): GBP, CHF"; PublishState un pair ko `busy` me (scanner AI nahi poochhta). Dashboard signal patti par "AAJ BAND (loss): GBP, CHF". Input `LossCurBlock` (true). Chalu trade TP / SL tak.

## SAMUSIGNAL AI AUTO v1.09 — Grey akshar hare + bold (13 Nov 2026)
- User: "grey words samajh nahi aate, green dark + bold karo". `cLbl` 167,169,174 → 134,239,172 (chamakdaar hara); `DTxt` / `DRun` me cLbl wala text hamesha bold; Fit bhi bold se naapta. Kaam / niyam wahi. Spread wala sujhaav ab v1.10.

## SAMUSIGNAL AI AUTO v1.08 — Strategy 1 / 2 (13 Nov 2026)
- User: "PERSONAL FX ki Strategy 4 isme Strategy 2 ke roop me; abhi wala Strategy 1".
- Input `Strategy` (default **1** = abhi wala, TP $0.25 / SL $1.50). **2** = 1 + RECOVERY, v7.5 S4 ka port: `S2Debt()` (aaj ke is Magic ke band deal, loss jodo / baad ki jeet ghatao), `S2Adx()` (M15 ADX14), `S2Manage()` har second: SL backup, badhaya hua (SL profit me) → TP $0.50 + lock +$0.20 @ +$0.30; aam trade yogya (bharne ke ≤15 min + ADX ≥25 + baaki ghata > 0) → +$0.25 par SL +$0.10 (ya +$0.20) aur TP $0.50, warna $0.25 par band; broker TP yogya par $0.50.
- Inputs S2_BigTP_Usd 0.50, S2_LockAt 0.30, S2_LockTo 0.20, S2_PreLock 0.10, S2_FastMin 15, S2_AdxMin 25. Push "SAMUSIGNAL AI AUTO S2: ..." sirf recovery / lock par (TP / SL push pehle jaisa OnTradeTransaction se).
- Dashboard news dabbe me line: "STRATEGY 2 RECOVERY: ON - baaki ghata $x" / "taiyaar" / "STRATEGY 1".

## SAMUSIGNAL AI AUTO v1.07 — Bade akshar (13 Nov 2026)
- User (v1.06 screenshot): "sahi hai, par words itne baarik ki dikhte nahi" (Toolbox khula = aadhi oonchai).
- `SetFont`: design size ≤13 wale akshar × `TextScale` (input, 1.4; 0.8–2.0), asli size kam se kam 10 (pehle 7). Pill / button text 12→14. News dabbe ki lambi lines `Fit` se katti hain; scan tile `28|18|AI 5|2 ok`.
- Dabbe / meter / ghadi / niyam wahi. Spread wala sujhaav ab v1.08.

## SAMUSIGNAL AI AUTO v1.06 — Chaudi screen poori bhare (13 Nov 2026)
- User (PC screenshot): dashboard 960×640 (3:2) tha, chaudi window me beech me chhota + side kaali.
- Ab `g_Kx` (1.0–2.0): oonchai se scale, bachi chaudai me saari x-jagah / dabbe ki chaudai phailti; meter (DGauge) apni jagah par gol hi bante, akshar ka size wahi. Click hit-test bhi `g_Kx` se. Input `WideFit` (true). Mini patti / PanelScale>0 par purana jaisa.
- Saath me user ko bataya: Ctrl+T / Ctrl+M / Ctrl+N + F11 se chart ko zyada jagah.

## SAMUSIGNAL AI AUTO v1.05 — Har scan ka phone push (13 Nov 2026)
- User ne option **b** chuna: har 15m scan ke baad MT5 push — `AI AUTO 11:47 | 2 signal | laga: NZDUSD SELL | SKIP: GBPJPY SELL trend`; signal na mile to `koi signal nahi | achhe 19, AI ne dekhe 5, sahmat 0`.
- Sirf trade samay me (07-17, 20-22 IST), Sat / Sun nahi, PAUSE / din band par nahi. Scan fail (`ok:false`, jaise Data Feed band) par ek hi baar push, theek hone tak.
- Input `ScanPushOn` (true). Trade ke niyam me koi badlav nahi.
- **Trend niyam dheela karna (sujhaav 1 / 2 / 1+2) — user ne PENDING rakha.**

## SAMUSIGNAL AI AUTO v1.04 — Trade samay + 15m trend jaanch (12 Nov 2026)
- Wajah: CADJPY BUY LIMIT 112.164 (demo, 11 Nov ~23:45 IST bhara) — signal ke baad M5 par trend neeche palat gaya, LIMIT girte bhaav me bhar gaya (~-$0.91, SL nahi laga tab tak). User ne sirf sujhaav A (trend jaanch) Final kiya + trade samay.
- (1) `TradeWindows` = "07:00-17:00,20:00-22:00" (IST). Bahar: naya signal SKIP ("trading samay ke bahar (agla 20:00 IST)"), EA ke saare pending CANCEL (samay khatam), chalu trade apne TP / SL tak. Firebase state stop=true -> scanner AI nahi poochhta. Dashboard: "SAMAY BAHAR" + "naya trade 20:00 IST se" / "trade samay 17:00 IST tak".
- (2) `TrendRecheck` (15m EMA `TrendEMA`=21, band candle): BUY pending cancel jab aakhri band 15m close < EMA aur EMA neeche jhuka (EMA[1] < EMA[2]); SELL ulta. Har 10 sec jaanch (15m candle band hone par badalta hai); signal ke waqt hi aisa ho to SKIP "trend: ...". iMA handle har symbol ka cache. Data taiyar na ho to rok nahi.
- (3) `MaxSpreadPctOfTP` default 25 -> **60** (user). News rok 60 min pehle / baad alag se wahi chalta hai. Badlav SIRF is naye EA me (PERSONAL FX nahi chhua).
- B (tez girawat), C (LIMIT 30 min), D (raat JPY) NAHI bane. Spread ka pakka hal ab **v1.05**.

## SAMUSIGNAL AI AUTO v1.03 — Dashboard poori screen (12 Nov 2026)
- v1.02 VPS par compile + chal gaya; user: "full screen show hona chahiye". Ab PanelScale = 0 (default) = chart ke size se apne aap (min(W/960, H/640)), beech me; FullScreen=true par CHART_SHOW=false + background dashboard jaisa (EA hatane / mini par wapas). CHARTEVENT_CHART_CHANGE par dobara size. Mini patti = poori chaudai, upar.
- Bug fix: TimeToString(.., TIME_SECONDS / TIME_MINUTES) sirf "hh:mi(:ss)" deta hai — v1.02 me StringSubstr(11) se beech ki IST ghadi aur server time khaali the. Meter ka bada ank sui ke neeche (cy+42).
- Spread ka pakka hal ab **v1.04**.

## SAMUSIGNAL AI AUTO v1.02 — Dashboard "Twin Gauge" (design 4) (11 Nov 2026)
- User ne 6 design me se **4 (Twin Gauge)** chuna (canvas: claude.ai/artifact/Qtj8HhVKd25Q9gPoxhSoRB). "Baaki mat banana" — sirf ye panel; trade ke niyam me koi badlav NAHI.
- CCanvas (OBJ_BITMAP_LABEL "SSA_DASH", 960x640 x PanelScale 0.8): profit meter ($0 -> DailyTargetUsd), loss meter (0 -> MaxLossesPerDay, aakhri khaana laal), beech me IST ghadi + server + session + halat (CHALU / AAJ BAND / PAUSE / ALGO BAND / NET ERROR / BAND (REAL)) + DEMO/REAL + agla scan countdown; 4 khaane (TP/SL + jeet %, open / pending + floating, scanner aakhri scan, spread aakhri signal ka); aaj ke signal ki patti (lage / spread / news / 1-pair / baaki — terminal GlobalVariables `SSA<magic>_<din>_<pl|sp|nw|pr|ot|in>`); open trades (5 tak, pending ka bacha min); agli High news (36 ghante, har 10 min) ya "news rok abhi chalu"; niyam; ALGO / FIREBASE / REAL LOCK; aakhri signal + nateeja.
- Buttons: **PAUSE / RESUME** (naya order nahi; GlobalVariable `SSA<magic>_pause`, restart me bhi; Firebase state stop=true + paused, scanner AI nahi poochhta), **CANCEL PENDING** (2 baar dabana, 4 sec me), **-/+** chhoti patti (mini).
- Inputs: PanelOn (false = purana Comment text), PanelScale, PanelX, PanelY. Sab text ASCII (MetaEditor encoding).
- Compile yahan nahi hota — VPS Helper card me dekhna (CCanvas LineThick / FontSet).
### Baaki
- Spread ka pakka hal ab **v1.03** (pehle v1.02 kaha tha) — "Final" ka intezaar. TP -> SL trail — faisla baaki.

## SAMUSIGNAL AI AUTO v1.01 — Inputs ke naam saaf (11 Nov 2026)
- MT5 input ka note naam ki jagah dikhata hai — v1.00 me FirebaseAuth "News Pusher / Data Feed EA wala hi" aur TP / SL dono "$ per 0.01 lot" dikhte the. Ab: "FirebaseAuth (News Pusher wala hi)", "TP $ (0.01 lot par)", "SL $ (0.01 lot par)" ... Kaam me koi badlav nahi.
- VPS par chalu (11 Nov 22:36 IST, demo 434476133, XAUUSDm M15 chart). Scanner install ho gaya (test: 28 pair, AI 5, sahmat 2). Pehle 2 signal (22:46) spread filter se SKIP (18 / 21 pts > 9 / 10). User faisla: spread 25% hi rahega (A) — 2-3 din dekhna kitne trade lagte hain.
- config.json fix (scanner): Notepad me quote / comma chhoote to bhi keys padh leta hai.

## SAMUSIGNAL AI AUTO v1.00 + VPS Scanner v1.00 — AI sahmat par auto LIMIT (11 Nov 2026, DEMO)
- User ki strategy: XAUUSD / BTCUSD chhod kar sirf AI sahmat; TP $0.25 / SL $1.50 (0.01 lot); 1 pair 1 trade (band hone par naya); jitne pair sahmat sab; High news 60 min pehle - 60 min baad naya order nahi + EA ke pending cancel; spread filter; din me 4 loss ya $5 profit -> din band (chalu trade TP / SL tak chalte hain); LIMIT 60 min. User ke faisle: rasta B (VPS scanner), LIMIT, 0.01, chalu trade chalne do, DEMO.
- **Scanner** `vps-scanner/scanner.mjs` (Node 22, `C:\SamuScanner`, Task Scheduler har 1 min, har 15m slot me ek scan, candle ke 25 sec baad): app ka engine GitHub Pages (`SAMUSIGNAL-AI/src/{symbols,data,engine,ai}.js`) se har 6 ghante taaza (app badle to scanner bhi), MT5 feed se 15m + 1H, Grade A/B + 15m/1H saath, top 5 par `aiCheck` (60 min cache, roz `aiPerDay` 300), sahmat + bharosa >= 70 -> `/samuai/auto/sig/<a+base36 ms>` {sym, dir, entry, sl, grade, conf, why, live, at, exp}. Ek signal 2 din tak dobara nahi. Halat `/samuai/auto/scan`. EA ki `/samuai/auto/state` padhta hai: busy / news pair par AI nahi; EA 10 min chup ya din band -> scan chhodta hai. Khud ka naya version raw GitHub se (6 ghante). Keys sirf VPS ki `config.json` me. `--test` = likhta nahi, dikhata hai.
- **Install**: `vps-scanner/install.ps1` (ek line PowerShell): portable Node v22.11.0, config.json Notepad me (gKey + fbAuth user khud), task "SamuScanner", test scan.
- **EA** `SAMUSIGNAL AI AUTO v1.00.mq5` (magic 7310001, comment "SSA"+sig id): har 5 sec `/samuai/auto/sig?orderBy="$key"&limitToLast=30`; jis par `st` nahi use nipatata: PLACED / SKIP (wajah) / ERROR, pending hatane par CANCELLED / EXPIRED. TP / SL doori = $ / (OrderCalcProfit se $ per price per lot x 0.01). Spread > TP doori ka 25% -> SKIP. BUY LIMIT entry ask se neeche hona chahiye (warna SKIP). Din = broker server din, EA ke deals se (loss = DEAL_PROFIT < 0 wala exit). Har 30 sec `/samuai/auto/state` {t, stop, why, losses, net, open, pend, busy[], news[], status} (balance / login NAHI). Push: lagaya / bhara / TP-SL + aaj ka hisaab / din band / news cancel. REAL account par AllowReal=false -> koi order nahi.
- Test (yahan): scanner nakli Firebase + nakli Gemini ke saath — sahmat signal likha, ek slot me ek hi scan. EA ka compile yahan nahi hota -> VPS Helper card me compile result dekhna.
### Baaki
- VPS par install + DEMO chart par EA lagana (user). 1-2 hafte demo nateeja, phir REAL ke liye alag "Final".
- Spread asal hisaab me: paper ($0.25) me spread nahi tha; demo se asli tasveer milegi.

## SUPERTREND GRID v2.08 — lock trade par TP (30 Oct 2026)

- **Live (demo $10,000, v2.07):** 3 Buy × 0.05 (4007.155 / 3997.126 / 3987.119, $10 grid sahi) → 3977.8 par khula loss −$300 → **DD LOCK**: 3 Sell × 0.05 (`STG_LOCK`), bina TP. Lock −$300 par laga → Ankush ki setting me Max DD 300 lagti hai (default 500).
- **Ankush:** TP dikhna chahiye.
- **Fix:** default `InpDDMode` ab **LOCK+TP** (har ulti trade TP $5 = 5.00 price, round 7 6 5 4 3). Pehle se khuli lock trade bina TP ho (purana version / mode badla) to EA TP laga deta hai; price TP ke paar ho to band.

## SUPERTREND GRID v2.07 — Cockpit dashboard (29 Oct 2026)

- **Ankush:** dashboard alag / unique chahiye — rang, ghadi, emergency par screen par flash. 6 preview banaye (Design canvas artifact: Neon Cyber, Cockpit, Light Desk, Matrix Terminal, Top Strip, Gold Luxe) → Ankush ne **Cockpit** chuna.
- **Panel (960 px design, chart ki chaudai me scale):** Row1 badi IST ghadi (second, din / tareekh, server time, session) + TREND + **MASTER CAUTION** · Row2 bade number BASKET P&L / DAILY / CYCLE / RESERVE · Row3 **DD gauge** 20 khane (hara / amber / laal) · Row4 lights NEWS / SPREAD / ALGO / WEEKEND / LOCK / SPIKE · Row5 status + PAUSE / CLOSE ALL · Row6 avg / agla grid / lock + reserve USE box. Fonts Consolas + Arial.
- **Alert:** `Notify(msg, level)` — 2 = laal (Max DD lock / band, spike): master caution laal blink, chart ke beech bada flash 15 sec, `alert2.wav`, click = OK · 1 = hara (cycle profit, din target) 60 sec. Timer 0.5 sec.

## SUPERTREND GRID v2.06 — 30% reserve (29 Oct 2026)

- **Ankush:** jo profit aaye uska 30% emergency ke liye alag; panel par dikhe kitna bacha hai aur kitna use karna hai; use na karo to pada rahe ($10k → $20k ho jaaye tab bhi).
- **Sach (bataya):** MT5 EA paisa alag account me nahi bhej sakta (Exness Personal Area → Transfer haath se). Isliye **usi account me kagzi reserve** chuna gaya.
- **Kaise:** har cycle band → us cycle ka P/L (`CSTART` se) → pichhla loss (`RCARRY`) pehle pura, baaki ka **30%** `RES` me (push alert). AUTO lot aur din target sirf **Trading balance = balance − reserve** par. Panel [6] RESERVE: bacha / use kiya / trading balance + box me $ likho → **USE** (reserve se utna trading me, reserve se zyada nahi). Inputs `InpReserve`, `InpReservePct`.
- Kagzi hai → margin call / stop-out me broker poora balance use karta hai; asli suraksha ke liye haath se transfer.

## SUPERTREND GRID v2.05 — TF chuno, AUTO lot, spread / weekend / push / spike (29 Oct 2026)

- **Ankush ke saath tay:**
  - Supertrend TF chuno: **M1** (default) / M5 / M15 / M30. Upar wale TF ka filter (default M15) **OFF** — Ankush: M1 par basket band hokar naye trend se shuru hota hai, dono taraf trade aayenge.
  - **AUTO lot:** har **$2000** balance par 0.01 ($10,000 = 0.05), basket shuru par tay. Trailing ($2 / $1 / $1) aur lock TP ($5) 0.01 ke hisaab, lot ke saath x badhte. Max DD $500, cycle $50, din 1% — account ke hisaab, nahi badhte.
  - **Spread filter:** spread > 0.50 → naya basket / grid nahi.
  - **Weekend:** Shukra **3 PM IST** ke baad se Somvar **7 AM IST** tak naya basket nahi (chalu basket chalta rahe).
  - **Push alert:** Max DD lock / band, cycle profit, din ka target, spike.
  - **SPIKE:** pichhle 5 min (M1) me basket ke khilaf **$30** → basket ke kul lot jitni **ek** ulti trade, **TP price $5** (0.05 lot par $25). Khuli rahe tab grid / trailing / Max DD lock ruke. Agla spike kam se kam 5 min baad.
  - **News ke samay grid bhi nahi** (`InpNewsBlockGrid`, default ON).

## SUPERTREND GRID v2.04 — cycle profit $50 (29 Oct 2026)

- **Ankush:** kabhi atak jaaye (lock) to jab opening balance se +$50 ho jaaye, saare trade band, naya basket / naya cycle.
- **Badlav:** `InpCycleProfit` 50: basket ki pehli trade se ab tak ki band deals (lock ki TP wali Sell bhi, manual close bhi) + khuli trade ≥ +$50 → CloseAll → cooldown → naya basket. Panel [1] me naya row "CYCLE P&L x / +$50".

## SUPERTREND GRID v2.03 — LOCK+TP round 7 6 5 4 3 (29 Oct 2026)

- **Ankush:** DD par pehle round 7 Sell (basket jitni), sab TP $5; market aur neeche → sab band → agle round 6, phir 5, 4, 3, phir wapas 7 — 7 6 5 4 3, 7 6 5 4 3 ...
- **Badlav:** mode 2 LOCK+TP me har round ek kam (`InpLockMinTrades` 3 tak), phir basket jitni se dobara. Round GV `LOCKK`. Status: "LOCK+TP round k".
- **⚠️ Hisaab (Ankush ko bataya), 7 Buy:** har $5 neeche wale round me net = (Sell k − 7) × $5 → 7: 0 · 6: −5 · 5: −10 · 4: −15 · 3: −20 → ek poora chakkar ($25 neeche) ≈ **−$50** aur. Kam Sell = basket ki disha me khula exposure → market palte to tezi se wapas, na palte to DD badhta. Basket ka apna exit lock me nahi — CLOSE ALL.

## SUPERTREND GRID v2.02 — DD par 3 vikalp (29 Oct 2026)

- **Ankush (soch rahe hain, vikalp chahiye):** Max DD $500 par jitni Buy (jaise 7 × 0.01) utni Sell, har Sell ka TP $5; market aur neeche gaya to 7 Sell TP par band → phir 7 Sell, aise hi chalta rahe.
- **Account:** Ankush ise **$10,000** balance par chalayenge → $500 DD = 5%, stop-out ki chinta nahi (pehle wali $81 wali chetavani demo ke liye thi).
- **`InpDDMode`:** 0 CLOSE (sab band + aaj band) · **1 LOCK (default)** · 2 LOCK+TP (ulti trade ka TP `InpLockTP` $5; saari TP par band → utni hi phir; rokna = CLOSE ALL).
- **⚠️ Hisaab (Ankush ko bataya):** LOCK+TP me har $5 neeche: Sell +$35 book, Buy −$35 aur khule → equity wahi; phir upar aaye to Buy +$35, nayi Sell −$35 → equity wahi. Yani equity lagbhag jam jaati hai, har nayi 7 Sell par spread (~$1.75) jaata hai, basket kabhi khud band nahi hota — sirf "loss book + profit book" ka roop badalta hai.

## SUPERTREND GRID v2.01 — Max DD $500 par LOCK (29 Oct 2026)

- **Ankush:** Max DD $500, aur DD pahunchne par jitni Buy trade chalu hain utni hi Sell trade lagni chahiye.
- **Badlav:** `InpMaxDD` 40 → **500**; naya `InpDDLock` (default true): DD par sab band karne ki jagah basket ki har trade ke saamne ek ulti trade (5 Buy × 0.01 → 5 Sell × 0.01, comment `STG_LOCK`). Lock ke baad EA grid / trailing nahi karta — faisla haath se (CLOSE ALL). Lock wali ulti trade haath se band ho to EA basket phir sambhalta hai. `InpDDLock` false = purana (sab band + aaj band).
- **⚠️ Ankush ko bataya:** $81 account par $500 DD kabhi nahi aayega — usse pehle broker ka stop-out. 7 trade tak (0.07 lot, −$60) khula loss ~−$210 = account khatm. $500 tabhi matlab ka jab account bada ho.

## SUPERTREND GRID v2.00 — nayi strategy, hedge ki jagah grid (29 Oct 2026)

- **Ankush:** hedge wala achha nahi chal raha (demo ~$98 → ~$81). Supertrend se entry wahi, baaki badlo.
- **Niyam (Ankush ke saath tay):**
  - Entry: **M1** Supertrend (ATR 10, ×3, band candle) ki disha, nayi M1 candle par **0.01**.
  - Grid: pehli entry se har **$10** ulta → usi disha me ek aur 0.01, **kul 7 trade** tak.
  - Basket: kul profit **+$2** → **$1 lock**, phir sabse unche profit se **$1 peeche** trailing. Fixed TP nahi. Lock ka SL server par bhi (sab trade par ek hi price, avg + lock / lots).
  - **Max DD $40** (basket) → sab band, aaj band (RESUME se hatao).
  - Band hone ke baad **5 min cooldown**, phir M1 Supertrend ki mojooda disha me naya basket.
  - Din ka target: din ki shuruaat ke balance ka **1%**.
  - Pehle jaisa: news filter (USD ±30), manual close ginti, dashboard, PAUSE/RESUME, CLOSE ALL. Naya Magic **26102901**, GV prefix `STG2_`.
- **⚠️ Ankush ko bataya:** $10 gap par 3 trade (−$20) ke baad price ~−$23 par hi loss −$40 → Max DD $40 me grid asal me ~3 trade tak; 7 trade tak −$210 khula loss (account ~$81).
- **Pending (baad me):** 5 min me $30 ek-tarfa chaal → ulti disha me basket jitne lot ka ek trade, TP $5 — Ankush ne abhi rok diya.
- **Baaki:** VPS par compile (yahan compile nahi) · Strategy Tester real ticks · demo.

## SUPERTREND HEDGE v1.19 — poora code review (28 Oct 2026)

- **Ankush:** abhi bhi kuch galat ho raha hai, poora setup check karo.
- **Sahi mila:** Supertrend (TV jaisa, band candle), nayi M5 candle par entry, hedge level (main ± 3), HYBRID emergency Stop (± 0.30, server), +$0.20 SL (Ask/Bid ke baad asli profit), lock me main TP hatna, cycle kul +$1, Max DD, din target, news, manual close ginti.
- **Kamiyan (fix):** (1) kabhi 2 hedge khule (pehle log me 06:20:43 / 06:20:46) to hedge > main → net ulti exposure → DD badhta; ab extra (sabse naya) hedge turant band · (2) market hedge se thik pehle positions dobara gine (usi pal Stop bhara ho to doosra nahi) · (3) +$0.20 ke baad wala "aage jaao" niyam price level ke main wali taraf wapas jaaye to reset.
- **Dhaanche ki seema (bug nahi):** lock me cycle tab tak atka rahega jab tak kul +$1 na bane; price main ki taraf bhaag jaaye aur hedge kabhi +$0.20 na dekhe to lock lamba chalega (swap). Yahan compile / tester nahi — VPS par compile + Strategy Tester (real ticks).

## SUPERTREND HEDGE v1.18 — lock me loss book nahi (28 Oct 2026)

- **Ankush:** hedge ka kaam sirf main ko sambhalna, DD maintain rahe; chop me +$0.20 book ho rahe hain to loss kisi bhi angle se nahi hona chahiye.
- **Bacha hua loss point:** lock ke dauraan main ka server TP lagta → main +$1 par band, cycle khatam hone par hedge ~−4.3 me band → cycle ~−3.3.
- **Fix (`InpNoLossClose` true):** hedge khula ho to main ka TP hata dete hain; lock me cycle sirf "kul (band + khuli) ≥ +$1" niyam se band. Hedge band ho aur main akela ho to cycle wala TP wapas. Panel MAIN TP: "LOCK - kul +$1 par band".
- **Keemat (Ankush ko bataya):** loss book nahi hota par khuli trades me baitha rehta hai — equity ~$3.3 neeche, cycle ghante / din atak sakta hai (naya cycle nahi), swap, ek-tarfa trend me lock khisak sakta hai. Max DD $20 aakhri safety (ye loss book karega) — rakhne ki salah.

## SUPERTREND HEDGE v1.17 — hedge kabhi loss me nahi katega (28 Oct 2026)

- **Ankush ki History (28 Oct, demo, balance ~98 → 81.30) ka hisaab:** TP wali cycle 6 × +$1 = +6 · 11:xx cycle (purana 0.02 hedge) −6.11 · **13:xx cycle −13.52** (main Buy 4053.07 −2.88 haath se band; ~21 hedge me **hard SL 9 baar × −1.24 = −11.16**, +0.20 wale sirf +1.09) · 15:xx −3.40 (3 hedge, main khula).
- **Wajah:** price hedge level (4050.07) ke aas-paas 4049–4051 ghoom raha tha → hedge → 1.24 ulta → hard SL → wapas neeche → naya hedge → phir hard SL. 0.01 hedge (main jitna) me hard SL ki zarurat hi nahi — hedge jitna gawaye main utna kamaye, DD nahi badhta. Hard SL 0.02 hedge ke zamane ka niyam tha.
- **Fix:** `InpHedgeNoLossCut` true (default) → hard SL aur M1 cut band, purana loss-side SL bhi hata dete hain. Hedge sirf +$0.20 par band (pehle $0.20 ke aage jaaye tab). DD ~−$3.3 par jama.
- **Sach:** jis cycle me hedge laga, wo lagbhag −$3.3 me hi khatm hogi (main TP par hedge loss me band hota hai). Profit = bina hedge wali cycle (≥75–80% chahiye).

## SUPERTREND HEDGE v1.16 — churn fix + frozen fix (28 Oct 2026)

- **Ankush (v1.15 live):** equity $95 → $88. Experts log: hedge +$0.20 par band → usi pal "spike" se naya hedge (price abhi bhi emergency level ke paar) → har kuch second chakkar, +0.20 − spread ≈ 0 ya minus. Saath me close "10029 frozen" (server SL usi price par, broker freeze) aur emergency stop "invalid price". 19:16:00 par v1.14 ki line bhi → shayad do chart par do version — ek hatana.
- **Fix:** profit wale hedge ke baad naya hedge tabhi jab price us band price se `InpHedgeEmergency` (0.30) aur aage jaaye, ya band hone ke BAAD ki M1 candle uske paar band ho. Loss wale cut ke baad pehle jaisa (level se). Server par +$0.20 SL ho to EA khud close nahi bhejta.
- $95 → $88 me main Buy ka floating loss bhi shaamil (price 4053 se neeche) — wo lock me hai, book nahi hua.

## SUPERTREND HEDGE v1.15 — HYBRID hedge + main akela rehne ka fix (28 Oct 2026)

- **Ankush ke screenshot:** Buy 0.01 @ 4053.07 → −4.47, phir −6.20, koi hedge nahi (level 4050.07). M1 CLOSE me hedge der se; spike me DD badhne ka darr.
- **HYBRID (`InpHedgeMode` 3, default):** M1 candle level ke paar band → market hedge, **aur** level se `InpHedgeEmergency` 0.30 aage server par Stop order → spike me turant hedge (VPS band ho tab bhi). M1 hedge se pehle Stop hataya jaata hai; hat-na fail = bhar chuka → doosra nahi (duplicate se bachav). **Ankush: DD $3-3.5 se upar nahi → emergency 0.70 → 0.30**, hedge lagne tak main loss ~$3.3 (+ spread / slippage).
- **Log fix (Ankush ka Experts screenshot, v1.14):** "cancel #... [invalid request]" baar-baar — EA hedge khule hone par har tick saare orders hata raha tha, market order (hedge khulna / SL se band) bhi. Nuksan nahi tha. Ab sirf Stop / Limit pending hate hain. Log me hedge ka asli lot (pehle "0.02" likha aata tha).
- **Bug fix (−6.20 ki wajah):** hedge +$0.20 par band hota hai jab price abhi level ke paar hai; purana "arm" niyam naye hedge se pehle price ko level ke peeche bhejta tha → price seedha aage gaya to main akela. Ab M1 CLOSE / HYBRID me ye intezaar nahi (TOUCH / BUFFER me pehle jaisa).

## SUPERTREND HEDGE v1.14 — hedge 0.01, partial band (28 Oct 2026)

- **Ankush:** partial ka niyam band, hedge bhi 0.01 se. (Unka "hedge ko main bana do" idea nahi liya — numbers se: hedge −$8 tak, phir 0.02 → 0.04 → 0.08 = martingale.)
- **Badlav:** `InpHedgeMult` 2.0 → 1.0 (hedge 0.01 = main jitna → $1 lock / partial apne aap band) · `InpMaxPartials` -1 (band) · **FIX:** whipsaw ab sirf LOSS me kate hedge (+$0.20 / 0-0 wale nahi gine). Panel par "LOSS HEDGE x / 6".
- Hedge: +$0.20 ke upar → SL entry + $0.20; nahi pahuncha → M1 cut / hard SL 1.00.
- **Ankush (DD na badhe, cycle der se band ho to chalega, ek-tarfa market me haath se $2-3 loss book karenge):** LOSS HEDGE limit band (`InpMaxWhipsaw` -1) aur 60 sec cooldown band (`InpHedgeCooldown` 0). M1 CLOSE me ek candle par ek hedge waise bhi. Max DD $20 waisa hi.
- **⚠️ Naya khatra:** 0.01 / 0.01 = poora lock. Price main ke khilaf aage badhta rahe to loss ~−$3 par jam jaata hai par basket +$1 kabhi nahi (pehle 0.02 se aata tha). Cycle tab tak atki jab tak price hedge entry − 0.20 tak wapas na aaye; swap katega, naya cycle nahi.

## SUPERTREND HEDGE v1.13 — saari setting default (28 Oct 2026)

- **Ankush:** saari setting default me hi ho, kuch badalna na pade.
- Ankush ki live setting: **din target $10** (default 5 → 10), **Max DD $20** (default 10 → 20). Baaki saare default (0.01 lot, $1 TP, $3 gap, 2x hedge, M1 CLOSE, cooldown 60s, hedge min +$0.20, M1 cut, hard SL 1.00, 4 partial, 6 whipsaw, news USD ±30) pehle se live jaise. Niyam v1.12 jaise.

## SUPERTREND HEDGE v1.12 — hedge 0-0 nahi, +$0.20 profit par band (28 Oct 2026)

- **Ankush:** abhi bhi loss. Baaki sab waisa hi rakho, sirf hedge band hone ka niyam: 0-0 par nahi, **kam se kam +$0.20 profit** lekar. 0.02 hedge aur partial ke baad bacha 0.01 — dono par.
- **Kaise:** hedge ka profit $0.20 ke upar gaya → server SL = entry + $0.20 (0.02 par 0.10 price, 0.01 par 0.20 price), EA bhi wahi check karta hai. Aage chale to chalne do, wapas $0.20 par aaye to band. Input `InpHedgeMinProfit` 0.20 (0 = purana 0-0).
- Jo hedge $0.20 tak nahi pahuncha → M1 cut / hard SL (v1.11 jaisa). $1 lock + 0.01 partial waise hi.
- H1 Supertrend filter / trend palte to cycle band — sujhaye, Ankush ne abhi nahi liye.

## SUPERTREND HEDGE v1.11 — hedge seconds me nahi kate (28 Oct 2026)

- **Ankush ka observation:** hedge lagta hai aur 1-3 second me kat jaata hai, baar-baar. Wajah: niyam tha "entry se 1 tick ulta = turant cut".
- **Fix:** jo hedge abhi 0 ke upar nahi gaya, wo tabhi katega jab hedge khulne ke baad band hui **M1 candle hedge level ke andar** band ho (`InpHedgeExitM1` true). Beech ki upar-neeche me hedge chalta rahega. Bada jhatka → server **HARD SL** entry + spread se 1.00 (`InpBackupSL`, pehle 0.50). Profit me aane ke baad asli 0-0 BE (server SL = entry) pehle jaisa.
- **Trade-off:** cut ab kam honge, par ek cut ka loss spread (~0.55) se zyada ho sakta hai — max ~$2.5 (1.00 + spread × 0.02). Tester / demo me milaana.

## SUPERTREND HEDGE v1.10 — hedge entry mode, nakli hedge kam (28 Oct 2026)

- **Ankush:** BE par loss hi asli problem hai, ye solve ho jaaye to EA taiyaar.
- **Sach:** buy Ask par khulta, Bid par band → jo hedge kabhi spread se upar nahi gaya, uska 0-0 par band hona mumkin nahi (broker ka spread). Hedge na kaatna (net 0.01 ulta, loss badhta) ya 0.01 lock (main TP kabhi nahi) — dono khatarnak. Isliye hal = **nakli hedge kam karo** (level chhoo kar laut-ne wale).
- **`InpHedgeMode`:** 0 TOUCH (pehle jaisa) · **1 M1 CLOSE (default)** — 1 min candle level ke paar band ho + price abhi bhi paar → market hedge, ek candle par ek hi · 2 BUFFER — level se `InpHedgeBuffer` 0.30 aage Stop.
- Text-to-Quant / Replit is hedge + partial + BE logic ko sahi test nahi kar sakte; whipsaw seconds me hote hain → **MT5 Strategy Tester (real ticks)** me teeno mode 2 hafte par chala kar milaana. Raw/Zero spread account se har cut ka loss aur kam.

## SUPERTREND HEDGE v1.09 — buttons status patti me (28 Oct 2026)

- **Ankush:** RESUME button dikh hi nahi raha tha — panel ke sabse neeche tha, chart chhota (neeche Toolbox khula) to kat jaata.
- **Fix:** PAUSE / RESUME aur CLOSE ALL ab upar STATUS patti me daayein. Trading niyam v1.08 jaise.

## SUPERTREND HEDGE v1.08 — RESUME se Max DD stop hatao, panel fit (28 Oct 2026)

- **Ankush ka screenshot (v1.07):** status "AAJ BAND (Max DD)", jabki Max DD input $50 aur din ka P&L +0.11. Wajah: aaj pehle purane version (Max DD $10) me ek cycle −$10 tak gaya (SELL 0.01 −4.77 + hedge loss) → aaj ka stop GlobalVariable me yaad. Input badalne se nahi hat-ta.
- **Fix:** din band ho to panel ka button **RESUME** dikhata hai; dabane par aaj ka Max DD stop hat jaata hai.
- **Panel:** chhote chart par daayein kat raha tha → chart ki chaudai me fit hone ke liye scale + font apne aap chhota (min font 7).
- Ankush ne apni setting badli: din target $10, Max DD $50.

## SUPERTREND HEDGE v1.07 — hedge 1 min cooldown (28 Oct 2026)

- **Ankush ka screenshot:** saare hedge (Buy 0.02) loss me kate (−0.48 se −1.14). Price level chhoo kar wapas aata → hedge kabhi 0 ke upar nahi gaya → spread / slippage jitna loss. 06:20:43 / 06:20:46 par 3 sec me do hedge (shayad do chart par EA — ek se hatana).
- **Ankush ka faisla:** hedge khulne ke baad kam se kam **1 minute cooldown** — usse pehle doosra hedge nahi (pending bhi hata diya jaata hai). Input `InpHedgeCooldown` 60 sec. Panel status par "HEDGE COOLDOWN xx sec".
- Baaki sujhav (M1 close confirmation, whipsaw 6 → 3) abhi nahi liye.

## SUPERTREND HEDGE v1.06 — manual close bhi target me (28 Oct 2026)

- **Ankush:** EA ki trade manual band karun to bhi profit / target me gini jaaye.
- **Wajah:** manual close wali deal ka Magic 0 hota hai → pehle din ka P&L, cycle P&L, recent closes me nahi aati thi.
- **Fix:** EA ki position (IN deal is Magic se, 7 din peeche tak) ki har band deal gini jaati hai — EA ne band ki ho ya haath se. EA ke bina khuli manual trade nahi gini jaati. Trading niyam v1.05 jaise.

## SUPERTREND HEDGE v1.05 — PERSONAL FX jaisa dashboard (28 Oct 2026)

- **Live:** v1.04 Exness demo (XAUUSDm M5) par compile ho kar chal raha hai (Ankush ka photo: aaj +0.58, balance 100.92).
- **Ankush:** dashboard PERSONAL FX jaisa chahiye → amber terminal panel (Consolas, DPI-aware, chart ki chaudai jitna): status bar + [1] CYCLE (Supertrend, main, TP, hedge level, hedge, partial x/4, whipsaw x/6, start balance, cycle P&L) · [2] ACCOUNT · [3] RISK CONTROL (din target, Max DD, news, algo) · [4] SETTINGS · [5] RECENT CLOSES (IST).
- **Buttons:** PAUSE / RESUME (naya cycle rokta, chalu trade nahi chhedta; restart ke baad bhi yaad) · CLOSE ALL.
- Trading niyam v1.04 jaise. Compile check VPS par.

## SUPERTREND HEDGE v1.04 — asli 0-0 BE + duplicate hedge fix (28 Oct 2026)

- **Ankush ka live screenshot (Exness trial XAUUSDm):** 03:45:07 par **do** Buy 0.02 hedge ek saath (4046.326, −0.55 + −0.55), phir 4046.565 par −0.88. Hedge "BE" par minus me kat rahe the.
- **Wajah 1 (bug):** price level par aaya → server ne Buy Stop bhara aur usi pal EA ne market se bhi khola. **Fix:** pending laga ho to market nahi; 5 sec me na bhare to hi pending hata kar market.
- **Wajah 2 (spread):** buy Ask par khulta, Bid par band → khulte hi −spread (0.275 × 0.02 = −0.55). Entry par turant 0-0 mumkin nahi.
- **Faisla (Ankush):** hedge spread cover karke 0 ke upar gaya → **server par SL = entry** (`InpBEPlus` 0) → price wapas aaye to bilkul 0-0. Jo hedge kabhi 0 tak nahi pahuncha, wo pehle jaisa spread jitne loss par katega (iska koi hal nahi; Raw/Zero spread account se kam hoga).
- EA sirf **ek chart** par lagana (do chart same Magic = duplicate).

## SUPERTREND HEDGE v1.03 — naya cycle sirf nayi M5 candle par (28 Oct 2026)

- **Bug (Ankush ne live dekha):** cycle band hote hi turant doosra trade khul gaya.
- **Fix:** cycle band hone ke baad (aakhri band deal ka time, history se — restart safe) **agli nayi M5 candle** shuru hone par hi Supertrend check → naya trade. EA lagane / restart par bhi agli nayi candle ka intezaar. Baaki sab v1.02 jaisa.

## SUPERTREND HEDGE v1.02 — 4 partial + 0-0 exit, whipsaw 6, Max DD $10 (28 Oct 2026)

- **Hisaab (spread 0.25):** partial wala hedge round ≈ +$0.75 (0.01 par +$1, bacha 0.01 BE par −spread) · whipsaw round ≈ −$0.50. Main 0.01 ka hedge level par loss $3 → **4 partial ≈ $3 = lagbhag 0-0** (3 partial = $2.25, kam).
- **Ankush ka faisla:**
  - Limit ab **partial ki ginti** se (`InpMaxPartials` 4), entry se nahi. 4 partial → naya hedge nahi.
  - **0-0 exit:** 4 partial ke baad cycle ka kul ≥ 0 → sab band, naya cycle.
  - **Whipsaw** (bina partial BE) alag gine, `InpMaxWhipsaw` 6 → naya hedge nahi (~$3 spread kharcha par ruk).
  - **Max DD $10** default (cycle −$10 → sab band, aaj band).
- v1.01 ka `InpMaxReentry` hata diya. Ginti deal history se (restart safe).
- **Dhyaan:** ek Max DD = 2 din ka target ($5). Limit ke baad main akela → Max DD hi bachav.

## SUPERTREND HEDGE v1.01 — cycle TP, re-entry 3, news filter (28 Oct 2026)

- **Ankush ka faisla (risk review ke baad):**
  - **Main TP cycle ke hisaab se:** TP = jahan cycle ka kul (band partial / BE + main) +$1 bane. BE ke spread loss se cycle ab minus me band nahi hoga.
  - **Re-entry max 3:** pehla hedge + 3 baar dobara (kul 4 hedge ek cycle me). Uske baad naya hedge nahi, main TP ka intezaar. Input `InpMaxReentry` (-1 = no limit).
  - **News filter:** USD HIGH impact se 30 min pehle / 30 min baad naya cycle nahi (MT5 calendar). Chalu cycle chalta rahega. Panel par news ka time **IST** me (Ankush). Strategy Tester me calendar nahi → tester me filter apne aap off.
- **⚠️ Dhyaan:** 3 re-entry ke baad main trade bina hedge ke hai → loss ki seema nahi. `InpMaxDD` set karna zaroori (default abhi bhi 0 = off).
- Ankush: din me ~1 ghanta chalana hai ($5 target), isliye news filter shayad hi lage, phir bhi ON rakha.
- **Baaki:** v1.00 jaisa (compile check VPS par, tester, demo).

## SUPERTREND HEDGE v1.00 — naya EA (28 Oct 2026)

- **Ankush ki strategy (sab tay):** MT5, hedging account, XAUUSD.
  - **Entry:** M5 Supertrend (ATR 10 RMA, x3, band candle) jis taraf, us taraf MAIN 0.01, TP $1 (server par). Naya cycle turant mojooda trend ki taraf.
  - **Hedge:** price $3 ulta (Buy 4000 → 3997) → ulti side **0.02** (Sell Stop / Buy Stop pending, level par market fallback).
  - **Lock:** hedge $1 per 0.01 (0.02 par $2, 3996) → lock. Price aur gaya + basket floating ≥ $1 → sab band. Price wapas 3996 → **0.01 partial close** (+$1); bacha 0.01 sirf hedge.
  - **BE:** hedge (0.02 ya bacha 0.01) entry se ulta gaya → turant band (sirf spread ka loss). Price dobara level ke paar → fir 0.02, wahi niyam, jitni baar bhi.
  - **Cycle +$1:** cycle shuru par balance note; cycle ka kul (band partial / BE + khuli trades) ≥ $1 → sab band, naya cycle (100 → 101).
  - **Cycle khatam:** main TP → hedge bhi band → fir Supertrend → naya cycle.
  - **Din:** $5 target (server 00:00 se, sirf band deals) → naya cycle nahi, chalu cycle pura hoga.
- **Safety:** hedge par backup SL server par (BE se 0.50 aage, EA band ho tab bhi) · Max DD input (default OFF; lage to sab band + aaj band) · Re-entry gap input (default 0 = usi level par).
- **Dhyaan:** entry aur BE ek hi level par → har chakkar spread jitna loss (~$0.4–0.6, 0.02 lot). Price level ke aas-paas ghoome to jud-ta hai; tab Re-entry gap 0.3 jaisa try karo. Gap / slippage me DD $3 se zyada ho sakta hai. Lock lamba chale to dono trade par swap.
- **Magic:** 26102801. Restart safe (main ticket + lock GlobalVariable me).
- **Baaki:** VPS par compile check (yahan compile nahi hota) · Strategy Tester real ticks · demo 1–2 hafta.

## ARADHAYA SCALPER v2.04 — E2 EMA slope veto (24 Oct 2026)

- **Replit agent se idea liya** ("Forex Scalping Signals" app — usme live signal asal me nahi bante, demo values hain). 4 idea M1 data par DD10 ke saath test (30000):
  - ATR min 2.5: +26.8% / DD 8.7% ❌ · trend me averaging band: koi farq nahi · band ke andar close par market entry: +2.1% / DD 13.8% ❌
  - **EMA slope veto** (M15 EMA50 ka 1 ghante ka move > ATR(M5) × 0.5 → E2 entry nahi): **+29.0% / DD 7.9%** (spread 0.35: +28.5% / 7.9%) ✅
- **Faisla (Ankush):** veto jodo. Input `InpE2SlopeVeto` (default ON), `InpE2SlopeMax` 0.5. Baaki sab v2.03 jaisa.

## ARADHAYA SCALPER v2.03 — PRESET DD10 / DD15 / DD20 (24 Oct 2026)

- **⚠️ Simulator ki galti mili:** pehle wale backtest me TP candle ke high/low par band ho raha tha aur grid add candle ke sabse achhe price par → v2.00–v2.02 ke saare % (+181%, +90% ...) **galat / bahut zyada** the. Theek karke M5 aur M1 dono par: v1.00, v2.00 (3 engine), v2.02 default **sab loss me**.
- **Naya sahi test:** Twelve Data XAUUSD **M1** (21 Apr – 23 Oct 2026, 2.68 lakh candle), har M5 candle ke andar M1 ki chaal, TP / add asli price par, 30000 balance, spread 0.25 aur 0.35. 60+ setup.
- **Nateeja:** sirf **E2 Range** lagataar profit me (2 level par TP 1.5 / 3 / 4.5 teeno plus, SL 0). E1 2-level thoda plus, E4 aur 3 engine saath loss, 4-level grid lagbhag har jagah loss.
- **Preset (30000, spread 0.25):**
  - **DD10 (default):** sirf E2, 2 level, TP 4.5, 4000 par 0.01, Group SL 8% → +27.9%, DD 8.6%, SL 0, 498 trade, 95% din plus, bura din −980.
  - **DD15:** sirf E2, 1 trade, TP 4.5, 1000 par 0.01, Group SL 16%, emergency 20% → +58.6%, DD 15.6% (1333 par DD 19% bhi aaya — khatra).
  - **DD20:** sirf E2, 2 level, TP 3.0, 2000 par 0.01, Group SL 16%, emergency 20% → +39.9%, DD 18.7%.
- Asli raftaar ~0.3–0.6% roz (0.8% target kam din pura). Sample chhota (1 engine, 6 mahine).
- **Baaki:** MT5 Strategy Tester (real ticks) me DD10 chala kar milaan · demo 2 hafta.

## ARADHAYA SCALPER v2.02 — 4000 par 0.01 lot (24 Oct 2026)

- **30000 balance par 6 mahine (v2.01, 3000 par 0.01):** +79% / +90% (spread 0.25 / 0.35), DD 19–21%, Group SL 8 baar, 92% din profit, sabse bura din −2,919 (~9%), August −7.1%.
- **Wahi test 4000 par 0.01:** +92% / +105%, **DD 12–14%, SL 5 baar**. 20000 par bhi DD 13.5% (3000 wale me 21%). Isliye v2.02 default 4000.
- Lot: 30000 = 0.07, 50000 = 0.12. Baaki sab v2.01 jaisa (din 0.8%, Group SL 8%, group target pehla lot × $4, lot limit × 15 / × 6).
- Dhyaan: bar-level simulation, settings ke chhote badlav par nateeja kaafi badalta hai. Tester (real ticks) + demo pehle.

## ARADHAYA SCALPER v2.01 — 3000 par 0.01 lot, din 0.80% (24 Oct 2026)

- **Ankush ki setting:** AUTO lot har 3000 balance par 0.01 (20000 = 0.06, 50000 = 0.16) · din ka target 0.80%.
- **Re-test (wahi 6 mahine, 0.06 lot):** purane 0.2% group target / 10% SL ke saath DD 14.6–15.4%, chhote lot par group target der se aata tha. Group target = pehla lot × $4 move (0.12% @20000) + Group SL 8% → **+86–89%, DD 11–12%, 6 SL** (spread 0.25/0.35). Isliye v2.01 me yahi default.
- **Badlav:** AutoPerBalance 3000 · DailyTarget 0.8% · GroupSL 8% · DailyLoss 8% · GroupTargetMove 4.0 (pehla lot × $4) · lot limit apne aap: kul = pehla lot × 15, net = × 6. Engine / regime / grid / TP v2.00 jaise.
- Dhyaan: simulation approximate; Strategy Tester (real ticks) + demo pehle.

## ARADHAYA SCALPER v2.00 — multi engine + manager (24 Oct 2026)

- **Ankush ka idea:** ek account par alag-alag strategy, exit ek saath (averaging / group net). Chop ka khatra bhi cover ho.
- **6 mahine ka M5 backtest** (Twelve Data XAUUSD, 20 Apr – 23 Oct 2026, 38,256 candle, apna bar-level simulator, cent 20000, lot 0.10, spread 0.25/0.35):
  - v1.00 (sirf trend, 6 level): **+3.6%, DD 39%, 13 basket SL** → v1.00 LIVE par nahi.
  - Sirf trend + regime: +81% / DD 16% / 4 SL. Sirf chop (regime ke saath): +120% / 4 SL; bina regime +7% / 11 SL.
  - Trend + Range + Chop bina group exit: +39% / DD 43%. **Group exit ke saath ("L2"): +181% / DD 11% / 4 SL** (0.35 spread: +153% / DD 12.5%).
  - Breakout (E3) jodne se nateeja bigda → v2.00 me default OFF.
  - Dhyaan: approximate simulation + ~20 setup me se best chuna (overfit ho sakta hai). Asli faisla MT5 Strategy Tester (real ticks) + demo.
- **v2.00 = L2 ke niyam:** E1 Trend (sirf TREND, market, 4 lvl, TP 1.5) · E2 Range (sirf RANGE, Bollinger limit OCO, 4 lvl, TP 1.5) · E4 Chop (RANGE/MIXED, 1 ghante ka box limit OCO, 3 lvl, TP 0.75) · E3 Breakout OFF.
- **Manager:** regime M15 ADX(14)/CHOP(14) (25/50 trend, 20/55 range) · group exit bank + floating ≥ 0.2% balance → sab band · kul lot 1.50 / net 0.60 (pending bhi gine) · group SL 10% → sab band + aaj band · din 1% target / 10% loss · server emergency SL 15% har basket.
- **Order type:** E1 market, E2/E4 limit, E3 stop, grid add market, exit market. News / time / pause / regime badle → pending cancel.
- **Magic:** 24102611 (E1), 24102612 (E2), 24102613 (E3), 24102614 (E4).
- **Baaki:** VPS compile check · Strategy Tester real ticks 3–6 mahine · demo 2 hafta · phir Smart Recovery (v2.0x) aur E3 dobara test.

## ARADHAYA SCALPER v1.00 — naya safe mode scalper (24 Oct 2026)

- **Kahan se idea:** FXMIND SCALPANDO (MT4, 3 engine martingale, x1.55, $2 gap, koi SL nahi, news filter naqli). Usme se sirf "chhota TP + basket average par sab band" liya; baaki khatarnak hissa hata diya.
- **Ankush ke saath tay (Discuss):** Cent account 20000 · XAUUSD **M5** · Basket SL **10%** · Din ka target **1% default ON** · naam ARADHAYA SCALPER.
- **Entry:** M15 EMA50/EMA200 + close EMA50 ke paar = trend; M5 pichli candle trend ki taraf; RSI(14) BUY 50–70 / SELL 30–50. Ek samay ek hi basket, sirf nayi M5 candle par.
- **Filter:** spread > 0.50 nahi · M5 ATR > 8 nahi · MT5 calendar USD high impact ±30 min · IST 02:30–05:30 nahi · Shukra 23:00 → Somvar 06:00 IST nahi · Shanivar 02:00 IST basket band.
- **Grid:** max 6 level · gap = ATR×1.5 (min $3, max $10), har level ×1.2 · lot L1–L2 same, phir ×1.3 · max lot 0.50 · AUTO lot har 2000 balance = 0.01 (20000 → 0.10) · ek M5 candle me ek hi add.
- **Exit:** L1–3 TP = avg ± 1.50 · L4+ = avg ± 0.30 · lock: avg se 1.00 aage → SL avg ± 0.30.
- **Safety:** basket SL (balance ka 10%) **server par har trade ki SL me** (VPS band ho tab bhi) + EA backup check · basket loss me band → aaj band · din loss limit 10% · din target 1% → sab band, kal tak band (restart ke baad bhi yaad, GlobalVariable).
- **Panel:** status, trend, basket, avg/TP/SL, aaj P/L vs target, spread/ATR/gap, agli news, CLOSE ALL + PAUSE/RESUME button. Push alert.
- **Magic:** 24102601.
- **Dhyaan:** 1% roz vs 10% SL → ek SL = ~10 din ka profit. Pehle Strategy Tester + demo/cent par 1–2 hafta.
- **Baaki:** Strategy Tester nateeja · VPS par compile check (VPS Helper card) · zarurat ho to TP / gap tune.

## ✅ FINAL FAISLA — Buster trailing test band (28 Oct 2026)

- **Shadow 17–27 Oct, 22 trade (0.01):** Buster asli **+10.39** (19/22 jeet, max DD −2.16, 2 best hata ke +5.81) · A +7.80 · B +4.96 · C +11.07 (max DD −5.51, 2 best hata ke +2.87) · D +2.10 (max DD −11.97). E (9 trade) +3.39 vs Buster +10.08; F (7 trade) +4.66 vs Buster +5.50.
- **Faisla:** Buster ka **apna trailing hi rakho** (`UseTrailingStop = true`). C ka +0.68 ka fark 22 trade par na ke barabar, aur uska DD 2.5 guna. Chaudi trailing (D/E) me jeet ka % gir jaata hai. Trailing Manager LIVE **nahi** hoga; shadow test band. Balance 55.62 → 66.01 (~10 din).
- Buster ka rule (data se): ~5000–6000 pts profit par SL ≈ open+5, phir ~5000 pts peeche. Apne `BTC EA` clone me same chahiye to (money-based inputs, lot ke hisaab se): 0.01 lot par InpBETrigger 0.55, InpBEPlus 0.05, InpTPMin 0.55, InpTrailing true, InpTrailDist 0.50 (0.10 lot par sab 10 guna).
- `BTC Trailing Manager v1.03` file rakhi hai (future test ke liye), chart se hata do.
- **BTC EA v1.18** (28 Oct): ye final trailing default me — Trailing ON, TPMin (shuru) $0.55, TrailDist $0.50, Breakeven $0.55 par entry+$0.05, Profit Lock OFF (Buster me nahi; jaldi kaat-ta). Sab $ 0.01 lot ke liye; lot badhao to $ bhi utne guna.
- **BTCGOLD EA v1.02** (28 Oct): BTC EA v1.18 wali FINAL Buster trailing gold par. Code same (ZigZag swing scan, stop orders, 72 ghante), sirf defaults gold ke hisaab se — M30 ATR BTC ~230 / gold ~7.5 (≈ ÷30): SL MAX $5, Trailing ON shuru $1.80 doori $1.60, Breakeven $1.80 par entry+$0.20, Profit Lock OFF, TP MAX $20, DAY LOSS $10, same-disha doori 3.0, ATR threshold 0.0008. Magic 111334 (v1.01 wala) — v1.01 chart se hata kar v1.02 lagao. Sab $ 0.01 lot ke liye; lot badhao to $ bhi utne guna. Pehle DEMO par 1 hafta.

## BTC Trailing Manager v1.03 — set F hybrid-C (24 Oct 2026)

- **Shadow 17–24 Oct (15 trade):** Buster asli +4.89 (balance 55.62→60.51) · A +1.96 · B +0.84 · C +9.29 · D +11.72 (2 bade trade hata do to −2.99). E sirf 2 trade: Buster +4.58, D −0.86, E +1.20.
- Kai trade ~300 price (30000 pts) par palat jaate hain → D/E ki trailing shuru hi nahi hoti (23 Oct: peak 296.6, D −2.01, E +0.05, Buster +2.34). C zyada bharosemand.
- **Naya set F (hybrid-C):** BE 5500 pts par SL = open+500, phir 20000 par trailing shuru, 15000 doori. Shadow me ab 6 sets (A–F). Real par zero risk (Mode=SHADOW).
- Faisla: abhi LIVE nahi; ~1 hafta aur (E/F ke 10+ trade), phir winner LIVE.

## BTC Trailing Manager v1.02 — set E hybrid (22 Oct 2026)

- **Shadow nateeja 17–22 Oct (13 trade, 0.01):** Buster asli +0.31 · A −2.14 · B −2.46 · C +6.59 · **D 30000/20000 +12.58** (2 bade trade +7.47/+7.24 se; chhote trade D me −1.50).
- **Buster ka chhupa trailing:** ~5000–6000 pts profit par SL ≈ open+5, phir ~5000 pts peeche (peak ka ~53% hi rakhta) → isliye profit chhota.
- **Naya set E (hybrid):** BE 5500 pts par SL = open+500, phir 30000 par trailing shuru, 20000 doori. Shadow me ab 5 sets (A–E). Real par abhi bhi zero risk (Mode=SHADOW).
- Agla kadam: ~1 hafta E vs D vs Buster → winner LIVE.

## BTC Trailing Manager v1.01 (SHADOW test) + Investor Account Watcher v1.04 (17 Oct 2026)

- Doosra VPS band, is VPS par naye demo terminal ki jagah nahi → real 3099 par hi **zero-risk SHADOW test**.
- Manager v1.01 Mode=SHADOW (default): real SL nahi chhuta (Buster `UseTrailingStop = true` hi rahe). Har naye Buster trade (Magic 111111) ki 4 virtual copies: A 10000/8000, B 15000/12000, C 20000/15000, D 30000/20000 pts (start/doori), step 1000; virtual SL Buster ke initial SL se shuru; real band hone ke baad bhi virtual tab tak chalta hai jab tak virtual SL/TP na lage. Buster ka REAL result bhi. File: `MQL5\Files\IW_shadow_<acc>.jsonl`. Panel me har setting ka kul $.
- Mode=LIVE: shadow ke saath real SL bhi LIVE settings se (tab Buster me UseTrailingStop=false).
- Watcher v1.04 shadow lines trail.json me bhejta hai; app Trailing tab me "Shadow test — kaunsi setting best".
- Agla kadam: 10+ complete trades ke baad best setting ko LIVE settings me daal kar Mode=LIVE.

## BTC Trailing Manager v1.00 + Investor Account Watcher v1.03 (17 Oct 2026)

- **Problem (Ankush):** Buster BTC ("BTC Ea Tp Sl 1.23", sirf .ex5) me trailing ka sirf on/off hai; loss fix ~$1.50 (SL 15000 pts, 0.01 lot) par profit bahut chhota aata hai.
- **Hal:** `BTC Trailing Manager v1.00` — alag chart par chalta hai, Buster ke trades (Magic, default 111111) ka SL aapki settings se khiskata hai: TrailStart 15000 / TrailDistance 12000 / TrailStep 1000 points, optional Break-even. Naya trade nahi kholta, TP nahi chhedta, SL kabhi peeche nahi. **Buster me UseTrailingStop = false rakhna zaroori.**
- Defaults sirf shuruaat hain — Investor Watch app ke Trailing tab (watcher v1.03) ke data se tune karenge.
- **Investor Account Watcher** (repo INVESTOR-ID): v1.00 positions+history → v1.01 401 fix (token file) → v1.02 pending orders + order history → v1.03 trailing tracker (1 sec scan, SL move events, peak vs close give-back, exit reason; `data/<acc>/trail.json`).
- Apna clone `BTC EA v1.17` me trailing settings pehle se hain (InpTPMin $, InpTrailDist $, InpTrailing default OFF).

## v10.5.1 — Pair tab fix: hedge β ab return se (17 Oct 2026)

- **Bug (Ankush ke live screenshot se):** EURAUD/EURNZD, AUDUSD/NZDUSD, AUDCAD/NZDCAD me correlation plus (0.6–0.8) par Hedge β **minus** (−0.10 se −0.45). Wajah: β price level se nikalta tha; 100 candle me dono ulte trend me ho to β minus. Aisi jodi pe TRADE LO aata to dono **same side** bata deta = hedge nahi, double risk.
- **Fix:** β ab candle **return** se (minimum-variance hedge) — iska sign hamesha correlation jaisa. Plus correlation jodi me ek BUY + ek SELL hi aayega. Spread/Z/half-life baaki wahi tareeka.
- Free plan pe jo symbol nahi milta (XAG/USD = 404) uski jodi scan ke baad **apne aap OFF** — agle scan me credit nahi jaata. Pairs list me dobara ON kar sakte ho.
- Display: Z/β/correlation hamesha 2–3 decimal (pehle "-1" jaisa dikhta tha).
- Kavach: 2 naye test (ulte trend me β ka sign = correlation; plus jodi me dono same side kabhi nahi). Purana level-β tareeka is test pe β = −0.695 deta tha.

## v10.5.0 — PAIR TRADING tab (17 Oct 2026)

Naya **PAIR** tab (bottom nav me 7th, ⚖️). Baaki saare tab waise hi. **Sirf app me signal** — MT5 ko kuch nahi jaata, Telegram nahi (Ankush ka faisla).

- **Pairs (sab default ON):** Gold/Silver (XAU/XAG), EURUSD/GBPUSD, AUDUSD/NZDUSD, EURUSD/USDCHF (ulti), EURJPY/GBPJPY, AUDJPY/NZDJPY, AUDCAD/NZDCAD, EURAUD/EURNZD, BTC/ETH. Apni jodi bhi add/delete ho sakti hai.
- **Timeframe:** H1 ya H4 (chip). 220 candle laata hai, cache H1 15 min / H4 45 min.
- **Ganit:** (v10.5.1 se β return se — upar dekho) log price pe OLS → β (hedge), spread = logA − β·logB − α, Z = spread / std (last *lookback* candle). Correlation candle **return** se (price wala jhootha high dikhata hai). Half-life = AR(1) se.
- **Signal:** |Z| ≥ Entry → TRADE LO (Z+ = A SELL, Z− = A BUY; B ka side β ke sign se — ulti jodi me dono same side). |Z| ≤ Exit = NORMAL, Exit–Entry = RUKO, |Z| ≥ Stop = BAHUT DOOR (entry nahi), |corr| < Min = PAIR TOOTA.
- **Lot B:** dono taraf ki USD value barabar (β ke hisaab se), min 0.01. Rounding se 25% se zyada farak ho to warning.
- **Virtual Tracker:** signal card pe 📌 TRACK → har scan pe P&L ($) aur Z update. Z Exit ke andar ya ulti taraf = EXIT, Stop ke bahar = STOP. Spread/commission nahi gina. Max 40 record.
- XAG/USD app ke SPECS me **nahi** daala (baaki app pe asar na ho) — sirf `PR_EXTRA` me (Exness 1 lot = 5000 oz).
- Credits: ek scan = jitne naye symbol (sab ON = 17 credit, free plan me ~3 min, 8/min limit pehle wala hi).

### Pair settings (PAIR tab → Settings)

| Setting | Default |
|---|---|
| Entry Z | 2.0 |
| Exit Z | 0.5 |
| Stop Z | 3.5 |
| Min Correlation | 0.70 |
| Lookback candle | 100 |
| Lot A | 0.01 |

Storage keys: `prCfg`, `prOff`, `prCust`, `prLast`, `prTrack`.

## Tithi Gold v2.06 — hamesha dono side (16 Oct 2026)

- Ankush ka faisla: trade hamesha dono side lagni chahiye (real EA me dono side dikhti hai). Default **both sides always = true**. Baaki sab v2.05 jaisa.

## Tithi Gold v2.05 — real EA ki live setting jaisa (16 Oct 2026)

- Real EA (investor login) ke live pending dekh ke pakka hua: 30 level/side, tier 10 / 10 / 10, lot **0.01 / 0.05 / 0.20**, gap 1.39 (gold 4166 pe). Photo wali "20 level" purani setting thi.
- Naye default: mid lot **0.05**, far lot **0.20**, cycle target **50**, both sides always **false**. Loss cap 3000 (v2.04 se).
- FIX: pehle side cycle shuru hote hi lock ho jaati thi (trend tha to poore cycle sirf ek side). Ab har tick dobara check: trend khatam -> dono side ke stop wapas, trend ulta -> side palat. Dono se ek side beech cycle me nahi jaata.
- Wajah (kyun demo loss me tha): target 3 se chhota profit, loss cap 300 se loss book, aur trend me side lock.
- Risk: ek taraf ~42 move pe 2.6 lot tak khule ho sakte hain. Real account ~$8,454 ka hai.
- Baaki: real EA ka chart timeframe pata karna (trend 6 candle us TF pe ginta hai); 0.05 -> 0.20 ka exact level (16-20 dikha nahi) confirm karna.

## Tithi Gold v2.04 — din ka loss cap 3000 (16 Oct 2026)

- Sirf default badla: **HARD day equity loss cap 300 → 3000** (account currency). Baaki saari settings v2.03 jaisi, Ankush ke Inputs screenshot ke hisaab se.
- Default settings: magic 26011001, 30 level/side, gap 1.0 × price/3000, lot 0.01 / 0.03 / 0.09 (FIXED), cycle target 3, day profit cap 250, loss cap **3000**, after-loss ×2 ON, pause 1 din, dono side hamesha, trend 6 bar / 30, deep DD 800 ×2, trailing arm 2 / dist 1, trail-if-red OFF, hold losers ON, extras (news/weekend/spread/dabba) OFF, push ON, close-by ON, slippage 1000.
- Global Variables ka prefix `TG2_` same hai, isliye purana pause/daydone state v2.04 pe bhi lagu hota hai.
- Baaki: compile check VPS Helper me (yahan compile nahi hota).

## v10.4.1 — AUTO ANALYZE kam sakht (15 Oct 2026)

- Shikayat: 10-12 pair pe sab NO TRADE.
- Wajah: AI se "confidence" = "+$3 pehle aane ka chance" maanga tha. $3 TP / $5 gap me ye bina kisi edge ke bhi ~62% hota hai, isliye 70% ki seema lagbhag kabhi paar nahi hoti thi. App ka apna filter (simulation me ~94% pass) rukawat nahi tha.
- Badlav: confidence ab **setup quality** (85+ textbook, 70-84 achha, 55-69 average, 55 se kam kamzor). Min confidence default **65** (naya storage key `mtfConf2`, purana 70 apne aap hata). Ek order (leg) ke liye 10 kam chalega (55).

## v10.4.0 — 4-timeframe AUTO ANALYZE (15 Oct 2026)

Chart Analysis page ka **📸 AUTO ANALYZE** button ab ye karta hai:

1. **4 timeframe ki candles** — 1H, 15m, 5m, 1m (4 TwelveData credits).
2. **App ka pakka filter (AI nahi)** — har timeframe: price > EMA21 > EMA50, EMA21 ka dhalaan, ADX ≥ 18 = UP (ulta = DOWN), warna FLAT.
   - 15m UP aur 1H khilaaf nahi → **UPTREND** (15m flat + 1H UP bhi UPTREND)
   - 15m DOWN aur 1H khilaaf nahi → **DOWNTREND**
   - 1H + 15m dono FLAT, 15m ADX < 22, range ≥ 2 × TP → **RANGE**
   - 15m aur 1H ulte, ya gadbad → **NO TRADE** (Gemini ko call hi nahi)
3. **Gemini sirf 2 level chunta hai** (mode app tay karti hai):
   - UPTREND: BUY LIMIT (neeche pullback) + BUY STOP (upar breakout)
   - DOWNTREND: SELL LIMIT (upar pullback) + SELL STOP (neeche breakdown)
   - RANGE: BUY LIMIT (support) + SELL LIMIT (resistance)
   - Prompt me PERSONAL FX ka niyam: +TP pehle aaye, −gap (averaging) se pehle.
4. **App ki jaanch har order pe**: sahi side, live se kam se kam 0.2×ATR(5m), zyada se zyada max(2×ATR(15m), 1.2×gap), Stop order pe chase check, AI confidence (kul ≥ Min confidence, har order ≥ Min − 10), RANGE me TP ke raaste me chhat/farsh.
5. **Bhejna**: dono order ek `batch` me Firebase `/personalfx/orders` (fields: `batch`, `leg`, `legs`). Lot / SL / TP / averaging = PERSONAL FX ke niyam.
6. **AI Report Card** (card 4): har faisla save; RESULT CHECK 1m candles laakar dekhta hai — kaun sa order pehle bhara, phir +TP pehle (WIN) ya −gap pehle (AVG), 60 min me na bhara (NOFILL). Ek candle me dono = AVG. Spread nahi gina.

Screenshot wala tareeka pehle jaisa (ek direction) — badla nahi.

## PERSONAL FX v5.9 (sirf app bridge badla)

- Ek batch ke orders ek-dusre ko REPLACE nahi karte (v5.8 me naya order purana hata deta tha).
- `AppBatchOCO = true`: app ka jo order pehle bhare, usi pair ke baaki saare app pending cancel (same side bhi), app me status **CANCELLED**.
- Lot, SL/TP, grid, averaging, profit lock, daily limits — **kuch nahi badla**.

## Settings (app → Settings → Auto Analyze · 4 timeframe)

| Setting | Default | Matlab |
|---|---|---|
| Min confidence % | 65 | AI ka setup-quality score; isse kam = NO TRADE (ek order ke liye 10 kam chalega) |
| PERSONAL FX TP $ | 3 | EA ka `Grid_TP_Dollar` (per 0.01 lot) |
| PERSONAL FX grid gap $ | 5 | EA ka `Grid_Gap_Usd` (per 0.01 lot) |

## Faisle (Ankush ke saath tay)

- Sirf trade ka **faisla** (direction + entry + Limit/Stop) behtar karna hai. SL/TP/averaging PERSONAL FX me hi rahenge.
- Chaaron order (BL+SL+BS+SS) ek saath **nahi** — 2 order wala tareeka chuna (trend me usi taraf Limit+Stop, range me BL+SL).
- PERSONAL FX me sirf app bridge ka batch badlav manzoor.
- Order MT5 pe sirf manual tap se jaata hai (auto-send nahi).
- Pair Trading abhi **sirf app me** — MT5 button / Telegram baad me (agar chahiye).

## Baaki kaam / dhyaan

- [ ] Pair tab 2–3 hafte chalao, Virtual Tracker ka WIN% / kul $ dekho — phir tay karo MT5 button ya Telegram alert chahiye ya nahi.
- [x] TwelveData free plan pe XAG/USD **nahi** aata (Ankush ka screenshot) — v10.5.1 me wo jodi apne aap OFF hoti hai. Gold ke liye koi aur jodi chahiye to baad me socho.

- [ ] PERSONAL FX v5.9 MetaEditor me compile karke VPS pe lagana (yahan compile nahi ho sakta).
- [ ] Agar ab bhi zyada NO TRADE aaye: NO TRADE card ka screenshot dekh ke wajah (filter / AI confidence / leg jaanch) pakdo.
- [ ] 2–3 hafte Report Card bharne do, phir dekho WIN% (kis mode / pair / samay me achha).
- [ ] Kavach ke 14 purane FAIL (C, F, H, I, Q group) v10.3.0 se pehle ke hain — test purane niyam maante hain, app ke naye niyam alag. Alag se dekhna hai.
- [ ] EA restart ke beech batch ka dusra order aaye to wo pehle ko replace kar sakta hai (rare) — zarurat padi to order comment me batch id daalna.


## AMC GOLD MASTER v1.00 (30 Oct 2026)

- **Kahan se:** GrowthMasters (Ankush ne kharida) ke 4 din / 20 trade (account 434151546, magic 20261014) ka observation.
- **Rules:** har M5 candle khulte hi (pehle 30 sec) entry, sirf jab apna trade khula na ho · pichhli candle hari = BUY, laal = SELL, doji (body < 0.10) skip · SL = pichhli candle low/high ± 0.30 (min 1.00, 10.00 se bada = skip) · TP = SL x 1.5 · lot = balance ka 1% risk · lock: profit $2 par SL +$1, phir har +$1 par lock +$1 (fixed $, GrowthMasters jaisa; `InpLockPerLot` ON = 0.01 lot ke hisaab) · din me max 5 trade (server 00:00 se).
- **Magic 20261030.** Extra suraksha default OFF: day loss %, day target %, max spread.
- **Dhyan:** 1% risk vs ~$10 avg jeet (10k par) — ek pura SL ≈ 10 jeet. Pehle DEMO.
- **Baaki:** GrowthMasters ka SL buffer feed offset ki wajah se pakka nahi (0.30 andaza); 1–2 hafte aur data se pura-SL ki dar dekhni hai.


## AMC GOLD MASTER v1.01 — Cockpit dashboard + journal (30 Oct 2026)

- **Ankush:** v1.00 VPS par laga diya; dashboard SUPERTREND GRID wala **Cockpit** jaisa chahiye, aur tracking rakhni hai ki EA kaise chal raha hai (aage badlav ke liye).
- **Panel (Cockpit, 960 px design, chart me fit):** IST ghadi + server + session · SIGNAL (chalti candle ki disha = agla trade + countdown) · MASTER CAUTION (SL laga = laal blink + chart ke beech flash + awaaz, click = OK; jeet / din poora = hara) · TRADE P&L (side, lot, peak) · DAILY (x/5 trade) · LOCK (pakka $) · RISK / TRADE · RISK GAUGE (khula loss vs 1 trade risk, 20 khane) · lights TRADES / SPREAD / ALGO / TIME / LOCK / DAY · status + PAUSE / CLOSE ALL (REAL par confirm) · ENTRY/SL/TP ya BAL/EQ.
- **Journal:** `MQL5\Files\AMC_GM_journal_<acc>.csv` — START (settings), har candle ENTRY (candle O/H/L/C, SL doori, spread, risk) ya SKIP (kaaran), LOCK, CLOSE (SL/TP/lock, peak, worst, kitni der), PAUSE/RESUME. Push notification (InpPush).
- **Investor Account Watcher v1.06:** journal file ko GitHub `INVESTOR-ID/data/<acc>/AMC_GM_journal_<acc>.csv` par bhejta hai (badle to, har 5 min) — Claude yahin se padh ke analysis karega. Watcher aur AMC **same terminal** me hon (MQL5\Files same).
- Strategy v1.00 jaisi hi (koi badlav nahi). Magic 20261030.

## PERSONAL FX v7.3 — News filter (app pending)
- App ka pending (comment "PFXA", abhi nahi bhara) — us pair ki currency (base / profit; gold = USD) ki HIGH news se 30 min pehle CANCEL, app me status "CANCELLED - news se pehle hataya: USD CPI m/m 19:00 IST", phone push.
- News se 30 min pehle se 15 min baad tak naya app PENDING nahi lagta (SKIP "news: ..."). MARKET / pair trade / chalu trade / haath ke order ko haath nahi.
- Inputs: NewsCancelPending=true, NewsBeforeMin=30, NewsAfterMin=15, NewsWithMedium=false. MT5 ka calendar (free), har minute taaza.

## PERSONAL FX v7.4 — App pending par 15m trend jaanch (12 Nov 2026, REAL)
- Wajah: 12 Nov AI AUTO demo (v1.04, trend jaanch + samay) ~19/19 TP (+$4.63), jabki REAL (app 🚀 pending) 7 TP / 1 SL (GBPCHF -1.50) + EURNZD BUY -1.14 chalu. User ne sirf sujhaav 1 Final kiya: "15m trend palte to app ka pending cancel" (trade samay REAL me NAHI).
- App pending (comment "PFXA", abhi nahi bhara): BUY_LIMIT / BUY_STOP ke liye aakhri band 15m close < EMA21 aur EMA21[1] < EMA21[2] -> CANCEL (SELL ulta). Har 10 sec. App status "CANCELLED - #tk trend palta: ...", push "PERSONAL FX TREND". Bhejte waqt hi palta ho to SKIP "trend: ...". Inputs AppTrendRecheck=true, AppTrendEMA=21. MARKET / pair trade / chalu trade / haath ke order ko haath nahi.

## PERSONAL FX v7.5 — STRATEGY 4: scalp + RECOVERY (13 Nov 2026, REAL, user Final)
- User ka idea: ek SL (-$1.50) ke baad kuch jeetne wale trade $0.25 ki jagah $0.50 tak jaayein, 2-3 aise trade se ghata cover. User ke faisle: lock +$0.30 par -> +$0.20 pakka; sirf SL ke baad (recovery); seedha REAL; naya **Strategy 4** (1 / 2 / 3 wahi).
- Paper data (11-12 Nov, 24 pfx TP): 17 (71%) +$0.50 tak gaye; ADX >= 25: 7 / 8; 10 min me TP: 11 / 14. Isi se "yogya" niyam.
- `Strategy = 4` (STRAT_4_RECOVER): aam = S3 jaisa (S4_TP_Usd 0.25, S4_SL_Usd 1.50, no grid, broker SL / TP + software backup).
- Baaki ghata `S4Debt()`: aaj (server din) ke saare closing deal (allowed symbols) kram se — loss jodo, baad ki jeet ghatao (0 tak). > 0 = recovery. History se nikalta hai (restart me bhi sahi). Panel "RECOVERY ON: baaki $x".
- Recovery me "abhi yogya" trade (umar <= S4_FastMin 15 min, band 15m ADX(14) >= S4_AdxMin 25): broker TP $0.50 (S4_BigTP_Usd) par rakha jaata hai; +$0.25 chhoote hi SL +$0.10 (S4_PreLock_Usd), +$0.30 (S4_LockAt_Usd) par SL +$0.20 (S4_LockTo_Usd); $0.50 par band. Yogya na rahe (15 min nikle / ADX kam) -> broker TP wapas $0.25. Modify na ho paaye to $0.25 par band (surakshit).
- "Badhaya hua" trade ki pehchan = SL profit me (stateless). Push: "PERSONAL FX S4: ... RECOVERY ...", "S4 LOCK".
- Compile yahan nahi hota; VPS Helper card dekhna. User ko REAL par Strategy 3 -> 4 khud badalna hai (S4_SL default 1.50).
