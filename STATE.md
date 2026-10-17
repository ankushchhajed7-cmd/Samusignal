# SamuSignal — STATE

Har push ke saath ye file update hoti hai: kaun sa version, settings, faisle, aur kya baaki hai.

## Abhi ka version

| Cheez | Version | File |
|---|---|---|
| SamuSignal app (PWA) | **10.5.0** | `index.html`, `sw.js` |
| PERSONAL FX EA | **5.9** | `vps-ea/PERSONAL FX v5.9 - GRID.mq5` |
| Tithi Gold EA | **2.06** | `vps-ea/Tithi Gold v2.06.mq5` |
| Kavach test | 254 test (24 naye pair test PASS; 14 purane FAIL v10.3.0 se chale aa rahe — neeche dekho) | `kavach.js` |

## v10.5.0 — PAIR TRADING tab (17 Oct 2026)

Naya **PAIR** tab (bottom nav me 7th, ⚖️). Baaki saare tab waise hi. **Sirf app me signal** — MT5 ko kuch nahi jaata, Telegram nahi (Ankush ka faisla).

- **Pairs (sab default ON):** Gold/Silver (XAU/XAG), EURUSD/GBPUSD, AUDUSD/NZDUSD, EURUSD/USDCHF (ulti), EURJPY/GBPJPY, AUDJPY/NZDJPY, AUDCAD/NZDCAD, EURAUD/EURNZD, BTC/ETH. Apni jodi bhi add/delete ho sakti hai.
- **Timeframe:** H1 ya H4 (chip). 220 candle laata hai, cache H1 15 min / H4 45 min.
- **Ganit:** log price pe OLS → β (hedge), spread = logA − β·logB − α, Z = spread / std (last *lookback* candle). Correlation candle **return** se (price wala jhootha high dikhata hai). Half-life = AR(1) se.
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
- [ ] TwelveData free plan pe XAG/USD aata hai ya nahi, phone pe confirm karo (na aaye to Gold/Silver card pe ERROR dikhega).

- [ ] PERSONAL FX v5.9 MetaEditor me compile karke VPS pe lagana (yahan compile nahi ho sakta).
- [ ] Agar ab bhi zyada NO TRADE aaye: NO TRADE card ka screenshot dekh ke wajah (filter / AI confidence / leg jaanch) pakdo.
- [ ] 2–3 hafte Report Card bharne do, phir dekho WIN% (kis mode / pair / samay me achha).
- [ ] Kavach ke 14 purane FAIL (C, F, H, I, Q group) v10.3.0 se pehle ke hain — test purane niyam maante hain, app ke naye niyam alag. Alag se dekhna hai.
- [ ] EA restart ke beech batch ka dusra order aaye to wo pehle ko replace kar sakta hai (rare) — zarurat padi to order comment me batch id daalna.
