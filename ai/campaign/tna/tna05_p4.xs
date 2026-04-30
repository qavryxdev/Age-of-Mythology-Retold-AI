//==============================================================================
/* tna05_p4.xs

   Yellow Egyptian player that owns a large, well-defended base and booms up to
   a very large army comprised of several different unit types.
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
float gWadjetDelay = 30; // In seconds.
float gChariotDelay = 20; // In seconds.
float gScarabDelay = 50; // In seconds.
float gMummyDelay = 60; // In seconds.

int gFirstLandUnit = cUnitTypeSpearman; // Begins training once they reach the Classical Age.
float gMaintainFirstLandUnitAmount = 4;
int gSecondLandUnit = cUnitTypeAxeman; // Begins training once they reach the Classical Age.
float gMaintainSecondLandUnitAmount = 3;
int gThirdLandUnit = cUnitTypeWadjet; // Begins training once they reach the Classical Age.
float gMaintainThirdLandUnitAmount = 2;
int gFourthLandUnit = cUnitTypeChariotArcher; // Begins training once they reach the Heroic Age.
float gMaintainFourthLandUnitAmount = 4;
int gFifthLandUnit = cUnitTypeScarab; // Begins training once they reach the Heroic Age.
float gMaintainFifthLandUnitAmount = 2;
int gSixthLandUnit = cUnitTypeMummy; // Begins training once they reach the Mythic Age.
float gMaintainSixthLandUnitAmount = 2;

float gMaxVillagerCount = 10;
float gAttackStartDelay = 1080; // 18 Minutes.
float gAttackWaveInterval = 1080; // In seconds.
float gAttackStartSize = 8;
float gAttackMaxSize = 10;

float gClassicalAgeUpTime = 600; // In seconds. (10 minutes)
float gHeroicAgeUpTime = 1260; // In seconds. (21 minutes)
float gMythicAgeUpTime = 2100; // In seconds. (35 minutes)
int gLandDefendPlan = -1;
int gLandDefendPlan2 = -1;

bool gShouldAttack = true;

Strategy scenarioAttackWaveStrategy()
{

   // Start enabling rules.
   xsEnableRule("ClassicalUnits");
   xsEnableRule("researchPickaxe");
   xsEnableRule("researchHandAxe");

   if (cDifficultyCurrent >= cDifficultyHard)
   {
      xsEnableRule("researchHandsOfThePharaoh");
   }

   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugStrategy("***Starting Scenario Attack Wave Strategy***");
      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================

      // Weaken certain Easy parameters.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gAttackStartSize = 3;
         gAttackMaxSize = 4;
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;

      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackStartDelay += xsGetTime(); // Offset for wakeup.

      gTrainDelay *= gDifficultyModifierTrainDelay;
      gWadjetDelay *= gDifficultyModifierTrainDelay;
      gChariotDelay *= gDifficultyModifierTrainDelay;
      gScarabDelay *= gDifficultyModifierTrainDelay;
      gMummyDelay *= gDifficultyModifierTrainDelay;
      gClassicalAgeUpTime *= gDifficultyModifierAgeUp;
      gClassicalAgeUpTime += xsGetTime(); // Offset for awake moment.
      gHeroicAgeUpTime *= gDifficultyModifierAgeUp;
      gHeroicAgeUpTime += xsGetTime(); // Offset for awake moment.
      gMythicAgeUpTime *= gDifficultyModifierAgeUp;
      gMythicAgeUpTime += xsGetTime(); // Offset for awake moment.


      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);

      data.setTrainDelay(gThirdLandUnit, gWadjetDelay);
      data.setTrainDelay(gFourthLandUnit, gChariotDelay);
      data.setTrainDelay(gFifthLandUnit, gScarabDelay);
      data.setTrainDelay(gSixthLandUnit, gMummyDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(245.0, 0.0, 31.0); // Left of the central TC.
      vector targetPoint = vector(155.0, 0.0, 204.0); // Next to the Temple of Kronos.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path that goes out their west gate, directly to the Kronos Temple.");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(197.0, 0.0, 81.0)); // Block #1
      kbPathAddWaypoint(pathID1, vector(187.0, 0.0, 103.0)); // Block #2
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path that goes out their south gate, directly to the Kronos Temple.");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(95.0, 0.0, 25.0)); // Block #1
      kbPathAddWaypoint(pathID2, vector(87.0, 0.0, 79.0)); // Block #2
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      /* gLandDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 40.0, startPoint, 10);
      aiPlanSetVariableFloat(gLandDefendPlan, cDefendPlanEngageRange, 0, 40.0);
      // Exclude Phoenixes and Pharaohs from the Land Defense Plan; they're busy patrolling the base.
      aiPlanAddUnitType(gLandDefendPlan, gFirstLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, gSecondLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, gThirdLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, gFourthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, gFifthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, gSixthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeAnubite, 0, 0, 200);
      */ 

      // Regular
      gLandDefendPlan = createDefendPlan("Main Patrol Plan", -1, 5.0, vector(203.0, 0.0, 41.0), 30, vector(203.0, 0.0, 41.0));
      // Exclude Phoenixes from the Land Defense Plan; they're busy patrolling the base.
      // Don't toss infantry into the plan until later.
      aiPlanSetVariableBool(gLandDefendPlan, cDefendPlanPatrol, 0, true);
      aiPlanSetNumberVariableValues(gLandDefendPlan, cDefendPlanPatrolWaypoints, 3);
      aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanPatrolWaypoints, 0, vector(203.0, 0.0, 41.0));
      aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanPatrolWaypoints, 1, vector(269.0, 0.0, 35.0));
      aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanPatrolWaypoints, 2, vector(301.0, 0.0, 77.0));
      aiPlanSetVariableInt(gLandDefendPlan, 0, 0, 1000);

      aiPlanAddUnitType(gLandDefendPlan, gFourthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypePharaoh, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeSonOfOsiris, 0, 0, 200);

      // Regular
      gLandDefendPlan2 = createDefendPlan("Spear Plan", -1, 5.0, vector(215.0, 0.0, 75.0), 30, vector(215.0, 0.0, 75.0));
      // Exclude Phoenixes and Pharaohs from the Land Defense Plan; they're busy patrolling the base.

      aiPlanSetVariableBool(gLandDefendPlan2, cDefendPlanPatrol, 0, true);
      aiPlanSetNumberVariableValues(gLandDefendPlan2, cDefendPlanPatrolWaypoints, 2);
      aiPlanSetVariableVector(gLandDefendPlan2, cDefendPlanPatrolWaypoints, 0, vector(215.0, 0.0, 79.0));
      aiPlanSetVariableVector(gLandDefendPlan2, cDefendPlanPatrolWaypoints, 1, vector(191.0, 0.0, 85.0));
      aiPlanSetVariableInt(gLandDefendPlan2, 0, 0, 1000);

      // Myth
      int gMythDefendPlan = createDefendPlan("Myth Unit Defense", -1, 5.0, vector(257.0, 0.0, 65.0), 10, vector(257.0, 0.0, 65.0));
      aiPlanAddUnitType(gMythDefendPlan, gThirdLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gMythDefendPlan, gFifthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gMythDefendPlan, gSixthLandUnit, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      int age = kbPlayerGetAge(cMyID);
      static bool done = false;
      static bool Reached_Classical = false;
      static bool Reached_Heroic = false;
      static bool Reached_Mythic = false;

      // Time to go to Classical.
      if (age == cAge1 && xsGetTime() >= gClassicalAgeUpTime)
      {
         researchSimpleTech(cTechClassicalAgePtah, cUnitTypeTownCenter, -1, 75);
      }

      // Time to go to Heroic.
      if (age == cAge2 && xsGetTime() >= gHeroicAgeUpTime)
      {
         researchSimpleTech(cTechHeroicAgeSekhmet, cUnitTypeTownCenter, -1, 75);
      }

      // Time to go to Mythic.
      if (age == cAge3 && xsGetTime() >= gMythicAgeUpTime)
      {
         researchSimpleTech(cTechMythicAgeOsiris, cUnitTypeCitadelCenter, -1, 75);
      }
      

      // * * * TECH RULES * * * //

      // CLASSICAL AGE //
      if (age >= cAge2 && Reached_Classical == false)
      {
         // Techs for all difficulties:
         xsEnableRule("researchMediumAxemen");
         xsEnableRule("researchMediumSpearmen");
         xsEnableRule("researchCopperArmoryTechs");
         xsEnableRule("researchPlow");

         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchLeatherFrameShield");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchScallopedAxe");
            xsEnableRule("researchMasons");
         }

         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            // No techs.
         }

         Reached_Classical = true;
      }

      // HEROIC AGE //
      if (age >= cAge3 && Reached_Heroic == false)
      {

         // Techs for all difficulties:
         xsEnableRule("researchHeavyAxemen");
         xsEnableRule("researchHeavySpearmen");
         xsEnableRule("researchBronzeWeapons");

         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchBronzeArmor");
            xsEnableRule("researchBronzeShields");
            xsEnableRule("researchHeavyChariotArchers");
            xsEnableRule("researchBoilingOil");
            xsEnableRule("researchCrenellations");
            xsEnableRule("researchBallistics");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchCrimsonLinen");
            xsEnableRule("researchBoneBow");
            xsEnableRule("researchGuardTower");
         }

         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchArchitects");
         }
         
         Reached_Heroic = true;
      }

      // Deploy Scarabs only after 30 minutes.
      static bool scarabs = false;
      if (xsGetTime() >= 1800 && scarabs == false)
      {
         gAttackWave.addAttackUnitType(gFifthLandUnit);
         scarabs = true;
      }

      // MYTHIC AGE //
      if (age >= cAge4 && Reached_Mythic == false)
      {
         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchNewKingdom");
            xsEnableRule("researchBurningPitch");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchAtefCrown");
            xsEnableRule("researchChampionSpearmen");
            xsEnableRule("researchChampionAxemen");
         }

         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchChampionChariotArchers");
            xsEnableRule("researchIronArmor");
         }
         
         Reached_Mythic = true;
      }

      // ************************** ATTACK ROUTE UPDATE ************************** //
      // If we find out that player 1 has stuff by the northwest Settlement,
      // then we'll start passing by that area before marching on to the Kronos Temple.
      // **************************************************************************//


      // Only define the paths once.
      static bool defined_paths = false;
      static int pathID3 = -1;
      static int pathID4 = -1;
      static int pathID5 = -1;

      if (defined_paths == false)
      {
         vector startPoint = vector(260.0, 0.0, 190.0); // In front of their Relic.
         vector targetPoint = vector(150.0, 0.0, 196.0); // Next to the Temple of Kronos.

         pathID3 = kbPathCreate("Path that goes to the northwest Settlement, then the Kronos Temple.");
         kbPathAddWaypoint(pathID3, startPoint);
         kbPathAddWaypoint(pathID3, vector(305.0, 0.0, 81.0)); // Block #1
         kbPathAddWaypoint(pathID3, vector(295.0, 0.0, 111.0)); // Block #2
         kbPathAddWaypoint(pathID3, vector(249.0, 0.0, 103.0)); // Block #3
         kbPathAddWaypoint(pathID3, vector(287.0, 0.0, 297.0)); // Block #4
         kbPathAddWaypoint(pathID3, vector(129.0, 0.0, 305.0)); // Block #5
         kbPathAddWaypoint(pathID3, vector(229.0, 0.0, 279.0)); // Block #6
         kbPathAddWaypoint(pathID3, vector(245.0, 0.0, 241.0)); // Block #7
         kbPathAddWaypoint(pathID3, targetPoint);

         // Duplicates of the original routes that go directly to the Kronos Temple.
         pathID4 = kbPathCreate("Path that goes out their west gate, directly to the Kronos Temple.");
         kbPathAddWaypoint(pathID4, startPoint);
         kbPathAddWaypoint(pathID4, vector(197.0, 0.0, 81.0)); // Block #1
         kbPathAddWaypoint(pathID4, vector(187.0, 0.0, 103.0)); // Block #2
         kbPathAddWaypoint(pathID4, targetPoint);

         pathID5 = kbPathCreate("Path that goes out their south gate, directly to the Kronos Temple.");
         kbPathAddWaypoint(pathID5, startPoint);
         kbPathAddWaypoint(pathID5, vector(95.0, 0.0, 25.0)); // Block #1
         kbPathAddWaypoint(pathID5, vector(87.0, 0.0, 79.0)); // Block #2
         kbPathAddWaypoint(pathID5, targetPoint);
         defined_paths = true;
      }

      // Only run through this code if it's been at least 1 minute since we last checked.
      static int route_check = 0;

      // Only run through this code if we haven't started attacking the northwest.
      static bool added_route = false;
      route_check++;
      int game_time = xsGetTime();

      // Only add the attack route if it's been more than 15 minutes.
      if (route_check >= 60 && game_time > 900)
      {
         // Don't check again until 1 minute later.
         route_check = 0;

         vector riverbank_center = vector(182.0, 0.0, 308.0);
         int numEnemyBuildings = -1;
         int numEnemyMilitary = -1;
         int numEnemyCitizens = -1;
         int totalEnemies = 0;

         numEnemyBuildings = getUnitCountByLocation(cUnitTypeBuilding, 1, cUnitStateAlive, riverbank_center, 69.0);
         numEnemyMilitary = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, 1, cUnitStateAlive, riverbank_center, 69.0);
         numEnemyCitizens = getUnitCountByLocation(cUnitTypeAbstractVillager, 1, cUnitStateAlive, riverbank_center, 69);

         totalEnemies += numEnemyBuildings;
         totalEnemies += numEnemyMilitary;
         totalEnemies += numEnemyCitizens;

         debugAttackWave("numResults for updating our attack route: " + totalEnemies);

         if (totalEnemies >= 1 && added_route == false)
         {
            // We found out that player 1 is hanging out north of the riverbank - updating our attack route.
            // Get rid of the old paths and start using the new one exclusively.
            kbPathDestroy(kbAttackRouteGetPathIDByIndex(gAttackWave.mAttackRouteID, 1));
            kbPathDestroy(kbAttackRouteGetPathIDByIndex(gAttackWave.mAttackRouteID, 0));
            kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID3);
            added_route = true;
         }
         if (totalEnemies == 0 && added_route == true)
         {
            // Get rid of the old path and start using the new ones exclusively.
            kbPathDestroy(kbAttackRouteGetPathIDByIndex(gAttackWave.mAttackRouteID, 0));
            kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID4);
            kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID5);
            added_route = false;
         }
      }

      static bool accelerated_attacks = false;
      if (gShouldAttack == true)
      {
         // Begin attacking more frequently at the 20-minute mark on all difficulties except Easy.
         if (xsGetTime() >= 2100 && cDifficultyCurrent >= cDifficultyModerate)
         {
            // Accelerate attacks from this point on - the Atlanteans should be built up by now.
            if (accelerated_attacks == false)
            {
               gAttackWaveInterval *= 0.75; // Attacks happen a bit faster now.
               accelerated_attacks = true;
            }
         }
         gAttackWave.update();
      }
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void tna05StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(241.00, 0.00, 31.00), 90);

   setOverrideStrategy(tna05StrategySetup);

   gOverrideFarmCount = 18; // We can't have too many farms due to space restrictions.
   gRBDSystem.setMaxFarmsPerBase(18);
   gRBDSystem.setMaxFarmsPerIteration(18);
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, vector(261.0, 5, 21.0), 15.0); // Our TC.
      kbBuildingPlacementAddPositionInfluence(bpID, vector(261.0, 5, 21.0), 100.0, 15.0, cFalloffLinear); // Our TC.
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

