//+------------------------------------------------------------------+
//|                                    PERSONAL FX v10.2 - GRID.mq5   |
//|     PERSONAL FX v10.2 — MANUAL ENTRY + MARTINGALE GRID SYSTEM    |
//|  Manual trade -> auto $TP -> loss gap -> same-side grid add ->  |
//|  basket average-price TP. Clean build: dashboard + daily limits  |
//|  + grid engine only (breakeven/trailing/autopilot/recovery/news  |
//|  session filters removed as requested).                          |
//+------------------------------------------------------------------+
//|  v4.1 : manual/mobile (magic 0) trades managed; grid state auto-synced   |
//|  v4.2 : REAL broker-side TP now set on positions (shows in MT5 T/P col)  |
//|  v4.3 : 3-COLUMN panel, font-size input, recent-closes log              |
//|  v4.4 : DPI-aware panel scaling (fixes overlap on hi-res screens),      |
//|         "Label" ghost-text bug fixed, narrower columns                  |
//|  v4.5 : FULL-WIDTH 3-column dashboard (auto-fits chart width), dotted    |
//|         rows, NEXT-ADD column in monitor, auto-rebuild on resize        |
//|  v4.6 : SYMBOL WHITELIST — EA now only manages Magic-0 (manual/mobile)   |
//|         trades on pairs YOU allow, so it can no longer grab trades      |
//|         opened by a DIFFERENT EA/robot sitting on another chart         |
//|  v4.7 : ADD GAP now measured in RAW PRICE distance (e.g. $5 = 4000,     |
//|         4005, 4010... on gold), not floating-$-loss.                    |
//|  v4.8 : Max concurrent-grids cap added (later removed in v4.9)          |
//|  v4.9 : Removed the pair-count cap — unlimited pairs allowed again.      |
//|  v5.0 : FIXED broker-side TP sync — legs no longer freeze at mismatched |
//|         prices as the grid grows. TP is CLAMPED (not skipped) at the   |
//|         broker's min-distance, so ALL legs of one pair show the SAME   |
//|         TP. (Actual basket close was always correct — this only fixes  |
//|         what the T/P column displays.)                                  |
//|  v5.1 : BASKET TP scaled with total lot (reverted in v5.2)              |
//|  v5.2 : REVERTED to FLAT $3 basket TP regardless of trade count/lot     |
//|         (back to original design — confirmed)                          |
//|  v5.3 : OCO PENDING — place Buy Limit + Sell Limit (or stops) on any   |
//|         pairs; when one FILLS, the leftover pending is auto-deleted.   |
//|         OCO_Mode: SAME PAIR (default) = only that pair's opposite      |
//|         pending removed, every pair works on its own.                  |
//|         ALL PAIRS = first fill anywhere removes every older pending.   |
//|         The filled trade then runs on normal grid rules ($TP/adds).    |
//|  v5.4 : APP BRIDGE — reads orders sent by SamuSignal Chart Analysis   |
//|         from Firebase /personalfx/orders (queue, many pairs at once). |
//|         Places MARKET / BUY-SELL LIMIT / BUY-SELL STOP with the lot   |
//|         from THIS EA's input, no SL/TP (grid rules manage the trade), |
//|         writes status back (PLACED / FAILED / SKIP / STALE) and       |
//|         deletes its own app pendings not filled in 60 min (EXPIRED).  |
//|         Also: grid engine now also runs every second (all pairs) and  |
//|         filling mode is set per symbol (fixes 10030 on other pairs).  |
//|  v5.5 : FirebaseURL default = SamuSignal Firebase (forexdiagnosis)    |
//|         so the app bridge works without typing the URL.              |
//|  v5.6 : APP BRIDGE diagnostics — every Firebase error is printed in  |
//|         Experts (HTTP code + reply), Alert once if Firebase rules    |
//|         need FirebaseAuth (401/403), startup line shows bridge state.|
//|  v5.7 : PROFIT LOCK — no loss once in good profit:                   |
//|         1 trade : profit >= $1.50 per 0.01 lot -> SL locks +$1.00     |
//|                   per 0.01 lot (TP $3 per 0.01 lot stays)            |
//|         basket  : basket profit >= $1.50 -> ONE common SL on all legs |
//|                   so the whole basket closes at least +$1.00 (flat,   |
//|                   basket TP $3 flat stays). Lock never moves back,    |
//|                   no trailing. Shown in MT5 S/L column (broker side). |
//|  v5.8 : GRID GAP IN $ — Grid_Gap_Usd = $5 loss per 0.01 lot per step, |
//|         converted to a price distance for EACH pair automatically:   |
//|         XAUUSD $5.00 (same as before), GBPUSD/EURUSD 50 pips,        |
//|         USDJPY ~79 pips ... (0 = old Grid_Gap_Price in raw price).   |
//|  v5.9 : APP BATCH (SamuSignal v10.4.0 — 2 order ek saath):           |
//|         - ek analysis ke dono order (jaise BUY LIMIT + BUY STOP, ya   |
//|           BUY LIMIT + SELL LIMIT) ek "batch" hain — ab ek-dusre ko    |
//|           REPLACE nahi karte (pehle naya order purana hata deta tha). |
//|         - AppBatchOCO: batch ka jo order pehle BHARE, usi pair ke     |
//|           baaki saare app pending turant cancel (same side bhi, jaise |
//|           Buy Limit bhara to Buy Stop bhi hatega) + app me CANCELLED. |
//|         Lot / SL / TP / grid / averaging / profit lock: KUCH NAHI BADLA.|
//|  v6.0 : PROFIT LOCK ab chalta hua (SamuSignal jaisa):              |
//|         profit +$1.00 -> SL +$0.50, +$1.10 -> +$0.60, +$1.20 ->     |
//|         +$0.70 ... (profit se $0.50 peeche, har 10 cent aage).      |
//|         1 trade: per 0.01 lot | basket: flat. SL sirf aage.         |
//|         Gold (XAU) ke alag input (abhi same). Baaki KUCH NAHI BADLA.|
//|  v6.1 : WEEKEND BAND HATAYA - Friday raat ko trades band nahi hote, |
//|         Sat/Sun naya trade / app order rokna bhi hata (CloseOnWeekend|
//|         / FridayCloseTime input hata diye). Baaki KUCH NAHI BADLA.  |
//|  v6.2 : APP LEVEL BROKER KE HISAAB SE - app ka price (TwelveData)  |
//|         aur broker ka price alag hota hai (BTC pe ~$100). Ab EA app  |
//|         ke 'live' aur broker ke price ka farak nikal ke Limit/Stop  |
//|         level utna khiskata hai (live se doori wahi rehti hai).    |
//|         Isse Sell/Buy STOP 'pehle hi paar' bol ke FAIL nahi hota.  |
//|         Inputs: AppAlignToBroker, AppMaxShiftPct (0.5% tak).       |
//|  v6.3 : SPREAD FILTER $ ME - pehle 300 points tha, BTC ka spread   |
//|         (~$15-20 = 1500-2000 points) hamesha 'zyada' aata tha, isse |
//|         BTC pe grid add / app market order kabhi nahi lagta tha.   |
//|         Ab MaxSpread_Usd = $0.50 per 0.01 lot (har pair pe ek jaisa)|
//|         0 = purana MaxSpread_Points. Skip ka log 1 min me 1 baar.  |
//|  v6.4 : GRID ADD SEEDHA - pair ka SABSE NAYA trade MT5 me jo loss  |
//|         dikhata hai (spread + swap milake) wo -$5 (0.01 lot pe) ho  |
//|         to TURANT agla trade. Har agle trade pe bhi yahi (-$5).     |
//|         Grid add pe spread filter nahi rokta. Inputs:              |
//|         GapFromLastTradeLoss = true (false = purana price-doori),   |
//|         GridAddIgnoreSpread = true. Max adds / margin / din ki seema|
//|         waise hi.                                                   |
//|  v6.5 : PAIR BASKET SL - ek pair ke SAARE trades milake (1 ho ya 7)|
//|         loss -$50 x (pehle trade ka lot/0.01) ho jaye to us pair ke |
//|         saare trades ek saath band. 0.01 se shuru -> -$50,          |
//|         0.02 se shuru -> -$100. Har pair alag. Inputs:              |
//|         UseBasketSL = true, BasketSL_Usd = 50 (0.01 lot pe).        |
//|  v6.6 : DAILY LOSS LIMIT HATAYA - loss ki suraksha ab sirf har pair |
//|         ka basket SL (v6.5). Din ka profit target ($100) waise hi.  |
//|  v6.7 : BUG FIX - app ke 2 order me se 1 "symbol nahi mila" Fail.   |
//|         Pair Market Watch me nahi tha -> EA ne joda, par us pal     |
//|         price 0 tha -> pehla order Fail, dusra lag jaata (kabhi     |
//|         LIMIT, kabhi STOP). Ab EA price aane tak 2 sec rukta hai,   |
//|         phir bhi na aaye to agle poll me dobara (30 sec tak).       |
//|  v6.8 : 2 ACCOUNT - EA har minute Firebase me apna account likhta |
//|         hai (/personalfx/accounts/<login>). App me tick kiye gaye  |
//|         account ka order sirf usi account ka EA lagata hai         |
//|         (order me "acct" = login). Bina acct wala purana order:    |
//|         AppAcceptUntagged = true ho to lagata hai.                 |
//|  v6.9 : PAIR TRADE (app Pair tab -> AUTO TRADE MT5). Dono leg     |
//|         MARKET, comment "PFXP<jodi>_<leg>". In pe GRID NIYAM NAHI  |
//|         (na grid add, na $3 TP, na basket SL). Dono milake:        |
//|         +$1 -> lock +$0.50, har +$0.10 pe lock aage; wapas lock    |
//|         tak = dono band. -$10 = dono band. (0.01 lot pe, lot ke     |
//|         saath badhta). Ek leg na khule -> 60 sec me dusri band.    |
//|         Result Firebase /personalfx/pairs me (app dikhata hai).    |
//|  v7.0 : 2 STRATEGY - input "Strategy":                            |
//|         1 = abhi jaisa (v6.9): $3 TP + grid/martingale + basket SL |
//|             + profit lock. KUCH NAHI BADLA.                        |
//|         2 = alag, saaf: har trade pe broker SL -$3 (0.01 lot pe,   |
//|             lot ke saath badhta) + TP $3 + wahi profit lock        |
//|             (+$1 -> +$0.50, har $0.10 aage). NA grid, NA martingale|
//|             NA basket SL. Har trade apne aap me alag (ek pair pe 2 |
//|             trade hon to bhi). Haath / mobile / F6-F7 / app order  |
//|             sab pe. Pair trade (PFXP) ke apne niyam dono me wahi.  |
//|         Inputs: Strategy, S2_SL_Usd = 3.                           |
//|  v7.1 : STRATEGY 3 (scalp) - har trade TP +$0.25, SL -$3 (0.01 lot |
//|         pe, lot ke saath badhta: 0.10 -> +$2.50 / -$30). Broker pe   |
//|         asli TP/SL + software backup. NA grid, NA martingale, NA     |
//|         basket SL, lock ki zaroorat nahi (TP lock se pehle). Haath / |
//|         mobile / F6-F7 / app order sab pe. Strategy 1 & 2 wahi.     |
//|         Inputs: S3_TP_Usd = 0.25, S3_SL_Usd = 3.                    |
//|  v7.2 : APP SYMBOL FIX - AppSymbolSuffix khaali ho to broker pe us  |
//|         jodi ke SAARE naam dekhta hai (GBPJPY / GBPJPYc / GBPJPYs) |
//|         aur sirf wahi chunta hai jis pe ye account TRADE kar sakta  |
//|         hai (pehle suchi ka pehla naam le leta tha -> CXM pe        |
//|         "10017 trade disabled"). Kai mile to chart wala suffix     |
//|         (XAUUSDc -> c) pehle. Strategy / grid niyam wahi.           |
//|  v7.5 : STRATEGY 4 (naya) = Strategy 3 jaisa scalp (TP $0.25 /     |
//|         SL $1.50, NO grid) + RECOVERY: aaj koi loss book hua ho    |
//|         (baaki ghata > 0) to TEZ + MAZBOOT trade (bharne ke 15 min |
//|         ke andar +$0.25, 15m ADX >= 25) $0.25 par band nahi hota:  |
//|         SL +$0.10 par, +$0.30 par SL +$0.20 pakka, TP $0.50.       |
//|         Baaki trade $0.25 par hi band. Baad ki jeet se ghata poora |
//|         hote hi recovery band. Strategy 1 / 2 / 3 bilkul wahi.     |
//|  v7.4 : APP PENDING TREND JAANCH - app ka pending ("PFXA", abhi   |
//|         nahi bhara) us pair ka 15m trend palat jaaye (BUY: band   |
//|         15m close EMA21 ke neeche + EMA neeche jhuka; SELL ulta)  |
//|         to apne aap CANCEL + app me "CANCELLED - trend palta" +    |
//|         push. Bhejte waqt hi palta ho to naya pending SKIP.        |
//|         Chalu trade / haath ke order / pair trade ko haath nahi.  |
//|  v7.3 : NEWS FILTER - app ka PENDING (abhi nahi bhara, "PFXA..") |
//|         us pair ki currency (jaise USD, EUR; gold = USD) ki HIGH    |
//|         news se NewsBeforeMin (30) min pehle apne aap CANCEL +     |
//|         app me "CANCELLED - news" + phone push. News se 30 min     |
//|         pehle se NewsAfterMin (15) min baad tak naya app PENDING   |
//|         bhi nahi lagta (SKIP). Chalu trade / haath ke order / pair |
//|         trade ko haath nahi lagata. MT5 ka apna calendar (free).  |
//|  v7.6 : STRATEGY 5 - CANDLE (SAMUSIGNAL AI ka Candle page).      |
//|         Candle page se MT5 button -> MARKET order, comment        |
//|         "PFXN<tf><key>" (tf 1 = 1 min, 5 = 5 min). Ye trade HAMESHA|
//|         Strategy 5 pe chalta hai, upar wala "Strategy" input      |
//|         (1/2/3/4) chahe kuch bhi ho. Baaki saare trades waise hi.  |
//|         Niyam: TP +$0.25 / SL -$1.50 (0.01 lot pe, lot ke saath     |
//|         badhta) broker pe + software backup; candle band hote hi  |
//|         (S5_MaxCandles = 1) jo bhi P/L ho, trade band. Lot S5_Lot  |
//|         (0.01). Na grid, na recovery, na lock. Ek pair pe ek hi    |
//|         candle trade. S5_MaxOrderAgeSec (15) se purana order nahi |
//|         lagta. Candle trade ka P/L Strategy 4 ke recovery hisaab  |
//|         me NAHI judta. Band hone par nateeja (TP / SL / CANDLE     |
//|         CLOSE, $) app ko wapas (orders/<key>: res, pl).            |
//|         App ke baaki pending (PFXA) ko candle order nahi hatata.  |
//|  v7.7 : STRATEGY 6 - HEDGE LADDER (Strategy = 6, user Final).     |
//|         Haath ka trade (jaise BUY 0.02) = MAIN. TP $3 har 0.01 lot |
//|         (0.02 -> $6) broker pe. Bhaav ulta: har $3 ki chaal (0.01  |
//|         lot pe; gold 3.00, EURUSD ~30 pip) par ulti disha ka 0.01  |
//|         HEDGE (comment "PFX6H"), koi seema nahi (S6_MaxHedges 0). |
//|         Hedge khula ho to main ka broker TP hata diya jata hai.   |
//|         Sab milake: main ghate me ho to +$5 (basket TP), main      |
//|         faayde me ho to +$3 (cycle TP) -> sab band.               |
//|         Palta: AAKHRI 2 hedge milake +$1 se upar ja kar wapas +$1 |
//|         par dono band; baaki har hedge (pehla bhi) +$1 se upar ja |
//|         kar wapas +$1 par akela band (lock). Saare hedge band ->  |
//|         main ka $6 TP wapas. Account HEDGING type hona chahiye.   |
//|  v7.8 : S6 BUG FIX - hedge sirf main se TAY $3 LEVEL par (gold:   |
//|         3573, 3570, 3567...). v7.7 me saare hedge lock se band     |
//|         hone par bhaav abhi bhi main se $3 neeche hota to TURANT  |
//|         naya hedge khul jata - har ~$1 par hedge khula/band hua    |
//|         (26 Nov demo: 16 hedge, aakhri 3552.86 par atka). Ab level |
//|         ka hisaab main ticket ke saath yaad (GV PFX6L_<ticket>):  |
//|         naya hedge tabhi jab bhaav AGLA level paar kare; bhaav     |
//|         level se upar laut kar dobara neeche paar kare to us level |
//|         par phir. Ek level par ek hi khula hedge. Naya input       |
//|         S6_LockArmUsd (default 1 = pehle jaisa): hedge itne $ se    |
//|         upar jaye tabhi lock chalu, band S6_LockUsd par.          |
//|  v7.9 : S6 CYCLE NET PROFIT (user Final): is cycle me (main khulne |
//|         ke baad) lock se BAND hue hedge ka pakka profit + main ka |
//|         P/L + khule hedge ka P/L >= S6_CycleNetUsd ($6) -> main + |
//|         saare hedge band. Naya cycle sirf aapke agle haath ke     |
//|         trade se. Basket +$5 / cycle +$3 niyam bhi rahe - jo pehle |
//|         pura ho. S6_LockArmUsd default 1 -> 2: hedge +$2 paar kare |
//|         tabhi lock chalu, band phir bhi +$1 par.                  |
//|  v8.0 : S6 JODI sirf zaroorat par (user Final): aakhri hedge khud |
//|         +$2 (S6_LockArmUsd) paar kar gaya -> wo AKELA +$1 par band,|
//|         usse pehle wala bhi AKELA +$1 par (jodi nahi). Aakhri hedge|
//|         +$2 tak nahi pahuncha (palta uske paas se) -> tabhi aakhri |
//|         2 MILAKE +$1 par dono band. Baaki sab v7.9 jaisa.         |
//|  v8.1 : S6 JODI FIX - jodi ka lock +$2 par nahi, +$1 (S6_LockUsd) |
//|         paar karte hi chalu. Naya hedge khulte waqt jodi lagbhag   |
//|         +$3 par hoti hai; bhaav turant palte to +$2 wali shart     |
//|         kabhi poori nahi hoti thi aur jodi atak jaati thi (26 Nov  |
//|         demo: 3580.50 + 3577.37). Akele hedge ka lock +$2 hi.     |
//|  v8.2 : S6 SLOT - har hedge ki jagah (slot 1 = main se $3, 2 = $6 |
//|         ...). Hedge profit me band (lock / jodi) -> usi slot ka    |
//|         naya hedge USI BHAAV par jahan band hua: bhaav wahan se    |
//|         main ki taraf jaye aur wapas us bhaav par aaye -> khulta.  |
//|         (v8.1 me level ki line dobara paar karni padti thi, isliye |
//|         3579 / 3576 band hone ke baad wahan hedge nahi khula.)    |
//|         Kabhi na khula slot: apne level par. Bhaav trigger se aadhe|
//|         gap se zyada aage nikal gaya (EA band tha / jhatka) -> us  |
//|         baar nahi, wapas aane par.                                |
//|  v8.3 : S6 PAKKA SEQUENCE + PENDING STOP (user Final). v8.2 ka    |
//|         "band hue bhaav par" hata (jodi band par 2 hedge ek hi     |
//|         bhaav par khul gaye - 3560.21 / 3560.15). Ab hedge SIRF     |
//|         level par: main -/+ n x $3 (gold 3565.81, 3562.81 ...),    |
//|         har level par EK. Bhaav abhi jin khali levels se pehle hai |
//|         (main ki taraf), unme se sabse paas ke S6_PendingAhead (3) |
//|         par SELL STOP (BUY main) / BUY STOP (SELL main), comment   |
//|         "PFX6H<level>" - chart par seedhi dikhti hai, broker usi   |
//|         bhaav par bharta hai. Hedge +$1 par band -> bhaav us level |
//|         se wapas main ki taraf jaate hi wahan phir STOP. Main ki   |
//|         taraf lautte bhaav par LIMIT se hedge NAHI (poora palta to |
//|         sab hedge ghate me khul jaate). Cycle / main TP band ->    |
//|         saare S6 pending hatao; bina main ke ya Strategy != 6 ->   |
//|         bache pending hatao. OCO niyam S6 pending / hedge ko nahi  |
//|         chhoota. Naya hedge bharne par push + jodi phir chalu.    |
//|  v8.4 : S6 NEECHE SE BAND + UPAR KHALI NAHI (user). Band sirf     |
//|         SABSE NEECHE wala hedge (6, 5, 4...): wo +$2 paar kar chuka|
//|         to akela +$1 par; nahi to neeche ke 2 milake +$1. Upar wale|
//|         tab tak chalu. Hedge gehrai (main se doori) ke kram me.   |
//|         Jo level +$1 par band hua aur bhaav level se aage tha ->   |
//|         wo level JAHAN BAND HUA usi bhaav par phir (STOP; bhaav    |
//|         seedha neeche gaya to market se) - neeche wale se PEHLE.  |
//|         Bhaav level se upar laut gaya -> theek level par. Taaki 1  |
//|         band aur 2 chalu jaisa na ho.                              |
//|  v8.5 : S6_PendingAhead default 3 -> 5 (user): seedhi chaal me     |
//|         ~5 hedge par basket +$5 - spike me bhi 5 pending pehle se. |
//|  v8.6 : S6 BUG FIX (user Final, real-gold backtest "B"):           |
//|         1) "market se dobara kholo" HATA - 26 Nov demo me 3 SELL ek |
//|            hi bhaav 3574.090 par khul gaye the. Ab hedge sirf       |
//|            pending STOP se, tay bhaav par.                         |
//|         2) Do hedge ke beech kam se kam aadha gap (gold 1.5 point):|
//|            khule hedge ke itne paas pending nahi lagta.            |
//|         3) Dobara khulne ka bhaav (4b) apne level se aadhe gap se  |
//|            aage nahi - kabhi agle level ke paar nahi, kram sahi.   |
//|         4) S6_BasketSL_Usd default 0 -> 60.                        |
//|         Backtest (B, SL $30): 7 din +$3.78 / 60 din +$5.60 per     |
//|         cycle (v8.5: +$3.58 / +$5.22), Basket SL aadha lagta hai.  |
//|  v8.7 : S6 LIVE APP (GRID-STARTAGY-2 "S6 LIVE"). Firebase          |
//|         /personalfx/s6live/<S6_LiveKey>/ (FirebaseAuth ke saath):  |
//|         live/<pair> har S6_LivePushSec (3) sec - main, har hedge   |
//|         (level, bhaav, P/L, lock), pending, kul / pakka / net,     |
//|         cycle ka sabse bada DD, balance, equity; hb har 30 sec;    |
//|         events (har S6 push sandesh); cycles (har band cycle:      |
//|         shuru / band, nateeja, P/L, DD, kitne hedge). Account      |
//|         number nahi jaata. Trade niyam v8.6 jaise hi.              |
//|  v8.8 : S6 JODI LOCK BHARTE HI (user Final). 27 Nov demo: SELL main |
//|         3613.63, aakhri BUY hedge 3635.79 chot par bhara aur bhaav  |
//|         1 sec me 1+ point gira - jodi (3633.13 + 3635.79) kabhi     |
//|         +$1 ke upar "dikhi" nahi, lock chalu nahi hua, jodi atki,   |
//|         aur "neeche se band" ne upar wale bhi rok diye (−$44).      |
//|         Ab sabse neeche wala hedge NAYA bhare (60 sec ke andar) aur |
//|         bhare bhaav par jodi (doori − spread) > +$1 ho to jodi ka   |
//|         lock usi pal chalu - bhaav palte to dono ~+$1 par band.    |
//|         Purane khule hedge par ye nahi lagta (ghate me zabardasti  |
//|         band na ho).                                               |
//|  v8.9 : S6 FIX (user Final, 27 Nov demo): cycle profit (pakka +    |
//|         khule) $8-10 hua par +$6 net par band nahi hua; ek jodi    |
//|         -$1.57 par band. Wajah: app ko data bhejte waqt (WebRequest)|
//|         EA ruk jaata tha. Ab: (1) S6 LIVE ka saara data queue me - |
//|         OnTimer ke AAKHIR me, ek baar me sirf ek request, aur kisi |
//|         trade action ke 1.5 sec ke andar nahi; events 10 sec me    |
//|         ek saath (PATCH); live har 5 sec. (2) OnTimer me trade     |
//|         niyam (ManageMartingaleGrids) SABSE PEHLE, app poll baad.  |
//|         (3) Basket SL SEEDHA $ (S6_BasketSL_Usd = 60 -> -$60), lot |
//|         se guna nahi (pehle 0.02 par -$120 ho jaata tha).          |
//|         (4) Experts log: har 10 sec "khule / pakka / net".         |
//|  v9.0 : S6 LIVE app ka 🩺 CHECK tab (user Final) - MT5 khole bina  |
//|         sab jaanch: hb (har 15 sec) me ab Strategy, Algo Trading /  |
//|         EA trade allowed, connected, ping, margin level, free      |
//|         margin, S6_LiveOn / push sec / ManageManualTrades, EA ki   |
//|         aakhri 20 galti (pending fail, TP modify fail, adhura band, |
//|         Firebase HTTP error, margin / max trades) aur aakhri 30    |
//|         "HAAL" (khule / pakka / net, har 10 sec). hb Strategy 6 na |
//|         ho tab bhi jaata hai (app me "Strategy galat" dikhe).      |
//|         live me spread bhi. Trade niyam v8.9 jaise.                |
//|  v10.1: user Final (27 Nov shaam, v9.0 se nayi shuruaat; purani   |
//|         v9.1-v9.3 hataayi, naam 10.1 taaki VPS par bhram na ho):   |
//|         main BUY 0.01 (haath se). Sab target $2: Net (pakka +      |
//|         khule) $2, Cycle TP $2, Basket TP $2, akele main ka TP $2  |
//|         (S6_TP_Usd 3 -> 2 per 0.01). Hedge 0.01 har $3, lock       |
//|         +$2 -> +$1 (v9.0 jaisa, 1 number bhi). NAYA: hedge khule   |
//|         hon aur bhaav main ke bhaav par laute -> doosra BUY 0.01   |
//|         (comment "PFX6HB", STOP main ke bhaav par, ek cycle me ek) |
//|         - wo sirf poore cycle ke saath band (akela nahi). Basket   |
//|         SL $60. Backtest round 17: v9.0 se ~30% kam $/ghanta, SL   |
//|         kam (1m 17 -> 5, 5m 8 -> 2).                               |
//|  v10.2: BUG FIX (user "A Final", 27 Nov raat): saare SELL band +   |
//|         doosra BUY khula -> EA $2 jaanch ke baad turant laut jaata |
//|         tha, pending wala hissa chalta hi nahi tha (purane pending |
//|         3641.27... pade rahe, 2 number 3644.27 nahi laga). Ab      |
//|         return sirf band karne par; pending theek $3 level par.    |
//+------------------------------------------------------------------+
#property copyright   "PERSONAL FX"
#property description "PERSONAL FX v10.2 — Strategy 1 (Grid) / 2 ($3 SL) / 3 (scalp) / 4 (scalp+recovery) / 6 (hedge ladder) + Strategy 5 CANDLE (app Candle page) + OCO + App Bridge"
#property version     "10.20"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade        trade;
CPositionInfo posInfo;

enum ENUM_PFX_STRATEGY
{
   STRAT_1_GRID = 1,    // 1 - Grid + Martingale (abhi jaisa, v6.9)
   STRAT_2_SL   = 2,    // 2 - Sirf $3 SL + $3 TP + profit lock (NO grid / martingale)
   STRAT_3_SCALP = 3,   // 3 - Scalp: TP +$0.25, SL -$3 (NO grid / martingale)
   STRAT_4_RECOVER = 4, // 4 - Scalp + RECOVERY: loss ke baad tez trade $0.50 tak (+$0.20 pakka)
   STRAT_6_HEDGE   = 6  // 6 - HEDGE LADDER: main TP $3/0.01, har $3 par ulta 0.01 hedge, basket +$5 / cycle +$3, hedge lock +$1 (v7.7)
};

enum ENUM_OCO_MODE
{
   OCO_OFF       = 0,   // OFF - pending orders are never touched
   OCO_SAME_PAIR = 1,   // SAME PAIR - fill removes opposite pending of that pair only
   OCO_ALL_PAIRS = 2    // ALL PAIRS - first fill removes every older pending on all pairs
};

//+------------------------------------------------------------------+
//|  INPUTS                                                           |
//+------------------------------------------------------------------+
input group "========== STRATEGY (v7.1) =========="
input ENUM_PFX_STRATEGY Strategy = STRAT_1_GRID;  // 1 = grid/martingale (abhi jaisa) | 2 = $3 SL, no grid
input double S2_SL_Usd           = 3.0;           // Strategy 2: har trade ka SL, $ per 0.01 lot (lot ke saath badhta)
input double S3_TP_Usd           = 0.25;          // Strategy 3: har trade ka TP, $ per 0.01 lot (lot ke saath badhta)
input double S3_SL_Usd           = 3.0;           // Strategy 3: har trade ka SL, $ per 0.01 lot (lot ke saath badhta)

