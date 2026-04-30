//==============================================================================
/* fott04_p2.xs

   Red Greek player owning the base in the north (Troy). Sends attacks Hoplites & Hippeis.
*/
//==============================================================================
// Includes

include "core\main.xs"; // The bulk of the AI.
include "campaign\global_spc_modifiers.xs"; // global modifiers for difficulties.

mutable void setupTradingPlans(void) {}
mutable void setupPatrolPlans(vector gatherPoint = cInvalidVector) {}

//==============================================================================
/*	Rules

   Add scenario-specific rules & functions in the section below.
*/
//==============================================================================

float gTrainDelay = 10; // In seconds.
float gMythTrainDelay = 20; // In seconds.
float gHeroTrainDelay = 60; // In seconds.

int gFirstLandUnit = cUnitTypeHoplite; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 10;
int gSecondLandUnit = cUnitTypeHippeus; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 14;
int gThirdLandUnit = cUnitTypePegasus; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 1;
int gFourthLandUnit = cUnitTypeMinotaur; // Hard and Titan only.
float gMaintainFourthLandUnitAmount = 2;
int gFifthLandUnit = cUnitTypeManticore; // Titan only.
float gMaintainFifthLandUnitAmount = 2;
int gSixthLandUnit = cUnitTypePerseus; // Hard and Titan only.
float gMaintainSixthLandUnitAmount = 1;

float gMaxVillagerCount = 5;
float gMaxCaravanCount = 3;

float gAttackStartDelay = 360; // In seconds.
float gAttackWaveInterval = 300; // In seconds.
float gAttackStartSize = 5;
float gAttackMaxSize = 12;
float gHeroicAgeUpTime = 480; // In seconds.
float gMythicAgeUpTime = 2400; // In seconds.

bool gLostMarket = false; // Flipped by function lostMarket()

int gDefendPlan = -1;
int gPatrolPlanLeft = -1;
int gPatrolPlanRight = -1;
int gTradePlanP3 = -1;
int gTradePlanP4 = -1;
int gTradePlanP2 = -1;

// Extra defend points (for myth units and Perseus)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;

