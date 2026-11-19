#!/usr/bin/env python3
"""
SAMUSIGNAL CANDLE EA - exit research (TP / SL / TIME / lock / ATR) on real 1-minute history.

Data : Yahoo Finance 1m (last ~7 days) for the 17 EA pairs (runs on GitHub Actions; no keys).
Signal: same as EA Signal() - EMA9/21, RSI14, body >= 1.2 x avg10 body, body >= 50% range.
Entry : next candle open (MARKET) + spread cost.
Exit  : many policies (fixed $, ATR based, candle-structure based, time stop, break-even, lock).
Output: per policy - trades, win %, avg win / loss ($ at 0.01 lot), expectancy, profit factor,
        net $, worst losing streak, max drawdown. Only aggregates are printed (no account data).
"""
import json, sys, time, math, urllib.request, itertools

PAIRS = ["EURUSD", "GBPUSD", "USDJPY", "USDCHF", "USDCAD", "AUDUSD", "NZDUSD", "EURJPY", "GBPJPY",
         "AUDJPY", "CADJPY", "CHFJPY", "NZDJPY", "EURAUD", "EURCAD", "EURCHF", "AUDCAD"]
# typical spread in pips (Exness standard, observed on EA: $0.06-0.11 per 0.01 lot)
SPREAD_PIPS = {"EURUSD": 0.8, "GBPUSD": 1.0, "USDJPY": 0.9, "USDCHF": 1.2, "USDCAD": 1.4, "AUDUSD": 0.9,
               "NZDUSD": 1.3, "EURJPY": 1.5, "GBPJPY": 2.0, "AUDJPY": 1.1, "CADJPY": 1.1, "CHFJPY": 2.0,
               "NZDJPY": 1.4, "EURAUD": 1.6, "EURCAD": 1.6, "EURCHF": 1.5, "AUDCAD": 1.5}
# $ per pip at 0.01 lot (approx: USD quote 0.10, JPY ~0.063, CAD ~0.070, CHF ~0.119, AUD ~0.067)
PIP_USD = {"USD": 0.10, "JPY": 0.063, "CAD": 0.070, "CHF": 0.119, "AUD": 0.067}


def pip_size(p): return 0.01 if p.endswith("JPY") else 0.0001
def pip_usd(p): return PIP_USD[p[3:]]


def fetch(p):
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{p}=X?interval=1m&range=7d"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    for i in range(4):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                j = json.load(r)
            res = j["chart"]["result"][0]
            q = res["indicators"]["quote"][0]
            bars = []
            for t, o, h, l, c in zip(res["timestamp"], q["open"], q["high"], q["low"], q["close"]):
                if None in (o, h, l, c) or h < l:
                    continue
                bars.append((t, o, h, l, c))
            return bars
        except Exception as e:
            print("fetch retry", p, e, file=sys.stderr)
            time.sleep(3 * (i + 1))
    return []


def ema(vals, n):
    out = [None] * len(vals)
    if len(vals) < n:
        return out
    k = 2.0 / (n + 1)
    e = sum(vals[:n]) / n
    out[n - 1] = e
    for i in range(n, len(vals)):
        e = vals[i] * k + e * (1 - k)
        out[i] = e
    return out


def rsi(vals, n=14):
    out = [None] * len(vals)
    if len(vals) < n + 1:
        return out
    g = l = 0.0
    for i in range(1, n + 1):
        d = vals[i] - vals[i - 1]
        g += max(d, 0); l += max(-d, 0)
    g /= n; l /= n
    out[n] = 100 if l == 0 else 100 - 100 / (1 + g / l)
    for i in range(n + 1, len(vals)):
        d = vals[i] - vals[i - 1]
        g = (g * (n - 1) + max(d, 0)) / n
        l = (l * (n - 1) + max(-d, 0)) / n
        out[i] = 100 if l == 0 else 100 - 100 / (1 + g / l)
    return out


