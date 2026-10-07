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
