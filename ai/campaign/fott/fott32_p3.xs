//==============================================================================
/* fott32_p3.xs

   Lothbrok's Clan (Loki)

   Norse player owning the base west of the player. They train units defensively,
   attacking once P1 cleared a path (destroyed a nearby enemy fortress).
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

float gTrainDelay = 10; // In seconds.
int gFirstLandUnit = cUnitTypeRaidingCavalry; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 4;
int gSecondLandUnit = cUnitTypeHuskarl; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 4;
int gThirdLandUnit = cUnitTypeMountainGiant; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 1;
float gMaxVillagerCount = 8;
float gAttackStartDelayLong = cWaitWithAttacking; // In seconds, used before the activation of attacks (Player destroyed a Fortress).
float gAttackStartDelay = 180; // In seconds, used after the activation of attacks (Player destroyed a Fortress).
float gAttackWaveInterval = 180; // In Seconds.
float gAttackStartSize = 4;
float gAttackMaxSize = 6;

Strategy scenarioAttackWaveStrategy()
{
   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugStrategy("***Starting Scenario Attack Wave Strategy***");
      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================
      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelayLong);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);  // Raiding Cavalry
      gAttackWave.addAttackUnitType(gSecondLandUnit); // Huskarls
      gAttackWave.addAttackUnitType(gThirdLandUnit);  // Mountain Giants

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticOxCartTraining, true);
      data.setFlag(cStrategyFlagAutomaticMainBaseTCRebuild, true);

      gAttackWave.setPlayerToAttack(2); // Attack player 2!

      // Where does our attack start and end.
      vector startPoint = vector(61.0, 1.0, 303.0);
      vector targetPoint = vector(258.0, 15.0, 309.0);

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.

      // Creating one attack route.
      int routeID = kbCreateAttackRouteWithPath("Route to Enemy", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Direct path to Enemy.");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path to Enemy, through enemy base on the side.");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(58.0, 3.0, 380.0));
      kbPathAddWaypoint(pathID2, vector(120.0, 3.0, 380.0));
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      // Set up a defend plan that handles all of our military units.
      int landDefendPlan = createDefendPlan("Land Defend Plan", kbBaseGetMainID(cMyID), 12.0, vector(61.0, 1.0, 304.0), 10);
      aiPlanSetVariableFloat(landDefendPlan, cDefendPlanEngageRange, 0, 42.0);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 200, 200);

      // Set up two explore plans to scout the map with our Ravens.
      int explorePlan = aiPlanCreate("Scout with Ravens 1", cPlanExplore);
      aiPlanAddUnitType(explorePlan, cUnitTypeRaven, 0, 1, 1);
      aiPlanSetVariableBool(explorePlan, cExplorePlanDoLoops, 0, false);
      aiPlanSetVariableBool(explorePlan, cExplorePlanAvoidingAttackedAreas, 0, false);
      aiPlanSetVariableInt(explorePlan, cExplorePlanNumberOfLoops, 0, -1);
      aiPlanSetFlag(explorePlan, cPlanFlagRequiresAllNeedUnits, true);
      aiPlanSetPriority(explorePlan, 90);

      explorePlan = aiPlanCreate("Scout with Ravens 2", cPlanExplore);
      aiPlanAddUnitType(explorePlan, cUnitTypeRaven, 0, 1, 1);
      aiPlanSetVariableBool(explorePlan, cExplorePlanDoLoops, 0, false);
      aiPlanSetVariableBool(explorePlan, cExplorePlanAvoidingAttackedAreas, 0, false);
      aiPlanSetVariableInt(explorePlan, cExplorePlanNumberOfLoops, 0, -1);
      aiPlanSetFlag(explorePlan, cPlanFlagRequiresAllNeedUnits, true);
      aiPlanSetPriority(explorePlan, 90);
      
      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;

      // Get P2's & P5's starting amount of Fortresses.
      static int fortCountAtStart = 0;
      if (fortCountAtStart == 0)
      {
         debugAttackWave("Cheating to look at all units on the map, looking for enemy Fortresses...");
         kbLookAtAllUnitsOnMap();
         int queryID = useSimpleUnitQuery(cUnitTypeFortress, 5, cUnitStateAlive);
         fortCountAtStart = kbUnitQueryExecute(queryID);
         queryID = useSimpleUnitQuery(cUnitTypeFortress, 2, cUnitStateAlive);
         int temp = kbUnitQueryExecute(queryID);
         fortCountAtStart += temp;
         debugAttackWave("Forts detected at start: " +fortCountAtStart);
      }

      if (done == false)
      {
         // Check if P2 or P5 lost a Fortress.
         kbLookAtAllUnitsOnMap(); // Cheating to look at all units on the map.
         int queryID = useSimpleUnitQuery(cUnitTypeFortress, 5, cUnitStateAlive);
         int fortCountNow = kbUnitQueryExecute(queryID);
         queryID = useSimpleUnitQuery(cUnitTypeFortress, 2, cUnitStateAlive);
         int temp = kbUnitQueryExecute(queryID);
         fortCountNow += temp;
         debugAttackWave("Forts detected now: " +fortCountNow);

         // If they have...
         if (fortCountNow < fortCountAtStart)
         {
            done = true;
            debugAttackWave("THEY LOST A FORTRESS?? They're gonna be easy pickings, time to attack!");
            gAttackWave.setAttackStartTime(gAttackStartDelay);
            gAttackWave.displayFirstAttackStats();
         }
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott32StrategySetup()
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
   gOverrideMaxVillagerPop = gMaxVillagerCount;

   gMainGatherBase = createOverrideGatherBase(vector(50.00, 0.00, 310.00), 50);
   gTimeToFarm = true;

   setOverrideStrategy(fott32StrategySetup);

   gOverrideFarmCount = 12; // We can't have too many farms due to space restrictions.
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, vector(55.0, 0.0, 287.0), 15.0); // Behind our TC.
      kbBuildingPlacementAddPositionInfluence(bpID, vector(55.0, 0.0, 287.0), 100.0, 15.0, cFalloffLinear); // Behind our TC.
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementSetStepSize(bpID, 0.5);
      aiPlanSetVariableBool(planID, cBuildPlanDoneWhenFoundationPlaced, 0, true);
      return (true);
   };
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}