Strategy scenarioAttackWaveStrategy()
{

   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugAttackWave("***Starting Scenario Attack Wave Strategy***");
      xsEnableRule("marketDestroyed");
      xsEnableRule("useRestoration");
      xsEnableRule("updateDefendPlan");
      xsEnableRule("managePlayer3Trading");
      xsEnableRule("managePlayer4Trading");
      xsEnableRule("managePlayer2Trading");

      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================
      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gTrainDelay *= gDifficultyModifierTrainDelay;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      
      // Make certain parameters way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gMaintainFirstLandUnitAmount = 6;
         gMaintainSecondLandUnitAmount = 8;

         gAttackStartSize = 3;
         gAttackMaxSize = 5;
      }

      gHeroicAgeUpTime = gHeroicAgeUpTime * gDifficultyModifierAgeUp;
      gMythicAgeUpTime = gMythicAgeUpTime * gDifficultyModifierAgeUp;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Pegasus

      // Only train Minotaurs and Perseus on Hard and Titan.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
         data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
         // Only train Manticores on Titan.
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
         }
      }

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);

      if (cDifficultyCurrent >= cDifficultyHard)
      {
         data.setTrainDelay(gFourthLandUnit, gMythTrainDelay);
         data.setTrainDelay(gSixthLandUnit, gHeroTrainDelay);
         // Only train Manticores on Titan.
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            data.setTrainDelay(gSixthLandUnit, gMythTrainDelay);
         }
      }

      // Maintain caravans, amount scaling by difficulty.
      // gMaxCaravanCount *= gDifficultyModifierMaintainVillager;
      // data.addUnitToMaintain(cUnitTypeCaravanGreek, gMaxCaravanCount, 70);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      gAttackWave.displayFirstAttackStats();

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      gTimeToFarm = true; // Stay within our base.
      
      // We want to research our military upgrades automatically.
      data.setFlag(cStrategyFlagAutoResearchMilitaryUpgrades, true);
      xsEnableRule("militaryUpgradeManager");

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(203.0, 0, 228.0); // Between the Temple and the Fortress that are in front of the Trojan Gate.
      vector targetPoint = vector(90.0, 0.0, 100.0); // Left of the player's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(100.0, 0.0, 244.0)); // Walk to the left side of the map.
      kbPathAddWaypoint(pathID1, vector(83.0, 0.0, 145.0));
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      // Only 5 priority so our patrol plans can steal.
      gDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 20.0, startPoint, 5);
      aiPlanAddUnitType(gDefendPlan, cUnitTypeHoplite, 0, 0, 200);
      aiPlanAddUnitType(gDefendPlan, cUnitTypeHippeus, 0, 0, 200);

      // Extra defend plans on Hard and Titan.
      vector Defend_1 = vector(215.0, 0.0, 223.0); // In front of the Temple.
      vector Defend_2 = vector(197.0, 0.0, 241.0); // In front of the Fortress.

      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gDefendPlan1 = createDefendPlan("Defend Plan 1", kbBaseGetMainID(cMyID), 20.0, Defend_1, 10, Defend_1);
         aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 25.0);
         aiPlanAddUnitType(gDefendPlan1, gFourthLandUnit, 0, 0, 200); // Minotaurs
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            aiPlanAddUnitType(gDefendPlan1, gFifthLandUnit, 0, 0, 200); // Manticores
         }
         
         gDefendPlan2 = createDefendPlan("Defend Plan 2", kbBaseGetMainID(cMyID), 20.0, Defend_2, 10, Defend_2);
         aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 25.0);
         aiPlanAddUnitType(gDefendPlan2, gSixthLandUnit, 0, 0, 200); // Perseus
      }

      setupPatrolPlans(startPoint);
      setupTradingPlans();

      int explorePlanID = aiPlanCreate("Kataskopos Explore", cPlanExplore, -1);
      aiPlanSetPriority(explorePlanID, 99);
      aiPlanAddUnitType(explorePlanID, cUnitTypeKataskopos, 1, 1, 1);

      int explorePlanID2 = aiPlanCreate("Pegasus Explore", cPlanExplore, -1);
      aiPlanSetPriority(explorePlanID2, 99);
      aiPlanAddUnitType(explorePlanID2, cUnitTypePegasus, 1, 1, 1);

      // Divide the starting 8 Donkeys evenly over our 2 starting trade plans.
      int queryID = useSimpleUnitQuery(cUnitTypeCaravanGreek);
      int numResults = kbUnitQueryExecute(queryID);
      for (int i = 0; i < numResults; i++)
      {
         if (i % 2 == 0)
         {
            aiPlanAddUnit(gTradePlanP3, kbUnitQueryGetResult(queryID, i));
         }
         else
         {
            aiPlanAddUnit(gTradePlanP4, kbUnitQueryGetResult(queryID, i));
         }
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
      static bool maintainCaravans = true;

      static bool reachedHeroic = false;
      static bool reachedMythic = false;

      int age = kbPlayerGetAge(cMyID);

      int time = xsGetTime();
      if (done == false)
      {
         if (needResearchHeroic == true && age == cAge2 && time >= gHeroicAgeUpTime)
         {
            if (researchSimpleTech(cTechHeroicAgeApollo, cUnitTypeTownCenter, -1, 75) == true)
            {
               debugAttackWave("Starting Heroic Age research plan.");
               needResearchHeroic = false;
            }
         }
         else if (needResearchMythic == true && age == cAge3 && time >= gMythicAgeUpTime)
         {
            if (researchSimpleTech(cTechMythicAgeArtemis, cUnitTypeTownCenter, -1, 75) == true)
            {
               debugAttackWave("Starting Mythic Age research plan.");
               needResearchMythic = false;
            }
         }
         else if (age == cAge4)
         {
            done = true;
            if (cDifficultyCurrent >= cDifficultyTitan)
            {
               xsEnableRule("useEarthquake");
            }
         }
      }

      // * * * TECH RULES * * * //

      // CLASSICAL AGE //
      if (age >= cAge2)
      {
         // Techs for all difficulties:
         xsEnableRule("researchCopperWeapons");
         xsEnableRule("researchCopperArmor");
         xsEnableRule("researchCopperShields");

         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchMediumInfantry");
            xsEnableRule("researchMediumCavalry");
            xsEnableRule("researchMasons");
         }

         // Tech Rules for Hard and Titan:
         // Tech Rules for Titan only:
      }

      // HEROIC AGE //
      if (reachedHeroic == false && kbPlayerGetAge(cMyID) == cAge3)
      {
         // Tech Rules for All Difficulties:

         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchBronzeWeapons");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchBronzeArmor");
            xsEnableRule("researchBronzeShields");
            xsEnableRule("researchHeavyInfantry");
            xsEnableRule("researchHeavyCavalry");
            xsEnableRule("researchBoilingOil");
            xsEnableRule("researchArchitects");
            xsEnableRule("researchFortifiedWall");
            xsEnableRule("researchGuardTower");
            xsEnableRule("researchLevyInfantry");
         }

         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchLevyCavalry");
         }

         // Change the boolean back to true so the rules aren't enabled multiple times.
         reachedHeroic = true;
      }

      // MYTHIC AGE //
      if (reachedMythic == false && kbPlayerGetAge(cMyID) == cAge4)
      {
         // Tech Rules for All Difficulties:
         // Tech Rules for Moderate and Up:
         // Tech Rules for Hard and Titan:
         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchChampionCavalry");
            xsEnableRule("researchConscriptInfantry");
            xsEnableRule("researchConscriptCavalry");
         }
         // Change the boolean back to true so the rules aren't enabled multiple times.
         reachedMythic = true;
      }

      /*
      if (maintainCaravans == true && gTradePlanP3 <= -1 && gTradePlanP4 <= -1)
      {
         // Per the design, if no allied Town Center is left standing, we stop retraining caravans.
         data.removeUnitToMaintain(cUnitTypeCaravanGreek);
         maintainCaravans = false;
      }
      */

      // Wait to reduce the number of units trained.
      static bool army_nerfed = false;
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         if(army_nerfed == false && gLostMarket == true)
         {
            gMaintainFirstLandUnitAmount *= 0.75; // Train fewer Hoplites.
            gMaintainSecondLandUnitAmount *= 0.75; // Train fewer Hippeis.

            data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
            data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);

            // Update attack size parameters based on the halved number of trained Hoplites and Hippeis.
            gAttackMaxSize *= 0.5; // Decrease attack size by -50%.
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
            army_nerfed = true;
         }
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott04StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(298.00, 0.00, 298.00), 80);

   setOverrideStrategy(fott04StrategySetup);

   gOverrideFarmCount = 8; // We can't have too many farms due to space restrictions.
   gOverrideOkToGatherGold = false;
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// Defend the Trojan Gate.
rule useRestoration
inactive
minInterval 5
{
   int numEnemies = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, 1, cUnitStateAlive, vector(223.0, 3.0, 246.0), 15.0);
   int numAllies = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive, vector(223.0, 3.0, 246.0), 15.0);
   debugAttackWave("numEnemies for casting Restoration " + numEnemies);
   debugAttackWave("numAllies for casting Restoration: " + numAllies);
   if (numEnemies >= 6 && numAllies >= 6)
   {
      if (aiCastGodPowerAtPosition(cProtoPowerRestoration, vector(223.0, 3.0, 246.0)) == true)
      {
         debugAttackWave("Casted Restoration!");
         xsDisableRule("useRestoration");
      }
   }
}

