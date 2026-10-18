//+------------------------------------------------------------------+
//|                                MEXA SCALP Signal EA v1.00.mq5    |
//|                                Ankush New Vision                 |
//+------------------------------------------------------------------+
//  CHANGELOG
//  v1.00 (2026-10-18)
//   - SIGNAL-ONLY EA — koi trade NAHI kholta (VPS Helper se deploy ke liye
//     EA form me banaya, kyunki helper files MQL5\Experts me daalta hai)
//   - MEXA SCALP app wala same signal: EMA 9/21 crossover + RSI 14 filter
//     BUY  = EMA fast upar cross + RSI 50..70
//     SELL = EMA fast niche cross + RSI 30..50
//   - Sirf CLOSED candle par signal (repaint nahi), har candle par max 1
//   - Phone PUSH (MT5 app, phone lock ho tab bhi) + popup Alert + sound
//   - Chart par BUY/SELL arrows (pichhle signals bhi) + EMA lines
//   - Message me TP/SL price (Gold: TP $3, SL $2)
//   - Lagate hi 1 test push; Algo Trading button OFF ho tab bhi chalta hai
//+------------------------------------------------------------------+
#property copyright   "Ankush New Vision"
#property version     "1.00"
#property description "MEXA SCALP Signal EA — sirf signal + phone push, koi trade nahi."
#property description "EMA 9/21 cross + RSI 14 filter, closed candle."

//--- inputs
input group "=== Signal (app jaisa) ==="
input int    InpEmaFast      = 9;     // EMA Fast
input int    InpEmaSlow      = 21;    // EMA Slow
input int    InpRsiPeriod    = 14;    // RSI Period
input double InpBuyRsiMin    = 50;    // BUY: RSI min
input double InpBuyRsiMax    = 70;    // BUY: RSI max
input double InpSellRsiMin   = 30;    // SELL: RSI min
input double InpSellRsiMax   = 50;    // SELL: RSI max

input group "=== Alerts ==="
input bool   InpPush         = true;  // Phone PUSH notification (MT5 app)
input bool   InpPopup        = true;  // Popup Alert (terminal)
input bool   InpSound        = true;  // Sound (popup band ho tab)
input string InpSoundFile    = "alert.wav"; // Sound file
input bool   InpTestPush     = true;  // Lagate hi 1 test push bhejo

input group "=== TP / SL (sirf message me) ==="
input bool   InpShowTpSl     = true;  // Message me TP/SL dikhao
input double InpTpMove       = 3.0;   // TP price move ($)
input double InpSlMove       = 2.0;   // SL price move ($)

input group "=== Chart ==="
input bool   InpShowEma      = true;  // Chart par EMA lines dikhao
input int    InpHistoryBars  = 500;   // Pichhle kitne candles ke arrows
input color  InpBuyColor     = clrLime;   // BUY arrow color
input color  InpSellColor    = clrRed;    // SELL arrow color

//--- globals
int      hFast = INVALID_HANDLE, hSlow = INVALID_HANDLE, hRsi = INVALID_HANDLE;
datetime lastBarChecked = 0;
string   lastSigText = "abhi koi nahi";
string   addedInd[2];
int      addedCount = 0;
const string PFX = "MEXA_SIG_";

//+------------------------------------------------------------------+
string TfName()
{
   return StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period), 7);
}

//+------------------------------------------------------------------+
void ShowComment()
{
   string push = "band";
   if(InpPush)
      push = (TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED) ? "ON" : "OFF  (Tools > Options > Notifications)");
   Comment("MEXA SCALP Signal EA v1.00  |  ", _Symbol, " ", TfName(),
           "  |  EMA ", InpEmaFast, "/", InpEmaSlow, "  RSI ", InpRsiPeriod,
           "\nSirf signal — koi trade nahi",
           "\nPush: ", push,
           "\nLast signal: ", lastSigText);
}

