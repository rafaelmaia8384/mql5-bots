//#include "CandleSignals.mqh"
#include "SymbolStrategyResult.mqh"

#define RATES_MAX 3
#define HOST_BACKEND_PATTERN "http://127.0.0.1/pattern-candles"

class SymbolStrategy {

   private:
   
      bool initSuccess;
      bool updateMarketInfo();
      
      //int handleMA200;
      //int handleEMA;
      
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
      virtual bool mustClosePositionOnAdjust();
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

   if (CopyRates(name, PERIOD_D1, 0, RATES_MAX, rates) < 0) {
               
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

bool SymbolStrategy::mustClosePositionOnAdjust(void) {

   return false;
}

bool SymbolStrategy::mustAdjustTP(void) {

   return updateMarketInfo();
}

double SymbolStrategy::getNewTP(void) {

   return 0.0;
}

int SymbolStrategy::getEuler(void) {

   if (MQLInfoInteger(MQL_TESTER)) return 0;
   
   string resHeaders;
   char data[];
   char result[];
   string url = HOST_BACKEND_PATTERN;
   
   string body = "[";
   
   for (int i = 0; i < RATES_MAX; i++) {
   
      body += i > 0 ? ",{": "{";
      body += "\"open\": " + DoubleToString(rates[i].open, 8) + ",";
      body += "\"high\": " + DoubleToString(rates[i].high, 8) + ",";
      body += "\"low\": " + DoubleToString(rates[i].low, 8) + ",";
      body += "\"close\": " + DoubleToString(rates[i].close, 8);
      body += "}";
   }
   
   body += "]";
   
   if (StringToCharArray(body, data, 0, WHOLE_ARRAY, CP_UTF8) > 0) {
   
      int res = WebRequest("POST", url, "Content-Type: application/json\r\n", 1000, data, result, resHeaders);
      
      if (res == 200) {
      
         string euler = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
         
         return (int)StringToInteger(euler);
      }
   }

   return 0;
}

SymbolStrategyResult* SymbolStrategy::getStrategyResult(void) {

   return NULL;
}