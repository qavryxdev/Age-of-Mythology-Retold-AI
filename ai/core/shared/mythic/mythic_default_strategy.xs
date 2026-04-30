//==============================================================================
// initMythicStrategy
//==============================================================================
void initMythicStrategy(ref StrategyData data)
{
   data.initDefaultStrategy(cAge4);
}
void addDefaultMythicStrategies()
{
   // Init Mythic Age strategy.
   gMythicStrategy.mData.mID = cStrategyMythic;
   gMythicStrategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      initMythicStrategy(data);
      // v1.0: zkraceny intervaly utoku - puvodni: (8,6.5,4.5,3,2,2)*60
      gAttackManager.mBaseAttackInterval = selectByDifficulty(5 * 60, 4 * 60, 3 * 60, 1.5 * 60, 1 * 60, 1 * 60);
      return (true);
   };
   gMythicStrategy.mUpdateFunc = [](ref StrategyData data) -> bool { return (kbPlayerGetAge(cMyID) == cAge4); };
   gMythicStrategy.mName = "Default Mythic";

   // Init Mythic Age Turtler strategy.
   gMythicTurtlerStrategy.mData.mID = cStrategyMythicTurtler;
   gMythicTurtlerStrategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      initMythicStrategy(data);
      // v1.0: Turtler v Mythic veku konecne utoci - nahromadena armada jde do utoku
      // puvodni: data.setFlag(cStrategyFlagCanAttack, false)
      gAttackManager.mBaseAttackInterval = selectByDifficulty(5 * 60, 3 * 60, 2 * 60, 1 * 60, 1 * 60, 1 * 60);

      xsEnableRule("wallManager");
      
      // Only do this on large/giant map sizes.
      if (cMapSizeCurrent >= cMapSizeLarge)
      {
         data.mWallCircleAmount = 3;
      }

      return (true);
   };
   gMythicTurtlerStrategy.mNextFunc = [](ref StrategyData data) -> int { return cStrategyWonder; };
   gMythicTurtlerStrategy.mUpdateFunc = [](ref StrategyData data) -> bool 
   { 
      patrolBaseGates(data); 
      return (kbPlayerGetAge(cMyID) == cAge4);
   };   
   gMythicTurtlerStrategy.mName = "Mythic Turtler";
}