input group "========== STRATEGY 4 - SCALP + RECOVERY (v7.5) =========="
input double S4_TP_Usd           = 0.25;          // S4: aam TP, $ per 0.01 lot
input double S4_SL_Usd           = 1.50;          // S4: SL, $ per 0.01 lot
input double S4_BigTP_Usd        = 0.50;          // S4 recovery: bada TP, $ per 0.01 lot
input double S4_LockAt_Usd       = 0.30;          // S4 recovery: itne profit par lock
input double S4_LockTo_Usd       = 0.20;          // S4 recovery: lock hone par itna pakka
input double S4_PreLock_Usd      = 0.10;          // S4 recovery: +TP se +LockAt ke beech itna pakka (0 = entry par)
input int    S4_FastMin          = 15;            // S4 recovery: bharne ke itne min ke andar +TP tak pahunche (0 = jaanch nahi)
input double S4_AdxMin           = 25;            // S4 recovery: 15m ADX kam se kam (0 = jaanch nahi)

input group "========== STRATEGY 5 - CANDLE (v7.6, sirf app Candle page) =========="
input double S5_TP_Usd           = 0.25;          // S5: TP, $ per 0.01 lot (lot ke saath badhta)
input double S5_SL_Usd           = 1.50;          // S5: SL, $ per 0.01 lot (lot ke saath badhta)
input double S5_Lot              = 0.01;          // S5: candle trade ka lot (EA ke FixedLot se alag)
input int    S5_MaxCandles       = 1;             // S5: itni candle ke baad band (1 = wahi candle band hote hi; 0 = sirf TP/SL)
input int    S5_CloseEarlySec    = 0;             // S5: candle band hone se itne sec pehle band (0 = theek close par)
input int    S5_MaxOrderAgeSec   = 15;            // S5: app order isse purana ho to NAHI lagta (STALE)

input group "========== STRATEGY 6 - HEDGE LADDER (v7.7) =========="
input double S6_TP_Usd           = 2.0;           // S6 v10.1: main trade TP, $ per 0.01 lot (0.01 main -> $2; pehle 3)
input double S6_Gap_Usd          = 3.0;           // S6: har itne $ ki ulti chaal (0.01 lot pe) par naya hedge
input double S6_HedgeLot         = 0.01;          // S6: har hedge ka lot
input double S6_BasketTP_Usd     = 2.0;           // S6: main ghate me + sab milake itna -> sab band (flat)
input double S6_CycleTP_Usd      = 2.0;           // S6: main faayde me + bache hedge milake itna -> sab band (flat)
input double S6_LockUsd          = 1.0;           // S6: hedge lock - wapas itne $ par aaye to band (per 0.01 lot)
input double S6_LockArmUsd       = 2.0;           // S6 v7.9: lock tabhi chalu jab hedge isse upar jaye (per 0.01 lot; LockUsd se kam ho to LockUsd)
input bool   S6_LiveOn           = true;          // S6 v8.7: GRID-STARTAGY-2 "S6 LIVE" app ke liye Firebase par live data
input string S6_LiveKey          = "s6";          // S6 v8.7: app me yahi key (account number nahi jaata)
input int    S6_LivePushSec      = 5;             // S6 v8.9: live data har itne sec (pehle 3)
input int    S6_PendingAhead     = 5;             // S6 v8.5: aage ke kitne khali levels par pending STOP (pehle 3; seedhi chaal me ~5 par basket)
input double S6_CycleNetUsd      = 2.0;           // S6 v7.9: band hedge ka pakka profit + sab khule trade >= itna -> sab band (0 = OFF)
input int    S6_MaxHedges        = 0;             // S6: ek pair pe max hedge (0 = koi seema nahi)
input bool   S6_SecondBuyOn      = true;          // S6 v10.1: hedge khule + bhaav main ke bhaav par laute -> doosra trade main ki disha me (S6_HedgeLot), sirf cycle ke saath band
input double S6_BasketSL_Usd     = 60.0;          // S6 v8.9: khule trades milake itna ghata ($, seedha - lot se guna nahi) -> sab band (0 = OFF)

input group "========== GENERAL =========="
input int    MagicNumber        = 111222;
input int    MaxOpenTrades      = 30;      // safety cap across all grids
input bool   ManageManualTrades = true;    // also manage trades opened by hand / mobile app (magic 0)
input string AllowedSymbolsCSV    = "";      // empty = ALL symbols. Else comma list e.g. "EURUSDm,GBPUSDm,XAUUSDm" — ONLY these get grid-managed (protects against other EAs' Magic-0 trades)

input group "========== MANUAL LOT =========="
input double FixedLot           = 0.01;    // starting lot for a fresh manual trade
input double MinLot             = 0.01;
input double MaxLot             = 10.0;

input group "========== MARTINGALE GRID =========="
input double Grid_TP_Dollar       = 3.0;   // single-trade TP, $ PER 0.01 LOT (auto-scales)
input bool   UsePriceDistanceGap   = true;   // true = gap is a raw PRICE move (recommended); false = old floating-$-loss basket mode
input double Grid_Gap_Usd         = 5.0;    // v5.8: har grid step = itna $ loss per 0.01 lot (har pair pe khud price me badalta hai). 0 = neeche wala Grid_Gap_Price
input double Grid_Gap_Price       = 5.0;    // PRICE distance per grid step when UsePriceDistanceGap=true (e.g. 5.0 = $5 on XAUUSD -> 4000,4005,4010...; for EURUSD enter the price distance e.g. 0.0050 = 50 pips)
input double Grid_Gap_Dollar      = 10.0;  // (legacy mode only) basket floating-loss gap ($) that triggers next add
input double Grid_BasketTP_Dollar = 3.0;   // combined basket TP once 2+ trades are open ($, FLAT — does not scale with lot/trade count)
input bool   GapFromLastTradeLoss = true;   // v6.4: sabse naya trade MT5 me -$Grid_Gap_Usd (0.01 lot pe, spread milake) -> turant agla trade
input bool   GridAddIgnoreSpread  = true;   // v6.4: grid add pe spread filter mat lagao (seedha niyam)
input int    Grid_MaxAdds         = 6;     // max martingale additions per pair (1 orig + N adds)

input group "========== PAIR BASKET SL (v6.5) =========="
input bool   UseBasketSL          = true;   // ek pair ke saare trades milake loss limit
input double BasketSL_Usd         = 50.0;   // $ per 0.01 lot of PEHLA trade: 0.01 -> -$50, 0.02 -> -$100

input group "========== PROFIT LOCK (v6.0 - chalta hua) =========="
input bool   UseProfitLock        = true;   // profit pakka + aage badhta
input double Lock_Start_Dollar    = 1.00;   // itna profit aate hi lock shuru (1 trade: per 0.01 lot | basket: flat)
input double Lock_Gap_Dollar      = 0.50;   // SL profit se itne $ peeche: +$1 -> +$0.50, +$1.10 -> +$0.60 ...
input double Lock_Step_Dollar     = 0.10;   // har itne $ pe SL aage
input double Gold_Lock_Start      = 1.00;   // Gold (XAU) ke liye alag - shuru
input double Gold_Lock_Gap        = 0.50;   // Gold - peeche $
input double Gold_Lock_Step       = 0.10;   // Gold - step $

input group "========== PAIR TRADE (v6.9 - app Pair tab) =========="
input bool   UsePairRules         = true;   // pair ke dono leg milake lock / SL (grid niyam nahi)
input double PairSL_Usd           = 10.0;   // dono milake itna loss (0.01 lot pe) -> dono band
input int    PairOrphanSec        = 60;     // ek hi leg khula reh gaya -> itne sec baad band

input group "========== DAILY RISK CONTROL =========="
input bool   UseDailyLimits       = true;
input double MaxDailyProfit       = 100.0; // account-wide daily profit target ($)

input group "========== OCO PENDING (v5.3) =========="
input ENUM_OCO_MODE OCO_Mode     = OCO_SAME_PAIR; // Buy Limit + Sell Limit: when one fills, leftover pending auto-deleted

input group "========== SAMUSIGNAL APP BRIDGE (v5.4) =========="
input bool   UseAppBridge         = true;   // read orders sent from SamuSignal Chart Analysis
input string FirebaseURL          = "https://forexdiagnosis-default-rtdb.asia-southeast1.firebasedatabase.app"; // SamuSignal / FXBridge wala Firebase (default set)
input string FirebaseAuth         = "";     // only if your Firebase rules need it (same as app)
input string AppSymbolSuffix      = "";     // empty = auto-find (XAUUSD -> XAUUSDc / XAUUSDm). Or force e.g. "c" or "m"
input int    AppPollSec           = 3;      // how often Firebase is checked (seconds)
input int    AppPendingExpiryMin  = 60;     // app pending not filled in this many minutes -> deleted
input int    AppMaxOrderAgeMin    = 10;     // order older than this when EA sees it -> NOT placed (STALE)
input bool   AppAlignToBroker     = true;   // v6.2: app (TwelveData) aur broker price ka farak level me jodo — live se doori wahi rahe
input double AppMaxShiftPct       = 0.5;    // v6.2: farak isse zyada (% price) ho to mat khiskao (kuch gadbad maano)
input bool   AppAcceptUntagged    = true;   // v6.8: app ka purana order (account tick ke bina) bhi lagao. 2 account pe EA ho to false rakho
input bool   AppBatchOCO          = true;   // v5.9: app ka jo order pehle bhare, usi pair ke BAAKI saare app pending cancel (same side bhi)

input group "========== APP PENDING TREND JAANCH (v7.4) =========="
input bool   AppTrendRecheck      = true;   // App ka pending bharne se pehle 15m trend palta to cancel
input int    AppTrendEMA          = 21;     // 15m EMA (trend ke liye)

input group "========== NEWS FILTER (v7.3) =========="
input bool   NewsCancelPending    = true;   // High news se pehle app ke PENDING (abhi nahi bhare) cancel
input int    NewsBeforeMin        = 30;     // news se itne min pehle
input int    NewsAfterMin         = 15;     // news ke itne min baad tak naya app pending nahi
input bool   NewsWithMedium       = false;  // Medium impact news pe bhi

input group "========== SAFETY FILTERS =========="
input bool   UseSpreadFilter      = true;
input int    MaxSpread_Points     = 300;    // sirf tab jab MaxSpread_Usd = 0
input double MaxSpread_Usd        = 0.50;   // v6.3: spread isse zyada ($ per 0.01 lot) ho to add / app market nahi (0 = points wala)

input group "========== PANEL =========="
input bool   ShowPanel            = true;
input int    Panel_X              = 10;
input int    Panel_Y              = 25;
input bool   EnableFKeys          = true;   // F6 Buy / F7 Sell / F8 Close All
input int    Panel_FontSize       = 10;     // 8-12; lower it if text still overlaps on your screen
input double Panel_Scale          = 0.0;    // 0 = AUTO from screen DPI. Force e.g. 1.5 / 2.0 if layout looks wrong

input group "========== NOTIFICATIONS =========="
input bool   UsePushNotify        = true;

//+------------------------------------------------------------------+
//|  THEME                                                            |
//+------------------------------------------------------------------+
#define QT_AMBER   C'255,176,0'
#define QT_AMBERD  C'170,125,30'
#define QT_DOTS    C'82,66,26'
#define QT_BG      C'8,8,8'
#define QT_BORDER  C'70,64,40'
#define QT_SECT    C'34,27,7'
#define QT_WHITE   C'230,230,222'
#define QT_GREEN   C'80,220,100'
#define QT_RED     C'255,90,80'
#define QT_DARKBTN C'12,12,10'
#define QFONT      "Consolas"
#define PANEL_W    808
#define COL_W      260
#define MAX_GRID_ROWS 12

//+------------------------------------------------------------------+
//|  GLOBALS                                                           |
//+------------------------------------------------------------------+
double   g_DayStartBalance = 0;
double   g_DailyPL         = 0;
int      g_DailyTradeCount = 0;
bool     g_DailyLimitHit   = false;
datetime g_LastDayReset    = 0;
double   g_LotInput        = 0.01;
string   g_ActiveSymbol    = "";   // symbol manual trades go to; set from panel edit box
double   g_S               = 1.0;   // panel scale factor (screen DPI / 96)
double   g_DpiS            = 1.0;   // real screen DPI / 96 (used for text width estimate)
int      g_CW              = 400;   // column width in px (set in BuildPanel)
int      g_LabChars        = 16;    // chars used by "LABEL ......" part of a row
int      g_ValX            = 200;   // x offset of value inside a column
int      g_LastChartW      = 0;     // chart width the panel was built for

// ===== MARTINGALE GRID state (per symbol, dynamic) =====
#define MAX_GRID_SYMS 30
string   g_GSym[MAX_GRID_SYMS];
int      g_GDir[MAX_GRID_SYMS];    // 1 = buy grid, -1 = sell grid
int      g_GAdds[MAX_GRID_SYMS];   // martingale adds done so far (0 = only original trade)
double   g_GLot[MAX_GRID_SYMS];    // lot used for every trade in this grid
double   g_GEntry[MAX_GRID_SYMS];  // ORIGINAL entry price of the grid (level 0) — used for price-distance gap
int      g_GCount = 0;

// ===== APP BRIDGE state (v5.4) =====
datetime g_AppLastPoll  = 0;
datetime g_AppLastOk    = 0;
string   g_AppStatus    = "OFF";
bool     g_AppUrlWarned = false;
bool     g_AppAuthWarned = false;
string   g_AppDone[300];             // keys already handled this session (no double orders)
int      g_AppDoneN     = 0;
// v5.9: abhi ke Firebase poll me kaun sa key kis batch ka hai (EA restart ke baad bhi sahi — Firebase se aata hai)
string   g_PollKey[];
string   g_PollBatch[];
int      g_PollN        = 0;

// session log (last 5 closed deals)
string g_LogTime[5];
string g_LogText[5];
double g_LogPL[5];
int    g_LogN = 0;

const string BT_BUY  = "PFX_BUY";
const string BT_SELL = "PFX_SELL";
const string BT_LDN  = "PFX_LDN";
const string BT_LUP  = "PFX_LUP";
const string BT_CALL = "PFX_CALL";
const string BT_F6   = "PFX_F6";
const string BT_F7   = "PFX_F7";
const string BT_F8   = "PFX_F8";
const string ED_SYM   = "PFX_SYM_EDIT";
const string BT_SYMSET= "PFX_SYM_SET";

//+------------------------------------------------------------------+
//|  INIT / DEINIT                                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFillingBySymbol(_Symbol);

   g_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_LastDayReset    = TimeCurrent();
   g_LotInput        = FixedLot;
   g_ActiveSymbol    = _Symbol;
   g_DailyLimitHit   = false;
   g_DailyTradeCount = 0;
   g_DailyPL         = 0;
   g_GCount = 0;
   g_LogN   = 0;

   int dpi = (int)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
   if(dpi<=0) dpi=96;
   g_DpiS = dpi/96.0;
   g_S = (Panel_Scale>0.0) ? Panel_Scale : (dpi/96.0);
   g_S = MathMax(0.75, MathMin(3.0, g_S));
   Print("PERSONAL FX: screen DPI ",dpi," -> panel scale ",DoubleToString(g_S,2),
         (Panel_Scale>0.0 ? " (manual)" : " (auto)"));

   EventSetTimer(1);
   if(ShowPanel) BuildPanel();

   if(Strategy==STRAT_6_HEDGE && (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
      Alert("PERSONAL FX v10.2: Strategy 6 ke liye HEDGING account chahiye - ye account netting hai, hedge main trade ko kaat dega!");
   Print("PERSONAL FX v10.2 Loaded | STRATEGY ", (Strategy==STRAT_6_HEDGE ? "6 (hedge ladder: TP $"+DoubleToString(S6_TP_Usd,2)+"/0.01L, gap $"+DoubleToString(S6_Gap_Usd,2)+", hedge "+DoubleToString(S6_HedgeLot,2)+", basket +$"+DoubleToString(S6_BasketTP_Usd,2)+", cycle +$"+DoubleToString(S6_CycleTP_Usd,2)+", net +$"+DoubleToString(S6_CycleNetUsd,2)+", lock +$"+DoubleToString(S6_LockUsd,2)+" @ +$"+DoubleToString(MathMax(S6_LockUsd,S6_LockArmUsd),2)+")"
         : Strategy==STRAT_4_RECOVER ? "4 (scalp +$"+DoubleToString(S4_TP_Usd,2)+" / -$"+DoubleToString(S4_SL_Usd,2)+" + RECOVERY $"+DoubleToString(S4_BigTP_Usd,2)+", lock +$"+DoubleToString(S4_LockTo_Usd,2)+" @ $"+DoubleToString(S4_LockAt_Usd,2)+", NO grid)"
         : Strategy==STRAT_3_SCALP ? "3 (scalp: +$"+DoubleToString(S3_TP_Usd,2)+" TP / -$"+DoubleToString(S3_SL_Usd,2)+" SL, NO grid)"
         : Strategy==STRAT_2_SL ? "2 ($"+DoubleToString(S2_SL_Usd,2)+" SL + $"+DoubleToString(Grid_TP_Dollar,2)+" TP + lock, NO grid)" : "1 (grid + martingale, v6.9 jaisa)"),
         " | OCO mode: ", OcoModeText(),
         " | App bridge: ", (UseAppBridge && FirebaseURL!="") ? "ON" : "OFF",
         " | App batch OCO: ", AppBatchOCO ? "ON" : "OFF",
         " | FirebaseAuth: ", (FirebaseAuth!="") ? "set" : "KHAALI");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0, "PFX_");
}

void OnTimer()
{
   ManageMartingaleGrids();     // v8.9: trade niyam SABSE PEHLE (app / Firebase ke kaam baad me)
   ManageAppBatchOCO();         // v5.9: app batch ka ek order bhara -> usi pair ke baaki app pending cancel
   ManageOCOPending();          // every second -> catches fills on ALL pairs, not just chart pair
   PollAppOrders();             // v5.4: SamuSignal orders from Firebase
   CheckAppPendingExpiry();     // v5.4: app pendings not filled in 60 min -> delete
   CheckNewsPending();          // v7.3: High news se 30 min pehle app pending cancel
   CheckAppTrendPending();      // v7.4: 15m trend palta to app pending cancel
   ManageMartingaleGrids();     // v5.4: grid TP/adds for ALL pairs even if chart pair is quiet (v8.9: dobara - poll ke baad taaza)
   if(UsePairRules) ManagePairTrades();   // v6.9
   ManageCandleTrades();        // v7.6: Strategy 5 (candle close par band - har second jaanch)
   if(ShowPanel) UpdatePanel();
   S6LvFlush();                 // v8.9: S6 LIVE app ka data - sabse aakhir, ek request
}

//+------------------------------------------------------------------+
//|  MAIN TICK                                                        |
//+------------------------------------------------------------------+
void OnTick()
{
   CheckDailyReset();
   if(UseDailyLimits) CheckDailyLimitsMonitor();

   ManageAppBatchOCO();         // v5.9
   ManageOCOPending();
   ManageMartingaleGrids();
   if(UsePairRules) ManagePairTrades();   // v6.9
   ManageCandleTrades();        // v7.6

   if(ShowPanel) UpdatePanel();
}

//+------------------------------------------------------------------+
//|  SESSION LOG — capture closed deals                                |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   ManageAppBatchOCO();         // v5.9: app batch — pehle ye (status CANCELLED likhta hai)
   ManageOCOPending();          // a pending may have just filled -> remove leftovers instantly
   if(!HistoryDealSelect(trans.deal)) return;

   long entry = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_OUT_BY) return;
   S5OnDealOut(trans.deal);                                // v7.6: candle trade band -> app ko nateeja
   if(!HistoryDealSelect(trans.deal)) return;              // (S5OnDealOut ne history chuni thi - wapas)

   long mg = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
   if(mg != MagicNumber && !(ManageManualTrades && mg==0)) return;

   double pl = HistoryDealGetDouble(trans.deal, DEAL_PROFIT)
             + HistoryDealGetDouble(trans.deal, DEAL_SWAP)
             + HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
   datetime dt = (datetime)HistoryDealGetInteger(trans.deal, DEAL_TIME);

   for(int i=4;i>0;i--)
   { g_LogTime[i]=g_LogTime[i-1]; g_LogText[i]=g_LogText[i-1]; g_LogPL[i]=g_LogPL[i-1]; }
   g_LogTime[0] = StringSubstr(TimeToString(dt, TIME_SECONDS), 11, 8);
   g_LogText[0] = "CLOSE";
   g_LogPL[0]   = pl;
   if(g_LogN < 5) g_LogN++;
}

//+------------------------------------------------------------------+
//|  WHICH POSITIONS BELONG TO US                                     |
//|  EA magic  OR  (manual / mobile-app trades with magic 0)          |
//+------------------------------------------------------------------+
bool IsAllowedSymbol(string sym)
{
   if(AllowedSymbolsCSV=="") return true;   // whitelist off -> everything allowed
   string list = AllowedSymbolsCSV;
   StringToUpper(list);
   string symU = sym;
   StringToUpper(symU);
   string parts[];
   int n = StringSplit(list, ',', parts);
   for(int i=0;i<n;i++)
   {
      string p = parts[i];
      StringTrimLeft(p); StringTrimRight(p);
      if(p=="") continue;
      if(symU==p) return true;
   }
   return false;
}

// v6.9: app Pair tab ka leg? (comment "PFXP...") -> grid niyam se bahar
string PosComment()                    // broker ne position ka comment hata diya ho to kholne wale order ka
{
   string c = posInfo.Comment();
   if(c!="") return c;
   if(HistoryOrderSelect((ulong)posInfo.Identifier())) return HistoryOrderGetString((ulong)posInfo.Identifier(), ORDER_COMMENT);
   return "";
}
bool IsPairPos()
{
   return (posInfo.Magic()==MagicNumber && StringFind(PosComment(),"PFXP")==0);
}

// v7.6: app Candle page ka trade? (comment "PFXN<tf><key>") -> Strategy 5, grid / S1-S4 se bahar
bool IsCandlePos()
{
   return (posInfo.Magic()==MagicNumber && StringFind(PosComment(),"PFXN")==0);
}

bool IsOurPos()
{
   long m = posInfo.Magic();
   if(!IsAllowedSymbol(posInfo.Symbol())) return false;   // not on the whitelist -> leave it alone
   if(IsPairPos()) return false;                          // v6.9: pair leg - ManagePairTrades sambhalta hai
   if(IsCandlePos()) return false;                        // v7.6: candle trade - ManageCandleTrades sambhalta hai
   if(m==MagicNumber) return true;
   if(ManageManualTrades && m==0) return true;
   return false;
}

// Re-syncs grid state from real open positions (works for trades placed
// from mobile/terminal and survives EA restarts).
void SyncGridState(string sym, int gi, int cnt)
{
   datetime firstT=0; double lot=0; int dir=0; double entryPx=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      if(firstT==0 || posInfo.Time()<firstT)
      {
         firstT  = posInfo.Time();
         lot     = posInfo.Volume();
         dir     = (posInfo.PositionType()==POSITION_TYPE_BUY) ? 1 : -1;
         entryPx = posInfo.PriceOpen();
      }
   }
   if(dir==0) return;
   if(cnt==1 || g_GLot[gi]<=0 || g_GDir[gi]==0)
   { g_GDir[gi]=dir; g_GLot[gi]=lot; g_GEntry[gi]=entryPx; }
   g_GAdds[gi] = MathMax(0, cnt-1);
}

//+------------------------------------------------------------------+
//|  GRID STATE HELPERS                                               |
//+------------------------------------------------------------------+
int GridIndex(string sym, bool createIfMissing)
{
   for(int i=0; i<g_GCount; i++) if(g_GSym[i]==sym) return i;
   if(createIfMissing && g_GCount<MAX_GRID_SYMS)
   {
      g_GSym[g_GCount]  = sym;
      g_GDir[g_GCount]  = 0;
      g_GAdds[g_GCount] = 0;
      g_GLot[g_GCount]  = 0;
      g_GEntry[g_GCount]= 0;
      return g_GCount++;
   }
   return -1;
}

// v6.5: pair ka PEHLA (sabse purana) trade ka lot
double FirstLegLot(string sym)
{
   double lot=0; long firstMs=LONG_MAX;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      if(posInfo.TimeMsc() < firstMs){ firstMs=posInfo.TimeMsc(); lot=posInfo.Volume(); }
   }
   return lot;
}

double GetSymbolFloatingPL(string sym)
{
   double t=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      t += posInfo.Profit()+posInfo.Swap();
   }
   return t;
}

int GetSymbolPositionCount(string sym)
{
   int c=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      c++;
   }
   return c;
}

void CloseSymbolTrades(string sym)
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      trade.PositionClose(posInfo.Ticket());
   }
}

//+------------------------------------------------------------------+
//|  OPEN NEXT GRID ADD (same direction, same lot as the grid start)  |
//+------------------------------------------------------------------+
// v6.3: spread $ me (0.01 lot pe) — har pair pe ek jaisa (BTC ke 1800 points bhi sirf ~$0.18)
bool SpreadTooHigh(string sym, string &txt)
{
   if(!UseSpreadFilter) return false;
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK), bid = SymbolInfoDouble(sym, SYMBOL_BID);
   if(MaxSpread_Usd > 0)
   {
      double k = ProfitPerPriceUnitPerLot(sym);
      if(k > 0 && ask > bid)
      {
         double usd = (ask - bid) * k * 0.01;
         txt = "$"+DoubleToString(usd,2)+" / 0.01 lot";
         return usd > MaxSpread_Usd;
      }
   }
   long sp = SymbolInfoInteger(sym, SYMBOL_SPREAD);
   txt = IntegerToString(sp)+" pts";
   return sp > MaxSpread_Points;
}
datetime g_SpreadWarnAt = 0;

