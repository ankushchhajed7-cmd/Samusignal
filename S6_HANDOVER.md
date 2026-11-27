# PERSONAL FX — Strategy 6 (Hedge Ladder): पूरा हाल — **नई शुरुआत v9.0 से** (27 Nov 2026 शाम)

नए Claude session / account के लिए handover। पहले ये file पढ़ो, फिर `STATE.md` (repo का पूरा इतिहास)।

> **User का फ़ैसला (27 Nov शाम):** v9.0 तक का सब रखो, उसके बाद के सारे बदलाव हटाओ — "यहाँ से नए स्टार्ट करूँगा"।
> इसलिए repo से EA v9.1 / v9.2 / v9.3 की files हटा दी गईं और app S6 LIVE v2.3.1 फिर v9.0 वाली settings को सही मानता है।
> अगला नया version (जो भी user बताए) **v9.1** नाम से नए सिरे से बनेगा।

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
| **EA (अभी का, आखिरी)** | `Samusignal/vps-ea/PERSONAL FX v9.0 - GRID.mq5` |
| इतिहास / हर version का कारण | `Samusignal/STATE.md` |
| Backtest simulator (research) | `Samusignal/research/s6_bt2.py` + `.github/workflows/s6-research.yml` (branch `ccr-de58b3c2-9qoj0z` पर push होते ही असली gold GC=F 1m 7 दिन + 5m 60 दिन; local: `python3 research/s6_bt2.py --synthetic 1500`) |
| App **S6 LIVE** (PWA) v2.3.1 | repo `GRID-STARTAGY-2/index.html` — LIVE · LADDER · RISK · HISTORY · 🩺 CHECK · SETUP; LIVE में 🔮 आगे का अंदाज़ा; CHECK में 📝 सुधार सूची; `?demo=1` |
| Live data जाँच (public log) | repo `INVESTOR-ID/.github/workflows/feed-check.yml` → `S6_HB / S6_DIAG / S6_ERR / S6_HAAL / S6_LIVE / S6_HEDGES / S6_PEND / S6_EV / S6_CY / S6_NOTE` |
| Firebase | `/personalfx/s6live/<S6_LiveKey=s6>/` → `hb`, `live/<pair>`, `events`, `cycles`, `notes` |

---

## 3. v9.0 के trade नियम (= v8.9 के नियम + app का CHECK data)
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

## 4. Version इतिहास (v9.0 तक)
| version | बदलाव |
|---|---|
| v8.3–v8.5 | pending STOP, नीचे से बंद, 4b, 5 pending आगे |
| v8.6 | market re-open हटाया, 1.5 point दूरी, Basket SL 60 |
| v8.7 | S6 LIVE app data (26 Nov 22:16 IST — रात भर यही चला) |
| v8.8 | जोड़ी lock नया hedge भरते ही |
| v8.9 | app upload EA नहीं रोकता, Basket SL सीधा $ |
| **v9.0** | app का CHECK tab data (algo, ping, margin, गलतियाँ, HAAL) — trade नियम v8.9 जैसे |

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
1. नई file `vps-ea/PERSONAL FX v9.x - GRID.mq5` (अगला: v9.1 नए सिरे से) repo में commit → PR → **main में merge**।
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
1. **News नियम:** high-impact news के ±30 min नया main trade न लेना। पूरा block करना है या सिर्फ़ चेतावनी? User का जवाब बाकी।
2. **Sideways / chop से बचाव:** main trade कब लें (समय या हालात)। पहले के test में ADX/ATR filter से फ़ायदा नहीं मिला। नया सोचना है।
3. **VPS Helper report ~55 दिन पुरानी (v1.02):** Helper / Bridge EA चालू करना है, ताकि compile नतीजा app CHECK में दिखे।
4. Chart पर **v9.0** लगाना (inputs जाँचकर)। VPS पर पुरानी v9.1–v9.3 files Experts folder में रह सकती हैं, उन्हें इस्तेमाल नहीं करना।
5. User अगला नया प्लान बताएगा: पहले backtest, फिर Final पर **v9.1** (नए सिरे से)।
6. App की सुधार सूची (Firebase `notes`) में बाकी points हैं: net DD दिखाना, Friday close का नियम, SL 0 पर "test mode" वगैरह।
7. पुराने pending काम: AI AUTO v1.14, "top up small pack", XM real status।
