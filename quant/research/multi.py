"""Locked weekend gap-fade rule on pairs it has never seen. No tuning.
thr=0.003 delay=1 hold=24, target = Friday mid close."""
import sys
from exec import *

THR, DELAY, HOLD = 0.003, 1, 24

def pip_of(pair): return 0.01 if 'JPY' in pair else (0.1 if pair == 'XAUUSD' else 0.0001)
def comm_of(pair): return COMM[pair] if pair in COMM else 0.9 * pip_of(pair)

def gapfade(j, pair, thr=THR, delay=DELAY, hold=HOLD):
    mid_o = (j.o_a + j.o_b) / 2; mid_c = (j.c_a + j.c_b) / 2
    idx = j.index.to_series(); dt = idx.diff()
    prev_dow = idx.shift(1).dt.dayofweek
    first = np.where((dt > pd.Timedelta(hours=40)) & (dt < pd.Timedelta(hours=80)) & (prev_dow == 4))[0]   # asli weekend: Friday → Sunday
    c = comm_of(pair); rs, ts, info = [], [], []
    for i in first:
        e = i + delay
        if e + hold >= len(j) or i == 0: continue
        pc = mid_c.iloc[i - 1]
        g = mid_o.iloc[e] / pc - 1
        if abs(g) < thr: continue
        d = -np.sign(g)
        seg = j.iloc[e:e + hold]
        hit = np.where((seg.l_b <= pc) if d < 0 else (seg.h_b >= pc))[0]
        en = j.o_a.iloc[e] if d > 0 else j.o_b.iloc[e]
        if len(hit):
            k = e + hit[0]
            ex = pc if d > 0 else pc + (j.o_a.iloc[k] - j.o_b.iloc[k])
            why = 'fill'
        else:
            k = e + hold
            ex = j.o_b.iloc[k] if d > 0 else j.o_a.iloc[k]
            why = 'time'
        rs.append((d * (ex - en) - c) / pc); ts.append(j.index[e])
        info.append(dict(pair=pair, t=j.index[e], dir=int(d), gap=g, entry=en, target=pc, exit=ex, why=why,
                         mae=float(((seg.l_b.min() - en) if d > 0 else (en - seg.h_a.max())) / pc)))
    return pd.Series(rs, index=ts), info

def st(x):
    if len(x) < 3: return f'n={len(x)}'
    t = x.mean() / x.std() * np.sqrt(len(x))
    pf = x[x > 0].sum() / -x[x < 0].sum() if (x < 0).any() else np.inf
    return f'n={len(x):3d} mean={x.mean()*1e4:+6.2f}bp t={t:+5.2f} win={(x>0).mean():.2f} pf={pf:.2f}'

if __name__ == '__main__':
    pairs = sys.argv[1].split(',')
    pooled = []
    for p in pairs:
        try: j = load_ba(p)
        except Exception as e: print(p, 'no data', e); continue
        s, _ = gapfade(j, p)
        pooled.append(s)
        print(f'{p}: {j.index[0].date()}..{j.index[-1].date()} ALL {st(s)}')
        for k, (a, b) in SPLITS.items(): print(f'    {k}: {st(s[a:b])}')
    allp = pd.concat(pooled).sort_index()
    print('POOLED', st(allp))
    for k, (a, b) in SPLITS.items(): print(f'    {k}: {st(allp[a:b])}')
    # sign-flip permutation p-value on pooled
    rng = np.random.default_rng(1); x = allp.values
    perm = np.array([(x * rng.choice([-1, 1], len(x))).mean() for _ in range(20000)])
    print('pooled sign-flip p =', ((perm >= x.mean()).sum() + 1) / (len(perm) + 1))
