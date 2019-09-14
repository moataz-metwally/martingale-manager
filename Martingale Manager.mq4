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
   WAITING_START_TIME_BUY,
   WAITING_START_TIME_SELL,
   WAITING_LASTBAR,
   WAITING_START_PENDING_BASED_ON_LASTBAR,
   LET_MARKET_DECIDE_FIND_DIRECTION,
   COUNTER_TRADE_2,
   COUNTER_TRADE_3,
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
   MARKET_EXCUTION_BUY,
   MARKET_EXCUTION_SELL,
   BAR_DEPENDANT,
   LET_MARKET_DECIDE
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
   int               lastcandle_dependant_timeframe;
   int               deviation_pips;
   enu_state         state;
   bool              enabled;
   enu_market        type_market;
   int               initial_trade_counter;
   double            lot_size[10];
   int               takeprofit;
   double            stoploss;
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
   int               time_shift;
   double            minimum_lost_size;
   double            lot_size_for_1_USD_per_pip;
   double            max_loss_per_trade;
   int               conf_version;

  };

Config conf;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct OrderCount
  {
   int               buy;
   int               sell;
   int               sellstop;
   int               buystop;
  };
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
   int strategy_hour=TimeHour(t)+conf.time_shift;
   int strategy_minute=TimeMinute(t);
   enu_state activeState=conf.s[id].state;
   string strategy_symbol=conf.s[id].symbol;
   int spread_cap=current_strategy.spread_cap;
   int magic_number=current_strategy.magic_number;
   int take_profit=current_strategy.takeprofit;
   int stop_loss=current_strategy.stoploss;
   OrderCount order_counts=CountOrders(strategy_symbol,current_strategy.magic_number);
   int bar_time_frame=current_strategy.lastcandle_dependant_timeframe;

   switch(activeState)
     {
/************************************************************************************************************/
      case CHECK_STRATGEY:

         if(current_strategy.type_market==MARKET_EXCUTION_BUY)
           {

            activeState=WAITING_START_TIME_BUY;

           }
         else if(current_strategy.type_market==MARKET_EXCUTION_SELL)
           {

            activeState=WAITING_START_TIME_SELL;

              }else if(current_strategy.type_market==BAR_DEPENDANT){

            activeState=WAITING_LASTBAR;

              }else if(current_strategy.type_market==LET_MARKET_DECIDE){

            activeState=WAITING_START_PENDING_BASED_ON_LASTBAR;
           }

         break;
/************************************************************************************************************/
      case WAITING_LASTBAR:

        {

         if(strategy_hour==current_strategy.start_time.hour && strategy_minute==current_strategy.start_time.minute)
           {

            // Bullish bar
            if(iOpen(strategy_symbol,bar_time_frame,1)<=iClose(strategy_symbol,bar_time_frame,1))
              {

               BuyOrder(strategy_symbol,
                        MarketInfo(strategy_symbol,MODE_ASK),
                        current_strategy.lot_size[0],
                        spread_cap,
                        magic_number,take_profit,stop_loss);
               //counter order
               SellStopOrder(strategy_symbol,
                             MarketInfo(strategy_symbol,MODE_BID)-Point*current_strategy.stoploss,
                             current_strategy.lot_size[1],
                             spread_cap,
                             magic_number,take_profit,stop_loss);

                 }else{  // Bearish bar

               SellOrder(strategy_symbol,
                         MarketInfo(strategy_symbol,MODE_BID),
                         current_strategy.lot_size[0],
                         spread_cap,
                         magic_number,take_profit,stop_loss);
               //counter order
               BuyStopOrder(strategy_symbol,
                            MarketInfo(strategy_symbol,MODE_ASK)+Point*current_strategy.stoploss,
                            current_strategy.lot_size[1],
                            spread_cap,
                            magic_number,take_profit,stop_loss);

              }

            activeState=COUNTER_TRADE_2;

           }
         break;
        }

/************************************************************************************************************/
      case WAITING_START_TIME_BUY:

         if(strategy_hour==current_strategy.start_time.hour && strategy_minute==current_strategy.start_time.minute)
           {

            BuyOrder(strategy_symbol,
                     MarketInfo(strategy_symbol,MODE_ASK),
                     current_strategy.lot_size[0],
                     spread_cap,
                     magic_number,take_profit,stop_loss);
            //counter order
            SellStopOrder(strategy_symbol,
                          MarketInfo(strategy_symbol,MODE_BID)-Point*current_strategy.stoploss,
                          current_strategy.lot_size[1],
                          spread_cap,
                          magic_number,take_profit,stop_loss);
           }

         activeState=COUNTER_TRADE_2;
         break;
/************************************************************************************************************/
      case WAITING_START_TIME_SELL:

         if(strategy_hour==current_strategy.start_time.hour && strategy_minute==current_strategy.start_time.minute)
           {

            SellOrder(strategy_symbol,
                      MarketInfo(strategy_symbol,MODE_BID),
                      current_strategy.lot_size[0],
                      spread_cap,
                      magic_number,take_profit,stop_loss);
            //counter order
            BuyStopOrder(strategy_symbol,
                         MarketInfo(strategy_symbol,MODE_ASK)+Point*current_strategy.stoploss,
                         current_strategy.lot_size[1],
                         spread_cap,
                         magic_number,take_profit,stop_loss);

           }

         activeState=COUNTER_TRADE_2;
         break;
/************************************************************************************************************/
      case WAITING_START_PENDING_BASED_ON_LASTBAR:
         if(strategy_hour==current_strategy.start_time.hour && strategy_minute==current_strategy.start_time.minute)
           {

            //fishing  order
            SellStopOrder(strategy_symbol,
                          MarketInfo(strategy_symbol,MODE_BID)-Point*current_strategy.deviation_pips,
                          current_strategy.lot_size[1],
                          spread_cap,
                          magic_number,take_profit,stop_loss);

            //fishing order
            BuyStopOrder(strategy_symbol,
                         MarketInfo(strategy_symbol,MODE_ASK)+Point*current_strategy.deviation_pips,
                         current_strategy.lot_size[1],
                         spread_cap,
                         magic_number,take_profit,stop_loss);
           }
         activeState=LET_MARKET_DECIDE_FIND_DIRECTION;
         break;
/************************************************************************************************************/
      case LET_MARKET_DECIDE_FIND_DIRECTION:
        {

         if(order_counts.buy==1 && order_counts.sellstop==0)
           {

            SellStopOrder(strategy_symbol,
                          MarketInfo(strategy_symbol,MODE_BID)-Point*current_strategy.stoploss,
                          current_strategy.lot_size[2],
                          spread_cap,
                          magic_number,take_profit,stop_loss);
              } else  if(order_counts.sell==1 && order_counts.buystop==0){

            BuyStopOrder(strategy_symbol,
                         MarketInfo(strategy_symbol,MODE_ASK)+Point*current_strategy.stoploss,
                         current_strategy.lot_size[2],
                         spread_cap,
                         magic_number,take_profit,stop_loss);

           }

        }
      break;
/************************************************************************************************************/
      case COUNTER_TRADE_2:
        {

         if(order_counts.buy==1 && order_counts.sellstop==0)
           {

            SellStopOrder(strategy_symbol,
                          MarketInfo(strategy_symbol,MODE_BID)-Point*current_strategy.stoploss,
                          current_strategy.lot_size[2],
                          spread_cap,
                          magic_number,take_profit,stop_loss);
              } else  if(order_counts.sell==1 && order_counts.buystop==0){

            BuyStopOrder(strategy_symbol,
                         MarketInfo(strategy_symbol,MODE_ASK)+Point*current_strategy.stoploss,
                         current_strategy.lot_size[2],
                         spread_cap,
                         magic_number,take_profit,stop_loss);

           }

        }
      break;

     }

   conf.s[id].state=activeState;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BuyOrder(string symbol,double price,double size,double spread,int magicnumber,double takeprofit,double stoploss)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SellOrder(string symbol,double price,double size,double spread,int magicnumber,double takeprofit,double stoploss)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BuyStopOrder(string symbol,double price,double size,double spread,int magicnumber,double takeprofit,double stoploss)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SellStopOrder(string symbol,double price,double size,double spread,int magicnumber,double takeprofit,double stoploss)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BuyLimitOrder(double price,double size,double spread,double takeprofit,double stoploss)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SellLimitOrder(double price,double size,double spread,double takeprofit,double stoploss)
  {

  }
//+------------------------------------------------------------------+

OrderCount CountOrders(string symbol,int magicNumber)
  {
   OrderCount tmp={0,0,0,0};
   int total= OrdersTotal();
   for(int i=total-1;i>=0;i--)
     {

      if(OrderSelect(i,SELECT_BY_POS))
        {
         if(OrderSymbol()==symbol && OrderMagicNumber()==magicNumber)
           {
            int type=OrderType();

            bool result=false;
            RefreshRates();
            switch(type)
              {
               //Close opened long positions
               case OP_BUY:
                  tmp.buy++;
                  break;

               case OP_SELL:
                  tmp.sell++;
                  break;

               case OP_BUYSTOP:
                  tmp.buystop++;
                  break;

               case OP_SELLSTOP:
                  tmp.sellstop++;
                  break;

              }

           }
        }

     }
   return tmp;

  }
//+------------------------------------------------------------------+
