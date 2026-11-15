//+------------------------------------------------------------------+
//|                                   EMA20 M5 SCALPING v1.00.mq5      |
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
//|           close ho (neeche na jaye). Pehli hi red mil gayi to      |
//|           dusri ka wait nahi. Beech me koi candle EMA ke neeche    |
//|           close ho gayi to setup cancel.                           |
//|   Step 3: Us RED candle ka HIGH koi bhi candle tode -> ENTRY       |
//|           (close ka wait nahi, high toot-te hi). = BUY STOP.       |
//|   SL    : Video: M5 candle EMA ke NEECHE close = trade band.       |
//|           Plus HARD SL (setup ka low - buffer, min/max pips).      |
//|   Target: Fixed nahi - rally ride (EMA close exit). TP_RR > 0      |
//|           karo to fixed TP bhi lag jayega.                         |
//|  SELL: bilkul ulta (red candle EMA ke neeche close -> agli 2 me    |
//|        green jo EMA ke neeche close ho -> uske LOW pe SELL STOP).  |
//|                                                                    |
//|  Pending order delete: candle EMA ke ulta close ho jaye, ya        |
//|  ExpiryBars poore ho jaye (0 = koi limit nahi), ya trade khul      |
//|  jaye (usi pair ka dusra pending bhi hat jata hai).                |
//|  Ek pair pe ek hi trade. Sab kuch sirf BAND candle pe (repaint     |
//|  nahi). Tester: "Every tick based on real ticks".                  |
//|                                                                    |
//|  CHANGELOG                                                         |
//|  v1.00 (15-Nov-2026) Pehla build.                                  |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.00"
#property description "EMA20 M5 SCALPING v1.00 - all forex pairs"
#property description "Green close above EMA20 -> red retest -> buy stop at red high (sell = ulta)"

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
input double EntryBufferPips = 0.2;    // High/Low ke paar entry buffer (pips)
input double MaxChasePips    = 1.0;    // High pehle toot gaya to itne pips tak market entry
input bool   CancelOnEmaClose= true;   // Candle EMA ke ulta close -> pending delete
input int    ExpiryBars      = 0;      // Pending kitni candle tak (0 = limit nahi)

input group "=== Exit / SL ==="
input bool   EmaCloseExit    = true;   // Candle EMA ke ulta close -> trade band (video SL)
input double SLBufferPips    = 1.0;    // Hard SL: setup low/high ke paar buffer (pips)
input double MinSLPips       = 3.0;    // Hard SL kam se kam (pips)
input double MaxSLPips       = 20.0;   // Hard SL zyada se zyada (pips)
input double TP_RR           = 0.0;    // Fixed TP = RR x SL (0 = TP nahi, rally ride)

input group "=== Risk ==="
input double Lot             = 0.01;   // Lot
input double MaxSpreadPips   = 3.0;    // Is se zyada spread -> naya order nahi
input int    MaxOpenTotal    = 10;     // Saare pair milake max trade + pending
input ulong  Magic           = 2026520;// Magic number
input bool   ShowPanel       = true;   // Chart pe panel

