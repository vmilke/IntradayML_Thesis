//Appendix III  
//The connector-1 to Meta Trader-5.

//+--------------------------------------------------------------------------------------------+
//|                                        TempletBook MQL5-2.mq5                                     |
//|   Based checking system and Sending buying and selling Orders            |
//|   flag TradeSygnalBuy & TradeSygnalSell  shoud be from ML model      |
//|          Futures contract:  ED (EURO/USD)   and others        	         |
//+--------------------------------------------------------------------------------------------+
//--- input parameters 
input double Lot = 1;
input int EA_Magic = 20016;
input double spreadLevel = 5.0;
input double StopLoss = 0.01;
input double Profit = 0.01;
input ulong Deviation = 10;    // In points
input ENUM_TIMEFRAMES PPeriod = PERIOD_H1;

input int numberBarOpenPosition = 5;
input int numberBarStopPosition = 5;
bool flagStopLoss = false;
// Handles
int handleIMA18;
int handleIMA28;
int handleIWMA5;
int handleIWMA8;
double MA18Buffer[];
double MA28Buffer[];
double WMA5Buffer[];
double WMA8Buffer[];
//+------------------------------------------------------------------+
//| OnCheckTradeInit – first checking                            |
//+------------------------------------------------------------------+
int OnCheckTradeInit()
  {
   if( (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL )   
   {
      int mb = MessageBox("Start it?", "Message Box", MB_YESNO|MB_ICONQUESTION);
      if( mb == IDNO )  return(0);  // "No" button
   }
   if( !TerminalInfoInteger(TERMINAL_CONNECTED) )  
   {
      Alert("No connection to the trade server");
      return(0);
   }
   else
   {
      if( !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) )   
      {
         Alert("Trade for this account is prohibited");  
         return(0);
      }
   }
   if( !AccountInfoInteger(ACCOUNT_TRADE_EXPERT) ) 
   {
      Alert("Trade with the help of experts for the account is prohibited");  
      return(0);
   }
   if( Lot < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN) ||        // Lot < Min сделки
       Lot > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)           //  Lot > MAX
     )   
   {
      Alert("Lot is not correct!");
      return(0);
   }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                      |
