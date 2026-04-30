//==============================================================================
/* tgg08_p3.xs
   
   Followers of Kronos (Kronos)

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

int gFirstLandUnit = cUnitTypeTurma; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 6;
int gSecondLandUnit = cUnitTypeMurmillo; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 5;
int gThirdLandUnit = cUnitTypePromethean; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 2;
int gFourthLandUnit = cUnitTypeArcus; // Gets trained starting in Heroic.
float gMaintainFourthLandUnitAmount = 5;
int gFifthLandUnit = cUnitTypeSatyr; // Gets trained starting in Heroic.
float gMaintainFifthLandUnitAmount = 1;
int gSixthLandUnit = cUnitTypeCentimanus; // Gets trained starting in Mythic.
float gMaintainSixthLandUnitAmount = 1;
int gSeventhLandUnit = cUnitTypeFireSiphon; // Gets trained starting in Mythic.
float gMaintainSeventhLandUnitAmount = 1;

float gMaxVillagerCount = 6;
float gMaxFishingShipCount = 1;

float gAttackStartDelay = 420; // In seconds.
float gAttackWaveInterval = 300; // In seconds.
float gAttackStartSize = 4;
float gAttackMaxSize = 15;

float gSecondAttackStartDelay = 360; // In seconds.
float gSecondAttackInterval = 300; // In seconds.
float gSecondAttackStartSize = 5;
float gSecondAttackMaxSize = 8;

float gMythicAgeUpTime = 1200; // In seconds.

vector gOurTCLocation = vector(27.0, 0.0, 117.0);

int gLandDefendPlan = -1;

Strategy scenarioAttackWaveStrategy()
{

   xsEnableRule("useValor");
   xsEnableRule("useChaos");
   xsEnableRuleGroup("ruleGroupBuildPlans");

   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugStrategy("***Starting Scenario Attack Wave Strategy***");
      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================
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

      gSecondAttackStartDelay *= gDifficultyModifierFirstAttack;
      gSecondAttackInterval *= gDifficultyModifierAttackInterval;
      gSecondAttackStartSize *= gDifficultyModifierAttackSizes;
      gSecondAttackMaxSize *= gDifficultyModifierAttackSizes;

      gTrainDelay *= gDifficultyModifierTrainDelay;
      gMythicAgeUpTime *= gDifficultyModifierAgeUp;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Turma
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Murmillo
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Promethean
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Arcus
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount); // Satyr

      // Centimanus and Fire Siphons are maintained upon reaching Mythic.
   
      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);      // Turma
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);     // Murmillo
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);      // Promethean
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);     // Arcus
      data.setTrainDelay(gFifthLandUnit, gTrainDelay);      // Satyr
      data.setTrainDelay(gSixthLandUnit, gTrainDelay);      // Centimanus
      data.setTrainDelay(gSeventhLandUnit, gTrainDelay);    // Fire Siphon

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);  // Turma
      gAttackWave.addAttackUnitType(gSecondLandUnit); // Murmillo
      gAttackWave.addAttackUnitType(gThirdLandUnit);  // Promethean
      gAttackWave.addAttackUnitType(gFourthLandUnit); // Arcus
      gAttackWave.addAttackUnitType(gFifthLandUnit);  // Satyr

      gSecondAttackWave.setName("gSecondAttackWave");
      gSecondAttackWave.setAttackStartTime(gSecondAttackStartDelay);
      gSecondAttackWave.setAttackInterval(gSecondAttackInterval);
      gSecondAttackWave.setAttackSize(gSecondAttackStartSize);
      gSecondAttackWave.setMaxAttackSize(gSecondAttackMaxSize);
      gSecondAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gSecondAttackWave.setMinAttackSize(gSecondAttackStartSize);
      gSecondAttackWave.addAttackUnitType(gFirstLandUnit);  // Only Turma

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticMainBaseTCRebuild, true);
      data.setFlag(cStrategyFlagAutomaticFishing, true);

      gAttackWave.setPlayerToAttack(1); // Attack P1!
      gSecondAttackWave.setPlayerToAttack(1); // Attack P1!

      // Where does our attack start and end.
      vector startPoint = vector(48.0, 0.0, 137.0); // By our town.
      vector targetPoint = vector(270.0, 0.0, 265.0);

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.

      // First route, used by the Main attacks.
      int routeMainID = kbCreateAttackRouteWithPath("Main Route To P1", startPoint, targetPoint);
      int pathMainID1 = kbPathCreate("Main Path 1");  // Via the rightmost gate, keeping close to the center lake before attacking TC directly from the west.
      kbPathAddWaypoint(pathMainID1, startPoint);
      kbPathAddWaypoint(pathMainID1, vector(110.0, 0.0, 136.0));
      kbPathAddWaypoint(pathMainID1, vector(169.0, 0.0, 160.0));
      kbPathAddWaypoint(pathMainID1, vector(160.0, 0.0, 212.0));
      kbPathAddWaypoint(pathMainID1, targetPoint);
      kbAttackRouteAddPath(routeMainID, pathMainID1);

      int pathMainID2 = kbPathCreate("Main Path 2");  // Via the rightmost gate, going around the underside of the round cliff before attacking TC directly from the west.
      kbPathAddWaypoint(pathMainID2, startPoint);
      kbPathAddWaypoint(pathMainID2, vector(110.0, 0.0, 136.0));
      kbPathAddWaypoint(pathMainID2, vector(125.0, 0.0, 197.0));
      kbPathAddWaypoint(pathMainID2, vector(160.0, 0.0, 212.0));
      kbPathAddWaypoint(pathMainID2, targetPoint);
      kbAttackRouteAddPath(routeMainID, pathMainID2);

      int pathMainID3 = kbPathCreate("Main Path 3");  // Via the leftmost gate, sweeping the area below the eastern lake before attacking TC directly from the south.
      kbPathAddWaypoint(pathMainID3, startPoint);
      kbPathAddWaypoint(pathMainID3, vector(67.0, 0.0, 200.0));
      kbPathAddWaypoint(pathMainID3, vector(111.0, 0.0, 238.0));
      kbPathAddWaypoint(pathMainID3, vector(160.0, 0.0, 212.0));
      kbPathAddWaypoint(pathMainID3, targetPoint);
      kbAttackRouteAddPath(routeMainID, pathMainID3);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeMainID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      // Second route, used by the Turma Raid attacks.
      int routeRaidID = kbCreateAttackRouteWithPath("Raid Route To P1", startPoint, targetPoint);
      int pathRaidID1 = kbPathCreate("Raid Path 1");  // Via the rightmost gate, keeping close to the center lake before attacking TC directly from the west.
      kbPathAddWaypoint(pathRaidID1, startPoint);
      kbPathAddWaypoint(pathRaidID1, vector(94.0, 0.0, 79.0));
      kbPathAddWaypoint(pathRaidID1, vector(196.0, 0.0, 101.0));
      kbPathAddWaypoint(pathRaidID1, vector(226.0, 0.0, 97.0));
      kbPathAddWaypoint(pathRaidID1, vector(249.0, 0.0, 161.0));
      kbPathAddWaypoint(pathRaidID1, targetPoint);
      kbAttackRouteAddPath(routeRaidID, pathRaidID1);

      int pathRaidID2 = kbPathCreate("Raid Path 2");  // Via the rightmost gate, going around the underside of the round cliff before attacking TC directly from the west.
      kbPathAddWaypoint(pathRaidID2, startPoint);
      kbPathAddWaypoint(pathRaidID2, vector(75.0, 0.0, 109.0));
      kbPathAddWaypoint(pathRaidID2, vector(109.0, 0.0, 134.0));
      kbPathAddWaypoint(pathRaidID2, vector(212.0, 0.0, 166.0));
      kbPathAddWaypoint(pathRaidID2, vector(249.0, 0.0, 161.0));
      kbPathAddWaypoint(pathRaidID2, targetPoint);
      kbAttackRouteAddPath(routeRaidID, pathRaidID2);

      gSecondAttackWave.setGatherPoint(startPoint);
      gSecondAttackWave.setTargetPoint(targetPoint);
      gSecondAttackWave.setAttackRouteID(routeRaidID);
      gSecondAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      // Create a general-purpose defend plan to keep existing military occupied and gathered.
      gLandDefendPlan = createDefendPlan("Primary Land Defend", -1, 20.0, startPoint, 10, startPoint);
      aiPlanSetVariableFloat(gLandDefendPlan, cDefendPlanEngageRange, 0, 50.0);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      static bool reachedAge4 = false;
      int age = kbPlayerGetAge(cMyID);
      int time = xsGetTime();
      if (done == false)
      {
         if (age < cAge4 && time >= gMythicAgeUpTime)
         {
            researchSimpleTech(cTechMythicAgeHelios, cUnitTypeTownCenter, -1, 75);
         }
         if (age >= cAge4 && reachedAge4 == false)
         {
            data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount); // Centimanus
            data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount); // Fire Siphon
            gAttackWave.addAttackUnitType(gSixthLandUnit);
            gAttackWave.addAttackUnitType(gSeventhLandUnit);
            reachedAge4 = true;
            done = true;
         }
      }

      // *** Gradually increase the minimum attack size as the mission progresses. ***

      // Don't scale the attacks like this on Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         static int elapsed_time = 60; // Wait 120 + 60 seconds before the first size increase.
         int increase_interval = xsGetTime() - elapsed_time;

         // Increase the Attack Start Size every 120 seconds.
         if (increase_interval >= 120)
         {
            // Run this as long as the minimum size is lower than the max size.
            if (gAttackStartSize < gAttackMaxSize)
            {
               gAttackStartSize *= 1.2; // Increases by 20 percent.
               gAttackWave.setAttackSize(gAttackStartSize);
               gAttackWave.update();
               elapsed_time = xsGetTime();
            }
            // Stop running this if gAttackStartSize catches up to the max attack size.
            else if (gAttackStartSize > gAttackMaxSize)
            {
               gAttackStartSize = gAttackMaxSize;
               gAttackWave.setAttackSize(gAttackStartSize);
               gAttackWave.update();
            }
         }
      }

      // New Tech Rules
      if (age >= cAge3)
      {
         // All Difficulties:
         researchSimpleTech(cTechBronzeWeapons, cUnitTypeArmory, -1, 60);

         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechHeavyInfantry, cUnitTypeMilitaryBarracks, -1, 60);
            researchSimpleTech(cTechHeavyArchers, cUnitTypeMilitaryBarracks, -1, 60);
            researchSimpleTech(cTechDraftHorses, cUnitTypePalace, -1, 60);
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            researchSimpleTech(cTechHeavyCavalry, cUnitTypeCounterBarracks, -1, 60);
            researchSimpleTech(cTechArchitects, cUnitTypeTownCenter, -1, 60);
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            researchSimpleTech(cTechGemini, cUnitTypeTemple, -1, 60);
         }
      }
      if (age >= cAge4)
      {
         // All Difficulties:

         // Moderate and Up:

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechChampionInfantry, cUnitTypeMilitaryBarracks, -1, 60);
            researchSimpleTech(cTechPetrification, cUnitTypePalace, -1, 60);
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            researchSimpleTech(cTechChampionArchers, cUnitTypeMilitaryBarracks, -1, 60);
            researchSimpleTech(cTechChampionCavalry, cUnitTypeCounterBarracks, -1, 60);
            researchSimpleTech(cTechHaloOfTheSun, cUnitTypePalace, -1, 60);
            researchSimpleTech(cTechIronArmor, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
         }
      }


      gAttackWave.update();
      gSecondAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}


// Set up the strategy.
void tna08StrategySetup()
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
   gMaxFishingShipCount *= gDifficultyModifierMaintainFishing;

   gOverrideClosestFishLocation = vector(31.00, 0.00, 173.00);
   gMaxFishDockScanRange = 560;

   gMainGatherBase = createOverrideGatherBase(vector(22.00, 0.00, 135.00), 38);

   setOverrideStrategy(tna08StrategySetup);

   gOverrideFarmCount = 6; // Don't overdo the Farms.
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, gOurTCLocation, 15.0);
      kbBuildingPlacementAddPositionInfluence(bpID, gOurTCLocation, 100.0, 15.0, cFalloffLinear);
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

// Called from the triggers to cast Vortex and add affected units into an attack plan.
void useVortex()
{
   int[] plans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
   int numPlans = plans.size();
   if (numPlans <= 0)
   {
      // Create a new attack plan if needed.
      int attackPlanID = aiPlanCreate("Vortex attack wave!", cPlanAttack);
      aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetMode, 0, cAttackPlanTargetModePoint);
      aiPlanSetVariableVector(attackPlanID, cAttackPlanTargetPoint, 0, vector(160.0, 0.0, 212.0));
      aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetPlayerID, 0, 1); // Attack Player 1!
      aiPlanSetVariableVector(attackPlanID, cAttackPlanGatherPoint, 0, vector(160.0, 0.0, 212.0));
      aiPlanSetVariableFloat(attackPlanID, cAttackPlanGatherDistance, 0, 50.0);
      aiPlanSetVariableFloat(attackPlanID, cAttackPlanAttackModeEngageRange, 0, 50.0);

      int routeVortexID = kbCreateAttackRouteWithPath("Vortex Route To Guardian", vector(158.0, 0.0, 209.0), vector(160.0, 0.0, 212.0));
      int pathVortexID = kbPathCreate("Vortex Path");
      kbPathAddWaypoint(pathVortexID, vector(158.0, 0.0, 209.0));
      kbPathAddWaypoint(pathVortexID, vector(160.0, 0.0, 212.0));
      kbAttackRouteAddPath(routeVortexID, pathVortexID);

      aiPlanSetVariableInt(attackPlanID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
      aiPlanSetVariableInt(attackPlanID, cAttackPlanAttackRouteID, 0, routeVortexID);
      setDefaultAttackPlanTargetUnitTypes(attackPlanID);
      aiPlanSetVariableInt(attackPlanID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeNoTarget);
      aiPlanAddUnitType(attackPlanID, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
      transferAllUnitsBetweenTwoPlans(gLandDefendPlan, attackPlanID);
      aiPlanSetPriority(attackPlanID, 90); // Very high priority. Use plenty of units.

      // Add our new plan.
      plans = aiPlanGetIDsByType(cPlanAttack);
   }
   for (int i = 0; i < plans.size(); i++)
   {
      if (aiCastGodPowerAtPosition(cProtoPowerVortex, vector(160.0, 0.0, 212.0)) == true)
      {
         debugGodPowers("Casted Vortex while utilizing attack plan: " + aiPlanGetName(plans[i]));
      }

      // Possibly necessary if reusing pre-existing attack plan, add relevant units to attack plan.
      int queryID = useSimpleUnitQuery(cUnitTypeMilitaryUnit);
      int numResults = kbUnitQueryExecute(queryID);
      int[] units = kbUnitQueryGetResults(queryID);
      for (int j = 0; j < numResults; j++)
      {
         // Exclude units which are already part of the relevant attack plan.
         if (kbUnitGetPlanID(units[j]) == plans[i])
         {
            aiPlanAddUnit(plans[i], units[j]);
         }
      }
   }
}

// Every 1:30, have a one-in-third chance of tranforming a unit into a hero with Valor.
rule useValor
inactive
minInterval 90
{
   // Don't attempt to invoke before 3 minutes have elapsed.
   if (xsGetTime() < 180)
   {
      return;
   }

   static int casts = 0;

   // Clear a ~33% chance to be able to invoke.
   int rand = xsRandInt(1, 100);
   if (rand > 33)
   {
      debugAttackWave("Failed the roll to invoke Valor. I rolled a " + rand + " while needing 33 or lower.");
      return;
   }

   int unitID = getUnit(cUnitTypeHumanSoldier);
   if (unitID >= 0)
   {
      // Invoke god power!
      if (aiCastGodPowerAtPosition(cProtoPowerValor, kbUnitGetPosition(unitID)) == true)
      {
         casts++;
         debugAttackWave("Casted Valor! (for a total of " + casts + "/6 times)");
         if (casts >= 6)
         {
            debugAttackWave("Ceasing Valor checks.");
            xsDisableRule("useValor");
            return;
         }
         else if (casts < 6)
         {
            return;
         }
      }
   }
}

// When reaching Heroic, look to invoke Chaos during an attack.
// Upon a successful invocation, wait 10 minutes before doing it again.
rule useChaos
inactive
minInterval 10
{
   static int casts = 0;
   static int delay = 0;
   if (delay > 0)
   {
      delay -= 10;   // Same as rule interval.
      return;
   }

   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   int unitID = -1;
   int numEnemies = -1;
   int targetID = -1;
   for (int i = 0; i < attackPlans.size(); i++)
   {
      if (aiPlanGetParentID(attackPlans[i]) == -1)
      {
         // We just take the first unit to scan from.
         unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
         if (unitID >= 0)
         {
            // Look for enemies.
            numEnemies = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 20.0);
            debugAttackWave("numEnemies for casting Chaos offensively: " + numEnemies);
            if (numEnemies >= 10)
            {
               // Grab an enemy unit.
               targetID = getUnitByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 20.0);
               if (targetID >= 0)
               {
                  // Invoke god power!
                  if (aiCastGodPowerAtPosition(cProtoPowerChaos, kbUnitGetPosition(targetID)) == true)
                  {
                     debugAttackWave("Casted Chaos!");
                     casts++;
                     if (casts == 1)
                     {
                        delay = 600;   // 10-minute delay before getting to invoke this again.
                        return;
                     }
                     else if (casts > 1)
                     {
                        xsDisableRule("useChaos");
                        return;
                     }
                  }
               }
            }
         }
      }
   }
}

void buildBuilding(int type = cUnitTypeManor, vector location = cInvalidVector)
{
   int builder = cUnitTypeVillagerAtlantean;
   int buildPlanID = aiPlanCreate("Build Plan", cPlanBuild, -1);
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID));
   kbBuildingPlacementSetBuildingPUID(bpID, type);
   kbBuildingPlacementSetCenterPosition(bpID, location, 10.0);
   kbBuildingPlacementSetStepSize(bpID, 2.0);
   kbBuildingPlacementSetBufferSpace(bpID, 0.0);
   kbBuildingPlacementAddPositionInfluence(bpID, location, 100.0, 50.0, cFalloffLinear);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, type);
   aiPlanAddUnitType(buildPlanID, builder, 1, 1, 1, false);
   aiPlanSetPriority(buildPlanID, 90);
}

rule buildCounterBarracks
inactive
minInterval 10
group ruleGroupBuildPlans
{
    int building = cUnitTypeCounterBarracks;
    vector location = vector(38.0, 0.0, 110.0);
    if (getUnit(building, cMyID, cUnitStateABQ) < 1)
    {
        buildBuilding(building, location);
    }
}

rule buildPalace
inactive
minInterval 30
group ruleGroupBuildPlans
{
   if (kbPlayerGetAge(cMyID) < cAge3)
   {
      return;
   }
    int building = cUnitTypePalace;
    vector location = vector(41.0, 0.0, 145.0);
    if (getUnit(building, cMyID, cUnitStateABQ) < 1)
    {
        buildBuilding(building, location);
    }
}

rule buildArmory
inactive
minInterval 60
group ruleGroupBuildPlans
{
    int building = cUnitTypeArmory;
    vector location = vector(14.0, 0.0, 83.0);
    if (getUnit(building, cMyID, cUnitStateABQ) < 1)
    {
        buildBuilding(building, location);
    }
}