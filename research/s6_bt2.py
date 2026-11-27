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


import os
SYM = os.environ.get("S6_SYM", "GC=F")                       # user 27 Nov raat: BTC bhi (BTC-USD)
SCALE = float(os.environ.get("S6_SCALE", "1"))               # 0.01 lot par $ per point: gold 1, BTC 0.01 -> bhaav x SCALE = "gold jaisa point"
LABEL = os.environ.get("S6_LABEL", "GOLD")


def fetch(interval, rng):
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{SYM}?interval={interval}&range={rng}"
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
                bars.append((t, o * SCALE, h * SCALE, l * SCALE, c * SCALE))
            return bars
        except Exception as e:
            print("fetch retry", interval, e, file=sys.stderr)
            time.sleep(4 * (i + 1))
    return []


def path_points(bar):
    t, o, h, l, c = bar
    return [o, l, h, c] if c >= o else [o, h, l, c]


BASE = dict(reentry=True, space=1.5, pairfill=1.0, guard=False, off=0.0, pairsl=None,
            arm=2.0, trail=None, lock=1.0, pair_arm=1.0, noise=0.0, limit=False, deeponly=False, allprofit=None, nolifo=False, hedgetp=None, onlynet=False, tier=False, trail1=False, resetnh=False, overlap=False, ovbank=False, ovmin=1.0, jointtp=None, netrules=False, gap=3.0, recdd=None, rectgt=1.0, triple=False, help_start=None, help_step=2.0, help_tp=1.0,
            mainlot=2.0, keep1=False, tnet=6.0, tcyc=3.0, tbsk=5.0, ttp=None, b2=False, pxreset=False)


_TCACHE = {}
def trend_arr(bars, f, sl):
    k = (id(bars), f, sl)
    if k not in _TCACHE:
        def ema(n):
            a = 2.0 / (n + 1); out = []; e = bars[0][4]
            for b in bars: e = b[4] * a + e * (1 - a); out.append(e)
            return out
        ef, es = ema(f), ema(sl)
        _TCACHE[k] = [1 if x > y else -1 for x, y in zip(ef, es)]
    return _TCACHE[k]


_SCACHE = {}
def sig_arr(bars, rule):
    k = (id(bars), rule)
    if k in _SCACHE:
        return _SCACHE[k]
    C = [b[4] for b in bars]; Hh = [b[2] for b in bars]; Ll = [b[3] for b in bars]; n = len(C)
    def ema(src, m):
        a = 2.0 / (m + 1); out = []; e = src[0]
        for x in src: e = x * a + e * (1 - a); out.append(e)
        return out
    kind = rule[0]; out = [0] * n
    if kind == "ema":
        f, sl = rule[1], rule[2]; ef, es = ema(C, f), ema(C, sl)
        out = [1 if x > y else -1 for x, y in zip(ef, es)]
    elif kind == "mom":
        N = rule[1]; out = [0 if i < N else (1 if C[i] > C[i - N] else -1) for i in range(n)]
    elif kind == "rsi":
        N, lo = 14, rule[1]; g = l = 0.0; r = [50.0] * n
        for i in range(1, n):
            ch = C[i] - C[i - 1]; up, dn = max(ch, 0), max(-ch, 0)
            if i <= N: g += up / N; l += dn / N
            else: g = (g * (N - 1) + up) / N; l = (l * (N - 1) + dn) / N
            r[i] = 100.0 if l == 0 else 100 - 100 / (1 + g / l)
        out = [1 if x > 100 - lo else (-1 if x < lo else 0) for x in r]
    elif kind == "adx":
        N, th = 14, rule[1]; tr = pdm = ndm = 0.0; ax = 0.0; out = [0] * n
        for i in range(1, n):
            up, dn = Hh[i] - Hh[i - 1], Ll[i - 1] - Ll[i]
            p_ = up if up > dn and up > 0 else 0; m_ = dn if dn > up and dn > 0 else 0
            t = max(Hh[i] - Ll[i], abs(Hh[i] - C[i - 1]), abs(Ll[i] - C[i - 1]))
            tr = tr - tr / N + t; pdm = pdm - pdm / N + p_; ndm = ndm - ndm / N + m_
            pdi = pdm / tr * 100 if tr else 0; ndi = ndm / tr * 100 if tr else 0
            dx = abs(pdi - ndi) / (pdi + ndi) * 100 if pdi + ndi else 0
            ax = ax + (dx - ax) / N
            out[i] = (1 if pdi > ndi else -1) if ax > th else 0
    elif kind == "don":
        N = rule[1]; out = [0] * n
        for i in range(N, n):
            if C[i] >= max(Hh[i - N:i]): out[i] = 1
            elif C[i] <= min(Ll[i - N:i]): out[i] = -1
    elif kind == "htf":
        f, sl, m = rule[1], rule[2], rule[3]; ef, es = ema(C, f * m), ema(C, sl * m)
        out = [1 if x > y else -1 for x, y in zip(ef, es)]
    _SCACHE[k] = out
    return out