//+------------------------------------------------------------------+
int OnInit()
  {
   handleIMA18 = iMA( _Symbol, PPeriod, 18, 0, MODE_EMA, PRICE_CLOSE);
   handleIMA28 = iMA( _Symbol, PPeriod, 28, 0, MODE_EMA, PRICE_CLOSE);
   handleIWMA5 = iMA( _Symbol, PPeriod, 5, 0, MODE_LWMA, PRICE_CLOSE);
   handleIWMA8 = iMA( _Symbol, PPeriod, 8, 0, MODE_LWMA, PRICE_CLOSE);
   
   return( OnCheckTradeInit() );
//--- create timer
//   EventSetTimer(20);
//   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
//   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| OnCheckTradeTick – Second checking                     |
//+------------------------------------------------------------------+
int OnCheckTradeTick()
   {
      if( !TerminalInfoInteger(TERMINAL_CONNECTED) )  
      {
         Alert("No connection to the trade server");
         return(0);
      }
      if( !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) )
      {
         Alert("Authomatic trading is turn off ");
         return(0);
      }
      if( !MQLInfoInteger(MQL_TRADE_ALLOWED) )
      {
         Alert("It is turn off", __FILE__); 
         return(0);
      }
      if( (ENUM_ACCOUNT_STOPOUT_MODE)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE) == ACCOUNT_STOPOUT_MODE_PERCENT )    // ACCOUNT_MARGIN_SO_MODE - равен либо ACCOUNT_STOPOUT_MODE_PERCENT либо ACCOUNT_STOPOUT_MODE_MONEY
      {
         if( AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) != 0   &&    
             AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) <= AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL)
             // (Margin Call)
           )
         {
            Alert("Margin Call !!");
            return(0);
         }
      }
      if( (ENUM_ACCOUNT_STOPOUT_MODE)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE) == ACCOUNT_STOPOUT_MODE_MONEY )
      {
         if( AccountInfoDouble(ACCOUNT_EQUITY) <= AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL) )
             // (Margin Call)
         {
            Alert("Margin Call !!");
            return(0);
         }
      }
      if( (ENUM_ACCOUNT_STOPOUT_MODE)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE) == ACCOUNT_STOPOUT_MODE_PERCENT )
      {
         if( AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) != 0   &&    
             AccountInfoDouble(ACCOUNT_MARGIN_LEVEL) <= AccountInfoDouble(ACCOUNT_MARGIN_SO_SO)
           )
         {
            Alert("Stop Out !!");
            return(0);
         }
      }
      if( (ENUM_ACCOUNT_STOPOUT_MODE)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE) == ACCOUNT_STOPOUT_MODE_MONEY )
      {
         if( AccountInfoDouble(ACCOUNT_EQUITY) <= AccountInfoDouble(ACCOUNT_MARGIN_SO_SO) )
         {
            Alert("Stop Out !!");
            return(0);
         }
      }
      // checking bouble marging
      double margin;
      MqlTick last_tick;      
      ResetLastError(); 
      if( SymbolInfoTick(Symbol(), last_tick) )    
      {
         if( OrderCalcMargin(ORDER_TYPE_BUY, Symbol(), Lot, last_tick.ask, margin) )    
         {
            if( margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE) )    
            {
               Alert("Not enough money in the account");
               return(0);
            }
         }
      }
      else
      {
         Print( GetLastError() 
      }
//      double _spread = SymbolInfoInteger(Symbol(), SYMBOL_SPREAD) * MathPow(10, -SymbolInfoInteger(Symbol(), SYMBOL_DIGITS) ) / MathPow(10, -4);
      if( (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL )
      {
         Alert("We have limits for trading operation");
         return(0);
      }
      if( Bars(Symbol(), 0) < 100 )
      {
         Alert("In the chart little bars, Expert will not work!");
         return(0);
      }
      return(1);      
   }  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
      // Second checking go on
      if( !OnCheckTradeTick() )
      {
         return;
      }
      static datetime last_time;
      datetime last_bar_time = (datetime)SeriesInfoInteger( Symbol(), Period(), SERIES_LASTBAR_DATE );   
      if( last_time != last_bar_time )
      {
         last_time = last_bar_time;
      }
      else
      {
         return;
      }
      static datetime last_time_pause;
      datetime last_bar_time_pause = (datetime)SeriesInfoInteger( Symbol(), PERIOD_H1, SERIES_LASTBAR_DATE );   
      if( last_time_pause != last_bar_time_pause )
      {
         last_time_pause = last_bar_time_pause;
         flagStopLoss = false;
      }
      if( flagStopLoss == true ) return;
      bool BuyOpened  = false;
      bool SellOpened = false;
      if( PositionSelect(_Symbol) == true )
      {
         if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY )
         {
            BuyOpened = true;
         }
         else if( PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL )
         {
            SellOpened = true;
         }
      }
      MqlRates mrate[];    
      ResetLastError();
      if( CopyRates(Symbol(), Period(), 0, numberBarStopPosition, mrate) < 0 )  
      {
         Print(GetLastError());
         return;
      }
      ArraySetAsSeries(mrate, true);
      // Start the Trading 
          bool TradeSignalBuy  = false;
      bool TradeSignalSell = false;
      TradeSignalBuy  = OnTradeSignalBuy();
      TradeSignalSell = OnTradeSignalSell();
      bool TradeSignalBuyStop    = false;
      bool TradeSignalSellStop   = false; 
      TradeSignalBuyStop   = OnTradeSignalBuyStop(mrate);
      TradeSignalSellStop  = OnTradeSignalSellStop(mrate);

      MqlTradeRequest mrequest;           
      MqlTradeCheckResult check_result;   
      MqlTradeResult mresult;             
      MqlTick latest_price;
      if( !SymbolInfoTick(_Symbol, latest_price) )             
      {
         Alert("Have not received last data: ", GetLastError());
         return;
      }
      // ----------------------------------
      //  BUYING
      if(   TradeSignalBuy == true    &&     
            BuyOpened == false
        )
      {
         //---------------
         if( ((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_EXEMODE)) == SYMBOL_TRADE_EXECUTION_INSTANT )      
         {
            ZeroMemory( mrequest );    
            mrequest.action   = TRADE_ACTION_DEAL;   
            mrequest.symbol   = _Symbol;
            mrequest.volume   = Lot;
            mrequest.price    = NormalizeDouble(latest_price.ask, _Digits);            
            mrequest.sl       = NormalizeDouble(latest_price.bid - StopLoss, _Digits); 
            mrequest.tp       = NormalizeDouble(latest_price.ask + Profit, _Digits);   
            mrequest.deviation= Deviation;                                             
            mrequest.type     = ORDER_TYPE_BUY;
            mrequest.type_filling = ORDER_FILLING_FOK            
            ZeroMemory(check_result);
            ZeroMemory(mresult);
            if( !OrderCheck(mrequest, check_result) )    
            {
               if( check_result.retcode == 10014 ) Alert("Wrong volume");
               if( check_result.retcode == 10015 ) Alert("Wrong price");
               if( check_result.retcode == 10016 ) Alert("Wrong stop-loss");
               if( check_result.retcode == 10019 ) Alert("No money");
               return;
            }
            else     // everything is OK
            {
               if( OrderSend(mrequest, mresult) )        // send order
               {
                  if( mresult.retcode == 10009  ||       
                      mresult.retcode == 10008)          
                  {
                     Print("Price=", mresult.price);     
                  }
                  else
                  { 
                     if( mresult.retcode == 1004 )     // Reqouta 
                     {
                        Print("Requota bid ", mresult.bid);
                        Print("Requota ask ", mresult.ask);
                     }
                     else
                     {
                        Print("Retcode ", mresult.retcode);
                     }
                  }
               }
               else  // the order havn’t sent
               {
                  Print("Retcode ", mresult.retcode);
               }
            }
         }
         //---------------
         if( ((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_EXEMODE)) == SYMBOL_TRADE_EXECUTION_EXCHANGE )                
            {
            ZeroMemory(mrequest);    
            mrequest.action   = TRADE_ACTION_DEAL;   
            mrequest.symbol   = _Symbol;
            mrequest.volume   = Lot;
            mrequest.type     = ORDER_TYPE_BUY;
            mrequest.type_filling = ORDER_FILLING_FOK;               
            ZeroMemory(check_result);
            ZeroMemory(mresult);
            if( !OrderCheck(mrequest, check_result)            {
               if( check_result.retcode == 10014 ) Alert("Wrong volume");
               if( check_result.retcode == 10019 ) Alert("No money");
               return;
            }
            else     // everything is ok
            {
               if( OrderSend(mrequest, mresult) )        // send the order
               {
                  if( mresult.retcode == 10009  ||       
                      mresult.retcode == 10008)          
                  {
                     //----------------
                     ZeroMemory(mrequest);
                     mrequest.action = TRADE_ACTION_SLTP;   
                     mrequest.symbol   = _Symbol;
                     mrequest.sl       = NormalizeDouble(mresult.price - StopLoss, _Digits); 
                     mrequest.tp       = NormalizeDouble(mresult.price + Profit, _Digits);   
                     ZeroMemory(check_result);
                     ZeroMemory(mresult);
                     if( !OrderCheck(mrequest, check_result) )    
                     {
                        if( check_result.retcode == 10015 ) Alert("Wrong price");
                        if( check_result.retcode == 10016 ) Alert("Wrong stop-loss");
                        return;
                     }
                     else
                     {
                        if( OrderSend(mrequest, mresult) )
                        {
                           if( mresult.retcode == 10009  ||       
                               mresult.retcode == 10008)          
                           {
                              Print("SL ", mrequest.sl, "TP ", mrequest.tp);     
                           }  
                           else   
                           {
                              Print("Retcode ", mresult.retcode);                           
                           }
                        }
                        else  
                        {
                           Print("Retcode ", mresult.retcode);
                        }
                     }
                  }
                  else  
                  {
                     Print("Retcode ", mresult.retcode);
                  }
               }      
               else  
               {
                  Print("Retcode ", mresult.retcode);
               }
            }   
         }
      }

// SELL-STOP order
      if(   TradeSignalSellStop == true    &&     
            SellOpened == true
        )
      {
         if( ((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_EXEMODE)) == SYMBOL_TRADE_EXECUTION_INSTANT )                
         {
            ZeroMemory( mrequest );    
            mrequest.action   = TRADE_ACTION_DEAL;   
            mrequest.symbol   = _Symbol;
            mrequest.volume   = Lot;
            mrequest.price    = NormalizeDouble(latest_price.ask, _Digits);            // buy by ask
            mrequest.sl       = NormalizeDouble(0.0, _Digits);    
            mrequest.tp       = NormalizeDouble(0.0, _Digits);    
            mrequest.deviation= Deviation;                                             
            mrequest.type     = ORDER_TYPE_BUY;
            mrequest.type_filling = ORDER_FILLING_FOK;                  
            ZeroMemory(check_result);
            ZeroMemory(mresult);
            if( !OrderCheck(mrequest, check_result) )    
            {
               if( check_result.retcode == 10014 ) Alert("Wrong volume");
               if( check_result.retcode == 10015 ) Alert("Wrone price");
               if( check_result.retcode == 10016 ) Alert("Wrong stop-loss");
               if( check_result.retcode == 10019 ) Alert("No money");
               return;
            }
            else     
            {
               if( OrderSend(mrequest, mresult) )        
               {
                  if( mresult.retcode == 10009  ||       
                      mresult.retcode == 10008)          
                  {
                     Print("Price=", mresult.price);     
                  }
                  else
                  { 
                     if( mresult.retcode == 1004 )     
                     {
                        Print("Requota bid ", mresult.bid);
                        Print("Requota ask ", mresult.ask);
                     }
                     else
                     {
                        Print("Retcode ", mresult.retcode);
                     }
                  }
               }
               else  
               {
                  Print("Retcode ", mresult.retcode);
               }
            }
         }
         //---------------
         if( ((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_EXEMODE)) == SYMBOL_TRADE_EXECUTION_EXCHANGE )                
         {
            ZeroMemory(mrequest);    
            mrequest.action   = TRADE_ACTION_DEAL;   
            mrequest.symbol   = _Symbol;
            mrequest.volume   = Lot;
            mrequest.type     = ORDER_TYPE_BUY;
            mrequest.type_filling = ORDER_FILLING_FOK;   
            ZeroMemory(check_result);
            ZeroMemory(mresult);
            if( !OrderCheck(mrequest, check_result) )                {
               if( check_result.retcode == 10014 ) Alert("Wrong volume");
               if( check_result.retcode == 10019 ) Alert("No money");
               return;
            }
            else     // ok
            {
               if( OrderSend(mrequest, mresult) )        
               {
                  if( mresult.retcode == 10009  ||       
                      mresult.retcode == 10008)          
                  {
                     Print("Price", mrequest.price);     
                  }  
                  else   
                  {
                     Print("Retcode ", mresult.retcode);                           
                  }
               }
               else  
               {
                  Print("Retcode ", mresult.retcode);
               }
            }
         }
         //----------------
      }
      //-------------------------------------------------------
      
     // SELLING
      if(   TradeSignalSell == true    &&     
            SellOpened == false
        )
      {
         //---------------
         if( ((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_EXEMODE)) == SYMBOL_TRADE_EXECUTION_INSTANT )                
         {
            ZeroMemory( mrequest );    
            mrequest.action   = TRADE_ACTION_DEAL;   
            mrequest.symbol   = _Symbol;
            mrequest.volume   = Lot;
            mrequest.price    = NormalizeDouble(latest_price.bid, _Digits);            // sell by bid
            mrequest.sl       = NormalizeDouble(latest_price.ask + StopLoss, _Digits); 
            mrequest.tp       = NormalizeDouble(latest_price.bid - Profit, _Digits);   
            mrequest.deviation= Deviation;                                             
            mrequest.type     = ORDER_TYPE_SELL;
            mrequest.type_filling = ORDER_FILLING_FOK;                  
            ZeroMemory(check_result);
            ZeroMemory(mresult);
            if( !OrderCheck(mrequest, check_result) )    
            {
               if( check_result.retcode == 10014 ) Alert("Wrong volume");
               if( check_result.retcode == 10015 ) Alert("Wrong price");
               if( check_result.retcode == 10016 ) Alert("Wrong stop-loss");
               if( check_result.retcode == 10019 ) Alert("No money");
               return;
            }
            else     // ok
            {
               if( OrderSend(mrequest, mresult) )        
               {
                  if( mresult.retcode == 10009  ||       
                      mresult.retcode == 10008)          
                  {
                     Print("Price=", mresult.price);     
                  }
                  else
                  { 
                     if( mresult.retcode == 1004 )     
                     {
                        Print("Requota bid ", mresult.bid);
                        Print("Requota ask ", mresult.ask);
                     }
                     else
                     {
                        Print("Retcode ", mresult.retcode);
                     }
                  }
               }
               else  
               {
                  Print("Retcode ", mresult.retcode);
               }
            }
         }
         //---------------
         if( ((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_EXEMODE)) == SYMBOL_TRADE_EXECUTION_EXCHANGE )                
         {
            ZeroMemory(mrequest);    
            mrequest.action   = TRADE_ACTION_DEAL;   
            mrequest.symbol   = _Symbol;
            mrequest.volume   = Lot;
            mrequest.type     = ORDER_TYPE_SELL;
            mrequest.type_filling = ORDER_FILLING_FOK;              
            ZeroMemory(check_result);
            ZeroMemory(mresult);
            if( !OrderCheck(mrequest, check_result) )    
            {
               if( check_result.retcode == 10014 ) Alert("Wrong volume");
               if( check_result.retcode == 10019 ) Alert("No money");
               return;
            }
            else     
            {
               if( OrderSend(mrequest, mresult) )        
               {
                  if( mresult.retcode == 10009  ||       
                      mresult.retcode == 10008)          
                  {
                     //----------------
                     ZeroMemory(mrequest);
                     mrequest.action = TRADE_ACTION_SLTP;   
                     mrequest.symbol   = _Symbol;
                     mrequest.sl       = NormalizeDouble(mresult.price + StopLoss, _Digits); // changing stop-loss
                     mrequest.tp       = NormalizeDouble(mresult.price - Profit, _Digits);   // changing take-profit
                     ZeroMemory(check_result);
                     ZeroMemory(mresult);
                     if( !OrderCheck(mrequest, check_result) )    
                     {
                        if( check_result.retcode == 10015 ) Alert("Wrong price");
                        if( check_result.retcode == 10016 ) Alert("Wrong stop-loss");
                        return;
                     }
                     else
                     {
                        if( OrderSend(mrequest, mresult) )
                        {
                           if( mresult.retcode == 10009  ||       
                               mresult.retcode == 10008)          
                           {
                              Print("SL ", mrequest.sl, "TP ", mrequest.tp);     
                           }  
                           else   
                           {
                              Print("Retcode ", mresult.retcode);                           
                           }
                        }
                        else  
                        {
                           Print("Retcode ", mresult.retcode);
                        }
                     }
                     //-------------------
                  }
                  else  
                  {
                     Print("Retcode ", mresult.retcode);
                  }
               }      
               else  
               {
                  Print("Retcode ", mresult.retcode);
               }
            }   
         }
      }
      //-------------------------------------------------------
      
    // BUY-STOP 
      if(   TradeSignalBuyStop == true    &&     
            BuyOpened == true
        )
      {
         //---------------
         if( ((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_EXEMODE)) == SYMBOL_TRADE_EXECUTION_INSTANT )                
         {
            ZeroMemory( mrequest );    
            mrequest.action   = TRADE_ACTION_DEAL;   
            mrequest.symbol   = _Symbol;
            mrequest.volume   = Lot;
            mrequest.price    = NormalizeDouble(latest_price.bid, _Digits);            // sell by bid
            mrequest.sl       = NormalizeDouble(0.0, _Digits);    
            mrequest.tp       = NormalizeDouble(0.0, _Digits);    
            mrequest.deviation= Deviation;                                             
            mrequest.type     = ORDER_TYPE_SELL;
            mrequest.type_filling = ORDER_FILLING_FOK;                  
            ZeroMemory(check_result);
            ZeroMemory(mresult);
            if( !OrderCheck(mrequest, check_result) )    
            {
               if( check_result.retcode == 10014 ) Alert("Wrong volume");
               if( check_result.retcode == 10015 ) Alert("Wrong price");
               if( check_result.retcode == 10016 ) Alert("Wrong stop-loss");
               if( check_result.retcode == 10019 ) Alert("No money");
               return;
            }
            else     
            {
               if( OrderSend(mrequest, mresult) )        
               {
                  if( mresult.retcode == 10009  ||       
                      mresult.retcode == 10008)          
                  {
                     Print("Price=", mresult.price);     
                  }
                  else
                  { 
                     if( mresult.retcode == 1004 )                          {
                        Print("Requota bid ", mresult.bid);
                        Print("Requota ask ", mresult.ask);
                     }
                     else
                     {
                        Print("Retcode ", mresult.retcode);
                     }
                  }
               }
               else  
               {
                  Print("Retcode ", mresult.retcode);
               }
            }
         }
         //---------------
         if( ((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_EXEMODE)) == SYMBOL_TRADE_EXECUTION_EXCHANGE )                
         {
            ZeroMemory(mrequest);    
            mrequest.action   = TRADE_ACTION_DEAL;   
            mrequest.symbol   = _Symbol;
            mrequest.volume   = Lot;
            mrequest.type     = ORDER_TYPE_SELL;
            mrequest.type_filling = ORDER_FILLING_FOK;               
            ZeroMemory(check_result);
            ZeroMemory(mresult);
            if( !OrderCheck(mrequest, check_result) )    
            {
               if( check_result.retcode == 10014 ) Alert("wrong volume");
               if( check_result.retcode == 10019 ) Alert("No money");
               return;
            }
            else     
            {
               if( OrderSend(mrequest, mresult) )        
               {
                  if( mresult.retcode == 10009  ||       
                      mresult.retcode == 10008)          
                  {
                     Print("Price ", mresult.price);     
                  }
                  else  
                  {
                     Print("Retcode ", mresult.retcode);
                  }
               }      
               else  
               {
                  Print("Retcode ", mresult.retcode);
               }
            }   
         }
      }
  }


