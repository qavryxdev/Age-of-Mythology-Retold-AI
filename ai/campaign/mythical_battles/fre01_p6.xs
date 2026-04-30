//==============================================================================
/* fre01_p6.xs

   Fafnir's Lair (Freyr)
   Owns a temple in the eastern caves. Once activated, it maintains Fafnir dragons to guard the gold mines nearby.
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

float gTrainDelay = 20; // In seconds.
int gFirstLandUnit = cUnitTypeFafnir; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 2;

float gAttackStartDelay = cWaitWithAttacking; // In seconds - never supposed to attack.
float gAttackWaveInterval = cWaitWithAttacking; // In seconds - never supposed to attack.

float gAttackStartSize = 0;
float gAttackMaxSize = 0;

Strategy scenarioAttackWaveStrategy()
{
   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugAttackWave("***Starting Scenario Attack Wave Strategy***");

      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================
      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gTrainDelay *= gDifficultyModifierTrainDelay;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;

      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      
      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.setMinAttackSize(gAttackStartSize);
      gAttackWave.addAttackUnitType(gFirstLandUnit);  // Fafnirs
      gAttackWave.displayFirstAttackStats();

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start.
      vector startPoint = vector(261.0, 0.0, 43.0); // Among the gold mines.
      vector endPoint = vector(56.0, 0.0, 20.0); // In the enemy base.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, endPoint);
      int pathID = kbPathCreate("Path");
      kbPathAddWaypoint(pathID, startPoint);
      kbPathAddWaypoint(pathID, endPoint);
      kbAttackRouteAddPath(routeID, pathID);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(endPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      //int landDefendPlan = createDefendPlan("Primary Land Defend", -1, 20.0, startPoint, 20, startPoint);
      //aiPlanAddUnitType(landDefendPlan, gFirstLandUnit, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fre01StrategySetup()
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
   // Max out available military slots, we control this number via maintain plans anyway.
   gOverrideMaxMilitaryPop = 200;
   setOverrideStrategy(fre01StrategySetup);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}