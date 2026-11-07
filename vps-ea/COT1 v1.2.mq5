//+------------------------------------------------------------------+
//|                                                         COT1.mq5 |
//|                                          Copyright 2024, Geraked |
//|                                       https://github.com/geraked |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2024, Geraked"
#property link        "https://github.com/geraked"
#property version     "1.2"
#property description "A strategy using Commitments of Traders (COT) and Super Trend indicator"
#property description "Multiple Symbols-Daily  2021.01.01 - 2024.01.14"


//===== BEGIN EAUtils.mqh =====
//+------------------------------------------------------------------+
//|                                                      EAUtils.mqh |
//|                                     Copyright 2023-2024, Geraked |
//|                                       https://github.com/geraked |
//+------------------------------------------------------------------+





//===== BEGIN errordescription.mqh =====
//+------------------------------------------------------------------+
//|                                             ErrorDescription.mqh |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| returns trade server return code description                     |
//+------------------------------------------------------------------+
string TradeServerReturnCodeDescription(int return_code)
  {
//---
   switch(return_code)
     {
      case TRADE_RETCODE_REQUOTE:            return("Requote");
      case TRADE_RETCODE_REJECT:             return("Request rejected");
      case TRADE_RETCODE_CANCEL:             return("Request canceled by trader");
      case TRADE_RETCODE_PLACED:             return("Order placed");
      case TRADE_RETCODE_DONE:               return("Request completed");
      case TRADE_RETCODE_DONE_PARTIAL:       return("Only part of the request was completed");
      case TRADE_RETCODE_ERROR:              return("Request processing error");
      case TRADE_RETCODE_TIMEOUT:            return("Request canceled by timeout");
      case TRADE_RETCODE_INVALID:            return("Invalid request");
      case TRADE_RETCODE_INVALID_VOLUME:     return("Invalid volume in the request");
      case TRADE_RETCODE_INVALID_PRICE:      return("Invalid price in the request");
      case TRADE_RETCODE_INVALID_STOPS:      return("Invalid stops in the request");
      case TRADE_RETCODE_TRADE_DISABLED:     return("Trade is disabled");
      case TRADE_RETCODE_MARKET_CLOSED:      return("Market is closed");
      case TRADE_RETCODE_NO_MONEY:           return("There is not enough money to complete the request");
      case TRADE_RETCODE_PRICE_CHANGED:      return("Prices changed");
      case TRADE_RETCODE_PRICE_OFF:          return("There are no quotes to process the request");
      case TRADE_RETCODE_INVALID_EXPIRATION: return("Invalid order expiration date in the request");
      case TRADE_RETCODE_ORDER_CHANGED:      return("Order state changed");
      case TRADE_RETCODE_TOO_MANY_REQUESTS:  return("Too frequent requests");
      case TRADE_RETCODE_NO_CHANGES:         return("No changes in request");
      case TRADE_RETCODE_SERVER_DISABLES_AT: return("Autotrading disabled by server");
      case TRADE_RETCODE_CLIENT_DISABLES_AT: return("Autotrading disabled by client terminal");
      case TRADE_RETCODE_LOCKED:             return("Request locked for processing");
      case TRADE_RETCODE_FROZEN:             return("Order or position frozen");
      case TRADE_RETCODE_INVALID_FILL:       return("Invalid order filling type");
      case TRADE_RETCODE_CONNECTION:         return("No connection with the trade server");
      case TRADE_RETCODE_ONLY_REAL:          return("Operation is allowed only for live accounts");
      case TRADE_RETCODE_LIMIT_ORDERS:       return("The number of pending orders has reached the limit");
      case TRADE_RETCODE_LIMIT_VOLUME:       return("The volume of orders and positions for the symbol has reached the limit");
     }
//---
   return("Invalid return code of the trade server");
  }
//+------------------------------------------------------------------+
//| returns runtime error code description                           |
//+------------------------------------------------------------------+
string ErrorDescription(int err_code)
  {
//---
   switch(err_code)
     {
      //--- Constant Description
      case ERR_SUCCESS:                      return("The operation completed successfully");
      case ERR_INTERNAL_ERROR:               return("Unexpected internal error");
      case ERR_WRONG_INTERNAL_PARAMETER:     return("Wrong parameter in the inner call of the client terminal function");
      case ERR_INVALID_PARAMETER:            return("Wrong parameter when calling the system function");
      case ERR_NOT_ENOUGH_MEMORY:            return("Not enough memory to perform the system function");
      case ERR_STRUCT_WITHOBJECTS_ORCLASS:   return("The structure contains objects of strings and/or dynamic arrays and/or structure of such objects and/or classes");
      case ERR_INVALID_ARRAY:                return("Array of a wrong type, wrong size, or a damaged object of a dynamic array");
      case ERR_ARRAY_RESIZE_ERROR:           return("Not enough memory for the relocation of an array, or an attempt to change the size of a static array");
      case ERR_STRING_RESIZE_ERROR:          return("Not enough memory for the relocation of string");
      case ERR_NOTINITIALIZED_STRING:        return("Not initialized string");
      case ERR_INVALID_DATETIME:             return("Invalid date and/or time");
      case ERR_ARRAY_BAD_SIZE:               return("Requested array size exceeds 2 GB");
      case ERR_INVALID_POINTER:              return("Wrong pointer");
      case ERR_INVALID_POINTER_TYPE:         return("Wrong type of pointer");
      case ERR_FUNCTION_NOT_ALLOWED:         return("System function is not allowed to call");
      //--- Charts	
      case ERR_CHART_WRONG_ID:               return("Wrong chart ID");
      case ERR_CHART_NO_REPLY:               return("Chart does not respond");
      case ERR_CHART_NOT_FOUND:              return("Chart not found");
      case ERR_CHART_NO_EXPERT:              return("No Expert Advisor in the chart that could handle the event");
      case ERR_CHART_CANNOT_OPEN:            return("Chart opening error");
      case ERR_CHART_CANNOT_CHANGE:          return("Failed to change chart symbol and period");
      //case ERR_CHART_WRONG_TIMER_PARAMETER:  return("Wrong parameter for timer");
      case ERR_CHART_CANNOT_CREATE_TIMER:    return("Failed to create timer");
      case ERR_CHART_WRONG_PROPERTY:         return("Wrong chart property ID");
      case ERR_CHART_SCREENSHOT_FAILED:      return("Error creating screenshots");
      case ERR_CHART_NAVIGATE_FAILED:        return("Error navigating through chart");
      case ERR_CHART_TEMPLATE_FAILED:        return("Error applying template");
      case ERR_CHART_WINDOW_NOT_FOUND:       return("Subwindow containing the indicator was not found");
      case ERR_CHART_INDICATOR_CANNOT_ADD:   return("Error adding an indicator to chart");
      case ERR_CHART_INDICATOR_CANNOT_DEL:   return("Error deleting an indicator from the chart");
      case ERR_CHART_INDICATOR_NOT_FOUND:    return("Indicator not found on the specified chart");
      //--- Graphical Objects	
      case ERR_OBJECT_ERROR:                 return("Error working with a graphical object");
      case ERR_OBJECT_NOT_FOUND:             return("Graphical object was not found");
      case ERR_OBJECT_WRONG_PROPERTY:        return("Wrong ID of a graphical object property");
      case ERR_OBJECT_GETDATE_FAILED:        return("Unable to get date corresponding to the value");
      case ERR_OBJECT_GETVALUE_FAILED:       return("Unable to get value corresponding to the date");
      //--- MarketInfo	
      case ERR_MARKET_UNKNOWN_SYMBOL:        return("Unknown symbol");
      case ERR_MARKET_NOT_SELECTED:          return("Symbol is not selected in MarketWatch");
      case ERR_MARKET_WRONG_PROPERTY:        return("Wrong identifier of a symbol property");
      case ERR_MARKET_LASTTIME_UNKNOWN:      return("Time of the last tick is not known (no ticks)");
      case ERR_MARKET_SELECT_ERROR:          return("Error adding or deleting a symbol in MarketWatch");
      //--- History Access	
      case ERR_HISTORY_NOT_FOUND:            return("Requested history not found");
      case ERR_HISTORY_WRONG_PROPERTY:       return("Wrong ID of the history property");
      //--- Global_Variables	
      case ERR_GLOBALVARIABLE_NOT_FOUND:     return("Global variable of the client terminal is not found");
      case ERR_GLOBALVARIABLE_EXISTS:        return("Global variable of the client terminal with the same name already exists");
      case ERR_MAIL_SEND_FAILED:             return("Email sending failed");
      case ERR_PLAY_SOUND_FAILED:            return("Sound playing failed");
      case ERR_MQL5_WRONG_PROPERTY:          return("Wrong identifier of the program property");
      case ERR_TERMINAL_WRONG_PROPERTY:      return("Wrong identifier of the terminal property");
      case ERR_FTP_SEND_FAILED:              return("File sending via ftp failed");
      case ERR_NOTIFICATION_SEND_FAILED:     return("Error in sending notification");
      //--- Custom Indicator Buffers
      case ERR_BUFFERS_NO_MEMORY:            return("Not enough memory for the distribution of indicator buffers");
      case ERR_BUFFERS_WRONG_INDEX:          return("Wrong indicator buffer index");
      //--- Custom Indicator Properties
      case ERR_CUSTOM_WRONG_PROPERTY:        return("Wrong ID of the custom indicator property");
      //--- Account
      case ERR_ACCOUNT_WRONG_PROPERTY:       return("Wrong account property ID");
      case ERR_TRADE_WRONG_PROPERTY:         return("Wrong trade property ID");
      case ERR_TRADE_DISABLED:               return("Trading by Expert Advisors prohibited");
      case ERR_TRADE_POSITION_NOT_FOUND:     return("Position not found");
      case ERR_TRADE_ORDER_NOT_FOUND:        return("Order not found");
      case ERR_TRADE_DEAL_NOT_FOUND:         return("Deal not found");
      case ERR_TRADE_SEND_FAILED:            return("Trade request sending failed");
      //--- Indicators	
      case ERR_INDICATOR_UNKNOWN_SYMBOL:     return("Unknown symbol");
      case ERR_INDICATOR_CANNOT_CREATE:      return("Indicator cannot be created");
      case ERR_INDICATOR_NO_MEMORY:          return("Not enough memory to add the indicator");
      case ERR_INDICATOR_CANNOT_APPLY:       return("The indicator cannot be applied to another indicator");
      case ERR_INDICATOR_CANNOT_ADD:         return("Error applying an indicator to chart");
      case ERR_INDICATOR_DATA_NOT_FOUND:     return("Requested data not found");
      case ERR_INDICATOR_WRONG_HANDLE:       return("Wrong indicator handle");
      case ERR_INDICATOR_WRONG_PARAMETERS:   return("Wrong number of parameters when creating an indicator");
      case ERR_INDICATOR_PARAMETERS_MISSING: return("No parameters when creating an indicator");
      case ERR_INDICATOR_CUSTOM_NAME:        return("The first parameter in the array must be the name of the custom indicator");
      case ERR_INDICATOR_PARAMETER_TYPE:     return("Invalid parameter type in the array when creating an indicator");
      case ERR_INDICATOR_WRONG_INDEX:        return("Wrong index of the requested indicator buffer");
      //--- Depth of Market	
      case ERR_BOOKS_CANNOT_ADD:             return("Depth Of Market can not be added");
      case ERR_BOOKS_CANNOT_DELETE:          return("Depth Of Market can not be removed");
      case ERR_BOOKS_CANNOT_GET:             return("The data from Depth Of Market can not be obtained");
      case ERR_BOOKS_CANNOT_SUBSCRIBE:       return("Error in subscribing to receive new data from Depth Of Market");
      //--- File Operations
      case ERR_TOO_MANY_FILES:               return("More than 64 files cannot be opened at the same time");
      case ERR_WRONG_FILENAME:               return("Invalid file name");
      case ERR_TOO_LONG_FILENAME:            return("Too long file name");
      case ERR_CANNOT_OPEN_FILE:             return("File opening error");
      case ERR_FILE_CACHEBUFFER_ERROR:       return("Not enough memory for cache to read");
      case ERR_CANNOT_DELETE_FILE:           return("File deleting error");
      case ERR_INVALID_FILEHANDLE:           return("A file with this handle was closed, or was not opening at all");
      case ERR_WRONG_FILEHANDLE:             return("Wrong file handle");
      case ERR_FILE_NOTTOWRITE:              return("The file must be opened for writing");
      case ERR_FILE_NOTTOREAD:               return("The file must be opened for reading");
      case ERR_FILE_NOTBIN:                  return("The file must be opened as a binary one");
      case ERR_FILE_NOTTXT:                  return("The file must be opened as a text");
      case ERR_FILE_NOTTXTORCSV:             return("The file must be opened as a text or CSV");
      case ERR_FILE_NOTCSV:                  return("The file must be opened as CSV");
      case ERR_FILE_READERROR:               return("File reading error");
      case ERR_FILE_BINSTRINGSIZE:           return("String size must be specified, because the file is opened as binary");
      case ERR_INCOMPATIBLE_FILE:            return("A text file must be for string arrays, for other arrays - binary");
      case ERR_FILE_IS_DIRECTORY:            return("This is not a file, this is a directory");
      case ERR_FILE_NOT_EXIST:               return("File does not exist");
      case ERR_FILE_CANNOT_REWRITE:          return("File can not be rewritten");
      case ERR_WRONG_DIRECTORYNAME:          return("Wrong directory name");
      case ERR_DIRECTORY_NOT_EXIST:          return("Directory does not exist");
      case ERR_FILE_ISNOT_DIRECTORY:         return("This is a file, not a directory");
      case ERR_CANNOT_DELETE_DIRECTORY:      return("The directory cannot be removed");
      case ERR_CANNOT_CLEAN_DIRECTORY:       return("Failed to clear the directory (probably one or more files are blocked and removal operation failed)");
      case ERR_FILE_WRITEERROR:              return("Failed to write a resource to a file");
      //--- String Casting	
      case ERR_NO_STRING_DATE:               return("No date in the string");
      case ERR_WRONG_STRING_DATE:            return("Wrong date in the string");
      case ERR_WRONG_STRING_TIME:            return("Wrong time in the string");
      case ERR_STRING_TIME_ERROR:            return("Error converting string to date");
      case ERR_STRING_OUT_OF_MEMORY:         return("Not enough memory for the string");
      case ERR_STRING_SMALL_LEN:             return("The string length is less than expected");
      case ERR_STRING_TOO_BIGNUMBER:         return("Too large number, more than ULONG_MAX");
      case ERR_WRONG_FORMATSTRING:           return("Invalid format string");
      case ERR_TOO_MANY_FORMATTERS:          return("Amount of format specifiers more than the parameters");
      case ERR_TOO_MANY_PARAMETERS:          return("Amount of parameters more than the format specifiers");
      case ERR_WRONG_STRING_PARAMETER:       return("Damaged parameter of string type");
      case ERR_STRINGPOS_OUTOFRANGE:         return("Position outside the string");
      case ERR_STRING_ZEROADDED:             return("0 added to the string end, a useless operation");
      case ERR_STRING_UNKNOWNTYPE:           return("Unknown data type when converting to a string");
      case ERR_WRONG_STRING_OBJECT:          return("Damaged string object");
      //--- Operations with Arrays	
      case ERR_INCOMPATIBLE_ARRAYS:          return("Copying incompatible arrays. String array can be copied only to a string array, and a numeric array - in numeric array only");
      case ERR_SMALL_ASSERIES_ARRAY:         return("The receiving array is declared as AS_SERIES, and it is of insufficient size");
      case ERR_SMALL_ARRAY:                  return("Too small array, the starting position is outside the array");
      case ERR_ZEROSIZE_ARRAY:               return("An array of zero length");
      case ERR_NUMBER_ARRAYS_ONLY:           return("Must be a numeric array");
      case ERR_ONEDIM_ARRAYS_ONLY:           return("Must be a one-dimensional array");
      case ERR_SERIES_ARRAY:                 return("Timeseries cannot be used");
      case ERR_DOUBLE_ARRAY_ONLY:            return("Must be an array of type double");
      case ERR_FLOAT_ARRAY_ONLY:             return("Must be an array of type float");
      case ERR_LONG_ARRAY_ONLY:              return("Must be an array of type long");
      case ERR_INT_ARRAY_ONLY:               return("Must be an array of type int");
      case ERR_SHORT_ARRAY_ONLY:             return("Must be an array of type short");
      case ERR_CHAR_ARRAY_ONLY:              return("Must be an array of type char");
      //--- Operations with OpenCL	
      case ERR_OPENCL_NOT_SUPPORTED:         return("OpenCL functions are not supported on this computer");
      case ERR_OPENCL_INTERNAL:              return("Internal error occurred when running OpenCL");
      case ERR_OPENCL_INVALID_HANDLE:        return("Invalid OpenCL handle");
      case ERR_OPENCL_CONTEXT_CREATE:        return("Error creating the OpenCL context");
      case ERR_OPENCL_QUEUE_CREATE:          return("Failed to create a run queue in OpenCL");
      case ERR_OPENCL_PROGRAM_CREATE:        return("Error occurred when compiling an OpenCL program");
      case ERR_OPENCL_TOO_LONG_KERNEL_NAME:  return("Too long kernel name (OpenCL kernel)");
      case ERR_OPENCL_KERNEL_CREATE:         return("Error creating an OpenCL kernel");
      case ERR_OPENCL_SET_KERNEL_PARAMETER:  return("Error occurred when setting parameters for the OpenCL kernel");
      case ERR_OPENCL_EXECUTE:               return("OpenCL program runtime error");
      case ERR_OPENCL_WRONG_BUFFER_SIZE:     return("Invalid size of the OpenCL buffer");
      case ERR_OPENCL_WRONG_BUFFER_OFFSET:   return("Invalid offset in the OpenCL buffer");
      case ERR_OPENCL_BUFFER_CREATE:         return("Failed to create and OpenCL buffer");
      //--- User-Defined Errors	
      default: if(err_code>=ERR_USER_ERROR_FIRST && err_code<ERR_USER_ERROR_LAST)
                                             return("User error "+string(err_code-ERR_USER_ERROR_FIRST));
     }
//---
   return("Unknown error");
  }
//+------------------------------------------------------------------+

//===== END errordescription.mqh =====


#define DIR "Geraked\\"

enum ENUM_NEWS_IMPORTANCE {
    NEWS_IMPORTANCE_NONE = CALENDAR_IMPORTANCE_NONE, // None
    NEWS_IMPORTANCE_LOW = CALENDAR_IMPORTANCE_LOW, // Low
    NEWS_IMPORTANCE_MEDIUM = CALENDAR_IMPORTANCE_MODERATE, // Medium
    NEWS_IMPORTANCE_HIGH = CALENDAR_IMPORTANCE_HIGH // High
};

enum ENUM_FILLING {
    FILLING_DEFAULT, // Default
    FILLING_FOK, // FOK
    FILLING_IOK, // IOK
    FILLING_BOC, // BOC
    FILLING_RETURN // RETURN
};

enum ENUM_SL {
    SL_SWING, // Swing
    SL_AR, // Average Range
    SL_MR, // Max Range
    SL_FIXED_POINT // Fixed Points
};

enum ENUM_RISK {
    RISK_DEFAULT, // Default
    RISK_FIXED_VOL, // Fixed Volume
    RISK_MIN_AMOUNT, // Min Amount
    RISK_EQUITY = ACCOUNT_EQUITY, // % of Equity
    RISK_BALANCE = ACCOUNT_BALANCE, // % of Balance
    RISK_MARGIN_FREE = ACCOUNT_MARGIN_FREE, // % of Free Margin
    RISK_CREDIT = ACCOUNT_CREDIT // % of Credit
};

class GerEA {
private:
    ulong magicNumber;
    bool authorized;
public:
    double risk;
    double martingaleRisk;
    bool martingale;
    int slippage;
    bool reverse;
    int nRetry;
    int mRetry;
    double trailingStopLevel;
    bool grid;
    double gridVolMult;
    double gridTrailingStopLevel;
    int gridMaxLvl;
    double equityDrawdownLimit;
    bool news;
    ENUM_NEWS_IMPORTANCE newsImportance;
    int newsMinsBefore;
    int newsMinsAfter;
    ENUM_FILLING filling;
    ENUM_RISK riskMode;

    GerEA() {
        risk = 0.01;
        martingaleRisk = 0.04;
        martingale = false;
        slippage = 30;
        reverse = false;
        nRetry = 5;
        mRetry = 2000;
        trailingStopLevel = 0.5;
        grid = false;
        gridVolMult = 1.0;
        gridTrailingStopLevel = 0;
        gridMaxLvl = 20;
        equityDrawdownLimit = 0;
        news = false;
        newsImportance = NEWS_IMPORTANCE_MEDIUM;
        newsMinsBefore = 60;
        newsMinsAfter = 60;
        filling = FILLING_DEFAULT;
        riskMode = RISK_DEFAULT;
    }

    void Init(int magicSeed = 1) {
        magicNumber = calcMagic(magicSeed);
        authorized = auth();
    }

    bool BuyOpen(double sl, double tp, bool isl = false, bool itp = false, string comment = "", string name = NULL, double vol = 0) {
        if (!reverse)
            return order(ORDER_TYPE_BUY, magicNumber, Ask(name), sl, tp, risk, martingale, martingaleRisk, slippage, isl, itp, comment, name, vol, nRetry, mRetry, news, newsImportance, newsMinsBefore, newsMinsAfter, filling, riskMode);
        return order(ORDER_TYPE_SELL, magicNumber, Bid(name), tp, sl, risk, martingale, martingaleRisk, slippage, itp, isl, comment, name, vol, nRetry, mRetry, news, newsImportance, newsMinsBefore, newsMinsAfter, filling, riskMode);
    }

    bool SellOpen(double sl, double tp, bool isl = false, bool itp = false, string comment = "", string name = NULL, double vol = 0) {
        if (!reverse)
            return order(ORDER_TYPE_SELL, magicNumber, Bid(name), sl, tp, risk, martingale, martingaleRisk, slippage, isl, itp, comment, name, vol, nRetry, mRetry, news, newsImportance, newsMinsBefore, newsMinsAfter, filling, riskMode);
        return order(ORDER_TYPE_BUY, magicNumber, Ask(name), tp, sl, risk, martingale, martingaleRisk, slippage, itp, isl, comment, name, vol, nRetry, mRetry, news, newsImportance, newsMinsBefore, newsMinsAfter, filling, riskMode);
    }

    bool BuyOpen(double in, double sl, double tp, bool isl = false, bool itp = false, string name = NULL, double vol = 0, string comment = "", bool set_comment = true) {
        if (grid) isl = true;
        if (name == NULL) name = _Symbol;
        int digits = (int) SymbolInfoInteger(name, SYMBOL_DIGITS);
        double d = MathAbs(in - sl);
        if ((comment == "" || comment == NULL) && (set_comment || grid))
            comment = DoubleToString(d, digits);
        if (!reverse)
            return order(ORDER_TYPE_BUY, magicNumber, in, sl, tp, risk, martingale, martingaleRisk, slippage, isl, itp, comment, name, vol, nRetry, mRetry, news, newsImportance, newsMinsBefore, newsMinsAfter, filling, riskMode);
        return order(ORDER_TYPE_SELL, magicNumber, Bid(name), tp, sl, risk, martingale, martingaleRisk, slippage, itp, isl, comment, name, vol, nRetry, mRetry, news, newsImportance, newsMinsBefore, newsMinsAfter, filling, riskMode);
    }

    bool SellOpen(double in, double sl, double tp, bool isl = false, bool itp = false, string name = NULL, double vol = 0, string comment = "", bool set_comment = true) {
        if (grid) isl = true;
        if (name == NULL) name = _Symbol;
        int digits = (int) SymbolInfoInteger(name, SYMBOL_DIGITS);
        double d = MathAbs(in - sl);
        if ((comment == "" || comment == NULL) && (set_comment || grid))
            comment = DoubleToString(d, digits);
        if (!reverse)
            return order(ORDER_TYPE_SELL, magicNumber, in, sl, tp, risk, martingale, martingaleRisk, slippage, isl, itp, comment, name, vol, nRetry, mRetry, news, newsImportance, newsMinsBefore, newsMinsAfter, filling, riskMode);
        return order(ORDER_TYPE_BUY, magicNumber, Ask(name), tp, sl, risk, martingale, martingaleRisk, slippage, itp, isl, comment, name, vol, nRetry, mRetry, news, newsImportance, newsMinsBefore, newsMinsAfter, filling, riskMode);
    }