//--- per-pair state
struct PairState
  {
   string   sym;
   int      ema;
   datetime lastBar;
   int      bStage;     // 0 = kuch nahi, 1 = green mila, red ka wait
   int      bWait;
   double   bSigLow;
   int      sStage;     // 0 = kuch nahi, 1 = red mila, green ka wait
   int      sWait;
   double   sSigHigh;
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
      if(p!="" && StringFind(u,p)==0) return true;   // EURUSD bhi EURUSDm se match
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
   int h = iMA(sym, TF, EmaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(h==INVALID_HANDLE){ Print("EMA handle fail: ", sym); return; }
   ArrayResize(P, NP+1);
   P[NP].sym = sym;  P[NP].ema = h;  P[NP].lastBar = 0;
   P[NP].bStage = 0; P[NP].bWait = 0; P[NP].bSigLow = 0;
   P[NP].sStage = 0; P[NP].sWait = 0; P[NP].sSigHigh = 0;
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
           {  // suffix wala naam dhundo (EURUSD -> EURUSDm)
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
   // khaali = saare forex. Pehle Market Watch wale, phir baaki (ek base+quote ka ek hi symbol)
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

double NP_(string sym, double price)
  {
   return NormalizeDouble(price, (int)SymbolInfoInteger(sym, SYMBOL_DIGITS));
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

// is pair par hamara pending (type: ORDER_TYPE_BUY_STOP / SELL_STOP)
ulong FindPending(string sym, ENUM_ORDER_TYPE type, datetime &setup)
  {
   setup = 0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong t = OrderGetTicket(i);
      if(t==0) continue;
      if(OrderGetString(ORDER_SYMBOL)!=sym || (ulong)OrderGetInteger(ORDER_MAGIC)!=Magic) continue;
      if((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)!=type) continue;
      setup = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      return t;
     }
   return 0;
  }

int CountOurs()
  {
   int c = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong t = PositionGetTicket(i);
      if(t!=0 && (ulong)PositionGetInteger(POSITION_MAGIC)==Magic) c++;
     }
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      ulong t = OrderGetTicket(i);
      if(t!=0 && (ulong)OrderGetInteger(ORDER_MAGIC)==Magic) c++;
     }
   return c;
  }

void DeletePending(string sym, ENUM_ORDER_TYPE type, string why)
  {
   datetime st;
   ulong t = FindPending(sym, type, st);
   if(t==0) return;
   if(trade.OrderDelete(t)) Print(sym, " pending delete (", why, ")");
  }

//+------------------------------------------------------------------+
//  Hard SL: setup extreme se buffer, min/max pips ke beech
double HardSL(string sym, bool buy, double entry, double extreme)
  {
   double pip = Pip(sym);
   double sl  = buy ? extreme - SLBufferPips*pip : extreme + SLBufferPips*pip;
   double dist = MathAbs(entry - sl);
   if(dist < MinSLPips*pip) dist = MinSLPips*pip;
   if(MaxSLPips>0 && dist > MaxSLPips*pip) dist = MaxSLPips*pip;
   // broker stop level
   double lvl = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*SymbolInfoDouble(sym, SYMBOL_POINT);
   if(dist < lvl + pip*0.5) dist = lvl + pip*0.5;
   return NP_(sym, buy ? entry - dist : entry + dist);
  }

//  Step 3: BUY STOP (red high) / SELL STOP (green low)
void PlaceEntry(int i, bool buy, double level, double extreme)
  {
   string sym = P[i].sym;
   double pip = Pip(sym);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   double spreadPips = (ask-bid)/pip;
   if(spreadPips > MaxSpreadPips)
     { P[i].status = StringFormat("%s skip: spread %.1f pip", buy?"BUY":"SELL", spreadPips); return; }

   ulong pt; int dir = PosDir(sym, pt);
   if(dir!=0){ P[i].status = "trade chalu - naya setup skip"; return; }

   // naya setup = purana usi taraf ka pending hatao
   DeletePending(sym, buy?ORDER_TYPE_BUY_STOP:ORDER_TYPE_SELL_STOP, "naya setup");
   if(CountOurs() >= MaxOpenTotal){ P[i].status = "MaxOpenTotal poora"; return; }

   double lot = NormLot(sym, Lot);
   double lvl = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*SymbolInfoDouble(sym, SYMBOL_POINT);
   trade.SetTypeFillingBySymbol(sym);
   string cmt = buy ? "EMA20 B" : "EMA20 S";

   if(buy)
     {
      // chart ka high BID pe hai, buy stop ASK pe chalta hai -> spread jodo
      double price = NP_(sym, level + EntryBufferPips*pip + (ask-bid));
      if(price - ask > lvl)
        {
         double sl = HardSL(sym, true, price, extreme);
         double tp = (TP_RR>0) ? NP_(sym, price + TP_RR*(price-sl)) : 0;
         if(trade.BuyStop(lot, price, sym, sl, tp, ORDER_TIME_GTC, 0, cmt))
            P[i].status = StringFormat("BUY STOP %s  SL %s", DoubleToString(price,(int)SymbolInfoInteger(sym,SYMBOL_DIGITS)), DoubleToString(sl,(int)SymbolInfoInteger(sym,SYMBOL_DIGITS)));
         else P[i].status = "BUY STOP fail "+IntegerToString(trade.ResultRetcode());
        }
      else if(ask - price <= MaxChasePips*pip)
        {
         double sl = HardSL(sym, true, ask, extreme);
         double tp = (TP_RR>0) ? NP_(sym, ask + TP_RR*(ask-sl)) : 0;
         if(trade.Buy(lot, sym, 0, sl, tp, cmt)) P[i].status = "BUY market (high pehle toota)";
         else P[i].status = "BUY fail "+IntegerToString(trade.ResultRetcode());
        }
      else P[i].status = "BUY skip: high bahut pehle toot gaya";
     }
   else
     {
      double price = NP_(sym, level - EntryBufferPips*pip);
      if(bid - price > lvl)
        {
         double sl = HardSL(sym, false, price, extreme);
         double tp = (TP_RR>0) ? NP_(sym, price - TP_RR*(sl-price)) : 0;
         if(trade.SellStop(lot, price, sym, sl, tp, ORDER_TIME_GTC, 0, cmt))
            P[i].status = StringFormat("SELL STOP %s  SL %s", DoubleToString(price,(int)SymbolInfoInteger(sym,SYMBOL_DIGITS)), DoubleToString(sl,(int)SymbolInfoInteger(sym,SYMBOL_DIGITS)));
         else P[i].status = "SELL STOP fail "+IntegerToString(trade.ResultRetcode());
        }
      else if(price - bid <= MaxChasePips*pip)
        {
         double sl = HardSL(sym, false, bid, extreme);
         double tp = (TP_RR>0) ? NP_(sym, bid - TP_RR*(sl-bid)) : 0;
         if(trade.Sell(lot, sym, 0, sl, tp, cmt)) P[i].status = "SELL market (low pehle toota)";
         else P[i].status = "SELL fail "+IntegerToString(trade.ResultRetcode());
        }
      else P[i].status = "SELL skip: low bahut pehle toot gaya";
     }
  }

//+------------------------------------------------------------------+
//  Har second: trade khul gaya to usi pair ke saare pending hatao
void CleanPendingsIfPosition(int i)
  {
   ulong pt;
   if(PosDir(P[i].sym, pt)==0) return;
   DeletePending(P[i].sym, ORDER_TYPE_BUY_STOP,  "trade khul gaya");
   DeletePending(P[i].sym, ORDER_TYPE_SELL_STOP, "trade khul gaya");
  }

//  Nayi M5 candle band hui -> sab kuch yahan
void OnNewBar(int i)
  {
   string sym = P[i].sym;
   MqlRates r[];
   double e[];
   ArraySetAsSeries(r, true);
   ArraySetAsSeries(e, true);
   if(CopyRates(sym, TF, 1, 2, r) < 2) return;          // r[0] = abhi band hui, r[1] = usse pehle
   if(CopyBuffer(P[i].ema, 0, 1, 2, e) < 2) return;

   double c1 = r[0].close, o1 = r[0].open, h1 = r[0].high, l1 = r[0].low;
   double c2 = r[1].close;
   double e1 = e[0], e2 = e[1];
   bool green = c1 > o1, red = c1 < o1;
   bool closeAbove = c1 > e1, closeBelow = c1 < e1;

   // 1) EXIT: candle EMA ke ulta close (video ka SL)
   ulong pt; int dir = PosDir(sym, pt);
   if(EmaCloseExit && dir!=0)
     {
      if((dir==1 && closeBelow) || (dir==-1 && closeAbove))
        {
         if(trade.PositionClose(pt)) Print(sym, " trade band: candle EMA ke ", (dir==1?"neeche":"upar"), " close");
         dir = 0;
        }
     }

   // 2) PENDING cancel: EMA ulta close / expiry
   datetime st;
   if(FindPending(sym, ORDER_TYPE_BUY_STOP, st)!=0)
     {
      bool exp = (ExpiryBars>0 && Bars(sym, TF, st, TimeCurrent())-1 >= ExpiryBars);
      if((CancelOnEmaClose && closeBelow) || exp) DeletePending(sym, ORDER_TYPE_BUY_STOP, exp?"expiry":"EMA ke neeche close");
     }
   if(FindPending(sym, ORDER_TYPE_SELL_STOP, st)!=0)
     {
      bool exp = (ExpiryBars>0 && Bars(sym, TF, st, TimeCurrent())-1 >= ExpiryBars);
      if((CancelOnEmaClose && closeAbove) || exp) DeletePending(sym, ORDER_TYPE_SELL_STOP, exp?"expiry":"EMA ke upar close");
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
            PlaceEntry(i, true, h1, MathMin(P[i].bSigLow, l1));
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
            PlaceEntry(i, false, l1, MathMax(P[i].sSigHigh, h1));
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
   string s = "EMA20 M5 SCALPING v1.00   |  pairs: "+IntegerToString(NP)+"  |  open+pending: "+IntegerToString(CountOurs())+"/"+IntegerToString(MaxOpenTotal)+"\n";
   s += "Lot "+DoubleToString(Lot,2)+"  |  Hard SL "+DoubleToString(MinSLPips,1)+"-"+DoubleToString(MaxSLPips,1)+" pip  |  Exit: "+(EmaCloseExit?"EMA close":"sirf SL/TP")+(TP_RR>0?"  TP "+DoubleToString(TP_RR,1)+"R":"")+"\n";
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
      CleanPendingsIfPosition(i);
      datetime t0 = iTime(P[i].sym, TF, 0);
      if(t0==0) continue;
      if(P[i].lastBar==0){ P[i].lastBar = t0; P[i].status = "ready - nayi candle ka wait"; continue; }
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
   string list = "";
   for(int i=0;i<NP;i++) list += P[i].sym+" ";
   Print("EMA20 M5 SCALPING v1.00 shuru. Pairs (", NP, "): ", list);
   EventSetTimer(1);
   Work();
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   for(int i=0;i<NP;i++) if(P[i].ema!=INVALID_HANDLE) IndicatorRelease(P[i].ema);
   Comment("");
  }

void OnTick()  { Work(); }
void OnTimer() { Work(); }
//+------------------------------------------------------------------+
