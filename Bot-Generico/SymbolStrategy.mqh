#include "SymbolStrategyResult.mqh"

class SymbolStrategy {

   private:
   
      bool initSuccess;
      string name;
      bool adjustMarketInfo();
      
      
   protected:
   
      bool adjusted;
      MqlTick lastTick;
      MqlRates rates[];
      int handleMedia200;
      double arrayMedia200[];

   public:
   
      SymbolStrategy(string symbolName);
      ~SymbolStrategy();
      
      bool checkInitSuccess();
      void newBar();
      bool mustAdjustTP();
      bool mustClosePosition();
      SymbolStrategyResult* getStrategyResult();
};

SymbolStrategy::SymbolStrategy(string symbolName) {

   initSuccess = false;
   name = symbolName;
   adjusted = false;
   
   handleMedia200 = iMA(name, PERIOD_D1, 200, 0, MODE_SMA, PRICE_CLOSE);
   
   if (handleMedia200 == INVALID_HANDLE) {
   
      Print("Erro ao iniciar medias moveis.");
      
      return;
   }
   
   if (!ArraySetAsSeries(rates, true)) return;
   if (!ArraySetAsSeries(arrayMedia200, true)) return;
   
   initSuccess = true;
}
  
SymbolStrategy::~SymbolStrategy() {

}

bool SymbolStrategy::checkInitSuccess(void) {

   return initSuccess;
}

bool SymbolStrategy::adjustMarketInfo(void) {

   return true;
}

void SymbolStrategy::newBar() {

   adjusted = false;
}

bool SymbolStrategy::mustAdjustTP(void) {

   if (!adjusted) {
   
      adjusted = true;
      
      //Verificar se o TP deve ser ajustado
      //return true?
   }
   
   return false;
}

bool SymbolStrategy::mustClosePosition(void) {

   return false;
}

SymbolStrategyResult* SymbolStrategy::getStrategyResult(void) {

   return NULL;
}

