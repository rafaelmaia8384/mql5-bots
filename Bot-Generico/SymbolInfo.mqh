#include "SymbolStrategy.mqh"
#include "SymbolStrategyResult.mqh"
#include "StrategyLarryWilliams777.mqh"

class SymbolInfo {

   private:
   
      string name;
      bool initSuccess;
      SymbolStrategy* symbolStrategies[];
      SymbolStrategy* currentStrategy;
      bool addStrategy(SymbolStrategy* symbolStrategy);
      
   public:
   
      SymbolInfo(string symbolName);
      ~SymbolInfo();
      
      bool checkInitSuccess();
      string getName();
      void newBar();
      bool mustAdjustTP();
      bool mustClosePosition();
      SymbolStrategyResult* getStrategyResult();
};

SymbolInfo::SymbolInfo(string symbolName) {
   
   initSuccess = false;
   
   name = symbolName;
   
   //Adicionar estrategias no simbolo
   
   //if (!addStrategy(new StrategyLarryWilliams777(name))) return;
   //if (!addStrategy(new StrategyLarryWilliams777(name))) return;
   //if (!addStrategy(new StrategyLarryWilliams777(name))) return;
   //if (!addStrategy(new StrategyLarryWilliams777(name))) return;
   //if (!addStrategy(new StrategyLarryWilliams777(name))) return;
   
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

void SymbolInfo::newBar(void) {

   int strategyCount = ArraySize(symbolStrategies);
   
   for (int i = 0; i < strategyCount; i++) {
   
      symbolStrategies[i].newBar();
   }
}

bool SymbolInfo::mustAdjustTP(void) {

   return currentStrategy.mustAdjustTP();
}

bool SymbolInfo::mustClosePosition(void) {

   return currentStrategy.mustClosePosition();
}

/*bool SymbolInfo::adjustMarketInfo(void) {

   if (!SymbolInfoTick(name, lastTick)) {
               
      Alert("Erro ao obter lastTick: ", GetLastError());
      
      return false;
   }

   if (CopyRates(name, PERIOD_D1, 0, 5, rates) < 0) {
               
      Print(CLASS_NAME, ", ", name,": Erro ao copiar o MqlRates: ", GetLastError());
      
      return false;
   }
   
   if (CopyBuffer(handleMA5Max, 0, 0, 1, arrayMA5Max) < 0      ||
       CopyBuffer(handleMA2Min, 0, 0, 1, arrayMA2Min) < 0      ||
       CopyBuffer(handleStochastic, 0, 0, 1, arrayStochastic) < 0) {
                     
      Print(CLASS_NAME, ", ", name,": Erro ao copiar indicadores: ", GetLastError());
      
      return false;
   }
   
   return true;
}*/

/*double SymbolInfo::calculateStrategy(void) {

   if (adjustMarketInfo()) {
   
      //Verificar se ultimo preco esta acima da media de 30
   
      if (arrayStochastic[0] < 30.0) {
      
         //Verificar se ultimo candle esta fechando abaixo da media minima de 3
         
         if (lastTick.last < arrayMA2Min[0]) {
            
            return arrayMA2Min[0] - lastTick.last;
         }  
      }
   }
   
   return 0.0;
}*/

SymbolStrategyResult* SymbolInfo::getStrategyResult(void) {

   if (currentStrategy != NULL) {
   
      return currentStrategy.getStrategyResult();
   }

   return NULL;
}