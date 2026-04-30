//==============================================================================
/* fott22_p4

   Continuously trains Einheri and attacks the plater every 4:30 minutes.
   Favor and Resource Mechanic needs to be updated.

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
float gTrainDelay = 60; // In seconds.
int gFirstLandUnit = cUnitTypeEinheri; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 3;
int gExtraLandUnitDelay = 10;

float gAttackStartDelay = 520; // In seconds.
float gAttackWaveInterval = 400; // In seconds.
float gAttackStartSize = 2;
float gAttackMaxSize = 3;
int gLandDefendPlan = -1;


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

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;
      gExtraLandUnitDelay += xsGetTime(); // Offset for starting time.



      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);



      // Train delay, how long the AI waits before queuing up another unit.
      int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gFirstLandUnit);
      aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gFirstLandUnit, cProtoStatTrainPoints) + gTrainDelay);



      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);


      //==============================================================================
      // Init Shared part.
      //==============================================================================
      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(275.0, 0.0, 83.0); // Next to the Hill Fort
      vector targetPoint = vector(175.0, 0.0, 123.0); // By the southwestern Settlement.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(351.0, 0.0, 109.0)); // 1st Waypoint
      kbPathAddWaypoint(pathID1, vector(287.0, 0.0, 211.0)); // 2nd Waypoint
      kbPathAddWaypoint(pathID1, vector(211.0, 0.0, 265.0)); // 3rd Waypoint
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path 2");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(275.0, 0.0, 53.0)); // 1st Waypoint
      kbPathAddWaypoint(pathID2, vector(183.0, 0.0, 139.0)); // 2nd Waypoint
      kbPathAddWaypoint(pathID2, vector(211.0, 0.0, 265.0)); // 3rd Waypoint
      kbPathAddWaypoint(pathID2, vector(287.0, 0.0, 211.0)); // 4th Waypoint
      kbPathAddWaypoint(pathID2, vector(351.0, 0.0, 109.0)); // 5th Waypoint
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });


// Defend Points (Divided to ensure a more natural distribution of guards)
      int gLeftDefendPlan = -1;
      int gRightDefendPlan = -1;

   // SPLIT AMOUNTS
      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 2; // Einheri

   // DEFINE THE PLANS
      // Left
      gLeftDefendPlan = createDefendPlan("Left Defense Plan", kbBaseGetMainID(cMyID), 10, vector(279.0, 0.0, 143.0), 20);
      aiPlanSetVariableFloat(gLeftDefendPlan, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gLeftDefendPlan, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Einheri

      // Right
      gRightDefendPlan = createDefendPlan("Right Defense Plan", kbBaseGetMainID(cMyID), 10, vector(279.0, 0.0, 81.0), 20);
      aiPlanSetVariableFloat(gRightDefendPlan, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gRightDefendPlan, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Einheri

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
      if (done == false && time >= gExtraLandUnitDelay)
      {
         done = true;

        
    

         
     

         // Bump our Priest maintain.

      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott18StrategySetup()
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

   setOverrideStrategy(fott18StrategySetup);
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


// On hard and titan defend the Tamarisk Tree continuously.
