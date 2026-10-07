//+------------------------------------------------------------------+
//|            GridTrend_EA_Strategy2.mq5   v1.05                    |
//|  10K EDITION: 10000 balance ke liye. Strategy/lots/gaps/$ limits |
//|   30000 wale jaise hi. Sirf Global_Target_Pct 0.5 → 1.5 kiya,    |
//|   taaki combined basket target 150 hi rahe (pehle 30000×0.5%).   |
//|  10K TRADING HOURS: 7 AM - 5 PM IST hi naya cycle shuru hoga.   |
//|   5 PM ke baad sab trades band hon to koi naya trade nahi. Koi   |
//|   trade khula ho to cycle (grid, flip, TP) 5 PM ke baad bhi chale|
//|  v1.05 SAFETY ONLY (v1.03 base — settings/strategy 100% same):    |
//|   - TOTAL DD LOCKOUT: limit hit → sab band aur EA LOCK. Pehle     |
//|     agle H1 pe dobara trading shuru ho jaati thi. Ab lock restart |
//|     ke baad bhi rehta hai, sirf manual Reset_DD_Lockout se khulega|
//|     (one-shot: reset ke baad input wapas false karna zaroori)     |
//|   - Broker retcode check — order/close sach mein hua tabhi maana  |
//|   - Close fail ho to basket band hone tak har tick retry; tab tak |
//|     na naya trade, na restart (galat entry se bachav)             |
//|   - $400 flip / $2000 Total DD fixed hi rahe (account currency —  |
//|     cent account mein cents). v1.04 wala % system NAHI liya       |
//|  v1.03: GRID 2 MOBILE APP BRIDGE — EA ab apna poora live data     |
//|   (balance, equity, opening bal, profit/loss, buy/sell grid,      |
//|   har trade, flip state, DD, filters, events, cycle history)      |
//|   Firebase /gt2/{account} pe push karta hai. Phone ka GRID 2 PWA  |
//|   isko padhta hai. Push sirf OnTimer se hota hai (OnTick/trading  |
//|   logic 100% same). Tester mein bridge auto-OFF.                  |
//|   MT5 > Tools > Options > Expert Advisors > WebRequest URL list   |
//|   mein Firebase host add hona chahiye (pehle se add hai).         |
//|  v1.02: DESKTOP DASHBOARD FIX — Windows scaling (125%/150%) pe    |
//|   rows overlap nahi hongi (auto DPI scale), aur candles ab panel  |
//|   ke upar nahi aayengi (Chart-on-foreground OFF). Trading same.   |
//|  v1.01 BUG FIXES (settings/strategy same, sirf flip logic fix):   |
//|   - FIX: pehle se DD-frozen side dobara flip count nahi karti     |
//|     (pehle har 60 min wahi frozen side count kha jaati thi, 4 ka  |
//|     cap ~3 ghante mein sirf 1 asli flip se khatam ho jaata tha)   |
//|   - FIX: 4 flips ke baad 6h pause ab SAHI — pause khatam hote hi  |
//|     counter reset, flips phir chalu (pehle pause baar-baar        |
//|     repeat hota tha aur flips kabhi wapas nahi aate the)          |
//|   - FIX: flip counter ab har basket/cycle close pe pakka reset    |
//|     (pehle restart usi tick mein trade khol deta tha)             |
//|   - Frozen side band ho jaye to uska agla basket fresh maana jata |
//|  STRATEGY 2 — base v3.29 (no % DD, no fallbacks, no time close).  |
//|  Naya: PER-SIDE DD FLIP. Buy side aur Sell side ka drawdown alag  |
//|  count hota hai. Jis side ka floating loss DD_Flip_Dollars ($400) |
//|  cross kare, woh side FREEZE (khuli rehti hai, naye level nahi)   |
//|  aur opposite side ka grid 0.01 se fresh start ho jata hai.       |
//|  Purana Stop & Reverse ($180 move wala) is branch mein REMOVE.    |
//|  Max 4 flips per cycle, uske baad pause. Baki sab v3.29 jaisa.    |
//|  v3.29: DONO FALLBACK SYSTEM REMOVE — per-basket time-decay       |
//|         (Enable_Fallback + 4 phases) aur Global Fallback          |
//|         (Global_Phase1/2/3 + Max_Cycle_Hours hard close) dono     |
//|         gaye. Ab target time ke saath kabhi kam nahi hota aur     |
//|         koi time-based exit nahi hai — sirf fixed target / TP /   |
//|         trailing / Total DD $ limit hi basket band karte hain     |
//|  v3.28: % BASED DRAWDOWN SYSTEM PURA REMOVE — Enable_DD, 4-stage |
//|         ladder (10/15/20/25%), DD alert cooldown aur Progressive |
//|         De-Risk lot taper sab hata diye. Ab account-level risk   |
//|         sirf TOTAL DD $ limit se handle hota hai (v3.29 ke baad)  |
//|         hai. DD% aur Max DD Ever sirf DISPLAY ke liye bache hain |
//|  v3.27: STOP & REVERSE — bada one-side move (default $180/24h)   |
//|         ho aur uske opposite basket loss mein ho, to us basket ko |
//|         band karke naye (move ki) direction mein bade lot se      |
//|         reverse ho jata hai — bade move se profit nikalne ki      |
//|         koshish, sirf bada loss lene ki jagah                     |
//|  v3.26 FIX: Partial Close ab "oldest" trade ki jagah SABSE        |
//|         PROFITABLE trade close karta hai — grid mein oldest       |
//|         aksar sabse worst-positioned hoti hai, isliye "profit     |
//|         lock" karte waqt asal mein loss crystallize ho jaata tha  |
//|  v3.25: Har symbol ki state/log/JSON file ab alag hai (symbol     |
//|         naam suffix ke saath) — XAUUSD+EURUSD (ya kisi bhi 2      |
//|         symbols) ek saath chalane par ab data corrupt nahi hoga   |
//|  v3.24: Trend-Change First Trade feature PURA REMOVE kar diya —  |
//|         ab sabhi trades hamesha normal lot table + basket-average |
//|         TP se khulte hain, koi 0.20 lot/$5 TP exception nahi     |
//|  v3.23: Trailing loosened (Activate $45, Pullback $22) —          |
//|         backtest se pata chala $20/$10 bahut tight tha            |
//|  v3.22: Fixed OnTradeTransaction initial-deposit double-count bug |
//|  v3.21: ACCOUNT LOCK security added                              |
//|  v3.20: Auto deposit/withdrawal baseline adjustment               |
//|  v3.19: Settings values bhi JSON export mein                     |
//|  v3.18: JSON dashboard-export expand kiya — TP prices, Total DD$, |
//|         Spike status, Performance analytics bhi ab export hote    |
//|         hain (naye standalone Dashboard-only EA ke liye)          |
//|  v3.17: Har input parameter ko clear Hinglish comment diya —      |
//|         MT5 Inputs tab mein sabki description ab dikhegi          |
//|  v3.16: VOLATILITY SPIKE FILTER — news-calendar se independent.   |
//|         $30 move in 5min detect ho to naya trade 20min block hai  |
//|  v3.15: Recovery Hold ab sirf tab lagu hota hai jab opposite side |
//|         kam se kam N (default 10) trades deep ho — shallow        |
//|         baskets mein false-trigger nahi hoga                     |
//|  v3.14: Desktop dashboard redesign — 3-column layout (compact),  |
//|         solid master background panel (candles kabhi peeche se   |
//|         nahi dikhenge), darker color palette, glossy "mirror-    |
//|         finish" highlight strip har row ke top pe                |
//|  v3.13: RECOVERY HOLD — agar naya trend-flip hote waqt opposite  |
//|         side ke last N trades profit mein hain (recovering),     |
//|         naya opposite-direction basket open hona PAUSE hota hai  |
//|  v3.12: TOTAL DD — fixed $ account-wide loss limit (parallel to  |
//|         existing % DD system) — hit hote hi sab liquidate        |
//|  v3.11: 'Enable_Individual_TP' option pura hata diya — ab EA     |
//|         hamesha basket-average TP use karta hai (grid trades ke  |
//|         liye). Trend-change 1st trade ka hard $ TP protected hai |
//|  v3.10 FIX: Trend-change 1st trade ka special TP ab hamesha       |
//|         protected hai — basket-TP mode mein bhi UpdateTP() ise    |
//|         overwrite nahi karega                                    |
//|  v3.09: Progressive de-risk (DD-scaled lot) + Performance         |
//|         analytics (win-rate/expectancy/avg-recovery/max-DD)       |
//|         dashboard panel + CSV trade log                          |
//|  v3.08: UpdateTP moved to every-tick — manual close ke baad       |
//|         average TP instantly (M1 wait ke bina) recalc hota hai   |
//|  v3.07: Trend-change 1st trade override — genuine flip pe        |
//|         special lot (0.20) + hard $5 TP, baaki grid untouched    |
//|  v3.06: DD alert cooldown — same level max 1 push / 30 min       |
//|  v3.05: QUANT TERMINAL dashboard restyle (logic 100% untouched)  |
//|  Standard Grid | Basket-Average TP | Tight DD & Fallback         |
//|  NEW: Basket Trailing + Supertrend Whipsaw Confirmation          |
//|  v3.04 FIX: Global-basket baseline BALANCE-anchored + float guard |
//+------------------------------------------------------------------+
#property copyright "GridTrend S2 v1.05"
#property version   "1.05"
#property strict
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
CTrade trade; CPositionInfo pos;

input group "══ ACCOUNT LOCK (security) ══"
input long Allowed_Account_Number = 0;   // Sirf isi MT5 account number (login) pe EA chalega. 0 = lock OFF (kisi bhi account pe chalega)
input group "══ SUPERTREND ══"
input int             ST_Period     = 10;   // Supertrend ATR period — trend detect karne ke liye kitne candles ka average
input double          ST_Multiplier = 3.0;  // Band multiplier — bada number = kam sensitive (kam false signals)
input ENUM_TIMEFRAMES Filter_TF     = PERIOD_H1;   // Kis timeframe pe trend/signal check ho (H1 recommended)
input group "══ SIGNAL CONFIRM ══"
input bool Enable_SignalConfirm = true;   // ON = trend-flip se pehle N consecutive H1 bars ka confirmation chahiye (whipsaw-proof)
input int  Signal_Confirm_Bars  = 2;   // ST flip itne consecutive H1 bars hold kare tabhi basket switch
input group "══ PROFIT TARGET ══"
input bool   Enable_ProfitReset  = true;   // ON = poore account ka profit target track hoga
input double Total_Profit_Target = 500.0;  // Itna $ total account profit ho to poora cycle reset (sab band, fresh start)
// v3.28: "DRAWDOWN" (% based) input group pura remove — neeche wala TOTAL DD $ limit hi ab single account-level hard-stop hai.
input group "══ TOTAL DD — FIXED $ LIMIT ══"
input bool   Enable_TotalDD_Limit    = true;   // v3.12: poore account ka fixed $ floating-loss limit
input double Total_DD_Dollar_Limit   = 2000.0; // S2: account-level BACKSTOP (account currency — cent account mein cents). Hit hote hi sab band + EA LOCK (v1.05)
input bool   Reset_DD_Lockout        = false;  // v1.05: LOCK kholne ke liye — positions flat hon, TRUE karke OK dabao (EA reinit). Reset ke baad wapas FALSE kar do
input group "══ RECOVERY HOLD (naya opposite trade pause) ══"
input bool   Enable_RecoveryHold     = true;   // v3.13: opposite side recover kar raha ho to naya trend-flip trade hold karo
input int    RecoveryHold_LastN      = 4;      // Opposite side ke sabse recent N trades check honge
input int    RecoveryHold_MinOppositeTrades = 10;  // v3.15: opposite side kam se kam itni trades deep ho tabhi yeh check lagu hoga
// S2: purana STOP & REVERSE ($180 move wala) pura remove — ab flip DD se hota hai, price move se nahi.
input group "══ PER-SIDE DD FLIP (Strategy 2) ══"
input bool   Enable_DDFlip          = true;   // ON = kisi ek side ka DD limit cross hote hi trend flip
input double DD_Flip_Dollars        = 400.0;  // Per-side floating loss $ — buy aur sell ka ALAG-ALAG count
input int    DD_Flip_Max_Per_Cycle  = 4;      // Ek cycle mein max itne flips, uske baad pause
input int    DD_Flip_Pause_Hrs      = 6;      // Cap hit hone par itne ghante naya flip nahi
input int    DD_Flip_Cooldown_Min   = 60;     // Do flips ke beech minimum gap (whipsaw se bachav)
input double DD_Flip_Unfreeze_Frac  = 0.5;    // Frozen side tab tak frozen jab tak loss limit ke is fraction se upar na aaye
input group "══ NEWS FILTER ══"
input bool Enable_News  = true;   // ON = economic calendar (news time) ke around trading rukegi
input int  News_Before  = 30;     // News se kitne minute PEHLE trading rok di jaye
input int  News_After   = 30;     // News ke kitne minute BAAD tak trading band rahegi
input bool News_High    = true;   // High-impact news (NFP, Fed rate etc.) ke liye filter lagu ho
input bool News_Medium  = false;  // Medium-impact news ke liye bhi filter lagu ho
input group "══ VOLATILITY SPIKE FILTER ══"
input bool   Enable_SpikeFilter = true;   // v3.16: news-calendar se independent — sudden $ spike catch karta hai
input double Spike_Move_Dollars = 30.0;   // Itna $ one-side move ho window ke andar to spike maana jayega
input int    Spike_Window_Min   = 5;      // Kitne minute ke andar yeh move dekhna hai
input int    Spike_Block_Min    = 20;     // Spike detect hone pe kitne minute naya trade block rahega
input group "══ SPREAD FILTER ══"
input bool   Enable_SpreadFilter = true;    // ON = high-spread waqt naya trade nahi khulega
input double Max_Spread_Points   = 280.0;   // Is se zyada spread (broker points) ho to trade block
input group "══ ATR DYNAMIC GAP ══"
input bool   Enable_ATR   = false;   // ON = grid ka gap volatility ke hisaab se dynamically bada-chota ho
input double ATR_Max_Mult = 3.0;     // Gap kitna zyada bad sakta hai — upper limit
input int    ATR_Avg_Bars = 20;      // ATR ka average kitne candles se calculate ho
input group "══ GRID ══"
input bool Enable_BuyGrid  = true;   // BUY direction ka grid trading ON/OFF
input bool Enable_SellGrid = true;   // SELL direction ka grid trading ON/OFF
input int  Max_Trades      = 30;     // Ek basket (direction) mein max kitni grid trades khul sakti hain
input group "══ AVG TP ══"
input double AvgTP_PerTrade  = 5.0;    // Basket ka per-trade $ target (v3.29: ab hamesha yehi, koi time-decay nahi)
input bool   Enable_Trailing = true;   // Basket profit peak se lock-in karne wala trailing ON/OFF
input double Trail_Pullback  = 22.0;   // $ pullback from peak to lock-in — v3.23: loosened (backtest se pata chala 10.0 bahut tight tha, profit jaldi cut kar raha tha)
input double Trail_Activate  = 45.0;   // basket itna $ profit chhuye tabhi trailing arm hoga — v3.23: loosened (pehle 20.0 tha)
// v3.29: "FALLBACK" group pura remove — basket target ab hamesha AvgTP_PerTrade x trades, time se kam nahi hota.
input group "══ GLOBAL BASKET TP ══"
input bool   Enable_GlobalBasket   = true;   // Master override: dono side ka combined PnL pe close
input double Global_Target_Pct     = 1.5;    // 10K: 30000 wale jaisa hi combined target (10000 × 1.5% = 150). Balance ka % = combined target
// v3.29: Global Fallback (phase decay + Max_Cycle_Hours hard close) bhi remove — global target ab fixed hai.
input double Basket_FloatGuard_Mult = 3.0;   // v3.04: profit-close block agar floating < -(Mult × target). Anti fake-profit guard. 0 = OFF
input group "══ PARTIAL PROFIT LOCK ══"
input bool   Enable_PartialClose       = true;   // ON = target ka 60% chhune pe purani trade partial-close hogi
input double PartialClose_Trigger_Pct  = 60.0;   // Basket target ka kitna % chhune pe partial close trigger ho
input int    PartialClose_Min_Trades   = 6;      // Kam se kam itni trades khuli ho tabhi partial close lagu ho
input int    PartialClose_Cooldown_Sec = 300;    // Do partial-closes ke beech minimum gap (seconds)
input group "══ DASHBOARD EXPORT ══"
input bool Enable_DashboardExport = true;   // ON = live status ek JSON file mein export (external dashboard app ke liye)
input group "══ DASHBOARD ══"
input int Dashboard_Left_X  = 10;    // Dashboard panel ki left edge se X position (pixels)
input int Dashboard_Col_Gap = 14;     // v3.14: teeno column ke beech ka gap (px)
input int Dashboard_Y       = 35;    // Dashboard panel ki top se Y position (pixels)
input double Dashboard_Scale = 0;    // 0 = AUTO (Windows display scaling se), ya manual: 1.0 / 1.25 / 1.5
input group "══ HISTORY PANEL ══"
input bool Enable_HistoryPanel = true;   // ON = last 3 closed cycles ka history panel chart pe dikhega
input int  HistoryPanel_X = 10;    // History panel ki X position (pixels)
input int  HistoryPanel_Y = 450;   // History panel ki Y position (pixels)
input group "══ NEWS PANEL ══"
input bool Enable_NewsPanel = true;   // ON = agle 3 upcoming news events ka panel chart pe dikhega
input int  NewsPanel_X = 430;    // News panel ki X position (pixels)
input int  NewsPanel_Y = 450;    // News panel ki Y position (pixels)
input group "══ GAP TABLE ══"
input double Gap_01=5;  input double Gap_02=5;  input double Gap_03=6;   // Gap_XX = level XX ka naya grid-trade khulne ke liye zaroori $ move (ATR ON ho to aur bada ho sakta hai)
input double Gap_04=6;  input double Gap_05=7;  input double Gap_06=7;
input double Gap_07=8;  input double Gap_08=8;  input double Gap_09=9;
input double Gap_10=9;  input double Gap_11=10; input double Gap_12=10;
input double Gap_13=11; input double Gap_14=11; input double Gap_15=12;
input double Gap_16=12; input double Gap_17=13; input double Gap_18=13;
input double Gap_19=14; input double Gap_20=14; input double Gap_21=15;
input double Gap_22=15; input double Gap_23=16; input double Gap_24=16;
input double Gap_25=17; input double Gap_26=17; input double Gap_27=18;
input double Gap_28=18; input double Gap_29=19;
input double Gap_30=0;  input double Gap_31=0;  input double Gap_32=0;
input double Gap_33=0;  input double Gap_34=0;  input double Gap_35=0;
input double Gap_36=0;  input double Gap_37=0;  input double Gap_38=0;
input double Gap_39=0;  input double Gap_40=0;  input double Gap_41=0;
input double Gap_42=0;  input double Gap_43=0;  input double Gap_44=0;
input group "══ LOT TABLE ══"
input double Lot_01=0.01; input double Lot_02=0.01; input double Lot_03=0.01;   // Lot_XX = level XX ka lot size. 0 = us level ke aage grid rukk jayegi (max depth)
input double Lot_04=0.02; input double Lot_05=0.02; input double Lot_06=0.02;
input double Lot_07=0.03; input double Lot_08=0.03; input double Lot_09=0.03;
input double Lot_10=0.04; input double Lot_11=0.04; input double Lot_12=0.04;
input double Lot_13=0.05; input double Lot_14=0.05; input double Lot_15=0.05;
input double Lot_16=0.06; input double Lot_17=0.06; input double Lot_18=0.06;
input double Lot_19=0.07; input double Lot_20=0.07; input double Lot_21=0.07;
input double Lot_22=0.08; input double Lot_23=0.08; input double Lot_24=0.08;
input double Lot_25=0.09; input double Lot_26=0.09; input double Lot_27=0.09;
input double Lot_28=0.10; input double Lot_29=0.10; input double Lot_30=0.10;
input double Lot_31=0.00; input double Lot_32=0.00; input double Lot_33=0.00;
input double Lot_34=0.00; input double Lot_35=0.00; input double Lot_36=0.00;
input double Lot_37=0.00; input double Lot_38=0.00; input double Lot_39=0.00;
input double Lot_40=0.00; input double Lot_41=0.00; input double Lot_42=0.00;
input double Lot_43=0.00; input double Lot_44=0.00; input double Lot_45=0.00;
input group "══ WEEKEND FILTER ══"
input bool Enable_WeekendBlock = true;   // ON = weekend/market-open ke pehle-baad naya (pehla) trade nahi khulega
input int  Friday_Stop_Hour    = 14;     // Friday ko is IST hour ke baad naya trade band (weekend gap se bachne)
input int  Monday_Start_Hour   = 7;      // Monday ko is IST hour se pehle naya trade band (illiquid open se bachne)
input group "══ TRADING HOURS (10K) ══"
input bool Enable_TradingHours = true;   // ON = sirf Start-End IST ke beech naya cycle. Koi trade khula ho to cycle bahar bhi chalti rahegi
input int  Trade_Start_Hour    = 7;      // Is IST hour se naya cycle shuru ho sakta hai (7 = 7:00 AM)
input int  Trade_End_Hour      = 17;     // Is IST hour ke baad naya cycle nahi (17 = 5:00 PM)
input group "══ NOTIFICATIONS ══"
input bool   Enable_PushNotify  = true;    // ON = MT5 mobile app pe push notification alerts milenge
input bool   Enable_Telegram    = false;   // ON = Telegram alerts (abhi placeholder — actual sending implement nahi hai)
input string Telegram_Bot_Token = "";      // Telegram Bot ka API token (Telegram feature use karna ho to)
input string Telegram_Chat_ID   = "";      // Jis Telegram chat/group mein alert bhejni hai uski Chat ID
input group "══ GENERAL ══"
input long   Magic_Number  = 20250001;    // Is EA ki apni unique ID — isi Magic wali trades hi yeh manage karega
input int    Slippage      = 3;           // Order execution mein max allowed slippage (points)
input string Trade_Comment = "GridTrend_EA";   // Har trade ke comment mein yeh prefix lagega (identify karne ke liye)
input bool   Reset_Cycle_Baseline = false;  // v3.20: EMERGENCY FALLBACK ONLY — deposit/withdrawal ab AUTO-detect hoti hai (OnTradeTransaction), isko normally kabhi chhoona nahi padega
input group "══ GRID 2 MOBILE APP BRIDGE (v1.03) ══"
input bool   Enable_Bridge          = true;   // ON = live data Firebase pe push (GRID 2 phone app ke liye). Tester mein auto-OFF
input string Bridge_FB_URL          = "https://forexdiagnosis-default-rtdb.asia-southeast1.firebasedatabase.app";   // Firebase Realtime DB host (MT5 WebRequest list mein hona chahiye)
input string Bridge_Root            = "gt2";  // Firebase node — data /gt2/{account number} pe jayega
input int    Bridge_Push_Sec        = 5;      // Har kitne second live data push ho (5 = recommended)
input double Bridge_Opening_Balance = 0;      // App mein dikhne wala OPENING BALANCE. 0 = AUTO (account ke total deposits - withdrawals)

