//+------------------------------------------------------------------+
//|                                   EMA20 M5 SCALPING v1.01.mq5      |
//|                                   Ankush New Vision                |
//|                                                                    |
//|  Strategy: Tanisha Garg - "The Best 5-Minute Scalping Strategy"    |
//|  (youtu.be/KjPH6Fv1T6M). EMA 20, 5 min. Ek chart pe lagao - EA     |
//|  saare forex pair khud scan karta hai (gold / BTC nahi).           |
//|                                                                    |
//|  BUY (video wala):                                                 |
//|   Step 1: GREEN candle jo EMA 20 ko neeche se cross karke UPAR     |
//|           close ho. Is candle pe trade NAHI.                       |
//|   Step 2: Agli 2 candle me se koi ek RED ho jo EMA ke UPAR hi      |
//|           close ho. Beech me koi candle EMA ke neeche close ho     |
//|           gayi to setup cancel.                                    |
//|   Step 3: Chart ka price (BID) us RED candle ka HIGH tode ->       |
//|           turant ENTRY (market). EA khud price dekhta hai          |
//|           ("virtual stop") - broker pe pending order nahi.         |
//|   SL    : M5 candle EMA ke NEECHE close = trade band (video).      |
//|           Plus HARD SL (setup ka low - buffer, min/max pips).      |
//|   Trail : Profit TrailStartPips pe pahunche -> SL entry (+Lock)    |
//|           pe; phir price jitna badhe SL utna peeche-peeche upar    |
//|           (TrailDistancePips duri pe). SL kabhi neeche nahi aata.  |
//|  SELL: bilkul ulta (red candle EMA ke neeche close -> agli 2 me    |
//|        green jo EMA ke neeche close ho -> BID uska LOW tode).      |
//|                                                                    |
//|  CHANGELOG                                                         |
//|  v1.01 (16-Nov-2026) Galat entry ka fix + trailing SL.             |
//|   * BUG FIX: v1.00 me broker stop-level ki wajah se EA kai baar    |
//|     red candle band hote hi MARKET trade le leta tha, high toote   |
//|     bina (GBPCAD 1.88601 jaise). Ab "virtual stop": entry tabhi    |
//|     jab BID sach me high/low tode. Spread zyada ho to wait.        |
//|   * Spread spike (rollover) pe Ask ki wajah se entry ab nahi.      |
//|   * EMA ab EA khud candles se nikalta hai - dusre pair ka purana   |
//|     (1 candle late) EMA padhne ki galti khatam.                    |
//|   * Session filter: server time 07:00-24:00 (Exness = GMT).        |
//|     00-07 (Asian, spread zyada) me naya trade nahi.                |
//|   * Trailing SL: TrailStart 15 pip -> SL entry+1 pip, phir 10 pip  |
//|     peeche chalta hai (TrailStep 1 pip).                           |
//|   * Purane v1.00 ke bache hue pending order start pe delete.       |
//|  v1.00 (15-Nov-2026) Pehla build.                                  |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.01"
#property description "EMA20 M5 SCALPING v1.01 - all forex pairs"
#property description "Green close above EMA20 -> red retest -> BID breaks red high = buy (sell = ulta)"

#include <Trade/Trade.mqh>

//--- inputs
input group "=== Pairs ==="
input string PairsCSV        = "";     // Pairs (khaali = saare forex pair apne aap)
input string ExcludeCSV      = "";     // In pair par trade nahi (jaise EURGBP,USDCHF)
input bool   MajorsOnly      = true;   // Sirf 8 major currency (28 pair)
input int    MaxPairs        = 40;     // Zyada se zyada kitne pair scan

input group "=== Strategy ==="
input ENUM_TIMEFRAMES TF     = PERIOD_M5; // Timeframe
input int    EmaPeriod       = 20;     // EMA period
input bool   TradeBuy        = true;   // BUY setup
input bool   TradeSell       = true;   // SELL setup
input bool   RequireCross    = true;   // Step 1 candle EMA ko cross kare (false = sirf touch)
input int    ConfirmBars     = 2;      // Step 2: agli kitni candle me red/green chahiye
input double EntryBufferPips = 0.2;    // High/Low ke paar kitna tootna chahiye (pips)
input double MaxChasePips    = 1.0;    // Break ke baad price itne pips se zyada door -> skip
input bool   CancelOnEmaClose= true;   // Candle EMA ke ulta close -> setup cancel
input int    ExpiryBars      = 0;      // Break ka wait kitni candle (0 = limit nahi)