def htf_dir(bars, mins):
    """EMA9 vs EMA21 on closed higher-timeframe candles -> dict minute_ts -> dir known at that minute."""
    buckets, order = {}, []
    for t, o, h, l, c in bars:
        b = t - t % (mins * 60)
        if b not in buckets:
            order.append(b)
        buckets[b] = c                      # last close in bucket
    closes = [buckets[b] for b in order]
    e9, e21 = ema(closes, 9), ema(closes, 21)
    dir_at_bucket = {}
    for i, b in enumerate(order):
        # direction from the PREVIOUS completed bucket (no look-ahead)
        if i >= 1 and e9[i - 1] is not None and e21[i - 1] is not None:
            dir_at_bucket[b] = 1 if e9[i - 1] > e21[i - 1] else (-1 if e9[i - 1] < e21[i - 1] else 0)
    return lambda t: dir_at_bucket.get(t - t % (mins * 60), 0)


def signals(p, bars):
    """EA Signal() on each closed bar i -> entry at bar i+1 open."""
    C = [b[4] for b in bars]
    e9, e21, rs = ema(C, 9), ema(C, 21), rsi(C, 14)
    h15, h60 = htf_dir(bars, 15), htf_dir(bars, 60)
    out = []
    for i in range(30, len(bars) - 2):
        t, o, h, l, c = bars[i]
        if bars[i + 1][0] - t > 180:          # gap (weekend / missing) - skip
            continue
        body, rng = abs(c - o), h - l
        if c == o or rng <= 0 or body < 0.5 * rng:
            continue
        avg = sum(abs(bars[j][4] - bars[j][1]) for j in range(i - 10, i)) / 10
        if avg <= 0 or body < 1.2 * avg:
            continue
        if e9[i] is None or e21[i] is None or rs[i] is None:
            continue
        if c > o:
            if not (e9[i] > e21[i] and c > e9[i] and 50 <= rs[i] < 70):
                continue
            d = 1
        else:
            if not (e9[i] < e21[i] and c < e9[i] and 30 < rs[i] <= 50):
                continue
            d = -1
        trs = [max(bars[j][2], bars[j - 1][4]) - min(bars[j][3], bars[j - 1][4]) for j in range(i - 13, i + 1)]
        atr = sum(trs) / 14
        out.append({"i": i, "dir": d, "body": body, "atr": atr, "sig_hi": h, "sig_lo": l,
                    "htf": (h15(t) == d and h60(t) == d), "e21": e21[i], "close": c,
                    "hour": time.gmtime(t).tm_hour})
    return out


def simulate(p, bars, s, pol):
    """returns (pl_usd at 0.01 lot, bars_held, reason) or None if can't enter."""
    ps, pu = pip_size(p), pip_usd(p)
    usd_per_price = pu / ps                        # $ per 1.0 price move at 0.01 lot
    spr = SPREAD_PIPS[p] * ps
    i0 = s["i"] + 1
    d = -s["dir"] if pol.get("fade") else s["dir"]        # fade = ulti disha (jaanch ke liye)
    entry = bars[i0][1] + (spr if d > 0 else 0)  # BUY at ask, SELL at bid (bid series)
    # distances in price
    kind = pol["kind"]
    if kind == "usd":
        tp_d, sl_d = pol["tp"] / usd_per_price, pol["sl"] / usd_per_price
    elif kind == "atr":
        tp_d, sl_d = pol["tp"] * s["atr"], pol["sl"] * s["atr"]
    else:   # "struct": SL beyond signal candle extreme, TP = R x risk
        ref = s["sig_lo"] if d > 0 else s["sig_hi"]
        sl_d = abs(entry - ref) + spr + 0.1 * s["atr"]
        tp_d = pol["tp"] * sl_d
    if sl_d <= 0 or tp_d <= 0:
        return None
    tp = entry + d * tp_d
    sl = entry - d * sl_d
    lock_at = pol.get("lock_at")           # in $ (0.01 lot) or R fraction for atr/struct
    lock_to = pol.get("lock_to", 0.0)
    if lock_at is not None and kind != "usd":
        lock_at_d, lock_to_d = lock_at * sl_d, lock_to * sl_d
    elif lock_at is not None:
        lock_at_d, lock_to_d = lock_at / usd_per_price, lock_to / usd_per_price
    rec = pol.get("rec")                    # recovery: dip >= rec*sl_d then exit at entry
    rec_armed = False
    maxbars = pol["time"]
    locked = False
    for k in range(i0, min(len(bars), i0 + maxbars)):
        if k > i0 and bars[k][0] - bars[k - 1][0] > 180:      # data gap -> close at last close
            px = bars[k - 1][4]
            return ((px - entry) * d - (spr if d < 0 else 0)) * usd_per_price, k - i0, "GAP"
        _, o, h, l, c = bars[k]
        # bid series: BUY exits at bid; SELL exits at ask = bid + spr
        hi = h + (spr if d < 0 else 0)
        lo = l + (spr if d < 0 else 0)
        fav = (hi - entry) if d > 0 else (entry - lo)
        adv = (entry - lo) if d > 0 else (hi - entry)
        cur_sl = (entry + d * lock_to_d) if locked else sl
        sl_hit = (lo <= cur_sl) if d > 0 else (hi >= cur_sl)       # conservative: SL pehle
        if sl_hit:
            return ((cur_sl - entry) * d) * usd_per_price, k - i0 + 1, ("LOCK" if locked else "SL")
        if rec is not None and rec_armed and fav >= 0:
            return 0.0, k - i0 + 1, "WAPSI"
        if fav >= tp_d:
            return tp_d * usd_per_price, k - i0 + 1, "TP"
        if rec is not None and adv >= rec * sl_d:
            rec_armed = True
        if lock_at is not None and not locked and fav >= lock_at_d:
            locked = True
    k = min(len(bars), i0 + maxbars) - 1
    px = bars[k][4] + (spr if d < 0 else 0)
    return (px - entry) * d * usd_per_price, k - i0 + 1, "TIME"


