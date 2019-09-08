//+------------------------------------------------------------------+
//|                                           Martingale Manager.mq4 |
//|                                                  Moataz Metwally |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Moataz Metwally"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum enu_state  // enumeration of named constants
  {
   CHECK_STRATGEY,
   WAITING_START_TIME,
   WAITING_LASTBAR,
   WAITING_START_PENDING_BASED_ON_LASTBAR,
   TRADE_1,
   TRADE_2,
   TRADE_3,
   TRADE_4,
   TRADE_6,
   TRADE_7,
   TRADE_8,
   TRADE_9,
   TRADE_10,
   TRADE_11
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum enu_market  // enumeration of named constants
  {
   MARKET_EXCUTION,
   BAR_DEPENDANT,
   PENDING_ORDER
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct time_t
  {
   int               hour;
   int               minute;

  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct strategy
  {
   string            symbol;
   time_t            start_time;
   bool              bar_dependant_bar;
   int               lastcandle_dependant_timeframe;
   int               deviation_pips;
   enu_state         state;
   bool              enabled;
   enu_market        type_market;
   int               initial_trade_counter;
   int               lot_size[10];
   int               takeprofit;
   int               stoploss;
   int               spread_cap;
   int               magic_number;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct Config
  {
   strategy          s[20];
   int               num_stratgies;
   double            pip_representation;
   int               time_adjustment;
   double            minimum_lost_size;
   double            lot_size_for_1_USD_per_pip;
   double            max_loss_per_trade;
   int               conf_version;

  };

Config conf;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetMillisecondTimer(1);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+

int counter;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
RefreshRates();

   counter++;
   if(counter%2000)
     {

      // read  configuration
     }

   for(int i=0;i<conf.num_stratgies;i++)
     {

     }

  }
//+------------------------------------------------------------------+

void processStrategy(int id)
  {
  

   datetime t=TimeGMT();
   strategy current_strategy=conf.s[id];
   int strategy_hour=TimeHour(t)+conf.time_adjustment;
   int strategy_minute=TimeMinute(t)+conf.time_adjustment;
   enu_state activeState=conf.s[id].state;
   switch(activeState)
     {

      case CHECK_STRATGEY:
        {
         if(current_strategy.type_market == MARKET_EXCUTION){
         
           activeState=WAITING_START_TIME;
         
         }else if(current_strategy.type_market == BAR_DEPENDANT){
         
         activeState=WAITING_LASTBAR;
         
         }else if(current_strategy.type_market == PENDING_ORDER){
         
         activeState=WAITING_START_PENDING_BASED_ON_LASTBAR;
         }
 
         break;
        }

      case WAITING_LASTBAR:
        {
        


         break;
        }
      case WAITING_START_TIME:
        {
         
         
         break;
        }

      case WAITING_START_PENDING_BASED_ON_LASTBAR:
        {
        
         break;
        }



     }

   conf.s[id].state=activeState;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BuyOrder(double price,double size,double spread)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SellOrder(double price,double size,double spread)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BuyStopOrder(double price,double size,double spread)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SellStopOrder(double price,double size,double spread)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BuyLimitOrder(double price,double size,double spread)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SellLimitOrder(double price,double size,double spread)
  {

  }

//+------------------------------------------------------------------+
