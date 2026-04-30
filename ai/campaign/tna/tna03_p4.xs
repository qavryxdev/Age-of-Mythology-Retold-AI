//==============================================================================
/* tna03_p2.xs

   Pink Greek player that maintains a small army of human soldiers patrolling
   in a circle by the Plenty Vault in their base, as well as the one to the
   southeast.
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
int gFirstLandUnit = cUnitTypeHypaspist;
float gMaintainFirstLandUnitAmount = 5;
int gSecondLandUnit = cUnitTypePeltast;
float gMaintainSecondLandUnitAmount = 3;
int gThirdLandUnit = cUnitTypeToxotes;
float gMaintainThirdLandUnitAmount = 2;

float gMaxVillagerCount = 0; // No Villagers.
// No Attack waves.

int gPatrolPlanLeft = -1;
int gLandDefendPlan = -1;

Strategy scenarioAttackWaveStrategy()
{

   // Start enabling rules.
   xsEnableRule("useRestoration");

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

      gTrainDelay *= gDifficultyModifierTrainDelay;


      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);

      //==============================================================================
      // Init Shared part.
      //==============================================================================

      vector basePoint = vector(259.81, 0.0, 334.34);
      gLandDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 20.0, basePoint, 10);
      aiPlanSetVariableFloat(gLandDefendPlan, cDefendPlanEngageRange, 0, 50.0);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
      
      aiPlanSetFlag(gLandDefendPlan, cPlanFlagRequiresAllNeedUnits, true);
      aiPlanSetVariableBool(gLandDefendPlan, cDefendPlanPatrol, 0, true);
      aiPlanSetNumberVariableValues(gLandDefendPlan, cDefendPlanPatrolWaypoints, 5);
      aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanPatrolWaypoints, 0, vector(259.81, 0.0, 334.34));
      aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanPatrolWaypoints, 1, vector(198.68, 0.0, 351.06));
      aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanPatrolWaypoints, 2, vector(185.26, 0.44, 311.49));
      aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanPatrolWaypoints, 3, vector(250.73, -2.70, 246.85));
      aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanPatrolWaypoints, 4, vector(297.10, 0.0, 320.68));
      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {

      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void tna03StrategySetup()
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
   // gMaxVillagerCount *= gDifficultyModifierMaintainVillager;

   gOverrideMaxVillagerPop = gMaxVillagerCount;
   setOverrideStrategy(tna03StrategySetup);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// Bronze our army if we're in combat.
rule useRestoration
inactive
minInterval 3
{
   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   int unitID = -1;
   int numEnemies = -1;
   for (int i = 0; i < attackPlans.size(); i++)
   {
      if (aiPlanGetParentID(attackPlans[i]) == -1)
      {
         // We just take the first unit to scan from.
         unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
         if (unitID >= 0)
         {
            numEnemies =
               getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 10.0);
            debugAttackWave("numEnemies for casting Restoration: " + numEnemies);
            if (numEnemies >= 5)
            {
               if (aiCastGodPowerAtPosition(cProtoPowerRestoration, kbUnitGetPosition(unitID)) == true)
               {
                  debugAttackWave("Casted Restoration!");
                  xsDisableRule("useRestoration");
               }
            }
         }
      }
   }
}