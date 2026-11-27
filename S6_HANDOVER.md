# PERSONAL FX — Strategy 6 (Hedge Ladder): पूरा हाल — **अभी का EA v10.1** (27 Nov 2026 रात)

नए Claude session / account के लिए handover। पहले ये file पढ़ो, फिर `STATE.md` (repo का पूरा इतिहास)।

> **27 Nov शाम:** user ने कहा "v9.0 तक का सब रखो, उसके बाद के सारे बदलाव हटाओ"। v9.1 / v9.2 / v9.3 हटाए गए।
> **27 Nov रात:** user का नया प्लान backtest (round 17) के बाद **Final** → **EA v10.1** बना।
> नाम 10.1 क्यों: पुरानी v9.1 file पहले VPS पर जा चुकी हो सकती है। उसी नाम से नई file भेजें तो गड़बड़ होती, इसलिए 10.1 से नई गिनती।
> **अगला version: v10.2** (फिर 10.3…)।

---

## 1. काम करने का तरीका (user की पसंद)
1. जवाब **हिंदी (देवनागरी)** में दो, Hinglish भी चलता है। कुछ पूछना हो तो **नंबर वाले format (1, 2, 3…)** में।
2. समझाते समय **trade नंबर** (1 नंबर, 2 नंबर…) और असली भाव के उदाहरण दो, जैसे "BUY 0.02 @ 4000 → 1 नंबर SELL 3997"।
3. **पहले सुझाव दो, बनाओ सिर्फ़ "Final" बोलने पर।** नियम बदलने से पहले **backtest** करो, फिर Final।
4. हर बदलाव पर version बढ़ाओ। Flow:
   - branch `ccr-de58b3c2-9qoj0z` पर commit
   - PR खोलो
   - squash-merge खुद करो
   - branch को main पर reset करो
5. सच बोलो। गलत नंबर मत दो। Real पैसे के जोखिम से पहले चेतावनी दो।
6. **Secrets कभी chat या commit में नहीं:** FirebaseAuth, TwelveData key, Telegram token, Gemini key। Public GitHub Actions log (INVESTOR-ID) में balance, login या server मत छापो।
7. SAMUSIGNAL-PRO (paid repo) को मत छूना।

---

---

## 2. Repos और files
| चीज़ | जगह |
|---|---|
| **EA (अभी का, आखिरी)** | `Samusignal/vps-ea/PERSONAL FX v10.1 - GRID.mq5` |
| EA पिछला (backup, पुराने नियम) | `Samusignal/vps-ea/PERSONAL FX v9.0 - GRID.mq5` |
| नए प्लान की बातचीत + backtest table | `Samusignal/S6_NEW_PLAN.md` |
| इतिहास / हर version का कारण | `Samusignal/STATE.md` |
| Backtest simulator (research) | `Samusignal/research/s6_bt2.py` + `.github/workflows/s6-research.yml` (branch `ccr-de58b3c2-9qoj0z` पर push होते ही असली gold GC=F 1m 7 दिन + 5m 60 दिन; local: `python3 research/s6_bt2.py --synthetic 1500`) |
| App **S6 LIVE** (PWA) v2.5.0 | repo `GRID-STARTAGY-2/index.html` — LIVE · LADDER · RISK · HISTORY · 🩺 CHECK · SETUP; LIVE में 🔮 आगे का अंदाज़ा; CHECK में 📝 सुधार सूची; `?demo=1` |
| Live data जाँच (public log) | repo `INVESTOR-ID/.github/workflows/feed-check.yml` → `S6_HB / S6_DIAG / S6_ERR / S6_HAAL / S6_LIVE / S6_HEDGES / S6_PEND / S6_EV / S6_CY / S6_NOTE` |
| Firebase | `/personalfx/s6live/<S6_LiveKey=s6>/` → `hb`, `live/<pair>`, `events`, `cycles`, `notes` |

---

