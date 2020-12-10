#include "SymbolStrategy.mqh"
#include "SymbolStrategyResult.mqh"
#include "StrategyLarryWilliams1.mqh"
#include "StrategyLarryWilliams2.mqh"

class SymbolInfo {

   private:
   
      string name;
      bool initSuccess;
      int strategyCount;
      SymbolStrategy* symbolStrategies[];
      SymbolStrategy* currentStrategy;
      bool addStrategy(SymbolStrategy* symbolStrategy);
      
   public:
   
      SymbolInfo(string symbolName);
      ~SymbolInfo();
      
      bool checkInitSuccess();
      string getName();
      bool newBar();
      SymbolStrategy* getConfirmedStrategy();
};

SymbolInfo::SymbolInfo(string symbolName) {
   
   initSuccess = false;
   
   name = symbolName;
   
   //Adicionar estrategias no simbolo
   
   if (!addStrategy(new StrategyLarryWilliams1(name))) return;
   //if (!addStrategy(new StrategyLarryWilliams2(name))) return;
   
   strategyCount = ArraySize(symbolStrategies);
   
   initSuccess = true;
}

SymbolInfo::~SymbolInfo() {

   //Deletar algum objeto alocado em memoria.
}

bool SymbolInfo::addStrategy(SymbolStrategy* symbolStrategy) {

   if (!symbolStrategy.checkInitSuccess()) {
   
      return false;
   }

   int currSize = ArraySize(symbolStrategies);

   if (ArrayResize(symbolStrategies, currSize + 1, 0) == -1) {
   
      Print("Nao foi possivel alocar espaco para o array symbolStrategies[].");
      
      delete symbolStrategy;
      
      return false;
   }
   
   symbolStrategies[currSize] = symbolStrategy;

   return true;
}

bool SymbolInfo::checkInitSuccess(void) {

   return initSuccess;
}

string SymbolInfo::getName(void) {

   return name;
}

bool SymbolInfo::newBar(void) {
   
   for (int i = 0; i < strategyCount; i++) {
   
      if (!symbolStrategies[i].newBar()) return false;
   }
   
   return true;
}

SymbolStrategy* SymbolInfo::getConfirmedStrategy() {

   Print("getConfirmedStrategy()");

   for (int i = 0; i < strategyCount; i++) {
   
      if (symbolStrategies[i].mustOpenPosition()) {
      
         return symbolStrategies[i];
      }
   }
   
   return NULL;
}