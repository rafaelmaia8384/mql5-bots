#property copyright "Bot básico"

/*
   Este bot utiliza o novo setup "Medias INDOL", criado por Rafael Paiviandre Maia.
   
   O metodo para calcular a entrada e' baseado em 3 medias moveis: 140, 70 e 35, juntamente
   com o RSI-2, em cada um dos dois ativos (Indice e Dolar).
   O primeiro sinal de compra e' ativado caso as medias moveis estejam ascendentes: 140 < 70 < 35.
   O segundo sinal de compra verifica-se quando os 5 ultimos valores de cada media estao crescentes m[0] > m[1] > m[2] > m[3] > m[4].
   O terceiro sinal de compra e' registrado quando o RSI-2 esta abaixo do RSI_MIN.
   O quarto e ultimo sinal, verifica-se quando o papel oposto confirma o contrario dos primeiros 2 sinais.
   
   Para operacoes de vendas, invertem-se as regras acima.
*/

//Biblioteca para facilitar as ordens
#include <Trade\Trade.mqh>

CTrade trade;
MqlTick lastTick;
MqlRates rates[];

input double VOLUME = 1.0; //Volume de negociacao
input double RSI_MIN = 12; //RSI minimo de gatilho
input int DEVIATION_POINTS = 10; //Pontos de desvio maximo
input string ATIVO_INDICE = "WIN$"; //Papel corrente do indice
input string ATIVO_DOLAR = "WDO$"; //Papel corrente do dolar

ulong magicNum = 11071986;

int handleINDMedia140;
int handleINDMedia70;
int handleINDMedia35;
int handleDOLMedia140;
int handleDOLMedia70;
int handleDOLMedia35;
int handleINDRSI;
int handleDOLRSI;

double arrayINDMedia140[];
double arrayINDMedia70[];
double arrayINDMedia35[];
double arrayDOLMedia140[];
double arrayDOLMedia70[];
double arrayDOLMedia35[];
double arrayINDRSI[];
double arrayDOLRSI[];

bool positionModified = false;

datetime lastbarTimeopen; 

int OnInit() {

   handleINDMedia140 = iMA(ATIVO_INDICE, _Period, 140, 0, MODE_SMA, PRICE_CLOSE);
   handleINDMedia70 = iMA(ATIVO_INDICE, _Period, 70, 0, MODE_SMA, PRICE_CLOSE);
   handleINDMedia35 = iMA(ATIVO_INDICE, _Period, 35, 0, MODE_SMA, PRICE_CLOSE);
   handleDOLMedia140 = iMA(ATIVO_DOLAR, _Period, 140, 0, MODE_SMA, PRICE_CLOSE);
   handleDOLMedia70 = iMA(ATIVO_DOLAR, _Period, 70, 0, MODE_SMA, PRICE_CLOSE);
   handleDOLMedia35 = iMA(ATIVO_DOLAR, _Period, 35, 0, MODE_SMA, PRICE_CLOSE);
   handleINDRSI = iRSI(ATIVO_INDICE, _Period, 2, PRICE_CLOSE);
   handleDOLRSI = iRSI(ATIVO_DOLAR, _Period, 2, PRICE_CLOSE);
   
   if (handleINDMedia140 == INVALID_HANDLE   || 
       handleINDMedia70 == INVALID_HANDLE    ||
       handleINDMedia35 == INVALID_HANDLE    ||
       handleDOLMedia140 == INVALID_HANDLE   ||
       handleDOLMedia70 == INVALID_HANDLE    ||
       handleDOLMedia35 == INVALID_HANDLE    ||
       handleINDRSI == INVALID_HANDLE        ||
       handleDOLRSI == INVALID_HANDLE) {
   
      Print("Ativo: ", _Symbol, ", Erro ao iniciar indicadores.");
      return INIT_FAILED;
   }
   
   ArraySetAsSeries(rates, true);
   ArraySetAsSeries(arrayINDMedia140, true);
   ArraySetAsSeries(arrayINDMedia70, true);
   ArraySetAsSeries(arrayINDMedia35, true);
   ArraySetAsSeries(arrayDOLMedia140, true);
   ArraySetAsSeries(arrayDOLMedia70, true);
   ArraySetAsSeries(arrayDOLMedia35, true);
   ArraySetAsSeries(arrayINDRSI, true);
   ArraySetAsSeries(arrayDOLRSI, true);
   
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetDeviationInPoints(DEVIATION_POINTS);
   trade.SetExpertMagicNumber(magicNum);
   
   Print("Ativo: ", _Symbol, ", Bot iniciado.");

   return INIT_SUCCEEDED;
}



