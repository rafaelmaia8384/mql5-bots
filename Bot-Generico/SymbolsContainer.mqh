#include "SymbolInfo.mqh"
#include "SymbolStrategyResult.mqh"

class SymbolsContainer {

   private:
   
      int symbolsCount;
      bool initSuccess;
      SymbolInfo* symbolsInfo[];
      
   public:
   
      SymbolsContainer(string &symbolsList[]);
      ~SymbolsContainer();
      bool checkInitSuccess();
      bool newBar();
      SymbolStrategy* getConfirmedStrategy();
};

SymbolsContainer::SymbolsContainer(string &symbolsList[]) {

   initSuccess = false;
   symbolsCount = ArraySize(symbolsList);
   
   //Checar se os papeis existem
   
   for (int i = 0; i < symbolsCount; i++) {
   
      SymbolInfoDouble(symbolsList[i], SYMBOL_ASK);
      
      if (GetLastError() == ERR_MARKET_UNKNOWN_SYMBOL) {
      
         Print("Nao foi possivel obter informacoes do papel: ", symbolsList[i]);
      
         return;
      }
   }
   
   //Redimensionar o array para armazenar os objetos SymbolInfo
   
   if (ArrayResize(symbolsInfo, symbolsCount, 0) == -1) {
   
      Print("Nao foi possivel alocar espaco para o array symbolsInfo[].");
      
      return;
   }
   
   //Criar e adicionar os objetos SymbolInfo no array symbolsInfo[]
   
   for (int i = 0; i < symbolsCount; i++) {
   
      SymbolInfo *si = new SymbolInfo(symbolsList[i]);
      
      if (!si.checkInitSuccess()) {
      
         delete si;
         
         return;
      }
      
      symbolsInfo[i] = si;
   }
   
   initSuccess = true;
}

SymbolsContainer::~SymbolsContainer() {
   
   for (int i = 0; i < symbolsCount; i++) {
   
      delete symbolsInfo[i];
   }
}

bool SymbolsContainer::checkInitSuccess(void) {

   return initSuccess;
}

bool SymbolsContainer::newBar(void) {

   for (int i = 0; i < symbolsCount; i++) {
   
      if (!symbolsInfo[i].newBar()) return false;
   }
   
   return true;
}

SymbolStrategy* SymbolsContainer::getConfirmedStrategy(void) {

   SymbolStrategy* symbolStrategyList[];
   int eulerList[];
   
   for (int i = 0; i < symbolsCount; i++) {
   
      SymbolInfo* si = symbolsInfo[i];
      SymbolStrategy* symbolStrategy = si.getConfirmedStrategy();
      
      if (symbolStrategy != NULL) {
      
         int size = ArraySize(symbolStrategyList);
         
         if (ArrayResize(symbolStrategyList, size + 1, 0) == -1) return NULL;
         
         symbolStrategyList[size] = symbolStrategy;
      }
   }
   
   int strategiesSize = ArraySize(symbolStrategyList);
   
   if (strategiesSize > 0) {
   
      for (int i = 0; i < strategiesSize; i++) {
         
         int size = ArraySize(eulerList);
         
         if (ArrayResize(eulerList, size + 1, 0) == -1) return NULL;
         
         eulerList[size] = symbolStrategyList[i].getEuler();
      }
      
      int index = ArrayMaximum(eulerList, 0, WHOLE_ARRAY);
         
      if (index != -1) {
         
         return symbolStrategyList[index];
      }
   }
   
   return NULL;
}