// If either of our outer gates are broken, focus defense efforts purely on the main gate. Avoid trickling units to outer gates.
rule updateDefendPlan
inactive
minInterval 5
{
   if ((getUnitCountByLocation(cUnitTypeWallGate, cMyID, cUnitStateAlive, vector(216.0, 0.0, 188.0), 10.0) <= 0) ||
       (getUnitCountByLocation(cUnitTypeWallGate, cMyID, cUnitStateAlive, vector(160.0, 0.0, 236.0), 10.0) <= 0))
   {
      debugAttackWave("Reducing Defend Plan engage range to 20.");
      aiPlanSetVariableFloat(gDefendPlan, cDefendPlanEngageRange, 0, 20.0);
      xsDisableRule("updateDefendPlan");
   }
}

// Cast Earthquake on 2+ forward military buildings of the player near our outer gates.
rule useEarthquake
inactive
minInterval 15
{
   int queryID = useSimpleUnitQuery(cUnitTypeMilitaryBuilding, 1, cUnitStateAlive, vector(216.0, 0.0, 188.0), 20.0);
   kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateSeeable);
   int numResults = kbUnitQueryExecute(queryID);
   if (numResults > 1)
   {
      if (aiCastGodPowerAtPosition(cProtoPowerEarthquake, vector(216.0, 0.0, 188.0)) == true)
      {
         debugAttackWave("Casted Earthquake on eastern outer gate!");
         xsDisableRule("useEarthquake");
      }
   }
   queryID = useSimpleUnitQuery(cUnitTypeMilitaryBuilding, 1, cUnitStateAlive, vector(160.0, 0.0, 236.0), 20.0);
   kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateSeeable);
   numResults = kbUnitQueryExecute(queryID);
   if (numResults > 1)
   {
      if (aiCastGodPowerAtPosition(cProtoPowerEarthquake, vector(160.0, 0.0, 236.0)) == true)
      {
         debugAttackWave("Casted Earthquake on western outer gate!");
         xsDisableRule("useEarthquake");
      }
   }
}