void OpenGridAdd(string sym, int gi)
{
   if(UseDailyLimits && g_DailyLimitHit) return;
   if(PositionsTotal() >= MaxOpenTrades)
   { Print("PERSONAL FX GRID: MAX OPEN TRADES — skip add on ", sym); return; }

   string spTxt = "";
   if(!GridAddIgnoreSpread && SpreadTooHigh(sym, spTxt))
   {
      if(TimeCurrent() - g_SpreadWarnAt >= 60)
      { g_SpreadWarnAt = TimeCurrent(); Print("PERSONAL FX GRID: spread zyada (", spTxt, ") — add ruka ", sym); }
      return;
   }

   trade.SetTypeFillingBySymbol(sym);   // v5.4: correct filling mode for THIS pair
   ENUM_ORDER_TYPE type = (g_GDir[gi]==1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double price = (type==ORDER_TYPE_BUY) ? SymbolInfoDouble(sym,SYMBOL_ASK)
                                         : SymbolInfoDouble(sym,SYMBOL_BID);
   double lot = g_GLot[gi];

   double marginReq=0, freeMargin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(OrderCalcMargin(type,sym,lot,price,marginReq) && marginReq>0 && marginReq>freeMargin)
   { Print("PERSONAL FX GRID [",sym,"]: NO MARGIN for add — need $",DoubleToString(marginReq,2)); return; }

   bool ok=(type==ORDER_TYPE_BUY) ?
           trade.Buy(lot,sym,price,0,0,"PFX_GRID_ADD"):
           trade.Sell(lot,sym,price,0,0,"PFX_GRID_ADD");

   if(ok)
   {
      g_GAdds[gi]++;
      g_DailyTradeCount++;
      Print("PERSONAL FX GRID [",sym,"]: Add #",g_GAdds[gi]," opened @ ",
            DoubleToString(price,(int)SymbolInfoInteger(sym,SYMBOL_DIGITS)),
            " | Lot ",DoubleToString(lot,2));
      if(UsePushNotify)
         SendNotification("PERSONAL FX GRID: Add #"+IntegerToString(g_GAdds[gi])+" "+sym+
                          " "+(g_GDir[gi]==1?"BUY":"SELL")+" @ "
                          +DoubleToString(price,(int)SymbolInfoInteger(sym,SYMBOL_DIGITS)));
   }
   else
      Print("PERSONAL FX GRID [",sym,"]: Add FAILED [",trade.ResultRetcode(),"] ",
            trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
//|  BROKER-SIDE TP SYNC  (v5.0 fixed: clamp, always restamp)         |
//|  Puts a real TP price on every position so it shows in the MT5    |
//|  T/P column (desktop + mobile).                                   |
//|   1 trade  : TP price worth  Grid_TP_Dollar x (lot/0.01)          |
//|   2+ trades: ONE common TP price on ALL legs = basket average     |
//|              price shifted so the whole basket nets a flat        |
//|              Grid_BasketTP_Dollar                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|  PROFIT LOCK (v6.0 - chalta hua)                                  |
//|  profit >= Lock_Start_Dollar -> pakka = (profit 10c tak neeche)   |
//|            - Lock_Gap_Dollar: +$1 -> +$0.50, +$1.10 -> +$0.60 ...  |
//|  1 trade : sab $ x (lot/0.01) | 2+ legs: basket flat, ONE SL      |
//|  SL only ever moves in the profit direction (never back).         |
//|  TP is left exactly as SyncTPLevels set it.                       |
//+------------------------------------------------------------------+
void ApplyProfitLock(string sym, int cnt, double totalPL)
{
   if(cnt<=0) return;

   double V=0, W=0, swapSum=0;
   int dir=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      int d = (posInfo.PositionType()==POSITION_TYPE_BUY) ? 1 : -1;
      if(dir==0) dir=d;
      else if(dir!=d) return;                    // mixed directions -> leave alone
      V       += posInfo.Volume();
      W       += posInfo.Volume()*posInfo.PriceOpen();
      swapSum += posInfo.Swap();
   }
   if(V<=0 || dir==0) return;

   double scale   = (cnt==1) ? (V/0.01) : 1.0;   // basket = flat
   bool   gold    = (StringFind(sym,"XAU")==0 || StringFind(sym,"GOLD")>=0);
   double lStart  = gold ? Gold_Lock_Start : Lock_Start_Dollar;
   double lGap    = gold ? Gold_Lock_Gap   : Lock_Gap_Dollar;
   double lStep   = gold ? Gold_Lock_Step  : Lock_Step_Dollar;
   if(lGap<=0 || lStep<=0) return;
   double pl1     = totalPL/scale;               // profit $ (0.01 lot pe / basket flat)
   if(pl1 < lStart-1e-6) return;                 // not there yet
   double lockUsd = (MathFloor(pl1/lStep+1e-6)*lStep - lGap)*scale;   // +$1.00 -> 0.50, +$1.10 -> 0.60 ...
   if(lockUsd <= 0) return;

   double k = ProfitPerPriceUnitPerLot(sym);
   if(k<=0) return;
   int    digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt     = SymbolInfoDouble(sym, SYMBOL_POINT);
   double avg    = W/V;
   double dist   = (lockUsd - swapSum)/(k*V);
   double slPx   = NormalizeDouble((dir==1) ? avg+dist : avg-dist, digits);

   // broker minimum distance: SL must sit on the right side of the live price
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double minD = (double)MathMax(SymbolInfoInteger(sym,SYMBOL_TRADE_STOPS_LEVEL),
                                 SymbolInfoInteger(sym,SYMBOL_TRADE_FREEZE_LEVEL))*pt + pt;
   if(dir==1  && slPx > bid-minD) return;        // too close right now -> try next tick
   if(dir==-1 && slPx < ask+minD) return;

   bool changed=false;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      double cur = posInfo.StopLoss();
      bool better = (cur==0) || (dir==1 ? slPx > cur+pt/2 : slPx < cur-pt/2);
      if(!better) continue;                      // already locked same or better
      if(trade.PositionModify(posInfo.Ticket(), slPx, posInfo.TakeProfit()))
         changed=true;
      else
         Print("PERSONAL FX LOCK: modify failed ",sym," #",posInfo.Ticket(),
               " [",trade.ResultRetcode(),"] ",trade.ResultRetcodeDescription());
   }
   if(changed)
   {
      string m = sym+" "+(dir==1?"BUY":"SELL")+" x"+IntegerToString(cnt)+" -> SL "+DoubleToString(slPx,digits)
                 +" | +$"+DoubleToString(lockUsd,2)+" pakka";
      Print("PERSONAL FX LOCK: ", m);
      if(UsePushNotify) SendNotification("PERSONAL FX LOCK: "+m);
   }
}

double ProfitPerPriceUnitPerLot(string sym)
{
   double pt    = SymbolInfoDouble(sym, SYMBOL_POINT);
   double price = SymbolInfoDouble(sym, SYMBOL_BID);
   if(pt<=0 || price<=0) return 0;
   double delta = pt*100.0;
   double p=0;
   if(OrderCalcProfit(ORDER_TYPE_BUY, sym, 1.0, price, price+delta, p) && p>0)
      return p/delta;
   double tv = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(sym, SYMBOL_TRADE_TICK_SIZE);
   if(ts>0 && tv>0) return tv/ts;
   return 0;
}

// v5.8: one grid step as a PRICE distance for this pair
//   Grid_Gap_Usd > 0 : the move that loses Grid_Gap_Usd on 0.01 lot (gold $5 -> 5.00, GBPUSD -> 0.0050)
//   Grid_Gap_Usd = 0 : old raw-price Grid_Gap_Price
double GridGapDistance(string sym)
{
   if(Grid_Gap_Usd > 0)
   {
      double k = ProfitPerPriceUnitPerLot(sym);          // $ per 1.0 price per 1.00 lot
      if(k > 0) return Grid_Gap_Usd / (k*0.01);
   }
   return Grid_Gap_Price;
}

void SyncTPLevels(string sym, int cnt)
{
   if(cnt<=0) return;

   double V=0, W=0, swapSum=0;
   int    dir=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      int d = (posInfo.PositionType()==POSITION_TYPE_BUY) ? 1 : -1;
      if(dir==0) dir=d;
      else if(dir!=d) return;              // mixed directions -> don't touch TP
      V       += posInfo.Volume();
      W       += posInfo.Volume()*posInfo.PriceOpen();
      swapSum += posInfo.Swap();
   }
   if(V<=0 || dir==0) return;

   double target = (cnt==1) ? Grid_TP_Dollar*(V/0.01) : Grid_BasketTP_Dollar;
   double k = ProfitPerPriceUnitPerLot(sym);
   if(k<=0) return;

   double avg    = W/V;
   double dist   = (target - swapSum)/(k*V);
   int    digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt     = SymbolInfoDouble(sym, SYMBOL_POINT);
   double tpPrice = NormalizeDouble((dir==1) ? avg+dist : avg-dist, digits);

   // Respect the broker's minimum stop distance — CLAMP, never skip.
   // (Skipping used to "freeze" older legs at a stale TP once the grid grew
   //  large enough that the true target price sat inside this distance.)
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double minDist = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*pt + 2*pt;
   if(dir==1)
   {
      double floorPx = NormalizeDouble(bid + minDist, digits);
      if(tpPrice < floorPx) tpPrice = floorPx;
   }
   else
   {
      double ceilPx = NormalizeDouble(ask - minDist, digits);
      if(tpPrice > ceilPx) tpPrice = ceilPx;
   }

   // Always (re)stamp EVERY leg to the SAME fresh price — no tolerance-skip,
   // so every leg of the same pair shows one identical, current TP.
   bool changed=false; bool anyFail=false;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      if(posInfo.TakeProfit()==tpPrice) continue;   // already exactly set
      if(trade.PositionModify(posInfo.Ticket(), posInfo.StopLoss(), tpPrice))
         changed=true;
      else
      {
         anyFail=true;
         Print("PERSONAL FX TP: modify failed ",sym," #",posInfo.Ticket(),
               " [",trade.ResultRetcode(),"] ",trade.ResultRetcodeDescription());
      }
   }
   if(changed)
      Print("PERSONAL FX TP: ",sym," ",(dir==1?"BUY":"SELL")," x",cnt,
            " -> TP ",DoubleToString(tpPrice,digits),
            " (target $",DoubleToString(target,2),")",
            anyFail ? " [some legs failed, see above]" : "");
}

//+------------------------------------------------------------------+
//|  v7.0 STRATEGY 2 - har trade alag: SL -$S2_SL_Usd, TP $Grid_TP,  |
//|  profit lock (wahi Lock_* inputs). Sab $ x (lot/0.01).            |
//|  Broker pe asli SL/TP lagta hai; software backup bhi (band karta).|
//|  SL sirf aage (profit ki taraf) khisakta hai, kabhi peeche nahi.  |
//+------------------------------------------------------------------+
void S2ManageSymbol(string sym, double tp1, double sl1, bool lockOn)   // v7.1: tp1 / sl1 = $ per 0.01 lot
{
   double k = ProfitPerPriceUnitPerLot(sym);
   if(k<=0) return;
   int    digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt     = SymbolInfoDouble(sym, SYMBOL_POINT);
   double bid    = SymbolInfoDouble(sym, SYMBOL_BID);
   double ask    = SymbolInfoDouble(sym, SYMBOL_ASK);
   if(bid<=0 || ask<=0) return;
   double minD   = (double)MathMax(SymbolInfoInteger(sym,SYMBOL_TRADE_STOPS_LEVEL),
                                   SymbolInfoInteger(sym,SYMBOL_TRADE_FREEZE_LEVEL))*pt + 2*pt;
   bool   gold   = (StringFind(sym,"XAU")==0 || StringFind(sym,"GOLD")>=0);
   double lStart = gold ? Gold_Lock_Start : Lock_Start_Dollar;
   double lGap   = gold ? Gold_Lock_Gap   : Lock_Gap_Dollar;
   double lStep  = gold ? Gold_Lock_Step  : Lock_Step_Dollar;

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      ulong  tk    = posInfo.Ticket();
      double vol   = posInfo.Volume();
      if(vol<=0) continue;
      int    dir   = (posInfo.PositionType()==POSITION_TYPE_BUY) ? 1 : -1;
      double open  = posInfo.PriceOpen();
      double swap  = posInfo.Swap();
      double scale = vol/0.01;
      double pl    = posInfo.Profit()+swap;
      double tpUsd = tp1*scale;
      double slUsd = sl1*scale;

      // software backup: TP / SL broker pe na laga ho ya slip ho to bhi band
      if(pl >= tpUsd || (sl1>0 && pl <= -slUsd))
      {
         if(trade.PositionClose(tk))
         {
            string m = sym+" "+(dir==1?"BUY":"SELL")+" band "+(pl>=0?"+$":"-$")+DoubleToString(MathAbs(pl),2)+(pl>=tpUsd?" (TP)":" (SL)");
            Print("PERSONAL FX S2: ", m);
            if(UsePushNotify) SendNotification("PERSONAL FX S2: "+m);
         }
         continue;
      }

      // chahiye wala SL: -$S2_SL ya profit lock (jo zyada achha)
      double want = 0;
      if(sl1>0) want = NormalizeDouble(open + dir*(-slUsd - swap)/(k*vol), digits);
      double lockUsd = 0;
      if(lockOn && UseProfitLock && lGap>0 && lStep>0)
      {
         double pl1 = pl/scale;
         if(pl1 >= lStart-1e-6)
         {
            lockUsd = (MathFloor(pl1/lStep+1e-6)*lStep - lGap)*scale;
            if(lockUsd > 0)
            {
               double lockPx = NormalizeDouble(open + dir*(lockUsd - swap)/(k*vol), digits);
               if(want==0 || (dir==1 ? lockPx > want : lockPx < want)) want = lockPx;
            }
         }
      }
      double tpPx = NormalizeDouble(open + dir*(tpUsd - swap)/(k*vol), digits);
      // broker ki min doori: TP clamp, SL bahut paas ho to agle tick
      if(dir==1){ double f = NormalizeDouble(bid+minD, digits); if(tpPx < f) tpPx = f; }
      else      { double c = NormalizeDouble(ask-minD, digits); if(tpPx > c) tpPx = c; }
      double cur = posInfo.StopLoss(), newSL = cur;
      if(want>0)
      {
         bool better = (cur==0) || (dir==1 ? want > cur+pt/2 : want < cur-pt/2);
         bool fits   = (dir==1) ? (want < bid-minD) : (want > ask+minD);
         if(better && fits) newSL = want;
      }
      double curTP = posInfo.TakeProfit();
      bool tpDiff = (curTP==0) || MathAbs(curTP - tpPx) > pt/2;
      if(newSL==cur && !tpDiff) continue;
      if(trade.PositionModify(tk, newSL, tpPx))
      {
         if(newSL!=cur)
         {
            string m = sym+" "+(dir==1?"BUY":"SELL")+" -> SL "+DoubleToString(newSL,digits)
                       +(lockUsd>0 && newSL==want ? " | +$"+DoubleToString(lockUsd,2)+" pakka" : " | -$"+DoubleToString(slUsd,2)+" SL");
            Print("PERSONAL FX S2: ", m);
            if(UsePushNotify && lockUsd>0 && newSL==want) SendNotification("PERSONAL FX LOCK: "+m);
         }
      }
      else
         Print("PERSONAL FX S2: modify failed ",sym," #",tk," [",trade.ResultRetcode(),"] ",trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//|  v7.5 STRATEGY 4 - Strategy 3 jaisa scalp + RECOVERY               |
//|  Baaki ghata (aaj, server din): har loss jodo, uske baad ki har    |
//|  jeet ghatao (0 se neeche nahi). > 0 = recovery chalu.             |
//|  Recovery me "abhi yogya" trade (umar <= S4_FastMin, 15m ADX >=    |
//|  S4_AdxMin): broker TP $0.50 par; +$0.25 chhoote hi SL +$0.10,     |
//|  +$0.30 par SL +$0.20. Yogya nahi -> aam $0.25 TP. Jis trade ka SL |
//|  profit me hai = "badhaya hua" (restart ke baad bhi pehchan).      |
//+------------------------------------------------------------------+
double   g_S4Debt = 0;
datetime g_S4DebtAt = 0;
string   g_S4AdxSym[]; int g_S4AdxH[];
double S4Debt()
{
   if(TimeLocal() - g_S4DebtAt < 2 && g_S4DebtAt > 0) return g_S4Debt;
   g_S4DebtAt = TimeLocal();
   long ns = (long)TimeTradeServer();
   datetime d0 = (datetime)(ns - ns % 86400);
   double debt = 0;
   if(HistorySelect(d0, (datetime)(ns + 3600)))
   {
      int n = HistoryDealsTotal();
      for(int i=0;i<n;i++)                                   // puraane se naye
      {
         ulong d = HistoryDealGetTicket(i);
         if(d==0) continue;
         long ty = HistoryDealGetInteger(d, DEAL_TYPE);
         if(ty!=DEAL_TYPE_BUY && ty!=DEAL_TYPE_SELL) continue;
         long en = HistoryDealGetInteger(d, DEAL_ENTRY);
         if(en!=DEAL_ENTRY_OUT && en!=DEAL_ENTRY_OUT_BY) continue;
         if(!IsAllowedSymbol(HistoryDealGetString(d, DEAL_SYMBOL))) continue;
         ulong pid = (ulong)HistoryDealGetInteger(d, DEAL_POSITION_ID);    // v7.6: candle (S5) trade recovery me nahi
         if(pid>0 && StringFind(HistoryOrderGetString(pid, ORDER_COMMENT),"PFXN")==0) continue;
         double p = HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) + HistoryDealGetDouble(d, DEAL_COMMISSION);
         if(p < 0) debt += -p;
         else if(debt > 0) debt = MathMax(0.0, debt - p);
      }
   }
   g_S4Debt = debt;
   return debt;
}
double S4Adx(string sym)
{
   int h = INVALID_HANDLE;
   for(int i=0;i<ArraySize(g_S4AdxSym);i++) if(g_S4AdxSym[i]==sym){ h = g_S4AdxH[i]; break; }
   if(h == INVALID_HANDLE)
   {
      h = iADX(sym, PERIOD_M15, 14);
      int n = ArraySize(g_S4AdxSym);
      ArrayResize(g_S4AdxSym, n+1); ArrayResize(g_S4AdxH, n+1);
      g_S4AdxSym[n] = sym; g_S4AdxH[n] = h;
   }
   if(h == INVALID_HANDLE) return -1;
   double b[];
   if(CopyBuffer(h, 0, 1, 1, b) != 1) return -1;             // aakhri band 15m candle ka ADX
   return b[0];
}
void S4ManageSymbol(string sym)
{
   double k = ProfitPerPriceUnitPerLot(sym);
   if(k<=0) return;
   int    digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt     = SymbolInfoDouble(sym, SYMBOL_POINT);
   double bid    = SymbolInfoDouble(sym, SYMBOL_BID);
   double ask    = SymbolInfoDouble(sym, SYMBOL_ASK);
   if(bid<=0 || ask<=0) return;
   double minD   = (double)MathMax(SymbolInfoInteger(sym,SYMBOL_TRADE_STOPS_LEVEL),
                                   SymbolInfoInteger(sym,SYMBOL_TRADE_FREEZE_LEVEL))*pt + 2*pt;
   bool   recov  = (S4Debt() > 0.005);
   double adx    = -2;                                        // -2 = abhi poochha nahi

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      ulong  tk    = posInfo.Ticket();
      double vol   = posInfo.Volume();
      if(vol<=0) continue;
      int    dir   = (posInfo.PositionType()==POSITION_TYPE_BUY) ? 1 : -1;
      double open  = posInfo.PriceOpen();
      double swap  = posInfo.Swap();
      double scale = vol/0.01;
      double pl    = posInfo.Profit()+swap;
      double tpUsd = S4_TP_Usd*scale, slUsd = S4_SL_Usd*scale, bigUsd = S4_BigTP_Usd*scale;
      double curSL = posInfo.StopLoss(), curTP = posInfo.TakeProfit();
      string side  = (dir==1?"BUY":"SELL");
      // SL lagne par kitna milega ($); > 0 = ye trade "badhaya hua" hai
      double slGain = (curSL>0) ? dir*(curSL-open)*k*vol + swap : -1e9;
      bool   ext    = (slGain > 0.004*scale);

      // software backup: SL
      if(S4_SL_Usd>0 && pl <= -slUsd)
      {
         if(trade.PositionClose(tk))
         {
            string m = sym+" "+side+" band -$"+DoubleToString(MathAbs(pl),2)+" (SL)";
            Print("PERSONAL FX S4: ", m);
            if(UsePushNotify) SendNotification("PERSONAL FX S4: "+m);
            g_S4DebtAt = 0;
         }
         continue;
      }

      if(ext)                                                 // ---- badhaya hua trade: TP $0.50, lock +$0.20 ----
      {
         if(pl >= bigUsd)
         {
            if(trade.PositionClose(tk))
            {
               string m = sym+" "+side+" band +$"+DoubleToString(pl,2)+" (RECOVERY TP)";
               Print("PERSONAL FX S4: ", m);
               if(UsePushNotify) SendNotification("PERSONAL FX S4: "+m);
               g_S4DebtAt = 0;
            }
            continue;
         }
         double newSL = curSL;
         if(pl >= S4_LockAt_Usd*scale)
         {
            double lockPx = NormalizeDouble(open + dir*(S4_LockTo_Usd*scale - swap)/(k*vol), digits);
            bool better = (dir==1 ? lockPx > curSL+pt/2 : lockPx < curSL-pt/2);
            bool fits   = (dir==1) ? (lockPx < bid-minD) : (lockPx > ask+minD);
            if(better && fits) newSL = lockPx;
         }
         double bigPx = NormalizeDouble(open + dir*(bigUsd - swap)/(k*vol), digits);
         if(dir==1){ double f = NormalizeDouble(bid+minD, digits); if(bigPx < f) bigPx = f; }
         else      { double c = NormalizeDouble(ask-minD, digits); if(bigPx > c) bigPx = c; }
         bool tpDiff = (curTP==0) || MathAbs(curTP - bigPx) > pt/2;
         if(newSL!=curSL || tpDiff)
         {
            if(trade.PositionModify(tk, newSL, bigPx))
            {
               if(newSL!=curSL)
               {
                  string m = sym+" "+side+" +$"+DoubleToString(S4_LockTo_Usd*scale,2)+" pakka (recovery, TP $"+DoubleToString(bigUsd,2)+")";
                  Print("PERSONAL FX S4: ", m);
                  if(UsePushNotify) SendNotification("PERSONAL FX S4 LOCK: "+m);
               }
            }
         }
         continue;
      }

      // ---- aam trade ----
      // recovery ke liye "abhi yogya"? (tez: umar <= S4_FastMin; mazboot: 15m ADX >= S4_AdxMin)
      bool elig = false;
      if(recov && S4_BigTP_Usd > S4_TP_Usd)
      {
         long ageMin = (long)(TimeCurrent() - posInfo.Time())/60;
         bool fast = (S4_FastMin<=0 || ageMin <= S4_FastMin);
         bool strong = true;
         if(fast && S4_AdxMin>0)
         {
            if(adx < -1) adx = S4Adx(sym);
            strong = (adx >= S4_AdxMin);
         }
         elig = (fast && strong);
      }

      if(pl >= tpUsd)
      {
         if(elig)
         {
            double keep  = (pl >= S4_LockAt_Usd*scale) ? S4_LockTo_Usd*scale : MathMax(0.01*scale, S4_PreLock_Usd*scale);
            double slPx  = NormalizeDouble(open + dir*(keep - swap)/(k*vol), digits);
            double bigPx = NormalizeDouble(open + dir*(bigUsd - swap)/(k*vol), digits);
            bool slFits  = (dir==1) ? (slPx < bid-minD) : (slPx > ask+minD);
            bool tpFits  = (dir==1) ? (bigPx > bid+minD) : (bigPx < ask-minD);
            if(slFits && tpFits && trade.PositionModify(tk, slPx, bigPx))
            {
               string m = sym+" "+side+" RECOVERY: $"+DoubleToString(tpUsd,2)+" par band nahi - TP $"+DoubleToString(bigUsd,2)+", +$"+DoubleToString(keep,2)+" pakka (baaki ghata $"+DoubleToString(S4Debt(),2)+")";
               Print("PERSONAL FX S4: ", m);
               if(UsePushNotify) SendNotification("PERSONAL FX S4: "+m);
               continue;
            }
         }
         if(trade.PositionClose(tk))                          // aam TP (ya badhana na ho paya)
         {
            string m = sym+" "+side+" band +$"+DoubleToString(pl,2)+" (TP)";
            Print("PERSONAL FX S4: ", m);
            if(UsePushNotify) SendNotification("PERSONAL FX S4: "+m);
            g_S4DebtAt = 0;
         }
         continue;
      }

      // broker par SL -$S4_SL aur TP: yogya ho to $0.50 (taaki broker $0.25 par band na kare), warna $0.25
      double wantSL = (S4_SL_Usd>0) ? NormalizeDouble(open + dir*(-slUsd - swap)/(k*vol), digits) : 0;
      double wantTP = NormalizeDouble(open + dir*((elig ? bigUsd : tpUsd) - swap)/(k*vol), digits);
      if(dir==1){ double f = NormalizeDouble(bid+minD, digits); if(wantTP < f) wantTP = f; }
      else      { double c = NormalizeDouble(ask-minD, digits); if(wantTP > c) wantTP = c; }
      double newSL = curSL;
      if(wantSL>0)
      {
         bool better = (curSL==0) || (dir==1 ? wantSL > curSL+pt/2 : wantSL < curSL-pt/2);
         bool fits   = (dir==1) ? (wantSL < bid-minD) : (wantSL > ask+minD);
         if(better && fits) newSL = wantSL;
      }
      bool tpDiff = (curTP==0) || MathAbs(curTP - wantTP) > pt/2;
      if(newSL==curSL && !tpDiff) continue;
      if(!trade.PositionModify(tk, newSL, wantTP))
         Print("PERSONAL FX S4: modify failed ",sym," #",tk," [",trade.ResultRetcode(),"] ",trade.ResultRetcodeDescription());
   }
}


//+------------------------------------------------------------------+
//|  v7.7 STRATEGY 6 - HEDGE LADDER                                   |
//|  MAIN = pair ka sabse purana trade (hedge nahi). HEDGE = EA ka    |
//|  ulti disha ka trade, comment "PFX6H".                            |
//|  1) koi hedge nahi: main TP $S6_TP x (lot/0.01) broker pe + backup |
//|  2) main se / sabse door hedge se $S6_Gap (0.01 lot pe) ulti chaal |
//|     -> naya hedge S6_HedgeLot                                     |
//|  3) hedge khule: main ka broker TP hata. Sab milake:              |
//|     main ghate me -> +$S6_BasketTP | main faayde me -> +$S6_CycleTP|
//|     -> main + saare hedge band                                    |
//|  4) aakhri 2 hedge MILAKE lock; baaki har hedge AKELA lock:       |
//|     +$S6_Lock se upar gaya, wapas +$S6_Lock par aaya -> band.     |
//|     Jodi band hone ke baad (naya hedge khulne tak) sab akele.     |
//+------------------------------------------------------------------+
bool S6IsHedge()
{
   return (posInfo.Magic()==MagicNumber && StringFind(PosComment(),"PFX6H")==0);
}

string S6Gv(string what, string sym) { return "PFX6"+what+"_"+IntegerToString(MagicNumber)+"_"+sym; }

double S6GvGet(string name) { return GlobalVariableCheck(name) ? GlobalVariableGet(name) : 0; }

ulong g_S6ActAt = 0;                                            // v8.9: aakhri trade action (ms)
void S6Push(string m)
{
   Print(m);
   if(UsePushNotify) SendNotification(m);
   g_S6ActAt = GetTickCount64();                                 // v8.9: abhi trade hua - app ka data thoda ruke
   if(StringFind(m,"nahi laga")>=0 || StringFind(m,"nahi khula")>=0) S6LvErr(m);   // v9.0: margin / max trades
   S6LvEvent(m);                                                 // v8.7: app ke events me bhi (v8.9: queue)
}

//+------------------------------------------------------------------+
//|  v8.7 S6 LIVE APP - Firebase /personalfx/s6live/<key>/...         |
//+------------------------------------------------------------------+
string   g_LvSym[30]; ulong g_LvMain[30]; long g_LvStart[30]; double g_LvMinTot[30];
int      g_LvHedges[30]; string g_LvWhy[30]; datetime g_LvWhyAt[30]; ulong g_LvPushAt[30];
int      g_LvDir[30]; double g_LvLot[30], g_LvOpen[30]; int g_LvN = 0; ulong g_LvHbAt = 0; ulong g_LvLogAt[30];

bool S6LiveBase()                                                // v9.0: app tak bhejna mumkin (Strategy kuch bhi)
{
   return (S6_LiveOn && UseAppBridge && FirebaseURL!="" && S6_LiveKey!="" && !MQLInfoInteger(MQL_TESTER));
}
bool S6LiveOK()
{
   return (S6LiveBase() && Strategy==STRAT_6_HEDGE);
}
// v9.0: aakhri 20 galti + aakhri 30 HAAL (sirf yaad - hb ke saath app ko)
string g_ErrM[20]; long g_ErrT[20]; int g_ErrN = 0, g_ErrPos = 0;
string g_HaalJ[30]; int g_HaalN = 0, g_HaalPos = 0;
void S6LvErr(string m)
{
   g_ErrM[g_ErrPos] = m; g_ErrT[g_ErrPos] = (long)TimeGMT()*1000;
   g_ErrPos = (g_ErrPos+1) % 20; if(g_ErrN < 20) g_ErrN++;
}
void S6LvHaal(string sym, double tot, double real, double net, int hn)
{
   g_HaalJ[g_HaalPos] = "{\"t\":"+IntegerToString((long)TimeGMT()*1000)+",\"s\":\""+sym+"\",\"o\":"+DoubleToString(tot,2)+",\"b\":"+DoubleToString(real,2)
                      +",\"n\":"+DoubleToString(net,2)+",\"h\":"+IntegerToString(hn)+"}";
   g_HaalPos = (g_HaalPos+1) % 30; if(g_HaalN < 30) g_HaalN++;
}
string S6LvKey(string k)                                         // Firebase key me . $ # [ ] / nahi chalte
{
   string bad = ".$#[]/ "; for(int i=0; i<StringLen(bad); i++) StringReplace(k, StringSubstr(bad,i,1), "_");
   return k;
}
string S6LvUrl(string path) { return AppUrl("s6live/"+S6LvKey(S6_LiveKey)+"/"+path); }
string S6N(double v, int dg) { return DoubleToString(v, dg); }
int S6LvIdx(string sym, bool create)
{
   for(int i=0; i<g_LvN; i++) if(g_LvSym[i]==sym) return i;
   if(!create || g_LvN>=30) return -1;
   g_LvSym[g_LvN]=sym; g_LvMain[g_LvN]=0; g_LvStart[g_LvN]=0; g_LvMinTot[g_LvN]=0; g_LvHedges[g_LvN]=0;
   g_LvWhy[g_LvN]=""; g_LvWhyAt[g_LvN]=0; g_LvPushAt[g_LvN]=0; g_LvLogAt[g_LvN]=0; g_LvDir[g_LvN]=0; g_LvLot[g_LvN]=0; g_LvOpen[g_LvN]=0;
   return g_LvN++;
}
void S6LvWhy(string sym, string why)                             // EA ne cycle kis niyam se band kiya
{
   int i = S6LvIdx(sym, true); if(i<0) return;
   g_LvWhy[i] = why; g_LvWhyAt[i] = TimeCurrent();
}
// v8.9: koi bhi Firebase likhna yahan sirf QUEUE me - asli bhejna S6LvFlush (OnTimer ke aakhir) se
string g_QPath[40], g_QBody[40]; int g_QN = 0;
string g_EvQ = ""; int g_EvN = 0, g_EvSeq = 0; ulong g_EvAt = 0;
void S6LvPut(string path, string body)
{
   if(!S6LiveBase()) return;
   for(int q=0; q<g_QN; q++) if(g_QPath[q]==path){ g_QBody[q] = body; return; }   // wahi path - naya data
   if(g_QN >= 40){ for(int q=1; q<g_QN; q++){ g_QPath[q-1]=g_QPath[q]; g_QBody[q-1]=g_QBody[q]; } g_QN--; }
   g_QPath[g_QN] = path; g_QBody[g_QN] = body; g_QN++;
}
void S6LvEvent(string m)
{
   if(!S6LiveOK()) return;
   long ms = (long)TimeGMT()*1000;
   string k = "e"+IntegerToString(ms)+"_"+IntegerToString(g_EvSeq++ % 1000);
   if(g_EvN >= 60) { g_EvQ = ""; g_EvN = 0; }                   // bahut jama - purane chhodo
   g_EvQ += (g_EvN++ ? "," : "") + "\""+k+"\":{\"t\":"+IntegerToString(ms)+",\"m\":\""+AppJsonSafe(m)+"\"}";
}
// OnTimer ke aakhir: ek baar me sirf EK request, aur trade action ke 1.5 sec baad hi
void S6LvFlush()
{
   if(!S6LiveBase()) return;
   ulong now = GetTickCount64();
   if(g_S6ActAt != 0 && now - g_S6ActAt < 1500) return;
   string resp; int code;
   if(g_EvN > 0 && (g_EvN >= 10 || g_EvAt == 0 || now - g_EvAt >= 10000))
   {
      g_EvAt = now;
      AppHttp("POST", S6LvUrl("events"), "{"+g_EvQ+"}", "X-HTTP-Method-Override: PATCH\r\n", resp, code);
      g_EvQ = ""; g_EvN = 0;
      return;
   }
   if(g_QN > 0)
   {
      string p = g_QPath[0], b = g_QBody[0];
      for(int q=1; q<g_QN; q++){ g_QPath[q-1]=g_QPath[q]; g_QBody[q-1]=g_QBody[q]; }
      g_QN--;
      AppHttp("POST", S6LvUrl(p), b, "X-HTTP-Method-Override: PUT\r\n", resp, code);
   }
}
void S6LvHedgeFilled(string sym) { int i = S6LvIdx(sym, false); if(i>=0) g_LvHedges[i]++; }

