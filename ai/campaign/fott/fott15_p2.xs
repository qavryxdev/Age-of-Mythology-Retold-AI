//==============================================================================
/* fott15_p2.xs

   Red Egyptian player owning the large base. Sends naval attacks of Siege Ships and Leviathans,
   while defending key locations in its base.
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
mutable void updateDefendPlans() {}

float gTrainDelay = 0; // In seconds.
int gFirstLandUnit = cUnitTypeSpearman; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 10;
int gSecondLandUnit = cUnitTypeChariotArcher; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 8;
int gThirdLandUnit = cUnitTypeWadjet; // Begins training at 240 seconds.
float gMaintainThirdLandUnitAmount = 4;
int gFourthLandUnit = cUnitTypeScorpionMan; // Begins training at 240 seconds.
float gMaintainFourthLandUnitAmount = 4;
int gFifthLandUnit = cUnitTypePriest; // Gets trained from the start.
float gMaintainFifthLandUnitAmount = 6;

int gFirstNavalUnit = cUnitTypeWarBarge; // Gets trained from the start.
float gMaintainFirstNavalUnitAmount = 3;
int gSecondNavalUnit = cUnitTypeRammingGalley; // Gets trained from the start.
float gMaintainSecondNavalUnitAmount = 2;
int gThirdNavalUnit = cUnitTypeLeviathan; // Gets trained from the start, on Titan difficulty.
float gMaintainThirdNavalUnitAmount = 2;
int gFourthNavalUnit = cUnitTypeKebenit; // Gets trained from the start.
float gMaintainFourthNavalUnitAmount = 3;

float gMaxVillagerCount = 20;
float gMaxFishingShipCount = 3;
int gInitialTrainDelayWadjetScorpion = 240;

float gNavalAttackStartDelay = 360; // In seconds.
float gNavalAttackWaveInterval = 240; // In seconds.

float gNavalAttackStartSize = 4;
float gNavalAttackMaxSize = 8;
float gMythicAgeUpTime = 1500; // In seconds. (25 minutes)

/*
int gSpearDefendPlan = -1;
int gChariotDefendPlan = -1;
int gWadjetDefendPlan = -1;
int gScorpionDefendPlan = -1;
int gWaterDefendPlan = -1;
*/

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;
      int gDefendPlan3 = -1;
      int gDefendPlan4 = -1;
      int gDefendPlan5 = -1;

int gWakeUpTime = 0; // Set to the current in-game time when the AI is told to 'wake up', after Arkantos gets a base.