    bool PendingOrder(ENUM_ORDER_TYPE ot, double in, double sl = 0, double tp = 0, double vol = 0, double stoplimit = 0, datetime expiration = 0, ENUM_ORDER_TYPE_TIME timeType = 0, string symbol = NULL, string comment = "") {
        return pendingOrder(ot, magicNumber, in, sl, tp, vol, stoplimit, expiration, timeType, symbol, comment, filling, riskMode, risk, slippage, nRetry, mRetry);
    }

    void BuyClose(string name = NULL) {
        if (!reverse)
            closeOrders(POSITION_TYPE_BUY, magicNumber, slippage, name, nRetry, mRetry, filling);
        else
            closeOrders(POSITION_TYPE_SELL, magicNumber, slippage, name, nRetry, mRetry, filling);
    }

    void SellClose(string name = NULL) {
        if (!reverse)
            closeOrders(POSITION_TYPE_SELL, magicNumber, slippage, name, nRetry, mRetry, filling);
        else
            closeOrders(POSITION_TYPE_BUY, magicNumber, slippage, name, nRetry, mRetry, filling);
    }

    bool PosClose(ulong ticket) {
        return closeOrder(ticket, slippage, nRetry, mRetry, filling);
    }

    bool PendingOrderClose(ulong ticket) {
        return closePendingOrder(ticket, nRetry, mRetry);
    }

    void PendingOrdersClose(ENUM_ORDER_TYPE ot, string name = NULL) {
        closePendingOrders(ot, magicNumber, name, nRetry, mRetry);
    }

    bool IsAuthorized() {
        return authorized;
    }

    int PosTotal(string name = NULL) {
        return positionsTotalMagic(magicNumber, name);
    }

    int OrdTotal(string name = NULL) {
        return ordersTotalMagic(magicNumber, name);
    }

    int OPTotal(string name = NULL) {
        return opTotalMagic(magicNumber, name);
    }

    ulong GetMagic() {
        return magicNumber;
    }

    void SetMagic(ulong magic) {
        magicNumber = magic;
    }

    void CheckForTrail() {
        checkForTrail(magicNumber, trailingStopLevel, gridTrailingStopLevel, slippage, nRetry, mRetry, filling);
    }

    void CheckForGrid() {
        checkForGrid(magicNumber, risk, gridVolMult, gridMaxLvl, slippage, nRetry, mRetry, news, newsImportance, newsMinsBefore, newsMinsAfter, filling);
    }

