//==============================================================================
/* tna05_p3.xs

   Orange Egyptian player that attacks amphibiously.
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
float gAnubiteDelay = 30; // In seconds.
float gKebenitDelay = 30; // In seconds
float gCamelRiderDelay = 45; // In seconds.
float gSiegeTowerDelay = 60; // In seconds.
float gLeviathanDelay = 90; // In seconds.
float gWarBargeDelay = 45; // In seconds.
float gRammingShipDelay = 30; // In seconds.

int gFirstLandUnit = cUnitTypeAxeman; // Begins training once they reach the Classical Age.
float gMaintainFirstLandUnitAmount = 3;
int gSecondLandUnit = cUnitTypeSlinger; // Begins training once they reach the Classical Age.
float gMaintainSecondLandUnitAmount = 3;
int gThirdLandUnit = cUnitTypePriest; // Begins training once they reach the Classical Age.
float gMaintainThirdLandUnitAmount = 2;
int gFourthLandUnit = cUnitTypeAnubite; // Begins training once they reach the Classical Age.
float gMaintainFourthLandUnitAmount = 2;
int gFifthLandUnit = cUnitTypeCamelRider; // Begins training once they reach the Heroic Age.
float gMaintainFifthLandUnitAmount = 4;
int gSixthLandUnit = cUnitTypeSiegeTower; // Begins training once they reach the Heroic Age.
float gMaintainSixthLandUnitAmount = 1;
int gSeventhLandUnit = cUnitTypeScorpionMan; // Begins training once they reach the Heroic Age.
float gMaintainSeventhLandUnitAmount = 3;

// TODO - naval escorts for transports.
int gFirstWaterUnit = cUnitTypeKebenit; // Begins training once they reach the Classical Age.
float gMaintainFirstWaterUnitAmount = 2;
int gSecondWaterUnit = cUnitTypeLeviathan; // Begins training once they reach the Heroic Age.
float gMaintainSecondWaterUnitAmount = 1;
int gThirdWaterUnit = cUnitTypeWarBarge; // Begins training once they reach the Heroic Age.
float gMaintainThirdWaterUnitAmount = 1;

float gMaxVillagerCount = 10;
float gMaxFishingShipCount = 2;

float gAttackStartDelay = 360; // Routes that only target the Kronos Temple
float gAttackWaveInterval = 720; // In seconds.
float gAttackStartSize = 5;
float gAttackMaxSize = 8;

float gSecondAttackStartDelay = 1200; // Crosses the river and attacks the resource area before going to the Temple.
float gSecondAttackInterval = 720; // Landings only.
float gSecondAttackStartSize = 7;
float gSecondAttackMaxSize = 10;

float gNavalAttackStartDelay = 900; // In seconds.
float gNavalAttackWaveInterval = 600; // In seconds.
float gNavalAttackStartSize = 2;
float gNavalAttackMaxSize = 3;

float gInitialAttackStartSize = 4; // Used to calculate new values from increments before applying the multiplier.
float gInitialAttackMaxSize = 8; // Used to calculate new values from increments before applying the multiplier.

float gClassicalAgeUpTime = 420; // In seconds. (7 minutes)
float gHeroicAgeUpTime = 1110; // In seconds. (18½ minutes)

int gLandDefendPlan = -1;

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;
      int gDefendPlan3 = -1;

bool gShouldAttack = true;

Strategy scenarioAttackWaveStrategy()
{

   // Start enabling rules.
   xsEnableRule("buildDock");
   xsEnableRule("useVision");
   xsEnableRule("usePlagueOfSerpents");
   xsEnableRule("useAncestors");
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
      gMaintainSeventhLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gMaintainFirstWaterUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondWaterUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdWaterUnitAmount *= gDifficultyModifierMaintainUnit;

      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gSecondAttackInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gSecondAttackStartSize *= gDifficultyModifierAttackSizes;
      gSecondAttackMaxSize *= gDifficultyModifierAttackSizes;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackStartDelay += xsGetTime(); // Offset for wakeup.

      gSecondAttackStartDelay *= gDifficultyModifierFirstAttack;
      gSecondAttackStartDelay += xsGetTime(); // Offset for wakeup.

      gNavalAttackStartDelay *= gDifficultyModifierFirstAttack;
      gNavalAttackStartDelay += xsGetTime(); // Offset for wakeup.
      gNavalAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gNavalAttackStartSize *= gDifficultyModifierAttackSizes;
      gNavalAttackMaxSize *= gDifficultyModifierAttackSizes;

      gTrainDelay *= gDifficultyModifierTrainDelay;
      gAnubiteDelay *= gDifficultyModifierTrainDelay;
      gKebenitDelay *= gDifficultyModifierTrainDelay;
      gCamelRiderDelay *= gDifficultyModifierTrainDelay;
      gSiegeTowerDelay *= gDifficultyModifierTrainDelay;
      gLeviathanDelay *= gDifficultyModifierTrainDelay;
      gWarBargeDelay *= gDifficultyModifierTrainDelay;
      gRammingShipDelay *= gDifficultyModifierTrainDelay;

      gClassicalAgeUpTime *= gDifficultyModifierAgeUp;
      gClassicalAgeUpTime += xsGetTime(); // Offset for awake moment.
      gHeroicAgeUpTime *= gDifficultyModifierAgeUp;
      gHeroicAgeUpTime += xsGetTime(); // Offset for awake moment.


      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
      data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);

      data.addUnitToMaintain(gFirstWaterUnit, gMaintainFirstWaterUnitAmount);
      data.addUnitToMaintain(gSecondWaterUnit, gMaintainSecondWaterUnitAmount);
      data.addUnitToMaintain(gThirdWaterUnit, gMaintainThirdWaterUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gFourthLandUnit);
      aiPlanSetVariableInt(
         planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gFourthLandUnit, cProtoStatTrainPoints)
         + gAnubiteDelay
      );
      planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gFifthLandUnit);
      aiPlanSetVariableInt(
         planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gFifthLandUnit, cProtoStatTrainPoints)
         + gCamelRiderDelay
      );
      planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gSixthLandUnit);
      aiPlanSetVariableInt(
         planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gSixthLandUnit, cProtoStatTrainPoints)
         + gSiegeTowerDelay
      );
      planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gSeventhLandUnit);
      aiPlanSetVariableInt(
         planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gSixthLandUnit, cProtoStatTrainPoints)
         + gTrainDelay
      );

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      gAttackWave.addAttackUnitType(gThirdLandUnit);
      gAttackWave.addAttackUnitType(gFourthLandUnit);
      gAttackWave.addAttackUnitType(gFifthLandUnit);
      // Don't add Siege Towers until way layer.
      gAttackWave.addAttackUnitType(gSeventhLandUnit);

      // River crossing waves (not dispatched on Easy)
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         gSecondAttackWave.setName("gSecondAttackWave");
         gSecondAttackWave.setAttackStartTime(gSecondAttackStartDelay);
         gSecondAttackWave.setAttackInterval(gSecondAttackInterval);
         gSecondAttackWave.setAttackSize(gAttackStartSize);
         gSecondAttackWave.setMaxAttackSize(gAttackMaxSize);
         gSecondAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
         gSecondAttackWave.addAttackUnitType(gFirstLandUnit);
         gSecondAttackWave.addAttackUnitType(gSecondLandUnit);
         gSecondAttackWave.addAttackUnitType(gThirdLandUnit);
         gSecondAttackWave.addAttackUnitType(gFourthLandUnit);
         gSecondAttackWave.addAttackUnitType(gFifthLandUnit);
         // Don't add Siege Towers until way later.
         gSecondAttackWave.addAttackUnitType(gSeventhLandUnit);
      }

      // Don't dispatch naval attacks on Easy.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gNavalAttackWave.setName("gNavalAttackWave");
         gNavalAttackWave.setAttackStartTime(gNavalAttackStartDelay);
         gNavalAttackWave.setAttackInterval(gNavalAttackWaveInterval);
         gNavalAttackWave.setAttackSize(gNavalAttackStartSize);
         gNavalAttackWave.setMaxAttackSize(gNavalAttackMaxSize);
         gNavalAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
         gNavalAttackWave.addAttackUnitType(gFirstWaterUnit);
         gNavalAttackWave.addAttackUnitType(gThirdWaterUnit);
         gNavalAttackWave.setIsNavalAttackWave();
         
         debugAttackWave("Naval Attack Times:");
         gNavalAttackWave.displayFirstAttackStats();
      }
      
      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticFishing, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!
      gSecondAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(46.0, 0.0, 213.0); // Between their Migdol Strongholds
      vector targetPoint = vector(168.0, 8.0, 201.0); // Next to the Temple of Kronos.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path that leads directly to the Kronos Temple.");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path that goes out the south gate, past the lake, before arching up to the Kronos Temple.");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(29.0, 0.0, 115.0)); // Block #1
      kbPathAddWaypoint(pathID2, vector(79.0, 0.0, 63.0)); // Block #2
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

      vector startPoint2 = vector(51.0, 0.0, 293.0); // Near the Dock.

      int routeID2 = kbCreateAttackRouteWithPath("River crossing route to P1.", startPoint, targetPoint);
      int pathID3 = kbPathCreate("Path that crosses the river first.");
      kbPathAddWaypoint(pathID3, startPoint2);
      kbPathAddWaypoint(pathID3, vector(59.0, 0.0, 293.0)); // Block #1
      kbPathAddWaypoint(pathID3, vector(103.0, 0.0, 263.0)); // Block #2
      kbPathAddWaypoint(pathID3, vector(119.0, 0.0, 267.0)); // Block #3
      kbPathAddWaypoint(pathID3, vector(153.0, 0.0, 299.0)); // Block #4
      kbPathAddWaypoint(pathID3, vector(279.0, 0.0, 303.0)); // Block #5
      kbPathAddWaypoint(pathID3, vector(271.0, 0.0, 249.0)); // Block #6
      kbPathAddWaypoint(pathID3, targetPoint);
      kbAttackRouteAddPath(routeID2, pathID3);

      gSecondAttackWave.setGatherPoint(startPoint2);
      gSecondAttackWave.setTargetPoint(targetPoint);
      gSecondAttackWave.setAttackRouteID(routeID2);
      gSecondAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      // Where does our attack start and end.
      vector navalStartPoint = vector(53.0, 0.0, 211.0); // In the western part of the river.
      vector navalTargetPoint = vector(161.0, 0.0, 247.0); // Near the player's initial shore.

      int routeID3 = kbCreateAttackRouteWithPath("Naval attack route.", navalStartPoint, navalTargetPoint);
      int pathID4 = kbPathCreate("Water route.");
      kbPathAddWaypoint(pathID4, navalStartPoint);
      kbPathAddWaypoint(pathID4, vector(299.0, 0.0, 249.0)); // Goes to the other side of the river first.
      kbPathAddWaypoint(pathID4, navalTargetPoint);
      kbAttackRouteAddPath(routeID3, pathID4);

      gNavalAttackWave.setGatherPoint(navalStartPoint);
      gNavalAttackWave.setTargetPoint(navalTargetPoint);
      gNavalAttackWave.setAttackRouteID(routeID2);
      gNavalAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      gLandDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 50.0, startPoint, 10);
      aiPlanSetVariableFloat(gLandDefendPlan, cDefendPlanEngageRange, 0, 40.0);
      // Exclude Pharaohs from the Land Defense Plan.
      aiPlanAddUnitType(gLandDefendPlan, gSixthLandUnit, 0, 0, 200); // Siege Towers are at the start point.


   // SPLIT AMOUNTS
      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 2; // Axemen
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 2; // Slingers
      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2; // Priests
      int fifthLandUnitSplitAmount = gMaintainFifthLandUnitAmount / 2; // Camel Riders
      int seventhLandUnitSplitAmount = gMaintainSeventhLandUnitAmount / 2; // Scorpion Men

   // DEFINE THE PLANS
      // Plan 1 (On the Relic plateau)
      gDefendPlan1 = createDefendPlan("Defense Plan 1", kbBaseGetMainID(cMyID), 15, vector(43.0, 0.0, 245.0), 30);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 40);
      aiPlanAddUnitType(gDefendPlan1, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Axemen
      aiPlanAddUnitType(gDefendPlan1, gSeventhLandUnit, 0, 0, seventhLandUnitSplitAmount); // Scorpion Men

      // Plan 2 (By their east gate)
      gDefendPlan2 = createDefendPlan("Defense Plan 2", kbBaseGetMainID(cMyID), 5, vector(81.0, 0.0, 157.0), 30);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 20);
      aiPlanAddUnitType(gDefendPlan2, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Axemen
      aiPlanAddUnitType(gDefendPlan2, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Slingers
      aiPlanAddUnitType(gDefendPlan2, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Priests
      aiPlanAddUnitType(gDefendPlan2, gFifthLandUnit, 0, 0, fifthLandUnitSplitAmount); // Camel Riders
      aiPlanAddUnitType(gDefendPlan2, gSeventhLandUnit, 0, 0, seventhLandUnitSplitAmount); // Scorpion Men

      // Plan 3 (By their south gate)
      gDefendPlan3 = createDefendPlan("Defense Plan 3", kbBaseGetMainID(cMyID), 5, vector(33.0, 0.0, 137.0), 30);
      aiPlanSetVariableFloat(gDefendPlan3, cDefendPlanEngageRange, 0, 40);
      aiPlanAddUnitType(gDefendPlan3, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Slingers
      aiPlanAddUnitType(gDefendPlan3, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Priests
      aiPlanAddUnitType(gDefendPlan3, gFourthLandUnit, 0, 0, 200); // Anubites
      aiPlanAddUnitType(gDefendPlan3, gFifthLandUnit, 0, 0, fifthLandUnitSplitAmount); // Camel Riders


      int waterDefendPlan = createDefendPlan("Water Defend Plan", -1, 5, navalStartPoint, 30);
      aiPlanSetVariableFloat(gDefendPlan3, cDefendPlanEngageRange, 0, 20);
      aiPlanAddUnitType(waterDefendPlan, cUnitTypeLogicalTypeNavalMilitary, 0, 0, 200);

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

      // Time to go to Classical.
      if (age < cAge2 && xsGetTime() >= gClassicalAgeUpTime)
      {
         researchSimpleTech(cTechClassicalAgeAnubis, cUnitTypeTownCenter, -1, 75);
      }

      // Time to go to Heroic.
      if (age < cAge3 && xsGetTime() >= gHeroicAgeUpTime)
      {
         researchSimpleTech(cTechHeroicAgeNephthys, cUnitTypeTownCenter, -1, 75);
      }
      
      // * * * TECH RULES * * * //

      // CLASSICAL AGE //
      if (age >= cAge2 && Reached_Classical == false)
      {
         // Techs for all difficulties:
         xsEnableRule("researchMediumAxemen");
         xsEnableRule("researchMediumSlingers");
         xsEnableRule("researchPlow");

         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchCopperArmoryTechs");
            xsEnableRule("researchStoneWall");
            xsEnableRule("researchPurseSeine");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchFeetOfTheJackal");
            xsEnableRule("researchNecropolis");
            xsEnableRule("researchMasons");
         }

         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            // N/A
         }

         Reached_Classical = true;
      }

      // HEROIC AGE //
      if (age >= cAge3 && Reached_Heroic == false)
      {
         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchBronzeWeapons");
            xsEnableRule("researchHeavySlingers");
            xsEnableRule("researchFortifiedWall");
            xsEnableRule("researchBoilingOil");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchBronzeShields");
            xsEnableRule("researchHeavyCamels");
            xsEnableRule("researchHeavyAxemen");
            xsEnableRule("researchDraftHorses");
            xsEnableRule("researchGuardTower");
            xsEnableRule("researchBallistics");
            xsEnableRule("researchSlingsOfTheSun");
            xsEnableRule("researchArchitects");
         }

         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchBronzeArmor");
            xsEnableRule("researchNebty");
            xsEnableRule("researchFortifiedTownCenter");
            xsEnableRule("researchHeavyWarships");
         }
         
         Reached_Heroic = true;
      }

      // Deploy Siege Towers only after 30 minutes.
      static bool siege_towers = false;
      if (xsGetTime() >= 1800 && siege_towers == false)
      {
         gAttackWave.addAttackUnitType(gSixthLandUnit);
         gSecondAttackWave.addAttackUnitType(gSixthLandUnit);
         siege_towers = true;
      }

      static bool accelerated_attacks = false;
      // Begin attacking more frequently at the 20-minute mark on all difficulties except Easy.
      if (xsGetTime() >= 1800 && cDifficultyCurrent >= cDifficultyModerate)
      {
         // Accelerate attacks from this point on - the Atlanteans should be built up by now.
         if (accelerated_attacks == false)
         {
            gAttackWaveInterval *= 0.75; // Attacks happen a bit faster now.
            gSecondAttackInterval *= 0.75; // Attacks happen a bit faster now.
            accelerated_attacks = true;
         }
      }

      if (gShouldAttack == true)
      {
         gAttackWave.update();
         gNavalAttackWave.update();
         gSecondAttackWave.update();

         // Only continue the second wave if the Atlanteans have stuff in the northwest.
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
         vector dock_zone = vector(57.0, 0.0, 273.0);
         if (totalEnemies >= 1 && getUnitCountByLocation(cUnitTypeLeviathan, cMyID, cUnitStateAlive, dock_zone, 300.0) == 1)
         {
            // gSecondAttackWave.update();
            totalEnemies = 0;
         }
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
   gOverrideMaxFishingShipPop = gMaxFishingShipCount;

   gMainGatherBase = createOverrideGatherBase(vector(39.00, 0.00, 167.00), 41);
   createOverrideGatherBase(vector(29.00, 0.00, 222.00), 30);
   createOverrideGatherBase(vector(23.00, 0.00, 295.00), 36);
   createOverrideGatherBase(vector(57.00, 0.00, 273.00), 28);
   gOverrideClosestFishLocation = vector(96.00, 0.00, 271.00);
   gMaxFishDockScanRange = 42;

   setOverrideStrategy(tna05StrategySetup);

   gOverrideFarmCount = 18; // We can't have too many farms due to space restrictions.
   gRBDSystem.setMaxFarmsPerBase(18);
   gRBDSystem.setMaxFarmsPerIteration(18);
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, vector(39.0, 3, 167.0), 15.0); // Our TC.
      kbBuildingPlacementAddPositionInfluence(bpID, vector(39.0, 3, 167.0), 100.0, 15.0, cFalloffLinear); // Our TC.
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

// Only starts working once the initial army is dead.
rule usePlagueOfSerpents
inactive
minInterval 10
{
   int numTemplesOfKronos = -1;
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
            numEnemies = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 10.0);
            numTemplesOfKronos = getUnitCountByLocation(cUnitTypeTempleOfKronos, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 10.0);
            debugAttackWave("numEnemies for casting Eclipse: " + numEnemies);
            if (numEnemies >= 2 && numTemplesOfKronos >= 1)
            {
               if (aiCastGodPowerAtPosition(cProtoPowerPlagueOfSerpents, kbUnitGetPosition(unitID)) == true)
               {
                  debugAttackWave("Casted Plague of Serpents!");
                  xsDisableRule("usePlagueOfSerpents");
                  return;
               }
            }
         }
      }
   }
}

rule useAncestors
inactive
minInterval 10
{
   int age = kbPlayerGetAge(cMyID);
   if (age >= cAge3)
   {
      int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
      int unitID = -1;
      int numEnemies = -1;
      int numDocks = -1;
      for (int i = 0; i < attackPlans.size(); i++)
      {
         if (aiPlanGetParentID(attackPlans[i]) == -1)
         {
            // We just take the first unit to scan from.
            unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
            if (unitID >= 0)
            {
               numEnemies = getUnitCountByLocation(cUnitTypeMilitaryUnit, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 10.0);
               numDocks = getUnitCountByLocation(cUnitTypeDock, 3, cUnitStateAlive, kbUnitGetPosition(unitID), 10.0);
               debugAttackWave("numEnemies for casting Ancestors: " + numEnemies);
               if (numEnemies >= 2 && numDocks >= 1)
               {
                  if (aiCastGodPowerAtPosition(cProtoPowerAncestors, kbUnitGetPosition(unitID)) == true)
                  {
                     debugAttackWave("Casted Ancestors");
                     xsDisableRule("useAncestors");
                     return;
                  }
               }
            }
         }
      }
   }
}

// Try to build a Dock above the relic Plateau.
rule buildDock
inactive
minInterval 10
{
   vector buildPosition = vector(57.0, -1.00, 273.0); // Shore above the Relic plateau.
   int numPlayerUnits = getUnitCountByLocation(cUnitTypeUnit, 1, cUnitStateAlive, buildPosition, 15.0);
   int numPlayerBuildings = getUnitCountByLocation(cUnitTypeBuilding, 1, cUnitStateAlive, buildPosition, 15.0);
   int numPlayerTotal = numPlayerUnits + numPlayerBuildings;
   if (numPlayerTotal <= 0)
   {
      int dockBuildPlan = createDockBuildPlan(kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)), vector(58.0, -1.00, 277.0), 1, 99, 1);
      xsDisableRule("buildDock");
   }

}

rule useVision
inactive
minInterval 180
{
   if (aiCastGodPowerAtPosition(cProtoPowerVision, vector(183.17, 8.73, 185.74)) == true)
   {
      debugAttackWave("Casted Rain!");
      xsDisableRule("useVision");
      return;
   }
}

/**/
// * * * * * * * * * * TECH PROGRESSIONS * * * * * * * * * * //
/**/

