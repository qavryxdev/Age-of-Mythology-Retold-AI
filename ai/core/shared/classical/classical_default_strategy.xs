//==============================================================================
// initClassicalStrategy
//==============================================================================
void initClassicalStrategy(ref StrategyData data)
{
   data.initDefaultStrategy(cAge2);
}

//==============================================================================
// patrolBaseGates
// 
// Used by the turtler plans to patrol the gates
//==============================================================================
void patrolBaseGates(ref StrategyData data)
{
   // If we can patrol we should patrol our gates
   static int nextUpdateTime = 0;
   int currentTime = xsGetTime();
   if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == true && currentTime >= nextUpdateTime)
   {
      // Update at 30 seconds intervals.
      nextUpdateTime = currentTime + 30;
      int locationUnit = getUnitByLocation(cUnitTypeWallGate, cMyID, cUnitStateAlive, 
         aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0), 30.0 + data.mWallCircleAmount * 20.0);
      if (kbUnitGetIsIDValid(locationUnit) == true)
      {
         vector location = kbUnitGetPosition(locationUnit);
         debugStrategy("Moving to defend gate: " + locationUnit + "at " + location);
         aiPlanSetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0, location);
         aiPlanSetVariableFloat(gPrimaryLandDefendPlan, cDefendPlanGatherDistance, 0, 10.0);
      }
   }
}

//==============================================================================
// addDefaultClassicalStrategies
//==============================================================================
void addDefaultClassicalStrategies()
{
   // Init Classical Age strategy.
   gClassicalStrategy.mData.mID = cStrategyClassical;
   gClassicalStrategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      initClassicalStrategy(data);
      // v1.0: zkraceny intervaly utoku - puvodni: (10,8,6,4,3,3)*60
      gAttackManager.mBaseAttackInterval = selectByDifficulty(7, 5, 4, 2, 1, 1) * 60;
      return (true);
   };
   gClassicalStrategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      return (kbPlayerGetAge(cMyID) == cAge2);
   };
   gClassicalStrategy.mName = "Default Classical";

   // Init Classical Age Rusher strategy.
   gClassicalRusherStrategy.mData.mID = cStrategyClassicalRusher;
   gClassicalRusherStrategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      initClassicalStrategy(data);

      data.setFlag(cStrategyFlagAutoResearchEconomyUpgrades, false);
      // v1.0: zkraceny intervaly utoku - puvodni: (10,7.5,4.5,3.5,2.5,2.5)*60
      gAttackManager.mBaseAttackInterval = selectByDifficulty(6 * 60.0, 4 * 60.0, 2.5 * 60.0, 1.5 * 60.0, 1.0 * 60.0, 1.0 * 60.0);
      return (true);
   };
   gClassicalRusherStrategy.mNextFunc = [](ref StrategyData data) -> int { return cStrategyHeroic; };
   gClassicalRusherStrategy.mUpdateFunc = [](ref StrategyData data) -> bool { return (kbPlayerGetAge(cMyID) == cAge2); };
   gClassicalRusherStrategy.mName = "Classical Rusher";

   // Init Classical Age Turtler strategy.
   gClassicalTurtlerStrategy.mData.mID = cStrategyClassicalTurtler;
   gClassicalTurtlerStrategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      initClassicalStrategy(data);

      data.setFlag(cStrategyFlagAutoResearchMilitaryUpgrades, false);

      // Don't attack.
      data.setFlag(cStrategyFlagCanAttack, false);
      
      xsEnableRule("wallManager");

      data.mWallCircleAmount = 1;
      return (true);
   };
   gClassicalTurtlerStrategy.mNextFunc = [](ref StrategyData data) -> int { return cStrategyHeroicTurtler; };
   gClassicalTurtlerStrategy.mUpdateFunc = [](ref StrategyData data) -> bool 
   {
      patrolBaseGates(data);
      return (kbPlayerGetAge(cMyID) == cAge2); 
   };   
   gClassicalTurtlerStrategy.mName = "Classical Turtler";
}