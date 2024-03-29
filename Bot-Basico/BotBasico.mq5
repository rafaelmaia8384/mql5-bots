#property copyright "Bot básico"

//Biblioteca para facilitar as ordens
#include <Trade\Trade.mqh>

CTrade trade;
MqlTick lastTick;
MqlRates rates[];

input ulong DEVIATION_IN_POINTS = 30; //Desvio em pontos aceitavel
input double VOLUME = 1.0; //Volume de negociacao
input double TAKE_PROFIT = 100.0; //Take profit
input double STOP_LOSS = 100.0; //Stop loss

ulong magicNum = 11071986;

int handleMedia20;
int handleMedia9;
int handleMedia3;
double arrayMedia20[];
double arrayMedia9[];
double arrayMedia3[];

datetime lastbarTimeopen; 

int OnInit() {

   handleMedia20 = iMA(_Symbol, _Period, 20, 0, MODE_SMA, PRICE_CLOSE);
   handleMedia9 = iMA(_Symbol, _Period, 9, 0, MODE_SMA, PRICE_CLOSE);
   handleMedia3 = iMA(_Symbol, _Period, 3, 0, MODE_SMA, PRICE_CLOSE);
   
   if (handleMedia20 == INVALID_HANDLE || handleMedia9 == INVALID_HANDLE || handleMedia3 == INVALID_HANDLE) {
   
      Print("Erro ao iniciar medias moveis.");
      return INIT_FAILED;
   }
   
   ArraySetAsSeries(rates, true);
   ArraySetAsSeries(arrayMedia20, true);
   ArraySetAsSeries(arrayMedia9, true);
   ArraySetAsSeries(arrayMedia3, true);
   
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetDeviationInPoints(DEVIATION_IN_POINTS);
   trade.SetExpertMagicNumber(magicNum);
   
   Print("Bot iniciado.");

   return INIT_SUCCEEDED;
}



void OnDeinit(const int reason) {
   
}

void OnTick() {

   int tradingTimeValue = getTradingTimeValue();

   if (tradingTimeValue == -1) {
   
      Comment("Fora do horario de negociacao.");
   }
   else if (tradingTimeValue == 0) {
   
      Comment("Dentro do horario de negociacao.");
   
      if (isNewBar()) {
      
         if (!isOrderOpened() && !isPositionOpened()) {        

            if (!SymbolInfoTick(_Symbol, lastTick)) {
            
               Alert("Erro ao obter lastTick: ", GetLastError());
               return;
            }
            
            if (CopyRates(_Symbol, _Period, 0, 5, rates) < 0) {
            
               Alert("Erro ao copiar o MqlRates: ", GetLastError());
               return;
            }
            
            //Aqui podemos iniciar a verificacao das estrategias
            
            if (CopyBuffer(handleMedia20, 0, 0, 5, arrayMedia20) < 0 ||
                CopyBuffer(handleMedia9, 0, 0, 5, arrayMedia9) < 0 ||
                CopyBuffer(handleMedia3, 0, 0, 5, arrayMedia3) < 0) {
            
               Alert("Erro ao copiar medias moveis:", GetLastError());
               return;
            }
            
            double PRC = NormalizeDouble(lastTick.ask, _Digits);
            double SL_BUY = NormalizeDouble(PRC - STOP_LOSS, _Digits);
            double SL_SELL = NormalizeDouble(PRC + STOP_LOSS, _Digits);
            double TP_BUY = NormalizeDouble(PRC + TAKE_PROFIT, _Digits);
            double TP_SELL = NormalizeDouble(PRC - TAKE_PROFIT, _Digits);
         }
      }
   }
   else if (tradingTimeValue == 1) {
   
      Comment("Horario de fechamento.");
      
      if (isOrderOpened()) {
      
         closePendingOrders();
      }
      else if (isPositionOpened()) {
      
         closePositionedOrders();
      }
   }
}

bool isNewBar() { 

   static datetime bartime = 0;
   datetime currbarTime = iTime(_Symbol, _Period, 0); 

   if (bartime != currbarTime) { 
   
      bartime = currbarTime; 
      lastbarTimeopen = bartime; 

      return true; 
   } 

   return false; 
}

bool isPositionOpened() {

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
   
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      
      if (symbol == _Symbol && magic == magicNum) {
      
         return true;
      }
   }
   
   return false;
}

bool isOrderOpened() {

   for (int i = OrdersTotal() - 1; i >= 0; i--) {
   
      ulong ticket = OrderGetTicket(i);
      string symbol = OrderGetString(ORDER_SYMBOL);
      ulong magic = OrderGetInteger(ORDER_MAGIC);
      
      if (symbol == _Symbol && magic == magicNum) {
      
         return true;
      }
   }
   
   return false;
}

int getTradingTimeValue() {

   /*
      Horario de negociacao: da 10h00 as 16h00
      Horario de fechamento: a partir da 16h00
      
      Essa funcao retorna:
      -1 se esta fora do horario de negociacao
       0 se esta em horario de negociacao
       1 se esta em horario de fechamento
   */

   int negotiationStartHour = 10;
   int negotiationStopHour = 16;
   int negotiationClose = 17;
   
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   
   if (now.hour < negotiationStartHour) {
   
      return -1;
   }
   else if (now.hour < negotiationStopHour) {
   
      return 0;
   }
   else if (now.hour < negotiationClose) {
   
      return 1;
   }
   else {
   
      return -1;
   }
}

void closePositionedOrders() {

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
   
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      
      if (symbol == _Symbol && magic == magicNum) {
      
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         
         if (trade.PositionClose(ticket, DEVIATION_IN_POINTS)) {
         
            Print("Posicao fechada com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
         else {
         
            Print("Posicao fechada com falha. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
      }
   }
}

void closePendingOrders() {

   for (int i = OrdersTotal() - 1; i >= 0; i--) {
   
      ulong ticket = OrderGetTicket(i);
      string symbol = OrderGetString(ORDER_SYMBOL);
      ulong magic = OrderGetInteger(ORDER_MAGIC);
      
      if (symbol == _Symbol && magic == magicNum) {
         
         if (trade.OrderDelete(ticket)) {
         
            Print("Ordem deletada com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
         else {
         
            Print("Ordem deletada com falha. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
      }
   }
}