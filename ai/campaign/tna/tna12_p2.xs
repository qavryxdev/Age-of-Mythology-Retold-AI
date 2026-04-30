//==============================================================================
/* tgg12_p2.xs
   
   Atlanteans of Kronos (Kronos)

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

int gFirstLandUnit = cUnitTypeMurmillo; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 4;
int gSecondLandUnit = cUnitTypeTurma; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 3;
int gThirdLandUnit = cUnitTypeAutomaton; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 2;
int gFourthLandUnit = cUnitTypeContarius; // Gets trained starting in Heroic.
float gMaintainFourthLandUnitAmount = 4;
int gFifthLandUnit = cUnitTypeSatyr; // Gets trained starting in Heroic.
float gMaintainFifthLandUnitAmount = 2;
int gSixthLandUnit = cUnitTypeCentimanus; // Gets trained starting in Mythic.
float gMaintainSixthLandUnitAmount = 2;
int gSeventhLandUnit = cUnitTypeFanatic; // Gets trained starting in Mythic.
float gMaintainSeventhLandUnitAmount = 4;

float gMaxVillagerCount = 8; // 8 Citizens.

float gAttackStartDelay = 20; // In seconds.
float gAttackWaveInterval = 240; // In seconds. Cut this number by half. It used be 480 seconds which made the Titan difficulty too easy.
float gAttackStartSize = 8;
float gAttackMaxSize = 20;

float gHeroicAgeUpTime = 600; // In seconds.
float gMythicAgeUpTime = 1200; // In seconds.

vector gOurTCLocation = vector(197.0, 0.0, 179.0);

Strategy scenarioAttackWaveStrategy()
{

   xsEnableRule("useDeconstruction");
   xsEnableRule("useSpiderLair");
   xsEnableRuleGroup("ruleGroupBuildPlans");
   xsEnableRuleGroup("ruleGroupUpgrades");

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

      gTrainDelay *= gDifficultyModifierTrainDelay;
      gHeroicAgeUpTime *= gDifficultyModifierAgeUp;
      gMythicAgeUpTime *= gDifficultyModifierAgeUp;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Murmillo
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Turma
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Automaton

      // Arcus and Satyrs are maintained upon reaching Heroic.
      // Centimanus and Fire Siphons are maintained upon reaching Mythic.
   
      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);      // Murmillo
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);     // Turma
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);      // Automaton
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);     // Contarius
      data.setTrainDelay(gFifthLandUnit, gTrainDelay);      // Satyr
      data.setTrainDelay(gSixthLandUnit, gTrainDelay);      // Centimanus
      data.setTrainDelay(gSeventhLandUnit, gTrainDelay);      // Fanatic

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);  // Murmillo
      gAttackWave.addAttackUnitType(gSecondLandUnit); // Turma
      gAttackWave.addAttackUnitType(gThirdLandUnit);  // Automaton

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticMainBaseTCRebuild, true);
      gTimeToFarm = true;

      gAttackWave.setPlayerToAttack(1); // Attack P1!

      // Four waypoints are used in all paths, each placed by a Gaia Pool/Summoning Tree:
      vector south = vector(94.0, 0.0, 57.0);
      vector southwest = vector(54.0, 0.0, 170.0);
      vector north = vector(194.0, 0.0, 288.0);
      vector east = vector(273.0, 0.0, 98.0);

      // Where does our attack start and end.
      vector startPoint = vector(188.0, 0.0, 162.0); // By our Town Center and Palace.
      vector targetPoint = south; // Attacks end at the south pool, where the player is likely to have set up their base.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.

      int routeID = kbCreateAttackRouteWithPath("Route to Pools", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Clockwise starting at South");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, south);
      kbPathAddWaypoint(pathID1, southwest);
      kbPathAddWaypoint(pathID1, north);
      kbPathAddWaypoint(pathID1, east);
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Clockwise starting at Southwest");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, southwest);
      kbPathAddWaypoint(pathID2, north);
      kbPathAddWaypoint(pathID2, east);
      kbPathAddWaypoint(pathID2, south);
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      int pathID3 = kbPathCreate("Clockwise starting at North");
      kbPathAddWaypoint(pathID3, startPoint);
      kbPathAddWaypoint(pathID3, north);
      kbPathAddWaypoint(pathID3, east);
      kbPathAddWaypoint(pathID3, south);
      kbPathAddWaypoint(pathID3, southwest);
      kbPathAddWaypoint(pathID3, targetPoint);
      kbAttackRouteAddPath(routeID, pathID3);

      int pathID4 = kbPathCreate("Clockwise starting at East");
      kbPathAddWaypoint(pathID4, startPoint);
      kbPathAddWaypoint(pathID4, east);
      kbPathAddWaypoint(pathID4, south);
      kbPathAddWaypoint(pathID4, southwest);
      kbPathAddWaypoint(pathID4, north);
      kbPathAddWaypoint(pathID4, targetPoint);
      kbAttackRouteAddPath(routeID, pathID4);

      int pathID5 = kbPathCreate("Counter-Clockwise starting at South");
      kbPathAddWaypoint(pathID5, startPoint);
      kbPathAddWaypoint(pathID5, south);
      kbPathAddWaypoint(pathID5, east);
      kbPathAddWaypoint(pathID5, north);
      kbPathAddWaypoint(pathID5, southwest);
      kbPathAddWaypoint(pathID5, targetPoint);
      kbAttackRouteAddPath(routeID, pathID5);

      int pathID6 = kbPathCreate("Counter-Clockwise starting at Southwest");
      kbPathAddWaypoint(pathID6, startPoint);
      kbPathAddWaypoint(pathID6, southwest);
      kbPathAddWaypoint(pathID6, south);
      kbPathAddWaypoint(pathID6, east);
      kbPathAddWaypoint(pathID6, north);
      kbPathAddWaypoint(pathID6, targetPoint);
      kbAttackRouteAddPath(routeID, pathID6);

      int pathID7 = kbPathCreate("Counter-Clockwise starting at North");
      kbPathAddWaypoint(pathID7, startPoint);
      kbPathAddWaypoint(pathID7, north);
      kbPathAddWaypoint(pathID7, southwest);
      kbPathAddWaypoint(pathID7, south);
      kbPathAddWaypoint(pathID7, east);
      kbPathAddWaypoint(pathID7, targetPoint);
      kbAttackRouteAddPath(routeID, pathID7);

      int pathID8 = kbPathCreate("Counter-Clockwise starting at East");
      kbPathAddWaypoint(pathID8, startPoint);
      kbPathAddWaypoint(pathID8, east);
      kbPathAddWaypoint(pathID8, north);
      kbPathAddWaypoint(pathID8, southwest);
      kbPathAddWaypoint(pathID8, south);
      kbPathAddWaypoint(pathID8, targetPoint);
      kbAttackRouteAddPath(routeID, pathID8);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      // Create a general-purpose defend plan to keep existing military occupied and gathered.
      createDefendPlan("Generic Defend Plan", kbBaseGetMainID(cMyID), 20.0, startPoint, 10);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      static bool reachedAge3 = false;
      static bool reachedAge4 = false;
      int age = kbPlayerGetAge(cMyID);
      int time = xsGetTime();
      if (done == false)
      {
         if (age >= cAge3 && reachedAge3 == false)
         {
            data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Contarius
            data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount); // Satyr
            gAttackWave.addAttackUnitType(gFourthLandUnit);
            gAttackWave.addAttackUnitType(gFifthLandUnit);
            xsEnableRule("useChaos");
            reachedAge3 = true;
         }
         if (age >= cAge4 && reachedAge4 == false)
         {
            data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount); // Centimanus
            data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount); // Fantic
            gAttackWave.addAttackUnitType(gSixthLandUnit);
            gAttackWave.addAttackUnitType(gSeventhLandUnit);
            reachedAge4 = true;
            done = true;
         }

         if (age == cAge2 && time >= gHeroicAgeUpTime)
         {
            researchSimpleTech(cTechHeroicAgeHyperion, cUnitTypeTownCenter, -1, 75);
         }
         else if (age == cAge3 && time >= gMythicAgeUpTime)
         {
            researchSimpleTech(cTechMythicAgeHelios, cUnitTypeTownCenter, -1, 75);
         }
      }

      // New Tech Rules
      if (age >= cAge2)
      {
         // All Difficulties:
         researchSimpleTech(cTechMasons, cUnitTypeTownCenter, -1, 60);
         researchSimpleTech(cTechCopperWeapons, cUnitTypeArmory, -1, 60);
         researchSimpleTech(cTechCopperArmor, cUnitTypeArmory, -1, 60);
         researchSimpleTech(cTechCopperShields, cUnitTypeArmory, -1, 60);
         researchSimpleTech(cTechMediumInfantry, cUnitTypeMilitaryBarracks, -1, 60);
         researchSimpleTech(cTechMediumArchers, cUnitTypeMilitaryBarracks, -1, 60);
         researchSimpleTech(cTechMediumCavalry, cUnitTypeCounterBarracks, -1, 60);
         researchSimpleTech(cTechHephaestusRevenge, cUnitTypeTemple, -1, 60);

         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            researchSimpleTech(cTechVolcanicForge, cUnitTypeArmory, -1, 60);
         }

         // Hard and Up:

         // Titan Only:         
         
      }
      if (age >= cAge3)
      {
         // All Difficulties:
         researchSimpleTech(cTechBronzeWeapons, cUnitTypeArmory, -1, 60);
         researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 60);
         researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 60);
         researchSimpleTech(cTechHeavyInfantry, cUnitTypeMilitaryBarracks, -1, 60);
         researchSimpleTech(cTechHeavyArchers, cUnitTypeMilitaryBarracks, -1, 60);
         researchSimpleTech(cTechHeavyCavalry, cUnitTypeCounterBarracks, -1, 60);
         researchSimpleTech(cTechIronWall, cUnitTypeWallConnector, -1, 60);

         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            researchSimpleTech(cTechArchitects, cUnitTypeTownCenter, -1, 60);
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            researchSimpleTech(cTechFortifiedTownCenter, cUnitTypeTownCenter, -1, 60);
            researchSimpleTech(cTechGemini, cUnitTypeTemple, -1, 60);
         }

         // Titan Only:

      }
      if (age >= cAge4)
      {
         // All Difficulties:

         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            researchSimpleTech(cTechChampionInfantry, cUnitTypeMilitaryBarracks, -1, 60);
            researchSimpleTech(cTechChampionArchers, cUnitTypeMilitaryBarracks, -1, 60);
            researchSimpleTech(cTechChampionCavalry, cUnitTypeCounterBarracks, -1, 60);
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechOrichalcumWall, cUnitTypeWallConnector, -1, 60);
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            researchSimpleTech(cTechIronArmor, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
         }
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}


// Set up the strategy.
void tna12StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(197.00, 0.00, 179.00), 60);
   createOverrideGatherBase(vector(159.00, 0.00, 213.00), 30);
   createOverrideGatherBase(vector(169.00, 0.00, 139.00), 30);

   setOverrideStrategy(tna12StrategySetup);

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

// Below is a rule for attempting to heroize a human soldier.
// TODO: revisit if implementation is feasible; otherwise remove.
/*
rule heroizeUnit
inactive
minInterval 15
{
   static int chance = 50;  // The chance to heroize a unit when this rule is checked. The chance fluctuates depending on successful/failed checks.
   int unitID = -1;

   if (chance >= xsRandInt(0, 100))
   {
      debugAttackWave("HEROIZE - " + chance + " CHANCE");
      // Check if the chosen unit is not in an attack plan before determining success.
      unitID = getUnit(cUnitTypeHumanSoldier);
      if (kbUnitGetPlanID(unitID) < 0)
      {
         debugAttackWave("HEROIZE - FOUND A SUITABLE UNIT!!");
         chance -= 30;  // Lower chance to heroize the next time we check.
         unitSelect(unitID);
         commandTransformInSelected(); // Heroize!
      }
      else
      {
         chance += 10;  // Higher chance to heroize the next time we check.
      }
   }
   else
   {
      chance += 10;  // Higher chance to heroize the next time we check.
   }

   if (chance > 80)
   {
      chance = 80;
   }
   else if (chance < 10)
   {
      chance = 10;
   }
}
*/

