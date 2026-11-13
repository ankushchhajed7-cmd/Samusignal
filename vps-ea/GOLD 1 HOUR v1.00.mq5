//+------------------------------------------------------------------+
//|                                          GOLD 1 HOUR v1.00.mq5   |
//|                                   Ankush New Vision              |
//+------------------------------------------------------------------+
//| CHANGELOG                                                        |
//| v1.00 (13 Nov 2026) - First build                                |
//|   - Har 1 ghante (naya H1 candle) par 1 BUY market order         |
//|   - Sirf BUY, market direction ka koi filter nahi                |
//|   - Har trade ka alag TP = $5 (money), lot ke hisaab se          |
//|     har pair ka TP price khud calculate hota hai                 |
//|   - Lot size input (default 0.01), SL nahi                       |
//|   - Kisi bhi pair ke chart par chal sakta hai (Gold, EURUSD...)  |
//+------------------------------------------------------------------+
#property copyright "Ankush New Vision"
#property version   "1.00"
#property description "GOLD 1 HOUR - har ghante 1 BUY, har trade ka alag $5 TP, no SL"

#include <Trade\Trade.mqh>

//--- Inputs
input double InpLots          = 0.01;   // Lot size
input double InpTPMoney       = 5.0;    // TP per trade (account currency, $)
input long   InpMagic         = 101001; // Magic number
input bool   InpTradeOnAttach = false;  // Chart par lagate hi pehla trade le?
input int    InpMaxOpenTrades = 0;      // Max open trades (0 = unlimited)
input int    InpSlippage      = 30;     // Max slippage (points)
input bool   InpShowPanel     = true;   // Chart par info panel dikhaye

//--- Globals
CTrade   trade;
datetime g_lastTradedHour = 0;   // jis H1 candle par trade ho chuka
datetime g_lastTryTime    = 0;   // retry throttle
string   g_lastMsg        = "";

//+------------------------------------------------------------------+
int OnInit()
{
   if(InpLots <= 0 || InpTPMoney <= 0)
   {
      Print("GOLD 1 HOUR: Lot aur TP dono 0 se bade hone chahiye.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippage);
   trade.SetTypeFillingBySymbol(_Symbol);

   // Chart par lagate hi trade nahi lena ho to current hour ko "done" maan lo
   if(!InpTradeOnAttach)
      g_lastTradedHour = iTime(_Symbol, PERIOD_H1, 0);

   g_lastMsg = "Ready. Agle ghante ka wait...";
   UpdatePanel();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");
}

//+------------------------------------------------------------------+
void OnTick()
{
   datetime hourBar = iTime(_Symbol, PERIOD_H1, 0);
   if(hourBar == 0) { UpdatePanel(); return; }

   // Naya ghanta shuru hua aur is ghante ka trade abhi nahi hua
   if(hourBar != g_lastTradedHour)
   {
      // Fail hone par har tick spam na ho - 10 second ka gap
      if(TimeCurrent() - g_lastTryTime >= 10)
      {
         g_lastTryTime = TimeCurrent();
         if(OpenHourlyBuy())
            g_lastTradedHour = hourBar;
      }
   }

   UpdatePanel();
}

//+------------------------------------------------------------------+
//| Ek BUY order kholta hai, $ TP ke saath                           |
//+------------------------------------------------------------------+
bool OpenHourlyBuy()
{
   // Max open trades check
   if(InpMaxOpenTrades > 0 && CountMyTrades() >= InpMaxOpenTrades)
   {
      g_lastMsg = "Max open trades limit - is ghante skip";
      return(true); // is ghante ko skip maan lo, dobara try nahi
   }

   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      g_lastMsg = "Algo Trading OFF hai - button ON karo";
      return(false);
   }

   double lots = NormalizeLots(InpLots);
   if(lots <= 0)
   {
      g_lastMsg = "Lot size galat hai";
      return(false);
   }

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || tick.ask <= 0)
   {
      g_lastMsg = "Price nahi mila";
      return(false);
   }

   double tpDist = TPDistanceForMoney(lots, InpTPMoney);
   if(tpDist <= 0)
   {
      g_lastMsg = "TP calculate nahi hua (tick value 0)";
      return(false);
   }

   // Broker stop level se kam na ho
   double minDist = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   if(tpDist < minDist) tpDist = minDist + _Point;

   double tp = NormalizePrice(tick.ask + tpDist);

   string cmt = "G1H " + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES);
   if(trade.Buy(lots, _Symbol, 0.0, 0.0, tp, cmt))
   {
      uint rc = trade.ResultRetcode();
      if(rc == TRADE_RETCODE_DONE || rc == TRADE_RETCODE_PLACED || rc == TRADE_RETCODE_DONE_PARTIAL)
      {
         g_lastMsg = StringFormat("BUY %.2f @ %s  TP %s ($%.2f)",
                                  lots,
                                  DoubleToString(trade.ResultPrice(), _Digits),
                                  DoubleToString(tp, _Digits),
                                  InpTPMoney);
         Print("GOLD 1 HOUR: ", g_lastMsg);
         return(true);
      }
   }

   string failMsg = StringFormat("BUY fail: %u %s", trade.ResultRetcode(), trade.ResultRetcodeDescription());
   if(failMsg != g_lastMsg) Print("GOLD 1 HOUR: ", failMsg); // same error baar-baar log na ho
   g_lastMsg = failMsg;
   return(false);
}