//--- Core variables
double   gapArr[44];
double   lotArr[45];
int      buyActive=0,  sellActive=0;
datetime buyStartTime=0, sellStartTime=0;
double   buyPeak=-1e10, sellPeak=-1e10;
bool     buyFrozen=false, sellFrozen=false;
int      cycleCount=0;
double   cycleStartBal=0, dailyStartBal=0;
datetime lastDayReset=0;
int      g_lastSig=0, g_lastSTDir=0;
int      g_pendingSig=0, g_pendingCount=0;   // whipsaw confirmation
int      atrHandle=INVALID_HANDLE;
datetime g_lastOpenTime=0;
datetime g_lastH1=0;
datetime g_lastM1=0;
datetime g_lastStateSave=0;
double   basketStartEquity=0;   // realized-inclusive global basket baseline (v3.04: BALANCE-anchored)
datetime lastPartialClose_Buy=0, lastPartialClose_Sell=0;   // partial-close cooldown

//--- v3.09: Performance analytics (lifetime, persisted across restarts)
int      g_totalWins=0, g_totalLosses=0;
double   g_totalProfitSum=0, g_totalLossSum=0;   // sum of winning $ and sum of |losing $|
double   g_sumDurationHrs=0;                     // for average recovery time
double   g_maxDDEver=0;                          // highest DD% ever seen (lifetime)
bool     g_totalDDTriggered=false;                // v1.05: LATCHED lock — state file mein save, sirf manual reset se khulta hai
datetime g_ddLockTime=0;                          // v1.05: lock kab laga (display/alert ke liye)
bool     g_resetInputPrev=false;                  // v1.05: pichli baar Reset_DD_Lockout kya tha — one-shot reset ke liye
bool     g_closePendB=false, g_closePendS=false;  // v1.05: close fail hua → basket flat hone tak retry
datetime g_spikeBlockUntil=0;                     // v3.16: volatility spike detect hone pe is time tak naya trade block
datetime g_eaInitTime=0;                          // v3.22: EA/backtest start time — initial-deposit false-positive rokne ke liye
// S2: PER-SIDE DD FLIP state
int      g_flipCount=0;            // is cycle mein kitne flips ho chuke
datetime g_lastFlipTime=0;         // last flip ka time (cooldown ke liye)
datetime g_flipPauseUntil=0;       // cap hit hone ke baad itne time tak koi flip nahi
int      g_ddFrozenDir=0;          // kaunsi side DD ki wajah se frozen hai (1=BUY, -1=SELL, 0=koi nahi)
#define  STATS_CSV_FILE_BASE  "GridTrendS2_TradeLog"
#define  DASHBOARD_EXPORT_FILE_BASE  "GridTrendS2_Dashboard"
#define  STATE_FILE_BASE             "GridTrendS2_EA_State"
// v3.25: har symbol ki apni alag file — XAUUSD aur EURUSD (ya kisi bhi 2 symbols) EK SAATH
// chalane par ab state/log/JSON files overwrite/corrupt nahi hongi, har symbol ka data alag rahega.
string g_statsCsvFile, g_dashboardJsonFile, g_stateFile;

//--- Dashboard export
datetime lastDashboardExport=0;
#define  STATE_VERSION          6   // v1.05: DD lockout state add (v5 file bhi load hoti hai)

//--- History & news
datetime last3CloseTime[3]    = {0,0,0};
double   last3CloseProfit[3]  = {0.0,0.0,0.0};
int      last3CloseDuration[3]= {0,0,0};
datetime nextNewsTime[3]      = {0,0,0};
string   nextNewsName[3]      = {"","",""};
int      nextNewsImpact[3]    = {0,0,0};
datetime lastNewsCheck        = 0;

//--- Dashboard defines
#define PFX        "V_"
#define DBW        330
#define LHT        28
#define FSZ        11

// DESKTOP FIX: Windows display scaling (125%/150%) pe font bada ho jaata hai par
// pixel boxes nahi — isliye rows overlap hoti thi. Ab saare pixel size/position scale hote hain.
double g_dbScale=1.0;
int SC(int v){ return (int)MathRound(v*g_dbScale); }
#define HIST_PNL_W   400
#define HIST_PNL_H   28
#define HIST_PNL_FSZ 11
#define HIST_PREFIX  "HP_"
#define NEWS_PNL_W   480
#define NEWS_PNL_H   28
#define NEWS_PNL_FSZ 11
#define NEWS_PREFIX  "NP_"
#define R_TITLE  0
#define R_SEP1   1
#define R_SIG    2
#define R_SEP2   3
#define R_PROFIT 4
#define R_BUY    5
#define R_SELL   6
#define R_SEP3   7
#define R_ST     8
#define R_ATR    9
#define R_DD     10
#define R_DD_STS 11
#define R_NEWS   12
#define R_SPREAD 13
#define R_WKD    14
#define R_SEP4   15
#define R_TRD    16
#define R_PNL    17
#define R_TBP    18
#define R_TSP    19
#define R_PHS    20
#define R_CYC    21
#define R_SEP5   22
#define R_BAL    23
#define R_EQ     24
#define R_GBL    25
#define R_SEP6   26
#define R_WINRATE 27
#define R_EXPECT  28
#define R_AVGREC  29
#define R_MAXDD   30
#define R_TOTDD   31
#define R_SPIKE   32

color BG_DARK  = C'3,3,3';       // base row (near-pure black) — v3.14 darker
color BG_MID   = C'7,6,3';       // alt row (amber-tinted near-black) — v3.14 darker
color BG_TITLE = C'196,130,0';   // AMBER title bar (text = black) — v3.14 deeper amber
color BG_SIG   = C'7,6,3';
color BG_PROF  = C'3,3,3';
color BG_BUY   = C'3,3,3';
color BG_SEL   = C'7,6,3';
color BG_SEP   = C'22,17,4';     // section header strip (dark amber) — v3.14 darker
color BG_PANEL = C'2,2,2';       // v3.14: master panel backing (blocks chart candles fully)

// v3.14: 3-COLUMN LAYOUT MAP — har row-id ka column (0/1/2) aur us column ke andar ka row number.
// Col0: F1 Signal + F2 Profit&Grids + F5 Account | Col1: F3 Filters&Risk | Col2: F4 Position + F6 Performance
int DB_COL[33]={-1,0,0,0,0,0,0,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,1};
int DB_ROW[33]={ 0,1,2,3,4,5,6,1,2,3,4,5,6,7,8,1,2,3,4,5,6,7,7,8,9,10,8,9,10,11,12,13,9};
#define DB_MAXROW  13   // sabse lambe column (Col2) mein kitni rows hain — master panel height isi se

// Row-background ka color halka karke ek thin "glossy" highlight strip banata hai (mirror-finish look)
color Lighten(color c,int amt)
{
   int r=(int)c & 0xFF, g=((int)c>>8)&0xFF, b=((int)c>>16)&0xFF;
   r=(int)MathMin(255,r+amt); g=(int)MathMin(255,g+amt); b=(int)MathMin(255,b+amt);
   return (color)((b<<16)|(g<<8)|r);
}
// Semantic text colors (QUANT TERMINAL amber theme)
color TXT_LBL  = C'170,125,30';  // labels (amber-dim)
color TXT_VAL  = C'230,230,222'; // values (near-white)
color CL_GREEN = C'80,220,100';  // positive
color CL_RED   = C'255,90,80';   // negative / alert
color CL_AMBER = C'255,176,0';   // amber primary
color CL_CYAN  = C'255,206,84';  // light amber (accent)
color CL_DIM   = C'110,85,30';   // dim amber

//+------------------------------------------------------------------+
//| DASHBOARD EXPORT                                                 |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| JSON string escape (quotes/backslash safe for event names)       |
//+------------------------------------------------------------------+
string JEsc(string s)
{
   string o="";
   for(int i=0;i<StringLen(s);i++)
   {
      ushort c=StringGetCharacter(s,i);
      if(c=='"'||c=='\\') { o+="\\"; o+=ShortToString(c); }
      else if(c=='\n'||c=='\r'||c=='\t') o+=" ";
      else o+=ShortToString(c);
   }
   return o;
}

void ExportDashboardJSON()
{
   if(!Enable_DashboardExport) return;
   int bCnt=CountTrades(1), sCnt=CountTrades(-1);
   // FIX: real profit = equity - cycleStartBal
   double pnl = AccountInfoDouble(ACCOUNT_EQUITY) - cycleStartBal;
   datetime istTime=TimeCurrent()+5*3600+30*60;
   MqlDateTime dt; TimeToStruct(istTime,dt);
   string istTimeStr=(dt.hour<10?"0":"")+IntegerToString(dt.hour)+":"+(dt.min<10?"0":"")+IntegerToString(dt.min);
   // v3.29: fallback phases remove — dashboard compatibility ke liye ab basket ki AGE bhejte hain
   double basketAgeH=0;
   datetime bkSt=GetGlobalBasketStart();
   if(bkSt>0) basketAgeH=(double)(TimeCurrent()-bkSt)/3600.0;
   string fbPhase=(bCnt+sCnt>0)?("Age "+DoubleToString(basketAgeH,1)+"h"):"Waiting...";
   string json="{";
   json+="\"signal\":"       +IntegerToString(g_lastSig)+",";
   json+="\"stDirection\":"  +IntegerToString(g_lastSTDir)+",";
   json+="\"pendingSig\":"   +IntegerToString(g_pendingSig)+",";
   json+="\"pendingCount\":" +IntegerToString(g_pendingCount)+",";
   json+="\"profit\":"       +DoubleToString(pnl,2)+",";
   json+="\"totalTarget\":"  +DoubleToString(Total_Profit_Target,2)+",";
   json+="\"buyTrades\":"    +IntegerToString(bCnt)+",";
   json+="\"sellTrades\":"   +IntegerToString(sCnt)+",";
   json+="\"buyFrozen\":"    +(buyFrozen?"true":"false")+",";
   json+="\"sellFrozen\":"   +(sellFrozen?"true":"false")+",";
   json+="\"drawdown\":"     +DoubleToString(GetCurrentDD(),2)+",";
   json+="\"flipCount\":"   +IntegerToString(g_flipCount)+",";
   json+="\"ddFrozenDir\":" +IntegerToString(g_ddFrozenDir)+",";
   json+="\"buySideDD\":"   +DoubleToString(GetNetPnL(1),2)+",";
   json+="\"sellSideDD\":"  +DoubleToString(GetNetPnL(-1),2)+",";
   json+="\"ddLevel\":0,";   // v3.28: % DD stages remove — dashboard compatibility ke liye key 0 pe fixed
   json+="\"newsActive\":"   +(IsNews()?"true":"false")+",";
   json+="\"spread\":"       +IntegerToString(GetCurrentSpread())+",";
   json+="\"weekend\":"      +(IsWeekendBlock()?"true":"false")+",";
   json+="\"netPnL\":"       +DoubleToString(GetNetPnL(1)+GetNetPnL(-1),2)+",";
   json+="\"fallbackPhase\":\""+fbPhase+"\",";
   json+="\"cycles\":"       +IntegerToString(cycleCount)+",";
   json+="\"balance\":"      +DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)+",";
   json+="\"equity\":"       +DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2)+",";
   json+="\"atrMult\":"      +DoubleToString(GetATRMult(),2)+",";
   double gbTgt=GetGlobalTarget();   // v3.29: fixed target, koi phase decay nahi
   double gbEq=AccountInfoDouble(ACCOUNT_EQUITY);
   double gbBase=(basketStartEquity>0)?basketStartEquity:gbEq;
   double gbRecov=gbEq-gbBase;
   json+="\"basketEnabled\":"+(string)(Enable_GlobalBasket?"true":"false")+",";
   json+="\"basketRecovery\":"+DoubleToString(gbRecov,2)+",";
   json+="\"basketStartEq\":" +DoubleToString(basketStartEquity,2)+",";
   json+="\"basketTarget\":" +DoubleToString(gbTgt,2)+",";
   json+="\"basketPhase\":1,";       // v3.29: phases remove — fixed 1
   json+="\"basketAgeHrs\":"+DoubleToString(basketAgeH,1)+",";
   json+="\"basketManaging\":"+(string)((CountTrades(1)>0&&CountTrades(-1)>0)?"true":"false")+",";
   json+="\"version\":\"3.18\",";
   // ---- v3.18: newer feature fields ----
   json+="\"buyTP\":"        +DoubleToString((CountTrades(1)>0)?CalcTP(1):0,2)+",";
   json+="\"sellTP\":"       +DoubleToString((CountTrades(-1)>0)?CalcTP(-1):0,2)+",";
   json+="\"totalDDDollar\":"+DoubleToString(GetCurrentDD_Dollar(),2)+",";
   json+="\"totalDDLimit\":" +DoubleToString(Total_DD_Dollar_Limit,2)+",";
   json+="\"totalDDOn\":"    +(string)(Enable_TotalDD_Limit?"true":"false")+",";
   int spikeSecLeft=(int)(g_spikeBlockUntil-TimeCurrent()); if(spikeSecLeft<0) spikeSecLeft=0;
   json+="\"spikeBlocked\":" +(string)(IsSpikeBlocked()?"true":"false")+",";
   json+="\"spikeSecLeft\":" +IntegerToString(spikeSecLeft)+",";
   int totCycAn=g_totalWins+g_totalLosses;
   double winRate=(totCycAn>0)?((double)g_totalWins/totCycAn*100.0):0;
   double avgWinA =(g_totalWins>0)?g_totalProfitSum/g_totalWins:0;
   double avgLossA=(g_totalLosses>0)?g_totalLossSum/g_totalLosses:0;
   double expectancyA=(winRate/100.0*avgWinA)-((1-winRate/100.0)*avgLossA);
   double avgRecA=(totCycAn>0)?g_sumDurationHrs/totCycAn:0;
   json+="\"winRate\":"      +DoubleToString(winRate,1)+",";
   json+="\"totalWins\":"    +IntegerToString(g_totalWins)+",";
   json+="\"totalLosses\":"  +IntegerToString(g_totalLosses)+",";
   json+="\"expectancy\":"   +DoubleToString(expectancyA,2)+",";
   json+="\"avgRecovery\":"  +DoubleToString(avgRecA,1)+",";
   json+="\"maxDDEver\":"    +DoubleToString(g_maxDDEver,2)+",";
   // ---- v3.19: SETTINGS object (current input values, dashboard EA ke liye) ----
   json+="\"cfgSigConfirmOn\":"+(string)(Enable_SignalConfirm?"true":"false")+",";
   json+="\"cfgSigConfirmBars\":"+IntegerToString(Signal_Confirm_Bars)+",";
   json+="\"cfgTotalDDOn\":"+(string)(Enable_TotalDD_Limit?"true":"false")+",";
   json+="\"cfgTotalDDLimit\":"+DoubleToString(Total_DD_Dollar_Limit,0)+",";
   json+="\"cfgRecHoldOn\":"+(string)(Enable_RecoveryHold?"true":"false")+",";
   json+="\"cfgRecHoldLastN\":"+IntegerToString(RecoveryHold_LastN)+",";
   json+="\"cfgRecHoldMinOpp\":"+IntegerToString(RecoveryHold_MinOppositeTrades)+",";
   json+="\"cfgNewsOn\":"+(string)(Enable_News?"true":"false")+",";
   json+="\"cfgNewsBefore\":"+IntegerToString(News_Before)+",";
   json+="\"cfgNewsAfter\":"+IntegerToString(News_After)+",";
   json+="\"cfgNewsHigh\":"+(string)(News_High?"true":"false")+",";
   json+="\"cfgNewsMed\":"+(string)(News_Medium?"true":"false")+",";
   json+="\"cfgSpikeOn\":"+(string)(Enable_SpikeFilter?"true":"false")+",";
   json+="\"cfgSpikeMove\":"+DoubleToString(Spike_Move_Dollars,0)+",";
   json+="\"cfgSpikeWindow\":"+IntegerToString(Spike_Window_Min)+",";
   json+="\"cfgSpikeBlockMin\":"+IntegerToString(Spike_Block_Min)+",";
   json+="\"cfgSpreadOn\":"+(string)(Enable_SpreadFilter?"true":"false")+",";
   json+="\"cfgMaxSpread\":"+DoubleToString(Max_Spread_Points,0)+",";
   json+="\"cfgWkdOn\":"+(string)(Enable_WeekendBlock?"true":"false")+",";
   json+="\"cfgFriStop\":"+IntegerToString(Friday_Stop_Hour)+",";
   json+="\"cfgMonStart\":"+IntegerToString(Monday_Start_Hour)+",";
   json+="\"cfgTrailOn\":"+(string)(Enable_Trailing?"true":"false")+",";
   json+="\"cfgTrailActivate\":"+DoubleToString(Trail_Activate,0)+",";
   json+="\"cfgTrailPullback\":"+DoubleToString(Trail_Pullback,0)+",";
   json+="\"cfgFallbackOn\":false,";   // v3.29: dono fallback system remove
   json+="\"cfgGlobalPct\":"+DoubleToString(Global_Target_Pct,2)+",";
   json+="\"cfgPartialOn\":"+(string)(Enable_PartialClose?"true":"false")+",";
   json+="\"cfgPartialPct\":"+DoubleToString(PartialClose_Trigger_Pct,0)+",";
   json+="\"cfgPartialMin\":"+IntegerToString(PartialClose_Min_Trades)+",";
   json+="\"cfgMaxTrades\":"+IntegerToString(Max_Trades)+",";
   json+="\"cfgAvgTP\":"+DoubleToString(AvgTP_PerTrade,1)+",";
   json+="\"cfgATROn\":"+(string)(Enable_ATR?"true":"false")+",";
   json+="\"cfgATRMaxMult\":"+DoubleToString(ATR_Max_Mult,1)+",";
   json+="\"cfgProfitTarget\":"+DoubleToString(Total_Profit_Target,0)+",";
   // ---- NEWS array (IST) ----
   json+="\"news\":[";
   bool firstN=true;
   for(int i=0;i<3;i++)
   {
      if(nextNewsTime[i]<=0) continue;
      datetime ist=nextNewsTime[i]+5*3600+30*60;
      MqlDateTime nd; TimeToStruct(ist,nd);
      string nt=(nd.hour<10?"0":"")+IntegerToString(nd.hour)+":"+(nd.min<10?"0":"")+IntegerToString(nd.min);
      if(!firstN) json+=","; firstN=false;
      json+="{\"time\":\""+nt+"\",\"impact\":"+IntegerToString(nextNewsImpact[i])+",\"name\":\""+JEsc(nextNewsName[i])+"\"}";
   }
   json+="],";
   // ---- HISTORY array (last 3 cycles) ----
   json+="\"history\":[";
   bool firstH=true;
   for(int i=0;i<3;i++)
   {
      if(last3CloseTime[i]<=0) continue;
      MqlDateTime hd; TimeToStruct(last3CloseTime[i],hd);
      string hdate=(hd.day<10?"0":"")+IntegerToString(hd.day)+"/"+(hd.mon<10?"0":"")+IntegerToString(hd.mon);
      string htime=(hd.hour<10?"0":"")+IntegerToString(hd.hour)+":"+(hd.min<10?"0":"")+IntegerToString(hd.min);
      if(!firstH) json+=","; firstH=false;
      json+="{\"profit\":"+DoubleToString(last3CloseProfit[i],2)+",\"date\":\""+hdate+"\",\"time\":\""+htime+"\",\"hrs\":"+IntegerToString(last3CloseDuration[i])+"}";
   }
   json+="],";
   json+="\"istTime\":\""    +istTimeStr+"\"";
   json+="}";
   int handle=FileOpen(g_dashboardJsonFile,FILE_WRITE|FILE_TXT);
   if(handle!=INVALID_HANDLE){FileWriteString(handle,json);FileClose(handle);}
}