// Activated once the player reaches Classical.
rule ClassicalUnits
inactive
minInterval 10
{
   int age = kbPlayerGetAge(cMyID);
   if (age >= cAge2)
   {
      // We're in Classical, now we can add Spearmen, Axemen, and Wadjets to our attack plan.
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      gAttackWave.addAttackUnitType(gThirdLandUnit);
      gAttackWave.update();
      xsEnableRule("HeroicUnits");
      xsDisableRule("ClassicalUnits");
      return;
   }
}

// Activated once the player reaches Heroic.
rule HeroicUnits
inactive
minInterval 10
{
   int age = kbPlayerGetAge(cMyID);
   if (age >= cAge3)
   {
      gAttackWave.addAttackUnitType(gFourthLandUnit);
      gAttackWave.update();   
      xsEnableRule("MythicUnits");
      xsEnableRule("useCitadel");
      xsDisableRule("HeroicUnits");
      return;
   }
}

rule useCitadel
inactive
minInterval 10
{
   int queryID = getUnitByLocation(cUnitTypeAbstractTownCenter, cMyID, cUnitStateAlive, vector(261.0, 5.0, 21.0), 15.0);
   if (queryID > 0)
   {
      if (aiCastGodPowerAtUnit(cProtoPowerCitadel, queryID) == true)
      {
         debugAttackWave("Casted Citadel!");
         xsDisableRule("useCitadel");
      }
   }
}