## 3. v10.1 के trade नियम (अभी के) — user का नया प्लान (B)
उदाहरण: **main BUY 0.01 @ 4000** (हाथ से)। SELL 0.01 हर $3।

1. **Main lot 0.01** (पहले 0.02)। अकेला हो तो TP **+$2** (4002)। `S6_TP_Usd` = 2 per 0.01।
2. **SELL hedge:** 3997, 3994, 3991… हर $3 पर 0.01। Pending STOP आगे के 5 levels पर (v9.0 जैसा)।
3. **हर SELL (1 नंबर भी) पर $1 नियम** (v9.0 जैसा): +$2 पार → lock, **+$1** पर बंद, सबसे दूर वाला पहले; जोड़ी +$1।
4. **दूसरा BUY 0.01 (नया):**
   - कब: SELL खुले हों और भाव लौटकर **main के भाव 4000** पर आए।
   - कैसे: EA 4000 पर BUY STOP (comment **"PFX6HB"**) रखता है। भरते ही दूसरा BUY।
   - **एक cycle में एक ही बार** (GV `PFX6B2_<main ticket>`)।
   - अकेला बंद नहीं होता। सिर्फ़ cycle के साथ बंद।
   - सारे SELL बंद हो जाएँ और दूसरा BUY न भरा हो → pending हटता है।
   - `S6_SecondBuyOn` = false करो तो ये बंद (बाकी नियम वही)।
5. **Cycle बंद (सारे trade), जो पहले आए:**
   1. पक्का + खुले ≥ **$2** (Net)
   2. main profit में और खुले ≥ **$2** (Cycle TP)
   3. main घाटे में और खुले ≥ **$2** (Basket TP)
   4. SELL सब बंद, सिर्फ़ main + दूसरा BUY बचे → दोनों मिलाकर ≥ **$2** (TP)
   5. खुले ≤ **−$60** (Basket SL)
6. कोई घाटे वाला कट नहीं (−$2 कट नहीं), lock 1.2 नहीं।
7. **Inputs (v10.1 default):**
   - Strategy = 6, `S6_HedgeLot` = 0.01, `S6_Gap_Usd` = 3
   - `S6_TP_Usd` = **2**, `S6_CycleNetUsd` = **2**, `S6_CycleTP_Usd` = **2**, `S6_BasketTP_Usd` = **2**
   - `S6_SecondBuyOn` = **true** (नया)
   - `S6_LockArmUsd` = 2, `S6_LockUsd` = 1, `S6_PendingAhead` = 5, `S6_BasketSL_Usd` = 60
   - `S6_LiveOn` = true, `S6_LiveKey` = s6, `S6_LivePushSec` = 5, FirebaseAuth (सिर्फ़ MT5 में)
   - **Main trade हाथ से 0.01 लगाना** (0.02 नहीं)।
8. **Backtest round 17** (असली gold, `research/s6_bt2.py`):

   | | 1m: $/cycle · $/घंटा · SL | 5m: $/cycle · $/घंटा · SL |
   |---|---|---|
   | v9.0 (main 0.02, $6/$3/$5) | $3.86 · 2.25 · 17 | $5.31 · 2.64 · 8 |
   | **v10.1 (B)** | $1.55 · 1.62 · 5 | $1.96 · 1.77 · 2 |
   | (A) 1 नंबर सिर्फ़ cycle पर (नहीं चुना) | $1.51 · 0.54 · 1 | $1.77 · 0.51 · 1 |

   - v10.1: प्रति घंटा ~30% कम कमाई, पर SL कम (1m 17 → 5, 5m 8 → 2)। main lot आधा।
9. **Code में कहाँ (S6ManageSymbol):**
   - scan: `PFX6HB` → `b2Tk / b2PL` (hedge list में नहीं)
   - `total = mPL + sumH + b2PL`
   - Net / basket / cycle / SL close में b2 भी बंद
   - `hn==0` branch: main + b2 मिलाकर TP / SL
   - "v10.1: doosra trade" block: pending रखना / हटाना
   - hedge pending loop और app की pend list "PFX6HB" छोड़ते हैं