// har 30 sec: EA chalu hai + balance / equity
void S6LvHeartbeat()
{
   if(!S6LiveBase()) return;
   ulong now = GetTickCount64();
   if(g_LvHbAt!=0 && now - g_LvHbAt < 15000) return;
   g_LvHbAt = now;
   string er = "";
   for(int e=0; e<g_ErrN; e++){ int ix = (g_ErrPos - 1 - e + 20) % 20; er += (e>0?",":"")+"{\"t\":"+IntegerToString(g_ErrT[ix])+",\"m\":\""+AppJsonSafe(g_ErrM[ix])+"\"}"; }
   string hl = "";
   for(int e=0; e<g_HaalN; e++){ int ix = (g_HaalPos - 1 - e + 30) % 30; hl += (e>0?",":"")+g_HaalJ[ix]; }
   string body = "{\"at\":"+IntegerToString((long)TimeGMT()*1000)+",\"v\":\"10.2\",\"strat\":"+IntegerToString((int)Strategy)
               +",\"ta\":"+(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)?"true":"false")+",\"ea\":"+(MQLInfoInteger(MQL_TRADE_ALLOWED)?"true":"false")
               +",\"conn\":"+(TerminalInfoInteger(TERMINAL_CONNECTED)?"true":"false")+",\"ping\":"+IntegerToString((int)(TerminalInfoInteger(TERMINAL_PING_LAST)/1000))
               +",\"ml\":"+S6N(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL),1)+",\"fm\":"+S6N(AccountInfoDouble(ACCOUNT_MARGIN_FREE),2)
               +",\"liveOn\":"+(S6_LiveOn?"true":"false")+",\"push\":"+IntegerToString(S6_LivePushSec)+",\"manual\":"+(ManageManualTrades?"true":"false")
               +",\"errs\":["+er+"],\"haal\":["+hl+"]"
               +",\"bal\":"+S6N(AccountInfoDouble(ACCOUNT_BALANCE),2)
               +",\"eq\":"+S6N(AccountInfoDouble(ACCOUNT_EQUITY),2)+",\"cur\":\""+AccountInfoString(ACCOUNT_CURRENCY)+"\",\"demo\":"
               +((AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_REAL)?"false":"true")
               +",\"cfg\":{\"tp\":"+S6N(S6_TP_Usd,2)+",\"gap\":"+S6N(S6_Gap_Usd,2)+",\"hlot\":"+S6N(S6_HedgeLot,2)+",\"basket\":"+S6N(S6_BasketTP_Usd,2)
               +",\"cycle\":"+S6N(S6_CycleTP_Usd,2)+",\"net\":"+S6N(S6_CycleNetUsd,2)+",\"sl\":"+S6N(S6_BasketSL_Usd,2)+",\"lock\":"+S6N(S6_LockUsd,2)
               +",\"arm\":"+S6N(MathMax(S6_LockUsd,S6_LockArmUsd),2)+",\"ahead\":"+IntegerToString(S6_PendingAhead)+",\"b2\":"+(S6_SecondBuyOn?"1":"0")+"}}";
   S6LvPut("hb", body);
}

// har S6ManageSymbol pass par (main ho to): cycle track + har few sec live
void S6LvLive(string sym, ulong mTk, int mDir, double mOpen, double mVol, double mPL, double mTP, long mMs,
              ulong &hTk[], double &hOpen[], double &hPL[], double &hVol[], int hn, double sumH, double total)
{
   if(!S6LiveOK() || mTk==0) return;
   int i = S6LvIdx(sym, true); if(i<0) return;
   if(g_LvMain[i]!=mTk)
   {
      if(g_LvMain[i]!=0) S6LvFinalize(i);                        // pichla cycle (agar band hua) pehle likho
      g_LvMain[i]=mTk; g_LvStart[i]=mMs; g_LvMinTot[i]=0; g_LvHedges[i]=hn; g_LvDir[i]=mDir; g_LvLot[i]=mVol; g_LvOpen[i]=mOpen; g_LvWhy[i]="";
      S6LvEvent("PERSONAL FX S6: naya cycle "+sym+" "+(mDir==1?"BUY":"SELL")+" "+DoubleToString(mVol,2)+" @ "+DoubleToString(mOpen,(int)SymbolInfoInteger(sym,SYMBOL_DIGITS)));
      g_LvPushAt[i]=0;
   }
   if(total < g_LvMinTot[i]) g_LvMinTot[i] = total;
   ulong now = GetTickCount64();
   if(g_LvPushAt[i]!=0 && now - g_LvPushAt[i] < (ulong)MathMax(1,S6_LivePushSec)*1000) return;
   g_LvPushAt[i] = now;
   int    dg   = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double k    = ProfitPerPriceUnitPerLot(sym);
   double gap  = (k>0 && S6_Gap_Usd>0) ? S6_Gap_Usd/(k*0.01) : 0;
   double real = S6Realized(sym, (datetime)(mMs/1000) - 5);
   string hs = "";
   for(int j=0; j<hn; j++)
   {
      int lv = S6Slot(hTk[j], hOpen[j], mOpen, mDir, gap);
      bool ar = (S6GvGet("PFX6A_"+IntegerToString((long)hTk[j]))==1);
      hs += (j?",":"")+"{\"n\":"+IntegerToString(lv)+",\"o\":"+S6N(hOpen[j],dg)+",\"pl\":"+S6N(hPL[j],2)+",\"lot\":"+S6N(hVol[j],2)+",\"a\":"+(ar?"1":"0")+"}";
   }
   string ps = ""; int np = 0;
   for(int o=OrdersTotal()-1; o>=0; o--)
   {
      ulong ot = OrderGetTicket(o); if(ot==0) continue;
      if(OrderGetString(ORDER_SYMBOL)!=sym || OrderGetInteger(ORDER_MAGIC)!=MagicNumber) continue;
      string cm = OrderGetString(ORDER_COMMENT); if(StringFind(cm,"PFX6H")!=0 || cm=="PFX6HB") continue;
      ps += (np++?",":"")+"{\"n\":"+IntegerToString((int)StringToInteger(StringSubstr(cm,5)))+",\"p\":"+S6N(OrderGetDouble(ORDER_PRICE_OPEN),dg)+"}";
   }
   string body = "{\"at\":"+IntegerToString((long)TimeGMT()*1000)+",\"state\":\"RUN\",\"sym\":\""+sym+"\",\"dg\":"+IntegerToString(dg)
      +",\"dir\":\""+(mDir==1?"BUY":"SELL")+"\",\"lot\":"+S6N(mVol,2)+",\"open\":"+S6N(mOpen,dg)+",\"tp\":"+S6N(mTP,dg)
      +",\"bid\":"+S6N(SymbolInfoDouble(sym,SYMBOL_BID),dg)+",\"ask\":"+S6N(SymbolInfoDouble(sym,SYMBOL_ASK),dg)+",\"sp\":"+S6N(SymbolInfoDouble(sym,SYMBOL_ASK)-SymbolInfoDouble(sym,SYMBOL_BID),dg)+",\"gapPx\":"+S6N(gap,dg)
      +",\"mpl\":"+S6N(mPL,2)+",\"hpl\":"+S6N(sumH,2)+",\"tot\":"+S6N(total,2)+",\"banked\":"+S6N(real,2)+",\"net\":"+S6N(real+total,2)
      +",\"dd\":"+S6N(g_LvMinTot[i],2)+",\"start\":"+IntegerToString(mMs - (long)(TimeTradeServer()-TimeGMT())*1000)+",\"nh\":"+IntegerToString(hn)+",\"used\":"+IntegerToString(g_LvHedges[i])
      +",\"bal\":"+S6N(AccountInfoDouble(ACCOUNT_BALANCE),2)+",\"eq\":"+S6N(AccountInfoDouble(ACCOUNT_EQUITY),2)
      +",\"hedges\":["+hs+"],\"pend\":["+ps+"]}";
   S6LvPut("live/"+S6LvKey(sym), body);
}

// main band ho gaya -> cycle ka hisaab likho (TP broker par laga ho, haath se band, ya EA ne)
void S6LvFinalize(int i)
{
   if(i<0 || g_LvMain[i]==0) return;
   ulong mTk = g_LvMain[i]; string sym = g_LvSym[i];
   g_LvMain[i] = 0;
   if(!S6LiveOK()) return;
   double mainPL = 0; long reason = -1; datetime endT = TimeCurrent();
   if(HistorySelectByPosition(mTk))
      for(int d=0; d<HistoryDealsTotal(); d++)
      {
         ulong dl = HistoryDealGetTicket(d); if(dl==0) continue;
         long en = HistoryDealGetInteger(dl, DEAL_ENTRY);
         if(en!=DEAL_ENTRY_OUT && en!=DEAL_ENTRY_OUT_BY) continue;
         mainPL += HistoryDealGetDouble(dl,DEAL_PROFIT)+HistoryDealGetDouble(dl,DEAL_SWAP)+HistoryDealGetDouble(dl,DEAL_COMMISSION);
         reason = HistoryDealGetInteger(dl, DEAL_REASON); endT = (datetime)HistoryDealGetInteger(dl, DEAL_TIME);
      }
   datetime st = (datetime)(g_LvStart[i]/1000);
   double hedgePL = S6Realized(sym, st - 5);
   string why = (g_LvWhy[i]!="" && TimeCurrent()-g_LvWhyAt[i] < 120) ? g_LvWhy[i]
              : reason==DEAL_REASON_TP ? "TP" : reason==DEAL_REASON_SL ? "SL" : reason==DEAL_REASON_EXPERT ? "EA"
              : (reason==DEAL_REASON_CLIENT || reason==DEAL_REASON_MOBILE || reason==DEAL_REASON_WEB) ? "HAATH SE" : "BAND";
   long off = (long)(TimeTradeServer()-TimeGMT())*1000;
   int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pl = mainPL + hedgePL;
   string body = "{\"start\":"+IntegerToString(g_LvStart[i]-off)+",\"end\":"+IntegerToString((long)endT*1000-off)+",\"sym\":\""+sym
      +"\",\"dir\":\""+(g_LvDir[i]==1?"BUY":"SELL")+"\",\"lot\":"+S6N(g_LvLot[i],2)+",\"open\":"+S6N(g_LvOpen[i],dg)
      +",\"res\":\""+AppJsonSafe(why)+"\",\"pl\":"+S6N(pl,2)+",\"mpl\":"+S6N(mainPL,2)+",\"hpl\":"+S6N(hedgePL,2)
      +",\"dd\":"+S6N(g_LvMinTot[i],2)+",\"hedges\":"+IntegerToString(g_LvHedges[i])+"}";
   S6LvPut("cycles/c"+IntegerToString((long)endT*1000-off), body);   // v8.9: queue
   S6LvPut("live/"+S6LvKey(sym), "{\"at\":"+IntegerToString((long)TimeGMT()*1000)+",\"state\":\"IDLE\",\"sym\":\""+sym+"\",\"last\":"+body+"}");
   S6LvEvent("PERSONAL FX S6: CYCLE BAND "+sym+" | "+why+" | "+(pl>=0?"+$":"-$")+DoubleToString(MathAbs(pl),2)
             +" | sabse bada DD $"+DoubleToString(g_LvMinTot[i],2)+" | hedge "+IntegerToString(g_LvHedges[i]));
}

// har pass: jiska main ab khula nahi -> cycle band likho
void S6LvCheck()
{
   S6LvHeartbeat();                                              // v9.0: Strategy 6 na ho tab bhi (app me dikhe)
   if(Strategy!=STRAT_6_HEDGE) return;
   for(int i=0; i<g_LvN; i++)
      if(g_LvMain[i]!=0 && !PositionSelectByTicket(g_LvMain[i])) S6LvFinalize(i);
}

// broker TP: open se itne $ (swap milake) par; zaroorat ho tabhi badlo
datetime g_S6TpWarn = 0, g_S6WarnMax = 0, g_S6WarnMg = 0;
void S6StampTP(ulong tk, string sym, int dir, double open, double vol, double swap, double usd, double curSL, double curTP)
{
   double k = ProfitPerPriceUnitPerLot(sym);
   if(k<=0 || vol<=0) return;
   int    digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt     = SymbolInfoDouble(sym, SYMBOL_POINT);
   double tpPx   = NormalizeDouble(open + dir*(usd - swap)/(k*vol), digits);
   if(MathAbs(curTP - tpPx) < pt*0.5) return;
   double bid = SymbolInfoDouble(sym, SYMBOL_BID), ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double minDist = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*pt + 2*pt;
   if(dir==1  && tpPx < bid + minDist) return;   // bhaav TP ke paas / paar - software backup band karega
   if(dir==-1 && tpPx > ask - minDist) return;
   if(!trade.PositionModify(tk, curSL, tpPx) && TimeCurrent()-g_S6TpWarn >= 60)
   {
      g_S6TpWarn = TimeCurrent();
      Print("PERSONAL FX S6: TP modify failed ",sym," #",tk," [",trade.ResultRetcode(),"] ",trade.ResultRetcodeDescription());
      S6LvErr("TP modify fail "+sym+" #"+IntegerToString((long)tk)+" ["+IntegerToString((int)trade.ResultRetcode())+"] "+trade.ResultRetcodeDescription());
   }
}

// v8.2: SLOT helpers - GV PFX6N_<hedge> = slot, PFX6T_<main>_<n> = trigger bhaav, PFX6S_<main>_<n> = 1 (bhaav trigger se pehle ki taraf dikha)
string S6SlotGv(string what, ulong mTk, int n) { return "PFX6"+what+"_"+IntegerToString((long)mTk)+"_"+IntegerToString(n); }

int S6Slot(ulong hTk, double hOpen, double mOpen, int mDir, double gap)
{
   string g = "PFX6N_"+IntegerToString((long)hTk);
   if(GlobalVariableCheck(g)) return (int)GlobalVariableGet(g);
   if(PositionSelectByTicket(hTk))                              // v8.3: comment "PFX6H<level>"
   {
      string c = PositionGetString(POSITION_COMMENT);
      if(StringFind(c,"PFX6H")==0 && StringLen(c)>5){ int n = (int)StringToInteger(StringSubstr(c,5)); if(n>=1) return n; }
   }
   if(gap <= 0) return 0;
   double dist = (mDir==1) ? (mOpen - hOpen) : (hOpen - mOpen);
   return (int)MathMax(1, MathRound(dist/gap));                  // purane version ka hedge: sabse paas wala slot
}

// hedge profit me band -> slot ka naya trigger = abhi ka bhaav (jahan band hua)
void S6SlotFree(ulong mTk, ulong hTk, double hOpen, double mOpen, int mDir, double gap, string sym)
{
   if(mTk==0) return;
   int n = S6Slot(hTk, hOpen, mOpen, mDir, gap);
   GlobalVariableDel("PFX6N_"+IntegerToString((long)hTk));
   if(n < 1) return;
   double px = (mDir==1) ? SymbolInfoDouble(sym, SYMBOL_BID) : SymbolInfoDouble(sym, SYMBOL_ASK);
   double L  = mOpen - mDir*n*gap;
   if(gap > 0 && ((mDir==1) ? (px < L) : (px > L)))               // v8.4: level se aage band -> usi bhaav par dobara
   {
      px = (mDir==1) ? MathMax(px, L - 0.5*gap) : MathMin(px, L + 0.5*gap);   // v8.6: aadhe gap se aage nahi
      GlobalVariableSet(S6SlotGv("T",mTk,n), px);
      GlobalVariableSet(S6SlotGv("S",mTk,n), 0);
   }
   else { GlobalVariableDel(S6SlotGv("T",mTk,n)); GlobalVariableDel(S6SlotGv("S",mTk,n)); }   // level se pehle band -> theek level
}

void S6SlotsClear(ulong mTk)
{
   GlobalVariablesDeleteAll("PFX6T_"+IntegerToString((long)mTk)+"_");
   GlobalVariablesDeleteAll("PFX6S_"+IntegerToString((long)mTk)+"_");
   GlobalVariableDel("PFX6L_"+IntegerToString((long)mTk));
}

// v7.9: is cycle (main khulne ke baad) me band hue hedge ("PFX6H") ka pakka P/L
double S6Realized(string sym, datetime from)
{
   if(!HistorySelect(from, TimeCurrent()+3600)) return 0;
   long pids[]; int np = 0;
   for(int i=HistoryOrdersTotal()-1; i>=0; i--)
   {
      ulong o = HistoryOrderGetTicket(i);
      if(o==0) continue;
      if(HistoryOrderGetString(o, ORDER_SYMBOL)!=sym) continue;
      if(HistoryOrderGetInteger(o, ORDER_MAGIC)!=MagicNumber) continue;
      if(StringFind(HistoryOrderGetString(o, ORDER_COMMENT),"PFX6H")!=0) continue;
      ArrayResize(pids, np+1); pids[np++] = HistoryOrderGetInteger(o, ORDER_POSITION_ID);
   }
   double r = 0;
   for(int i=HistoryDealsTotal()-1; i>=0; i--)
   {
      ulong dl = HistoryDealGetTicket(i);
      if(dl==0) continue;
      if(HistoryDealGetString(dl, DEAL_SYMBOL)!=sym) continue;
      long en = HistoryDealGetInteger(dl, DEAL_ENTRY);
      if(en!=DEAL_ENTRY_OUT && en!=DEAL_ENTRY_OUT_BY) continue;
      long pid = HistoryDealGetInteger(dl, DEAL_POSITION_ID);
      bool hedge = (StringFind(HistoryDealGetString(dl, DEAL_COMMENT),"PFX6H")==0);
      for(int j=0; j<np && !hedge; j++) if(pids[j]==pid) hedge = true;
      if(!hedge) continue;
      r += HistoryDealGetDouble(dl, DEAL_PROFIT) + HistoryDealGetDouble(dl, DEAL_SWAP) + HistoryDealGetDouble(dl, DEAL_COMMISSION);
   }
   return r;
}

// v8.3: is pair ke saare S6 pending (PFX6H<level>) hatao
void S6DeletePendings(string sym)
{
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      ulong ot = OrderGetTicket(i);
      if(ot==0) continue;
      if(OrderGetString(ORDER_SYMBOL)!=sym) continue;
      if(OrderGetInteger(ORDER_MAGIC)!=MagicNumber) continue;
      if(StringFind(OrderGetString(ORDER_COMMENT),"PFX6H")!=0) continue;
      trade.OrderDelete(ot);
   }
}

// v8.3: bina main ke (ya Strategy 6 band) bache S6 pending hatao - har second
void S6CleanPendings()
{
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      ulong ot = OrderGetTicket(i);
      if(ot==0) continue;
      if(OrderGetInteger(ORDER_MAGIC)!=MagicNumber) continue;
      if(StringFind(OrderGetString(ORDER_COMMENT),"PFX6H")!=0) continue;
      string sym = OrderGetString(ORDER_SYMBOL);
      bool hasMain = false;
      if(Strategy==STRAT_6_HEDGE)
         for(int p=0; p<PositionsTotal() && !hasMain; p++)
         {
            if(!posInfo.SelectByIndex(p)) continue;
            if(!IsOurPos() || posInfo.Symbol()!=sym) continue;
            if(!S6IsHedge()) hasMain = true;
         }
      if(!hasMain && OrderSelect(ot))
         if(trade.OrderDelete(ot)) Print("PERSONAL FX S6: bina main ka pending hataya ", sym, " #", ot);
   }
}

