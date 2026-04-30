//==============================================================================
/* tgg10_p2.xs
   
   Promethean Servants (Oranos)

   Rather standard player with their base in the north of the map. Attacks with Counter-Barracks units, Prometheans
   and will advance to Mythic (via Helios) to train Fire Siphons.

   Their most unique feature is that they utilize all of their god powers. They are, however, forbidden from using Valor on Easy difficulty
   to not discourage player Myth Units on that skill level.

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
float gMaintainFirstLandUnitAmount = 4;
int gSecondLandUnit = cUnitTypeKatapeltes; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 3;
int gThirdLandUnit = cUnitTypeCheiroballista; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 2;
int gFourthLandUnit = cUnitTypePromethean; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 2;
int gFifthLandUnit = cUnitTypeFireSiphon; // Gets trained starting in Mythic.
float gMaintainFifthLandUnitAmount = 2;
int gSixthLandUnit = cUnitTypeCentimanus; // Gets trained starting in Mythic.
float gMaintainSixthLandUnitAmount = 1;

float gMaxVillagerCount = 6;  // 6 Citizens.

float gAttackStartDelay = 600; // In seconds.
float gAttackWaveInterval = 480; // In seconds.
float gAttackStartSize = 6;
float gAttackMaxSize = 16;

float gMythicAgeUpTime = 1800; // In seconds.

vector gOurTCLocation = vector(199.0, 0.0, 247.0);


Strategy scenarioAttackWaveStrategy()
{

   xsEnableRule("useShockwave");
   xsEnableRule("useValor");
   xsEnableRule("useChaos");
   xsEnableRule("unlockAdditionalAttackPaths");
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

      if (cDifficultyCurrent >= cDifficultyHard)
      {
            gFourthLandUnit = cUnitTypeSatyr;
            gMaintainFourthLandUnitAmount = 4;
            gAttackStartSize = 15;
            gAttackMaxSize = 35;
            gMythicAgeUpTime = 500; // In seconds.
            gAttackWaveInterval = 360; // In seconds.
      }
      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      // gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      gTrainDelay *= gDifficultyModifierTrainDelay;
      gMythicAgeUpTime *= gDifficultyModifierAgeUp;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Turma
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Katapeltes
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Cheiroballista
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Promethean

      // Fire Siphons are maintained upon reaching Mythic.
   
      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);      // Turma
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);     // Katapeltes
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);      // Cheiroballista
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);     // Promethean
      data.setTrainDelay(gFifthLandUnit, gTrainDelay);      // Fire Siphon
      data.setTrainDelay(gSixthLandUnit, gTrainDelay);      // Centimanus

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);  // Turma
      gAttackWave.addAttackUnitType(gSecondLandUnit); // Katapeltes
      gAttackWave.addAttackUnitType(gThirdLandUnit);  // Cheiroballista
      gAttackWave.addAttackUnitType(gFourthLandUnit);  // Promethean

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);

      gAttackWave.setPlayerToAttack(1); // Attack P1!

      // Where does our attack start and end.
      vector startPoint = vector(186.0, 0.0, 258.0); // By our town.
      vector targetPoint = vector(42.0, 0.0, 273.0); // Player's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 - Through the Pass");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(130.0, 0.0, 268.0));
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });


      createDefendPlan("Generic Defend Plan", kbBaseGetMainID(cMyID), 30.0, gOurTCLocation, 10);

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
            data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount); // Fire Sihpon
            gAttackWave.addAttackUnitType(gFifthLandUnit);
            gAttackWave.addAttackUnitType(cUnitTypeCentimanus);   // Since we get one for free when aging up.
            data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount); // Centimanus
            //xsEnableRule("useVortex");  // Causing too much lag at the moment.
            reachedAge4 = true;
            done = true;
         }
      }

      // New Tech Rules
      if (age >= cAge3)
      {
         // All Difficulties:
         
         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            if (getUnit(cUnitTypeArmory, cMyID, cUnitStateABQ) >= 1)
            {
               researchSimpleTech(cTechBronzeWeapons, cUnitTypeArmory, -1, 60);
            }
            if (getUnit(cUnitTypeCounterBarracks, cMyID, cUnitStateABQ) >= 1)
            {
               researchSimpleTech(cTechHeavyInfantry, cUnitTypeCounterBarracks, -1, 60);
               researchSimpleTech(cTechHeavyArchers, cUnitTypeCounterBarracks, -1, 60);
               researchSimpleTech(cTechHeavyCavalry, cUnitTypeCounterBarracks, -1, 60);
            }
            if (getUnit(cUnitTypePalace, cMyID, cUnitStateABQ) >= 1)
            {
               researchSimpleTech(cTechDraftHorses, cUnitTypePalace, -1, 60);
            }
            researchSimpleTech(cTechFortifiedTownCenter, cUnitTypeTownCenter, -1, 60);
            researchSimpleTech(cTechIrrigation, cUnitTypeEconomicGuild, -1, 60);
            researchSimpleTech(cTechShaftMine, cUnitTypeEconomicGuild, -1, 60);
            researchSimpleTech(cTechBowSaw, cUnitTypeEconomicGuild, -1, 60);
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            researchSimpleTech(cTechArchitects, cUnitTypeTownCenter, -1, 60);
            if (getUnit(cUnitTypeArmory, cMyID, cUnitStateABQ) >= 1)
            {
               researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 60);
               researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 60);
            }
            researchSimpleTech(cTechArchitects, cUnitTypeTownCenter, -1, 60);
            researchSimpleTech(cTechBoilingOil, cUnitTypeMirrorTower, -1, 60);
         }

         // Titan Only:
         if (cDifficultyCurrent >= cDifficultyTitan)
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
            if (getUnit(cUnitTypeArmory, cMyID, cUnitStateABQ) >= 1)
            {
               researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 60);
            }
            if (getUnit(cUnitTypeCounterBarracks, cMyID, cUnitStateABQ) >= 1)
            {
               researchSimpleTech(cTechChampionInfantry, cUnitTypeCounterBarracks, -1, 60);
               researchSimpleTech(cTechChampionArchers, cUnitTypeCounterBarracks, -1, 60);
            }
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            if (getUnit(cUnitTypeCounterBarracks, cMyID, cUnitStateABQ) >= 1)
            {
               researchSimpleTech(cTechChampionCavalry, cUnitTypeCounterBarracks, -1, 60);
            }
            if (getUnit(cUnitTypePalace, cMyID, cUnitStateABQ) >= 1)
            {
               researchSimpleTech(cTechHaloOfTheSun, cUnitTypePalace, -1, 60);
            }
            if (getUnit(cUnitTypeArmory, cMyID, cUnitStateABQ) >= 1)
            {
            researchSimpleTech(cTechIronArmor, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
            }
         }
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}


// Set up the strategy.
void tna10StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(208.00, 0.00, 258.00), 53);

   setOverrideStrategy(tna10StrategySetup);

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

rule unlockAdditionalAttackPaths
inactive
minInterval 600
{
   debugAttackWave("Adding additonal paths to my attack route! I now have a 1/3rd's chance to flank the player through the east!");
   vector startPoint = vector(186.0, 0.0, 258.0); // By our town.
   vector targetPoint = vector(42.0, 0.0, 273.0); // Player's TC.

   int pathID2 = kbPathCreate("Path 2 - Through the Pass");
   kbPathAddWaypoint(pathID2, startPoint);
   kbPathAddWaypoint(pathID2, vector(130.0, 0.0, 268.0));
   kbPathAddWaypoint(pathID2, targetPoint);
   kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID2);

   int pathID3 = kbPathCreate("Path 3 - Flank from the East");
   kbPathAddWaypoint(pathID3, startPoint);
   kbPathAddWaypoint(pathID3, vector(208.0, 0.0, 128.0));
   kbPathAddWaypoint(pathID3, vector(110.0, 0.0, 146.0));
   kbPathAddWaypoint(pathID3, targetPoint);
   kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID3);

   gAttackWave.update();
   xsDisableRule("unlockAdditionalAttackPaths");
   return;
}

rule useShockwave
inactive
minInterval 5
{
   static int casts = 0;
   static int delay = 300; // 5 minutes before first cast.
   if (delay > 0)
   {
      delay -= 5;   // Same as rule interval.
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
            debugAttackWave("numEnemies for casting Shockwave offensively: " + numEnemies);
            if (numEnemies >= 5)
            {
               // Grab an enemy unit.
               targetID = getUnitByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 20.0);
               if (targetID >= 0)
               {
                  // Invoke god power!
                  if (aiCastGodPowerAtPosition(cProtoPowerShockwave, kbUnitGetPosition(targetID)) == true)
                  {
                     casts++;
                     debugAttackWave("Casted Shockwave! (" + casts + "/3)");
                     if (casts < 3)
                     {
                        delay = 180;   // 3-minute delay before getting to invoke this again.
                        return;
                     }
                     else if (casts >= 3)
                     {
                        xsDisableRule("useShockwave");
                        return;
                     }
                  }
               }
            }
         }
      }
   }

   numEnemies = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, gOurTCLocation, 30.0);
   debugAttackWave("numEnemies for casting Shockwave defensively: " + numEnemies);
   if (numEnemies >= 5)
   {
      // Grab an enemy unit.
      targetID = getUnitByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, gOurTCLocation, 30.0);
      if (targetID >= 0)
      {
         // Invoke god power!
         if (aiCastGodPowerAtPosition(cProtoPowerShockwave, kbUnitGetPosition(targetID)) == true)
         {
            casts++;
            debugAttackWave("Casted Shockwave! (" + casts + "/3)");
            if (casts < 3)
            {
               delay = 180;   // 3-minute delay before getting to invoke this again.
               return;
            }
            else if (casts >= 3)
            {
               xsDisableRule("useShockwave");
               return;
            }
         }
      }
   }
}

rule useValor
inactive
minInterval 5
{
   // Not allowed to invoke Valor on Easy.
   if (cDifficultyCurrent == cDifficultyEasy)
   {
      xsDisableRule("useValor");
      return;
   }

   static int casts = 0;
   static int delay = 480; // 8 minutes before first cast.
   if (delay > 0)
   {
      delay -= 5;   // Same as rule interval.
      return;
   }

   // Check if we have fewer heroes than the player has myth units.
   int myHeroCount = kbUnitCount(cUnitTypeHero, cMyID, cUnitStateAlive);
   int enemyMythCount = kbUnitCount(cUnitTypeMythUnit, 1, cUnitStateAlive);
   if (myHeroCount >= enemyMythCount)
   {
      return;  // We have more or equal, no need to invoke Valor.
   }

   int unitID = getUnit(cUnitTypeHumanSoldier);
   if (unitID >= 0)
   {
      // Invoke god power!
      if (aiCastGodPowerAtPosition(cProtoPowerValor, kbUnitGetPosition(unitID)) == true)
      {
         casts++;
         debugAttackWave("Casted Valor! (" + casts + "/6)");
         if (casts < 6)
         {
            delay = 60;   // 1-minute delay before getting to invoke this again.
            return;
         }
         else if (casts >= 6)
         {
            xsDisableRule("useValor");
            return;
         }
      }
   }
}

rule useChaos
inactive
minInterval 10
{
   static int casts = 0;
   static int delay = 600; // 10 minutes before first cast.
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
                     debugAttackWave("Casted Chaos! (" + casts + "/2)");
                     casts++;
                     if (casts < 2)
                     {
                        delay = 600;   // 10-minute delay before getting to invoke this again.
                        return;
                     }
                     else if (casts >= 2)
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

/* Vortex disabled for the time being as it is causing plenty of lag.
This logic doesn't work, you will shift defending units that will just instantly run back, don't enable back in this state.
rule useVortex
inactive
minInterval 5
{
   int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanCombat, cDefendPlanCombatType, cDefendPlanCombatTypeAttack);
   int numUnits = -1;
   vector enemyBase = vector(57.0, 0.0, 265.0); // Player's easternmost Town Center.
   if (planID >= 0)
   {
      // Look for my units near the enemy TC.
      numUnits = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, enemyBase, 20.0);
      debugAttackWave("We've got this many units near the enemy TC for casting Vortex: " + numUnits);
      if (numUnits >= 4)
      {
         // Invoke god power!
         if (aiCastGodPowerAtPosition(cProtoPowerVortex, enemyBase) == true)
         {
            debugAttackWave("Casted Vortex!");
            xsDisableRule("useVortex");
            return;
         }
      }
   }
}
*/

