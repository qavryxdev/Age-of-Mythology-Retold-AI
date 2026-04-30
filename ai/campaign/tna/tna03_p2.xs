//==============================================================================
/* tna03_p2.xs

   Red Greek player that maintains a mix of human soldiers that move between
   most of the Plenty Vaults scattered across the map. Start with Hoplites,
   Toxotes, Minotaurs, Manticores, and Medusae that are not replaced.
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
float gMaintainFirstLandUnitAmount = 13;
int gSecondLandUnit = cUnitTypePeltast;
float gMaintainSecondLandUnitAmount = 10;
int gThirdLandUnit = cUnitTypeHippeus;
float gMaintainThirdLandUnitAmount = 3;
int gFourthLandUnit = cUnitTypeMyrmidon;
float gMaintainFourthLandUnitAmount = 4;

int gFifthLandUnit = cUnitTypeMinotaur;
float gMaintainFifthLandUnitAmount = 1;

float gMaxVillagerCount = 0; // No Villagers.
// No Attack waves.

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

      if (cDifficultyCurrent >= cDifficultyHard)
      {
            gMaintainFirstLandUnitAmount = 15;
            gMaintainSecondLandUnitAmount = 16;
            gMaintainThirdLandUnitAmount = 5;
            gMaintainFourthLandUnitAmount = 6;
            data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gTrainDelay *= gDifficultyModifierTrainDelay;


      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);
      data.setTrainDelay(gFifthLandUnit, gTrainDelay);

      //==============================================================================
      // Init Shared part.
      //==============================================================================

      vector basePoint = vector(457.59, 5.41, 205.18);
      gLandDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 20.0, basePoint, 10);
      aiPlanSetVariableFloat(gLandDefendPlan, cDefendPlanEngageRange, 0, 50.0);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
      
      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {

   // Subtracted from the in-game timer to calculate the current point on the interval:
   static int last_move_time = 0;

   // How much time has passed since we last shuffled the defend point:
   int cycle_time = xsGetTime() - last_move_time; 

   // Total game time, used to decide when to add the last vault into the pool:
   int current_time = xsGetTime(); 

   // The length of each interval before we move again:
   static int threshold = -1; 

   if (cDifficultyCurrent == cDifficultyEasy)
   {
      threshold = 240;
   }
   else if (cDifficultyCurrent == cDifficultyModerate)
   {
      threshold = 180;
   }   
   else if (cDifficultyCurrent == cDifficultyHard)
   {
      threshold = 110;

   }
   else if (cDifficultyCurrent >= cDifficultyTitan)
   {
      threshold = 90;
   }

   if (cycle_time >= threshold) // It's been long enough that we will now randomize the vault location again.
   {
      last_move_time += cycle_time;
      cycle_time = 0; // Reset cycle_time to 0 for the next interval.
      int vault_choice = 0;

      // Don't include the Vault closest to Kastor until after 10 minutes.
      if (current_time <= 600)
      {
         vault_choice = xsRandInt(0, 2);
      }
      else
      {
         vault_choice = xsRandInt(0, 3);
      }
      
      // Vectors for the possible vaults:
      vector North_Woods = vector(422.01, 0, 306.29);
      vector Center_North = vector(250.26, -2.70, 238.34);
      vector Center_East = vector(289.5, 4.18, 149.93);
      vector Center_South = vector(154.6, 6.61, 170.70);

      if (vault_choice == 0)
      {
         aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanTargetPoint, 0, North_Woods);
         aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanGatherPoint, 0, North_Woods);
      }
      else if (vault_choice == 1)
      {
         aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanTargetPoint, 0, Center_North);
         aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanGatherPoint, 0, Center_North);
      }
      else if (vault_choice == 2)
      {
         aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanTargetPoint, 0, Center_East);
         aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanGatherPoint, 0, Center_East);
      }
      else if (vault_choice == 3)
      {
         aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanTargetPoint, 0, Center_South);
         aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanGatherPoint, 0, Center_South);
      }
   }
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