void S6ManageSymbol(string sym)
{
   ulong  mTk=0; long mMs=LONG_MAX; int mDir=0; double mOpen=0, mVol=0, mPL=0, mSwap=0, mSL=0, mTP=0;
   ulong  hTk[]; double hOpen[], hPL[], hVol[]; long hMs[]; int hn=0;
   ulong  xTk[]; int xn=0;                                   // main ke alawa haath ke trade (ek pair pe ek hi rakho)
   ulong  b2Tk=0; double b2PL=0;                             // v10.1: doosra trade (main ki disha, "PFX6HB")

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      double pl = posInfo.Profit()+posInfo.Swap();
      if(S6IsHedge() && PosComment()=="PFX6HB"){ b2Tk=posInfo.Ticket(); b2PL=pl; continue; }   // v10.1
      if(S6IsHedge())
      {
         ArrayResize(hTk,hn+1); ArrayResize(hOpen,hn+1); ArrayResize(hPL,hn+1); ArrayResize(hVol,hn+1); ArrayResize(hMs,hn+1);
         hTk[hn]=posInfo.Ticket(); hOpen[hn]=posInfo.PriceOpen(); hPL[hn]=pl; hVol[hn]=posInfo.Volume(); hMs[hn]=posInfo.TimeMsc();
         hn++;
         continue;
      }
      if(posInfo.TimeMsc() < mMs)
      {
         if(mTk!=0){ ArrayResize(xTk,xn+1); xTk[xn++]=mTk; }
         mTk=posInfo.Ticket(); mMs=posInfo.TimeMsc();
         mDir=(posInfo.PositionType()==POSITION_TYPE_BUY) ? 1 : -1;
         mOpen=posInfo.PriceOpen(); mVol=posInfo.Volume(); mPL=pl; mSwap=posInfo.Swap();
         mSL=posInfo.StopLoss(); mTP=posInfo.TakeProfit();
      }
      else { ArrayResize(xTk,xn+1); xTk[xn++]=posInfo.Ticket(); }
   }
   if(mTk==0 && hn==0 && b2Tk==0) return;

   // hedge: main ke paas se door (v8.4; main na ho to time)
   for(int a=1; a<hn; a++)
      for(int b=a; b>0 && ((mDir!=0) ? (mDir*(mOpen-hOpen[b]) < mDir*(mOpen-hOpen[b-1])) : (hMs[b]<hMs[b-1])); b--)   // v8.4: gehrai ke kram me (aakhri = sabse neeche)
      {
         ulong t=hTk[b]; hTk[b]=hTk[b-1]; hTk[b-1]=t;
         double o=hOpen[b]; hOpen[b]=hOpen[b-1]; hOpen[b-1]=o;
         double p=hPL[b];   hPL[b]=hPL[b-1];     hPL[b-1]=p;
         double v=hVol[b];  hVol[b]=hVol[b-1];   hVol[b-1]=v;
         long   m=hMs[b];   hMs[b]=hMs[b-1];     hMs[b-1]=m;
      }

   // extra haath ke trade: apna alag TP (main jaisa), hedge hisaab me nahi
   for(int x=0; x<xn; x++)
   {
      if(!posInfo.SelectByTicket(xTk[x])) continue;
      int    d   = (posInfo.PositionType()==POSITION_TYPE_BUY) ? 1 : -1;
      double usd = S6_TP_Usd*(posInfo.Volume()/0.01);
      double pl  = posInfo.Profit()+posInfo.Swap();
      if(S6_TP_Usd>0 && pl >= usd){ if(trade.PositionClose(xTk[x])) S6Push("PERSONAL FX S6: TP +$"+DoubleToString(pl,2)+" "+sym+" (extra trade)"); continue; }
      if(S6_TP_Usd>0) S6StampTP(xTk[x], sym, d, posInfo.PriceOpen(), posInfo.Volume(), posInfo.Swap(), usd, posInfo.StopLoss(), posInfo.TakeProfit());
   }

   double sumH = 0;
   for(int i=0; i<hn; i++) sumH += hPL[i];
   double total = mPL + sumH + b2PL;                             // v10.1: doosra trade bhi
   string gvP = S6Gv("P",sym), gvU = S6Gv("U",sym), gvT = S6Gv("T",sym);
   S6LvLive(sym, mTk, mDir, mOpen, mVol, mPL, mTP, mMs, hTk, hOpen, hPL, hVol, hn, sumH, total);   // v8.7: app

   // ---------- v7.9: CYCLE NET PROFIT (band hedge ka pakka + sab khule) ----------
   if(mTk!=0 && S6_CycleNetUsd > 0)
   {
      double real = S6Realized(sym, (datetime)(mMs/1000) - 5);
      double net  = real + total;
      int li = S6LvIdx(sym, true);                               // v8.9: har 10 sec Experts me haal
      if(li >= 0 && (g_LvLogAt[li]==0 || GetTickCount64() - g_LvLogAt[li] >= 10000))
      {
         g_LvLogAt[li] = GetTickCount64();
         S6LvHaal(sym, total, real, net, hn);                     // v9.0: app ke CHECK tab ke liye
         Print("PERSONAL FX S6 HAAL ", sym, " | khule $", DoubleToString(total,2), " | pakka $", DoubleToString(real,2), " | net $", DoubleToString(net,2),
               " (band +$", DoubleToString(S6_CycleNetUsd,2), ") | hedge ", hn);
      }
      if(net >= S6_CycleNetUsd)
      {
         int ok = 0;
         for(int i=hn-1; i>=0; i--) if(trade.PositionClose(hTk[i])){ ok++; GlobalVariableDel("PFX6A_"+IntegerToString((long)hTk[i])); }
         if(trade.PositionClose(mTk)){ ok++; S6SlotsClear(mTk); }
         if(b2Tk!=0 && trade.PositionClose(b2Tk)) ok++; else if(b2Tk==0) ok++;   // v10.1
         if(ok < hn+2) S6LvErr("cycle band ADHURA "+sym+": "+IntegerToString(ok)+" / "+IntegerToString(hn+1)+" band ["+IntegerToString((int)trade.ResultRetcode())+"] "+trade.ResultRetcodeDescription());
         S6DeletePendings(sym);                                  // v8.3
         if(GlobalVariableCheck(gvP)) GlobalVariableDel(gvP);
         if(GlobalVariableCheck(gvU)) GlobalVariableDel(gvU);
         S6LvWhy(sym, "NET +$"+DoubleToString(S6_CycleNetUsd,0));
         S6Push("PERSONAL FX S6: CYCLE NET +$"+DoubleToString(net,2)+" "+sym+" | pakka hedge $"+DoubleToString(real,2)
                +" + main $"+DoubleToString(mPL,2)+" + "+IntegerToString(hn)+" khule hedge $"+DoubleToString(sumH,2)
                +" -> "+IntegerToString(ok)+" trade band. Naya cycle aapke agle trade se.");
         return;
      }
   }

   // ---------- koi hedge nahi: main apne TP par ----------
   if(hn==0)
   {
      if(GlobalVariableCheck(gvP)) GlobalVariableDel(gvP);
      if(GlobalVariableCheck(gvU)) GlobalVariableDel(gvU);
      if(mTk==0)
      {
         if(b2Tk!=0 && trade.PositionClose(b2Tk)) S6Push("PERSONAL FX S6: main band - doosra trade bhi band "+sym);   // v10.1
         return;
      }
      double usd = S6_TP_Usd*(mVol/0.01);
      if(b2Tk!=0)                                                // v10.1: main + doosra trade milake $TP
      {
         if(mTP != 0) trade.PositionModify(mTk, mSL, 0);
         bool tp = (S6_TP_Usd>0 && mPL + b2PL >= usd);
         bool sl = (S6_BasketSL_Usd > 0 && mPL + b2PL <= -S6_BasketSL_Usd);
         if(tp || sl)
         {
            S6DeletePendings(sym);
            bool c1 = trade.PositionClose(b2Tk);
            bool c2 = trade.PositionClose(mTk);
            if(c2) S6SlotsClear(mTk);
            S6LvWhy(sym, tp ? "TP" : "BASKET SL -$"+DoubleToString(-(mPL+b2PL),2));
            S6Push("PERSONAL FX S6: "+(tp?"TP +$":"BASKET SL $")+DoubleToString(mPL+b2PL,2)+" "+sym+" (main + doosra trade)"+((c1&&c2)?"":" - ADHURA"));
            return;
         }
         // v10.2: band nahi hua -> aage pending wala hissa bhi chale (pehle yahin laut jaata tha)
      }
      if(b2Tk==0 && S6_TP_Usd>0 && mPL >= usd)            // v10.2: doosra trade ho to main akela band nahi
      {
         if(trade.PositionClose(mTk)){ S6SlotsClear(mTk); S6DeletePendings(sym); S6LvWhy(sym, "TP"); S6Push("PERSONAL FX S6: TP +$"+DoubleToString(mPL,2)+" "+sym+" (main, koi hedge nahi)"); }
         return;
      }
      if(b2Tk==0 && S6_TP_Usd>0) S6StampTP(mTk, sym, mDir, mOpen, mVol, mSwap, usd, mSL, mTP);   // v10.2: doosra trade ho to broker TP nahi
   }
   else if(mTk!=0)
   {
      // ---------- hedge khule: main + saare hedge ----------
      bool   closeAll = false; string why = "";
      double need = (mPL >= 0) ? S6_CycleTP_Usd : S6_BasketTP_Usd;
      if(need > 0 && total >= need)
      { closeAll = true; why = (mPL >= 0 ? "CYCLE TP" : "BASKET TP")+" +$"+DoubleToString(total,2); }
      else if(S6_BasketSL_Usd > 0 && total <= -S6_BasketSL_Usd)          // v8.9: seedha $ (pehle x lot/0.01)
      { closeAll = true; why = "BASKET SL -$"+DoubleToString(-total,2); }
      if(closeAll)
      {
         int ok = 0;
         for(int i=hn-1; i>=0; i--) if(trade.PositionClose(hTk[i])){ ok++; GlobalVariableDel("PFX6A_"+IntegerToString((long)hTk[i])); }
         if(trade.PositionClose(mTk)){ ok++; S6SlotsClear(mTk); }
         if(b2Tk!=0 && trade.PositionClose(b2Tk)) ok++; else if(b2Tk==0) ok++;   // v10.1
         if(ok < hn+2) S6LvErr("cycle band ADHURA "+sym+": "+IntegerToString(ok)+" / "+IntegerToString(hn+1)+" band ["+IntegerToString((int)trade.ResultRetcode())+"] "+trade.ResultRetcodeDescription());
         S6DeletePendings(sym);                                  // v8.3
         if(GlobalVariableCheck(gvP)) GlobalVariableDel(gvP);
         if(GlobalVariableCheck(gvU)) GlobalVariableDel(gvU);
         S6LvWhy(sym, why);
         S6Push("PERSONAL FX S6: "+why+" "+sym+" | main $"+DoubleToString(mPL,2)+" + "+IntegerToString(hn)+" hedge $"+DoubleToString(sumH,2)+(b2Tk!=0?" + doosra $"+DoubleToString(b2PL,2):"")+" -> "+IntegerToString(ok)+" trade band");
         return;
      }
      // hedge khula hai -> main ka broker TP hatao
      if(mTP != 0 && !trade.PositionModify(mTk, mSL, 0) && TimeCurrent()-g_S6TpWarn >= 60)
      {
         g_S6TpWarn = TimeCurrent();
         Print("PERSONAL FX S6: main TP hatana failed ",sym," #",mTk," [",trade.ResultRetcode(),"] ",trade.ResultRetcodeDescription());
      }
   }

   // ---------- hedge lock ----------
   double k6 = ProfitPerPriceUnitPerLot(sym);
   double gap6 = (k6 > 0 && S6_Gap_Usd > 0) ? S6_Gap_Usd/(k6*0.01) : 0;   // v8.2: slot ke liye
   if(hn > 0)
   {
      bool pairUsed = false;                                     // v8.4: jodi har baar jab sabse neeche wale ko dikkat
      // v8.0: pehle har hedge (aakhri bhi) ka lock chalu karo
      for(int i=0; i<hn; i++)
      {
         string gvA0 = "PFX6A_"+IntegerToString((long)hTk[i]);
         double am0  = MathMax(S6_LockUsd, S6_LockArmUsd)*(hVol[i]/0.01);
         if(S6GvGet(gvA0) != 1 && hPL[i] > am0) GlobalVariableSet(gvA0, 1);
      }
      bool newestArmed = (S6GvGet("PFX6A_"+IntegerToString((long)hTk[hn-1])) == 1);   // v8.4: sabse NEECHE wala khud +$2 paar?
      int  pairFrom = (!pairUsed && hn >= 2 && !newestArmed) ? hn-2 : hn;   // jodi sirf jab aakhri ko dikkat
      int  closedN = 0; double closedPL = 0; bool pairClosed = false;
      for(int i=(pairFrom==hn ? hn-1 : hn); i<pairFrom; i++)      // v8.4: sirf sabse neeche wala (upar wale ruko)
      {
         string gvA = "PFX6A_"+IntegerToString((long)hTk[i]);
         double lk  = S6_LockUsd*(hVol[i]/0.01);
         if(S6GvGet(gvA) == 1 && hPL[i] <= lk)
            if(trade.PositionClose(hTk[i])){ closedN++; closedPL += hPL[i]; GlobalVariableDel(gvA); S6SlotFree(mTk, hTk[i], hOpen[i], mOpen, mDir, gap6, sym); }
      }
      if(closedN > 0)
         S6Push("PERSONAL FX S6: LOCK "+sym+" | "+IntegerToString(closedN)+" hedge band +$"+DoubleToString(closedPL,2)
                +" | baaki "+IntegerToString(hn-closedN)+" hedge");
      if(pairFrom < hn)
      {
         int    a = hn-2, b = hn-1;
         double comb = hPL[a] + hPL[b];
         double lk   = S6_LockUsd*((hVol[a]+hVol[b])/0.02);
         double am   = lk;                                       // v8.1: jodi +$1 paar karte hi chalu (+$2 nahi)
         double armT = (double)(long)hTk[b];                     // jodi ki pehchaan = sabse naya hedge
         if(comb > am && S6GvGet(gvP) != armT) GlobalVariableSet(gvP, armT);
         if(S6GvGet(gvP) == armT && comb <= lk)
         {
            bool c1 = trade.PositionClose(hTk[b]);
            bool c2 = trade.PositionClose(hTk[a]);
            if(c1) S6SlotFree(mTk, hTk[b], hOpen[b], mOpen, mDir, gap6, sym);
            if(c2) S6SlotFree(mTk, hTk[a], hOpen[a], mOpen, mDir, gap6, sym);
            if(c1 || c2)
            {
               pairClosed = true;
               GlobalVariableDel(gvP);
               GlobalVariableSet(gvU, 1);                        // ab baaki hedge akele (naya hedge khulne tak)
               GlobalVariableDel("PFX6A_"+IntegerToString((long)hTk[a]));
               GlobalVariableDel("PFX6A_"+IntegerToString((long)hTk[b]));
               S6Push("PERSONAL FX S6: LOCK "+sym+" | aakhri 2 hedge milake band $"+DoubleToString(comb,2)
                      +" ("+DoubleToString(hPL[b],2)+" / "+DoubleToString(hPL[a],2)+") | baaki "+IntegerToString(hn-2)+" hedge");
            }
         }
      }
      if(closedN > 0 || pairClosed) return;                      // agle second taaza list se aage
   }

   // ---------- v10.1: doosra trade - hedge khule hon to main ke bhaav par STOP (ek cycle me ek) ----------
   if(mTk!=0)
   {
      string gvB = "PFX6B2_"+IntegerToString((long)mTk);
      if(b2Tk!=0 && !GlobalVariableCheck(gvB)) GlobalVariableSet(gvB, 1);
      ulong b2Ord = 0;
      for(int i=OrdersTotal()-1; i>=0; i--)
      {
         ulong ot = OrderGetTicket(i); if(ot==0) continue;
         if(OrderGetString(ORDER_SYMBOL)!=sym || OrderGetInteger(ORDER_MAGIC)!=MagicNumber) continue;
         if(OrderGetString(ORDER_COMMENT)=="PFX6HB") b2Ord = ot;
      }
      bool want = (S6_SecondBuyOn && hn > 0 && b2Tk==0 && !GlobalVariableCheck(gvB));
      double bB = SymbolInfoDouble(sym, SYMBOL_BID), aB = SymbolInfoDouble(sym, SYMBOL_ASK);
      int    dB = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      double pB = SymbolInfoDouble(sym, SYMBOL_POINT);
      double mdB = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*pB + 2*pB;
      double Lb = NormalizeDouble(mOpen, dB);
      bool room = (mDir==1) ? (Lb > aB + mdB) : (Lb < bB - mdB);  // STOP lagane ki jagah (bhaav main se door)
      if(want && b2Ord==0 && room)
      {
         double lotB = NormalizeLot(sym, S6_HedgeLot);
         trade.SetTypeFillingBySymbol(sym);
         bool okB = (mDir==1) ? trade.BuyStop (lotB, Lb, sym, 0, 0, ORDER_TIME_GTC, 0, "PFX6HB")
                              : trade.SellStop(lotB, Lb, sym, 0, 0, ORDER_TIME_GTC, 0, "PFX6HB");
         if(okB) Print("PERSONAL FX S6: doosra trade pending ", (mDir==1?"BUY STOP":"SELL STOP"), " ", sym, " @ ", DoubleToString(Lb,dB));
         else    S6LvErr("doosra trade pending FAIL "+sym+" @ "+DoubleToString(Lb,dB)+" ["+IntegerToString((int)trade.ResultRetcode())+"] "+trade.ResultRetcodeDescription());
      }
      else if(!want && b2Ord!=0) trade.OrderDelete(b2Ord);      // hedge nahi / pehle khul chuka -> hatao
   }

   // ---------- v8.3: agle hedge = PENDING STOP, sirf sequence ke level par ----------
   if(mTk==0) return;                                            // main haath se band -> hedge sirf apne lock par
   double k = ProfitPerPriceUnitPerLot(sym);
   if(k <= 0 || S6_Gap_Usd <= 0) return;
   double gap    = S6_Gap_Usd/(k*0.01);
   int    digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt     = SymbolInfoDouble(sym, SYMBOL_POINT);
   double bid    = SymbolInfoDouble(sym, SYMBOL_BID), ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double minD   = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*pt + 2*pt;

   // pending bhara -> naya hedge: jodi phir chalu + push
   if(hn > 0)
   {
      string gvW = S6Gv("W",sym);
      int nwI = 0; for(int i=1; i<hn; i++) if(hMs[i] > hMs[nwI]) nwI = i;   // v8.4: sabse naya (time se)
      if((double)hMs[nwI] > S6GvGet(gvW))
      {
         GlobalVariableSet(gvW, (double)hMs[nwI]);
         GlobalVariableSet(gvU, 0);
         g_DailyTradeCount++;
         S6LvHedgeFilled(sym);                                    // v8.7
         // v8.8: naya hedge sabse neeche bhara -> jodi ka lock bhare bhaav ke hisaab se usi pal chalu
         if(hn >= 2 && nwI == hn-1 && (long)TimeCurrent()*1000 - hMs[nwI] < 60000)
         {
            double kk  = ProfitPerPriceUnitPerLot(sym);
            double spU = (SymbolInfoDouble(sym,SYMBOL_ASK) - SymbolInfoDouble(sym,SYMBOL_BID)) * kk;   // $ per 1.00 lot
            double cf  = MathAbs(hOpen[hn-1] - hOpen[hn-2]) * kk * hVol[hn-2] - spU * (hVol[hn-1] + hVol[hn-2]);
            double lkf = S6_LockUsd*((hVol[hn-2]+hVol[hn-1])/0.02);
            if(kk > 0 && cf > lkf)
            {
               GlobalVariableSet(gvP, (double)(long)hTk[hn-1]);
               Print("PERSONAL FX S6: jodi lock bharte hi chalu ", sym, " (bhare bhaav par jodi $", DoubleToString(cf,2), ")");
            }
         }
         S6Push("PERSONAL FX S6: HEDGE level "+IntegerToString(S6Slot(hTk[nwI], hOpen[nwI], mOpen, mDir, gap))+" "+sym+" "+(mDir==1?"SELL":"BUY")
                +" "+DoubleToString(hVol[nwI],2)+" @ "+DoubleToString(hOpen[nwI],digits)+" | khule hedge "+IntegerToString(hn)+" | sab milake $"+DoubleToString(total,2));
      }
   }

   // kaunse level bhare hain
   int occ[]; ArrayResize(occ, hn);
   for(int i=0; i<hn; i++) occ[i] = S6Slot(hTk[i], hOpen[i], mOpen, mDir, gap);

   // v8.4: khali level ka bhaav = band hua tha (level se aage) to WAHI bhaav, warna theek level
   int cap = MathMax(0, S6_PendingAhead);
   if(S6_MaxHedges > 0) cap = MathMin(cap, MathMax(0, S6_MaxHedges - hn));
   double px0    = (mDir==1) ? bid : ask;
   double beyond = (mDir==1) ? (mOpen - bid) : (ask - mOpen);
   int    maxN   = (int)MathFloor(MathMax(beyond,0)/gap) + cap + 3;
   if(maxN > 2000) maxN = 2000;
   int cN[]; double cT[]; int nc = 0;                            // pending (bhaav se aage)
   double minSp = 0.5*gap;                                       // v8.6: do hedge ke beech kam se kam aadha gap
   for(int n=1; n<=maxN; n++)
   {
      bool busy = false;
      for(int i=0; i<hn; i++) if(occ[i]==n){ busy = true; break; }
      if(busy) continue;
      double L  = NormalizeDouble(mOpen - mDir*n*gap, digits);
      string gT = S6SlotGv("T",mTk,n), gS = S6SlotGv("S",mTk,n);
      bool   re = GlobalVariableCheck(gT);
      if(re && ((mDir==1) ? (bid > L) : (ask < L))){ GlobalVariableDel(gT); GlobalVariableDel(gS); re = false; }   // bhaav level se upar laut gaya -> theek level
      double T  = re ? GlobalVariableGet(gT) : L;
      if(re) T = (mDir==1) ? MathMax(T, L - 0.5*gap) : MathMin(T, L + 0.5*gap);   // v8.6: aadhe gap se aage nahi
      T = NormalizeDouble(T, digits);
      bool ahead = (mDir==1) ? (T < bid) : (T > ask);
      if(!ahead) continue;                                       // v8.6: bhaav nikal gaya -> wapas aane par (market se nahi)
      bool nearH = false;
      for(int i=0; i<hn; i++) if(MathAbs(hOpen[i] - T) < minSp){ nearH = true; break; }
      if(nearH) continue;                                        // v8.6: khule hedge ke bahut paas - nahi
      if(re && S6GvGet(gS) != 1) GlobalVariableSet(gS, 1);
      ArrayResize(cN, nc+1); ArrayResize(cT, nc+1); cN[nc] = n; cT[nc] = T; nc++;
   }
   for(int a=1; a<nc; a++)                                       // bhaav ke sabse paas pehle
      for(int b=a; b>0 && MathAbs(cT[b]-px0) < MathAbs(cT[b-1]-px0); b--)
      { int tn = cN[b]; cN[b] = cN[b-1]; cN[b-1] = tn; double tt = cT[b]; cT[b] = cT[b-1]; cT[b-1] = tt; }
   int nw = MathMin(nc, cap);

   // maujood S6 pending: sahi level + sahi bhaav = rakho, baaki hatao
   int have[]; ArrayResize(have, MathMax(nw,1)); ArrayInitialize(have, 0);
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      ulong ot = OrderGetTicket(i);
      if(ot==0) continue;
      if(OrderGetString(ORDER_SYMBOL)!=sym) continue;
      if(OrderGetInteger(ORDER_MAGIC)!=MagicNumber) continue;
      string cm = OrderGetString(ORDER_COMMENT);
      if(StringFind(cm,"PFX6H")!=0) continue;
      if(cm=="PFX6HB") continue;                                 // v10.1: doosra trade ka pending alag
      int    on = (int)StringToInteger(StringSubstr(cm,5));
      double op = OrderGetDouble(ORDER_PRICE_OPEN);
      bool keep = false;
      for(int w=0; w<nw; w++)
         if(cN[w]==on && have[w]==0 && MathAbs(op - cT[w]) < pt*2){ have[w] = 1; keep = true; break; }
      if(!keep) trade.OrderDelete(ot);
   }

   ENUM_ORDER_TYPE htype = (mDir==1) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   double lot = NormalizeLot(sym, S6_HedgeLot);

   // jo pending nahi hai wo lagao
   for(int w=0; w<nw; w++)
   {
      if(have[w]==1) continue;
      if(PositionsTotal() >= MaxOpenTrades)
      {
         if(TimeCurrent()-g_S6WarnMax >= 300){ g_S6WarnMax = TimeCurrent(); S6Push("PERSONAL FX S6: MaxOpenTrades ("+IntegerToString(MaxOpenTrades)+") poora - "+sym+" pending nahi laga"); }
         break;
      }
      int    nn = cN[w];
      double L  = cT[w];
      if((mDir==1) ? (L >= bid - minD) : (L <= ask + minD)) continue;   // bhaav bahut paas - agli baar
      double marginReq=0, freeMargin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(OrderCalcMargin(htype,sym,lot,L,marginReq) && marginReq>0 && marginReq>freeMargin)
      {
         if(TimeCurrent()-g_S6WarnMg >= 300){ g_S6WarnMg = TimeCurrent(); S6Push("PERSONAL FX S6: MARGIN nahi - "+sym+" pending nahi laga (chahiye $"+DoubleToString(marginReq,2)+")"); }
         break;
      }
      trade.SetTypeFillingBySymbol(sym);
      string tag = "PFX6H"+IntegerToString(nn);
      bool ok = (mDir==1) ? trade.SellStop(lot, L, sym, 0, 0, ORDER_TIME_GTC, 0, tag)
                          : trade.BuyStop (lot, L, sym, 0, 0, ORDER_TIME_GTC, 0, tag);
      if(ok)
      {
         ulong ot = trade.ResultOrder();
         if(ot > 0) GlobalVariableSet("PFX6N_"+IntegerToString((long)ot), nn);   // bharne par position = isi ticket
         Print("PERSONAL FX S6: pending ", (mDir==1?"SELL STOP":"BUY STOP"), " level ", nn, " ", sym, " @ ", DoubleToString(L,digits));
      }
      else if(TimeCurrent()-g_S6TpWarn >= 60)
      {
         g_S6TpWarn = TimeCurrent();
         Print("PERSONAL FX S6 [",sym,"]: pending FAILED level ",nn," @ ",DoubleToString(L,digits)," [",trade.ResultRetcode(),"] ",trade.ResultRetcodeDescription());
         S6LvErr("pending FAIL level "+IntegerToString(nn)+" "+sym+" @ "+DoubleToString(L,digits)+" ["+IntegerToString((int)trade.ResultRetcode())+"] "+trade.ResultRetcodeDescription());
      }
   }
}

//+------------------------------------------------------------------+
//|  v7.6 STRATEGY 5 - CANDLE (app Candle page, comment "PFXN<tf><key>")|
//|  TP +$S5_TP / SL -$S5_SL (0.01 lot pe) broker pe + software backup. |
//|  Candle band (S5_MaxCandles) -> jo bhi P/L, band. Nateeja app ko.   |
//+------------------------------------------------------------------+
ulong    g_S5WhyPid[]; string g_S5Why[];
datetime g_S5LastMod = 0;
void S5RememberWhy(ulong pid, string why)
{
   int n = ArraySize(g_S5WhyPid);
   for(int i=0;i<n;i++) if(g_S5WhyPid[i]==pid){ g_S5Why[i]=why; return; }
   if(n >= 50){ for(int j=1;j<n;j++){ g_S5WhyPid[j-1]=g_S5WhyPid[j]; g_S5Why[j-1]=g_S5Why[j]; } n--; }
   ArrayResize(g_S5WhyPid, n+1); ArrayResize(g_S5Why, n+1);
   g_S5WhyPid[n] = pid; g_S5Why[n] = why;
}
string S5TakeWhy(ulong pid)
{
   for(int i=0;i<ArraySize(g_S5WhyPid);i++) if(g_S5WhyPid[i]==pid){ string w=g_S5Why[i]; g_S5WhyPid[i]=0; return w; }
   return "";
}
int S5CountOpen(string sym)
{
   int c = 0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol()==sym && IsCandlePos()) c++;
   }
   return c;
}
void ManageCandleTrades()
{
   long nowSrv = (long)TimeTradeServer();
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsCandlePos()) continue;
      string sym  = posInfo.Symbol();
      string cm   = PosComment();
      int    tf   = (StringSubstr(cm,4,1)=="5") ? 5 : 1;
      ulong  tk   = posInfo.Ticket();
      ulong  pid  = (ulong)posInfo.Identifier();
      double vol  = posInfo.Volume();
      if(vol<=0) continue;
      int    dir  = (posInfo.PositionType()==POSITION_TYPE_BUY) ? 1 : -1;
      double open = posInfo.PriceOpen();
      double swap = posInfo.Swap();
      double scale= vol/0.01;
      double pl   = posInfo.Profit()+swap;
      double tpUsd= S5_TP_Usd*scale, slUsd = S5_SL_Usd*scale;
      string side = (dir==1?"BUY":"SELL");

      string why = "";
      if(S5_SL_Usd>0 && pl <= -slUsd) why = "SL";
      else if(S5_TP_Usd>0 && pl >= tpUsd) why = "TP";
      else if(S5_MaxCandles>0)
      {
         long per = (long)tf*60;
         long t0  = (long)posInfo.Time();
         long tEnd = (t0 - t0 % per) + per*S5_MaxCandles - (long)MathMax(0,S5_CloseEarlySec);
         if(nowSrv >= tEnd) why = "CANDLE CLOSE";
      }
      if(why!="")
      {
         S5RememberWhy(pid, why);
         if(!trade.PositionClose(tk))
            Print("PERSONAL FX S5: close failed ",sym," #",tk," [",trade.ResultRetcode(),"] ",trade.ResultRetcodeDescription());
         continue;
      }

      // broker pe asli TP / SL (ek baar; fail ho to 3 sec baad dobara)
      double curSL = posInfo.StopLoss(), curTP = posInfo.TakeProfit();
      if((curSL>0 || S5_SL_Usd<=0) && (curTP>0 || S5_TP_Usd<=0)) continue;
      if(TimeLocal() - g_S5LastMod < 3) continue;
      double k = ProfitPerPriceUnitPerLot(sym);
      if(k<=0) continue;
      int    digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      double pt     = SymbolInfoDouble(sym, SYMBOL_POINT);
      double bid    = SymbolInfoDouble(sym, SYMBOL_BID);
      double ask    = SymbolInfoDouble(sym, SYMBOL_ASK);
      if(bid<=0 || ask<=0) continue;
      double minD   = (double)MathMax(SymbolInfoInteger(sym,SYMBOL_TRADE_STOPS_LEVEL),
                                      SymbolInfoInteger(sym,SYMBOL_TRADE_FREEZE_LEVEL))*pt + 2*pt;
      double tpPx = (S5_TP_Usd>0) ? NormalizeDouble(open + dir*(tpUsd - swap)/(k*vol), digits) : 0;
      double slPx = (S5_SL_Usd>0) ? NormalizeDouble(open - dir*(slUsd + swap)/(k*vol), digits) : 0;
      if(dir==1)
      {
         if(tpPx>0 && tpPx < bid+minD) tpPx = NormalizeDouble(bid+minD, digits);
         if(slPx>0 && slPx > bid-minD) slPx = NormalizeDouble(bid-minD, digits);
      }
      else
      {
         if(tpPx>0 && tpPx > ask-minD) tpPx = NormalizeDouble(ask-minD, digits);
         if(slPx>0 && slPx < ask+minD) slPx = NormalizeDouble(ask+minD, digits);
      }
      g_S5LastMod = TimeLocal();
      if(trade.PositionModify(tk, slPx, tpPx))
         Print("PERSONAL FX S5: ",sym," ",side," #",tk," TP ",DoubleToString(tpPx,digits)," (+$",DoubleToString(tpUsd,2),
               ") | SL ",DoubleToString(slPx,digits)," (-$",DoubleToString(slUsd,2),") | ",tf,"m candle close par band");
      else
         Print("PERSONAL FX S5: TP/SL set failed ",sym," #",tk," [",trade.ResultRetcode(),"] ",trade.ResultRetcodeDescription());
   }
}
// candle trade ka OUT deal -> P/L + wajah app ko (orders/<key>) + push
void S5OnDealOut(ulong deal)
{
   if(!HistoryDealSelect(deal)) return;
   ulong  pid = (ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID);
   long   rsn = HistoryDealGetInteger(deal, DEAL_REASON);
   string sym = HistoryDealGetString(deal, DEAL_SYMBOL);
   double pl  = HistoryDealGetDouble(deal, DEAL_PROFIT) + HistoryDealGetDouble(deal, DEAL_SWAP) + HistoryDealGetDouble(deal, DEAL_COMMISSION);
   if(pid==0) return;
   if(!HistorySelectByPosition(pid)) return;
   string cm = "";
   for(int i=0;i<HistoryOrdersTotal();i++)
   {
      ulong o = HistoryOrderGetTicket(i);
      if(o==0) continue;
      string c = HistoryOrderGetString(o, ORDER_COMMENT);
      if(StringFind(c,"PFXN")==0){ cm = c; break; }
   }
   if(cm=="") return;                                       // candle trade nahi
   if(PositionSelectByTicket(pid)) return;                  // abhi poora band nahi (partial)
   double cmsIn = 0;                                        // kholte waqt ka commission bhi jodo
   for(int i=0;i<HistoryDealsTotal();i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d==0 || d==deal) continue;
      if(HistoryDealGetInteger(d, DEAL_ENTRY)==DEAL_ENTRY_IN) cmsIn += HistoryDealGetDouble(d, DEAL_COMMISSION);
   }
   pl += cmsIn;
   string why = S5TakeWhy(pid);
   if(why=="") why = (rsn==DEAL_REASON_TP) ? "TP" : (rsn==DEAL_REASON_SL) ? "SL" : (rsn==DEAL_REASON_SO) ? "STOP OUT" : "HAATH SE";
   string key = StringSubstr(cm, 5);
   string m   = sym+" candle trade band "+(pl>=0?"+":"-")+"$"+DoubleToString(MathAbs(pl),2)+" ("+why+")";
   Print("PERSONAL FX S5: ", m);
   if(UsePushNotify) SendNotification("PERSONAL FX S5: "+m);
   if(StringLen(key)>=10 && UseAppBridge && FirebaseURL!="" && !MQLInfoInteger(MQL_TESTER))
   {
      long nowMs = (long)TimeGMT()*1000;
      string body = "{\"status\":\"CLOSED\",\"res\":\""+AppJsonSafe(why)+"\",\"pl\":"+DoubleToString(pl,2)
                  + ",\"closed\":"+IntegerToString(nowMs)+",\"msg\":\""+AppJsonSafe(m)+"\"}";
      string resp; int code;
      if(!AppHttp("POST", AppUrl("orders/"+key), body, "X-HTTP-Method-Override: PATCH\r\n", resp, code))
         Print("PERSONAL FX S5: app ko nateeja nahi bhej paya ", key, " (", code, ")");
   }
}