//+------------------------------------------------------------------+
//| DASHBOARD OBJECT HELPERS                                         |
//+------------------------------------------------------------------+
void ClearDB()
{
   int tot=ObjectsTotal(0);
   for(int i=tot-1;i>=0;i--)
   { string n=ObjectName(0,i); if(StringFind(n,"V_")==0||StringFind(n,"Z_")==0) ObjectDelete(0,n); }
}

// QUANT TERMINAL dotted-leader row: "  LABEL ......... VALUE"
string DRow(string lbl)
{
   string s=lbl+" ";
   while(StringLen(s)<16) s+=".";
   return "  "+s+" ";
}

// v3.14: Master background panel — ek hi bada solid rectangle jo teeno column + gaps + title
// ko poora cover karta hai, taaki kahin bhi chart candles peeche se na dikhein.
void CreateMasterPanel()
{
   int x0=Dashboard_Left_X-6, y0=Dashboard_Y-6;
   int fullW=3*DBW+2*Dashboard_Col_Gap+12;
   int fullH=(DB_MAXROW+1)*LHT+12;
   string rb=PFX+"masterbg";
   if(ObjectFind(0,rb)<0) ObjectCreate(0,rb,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,rb,OBJPROP_XDISTANCE,SC(x0));
   ObjectSetInteger(0,rb,OBJPROP_YDISTANCE,SC(y0));
   ObjectSetInteger(0,rb,OBJPROP_XSIZE,SC(fullW));
   ObjectSetInteger(0,rb,OBJPROP_YSIZE,SC(fullH));
   ObjectSetInteger(0,rb,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,rb,OBJPROP_BGCOLOR,BG_PANEL);
   ObjectSetInteger(0,rb,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,rb,OBJPROP_COLOR,C'40,32,8');   // thin amber-dim frame edge
   ObjectSetInteger(0,rb,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,rb,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,rb,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,rb,OBJPROP_BACK,false);   // foreground — candles kabhi upar nahi aayenge
}

void CreateDBLine(int id,string txt,color clr,color bg)
{
   int x,y,w;
   if(id==0)   // TITLE — poore panel ki width mein span karta hai
   {
      x=Dashboard_Left_X; y=Dashboard_Y; w=3*DBW+2*Dashboard_Col_Gap;
   }
   else
   {
      int col=DB_COL[id], row=DB_ROW[id];
      x=Dashboard_Left_X+col*(DBW+Dashboard_Col_Gap);
      y=Dashboard_Y+row*LHT;
      w=DBW;
   }
   string rb=PFX+"r"+IntegerToString(id);
   if(ObjectFind(0,rb)<0) ObjectCreate(0,rb,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,rb,OBJPROP_XDISTANCE,  SC(x));
   ObjectSetInteger(0,rb,OBJPROP_YDISTANCE,  SC(y));
   ObjectSetInteger(0,rb,OBJPROP_XSIZE,      SC(w));
   ObjectSetInteger(0,rb,OBJPROP_YSIZE,      SC(LHT-1));
   ObjectSetInteger(0,rb,OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0,rb,OBJPROP_BGCOLOR,    bg);
   ObjectSetInteger(0,rb,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,rb,OBJPROP_COLOR,      bg);
   ObjectSetInteger(0,rb,OBJPROP_WIDTH,      0);
   ObjectSetInteger(0,rb,OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0,rb,OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0,rb,OBJPROP_BACK,       false);
   // v3.14: "Mirror finish" — row ke top pe 5px ka halka highlight strip (glassy reflection look)
   string hl=PFX+"h"+IntegerToString(id);
   if(ObjectFind(0,hl)<0) ObjectCreate(0,hl,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,hl,OBJPROP_XDISTANCE,  SC(x));
   ObjectSetInteger(0,hl,OBJPROP_YDISTANCE,  SC(y));
   ObjectSetInteger(0,hl,OBJPROP_XSIZE,      SC(w));
   ObjectSetInteger(0,hl,OBJPROP_YSIZE,      SC(5));
   ObjectSetInteger(0,hl,OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0,hl,OBJPROP_BGCOLOR,    Lighten(bg,22));
   ObjectSetInteger(0,hl,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,hl,OBJPROP_COLOR,      Lighten(bg,22));
   ObjectSetInteger(0,hl,OBJPROP_WIDTH,      0);
   ObjectSetInteger(0,hl,OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0,hl,OBJPROP_HIDDEN,     true);
   ObjectSetInteger(0,hl,OBJPROP_BACK,       false);
   string rl=PFX+"t"+IntegerToString(id);
   if(ObjectFind(0,rl)<0) ObjectCreate(0,rl,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,rl,OBJPROP_XDISTANCE,  SC(x+8));
   ObjectSetInteger(0,rl,OBJPROP_YDISTANCE,  SC(y+5));
   ObjectSetInteger(0,rl,OBJPROP_CORNER,     CORNER_LEFT_UPPER);
   ObjectSetInteger(0,rl,OBJPROP_ANCHOR,     ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,rl,OBJPROP_FONTSIZE,   FSZ);
   ObjectSetInteger(0,rl,OBJPROP_COLOR,      clr);
   ObjectSetInteger(0,rl,OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0,rl,OBJPROP_HIDDEN,     true);
   ObjectSetString(0,rl,OBJPROP_FONT,        "Consolas");
   ObjectSetString(0,rl,OBJPROP_TEXT,        txt);
}

void UpdateDBLine(int id,string txt,color clr,color bg)
{
   string rl=PFX+"t"+IntegerToString(id);
   string rb=PFX+"r"+IntegerToString(id);
   string hl=PFX+"h"+IntegerToString(id);
   if(ObjectFind(0,rl)>=0){ObjectSetString(0,rl,OBJPROP_TEXT,txt);ObjectSetInteger(0,rl,OBJPROP_COLOR,clr);}
   if(ObjectFind(0,rb)>=0) ObjectSetInteger(0,rb,OBJPROP_BGCOLOR,bg);
   if(ObjectFind(0,hl)>=0){color hc=Lighten(bg,22); ObjectSetInteger(0,hl,OBJPROP_BGCOLOR,hc); ObjectSetInteger(0,hl,OBJPROP_COLOR,hc);}
}

