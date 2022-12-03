//+------------------------------------------------------------------+
//|                                            MACDCrosshoverMTF.mq4 |
//|                                                             vlrr |
//|                      https://www.youtube.com/watch?v=Yj0yEBxwLVw |
//+------------------------------------------------------------------+
#property copyright "vlrr"
#property link      "https://www.youtube.com/watch?v=Yj0yEBxwLVw"
#property version   "1.00"
#property strict

#define MAGIC_NUMBER 20220800

#include <basics.mqh>

//--- Global variables
int si = 1;

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
//| Main Function                                                    |
//+------------------------------------------------------------------+
void OnBar()
  {
   switch(getTrend(3, si, -1, 20, 50, 100))
     {
      case T_UPTREND :
         if(getMACDCrosshover() == TYPE_BULLISH)
           {
            int atr_value_mult = 3;
            if(getAtr(si) >= 1)
               atr_value_mult = 1;
            double sl = Ask - getAtr(si) * atr_value_mult;
            double tp = Ask + (Ask - sl) * 2;
            takeOrder(TYPE_BULLISH, sl, tp, MAGIC_NUMBER);
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
            takeOrder(TYPE_BEARISH, sl, tp, MAGIC_NUMBER);
           }
         break;

      default:
         break;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int getMACDCrosshover()
  {
   double prev_macd_signal = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, si + 1);
   double prev_macd_main = /*prev_macd_signal + */iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, si + 1);

   double macd_signal = iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, si);
   double macd_main = /*macd_signal + */iMACD(_Symbol, _Period, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, si);

   if(prev_macd_main < 0 && macd_main > 0/*prev_macd_main < prev_macd_signal && macd_main > macd_signal*/)
     {
      return TYPE_BULLISH;
     }
   else
      if(prev_macd_main > 0 && macd_main < 0/*prev_macd_main > prev_macd_signal && macd_main < macd_signal*/)
        {
         return TYPE_BEARISH;
        }
      else
         return T_NOTREND;

  }

//+------------------------------------------------------------------+
