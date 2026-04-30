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
float gTrainDelay = 1; // In seconds.
int gFirstLandUnit = cUnitTypeHoplite; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 8;
int gSecondLandUnit = cUnitTypeHippeus; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 4;
int gThirdLandUnit = cUnitTypeToxotes; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 4;
int gFourthLandUnit = cUnitTypeHypaspist; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 4;
int gFifthLandUnit = cUnitTypePeltast; // Gets trained from the start.
float gMaintainFifthLandUnitAmount = 4;
int gSixthLandUnit = cUnitTypeCyclops; // Gets trained from the start.
float gMaintainSixthLandUnitAmount = 2;
int gSeventhLandUnit = cUnitTypeProdromos; // Not Easy
float gMaintainSeventhLandUnitAmount = 4;
int gEighthLandUnit = cUnitTypeChimera; // Not Easy. 16:40 game time passed since waking up.
float gMaintainEighthLandUnitAmount = 3;

int gNinthLandUnit = cUnitTypeAtalanta; // Gets trained from the start.
float gMaintainNinthLandUnitAmount = 1;
int gTenthLandUnit = cUnitTypeTheseus; // Gets trained from the start.
float gMaintainTenthLandUnitAmount = 1;

int gFirstNavalUnit = cUnitTypeTrireme; 
float gMaintainFirstNavalUnitAmount = 3;
int gSecondNavalUnit = cUnitTypeJuggernaut;
float gMaintainSecondNavalUnitAmount = 2;
int gThirdNavalUnit = cUnitTypeCarcinos;
float gMaintainThirdNavalUnitAmount = 1;

int gEigthLandUnitDelay = 1000;

float gAttackStartDelayLong = cWaitWithAttacking; // In seconds.
float gAttackStartDelay = 150; // In seconds.
float gAttackWaveInterval = 460; // In seconds.
float gAttackStartSize = 8;
float gAttackMaxSize = 14;

float gNavalAttackStartDelay = 540; // In seconds.
float gNavalAttackWaveInterval = 300; // In Seconds.
float gNavalAttackStartSize = 3;
float gNavalAttackMaxSize = 5;

