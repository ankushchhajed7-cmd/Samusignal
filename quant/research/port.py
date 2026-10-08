"""Round 3: multi-asset portfolio strategies on daily data.
Usage: python3 port.py [SPLITS]   e.g. DEV  |  DEV,VAL  |  DEV,VAL,HOLD"""
import sys, os, numpy as np, pandas as pd
from lab import HIST

PSPLITS = {'DEV': ('1990-01-01', '2009-12-31'), 'VAL': ('2010-01-01', '2017-12-31'), 'HOLD': ('2018-01-01', '2100-01-01')}
CLS = {}
for m in 'EURUSD GBPUSD USDJPY AUDUSD USDCAD USDCHF NZDUSD'.split(): CLS[m] = ('fx', 1)
for m in 'EURJPY GBPJPY EURGBP AUDJPY EURAUD EURCHF'.split(): CLS[m] = ('fxx', 2)
for m in 'XAUUSD XAGUSD'.split(): CLS[m] = ('metal', 3)
for m in 'LIGHTCMDUSD BRENTCMDUSD COPPERCMDUSD'.split(): CLS[m] = ('energy', 5)
for m in 'USTBONDTRUSD BUNDTREUR'.split(): CLS[m] = ('bond', 2)
for m in 'USA500IDXUSD USATECHIDXUSD USA30IDXUSD DEUIDXEUR FRAIDXEUR GBRIDXGBP JPNIDXJPY'.split(): CLS[m] = ('index', 2)
FIN = 0.025 / 261
AN = 261

def load_all():
    px = {}
    for m in CLS:
        f = os.path.join(HIST, f'{m}_D1.csv.gz')
        if not os.path.exists(f): continue
        d = pd.read_csv(f)
        s = pd.Series(d.c.values, index=pd.DatetimeIndex(pd.to_datetime(d.t, unit='ms')).normalize())
        s = s[~s.index.duplicated(keep='last')]
        s = s[s.index.dayofweek < 5]
        px[m] = s
    P = pd.DataFrame(px).sort_index()
    P = P[P.index.dayofweek < 5]
    return P

def clean_returns(P):
    R = P.pct_change(fill_method=None)
    # flat days (holiday copies) and absurd ticks -> 0/NaN
    R[(R.abs() > 0.25)] = np.nan
    return R

def ewm_vol(R):
    return R.ewm(com=60, min_periods=60).std() * np.sqrt(AN)

def run(W, R, label, scale_to=0.10, rebalance='W-FRI'):
    """W: target raw weights at rebalance dates (index subset of R.index). Returns daily net returns."""
    Wd = W.reindex(R.index).ffill()
    Wd = Wd.shift(1)                                    # decided at close, earn next day's return
    # warm-up: trade only once enough markets have signals (else vol-scaling blows up on 1-2 markets)
    active = Wd.notna().sum(axis=1)
    Wd = Wd.where(pd.Series(active >= max(3, int(0.5 * W.shape[1])), index=Wd.index), np.nan)
    raw = (Wd * R.fillna(0)).sum(axis=1)
    # portfolio vol scaling from trailing 1y realized vol of raw book (known at the time)
    rv = raw.rolling(252, min_periods=126).std().shift(1) * np.sqrt(AN)
    k = (scale_to / rv).clip(upper=5.0)
    k = k.reindex(W.index, method='ffill').reindex(R.index).ffill().shift(1) if False else k
    # hold scale fixed between rebalances
    reb = R.index.isin(W.index)
    kk = k.where(pd.Series(reb, index=R.index)).ffill()
    Wf = Wd.mul(kk, axis=0)
    gross = (Wf * R.fillna(0)).sum(axis=1)
    turn = Wf.diff().abs()
    tc = sum(turn[m].fillna(0) * CLS[m][1] / 1e4 for m in Wf.columns)
    fin = Wf.abs().sum(axis=1) * FIN
    net = (gross - tc - fin).dropna()
    net = net[net.index >= Wf.dropna(how='all').index.min()]
    return net, Wf

