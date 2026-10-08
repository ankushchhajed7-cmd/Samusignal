# SamuQuant research — kya test hua, kya mila

**Nateeja: EURUSD / XAUUSD ke liye koi bhi niyam pehle se tay shartein pass nahi kar paya.**
Live signal ka safety lock (`quant/signal.mjs`) isi wajah se band hai.

## Tareeka (overfitting se bachne ke liye)
- Data: Dukascopy H1, bid + ask. EURUSD 2008 se, XAUUSD 2010 se. Weekend ki flat candles hatayi.
- Teen hisse: **DEV 2008–2018** (idea banana), **VAL 2019–2022** (shortlist jaanchna), **HOLD 2023→** (sirf ek baar).
- Pass shartein pehle likhi gayi: `PREREG.md`.
- Kharcha: EURUSD 1.2 pip (asli bid/ask test me spread + 0.9 pip), XAUUSD $0.35 round-trip.

## Kya test hua (DEV par)
| Idea | Nateeja |
|---|---|
| Asia range breakout + trend t-score (pehli strategy) | DEV aur OOS dono negative (−0.03R/trade) |
| Time-series momentum (20/60/120/250 din, weekly 4/12/26/52 hafte) | t < 2.1, aas-paas ke settings kamzor |
| Daily reversal (1/3/5 din) | negative / bekaar |
| Intraday mean-reversion (z-score, Asia / poora din) | zyadatar negative |
| Intraday momentum (London subah → shaam) | negative |
| Ghante ka asar (hour-of-day) | Gold 20–23 UTC ka asar **nakli** — DST ke saath khisakta hai (rollover spread). Gold 02/05 UTC asli lagta hai par ~1 bp, kharcha ~2.7 bp |
| EURUSD Asia drift (01–04 UTC BUY) | bid/ask par t 2.4, VAL me khatam (t −0.14) |
| **Weekend gap fade** (gap ≥ 0.3%, 1 ghante baad ulti disha, 24 ghante / gap bharne tak) | EURUSD: DEV t 3.2, VAL +, HOLD + (har hisse me sirf ~8 trades). **Naye pairs pe fail** (neeche) |

## Aakhri jaanch: gap fade naye pairs par (niyam bilkul wahi, koi tuning nahi)
| Pair | DEV | VAL | HOLD |
|---|---|---|---|
| EURUSD (jahan chuna gaya) | +22.9 bp, t 3.48 | +16 bp | +7.8 bp |
| AUDUSD | −15.5 bp | +26 bp | +13 bp |
| USDJPY | +3.3 bp | −12 bp | −15 bp |
| GBPUSD | −21.8 bp | +15 bp | +33 bp |
| **Naye 3 milake** | **−10.8 bp** | +11.8 bp | +5.2 bp |

Sign-flip permutation p = **0.83**. Matlab EURUSD ka accha nateeja ek pair ki kismat thi; ~100 variations test karne par
ek-do ka t > 3 aana aam baat hai (multiple testing).

## Data ki galtiyan jo pakdi gayi
1. Weekend flat candles (o=h=l=c) trend/ATR bigaad rahi thi → hatayi.
2. Ask data ke kuch saal Dukascopy 429 ki wajah se gayab the → "gap" nakli dikh rahe the → sirf asli Friday→Sunday gap gine.

## Dobara chalana
```
cd quant/research
python3 screen.py            # DEV screening
python3 val1.py DEV          # bid/ask execution (VAL / HOLD bhi de sakte ho)
python3 multi_bid.py AUDUSD,USDJPY,GBPUSD
```

## Round 2 — US30 (Dow Jones CFD), 2013 se
Niyam pehle likhe (`PREREG.md`, Round 2): US30 par chuna niyam US500 aur US100 par bina badle chalna chahiye.
Kharcha: 3 points round-trip + raat ka financing (Fed rate + 2.5%).

| Idea (DEV 2013–2019) | Per trade | t | Faisla |
|---|---|---|---|
| Buy & hold (financing ke saath) | +3.8 bp/din | 1.41 | kamzor |
| Raat ki drift (16:00 → 09/10:00 ET) | +1.1 / +1.8 bp | 0.55 / 0.86 | financing kha jaata hai |
| Turn-of-month (4 variants) | +18…+32 bp | 0.5–0.8 | trade kam, sabit nahi |
| Intraday momentum (10:00 ET disha → aakhri ghanta) | −2.3 bp | −2.87 | ulta; ulta karne par bhi kharcha zyada |
| 200-din MA long-only | +0.8 bp | 0.44 | bekaar |
| Din (Mon–Fri) | — | < 1.4 | kuch nahi |
| Ghanta (NY) | 17:00 ET t −3.5 | — | CFD rollover ka spread asar, nakli |

DEV me hi koi idea t > 2 (sahi disha me) nahi aaya, isliye VAL/HOLD khole hi nahi. US30 pe bhi koi strategy pass nahi.

Dobara chalana: `HIST=../history python3 idx_screen.py USA30IDXUSD DEV`

## Round 3 — hedge-fund style portfolios (Yahoo daily, 2000–2026, 36 markets)
Parameters research papers se (Hurst-Ooi-Pedersen trend, Menkhoff FX momentum, risk parity) — tune nahi kiye.
Universe: 13 indices (Nifty/Sensex samet), 4 US bond futures, 7 FX, gold/silver/copper, Brent, 8 agri.
Kharab roll data wale (crude WTI, nat gas, hogs, gasoline, heating oil, platinum) pehle hi bahar.
Do venue: **CFD** (2.5% financing markup) aur **futures** (exchange, markup nahi — India me legal raasta NSE/MCX).

| Strategy (futures venue, 10% vol) | DEV 2000–12 | VAL 2013–18 | HOLD 2019–26 |
|---|---|---|---|
| S1 trend-following (CTA) | +3.0%, SR 0.19 | −2.5% | +0.9% |
| S2 FX cross-sectional momentum | −1.9% | +0.5% | +1.2% |
| S3 risk parity long-only (indices+bonds+gold) | +5.3%, SR 0.51 | +5.7%, SR 0.53 | +7.4%, SR 0.63, DD 32% |
| S&P 500 buy & hold (tulna) | +2.2% (DD 54%) | +8.4% | +18.3% |

CFD venue par teeno negative (financing ~3x gross pe 7%+ saalana kha jaata hai).
Bug jo pakda: shuruaat me 1–2 market pe vol-scaling 5x ho gaya tha (Jan 2000 me nakli −60%) → warm-up rule.
Note: debug ke dauran S1 ke VAL/HOLD saal-dar-saal number dikh gaye the (PREREG.md me likha).

**Nateeja:** koi *trading* edge pass nahi. Sirf S3 (diversified long-only, risk barabar) teeno periods me positive —
ye trading hack nahi, investment hai (risk premia), aur 2022 me ~30% gira. Pre-registered DD < 25% shart (10% vol pe) fail.

Dobara chalana: `python3 fetch_yahoo.py` (Actions) phir `python3 porty.py DEV,VAL,HOLD`
