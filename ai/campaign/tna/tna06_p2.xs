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
int gSecondLandUnit = cUnitTypeToxotes; // Starts training once Objective 2 is complete.
float gMaintainSecondLandUnitAmount = 8;
int gThirdLandUnit = cUnitTypeMyrmidon; // Starts training once Objective 2 is complete.
float gMaintainThirdLandUnitAmount = 16;

float gAttackStartDelay = cWaitWithAttacking; // Updates to 240 once you complete Objective 2.
float gAttackWaveInterval = 180; // In seconds; southern base only.

float gAttackStartSize = 6;
float gAttackMaxSize = 10;
int gLandDefendPlan = -1;

Strategy scenarioAttackWaveStrategy()
{
   // This should never fail.

   // Start enabling rules.
   xsEnableRule("useBronze");

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

      // Don't apply multipliers to first attacks until they're called upon.
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;

      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;

      // Define first attack.
      gAttackStartDelay = 240;
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      // gAttackStartDelay += xsGetTime();

      // We can now start maintaining new units.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      gAttackWave.setAttackStartTime(gAttackStartDelay);

      gSecondAttackWave.addAttackUnitType(gThirdLandUnit);


      //==============================================================================
      // Init Shared part.
      //==============================================================================

      // * * * * * * * * * * * * * //
      //  Attack Plan - South Base //
      // * * * * * * * * * * * * * //

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector gatherPoint = vector(129.59, 0.17, 30.29); // In the middle of the south base.
      vector targetPoint = vector(221.45, -0.27, 55.12); // At the east Underworld Passage.
      // vector targetPoint = vector(203.60, -0.26, 49.30); // At the south Underworld Passage.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("South Wave", gatherPoint, targetPoint);
      
      // Southern attack route.
      int pathID1 = kbPathCreate("South Attack Route");
      kbPathAddWaypoint(pathID1, gatherPoint);
      kbPathAddWaypoint(pathID1, targetPoint); // End point.
      kbAttackRouteAddPath(kbAttackRouteGetByName("South Wave"), pathID1);
      debugAttackWave("We've added a new route!");

      gAttackWave.setGatherPoint(gatherPoint);
      gAttackWave.setTargetPoint(targetPoint);

      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      gLandDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 40.0, gatherPoint, 10);
      aiPlanAddUnitType(gLandDefendPlan, gFirstLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, gSecondLandUnit, 0, 0, 200);
      // Myrmidons aren't part of the defense plan; they're just hanging out on the peak.
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

// Bronze our army if we're in combat.
rule useBronze
inactive
minInterval 3
{
   int numEnemies = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, 1, cUnitStateAlive, vector(129.0, 0.0, 30.0), 35.0);
   int numAllies = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive, vector(129.0, 0.0, 30.0), 30.0);
   debugAttackWave("numEnemies for casting Restoration " + numEnemies);
   debugAttackWave("numAllies for casting Restoration: " + numAllies);
   if (numEnemies >= 6 && numAllies >= 10)
   {
      if (aiCastGodPowerAtPosition(cProtoPowerBronze, vector(129.0, 0.0, 30.0)) == true)
      {
         debugAttackWave("Casted Bronze!");
         xsDisableRule("useBronze");
      }
   }
}