void setupPatrolPlans(vector gatherPoint = cInvalidVector)
{
   // Western Patrol plan.
   gPatrolPlanLeft = createDefendPlan("Patrol Plan Left", -1, 7.5, vector(150.0, 0.0, 240.0), 15, vector(150.0, 0.0, 240.0));
   aiPlanAddUnitType(gPatrolPlanLeft, cUnitTypeHippeus, 4, 4, 4);
   aiPlanSetFlag(gPatrolPlanLeft, cPlanFlagRequiresAllNeedUnits, true);
   aiPlanSetVariableBool(gPatrolPlanLeft, cDefendPlanPatrol, 0, true);
   aiPlanSetNumberVariableValues(gPatrolPlanLeft, cDefendPlanPatrolWaypoints, 6);
   aiPlanSetVariableVector(gPatrolPlanLeft, cDefendPlanPatrolWaypoints, 0, vector(150.0, 0.0, 240.0));
   aiPlanSetVariableVector(gPatrolPlanLeft, cDefendPlanPatrolWaypoints, 1, vector(124.0, 0.0, 250.0));
   aiPlanSetVariableVector(gPatrolPlanLeft, cDefendPlanPatrolWaypoints, 2, vector(90.0, 0.0, 246.0));
   aiPlanSetVariableVector(gPatrolPlanLeft, cDefendPlanPatrolWaypoints, 3, vector(49.0, 0.0, 217.0));
   aiPlanSetVariableVector(gPatrolPlanLeft, cDefendPlanPatrolWaypoints, 4, vector(90.0, 0.0, 246.0)); // Turn back.
   aiPlanSetVariableVector(gPatrolPlanLeft, cDefendPlanPatrolWaypoints, 5, vector(124.0, 0.0, 250.0));
   aiPlanSetVariableFloat(gPatrolPlanLeft, cDefendPlanEngageRange, 0, 30.0);

   // Eastern Patrol plan.
   gPatrolPlanRight = createDefendPlan("Patrol Plan Right", -1, 7.5, vector(222.0, 0.0, 178.0), 10, vector(222.0, 0.0, 178.0));
   aiPlanAddUnitType(gPatrolPlanRight, cUnitTypeHippeus, 4, 4, 4);
   aiPlanSetFlag(gPatrolPlanRight, cPlanFlagRequiresAllNeedUnits, true);
   aiPlanSetVariableBool(gPatrolPlanRight, cDefendPlanPatrol, 0, true);
   aiPlanSetNumberVariableValues(gPatrolPlanRight, cDefendPlanPatrolWaypoints, 10);
   aiPlanSetVariableVector(gPatrolPlanRight, cDefendPlanPatrolWaypoints, 0, vector(222.0, 0.0, 178.0));
   aiPlanSetVariableVector(gPatrolPlanRight, cDefendPlanPatrolWaypoints, 1, vector(265.0, 0.0, 162.0));
   aiPlanSetVariableVector(gPatrolPlanRight, cDefendPlanPatrolWaypoints, 2, vector(275.0, 0.0, 134.0));
   aiPlanSetVariableVector(gPatrolPlanRight, cDefendPlanPatrolWaypoints, 3, vector(268.0, 0.0, 116.0));
   aiPlanSetVariableVector(gPatrolPlanRight, cDefendPlanPatrolWaypoints, 4, vector(247.0, 0.0, 90.0));
   aiPlanSetVariableVector(gPatrolPlanRight, cDefendPlanPatrolWaypoints, 5, vector(264.0, 8.0, 60.0));
   aiPlanSetVariableVector(gPatrolPlanRight, cDefendPlanPatrolWaypoints, 6, vector(247.0, 0.0, 90.0)); // Turn back.
   aiPlanSetVariableVector(gPatrolPlanRight, cDefendPlanPatrolWaypoints, 7, vector(268.0, 0.0, 116.0));
   aiPlanSetVariableVector(gPatrolPlanRight, cDefendPlanPatrolWaypoints, 8, vector(275.0, 0.0, 134.0));
   aiPlanSetVariableVector(gPatrolPlanRight, cDefendPlanPatrolWaypoints, 9, vector(265.0, 0.0, 162.0));
   aiPlanSetVariableFloat(gPatrolPlanRight, cDefendPlanEngageRange, 0, 30.0);
}