void OnDeinit(const int reason) {
   
}

bool adjustRates() {

   if (CopyRates(_Symbol, _Period, 0, 5, rates) < 0) {
               
      Print("Ativo: ", _Symbol, ", Erro ao copiar o MqlRates: ", GetLastError());
      return false;
   }
   
   return true;
}

void OnTick() {

   int tradingTimeValue = getTradingTimeValue();
   
   if (tradingTimeValue == 0) {
   
      Comment("Fora do horario de negociacao.\n", TimeToString(TimeCurrent(), TIME_MINUTES));
   }
   else if (tradingTimeValue == 1) {
   
      Comment("Horario de ajuste.\n", TimeToString(TimeCurrent(), TIME_MINUTES));
      
      if (isPositionOpened()) {
      
         int elapsedHours = getCurrentPositionElapsedHours();
            
         if (elapsedHours >= 24 * 7) {
            
            //Fechar posicao devido ao tempo
               
            Print("Ativo: ", _Symbol, ", Posicao fechada devido ao tempo. elapsedHours: ", elapsedHours);
            
            closePositionedOrders();
         }
      
         else if (!positionModified) {
         
            if (!adjustRates()) return;            
            
            //Ajustar o novo Take Profit
               
            double newPrice = NormalizeDouble(rates[1].high > rates[2].high ? rates[1].high : rates[2].high, _Digits);
            
            updateCurrentPositionTakeProfit(newPrice);
            
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
         
            if (!adjustRates()) return;
            
            if (!SymbolInfoTick(_Symbol, lastTick)) {
               
               Print("Ativo: ", _Symbol, ", Erro ao obter lastTick: ", GetLastError());
               return;
            }
               
            if (CopyBuffer(handleMedia200, 0, 0, 5, arrayMedia200) < 0 ||
                CopyBuffer(handleRSI, 0, 0, 5, arrayRSI) < 0) {
                     
               Print("Ativo: ", _Symbol, ", Erro ao copiar medias moveis: ", GetLastError());
               return;
            }
               
            //Aqui podemos iniciar a verificacao das estrategias
               
            if (rates[0].low > arrayMedia200[0]) {
            
               //Precos acima da media de 200, podemos prosseguir
               
               Print("Ativo: ", _Symbol, ", rates[0].low > MA 200.");
                   
               if (arrayRSI[0] <= RSI_MIN) {
               
                  //RSI do candle atual esta menor ou igual ao RSI_MIN
                     
                  Print("Ativo: ", _Symbol, ", RSI <= ", RSI_MIN);
                        
                  double PRC = NormalizeDouble(lastTick.ask, _Digits);
                  double takeProfitPrice = rates[0].high > rates[1].high ? rates[0].high : rates[1].high;
                  double TP = NormalizeDouble(takeProfitPrice, _Digits);
                  
                  double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
                  
                  if (VOLUME * PRC < freeMargin) {
                  
                     trade.Buy(VOLUME, _Symbol, PRC, 0, TP, "");
                  }
                  else {
                  
                     Print("Ativo: ", _Symbol, ", Margem insuficiente para compra!");
                  }
               }      
            }
         }
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

int getCurrentPositionElapsedHours() {

   for (int i = PositionsTotal() - 1; i >= 0; i--) {
   
      string symbol = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      
      if (symbol == _Symbol && magic == magicNum) {
      
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
      
      if (symbol == _Symbol && magic == magicNum) {
      
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         
         if (trade.PositionClose(ticket, -1)) {
         
            Print("Ativo: ", _Symbol, ", Posicao fechada com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
         else {
         
            Print("Ativo: ", _Symbol, ", Posicao fechada com falha. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
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
         
            Print("Ativo: ", _Symbol, ", Ordem deletada com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
         else {
         
            Print("Ativo: ", _Symbol, ", Ordem deletada com falha. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
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
         double step = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
         double newTakeProfit = step * MathRound(newPrice / step);

         if (trade.PositionModify(ticket, 0, newTakeProfit)) {
         
            Print("Ativo: ", _Symbol, ", Posicao modificada com sucesso. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
         else {
            
            Print("Ativo: ", _Symbol, ", Posicao modificada com falha. ", trade.ResultRetcode(), ", RetCodeDescription: ", trade.ResultRetcodeDescription());
         }
         
         break;
      }
   }
}