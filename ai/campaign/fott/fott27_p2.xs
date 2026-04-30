//==============================================================================
/* fott27_p2.xs

   Red Norse player owning the production buildings and eco in the north. Sends attacks of (Hirdmen, Throwing Axemen or
   Berserks), (Hersirs or Godis), (Einheri, Battle Boars or Frost Giants), Jarls, Huskarls and Portable Rams.
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
int gFirstLandUnit = -1; // Random Longhouse unit -> trained from Classical Age.
float gMaintainFirstLandUnitAmount = 10;

int gSecondLandUnit = cUnitTypeHersir; // Random Great Hall unit; always Hersir in Classical -> trained from Classical Age.
float gMaintainSecondLandUnitAmount = 8;
int gThirdLandUnit = cUnitTypeEinheri; // Random Temple unit; always Einheri in Classical -> trained from Classical Age.
float gMaintainThirdLandUnitAmount = 4;
int gFourthLandUnit = cUnitTypeHuskarl; // Starts getting trained in Heroic.
float gMaintainFourthLandUnitAmount = -1; // Amount decided randomly, shuffled in Mythic.
int gFifthLandUnit = cUnitTypeJarl; // Starts getting trained in Heroic.
float gMaintainFifthLandUnitAmount = -1; // Amount decided randomly, shuffled in Mythic.
int gSixthLandUnit = cUnitTypePortableRam; // Starts getting trained in Heroic.
float gMaintainSixthLandUnitAmount = 2;

float gMaxVillagerCount = 18;
float gAttackStartDelay = 300; // In seconds.
float gAttackWaveInterval = 240; // In seconds.
float gAttackStartSize = 5;
float gAttackMaxSize = 10;
float gHeroicAgeUpTime = 480; // In seconds. (8 minutes)
float gMythicAgeUpTime = 1080; // In seconds. (18 minutes)
int gLandDefendPlan = -1;

int routeID = -1;
int routeID1 = -1;
int routeID2 = -1;
int routeID3 = -1;

int pathID0 = -1;
int pathID1 = -1;
int pathID2 = -1;
int pathID3 = -1;

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;
      int gDefendPlan3 = -1;
      int gDefendPlan4 = -1;

// Choose the route.
   vector getAttackStart(int index = -1)
   {
      // Route 1 (Far West)
      if(index == 0)
      {
         return vector(131.0, 0.0, 231.0);
      }
      // Route 2 (Centre-West)
      else if(index == 1)
      {
         return vector(151.0, 0.0, 181.0);
      }
      // Route 3 (Centre-East)
      else if(index == 2)
      {
         return vector(167.0, 0.0, 137.0);
      }
      // Route 4 (Far East)
      return vector(229.0, 0.0, 141.0);
   }
   int getRouteID(int index = -1)
   {
      // Route 1 (Far West)
      if(index == 0)
      {
         return routeID;
      }
      // Route 2 (Centre-West)
      else if(index == 1)
      {
         return routeID1;
      }
      // Route 3 (Centre-East)
      else if(index == 2)
      {
         return routeID2;
      }
      // Route 4 (Far East)
      return routeID3;
   }

Strategy scenarioAttackWaveStrategy()
{
   // This should never fail.
   aiCastGodPowerAtPosition(cProtoPowerRain, vector(95.0, 0.0, 173.0));

   // Start enabling rules.
   // xsEnableRule("increaseAttackSize");
   xsEnableRule("useUndermine");

   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugStrategy("***Starting Scenario Attack Wave Strategy***");
      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================

      // Certain parameters are much more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gMaintainFirstLandUnitAmount = 8; // 8 Longhouse Units
         gMaintainSecondLandUnitAmount = 5; // 5 Heroes
         gMaintainThirdLandUnitAmount = 3; // 3 Myth Units
         gMaintainSixthLandUnitAmount = 1; // 1 Portable Ram

         gAttackWaveInterval = 600; // In seconds.
         gAttackStartSize = 5;
         gAttackMaxSize = 7;
      }

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackStartDelay += xsGetTime(); // Offset for awake moment.
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;

      gHeroicAgeUpTime *= gDifficultyModifierAgeUp;
      gHeroicAgeUpTime += xsGetTime(); // Offset for awake moment.
      gMythicAgeUpTime *= gDifficultyModifierAgeUp;
      gMythicAgeUpTime += xsGetTime(); // Offset for awake moment.

      // Longhouse Units - Hirdmen, Throwing Axemen, or Berserks.
      int random = xsRandInt(0, 2);
      if (random == 0)
      {
         gFirstLandUnit = cUnitTypeHirdman;
      }
      else if (random == 1)
      {
         gFirstLandUnit = cUnitTypeThrowingAxeman;
      }
      else // 2.
      {
         gFirstLandUnit = cUnitTypeBerserk;
      }

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
      gAttackWave.addAttackUnitType(gSixthLandUnit);

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticOxCartTraining, true);
      data.setFlag(cStrategyFlagAutoResearchMilitaryUpgrades, true);
      gTimeToFarm = true;

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(180.0, 0.0, 165.0); // Next to P1's TC.
      vector targetPoint = vector(127.0, 0.0, 55.0); // Next to P1's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      routeID = kbCreateAttackRouteWithPath("Far West Route", startPoint, targetPoint);

      pathID0 = kbPathCreate("Path 1 start in the far west.");
      kbPathAddWaypoint(pathID0, vector(115.0, 0.0, 219.0)); // Start
      kbPathAddWaypoint(pathID0, vector(47.0, 0.0, 175.0)); // Block #2.
      kbPathAddWaypoint(pathID0, vector(51.0, 0.0, 147.0)); // Block #3.
      kbPathAddWaypoint(pathID0, vector(75.0, 0.0, 77.0)); // Block #4.
      kbPathAddWaypoint(pathID0, targetPoint);
      kbAttackRouteAddPath(routeID, pathID0);

      pathID1 = kbPathCreate("Path 2 starts in the centre-west.");
      kbPathAddWaypoint(pathID1, vector(129.0, 0.0, 177.0)); // Start Point
      kbPathAddWaypoint(pathID1, vector(115.0, 0.0, 167.0)); // Block #1.
      kbPathAddWaypoint(pathID1, vector(105.0, 0.0, 119.0)); // Block #2.
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      pathID2 = kbPathCreate("Path 3 starts in the centre-right.");
      kbPathAddWaypoint(pathID2, vector(169.0, 0.0, 131.0)); // Start Point
      kbPathAddWaypoint(pathID2, vector(179.0, 0.0, 111.0)); // Block #1.
      kbPathAddWaypoint(pathID2, vector(239.0, 0.0, 59.0)); // Block #2.
      kbPathAddWaypoint(pathID2, vector(219.0, 0.0, 21.0)); // Block #3.
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      pathID3 = kbPathCreate("Path 4 starts in the far right.");
      kbPathAddWaypoint(pathID3, vector(225.0, 0.0, 113.0)); // Start Point
      kbPathAddWaypoint(pathID3, vector(239.0, 0.0, 59.0)); // Block #2.
      kbPathAddWaypoint(pathID3, vector(219.0, 0.0, 21.0)); // Block #3.
      kbPathAddWaypoint(pathID3, targetPoint);
      kbAttackRouteAddPath(routeID, pathID3);

      // Randomize a matching attack route for both land and naval attack plans.
      int rand = xsRandInt() % 4;

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      /* gLandDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 60.0, startPoint, 20);
      aiPlanSetVariableFloat(gLandDefendPlan, cDefendPlanEngageRange, 0, 25.0);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200); */


   // SPLIT AMOUNTS
      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 2; // Longhouse Units
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 3; // Hersirs or Goðar
      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2; // Einheri, Battle Boar, or Frost Giant
      int sixthLandUnitSplitAmount = gMaintainSixthLandUnitAmount / 2; // Portable Rams


   // DEFINE THE PLANS
      // Plan 1 (Guarding their northern base)
      gDefendPlan1 = createDefendPlan("Defense Plan 1", kbBaseGetMainID(cMyID), 10, vector(131.0, 0.0, 231.0), 30);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 25);
      aiPlanAddUnitType(gDefendPlan1, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Heroes
      aiPlanAddUnitType(gDefendPlan1, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Myth Units
      aiPlanAddUnitType(gDefendPlan1, gSixthLandUnit, 0, 0, 200); // Portable Rams

      // Plan 2 (Guarding their southern gauntlet)
      gDefendPlan2 = createDefendPlan("Defense Plan 2", kbBaseGetMainID(cMyID), 10, vector(151.0, 0.0, 181.0), 30);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan2, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Longhouse Units
      aiPlanAddUnitType(gDefendPlan2, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Heroes
      aiPlanAddUnitType(gDefendPlan2, gFifthLandUnit, 0, 0, 200); // Jarls

      // Plan 3 (Guarding the eastern multi-walled area)
      gDefendPlan3 = createDefendPlan("Defense Plan 3", kbBaseGetMainID(cMyID), 10, vector(153.0, 0.0, 143.0), 30);
      aiPlanSetVariableFloat(gDefendPlan3, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan3, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Longhouse Units
      aiPlanAddUnitType(gDefendPlan3, gFourthLandUnit, 0, 0, 200); // Huskies
      aiPlanAddUnitType(gDefendPlan3, gSixthLandUnit, 0, 0, 200); // Portable Rams

      // Plan 4 (Entrance to their southwestern Temple)
      gDefendPlan4 = createDefendPlan("Defense Plan 4", kbBaseGetMainID(cMyID), 10, vector(229.0, 0.0, 141.0), 30);
      aiPlanSetVariableFloat(gDefendPlan4, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan4, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Heroes
      aiPlanAddUnitType(gDefendPlan4, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Myth Units

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      int age = kbPlayerGetAge(cMyID);

      static bool needResearchHeroic = true;
      static bool needResearchMythic = true;
      static bool classical_done = false;
      static bool heroic_done = false;
      static bool mythic_done = false;

      // Shuffle units for Classical Age.
      if (classical_done == false && age == cAge2)
      {
         classical_done = true;
         // Longhouse Units - Hirdmen, Throwing Axemen, or Berserks.
         /* 
         int oldLonghouseUnit = gFirstLandUnit;
         while (gFirstLandUnit == oldLonghouseUnit)
         {
            int random = xsRandInt(0, 2);
            if (random == 0)
            {
               gFirstLandUnit = cUnitTypeHirdman;
            }
            else if (random == 1)
            {
               gFirstLandUnit = cUnitTypeThrowingAxeman;
            }
            else // 2.
            {
               gFirstLandUnit = cUnitTypeBerserk;
            }
         } */

         // CLASSICAL AGE TECH RULES //
         // All Difficulties:
         researchSimpleTech(cTechMediumInfantry, cUnitTypeLonghouse, -1, 60);
         researchSimpleTech(cTechMediumCavalry, cUnitTypeGreatHall, -1, 60);
         researchSimpleTech(cTechCopperWeapons, cUnitTypeArmory, -1, 60);
         researchSimpleTech(cTechCopperArmor, cUnitTypeArmory, -1, 60);
         researchSimpleTech(cTechCopperShields, cUnitTypeArmory, -1, 60);

         // Moderate and Up:

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         { 
            researchSimpleTech(cTechGjallarhorn, cUnitTypeTemple, -1, 60);
            researchSimpleTech(cTechCrenellations, cUnitTypeSentryTower, -1, 60);
            researchSimpleTech(cTechPlow, cUnitTypeOxCart, -1, 60);
         }

         // Titan Only:

         data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
         data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
         data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);

         data.setTrainDelay(gFirstLandUnit, gTrainDelay);
         data.setTrainDelay(gSecondLandUnit, gTrainDelay);
         data.setTrainDelay(gThirdLandUnit, gTrainDelay);

         gAttackWave.addAttackUnitType(gFirstLandUnit);
         gAttackWave.addAttackUnitType(gSecondLandUnit);
         gAttackWave.addAttackUnitType(gThirdLandUnit);

         gAttackWave.update();
      }

      // Time to go to Heroic.
      if (needResearchHeroic == true && age == cAge2 && xsGetTime() >= gHeroicAgeUpTime)
      {
         if (researchSimpleTech(cTechHeroicAgeBragi, cUnitTypeTownCenter, -1, 75) == true)
         {
            debugAttackWave("Starting Heroic Age research plan.");
            needResearchHeroic = false;
         }
      }
      // Shuffle units for Heroic Age.
      if (heroic_done == false && age == cAge3)
      {
         heroic_done = true;
         // Shuffle our army.
         data.removeUnitToMaintain(gFirstLandUnit);
         data.removeUnitToMaintain(gSecondLandUnit);
         data.removeUnitToMaintain(gThirdLandUnit);
         data.removeUnitToMaintain(gFourthLandUnit);
         data.removeUnitToMaintain(gFifthLandUnit);

         // Longhouse Units - Hirdmen, Throwing Axemen, or Berserks.
         int oldLonghouseUnit = gFirstLandUnit;
         while (gFirstLandUnit == oldLonghouseUnit)
         {
            int random = xsRandInt(0, 2);
            if (random == 0)
            {
               gFirstLandUnit = cUnitTypeHirdman;
            }
            else if (random == 1)
            {
               gFirstLandUnit = cUnitTypeThrowingAxeman;
            }
            else // 2.
            {
               gFirstLandUnit = cUnitTypeBerserk;
            }
         }

         // Great Hall Units - Hersirs or Goðar.
         int oldGreatHallUnit = gSecondLandUnit;
         while (gSecondLandUnit == oldGreatHallUnit)
         {
            if (xsRandBool() == true)
            {
               gSecondLandUnit = cUnitTypeHersir;
            }
            else // false.
            {
               gSecondLandUnit = cUnitTypeGodi;
            }
         }

         // Temple Units - Einherjars or Battle Boars (Frost Giants not yet available)
         int oldTempleUnit = gThirdLandUnit;
         while (gThirdLandUnit == oldTempleUnit)
         {
            bool HeroicTemple = xsRandBool();
            if (HeroicTemple == true)
            {
               gThirdLandUnit = cUnitTypeEinheri;
            }
            else // false.
            {
               gThirdLandUnit = cUnitTypeBattleBoar;
            }
         }

         // Decide first Jarl/Huskarl/Portable Ram combination.
         if (xsRandBool() == true) // More Huskarls than Jarls.
         {
            gMaintainFourthLandUnitAmount = 6 * gDifficultyModifierMaintainUnit;
            gMaintainFifthLandUnitAmount = 2 * gDifficultyModifierMaintainUnit;
            // Fewer on Easy.
            if (cDifficultyCurrent == cDifficultyEasy)
            {
               gMaintainFourthLandUnitAmount = 3;
               gMaintainFifthLandUnitAmount = 1;
            }
         }
         else // false; more Jarls than Huskarls.
         {
            gMaintainFourthLandUnitAmount = 3 * gDifficultyModifierMaintainUnit;
            gMaintainFifthLandUnitAmount = 5 * gDifficultyModifierMaintainUnit;
            // Fewer on Easy.
            if (cDifficultyCurrent == cDifficultyEasy)
            {
               gMaintainFourthLandUnitAmount = 1;
               gMaintainFifthLandUnitAmount = 3;
            }
         }

         // Add randomized units to attack plan.
         data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
         data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
         data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
         data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
         data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);

         // Adding portable ram.
         data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);

         // Train delay, how long the AI waits before queuing up another unit.
         data.setTrainDelay(gFirstLandUnit, gTrainDelay);
         data.setTrainDelay(gSecondLandUnit, gTrainDelay);
         data.setTrainDelay(gThirdLandUnit, gTrainDelay);
         data.setTrainDelay(gFourthLandUnit, gTrainDelay);
         data.setTrainDelay(gFifthLandUnit, gTrainDelay);
         data.setTrainDelay(gSixthLandUnit, gTrainDelay);

         // Add Shuffled Units Back to Plans

            // SPLIT AMOUNTS
               int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 2; // Longhouse Units
               int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 3; // Hersirs or Goðar
               int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2; // Einheri, Battle Boar, or Frost Giant
               int sixthLandUnitSplitAmount = gMaintainSixthLandUnitAmount / 2; // Portable Rams

         aiPlanAddUnitType(gDefendPlan1, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Heroes
         aiPlanAddUnitType(gDefendPlan1, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Myth Units

         aiPlanAddUnitType(gDefendPlan2, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Longhouse Units
         aiPlanAddUnitType(gDefendPlan2, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Heroes

         aiPlanAddUnitType(gDefendPlan3, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Longhouse Units

         aiPlanAddUnitType(gDefendPlan4, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Heroes
         aiPlanAddUnitType(gDefendPlan4, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Myth Units


         gAttackWave.addAttackUnitType(gFirstLandUnit);
         gAttackWave.addAttackUnitType(gSecondLandUnit);
         gAttackWave.addAttackUnitType(gThirdLandUnit);
         gAttackWave.addAttackUnitType(gFourthLandUnit);
         gAttackWave.addAttackUnitType(gFifthLandUnit);

         // Enlarge our attacks.
         if (cDifficultyCurrent == cDifficultyHard)
         {
            gAttackMaxSize *= 1.15; // Dispatch +15% units (Hard)
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }
         else if (cDifficultyCurrent == cDifficultyTitan)
         {
            gAttackMaxSize *= 1.25; // Dispatch +25% units (Titan)
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }

         // HEROIC AGE TECH RULES //
         // All Difficulties:
         researchSimpleTech(cTechIrrigation, cUnitTypeOxCart, -1, 60);
         researchSimpleTech(cTechShaftMine, cUnitTypeOxCart, -1, 60);
         researchSimpleTech(cTechBowSaw, cUnitTypeOxCart, -1, 60);

         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         { 
            researchSimpleTech(cTechHeavyInfantry, cUnitTypeLonghouse, -1, 60);
            researchSimpleTech(cTechHeavyCavalry, cUnitTypeGreatHall, -1, 60);
            researchSimpleTech(cTechBronzeWeapons, cUnitTypeArmory, -1, 60);
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 60); 
            researchSimpleTech(cTechThurisazRune, cUnitTypeTemple, -1, 60);
            researchSimpleTech(cTechBoilingOil, cUnitTypeSentryTower, -1, 60);
            researchSimpleTech(cTechBallistics, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechFortifiedTownCenter, cUnitTypeTownCenter, -1, 60);
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            researchSimpleTech(cTechCallOfValhalla, cUnitTypeLonghouse, -1, 60);
         }

         gAttackWave.update();

         // We're in Heroic, now we can use Flaming Weapons.
         xsEnableRule("useFlamingWeapons");
      }

      // Time to go to Mythic.
      if (needResearchMythic == true && age == cAge3 && xsGetTime() >= gMythicAgeUpTime)
      {
         if (researchSimpleTech(cTechMythicAgeHel, cUnitTypeTownCenter, -1, 75) == true)
         {
            debugAttackWave("Starting Mythic Age research plan.");
            needResearchMythic = false;
         }
      }
      // Shuffle units for Mythic Age.
      if (mythic_done == false && age == cAge4)
      {
         mythic_done = true;
         // Shuffle our army.
         data.removeUnitToMaintain(gFirstLandUnit);
         data.removeUnitToMaintain(gSecondLandUnit);
         data.removeUnitToMaintain(gThirdLandUnit);
         // Huskarls and Jarls need to be re-added.
         data.removeUnitToMaintain(gFourthLandUnit);
         data.removeUnitToMaintain(gFifthLandUnit);

         // Longhouse Units - Hirdmen, Throwing Axemen, or Berserks
         int oldLonghouseUnit = gFirstLandUnit;
         while (gFirstLandUnit == oldLonghouseUnit)
         {
            int random = xsRandInt(0, 2);
            if (random == 0)
            {
               gFirstLandUnit = cUnitTypeHirdman;
            }
            else if (random == 1)
            {
               gFirstLandUnit = cUnitTypeThrowingAxeman;
            }
            else // 2.
            {
               gFirstLandUnit = cUnitTypeBerserk;
            }
         }

         // Great Hall Units - Hersirs or Godis
         int oldGreatHallUnit = gSecondLandUnit;
         while (gSecondLandUnit == oldGreatHallUnit)
         {
            if (xsRandBool() == true)
            {
               gSecondLandUnit = cUnitTypeHersir;
            }
            else // false.
            {
               gSecondLandUnit = cUnitTypeGodi;
            }
         }

         // Temple Units - Einherjars, Battle Boars, or Frost Giants
         int oldTempleUnit = gThirdLandUnit;
         while (gThirdLandUnit == oldTempleUnit)
         {
            int random = xsRandInt(0, 2);
            if (random == 0)
            {
               gThirdLandUnit = cUnitTypeEinheri;
            }
            else if (random == 1)
            {
               gThirdLandUnit = cUnitTypeBattleBoar;
            }
            else // 2.
            {
               gThirdLandUnit = cUnitTypeFrostGiant;
            }
         }

         // Shuffle the Jarl/Huskarl/Portable Ram combination.
         int oldHuskarlAmount = gMaintainFourthLandUnitAmount;
         int oldJarlAmount = gMaintainFifthLandUnitAmount;
         if (xsRandBool() == true) // More Huskarls than Jarls.
         {
            gMaintainFourthLandUnitAmount = 7 * gDifficultyModifierMaintainUnit;
            gMaintainFifthLandUnitAmount = 4 * gDifficultyModifierMaintainUnit;
            // Fewer on Easy.
            if (cDifficultyCurrent == cDifficultyEasy)
            {
               gMaintainFourthLandUnitAmount = 3;
               gMaintainFifthLandUnitAmount = 2;
            }
         }
         else // false; more Jarls than Huskarls.
         {
            gMaintainFourthLandUnitAmount = 5 * gDifficultyModifierMaintainUnit;
            gMaintainFifthLandUnitAmount = 6 * gDifficultyModifierMaintainUnit;
            // Fewer on Easy.
            if (cDifficultyCurrent == cDifficultyEasy)
            {
               gMaintainFourthLandUnitAmount = 3;
               gMaintainFifthLandUnitAmount = 2;
            }
         }

         // Add randomized units to attack plan.
         data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
         data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
         data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
         data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
         data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);

         // Train delay, how long the AI waits before queuing up another unit.
         data.setTrainDelay(gFirstLandUnit, gTrainDelay);
         data.setTrainDelay(gSecondLandUnit, gTrainDelay);
         data.setTrainDelay(gThirdLandUnit, gTrainDelay);
         data.setTrainDelay(gFourthLandUnit, gTrainDelay);
         data.setTrainDelay(gFifthLandUnit, gTrainDelay);
         data.setTrainDelay(gSixthLandUnit, gTrainDelay);

         // Add Shuffled Units Back to Plans.

            // SPLIT AMOUNTS
               int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 2; // Longhouse Units
               int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 3; // Hersirs or Goðar
               int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2; // Einheri, Battle Boar, or Frost Giant
               int sixthLandUnitSplitAmount = gMaintainSixthLandUnitAmount / 2; // Portable Rams

         aiPlanAddUnitType(gDefendPlan1, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Heroes
         aiPlanAddUnitType(gDefendPlan1, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Myth Units

         aiPlanAddUnitType(gDefendPlan2, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Longhouse Units
         aiPlanAddUnitType(gDefendPlan2, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Heroes
         aiPlanAddUnitType(gDefendPlan2, gFifthLandUnit, 0, 0, 200); // Jarls

         aiPlanAddUnitType(gDefendPlan3, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Longhouse Units
         aiPlanAddUnitType(gDefendPlan3, gFourthLandUnit, 0, 0, 200); // Huskies

         aiPlanAddUnitType(gDefendPlan4, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Heroes
         aiPlanAddUnitType(gDefendPlan4, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Myth Units

         gAttackWave.addAttackUnitType(gFirstLandUnit);
         gAttackWave.addAttackUnitType(gSecondLandUnit);
         gAttackWave.addAttackUnitType(gThirdLandUnit);
         gAttackWave.addAttackUnitType(gFourthLandUnit);
         gAttackWave.addAttackUnitType(gFifthLandUnit);

         // Enlarge our attacks.
         if (cDifficultyCurrent == cDifficultyModerate)
         {
            gAttackMaxSize *= 1.10; // Dispatch +10% units (Moderate)
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }
         else if (cDifficultyCurrent == cDifficultyHard)
         {
            gAttackMaxSize *= 1.05; // Dispatch +5% units (Hard)
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }
         else if (cDifficultyCurrent == cDifficultyTitan)
         {
            gAttackMaxSize *= 1.10; // Dispatch +10% units (Titan)
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }

         gAttackWave.update();

         // MYTHIC AGE TECH RULES //
         // All Difficulties:
         researchSimpleTech(cTechFloodControl, cUnitTypeOxCart, -1, 60);
         researchSimpleTech(cTechQuarry, cUnitTypeOxCart, -1, 60);
         researchSimpleTech(cTechCarpenters, cUnitTypeOxCart, -1, 60);

         // Moderate and Up:

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 60);
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            researchSimpleTech(cTechIronArmor, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechChampionInfantry, cUnitTypeLonghouse, -1, 60);
            researchSimpleTech(cTechChampionCavalry, cUnitTypeGreatHall, -1, 60);
         }
      }


      static int elapsed_time = 0;
      int increase_interval = xsGetTime() - elapsed_time;
      
      // Increase the Attack Start Size every 90 seconds. Stop running this if gAttackStartSize catches up to the max attack size.
      if ((increase_interval >= 90) && (gAttackStartSize < gAttackMaxSize))
      {
         gAttackStartSize *= 1.1; // Increases by 10 percent.
         elapsed_time = xsGetTime();
         // If the last adjustment knocked the gAttackStartSize over the gAttackMaxSize, resolve it.
         if (gAttackStartSize > gAttackMaxSize)
         {
            gAttackStartSize = gAttackMaxSize;
         }
      }


      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott27StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(115.00, 0.00, 259.00), 32);
   // createOverrideGatherBase(vector(173.00, 0.00, 251.00), 64);
   createOverrideGatherBase(vector(77.00, 0.00, 257.00), 24);
   gOverrideFarmCount = 20; // We can't have too many farms due to space restrictions.
   gRBDSystem.setMaxFarmsPerBase(20);
   gRBDSystem.setMaxFarmsPerIteration(20);

   setOverrideStrategy(fott27StrategySetup);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// Increase attack sizes every time an attack is launched.
rule increaseAttackSize
inactive
minInterval 360 // TODO - The actual conditions are different.
{
   int current_time = xsGetTime();
   int oldAttackStartSize = gAttackStartSize;
   int oldAttackMaxSize = gAttackMaxSize;
   
   gAttackStartSize = oldAttackStartSize * 1.1; // Increases by 10 percent.
   if (oldAttackStartSize > oldAttackMaxSize)
   {
      debugAttackWave("Start size surpassed max size; we will no longer increase attack sizes.");
      gAttackStartSize = gAttackMaxSize;
      xsDisableRule("increaseAttackSize");
      return;
   }
}

// Use Undermine while attacking and P1 has more than 2 Wall segments in sight.
rule useUndermine
inactive
minInterval 5
{
   int planID = -1;
   int unitID = -1;
   int numWalls = -1;
   int targetID = -1;
   int[] planIDs = aiPlanGetIDsByType(cPlanAttack);
   for (int i = 0; i < planIDs.size(); i++)
   {
      planID = planIDs[i];
      if (aiPlanGetParentID(planID) == -1)
      {
         // We just take the first unit to scan from.
         unitID = aiPlanGetUnitIDByIndex(planID, 0);
         if (unitID >= 0)
         {
            numWalls = getUnitCountByLocation(cUnitTypeAbstractWall, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 15.0);
            debugAttackWave("numWalls for casting Wall Segments: " + numWalls);
            if (numWalls >= 2)
            {
               // Grab an enemy wall.
               targetID = getUnitByLocation(cUnitTypeAbstractWall, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 15.0);
               if (targetID >= 0)
               {
                  if (aiCastGodPowerAtDualPosition(cProtoPowerUndermine, kbUnitGetPosition(unitID), kbUnitGetPosition(targetID)) == true)
                  {
                     debugAttackWave("Casted Undermine!");
                     xsDisableRule("useUndermine");
                  }
               }
            }
         }  
      }
   }
}

// Use Flaming Weapons while attacking and P1 has more than 6 soldiers in sight.
rule useFlamingWeapons
inactive
minInterval 5
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
            int queryID = useSimpleUnitQuery(cUnitTypeMilitaryUnit, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 15.0);
            numEnemies = kbUnitQueryExecute(queryID);
            debugAttackWave("numEnemies for invoking Flaming Weapons: " + numEnemies);
            if (numEnemies >= 6 && xsGetTime() >= 900)
            {
               if (aiCastGodPowerAtPosition(cProtoPowerFlamingWeapons, kbUnitGetPosition(kbUnitQueryGetResult(queryID, 0))) == true)
               {
                  debugAttackWave("Invoke Flaming Weapons!");
                  xsDisableRule("useFlamingWeapons");
               }
            }
         }
      }
   }
}

// Move defend plans (when nearby buildings are destroyed)
   void updateDefendPlan1()
   {
      // Nearby buildings are destroyed. We will move our defend plan behind the inner walls.
      aiPlanSetVariableVector(gDefendPlan1, cDefendPlanTargetPoint, 0, vector(197.0, 0.0, 227.0));
      aiPlanSetVariableVector(gDefendPlan1, cDefendPlanGatherPoint, 0, vector(197.0, 0.0, 227.0));
      debugAttackWave("Contracted our defense plan.");
   }
   void updateDefendPlan2()
   {
      // Nearby buildings are destroyed. We will move our defend plan behind the inner walls.
      aiPlanSetVariableVector(gDefendPlan2, cDefendPlanTargetPoint, 0, vector(171.0, 0.0, 189.0));
      aiPlanSetVariableVector(gDefendPlan2, cDefendPlanGatherPoint, 0, vector(171.0, 0.0, 189.0));
      debugAttackWave("Contracted our defense plan.");
   }
   void updateDefendPlan3()
   {
      // Nearby buildings are destroyed. We will move our defend plan behind the inner walls.
      aiPlanSetVariableVector(gDefendPlan3, cDefendPlanTargetPoint, 0, vector(209.0, 0.0, 161.0));
      aiPlanSetVariableVector(gDefendPlan3, cDefendPlanGatherPoint, 0, vector(209.0, 0.0, 161.0));
      debugAttackWave("Contracted our defense plan.");
   }
   void updateDefendPlan4()
   {
      // Nearby buildings are destroyed. We will move our defend plan behind the inner walls.
      aiPlanSetVariableVector(gDefendPlan4, cDefendPlanTargetPoint, 0, vector(239.0, 0.0, 181.0));
      aiPlanSetVariableVector(gDefendPlan4, cDefendPlanGatherPoint, 0, vector(239.0, 0.0, 181.0));
      debugAttackWave("Contracted our defense plan.");
   }