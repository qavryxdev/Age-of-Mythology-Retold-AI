//==============================================================================
/* fott32_p2.xs

   Gargarensis (Poseidon)

   Red Greek player owning the base on the northern acropolis. Trains Greek infantry and archers,
   as well as two Heroes (Atalanta & Polyphemus).

   They won't attack until they lose one of their Fortresses. At this point, they also start maintaining
   myth units and siege.
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

float gTrainDelay = 10; // In seconds. (Set to 1 on Titan)
int gFirstLandUnit = cUnitTypeHoplite; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 12;
int gSecondLandUnit = cUnitTypeHypaspist; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 8;
int gThirdLandUnit = cUnitTypeToxotes; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 12;
int gFourthLandUnit = cUnitTypePeltast; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 6;
int gFifthLandUnit = cUnitTypeHetairos; // Not trained from the start.
float gMaintainFifthLandUnitAmount = 8;
int gSixthLandUnit = cUnitTypeChimera; // Not trained from the start.
float gMaintainSixthLandUnitAmount = 3;
int gSeventhLandUnit = cUnitTypeHelepolis; // Not trained from the start.
float gMaintainSeventhLandUnitAmount = 1;
int gEighthLandUnit = cUnitTypeAtalanta; // Gets trained from the start.
float gMaintainEighthLandUnitAmount = 1;   // Not affected by modifier.
int gNinthLandUnit = cUnitTypePolyphemus; // Gets trained from the start. Not affected by modifier.
float gMaintainNinthLandUnitAmount = 1;   // Not affected by modifier.
float gMaxVillagerCount = 16;
float gAttackStartDelayLong = cWaitWithAttacking; // In seconds, used before the activation of attacks (by losing a Fortress).
float gAttackStartDelay = 180; // In seconds, used after the activation of attacks (by losing a Fortress).
float gAttackWaveInterval = 180; // In Seconds.
float gAttackStartSize = 12;
float gAttackMaxSize = 25;

bool gAllyDown = false;

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

      // Certain parameters are way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gMaintainFirstLandUnitAmount = 3; // Hoplites
         gMaintainSecondLandUnitAmount = 2; // Hypaspists
         gMaintainThirdLandUnitAmount = 3; // Toxotai
         gMaintainFourthLandUnitAmount = 2; // Peltasts
         gMaintainFifthLandUnitAmount = 2; // Hetairoi
         gMaintainSixthLandUnitAmount = 1; // Chimerai

         gAttackWaveInterval = 600; // In Seconds.
         gAttackStartSize = 4;
         gAttackMaxSize = 6;
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSeventhLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      // Additional Feature: "Train frequency is faster on Titan specifically"
      if (cDifficultyCurrent >= cDifficultyTitan)
      {
         gTrainDelay = 1;  // As fast as possible.
      }
      else
      {
         gTrainDelay *= gDifficultyModifierTrainDelay;   // 10s on Easy, 7.5s on Moderate, 5s on Hard
      }

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      data.addUnitToMaintain(gEighthLandUnit, gMaintainEighthLandUnitAmount);
      data.addUnitToMaintain(gNinthLandUnit, gMaintainNinthLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);
      data.setTrainDelay(gFifthLandUnit, gTrainDelay);
      data.setTrainDelay(gEighthLandUnit, gTrainDelay);
      data.setTrainDelay(gNinthLandUnit, gTrainDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelayLong);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);  // Hoplites
      gAttackWave.addAttackUnitType(gSecondLandUnit); // Hypaspists
      gAttackWave.addAttackUnitType(gThirdLandUnit);  // Toxotai
      gAttackWave.addAttackUnitType(gFourthLandUnit); // Peltasts
      gAttackWave.addAttackUnitType(gFifthLandUnit); // Hetairoi
      gAttackWave.addAttackUnitType(gEighthLandUnit); // Hero Atalanta
      gAttackWave.addAttackUnitType(gNinthLandUnit);  // Hero Polyphemus

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticMainBaseTCRebuild, true);
      data.setFlag(cStrategyFlagAutoResearchMilitaryUpgrades, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(252.0, 1.0, 283.0); // In front of the acropolis pit.
      vector targetPoint = vector(46.0, 1.0, 232.0); // Player's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 Egyptians");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(224.0, 1.0, 245.0));
      kbPathAddWaypoint(pathID1, vector(180.0, 1.0, 251.0));
      kbPathAddWaypoint(pathID1, vector(129.0, 1.0, 197.0));
      kbPathAddWaypoint(pathID1, vector(107.0, 1.0, 168.0));
      kbPathAddWaypoint(pathID1, vector(36.0, 1.0, 167.0));
      kbPathAddWaypoint(pathID1, vector(27.0, 1.0, 27.0));
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
            static int counter = 0;
            if (counter == 0)
            {
               xsEnableRule("expandAttackRoutes");
               counter++; // Only do this for the first attack.
            }
         }
      );


      // Initialize 3 defend plans:
      // Splitting our Hypaspists and Peltasts into two groups, to be used in two defend plans.
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 2;
      int fourthLandUnitSplitAmount = gMaintainFourthLandUnitAmount / 2;

      // First one for Hypaspists and Peltasts to defend the upper acropolis entrance.
      vector defendPoint = vector(261.0, 1.0, 309.0); // A bit behind the two fortresses guarding the upper entrance (by the corner of the Atlantis Tile).
      int landDefendPlan1 = createDefendPlan("First Land Defense", kbBaseGetMainID(cMyID), 25.0, defendPoint, 40);
      aiPlanSetVariableFloat(landDefendPlan1, cDefendPlanEngageRange, 0, 20.0);
      aiPlanAddUnitType(landDefendPlan1, gFirstLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan1, gSecondLandUnit, 0, secondLandUnitSplitAmount, secondLandUnitSplitAmount);
      aiPlanAddUnitType(landDefendPlan1, gFourthLandUnit, 0, fourthLandUnitSplitAmount, fourthLandUnitSplitAmount);
      aiPlanAddUnitType(landDefendPlan1, gFifthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan1, gEighthLandUnit, 0, 0, 200);

      // Second one for Hypaspists and Peltasts to defend the lower acropolis entrance.
      defendPoint = vector(266.0, 1.0, 243.0); // Near the acropolis TC.
      int landDefendPlan2 = createDefendPlan("Second Land Defense", kbBaseGetMainID(cMyID), 25.0, defendPoint, 40);
      aiPlanSetVariableFloat(landDefendPlan2, cDefendPlanEngageRange, 0, 20.0);
      aiPlanAddUnitType(landDefendPlan2, gSecondLandUnit, 0, secondLandUnitSplitAmount, secondLandUnitSplitAmount);
      aiPlanAddUnitType(landDefendPlan2, gThirdLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan2, gFourthLandUnit, 0, fourthLandUnitSplitAmount, fourthLandUnitSplitAmount);
      aiPlanAddUnitType(landDefendPlan2, gSixthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan2, gSeventhLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan2, gNinthLandUnit, 0, 0, 200);

      // Third one for the Living Poseidon Statue guarding the Atlantis Tile.
      defendPoint = vector(259.0, 1.0, 279.0); // Between the two Fortresses by the lower entrance.
      int landDefendPlan3 = createDefendPlan("Third Land Defense", kbBaseGetMainID(cMyID), 20.0, defendPoint, 40);
      aiPlanSetVariableFloat(landDefendPlan3, cDefendPlanEngageRange, 0, 25.0);
      aiPlanAddUnitType(landDefendPlan3, cUnitTypeLivingPoseidonStatue, 0, 1, 1);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;

      // Get our starting amount of Fortresses.
      static int fortCountAtStart = 0;
      if (fortCountAtStart == 0)
      {
         fortCountAtStart = kbUnitCount(cUnitTypeFortress, cMyID, cUnitStateAlive);
      }

      if (done == false)
      {
         // Check if we have lost a Fortress.
         int fortCountNow = kbUnitCount(cUnitTypeFortress, cMyID, cUnitStateAlive);
         //debugAttackWave("FORTRESSES: " + fortCountNow + "/" + fortCountAtStart);

         // If we have...
         if (fortCountNow < fortCountAtStart)
         {
            done = true;
            debugAttackWave("WE LOST A FORTRESS?? That's the last straw, time to attack back!");

            // Train new units (6th, 7th types) and use them in attacks.
            data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
            data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);

            int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gSixthLandUnit);
            aiPlanSetVariableInt(
               planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gSixthLandUnit, cProtoStatTrainPoints) + gTrainDelay
            );
            planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gSeventhLandUnit);
            aiPlanSetVariableInt(
               planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gSeventhLandUnit, cProtoStatTrainPoints) + gTrainDelay
            );

            gAttackWave.addAttackUnitType(gSixthLandUnit);  // Chimerai
            gAttackWave.addAttackUnitType(gSeventhLandUnit);   // Helepolis

            // Try newAttackStartDelay if just setting the normal delay doesn't work.
            //float newAttackStartDelay = xsGetTime() + gAttackStartDelay;
            gAttackWave.setAttackStartTime(gAttackStartDelay);

            // 
            xsEnableRule("buildTowers");
         }
         // We'll also start attacking if one of our allies went down.
         if (gAllyDown == true)
         {
            done = true;
            debugAttackWave("Arkantos is gaining on us! Time to attack back!");

            // Train new units (6th, 7th types) and use them in attacks.
            data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
            data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);

            int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gSixthLandUnit);
            aiPlanSetVariableInt(
               planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gSixthLandUnit, cProtoStatTrainPoints) + gTrainDelay
            );
            planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gSeventhLandUnit);
            aiPlanSetVariableInt(
               planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gSeventhLandUnit, cProtoStatTrainPoints) + gTrainDelay
            );

            gAttackWave.addAttackUnitType(gSixthLandUnit);  // Colossi
            gAttackWave.addAttackUnitType(gSeventhLandUnit);   // Helepolis

            // Try newAttackStartDelay if just setting the normal delay doesn't work.
            //float newAttackStartDelay = xsGetTime() + gAttackStartDelay;
            gAttackWave.setAttackStartTime(gAttackStartDelay);

            // 
            xsEnableRule("buildTowers");
         }

      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott32StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(283.00, 0.00, 231.00), 35);
   createOverrideGatherBase(vector(326.00, 0.00, 280.00), 70);
   createOverrideGatherBase(vector(307.00, 0.00, 377.00), 35);
   createOverrideGatherBase(vector(275.00, 0.00, 363.00), 10);
   gTimeToFarm = true;

   setOverrideStrategy(fott32StrategySetup);

   gOverrideFarmCount = 12; // We can't have too many farms due to space restrictions.
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, vector(283.0, 0.0, 231.0), 15.0); // Our TC.
      kbBuildingPlacementAddPositionInfluence(bpID, vector(283.0, 0.0, 231.0), 100.0, 15.0, cFalloffLinear); // Our TC.
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementSetStepSize(bpID, 0.5);
      aiPlanSetVariableBool(planID, cBuildPlanDoneWhenFoundationPlaced, 0, true);
      return (true);
   };
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// *** RULE - buildTowers ***
// After having lost a Fortress, we build some towers on the western path.
rule buildTowers
inactive
minInterval 60
{
   vector buildPosition = vector(219.0, 10.00, 315.0); // Between the two future buildPoints.
   int myTowers = getUnitCountByLocation(cUnitTypeSentryTower, cMyID, cUnitStateABQ, buildPosition, 25.0);
   int numPlayerUnits = getUnitCountByLocation(cUnitTypeUnit, 1, cUnitStateAlive, buildPosition, 25.0);
   int numPlayerBuildings = getUnitCountByLocation(cUnitTypeBuilding, 1, cUnitStateAlive, buildPosition, 25.0);
   int numPlayerTotal = numPlayerUnits + numPlayerBuildings;
   int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeSentryTower);
   if (planID <= 0 && myTowers <= 0 && numPlayerTotal < 2)
   {
      debugAttackWave("The coast is clear to build some towers by my upper entrance.");

      // First tower, left.
      buildPosition = vector(219.0, 10.00, 322.0); // Leftmost cinematic block by the western entrance, on the edge of the cliff.
      int buildPlanID = aiPlanCreate("Tower 1 Build Plan", cPlanBuild, -1);
      int bpID = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID));
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeSentryTower);
      kbBuildingPlacementSetCenterPosition(bpID, buildPosition, 10.0);
      kbBuildingPlacementSetStepSize(bpID, 1.0);
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementAddPositionInfluence(bpID, buildPosition, 100.0, 50.0, cFalloffLinear);
      aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, cUnitTypeSentryTower);
      aiPlanAddUnitType(buildPlanID, cUnitTypeVillagerGreek, 1, 1, 1);
      aiPlanSetPriority(buildPlanID, 99);

      // Second tower, right.
      buildPosition = vector(220.0, 11.00, 308.0); // Rightmost cinematic block by the western entrance, on the edge of the cliff.
      int buildPlanID2 = aiPlanCreate("Tower 2 Build Plan", cPlanBuild, -1);
      int bpID2 = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID2));
      kbBuildingPlacementSetBuildingPUID(bpID2, cUnitTypeSentryTower);
      kbBuildingPlacementSetCenterPosition(bpID2, buildPosition, 10.0);
      kbBuildingPlacementSetStepSize(bpID2, 1.0);
      kbBuildingPlacementSetBufferSpace(bpID2, 0.0);
      kbBuildingPlacementAddPositionInfluence(bpID2, buildPosition, 100.0, 50.0, cFalloffLinear);
      aiPlanSetVariableInt(buildPlanID2, cBuildPlanBuildingPlacementID, 0, bpID2);
      aiPlanSetVariableInt(buildPlanID2, cBuildPlanBuildingTypeID, 0, cUnitTypeSentryTower);
      aiPlanAddUnitType(buildPlanID2, cUnitTypeVillagerGreek, 1, 1, 1);
      aiPlanSetPriority(buildPlanID2, 99);
   }
}

// *** RULE - expandAttackRoutes ***
// 30 seconds after the first attack goes out we expand our possible routes.
rule expandAttackRoutes
inactive
minInterval 30
{
   int routeID = gAttackWave.mAttackRouteID;

   vector startPoint = vector(252.0, 1.0, 283.0); // In front of the acropolis pit.
   vector targetPoint = vector(46.0, 1.0, 232.0); // Player's TC.

   int pathID2 = kbPathCreate("Path 2 Norse");
   kbPathAddWaypoint(pathID2, startPoint);
   kbPathAddWaypoint(pathID2, vector(242.0, 1.0, 310.0));
   kbPathAddWaypoint(pathID2, vector(214.0, 1.0, 314.0));
   kbPathAddWaypoint(pathID2, vector(175.0, 1.0, 279.0));
   kbPathAddWaypoint(pathID2, vector(78.0, 1.0, 364.0));
   kbPathAddWaypoint(pathID2, vector(45.0, 1.0, 340.0));
   kbPathAddWaypoint(pathID2, vector(89.0, 1.0, 259.0));
   kbPathAddWaypoint(pathID2, vector(48.0, 1.0, 242.0));
   kbPathAddWaypoint(pathID2, targetPoint);
   kbAttackRouteAddPath(routeID, pathID2);

   debugAttackWave("Unlocked the attack route going through the Norse base.");
   xsDisableRule("expandAttackRoutes");
}

void AllyDied()
{
   gAllyDown = true;
   debugAttackWave("Arkantos took down one of our allies! This cannot stand!");
}