void buildBuilding(int type = cUnitTypeManor, vector location = cInvalidVector)
{
   int builder = cUnitTypeVillagerAtlantean;
   int buildPlanID = aiPlanCreate("Build Plan", cPlanBuild, -1);
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID));
   kbBuildingPlacementSetBuildingPUID(bpID, type);
   kbBuildingPlacementSetCenterPosition(bpID, location, 15.0);
   kbBuildingPlacementSetStepSize(bpID, 1.0);
   kbBuildingPlacementSetBufferSpace(bpID, 0.0);
   kbBuildingPlacementAddPositionInfluence(bpID, location, 100.0, 50.0, cFalloffLinear);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, type);
   aiPlanAddUnitType(buildPlanID, builder, 1, 1, 1, false);
   aiPlanSetPriority(buildPlanID, 99);
}

rule buildCounterBarracks
inactive
minInterval 30
group ruleGroupBuildPlans
{
    int building = cUnitTypeCounterBarracks;
    vector location = vector(172.0, 0.0, 267.0);
    if (getUnit(building, cMyID, cUnitStateABQ) < 1)
    {
        buildBuilding(building, location);
    }
   xsSetRuleMinInterval("buildCounterBarracks", 60);
}

rule buildPalace
inactive
minInterval 540
group ruleGroupBuildPlans
{
   int building = cUnitTypePalace;
   vector location = vector(170.0, 0.0, 243.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 1)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildPalace", 60);
}

rule buildArmory
inactive
minInterval 45
group ruleGroupBuildPlans
{
   int building = cUnitTypeArmory;
   vector location = vector(200.0, 0.0, 219.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 1)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildArmory", 60);
}