def stats(res):
    pls = [r[0] for r in res]
    n = len(pls)
    if n == 0:
        return None
    w = [x for x in pls if x > 0]
    lo = [x for x in pls if x <= 0]
    net = sum(pls)
    pf = (sum(w) / -sum(lo)) if lo and sum(lo) < 0 else float("inf")
    eq = peak = dd = 0.0
    streak = mx = 0
    for x in pls:
        eq += x; peak = max(peak, eq); dd = max(dd, peak - eq)
        streak = streak + 1 if x <= 0 else 0
        mx = max(mx, streak)
    reasons = {}
    for r in res:
        reasons[r[2]] = reasons.get(r[2], 0) + 1
    return {"n": n, "win": 100.0 * len(w) / n, "aw": (sum(w) / len(w)) if w else 0, "al": (sum(lo) / len(lo)) if lo else 0,
            "exp": net / n, "pf": pf, "net": net, "dd": dd, "streak": mx,
            "hold": sum(r[1] for r in res) / n, "why": reasons}


def main():
    data = {}
    for p in PAIRS:
        b = fetch(p)
        if len(b) > 500:
            data[p] = b
        print(f"DATA {p}: {len(b)} bars", flush=True)
    if not data:
        print("NO DATA"); return
    sigs = {p: signals(p, b) for p, b in data.items()}
    total = sum(len(v) for v in sigs.values())
    first = min(b[0][0] for b in data.values()); last = max(b[-1][0] for b in data.values())
    for p, v in sigs.items():
        print(f"SIG {p}: {len(v)} | HTF {sum(1 for s in v if s['htf'])}")
    print(f"SIGNALS: {total} | HTF (15m+1h saath): {sum(1 for v in sigs.values() for s in v if s['htf'])} | "
          f"{time.strftime('%d %b %H:%M', time.gmtime(first))} -> {time.strftime('%d %b %H:%M', time.gmtime(last))} UTC")

    pols = []
    # current EA v1.10 style (0.01 lot): TP 0.25 / SL 3 / lock 0.15->0.05 / recovery at -1 / TIME 300 (and 200)
    pols.append(("NOW v1.10: TP .25 SL 3 lock .15>.05 wapsi-1 T300", {"kind": "usd", "tp": .25, "sl": 3, "time": 300, "lock_at": .15, "lock_to": .05, "rec": 1 / 3}))
    pols.append(("NOW plain: TP .25 SL 3 T300", {"kind": "usd", "tp": .25, "sl": 3, "time": 300}))
    pols.append(("PAPER: TP .10 SL 10 T200", {"kind": "usd", "tp": .10, "sl": 10, "time": 200}))
    for tp, sl, tm in itertools.product([.15, .25, .5, 1.0], [.25, .5, 1.0, 1.5, 3.0], [15, 30, 60, 300]):
        pols.append((f"USD TP {tp} SL {sl} T{tm}", {"kind": "usd", "tp": tp, "sl": sl, "time": tm}))
    for tp, sl, tm in itertools.product([0.5, 1, 1.5, 2, 3], [0.5, 1, 1.5, 2, 3], [15, 30, 60, 300]):
        pols.append((f"ATR TP {tp} SL {sl} T{tm}", {"kind": "atr", "tp": tp, "sl": sl, "time": tm}))
        pols.append((f"ATR TP {tp} SL {sl} T{tm} BE.5", {"kind": "atr", "tp": tp, "sl": sl, "time": tm, "lock_at": .5, "lock_to": .05}))
    for r, tm in itertools.product([0.5, 1, 1.5, 2, 3], [15, 30, 60, 300]):
        pols.append((f"STRUCT TP {r}R T{tm}", {"kind": "struct", "tp": r, "time": tm}))
        pols.append((f"STRUCT TP {r}R T{tm} BE.5", {"kind": "struct", "tp": r, "time": tm, "lock_at": .5, "lock_to": .05}))

    # v2: jeetne wale ke aas-paas baarik jaanch (lock / wapsi alag-alag, SL / TIME / TP)
    for tp in (.2, .25, .35, .5):
        for sl in (2, 2.5, 3, 4, 5):
            for tm in (150, 200, 300, 450):
                pols.append((f"FINE TP {tp} SL {sl} T{tm}", {"kind": "usd", "tp": tp, "sl": sl, "time": tm}))
    for tp in (.25, .5):
        pols.append((f"FINE TP {tp} SL 3 T300 +lock.15>.05", {"kind": "usd", "tp": tp, "sl": 3, "time": 300, "lock_at": .15, "lock_to": .05}))
        pols.append((f"FINE TP {tp} SL 3 T300 +lock.20>.10", {"kind": "usd", "tp": tp, "sl": 3, "time": 300, "lock_at": .20, "lock_to": .10}))
        pols.append((f"FINE TP {tp} SL 3 T300 +wapsi-1", {"kind": "usd", "tp": tp, "sl": 3, "time": 300, "rec": 1 / 3}))
        pols.append((f"FINE TP {tp} SL 3 T300 +wapsi-2", {"kind": "usd", "tp": tp, "sl": 3, "time": 300, "rec": 2 / 3}))
    for tp, sl, tm in [(.25, 3, 300), (.5, 3, 300), (1, 1, 60), (1.5, 1.5, 60), (1, 2, 60), (2, 2, 300)]:
        k = "usd" if sl == 3 else "atr"
        pols.append((f"FADE {k.upper()} TP {tp} SL {sl} T{tm}", {"kind": k, "tp": tp, "sl": sl, "time": tm, "fade": True}))
    mid = first + (last - first) // 2

    def run(pol, flt, part=None):
        res = []
        for p, ss in sigs.items():
            busy_until = -1
            for s in ss:
                if flt == "HTF" and not s["htf"]:
                    continue
                t = data[p][s["i"]][0]
                if part == 1 and t >= mid or part == 2 and t < mid:
                    continue
                if s["i"] < busy_until:
                    continue
                r = simulate(p, data[p], s, pol)
                if r is None:
                    continue
                res.append(r)
                busy_until = s["i"] + 1 + r[1]
        return stats(res)

    rows = []
    for name, pol in pols:
        for flt in ("ALL", "HTF"):
            res = []
            for p, ss in sigs.items():
                busy_until = -1
                for s in ss:
                    if flt == "HTF" and not s["htf"]:
                        continue
                    if s["i"] < busy_until:          # one trade per pair at a time (EA rule)
                        continue
                    r = simulate(p, data[p], s, pol)
                    if r is None:
                        continue
                    res.append(r)
                    busy_until = s["i"] + 1 + r[1]
            st = stats(res)
            if st:
                rows.append((name, flt, st))

    def line(name, flt, st):
        pf = "inf" if st["pf"] == float("inf") else f"{st['pf']:.2f}"
        why = " ".join(f"{k}:{v}" for k, v in sorted(st["why"].items()))
        return (f"{flt:3} | {name:42} | n {st['n']:4} | win {st['win']:5.1f}% | avgW {st['aw']:+.3f} avgL {st['al']:+.3f} | "
                f"exp {st['exp']:+.4f} | PF {pf:>5} | net {st['net']:+8.2f} | DD {st['dd']:6.2f} | streak {st['streak']:2} | hold {st['hold']:5.1f} | {why}")

    print("\n=== BASE (abhi jaisa) + FADE ===")
    for r in rows:
        if r[0].startswith(("NOW", "PAPER", "FADE")):
            print("RES", line(*r))
    for flt in ("ALL", "HTF"):
        good = [r for r in rows if r[1] == flt and r[2]["n"] >= 80]
        print(f"\n=== TOP 25 by net ({flt}, n>=80) ===")
        for r in sorted(good, key=lambda r: -r[2]["net"])[:25]:
            print("TOP", line(*r))
        print(f"\n=== TOP 15 by profit factor ({flt}, n>=80) ===")
        for r in sorted(good, key=lambda r: -(r[2]["pf"] if r[2]["pf"] != float("inf") else 99))[:15]:
            print("PF ", line(*r))
    # stability: top 10 (dono filter) pehle aadhe vs baad ke aadhe din
    print("\n=== STABILITY: top 10 (n>=80) pehla aadha vs doosra aadha ===")
    good2 = sorted([r for r in rows if r[2]["n"] >= 80], key=lambda r: -r[2]["net"])[:10]
    P = dict(pols)
    for name, flt, st in good2:
        a, b = run(P[name], flt, 1), run(P[name], flt, 2)
        fa = f"n {a['n']} net {a['net']:+.2f} win {a['win']:.0f}%" if a else "-"
        fb = f"n {b['n']} net {b['net']:+.2f} win {b['win']:.0f}%" if b else "-"
        print(f"STAB {flt} | {name:42} | 1st: {fa} | 2nd: {fb}")
    print("\n=== FINE (HTF) sab ===")
    for r in sorted([r for r in rows if r[1] == "HTF" and r[0].startswith("FINE")], key=lambda r: -r[2]["net"]):
        print("FINE", line(*r))
    for nm in ("FINE TP 0.25 SL 3 T300", "FINE TP 0.35 SL 4 T450", "FINE TP 0.2 SL 4 T450", "NOW v1.10: TP .25 SL 3 lock .15>.05 wapsi-1 T300"):
        print(f"\n=== PER PAIR (HTF) {nm} ===")
        tot_x = 0.0; n_x = 0
        for p, ss in sigs.items():
            res, busy_until = [], -1
            for s in ss:
                if not s["htf"] or s["i"] < busy_until:
                    continue
                r = simulate(p, data[p], s, P[nm])
                if r is None:
                    continue
                res.append(r); busy_until = s["i"] + 1 + r[1]
            st = stats(res)
            if st:
                print(f"PP {p}: n {st['n']} win {st['win']:.1f}% net {st['net']:+.2f} PF {st['pf'] if st['pf']!=float('inf') else 99:.2f} avgL {st['al']:+.2f}")
                if p != "AUDCAD":
                    tot_x += st["net"]; n_x += st["n"]
        print(f"PPX {nm}: AUDCAD ke bina n {n_x} net {tot_x:+.2f}")
    # per-pair for best HTF policy
    good = [r for r in rows if r[1] == "HTF" and r[2]["n"] >= 80]
    if good:
        best = max(good, key=lambda r: r[2]["net"])
        pol = dict(pols)[best[0]]
        print(f"\n=== PER PAIR for best HTF: {best[0]} ===")
        for p, ss in sigs.items():
            res, busy_until = [], -1
            for s in ss:
                if not s["htf"] or s["i"] < busy_until:
                    continue
                r = simulate(p, data[p], s, pol)
                if r is None:
                    continue
                res.append(r); busy_until = s["i"] + 1 + r[1]
            st = stats(res)
            if st:
                print(f"PAIR {p}: n {st['n']} win {st['win']:.1f}% net {st['net']:+.2f} PF {st['pf'] if st['pf']!=float('inf') else 99:.2f}")
        # by hour (UTC)
        print(f"\n=== BY HOUR UTC for best HTF ===")
        byh = {}
        for p, ss in sigs.items():
            busy_until = -1
            for s in ss:
                if not s["htf"] or s["i"] < busy_until:
                    continue
                r = simulate(p, data[p], s, pol)
                if r is None:
                    continue
                busy_until = s["i"] + 1 + r[1]
                byh.setdefault(s["hour"], []).append(r)
        for h in sorted(byh):
            st = stats(byh[h])
            print(f"HOUR {h:02d}: n {st['n']} win {st['win']:.1f}% net {st['net']:+.2f}")


if __name__ == "__main__":
    main()
