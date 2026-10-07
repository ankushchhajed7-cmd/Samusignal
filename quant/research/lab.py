"""Research lab: load H1 data, evaluate position-series and trade-list strategies by split."""
import numpy as np, pandas as pd, gzip, sys, os

HIST = os.environ.get('HIST', os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'history'))
COST = {'EURUSD': 0.00012, 'XAUUSD': 0.35}          # round trip, price units
CARRY = {'EURUSD': 0.00005, 'XAUUSD': 0.10}         # per day held (swap proxy)
SPLITS = {'DEV': ('2008-01-01', '2018-12-31'), 'VAL': ('2019-01-01', '2022-12-31'), 'HOLD': ('2023-01-01', '2100-01-01')}

def load(pair):
    df = pd.read_csv(os.path.join(HIST, f'{pair}_H1.csv.gz'))
    df.index = pd.to_datetime(df.t, unit='ms', utc=True)
    return df[['o', 'h', 'l', 'c']]

def daily(df):
    d = df.resample('1D').agg({'o': 'first', 'h': 'max', 'l': 'min', 'c': 'last'}).dropna()
    n = df.c.resample('1D').count()
    return d[n.reindex(d.index) >= 8]

def stats_from_daily(pnl):
    """pnl: daily returns (fraction) series"""
    pnl = pnl.dropna()
    if len(pnl) < 20 or pnl.std() == 0: return dict(n=len(pnl), sr=np.nan, t=np.nan, ann=np.nan, pf=np.nan, dd=np.nan)
    sr = pnl.mean() / pnl.std() * np.sqrt(252)
    eq = pnl.cumsum()
    return dict(n=len(pnl), sr=sr, t=pnl.mean() / pnl.std() * np.sqrt(len(pnl)), ann=pnl.mean() * 252,
                pf=pnl[pnl > 0].sum() / -pnl[pnl < 0].sum() if (pnl < 0).any() else np.inf,
                dd=(eq.cummax() - eq).max())

def pos_pnl(df, pos, pair, carry=False):
    """pos decided at close of bar t, earns return of bar t+1. Returns per-bar pnl as fraction of price."""
    r = df.c.pct_change().shift(-1)
    gross = pos * r
    turn = pos.diff().abs().fillna(pos.abs())
    cost = turn * (COST[pair] / 2) / df.c
    net = gross - cost
    if carry:
        held_days = pos.abs() / 24.0
        net = net - held_days * CARRY[pair] / df.c
    return net

def split_report(pnl_bar, label=''):
    d = pnl_bar.resample('1D').sum()
    d = d[d != 0] if (d != 0).sum() > 0 else d
    out = {}
    for k, (a, b) in SPLITS.items():
        out[k] = stats_from_daily(d[a:b])
    return out

def trade_stats(rs):
    rs = np.asarray(rs, float)
    if len(rs) < 5: return dict(n=len(rs), exp=np.nan, pf=np.nan, t=np.nan, win=np.nan)
    w, l = rs[rs > 0], rs[rs <= 0]
    return dict(n=len(rs), exp=rs.mean(), pf=w.sum() / -l.sum() if l.sum() < 0 else np.inf,
                t=rs.mean() / rs.std(ddof=1) * np.sqrt(len(rs)), win=len(w) / len(rs))

def trade_split(trades):
    """trades: DataFrame with index=entry time, column r"""
    return {k: trade_stats(trades.loc[a:b, 'r']) for k, (a, b) in SPLITS.items()}

def fmt(rep, keys=('sr', 't', 'pf', 'n')):
    return ' | '.join(f"{k}: " + ' '.join(f"{m}={v[m]:.2f}" if isinstance(v[m], float) else f"{m}={v[m]}" for m in keys) for k, v in rep.items())