//+------------------------------------------------------------------+
//|  MAIN GRID ENGINE — runs every tick for every symbol currently    |
//|  holding our positions.                                            |
//|  cnt==1 : single trade -> individual TP ($3 / 0.01 lot)           |
//|  cnt>=2 : grid active  -> basket TP (flat $3, combined) only      |
//|  either : if price moves against us by the next gap step AND      |
//|           adds < max -> open next same-side same-lot grid trade   |
//+------------------------------------------------------------------+
void ManageMartingaleGrids()
{
   S6CleanPendings();                                            // v8.3: bina main ke / Strategy 6 band -> S6 pending hatao
   S6LvCheck();                                                  // v8.7: app - cycle band / heartbeat
   string symsOpen[50]; int symCount=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      string sym = posInfo.Symbol();
      bool found=false;
      for(int k=0; k<symCount; k++) if(symsOpen[k]==sym){ found=true; break; }
      if(!found && symCount<50) symsOpen[symCount++]=sym;
   }

   for(int k=0; k<symCount; k++)
   {
      string sym = symsOpen[k];
      int    gi  = GridIndex(sym, true);
      int    cnt = GetSymbolPositionCount(sym);
      if(cnt==0) continue;

      SyncGridState(sym, gi, cnt);

      if(Strategy==STRAT_2_SL){ S2ManageSymbol(sym, Grid_TP_Dollar, S2_SL_Usd, true); g_GAdds[gi] = 0; continue; }   // v7.0: na grid, na basket - har trade alag
      if(Strategy==STRAT_3_SCALP){ S2ManageSymbol(sym, S3_TP_Usd, S3_SL_Usd, false); g_GAdds[gi] = 0; continue; }   // v7.1: scalp
      if(Strategy==STRAT_4_RECOVER){ S4ManageSymbol(sym); g_GAdds[gi] = 0; continue; }                               // v7.5: scalp + recovery
      if(Strategy==STRAT_6_HEDGE){ S6ManageSymbol(sym); g_GAdds[gi] = 0; continue; }                                 // v7.7: hedge ladder

      double totalPL = GetSymbolFloatingPL(sym);
      bool   closedThisTick = false;

      // v6.5: pair basket SL - saare trades milake -$BasketSL_Usd x (pehle trade ka lot/0.01) -> sab band
      if(UseBasketSL && BasketSL_Usd > 0)
      {
         double firstLot = FirstLegLot(sym);
         double slLimit  = BasketSL_Usd*(firstLot/0.01);
         if(firstLot > 0 && totalPL <= -slLimit)
         {
            Print("PERSONAL FX v10.2 BASKET SL: ", sym, " | ", cnt, " trades | P/L $", DoubleToString(totalPL,2),
                  " <= -$", DoubleToString(slLimit,2), " (pehla lot ", DoubleToString(firstLot,2), ") -> sab band");
            CloseSymbolTrades(sym);
            g_GAdds[gi] = 0;
            if(UsePushNotify)
               SendNotification("PERSONAL FX: Basket SL -$"+DoubleToString(-totalPL,2)+" "+sym+" ("+IntegerToString(cnt)+" trades band)");
            continue;
         }
      }

      if(cnt==1)
      {
         for(int i=0; i<PositionsTotal(); i++)
         {
            if(!posInfo.SelectByIndex(i)) continue;
            if(!IsOurPos()) continue;
            if(posInfo.Symbol()!=sym) continue;

            double lotFactor = posInfo.Volume()/0.01;
            double tpTarget  = Grid_TP_Dollar*lotFactor;
            double profit    = posInfo.Profit()+posInfo.Swap();

            if(profit >= tpTarget)
            {
               ulong tk = posInfo.Ticket();
               if(trade.PositionClose(tk))
               {
                  g_GAdds[gi] = 0;
                  closedThisTick = true;
                  if(UsePushNotify)
                     SendNotification("PERSONAL FX GRID: TP Hit +$"+DoubleToString(profit,2)+" "+sym);
               }
            }
            break; // only one position in this branch
         }
      }
      else // cnt >= 2 -> grid active, basket mode
      {
         if(totalPL >= Grid_BasketTP_Dollar)
         {
            CloseSymbolTrades(sym);
            g_GAdds[gi] = 0;
            closedThisTick = true;
            if(UsePushNotify)
               SendNotification("PERSONAL FX GRID: Basket TP! +$"+DoubleToString(totalPL,2)+" "+sym);
         }
      }

      if(closedThisTick) continue;

      if(UseProfitLock) ApplyProfitLock(sym, cnt, totalPL);   // v5.7

      // next grid-add trigger: PRICE-distance mode (default) or legacy $-loss mode
      bool doAdd=false;
      if(g_GAdds[gi] < Grid_MaxAdds)
      {
         if(GapFromLastTradeLoss && Grid_Gap_Usd > 0)
         {
            // v6.4: is pair ka SABSE NAYA trade — MT5 jo P/L dikhata hai (spread + swap) wo -$5 x (lot/0.01) -> turant agla
            double lastPL=0, lastVol=0; long lastMs=0;
            for(int i=0; i<PositionsTotal(); i++)
            {
               if(!posInfo.SelectByIndex(i)) continue;
               if(!IsOurPos()) continue;
               if(posInfo.Symbol()!=sym) continue;
               if(posInfo.TimeMsc() >= lastMs)
               { lastMs = posInfo.TimeMsc(); lastPL = posInfo.Profit()+posInfo.Swap(); lastVol = posInfo.Volume(); }
            }
            if(lastVol>0 && lastPL <= -Grid_Gap_Usd*(lastVol/0.01)) doAdd=true;
         }
         else if(UsePriceDistanceGap && g_GEntry[gi]>0)
         {
            double step  = (g_GAdds[gi]+1) * GridGapDistance(sym);   // v5.8
            double bid   = SymbolInfoDouble(sym, SYMBOL_BID);
            double ask   = SymbolInfoDouble(sym, SYMBOL_ASK);
            if(g_GDir[gi]==1  && bid <= g_GEntry[gi]-step) doAdd=true;   // buy grid: price fell $step
            if(g_GDir[gi]==-1 && ask >= g_GEntry[gi]+step) doAdd=true;   // sell grid: price rose $step
         }
         else
         {
            double nextThreshold = -((g_GAdds[gi]+1) * Grid_Gap_Dollar);   // legacy: cumulative basket $-loss
            if(totalPL <= nextThreshold) doAdd=true;
         }
      }
      if(doAdd) OpenGridAdd(sym, gi);

      // keep real broker-side TP in sync (also right after a new add)
      SyncTPLevels(sym, GetSymbolPositionCount(sym));
      // if g_GAdds[gi] >= Grid_MaxAdds -> do nothing, wait for basket TP only
   }
}

//+------------------------------------------------------------------+
//|  OCO PENDING (v5.3)                                               |
//|  You place Buy Limit + Sell Limit (stops also work) on one or     |
//|  many pairs. When one of them FILLS:                              |
//|   SAME PAIR : the OPPOSITE-side pending on THAT pair is deleted.  |
//|               Other pairs keep their pendings and work the same.  |
//|   ALL PAIRS : every pending (all pairs) placed BEFORE that fill   |
//|               is deleted -> only one pair gets traded.            |
//|  Only pendings placed BEFORE the fill are removed, so a fresh     |
//|  pending you place later is never touched. Works after EA/VPS     |
//|  restart too (fill is read from the position's opening order).    |
//|  The filled trade itself runs on the normal grid rules.           |
//+------------------------------------------------------------------+
bool IsPendingType(long t)
{
   return (t==ORDER_TYPE_BUY_LIMIT  || t==ORDER_TYPE_SELL_LIMIT ||
           t==ORDER_TYPE_BUY_STOP   || t==ORDER_TYPE_SELL_STOP  ||
           t==ORDER_TYPE_BUY_STOP_LIMIT || t==ORDER_TYPE_SELL_STOP_LIMIT);
}

int PendingDir(long t)
{
   if(t==ORDER_TYPE_BUY_LIMIT  || t==ORDER_TYPE_BUY_STOP  || t==ORDER_TYPE_BUY_STOP_LIMIT)  return 1;
   if(t==ORDER_TYPE_SELL_LIMIT || t==ORDER_TYPE_SELL_STOP || t==ORDER_TYPE_SELL_STOP_LIMIT) return -1;
   return 0;
}

bool IsOurMagicOnSymbol(string sym, long mg)
{
   if(!IsAllowedSymbol(sym)) return false;
   if(mg==MagicNumber) return true;
   if(ManageManualTrades && mg==0) return true;
   return false;
}

string OcoModeText()
{
   if(OCO_Mode==OCO_SAME_PAIR) return "SAME PAIR";
   if(OCO_Mode==OCO_ALL_PAIRS) return "ALL PAIRS";
   return "OFF";
}

int CountOurPendings()
{
   int c=0;
   for(int i=0;i<OrdersTotal();i++)
   {
      ulong tk=OrderGetTicket(i);
      if(tk==0) continue;
      if(!IsPendingType(OrderGetInteger(ORDER_TYPE))) continue;
      if(!IsOurMagicOnSymbol(OrderGetString(ORDER_SYMBOL), OrderGetInteger(ORDER_MAGIC))) continue;
      c++;
   }
   return c;
}

void ManageOCOPending()
{
   if(OCO_Mode==OCO_OFF) return;
   if(OrdersTotal()==0)  return;

   // 1) our open positions that were opened by a PENDING order (= a fill)
   string fSym[60]; int fDir[60]; long fTime[60]; int nF=0;
   for(int i=0; i<PositionsTotal() && nF<60; i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      long ident = posInfo.Identifier();          // = ticket of the order that opened it
      if(!HistoryOrderSelect((ulong)ident)) continue;
      long ot = HistoryOrderGetInteger((ulong)ident, ORDER_TYPE);
      if(!IsPendingType(ot)) continue;            // market / grid-add trade -> not an OCO trigger
      if(StringFind(HistoryOrderGetString((ulong)ident, ORDER_COMMENT),"PFX6H")==0) continue;   // v8.3: S6 hedge OCO nahi chalata
      fSym[nF]  = posInfo.Symbol();
      fDir[nF]  = (posInfo.PositionType()==POSITION_TYPE_BUY) ? 1 : -1;
      fTime[nF] = posInfo.TimeMsc();
      nF++;
   }
   if(nF==0) return;

   // 2) delete leftover pendings that belong to the same batch (placed before the fill)
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0) continue;
      long ot = OrderGetInteger(ORDER_TYPE);
      if(!IsPendingType(ot)) continue;
      string sym = OrderGetString(ORDER_SYMBOL);
      if(!IsOurMagicOnSymbol(sym, OrderGetInteger(ORDER_MAGIC))) continue;
      if(StringFind(OrderGetString(ORDER_COMMENT),"PFX6H")==0) continue;   // v8.3: S6 pending OCO se nahi hatta
      long setup = OrderGetInteger(ORDER_TIME_SETUP_MSC);
      int  odir  = PendingDir(ot);
      string otxt = EnumToString((ENUM_ORDER_TYPE)ot);
      double opx  = OrderGetDouble(ORDER_PRICE_OPEN);

      string trigSym=""; int trigDir=0;
      for(int f=0; f<nF; f++)
      {
         if(setup >= fTime[f]) continue;          // placed AFTER that fill -> new order, keep it
         if(OCO_Mode==OCO_ALL_PAIRS)
         { trigSym=fSym[f]; trigDir=fDir[f]; break; }
         if(fSym[f]==sym && fDir[f]==-odir)
         { trigSym=fSym[f]; trigDir=fDir[f]; break; }
      }
      if(trigSym=="") continue;

      int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      if(trade.OrderDelete(tk))
      {
         string msg = "PERSONAL FX OCO: "+trigSym+" "+(trigDir==1?"BUY":"SELL")+
                      " filled -> removed "+sym+" "+otxt+" @ "+DoubleToString(opx,dg);
         Print(msg);
         if(UsePushNotify) SendNotification(msg);
      }
      else
         Print("PERSONAL FX OCO: delete FAILED ",sym," #",tk," [",trade.ResultRetcode(),"] ",
               trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//|  SAMUSIGNAL APP BRIDGE (v5.4)                                     |
//|  App (Chart Analysis) writes orders to Firebase:                  |
//|    /personalfx/orders/<key> = {pair, type, entry, at, status:NEW} |
//|    v5.9: + batch, leg, legs (ek analysis ke 2 order = ek batch)    |
//|  type = BUYMARKET / BUYLIMIT / BUYSTOP / SELLMARKET / SELLLIMIT /  |
//|         SELLSTOP. entry = 0 for MARKET.                           |
//|  EA: every AppPollSec reads the list, places each NEW order once  |
//|  with THIS EA's lot (no SL/TP -> grid rules manage it) and writes |
//|  status back: PLACED / FAILED / SKIP / STALE / EXPIRED.           |
//|  MT5: Tools > Options > Expert Advisors > "Allow WebRequest" and  |
//|  add the Firebase URL (same as FirebaseURL input).                |
//+------------------------------------------------------------------+
string AppBase()
{
   string u = FirebaseURL;
   StringTrimLeft(u); StringTrimRight(u);
   while(StringLen(u)>0 && StringGetCharacter(u, StringLen(u)-1)=='/')
      u = StringSubstr(u, 0, StringLen(u)-1);
   if(u!="" && StringFind(u,"http")!=0) u = "https://"+u;
   return u;
}

string AppUrl(string path)
{
   string u = AppBase()+"/personalfx/"+path+".json";
   if(FirebaseAuth!="") u += "?auth="+FirebaseAuth;
   return u;
}

// method: GET / POST. extraHdr e.g. "X-HTTP-Method-Override: PATCH\r\n"
bool AppHttp(string method, string url, string body, string extraHdr, string &resp, int &code)
{
   char data[], result[];
   string rh;
   string hdr = "Content-Type: application/json\r\n" + extraHdr;
   if(body!="")
   {
      int n = StringToCharArray(body, data, 0, WHOLE_ARRAY, CP_UTF8);
      if(n>0) ArrayResize(data, n-1);              // drop trailing 0
   }
   ResetLastError();
   string prevSt = g_AppStatus;
   code = WebRequest(method, url, hdr, 4000, data, result, rh);
   if(code==-1)
   {
      int err = GetLastError();
      if(err==4014)
      {
         g_AppStatus = "URL ALLOW KARO";
         if(!g_AppUrlWarned)
         {
            g_AppUrlWarned = true;
            Alert("PERSONAL FX: MT5 > Tools > Options > Expert Advisors > 'Allow WebRequest' ON karke ye URL add karo: ", AppBase());
         }
      }
      else g_AppStatus = "NET ERR "+IntegerToString(err);
      S6LvErr("Firebase WebRequest error "+IntegerToString(err)+(err==4014?" (MT5 me WebRequest URL allow karo)":""));
      if(g_AppStatus!=prevSt) Print("PERSONAL FX APP: WebRequest error ", err, " (", g_AppStatus, ")");
      return false;
   }
   resp = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   if((code<200 || code>=300) && method!="GET")      // GET errors are printed by PollAppOrders (only on change)
      S6LvErr("Firebase HTTP "+IntegerToString(code)+" "+method+" "+StringSubstr(url, StringFind(url,"/personalfx/")<0?0:StringFind(url,"/personalfx/"), StringFind(url,"?")<0?60:MathMin(60,StringFind(url,"?")-MathMax(0,StringFind(url,"/personalfx/")))));
      Print("PERSONAL FX APP: HTTP ", code, " on ", method, " ", StringSubstr(url,0,StringFind(url,"?")<0?StringLen(url):StringFind(url,"?")),
            " | reply: ", StringSubstr(resp,0,160));
   return (code>=200 && code<300);
}

string AppJsonSafe(string t)
{
   StringReplace(t, "\\", "/");
   StringReplace(t, "\"", "'");
   StringReplace(t, "{", "(");
   StringReplace(t, "}", ")");
   return t;
}

// write status back to the app (PATCH via method override — works on every MT5 build)
void AppSetStatus(string key, string status, string msg)
{
   long nowMs = (long)TimeGMT()*1000;
   string body = "{\"status\":\""+status+"\",\"msg\":\""+AppJsonSafe(msg)+"\",\"done\":"+IntegerToString(nowMs)+"}";
   string resp; int code;
   if(!AppHttp("POST", AppUrl("orders/"+key), body, "X-HTTP-Method-Override: PATCH\r\n", resp, code))
      Print("PERSONAL FX APP: status write failed for ", key, " (", code, ")");
   Print("PERSONAL FX APP: ", key, " -> ", status, " | ", msg);
}

bool AppIsDone(string key)
{
   for(int i=0;i<g_AppDoneN;i++) if(g_AppDone[i]==key) return true;
   return false;
}
// v6.7: dobara try ke liye done list se hatao
void AppUnmarkDone(string key)
{
   for(int i=0;i<g_AppDoneN;i++)
      if(g_AppDone[i]==key){ for(int j=i+1;j<g_AppDoneN;j++) g_AppDone[j-1]=g_AppDone[j]; g_AppDoneN--; return; }
}

// v6.7: symbol abhi Market Watch me juda ho to pehla tick aane me thoda waqt lagta hai
bool AppWaitPrice(string sym, int maxMs)
{
   MqlTick tk;
   int waited = 0;
   while(true)
   {
      if(SymbolInfoTick(sym, tk) && tk.bid > 0 && tk.ask > 0) return true;
      if(waited >= maxMs) return false;
      Sleep(100); waited += 100;
   }
   return false;
}

void AppMarkDone(string key)
{
   if(AppIsDone(key)) return;
   if(g_AppDoneN>=300)                       // keep the newest 299
   { for(int i=1;i<300;i++) g_AppDone[i-1]=g_AppDone[i]; g_AppDoneN=299; }
   g_AppDone[g_AppDoneN++] = key;
}

// ---- tiny JSON readers (flat objects written by the app) ----
string JsonStr(string obj, string key)
{
   string pat = "\""+key+"\"";
   int p = StringFind(obj, pat);
   if(p<0) return "";
   p = StringFind(obj, ":", p+StringLen(pat));
   if(p<0) return "";
   p++;
   int n = StringLen(obj);
   while(p<n && (StringGetCharacter(obj,p)==' ')) p++;
   if(p>=n || StringGetCharacter(obj,p)!='"') return "";
   int q = p+1;
   while(q<n)
   {
      ushort c = StringGetCharacter(obj,q);
      if(c=='\\') { q+=2; continue; }
      if(c=='"') break;
      q++;
   }
   return StringSubstr(obj, p+1, q-p-1);
}

double JsonNum(string obj, string key)
{
   string pat = "\""+key+"\"";
   int p = StringFind(obj, pat);
   if(p<0) return 0;
   p = StringFind(obj, ":", p+StringLen(pat));
   if(p<0) return 0;
   p++;
   int n = StringLen(obj);
   while(p<n && (StringGetCharacter(obj,p)==' ' || StringGetCharacter(obj,p)=='"')) p++;
   int q = p;
   while(q<n)
   {
      ushort c = StringGetCharacter(obj,q);
      if((c>='0' && c<='9') || c=='.' || c=='-' || c=='+' || c=='e' || c=='E') q++;
      else break;
   }
   if(q==p) return 0;
   return StringToDouble(StringSubstr(obj, p, q-p));
}

// split {"k1":{...},"k2":{...}} into keys[] / objs[]
int AppSplitRecords(string s, string &keys[], string &objs[])
{
   int n = StringLen(s), cnt = 0;
   ArrayResize(keys,0); ArrayResize(objs,0);
   int i = StringFind(s, "{");
   if(i<0) return 0;
   i++;
   while(i<n)
   {
      // find next key
      while(i<n && StringGetCharacter(s,i)!='"' && StringGetCharacter(s,i)!='}') i++;
      if(i>=n || StringGetCharacter(s,i)=='}') break;
      int k1 = i+1, k2 = StringFind(s, "\"", k1);
      if(k2<0) break;
      string key = StringSubstr(s, k1, k2-k1);
      i = StringFind(s, ":", k2);
      if(i<0) break;
      i++;
      while(i<n && StringGetCharacter(s,i)==' ') i++;
      if(i>=n) break;
      if(StringGetCharacter(s,i)!='{')
      {  // not an object -> skip value
         while(i<n && StringGetCharacter(s,i)!=',' && StringGetCharacter(s,i)!='}') i++;
         continue;
      }
      int depth=0; bool inStr=false; int start=i;
      for(; i<n; i++)
      {
         ushort c = StringGetCharacter(s,i);
         if(inStr){ if(c=='\\'){ i++; continue; } if(c=='"') inStr=false; continue; }
         if(c=='"') inStr=true;
         else if(c=='{') depth++;
         else if(c=='}'){ depth--; if(depth==0){ i++; break; } }
      }
      ArrayResize(keys,cnt+1); ArrayResize(objs,cnt+1);
      keys[cnt]=key; objs[cnt]=StringSubstr(s, start, i-start);
      cnt++;
   }
   return cnt;
}

// v7.2: chart ke symbol ka suffix (XAUUSDc -> "c", EURUSD -> "")
string AppChartSuffix()
{
   string s = _Symbol;
   if(StringLen(s) <= 6) return "";
   return StringSubstr(s, 6);
}
bool AppSymTradable(string s)
{
   long m = SymbolInfoInteger(s, SYMBOL_TRADE_MODE);
   return (m == SYMBOL_TRADE_MODE_FULL || m == SYMBOL_TRADE_MODE_LONGONLY || m == SYMBOL_TRADE_MODE_SHORTONLY);
}
string g_AppResLog = "|";     // kis jodi ka chunav log me likh chuke
string AppResolve(string pair)
{
   if(AppSymbolSuffix!="")
   {
      string s = pair+AppSymbolSuffix;
      if(SymbolSelect(s,true)) return s;
      return "";
   }
   // v7.2: us jodi ke saare naam dekho, sirf trade-chalu wala chuno; chart ka suffix / bina suffix pehle
   string want = pair;
   StringToUpper(want); StringTrimLeft(want); StringTrimRight(want);
   if(want=="") return "";
   string suf = AppChartSuffix();
   StringToUpper(suf);
   string best = "", firstAny = "";
   int bestScore = -1, seen = 0;
   int total = SymbolsTotal(false);
   for(int i=0;i<total;i++)
   {
      string s = SymbolName(i,false);
      string up = s;
      StringToUpper(up);
      if(StringFind(up,want)!=0) continue;
      if(StringLen(up) > StringLen(want)+4) continue;          // GBPJPY ke naam par koi lamba alag symbol nahi
      seen++;
      if(firstAny=="") firstAny = s;
      if(!AppSymTradable(s)) continue;                         // is account pe trade band -> chhodo
      string rest = StringSubstr(up, StringLen(want));
      int score = 1 + (rest==suf ? 2 : 0) + (rest=="" ? 1 : 0);
      if(score > bestScore){ bestScore = score; best = s; }
   }
   if(best=="") best = firstAny;                               // koi trade-chalu nahi mila -> purana tareeka (MT5 error batayega)
   if(best=="") return "";
   if(!SymbolSelect(best,true)) return "";
   if(StringFind(g_AppResLog, "|"+want+"|")<0)
   {
      g_AppResLog += want+"|";
      Print("PERSONAL FX APP: ", want, " -> ", best, " (", seen, " naam mile", (bestScore<0 ? ", koi trade-chalu nahi!" : ", trade chalu"),
            ", chart suffix '", AppChartSuffix(), "')");
   }
   return best;
}

// already placed earlier (EA restart / status write failed)? -> look for our comment
bool AppAlreadyPlaced(string tag, ulong &ticket)
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0) continue;
      if(OrderGetString(ORDER_COMMENT)==tag){ ticket=tk; return true; }
   }
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Comment()==tag){ ticket=posInfo.Ticket(); return true; }
   }
   return false;
}

// v5.9: is poll me ye app key kis batch ka hai ("" = batch nahi / pata nahi)
string AppKeyBatch(string key)
{
   for(int i=0;i<g_PollN;i++) if(g_PollKey[i]==key) return g_PollBatch[i];
   return "";
}

// a fresher app order on the same pair replaces the older app pending (called only right before sending)
// v5.9: SAME batch ke pending ko nahi hatata (2 order ek saath rehte hain)
void AppReplaceOld(string sym, string batch)
{
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0) continue;
      if(OrderGetString(ORDER_SYMBOL)!=sym) continue;
      string cm = OrderGetString(ORDER_COMMENT);
      if(StringFind(cm,"PFXA")!=0) continue;
      if(batch!="" && AppKeyBatch(StringSubstr(cm,4))==batch) continue;   // v5.9: apna hi batch — rehne do
      if(trade.OrderDelete(tk))
      {
         string k = StringSubstr(cm,4);
         if(StringLen(k)>=19) AppSetStatus(k, "REPLACED", "#"+IntegerToString((long)tk)+" naye order ne jagah li");
      }
   }
}

void ProcessAppOrder(string key, string obj)
{
   string pair = JsonStr(obj, "pair");
   string typ  = JsonStr(obj, "type");
   double entry = JsonNum(obj, "entry");
   long   atMs  = (long)JsonNum(obj, "at");
   string batch = JsonStr(obj, "batch");       // v5.9: "" = purana app (ek order)
   string tag   = "PFXA"+key;                  // order comment = link back to the app record
   string pr    = JsonStr(obj, "pr");          // v6.9: pair trade jodi id ("" = normal)
   int    prLeg = (int)JsonNum(obj, "leg");
   if(pr!="") tag = "PFXP"+pr+"_"+IntegerToString(prLeg);
   bool   cs    = (JsonStr(obj, "strat")=="CANDLE");   // v7.6: app Candle page -> Strategy 5
   int    csTf  = (int)JsonNum(obj, "tf");
   if(cs){ if(csTf!=5) csTf = 1; tag = "PFXN"+IntegerToString(csTf)+key; pr = ""; }
   AppMarkDone(key);                           // never handle the same key twice in this session

   ulong oldTk=0;
   if(AppAlreadyPlaced(tag, oldTk))
   { AppSetStatus(key, "PLACED", "#"+IntegerToString((long)oldTk)+" (pehle se laga hua)"); return; }

   long nowMs = (long)TimeGMT()*1000;
   if(cs && atMs>0 && nowMs-atMs > (long)MathMax(3,S5_MaxOrderAgeSec)*1000)   // v7.6: candle signal sirf kuch sec ka
   { AppSetStatus(key, "STALE", IntegerToString((nowMs-atMs)/1000)+" sec purana - candle signal ka waqt nikal gaya"); return; }
   if(atMs>0 && nowMs-atMs > (long)AppMaxOrderAgeMin*60000)
   { AppSetStatus(key, "STALE", IntegerToString((nowMs-atMs)/60000)+" min purana - EA band tha? dobara bhejo"); return; }

   bool isBuy = (StringFind(typ,"BUY")==0);
   bool isSell= (StringFind(typ,"SELL")==0);
   string kind = isBuy ? StringSubstr(typ,3) : (isSell ? StringSubstr(typ,4) : "");
   if((!isBuy && !isSell) || (kind!="MARKET" && kind!="LIMIT" && kind!="STOP"))
   { AppSetStatus(key, "FAILED", "type samajh nahi aaya: "+typ); return; }

   string sym = AppResolve(pair);
   if(sym=="")
   { AppSetStatus(key, "FAILED", pair+" symbol broker pe nahi mila (AppSymbolSuffix check karo)"); return; }
   // v6.7: symbol mila par price abhi 0 (Market Watch me abhi juda) -> rukko, Fail mat likho
   if(!AppWaitPrice(sym, 2000))
   {
      if(atMs>0 && nowMs-atMs < 30000)
      {
         AppUnmarkDone(key);                    // agle poll (AppPollSec) me dobara
         Print("PERSONAL FX APP: ", sym, " ka price abhi nahi aaya - ", key, " agle poll me dobara");
         return;
      }
      AppSetStatus(key, "FAILED", sym+" ka price nahi aaya (market band? symbol Market Watch me hai?)"); return;
   }
   if(!IsAllowedSymbol(sym))
   { AppSetStatus(key, "SKIP", sym+" AllowedSymbolsCSV me nahi"); return; }
   if(UseDailyLimits && g_DailyLimitHit)
   { AppSetStatus(key, "SKIP", "daily limit hit - aaj naya trade nahi"); return; }
   if(pr!="" && kind!="MARKET")
   { AppSetStatus(key, "FAILED", "pair trade sirf MARKET"); return; }
   if(cs && kind!="MARKET")
   { AppSetStatus(key, "FAILED", "candle trade sirf MARKET"); return; }
   if(cs && S5CountOpen(sym) > 0)                     // v7.6: ek pair pe ek hi candle trade
   { AppSetStatus(key, "SKIP", sym+" pe candle trade pehle se chalu"); return; }
   if(!cs && pr=="" && GetSymbolPositionCount(sym) > 0)      // v6.9: pair leg grid se alag - rokta nahi
   { AppSetStatus(key, "SKIP", sym+" pe grid pehle se chal raha hai"); return; }
   if(PositionsTotal() >= MaxOpenTrades)
   { AppSetStatus(key, "SKIP", "MaxOpenTrades poora"); return; }
   string nwhy = "";
   if(kind!="MARKET" && pr=="" && NewsBlock(sym, nwhy))      // v7.3: news ke aas-paas naya pending nahi
   { AppSetStatus(key, "SKIP", "news: "+nwhy+" — pending nahi lagaya"); return; }
   string twhy = "";
   if(kind!="MARKET" && pr=="" && AppTrendFlipped(sym, isBuy, twhy))   // v7.4: trend pehle hi palta -> pending nahi
   { AppSetStatus(key, "SKIP", "trend: "+twhy+" - pending nahi lagaya"); return; }

   int    dg  = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   double pt  = SymbolInfoDouble(sym, SYMBOL_POINT);
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double lot = NormalizeLot(sym, cs ? S5_Lot : g_LotInput);   // lot = THIS EA's input (panel +/- if changed); v7.6 candle = S5_Lot
   trade.SetTypeFillingBySymbol(sym);

   // ---------- MARKET ----------
   if(kind=="MARKET")
   {
      string spTxt = "";
      if(SpreadTooHigh(sym, spTxt))
      { AppSetStatus(key, "SKIP", "spread zyada: "+spTxt); return; }
      ENUM_ORDER_TYPE ot = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double px = isBuy ? ask : bid;
      double marginReq=0;
      if(OrderCalcMargin(ot, sym, lot, px, marginReq) && marginReq>0 && marginReq>AccountInfoDouble(ACCOUNT_MARGIN_FREE))
      { AppSetStatus(key, "FAILED", "margin nahi - chahiye $"+DoubleToString(marginReq,2)); return; }
      if(pr=="" && !cs) AppReplaceOld(sym, batch);    // v6.9: pair leg / v7.6 candle trade dusre app pending ko nahi hatata
      bool ok = isBuy ? trade.Buy(lot, sym, px, 0, 0, tag) : trade.Sell(lot, sym, px, 0, 0, tag);
      if(!ok)
      { AppSetStatus(key, "FAILED", "MT5 error "+IntegerToString(trade.ResultRetcode())+" "+trade.ResultRetcodeDescription()); return; }
      g_DailyTradeCount++;
      int gi = (pr=="" && !cs) ? GridIndex(sym, true) : -1;  // v6.9: pair leg grid nahi; v7.6 candle bhi nahi
      if(gi>=0){ g_GDir[gi]=isBuy?1:-1; g_GAdds[gi]=0; g_GLot[gi]=lot; g_GEntry[gi]=trade.ResultPrice()>0?trade.ResultPrice():px; }
      string m = "#"+IntegerToString((long)trade.ResultOrder())+" "+(isBuy?"BUY":"SELL")+" "+DoubleToString(lot,2)+" @ "+DoubleToString(trade.ResultPrice()>0?trade.ResultPrice():px,dg)
                 +(pr!="" ? " | PAIR leg "+IntegerToString(prLeg)+" (lock/SL dono milake)" : "")
                 +(cs ? " | S5 CANDLE "+IntegerToString(csTf)+"m: TP +$"+DoubleToString(S5_TP_Usd*lot/0.01,2)+" / SL -$"+DoubleToString(S5_SL_Usd*lot/0.01,2)+" / candle close" : "");
      if(cs) ManageCandleTrades();                     // v7.6: broker TP/SL turant
      AppSetStatus(key, "PLACED", m);
      if(UsePushNotify) SendNotification("PERSONAL FX APP: "+sym+" "+m);
      return;
   }

   // ---------- PENDING (LIMIT / STOP) ----------
   if(entry<=0)
   { AppSetStatus(key, "FAILED", "entry price nahi mila"); return; }
   entry = NormalizeDouble(entry, dg);
   // v6.2: app ka level TwelveData price pe bana hai — broker ka price alag (BTC pe ~$100).
   //       Farak (broker mid - app live) level me jodo, taaki live se doori wahi rahe.
   double appLive = JsonNum(obj, "live");
   string shiftTxt = "";
   if(AppAlignToBroker && appLive > 0)
   {
      double mid = (bid + ask) / 2.0;
      double off = mid - appLive;
      Print("PERSONAL FX APP: ", sym, " app live ", DoubleToString(appLive,dg), " | broker ", DoubleToString(mid,dg),
            " | farak ", DoubleToString(off,dg));
      if(MathAbs(off) <= appLive * AppMaxShiftPct / 100.0)
      {
         if(MathAbs(off) >= pt)
         {
            entry = NormalizeDouble(entry + off, dg);
            shiftTxt = " | broker farak "+(off>0?"+":"")+DoubleToString(off,dg)+" jod diya";
         }
      }
      else shiftTxt = " | farak "+DoubleToString(off,dg)+" bahut bada - level nahi khiskaya";
   }
   double minD = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL)*pt;
   double fz   = (double)SymbolInfoInteger(sym, SYMBOL_TRADE_FREEZE_LEVEL)*pt;
   if(fz>minD) minD=fz;
   string wrong="";
   if(isBuy  && kind=="LIMIT" && entry >= ask-minD) wrong="price pehle hi entry ke neeche/paas aa gaya";
   if(isBuy  && kind=="STOP"  && entry <= ask+minD) wrong="price pehle hi entry ke upar/paas chala gaya";
   if(isSell && kind=="LIMIT" && entry <= bid+minD) wrong="price pehle hi entry ke upar/paas chala gaya";
   if(isSell && kind=="STOP"  && entry >= bid-minD) wrong="price pehle hi entry ke neeche/paas aa gaya";
   if(wrong!="")
   { AppSetStatus(key, "FAILED", wrong+" (entry "+DoubleToString(entry,dg)+", live "+DoubleToString(isBuy?ask:bid,dg)+shiftTxt+") - dobara analyze karo"); return; }

   ENUM_ORDER_TYPE pot = isBuy ? (kind=="LIMIT"?ORDER_TYPE_BUY_LIMIT:ORDER_TYPE_BUY_STOP)
                               : (kind=="LIMIT"?ORDER_TYPE_SELL_LIMIT:ORDER_TYPE_SELL_STOP);
   double marginReq=0;
   if(OrderCalcMargin(isBuy?ORDER_TYPE_BUY:ORDER_TYPE_SELL, sym, lot, entry, marginReq) && marginReq>0
      && marginReq>AccountInfoDouble(ACCOUNT_MARGIN_FREE))
   { AppSetStatus(key, "FAILED", "margin nahi - chahiye $"+DoubleToString(marginReq,2)); return; }

   AppReplaceOld(sym, batch);
   bool ok=false;
   if(pot==ORDER_TYPE_BUY_LIMIT)  ok = trade.BuyLimit (lot, entry, sym, 0, 0, ORDER_TIME_GTC, 0, tag);
   if(pot==ORDER_TYPE_BUY_STOP)   ok = trade.BuyStop  (lot, entry, sym, 0, 0, ORDER_TIME_GTC, 0, tag);
   if(pot==ORDER_TYPE_SELL_LIMIT) ok = trade.SellLimit(lot, entry, sym, 0, 0, ORDER_TIME_GTC, 0, tag);
   if(pot==ORDER_TYPE_SELL_STOP)  ok = trade.SellStop (lot, entry, sym, 0, 0, ORDER_TIME_GTC, 0, tag);
   if(!ok)
   { AppSetStatus(key, "FAILED", "MT5 error "+IntegerToString(trade.ResultRetcode())+" "+trade.ResultRetcodeDescription()); return; }
   g_DailyTradeCount++;
   string m = "#"+IntegerToString((long)trade.ResultOrder())+" "+(isBuy?"BUY ":"SELL ")+kind+" "+DoubleToString(lot,2)+" @ "+DoubleToString(entry,dg)
              +" | "+IntegerToString(AppPendingExpiryMin)+" min"
              +(batch!="" ? " | batch "+IntegerToString((int)JsonNum(obj,"leg"))+"/"+IntegerToString((int)JsonNum(obj,"legs")) : "")
              +shiftTxt;
   AppSetStatus(key, "PLACED", m);
   if(UsePushNotify) SendNotification("PERSONAL FX APP: "+sym+" "+m);
}