// Switch what patrol plan takes priority over the other, to make sure we patrol both paths if we have too few Hippeis to
// populate both. We switch every 2 minutes.
/*
rule switchPatrol
inactive
minInterval 120
{
   // Plan left starts out on 15 priority.
   static bool leftPrio = true;
   if (leftPrio == true)
   {
      aiPlanSetPriority(gPatrolPlanLeft, 10);
      aiPlanSetPriority(gPatrolPlanRight, 15);
      leftPrio = false;
   }
   else
   {
      aiPlanSetPriority(gPatrolPlanLeft, 15);
      aiPlanSetPriority(gPatrolPlanRight, 10);
      leftPrio = true;
   }
}
*/

void setupTradingPlans()
{
   // Trade Plans.
      int marketID = getUnit(cUnitTypeMarket);
      int targetTownCenterID = -1;

      // Trade to P3 Town Center.
      targetTownCenterID = getUnit(cUnitTypeTownCenter, 3);
      gTradePlanP3 = aiPlanCreate("Trade With P3", cPlanTrade);
      aiPlanSetVariableInt(gTradePlanP3, cTradePlanTargetUnitTypeID, 0, cUnitTypeTownCenter);
      aiPlanSetVariableInt(gTradePlanP3, cTradePlanTargetUnitID, 0, targetTownCenterID);
      aiPlanSetPriority(gTradePlanP3, 100);
      aiPlanAddUnitType(gTradePlanP3, cUnitTypeCaravanGreek, 0, 0, 4);
      aiPlanSetVariableInt(gTradePlanP3, cTradePlanMarketID, 0, marketID);
      aiPlanSetVariableBool(gTradePlanP3, cTradePlanUpdateTarget, 0, false);

      // Trade to P4 Town Center.
      targetTownCenterID = getUnit(cUnitTypeTownCenter, 4);
      gTradePlanP4 = aiPlanCreate("Trade With P4", cPlanTrade);
      aiPlanSetVariableInt(gTradePlanP4, cTradePlanTargetUnitTypeID, 0, cUnitTypeTownCenter);
      aiPlanSetVariableInt(gTradePlanP4, cTradePlanTargetUnitID, 0, targetTownCenterID);
      aiPlanSetPriority(gTradePlanP4, 100);
      aiPlanAddUnitType(gTradePlanP4, cUnitTypeCaravanGreek, 0, 0, 4);
      aiPlanSetVariableInt(gTradePlanP4, cTradePlanMarketID, 0, marketID);
      aiPlanSetVariableBool(gTradePlanP4, cTradePlanUpdateTarget, 0, false);
}

