# Pre-registration (written before looking at any 2019+ data in this research round)
Splits: DEV 2008-01-01..2018-12-31 | VAL 2019-01-01..2022-12-31 | HOLDOUT 2023-01-01..end (touched ONCE)
Costs: EURUSD 1.2 pip round trip, XAUUSD $0.35 round trip (+ swap ignored for intraday; daily-hold strategies charged 0.5 pip / $0.10 per day carry proxy)
Pass (all required):
 1. HOLDOUT expectancy > 0 after costs, PF >= 1.15
 2. HOLDOUT significance p < 0.05 (sign-flip permutation on trades or t-stat of daily returns > 1.96)
 3. DEV and VAL both positive (PF > 1.05)
 4. Parameter neighbourhood: >= 70% of neighbouring cells positive on DEV
 5. Monte Carlo 95th pct max DD at 1% risk/trade < 25%
Multiple testing: number of hypotheses tried is recorded and reported.
LOCKED after DEV (before VAL): C2 EURUSD weekend gap fade thr=0.003 delay=1 hold=24, target=Friday close. C1 rejected.
HOLDOUT run once for C2 thr=0.003 delay=1 hold=24

# ROUND 2 — US indices (written before any index data was downloaded)
Instruments: US30 (usa30idxusd) primary; US500, US100 = replication (rule must work there UNCHANGED).
Splits: DEV 2013-01-01..2019-12-31 | VAL 2020-01-01..2022-12-31 | HOLD 2023-01-01..end (once).
Costs: spread+slippage round trip US30 3 pts, US500 0.75 pt, US100 2 pts (or real bid/ask when available);
long overnight financing = (Fed funds yearly avg + 2.5%)/360 per night held over 21:00 UTC.
Pass (all): US30 HOLD PF>=1.15 & positive; US30 DEV+VAL positive; replication on US500 AND US100 positive in
DEV, VAL and HOLD; pooled (3 indices, VAL+HOLD) t > 2; MC 95% DD at chosen sizing < 25%.
Also report vs buy-and-hold (same instrument, same costs).
