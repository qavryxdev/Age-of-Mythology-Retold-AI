//==============================================================================
/* fott23_p2.xs

   Red Norse player owning a base that spans most of the cave. Attacks with a
   mix of Trolls, Mountain Giants, Fire Giants, Hirdmen,
   Attacks with Hypaspists, Hippeis, Toxotes, and Petroboli. Has some static
   Hoplites.
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
int gFirstLandUnit = cUnitTypeHirdman; // Trained from the beginning, but not on Easy.
float gMaintainFirstLandUnitAmount = 5;
int gSecondLandUnit = cUnitTypeThrowingAxeman; // Trained from the beginning, but not on Easy.
float gMaintainSecondLandUnitAmount = 5;
int gThirdLandUnit = cUnitTypeHuskarl; // Trained from the beginning, but not on Easy.
float gMaintainThirdLandUnitAmount = 5;
int gFourthLandUnit = cUnitTypeTroll; // Trained from the beginning.
float gMaintainFourthLandUnitAmount = 3;
int gFifthLandUnit = cUnitTypeMountainGiant; // Trained beginning in Heroic.
float gMaintainFifthLandUnitAmount = 1;
int gSixthLandUnit = cUnitTypeFireGiant; // Trained beginning in Mythic.
float gMaintainSixthLandUnitAmount = 2;
int gSeventhLandUnit = cUnitTypeBallista; // Trained beginning in Mythic.
float gMaintainSeventhLandUnitAmount = 2;

float gMaxVillagerCount = 0;

float gAttackStartDelay = 240; // In seconds.
float gAttackWaveInterval = 360; // In seconds.

float gAttackStartSize = 7;
float gAttackMaxSize = 15;

bool gStopRegularProduction = false;


// Age Up time is dramatically different depending on the difficulty.
float gHeroicAgeUpTime = -1; // Depends on difficulty.
float gMythicAgeUpTime = -1; // Depends on difficulty.

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;
      int gDefendPlan3 = -1;

Strategy scenarioAttackWaveStrategy()
{
   // This should never fail.
   xsEnableRule("invokeWalkingWoods");

   int explorePlanID = aiPlanCreate("Berserk Explore", cPlanExplore, -1);
   aiPlanSetPriority(explorePlanID, 99);
   aiPlanAddUnitType(explorePlanID, cUnitTypeBerserk, 1, 1, 1);

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
         gAttackStartSize = 2;
         gAttackMaxSize = 3; // Decreasing from 15, we don't maintain that many units on this difficulty level.
         gAttackWaveInterval = 600; // Rarely attack.
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
      gTrainDelay *= gDifficultyModifierTrainDelay;

      // Age up times are manually decided because the time difference was so drastic in legacy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gHeroicAgeUpTime = 1200; // 20 minutes, in seconds.
         gMythicAgeUpTime = 2400; // 40 minutes, in seconds.
      }
      else if (cDifficultyCurrent == cDifficultyModerate)
      {
         gHeroicAgeUpTime = 720; // 12 minutes, in seconds.
         gMythicAgeUpTime = 1800; // 1800 seconds
      }
      else if (cDifficultyCurrent == cDifficultyHard)
      {
         gHeroicAgeUpTime = 240; // 4 minutes, in seconds.
         gMythicAgeUpTime = 1400; // 1400 seconds
      }
      else if (cDifficultyCurrent >= cDifficultyTitan)
      {
         gHeroicAgeUpTime = 60; // 1 minute, in seconds.
         gMythicAgeUpTime = 1000; // 1000 seconds
      }

      gHeroicAgeUpTime += xsGetTime(); // Offset for awake moment.
      gMythicAgeUpTime += xsGetTime(); // Offset for awake moment.

      // Set units to maintain from the start of the game.

      // Hirdmen, Throwing Axemen and Berserks are not trained on Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
         data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
         data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      }

      // Trolls are newly produced all the time.
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      // Don't train Fire Giants until way later; those things are terrifying.

      data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         data.setTrainDelay(gFirstLandUnit, gTrainDelay);
         data.setTrainDelay(gSecondLandUnit, gTrainDelay);
         data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      }
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);
      data.setTrainDelay(gFifthLandUnit, gTrainDelay);
      data.setTrainDelay(gSeventhLandUnit, gTrainDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);

      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         gAttackWave.addAttackUnitType(gFirstLandUnit);
         gAttackWave.addAttackUnitType(gSecondLandUnit);
         gAttackWave.addAttackUnitType(gThirdLandUnit);
      }
      gAttackWave.addAttackUnitType(gFourthLandUnit);
      gAttackWave.addAttackUnitType(gFifthLandUnit);
      gAttackWave.addAttackUnitType(gSeventhLandUnit);
      gAttackWave.setAttackStartTime(gAttackStartDelay);

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // We want to research our military upgrades automatically.
      data.setFlag(cStrategyFlagAutoResearchMilitaryUpgrades, true);
      xsEnableRule("militaryUpgradeManager");

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(133.0, 0.0, 229.0); // In front of the Forge entrance.
      vector targetPoint = vector(133.0, 0.0, 20.33); // At the southeast Settlement.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Western cave entrance");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(187.0, 0.0, 141.0)); // Block #1
      kbPathAddWaypoint(pathID1, vector(111.0, 0.0, 131.0)); // Block #2
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Central cave entrance");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(187.0, 0.0, 141.0)); // Block #1
      kbPathAddWaypoint(pathID2, vector(162.0, 0.0, 90.0)); // Block #2
      kbPathAddWaypoint(pathID2, vector(129.0, 0.0, 90.0)); // Block #3
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      int pathID3 = kbPathCreate("Eastern cave entrance");
      kbPathAddWaypoint(pathID3, startPoint);
      kbPathAddWaypoint(pathID3, vector(187.0, 0.0, 141.0)); // Block #1
      kbPathAddWaypoint(pathID3, vector(277.0, 0.0, 141.0)); // Block #2
      kbPathAddWaypoint(pathID3, vector(257.0, 0.0, 67.0)); // Block #3
      kbPathAddWaypoint(pathID3, targetPoint);
      kbAttackRouteAddPath(routeID, pathID3);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

   // SPLIT AMOUNTS
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 2; // Throwing Axemen
      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2; // Huskarls

   // DEFINE THE PLANS
      // Plan 1 (Hirdmen, Trolls, Throwing Axemen)
      gDefendPlan1 = createDefendPlan("Defense Plan 1", kbBaseGetMainID(cMyID), 10, vector(121.0, 0.0, 299.0), 20);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan1, gFirstLandUnit, 0, 0, 200); // Hirdmen
      aiPlanAddUnitType(gDefendPlan1, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Throwing Axemen
      aiPlanAddUnitType(gDefendPlan1, gFourthLandUnit, 0, 0, 200); // Trolls

      // Plan 2 (Huskarls, Fire Giants, Ballistae)
      gDefendPlan2 = createDefendPlan("Defense Plan 2", kbBaseGetMainID(cMyID), 10, vector(263.0, 0.0, 267.0), 20);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan2, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Huskarls
      aiPlanAddUnitType(gDefendPlan2, gSixthLandUnit, 0, 0, 200); // Fire Giants
      aiPlanAddUnitType(gDefendPlan2, gSeventhLandUnit, 0, 0, 200); // Ballistae

      // Plan 3 (Throwing Axemen, Mountain Giants)
      gDefendPlan3 = createDefendPlan("Defense Plan 3", kbBaseGetMainID(cMyID), 10, vector(249.0, 0.0, 207.0), 20);
      aiPlanSetVariableFloat(gDefendPlan3, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan3, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Throwing Axemen
      aiPlanAddUnitType(gDefendPlan3, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Huskarls
      aiPlanAddUnitType(gDefendPlan3, gFifthLandUnit, 0, 0, 200); // Mountain Giants

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      int age = kbPlayerGetAge(cMyID);
      int time = xsGetTime();

      static bool no_more_training = false;

      // Age Up Rules
      if (age < cAge3 && time >= gHeroicAgeUpTime)
      {
         xsEnableRule("heroic");
      }
      if (age < cAge4 && time >= gMythicAgeUpTime)
      {
         xsEnableRule("mythic");
      }
      // New Tech Rules
      if (age >= cAge2)
      {
         // All Difficulties:

         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            researchSimpleTech(cTechCopperWeapons, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechMediumInfantry, cUnitTypeLonghouse, -1, 60);
            researchSimpleTech(cTechCrenellations, cUnitTypeSentryTower, -1, 60);
            researchSimpleTech(cTechMasons, cUnitTypeTownCenter, -1, 60);
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            researchSimpleTech(cTechCopperArmor, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechCopperShields, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechCaveTroll, cUnitTypeTemple, -1, 60);
         }

         // Titan Only:         
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            researchSimpleTech(cTechDwarvenBreastplate, cUnitTypeArmory, -1, 60);
         }

      }
      if (age >= cAge3)
      {
         // All Difficulties:

         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            researchSimpleTech(cTechDraftHorses, cUnitTypeHillFort, -1, 60);
            researchSimpleTech(cTechArchitects, cUnitTypeTownCenter, -1, 60);
            researchSimpleTech(cTechLevyLonghouseSoldiers, cUnitTypeLonghouse, -1, 60);
            researchSimpleTech(cTechLevyHillFortSoldiers, cUnitTypeHillFort, -1, 60);
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            researchSimpleTech(cTechHeavyInfantry, cUnitTypeLonghouse, -1, 60);
            researchSimpleTech(cTechBoilingOil, cUnitTypeSentryTower, -1, 60);
            researchSimpleTech(cTechBronzeWeapons, cUnitTypeArmory, -1, 60);
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 60);
            if (xsGetTime() >= 1200)
            {
               researchSimpleTech(cTechJotuns, cUnitTypeTemple, -1, 60);
            }
         }
      }
      if (age >= cAge4)
      {
         // All Difficulties:

         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            researchSimpleTech(cTechBurningPitch, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechConscriptLonghouseSoldiers, cUnitTypeLonghouse, -1, 60);
            researchSimpleTech(cTechConscriptHillFortSoldiers, cUnitTypeHillFort, -1, 60);
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            researchSimpleTech(cTechChampionInfantry, cUnitTypeLonghouse, -1, 60);
            researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechRampage, cUnitTypeTemple, -1, 60);
            // Don't get Granite Blood until way later into the mission.
            if (xsGetTime() >= 1800)
            {
               researchSimpleTech(cTechGraniteBlood, cUnitTypeTemple, -1, 60);
            }
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            if (xsGetTime() >= 1600)
            {
               researchSimpleTech(cTechIronArmor, cUnitTypeArmory, -1, 60);
               researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
            }
         }
      }

      // Train more Mountain Giants 810 seconds in, and not on Easy.
      static bool mountain_giant_increase_1 = false;
      if (mountain_giant_increase_1 == false && no_more_training == false)
      {
         if (cDifficultyCurrent >= cDifficultyModerate && time >= 810)
         {
            gMaintainFifthLandUnitAmount *= 2.00; // Train +100% Mountain Giants.
            data.adjustUnitToMaintainAmount(gFifthLandUnit, gMaintainFifthLandUnitAmount);
            gAttackMaxSize *= 1.05; // Increase attack size by +5%.
            mountain_giant_increase_1 = true;
         }
      }
      // Train more Mountain Giants 1500 seconds in, and not on Easy.
      static bool mountain_giant_increase_2 = false;
      if (mountain_giant_increase_2 == false && no_more_training == false)
      {
         if (cDifficultyCurrent >= cDifficultyModerate && time >= 1500)
         {
            gMaintainFifthLandUnitAmount *= 1.50; // Train +50% Mountain Giants.
            data.adjustUnitToMaintainAmount(gFifthLandUnit, gMaintainFifthLandUnitAmount);
            gAttackMaxSize *= 1.05; // Increase attack size by +5%.
            mountain_giant_increase_2 = true;
         }
      }

      // Only start making Fire Giants deep into the mission, and not on Easy.
      static bool fire_giants = false;
      if (fire_giants == false && no_more_training == false)
      {
         if (cDifficultyCurrent >= cDifficultyModerate && time >= 960)
         {
            data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
            data.setTrainDelay(gSixthLandUnit, gTrainDelay);
            gAttackWave.addAttackUnitType(gSixthLandUnit);
            gAttackMaxSize *= 1.10; // Increase attack size by +10%.
            fire_giants = true;
         }
      }

      if (gStopRegularProduction == true && no_more_training == false)
      {
         data.removeUnitToMaintain(gFirstLandUnit);
         data.removeUnitToMaintain(gSecondLandUnit);
         data.removeUnitToMaintain(gThirdLandUnit);
         data.removeUnitToMaintain(gFourthLandUnit);
         data.removeUnitToMaintain(gFifthLandUnit);
         data.removeUnitToMaintain(gSixthLandUnit);
         data.removeUnitToMaintain(gSeventhLandUnit);
         no_more_training = true;
      }

      gAttackWave.update();
      return cStrategyContinue;
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott23StrategySetup()
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
   setOverrideStrategy(fott23StrategySetup);

   gOverrideFarmCount = 0;
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
   researchSimpleTech(cTechHeroicAgeNjord, cUnitTypeTownCenter, -1, 75);
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
   researchSimpleTech(cTechMythicAgeHel, cUnitTypeTownCenter, -1, 75);
   int age = kbPlayerGetAge(cMyID);
   if (age >= cAge4)
   {
      xsDisableRule("mythic"); // Disables once age up is successful.
   }
}

rule invokeWalkingWoods
inactive 
minInterval 5
{
   vector treeBlock = vector(117.0, 0.00, 39.0);
   if(kbLocationVisible(treeBlock))
   {
      if (aiCastGodPowerAtPosition(cProtoPowerWalkingWoods, treeBlock) == true)
      {
         debugAttackWave("Casted Walking Woods!");
         xsDisableRule("invokeWalkingWoods");
      }
   }
}

rule endDefendPlan
inactive 
minInterval 5
{
   aiPlanDestroy(gDefendPlan1);
   aiPlanDestroy(gDefendPlan2);
   aiPlanDestroy(gDefendPlan3);
   xsDisableRule("endDefendPlan");

   gStopRegularProduction = true;
}