// Activated once the player reaches Mythic.
rule MythicUnits
inactive
minInterval 10
{
   int age = kbPlayerGetAge(cMyID);
   if (age >= cAge4)
   {
      int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gSixthLandUnit);
      aiPlanSetVariableInt(
         planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gSixthLandUnit, cProtoStatTrainPoints)
         + gChariotDelay
      );
      gAttackWave.addAttackUnitType(gSixthLandUnit);
      gAttackWave.update();
      xsEnableRule("useSonOfOsiris");
      xsDisableRule("MythicUnits");
   }
}

rule useSonOfOsiris
inactive
minInterval 10
{
   int queryID2 = getUnitByLocation(cUnitTypePharaoh, cMyID, cUnitStateAlive, vector(261.0, 0.0, 21.0), 150.0);
   if (queryID2 > 0)
   {
      if (aiCastGodPowerAtUnit(cProtoPowerSonOfOsiris, queryID2) == true)
      {
         debugAttackWave("Casted Son of Osiris!");
         xsDisableRule("useSonOfOsiris");
      }
   }
}

rule WeakenedEconomy
inactive
minInterval 10
{
   kbPlayerSetHandicap(cMyID, 0.1 * kbPlayerGetHandicap(cMyID));
   debugAttackWave("Our economy is way weaker now.");
   // Stop attacking on Easy and Moderate.
   if (cDifficultyCurrent <= cDifficultyModerate)
   {
      gShouldAttack = false;
   }
   xsDisableRule("WeakenedEconomy");
}