//+------------------------------------------------+
//| Trade function                                      |
//|                                                                  |
//|        creating flagStopLoss                    |
//+-------------------------------------------------+
void OnTrade()    
  {
   static int _deals;
   ulong _ticket = 0;
   
   if( HistorySelect(0, TimeCurrent()) )     
   {
      int i = HistoryDealsTotal() - 1;         
      if( _deals != i )
      {
         _deals = i;
      }
      else
      {
         return;  
      }
      if( ( _ticket = HistoryDealGetTicket(i)) > 0 )        
      {
         string _comment = HistoryDealGetString( _ticket, DEAL_COMMENT);   // comments
         if( StringFind( _comment, "sl", 0) != -1 )      // StringFind "sl" in the comments
         {
            flagStopLoss = true;    
         }
      }
   }
  }

//+--------------------------------------------+
//| Trade system part-1                       |
//|   OnTradeSignalBuy – buy signal  |
//|   It will be changed !!!!                  |
//+------------------------------------------+
bool OnTradeSignalBuy()
  {
   bool flagBuy = false;
   if( CopyBuffer(handleIMA18, 0, 0, numberBarOpenPosition, MA18Buffer) < 0 )    return false;
   if( CopyBuffer(handleIMA28, 0, 0, numberBarOpenPosition, MA28Buffer) < 0 )    return false;
   if( CopyBuffer(handleIWMA5, 0, 0, numberBarOpenPosition, WMA5Buffer) < 0 )    return false;
   if( CopyBuffer(handleIWMA8, 0, 0, numberBarOpenPosition, WMA8Buffer) < 0 )    return false;
   ArraySetAsSeries( MA18Buffer, true ); 
   ArraySetAsSeries( MA28Buffer, true );
   ArraySetAsSeries( WMA5Buffer, true );
   ArraySetAsSeries( WMA8Buffer, true );
   bool flagCross1 = false;
   bool flagCross2 = false;
   bool flagCross  = false;
   if(   WMA5Buffer[1] > MA18Buffer[1]             &&
         WMA5Buffer[1] > MA28Buffer[1]             &&
         WMA8Buffer[1] > MA18Buffer[1]             &&
         WMA8Buffer[1] > MA28Buffer[1]
     )
   {
      for( int i=2; i < numberBarOpenPosition; i++)      
      {
         if(   WMA5Buffer[i] < MA18Buffer[i]             &&
               WMA5Buffer[i] < MA28Buffer[i] 
           )      
         {
            flagCross1 = true;
         }
         if(              
               WMA8Buffer[i] < MA18Buffer[i]             &&
               WMA8Buffer[i] < MA28Buffer[i]
           )
         {
            flagCross2 = true;
         }
      }
         if( flagCross1 == true     &&    flagCross2 == true )    
         {
            flagCross = true;
         }
   }
   flagBuy = flagCross;
   return flagBuy;
  }