void BuildDB()
{
   ClearDB();
   CreateMasterPanel();   // v3.14: solid backing panel — candles kahin se bhi peeche se nahi dikhenge
   CreateDBLine(R_TITLE, "  GRIDTREND S2 - PER-SIDE DD FLIP v1.05", C'0,0,0', BG_TITLE);
   CreateDBLine(R_SEP1,  "  [F1] SIGNAL",                      CL_AMBER, BG_SEP);
   CreateDBLine(R_SIG,   DRow("Signal")+"...",            TXT_VAL,  BG_SIG);
   CreateDBLine(R_SEP2,  "  [F2] PROFIT & GRIDS",              CL_AMBER, BG_SEP);
   CreateDBLine(R_PROFIT,DRow("Profit")+"$0 / $500",      CL_CYAN,  BG_PROF);
   CreateDBLine(R_BUY,   DRow("BUY  Grid")+"Waiting",        CL_DIM,   BG_BUY);
   CreateDBLine(R_SELL,  DRow("SELL Grid")+"Waiting",        CL_DIM,   BG_SEL);
   CreateDBLine(R_SEP3,  "  [F3] FILTERS & RISK",              CL_AMBER, BG_SEP);
   CreateDBLine(R_ST,    DRow("Supertrend")+"---",            TXT_VAL,  BG_DARK);
   CreateDBLine(R_ATR,   DRow("ATR Gap")+"1.0x",           TXT_VAL,  BG_MID);
   CreateDBLine(R_DD,    DRow("Drawdown")+"0.00%",          CL_GREEN, BG_DARK);
   CreateDBLine(R_DD_STS,DRow("Side DD")+"--",              CL_DIM,   BG_MID);
   CreateDBLine(R_NEWS,  DRow("News")+"Safe",           CL_GREEN, BG_DARK);
   CreateDBLine(R_SPREAD,DRow("Spread")+"0 / 280",        CL_GREEN, BG_MID);
   CreateDBLine(R_WKD,   DRow("Weekend")+"OK",             CL_GREEN, BG_MID);
   CreateDBLine(R_SPIKE, DRow("Spike")+"Safe",             CL_GREEN, BG_DARK);
   CreateDBLine(R_SEP4,  "  [F4] POSITION",                    CL_AMBER, BG_SEP);
   CreateDBLine(R_TRD,   DRow("Trades")+"B:0   S:0",      TXT_VAL,  BG_DARK);
   CreateDBLine(R_PNL,   DRow("Net P&L")+"$0.00",          TXT_VAL,  BG_MID);
   CreateDBLine(R_TBP,   DRow("BUY TP @")+"---",            CL_CYAN,  BG_DARK);
   CreateDBLine(R_TSP,   DRow("SELL TP @")+"---",            CL_CYAN,  BG_MID);
   CreateDBLine(R_PHS,   DRow("Basket Age")+"--",            TXT_VAL,  BG_DARK);
   CreateDBLine(R_CYC,   DRow("Cycles")+"0 done",         TXT_VAL,  BG_MID);
   CreateDBLine(R_SEP5,  "  [F5] ACCOUNT",                     CL_AMBER, BG_SEP);
   CreateDBLine(R_BAL,   DRow("Balance")+"$0.00",          TXT_VAL,  BG_DARK);
   CreateDBLine(R_EQ,    DRow("Equity")+"$0.00",          TXT_VAL,  BG_MID);
   CreateDBLine(R_GBL,   DRow("Basket Rec")+"idle",           CL_DIM,   BG_DARK);
   CreateDBLine(R_SEP6,  "  [F6] PERFORMANCE",                       CL_AMBER, BG_SEP);
   CreateDBLine(R_WINRATE,DRow("Win Rate")+"--",              TXT_VAL,  BG_DARK);
   CreateDBLine(R_EXPECT, DRow("Expectancy")+"$0.00",          TXT_VAL,  BG_MID);
   CreateDBLine(R_AVGREC, DRow("Avg Recovery")+"-- hrs",        TXT_VAL,  BG_DARK);
   CreateDBLine(R_MAXDD,  DRow("Max DD Ever")+"0.00%",          CL_GREEN, BG_MID);
   CreateDBLine(R_TOTDD,  DRow("Total DD $")+"$0 / $300",       CL_GREEN, BG_DARK);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| HISTORY PANEL                                                    |
//+------------------------------------------------------------------+
void ClearHistoryPanel()
{
   int tot=ObjectsTotal(0);
   for(int i=tot-1;i>=0;i--)
   { string n=ObjectName(0,i); if(StringFind(n,HIST_PREFIX)==0) ObjectDelete(0,n); }
}

void CreateHistPanelLine(int id,string txt,color clr,color bg)
{
   int y=HistoryPanel_Y+id*HIST_PNL_H;
   string rb=HIST_PREFIX+"r"+IntegerToString(id);
   if(ObjectFind(0,rb)<0) ObjectCreate(0,rb,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,rb,OBJPROP_XDISTANCE, SC(HistoryPanel_X));
   ObjectSetInteger(0,rb,OBJPROP_YDISTANCE, SC(y));
   ObjectSetInteger(0,rb,OBJPROP_XSIZE,     SC(HIST_PNL_W));
   ObjectSetInteger(0,rb,OBJPROP_YSIZE,     SC(HIST_PNL_H-2));
   ObjectSetInteger(0,rb,OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0,rb,OBJPROP_BGCOLOR,   bg);
   ObjectSetInteger(0,rb,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,rb,OBJPROP_COLOR,     bg);
   ObjectSetInteger(0,rb,OBJPROP_WIDTH,     0);
   ObjectSetInteger(0,rb,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,rb,OBJPROP_HIDDEN,    true);
   ObjectSetInteger(0,rb,OBJPROP_BACK,      false);
   string rl=HIST_PREFIX+"t"+IntegerToString(id);
   if(ObjectFind(0,rl)<0) ObjectCreate(0,rl,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,rl,OBJPROP_XDISTANCE,SC(HistoryPanel_X+6));
   ObjectSetInteger(0,rl,OBJPROP_YDISTANCE,SC(y+5));
   ObjectSetInteger(0,rl,OBJPROP_CORNER,   CORNER_LEFT_UPPER);
   ObjectSetInteger(0,rl,OBJPROP_ANCHOR,   ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,rl,OBJPROP_FONTSIZE, HIST_PNL_FSZ);
   ObjectSetInteger(0,rl,OBJPROP_COLOR,    clr);
   ObjectSetInteger(0,rl,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,rl,OBJPROP_HIDDEN,   true);
   ObjectSetString(0,rl,OBJPROP_FONT,      "Consolas");
   ObjectSetString(0,rl,OBJPROP_TEXT,      txt);
}

void UpdateHistPanelLine(int id,string txt,color clr,color bg)
{
   string rl=HIST_PREFIX+"t"+IntegerToString(id);
   string rb=HIST_PREFIX+"r"+IntegerToString(id);
   if(ObjectFind(0,rl)>=0){ObjectSetString(0,rl,OBJPROP_TEXT,txt);ObjectSetInteger(0,rl,OBJPROP_COLOR,clr);}
   if(ObjectFind(0,rb)>=0) ObjectSetInteger(0,rb,OBJPROP_BGCOLOR,bg);
}

void BuildHistoryPanel()
{
   if(!Enable_HistoryPanel) return;
   ClearHistoryPanel();
   CreateHistPanelLine(0,"  [F6] CYCLE HISTORY",                     C'0,0,0', BG_TITLE);
   CreateHistPanelLine(1,"   #    Profit      Date     Time    Hrs", TXT_LBL,  BG_MID);
   CreateHistPanelLine(2,"   1    --          --/--    --:--   --",  CL_DIM,   BG_DARK);
   CreateHistPanelLine(3,"   2    --          --/--    --:--   --",  CL_DIM,   BG_MID);
   CreateHistPanelLine(4,"   3    --          --/--    --:--   --",  CL_DIM,   BG_DARK);
   ChartRedraw(0);
}

void UpdateHistoryPanel()
{
   if(!Enable_HistoryPanel) return;
   for(int i=0;i<3;i++)
   {
      color bgC=(i%2==0)?BG_DARK:BG_MID;
      if(last3CloseTime[i]>0)
      {
         MqlDateTime dt; TimeToStruct(last3CloseTime[i],dt);
         string dStr=(dt.day<10?"0":"")+IntegerToString(dt.day)+"/"+(dt.mon<10?"0":"")+IntegerToString(dt.mon);
         string tStr=(dt.hour<10?"0":"")+IntegerToString(dt.hour)+":"+(dt.min<10?"0":"")+IntegerToString(dt.min);
         string pStr="$"+DoubleToString(last3CloseProfit[i],2);
         while(StringLen(pStr)<10) pStr=pStr+" ";
         string hStr=IntegerToString(last3CloseDuration[i]);
         string row="   "+IntegerToString(i+1)+"    "+pStr+"  "+dStr+"    "+tStr+"   "+hStr;
         color rc=(last3CloseProfit[i]>=0)?CL_GREEN:CL_RED;
         UpdateHistPanelLine(i+2,row,rc,bgC);
      }
      else UpdateHistPanelLine(i+2,"   "+IntegerToString(i+1)+"    --          --/--    --:--   --",CL_DIM,bgC);
   }
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| NEWS PANEL                                                       |
//+------------------------------------------------------------------+
void ClearNewsPanel()
{
   int tot=ObjectsTotal(0);
   for(int i=tot-1;i>=0;i--)
   { string n=ObjectName(0,i); if(StringFind(n,NEWS_PREFIX)==0) ObjectDelete(0,n); }
}

void CreateNewsPanelLine(int id,string txt,color clr,color bg)
{
   int y=NewsPanel_Y+id*NEWS_PNL_H;
   string rb=NEWS_PREFIX+"r"+IntegerToString(id);
   if(ObjectFind(0,rb)<0) ObjectCreate(0,rb,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,rb,OBJPROP_XDISTANCE, SC(NewsPanel_X));
   ObjectSetInteger(0,rb,OBJPROP_YDISTANCE, SC(y));
   ObjectSetInteger(0,rb,OBJPROP_XSIZE,     SC(NEWS_PNL_W));
   ObjectSetInteger(0,rb,OBJPROP_YSIZE,     SC(NEWS_PNL_H-2));
   ObjectSetInteger(0,rb,OBJPROP_CORNER,    CORNER_LEFT_UPPER);
   ObjectSetInteger(0,rb,OBJPROP_BGCOLOR,   bg);
   ObjectSetInteger(0,rb,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,rb,OBJPROP_COLOR,     bg);
   ObjectSetInteger(0,rb,OBJPROP_WIDTH,     0);
   ObjectSetInteger(0,rb,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,rb,OBJPROP_HIDDEN,    true);
   ObjectSetInteger(0,rb,OBJPROP_BACK,      false);
   string rl=NEWS_PREFIX+"t"+IntegerToString(id);
   if(ObjectFind(0,rl)<0) ObjectCreate(0,rl,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,rl,OBJPROP_XDISTANCE,SC(NewsPanel_X+6));
   ObjectSetInteger(0,rl,OBJPROP_YDISTANCE,SC(y+5));
   ObjectSetInteger(0,rl,OBJPROP_CORNER,   CORNER_LEFT_UPPER);
   ObjectSetInteger(0,rl,OBJPROP_ANCHOR,   ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,rl,OBJPROP_FONTSIZE, NEWS_PNL_FSZ);
   ObjectSetInteger(0,rl,OBJPROP_COLOR,    clr);
   ObjectSetInteger(0,rl,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,rl,OBJPROP_HIDDEN,   true);
   ObjectSetString(0,rl,OBJPROP_FONT,      "Consolas");
   ObjectSetString(0,rl,OBJPROP_TEXT,      txt);
}

void UpdateNewsPanelLine(int id,string txt,color clr,color bg)
{
   string rl=NEWS_PREFIX+"t"+IntegerToString(id);
   string rb=NEWS_PREFIX+"r"+IntegerToString(id);
   if(ObjectFind(0,rl)>=0){ObjectSetString(0,rl,OBJPROP_TEXT,txt);ObjectSetInteger(0,rl,OBJPROP_COLOR,clr);}
   if(ObjectFind(0,rb)>=0) ObjectSetInteger(0,rb,OBJPROP_BGCOLOR,bg);
}

void BuildNewsPanel()
{
   if(!Enable_NewsPanel) return;
   ClearNewsPanel();
   CreateNewsPanelLine(0,"  [F7] NEWS EVENTS (IST)",                   C'0,0,0', BG_TITLE);
   CreateNewsPanelLine(1,"   #    Time      Impact    Event",          TXT_LBL, BG_MID);
   CreateNewsPanelLine(2,"   1    --:--     --        --",             CL_DIM,  BG_DARK);
   CreateNewsPanelLine(3,"   2    --:--     --        --",             CL_DIM,  BG_MID);
   CreateNewsPanelLine(4,"   3    --:--     --        --",             CL_DIM,  BG_DARK);
   ChartRedraw(0);
}

void UpdateNewsPanel()
{
   if(!Enable_NewsPanel) return;
   for(int i=0;i<3;i++)
   {
      color bgC=(i%2==0)?BG_DARK:BG_MID;
      if(nextNewsTime[i]>0)
      {
         datetime ist=nextNewsTime[i]+5*3600+30*60;
         MqlDateTime dt; TimeToStruct(ist,dt);
         string tStr=(dt.hour<10?"0":"")+IntegerToString(dt.hour)+":"+(dt.min<10?"0":"")+IntegerToString(dt.min);
         string impStr=(nextNewsImpact[i]==1)?"HIGH":(nextNewsImpact[i]==2)?"MED":"--";
         while(StringLen(impStr)<8) impStr=impStr+" ";
         color impClr=(nextNewsImpact[i]==1)?CL_RED:(nextNewsImpact[i]==2)?CL_AMBER:CL_DIM;
         string evName=nextNewsName[i];
         if(StringLen(evName)>20) evName=StringSubstr(evName,0,20);
         UpdateNewsPanelLine(i+2,"   "+IntegerToString(i+1)+"    "+tStr+"     "+impStr+"  "+evName,impClr,bgC);
      }
      else UpdateNewsPanelLine(i+2,"   "+IntegerToString(i+1)+"    --:--     --        --",CL_DIM,bgC);
   }
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| HELPERS                                                          |
//+------------------------------------------------------------------+
string TimeToIST(datetime t)
{
   datetime ist=t+5*3600+30*60;
   MqlDateTime dt; TimeToStruct(ist,dt);
   return (dt.hour<10?"0":"")+IntegerToString(dt.hour)+":"+(dt.min<10?"0":"")+IntegerToString(dt.min);
}

void FetchNextNewsEvents()
{
   if(!Enable_News) return;
   if(TimeCurrent()-lastNewsCheck<300) return;
   lastNewsCheck=TimeCurrent();
   for(int i=0;i<3;i++){nextNewsTime[i]=0;nextNewsName[i]="";nextNewsImpact[i]=0;}
   datetime now=TimeCurrent();
   MqlCalendarValue vals[];
   int n=CalendarValueHistory(vals,now-(datetime)(News_After*60),now+(datetime)(News_Before*60+86400),"US");
   datetime tT[100]; string tN[100]; int tI[100]; int idx=0;
   for(int i=0;i<n&&idx<100;i++)
   {
      MqlCalendarEvent ev;
      if(!CalendarEventById(vals[i].event_id,ev)) continue;
      bool isH=(News_High&&ev.importance==CALENDAR_IMPORTANCE_HIGH);
      bool isM=(News_Medium&&ev.importance==CALENDAR_IMPORTANCE_MODERATE);
      if(!isH&&!isM) continue;
      datetime et=(datetime)vals[i].time;
      if(et<=now) continue;
      tT[idx]=et; tN[idx]=ev.name; tI[idx]=isH?1:2; idx++;
   }
   for(int i=0;i<idx-1;i++)
      for(int j=i+1;j<idx;j++)
         if(tT[i]>tT[j]){datetime tt=tT[i];string tn=tN[i];int ti=tI[i];tT[i]=tT[j];tN[i]=tN[j];tI[i]=tI[j];tT[j]=tt;tN[j]=tn;tI[j]=ti;}
   for(int i=0;i<3&&i<idx;i++){nextNewsTime[i]=tT[i];nextNewsName[i]=tN[i];nextNewsImpact[i]=tI[i];}
}

// v3.29: GetPhaseHours() / CalcFallbackTarget() / GetFallbackPhaseStr() pura remove —
// basket target ab seedha AvgTP_PerTrade x trades hai (GetTPTarget dekho).

//+------------------------------------------------------------------+
//| UPDATE DASHBOARD                                                 |
//+------------------------------------------------------------------+
void UpdateDB()
{
   int bCnt=CountTrades(1),sCnt=CountTrades(-1);
   if(g_lastSig==1)       UpdateDBLine(R_SIG,DRow("Signal")+"BUY",CL_GREEN,BG_SIG);
   else if(g_lastSig==-1) UpdateDBLine(R_SIG,DRow("Signal")+"SELL",CL_RED,BG_SIG);
   else                   UpdateDBLine(R_SIG,DRow("Signal")+"Loading",CL_DIM,BG_SIG);
   double pAll = AccountInfoDouble(ACCOUNT_EQUITY) - cycleStartBal;
   color pc=(pAll>=Total_Profit_Target*0.8)?CL_GREEN:(pAll<0)?CL_RED:CL_CYAN;
   UpdateDBLine(R_PROFIT,DRow("Profit")+"$"+DoubleToString(pAll,2)+" / $"+DoubleToString(Total_Profit_Target,0),pc,BG_PROF);
   string bs; color bc;
   if(bCnt>0&&!buyFrozen){bs=DRow("BUY  Grid")+"ACTIVE  T:"+IntegerToString(bCnt);bc=CL_GREEN;}
   else if(bCnt>0){bs=DRow("BUY  Grid")+"FROZEN  T:"+IntegerToString(bCnt);bc=CL_CYAN;}
   else{bs=(g_lastSig==1)?DRow("BUY  Grid")+"Ready":DRow("BUY  Grid")+"Waiting";bc=(g_lastSig==1)?CL_GREEN:CL_DIM;}
   UpdateDBLine(R_BUY,bs,bc,BG_BUY);
   string ss; color sc;
   if(sCnt>0&&!sellFrozen){ss=DRow("SELL Grid")+"ACTIVE  T:"+IntegerToString(sCnt);sc=CL_RED;}
   else if(sCnt>0){ss=DRow("SELL Grid")+"FROZEN  T:"+IntegerToString(sCnt);sc=CL_CYAN;}
   else{ss=(g_lastSig==-1)?DRow("SELL Grid")+"Ready":DRow("SELL Grid")+"Waiting";sc=(g_lastSig==-1)?CL_GREEN:CL_DIM;}
   UpdateDBLine(R_SELL,ss,sc,BG_SEL);
   string stS=(g_lastSTDir==1)?"BUY":(g_lastSTDir==-1)?"SELL":"Loading";
   if(Enable_SignalConfirm&&g_pendingSig!=0&&g_pendingSig!=g_lastSig)
      stS+="  ("+(g_pendingSig==1?"BUY":"SELL")+" "+IntegerToString(g_pendingCount)+"/"+IntegerToString(Signal_Confirm_Bars)+")";
   UpdateDBLine(R_ST,DRow("Supertrend")+""+stS,(g_lastSTDir==1)?CL_GREEN:(g_lastSTDir==-1)?CL_RED:CL_DIM,BG_DARK);
   double am=GetATRMult();
   UpdateDBLine(R_ATR,DRow("ATR Gap")+""+DoubleToString(am,2)+"x",(am>=2)?CL_AMBER:TXT_VAL,BG_MID);
   // v3.28: DD% ab sirf INFO hai (koi auto-action nahi). Color ab $ limit ke % se banta hai.
   double dd=GetCurrentDD();
   double ddDolNow=GetCurrentDD_Dollar();
   double ddFrac=(Enable_TotalDD_Limit&&Total_DD_Dollar_Limit>0)?(ddDolNow/Total_DD_Dollar_Limit):0.0;
   color ddCol=(ddFrac>=0.75)?CL_RED:(ddFrac>=0.40)?CL_AMBER:(ddDolNow>0)?TXT_VAL:CL_GREEN;
   UpdateDBLine(R_DD,DRow("Drawdown")+""+DoubleToString(dd,2)+"%",ddCol,BG_DARK);
   // S2: per-side DD + flip counter
   double bSideDD=(bCnt>0)?GetNetPnL(1):0, sSideDD=(sCnt>0)?GetNetPnL(-1):0;
   double worstSide=MathMin(bSideDD,sSideDD);
   string ddMsg=DRow("Side DD")+"B$"+DoubleToString(bSideDD,0)+" S$"+DoubleToString(sSideDD,0)+
                "  F"+IntegerToString(g_flipCount)+"/"+IntegerToString(DD_Flip_Max_Per_Cycle)+
                (g_ddFrozenDir!=0?((g_ddFrozenDir==1)?" [B frz]":" [S frz]"):"");
   color ddSts=(worstSide<=-DD_Flip_Dollars*0.75)?CL_RED:(worstSide<=-DD_Flip_Dollars*0.5)?CL_AMBER:CL_DIM;
   UpdateDBLine(R_DD_STS,ddMsg,ddSts,BG_MID);
   bool nw=IsNews();
   string nMsg=DRow("News")+"";
   if(nw) nMsg+="BLOCK";
   else if(nextNewsTime[0]>0) nMsg+="Next "+TimeToIST(nextNewsTime[0]);
   else nMsg+="Safe";
   UpdateDBLine(R_NEWS,nMsg,nw?CL_RED:CL_GREEN,BG_DARK);
   int spPts=GetCurrentSpread(); bool spHigh=IsSpreadTooHigh();
   UpdateDBLine(R_SPREAD,DRow("Spread")+""+IntegerToString(spPts)+" / 280",spHigh?CL_RED:CL_GREEN,BG_MID);
   bool wkd=IsWeekendBlock(), offH=IsOutsideHours();
   string wTxt=wkd?"BLOCKED":offH?("OFF HRS "+IntegerToString(Trade_Start_Hour)+"-"+IntegerToString(Trade_End_Hour)):"OK";
   UpdateDBLine(R_WKD,DRow("Weekend")+wTxt,wkd?CL_RED:offH?CL_AMBER:CL_GREEN,BG_MID);
   bool spikeBlocked=IsSpikeBlocked();
   if(spikeBlocked)
   {
      int secsLeft=(int)(g_spikeBlockUntil-TimeCurrent());
      if(secsLeft<0) secsLeft=0;
      UpdateDBLine(R_SPIKE,DRow("Spike")+"BLOCKED "+IntegerToString(secsLeft/60)+"m"+IntegerToString(secsLeft%60)+"s",CL_RED,BG_DARK);
   }
   else UpdateDBLine(R_SPIKE,DRow("Spike")+"Safe",CL_GREEN,BG_DARK);
   UpdateDBLine(R_TRD,DRow("Trades")+"B:"+IntegerToString(bCnt)+"   S:"+IntegerToString(sCnt),TXT_VAL,BG_DARK);
   double flt=GetNetPnL(1)+GetNetPnL(-1);   // real floating P&L of OPEN trades
   UpdateDBLine(R_PNL,DRow("Net P&L")+"$"+DoubleToString(flt,2),(flt>=0)?CL_GREEN:CL_RED,BG_MID);
   string tb="---",ts="---";
   if(bCnt>0){double t=CalcTP(1);if(t>0)tb=DoubleToString(t,_Digits);}
   if(sCnt>0){double t=CalcTP(-1);if(t>0)ts=DoubleToString(t,_Digits);}
   UpdateDBLine(R_TBP,DRow("BUY TP @")+""+tb,CL_CYAN,BG_DARK);
   UpdateDBLine(R_TSP,DRow("SELL TP @")+""+ts,CL_CYAN,BG_MID);
   // v3.29: FB Phase row ab basket ki AGE dikhati hai (koi time-based action nahi hota)
   string ph="--"; color phc=CL_DIM;
   datetime bkStart=GetGlobalBasketStart();
   if(bCnt+sCnt>0 && bkStart>0)
   {
      double ageH=(double)(TimeCurrent()-bkStart)/3600.0;
      ph=DoubleToString(ageH,1)+"h open";
      phc=(ageH>=72)?CL_AMBER:TXT_VAL;
   }
   UpdateDBLine(R_PHS,DRow("Basket Age")+""+ph,phc,BG_DARK);
   UpdateDBLine(R_CYC,DRow("Cycles")+""+IntegerToString(cycleCount)+" done",(cycleCount>0)?CL_GREEN:CL_DIM,BG_MID);
   double bal=AccountInfoDouble(ACCOUNT_BALANCE),eq=AccountInfoDouble(ACCOUNT_EQUITY);
   UpdateDBLine(R_BAL,DRow("Balance")+"$"+DoubleToString(bal,2),TXT_VAL,BG_DARK);
   UpdateDBLine(R_EQ, DRow("Equity")+"$"+DoubleToString(eq,2),(eq>=bal)?CL_GREEN:CL_RED,BG_MID);
   // Global basket TP row
   if(Enable_GlobalBasket)
   {
      int gbC=bCnt+sCnt;
      if(gbC>0)
      {
         double base=(basketStartEquity>0)?basketStartEquity:bal;
         double recov=eq-base;
         double gt=GetGlobalTarget();   // v3.29: fixed target
         string gtStr="$"+DoubleToString(gt,1);
         string mode=(bCnt>0&&sCnt>0)?"  MANAGING":"";
         color gbc=(recov>=0)?CL_GREEN:CL_CYAN;
         UpdateDBLine(R_GBL,DRow("Basket Rec")+"$"+DoubleToString(recov,1)+" / "+gtStr+mode,gbc,BG_DARK);
      }
      else UpdateDBLine(R_GBL,DRow("Basket Rec")+"idle",CL_DIM,BG_DARK);
   }
   else UpdateDBLine(R_GBL,DRow("Basket Rec")+"OFF",CL_DIM,BG_DARK);
   // v3.09: PERFORMANCE ANALYTICS row updates
   int totCyc=g_totalWins+g_totalLosses;
   if(totCyc>0)
   {
      double wr=(double)g_totalWins/totCyc*100.0;
      UpdateDBLine(R_WINRATE,DRow("Win Rate")+DoubleToString(wr,1)+"%  ("+IntegerToString(g_totalWins)+"W/"+IntegerToString(g_totalLosses)+"L)",
                   (wr>=50)?CL_GREEN:CL_AMBER,BG_DARK);
      double avgWin =(g_totalWins>0)  ?g_totalProfitSum/g_totalWins :0;
      double avgLoss=(g_totalLosses>0)?g_totalLossSum/g_totalLosses :0;
      double expectancy=(wr/100.0*avgWin)-((1-wr/100.0)*avgLoss);
      UpdateDBLine(R_EXPECT,DRow("Expectancy")+"$"+DoubleToString(expectancy,2)+" /cycle",
                   (expectancy>=0)?CL_GREEN:CL_RED,BG_MID);
      double avgRec=g_sumDurationHrs/totCyc;
      UpdateDBLine(R_AVGREC,DRow("Avg Recovery")+DoubleToString(avgRec,1)+" hrs",TXT_VAL,BG_DARK);
   }
   else
   {
      UpdateDBLine(R_WINRATE,DRow("Win Rate")+"-- (no data)",CL_DIM,BG_DARK);
      UpdateDBLine(R_EXPECT, DRow("Expectancy")+"--",CL_DIM,BG_MID);
      UpdateDBLine(R_AVGREC, DRow("Avg Recovery")+"--",CL_DIM,BG_DARK);
   }
   // v3.28: DD inputs remove — yeh sirf display thresholds hain (20% red / 10% amber), koi action trigger nahi karte
   UpdateDBLine(R_MAXDD,DRow("Max DD Ever")+DoubleToString(g_maxDDEver,2)+"%",
                (g_maxDDEver>=20.0)?CL_RED:(g_maxDDEver>=10.0)?CL_AMBER:CL_GREEN,BG_MID);
   // v3.12: Total DD $ (fixed dollar hard-stop) status row
   if(g_totalDDTriggered)   // v1.05
      UpdateDBLine(R_TOTDD,DRow("Total DD $")+"LOCKED - manual reset",CL_RED,BG_DARK);
   else if(Enable_TotalDD_Limit)
   {
      double ddDol=GetCurrentDD_Dollar();
      color tdc=(ddDol>=Total_DD_Dollar_Limit)?CL_RED:(ddDol>=Total_DD_Dollar_Limit*0.7)?CL_AMBER:CL_GREEN;
      UpdateDBLine(R_TOTDD,DRow("Total DD $")+"$"+DoubleToString(ddDol,2)+" / $"+DoubleToString(Total_DD_Dollar_Limit,0),tdc,BG_DARK);
   }
   else UpdateDBLine(R_TOTDD,DRow("Total DD $")+"OFF",CL_DIM,BG_DARK);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| MARKET ANALYSIS                                                  |
//+------------------------------------------------------------------+
int GetST()
{
   int bars=ST_Period+100;
   double aB[],hi[],lo[],cl[];
   ArraySetAsSeries(aB,true);ArraySetAsSeries(hi,true);ArraySetAsSeries(lo,true);ArraySetAsSeries(cl,true);
   if(CopyBuffer(atrHandle,0,1,bars,aB)<bars) return g_lastSTDir;
   if(CopyHigh(_Symbol,Filter_TF,1,bars,hi)<bars) return g_lastSTDir;
   if(CopyLow(_Symbol,Filter_TF,1,bars,lo)<bars) return g_lastSTDir;
   if(CopyClose(_Symbol,Filter_TF,1,bars,cl)<bars) return g_lastSTDir;
   double pU=0,pD=0; int tr=-1;
   for(int i=bars-1;i>=0;i--)
   {
      double hl=(hi[i]+lo[i])/2;
      double bU=hl+ST_Multiplier*aB[i],bD=hl-ST_Multiplier*aB[i];
      double fU,fD;
      if(i==bars-1){fU=bU;fD=bD;}
      else{fD=(bD>pD||cl[i+1]<pD)?bD:pD;fU=(bU<pU||cl[i+1]>pU)?bU:pU;}
      tr=(tr==-1)?((cl[i]>fU)?1:-1):((cl[i]<fD)?-1:1);
      pU=fU;pD=fD;
   }
   if(tr!=0) g_lastSTDir=tr;
   return g_lastSTDir;
}

bool IsNews()
{
   if(!Enable_News) return false;
   datetime now=TimeCurrent();
   MqlCalendarValue vals[];
   int n=CalendarValueHistory(vals,now-(datetime)(News_After*60),now+(datetime)(News_Before*60),"US");
   for(int i=0;i<n;i++)
   {
      MqlCalendarEvent ev;
      if(!CalendarEventById(vals[i].event_id,ev)) continue;
      if(News_High&&ev.importance==CALENDAR_IMPORTANCE_HIGH) return true;
      if(News_Medium&&ev.importance==CALENDAR_IMPORTANCE_MODERATE) return true;
   }
   return false;
}

int GetCurrentSpread(){return (int)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);}
bool IsSpreadTooHigh(){return Enable_SpreadFilter&&(GetCurrentSpread()>Max_Spread_Points);}

//+------------------------------------------------------------------+
//| v3.16: VOLATILITY SPIKE FILTER — news calendar se independent.    |
//| Agar Spike_Window_Min ke andar Spike_Move_Dollars se zyada        |
//| one-side move ho jaye, Spike_Block_Min tak naya trade block hai.  |
//+------------------------------------------------------------------+
void CheckVolatilitySpike()
{
   if(!Enable_SpikeFilter) return;
   double nowPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double pastPrice=iClose(_Symbol,PERIOD_M1,Spike_Window_Min);
   if(pastPrice<=0) return;   // history abhi load nahi hui
   double move=MathAbs(nowPrice-pastPrice);
   if(move>=Spike_Move_Dollars)
   {
      datetime newUntil=TimeCurrent()+Spike_Block_Min*60;
      if(newUntil>g_spikeBlockUntil)   // extend karo, kabhi ghatao mat
      {
         if(g_spikeBlockUntil<TimeCurrent())   // sirf FRESH spike pe hi alert (already-blocked window ko silently extend mat)
            SendAlert("VOLATILITY SPIKE! $"+DoubleToString(move,2)+" move in "+IntegerToString(Spike_Window_Min)+"min — new entries paused "+IntegerToString(Spike_Block_Min)+"min");
         g_spikeBlockUntil=newUntil;
      }
   }
}

bool IsSpikeBlocked(){ return Enable_SpikeFilter && TimeCurrent()<g_spikeBlockUntil; }

//+------------------------------------------------------------------+
//| S2: PER-SIDE DD FLIP                                             |
//| Buy aur Sell ka drawdown alag-alag gina jata hai. Jis side ka    |
//| floating loss DD_Flip_Dollars cross kare: woh side KHULI REHTI   |
//| hai par FREEZE ho jati hai (naye grid level nahi), aur opposite  |
//| side ka grid normal 0.01 lot se fresh start hota hai.            |
//| Frozen side apne average TP pe khud band ho sakti hai.           |
//+------------------------------------------------------------------+
void CheckDDFlip()
{
   if(!Enable_DDFlip) return;
   if(g_totalDDTriggered) return;   // v1.05: DD lock ke dauraan koi flip / naya grid nahi
   int bCnt=CountTrades(1), sCnt=CountTrades(-1);
   if(bCnt==0 && sCnt==0)
   { g_flipCount=0; g_ddFrozenDir=0; g_flipPauseUntil=0; return; }   // naya cycle — counter reset
   // v1.01 FIX: pause chal raha hai → wait; pause khatam → counter reset, flips phir chalu
   if(g_flipPauseUntil>0)
   {
      if(TimeCurrent()<g_flipPauseUntil) return;
      g_flipPauseUntil=0; g_flipCount=0;
      SendAlert("DD FLIP PAUSE KHATAM — flip counter reset, flips phir chalu");
   }
   // safety: cap pe hai par pause set nahi (jaise purani state-file se load) → pause shuru
   if(g_flipCount>=DD_Flip_Max_Per_Cycle)
   {
      g_flipPauseUntil=TimeCurrent()+DD_Flip_Pause_Hrs*3600;
      SendAlert("DD FLIP CAP: "+IntegerToString(g_flipCount)+" flips ho chuke — "+
                IntegerToString(DD_Flip_Pause_Hrs)+"h pause, ab normal logic chalegi");
      return;
   }
   if(TimeCurrent()-g_lastFlipTime < DD_Flip_Cooldown_Min*60) return;

   double bp=GetNetPnL(1), sp=GetNetPnL(-1);
   int loseDir=0; double worst=0;
   // v1.01 FIX: jo side pehle se DD-frozen hai woh dobara flip count nahi karegi
   if(bCnt>0 && g_ddFrozenDir!=1  && bp<=-DD_Flip_Dollars){ loseDir=1;  worst=bp; }
   if(sCnt>0 && g_ddFrozenDir!=-1 && sp<=-DD_Flip_Dollars && (loseDir==0 || sp<worst)){ loseDir=-1; worst=sp; }
   if(loseDir==0) return;

   int newDir=-loseDir;
   g_flipCount++;
   g_lastFlipTime=TimeCurrent();
   g_ddFrozenDir=loseDir;
   SendAlert("DD FLIP #"+IntegerToString(g_flipCount)+": "+(loseDir==1?"BUY":"SELL")+
             " side $"+DoubleToString(worst,2)+" — FREEZE (khuli rahegi), "+
             (newDir==1?"BUY":"SELL")+" grid start");
   // v1.01: 4th flip hote hi 6h pause turant shuru
   if(g_flipCount>=DD_Flip_Max_Per_Cycle)
   {
      g_flipPauseUntil=TimeCurrent()+DD_Flip_Pause_Hrs*3600;
      SendAlert("DD FLIP CAP: "+IntegerToString(g_flipCount)+" flips ho chuke — "+
                IntegerToString(DD_Flip_Pause_Hrs)+"h pause, uske baad counter reset");
   }
   if(loseDir==1){ buyFrozen=true;  sellFrozen=false; }
   else          { sellFrozen=true; buyFrozen=false;  }
   g_lastSig=newDir;   // flip ko hi naya signal maan lo
   if(newDir==1 && Enable_BuyGrid)
   {
      buyActive=1;
      if(bCnt==0){ buyStartTime=TimeCurrent(); OpenTrade(1); }   // normal lot (0.01) se fresh
   }
   else if(newDir==-1 && Enable_SellGrid)
   {
      sellActive=1;
      if(sCnt==0){ sellStartTime=TimeCurrent(); OpenTrade(-1); }
   }
}

double GetCurrentDD()
{
   double bal=AccountInfoDouble(ACCOUNT_BALANCE),eq=AccountInfoDouble(ACCOUNT_EQUITY);
   if(bal<=0) return 0;
   return (bal-eq)/bal*100.0;
}

// v3.28: GetCurrentDDLevel() / CloseLosingTrades() / SendDDAlert() / CheckStagedDD()
// pura remove — % based staged drawdown system ab EA mein nahi hai.

double GetATRMult()
{
   if(!Enable_ATR) return 1.0;
   double aB[]; ArraySetAsSeries(aB,true);
   if(CopyBuffer(atrHandle,0,1,ATR_Avg_Bars+2,aB)<ATR_Avg_Bars+2) return 1.0;
   double cur=aB[0],sum=0;
   for(int i=1;i<=ATR_Avg_Bars;i++) sum+=aB[i];
   double avg=sum/ATR_Avg_Bars;
   return NormalizeDouble(MathMax(1.0,MathMin(ATR_Max_Mult,cur/avg)),2);
}

bool IsWeekendBlock()
{
   if(!Enable_WeekendBlock) return false;
   datetime nowIST=TimeGMT()+5*3600+30*60;
   MqlDateTime dt; TimeToStruct(nowIST,dt);
   if(dt.day_of_week==5&&dt.hour>=Friday_Stop_Hour) return true;
   if(dt.day_of_week==6||dt.day_of_week==0) return true;
   if(dt.day_of_week==1&&dt.hour<Monday_Start_Hour) return true;
   return false;
}

// 10K: trading hours ke bahar? (IST). Sirf NAYA cycle rokta hai — OpenTrade mein b+s==0 check
bool IsOutsideHours()
{
   if(!Enable_TradingHours) return false;
   datetime nowIST=TimeGMT()+5*3600+30*60;
   MqlDateTime dt; TimeToStruct(nowIST,dt);
   return (dt.hour<Trade_Start_Hour || dt.hour>=Trade_End_Hour);
}

void SendAlert(string msg){Print("ALERT: ",msg);if(Enable_PushNotify)SendNotification(msg);BrEvent(msg);}   // v1.03: app feed mein bhi

//+------------------------------------------------------------------+
//| v3.13: RECOVERY HOLD — ek direction ke sabse RECENT N (opened)   |
//| trades check karta hai — sab profit mein hain kya (recovering)   |
//+------------------------------------------------------------------+
bool LastNTradesProfitable(int dir,int n)
{
   if(n<=0) return false;
   datetime times[100]; double profits[100]; int cnt=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol||pos.Magic()!=Magic_Number) continue;
      bool m=(dir==1&&pos.PositionType()==POSITION_TYPE_BUY)||(dir==-1&&pos.PositionType()==POSITION_TYPE_SELL);
      if(!m) continue;
      if(cnt<100){ times[cnt]=pos.Time(); profits[cnt]=pos.Profit()+pos.Swap(); cnt++; }
   }
   if(cnt<n) return false;   // itni trades hi nahi hain abhi — safe default: hold mat karo, normal flip hone do
   // recent-most-first selection sort (open time descending)
   for(int a=0;a<cnt-1;a++)
      for(int b=a+1;b<cnt;b++)
         if(times[b]>times[a])
         { datetime tt=times[a];times[a]=times[b];times[b]=tt; double pp=profits[a];profits[a]=profits[b];profits[b]=pp; }
   for(int k=0;k<n;k++) if(profits[k]<=0) return false;   // koi ek bhi loss mein → recovering nahi mana
   return true;
}

// v3.28: Progressive De-Risk (GetDeRiskMult) remove — lot ab hamesha lot table se full size.

// Broker ke lot-step/min ke hisaab se lot ko valid size pe round karta hai. Bahut chhota ho to 0.
double NormalizeLot(double lot)
{
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double minLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   if(step<=0) step=0.01;
   lot=MathFloor(lot/step+0.0000001)*step;
   if(lot<minLot-0.0000001) return 0;
   return NormalizeDouble(lot,2);
}

//+------------------------------------------------------------------+
//| v1.05: CTrade true return kar sakta hai jabki server ne order     |
//| execute hi nahi kiya — isliye broker ka retcode bhi check karo.   |
//+------------------------------------------------------------------+
bool TradeRequestAccepted(bool requestOK,string action)
{
   static datetime lastFailureLog=0;
   uint rc=trade.ResultRetcode();
   bool accepted=requestOK &&
      (rc==TRADE_RETCODE_DONE || rc==TRADE_RETCODE_DONE_PARTIAL ||
       rc==TRADE_RETCODE_PLACED || rc==TRADE_RETCODE_NO_CHANGES);
   if(!accepted && TimeCurrent()-lastFailureLog>=30)
   {
      Print("GridTrend ",action," FAILED: retcode ",IntegerToString((int)rc)," — ",trade.ResultRetcodeDescription());
      lastFailureLog=TimeCurrent();
   }
   return accepted;
}

// v1.05: close fail hone par pending flag (basket flat hone tak retry)
bool IsClosePending(int dir){ return (dir==1)?g_closePendB:g_closePendS; }
void SetClosePending(int dir,bool v){ if(dir==1) g_closePendB=v; else g_closePendS=v; }

// Har tick lifetime-highest drawdown % track karta hai (analytics ke liye)
void UpdateMaxDDEver()
{
   double dd=GetCurrentDD();
   if(dd>g_maxDDEver) g_maxDDEver=dd;
}

//+------------------------------------------------------------------+
//| v3.12: TOTAL DD — FIXED $ LIMIT (existing % system se parallel,   |
//| jo bhi pehle trigger ho). Balance-Equity ka floating loss $ mein  |
//+------------------------------------------------------------------+
double GetCurrentDD_Dollar()
{
   double bal=AccountInfoDouble(ACCOUNT_BALANCE);
   double eq =AccountInfoDouble(ACCOUNT_EQUITY);
   double dd=bal-eq;
   return (dd>0)?dd:0;
}

void CheckTotalDDLimit()
{
   // v1.05: LATCHED LOCKOUT — ek baar hit hua to EA lock. Pehle (v1.03) floating
   // recover hote hi trigger reset ho jaata tha aur agle H1 pe naya basket khul jaata tha.
   if(Enable_TotalDD_Limit && !g_totalDDTriggered)
   {
      double ddDollar=GetCurrentDD_Dollar();
      if(ddDollar>=Total_DD_Dollar_Limit)
      {
         g_totalDDTriggered=true;
         g_ddLockTime=TimeCurrent();
         // liquidate se pehle realized loss capture karo analytics ke liye
         double combinedPnL=GetNetPnL(1)+GetNetPnL(-1);
         double durHrs=0; datetime st=GetGlobalBasketStart();
         if(st>0) durHrs=(double)(TimeCurrent()-st)/3600.0;
         SendAlert("TOTAL DD LIMIT HIT! -$"+DoubleToString(ddDollar,2)+" >= $"+DoubleToString(Total_DD_Dollar_Limit,2)+
                   " — LIQUIDATING ALL + EA LOCKED (manual Reset_DD_Lockout tak koi naya trade nahi)");
         LogCycleResult("BOTH",combinedPnL,durHrs,"TOTAL_DD_LIMIT");
         SaveEAState();   // lock turant file mein — VPS restart pe bhi bana rahe
      }
   }
   // Lock laga hai → jab tak is EA ki sab positions band na ho jayein, har tick close try karo
   if(g_totalDDTriggered)
   {
      if(CountTrades(1)>0)  CloseAll(1);
      if(CountTrades(-1)>0) CloseAll(-1);
      if(CountTrades(1)==0 && CountTrades(-1)==0)
      {
         g_closePendB=false; g_closePendS=false;
         buyFrozen=false; sellFrozen=false;
      }
   }
}

//+------------------------------------------------------------------+
//| v3.09: PERFORMANCE ANALYTICS — cycle-close result log karta hai   |
//| (lifetime win/loss stats update + CSV file mein row likhta hai)   |
//+------------------------------------------------------------------+
void LogCycleResult(string dirLabel,double profit,double durationHrs,string reason)
{
   if(profit>=0){g_totalWins++; g_totalProfitSum+=profit;}
   else{g_totalLosses++; g_totalLossSum+=(-profit);}
   g_sumDurationHrs+=durationHrs;
   BrCycle(dirLabel,profit,durationHrs,reason);   // v1.03: app ke HISTORY tab ke liye
   int h=FileOpen(g_statsCsvFile,FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(h==INVALID_HANDLE) return;
   if(FileSize(h)==0) FileWrite(h,"DateTime,Direction,Reason,Profit,DurationHrs,Balance,Equity");
   FileSeek(h,0,SEEK_END);
   FileWrite(h,TimeToString(TimeCurrent(),TIME_DATE|TIME_MINUTES)+","+dirLabel+","+reason+","+
             DoubleToString(profit,2)+","+DoubleToString(durationHrs,2)+","+
             DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)+","+
             DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2));
   FileClose(h);
}