/**/
// * * * * * * * * * * TECH PROGRESSIONS * * * * * * * * * * //
/**/

// ECONOMIC TECHS
   // Hand Axe
      rule researchHandAxe
      inactive
      minInterval 180
      {
         debugAttackWave("Starting Hand Axe research plan.");
         researchSimpleTech(cTechHandAxe, cUnitTypeLumberCamp, -1, 50);
         xsDisableRule("researchHandAxe");
      }
   // Pickaxe
      rule researchPickaxe
      inactive
      minInterval 180
      {
         debugAttackWave("Starting Pickaxe research plan.");
         researchSimpleTech(cTechPickaxe, cUnitTypeMiningCamp, -1, 50);
         xsDisableRule("researchPickaxe");
      }
   // Plow
      rule researchPlow
      inactive
      minInterval 30
      {
         xsSetRuleMinIntervalSelf(10);
         // Cease if we have it. Otherwise, research it.
         if (kbTechGetStatus(cTechPlow) == cTechStatusActive)
         {
            xsDisableRule("researchPlow");
            return;
         }
         else if (kbTechGetStatus(cTechPlow) == cTechStatusObtainable)
         {
            debugAttackWave("Starting Plow research plan.");
            researchSimpleTech(cTechPlow, cUnitTypeGranary, -1, 60);
            return;
         }
      }
   // Irrigation
      rule researchIrrigation
      inactive
      minInterval 30
      {
         xsSetRuleMinIntervalSelf(10);
         // Cease if we have it. Otherwise, research it.
         if (kbTechGetStatus(cTechIrrigation) == cTechStatusActive)
         {
            xsDisableRule("researchIrrigation");
            return;
         }
         else if (kbTechGetStatus(cTechIrrigation) == cTechStatusObtainable)
         {
            debugAttackWave("Starting Irrigation research plan.");
            researchSimpleTech(cTechIrrigation, cUnitTypeGranary, -1, 60);
            return;
         }
      }
   // Bow Saw
      rule researchBowSaw
      inactive
      minInterval 30
      {
         xsSetRuleMinIntervalSelf(10);
         // Cease if we have it. Otherwise, research it.
         if (kbTechGetStatus(cTechBowSaw) == cTechStatusActive)
         {
            xsDisableRule("researchBowSaw");
            return;
         }
         else if (kbTechGetStatus(cTechBowSaw) == cTechStatusObtainable)
         {
            debugAttackWave("Starting BowSaw research plan.");
            researchSimpleTech(cTechBowSaw, cUnitTypeLumberCamp, -1, 60);
            return;
         }
      }
   // Shaft Mine
      rule researchShaftMine
      inactive
      minInterval 30
      {
         xsSetRuleMinIntervalSelf(10);
         // Cease if we have it. Otherwise, research it.
         if (kbTechGetStatus(cTechShaftMine) == cTechStatusActive)
         {
            xsDisableRule("researchShaftMine");
            return;
         }
         else if (kbTechGetStatus(cTechShaftMine) == cTechStatusObtainable)
         {
            debugAttackWave("Starting ShaftMine research plan.");
            researchSimpleTech(cTechShaftMine, cUnitTypeMiningCamp, -1, 60);
            return;
         }
      }