bool gAllowedToAttack = false;

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;
      int gDefendPlan3 = -1;
      int gDefendPlan4 = -1;

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
         gMaintainFirstLandUnitAmount = 4; // Hoplites
         gMaintainSecondLandUnitAmount = 2; // Hippeis
         gMaintainThirdLandUnitAmount = 2; // Toxotai
         gMaintainFourthLandUnitAmount = 2; // Hypaspists
         gMaintainFifthLandUnitAmount = 2; // Peltasts
         gMaintainSixthLandUnitAmount = 1; // Cyclopes
         gMaintainSeventhLandUnitAmount = 2; // Prodromoi
         gMaintainEighthLandUnitAmount = 1; // Chimerai

         gMaintainFirstNavalUnitAmount = 1; // Trireme
         gMaintainSecondNavalUnitAmount = 1; // Juggernaut

         gAttackStartDelay = 400; // In seconds.
         gAttackWaveInterval = 600; // In seconds.
         gAttackStartSize = 4;
         gAttackMaxSize = 6;
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSeventhLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainEighthLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gMaintainFirstNavalUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondNavalUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdNavalUnitAmount *= gDifficultyModifierMaintainUnit;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      gNavalAttackStartDelay *= gDifficultyModifierFirstAttack;
      gNavalAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gNavalAttackStartSize *= gDifficultyModifierAttackSizes;
      gNavalAttackMaxSize *= gDifficultyModifierAttackSizes;

      gTrainDelay *= gDifficultyModifierTrainDelay;
      gEigthLandUnitDelay += xsGetTime(); // Offset for starting time.

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
      data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);
      // Chimerai come later.
      data.addUnitToMaintain(gNinthLandUnit, gMaintainNinthLandUnitAmount);
      data.addUnitToMaintain(gTenthLandUnit, gMaintainTenthLandUnitAmount);

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
      gAttackWave.addAttackUnitType(gFifthLandUnit);
      gAttackWave.addAttackUnitType(gSixthLandUnit);
      gAttackWave.addAttackUnitType(gSeventhLandUnit);
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         gAttackWave.addAttackUnitType(gEighthLandUnit);
      }
      gAttackWave.addAttackUnitType(gNinthLandUnit);
      gAttackWave.addAttackUnitType(gTenthLandUnit);

      // Don't launch naval attacks on easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         data.addUnitToMaintain(gFirstNavalUnit, gMaintainFirstNavalUnitAmount);
         data.addUnitToMaintain(gSecondNavalUnit, gMaintainSecondNavalUnitAmount);
         data.addUnitToMaintain(gThirdNavalUnit, gMaintainThirdNavalUnitAmount);

         gNavalAttackWave.setName("gNavalAttackWave");
         gNavalAttackWave.setAttackStartTime(gAttackStartDelayLong);
         gNavalAttackWave.setAttackInterval(gNavalAttackWaveInterval);
         gNavalAttackWave.setAttackSize(gNavalAttackStartSize);
         gNavalAttackWave.setMaxAttackSize(gNavalAttackMaxSize);
         gNavalAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
         gNavalAttackWave.setIsNavalAttackWave();

         gNavalAttackWave.addAttackUnitType(gFirstNavalUnit);
         gNavalAttackWave.addAttackUnitType(gSecondNavalUnit);
         gNavalAttackWave.addAttackUnitType(gThirdNavalUnit);
      }

      gAttackWave.displayFirstAttackStats();
      gNavalAttackWave.displayFirstAttackStats();

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(177.0, 7.45, 169.0); // In front of the Citadel
      vector targetPoint = vector(77.0, 3.00, 239.0); // P1's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      // Naval Route
      vector startPoint2 = vector(267.0, 7.45, 323.0); // Entrance to the bay.
      vector targetPoint2 = vector(59.0, 3.00, 175.0); // By the isolated Settlement.

      int routeID2 = kbCreateAttackRouteWithPath("Naval Route To P1", startPoint2, targetPoint2);

      gNavalAttackWave.setGatherPoint(startPoint2);
      gNavalAttackWave.setTargetPoint(targetPoint2);
      gNavalAttackWave.setAttackRouteID(routeID2);
      gNavalAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 2; // Hoplites
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 3; // Hippeis
      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2; // Toxotai
      int fourthLandUnitSplitAmount = gMaintainFourthLandUnitAmount / 2; // Hypaspists
      int fifthLandUnitSplitAmount = gMaintainFifthLandUnitAmount / 3; // Peltasts
      int sixthLandUnitSplitAmount = gMaintainSixthLandUnitAmount / 2; // Cyclopes
      int seventhLandUnitSplitAmount = gMaintainSeventhLandUnitAmount / 2; // Prodromoi

      vector Defend_1 = vector(145.0, 0.0, 207.0); // Below the main corridor.
      vector Defend_2 = vector(181.0, 0.0, 233.0); // Above the main corridor.
      vector Defend_3 = vector(229.0, 0.0, 203.0); // Below the north gate.
      vector Defend_4 = vector(265.0, 0.0, 189.0); // Open area en route to the north.

      gDefendPlan1 = createDefendPlan("Defend Plan 1", kbBaseGetMainID(cMyID), 20.0, Defend_1, 10, Defend_1);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(gDefendPlan1, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Hoplites
      aiPlanAddUnitType(gDefendPlan1, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Hippeis
      aiPlanAddUnitType(gDefendPlan1, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount); // Hypaspists
      aiPlanAddUnitType(gDefendPlan1, gFifthLandUnit, 0, 0, fifthLandUnitSplitAmount); // Peltasts
      aiPlanAddUnitType(gDefendPlan1, gEighthLandUnit, 0, 0, 200); // Chimerai
      
      gDefendPlan2 = createDefendPlan("Defend Plan 2", kbBaseGetMainID(cMyID), 20.0, Defend_2, 10, Defend_2);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(gDefendPlan2, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Toxotai
      aiPlanAddUnitType(gDefendPlan2, gFifthLandUnit, 0, 0, fifthLandUnitSplitAmount); // Peltasts
      aiPlanAddUnitType(gDefendPlan2, gSixthLandUnit, 0, 0, sixthLandUnitSplitAmount); // Cyclopes
      aiPlanAddUnitType(gDefendPlan2, gSeventhLandUnit, 0, 0, seventhLandUnitSplitAmount); // Prodromoi

      gDefendPlan3 = createDefendPlan("Defend Plan 3", kbBaseGetMainID(cMyID), 20.0, Defend_3, 10, Defend_3);
      aiPlanSetVariableFloat(gDefendPlan3, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(gDefendPlan3, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Toxotai
      aiPlanAddUnitType(gDefendPlan3, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount); // Hypaspists
      aiPlanAddUnitType(gDefendPlan3, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Hippeis

      gDefendPlan4 = createDefendPlan("Defend Plan 4", kbBaseGetMainID(cMyID), 20.0, Defend_4, 10, Defend_4);
      aiPlanSetVariableFloat(gDefendPlan4, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(gDefendPlan4, gFifthLandUnit, 0, 0, fifthLandUnitSplitAmount); // Peltasts
      aiPlanAddUnitType(gDefendPlan4, gSeventhLandUnit, 0, 0, seventhLandUnitSplitAmount); // Prodromoi
      aiPlanAddUnitType(gDefendPlan4, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Hippeis
      aiPlanAddUnitType(gDefendPlan4, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Hoplites

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
            xsEnableRule("researchChampionInfantry");
         }
         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchChampionArchers");
            xsEnableRule("researchChampionCavalry");
            xsEnableRule("researchBurningPitch");
         }

         // Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchIronArmor");
            xsEnableRule("researchIronShields");
            xsEnableRule("researchFlamesOfTyphon");
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchShaftsOfPlague");
            xsEnableRule("researchChampionWarships");
         }

         done = true;
      }

      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         static bool addedChimeras = false;
         if (addedChimeras == false && time >= gEigthLandUnitDelay)
         {
            data.addUnitToMaintain(gEighthLandUnit, gMaintainEighthLandUnitAmount);
            addedChimeras = true;
         }
      }

      // Dispatch larger armies after 1200 seconds (Hard and Titan only).
      static bool larger_armies = false;
      if (larger_armies == false)
      {
         if (cDifficultyCurrent >= cDifficultyHard && time >= 1200)
         {
            gAttackMaxSize *= 1.15; // Armies are +15% larger.
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
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
               vector startPoint = vector(177.0, 7.0, 169.0); // In front of their TC.
               vector targetPoint = vector(77.0, 3.0, 238.0); // Southwest of the main gate.

               int pathID1 = kbPathCreate("Path that goes straight out the front gate.");
               kbPathAddWaypoint(pathID1, startPoint);
               kbPathAddWaypoint(pathID1, vector(173.0, 0.0, 211.0)); // Block #1
               kbPathAddWaypoint(pathID1, vector(149.0, 0.0, 241.0)); // Block #2
               kbPathAddWaypoint(pathID1, vector(143.0, 0.0, 293.0)); // Block #3
               kbPathAddWaypoint(pathID1, targetPoint);
               kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID1);
               added_west = true;
               gAllowedToAttack = true;
            }
            // Start attacking anyway if we're too late into the game; prevents exploits.
            else if (xsGetTime() >= 600)
            {
               // We found out that player 1 is hanging out in the west - updating our attack route.
               vector startPoint = vector(177.0, 7.0, 169.0); // In front of their TC.
               vector targetPoint = vector(77.0, 3.0, 238.0); // Southwest of the main gate.

               int pathID1 = kbPathCreate("Path that goes straight out the front gate.");
               kbPathAddWaypoint(pathID1, startPoint);
               kbPathAddWaypoint(pathID1, vector(173.0, 0.0, 211.0)); // Block #1
               kbPathAddWaypoint(pathID1, vector(149.0, 0.0, 241.0)); // Block #2
               kbPathAddWaypoint(pathID1, vector(143.0, 0.0, 293.0)); // Block #3
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

               vector startPoint = vector(177.0, 7.0, 169.0); // In front of their TC.
               vector targetPoint = vector(77.0, 3.0, 238.0); // Southwest of the main gate.

               int pathID2 = kbPathCreate("Path that goes to the northern Settlement, then by the front gate.");
               kbPathAddWaypoint(pathID2, startPoint);
               kbPathAddWaypoint(pathID2, vector(251.0, 0.0, 185.0)); // Block #1
               kbPathAddWaypoint(pathID2, vector(367.0, 0.0, 287.0)); // Block #2
               kbPathAddWaypoint(pathID2, vector(231.0, 0.0, 261.0)); // Block #3
               kbPathAddWaypoint(pathID2, vector(157.7, 0.0, 307.0)); // Block #4
               kbPathAddWaypoint(pathID2, vector(105.0, 0.0, 285.0)); // Block #5
               kbPathAddWaypoint(pathID2, targetPoint);
               kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID2);
               added_north = true;
               gAllowedToAttack = true;
            }
            else if (xsGetTime() >= 600 && added_north == false)
            {
               // We found out that player 1 is hanging out in the north - updating our attack route.

               vector startPoint = vector(177.0, 7.0, 169.0); // In front of their TC.
               vector targetPoint = vector(77.0, 3.0, 238.0); // Southwest of the main gate.

               int pathID2 = kbPathCreate("Path that goes to the northern Settlement, then by the front gate.");
               kbPathAddWaypoint(pathID2, startPoint);
               kbPathAddWaypoint(pathID2, vector(251.0, 0.0, 185.0)); // Block #1
               kbPathAddWaypoint(pathID2, vector(367.0, 0.0, 287.0)); // Block #2
               kbPathAddWaypoint(pathID2, vector(231.0, 0.0, 261.0)); // Block #3
               kbPathAddWaypoint(pathID2, vector(157.7, 0.0, 307.0)); // Block #4
               kbPathAddWaypoint(pathID2, vector(105.0, 0.0, 285.0)); // Block #5
               kbPathAddWaypoint(pathID2, targetPoint);
               kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID2);
               added_north = true;
               gAllowedToAttack = true;
            }
         }
      }

      gAttackWave.update();
      gNavalAttackWave.update();
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

