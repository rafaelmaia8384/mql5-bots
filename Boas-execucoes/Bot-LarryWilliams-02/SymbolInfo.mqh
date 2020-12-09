#define CLASS_NAME "Bot-IFR2-Ciclico.SymbolInfo"

class SymbolInfo {

   private:
   
      string name;
      bool initFail;
      
      int rsiMin;
      int countMA200;

      MqlTick lastTick;
      MqlRates rates[];
   
      int handleMA3Max;
      int handleMA3Min;
      int handleMA30;
   
      double arrayMA3Max[];
      double arrayMA3Min[];
      double arrayMA30[];
      
      datetime lastBarOpenTime;
      
      bool isNewBar();
      
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
      
   handleMA3Max = iMA(name, PERIOD_D1, 3, 0, MODE_SMA, PRICE_HIGH);
   handleMA3Min = iMA(name, PERIOD_D1, 3, 0, MODE_SMA, PRICE_LOW);
   handleMA30 = iMA(name, PERIOD_D1, 30, 0, MODE_SMA, PRICE_CLOSE);
         
   if (handleMA3Max == INVALID_HANDLE     || 
       handleMA3Min == INVALID_HANDLE     ||
       handleMA30 == INVALID_HANDLE) {
             
      Print(CLASS_NAME, ", ", name,": Nao foi possivel obter os indicadores: ", GetLastError());
            
      initFail = true;
         
      return;
   }
         
   if (!ArraySetAsSeries(rates, true)           ||
       !ArraySetAsSeries(arrayMA3Max, true)     ||
       !ArraySetAsSeries(arrayMA3Min, true)     ||
       !ArraySetAsSeries(arrayMA30, true)) {
             
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
   
   if (CopyBuffer(handleMA3Max, 0, 0, 1, arrayMA3Max) < 0    ||
       CopyBuffer(handleMA3Min, 0, 0, 1, arrayMA3Min) < 0      ||
       CopyBuffer(handleMA30, 0, 0, 1, arrayMA30) < 0) {
                     
      Print(CLASS_NAME, ", ", name,": Erro ao copiar indicadores: ", GetLastError());
      
      return false;
   }
   
   return true;
}

double SymbolInfo::calculateStrategy(void) {

   if (adjustMarketInfo()) {
   
      //Verificar se ultimo preco esta acima da media de 30
   
      if (lastTick.last > arrayMA30[0]) {
      
         //Verificar se ultimo candle esta fechando abaixo da media minima de 3
         
         if (lastTick.last < arrayMA3Min[0]) {
            
            return lastTick.last - arrayMA30[0];
         }  
      }
   }
   
   return 0.0;
}

bool SymbolInfo::checkClosePosition(void) {

   if (adjustMarketInfo()) {
   
      return lastTick.last > arrayMA3Max[0];
   }
   
   return false;
}

double SymbolInfo::getPriceAsk(void) {

   return lastTick.ask;
}

SymbolInfo::~SymbolInfo() {

   //Deletar algum objeto alocado em memoria.
}