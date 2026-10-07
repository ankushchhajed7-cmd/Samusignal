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
