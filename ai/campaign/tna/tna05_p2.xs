//==============================================================================
/* tna05_p2.xs

   Red Egyptian player that attacks over land.
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
float gSphinxDelay = 60; // In seconds.
float gElephantDelay = 45; // In seconds.
float gSiegeTowerDelay = 60; // In seconds.
float gPetsuchosDelay = 90; // In seconds.

int gFirstLandUnit = cUnitTypeSpearman; // Begins training once they reach the Classical Age.
float gMaintainFirstLandUnitAmount = 4;
int gSecondLandUnit = cUnitTypePriest; // Begins training once they reach the Classical Age.
float gMaintainSecondLandUnitAmount = 3;
int gThirdLandUnit = cUnitTypeSphinx; // Begins training once they reach the Classical Age.
float gMaintainThirdLandUnitAmount = 2;
int gFourthLandUnit = cUnitTypeWarElephant; // Begins training once they reach the Heroic Age.
float gMaintainFourthLandUnitAmount = 3;
int gFifthLandUnit = cUnitTypeSiegeTower; // Begins training once they reach the Heroic Age.
float gMaintainFifthLandUnitAmount = 1;
int gSixthLandUnit = cUnitTypePetsuchos; // Begins training once they reach the Heroic Age.
float gMaintainSixthLandUnitAmount = 1;

float gMaxVillagerCount = 10;
float gMaxFishingShipCount = 2;
float gAttackStartDelay = 180; // 3 Minutes.
float gAttackWaveInterval = 640; // In seconds.
float gAttackStartSize = 5;
float gAttackMaxSize = 8;

float gInitialAttackStartSize = 5; // Used to calculate new values from increments before applying the multiplier.
float gInitialAttackMaxSize = 8; // Used to calculate new values from increments before applying the multiplier.

float gClassicalAgeUpTime = 330; // In seconds. (5½ minutes)
float gHeroicAgeUpTime = 1020; // In seconds. (17 minutes)

int gLandDefendPlan = -1;

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;
      int gDefendPlan3 = -1;
      int gDefendPlan4 = -1;


bool gShouldAttack = true;

Strategy scenarioAttackWaveStrategy()
{

   // Start enabling rules.
   xsEnableRule("HeroicUnits");
   xsEnableRule("useRain");
   xsEnableRule("useEclipse");
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
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticFishing, true);

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
      gSphinxDelay *= gDifficultyModifierTrainDelay;
      gElephantDelay *= gDifficultyModifierTrainDelay;
      gSiegeTowerDelay *= gDifficultyModifierTrainDelay;
      gPetsuchosDelay *= gDifficultyModifierTrainDelay;
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

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gSphinxDelay);

      data.setTrainDelay(gFourthLandUnit, gElephantDelay);
      data.setTrainDelay(gFifthLandUnit, gSiegeTowerDelay);
      data.setTrainDelay(gSixthLandUnit, gPetsuchosDelay);

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
      // Don't add Siege Towers until way later.
      
      gAttackWave.addAttackUnitType(gSixthLandUnit);

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(260.0, 0.0, 190.0); // In front of their Relic.
      vector targetPoint = vector(150.0, 0.0, 196.0); // Next to the Temple of Kronos.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path that leads directly to the Kronos Temple.");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
            static int counter = 0;
            static int old_counter = 0;
            counter++;
            if (counter >= counter + 1)
            {
               // We will decide whether or not to increase the attack size each time we launch an attack.
               // The amount goes up 4 times. (base Start reaches 8, base Max reaches 12)
               if (counter <= 5)
               {
                  gInitialAttackStartSize = gInitialAttackStartSize + 1; // Value to apply multiplier to.
                  gInitialAttackMaxSize = gInitialAttackMaxSize + 1; // Value to apply multiplier to.

                  gAttackStartSize = gInitialAttackStartSize * gDifficultyModifierAttackSizes; // Multiplier applied.
                  gAttackMaxSize = gInitialAttackMaxSize * gDifficultyModifierAttackSizes; // Multiplier applied.
               }
            }
            old_counter = counter;
         }
      );


   // SPLIT AMOUNTS
      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 2; // Spearmen
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 2; // Priests
      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2; // Sphinxes
      int fourthLandUnitSplitAmount = gMaintainFourthLandUnitAmount / 2; // War Elephants


   // DEFINE THE PLANS
      // Plan 1 (By the Barracks)
      gDefendPlan1 = createDefendPlan("Defense Plan 1", kbBaseGetMainID(cMyID), 5, vector(289.0, 0.0, 221.0), 30);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 40);
      aiPlanAddUnitType(gDefendPlan1, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Spearmen
      aiPlanAddUnitType(gDefendPlan1, gFifthLandUnit, 0, 0, 200); // Siege Towers

      // Plan 2 (Left of their Relic)
      gDefendPlan2 = createDefendPlan("Defense Plan 2", kbBaseGetMainID(cMyID), 5, vector(261.0, 0.0, 209.0), 30);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 40);
      aiPlanAddUnitType(gDefendPlan2, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Spearmen
      aiPlanAddUnitType(gDefendPlan2, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Priests
      aiPlanAddUnitType(gDefendPlan2, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Sphinxes

      // Plan 3 (Below their Relic)
      gDefendPlan3 = createDefendPlan("Defense Plan 3", kbBaseGetMainID(cMyID), 5, vector(263.0, 0.0, 173.0), 30);
      aiPlanSetVariableFloat(gDefendPlan3, cDefendPlanEngageRange, 0, 40);
      aiPlanAddUnitType(gDefendPlan3, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Sphinxes
      aiPlanAddUnitType(gDefendPlan3, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount); // War Elephants
      aiPlanAddUnitType(gDefendPlan3, gSixthLandUnit, 0, 0, 200); // Petsuchoses

      // Plan 4 (By their eastern gate)
      gDefendPlan4 = createDefendPlan("Defense Plan 4", kbBaseGetMainID(cMyID), 5, vector(295.0, 0.0, 145.0), 30);
      aiPlanSetVariableFloat(gDefendPlan4, cDefendPlanEngageRange, 0, 40);
      aiPlanAddUnitType(gDefendPlan4, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Priests
      aiPlanAddUnitType(gDefendPlan4, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount); // War Elephants

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
         researchSimpleTech(cTechClassicalAgeBast, cUnitTypeTownCenter, -1, 75);
      }
      // Time to go to Heroic.
      if (age < cAge3 && xsGetTime() >= gHeroicAgeUpTime)
      {
         researchSimpleTech(cTechHeroicAgeSobek, cUnitTypeTownCenter, -1, 75);
      }
      

      // * * * TECH RULES * * * //

      // CLASSICAL AGE //
      if (age >= cAge2 && Reached_Classical == false)
      {
         // Techs for all difficulties:
         xsEnableRule("researchMediumSpearmen");
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
            xsEnableRule("researchCriosphinx");
            xsEnableRule("researchMasons");
            xsEnableRule("researchSacredCats");
         }

         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchHieracosphinx");
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
            xsEnableRule("researchBoilingOil");
            xsEnableRule("researchCrenellations");
            xsEnableRule("researchBallistics");
            xsEnableRule("researchIrrigation");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchBronzeArmor");
            xsEnableRule("researchHeavyElephants");
            xsEnableRule("researchHeavySpearmen");
            xsEnableRule("researchGuardTower");
            xsEnableRule("researchFortifiedTownCenter");
         }

         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchBronzeShields");
            xsEnableRule("researchCrocodilopolis");
         }
         
         Reached_Heroic = true;
      }

      // Deploy Siege Towers only after 25 minutes.
      static bool siege_towers = false;
      if (xsGetTime() >= 1500 && siege_towers == false)
      {
         gAttackWave.addAttackUnitType(gFifthLandUnit);
         siege_towers = true;
      }

      // ************************** ATTACK ROUTE UPDATE ************************** //
      // If we find out that player 1 has stuff by the northwest Settlement,
      // then we'll start passing by that area before marching on to the Kronos Temple.
      // **************************************************************************//

      // Only define the paths once.
      static bool defined_paths = false;
      static int pathID2 = -1;
      static int pathID3 = -1;

      if (defined_paths == false)
      {
         vector startPoint = vector(260.0, 0.0, 190.0); // In front of their Relic.
         vector targetPoint = vector(150.0, 0.0, 196.0); // Next to the Temple of Kronos.

         pathID2 = kbPathCreate("Path that goes to the northwest Settlement, then the Kronos Temple.");
         kbPathAddWaypoint(pathID2, startPoint);
         kbPathAddWaypoint(pathID2, vector(273.0, 0.0, 220.0)); // Block #1
         kbPathAddWaypoint(pathID2, vector(132.0, 0.0, 306.0)); // Block #2
         kbPathAddWaypoint(pathID2, vector(284.0, 0.0, 304.0)); // Block #3
         kbPathAddWaypoint(pathID2, vector(262.0, 0.0, 240.0)); // Block #4
         kbPathAddWaypoint(pathID2, targetPoint);

         // Clone of the original route.
         pathID3 = kbPathCreate("Path that leads directly to the Kronos Temple.");
         kbPathAddWaypoint(pathID3, startPoint);
         kbPathAddWaypoint(pathID3, targetPoint);
         defined_paths = true;
      }

      // Only run through this code if it's been at least 1 minute since we last checked.
      static int route_check = 0;

      // Only run through this code if we haven't started attacking the northwest.
      static bool added_route = false;

      route_check++;
      int game_time = xsGetTime();

      // Only add the attack route if it's been more than 10 minutes.
      if (route_check >= 60 && game_time > 600)
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

            // Get rid of the old path and start using the new one exclusively.
            kbPathDestroy(kbAttackRouteGetPathIDByIndex(gAttackWave.mAttackRouteID, 0));
            kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID2);
            added_route = true;
         }
         // Switch back to the original route if player 1 is not there.
         if (totalEnemies == 0 && added_route == true)
         {
            // Get rid of the old path and start using the new one exclusively.
            kbPathDestroy(kbAttackRouteGetPathIDByIndex(gAttackWave.mAttackRouteID, 0));
            kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID3);
            added_route = false;
         }
      }

      static bool accelerated_attacks = false;
      if (gShouldAttack == true)
      {
         // Begin attacking more frequently at the 20-minute mark on all difficulties except Easy.
         if (xsGetTime() >= 1800 && cDifficultyCurrent >= cDifficultyModerate)
         {
            // Accelerate attacks from this point on - the Atlanteans should be built up by now.
            if (accelerated_attacks == false)
            {
               gAttackWaveInterval *= 0.5; // Attacks happen twice as fast now.
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
   gMaxFishingShipCount *= gDifficultyModifierMaintainFishing;

   gOverrideMaxVillagerPop = gMaxVillagerCount;
   gOverrideMaxFishingShipPop = gMaxFishingShipCount;

   gMainGatherBase = createOverrideGatherBase(vector(297.00, 0.00, 191.00), 65);
   createOverrideGatherBase(vector(251.00, 0.00, 259.00), 15);
   gOverrideClosestFishLocation = vector(294.00, 0.00, 235.00);
   gMaxFishDockScanRange = 50;

   setOverrideStrategy(tna05StrategySetup);

   gOverrideFarmCount = 18; // We can't have too many farms due to space restrictions.
   gRBDSystem.setMaxFarmsPerBase(18);
   gRBDSystem.setMaxFarmsPerIteration(18);
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, vector(297.0, 5, 191.0), 15.0); // Our TC.
      kbBuildingPlacementAddPositionInfluence(bpID, vector(297.0, 5, 191.0), 100.0, 15.0, cFalloffLinear); // Our TC.
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
rule useEclipse
inactive
minInterval 10
{
   int numSphinxes = -1;
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
            numSphinxes = getUnitCountByLocation(cUnitTypeSphinx, 2, cUnitStateAlive, kbUnitGetPosition(unitID), 15.0);
            debugAttackWave("numEnemies for casting Eclipse: " + numEnemies);
            debugAttackWave("numSphinxes for casting Eclipse: " + numSphinxes);
            if (numEnemies >= 2 && numSphinxes >= 2)
            {
               if (aiCastGodPowerAtPosition(cProtoPowerEclipse, kbUnitGetPosition(unitID)) == true)
               {
                  debugAttackWave("Casted Eclipse!");
                  xsDisableRule("useEclipse");
                  return;
               }
            }
         }
      }
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
      
      xsDisableRule("HeroicUnits");
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

rule useRain
inactive
minInterval 540
{
   if (aiCastGodPowerAtPosition(cProtoPowerRain, vector(297.0, 0.0, 191.0)) == true)
   {
      debugAttackWave("Casted Rain!");
      xsDisableRule("useRain");
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
      // Sacred Cats
         rule researchSacredCats
         inactive
         minInterval 30
         {
            debugAttackWave("Starting Sacred Cats research plan.");
            researchSimpleTech(cTechSacredCats, cUnitTypeGranary, -1, 60);
            xsDisableRule("researchSacredCats");
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
         // Medium Spearmen
            rule researchMediumSpearmen
            inactive
            minInterval 60
            {
               debugAttackWave("Starting Medium Spearmen research plan.");
               researchSimpleTech(cTechMediumSpearmen, cUnitTypeBarracks, -1, 50);
               xsDisableRule("researchMediumSpearmen");
            }
   // NOT EASY
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
   // HARD AND TITAN ONLY
      // Criosphinx
         rule researchCriosphinx
         inactive
         minInterval 300
         {
            debugAttackWave("Starting Criosphinx research plan.");
            researchSimpleTech(cTechCriosphinx, cUnitTypeTemple, -1, 50);
            xsDisableRule("researchCriosphinx");
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
   // TITAN ONLY
      // Hieracosphinx
         rule researchHieracosphinx
         inactive
         minInterval 600
         {
            xsSetRuleMinIntervalSelf(10);
            if (kbTechGetStatus(cTechCriosphinx) == cTechStatusActive)
            {
               debugAttackWave("Starting Hieracosphinx research plan.");
               researchSimpleTech(cTechHieracosphinx, cUnitTypeTemple, -1, 50);
               xsDisableRule("researchHieracosphinx");
            }
         }

// *** HEROIC AGE ***
   // NOT EASY
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
            debugAttackWave("Starting Ballistics research plans.");
            researchSimpleTech(cTechBallistics, cUnitTypeArmory, -1, 50);
            xsDisableRule("researchBallistics");
         }
   // HARD AND TITAN ONLY
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
      // Heavy Spearmen
         rule researchHeavySpearmen
         inactive
         minInterval 300
         {
            xsSetRuleMinIntervalSelf(10);
            if (kbTechGetStatus(cTechMediumSpearmen) == cTechStatusActive)
            {
               debugAttackWave("Starting Heavy Spearmen research plan.");
               researchSimpleTech(cTechHeavySpearmen, cUnitTypeBarracks, -1, 50);
               xsDisableRule("researchHeavySpearmen");
            }
         }
      // Heavy War Elephants
         rule researchHeavyElephants
         inactive
         minInterval 900
      {
         xsSetRuleMinIntervalSelf(10);
         // Cease if we have it. Otherwise, research it.
         if (kbTechGetStatus(cTechHeavyWarElephants) == cTechStatusActive)
         {
            xsDisableRule("researchHeavyWarElephants");
            return;
         }
         else if (kbTechGetStatus(cTechHeavyWarElephants) == cTechStatusObtainable)
         {
            debugAttackWave("Starting Heavy War Elephants research plan.");
            researchSimpleTech(cTechHeavyWarElephants, cUnitTypeMigdolStronghold, -1, 60);
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
            else if (kbTechGetStatus(cTechFortifiedTownCenter) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Fortified Town Center research plan.");
               researchSimpleTech(cTechFortifiedTownCenter, cUnitTypeTownCenter, -1, 60);
               return;
            }
         }
   // TITAN ONLY
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
      // Crocodilopolis
         rule researchCrocodilopolis
         inactive
         minInterval 1200
         {
            debugAttackWave("Starting Crocodilopolis research plan.");
            researchSimpleTech(cTechCrocodilopolis, cUnitTypeTemple, -1, 50);
            xsDisableRule("researchCrocodilopolis");
         }