//+------------------------------------------------------------------+
//| TRADE COUNTING & EXTREME                                         |
//+------------------------------------------------------------------+
int CountTrades(int dir)
{
   int n=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol||pos.Magic()!=Magic_Number) continue;
      if(dir==1&&pos.PositionType()==POSITION_TYPE_BUY) n++;
      if(dir==-1&&pos.PositionType()==POSITION_TYPE_SELL) n++;
   }
   return n;
}

// Returns LOWEST BUY price or HIGHEST SELL price (adverse extreme)
double GetExtreme(int dir)
{
   double ext=(dir==1)?1e10:-1e10; bool ok=false;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol||pos.Magic()!=Magic_Number) continue;
      if(dir==1&&pos.PositionType()==POSITION_TYPE_BUY){ext=MathMin(ext,pos.PriceOpen());ok=true;}
      if(dir==-1&&pos.PositionType()==POSITION_TYPE_SELL){ext=MathMax(ext,pos.PriceOpen());ok=true;}
   }
   return ok?ext:0;
}

int GetMaxTrades()
{
   int mx=0;
   for(int i=0;i<45;i++){if(lotArr[i]>0)mx=i+1;else break;}
   return MathMin(mx,Max_Trades);
}

double GetNetPnL(int dir)
{
   double t=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol||pos.Magic()!=Magic_Number) continue;
      bool m=(dir==1&&pos.PositionType()==POSITION_TYPE_BUY)||(dir==-1&&pos.PositionType()==POSITION_TYPE_SELL);
      if(m) t+=pos.Profit()+pos.Swap();
   }
   return t;
}

//+------------------------------------------------------------------+
//| OPEN TRADE — Basket-average TP (grid trades)                    |
//+------------------------------------------------------------------+
void OpenTrade(int dir,double forceLot=0)
{
   if(g_totalDDTriggered) return;      // v1.05: DD lock — manual reset tak koi naya trade nahi
   if(IsClosePending(dir)) return;     // v1.05: is side ka close abhi pending hai — pehle flat ho
   if(TimeCurrent()-g_lastOpenTime<3) return;
   if(IsSpreadTooHigh()) return;
   if(IsSpikeBlocked()) return;   // v3.16: volatility spike cooldown
   if(Enable_TotalDD_Limit && GetCurrentDD_Dollar()>=Total_DD_Dollar_Limit) return;   // v3.12 — ab yehi single DD gate hai
   int idx=CountTrades(dir);
   if(IsWeekendBlock()&&idx==0) return;
   if(IsOutsideHours() && CountTrades(1)+CountTrades(-1)==0) return;   // 10K: 5 PM-7 AM naya cycle nahi
   if(IsNews()) return;
   int max=GetMaxTrades();
   if(idx>=max||idx>=45||lotArr[idx]<=0) return;
   // AUTO snapshot: combined basket ka pehla trade → baseline capture.
   // v3.04 FIX: BALANCE se (equity nahi) — pehle trade pe floating ~0 hota hai, par
   // balance-anchored rakhne se recovery-math हमेशा realized+floating ke saath consistent rehta hai.
   if(CountTrades(1)==0 && CountTrades(-1)==0)
      basketStartEquity=AccountInfoDouble(ACCOUNT_BALANCE);
   double pr=(dir==1)?SymbolInfoDouble(_Symbol,SYMBOL_ASK):SymbolInfoDouble(_Symbol,SYMBOL_BID);
   // v3.24: Trend-Change First Trade feature hata di gayi — ab sabhi grid trades hamesha
   // normal lotArr[idx] se khulte hain, TP hamesha basket-average se manage hota hai (tp=0).
   // v3.27: forceLot>0 ho (Stop&Reverse ka pehla trade) to us lot se khulega, warna normal lotArr[idx] se.
   double lot=(forceLot>0 && idx==0)?forceLot:lotArr[idx];
   double tp=0;
   string cm=Trade_Comment+"_"+(dir==1?"B":"S")+IntegerToString(idx+1);
   // v3.28: de-risk multiplier hata — lot seedha table se, sirf broker step pe normalize
   lot=NormalizeLot(lot);
   if(lot<=0) return;   // broker minimum se neeche — trade skip
   bool requestOK=(dir==1)?trade.Buy(lot,_Symbol,pr,0,tp,cm):trade.Sell(lot,_Symbol,pr,0,tp,cm);
   if(TradeRequestAccepted(requestOK,"OPEN"))   // v1.05: retcode check
   {
      g_lastOpenTime=TimeCurrent();
      // v1.03: app feed — sirf log, trading par koi asar nahi
      BrEventT("OPEN",(dir==1?"BUY":"SELL")+" L"+IntegerToString(idx+1)+"  "+DoubleToString(lot,2)+" lot @ "+
               DoubleToString(trade.ResultPrice()>0?trade.ResultPrice():pr,_Digits));
   }
}

//+------------------------------------------------------------------+
//| CLOSE ALL                                                        |
//+------------------------------------------------------------------+
bool CloseAll(int dir)
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol||pos.Magic()!=Magic_Number) continue;
      bool m=(dir==1&&pos.PositionType()==POSITION_TYPE_BUY)||(dir==-1&&pos.PositionType()==POSITION_TYPE_SELL);
      if(m) TradeRequestAccepted(trade.PositionClose(pos.Ticket()),"CLOSE");   // v1.05: retcode check
   }
   // v1.05: koi position bachi hai (broker ne close reject kiya) → state reset MAT karo,
   // pending flag lagao — RetryPendingCloses() har tick dobara try karega.
   if(CountTrades(dir)>0){ SetClosePending(dir,true); return false; }
   SetClosePending(dir,false);
   // Reset peak so old peak agle cycle mein leak na kare
   if(dir==1){buyActive=0;buyStartTime=0;buyPeak=-1e10;lastPartialClose_Buy=0;}
   else{sellActive=0;sellStartTime=0;sellPeak=-1e10;lastPartialClose_Sell=0;}
   // v1.01 FIX: band hui side ab "frozen" nahi — agla basket us side ka fresh hai
   if(g_ddFrozenDir==dir) g_ddFrozenDir=0;
   // v1.01 FIX: dono side flat → cycle close → flip counter + pause pakka reset
   if(CountTrades(1)==0 && CountTrades(-1)==0)
   { g_flipCount=0; g_ddFrozenDir=0; g_flipPauseUntil=0; g_lastFlipTime=0; }
   return true;
}

//+------------------------------------------------------------------+
//| v1.05: pehle kisi close mein fail hua tha → har tick dobara band   |
//| karo. Side flat hote hi (signal wahi ho to) normal Restart.        |
//+------------------------------------------------------------------+
void RetryPendingCloses()
{
   if(g_totalDDTriggered) return;   // lock khud CheckTotalDDLimit mein close karta hai
   for(int k=0;k<2;k++)
   {
      int dir=(k==0)?1:-1;
      if(!IsClosePending(dir)) continue;
      if(CloseAll(dir))
      {
         SendAlert("Pending close done — "+(dir==1?"BUY":"SELL")+" side ab flat");
         Restart(dir);
      }
   }
}

//+------------------------------------------------------------------+
//| TP CALCULATION                                                   |
//+------------------------------------------------------------------+
double GetTPTarget(int dir)
{
   int cnt=CountTrades(dir);
   if(cnt==0) return 1e10;
   return AvgTP_PerTrade*cnt;   // v3.29: fixed target, time-decay remove
}

double CalcPriceForTarget(int dir,double target)
{
   int cnt=CountTrades(dir);
   if(cnt==0) return 0;
   double tL=0,pnl=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol||pos.Magic()!=Magic_Number) continue;
      bool m=(dir==1&&pos.PositionType()==POSITION_TYPE_BUY)||(dir==-1&&pos.PositionType()==POSITION_TYPE_SELL);
      if(!m) continue;
      tL+=pos.Volume(); pnl+=pos.Profit()+pos.Swap();
   }
   if(tL<=0) return 0;
   double tSz=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tVl=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   if(tSz<=0||tVl<=0) return 0;
   double cur=(dir==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double dist=(target-pnl)/(tL*(tVl/tSz));
   return (dir==1)?NormalizeDouble(cur+dist,_Digits):NormalizeDouble(cur-dist,_Digits);
}

double CalcTP(int dir)
{
   double tgt=GetTPTarget(dir);
   if(tgt==-9999||tgt>=1e9) return 0;
   return CalcPriceForTarget(dir,tgt);
}

void CheckPartialClose(int dir)
{
   if(!Enable_PartialClose) return;
   // Global override active (dono side khuli) → winner ko chhota mat karo, global rescue karega
   if(Enable_GlobalBasket && BothSidesOpen()) return;
   int cnt=CountTrades(dir);
   if(cnt<PartialClose_Min_Trades) return;
   // Cooldown: pichhle partial close se itne sec na beete toh skip
   datetime lastPC=(dir==1)?lastPartialClose_Buy:lastPartialClose_Sell;
   if(lastPC>0 && (TimeCurrent()-lastPC)<PartialClose_Cooldown_Sec) return;
   double pnl=GetNetPnL(dir),tgt=GetTPTarget(dir);
   if(tgt<=0||tgt>=1e9) return;
   if(pnl<tgt*(PartialClose_Trigger_Pct/100.0)) return;
   // v3.26 FIX: pehle "oldest" trade close hoti thi — grid mein oldest aksar sabse WORST-positioned
   // (sabse zyada loss mein) hoti hai, isliye "profit lock" karte waqt asal mein loss crystallize ho
   // jaata tha. Ab isके bajaye us direction ki SABSE PROFITABLE (ya sabse kam loss wali) trade close
   // hoti hai — taaki genuinely profit lock ho, koi losing trade galti se close na ho.
   ulong bestT=0; double bestPnL=-1e18;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol||pos.Magic()!=Magic_Number) continue;
      bool m=(dir==1&&pos.PositionType()==POSITION_TYPE_BUY)||(dir==-1&&pos.PositionType()==POSITION_TYPE_SELL);
      if(!m) continue;
      double p=pos.Profit()+pos.Swap();
      if(bestT==0||p>bestPnL){bestT=pos.Ticket();bestPnL=p;}
   }
   // Timer sirf tab set ho jab close actually safal ho (fail pe retry block na ho)
   if(bestT>0 && TradeRequestAccepted(trade.PositionClose(bestT),"PARTIAL CLOSE"))
   {
      if(dir==1) lastPartialClose_Buy=TimeCurrent();
      else       lastPartialClose_Sell=TimeCurrent();
      SendAlert("Partial close "+(dir==1?"BUY":"SELL")+" — most profitable trade locked ($"+DoubleToString(bestPnL,2)+")");
   }
}

