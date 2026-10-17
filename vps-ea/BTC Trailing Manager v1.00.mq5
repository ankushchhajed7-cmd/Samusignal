//+------------------------------------------------------------------+
//|                                       BTC Trailing Manager v1.00  |
//|                                        Ankush New Vision          |
//|                                                                   |
//|  Buster BTC ("BTC Ea Tp Sl 1.23") me trailing ki koi setting      |
//|  nahi hai (sirf on/off). Ye chhota EA usi account par ALAG chart  |
//|  par chalta hai aur Buster ke trades ka trailing aapki settings   |
//|  se karta hai.                                                    |
//|                                                                   |
//|  ZAROORI: Buster ke inputs me  UseTrailingStop = false  rakho,    |
//|  warna dono SL khiskayenge aur jo tight hoga wahi jeetega.        |
//|                                                                   |
//|  Ye EA naya trade NAHI kholta, trade band NAHI karta, TP NAHI     |
//|  chhedta. Sirf SL ko profit ki taraf khiskata hai (kabhi peeche   |
//|  nahi).                                                           |
//|                                                                   |
//|  Units: POINTS (Buster ke StopLoss jaisa). BTCUSD# par            |
//|  1 point = 0.01 price, 15000 points = 150 price = 0.01 lot par    |
//|  $1.50.                                                           |
//|                                                                   |
//|  CHANGELOG                                                        |
//|   v1.00 - Pehla build: TrailStart / TrailDistance / TrailStep,    |
//|           optional Break-even, magic + symbol filter, stops/freeze|
//|           level ka dhyan, chart par panel.                        |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property link      "https://github.com/ankushchhajed7-cmd"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>

input group "=== Kis trade ko manage kare ==="
input long   MagicNumber    = 111111;  // Buster ka Magic Number (0 = magic mat dekho)
input bool   OnlyThisSymbol = true;    // sirf is chart ke symbol ke trades

input group "=== Trailing Stop (POINTS) ==="
input bool   UseTrailing    = true;    // trailing chalu
input int    TrailStart     = 15000;   // itne points profit ke baad trailing shuru (15000 = 150 price)
input int    TrailDistance  = 12000;   // SL price se itne points peeche chalega
input int    TrailStep      = 1000;    // SL tabhi khiske jab kam se kam itna aage ja sake

input group "=== Break-even (optional) ==="
input bool   UseBreakEven   = false;   // break-even chalu
input int    BreakEvenAt    = 10000;   // itne points profit par SL ko open ke paas le aao
input int    BreakEvenLock  = 500;     // SL = open + itne points (buy) / open - itne (sell)

input group "=== Display ==="
input bool   ShowPanel      = true;    // chart par chhota panel

CTrade   gTrade;
int      gManaged   = 0;
int      gMoves     = 0;
string   gLastMsg   = "abhi koi SL move nahi";

//+------------------------------------------------------------------+
bool IsMine(const string sym, long magic)
{
   if(OnlyThisSymbol && sym != _Symbol) return false;
   if(MagicNumber != 0 && magic != MagicNumber) return false;
   return true;
}

// candidate SL "better" than current for this direction by at least minGap (price)?
bool Better(int dir, double cand, double cur, double minGap)
{
   if(cand <= 0) return false;
   if(cur  <= 0) return true;
   if(dir > 0) return cand > cur + minGap;
   return cand < cur - minGap;
}