def run_cycle(bars, start, d, bsl, max_hours, **kw):
    c = dict(BASE); c.update(kw)
    s = SPREAD
    mid0 = bars[start][1]
    end_t = bars[start][0] + max_hours * 3600
    G = c["gap"]
    anc = [0.0]                                     # user 27 Nov raat (B): koi SELL khula nahi -> ladder abhi ke bhaav se $3
    lv = lambda n: anc[0] + n * G - c["off"]
    wasH = False
    minnet = 0.0
    H = []                      # {n, o, armed, peak, id}
    R = {}
    banked = 0.0; pair_id = None; minf = 0.0; used = 0; uid = 0; trip_id = None
    helper = None                                   # user 27 Nov: madad wala BUY 0.01 (main ki disha) - gehrai o
    b2 = None                                       # user 27 Nov shaam: main ke bhaav par lautne par doosra BUY 0.01
    prevD = s
    last_mid = mid0
    t0 = bars[start][0]
    rng = random.Random(start * 2 + (d > 0)) if c["noise"] else None

    def setR(h, D):
        if c["reentry"] and D > lv(h["n"]):
            R[h["n"]] = min(D, lv(h["n"]) + 0.5 * G)

    def floor(h):
        if c["trail1"]:                              # user 27 Nov: +$3 par $2, phir $1 peeche (neeche $1 @ +$1.20)
            return max(c["lock"], h["peak"] - 1.0) if h["peak"] >= 3.0 else c["lock"]
        if c["tier"]:                                # user 27 Nov: 1 no. $3, 2 no. $2, baaki $1 lock, phir $0.20 peeche
            t = 3.0 if h["n"] == 1 else 2.0 if h["n"] == 2 else 1.0
            if h["peak"] >= t + 0.2:
                return max(t, h["peak"] - 0.2)
            return c["lock"]
        if c["trail"] is None:
            return c["lock"]
        return max(c["lock"], h["peak"] - c["trail"])

    la = c.get("lockai")
    tr = trend_arr(bars, *c.get("lockema", (20, 50))) if la == "ema" else None
    sg = sig_arr(bars, c["lockrule"]) if la == "rule" else None
    def keep_one(h, bi_, D_):
        # sirf us pal jab sabse neeche wala lock +$1 par band hone wala ho: band karo ya chalne do?
        if la == "rule":
            return bi_ > start and d * sg[bi_ - 1] < 0                     # pichhli BAND candle ka signal hedge ki disha me
        if la == "oracle2":                                                # aage dekho: chalne dena sach me behtar tha?
            for k2 in range(bi_ + 1, min(len(bars), bi_ + c.get("lookahead", 60))):
                hb, lb = bars[k2][2], bars[k2][3]
                worst = s - d * ((hb if d > 0 else lb) - mid0) - h["o"] - s
                best = s - d * ((lb if d > 0 else hb) - mid0) - h["o"] - s
                if worst <= 0.0: return False                             # pehle ghate me jaata -> band karna sahi
                if best >= h["peak"] + 1.0: return True                   # pehle naya upar -> chalne dena sahi
            return False
        return False
    for bi in range(start, len(bars)):
        bar = bars[bi]
        # user 27 Nov raat: AI faisla - hedge ki disha me chaal jaari (pullback) -> lock band nahi (hedge chalne do); palta -> lock chalu
        keep = False
        if la == "never":
            keep = True
        elif la == "ema":
            keep = (d * tr[bi - 1] < 0) if bi > start else False          # pichhli band candle ka trend hedge ki taraf
        elif la == "oracle":
            k2 = min(len(bars) - 1, bi + c.get("lookahead", 30))
            keep = d * (bars[k2][4] - bars[bi][4]) < 0                    # BHAVISHYA: aage bhaav hedge ki taraf (sirf upper seema dekhne ke liye)
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
                if c["pxreset"]:
                    if not H:
                        if wasH:
                            anc[0] = max(0.0, D)              # aakhri SELL band hua -> yahin se naya ladder
                        anc[0] = min(anc[0], max(0.0, D))    # bhaav main ki taraf aaye -> ladder bhi saath upar
                        R.clear()
                    wasH = bool(H)
                H.sort(key=lambda h: h["o"])                 # deepest last
                hpl = [D - h["o"] - s for h in H]
                mainPL = -c["mainlot"] * D
                if c["b2"] and b2 is None and (H or (c.get("b2any") and used > 0)) and prevD > s and D <= s:
                    b2 = D
                b2PL = (b2 - D - s) if b2 is not None else 0.0
                # ---- madad wala BUY: +$1 par band (sirf profit), ek samay ek; start par phir har step gehra ----
                if c["help_start"] is not None:
                    if helper is not None and (helper - D - s) >= c["help_tp"]:
                        banked += helper - D - s; helper = None
                    elif helper is None and D > prevD and D >= c["help_start"]:
                        k = int((D - c["help_start"]) // c["help_step"])
                        Lh = c["help_start"] + k * c["help_step"]
                        if prevD < Lh <= D:
                            helper = Lh
                helpPL = (helper - D - s) if helper is not None else 0.0
                tot = mainPL + sum(hpl) + helpPL + b2PL
                if tot < minf:
                    minf = tot
                dur = bar[0] - t0
                # ---- close rules (EA order) ----
                if banked + tot < minnet:
                    minnet = banked + tot
                if c["recdd"] is not None and minnet <= -c["recdd"] and banked + tot >= c["rectgt"]:   # recovery mode
                    return ("REC", banked + tot, minf, dur, used)
                if banked + tot >= c["tnet"]:
                    return ("NET6", banked + tot, minf, dur, used)
                if c.get("be_after") is not None and dur >= c["be_after"] * 3600 and banked + tot >= c.get("be_tgt", 0.0):   # user 27 Nov raat: sideways me der ho to chhota target
                    return ("BE", banked + tot, minf, dur, used)
                if not H:
                    if mainPL + b2PL >= (c["ttp"] if c["ttp"] is not None else 3.0 * c["mainlot"]):
                        return ("TP", banked + mainPL + helpPL + b2PL, minf, dur, used)
                else:
                    if not c["onlynet"] and (banked + tot if c["netrules"] else tot) >= (c["tcyc"] if mainPL >= 0 else c["tbsk"]):
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
                if c["jointtp"] is not None and len(H) >= 2 and hpl[-1] >= c["jointtp"]:   # user: naya (gehra) +$1 -> sab hedge band
                    banked += sum(hpl)
                    for h in list(H):
                        H.remove(h); setR(h, D)
                    closed = True; pair_id = None
                elif c["nolifo"]:                              # SEEDHA: har hedge apne aap (koi kram / jodi nahi)
                    for h, p in list(zip(H, hpl)):
                        if (c["hedgetp"] is not None and p >= c["hedgetp"]) or (c["hedgetp"] is None and h["armed"] and p <= floor(h)):
                            banked += p; H.remove(h); setR(h, D); closed = True
                    if not closed and c.get("indpair") and len(H) >= 2 and not H[-1]["armed"]:   # khud-band + gehri jodi niyam
                        b = H[-1]; a = H[-2]; cb = (D - a["o"] - s) + (D - b["o"] - s)
                        if cb > c["pair_arm"]:
                            pair_id = b["id"]
                        if (pair_id == b["id"] and cb <= c["lock"]) or (c["pairsl"] is not None and pair_id != b["id"] and cb <= -c["pairsl"]):
                            banked += cb; H.pop(); H.pop(); setR(b, D); setR(a, D); pair_id = None; closed = True
                        elif c["triple"] and len(H) >= 3 and pair_id != b["id"]:      # user 27 Nov raat: sab niyam saath - tikdi bhi
                            z = H[-3]; c3 = (D - z["o"] - s) + cb
                            if c3 > c["pair_arm"]:
                                trip_id = b["id"]
                            if trip_id == b["id"] and c3 <= c["lock"]:
                                banked += c3; H.pop(); H.pop(); H.pop(); setR(b, D); setR(a, D); setR(z, D); trip_id = None; closed = True
                elif H:
                    b = H[-1]; pb = hpl[-1]
                    keepb = c["keep1"] and b["n"] == 1             # user: 1 number SELL sirf cycle par
                    if keepb:
                        pass
                    elif b["armed"]:
                        if pb <= floor(b) and not (la in ("rule", "oracle2") and keep_one(b, bi, D)):
                            banked += pb; H.pop(); setR(b, D); closed = True
                    elif len(H) >= 2 and not (c["keep1"] and H[-2]["n"] == 1):
                        a = H[-2]; cb = hpl[-2] + pb
                        if cb > c["pair_arm"]:
                            pair_id = b["id"]
                        if pair_id == b["id"] and cb <= c["lock"]:
                            banked += cb; H.pop(); H.pop(); setR(b, D); setR(a, D); pair_id = None; closed = True
                        elif c["pairsl"] is not None and pair_id != b["id"] and cb <= -c["pairsl"]:
                            banked += cb; H.pop(); H.pop(); setR(b, D); setR(a, D); pair_id = None; closed = True
                        elif c["triple"] and len(H) >= 3 and pair_id != b["id"]:      # user: jodi se na bane to gehre 3 milake +$1
                            z = H[-3]; c3 = hpl[-3] + cb
                            if c3 > c["pair_arm"]:
                                trip_id = b["id"]
                            if trip_id == b["id"] and c3 <= c["lock"]:
                                banked += c3; H.pop(); H.pop(); H.pop(); setR(b, D); setR(a, D); setR(z, D); trip_id = None; closed = True
                # ---- overlap ("close minus by plus"): sabse ghate wala hedge + profit wale hedge saath, kul >= +$0.5 ----
                if c["overlap"] and not closed and len(H) >= 1:
                    pl = {id(h): D - h["o"] - s for h in H}
                    W = min(H, key=lambda h: pl[id(h)])
                    if pl[id(W)] <= -c["ovmin"]:
                        acc = pl[id(W)]; chosen = []
                        for h in sorted((h for h in H if h is not W and pl[id(h)] > 0), key=lambda h: -pl[id(h)]):
                            if acc >= 0.5:
                                break
                            chosen.append(h); acc += pl[id(h)]
                        ok = acc >= 0.5 or (c["ovbank"] and banked + acc >= 0.5 and pl[id(W)] <= -3.0)   # B: pakke profit se bhi chuka sakte
                        if ok:
                            for h in [W] + chosen:
                                H.remove(h); setR(h, D)
                            banked += acc; closed = True; pair_id = None
                # ---- re-entry back to exact level ----
                if c["resetnh"] and not H:                  # user 27 Nov: koi hedge khula nahi -> sab pending theek $3 level par
                    R.clear()
                for n in list(R.keys()):
                    if D < lv(n):
                        R.pop(n)
                # ---- pending fills (STOP: depth crosses the trigger going deeper) ----
                if not closed and D > prevD:
                    occ = {h["n"] for h in H}
                    nmax = int((D - anc[0] + c["off"]) / G) + 2
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
                    for n in range(1, int((prevD + c["off"]) / G) + 2):
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
    tot = -c["mainlot"] * D + sum(D - h["o"] - s for h in H) + ((helper - D - s) if helper is not None else 0.0) + ((b2 - D - s) if b2 is not None else 0.0)
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
          f"BSL/OPEN={bad:3d} hedges/cyc={statistics.mean(r['used'] for r in rows):5.1f} medDur={dur:5.0f}m "
          f"$/hr={sum(pl) / max(1e-9, sum(r['dur'] for r in rows) / 3600):6.2f}  "
          + " ".join(f"{k}:{v}" for k, v in sorted(kinds.items())))


