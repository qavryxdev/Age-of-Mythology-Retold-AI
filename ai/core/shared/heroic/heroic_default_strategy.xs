//==============================================================================
// initHeroicStrategy
//==============================================================================
void initHeroicStrategy(ref StrategyData data)
{
   data.initDefaultStrategy(cAge3);
}

void addDefaultHeroicStrategies()
{
   // Init Heroic Age strategy.
   gHeroicStrategy.mData.mID = cStrategyHeroic;
   gHeroicStrategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      initHeroicStrategy(data);
      // v1.0: zkraceny intervaly utoku - puvodni: (9,7,5,3.5,2.5,2.5)*60
      gAttackManager.mBaseAttackInterval = selectByDifficulty(6 * 60, 4 * 60, 3 * 60, 2 * 60, 1 * 60, 1 * 60);
      return (true);
   };
   gHeroicStrategy.mUpdateFunc = [](ref StrategyData data) -> bool { return (kbPlayerGetAge(cMyID) == cAge3); };
   gHeroicStrategy.mName = "Default Heroic";

   
   // Init Heroic Age Turtler strategy.
   gHeroicTurtlerStrategy.mData.mID = cStrategyHeroicTurtler;
   gHeroicTurtlerStrategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      initHeroicStrategy(data);

      data.setFlag(cStrategyFlagAutoResearchMilitaryUpgrades, false);

      // Don't attack.
      data.setFlag(cStrategyFlagCanAttack, false);

      xsEnableRule("wallManager");

      data.mWallCircleAmount = 2;
      return (true);
   };
   gHeroicTurtlerStrategy.mNextFunc = [](ref StrategyData data) -> int 
   {
      return cStrategyMythicTurtler; 
   };
   gHeroicTurtlerStrategy.mUpdateFunc = [](ref StrategyData data) -> bool 
   {
      patrolBaseGates(data); 
      return (kbPlayerGetAge(cMyID) == cAge3); 
   };   
   gHeroicTurtlerStrategy.mName = "Heroic Turtler";
   
}