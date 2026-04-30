//==============================================================================
/* fott20_p2.xs


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

float gTrainDelay = 15; // In seconds.
float gTrainDelayHeroic = 10; // In seconds.

int gFirstLandUnit = cUnitTypeSphinx; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 3;
int gSecondLandUnit = cUnitTypeSpearman; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 8;
int gThirdLandUnit = cUnitTypeSlinger; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 8;
int gFourthLandUnit = cUnitTypePriest;
float gMaintainFourthLandUnitAmount = 6;
int gFifthLandUnit = cUnitTypeChariotArcher; // Start in Heroic.
float gMaintainFifthLandUnitAmount = 8;
int gSixthLandUnit = cUnitTypeSiegeTower; // Start in Heroic.
float gMaintainSixthLandUnitAmount = 2;
int gSeventhLandUnit = cUnitTypeCamelRider; // Start in Heroic.
float gMaintainSeventhLandUnitAmount = 8;
int gEighthLandUnit = cUnitTypeScorpionMan; // Start in Heroic.
float gMaintainEighthLandUnitAmount = 2;
int gNinthLandUnit = cUnitTypePhoenix; // Start in Mythic.
float gMaintainNinthLandUnitAmount = 1;

int gWallBuildPlan = -1;
int gWallDefendPlan = -1;

float gMaxVillagerCount = 16;
float gAttackStartDelay = -1; // In seconds.
float gAttackWaveInterval = 600; // In seconds.
float gAttackStartSize = 10;
float gAttackMaxSize = 14;

float gSecondAttackStartDelay = -1; // In seconds.
float gSecondAttackWaveInterval = 600; // In Seconds.

float gHeroicAgeUpTime = 900;  // 15 minutes (on easy)
float gMythicAgeUpTime = 1000;  // 1000 seconds

int gDefensePlan1 = -1;
int gDefensePlan2 = -1;
int gDefensePlan3 = -1;
int gDefensePlan4 = -1;

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
         gMaxVillagerCount = 12;
         gMaintainFirstLandUnitAmount = 1; // 1 Sphinx
         gMaintainSecondLandUnitAmount = 5; // 5 Spearmen
         gMaintainThirdLandUnitAmount = 5; // 5 Slingers
         gMaintainFourthLandUnitAmount = 2; // 2 Priests
         gMaintainFifthLandUnitAmount = 6; // 6 Chariot Archers
         gMaintainSeventhLandUnitAmount = 4; // 4 Camel Riders

         gAttackStartSize = 5;
         gAttackMaxSize = 12;

         gMythicAgeUpTime = 2400; // It takes very long to get to Mythic on Easy.
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSeventhLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainEighthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainNinthLandUnitAmount *= gDifficultyModifierMaintainUnit;

      // It's not certain whether Kemsyt will attack Chiron or Amanra first.
      int random = xsRandInt(0, 1);
      // Kemsyt attacks Chiron first.
      if (random == 0)
      {
         gAttackStartDelay = 500;
         gSecondAttackStartDelay = 800;
      }
      // Kemsyt attacks Amanra first.
      else // 1
      {
         gAttackStartDelay = 800;
         gSecondAttackStartDelay = 500;
      }

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;

      gSecondAttackStartDelay *= gDifficultyModifierFirstAttack;
      gSecondAttackWaveInterval *= gDifficultyModifierAttackInterval;

      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;
      gTrainDelayHeroic *= gDifficultyModifierTrainDelay;
      gHeroicAgeUpTime *= gDifficultyModifierAgeUp;
      gMythicAgeUpTime *= gDifficultyModifierAgeUp;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);

      // Details about the attack waves.

      // Attack Chiron's Base
         gAttackWave.setName("gAttackWave");
         gAttackWave.setAttackStartTime(gAttackStartDelay);
         gAttackWave.setAttackInterval(gAttackWaveInterval);
         gAttackWave.setAttackSize(gAttackStartSize);
         gAttackWave.setMaxAttackSize(gAttackMaxSize);
         gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
         gAttackWave.addAttackUnitType(gFirstLandUnit); // Sphinxes
         gAttackWave.addAttackUnitType(gSecondLandUnit); // Spearmen
         gAttackWave.addAttackUnitType(gThirdLandUnit); // Slingers

      // Attack Amanra's Base
         gSecondAttackWave.setName("gSecondAttackWave");
         gSecondAttackWave.setAttackStartTime(gSecondAttackStartDelay);
         gSecondAttackWave.setAttackInterval(gSecondAttackWaveInterval);
         gSecondAttackWave.setAttackSize(gAttackStartSize);
         gSecondAttackWave.setMaxAttackSize(gAttackMaxSize);
         gSecondAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
         // gSecondAttackWave.addAttackUnitType(gFirstLandUnit); // Sphinxes
         gSecondAttackWave.addAttackUnitType(gSecondLandUnit); // Spearmen
         // gSecondAttackWave.addAttackUnitType(gThirdLandUnit); // Slingers

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticMainBaseTCRebuild, true);

      gAttackWave.setPlayerToAttack(1); // Attack P1
      gSecondAttackWave.setPlayerToAttack(1); // Attack P1

      // Where does our attack start and end.
      vector startPoint1 = vector(164.0, 1.0, 317.0);     // Above the Armory and Siege Workshop, below Player 3's Town Center.
      vector startPoint2 = vector(225.0, 1.0, 241.0);     // Right of the city.

      vector targetPoint1 = vector(15.0, 1.0, 175.0);     // Chiron's base (the player's left flank)
      vector targetPoint2 = vector(135.0, 1.0, 54.0);     // Amanra's base (the player's right flank)

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a path to it.
      int routeID1 = kbCreateAttackRouteWithPath("Route To Chiron", startPoint1, targetPoint1);
      int routeID2 = kbCreateAttackRouteWithPath("Route To Amanra", startPoint2, targetPoint2);

      // Path 1, used for the first attack wave, which goes to Chiron's base.
      int pathID1 = kbPathCreate("Path 1 to Chiron");
      kbPathAddWaypoint(pathID1, startPoint1);
      kbPathAddWaypoint(pathID1, vector(102.0, 1.0, 263.0)); // Left Block #1
      kbPathAddWaypoint(pathID1, vector(86.0, 1.0, 212.0)); // Left Block #2
      kbPathAddWaypoint(pathID1, vector(86.0, 1.0, 163.0)); // Left Block #3
      kbPathAddWaypoint(pathID1, vector(27.0, 1.0, 139.0)); // Left Block #4
      kbPathAddWaypoint(pathID1, vector(170.0, 1.0, 85.0)); // Right Block #5
      kbPathAddWaypoint(pathID1, targetPoint1);
      kbAttackRouteAddPath(routeID1, pathID1);

      // Path 2, used for the first attack wave, which goes to Amanra's base.
      int pathID2 = kbPathCreate("Path 2 to Amanra");
      kbPathAddWaypoint(pathID2, startPoint2);
      kbPathAddWaypoint(pathID2, vector(228.0, 1.0, 226.0)); // Right Block #2
      kbPathAddWaypoint(pathID2, vector(214.0, 1.0, 192.0)); // Right Block #3
      kbPathAddWaypoint(pathID2, vector(206.0, 1.0, 140.0)); // Right Block #4
      kbPathAddWaypoint(pathID2, vector(170.0, 1.0, 85.0)); // Right Block #5
      kbPathAddWaypoint(pathID2, targetPoint2);
      kbAttackRouteAddPath(routeID2, pathID2);
      
      gAttackWave.setGatherPoint(startPoint1);
      gAttackWave.setTargetPoint(targetPoint1);
      gAttackWave.setAttackRouteID(routeID1);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
         static int counter = 0;
         static bool enabledEclipse = false;
         counter++;

         if (counter >= 3 && enabledEclipse == false)
         {
            if (cDifficultyCurrent >= cDifficultyModerate)
            {
               debugAttackWave("I will use Eclipse in 45 seconds (unless we're on Easy/Moderate)!");
               xsEnableRule("useEclipse");
            }
            enabledEclipse = true;
         }

      });

      gSecondAttackWave.setGatherPoint(startPoint2);
      gSecondAttackWave.setTargetPoint(targetPoint2);
      gSecondAttackWave.setAttackRouteID(routeID2);
      gSecondAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });


// *** DEFEND PLANS ***
   // SPLIT AMOUNTS
      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 2;
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 2;
      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2;
      int fourthLandUnitSplitAmount = gMaintainFourthLandUnitAmount / 2;
      int fifthLandUnitSplitAmount = gMaintainFifthLandUnitAmount / 2;
      int sixthLandUnitSplitAmount = gMaintainSixthLandUnitAmount / 2;
      int seventhLandUnitSplitAmount = gMaintainSeventhLandUnitAmount / 2;
      // int eighthLandUnitSplitAmount = gMaintainEighthLandUnitAmount / 2; Only one spot for Scorpion Men.
      // int ninthLandUnitSplitAmount = gMaintainNinthLandUnitAmount / 2; Only one spot for Phoenixes.


   // DEFINE THE PLANS

      // PLAN 1 (Leftmost)
      gDefensePlan1 = createDefendPlan("Defense Plan 1", kbBaseGetMainID(cMyID), 10, vector(99, 0, 329), 20);
      aiPlanSetVariableFloat(gDefensePlan1, cDefendPlanEngageRange, 0, 30);

      aiPlanAddUnitType(gDefensePlan1, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Slingers
      aiPlanAddUnitType(gDefensePlan1, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount); // Priests
      aiPlanAddUnitType(gDefensePlan1, gFifthLandUnit, 0, 0, fifthLandUnitSplitAmount); // Chariot Archers

      // PLAN 2 (Middle)
      gDefensePlan2 = createDefendPlan("Defense Plan 2", kbBaseGetMainID(cMyID), 10, vector(167, 1.0, 291), 10);
      aiPlanSetVariableFloat(gDefensePlan2, cDefendPlanEngageRange, 0, 30);

      aiPlanAddUnitType(gDefensePlan2, gSixthLandUnit, 0, 0, sixthLandUnitSplitAmount); // Siege Towers
      aiPlanAddUnitType(gDefensePlan2, gSeventhLandUnit, 0, 0, seventhLandUnitSplitAmount); // Camel Riders
      aiPlanAddUnitType(gDefensePlan2, gEighthLandUnit, 0, 0, 200); // Scorpion Men

      // PLAN 3 (Rightmost)
      gDefensePlan3 = createDefendPlan("Defense Plan 3", kbBaseGetMainID(cMyID), 10, vector(209.0, 1.0, 271.0), 10);
      aiPlanSetVariableFloat(gDefensePlan3, cDefendPlanEngageRange, 0, 30);

      aiPlanAddUnitType(gDefensePlan3, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Sphinxes
      aiPlanAddUnitType(gDefensePlan3, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Spearmen
      aiPlanAddUnitType(gDefensePlan3, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Slingers
      aiPlanAddUnitType(gDefensePlan3, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount); // Priests
      aiPlanAddUnitType(gDefensePlan3, gFifthLandUnit, 0, 0, fifthLandUnitSplitAmount); // Chariot Archers
      aiPlanAddUnitType(gDefensePlan3, gNinthLandUnit, 0, 0, 200); // Phoenixes

      // PLAN 4 (In front of gate)
      gDefensePlan4 = createDefendPlan("Defense Plan 4", kbBaseGetMainID(cMyID), 10, vector(137.0, 1.0, 269.0), 20);
      aiPlanSetVariableFloat(gDefensePlan4, cDefendPlanEngageRange, 0, 30);

      aiPlanAddUnitType(gDefensePlan4, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Sphinxes
      aiPlanAddUnitType(gDefensePlan4, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount); // Spearmen
      aiPlanAddUnitType(gDefensePlan4, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount); // Siege Towers
      aiPlanAddUnitType(gDefensePlan4, gFifthLandUnit, 0, 0, fifthLandUnitSplitAmount); // Camels

      // Build Walls to guard Arkantos' route on Moderate and up.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         xsEnableRuleGroup("ruleGroupWall");
      }
      // Use Prosperity on Hard and Titan.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         xsEnableRule("useProsperity");
      }

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      static bool needResearchHeroic = true;
      static bool needResearchMythic = true;
      static bool age3UnitsActive = false;

      static bool reachedHeroic = false;
      static bool reachedMythic = false;

      int age = kbPlayerGetAge(cMyID);
      int time = xsGetTime();

      if (done == false)
      {
         // We're already in Heroic on non-Easy difficulties.
         if (cDifficultyCurrent == cDifficultyEasy)
         {
            if (needResearchHeroic == true && age < cAge3 && time >= gHeroicAgeUpTime)
            {
               if (researchSimpleTech(cTechHeroicAgeNephthys, cUnitTypeCitadelCenter, -1, 60) == true)
               {
                  debugAttackWave("Starting Heroic Age research plan.");
                  needResearchHeroic = false;
               }
            }
         }

         if (age >= cAge3 && age3UnitsActive == false)
         {
            age3UnitsActive = true;

            // Maintain Heroic Age units.
            data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Priests
            data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);   // Chariot Archers
            data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);   // Camel Riders
            // No extra Scorpion Men or Siege Towers on Easy.
            if (cDifficultyCurrent >= cDifficultyModerate)
            {
               data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);   // Siege Towers
               data.addUnitToMaintain(gEighthLandUnit, gMaintainEighthLandUnitAmount);   // Scorpion Men
            }

            data.setTrainDelay(gFourthLandUnit, gTrainDelayHeroic);
            data.setTrainDelay(gFifthLandUnit, gTrainDelayHeroic);
            data.setTrainDelay(gSeventhLandUnit, gTrainDelayHeroic);
            // No extra Scorpion Men or Siege Towers on Easy.
            if (cDifficultyCurrent >= cDifficultyModerate)
            {
               data.setTrainDelay(gSixthLandUnit, gTrainDelayHeroic);
               data.setTrainDelay(gEighthLandUnit, gTrainDelayHeroic);
            }

            // gAttackWave.addAttackUnitType(gFourthLandUnit);
            gAttackWave.addAttackUnitType(gFifthLandUnit);
            // No Siege Towers until later.
            gAttackWave.addAttackUnitType(gSeventhLandUnit);
            // No extra Scorpion Men on Easy.
            if (cDifficultyCurrent >= cDifficultyModerate)
            {
               gAttackWave.addAttackUnitType(gEighthLandUnit);
            }

            gSecondAttackWave.addAttackUnitType(gFourthLandUnit);
            gSecondAttackWave.addAttackUnitType(gFifthLandUnit);
            // No Siege Towers until later.
            gSecondAttackWave.addAttackUnitType(gSeventhLandUnit);
            // No extra Scorpion Men on Easy.
            if (cDifficultyCurrent >= cDifficultyModerate)
            {
               gSecondAttackWave.addAttackUnitType(gEighthLandUnit);
            }

            // Update attack size parameters based on the enlarged army composition.
            gAttackMaxSize *= 1.20; // Attack size increases by +20%
            gAttackWave.setMaxAttackSize(gAttackMaxSize);

            // Train more Villagers to support the larger army.
            gMaxVillagerCount *= 1.40; // Train +40% more Villagers.
            gOverrideMaxVillagerPop = gMaxVillagerCount;

            // Enable God Power
            xsEnableRule("useAncestors");
         }

         if (needResearchMythic == true && age < cAge4 && time >= gMythicAgeUpTime)
         {
            if (researchSimpleTech(cTechMythicAgeThoth, cUnitTypeCitadelCenter, -1, 60) == true)
            {
               debugAttackWave("Starting Mythic Age research plan.");
               needResearchMythic = false;
            }
         }

         if (age >= cAge4 && age3UnitsActive == true)
         {
            // Make Phoenixes except on Easy.
            if (cDifficultyCurrent >= cDifficultyModerate)
            {
               data.addUnitToMaintain(gNinthLandUnit, gMaintainNinthLandUnitAmount); // Phoenixes
               gAttackWave.addAttackUnitType(gNinthLandUnit);
               gSecondAttackWave.addAttackUnitType(gNinthLandUnit);
               // Update attack size parameters based on the enlarged army composition.
               gAttackMaxSize *= 1.05; // Attack size increases by +5%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);
            }
            done = true;
         }
      }

      // Wait for Siege Towers until 15 minutes in.
      static bool siege_towers = false;
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         if (time >= 900 && cDifficultyCurrent != cDifficultyTitan)
         {
            if (siege_towers == false)
            {
               gAttackWave.addAttackUnitType(gSixthLandUnit);
               gSecondAttackWave.addAttackUnitType(gSixthLandUnit);
               gAttackMaxSize *= 1.05; // Attack size increases by +5%
               gAttackWaveInterval *= 1.5; // Attacks are dispatched slower now that we use siege.
               gSecondAttackWaveInterval *= 1.5; // Attacks are dispatched slower now that we use siege.
               gAttackWave.setAttackInterval(gAttackWaveInterval);
               gSecondAttackWave.setAttackInterval(gSecondAttackWaveInterval);
               siege_towers = true;
            }
         }
         // Siege Towers join sooner on Titan.
         if (time >= 640 && cDifficultyCurrent == cDifficultyTitan)
         {
            if (siege_towers == false)
            {
               gAttackWave.addAttackUnitType(gSixthLandUnit);
               gSecondAttackWave.addAttackUnitType(gSixthLandUnit);
               gAttackMaxSize *= 1.05; // Attack size increases by +5%
               gAttackWaveInterval *= 1.25; // Attacks are dispatched slower now that we use siege. (but not too much slower)
               gSecondAttackWaveInterval *= 1.25; // Attacks are dispatched slower now that we use siege. (but not too much slower)
               gAttackWave.setAttackInterval(gAttackWaveInterval);
               gSecondAttackWave.setAttackInterval(gSecondAttackWaveInterval);
               siege_towers = true;
            }
         }
      }
      // * * * TECH RULES * * * //

      static bool classical_techs = false;
      if (classical_techs == false)
      {
         // CLASSICAL AGE //

            // Techs for all difficulties:
               xsEnableRule("researchMediumSpearmen");
               xsEnableRule("researchMediumSlingers");
               xsEnableRule("researchPlow");

            // Techs for Easy only:
            if (cDifficultyCurrent == cDifficultyEasy)
            {
               xsEnableRule("researchMediumSpearmen");
               xsEnableRule("researchMediumSlingers");
            }
            // Techs for Easy and Moderate only:
            if (cDifficultyCurrent <= cDifficultyModerate)
            {
               xsEnableRule("researchCrenellations");
               xsEnableRule("researchMasons");
            }

            // Tech Rules for Moderate and Up:
            if (cDifficultyCurrent >= cDifficultyModerate)
            {
               xsEnableRule("researchCriosphinx");
            }

            // Tech Rules for Hard and Titan:
            if (cDifficultyCurrent >= cDifficultyHard)
            {
               xsEnableRule("researchHieracosphinx");
            }
            // Tech Rules for Titan only:
            classical_techs = true;
      }

      // HEROIC AGE //
      if (reachedHeroic == false && kbPlayerGetAge(cMyID) == cAge3)
      {
         // Tech Rules for All Difficulties:
            xsEnableRule("researchBronzeWeapons");
            xsEnableRule("researchBronzeArmor");
            xsEnableRule("researchBronzeShields");
            xsEnableRule("researchHeavySpearmen");
            xsEnableRule("researchHeavySlingers");
            xsEnableRule("researchBowSaw");
            xsEnableRule("researchShaftMine");
            xsEnableRule("researchIrrigation");
         // Techs for Moderate only:
         if (cDifficultyCurrent == cDifficultyModerate)
         {
            xsEnableRule("researchBoilingOil");
         }
         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchHeavyChariotArchers");
            xsEnableRule("researchHeavyCamelRiders");
            xsEnableRule("researchBallistics");
            // Guard Tower already researched on Titan.
            if (cDifficultyCurrent != cDifficultyTitan)
            {
               xsEnableRule("researchGuardTower");
            }
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchFuneralRites");
            xsEnableRule("researchNebty");
         }

         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchDraftHorses");
            xsEnableRule("researchArchitects");
         }

         // Change the boolean back to true so the rules aren't enabled multiple times.
         reachedHeroic = true;
      }

      // MYTHIC AGE //
      if (reachedMythic == false && kbPlayerGetAge(cMyID) == cAge4)
      {
         // Tech Rules for All Difficulties:
         xsEnableRule("researchFloodControl");
         xsEnableRule("researchQuarry");
         xsEnableRule("researchCarpenters");

         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchChampionSlingers");
            xsEnableRule("researchChampionSpearmen");
            xsEnableRule("researchBurningPitch");
         }
         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchIronArmor");
            xsEnableRule("researchIronShields");
            xsEnableRule("researchBallistaTower");
            xsEnableRule("researchCitadelWall");
            xsEnableRule("researchChampionCamelRiders");
            xsEnableRule("researchEngineers");
            xsEnableRule("researchConscriptBarracksSoldiers");
            xsEnableRule("researchConscriptMigdolSoldiers");
         }
         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchChampionChariotArchers");
         }
         // Change the boolean back to true so the rules aren't enabled multiple times.
         reachedMythic = true;
      }

      gAttackWave.update();
      gSecondAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}


// Set up the strategy.
void fott20StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(206.00, 0.00, 357.00), 111);

   setOverrideStrategy(fott20StrategySetup);

   // gOverrideFarmCount = 15; // Don't overdo the Farms.
   gRBDSystem.setMaxFarmsPerBase(32);
   gRBDSystem.setMaxFarmsPerIteration(32);
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, vector(136.0, 0.0, 325.0), 15.0); // Our TC.
      kbBuildingPlacementAddPositionInfluence(bpID, vector(136.0, 0.0, 325.0), 100.0, 15.0, cFalloffLinear); // Our TC.
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
void postInit()
{
}

rule useEclipse
inactive
minInterval 45
{
   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   int unitID = -1;
   for (int i = 0; i < attackPlans.size(); i++)
   {
      if (aiPlanGetParentID(attackPlans[i]) == -1)
      {
         // We just take the first unit to scan from.
         unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
         if (unitID >= 0)
         {
            if (aiCastGodPowerAtPosition(cProtoPowerEclipse, kbUnitGetPosition(unitID)) == true)
            {
               debugAttackWave("Casted Eclipse!");
               xsDisableRule("useEclipse");
            }
         }
      }
   }
}

// Use Ancestors while attacking
rule useAncestors
inactive
minInterval 5
{
   // Only initial delay is 8 minutes, after that go to regular interval.
   xsSetRuleMinIntervalSelf(10);
   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   int unitID = -1;
   int numEnemies = -1;

   // Only invoke this after 12 minutes.
   int current_time_2 = xsGetTime();
   if (current_time_2 >= 480)
   {
      for (int i = 0; i < attackPlans.size(); i++)
      {
         if (aiPlanGetParentID(attackPlans[i]) == -1)
         {
            // We just take the first unit to scan from.
            unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
            if (unitID >= 0)
            {
               numEnemies = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 10.0);
               debugAttackWave("numEnemies for casting Ancestors offensively: " + numEnemies);
               if (numEnemies >= 5)
               {
                  if (aiCastGodPowerAtPosition(cProtoPowerAncestors, kbUnitGetPosition(unitID)) == true)
                  {
                     debugAttackWave("Casted Ancestors!");
                     xsDisableRule("useAncestors");
                     return;
                  }
               }
            }
         }
      }
   }
}

void focusPyramidDefense()
{
   aiPlanSetVariableVector(gDefensePlan2, cDefendPlanGatherPoint, 0, vector(181.50, 4.80, 297.0));
   aiPlanSetVariableFloat(gDefensePlan2, cDefendPlanGatherDistance, 0, 50.0);
   aiPlanSetVariableFloat(gDefensePlan2, cDefendPlanEngageRange, 0, 30.0);
   aiPlanSetPriority(gDefensePlan2, 100);

   aiPlanSetVariableVector(gDefensePlan4, cDefendPlanGatherPoint, 0, vector(181.50, 4.80, 297.0));
   aiPlanSetVariableFloat(gDefensePlan4, cDefendPlanGatherDistance, 0, 50.0);
   aiPlanSetVariableFloat(gDefensePlan4, cDefendPlanEngageRange, 0, 30.0);
   aiPlanSetPriority(gDefensePlan4, 100);
}

// Eastern Wall

rule buildWall
inactive
minInterval 120
group ruleGroupWall
{
   gWallBuildPlan = aiPlanCreate("Wall Plan", cPlanBuildWall);
   aiPlanSetVariableInt(gWallBuildPlan, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeStraight);
   aiPlanAddUnitType(gWallBuildPlan, cUnitTypeAbstractVillager, 0, 1, 1);
   aiPlanSetVariableVector(gWallBuildPlan, cBuildWallPlanWallStart, 0, vector(321.39, 8.91, 178.66));
   aiPlanSetVariableVector(gWallBuildPlan, cBuildWallPlanWallEnd, 0, vector(352.47, 9.47, 184.29));
   aiPlanSetVariableInt(gWallBuildPlan, cBuildWallPlanNumberOfGates, 0, 0);
   aiPlanSetPriority(gWallBuildPlan, 99);
   aiPlanSetEventHandler(gWallBuildPlan, cPlanEventStateChange, "wallBuildPlanEventHandler");

   xsDisableRule("buildWall");
}

rule wallDefenders
inactive
minInterval 120
group ruleGroupWall
{
   int secondLandUnitDefendAmount = selectByDifficulty(2, 2, 3, 4, 4, 4);
   int thirdLandUnitDefendAmount = selectByDifficulty(0, 1, 2, 3, 3, 3);
   int fourthLandUnitDefendAmount = selectByDifficulty(0, 0, 1, 1, 1, 1);
   int fifthLandUnitDefendAmount = selectByDifficulty(2, 3, 4, 5, 5, 5);
   gWallDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 20.0, vector(333.00, 8.00, 190.00), 20);
   aiPlanSetVariableFloat(gWallDefendPlan, cDefendPlanEngageRange, 0, 30.0);
   aiPlanAddUnitType(gWallDefendPlan, gSecondLandUnit, 0, secondLandUnitDefendAmount, secondLandUnitDefendAmount);   // Spearmen
   aiPlanAddUnitType(gWallDefendPlan, gThirdLandUnit, 0, thirdLandUnitDefendAmount, thirdLandUnitDefendAmount);   // Slingers
   aiPlanAddUnitType(gWallDefendPlan, gFourthLandUnit, 0, fourthLandUnitDefendAmount, fourthLandUnitDefendAmount);   // Priests
   aiPlanAddUnitType(gWallDefendPlan, gFifthLandUnit, 0, fifthLandUnitDefendAmount, fifthLandUnitDefendAmount);   // Chariot Archers

   xsDisableRule("wallDefenders");
}

void wallBuildPlanEventHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateDone || state == cPlanStateFailed) // We're done or it failed, whatever just end the defend plan.
   {
      debugAttackWave("Our wall build plan is done, destroying our accompanying defend plan.");
      if (gWallDefendPlan != -1)
      {
         aiPlanDestroy(gWallDefendPlan);
      }
   }
}

// * * * * * * * * * * * * * * * * * * * * * * * * //
//                 BUILDING RULES                  //
// * * * * * * * * * * * * * * * * * * * * * * * * //

void buildBuilding(int type = cUnitTypeManor, vector location = cInvalidVector)
{
   int builder = cUnitTypeAbstractVillager;
   int buildPlanID = aiPlanCreate("Build Plan", cPlanBuild, -1);
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID));
   kbBuildingPlacementSetBuildingPUID(bpID, type);
   kbBuildingPlacementSetCenterPosition(bpID, location, 10.0);
   kbBuildingPlacementSetStepSize(bpID, 1.0);
   kbBuildingPlacementSetBufferSpace(bpID, 0.0);
   kbBuildingPlacementAddPositionInfluence(bpID, location, 100.0, 50.0, cFalloffLinear);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, type);
   aiPlanAddUnitType(buildPlanID, builder, 1, 1, 1, false);
   aiPlanSetPriority(buildPlanID, 90);
}

// *** TECH RULES *** //
   // CLASSICAL AGE
      // ALL DIFFICULTIES:
         // Plow
            rule researchPlow
            inactive
            minInterval 30
            {
               debugAttackWave("Starting Plow research plan.");
               researchSimpleTech(cTechPlow, cUnitTypeGranary, -1, 60);
               xsDisableRule("researchPlow");
            }
      // EASY ONLY:
         // Medium Spearmen
            rule researchMediumSpearmen
            inactive
            minInterval 720
            {
               debugAttackWave("Starting Medium Spearmen research plan.");
               researchSimpleTech(cTechMediumSpearmen, cUnitTypeBarracks, -1, 60);
               xsDisableRule("researchMediumSpearmen");
            }
         // Medium Slingers
            rule researchMediumSlingers
            inactive
            minInterval 720
            {
               debugAttackWave("Starting Medium Slingers research plan.");
               researchSimpleTech(cTechMediumSlingers, cUnitTypeBarracks, -1, 60);
               xsDisableRule("researchMediumSlingers");
            }
      // EASY AND MODERATE ONLY:
         // Crenellations
            rule researchCrenellations
            inactive
            minInterval 800
            {
               debugAttackWave("Starting Crenellations research plan.");
               researchSimpleTech(cTechCrenellations, cUnitTypeSentryTower, -1, 60);
               xsDisableRule("researchCrenellations");
            }
         // Masons
            rule researchMasons
            inactive
            minInterval 600
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
   // MODERATE AND UP:
      // Criosphinx
         rule researchCriosphinx
         inactive
         minInterval 360
         {
            debugAttackWave("Starting Criosphinx research plan.");
            researchSimpleTech(cTechCriosphinx, cUnitTypeTemple, -1, 60);
            xsDisableRule("researchCriosphinx");
         }
   // HARD AND UP:
      // Hieracosphinx
         rule researchHieracosphinx
         inactive
         minInterval 600
         {
            xsSetRuleMinIntervalSelf(10);
            if (kbTechGetStatus(cTechCriosphinx) == cTechStatusActive)
            {
               debugAttackWave("Starting Hieracosphinx research plan.");
               researchSimpleTech(cTechHieracosphinx, cUnitTypeTemple, -1, 60);
               xsDisableRule("researchHieracosphinx");
            }
         }

   // HEROIC AGE
      // ALL DIFFICULTIES
         // Bronze Weapons
            rule researchBronzeWeapons
            inactive
            minInterval 460
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
         // Bronze Armor
            rule researchBronzeArmor
            inactive
            minInterval 550
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
            minInterval 620
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
         // Heavy Spearmen
            rule researchHeavySpearmen
            active
            minInterval 30
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
         // Heavy Slingers
            rule researchHeavySlingers
            inactive
            minInterval 30
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
         // Irrigation
            rule researchIrrigation
            inactive
            minInterval 30
            {
               xsSetRuleMinIntervalSelf(10);
               if (kbTechGetStatus(cTechPlow) == cTechStatusActive)
               {
                  debugAttackWave("Starting Irrigation research plan.");
                  researchSimpleTech(cTechIrrigation, cUnitTypeGranary, -1, 60);
                  xsDisableRule("researchIrrigation");
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
                  debugAttackWave("Starting Shaft Mine research plan.");
                  researchSimpleTech(cTechShaftMine, cUnitTypeMiningCamp, -1, 60);
                  return;
               }
            }
      // MODERATE AND UP:
         // Ballistics
            rule researchBallistics
            inactive
            minInterval 250
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
         // Heavy Chariot Archers
            rule researchHeavyChariotArchers
            inactive
            minInterval 320
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
         // Heavy Camel Riders
            rule researchHeavyCamelRiders
            inactive
            minInterval 440
            {
               debugAttackWave("Starting Heavy Camel Riders research plan.");
               researchSimpleTech(cTechHeavyCamelRiders, cUnitTypeMigdolStronghold, -1, 60);
               xsDisableRule("researchHeavyCamelRiders");
            }
         // Boiling Oil
            rule researchBoilingOil
            inactive
            minInterval 720
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
         // Guard Tower (Not on Titan)
            rule researchGuardTower
            inactive
            minInterval 500
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
      // HARD AND UP:
         // Funeral Rites
            rule researchFuneralRites
            inactive
            minInterval 140
            {
               debugAttackWave("Starting Funeral Rites research plan.");
               researchSimpleTech(cTechFuneralRites, cUnitTypeTemple, -1, 60);
               xsDisableRule("researchFuneralRites");
            }
         // Nebty
            rule researchNebty
            inactive
            minInterval 480
            {
               debugAttackWave("Starting Nebty research plan.");
               researchSimpleTech(cTechNebty, cUnitTypeTemple, -1, 60);
               xsDisableRule("researchNebty");
            }
      // TITAN ONLY:
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
         // Draft Horses
            rule researchDraftHorses
            inactive
            minInterval 1080
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

   // MYTHIC AGE
      // ALL DIFFICULTIES:
         // Flood Control
            rule researchFloodControl
            inactive
            minInterval 30
            {
               xsSetRuleMinIntervalSelf(10);
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
            minInterval 30
            {
               xsSetRuleMinIntervalSelf(10);
               if (kbTechGetStatus(cTechBowSaw) == cTechStatusActive)
               {
                  debugAttackWave("Starting Carpenters research plan.");
                  researchSimpleTech(cTechCarpenters, cUnitTypeLumberCamp, -1, 60);
                  xsDisableRule("researchCarpenters");
               }
            }
         // Quarry
            rule researchQuarry
            inactive
            minInterval 30
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
                  researchSimpleTech(cTechQuarry, cUnitTypeStorehouse, -1, 60);
                  return;
               }
            }
      // MODERATE AND UP:
         // Iron Weapons
            rule researchIronWeapons
            inactive
            minInterval 120
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
         // Champion Spearmen
            rule researchChampionSpearmen
            inactive
            minInterval 120
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
         // Champion Slingers
            rule researchChampionSlingers
            inactive
            minInterval 120
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionSlingers) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionSlingers");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionSlingers) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Slingers research plan.");
                  researchSimpleTech(cTechChampionSlingers, cUnitTypeBarracks, -1, 60);
                  return;
               }
            }
         // Burning Pitch
            rule researchBurningPitch
            inactive
            minInterval 360
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
      // HARD AND UP:
         // Iron Armor
            rule researchIronArmor
            inactive
            minInterval 180
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
         // Iron Shields
            rule researchIronShields
            inactive
            minInterval 240
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
         // Champion Camel Riders
            rule researchChampionCamelRiders
            inactive
            minInterval 300
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechHeavyCamelRiders) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionCamelRiders");
                  return;
               }
               else if (kbTechGetStatus(cTechHeavyCamelRiders) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Camel Riders research plan.");
                  researchSimpleTech(cTechHeavyCamelRiders, cUnitTypeMigdolStronghold, -1, 60);
                  return;
               }
            }
         // Ballista Tower
            rule researchBallistaTower
            inactive
            minInterval 300
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
         // Citadel Wall
            rule researchCitadelWall
            inactive
            minInterval 60
            {
               xsSetRuleMinIntervalSelf(10);
               if (kbTechGetStatus(cTechFortifiedWall) == cTechStatusActive)
               {
                  debugAttackWave("Starting CitadelWall research plan.");
                  researchSimpleTech(cTechCitadelWall, cUnitTypeWallConnector, -1, 60);
                  xsDisableRule("researchCitadelWall");
               }
            }
         // Engineers
            rule researchEngineers
            inactive
            minInterval 600
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechEngineers) == cTechStatusActive)
               {
                  xsDisableRule("researchEngineers");
                  return;
               }
               else if (kbTechGetStatus(cTechEngineers) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Engineers research plan.");
                  researchSimpleTech(cTechEngineers, cUnitTypeSiegeWorks, -1, 60);
                  return;
               }
            }

         // Conscript Barracks Soldiers
            rule researchConscriptBarracksSoldiers
            inactive
            minInterval 10
            {
               xsSetRuleMinIntervalSelf(10);
               if (kbTechGetStatus(cTechLevyBarracksSoldiers) == cTechStatusActive)
               {
                  debugAttackWave("Starting Conscript Barracks Soldiers research plan.");
                  researchSimpleTech(cTechConscriptBarracksSoldiers, cUnitTypeBarracks, -1, 60);
                  xsDisableRule("researchConscriptBarracksSoldiers");
               }
            }
         // Conscript Migdol Soldiers
            rule researchConscriptMigdolSoldiers
            inactive
            minInterval 10
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechConscriptMigdolSoldiers) == cTechStatusActive)
               {
                  xsDisableRule("researchConscriptMigdolSoldiers");
                  return;
               }
               else if (kbTechGetStatus(cTechConscriptMigdolSoldiers) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Conscript Migdol Soldiers research plan.");
                  researchSimpleTech(cTechConscriptMigdolSoldiers, cUnitTypeMigdolStronghold, -1, 60);
                  return;
               }
            }
      // TITAN ONLY:
         // Champion Chariot Archers
            rule researchChampionChariotArchers
            inactive
            minInterval 300
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

// *** GOD POWER RULES ***
   // Prosperity (#1)
      rule useProsperity
      inactive
      minInterval 300
      {
         if (aiCastGodPowerAtPosition(cProtoPowerProsperity, vector(131.0, 0.0, 317.0)) == true)
         {
            debugAttackWave("Casted Prosperity!");
            xsDisableRule("useProsperity");
            xsEnableRule("useProsperityAgain");
            xsEnableRule("stopProsperity");
            return;
         }
      }
   // Prosperity (#2)
      rule useProsperityAgain
      inactive
      minInterval 360
      {
         if (aiCastGodPowerAtPosition(cProtoPowerProsperity, vector(131.0, 0.0, 317.0)) == true)
         {
            debugAttackWave("Casted Prosperity!");
            return;
         }
      }

   // Stop Prosperity
   rule stopProsperity
   inactive
   minInterval 10
   {
      int tc_alive = getUnitCountByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, vector(173.0, 0.0, 340.15), 5.0);
      int citadel_alive = getUnitCountByLocation(cUnitTypeCitadelCenter, cMyID, cUnitStateAlive, vector(130.5, 0.0, 322.56), 5.0);

      if (tc_alive == 0 && citadel_alive == 0)
      {
         xsDisableRule("useProsperityAgain");
         return;
      }      
   }

   // Meteor
      // Wait to use Meteor until 5 minutes after Arkantos arrives (activated by triggers; Hard and Titan only)
      void waitForMeteor()
      {
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("useMeteor");
         }
         xsDisableRule("waitForMeteor"); // Disable self.
         return;
      }
      rule useMeteor
      inactive
      minInterval 480
      {
         // Use Meteor only if Arkantos has stuff by his spawn location.
            vector arkantos_tc = vector(313.0, 0.0, 97.0);
            int numEnemyBuildings = -1;
            int numEnemyMilitary = -1;
            int numEnemyCitizens = -1;
            int totalEnemies = 0;

            numEnemyBuildings = getUnitCountByLocation(cUnitTypeBuilding, 1, cUnitStateAlive, arkantos_tc, 30.0);
            numEnemyMilitary = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, 1, cUnitStateAlive, arkantos_tc, 30.0);
            numEnemyCitizens = getUnitCountByLocation(cUnitTypeAbstractVillager, 1, cUnitStateAlive, arkantos_tc, 30);

            numEnemyBuildings *= 5; // Only 1 building needed to convince them to use Meteor.
            numEnemyCitizens *= 5; // Only 1 Citizen needed to convince them to use Meteor.

            totalEnemies += numEnemyBuildings;
            totalEnemies += numEnemyMilitary;
            totalEnemies += numEnemyCitizens;

            debugAttackWave("numResults for updating our attack route: " + totalEnemies);
            if (totalEnemies >= 5)
            {
               // We found out that player 1 is hanging out at the TC area - let's use Meteor.
               if (aiCastGodPowerAtPosition(cProtoPowerMeteor, vector(313.0, 0.0, 97.0)) == true)
               {
                  debugAttackWave("Casted Meteor!");
                  xsDisableRule("useMeteor");
                  return;
               }
            }
      }