//+--------------------------------------------------------------+
//| Trade system part-2                                               |
//| OnTradeSignalBuyStop – signal  Buy-stop-loss  |
//|   it will be changed                                                  |
//+--------------------------------------------------------------+
bool OnTradeSignalBuyStop(MqlRates& mrate[])
  {
   bool flagBuyStop = false;
   if( CopyBuffer(handleIWMA5, 0, 0, numberBarStopPosition, WMA5Buffer) < 0 )    return false;
   if( CopyBuffer(handleIWMA8, 0, 0, numberBarStopPosition, WMA8Buffer) < 0 )    return false;
   ArraySetAsSeries( WMA5Buffer, true );
   ArraySetAsSeries( WMA8Buffer, true );
      bool flagCross  = false;
      if(   WMA5Buffer[1] < WMA8Buffer[1] )
   {
      for( int i=2; i < numberBarStopPosition; i++)      
      {
         if(   WMA5Buffer[i] > WMA8Buffer[i] )
         {
            flagCross = true;
         }
      }
   }
   double max = mrate[1].high;
   for( int i=1; i < numberBarStopPosition; i++)
   {
      if( mrate[i].high > max )     max = mrate[i].high;
   }
   if(   flagCross == true             &&
         mrate[1].high <= max          &&             
         mrate[numberBarStopPosition-1].high <= max   
     )
     {
      return flagBuyStop = true;
     }
  return flagBuyStop;
  }

