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
#define MAGIC_NUMBER 20222023

#define TYPE_BULLISH                0
#define TYPE_BEARISH                1
#define T_UPTREND                   2
#define T_DOWNTREND                 3
#define T_NOTREND                   4

const int si = 1;
input double risk_management_percentage = 1; // Pourcentage risqué du compte par ordre

//+------------------------------------------------------------------+
//| Fichiers importés                                                |
//+------------------------------------------------------------------+
#include "newBar.mqh" // Fonction qui vérifie si une nouvelle bougie a été créée
#include "StrategyLogic.mqh" // Fichier qui contient les deux principales fonctions pour la logique de la stratégie
#include "OrderTaking.mqh" // Fichier qui contient les fonctions pour passer des ordres


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
  
  // Exécuter le code de la stratégie seulement lorsqu'une nouvelle bougie est formée
   if(newBar())
      OnBar();
      
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
            
            takeOrder(TYPE_BULLISH);
           }
         break;
      case T_DOWNTREND :
         if(getMACDCrosshover() == TYPE_BEARISH)
           {
            
            takeOrder(TYPE_BEARISH);
           }
         break;

      default:
         break;
     }
  }

//+------------------------------------------------------------------+