// Hands of the Pharaoh (Archaic Age)
   rule researchHandsOfThePharaoh
   inactive
   minInterval 240
   {
      debugAttackWave("Starting Hands of the Pharaoh research plan.");
      researchSimpleTech(cTechHandsOfThePharaoh, cUnitTypeTemple, -1, 50);
      xsDisableRule("researchHandsOfThePharaoh");
   }

// *** CLASSICAL AGE ***
   // ALL DIFFICULTIES
      // Medium Spearmen
         rule researchMediumSpearmen
         inactive
         minInterval 30
         {
            debugAttackWave("Starting Medium Spearmen research plan.");
            researchSimpleTech(cTechMediumSpearmen, cUnitTypeBarracks, -1, 50);
            xsDisableRule("researchMediumSpearmen");
         }
      // Medium Axemen
         rule researchMediumAxemen
         inactive
         minInterval 60
         {
            debugAttackWave("Starting Medium Axemen research plan.");
            researchSimpleTech(cTechMediumAxemen, cUnitTypeBarracks, -1, 50);
            xsDisableRule("researchMediumAxemen");
         }
      // Copper Armory
         rule researchCopperArmoryTechs
         inactive
         minInterval 90
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if ((kbTechGetStatus(cTechCopperWeapons) == cTechStatusActive) &&
               (kbTechGetStatus(cTechCopperArmor) == cTechStatusActive) &&
               (kbTechGetStatus(cTechCopperShields) == cTechStatusActive))
            {
               xsDisableRule("researchCopperArmoryTechs");
               return;
            }
            if (kbTechGetStatus(cTechCopperWeapons) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Copper Weapons research plan.");
               researchSimpleTech(cTechCopperWeapons, cUnitTypeArmory, -1, 60);
               return;
            }
            if (kbTechGetStatus(cTechCopperArmor) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Copper Armor research plan.");
               researchSimpleTech(cTechCopperArmor, cUnitTypeArmory, -1, 60);
               return;
            }
            if (kbTechGetStatus(cTechCopperShields) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Copper Shields research plan.");
               researchSimpleTech(cTechCopperShields, cUnitTypeArmory, -1, 60);
               return;
            }
         }
   // NOT EASY
      // Leather Frame Shield
         rule researchLeatherFrameShield
         inactive
         minInterval 300
         {
            debugAttackWave("Starting Leather Frame Shield research plan.");
            researchSimpleTech(cTechLeatherFrameShield, cUnitTypeArmory, -1, 50);
            xsDisableRule("researchLeatherFrameShield");
         }
   // HARD AND TITAN ONLY
      // Scalloped Axe
         rule researchScallopedAxe
         inactive
         minInterval 210
         {
            debugAttackWave("Starting Scalloped Axe research plan.");
            researchSimpleTech(cTechScallopedAxe, cUnitTypeArmory, -1, 50);
            xsDisableRule("researchScallopedAxe");
         }
      // Masons
         rule researchMasons
         inactive
         minInterval 900
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechMasons) == cTechStatusActive)
            {
               xsDisableRule("researchMasons");
               return;
            }
            else if (kbTechGetStatus(cTechMasons) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Masons research plan.");
               researchSimpleTech(cTechMasons, cUnitTypeTownCenter, -1, 60);
               return;
            }
         }

