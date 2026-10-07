"""Realistic execution: buy at ASK, sell at BID (Dukascopy), plus commission + slippage."""
from lab import *

COMM = {'EURUSD': 0.00007 + 0.00002, 'XAUUSD': 0.07 + 0.05}   # round-trip commission + slippage, price units

def load_ba(pair):
    b = load(pair)
    a = pd.read_csv(os.path.join(HIST, f'{pair}_H1_ask.csv.gz'))
    a.index = pd.to_datetime(a.t, unit='ms', utc=True)
    a = a[['o', 'h', 'l', 'c']]
    j = b.join(a, lsuffix='_b', rsuffix='_a', how='inner')
    return j

def spread_profile(j, pair, split='DEV'):
    a, b = SPLITS[split]
    s = (j.o_a - j.o_b)[a:b]
    pip = 0.0001 if pair == 'EURUSD' else 0.1
    return (s.groupby(s.index.hour).median() / pip).round(2)

def trade_ret(j, pair, i_entry, i_exit, d, entry_field='o', exit_field='o'):
    """enter at bar i_entry open (or close), exit at bar i_exit open/close. Returns fraction."""
    if d > 0:
        en = j[f'{entry_field}_a'].iloc[i_entry]; ex = j[f'{exit_field}_b'].iloc[i_exit]
    else:
        en = j[f'{entry_field}_b'].iloc[i_entry]; ex = j[f'{exit_field}_a'].iloc[i_exit]
    mid = (j[f'{entry_field}_a'].iloc[i_entry] + j[f'{entry_field}_b'].iloc[i_entry]) / 2
    return (d * (ex - en) - COMM[pair]) / mid
