#define CLASS_NAME "Bot-IFR2-Ciclico.SymbolInfo"
#define MA200_COUNT 15
#define RSI_MIN 15

class SymbolInfo {

   private:
   
      string name;
      bool initFail;

      MqlTick lastTick;
      MqlRates rates[];
   
      int handleMA200;
      int handleRSI2;
   
      double arrayMA200[];
      double arrayRSI2[];
      
      datetime lastBarOpenTime;
      
      bool isNewBar();
      
   public:
   
      SymbolInfo(string symbolName);
      ~SymbolInfo();
     
      string getName();
      bool checkInitSuccess();
      bool adjustMarketInfo();
      double calculateStrategy();
      double getNewTakeProfit();
      double getPriceAsk();
      double getPriceTarget();
};

SymbolInfo::SymbolInfo(string symbolName) {
   
   initFail = false;
   
   name = symbolName;
      
   handleMA200 = iMA(name, PERIOD_D1, 200, 0, MODE_SMA, PRICE_CLOSE);
   handleRSI2 = iRSI(name, PERIOD_D1, 2, PRICE_CLOSE);
         
   if (handleMA200 == INVALID_HANDLE || handleRSI2 == INVALID_HANDLE) {
             
      Print(CLASS_NAME, ", ", name,": Nao foi possivel obter os indicadores: ", GetLastError());
            
      initFail = true;
         
      return;
   }
         
   if (!ArraySetAsSeries(rates, true) ||
       !ArraySetAsSeries(arrayMA200, true) ||
       !ArraySetAsSeries(arrayRSI2, true)) {
             
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
   
   if (CopyBuffer(handleMA200, 0, 0, MA200_COUNT, arrayMA200) < 0  ||
       CopyBuffer(handleRSI2, 0, 0, 2, arrayRSI2) < 0) {
                     
      Print(CLASS_NAME, ", ", name,": Erro ao copiar indicadores: ", GetLastError());
      
      return false;
   }
   
   return true;
}

double SymbolInfo::calculateStrategy(void) {

   if (adjustMarketInfo()) {
   
      //Verificar se ultimo preco esta acima da MA200
   
      if (lastTick.last > arrayMA200[0]) {
      
         bool upTrending = true;
         
         //Verificar tendencia de alta da MA200
         
         for (int i = 0; i < MA200_COUNT - 1; i++) {
         
            if (arrayMA200[i] < arrayMA200[i+1]) {
            
               upTrending = false;
               
               break;
            }
         }
         
         if (upTrending && arrayRSI2[0] <= RSI_MIN && arrayRSI2[1] <= RSI_MIN) {
            
            return rates[0].low - arrayMA200[0];
         }  
      }
   }
   
   return 0.0;
}

double SymbolInfo::getNewTakeProfit(void) {

   return rates[2].high > rates[3].high ? rates[2].high : rates[3].high;
}

double SymbolInfo::getPriceAsk(void) {

   return lastTick.ask;
}

double SymbolInfo::getPriceTarget(void) {

   return rates[1].high > rates[2].high ? rates[1].high : rates[2].high;
}

SymbolInfo::~SymbolInfo() {

   //Deletar algum objeto alocado em memoria.
}