rule useDeconstruction
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
   int targetID = -1;
   for (int i = 0; i < attackPlans.size(); i++)
   {
      if (aiPlanGetParentID(attackPlans[i]) == -1)
      {
         // We just take the first unit to scan from.
         unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
         if (unitID >= 0)
         {
            // Grab an enemy unit.
            targetID = getUnitByLocation(cUnitTypePalace, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 30.0);
            if (targetID >= 0)
            {
               // Invoke god power!
               if (aiCastGodPowerAtUnit(cProtoPowerDeconstruction, targetID) == true)
               {
                  debugAttackWave("Casted Deconstruction! (" + casts + "/2)");
                  casts++;
                  if (casts < 2)
                  {
                     delay = 300;   // 5-minute delay before getting to invoke this again.
                     return;
                  }
                  else if (casts >= 2)
                  {
                     xsDisableRule("useDeconstruction");
                     return;
                  }
               }
            }
         }
      }
   }
}

rule useSpiderLair
inactive
minInterval 5
{
   static int casts = 0;
   static int delay = 0;
   if (delay > 0)
   {
      delay -= 5;   // Same as rule interval.
      return;
   }

   int planID = -1;
   int unitCount = -1;
   vector locationStart = cInvalidVector;
   vector locationEnd = cInvalidVector;
   bool willCast = false;  // False until we find our units near a location.

   vector southPoolStart = vector(94.0, 0.0, 57.0);
   vector southwestPoolStart = vector(54.0, 0.0, 170.0);
   vector northPoolStart = vector(194.0, 0.0, 288.0);
   vector eastPoolStart = vector(273.0, 0.0, 98.0);
   vector southPoolEnd = vector(102.0, 0.0, 57.0);
   vector southwestPoolEnd = vector(54.0, 0.0, 167.0);
   vector northPoolEnd = vector(209.0, 0.0, 287.0);
   vector eastPoolEnd = vector(278.0, 0.0, 108.0);

   int[] planIDs = aiPlanGetIDsByType(cPlanAttack);
   for (int i = 0; i < planIDs.size(); i++)
   {
      planID = planIDs[i];
      // Check if we're currently attacking.
      if (aiPlanGetParentID(planID) == -1)
         {
         // Check South Pool
         if (willCast == false)
         {
            unitCount = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, southPoolStart, 20.0);
            if (unitCount >= 1)
            {
               locationStart = southPoolStart;
               locationEnd = southPoolEnd;
               willCast = true;
            }
         }

         // Check Southwest Pool
         if (willCast == false)
         {
            unitCount = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, southwestPoolStart, 20.0);
            if (unitCount >= 1)
            {
               locationStart = southwestPoolStart;
               locationEnd = southwestPoolEnd;
               willCast = true;
            }
         }

         // Check North Pool
         if (willCast == false)
         {
            unitCount = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, northPoolStart, 20.0);
            if (unitCount >= 1)
            {
               locationStart = northPoolStart;
               locationEnd = northPoolEnd;
               willCast = true;
            }
         }

         // Check East Pool
         if (willCast == false)
         {
            unitCount = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, eastPoolStart, 20.0);
            if (unitCount >= 1)
            {
               locationStart = eastPoolStart;
               locationEnd = eastPoolEnd;
               willCast = true;
            }
         }
         
         // Invoke if we've found a location to cast at.
         if (willCast == true)
         {
            // Invoke god power!
            if (aiCastGodPowerAtDualPosition(cProtoPowerSpiderLair, locationStart, locationEnd) == true)
            {
               debugAttackWave("Casted Spider Lair!");
               casts++;
               if (casts < 3)
               {
                  delay = 180;   // 3-minute delay before getting to invoke this again.
                  return;
               }
               else if (casts >= 3)
               {
                  xsDisableRule("useSpiderLair");
                  return;
               }
            }
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
   kbBuildingPlacementSetCenterPosition(bpID, location, 15.0);
   kbBuildingPlacementSetStepSize(bpID, 1.0);
   kbBuildingPlacementSetBufferSpace(bpID, 0.0);
   kbBuildingPlacementAddPositionInfluence(bpID, location, 100.0, 50.0, cFalloffLinear);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, type);
   aiPlanAddUnitType(buildPlanID, builder, 1, 1, 1, false);
   aiPlanSetPriority(buildPlanID, 90);
}

