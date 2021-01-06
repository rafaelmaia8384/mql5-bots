#include "SymbolStrategy.mqh"
#include "SymbolStrategyResult.mqh"

class StrategyBandasDeBollinger: public SymbolStrategy {

   private:
   
      bool initSuccess;      
      bool updateMarketInfo();
      
      //Variaveis da estrategia
      
      int handleRSI;
      int handleMA200;
      int handleBB;
   
      double arrayRSI[];
      double arrayMA200[];
      double arrayBBup[];
      double arrayBBmiddle[];
      double arrayBBdown[];
      
      bool countBars;
      int barCount;

   public:
   
      StrategyBandasDeBollinger(string symbolName);
      ~StrategyBandasDeBollinger();
      
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

StrategyBandasDeBollinger::StrategyBandasDeBollinger(string symbolName) : SymbolStrategy(symbolName) {

   initSuccess = false;

   handleRSI = iRSI(_Symbol, _Period, 2, PRICE_CLOSE);
   handleMA200 = iMA(name, PERIOD_D1, 200, 0, MODE_SMA, PRICE_CLOSE);
   handleBB = iBands(name, PERIOD_D1, 20, 0, 2, PRICE_CLOSE);
         
   if (handleRSI == INVALID_HANDLE     || 
       handleMA200 == INVALID_HANDLE     || 
       handleBB == INVALID_HANDLE) {
             
      Print("Nao foi possivel obter os indicadores: ", GetLastError());
         
      return;
   }
         
   if (!ArraySetAsSeries(arrayRSI, true)     ||
       !ArraySetAsSeries(arrayMA200, true)     ||
       !ArraySetAsSeries(arrayBBup, true)     ||
       !ArraySetAsSeries(arrayBBmiddle, true) ||
       !ArraySetAsSeries(arrayBBdown, true)) {
             
      Print("Nao foi possivel serializar os arrays: ", GetLastError());
         
      return;
   }
   
   initSuccess = true;
}

StrategyBandasDeBollinger::~StrategyBandasDeBollinger() {

}

bool StrategyBandasDeBollinger::checkInitSuccess(void) {

   if (!SymbolStrategy::checkInitSuccess()) return false;
   
   return initSuccess;
}

string StrategyBandasDeBollinger::getStrategyName(void) {

   return "ESTRATEGIA BANDAS DE BOLLINGER";
}

bool StrategyBandasDeBollinger::newBar(void) {

   Print("newBar()");

   if (!SymbolStrategy::newBar()) return false;   
   if (!updateMarketInfo()) return false;
   
   if (countBars) barCount++;
   
   return true;
}

bool StrategyBandasDeBollinger::updateMarketInfo(void) {
   
   if (CopyBuffer(handleRSI, 0, 0, 1, arrayRSI) < 0      ||
       CopyBuffer(handleMA200, 0, 0, 1, arrayMA200) < 0      ||
       CopyBuffer(handleBB, 1, 0, 1, arrayBBup) < 0      ||
       CopyBuffer(handleBB, 0, 0, 1, arrayBBmiddle) < 0   ||
       CopyBuffer(handleBB, 2, 0, 1, arrayBBdown) < 0) {
                     
      Print("Erro ao copiar indicadores: ", GetLastError());
      
      return false;
   }
   
   return true;
}

bool StrategyBandasDeBollinger::mustOpenPosition(void) {

   Print("mustOpenPosition()");
   
   if (arrayRSI[0] < 20.0) {
   
      if (lastTick.last > arrayMA200[0] && lastTick.last < arrayBBdown[0]) {
         
         Print("true");
               
         return true;
      }  
   }
   
   return false;
}

bool StrategyBandasDeBollinger::mustClosePosition(void) {

   Print("mustClosePosition()");
   
   if (lastTick.last >= arrayBBmiddle[0]) {
   
      return true;
   }

   return false;
}

bool StrategyBandasDeBollinger::mustClosePositionOnAdjust(void) {

   Print("mustClosePositionOnAdjust()");
   
   if (lastTick.last > arrayBBmiddle[0]) return true;
   
   return false;
}

bool StrategyBandasDeBollinger::mustAdjustTP(void) {

   if (!SymbolStrategy::mustAdjustTP()) return false;
   if (!updateMarketInfo()) return false;
   
   //Retornar verdadeiro caso queira ajusar o Take Profit
   
   return false;
}

double StrategyBandasDeBollinger::getNewTP(void) {

   //Lembrar de normalizar o preco

   return 0.0;
}

SymbolStrategyResult* StrategyBandasDeBollinger::getStrategyResult(void) {

   Print("getStrategyResult()");
   
   int digits = (int)SymbolInfoInteger(name, SYMBOL_DIGITS);
   double priceAsk = NormalizeDouble(lastTick.ask, digits);

   return new SymbolStrategyResult(priceAsk, 0.0, 0.0);
}