//Simple WebRequest test

datetime lastBarOpenTime;
MqlTick lastTick;
MqlRates rates[];

int OnInit() {

   request(3);
  
   //Print("Result: ", res);
   //Print("Response: ", CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8));
  
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {

   
}

void request(int count) {
   
   if (!SymbolInfoTick(_Symbol, lastTick)) {
               
      Alert("Erro ao obter lastTick: ", GetLastError());
         
      return;
   }
   
   if (CopyRates(_Symbol, _Period, 0, count, rates) < 0) {
                  
      Print("Erro ao copiar o MqlRates: ", GetLastError());
         
      return;
   }

   string resHeaders;
   char data[];
   char result[];
   string url = "http://127.0.0.1/pattern-candles";
   
   string body = "[";
   
   for (int i = 0; i < count; i++) {
   
      body += i > 0 ? ",{": "{";
      
      body += "\"time\": " + IntegerToString(rates[i].time) + ",";
      body += "\"open\": " + DoubleToString(rates[i].open, 8) + ",";
      body += "\"high\": " + DoubleToString(rates[i].high, 8) + ",";
      body += "\"low\": " + DoubleToString(rates[i].low, 8) + ",";
      body += "\"close\": " + DoubleToString(rates[i].close, 8);
      
      body += "}";
   }
   
   body += "]";
   
   Print(body);
   
   StringToCharArray(body, data, 0, WHOLE_ARRAY, CP_UTF8);
   
   int res = WebRequest("POST", url, "Content-Type: application/json\r\n", 1000, data, result, resHeaders);
   
   if (res == 200) {
   
      Print(CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8));
   }
}

void OnTick() {

   if (isNewBar()) {
      
      request(10);
   }  
}

bool isNewBar() { 

   static datetime bartime = 0;
   datetime currbarTime = iTime(_Symbol, _Period, 0); 

   if (bartime != currbarTime) { 
   
      bartime = currbarTime; 
      lastBarOpenTime = bartime; 

      return true; 
   } 

   return false; 
}