//+------------------------------------------------------------------+
//|  v6.9 PAIR TRADES - dono leg milake lock / SL                      |
//+------------------------------------------------------------------+
string PairGroupOf(string cm)          // "PFXP<grp>_<leg>" -> grp
{
   int u = StringFind(cm, "_", 4);
   return (u>4) ? StringSubstr(cm, 4, u-4) : StringSubstr(cm, 4);
}

void PairClose(string grp, double pl, string why, int legs)
{
   string syms = "";
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsPairPos()) continue;
      if(PairGroupOf(PosComment())!=grp) continue;
      string sy = posInfo.Symbol();
      if(trade.PositionClose(posInfo.Ticket())) syms += (syms==""?"":"/")+sy;
      else Print("PERSONAL FX PAIR: close FAILED ", sy, " #", posInfo.Ticket(), " [", trade.ResultRetcode(), "]");
   }
   GlobalVariableDel("PFXP_"+grp);
   string msg = "PERSONAL FX PAIR "+why+": "+syms+" "+(pl>=0?"+$":"-$")+DoubleToString(MathAbs(pl),2)+" ("+IntegerToString(legs)+" leg band)";
   Print(msg);
   if(UsePushNotify) SendNotification(msg);
   if(UseAppBridge && FirebaseURL!="" && !MQLInfoInteger(MQL_TESTER))
   {
      long nowMs = (long)TimeGMT()*1000;
      string body = "{\"grp\":\""+grp+"\",\"acct\":\""+AppMyLogin()+"\",\"why\":\""+why+"\",\"pl\":"+DoubleToString(pl,2)
                    +",\"syms\":\""+AppJsonSafe(syms)+"\",\"at\":"+IntegerToString(nowMs)+"}";
      string resp; int code;
      if(!AppHttp("POST", AppUrl("pairs/"+AppMyLogin()+"_"+grp), body, "X-HTTP-Method-Override: PUT\r\n", resp, code))
         Print("PERSONAL FX PAIR: result write fail (", code, ")");
   }
}

void ManagePairTrades()
{
   string grp[30]; double pl[30], vol[30]; int legs[30]; long first[30]; bool gold[30]; int n=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsPairPos()) continue;
      string g = PairGroupOf(PosComment());
      int k=-1;
      for(int j=0;j<n;j++) if(grp[j]==g){ k=j; break; }
      if(k<0)
      {
         if(n>=30) continue;
         k=n++; grp[k]=g; pl[k]=0; vol[k]=posInfo.Volume(); legs[k]=0; first[k]=posInfo.TimeMsc(); gold[k]=false;
      }
      pl[k]   += posInfo.Profit()+posInfo.Swap();
      legs[k]++;
      if(posInfo.Volume()<vol[k]) vol[k]=posInfo.Volume();
      if(posInfo.TimeMsc()<first[k]) first[k]=posInfo.TimeMsc();
      if(StringFind(posInfo.Symbol(),"XAU")==0) gold[k]=true;
   }
   long nowMs = (long)TimeCurrent()*1000;
   for(int k=0;k<n;k++)
   {
      double kf = vol[k]/0.01; if(kf<=0) kf=1;
      // ek hi leg (dusra khula nahi / band ho gaya) -> PairOrphanSec baad band
      if(legs[k]<2)
      {
         if(PairOrphanSec>0 && nowMs-first[k] > (long)PairOrphanSec*1000) PairClose(grp[k], pl[k], "AKELA LEG", legs[k]);
         continue;
      }
      double st = gold[k]?Gold_Lock_Start:Lock_Start_Dollar, gp = gold[k]?Gold_Lock_Gap:Lock_Gap_Dollar, sp = gold[k]?Gold_Lock_Step:Lock_Step_Dollar;
      string gv = "PFXP_"+grp[k];
      double lock = GlobalVariableCheck(gv) ? GlobalVariableGet(gv) : -1e9;   // EA restart ke baad bhi yaad
      double g = pl[k]/kf;                                                     // profit $ (0.01 lot pe)
      if(sp>0 && g >= st-1e-9)
      {
         double lk = (MathFloor(g/sp+1e-9)*sp - gp)*kf;
         if(lk>0 && lk>lock+1e-9){ lock=lk; GlobalVariableSet(gv, lock);
            Print("PERSONAL FX PAIR: ", grp[k], " P/L $", DoubleToString(pl[k],2), " -> lock +$", DoubleToString(lock,2)); }
      }
      if(lock>0 && pl[k] <= lock+1e-9)          { PairClose(grp[k], pl[k], "LOCK", legs[k]); continue; }
      if(PairSL_Usd>0 && pl[k] <= -PairSL_Usd*kf){ PairClose(grp[k], pl[k], "SL", legs[k]); continue; }
   }
}

// v6.8: app ko batao ye EA kis account pe chal raha hai (har 60 sec)
datetime g_AppLastBeat = 0;
string AppMyLogin(){ return IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)); }
void AppHeartbeat()
{
   if(TimeLocal()-g_AppLastBeat < 60) return;
   g_AppLastBeat = TimeLocal();
   long nowMs = (long)TimeGMT()*1000;
   string body = "{\"login\":\""+AppMyLogin()+"\""
      +",\"name\":\""+AppJsonSafe(AccountInfoString(ACCOUNT_NAME))+"\""
      +",\"server\":\""+AppJsonSafe(AccountInfoString(ACCOUNT_SERVER))+"\""
      +",\"cur\":\""+AppJsonSafe(AccountInfoString(ACCOUNT_CURRENCY))+"\""
      +",\"real\":"+(AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_REAL?"true":"false")
      +",\"bal\":"+DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE),2)
      +",\"eq\":"+DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY),2)
      +",\"lot\":"+DoubleToString(g_LotInput,2)
      +",\"ver\":\"6.9\",\"pair\":true,\"at\":"+IntegerToString(nowMs)+"}";
   string resp; int code;
   if(!AppHttp("POST", AppUrl("accounts/"+AppMyLogin()), body, "X-HTTP-Method-Override: PUT\r\n", resp, code))
      Print("PERSONAL FX APP: account heartbeat fail (", code, ")");
}

void PollAppOrders()
{
   if(!UseAppBridge || FirebaseURL=="") { g_AppStatus="OFF"; return; }
   if(MQLInfoInteger(MQL_TESTER)) return;                       // WebRequest not allowed in tester
   if(TimeLocal()-g_AppLastPoll < MathMax(1,AppPollSec)) return;
   g_AppLastPoll = TimeLocal();

   string resp; int code;
   string before = g_AppStatus;
   if(!AppHttp("GET", AppUrl("orders"), "", "", resp, code))
   {
      if(code>0) g_AppStatus = (code==401 || code==403) ? "AUTH CHAHIYE" : "HTTP "+IntegerToString(code);
      if(g_AppStatus!=before)
      {
         Print("PERSONAL FX APP: Firebase read FAIL -> ", g_AppStatus, " | code ", code, " | reply: ", StringSubstr(resp,0,160));
         if((code==401 || code==403) && !g_AppAuthWarned)
         {
            g_AppAuthWarned = true;
            Alert("PERSONAL FX: Firebase rules band hain (", code, "). EA input 'FirebaseAuth' me wahi secret daalo jo SamuSignal Settings / FXBridgeEA me hai.");
         }
      }
      return;
   }
   if(StringFind(before,"ON")!=0) Print("PERSONAL FX APP: Firebase connected - account ", AppMyLogin(), " ke app orders padh raha hoon (har ", AppPollSec, " sec)");
   AppHeartbeat();   // v6.8
   g_AppLastOk = TimeLocal();
   g_AppStatus = "ON | "+TimeToString(g_AppLastOk, TIME_SECONDS);
   StringTrimLeft(resp); StringTrimRight(resp);
   if(resp=="" || resp=="null") return;

   string keys[], objs[];
   int n = AppSplitRecords(resp, keys, objs);
   // v5.9: key -> batch map (AppReplaceOld isi se apna batch pehchaanta hai)
   ArrayResize(g_PollKey, n); ArrayResize(g_PollBatch, n); g_PollN = n;
   for(int i=0;i<n;i++){ g_PollKey[i]=keys[i]; g_PollBatch[i]=JsonStr(objs[i],"batch"); }
   // oldest first, so orders are placed in the order you sent them
   for(int a=0;a<n-1;a++)
      for(int b=a+1;b<n;b++)
         if(JsonNum(objs[b],"at") < JsonNum(objs[a],"at"))
         { string tk=keys[a]; keys[a]=keys[b]; keys[b]=tk; string to=objs[a]; objs[a]=objs[b]; objs[b]=to; }
   for(int i=0;i<n;i++)
   {
      if(JsonStr(objs[i],"status")!="NEW") continue;
      if(AppIsDone(keys[i])) continue;
      // v6.8: order kis account ka hai? dusre account ka -> chhuo bhi mat
      string acct = JsonStr(objs[i],"acct");
      if(acct=="" && JsonNum(objs[i],"acct")>0) acct = DoubleToString(JsonNum(objs[i],"acct"),0);
      if(acct!="" && acct!=AppMyLogin()) continue;
      if(acct=="" && !AppAcceptUntagged) continue;
      ProcessAppOrder(keys[i], objs[i]);
   }
}

//+------------------------------------------------------------------+
//|  v5.9 APP BATCH OCO                                               |
//|  App ka koi pending (comment "PFXA<key>") BHAR gaya -> usi pair ke |
//|  baaki saare app pending (jo us fill se PEHLE lage the) cancel,    |
//|  direction chahe kuch bhi ho. Naya order (fill ke BAAD laga) nahi  |
//|  chhuta. EA/VPS restart ke baad bhi chalta hai (MT5 history se).   |
//+------------------------------------------------------------------+
string OpeningOrderComment()
{
   long ident = posInfo.Identifier();                 // = ticket of the order that opened it
   if(HistoryOrderSelect((ulong)ident))
   {
      string c = HistoryOrderGetString((ulong)ident, ORDER_COMMENT);
      if(c!="") return c;
   }
   return posInfo.Comment();
}

void ManageAppBatchOCO()
{
   if(!AppBatchOCO) return;
   if(OrdersTotal()==0) return;

   // 1) app pending se khule positions (= fill)
   string fSym[60]; long fTime[60]; ulong fTk[60]; int nF=0;
   for(int i=0; i<PositionsTotal() && nF<60; i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(StringFind(OpeningOrderComment(),"PFXA")!=0) continue;
      fSym[nF]  = posInfo.Symbol();
      fTime[nF] = posInfo.TimeMsc();
      fTk[nF]   = posInfo.Ticket();
      nF++;
   }
   if(nF==0) return;

   // 2) usi pair ke baaki app pending (fill se pehle lage) -> cancel
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0) continue;
      if(!IsPendingType(OrderGetInteger(ORDER_TYPE))) continue;
      string cm = OrderGetString(ORDER_COMMENT);
      if(StringFind(cm,"PFXA")!=0) continue;
      string sym  = OrderGetString(ORDER_SYMBOL);
      long  setup = OrderGetInteger(ORDER_TIME_SETUP_MSC);
      ulong trig  = 0;
      for(int f=0; f<nF; f++)
         if(fSym[f]==sym && setup < fTime[f]) { trig = fTk[f]; break; }
      if(trig==0) continue;

      int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      string otxt = EnumToString((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE));
      double opx  = OrderGetDouble(ORDER_PRICE_OPEN);
      if(trade.OrderDelete(tk))
      {
         string msg = "PERSONAL FX BATCH: "+sym+" app order bhara (#"+IntegerToString((long)trig)+
                      ") -> baaki "+otxt+" @ "+DoubleToString(opx,dg)+" cancel";
         Print(msg);
         if(UsePushNotify) SendNotification(msg);
         if(UseAppBridge && FirebaseURL!="" && !MQLInfoInteger(MQL_TESTER) && StringLen(cm)>=23)
            AppSetStatus(StringSubstr(cm,4), "CANCELLED", "#"+IntegerToString((long)tk)+" dusra order (#"+IntegerToString((long)trig)+") pehle bhara");
      }
      else
         Print("PERSONAL FX BATCH: cancel FAILED ",sym," #",tk," [",trade.ResultRetcode(),"] ",
               trade.ResultRetcodeDescription());
   }
}

// app pendings (comment "PFXA<key>") not filled in AppPendingExpiryMin -> delete + tell app
//+------------------------------------------------------------------+
//|  v7.3: NEWS FILTER — MT5 calendar se aane wali High news          |
//+------------------------------------------------------------------+
datetime g_NewsT[];  string g_NewsCur[], g_NewsName[];
datetime g_NewsLoaded = 0;
void NewsLoad()
{
   if(TimeLocal() - g_NewsLoaded < 60 && g_NewsLoaded>0) return;   // har minute taaza
   g_NewsLoaded = TimeLocal();
   ArrayResize(g_NewsT, 0); ArrayResize(g_NewsCur, 0); ArrayResize(g_NewsName, 0);
   datetime now = TimeTradeServer();
   MqlCalendarValue v[];
   int n = CalendarValueHistory(v, now - (NewsAfterMin+5)*60, now + (NewsBeforeMin+65)*60);
   for(int i=0;i<n;i++)
   {
      MqlCalendarEvent e;
      if(!CalendarEventById(v[i].event_id, e)) continue;
      if(!(e.importance==CALENDAR_IMPORTANCE_HIGH || (NewsWithMedium && e.importance==CALENDAR_IMPORTANCE_MODERATE))) continue;
      if(e.type==CALENDAR_TYPE_HOLIDAY) continue;
      MqlCalendarCountry c;
      if(!CalendarCountryById(e.country_id, c)) continue;
      int m = ArraySize(g_NewsT);
      ArrayResize(g_NewsT, m+1); ArrayResize(g_NewsCur, m+1); ArrayResize(g_NewsName, m+1);
      g_NewsT[m] = v[i].time; g_NewsCur[m] = c.currency; g_NewsName[m] = e.name;
   }
}
// sym ki currency (base / profit; gold = USD) ki news window me? why = "USD CPI m/m 19:00"
bool NewsBlock(string sym, string &why)
{
   why = "";
   if(!NewsCancelPending) return false;
   NewsLoad();
   string b = SymbolInfoString(sym, SYMBOL_CURRENCY_BASE), p = SymbolInfoString(sym, SYMBOL_CURRENCY_PROFIT);
   datetime now = TimeTradeServer();
   for(int i=0;i<ArraySize(g_NewsT);i++)
   {
      if(g_NewsCur[i]!=b && g_NewsCur[i]!=p) continue;
      long left = (long)(g_NewsT[i] - now);
      if(left > NewsBeforeMin*60 || left < -NewsAfterMin*60) continue;
      long ist = (long)g_NewsT[i] - (long)(TimeTradeServer() - TimeGMT()) + 19800;
      why = g_NewsCur[i]+" "+g_NewsName[i]+" "+StringSubstr(TimeToString((datetime)ist, TIME_DATE|TIME_MINUTES), 11)+" IST"
            + (left>0 ? " ("+IntegerToString((int)(left/60))+" min me)" : " (abhi hui)");
      return true;
   }
   return false;
}
// app ke pending (PFXA, abhi nahi bhare) jinke pair pe news aa rahi hai -> cancel
void CheckNewsPending()
{
   if(!NewsCancelPending) return;
   static datetime last = 0;
   if(TimeLocal() - last < 5) return;                     // har 5 sec kaafi
   last = TimeLocal();
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0) continue;
      string cm = OrderGetString(ORDER_COMMENT);
      if(StringFind(cm,"PFXA")!=0) continue;               // sirf app ke pending
      string sym = OrderGetString(ORDER_SYMBOL), why;
      if(!NewsBlock(sym, why)) continue;
      if(trade.OrderDelete(tk))
      {
         string m = "#"+IntegerToString((long)tk)+" news se pehle hataya: "+why;
         Print("PERSONAL FX NEWS: ", sym, " ", m);
         if(UseAppBridge && FirebaseURL!="" && !MQLInfoInteger(MQL_TESTER) && StringLen(cm)>=23)
            AppSetStatus(StringSubstr(cm,4), "CANCELLED", m);
         if(UsePushNotify) SendNotification("PERSONAL FX NEWS: "+sym+" pending cancel — "+why);
      }
   }
}

//+------------------------------------------------------------------+
//|  v7.4: APP PENDING TREND JAANCH (15m EMA)                         |
//+------------------------------------------------------------------+
string g_AtSym[]; int g_AtH[];
int AppTrendHandle(string sym)
{
   for(int i=0;i<ArraySize(g_AtSym);i++) if(g_AtSym[i]==sym) return g_AtH[i];
   int h = iMA(sym, PERIOD_M15, AppTrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   int n = ArraySize(g_AtSym);
   ArrayResize(g_AtSym, n+1); ArrayResize(g_AtH, n+1);
   g_AtSym[n] = sym; g_AtH[n] = h;
   return h;
}
// true = 15m trend order ke ulta: BUY ke liye aakhri band 15m candle EMA ke neeche + EMA neeche jhuka (SELL ulta)
bool AppTrendFlipped(string sym, bool isBuy, string &why)
{
   why = "";
   if(!AppTrendRecheck) return false;
   int h = AppTrendHandle(sym);
   if(h == INVALID_HANDLE) return false;
   double e[];
   ArraySetAsSeries(e, true);
   if(CopyBuffer(h, 0, 1, 2, e) != 2) return false;        // data abhi taiyar nahi -> rok nahi
   double c = iClose(sym, PERIOD_M15, 1);
   if(c <= 0) return false;
   int dg = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
   if(isBuy && c < e[0] && e[0] < e[1])
   { why = "15m trend neeche palta (close "+DoubleToString(c,dg)+" < EMA"+IntegerToString(AppTrendEMA)+" "+DoubleToString(e[0],dg)+")"; return true; }
   if(!isBuy && c > e[0] && e[0] > e[1])
   { why = "15m trend upar palta (close "+DoubleToString(c,dg)+" > EMA"+IntegerToString(AppTrendEMA)+" "+DoubleToString(e[0],dg)+")"; return true; }
   return false;
}
// app ke pending (PFXA, abhi nahi bhare) jinka 15m trend palat gaya -> cancel
void CheckAppTrendPending()
{
   if(!AppTrendRecheck) return;
   static datetime last = 0;
   if(TimeLocal() - last < 10) return;                     // har 10 sec kaafi (15m candle band hone par badalta hai)
   last = TimeLocal();
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0) continue;
      string cm = OrderGetString(ORDER_COMMENT);
      if(StringFind(cm,"PFXA")!=0) continue;               // sirf app ke pending
      long ty = OrderGetInteger(ORDER_TYPE);
      bool isBuy = (ty==ORDER_TYPE_BUY_LIMIT || ty==ORDER_TYPE_BUY_STOP);
      string sym = OrderGetString(ORDER_SYMBOL), why;
      if(!AppTrendFlipped(sym, isBuy, why)) continue;
      if(trade.OrderDelete(tk))
      {
         string m = "#"+IntegerToString((long)tk)+" trend palta: "+why;
         Print("PERSONAL FX TREND: ", sym, " ", m);
         if(UseAppBridge && FirebaseURL!="" && !MQLInfoInteger(MQL_TESTER) && StringLen(cm)>=23)
            AppSetStatus(StringSubstr(cm,4), "CANCELLED", m);
         if(UsePushNotify) SendNotification("PERSONAL FX TREND: "+sym+" pending cancel - "+why);
      }
   }
}

void CheckAppPendingExpiry()
{
   if(AppPendingExpiryMin<=0) return;
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      ulong tk = OrderGetTicket(i);
      if(tk==0) continue;
      string cm = OrderGetString(ORDER_COMMENT);
      if(StringFind(cm,"PFXA")!=0) continue;
      datetime setup = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
      if(TimeCurrent()-setup < AppPendingExpiryMin*60) continue;
      string sym = OrderGetString(ORDER_SYMBOL);
      if(trade.OrderDelete(tk))
      {
         Print("PERSONAL FX APP: ", sym, " pending #", tk, " ", AppPendingExpiryMin, " min me nahi bhara -> hata diya");
         if(UseAppBridge && FirebaseURL!="" && !MQLInfoInteger(MQL_TESTER) && StringLen(cm)>=23)
            AppSetStatus(StringSubstr(cm,4), "EXPIRED", "#"+IntegerToString((long)tk)+" "+IntegerToString(AppPendingExpiryMin)+" min me nahi bhara - hata diya");
      }
   }
}

//+------------------------------------------------------------------+
//|  MANUAL TRADE ENTRY — starts a fresh grid on this symbol          |
//+------------------------------------------------------------------+
void ExecuteManualTrade(ENUM_ORDER_TYPE type)
{
   string sym = (g_ActiveSymbol!="") ? g_ActiveSymbol : _Symbol;

   if(sym=="" || SymbolInfoDouble(sym,SYMBOL_BID)<=0)
   { Alert("PERSONAL FX: Invalid/unknown symbol \""+sym+"\" — type it correctly and press SET"); return; }

   if(!IsAllowedSymbol(sym))
   { Alert("PERSONAL FX: \""+sym+"\" is not in AllowedSymbolsCSV — add it in inputs or clear the whitelist"); return; }

   if(UseDailyLimits && g_DailyLimitHit)
   { Alert("PERSONAL FX: DAILY LIMIT HIT — no new trades today"); return; }

   if(GetSymbolPositionCount(sym) > 0)
   { Alert("PERSONAL FX: Grid already active on "+sym+" — wait for it to close first."); return; }

   string spTxt = "";
   if(SpreadTooHigh(sym, spTxt))
   { Alert("PERSONAL FX: SPREAD TOO HIGH: "+spTxt); return; }

   if(PositionsTotal() >= MaxOpenTrades)
   { Alert("PERSONAL FX: MAX OPEN TRADES REACHED"); return; }

   double price = (type==ORDER_TYPE_BUY) ? SymbolInfoDouble(sym,SYMBOL_ASK)
                                         : SymbolInfoDouble(sym,SYMBOL_BID);
   double lot = NormalizeLot(sym, g_LotInput);
   trade.SetTypeFillingBySymbol(sym);   // v5.4

   double marginReq=0, freeMargin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(!OrderCalcMargin(type, sym, lot, price, marginReq))
      Print("PERSONAL FX: OrderCalcMargin failed, err ", GetLastError());

   if(marginReq>0 && marginReq>freeMargin)
   {
      Alert("PERSONAL FX: NO MONEY! Lot ", DoubleToString(lot,2),
            " needs $", DoubleToString(marginReq,2),
            " margin, Free = $", DoubleToString(freeMargin,2));
      return;
   }

   bool ok=(type==ORDER_TYPE_BUY) ?
           trade.Buy(lot,sym,price,0,0,"PFX_MANUAL"):
           trade.Sell(lot,sym,price,0,0,"PFX_MANUAL");

   if(ok)
   {
      g_DailyTradeCount++;
      int gi = GridIndex(sym, true);
      g_GDir[gi]   = (type==ORDER_TYPE_BUY) ? 1 : -1;
      g_GAdds[gi]  = 0;
      g_GLot[gi]   = lot;
      g_GEntry[gi] = price;
      Print("PERSONAL FX: ", EnumToString(type), " opened on ", sym,
            " | Lot ", DoubleToString(lot,2), " | Grid started");
   }
   else
      Alert("PERSONAL FX: Trade FAILED [", trade.ResultRetcode(), "] ",
            trade.ResultRetcodeDescription());
}

//+------------------------------------------------------------------+
//|  DAILY LIMITS                                                     |
//+------------------------------------------------------------------+
void CheckDailyLimitsMonitor()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double eqPL  = equity - g_DayStartBalance;
   g_DailyPL = balance - g_DayStartBalance;

   // v6.6: daily loss limit hataya - loss ka control har pair ka basket SL karta hai
   if(eqPL >= MaxDailyProfit && !g_DailyLimitHit)
   {
      g_DailyLimitHit = true;
      CloseAllOurTrades();
      if(UsePushNotify)
         SendNotification("PERSONAL FX: Daily Target Hit! +$"+DoubleToString(eqPL,2));
   }
}

void CloseAllOurTrades()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      bool cand = IsCandlePos();                         // v7.6: candle trade bhi F8 / daily target me band
      if(!IsOurPos() && !cand) continue;
      if(cand) S5RememberWhy((ulong)posInfo.Identifier(), "CLOSE ALL");
      trade.PositionClose(posInfo.Ticket());
   }
   for(int g=0; g<g_GCount; g++) g_GAdds[g]=0;
}