10. **ध्यान दो:**
   - App की LIVE ladder में दूसरा BUY अलग row में नहीं दिखता। पर कुल (total) में उसका P/L जुड़ा है।
   - EA यहाँ compile नहीं हुआ (MetaEditor नहीं)। VPS पर compile नतीजा देखना।
   - पहले **demo** पर चलाओ।

---

## 3b. v9.0 के trade नियम (पुराने, backup) (= v8.9 के नियम + app का CHECK data)
उदाहरण main BUY 0.02 @ 4000, SELL 0.01 हर 3 point:

1. **Main:** हाथ का trade। अकेला हो तो TP **+$6** (4003)। Hedge खुलते ही TP हटता है।
2. **Hedge levels:** 3997, 3994, 3991… (हर $3 / 0.01)।
3. **Pending:** आगे के **5** खाली levels पर STOP। खुले hedge से **1.5 point** के अंदर नहीं।
4. **4b:** बंद hedge अपने बंद भाव पर दोबारा (level से 1.5 point तक)। भाव level के पार लौटे तो ठीक level।
5. **Lock:** hedge **+$2** पार करे → lock, **+$1** पर बंद। **सबसे दूर वाला पहले** (LIFO)।
6. **जोड़ी:** सबसे दूर वाले का lock न हो तो आखिरी 2 मिलकर +$1 पार करें, फिर **+$1** पर दोनों बंद। v8.8 से: नया hedge भरते ही जोड़ी > +$1 हो तो उसी पल चालू।
7. **कोई घाटे वाला कट नहीं।** Hedge सिर्फ़ profit (+$1) में या cycle बंद होने पर बंद होते हैं।
8. **Cycle बंद:**
   1. पक्का + खुले ≥ **+$6**
   2. main profit में और खुले ≥ **+$3**
   3. main घाटे में और खुले ≥ **+$5**
   4. खुले ≤ **−$60** (सीधा $, lot से गुणा नहीं — v8.9 से)
9. **Inputs (v9.0):**
   - Strategy = 6
   - `S6_LockArmUsd` = **2.0**, `S6_LockUsd` = 1
   - `S6_PendingAhead` = 5
   - `S6_CycleNetUsd` = 6, `S6_CycleTP_Usd` = 3, `S6_BasketTP_Usd` = 5
   - `S6_BasketSL_Usd` = 60
   - `S6_LiveOn` = true, `S6_LiveKey` = s6, `S6_LivePushSec` = 5
   - FirebaseAuth (सिर्फ़ MT5 में)

**सीधी गिरावट का पक्का हिसाब** (Exness XAUUSDm, 0.01 lot = $1/point, spread $0.20):
- 5 SELL खुलने के बाद, main से **17.0 point** नीचे (4000 → bid 3983.000), basket +$5 पर cycle बंद।
- main −$34; SELLs +13.8 +10.8 +7.8 +4.8 +1.8; कुल **+$5.00**।

---

## 4. Version इतिहास
| version | बदलाव |
|---|---|
| v8.3–v8.5 | pending STOP, नीचे से बंद, 4b, 5 pending आगे |
| v8.6 | market re-open हटाया, 1.5 point दूरी, Basket SL 60 |
| v8.7 | S6 LIVE app data (26 Nov 22:16 IST — रात भर यही चला) |
| v8.8 | जोड़ी lock नया hedge भरते ही |
| v8.9 | app upload EA नहीं रोकता, Basket SL सीधा $ |
| v9.0 | app का CHECK tab data (algo, ping, margin, गलतियाँ, HAAL) — trade नियम v8.9 जैसे |
| (v9.1–v9.3) | हटाए गए (user को पसंद नहीं) |
| **v10.1** | नया प्लान: main 0.01, सब target $2, दूसरा BUY main के भाव पर, SL 60 |

