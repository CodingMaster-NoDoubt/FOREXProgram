//+------------------------------------------------------------------+
//|                                                  OrderTaking.mqh |
//|                                                    Valère Bardon |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Valère Bardon"
#property link      ""
#property strict

// Constantes
const double PIP_VALUE = MarketInfo(_Symbol, MODE_TICKSIZE) * 10;
const double LOT_SIZE = MarketInfo(_Symbol, MODE_LOTSIZE);

// Variable globale
int gTicket;

//+------------------------------------------------------------------+
//| Fonction pour passer des ordres (prendre des positions)          |
//+------------------------------------------------------------------+
void takeOrder(int type)
  {

// Déclaration des variables
   double lot_size;
   int atr_value_mult = 3;
   if(getAtr(si) >= 1)
         atr_value_mult = 1;
   if(type == TYPE_BULLISH)
     {
      
      double sl = Ask - getAtr(si) * atr_value_mult;
      double tp = Ask + (Ask - sl) * 2;
      
      int sl_in_pips = int(MathRound((Ask - sl) / PIP_VALUE));
      lot_size = getVolume(sl_in_pips, TYPE_BULLISH);

      gTicket = OrderSend(_Symbol, OP_BUY, lot_size, Ask, 100, sl, tp, "Bullish position", MAGIC_NUMBER);
     }
   else
     {
         
      double sl = Bid + getAtr(si) * atr_value_mult;
      double tp = Bid - (sl - Bid) * 2;
      
      int sl_in_pips = int(MathRound((sl - Bid) / PIP_VALUE));
      lot_size = getVolume(sl_in_pips, TYPE_BEARISH);

      gTicket = OrderSend(_Symbol, OP_SELL, lot_size, Bid, 100, sl, tp, "Bearish position", MAGIC_NUMBER);
     }

  }

//+------------------------------------------------------------------------------+
//| Utilisé pour gérer le risque (seulement risquer 1 ou 2% du compte par ordre) |
//+------------------------------------------------------------------------------+
double getVolume(double sl, int exchange_type) // Exchange rate is Ask for buy and Bid for sell
  {
  
   if(sl == 0)
      return MarketInfo(_Symbol, MODE_MINLOT);

   double lots;
   double risk_amount = AccountBalance() * (risk_management_percentage / 100);
   double exchange_rate = 1;

// Calculer le taux de change entre la devise de cotation et la devise du compte (https://www.cashbackforex.com/tools/position-size-calculator/EURGBP)
// La devise de cotation est la deuxième devise dans la paire de devise (ex : JPY dans USDJPY), et la devise utilisée pour dans la paire de devise.
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

// FORMULE
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

//+--------------------------------------------------------------------------------------------------------------+
//| Prendre la valeur ATR (Average True Range) de la bougie selectionnée. Le ATR est un indicateur qui permet    |
//| de voir la volatilité, il est donc utile pour trouver des "stoploss" qui ne se feront pas toucher par erreur.|
//+--------------------------------------------------------------------------------------------------------------+
double getAtr(int index)
  {
   double atr_value = iATR(_Symbol, _Period, 14, index);
   return atr_value;
  }

//+------------------------------------------------------------------+
