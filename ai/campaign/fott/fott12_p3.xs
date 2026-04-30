//==============================================================================
/* fott12_p3.xs

   Orange Egyptian player owning the base in the north-east. Sends attacks of Spearmen, Chariot Archers, Anubites, Scorpion Men,
   Avengers.
*/
//==============================================================================
// Includes

include "core\main.xs"; // The bulk of the AI.
include "campaign\global_spc_modifiers.xs"; // global modifiers for difficulties.

//==============================================================================
/*	Rules

   Add scenario-specific rules & functions in the section below.
*/
//==============================================================================

int gFirstLandUnit = cUnitTypeSpearman; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 7;
int gSecondLandUnit = cUnitTypeChariotArcher; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 5;
int gThirdLandUnit = cUnitTypeAnubite; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 4;
int gFourthLandUnit = cUnitTypeScorpionMan; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 2;
int gFifthLandUnit = cUnitTypeAvenger; // Gets trained from the start.
float gMaintainFifthLandUnitAmount = 2;
float gMaxVillagerCount = 10;
float gAttackStartDelay = 300; // In seconds.
float gAttackWaveInterval = 240; // In seconds.
float gAttackStartSize = 5;
float gAttackMaxSize = 10;
int gWakeUpTime = -1;

Strategy scenarioAttackWaveStrategy()
{

   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugAttackWave("***Starting Scenario Attack Wave Strategy***");

      // This should never fail.
      aiCastGodPowerAtPosition(cProtoPowerVision, vector(122.0, 0.0, 166.0));
      xsEnableRule("useSerpents");
      xsEnableRule("setupTradeRoute");
      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================
      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      // Certain parameters are way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gMaintainFirstLandUnitAmount = 4; // 4 Spearmen
         gMaintainSecondLandUnitAmount = 4; // 4 Chariot Archers
         gMaintainThirdLandUnitAmount = 2; // 2 Anubites
         gMaintainFourthLandUnitAmount = 1; // 1 Scorpion Man
         gMaintainFifthLandUnitAmount = 1; // 1 Avenger

         // Feeble attacks.
         gAttackStartSize = 3;
         gAttackMaxSize = 5;
      }

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);

      // Don't add Chariot Archers or Avengers until later.
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gThirdLandUnit);
      // Only start with Scorpion Men on Hard and Titan.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gAttackWave.addAttackUnitType(gFourthLandUnit);
      }

      // Record wakeup time.
      gWakeUpTime += xsGetTime();

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      gTimeToFarm = true;

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(239.0, 7.0, 146.0); // In front of our Migdol Stronghold.
      vector targetPoint = vector(110.0, 0.0, 158.0); // P1's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 Left");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(183.0, 0.0, 136.0)); // Walk through the left gate.
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      //int pathID2 = kbPathCreate("Path 2 Right");
      //kbPathAddWaypoint(pathID2, startPoint);
      //kbPathAddWaypoint(pathID2, vector(203.0, 0.0, 108.0)); // Walk through the right gate.
      //kbPathAddWaypoint(pathID2, targetPoint);
      //kbAttackRouteAddPath(routeID, pathID2);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );
      gAttackWave.displayFirstAttackStats();
      
      

      int landDefendPlan = createDefendPlan("Primary Land Defend", -1, 30.0, startPoint, 20, startPoint);
      aiPlanAddUnitType(landDefendPlan, gFirstLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gSecondLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gThirdLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gFourthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gFifthLandUnit, 0, 0, 200);

      // There are 3 Laborers stuck in a pit that we need to manually manage.
      int reservePlanID = aiPlanCreate("Reserve Plan", cPlanReserve, -1);
      aiPlanSetPriority(reservePlanID, 99);
      aiPlanAddUnitType(reservePlanID, cUnitTypeVillagerEgyptian, 3, 3, 3);
      int queryID = useSimpleUnitQuery(cUnitTypeVillagerEgyptian, cMyID, cUnitStateAlive, vector(210.0, 0.0, 258.0), 20.0);
      int numResults = kbUnitQueryExecute(queryID);
      int treeID = getClosestUnitByLocation(cUnitTypeTree, 0, cUnitStateAlive, vector(210.0, 0.0, 258.0), 20.0);
      int[] results = kbUnitQueryGetResults(queryID);

      for (int i = 0; i < numResults; i++)
      {
         aiPlanAddUnit(reservePlanID, results[i], false);
      }
      aiTaskWorkUnits(results, treeID);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      int time = xsGetTime();
      static bool more_units = false;

      // Start deploying Scorpion Men after 10 minutes on Moderate.
      if (cDifficultyCurrent == cDifficultyModerate)
      {
         if (time >= 600 + gWakeUpTime && more_units == false)
         {
            gAttackWave.addAttackUnitType(gFourthLandUnit);
            gAttackMaxSize *= 1.10; // Attack size increases by +10%
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
            more_units = true;
         }
      }

      // Start deploying Chariot Archers after 20 minutes on Moderate.
      if (cDifficultyCurrent == cDifficultyModerate)
      {
         if (time >= 1200 + gWakeUpTime && more_units == false)
         {
            gAttackWave.addAttackUnitType(gSecondLandUnit);
            gAttackMaxSize *= 1.10; // Attack size increases by +10%
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
            more_units = true;
         }
      }

      // Start deploying Chariot Archers and Avengers after 12 minutes on Hard and Titan.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         if (time >= 720 + gWakeUpTime && more_units == false)
         {
            gAttackWave.addAttackUnitType(gSecondLandUnit);
            gAttackWave.addAttackUnitType(gFifthLandUnit);
            gAttackMaxSize *= 1.25; // Attack size increases by +25%
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
            more_units = true;
         }
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott12StrategySetup()
{
   gStrategyManager.mStartingStrategy = cStrategyScenarioAttackWave;
   Strategy strategy = scenarioAttackWaveStrategy();
   gStrategyManager.addStrategy(strategy);
}

