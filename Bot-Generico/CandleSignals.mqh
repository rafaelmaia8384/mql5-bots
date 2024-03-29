#include "CCandlePattern.mqh"

class CandleSignals : public CCandlePattern {

   private:

     int i;

   public:
   
     CandleSignals();
     ~CandleSignals();
     bool ValidationSettings();
     bool InitIndicators(CIndicators *indicators);
};

CandleSignals::CandleSignals() {

}

CandleSignals::~CandleSignals() {

}

bool CandleSignals::ValidationSettings(void) {

   return CCandlePattern::ValidationSettings();
}

bool CandleSignals::InitIndicators(CIndicators *indicators) {

   return CCandlePattern::InitIndicators(indicators);
}