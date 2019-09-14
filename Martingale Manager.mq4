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
   COUNTER_TRADE_LOOP,
   COUNTER_TRADE_1,
   FINILIZE_TRADES
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
   int               year;
   int               month;
   int               day;
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
   double            lot_size[11];
   int               next_size;
   int               tradeno_cap;
   int               takeprofit;
   int               stoploss;
   int               spread_cap;
   int               average_spread;
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

   conf.num_stratgies=1;
   conf.s[0].average_spread=30;
   conf.s[0].enabled=true;
   conf.s[0].start_time.year=2019;
   conf.s[0].start_time.month=9;
   conf.s[0].start_time.day=1;
   conf.s[0].start_time.hour=10;
   conf.s[0].start_time.minute=0;
   conf.s[0].lastcandle_dependant_timeframe=PERIOD_H1;
   conf.s[0].next_size=0;
   conf.s[0].lot_size[0]=0.01;
   conf.s[0].lot_size[1]=0.02;
   conf.s[0].lot_size[2]=0.04;
   conf.s[0].lot_size[3]=0.08;
   conf.s[0].lot_size[4]=0.16;
   conf.s[0].lot_size[5]=0.32;
   conf.s[0].lot_size[6]=0.08;
   conf.s[0].lot_size[7]=0.16;
   conf.s[0].lot_size[8]=0.32;
   conf.s[0].lot_size[9]=0.32;
   conf.s[0].lot_size[10]=0.32;
   
   conf.s[0].symbol="GPBPJPY";
   conf.s[0].spread_cap = 50;
   conf.s[0].type_market = MARKET_EXCUTION_BUY;
   conf.s[0].tradeno_cap = 11;
   conf.s[0].takeprofit = 500;
   conf.s[0].stoploss = 200;
   conf.s[0].magic_number = 26587;
   
   
   



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
   if(counter%2000==0)
     {

      // read  configuration
     }

   for(int i=0;i<conf.num_stratgies;i++)
     {

      processStrategy(i);

     }

  }
//+------------------------------------------------------------------+