//+--------------------------------------------+
//| Trade system part-3                       |
//|   OnTradeSignalSel – sell signal    |
//|   it will be changed	              |
//+--------------------------------------------+
bool OnTradeSignalSell()
  {
   bool flagSell = false;
   if( CopyBuffer(handleIMA18, 0, 0, numberBarOpenPosition, MA18Buffer) < 0 )    return false;
   if( CopyBuffer(handleIMA28, 0, 0, numberBarOpenPosition, MA28Buffer) < 0 )    return false;
   if( CopyBuffer(handleIWMA5, 0, 0, numberBarOpenPosition, WMA5Buffer) < 0 )    return false;
   if( CopyBuffer(handleIWMA8, 0, 0, numberBarOpenPosition, WMA8Buffer) < 0 )    return false;
   ArraySetAsSeries( MA18Buffer, true ); 
   ArraySetAsSeries( MA28Buffer, true );
   ArraySetAsSeries( WMA5Buffer, true );
   ArraySetAsSeries( WMA8Buffer, true );
   bool flagCross1 = false;
   bool flagCross2 = false;
   bool flagCross  = false;
      if(   WMA5Buffer[1] < MA18Buffer[1]             &&
         WMA5Buffer[1] < MA28Buffer[1]             &&
         WMA8Buffer[1] < MA18Buffer[1]             &&
         WMA8Buffer[1] < MA28Buffer[1]
     )
   {
      for( int i=2; i < numberBarOpenPosition; i++)      
      {
         if(   WMA5Buffer[i] > MA18Buffer[i]             &&
               WMA5Buffer[i] > MA28Buffer[i] 
           )      
         {
            flagCross1 = true;
         }
         if(              
               WMA8Buffer[i] > MA18Buffer[i]             &&
               WMA8Buffer[i] > MA28Buffer[i]
           )
         {
            flagCross2 = true;
         }
      }
         if( flagCross1 == true     &&    flagCross2 == true )    
         {
            flagCross = true;
         }
   }
   flagSell = flagCross;
   return flagSell;
  }

