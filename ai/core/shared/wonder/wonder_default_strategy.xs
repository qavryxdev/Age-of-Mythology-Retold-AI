void addDefaultWonderStrategies()
{
   // Init Wonder Age strategy.
   gWonderStrategy.mData.mID = cStrategyWonder;

   gWonderStrategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      data.initDefaultStrategy(cAge5);

      return (true);
   };

   gWonderStrategy.mUpdateFunc = [](ref StrategyData data) -> bool { return (true); };
   gWonderStrategy.mName = "Default Wonder";
}