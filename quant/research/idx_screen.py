"""Index hypotheses. Usage: python3 idx_screen.py NAME [SPLITS]  (default prints DEV only)."""
import sys
from idx import *

name = sys.argv[1]
show = sys.argv[2].split(',') if len(sys.argv) > 2 else ['DEV']
SP = {k: v for k, v in ISPLITS.items() if k in show}
def summ2(s, label):
    out = []
    for k, (a, b) in SP.items():
        x = s[a:b]
        if len(x) < 3: out.append(f'{k}: n={len(x)}'); continue
        pf = x[x > 0].sum() / -x[x < 0].sum() if (x < 0).any() else np.inf
        out.append(f'{k}: n={len(x):4d} {x.mean()*1e4:+6.2f}bp t={tstat(x):+5.2f} pf={pf:4.2f} sum={x.sum()*100:+6.1f}% win={(x>0).mean():.2f}')
    print(f'{label:38s} ' + ' | '.join(out))

df = load_idx(name)
cost = COSTPT[name]
ny = df.ny
nyd = ny.dt.date if hasattr(ny, 'dt') else pd.Series(ny.date, index=df.index)
df['d'] = [x.date() for x in ny]; df['h'] = [x.hour for x in ny]; df['dow'] = [x.dayofweek for x in ny]

# per NY trading day: price at key times
g = df.groupby('d')
def at(hour, field):
    s = df[df.h == hour].groupby('d')[field].last()
    return s
C16 = at(15, 'c')          # 16:00 ET close (close of 15:00 bar)
O09 = at(9, 'o')           # 09:00 ET (pre-open)
O10 = at(10, 'o')          # 10:00 ET
O15 = at(15, 'o')          # 15:00 ET
O14 = at(14, 'o')
days = pd.Index(sorted(set(C16.index) & set(O10.index) & set(O09.index) & set(O15.index)))
days = days[[pd.Timestamp(d).dayofweek < 5 for d in days]]
C16, O09, O10, O15, O14 = [s.reindex(days) for s in (C16, O09, O10, O15, O14)]
idx_ts = pd.DatetimeIndex([pd.Timestamp(d) for d in days])
def ser(vals): return pd.Series(np.asarray(vals, float), index=idx_ts)

nights = ser([(pd.Timestamp(days[i + 1]) - pd.Timestamp(days[i])).days if i + 1 < len(days) else np.nan for i in range(len(days))])
fin = ser([fin_rate(pd.Timestamp(d)) for d in days])

# I0 buy & hold close-to-close (financing every night)
cc = C16.values
bh = ser(np.r_[(cc[1:] - cc[:-1] - 0) / cc[:-1], np.nan]) - nights * fin
summ2(bh.dropna(), 'I0 buy&hold (daily, financed)')

# I1 overnight: buy 16:00 close day t, sell next day 09:00 or 10:00
for lab, O in [('09', O09), ('10', O10)]:
    nxt = O.shift(-1).values
    r = ser((nxt - cc - cost) / cc) - nights * fin
    summ2(r.dropna(), f'I1 overnight long -> {lab}:00 ET')
# intraday 10 -> 16
r = ser((cc - O10.values - cost) / O10.values)
summ2(r.dropna(), 'I1b intraday long 10->16 ET')

# I2 turn of month: enter close of day before last trading day, exit close of 3rd trading day
dd = pd.Series(days, index=idx_ts)
mon = idx_ts.to_period('M')
pos_in_month = dd.groupby(mon).cumcount().values
cnt_in_month = dd.groupby(mon).transform('count').values
for (k_before, k_after) in [(1, 3), (2, 3), (1, 4), (0, 3)]:
    rs, ts = [], []
    for i in range(len(days)):
        if pos_in_month[i] == cnt_in_month[i] - 1 - k_before:          # entry day
            # find exit: k_after-th trading day of next month (1-based)
            j = i + 1; seen = 0
            while j < len(days) and seen < k_after:
                if mon[j] != mon[i]: seen += 1
                if seen == k_after: break
                j += 1
            if j >= len(days): continue
            n = (pd.Timestamp(days[j]) - pd.Timestamp(days[i])).days
            rs.append((cc[j] - cc[i] - cost) / cc[i] - n * fin.iloc[i]); ts.append(idx_ts[i])
    summ2(pd.Series(rs, index=ts), f'I2 TOM enter -{k_before} exit +{k_after}')

# I3 intraday momentum: sign(prev close -> 10:00) ; trade 15:00->16:00 (and 14:00->16:00)
prev_c = np.r_[np.nan, cc[:-1]]
first = O10.values / prev_c - 1
for lab, O in [('15', O15), ('14', O14)]:
    d = np.sign(first)
    r = ser((d * (cc - O.values) - cost) / O.values)
    summ2(r.dropna(), f'I3 intraday mom {lab}->16 ET')

# I4 200-day MA long-only (decided at close, held next day)
ma = pd.Series(cc).rolling(200).mean().values
on = cc > ma
r_next = np.r_[(cc[1:] - cc[:-1]) / cc[:-1], np.nan]
sw = np.r_[on[0], on[1:] != on[:-1]].astype(float)
r = ser(np.where(on, r_next - nights.values * fin.values, 0) - sw * cost / cc)
summ2(r.dropna(), 'I4 200d MA long-only (daily)')

# I5 day-of-week (close-to-close of that day, financed)
for wd in range(5):
    m = np.array([pd.Timestamp(d).dayofweek == wd for d in days])
    x = ser(np.r_[np.nan, (cc[1:] - cc[:-1]) / cc[:-1]])[m]
    summ2(x.dropna(), f'I5 day-of-week {["Mon","Tue","Wed","Thu","Fri"][wd]} (gross)')

# I6 daily reversal: after down day < -thr, long next day close->close
for thr in [0.0, 0.01]:
    rp = np.r_[np.nan, (cc[1:] - cc[:-1]) / cc[:-1]]
    sig = rp < -thr
    r = ser(np.where(sig, r_next - nights.values * fin.values - cost / cc, np.nan))
    summ2(r.dropna(), f'I6 buy after down day < -{thr*100:.0f}%')

# hour-of-day (NY clock), gross
r = df.c.pct_change()
m = (df.index >= SP[list(SP)[0]][0]) & (df.index <= SP[list(SP)[0]][1]) if SP else slice(None)
rr = r[m]; hh = df.h[m]
gg = rr.groupby(hh.values)
print('hour-of-day (NY) t:', (gg.mean() / gg.std() * np.sqrt(gg.count())).round(1).to_dict())