//+------------------------------------------------------------+
//| Trade system part-4                                             |
//|                                                                  	|
//| OnTradeSignalSellStop - Sell-stop-loss signal  |
//|   It will be changed              		|
//+------------------------------------------------------------+
bool OnTradeSignalSellStop(MqlRates& mrate[])
  {
   bool flagSellStop = false;
   if( CopyBuffer(handleIWMA5, 0, 0, numberBarStopPosition, WMA5Buffer) < 0 )    return false;
   if( CopyBuffer(handleIWMA8, 0, 0, numberBarStopPosition, WMA8Buffer) < 0 )    return false;
      ArraySetAsSeries( WMA5Buffer, true );
   ArraySetAsSeries( WMA8Buffer, true );
   bool flagCross  = false;
      if(   WMA5Buffer[1] > WMA8Buffer[1] )
   {
      for( int i=2; i < numberBarStopPosition; i++)      
      {
         if(   WMA5Buffer[i] < WMA8Buffer[i] )
         {
            flagCross = true;
         }
      }
   }
   double min = mrate[1].low;
   for( int i=1; i < numberBarStopPosition; i++)
   {
      if( mrate[i].low < min )     min = mrate[i].low;
   }
   if(   flagCross == true             &&
         mrate[1].low  >= min          &&             
         mrate[numberBarStopPosition-1].low  >= min   
     )
     {
      return flagSellStop = true;
     }
  return flagSellStop;
  }

//+------------------------------------------------------------------+
//| Timer function                                                   	        |
//+------------------------------------------------------------------+
void OnTimer()

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{}
//+------------------------------------------------------------------+
//| ChartEvent function                                                     |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {}
//+------------------------------------------------------------------+
//| BookEvent function                                                      |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  { }
//+------------------------------------------------------------------+
