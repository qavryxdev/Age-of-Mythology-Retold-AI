//==============================================================================
/* fott30_p4.xs

   Had to change the Desired unit numbers to create plan that resembled the Legacy AI behaviour.
   Instead of 200, used smaller numbers such as 5, 8 or 3.
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
int gFirstLandUnit = cUnitTypeHuskarl; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 4;
int gSecondLandUnit = cUnitTypeHersir; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 3;

int gThirdLandUnit = cUnitTypeThrowingAxeman; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 4;
int gFourthLandUnit = cUnitTypeJarl; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 2;

int gFifthLandUnit = cUnitTypeBerserk; // Gets trained from the start.
float gMaintainFifthLandUnitAmount = 3;
int gSixthLandUnit = cUnitTypeFrostGiant; // Only used in defend plan.
float gMaintainSixthLandUnitAmount = 4;
int gSeventhLandUnit = cUnitTypeBallista; // Gets trained from the start.
float gMaintainSeventhLandUnitAmount = 1;

int gExtraLandUnitDelay = 10;

float gMaxVillagerCount = 5;


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
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSeventhLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gTrainDelay *= gDifficultyModifierTrainDelay;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);
      // Set train delay.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);
      data.setTrainDelay(gFifthLandUnit, gTrainDelay);
      data.setTrainDelay(gSeventhLandUnit, gTrainDelay);

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticOxCartTraining, true);
      gTimeToFarm = true;

      // We want to research our military upgrades automatically.
      data.setFlag(cStrategyFlagAutoResearchMilitaryUpgrades, true);
      xsEnableRule("militaryUpgradeManager");

      gAttackWave.setPlayerToAttack(1); // Attack player 1!
      
      // EASTERN PASS
      int easternPassDefendPlan = createDefendPlan("Eastern Pass Defend Plan", kbBaseGetMainID(cMyID), 15.0, vector(257.66, 0.44, 151.52), 10);
      aiPlanSetVariableFloat(easternPassDefendPlan, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(easternPassDefendPlan, gFirstLandUnit, 0, 0, 200);
      aiPlanAddUnitType(easternPassDefendPlan, gSecondLandUnit, 0, 0, 200);

      // MIDDLE PASS
      int middlePassDefendPlan = createDefendPlan("Middle Pass Defend Plan", kbBaseGetMainID(cMyID), 15.0, vector(223.80, 2.36, 194.25), 10);
      aiPlanSetVariableFloat(middlePassDefendPlan, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(middlePassDefendPlan, gThirdLandUnit, 0, 0, 200);

      // WESTERN PASS
      int westernPassDefendPlan = createDefendPlan("Western Pass Defend Plan", kbBaseGetMainID(cMyID), 15.0, vector(206.07, 0.00, 308.66), 10);
      aiPlanSetVariableFloat(westernPassDefendPlan, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(westernPassDefendPlan, gFourthLandUnit, 0, 0, 200);

      // TOWN CENTER
      int townCenterDefendPlan = createDefendPlan("Town Center Defend Plan", kbBaseGetMainID(cMyID), 20.0, vector(285.64, 0.00, 288.01), 10);
      aiPlanSetVariableFloat(townCenterDefendPlan, cDefendPlanEngageRange, 0, 50.0);
      aiPlanAddUnitType(townCenterDefendPlan, gFifthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(townCenterDefendPlan, gSixthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(townCenterDefendPlan, gSeventhLandUnit, 0, 0, 200);

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
   // This function is ran every second by the strategy system.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott30StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(293.00, 0.00, 311.00), 45);

   setOverrideStrategy(fott30StrategySetup);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}