//==============================================================================
/* tgg02_p2.xs

   Rolf's Raiders (Odin)

   Tightly scripted AI that solely focuses on naval combat. They maintain Arrow and Siege Ships, using them
   to wander randomly between different points of the map.

   One Arrow Ship will occasionally harass the player's base.

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

int gFirstWaterUnit = cUnitTypeLongboat; // Gets trained from the start.
float gMaintainFirstWaterUnitAmount = 4;
int gSecondWaterUnit = cUnitTypeDragonShip; // Gets trained from the start.
float gMaintainSecondWaterUnitAmount = 4;
int gFirstLandUnit = cUnitTypeBallista; // Placeholder.
float gMaintainFirstLandUnitAmount = 0;

float gAttackStartDelay = cWaitWithAttacking; // In seconds.
float gAttackWaveInterval = 9999; // In Seconds.
float gAttackStartSize = 0;
float gAttackMaxSize = 0;
float gMaxVillagerCount = 0;
float gMaxFishingShipCount = 0;

float gWakeUpTime = 0;

vector gActiveDefendPoint1 = cInvalidVector;
vector gActiveDefendPoint2 = cInvalidVector;
vector gActiveDefendPoint3 = cInvalidVector;
vector gDefendPoint1 = vector(89.0, 0.0, 90.0);
vector gDefendPoint2 = vector(53.0, 0.0, 199.0);
vector gDefendPoint3 = vector(251.0, 0.0, 118.0);

vector gActiveAnnoyPoint = cInvalidVector;
vector gAnnoyPoint1 = vector(6.0, 0.0, 133.0);
vector gAnnoyPoint2 = vector(22.0, 0.0, 64.0);

int gPrimaryDefendPlanID = -1;
int gSecondaryDefendPlanID = -1;
int gTertiaryDefendPlanID = -1;
int gAnnoyPlanID = -1;



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
      gMaintainFirstWaterUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondWaterUnitAmount *= gDifficultyModifierMaintainUnit;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstWaterUnit, gMaintainFirstWaterUnitAmount);
      data.addUnitToMaintain(gSecondWaterUnit, gMaintainSecondWaterUnitAmount);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(39.0, 0.0, 227.0);
      vector targetPoint = vector(26.0, 0.0, 50.0); // Central beach on the player's island.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.

      // Creating one attack route, to have something in place if we decide to make this player attack in the future.
      int routeID = kbCreateAttackRouteWithPath("Route to Enemy", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path to Enemy");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      return true;
   };            

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      gAttackWave.update();
      return cStrategyContinue;
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void tgg02StrategySetup()
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
   gOverrideMaxVillagerPop = gMaxVillagerCount;

   gMainGatherBase = createOverrideGatherBase(vector(17.00, 0.00, 281.00), 53);

   xsEnableRule("awaitingStartup");

   setOverrideStrategy(tgg02StrategySetup);
   gOverrideMaxFishingShipPop = gMaxFishingShipCount;
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// *** RULE - awaitingStartup ***
// Wait until "gStartInactive" becomes 'false', which is the case when using our designated AI activation triggers.
// That will activate us.
rule awaitingStartup
inactive
minInterval 5
{
   // Keep cancelling if the AI is not yet activated.
   if (gStartInactive == true)
   {
      return;
   }

   // Once it is activated...
   debugAttackWave("*** I AM ACTIVATED ***");
   gWakeUpTime = xsGetTime();

   // Create tiny defense plans to keep warships in specific locations near the docks.
   // Longboats
   vector gatherPointLongboats = vector(83.0, 0.0, 275.0);
   int gatherLongboatsID = createDefendPlan("Gather Longboats", -1, 15.0, gatherPointLongboats, 10, gatherPointLongboats);
   aiPlanSetVariableFloat(gatherLongboatsID, cDefendPlanEngageRange, 0, 20.0);
   aiPlanAddUnitType(gatherLongboatsID, gFirstWaterUnit, 0, 0, 200);

   // Dragon Ships
   vector gatherPointDragonShips = vector(39.0, 0.0, 227.0);
   int gatherDragonShipsID = createDefendPlan("Gather Dragon Ships", -1, 15.0, gatherPointDragonShips, 10, gatherPointDragonShips);
   aiPlanSetVariableFloat(gatherDragonShipsID, cDefendPlanEngageRange, 0, 20.0);
   aiPlanAddUnitType(gatherDragonShipsID, gSecondWaterUnit, 0, 0, 200);

   // Enable other rules.
   xsEnableRule("monitorForPlayerDock");

   // End self.
   xsDisableRule("awaitingStartup");
}

rule monitorForPlayerDock
inactive
minInterval 10
{
   debugAttackWave("Cheating to look at all units on the map, looking for a player dock...");
   kbLookAtAllUnitsOnMap();
   // Do nothing if the player does not have a dock yet.
   if (getUnit(cUnitTypeDock, 1, cUnitStateAlive) <= 0)
   {
      return;
   }

   // The player has a dock! Time to rotate our ships around and occasionally annoy the player.
   debugAttackWave("The player has a dock! Time to get aggressive!");

   // Create the primary defend plan that cycles between three different points at random.
   gPrimaryDefendPlanID = createDefendPlan("Rotating Defend Plan 1", -1, 20.0, gDefendPoint1, 10, gDefendPoint1);
   aiPlanSetVariableFloat(gPrimaryDefendPlanID, cDefendPlanEngageRange, 0, 30.0);
   aiPlanAddUnitType(gPrimaryDefendPlanID, gFirstWaterUnit, 0, gMaintainFirstWaterUnitAmount * 0.4, gMaintainFirstWaterUnitAmount * 0.4);
   aiPlanAddUnitType(gPrimaryDefendPlanID, gSecondWaterUnit, 0, gMaintainSecondWaterUnitAmount * 0.4, gMaintainFirstWaterUnitAmount * 0.4);

   gSecondaryDefendPlanID = createDefendPlan("Rotating Defend Plan 2", -1, 20.0, gDefendPoint2, 10, gDefendPoint2);
   aiPlanSetVariableFloat(gSecondaryDefendPlanID, cDefendPlanEngageRange, 0, 30.0);
   aiPlanAddUnitType(gSecondaryDefendPlanID, gFirstWaterUnit, 0, gMaintainFirstWaterUnitAmount * 0.3, gMaintainFirstWaterUnitAmount * 0.3);
   aiPlanAddUnitType(gSecondaryDefendPlanID, gSecondWaterUnit, 0, gMaintainSecondWaterUnitAmount * 0.3, gMaintainFirstWaterUnitAmount * 0.3);

   gTertiaryDefendPlanID = createDefendPlan("Rotating Defend Plan 3", -1, 20.0, gDefendPoint3, 10, gDefendPoint3);
   aiPlanSetVariableFloat(gTertiaryDefendPlanID, cDefendPlanEngageRange, 0, 30.0);
   aiPlanAddUnitType(gTertiaryDefendPlanID, gFirstWaterUnit, 0, gMaintainFirstWaterUnitAmount * 0.3, gMaintainFirstWaterUnitAmount * 0.3);
   aiPlanAddUnitType(gTertiaryDefendPlanID, gSecondWaterUnit, 0, gMaintainSecondWaterUnitAmount * 0.3, gMaintainFirstWaterUnitAmount * 0.3);

   // Randomize starting position.
   switch(xsRandInt(1, 3))
   {
      case 1:
      {
         gActiveDefendPoint1 = gDefendPoint1;
         gActiveDefendPoint2 = gDefendPoint2;
         gActiveDefendPoint3 = gDefendPoint3;
         debugAttackWave("Defend Point 1 chosen: we're going near the player's shore!");
         break;
      }
      case 2:
      {
         gActiveDefendPoint1 = gDefendPoint2;
         gActiveDefendPoint2 = gDefendPoint3;
         gActiveDefendPoint3 = gDefendPoint1;
         debugAttackWave("Defend Point 2 chosen: we're staying close to home.");
         break;
      }
      case 3:
      {
         gActiveDefendPoint1 = gDefendPoint3;
         gActiveDefendPoint2 = gDefendPoint1;
         gActiveDefendPoint3 = gDefendPoint2;
         debugAttackWave("Defend Point 3 chosen: we're going near our rival's shore!");
         break;
      }
   }

   aiPlanSetVariableVector(gPrimaryDefendPlanID, cDefendPlanTargetPoint, 0, gActiveDefendPoint1);
   aiPlanSetVariableVector(gPrimaryDefendPlanID, cDefendPlanGatherPoint, 0, gActiveDefendPoint1);

   aiPlanSetVariableVector(gSecondaryDefendPlanID, cDefendPlanTargetPoint, 0, gActiveDefendPoint2);
   aiPlanSetVariableVector(gSecondaryDefendPlanID, cDefendPlanGatherPoint, 0, gActiveDefendPoint2);

   aiPlanSetVariableVector(gTertiaryDefendPlanID, cDefendPlanTargetPoint, 0, gActiveDefendPoint3);
   aiPlanSetVariableVector(gTertiaryDefendPlanID, cDefendPlanGatherPoint, 0, gActiveDefendPoint3);

   // Enable other rules.
   xsEnableRule("cycleDefendPlan");

   // On Moderate or above, enable 'annoy' plans (single ships grazing the player's shores).
   if (cDifficultyCurrent > cDifficultyEasy)
   {
      xsEnableRule("enableAnnoyPlan");
   }

   // End self.
   xsDisableRule("monitorForPlayerDock");
}

rule cycleDefendPlan
inactive
minInterval 75
{
   switch(xsRandInt(1, 3))
   {
      case 1:
      {
         gActiveDefendPoint1 = gDefendPoint1;
         gActiveDefendPoint2 = gDefendPoint2;
         gActiveDefendPoint3 = gDefendPoint3;
         debugAttackWave("Defend Point 1 chosen: we're going near the player's shore!");
         break;
      }
      case 2:
      {
         gActiveDefendPoint1 = gDefendPoint2;
         gActiveDefendPoint2 = gDefendPoint3;
         gActiveDefendPoint3 = gDefendPoint1;
         debugAttackWave("Defend Point 2 chosen: we're staying close to home.");
         break;
      }
      case 3:
      {
         gActiveDefendPoint1 = gDefendPoint3;
         gActiveDefendPoint2 = gDefendPoint1;
         gActiveDefendPoint3 = gDefendPoint2;
         debugAttackWave("Defend Point 3 chosen: we're going near our rival's shore!");
         break;
      }
   }

   aiPlanSetVariableVector(gPrimaryDefendPlanID, cDefendPlanTargetPoint, 0, gActiveDefendPoint1);
   aiPlanSetVariableVector(gPrimaryDefendPlanID, cDefendPlanGatherPoint, 0, gActiveDefendPoint1);

   aiPlanSetVariableVector(gSecondaryDefendPlanID, cDefendPlanTargetPoint, 0, gActiveDefendPoint2);
   aiPlanSetVariableVector(gSecondaryDefendPlanID, cDefendPlanGatherPoint, 0, gActiveDefendPoint2);

   aiPlanSetVariableVector(gTertiaryDefendPlanID, cDefendPlanTargetPoint, 0, gActiveDefendPoint3);
   aiPlanSetVariableVector(gTertiaryDefendPlanID, cDefendPlanGatherPoint, 0, gActiveDefendPoint3);

   return;
}

rule enableAnnoyPlan
inactive
minInterval 5
{
   // Do not bother with this until 3 minutes have passed since we were activated.
   if (xsGetTime() < 180 + gWakeUpTime)
   {
      return;
   }

   // Create an 'annoy' defend plan that cycles between two points at random.
   // One point is near the player base, the other is a bit further away.
   // When the point near the player base is chosen, we will appear to be 'annoying' him with a warship.
   gAnnoyPlanID = createDefendPlan("Annoy Plan", -1, 20.0, gAnnoyPoint1, 10, gAnnoyPoint1);
   aiPlanAddUnitType(gAnnoyPlanID, cUnitTypeAbstractWarship, 0, 1, 1);
   // Randomize starting position.
   switch(xsRandInt(1, 2))
   {
      case 1:
      {
         gActiveAnnoyPoint = gAnnoyPoint1;
         debugAttackWave("Annoy Point 1 chosen: we're staying away from the player... for now.");
         break;
      }
      case 2:
      {
         gActiveAnnoyPoint = gAnnoyPoint2;
         debugAttackWave("Annoy Point 2 chosen: we're going near the player's base!");
         break;
      }
   }
   aiPlanSetVariableVector(gAnnoyPlanID, cDefendPlanTargetPoint, 0, gActiveAnnoyPoint);
   aiPlanSetVariableVector(gAnnoyPlanID, cDefendPlanGatherPoint, 0, gActiveAnnoyPoint);

   // Enable other rules.
   xsEnableRule("cycleAnnoyPlan");

   // End self.
   xsDisableRule("enableAnnoyPlan");
}

rule cycleAnnoyPlan
inactive
minInterval 50
{
   switch(xsRandInt(1, 2))
   {
      case 1:
      {
         gActiveAnnoyPoint = gAnnoyPoint1;
         debugAttackWave("Annoy Point 1 chosen: we're staying away from the player... for now.");
         break;
      }
      case 2:
      {
         gActiveAnnoyPoint = gAnnoyPoint2;
         debugAttackWave("Annoy Point 2 chosen: we're going near the player's base!");
         break;
      }
   }

   aiPlanSetVariableVector(gAnnoyPlanID, cDefendPlanTargetPoint, 0, gActiveAnnoyPoint);
   aiPlanSetVariableVector(gAnnoyPlanID, cDefendPlanGatherPoint, 0, gActiveAnnoyPoint);
   return;
}