void DrawHLine(string name,double price,color clr)
{
   if(price<=0){if(ObjectFind(0,name)>=0)ObjectDelete(0,name);return;}
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_HLINE,0,0,0);
   ObjectSetDouble(0,name,OBJPROP_PRICE,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_DASH);
}

// UpdateTP: basket-average TP — skips only the Trend-Change trade's protected hard TP
void UpdateTP(int dir)
{
   if(CountTrades(dir)==0) return;
   double tp=CalcTP(dir);
   if(tp<=0) return;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol||pos.Magic()!=Magic_Number) continue;
      bool m=(dir==1&&pos.PositionType()==POSITION_TYPE_BUY)||(dir==-1&&pos.PositionType()==POSITION_TYPE_SELL);
      if(!m) continue;
      // v3.24: Trend-Change feature hata di gayi hai — ab sabhi trades hamesha basket-average TP se manage hote hain, koi exception nahi.
      // Spam guard: agar TP already basket-TP ke paas hai (~10 cents) to dobara modify mat karo
      if(MathAbs(pos.TakeProfit()-tp) < 0.10) continue;
      TradeRequestAccepted(trade.PositionModify(pos.Ticket(),pos.StopLoss(),tp),"TP MODIFY");
   }
}

//+------------------------------------------------------------------+
//| GRID MANAGEMENT — Standard one-direction (v2.90 logic)          |
//+------------------------------------------------------------------+
void ManageGrid(int dir)
{
   if(dir==1&&buyFrozen) return;
   if(dir==-1&&sellFrozen) return;
   int cnt=CountTrades(dir),max=GetMaxTrades();
   if(cnt==0||cnt>=max) return;
   double gap=gapArr[cnt-1];
   if(gap<=0) return;
   double ext=GetExtreme(dir);
   if(ext==0) return;
   double cur=(dir==1)?SymbolInfoDouble(_Symbol,SYMBOL_BID):SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double diff=(dir==1)?(ext-cur):(cur-ext);
   if(diff>=gap*GetATRMult()) OpenTrade(dir);
}

//+------------------------------------------------------------------+
//| HANDLE SIGNAL — Freeze/Unfreeze bug fixed                       |
//+------------------------------------------------------------------+
void HandleSignal(int sig)
{
   int bCnt=CountTrades(1),sCnt=CountTrades(-1);
   // S2: DD ki wajah se frozen side ko SuperTrend signal se dobara mat kholo —
   // pehle uska loss limit ke DD_Flip_Unfreeze_Frac hisse tak recover hona chahiye.
   if(Enable_DDFlip && g_ddFrozenDir==sig && CountTrades(sig)>0)
   {
      if(GetNetPnL(sig)<=-DD_Flip_Dollars*DD_Flip_Unfreeze_Frac)
      {
         Print("DD FLIP: ",(sig==1?"BUY":"SELL")," side abhi DD-frozen hai ($",
               DoubleToString(GetNetPnL(sig),2),") — signal ignore");
         return;
      }
      g_ddFrozenDir=0;   // recover ho gaya — normal signal handling
   }
   if(sig==1&&Enable_BuyGrid)
   {
      buyFrozen=false;                          // Reset frozen
      if(!sellFrozen&&sCnt>0) sellFrozen=true;  // Freeze SELL if active
      if(bCnt==0)
      {
         // v3.13: SELL side recover kar raha hai (last N trades profit mein) → naya BUY hold karo
         // v3.15: sirf tab lagu hoga jab SELL side kam se kam RecoveryHold_MinOppositeTrades deep ho
         if(Enable_RecoveryHold && sCnt>=RecoveryHold_MinOppositeTrades && LastNTradesProfitable(-1,RecoveryHold_LastN))
            Print("RECOVERY HOLD: SELL (",sCnt," trades deep) last ",RecoveryHold_LastN," profit mein — naya BUY entry paused is H1 bar tak");
         else
         { buyActive=1;buyStartTime=TimeCurrent();OpenTrade(1); }
      }
      else buyActive=1;
   }
   else if(sig==-1&&Enable_SellGrid)
   {
      sellFrozen=false;                         // Reset frozen
      if(!buyFrozen&&bCnt>0) buyFrozen=true;    // Freeze BUY if active
      if(sCnt==0)
      {
         // v3.13: BUY side recover kar raha hai (last N trades profit mein) → naya SELL hold karo
         // v3.15: sirf tab lagu hoga jab BUY side kam se kam RecoveryHold_MinOppositeTrades deep ho
         if(Enable_RecoveryHold && bCnt>=RecoveryHold_MinOppositeTrades && LastNTradesProfitable(1,RecoveryHold_LastN))
            Print("RECOVERY HOLD: BUY (",bCnt," trades deep) last ",RecoveryHold_LastN," profit mein — naya SELL entry paused is H1 bar tak");
         else
         { sellActive=1;sellStartTime=TimeCurrent();OpenTrade(-1); }
      }
      else sellActive=1;
   }
}

//+------------------------------------------------------------------+
//| GLOBAL BASKET TP — dono side ka combined exit (master override)  |
//+------------------------------------------------------------------+
bool BothSidesOpen(){ return (CountTrades(1)>0 && CountTrades(-1)>0); }

// Combined basket ka "start" = oldest abhi-open side ka start time
datetime GetGlobalBasketStart()
{
   datetime bs=buyStartTime, ss=sellStartTime;
   if(CountTrades(1)==0)  bs=0;
   if(CountTrades(-1)==0) ss=0;
   if(bs>0 && ss>0) return MathMin(bs,ss);
   if(bs>0) return bs;
   if(ss>0) return ss;
   return 0;
}

double GetGlobalTarget()
{
   double tgt=AccountInfoDouble(ACCOUNT_BALANCE)*(Global_Target_Pct/100.0);
   if(tgt<1.0) tgt=1.0;   // floor
   return tgt;
}

// v3.29: GetGlobalTargetEffective() remove — ab sirf GetGlobalTarget() (fixed % of balance) use hota hai.

void CheckGlobalBasket()
{
   if(!Enable_GlobalBasket) return;
   if(CountTrades(1)==0 && CountTrades(-1)==0) return;
   double eq  = AccountInfoDouble(ACCOUNT_EQUITY);
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   // v3.04 FIX: baseline hamesha BALANCE se — EQUITY se nahi.
   // Equity me floating loss ghusa hota hai → drawdown me capture karne pe fake-low baseline (v3.03 bug).
   if(basketStartEquity<=0) basketStartEquity=bal;
   // REALIZED-INCLUSIVE recovery = equity - baseline (banked TPs + floating dono)
   double recovery = eq - basketStartEquity;
   double liveFloat= GetNetPnL(1)+GetNetPnL(-1);   // abhi khuli trades ka ASLI floating P/L
   double tgt=GetGlobalTarget();   // v3.29: fixed target — koi time decay / force close nahi
   bool hit=false; string reason="";
   if(recovery>=tgt)
   {
      // v3.04 SANITY GUARD: recovery "profit" bol raha hai — confirm karo floating itna
      // negative na ho ki "profit" fake ho. Yehi ek check aaj wala -$1661 loss rok deta.
      // Guard OFF agar Mult<=0.
      double guardFloor = -Basket_FloatGuard_Mult*GetGlobalTarget();
      bool guardOK = (Basket_FloatGuard_Mult<=0.0) || (liveFloat >= guardFloor);
      if(guardOK)
         { hit=true; reason="target $"+DoubleToString(tgt,2)+" hit"; }
      else
      {
         static datetime lastWarn=0;
         if(TimeCurrent()-lastWarn>300)
         {
            Print("BLOCKED basket close — recovery $",DoubleToString(recovery,2),
                  " par floating $",DoubleToString(liveFloat,2),
                  " (guard floor ",DoubleToString(guardFloor,2),"). Baseline balance pe re-anchor.");
            lastWarn=TimeCurrent();
         }
         basketStartEquity=bal;   // baseline theek → recovery ab ≈ floating, fake close nahi
      }
   }
   if(hit)
   {
      double durHrs=(double)(TimeCurrent()-GetGlobalBasketStart())/3600.0;
      SendAlert("GLOBAL BASKET CLOSE: "+reason+" | recovery $"+DoubleToString(recovery,2)+" | floating $"+DoubleToString(liveFloat,2));
      bool okB=CloseAll(1), okS=CloseAll(-1);
      buyFrozen=false; sellFrozen=false;
      LogCycleResult("BOTH",recovery,durHrs,"GLOBAL_TARGET");
      basketStartEquity=0;   // next basket fresh capture karega
      // v1.05: restart sirf tab jab dono side sach mein flat ho; warna RetryPendingCloses sambhalega
      if(okB && okS && g_lastSig!=0) Restart(g_lastSig);
   }
}

//+------------------------------------------------------------------+
//| TP CHECK & RESTART                                               |
//+------------------------------------------------------------------+
void CheckTP(int dir)
{
   if(CountTrades(dir)==0) return;
   if(IsClosePending(dir)) return;   // v1.05: close already chal raha hai — dobara log/close nahi
   // Global override: dono side khuli ho toh per-direction exit skip — global decide karega
   if(Enable_GlobalBasket && BothSidesOpen()) return;
   double pnl=GetNetPnL(dir),tgt=GetTPTarget(dir);
   if(pnl>=tgt)
   {
      double durHrs=(double)(TimeCurrent()-((dir==1)?buyStartTime:sellStartTime))/3600.0;
      SendAlert("TP HIT");
      bool ok=CloseAll(dir);
      LogCycleResult(dir==1?"BUY":"SELL",pnl,durHrs,"TP_HIT");
      if(ok) Restart(dir);   // v1.05: fail hua to RetryPendingCloses flat hone ke baad restart karega
   }
}

//+------------------------------------------------------------------+
//| BASKET TRAILING — peak se pullback pe winner lock                |
//| buyPeak/sellPeak ab actually use ho rahe hain (pehle dead the)   |
//+------------------------------------------------------------------+
void CheckTrailing(int dir)
{
   if(!Enable_Trailing) return;
   // Global override active (dono side khuli) → trailing skip, peak reset taaki single-side pe fresh arm ho
   if(Enable_GlobalBasket && BothSidesOpen()){ if(dir==1) buyPeak=-1e10; else sellPeak=-1e10; return; }
   int cnt=CountTrades(dir);
   if(cnt==0){ if(dir==1) buyPeak=-1e10; else sellPeak=-1e10; return; }
   if(IsClosePending(dir)) return;   // v1.05: close already chal raha hai
   double pnl=GetNetPnL(dir);
   double peak=(dir==1)?buyPeak:sellPeak;
   if(pnl>peak){ peak=pnl; if(dir==1) buyPeak=peak; else sellPeak=peak; }
   if(peak<Trail_Activate) return;                 // abhi arm nahi hua
   if(pnl<=peak-Trail_Pullback)                    // pullback → lock-in
   {
      double durHrs=(double)(TimeCurrent()-((dir==1)?buyStartTime:sellStartTime))/3600.0;
      SendAlert("Trail lock "+(dir==1?"BUY":"SELL")+" @ $"+DoubleToString(pnl,2)+" (peak $"+DoubleToString(peak,2)+")");
      bool ok=CloseAll(dir);
      LogCycleResult(dir==1?"BUY":"SELL",pnl,durHrs,"TRAIL_LOCK");
      if(ok) Restart(dir);   // v1.05
   }
}

void Restart(int dir)
{
   if(g_lastSig!=dir) return;
   if(dir==1&&Enable_BuyGrid){buyActive=1;buyStartTime=TimeCurrent();OpenTrade(1);}
   else if(dir==-1&&Enable_SellGrid){sellActive=1;sellStartTime=TimeCurrent();OpenTrade(-1);}
}

void CheckProfitTarget()
{
   if(!Enable_ProfitReset) return;
   // FIX: equity - cycleStartBal = real account profit
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double pnl    = equity - cycleStartBal;
   if(pnl >= Total_Profit_Target)
   {
      cycleCount++;
      for(int i=2;i>=1;i--)
      {
         last3CloseTime[i]    = last3CloseTime[i-1];
         last3CloseProfit[i]  = last3CloseProfit[i-1];
         last3CloseDuration[i]= last3CloseDuration[i-1];
      }
      int dur=0;
      int bCnt=CountTrades(1),sCnt=CountTrades(-1);
      if(bCnt>0&&buyStartTime>0) dur=(int)(TimeCurrent()-buyStartTime)/3600;
      else if(sCnt>0&&sellStartTime>0) dur=(int)(TimeCurrent()-sellStartTime)/3600;
      last3CloseTime[0]    = TimeCurrent();
      last3CloseProfit[0]  = pnl;
      last3CloseDuration[0]= dur;
      SendAlert("Cycle #"+IntegerToString(cycleCount)+" done! $"+DoubleToString(pnl,2));
      bool okB=CloseAll(1), okS=CloseAll(-1);
      // Reset cycleStartBal for next cycle
      cycleStartBal = AccountInfoDouble(ACCOUNT_BALANCE);
      basketStartEquity = 0;   // naya basket fresh capture karega
      if(okB && okS && g_lastSig!=0) Restart(g_lastSig);   // v1.05: sirf flat hone ke baad
   }
}

void DailyReset()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   datetime today=TimeCurrent()-(long)(dt.hour*3600+dt.min*60+dt.sec);
   if(lastDayReset!=today) lastDayReset=today;
}

//+------------------------------------------------------------------+
//| STATE SAVE / LOAD                                                |
//+------------------------------------------------------------------+
void SaveEAState()
{
   int handle=FileOpen(g_stateFile,FILE_WRITE|FILE_BIN);
   if(handle==INVALID_HANDLE) return;
   FileWriteInteger(handle,STATE_VERSION);
   FileWriteDouble(handle,cycleStartBal);
   FileWriteDouble(handle,basketStartEquity);
   FileWriteDouble(handle,dailyStartBal);
   FileWriteInteger(handle,buyActive);
   FileWriteInteger(handle,sellActive);
   FileWriteLong(handle,(long)buyStartTime);
   FileWriteLong(handle,(long)sellStartTime);
   FileWriteDouble(handle,buyPeak);
   FileWriteDouble(handle,sellPeak);
   FileWriteInteger(handle,buyFrozen?1:0);
   FileWriteInteger(handle,sellFrozen?1:0);
   FileWriteInteger(handle,cycleCount);
   FileWriteLong(handle,(long)lastDayReset);
   FileWriteInteger(handle,g_lastSig);
   FileWriteInteger(handle,g_lastSTDir);
   FileWriteLong(handle,(long)g_lastOpenTime);
   FileWriteLong(handle,(long)g_lastH1);
   FileWriteLong(handle,(long)g_lastM1);
   FileWriteLong(handle,(long)lastNewsCheck);
   for(int i=0;i<3;i++)
   {
      FileWriteLong(handle,(long)last3CloseTime[i]);
      FileWriteDouble(handle,last3CloseProfit[i]);
      FileWriteInteger(handle,last3CloseDuration[i]);
   }
   for(int i=0;i<3;i++)
   {
      FileWriteLong(handle,(long)nextNewsTime[i]);
      FileWriteString(handle,nextNewsName[i]);
      FileWriteInteger(handle,nextNewsImpact[i]);
   }
   // v3.09: lifetime performance analytics
   FileWriteInteger(handle,g_totalWins);
   FileWriteInteger(handle,g_totalLosses);
   FileWriteDouble(handle,g_totalProfitSum);
   FileWriteDouble(handle,g_totalLossSum);
   FileWriteDouble(handle,g_sumDurationHrs);
   FileWriteDouble(handle,g_maxDDEver);
   // S2: flip state
   FileWriteInteger(handle,g_flipCount);
   FileWriteLong(handle,(long)g_lastFlipTime);
   FileWriteLong(handle,(long)g_flipPauseUntil);
   FileWriteInteger(handle,g_ddFrozenDir);
   // v1.05: DD lockout state
   FileWriteInteger(handle,g_totalDDTriggered?1:0);
   FileWriteLong(handle,(long)g_ddLockTime);
   FileWriteInteger(handle,g_resetInputPrev?1:0);
   FileClose(handle);
   g_lastStateSave=TimeCurrent();
}

void LoadEAState()
{
   if(!FileIsExist(g_stateFile)){cycleStartBal=AccountInfoDouble(ACCOUNT_BALANCE);dailyStartBal=cycleStartBal;return;}
   int handle=FileOpen(g_stateFile,FILE_READ|FILE_BIN);
   if(handle==INVALID_HANDLE){cycleStartBal=AccountInfoDouble(ACCOUNT_BALANCE);dailyStartBal=cycleStartBal;return;}
   int version=FileReadInteger(handle);
   if(version!=STATE_VERSION && version!=5){FileClose(handle);Print("State version mismatch — fresh start.");cycleStartBal=AccountInfoDouble(ACCOUNT_BALANCE);dailyStartBal=cycleStartBal;return;}
   cycleStartBal   =FileReadDouble(handle);
   basketStartEquity=FileReadDouble(handle);
   dailyStartBal   =FileReadDouble(handle);
   buyActive       =FileReadInteger(handle);
   sellActive      =FileReadInteger(handle);
   buyStartTime    =(datetime)FileReadLong(handle);
   sellStartTime   =(datetime)FileReadLong(handle);
   buyPeak         =FileReadDouble(handle);
   sellPeak        =FileReadDouble(handle);
   buyFrozen       =(FileReadInteger(handle)==1);
   sellFrozen      =(FileReadInteger(handle)==1);
   cycleCount      =FileReadInteger(handle);
   lastDayReset    =(datetime)FileReadLong(handle);
   g_lastSig       =FileReadInteger(handle);
   g_lastSTDir     =FileReadInteger(handle);
   g_lastOpenTime  =(datetime)FileReadLong(handle);
   g_lastH1        =(datetime)FileReadLong(handle);
   g_lastM1        =(datetime)FileReadLong(handle);
   lastNewsCheck   =(datetime)FileReadLong(handle);
   for(int i=0;i<3;i++)
   {
      last3CloseTime[i]    =(datetime)FileReadLong(handle);
      last3CloseProfit[i]  =FileReadDouble(handle);
      last3CloseDuration[i]=FileReadInteger(handle);
   }
   for(int i=0;i<3;i++)
   {
      nextNewsTime[i]  =(datetime)FileReadLong(handle);
      nextNewsName[i]  =FileReadString(handle);
      nextNewsImpact[i]=FileReadInteger(handle);
   }
   // v3.09: lifetime performance analytics
   g_totalWins      =FileReadInteger(handle);
   g_totalLosses    =FileReadInteger(handle);
   g_totalProfitSum =FileReadDouble(handle);
   g_totalLossSum   =FileReadDouble(handle);
   g_sumDurationHrs =FileReadDouble(handle);
   g_maxDDEver      =FileReadDouble(handle);
   // S2: flip state
   g_flipCount      =FileReadInteger(handle);
   g_lastFlipTime   =(datetime)FileReadLong(handle);
   g_flipPauseUntil =(datetime)FileReadLong(handle);
   g_ddFrozenDir    =FileReadInteger(handle);
   // v1.05: v5 (v1.03) file mein lock state nahi hoti → unlocked se shuru
   if(version>=6)
   {
      g_totalDDTriggered=(FileReadInteger(handle)==1);
      g_ddLockTime      =(datetime)FileReadLong(handle);
      g_resetInputPrev  =(FileReadInteger(handle)==1);
   }
   FileClose(handle);
   // Safety: peak ko current basket pnl pe re-seed karo (purana peak stale ho sakta hai)
   if(CountTrades(1)>0)  buyPeak=MathMax(buyPeak,GetNetPnL(1));  else buyPeak=-1e10;
   if(CountTrades(-1)>0) sellPeak=MathMax(sellPeak,GetNetPnL(-1)); else sellPeak=-1e10;
   // Mid-basket upgrade/restart: agar trades khule hain par baseline missing → BALANCE le lo.
   // v3.04 FIX: pehle EQUITY leta tha — drawdown me restart pe fake-low baseline banta tha (v3.03 bug).
   if((CountTrades(1)>0||CountTrades(-1)>0) && basketStartEquity<=0)
   {
      basketStartEquity=AccountInfoDouble(ACCOUNT_BALANCE);
      Print("Basket baseline missing — current BALANCE pe set: $",DoubleToString(basketStartEquity,2));
   }
}

