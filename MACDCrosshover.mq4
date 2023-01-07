//+------------------------------------------------------------------+
//|                                            MACDCrosshoverMTF.mq4 |
//|                                                             vlrr |
//|                      https://www.youtube.com/watch?v=Yj0yEBxwLVw |
//+------------------------------------------------------------------+
#property copyright "vlrr"
#property link      "https://www.youtube.com/watch?v=Yj0yEBxwLVw"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Constantes                                                       |
//+------------------------------------------------------------------+
#define MAGIC_NUMBER 20220800

#define TYPE_BULLISH                0
#define TYPE_BEARISH                1
#define T_UPTREND                   2
#define T_DOWNTREND                 3
#define T_NOTREND                   4

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
const double PIP_VALUE = MarketInfo(_Symbol, MODE_TICKSIZE) * 10;
const double LOT_SIZE = MarketInfo(_Symbol, MODE_LOTSIZE);

const int si = 1;
const double risk_management_percentage = 1;

//#include <basics.mqh>

//--- Global variables
datetime gBarTime;
int gTicket;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("INIT !");
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print("DEINIT !");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(newBar())
     {
      OnBar();
     }
  }

//+------------------------------------------------------------------+
//| Check if a new bar has been created                              |
//+------------------------------------------------------------------+
bool newBar()
  {
   datetime currentBarTime = iTime(_Symbol, _Period, 0); // Gets the time of the current forming bar
   if(currentBarTime != gBarTime)  // If the current bar is not the the same as the bar in the current variable, it means that a new bar has been created
     {
      gBarTime = currentBarTime; // Update the global variable time to the current bar time
      return true; // Returns true for new bar
     }
   else
      return false;

  }

//+------------------------------------------------------------------+
//| Main Function                                                    |
//+------------------------------------------------------------------+
void OnBar()
  {
   switch(getTrend(si))
     {
      case T_UPTREND :
         if(getMACDCrosshover() == TYPE_BULLISH)
           {
            int atr_value_mult = 3;
            if(getAtr(si) >= 1)
               atr_value_mult = 1;
            double sl = Ask - getAtr(si) * atr_value_mult;
            double tp = Ask + (Ask - sl) * 2;
            takeOrder(TYPE_BULLISH, sl, tp);
           }
         break;
      case T_DOWNTREND :
         if(getMACDCrosshover() == TYPE_BEARISH)
           {
            int atr_value_mult = 3;
            if(getAtr(si) >= 1)
               atr_value_mult = 1;
            double sl = Bid + getAtr(si) * atr_value_mult;
            double tp = Bid - (sl - Bid) * 2;
            takeOrder(TYPE_BEARISH, sl, tp);
           }
         break;

      default:
         break;
     }
  }

//+------------------------------------------------------------------+
//| Main logic function                                              |
//+------------------------------------------------------------------+
int getMACDCrosshover()
  {
   double prev_macd_main = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, si + 1);
   double macd_main = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, si);

   if(prev_macd_main < 0 && macd_main > 0)
     {
      return TYPE_BULLISH;
     }
   else
      if(prev_macd_main > 0 && macd_main < 0)
        {
         return TYPE_BEARISH;
        }
      else
         return T_NOTREND;

  }

//+------------------------------------------------------------------+
//| Get the trend direction                                          |
//+------------------------------------------------------------------+
int getTrend(int si)
  {
// Preparing variables
   double ema20 = iMA(_Symbol, _Period, 20, 0, MODE_EMA, PRICE_CLOSE, si);
   double ema50 = iMA(_Symbol, _Period, 50, 0, MODE_EMA, PRICE_CLOSE, si);
   double ema200 = iMA(_Symbol, _Period, 100, 0, MODE_EMA, PRICE_CLOSE, si);

   if(ema20 > ema50 && ema50 > ema200)
      return T_UPTREND;
   else
      if(ema20 < ema50 && ema50 < ema200)
         return T_DOWNTREND;
      else
         return T_NOTREND;
  }


//+------------------------------------------------------------------+
//| Get ATR value                                                    |
//+------------------------------------------------------------------+
double getAtr(int index)
  {
   double atr_value = iATR(_Symbol, _Period, 14, index);
   return atr_value;
  }

