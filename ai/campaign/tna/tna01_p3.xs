//==============================================================================
/* tna01_p2.xs

   Yellow Norse player that maintains an army of Hirdmen.
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
int gFirstLandUnit = cUnitTypeHirdman; // Begins training once they reach the Classical Age.
float gMaintainFirstLandUnitAmount = 8;

float gMaxVillagerCount = 0; // No Villagers.
float gMaxFishingShipCount = 4;

float gAttackStartDelay = 580;
float gAttackWaveInterval = 340;
float gAttackStartSize = 4;
float gAttackMaxSize = 12;

float gInitialAttackStartSize = 5; // Used to calculate new values from increments before applying the multiplier.
float gInitialAttackMaxSize = 15; // Used to calculate new values from increments before applying the multiplier.

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

      // Certain parameters are way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gAttackWaveInterval = 600;
         gAttackStartSize = 3;
         gAttackMaxSize = 4;
      }

      if (cDifficultyCurrent >= cDifficultyHard)
      {
            gAttackStartDelay = 280;
            gAttackWaveInterval = 240;
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;

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
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      //==============================================================================
      // Init Shared part.
      //==============================================================================
      data.setFlag(cStrategyFlagAutomaticFishing, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(154.89, 2.03, 218.86); // Below the pig on a spit.
      vector basePoint = vector(155.75, 2.0, 239.82); // Between the torches.
      vector targetPoint = vector(6.28, 5.51, 236.88); // South of P1's base.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 start below the Town Center.");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
            debugAttackWave("***Starting Attack***");
         }
      );

      gLandDefendPlan = createDefendPlan("Primary Land Defend", -1, 20.0, basePoint, 10, basePoint);
      aiPlanSetVariableFloat(gLandDefendPlan, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      // Increase the attack size after 300 seconds (Hard and Titan only).
      static bool attack_increase = false;
      if (attack_increase == false)
      {
         if (cDifficultyCurrent >= cDifficultyHard && xsGetTime() >= 400)
         {
            gAttackMaxSize *= 1.25; // Increase by +25%
            attack_increase = true;
         }
      }

      gAttackWave.update();
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
   gMaxFishingShipCount *= gDifficultyModifierMaintainFishing;
   gOverrideMaxFishingShipPop = gMaxFishingShipCount;

   gOverrideClosestFishLocation = vector(136.19, 0.00, 171.47);
   gMaxFishDockScanRange = 560;

   setOverrideStrategy(tna01StrategySetup);

   gOverrideFarmCount = 10; // Just don't make too many cuz we don't need them that much.
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// Currently, we have no rules.