// *** HEROIC AGE ***
   // ALL DIFFICULTIES
      // Heavy Axemen
         rule researchHeavyAxemen
         inactive
         minInterval 30
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechHeavyAxemen) == cTechStatusActive)
            {
               xsDisableRule("researchHeavyAxemen");
               return;
            }
            else if (kbTechGetStatus(cTechHeavyAxemen) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Heavy Axemen research plan.");
               researchSimpleTech(cTechHeavyAxemen, cUnitTypeBarracks, -1, 60);
               return;
            }
         }
      // Heavy Spearmen
         rule researchHeavySpearmen
         inactive
         minInterval 60
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
      // Bronze Weapons
         rule researchBronzeWeapons
         inactive
         minInterval 150
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
   // NOT EASY
      // Bronze Armor
         rule researchBronzeArmor
         inactive
         minInterval 240
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
         minInterval 300
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
      // Heavy Chariots
         rule researchHeavyChariotArchers
         inactive
         minInterval 360
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
      // Boiling Oil
         rule researchBoilingOil
         inactive
         minInterval 240
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
      // Crenellations
         rule researchCrenellations
         inactive
         minInterval 320
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechCrenellations) == cTechStatusActive)
            {
               xsDisableRule("researchCrenellations");
               return;
            }
            else if (kbTechGetStatus(cTechCrenellations) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Crenellations research plan.");
               researchSimpleTech(cTechCrenellations, cUnitTypeSentryTower, -1, 60);
               return;
            }
         }
      // Ballistics
         rule researchBallistics
         inactive
         minInterval 50
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechBallistics) == cTechStatusActive)
            {
               xsDisableRule("researchBallistics");
               return;
            }
            else if (kbTechGetStatus(cTechBallistics) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Ballistics research plan.");
               researchSimpleTech(cTechBallistics, cUnitTypeArmory, -1, 60);
               return;
            }
         }
   // HARD AND TITAN ONLY
      // Crimson Linen
         rule researchCrimsonLinen
         inactive
         minInterval 440
         {
            debugAttackWave("Starting Crimson Linen research plan.");
            researchSimpleTech(cTechCrimsonLinen, cUnitTypeTemple, -1, 50);
            xsDisableRule("researchCrimsonLinen");
         }
      // Bone Bow
         rule researchBoneBow
         inactive
         minInterval 180
         {
            debugAttackWave("Starting Bone Bow research plan.");
            researchSimpleTech(cTechBoneBow, cUnitTypeMigdolStronghold, -1, 50);
            xsDisableRule("researchBoneBow");
         }
      // Guard Tower
         rule researchGuardTower
         inactive
         minInterval 360
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
   // TITAN ONLY
      // Architects
         rule researchArchitects
         inactive
         minInterval 600
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