//+------------------------------------------------------------------+
void AddEmaToChart(const int handle)
{
   if(!ChartIndicatorAdd(0, 0, handle)) return;
   int total = ChartIndicatorsTotal(0, 0);
   if(total > 0 && addedCount < 2)
      addedInd[addedCount++] = ChartIndicatorName(0, 0, total - 1);
}

//+------------------------------------------------------------------+
//| shift k (1 = last closed) par signal: +1 BUY, -1 SELL, 0 none    |
//+------------------------------------------------------------------+
int SignalAt(const int k, const double &f[], const double &s[], const double &r[])
{
   bool up = (f[k + 1] <= s[k + 1] && f[k] > s[k]);
   bool dn = (f[k + 1] >= s[k + 1] && f[k] < s[k]);
   if(up && r[k] >= InpBuyRsiMin && r[k] <= InpBuyRsiMax)   return(+1);
   if(dn && r[k] >= InpSellRsiMin && r[k] <= InpSellRsiMax) return(-1);
   return(0);
}

//+------------------------------------------------------------------+
void DrawArrow(const int dir, const datetime t, const double price)
{
   string name = PFX + (dir > 0 ? "B_" : "S_") + IntegerToString((long)t);
   if(ObjectFind(0, name) >= 0) return;
   ENUM_OBJECT type = (dir > 0 ? OBJ_ARROW_BUY : OBJ_ARROW_SELL);
   if(!ObjectCreate(0, name, type, 0, t, price)) return;
   ObjectSetInteger(0, name, OBJPROP_COLOR, dir > 0 ? InpBuyColor : InpSellColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, "MEXA SCALP " + (dir > 0 ? "BUY" : "SELL"));
}

//+------------------------------------------------------------------+
bool LoadBuffers(const int count, double &f[], double &s[], double &r[])
{
   ArraySetAsSeries(f, true);
   ArraySetAsSeries(s, true);
   ArraySetAsSeries(r, true);
   if(CopyBuffer(hFast, 0, 0, count, f) < count) return(false);
   if(CopyBuffer(hSlow, 0, 0, count, s) < count) return(false);
   if(CopyBuffer(hRsi,  0, 0, count, r) < count) return(false);
   return(true);
}

//+------------------------------------------------------------------+
bool DrawHistory()
{
   int bars = MathMin(InpHistoryBars, Bars(_Symbol, _Period) - InpEmaSlow - 5);
   if(bars < 3) return(false);
   double f[], s[], r[];
   if(!LoadBuffers(bars + 2, f, s, r)) return(false);
   for(int k = bars; k >= 1; k--)
   {
      int dir = SignalAt(k, f, s, r);
      if(dir == 0) continue;
      datetime t = iTime(_Symbol, _Period, k);
      DrawArrow(dir, t, dir > 0 ? iLow(_Symbol, _Period, k) : iHigh(_Symbol, _Period, k));
   }
   ChartRedraw();
   return(true);
}

//+------------------------------------------------------------------+
bool historyDone = false;

