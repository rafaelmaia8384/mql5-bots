#include "SymbolStrategy.mqh"
#include "SymbolStrategyResult.mqh"

class StrategyLarryWilliams777: public SymbolStrategy {

   private:

   public:
   
      StrategyLarryWilliams777(string symbolName);
      ~StrategyLarryWilliams777();
      void newBar();
      SymbolStrategyResult* getStrategyResult();
};

StrategyLarryWilliams777::StrategyLarryWilliams777(string symbolName) : SymbolStrategy(symbolName) {

}

StrategyLarryWilliams777::~StrategyLarryWilliams777() {

}

void StrategyLarryWilliams777::newBar(void) {

   SymbolStrategy::newBar();
   
   //Implementar aqui as regras
}

SymbolStrategyResult* StrategyLarryWilliams777::getStrategyResult(void) {

   return NULL;
}