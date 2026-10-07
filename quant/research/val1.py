"""Candidates with real bid/ask execution. Usage: python3 val1.py SPLIT[,SPLIT...]"""
import sys
from exec import *

splits = sys.argv[1].split(',') if len(sys.argv) > 1 else ['DEV']

def summarize(name, s):
    for sp in splits:
        a, b = SPLITS[sp]
        x = s[a:b]
        if len(x) < 5: print(f'{name:44s} {sp}: n={len(x)}'); continue
        t = x.mean() / x.std() * np.sqrt(len(x))
        pf = x[x > 0].sum() / -x[x < 0].sum()
        print(f'{name:44s} {sp}: n={len(x):4d} mean={x.mean()*1e4:+6.2f}bp t={t:+5.2f} win={(x>0).mean():.2f} pf={pf:.2f} sum={x.sum()*100:+6.1f}%')

j = load_ba('EURUSD')
print('EURUSD median spread by hour (pips, DEV):'); print(spread_profile(j, 'EURUSD').to_dict())
hr = j.index.hour.values
day = j.index.floor('D')

# C1: EURUSD Asia drift — buy open of hour h0, sell open of hour h1 (same day)
for h0, h1 in [(1, 4), (1, 3), (1, 6), (2, 4), (0, 4)]:
    rs, ts = [], []
    starts = np.where(hr == h0)[0]
    for i in starts:
        k = i + (h1 - h0)
        if k >= len(j) or day[k] != day[i] or hr[k] != h1: continue
        if j.index[i].dayofweek == 0 and False: pass
        rs.append(trade_ret(j, 'EURUSD', i, k, +1)); ts.append(j.index[i])
    summarize(f'C1 EURUSD long {h0:02d}->{h1:02d} UTC', pd.Series(rs, index=ts))

# C2: weekend gap fade. gap = mid open of first bar vs Friday mid close.
mid_o = (j.o_a + j.o_b) / 2; mid_c = (j.c_a + j.c_b) / 2
first = np.where(j.index.to_series().diff().values > np.timedelta64(30, 'h'))[0]
for thr in [0.002, 0.003, 0.004]:
    for delay in [0, 1, 2]:              # enter at open of first bar + delay
        for hold in [12, 24]:
            rs, ts = [], []
            for i in first:
                e = i + delay
                if e + hold >= len(j): continue
                pc = mid_c.iloc[i - 1]
                g = mid_o.iloc[e] / pc - 1
                if abs(g) < thr: continue
                d = -np.sign(g)
                exit_i = e + hold
                # target touch: mid back to Friday close
                seg = j.iloc[e:e + hold]
                hit = np.where((seg.l_b <= pc) if d < 0 else (seg.h_b >= pc))[0]
                if len(hit):
                    k = e + hit[0]
                    ex = pc if d > 0 else pc + (j.o_a.iloc[k] - j.o_b.iloc[k])   # long sells at bid=pc; short buys at ask≈pc+spread
                    en = j.o_a.iloc[e] if d > 0 else j.o_b.iloc[e]
                    r = (d * (ex - en) - COMM['EURUSD']) / pc
                else:
                    r = trade_ret(j, 'EURUSD', e, exit_i, d)
                rs.append(r); ts.append(j.index[e])
            summarize(f'C2 gap fade thr={thr} delay={delay} hold={hold}', pd.Series(rs, index=ts))
