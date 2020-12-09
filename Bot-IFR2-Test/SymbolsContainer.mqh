#include "SymbolInfo.mqh"

#define CLASS_NAME "Bot-IFR2-Ciclico.SymbolContainer"

class SymbolsContainer {

   private:
   
      int symbolsCount;
      bool initSuccess;
      SymbolInfo* symbolsInfo[];
      
   public:
   
      SymbolsContainer(string &symbolsList[], int rsi, int ma200);
      ~SymbolsContainer();
      
      bool checkInitSuccess();
      SymbolInfo* confirmStrategy();
};

SymbolsContainer::SymbolsContainer(string &symbolsList[], int rsi, int ma200) {

   initSuccess = false;
   
   symbolsCount = ArraySize(symbolsList);
   
   //Checar se os papeis existem
   
   for (int i = 0; i < symbolsCount; i++) {
   
      SymbolInfoDouble(symbolsList[i], SYMBOL_ASK);
      
      if (GetLastError() == ERR_MARKET_UNKNOWN_SYMBOL) {
      
         Print(CLASS_NAME, ": Nao foi possivel obter informacoes do papel: ", symbolsList[i]);
      
         return;
      }
   }
   
   //Redimensionar o array para armazenar os objetos SymbolInfo
   
   if (ArrayResize(symbolsInfo, symbolsCount, 0) == -1) {
   
      Print(CLASS_NAME, ": Nao foi possivel alocar espaco para o array symbolsInfo[].");
      
      return;
   }
   
   //Criar e adicionar os objetos SymbolInfo no array symbolsInfo[]
   
   for (int i = 0; i < symbolsCount; i++) {
   
      SymbolInfo *si = new SymbolInfo(symbolsList[i], rsi, ma200);
      symbolsInfo[i] = si;
      
      //Falha em caso de inicializacao errada
      
      if (!si.checkInitSuccess()) {
      
         delete si;
      
         Print(CLASS_NAME, ": Erro ao criar SymbolInfo.");
         
         return;
      }
   }
   
   initSuccess = true;
}

bool SymbolsContainer::checkInitSuccess(void) {

   return initSuccess;
}


SymbolInfo* SymbolsContainer::confirmStrategy(void) {

   SymbolInfo* confirmedSymbols[];
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
   
      int index = ArrayMinimum(confirmedTrendings, 0, WHOLE_ARRAY);
      
      return confirmedSymbols[index];
   }
   
   return NULL;
}

SymbolsContainer::~SymbolsContainer() {
   
   for (int i = 0; i < symbolsCount; i++) {
   
      delete symbolsInfo[i];
   }
}