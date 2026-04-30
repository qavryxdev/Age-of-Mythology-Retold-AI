//==============================================================================
/* fott18_p2.xs

   Red Greek player owning the base in the north (Troy). Sends attacks of Hoplite, Hippeis, Prodromos, Petroboli.
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
int gFirstLandUnit = cUnitTypeSpearman; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 5;
int gSecondLandUnit = cUnitTypeAxeman; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 5;
int gThirdLandUnit = cUnitTypeSlinger; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 5;
int gFourthLandUnit = cUnitTypeAnubite; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 6;
int gFifthLandUnit = cUnitTypePriest; // Gets trained from the start.
float gMaintainFifthLandUnitAmount = 2;
float gMaintainFifthLandUnitIncrease = 4;

int gExtraLandUnitDelay1 = 640; // In seconds.
int gExtraLandUnitDelay2 = 960; // In seconds.
int gSixthLandUnit = cUnitTypeWarElephant; // Gets trained after gExtraLandUnitDelay1.
float gMaintainSixthLandUnitAmount = 4;
int gSeventhLandUnit = cUnitTypeSiegeTower; // Gets trained after gExtraLandUnitDelay2.
float gMaintainSeventhLandUnitAmount = 2;
int gEighthLandUnit = cUnitTypeScarab; // Gets trained after gExtraLandUnitDelay1.
float gMaintainEighthLandUnitAmount = 2;

float gMaxVillagerCount = 28;
float gAttackStartDelay = 360; // In seconds.
float gAttackWaveInterval = 240; // In seconds.
float gAttackStartSize = 8;
float gAttackMaxSize = 14;
int gTamariskDefendPlanID = -1;
int gMythicAgeUpTime = 1600; // In seconds.

int gGateBuildPlan = -1;
int gGateBuildPlan2 = -1;
int gGateDefendPlan = -1;
int gGateDefendPlan2 = -1;

// Defend Points (Divided to prevent clogging from blocking attack waves)
   // Inner Defense 1
      const float InnerDefense1GatherDistance = 10.0;
      const float InnerDefense1EngageRange = 40.0;
      const vector InnerDefense1Position = vector(191.00, 0.00, 259.00);

   // Inner Defense 2
      const float InnerDefense2GatherDistance = 10.0;
      const float InnerDefense2EngageRange = 40.0;
      const vector InnerDefense2Position = vector(265.00, 0.00, 233.00);

   // Outer Defense 1
      const float OuterDefense1GatherDistance = 10.0;
      const float OuterDefense1EngageRange = 40.0;
      const vector OuterDefense1Position = vector(119.00, 0.00, 241.00);

   // Outer Defense 2
      const float OuterDefense2GatherDistance = 10.0;
      const float OuterDefense2EngageRange = 30.0;
      const vector OuterDefense2Position = vector(243.00, 0.00, 129.00);


// TC Defense
const float TC1DefendPlanGatherDistance = 10.0;
const float TC1DefendPlanEngageRange = 40.0;
const vector landTC1Position = vector(164.65, 0.00, 335.79);

const float TC2DefendPlanGatherDistance = 15.0;
const float TC2DefendPlanEngageRange = 30.0;
const vector landTC2Position = vector(117.70, 0.00, 291.05);

Strategy scenarioAttackWaveStrategy()
{

   xsEnableRule("useVision");
   xsEnableRule("useSerpents");
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      xsEnableRule("defendTamariskTree");
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
      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitIncrease *= gDifficultyModifierMaintainUnit;
      gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSeventhLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainEighthLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;
      gExtraLandUnitDelay1 += xsGetTime(); // Offset for starting time.
      gExtraLandUnitDelay2 += xsGetTime(); // Offset for starting time.
      gMythicAgeUpTime *= gDifficultyModifierAgeUp; // Offset for starting time.

      // Certain parameters are way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gAttackStartSize = 4;
         gAttackMaxSize = 6;
         gTrainDelay = 30; // It's more possible to conquer Gargarensis if you want.
      }

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);
      data.setTrainDelay(gFifthLandUnit, gTrainDelay);

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
      // Anubites don't attack!
      gAttackWave.addAttackUnitType(gFifthLandUnit);

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(173.0, 1.0, 185.0); // Above the Tamarisk Tree.
      vector targetPoint = vector(131.0, 4.5, 56.0); // P1's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 center");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(175.0, 1.0, 171.0)); // Next to the northern Anubite near the Tamarisk Tree.
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
            static int counter = 0;
            if (counter == 0)
            {
               xsEnableRule("expandAttackRoutes");
               counter++; // Only do this for the first attack.
            }
         }
      );

      
      int landDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 50.0, startPoint, 10);
      aiPlanSetVariableFloat(landDefendPlan, cDefendPlanEngageRange, 0, 45.0);
      // Only Scorpion Men are here.
      aiPlanAddUnitType(landDefendPlan, cUnitTypeScorpionMan, 0, 0, 200); // Scorpion Men

      // Defend Plan Division
      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 2; // Spearmen
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 2; // Axemen
      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2; // Slingers

      int sixthLandUnitSplitAmount = gMaintainSixthLandUnitAmount / 2; // War Elephants
      int eighthLandUnitSplitAmount = gMaintainSeventhLandUnitAmount / 2; // Scarabs

      // Inner Defense 1 (All siege, ½ War Elephants, ½ Scarabs)
         int InnerDefensePlan1 = createDefendPlan("Inner Defense 1", kbBaseGetMainID(cMyID), InnerDefense1GatherDistance, InnerDefense1Position, 10);
         aiPlanSetVariableFloat(InnerDefensePlan1, cDefendPlanEngageRange, 0, InnerDefense1EngageRange);
         // UNITS MAINTAINED:
            aiPlanAddUnitType(InnerDefensePlan1, gSixthLandUnit, 0, 0, sixthLandUnitSplitAmount);
            aiPlanAddUnitType(InnerDefensePlan1, gSeventhLandUnit, 0, 0, gMaintainSeventhLandUnitAmount);
            aiPlanAddUnitType(InnerDefensePlan1, gEighthLandUnit, 0, 0, eighthLandUnitSplitAmount);

      // Inner Defense 2 (½ War Elephants, ½ Scarabs)
         int InnerDefensePlan2 = createDefendPlan("Inner Defense 2", kbBaseGetMainID(cMyID), InnerDefense2GatherDistance, InnerDefense2Position, 10);
         aiPlanSetVariableFloat(InnerDefensePlan2, cDefendPlanEngageRange, 0, InnerDefense2EngageRange);
         // UNITS MAINTAINED:
            aiPlanAddUnitType(InnerDefensePlan2, gSixthLandUnit, 0, 0, sixthLandUnitSplitAmount);
            aiPlanAddUnitType(InnerDefensePlan2, gEighthLandUnit, 0, 0, eighthLandUnitSplitAmount);

      // Outer Defense 1 (½ Spearmen, ½ Axemen, ½ Slingers)
         int OuterDefensePlan1 = createDefendPlan("Outer Defense 1", kbBaseGetMainID(cMyID), OuterDefense1GatherDistance, OuterDefense1Position, 10);
         aiPlanSetVariableFloat(OuterDefensePlan1, cDefendPlanEngageRange, 0, OuterDefense1EngageRange);
         // UNITS MAINTAINED:
            aiPlanAddUnitType(OuterDefensePlan1, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount);
            aiPlanAddUnitType(OuterDefensePlan1, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount);
            aiPlanAddUnitType(OuterDefensePlan1, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount);

      // Outer Defense 2 (½ Spearmen, ½ Axemen, ½ Slingers, Priests)
         int OuterDefensePlan2 = createDefendPlan("Outer Defense 2", kbBaseGetMainID(cMyID), OuterDefense2GatherDistance, OuterDefense2Position, 10);
         aiPlanSetVariableFloat(OuterDefensePlan2, cDefendPlanEngageRange, 0, OuterDefense2EngageRange);
         // UNITS MAINTAINED:
            aiPlanAddUnitType(OuterDefensePlan2, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount);
            aiPlanAddUnitType(OuterDefensePlan2, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount);
            aiPlanAddUnitType(OuterDefensePlan2, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount);
            aiPlanAddUnitType(OuterDefensePlan2, gFifthLandUnit, 0, 0, 200);

      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gTamariskDefendPlanID = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 50.0, vector(144.0, 4.45, 166.0), 20);
         aiPlanSetVariableFloat(landDefendPlan, cDefendPlanEngageRange, 0, 25.0);
         // We only put units in this plan if we've found the player's Laborers near the Tamarisk Tree.
         aiPlanAddUnitType(gTamariskDefendPlanID, gFourthLandUnit, 0, 0, 200); // Anubites
         aiPlanAddUnitType(gTamariskDefendPlanID, gFifthLandUnit, 0, 0, 200); // Priests
      }

      // Build Walls and a Migdol to guard the Tamarisk Tree on Moderate and up.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         xsEnableRuleGroup("ruleGroupBuildPlans");
      }
      
      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done1 = false;
      static bool done2 = false;
      static bool reachedMythic = false;

      int time = xsGetTime();

      // Increases do not occur on Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         if (done1 == false && time >= gExtraLandUnitDelay1)
         {
            done1 = true;

            data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
            data.addUnitToMaintain(gEighthLandUnit, gMaintainEighthLandUnitAmount);

            data.setTrainDelay(gSixthLandUnit, gTrainDelay);
            data.setTrainDelay(gEighthLandUnit, gTrainDelay);

            gAttackWave.addAttackUnitType(gSixthLandUnit);
            gAttackWave.addAttackUnitType(gEighthLandUnit);

            // Update attack size parameters based on the enlarged army composition.
            gAttackMaxSize *= 1.15; // Attack size increases by +15%
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }
         // Begin training Siege Towers and make more Priests.
         if (done2 == false && time >= gExtraLandUnitDelay2)
         {
            done2 = true;
            data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);
            data.setTrainDelay(gSeventhLandUnit, gTrainDelay);
            gAttackWave.addAttackUnitType(gSeventhLandUnit);

            // Update attack size parameters based on the enlarged army composition.
            gAttackMaxSize *= 1.10; // Attack size increases by +5%
            gAttackWave.setMaxAttackSize(gAttackMaxSize);

            // Bump our Priest maintain.
            int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gFifthLandUnit);
            aiPlanSetVariableInt(
               planID, cTrainPlanNumberToMaintain, 0, gMaintainFifthLandUnitAmount + gMaintainFifthLandUnitIncrease
            );
         }
      }


      static bool ageup = false;
      int age = kbPlayerGetAge(cMyID);
      if (ageup == false)
      {
         if (age < cAge4 && time >= gMythicAgeUpTime)
         {
            researchSimpleTech(cTechMythicAgeHorus, cUnitTypeTownCenter, -1, 75);
         }
         else if (age >= cAge4)
         {
            xsEnableRule("useTornado");
            ageup = true;
         }
      }

      // * * * TECH RULES * * * //

      // HEROIC AGE //
      static bool heroic_techs = false;
      if (age >= cAge3 && heroic_techs == false)
      {
         // Tech Rules for All Difficulties:
         xsEnableRule("researchBronzeWeapons");
         xsEnableRule("researchBowSaw");
         xsEnableRule("researchIrrigation");
         xsEnableRule("researchShaftMine");

         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            // Heavy Slingers is already researched on Hard and Titan at the start.
            if (cDifficultyCurrent == cDifficultyModerate)
            {
               xsEnableRule("researchHeavySlingers");
            }
            // Heavy Spearmen and Axemen are already researched on Titan at the start.
            if (cDifficultyCurrent != cDifficultyTitan)
            {
               xsEnableRule("researchHeavySpearmen");
               xsEnableRule("researchHeavyAxemen");
            }
            xsEnableRule("researchBronzeArmor");
            xsEnableRule("researchBronzeShields");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchArchitects");
            xsEnableRule("researchSlingsOfTheSun");
            xsEnableRule("researchForceOfTheWestWind");
            xsEnableRule("researchHeavyWarElephants");
            xsEnableRule("researchBallistics");
         }

         // Tech Rules for Titan only:
         heroic_techs = true;
      }

      // MYTHIC AGE //
      if (age >= cAge4 && reachedMythic == false)
      {
         // Tech Rules for All Difficulties:
         xsEnableRule("researchCarpenters");
         xsEnableRule("researchFloodControl");
         xsEnableRule("researchQuarry");
         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchChampionSpearmen");
            xsEnableRule("researchChampionAxemen");
            xsEnableRule("researchChampionSlingers");
         }
         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchIronArmor");
         }
         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchChampionWarElephants");
            xsEnableRule("researchIronShields");
            xsEnableRule("researchEngineers");
         }
         // Change the boolean back to false so the rules aren't enabled multiple times.
         reachedMythic = true;
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott18StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(223.00, 0.00, 245.00), 80); // Covering our large base.
   createOverrideGatherBase(vector(137.00, 0.00, 215.00), 25);
   createOverrideGatherBase(vector(203.00, 0.00, 173.00), 25);
   createOverrideGatherBase(vector(215.00, 0.00, 135.00), 25);

   gTimeToFarm = true;
   setOverrideStrategy(fott18StrategySetup);

   gRBDSystem.setMaxFarmsPerBase(32);
   gRBDSystem.setMaxFarmsPerIteration(32);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}


// Build Gate 1

rule buildGate1
inactive
minInterval 30
group ruleGroupBuildPlans
{
   xsSetRuleMinInterval("buildGate1", 10);

   vector centerPosition = vector(122.00, 0.0, 167.0);
   int numEnemyVills = getUnitCountByLocation(cUnitTypeVillagerEgyptian, 1, cUnitStateAlive, vector(145.0, 0.0, 167.0), 15.0);
   if (numEnemyVills >= 3)
   {
      // Build plan.
      gGateBuildPlan = aiPlanCreate("Wall/Gate Plan", cPlanBuildWall);
      aiPlanSetVariableInt(gGateBuildPlan, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeStraight);
      aiPlanAddUnitType(gGateBuildPlan, cUnitTypeAbstractVillager, 0, 1, 1);
      aiPlanSetVariableVector(gGateBuildPlan, cBuildWallPlanWallStart, 0, vector(115.0, 0.0, 171.0));
      aiPlanSetVariableVector(gGateBuildPlan, cBuildWallPlanWallEnd, 0, vector(129.0, 0.0, 163.0));
      aiPlanSetVariableInt(gGateBuildPlan, cBuildWallPlanNumberOfGates, 0, 1);
      aiPlanSetPriority(gGateBuildPlan, 99);
      aiPlanSetEventHandler(gGateBuildPlan, cPlanEventStateChange, "gateBuildPlanEventHandler");
      xsEnableRule("killGatePlan1");
      xsDisableRule("buildGate1");
   }
   else
   {
      debugAttackWave("numEnemyVills: " + numEnemyVills + ", not building the Wall & Gate now.");
   }
}


rule buildGate2
inactive
minInterval 30
group ruleGroupBuildPlans
{
   xsSetRuleMinInterval("buildGate2", 10);

   vector centerPosition = vector(162.00, 0.0, 143.0);
   int numEnemyVills = getUnitCountByLocation(cUnitTypeVillagerEgyptian, 1, cUnitStateAlive, vector(145.0, 0.0, 167.0), 15.0);
   if (numEnemyVills >= 3)
   {
      // Build plan.
      gGateBuildPlan2 = aiPlanCreate("Wall/Gate Plan", cPlanBuildWall);
      aiPlanSetVariableInt(gGateBuildPlan2, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeStraight);
      aiPlanAddUnitType(gGateBuildPlan2, cUnitTypeAbstractVillager, 0, 1, 1);
      aiPlanSetVariableVector(gGateBuildPlan2, cBuildWallPlanWallStart, 0, vector(157.0, 0.0, 143.0));
      aiPlanSetVariableVector(gGateBuildPlan2, cBuildWallPlanWallEnd, 0, vector(167.0, 0.0, 143.0));
      aiPlanSetVariableInt(gGateBuildPlan2, cBuildWallPlanNumberOfGates, 0, 1);
      aiPlanSetPriority(gGateBuildPlan2, 99);
      aiPlanSetEventHandler(gGateBuildPlan2, cPlanEventStateChange, "gateBuildPlanEventHandler2");
      xsEnableRule("killGatePlan2");
      xsDisableRule("buildGate2");
   }
   else
   {
      debugAttackWave("numEnemyVills: " + numEnemyVills + ", not building the Wall & Gate now.");
   }
}




void gateBuildPlanEventHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateDone || state == cPlanStateFailed) // We're done or it failed, whatever just end the defend plan.
   {
      debugAttackWave("Our gate build plan is done, destroying our accompanying defend plan.");
      if (gGateDefendPlan != -1)
      {
         aiPlanDestroy(gGateDefendPlan);
      }
      xsDisableRule("killGatePlan1");
   }
}
void gateBuildPlanEventHandler2(int planID = -1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateDone || state == cPlanStateFailed) // We're done or it failed, whatever just end the defend plan.
   {
      debugAttackWave("Our gate build plan is done, destroying our accompanying defend plan.");
      if (gGateDefendPlan2 != -1)
      {
         aiPlanDestroy(gGateDefendPlan2);
      }
      xsDisableRule("killGatePlan2");
   }
}

rule gateDefenders1
inactive
minInterval 30
group ruleGroupBuildPlans
{
   int fourthLandUnitDefendAmount = selectByDifficulty(3, 6, 6, 6, 6, 6);
   
   gGateDefendPlan = createDefendPlan("Gate Defense 1", kbBaseGetMainID(cMyID), 15.0, vector(131.00, 0.00, 175.00), 10);
   aiPlanSetVariableFloat(gGateDefendPlan, cDefendPlanEngageRange, 0, 25.0);
   aiPlanAddUnitType(gGateDefendPlan, gFourthLandUnit, 0, 0, fourthLandUnitDefendAmount);

   xsDisableRule("gateDefenders1");
}
rule gateDefenders2
inactive
minInterval 30
group ruleGroupBuildPlans
{
   int fourthLandUnitDefendAmount = selectByDifficulty(3, 6, 6, 6, 6, 6);
   
   gGateDefendPlan2 = createDefendPlan("Gate Defense 2", kbBaseGetMainID(cMyID), 15.0, vector(161.00, 0.00, 151.00), 10);
   aiPlanSetVariableFloat(gGateDefendPlan2, cDefendPlanEngageRange, 0, 25.0);
   aiPlanAddUnitType(gGateDefendPlan2, gFourthLandUnit, 0, 0, fourthLandUnitDefendAmount);

   xsDisableRule("gateDefenders2");
}

rule killGatePlan1
inactive
minInterval 300
{
   if (gGateDefendPlan != -1)
   {
      aiPlanDestroy(gGateDefendPlan);
   }
   xsDisableRule("killGatePlan1");
}
rule killGatePlan2
inactive
minInterval 300
{
   if (gGateDefendPlan2 != -1)
   {
      aiPlanDestroy(gGateDefendPlan2);
   }
   xsDisableRule("killGatePlan2");
}

// Build Migdol Stronghold

rule buildMigdol
inactive
minInterval 540
group ruleGroupBuildPlans
{
   xsSetRuleMinInterval("buildMigdol", 10);

   vector buildPosition3 = vector(117.0, 0.00, 181.0); // Upper-Left of Temple.
   int numEnemyVills = getUnitCountByLocation(cUnitTypeVillagerEgyptian, 1, cUnitStateAlive, vector(145.0, 0.0, 167.0), 15.0);
   if (numEnemyVills >= 3)
   {
      // Build plan.
      int buildPlanID = aiPlanCreate("Migdol Build Plan", cPlanBuild, -1);
      int bpID = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID));
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeMigdolStronghold);
      kbBuildingPlacementSetCenterPosition(bpID, buildPosition3, 8.0);
      kbBuildingPlacementSetStepSize(bpID, 0.5);
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementAddPositionInfluence(bpID, buildPosition3, 100.0, 50.0, cFalloffLinear);
      aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, cUnitTypeMigdolStronghold);
      aiPlanAddUnitType(buildPlanID, cUnitTypeVillagerEgyptian, 2, 2, 2);
      aiPlanSetPriority(buildPlanID, 99);
      xsDisableRule("buildMigdol");
   }
   else
   {
      debugAttackWave("numEnemyVills: " + numEnemyVills + ", not building the Migdol now.");
   }
}


// 30 Seconds after the first attack goes out we expand our possible routes.
rule expandAttackRoutes
inactive
minInterval 30
{

   int pathID2 = kbPathCreate("Path 2 Left");
   kbPathAddWaypoint(pathID2, vector(173.0, 1.0, 185.0)); // Above the Tamarisk Tree.
   kbPathAddWaypoint(pathID2, vector(103.0, 1.0, 209.0)); // Waypoint between the 2 Towers.
   kbPathAddWaypoint(pathID2, vector(29.0, 1.0, 181.0)); // By the western Settlement.
   kbPathAddWaypoint(pathID2, vector(131.0, 4.5, 56.0)); // P1's TC.
   kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID2);

   int pathID3 = kbPathCreate("Path 3 Right");
   kbPathAddWaypoint(pathID3, vector(173.0, 1.0, 185.0)); // Above the Tamarisk Tree.
   kbPathAddWaypoint(pathID3, vector(227.0, 1.0, 115.0)); // By the right gold mines.
   kbPathAddWaypoint(pathID3, vector(249.0, 4.0, 78.0));
   kbPathAddWaypoint(pathID3, vector(266.0, 6.0, 15.0));
   kbPathAddWaypoint(pathID3, vector(205.0, 4.5, 45.0));
   kbPathAddWaypoint(pathID3, vector(131.0, 4.5, 56.0)); // P1's TC.
   kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID3);

   gAttackWave.update();
   debugAttackWave("Expanded attack routes.");
   xsDisableRule("expandAttackRoutes");
}

// On hard and titan defend the Tamarisk Tree continuously.
rule defendTamariskTree
inactive
minInterval 5
{
   int numLaborers = getUnitCountByLocation(cUnitTypeVillagerEgyptian, 1, cUnitStateAlive, vector(144.0, 4.45, 166.0), 20.0);
   if (numLaborers >= 1)
   {
      debugAttackWave("P1 Laborers detected near the Tamarisk Tree!");
      aiPlanAddUnitType(gTamariskDefendPlanID, gFourthLandUnit, 2, 2, 200);
      aiPlanAddUnitType(gTamariskDefendPlanID, gFifthLandUnit, 2, 2, 200);
      aiPlanSetPriority(gTamariskDefendPlanID, 20);
   }
   else
   {
      debugAttackWave("Didn't find P1 Laborers near the Tamarisk Tree!");
      aiPlanAddUnitType(gTamariskDefendPlanID, gFourthLandUnit, 0, 0, 0);
      aiPlanAddUnitType(gTamariskDefendPlanID, gFifthLandUnit, 0, 0, 0);
      aiPlanSetPriority(gTamariskDefendPlanID, 5);
   }
}

// Cast vision on the player's TC.
rule useVision
inactive
minInterval 120
{
   // This should never fail.
   aiCastGodPowerAtPosition(cProtoPowerVision, vector(131.0, 4.5, 56.0));
   debugAttackWave("Casted Vision!");
   xsDisableRule("useVision");
}

// Use Serpents to protect the Tamarisk Tree.
rule useSerpents
inactive
minInterval 5
{
   int numLaborers = getUnitCountByLocation(cUnitTypeVillagerEgyptian, 1, cUnitStateAlive, vector(144.0, 4.45, 166.0), 20.0);
   debugAttackWave("numLaborers for casting Serpents: " + numLaborers);
   if (numLaborers >= 3)
   {
      // Cast it a bit to the south of the Tamarisk Tree, on our revealer.
      if (aiCastGodPowerAtPosition(cProtoPowerPlagueOfSerpents, vector(142.0, 4.45, 161.0)) == true)
      {
         debugAttackWave("Casted Serpents!");
         xsDisableRule("useSerpents");
      }
   }
}

// Use tornado once we've reached one of the player's Town Centers.
rule useTornado
inactive
minInterval 5
{
   int queryID = useSimpleUnitQuery(cUnitTypeTownCenter, 1, cUnitStateAlive);
   kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateSeeable);
   int numTownCenters = kbUnitQueryExecute(queryID);
   debugAttackWave("numTownCenters for casting Tornado: " + numTownCenters);
   if (numTownCenters > 0)
   {
      if (aiCastGodPowerAtPosition(cProtoPowerTornado, kbUnitGetPosition(kbUnitQueryGetResult(queryID, 0))) == true)
      {
         debugAttackWave("Casted Tornado!");
         xsDisableRule("useTornado");
      }
   }
}

// TECH RULES //
   // *** HEROIC AGE TECHS ***
      // ALL DIFFICULTIES
         // Bronze Weapons
            rule researchBronzeWeapons
            inactive
            minInterval 520
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
         // Shaft Mine
            rule researchShaftMine
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechShaftMine) == cTechStatusActive)
               {
                  xsDisableRule("researchShaftMine");
                  return;
               }
               else if (kbTechGetStatus(cTechShaftMine) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Shaft Mine research plan.");
                  researchSimpleTech(cTechShaftMine, cUnitTypeMiningCamp, -1, 60);
                  return;
               }
            }
         // Irrigation
            rule researchIrrigation
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
            {
               researchSimpleTech(cTechIrrigation, cUnitTypeGranary, -1, 60);
               xsDisableRule("researchIrrigation"); // Disable self.
            }
         // Bow Saw
            rule researchBowSaw
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechBowSaw) == cTechStatusActive)
               {
                  xsDisableRule("researchBowSaw");
                  return;
               }
               else if (kbTechGetStatus(cTechBowSaw) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Bow Saw research plan.");
                  researchSimpleTech(cTechBowSaw, cUnitTypeLumberCamp, -1, 60);
                  return;
               }
            }
      // MODERATE AND UP
         // Bronze Armor
            rule researchBronzeArmor
            inactive
            minInterval 640
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
            minInterval 720
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
         // Heavy Slingers (MODERATE ONLY)
            rule researchHeavySlingers
            active
            minInterval 460
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechHeavySlingers) == cTechStatusActive)
               {
                  xsDisableRule("researchHeavySlingers");
                  return;
               }
               else if (kbTechGetStatus(cTechHeavySlingers) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Heavy Slingers research plan.");
                  researchSimpleTech(cTechHeavySlingers, cUnitTypeBarracks, -1, 60);
                  return;
               }
            }
         // Heavy Spearmen (NOT TITAN)
            rule researchHeavySpearmen
            active
            minInterval 460
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechHeavySpearmen) == cTechStatusActive)
               {
                  xsDisableRule("researchHeavySpearmen");
                  return;
               }
               else if (kbTechGetStatus(cTechHeavySpearmen) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Heavy Spearmen research plan.");
                  researchSimpleTech(cTechHeavySpearmen, cUnitTypeBarracks, -1, 60);
                  return;
               }
            }
         // Heavy Axemen (NOT TITAN)
            rule researchHeavyAxemen
            active
            minInterval 460
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechHeavyAxemen) == cTechStatusActive)
               {
                  xsDisableRule("researchHeavyAxemen");
                  return;
               }
               else if (kbTechGetStatus(cTechHeavyAxemen) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Heavy Axemen research plan.");
                  researchSimpleTech(cTechHeavyAxemen, cUnitTypeBarracks, -1, 60);
                  return;
               }
            }
      // HARD AND TITAN
         // Ballistics
            rule researchBallistics
            inactive
            minInterval 750
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
         // Slings of the Sun
            rule researchSlingsOfTheSun
            active
            minInterval 640
            {
               debugAttackWave("Starting Slings Of The Sun research plan.");
               researchSimpleTech(cTechSlingsOfTheSun, cUnitTypeBarracks, -1, 50);
               xsDisableRule("researchSlingsOfTheSun");
            }
         // Force of the West Wind
            rule researchForceOfTheWestWind
            active
            minInterval 1260
            {
               debugAttackWave("Starting Force Of The West Wind research plan.");
               researchSimpleTech(cTechForceOfTheWestWind, cUnitTypeSiegeWorks, -1, 50);
               xsDisableRule("researchForceOfTheWestWind");
            }
         // Heavy War Elephants
            rule researchHeavyWarElephants
            active
            minInterval 960
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

   // ALL DIFFICULTIES
         // Quarry
            rule researchQuarry
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechQuarry) == cTechStatusActive)
               {
                  xsDisableRule("researchQuarry");
                  return;
               }
               else if (kbTechGetStatus(cTechQuarry) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Quarry research plan.");
                  researchSimpleTech(cTechQuarry, cUnitTypeMiningCamp, -1, 60);
                  return;
               }
            }
         // Flood Control
            rule researchFloodControl
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechFloodControl) == cTechStatusActive)
               {
                  xsDisableRule("researchFloodControl");
                  return;
               }
               else if (kbTechGetStatus(cTechFloodControl) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Flood Control research plan.");
                  researchSimpleTech(cTechFloodControl, cUnitTypeGranary, -1, 60);
                  return;
               }
            }
         // Flood Control
            rule researchCarpenters
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
            {
               researchSimpleTech(cTechCarpenters, cUnitTypeLumberCamp, -1, 60);
               xsDisableRule("researchCarpenters"); // Disable self.
            }

   // MODERATE AND UP
         // Champion Spearmen
         rule researchChampionSpearmen
         active
         minInterval 180
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechChampionSpearmen) == cTechStatusActive)
            {
               xsDisableRule("researchChampionSpearmen");
               return;
            }
            else if (kbTechGetStatus(cTechChampionSpearmen) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Champion Spearmen research plan.");
               researchSimpleTech(cTechChampionSpearmen, cUnitTypeBarracks, -1, 60);
               return;
            }
         }

         // Champion Axemen
         rule researchChampionAxemen
         active
         minInterval 300
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechChampionAxemen) == cTechStatusActive)
            {
               xsDisableRule("researchChampionAxemen");
               return;
            }
            else if (kbTechGetStatus(cTechChampionAxemen) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Champion Axemen research plan.");
               researchSimpleTech(cTechChampionAxemen, cUnitTypeBarracks, -1, 60);
               return;
            }
         }

         // Champion Slingers
         rule researchChampionSlingers
         active
         minInterval 300
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechChampionSlingers) == cTechStatusActive)
            {
               xsDisableRule("researchChampionSlingers");
               return;
            }
            else if (kbTechGetStatus(cTechChampionSlingers) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Champion Slingers research plan.");
               researchSimpleTech(cTechChampionSlingers, cUnitTypeBarracks, -1, 60);
               return;
            }
         }

   // HARD AND UP
            // Iron Weapons
            rule researchIronWeapons
            inactive
            minInterval 360
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
            // Iron Armor
            rule researchIronArmor
            inactive
            minInterval 560
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

   // TITAN ONLY
            // Iron Shields
            rule researchIronShields
            inactive
            minInterval 190
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

            // Champion War Elephants
            rule researchChampionWarElephants
            inactive
            minInterval 720
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionWarElephants) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionWarElephants");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionWarElephants) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion War Elephants research plan.");
                  researchSimpleTech(cTechChampionWarElephants, cUnitTypeMigdolStronghold, -1, 60);
                  return;
               }
            }

            // Engineers
            rule researchEngineers
            inactive
            minInterval 900
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
                  researchSimpleTech(cTechEngineers, cUnitTypeSiegeWorks, -1, 60);
                  return;
               }
            }