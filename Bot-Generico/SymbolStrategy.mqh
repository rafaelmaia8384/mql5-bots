//#include "CandleSignals.mqh"
#include "SymbolStrategyResult.mqh"

class SymbolStrategy {

   private:
   
      bool initSuccess;
      bool updateMarketInfo();
      
   protected:
   
      string name;
      MqlTick lastTick;
      MqlRates rates[];
      
   public:
   
      SymbolStrategy(string symbolName);
      ~SymbolStrategy();
      
      string getSymbolName();
      int getEuler();
      
      virtual bool checkInitSuccess();
      virtual string getStrategyName();
      virtual bool newBar();
      virtual bool mustOpenPosition();
      virtual bool mustClosePosition();
      virtual bool mustAdjustTP();
      virtual double getNewTP();
      virtual SymbolStrategyResult* getStrategyResult();
};

SymbolStrategy::SymbolStrategy(string symbolName) {

   initSuccess = false;
   name = symbolName;
   
   if (!ArraySetAsSeries(rates, true)) return;
   
   initSuccess = true;
}
  
SymbolStrategy::~SymbolStrategy() {

}

bool SymbolStrategy::checkInitSuccess(void) {

   return initSuccess;
}

string SymbolStrategy::getSymbolName(void) {

   return name;
}

string SymbolStrategy::getStrategyName(void) {

   return NULL;
}

bool SymbolStrategy::updateMarketInfo(void) {

   if (!SymbolInfoTick(name, lastTick)) {
               
      Alert("Erro ao obter lastTick: ", GetLastError());
      
      return false;
   }

   if (CopyRates(name, PERIOD_D1, 0, 5, rates) < 0) {
               
      Print("Erro ao copiar o MqlRates: ", GetLastError());
      
      return false;
   }

   return true;
}

bool SymbolStrategy::newBar() {

   if (!updateMarketInfo()) return false;
   
   return true;
}

bool SymbolStrategy::mustOpenPosition(void) {

   return false;
}

bool SymbolStrategy::mustClosePosition(void) {

   return false;
}

bool SymbolStrategy::mustAdjustTP(void) {

   return false;
}

double SymbolStrategy::getNewTP(void) {

   return 0.0;
}

int SymbolStrategy::getEuler(void) {

   return 0;
}

SymbolStrategyResult* SymbolStrategy::getStrategyResult(void) {

   return NULL;
}