def stats(x):
    x = x.dropna()
    if len(x) < 50 or x.std() == 0: return None
    ann = x.mean() * AN; vol = x.std() * np.sqrt(AN); eq = (1 + x).cumprod()
    return dict(ann=ann, vol=vol, sr=ann / vol, t=x.mean() / x.std() * np.sqrt(len(x)),
                dd=(1 - eq / eq.cummax()).max(), yrs=len(x) / AN)

def report(net, label, splits):
    parts = []
    for k in splits:
        a, b = PSPLITS[k]; s = stats(net[a:b])
        parts.append(f'{k}: ' + (f"ann={s['ann']*100:+5.1f}% vol={s['vol']*100:4.1f}% SR={s['sr']:+.2f} t={s['t']:+.2f} DD={s['dd']*100:4.1f}% ({s['yrs']:.0f}y)" if s else 'n/a'))
    print(f'{label:34s} ' + ' | '.join(parts))

def rebal_dates(idx, freq):
    s = pd.Series(idx, index=idx)
    return pd.DatetimeIndex(s.groupby(s.index.to_period(freq)).max().values)

def s1_tsmom(P, R, markets=None):
    markets = markets or list(P.columns)
    vol = ewm_vol(R[markets])
    sig = sum(np.sign(P[markets] / P[markets].shift(n) - 1) for n in (21, 63, 252)) / 3
    raw = sig * (0.10 / vol)
    dates = rebal_dates(P.index, 'W-FRI')
    return raw.loc[dates]

def s2_fxmom(P, R):
    fx = [m for m in P.columns if CLS[m][0] == 'fx']
    # express all as USD-quote-like: price of foreign ccy in USD (invert USDxxx)
    Q = P[fx].copy()
    for m in fx:
        if m.startswith('USD'): Q[m] = 1 / Q[m]
    mom = Q.shift(21) / Q.shift(252) - 1
    dates = rebal_dates(P.index, 'M')
    W = pd.DataFrame(0.0, index=dates, columns=P.columns)
    vol = ewm_vol(R[fx])
    for d in dates:
        m = mom.loc[d].dropna()
        if len(m) < 6: continue
        top, bot = m.nlargest(3).index, m.nsmallest(3).index
        for c in top: W.loc[d, c] = (1 if not c.startswith('USD') else -1) * 0.10 / vol.loc[d, c]
        for c in bot: W.loc[d, c] = (-1 if not c.startswith('USD') else 1) * 0.10 / vol.loc[d, c]
    return W.fillna(0)

def s3_riskparity(P, R):
    mk = [m for m in P.columns if CLS[m][0] in ('index', 'bond', 'metal') and m != 'XAGUSD']
    vol = ewm_vol(R[mk])
    W = (1 / vol).where(P[mk].notna())
    dates = rebal_dates(P.index, 'M')
    W = W.loc[dates].reindex(columns=P.columns).fillna(0)
    return W

if __name__ == '__main__':
    splits = sys.argv[1].split(',') if len(sys.argv) > 1 else ['DEV']
    P = load_all(); R = clean_returns(P)
    print('markets:', len(P.columns), {m: str(P[m].first_valid_index().date()) for m in P.columns})
    W1 = s1_tsmom(P, R); n1, Wf1 = run(W1, R, 'S1'); report(n1, 'S1 TSMOM/CTA all markets', splits)
    print('   avg gross leverage', round(Wf1.abs().sum(axis=1).mean(), 2))
    for cls in sorted(set(c for c, _ in CLS.values())):
        mk = [m for m in P.columns if CLS[m][0] != cls]
        n, _ = run(s1_tsmom(P, R, mk), R, ''); report(n, f'S1 drop {cls}', splits)
    W2 = s2_fxmom(P, R); n2, _ = run(W2, R, 'S2'); report(n2, 'S2 FX cross-sectional mom', splits)
    W3 = s3_riskparity(P, R); n3, _ = run(W3, R, 'S3'); report(n3, 'S3 risk parity long-only', splits)