void processStrategy(int id)
  {
   datetime t=TimeGMT();
   strategy current_strategy=conf.s[id];
   int current_hour=TimeHour(t);
   int current_minute=TimeMinute(t);

   int current_day=TimeDay(t);
   int current_month=TimeMonth(t);
   int current_year=TimeYear(t);

   enu_state activeState=conf.s[id].state;
   string strategy_symbol=conf.s[id].symbol;
   int spread_cap=current_strategy.spread_cap;
   int magic_number=current_strategy.magic_number;
   int take_profit=current_strategy.takeprofit;
   int stop_loss=current_strategy.stoploss;
   OrderCount order_counts=CountOrders(strategy_symbol,current_strategy.magic_number);
   int bar_time_frame=current_strategy.lastcandle_dependant_timeframe;

   double   StopLoss,TakeProfit,TradeSize,OpenTradeAt;
   double   CounterPendingStopLoss,CounterPendingTakeProfit,CounterPendingOpenTradeAt,CounterPendingOrderTradeSize;

   if(current_strategy.enabled==false)
      return;



   switch(activeState)
     {
/************************************************************************************************************/
      case CHECK_STRATGEY:

         current_strategy.next_size=0;
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

         if(current_hour==current_strategy.start_time.hour && 
            current_minute==current_strategy.start_time.minute && 
            current_day==current_strategy.start_time.day && 
            current_month==current_strategy.start_time.month && 
            current_year==current_strategy.start_time.year
            )
           {

            // Bullish bar
            if(iOpen(strategy_symbol,bar_time_frame,1)<=iClose(strategy_symbol,bar_time_frame,1))
              {

               OpenTradeAt = NormalizeDouble(Ask, Digits);
               StopLoss    = NormalizeDouble(iOpen(strategy_symbol,bar_time_frame,0) - stop_loss * Point - (current_strategy.average_spread * Point) , Digits);
               TakeProfit  = NormalizeDouble(take_profit * Point + iOpen(strategy_symbol,bar_time_frame,0) + (current_strategy.average_spread * Point), Digits);
               TradeSize   = current_strategy.lot_size[0];


               CounterPendingOpenTradeAt=StopLoss;
               CounterPendingStopLoss    = NormalizeDouble((CounterPendingOpenTradeAt + stop_loss * Point)+ (current_strategy.average_spread * Point), Digits);
               CounterPendingTakeProfit  = NormalizeDouble((CounterPendingOpenTradeAt - take_profit * Point)- (current_strategy.average_spread * Point), Digits);
               CounterPendingOrderTradeSize=current_strategy.lot_size[1];

               BuyOrder(strategy_symbol,
                        OpenTradeAt,
                        TradeSize,
                        spread_cap,
                        magic_number,TakeProfit,StopLoss);
               //counter order
               SellStopOrder(strategy_symbol,
                             CounterPendingOpenTradeAt,
                             CounterPendingOrderTradeSize,
                             spread_cap,
                             magic_number,CounterPendingTakeProfit,CounterPendingStopLoss);

                 }else{  // Bearish bar

               OpenTradeAt = NormalizeDouble(Bid, Digits);
               StopLoss    = NormalizeDouble(iOpen(strategy_symbol,bar_time_frame,0) + stop_loss * Point + (current_strategy.average_spread * Point), Digits);
               TakeProfit  = NormalizeDouble(iOpen(strategy_symbol,bar_time_frame,0) - take_profit * Point - (current_strategy.average_spread * Point), Digits);
               TradeSize=current_strategy.lot_size[0];

               CounterPendingOpenTradeAt = StopLoss;
               CounterPendingStopLoss    = NormalizeDouble((CounterPendingOpenTradeAt - stop_loss * Point) - (current_strategy.average_spread * Point), Digits);
               CounterPendingTakeProfit  = NormalizeDouble((CounterPendingOpenTradeAt + take_profit * Point) + (current_strategy.average_spread * Point), Digits);
               CounterPendingOrderTradeSize=current_strategy.lot_size[1];

               SellOrder(strategy_symbol,
                         CounterPendingOpenTradeAt,
                         TradeSize,
                         spread_cap,
                         magic_number,TakeProfit,StopLoss);
               //counter order
               BuyStopOrder(strategy_symbol,
                            CounterPendingOpenTradeAt,
                            CounterPendingOrderTradeSize,
                            spread_cap,
                            magic_number,CounterPendingTakeProfit,CounterPendingStopLoss);

              }

            // Go to the Counter Trade Loop state
            current_strategy.next_size=2;

            activeState=COUNTER_TRADE_LOOP;

           }
         break;
        }

/************************************************************************************************************/
      case WAITING_START_TIME_BUY:

         if(current_hour==current_strategy.start_time.hour && 
            current_minute==current_strategy.start_time.minute && 
            current_day==current_strategy.start_time.day && 
            current_month==current_strategy.start_time.month && 
            current_year==current_strategy.start_time.year
            )
           {

            OpenTradeAt = NormalizeDouble(Ask, Digits);
            StopLoss    = NormalizeDouble(iOpen(strategy_symbol,bar_time_frame,0) - stop_loss * Point - (current_strategy.average_spread * Point), Digits);
            TakeProfit  = NormalizeDouble(take_profit * Point + iOpen(strategy_symbol,bar_time_frame,0) + (current_strategy.average_spread * Point), Digits);
            TradeSize   = current_strategy.lot_size[0];


            CounterPendingOpenTradeAt=StopLoss;
            CounterPendingStopLoss    = NormalizeDouble((CounterPendingOpenTradeAt + stop_loss * Point)+ (current_strategy.average_spread * Point), Digits);
            CounterPendingTakeProfit  = NormalizeDouble((CounterPendingOpenTradeAt - take_profit * Point)- (current_strategy.average_spread * Point), Digits);
            CounterPendingOrderTradeSize=current_strategy.lot_size[1];

            BuyOrder(strategy_symbol,
                     OpenTradeAt,
                     TradeSize,
                     spread_cap,
                     magic_number,TakeProfit,StopLoss);
            //counter order
            SellStopOrder(strategy_symbol,
                          CounterPendingOpenTradeAt,
                          CounterPendingOrderTradeSize,
                          spread_cap,
                          magic_number,CounterPendingTakeProfit,CounterPendingStopLoss);
            current_strategy.next_size=2;
            activeState=COUNTER_TRADE_LOOP;
           }

      break;
/************************************************************************************************************/
      case WAITING_START_TIME_SELL:

         if(current_hour==current_strategy.start_time.hour && 
            current_minute==current_strategy.start_time.minute && 
            current_day==current_strategy.start_time.day && 
            current_month==current_strategy.start_time.month && 
            current_year==current_strategy.start_time.year
            )
           {

            OpenTradeAt = NormalizeDouble(Bid, Digits);
            StopLoss    = NormalizeDouble(iOpen(strategy_symbol,bar_time_frame,0) + stop_loss * Point + (current_strategy.average_spread * Point), Digits);
            TakeProfit  = NormalizeDouble(iOpen(strategy_symbol,bar_time_frame,0) - take_profit * Point - (current_strategy.average_spread * Point), Digits);
            TradeSize=current_strategy.lot_size[0];

            CounterPendingOpenTradeAt = StopLoss;
            CounterPendingStopLoss    = NormalizeDouble((CounterPendingOpenTradeAt - stop_loss * Point) - (current_strategy.average_spread * Point), Digits);
            CounterPendingTakeProfit  = NormalizeDouble((CounterPendingOpenTradeAt + take_profit * Point) + (current_strategy.average_spread * Point), Digits);
            CounterPendingOrderTradeSize=current_strategy.lot_size[1];

            SellOrder(strategy_symbol,
                      CounterPendingOpenTradeAt,
                      TradeSize,
                      spread_cap,
                      magic_number,TakeProfit,StopLoss);
            //counter order
            BuyStopOrder(strategy_symbol,
                         CounterPendingOpenTradeAt,
                         CounterPendingOrderTradeSize,
                         spread_cap,
                         magic_number,CounterPendingTakeProfit,CounterPendingStopLoss);
            current_strategy.next_size=2;
            activeState=COUNTER_TRADE_LOOP;
           }

      break;
/************************************************************************************************************/
      case WAITING_START_PENDING_BASED_ON_LASTBAR:
         if(current_hour==current_strategy.start_time.hour && 
            current_minute==current_strategy.start_time.minute && 
            current_day==current_strategy.start_time.day && 
            current_month==current_strategy.start_time.month && 
            current_year==current_strategy.start_time.year
            )
           {

            double   SellPendingStopLoss,SellPendingTakeProfit,SellPendingOpenTradeAt,SellPendingOrderTradeSize;
            double   BuyPendingStopLoss,BuyPendingTakeProfit,BuyPendingOpenTradeAt,BuyPendingOrderTradeSize;

            SellPendingOpenTradeAt=NormalizeDouble(iOpen(strategy_symbol,bar_time_frame,0)-current_strategy.deviation_pips*Point,Digits);
            SellPendingStopLoss    = NormalizeDouble((SellPendingOpenTradeAt + stop_loss * Point) + (current_strategy.average_spread * Point), Digits);
            SellPendingTakeProfit  = NormalizeDouble((SellPendingOpenTradeAt - take_profit * Point) - (current_strategy.average_spread * Point), Digits);
            SellPendingOrderTradeSize=current_strategy.lot_size[0];

            BuyPendingOpenTradeAt=NormalizeDouble(iOpen(strategy_symbol,bar_time_frame,0)+current_strategy.deviation_pips*Point,Digits);
            BuyPendingStopLoss    = NormalizeDouble((BuyPendingOpenTradeAt - stop_loss * Point) - (current_strategy.average_spread * Point), Digits);
            BuyPendingTakeProfit  = NormalizeDouble((BuyPendingOpenTradeAt + take_profit * Point) + (current_strategy.average_spread * Point), Digits);
            BuyPendingOrderTradeSize=current_strategy.lot_size[0];
            //fishing  order
            SellStopOrder(strategy_symbol,
                          SellPendingOpenTradeAt,
                          SellPendingOrderTradeSize,
                          spread_cap,
                          magic_number,SellPendingTakeProfit,SellPendingStopLoss);

            //fishing order
            BuyStopOrder(strategy_symbol,
                         BuyPendingOpenTradeAt,
                         BuyPendingOrderTradeSize,
                         spread_cap,
                         magic_number,BuyPendingTakeProfit,BuyPendingOrderTradeSize);

            current_strategy.next_size=1;
            activeState=LET_MARKET_DECIDE_FIND_DIRECTION;
           }

      break;
/************************************************************************************************************/
      case LET_MARKET_DECIDE_FIND_DIRECTION:
        {

         if((order_counts.buy==1 && order_counts.sellstop==0) || (order_counts.sell==1 && order_counts.buystop==0))
           {

            DeletePendingOrders(strategy_symbol,magic_number);
            current_strategy.next_size=1;
            activeState=COUNTER_TRADE_LOOP;

           }

        }
      break;

/************************************************************************************************************/
      case COUNTER_TRADE_LOOP:

         if(current_strategy.next_size==current_strategy.tradeno_cap)
           {
            activeState=FINILIZE_TRADES;

            return;
           }

         // checking that the take profit has been achieved
         if(IsLastOrderProfit(strategy_symbol,magic_number) && order_counts.buy==0 && order_counts.sell==0)
           {

            activeState=FINILIZE_TRADES;
            return;

           }
         if(order_counts.buy==1 && order_counts.sellstop==0 && order_counts.buystop==0 && order_counts.sell==0)
           {

            CounterPendingOpenTradeAt = GetLastBuyOrderStopLoss(strategy_symbol,magic_number);
            CounterPendingStopLoss    = NormalizeDouble((CounterPendingOpenTradeAt + stop_loss * Point) + (current_strategy.average_spread * Point), Digits);
            CounterPendingTakeProfit  = NormalizeDouble((CounterPendingOpenTradeAt - take_profit * Point) - (current_strategy.average_spread * Point), Digits);
            CounterPendingOrderTradeSize=current_strategy.lot_size[current_strategy.next_size];

            SellStopOrder(strategy_symbol,
                          CounterPendingOpenTradeAt,
                          CounterPendingOrderTradeSize,
                          spread_cap,
                          magic_number,CounterPendingTakeProfit,CounterPendingStopLoss);
            current_strategy.next_size++;

              } else  if(order_counts.sell==1 && order_counts.buystop==0 && order_counts.buy==0 && order_counts.sellstop==0){

            CounterPendingOpenTradeAt = GetLastSellOrderStopLoss(strategy_symbol,magic_number);
            CounterPendingStopLoss    = NormalizeDouble((CounterPendingOpenTradeAt - stop_loss * Point) - (current_strategy.average_spread * Point), Digits);
            CounterPendingTakeProfit  = NormalizeDouble((CounterPendingOpenTradeAt + take_profit * Point) + (current_strategy.average_spread * Point), Digits);
            CounterPendingOrderTradeSize=current_strategy.lot_size[current_strategy.next_size];

            BuyStopOrder(strategy_symbol,
                         CounterPendingOpenTradeAt,
                         CounterPendingOrderTradeSize,
                         spread_cap,
                         magic_number,CounterPendingTakeProfit,CounterPendingStopLoss);
            current_strategy.next_size++;

           }

         break;
/************************************************************************************************************/
      case FINILIZE_TRADES:

         DeletePendingOrders(strategy_symbol,magic_number);
         CloseOrder(strategy_symbol,magic_number);
         break;
/************************************************************************************************************/
      default:

         break;

     }

   conf.s[id].state=activeState;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BuyOrder(string symbol,double price,double size,double spread,int magicnumber,double takeprofit,double stoploss)
  {
   int ticketNo=0;

   ticketNo=OrderSend(symbol,OP_BUY,size,price,1,NULL,NULL,"Martingale Manager",magicnumber,0,Green);

   while(ticketNo<0)
     {
      ticketNo=OrderSend(symbol,OP_BUY,size,price,1,NULL,NULL,"Martingale Manager",magicnumber,0,Green);
      Sleep(20);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SellOrder(string symbol,double price,double size,double spread,int magicnumber,double takeprofit,double stoploss)
  {

   int ticketNo=0;

   ticketNo=OrderSend(Symbol(),OP_SELL,size,price,1,NULL,NULL,"Martingale Manager",magicnumber,0,Green);

   while(ticketNo<0)
     {
      ticketNo=OrderSend(Symbol(),OP_SELL,size,price,1,NULL,NULL,"Martingale Manager",magicnumber,0,Green);
      Sleep(20);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BuyStopOrder(string symbol,double price,double size,double spread,int magicnumber,double takeprofit,double stoploss)
  {
   int ticketNo=0;

   ticketNo=OrderSend(Symbol(),OP_BUYSTOP,size,price,1,NULL,NULL,"Martingale Manager",magicnumber,0,Green);

   while(ticketNo<0)
     {
      ticketNo=OrderSend(Symbol(),OP_BUYSTOP,size,price,1,NULL,NULL,"Martingale Manager",magicnumber,0,Green);
      Sleep(20);
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SellStopOrder(string symbol,double price,double size,double spread,int magicnumber,double takeprofit,double stoploss)
  {
   int ticketNo=0;

   ticketNo=OrderSend(Symbol(),OP_SELLSTOP,size,price,1,NULL,NULL,"Martingale Manager",magicnumber,0,Green);

   while(ticketNo<0)
     {
      ticketNo=OrderSend(Symbol(),OP_SELLSTOP,size,price,1,NULL,NULL,"Martingale Manager",magicnumber,0,Green);
      Sleep(20);
     }

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
//|                                                                  |
//+------------------------------------------------------------------+
void DeletePendingOrders(string symbol,int magicNumber)
  {

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

               case OP_BUYSTOP:
                  if(OrderDelete(OrderTicket())==false)
                  i--;
                  break;

               case OP_SELLSTOP:
                  if(OrderDelete(OrderTicket())==false)
                  i--;
                  break;

              }

           }
        }

     }

  }
//+------------------------------------------------------------------+

int CloseOrder(string symbol,int magicNumber)
  {
   int total= OrdersTotal();
   for(int i=total-1;i>=0;i--)
     {

      OrderSelect(i,SELECT_BY_POS);
      if(OrderSymbol()==symbol && OrderMagicNumber()==magicNumber)
        {
         int type=OrderType();

         bool result=false;
         RefreshRates();
         switch(type)
           {
            //Close opened long positions
            case OP_BUY       : result=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),1,Red);
            break;

            //Close opened short positions
            case OP_SELL      : result=OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),1,Red);

           }

         if(result==false)
           {
            i--;
            Sleep(1);
           }
        }

     }

   return(0);
  }
//+------------------------------------------------------------------+

double GetLastBuyOrderStopLoss(string symbol,int magicNumber)
  {

   int total=OrdersTotal();

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
               case OP_BUY:
                  return OrderStopLoss();
                  break;

              }

           }
        }

     }

   return 0;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetLastSellOrderStopLoss(string symbol,int magicNumber)
  {

   int total=OrdersTotal();

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
               case OP_SELL:
                  return OrderStopLoss();
                  break;

              }

           }
        }

     }

   return 0;

  }
//+------------------------------------------------------------------+

bool IsLastOrderProfit(string symbol,int magicNumber)
  {

   for(int i=OrdersHistoryTotal()-1;i>=0;i--)
     {
      OrderSelect(i,SELECT_BY_POS,MODE_HISTORY);  //error was here
      if(OrderSymbol()==symbol && OrderMagicNumber()==magicNumber)
        {
         //for buy order
         if(OrderType()==OP_BUY && OrderClosePrice()>=OrderOpenPrice())
            return true;
         else
            return false;
        }
     }

   return false;

  }
//+------------------------------------------------------------------+