रात v8.7 और सुबह v8.9 / v9.0 पर profit (200 → 245):
- 26 Nov 22:57 TP +$6
- 23:34 → 05:31 CYCLE +$3.09
- 07:38 CYCLE +$3.11
- 09:02–10:59: +$12.91, +$6, +$6, +$6, +$6, +$6

---

## 5. आज़माकर हटाया गया (दोबारा मत आज़माना, जब तक user न कहे)
v9.1–v9.3 में ये आज़माए गए। Demo पर user को पसंद नहीं आए (sideways में 208 → ~200), इसलिए हटाए:
1. "जोड़ी −$2 पर घाटे में कट"
2. lock +$1.20
3. pending reject / ताज़ा भाव वाले तकनीकी fixes
4. "नया hedge सिर्फ़ सबसे गहरे से आगे"

Backtest (research) में ये भी कमज़ोर निकले:
1. trailing lock (हर रूप)
2. "हर hedge खुद बंद"
3. STOP + LIMIT से ठीक level
4. "hedge न हो तो reset"
5. हर hedge +$1 TP
6. 2-hedge तरीका
7. overlap close
8. recovery mode
9. gap $4 / $5
10. तिकड़ी
11. मदद वाला BUY 0.01

पूरे नंबर `STATE.md` में हैं।
**सबक:** sideways (ऊपर-नीचे) बाज़ार इस strategy के लिए सबसे बुरा है। अगला सुधार शायद **"main trade कब लें" (समय / हालात)** में है, नियमों में नहीं।

---

## 6. VPS Helper: नया EA VPS पर कैसे पहुँचता है
**File:** `Samusignal/vps-helper/SamuVpsHelper.ps1` (v1.07)। Install script: `vps-helper/install.ps1`।

**Install (VPS पर एक बार):** VPS पर PowerShell खोलकर ये एक line चलाओ:
```
[Net.ServicePointManager]::SecurityProtocol='Tls12';iex(iwr https://raw.githubusercontent.com/ankushchhajed7-cmd/samusignal/main/vps-helper/install.ps1 -UseBasicParsing).Content
```
ये तीन काम करता है:
- `C:\SamuVpsHelper` में helper रखता है।
- Windows Task Scheduler में **"SamuVpsHelper"** task बनाता है (हर 2 min, छुपा हुआ)।
- एक बार तुरंत चलाकर नतीजा दिखाता है।

**ये हर 2 min में क्या करता है:**
1. GitHub repo `samusignal` की **main** branch पर नया commit आया? तो `vps-ea/` और `copytrade-ea/` की हर `.mq5` file VPS के **हर MT5 terminal** के `MQL5\Experts` में copy करता है।
2. हर terminal के **MetaEditor से compile** करता है और errors पढ़ता है। `.ex5` files सीधे copy होती हैं, compile नहीं।
3. `vps-files/*.json` → हर terminal के `MQL5\Files` में।
4. Report बनाता है (compile नतीजा, Experts log की आखिरी lines, RAM): `<Common>\Files\SamuCopy\vps.json`।
5. ये report **CopyTrade Bridge EA (v1.02+)** Firebase `/copytrade/vps` पर भेजता है। App में दिखता है:
   - S6 LIVE → 🩺 CHECK → "VPS Helper · compile"
   - पुराने app में COPY tab → "VPS Helper" card
6. अपना नया version भी GitHub से खुद ले लेता है।

**नया EA version VPS पर भेजने का तरीका (हर बार):**
1. नई file `vps-ea/PERSONAL FX v10.x - GRID.mq5` (अगला: v10.2) repo में commit → PR → **main में merge**।
2. ~2 min में Helper उसे हर terminal के `MQL5\Experts` में डालकर compile कर देगा।
3. **Chart पर लगाना user का काम है।** Helper कभी trade नहीं करता, chart पर EA नहीं लगाता या हटाता, MT5 restart नहीं करता।
   - MT5 में Navigator → Expert Advisors → नया version chart पर लगाओ (inputs जाँचकर)।
