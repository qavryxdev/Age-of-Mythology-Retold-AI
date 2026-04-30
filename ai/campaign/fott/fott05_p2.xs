//==============================================================================
/* fott05_p2.xs

   Red Greek player owning the base in the north (Troy). Sends attacks of Hoplite, Hippeis, Prodromos, Petroboli.
   Builds 3 forward buildings during the game and defends them a little.
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

float gMythTrainDelay = 40; // In seconds.

int gFirstLandUnit = cUnitTypeHoplite; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 8;
int gSecondLandUnit = cUnitTypeHippeus; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 4;
int gThirdLandUnit = cUnitTypeProdromos; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 2;
int gFourthLandUnit = cUnitTypePetrobolos; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 1;
int gFifthLandUnit = cUnitTypeToxotes; // Gets trained from the start.
float gMaintainFifthLandUnitAmount = 6;
int gSixthLandUnit = cUnitTypeColossus; // Gets trained from the start.
float gMaintainSixthLandUnitAmount = 2;

float gMaxVillagerCount = 20;
float gAttackStartDelay = 20; // In seconds.
float gAttackWaveInterval = 480; // In seconds.

float gAttackFirstAttackStartSize = 15; // Cavalry only.
float gAttackIntervalAttackStartSize = 12; // Later Attacks
float gAttackMaxSize = 16;

float gMythicAgeUpTime = 600; // In seconds.
int gTowerDefendPlan = -1;
int gTowerBuildPlan = -1;
int gStableDefendPlan = -1;
int gStableBuildPlan = -1;
int gFortressDefendPlan = -1;
int gFortressBuildPlan = -1;

Strategy scenarioAttackWaveStrategy()
{
   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugAttackWave("***Starting Scenario Attack Wave Strategy***");
      xsEnableRule("usePestilence");

      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================

      // Make certain parameters way more lenient on Easy.
      if(cDifficultyCurrent == cDifficultyEasy)
      {
         gAttackStartDelay = 600; // Wait longer to launch the first attack.
         gAttackWaveInterval = 600; // Attack less frequently after the first strike.

         gAttackFirstAttackStartSize = 4; // There are only 2 Hippeis that attack you on Easy.
         gAttackIntervalAttackStartSize = 5; // Weak attacks on Easy.
         gAttackMaxSize = 6; // Never let this be too high.

         gMaintainFirstLandUnitAmount = 5; // 5 Hoplites
         gMaintainSecondLandUnitAmount = 2; // 2 Hippeis
         gMaintainThirdLandUnitAmount = 2; // 2 Prodromoi
         gMaintainFourthLandUnitAmount = 0; // Don't make Petroboli on Easy.
         gMaintainFifthLandUnitAmount = 4; // 4 Toxotai
         gMaintainSixthLandUnitAmount = 1; // Only one Colossus on Easy.
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackFirstAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackIntervalAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gMythTrainDelay *= gDifficultyModifierTrainDelay;

      gMythicAgeUpTime = gMythicAgeUpTime * gDifficultyModifierAgeUp + xsGetTime();

      // Troy advances to the Mythic Age much sooner on Titan.
      if (cDifficultyCurrent == cDifficultyTitan)
      {
         gMythicAgeUpTime /= 4;
      }

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);

      data.setTrainDelay(gSixthLandUnit, gMythTrainDelay);

      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(cWaitWithAttacking); // Switch to the regular attack delay once Arkantos reaches the TC.
      gAttackWave.displayFirstAttackStats();

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      gTimeToFarm = true;

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(239.0, 0.0, 186.0); // In front of our TC.
      vector targetPoint = vector(97.0, 0.0, 193.0); // P1's TC.

      // Create the routes along which the AI attacks. Every route has equal chances of being chosen.
      // If you need a route to only become available later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(164.0, 0.0, 220.0)); // To the left of our base, near our farms.
      kbPathAddWaypoint(pathID1, vector(111.0, 4.0, 257.0)); // Left side of our farms, up the hill.
      kbPathAddWaypoint(pathID1, vector(80.0, 3.0, 238.0)); // Past the gold mine, into the enemy base.
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      // We create this duplicate path because we need this way of walking to be chosen 2/3 of the time.
      int pathID2 = kbPathCreate("Copy of path 1");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(164.0, 0.0, 220.0)); // To the left of our base, near our farms.
      kbPathAddWaypoint(pathID2, vector(111.0, 4.0, 257.0)); // Left side of our farms, up the hill.
      kbPathAddWaypoint(pathID2, vector(80.0, 3.0, 238.0)); // Past the gold mine, into the enemy base.
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
            // Start our regular attacks after the initial cavalry raid.
            static bool firstAttack = true;
            if (firstAttack == true)
            {
               gAttackWave.setAttackSize(gAttackIntervalAttackStartSize);
               gAttackWave.setMinAttackSize(gAttackIntervalAttackStartSize);
               // Add the other units in.
               gAttackWave.addAttackUnitType(gFirstLandUnit);
               gAttackWave.addAttackUnitType(gFourthLandUnit);
               gAttackWave.addAttackUnitType(gFifthLandUnit);
               gAttackWave.addAttackUnitType(gSixthLandUnit);
               firstAttack = false;
            }

            static int counter = 0;
            counter++;

            static bool path_added = false;
            static bool tower_plan = false;
            static bool fortress_plan = false;

            if (counter == 2 && path_added == false)
            {
               // Add the new attack path in, the second attack can use this path now.
               int pathID3 = kbPathCreate("Path 3");
               kbPathAddWaypoint(pathID3, vector(239.0, 0.0, 186.0));
               kbPathAddWaypoint(pathID3, vector(97.0, 0.0, 193.0));
               kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID3);
               path_added = true;
            }

            // Don't build the Tower on Easy.
            if (cDifficultyCurrent >= cDifficultyModerate)
            {
               if (xsGetTime() >= 10 && tower_plan == false)
               {
                  xsEnableRule("buildTower");
                  tower_plan = true;
               }
            }
            // The stable plan is activated by the dialogue trigger.

            // Build the Fortress after 10 minutes (Not on Easy).
            if (cDifficultyCurrent >= cDifficultyModerate)
            {
               if (xsGetTime() >= 600 && fortress_plan == false)
               {
                  xsEnableRule("buildFortress");
                  fortress_plan = true;
               }
            }
         }
      );
      

      int landDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 50.0, startPoint, 10);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool needResearchMythic = true;
      static bool reachedMythic = false;

      int age = kbPlayerGetAge(cMyID);
      int time = xsGetTime();
      if (needResearchMythic == true && xsGetTime() >= gMythicAgeUpTime)
      {
         if (researchSimpleTech(cTechMythicAgeHephaestus, cUnitTypeTownCenter, -1, 60) == true)
         {
            debugAttackWave("Starting Mythic Age research plan.");
            needResearchMythic = false;
         }
      }

      // * * * TECH RULES * * * //

      // HEROIC AGE //
      if (age >= cAge3)
      {
         // Tech Rules for All Difficulties:

         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchHeavyInfantry");
            xsEnableRule("researchFortifiedWall");
            xsEnableRule("researchHeavyArchers");
            xsEnableRule("researchBoilingOil");
            xsEnableRule("researchDraftHorses");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchArchitects");
         }

         // Tech Rules for Titan only:

         // Not Hard or Titan:
         if (cDifficultyCurrent <= cDifficultyModerate)
         {
            xsEnableRule("researchHeavyCavalry");
         }
         // Not Titan:
         if (cDifficultyCurrent <= cDifficultyHard)
         {
            xsEnableRule("researchBronzeShields");
         }
      }

      // MYTHIC AGE //
      if (age >= cAge4 && reachedMythic == false)
      {
         // Tech Rules for All Difficulties:
         xsEnableRule("researchQuarry");
         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchHandOfTalos");
         }
         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchEngineers");
            xsEnableRule("researchShoulderOfTalos");
         }
         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchIronArmor");
            xsEnableRule("researchIronShields");
            xsEnableRule("researchChampionInfantry");
            xsEnableRule("researchChampionCavalry");
            xsEnableRule("researchChampionArchers");
         }
         // Change the boolean back to false so the rules aren't enabled multiple times.
         reachedMythic = true;
      }

      // Don't invoke curse until at least 10 minutes into the mission.
      static bool curse_activated = false;
      if (time >= 600 && curse_activated == false)
      {
         xsEnableRule("useCurse");
         curse_activated = true;
      }

      // Start making more soldiers after 12 minutes since the first attack.
      static bool army_buffed = false;

      if (army_buffed == false && time >= 720)
      {
         // Smaller increase on Moderate.
         if (cDifficultyCurrent == cDifficultyModerate)
         {
            gMaintainFirstLandUnitAmount *= 1.25; // Train +25% Hoplites.
            gMaintainSecondLandUnitAmount *= 1.25; // Train +25% Hippeis.
            gMaintainFifthLandUnitAmount *= 1.25; // Train +25% Toxotai.
            gMaintainFourthLandUnitAmount *= 2.00; // Train +100% Petroboli.

            data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
            data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
            data.adjustUnitToMaintainAmount(gFourthLandUnit, gMaintainFourthLandUnitAmount);
            data.adjustUnitToMaintainAmount(gFifthLandUnit, gMaintainFifthLandUnitAmount);
                           
            // Update attack size parameters based on the enlarged army composition.
            gAttackMaxSize *= 1.15; // Attack size increases by +15%
            gAttackWave.setMaxAttackSize(gAttackMaxSize);

            // Train more Villagers to support the larger army.
            gMaxVillagerCount *= 1.15; // Train +15% more Villagers.
            gOverrideMaxVillagerPop = gMaxVillagerCount;
         }
         // Larger increase on Hard + Titan.
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            gMaintainFirstLandUnitAmount *= 1.50; // Train +50% Hoplites.
            gMaintainSecondLandUnitAmount *= 1.50; // Train +50% Hippeis.
            gMaintainThirdLandUnitAmount *= 2.50; // Train +150% Prodromoi.
            gMaintainFourthLandUnitAmount *= 3.00; // Train +200% Petroboli.
            gMaintainFifthLandUnitAmount *= 1.50; // Train +50% Toxotai.
            gMaintainSixthLandUnitAmount *= 1.50; // Train +50% Colossi.

            data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
            data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
            data.adjustUnitToMaintainAmount(gThirdLandUnit, gMaintainThirdLandUnitAmount);
            data.adjustUnitToMaintainAmount(gFourthLandUnit, gMaintainFourthLandUnitAmount);
            data.adjustUnitToMaintainAmount(gFifthLandUnit, gMaintainFifthLandUnitAmount);
            data.adjustUnitToMaintainAmount(gSixthLandUnit, gMaintainSixthLandUnitAmount);
                           
            // Update attack size parameters based on the enlarged army composition.
            gAttackMaxSize *= 1.40; // Attack size increases by +40%
            gAttackWave.setMaxAttackSize(gAttackMaxSize);

            // Train more Villagers to support the larger army.
            gMaxVillagerCount *= 1.50; // Train +50% more Villagers.
            gOverrideMaxVillagerPop = gMaxVillagerCount;
         }

         // Accelerate attacks from this point on - Arkantos should be built up now.
         gAttackWaveInterval = 300;
         gAttackWaveInterval *= gDifficultyModifierAttackInterval;

         army_buffed = true;
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott05StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(265.00, 0.00, 215.00), 65);
   createOverrideGatherBase(vector(251.00, 0.00, 199.00), 55);

   setOverrideStrategy(fott05StrategySetup);

   gOverrideFarmCount = 20; // We can't have too many farms due to space restrictions.
   gRBDSystem.setMaxFarmsPerBase(20);
   gRBDSystem.setMaxFarmsPerIteration(20);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// Pestilence enemy buildings that we attack.
rule usePestilence
inactive
minInterval 5
{
   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   int unitID = -1;
   int numBuildings = -1;
   for (int i = 0; i < attackPlans.size(); i++)
   {
      if (aiPlanGetParentID(attackPlans[i]) == -1)
      {
         // We just take the first unit to scan from.
         unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
         if (unitID >= 0)
         {
            numBuildings = getUnitCountByLocation(cUnitTypeMilitaryBuilding, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 15.0);
            debugAttackWave("numBuildings for casting Pestilence: " + numBuildings);
            if (numBuildings >= 2)
            {
               if (aiCastGodPowerAtPosition(cProtoPowerPestilence, kbUnitGetPosition(unitID)) == true)
               {
                  debugAttackWave("Casted Pestilence!");
                  xsDisableRule("usePestilence");
               }
            }
         }
      }
   }
}

// Use Curse while attacking or if we're in danger in our base.
rule useCurse
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
            numEnemies = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 10.0);
            debugAttackWave("numEnemies for casting Curse offensively: " + numEnemies);
            if (numEnemies >= 2)
            {
               if (aiCastGodPowerAtPosition(cProtoPowerCurse, kbUnitGetPosition(unitID)) == true)
               {
                  debugAttackWave("Casted Curse!");
                  xsDisableRule("useCurse");
                  return;
               }
            }
         }
      }
   }
}


// Try to build a Sentry Tower next to a P1 gold mine, also send some guards.
rule buildTower
inactive
minInterval 10
{
   // Mother nature block next to the gold mine north-west of the player's base.
   vector buildPosition = vector(97.0, 4.00, 247.0);
   static bool done = false;
   if (done == true)
   {
      int towerDefenders = aiPlanGetNumberUnits(gTowerDefendPlan); // We add this check to avoid stopping unit assignment before we even assigned any.
      int towerBuilders = aiPlanGetNumberUnits(gTowerBuildPlan); // Builders are not assigned until we can afford the building.
      if (towerDefenders >= 1 && towerBuilders >= 1) // This may require multiple iterations over this rule.
      {
         debugAttackWave("Tower Defenders and Builders have been assigned successfully, disabling rule.");
         aiPlanSetFlag(gTowerDefendPlan, cPlanFlagNoMoreUnits, true); // We send 4 initial units to defend this endeavor, not more.
         aiPlanSetFlag(gTowerBuildPlan, cPlanFlagNoMoreUnits, true); // Stop sending Villagers.
         // We try only once to do this build + defend plan.
         xsDisableRule("buildTower");
      }
      return;
   }

   int numPlayerUnits = getUnitCountByLocation(cUnitTypeUnit, 1, cUnitStateAlive, buildPosition, 15.0);
   int numPlayerBuildings = getUnitCountByLocation(cUnitTypeBuilding, 1, cUnitStateAlive, buildPosition, 15.0);
   int numPlayerTotal = numPlayerUnits + numPlayerBuildings;
   if (numPlayerTotal <= 0)
   {
      // This isn't really reliable since these units could be in an attack plan, but that attack covers this build anyway
      // maybe.
      if (kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive) < 4)
      {
         debugAttackWave("Not enough military to defend our Tower build plan, waiting until we have enough.");
         return;
      }

      // Defend plan.
      gTowerDefendPlan = createDefendPlan("Tower Land Defend", -1, 15.0, buildPosition, 25, buildPosition);
      aiPlanAddUnitType(gTowerDefendPlan, cUnitTypeLogicalTypeLandMilitary, 4, 4, 4);

      // Build plan.
      gTowerBuildPlan = aiPlanCreate("Tower Build Plan", cPlanBuild, -1);
      int bpID = kbBuildingPlacementCreate(aiPlanGetName(gTowerBuildPlan));
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeSentryTower);
      kbBuildingPlacementSetCenterPosition(bpID, buildPosition, 10.0);
      kbBuildingPlacementSetStepSize(bpID, 1.0);
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementAddPositionInfluence(bpID, buildPosition, 100.0, 50.0, cFalloffLinear);
      aiPlanSetVariableInt(gTowerBuildPlan, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetVariableInt(gTowerBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypeSentryTower);
      aiPlanAddUnitType(gTowerBuildPlan, cUnitTypeVillagerGreek, 2, 2, 2);
      aiPlanSetPriority(gTowerBuildPlan, 99);
      aiPlanSetEventHandler(gTowerBuildPlan, cPlanEventStateChange, "towerBuildPlanEventHandler");

      done = true; // Disable in another iteration.
      xsSetRuleMinInterval("buildTower", 30);
      debugAttackWave("Starting the Tower build and defend plans!");
   }
   else
   {
      debugAttackWave("Found " + numPlayerTotal + " enemies near Tower position, not building the forward Tower now.");
   }
}

void towerBuildPlanEventHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateDone || state == cPlanStateFailed)
   {
      debugAttackWave("Our Tower build plan is done, destroying our accompanying defend plan.");
      aiPlanDestroy(gTowerDefendPlan);
   }
}


// Try to build a Stable to the east of the player's base, also send some guards.
rule buildStable
inactive
minInterval 10
{
   vector buildPosition = vector(150.0, 0.00, 129.0); // Red cinematic start block to the east of the player's base.
   static bool done = false;
   if (done == true)
   {
      int stableDefenders = aiPlanGetNumberUnits(gStableDefendPlan); // We add this check to avoid stopping unit assignment before we even assigned any.
      int stableBuilders = aiPlanGetNumberUnits(gStableBuildPlan); // Builders are not assigned until we can afford the building.
      if (stableDefenders >= 1 && stableBuilders >= 1) // This may require multiple iterations over this rule.
      {
         debugAttackWave("Stable Defenders and Builders have been assigned successfully, disabling rule.");
         aiPlanSetFlag(gStableDefendPlan, cPlanFlagNoMoreUnits, true); // We send 4 initial units to defend this endeavor, not more.
         aiPlanSetFlag(gStableBuildPlan, cPlanFlagNoMoreUnits, true); // Stop sending Villagers.
         // We try only once to do this build + defend plan.
         xsDisableRule("buildStable");
      }
      return;
   }

   int numPlayerUnits = getUnitCountByLocation(cUnitTypeUnit, 1, cUnitStateAlive, buildPosition, 15.0);
   int numPlayerBuildings = getUnitCountByLocation(cUnitTypeBuilding, 1, cUnitStateAlive, buildPosition, 15.0);
   int numPlayerTotal = numPlayerUnits + numPlayerBuildings;
   if (numPlayerTotal <= 0)
   {
      // This isn't really reliable since these units could be in an attack plan, but that attack covers this build anyway
      // maybe.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         if (kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive) < 4)
         {
            debugAttackWave("Not enough military to defend our Stable build plan, waiting until we have enough.");
            return;
         }
      }
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         if (kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive) < 2)
         {
            debugAttackWave("Not enough military to defend our Stable build plan, waiting until we have enough.");
            return;
         }
      }

      // Defend plan.
      gStableDefendPlan = createDefendPlan("Stable Land Defend", -1, 15.0, buildPosition, 25, buildPosition);
      // Fewer guards on Easy than other difficulties.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         aiPlanAddUnitType(gStableDefendPlan, cUnitTypeLogicalTypeLandMilitary, 4, 4, 4);
      }
      if (cDifficultyCurrent >= cDifficultyEasy)
      {
         aiPlanAddUnitType(gStableDefendPlan, cUnitTypeLogicalTypeLandMilitary, 2, 2, 2);
      }

      // Build plan.
      gStableBuildPlan = aiPlanCreate("Stable Build Plan", cPlanBuild, -1);
      int bpID = kbBuildingPlacementCreate(aiPlanGetName(gStableBuildPlan));
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeStable);
      kbBuildingPlacementSetCenterPosition(bpID, buildPosition, 10.0);
      kbBuildingPlacementSetStepSize(bpID, 1.0);
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementAddPositionInfluence(bpID, buildPosition, 100.0, 50.0, cFalloffLinear);
      aiPlanSetVariableInt(gStableBuildPlan, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetVariableInt(gStableBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypeStable);
      aiPlanAddUnitType(gStableBuildPlan, cUnitTypeVillagerGreek, 2, 2, 2);
      aiPlanSetPriority(gStableBuildPlan, 99);
      aiPlanSetEventHandler(gStableBuildPlan, cPlanEventStateChange, "stableBuildPlanEventHandler");

      done = true; // Disable in another iteration.
      xsSetRuleMinInterval("buildStable", 30);
      debugAttackWave("Starting the Stable build and defend plans!");
   }
   else
   {
      debugAttackWave("Found " + numPlayerTotal + " enemies near Stable position, not building the forward Stable now.");
   }
}

void stableBuildPlanEventHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateDone || state == cPlanStateFailed) // We're done or it failed, whatever just end the defend plan.
   {
      debugAttackWave("Our Stable build plan is done, destroying our accompanying defend plan.");
      aiPlanDestroy(gStableDefendPlan);
   }
}


// Try to build a Fortress on the hill between our base and the player's base, also send some guards.
rule buildFortress
inactive
minInterval 10
{
   vector buildPosition = vector(152.0, 7.00, 184.0); // Teal cinematic block on the hill.
   static bool done = false;
   if (done == true)
   {
      int fortressDefenders = aiPlanGetNumberUnits(gFortressDefendPlan); // We add this check to avoid stopping unit assignment before we even assigned any.
      int fortressBuilders = aiPlanGetNumberUnits(gFortressBuildPlan); // Builders are not assigned until we can afford the building.
      if (fortressDefenders >= 1 && fortressBuilders >= 1) // This may require multiple iterations over this rule.
      {
         debugAttackWave("Fortress Defenders and Builders have been assigned successfully, disabling rule.");
         aiPlanSetFlag(gFortressDefendPlan, cPlanFlagNoMoreUnits, true); // We send 6 initial units to defend this endeavor, not more.
         aiPlanSetFlag(gFortressBuildPlan, cPlanFlagNoMoreUnits, true); // Stop sending Villagers.
         // We try only once to do this build + defend plan.
         xsDisableRule("buildFortress");
      }
      return;
   }

   int numPlayerUnits = getUnitCountByLocation(cUnitTypeUnit, 1, cUnitStateAlive, buildPosition, 15.0);
   int numPlayerBuildings = getUnitCountByLocation(cUnitTypeBuilding, 1, cUnitStateAlive, buildPosition, 15.0);
   int numPlayerTotal = numPlayerUnits + numPlayerBuildings;
   if (numPlayerTotal <= 0)
   {
      // This isn't really reliable since these units could be in an attack plan, but that attack covers this build anyway maybe.
      if (kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive) < 6)
      {
         debugAttackWave("Not enough military to defend our Fortress build plan, waiting until we have enough.");
         return;
      }

      // Defend plan.
      gFortressDefendPlan = createDefendPlan("Fortress Land Defend", -1, 15.0, buildPosition, 25, buildPosition);
      aiPlanAddUnitType(gFortressDefendPlan, cUnitTypeLogicalTypeLandMilitary, 6, 6, 6);

      // Build plan.
      gFortressBuildPlan = aiPlanCreate("Fortress Build Plan", cPlanBuild, -1);
      int bpID = kbBuildingPlacementCreate(aiPlanGetName(gFortressBuildPlan));
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeFortress);
      kbBuildingPlacementSetCenterPosition(bpID, buildPosition, 15.0);
      kbBuildingPlacementSetStepSize(bpID, 1.0);
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementAddPositionInfluence(bpID, buildPosition, 100.0, 50.0, cFalloffLinear);
      aiPlanSetVariableInt(gFortressBuildPlan, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetVariableInt(gFortressBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypeFortress);
      aiPlanAddUnitType(gFortressBuildPlan, cUnitTypeVillagerGreek, 3, 3, 3);
      aiPlanSetPriority(gFortressBuildPlan, 99);
      aiPlanSetEventHandler(gFortressBuildPlan, cPlanEventStateChange, "fortressBuildPlanEventHandler");

      done = true; // Disable in another iteration.
      xsSetRuleMinInterval("buildFortress", 30);
      debugAttackWave("Starting the Fortress build and defend plans!");
   }
   else
   {
      debugAttackWave("Found " + numPlayerTotal + " enemies near Fortress position, not building the forward Fortress now.");
   }
}

void fortressBuildPlanEventHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateDone || state == cPlanStateFailed) // We're done or it failed, whatever just end the defend plan.
   {
      debugAttackWave("Our Fortress build plan is done, destroying our accompanying defend plan.");
      aiPlanDestroy(gFortressDefendPlan);
   }
}


// TECH RULES //

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

   rule researchHeavyInfantry
   active
   minInterval 240
   {
      xsSetRuleMinIntervalSelf(10);
      // Cease if we have it. Otherwise, research it.
      if (kbTechGetStatus(cTechHeavyInfantry) == cTechStatusActive)
      {
         xsDisableRule("researchHeavyInfantry");
         return;
      }
      else if (kbTechGetStatus(cTechHeavyInfantry) == cTechStatusObtainable)
      {
         debugAttackWave("Starting Heavy Infantry research plan.");
         researchSimpleTech(cTechHeavyInfantry, cUnitTypeMilitaryAcademy, -1, 60);
         return;
      }
   }

   rule researchFortifiedWall
   active
   minInterval 240
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
         researchSimpleTech(cTechFortifiedWall, cUnitTypeWallConnector, -1, 60);
         return;
      }
   }

   rule researchHeavyCavalry
   active
   minInterval 180
   {
      xsSetRuleMinIntervalSelf(10);
      // Cease if we have it. Otherwise, research it.
      if (kbTechGetStatus(cTechHeavyCavalry) == cTechStatusActive)
      {
         xsDisableRule("researchHeavyCavalry");
         return;
      }
      else if (kbTechGetStatus(cTechHeavyCavalry) == cTechStatusObtainable)
      {
         debugAttackWave("Starting Heavy Cavalry research plan.");
         researchSimpleTech(cTechHeavyCavalry, cUnitTypeStable, -1, 60);
         return;
      }
   }

   rule researchHeavyArchers
   active
   minInterval 360
   {
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechHeavyArchers) == cTechStatusActive)
   {
      xsDisableRule("researchHeavyArchers");
      return;
   }
   else if (kbTechGetStatus(cTechHeavyArchers) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Heavy Archers research plan.");
      researchSimpleTech(cTechHeavyArchers, cUnitTypeArcheryRange, -1, 60);
      return;
   }
   }

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

   rule researchIronArmor
   inactive
   minInterval 210
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

   rule researchIronShields
   inactive
   minInterval 270
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

   rule researchChampionCavalry
   active
   minInterval 180
   {
      xsSetRuleMinIntervalSelf(10);
      // Cease if we have it. Otherwise, research it.
      if (kbTechGetStatus(cTechChampionCavalry) == cTechStatusActive)
      {
         xsDisableRule("researchChampionCavalry");
         return;
      }
      else if (kbTechGetStatus(cTechChampionCavalry) == cTechStatusObtainable)
      {
         debugAttackWave("Starting Champion Cavalry research plan.");
         researchSimpleTech(cTechChampionCavalry, cUnitTypeStable, -1, 60);
         return;
      }
   }

   rule researchChampionInfantry
   active
   minInterval 90
   {
      xsSetRuleMinIntervalSelf(10);
      // Cease if we have it. Otherwise, research it.
      if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusActive)
      {
         xsDisableRule("researchChampionInfantry");
         return;
      }
      else if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusObtainable)
      {
         debugAttackWave("Starting Champion Infantry research plan.");
         researchSimpleTech(cTechChampionInfantry, cUnitTypeMilitaryAcademy, -1, 60);
         return;
      }
   }

   rule researchChampionArchers
   active
   minInterval 360
   {
      xsSetRuleMinIntervalSelf(10);
      // Cease if we have it. Otherwise, research it.
      if (kbTechGetStatus(cTechChampionArchers) == cTechStatusActive)
      {
         xsDisableRule("researchChampionArchers");
         return;
      }
      else if (kbTechGetStatus(cTechChampionArchers) == cTechStatusObtainable)
      {
         debugAttackWave("Starting Champion Archers research plan.");
         researchSimpleTech(cTechChampionArchers, cUnitTypeArcheryRange, -1, 60);
         return;
      }
   }

   rule researchDraftHorses
   active
   minInterval 240
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
         researchSimpleTech(cTechDraftHorses, cUnitTypeFortress, -1, 60);
         return;
      }
   }

   rule researchEngineers
   active
   minInterval 480
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
         researchSimpleTech(cTechEngineers, cUnitTypeFortress, -1, 60);
         return;
      }
   }

   rule researchHandOfTalos
   active
   minInterval 120
   {
      xsSetRuleMinIntervalSelf(10);
      // Cease if we have it. Otherwise, research it.
      if (kbTechGetStatus(cTechHandOfTalos) == cTechStatusActive)
      {
         xsDisableRule("researchHandOfTalos");
         return;
      }
      else if (kbTechGetStatus(cTechHandOfTalos) == cTechStatusObtainable)
      {
         debugAttackWave("Starting Hand of Talos research plan.");
         researchSimpleTech(cTechHandOfTalos, cUnitTypeTemple, -1, 60);
         return;
      }
   }

   rule researchShoulderOfTalos
   active
   minInterval 480
   {
      xsSetRuleMinIntervalSelf(10);
      // Cease if we have it. Otherwise, research it.
      if (kbTechGetStatus(cTechShoulderOfTalos) == cTechStatusActive)
      {
         xsDisableRule("researchShoulderOfTalos");
         return;
      }
      else if (kbTechGetStatus(cTechShoulderOfTalos) == cTechStatusObtainable)
      {
         debugAttackWave("Starting Shoulder of Talos research plan.");
         researchSimpleTech(cTechShoulderOfTalos, cUnitTypeTemple, -1, 60);
         return;
      }
   }

   rule researchQuarry
   active
   minInterval 480
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


// Called from the triggers to enable attacks.
   void updateParameters()
   {

      // Delay the first attack until after Arkantos reaches the TC.
      gAttackStartDelay += xsGetTime();
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackFirstAttackStartSize);
      gAttackWave.setMinAttackSize(gAttackFirstAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      
      // Only attack with cavalry during the first attack.
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      gAttackWave.addAttackUnitType(gThirdLandUnit);
      return;
   }