// If we lose our Market we need to destroy our trading plans.
rule marketDestroyed
inactive
minInterval 5
{
   if (getUnit(cUnitTypeMarket) < 0)
   {
      xsDisableRule("managePlayer3Trading");
      xsDisableRule("managePlayer4Trading");
      xsDisableRule("managePlayer2Trading");
      aiPlanDestroy(gTradePlanP3);
      aiPlanDestroy(gTradePlanP4);
      aiPlanDestroy(gTradePlanP2);
      aiPlanDestroy(gPatrolPlanRight);
      aiPlanDestroy(gPatrolPlanLeft);
      xsDisableRule("marketDestroyed");
   }
}

// If the Town Center belonging to P3 is destroyed we need to switch our trade routes.
// Check if we can still trade with P4.
rule managePlayer3Trading
inactive
minInterval 5
{
   if (getUnit(cUnitTypeTownCenter, 3) < 0)
   {
      if (getUnit(cUnitTypeTownCenter, 4) >= 0)
      {
         int[] units = new int(0, 0);
         if (gTradePlanP4 >= 0)
         {
            units = aiPlanGetUnits(gTradePlanP3);
            for (int i = 0; i < units.size(); i++)
            {
               aiPlanAddUnit(gTradePlanP4, units[i]);
            }
         }
      }

      aiPlanRemoveUnit(gTradePlanP4, cUnitTypeCaravanGreek);
      aiPlanAddUnitType(gTradePlanP4, cUnitTypeCaravanGreek, 0, 0, 8);

      aiPlanDestroy(gTradePlanP3);
      aiPlanDestroy(gPatrolPlanLeft);
      gTradePlanP3 = -1;
      xsDisableRule("managePlayer3Trading");
   }
}

// Same as above but for P4.
rule managePlayer4Trading
inactive
minInterval 5
{
   if (getUnit(cUnitTypeTownCenter, 4) < 0)
   {
      if (getUnit(cUnitTypeTownCenter, 3) >= 0)
      {
         int[] units = new int(0, 0);
         if (gTradePlanP3 >= 0)
         {
            units = aiPlanGetUnits(gTradePlanP4);
            for (int i = 0; i < units.size(); i++)
            {
               aiPlanAddUnit(gTradePlanP3, units[i]);
            }
         }
      }

      aiPlanRemoveUnit(gTradePlanP3, cUnitTypeCaravanGreek);
      aiPlanAddUnitType(gTradePlanP3, cUnitTypeCaravanGreek, 0, 0, 8);

      aiPlanDestroy(gTradePlanP4);
      aiPlanDestroy(gPatrolPlanRight);
      gTradePlanP4 = -1;
      xsDisableRule("managePlayer4Trading");
   }
}

