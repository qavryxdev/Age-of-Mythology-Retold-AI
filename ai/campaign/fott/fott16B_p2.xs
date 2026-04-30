//==============================================================================
/* fott16B_p2.xs

   Blue Greek player owning the base in the north. Sends attacks of Hippeis, Prodromos, Hypaspists, Hoplites, Petroboli.
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

int gFirstLandUnit = cUnitTypeHippeus; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 8;
int gSecondLandUnit = cUnitTypeProdromos; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 8;
int gThirdLandUnit = cUnitTypeCentaur; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 4;
int gFourthLandUnit = cUnitTypeHoplite; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 7;
int gFifthLandUnit = cUnitTypePetrobolos; // Gets trained from the start.
float gMaintainFifthLandUnitAmount = 1;
int gSixthLandUnit = cUnitTypePegasus; // Gets trained from the start.
float gMaintainSixthLandUnitAmount = 1; // Not affected by the multiplier.

int gSeventhLandUnit = cUnitTypeJason; // Gets trained from the start.
float gMaintainSeventhLandUnitAmount = 1; // Not affected by the multiplier.
int gEighthLandUnit = cUnitTypeHippolyta; // Gets trained from the start.
float gMaintainEighthLandUnitAmount = 1; // Not affected by the multiplier.
int gNinthLandUnit = cUnitTypeAtalanta; // Gets trained from the start.
float gMaintainNinthLandUnitAmount = 1; // Not affected by the multiplier.
int gTenthLandUnit = cUnitTypeHelepolis; // Gets trained from the start.
float gMaintainTenthLandUnitAmount = 1;

int gFirstNavalUnit = cUnitTypeTrireme; // Once the player has a dock.
float gMaintainFirstNavalUnitAmount = 2;

float gFirstDelay = 60;
float gSecondDelay = 60;
float gThirdDelay = 40;
float gFourthDelay = 40;
float gFifthDelay = 90;
float gNavalDelay = 60;

float gMaxVillagerCount = 12;

float gAttackStartDelay = 300; // In seconds.
float gAttackWaveInterval = 240; // In seconds.
float gAttackStartSize = 12;
float gAttackMaxSize = 16;

float gNavalAttackStartDelayLong = 99999; // In seconds.
float gNavalAttackStartDelay = 300; // In seconds.
float gNavalAttackWaveInterval = 300; // In Seconds.

float gNavalAttackStartSize = 2;
float gNavalAttackMaxSize = 2; // Up to 4 but we only construct 2 ships.

int gMythicAgeUpTime = 480; // In seconds.

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
      
      // Click up to Mythic immediately on Titan.
      if (cDifficultyCurrent == cDifficultyTitan)
      {
         gMythicAgeUpTime = 0;
         gMaintainFifthLandUnitAmount = 2; // More Petroboli.
         gAttackStartDelay = 180; // Dispatch the first attack sooner; need to whittle down Arkantos' large starting army.
      }
 
      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainTenthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFirstNavalUnitAmount *= gDifficultyModifierMaintainUnit;

      gFirstDelay *= gDifficultyModifierTrainDelay;
      gSecondDelay *= gDifficultyModifierTrainDelay;
      gThirdDelay *= gDifficultyModifierTrainDelay;
      gFourthDelay *= gDifficultyModifierTrainDelay;
      gFifthDelay *= gDifficultyModifierTrainDelay;
      gNavalDelay *= gDifficultyModifierTrainDelay;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartDelay += xsGetTime(); // Five minutes of gametime, modified by difficulty, after waking up.
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      gNavalAttackStartDelay *= gDifficultyModifierFirstAttack;
      gNavalAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gNavalAttackStartSize *= gDifficultyModifierAttackSizes;
      gNavalAttackMaxSize *= gDifficultyModifierAttackSizes;

      gMythicAgeUpTime = gMythicAgeUpTime * gDifficultyModifierAgeUp + xsGetTime();

      // Certain parameters are way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gMaintainFirstLandUnitAmount = 4; // Fewer Hippeis.
         gMaintainSecondLandUnitAmount = 4; // Fewer Prodromoi.
         gMaintainThirdLandUnitAmount = 2; // Fewer Centaurs.
         gMaintainFourthLandUnitAmount = 3; // Fewer Hoplites.
         gMaintainFifthLandUnitAmount = 1; // Fewer Petroboli.

         gAttackStartDelay = 300; // In seconds.
         gAttackWaveInterval = 600; // They don't attack you much. This is a part 2.
         gAttackStartSize = 3; // Don't fight too hard.
         gAttackMaxSize = 6; // Don't fight too hard.
      }

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
      data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);
      data.addUnitToMaintain(gEighthLandUnit, gMaintainEighthLandUnitAmount);
      data.addUnitToMaintain(gNinthLandUnit, gMaintainNinthLandUnitAmount);
      data.addUnitToMaintain(gTenthLandUnit, gMaintainTenthLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gFirstDelay);
      data.setTrainDelay(gSecondLandUnit, gSecondDelay);
      data.setTrainDelay(gThirdLandUnit, gThirdDelay);
      data.setTrainDelay(gFourthLandUnit, gFourthDelay);
      data.setTrainDelay(gFifthLandUnit, gFifthDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);

      gAttackWave.addAttackUnitType(gFirstLandUnit); // Hippeis
      gAttackWave.addAttackUnitType(gFifthLandUnit); // Petroboli
      gAttackWave.addAttackUnitType(gFourthLandUnit); // Hoplites
      gAttackWave.addAttackUnitType(gNinthLandUnit); // Atalanta
      gAttackWave.addAttackUnitType(cUnitTypeAchilles); // Achilles

      gAttackWave.addAttackUnitType(gSecondLandUnit); // Prodromoi
      gAttackWave.addAttackUnitType(gThirdLandUnit); // Centaurs
      gAttackWave.addAttackUnitType(gSeventhLandUnit); // Jason
      gAttackWave.addAttackUnitType(gEighthLandUnit); // Hippolyta
      gAttackWave.addAttackUnitType(gTenthLandUnit); // Helepolii

      gNavalAttackWave.setName("gNavalAttackWave");
      gNavalAttackWave.setAttackStartTime(gNavalAttackStartDelayLong);
      gNavalAttackWave.setAttackInterval(gNavalAttackWaveInterval);
      gNavalAttackWave.setAttackSize(gNavalAttackStartSize);
      gNavalAttackWave.setMaxAttackSize(gNavalAttackMaxSize);
      gNavalAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gNavalAttackWave.addAttackUnitType(gFirstNavalUnit);
      gNavalAttackWave.setIsNavalAttackWave();

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      xsEnableRule("usePestilence");
      xsEnableRule("useBronze");
      xsEnableRule("useEarthquake");

      // Retain our base layout, put all pre-placed units in a reserve plan.
      int reservePlanID = aiPlanCreate("Reserve Plan", cPlanReserve, -1);
      aiPlanSetPriority(reservePlanID, 1);
      aiPlanAddUnitType(reservePlanID, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
      int queryID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive);
      int numResults = kbUnitQueryExecute(queryID);
      for (int i = 0; i < numResults; i++)
      {
         aiPlanAddUnit(reservePlanID, kbUnitQueryGetResult(queryID, i), false);
      }

      int explorePlanID = aiPlanCreate("Pegasus Explore", cPlanExplore, -1);
      aiPlanSetPriority(explorePlanID, 99);
      aiPlanAddUnitType(explorePlanID, cUnitTypePegasus, 1, 1, 1);

      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!
      gNavalAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(159.0, 0, 177.0); // In front of the Statue of Lightning in the center of our base.
      vector startPoint2 = vector(165.0, 0, 145.0); // In front of the Temple.
      vector targetPoint = vector(46.0, 0.0, 150.0); // Player's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("FirstArmy", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 left side");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(114.0, 4.0, 191.0));
      kbPathAddWaypoint(pathID1, vector(97.0, 0.0, 151.0));
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path 2 right side");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(161.0, 8.0, 139.0));
      kbPathAddWaypoint(pathID2, vector(97.0, 8.0, 151.0));
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

      // Where does our naval attack start and end.
      vector navalStartPoint = vector(178.0, 0.0, 118.0); // Next to the AI's dock.
      vector navalTargetPoint = vector(82.0, 0.0, 6.0); // Eastern edge of southern coast.

      int routeID3 = kbCreateAttackRouteWithPath("Route past P1's coast", navalStartPoint, navalTargetPoint);
      int pathID5 = kbPathCreate("Path 5");
      kbPathAddWaypoint(pathID5, navalStartPoint);
      kbPathAddWaypoint(pathID5, vector(122.0, 0.0, 75.0)); // Through the bay.
      kbPathAddWaypoint(pathID5, vector(45.0, 0.0, 125.0)); // To P1's base.
      kbPathAddWaypoint(pathID5, vector(4.0, 0.0, 110.0)); // Along P1's coast.
      kbPathAddWaypoint(pathID5, vector(41.0, 0.0, 53.0)); // Western edge of southern coast.
      kbPathAddWaypoint(pathID5, navalTargetPoint);
      kbAttackRouteAddPath(routeID3, pathID5);

      gNavalAttackWave.setGatherPoint(navalStartPoint);
      gNavalAttackWave.setTargetPoint(navalTargetPoint);
      gNavalAttackWave.setAttackRouteID(routeID3);
      gNavalAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      int landDefendPlan = createDefendPlan("Primary Land Defend", -1, 15.0, vector(176.00, 3.50, 181.00), 10, vector(176.00, 3.50, 181.00));
      aiPlanSetVariableFloat(landDefendPlan, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeHoplite, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeHippeus, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, cUnitTypePetrobolos, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeAtalanta, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeProdromos, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeCentaur, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeJason, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeHippolyta, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeHelepolis, 0, 0, 200);

      int navalDefendPlan = createDefendPlan("Primary Water Defend", -1, 10.0, navalStartPoint, 10, navalStartPoint);
      aiPlanAddUnitType(navalDefendPlan, cUnitTypeTrireme, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      static bool needResearchMythic = true;
      static bool reachedMythic = false;

      int age = kbPlayerGetAge(cMyID);
      int time = xsGetTime();
      if (done == false)
         // Don't age up on easy.
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            if (needResearchMythic == true && age < cAge4 && time >= gMythicAgeUpTime)
            {
               if (researchSimpleTech(cTechMythicAgeHephaestus, cUnitTypeTownCenter, -1, 60) == true)
               {
                  debugAttackWave("Starting Mythic Age research plan.");
                  needResearchMythic = false;
               }
            }
            else if (age == cAge4)
            {
               done = true;
            }
         }

      static bool enemyHasDock = false;
      if (enemyHasDock == false)
      {
         debugAttackWave("Cheating to look at all units on the map, looking for a player dock...");
         kbLookAtAllUnitsOnMap();
         // Do nothing if the player does not have a dock yet.
         if (getUnit(cUnitTypeDock, 1, cUnitStateAlive) >= 0)
         {
            // The player has a dock! Time to enable naval unit training as well as naval attacks.
            debugAttackWave("The player has a dock! Time to get started on water!");

            // Start maintaining Triremes.
            data.addUnitToMaintain(gFirstNavalUnit, gMaintainFirstNavalUnitAmount);
            data.setTrainDelay(gFirstNavalUnit, gNavalDelay);

            // Set naval attack start time.
            gNavalAttackWave.setAttackStartTime(gNavalAttackStartDelay);

            enemyHasDock = true;
         }
      }
      else
      {
         gNavalAttackWave.update();
      }

      // * * * TECH RULES * * * //

      // HEROIC AGE //
      static bool heroic_techs = false;
      if (age >= cAge3 && heroic_techs == false)
      {
         // Tech Rules for Easy and Moderate:
         if (cDifficultyCurrent <= cDifficultyModerate)
         {
            xsEnableRule("researchBronzeWeapons");
         }

         // Tech Rules for Moderate Only:
         if (cDifficultyCurrent == cDifficultyModerate)
         {
            xsEnableRule("researchHeavyInfantry");
            xsEnableRule("researchBronzeArmor");
            xsEnableRule("researchBronzeShields");
            xsEnableRule("researchHeavyCavalry");
            xsEnableRule("researchFortifiedTownCenter");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchArchitects");
            xsEnableRule("researchBurningPitch");
         }

         // Tech Rules for Titan only:
         heroic_techs = true;
      }

      // MYTHIC AGE //
      if (age >= cAge4 && reachedMythic == false)
      {
         // Tech Rules for All Difficulties:
         xsEnableRule("researchConscriptSailors");
         // Tech Rules for Moderate and Up:
         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchChampionInfantry");
            xsEnableRule("researchEngineers");
         }
         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchIronArmor");
            xsEnableRule("researchIronShields");
            xsEnableRule("researchChampionCavalry");
         }
         // Change the boolean back to true so the rules aren't enabled multiple times.
         reachedMythic = true;
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott16BStrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(195.00, 0.00, 225.00), 51);
   gOverrideClosestFishLocation = vector(176.00, 0.00, 114.00);
   gMaxFishDockScanRange = 40;

   setOverrideStrategy(fott16BStrategySetup);

   gOverrideFarmCount = 19; // We can't have too many farms due to space restrictions, 19 still fit well.
   gRBDSystem.setMaxFarmsPerBase(19);
   gRBDSystem.setMaxFarmsPerIteration(19);
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
            if (numBuildings >= 1)
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

// Bronze our army if we're in combat.
rule useBronze
inactive
minInterval 5
{
   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   int unitID = -1;
   int numEnemies = -1;

   // Only invoke this after 6 minutes.
   int current_time = xsGetTime();
   if (current_time >= 360)
   {
      for (int i = 0; i < attackPlans.size(); i++)
      {
         if (aiPlanGetParentID(attackPlans[i]) == -1)
         {
            // We just take the first unit to scan from.
            unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
            if (unitID >= 0)
            {
               numEnemies = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 15.0);
               debugAttackWave("numEnemies for casting Bronze: " + numEnemies);
               if (numEnemies >= 8)
               {
                  if (aiCastGodPowerAtPosition(cProtoPowerBronze, kbUnitGetPosition(unitID)) == true)
                  {
                     debugAttackWave("Casted Bronze!");
                     xsDisableRule("useBronze");
                  }
               }
            }
         }
      }
   }
}

// Attack the second TC of the player.
rule useEarthquake
inactive
minInterval 5
{
   // Only invoke this after 10 minutes.
   int current_time2 = xsGetTime();
   if (current_time2 >= 600)
   {
      int queryID = useSimpleUnitQuery(cUnitTypeTownCenter, 1, cUnitStateAlive, vector(30.0, 2.0, 223.0), 15.0);
      kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateSeeable);
      int numResults = kbUnitQueryExecute(queryID);
      debugAttackWave("numResults for casting Earthquake: " + numResults);
      if (numResults > 0)
      {
         if (aiCastGodPowerAtPosition(cProtoPowerEarthquake, vector(30.0, 2.0, 223.0)) == true)
         {
            debugAttackWave("Casted Earthquake!");
            xsDisableRule("Earthquake");
         }
      }
   }
}

// TECH RULES //

// *** HEROIC AGE TECHS ***
   // EASY AND MODERATE
      // Bronze Weapons
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

   // MODERATE ONLY
      // Bronze Armor
         rule researchBronzeArmor
         inactive
         minInterval 300
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
         minInterval 360
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

      // Burning Pitch
         rule researchBurningPitch
         inactive
         minInterval 560
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

      // Heavy Infantry
         rule researchHeavyInfantry
         active
         minInterval 300
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

      // Heavy Cavalry
         rule researchHeavyCavalry
         active
         minInterval 320
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

      // Fortified Town Center
         rule researchFortifiedTownCenter
         inactive
         minInterval 180
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
               debugAttackWave("Starting Fortified TownCenter research plan.");
               researchSimpleTech(cTechFortifiedTownCenter, cUnitTypeTownCenter, -1, 60);
               return;
            }
         }

   // HARD AND TITAN
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

// *** MYTHIC AGE TECHS ***
   // ALL DIFFICULTIES:
      // Conscript Sailors
         rule researchConscriptSailors
         inactive
         minInterval 10
         {
            debugAttackWave("Starting Conscript Sailors research plan.");
            researchSimpleTech(cTechConscriptSailors, cUnitTypeDock, -1, 50);
            xsDisableRule("researchConscriptSailors");
         }

   // HARD AND TITAN ONLY:
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

      // Champion Infantry
         rule researchChampionInfantry
         active
         minInterval 10
         {
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

      // Engineers
         rule researchEngineers
         active
         minInterval 60
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

   // TITAN ONLY:
      // Iron Armor
         rule researchIronArmor
         inactive
         minInterval 60
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
         minInterval 600
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

      // Champion Cavalry
         rule researchChampionCavalry
         active
         minInterval 10
         {
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