input group "=== Session (server time) ==="
input bool   UseSession      = true;   // Session filter
input int    StartHour       = 7;      // Naya trade is ghante se (server)
input int    EndHour         = 24;     // Is ghante tak (24 = raat 12)

input group "=== Exit / SL ==="
input bool   EmaCloseExit    = true;   // Candle EMA ke ulta close -> trade band (video SL)
input double SLBufferPips    = 1.0;    // Hard SL: setup low/high ke paar buffer (pips)
input double MinSLPips       = 3.0;    // Hard SL kam se kam (pips)
input double MaxSLPips       = 20.0;   // Hard SL zyada se zyada (pips)
input double TP_RR           = 0.0;    // Fixed TP = RR x SL (0 = TP nahi, rally ride)

input group "=== Trailing SL (breakeven -> trail) ==="
input bool   UseTrail        = true;   // Trailing SL on
input double TrailStartPips  = 15.0;   // Itna profit -> SL entry pe (breakeven)
input double TrailLockPips   = 1.0;    // Breakeven pe kitna profit lock (pips)
input double TrailDistancePips = 10.0; // Phir SL price se itna peeche chalega (pips)
input double TrailStepPips   = 1.0;    // SL kam se kam itna khiske tab hi modify (pips)

input group "=== Risk ==="
input double Lot             = 0.01;   // Lot
input double MaxSpreadPips   = 3.0;    // Is se zyada spread -> entry ka wait
input int    MaxOpenTotal    = 10;     // Saare pair milake max trade
input ulong  Magic           = 2026520;// Magic number (v1.00 wala hi)
input bool   ShowPanel       = true;   // Chart pe panel

#define EMA_BARS 300

//--- per-pair state
struct PairState
  {
   string   sym;
   datetime lastBar;
   int      bStage;     // 0 = kuch nahi, 1 = green mila, red ka wait
   int      bWait;
   double   bSigLow;
   int      sStage;     // 0 = kuch nahi, 1 = red mila, green ka wait
   int      sWait;
   double   sSigHigh;
   bool     vb;         // virtual BUY stop
   double   vbLevel, vbExt;
   datetime vbBar;
   bool     vs;         // virtual SELL stop
   double   vsLevel, vsExt;
   datetime vsBar;
   string   status;
  };

PairState P[];
int       NP = 0;
CTrade    trade;

string MAJORS = ",USD,EUR,GBP,JPY,CHF,AUD,NZD,CAD,";
string FIATS  = ",USD,EUR,GBP,JPY,CHF,AUD,NZD,CAD,SGD,HKD,NOK,SEK,DKK,PLN,ZAR,MXN,TRY,CNH,HUF,CZK,";

//+------------------------------------------------------------------+
string Up(string s){ StringToUpper(s); return s; }

bool InCSV(string csv, string sym)
  {
   if(csv=="") return false;
   string parts[];
   int n = StringSplit(Up(csv), ',', parts);
   string u = Up(sym);
   for(int i=0;i<n;i++)
     {
      string p = parts[i];
      StringTrimLeft(p); StringTrimRight(p);
      if(p!="" && StringFind(u,p)==0) return true;
     }
   return false;
  }

bool IsForex(string sym)
  {
   string b = Up(SymbolInfoString(sym, SYMBOL_CURRENCY_BASE));
   string q = Up(SymbolInfoString(sym, SYMBOL_CURRENCY_PROFIT));
   if(StringLen(b)!=3 || StringLen(q)!=3 || b==q) return false;
   string list = MajorsOnly ? MAJORS : FIATS;
   if(StringFind(list, ","+b+",")<0 || StringFind(list, ","+q+",")<0) return false;
   if(SymbolInfoInteger(sym, SYMBOL_TRADE_MODE)!=SYMBOL_TRADE_MODE_FULL) return false;
   return true;
  }

bool HasPairKey(string &keys[], string k)
  {
   for(int i=0;i<ArraySize(keys);i++) if(keys[i]==k) return true;
   return false;
  }

void AddPair(string sym)
  {
   if(NP>=MaxPairs) return;
   if(!SymbolSelect(sym, true)) return;
   ArrayResize(P, NP+1);
   P[NP].sym = sym;  P[NP].lastBar = 0;
   P[NP].bStage = 0; P[NP].bWait = 0; P[NP].bSigLow = 0;
   P[NP].sStage = 0; P[NP].sWait = 0; P[NP].sSigHigh = 0;
   P[NP].vb = false; P[NP].vbLevel = 0; P[NP].vbExt = 0; P[NP].vbBar = 0;
   P[NP].vs = false; P[NP].vsLevel = 0; P[NP].vsExt = 0; P[NP].vsBar = 0;
   P[NP].status = "shuru";
   NP++;
  }

