#define CLASS_NAME "Bot-IFR2-Ciclico.SymbolInfo"

class SymbolInfo {

   private:
   
      string name;
      bool initFail;
      
      int rsiMin;
      int countMA200;

      MqlTick lastTick;
      MqlRates rates[];
   
      int handleMA5Max;
      int handleMA2Min;
      int handleStochastic;
   
      double arrayMA5Max[];
      double arrayMA2Min[];
      double arrayStochastic[];
      
   public:
   
      SymbolInfo(string symbolName, int rsi, int ma200);
      ~SymbolInfo();
     
      string getName();
      bool checkInitSuccess();
      bool adjustMarketInfo();
      double calculateStrategy();
      double getNewTakeProfit();
      double getPriceAsk();
      double getPriceTarget();
      bool checkClosePosition();
};

SymbolInfo::SymbolInfo(string symbolName, int rsi, int ma200) {
   
   initFail = false;
   
   name = symbolName;
   rsiMin = rsi;
   countMA200 = ma200;
      
   handleMA5Max = iMA(name, PERIOD_D1, 5, 0, MODE_SMA, PRICE_HIGH);
   handleMA2Min = iMA(name, PERIOD_D1, 2, 0, MODE_SMA, PRICE_LOW);
   handleStochastic = iStochastic(name, PERIOD_D1, 7, 3, 3, MODE_SMA, STO_LOWHIGH);
         
   if (handleMA5Max == INVALID_HANDLE     || 
       handleMA2Min == INVALID_HANDLE     ||
       handleStochastic == INVALID_HANDLE) {
             
      Print(CLASS_NAME, ", ", name,": Nao foi possivel obter os indicadores: ", GetLastError());
            
      initFail = true;
         
      return;
   }
         
   if (!ArraySetAsSeries(rates, true)           ||
       !ArraySetAsSeries(arrayMA5Max, true)     ||
       !ArraySetAsSeries(arrayMA2Min, true)     ||
       !ArraySetAsSeries(arrayStochastic, true)) {
             
      Print(CLASS_NAME, ", ", name,": Nao foi possivel serializar os arrays: ", GetLastError());
      
      initFail = true;
         
      return;
   }
}

string SymbolInfo::getName(void) {

   return name;
}

bool SymbolInfo::checkInitSuccess(void) {

   return !initFail;
}

bool SymbolInfo::adjustMarketInfo(void) {

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
}

double SymbolInfo::calculateStrategy(void) {

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
}

bool SymbolInfo::checkClosePosition(void) {

   if (adjustMarketInfo()) {
   
      return lastTick.last > arrayMA5Max[0];
   }
   
   return false;
}

double SymbolInfo::getPriceAsk(void) {

   return lastTick.ask;
}

SymbolInfo::~SymbolInfo() {

   //Deletar algum objeto alocado em memoria.
}