Strategy scenarioAttackWaveStrategy()
{
   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugAttackWave("***Starting Scenario Attack Wave Strategy***");
      xsEnableRule("enableSpearDefendPlan");

      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================
      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      // Don't apply the multiplier to the naval units.

      // Don't apply the multiplier to naval assaults on Moderate.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gNavalAttackWaveInterval *= gDifficultyModifierAttackInterval;
         gNavalAttackStartSize *= gDifficultyModifierAttackSizes;
         gNavalAttackMaxSize *= gDifficultyModifierAttackSizes;
      }
      
      gInitialTrainDelayWadjetScorpion += xsGetTime(); // Offset for awake moment.

      // Certain parameters are way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gMaintainFirstLandUnitAmount = 6; // 6 Spearmen
         gMaintainSecondLandUnitAmount = 3; // 3 Chariot Archers
         gMaintainThirdLandUnitAmount = 2; // 2 Wadjets
         gMaintainFourthLandUnitAmount = 1; // 1 Scorpion Man
         gMaintainFifthLandUnitAmount = 2; // 2 Priests

         gMaintainFirstNavalUnitAmount = 3; // 3 War Barges
         gMaintainSecondNavalUnitAmount = 2; // 2 Ramming Galleys
         gMaintainFourthNavalUnitAmount = 2; // 2 Kebenits

         gMythicAgeUpTime = 2100; // In seconds. (35 minutes)
      }

      // Naval attacks aren't too strong on Moderate.
      if (cDifficultyCurrent == cDifficultyModerate)
      {
         gNavalAttackStartSize = 3;
         gNavalAttackMaxSize = 5;
         // Apply the multiplier to the Train Delay.
         gTrainDelay = gDifficultyModifierTrainDelay;
      }

      // Set units to maintain from the start of the game.

      // These units are intended to be newly produced all the time.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      data.addUnitToMaintain(gFirstNavalUnit, gMaintainFirstNavalUnitAmount);
      data.addUnitToMaintain(gSecondNavalUnit, gMaintainSecondNavalUnitAmount);
      data.addUnitToMaintain(gFourthNavalUnit, gMaintainFourthNavalUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      if (cDifficultyCurrent <= cDifficultyModerate)
      {
         data.setTrainDelay(gFirstLandUnit, gTrainDelay);
         data.setTrainDelay(gSecondLandUnit, gTrainDelay);
         data.setTrainDelay(gFirstNavalUnit, gTrainDelay);
         data.setTrainDelay(gSecondNavalUnit, gTrainDelay);
      }

      // Details about the attack waves.

      // Naval attacks do not occur on Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         // Don't initiate the waves until Arkantos arrives at the TC.
         gNavalAttackWave.setName("gNavalAttackWave");
         gNavalAttackWave.setAttackStartTime(cWaitWithAttacking);
         gNavalAttackWave.setAttackInterval(gNavalAttackWaveInterval);
         gNavalAttackWave.setAttackSize(gNavalAttackStartSize);
         gNavalAttackWave.setMaxAttackSize(gNavalAttackMaxSize);
         gNavalAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
         gNavalAttackWave.addAttackUnitType(gFirstNavalUnit);
         gNavalAttackWave.addAttackUnitType(gThirdNavalUnit);
         gNavalAttackWave.setIsNavalAttackWave();
      }

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticFishing, true);

      /*
      gNavalAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(190.0, 2.0, 130.0); // Center of the main harbor.
      vector targetPoint = vector(99.0, 2.0, 235.0); // Shore of the base P1 inherits.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gNavalAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID = kbPathCreate("Path 1 - Attack P1 harbor");
      kbPathAddWaypoint(pathID, startPoint);
      kbPathAddWaypoint(pathID, vector(214.0, 2.0, 163.0)); // Exit our harbor.
      kbPathAddWaypoint(pathID, vector(183.0, 2.0, 217.0)); // Head towards P1.
      kbPathAddWaypoint(pathID, targetPoint);
      kbAttackRouteAddPath(routeID, pathID);

      gNavalAttackWave.setGatherPoint(startPoint);
      gNavalAttackWave.setTargetPoint(targetPoint);
      gNavalAttackWave.setAttackRouteID(routeID);
      gNavalAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );
      gNavalAttackWave.displayFirstAttackStats();
      */

      // DEFEND PLANS
      vector Defend_1 = vector(137.0, 0.0, 127.0); // In the west.
      vector Defend_2 = vector(127.0, 0.0, 85.0); // West of the west gate.
      vector Defend_3 = vector(187.0, 0.0, 67.0); // Next to the Pyramid.
      vector Defend_4 = vector(259.0, 0.0, 75.0); // Northeast of the Set Wonder.
      vector Defend_5 = vector(361.0, 0.0, 105.0); // In their northeastern area.

      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 3; // Spearmen
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 4; // Chariot Archers
      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 3; // Wadjets
      int fourthLandUnitSplitAmount = gMaintainFourthLandUnitAmount / 2; // Scorpion Men
      int fifthLandUnitSplitAmount = gMaintainFifthLandUnitAmount / 3; // Priests

      gDefendPlan1 = createDefendPlan("Defend Plan 1", kbBaseGetMainID(cMyID), 20.0, Defend_1, 10, Defend_1);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(gDefendPlan1, gFirstLandUnit, 0, 5, firstLandUnitSplitAmount); // Spearmen
      aiPlanAddUnitType(gDefendPlan1, gFifthLandUnit, 0, 5, fifthLandUnitSplitAmount); // Priests

      gDefendPlan2 = createDefendPlan("Defend Plan 2", kbBaseGetMainID(cMyID), 20.0, Defend_2, 10, Defend_2);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(gDefendPlan2, gSecondLandUnit, 0, 5, secondLandUnitSplitAmount); // Chariot Archers
      aiPlanAddUnitType(gDefendPlan2, gThirdLandUnit, 0, 5, thirdLandUnitSplitAmount); // Wadjets

      gDefendPlan3 = createDefendPlan("Defend Plan 3", kbBaseGetMainID(cMyID), 20.0, Defend_3, 10, Defend_3);
      aiPlanSetVariableFloat(gDefendPlan3, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(gDefendPlan3, gFirstLandUnit, 0, 5, firstLandUnitSplitAmount); // Spearmen
      aiPlanAddUnitType(gDefendPlan3, gSecondLandUnit, 0, 5, secondLandUnitSplitAmount); // Chariot Archers
      aiPlanAddUnitType(gDefendPlan3, gFourthLandUnit, 0, 5, fourthLandUnitSplitAmount); // Scorpion Men
      aiPlanAddUnitType(gDefendPlan3, gFifthLandUnit, 0, 5, fifthLandUnitSplitAmount); // Priests

      gDefendPlan4 = createDefendPlan("Defend Plan 4", kbBaseGetMainID(cMyID), 20.0, Defend_4, 10, Defend_4);
      aiPlanSetVariableFloat(gDefendPlan4, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(gDefendPlan4, gSecondLandUnit, 0, 5, secondLandUnitSplitAmount); // Chariot Archers
      aiPlanAddUnitType(gDefendPlan4, gThirdLandUnit, 0, 5, thirdLandUnitSplitAmount); // Wadjets

      gDefendPlan5 = createDefendPlan("Defend Plan 5", kbBaseGetMainID(cMyID), 20.0, Defend_5, 10, Defend_5);
      aiPlanSetVariableFloat(gDefendPlan5, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(gDefendPlan5, gFirstLandUnit, 0, 5, firstLandUnitSplitAmount); // Spearmen
      aiPlanAddUnitType(gDefendPlan5, gSecondLandUnit, 0, 5, secondLandUnitSplitAmount); // Chariot Archers
      aiPlanAddUnitType(gDefendPlan5, gThirdLandUnit, 0, 5, thirdLandUnitSplitAmount); // Wadjets
      aiPlanAddUnitType(gDefendPlan5, gFourthLandUnit, 0, 5, fourthLandUnitSplitAmount); // Scorpion Men
      aiPlanAddUnitType(gDefendPlan5, gFifthLandUnit, 0, 5, fifthLandUnitSplitAmount); // Priests

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool ageup = false;
      int age = kbPlayerGetAge(cMyID);
      int time = xsGetTime();

      if (ageup == false)
      {
         if (age < cAge4 && time >= gMythicAgeUpTime)
         {
            researchSimpleTech(cTechMythicAgeHorus, cUnitTypeTownCenter, -1, 75);
         }
         else if (age >= cAge4)
         {
            ageup = true;
         }
      }

      static bool reachedMythic = false;

      // MYTHIC AGE //
      if (age >= cAge4 && reachedMythic == false)
      {
         // Tech Rules for All Difficulties:
         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchBallistaTower");
            xsEnableRule("researchQuarry");
            xsEnableRule("researchFloodControl");
            xsEnableRule("researchCarpenters");
         }
         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchChampionSpearmen");
            xsEnableRule("researchChampionWarships");
            xsEnableRule("researchChampionChariotArchers");
            xsEnableRule("researchGreatestOfFifty");
         }
         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchIronArmor");
            xsEnableRule("researchIronShields");
            xsEnableRule("researchSpearOfHorus");
            xsEnableRule("researchConscriptSailors");
         }
         // Change the boolean back to false so the rules aren't enabled multiple times.
         reachedMythic = true;
      }

      // Start making more warships 15 minutes since waking up (Hard and Titan only).
      static bool army_buffed = false;

      if (army_buffed == false && time >= 900 + gWakeUpTime)
      {
         // Smaller increase on Hard.
         if (cDifficultyCurrent == cDifficultyHard)
         {
            gMaintainFirstNavalUnitAmount *= 1.50; // Train +50% War Barges.
            gMaintainSecondNavalUnitAmount *= 1.50; // Train +50% Ramming Galleys.
            gMaintainFourthNavalUnitAmount *= 1.50; // Train +50% Kebenits.

            data.adjustUnitToMaintainAmount(gFirstNavalUnit, gMaintainFirstNavalUnitAmount);
            data.adjustUnitToMaintainAmount(gSecondNavalUnit, gMaintainSecondNavalUnitAmount);
            data.adjustUnitToMaintainAmount(gFourthNavalUnit, gMaintainFourthNavalUnitAmount);
            army_buffed = true;
         }
         // Larger increase on Titan.
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            gMaintainFirstNavalUnitAmount *= 2.0; // Train +100% War Barges.
            gMaintainSecondNavalUnitAmount *= 2.0; // Train +100% Ramming Galleys.
            gMaintainFourthNavalUnitAmount *= 2.0; // Train +100% Kebenits.

            data.adjustUnitToMaintainAmount(gFirstNavalUnit, gMaintainFirstNavalUnitAmount);
            data.adjustUnitToMaintainAmount(gSecondNavalUnit, gMaintainSecondNavalUnitAmount);
            data.adjustUnitToMaintainAmount(gFourthNavalUnit, gMaintainFourthNavalUnitAmount);
            army_buffed = true;
         }
         }

      // gNavalAttackWave.update();

      static bool done = false;
      if (done == false && xsGetTime() >= gInitialTrainDelayWadjetScorpion)
      {
         done = true;
         data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Start training Wadjets.
         data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Start training Scorpion Men.
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            data.addUnitToMaintain(gThirdNavalUnit, gMaintainThirdNavalUnitAmount); // Start training Leviathans.
         }
         data.setTrainDelay(gThirdLandUnit, gTrainDelay);
         data.setTrainDelay(gFourthLandUnit, gTrainDelay);
      }

      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott15StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(259.00, 0.00, 37.00), 90);
   createOverrideGatherBase(vector(345.00, 0.00, 115.00), 60);
   gTimeToFarm = true;

   gOverrideClosestFishLocation = vector(205.00, 0.00, 150.00);
   gMaxFishDockScanRange = 36;

   gOverrideMaxVillagerPop = gMaxVillagerCount;
   gOverrideMaxFishingShipPop = gMaxFishingShipCount;
   setOverrideStrategy(fott15StrategySetup);

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

