//==============================================================================
/* fott31_p2.xs
   
   fott31 player2
   Continuously trains Greek Units and attacks using multiple paths.
   This is a simplified version of the AI attack plan, there are various issues with the commented out code.

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
float gTrainDelay = 0; // In seconds.
int gFirstLandUnit = cUnitTypeHetairos; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 7;
int gSecondLandUnit = cUnitTypeColossus; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 1;
int gThirdLandUnit = cUnitTypeToxotes; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 5;
int gFourthLandUnit = cUnitTypeHippolyta; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 1;
int gFifthLandUnit = cUnitTypePolyphemus; // Not Easy
float gMaintainFifthLandUnitAmount = 1;

float gAttackStartDelayLong = cWaitWithAttacking; // In seconds.
float gAttackStartDelay = 300; // In seconds.
float gAttackWaveInterval = 460; // In seconds.
float gAttackStartSize = 7;
float gAttackMaxSize = 11;

// Don't add Polyphemus until later; he's far too strong for the beginning.
int gFifthLandUnitDelay = 1200;

bool gAllowedToAttack = false;

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
         gMaintainFirstLandUnitAmount = 4; // Hetairoi
         gMaintainSecondLandUnitAmount = 1; // Colossi
         gMaintainThirdLandUnitAmount = 3; // Toxotai

         gAttackStartDelay = 600; // In seconds.
         gAttackWaveInterval = 600; // In seconds.
         gAttackStartSize = 3;
         gAttackMaxSize = 5;
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      gTrainDelay *= gDifficultyModifierTrainDelay;
      gFifthLandUnitDelay += xsGetTime(); // Offset for starting time.

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      // Don't add Polyphemus until way later.

      /* // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      data.setTrainDelay(gFourthLandUnit, gTrainDelay); */

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelayLong);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      gAttackWave.addAttackUnitType(gThirdLandUnit);
      gAttackWave.addAttackUnitType(gFourthLandUnit);
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         gAttackWave.addAttackUnitType(gFifthLandUnit);
      }

      gAttackWave.displayFirstAttackStats();
      
      //==============================================================================
      // Init Shared part.
      //==============================================================================
      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack and defend plan start and end.
      vector startPoint = vector(191.0, 11, 53.0); // In the Town Center of the East of Atlantis
      vector targetPoint = vector(77.71, 3.00, 238.85); // P1's TC.

      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      int landDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 20.0, vector(225.0, 0.0, 61.0), 10);
      aiPlanSetVariableFloat(landDefendPlan, cDefendPlanEngageRange, 0, 20.0);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      int time = xsGetTime();
      if (done == false && gAllowedToAttack == true)
      {
         debugAttackWave("Enabling attacks.");
         debugAttackWave("New attack time: " + turnNumberIntoTimeDisplay(time + gAttackStartDelay));
         gAttackWave.setAttackStartTime(gAttackStartDelay);

         // Only begin researching technologies once we're allowed to attack.

         // Moderate and Hard:
         if (cDifficultyCurrent >= cDifficultyModerate && cDifficultyCurrent < cDifficultyTitan)
         {
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchHandOfTalos");
         }
         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchChampionArchers");
            xsEnableRule("researchBurningPitch");
         }
         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchIronArmor");
            xsEnableRule("researchIronShields");
            xsEnableRule("researchShoulderOfTalos");
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchOlympianWeapons");
         }

         done = true;
      }

      // Add more Colossi later on.
      if (cDifficultyCurrent >= cDifficultyModerate && time >= 600)
      {
         gMaintainSecondLandUnitAmount *= 2.0; // Train +100% more Colossi.
         // Update attack size parameters based on the enlarged army composition.
         gAttackMaxSize *= 1.05; // Attack size increases by +5%
         gAttackWave.setMaxAttackSize(gAttackMaxSize);
      }

      if (cDifficultyCurrent >= cDifficultyHard)
      {
         static bool addedPolyphemus = false;
         if (addedPolyphemus == false && time >= gFifthLandUnitDelay)
         {
            data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
            addedPolyphemus = true;
         }
      }

      // ************************** ATTACK ROUTE UPDATE ************************** //
      // If we find out that player 1 has stuff by the north Settlement,
      // then we'll start passing by that area before marching on to the southwest.
      // **************************************************************************//

      static int route_check_time = 10;

      static bool added_west = false;
      static bool added_north = false;
      
      // Only run through this code if it's been at least 15 seconds since we last checked.
      if (time >= route_check_time)
      {
         route_check_time += 15;
         // Only run through this code if we haven't added all possible routes.
         if (added_west == true && added_north == true)
         {
            route_check_time += 9999;
         }
         else if (added_west == false)
         {
            vector western_area = vector(150.78, 0.0, 296.85);
            int numEnemyBuildingsWest = -1;
            int totalEnemiesWest = 0;
            numEnemyBuildingsWest = getUnitCountByLocation(cUnitTypeTownCenter, 1, cUnitStateAlive, western_area, 127.0);
            numEnemyBuildingsWest *= 5; // Only 1 building needed to convince them to start attacking the west.
            totalEnemiesWest += numEnemyBuildingsWest;

            // Decide when to add the west route.
            debugAttackWave("numResults for adding west route: " + totalEnemiesWest);
            if (totalEnemiesWest >= 1)
            {
               // We found out that player 1 is hanging out in the west - updating our attack route.
               vector startPoint = vector(190.68, 0.0, 52.8); // In front of their TC.
               vector targetPoint = vector(77.71, 0.0, 238.85); // Southwest of the main gate.

               int pathID1 = kbPathCreate("Path that goes straight out the front gate.");
               kbPathAddWaypoint(pathID1, startPoint);
               kbPathAddWaypoint(pathID1, vector(166.59, 0.0, 53.25)); // Block #1
               kbPathAddWaypoint(pathID1, vector(144.93, 0.0, 89.51)); // Block #2
               kbPathAddWaypoint(pathID1, vector(171.40, 0.0, 215.00)); // Block #3
               kbPathAddWaypoint(pathID1, vector(144.59, 0.0, 243.94)); // Block #4
               kbPathAddWaypoint(pathID1, vector(105.64, 0.0, 283.87)); // Block #5
               kbPathAddWaypoint(pathID1, targetPoint);
               kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID1);
               added_west = true;
               gAllowedToAttack = true;
            }
            // Start attacking anyway if we're too late into the game; prevents exploits.
            else if (xsGetTime() >= 600 && added_west == false)
            {
               // We found out that player 1 is hanging out in the west - updating our attack route.
               vector startPoint = vector(190.68, 0.0, 52.8); // In front of their TC.
               vector targetPoint = vector(77.71, 0.0, 238.85); // Southwest of the main gate.

               int pathID1 = kbPathCreate("Path that goes straight out the front gate.");
               kbPathAddWaypoint(pathID1, startPoint);
               kbPathAddWaypoint(pathID1, vector(166.59, 0.0, 53.25)); // Block #1
               kbPathAddWaypoint(pathID1, vector(144.93, 0.0, 89.51)); // Block #2
               kbPathAddWaypoint(pathID1, vector(171.40, 0.0, 215.00)); // Block #3
               kbPathAddWaypoint(pathID1, vector(144.59, 0.0, 243.94)); // Block #4
               kbPathAddWaypoint(pathID1, vector(105.64, 0.0, 283.87)); // Block #5
               kbPathAddWaypoint(pathID1, targetPoint);
               kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID1);
               added_west = true;
               gAllowedToAttack = true;
            }
         }
         if (added_north == false)
         {
            vector northern_area = vector(369.0, 0.0, 299.0);
            int numEnemyBuildingsNorth = -1;
            int totalEnemiesNorth = 0;
            numEnemyBuildingsNorth = getUnitCountByLocation(cUnitTypeTownCenter, 1, cUnitStateAlive, northern_area, 98.0);
            numEnemyBuildingsNorth *= 5; // Only 1 building needed to convince them to start attacking the northern Settlement.
            totalEnemiesNorth += numEnemyBuildingsNorth;

            // Decide when to add the north route.
            debugAttackWave("numResults for adding north route: " + totalEnemiesNorth);
            if (totalEnemiesNorth >= 5)
            {
               // We found out that player 1 is hanging out in the north - updating our attack route.

               vector startPoint = vector(190.68, 0.0, 52.8); // In front of their TC.
               vector targetPoint = vector(77.71, 0.0, 238.85); // Southwest of the main gate.

               int pathID2 = kbPathCreate("Path that goes to the northern Settlement, then by the front gate.");
               kbPathAddWaypoint(pathID2, startPoint);
               kbPathAddWaypoint(pathID2, vector(166.59, 0.0, 53.25)); // Block #1
               kbPathAddWaypoint(pathID2, vector(144.93, 0.0, 89.51)); // Block #2
               kbPathAddWaypoint(pathID2, vector(366.34, 0.0, 308.77)); // Block #3
               kbPathAddWaypoint(pathID2, vector(156.26, 0.0, 306.08)); // Block #4
               kbPathAddWaypoint(pathID2, vector(105.64, 0.0, 283.87)); // Block #5
               kbPathAddWaypoint(pathID2, targetPoint);
               kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID2);
               added_north = true;
               gAllowedToAttack = true;
            }
            else if (xsGetTime() >= 600)
            {
               // We found out that player 1 is hanging out in the north - updating our attack route.

               vector startPoint = vector(190.68, 0.0, 52.8); // In front of their TC.
               vector targetPoint = vector(77.71, 0.0, 238.85); // Southwest of the main gate.

               int pathID2 = kbPathCreate("Path that goes to the northern Settlement, then by the front gate.");
               kbPathAddWaypoint(pathID2, startPoint);
               kbPathAddWaypoint(pathID2, vector(166.59, 0.0, 53.25)); // Block #1
               kbPathAddWaypoint(pathID2, vector(144.93, 0.0, 89.51)); // Block #2
               kbPathAddWaypoint(pathID2, vector(366.34, 0.0, 308.77)); // Block #3
               kbPathAddWaypoint(pathID2, vector(156.26, 0.0, 306.08)); // Block #4
               kbPathAddWaypoint(pathID2, vector(105.64, 0.0, 283.87)); // Block #5
               kbPathAddWaypoint(pathID2, targetPoint);
               kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID2);
               added_north = true;
               gAllowedToAttack = true;
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
void fott31StrategySetup()
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
   //gMaxVillagerCount *= gDifficultyModifierMaintainVillager;

   gOverrideMaxVillagerPop = 0;
   setOverrideStrategy(fott31StrategySetup);
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

// *** TECHS ***
   // MYTHIC AGE
      // ALL DIFFICULTIES:
      // MODERATE AND UP:
         // Iron Weapons
            rule researchIronWeapons
            inactive
            minInterval 350
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
         // Champion Ranged Soldiers
            rule researchChampionArchers
            inactive
            minInterval 480
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
         // Burning Pitch
            rule researchBurningPitch
            inactive
            minInterval 540
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
         // Hand Of Talos
            rule researchHandOfTalos
            inactive
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
      // HARD AND UP:
         // Iron Armor
            rule researchIronArmor
            inactive
            minInterval 640
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
            minInterval 720
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

         // Shoulder of Talos
            rule researchShoulderOfTalos
            inactive
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

      // TITAN ONLY:
         // Olympian Weapons
            rule researchOlympianWeapons
            inactive
            minInterval 640
            {
               debugAttackWave("Starting Olympian Weapons research plan.");
               researchSimpleTech(cTechOlympianWeapons, cUnitTypeArmory, -1, 60);
               xsDisableRule("researchOlympianWeapons");
            }