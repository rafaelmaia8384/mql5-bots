/*
   Este bot utiliza a setup IFR2 criado pelo trader profissional Stormer. Basicamente, o funcionamento
   se da atraves da variacao do IFR. Quando o indicador for <= RSI_MIN, ativa-se o gatilho de compra. Essa
   compra deve ser efetuada nos ultimos minutos do pregao. Nos primeiros minutos do pregao do proximo dia,
   verifica-se se e' necessario fazer um ajuste no TP, colocando-o como sendo a maxima dos dois candles
   anteriores ao candle de compra. o Stop Loss fica sendo de 5% abaixo do preco de compra.
*/

#include <Trade\Trade.mqh>
#include "SymbolInfo.mqh"
#include "SymbolsContainer.mqh"

#define BOT_NAME "IFR2-Ciclico"

input int MARGIN = 10000; //Valor financeiro
input int DEVIATION_POINTS = 10; //Pontos de desvio maximo
input int MIN_RSI = 10;
input int COUNT_MA200 = 10;
input string SYMBOLS_LIST = ""; //Lista de ativos, separados por virgula
input ulong MAGIC_NUM = 11071986; //Numero de identificacao do BOT

CTrade trade();
SymbolsContainer* symbolsContainer;
SymbolInfo* currentSymbol;

bool positionModified = false;
datetime lastBarOpenTime;

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
   
   symbolsContainer = new SymbolsContainer(symbolsResult, MIN_RSI, COUNT_MA200);
   
   if (symbolsContainer.checkInitSuccess()) return INIT_SUCCEEDED;
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
      
         //Fechar ordens abertas pois nao foram executadas a tempo
         
         closePendingOrders();
      }
      else if (isPositionOpened()) {
      
         int elapsedHours = getCurrentPositionElapsedHours();
            
         if (elapsedHours >= 24 * 7) {
            
            //Fechar posicao devido ao tempo
               
            Print("Posicao fechada devido ao tempo. elapsedHours: ", elapsedHours);
            
            closePositionedOrders();
         }
         else if (!positionModified) {
         
            //Ajustar informacoes de mercado no currentSymbol
            
            currentSymbol.adjustMarketInfo();      
            
            //Ajustar o novo Take Profit
            
            updateTakeProfit(currentSymbol.getNewTakeProfit());
            
            positionModified = true;
         }
      }
   }
   else if (tradingTimeValue == 2) {
   
      Comment("Horario de stand-by.\n", TimeToString(TimeCurrent(), TIME_MINUTES));
   }
   else if (tradingTimeValue == 3) {
   
      Comment("Horario de compra.\n", TimeToString(TimeCurrent(), TIME_MINUTES));
      
      if (isNewBar()) {
      
         positionModified = false;
         
         if (!isOrderOpened() && !isPositionOpened()) {
         
            currentSymbol = symbolsContainer.confirmStrategy();
         
            if (currentSymbol != NULL) {
            
               //Melhor ativo encontrado, realizar compra, com stop de 5%
               
               string symbolName = currentSymbol.getName();
               double symbolAsk = currentSymbol.getPriceAsk();
               double symbolTarget = currentSymbol.getPriceTarget();
               
               if (symbolAsk > 0 && symbolTarget > 0) {
                  
                  double PRC = NormalizeDouble(symbolAsk, (int)SymbolInfoInteger(symbolName, SYMBOL_DIGITS));
                  double TP = NormalizeDouble(symbolTarget, (int)SymbolInfoInteger(symbolName, SYMBOL_DIGITS));
                  double SL = NormalizeDouble(symbolAsk * 0.95, (int)SymbolInfoInteger(symbolName, SYMBOL_DIGITS));
                     
                  double volume = 0;
                     
                  while (symbolAsk * (volume + 100.0) <= AccountInfoDouble(ACCOUNT_MARGIN_FREE)) {
                     
                     volume += 100.0;
                  }
                     
                  if (trade.Buy(volume, currentSymbol.getName(), PRC, SL, TP, "")) {
               
                     Print("Posicao comprada com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
                  }
                  else {
                     
                     Print("Posicao comprada com falha. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
                  }
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

int getCurrentPositionElapsedHours() {

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
   
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      
      if (magic == MAGIC_NUM) {
      
         datetime posTime = (datetime)PositionGetInteger(POSITION_TIME);
         
         return (int)(TimeCurrent() - posTime) / 3600;
      }
   }
   
   return -1;
}

bool isPositionOpened() {

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
   
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      
      if (magic == MAGIC_NUM) {
      
         return true;
      }
   }
   
   return false;
}

bool isOrderOpened() {

   for (int i = OrdersTotal() - 1; i >= 0; i--) {
   
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
      Horario de ajuste: das 10h00 as 10h30
      Horario de stand-by: das 10h30 as 17h50
      Horario de compra: das 17h50 as 17h55h
      
      Essa funcao retorna:
      0 Fora do horario de negociacao
      1 Horario de ajuste
      2 Horario de stand-by
      3 Horario de compra
   */
   
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   
   if (now.hour < 10) {
   
      return 0;
   }
   else if (now.hour == 10 && now.min < 30) {
   
      return 1;
   }
   else if (now.hour <= 17) {
   
      if (now.hour < 17) return 2;
      else if (now.hour == 17 && now.min < 50) return 2;
      else if (now.min < 55) return 3;
      else return 0;
   }
   else {
   
      return 0;
   }
}

void closePositionedOrders() {

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
   
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      
      if (magic == MAGIC_NUM) {
      
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         
         if (trade.PositionClose(ticket, -1)) {
         
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
      ulong magic = OrderGetInteger(ORDER_MAGIC);
      
      if (magic == MAGIC_NUM) {
         
         if (trade.OrderDelete(ticket)) {
         
            Print("Ordem deletada com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
         else {
         
            Print("Ordem deletada com falha. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
      }
   }
}

void updateTakeProfit(double newPrice) {

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
   
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      
      if (magic == MAGIC_NUM) {
         
         MqlTick tick;
         
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         double currentTakeProfit = PositionGetDouble(POSITION_TP);
         double currentStop = PositionGetDouble(POSITION_SL);
         
         if (newPrice != currentTakeProfit) {
         
            if (SymbolInfoTick(currentSymbol.getName(), tick) && tick.ask > newPrice) {
            
               if (trade.PositionClose(ticket, -1)) {
         
                  Print("Posicao fechada no ajuste com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
               }
               else {
                  
                  Print("Posicao fechada no ajuste com falha. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
               }
            }
            else if (trade.PositionModify(ticket, currentStop, NormalizeDouble(newPrice, (int)SymbolInfoInteger(currentSymbol.getName(), SYMBOL_DIGITS)))) {
         
               Print("Posicao modificada com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
            }
            else {
                  
               Print("Posicao modificada com falha. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
            }
         }
         
         return;
      }
   }
}