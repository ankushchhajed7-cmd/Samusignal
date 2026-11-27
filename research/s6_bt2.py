#!/usr/bin/env python3
"""
PERSONAL FX Strategy 6 - v9.0 rules vs suggested changes (27 Nov 2026), backtest on REAL gold.

Data : Yahoo Finance gold futures (GC=F) 1m (~7 days) and 5m (~60 days). Runs on GitHub Actions.
Model: one cycle = main 0.02 (BUY or SELL) at a start time, hedges 0.01 opposite. Depth D = points
       against the main. 0.01 lot = $1 per point. Spread SPREAD points. Path inside a bar O-L-H-C / O-H-L-C,
       stepped every TICK points. No slippage, no broker rejects.
v9.0 (as running):
  - hedge level n at depth n*GAP; pending STOP there (or at the re-entry price, see below)
  - no pending within SPACE (1.5) points of an open hedge
  - lock LIFO: only the deepest hedge; armed after > +$2, closes at +$1. If the deepest is not armed
    and there are 2+: deepest two together, pair armed after > +$1, closes at +$1
  - v8.8: when a new deepest hedge fills and (pair at fill) > +$1 -> pair armed at once
  - 4b re-entry: a level that closed deeper than itself reopens at the close depth, capped at
    level + half a gap; back to the exact level once price returns above (shallower than) the level
  - close: banked + open >= +$6 (NET6); no hedge: main >= +$6 (TP); with hedges: open >= +$3 when
    main in profit (CYC3), >= +$5 when main in loss (BSK5); open <= -SL (BSL)
Variants (user 27 Nov):
  A  re-entry only at the exact level (never deeper)
  B  pair lock at fill only when the pair is >= +$2 (not +$1)
  E  new hedge only when every open hedge deeper than it is in profit
  O  pendings OFF points before the level (towards the main)
  G  deepest pair (not armed) together <= -$2 -> close both at a loss
  T  trailing lock: armed at ARM, floor = max($1, peak - TRAIL), close at the floor
"""
import json, sys, time, urllib.request, statistics, random

SPREAD = 0.25
GAP = 3.0
TICK = 0.1


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


BASE = dict(reentry=True, space=1.5, pairfill=1.0, guard=False, off=0.0, pairsl=None,
            arm=2.0, trail=None, lock=1.0, pair_arm=1.0, noise=0.0, limit=False, deeponly=False, allprofit=None)


def run_cycle(bars, start, d, bsl, max_hours, **kw):
    c = dict(BASE); c.update(kw)
    s = SPREAD
    mid0 = bars[start][1]
    end_t = bars[start][0] + max_hours * 3600
    lv = lambda n: n * GAP - c["off"]
    H = []                      # {n, o, armed, peak, id}
    R = {}
    banked = 0.0; pair_id = None; minf = 0.0; used = 0; uid = 0
    prevD = s
    last_mid = mid0
    t0 = bars[start][0]
    rng = random.Random(start * 2 + (d > 0)) if c["noise"] else None

    def setR(h, D):
        if c["reentry"] and D > lv(h["n"]):
            R[h["n"]] = min(D, lv(h["n"]) + 0.5 * GAP)

    def floor(h):
        if c["trail"] is None:
            return c["lock"]
        return max(c["lock"], h["peak"] - c["trail"])

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
                if rng:                                     # stress: tick noise inside the bar
                    mid += rng.gauss(0, c["noise"])
                D = s - d * (mid - mid0)
                H.sort(key=lambda h: h["o"])                 # deepest last
                hpl = [D - h["o"] - s for h in H]
                mainPL = -2 * D
                tot = mainPL + sum(hpl)
                if tot < minf:
                    minf = tot
                dur = bar[0] - t0
                # ---- close rules (EA order) ----
                if banked + tot >= 6:
                    return ("NET6", banked + tot, minf, dur, used)
                if not H:
                    if mainPL >= 6:
                        return ("TP", banked + mainPL, minf, dur, used)
                else:
                    if tot >= (3 if mainPL >= 0 else 5):
                        return ("CYC3" if mainPL >= 0 else "BSK5", banked + tot, minf, dur, used)
                    if bsl and tot <= -bsl:
                        return ("BSL", banked + tot, minf, dur, used)
                # ---- locks (LIFO) ----
                for h, p in zip(H, hpl):
                    if p > h["peak"]:
                        h["peak"] = p
                    if not h["armed"] and (p >= c["arm"] if c["trail"] is not None else p > c["arm"]):
                        h["armed"] = True
                closed = False
                if H:
                    b = H[-1]; pb = hpl[-1]
                    if b["armed"]:
                        if pb <= floor(b):
                            banked += pb; H.pop(); setR(b, D); closed = True
                    elif len(H) >= 2:
                        a = H[-2]; cb = hpl[-2] + pb
                        if cb > c["pair_arm"]:
                            pair_id = b["id"]
                        if pair_id == b["id"] and cb <= c["lock"]:
                            banked += cb; H.pop(); H.pop(); setR(b, D); setR(a, D); pair_id = None; closed = True
                        elif c["pairsl"] is not None and cb <= -c["pairsl"]:
                            banked += cb; H.pop(); H.pop(); setR(b, D); setR(a, D); pair_id = None; closed = True
                # ---- re-entry back to exact level ----
                for n in list(R.keys()):
                    if D < lv(n):
                        R.pop(n)
                # ---- pending fills (STOP: depth crosses the trigger going deeper) ----
                if not closed and D > prevD:
                    occ = {h["n"] for h in H}
                    nmax = int((D + c["off"]) / GAP) + 2
                    for n in range(1, nmax + 1):
                        if n in occ:
                            continue
                        trig = R.get(n, lv(n))
                        if not (prevD < trig <= D):
                            continue
                        if c["space"] and any(abs(h["o"] - trig) < c["space"] for h in H):
                            continue
                        if c["guard"] and any(h["o"] > trig and (D - h["o"] - s) <= 0 for h in H):
                            continue
                        if c["deeponly"] and H and trig <= max(h["o"] for h in H):   # N: sirf sabse gehre se aage
                            continue
                        if c["allprofit"] is not None and any((D - h["o"] - s) < c["allprofit"] for h in H):   # P: saare khule profit me
                            continue
                        deepest_before = max((h["o"] for h in H), default=None)
                        uid += 1; used += 1
                        nh = {"n": n, "o": trig, "armed": False, "peak": -s, "id": uid}
                        H.append(nh); occ.add(n); R.pop(n, None)
                        if c["pairfill"] is not None and deepest_before is not None and trig > deepest_before:
                            if (trig - deepest_before) - 2 * s > c["pairfill"]:
                                pair_id = uid
                # ---- user 27 Nov: khali level par LIMIT bhi (bhaav main ki taraf laut kar level chhue to wahin) ----
                if c["limit"] and not closed and D < prevD:
                    occ = {h["n"] for h in H}
                    for n in range(1, int((prevD + c["off"]) / GAP) + 2):
                        if n in occ:
                            continue
                        L = lv(n)
                        if not (D <= L < prevD):
                            continue
                        if c["space"] and any(abs(h["o"] - L) < c["space"] for h in H):
                            continue
                        uid += 1; used += 1
                        H.append({"n": n, "o": L, "armed": False, "peak": -s, "id": uid}); occ.add(n); R.pop(n, None)
                prevD = D
            last_mid = target
    D = s - d * (last_mid - mid0)
    tot = -2 * D + sum(D - h["o"] - s for h in H)
    return ("OPEN", banked + tot, minf, bars[min(len(bars) - 1, bi)][0] - t0, used)


