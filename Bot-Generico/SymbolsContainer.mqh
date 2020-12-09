#include "SymbolInfo.mqh"

class SymbolsContainer {

   private:
   
      int symbolsCount;
      bool initSuccess;
      SymbolInfo* symbolsInfo[];
      
   public:
   
      SymbolsContainer(string &symbolsList[]);
      ~SymbolsContainer();
      bool checkInitSuccess();
      void newBar();
      SymbolInfo* confirmedStrategy();
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

void SymbolsContainer::newBar(void) {

   for (int i = 0; i < symbolsCount; i++) {
   
      symbolsInfo[i].newBar();
   }
}

SymbolInfo* SymbolsContainer::confirmedStrategy(void) {

   /*SymbolInfo* confirmedSymbols[];
   double confirmedTrendings[];

   for (int i = 0; i < symbolsCount; i++) {
   
      SymbolInfo* si = symbolsInfo[i];
      double trending = si.calculateStrategy();
            
      if (trending > 0.0) {
      
         //Estrategia do ativo confirmada, adicionar num array pra ver o melhor papel depois
         
         int size1 = ArraySize(confirmedSymbols);
         int size2 = ArraySize(confirmedTrendings);
         
         ArrayResize(confirmedSymbols, size1 + 1, 0);
         ArrayResize(confirmedTrendings, size2 + 1, 0);
         
         confirmedSymbols[size1] = si;
         confirmedTrendings[size2] = trending;
      }
   }
   
   if (ArraySize(confirmedSymbols) > 0 && ArraySize(confirmedTrendings) > 0) {
   
      int index = ArrayMaximum(confirmedTrendings, 0, WHOLE_ARRAY);
      
      return confirmedSymbols[index];
   }
   
   return NULL;*/
   
   return NULL;
}