//+------------------------------------------------------------------+
//| v1.03: GRID 2 MOBILE APP BRIDGE (Firebase Realtime DB, REST)     |
//| Sab kuch OnTimer se — OnTick mein sirf event QUEUE hota hai, koi |
//| network call nahi. Isliye trading speed/logic par koi asar nahi.  |
//|  /gt2/{acct}/live     = poora live snapshot (har Bridge_Push_Sec) |
//|  /gt2/{acct}/events   = alerts + trade opens (activity feed)      |
//|  /gt2/{acct}/cycles   = har basket close ka result                |
//+------------------------------------------------------------------+
#define  BR_VER  "1.05"
bool     g_brOn=false;
string   g_brQ[];            // /events ke liye pending JSON
string   g_brCycQ[];         // /cycles ke liye pending JSON
datetime g_brLastStats=0;
bool     g_brUrlWarned=false;
int      g_brFail=0;
double   g_brToday=0,g_brWeek=0,g_brMonth=0,g_brAll=0,g_brDep=0,g_brWd=0;
int      g_brTodayDeals=0,g_brAllDeals=0;
double   g_brDaily[30];
string   g_brDailyKey[30];

string BrNum(double v,int d=2){ return DoubleToString(v,d); }
string BrBool(bool b){ return b?"true":"false"; }
string BrStr(string s){ return "\""+JEsc(s)+"\""; }
long   BrEpoch(){ return (long)TimeGMT(); }
long   BrSrvToEpoch(datetime t){ if(t<=0) return 0; return (long)t-((long)TimeTradeServer()-(long)TimeGMT()); }
string BrNode(){ return Bridge_FB_URL+"/"+Bridge_Root+"/"+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)); }

string BrTypeOf(string m)
{
   if(StringFind(m,"TP HIT")==0)        return "TP";
   if(StringFind(m,"Trail lock")==0)    return "TRAIL";
   if(StringFind(m,"DD FLIP")==0)       return "FLIP";
   if(StringFind(m,"TOTAL DD")==0)      return "DDLIMIT";
   if(StringFind(m,"GLOBAL BASKET")==0) return "BASKET";
   if(StringFind(m,"Cycle #")==0)       return "CYCLE";
   if(StringFind(m,"VOLATILITY")==0)    return "SPIKE";
   if(StringFind(m,"Partial close")==0) return "PARTIAL";
   if(StringFind(m,"DEPOSIT")==0||StringFind(m,"WITHDRAWAL")==0) return "FUNDS";
   return "INFO";
}

void BrEventT(string type,string msg)
{
   if(!g_brOn) return;
   int n=ArraySize(g_brQ);
   if(n>=60) return;   // network down ho to queue max 60
   ArrayResize(g_brQ,n+1);
   g_brQ[n]="{\"t\":"+IntegerToString(BrEpoch())+",\"type\":\""+type+"\",\"msg\":"+BrStr(msg)+
            ",\"bal\":"+BrNum(AccountInfoDouble(ACCOUNT_BALANCE))+",\"eq\":"+BrNum(AccountInfoDouble(ACCOUNT_EQUITY))+"}";
}
void BrEvent(string msg){ BrEventT(BrTypeOf(msg),msg); }

void BrCycle(string dirLabel,double profit,double hrs,string reason)
{
   if(!g_brOn) return;
   int n=ArraySize(g_brCycQ);
   if(n>=30) return;
   ArrayResize(g_brCycQ,n+1);
   g_brCycQ[n]="{\"t\":"+IntegerToString(BrEpoch())+",\"dir\":\""+dirLabel+"\",\"reason\":\""+reason+
               "\",\"profit\":"+BrNum(profit)+",\"hrs\":"+BrNum(hrs,2)+
               ",\"bal\":"+BrNum(AccountInfoDouble(ACCOUNT_BALANCE))+"}";
}

// POST = naya child (events/cycles). PUT = overwrite (live). Firebase method-override header use hota hai.
int BrSend(string verb,string path,string body)
{
   char data[],res[]; string rh;
   int len=StringToCharArray(body,data,0,WHOLE_ARRAY,CP_UTF8);
   if(len>0) ArrayResize(data,len-1);   // trailing \0 hatao
   string hdr="Content-Type: application/json\r\n";
   if(verb!="POST") hdr+="X-HTTP-Method-Override: "+verb+"\r\n";
   ResetLastError();
   int code=WebRequest("POST",BrNode()+path,hdr,3000,data,res,rh);
   if(code==-1)
   {
      int err=GetLastError();
      if(err==4014 && !g_brUrlWarned)
      {
         g_brUrlWarned=true;
         Print("GRID2 BRIDGE: WebRequest BLOCKED — MT5 Tools > Options > Expert Advisors mein yeh URL add karo: ",Bridge_FB_URL);
      }
      g_brFail++;
   }
   else if(code!=200)
   {
      g_brFail++;
      if(g_brFail%30==1) Print("GRID2 BRIDGE: HTTP ",code," (",path,") ",CharArrayToString(res,0,WHOLE_ARRAY,CP_UTF8));
   }
   else g_brFail=0;
   return code;
}

// Account history se: today/week/month/all-time realized P&L (sirf is EA ki positions),
// deposits/withdrawals (opening balance ke liye) aur last 30 din ka daily P&L.
void BrCalcStats()
{
   datetime now=TimeCurrent();
   datetime dayStart=(datetime)((long)now-((long)now%86400));
   MqlDateTime d; TimeToStruct(now,d);
   int back=(d.day_of_week==0)?6:d.day_of_week-1;
   datetime weekStart=dayStart-back*86400;
   datetime monthStart=dayStart-(d.day-1)*86400;
   for(int i=0;i<30;i++)
   {
      g_brDaily[i]=0;
      MqlDateTime kd; TimeToStruct(dayStart-(29-i)*86400,kd);
      g_brDailyKey[i]=(kd.day<10?"0":"")+IntegerToString(kd.day)+"/"+(kd.mon<10?"0":"")+IntegerToString(kd.mon);
   }
   if(!HistorySelect(0,now+3600)) return;
   int tot=HistoryDealsTotal();
   // pass 1: is EA ki positions ke IDs (manual close ka OUT deal magic 0 hota hai, isliye position-id se match)
   long ids[]; int nid=0;
   for(int i=0;i<tot;i++)
   {
      ulong tk=HistoryDealGetTicket(i); if(tk==0) continue;
      if(HistoryDealGetInteger(tk,DEAL_MAGIC)!=Magic_Number) continue;
      if(HistoryDealGetString(tk,DEAL_SYMBOL)!=_Symbol) continue;
      if(HistoryDealGetInteger(tk,DEAL_ENTRY)!=DEAL_ENTRY_IN) continue;
      ArrayResize(ids,nid+1,256); ids[nid++]=HistoryDealGetInteger(tk,DEAL_POSITION_ID);
   }
   if(nid>1) ArraySort(ids);
   double td=0,wk=0,mo=0,al=0,dep=0,wd=0; int tdN=0,alN=0;
   for(int i=0;i<tot;i++)
   {
      ulong tk=HistoryDealGetTicket(i); if(tk==0) continue;
      long typ=HistoryDealGetInteger(tk,DEAL_TYPE);
      double p=HistoryDealGetDouble(tk,DEAL_PROFIT);
      if(typ==DEAL_TYPE_BALANCE){ if(p>=0) dep+=p; else wd+=-p; continue; }
      if(typ!=DEAL_TYPE_BUY && typ!=DEAL_TYPE_SELL) continue;
      if(nid==0) continue;
      long pid=HistoryDealGetInteger(tk,DEAL_POSITION_ID);
      int at=ArrayBsearch(ids,pid);
      if(at<0||at>=nid||ids[at]!=pid) continue;
      double net=p+HistoryDealGetDouble(tk,DEAL_SWAP)+HistoryDealGetDouble(tk,DEAL_COMMISSION);
      datetime t=(datetime)HistoryDealGetInteger(tk,DEAL_TIME);
      long ent=HistoryDealGetInteger(tk,DEAL_ENTRY);
      bool isOut=(ent==DEAL_ENTRY_OUT||ent==DEAL_ENTRY_INOUT||ent==DEAL_ENTRY_OUT_BY);
      al+=net; if(isOut) alN++;
      if(t>=monthStart) mo+=net;
      if(t>=weekStart)  wk+=net;
      if(t>=dayStart){ td+=net; if(isOut) tdN++; }
      long tDay=(long)t-((long)t%86400);
      int idx=29-(int)(((long)dayStart-tDay)/86400);
      if(idx>=0&&idx<30) g_brDaily[idx]+=net;
   }
   g_brToday=td; g_brWeek=wk; g_brMonth=mo; g_brAll=al; g_brDep=dep; g_brWd=wd;
   g_brTodayDeals=tdN; g_brAllDeals=alN;
}

string BrSide(int dir)
{
   int n=0; double lots=0,wsum=0,pnl=0; datetime first=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol||pos.Magic()!=Magic_Number) continue;
      bool m=(dir==1&&pos.PositionType()==POSITION_TYPE_BUY)||(dir==-1&&pos.PositionType()==POSITION_TYPE_SELL);
      if(!m) continue;
      n++; lots+=pos.Volume(); wsum+=pos.Volume()*pos.PriceOpen(); pnl+=pos.Profit()+pos.Swap();
      if(first==0||pos.Time()<first) first=pos.Time();
   }
   double avg=(lots>0)?wsum/lots:0;
   double tp=(n>0)?CalcTP(dir):0;
   double tgt=(n>0)?GetTPTarget(dir):0;
   int mx=GetMaxTrades();
   double nextPx=0,nextLot=0,nextGap=0;
   if(n>0 && n<mx)
   {
      nextGap=gapArr[n-1]*GetATRMult();
      double ext=GetExtreme(dir);
      if(gapArr[n-1]>0 && ext>0) nextPx=(dir==1)?ext-nextGap:ext+nextGap;
      nextLot=lotArr[n];
   }
   else if(n==0) nextLot=lotArr[0];
   bool frz=(dir==1)?buyFrozen:sellFrozen;
   int  act=(dir==1)?buyActive:sellActive;
   double peak=(dir==1)?buyPeak:sellPeak; if(peak<-1e9) peak=0;
   bool armed=(Enable_Trailing && n>0 && peak>=Trail_Activate);
   bool on=(dir==1)?Enable_BuyGrid:Enable_SellGrid;
   string s="{";
   s+="\"n\":"+IntegerToString(n)+",\"lots\":"+BrNum(lots)+",\"avg\":"+BrNum(avg,_Digits)+",\"pnl\":"+BrNum(pnl);
   s+=",\"tp\":"+BrNum(tp,_Digits)+",\"target\":"+BrNum(tgt)+",\"frozen\":"+BrBool(frz && n>0)+",\"active\":"+BrBool(act==1);
   s+=",\"ddFrozen\":"+BrBool(g_ddFrozenDir==dir)+",\"on\":"+BrBool(on);
   s+=",\"peak\":"+BrNum(peak)+",\"trailArmed\":"+BrBool(armed);
   s+=",\"nextPx\":"+BrNum(nextPx,_Digits)+",\"nextLot\":"+BrNum(nextLot)+",\"nextGap\":"+BrNum(nextGap);
   s+=",\"start\":"+IntegerToString(BrSrvToEpoch(first))+",\"max\":"+IntegerToString(mx);
   s+="}";
   return s;
}

string BrStatus()
{
   int b=CountTrades(1),s=CountTrades(-1);
   if(g_totalDDTriggered)  return "DD LOCKED - MANUAL RESET";   // v1.05
   if(Enable_TotalDD_Limit && GetCurrentDD_Dollar()>=Total_DD_Dollar_Limit) return "DD LIMIT HIT";
   if(IsWeekendBlock() && b+s==0) return "WEEKEND BLOCK";
   if(IsOutsideHours() && b+s==0) return "OUTSIDE HOURS";   // 10K
   if(IsNews())            return "NEWS BLOCK";
   if(IsSpikeBlocked())    return "SPIKE BLOCK";
   if(IsSpreadTooHigh())   return "SPREAD HIGH";
   if(g_flipPauseUntil>TimeCurrent()) return "FLIP PAUSE";
   if(b+s>0)               return "RUNNING";
   if(g_lastSig==0)        return "LOADING SIGNAL";
   return "WAITING ENTRY";
}

string BrLiveJSON()
{
   double bal=AccountInfoDouble(ACCOUNT_BALANCE), eq=AccountInfoDouble(ACCOUNT_EQUITY);
   double netDep=g_brDep-g_brWd;
   double opening=(Bridge_Opening_Balance>0)?Bridge_Opening_Balance:((netDep>0)?netDep:cycleStartBal);
   int bCnt=CountTrades(1), sCnt=CountTrades(-1);
   string j="{";
   j+="\"ver\":\""+BR_VER+"\",\"ea\":\"GridTrend S2 v1.03\",\"ts\":"+IntegerToString(BrEpoch());
   j+=",\"acct\":"+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   j+=",\"name\":"+BrStr(AccountInfoString(ACCOUNT_NAME))+",\"server\":"+BrStr(AccountInfoString(ACCOUNT_SERVER));
   j+=",\"company\":"+BrStr(AccountInfoString(ACCOUNT_COMPANY))+",\"cur\":"+BrStr(AccountInfoString(ACCOUNT_CURRENCY));
   j+=",\"lev\":"+IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE));
   j+=",\"demo\":"+BrBool(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_DEMO);
   j+=",\"sym\":"+BrStr(_Symbol)+",\"digits\":"+IntegerToString(_Digits);
   j+=",\"bid\":"+BrNum(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits)+",\"ask\":"+BrNum(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   j+=",\"spread\":"+IntegerToString(GetCurrentSpread())+",\"maxSpread\":"+BrNum(Max_Spread_Points,0);
   j+=",\"status\":\""+BrStatus()+"\"";
   // ---- account ----
   j+=",\"bal\":"+BrNum(bal)+",\"eq\":"+BrNum(eq)+",\"margin\":"+BrNum(AccountInfoDouble(ACCOUNT_MARGIN));
   j+=",\"freeMargin\":"+BrNum(AccountInfoDouble(ACCOUNT_MARGIN_FREE))+",\"marginLevel\":"+BrNum(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),1);
   j+=",\"floating\":"+BrNum(GetNetPnL(1)+GetNetPnL(-1));
   j+=",\"opening\":"+BrNum(opening)+",\"openingAuto\":"+BrBool(Bridge_Opening_Balance<=0);
   j+=",\"deposits\":"+BrNum(g_brDep)+",\"withdrawals\":"+BrNum(g_brWd);
   j+=",\"pl\":{\"today\":"+BrNum(g_brToday)+",\"week\":"+BrNum(g_brWeek)+",\"month\":"+BrNum(g_brMonth)+",\"all\":"+BrNum(g_brAll);
   j+=",\"todayDeals\":"+IntegerToString(g_brTodayDeals)+",\"allDeals\":"+IntegerToString(g_brAllDeals)+"}";
   j+=",\"daily\":[";
   for(int i=0;i<30;i++){ if(i>0) j+=","; j+="{\"d\":\""+g_brDailyKey[i]+"\",\"p\":"+BrNum(g_brDaily[i])+"}"; }
   j+="]";
   // ---- cycle / profit target ----
   j+=",\"cycle\":{\"startBal\":"+BrNum(cycleStartBal)+",\"profit\":"+BrNum(eq-cycleStartBal)+",\"target\":"+BrNum(Total_Profit_Target)+
      ",\"on\":"+BrBool(Enable_ProfitReset)+",\"count\":"+IntegerToString(cycleCount)+"}";
   // ---- signal ----
   j+=",\"sig\":{\"sig\":"+IntegerToString(g_lastSig)+",\"st\":"+IntegerToString(g_lastSTDir)+",\"pend\":"+IntegerToString(g_pendingSig)+
      ",\"pendN\":"+IntegerToString(g_pendingCount)+",\"confirmOn\":"+BrBool(Enable_SignalConfirm)+",\"confirmBars\":"+IntegerToString(Signal_Confirm_Bars)+
      ",\"tf\":\""+StringSubstr(EnumToString(Filter_TF),7)+"\",\"stPeriod\":"+IntegerToString(ST_Period)+",\"stMult\":"+BrNum(ST_Multiplier,1)+"}";
   // ---- sides ----
   j+=",\"buy\":"+BrSide(1)+",\"sell\":"+BrSide(-1);
   // ---- flip ----
   long pauseLeft=(g_flipPauseUntil>TimeCurrent())?(long)(g_flipPauseUntil-TimeCurrent()):0;
   long cdLeft=0; if(g_lastFlipTime>0){ cdLeft=(long)(g_lastFlipTime+DD_Flip_Cooldown_Min*60-TimeCurrent()); if(cdLeft<0) cdLeft=0; }
   j+=",\"flip\":{\"on\":"+BrBool(Enable_DDFlip)+",\"count\":"+IntegerToString(g_flipCount)+",\"max\":"+IntegerToString(DD_Flip_Max_Per_Cycle)+
      ",\"limit\":"+BrNum(DD_Flip_Dollars,0)+",\"frozenDir\":"+IntegerToString(g_ddFrozenDir)+",\"pauseLeft\":"+IntegerToString(pauseLeft)+
      ",\"cdLeft\":"+IntegerToString(cdLeft)+",\"unfreeze\":"+BrNum(DD_Flip_Unfreeze_Frac,2)+",\"pauseHrs\":"+IntegerToString(DD_Flip_Pause_Hrs)+
      ",\"cdMin\":"+IntegerToString(DD_Flip_Cooldown_Min)+",\"last\":"+IntegerToString(BrSrvToEpoch(g_lastFlipTime))+"}";
   // ---- drawdown ----
   j+=",\"dd\":{\"pct\":"+BrNum(GetCurrentDD())+",\"usd\":"+BrNum(GetCurrentDD_Dollar())+",\"limit\":"+BrNum(Total_DD_Dollar_Limit,0)+
      ",\"on\":"+BrBool(Enable_TotalDD_Limit)+",\"locked\":"+BrBool(g_totalDDTriggered)+",\"maxEver\":"+BrNum(g_maxDDEver)+"}";
   // ---- global basket ----
   double gbBase=(basketStartEquity>0)?basketStartEquity:eq;
   datetime bkSt=GetGlobalBasketStart();
   j+=",\"basket\":{\"on\":"+BrBool(Enable_GlobalBasket)+",\"rec\":"+BrNum((bCnt+sCnt>0)?eq-gbBase:0)+",\"target\":"+BrNum(GetGlobalTarget())+
      ",\"startEq\":"+BrNum(basketStartEquity)+",\"ageH\":"+BrNum((bkSt>0)?(double)(TimeCurrent()-bkSt)/3600.0:0,1)+
      ",\"managing\":"+BrBool(bCnt>0&&sCnt>0)+",\"guard\":"+BrNum(Basket_FloatGuard_Mult,1)+",\"pct\":"+BrNum(Global_Target_Pct,2)+"}";
   // ---- filters ----
   long spLeft=(long)(g_spikeBlockUntil-TimeCurrent()); if(spLeft<0) spLeft=0;
   j+=",\"filt\":{\"news\":"+BrBool(IsNews())+",\"newsOn\":"+BrBool(Enable_News)+",\"wkd\":"+BrBool(IsWeekendBlock())+",\"wkdOn\":"+BrBool(Enable_WeekendBlock)+
      ",\"spike\":"+BrBool(IsSpikeBlocked())+",\"spikeLeft\":"+IntegerToString(spLeft)+",\"spikeOn\":"+BrBool(Enable_SpikeFilter)+
      ",\"spreadHigh\":"+BrBool(IsSpreadTooHigh())+",\"spreadOn\":"+BrBool(Enable_SpreadFilter)+
      ",\"atr\":"+BrNum(GetATRMult())+",\"atrOn\":"+BrBool(Enable_ATR)+"}";
   j+=",\"newsList\":[";
   bool f1=true;
   for(int i=0;i<3;i++)
   {
      if(nextNewsTime[i]<=0) continue;
      if(!f1) j+=","; f1=false;
      j+="{\"t\":"+IntegerToString(BrSrvToEpoch(nextNewsTime[i]))+",\"imp\":"+IntegerToString(nextNewsImpact[i])+",\"name\":"+BrStr(nextNewsName[i])+"}";
   }
   j+="]";
   // ---- performance ----
   int totC=g_totalWins+g_totalLosses;
   double wr=(totC>0)?(double)g_totalWins/totC*100.0:0;
   double aW=(g_totalWins>0)?g_totalProfitSum/g_totalWins:0, aL=(g_totalLosses>0)?g_totalLossSum/g_totalLosses:0;
   j+=",\"perf\":{\"wins\":"+IntegerToString(g_totalWins)+",\"losses\":"+IntegerToString(g_totalLosses)+",\"wr\":"+BrNum(wr,1)+
      ",\"exp\":"+BrNum((wr/100.0*aW)-((1-wr/100.0)*aL))+",\"avgWin\":"+BrNum(aW)+",\"avgLoss\":"+BrNum(aL)+
      ",\"avgRec\":"+BrNum((totC>0)?g_sumDurationHrs/totC:0,1)+",\"profitSum\":"+BrNum(g_totalProfitSum)+",\"lossSum\":"+BrNum(g_totalLossSum)+"}";
   j+=",\"last3\":[";
   bool f2=true;
   for(int i=0;i<3;i++)
   {
      if(last3CloseTime[i]<=0) continue;
      if(!f2) j+=","; f2=false;
      j+="{\"t\":"+IntegerToString(BrSrvToEpoch(last3CloseTime[i]))+",\"p\":"+BrNum(last3CloseProfit[i])+",\"h\":"+IntegerToString(last3CloseDuration[i])+"}";
   }
   j+="]";
   // ---- open positions ----
   j+=",\"pos\":[";
   bool f3=true;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol||pos.Magic()!=Magic_Number) continue;
      if(!f3) j+=","; f3=false;
      j+="{\"tk\":"+IntegerToString((long)pos.Ticket())+",\"d\":"+(pos.PositionType()==POSITION_TYPE_BUY?"1":"-1")+
         ",\"lot\":"+BrNum(pos.Volume())+",\"op\":"+BrNum(pos.PriceOpen(),_Digits)+",\"tp\":"+BrNum(pos.TakeProfit(),_Digits)+
         ",\"pl\":"+BrNum(pos.Profit()+pos.Swap())+",\"sw\":"+BrNum(pos.Swap())+",\"c\":"+BrStr(pos.Comment())+
         ",\"t\":"+IntegerToString(BrSrvToEpoch(pos.Time()))+"}";
   }
   j+="]";
   // ---- settings (inputs) ----
   j+=",\"cfg\":{\"magic\":"+IntegerToString(Magic_Number)+",\"maxTrades\":"+IntegerToString(Max_Trades)+",\"avgTP\":"+BrNum(AvgTP_PerTrade,1)+
      ",\"trailOn\":"+BrBool(Enable_Trailing)+",\"trailAct\":"+BrNum(Trail_Activate,0)+",\"trailPull\":"+BrNum(Trail_Pullback,0)+
      ",\"partialOn\":"+BrBool(Enable_PartialClose)+",\"partialPct\":"+BrNum(PartialClose_Trigger_Pct,0)+",\"partialMin\":"+IntegerToString(PartialClose_Min_Trades)+
      ",\"recHoldOn\":"+BrBool(Enable_RecoveryHold)+",\"recHoldN\":"+IntegerToString(RecoveryHold_LastN)+",\"recHoldMin\":"+IntegerToString(RecoveryHold_MinOppositeTrades)+
      ",\"newsBefore\":"+IntegerToString(News_Before)+",\"newsAfter\":"+IntegerToString(News_After)+",\"newsHigh\":"+BrBool(News_High)+",\"newsMed\":"+BrBool(News_Medium)+
      ",\"spikeMove\":"+BrNum(Spike_Move_Dollars,0)+",\"spikeWin\":"+IntegerToString(Spike_Window_Min)+",\"spikeBlock\":"+IntegerToString(Spike_Block_Min)+
      ",\"friStop\":"+IntegerToString(Friday_Stop_Hour)+",\"monStart\":"+IntegerToString(Monday_Start_Hour)+
      ",\"atrMax\":"+BrNum(ATR_Max_Mult,1)+",\"buyGrid\":"+BrBool(Enable_BuyGrid)+",\"sellGrid\":"+BrBool(Enable_SellGrid)+
      ",\"push\":"+BrBool(Enable_PushNotify)+",\"pushSec\":"+IntegerToString(Bridge_Push_Sec);
   int mx=GetMaxTrades();
   j+=",\"gaps\":[";
   for(int i=0;i<mx&&i<44;i++){ if(i>0) j+=","; j+=BrNum(gapArr[i],1); }
   j+="],\"lots\":[";
   for(int i=0;i<mx&&i<45;i++){ if(i>0) j+=","; j+=BrNum(lotArr[i]); }
   j+="]}";
   j+="}";
   return j;
}

