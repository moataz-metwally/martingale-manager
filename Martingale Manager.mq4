//+------------------------------------------------------------------+
//|                                           Martingale Manager.mq4 |
//|                                                  Moataz Metwally |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Moataz Metwally"
#property link "https://www.mql5.com"
#property version "1.00"
#include <Files\FileTxt.mqh>
#include <mq4-http.mqh>
#include <hash.mqh>
#include <json.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum enu_state // enumeration of named constants
{
	CHECK_STRATGEY,
	WAITING_START_TIME_BUY,
	WAITING_START_TIME_SELL,
	WAITING_LASTBAR,
	WAITING_START_PENDING_BASED_ON_LASTBAR,
	LET_MARKET_DECIDE_FIND_DIRECTION,
	COUNTER_TRADE_LOOP,
	COUNTER_TRADE_1,
	TRADE_CAP_REACH,
	FINALIZE_TRADES
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum enu_market // enumeration of named constants
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
	int year;
	int month;
	int day;
	int hour;
	int minute;
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct strategy
{
	string symbol;
	time_t start_time;					// the start time of the strategy in GMT
	time_t expire_time;					// for let market decide direction GMT time
	int lastcandle_dependant_timeframe; // for Bar dependant strategy
	int deviation_pips;
	enu_state state;
	bool enabled;
	enu_market type_market;
	double lot_size[20];
	int next_size;
	int tradeno_cap;
	int takeprofit;
	int stoploss;
	int spread_cap;
	int average_spread;
	int magic_number;
	int trades_tickets[20];
	int num_trade_tickets;
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct Config
{
	strategy s[20];
	int num_stratgies;
	int conf_version;
};

Config conf;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct OrderCount
{
	int buy;
	int sell;
	int sellstop;
	int buystop;
};

void ReadConfig()
{

	string str;
	string InpFileName = "config.json";  // file name
	string InpDirectoryName = "//Files"; // directory name

	ResetLastError();
	int file_handle = FileOpen(InpFileName, FILE_READ | FILE_BIN | FILE_ANSI);
	if (file_handle != INVALID_HANDLE)
	{
		PrintFormat("%s file is available for reading", InpFileName);
		PrintFormat("File path: %s\\Files\\", TerminalInfoString(TERMINAL_DATA_PATH));
		//--- additional variables
		int str_size;

		//--- read data from the file
		while (!FileIsEnding(file_handle))
		{
			//--- find out how many symbols are used for writing the time
			str_size = FileSize(file_handle);
			//--- read the string
			str = FileReadString(file_handle, str_size);
			//--- print the string
			PrintFormat(str);
		}
		//--- close the file
		FileClose(file_handle);
		PrintFormat("Data is read, %s file is closed", InpFileName);
	}
	else
		PrintFormat("Failed to open %s file, Error code = %d", InpFileName, GetLastError());

	JSONParser *parser = new JSONParser();
	JSONValue *jv = parser.parse(str);
	Print("json:");
	if (jv == NULL)
	{
		Print("error:" + (string)parser.getErrorCode() + parser.getErrorMessage());
	}
	else
	{

		Print("PARSED:" + jv.toString());
		if (jv.isObject())
		{
			JSONObject *jo = jv;
			int StrategiesCount = jo.getObject("Configuration").getArray("strategies").size();
			conf.num_stratgies = StrategiesCount;
			Print("Number of strategies:", StrategiesCount);
			conf.conf_version = jo.getObject("Configuration").getInt("conf_version");

			Print("Config version:", conf.conf_version);
			strategy tmp;
			for (int i = 0; i < StrategiesCount; i++)
			{

				JSONObject *StrategyJsonObj = jo.getObject("Configuration").getArray("strategies").getObject(i);

				conf.s[i].symbol = StrategyJsonObj.getString("symbol");

				conf.s[i].start_time.minute = StrategyJsonObj.getObject("start_time").getInt("minute");
				conf.s[i].start_time.hour = StrategyJsonObj.getObject("start_time").getInt("hour");
				conf.s[i].start_time.day = StrategyJsonObj.getObject("start_time").getInt("day");
				conf.s[i].start_time.month = StrategyJsonObj.getObject("start_time").getInt("month");
				conf.s[i].start_time.year = StrategyJsonObj.getObject("start_time").getInt("year");

				conf.s[i].expire_time.minute = StrategyJsonObj.getObject("expire_time").getInt("minute");
				conf.s[i].expire_time.hour = StrategyJsonObj.getObject("expire_time").getInt("hour");
				conf.s[i].expire_time.day = StrategyJsonObj.getObject("expire_time").getInt("day");
				conf.s[i].expire_time.month = StrategyJsonObj.getObject("expire_time").getInt("month");
				conf.s[i].expire_time.year = StrategyJsonObj.getObject("expire_time").getInt("year");

				if (StrategyJsonObj.getObject("lastcandle_dependant_timeframe").getInt("M15") == 1)
				{
					conf.s[i].lastcandle_dependant_timeframe = PERIOD_M15;
				}
				else if (StrategyJsonObj.getObject("lastcandle_dependant_timeframe").getInt("H1") == 1)
				{
					conf.s[i].lastcandle_dependant_timeframe = PERIOD_H1;
				}
				else if (StrategyJsonObj.getObject("lastcandle_dependant_timeframe").getInt("4H") == 1)
				{
					conf.s[i].lastcandle_dependant_timeframe = PERIOD_H4;
				}
				else if (StrategyJsonObj.getObject("lastcandle_dependant_timeframe").getInt("D1") == 1)
				{
					conf.s[i].lastcandle_dependant_timeframe = PERIOD_D1;
				}

				if (StrategyJsonObj.getObject("type_market").getInt("MARKET_EXCUTION_BUY") == 1)
				{
					conf.s[i].type_market = MARKET_EXCUTION_BUY;
				}
				else if (StrategyJsonObj.getObject("type_market").getInt("MARKET_EXCUTION_SELL") == 1)
				{
					conf.s[i].type_market = MARKET_EXCUTION_SELL;
				}
				else if (StrategyJsonObj.getObject("type_market").getInt("BAR_DEPENDANT") == 1)
				{
					conf.s[i].type_market = BAR_DEPENDANT;
				}
				else if (StrategyJsonObj.getObject("type_market").getInt("LET_MARKET_DECIDE") == 1)
				{
					conf.s[i].type_market = LET_MARKET_DECIDE;
				}

				conf.s[i].enabled = StrategyJsonObj.getBool("enabled");
				conf.s[i].deviation_pips = StrategyJsonObj.getInt("deviation_pips");
				conf.s[i].takeprofit = StrategyJsonObj.getInt("takeprofit");
				conf.s[i].tradeno_cap = StrategyJsonObj.getInt("tradeno_cap");
				conf.s[i].spread_cap = StrategyJsonObj.getInt("spread_cap");
				conf.s[i].average_spread = StrategyJsonObj.getInt("average_spread");
				conf.s[i].magic_number = StrategyJsonObj.getInt("magic_number");
				conf.s[i].stoploss = StrategyJsonObj.getInt("stoploss");

				Print("Magic:", conf.s[i].magic_number);

				JSONArray *LotSizeJsonArray = StrategyJsonObj.getArray("lot_size");
				int lot_count = LotSizeJsonArray.size();

				for (int j = 0; j < lot_count; j++)
				{

					conf.s[i].lot_size[j] = LotSizeJsonArray.getDouble(j);
					Print("lot_size[", i, "]:", conf.s[i].lot_size[j]);
				}
			}
		}
		delete jv;
	}
	delete parser;
}
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

	ReadConfig();

	/*conf.num_stratgies = 1;
	conf.s[0].average_spread = 30;
	conf.s[0].enabled = true;
	conf.s[0].start_time.year = 2019;
	conf.s[0].start_time.month = 8;
	conf.s[0].start_time.day = 7;
	conf.s[0].start_time.hour = 18;
	conf.s[0].start_time.minute = 0;
	conf.s[0].lastcandle_dependant_timeframe = PERIOD_H1;
	conf.s[0].next_size = 0;
	conf.s[0].lot_size[0] = 0.01;
	conf.s[0].lot_size[1] = 0.02;
	conf.s[0].lot_size[2] = 0.04;
	conf.s[0].lot_size[3] = 0.08;
	conf.s[0].lot_size[4] = 0.16;
	conf.s[0].lot_size[5] = 0.32;
	conf.s[0].lot_size[6] = 0.64;
	conf.s[0].lot_size[7] = 1.28;
	conf.s[0].lot_size[8] = 2.56;
	conf.s[0].lot_size[9] = 5.12;
	conf.s[0].lot_size[10] = 10.24;

	conf.s[0].symbol = "GBPJPY";
	conf.s[0].spread_cap = 50;
	conf.s[0].type_market = LET_MARKET_DECIDE;
	conf.s[0].tradeno_cap = 10;
	conf.s[0].takeprofit = 1000;
	conf.s[0].stoploss = 400;
	conf.s[0].magic_number = 26587;
	conf.s[0].deviation_pips = 500;
*/
	//--- create timer
	//EventSetMillisecondTimer(1);

	//---
	return (INIT_SUCCEEDED);
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
	for (int i = 0; i < conf.num_stratgies; i++)
	{

		processStrategy(i);
	}
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+

int counter;

void OnTimer()
{
	//---
	RefreshRates();

	counter++;
	if (counter % 2000 == 0)
	{

		// read  configuration
	}
}

void processStrategy(int id)
{
	datetime t = TimeGMT();
	strategy current_strategy = conf.s[id];
	int current_hour = TimeHour(t);
	int current_minute = TimeMinute(t);

	int current_day = TimeDay(t);
	int current_month = TimeMonth(t);
	int current_year = TimeYear(t);

	enu_state activeState = conf.s[id].state;
	string strategy_symbol = conf.s[id].symbol;
	int spread_cap = current_strategy.spread_cap;
	int magic_number = current_strategy.magic_number;
	int take_profit = current_strategy.takeprofit;
	int stop_loss = current_strategy.stoploss;
	OrderCount order_counts = CountOrders(strategy_symbol, current_strategy.magic_number);
	int bar_time_frame = current_strategy.lastcandle_dependant_timeframe;

	int CurrentTradeSize = conf.s[id].next_size;

	double StopLoss, TakeProfit, TradeSize, OpenTradeAt;
	double CounterPendingStopLoss, CounterPendingTakeProfit, CounterPendingOpenTradeAt, CounterPendingOrderTradeSize;

	if (current_strategy.enabled == false)
		return;

	RefreshRates();
	switch (activeState)
	{
		/************************************************************************************************************/
		// In this state we check on the type of the strategy based on the selected type_market.
		// MARKET_EXCUTION_BUY means that the strategy shall execute buy order once the start time has been reached regardless any other condition
		//MARKET_EXCUTION_SELL means that the strategy shall execute sell order once the start time has been reached regardless any other condition
		//BAR_DEPENDANT means that the strategy shall start first order trend based on the last bar direction and the given start time. if it was bullish, we go bullish  other wise, we go bearish.
		//LET_MARKET_DECIDE this means that the strategy will start at a certain time with two pending orders as breaking out targets. these to pending orders are apart of each other with a given gap (deviation pips).
		// if one pending order is activated then that's the right direction after that we delete the other pending order. and start the martingale loop(counter order loop).

	case CHECK_STRATGEY:
		CurrentTradeSize = 0;
		if (current_strategy.type_market == MARKET_EXCUTION_BUY)
		{

			activeState = WAITING_START_TIME_BUY;
		}
		else if (current_strategy.type_market == MARKET_EXCUTION_SELL)
		{

			activeState = WAITING_START_TIME_SELL;
		}
		else if (current_strategy.type_market == BAR_DEPENDANT)
		{

			activeState = WAITING_LASTBAR;
		}
		else if (current_strategy.type_market == LET_MARKET_DECIDE)
		{

			activeState = WAITING_START_PENDING_BASED_ON_LASTBAR;
		}

		break;
		/************************************************************************************************************/

		///Wait the start time of the strategy (based on GMT time) then check the last bar of the intended timeframe(bar_time_frame), if it is bullish, we go long, other wise, we go sell.
	case WAITING_LASTBAR:

	{

		if (current_hour == current_strategy.start_time.hour &&
			current_minute == current_strategy.start_time.minute &&
			current_day == current_strategy.start_time.day &&
			current_month == current_strategy.start_time.month &&
			current_year == current_strategy.start_time.year)
		{

			// Bullish bar
			if (iOpen(strategy_symbol, bar_time_frame, 1) <= iClose(strategy_symbol, bar_time_frame, 1))
			{

				OpenTradeAt = NormalizeDouble(Ask, Digits);
				StopLoss = NormalizeDouble(iOpen(strategy_symbol, bar_time_frame, 0) - stop_loss * Point - (current_strategy.average_spread * Point), Digits);
				TakeProfit = NormalizeDouble(take_profit * Point + iOpen(strategy_symbol, bar_time_frame, 0) + (current_strategy.average_spread * Point), Digits);
				TradeSize = current_strategy.lot_size[0];

				CounterPendingOpenTradeAt = StopLoss;
				CounterPendingStopLoss = NormalizeDouble((CounterPendingOpenTradeAt + stop_loss * Point) + (current_strategy.average_spread * Point), Digits);
				CounterPendingTakeProfit = NormalizeDouble((CounterPendingOpenTradeAt - take_profit * Point) - (current_strategy.average_spread * Point), Digits);
				CounterPendingOrderTradeSize = current_strategy.lot_size[1];

				conf.s[id].trades_tickets[conf.s[id].num_trade_tickets] = BuyOrder(strategy_symbol,
																				   OpenTradeAt,
																				   TradeSize,
																				   spread_cap,
																				   magic_number, TakeProfit, StopLoss);

				conf.s[id].num_trade_tickets++;
				//counter order
				conf.s[id].trades_tickets[conf.s[id].num_trade_tickets] = SellStopOrder(strategy_symbol,
																						CounterPendingOpenTradeAt,
																						CounterPendingOrderTradeSize,
																						spread_cap,
																						magic_number, CounterPendingTakeProfit, CounterPendingStopLoss);
				conf.s[id].num_trade_tickets++;
			}
			else // Bearish bar
			{

				OpenTradeAt = NormalizeDouble(Bid, Digits);
				StopLoss = NormalizeDouble(iOpen(strategy_symbol, bar_time_frame, 0) + stop_loss * Point + (current_strategy.average_spread * Point), Digits);
				TakeProfit = NormalizeDouble(iOpen(strategy_symbol, bar_time_frame, 0) - take_profit * Point - (current_strategy.average_spread * Point), Digits);
				TradeSize = current_strategy.lot_size[0];

				CounterPendingOpenTradeAt = StopLoss;
				CounterPendingStopLoss = NormalizeDouble((CounterPendingOpenTradeAt - stop_loss * Point) - (current_strategy.average_spread * Point), Digits);
				CounterPendingTakeProfit = NormalizeDouble((CounterPendingOpenTradeAt + take_profit * Point) + (current_strategy.average_spread * Point), Digits);
				CounterPendingOrderTradeSize = current_strategy.lot_size[1];

				conf.s[id].trades_tickets[conf.s[id].num_trade_tickets] = SellOrder(strategy_symbol,
																					OpenTradeAt,
																					TradeSize,
																					spread_cap,
																					magic_number, TakeProfit, StopLoss);
				conf.s[id].num_trade_tickets++;
				//counter order
				conf.s[id].trades_tickets[conf.s[id].num_trade_tickets] = BuyStopOrder(strategy_symbol,
																					   CounterPendingOpenTradeAt,
																					   CounterPendingOrderTradeSize,
																					   spread_cap,
																					   magic_number, CounterPendingTakeProfit, CounterPendingStopLoss);
				conf.s[id].num_trade_tickets++;
			}

			// Go to the Counter Trade Loop state
			CurrentTradeSize = 2;

			activeState = COUNTER_TRADE_LOOP;
		}

		break;
	}

	/************************************************************************************************************/
	// Wait till the start_time to be reached (GMT based) then go Long blindly with the counter pending order
	case WAITING_START_TIME_BUY:

		if (current_hour == current_strategy.start_time.hour &&
			current_minute == current_strategy.start_time.minute &&
			current_day == current_strategy.start_time.day &&
			current_month == current_strategy.start_time.month &&
			current_year == current_strategy.start_time.year)
		{

			OpenTradeAt = NormalizeDouble(Ask, Digits);
			StopLoss = NormalizeDouble(iOpen(strategy_symbol, bar_time_frame, 0) - stop_loss * Point - (current_strategy.average_spread * Point), Digits);
			TakeProfit = NormalizeDouble(take_profit * Point + iOpen(strategy_symbol, bar_time_frame, 0) + (current_strategy.average_spread * Point), Digits);
			TradeSize = current_strategy.lot_size[0];

			CounterPendingOpenTradeAt = StopLoss;
			CounterPendingStopLoss = NormalizeDouble((CounterPendingOpenTradeAt + stop_loss * Point) + (current_strategy.average_spread * Point), Digits);
			CounterPendingTakeProfit = NormalizeDouble((CounterPendingOpenTradeAt - take_profit * Point) - (current_strategy.average_spread * Point), Digits);
			CounterPendingOrderTradeSize = current_strategy.lot_size[1];

			conf.s[id].trades_tickets[conf.s[id].num_trade_tickets] = BuyOrder(strategy_symbol,
																			   OpenTradeAt,
																			   TradeSize,
																			   spread_cap,
																			   magic_number, TakeProfit, StopLoss);
			conf.s[id].num_trade_tickets++;
			//counter order
			conf.s[id].trades_tickets[conf.s[id].num_trade_tickets] = SellStopOrder(strategy_symbol,
																					CounterPendingOpenTradeAt,
																					CounterPendingOrderTradeSize,
																					spread_cap,
																					magic_number, CounterPendingTakeProfit, CounterPendingStopLoss);
			conf.s[id].num_trade_tickets++;
			CurrentTradeSize = 2;
			activeState = COUNTER_TRADE_LOOP;
		}

		break;
	/************************************************************************************************************/
	// Wait till the start_time to be reached (GMT based) then go Short blindly with the counter pending order.
	case WAITING_START_TIME_SELL:

		if (current_hour == current_strategy.start_time.hour &&
			current_minute == current_strategy.start_time.minute &&
			current_day == current_strategy.start_time.day &&
			current_month == current_strategy.start_time.month &&
			current_year == current_strategy.start_time.year)
		{

			OpenTradeAt = NormalizeDouble(Bid, Digits);
			StopLoss = NormalizeDouble(iOpen(strategy_symbol, bar_time_frame, 0) + stop_loss * Point + (current_strategy.average_spread * Point), Digits);
			TakeProfit = NormalizeDouble(iOpen(strategy_symbol, bar_time_frame, 0) - take_profit * Point - (current_strategy.average_spread * Point), Digits);
			TradeSize = current_strategy.lot_size[0];

			CounterPendingOpenTradeAt = StopLoss;
			CounterPendingStopLoss = NormalizeDouble((CounterPendingOpenTradeAt - stop_loss * Point) - (current_strategy.average_spread * Point), Digits);
			CounterPendingTakeProfit = NormalizeDouble((CounterPendingOpenTradeAt + take_profit * Point) + (current_strategy.average_spread * Point), Digits);
			CounterPendingOrderTradeSize = current_strategy.lot_size[1];

			conf.s[id].trades_tickets[conf.s[id].num_trade_tickets] = SellOrder(strategy_symbol,
																				OpenTradeAt,
																				TradeSize,
																				spread_cap,
																				magic_number, TakeProfit, StopLoss);
			conf.s[id].num_trade_tickets++;
			//counter order
			conf.s[id].trades_tickets[conf.s[id].num_trade_tickets] = BuyStopOrder(strategy_symbol,
																				   CounterPendingOpenTradeAt,
																				   CounterPendingOrderTradeSize,
																				   spread_cap,
																				   magic_number, CounterPendingTakeProfit, CounterPendingStopLoss);
			conf.s[id].num_trade_tickets++;
			CurrentTradeSize = 2;
			activeState = COUNTER_TRADE_LOOP;
		}

		break;
	/************************************************************************************************************/
	// Wait till the start_time to be reached (GMT based) then start two pending orders with the given gap(2* deviation_pips).
	case WAITING_START_PENDING_BASED_ON_LASTBAR:
		if (current_hour == current_strategy.start_time.hour &&
			current_minute == current_strategy.start_time.minute &&
			current_day == current_strategy.start_time.day &&
			current_month == current_strategy.start_time.month &&
			current_year == current_strategy.start_time.year)
		{

			double SellPendingStopLoss, SellPendingTakeProfit, SellPendingOpenTradeAt, SellPendingOrderTradeSize;
			double BuyPendingStopLoss, BuyPendingTakeProfit, BuyPendingOpenTradeAt, BuyPendingOrderTradeSize;

			SellPendingOpenTradeAt = NormalizeDouble(iOpen(strategy_symbol, bar_time_frame, 0) - current_strategy.deviation_pips * Point, Digits);
			SellPendingStopLoss = NormalizeDouble((SellPendingOpenTradeAt + stop_loss * Point) + (current_strategy.average_spread * Point), Digits);
			SellPendingTakeProfit = NormalizeDouble((SellPendingOpenTradeAt - take_profit * Point) - (current_strategy.average_spread * Point), Digits);
			SellPendingOrderTradeSize = current_strategy.lot_size[0];

			BuyPendingOpenTradeAt = NormalizeDouble(iOpen(strategy_symbol, bar_time_frame, 0) + current_strategy.deviation_pips * Point, Digits);
			BuyPendingStopLoss = NormalizeDouble((BuyPendingOpenTradeAt - stop_loss * Point) - (current_strategy.average_spread * Point), Digits);
			BuyPendingTakeProfit = NormalizeDouble((BuyPendingOpenTradeAt + take_profit * Point) + (current_strategy.average_spread * Point), Digits);
			BuyPendingOrderTradeSize = current_strategy.lot_size[0];
			//fishing  order
			conf.s[id].trades_tickets[conf.s[id].num_trade_tickets] = SellStopOrder(strategy_symbol,
																					SellPendingOpenTradeAt,
																					SellPendingOrderTradeSize,
																					spread_cap,
																					magic_number, SellPendingTakeProfit, SellPendingStopLoss);
			conf.s[id].num_trade_tickets++;

			//fishing order
			conf.s[id].trades_tickets[conf.s[id].num_trade_tickets] = BuyStopOrder(strategy_symbol,
																				   BuyPendingOpenTradeAt,
																				   BuyPendingOrderTradeSize,
																				   spread_cap,
																				   magic_number, BuyPendingTakeProfit, BuyPendingStopLoss);
			conf.s[id].num_trade_tickets++;

			CurrentTradeSize = 1;
			activeState = LET_MARKET_DECIDE_FIND_DIRECTION;
		}

		break;
	/************************************************************************************************************/
	// wait till one of the two pending orders placed to go to the COUNTER_TRADE_LOOP ( martingale loop)
	case LET_MARKET_DECIDE_FIND_DIRECTION:
	{

		if ((order_counts.buy == 1 && order_counts.sellstop == 1) || (order_counts.sell == 1 && order_counts.buystop == 1))
		{

			DeletePendingOrders(strategy_symbol, magic_number);
			CurrentTradeSize = 1;
			activeState = COUNTER_TRADE_LOOP;
		}
		else
		{

			if (current_hour == current_strategy.expire_time.hour &&
				current_minute == current_strategy.expire_time.minute &&
				current_day == current_strategy.expire_time.day &&
				current_month == current_strategy.expire_time.month &&
				current_year == current_strategy.expire_time.year)
			{

				activeState = FINALIZE_TRADES;
			}
		}
	}

	break;

	/************************************************************************************************************/
	// Martingale counter trade loop to protect orders. counter orders are based on other order's stoploss. this state will keep checking if the tradeno_cap has been reached or not, if so, we go to TRADE_CAP_REACH state where no more protection.
	// if one of the old postions hit the takeprofit we will finalize all the trades.
	case COUNTER_TRADE_LOOP:

		// Check if the trade number cap has been reached
		if (CurrentTradeSize >= current_strategy.tradeno_cap)
		{
			activeState = TRADE_CAP_REACH;

			break;
		}
		//Print("numbertrades:",DoesStrategyHitProfit(current_strategy), " buy count", order_counts.buy, " sell count:" , order_counts.sell );

		// checking that the take profit has been achieved
		if (DoesStrategyHitProfit(conf.s[id]) && order_counts.buy == 0 && order_counts.sell == 0)
		{

			activeState = FINALIZE_TRADES;

			break;
		}
		// if there is only active buy order which means that the buy stop order is placed and sell order hit the stoploss and closed
		if (order_counts.buy == 1 && order_counts.sellstop == 0 && order_counts.buystop == 0 && order_counts.sell == 0)
		{

			CounterPendingOpenTradeAt = GetLastBuyOrderStopLoss(strategy_symbol, magic_number);
			CounterPendingStopLoss = NormalizeDouble((CounterPendingOpenTradeAt + stop_loss * Point) + (current_strategy.average_spread * Point), Digits);
			CounterPendingTakeProfit = NormalizeDouble((CounterPendingOpenTradeAt - take_profit * Point) - (current_strategy.average_spread * Point), Digits);
			CounterPendingOrderTradeSize = current_strategy.lot_size[CurrentTradeSize];

			Print("XXXXXXXXOpen Price: " + DoubleToStr(CounterPendingOpenTradeAt, 5) + ", StopLoss: " + DoubleToStr(CounterPendingStopLoss, 5) + ", Take Profit: " + DoubleToStr(CounterPendingTakeProfit, 5) + ", Lot Size: " + DoubleToStr(CounterPendingOrderTradeSize, 5) + "NextSize:", CurrentTradeSize);
			conf.s[id].trades_tickets[conf.s[id].num_trade_tickets] = SellStopOrder(strategy_symbol,
																					CounterPendingOpenTradeAt,
																					CounterPendingOrderTradeSize,
																					spread_cap,
																					magic_number, CounterPendingTakeProfit, CounterPendingStopLoss);
			conf.s[id].num_trade_tickets++;
			CurrentTradeSize++;
		}
		// if there is only active sell order which means that the sell stop order is placed and buy order hit the stoploss and closed
		else if (order_counts.sell == 1 && order_counts.buystop == 0 && order_counts.buy == 0 && order_counts.sellstop == 0)
		{

			CounterPendingOpenTradeAt = GetLastSellOrderStopLoss(strategy_symbol, magic_number);
			CounterPendingStopLoss = NormalizeDouble((CounterPendingOpenTradeAt - stop_loss * Point) - (current_strategy.average_spread * Point), Digits);
			CounterPendingTakeProfit = NormalizeDouble((CounterPendingOpenTradeAt + take_profit * Point) + (current_strategy.average_spread * Point), Digits);
			CounterPendingOrderTradeSize = current_strategy.lot_size[CurrentTradeSize];
			Print("XXXXXXXXOpen Price: " + DoubleToStr(CounterPendingOpenTradeAt, 5) + ", StopLoss: " + DoubleToStr(CounterPendingStopLoss, 5) + ", Take Profit: " + DoubleToStr(CounterPendingTakeProfit, 5) + ", Lot Size: " + DoubleToStr(CounterPendingOrderTradeSize, 5) + "NextSize:", CurrentTradeSize);

			conf.s[id].trades_tickets[conf.s[id].num_trade_tickets] = BuyStopOrder(strategy_symbol,
																				   CounterPendingOpenTradeAt,
																				   CounterPendingOrderTradeSize,
																				   spread_cap,
																				   magic_number, CounterPendingTakeProfit, CounterPendingStopLoss);
			conf.s[id].num_trade_tickets++;
			CurrentTradeSize++;
		}

		break;
	/************************************************************************************************************/
	// Close and delete all existing trades.
	case FINALIZE_TRADES:

		DeletePendingOrders(strategy_symbol, magic_number);
		CloseOrder(strategy_symbol, magic_number);

		//Print("close Orders: success trade");

		break;

		/************************************************************************************************************/
	// do nothing and wait the last trades to finish.
	case TRADE_CAP_REACH:

		Print("Last Chance :(");

		break;

	/************************************************************************************************************/
	default:

		break;
	}

	conf.s[id].state = activeState;
	conf.s[id].next_size = CurrentTradeSize;
}

int BuyOrder(string symbol, double price, double size, double spread, int magicnumber, double takeprofit, double stoploss)
{
	int ticketNo = 0;

	ticketNo = OrderSend(symbol, OP_BUY, size, price, 1, stoploss, takeprofit, "Martingale Manager", magicnumber, 0, Green);

	while (ticketNo < 0)
	{
		ticketNo = OrderSend(symbol, OP_BUY, size, price, 1, stoploss, takeprofit, "Martingale Manager", magicnumber, 0, Green);
		Sleep(20);
	}
	return ticketNo;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int SellOrder(string symbol, double price, double size, double spread, int magicnumber, double takeprofit, double stoploss)
{

	int ticketNo = 0;

	ticketNo = OrderSend(Symbol(), OP_SELL, size, price, 1, stoploss, takeprofit, "Martingale Manager", magicnumber, 0, Green);

	while (ticketNo < 0)
	{
		ticketNo = OrderSend(Symbol(), OP_SELL, size, price, 1, stoploss, takeprofit, "Martingale Manager", magicnumber, 0, Green);
		Sleep(20);
	}
	return ticketNo;
}

int BuyStopOrder(string symbol, double price, double size, double spread, int magicnumber, double takeprofit, double stoploss)
{
	int ticketNo = 0;

	ticketNo = OrderSend(Symbol(), OP_BUYSTOP, size, price, 1, stoploss, takeprofit, "Martingale Manager", magicnumber, 0, Green);

	while (ticketNo < 0)
	{
		ticketNo = OrderSend(Symbol(), OP_BUYSTOP, size, price, 1, stoploss, takeprofit, "Martingale Manager", magicnumber, 0, Green);
		Sleep(20);
	}
	return ticketNo;
}

int SellStopOrder(string symbol, double price, double size, double spread, int magicnumber, double takeprofit, double stoploss)
{
	int ticketNo = 0;

	ticketNo = OrderSend(Symbol(), OP_SELLSTOP, size, price, 1, stoploss, takeprofit, "Martingale Manager", magicnumber, 0, Green);

	while (ticketNo < 0)
	{
		ticketNo = OrderSend(Symbol(), OP_SELLSTOP, size, price, 1, stoploss, takeprofit, "Martingale Manager", magicnumber, 0, Green);
		Sleep(20);
	}

	return ticketNo;
}

void BuyLimitOrder(double price, double size, double spread, double takeprofit, double stoploss)
{
}

void SellLimitOrder(double price, double size, double spread, double takeprofit, double stoploss)
{
}

OrderCount CountOrders(string symbol, int magicNumber)
{
	OrderCount tmp;
	tmp.buy = 0;
	tmp.buystop = 0;
	tmp.sell = 0;
	tmp.sellstop = 0;
	int total = OrdersTotal();
	for (int i = total - 1; i >= 0; i--)
	{

		if (OrderSelect(i, SELECT_BY_POS))
		{
			if (OrderSymbol() == symbol && OrderMagicNumber() == magicNumber)
			{
				int type = OrderType();

				bool result = false;
				RefreshRates();
				switch (type)
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
void DeletePendingOrders(string symbol, int magicNumber)
{

	int total = OrdersTotal();
	for (int i = total - 1; i >= 0; i--)
	{

		if (OrderSelect(i, SELECT_BY_POS))
		{
			if (OrderSymbol() == symbol && OrderMagicNumber() == magicNumber)
			{
				int type = OrderType();

				bool result = false;
				RefreshRates();
				switch (type)
				{

				case OP_BUYSTOP:
					if (OrderDelete(OrderTicket()) == false)
						i--;
					break;

				case OP_SELLSTOP:
					if (OrderDelete(OrderTicket()) == false)
						i--;
					break;
				}
			}
		}
	}
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CloseOrder(string symbol, int magicNumber)
{
	int total = OrdersTotal();
	for (int i = total - 1; i >= 0; i--)
	{

		OrderSelect(i, SELECT_BY_POS);
		if (OrderSymbol() == symbol && OrderMagicNumber() == magicNumber)
		{
			int type = OrderType();

			bool result = false;
			RefreshRates();
			switch (type)
			{
			//Close opened long positions
			case OP_BUY:
				result = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 1, Red);
				break;

			//Close opened short positions
			case OP_SELL:
				result = OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 1, Red);
			}

			if (result == false)
			{
				i--;
				Sleep(1);
			}
		}
	}

	return (0);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetLastBuyOrderStopLoss(string symbol, int magicNumber)
{

	int total = OrdersTotal();

	for (int i = total - 1; i >= 0; i--)
	{

		if (OrderSelect(i, SELECT_BY_POS))
		{
			if (OrderSymbol() == symbol && OrderMagicNumber() == magicNumber)
			{
				int type = OrderType();

				bool result = false;
				RefreshRates();
				switch (type)
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
double GetLastSellOrderStopLoss(string symbol, int magicNumber)
{

	int total = OrdersTotal();

	for (int i = total - 1; i >= 0; i--)
	{

		if (OrderSelect(i, SELECT_BY_POS))
		{
			if (OrderSymbol() == symbol && OrderMagicNumber() == magicNumber)
			{
				int type = OrderType();

				bool result = false;
				RefreshRates();
				switch (type)
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool DoesStrategyHitProfit(strategy &s)
{

	//Print("Number of trades:",s.num_trade_tickets);
	for (int i = 0; i < s.num_trade_tickets; i++)
	{
		OrderSelect(s.trades_tickets[i], SELECT_BY_TICKET, MODE_HISTORY);

		if ((OrderType() == OP_BUY) && OrderClosePrice() >= OrderOpenPrice())
		{
			//Print("Number of trades[",i,"]:",s.trades_tickets[i]);
			return true;
		}
		if ((OrderType() == OP_SELL) && OrderClosePrice() <= OrderOpenPrice())
		{
			//Print("Number of trades[",i,"]:",s.trades_tickets[i]);
			return true;
		}
	}

	return false;
}
//+------------------------------------------------------------------+
