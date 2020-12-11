#include "SymbolStrategy.mqh"
#include "SymbolStrategyResult.mqh"

class StrategyLarryWilliams1: public SymbolStrategy {

   private:
   
      bool initSuccess;      
      bool updateMarketInfo();
      
      //Variaveis da estrategia
      
      int handleMA5Max;
      int handleMA2Min;
      int handleStochastic;
   
      double arrayMA5Max[];
      double arrayMA2Min[];
      double arrayStochastic[];
      
      bool countBars;
      int barCount;

   public:
   
      StrategyLarryWilliams1(string symbolName);
      ~StrategyLarryWilliams1();
      
      virtual bool checkInitSuccess();
      virtual string getStrategyName();
      virtual bool newBar();
      virtual bool mustOpenPosition();
      virtual bool mustClosePosition();
      virtual bool mustAdjustTP();
      virtual double getNewTP();
      virtual SymbolStrategyResult* getStrategyResult();
};

StrategyLarryWilliams1::StrategyLarryWilliams1(string symbolName) : SymbolStrategy(symbolName) {

   initSuccess = false;

   handleMA5Max = iMA(name, PERIOD_D1, 5, 0, MODE_SMA, PRICE_HIGH);
   handleMA2Min = iMA(name, PERIOD_D1, 2, 0, MODE_SMA, PRICE_LOW);
   handleStochastic = iStochastic(name, PERIOD_D1, 7, 3, 3, MODE_SMA, STO_LOWHIGH);
         
   if (handleMA5Max == INVALID_HANDLE     || 
       handleMA2Min == INVALID_HANDLE     ||
       handleStochastic == INVALID_HANDLE) {
             
      Print("Nao foi possivel obter os indicadores: ", GetLastError());
         
      return;
   }
         
   if (!ArraySetAsSeries(arrayMA5Max, true)     ||
       !ArraySetAsSeries(arrayMA2Min, true)     ||
       !ArraySetAsSeries(arrayStochastic, true)) {
             
      Print("Nao foi possivel serializar os arrays: ", GetLastError());
         
      return;
   }
   
   initSuccess = true;
}

StrategyLarryWilliams1::~StrategyLarryWilliams1() {

}

bool StrategyLarryWilliams1::checkInitSuccess(void) {

   if (!SymbolStrategy::checkInitSuccess()) return false;
   
   return initSuccess;
}

string StrategyLarryWilliams1::getStrategyName(void) {

   return "ESTRATEGIA LARRY WILLIAMS 1";
}

bool StrategyLarryWilliams1::newBar(void) {

   Print("newBar()");

   if (!SymbolStrategy::newBar()) return false;   
   if (!updateMarketInfo()) return false;
   
   if (countBars) barCount++;
   
   return true;
}

bool StrategyLarryWilliams1::updateMarketInfo(void) {
   
   if (CopyBuffer(handleMA5Max, 0, 0, 1, arrayMA5Max) < 0      ||
       CopyBuffer(handleMA2Min, 0, 0, 1, arrayMA2Min) < 0      ||
       CopyBuffer(handleStochastic, 0, 0, 1, arrayStochastic) < 0) {
                     
      Print("Erro ao copiar indicadores: ", GetLastError());
      
      return false;
   }
   
   return true;
}

bool StrategyLarryWilliams1::mustOpenPosition(void) {

   Print("mustOpenPosition()");

   if (arrayStochastic[0] < 30.0) {
   
      Print("lastTick: ", lastTick.last);
      Print("arrayMA2Min[0]: ", arrayMA2Min[0]);
         
      if (lastTick.last < arrayMA2Min[0]) {
      
         Print("true");
         
         countBars = true;
            
         return true;
      }  
   }
   
   return false;
}

bool StrategyLarryWilliams1::mustClosePosition(void) {

   Print("mustClosePosition()");
   
   if (lastTick.last > arrayMA5Max[0] || barCount > 3) {
   
      barCount = 0;
      countBars = false;
   
      return true;
   }

   return false;
}

bool StrategyLarryWilliams1::mustAdjustTP(void) {

   Print("mustAdjustTP()");
   
   return false;
}

double StrategyLarryWilliams1::getNewTP(void) {

   //Lembrar de normalizar o preco

   return 0.0;
}

SymbolStrategyResult* StrategyLarryWilliams1::getStrategyResult(void) {

   Print("getStrategyResult()");
   
   int digits = (int)SymbolInfoInteger(name, SYMBOL_DIGITS);
   double priceAsk = NormalizeDouble(lastTick.ask, digits);

   return new SymbolStrategyResult(priceAsk, 0.0, 0.0);
}