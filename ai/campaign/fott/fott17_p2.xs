//==============================================================================
/* fott17_p2.xs

   Red Egyptian player owning the island in the north. Sends transport attacks of Spearmen, Axemen, and Scarabs.
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

int gFirstLandUnit = cUnitTypeSpearman;
float gMaintainFirstLandUnitAmount = 6;
int gSecondLandUnit = cUnitTypeAnubite;
float gMaintainSecondLandUnitAmount = 5;
int gThirdLandUnit = cUnitTypeChariotArcher;
float gMaintainThirdLandUnitAmount = 8;
int gFourthLandUnit = cUnitTypeScorpionMan;
float gMaintainFourthLandUnitAmount = 5;
int gFifthLandUnit = cUnitTypeSiegeTower;
float gMaintainFifthLandUnitAmount = 1;
int gSixthLandUnit = cUnitTypeCatapult;
float gMaintainSixthLandUnitAmount = 1;
int gSeventhLandUnit = cUnitTypeAxeman;
float gMaintainSeventhLandUnitAmount = 6;

int gFirstWaterUnit = cUnitTypeKebenit; 
float gMaintainFirstWaterUnitAmount = 3;
int gSecondWaterUnit = cUnitTypeWarTurtle;
float gMaintainSecondWaterUnitAmount = 2;
int gThirdWaterUnit = cUnitTypeLeviathan;
float gMaintainThirdWaterUnitAmount = 3;
int gFourthWaterUnit = cUnitTypeWarBarge; 
float gMaintainFourthWaterUnitAmount = 3;

float gMaxVillagerCount = 15;
float gMaxFishingShipCount = 6;

float gAttackStartDelay = 240; // In seconds.
float gAttackWaveInterval = 300; // In Seconds.
float gAttackStartSize = 8;
float gAttackMaxSize = 14;

float gSecondAttackStartDelay = 350; // In seconds.
float gSecondAttackWaveInterval = 300; // In Seconds.

float gNavalAttackStartDelay = 240; // In seconds.
float gNavalAttackWaveInterval = 300; // In Seconds.
float gNavalAttackStartSize = 3;
float gNavalAttackMaxSize = 5;

float gSecondNavalAttackStartDelay = 250; // In seconds.
float gSecondNavalAttackWaveInterval = 300; // In Seconds.

int gLandNorthDefendPlan = -1;
int gLandTC1DefendPlan = -1;
int gLandTC2DefendPlan = -1;

int routeID0 = -1;
int routeID1 = -1;
int routeID2 = -1;
int routeID3 = -1;

int routeID0A = -1;
int routeID1A = -1;
int routeID2A = -1;
int routeID3A = -1;

int pathID1 = -1;
int pathID2 = -1;
int pathID3 = -1;
int pathID4 = -1;

int pathID0A = -1;
int pathID1A = -1;
int pathID2A = -1;
int pathID3A = -1;

// Water patrol
const vector waterPatrolStartPoint = vector(370.70, 0.00, 318.89);
const vector waterPatrolP1 = vector(318.25, 0.00, 255.68);
const vector waterPatrolP2 = vector(240.14, 0.00, 193.52);
const vector waterPatrolP3 = vector(142.47, 0.00, 191.60);
const float waterPatrolEngageRange = 40.0;
const float waterPatrolGatherDistance = 20.0;
const int waterPatrolMaxSize = 5;

// God powers
const float ancestorRange = 50.0;
const int ancestorUnitThreshold = 6;
const float fisherDoomedThreshold = 50.0;

// North Defense
const float NorthDefendPlanGatherDistance = 10.0;
const float NorthDefendPlanEngageRange = 40.0;
const vector landNorthPosition = vector(319.00, 0.00, 329.00);

// TC Defense
const float TC1DefendPlanGatherDistance = 10.0;
const float TC1DefendPlanEngageRange = 40.0;
const vector landTC1Position = vector(164.65, 0.00, 335.79);

const float TC2DefendPlanGatherDistance = 15.0;
const float TC2DefendPlanEngageRange = 30.0;
const vector landTC2Position = vector(117.70, 0.00, 291.05);

vector gEnemyTCLocation = vector(50.0, 3.0, 261.0);
// Need to be on land now
vector getLandAttackStart(int index = -1)
{
   if(index == 0)
   {
      return vector(139.0, 0.0, 343.0);
   }
   return vector(89.0, 0.0, 279.0);
   
}

vector getLandAttackTargetSpot(int index = -1)
{
   if(index == 0)
   {
      return vector(19.00, 0.00, 31.00);
   }
   return vector(295.00, 0.00, 109.00);
}

vector getNavalAttackStart(int index = -1)
{
   if(index == 0)
   {
      return vector(91.0, 0.0, 333.0);
   }
   return vector(319.0, 0.0, 303.0);
   
}

int getLandRouteID(int index = -1)
{
   if(index == 0)
   {
      return routeID0;
   }
   return routeID1;
}

int getLandRouteIDA(int index = -1)
{
   if(index == 0)
   {
      return routeID0A;
   }
   return routeID1A;
}

int getNavalRouteID(int index = -1)
{
   if(index == 0)
   {
      return routeID2;
   }
   return routeID3;
}

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

      // Certain parameters are much more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gMaintainFirstLandUnitAmount = 4; // 4 Spearmen
         gMaintainSecondLandUnitAmount = 2; // 2 Anubites
         gMaintainThirdLandUnitAmount = 3; // 3 Chariot Archers
         gMaintainFourthLandUnitAmount = 2; // 2 Scorpion Men
         gMaintainSeventhLandUnitAmount = 4; // 4 Axemen
         gMaintainThirdWaterUnitAmount = 2; // 2 Leviathans

         gAttackWaveInterval = 600; // In Seconds.
         gSecondAttackWaveInterval = 600; // In Seconds.
         gNavalAttackWaveInterval = 600; // In Seconds.
         gSecondNavalAttackWaveInterval = 600; // In Seconds.
         gAttackStartSize = 3;
         gAttackMaxSize = 5;
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSeventhLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gMaintainFirstWaterUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondWaterUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdWaterUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthWaterUnitAmount *= gDifficultyModifierMaintainUnit;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      gNavalAttackStartDelay *= gDifficultyModifierFirstAttack;
      gNavalAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gNavalAttackStartSize *= gDifficultyModifierAttackSizes;
      gNavalAttackMaxSize *= gDifficultyModifierAttackSizes;

      gSecondNavalAttackStartDelay *= gDifficultyModifierFirstAttack;
      gSecondNavalAttackWaveInterval *= gDifficultyModifierAttackInterval;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);

      data.addUnitToMaintain(gFirstWaterUnit, gMaintainFirstWaterUnitAmount);
      data.addUnitToMaintain(gSecondWaterUnit, gMaintainSecondWaterUnitAmount);
      data.addUnitToMaintain(gThirdWaterUnit, gMaintainThirdWaterUnitAmount);
      data.addUnitToMaintain(gFourthWaterUnit, gMaintainFourthWaterUnitAmount);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(cWaitWithAttacking);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);

      // No Siege Towers until later.

      gSecondAttackWave.setName("gSecondAttackWave");
      gSecondAttackWave.setAttackStartTime(cWaitWithAttacking);
      gSecondAttackWave.setAttackInterval(gSecondAttackWaveInterval);
      gSecondAttackWave.setAttackSize(gAttackStartSize);
      gSecondAttackWave.setMaxAttackSize(gAttackMaxSize);
      gSecondAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gSecondAttackWave.addAttackUnitType(gThirdLandUnit);
      gSecondAttackWave.addAttackUnitType(gFourthLandUnit);
      
      // No Catapults until later.
      gSecondAttackWave.addAttackUnitType(gSeventhLandUnit);

      gNavalAttackWave.setName("gNavalAttackWave");
      gNavalAttackWave.setAttackStartTime(cWaitWithAttacking);
      gNavalAttackWave.setAttackInterval(gNavalAttackWaveInterval);
      gNavalAttackWave.setAttackSize(gNavalAttackStartSize);
      gNavalAttackWave.setMaxAttackSize(gNavalAttackMaxSize);
      gNavalAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gNavalAttackWave.addAttackUnitType(gFirstWaterUnit);
      gNavalAttackWave.setIsNavalAttackWave();
      // gNavalAttackWave.addAttackUnitType(gSecondWaterUnit);

      gSecondNavalAttackWave.setName("gSecondNavalAttackWave");
      gSecondNavalAttackWave.setAttackStartTime(gSecondNavalAttackStartDelay);
      gSecondNavalAttackWave.setAttackInterval(gSecondNavalAttackWaveInterval);
      gSecondNavalAttackWave.setAttackSize(gNavalAttackStartSize);
      gSecondNavalAttackWave.setMaxAttackSize(gNavalAttackMaxSize);
      gSecondNavalAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gSecondNavalAttackWave.addAttackUnitType(gFourthWaterUnit);
      gSecondNavalAttackWave.setIsNavalAttackWave();

      debugAttackWave("Land Attack Time:");
      gAttackWave.displayFirstAttackStats();
      gSecondAttackWave.displayFirstAttackStats();
      debugAttackWave("Naval Attack Time:");
      gNavalAttackWave.displayFirstAttackStats();
      // gSecondNavalAttackWave.displayFirstAttackStats();

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticFishing, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!
      gNavalAttackWave.setPlayerToAttack(1); // Attack player 1!

      gSecondAttackWave.setPlayerToAttack(1); // Attack player 1!
      // gSecondNavalAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint1 = vector(145.0, 0.0, 343.0); // Northern Start Point.
      vector startPoint2 = vector(97.0, 0.0, 257.0); // Southern Start Point.
      vector targetPoint = vector(19.00, 0.00, 31.00);
   
      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.


      // *** Used for the Spearman, Anubite, and Siege Tower Army. *** //
         routeID0 = kbCreateAttackRouteWithPath("Route 1 To P1", startPoint1, targetPoint);
         pathID1 = kbPathCreate("Transport Path 1");
         kbPathAddWaypoint(pathID1, startPoint1);
         kbPathAddWaypoint(pathID1, vector(359.00, 0.00, 365.00));
         kbPathAddWaypoint(pathID1, vector(327.00, 0.00, 289.00));
         kbPathAddWaypoint(pathID1, vector(333.00, 0.00, 205.00));
         kbPathAddWaypoint(pathID1, vector(321.00, 0.00, 147.00));
         kbPathAddWaypoint(pathID1, vector(295.00, 0.00, 109.00));
         kbPathAddWaypoint(pathID1, vector(279.00, 0.00, 95.00));
         // kbPathAddWaypoint(pathID1, vector(371.00, 0.00, 19.00));
         kbPathAddWaypoint(pathID1, vector(245.00, 0.00, 69.00));
         kbPathAddWaypoint(pathID1, vector(19.00, 0.00, 31.00));
         kbPathAddWaypoint(pathID1, targetPoint);
         kbAttackRouteAddPath(routeID0, pathID1);
         
         // targetPoint = vector(273.00, 0.00, 105.00);

         // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
         // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
         // path to it.
         
         pathID2 = kbPathCreate("Transport Path 2");
         kbPathAddWaypoint(pathID2, startPoint1);
         // kbPathAddWaypoint(pathID1, vector(327.00, 0.00, 289.00));
         // kbPathAddWaypoint(pathID2, vector(249.00, 0.0, 217.00));
         kbPathAddWaypoint(pathID2, vector(35.00, 0.0, 315.00));
         kbPathAddWaypoint(pathID2, vector(21.00, 0.0, 125.00));
         kbPathAddWaypoint(pathID2, vector(25.00, 0.0, 23.00));
         kbPathAddWaypoint(pathID2, vector(177.00, 0.0, 129.00));
         kbPathAddWaypoint(pathID2, vector(203.00, 0.0, 149.00));
         kbPathAddWaypoint(pathID2, vector(217.00, 0.00, 149.00));
         kbPathAddWaypoint(pathID2, vector(279.00, 0.00, 95.00));
         // kbPathAddWaypoint(pathID2, vector(371.00, 0.00, 19.00));
         kbPathAddWaypoint(pathID2, vector(245.00, 0.00, 69.00));
         kbPathAddWaypoint(pathID2, vector(19.00, 0.00, 31.00));
         kbPathAddWaypoint(pathID2, targetPoint);
         kbAttackRouteAddPath(routeID0, pathID2);

         // Randomize a matching attack route for both land and naval attack plans.
         int rand = xsRandInt() % 2;

         gAttackWave.setGatherPoint(vector(145.0, 0.0, 343.0));
         gAttackWave.setTargetPoint(targetPoint);
         gAttackWave.setAttackRouteID(routeID0);
         gAttackWave.setWaveStartCallback(
            [](int planID = -1)
            {
               debugAttackWave("***Starting Land Attack***");
            }
         );

      // *** Used for the Chariot Archer, Scorpion Man, and Catapult Army. *** //
         routeID1 = kbCreateAttackRouteWithPath("Route 2 To P1", startPoint2, targetPoint);
         pathID0A = kbPathCreate("Transport Path 1A");
         kbPathAddWaypoint(pathID0A, startPoint2);
         kbPathAddWaypoint(pathID0A, vector(77.00, 0.00, 229.00));
         kbPathAddWaypoint(pathID0A, vector(115.00, 0.00, 197.00));
         kbPathAddWaypoint(pathID0A, vector(195.00, 0.00, 205.00));
         kbPathAddWaypoint(pathID0A, vector(289.00, 0.00, 237.00));
         kbPathAddWaypoint(pathID0A, vector(333.00, 0.00, 205.00));
         kbPathAddWaypoint(pathID0A, vector(321.00, 0.00, 147.00));
         kbPathAddWaypoint(pathID0A, vector(295.00, 0.00, 109.00));
         kbPathAddWaypoint(pathID0A, vector(279.00, 0.00, 95.00));
         kbPathAddWaypoint(pathID0A, vector(371.00, 0.00, 19.00));
         kbPathAddWaypoint(pathID0A, vector(245.00, 0.00, 69.00));
         kbPathAddWaypoint(pathID0A, vector(19.00, 0.00, 31.00));
         kbPathAddWaypoint(pathID0A, targetPoint);
         kbAttackRouteAddPath(routeID1, pathID0A);
         
         // targetPoint = getLandAttackTargetSpot(1);

         // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
         // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
         // path to it.
         pathID1A = kbPathCreate("Transport Path 2A");
         kbPathAddWaypoint(pathID1A, startPoint2);
         kbPathAddWaypoint(pathID1A, vector(77.00, 0.0, 229.00));
         kbPathAddWaypoint(pathID1A, vector(21.00, 0.0, 125.00));
         kbPathAddWaypoint(pathID1A, vector(25.00, 0.0, 23.00));
         kbPathAddWaypoint(pathID1A, vector(177.00, 0.0, 129.00));
         kbPathAddWaypoint(pathID1A, vector(203.00, 0.0, 149.00));
         kbPathAddWaypoint(pathID1A, vector(217.00, 0.00, 149.00));
         kbPathAddWaypoint(pathID1A, vector(279.00, 0.00, 95.00));
         kbPathAddWaypoint(pathID1A, vector(371.00, 0.00, 19.00));
         kbPathAddWaypoint(pathID1A, vector(245.00, 0.00, 69.00));
         kbPathAddWaypoint(pathID1A, vector(19.00, 0.00, 31.00));
         kbPathAddWaypoint(pathID1A, targetPoint);
         kbAttackRouteAddPath(routeID1, pathID1A);

         // Randomize a matching attack route for both land and naval attack plans.
         int randA = xsRandInt() % 2;

         gSecondAttackWave.setGatherPoint(vector(97.0, 0.0, 257.0));
         gSecondAttackWave.setTargetPoint(targetPoint);
         gSecondAttackWave.setAttackRouteID(routeID1);
         gSecondAttackWave.setWaveStartCallback(
            [](int planID = -1)
            {
               debugAttackWave("***Starting Second Land Attack***");
            }
         );

      // *** Used for the Kebenit Naval Waves *** //

         // Where does our attack start and end.
         vector startPoint3 = vector(91.0, 0.0, 333.0);
         vector targetPoint1 = vector(295.0, 0.00, 109.0);

         // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
         // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
         // path to it.
         routeID2 = kbCreateAttackRouteWithPath("Route 1 To P1 Shore", startPoint3, targetPoint1);
         pathID2 = kbPathCreate("Naval Path 1");
         kbPathAddWaypoint(pathID2, startPoint3);
         kbPathAddWaypoint(pathID2, vector(21.0, 0.00, 125.0));
         kbPathAddWaypoint(pathID2, vector(99.0, 0.00, 79.0));
         kbPathAddWaypoint(pathID2, vector(145.0, 0.00, 165.0));
         kbPathAddWaypoint(pathID2, targetPoint1);
         kbAttackRouteAddPath(routeID2, pathID2);
         
         vector startPoint3A = vector(319.0, 0.0, 303.0);
         vector targetPoint2 = vector(142.44, 0.0, 127.10);

         // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
         // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
         // path to it.
         pathID3 = kbPathCreate("Naval Path 2");
         kbPathAddWaypoint(pathID3, startPoint3);
         kbPathAddWaypoint(pathID3, vector(327.31, 0.0, 289.82));
         kbPathAddWaypoint(pathID3, vector(333.0, 0.0, 205.0));
         kbPathAddWaypoint(pathID3, vector(321.0, 0.0, 147.0));
         kbPathAddWaypoint(pathID3, targetPoint1);
         kbAttackRouteAddPath(routeID2, pathID3);

         gNavalAttackWave.setGatherPoint(getNavalAttackStart(rand));
         gNavalAttackWave.setTargetPoint(targetPoint1);
         gNavalAttackWave.setAttackRouteID(getNavalRouteID(rand));
         gNavalAttackWave.setWaveStartCallback(
            [](int planID = -1)
            {
               debugAttackWave("***Starting Naval Attack***");
            }
         );

      // *** Used for the War Barge Naval Waves *** //

         // Where does our attack start and end.
         vector startPoint4 = vector(91.0, 0.0, 333.0);
         targetPoint1 = vector(295.84, 0.00, 109.08);

         // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
         // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
         // path to it.
         routeID2A = kbCreateAttackRouteWithPath("Route 1A To P1 Shore", startPoint2, targetPoint1);
         pathID2A = kbPathCreate("Naval Path 1A");
         kbPathAddWaypoint(pathID2A, startPoint4);
         kbPathAddWaypoint(pathID2A, vector(21.0, 0.00, 125.0));
         kbPathAddWaypoint(pathID2A, vector(99.0, 0.00, 79.0));
         kbPathAddWaypoint(pathID2A, vector(145.0, 0.00, 165.0));
         kbPathAddWaypoint(pathID2A, targetPoint1);
         kbAttackRouteAddPath(routeID2A, pathID2A);
         
         vector startPoint4A = vector(319.0, 0.0, 303.0);

         // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
         // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
         // path to it.
         routeID3A = kbCreateAttackRouteWithPath("Route 2A To P1 Shore", startPoint4A, targetPoint1);
         pathID3A = kbPathCreate("Naval Path 2A");
         kbPathAddWaypoint(pathID3A, startPoint4A);
         kbPathAddWaypoint(pathID3A, vector(327.31, 0.0, 289.82));
         kbPathAddWaypoint(pathID3A, vector(333.0, 0.0, 205.0));
         kbPathAddWaypoint(pathID3A, vector(321.0, 0.0, 147.0));
         kbPathAddWaypoint(pathID3A, targetPoint1);
         kbAttackRouteAddPath(routeID3A, pathID3A);

         gSecondNavalAttackWave.setGatherPoint(getNavalAttackStart(randA));
         gSecondNavalAttackWave.setTargetPoint(targetPoint1);
         gSecondNavalAttackWave.setAttackRouteID(getNavalRouteID(randA));
         gSecondNavalAttackWave.setWaveStartCallback(
            [](int planID = -1)
            {
               debugAttackWave("***Starting Naval Attack***");
            }
         );

      int waterDefendPlan = createDefendPlan("Water Patrol Plan", kbBaseGetMainID(cMyID), waterPatrolGatherDistance, waterPatrolStartPoint, 10);
      aiPlanSetVariableFloat(waterDefendPlan, cDefendPlanEngageRange, 0, waterPatrolEngageRange);
      aiPlanAddUnitType(waterDefendPlan, cUnitTypeKebenit, 0, 0, waterPatrolMaxSize);
      aiPlanAddUnitType(waterDefendPlan, cUnitTypeWarBarge, 0, 0, waterPatrolMaxSize);
      aiPlanSetVariableBool(waterDefendPlan, cDefendPlanPatrol, 0, true);
      aiPlanSetNumberVariableValues(waterDefendPlan, cDefendPlanPatrolWaypoints, 4);
      aiPlanSetVariableVector(waterDefendPlan, cDefendPlanPatrolWaypoints, 0, waterPatrolStartPoint);
      aiPlanSetVariableVector(waterDefendPlan, cDefendPlanPatrolWaypoints, 1, waterPatrolP1);
      aiPlanSetVariableVector(waterDefendPlan, cDefendPlanPatrolWaypoints, 2, waterPatrolP2);
      aiPlanSetVariableVector(waterDefendPlan, cDefendPlanPatrolWaypoints, 3, waterPatrolP3);
      aiPlanSetPriority(waterDefendPlan, 10); // Very low priority, don't steal from attack plans.

      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2;
      int fourthLandUnitSplitAmount = gMaintainFourthLandUnitAmount / 2;
      int sixthLandUnitSplitAmount = gMaintainSixthLandUnitAmount / 2;
      int seventhLandUnitSplitAmount = gMaintainSeventhLandUnitAmount / 2;

      gLandNorthDefendPlan = createDefendPlan("North Land Defend", kbBaseGetMainID(cMyID), NorthDefendPlanGatherDistance, landNorthPosition, 10);
      aiPlanSetVariableFloat(gLandNorthDefendPlan, cDefendPlanEngageRange, 0, NorthDefendPlanEngageRange);
      aiPlanAddUnitType(gLandNorthDefendPlan, gFirstLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gLandNorthDefendPlan, gSecondLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gLandNorthDefendPlan, gFifthLandUnit, 0, 0, 200);

      gLandTC1DefendPlan = createDefendPlan("TC 1 Land Defend", kbBaseGetMainID(cMyID), TC1DefendPlanGatherDistance, landTC1Position, 10);
      aiPlanSetVariableFloat(gLandTC1DefendPlan, cDefendPlanEngageRange, 0, TC1DefendPlanEngageRange);

      aiPlanAddUnitType(gLandTC1DefendPlan, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount);
      aiPlanAddUnitType(gLandTC1DefendPlan, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount);
      aiPlanAddUnitType(gLandTC1DefendPlan, gSixthLandUnit, 0, 0, sixthLandUnitSplitAmount);
      aiPlanAddUnitType(gLandTC1DefendPlan, gSeventhLandUnit, 0, 0, seventhLandUnitSplitAmount);
      
      gLandTC2DefendPlan = createDefendPlan("TC 2 Land Defend", kbBaseGetMainID(cMyID), TC2DefendPlanGatherDistance, landTC2Position, 10);
      aiPlanSetVariableFloat(gLandTC2DefendPlan, cDefendPlanEngageRange, 0, TC2DefendPlanEngageRange);
      aiPlanAddUnitType(gLandTC2DefendPlan, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount);
      aiPlanAddUnitType(gLandTC2DefendPlan, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount);
      aiPlanAddUnitType(gLandTC2DefendPlan, gSixthLandUnit, 0, 0, sixthLandUnitSplitAmount);
      aiPlanAddUnitType(gLandTC2DefendPlan, gSeventhLandUnit, 0, 0, seventhLandUnitSplitAmount);

      int explorePlanID = aiPlanCreate("Kebenit Explore", cPlanExplore, -1);
      aiPlanSetPriority(explorePlanID, 90);
      aiPlanAddUnitType(explorePlanID, cUnitTypeKebenit, 1, 1, 1);
      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool reachedMythic = false;

      int age = kbPlayerGetAge(cMyID);
      int time = xsGetTime();

      static int mythic_time = 1620; // 27 * 60
      // Click up much sooner on Titan.
      if (cDifficultyCurrent == cDifficultyTitan)
      {
         mythic_time = 300;
      }

      if(age == cAge3 && xsGetTime() > mythic_time * gDifficultyModifierAgeUp)
      {
         xsEnableRule("mythic");
      }

      // Only start making siege weapons after 15 minutes.
      static bool add_siege = false;
      if (time >= 900 && add_siege == false)
      {
         // Don't make Siege Towers on Easy.
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
            gAttackWave.addAttackUnitType(gFifthLandUnit);

            // Only make Catapults on Hard and Titan.
            if (cDifficultyCurrent >= cDifficultyHard)
            {
               data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
               gSecondAttackWave.addAttackUnitType(gSixthLandUnit);
            }
         }
         add_siege = true;
      }

      // Start dispatching War Barges after 10 minutes.
      static bool war_barges = false;

      // Only do this on Moderate and up.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         if (time >= 600 && war_barges == false)
         {
            gNavalAttackWave.addAttackUnitType(gFourthWaterUnit);
            gNavalAttackMaxSize *= 1.20; // Attack size increases by +20%
            gNavalAttackWave.setMaxAttackSize(gAttackMaxSize);
            war_barges = true;
         }
      }


      // * * * TECH RULES * * * //

      // HEROIC AGE //

         static bool heroic_techs = false;
         if (heroic_techs == false)
         {
            // Tech Rules for Easy Only:
            if (cDifficultyCurrent == cDifficultyEasy)
            {
               xsEnableRule("researchBronzeWeapons");
               xsEnableRule("researchHeavySpearmen");
            }

            // Tech Rules for Moderate and Hard:
            if (cDifficultyCurrent >= 1 && cDifficultyCurrent != cDifficultyTitan)
            {
               xsEnableRule("researchBronzeArmor");
               xsEnableRule("researchBronzeShields");
               xsEnableRule("researchHeavyChariotArchers");
               xsEnableRule("researchGuardTower");
               xsEnableRule("researchBoilingOil");
               xsEnableRule("researchFortifiedTownCenter");
            }

            // Tech Rules for Hard and Titan:
            if (cDifficultyCurrent >= cDifficultyHard)
            {
               xsEnableRule("researchHeavyWarships");
               xsEnableRule("researchArchitects");
            }
            // Tech Rules for Titan only:
            heroic_techs = true;
         }



      // MYTHIC AGE //
      if (reachedMythic == false && kbPlayerGetAge(cMyID) == cAge4)
      {
         // Tech Rules for All Difficulties:
         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchChampionAxemen");
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchFloodControl");
            xsEnableRule("researchQuarry");
            xsEnableRule("researchCarpenters");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchIronArmor");
            xsEnableRule("researchChampionSpearmen");
            xsEnableRule("researchChampionChariotArchers");
            xsEnableRule("researchBallistaTower");
         }
         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchIronShields");
            xsEnableRule("researchChampionWarships");
         }
         // Change the boolean back to true so the rules aren't enabled multiple times.
         reachedMythic = true;
      }

      gAttackWave.update();
      gSecondAttackWave.update();
      gNavalAttackWave.update();
      return cStrategyContinue;
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott17StrategySetup()
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
   gMaxFishingShipCount *= gDifficultyModifierMaintainFishing;
   gOverrideMaxVillagerPop = gMaxVillagerCount;
   // gOverrideMaxFishingShipPop = gMaxFishingShipCount;

   gMainGatherBase = createOverrideGatherBase(vector(176.00, 0.00, 336.00), 35);
   createOverrideGatherBase(vector(209.00, 0.00, 313.00), 35);
   createOverrideGatherBase(vector(123.00, 0.00, 314.00), 35);
   createOverrideGatherBase(vector(65.00, 0.00, 271.00), 35);

   gOverrideClosestFishLocation = vector(119.74, 0.00, 364.00);
   gMaxFishDockScanRange = 560;

   setOverrideStrategy(fott17StrategySetup);

   gRBDSystem.setMaxFarmsPerBase(32);
   gRBDSystem.setMaxFarmsPerIteration(32);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}


rule heroic
   inactive
   minInterval 5
{
   researchSimpleTech(cTechHeroicAgeNephthys, cUnitTypeTownCenter, -1, 75);
   int age = kbPlayerGetAge(cMyID);
   if (age >= cAge3)
   {
      xsDisableRule("heroic"); // Disables once age up is successful.
   }
}
rule mythic
   inactive
   minInterval 5
{
   researchSimpleTech(cTechMythicAgeHorus, cUnitTypeTownCenter, -1, 75);
   int age = kbPlayerGetAge(cMyID);
   if (age >= cAge4)
   {
      xsDisableRule("mythic");  // Disables once age up is successful.
   }
}

rule ancestors
active
minInterval 5
{
   int queryID = useSimpleUnitQuery(cUnitTypeCinematicBlockArea);
   int numAreaMarkers = kbUnitQueryExecute(queryID);
   if(numAreaMarkers == 0)
   {
      debugAttackWave("Small problem for our tornado logic if we don't have area blocks");
      xsDisableRule("ancestors");
   }
   int[] areaUnits = kbUnitQueryGetResults(queryID); 

   // Is player 1 sneaky
   const int playerID = 1;
   for(int i = 0; i < numAreaMarkers; i++)
   {
      // Is it close to our area?
      int areaID = areaUnits[i];
      vector loc = kbUnitGetPosition(areaID);
      queryID = useSimpleUnitQuery(cUnitTypeNavalUnit, playerID,cUnitStateAlive,loc,ancestorRange);
      if(kbUnitQueryExecute(queryID) >= ancestorUnitThreshold)
      {
         aiCastGodPowerAtUnit(cProtoPowerAncestors,kbUnitQueryGetResult(queryID, 0));
         xsDisableRule("ancestors");
         return;
      }
   }
}

rule tornado
active
minInterval 2
{
   int scoutPlanID = aiPlanGetIDByTypeIndex(cPlanExplore, 0);
   if(scoutPlanID == -1)
   {
      return;
   }
   int scoutUnitID = aiPlanGetUnitIDByIndex(scoutPlanID, 0);
   // Nice player outplayed our logic
   if(scoutUnitID == -1)
   {
      return;
   }
   const int playerID = 1;
   int queryID = useSimpleUnitQuery(cUnitTypeAbstractFishingShip, playerID);
   int numFishers = kbUnitQueryExecute(queryID);
   if(numFishers == 0)
   {
      // No fishers for the storm
      return;
   }
   debugAttackWave("Fisher found");
   int[] fishers = kbUnitQueryGetResults(queryID);
   
   // Cheat to see our player waypoints
   xsSetContextPlayer(playerID);
   int otherPlayerQueryID = kbUnitQueryCreate("otherPlayerQuery"); 
   // Define a query to get all matching units
   if (otherPlayerQueryID == -1)
   {
      return;
   }
   kbUnitQuerySetPlayerID(otherPlayerQueryID, playerID);
   kbUnitQuerySetUnitType(otherPlayerQueryID, cUnitTypeCinematicBlockSpawnPoint);
   kbUnitQueryResetResults(otherPlayerQueryID);
   int numAreaMarkers = kbUnitQueryExecute(otherPlayerQueryID);
   if(numAreaMarkers == 0)
   {
      debugAttackWave("Small problem for our tornado logic if we don't have spawn points");
      xsDisableRule("tornado");
   }
   int[] avoidAreaUnits = kbUnitQueryGetResults(otherPlayerQueryID);
   // And restore it
   xsSetContextPlayer(cMyID);

   for(int fisherI = 0; fisherI < numFishers; fisherI++)
   {
      int fisherID = fishers[fisherI];
      vector fisherPos = kbUnitGetPosition(fisherID);
      for(int avoidI = 0; avoidI < numAreaMarkers; avoidI++)
      {
         vector areaPos = kbUnitGetPosition(avoidAreaUnits[avoidI]);
         if(xsVectorLength(areaPos-fisherPos) <= fisherDoomedThreshold)
         {
            fisherID = -1;
            break;
         }
      }
      if(fisherID == -1)
      {
         continue;
      }
      // Unlucky fisher
      debugAttackWave("Fisher obliterated");
      aiCastGodPowerAtUnit(cProtoPowerTornado,fisherID);
      xsDisableRule("tornado");
      break;
   }
}

// *** HEROIC AGE UPGRADES *** //
   // EASY ONLY
      // Bronze Weapons
         rule researchBronzeWeapons
         inactive
         minInterval 860
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechBronzeWeapons) == cTechStatusActive)
            {
               xsDisableRule("researchBronzeWeapons");
               return;
            }
            else if (kbTechGetStatus(cTechBronzeWeapons) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Bronze Weapons research plan.");
               researchSimpleTech(cTechBronzeWeapons, cUnitTypeArmory, -1, 60);
               return;
            }
         }
      // Heavy Spearmen
         rule researchHeavySpearmen
         active
         minInterval 360
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechHeavySpearmen) == cTechStatusActive)
            {
               xsDisableRule("researchHeavySpearmen");
               return;
            }
            else if (kbTechGetStatus(cTechHeavySpearmen) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Heavy Spearmen research plan.");
               researchSimpleTech(cTechHeavySpearmen, cUnitTypeBarracks, -1, 60);
               return;
            }
         }

   // MODERATE AND HARD
      // Bronze Armor
         rule researchBronzeArmor
         inactive
         minInterval 620
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechBronzeArmor) == cTechStatusActive)
            {
               xsDisableRule("researchBronzeArmor");
               return;
            }
            else if (kbTechGetStatus(cTechBronzeArmor) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Bronze Armor research plan.");
               researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 60);
               return;
            }
         }
      // Bronze Shields
         rule researchBronzeShields
         inactive
         minInterval 500
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechBronzeShields) == cTechStatusActive)
            {
               xsDisableRule("researchBronzeShields");
               return;
            }
            else if (kbTechGetStatus(cTechBronzeShields) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Bronze Shields research plan.");
               researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 60);
               return;
            }
         }
      // Heavy Chariot Archers
         rule researchHeavyChariotArchers
         active
         minInterval 640
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechHeavyChariotArchers) == cTechStatusActive)
            {
               xsDisableRule("researchHeavyChariotArchers");
               return;
            }
            else if (kbTechGetStatus(cTechHeavyChariotArchers) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Heavy Chariot Archers research plan.");
               researchSimpleTech(cTechHeavyChariotArchers, cUnitTypeMigdolStronghold, -1, 60);
               return;
            }
         }
      // Guard Tower
         rule researchGuardTower
         inactive
         minInterval 750
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechGuardTower) == cTechStatusActive)
            {
               xsDisableRule("researchGuardTower");
               return;
            }
            else if (kbTechGetStatus(cTechGuardTower) == cTechStatusObtainable)
            {
               debugAttackWave("Starting GuardTower research plan.");
               researchSimpleTech(cTechGuardTower, cUnitTypeSentryTower, -1, 60);
               return;
            }
         }
      // Boiling Oil
         rule researchBoilingOil
         inactive
         minInterval 840
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechBoilingOil) == cTechStatusActive)
            {
               xsDisableRule("researchBoilingOil");
               return;
            }
            else if (kbTechGetStatus(cTechBoilingOil) == cTechStatusObtainable)
            {
               debugAttackWave("Starting BoilingOil research plan.");
               researchSimpleTech(cTechBoilingOil, cUnitTypeSentryTower, -1, 60);
               return;
            }
         }
      // Fortified Town Center
         rule researchFortifiedTownCenter
         inactive
         minInterval 980
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechFortifiedTownCenter) == cTechStatusActive)
            {
               xsDisableRule("researchFortifiedTownCenter");
               return;
            }
            else if (kbTechGetStatus(cTechFortifiedTownCenter) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Fortified TownCenter research plan.");
               researchSimpleTech(cTechFortifiedTownCenter, cUnitTypeTownCenter, -1, 60);
               return;
            }
         }

   // HARD AND UP
      // Architects
         rule researchArchitects
         inactive
         minInterval 180
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechArchitects) == cTechStatusActive)
            {
               xsDisableRule("researchArchitects");
               return;
            }
            else if (kbTechGetStatus(cTechArchitects) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Architects research plan.");
               researchSimpleTech(cTechArchitects, cUnitTypeTownCenter, -1, 60);
               return;
            }
         }
      // Heavy Warships
         rule researchHeavyWarships
         inactive
         minInterval 180
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechHeavyWarships) == cTechStatusActive)
            {
               xsDisableRule("researchHeavyWarships");
               return;
            }
            else if (kbTechGetStatus(cTechHeavyWarships) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Heavy Warships research plan.");
               researchSimpleTech(cTechHeavyWarships, cUnitTypeDock, -1, 60);
               return;
            }
         }

// *** MYTHIC AGE UPGRADES *** //
   // MODERATE AND UP
         // Quarry
            rule researchQuarry
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechQuarry) == cTechStatusActive)
               {
                  xsDisableRule("researchQuarry");
                  return;
               }
               else if (kbTechGetStatus(cTechQuarry) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Quarry research plan.");
                  researchSimpleTech(cTechQuarry, cUnitTypeMiningCamp, -1, 60);
                  return;
               }
            }
         // Flood Control
            rule researchFloodControl
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechFloodControl) == cTechStatusActive)
               {
                  xsDisableRule("researchFloodControl");
                  return;
               }
               else if (kbTechGetStatus(cTechFloodControl) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Flood Control research plan.");
                  researchSimpleTech(cTechFloodControl, cUnitTypeGranary, -1, 60);
                  return;
               }
            }
         // Carpenters
            rule researchCarpenters
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
            {
               researchSimpleTech(cTechCarpenters, cUnitTypeLumberCamp, -1, 60);
               xsDisableRule("researchCarpenters"); // Disable self.
            }
         // Champion Axemen
            rule researchChampionAxemen
            active
            minInterval 140
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionAxemen) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionAxemen");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionAxemen) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Axemen research plan.");
                  researchSimpleTech(cTechChampionAxemen, cUnitTypeBarracks, -1, 60);
                  return;
               }
            }
         // Iron Weapons
            rule researchIronWeapons
            inactive
            minInterval 180
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechIronWeapons) == cTechStatusActive)
               {
                  xsDisableRule("researchIronWeapons");
                  return;
               }
               else if (kbTechGetStatus(cTechIronWeapons) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Iron Weapons research plan.");
                  researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 60);
                  return;
               }
            }
   // HARD AND UP
            rule researchChampionSpearmen
            active
            minInterval 60
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionSpearmen) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionSpearmen");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionSpearmen) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Spearmen research plan.");
                  researchSimpleTech(cTechChampionSpearmen, cUnitTypeBarracks, -1, 60);
                  return;
               }
            }
            rule researchChampionChariotArchers
            active
            minInterval 150
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionChariotArchers) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionChariotArchers");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionChariotArchers) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Chariot Archers research plan.");
                  researchSimpleTech(cTechChampionChariotArchers, cUnitTypeMigdolStronghold, -1, 60);
                  return;
               }
            }
            rule researchBallistaTower
            inactive
            minInterval 60
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechBallistaTower) == cTechStatusActive)
               {
                  xsDisableRule("researchBallistaTower");
                  return;
               }
               else if (kbTechGetStatus(cTechBallistaTower) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Ballista Tower research plan.");
                  researchSimpleTech(cTechBallistaTower, cUnitTypeSentryTower, -1, 60);
                  return;
               }
            }
         // Iron Armor
            rule researchIronArmor
            inactive
            minInterval 120
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechIronArmor) == cTechStatusActive)
               {
                  xsDisableRule("researchIronArmor");
                  return;
               }
               else if (kbTechGetStatus(cTechIronArmor) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Iron Armor research plan.");
                  researchSimpleTech(cTechIronArmor, cUnitTypeArmory, -1, 60);
                  return;
               }
            }
   // TITAN ONLY
            // Iron Shields
            rule researchIronShields
            inactive
            minInterval 90
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechIronShields) == cTechStatusActive)
               {
                  xsDisableRule("researchIronShields");
                  return;
               }
               else if (kbTechGetStatus(cTechIronShields) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Iron Shields research plan.");
                  researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
                  return;
               }
            }

            // Champion Warships
            rule researchChampionWarships
            inactive
            minInterval 1080
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionWarships) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionWarships");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionWarships) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Warships research plan.");
                  researchSimpleTech(cTechChampionWarships, cUnitTypeDock, -1, 60);
                  return;
               }
            }


// Called from the triggers to enable attacks. Occurs when Amanra reaches the Town Center.
void updateParameters()
{
   // Define first attack.
   gAttackWave.setAttackStartTime(gAttackStartDelay);
   gSecondAttackWave.setAttackStartTime(gSecondAttackStartDelay);
   gNavalAttackWave.setAttackStartTime(gNavalAttackStartDelay);
   return;
}

// Move defend plans (when nearby production is destroyed)
   void updateNorthPlan()
   {
      // Lost our nearby production. Move TC dfend point to the plateau.
      aiPlanSetVariableVector(gLandNorthDefendPlan, cDefendPlanTargetPoint, 0, vector(239.0, 0.0, 279.0));
      aiPlanSetVariableVector(gLandNorthDefendPlan, cDefendPlanGatherPoint, 0, vector(239.0, 0.0, 279.0));
      debugAttackWave("Moved our defend plan to the plateau.");
   }

   void updateTCPlan1()
   {
      // Lost our nearby production. Move TC dfend point to the plateau.
      aiPlanSetVariableVector(gLandTC1DefendPlan, cDefendPlanTargetPoint, 0, vector(167.0, 0.0, 285.0));
      aiPlanSetVariableVector(gLandTC1DefendPlan, cDefendPlanGatherPoint, 0, vector(167.0, 0.0, 285.0));
      debugAttackWave("Moved our defend plan to the plateau.");
   }

   void updateTCPlan2()
   {
      // Lost our nearby production. Move TC dfend point to the plateau.
      aiPlanSetVariableVector(gLandTC2DefendPlan, cDefendPlanTargetPoint, 0, vector(211.0, 0.0, 289.0));
      aiPlanSetVariableVector(gLandTC2DefendPlan, cDefendPlanGatherPoint, 0, vector(211.0, 0.0, 289.0));
      debugAttackWave("Moved our defend plan to the plateau.");
   }