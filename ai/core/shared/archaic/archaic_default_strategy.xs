//==============================================================================
// initArchaicStrategy
//==============================================================================
void initArchaicStrategy(ref StrategyData data)
{
   data.initDefaultStrategy(cAge1);
}

void addDefaultArchaicStrategies()
{
   // Init Archaic Age strategy.
   gArchaicStrategy.mData.mID = cStrategyArchaic;

   gArchaicStrategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      initArchaicStrategy(data);
      return (true);
   };

   gArchaicStrategy.mUpdateFunc = [](ref StrategyData data) -> bool { return (kbPlayerGetAge(cMyID) == cAge1); };
   gArchaicStrategy.mName = "Default Archaic";
   
   // Init build order strategy.
   gStartupBOStrategy.mData.mID = cStrategyStartupBO;

   gStartupBOStrategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      if (initBOSystem() == false)
      {
         debugBO("BO startup failed!!!");
         return false;
      }
      gStartupBOArchaic(); // For Deathmatch this is the only one we set.
      gStartupBOClassical();
      startBOSystem();
      // We enable scouting below but don't want this rule yet.
      xsDisableRule("scoutingMonitor");
      if (cMyCulture == cCultureGreek)
      {
         xsDisableRule("kataskoposManager");
      }
      // We want the gPrimaryLandDefendPlan already but don't want this rule killing it instantly.
      xsDisableRule("defenseReflex");
      xsDisableRule("newDefend");

      data.setFlag(cStrategyFlagAutomaticHerding);
      data.setFlag(cStrategyFlagAutomaticScouting);
      data.setFlag(cStrategyFlagManageOracles);
      data.setFlag(cStrategyFlagScoutWithStartingTransport);
      // We need the Hersirs to potentially build, can't steal them for Relics.
      if (cMyCulture != cCultureNorse)
      {
         data.setFlag(cStrategyFlagCollectRelics);
      }

      return (true);
   };

   gStartupBOStrategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      // Keep running BO system until the current BO is finished.
      return (boSystem.done == false);
   };
   
   gStartupBOStrategy.mName = "BO";
}