#property copyright "Bot básico"

/*
   Este bot utiliza a setup IFR2. Basicamente, utiliza-se um indicador RSI de 2 periodos.
   Quando um novo candle e' aberto, checa-se se o RSI do candle anterior esta' abaixo de 10.
   Caso seja verdadeiro, verifica-se se o preco atual esta' acima da media movel de 200.
   Dessa forma, envia-se uma ordem de compra no preco de fechamento do candle anterior, colocando
   o Take Profit na maxima dos dois ultimos candles anteriores.
   
   Ao surgirem novos candles, o bot verifica se estamos posicionados e, caso verdadeiro, atualiza-se
   o Take Profit para a maxima dos dois ultimos candles, novamente. O Stop Loss e' definido ao enviar
   a ordem de compra, como sendo o valor de compra menos 130% o tamanho do candle de compra.
*/

//Biblioteca para facilitar as ordens
#include <Trade\Trade.mqh>

CTrade trade;
MqlTick lastTick;
MqlRates rates[];

input double VOLUME = 10.0; //Volume de negociacao

ulong magicNum = 11071986;

int handleMedia200;
int handleRSI;
double arrayMedia200[];
double arrayRSI[];

int pendingOrderCounter = 0;
int positionOrderCounter = 0;

datetime lastbarTimeopen; 

int OnInit() {

   handleMedia200 = iMA(_Symbol, _Period, 200, 0, MODE_SMA, PRICE_CLOSE);
   handleRSI = iRSI(_Symbol, _Period, 2, PRICE_CLOSE);
   
   if (handleMedia200 == INVALID_HANDLE || handleRSI == INVALID_HANDLE) {
   
      Print("Erro ao iniciar medias moveis.");
      return INIT_FAILED;
   }
   
   ArraySetAsSeries(rates, true);
   ArraySetAsSeries(arrayMedia200, true);
   ArraySetAsSeries(arrayRSI, true);
   
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   //trade.SetDeviationInPoints(DEVIATION_IN_POINTS);
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
      
         Print("Nova barra.");
         
         if (CopyRates(_Symbol, _Period, 0, 5, rates) < 0) {
               
            Alert("Erro ao copiar o MqlRates: ", GetLastError());
            return;
         }
      
         if (!isOrderOpened()) {
         
            if (!isPositionOpened()) {
            
               if (!SymbolInfoTick(_Symbol, lastTick)) {
               
                  Alert("Erro ao obter lastTick: ", GetLastError());
                  return;
               }
               
               if (CopyBuffer(handleMedia200, 0, 0, 5, arrayMedia200) < 0 ||
                   CopyBuffer(handleRSI, 0, 0, 5, arrayRSI) < 0) {
                     
                  Alert("Erro ao copiar medias moveis: ", GetLastError());
                  return;
               }
               
               //Aqui podemos iniciar a verificacao das estrategias
               
               if (lastTick.last > arrayMedia200[0] && lastTick.last - arrayMedia200[0] > 400.0) {
               
                  Print("last tick > MA 200");

                  //Precos acima da media de 200, podemos prosseguir
                  
                  if (arrayRSI[1] <= 15) {
                  
                     Print("RSI <= 15");
                     
                     //RSI do candle anterior esta menor ou igual a 10
                     
                     double PRC = NormalizeDouble(rates[1].close, _Digits);
                     double sellLossPrice = PRC - ((rates[1].high - rates[1].low) * 1.3);
                     double takeProfitPrice = rates[1].high > rates[2].high ? rates[1].high : rates[2].high;
                     double SL = NormalizeDouble(sellLossPrice, _Digits);
                     double TP = NormalizeDouble(takeProfitPrice, _Digits);
                     
                     //Verificar se o o valor de SL/TP vale o risco
                     
                     double loss = (PRC-SL);
                     double gain = (TP-PRC);
                     double risk = loss/gain;
                     
                     if (risk > 1.5) {
                     
                        Alert("Relacao de risco nao compensada!");
                        return;
                     }
                     else if (SL/PRC < 0.98) {
                     
                        //Verificar isso?
                     }
                     else {
                     
                        Print("Risco: ", risk);
                     }
                     
                     trade.Buy(VOLUME, _Symbol, PRC, SL, TP, "");
                  }
               }
            }
            else {
            
               //Estou posicionado... fazer algo?
               //Aguardar no maximo 7 novos candles posicionados.
               
               if (positionOrderCounter++ >= 7) {
               
                  positionOrderCounter = 0;
                  
                  closePositionedOrders();
               }
               else {
               
                  //Atualizar Take Profit da posicao atual
                  
                  double newPrice = rates[1].high > rates[2].high ? NormalizeDouble(rates[1].high, _Digits) : NormalizeDouble(rates[2].high, _Digits);
                  
                  updateCurrentPositionTakeProfit(newPrice);
               }
            }
         }
         else {
         
            //Tem ordem em aberto... fazer algo?
            //Aguardar no maximo 3 novos candles para executar a ordem.
            
            if (pendingOrderCounter++ >= 3) {
            
               pendingOrderCounter = 0;
               
               closePendingOrders();
            }
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

void updateCurrentPositionTakeProfit(double newPrice) {

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
   
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      
      if (symbol == _Symbol && magic == magicNum) {
      
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         double tp = PositionGetDouble(POSITION_TP);
         double sl = PositionGetDouble(POSITION_SL);
         
         if (tp != newPrice) {

            if (trade.PositionModify(ticket, sl, newPrice)) {
         
               Print("Posicao modificada com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
            }
            else {
            
               Print("Posicao modificada com falha. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
            }
         }
         else {
         
            Print("Take Profit igual ao anterior.");
         }
      }
   }
}