void ManageAll()
{
   gManaged = 0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0 || !PositionSelectByTicket(tk)) continue;

      string sym   = PositionGetString(POSITION_SYMBOL);
      long   magic = PositionGetInteger(POSITION_MAGIC);
      if(!IsMine(sym, magic)) continue;
      gManaged++;

      int    dir  = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl   = PositionGetDouble(POSITION_SL);
      double tp   = PositionGetDouble(POSITION_TP);
      double pt   = SymbolInfoDouble(sym, SYMBOL_POINT);
      int    dg   = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      if(pt <= 0) continue;

      double bid = SymbolInfoDouble(sym, SYMBOL_BID);
      double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
      double px  = (dir > 0) ? bid : ask;          // price at which this position would close
      if(px <= 0) continue;

      double profitPts = dir * (px - open) / pt;
      double stopsLvl  = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)  * pt;
      double freezeLvl = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_FREEZE_LEVEL) * pt;

      // inside freeze level the broker won't accept a modify
      if(sl > 0 && freezeLvl > 0 && MathAbs(px - sl) <= freezeLvl) continue;

      double newSL = sl;
      string why   = "";

      // 1) break-even
      if(UseBreakEven && profitPts >= BreakEvenAt)
      {
         double be = open + dir * BreakEvenLock * pt;
         if(Better(dir, be, newSL, pt * 0.5)) { newSL = be; why = "BE"; }
      }

      // 2) trailing
      if(UseTrailing && profitPts >= TrailStart)
      {
         double tr = px - dir * TrailDistance * pt;
         if(Better(dir, tr, newSL, TrailStep * pt)) { newSL = tr; why = "TRAIL"; }
      }

      if(why == "") continue;

      // respect broker minimum distance from price
      double minGap = stopsLvl + pt;
      if(dir > 0 && newSL > px - minGap) newSL = px - minGap;
      if(dir < 0 && newSL < px + minGap) newSL = px + minGap;
      newSL = NormalizeDouble(newSL, dg);

      if(!Better(dir, newSL, sl, pt * 0.5)) continue;   // still must tighten

      if(gTrade.PositionModify(tk, newSL, tp))
      {
         gMoves++;
         gLastMsg = StringFormat("%s #%I64u %s SL %s -> %s (profit %.0f pts)",
                                 why, tk, (dir > 0 ? "BUY" : "SELL"),
                                 DoubleToString(sl, dg), DoubleToString(newSL, dg), profitPts);
         Print("BTC Trailing Manager: ", gLastMsg);
      }
      else
      {
         PrintFormat("BTC Trailing Manager: modify fail #%I64u code=%u %s",
                     tk, gTrade.ResultRetcode(), gTrade.ResultRetcodeDescription());
      }
   }
}

void Panel()
{
   if(!ShowPanel) return;
   double pt = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   string s = "BTC Trailing Manager v1.00\n";
   s += StringFormat("Magic: %I64d   Symbol: %s\n", MagicNumber, OnlyThisSymbol ? _Symbol : "ALL");
   s += StringFormat("Trailing: %s  start %d pts (%.2f)  distance %d pts (%.2f)  step %d pts\n",
                     UseTrailing ? "ON" : "OFF", TrailStart, TrailStart * pt, TrailDistance, TrailDistance * pt, TrailStep);
   s += StringFormat("Break-even: %s  at %d pts  lock %d pts\n", UseBreakEven ? "ON" : "OFF", BreakEvenAt, BreakEvenLock);
   s += StringFormat("Managed trades now: %d   SL moves: %d\n", gManaged, gMoves);
   s += "Last: " + gLastMsg + "\n";
   s += "Yaad rahe: Buster me UseTrailingStop = false";
   Comment(s);
}

//+------------------------------------------------------------------+
int OnInit()
{
   if(TrailDistance <= 0 || TrailStart < 0 || TrailStep < 0)
   {
      Alert("BTC Trailing Manager: TrailDistance > 0 hona chahiye, baaki values minus nahi.");
      return INIT_PARAMETERS_INCORRECT;
   }
   gTrade.SetExpertMagicNumber(0);       // modifications only; magic not used
   gTrade.SetDeviationInPoints(50);
   Print("BTC Trailing Manager v1.00 start. Magic=", MagicNumber,
         " Start=", TrailStart, " Distance=", TrailDistance, " Step=", TrailStep,
         " | Buster me UseTrailingStop=false rakhna.");
   EventSetTimer(1);
   ManageAll();
   Panel();
   return INIT_SUCCEEDED;
}

void OnTick()  { ManageAll(); }

void OnTimer() { ManageAll(); Panel(); }

void OnDeinit(const int reason)
{
   EventKillTimer();
   Comment("");
}
//+------------------------------------------------------------------+
