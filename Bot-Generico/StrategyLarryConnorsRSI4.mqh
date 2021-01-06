#include "SymbolStrategy.mqh"
#include "SymbolStrategyResult.mqh"

class StrategyLarryConnorsRSI4: public SymbolStrategy {

   private:
   
      bool initSuccess;      
      bool updateMarketInfo();
      
      //Variaveis da estrategia
      
      int handleRSI;
      int handleMA200;
   
      double arrayRSI[];
      double arrayMA200[];
      
      bool countBars;
      int barCount;

   public:
   
      StrategyLarryConnorsRSI4(string symbolName);
      ~StrategyLarryConnorsRSI4();
      
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

StrategyLarryConnorsRSI4::StrategyLarryConnorsRSI4(string symbolName) : SymbolStrategy(symbolName) {

   initSuccess = false;

   handleRSI = iRSI(_Symbol, _Period, 4, PRICE_CLOSE);
   handleMA200 = iMA(name, PERIOD_D1, 200, 0, MODE_SMA, PRICE_CLOSE);
         
   if (handleRSI == INVALID_HANDLE     || 
       handleMA200 == INVALID_HANDLE) {
             
      Print("Nao foi possivel obter os indicadores: ", GetLastError());
         
      return;
   }
         
   if (!ArraySetAsSeries(arrayRSI, true)     ||
       !ArraySetAsSeries(arrayMA200, true)) {
             
      Print("Nao foi possivel serializar os arrays: ", GetLastError());
         
      return;
   }
   
   initSuccess = true;
}

StrategyLarryConnorsRSI4::~StrategyLarryConnorsRSI4() {

}

bool StrategyLarryConnorsRSI4::checkInitSuccess(void) {

   if (!SymbolStrategy::checkInitSuccess()) return false;
   
   return initSuccess;
}

string StrategyLarryConnorsRSI4::getStrategyName(void) {

   return "ESTRATEGIA LARRY CONNORS RSI4";
}

bool StrategyLarryConnorsRSI4::newBar(void) {

   Print("newBar()");

   if (!SymbolStrategy::newBar()) return false;   
   if (!updateMarketInfo()) return false;
   
   if (countBars) barCount++;
   
   return true;
}

bool StrategyLarryConnorsRSI4::updateMarketInfo(void) {
   
   if (CopyBuffer(handleRSI, 0, 0, 2, arrayRSI) < 0      ||
       CopyBuffer(handleMA200, 0, 0, 5, arrayMA200) < 0) {
                     
      Print("Erro ao copiar indicadores: ", GetLastError());
      
      return false;
   }
   
   return true;
}

bool StrategyLarryConnorsRSI4::mustOpenPosition(void) {

   Print("mustOpenPosition()");
   
   if (lastTick.last > arrayMA200[0] && arrayRSI[0] < 30.0 && arrayRSI[1] < 30.0) {
   
      return true;
   }
   
   return false;
}

bool StrategyLarryConnorsRSI4::mustClosePosition(void) {

   Print("mustClosePosition()");
   
   if (arrayRSI[0] >= 55.0) {
   
      return true;
   }

   return false;
}

bool StrategyLarryConnorsRSI4::mustClosePositionOnAdjust(void) {
   
   return false;
}

bool StrategyLarryConnorsRSI4::mustAdjustTP(void) {

   if (!SymbolStrategy::mustAdjustTP()) return false;
   if (!updateMarketInfo()) return false;
   
   //Retornar verdadeiro caso queira ajusar o Take Profit
   
   return false;
}

double StrategyLarryConnorsRSI4::getNewTP(void) {

   //Lembrar de normalizar o preco

   return 0.0;
}

SymbolStrategyResult* StrategyLarryConnorsRSI4::getStrategyResult(void) {

   Print("getStrategyResult()");
   
   int digits = (int)SymbolInfoInteger(name, SYMBOL_DIGITS);
   double priceAsk = NormalizeDouble(lastTick.ask, digits);

   return new SymbolStrategyResult(priceAsk, 0.0, 0.0);
}