//==============================================================================
/*	preInit()

   This function is called in main() before any of the normal initialization
   happens. Use it to override default values of variables as needed for
   scenario effects.
*/
//==============================================================================
void preInit()
{
   gMaxVillagerCount *= gDifficultyModifierMaintainVillager;

   gMainGatherBase = createOverrideGatherBase(vector(295.00, 0.00, 225.00), 100);
   createOverrideGatherBase(vector(333.00, 0.00, 207.00), 75);

   gOverrideMaxVillagerPop = gMaxVillagerCount;
   setOverrideStrategy(fott12StrategySetup);

   gRBDSystem.setMaxFarmsPerBase(32);
   gRBDSystem.setMaxFarmsPerIteration(32);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// Use Serpents while attacking or if we're in danger next to the Guardian.
rule useSerpents
inactive
minInterval 5
{
   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   int unitID = -1;
   int numEnemies = -1;

   // Only invoke this after 8 minutes.
   int current_time = xsGetTime();
   if (current_time >= 480 + gWakeUpTime)
   {
      for (int i = 0; i < attackPlans.size(); i++)
      {
         if (aiPlanGetParentID(attackPlans[i]) == -1)
         {
            // We just take the first unit to scan from.
            unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
            if (unitID >= 0)
            {
               numEnemies = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 10.0);
               debugAttackWave("numEnemies for casting Serpents offensively: " + numEnemies);
               if (numEnemies >= 5)
               {
                  if (aiCastGodPowerAtPosition(cProtoPowerPlagueOfSerpents, kbUnitGetPosition(unitID)) == true)
                  {
                     debugAttackWave("Casted Serpents!");
                     xsEnableRule("useAncestors");
                     xsDisableRule("useSerpents");
                     return;
                  }
               }
            }
         }
      }
   }


   // Next to the gate that protects the Guardian.
   numEnemies = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, vector(267.0, 7.0, 143.0), 20.0);
   debugAttackWave("numEnemies for casting Serpents defensively: " + numEnemies);
   if (numEnemies >= 5)
   {
      if (aiCastGodPowerAtPosition(cProtoPowerPlagueOfSerpents, vector(262.0, 7.0, 143.0)) == true)
      {
         debugAttackWave("Casted Serpents!");
         xsEnableRule("useAncestors");
         xsDisableRule("useSerpents");
      }
   }
}

// Use Ancestors while attacking or if we're in danger near our Migdol Stronghold.
rule useAncestors
inactive
minInterval 5
{
   // Only initial delay is 5 minutes, after that go to regular interval.
   xsSetRuleMinIntervalSelf(10);
   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   int unitID = -1;
   int numEnemies = -1;

   // Only invoke this after 12 minutes.
   int current_time_2 = xsGetTime();
   if (current_time_2 >= 720 + gWakeUpTime)
   {
      for (int i = 0; i < attackPlans.size(); i++)
      {
         if (aiPlanGetParentID(attackPlans[i]) == -1)
         {
            // We just take the first unit to scan from.
            unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
            if (unitID >= 0)
            {
               numEnemies = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 10.0);
               debugAttackWave("numEnemies for casting Ancestors offensively: " + numEnemies);
               if (numEnemies >= 5)
               {
                  if (aiCastGodPowerAtPosition(cProtoPowerAncestors, kbUnitGetPosition(unitID)) == true)
                  {
                     debugAttackWave("Casted Ancestors!");
                     xsDisableRule("useAncestors");
                     return;
                  }
               }
            }
         }
      }
   }
   // Cast near Migdol Stronghold.
   numEnemies = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, vector(250.0, 7.0, 155.0), 20.0);
   debugAttackWave("numEnemies for casting Ancestors defensively: " + numEnemies);
   if (numEnemies >= 5)
   {
      if (aiCastGodPowerAtPosition(cProtoPowerAncestors, vector(239.0, 7.0, 146.0)) == true) // Cast on startPoint.
      {
         debugAttackWave("Casted Ancestors!");
         xsDisableRule("useAncestors");
      }
   }

}

rule setupTradeRoute
inactive
minInterval 15
{
   int marketID = getUnit(cUnitTypeMarket);
   int townCenterID = getUnit(cUnitTypeTownCenter);
   if (marketID < 0 || townCenterID < 0)
   {
      return;
   }

   int tradePlan = -1;

   // Trade to the town center.
   tradePlan = aiPlanCreate("Trade Plan", cPlanTrade);
   aiPlanSetVariableInt(tradePlan, cTradePlanTargetUnitTypeID, 0, cUnitTypeTownCenter);
   aiPlanSetVariableInt(tradePlan, cTradePlanTargetUnitID, 0, townCenterID);
   aiPlanSetPriority(tradePlan, 100);
   aiPlanAddUnitType(tradePlan, cUnitTypeCaravanEgyptian, 0, 0, 200);
   aiPlanSetVariableInt(tradePlan, cTradePlanMarketID, 0, marketID);
   aiPlanSetVariableBool(tradePlan, cTradePlanUpdateTarget, 0, false);

   if (tradePlan >= 0)
   {
      xsDisableRule("setupTradeRoute");
      return;
   }
}