//==============================================================================
/* tna07_p4.xs
   
   Promethean Horde (Kronos)

   Launches basic attacks against the player. It receives units via triggers. They eventually get control of the rampaging Prometheus Titan, using it to wipe the player's base.

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

int gFirstLandUnit = cUnitTypeTitanPrometheus; // We attack with this.
int gSecondLandUnit = cUnitTypePromethean; // We attack with this.
int gThirdLandUnit = cUnitTypePrometheanOffspring; // We attack with this.
int gFourthLandUnit = cUnitTypeBehemoth; // We attack with this.
int gFifthLandUnit = cUnitTypeSatyr; // We attack with this.

float gMaxVillagerCount = 0;
float gAttackStartDelay = 0; // In seconds. Not affected by multiplier.
float gSecondAttackStartDelay = 30; // In seconds. Not affected by multiplier.
float gAttackWaveInterval = 75; // In seconds. Not affected by multiplier.
float gAttackStartSize = 4;
float gAttackMaxSize = 4;

const vector firstPatrolPlanP1 = vector(115.00, 0.00, 168.00);
const vector firstPatrolPlanP2 = vector(187.00, 0.00, 160.00);
const vector secondPatrolPlanP1 = vector(101.00, 0.00, 148.00);
const vector secondPatrolPlanP2 = vector(223.00, 0.00, 150.00);
const vector thirdPatrolPlanP1 = vector(110.00, 0.00, 127.00);
const vector thirdPatrolPlanP2 = vector(211.00, 0.00, 121.00);
const float patrolPlanEngageRange = 20.0;
const float patrolPlanGatherDistance = 20.0;
const int patrolPlanMaxSize = 20;

vector gOurTCLocation = vector(159.00, 0.00, 143.00);

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

      // Certain parameters are way more lenient on easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
            gAttackStartSize = 3;
            gAttackMaxSize = 4;
            gAttackWaveInterval = 100;
      }

      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.addAttackUnitType(gFirstLandUnit);  // Prometheus Titan
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      gAttackWave.addAttackUnitType(gThirdLandUnit);
      gAttackWave.addAttackUnitType(gFourthLandUnit);
      gAttackWave.addAttackUnitType(gFifthLandUnit);

      gSecondAttackWave.setName("gSecondAttackWave");
      gSecondAttackWave.setAttackStartTime(gSecondAttackStartDelay);
      gSecondAttackWave.setAttackInterval(gAttackWaveInterval);
      gSecondAttackWave.setAttackSize(gAttackStartSize);
      gSecondAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gSecondAttackWave.setMaxAttackSize(gAttackMaxSize);
      gSecondAttackWave.addAttackUnitType(gFirstLandUnit);  // Prometheus Titan
      gSecondAttackWave.addAttackUnitType(gSecondLandUnit);
      gSecondAttackWave.addAttackUnitType(gThirdLandUnit);
      gSecondAttackWave.addAttackUnitType(gFourthLandUnit);
      gSecondAttackWave.addAttackUnitType(gFifthLandUnit);

      //==============================================================================
      // Init Shared part.
      //==============================================================================

      gAttackWave.setPlayerToAttack(1); // Attack P1!
      gSecondAttackWave.setPlayerToAttack(1); // Attack P1!

      // Where does our attack start and end.
      vector startPoint = vector(140.0, 0.0, 147.0); // Spawn point.
      vector targetPoint = vector(75.0, 0.0, 40.0); // Player's Town Center in the southeast.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 to P1");  // Shortest path: taking the eastern exit from Sikyos and coming in from above.
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(130.0, 0.0, 76.0));
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path 2 to P1");  // Going through the middle entrance and clearing the Settlement west of the player's base before coming in from the west.
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(74.0, 0.0, 148.0));
      kbPathAddWaypoint(pathID2, vector(36.0, 0.0, 119.0));
      kbPathAddWaypoint(pathID2, vector(83.0, 0.0, 82.0));
      kbPathAddWaypoint(pathID2, vector(257.0, 0.0, 63.0));
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      int pathID3 = kbPathCreate("Path 3 to P1");  // Long route: clearing the gold mines near the river, before going low and approaching from the south.
      kbPathAddWaypoint(pathID3, startPoint);
      kbPathAddWaypoint(pathID3, vector(62.0, 0.0, 228.0));
      kbPathAddWaypoint(pathID3, vector(29.0, 0.0, 200.0));
      kbPathAddWaypoint(pathID3, vector(14.0, 0.0, 36.0));
      kbPathAddWaypoint(pathID3, vector(231.0, 0.0, 15.0));
      kbPathAddWaypoint(pathID3, targetPoint);
      kbAttackRouteAddPath(routeID, pathID3);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      gSecondAttackWave.setGatherPoint(startPoint);
      gSecondAttackWave.setTargetPoint(targetPoint);
      gSecondAttackWave.setAttackRouteID(routeID);
      gSecondAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      int firstPatrolPlan = createDefendPlan("First Patrol Plan", kbBaseGetMainID(cMyID), patrolPlanGatherDistance, firstPatrolPlanP1, 10);
      aiPlanSetVariableFloat(firstPatrolPlan, cDefendPlanEngageRange, 0, patrolPlanEngageRange);
      aiPlanAddUnitType(firstPatrolPlan, cUnitTypeLogicalTypeMythUnitNotTitan, 0, 0, patrolPlanMaxSize);
      aiPlanSetVariableBool(firstPatrolPlan, cDefendPlanPatrol, 0, true);
      aiPlanSetNumberVariableValues(firstPatrolPlan, cDefendPlanPatrolWaypoints, 2);
      aiPlanSetVariableVector(firstPatrolPlan, cDefendPlanPatrolWaypoints, 0, firstPatrolPlanP1);
      aiPlanSetVariableVector(firstPatrolPlan, cDefendPlanPatrolWaypoints, 1, firstPatrolPlanP2);
      aiPlanSetPriority(firstPatrolPlan, 10); // Very low priority, don't steal from attack plans.

      int secondPatrolPlan = createDefendPlan("First Patrol Plan", kbBaseGetMainID(cMyID), patrolPlanGatherDistance, secondPatrolPlanP1, 10);
      aiPlanSetVariableFloat(secondPatrolPlan, cDefendPlanEngageRange, 0, patrolPlanEngageRange);
      aiPlanAddUnitType(secondPatrolPlan, cUnitTypeLogicalTypeMythUnitNotTitan, 0, 0, patrolPlanMaxSize);
      aiPlanSetVariableBool(secondPatrolPlan, cDefendPlanPatrol, 0, true);
      aiPlanSetNumberVariableValues(secondPatrolPlan, cDefendPlanPatrolWaypoints, 2);
      aiPlanSetVariableVector(secondPatrolPlan, cDefendPlanPatrolWaypoints, 0, secondPatrolPlanP1);
      aiPlanSetVariableVector(secondPatrolPlan, cDefendPlanPatrolWaypoints, 1, secondPatrolPlanP2);
      aiPlanSetPriority(secondPatrolPlan, 10); // Very low priority, don't steal from attack plans.

      int thirdPatrolPlan = createDefendPlan("First Patrol Plan", kbBaseGetMainID(cMyID), patrolPlanGatherDistance, thirdPatrolPlanP1, 10);
      aiPlanSetVariableFloat(thirdPatrolPlan, cDefendPlanEngageRange, 0, patrolPlanEngageRange);
      aiPlanAddUnitType(thirdPatrolPlan, cUnitTypeLogicalTypeMythUnitNotTitan, 0, 0, patrolPlanMaxSize);
      aiPlanSetVariableBool(thirdPatrolPlan, cDefendPlanPatrol, 0, true);
      aiPlanSetNumberVariableValues(thirdPatrolPlan, cDefendPlanPatrolWaypoints, 2);
      aiPlanSetVariableVector(thirdPatrolPlan, cDefendPlanPatrolWaypoints, 0, thirdPatrolPlanP1);
      aiPlanSetVariableVector(thirdPatrolPlan, cDefendPlanPatrolWaypoints, 1, thirdPatrolPlanP2);
      aiPlanSetPriority(thirdPatrolPlan, 10); // Very low priority, don't steal from attack plans.

      //int landDefendPlan = createDefendPlan("Defend Plan", -1, 15.0, startPoint, 10, startPoint);
      //aiPlanAddUnitType(landDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      if (done == false)
      {
         done = true;
      }

      // Never let the attack waves get larger than the initial values unless told so.
      if (gAttackMaxSize > 4 && cDifficultyCurrent == cDifficultyEasy)
      {
         gAttackMaxSize = 4;
         gAttackWave.setMaxAttackSize(gAttackMaxSize);
      }
      if (gAttackMaxSize > 6 && cDifficultyCurrent == cDifficultyModerate)
      {
         if (xsGetTime() <= 600)
         {
            gAttackMaxSize = 6;
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }
         // Only send more units later.
         if (xsGetTime() > 600)
         {
            gAttackMaxSize = 10;
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }
      }
      if (gAttackMaxSize > 6 && cDifficultyCurrent == cDifficultyHard)
      {
         if (xsGetTime() <= 480)
         {
            gAttackMaxSize = 6;
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }
         // Only send more units later.
         if (xsGetTime() > 480)
         {
            gAttackMaxSize = 12;
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }
      }
      if (gAttackMaxSize > 8 && cDifficultyCurrent == cDifficultyTitan)
      {
         if (xsGetTime() <= 480)
         {
            gAttackMaxSize = 8;
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }
         // Only send more units later.
         if (xsGetTime() > 480 && xsGetTime() <= 660)
         {
            gAttackMaxSize = 14;
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }
         if (xsGetTime() > 660)
         {
            gAttackMaxSize = 20;
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }
      }

      gAttackWave.update();
      // Only use the second attack wave on Hard and Titan.
      if(cDifficultyCurrent >= cDifficultyHard)
      {
         gSecondAttackWave.update();
      }
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}


// Set up the strategy.
void tna07StrategySetup()
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

   gOverrideMaxVillagerPop = gMaxVillagerCount;

   gMainGatherBase = createOverrideGatherBase(vector(159.00, 0.00, 143.00), 10);

   setOverrideStrategy(tna07StrategySetup);

   gOverrideFarmCount = 3; // Don't overdo the Farms.
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, gOurTCLocation, 15.0);
      kbBuildingPlacementAddPositionInfluence(bpID, gOurTCLocation, 100.0, 15.0, cFalloffLinear);
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
void postInit()
{
}