// *** MYTHIC AGE ***
   // NOT EASY
      // New Kingdom
         rule researchNewKingdom
         inactive
         minInterval 300
         {
            debugAttackWave("Starting New Kingdom research plan.");
            researchSimpleTech(cTechNewKingdom, cUnitTypeTemple, -1, 50);
            xsDisableRule("researchNewKingdom");
         }
      // Burning Pitch
         rule researchBurningPitch
         inactive
         minInterval 150
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechBurningPitch) == cTechStatusActive)
            {
               xsDisableRule("researchBurningPitch");
               return;
            }
            else if (kbTechGetStatus(cTechBurningPitch) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Burning Pitch research plan.");
               researchSimpleTech(cTechBurningPitch, cUnitTypeArmory, -1, 60);
               return;
            }
         }

   // HARD AND TITAN ONLY
      // Iron Weapons
         rule researchIronWeapons
         inactive
         minInterval 150
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
      // Atef Crown
         rule researchAtefCrown
         inactive
         minInterval 600
         {
            debugAttackWave("Starting Atef Crown research plan.");
            researchSimpleTech(cTechAtefCrown, cUnitTypeTemple, -1, 50);
            xsDisableRule("researchAtefCrown");
         }
      // Champion Spearmen
         rule researchChampionSpearmen
         inactive
         minInterval 480
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
      // Champion Axemen
         rule researchChampionAxemen
         inactive
         minInterval 640
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

   // TITAN ONLY
      // Iron Armor
         rule researchIronArmor
         inactive
         minInterval 240
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
      // Champion ChariotArchers
         rule researchChampionChariotArchers
         inactive
         minInterval 480
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

// The initial army died. Infantry should now be in the regular defend plans.
void EnableDefense()
{
   aiPlanAddUnitType(gLandDefendPlan, gFirstLandUnit, 0, 0, 200);
   aiPlanAddUnitType(gLandDefendPlan, gSecondLandUnit, 0, 0, 200);
   aiPlanAddUnitType(gLandDefendPlan, cUnitTypeAnubite, 0, 0, 200);
   aiPlanAddUnitType(gLandDefendPlan2, gFirstLandUnit, 0, 0, 200);
}