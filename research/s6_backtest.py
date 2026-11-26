#!/usr/bin/env python3
"""
PERSONAL FX Strategy 6 (hedge ladder, v8.5 rules) - backtest on REAL gold prices.

Data  : Yahoo Finance gold futures (GC=F) - 1m bars (last ~7 days) and 5m bars (last ~60 days).
        Runs on GitHub Actions (no keys). Only aggregates are printed.
Model : one cycle = main trade 0.02 (BUY or SELL) at a start time, hedges 0.01 opposite.
        Prices in gold points; 0.01 lot = $1 per point. Spread SPREAD points (bid/ask around mid).
Rules (same as EA v8.5):
  - hedge levels every GAP points from the main (SELL STOP / BUY STOP at the level)
  - hedge lock: armed after > +$2, closes when back to +$1; only the DEEPEST hedge closes
    (alone if armed, else the deepest two together at +$1, pair armed after > +$1)
  - a level that closed beyond its own price reopens at the price it closed at (STOP; market if
    price ran past it); if price went back above the level -> exact level again
  - no hedge: main TP +$6 (0.02). With hedges: banked + open >= +$6 (NET6), or open total
    >= +$3 when main in profit (CYC3) / >= +$5 when main in loss (BSK5), or <= -BSL (BSL)
Starts: every START_MIN minutes, both directions; a cycle runs until it closes or MAX_HOURS.
Output: overall, by India start hour, by 15m ADX, by 15m ATR, by last-4h range.
"""
import json, sys, time, math, urllib.request, statistics

SPREAD = 0.25      # points (~$0.25 per 0.01 lot)
GAP = 3.0          # $3 per 0.01 lot = 3 points on gold
ARM, LOCK = 2.0, 1.0
PAIR_ARM = 1.0
TICK = 0.1         # path interpolation step (points)


def fetch(interval, rng):
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/GC=F?interval={interval}&range={rng}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    for i in range(5):
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
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
            print("fetch retry", interval, e, file=sys.stderr)
            time.sleep(4 * (i + 1))
    return []


def path_points(bar):
    t, o, h, l, c = bar
    return [o, l, h, c] if c >= o else [o, h, l, c]


def resample(bars, mins):
    out = []; cur = None
    for t, o, h, l, c in bars:
        k = t - t % (mins * 60)
        if cur is None or cur[0] != k:
            if cur: out.append(tuple(cur))
            cur = [k, o, h, l, c]
        else:
            cur[2] = max(cur[2], h); cur[3] = min(cur[3], l); cur[4] = c
    if cur: out.append(tuple(cur))
    return out


def indicators(b15):
    """ADX14, ATR14 per 15m bar index (Wilder)."""
    n = len(b15); adx = [None] * n; atr = [None] * n
    tr_s = pdm_s = ndm_s = 0.0; dx_list = []; adx_v = None; N = 14
    for i in range(1, n):
        _, o, h, l, c = b15[i]; _, po, ph, pl, pc = b15[i - 1]
        tr = max(h - l, abs(h - pc), abs(l - pc))
        up, dn = h - ph, pl - l
        pdm = up if up > dn and up > 0 else 0.0
        ndm = dn if dn > up and dn > 0 else 0.0
        if i <= N:
            tr_s += tr; pdm_s += pdm; ndm_s += ndm
            if i < N: continue
        else:
            tr_s = tr_s - tr_s / N + tr; pdm_s = pdm_s - pdm_s / N + pdm; ndm_s = ndm_s - ndm_s / N + ndm
        atr[i] = tr_s / N
        pdi = 100 * pdm_s / tr_s if tr_s else 0; ndi = 100 * ndm_s / tr_s if tr_s else 0
        dx = 100 * abs(pdi - ndi) / (pdi + ndi) if (pdi + ndi) else 0
        if adx_v is None:
            dx_list.append(dx)
            if len(dx_list) == N: adx_v = sum(dx_list) / N
        else:
            adx_v = (adx_v * (N - 1) + dx) / N
        adx[i] = adx_v
    return adx, atr


