# PERSONAL FX — Strategy 6 (Hedge Ladder): पूरा हाल (27 Nov 2026)

नए Claude session / account के लिए handover। पहले ये file पढ़ो, फिर `STATE.md` (repo का पूरा इतिहास)।

---

## 0. ताज़ा फ़ैसला (27 Nov शाम): v9.2 छोड़ा, v9.0 वाले नियमों पर वापसी
- User को v9.2 demo पर पसंद नहीं आया: sideways बाज़ार (3670–3681) में "जोड़ी −$2" कटों से balance 208 → ~200।
- User का अच्छा profit (200 → 245) **रात v8.7** और **सुबह v8.9 / v9.0** पर आया (उस समय तक −$2 कट और +$1.20 lock नहीं थे)।
- Version का समय (IST):

| version | समय |
|---|---|
| v8.6 | 26 Nov 20:58 |
| **v8.7** | **26 Nov 22:16 (रात भर यही चला)** |
| v8.8 | 27 Nov 08:31 |
| v8.9 | 27 Nov 08:44 |
| **v9.0** | **27 Nov 08:54** |
| v9.1 / v9.2 | दिन में |

- रात / सुबह के cycles:
  - 26 Nov 22:57 TP +$6
  - 23:34 → 05:31 CYCLE +$3.09
  - 07:38 CYCLE +$3.11
  - 09:02–10:59: +$12.91, +$6, +$6, +$6, +$6, +$6
  - (07:54 SELL 3613 cycle v8.7 bugs के कारण −$11.27 हाथ से, DD −$67 — v8.8 / v8.9 में ठीक)

### v9.0 के trade नियम (= v8.9; सिर्फ़ app का CHECK data जुड़ा)
उदाहरण main BUY 0.02 @ 4000, SELL 0.01 हर 3 point:

1. **Main:** हाथ का trade। अकेला हो तो TP **+$6** (4003)। Hedge खुलते ही TP हटता है।
2. **Hedge levels:** 3997, 3994, 3991… (हर $3 / 0.01)।
3. **Pending:** आगे के **5** खाली levels पर STOP। खुले hedge से **1.5 point** के अंदर नहीं।
4. **4b:** बंद hedge अपने बंद भाव पर दोबारा (level से 1.5 point तक)। भाव level के पार लौटे तो ठीक level।
5. **Lock:** hedge **+$2** पार करे → lock, **+$1** पर बंद। **सबसे दूर वाला पहले** (LIFO)।
6. **जोड़ी:** सबसे दूर वाले का lock न हो तो आखिरी 2 मिलकर +$1 पार करें, फिर **+$1** पर दोनों बंद। v8.8 से: नया hedge भरते ही जोड़ी > +$1 हो तो उसी पल चालू।
7. **कोई घाटे वाला कट नहीं** (जोड़ी −$2 v9.1 में आया था, v9.0 में नहीं)।
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
10. v9.0 में v9.2 वाले bug fixes **नहीं** हैं:
    - pending लगाते समय ताज़ा भाव / reject इलाज
    - पहले pending हटाना
    - सिर्फ़ इसी cycle का पक्का
    - hedge न हो तब भी SL

### दो रास्ते (user ने अभी चुनना है)
1. **`PERSONAL FX v9.0 - GRID.mq5`** chart पर लगाओ (रात / सुबह वाले नियम ज्यों के त्यों)।
2. **`PERSONAL FX v9.2 - GRID.mq5`** रखो, बस inputs **`S6_PairLossUsd = 0`** और **`S6_LockArmUsd = 2.0`** = v9.0 के trade नियम + v9.2 bug fixes। (मेरी सलाह)

- App S6 LIVE v2.4.0 का CHECK अभी lock 1.2 और ploss 2 को "सही" मानता है। v9.0 नियम पर 🔴 दिखाएगा। चाहें तो app के `WANT` में arm 2 / ploss 0 करना (छोटा बदलाव)।

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

