"""Stage 1 screening: DEV (2008-2018) ONLY. Never prints VAL/HOLD."""
import numpy as np, pandas as pd
from lab import *

DEV = SPLITS['DEV']
def dev_daily(pnl_bar):
    d = pnl_bar.resample('1D').sum()
    d = d[DEV[0]:DEV[1]]
    d = d[d.index.dayofweek < 5]
    return stats_from_daily(d)

def show(name, st):
    print(f"{name:48s} SR={st['sr']:+.2f} t={st['t']:+.2f} ann={st['ann']*100:+.2f}% pf={st['pf']:.2f} n={st['n']}")

res = []
for pair in ['EURUSD', 'XAUUSD']:
    df = load(pair)
    dd = daily(df)
    hr = df.index.hour
    print(f'===== {pair}  bars={len(df)}  {df.index[0]} -> {df.index[-1]}')

    # H1: time-series momentum on daily closes, held through next day (positions on H1 grid)
    for L in [20, 60, 120, 250]:
        sig = np.sign(dd.c / dd.c.shift(L) - 1)
        pos = sig.reindex(df.index, method='ffill').shift(1).fillna(0)   # yesterday's daily signal, applied today
        # convert: decision at end of day d applies from first bar of day d+1
        sig_by_day = sig.shift(1)
        pos = pd.Series(df.index.floor('D').map(sig_by_day), index=df.index).fillna(0)
        st = dev_daily(pos_pnl(df, pos, pair, carry=True)); show(f'H1 TSMOM L={L}', st); res.append((pair, 'H1', L, st))

    # H7: daily short-term reversal
    for L in [1, 3, 5]:
        sig = -np.sign(dd.c / dd.c.shift(L) - 1)
        pos = pd.Series(df.index.floor('D').map(sig.shift(1)), index=df.index).fillna(0)
        st = dev_daily(pos_pnl(df, pos, pair, carry=True)); show(f'H7 daily reversal L={L}', st); res.append((pair, 'H7', L, st))

    # H2: hour-of-day mean return (DEV only), t-stats
    r = df.c.pct_change()
    rd = r[DEV[0]:DEV[1]]
    g = rd.groupby(rd.index.hour)
    hs = pd.DataFrame({'mean_bp': g.mean() * 1e4, 't': g.mean() / g.std() * np.sqrt(g.count())})
    print('H2 hour-of-day (DEV):'); print(hs.round(2).T.to_string())

    # H3: day-of-week (daily returns)
    dr = dd.c.pct_change()[DEV[0]:DEV[1]]
    g = dr.groupby(dr.index.dayofweek)
    print('H3 day-of-week (DEV) t:', (g.mean() / g.std() * np.sqrt(g.count())).round(2).to_dict())

    # H4: intraday mean reversion after large k-hour move, by session
    for k in [1, 3, 6]:
        rk = df.c / df.c.shift(k) - 1
        vol = r.rolling(24 * 20).std() * np.sqrt(k)
        z = rk / vol
        for zth in [2.0, 2.5]:
            for sess, hours in [('asia', range(0, 7)), ('all', range(24))]:
                ok = np.isin(hr, list(hours))
                ent = pd.Series(np.where(ok & (z > zth), -1, np.where(ok & (z < -zth), 1, 0)), index=df.index)
                # hold k hours
                pos = ent.replace(0, np.nan).ffill(limit=k - 1 if k > 1 else 0).fillna(0) if k > 1 else ent
                st = dev_daily(pos_pnl(df, pos, pair)); show(f'H4 MR k={k} z={zth} {sess}', st); res.append((pair, 'H4', (k, zth, sess), st))

    # H8: intraday momentum: first hours of London predict rest of day
    for a, b in [(7, 9), (7, 11)]:
        day_open = df.o.groupby(df.index.floor('D')).transform(lambda s: s.iloc[0])
        sig_h = df.c[(hr == b - 1)]
        morning = (sig_h / df.o[hr == a].reindex(sig_h.index.floor('D') + pd.Timedelta(hours=a)).values - 1)
        sgn = np.sign(morning)
        pos = pd.Series(0.0, index=df.index)
        dayk = df.index.floor('D')
        m = pd.Series(sgn.values, index=sgn.index.floor('D'))
        m = m[~m.index.duplicated()]
        hold = (hr >= b - 1) & (hr < 20)
        pos[hold] = dayk[hold].map(m).fillna(0).values
        st = dev_daily(pos_pnl(df, pos, pair)); show(f'H8 intraday momentum {a}-{b} -> 20', st); res.append((pair, 'H8', (a, b), st))