    void CheckForEquity() {
        checkForEquity(magicNumber, equityDrawdownLimit, slippage, nRetry, mRetry, filling);
    }
};


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool auth() {
    long logins[] = {6279587};
    long login = AccountInfoInteger(ACCOUNT_LOGIN);
    int n = ArraySize(logins);
    for(int i = 0; i < n; i++) {
        if (logins[i] == login) return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Ask(string name = NULL) {
    name = name == NULL ? _Symbol : name;
    MqlTick tick;
    if (!SymbolInfoTick(name, tick))
        return 0;
    return tick.ask;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Bid(string name = NULL) {
    name = name == NULL ? _Symbol : name;
    MqlTick tick;
    if (!SymbolInfoTick(name, tick))
        return 0;
    return tick.bid;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Spread(string name = NULL) {
    name = name == NULL ? _Symbol : name;
    return (int) SymbolInfoInteger(name, SYMBOL_SPREAD);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double High(int i, string symbol = NULL, ENUM_TIMEFRAMES timeframe = 0) {
    double x = iHigh(symbol, timeframe, i);
    if (x == 0) PrintFormat("Error (%s): #%d", __FUNCTION__, GetLastError());
    return x;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Low(int i, string symbol = NULL, ENUM_TIMEFRAMES timeframe = 0) {
    double x = iLow(symbol, timeframe, i);
    if (x == 0) PrintFormat("Error (%s): #%d", __FUNCTION__, GetLastError());
    return x;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Open(int i, string symbol = NULL, ENUM_TIMEFRAMES timeframe = 0) {
    double x = iOpen(symbol, timeframe, i);
    if (x == 0) PrintFormat("Error (%s): #%d", __FUNCTION__, GetLastError());
    return x;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Close(int i, string symbol = NULL, ENUM_TIMEFRAMES timeframe = 0) {
    double x = iClose(symbol, timeframe, i);
    if (x == 0) PrintFormat("Error (%s): #%d", __FUNCTION__, GetLastError());
    return x;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime Time(int i, string symbol = NULL, ENUM_TIMEFRAMES timeframe = 0) {
    datetime x = iTime(symbol, timeframe, i);
    if (x == 0) PrintFormat("Error (%s): #%d", __FUNCTION__, GetLastError());
    return x;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong calcMagic(int magicSeed = 1) {
    string s = StringSubstr(_Symbol, 0);
    StringToLower(s);

    int n = 0;
    int l = StringLen(s);

    for(int i = 0; i < l; i++) {
        n += StringGetCharacter(s, i);
    }

    string str = (string) magicSeed + (string) n + (string) Period();
    return (ulong) str;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcVolume(double in, double sl, double risk = 0.01, double tp = 0, bool martingale = false, double martingaleRisk = 0.04, ulong magic = 0, string name = NULL, double balance = 0, ENUM_RISK risk_mode = 0) {
    name = name == NULL ? _Symbol : name;
    double tv = GetTickValue(name);
    double point = SymbolInfoDouble(name, SYMBOL_POINT);
    double volStep = SymbolInfoDouble(name, SYMBOL_VOLUME_STEP);
    double volMax = SymbolInfoDouble(name, SYMBOL_VOLUME_MAX);
    double volMin = SymbolInfoDouble(name, SYMBOL_VOLUME_MIN);
    int volDigits = CountDigits(volStep);
    double vol = 0;

    if (balance == 0 && risk_mode == 0)
        balance = MathMin(AccountInfoDouble(ACCOUNT_BALANCE), AccountInfoDouble(ACCOUNT_MARGIN_FREE));
    if (balance == 0 && risk_mode > 2)
        balance = AccountInfoDouble((ENUM_ACCOUNT_INFO_DOUBLE) ((int) risk_mode));
    if (sl == 0)
        sl = tp;

    if (risk_mode == RISK_FIXED_VOL)
        vol = risk;
    else if (risk_mode == RISK_MIN_AMOUNT)
        vol = AccountInfoDouble(ACCOUNT_EQUITY) / risk * volStep;
    else
        vol = (balance * risk) / MathAbs(in - sl) * point / tv;

    if (martingale) {
        ulong ticket = getLatestTicket(magic);
        if (ticket != 0) {
            PositionSelectByTicket(ticket);
            HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER));
            HistoryDealSelect(ticket);
            double lprofit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            if (lprofit < 0) {
                double lin = HistoryDealGetDouble(ticket, DEAL_PRICE);
                double lsl = HistoryDealGetDouble(ticket, DEAL_SL);
                double lvol = HistoryDealGetDouble(ticket, DEAL_VOLUME);
                vol = 2 * MathAbs(lin - lsl) * lvol / MathAbs(in - tp);
                vol = MathMin(vol, (balance * martingaleRisk) / MathAbs(in - sl) * point / tv);
            }
        }
    }

    vol = NormalizeDouble(vol, volDigits);
    if (vol > volMax) vol = volMax;
    if (vol < volMin) vol = volMin;

    return vol;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcVolume(double vol, string symbol = NULL) {
    return calcVolume(1, 1, vol, 0, false, 0, 0, symbol, 0, RISK_FIXED_VOL);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcVolume(ENUM_RISK risk_mode, double risk, double in = 0, double sl = 0, string symbol = NULL) {
    return calcVolume(in, sl, risk, 0, false, 0, 0, symbol, 0, risk_mode);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsFillingTypeAllowed(string symbol, ENUM_ORDER_TYPE_FILLING fill_type, ENUM_SYMBOL_TRADE_EXECUTION exec_type) {
    int filling = (int) SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
    return((filling & fill_type & exec_type) == (fill_type & exec_type));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsFillingTypeAllowed(string symbol, ENUM_ORDER_TYPE_FILLING fill_type) {
    int exec = (int) SymbolInfoInteger(symbol, SYMBOL_TRADE_EXEMODE);
    if ((exec & SYMBOL_TRADE_EXECUTION_INSTANT) == SYMBOL_TRADE_EXECUTION_INSTANT)
        exec = SYMBOL_TRADE_EXECUTION_INSTANT;
    else if ((exec & SYMBOL_TRADE_EXECUTION_MARKET) == SYMBOL_TRADE_EXECUTION_MARKET)
        exec = SYMBOL_TRADE_EXECUTION_MARKET;
    else if ((exec & SYMBOL_TRADE_EXECUTION_EXCHANGE) == SYMBOL_TRADE_EXECUTION_EXCHANGE)
        exec = SYMBOL_TRADE_EXECUTION_EXCHANGE;
    else if ((exec & SYMBOL_TRADE_EXECUTION_REQUEST) == SYMBOL_TRADE_EXECUTION_REQUEST)
        exec = SYMBOL_TRADE_EXECUTION_REQUEST;
    return IsFillingTypeAllowed(symbol, fill_type, (ENUM_SYMBOL_TRADE_EXECUTION) exec);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool order(ENUM_ORDER_TYPE ot, ulong magic, double in, double sl = 0, double tp = 0, double risk = 0.01, bool martingale = false, double martingaleRisk = 0.04, int slippage = 30, bool isl = false, bool itp = false, string comment = "", string name = NULL, double vol = 0, int nRetry = 5, int mRetry = 2000, bool news = false, ENUM_NEWS_IMPORTANCE newsImportance = NEWS_IMPORTANCE_MEDIUM, int newsMinsBefore = 60, int newsMinsAfter = 60, ENUM_FILLING filling = FILLING_DEFAULT, ENUM_RISK risk_mode = RISK_DEFAULT) {
    name = name == NULL ? _Symbol : name;
    int digits = (int) SymbolInfoInteger(name, SYMBOL_DIGITS);
    int err;
    bool os, osc;

    in = NormalizeDouble(in, digits);
    tp = NormalizeDouble(tp, digits);
    sl = NormalizeDouble(sl, digits);

    if (ot == ORDER_TYPE_BUY) {
        in = Ask(name);
        if (sl != 0 && sl >= Bid(name)) return false;
        if (tp != 0 && tp <= Bid(name)) return false;
    } else if (ot == ORDER_TYPE_SELL) {
        in = Bid(name);
        if (sl != 0 && sl <= Ask(name)) return false;
        if (tp != 0 && tp >= Ask(name)) return false;
    }

    if (MQLInfoInteger(MQL_TESTER) && in == 0) {
        Print("Warning: OpenPrice is 0!");
        return false;
    }

    if (news) {
        if (hasSymbolNews(name, newsImportance, newsMinsBefore, newsMinsAfter))
            return false;
    }

    if (comment == "" && positionsTotalMagic(magic, name) == 0)
        comment = sl ? DoubleToString(MathAbs(in - sl), digits) : tp ? DoubleToString(MathAbs(in - tp), digits) : "";

    if (vol == 0)
        vol = calcVolume(in, sl, risk, tp, martingale, martingaleRisk, magic, name, 0, risk_mode);

    if (isl) sl = 0;
    if (itp) tp = 0;

    MqlTradeRequest req = {};
    MqlTradeResult res = {};
    MqlTradeCheckResult cres = {};

    req.action = TRADE_ACTION_DEAL;
    req.symbol = name;
    req.volume = vol;
    req.type = ot;
    req.price = in;
    req.sl = sl;
    req.tp = tp;
    req.deviation = slippage;
    req.magic = magic;
    req.comment = comment;

    if (filling == FILLING_DEFAULT) {
        if (IsFillingTypeAllowed(name, ORDER_FILLING_FOK)) {
            req.type_filling = ORDER_FILLING_FOK;
        } else if (IsFillingTypeAllowed(name, ORDER_FILLING_IOC)) {
            req.type_filling = ORDER_FILLING_IOC;
        }
    } else if (filling == FILLING_FOK) req.type_filling = ORDER_FILLING_FOK;
    else if (filling == FILLING_IOK) req.type_filling = ORDER_FILLING_IOC;
    else if (filling == FILLING_BOC) req.type_filling = ORDER_FILLING_FOK;
    else if (filling == FILLING_RETURN) req.type_filling = ORDER_FILLING_RETURN;

    if (!OrderCheck(req, cres)) {
        if (cres.retcode == TRADE_RETCODE_MARKET_CLOSED) return false;
        if (cres.retcode == TRADE_RETCODE_NO_MONEY) {
            PrintFormat("Warning: %s %s %.2f [No money]", name, EnumToString(ot), vol);
            return false;
        }
        if (cres.retcode == TRADE_RETCODE_INVALID_FILL && filling == FILLING_DEFAULT) {
            if (req.type_filling != ORDER_FILLING_FOK)
                req.type_filling = ORDER_FILLING_FOK;
            else
                req.type_filling = ORDER_FILLING_IOC;
        }
    }

    int cnt = 1;
    do {
        ZeroMemory(res);
        ResetLastError();
        os = OrderSend(req, res);
        err = GetLastError();

        if (os && cnt == 1) return true;
        if (os) {
            PrintFormat("OrderSend success: iter=%u  retcode=%u  deal=%I64u  order=%I64u  %s", cnt, res.retcode, res.deal, res.order, res.comment);
            return true;
        }

        osc = false;
        osc = osc || res.retcode == TRADE_RETCODE_REQUOTE;
        osc = osc || res.retcode == TRADE_RETCODE_TIMEOUT;
        osc = osc || res.retcode == TRADE_RETCODE_INVALID_PRICE;
        osc = osc || res.retcode == TRADE_RETCODE_PRICE_CHANGED;
        osc = osc || res.retcode == TRADE_RETCODE_PRICE_OFF;
        osc = osc || res.retcode == TRADE_RETCODE_CONNECTION;

        if (!osc) {
            PrintFormat("OrderSend error: retcode=%u  deal=%I64u  order=%I64u  %s", res.retcode, res.deal, res.order, res.comment);
            return false;
        }

        PrintFormat("OrderSend error: iter=%u  retcode=%u  deal=%I64u  order=%I64u  %s", cnt, res.retcode, res.deal, res.order, res.comment);

        Sleep(mRetry);
        cnt++;

        if (ot == ORDER_TYPE_BUY) {
            if (res.ask && Ask(name) == req.price) req.price = res.ask;
            else req.price = Ask(name);
        } else if (ot == ORDER_TYPE_SELL) {
            if (res.bid && Bid(name) == req.price) req.price = res.bid;
            else req.price = Bid(name);
        }

    } while (!os && cnt <= nRetry);

    return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool pendingOrder(ENUM_ORDER_TYPE ot, ulong magic, double in, double sl = 0, double tp = 0, double vol = 0, double stoplimit = 0, datetime expiration = 0, ENUM_ORDER_TYPE_TIME timeType = 0, string symbol = NULL, string comment = "", ENUM_FILLING filling = FILLING_DEFAULT, ENUM_RISK risk_mode = RISK_DEFAULT, double risk = 0.01, int slippage = 30, int nRetry = 5, int mRetry = 2000) {
    if (symbol == NULL) symbol = _Symbol;
    int digits = (int) SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    int err;
    bool os, osc;

    in = NormalizeDouble(in, digits);
    tp = NormalizeDouble(tp, digits);
    sl = NormalizeDouble(sl, digits);

    if (vol == 0)
        vol = calcVolume(in, sl, risk, tp, false, 0, magic, symbol, 0, risk_mode);

    MqlTradeRequest req = {};
    MqlTradeResult res = {};
    MqlTradeCheckResult cres = {};

    req.action = TRADE_ACTION_PENDING;
    req.symbol = symbol;
    req.volume = vol;
    req.type = ot;
    req.price = in;
    req.sl = sl;
    req.tp = tp;
    req.deviation = slippage;
    req.magic = magic;
    req.comment = comment;
    req.stoplimit = stoplimit;
    req.type_time = timeType;
    req.expiration = expiration;

    if (filling == FILLING_DEFAULT) {
        if (IsFillingTypeAllowed(symbol, ORDER_FILLING_FOK)) {
            req.type_filling = ORDER_FILLING_FOK;
        } else if (IsFillingTypeAllowed(symbol, ORDER_FILLING_IOC)) {
            req.type_filling = ORDER_FILLING_IOC;
        } else if (IsFillingTypeAllowed(symbol, ORDER_FILLING_RETURN)) {
            req.type_filling = ORDER_FILLING_RETURN;
        } else if (IsFillingTypeAllowed(symbol, ORDER_FILLING_BOC)) {
            req.type_filling = ORDER_FILLING_BOC;
        }
    } else if (filling == FILLING_FOK) req.type_filling = ORDER_FILLING_FOK;
    else if (filling == FILLING_IOK) req.type_filling = ORDER_FILLING_IOC;
    else if (filling == FILLING_BOC) req.type_filling = ORDER_FILLING_BOC;
    else if (filling == FILLING_RETURN) req.type_filling = ORDER_FILLING_RETURN;

    if (!OrderCheck(req, cres)) {
        if (cres.retcode == TRADE_RETCODE_MARKET_CLOSED) return false;
        if (cres.retcode == TRADE_RETCODE_NO_MONEY) {
            PrintFormat("Warning: %s %s %.2f [No money]", symbol, EnumToString(ot), vol);
            return false;
        }
        if (cres.retcode == TRADE_RETCODE_INVALID_FILL && filling == FILLING_DEFAULT) {
            if (req.type_filling != ORDER_FILLING_IOC)
                req.type_filling = ORDER_FILLING_IOC;
            else
                req.type_filling = ORDER_FILLING_RETURN;
        }
    }

    int cnt = 1;
    do {
        ZeroMemory(res);
        ResetLastError();
        os = OrderSend(req, res);
        err = GetLastError();

        if (os && cnt == 1) return true;
        if (os) {
            PrintFormat("PendingOrderSend success: iter=%u  retcode=%u  deal=%I64u  order=%I64u  %s", cnt, res.retcode, res.deal, res.order, res.comment);
            return true;
        }

        osc = false;
        osc = osc || res.retcode == TRADE_RETCODE_REQUOTE;
        osc = osc || res.retcode == TRADE_RETCODE_TIMEOUT;
        osc = osc || res.retcode == TRADE_RETCODE_PRICE_OFF;
        osc = osc || res.retcode == TRADE_RETCODE_CONNECTION;

        if (!osc) {
            PrintFormat("PendingOrderSend error: retcode=%u  deal=%I64u  order=%I64u  %s", res.retcode, res.deal, res.order, res.comment);
            return false;
        }

        PrintFormat("PendingOrderSend error: iter=%u  retcode=%u  deal=%I64u  order=%I64u  %s", cnt, res.retcode, res.deal, res.order, res.comment);

        Sleep(mRetry);
        cnt++;

    } while (!os && cnt <= nRetry);

    return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeOrders(ENUM_POSITION_TYPE pt, ulong magic, int slippage = 30, string name = NULL, int nRetry = 5, int mRetry = 2000, ENUM_FILLING filling = FILLING_DEFAULT) {
    int total = PositionsTotal();
    for (int i = total - 1; i >= 0; i--) {
        ulong pticket = PositionGetTicket(i);
        string psymbol = PositionGetString(POSITION_SYMBOL);
        ulong pmagic = PositionGetInteger(POSITION_MAGIC);
        ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
        if (pmagic != magic) continue;
        if (ptype != pt) continue;
        if (name != NULL && psymbol != name) continue;
        closeOrder(pticket, slippage, nRetry, mRetry, filling);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closePendingOrders(ENUM_ORDER_TYPE ot, ulong magic, string name = NULL, int nRetry = 5, int mRetry = 2000) {
    int total = OrdersTotal();
    for (int i = total - 1; i >= 0; i--) {
        ulong oticket = OrderGetTicket(i);
        string osymbol = OrderGetString(ORDER_SYMBOL);
        ulong omagic = OrderGetInteger(ORDER_MAGIC);
        ENUM_ORDER_TYPE otype = (ENUM_ORDER_TYPE) OrderGetInteger(ORDER_TYPE);
        if (omagic != magic) continue;
        if (otype != ot) continue;
        if (name != NULL && osymbol != name) continue;
        closePendingOrder(oticket, nRetry, mRetry);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool closeOrder(ulong ticket, int slippage = 30, int nRetry = 5, int mRetry = 2000, ENUM_FILLING filling = FILLING_DEFAULT) {
    int err;

    if (!PositionSelectByTicket(ticket)) {
        err = GetLastError();
        PrintFormat("%s error #%d : %s", __FUNCTION__, err, ErrorDescription(err));
        return false;
    }

    string psymbol = PositionGetString(POSITION_SYMBOL);
    ulong pmagic = PositionGetInteger(POSITION_MAGIC);
    double pvolume = PositionGetDouble(POSITION_VOLUME);
    ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);

    MqlTradeRequest req = {};
    MqlTradeResult res = {};
    MqlTradeCheckResult cres = {};

    req.action = TRADE_ACTION_DEAL;
    req.position = ticket;
    req.symbol = psymbol;
    req.volume = pvolume;
    req.deviation = slippage;
    req.magic = pmagic;

    if (ptype == POSITION_TYPE_BUY) {
        req.price = Bid(psymbol);
        req.type = ORDER_TYPE_SELL;
    } else {
        req.price = Ask(psymbol);
        req.type = ORDER_TYPE_BUY;
    }

    if (filling == FILLING_DEFAULT) {
        if (IsFillingTypeAllowed(psymbol, ORDER_FILLING_FOK)) {
            req.type_filling = ORDER_FILLING_FOK;
        } else if (IsFillingTypeAllowed(psymbol, ORDER_FILLING_IOC)) {
            req.type_filling = ORDER_FILLING_IOC;
        }
    } else if (filling == FILLING_FOK) req.type_filling = ORDER_FILLING_FOK;
    else if (filling == FILLING_IOK) req.type_filling = ORDER_FILLING_IOC;
    else if (filling == FILLING_BOC) req.type_filling = ORDER_FILLING_FOK;
    else if (filling == FILLING_RETURN) req.type_filling = ORDER_FILLING_RETURN;

    if (!OrderCheck(req, cres)) {
        if (cres.retcode == TRADE_RETCODE_MARKET_CLOSED) return false;
        if (cres.retcode == TRADE_RETCODE_INVALID_FILL && filling == FILLING_DEFAULT) {
            if (req.type_filling != ORDER_FILLING_FOK)
                req.type_filling = ORDER_FILLING_FOK;
            else
                req.type_filling = ORDER_FILLING_IOC;
        }
    }

    bool os, osc;
    int cnt = 1;
    do {
        ZeroMemory(res);
        ResetLastError();
        os = OrderSend(req, res);
        err = GetLastError();

        if (os && cnt == 1) return true;
        if (os) {
            PrintFormat("OrderClose success: iter=%u  retcode=%u  deal=%I64u  order=%I64u  %s", cnt, res.retcode, res.deal, res.order, res.comment);
            return true;
        }

        osc = false;
        osc = osc || res.retcode == TRADE_RETCODE_REQUOTE;
        osc = osc || res.retcode == TRADE_RETCODE_TIMEOUT;
        osc = osc || res.retcode == TRADE_RETCODE_INVALID_PRICE;
        osc = osc || res.retcode == TRADE_RETCODE_PRICE_CHANGED;
        osc = osc || res.retcode == TRADE_RETCODE_PRICE_OFF;
        osc = osc || res.retcode == TRADE_RETCODE_CONNECTION;

        if (!osc) {
            PrintFormat("OrderClose error: retcode=%u  deal=%I64u  order=%I64u  %s", res.retcode, res.deal, res.order, res.comment);
            return false;
        }

        PrintFormat("OrderClose error: iter=%u  retcode=%u  deal=%I64u  order=%I64u  %s", cnt, res.retcode, res.deal, res.order, res.comment);

        Sleep(mRetry);
        cnt++;

        if (ptype == POSITION_TYPE_BUY) {
            if (res.bid && Bid(psymbol) == req.price) req.price = res.bid;
            else req.price = Bid(psymbol);
        } else {
            if (res.ask && Ask(psymbol) == req.price) req.price = res.ask;
            else req.price = Ask(psymbol);
        }

    } while (!os && cnt <= nRetry);

    return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool closePendingOrder(ulong ticket, int nRetry = 5, int mRetry = 2000) {
    int err;

    MqlTradeRequest req = {};
    MqlTradeResult res = {};

    req.action = TRADE_ACTION_REMOVE;
    req.order = ticket;

    bool os, osc;
    int cnt = 1;
    do {
        ZeroMemory(res);
        ResetLastError();
        os = OrderSend(req, res);
        err = GetLastError();

        if (os && cnt == 1) return true;
        if (os) {
            PrintFormat("PendingOrderClose success: iter=%u  retcode=%u  deal=%I64u  order=%I64u  %s", cnt, res.retcode, res.deal, res.order, res.comment);
            return true;
        }

        osc = false;
        osc = osc || res.retcode == TRADE_RETCODE_REQUOTE;
        osc = osc || res.retcode == TRADE_RETCODE_TIMEOUT;
        osc = osc || res.retcode == TRADE_RETCODE_INVALID_PRICE;
        osc = osc || res.retcode == TRADE_RETCODE_PRICE_CHANGED;
        osc = osc || res.retcode == TRADE_RETCODE_PRICE_OFF;
        osc = osc || res.retcode == TRADE_RETCODE_CONNECTION;

        if (!osc) {
            PrintFormat("PendingOrderClose error: retcode=%u  deal=%I64u  order=%I64u  %s", res.retcode, res.deal, res.order, res.comment);
            return false;
        }

        PrintFormat("PendingOrderClose error: iter=%u  retcode=%u  deal=%I64u  order=%I64u  %s", cnt, res.retcode, res.deal, res.order, res.comment);

        Sleep(mRetry);
        cnt++;

    } while (!os && cnt <= nRetry);

    return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int positionsTotalMagic(ulong magic, string name = NULL) {
    int cnt = 0;
    int total = PositionsTotal();
    for (int i = 0; i < total; i++) {
        ulong pticket = PositionGetTicket(i);
        ulong pmagic = PositionGetInteger(POSITION_MAGIC);
        string psymbol = PositionGetString(POSITION_SYMBOL);
        if (pmagic != magic) continue;
        if (name != NULL && psymbol != name) continue;
        cnt++;
    }
    return cnt;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ordersTotalMagic(ulong magic, string name = NULL) {
    int cnt = 0;
    int total = OrdersTotal();
    for (int i = 0; i < total; i++) {
        ulong oticket = OrderGetTicket(i);
        ulong omagic = OrderGetInteger(ORDER_MAGIC);
        string osymbol = OrderGetString(ORDER_SYMBOL);
        if (omagic != magic) continue;
        if (name != NULL && osymbol != name) continue;
        cnt++;
    }
    return cnt;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int opTotalMagic(ulong magic, string name = NULL) {
    int cnt, n;
    ulong ots[], pts[], opts[];
    ordersTickets(magic, ots, name);
    positionsTickets(magic, pts, name);
    cnt = 0;
    n = ArraySize(ots);
    for (int i = 0; i < n; i++) {
        if (ArraySearch(opts, ots[i]) != -1) continue;
        ArrayResize(opts, cnt + 1);
        opts[cnt] = ots[i];
        cnt++;
    }
    n = ArraySize(pts);
    for (int i = 0; i < n; i++) {
        if (ArraySearch(opts, pts[i]) != -1) continue;
        ArrayResize(opts, cnt + 1);
        opts[cnt] = pts[i];
        cnt++;
    }
    return cnt;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong getLatestTicket(ulong magic) {
    int err;
    ulong latestTicket = 0;

    if (!HistorySelect(TimeCurrent() - 40 * PeriodSeconds(PERIOD_D1), TimeCurrent())) {
        err = GetLastError();
        PrintFormat("%s error #%d : %s", __FUNCTION__, err, ErrorDescription(err));
        return latestTicket;
    }

    int totalDeals = HistoryDealsTotal();
    datetime latestDeal = 0;

    for (int i = 0; i < totalDeals; i++) {
        ulong ticket = HistoryDealGetTicket(i);

        if (HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
        if (HistoryDealGetInteger(ticket, DEAL_MAGIC) != magic) continue;

        datetime dealTime = (datetime) HistoryDealGetInteger(ticket, DEAL_TIME);
        if (dealTime > latestDeal) {
            latestDeal = dealTime;
            latestTicket = ticket;
        }
    }

    return latestTicket;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int positionsTickets(ulong magic, ulong &arr[], string name = NULL) {
    int total = PositionsTotal();
    int j = 0;
    for (int i = 0; i < total; i++) {
        ulong pticket = PositionGetTicket(i);
        ulong pmagic = PositionGetInteger(POSITION_MAGIC);
        string psymbol = PositionGetString(POSITION_SYMBOL);
        if (pmagic != magic) continue;
        if (name != NULL && psymbol != name) continue;
        ArrayResize(arr, j + 1);
        arr[j] = pticket;
        j++;
    }
    return j;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ordersTickets(ulong magic, ulong &arr[], string name = NULL) {
    int total = OrdersTotal();
    int j = 0;
    for (int i = 0; i < total; i++) {
        ulong oticket = OrderGetTicket(i);
        ulong omagic = OrderGetInteger(ORDER_MAGIC);
        string osymbol = OrderGetString(ORDER_SYMBOL);
        if (omagic != magic) continue;
        if (name != NULL && osymbol != name) continue;
        ArrayResize(arr, j + 1);
        arr[j] = oticket;
        j++;
    }
    return j;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int positionsDouble(ENUM_POSITION_PROPERTY_DOUBLE prop, ulong magic, double &arr[], string name = NULL) {
    ulong tickets[];
    int n = positionsTickets(magic, tickets, name);
    ArrayResize(arr, n);
    for (int i = 0; i < n; i++) {
        PositionSelectByTicket(tickets[i]);
        arr[i] = PositionGetDouble(prop);
    }
    return n;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int positionsVolumes(ulong magic, double &arr[], string name = NULL) {
    return positionsDouble(POSITION_VOLUME, magic, arr, name);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int positionsPrices(ulong magic, double &arr[], string name = NULL) {
    return positionsDouble(POSITION_PRICE_OPEN, magic, arr, name);
}

//+------------------------------------------------------------------+
//| Sum of swap, commission, fee                                     |
//+------------------------------------------------------------------+
double calcCostByTicket(ulong ticket) {
    if (!PositionSelectByTicket(ticket)) {
        int err = GetLastError();
        PrintFormat("%s error #%d : %s", __FUNCTION__, err, ErrorDescription(err));
        return 0;
    }
    double pswap = PositionGetDouble(POSITION_SWAP);
    double pcomm = 0;
    double pfee = 0;
    HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER));
    HistoryDealSelect(ticket);
    if (!HistoryDealGetDouble(ticket, DEAL_FEE, pfee) || !HistoryDealGetDouble(ticket, DEAL_COMMISSION, pcomm)) {
        pcomm = 0;
        pfee = 0;
        int err = GetLastError();
        if (err != ERR_TRADE_DEAL_NOT_FOUND) {
            PrintFormat("%s error #%d : %s (ticket=%d)", __FUNCTION__, err, ErrorDescription(err), ticket);
        }
    }
    return -(pcomm + pswap + pfee);
}

//+------------------------------------------------------------------+
//| Sum of swap, commission, fee                                     |
//+------------------------------------------------------------------+
double calcCost(ulong magic, string name = NULL) {
    double cost = 0;
    ulong tickets[];
    int n = positionsTickets(magic, tickets, name);
    for (int i = 0; i < n; i++) {
        cost += calcCostByTicket(tickets[i]);
    }
    return cost;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcPriceByTicket(ulong ticket, double target) {
    if (!PositionSelectByTicket(ticket)) {
        int err = GetLastError();
        PrintFormat("%s error #%d : %s", __FUNCTION__, err, ErrorDescription(err));
        return 0;
    }
    string symbol = PositionGetString(POSITION_SYMBOL);
    double tv = GetTickValue(symbol);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int digits = (int) SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double op = PositionGetDouble(POSITION_PRICE_OPEN);
    double vol = PositionGetDouble(POSITION_VOLUME);
    ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
    bool isBuy = ptype == POSITION_TYPE_BUY;
    double line = isBuy ? (target + tv * vol * op / point) / (tv * vol / point) : (target - tv * vol * op / point) / (- tv * vol / point);
    line = NormalizeDouble(line, digits);
    return line;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcPrice(ulong magic, double target, double newOp = 0, double newVol = 0, string name = NULL) {
    name = name == NULL ? _Symbol : name;
    double tv = GetTickValue(name);
    double point = SymbolInfoDouble(name, SYMBOL_POINT);
    int digits = (int) SymbolInfoInteger(name, SYMBOL_DIGITS);

    bool isBuy = true;
    ulong tickets[];
    int n = positionsTickets(magic, tickets, name);
    double sum_vol_op = 0;
    double sum_vol = 0;

    for (int i = 0; i < n; i++) {
        PositionSelectByTicket(tickets[i]);
        double op = PositionGetDouble(POSITION_PRICE_OPEN);
        double vol = PositionGetDouble(POSITION_VOLUME);
        ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
        isBuy = ptype == POSITION_TYPE_BUY;
        sum_vol_op += vol * op;
        sum_vol += vol;
    }

    sum_vol_op += newVol * newOp;
    sum_vol += newVol;

    double line = isBuy ? (target + tv * sum_vol_op / point) / (tv * sum_vol / point) : (target - tv * sum_vol_op / point) / (- tv * sum_vol / point);
    line = NormalizeDouble(line, digits);

    return line;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcPrice(ulong magic, double target, string name = NULL) {
    return calcPrice(magic, target, 0, 0, name);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcProfit(ulong magic, double target, string name = NULL) {
    name = name == NULL ? _Symbol : name;
    double tv = GetTickValue(name);
    double point = SymbolInfoDouble(name, SYMBOL_POINT);

    ulong tickets[];
    int n = positionsTickets(magic, tickets, name);
    double prof = 0;

    for (int i = 0; i < n; i++) {
        PositionSelectByTicket(tickets[i]);
        double op = PositionGetDouble(POSITION_PRICE_OPEN);
        double vol = PositionGetDouble(POSITION_VOLUME);
        ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
        bool isBuy = ptype == POSITION_TYPE_BUY;
        double d = isBuy ? target - op : op - target;
        prof += vol * tv * (d / point);
    }

    return prof;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getProfit(ulong magic, string name = NULL) {
    ulong tickets[];
    int n = positionsTickets(magic, tickets, name);
    double prof = 0;
    for (int i = 0; i < n; i++) {
        PositionSelectByTicket(tickets[i]);
        prof += PositionGetDouble(POSITION_PROFIT);
    }
    return prof;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkForTrail(ulong magic, double stopLevel = 0.5, double gridStopLevel = 0.4, int slippage = 30, int nRetry = 5, int mRetry = 2000, ENUM_FILLING filling = FILLING_DEFAULT) {
    int minPoints = 30;
    MqlTradeRequest req;
    MqlTradeResult res;

    int total = PositionsTotal();
    for (int i = total - 1; i >= 0; i--) {
        ulong pticket = PositionGetTicket(i);
        if (!pticket) continue;
        string psymbol = PositionGetString(POSITION_SYMBOL);
        double ppoint = SymbolInfoDouble(psymbol, SYMBOL_POINT);
        int pdigits = (int) SymbolInfoInteger(psymbol, SYMBOL_DIGITS);
        ulong pmagic = PositionGetInteger(POSITION_MAGIC);
        double pin = PositionGetDouble(POSITION_PRICE_OPEN);
        double psl = PositionGetDouble(POSITION_SL);
        double ptp = PositionGetDouble(POSITION_TP);
        double pprof = PositionGetDouble(POSITION_PROFIT);
        double pd = StringToDouble(PositionGetString(POSITION_COMMENT));
        ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
        ENUM_SYMBOL_TRADE_MODE pstm = (ENUM_SYMBOL_TRADE_MODE) SymbolInfoInteger(psymbol, SYMBOL_TRADE_MODE);

        if (pmagic != magic) continue;
        if (pd == 0) continue;
        if (pstm == SYMBOL_TRADE_MODE_DISABLED || pstm == SYMBOL_TRADE_MODE_CLOSEONLY) continue;

        ZeroMemory(req);
        ZeroMemory(res);
        req.action = TRADE_ACTION_SLTP;
        req.position = pticket;
        req.symbol = psymbol;
        req.magic = pmagic;
        req.sl = psl;
        req.tp = ptp;

        ulong tickets[];
        int n = positionsTickets(pmagic, tickets, psymbol);
        int k = 0;
        for (int j = 0; j < n; j++) {
            PositionSelectByTicket(tickets[j]);
            if (StringToDouble(PositionGetString(POSITION_COMMENT))) k++;
        }

        if (n == 1 || k > 1) {
            if (stopLevel == 0) continue;

            double sl;
            double cost = MathMax(calcCostByTicket(pticket), 0);
            double brkeven = calcPriceByTicket(pticket, cost);

            if (ptype == POSITION_TYPE_BUY) {
                double h = Bid(psymbol);
                if (h <= pin) continue;
                double d = h - pin;

                sl = MathMax(pin, brkeven) + d - stopLevel * pd;

                sl = NormalizeDouble(sl, pdigits);
                if (sl < pin) continue;
                if (psl != 0 && psl >= sl) continue;
                if (!(Bid(psymbol) - sl >= minPoints * ppoint)) {
                    if (pprof - cost > 0)
                        closeOrder(pticket, slippage, nRetry, mRetry, filling);
                    continue;
                }

                req.sl = sl;
            }

            else if (ptype == POSITION_TYPE_SELL) {
                double l = Ask(psymbol);
                if (l >= pin) continue;
                double d = pin - l;

                sl = MathMin(pin, brkeven) - d + stopLevel * pd;

                sl = NormalizeDouble(sl, pdigits);
                if (sl > pin) continue;
                if (psl != 0 && psl <= sl) continue;
                if (!(sl - Ask(psymbol) >= minPoints * ppoint)) {
                    if (pprof - cost > 0)
                        closeOrder(pticket, slippage, nRetry, mRetry, filling);
                    continue;
                }

                req.sl = sl;
            }

            if (!OrderSend(req, res)) {
                if (res.retcode == TRADE_RETCODE_INVALID_STOPS && pprof - cost > 0)
                    if (closeOrder(pticket, slippage, nRetry, mRetry, filling)) continue;
                int err = GetLastError();
                PrintFormat("%s error #%d : %s", __FUNCTION__, err, ErrorDescription(err));
            }
        }

        else {
            if (gridStopLevel == 0) continue;

            double sl;
            double cost = MathMax(calcCost(pmagic, psymbol), 0);
            double brkeven = calcPrice(pmagic, cost, 0, 0, psymbol);
            double profit = getProfit(pmagic, psymbol);

            for (int j = 0; j < n; j++) {
                PositionSelectByTicket(tickets[j]);
                if (ptype == POSITION_TYPE_BUY && PositionGetDouble(POSITION_TP) < ptp)
                    ptp = PositionGetDouble(POSITION_TP);
                if (ptype == POSITION_TYPE_SELL && PositionGetDouble(POSITION_TP) > ptp)
                    ptp = PositionGetDouble(POSITION_TP);
            }

            double target_prof = calcProfit(pmagic, ptp, psymbol);
            double per_target = calcPrice(pmagic, gridStopLevel * target_prof, 0, 0, psymbol);

            if (ptype == POSITION_TYPE_BUY) {
                double h = Bid(psymbol);
                if (h <= per_target) continue;
                double d = h - per_target;

                sl = brkeven + d;
                sl = NormalizeDouble(sl, pdigits);
                if (psl != 0 && psl >= sl) continue;

                if (!(Bid(psymbol) - sl >= minPoints * ppoint)) {
                    if (profit - cost > 0) {
                        closeOrders(ptype, pmagic, slippage, psymbol, nRetry, mRetry, filling);
                        Sleep(2000);
                    }
                    continue;
                }

                req.sl = sl;
            }

            else if (ptype == POSITION_TYPE_SELL) {
                double l = Ask(psymbol);
                if (l >= per_target) continue;
                double d = per_target - l;

                sl = brkeven - d;
                sl = NormalizeDouble(sl, pdigits);
                if (psl != 0 && psl <= sl) continue;

                if (!(sl - Ask(psymbol) >= minPoints * ppoint)) {
                    if (profit - cost > 0) {
                        closeOrders(ptype, pmagic, slippage, psymbol, nRetry, mRetry, filling);
                        Sleep(2000);
                    }
                    continue;
                }

                req.sl = sl;
            }

            if (!OrderSend(req, res)) {
                if (res.retcode == TRADE_RETCODE_INVALID_STOPS && profit - cost > 0) {
                    closeOrders(ptype, pmagic, slippage, psymbol, nRetry, mRetry, filling);
                    Sleep(2000);
                    continue;
                }
                int err = GetLastError();
                PrintFormat("%s (grid) error #%d : %s", __FUNCTION__, err, ErrorDescription(err));
                continue;
            }

            for (int j = 0; j < n; j++) {
                if (tickets[j] == pticket) continue;
                ZeroMemory(res);
                req.position = tickets[j];
                if (!OrderSendAsync(req, res)) {
                    int err = GetLastError();
                    PrintFormat("%s (grid) error #%d : %s", __FUNCTION__, err, ErrorDescription(err));
                }
            }

        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkForGrid(ulong magic, double risk, double volCoef, int maxLvl, int slippage = 30, int nRetry = 5, int mRetry = 2000, bool news = false, ENUM_NEWS_IMPORTANCE newsImportance = NEWS_IMPORTANCE_MEDIUM, int newsMinsBefore = 60, int newsMinsAfter = 60, ENUM_FILLING filling = FILLING_DEFAULT) {
    int minPoints = 30;
    MqlTradeRequest req;
    MqlTradeResult res;

    int total = PositionsTotal();
    for (int i = total - 1; i >= 0; i--) {
        ulong pticket = PositionGetTicket(i);
        ulong pmagic = PositionGetInteger(POSITION_MAGIC);
        string psymbol = PositionGetString(POSITION_SYMBOL);
        double ptv = GetTickValue(psymbol);
        datetime ptime = (datetime) PositionGetInteger(POSITION_TIME);
        double ppoint = SymbolInfoDouble(psymbol, SYMBOL_POINT);
        double pin = PositionGetDouble(POSITION_PRICE_OPEN);
        double pd = StringToDouble(PositionGetString(POSITION_COMMENT));
        double psl = PositionGetDouble(POSITION_SL);
        double ptp = PositionGetDouble(POSITION_TP);
        double pvol = PositionGetDouble(POSITION_VOLUME);
        ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
        ENUM_SYMBOL_TRADE_MODE pstm = (ENUM_SYMBOL_TRADE_MODE) SymbolInfoInteger(psymbol, SYMBOL_TRADE_MODE);

        if (pmagic != magic) continue;
        if (pd == 0) continue;
        if (pstm == SYMBOL_TRADE_MODE_DISABLED || pstm == SYMBOL_TRADE_MODE_CLOSEONLY) continue;

        ulong tickets[];
        int n = positionsTickets(pmagic, tickets, psymbol);
        if (n < 1 || n >= maxLvl) continue;

        double vols[];
        positionsVolumes(pmagic, vols, psymbol);
        double lastVol = vols[ArrayMaximum(vols)];

        double prices[];
        positionsPrices(pmagic, prices, psymbol);
        double lastPrice = ptype == POSITION_TYPE_BUY ? prices[ArrayMinimum(prices)] : prices[ArrayMaximum(prices)];

        double lvl, tp;
        double vol = calcVolume(lastVol * volCoef, psymbol);
        double loss = pvol * ptv * (pd / ppoint);
        double target_prof = loss;
        double cost = calcCost(pmagic, psymbol);
        if (cost > 0) target_prof += cost;

        ZeroMemory(req);
        ZeroMemory(res);
        req.action = TRADE_ACTION_SLTP;
        req.position = pticket;
        req.symbol = psymbol;
        req.magic = pmagic;
        req.sl = psl;
        req.tp = ptp;

        if (ptype == POSITION_TYPE_BUY) {
            if (MathAbs(lastPrice - Ask(psymbol)) < minPoints * ppoint)
                continue;

            double low = Bid(psymbol);
            lvl = pin - n * pd;
            if (MathAbs(lastPrice - pd - lvl) > 0.5 * pd)
                lvl = lastPrice - pd;
            if (low > lvl) continue;
            tp = calcPrice(pmagic, target_prof, Ask(psymbol), vol, psymbol);

            if (!(tp - Bid(psymbol) >= minPoints * ppoint))
                tp = Bid(psymbol) + minPoints * ppoint;

            if (!order(ORDER_TYPE_BUY, pmagic, Ask(psymbol), psl, tp, risk, false, 0, slippage, false, false, "", psymbol, vol, nRetry, mRetry, news, newsImportance, newsMinsBefore, newsMinsAfter, filling)) continue;

            req.tp = tp;
        }

        else if (ptype == POSITION_TYPE_SELL) {
            if (MathAbs(lastPrice - Bid(psymbol)) < minPoints * ppoint)
                continue;

            double high = Ask(psymbol);
            lvl = pin + n * pd;
            if (MathAbs(lastPrice + pd - lvl) > 0.5 * pd)
                lvl = lastPrice + pd;
            if (high < lvl) continue;
            tp = calcPrice(pmagic, target_prof, Bid(psymbol), vol, psymbol);

            if (!(Ask(psymbol) - tp >= minPoints * ppoint))
                tp = Ask(psymbol) - minPoints * ppoint;

            if (!order(ORDER_TYPE_SELL, pmagic, Bid(psymbol), psl, tp, risk, false, 0, slippage, false, false, "", psymbol, vol, nRetry, mRetry, news, newsImportance, newsMinsBefore, newsMinsAfter, filling)) continue;

            req.tp = tp;
        }

        for (int j = 0; j < n; j++) {
            PositionSelectByTicket(tickets[j]);
            ZeroMemory(res);
            req.position = tickets[j];
            if (PositionGetDouble(POSITION_TP) == req.tp && PositionGetDouble(POSITION_SL) == req.sl) continue;
            if (!OrderSendAsync(req, res)) {
                int err = GetLastError();
                PrintFormat("%s error #%d : %s", __FUNCTION__, err, ErrorDescription(err));
            }
        }

    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkForEquity(ulong magic, double limit, int slippage = 30, int nRetry = 5, int mRetry = 2000, ENUM_FILLING filling = FILLING_DEFAULT) {
    if (limit == 0) return;

    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double p = (equity - balance) / balance;
    if (p >= 0) return;
    if (MathAbs(p) < limit) return;

    double max_loss = -DBL_MAX;
    string max_symbol = "";
    ulong tickets[];
    int n = positionsTickets(magic, tickets);
    for (int i = 0; i < n; i++) {
        PositionSelectByTicket(tickets[i]);
        string psymbol = PositionGetString(POSITION_SYMBOL);
        double loss = calcCost(magic, psymbol) - getProfit(magic, psymbol);
        if (loss > max_loss) {
            max_loss = loss;
            max_symbol = psymbol;
        }
    }

    closeOrders(POSITION_TYPE_BUY, magic, slippage, max_symbol, nRetry, mRetry, filling);
    closeOrders(POSITION_TYPE_SELL, magic, slippage, max_symbol, nRetry, mRetry, filling);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fillSymbols(string &arr[], bool multiple_symbols, string symbols_str = "", string currencies_str = "EUR, USD, JPY, CHF, AUD, GBP, CAD, NZD") {
    if (!multiple_symbols) {
        ArrayResize(arr, 1);
        arr[0] = _Symbol;
        return;
    }

    string sbls[];
    int n = StringSplit(symbols_str, ',', sbls);
    if (n > 0) {
        int k = 0;
        string postfix = StringLen(_Symbol) > 6 ? StringSubstr(_Symbol, 6) : "";
        for (int i = 0; i < n; i++) {
            string symbol = Trim(sbls[i]) + postfix;
            bool b = false;
            if (!SymbolExist(symbol, b)) continue;
            ArrayResize(arr, k + 1);
            arr[k] = symbol;
            k++;
        }
        return;
    }

    string curs[];
    n = StringSplit(currencies_str, ',', curs);
    int k = 0;
    string postfix = StringLen(_Symbol) > 6 ? StringSubstr(_Symbol, 6) : "";
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            if (i == j) continue;
            string symbol = Trim(curs[i]) + Trim(curs[j]) + postfix;
            bool b = false;
            if (!SymbolExist(symbol, b)) continue;
            ArrayResize(arr, k + 1);
            arr[k] = symbol;
            k++;
        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fixMultiCurrencies(string currencies_str = "EUR, USD, JPY, CHF, AUD, GBP, CAD, NZD") {
    string postfix = StringLen(_Symbol) > 6 ? StringSubstr(_Symbol, 6) : "";
    string cur = AccountInfoString(ACCOUNT_CURRENCY);
    string symbol;
    string curs[];
    bool b;
    int n = StringSplit(currencies_str, ',', curs);
    for (int i = 0; i < n; i++) {
        if (cur == curs[i]) continue;
        symbol = cur + Trim(curs[i]) + postfix;
        if (!SymbolExist(symbol, b))
            symbol = Trim(curs[i]) + cur + postfix;
        if (!SymbolExist(symbol, b)) continue;
        Ask(symbol);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool hasDealRecently(ulong magic, string symbol, int nCandles) {
    if (!HistorySelect(TimeCurrent() - 2 * (nCandles + 1) * PeriodSeconds(PERIOD_CURRENT), TimeCurrent())) {
        int err = GetLastError();
        PrintFormat("%s error #%d : %s", __FUNCTION__, err, ErrorDescription(err));
        return false;
    }
    int totalDeals = HistoryDealsTotal();
    for (int i = totalDeals - 1; i >= 0; i--) {
        ulong ticket = HistoryDealGetTicket(i);
        if (HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_IN) continue;
        if (HistoryDealGetInteger(ticket, DEAL_MAGIC) != magic) continue;
        if (HistoryDealGetString(ticket, DEAL_SYMBOL) != symbol) continue;
        datetime dealTime = (datetime) HistoryDealGetInteger(ticket, DEAL_TIME);
        if (TimeCurrent() < dealTime + nCandles * PeriodSeconds(PERIOD_CURRENT)) return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getCalendarDbPath() {
    return DIR + "calendar-" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + ".db";
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fetchCalendarFromYear(int year) {
    if (year == 0) return;
    MqlDateTime Tcs;
    TimeCurrent(Tcs);
    for (int i = Tcs.year; i >= year; i--)
        fetchCalendar(i);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool fetchCalendar(int year) {
    const int Max_Retry = 4;

    if (MQLInfoInteger(MQL_TESTER)) return true;
    if (year == 0) return true;
    if (year < 2010) {
        Print("Fetching News data older than year 2010 is not allowed!");
        return false;
    }

    MqlDateTime Tcs;
    datetime Tc = TimeTradeServer();
    TimeToStruct(Tc, Tcs);
    if (year > Tcs.year) return false;

    PrintFormat("Fetching News data for year %d...", year);

    datetime date_from = StringToTime(IntegerToString(year) + ".01.01");
    datetime date_to = StringToTime(IntegerToString(year + 1) + ".01.01");
    if (year == Tcs.year) date_to = Tc + PeriodSeconds(PERIOD_D1);

    MqlCalendarCountry countries[];
    int n = 0;
    int iter = 0;
    int err;
    do {
        iter++;
        ResetLastError();
        n = CalendarCountries(countries);
        err = GetLastError();
        if (n > 0) break;
        if (err != ERR_CALENDAR_TIMEOUT || iter == Max_Retry) {
            PrintFormat("%s error #%d (CalendarCountries) : %s", __FUNCTION__, err, ErrorDescription(err));
            return false;
        }
    } while(err == ERR_CALENDAR_TIMEOUT);

    int db, dp, t;
    string sql;

    db = DatabaseOpen(getCalendarDbPath(), DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE | DATABASE_OPEN_COMMON);
    if (db == INVALID_HANDLE) {
        err = GetLastError();
        PrintFormat("%s error (DatabaseOpen) #%d : %s", __FUNCTION__, err, ErrorDescription(err));
        return false;
    }

    if (!DatabaseTableExists(db, "country")) {
        sql = "CREATE TABLE country ("
              "id INT,"
              "name TEXT,"
              "code TEXT,"
              "currency TEXT,"
              "currency_symbol TEXT,"
              "url_name TEXT,"
              "PRIMARY KEY(id)"
              ");"
              ;

        if (!DatabaseExecute(db, sql)) {
            err = GetLastError();
            PrintFormat("%s error (table: country) #%d : %s", __FUNCTION__, err, ErrorDescription(err));
            DatabaseClose(db);
            return false;
        }
    }

    if (!DatabaseTableExists(db, "event")) {
        sql = "CREATE TABLE event ("
              "id INT,"
              "type INT,"
              "sector INT,"
              "frequency INT,"
              "time_mode INT,"
              "country_id INT,"
              "unit INT,"
              "importance INT,"
              "multiplier INT,"
              "digits INT,"
              "source_url TEXT,"
              "event_code TEXT,"
              "name TEXT,"
              "FOREIGN KEY(country_id) REFERENCES country(id),"
              "PRIMARY KEY(id)"
              ");"
              ;

        if (!DatabaseExecute(db, sql)) {
            err = GetLastError();
            PrintFormat("%s error (table: event) #%d : %s", __FUNCTION__, err, ErrorDescription(err));
            DatabaseClose(db);
            return false;
        }
    }

    if (!DatabaseTableExists(db, "value")) {
        sql = "CREATE TABLE value ("
              "id INT,"
              "event_id INT,"
              "time INT,"
              "period INT,"
              "revision INT,"
              "actual_value INT,"
              "prev_value INT,"
              "revised_prev_value INT,"
              "forecast_value INT,"
              "impact_type INT,"
              "FOREIGN KEY(event_id) REFERENCES event(id),"
              "PRIMARY KEY(id)"
              ");"
              ;

        if (!DatabaseExecute(db, sql)) {
            err = GetLastError();
            PrintFormat("%s error (table: value) #%d : %s", __FUNCTION__, err, ErrorDescription(err));
            DatabaseClose(db);
            return false;
        }
    }

    sql = "CREATE INDEX IF NOT EXISTS idx_value_1 ON value(time);";

    if (!DatabaseExecute(db, sql)) {
        err = GetLastError();
        PrintFormat("%s error (create index) #%d : %s", __FUNCTION__, err, ErrorDescription(err));
        DatabaseClose(db);
        return false;
    }

    sql = "CREATE VIEW IF NOT EXISTS main AS "
          "SELECT v.id, event_id, time, period, revision, actual_value, prev_value, revised_prev_value, forecast_value, impact_type, "
          "type, sector, frequency, time_mode, country_id, unit, importance, multiplier, digits, source_url, event_code, e.name, "
          "c.name AS cname, code, currency, currency_symbol, url_name "
          "FROM value v "
          "JOIN event e ON e.id = v.event_id "
          "JOIN country c ON c.id = e.country_id "
          "ORDER BY time DESC "
          ";";

    if (!DatabaseExecute(db, sql)) {
        err = GetLastError();
        PrintFormat("%s error (view) #%d : %s", __FUNCTION__, err, ErrorDescription(err));
        DatabaseClose(db);
        return false;
    }

    if (!DatabaseTransactionBegin(db)) {
        err = GetLastError();
        PrintFormat("%s error (DatabaseTransactionBegin) #%d : %s", __FUNCTION__, err, ErrorDescription(err));
        DatabaseClose(db);
        return false;
    }

    for (int i = 0; i < n; i++) {
        if (IsStopped()) {
            PrintFormat("%s (loop: countries) stopped!", __FUNCTION__);
            DatabaseTransactionRollback(db);
            DatabaseClose(db);
            return false;
        }

        sql = StringFormat("SELECT EXISTS (SELECT 1 FROM country WHERE id=%d LIMIT 1)", countries[i].id);
        dp = DatabasePrepare(db, sql);
        DatabaseRead(dp);
        DatabaseColumnInteger(dp, 0, t);
        DatabaseFinalize(dp);

        if (!t) {
            StringReplace(countries[i].name, "'", "''");
            StringReplace(countries[i].code, "'", "''");
            StringReplace(countries[i].currency, "'", "''");
            StringReplace(countries[i].currency_symbol, "'", "''");
            StringReplace(countries[i].url_name, "'", "''");

            sql = "INSERT INTO country(id, name, code, currency, currency_symbol, url_name) VALUES("
                  + StringFormat("%d, '%s', '%s', '%s', '%s', '%s'", countries[i].id, countries[i].name, countries[i].code, countries[i].currency, countries[i].currency_symbol, countries[i].url_name) +
                  ")"
                  ";";

            if (!DatabaseExecute(db, sql)) {
                err = GetLastError();
                PrintFormat("%s error (insert: country) #%d : %s", __FUNCTION__, err, ErrorDescription(err));
                DatabaseTransactionRollback(db);
                DatabaseClose(db);
                return false;
            }
        }

        MqlCalendarValue values[];
        int m = 0;
        iter = 0;
        do {
            iter++;
            ResetLastError();
            m = CalendarValueHistory(values, date_from, date_to, countries[i].code);
            err = GetLastError();
            if (m > -1) break;
            if (err != ERR_CALENDAR_TIMEOUT || iter == Max_Retry) {
                PrintFormat("%s error #%d (CalendarValueHistory) : %s, country: %s", __FUNCTION__, err, ErrorDescription(err), countries[i].code);
                DatabaseTransactionRollback(db);
                DatabaseClose(db);
                return false;
            }
        } while(err == ERR_CALENDAR_TIMEOUT);

        for (int j = 0; j < m; j++) {
            if (IsStopped()) {
                PrintFormat("%s (loop: values) stopped!", __FUNCTION__);
                DatabaseTransactionRollback(db);
                DatabaseClose(db);
                return false;
            }

            sql = StringFormat("SELECT EXISTS (SELECT 1 FROM value WHERE id=%d LIMIT 1)", values[j].id);
            dp = DatabasePrepare(db, sql);
            DatabaseRead(dp);
            DatabaseColumnInteger(dp, 0, t);
            DatabaseFinalize(dp);
            if (t) {
                sql = "UPDATE value SET " +
                      StringFormat("event_id=%d, time=%d, period=%d, revision=%d, actual_value=%d, prev_value=%d, revised_prev_value=%d, forecast_value=%d, impact_type=%d ", values[j].event_id, values[j].time, values[j].period, values[j].revision, values[j].actual_value, values[j].prev_value, values[j].revised_prev_value, values[j].forecast_value, values[j].impact_type) +
                      StringFormat("WHERE id=%d ", values[j].id) +
                      ";";

                if (!DatabaseExecute(db, sql)) {
                    err = GetLastError();
                    PrintFormat("%s error (update: value) #%d : %s", __FUNCTION__, err, ErrorDescription(err));
                    DatabaseTransactionRollback(db);
                    DatabaseClose(db);
                    return false;
                }
                continue;
            }

            MqlCalendarEvent event;
            if (!CalendarEventById(values[j].event_id, event)) {
                err = GetLastError();
                PrintFormat("%s (CalendarEventById) error #%d : %s, country: %s", __FUNCTION__, err, ErrorDescription(err), countries[i].code);
                continue;
            }

            sql = StringFormat("SELECT EXISTS (SELECT 1 FROM event WHERE id=%d LIMIT 1)", event.id);
            dp = DatabasePrepare(db, sql);
            DatabaseRead(dp);
            DatabaseColumnInteger(dp, 0, t);
            DatabaseFinalize(dp);

            if (!t) {
                StringReplace(event.source_url, "'", "''");
                StringReplace(event.event_code, "'", "''");
                StringReplace(event.name, "'", "''");

                sql = "INSERT INTO `event`(id, type, sector, frequency, time_mode, country_id, unit, importance, multiplier, digits, source_url, event_code, name) VALUES("
                      + StringFormat("%d, %d, %d, %d, %d, %d, %d, %d, %d, %d, '%s', '%s', '%s'", event.id, event.type, event.sector, event.frequency, event.time_mode, event.country_id, event.unit, event.importance, event.multiplier, event.digits, event.source_url, event.event_code, event.name) +
                      ")"
                      ";";

                if (!DatabaseExecute(db, sql)) {
                    err = GetLastError();
                    PrintFormat("%s error (insert: event) #%d : %s", __FUNCTION__, err, ErrorDescription(err));
                    DatabaseTransactionRollback(db);
                    DatabaseClose(db);
                    return false;
                }
            }

            sql = "INSERT INTO value(id, event_id, time, period, revision, actual_value, prev_value, revised_prev_value, forecast_value, impact_type) VALUES("
                  + StringFormat("%d, %d, %d, %d, %d, %d, %d, %d, %d, %d", values[j].id, values[j].event_id, values[j].time, values[j].period, values[j].revision, values[j].actual_value, values[j].prev_value, values[j].revised_prev_value, values[j].forecast_value, values[j].impact_type) +
                  ")"
                  ";";

            if (!DatabaseExecute(db, sql)) {
                err = GetLastError();
                PrintFormat("%s error (insert: value) #%d : %s", __FUNCTION__, err, ErrorDescription(err));
                DatabaseTransactionRollback(db);
                DatabaseClose(db);
                return false;
            }
        }
    }

    if (!DatabaseTransactionCommit(db)) {
        err = GetLastError();
        PrintFormat("%s error (DatabaseTransactionCommit) #%d : %s", __FUNCTION__, err, ErrorDescription(err));
        DatabaseClose(db);
        return false;
    }

    DatabaseClose(db);
    PrintFormat("Fetching News data for year %d successfully ended.", year);
    return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool hasSymbolNews(string symbol, ENUM_NEWS_IMPORTANCE importance = 0, int minsBefore = 0, int minsAfter = 0, datetime time = 0) {
    string cur1 = StringSubstr(symbol, 0, 3);
    string cur2 = StringSubstr(symbol, 3, 3);
    if (hasCurrencyNews(cur1, importance, minsBefore, minsAfter, time))
        return true;
    if (hasCurrencyNews(cur2, importance, minsBefore, minsAfter, time))
        return true;
    return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool hasCurrencyNews(string currency, ENUM_NEWS_IMPORTANCE importance = 0, int minsBefore = 0, int minsAfter = 0, datetime time = 0) {
    const int Max_Retry = 4;

    int p = 2 * (minsBefore + minsAfter + 1) * PeriodSeconds(PERIOD_M1);
    datetime Tc = time == 0 ? TimeTradeServer() : time;
    datetime date_from = Tc - p;
    datetime date_to = Tc + p;

    if (!MQLInfoInteger(MQL_TESTER)) {
        MqlCalendarValue values[];
        int n = 0;
        int iter = 0;
        int err;
        do {
            iter++;
            ResetLastError();
            n = CalendarValueHistory(values, date_from, date_to, NULL, currency);
            err = GetLastError();
            if (n > -1) break;
            if (err != ERR_CALENDAR_TIMEOUT || iter == Max_Retry) {
                PrintFormat("%s error #%d (CalendarValueHistory) : %s, currency: %s", __FUNCTION__, err, ErrorDescription(err), currency);
                return false;
            }
        } while(err == ERR_CALENDAR_TIMEOUT);

        for (int i = 0; i < n; i++) {
            MqlCalendarEvent event;
            if (!CalendarEventById(values[i].event_id, event)) {
                err = GetLastError();
                PrintFormat("%s error #%d : %s, currency: %s", __FUNCTION__, err, ErrorDescription(err), currency);
                continue;
            }

            datetime t = values[i].time;
            datetime tb = t - minsBefore * PeriodSeconds(PERIOD_M1);
            datetime te = t + minsAfter * PeriodSeconds(PERIOD_M1);
            if (!(Tc >= tb && Tc <= te)) continue;
            if (event.importance >= (int) importance) return true;
        }

        return false;
    }

    if (!FileIsExist(getCalendarDbPath(), FILE_COMMON)) return false;

    int db, dp;
    string sql;

    db = DatabaseOpen(getCalendarDbPath(), DATABASE_OPEN_READONLY | DATABASE_OPEN_COMMON);
    if (db == INVALID_HANDLE) {
        int err = GetLastError();
        PrintFormat("%s error (DatabaseOpen) #%d : %s", __FUNCTION__, err, ErrorDescription(err));
        return false;
    }

    sql = StringFormat("SELECT time_mode, time, importance FROM main WHERE time >= %d AND time < %d AND currency='%s' COLLATE NOCASE", date_from, date_to, currency);
    dp = DatabasePrepare(db, sql);

    while (DatabaseRead(dp) && !IsStopped()) {
        long time_mode, time, imp;
        DatabaseColumnLong(dp, 0, time_mode);
        DatabaseColumnLong(dp, 1, time);
        DatabaseColumnLong(dp, 2, imp);
        datetime t = (datetime) time;

        datetime tb = t - minsBefore * PeriodSeconds(PERIOD_M1);
        datetime te = t + minsAfter * PeriodSeconds(PERIOD_M1);
        if (!(Tc >= tb && Tc <= te)) continue;

        if (imp >= (int) importance) {
            DatabaseFinalize(dp);
            DatabaseClose(db);
            return true;
        }
    }

    DatabaseFinalize(dp);
    DatabaseClose(db);
    return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double BuySL(ENUM_SL sltype, int lookback, double price = 0, int dev = 0, int start = 0, string symbol = NULL, ENUM_TIMEFRAMES timeframe = 0) {
    symbol = symbol == NULL ? _Symbol : symbol;
    price = price == 0 ? Ask(symbol) : price;
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int digits = (int) SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double sl = 0;

    if (sltype == SL_SWING) {
        int i = iLowest(symbol, timeframe, MODE_LOW, lookback, start);
        sl = iLow(symbol, timeframe, i) - dev * point;
    }

    else if (sltype == SL_AR) {
        double sum = 0;
        for (int i = start; i < start + lookback; i++) {
            double high = iHigh(symbol, timeframe, i);
            double low = iLow(symbol, timeframe, i);
            double range = high - low;
            sum += range;
        }
        sl = price - (sum / lookback) - dev * point;
    }

    else if (sltype == SL_MR) {
        double max = 0;
        for (int i = start; i < start + lookback; i++) {
            double high = iHigh(symbol, timeframe, i);
            double low = iLow(symbol, timeframe, i);
            double range = high - low;
            if (range > max)
                max = range;
        }
        sl = price - max - dev * point;
    }

    else if (sltype == SL_FIXED_POINT) {
        sl = price - dev * point;
    }

    sl = NormalizeDouble(sl, digits);
    return sl;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SellSL(ENUM_SL sltype, int lookback, double price = 0, int dev = 0, int start = 0, string symbol = NULL, ENUM_TIMEFRAMES timeframe = 0) {
    symbol = symbol == NULL ? _Symbol : symbol;
    price = price == 0 ? Bid(symbol) : price;
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int digits = (int) SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double sl = 0;

    if (sltype == SL_SWING) {
        int i = iHighest(symbol, timeframe, MODE_HIGH, lookback, start);
        sl = iHigh(symbol, timeframe, i) + dev * point;
    }

    else if (sltype == SL_AR) {
        double sum = 0;
        for (int i = start; i < start + lookback; i++) {
            double high = iHigh(symbol, timeframe, i);
            double low = iLow(symbol, timeframe, i);
            double range = high - low;
            sum += range;
        }
        sl = price + (sum / lookback) + dev * point;
    }

    else if (sltype == SL_MR) {
        double max = 0;
        for (int i = start; i < start + lookback; i++) {
            double high = iHigh(symbol, timeframe, i);
            double low = iLow(symbol, timeframe, i);
            double range = high - low;
            if (range > max)
                max = range;
        }
        sl = price + max + dev * point;
    }

    else if (sltype == SL_FIXED_POINT) {
        sl = price + dev * point;
    }

    sl = NormalizeDouble(sl, digits);
    return sl;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetTickValue(string symbol = NULL) {
    if (symbol == NULL) symbol = _Symbol;
    double price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double profit = 0;
    if (OrderCalcProfit(ORDER_TYPE_BUY, symbol, 1, price, price + tickSize, profit) && profit > 0)
        return profit;
    return SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Trim(string s) {
    string str = s + " ";
    StringTrimLeft(str);
    StringTrimRight(str);
    return str;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
int ArraySearch(const T &arr[], T value) {
    int n = ArraySize(arr);
    for (int i = 0; i < n; i++) {
        if (arr[i] == value)
            return i;
    }
    return -1;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
int ArrayAdd(T &arr[], T value) {
    int n = ArrayResize(arr, ArraySize(arr) + 1);
    arr[n - 1] = value;
    return n;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountDigits(double val, int maxPrecision = 8) {
    int digits = 0;
    while (NormalizeDouble(val, digits) != NormalizeDouble(val, maxPrecision))
        digits++;
    return digits;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Ind(int handle, int i, int buffer_index = 0) {
    double B[1];
    if (handle <= 0) {
        PrintFormat("Error (%s, handle): #%d", __FUNCTION__, GetLastError());
        return -1;
    }
    if (CopyBuffer(handle, buffer_index, i, 1, B) != 1) {
        PrintFormat("Error (%s, CopyBuffer): #%d", __FUNCTION__, GetLastError());
        return -1;
    }
    return B[0];
}

//+------------------------------------------------------------------+

//===== END EAUtils.mqh =====


//===== BEGIN Cot.mqh =====
//+------------------------------------------------------------------+
//|                                                          Cot.mqh |
//|                                     Copyright 2024-2025, Geraked |
//|                                       https://github.com/geraked |
//+------------------------------------------------------------------+





//===== BEGIN WinINet.mqh =====
//+------------------------------------------------------------------+
//|                                                      WinINet.mqh |
//|                                     Copyright 2023-2025, Geraked |
//|                                       https://github.com/geraked |
//+------------------------------------------------------------------+




#define WININET_TIMEOUT_SECS   300
#define WININET_BUFF_SIZE      16384
#define WININET_KERNEL_ERRORS  true

#define INTERNET_FLAG_PRAGMA_NOCACHE            0x00000100
#define INTERNET_FLAG_KEEP_CONNECTION           0x00400000
#define INTERNET_FLAG_SECURE                    0x00800000
#define INTERNET_FLAG_RELOAD                    0x80000000
#define INTERNET_FLAG_IGNORE_REDIRECT_TO_HTTP   0x00008000
#define INTERNET_FLAG_IGNORE_REDIRECT_TO_HTTPS  0x00004000
#define INTERNET_FLAG_IGNORE_CERT_DATE_INVALID  0x00002000
#define INTERNET_FLAG_IGNORE_CERT_CN_INVALID    0x00001000
#define INTERNET_FLAG_NO_AUTO_REDIRECT          0x00200000
#define HTTP_ADDREQ_FLAG_REPLACE                0x80000000
#define HTTP_ADDREQ_FLAG_ADD                    0x20000000

#define INTERNET_OPTION_HTTP_DECODING           65
#define INTERNET_OPTION_SEND_TIMEOUT            5
#define INTERNET_OPTION_RECEIVE_TIMEOUT         6
#define HTTP_QUERY_CONTENT_LENGTH               5
#define HTTP_QUERY_STATUS_CODE                  19
#define HTTP_QUERY_STATUS_TEXT                  20
#define HTTP_QUERY_RAW_HEADERS                  21
#define HTTP_QUERY_RAW_HEADERS_CRLF             22

#import "kernel32.dll"
uint GetLastError(void);
#import

#import "wininet.dll"
long InternetOpenW(const ushort &lpszAgent[], int dwAccessType, const ushort &lpszProxyName[], const ushort &lpszProxyBypass[], uint dwFlags);
long InternetConnectW(long hInternet, const ushort &lpszServerName[], int nServerPort, const ushort &lpszUsername[], const ushort &lpszPassword[], int dwService, uint dwFlags, int dwContext);
long HttpOpenRequestW(long hConnect, const ushort &lpszVerb[], const ushort &lpszObjectName[], const ushort &lpszVersion[], const ushort &lpszReferer[], const ushort &lplpszAcceptTypes[][], uint dwFlags, int dwContext);
int InternetCloseHandle(long hInternet);
int InternetSetOptionW(long hInternet, int dwOption, long &lpBuffer, int dwBufferLength);
int HttpAddRequestHeadersW(long hRequest, const ushort &lpszHeaders[], int dwHeadersLength, uint dwModifiers);
int HttpSendRequestW(long hRequest, const ushort &lpszHeaders[], int dwHeadersLength, const uchar &lpOptional[], int dwOptionalLength);
int HttpSendRequestExW(long hRequest, long lpBuffersIn, long lpBuffersOut, uint dwFlags, int dwContext);
int HttpEndRequestW(long hRequest, long lpBuffersOut, uint dwFlags, int dwContext);
int HttpQueryInfoW(long hRequest, int dwInfoLevel, uchar &lpvBuffer[], int &lpdwBufferLength, int &lpdwIndex);
int InternetWriteFile(long hFile, const uchar &lpBuffer[], int dwNumberOfBytesToWrite, int &lpdwNumberOfBytesWritten);
int InternetReadFile(long hFile, uchar &lpBuffer[], int dwNumberOfBytesToRead, int &lpdwNumberOfBytesRead);
#import

struct WininetRequest {
    string           method;
    string           host;
    int              port;
    string           path;
    string           headers;
    uchar            data[];
    string           data_str;
    void             WininetRequest() {
        method = "GET";
        port = 443;
        path = "/";
        headers = "";
    }
};

struct WininetResponse {
    int              status;
    string           headers;
    uchar            data[];
    string           GetDataStr() {
        return UnicodeUnescape(data);
    }
};

//+------------------------------------------------------------------+
//| HTTP request using wininet.dll                                   |
//+------------------------------------------------------------------+
int WebReq(
    const string  method,           // HTTP method
    const string  host,             // host name
    const string  path,             // URL path
    int           port,             // port number
    bool          secure,           // use HTTPS
    const string  headers,          // HTTP request headers
    const uchar   &data[],          // HTTP request body
    uchar         &result[],        // server response data
    string        &result_headers   // headers of server response
) {

//- Declare the variables.
    ushort buff[WININET_BUFF_SIZE / 2], buff2[WININET_BUFF_SIZE / 2];
    uchar cbuff[WININET_BUFF_SIZE];
    int n, bLen, bLen2, bIdx;
    long lval;
    long session, connection, request;
    int status;
    uint flags;
    string head;

//- Create the NULL string.
    ushort nill[2] = {0, 0};
    ushort nill2[2][2] = {{0, 0}, {0, 0}};

//- Create a session.
    StringToShortArray(GetUserAgent(), buff);
    session = InternetOpenW(buff, 0, nill, nill, 0);
    if (session <= 0)
        return _wininetErr("InternetOpen");

//- Enable automatically decoding from gzip and deflate.
    lval = 1;
    if (!InternetSetOptionW(session, INTERNET_OPTION_HTTP_DECODING, lval, sizeof(int)))
        return _wininetErr("InternetSetOption, DECODING", session);

//- Set timeouts.
    lval = WININET_TIMEOUT_SECS * 1000;
    if (!InternetSetOptionW(session, INTERNET_OPTION_SEND_TIMEOUT, lval, sizeof(int)))
        return _wininetErr("InternetSetOption, SEND_TIMEOUT", session);
    lval = WININET_TIMEOUT_SECS * 1000;
    if (!InternetSetOptionW(session, INTERNET_OPTION_RECEIVE_TIMEOUT, lval, sizeof(int)))
        return _wininetErr("InternetSetOption, RECEIVE_TIMEOUT", session);

//- Create a connection.
    StringToShortArray(host, buff);
    connection = InternetConnectW(session, buff, port, nill, nill, 3, 0, 0);
    if (connection <= 0)
        return _wininetErr("InternetConnect", session);

//- Open a request.
    StringToShortArray(method, buff);
    StringToShortArray(path, buff2);
    flags = INTERNET_FLAG_RELOAD | INTERNET_FLAG_PRAGMA_NOCACHE;
    flags |= INTERNET_FLAG_IGNORE_CERT_CN_INVALID | INTERNET_FLAG_IGNORE_CERT_DATE_INVALID;
    if (port == 443 || (secure && port != 80)) flags |= INTERNET_FLAG_SECURE;
    if (method == "GET") flags |= INTERNET_FLAG_IGNORE_REDIRECT_TO_HTTP | INTERNET_FLAG_IGNORE_REDIRECT_TO_HTTPS;
    if (method != "GET") flags |= INTERNET_FLAG_NO_AUTO_REDIRECT;
    request = HttpOpenRequestW(connection, buff, buff2, nill, nill, nill2, flags, 0);
    if (request <= 0)
        return _wininetErr("HttpOpenRequest", session, connection);

//- Add request headers.
    n = ArraySize(data);
    if (n > 0 && data[n - 1] == 0) n--;
    head = StringFormat("Accept-Encoding: gzip, deflate\r\n"
                        "Content-Length: %d\r\n", n);
    bLen = StringToShortArray(head + headers, buff);
    if (bLen > 0 && buff[bLen - 1] == 0) bLen--;
    if (!HttpAddRequestHeadersW(request, buff, bLen, HTTP_ADDREQ_FLAG_ADD | HTTP_ADDREQ_FLAG_REPLACE))
        return _wininetErr("HttpAddRequestHeaders", session, connection, request);

//- Send the request.
    int cnt = 1;
    while (!HttpSendRequestExW(request, 0, 0, 0, 0)) {
        if (cnt == 5)
            return _wininetErr("HttpSendRequestEx", session, connection, request);
        Sleep(1000);
        cnt++;
    }
    bIdx = 0;
    bLen2 = 0;
    while (true) {
        bLen = MathMin(WININET_BUFF_SIZE, n - bIdx);
        if (bLen <= 0) break;
        ArrayCopy(cbuff, data, 0, bIdx, bLen);
        if (!InternetWriteFile(request, cbuff, bLen, bLen2))
            return _wininetErr("InternetWriteFile", session, connection, request);
        bIdx += bLen2;
    }
    if (!HttpEndRequestW(request, 0, 0, 0))
        return _wininetErr("HttpEndRequest", session, connection, request);

//- Fetch the status code from the response header.
    bLen = WININET_BUFF_SIZE;
    bIdx = 0;
    if (!HttpQueryInfoW(request, HTTP_QUERY_STATUS_CODE, cbuff, bLen, bIdx))
        return _wininetErr("HttpQueryInfo, STATUS_CODE", session, connection, request);
    status = (int) UnicodeUnescape(cbuff, bLen);

//- Fetch the entire response header.
    bLen = WININET_BUFF_SIZE;
    bIdx = 0;
    if (!HttpQueryInfoW(request, HTTP_QUERY_RAW_HEADERS_CRLF, cbuff, bLen, bIdx))
        return _wininetErr("HttpQueryInfo, HEADER", session, connection, request);
    result_headers = UnicodeUnescape(cbuff, bLen);

//- Fetch the response body.
    bLen = 0;
    while (true) {
        if (!InternetReadFile(request, cbuff, WININET_BUFF_SIZE, bLen))
            return _wininetErr("InternetReadFile", session, connection, request);
        if (bLen <= 0) break;
        ArrayCopy(result, cbuff, ArraySize(result), 0, bLen);
    }

//- Close the request, connection, and session.
    if (!InternetCloseHandle(request))
        _wininetErr("InternetCloseRequest");
    if (!InternetCloseHandle(connection))
        _wininetErr("InternetCloseConnection");
    if (!InternetCloseHandle(session))
        _wininetErr("InternetCloseSession");

    return status;
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
bool WebReq(WininetRequest &req, WininetResponse &res) {
    if (req.method == NULL || req.method == "") req.method = "GET";
    if (req.path == NULL || req.path == "") req.path = "/";
    if (req.headers == NULL) req.headers = "";
    if (req.port == 0) req.port = 443;
    if (ArraySize(req.data) > 0 || req.data_str == NULL)
        res.status = WebReq(req.method, req.host, req.path, req.port, false, req.headers, req.data, res.data, res.headers);
    else {
        uchar data_arr[];
        StringToCharArray(req.data_str, data_arr, 0, WHOLE_ARRAY, CP_UTF8);
        res.status = WebReq(req.method, req.host, req.path, req.port, false, req.headers, data_arr, res.data, res.headers);
    }
    if (res.status == -1) return false;
    return true;
}

//+------------------------------------------------------------------+
//| Generate User-Agent for the HTTP request header.                 |
//+------------------------------------------------------------------+
string GetUserAgent() {
    return StringFormat(
               "%s/%d (%s; %s; %s %d Cores; %dMB RAM) WinINet/1.7",
               TerminalInfoString(TERMINAL_NAME),
               TerminalInfoInteger(TERMINAL_BUILD),
               TerminalInfoString(TERMINAL_OS_VERSION),
               TerminalInfoInteger(TERMINAL_X64) ? "x64" : "x32",
               TerminalInfoString(TERMINAL_CPU_NAME),
               TerminalInfoInteger(TERMINAL_CPU_CORES),
               TerminalInfoInteger(TERMINAL_MEMORY_PHYSICAL)
           );
}

//+------------------------------------------------------------------+
//| Remove 0 characters from the fixed size array.                   |
//+------------------------------------------------------------------+
template<typename T>
int ArrayRemoveGaps(T &arr[], int n) {
    int i, j, k;
    T c;
    k = 0;
    for (i = 0; i < n; i++) {
        if (arr[i] != 0) {
            k++;
            continue;
        }
        c = 0;
        for (j = i + 1; j < n; j++) {
            if (arr[j] != 0) {
                c = arr[j];
                arr[j] = 0;
                break;
            }
        }
        if (c == 0) break;
        arr[i] = c;
        k++;
    }
    if (k < n)
        arr[k] = 0;
    return k;
}

//+------------------------------------------------------------------+
//| Unescape Unicode characters from the string.                     |
//+------------------------------------------------------------------+
string UnicodeUnescape(string str) {
    ushort s[];
    ushort c1, c2, c, x;
    int n, i, j, k;
    n = StringLen(str);
    ArrayResize(s, n);
    i = 0;
    j = 0;
    while (i < n) {
        c1 = str[i];
        c2 = i + 1 < n ? str[i + 1] : 0;
        if (c1 == '\\' && (c2 == 'u' || c2 == 'U')) {
            if (i + 5 < n) {
                c = 0;
                for (k = i + 2; k < i + 6; k++) {
                    x = str[k];
                    if (x >= '0' && x <= '9') x = x - '0';
                    else if (x >= 'a' && x <= 'f') x = x - 'a' + 10;
                    else if (x >= 'A' && x <= 'F') x = x - 'A' + 10;
                    else break;
                    c = (c << 4) | (x & 0xF);
                }
                if (k == i + 6) {
                    if (c != 0) s[j++] = c;
                    i += 6;
                } else {
                    s[j++] = c1;
                    i++;
                }
            } else {
                s[j++] = c1;
                i++;
            }
        } else {
            s[j++] = c1;
            i++;
        }
    }
    return ShortArrayToString(s, 0, j);
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
string UnicodeUnescape(ushort &arr[], int n = 0) {
    if (n == 0) n = ArraySize(arr);
    n = ArrayRemoveGaps(arr, n);
    return UnicodeUnescape(ShortArrayToString(arr, 0, n));
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
string UnicodeUnescape(uchar &arr[], int n = 0) {
    if (n == 0) n = ArraySize(arr);
    n = ArrayRemoveGaps(arr, n);
    return UnicodeUnescape(CharArrayToString(arr, 0, n, CP_UTF8));
}

//+------------------------------------------------------------------+
//| Handle WinINet errors.                                           |
//+------------------------------------------------------------------+
int _wininetErr(string title = "", long session = 0, long connection = 0, long request = 0) {
    uint err = kernel32::GetLastError();
    if (WININET_KERNEL_ERRORS)
        PrintFormat("Error (%s, %s): #%d", "WinINet", title, err);
    if (request > 0) InternetCloseHandle(request);
    if (connection > 0) InternetCloseHandle(connection);
    if (session > 0) InternetCloseHandle(session);
    return -1;
}

//+------------------------------------------------------------------+

//===== END WinINet.mqh =====


//===== BEGIN SysTime.mqh =====
//+------------------------------------------------------------------+
//|                                                      SysTime.mqh |
//|                                          Copyright 2024, Geraked |
//|                                       https://github.com/geraked |
//+------------------------------------------------------------------+




#include <WinAPI\sysinfoapi.mqh>

//+------------------------------------------------------------------+
//| Retrieves the current system date and time in UTC format.        |
//+------------------------------------------------------------------+
datetime TimeSystem() {
    SYSTEMTIME st;
    GetSystemTime(st);
    return SystemTimeToDatetime(st);
}

//+------------------------------------------------------------------+
//| Retrieves the current local date and time.                       |
//+------------------------------------------------------------------+
datetime TimeSystemLocal() {
    SYSTEMTIME st;
    GetLocalTime(st);
    return SystemTimeToDatetime(st);
}

//+------------------------------------------------------------------+
//| Convert SYSTEMTIME to datetime.                                  |
//+------------------------------------------------------------------+
datetime SystemTimeToDatetime(SYSTEMTIME &st) {
    string str = StringFormat("%d.%02d.%02d %02d:%02d:%02d",
                              st.wYear, st.wMonth, st.wDay,
                              st.wHour, st.wMinute, st.wSecond);
    return StringToTime(str);
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
datetime TimeSystem(MqlDateTime &dt_str) {
    datetime t = TimeSystem();
    TimeToStruct(t, dt_str);
    return t;
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
datetime TimeSystemLocal(MqlDateTime &dt_str) {
    datetime t = TimeSystemLocal();
    TimeToStruct(t, dt_str);
    return t;
}

//+------------------------------------------------------------------+

//===== END SysTime.mqh =====


//===== BEGIN Shell.mqh =====
//+------------------------------------------------------------------+
//|                                                        Shell.mqh |
//|                                          Copyright 2024, Geraked |
//|                                       https://github.com/geraked |
//+------------------------------------------------------------------+




#include <WinAPI\processthreadsapi.mqh>

#define SHELL_DIR_PATH    "Shell\\"
#define CREATE_NO_WINDOW  0x08000000
#define WAIT_TIMEOUT      0x00000102

#import "kernel32.dll"
uint GetLastError(void);
int CloseHandle(long hObject);
int WaitForSingleObject(long hHandle, int dwMilliseconds);
#import

#import "user32.dll"
int WaitForInputIdle(long hHandle, int dwMilliseconds);
#import

//+------------------------------------------------------------------+
//| Execute PowerShell command.                                      |
//+------------------------------------------------------------------+
string PShell(string cmd, int timeout_ms = -1) {
    string wrap = "powershell & {Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; %s} *> \"%s\"";
    return _shell(wrap, cmd, timeout_ms);
}

//+------------------------------------------------------------------+
//| Execute CMD command.                                             |
//+------------------------------------------------------------------+
string CShell(string cmd, int timeout_ms = -1) {
    string wrap = "cmd /c \"(%s) > \"%s\" 2>&1\"";
    return _shell(wrap, cmd, timeout_ms);
}

//+------------------------------------------------------------------+
//| Open an application and pass the command.                        |
//+------------------------------------------------------------------+
bool Open(string cmd, int timeout_ms = -1) {
    PROCESS_INFORMATION pi;
    STARTUPINFOW si;
    ZeroMemory(pi);
    ZeroMemory(si);
    si.cb = sizeof(si);
    string dir = GetShellDirAbs();
    if (!CreateProcessW(NULL, cmd, 0, 0, 0, 0, 0, dir, si, pi)) {
        uint err = kernel32::GetLastError();
        PrintFormat("Error (%s, CreateProcess): #%d", __FUNCTION__, err);
        return false;
    }
    int wfs = WaitForSingleObject(pi.hProcess, timeout_ms);
    if (wfs != 0) {
        if (wfs == WAIT_TIMEOUT)
            Print("Warning: waiting for process timed out");
        else
            PrintFormat("Error (%s, WaitForSingleObject): #%d", __FUNCTION__, wfs);
        return false;
    }
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return true;
}

//+------------------------------------------------------------------+
//| Get absolute path of Shell working directory.                    |
//+------------------------------------------------------------------+
string GetShellDirAbs() {
    string abs_dir = TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\Files\\" + SHELL_DIR_PATH;
    if (!FileIsExist(SHELL_DIR_PATH, FILE_COMMON)) {
        if (!FolderCreate(SHELL_DIR_PATH, FILE_COMMON)) {
            PrintFormat("Error (%s): #%d", __FUNCTION__, ::GetLastError());
            return NULL;
        }
    }
    return abs_dir;
}

//+------------------------------------------------------------------+
//| Check if OS is Windows.                                          |
//+------------------------------------------------------------------+
bool IsWindows() {
    string os = TerminalInfoString(TERMINAL_OS_VERSION);
    StringToLower(os);
    return(StringFind(os, "windows") != -1);
}

//+------------------------------------------------------------------+
//| Used for the execution of console commands.                      |
//+------------------------------------------------------------------+
string _shell(string wrap, string cmd, int timeout_ms = -1) {
    PROCESS_INFORMATION pi;
    STARTUPINFOW si;
    ZeroMemory(pi);
    ZeroMemory(si);
    si.cb = sizeof(si);

    string dir_abs = GetShellDirAbs();
    string file_name = "ps-" + (string) GetMicrosecondCount();
    string p = dir_abs + file_name;
    string c = StringFormat(wrap, cmd, p);

    if (!CreateProcessW(NULL, c, 0, 0, 0, CREATE_NO_WINDOW, 0, dir_abs, si, pi)) {
        uint err = kernel32::GetLastError();
        PrintFormat("Error (%s, CreateProcess): #%d", __FUNCTION__, err);
        return NULL;
    }

    int wfs = WaitForSingleObject(pi.hProcess, timeout_ms);
    if (wfs != 0) {
        if (wfs == WAIT_TIMEOUT)
            Print("Warning: waiting for process timed out");
        else
            PrintFormat("Error (%s, WaitForSingleObject): #%d", __FUNCTION__, wfs);
        return NULL;
    }

    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);

    int fh = FileOpen(SHELL_DIR_PATH + file_name, FILE_READ | FILE_SHARE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON, CP_UTF8);
    if (fh == INVALID_HANDLE) {
        PrintFormat("Error (%s, FileOpen): #%d", __FUNCTION__, ::GetLastError());
        return NULL;
    }

    string str = "";
    while (!FileIsEnding(fh)) {
        if (IsStopped()) {
            PrintFormat("%s (loop: file) stopped!", __FUNCTION__);
            FileClose(fh);
            return NULL;
        }
        StringAdd(str, FileReadString(fh));
    }
    FileClose(fh);

    if (!FileDelete(SHELL_DIR_PATH + file_name, FILE_COMMON)) {
        PrintFormat("Error (%s, FileDelete): #%d", __FUNCTION__, ::GetLastError());
        return NULL;
    }

    return str;
}

//+------------------------------------------------------------------+

//===== END Shell.mqh =====


//===== BEGIN Storage.mqh =====
//+------------------------------------------------------------------+
//|                                                      Storage.mqh |
//|                                          Copyright 2024, Geraked |
//|                                       https://github.com/geraked |
//+------------------------------------------------------------------+






#define STORAGE_DB_PATH "Geraked\\storage.db"

enum ENUM_STORAGE_TIME {
    STORAGE_TIME_SYSTEM, // TimeSystem
    STORAGE_TIME_TRADESERVER // TimeTradeServer
};

//+------------------------------------------------------------------+
//| Returns the value of a global variable.                          |
//+------------------------------------------------------------------+
template<typename T>
T StorageGet(string key, T default_value) {
    while (GlobalVariableCheck("_DbLock"));
    while (!GlobalVariableTemp("_DbLock"));

    int db = _storageInitDb();
    if (db == INVALID_HANDLE) {
        while (!GlobalVariableDel("_DbLock"));
        return default_value;
    }

    string val;
    string sql = StringFormat("SELECT value FROM T WHERE key='%s' LIMIT 1", key);

    int dp = DatabasePrepare(db, sql);
    if (dp == INVALID_HANDLE) {
        PrintFormat("Error (%s, DatabasePrepare): #%d", __FUNCTION__, GetLastError());
        DatabaseClose(db);
        while (!GlobalVariableDel("_DbLock"));
        return default_value;
    }

    if (!DatabaseRead(dp) && GetLastError() != ERR_DATABASE_NO_MORE_DATA) {
        PrintFormat("Error (%s, DatabaseRead): #%d", __FUNCTION__, GetLastError());
    }

    if (!DatabaseColumnText(dp, 0, val)) {
        PrintFormat("Error (%s, DatabaseColumnText): #%d", __FUNCTION__, GetLastError());
    }

    DatabaseFinalize(dp);
    DatabaseClose(db);
    while (!GlobalVariableDel("_DbLock"));

    if (val == NULL)
        return default_value;
    if (typename(T) == "datetime" || typename(T) == "color")
        return (T)((long) val);

    return (T) val;
}

//+------------------------------------------------------------------+
//| Sets the new value to a global variable.                         |
//+------------------------------------------------------------------+
template<typename T>
bool StorageSet(string key, T value) {
    while (GlobalVariableCheck("_DbLock"));
    while (!GlobalVariableTemp("_DbLock"));

    int db = _storageInitDb(DATABASE_OPEN_READWRITE);
    if (db == INVALID_HANDLE) {
        while (!GlobalVariableDel("_DbLock"));
        return false;
    }

    string sql = "INSERT OR REPLACE INTO T (key, value, time_system, time_server) VALUES (";
    sql += StringFormat("'%s', ", key);

    if (typename(T) == "datetime" || typename(T) == "color")
        sql += StringFormat("'%d', ", value);
    else
        sql += StringFormat("'%s', ", (string) value);

    sql += StringFormat("%d, ", TimeSystem());
    sql += StringFormat("%d);", TimeTradeServer());

    if (!DatabaseExecute(db, sql)) {
        PrintFormat("Error (%s, Upsert): #%d", __FUNCTION__, GetLastError());
        DatabaseClose(db);
        while (!GlobalVariableDel("_DbLock"));
        return false;
    }
    DatabaseClose(db);
    while (!GlobalVariableDel("_DbLock"));

    return true;
}

//+------------------------------------------------------------------+
//| Deletes a global variable.                                       |
//+------------------------------------------------------------------+
bool StorageDel(string key) {
    while (GlobalVariableCheck("_DbLock"));
    while (!GlobalVariableTemp("_DbLock"));

    int db = _storageInitDb(DATABASE_OPEN_READWRITE);
    if (db == INVALID_HANDLE) {
        while (!GlobalVariableDel("_DbLock"));
        return false;
    }

    string sql = StringFormat("DELETE FROM T WHERE key='%s'", key);
    if (!DatabaseExecute(db, sql)) {
        PrintFormat("Error (%s, Delete): #%d", __FUNCTION__, GetLastError());
        DatabaseClose(db);
        while (!GlobalVariableDel("_DbLock"));
        return false;
    }
    DatabaseClose(db);
    while (!GlobalVariableDel("_DbLock"));

    return true;
}

//+------------------------------------------------------------------+
//| Deletes global variables with specified prefix in their names.   |
//+------------------------------------------------------------------+
bool StorageDeleteAll(string prefix = NULL, datetime time_limit = 0, ENUM_STORAGE_TIME time_mode = STORAGE_TIME_SYSTEM) {
    while (GlobalVariableCheck("_DbLock"));
    while (!GlobalVariableTemp("_DbLock"));

    if (prefix == NULL || prefix == "") {
        if (FileIsExist(STORAGE_DB_PATH, FILE_COMMON) && !FileDelete(STORAGE_DB_PATH, FILE_COMMON)) {
            PrintFormat("Error (%s, FileDelete): #%d", __FUNCTION__, GetLastError());
            while (!GlobalVariableDel("_DbLock"));
            return false;
        }
        while (!GlobalVariableDel("_DbLock"));
        return true;
    }

    int db = _storageInitDb(DATABASE_OPEN_READWRITE);
    if (db == INVALID_HANDLE) {
        while (!GlobalVariableDel("_DbLock"));
        return false;
    }

    string time_col = "time_system";
    if (time_mode == STORAGE_TIME_TRADESERVER)
        time_col = "time_server";

    string sql = StringFormat("DELETE FROM T WHERE key LIKE '%s%%'", prefix);
    if (time_limit != 0) sql += StringFormat(" AND %s <= %d", time_col, time_limit);
    if (!DatabaseExecute(db, sql)) {
        PrintFormat("Error (%s, Delete): #%d", __FUNCTION__, GetLastError());
        DatabaseClose(db);
        while (!GlobalVariableDel("_DbLock"));
        return false;
    }
    DatabaseClose(db);
    while (!GlobalVariableDel("_DbLock"));
    return true;
}

//+------------------------------------------------------------------+
//| Returns time of the last updating the global variable.           |
//+------------------------------------------------------------------+
datetime StorageLastUpdate(string key, ENUM_STORAGE_TIME time = STORAGE_TIME_SYSTEM) {
    while (GlobalVariableCheck("_DbLock"));
    while (!GlobalVariableTemp("_DbLock"));

    int db = _storageInitDb();
    if (db == INVALID_HANDLE) {
        while (!GlobalVariableDel("_DbLock"));
        return 0;
    }

    string time_col = "time_system";
    if (time == STORAGE_TIME_TRADESERVER)
        time_col = "time_server";

    datetime val = 0;
    string sql = StringFormat("SELECT %s FROM T WHERE key='%s' LIMIT 1", time_col, key);

    int dp = DatabasePrepare(db, sql);
    if (dp == INVALID_HANDLE) {
        PrintFormat("Error (%s, DatabasePrepare): #%d", __FUNCTION__, GetLastError());
        DatabaseClose(db);
        while (!GlobalVariableDel("_DbLock"));
        return val;
    }

    if (!DatabaseRead(dp) && GetLastError() != ERR_DATABASE_NO_MORE_DATA) {
        PrintFormat("Error (%s, DatabaseRead): #%d", __FUNCTION__, GetLastError());
    }

    if (!DatabaseColumnLong(dp, 0, val)) {
        PrintFormat("Error (%s, DatabaseColumnLong): #%d", __FUNCTION__, GetLastError());
    }

    DatabaseFinalize(dp);
    DatabaseClose(db);
    while (!GlobalVariableDel("_DbLock"));
    return val;
}

//+------------------------------------------------------------------+
//| Initialize the storage DB and return the handle.                 |
//+------------------------------------------------------------------+
int _storageInitDb(uint flags = DATABASE_OPEN_READONLY) {
    int db;
    string sql;
    string db_path = STORAGE_DB_PATH;

    if (!FileIsExist(db_path, FILE_COMMON))
        flags = DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE;

    flags |= DATABASE_OPEN_COMMON;
    db = DatabaseOpen(db_path, flags);
    if (db == INVALID_HANDLE) {
        PrintFormat("Error (%s, DatabaseOpen): #%d", __FUNCTION__, GetLastError());
        return INVALID_HANDLE;
    }

    if (!DatabaseTableExists(db, "T")) {
        sql = "CREATE TABLE T ("
              "key TEXT,"
              "value TEXT,"
              "time_system INT,"
              "time_server INT,"
              "PRIMARY KEY(key)"
              ");";

        if (!DatabaseExecute(db, sql)) {
            PrintFormat("Error (%s, CreateTable, T): #%d", __FUNCTION__, GetLastError());
            DatabaseClose(db);
            return INVALID_HANDLE;
        }
    }

    return db;
}

//+------------------------------------------------------------------+

//===== END Storage.mqh =====


#define COT_APP_TOKEN          ""
#define COT_DB_PATH            "Geraked\\cot.db"
#define COT_DB_CO_PATH         "Geraked\\cot-co.db"
#define COT_DIR_PATH           "Geraked\\cot\\"
#define COT_INIT_TIMEOUT_MINS  1

// Use major currencies only
#define COT_USE_CO      true
#define COT_CURRENCIES  "'232741','099741','096742','112741','090741','092741','097741','098662'"

enum ENUM_COT_REPORT {
    COT_REPORT_L = 1, // Legacy Futures Only Report
    COT_REPORT_LC, // Legacy Combined Report
    COT_REPORT_T, // TFF Futures Only Report
    COT_REPORT_TC, // TFF Combined Report
    COT_REPORT_D, // Disaggregated Futures Only Report
    COT_REPORT_DC, // Disaggregated Combined Report
    COT_REPORT_S // Supplemental Report
};

enum ENUM_COT_CLASS {
    COT_CLASS_COM = 1, // Commercial
    COT_CLASS_NCOM, // Non-Commercial
    COT_CLASS_NR, // Non-Reportables
    COT_CLASS_DEALER, // Dealer/Intermediary
    COT_CLASS_ASSET, // Asset Manager/Institutional
    COT_CLASS_LEV, // Leveraged Funds
    COT_CLASS_ORT, // Other Reportables (TFF)
    COT_CLASS_PM, // Producer/Merchant/Processor/User
    COT_CLASS_SD, // Swap Dealers
    COT_CLASS_MM, // Managed Money
    COT_CLASS_ORD, // Other Reportables (Disaggregated)
    COT_CLASS_IT // Index Traders
};

enum ENUM_COT_REPORT_CO {
    COT_REPORT_CO_L = 1, // Legacy Futures Only Report
    COT_REPORT_CO_LC, // Legacy Combined Report
    COT_REPORT_CO_T, // TFF Futures Only Report
    COT_REPORT_CO_TC // TFF Combined Report
};

enum ENUM_COT_CLASS_CO {
    COT_CLASS_CO_COM = 1, // Commercial
    COT_CLASS_CO_NCOM, // Non-Commercial
    COT_CLASS_CO_NR, // Non-Reportables
    COT_CLASS_CO_DEALER, // Dealer/Intermediary
    COT_CLASS_CO_ASSET, // Asset Manager/Institutional
    COT_CLASS_CO_LEV, // Leveraged Funds
    COT_CLASS_CO_ORT // Other Reportables
};

enum ENUM_COT_MODE {
    COT_MODE_COP, // Futures & Options Combined
    COT_MODE_FO // Futures Only
};

//+------------------------------------------------------------------+
//| Necessary to call in 'OnInit' function before using COT lib.     |
//+------------------------------------------------------------------+
bool CotInit(ENUM_COT_REPORT report_type, datetime start_date = 0, bool print_logs = true) {
    if (!IsWindows()) {
        Print("Error: The COT library can only be used on the Windows operating system.");
        return false;
    }

    if (MQLInfoInteger(MQL_OPTIMIZATION)) {
        Print("Error: The COT library cannot be used in optimization mode.");
        return false;
    }

    string rt = (string)((int) report_type);
    string k_running = "cot_init_running_" + rt;
    string k_year = "cot_init_year_" + rt;
    string k_status = "cot_init_status_" + rt;

    bool running, timeout;
    do {
        if (IsStopped()) return false;
        Sleep(500);
        running = ((bool) StorageGet(k_running, 0)) || ((bool) GlobalVariableGet(k_running));
        timeout = (TimeSystem() - StorageLastUpdate(k_running)) > 60 * COT_INIT_TIMEOUT_MINS;
    } while(running && !timeout);

    GlobalVariableSet(k_running, 1);
    StorageSet(k_running, 1);

    MqlDateTime oldbar_dts, stime_dts;
    datetime oldbar_dt;
    if (start_date == 0) {
        int bars = iBars(NULL, 0);
        if (bars < 1) {
            oldbar_dt = D'2011.01.01';
        } else {
            oldbar_dt = iTime(NULL, 0, bars - 1);
            if (oldbar_dt <= 0)
                oldbar_dt = D'2011.01.01';
        }
    } else {
        oldbar_dt = start_date;
    }
    TimeToStruct(oldbar_dt, oldbar_dts);
    datetime stime = TimeSystem(stime_dts);
    int start_year = MathMax(2011, oldbar_dts.year);
    int end_year = stime_dts.year;

    int year = StorageGet(k_year, end_year + 1);
    int status = StorageGet(k_status, 0);
    timeout = (TimeSystem() - StorageLastUpdate(k_status)) > 60 * COT_INIT_TIMEOUT_MINS;

    if (start_year >= year && !timeout && status > 0) {
        StorageSet(k_running, 0);
        GlobalVariableDel(k_running);
        if (status == 1)
            return true;
        else
            return false;
    }

    StorageSet(k_year, start_year);
    if (print_logs)
        PrintFormat("CotInit (%s) started...", rt);

    MqlDateTime t_dts;
    datetime date_from, date_to;
    datetime time = StringToTime(StringFormat("%d.01.01", start_year));
    CotGetDateRange(time, date_from, date_to);

    for (datetime t = date_from; t <= stime; t += 7 * PeriodSeconds(PERIOD_D1)) {
        if (IsStopped()) {
            StorageSet(k_status, 0);
            StorageSet(k_running, 0);
            GlobalVariableDel(k_running);
            return false;
        }

        if (!CotIsAvailable(report_type, t, true)) {
            if (stime - t <= 7 * PeriodSeconds(PERIOD_D1))
                continue;
            TimeToStruct(t, t_dts);
            if (t_dts.mon == 12 && t_dts.day > 19)
                continue;
            if (IsStopped()) {
                StorageSet(k_status, 0);
                StorageSet(k_running, 0);
                GlobalVariableDel(k_running);
                return false;
            }
            PrintFormat("CotInit (%s) failed: %s", rt, TimeToString(t, TIME_DATE));
            PrintFormat("Try again %d minutes later.", COT_INIT_TIMEOUT_MINS);
            StorageSet(k_status, 2);
            StorageSet(k_running, 0);
            GlobalVariableDel(k_running);
            return false;
        }
    }

    if (print_logs)
        PrintFormat("CotInit (%s) successfully ended.", rt);
    StorageSet(k_status, 1);
    StorageSet(k_running, 0);
    GlobalVariableDel(k_running);
    return true;
}

//+------------------------------------------------------------------+
//| Check if COT report is available in DB.                          |
//+------------------------------------------------------------------+
bool CotIsAvailable(ENUM_COT_REPORT report_type, datetime time = 0, bool force_retrieve = false) {
    if (time == 0) time = TimeCurrent();
    datetime date_from, date_to;
    MqlDateTime dts_from, dts_to;
    CotGetDateRange(time, date_from, date_to);
    TimeToStruct(date_from, dts_from);
    TimeToStruct(date_to, dts_to);

    int db, dp, t;
    string sql;
    string table = CotGetTableName(report_type);
    db = CotInitDb();
    if (db == INVALID_HANDLE) return false;

    sql = StringFormat("SELECT EXISTS (SELECT 1 FROM %s WHERE date >= %d AND date < %d AND rid=%d", table, date_from, date_to, report_type);
    if (COT_USE_CO) sql += StringFormat(" AND cid IN (%s)", COT_CURRENCIES);
    sql += " LIMIT 1)";
    dp = DatabasePrepare(db, sql);
    DatabaseRead(dp);
    DatabaseColumnInteger(dp, 0, t);
    DatabaseFinalize(dp);
    DatabaseClose(db);
    if (t) return true;

    if (!force_retrieve && MQLInfoInteger(MQL_TESTER))
        return false;

    if (!force_retrieve && !MQLInfoInteger(MQL_TESTER) && MathAbs(TimeSystem() - time) > 30 * PeriodSeconds(PERIOD_D1))
        return false;

    if (IsStopped()) return false;

    WininetRequest req;
    WininetResponse res;
    string date_from_str = TimeToString(date_from, TIME_DATE);
    string date_to_str = TimeToString(date_to, TIME_DATE);
    StringReplace(date_from_str, ".", "-");
    StringReplace(date_to_str, ".", "-");
    string query = StringFormat("SELECT 1 WHERE `report_date_as_yyyy_mm_dd` >= '%s' "
                                "AND `report_date_as_yyyy_mm_dd` < '%s'",
                                date_from_str, date_to_str);
    if (COT_USE_CO) query += StringFormat(" AND cftc_contract_market_code IN (%s)", COT_CURRENCIES);
    query += " LIMIT 1";
    req.host = "publicreporting.cftc.gov";
    req.path = "/resource/" + cotGetRequestId(report_type) + ".csv" + "?$query=" + query;
    if (COT_APP_TOKEN != "")
        req.headers = StringFormat("X-App-Token: %s\r\n", COT_APP_TOKEN);
    WebReq(req, res);
    if (res.status != 200) {
        PrintFormat("CotIsAvailable request failed! (status=%d, rt=%d, df=%s, dt=%s)", res.status, report_type, date_from_str, date_to_str);
        return false;
    }

    string ds[];
    string data = res.GetDataStr();
    StringTrimLeft(data);
    int n = StringSplit(data, '\n', ds);
    if (n < 2) return false;
    StringReplace(ds[1], "\"", "");
    StringReplace(ds[1], "'", "");
    StringTrimLeft(ds[1]);
    StringTrimRight(ds[1]);
    if (ds[1] != "1") return false;

    string fp1 = cotGetCsvFilePath(report_type, dts_from.year);
    string fp2 = cotGetCsvFilePath(report_type, dts_to.year);
    if (FileIsExist(fp1, FILE_COMMON)) {
        if (!FileDelete(fp1, FILE_COMMON)) {
            PrintFormat("Error (%s, FileDelete): #%d", __FUNCTION__, GetLastError());
            return false;
        }
    }
    if (!cotReadReport(report_type, dts_from.year))
        return false;
    if (fp1 != fp2) {
        if (FileIsExist(fp2, FILE_COMMON)) {
            if (!FileDelete(fp2, FILE_COMMON)) {
                PrintFormat("Error (%s, FileDelete): #%d", __FUNCTION__, GetLastError());
                return false;
            }
        }
        if (!cotReadReport(report_type, dts_to.year))
            return false;
    }

    if (IsStopped()) return false;

    db = CotInitDb();
    if (db == INVALID_HANDLE) return false;

    dp = DatabasePrepare(db, sql);
    DatabaseRead(dp);
    DatabaseColumnInteger(dp, 0, t);
    DatabaseFinalize(dp);
    DatabaseClose(db);
    if (!t) {
        PrintFormat("Warning: COT is not available! (rt=%d, df=%s, dt=%s)", report_type, date_from_str, date_to_str);
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Find the correct date range for COT.                             |
//+------------------------------------------------------------------+
void CotGetDateRange(datetime time, datetime &date_from, datetime &date_to) {
    MqlDateTime dts;
    datetime date = StringToTime(TimeToString(time, TIME_DATE));
    TimeToStruct(date, dts);
    int dow = dts.day_of_week;
    if (dow == 6) {
        dow = 0;
        date += PeriodSeconds(PERIOD_D1);
    }
    date_to = date - dow * PeriodSeconds(PERIOD_D1); // Last Sunday
    date_to -= 3 * PeriodSeconds(PERIOD_D1); // Last Thursday
    date_from = date_to - 3 * PeriodSeconds(PERIOD_D1); // 2nd Last Monday
}

//+------------------------------------------------------------------+
//| Fetch the COT report from the csv file and insert into the DB.   |
//+------------------------------------------------------------------+
bool cotReadReport(ENUM_COT_REPORT report_type, int year) {
    string file_path = cotGetCsvFilePath(report_type, year);
    if (!FileIsExist(file_path, FILE_COMMON))
        if (!cotDownloadReport(report_type, year))
            return false;

    string ccols[], ccols_str;
    string cols[], cols_str;
    string table = CotGetTableName(report_type);
    ccols_str = cotGetTableColumns("contract", ccols);
    cols_str = cotGetTableColumns(table, cols);
    if (ccols_str == NULL || cols_str == NULL)
        return false;

    int fh = FileOpen(file_path, FILE_READ | FILE_SHARE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON, CP_UTF8);
    if (fh == INVALID_HANDLE) {
        PrintFormat("Error (%s, FileOpen): #%d", __FUNCTION__, GetLastError());
        return false;
    }

    int cmap[], map[];
    string fcols[];
    string head =  FileReadString(fh);
    StringReplace(head, "__", "_");
    cotSplitCsvRecord(head, fcols);
    cotMapFcolsToDbcols(fcols, ccols, cmap);
    cotMapFcolsToDbcols(fcols, cols, map);

    int db, dp, t;
    string sql;
    db = CotInitDb(DATABASE_OPEN_READWRITE);
    if (db == INVALID_HANDLE) return false;

    if (!DatabaseTransactionBegin(db)) {
        PrintFormat("Error (%s, DatabaseTransactionBegin): #%d", __FUNCTION__, GetLastError());
        DatabaseClose(db);
        FileClose(fh);
        return false;
    }

    string r[];
    int n, m;
    string values;
    datetime date;
    int fo = CotIsFuturesOnly(report_type);
    while (!FileIsEnding(fh)) {
        if (IsStopped()) {
            PrintFormat("%s (loop: file) stopped!", __FUNCTION__);
            DatabaseTransactionRollback(db);
            DatabaseClose(db);
            FileClose(fh);
            return false;
        }

        m = cotSplitCsvRecord(FileReadString(fh), r);
        if (m <= 0) continue;

        sql = StringFormat("SELECT EXISTS (SELECT 1 FROM contract WHERE id='%s' LIMIT 1)", r[cmap[0]]);
        dp = DatabasePrepare(db, sql);
        DatabaseRead(dp);
        DatabaseColumnInteger(dp, 0, t);
        DatabaseFinalize(dp);

        if (!t) {
            values = "";
            n = ArraySize(cmap);
            for (int i = 0; i < n; i++) {
                if (StringLen(values) > 0)
                    StringAdd(values, ",");
                if (cmap[i] == -1)
                    StringAdd(values, "NULL");
                else
                    StringAdd(values, StringFormat("'%s'", r[cmap[i]]));
            }
            sql = StringFormat("INSERT INTO contract(%s) VALUES(%s)", ccols_str, values);
        } else {
            values = "";
            n = ArraySize(cmap);
            for (int i = 0; i < n; i++) {
                if (cmap[i] == -1)
                    continue;
                if (StringLen(values) > 0)
                    StringAdd(values, ",");
                StringAdd(values, StringFormat("%s='%s'", ccols[i], r[cmap[i]]));
            }
            sql = StringFormat("UPDATE contract SET %s WHERE id='%s' AND contract_market_name IS NULL", values, r[cmap[0]]);
        }

        if (!DatabaseExecute(db, sql)) {
            PrintFormat("Error (%s, Insert, contract): #%d", __FUNCTION__, GetLastError());
            DatabaseTransactionRollback(db);
            DatabaseClose(db);
            FileClose(fh);
            return false;
        }

        date = StringToTime(r[map[0]]);
        sql = StringFormat("SELECT EXISTS (SELECT 1 FROM %s WHERE date=%d AND rid=%d AND cid='%s' LIMIT 1)", table, date, report_type, r[map[2]]);
        dp = DatabasePrepare(db, sql);
        DatabaseRead(dp);
        DatabaseColumnInteger(dp, 0, t);
        DatabaseFinalize(dp);

        if (!t) {
            values = "";
            n = ArraySize(map);
            for (int i = 0; i < n; i++) {
                if (StringLen(values) > 0)
                    StringAdd(values, ",");
                if (cols[i] == "date")
                    StringAdd(values, StringFormat("%d", date));
                else if (cols[i] == "rid")
                    StringAdd(values, StringFormat("%d", report_type));
                else if (cols[i] == "cid")
                    StringAdd(values, StringFormat("'%s'", r[map[i]]));
                else if (cols[i] == "fo")
                    StringAdd(values, StringFormat("%d", fo));
                else if (map[i] == -1)
                    StringAdd(values, "NULL");
                else
                    StringAdd(values, StringFormat("%s", r[map[i]]));
            }
            sql = StringFormat("INSERT INTO %s(%s) VALUES(%s)", table, cols_str, values);
            if (!DatabaseExecute(db, sql)) {
                PrintFormat("Error (%s, Insert, %s): #%d", __FUNCTION__, table, GetLastError());
                DatabaseTransactionRollback(db);
                DatabaseClose(db);
                FileClose(fh);
                return false;
            }
        }
    }

    if (!DatabaseTransactionCommit(db)) {
        PrintFormat("Error (%s, DatabaseTransactionCommit): #%d", __FUNCTION__, GetLastError());
        DatabaseTransactionRollback(db);
        DatabaseClose(db);
        FileClose(fh);
        return false;
    }

    DatabaseClose(db);
    FileClose(fh);
    if (FileIsExist(file_path, FILE_COMMON))
        FileDelete(file_path, FILE_COMMON);

    return true;
}

//+------------------------------------------------------------------+
//| Download the COT report and save it as a csv file.               |
//+------------------------------------------------------------------+
bool cotDownloadReport(ENUM_COT_REPORT report_type, int year) {
    if (year < 2010) {
        Print("Downloading COT report older than year 2010 is not allowed!");
        return false;
    }

    MqlDateTime dts;
    TimeSystem(dts);
    if (year > dts.year) {
        Print("Downloading COT report for future years is not possible!");
        return false;
    }

    string file_name = cotGetCsvFileName(report_type, year);
    string file_path = cotGetCsvFilePath(report_type, year);

    if (FileIsExist(file_path, FILE_COMMON))
        return true;

    WininetRequest req;
    WininetResponse res;

    string query = StringFormat("SELECT * WHERE `report_date_as_yyyy_mm_dd` >= '%d-01-01' "
                                "AND `report_date_as_yyyy_mm_dd` < '%d-01-01'",
                                year, year + 1
                               );
    if (COT_USE_CO)
        query += StringFormat(" AND `cftc_contract_market_code` IN (%s)", COT_CURRENCIES);
    query += " ORDER BY `report_date_as_yyyy_mm_dd` DESC LIMIT 100000";

    req.host = "publicreporting.cftc.gov";
    req.path = "/resource/" + cotGetRequestId(report_type) + ".csv" + "?$query=" + query;
    if (COT_APP_TOKEN != "")
        req.headers = StringFormat("X-App-Token: %s\r\n", COT_APP_TOKEN);

    PrintFormat("Downloading '%s' file...", file_name);
    WebReq(req, res);
    if (res.status != 200) {
        PrintFormat("Downloading '%s' failed! (status=%d)", file_name, res.status);
        return false;
    }
    if (FileIsExist(file_path, FILE_COMMON))
        return true;
    PrintFormat("The file '%s' has been successfully downloaded. (%d bytes)", file_name, ArraySize(res.data));

    int file_handle = FileOpen(file_path, FILE_WRITE | FILE_BIN | FILE_COMMON);
    if (file_handle == INVALID_HANDLE) {
        PrintFormat("Error (%s, FileOpen): #%d", __FUNCTION__, GetLastError());
        return false;
    }
    if (!FileWriteArray(file_handle, res.data)) {
        PrintFormat("Error (%s, FileWriteArray): #%d", __FUNCTION__, ERR_FILE_WRITEERROR);
        FileClose(file_handle);
        FileDelete(file_path, FILE_COMMON);
        return false;
    }
    FileClose(file_handle);

    return true;
}

//+------------------------------------------------------------------+
//| Get column names of the table.                                   |
//+------------------------------------------------------------------+
string cotGetTableColumns(string table, string &arr[]) {
    string columns, col;
    int db, dp;
    string sql;
    int n;

    db = CotInitDb();
    if (db == INVALID_HANDLE) return NULL;

    sql = StringFormat("SELECT name FROM PRAGMA_TABLE_INFO('%s')", table);
    dp = DatabasePrepare(db, sql);
    if (dp == INVALID_HANDLE) {
        PrintFormat("Error (%s, DatabasePrepare): #%d", __FUNCTION__, GetLastError());
        DatabaseClose(db);
        return NULL;
    }

    columns = "";
    while (DatabaseRead(dp) && !IsStopped()) {
        if (!DatabaseColumnText(dp, 0, col)) {
            PrintFormat("Error (%s, DatabaseColumnText): #%d", __FUNCTION__, GetLastError());
            DatabaseFinalize(dp);
            DatabaseClose(db);
            return NULL;
        }
        n = ArraySize(arr);
        ArrayResize(arr, n + 1);
        arr[n] = col;
        if (StringLen(columns) > 0)
            StringAdd(columns, ",");
        StringAdd(columns, col);
    }

    DatabaseFinalize(dp);
    DatabaseClose(db);
    return columns;
}

//+------------------------------------------------------------------+
//| Map the csv file columns to the DB table columns.                |
//+------------------------------------------------------------------+
void cotMapFcolsToDbcols(const string &fcols[], const string &dbcols[], int &map[]) {
    int n = ArraySize(dbcols);
    ArrayResize(map, n);
    for (int i = 0; i < n; i++) {
        if (dbcols[i] == "id" || dbcols[i] == "cid")
            map[i] = ArraySearch(fcols, "cftc_contract_market_code", false);
        else if (dbcols[i] == "date")
            map[i] = ArraySearch(fcols, "report_date_as_yyyy_mm_dd", false);
        else
            map[i] = ArraySearch(fcols, dbcols[i], false);
    }
}

//+------------------------------------------------------------------+
//| Fetch values from the csv record.                                |
//+------------------------------------------------------------------+
int cotSplitCsvRecord(const string record, string &arr[]) {
    string rec = record;
    StringReplace(rec, "\",", "¡");
    while(StringReplace(rec, "¡,", "¡ ¡") > 0);
    int n = StringSplit(rec, '¡', arr);
    if (n == -1) {
        PrintFormat("Error (%s, StringSplit): #%d", __FUNCTION__, GetLastError());
        return -1;
    }
    for (int i = 0; i < n; i++) {
        StringReplace(arr[i], "\"", "");
        StringReplace(arr[i], "'", "''");
        StringTrimLeft(arr[i]);
        StringTrimRight(arr[i]);
        if (arr[i] == "")
            arr[i] = "NULL";
    }
    return n;
}

//+------------------------------------------------------------------+
//| Get the csv file name containing the COT report.                 |
//+------------------------------------------------------------------+
string cotGetCsvFileName(ENUM_COT_REPORT report_type, int year) {
    string file_name = IntegerToString(report_type) + "-" + IntegerToString(year);
    if (COT_USE_CO)
        file_name += "-co";
    file_name += ".csv";
    return file_name;
}

//+------------------------------------------------------------------+
//| Get the csv file path containing the COT report.                 |
//+------------------------------------------------------------------+
string cotGetCsvFilePath(ENUM_COT_REPORT report_type, int year) {
    string file_name = cotGetCsvFileName(report_type, year);
    string file_path = COT_DIR_PATH + file_name;
    return file_path;
}

//+------------------------------------------------------------------+
//| Initialize the COT DB and return the handle.                     |
//+------------------------------------------------------------------+
int CotInitDb(uint flags = DATABASE_OPEN_READONLY) {
    int db;
    string sql;
    string db_path = COT_USE_CO ? COT_DB_CO_PATH : COT_DB_PATH;

    if (!FileIsExist(db_path, FILE_COMMON))
        flags = DATABASE_OPEN_READWRITE | DATABASE_OPEN_CREATE;

    flags |= DATABASE_OPEN_COMMON;
    db = DatabaseOpen(db_path, flags);
    if (db == INVALID_HANDLE) {
        PrintFormat("Error (%s, DatabaseOpen): #%d", __FUNCTION__, GetLastError());
        return INVALID_HANDLE;
    }

    if (!DatabaseTableExists(db, "contract")) {
        sql = "CREATE TABLE contract ("
              "id TEXT,"
              "name TEXT,"
              "market_and_exchange_names TEXT,"
              "contract_market_name TEXT,"
              "cftc_market_code TEXT,"
              "cftc_region_code TEXT,"
              "cftc_commodity_code TEXT,"
              "commodity_name TEXT,"
              "contract_units TEXT,"
              "commodity TEXT,"
              "commodity_subgroup_name TEXT,"
              "commodity_group_name TEXT,"
              "cftc_subgroup_code TEXT,"
              "PRIMARY KEY(id)"
              ");";

        sql += "INSERT INTO contract(id, name) "
               "VALUES "
               "('232741', 'AUD'),"
               "('099741', 'EUR'),"
               "('096742', 'GBP'),"
               "('112741', 'NZD'),"
               "('090741', 'CAD'),"
               "('092741', 'CHF'),"
               "('097741', 'JPY'),"
               "('098662', 'USD')";

        sql += ","
               "('122741', 'ZAR'),"
               "('095741', 'MXN'),"
               "('089741', 'RUB'),"
               "('102741', 'RBL'),"
               "('088691', 'XAU'),"
               "('084691', 'XAG'),"
               "('133741', 'BTC'),"
               "('146021', 'ETH')";

        sql += ";";

        if (!DatabaseExecute(db, sql)) {
            PrintFormat("Error (%s, CreateTable, contract): #%d", __FUNCTION__, GetLastError());
            DatabaseClose(db);
            return INVALID_HANDLE;
        }
    }

    if (!DatabaseTableExists(db, "L")) {
        sql = "CREATE TABLE L ("
              "date INT, rid INT, cid TEXT, fo INT,"

              "open_interest_all INT, noncomm_positions_long_all INT, noncomm_positions_short_all INT, noncomm_postions_spread_all INT,"
              "comm_positions_long_all INT, comm_positions_short_all INT, tot_rept_positions_long_all INT, tot_rept_positions_short INT,"
              "nonrept_positions_long_all INT, nonrept_positions_short_all INT, open_interest_old INT, noncomm_positions_long_old INT,"
              "noncomm_positions_short_old INT, noncomm_positions_spread INT, comm_positions_long_old INT, comm_positions_short_old INT,"
              "tot_rept_positions_long_old INT, tot_rept_positions_short_1 INT, nonrept_positions_long_old INT, nonrept_positions_short_old INT,"
              "open_interest_other INT, noncomm_positions_long_other INT, noncomm_positions_short_other INT, noncomm_positions_spread_1 INT,"
              "comm_positions_long_other INT, comm_positions_short_other INT, tot_rept_positions_long_other INT, tot_rept_positions_short_2 INT,"
              "nonrept_positions_long_other INT, nonrept_positions_short_other INT, change_in_open_interest_all INT, change_in_noncomm_long_all INT,"
              "change_in_noncomm_short_all INT, change_in_noncomm_spead_all INT, change_in_comm_long_all INT, change_in_comm_short_all INT,"
              "change_in_tot_rept_long_all INT, change_in_tot_rept_short INT, change_in_nonrept_long_all INT, change_in_nonrept_short_all INT,"
              "pct_of_open_interest_all REAL, pct_of_oi_noncomm_long_all REAL, pct_of_oi_noncomm_short_all REAL, pct_of_oi_noncomm_spread REAL,"
              "pct_of_oi_comm_long_all REAL, pct_of_oi_comm_short_all REAL, pct_of_oi_tot_rept_long_all REAL, pct_of_oi_tot_rept_short REAL,"
              "pct_of_oi_nonrept_long_all REAL, pct_of_oi_nonrept_short_all REAL, pct_of_open_interest_old REAL, pct_of_oi_noncomm_long_old REAL,"
              "pct_of_oi_noncomm_short_old REAL, pct_of_oi_noncomm_spread_1 REAL, pct_of_oi_comm_long_old REAL, pct_of_oi_comm_short_old REAL,"
              "pct_of_oi_tot_rept_long_old REAL, pct_of_oi_tot_rept_short_1 REAL, pct_of_oi_nonrept_long_old REAL, pct_of_oi_nonrept_short_old REAL,"
              "pct_of_open_interest_other REAL, pct_of_oi_noncomm_long_other REAL, pct_of_oi_noncomm_short_other REAL, pct_of_oi_noncomm_spread_2 REAL,"
              "pct_of_oi_comm_long_other REAL, pct_of_oi_comm_short_other REAL, pct_of_oi_tot_rept_long_other REAL, pct_of_oi_tot_rept_short_2 REAL,"
              "pct_of_oi_nonrept_long_other REAL, pct_of_oi_nonrept_short_other REAL, traders_tot_all INT, traders_noncomm_long_all INT,"
              "traders_noncomm_short_all INT, traders_noncomm_spread_all INT, traders_comm_long_all INT, traders_comm_short_all INT,"
              "traders_tot_rept_long_all INT, traders_tot_rept_short_all INT, traders_tot_old INT, traders_noncomm_long_old INT,"
              "traders_noncomm_short_old INT, traders_noncomm_spead_old INT, traders_comm_long_old INT, traders_comm_short_old INT, traders_tot_rept_long_old INT,"
              "traders_tot_rept_short_old INT, traders_tot_other INT, traders_noncomm_long_other INT, traders_noncomm_short_other INT, traders_noncomm_spread_other INT,"
              "traders_comm_long_other INT, traders_comm_short_other INT, traders_tot_rept_long_other INT, traders_tot_rept_short_other INT,"
              "conc_gross_le_4_tdr_long REAL, conc_gross_le_4_tdr_short REAL, conc_gross_le_8_tdr_long REAL, conc_gross_le_8_tdr_short REAL, conc_net_le_4_tdr_long_all REAL,"
              "conc_net_le_4_tdr_short_all REAL, conc_net_le_8_tdr_long_all REAL, conc_net_le_8_tdr_short_all REAL, conc_gross_le_4_tdr_long_1 REAL,"
              "conc_gross_le_4_tdr_short_1 REAL, conc_gross_le_8_tdr_long_1 REAL, conc_gross_le_8_tdr_short_1 REAL, conc_net_le_4_tdr_long_old REAL,"
              "conc_net_le_4_tdr_short_old REAL, conc_net_le_8_tdr_long_old REAL, conc_net_le_8_tdr_short_old REAL, conc_gross_le_4_tdr_long_2 REAL,"
              "conc_gross_le_4_tdr_short_2 REAL, conc_gross_le_8_tdr_long_2 REAL, conc_gross_le_8_tdr_short_2 REAL, conc_net_le_4_tdr_long_other REAL,"
              "conc_net_le_4_tdr_short_other REAL, conc_net_le_8_tdr_long_other REAL, conc_net_le_8_tdr_short_other REAL,"

              "FOREIGN KEY(cid) REFERENCES contract(id),"
              "PRIMARY KEY(date, rid, cid)"
              ");"

              "CREATE INDEX idx_L_1 ON L(date);"
              ;

        if (!DatabaseExecute(db, sql)) {
            PrintFormat("Error (%s, CreateTable, L): #%d", __FUNCTION__, GetLastError());
            DatabaseClose(db);
            return INVALID_HANDLE;
        }
    }

    if (!DatabaseTableExists(db, "T")) {
        sql = "CREATE TABLE T ("
              "date INT, rid INT, cid TEXT, fo INT,"

              "open_interest_all INT, dealer_positions_long_all INT, dealer_positions_short_all INT, dealer_positions_spread_all INT,"
              "asset_mgr_positions_long INT, asset_mgr_positions_short INT, asset_mgr_positions_spread INT,"
              "lev_money_positions_long INT, lev_money_positions_short INT, lev_money_positions_spread INT,"
              "other_rept_positions_long INT, other_rept_positions_short INT, other_rept_positions_spread INT,"
              "tot_rept_positions_long_all INT, tot_rept_positions_short INT, nonrept_positions_long_all INT, nonrept_positions_short_all INT,"
              "change_in_open_interest_all INT, change_in_dealer_long_all INT, change_in_dealer_short_all INT, change_in_dealer_spread_all INT,"
              "change_in_asset_mgr_long INT, change_in_asset_mgr_short INT, change_in_asset_mgr_spread INT,"
              "change_in_lev_money_long INT, change_in_lev_money_short INT, change_in_lev_money_spread INT,"
              "change_in_other_rept_long INT, change_in_other_rept_short INT, change_in_other_rept_spread INT,"
              "change_in_tot_rept_long_all INT, change_in_tot_rept_short INT, change_in_nonrept_long_all INT, change_in_nonrept_short_all INT,"
              "pct_of_open_interest_all REAL, pct_of_oi_dealer_long_all REAL, pct_of_oi_dealer_short_all REAL, pct_of_oi_dealer_spread_all REAL,"
              "pct_of_oi_asset_mgr_long REAL, pct_of_oi_asset_mgr_short REAL, pct_of_oi_asset_mgr_spread REAL,"
              "pct_of_oi_lev_money_long REAL, pct_of_oi_lev_money_short REAL, pct_of_oi_lev_money_spread REAL,"
              "pct_of_oi_other_rept_long REAL, pct_of_oi_other_rept_short REAL, pct_of_oi_other_rept_spread REAL,"
              "pct_of_oi_tot_rept_long_all REAL, pct_of_oi_tot_rept_short REAL, pct_of_oi_nonrept_long_all REAL, pct_of_oi_nonrept_short_all REAL,"
              "traders_tot_all INT, traders_dealer_long_all INT, traders_dealer_short_all INT, traders_dealer_spread_all INT,"
              "traders_asset_mgr_long_all INT, traders_asset_mgr_short_all INT, traders_asset_mgr_spread INT,"
              "traders_lev_money_long_all INT, traders_lev_money_short_all INT, traders_lev_money_spread INT,"
              "traders_other_rept_long_all INT, traders_other_rept_short INT, traders_other_rept_spread INT,"
              "traders_tot_rept_long_all INT, traders_tot_rept_short_all INT,"
              "conc_gross_le_4_tdr_long REAL, conc_gross_le_4_tdr_short REAL, conc_gross_le_8_tdr_long REAL, conc_gross_le_8_tdr_short REAL,"
              "conc_net_le_4_tdr_long_all REAL, conc_net_le_4_tdr_short_all REAL, conc_net_le_8_tdr_long_all REAL, conc_net_le_8_tdr_short_all REAL,"

              "FOREIGN KEY(cid) REFERENCES contract(id),"
              "PRIMARY KEY(date, rid, cid)"
              ");"

              "CREATE INDEX idx_T_1 ON T(date);"
              ;

        if (!DatabaseExecute(db, sql)) {
            PrintFormat("Error (%s, CreateTable, T): #%d", __FUNCTION__, GetLastError());
            DatabaseClose(db);
            return INVALID_HANDLE;
        }
    }

    if (!DatabaseTableExists(db, "D")) {
        sql = "CREATE TABLE D ("
              "date INT, rid INT, cid TEXT, fo INT,"

              "open_interest_all INT, prod_merc_positions_long INT, prod_merc_positions_short INT,"
              "swap_positions_long_all INT, swap_positions_short_all INT, swap_positions_spread_all INT,"
              "m_money_positions_long_all INT, m_money_positions_short_all INT, m_money_positions_spread INT,"
              "other_rept_positions_long INT, other_rept_positions_short INT, other_rept_positions_spread INT,"
              "tot_rept_positions_long_all INT, tot_rept_positions_short INT, nonrept_positions_long_all INT, nonrept_positions_short_all INT,"
              "open_interest_old INT, prod_merc_positions_long_1 INT, prod_merc_positions_short_1 INT,"
              "swap_positions_long_old INT, swap_positions_short_old INT, swap_positions_spread_old INT,"
              "m_money_positions_long_old INT, m_money_positions_short_old INT, m_money_positions_spread_1 INT,"
              "other_rept_positions_long_1 INT, other_rept_positions_short_1 INT, other_rept_positions_spread_1 INT,"
              "tot_rept_positions_long_old INT, tot_rept_positions_short_1 INT, nonrept_positions_long_old INT, nonrept_positions_short_old INT,"
              "open_interest_other INT, prod_merc_positions_long_2 INT, prod_merc_positions_short_2 INT,"
              "swap_positions_long_other INT, swap_positions_short_other INT, swap_positions_spread_other INT,"
              "m_money_positions_long_other INT, m_money_positions_short_other INT, m_money_positions_spread_2 INT,"
              "other_rept_positions_long_2 INT, other_rept_positions_short_2 INT, other_rept_positions_spread_2 INT,"
              "tot_rept_positions_long_other INT, tot_rept_positions_short_2 INT, nonrept_positions_long_other INT, nonrept_positions_short_other INT,"
              "change_in_open_interest_all INT, change_in_prod_merc_long INT, change_in_prod_merc_short INT,"
              "change_in_swap_long_all INT, change_in_swap_short_all INT, change_in_swap_spread_all INT,"
              "change_in_m_money_long_all INT, change_in_m_money_short_all INT, change_in_m_money_spread INT,"
              "change_in_other_rept_long INT, change_in_other_rept_short INT, change_in_other_rept_spread INT,"
              "change_in_tot_rept_long_all INT, change_in_tot_rept_short INT, change_in_nonrept_long_all INT, change_in_nonrept_short_all INT,"
              "pct_of_open_interest_all REAL, pct_of_oi_prod_merc_long REAL, pct_of_oi_prod_merc_short REAL,"
              "pct_of_oi_swap_long_all REAL, pct_of_oi_swap_short_all REAL, pct_of_oi_swap_spread_all REAL,"
              "pct_of_oi_m_money_long_all REAL, pct_of_oi_m_money_short_all REAL, pct_of_oi_m_money_spread REAL,"
              "pct_of_oi_other_rept_long REAL, pct_of_oi_other_rept_short REAL, pct_of_oi_other_rept_spread REAL,"
              "pct_of_oi_tot_rept_long_all REAL, pct_of_oi_tot_rept_short REAL, pct_of_oi_nonrept_long_all REAL, pct_of_oi_nonrept_short_all REAL,"
              "pct_of_open_interest_old REAL, pct_of_oi_prod_merc_long_1 REAL, pct_of_oi_prod_merc_short_1 REAL,"
              "pct_of_oi_swap_long_old REAL, pct_of_oi_swap_short_old REAL, pct_of_oi_swap_spread_old REAL,"
              "pct_of_oi_m_money_long_old REAL, pct_of_oi_m_money_short_old REAL, pct_of_oi_m_money_spread_1 REAL,"
              "pct_of_oi_other_rept_long_1 REAL, pct_of_oi_other_rept_short_1 REAL, pct_of_oi_other_rept_spread_1 REAL,"
              "pct_of_oi_tot_rept_long_old REAL, pct_of_oi_tot_rept_short_1 REAL, pct_of_oi_nonrept_long_old REAL, pct_of_oi_nonrept_short_old REAL,"
              "pct_of_open_interest_other REAL, pct_of_oi_prod_merc_long_2 REAL, pct_of_oi_prod_merc_short_2 REAL,"
              "pct_of_oi_swap_long_other REAL, pct_of_oi_swap_short_other REAL, pct_of_oi_swap_spread_other REAL,"
              "pct_of_oi_m_money_long_other REAL, pct_of_oi_m_money_short_other REAL, pct_of_oi_m_money_spread_2 REAL,"
              "pct_of_oi_other_rept_long_2 REAL, pct_of_oi_other_rept_short_2 REAL, pct_of_oi_other_rept_spread_2 REAL,"
              "pct_of_oi_tot_rept_long_other REAL, pct_of_oi_tot_rept_short_2 REAL, pct_of_oi_nonrept_long_other REAL, pct_of_oi_nonrept_short_other REAL,"
              "traders_tot_all INT, traders_prod_merc_long_all INT, traders_prod_merc_short_all INT,"
              "traders_swap_long_all INT, traders_swap_short_all INT, traders_swap_spread_all INT,"
              "traders_m_money_long_all INT, traders_m_money_short_all INT, traders_m_money_spread_all INT,"
              "traders_other_rept_long_all INT, traders_other_rept_short INT, traders_other_rept_spread INT,"
              "traders_tot_rept_long_all INT, traders_tot_rept_short_all INT, traders_tot_old INT, traders_prod_merc_long_old INT, traders_prod_merc_short_old INT,"
              "traders_swap_long_old INT, traders_swap_short_old INT, traders_swap_spread_old INT,"
              "traders_m_money_long_old INT, traders_m_money_short_old INT, traders_m_money_spread_old INT,"
              "traders_other_rept_long_old INT, traders_other_rept_short_1 INT, traders_other_rept_spread_1 INT,"
              "traders_tot_rept_long_old INT, traders_tot_rept_short_old INT, traders_tot_other INT, traders_prod_merc_long_other INT, traders_prod_merc_short_other INT,"
              "traders_swap_long_other INT, traders_swap_short_other INT, traders_swap_spread_other INT,"
              "traders_m_money_long_other INT, traders_m_money_short_other INT, traders_m_money_spread_other INT,"
              "traders_other_rept_long_other INT, traders_other_rept_short_2 INT, traders_other_rept_spread_2 INT, traders_tot_rept_long_other INT, traders_tot_rept_short_other INT,"
              "conc_gross_le_4_tdr_long REAL, conc_gross_le_4_tdr_short REAL, conc_gross_le_8_tdr_long REAL, conc_gross_le_8_tdr_short REAL,"
              "conc_net_le_4_tdr_long_all REAL, conc_net_le_4_tdr_short_all REAL, conc_net_le_8_tdr_long_all REAL, conc_net_le_8_tdr_short_all REAL,"
              "conc_gross_le_4_tdr_long_1 REAL, conc_gross_le_4_tdr_short_1 REAL, conc_gross_le_8_tdr_long_1 REAL,"
              "conc_gross_le_8_tdr_short_1 REAL, conc_net_le_4_tdr_long_old REAL, conc_net_le_4_tdr_short_old REAL, conc_net_le_8_tdr_long_old REAL, conc_net_le_8_tdr_short_old REAL,"
              "conc_gross_le_4_tdr_long_2 REAL, conc_gross_le_4_tdr_short_2 REAL, conc_gross_le_8_tdr_long_2 REAL, conc_gross_le_8_tdr_short_2 REAL,"
              "conc_net_le_4_tdr_long_other REAL, conc_net_le_4_tdr_short_other REAL, conc_net_le_8_tdr_long_other REAL, conc_net_le_8_tdr_short_other REAL,"

              "FOREIGN KEY(cid) REFERENCES contract(id),"
              "PRIMARY KEY(date, rid, cid)"
              ");"

              "CREATE INDEX idx_D_1 ON D(date);"
              ;

        if (!DatabaseExecute(db, sql)) {
            PrintFormat("Error (%s, CreateTable, D): #%d", __FUNCTION__, GetLastError());
            DatabaseClose(db);
            return INVALID_HANDLE;
        }
    }

    if (!DatabaseTableExists(db, "S")) {
        sql = "CREATE TABLE S ("
              "date INT, rid INT, cid TEXT, fo INT,"

              "open_interest_all INT, ncomm_postions_long_all_nocit INT, ncomm_postions_short_all_nocit INT, ncomm_postions_spread_all_nocit INT,"
              "comm_positions_long_all_nocit INT, comm_positions_short_all_nocit INT,"
              "tot_rept_positions_long_all INT, tot_rept_positions_short INT, nonrept_positions_long_all INT, nonrept_positions_short_all INT,"
              "cit_positions_long_all INT, cit_positions_short_all INT,"
              "change_open_interest_all INT, change_noncomm_long_all_nocit INT, change_noncomm_short_all_nocit INT, change_noncomm_spead_all_nocit INT,"
              "change_comm_long_all_nocit INT, change_comm_short_all_nocit INT, change_tot_rept_long_all INT, change_tot_rept_short_all INT,"
              "change_nonrept_long_all INT, change_nonrept_short_all INT, change_cit_long_all INT, change_cit_short_all INT,"
              "pct_open_interest_all REAL, pct_oi_noncomm_long_all_nocit REAL, pct_oi_noncomm_short_all_nocit REAL, pct_oi_noncomm_spread_all_nocit REAL,"
              "pct_oi_comm_long_all_nocit REAL, pct_oi_comm_short_all_nocit REAL, pct_oi_tot_rept_long_all_nocit REAL, pct_oi_tot_rept_short_all_nocit REAL,"
              "pct_oi_nonrept_long_all_nocit REAL, pct_oi_nonrept_short_all_nocit REAL, pct_oi_cit_long_all REAL, pct_oi_cit_short_all REAL,"
              "traders_tot_all INT, traders_noncomm_long_all_nocit INT, traders_noncomm_short_all_nocit INT, traders_noncomm_spread_all_nocit INT,"
              "traders_comm_long_all_nocit INT, traders_comm_short_all_nocit INT, traders_tot_rept_long_all_nocit INT,"
              "traders_tot_rept_short_all_nocit INT, traders_cit_long_all INT, traders_cit_short_all INT,"

              "FOREIGN KEY(cid) REFERENCES contract(id),"
              "PRIMARY KEY(date, rid, cid)"
              ");"

              "CREATE INDEX idx_S_1 ON S(date);"
              ;

        if (!DatabaseExecute(db, sql)) {
            PrintFormat("Error (%s, CreateTable, S): #%d", __FUNCTION__, GetLastError());
            DatabaseClose(db);
            return INVALID_HANDLE;
        }
    }

    return db;
}

//+------------------------------------------------------------------+
//| Retrieve the URL id associated with the COT report.              |
//+------------------------------------------------------------------+
string cotGetRequestId(ENUM_COT_REPORT report_type) {
    string rid;
    switch(report_type) {
    case COT_REPORT_L:
        rid = "6dca-aqww";
        break;
    case COT_REPORT_LC:
        rid = "jun7-fc8e";
        break;
    case COT_REPORT_T:
        rid = "gpe5-46if";
        break;
    case COT_REPORT_TC:
        rid = "yw9f-hn96";
        break;
    case COT_REPORT_D:
        rid = "72hh-3qpy";
        break;
    case COT_REPORT_DC:
        rid = "kh3c-gbw2";
        break;
    case COT_REPORT_S:
        rid = "4zgm-a668";
        break;
    }
    return rid;
}

//+------------------------------------------------------------------+
//| Retrieve the name of the DB table associated with the COT report.|
//+------------------------------------------------------------------+
string CotGetTableName(ENUM_COT_REPORT report_type) {
    string table;
    switch(report_type) {
    case COT_REPORT_L:
        table = "L";
        break;
    case COT_REPORT_LC:
        table = "L";
        break;
    case COT_REPORT_T:
        table = "T";
        break;
    case COT_REPORT_TC:
        table = "T";
        break;
    case COT_REPORT_D:
        table = "D";
        break;
    case COT_REPORT_DC:
        table = "D";
        break;
    case COT_REPORT_S:
        table = "S";
        break;
    }
    return table;
}

//+------------------------------------------------------------------+
//| Determine the COT report is futures only or combined with options|
//+------------------------------------------------------------------+
int CotIsFuturesOnly(ENUM_COT_REPORT report_type) {
    int fo = 0;
    switch(report_type) {
    case COT_REPORT_L:
        fo = 1;
        break;
    case COT_REPORT_LC:
        fo = 0;
        break;
    case COT_REPORT_T:
        fo = 1;
        break;
    case COT_REPORT_TC:
        fo = 0;
        break;
    case COT_REPORT_D:
        fo = 1;
        break;
    case COT_REPORT_DC:
        fo = 0;
        break;
    case COT_REPORT_S:
        fo = 0;
        break;
    }
    return fo;
}

//+------------------------------------------------------------------+
//| Retrieve COT report type.                                        |
//+------------------------------------------------------------------+
ENUM_COT_REPORT CotGetReportType(ENUM_COT_CLASS clss, ENUM_COT_MODE mode) {
    ENUM_COT_REPORT t = 1;
    int i = (int) clss;
    if (i >= 1 && i < 4)
        t = (mode == COT_MODE_FO) ? COT_REPORT_L : COT_REPORT_LC;
    else if (i >= 4 && i < 8)
        t = (mode == COT_MODE_FO) ? COT_REPORT_T : COT_REPORT_TC;
    else if (i >= 8 && i < 12)
        t = (mode == COT_MODE_FO) ? COT_REPORT_D : COT_REPORT_DC;
    else if (i == 12)
        t = COT_REPORT_S;
    return t;
}

//+------------------------------------------------------------------+
//| Retrieve the COT field clause.                                   |
//+------------------------------------------------------------------+
string CotGetColClause(ENUM_COT_CLASS clss) {
    string c;
    switch(clss) {
    case COT_CLASS_COM:
        c = "comm";
        break;
    case COT_CLASS_NCOM:
        c = "noncomm";
        break;
    case COT_CLASS_NR:
        c = "nonrept";
        break;
    case COT_CLASS_DEALER:
        c = "dealer";
        break;
    case COT_CLASS_ASSET:
        c = "asset_mgr";
        break;
    case COT_CLASS_LEV:
        c = "lev_money";
        break;
    case COT_CLASS_ORT:
        c = "other_rept";
        break;
    case COT_CLASS_PM:
        c = "prod_merc";
        break;
    case COT_CLASS_SD:
        c = "swap";
        break;
    case COT_CLASS_MM:
        c = "m_money";
        break;
    case COT_CLASS_ORD:
        c = "other_rept";
        break;
    case COT_CLASS_IT:
        c = "cit";
        break;
    }
    return c;
}

//+------------------------------------------------------------------+
//| Retrieve the description about COT types.                        |
//+------------------------------------------------------------------+
string CotGetDescription(ENUM_COT_CLASS clss) {
    string c;
    switch(clss) {
    case COT_CLASS_COM:
        c = "Commercial";
        break;
    case COT_CLASS_NCOM:
        c = "Non-Commercial";
        break;
    case COT_CLASS_NR:
        c = "Non-Reportables";
        break;
    case COT_CLASS_DEALER:
        c = "Dealer/Intermediary";
        break;
    case COT_CLASS_ASSET:
        c = "Asset Manager/Institutional";
        break;
    case COT_CLASS_LEV:
        c = "Leveraged Funds";
        break;
    case COT_CLASS_ORT:
        c = "Other Reportables (TFF)";
        break;
    case COT_CLASS_PM:
        c = "Producer/Merchant/Processor/User";
        break;
    case COT_CLASS_SD:
        c = "Swap Dealers";
        break;
    case COT_CLASS_MM:
        c = "Managed Money";
        break;
    case COT_CLASS_ORD:
        c = "Other Reportables (Disaggregated)";
        break;
    case COT_CLASS_IT:
        c = "Index Traders";
        break;
    }
    return c;
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
string CotGetDescription(ENUM_COT_MODE mode) {
    string s;
    switch(mode) {
    case COT_MODE_COP:
        s = "Futures & Options Combined";
        break;
    case COT_MODE_FO:
        s = "Futures Only";
        break;
    }
    return s;
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
string CotGetDescription(ENUM_COT_CLASS_CO clss) {
    return CotGetDescription((ENUM_COT_CLASS) ((int) clss));
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
string CotGetColClause(ENUM_COT_CLASS_CO clss) {
    return CotGetColClause((ENUM_COT_CLASS) ((int) clss));
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
ENUM_COT_REPORT CotGetReportType(ENUM_COT_CLASS_CO clss, ENUM_COT_MODE mode) {
    return CotGetReportType((ENUM_COT_CLASS) ((int) clss), mode);
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
string CotGetTableName(ENUM_COT_CLASS clss) {
    return CotGetTableName(CotGetReportType(clss, COT_MODE_FO));
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
string CotGetTableName(ENUM_COT_REPORT_CO report_type) {
    return CotGetTableName((ENUM_COT_REPORT) ((int) report_type));
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
string CotGetTableName(ENUM_COT_CLASS_CO clss) {
    return CotGetTableName((ENUM_COT_CLASS) ((int) clss));
}

//+------------------------------------------------------------------+
//| Find the index of the value in the array.                        |
//+------------------------------------------------------------------+
int ArraySearch(const string &arr[], string value, bool case_sensitive = true) {
    int n = ArraySize(arr);
    string s1, s2;
    for (int i = 0; i < n; i++) {
        if (case_sensitive) {
            if (arr[i] == value)
                return i;
        } else {
            s1 = arr[i];
            s2 = value;
            StringToLower(s1);
            StringToLower(s2);
            if (s1 == s2)
                return i;
        }
    }
    return -1;
}
//+------------------------------------------------------------------+

//===== END Cot.mqh =====


//===== BEGIN Sql.mqh =====
//+------------------------------------------------------------------+
//|                                                          Sql.mqh |
//|                                          Copyright 2024, Geraked |
//|                                       https://github.com/geraked |
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| Fetch the query result as a matrix (double type).                |
//+------------------------------------------------------------------+
bool SqlSelect(int db, const string sql, matrix &m, string &head[]) {
    int nrows, ncols;
    int dp;
    double val;
    string sval;

    dp = DatabasePrepare(db, sql);
    if (dp == INVALID_HANDLE) {
        PrintFormat("Error (%s, DatabasePrepare): #%d", __FUNCTION__, GetLastError());
        return false;
    }

    nrows = 0;
    ncols = DatabaseColumnsCount(dp);
    m.Init(nrows, ncols);
    ArrayResize(head, ncols);

    while (DatabaseRead(dp) && !IsStopped()) {
        m.Resize(nrows + 1, ncols);
        for (int j = 0; j < ncols && !IsStopped(); j++) {
            if (nrows == 0) {
                sval = "";
                DatabaseColumnName(dp, j, sval);
                head[j] = sval;
            }

            if (!DatabaseColumnDouble(dp, j, val)) {
                PrintFormat("Error (%s, DatabaseColumnDouble): #%d", __FUNCTION__, GetLastError());
                DatabaseFinalize(dp);
                return false;
            }
            m[nrows][j] = val;
        }
        nrows++;
    }

    DatabaseFinalize(dp);
    return true;
}

//+------------------------------------------------------------------+
//| Fetch the query result as a array of strings.                    |
//+------------------------------------------------------------------+
bool SqlSelect(int db, const string sql, string &rows[], string &head[], const ushort sep = '\t') {
    int nrows, ncols;
    int dp;
    double dval;
    long lval;
    string sval;

    dp = DatabasePrepare(db, sql);
    if (dp == INVALID_HANDLE) {
        PrintFormat("Error (%s, DatabasePrepare): #%d", __FUNCTION__, GetLastError());
        return false;
    }

    nrows = 0;
    ncols = DatabaseColumnsCount(dp);
    ArrayResize(head, ncols);

    while (DatabaseRead(dp) && !IsStopped()) {
        string row = "";
        for (int j = 0; j < ncols && !IsStopped(); j++) {
            if (nrows == 0) {
                sval = "";
                DatabaseColumnName(dp, j, sval);
                head[j] = sval;
            }

            ENUM_DATABASE_FIELD_TYPE ct = DatabaseColumnType(dp, j);
            dval = 0;
            lval = 0;
            sval = "";
            if (StringLen(row) > 0)
                StringAdd(row, StringFormat("%c", sep));
            if (ct == DATABASE_FIELD_TYPE_FLOAT) {
                DatabaseColumnDouble(dp, j, dval);
                StringAdd(row, (string) dval);
            } else if (ct == DATABASE_FIELD_TYPE_INTEGER) {
                DatabaseColumnLong(dp, j, lval);
                StringAdd(row, (string) lval);
            } else if (ct == DATABASE_FIELD_TYPE_TEXT) {
                DatabaseColumnText(dp, j, sval);
                StringAdd(row, sval);
            }
        }
        ArrayResize(rows, nrows + 1);
        rows[nrows] = row;
        nrows++;
    }

    DatabaseFinalize(dp);
    return true;
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
bool SqlSelect(int db, const string sql, matrix &m) {
    string head[];
    return SqlSelect(db, sql, m, head);
}

//+------------------------------------------------------------------+
//| Overload                                                         |
//+------------------------------------------------------------------+
bool SqlSelect(int db, const string sql, string &rows[], const ushort sep = '\t') {
    string head[];
    return SqlSelect(db, sql, rows, head, sep);
}

//+------------------------------------------------------------------+
//| Returns the first value of the query result.                     |
//+------------------------------------------------------------------+
long SqlGetLong(int db, const string sql, long default_value = -1) {
    matrix m;
    if (!SqlSelect(db, sql, m)) return default_value;
    return (long) m[0][0];
}

//+------------------------------------------------------------------+
//| Returns the first value of the query result.                     |
//+------------------------------------------------------------------+
double SqlGetDouble(int db, const string sql, double default_value = -1) {
    matrix m;
    if (!SqlSelect(db, sql, m)) return default_value;
    return (double) m[0][0];
}

//+------------------------------------------------------------------+
//| Returns the first value of the query result.                     |
//+------------------------------------------------------------------+
string SqlGetString(int db, const string sql, string default_value = "") {
    string rows[], row[];
    if (!SqlSelect(db, sql, rows, '¡')) return default_value;
    if (ArraySize(rows) < 1) return default_value;
    int n = StringSplit(rows[0], '¡', row);
    if (n < 1) return default_value;
    return row[0];
}

//+------------------------------------------------------------------+

//===== END Sql.mqh =====



input group "Indicator Parameters"
bool StEnable = false; // SuperTrend filter removed in single-file VPS build
double StMultiplier = 3;
int StPeriod = 10;
ENUM_TIMEFRAMES IndTimeframe = PERIOD_M15;

input group "COT"
input ENUM_COT_CLASS_CO CotPrimaryClass = COT_CLASS_CO_DEALER; // COT Primary Class
input ENUM_COT_MODE CotPrimaryMode = COT_MODE_FO; // COT Primary Mode
input ENUM_COT_CLASS_CO CotSecondaryClass = COT_CLASS_CO_LEV; // COT Secondary Class
input ENUM_COT_MODE CotSecondaryMode = COT_MODE_FO; // COT Secondary Mode

input group "General"
input string OpenTime = "03:00"; // Open Time for Trades
input double TPCoef = 2.0; // TP Coefficient
input ENUM_SL SLType = SL_AR; // SL Type
input int SLLookback = 6; // SL Lookback
input int SLDev = 30; // SL Deviation (Points)
input bool Reverse = false; // Reverse Signal

input group "Risk Management"
input double Risk = 0.5; // Risk
input ENUM_RISK RiskMode = RISK_DEFAULT; // Risk Mode
input bool IgnoreSL = false; // Ignore SL
input bool IgnoreTP = false; // Ignore TP
input bool Trail = true; // Trailing Stop
input double TrailingStopLevel = 50; // Trailing Stop Level (%) (0: Disable)
input double EquityDrawdownLimit = 0; // Equity Drawdown Limit (%) (0: Disable)

input group "Strategy: Grid"
input bool Grid = false; // Grid Enable
input double GridVolMult = 1.2; // Grid Volume Multiplier
input double GridTrailingStopLevel = 0; // Grid Trailing Stop Level (%) (0: Disable)
input int GridMaxLvl = 20; // Grid Max Levels

input group "News"
input bool News = false; // News Enable
input ENUM_NEWS_IMPORTANCE NewsImportance = NEWS_IMPORTANCE_MEDIUM; // News Importance
input int NewsMinsBefore = 60; // News Minutes Before
input int NewsMinsAfter = 60; // News Minutes After
input int NewsStartYear = 0; // News Start Year to Fetch for Backtesting (0: Disable)

input group "Open Position Limit"
input bool OpenNewPos = true; // Allow Opening New Position
input bool MultipleOpenPos = false; // Allow Having Multiple Open Positions
input double MarginLimit = 1500; // Margin Limit (%) (0: Disable)
input int SpreadLimit = -1; // Spread Limit (Points) (-1: Disable)

input group "Auxiliary"
input int Slippage = 30; // Slippage (Points)
input int TimerInterval = 120; // Timer Interval (Seconds)
input ulong MagicNumber = 1004; // Magic Number
input ENUM_FILLING Filling = FILLING_DEFAULT; // Order Filling

int SignalCheckInterval = 15; // Minutes

GerEA ea;
string tcd;
MqlDateTime tcs;
datetime tc;
datetime signalLastCheck;

struct SSignal {
    string           symbol;
    string           type;
    string           clss;
    string           mode;
    string           gp;
    string           rp;
    string           date;
    int              cid;
    int              mid;
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ST(string symbol, int i = 0) {
    return -1; // SuperTrend removed in single-file VPS build
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckForSignal() {
    if (!OpenNewPos) return;
    if (tcs.day_of_week != MONDAY && tcs.day_of_week != TUESDAY) return;
    if (tc - signalLastCheck < SignalCheckInterval * 60) return;
    if (tc < StringToTime(tcd + OpenTime)) return;
    if (MarginLimit && PositionsTotal() > 0 && AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) < MarginLimit) return;
    if (!MultipleOpenPos && ea.OPTotal() > 0) return;

    signalLastCheck = tc;
    SSignal signals[];
    if (!FetchSignals(CotPrimaryClass, CotPrimaryMode, signals, tc))
        return;
    if (!FetchSignals(CotSecondaryClass, CotSecondaryMode, signals, tc))
        return;

    for (int i = 0; i < ArraySize(signals); i++) {
        string s = signals[i].symbol;
        string stype = signals[i].type;

        if (MarginLimit && PositionsTotal() > 0 && AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) < MarginLimit) return;
        if (!MultipleOpenPos && ea.OPTotal() > 0) return;

        if (ea.OPTotal(s) > 0) continue;
        if (hasDealCurrentWeek(ea.GetMagic(), s)) continue;
        if (SpreadLimit != -1 && Spread(s) > SpreadLimit) continue;

        int digits = (int) SymbolInfoInteger(s, SYMBOL_DIGITS);

        if (StEnable) {
            double st = ST(s);
            if (st == -1) continue;

            double h = iHigh(s, IndTimeframe, 0);
            double l = iLow(s, IndTimeframe, 0);
            double c = iClose(s, IndTimeframe, 0);

            if (st < c && stype == "sell")
                continue;
            if (st > c && stype == "buy")
                continue;
        }

        fixMultiCurrencies();

        if (stype == "buy") {
            double in = Ask(s);
            double sl = BuySL(SLType, SLLookback, in, SLDev, 0, s, PERIOD_D1);
            double tp = in + TPCoef * MathAbs(in - sl);
            ea.BuyOpen(in, sl, tp, IgnoreSL, IgnoreTP, s);
            Sleep(5000);
        }

        if (stype == "sell") {
            double in = Bid(s);
            double sl = SellSL(SLType, SLLookback, in, SLDev, 0, s, PERIOD_D1);
            double tp = in - TPCoef * MathAbs(in - sl);
            ea.SellOpen(in, sl, tp, IgnoreSL, IgnoreTP, s);
            Sleep(5000);
        }
    }
}


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    ea.Init();
    ea.SetMagic(MagicNumber);
    ea.risk = Risk * 0.01;
    ea.reverse = Reverse;
    ea.trailingStopLevel = TrailingStopLevel * 0.01;
    ea.grid = Grid;
    ea.gridVolMult = GridVolMult;
    ea.gridTrailingStopLevel = GridTrailingStopLevel * 0.01;
    ea.gridMaxLvl = GridMaxLvl;
    ea.equityDrawdownLimit = EquityDrawdownLimit * 0.01;
    ea.slippage = Slippage;
    ea.news = News;
    ea.newsImportance = NewsImportance;
    ea.newsMinsBefore = NewsMinsBefore;
    ea.newsMinsAfter = NewsMinsAfter;
    ea.filling = Filling;
    ea.riskMode = RiskMode;

    if (RiskMode == RISK_FIXED_VOL || RiskMode == RISK_MIN_AMOUNT) ea.risk = Risk;
    if (News) fetchCalendarFromYear(NewsStartYear);

    if (!CotInit(CotGetReportType(CotPrimaryClass, CotPrimaryMode)))
        return INIT_FAILED;
    if (!CotInit(CotGetReportType(CotSecondaryClass, CotSecondaryMode)))
        return INIT_FAILED;

    EventSetTimer(TimerInterval);

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    EventKillTimer();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    datetime oldTc = tc;
    tc = TimeCurrent(tcs);
    tcd = TimeToString(tc, TIME_DATE) + " ";
    if (tc == oldTc) return;

    if (Trail) ea.CheckForTrail();
    if (EquityDrawdownLimit) ea.CheckForEquity();
    if (Grid) ea.CheckForGrid();
    CheckForSignal();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnTesterInit() {
    return INIT_FAILED;
}

void OnTesterDeinit() {

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool FetchSignals(ENUM_COT_CLASS_CO clss, ENUM_COT_MODE mode, SSignal &signals[], datetime time = 0) {
    if (time == 0) time = TimeTradeServer();
    datetime date_from, date_to;
    CotGetDateRange(time, date_from, date_to);
    ENUM_COT_REPORT report_type = CotGetReportType(clss, mode);
    if (!CotIsAvailable(report_type, time)) {
        PrintFormat("The COT report is not available: %s (%s - %s)", TimeToString(time), TimeToString(date_from, TIME_DATE), TimeToString(date_to, TIME_DATE));
        return false;
    }

    string table = CotGetTableName(clss);
    string ccol = CotGetColClause(clss);
    string lcol = StringFormat("%s_positions_long", ccol);
    string scol = StringFormat("%s_positions_short", ccol);
    string lccol = StringFormat("change_in_%s_long", ccol);
    string sccol = StringFormat("change_in_%s_short", ccol);
    int fo = (mode == COT_MODE_FO) ? 1 : 0;

    if (clss == COT_CLASS_CO_COM || clss == COT_CLASS_CO_NCOM || clss == COT_CLASS_CO_NR || StringFind(lcol, "dealer") != -1) {
        lcol += "_all";
        scol += "_all";
        lccol += "_all";
        sccol += "_all";
    }

    string sql = "WITH M AS ( "
                 "SELECT strftime('%Y.%m.%d', date, 'unixepoch') AS d, date, name, "
                 + StringFormat("round(%s * 100.0 / (%s + %s), 2) AS lp, ", lcol, lcol, scol)
                 + StringFormat("round(%s * 100.0 / (%s + %s), 2) AS sp, ", scol, lcol, scol)
                 + StringFormat("%s AS lc, %s AS sc, ", lccol, sccol)
                 + StringFormat("(%s - %s) AS cnp ", lccol, sccol)
                 + StringFormat("FROM %s A ", table) +
                 "INNER JOIN contract C ON C.id = A.cid "
                 + StringFormat("WHERE date >= %d AND date < %d ", date_from, date_to) +
                 "AND C.id IN ('232741','099741','096742','112741','090741','092741','097741','098662') "
                 + StringFormat("AND fo = %d ", fo) +
                 "ORDER BY date DESC, name ASC LIMIT 8 "
                 ") "

                 "SELECT t1.name AS green, t2.name AS red, t1.lp AS green_percent, t2.sp As red_percent, t1.d AS date FROM "
                 "(SELECT * FROM M WHERE cnp > 0 ORDER BY lp DESC LIMIT 2) AS t1, "
                 "(SELECT * FROM M WHERE cnp < 0 ORDER BY sp DESC LIMIT 2) AS t2 "
                 ";";

    int db = CotInitDb();
    if (db == INVALID_HANDLE) return false;
    string rows[], head[];
    SqlSelect(db, sql, rows, head, '\t');
    DatabaseClose(db);

    string row[];
    string g, r, symbol;
    string postfix = StringLen(_Symbol) > 6 ? StringSubstr(_Symbol, 6) : "";
    int nrows = ArraySize(rows);
    int j = 0;
    bool b;

    for (int i = 0; i < nrows; i++) {
        StringSplit(rows[i], '\t', row);
        g = row[0];
        r = row[1];
        symbol = g + r + postfix;
        j = ArraySize(signals);

        if (SymbolExist(symbol, b)) {
            ArrayResize(signals, j + 1);
            signals[j].symbol = symbol;
            signals[j].type = "buy";
        } else {
            symbol = r + g + postfix;
            if (!SymbolExist(symbol, b)) continue;
            ArrayResize(signals, j + 1);
            signals[j].symbol = symbol;
            signals[j].type = "sell";
        }

        signals[j].clss = CotGetDescription(clss);
        signals[j].mode = CotGetDescription(mode);
        signals[j].gp = row[2];
        signals[j].rp = row[3];
        signals[j].date = row[4];
        signals[j].cid = clss;
        signals[j].mid = mode;
    }

    return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool hasDealCurrentWeek(ulong magic, string symbol) {
    datetime date_from, date_to;
    CotGetDateRange(TimeCurrent(), date_from, date_to);
    date_from += 7 * PeriodSeconds(PERIOD_D1);
    if (!HistorySelect(TimeCurrent() - 10 * PeriodSeconds(PERIOD_D1), TimeCurrent())) {
        int err = GetLastError();
        PrintFormat("%s error #%d : %s", __FUNCTION__, err, ErrorDescription(err));
        return false;
    }
    int totalDeals = HistoryDealsTotal();
    for (int i = totalDeals - 1; i >= 0; i--) {
        ulong ticket = HistoryDealGetTicket(i);
        if (HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_IN) continue;
        if (HistoryDealGetInteger(ticket, DEAL_MAGIC) != magic) continue;
        if (HistoryDealGetString(ticket, DEAL_SYMBOL) != symbol) continue;
        datetime dealTime = (datetime) HistoryDealGetInteger(ticket, DEAL_TIME);
        if (dealTime >= date_from) return true;
    }
    return false;
}

//+------------------------------------------------------------------+