// If both allied TCs are gone, then we have to trade with ourself.
rule managePlayer2Trading
inactive
minInterval 5
{   
   if (getUnit(cUnitTypeTownCenter, 4) < 0 && getUnit(cUnitTypeTownCenter, 3) < 0)
   {
      int marketID = getUnit(cUnitTypeMarket);
      int targetTownCenterID = -1;

      // Trade to P2 Town Center.
      targetTownCenterID = getUnit(cUnitTypeTownCenter, 2);
      gTradePlanP2 = aiPlanCreate("Trade With P2", cPlanTrade);
      aiPlanSetVariableInt(gTradePlanP2, cTradePlanTargetUnitTypeID, 0, cUnitTypeTownCenter);
      aiPlanSetVariableInt(gTradePlanP2, cTradePlanTargetUnitID, 0, targetTownCenterID);
      aiPlanSetPriority(gTradePlanP2, 100);
      aiPlanAddUnitType(gTradePlanP2, cUnitTypeCaravanGreek, 0, 0, 200);
      aiPlanSetVariableInt(gTradePlanP2, cTradePlanMarketID, 0, marketID);
      aiPlanSetVariableBool(gTradePlanP2, cTradePlanUpdateTarget, 0, false);

      // Re-assign our Donkeys.
      int queryID = useSimpleUnitQuery(cUnitTypeCaravanGreek);
      int numResults = kbUnitQueryExecute(queryID);
      for (int i = 0; i < numResults; i++)
      {
         aiPlanAddUnit(gTradePlanP2, kbUnitQueryGetResult(queryID, i));
      }

      int[] units = new int(0, 0);
      if (gTradePlanP3 >= 0)
      {
         units = aiPlanGetUnits(gTradePlanP4);
         for (int i = 0; i < units.size(); i++)
         {
            aiPlanAddUnit(gTradePlanP2, units[i]);
         }
      }

      int[] units2 = new int(0, 0);
      if (gTradePlanP4 >= 0)
      {
         units2 = aiPlanGetUnits(gTradePlanP3);
         for (int i = 0; i < units2.size(); i++)
         {
            aiPlanAddUnit(gTradePlanP2, units2[i]);
         }
      }

      gTradePlanP2 = -1;
      xsDisableRule("managePlayer2Trading");
   }
}


// TECH RULES //

rule researchCopperWeapons
inactive
minInterval 120
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechCopperWeapons) == cTechStatusActive)
   {
      xsDisableRule("researchCopperWeapons");
      return;
   }
   else if (kbTechGetStatus(cTechCopperWeapons) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Copper Weapons research plans.");
      researchSimpleTech(cTechCopperWeapons, cUnitTypeArmory, -1, 60);
   }
}

rule researchCopperArmor
inactive
minInterval 180
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechCopperArmor) == cTechStatusActive)
   {
      xsDisableRule("researchCopperArmor");
      return;
   }
   else if (kbTechGetStatus(cTechCopperArmor) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Copper Armor research plans.");
      researchSimpleTech(cTechCopperArmor, cUnitTypeArmory, -1, 60);
   }
}

rule researchCopperShields
inactive
minInterval 300
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechCopperShields) == cTechStatusActive)
   {
      xsDisableRule("researchCopperShields");
      return;
   }
   else if (kbTechGetStatus(cTechCopperShields) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Copper Shields research plan.");
      researchSimpleTech(cTechCopperShields, cUnitTypeArmory, -1, 60);
      return;
   }
}

rule researchMediumInfantry
inactive
minInterval 240
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechMediumInfantry) == cTechStatusActive)
   {
      xsDisableRule("researchMediumInfantry");
      return;
   }
   else if (kbTechGetStatus(cTechMediumInfantry) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Medium Infantry research plan.");
      researchSimpleTech(cTechMediumInfantry, cUnitTypeMilitaryAcademy, -1, 60);
      return;
   }
}

rule researchMediumCavalry
inactive
minInterval 270
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechMediumCavalry) == cTechStatusActive)
   {
      xsDisableRule("researchMediumCavalry");
      return;
   }
   else if (kbTechGetStatus(cTechMediumCavalry) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Medium Cavalry research plan.");
      researchSimpleTech(cTechMediumCavalry, cUnitTypeStable, -1, 60);
      return;
   }
}

rule researchMasons
inactive
minInterval 400
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

rule researchBronzeWeapons
inactive
minInterval 240
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

rule researchBronzeArmor
inactive
minInterval 360
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

rule researchBronzeShields
inactive
minInterval 480
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
minInterval 180
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

rule researchHeavyCavalry
active
minInterval 360
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

rule researchFortifiedWall
inactive
minInterval 90
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

rule researchIronWeapons
inactive
minInterval 320
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