4. Compile OK हुआ या नहीं: app CHECK में देखो, या VPS पर `C:\SamuVpsHelper\helper.log`।

**अभी की समस्या:** app में VPS Helper report ~55 दिन पुरानी (v1.02) दिख रही है। मतलब Helper task नहीं चल रहा, या Bridge EA किसी chart पर नहीं लगा।

ठीक करने के लिए:
1. VPS पर Task Scheduler में "SamuVpsHelper" है और चालू है, ये जाँचो। नहीं है तो ऊपर वाली install line दोबारा चलाओ।
2. CopyTrade Bridge EA (v1.02+) किसी chart पर लगाओ। ये report Firebase तक भेजता है।
3. तब तक नया EA हाथ से डालना होगा: file download → `MQL5\Experts` में रखो → MetaEditor में F7 (compile)।

**Helper हटाना हो तो** (PowerShell में):
```
Unregister-ScheduledTask -TaskName SamuVpsHelper -Confirm:$false
```

---

## 7. बाकी काम / खुले सवाल
1. **v10.1 chart पर लगाना** (user):
   - पुराना EA हटाओ, v10.1 लगाओ।
   - Inputs जाँचो (ऊपर 3.7)।
   - Main 0.01 हाथ से।
   - चलता cycle (0.02 main वाला) पहले बंद होने दो, फिर बदलो।
2. **VPS Helper report ~55 दिन पुरानी (v1.02):** Helper / Bridge EA चालू करना है, ताकि compile नतीजा app CHECK में दिखे। तब तक file हाथ से।
3. **News नियम:** high-impact news के ±30 min नया main trade न लेना। पूरा block या सिर्फ़ चेतावनी? User का जवाब बाकी।
4. **Sideways / chop से बचाव:** main trade कब लें (समय या हालात)। ADX/ATR filter से फ़ायदा नहीं मिला। नया सोचना है।
5. App में दूसरा BUY अलग row में दिखाना (ज़रूरत हो तो, अगला app version)।
6. App की सुधार सूची (Firebase `notes`): net DD दिखाना, Friday close का नियम, SL 0 पर "test mode" वगैरह।
7. पुराने pending: AI AUTO v1.14, "top up small pack", XM real status।
8. User S6 की कुछ जानकारी **SAMUSIGNAL AI** app में भी डालना चाहता है → नीचे section 9 देखो।

---

## 8. SamuSignal app (पुराना मुख्य app)
- Repo **`ankushchhajed7-cmd/Samusignal`** (public), GitHub Pages से चलता है (main branch की root)।
- Files: `index.html` (पूरा app, ~800 KB), `sw.js` (`VERSION = '10.9.3'`, cache `samusignal-v10-9-3`), `manifest.json`, `kavach.js` (tests)
- Version बदलना: `index.html` का `VERSION` + `sw.js` का `VERSION` दोनों एक जैसे।
- काम:
  - forex / crypto signal (ADX, 4H / Daily confluence), Trade tracker, Alerts, Trading Gyaan
  - COPY tab (VPS Helper card), MT5 order भेजना (Firebase `/personalfx/orders`, `/personalfx/accounts`)
  - Settings: TwelveData key, Gemini key (AI Analysis), Data source (MT5 feed / TwelveData)
  - **"🔑 SAMUSIGNAL AI (naya app) ke liye keys"**: सारी keys एक code में (`SAI1:` + base64 JSON) → नए app में paste। Chat / WhatsApp में मत भेजना।
- इसी repo में सारे EA (`vps-ea/`), VPS Helper (`vps-helper/`), VPS scanner (`vps-scanner/scanner.mjs` v1.13), `STATE.md` (सब versions की table "Abhi ka version")।

