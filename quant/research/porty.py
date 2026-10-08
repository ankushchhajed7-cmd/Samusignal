"""Round 3b on Yahoo daily data. Usage: python3 porty.py DEV[,VAL[,HOLD]]"""
import sys, os, numpy as np, pandas as pd
import port as P0
HY = os.environ.get('HY', os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'history', 'yahoo'))
U = {}
for s in 'I_GSPC I_NDX I_DJI I_RUT I_GDAXI I_FCHI I_FTSE I_N225 I_HSI I_AXJO I_STOXX50E I_BSESN I_NSEI'.split(): U[s] = ('index', 2)
for s in 'ZN_F ZB_F ZF_F ZT_F'.split(): U[s] = ('bond', 2)
for s in 'EURUSD_X GBPUSD_X USDJPY_X AUDUSD_X USDCAD_X USDCHF_X NZDUSD_X'.split(): U[s] = ('fx', 1)
for s in 'GC_F SI_F HG_F'.split(): U[s] = ('metal', 3)
U['BZ_F'] = ('energy', 5)
for s in 'ZC_F ZW_F ZS_F KC_F SB_F CT_F CC_F LE_F'.split(): U[s] = ('ags', 8)
P0.CLS.clear(); P0.CLS.update(U)
P0.PSPLITS.clear(); P0.PSPLITS.update({'DEV': ('2000-01-01', '2012-12-31'), 'VAL': ('2013-01-01', '2018-12-31'), 'HOLD': ('2019-01-01', '2100-01-01')})

def load():
    px = {}
    for s in U:
        d = pd.read_csv(os.path.join(HY, f'{s}.csv.gz'), index_col=0, parse_dates=True)
        c = d.Close.astype(float); c = c[c > 0]
        c.index = pd.DatetimeIndex(c.index).tz_localize(None).normalize()
        px[s] = c[~c.index.duplicated(keep='last')]
    P = pd.DataFrame(px).sort_index()
    P = P[P.index.dayofweek < 5]
    return P[P.index >= '1999-01-01']

if __name__ == '__main__':
    splits = sys.argv[1].split(',') if len(sys.argv) > 1 else ['DEV']
    P = load(); R = P0.clean_returns(P)
    R = R.where(P.notna())          # no return on days a market didn't trade (holidays)
    W1 = P0.s1_tsmom(P, R); n1, Wf1 = P0.run(W1, R, 'S1'); P0.report(n1, 'S1 TSMOM/CTA (36 mkts)', splits)
    print('   avg gross leverage', round(Wf1.loc['2001':].abs().sum(axis=1).mean(), 2))
    for cls in sorted(set(c for c, _ in U.values())):
        mk = [m for m in P.columns if U[m][0] != cls]
        n, _ = P0.run(P0.s1_tsmom(P, R, mk), R, ''); P0.report(n, f'S1 drop {cls}', splits)
    # S2 FX xs momentum on spot FX
    fx = [m for m in P.columns if U[m][0] == 'fx']
    Q = P[fx].copy()
    for m in fx:
        if m.startswith('USD'): Q[m] = 1 / Q[m]
    mom = Q.shift(21) / Q.shift(252) - 1
    dates = P0.rebal_dates(P.index, 'M'); vol = P0.ewm_vol(R[fx])
    W2 = pd.DataFrame(0.0, index=dates, columns=P.columns)
    for d in dates:
        m = mom.loc[d].dropna()
        if len(m) < 6: continue
        for c in m.nlargest(3).index: W2.loc[d, c] = (1 if not c.startswith('USD') else -1) * 0.10 / vol.loc[d, c]
        for c in m.nsmallest(3).index: W2.loc[d, c] = (-1 if not c.startswith('USD') else 1) * 0.10 / vol.loc[d, c]
    n2, _ = P0.run(W2.fillna(0), R, 'S2'); P0.report(n2, 'S2 FX cross-sectional mom', splits)
    mk = [m for m in P.columns if U[m][0] in ('index', 'bond') or m == 'GC_F']
    v = P0.ewm_vol(R[mk]); W3 = (1 / v).where(P[mk].notna()).loc[dates].reindex(columns=P.columns).fillna(0)
    n3, _ = P0.run(W3, R, 'S3'); P0.report(n3, 'S3 risk parity long-only', splits)
    eq = R['I_GSPC'].fillna(0); P0.report(eq, 'benchmark S&P500 buy&hold (unlevered)', splits)
    pd.DataFrame({'S1': n1, 'S2': n2, 'S3': n3}).to_csv('/tmp/claude-0/lab/porty_returns.csv')