## 2. Repos और files
| चीज़ | जगह |
|---|---|
| EA — **user की पसंद अब v9.0 वाले नियम** (देखो section 0) | `Samusignal/vps-ea/PERSONAL FX v9.0 - GRID.mq5` (या v9.2 file, 2 inputs बदलकर) |
| EA v9.2 (user ने छोड़ा) | `Samusignal/vps-ea/PERSONAL FX v9.2 - GRID.mq5` |
| EA v9.3 (v9.2 + `S6_NextOnlyDeeper`, test के लिए) | `Samusignal/vps-ea/PERSONAL FX v9.3 - GRID.mq5` |
| इतिहास / हर version का कारण | `Samusignal/STATE.md` |
| Backtest simulator | `Samusignal/research/s6_bt2.py` + workflow `.github/workflows/s6-research.yml` (branch `ccr-de58b3c2-9qoj0z` पर push होते ही असली gold GC=F 1m 7 दिन + 5m 60 दिन पर चलता है; local: `python3 research/s6_bt2.py --synthetic 1500`) |
| App **S6 LIVE** (PWA) v2.4.0 | repo `GRID-STARTAGY-2/index.html` (tabs: LIVE · LADDER · RISK · HISTORY · 🩺 CHECK · SETUP; `?demo=1`) |
| Live data जाँच (public log) | repo `INVESTOR-ID/.github/workflows/feed-check.yml` → `S6_HB / S6_DIAG / S6_ERR / S6_HAAL / S6_LIVE / S6_HEDGES / S6_PEND / S6_EV / S6_CY / S6_NOTE` |
| Firebase | `/personalfx/s6live/<S6_LiveKey=s6>/` → `hb`, `live/<pair>`, `events`, `cycles`, `notes` (सुधार सूची) |

---

## 3. v9.2 के नियम (27 Nov दोपहर का Final — शाम को user ने छोड़ा, section 0)
उदाहरण: **main BUY 0.02 @ 4000** (हाथ से), gold Exness XAUUSDm (0.01 lot = $1/point, spread ~$0.20)।

1. **Main:** pair पर सबसे पुराना हाथ वाला trade। अकेला हो तो TP **+$6** (4003)।
2. **Hedge levels:** हर **3 point** पर उल्टा **0.01**: 1 नंबर 3997, 2 नंबर 3994, 3 नंबर 3991…
3. **Pending:** भाव के आगे के **5** खाली levels पर SELL STOP। किसी खुले hedge से **1.5 point** के अंदर नहीं। भाव से कम से कम 2× spread दूर। Broker reject करे तो उस level पर 10 sec रुकना।
4. **4b दोबारा खुलना:** बंद हुआ hedge अपने बंद भाव पर दोबारा खुलता है (level से 1.5 point तक गहरा)। भाव level के पार लौटे तो ठीक level पर।
5. पहला hedge खुलते ही **main का TP हट जाता है।**
6. **Lock:** hedge **+$1.20** पार करे → lock, **+$1** पर बंद। सिर्फ़ **सबसे दूर वाला पहले** बंद होता है (LIFO)।
7. **जोड़ी नियम** (सबसे दूर वाले का lock चालू न हो): आखिरी 2 मिलकर **+$1** → दोनों बंद। मिलकर **−$2** → दोनों घाटे में बंद (`S6_PairLossUsd` = 2)।
8. **Cycle बंद होने के नियम:**
   1. पक्का + खुले ≥ **+$6** (net)
   2. main profit में और खुले ≥ **+$3** (cycle)
   3. main घाटे में और खुले ≥ **+$5** (basket)
   4. खुले ≤ **−$60** (Basket SL, 0 = बंद; hedge न हो तब भी)
9. **बंद करते समय:** पहले pending हटते हैं, फिर trades। कोई trade बंद न हो तो हर second दोबारा कोशिश।
10. **Inputs:**
    - Strategy = 6
    - `S6_LockArmUsd` = 1.2, `S6_LockUsd` = 1
    - `S6_PairLossUsd` = 2
    - `S6_BasketSL_Usd` = 60
    - `S6_PendingAhead` = 5
    - `S6_CycleNetUsd` = 6, `S6_CycleTP_Usd` = 3, `S6_BasketTP_Usd` = 5
    - `S6_LiveOn` = true, `S6_LiveKey` = s6
    - FirebaseAuth भरा हुआ (सिर्फ़ MT5 में)

**सीधी गिरावट का पक्का हिसाब** (spread $0.20): 5 SELL खुलने के बाद, main से **17.0 point** नीचे (4000 → bid 3983.000), basket +$5 पर cycle बंद होता है।
- main −$34
- SELLs +13.8 +10.8 +7.8 +4.8 +1.8
- कुल = **+$5.00**

---