void startAttackingWater()
{
   gNavalAttackWave.setAttackStartTime(gNavalAttackStartDelay);
   
   vector startPoint = vector(267.0, 7.45, 323.0); // Start Point.
   vector targetPoint = vector(59.0, 3.00, 175.0); // By the isolated Settlement

   // Left flank route.
   int pathID3 = kbPathCreate("Naval Route 1");
   kbPathAddWaypoint(pathID3, startPoint);
   kbPathAddWaypoint(pathID3, vector(101.0, 0.0, 333.0)); // Block #1.
   kbPathAddWaypoint(pathID3, vector(27.0, 0.0, 251.0)); // Block #2.
   kbPathAddWaypoint(pathID3, vector(31.0, 0.0, 137.0)); // Block #3.
   kbPathAddWaypoint(pathID3, targetPoint);
   kbAttackRouteAddPath(gNavalAttackWave.mAttackRouteID, pathID3);
   debugAttackWave("We have a route!");

   // Right flank route.
   int pathID4 = kbPathCreate("Naval Route 2");
   kbPathAddWaypoint(pathID4, startPoint);
   kbPathAddWaypoint(pathID4, vector(101.0, 0.0, 333.0)); // Block #1.
   kbPathAddWaypoint(pathID4, vector(27.0, 0.0, 251.0)); // Block #2.
   kbPathAddWaypoint(pathID4, vector(83.0, 0.0, 173.0)); // Block #3.
   kbPathAddWaypoint(pathID4, targetPoint);
   kbAttackRouteAddPath(gNavalAttackWave.mAttackRouteID, pathID4);
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
         // Champion Infantry
            rule researchChampionInfantry
            inactive
            minInterval 360
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
         // Champion Archers
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
         // Champion Cavalry
            rule researchChampionCavalry
            inactive
            minInterval 640
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
               if (kbTechGetStatus(cTechBronzeShields) == cTechStatusActive)
               {
                  debugAttackWave("Starting Iron Shields research plan.");
                  researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
                  xsDisableRule("researchIronShields");
               }
            }
         // Flames of Typhon
            rule researchFlamesOfTyphon
            inactive
            minInterval 1200
            {
               debugAttackWave("Starting Flames of Typhon research plan.");
               researchSimpleTech(cTechFlamesOfTyphon, cUnitTypeTemple, -1, 60);
               xsDisableRule("researchFlamesOfTyphon");
            }

      // TITAN ONLY:
         // Shafts of Plague
            rule researchShaftsOfPlague
            inactive
            minInterval 840
            {
               debugAttackWave("Starting Shafts of Plague research plan.");
               researchSimpleTech(cTechShaftsOfPlague, cUnitTypeArcheryRange, -1, 60);
               xsDisableRule("researchShaftsOfPlague");
            }
         // Champion Warships
            rule researchChampionWarships
            inactive
            minInterval 600
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