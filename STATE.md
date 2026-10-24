# SamuSignal — STATE

Har push ke saath ye file update hoti hai: kaun sa version, settings, faisle, aur kya baaki hai.

## Abhi ka version

| Cheez | Version | File |
|---|---|---|
| SamuSignal app (PWA) | **10.5.1** | `index.html`, `sw.js` |
| PERSONAL FX EA | **5.9** | `vps-ea/PERSONAL FX v5.9 - GRID.mq5` |
| Tithi Gold EA | **2.06** | `vps-ea/Tithi Gold v2.06.mq5` |
| BTC Trailing Manager (Buster ke liye) | **1.03** | `vps-ea/BTC Trailing Manager v1.03.mq5` |
| Investor Account Watcher (INVESTOR-ID repo) | **1.04** | `vps-ea/Investor Account Watcher v1.04.mq5` |
| MEXA SCALP Signal EA (MEXA-SCALP repo, sirf signal + push, koi trade nahi) | **1.00** | `vps-ea/MEXA SCALP Signal EA v1.00.mq5` |
| MEXA SCALP Trade EA (MEXA-SCALP repo, AUTO TRADE — cooldown + M15 trend filter + profit lock, demo / Strategy Tester) | **1.02** | `vps-ea/MEXA SCALP Trade EA v1.02.mq5` |
| ARADHAYA SCALPER (multi engine gold scalper + manager; v1.00 LIVE NA chalayein) | **2.05** | `vps-ea/ARADHAYA SCALPER v2.05.mq5` |
| Kavach test | 256 test (26 pair test PASS; 14 purane FAIL v10.3.0 se chale aa rahe — neeche dekho) | `kavach.js` |

## ARADHAYA SCALPER v2.05 — default preset SL20 (24 Oct 2026)

- **Test (M1, 30000, v2.04 niyam + EMA veto):** 2000 par 0.01 + SL 8% → +7.9% / DD 25.7% / 5 SL (July −18.5%). Wahi 2000 + **Group SL 20%** → **+45.8% / DD 15.8% / SL 0** (spread 0.35: +44.7% / 16.0%). 4000 + SL 20% = DD10 jaisa (+29.0% / 7.9%).
- **Faisla (Ankush):** 2000 par 0.01 + SL 20%, baaki sab same. Naya preset **SL20 = default**: E2 only, 2 level, TP 4.5, EMA veto, AutoPer 2000, Group SL 20%, din loss 20%, emergency 25%.
- Dhyaan: in 6 mahine me floating max ~16% gaya; SL laga to ek jhatke me ~20% (30000 par ~6000). Demo 2–4 hafta pehle.

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
