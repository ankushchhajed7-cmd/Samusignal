"""Locked gap-fade on bid-only data, conservative 2-pip round-trip cost. No tuning."""
import sys
from lab import *
THR, DELAY, HOLD = 0.003, 1, 24
def pip_of(p): return 0.01 if 'JPY' in p else 0.0001
def gapfade_bid(df, pair, cost_pips=2.0):
    idx=df.index.to_series(); dt=idx.diff(); prev_dow=idx.shift(1).dt.dayofweek
    first=np.where((dt>pd.Timedelta(hours=40))&(dt<pd.Timedelta(hours=80))&(prev_dow==4))[0]
    cost=cost_pips*pip_of(pair); rs=[]; ts=[]
    for i in first:
        e=i+DELAY
        if e+HOLD>=len(df): continue
        pc=df.c.iloc[i-1]; g=df.o.iloc[e]/pc-1
        if abs(g)<THR: continue
        d=-np.sign(g); seg=df.iloc[e:e+HOLD]
        hit=np.where((seg.l<=pc) if d<0 else (seg.h>=pc))[0]
        ex=pc if len(hit) else df.o.iloc[e+HOLD]
        rs.append((d*(ex-df.o.iloc[e])-cost)/pc); ts.append(df.index[e])
    return pd.Series(rs,index=ts)
def st(x):
    if len(x)<3: return f'n={len(x)}'
    t=x.mean()/x.std()*np.sqrt(len(x)); pf=x[x>0].sum()/-x[x<0].sum() if (x<0).any() else np.inf
    return f'n={len(x):3d} mean={x.mean()*1e4:+6.2f}bp t={t:+5.2f} win={(x>0).mean():.2f} pf={pf:.2f}'
pairs=sys.argv[1].split(','); pooled=[]
for p in pairs:
    s=gapfade_bid(load(p),p); pooled.append(s)
    print(f'{p}: ALL {st(s)}'); 
    for k,(a,b) in SPLITS.items(): print(f'    {k}: {st(s[a:b])}')
if len(pooled)>1:
    allp=pd.concat(pooled).sort_index(); print('POOLED', st(allp))
    for k,(a,b) in SPLITS.items(): print(f'    {k}: {st(allp[a:b])}')
    rng=np.random.default_rng(1); x=allp.values
    perm=np.array([(x*rng.choice([-1,1],len(x))).mean() for _ in range(20000)])
    print('sign-flip p =',((perm>=x.mean()).sum()+1)/(len(perm)+1))
