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

# ROUND 3 — hedge-fund style multi-asset portfolios, DAILY data (written before data arrived)
Universe: 27 markets (13 FX, XAU, XAG, WTI, Brent, Copper, US T-Bond, Bund, US500, US100, US30, GER40, FRA40, UK100, JPN).
Splits: DEV 1990-2009 | VAL 2010-2017 | HOLD 2018-2026 (once).
Parameters taken from published literature, NOT tuned:
 S1 TSMOM/CTA (Hurst-Ooi-Pedersen 2017): signal = mean(sign(r_1m), sign(r_3m), sign(r_12m)); per-market weight
    = signal * (10% / ann.vol_60d EWMA); portfolio scaled to 10% ann vol (using trailing 1y portfolio vol); weekly rebalance.
 S2 FX cross-sectional momentum (Menkhoff et al. 2012): rank FX vs USD by 12-1m return, long top 3 / short bottom 3, monthly.
 S3 Risk parity long-only (indices+bonds+gold), inverse-vol weights, monthly, 10% vol target.
Costs per unit turnover: FX majors 1bp, FX crosses 2bp, metals 3bp, energy 5bp, copper 5bp, indices 2bp, bonds 2bp.
Financing: 2.5%/yr on gross notional held (CFD markup), both long and short. FX carry ignored (no rate data).
Pass (all): HOLD Sharpe > 0.4 and return > 0; DEV and VAL Sharpe > 0.3; full-period t > 2;
max drawdown < 25% at 10% vol target; performance not dependent on a single asset class (drop-one-class test).

# ROUND 3b — same strategies (S1 TSMOM, S2 FX xs-mom, S3 risk parity) on YAHOO daily data (written before running)
Universe (36): indices ^GSPC ^NDX ^DJI ^RUT ^GDAXI ^FCHI ^FTSE ^N225 ^HSI ^AXJO ^STOXX50E ^BSESN ^NSEI;
bonds ZN ZB ZF ZT; FX spot EURUSD GBPUSD USDJPY AUDUSD USDCAD USDCHF NZDUSD; metals GC SI HG; energy BZ;
ags ZC ZW ZS KC SB CT CC LE.
Excluded BEFORE results for bad roll data (>5 daily jumps >15%): CL NG HE RB PL HO(5 kept out too).
Splits: DEV 2000-2012 | VAL 2013-2018 | HOLD 2019-2026 (once). Same literature parameters, no tuning.
Costs per turnover: FX 1bp, index 2bp, bond 2bp, metal 3bp, energy 5bp, ags 8bp. Financing 2.5%/yr on gross.
Same pass criteria as Round 3.
NOTE (after DEV run of 3b): CFD cost model (2.5% financing markup on ~3x gross) makes S1 negative on DEV although
gross signal positive. Adding a SECOND venue scenario = exchange-traded futures (how CTAs/hedge funds trade it,
and the legal route for an Indian resident: NSE/MCX): financing markup 0, same turnover costs. CFD result is kept
and reported as FAIL. Pass criteria unchanged.
BUGFIX (no tuning): warm-up — trade only when >=50% of markets have signals. Debug table exposed VAL/HOLD yearly S1 numbers before this run; noted.
