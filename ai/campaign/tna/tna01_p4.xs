//==============================================================================
/* tna01_p2.xs

   Maroon Norse player that maintains a purely defensive force of Huskarls and Throwing Axemen.
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
int gFirstLandUnit = cUnitTypeThrowingAxeman;
float gMaintainFirstLandUnitAmount = 6;
int gSecondLandUnit = cUnitTypeHuskarl;
float gMaintainSecondLandUnitAmount = 4;

float gMaxVillagerCount = 0; // No Villagers.
// No Attack waves.

int gLandDefendPlan = -1;

Strategy scenarioAttackWaveStrategy()
{

   // Start enabling rules.
   // There are no rules right now.

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

      gTrainDelay *= gDifficultyModifierTrainDelay;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      //==============================================================================
      // Init Shared part.
      //==============================================================================
      vector basePoint = vector(237.65, 11.27, 166.16);

      float engageRange = selectByDifficulty(20.0, 20.0, 30.0, 30.0, 30.0, 30.0);
      gLandDefendPlan = createDefendPlan("Primary Land Defend", -1, 20.0, basePoint, 50, basePoint);
      aiPlanSetVariableFloat(gLandDefendPlan, cDefendPlanEngageRange, 0, engageRange);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      // gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void tna01StrategySetup()
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
   gOverrideMaxMilitaryPop = 200; // Max out available military slots, we control this number via maintain plans anyway.
   // gMaxVillagerCount *= gDifficultyModifierMaintainVillager;

   gOverrideMaxVillagerPop = gMaxVillagerCount;
   setOverrideStrategy(tna01StrategySetup);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// Currently, we have no rules.