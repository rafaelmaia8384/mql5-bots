//Simple WebRequest test

int OnInit() {

   string body = "{\"hello\":\"world\"}";

   string resheaders;
   char data[];
   char result[];
   string url = "http://127.0.0.1/pattern-result";
   
   int res = WebRequest("POST", url, "Content-Type: application/json\r\n", 1000, data, result, resheaders);
   
   Print("Result: ", res);
   Print("Response: ", CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8));
  
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {

   
}

void OnTick() {

   
}