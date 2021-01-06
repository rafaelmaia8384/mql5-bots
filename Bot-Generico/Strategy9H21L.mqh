#include "SymbolStrategy.mqh"
#include "SymbolStrategyResult.mqh"

class Strategy9H21L: public SymbolStrategy {

   private:
   
      bool initSuccess;      
      bool updateMarketInfo();
      
      //Variaveis da estrategia
      
      int handleEMA9High;
      int handleMA21Low;
      int handleMA200;
   
      double arrayEMA9High[];
      double arrayMA21Low[];
      double arrayMA200[];
      
      int barCount;

   public:
   
      Strategy9H21L(string symbolName);
      ~Strategy9H21L();
      
      virtual bool checkInitSuccess();
      virtual string getStrategyName();
      virtual bool newBar();
      virtual bool mustOpenPosition();
      virtual bool mustClosePosition();
      virtual bool mustClosePositionOnAdjust();
      virtual bool mustAdjustTP();
      virtual double getNewTP();
      virtual SymbolStrategyResult* getStrategyResult();
};

Strategy9H21L::Strategy9H21L(string symbolName) : SymbolStrategy(symbolName) {

   initSuccess = false;

   handleEMA9High = iMA(name, PERIOD_D1, 9, 0, MODE_SMA, PRICE_HIGH);
   handleMA21Low = iMA(name, PERIOD_D1, 21, 0, MODE_SMA, PRICE_LOW);
   handleMA200 = iMA(name, PERIOD_D1, 200, 0, MODE_SMA, PRICE_CLOSE);
         
   if (handleEMA9High == INVALID_HANDLE     || 
       handleMA21Low == INVALID_HANDLE     ||
       handleMA200 == INVALID_HANDLE) {
             
      Print("Nao foi possivel obter os indicadores: ", GetLastError());
         
      return;
   }
         
   if (!ArraySetAsSeries(arrayEMA9High, true)     ||
       !ArraySetAsSeries(arrayMA21Low, true)     ||
       !ArraySetAsSeries(arrayMA200, true)) {
             
      Print("Nao foi possivel serializar os arrays: ", GetLastError());
         
      return;
   }
   
   initSuccess = true;
}

Strategy9H21L::~Strategy9H21L() {

}

bool Strategy9H21L::checkInitSuccess(void) {

   if (!SymbolStrategy::checkInitSuccess()) return false;
   
   return initSuccess;
}

string Strategy9H21L::getStrategyName(void) {

   return "ESTRATEGIA 9H21L";
}

bool Strategy9H21L::newBar(void) {

   Print("newBar()");

   if (!SymbolStrategy::newBar()) return false;   
   if (!updateMarketInfo()) return false;
   
   //barCount++;
   
   return true;
}

bool Strategy9H21L::updateMarketInfo(void) {
   
   if (CopyBuffer(handleEMA9High, 0, 0, 5, arrayEMA9High) < 0      ||
       CopyBuffer(handleMA21Low, 0, 0, 5, arrayMA21Low) < 0      ||
       CopyBuffer(handleMA200, 0, 0, 1, arrayMA200) < 0) {
                     
      Print("Erro ao copiar indicadores: ", GetLastError());
      
      return false;
   }
   
   return true;
}

bool Strategy9H21L::mustOpenPosition(void) {

   Print("mustOpenPosition()");
   
   if (lastTick.last > arrayMA200[0]) {
   
      if (arrayEMA9High[0] < arrayMA21Low[0] &&
          arrayEMA9High[1] < arrayMA21Low[1] && 
          arrayEMA9High[2] < arrayMA21Low[2] && 
          arrayEMA9High[3] < arrayMA21Low[3] &&
          arrayEMA9High[4] < arrayMA21Low[4]) {
      
         if (rates[0].close < arrayEMA9High[0]) {
         
            return true;
         
            /*if (lastTick.last > arrayMA21Low[0]) {         
               
            }*/
         }
      }
   }
   
   return false;
}

bool Strategy9H21L::mustClosePosition(void) {

   Print("mustClosePosition()");

   return false;
}

bool Strategy9H21L::mustClosePositionOnAdjust(void) {

   return false;
}

bool Strategy9H21L::mustAdjustTP(void) {

   if (!SymbolStrategy::mustAdjustTP()) return false;
   if (!updateMarketInfo()) return false;
   
   //Retornar verdadeiro caso queira ajusar o Take Profit
   
   return false;
}

double Strategy9H21L::getNewTP(void) {

   //Lembrar de normalizar o preco

   return 0.0;
}

SymbolStrategyResult* Strategy9H21L::getStrategyResult(void) {

   Print("getStrategyResult()");
   
   int digits = (int)SymbolInfoInteger(name, SYMBOL_DIGITS);
   double priceAsk = NormalizeDouble(lastTick.ask, digits);
   double tp = NormalizeDouble(lastTick.last * 1.05, digits);
   double sl = NormalizeDouble(lastTick.last * 0.95, digits);

   return new SymbolStrategyResult(priceAsk, tp, sl);
}