#include "SymbolStrategy.mqh"

class SymbolStrategyResult {

   private:
   
      double ask;
      double takeProfit;
      double sellLoss;
   
   public:
   
      SymbolStrategyResult(double priceAsk, double priceTP, double priceSL);
      ~SymbolStrategyResult();
      double getAsk();
      double getTakeProfit();
      double getSellLoss();
};

SymbolStrategyResult::SymbolStrategyResult(double priceAsk, double priceTP, double priceSL) {

   ask = priceAsk;
   takeProfit = priceTP;
   sellLoss = priceSL;
}

SymbolStrategyResult::~SymbolStrategyResult(void) {

}

double SymbolStrategyResult::getAsk(void) {

   return ask;
}

double SymbolStrategyResult::getTakeProfit(void) {

   return takeProfit;
}

double SymbolStrategyResult::getSellLoss(void) {

   return sellLoss;
}