//+------------------------------------------------------------------+
//|  DAILY RESET  (v6.1: weekend band hataya)                         |
//+------------------------------------------------------------------+

void CheckDailyReset()
{
   MqlDateTime now,last;
   TimeToStruct(TimeCurrent(),now);
   TimeToStruct(g_LastDayReset,last);
   if(now.day!=last.day)
   {
      g_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      g_DailyPL=0; g_DailyTradeCount=0; g_DailyLimitHit=false;
      g_LastDayReset = TimeCurrent();
      g_LogN=0;
      Print("PERSONAL FX: New trading day — daily limits reset");
   }
}

//+------------------------------------------------------------------+
//|  HELPERS                                                           |
//+------------------------------------------------------------------+
double NormalizeLot(string sym, double lot)
{
   double vmin = SymbolInfoDouble(sym, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(sym, SYMBOL_VOLUME_MAX);
   double vstp = SymbolInfoDouble(sym, SYMBOL_VOLUME_STEP);
   if(vstp <= 0) vstp = 0.01;
   lot = MathFloor(lot/vstp) * vstp;
   lot = MathMax(vmin, MathMin(vmax, lot));
   return NormalizeDouble(lot, 2);
}

void AdjustLot(int dir)
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step<=0) step=0.01;
   g_LotInput = NormalizeDouble(g_LotInput + dir*step, 2);
   g_LotInput = MathMax(MinLot, MathMin(MaxLot, g_LotInput));
}

// Resolves user-typed text (e.g. "gbpusd") to the broker's exact symbol
// name (e.g. "GBPUSD.m"). Returns "" if nothing matches.
string ResolveSymbol(string typed)
{
   string want = typed;
   StringToUpper(want);
   StringTrimLeft(want);
   StringTrimRight(want);
   if(want=="") return "";

   // exact match first
   if(SymbolSelect(want,true)) return want;

   // else scan the full symbol list for one that STARTS WITH the typed text
   int total = SymbolsTotal(false);
   for(int i=0;i<total;i++)
   {
      string s = SymbolName(i,false);
      string sUp = s;
      StringToUpper(sUp);
      if(StringFind(sUp,want)==0)
      {
         if(SymbolSelect(s,true)) return s;
      }
   }
   return "";
}

int SC_Digits()
{
   string s0 = (g_ActiveSymbol!="") ? g_ActiveSymbol : _Symbol;
   int d=(int)SymbolInfoInteger(s0, SYMBOL_DIGITS);
   return MathMax(2, MathMin(5, d));
}

int CountActiveGrids()
{
   string syms[50]; int n=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      string sym=posInfo.Symbol();
      bool found=false;
      for(int k=0;k<n;k++) if(syms[k]==sym){found=true;break;}
      if(!found && n<50) syms[n++]=sym;
   }
   return n;
}

double GetSymbolVolume(string sym)
{
   double v=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      if(posInfo.Symbol()!=sym) continue;
      v += posInfo.Volume();
   }
   return v;
}

double GetTotalFloatingPL()
{
   double t=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      t += posInfo.Profit()+posInfo.Swap();
   }
   return t;
}

//+------------------------------------------------------------------+
//|  CHART EVENTS — buttons + F-keys                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lp,const double &dp,const string &sp)
{
   if(id==CHARTEVENT_CHART_CHANGE)
   {
      int w=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
      if(ShowPanel && MathAbs(w-g_LastChartW)>4) RebuildPanel();
      return;
   }

   if(id==CHARTEVENT_KEYDOWN && EnableFKeys)
   {
      if(lp==117) ExecuteManualTrade(ORDER_TYPE_BUY);    // F6
      if(lp==118) ExecuteManualTrade(ORDER_TYPE_SELL);   // F7
      if(lp==119) CloseAllOurTrades();                   // F8
      return;
   }

   if(id==CHARTEVENT_OBJECT_ENDEDIT && sp==ED_SYM)
   { ApplySymbolFromEdit(); return; }

   if(id!=CHARTEVENT_OBJECT_CLICK) return;

   if(sp==BT_BUY  || sp==BT_F6) ExecuteManualTrade(ORDER_TYPE_BUY);
   if(sp==BT_SELL || sp==BT_F7) ExecuteManualTrade(ORDER_TYPE_SELL);
   if(sp==BT_LDN)                AdjustLot(-1);
   if(sp==BT_LUP)                AdjustLot(+1);
   if(sp==BT_CALL || sp==BT_F8)  CloseAllOurTrades();
   if(sp==BT_SYMSET)             ApplySymbolFromEdit();

   ObjectSetInteger(0,sp,OBJPROP_STATE,false);
   ChartRedraw(0);
}

// Reads whatever is typed in the symbol box, resolves it against the
// broker's symbol list, and if valid makes it the active trading symbol.
void ApplySymbolFromEdit()
{
   string typed = ObjectGetString(0, ED_SYM, OBJPROP_TEXT);
   string resolved = ResolveSymbol(typed);
   if(resolved=="")
   {
      Alert("PERSONAL FX: Symbol \""+typed+"\" not found with this broker");
      ObjectSetInteger(0, ED_SYM, OBJPROP_COLOR, QT_RED);
      return;
   }
   g_ActiveSymbol = resolved;
   ObjectSetString(0, ED_SYM, OBJPROP_TEXT, resolved);
   ObjectSetInteger(0, ED_SYM, OBJPROP_COLOR, QT_GREEN);
   Print("PERSONAL FX: Active trading symbol set to ", resolved);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//|  PANEL — BUILD  (FULL-WIDTH 3 columns, DPI-aware)                 |
//|  [1] ACTIVE PAIR & ORDER ENTRY | [3] ACCOUNT        | [6] MONITOR  |
//|  [2] GRID SETTINGS             | [4] RISK CONTROL   |              |
//|                                | [5] RECENT CLOSES  |              |
//+------------------------------------------------------------------+
int SC(int v) { return (int)MathRound(v*g_S); }

string DotPad(string label, int n)
{
   string r = label + " ";
   while(StringLen(r) < n) r += ".";
   return r;
}

void Sect(string n, string txt, int colx, int y)
{
   Rect("PFX_S_"+n, colx, y, g_CW, SC(24), QT_SECT);
   Lbl("PFX_SL_"+n, txt, colx+SC(8), y+SC(4), QT_AMBER, Panel_FontSize, QFONT);
}

void MakeRow(string id, string label, int colx, int y)
{
   Lbl("PFX_"+id+"_L", DotPad(label,g_LabChars), colx+SC(10), y, QT_AMBERD, Panel_FontSize, QFONT);
   Lbl("PFX_"+id+"_V", "--", colx+g_ValX, y, QT_WHITE, Panel_FontSize, QFONT);
}

void SetV(string id, string txt, color c)
{
   ObjectSetString(0,"PFX_"+id+"_V",OBJPROP_TEXT,txt);
   ObjectSetInteger(0,"PFX_"+id+"_V",OBJPROP_COLOR,c);
}

void OutBtn(string inner, string txt, int x, int y, int w, int h,
            color border, color fg, int fsz)
{
   int b=MathMax(2,SC(2));
   Rect("PFX_BR_"+inner, x, y, w, h, border);
   Btn(inner, txt, x+b, y+b, w-2*b, h-2*b, QT_DARKBTN, fg, fsz);
}

void RebuildPanel()
{
   ObjectsDeleteAll(0, "PFX_");
   BuildPanel();
   UpdatePanel();
}

void BuildPanel()
{
   int x=Panel_X, y=Panel_Y;
   int fs=Panel_FontSize;

   // ---- fit to the chart width ----
   int chartW = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   g_LastChartW = chartW;
   int PW  = MathMax(SC(760), chartW - 2*Panel_X);
   int gap = SC(8);
   int cw  = (PW - 2*SC(8) - 2*gap)/3;
   g_CW = cw;

   int c1=x+SC(8);
   int c2=c1+cw+gap;
   int c3=c2+cw+gap;

   int RH=SC(fs*2+4);            // row pitch
   int SH=SC(24);                // section header height
   int y0=y+SC(40);

   // text metrics (Consolas is monospaced, ~0.55 em wide)
   int charW = (int)MathRound(fs*96.0/72.0*g_DpiS*0.55);
   if(charW<6) charW=6;
   int avail = (cw-SC(20))/charW;
   g_LabChars = MathMax(14, MathMin(22, avail-18));
   g_ValX     = SC(10) + (g_LabChars+1)*charW;

   // background + borders (resized to real height at the end)
   Rect("PFX_BG",  x, y, PW, 100, QT_BG);
   Rect("PFX_B1",  x, y, PW, 2, QT_BORDER);
   Rect("PFX_B2",  x, y+98, PW, 2, QT_BORDER);
   Rect("PFX_B3",  x, y, 2, 100, QT_BORDER);
   Rect("PFX_B4",  x+PW-2, y, 2, 100, QT_BORDER);

   Rect("PFX_TITLE_BG", x, y, PW, SC(32), QT_AMBER);
   Lbl ("PFX_TITLE",   (Strategy==STRAT_6_HEDGE ? "PERSONAL FX v10.2 - STRATEGY 6  |  HEDGE LADDER: TP $"+DoubleToString(S6_TP_Usd,2)+"/0.01L, har $"+DoubleToString(S6_Gap_Usd,2)+" ulta "+DoubleToString(S6_HedgeLot,2)+"  |  BASKET +$"+DoubleToString(S6_BasketTP_Usd,2)+" / CYCLE +$"+DoubleToString(S6_CycleTP_Usd,2)
                       : Strategy==STRAT_4_RECOVER ? "PERSONAL FX v10.2 - STRATEGY 4  |  SCALP +$"+DoubleToString(S4_TP_Usd,2)+" / -$"+DoubleToString(S4_SL_Usd,2)+"  +  RECOVERY $"+DoubleToString(S4_BigTP_Usd,2)+" (lock +$"+DoubleToString(S4_LockTo_Usd,2)+")  |  NO GRID"
                       : Strategy==STRAT_3_SCALP ? "PERSONAL FX v10.2 - STRATEGY 3  |  SCALP +$"+DoubleToString(S3_TP_Usd,2)+" TP / -$"+DoubleToString(S3_SL_Usd,2)+" SL  |  NO GRID / MARTINGALE"
                       : Strategy==STRAT_2_SL ? "PERSONAL FX v10.2 - STRATEGY 2  |  $"+DoubleToString(S2_SL_Usd,2)+" SL + $"+DoubleToString(Grid_TP_Dollar,2)+" TP + LOCK  |  NO GRID / MARTINGALE"
                                             : "PERSONAL FX v10.2 - STRATEGY 1  |  MARTINGALE GRID  |  MANUAL + APP ENTRY + $ BASKET TP + OCO"),
        x+SC(12), y+SC(7), C'0,0,0', fs+1, QFONT);
   LblR("PFX_TITLE_R", "S5 CANDLE +$"+DoubleToString(S5_TP_Usd,2)+"/-$"+DoubleToString(S5_SL_Usd,2)+"    F6 BUY    F7 SELL    F8 CLOSE ALL", x+PW-SC(12), y+SC(8), C'0,0,0', fs);

   // ================= COLUMN 1 =================
   int yy=y0;
   Sect("SY","[1] ACTIVE PAIR & ORDER ENTRY", c1, yy);          yy+=SH+SC(6);
   int editW = MathMin(cw*55/100, SC(320));
   string es = (g_ActiveSymbol!="") ? g_ActiveSymbol : _Symbol;
   Edit(ED_SYM, es, c1+SC(10), yy, editW, SC(28), QT_DARKBTN, QT_GREEN, fs+1);
   OutBtn(BT_SYMSET, "SET", c1+SC(10)+editW+SC(8), yy, SC(90), SC(28), QT_AMBER, QT_AMBER, fs+1);
                                                                yy+=SC(28)+SC(10);
   int bw = (cw-SC(30))/2;
   OutBtn(BT_BUY,  "BUY  \x25B2", c1+SC(10),        yy, bw, SC(46), QT_GREEN, QT_GREEN, fs+3);
   OutBtn(BT_SELL, "SELL \x25BC", c1+SC(20)+bw,     yy, bw, SC(46), QT_RED,   QT_RED,   fs+3);
                                                                yy+=SC(46)+SC(10);
   int lx = c1+SC(10)+10*charW;
   Lbl ("PFX_LOT_L", DotPad("LOT SIZE",10), c1+SC(10), yy+SC(4), QT_AMBERD, fs, QFONT);
   Btn (BT_LDN,"-", lx, yy, SC(30), SC(26), QT_DARKBTN, QT_AMBER, fs+2);
   Lbl ("PFX_LOT_V","0.01", lx+SC(30)+SC(12), yy+SC(4), QT_AMBER, fs+1, QFONT);
   Btn (BT_LUP,"+", lx+SC(30)+SC(12)+6*charW, yy, SC(30), SC(26), QT_DARKBTN, QT_AMBER, fs+2);
                                                                yy+=SC(26)+SC(10);
   OutBtn(BT_CALL,"CLOSE ALL  [F8]", c1+SC(10), yy, cw-SC(20), SC(30), QT_RED, QT_RED, fs);
                                                                yy+=SC(30)+SC(12);

   Sect("GS","[2] GRID SETTINGS", c1, yy);                      yy+=SH+SC(4);
   MakeRow("GTP","TP / 0.01 LOT", c1, yy);                      yy+=RH;
   MakeRow("GGP","ADD GAP",       c1, yy);                      yy+=RH;
   MakeRow("GBT","BASKET TP",     c1, yy);                      yy+=RH;
   MakeRow("GMX","MAX ADDS",      c1, yy);                      yy+=RH;
   MakeRow("GOC","OCO PENDING",   c1, yy);                      yy+=RH;
   MakeRow("GAB","APP BRIDGE",    c1, yy);                      yy+=RH;
   MakeRow("GPL","PROFIT LOCK",   c1, yy);                      yy+=RH;
   int bottom1=yy;

   // ================= COLUMN 2 =================
   yy=y0;
   Sect("AC","[3] ACCOUNT", c2, yy);                            yy+=SH+SC(4);
   MakeRow("BAL","BALANCE",   c2, yy);                          yy+=RH;
   MakeRow("EQ", "EQUITY",    c2, yy);                          yy+=RH;
   MakeRow("DPL","DAILY P&L", c2, yy);                          yy+=RH;
   MakeRow("FPL","FLOAT P&L", c2, yy);                          yy+=RH+SC(8);

   Sect("RM","[4] RISK CONTROL", c2, yy);                       yy+=SH+SC(4);
   MakeRow("TD","TRADES TODAY", c2, yy);                        yy+=RH;
   MakeRow("DD","DAILY DD",     c2, yy);                        yy+=RH;
   MakeRow("DT","DAILY TARGET", c2, yy);                        yy+=RH+SC(8);

   Sect("LG","[5] RECENT CLOSES", c2, yy);                      yy+=SH+SC(4);
   for(int i=0;i<5;i++)
   {
      Lbl("PFX_LGT"+IntegerToString(i), "--", c2+SC(10),               yy, QT_DOTS,  fs-1, QFONT);
      Lbl("PFX_LGX"+IntegerToString(i), " ",  c2+SC(10)+10*charW,      yy, QT_WHITE, fs-1, QFONT);
      Lbl("PFX_LGP"+IntegerToString(i), " ",  c2+SC(10)+18*charW,      yy, QT_DOTS,  fs-1, QFONT);
      yy+=RH-SC(4);
   }
   int bottom2=yy;

   // ================= COLUMN 3 =================
   yy=y0;
   Sect("GM","[6] GRID MONITOR - LIVE (ANY PAIR)", c3, yy);    yy+=SH+SC(4);
   int mPair = SC(10);
   int mAdds = SC(10) + 14*charW;
   int mPL   = SC(10) + 20*charW;
   int mNext = SC(10) + 31*charW;
   Lbl("PFX_GMH0","PAIR / SIDE",  c3+mPair, yy, QT_AMBERD, fs-1, QFONT);
   Lbl("PFX_GMH1","ADDS",         c3+mAdds, yy, QT_AMBERD, fs-1, QFONT);
   Lbl("PFX_GMH2","BASKET P&L",   c3+mPL,   yy, QT_AMBERD, fs-1, QFONT);
   Lbl("PFX_GMH3","NEXT ADD",     c3+mNext, yy, QT_AMBERD, fs-1, QFONT);
   yy+=RH;
   for(int i=0;i<MAX_GRID_ROWS;i++)
   {
      string k=IntegerToString(i);
      Lbl("PFX_GMS"+k, "--", c3+mPair, yy, QT_WHITE, fs, QFONT);
      Lbl("PFX_GMA"+k, "--", c3+mAdds, yy, QT_DOTS,  fs, QFONT);
      Lbl("PFX_GMP"+k, "--", c3+mPL,   yy, QT_DOTS,  fs, QFONT);
      Lbl("PFX_GMN"+k, "--", c3+mNext, yy, QT_DOTS,  fs, QFONT);
      yy+=RH-SC(4);
   }
   int bottom3=yy;

   // ---- final panel height ----
   int bottom = MathMax(bottom1, MathMax(bottom2, bottom3));
   int PH = bottom - y + SC(10);
   Rect("PFX_BG",  x, y, PW, PH, QT_BG);
   Rect("PFX_B2",  x, y+PH-2, PW, 2, QT_BORDER);
   Rect("PFX_B3",  x, y, 2, PH, QT_BORDER);
   Rect("PFX_B4",  x+PW-2, y, 2, PH, QT_BORDER);
}

//+------------------------------------------------------------------+
//|  PANEL — UPDATE                                                   |
//+------------------------------------------------------------------+
void UpdatePanel()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double floatPL = GetTotalFloatingPL();
   double eqPL    = equity - g_DayStartBalance;
   double balPL   = balance - g_DayStartBalance;

   SetV("BAL","$"+DoubleToString(balance,2), QT_WHITE);
   SetV("EQ", "$"+DoubleToString(equity,2),  QT_WHITE);
   SetV("DPL",(balPL>=0?"+$":"-$")+DoubleToString(MathAbs(balPL),2),
              balPL>=0?QT_GREEN:QT_RED);
   SetV("FPL",(floatPL>=0?"+$":"-$")+DoubleToString(MathAbs(floatPL),2),
              floatPL>=0?QT_GREEN:QT_RED);

   ObjectSetString(0,"PFX_LOT_V",OBJPROP_TEXT,DoubleToString(g_LotInput,2));

   SetV("TD", IntegerToString(g_DailyTradeCount), QT_WHITE);
   SetV("DD", (eqPL>=0?"+$":"-$")+DoubleToString(MathAbs(eqPL),2),
              eqPL<0?QT_RED:QT_WHITE);
   SetV("DT", "+$"+DoubleToString(MathMax(balPL,0),2)+" / +$"
              +DoubleToString(MaxDailyProfit,0), QT_GREEN);

   if(UsePriceDistanceGap)
      SetV("GTP","$"+DoubleToString(Grid_TP_Dollar,2)+" /0.01L", QT_WHITE);
   else
      SetV("GTP","$"+DoubleToString(Grid_TP_Dollar,2)+" /0.01L", QT_WHITE);
   if(UsePriceDistanceGap)
      SetV("GGP", (Grid_Gap_Usd>0) ? "$"+DoubleToString(Grid_Gap_Usd,2)+" /0.01L"
                                   : DoubleToString(Grid_Gap_Price,SC_Digits()) +" price", QT_WHITE);
   else
      SetV("GGP","$"+DoubleToString(Grid_Gap_Dollar,2), QT_WHITE);
   SetV("GBT","$"+DoubleToString(Grid_BasketTP_Dollar,2)+" flat", QT_WHITE);
   SetV("GMX",IntegerToString(Grid_MaxAdds), QT_WHITE);
   if(Strategy==STRAT_3_SCALP)    // v7.1
   {
      SetV("GTP","$"+DoubleToString(S3_TP_Usd,2)+" /0.01L (S3)", QT_AMBER);
      SetV("GGP","OFF (S3) | SL -$"+DoubleToString(S3_SL_Usd,2)+" /0.01L", QT_AMBER);
      SetV("GBT","OFF (S3)", QT_AMBERD);
      SetV("GMX","0 (S3)", QT_AMBERD);
   }
   if(Strategy==STRAT_4_RECOVER)  // v7.5
   {
      double debt = S4Debt();
      SetV("GTP","$"+DoubleToString(S4_TP_Usd,2)+" /0.01L (S4)", QT_AMBER);
      SetV("GGP","OFF (S4) | SL -$"+DoubleToString(S4_SL_Usd,2)+" /0.01L", QT_AMBER);
      SetV("GBT", debt>0.005 ? "RECOVERY ON: baaki $"+DoubleToString(debt,2) : "recovery OFF (aaj ghata nahi)", debt>0.005 ? QT_AMBER : QT_AMBERD);
      SetV("GMX","0 (S4)", QT_AMBERD);
   }
   if(Strategy==STRAT_6_HEDGE)    // v7.7
   {
      SetV("GTP","$"+DoubleToString(S6_TP_Usd,2)+" /0.01L (S6 main)", QT_AMBER);
      SetV("GGP","$"+DoubleToString(S6_Gap_Usd,2)+" /0.01L -> ulta "+DoubleToString(S6_HedgeLot,2), QT_AMBER);
      SetV("GBT","+$"+DoubleToString(S6_BasketTP_Usd,2)+" / +$"+DoubleToString(S6_CycleTP_Usd,2)+" / net +$"+DoubleToString(S6_CycleNetUsd,2), QT_AMBER);
      SetV("GMX", S6_MaxHedges>0 ? IntegerToString(S6_MaxHedges)+" hedge" : "seema nahi", QT_AMBER);
   }
   if(Strategy==STRAT_2_SL)       // v7.0
   {
      SetV("GGP","OFF (S2) | SL -$"+DoubleToString(S2_SL_Usd,2)+" /0.01L", QT_AMBER);
      SetV("GBT","OFF (S2)", QT_AMBERD);
      SetV("GMX","0 (S2)", QT_AMBERD);
   }
   if(OCO_Mode==OCO_OFF) SetV("GOC","OFF", QT_AMBERD);
   else SetV("GOC",(OCO_Mode==OCO_ALL_PAIRS?"ALL":"PAIR")+" | "+IntegerToString(CountOurPendings())+" pend", QT_GREEN);
   if(UseProfitLock) SetV("GPL", "+$"+DoubleToString(Lock_Start_Dollar,2)+" -> -$"+DoubleToString(Lock_Gap_Dollar,2)+" trail", QT_GREEN);
   else SetV("GPL", "OFF", QT_AMBERD);
   SetV("GAB", g_AppStatus, (g_AppStatus=="OFF") ? QT_AMBERD : (StringFind(g_AppStatus,"ON")==0 ? QT_GREEN : QT_RED));

   // ---- Grid monitor rows ----
   string symsOpen[50]; int symCount=0;
   for(int i=0;i<PositionsTotal();i++)
   {
      if(!posInfo.SelectByIndex(i)) continue;
      if(!IsOurPos()) continue;
      string sym=posInfo.Symbol();
      bool found=false;
      for(int k=0;k<symCount;k++) if(symsOpen[k]==sym){found=true;break;}
      if(!found && symCount<50) symsOpen[symCount++]=sym;
   }

   for(int i=0;i<MAX_GRID_ROWS;i++)
   {
      if(i<symCount)
      {
         string sym=symsOpen[i];
         int gi = GridIndex(sym,false);
         double pl = GetSymbolFloatingPL(sym);
         string dirTxt = (gi>=0 && g_GDir[gi]==1) ? "BUY" : "SELL";
         int adds = (gi>=0) ? g_GAdds[gi] : 0;
         string addsTxt = IntegerToString(adds)+"/"+IntegerToString(Grid_MaxAdds);
         color plC = pl>=0?QT_GREEN:QT_RED;
         if(gi>=0 && g_GAdds[gi]>=Grid_MaxAdds) plC = QT_AMBER; // maxed out, waiting for TP

         ObjectSetString(0,"PFX_GMS"+IntegerToString(i),OBJPROP_TEXT, sym+" "+dirTxt);
         ObjectSetString(0,"PFX_GMA"+IntegerToString(i),OBJPROP_TEXT, addsTxt);
         ObjectSetString(0,"PFX_GMP"+IntegerToString(i),OBJPROP_TEXT,
                        (pl>=0?"+$":"-$")+DoubleToString(MathAbs(pl),2));
         ObjectSetInteger(0,"PFX_GMP"+IntegerToString(i),OBJPROP_COLOR,plC);
         string nxt;
         if(adds>=Grid_MaxAdds) nxt="MAXED";
         else if(UsePriceDistanceGap && gi>=0 && g_GEntry[gi]>0)
         {
            double step = (adds+1)*GridGapDistance(sym);   // v5.8
            double lvl  = (g_GDir[gi]==1) ? g_GEntry[gi]-step : g_GEntry[gi]+step;
            nxt = DoubleToString(lvl,(int)SymbolInfoInteger(sym,SYMBOL_DIGITS));
         }
         else nxt = "-$"+DoubleToString((adds+1)*Grid_Gap_Dollar,0);
         ObjectSetString(0,"PFX_GMN"+IntegerToString(i),OBJPROP_TEXT,nxt);
         ObjectSetInteger(0,"PFX_GMN"+IntegerToString(i),OBJPROP_COLOR,(adds>=Grid_MaxAdds)?QT_AMBER:QT_WHITE);
      }
      else
      {
         ObjectSetString(0,"PFX_GMS"+IntegerToString(i),OBJPROP_TEXT,"--");
         ObjectSetString(0,"PFX_GMA"+IntegerToString(i),OBJPROP_TEXT,"--");
         ObjectSetString(0,"PFX_GMP"+IntegerToString(i),OBJPROP_TEXT,"--");
         ObjectSetInteger(0,"PFX_GMP"+IntegerToString(i),OBJPROP_COLOR,QT_DOTS);
         ObjectSetString(0,"PFX_GMN"+IntegerToString(i),OBJPROP_TEXT,"--");
         ObjectSetInteger(0,"PFX_GMN"+IntegerToString(i),OBJPROP_COLOR,QT_DOTS);
      }
   }

   // ---- recent closes log ----
   for(int i=0;i<5;i++)
   {
      string n1="PFX_LGT"+IntegerToString(i);
      string n2="PFX_LGX"+IntegerToString(i);
      string n3="PFX_LGP"+IntegerToString(i);
      if(i<g_LogN)
      {
         ObjectSetString(0,n1,OBJPROP_TEXT,g_LogTime[i]);
         ObjectSetString(0,n2,OBJPROP_TEXT,g_LogText[i]);
         ObjectSetString(0,n3,OBJPROP_TEXT,(g_LogPL[i]>=0?"+$":"-$")+DoubleToString(MathAbs(g_LogPL[i]),2));
         ObjectSetInteger(0,n3,OBJPROP_COLOR,g_LogPL[i]>=0?QT_GREEN:QT_RED);
      }
      else
      {
         ObjectSetString(0,n1,OBJPROP_TEXT,"--");
         ObjectSetString(0,n2,OBJPROP_TEXT," ");
         ObjectSetString(0,n3,OBJPROP_TEXT," ");
      }
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//|  UI PRIMITIVES                                                     |
//+------------------------------------------------------------------+
void Rect(string n,int x,int y,int w,int h,color c)
{
   if(ObjectFind(0,n)<0)
      ObjectCreate(0,n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,c);
   ObjectSetInteger(0,n,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_BACK,false);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
}

void Lbl(string n,string t,int x,int y,color c,int f,string font)
{
   if(ObjectFind(0,n)<0)
      ObjectCreate(0,n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
   ObjectSetString(0,n,OBJPROP_TEXT,t);
   ObjectSetInteger(0,n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,f);
   ObjectSetString(0,n,OBJPROP_FONT,font);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
}

void LblR(string n,string t,int x,int y,color c,int f)
{
   Lbl(n,t,x,y,c,f,QFONT);
   ObjectSetInteger(0,n,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
}

void Btn(string n,string t,int x,int y,int w,int h,color bg,color fg,int f)
{
   if(ObjectFind(0,n)<0)
      ObjectCreate(0,n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,h);
   ObjectSetString(0,n,OBJPROP_TEXT,t);
   ObjectSetInteger(0,n,OBJPROP_COLOR,fg);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,f);
   ObjectSetString(0,n,OBJPROP_FONT,QFONT);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
}

void Edit(string n,string t,int x,int y,int w,int h,color bg,color fg,int f)
{
   if(ObjectFind(0,n)<0)
      ObjectCreate(0,n,OBJ_EDIT,0,0,0);
   ObjectSetInteger(0,n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,n,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,n,OBJPROP_YSIZE,h);
   ObjectSetString(0,n,OBJPROP_TEXT,t);
   ObjectSetInteger(0,n,OBJPROP_COLOR,fg);
   ObjectSetInteger(0,n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,n,OBJPROP_BORDER_COLOR,QT_AMBERD);
   ObjectSetInteger(0,n,OBJPROP_FONTSIZE,f);
   ObjectSetString(0,n,OBJPROP_FONT,QFONT);
   ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,n,OBJPROP_ALIGN,ALIGN_CENTER);
   ObjectSetInteger(0,n,OBJPROP_SELECTABLE,true);
}

//+------------------------------------------------------------------+
//|  END PERSONAL FX v10.2 — STRATEGY 1 GRID / 2 SL / 3 SCALP / 6 HEDGE |
//+------------------------------------------------------------------+