def run_cycle(bars, start, d, bsl, max_hours, cap=False):
    """d=+1 main BUY, -1 main SELL. Depth D = how far price moved AGAINST the main (trigger side)."""
    mid0 = bars[start][1]
    s = SPREAD
    end_t = bars[start][0] + max_hours * 3600
    H = []                    # dicts: lvl, o (depth), armed
    R = {}; seen = {}         # re-entry depth per level, seen flag
    banked = 0.0; pair_arm = None; minf = 0.0; uid = [0]
    prevD = s                 # depth at entry (spread)

    def dep(mid):
        return s - d * (mid - mid0)

    last_mid = mid0
    for bi in range(start, len(bars)):
        bar = bars[bi]
        if bar[0] > end_t:
            break
        pts = path_points(bar) if bi > start else [bar[1]] + path_points(bar)[1:]
        for target in pts:
            base = last_mid
            dist = target - base
            steps = max(1, int(abs(dist) / TICK))
            for k in range(1, steps + 1):
                mid = base + dist * k / steps
                D = dep(mid)
                # --- hedge entries (STOP crossing upward in depth) ---
                occ = {h["lvl"] for h in H}
                if D > prevD:
                    for n in range(max(1, int(prevD // GAP)), int(D // GAP) + 2):
                        if n in occ: continue
                        trig = R.get(n, n * GAP)
                        if prevD < trig <= D and (n not in R or seen.get(n)):
                            uid[0] += 1; H.append({"lvl": n, "o": trig, "armed": False, "id": uid[0]}); occ.add(n)
                            R.pop(n, None); seen.pop(n, None)
                # re-entry levels: seen / market fallback / clear when price back above level
                for n in list(R.keys()):
                    if D < n * GAP:                    # price went back above the level -> exact level
                        R.pop(n); seen.pop(n, None); continue
                    if D < R[n]: seen[n] = True
                    elif not seen.get(n) and D >= R[n] + 0.25 * GAP and n not in occ:
                        uid[0] += 1; H.append({"lvl": n, "o": D, "armed": False, "id": uid[0]}); occ.add(n)
                        R.pop(n); seen.pop(n, None)
                prevD = D
                H.sort(key=lambda h: h["o"])           # deepest last
                mainPL = -2 * D
                hpl = [D - h["o"] - s for h in H]
                tot = mainPL + sum(hpl)
                if tot < minf: minf = tot
                if not H:
                    if mainPL >= 6:
                        return ("TP", banked + mainPL, minf, bar[0] - bars[start][0])
                else:
                    if bsl and tot <= -bsl:
                        return ("BSL", banked + tot, minf, bar[0] - bars[start][0])
                    if banked + tot >= 6:
                        return ("NET6", banked + tot, minf, bar[0] - bars[start][0])
                    if tot >= (3 if mainPL >= 0 else 5):
                        return ("CYC3" if mainPL >= 0 else "BSK5", banked + tot, minf, bar[0] - bars[start][0])
                # --- locks ---
                for h, p in zip(H, hpl):
                    if p > ARM: h["armed"] = True
                if H:
                    b = H[-1]; pb = hpl[-1]
                    if len(H) >= 2 and not b["armed"]:
                        a = H[-2]; c = hpl[-2] + pb
                        if c > PAIR_ARM: pair_arm = b["id"]
                        if pair_arm == b["id"] and c <= LOCK:
                            banked += c
                            for h in (a, b):
                                H.remove(h)
                                if D > h["lvl"] * GAP and h is a: R[h["lvl"]] = min(D, h["lvl"] * GAP + 0.5 * GAP) if cap else D; seen[h["lvl"]] = False
                    elif b["armed"] and pb <= LOCK:
                        banked += pb; H.remove(b)
                        if D > b["lvl"] * GAP: R[b["lvl"]] = min(D, b["lvl"] * GAP + 0.5 * GAP) if cap else D; seen[b["lvl"]] = False
            last_mid = target
    D = dep(last_mid)
    tot = -2 * D + sum(D - h["o"] - s for h in H)
    return ("OPEN", banked + tot, minf, bars[min(len(bars) - 1, bi)][0] - bars[start][0])


def ist_hour(t):
    return int(((t + 19800) % 86400) // 3600)


def summarize(name, rows):
    if not rows:
        print(f"  {name:<22} n=0"); return
    pl = [r["pl"] for r in rows]; dd = [r["minf"] for r in rows]
    kinds = {}
    for r in rows: kinds[r["kind"]] = kinds.get(r["kind"], 0) + 1
    bad = kinds.get("BSL", 0) + kinds.get("OPEN", 0)
    wins = sum(1 for x in pl if x > 0)
    dur = statistics.median(r["dur"] for r in rows) / 60
    print(f"  {name:<22} n={len(rows):4d} win={100*wins/len(rows):5.1f}% avg=${statistics.mean(pl):6.2f} "
          f"total=${sum(pl):8.1f} worst=${min(pl):8.1f} DDworst=${min(dd):8.1f} DDp90=${sorted(dd)[len(dd)//10]:7.1f} "
          f"BSL/OPEN={bad:3d} medDur={dur:6.0f}min  " + " ".join(f"{k}:{v}" for k, v in sorted(kinds.items())))


def bucket(v, edges, labels):
    if v is None: return "n/a"
    for e, lab in zip(edges, labels):
        if v < e: return lab
    return labels[-1]


def study(label, bars, start_min, max_hours):
    print(f"\n==================== {label}: {len(bars)} bars, "
          f"{time.strftime('%Y-%m-%d %H:%M', time.gmtime(bars[0][0]))} -> {time.strftime('%Y-%m-%d %H:%M', time.gmtime(bars[-1][0]))} UTC")
    b15 = resample(bars, 15); adx, atr = indicators(b15)
    idx15 = {b[0]: i for i, b in enumerate(b15)}
    # --- v8.5 vs v8.6 fix (re-entry price never deeper than half a gap past its own level) ---
    print("\n--- COMPARE: v8.5 (as running) vs v8.6-fix (re-entry capped at level + half gap) ---")
    for cap in (False, True):
        for bsl in (0, 30):
            rows = []; last_start = None
            for i, b in enumerate(bars):
                t = b[0]
                if last_start is not None and t - last_start < start_min * 60: continue
                if t > bars[-1][0] - 6 * 3600: break
                k15 = t - t % 900 - 900
                j = idx15.get(k15)
                if j is None or adx[j] is None: continue
                last_start = t
                for d in (1, -1):
                    kind, pl, minf, dur = run_cycle(bars, i, d, bsl, max_hours, cap)
                    rows.append({"kind": kind, "pl": pl, "minf": minf, "dur": dur, "h": ist_hour(t), "adx": adx[j], "atr": atr[j], "dir": d})
            summarize(("v8.6-fix" if cap else "v8.5") + (" BSL$30" if bsl else " BSL off"), rows)
    for bsl in (0, 30):
        rows = []; last_start = None
        for i, b in enumerate(bars):
            t = b[0]
            if last_start is not None and t - last_start < start_min * 60: continue
            if t > bars[-1][0] - 6 * 3600: break          # need some room to run
            k15 = t - t % 900 - 900                        # last CLOSED 15m bar
            j = idx15.get(k15)
            if j is None or adx[j] is None: continue
            rng4 = max(x[2] for x in b15[max(0, j - 15):j + 1]) - min(x[3] for x in b15[max(0, j - 15):j + 1])
            last_start = t
            for d in (1, -1):
                kind, pl, minf, dur = run_cycle(bars, i, d, bsl, max_hours)
                rows.append({"kind": kind, "pl": pl, "minf": minf, "dur": dur, "h": ist_hour(t),
                             "adx": adx[j], "atr": atr[j], "rng4": rng4, "dir": d})
        print(f"\n--- Basket SL {'OFF' if not bsl else '$'+str(bsl)} ---")
        summarize("ALL", rows)
        summarize("main BUY", [r for r in rows if r["dir"] == 1])
        summarize("main SELL", [r for r in rows if r["dir"] == -1])
        print(" by India start time:")
        for a, b_ in [(0, 3), (3, 6), (6, 9), (9, 12), (12, 15), (15, 18), (18, 21), (21, 24)]:
            summarize(f"IST {a:02d}-{b_:02d}", [r for r in rows if a <= r["h"] < b_])
        print(" by 15m ADX at start:")
        for lab in ["<20", "20-25", "25-35", ">=35"]:
            summarize(f"ADX {lab}", [r for r in rows if bucket(r["adx"], [20, 25, 35], ["<20", "20-25", "25-35", ">=35"]) == lab])
        atrs = sorted(r["atr"] for r in rows if r["atr"] is not None)
        if atrs:
            q1, q2 = atrs[len(atrs) // 3], atrs[2 * len(atrs) // 3]
            print(f" by 15m ATR at start (terciles {q1:.2f} / {q2:.2f} points):")
            for lab, lo, hi in [("ATR low", -1, q1), ("ATR mid", q1, q2), ("ATR high", q2, 1e9)]:
                summarize(lab, [r for r in rows if r["atr"] is not None and lo <= r["atr"] < hi])
        rs = sorted(r["rng4"] for r in rows)
        if rs:
            q1, q2 = rs[len(rs) // 3], rs[2 * len(rs) // 3]
            print(f" by last-4h range at start (terciles {q1:.1f} / {q2:.1f} points):")
            for lab, lo, hi in [("4h range low", -1, q1), ("4h range mid", q1, q2), ("4h range high", q2, 1e9)]:
                summarize(lab, [r for r in rows if lo <= r["rng4"] < hi])
        if atrs:
            aq1 = atrs[len(atrs) // 3]
            print(" filters:")
            summarize("ADX>=25 + ATR not low", [r for r in rows if r["adx"] >= 25 and r["atr"] >= aq1])
            summarize("ADX<20 + ATR low", [r for r in rows if r["adx"] < 20 and r["atr"] < aq1])


def main():
    b1 = fetch("1m", "7d")
    if b1:
        study("GOLD 1m (7 days), start every 30 min, max 48h", b1, 30, 48)
    else:
        print("1m data not available")
    b5 = fetch("5m", "60d")
    if b5:
        study("GOLD 5m (60 days), start every 2h, max 72h", b5, 120, 72)
    else:
        print("5m data not available")


if __name__ == "__main__":
    main()