void BuildPairs()
  {
   NP = 0; ArrayResize(P, 0);
   if(PairsCSV!="")
     {
      string parts[];
      int n = StringSplit(PairsCSV, ',', parts);
      for(int i=0;i<n;i++)
        {
         string p = parts[i]; StringTrimLeft(p); StringTrimRight(p);
         if(p=="") continue;
         string found = "";
         if(SymbolSelect(p, true)) found = p;
         else
           {
            for(int j=0;j<SymbolsTotal(false);j++)
              {
               string s = SymbolName(j, false);
               if(StringFind(Up(s), Up(p))==0 && StringLen(s)<=StringLen(p)+3){ found = s; break; }
              }
           }
         if(found!="" && !InCSV(ExcludeCSV, found)) AddPair(found);
         else if(found=="") Print("Pair nahi mila: ", p);
        }
      return;
     }
   string keys[];
   for(int pass=0; pass<2; pass++)
     {
      int total = SymbolsTotal(pass==0);
      for(int i=0;i<total;i++)
        {
         string s = SymbolName(i, pass==0);
         if(!IsForex(s) || InCSV(ExcludeCSV, s)) continue;
         string k = Up(SymbolInfoString(s, SYMBOL_CURRENCY_BASE))+Up(SymbolInfoString(s, SYMBOL_CURRENCY_PROFIT));
         if(HasPairKey(keys, k)) continue;
         int ks = ArraySize(keys); ArrayResize(keys, ks+1); keys[ks] = k;
         AddPair(s);
        }
     }
  }

//+------------------------------------------------------------------+
double Pip(string sym)
  {
   int d = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt = SymbolInfoDouble(sym, SYMBOL_POINT);
   return (d==3 || d==5) ? pt*10.0 : pt;
  }

int Dg(string sym){ return (int)SymbolInfoInteger(sym, SYMBOL_DIGITS); }

double NormP(string sym, double price){ return NormalizeDouble(price, Dg(sym)); }

double NormLot(string sym, double lot)
  {
   double mn = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double mx = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   double st = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(st<=0) st = 0.01;
   lot = MathFloor(lot/st+1e-9)*st;
   if(lot<mn) lot = mn;
   if(lot>mx) lot = mx;
   return NormalizeDouble(lot, 2);
  }

double StopLvl(string sym)
  {
   return (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*SymbolInfoDouble(sym, SYMBOL_POINT);
  }

bool InSession()
  {
   if(!UseSession) return true;
   MqlDateTime t; TimeToStruct(TimeCurrent(), t);
   int h = t.hour;
   if(StartHour<=EndHour) return (h>=StartHour && h<EndHour);
   return (h>=StartHour || h<EndHour);           // raat paar wala session
  }

// is pair par hamari position (0 = nahi, 1 = buy, -1 = sell)
int PosDir(string sym, ulong &ticket)
  {
   ticket = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong t = PositionGetTicket(i);
      if(t==0) continue;
      if(PositionGetString(POSITION_SYMBOL)!=sym || (ulong)PositionGetInteger(POSITION_MAGIC)!=Magic) continue;
      ticket = t;
      return (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ? 1 : -1;
     }
   return 0;
  }

int CountPositions()
  {
   int c = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong t = PositionGetTicket(i);
      if(t!=0 && (ulong)PositionGetInteger(POSITION_MAGIC)==Magic) c++;
     }
   return c;
  }

// v1.00 ke bache broker pending (isi magic) hatao
void DeleteOldPendings()
  {
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong t = OrderGetTicket(i);
      if(t==0 || (ulong)OrderGetInteger(ORDER_MAGIC)!=Magic) continue;
      string s = OrderGetString(ORDER_SYMBOL);
      if(trade.OrderDelete(t)) Print(s, " purana v1.00 pending delete");
     }
  }