// Delay spear defense plan activation until after the opening battle concluded, to not interfere with units in that battle.
// We enable it once all the spearmen in the opening battle are either gone, or left behind permanently by the player (back-up timer).
rule enableSpearDefendPlan
inactive
minInterval 30
{
   if ((xsGetTime() >= 300) ||
       (getUnitCountByLocation(cUnitTypeSpearman, cMyID, cUnitStateAlive, vector(330.0, 0.0, 220.0), 25.0) <= 0))
   {
      xsDisableRule("enableSpearDefendPlan");
   }
}

// HEROIC AGE UPGRADES
   // *** MODERATE UPGRADES *** //
      // Research Architects 480 seconds after Arkantos reaches the TC.
      rule researchArchitects
      inactive
      minInterval 10 // AI will attempt to get the technology every 10 seconds.
      group ruleGroupUpgradesModerate
      {
         if (xsGetTime() >= 480 + gWakeUpTime)
            {
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
      }

   // *** HARD UPGRADES *** //
      // Research Heavy Warships 240 seconds after Arkantos reaches the TC.
      rule researchHeavyWarships
      inactive
      minInterval 10 // AI will attempt to get the technology every 10 seconds.
      group ruleGroupUpgradesHard
      {
         if (xsGetTime() >= 240 + gWakeUpTime)
            {
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
      }

// *** MYTHIC AGE UPGRADES *** //
   // MODERATE AND UP
         // Ballista Tower
            rule researchBallistaTower
            inactive
            minInterval 120 // Get the tech 120 seconds after the rule is enabled.
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
   // HARD AND UP
         // Champion Spearmen
            rule researchChampionSpearmen
            inactive
            minInterval 60 // Get the tech 60 seconds after the rule is enabled.
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
         // Champion Chariot Archers
            rule researchChampionChariotArchers
            inactive
            minInterval 180 // Get the tech 180 seconds after the rule is enabled.
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
         // Champion Warships
            rule researchChampionWarships
            inactive
            minInterval 90 // Get the tech 90 seconds after the rule is enabled.
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
         // Greatest of Fifty
            rule researchGreatestOfFifty
            inactive
            minInterval 300 // Get the tech 300 seconds after the rule is enabled.
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechGreatestOfFifty) == cTechStatusActive)
               {
                  xsDisableRule("researchGreatestOfFifty");
                  return;
               }
               else if (kbTechGetStatus(cTechGreatestOfFifty) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Greatest of Fifty research plan.");
                  researchSimpleTech(cTechGreatestOfFifty, cUnitTypeBarracks, -1, 60);
                  return;
               }
            }
         // Iron Weapons
            rule researchIronWeapons
            inactive
            minInterval 30 // Get the tech 30 seconds after the rule is enabled.
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
   // TITAN ONLY
         // Spear of Horus
            rule researchSpearOfHorus
            inactive
            minInterval 150 // Get the tech 150 seconds after the rule is enabled.
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechSpearOfHorus) == cTechStatusActive)
               {
                  xsDisableRule("researchSpearOfHorus");
                  return;
               }
               else if (kbTechGetStatus(cTechSpearOfHorus) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Spear of Horus research plan.");
                  researchSimpleTech(cTechSpearOfHorus, cUnitTypeBarracks, -1, 60);
                  return;
               }
            }
         // Iron Armor
            rule researchIronArmor
            inactive
            minInterval 50 // Get the tech 30 seconds after the rule is enabled.
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
            minInterval 75 // Get the tech 75 seconds after the rule is enabled.
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
         // Conscript Sailors
            rule researchConscriptSailors
            inactive
            minInterval 15 // Get the tech 15 seconds after the rule is enabled.
            {
               researchSimpleTech(cTechConscriptSailors, cUnitTypeDock, -1, 60);
               xsDisableRule("researchConscriptSailors"); // Disable self.
            }

