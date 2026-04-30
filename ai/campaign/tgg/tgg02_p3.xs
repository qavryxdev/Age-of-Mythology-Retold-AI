//==============================================================================
/* tgg02_p3.xs

   Bjarni's Brigands.
*/
//==============================================================================
// Includes

include "core\main.xs"; // The bulk of the AI.
include "campaign/global_spc_modifiers.xs"; // global modifiers for difficulties.

//==============================================================================
/*	Rules

   Add scenario-specific rules & functions in the section below.
*/
//==============================================================================

int gFirstWaterUnit = cUnitTypeDragonShip; 
float gMaintainFirstWaterUnitAmount = 4;
int gSecondWaterUnit = cUnitTypeDreki; 
float gMaintainSecondWaterUnitAmount = 4;
int gThirdWaterUnit = cUnitTypeTransportShipNorse; 
float gMaintainThirdWaterUnitAmount = 1;  // Not affected by multiplier.

int gFirstLandUnit = cUnitTypeJarl;
float gMaintainFirstLandUnitAmount = 3;  // Not affected by multiplier.
int gSecondLandUnit = cUnitTypeBerserk;
float gMaintainSecondLandUnitAmount = 5;  // Not affected by multiplier.

float gAttackStartDelay = 360; // In seconds.
float gAttackWaveInterval = 360; // In Seconds.
float gAttackStartSize = 4;
float gAttackMaxSize = 8;  // Not affected by multiplier.
float gMaxVillagerCount = 0;
float gMaxFishingShipCount = 0;

float gWakeUpTime = 0;

vector gActiveDefendPoint1 = cInvalidVector;
vector gActiveDefendPoint2 = cInvalidVector;
vector gActiveDefendPoint3 = cInvalidVector;
vector gDefendPoint1 = vector(98.0, 0.0, 82.0);
vector gDefendPoint2 = vector(256.0, 0.0, 112.0);
vector gDefendPoint3 = vector(60.0, 0.0, 195.0);

vector gActiveAnnoyPoint = cInvalidVector;
vector gAnnoyPoint1 = vector(106.0, 0.0, 45.0);
vector gAnnoyPoint2 = vector(132.0, 0.0, 11.0);

int gPrimaryDefendPlanID = -1;
int gSecondaryDefendPlanID = -1;
int gTertiaryDefendPlanID = -1;
int gAnnoyPlanID = -1;
// Water patrol
/*
const vector waterPatrolStartPoint = vector(370.70, 0.00, 318.89);
const vector waterPatrolP1 = vector(318.25, 0.00, 255.68);
const vector waterPatrolP2 = vector(240.14, 0.00, 193.52);
const vector waterPatrolP3 = vector(142.47, 0.00, 191.60);
const float waterPatrolEngageRange = 40.0;
const float waterPatrolGatherDistance = 20.0;
const int waterPatrolMaxSize = 5;
*/

/*
// God powers
const float ancestorRange = 50.0;
const int ancestorUnitThreshold = 6;
const float fisherDoomedThreshold = 50.0;
// TC Defense
const float TC1DefendPlanGatherDistance = 10.0;
const float TC1DefendPlanEngageRange = 40.0;
const vector landTC1Position= vector(164.91, 0.00000000, 335.56);

const float TC2DefendPlanGatherDistance = 15.0;
const float TC2DefendPlanEngageRange = 30.0;
const vector landTC2Position= vector(117.58, 0.00, 291.39);
*/

vector gEnemyTCLocation = vector(50.0, 3.0, 261.0);

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

      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstWaterUnit, gMaintainFirstWaterUnitAmount);
      data.addUnitToMaintain(gSecondWaterUnit, gMaintainSecondWaterUnitAmount);
      data.addUnitToMaintain(gThirdWaterUnit, gMaintainThirdWaterUnitAmount);
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(cWaitWithAttacking);  // Don't attack until later into the mission.
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(240.0, 0.0, 12.0);   // Southern point of home island.
      vector targetPoint = vector(24.0, 1.0, 30.0);   // Behind the player's Towncenter on their island.
   
      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID = kbPathCreate("Transport Path");
      kbPathAddWaypoint(pathID, startPoint);
      kbPathAddWaypoint(pathID, vector(170.0, 0.0, 30.0));
      kbPathAddWaypoint(pathID, vector(111.0, 0.0, 30.0));
      kbPathAddWaypoint(pathID, targetPoint);
      kbAttackRouteAddPath(routeID, pathID);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
            debugAttackWave("***Starting Attack***");
         }
      );
      
      // Create tiny defense plans to keep warships in specific locations near the docks.
      // Dreki
      vector gatherPointDreki = vector(240.0, 0.0, 73.0);
      int gatherDrekiID = createDefendPlan("Gather Dreki", -1, 15.0, gatherPointDreki, 10, gatherPointDreki);
      aiPlanSetVariableFloat(gatherDrekiID, cDefendPlanEngageRange, 0, 20.0);
      aiPlanAddUnitType(gatherDrekiID, gSecondWaterUnit, 0, 0, 200);

      // Dragon Ships
      vector gatherPointDragonShips = vector(224.0, 0.0, 29.0);
      int gatherDragonShipsID = createDefendPlan("Gather Dragon Ships", -1, 15.0, gatherPointDragonShips, 10, gatherPointDragonShips);
      aiPlanSetVariableFloat(gatherDragonShipsID, cDefendPlanEngageRange, 0, 20.0);
      aiPlanAddUnitType(gatherDragonShipsID, gFirstWaterUnit, 0, 0, 200);
      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      if (done == false)
      {
         debugAttackWave("Cheating to look at all units on the map, looking for a player dock...");
         kbLookAtAllUnitsOnMap();
         // Do nothing if the player does not have a dock yet.
         if (getUnit(cUnitTypeDock, 1, cUnitStateAlive) >= 0)
         {
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
            aiPlanAddUnitType(gTertiaryDefendPlanID, gFirstWaterUnit, 0, gMaintainFirstWaterUnitAmount * 0.2, gMaintainFirstWaterUnitAmount * 0.3);
            aiPlanAddUnitType(gTertiaryDefendPlanID, gSecondWaterUnit, 0, gMaintainSecondWaterUnitAmount * 0.2, gMaintainFirstWaterUnitAmount * 0.3);

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

            // Set land attack start time.
            gAttackWave.setAttackStartTime(gAttackStartDelay);

            // End
            done = true;
         }
      }
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

   gMainGatherBase = createOverrideGatherBase(vector(283.00, 0.00, 23.00), 64);

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
   
   gAnnoyPlanID = createDefendPlan("Annoy Plan", -1, 20.0, gActiveAnnoyPoint, 10, gActiveAnnoyPoint);
   aiPlanSetVariableFloat(gAnnoyPlanID, cDefendPlanEngageRange, 0, 30.0);
   aiPlanAddUnitType(gAnnoyPlanID, gFirstWaterUnit, 0, 1, 1);
   // Randomize starting position.
   switch(xsRandInt(1, 2))
   {
      case 1:
      {
         gActiveAnnoyPoint = gAnnoyPoint1;
         debugAttackWave("Annoy Point 1 chosen: center of the player's home island!");
         break;
      }
      case 2:
      {
         gActiveAnnoyPoint = gAnnoyPoint2;
         debugAttackWave("Annoy Point 2 chosen: sticking to the eastern fringes of the player's island!");
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