#include "SymbolStrategy.mqh"
#include "SymbolStrategyResult.mqh"

class StrategyLarryWilliamsMA3: public SymbolStrategy {

   private:
   
      bool initSuccess;      
      bool updateMarketInfo();
      
      //Variaveis da estrategia
      
      int handleMA3Max;
      int handleMA3Min;
      int handleMA30;
   
      double arrayMA3Max[];
      double arrayMA3Min[];
      double arrayMA30[];
      
      int barCount;

   public:
   
      StrategyLarryWilliamsMA3(string symbolName);
      ~StrategyLarryWilliamsMA3();
      
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

StrategyLarryWilliamsMA3::StrategyLarryWilliamsMA3(string symbolName) : SymbolStrategy(symbolName) {

   initSuccess = false;

   handleMA3Max = iMA(name, PERIOD_D1, 3, 0, MODE_SMA, PRICE_HIGH);
   handleMA3Min = iMA(name, PERIOD_D1, 3, 0, MODE_SMA, PRICE_LOW);
   handleMA30 = iMA(name, PERIOD_D1, 30, 0, MODE_SMA, PRICE_CLOSE);
         
   if (handleMA3Max == INVALID_HANDLE     || 
       handleMA3Min == INVALID_HANDLE     ||
       handleMA30 == INVALID_HANDLE) {
             
      Print("Nao foi possivel obter os indicadores: ", GetLastError());
         
      return;
   }
         
   if (!ArraySetAsSeries(arrayMA3Max, true)     ||
       !ArraySetAsSeries(arrayMA3Min, true)     ||
       !ArraySetAsSeries(arrayMA30, true)) {
             
      Print("Nao foi possivel serializar os arrays: ", GetLastError());
         
      return;
   }
   
   initSuccess = true;
}

StrategyLarryWilliamsMA3::~StrategyLarryWilliamsMA3() {

}

bool StrategyLarryWilliamsMA3::checkInitSuccess(void) {

   if (!SymbolStrategy::checkInitSuccess()) return false;
   
   return initSuccess;
}

string StrategyLarryWilliamsMA3::getStrategyName(void) {

   return "ESTRATEGIA LARRY WILLIAMS MA3";
}

bool StrategyLarryWilliamsMA3::newBar(void) {

   Print("newBar()");

   if (!SymbolStrategy::newBar()) return false;   
   if (!updateMarketInfo()) return false;
   
   //barCount++;
   
   return true;
}

bool StrategyLarryWilliamsMA3::updateMarketInfo(void) {
   
   if (CopyBuffer(handleMA3Max, 0, 0, 1, arrayMA3Max) < 0      ||
       CopyBuffer(handleMA3Min, 0, 0, 1, arrayMA3Min) < 0      ||
       CopyBuffer(handleMA30, 0, 0, 1, arrayMA30) < 0) {
                     
      Print("Erro ao copiar indicadores: ", GetLastError());
      
      return false;
   }
   
   return true;
}

bool StrategyLarryWilliamsMA3::mustOpenPosition(void) {

   Print("mustOpenPosition()");
   
   if (lastTick.last > arrayMA30[0]) {
   
      if (lastTick.last < arrayMA3Min[0]) {
      
         return true;
      }
   }
   
   return false;
}

bool StrategyLarryWilliamsMA3::mustClosePosition(void) {

   Print("mustClosePosition()");

   return lastTick.last > arrayMA3Max[0];
}

bool StrategyLarryWilliamsMA3::mustClosePositionOnAdjust(void) {

   return false;
}

bool StrategyLarryWilliamsMA3::mustAdjustTP(void) {

   if (!SymbolStrategy::mustAdjustTP()) return false;
   if (!updateMarketInfo()) return false;
   
   //Retornar verdadeiro caso queira ajusar o Take Profit
   
   return false;
}

double StrategyLarryWilliamsMA3::getNewTP(void) {

   //Lembrar de normalizar o preco

   return 0.0;
}

SymbolStrategyResult* StrategyLarryWilliamsMA3::getStrategyResult(void) {

   Print("getStrategyResult()");
   
   int digits = (int)SymbolInfoInteger(name, SYMBOL_DIGITS);
   double priceAsk = NormalizeDouble(lastTick.ask, digits);

   return new SymbolStrategyResult(priceAsk, 0.0, 0.0);
}