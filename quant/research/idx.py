"""Index research helpers (US clock aware)."""
import numpy as np, pandas as pd, os
from lab import HIST
ISPLITS = {'DEV': ('2013-01-01', '2019-12-31'), 'VAL': ('2020-01-01', '2022-12-31'), 'HOLD': ('2023-01-01', '2100-01-01')}
COSTPT = {'USA30IDXUSD': 3.0, 'USA500IDXUSD': 0.75, 'USATECHIDXUSD': 2.0}
FF = {2013: .1, 2014: .1, 2015: .13, 2016: .4, 2017: 1.0, 2018: 1.83, 2019: 2.16, 2020: .38, 2021: .08, 2022: 1.68,
      2023: 5.02, 2024: 5.14, 2025: 4.3, 2026: 3.9}
def fin_rate(ts): return (FF.get(ts.year, 4.0) + 2.5) / 100 / 360     # per night, fraction
def load_idx(name):
    df = pd.read_csv(os.path.join(HIST, f'{name}_H1.csv.gz'))
    df.index = pd.to_datetime(df.t, unit='ms', utc=True)
    df = df[['o', 'h', 'l', 'c']]
    df['ny'] = df.index.tz_convert('America/New_York')
    return df
def tstat(x):
    x = pd.Series(x).dropna()
    return x.mean() / x.std() * np.sqrt(len(x)) if len(x) > 2 and x.std() > 0 else np.nan
def summ(s, label):
    out = []
    for k, (a, b) in ISPLITS.items():
        x = s[a:b]
        if len(x) < 3: out.append(f'{k}: n={len(x)}'); continue
        pf = x[x > 0].sum() / -x[x < 0].sum() if (x < 0).any() else np.inf
        out.append(f'{k}: n={len(x):4d} {x.mean()*1e4:+6.2f}bp t={tstat(x):+5.2f} pf={pf:4.2f} sum={x.sum()*100:+6.1f}%')
    print(f'{label:34s} ' + ' | '.join(out))