//+------------------------------------------------------------------+
//| Take Order                                                       |
//+------------------------------------------------------------------+
void takeOrder(int type, double sl, double tp)
  {

   double lot_size;

   if(type == TYPE_BULLISH)
     {
      int sl_in_pips = int(MathRound((Ask - sl) / PIP_VALUE));
      lot_size = getVolume(sl_in_pips, TYPE_BULLISH);

      gTicket = OrderSend(_Symbol, OP_BUY, lot_size, Ask, 100, sl, tp, "Get Rich", MAGIC_NUMBER);
      //draw(TYPE_BULLISH, barIndexForDrawFunction);
     }
   else
     {
      int sl_in_pips = int(MathRound((sl - Bid) / PIP_VALUE));
      lot_size = getVolume(sl_in_pips, TYPE_BEARISH);

      gTicket = OrderSend(_Symbol, OP_SELL, lot_size, Bid, 100, sl, tp, "Get Rich", MAGIC_NUMBER);
      //draw(TYPE_BEARISH, barIndexForDrawFunction);
     }

   if(GetLastError() != 0)
     {
      Print("-----------------------------------------------------------------------------------------------------------------------------------------------------------");
      Print("Takeprofit : ", tp, " - Stoposs : ", sl);
      Print("Ask : ", Ask, " - Bid : ", Bid);
      Print("OrderType : ", type);
      Print("Lot Size : ", lot_size);
      Print("Account Equity : ", AccountEquity());
      Print("Account Balance : ", AccountBalance());
      Print("An Error Occured !");
      Print("-----------------------------------------------------------------------------------------------------------------------------------------------------------");
     }


  }

//+------------------------------------------------------------------+
//| Used for risk management                                         |
//+------------------------------------------------------------------+
double getVolume(double sl, int exchange_type) // Exchange rate is Ask for buy and Bid for sell
  {
   if(sl == 0)
      return MarketInfo(_Symbol, MODE_MINLOT);

   double lots;
   double risk_amount = AccountBalance() * (risk_management_percentage / 100);
   double exchange_rate = 1;

// Calculate exchange rate between quote currency and account currency (https://www.cashbackforex.com/tools/position-size-calculator/EURGBP)
   string quote_currency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
   string account_currency = AccountCurrency();
   string exchange_rate_pair = account_currency+quote_currency;

   if(quote_currency != account_currency) // If quote_currency == account_currency, we dont need any conversion, since we already defined the exchange_rate as 1
     {
      bool reverse_currency_pair = false;
      exchange_rate = MarketInfo(exchange_rate_pair, MODE_ASK);
      if(exchange_rate == 0) // Verify if the exchange_rate_pair exists
        {
         reverse_currency_pair = true;
         exchange_rate_pair = quote_currency+account_currency;
        }

      if(exchange_type == TYPE_BULLISH)
         exchange_rate = MarketInfo(exchange_rate_pair, MODE_ASK);
      else
         exchange_rate = MarketInfo(exchange_rate_pair, MODE_BID);

      if(reverse_currency_pair)
         exchange_rate = 1 / exchange_rate;
     }

// FORMULA
   lots = ((risk_amount * exchange_rate) / (sl * PIP_VALUE * LOT_SIZE));

// Il faut bien arrondir la valeur pour que l'ordre puisse passer sans erreur
   double lot_step = MarketInfo(_Symbol, MODE_MINLOT); // Trouver à combien de décimale arrondir
   lots = MathRound(lots / lot_step) * lot_step; // Arrondir

// Il faut vérifier que la taille du lot ne soit pas en dessous de la taille minimale et n'excède pas la valeur maximale définie par le Broker
   if(lots < MarketInfo(_Symbol, MODE_MINLOT))
     {
      Print("Lots traded is too small for your broker.");
      lots = MarketInfo(_Symbol, MODE_MINLOT); // Si la taille du lot est trop petite, la changer pour la valeur minimale acceptée par le Broker
     }
   else
      if(lots > MarketInfo(_Symbol, MODE_MAXLOT))
        {
         Print("Lots traded is too large for your broker.");
         lots = MarketInfo(_Symbol, MODE_MAXLOT); // Si la taille du lot est trop grande, la changer pour la valeur maximale acceptée par le Broker
        }

   return lots;
  }

//+------------------------------------------------------------------+