---

## 9. SAMUSIGNAL AI app (नया app)
- Repo **`ankushchhajed7-cmd/SAMUSIGNAL-AI`** (public), GitHub Pages: `https://ankushchhajed7-cmd.github.io/SAMUSIGNAL-AI/`
- **Version 1.38.0** — तीन जगह एक जैसा रखना: `src/app.js` (`VERSION`), `sw.js` (`VERSION`), `package.json`। `tests/version.test.mjs` जाँचता है।
- अपना `STATE.md` है (हर version का इतिहास) — काम से पहले पढ़ो।
- Tests: `npm test` (engine, flow, sentinel, version…), news अलग: `node --test tests/news.test.mjs tests/newsbrief.test.mjs`। कुल ~84 pass।
- **Pages:**
  1. `index.html` + `src/app.js`: चार्ट signal (सिर्फ़ BUY / SELL LIMIT, Grade A/B/C; 15m + 1H trend → impulse → Fib 50–61.8%; SL 78.6% पार; TP 1R/2R/3R; 60 min valid), 📋 Scanner (सारे pair), History, 🚀 MT5 पे लगाओ (`/personalfx/orders` → PERSONAL FX EA), ✋ मैंने trade लिया, Gemini AI (दूसरी राय + screenshot से signal), Council, Order Flow
  2. `news.html` (`src/news.js`, `newsrules.js`, `newsbrief.js`): NEWS SIGNAL — USD high news पर XAUUSD / EURUSD signal, MT5 calendar (News Pusher EA v1.03 → `/feed/news/*`), paper trade, 🤖 AI tab (Gemini + Google Search)
  3. `sentinel.html` (`src/sentinel.js`, `sentinelrules.js` 1.1.0): 🛡️ FX SENTINEL — 7 major + XAUUSD, score 0–100, सिर्फ़ PAPER; VPS scanner v1.13 app बंद होने पर भी चलाता है। Firebase `/sentinel/vps`, `/sentinel/radar`, `/sentinel/paper/*`, `/sentinel/daily/*`, `/sentinel/cfg`। रोज़ 21:55 IST report (`tools/sentinel-report.mjs` + workflow "Sentinel Daily Report")
  4. Candle page v1.36.0 में हटाया (`candlerules.js` Pages पर रहता है — scanner इस्तेमाल करता है)
- **Data:** MT5 Data Feed EA (Firebase `/feed`, Exness भाव) → न मिले तो TwelveData।
- **Keys:** repo में कोई key नहीं। SamuSignal app की localStorage (`samu_*`) से या "SAI1:" code paste से। localStorage `sai_*`।
- VPS scanner (`Samusignal/vps-scanner/scanner.mjs`) इसी app का engine (`src/{symbols,data,engine,ai}.js`, `sentinelrules.js`, `candlerules.js`) GitHub Pages से हर 6 घंटे लेता है। इसलिए इन files को बदलना = VPS scanner का बर्ताव भी बदलना।
- **S6 जानकारी SAMUSIGNAL AI में डालनी हो तो** (user का इरादा, अभी कुछ नहीं बना):
  - S6 का live data Firebase `/personalfx/s6live/s6/` में है (`hb`, `live/<pair>`, `events`, `cycles`, `notes`) — S6 LIVE app (`GRID-STARTAGY-2/index.html`) यही पढ़ता है।
  - सबसे आसान: SAMUSIGNAL AI में नया अलग page (जैसे `s6.html`) जो यही path पढ़े, या home पर S6 LIVE app का link button। बाकी app मत छूना (जैसे news / sentinel page अलग बने)।
  - App version bump (1.39.0) तीनों files में + sw SHELL में नई files।
  - पहले user से पूछो कि कौन सी जानकारी दिखानी है (live P/L, cycles, नियम, backtest), फिर Final पर बनाओ।