//+------------------------------------------------------------------+
int OnInit()
{
   if(InpEmaFast < 1 || InpEmaSlow <= InpEmaFast || InpRsiPeriod < 2)
   {
      Print("MEXA SCALP: galat inputs — EMA Slow, EMA Fast se bada hona chahiye");
      return(INIT_PARAMETERS_INCORRECT);
   }

   hFast = iMA(_Symbol, _Period, InpEmaFast, 0, MODE_EMA, PRICE_CLOSE);
   hSlow = iMA(_Symbol, _Period, InpEmaSlow, 0, MODE_EMA, PRICE_CLOSE);
   hRsi  = iRSI(_Symbol, _Period, InpRsiPeriod, PRICE_CLOSE);
   if(hFast == INVALID_HANDLE || hSlow == INVALID_HANDLE || hRsi == INVALID_HANDLE)
   {
      Print("MEXA SCALP: indicator handle nahi bana, error ", GetLastError());
      return(INIT_FAILED);
   }

   addedCount = 0;
   historyDone = false;
   if(InpShowEma && !MQLInfoInteger(MQL_TESTER))
   {
      AddEmaToChart(hFast);
      AddEmaToChart(hSlow);
   }

   lastBarChecked = iTime(_Symbol, _Period, 0);   // purane signal par alert nahi

   int prevReason = UninitializeReason();
   if(InpPush && InpTestPush && !MQLInfoInteger(MQL_TESTER) &&
      prevReason != REASON_CHARTCHANGE && prevReason != REASON_PARAMETERS)
   {
      if(!TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
         Alert("MEXA SCALP: Push notification OFF hai. Tools > Options > Notifications me MetaQuotes ID daalo aur Enable karo.");
      else if(!SendNotification("MEXA SCALP test OK - " + _Symbol + " " + TfName() + " signal alerts chalu"))
         Print("MEXA SCALP: test push fail, error ", GetLastError());
   }

   EventSetTimer(2);        // data late aaye to history arrows timer se
   ShowComment();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   for(int i = 0; i < addedCount; i++)
      if(addedInd[i] != "") ChartIndicatorDelete(0, 0, addedInd[i]);
   addedCount = 0;
   ObjectsDeleteAll(0, PFX);
   if(hFast != INVALID_HANDLE) IndicatorRelease(hFast);
   if(hSlow != INVALID_HANDLE) IndicatorRelease(hSlow);
   if(hRsi  != INVALID_HANDLE) IndicatorRelease(hRsi);
   Comment("");
}

//+------------------------------------------------------------------+
void OnTimer()
{
   if(!historyDone && DrawHistory())
   {
      historyDone = true;
      EventKillTimer();
   }
}

//+------------------------------------------------------------------+
void FireSignal(const int dir, const double price, const double rsi, const datetime barTime)
{
   string side = (dir > 0 ? "BUY" : "SELL");
   string msg  = "MEXA SCALP | " + _Symbol + " " + TfName() + " | " + side + " @ " +
                 DoubleToString(price, _Digits) + " | RSI " + DoubleToString(rsi, 0);
   if(InpShowTpSl)
   {
      double tp = price + dir * InpTpMove;
      double sl = price - dir * InpSlMove;
      msg += " | TP " + DoubleToString(tp, _Digits) + " SL " + DoubleToString(sl, _Digits);
   }

   lastSigText = side + " @ " + DoubleToString(price, _Digits) + "  (" +
                 TimeToString(barTime + PeriodSeconds(), TIME_MINUTES) + ")";

   if(InpPush && TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
   {
      if(!SendNotification(msg))
         Print("MEXA SCALP: push fail, error ", GetLastError());
   }
   if(InpPopup)
      Alert(msg);                       // Alert apni sound bhi bajata hai
   else if(InpSound)
      PlaySound(InpSoundFile);

   Print(msg);
   ShowComment();
}

//+------------------------------------------------------------------+
void OnTick()
{
   datetime bar0 = iTime(_Symbol, _Period, 0);
   if(bar0 == 0 || bar0 == lastBarChecked) return;       // naya candle nahi

   double f[], s[], r[];
   if(!LoadBuffers(3, f, s, r)) return;                   // data ready nahi — agle tick par
   lastBarChecked = bar0;

   if(!historyDone && DrawHistory()) { historyDone = true; EventKillTimer(); }

   int dir = SignalAt(1, f, s, r);
   if(dir == 0) return;

   datetime t1 = iTime(_Symbol, _Period, 1);
   DrawArrow(dir, t1, dir > 0 ? iLow(_Symbol, _Period, 1) : iHigh(_Symbol, _Period, 1));
   FireSignal(dir, iClose(_Symbol, _Period, 1), r[1], t1);
   ChartRedraw();
}
//+------------------------------------------------------------------+