//+------------------------------------------------------------------+
//  Hard SL: setup extreme se buffer, min/max pips ke beech
double HardSL(string sym, bool buy, double entry, double extreme)
  {
   double pip = Pip(sym);
   double sl  = buy ? extreme - SLBufferPips*pip : extreme + SLBufferPips*pip;
   double dist = MathAbs(entry - sl);
   if(buy && sl >= entry)  dist = 0;
   if(!buy && sl <= entry) dist = 0;
   if(dist < MinSLPips*pip) dist = MinSLPips*pip;
   if(MaxSLPips>0 && dist > MaxSLPips*pip) dist = MaxSLPips*pip;
   double lvl = StopLvl(sym);
   if(dist < lvl + pip*0.5) dist = lvl + pip*0.5;
   return NormP(sym, buy ? entry - dist : entry + dist);
  }

//  Step 3 poora: BID ne level toda -> market entry
bool OpenTrade(int i, bool buy, double extreme)
  {
   string sym = P[i].sym;
   double pip = Pip(sym);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   double lot = NormLot(sym, Lot);
   trade.SetTypeFillingBySymbol(sym);
   string cmt = buy ? "EMA20 B" : "EMA20 S";
   bool ok;
   if(buy)
     {
      double sl = HardSL(sym, true, ask, extreme);
      double tp = (TP_RR>0) ? NormP(sym, ask + TP_RR*(ask-sl)) : 0;
      ok = trade.Buy(lot, sym, 0, sl, tp, cmt);
     }
   else
     {
      double sl = HardSL(sym, false, bid, extreme);
      double tp = (TP_RR>0) ? NormP(sym, bid - TP_RR*(sl-bid)) : 0;
      ok = trade.Sell(lot, sym, 0, sl, tp, cmt);
     }
   if(ok){ P[i].status = (buy?"BUY khula ":"SELL khula ")+DoubleToString(buy?ask:bid, Dg(sym)); Print(sym, " ", P[i].status); }
   else    P[i].status = (buy?"BUY fail ":"SELL fail ")+IntegerToString(trade.ResultRetcode());
   return ok;
  }

//  Har tick/second: virtual stop toota kya?
void CheckTriggers(int i)
  {
   string sym = P[i].sym;
   ulong pt;
   if(PosDir(sym, pt)!=0){ P[i].vb = false; P[i].vs = false; return; }
   if(!P[i].vb && !P[i].vs) return;

   double pip = Pip(sym);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   if(bid<=0 || ask<=0) return;
   double spreadPips = (ask-bid)/pip;

   if(P[i].vb && bid >= P[i].vbLevel)
     {
      if(bid - P[i].vbLevel > MaxChasePips*pip){ P[i].vb = false; P[i].status = "BUY miss: price bahut upar nikal gaya"; return; }
      if(!InSession())                         { P[i].status = "BUY break - session band, wait"; return; }
      if(spreadPips > MaxSpreadPips)            { P[i].status = StringFormat("BUY break - spread %.1f pip, wait", spreadPips); return; }
      if(CountPositions() >= MaxOpenTotal)      { P[i].status = "BUY break - MaxOpenTotal poora"; return; }
      if(OpenTrade(i, true, P[i].vbExt)){ P[i].vb = false; P[i].vs = false; }
      return;
     }
   if(P[i].vs && bid <= P[i].vsLevel)
     {
      if(P[i].vsLevel - bid > MaxChasePips*pip){ P[i].vs = false; P[i].status = "SELL miss: price bahut neeche nikal gaya"; return; }
      if(!InSession())                         { P[i].status = "SELL break - session band, wait"; return; }
      if(spreadPips > MaxSpreadPips)            { P[i].status = StringFormat("SELL break - spread %.1f pip, wait", spreadPips); return; }
      if(CountPositions() >= MaxOpenTotal)      { P[i].status = "SELL break - MaxOpenTotal poora"; return; }
      if(OpenTrade(i, false, P[i].vsExt)){ P[i].vb = false; P[i].vs = false; }
     }
  }

