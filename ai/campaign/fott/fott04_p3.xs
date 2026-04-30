//==============================================================================
/* fott04_p4.xs

   Red Greek player owning the small base in the west. Does nothing but gather.
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

float gMaxVillagerCount = 2;

Strategy scenarioSPCCustomStrategy()
{
   Strategy strategy;
   strategy.mData.mID = cStrategySPCCustom;
   strategy.mName = "SPC Custom";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugAttackWave("***Starting Custom SPC Strategy***");
      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);

      // We defend our TC and gather next to it.
      int landDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 30.0, vector(38.0, 0, 200.0));
      aiPlanAddUnitType(landDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott04StrategySetup()
{
   gStrategyManager.mStartingStrategy = cStrategySPCCustom;
   Strategy strategy = scenarioSPCCustomStrategy();
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

   gMainGatherBase = createOverrideGatherBase(vector(27.00, 0.00, 201.00), 30);

   setOverrideStrategy(fott04StrategySetup);

   gOverrideFarmCount = 0; // Not allowed to farm.
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}