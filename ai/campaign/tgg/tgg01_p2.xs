//==============================================================================
/* tgg01_p2.xs
   
   Red Norse player owning the large base in the eastern half of the map. Trains
   a mix of human soldiers and myth units.

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

float gTrainDelay = 20; // In seconds.

int gFirstLandUnit = cUnitTypeRaidingCavalry; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 4;
int gSecondLandUnit = cUnitTypeThrowingAxeman; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 4;
int gThirdLandUnit = cUnitTypeHersir; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 2;
int gFourthLandUnit = cUnitTypeTroll; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 2;
int gFifthLandUnit = cUnitTypeHuskarl; // Gets trained starting in Heroic.
float gMaintainFifthLandUnitAmount = 4;
int gSixthLandUnit = cUnitTypeFrostGiant; // Gets trained starting in Heroic.
float gMaintainSixthLandUnitAmount = 3;

float gMaxVillagerCount = 12;
float gAttackStartDelay = 600; // In seconds.
float gAttackWaveInterval = 420; // In seconds.
float gAttackStartSize = 5;
float gAttackMaxSize = 16;

float gHeroicAgeUpTime = 1800; // In seconds.

vector gOurTCLocation = vector(150.0, 0, 152.0);
int gLandDefendPlan = -1;

Strategy scenarioAttackWaveStrategy()
{

   xsEnableRule("moveDefendPlan");

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
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;
      gHeroicAgeUpTime *= gDifficultyModifierAgeUp;
      gHeroicAgeUpTime += xsGetTime(); // Increase time based on the length of the intro cinematic.

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Raiding Cavalry
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Throwing Axemen
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Hersirs
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Trolls

      // Huskarls and Frost Giants are not produced until later.
   
      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);

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

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticOxCartTraining, true);

      gAttackWave.setPlayerToAttack(1); // Attack P1!

      // Where does our attack start and end.
      vector startPoint = vector(145.0, 0.0, 167.0); // Behind Frost GP zone.
      vector targetPoint = vector(54.0, 0.0, 306.0); // Brokk's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 to Town Center");
      kbPathAddWaypoint(pathID1, startPoint);
      // There were no waypoints in legacy.
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);
      
      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

       
      
      gLandDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 46.0, startPoint, 10);
      aiPlanSetVariableFloat(gLandDefendPlan, cDefendPlanEngageRange, 0, 35.0);
      
      // We don't want the wrong units to join the defense plan.
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeRaidingCavalry, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeThrowingAxeman, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeHersir, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeTroll, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeHuskarl, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeFrostGiant, 0, 0, 200);
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

      int age = kbPlayerGetAge(cMyID);
      int time = xsGetTime();

      // CLASSICAL AGE TECH RULES //
      // All Difficulties:
      // Moderate and Up:
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         researchSimpleTech(cTechMasons, cUnitTypeTownCenter, -1, 60);
      }

      // Hard and Up:
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         researchSimpleTech(cTechCaveTroll, cUnitTypeTemple, -1, 60);
         researchSimpleTech(cTechHallOfThanes, cUnitTypeLonghouse, -1, 60);
      }

      if (needResearchHeroic == true && age == cAge2 && time >= gHeroicAgeUpTime)
      {
         if (researchSimpleTech(cTechHeroicAgeNjord, cUnitTypeTownCenter, -1, 75) == true)
         {
            debugAttackWave("Starting Heroic Age research plan.");
            needResearchHeroic = false;
         }
      }
      else if (done == false && age >= cAge3)
      {
         data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount); // Start training Huskarls.
         data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount); // Start training Frost Giants.
         data.setTrainDelay(gFifthLandUnit, gTrainDelay);
         data.setTrainDelay(gSixthLandUnit, gTrainDelay);
         gAttackWave.addAttackUnitType(gFifthLandUnit); // Start dispatching Huskarls.
         gAttackWave.addAttackUnitType(gSixthLandUnit); // Start dispatching Frost Giants.
         done = true;

         // HEROIC AGE TECH RULES //
         // All Difficulties:

         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         { 
            researchSimpleTech(cTechBronzeWeapons, cUnitTypeArmory, -1, 60);
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            researchSimpleTech(cTechHeavyInfantry, cUnitTypeLonghouse, -1, 60);
            researchSimpleTech(cTechArchitects, cUnitTypeTownCenter, -1, 60);
            researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechBallistics, cUnitTypeArmory, -1, 60);
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            researchSimpleTech(cTechHeavyCavalry, cUnitTypeGreatHall, -1, 60);
            researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 60); 
         }
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}


// Set up the strategy.
void tgg01StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(159.00, 0.00, 70.00), 121);

   setOverrideStrategy(tgg01StrategySetup);

   gOverrideFarmCount = 8; // Don't overdo the Farms.
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

// Frost triggered.
rule castFrost
inactive
minInterval 3
{
   if (aiCastGodPowerAtPosition(cProtoPowerFrost, vector(148.0, 0.0, 208.0)) == true)
   {
      debugAttackWave("Casted Frost!");
      xsDisableRule("castFrost");
   }
   else
   {
      debugAttackWave("That didn't work...");
   }
}

// Other Frost location.
rule castOtherFrost
inactive
minInterval 3
{
   if (aiCastGodPowerAtPosition(cProtoPowerFrost, vector(104.0, 0.0, 44.0)) == true)
   {
      debugAttackWave("Casted Frost!");
      xsDisableRule("castOtherFrost");
   }
   else
   {
      debugAttackWave("That didn't work...");
   }
}

// Move defend location further back if the enemy has broken through out front gate, so that we don't infinitely trickle units to the front (that the player now controls).
rule moveDefendPlan
inactive
minInterval 10
{
   // If we can't find our forward Town Center, that means it has been destroyed.
   int towncenter = getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, vector(151.0, 0.0, 153.0), 20.0);
   int hillfort = getUnitByLocation(cUnitTypeHillFort, cMyID, cUnitStateAlive, vector(151.0, 0.0, 153.0), 30.0);
   if (towncenter < 0 && hillfort < 0)
   {
      debugAttackWave("Our forward Town Center and Hill Forts are down. Moving town defense to our rear Town Center!");
      vector newDefendPoint = vector(215.0, 0.0, 63.0);
      aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanTargetPoint, 0, newDefendPoint);
      aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanGatherPoint, 0, newDefendPoint);
      aiPlanSetVariableInt(gLandDefendPlan, cDefendPlanTargetMode, 0, cDefendPlanTargetModePoint);
      xsDisableRule("moveDefendPlan");
   }
}