## 4. Version इतिहास (छोटा)
| version | बदलाव |
|---|---|
| v8.6 | market re-open हटाया, 1.5 point दूरी, Basket SL 60 |
| v8.7 | S6 LIVE app data |
| v8.8 | जोड़ी lock भरते ही |
| v8.9 | app upload EA नहीं रोकता, Basket SL सीधा $ |
| v9.0 | app का CHECK tab data (algo, ping, margin, गलतियाँ, HAAL) |
| v9.1 | जोड़ी −$2 पर बंद (G), lock +$1.20 (L12), pending reject इलाज |
| v9.2 | पूरे code review के bug fix: ताज़ा भाव, पहले pending हटाना, सिर्फ़ इस cycle का पक्का, hedge न हो तब भी SL, slot नंबर |
| v9.3 | `S6_NextOnlyDeeper` (नया hedge सिर्फ़ सबसे गहरे से आगे)। **User ने v9.2 Final रखा।** |

---

## 5. Backtest से क्या सीखा (असली gold, SL $60, प्रति cycle औसत)
| | 1m | 5m |
|---|---|---|
| **v9.2** | **$5.50**, SL 2 बार | **$5.76**, SL 0 बार |
| v9.0 | $4.27 | $5.29 |

v9.2 से **कमज़ोर** निकले, इसलिए नहीं जोड़े:
1. Trailing lock (सारे रूप):
   - $0.20 पीछे
   - $1 पीछे
   - 3/2/1 वाला
2. "हर hedge अपने lock पर खुद बंद" (सबसे दूर वाला पहले की जगह)।
3. "नया hedge तभी जब पहले वाले profit में हों" (v9.3): 1m $4.47, 5m बराबर।
4. STOP + LIMIT से ठीक level पर दोबारा खोलना: बहुत बुरा ($1.22)।
5. "hedge न हो तो pending ठीक $3 level पर": $4.65।
6. सीधा version (हर hedge +$1 TP): घाटे में (−$0.36)।
7. User का 2-hedge तरीका (2 नंबर +$1 → दोनों बंद): $0.82, SL 70 बार।
8. Overlap close ("close minus by plus", पक्के profit से चुकाना): लगभग बराबर ($5.47), SL थोड़ा ज़्यादा।
9. Cycle/basket को "पक्का + खुले" पर गिनना: cycle घाटे में बंद नहीं होता, पर औसत कम ($5.22)।

**चेतावनी:** random (synthetic) data पर v9.1/v9.2 कमज़ोर निकला। फ़ायदा gold के पलटने वाले स्वभाव पर टिका है।

---

## 6. Demo का असली हाल (27 Nov)
1. सुबह के cycles: कई +$6 / +$3 वाले cycle बंद हुए।
2. Cycle **BUY 3658.505** (v9.0/9.1): 46 hedge, DD −$75, user ने हाथ से −$0.45 पर बंद किया।
3. अभी का cycle **BUY 3680.342** (v9.2):
   - भाव 3670–3681 में ~1.5 घंटे ऊपर-नीचे हुआ।
   - जोड़ी −$2 से 4 कट (−$14.23), +$1 lock 7 बार (+$6.71)।
   - Balance 208 → ~200, **net −$9.67**।
   - Sideways बाज़ार इस strategy के लिए सबसे बुरा है। कोई test किया नियम इसे पूरा नहीं रोकता।
4. **Real account पर अभी नहीं।** पहले demo पर कई दिन net plus दिखना चाहिए।

---

## 7. VPS Helper: नया EA VPS पर कैसे पहुँचता है
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
1. नई file `vps-ea/PERSONAL FX v9.x - GRID.mq5` repo में commit → PR → **main में merge**।
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

## 8. बाकी काम / खुले सवाल
1. **News नियम:** high-impact news के ±30 min नया main trade न लेना। पूरा block करना है या सिर्फ़ चेतावनी? User का जवाब बाकी।
2. **Sideways / chop से बचाव:** main trade कब लें (समय या हालात)। पहले के test में ADX/ATR filter से फ़ायदा नहीं मिला। नया सोचना है।
3. **VPS Helper report ~55 दिन पुरानी (v1.02):** Helper / Bridge EA चालू करना है, ताकि compile नतीजा app CHECK में दिखे।
4. Demo पर v9.2 के 2–3 दिन के नतीजे app HISTORY से देखकर तय करना है।
5. App की सुधार सूची (Firebase `notes`) में बाकी points हैं: net DD दिखाना, Friday close का नियम, SL 0 पर "test mode" वगैरह।
6. पुराने pending काम: AI AUTO v1.14, "top up small pack", XM real status।