rule buildArmory
inactive
minInterval 10
group ruleGroupBuildPlans
{
    int building = cUnitTypeArmory;
    vector location = vector(185.0, 0.0, 199.0);
    if (getUnit(building, cMyID, cUnitStateABQ) < 1)
    {
        buildBuilding(building, location);
    }
}

rule researchCopperWeaponsArmorShields
inactive
minInterval 30
group ruleGroupUpgrades
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if ((kbTechGetStatus(cTechCopperWeapons) == cTechStatusActive) &&
       (kbTechGetStatus(cTechCopperArmor) == cTechStatusActive) &&
       (kbTechGetStatus(cTechCopperShields) == cTechStatusActive))
   {
      xsDisableRule("researchCopperWeaponsArmorShields");
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

rule researchBronzeWeaponsArmorShields
inactive
minInterval 450
group ruleGroupUpgrades
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if ((kbTechGetStatus(cTechBronzeWeapons) == cTechStatusActive) &&
       (kbTechGetStatus(cTechBronzeArmor) == cTechStatusActive) &&
       (kbTechGetStatus(cTechBronzeShields) == cTechStatusActive))
   {
      xsDisableRule("researchBronzeWeaponsArmorShields");
      return;
   }
   if (kbTechGetStatus(cTechBronzeWeapons) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Bronze Weapons research plan.");
      researchSimpleTech(cTechBronzeWeapons, cUnitTypeArmory, -1, 60);
      return;
   }
   if (kbTechGetStatus(cTechBronzeArmor) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Bronze Armor research plan.");
      researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 60);
      return;
   }
   if (kbTechGetStatus(cTechBronzeShields) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Bronze Shields research plan.");
      researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 60);
      return;
   }
}

