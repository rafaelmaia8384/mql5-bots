/*
   Bot generico.
*/

#include <Trade\Trade.mqh>
#include "SymbolInfo.mqh"
#include "SymbolsContainer.mqh"
#include "SymbolStrategy.mqh"
#include "SymbolStrategyResult.mqh"

#define BOT_NAME "Bot-Generico"

input double MAX_CAPITAL = 0.0; //Capital maximo para compra
input int DEVIATION_POINTS = 10; //Pontos de desvio maximo
input string SYMBOLS_LIST = ""; //Lista de ativos, separados por virgula
input ulong MAGIC_NUM = 11071986; //Numero de identificacao do BOT

CTrade trade();
SymbolsContainer* symbolsContainer;
SymbolStrategy* currentSymbolStrategy;

datetime lastBarOpenTime;
bool adjustChecked;

int OnInit() {

   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetDeviationInPoints(DEVIATION_POINTS);
   trade.SetExpertMagicNumber(MAGIC_NUM);

   string symbols = SYMBOLS_LIST;
   string symbolsResult[];
   
   StringReplace(symbols, " ", "");
   StringToUpper(symbols);
   StringSplit(symbols, StringGetCharacter(",", 0), symbolsResult);
   
   if (ArraySize(symbolsResult) == 0) {
   
      ArrayResize(symbolsResult, 1, 0);
      symbolsResult[0] = _Symbol;
   }
   
   symbolsContainer = new SymbolsContainer(symbolsResult);
   
   if (symbolsContainer.checkInitSuccess()) {
   
      return INIT_SUCCEEDED;
   }
   else return INIT_FAILED;
}


void OnDeinit(const int reason) {
   
   delete symbolsContainer;
}

void OnTick() {

   int tradingTimeValue = getTradingTimeValue();
   
   if (tradingTimeValue == 0) {
   
      Comment("Fora do horario de negociacao.\n", TimeToString(TimeCurrent(), TIME_MINUTES));
   }
   else if (tradingTimeValue == 1) {
   
      Comment("Horario de ajuste.\n", TimeToString(TimeCurrent(), TIME_MINUTES));
      
      if (isOrderOpened()) {
      
         closePendingOrders();
      }
      else if (currentSymbolStrategy != NULL && isPositionOpened()) {
      
         if (!adjustChecked) {
         
            if (currentSymbolStrategy.mustAdjustTP()) {
         
               adjustChecked = true;
            
               updateCurrentTakeProfit(currentSymbolStrategy.getNewTP());
            }
         }
         
         if (currentSymbolStrategy.mustClosePositionOnAdjust()) {
         
            closePositionedOrders();
         }
      }
   }
   else if (tradingTimeValue == 2) {
   
      Comment("Horario de negociacao.\n", TimeToString(TimeCurrent(), TIME_MINUTES));
      
      if (isNewBar()) {
      
         adjustChecked = false;
      
         if (!symbolsContainer.newBar()) return;
         
         if (isPositionOpened()) {
         
            if (currentSymbolStrategy != NULL) {
            
               if (currentSymbolStrategy.mustClosePosition()) {
               
                  closePositionedOrders();
               }
            }
         }
         else {
         
            currentSymbolStrategy = symbolsContainer.getConfirmedStrategy();
         
            if (currentSymbolStrategy != NULL) {
            
               Print("currentSymbolStrategy != NULL");
            
               //Estrategia confirmada, realizar compra!
               
               SymbolStrategyResult* strategyResult = currentSymbolStrategy.getStrategyResult();
               
               double volume = 0;
               double marginFree = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
               double capital = MAX_CAPITAL > marginFree ? marginFree : MAX_CAPITAL;
                     
               while (strategyResult.getAsk() * (volume + 100.0) <= capital) {
                     
                  volume += 100.0;
               }
                     
               if (trade.Buy(volume, currentSymbolStrategy.getSymbolName(), strategyResult.getAsk(), strategyResult.getSellLoss(), strategyResult.getTakeProfit(), "")) {
                  
                  Print("### Simbolo ###: ", currentSymbolStrategy.getSymbolName());
                  Print("### Estrategia ###: ", currentSymbolStrategy.getStrategyName());
                  Print("Posicao comprada com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
               }
               else {
                     
                  Print("Falha ao comprar posicao. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
               }
            }
         }
      }
   }
}

bool isNewBar() { 

   static datetime bartime = 0;
   datetime currbarTime = iTime(_Symbol, PERIOD_D1, 0); 

   if (bartime != currbarTime) { 
   
      bartime = currbarTime; 
      lastBarOpenTime = bartime; 

      return true; 
   } 

   return false; 
}

bool isPositionOpened() {

   for (int i = 0; i < PositionsTotal(); i++) {
   
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      
      if (magic == MAGIC_NUM) {
      
         return true;
      }
   }
   
   return false;
}

double getCurrentPositionProfit() {

   for (int i = 0; i < PositionsTotal(); i++) {
   
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      
      if (magic == MAGIC_NUM) {
      
         return PositionGetDouble(POSITION_PROFIT);
      }
   }
   
   return 0.0;
}


bool isOrderOpened() {

   for (int i = 0; i < OrdersTotal(); i++) {
   
      ulong ticket = OrderGetTicket(i);
      ulong magic = OrderGetInteger(ORDER_MAGIC);
      
      if (magic == MAGIC_NUM) {
      
         return true;
      }
   }
   
   return false;
}

int getTradingTimeValue() {

   /*
      Horario de ajuste: das 10h00 as 17h50
      Horario de fechamento: das 17h50 as 17h55h
      
      Essa funcao retorna:
      0 Fora do horario de negociacao
      1 Horario de ajuste
      2 Horario de fechamento
   */
   
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   
   if (now.hour < 10) {
   
      return 0;
   }
   else if (now.hour <= 17) {
   
      if (now.hour < 17) return 1;
      else if (now.hour == 17 && now.min < 50) return 1;
      else if (now.min < 55) return 2;
      else return 0;
   }
   else {
   
      return 0;
   }
}

void closePositionedOrders() {

   for (int i = 0; i < PositionsTotal(); i++) {
   
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      
      if (magic == MAGIC_NUM) {
      
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         
         if (trade.PositionClose(ticket, -1)) {
         
            currentSymbolStrategy = NULL;
         
            Print("Posicao fechada com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
         else {
         
            Print("Falha ao fechar posicao. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
      }
   }
}

void closePendingOrders() {

   for (int i = 0; i < OrdersTotal(); i++) {
   
      ulong ticket = OrderGetTicket(i);
      ulong magic = OrderGetInteger(ORDER_MAGIC);
      
      if (magic == MAGIC_NUM) {
         
         if (trade.OrderDelete(ticket)) {
         
            Print("Ordem deletada com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
         else {
         
            Print("Falha ao deletar ordem. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
      }
   }
}

void updateCurrentTakeProfit(double newTP) {

   for (int i = 0; i < PositionsTotal(); i++) {
   
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      
      if (magic == MAGIC_NUM) {
      
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         double SL = PositionGetDouble(POSITION_SL);

         if (trade.PositionModify(ticket, SL, newTP)) {
         
            Print("Take profit modificado com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
         else {
            
            Print("Falha ao modificar take profit. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
         
         break;
      }
   }
}