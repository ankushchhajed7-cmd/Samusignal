from lab import *
DEV=SPLITS['DEV']
def show(name, st): print(f"{name:52s} SR={st['sr']:+.2f} t={st['t']:+.2f} ann={st['ann']*100:+.2f}% pf={st['pf']:.2f} n={st['n']}")
def devd(pnl):
    d=pnl.resample('1D').sum()[DEV[0]:DEV[1]]; d=d[d.index.dayofweek<5]; return stats_from_daily(d)
for pair in ['EURUSD','XAUUSD']:
    df=load(pair); hr=df.index.hour; print('=====',pair)
    # H10 weekend gap fade: first bar of week opens vs last close of prev week
    gapbars = df.index.to_series().diff() > pd.Timedelta(hours=30)
    idx=np.where(gapbars.values)[0]
    for thr in [0.0, 0.002, 0.004]:
      for hold in [4, 12, 24]:
        rs=[];ts=[]
        for i in idx:
            if i+hold>=len(df): continue
            pc=df.c.iloc[i-1]; o=df.o.iloc[i]; g=o/pc-1
            if abs(g)<thr: continue
            d=-np.sign(g); tgt=pc
            ex=df.c.iloc[i+hold-1]
            # exit at gap fill if touched
            seg=df.iloc[i:i+hold]
            hit = (seg.l<=tgt).values if d<0 else (seg.h>=tgt).values
            if hit.any(): ex=tgt
            rs.append(d*(ex-o)/o - COST[pair]*1.5/o)  # wider Sunday spread
            ts.append(df.index[i])
        s=pd.Series(rs,index=ts)[DEV[0]:DEV[1]]
        if len(s)>5: print(f"H10 gap fade thr={thr} hold={hold}: n={len(s)} mean={s.mean()*1e4:+.2f}bp t={s.mean()/s.std()*np.sqrt(len(s)):+.2f} win={(s>0).mean():.2f}")
    # H12 weekly TSMOM, vol targeted, rebalance Fridays close
    dd=daily(df); wk=dd.c.resample('W-FRI').last().dropna()
    for L in [4,12,26,52]:
        sig=np.sign(wk/wk.shift(L)-1)
        s=sig.reindex(df.index, method='ffill').shift(1).fillna(0)
        show(f'H12 weekly TSMOM L={L}w', devd(pos_pnl(df,s,pair,carry=True)))
    # H11 session legs
    for name,hours,sgn in [('asia long 1-5',[1,2,3,4,5],1),('long 2+5 only',[2,5],1),('london short 7-10',[7,8,9,10],-1),('eur long 1-3',[1,2,3],1)]:
        pos=pd.Series(np.where(np.isin(hr,[h-1 for h in hours]) & False,0,0),index=df.index,dtype=float)
        # position held during bar h means decided at close of bar h-1
        held=np.isin(hr,hours)
        pos=pd.Series(np.where(held,sgn,0.0),index=df.index).shift(-1).fillna(0)
        show(f'H11 {name}', devd(pos_pnl(df,pos,pair)))