// *** TECH RULES *** //

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
            debugAttackWave("Starting Bow Saw research plan.");
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
      // Purse Seine
         rule researchPurseSeine
         inactive
         minInterval 300
         {
            xsSetRuleMinIntervalSelf(10);
            if (kbTechGetStatus(cTechPurseSeine) == cTechStatusActive)
            {
               debugAttackWave("Starting Purse Seine research plan.");
               researchSimpleTech(cTechPurseSeine, cUnitTypeDock, -1, 50);
               xsDisableRule("researchPurseSeine");
            }
         }

// Hands of the Pharaoh (Archaic)
rule researchHandsOfThePharaoh
inactive
minInterval 240
{
   debugAttackWave("Starting Hands of the Pharaoh research plan.");
   researchSimpleTech(cTechHandsOfThePharaoh, cUnitTypeTemple, -1, 50);
   xsDisableRule("researchHandsOfThePharaoh");
}

   // CLASSICAL AGE
      // ALL DIFFICULTIES:
         // Medium Axemen
            rule researchMediumAxemen
            inactive
            minInterval 30
            {
               debugAttackWave("Starting Medium Axemen research plan.");
               researchSimpleTech(cTechMediumAxemen, cUnitTypeBarracks, -1, 50);
               xsDisableRule("researchMediumAxemen");
            }
         // Medium Slingers
            rule researchMediumSlingers
            inactive
            minInterval 60
            {
               debugAttackWave("Starting Medium Slingers research plan.");
               researchSimpleTech(cTechMediumSlingers, cUnitTypeBarracks, -1, 50);
               xsDisableRule("researchMediumSlingers");
            }
      // NOT EASY:
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
         // Stone Wall
            rule researchStoneWall
            inactive
            minInterval 360
            {
               debugAttackWave("Starting Stone Wall research plan.");
               researchSimpleTech(cTechStoneWall, cUnitTypeWallGate, -1, 50);
               xsDisableRule("researchStoneWall");
            }
      // HARD AND TITAN ONLY:
         // Feet of the Jackal
            rule researchFeetOfTheJackal
            inactive
            minInterval 400
            {
               debugAttackWave("Starting Feet of the Jackal research plan.");
               researchSimpleTech(cTechFeetOfTheJackal, cUnitTypeTemple, -1, 50);
               xsDisableRule("researchFeetOfTheJackal");
            }
         // Necropolis
            rule researchNecropolis
            inactive
            minInterval 100
            {
               debugAttackWave("Starting Necropolis research plan.");
               researchSimpleTech(cTechNecropolis, cUnitTypeTemple, -1, 50);
               xsDisableRule("researchNecropolis");
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
      // NOT EASY:
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
         // Heavy Slingers
            rule researchHeavySlingers
            inactive
            minInterval 300
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechHeavySlingers) == cTechStatusActive)
               {
                  xsDisableRule("researchHeavySlingers");
                  return;
               }
               else if (kbTechGetStatus(cTechHeavySlingers) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Heavy Slingers research plan.");
                  researchSimpleTech(cTechHeavySlingers, cUnitTypeBarracks, -1, 60);
                  return;
               }
            }
         // Fortified Wall
            rule researchFortifiedWall
            inactive
            minInterval 150
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechFortifiedWall) == cTechStatusActive)
               {
                  xsDisableRule("researchFortifiedWall");
                  return;
               }
               else if (kbTechGetStatus(cTechFortifiedWall) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Fortified Wall research plan.");
                  researchSimpleTech(cTechFortifiedWall, cUnitTypeWallGate, -1, 60);
                  return;
               }
            }
         // Boiling Oil
            rule researchBoilingOil
            inactive
            minInterval 120
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
      // HARD AND TITAN ONLY:
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
         // Heavy Axemen
            rule researchHeavyAxemen
            inactive
            minInterval 300
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
         // Heavy Camel Riders
            rule researchHeavyCamels
            inactive
            minInterval 900
            {
               debugAttackWave("Starting Heavy Camels research plan.");
               researchSimpleTech(cTechHeavyCamelRiders, cUnitTypeMigdolStronghold, -1, 50);
               xsDisableRule("researchHeavyCamels");
            }
         // Draft Horses
            rule researchDraftHorses
            inactive
            minInterval 120
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechDraftHorses) == cTechStatusActive)
               {
                  xsDisableRule("researchDraftHorses");
                  return;
               }
               else if (kbTechGetStatus(cTechDraftHorses) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Draft Horses research plan.");
                  researchSimpleTech(cTechDraftHorses, cUnitTypeSiegeWorks, -1, 60);
                  return;
               }
            }
         // Guard Tower
            rule researchGuardTower
            inactive
            minInterval 160
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
         // Slings of the Sun
            rule researchSlingsOfTheSun
            inactive
            minInterval 640
            {
               xsSetRuleMinIntervalSelf(10);
               debugAttackWave("Starting Slings of theSun research plan.");
               researchSimpleTech(cTechSlingsOfTheSun, cUnitTypeArmory, -1, 50);
               xsDisableRule("researchSlingsOfTheSun");
            }
      // Architects
         rule researchArchitects
         inactive
         minInterval 720
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

      // TITAN ONLY:
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
         // Nebty
            rule researchNebty
            inactive
            minInterval 210
            {
               debugAttackWave("Starting Nebty research plan.");
               researchSimpleTech(cTechNebty, cUnitTypeTemple, -1, 50);
               xsDisableRule("researchNebty");
            }
      // Fortified Town Center
         rule researchFortifiedTownCenter
         inactive
         minInterval 300
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechFortifiedTownCenter) == cTechStatusActive)
            {
               xsDisableRule("researchFortifiedTownCenter");
               return;
            }
            else if (kbTechGetStatus(cTechArchitects) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Fortified Town Center research plan.");
               researchSimpleTech(cTechFortifiedTownCenter, cUnitTypeTownCenter, -1, 60);
               return;
            }
         }
      // Heavy Warships
         rule researchHeavyWarships
         inactive
         minInterval 600
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
               debugAttackWave("Starting Sun Ray research plan.");
               researchSimpleTech(cTechHeavyWarships, cUnitTypeDock, -1, 60);
               return;
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

// Move defend plans (when nearby gates are breached)
   void updateDefendPlan2()
   {
      // The gate is breached. We will move closer to the TC.
      aiPlanSetVariableVector(gDefendPlan2, cDefendPlanTargetPoint, 0, vector(23.0, 0.0, 173.0));
      aiPlanSetVariableVector(gDefendPlan2, cDefendPlanGatherPoint, 0, vector(23.0, 0.0, 173.0));
      debugAttackWave("Moved our defend plan close to the cart's final destination.");
   }
   void updateDefendPlan3()
   {
      // The gate is breached. We will move closer to the TC.
      aiPlanSetVariableVector(gDefendPlan3, cDefendPlanTargetPoint, 0, vector(51.0, 0.0, 161.0));
      aiPlanSetVariableVector(gDefendPlan3, cDefendPlanGatherPoint, 0, vector(51.0, 0.0, 161.0));
      debugAttackWave("Moved our defend plan close to the cart's final destination.");
   }