void OnTimer()
{
   if(!g_brOn) return;
   if(g_brLastStats==0 || TimeLocal()-g_brLastStats>=60){ BrCalcStats(); g_brLastStats=TimeLocal(); }
   BrSend("PUT","/live.json",BrLiveJSON());
   int sent=0;
   while(ArraySize(g_brQ)>0 && sent<10)
   {
      if(BrSend("POST","/events.json",g_brQ[0])!=200) break;
      ArrayRemove(g_brQ,0,1); sent++;
   }
   while(ArraySize(g_brCycQ)>0 && sent<15)
   {
      if(BrSend("POST","/cycles.json",g_brCycQ[0])!=200) break;
      ArrayRemove(g_brCycQ,0,1); sent++;
   }
}

//+------------------------------------------------------------------+
//| EA LIFECYCLE                                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   // DESKTOP FIX: dashboard scale (DPI) + candles ko dashboard ke peeche bhejo
   if(Dashboard_Scale>0) g_dbScale=Dashboard_Scale;
   else
   {
      int dpi=TerminalInfoInteger(TERMINAL_SCREEN_DPI);
      g_dbScale=(dpi>0)?dpi/96.0:1.0;
   }
   if(g_dbScale<0.75) g_dbScale=0.75;
   if(g_dbScale>3.0)  g_dbScale=3.0;
   ChartSetInteger(0,CHART_FOREGROUND,false);   // "Chart on foreground" OFF — warna candles panel ke upar aati hain
   // v3.25: har symbol (chart) ki apni alag state/log/JSON file — sabse pehle set karo
   g_stateFile        = STATE_FILE_BASE+"_"+_Symbol+".dat";
   g_statsCsvFile     = STATS_CSV_FILE_BASE+"_"+_Symbol+".csv";
   g_dashboardJsonFile= DASHBOARD_EXPORT_FILE_BASE+"_"+_Symbol+".json";
   // v3.21: ACCOUNT LOCK — kuch bhi initialize hone se pehle.
   // Agar Allowed_Account_Number set hai (0 nahi) aur current account match nahi karta,
   // EA turant fail ho jaata hai — koi indicator, koi state-load, kuch bhi nahi chalta.
   if(Allowed_Account_Number!=0)
   {
      long curAcc=AccountInfoInteger(ACCOUNT_LOGIN);
      if(curAcc!=Allowed_Account_Number)
      {
         Print("❌ ACCOUNT LOCK: Yeh EA sirf account #",Allowed_Account_Number," ke liye licensed hai. ",
               "Yeh chart account #",curAcc," pe hai — MISMATCH. EA start nahi hoga.");
         Alert("GridTrend EA LOCKED: wrong account #"+IntegerToString(curAcc)+" (allowed: #"+IntegerToString(Allowed_Account_Number)+")");
         return INIT_FAILED;
      }
      Print("✅ ACCOUNT LOCK: Account #",curAcc," verified — EA proceed kar raha hai.");
   }
   trade.SetExpertMagicNumber(Magic_Number);
   trade.SetDeviationInPoints(Slippage*10);
   double g[]={Gap_01,Gap_02,Gap_03,Gap_04,Gap_05,Gap_06,Gap_07,Gap_08,Gap_09,Gap_10,Gap_11,Gap_12,Gap_13,Gap_14,Gap_15,Gap_16,Gap_17,Gap_18,Gap_19,Gap_20,Gap_21,Gap_22,Gap_23,Gap_24,Gap_25,Gap_26,Gap_27,Gap_28,Gap_29,Gap_30,Gap_31,Gap_32,Gap_33,Gap_34,Gap_35,Gap_36,Gap_37,Gap_38,Gap_39,Gap_40,Gap_41,Gap_42,Gap_43,Gap_44};
   ArrayCopy(gapArr,g);
   double l[]={Lot_01,Lot_02,Lot_03,Lot_04,Lot_05,Lot_06,Lot_07,Lot_08,Lot_09,Lot_10,Lot_11,Lot_12,Lot_13,Lot_14,Lot_15,Lot_16,Lot_17,Lot_18,Lot_19,Lot_20,Lot_21,Lot_22,Lot_23,Lot_24,Lot_25,Lot_26,Lot_27,Lot_28,Lot_29,Lot_30,Lot_31,Lot_32,Lot_33,Lot_34,Lot_35,Lot_36,Lot_37,Lot_38,Lot_39,Lot_40,Lot_41,Lot_42,Lot_43,Lot_44,Lot_45};
   ArrayCopy(lotArr,l);
   atrHandle=iATR(_Symbol,Filter_TF,ST_Period);
   if(atrHandle==INVALID_HANDLE) return INIT_FAILED;
   g_lastH1=iTime(_Symbol,Filter_TF,0);
   g_lastM1=iTime(_Symbol,PERIOD_M1,0);
   LoadEAState();
   // v1.05: DD LOCKOUT manual reset — ONE-SHOT. Sirf tab chalega jab input FALSE se TRUE hua ho
   // (pichli baar false tha). TRUE pe chhoda to agla lock VPS restart pe apne aap nahi khulega.
   if(Reset_DD_Lockout && !g_resetInputPrev)
   {
      if(!g_totalDDTriggered)
         Print("Reset_DD_Lockout: koi lock active nahi hai — kuch nahi kiya. Input wapas FALSE kar do.");
      else if(CountTrades(1)==0 && CountTrades(-1)==0)
      {
         g_totalDDTriggered=false; g_ddLockTime=0;
         g_closePendB=false; g_closePendS=false;
         cycleStartBal=AccountInfoDouble(ACCOUNT_BALANCE);   // naya cycle current balance se
         dailyStartBal=cycleStartBal;
         basketStartEquity=0;
         buyFrozen=false; sellFrozen=false;
         Print("DD LOCK RESET — EA phir se chalu. Ab Reset_DD_Lockout ko wapas FALSE kar do.");
         SendAlert("DD lock manually reset — trading phir chalu, naya cycle balance $"+DoubleToString(cycleStartBal,2));
      }
      else
      {
         Print("DD LOCK RESET REFUSED — pehle is EA ki sab positions band honi chahiye. Input FALSE karke dobara try karo.");
      }
   }
   else if(Reset_DD_Lockout && g_totalDDTriggered)
      Print("DD LOCKED: Reset_DD_Lockout pehle se TRUE hai — reset ke liye pehle FALSE, phir TRUE karo.");
   g_resetInputPrev=Reset_DD_Lockout;
   SaveEAState();
   if(g_totalDDTriggered)
      Print("⚠ EA DD-LOCKED hai (",TimeToString(g_ddLockTime),") — koi naya trade nahi khulega jab tak manual reset na ho.");
   // One-time baseline reset (input TRUE): profit/basket baseline ko aaj ke balance pe set karo
   if(Reset_Cycle_Baseline)
   {
      cycleStartBal     = AccountInfoDouble(ACCOUNT_BALANCE);
      dailyStartBal     = cycleStartBal;
      // v3.04 FIX: reset ke waqt agar basket khula ho to 0 mat karo.
      // 0 = agle tick pe recapture, aur v3.03 me wo EQUITY se hota tha = drawdown pe fake-low baseline = aaj wala bug.
      // Ab khula basket ho to seedha BALANCE pe anchor karo.
      basketStartEquity = (CountTrades(1)>0||CountTrades(-1)>0) ? AccountInfoDouble(ACCOUNT_BALANCE) : 0;
      SaveEAState();
      Print("Baseline RESET to current balance: $",DoubleToString(cycleStartBal,2),"  (ab is input ko wapas false kar do)");
   }
   BuildDB();
   BuildHistoryPanel();
   BuildNewsPanel();
   Print("═══════════════════════════════════════");
   Print("GridTrend S2 v1.05 — READY (dashboard scale ",DoubleToString(g_dbScale,2),"x)");
   Print("Spike Filter   : ", Enable_SpikeFilter?("ON  $"+DoubleToString(Spike_Move_Dollars,0)+"/"+IntegerToString(Spike_Window_Min)+"min -> block "+IntegerToString(Spike_Block_Min)+"min"):"OFF");
   Print("Recovery Hold  : ", Enable_RecoveryHold?("ON  min "+IntegerToString(RecoveryHold_MinOppositeTrades)+" trades deep, last "+IntegerToString(RecoveryHold_LastN)+" all-profit check"):"OFF");
   Print("Total DD $     : ", Enable_TotalDD_Limit?("ON  liquidate + LOCK at -$"+DoubleToString(Total_DD_Dollar_Limit,0)):"OFF",g_totalDDTriggered?"  [LOCKED NOW]":"");
   Print("% DD System    : REMOVED (v3.28) — no staged DD, no de-risk taper");
   Print("Fallback       : REMOVED — fixed target, no time-based close");
   Print("DD Flip        : ", Enable_DDFlip?("ON  per-side -$"+DoubleToString(DD_Flip_Dollars,0)+
         " | max "+IntegerToString(DD_Flip_Max_Per_Cycle)+"/cycle | cooldown "+
         IntegerToString(DD_Flip_Cooldown_Min)+"min"):"OFF");
   Print("Trailing       : ", Enable_Trailing?("ON  arm $"+DoubleToString(Trail_Activate,0)+" / pull $"+DoubleToString(Trail_Pullback,0)):"OFF");
   Print("Sig Confirm    : ", Enable_SignalConfirm?(IntegerToString(Signal_Confirm_Bars)+" bars"):"OFF (instant flip)");
   Print("Global Basket  : ", Enable_GlobalBasket?("ON  "+DoubleToString(Global_Target_Pct,2)+"% of bal | fixed target | BALANCE-anchored"):"OFF");
   Print("Float Guard    : ", (Basket_FloatGuard_Mult>0)?("ON  block close if floating < -"+DoubleToString(Basket_FloatGuard_Mult,1)+"x target"):"OFF");
   Print("═══════════════════════════════════════");
   // v3.11: basket-TP hamesha ON hai (Individual TP option remove ho gaya) — agar trades already khule hain
   // (upgrade/restart case), turant UpdateTP() call karke unpe fresh basket-TP apply kar do.
   if(CountTrades(1)>0)  UpdateTP(1);
   if(CountTrades(-1)>0) UpdateTP(-1);
   g_eaInitTime=TimeCurrent();   // v3.22: OnTradeTransaction ke initial-deposit guard ke liye
   // v1.03: GRID 2 app bridge — sirf live chart pe (Strategy Tester / optimization mein OFF)
   g_brOn=(Enable_Bridge && !MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_OPTIMIZATION) && StringLen(Bridge_FB_URL)>10);
   if(g_brOn)
   {
      EventSetTimer(MathMax(2,Bridge_Push_Sec));
      BrEventT("START","GridTrend S2 v1.05 start — "+_Symbol+" | Magic "+IntegerToString(Magic_Number));
      Print("GRID 2 Bridge  : ON  every ",MathMax(2,Bridge_Push_Sec),"s -> ",Bridge_FB_URL,"/",Bridge_Root,"/",AccountInfoInteger(ACCOUNT_LOGIN));
   }
   else Print("GRID 2 Bridge  : OFF",(MQLInfoInteger(MQL_TESTER)?" (tester)":""));
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();   // v1.03 bridge timer
   if(atrHandle!=INVALID_HANDLE) IndicatorRelease(atrHandle);
   SaveEAState();
   ClearDB();
   ClearHistoryPanel();
   ClearNewsPanel();
}

//+------------------------------------------------------------------+
//| v3.20: AUTO BASELINE ADJUSTMENT — deposit/withdrawal ko trading   |
//| deals se ALAG track karta hai (DEAL_TYPE_BALANCE) aur baselines   |
//| (cycleStartBal, basketStartEquity, dailyStartBal) ko turant       |
//| usi amount se shift kar deta hai. Isse profit/target tracking     |
//| deposit/withdrawal se kabhi galat nahi hoti — MANUAL RESET KI     |
//| ZAROORAT KHATAM (Reset_Cycle_Baseline ab sirf emergency fallback  |
//| hai, normal use mein kabhi chhoona nahi padega).                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD) return;
   if(!HistoryDealSelect(trans.deal)) return;
   long dealType=HistoryDealGetInteger(trans.deal,DEAL_TYPE);
   if(dealType!=DEAL_TYPE_BALANCE) return;   // sirf deposit/withdrawal/credit deals — trading deals nahi
   // v3.22 FIX: EA/backtest start ke turant baad (~5 sec) wala balance-deal IGNORE karo — yeh
   // initial deposit ka apna record hai (jo OnInit mein already cycleStartBal ban chuka hai),
   // isko dobara add karne se baseline DOUBLE ho jata tha (backtest mein bahut bada distortion).
   if(TimeCurrent()-g_eaInitTime<5) return;
   double amount=HistoryDealGetDouble(trans.deal,DEAL_PROFIT);
   if(MathAbs(amount)<0.005) return;         // 0 amount ignore
   cycleStartBal   +=amount;
   dailyStartBal   +=amount;
   if(basketStartEquity!=0) basketStartEquity+=amount;   // basket currently open ho to usko bhi shift karo
   SendAlert((amount>=0?"DEPOSIT":"WITHDRAWAL")+(" $"+DoubleToString(MathAbs(amount),2)+" detected — baselines auto-adjusted, profit tracking unaffected."));
   SaveEAState();
}

void OnTick()
{
   DailyReset();
   UpdateMaxDDEver();     // v3.28: sirf analytics tracker (pehle CheckStagedDD ke andar chalta tha)
   CheckTotalDDLimit();   // v3.12: fixed $ total loss hard-stop + v1.05 latched lock
   RetryPendingCloses();  // v1.05: pichla fail hua close dobara try
   CheckVolatilitySpike();   // v3.16: sudden $ spike detect karke naya trade temporarily block karo
   CheckDDFlip();   // S2: per-side DD limit cross ho to us side freeze + opposite grid start
   CheckProfitTarget();
   FetchNextNewsEvents();
   if(TimeCurrent()-g_lastStateSave>=3600) SaveEAState();
   if(Enable_DashboardExport&&TimeCurrent()-lastDashboardExport>=2)
   { ExportDashboardJSON(); lastDashboardExport=TimeCurrent(); }
   if(CountTrades(1)>0){  buyActive=1;  if(buyStartTime==0)  buyStartTime=TimeCurrent(); }
   if(CountTrades(-1)>0){ sellActive=1; if(sellStartTime==0) sellStartTime=TimeCurrent(); }
   // H1 bar: Supertrend check + whipsaw confirmation
   datetime cH1=iTime(_Symbol,Filter_TF,0);
   if(cH1!=g_lastH1)
   {
      g_lastH1=cH1;
      int s=GetST();
      if(s!=0)
      {
         if(s==g_lastSig)
         {
            // already isi direction mein — freeze state re-assert, pending clear
            g_pendingSig=0; g_pendingCount=0;
            HandleSignal(s);
         }
         else if(!Enable_SignalConfirm || g_lastSig==0)
         {
            // confirmation off, ya sabse pehla signal — abhi act karo
            g_lastSig=s; HandleSignal(s);
            g_pendingSig=0; g_pendingCount=0;
         }
         else
         {
            // opposite signal — flip se pehle N consecutive bars chahiye
            if(s==g_pendingSig) g_pendingCount++;
            else { g_pendingSig=s; g_pendingCount=1; }
            if(g_pendingCount>=Signal_Confirm_Bars)
            {
               g_lastSig=s; HandleSignal(s);
               g_pendingSig=0; g_pendingCount=0;
            }
            // warna: current basket hold karo, confirmation ka wait
         }
      }
   }
   // M1 bar: grid management
   datetime cM1=iTime(_Symbol,PERIOD_M1,0);
   if(cM1!=g_lastM1)
   {
      g_lastM1=cM1;
      if(g_lastSig==1&&buyActive==1&&CountTrades(1)==0)   OpenTrade(1);
      if(g_lastSig==-1&&sellActive==1&&CountTrades(-1)==0) OpenTrade(-1);
      if(buyActive==1)  ManageGrid(1);
      if(sellActive==1) ManageGrid(-1);
      CheckPartialClose(1); CheckPartialClose(-1);
   }
   // Every tick: GLOBAL basket override → trailing → per-direction TP
   // v3.08: UpdateTP yahan move kiya (pehle M1-only tha) — manual trade close ke baad
   // average TP turant (next tick) recalculate ho, 60 sec M1 wait ki zaroorat nahi.
   UpdateTP(1); UpdateTP(-1);
   CheckGlobalBasket();
   CheckTrailing(1); CheckTrailing(-1);
   CheckTP(1); CheckTP(-1);
   // Chart lines
   DrawHLine(PFX+"TPB",(CountTrades(1)>0)?CalcTP(1):0,clrLime);
   DrawHLine(PFX+"TPS",(CountTrades(-1)>0)?CalcTP(-1):0,clrRed);
   UpdateDB();
   UpdateHistoryPanel();
   UpdateNewsPanel();
}
//+------------------------------------------------------------------+