rule researchIronWeaponsArmorShields
inactive
minInterval 900
group ruleGroupUpgrades
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if ((kbTechGetStatus(cTechIronWeapons) == cTechStatusActive) &&
       (kbTechGetStatus(cTechIronArmor) == cTechStatusActive) &&
       (kbTechGetStatus(cTechIronShields) == cTechStatusActive))
   {
      xsDisableRule("researchIronWeaponsArmorShields");
      return;
   }
   if (kbTechGetStatus(cTechIronWeapons) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Iron Weapons research plan.");
      researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 60);
      return;
   }
   if (kbTechGetStatus(cTechIronArmor) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Iron Armor research plan.");
      researchSimpleTech(cTechIronArmor, cUnitTypeArmory, -1, 60);
      return;
   }
   if (kbTechGetStatus(cTechIronShields) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Iron Shields research plan.");
      researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
      return;
   }
}

rule researchBallistics
inactive
minInterval 120
group ruleGroupUpgrades
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

rule researchMediumUnits
inactive
minInterval 60
group ruleGroupUpgrades
{
   debugAttackWave("Starting Medium units research plan.");
   researchSimpleTech(cTechMediumInfantry, cUnitTypeMilitaryBarracks, -1, 50);
   researchSimpleTech(cTechMediumArchers, cUnitTypeCounterBarracks, -1, 50);
   researchSimpleTech(cTechMediumCavalry, cUnitTypeMilitaryBarracks, -1, 50);
   xsDisableRule("researchMediumUnits");
}