rule researchChampionCavalry
active
minInterval 360
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

rule researchLevyInfantry
active
minInterval 360
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechLevyInfantry) == cTechStatusActive)
   {
      xsDisableRule("researchLevyInfantry");
      return;
   }
   else if (kbTechGetStatus(cTechLevyInfantry) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Levy Infantry research plan.");
      researchSimpleTech(cTechLevyInfantry, cUnitTypeMilitaryAcademy, -1, 60);
      return;
   }
}

rule researchLevyCavalry
active
minInterval 360
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechLevyCavalry) == cTechStatusActive)
   {
      xsDisableRule("researchLevyCavalry");
      return;
   }
   else if (kbTechGetStatus(cTechLevyCavalry) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Levy Cavalry research plan.");
      researchSimpleTech(cTechLevyCavalry, cUnitTypeStable, -1, 60);
      return;
   }
}

rule researchConscriptInfantry
active
minInterval 360
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechConscriptInfantry) == cTechStatusActive)
   {
      xsDisableRule("researchConscriptInfantry");
      return;
   }
   else if (kbTechGetStatus(cTechConscriptInfantry) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Conscript Infantry research plan.");
      researchSimpleTech(cTechConscriptInfantry, cUnitTypeMilitaryAcademy, -1, 60);
      return;
   }
}

rule researchConscriptCavalry
active
minInterval 360
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechConscriptCavalry) == cTechStatusActive)
   {
      xsDisableRule("researchConscriptCavalry");
      return;
   }
   else if (kbTechGetStatus(cTechConscriptCavalry) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Conscript Cavalry research plan.");
      researchSimpleTech(cTechConscriptCavalry, cUnitTypeStable, -1, 60);
      return;
   }
}

rule researchGuardTower
inactive
minInterval 150
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

// If we lose our Market, then we can no longer dispatch very large armies.
void lostMarket()
{
   gLostMarket = true;
}

// Use Bolt on easier difficulties. Activated once Bolt is granted to Troy.
rule useBolt
inactive
minInterval 1
{
   // int planID = -1;
   // int unitID = -1;
   // int numMUs = -1;
   int targetID = -1;
   int targetID2 = -1;
   // int[] planIDs = aiPlanGetIDsByType(cPlanAttack);

   targetID = getUnitByLocation(cUnitTypeMythUnit, 1, cUnitStateAlive, vector(228.0, 0.0, 252.0), 30.0);
   debugAttackWave("MUs found: " + targetID);
   if (targetID >= 0)
   {
      if (aiCastGodPowerAtUnit(cProtoPowerBolt, targetID) == true)
      {
         debugAttackWave("Casted Bolt!");
         xsDisableRule("useBolt");
      }
   }
   else if (targetID == -1)
   {
      targetID2 = getUnitByLocation(cUnitTypeMilitaryUnit, 1, cUnitStateAlive, vector(228.0, 0.0, 252.0), 30.0);
      debugAttackWave("Others found: " + targetID2);
      if (targetID2 >= 0)
      {
         if (aiCastGodPowerAtUnit(cProtoPowerBolt, targetID2) == true)
         {
            debugAttackWave("Casted Bolt!");
            xsDisableRule("useBolt");
         }
      }
   }
}


/*
   for (int i = 0; i < planIDs.size(); i++)
   {
      planID = planIDs[i];
      if (aiPlanGetParentID(planID) == -1)
      {
         // We just take the first unit to scan from.
         unitID = aiPlanGetUnitIDByIndex(planID, 0);
         if (unitID >= 0)
         {
            numMUs = getUnitCountByLocation(cUnitTypeMythUnit, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 30.0);
            debugAttackWave("numMUs for casting Bolt: " + numMUs);
            if (numMUs >= 1)
            {
               // Grab an enemy Myth Unit.
               targetID = getUnitByLocation(cUnitTypeAbstractWall, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 15.0);
               if (targetID >= 0)
               {
                  if (aiCastGodPowerAtPosition(cProtoPowerBolt, kbUnitGetPosition(unitID)) == true)
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

*/