def summarize(name, rows):
    if not rows:
        print(f"  {name:<30} n=0"); return
    pl = [r["pl"] for r in rows]; dd = [r["minf"] for r in rows]
    kinds = {}
    for r in rows:
        kinds[r["kind"]] = kinds.get(r["kind"], 0) + 1
    bad = kinds.get("BSL", 0) + kinds.get("OPEN", 0)
    wins = sum(1 for x in pl if x > 0)
    dur = statistics.median(r["dur"] for r in rows) / 60
    print(f"  {name:<30} n={len(rows):4d} win={100*wins/len(rows):5.1f}% avg=${statistics.mean(pl):6.2f} "
          f"total=${sum(pl):8.1f} worst=${min(pl):8.1f} DDworst=${min(dd):7.1f} DDp90=${sorted(dd)[len(dd)//10]:6.1f} "
          f"BSL/OPEN={bad:3d} hedges/cyc={statistics.mean(r['used'] for r in rows):5.1f} medDur={dur:5.0f}m  "
          + " ".join(f"{k}:{v}" for k, v in sorted(kinds.items())))


VARS = [
    ("V0  v9.0", dict()),
    ("v9.1/9.2 = G+L12", dict(pairsl=2.0, arm=1.2)),
    ("P0  saare khule > $0", dict(allprofit=0.0)),
    ("P1  saare khule >= +$1", dict(allprofit=1.0)),
    ("v9.2 + P0", dict(pairsl=2.0, arm=1.2, allprofit=0.0)),
    ("v9.2 + P1", dict(pairsl=2.0, arm=1.2, allprofit=1.0)),
]


NOISY = [v[0] for v in VARS]


def study(label, bars, start_min, max_hours):
    print(f"\n==================== {label}: {len(bars)} bars, "
          f"{time.strftime('%Y-%m-%d %H:%M', time.gmtime(bars[0][0]))} -> {time.strftime('%Y-%m-%d %H:%M', time.gmtime(bars[-1][0]))} UTC", flush=True)
    starts = []; last = None
    for i, b in enumerate(bars):
        t = b[0]
        if last is not None and t - last < start_min * 60:
            continue
        if t > bars[-1][0] - 6 * 3600:
            break
        last = t; starts.append(i)
    print(f"  starts: {len(starts)} x 2 directions", flush=True)
    for bsl in (60, 0):
        print(f"\n--- Basket SL {'$%d' % bsl if bsl else 'OFF'} ---", flush=True)
        for vname, kw in VARS:
            rows = []
            for i in starts:
                for d in (1, -1):
                    kind, pl, minf, dur, used = run_cycle(bars, i, d, bsl, max_hours, **kw)
                    rows.append({"kind": kind, "pl": pl, "minf": minf, "dur": dur, "used": used})
            summarize(vname, rows)
            sys.stdout.flush()
    print("\n--- NOISE test (har 0.1 point par +-0.1 point shor, Basket SL $60) ---", flush=True)
    for vname, kw in VARS:
        if vname not in NOISY:
            continue
        rows = []
        for i in starts:
            for d in (1, -1):
                kind, pl, minf, dur, used = run_cycle(bars, i, d, 60, max_hours, noise=0.1, **kw)
                rows.append({"kind": kind, "pl": pl, "minf": minf, "dur": dur, "used": used})
        summarize(vname, rows)
        sys.stdout.flush()


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--synthetic":       # local smoke test (no network)
        import random
        random.seed(7); t = 1_700_000_000; p = 2600.0; bars = []
        for _ in range(int(sys.argv[2]) if len(sys.argv) > 2 else 3000):
            o = p; moves = [random.gauss(0, 0.35) for _ in range(4)]
            path = [o]
            for m in moves: path.append(path[-1] + m)
            p = path[-1]
            bars.append((t, o, max(path), min(path), p)); t += 60
        study("SYNTHETIC random walk 1m", bars, 30, 24)
        return
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