SIMPLE = dict(nolifo=True, reentry=False, onlynet=True, pairfill=None)
V93 = dict(pairsl=2.0, arm=1.2, deeponly=True)
USER = dict(nolifo=True, reentry=False, deeponly=True, resetnh=True, jointtp=1.0, pairfill=None)
V92 = dict(pairsl=2.0, arm=1.2)
V92 = dict(pairsl=2.0, arm=1.2)
NEWP = dict(arm=1.2, triple=True, resetnh=True)          # user 27 Nov: +$1 single/jodi/tikdi, -$2 kat nahi, reset
V90 = dict(pairsl=None, arm=2.0)                       # v9.0 niyam (lock +2 -> +1, jodi +1, -$2 kat nahi)
NEW1 = dict(V90, mainlot=1.0, tnet=2.0, tcyc=2.0, tbsk=2.0, ttp=2.0, b2=True)
E103 = dict(NEW1, keep1=False, nolifo=True, indpair=True, triple=True)
V104 = dict(NEW1, keep1=False, triple=True, allprofit=0.0, b2any=True)   # user 27 Nov raat: neeche se + jodi + tikdi + naya SELL sirf jab upar wale profit me
VARS = [
    ("v10.5 (abhi ka EA)", dict(V104)),
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
        study(f"{LABEL} 1m (7 days), start every 30 min, max 48h", b1, 30, 48)
    else:
        print("1m data not available")
    b5 = fetch("5m", "60d")
    if b5:
        study(f"{LABEL} 5m (60 days), start every 2h, max 72h", b5, 120, 72)
    else:
        print("5m data not available")


if __name__ == "__main__":
    main()