// Called from the triggers to enable attacks. Occurs when Arkantos gets a base.
void updateParameters()
{
   // Set the wakeup time and enable upgrade rules.
   gWakeUpTime = xsGetTime(); // Used to determine when to research upgrades.
   // ENABLE TECHS
      // Not Easy
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         xsEnableRuleGroup("ruleGroupUpgradesModerate");
      }
      // Hard and Titan
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         xsEnableRuleGroup("ruleGroupUpgradesHard");
      }
   // Define first attack.
   gNavalAttackWave.setAttackStartTime(gNavalAttackStartDelay);
   return;
}

// Move defend plans (when nearby production is destroyed)
   void updateDefendPlan1()
   {
      // Lost our nearby production. Move defend point 1 around the Osiris Piece Cart.
      aiPlanSetVariableVector(gDefendPlan1, cDefendPlanTargetPoint, 0, vector(199.0, 0.0, 63.0));
      aiPlanSetVariableVector(gDefendPlan1, cDefendPlanGatherPoint, 0, vector(199.0, 0.0, 63.0));
      debugAttackWave("Moved our defend plan close to the cart's final destination.");
   }
   void updateDefendPlan2()
   {
      // Lost our nearby production. Move defend point 2 around the Osiris Piece Cart.
      aiPlanSetVariableVector(gDefendPlan2, cDefendPlanTargetPoint, 0, vector(215.0, 0.0, 43.0));
      aiPlanSetVariableVector(gDefendPlan2, cDefendPlanGatherPoint, 0, vector(215.0, 0.0, 43.0));
      debugAttackWave("Moved our defend plan close to the cart's final destination.");
   }
   void updateDefendPlan3()
   {
      // Lost our nearby production. Move defend point 3 around the Osiris Piece Cart.
      aiPlanSetVariableVector(gDefendPlan3, cDefendPlanTargetPoint, 0, vector(213.0, 0.0, 71.0));
      aiPlanSetVariableVector(gDefendPlan3, cDefendPlanGatherPoint, 0, vector(213.0, 0.0, 71.0));
      debugAttackWave("Moved our defend plan close to the cart's final destination.");
   }
   void updateDefendPlan4()
   {
      // Lost our nearby production. Move defend point 4 around the Osiris Piece Cart.
      aiPlanSetVariableVector(gDefendPlan4, cDefendPlanTargetPoint, 0, vector(335.0, 0.0, 101.0));
      aiPlanSetVariableVector(gDefendPlan4, cDefendPlanGatherPoint, 0, vector(335.0, 0.0, 101.0));
      debugAttackWave("Moved our defend plan south.");
   }
   void updateDefendPlan4Again()
   {
      // Lost our nearby production. Move defend point 4 around the Osiris Piece Cart.
      aiPlanSetVariableVector(gDefendPlan4, cDefendPlanTargetPoint, 0, vector(237.0, 0.0, 51.0));
      aiPlanSetVariableVector(gDefendPlan4, cDefendPlanGatherPoint, 0, vector(237.0, 0.0, 51.0));
      debugAttackWave("Moved our defend plan close to the cart's final destination.");
   }
   void updateDefendPlan5()
   {
      // Lost our nearby production. Move defend point 5 around the Osiris Piece Cart.
      aiPlanSetVariableVector(gDefendPlan5, cDefendPlanTargetPoint, 0, vector(225.0, 0.0, 53.0));
      aiPlanSetVariableVector(gDefendPlan5, cDefendPlanGatherPoint, 0, vector(225.0, 0.0, 53.0));
      debugAttackWave("Moved our defend plan close to the cart's final destination.");
   }