//+------------------------------------------------------------------+
//| $ profit ke liye kitna price move chahiye (har pair ke liye)     |
//+------------------------------------------------------------------+
double TPDistanceForMoney(double lots, double money)
{
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE_PROFIT);
   if(tickValue <= 0) tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(tickSize <= 0 || tickValue <= 0 || lots <= 0) return(0);

   double ticks = money / (tickValue * lots);
   ticks = MathCeil(ticks);            // thoda upar round - $5 se kam na ho
   return(ticks * tickSize);
}

//+------------------------------------------------------------------+
double NormalizeLots(double lots)
{
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(stepLot <= 0) stepLot = 0.01;

   lots = MathFloor(lots / stepLot + 0.0000001) * stepLot;
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;
   return(NormalizeDouble(lots, 2));
}

//+------------------------------------------------------------------+
double NormalizePrice(double price)
{
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize > 0) price = MathRound(price / tickSize) * tickSize;
   return(NormalizeDouble(price, _Digits));
}

//+------------------------------------------------------------------+
int CountMyTrades()
{
   int cnt = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagic)
         cnt++;
   }
   return(cnt);
}

//+------------------------------------------------------------------+
double FloatingPL()
{
   double pl = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == InpMagic)
         pl += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   return(pl);
}

//+------------------------------------------------------------------+
void UpdatePanel()
{
   if(!InpShowPanel) return;

   datetime nextHour = iTime(_Symbol, PERIOD_H1, 0) + 3600;
   int secLeft = (int)(nextHour - TimeCurrent());
   if(secLeft < 0) secLeft = 0;

   double lots   = NormalizeLots(InpLots);
   double tpDist = TPDistanceForMoney(lots, InpTPMoney);

   string s = "GOLD 1 HOUR v1.00\n";
   s += StringFormat("Symbol: %s   Lot: %.2f   TP: $%.2f\n", _Symbol, lots, InpTPMoney);
   s += StringFormat("TP distance: %s (%d points)\n",
                     DoubleToString(tpDist, _Digits), (int)MathRound(tpDist / _Point));
   s += StringFormat("Open trades: %d   Floating P/L: %.2f\n", CountMyTrades(), FloatingPL());
   s += StringFormat("Agla BUY: %02d:%02d min mein\n", secLeft / 60, secLeft % 60);
   s += "Last: " + g_lastMsg;
   Comment(s);
}
//+------------------------------------------------------------------+