//  Trailing SL: pehle breakeven (+lock), phir price ke peeche-peeche
void ManageTrail(int i)
  {
   if(!UseTrail) return;
   string sym = P[i].sym;
   ulong t;
   int dir = PosDir(sym, t);
   if(dir==0 || !PositionSelectByTicket(t)) return;
   double pip  = Pip(sym);
   double open = PositionGetDouble(POSITION_PRICE_OPEN);
   double sl   = PositionGetDouble(POSITION_SL);
   double tp   = PositionGetDouble(POSITION_TP);
   double bid  = SymbolInfoDouble(sym, SYMBOL_BID);
   double ask  = SymbolInfoDouble(sym, SYMBOL_ASK);
   double lvl  = StopLvl(sym);
   if(dir==1)
     {
      double prof = (bid - open)/pip;
      if(prof < TrailStartPips) return;
      double nsl = MathMax(open + TrailLockPips*pip, bid - TrailDistancePips*pip);
      if(nsl > bid - lvl) nsl = bid - lvl - SymbolInfoDouble(sym, SYMBOL_POINT);
      nsl = NormP(sym, nsl);
      if(sl==0 || nsl >= sl + TrailStepPips*pip)
         if(trade.PositionModify(t, nsl, tp)) P[i].status = "BUY trail SL "+DoubleToString(nsl, Dg(sym));
     }
   else
     {
      double prof = (open - ask)/pip;
      if(prof < TrailStartPips) return;
      double nsl = MathMin(open - TrailLockPips*pip, ask + TrailDistancePips*pip);
      if(nsl < ask + lvl) nsl = ask + lvl + SymbolInfoDouble(sym, SYMBOL_POINT);
      nsl = NormP(sym, nsl);
      if(sl==0 || nsl <= sl - TrailStepPips*pip)
         if(trade.PositionModify(t, nsl, tp)) P[i].status = "SELL trail SL "+DoubleToString(nsl, Dg(sym));
     }
  }

//+------------------------------------------------------------------+
//  Nayi M5 candle band hui -> sab kuch yahan. EMA khud candles se.
void OnNewBar(int i)
  {
   string sym = P[i].sym;
   MqlRates r[];
   ArraySetAsSeries(r, false);                          // purani -> nayi
   int n = CopyRates(sym, TF, 1, EMA_BARS, r);
   if(n < EmaPeriod + 50){ P[i].status = "history kam - wait"; P[i].lastBar = 0; return; }

   // EMA (MT5 jaisa: pehla seed SMA, phir k = 2/(N+1))
   double k = 2.0/(EmaPeriod+1.0);
   double ema = 0;
   for(int j=0;j<EmaPeriod;j++) ema += r[j].close;
   ema /= EmaPeriod;
   double e2 = ema, e1 = ema;
   for(int j=EmaPeriod;j<n;j++)
     {
      ema = r[j].close*k + ema*(1.0-k);
      if(j==n-2) e2 = ema;
      if(j==n-1) e1 = ema;
     }

   double c1 = r[n-1].close, o1 = r[n-1].open, h1 = r[n-1].high, l1 = r[n-1].low;
   double c2 = r[n-2].close;
   datetime b1 = r[n-1].time;
   bool green = c1 > o1, red = c1 < o1;
   bool closeAbove = c1 > e1, closeBelow = c1 < e1;
   double pip = Pip(sym);

   // 1) EXIT: candle EMA ke ulta close (video ka SL)
   ulong pt; int dir = PosDir(sym, pt);
   if(EmaCloseExit && dir!=0)
     {
      if((dir==1 && closeBelow) || (dir==-1 && closeAbove))
        {
         if(trade.PositionClose(pt)){ Print(sym, " trade band: candle EMA ke ", (dir==1?"neeche":"upar"), " close"); P[i].status = "trade band (EMA close)"; }
         dir = 0;
        }
     }

   // 2) Virtual stop cancel: EMA ulta close / expiry
   if(P[i].vb)
     {
      bool exp = (ExpiryBars>0 && (int)((b1 - P[i].vbBar)/PeriodSeconds(TF)) >= ExpiryBars);
      if((CancelOnEmaClose && closeBelow) || exp){ P[i].vb = false; P[i].status = exp ? "BUY wait khatam (expiry)" : "BUY cancel (EMA ke neeche close)"; }
     }
   if(P[i].vs)
     {
      bool exp = (ExpiryBars>0 && (int)((b1 - P[i].vsBar)/PeriodSeconds(TF)) >= ExpiryBars);
      if((CancelOnEmaClose && closeAbove) || exp){ P[i].vs = false; P[i].status = exp ? "SELL wait khatam (expiry)" : "SELL cancel (EMA ke upar close)"; }
     }

   string st1 = "";
   // 3) BUY setup
   if(TradeBuy)
     {
      if(P[i].bStage==1)
        {
         P[i].bWait++;
         if(closeBelow){ P[i].bStage = 0; st1 = "BUY setup cancel (EMA ke neeche close)"; }
         else if(red && closeAbove)
           {
            P[i].bStage = 0;
            if(dir==0)
              {
               P[i].vb = true; P[i].vbLevel = h1 + EntryBufferPips*pip;
               P[i].vbExt = MathMin(P[i].bSigLow, l1); P[i].vbBar = b1;
               st1 = "BUY ready: BID > "+DoubleToString(P[i].vbLevel, Dg(sym))+" pe entry";
              }
            else st1 = "BUY setup - trade pehle se chalu, skip";
           }
         else if(P[i].bWait >= ConfirmBars){ P[i].bStage = 0; st1 = "BUY setup cancel (red nahi aayi)"; }
         else st1 = StringFormat("BUY: red ka wait (%d/%d)", P[i].bWait, ConfirmBars);
        }
      bool sig = green && closeAbove && (RequireCross ? (o1 < e1 || c2 < e2) : (l1 <= e1));
      if(sig)
        {
         P[i].bStage = 1; P[i].bWait = 0; P[i].bSigLow = l1;
         st1 = "BUY Step1: green EMA ke upar close";
        }
     }
   // 4) SELL setup (ulta)
   if(TradeSell)
     {
      if(P[i].sStage==1)
        {
         P[i].sWait++;
         if(closeAbove){ P[i].sStage = 0; st1 = "SELL setup cancel (EMA ke upar close)"; }
         else if(green && closeBelow)
           {
            P[i].sStage = 0;
            if(dir==0)
              {
               P[i].vs = true; P[i].vsLevel = l1 - EntryBufferPips*pip;
               P[i].vsExt = MathMax(P[i].sSigHigh, h1); P[i].vsBar = b1;
               st1 = "SELL ready: BID < "+DoubleToString(P[i].vsLevel, Dg(sym))+" pe entry";
              }
            else st1 = "SELL setup - trade pehle se chalu, skip";
           }
         else if(P[i].sWait >= ConfirmBars){ P[i].sStage = 0; st1 = "SELL setup cancel (green nahi aayi)"; }
         else st1 = StringFormat("SELL: green ka wait (%d/%d)", P[i].sWait, ConfirmBars);
        }
      bool sig = red && closeBelow && (RequireCross ? (o1 > e1 || c2 > e2) : (h1 >= e1));
      if(sig)
        {
         P[i].sStage = 1; P[i].sWait = 0; P[i].sSigHigh = h1;
         st1 = "SELL Step1: red EMA ke neeche close";
        }
     }
   if(st1!="") P[i].status = st1;
  }

