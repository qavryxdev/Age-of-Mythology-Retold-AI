//==============================================================================
/* tna07_p2.xs
   
   Tricked Atlanteans (Kronos)

   AI player that trains a basic set of Atlantean units and launches frequent attacks against Player 6 (Kastor).

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

int gFirstLandUnit = cUnitTypeMurmillo; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 4;
int gSecondLandUnit = cUnitTypeKatapeltes; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 4;
int gThirdLandUnit = cUnitTypeTurma; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 4;
int gFourthLandUnit = cUnitTypeBehemoth; // Gets trained after a certain amount of time.
float gMaintainFourthLandUnitAmount = 1;

float gMaxVillagerCount = 2;
float gAttackStartDelay = 45; // In seconds. Not affected by multiplier.
float gAttackWaveInterval = 45; // In seconds. Not affected by multiplier.
float gAttackStartSize = 3;
float gAttackMaxSize = 10;

vector gOurTCLocation = vector(105.0, 0.0, 259.0);

Strategy scenarioAttackWaveStrategy()
{

    xsEnableRule("useTraitor");

   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugStrategy("***Starting Scenario Attack Wave Strategy***");
      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Murmillo
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Katapeltes
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Turma
   
      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);     // Behemoth

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setAttackSizeMultiplier(1.2);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      gAttackWave.addAttackUnitType(gThirdLandUnit);

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);

      gAttackWave.setPlayerToAttack(6); // Attack P6!

      // Where does our attack start and end.
      vector startPoint = vector(98.0, 0.0, 292.0); // By our military buildings.
      vector targetPoint = vector(177.0, 0.0, 274.0); // Kastor's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P6", startPoint, targetPoint);
      int pathID = kbPathCreate("Path 1 to Town Center");  // Straight ahead.
      kbPathAddWaypoint(pathID, startPoint);
      kbPathAddWaypoint(pathID, targetPoint);
      kbAttackRouteAddPath(routeID, pathID);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      int landDefendPlan = createDefendPlan("Defend Plan", -1, 15.0, startPoint, 10, startPoint);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      int time = xsGetTime();
      if (done == false)
      {
         if (time >= 600)
         {
            data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Behemoth
            gAttackWave.addAttackUnitType(gFourthLandUnit);
            debugAttackWave("Let's train some Behemoths now!");

            done = true;
         }
      }

      gAttackWave.update();
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

   gMainGatherBase = createOverrideGatherBase(vector(84.00, 0.00, 278.00), 59);

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

rule useTraitor
inactive
minInterval 5
{
   static int casts = 0;   // Track how many times we've invoked this power.
   static int delay = 480; // 8 minutes before we can invoke for the first time.
   if (delay > 0)
   {
      delay -= 5; // Same as the rule interval.
      return;
   }

   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   int unitID = -1;
   int targetID = -1;
   for (int i = 0; i < attackPlans.size(); i++)
   {
      if (aiPlanGetParentID(attackPlans[i]) == -1)
      {
         // We just take the first unit to scan from.
         unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
         if (unitID >= 0)
         {
           // Look for enemies.
            targetID = getUnitByLocation(cUnitTypeHumanSoldier, 6, cUnitStateAlive, kbUnitGetPosition(unitID), 20.0);
            if (targetID >= 1)
            {
               // Invoke god power!
               if (aiCastGodPowerAtPosition(cProtoPowerTraitor, kbUnitGetPosition(targetID)) == true)
               {
                  debugAttackWave("Casted Traitor!");
                  casts++;

                  if (casts >= 2)
                  {
                     xsDisableRule("useTraitor");
                     return;
                  }
                  else if (casts < 2)
                  {
                     delay = 180;   // 3 minutes before we can invoke for the second time.
                  }
               }
            }
         }
      }
   }
}