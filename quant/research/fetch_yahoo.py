"""Yahoo Finance daily OHLC for the research universe -> quant/history/yahoo/<symbol>.csv.gz
GitHub Actions me chalta hai (.github/workflows/quant-yahoo.yml). Sandbox se Yahoo blocked hai."""
import os, sys, time, gzip
import yfinance as yf

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'history', 'yahoo')
os.makedirs(OUT, exist_ok=True)
syms = open(os.path.join(HERE, 'yahoo.txt')).read().split()
bad = []
for s in syms:
    for k in range(3):
        try:
            df = yf.download(s, period='max', interval='1d', auto_adjust=False, progress=False, threads=False)
            if df is None or df.empty: raise RuntimeError('empty')
            if hasattr(df.columns, 'levels'): df.columns = df.columns.get_level_values(0)
            df = df[['Open', 'High', 'Low', 'Close', 'Adj Close', 'Volume']].dropna(subset=['Close'])
            name = s.replace('^', 'I_').replace('=', '_').replace('.', '_')
            with gzip.open(os.path.join(OUT, f'{name}.csv.gz'), 'wt') as f:
                df.to_csv(f, float_format='%.6g')
            print(f'{s:10s} {len(df):6d} rows {df.index[0].date()} -> {df.index[-1].date()}')
            break
        except Exception as e:
            print(f'{s}: {e} (try {k + 1})'); time.sleep(5 * (k + 1))
    else:
        bad.append(s)
    time.sleep(1)
print('FAILED:', bad)