//+------------------------------------------------------------------+
void Panel()
  {
   if(!ShowPanel) return;
   string s = "EMA20 M5 SCALPING v1.01  |  pairs: "+IntegerToString(NP)+"  |  trade: "+IntegerToString(CountPositions())+"/"+IntegerToString(MaxOpenTotal)+"  |  session: "+(InSession()?"ON":"BAND")+"\n";
   s += "Lot "+DoubleToString(Lot,2)+"  |  Hard SL "+DoubleToString(MinSLPips,0)+"-"+DoubleToString(MaxSLPips,0)+" pip  |  Trail: "+(UseTrail?DoubleToString(TrailStartPips,0)+" pip pe BE, phir "+DoubleToString(TrailDistancePips,0)+" pip peeche":"off")+"\n";
   s += "------------------------------------------------\n";
   for(int i=0;i<NP;i++)
     {
      ulong pt; int d = PosDir(P[i].sym, pt);
      string pos = (d==1) ? "[BUY chalu] " : (d==-1) ? "[SELL chalu] " : "";
      s += P[i].sym+"   "+pos+P[i].status+"\n";
     }
   Comment(s);
  }

void Work()
  {
   for(int i=0;i<NP;i++)
     {
      CheckTriggers(i);
      ManageTrail(i);
      datetime t0 = iTime(P[i].sym, TF, 0);
      if(t0==0) continue;
      if(P[i].lastBar==0){ P[i].lastBar = t0; if(P[i].status=="shuru") P[i].status = "ready - nayi candle ka wait"; continue; }
      if(t0!=P[i].lastBar)
        {
         P[i].lastBar = t0;
         OnNewBar(i);
        }
     }
   Panel();
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(Magic);
   trade.SetDeviationInPoints(20);
   BuildPairs();
   if(NP==0){ Print("Koi forex pair nahi mila - PairsCSV bharo"); return INIT_FAILED; }
   DeleteOldPendings();
   string list = "";
   for(int i=0;i<NP;i++) list += P[i].sym+" ";
   Print("EMA20 M5 SCALPING v1.01 shuru. Pairs (", NP, "): ", list);
   EventSetTimer(1);
   Work();
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   Comment("");
  }

void OnTick()  { Work(); }
void OnTimer() { Work(); }
//+------------------------------------------------------------------+