rule researchHeavyUnits
inactive
minInterval 450
group ruleGroupUpgrades
{
   debugAttackWave("Starting Heavy units research plan.");
   researchSimpleTech(cTechHeavyInfantry, cUnitTypeMilitaryBarracks, -1, 50);
   researchSimpleTech(cTechHeavyArchers, cUnitTypeCounterBarracks, -1, 50);
   researchSimpleTech(cTechHeavyCavalry, cUnitTypeMilitaryBarracks, -1, 50);
   xsDisableRule("researchHeavyUnits");
}

rule researchChampionUnits
inactive
minInterval 900
group ruleGroupUpgrades
{
   debugAttackWave("Starting Champion units research plan.");
   researchSimpleTech(cTechChampionInfantry, cUnitTypeMilitaryBarracks, -1, 50);
   researchSimpleTech(cTechChampionArchers, cUnitTypeCounterBarracks, -1, 50);
   researchSimpleTech(cTechChampionCavalry, cUnitTypeMilitaryBarracks, -1, 50);
   xsDisableRule("researchChampionUnits");
}

rule researchAutomatonUpgrades
inactive
minInterval 120
group ruleGroupUpgrades
{
   debugAttackWave("Starting Automaton upgrades research plan.");
   researchSimpleTech(cTechHephaestusRevenge, cUnitTypeTemple, -1, 50);
   researchSimpleTech(cTechVolcanicForge, cUnitTypeArmory, -1, 50);
   xsDisableRule("researchAutomatonUpgrades");
}

rule researchSatyrUpgrades
inactive
minInterval 580
group ruleGroupUpgrades
{
   debugAttackWave("Starting Satyr upgrades research plan.");
   researchSimpleTech(cTechGemini, cUnitTypeTemple, -1, 50);
   xsDisableRule("researchSatyrUpgrades");
}

rule researchCentimanusUpgrades
inactive
minInterval 960
group ruleGroupUpgrades
{
   debugAttackWave("Starting Centimanus upgrades research plan.");
   researchSimpleTech(cTechTitanomachy, cUnitTypeTemple, -1, 50);
   xsDisableRule("researchCentimanusUpgrades");
}