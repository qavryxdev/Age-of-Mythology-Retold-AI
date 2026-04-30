//==============================================================================
/* tna06_p2.xs

   Red Greek player that owns the two bases in the eastern area. They send
   two different armies to attack the eastern Underworld Passage.
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
int gFirstLandUnit = cUnitTypeHoplite; // Starts training once Objective 2 is complete.
float gMaintainFirstLandUnitAmount = 8;
int gSecondLandUnit = cUnitTypeHippeus; // Starts training once Objective 2 is complete.
float gMaintainSecondLandUnitAmount = 8;

float gAttackStartDelay = cWaitWithAttacking; // Updates to 360 once you complete Objective 2.
float gAttackWaveInterval = 180; // In seconds; southern base only.

float gAttackStartSize = 6;
float gAttackMaxSize = 10;
int gLandDefendPlan = -1;

Strategy scenarioAttackWaveStrategy()
{
   // This should never fail.

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

      // Don't apply multipliers to first attacks until they're called upon.
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;

      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;

      // Define first attack.
      gAttackStartDelay = 360;
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      // gAttackStartDelay += xsGetTime();

      // We can now start maintaining new units.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);

      // Details about the attack waves.
      // North Base
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      gAttackWave.setAttackStartTime(gAttackStartDelay);


      //==============================================================================
      // Init Shared part.
      //==============================================================================

      // * * * * * * * * * * * * * //
      //  Attack Plan - North Base //
      // * * * * * * * * * * * * * //

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector gatherPoint = vector(237.0, 0.21, 144.87); // In the middle of the north base.
      vector targetPoint = vector(221.45, -0.27, 55.12); // At the east Underworld Passage.
      // vector targetPoint = vector(203.60, -0.26, 49.30); // At the east Underworld Passage.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("North Wave", gatherPoint, targetPoint);

      // Northern attack route.
      int pathID1 = kbPathCreate("North Attack Route");
      kbPathAddWaypoint(pathID1, gatherPoint);
      kbPathAddWaypoint(pathID1, vector(224.55, 0.0, 97.40)); // Block #1
      kbPathAddWaypoint(pathID1, targetPoint); // End point.
      kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID1);

      gAttackWave.setGatherPoint(gatherPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      // Main defense is in the left area.
      gLandDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 40.0, gatherPoint, 10);
      aiPlanAddUnitType(gLandDefendPlan, gFirstLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, gSecondLandUnit, 0, 0, 200);
      // We don't activate the plan until Arkantos and Ajax make it to the Temple.
      
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
void tna06StrategySetup()
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

   setOverrideStrategy(tna06StrategySetup);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// Restore our army if we're in combat.
rule useRestoration
inactive
minInterval 3
{
   int numEnemies = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, 1, cUnitStateAlive, vector(237.0, 0.0, 144.0), 30.0);
   int numAllies = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive, vector(237.0, 0.0, 144.0), 25.0);
   debugAttackWave("numEnemies for casting Restoration " + numEnemies);
   debugAttackWave("numAllies for casting Restoration: " + numAllies);
   if (numEnemies >= 6 && numAllies >= 10)
   {
      if (aiCastGodPowerAtPosition(cProtoPowerRestoration, vector(237.0, 0.0, 144.0)) == true)
      {
         debugAttackWave("Casted Restoration!");
         xsDisableRule("useRestoration");
      }
   }
}