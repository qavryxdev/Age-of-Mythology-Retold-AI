//==============================================================================
/* tgg04_p2.xs
   
   Red Norse player owning a base in the western half of the map, with walls sprawling to the north.
   They train an army composed primarly of Hersirs, Raiding Cavalry and Heroic & Mythic Myth Units.

    They invoke Walking Woods at some point during one of their attacks, and summons Nidhogg as soon
    as they reach Mythic Age.

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
float gMaintainFirstLandUnitAmount = 6;
int gSecondLandUnit = cUnitTypeHersir; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 5;
int gThirdLandUnit = cUnitTypeMountainGiant; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 1;
int gFourthLandUnit = cUnitTypeFrostGiant; // Gets trained starting in Mythic.
float gMaintainFourthLandUnitAmount = 1;
int gFifthLandUnit = cUnitTypeFireGiant; // Gets trained starting in Mythic. Doesn't get trained on Easy difficulty.
float gMaintainFifthLandUnitAmount = 1;
int gSixthLandUnit = cUnitTypeBallista; // Gets trained starting in Mythic.
float gMaintainSixthLandUnitAmount = 1;
int gSeventhLandUnit = cUnitTypeThrowingAxeman; // Gets trained on Hard and Titan after a difficulty-based delay.
float gMaintainSeventhLandUnitAmount = 5;
int gEighthLandUnit = cUnitTypeHuskarl; // Gets trained on Hard and Titan after a difficulty-based delay.
float gMaintainEighthLandUnitAmount = 5;

// The delay before adding the 7th & 8th land units into the attack plan (Throwing Axemen and Huskarls).
float gAddExtraUnitsDelay = 900; // In seconds. Hard only. Delay is halved on Titan.

int gSpecialLandUnit = cUnitTypeNidhogg;    // Summoned by a God Power.

float gMaxVillagerCount = 12;
float gAttackStartDelay = 180; // In seconds.
float gAttackWaveInterval = 420; // In seconds.
float gAttackStartSize = 4;
float gAttackMaxSize = 16; // Affected by the Attack Size Multiplier a second time once we start training Throwing Axemen and Huskarls.

float gMythicAgeUpTime = 1200; // In seconds.

vector gOurTCLocation = vector(50.0, 0.0, 352.0);

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;

Strategy scenarioAttackWaveStrategy()
{

    xsEnableRule("useWalkingWoods");

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
      gMaintainEighthLandUnitAmount *= gDifficultyModifierMaintainUnit;

      if (cDifficultyCurrent >= cDifficultyTitan)
      {
         gAddExtraUnitsDelay /= 2;
      }

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;
      gMythicAgeUpTime *= gDifficultyModifierAgeUp;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Raiding Cavalry
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Hersirs
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Mountain Giants

      // Frost Giants, Fire Giants and Ballistae are not trained until reaching Mythic.
   
      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);      // Raiding Cavalry
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);     // Hersirs
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);      // Mountain Giants

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

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticOxCartTraining, true);
      data.setFlag(cStrategyFlagAutoResearchEconomyUpgrades, true);

      gAttackWave.setPlayerToAttack(1); // Attack P1!

      // Where does our attack start and end.
      vector startPoint = vector(109.0, 0.0, 279.0); // Middle of their base.
      vector targetPoint = vector(331.0, 0.0, 42.0); // Dwarves' TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 to Town Center");  // Via the rightmost gate, keeping close to the center lake before attacking TC directly from the west.
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(153.0, 0.0, 148.0));
      kbPathAddWaypoint(pathID1, vector(239.0, 0.0, 148.0));
      kbPathAddWaypoint(pathID1, vector(257.0, 0.0, 98.0));
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path 2 to Town Center");  // Via the rightmost gate, going around the underside of the round cliff before attacking TC directly from the west.
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(153.0, 0.0, 148.0));
      kbPathAddWaypoint(pathID2, vector(191.0, 0.0, 75.0));
      kbPathAddWaypoint(pathID2, vector(331.0, 0.0, 42.0));
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      int pathID3 = kbPathCreate("Path 3 to Town Center");  // Via the leftmost gate, sweeping the area below the eastern lake before attacking TC directly from the south.
      kbPathAddWaypoint(pathID3, startPoint);
      kbPathAddWaypoint(pathID3, vector(90.0, 0.0, 160.0));
      kbPathAddWaypoint(pathID3, vector(191.0, 0.0, 75.0));
      kbPathAddWaypoint(pathID3, vector(245.0, 0.0, 15.0));
      kbPathAddWaypoint(pathID3, targetPoint);
      kbAttackRouteAddPath(routeID, pathID3);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      /* int landDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 30.0, startPoint, 10);
      aiPlanSetVariableFloat(landDefendPlan, cDefendPlanEngageRange, 0, 50.0);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200); */

   // DEFINE THE PLANS
      // Plan 1 (Grassy terrace)
      gDefendPlan1 = createDefendPlan("Defense Plan 1", kbBaseGetMainID(cMyID), 10, vector(75.0, 0.0, 257.0), 30);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 25);

      aiPlanAddUnitType(gDefendPlan1, gFirstLandUnit, 0, 0, 200); // Raiding Cavalry
      aiPlanAddUnitType(gDefendPlan1, gSecondLandUnit, 0, 0, 200); // Hersirs
      aiPlanAddUnitType(gDefendPlan1, gThirdLandUnit, 0, 0, 200); // Mountain Giants
      aiPlanAddUnitType(gDefendPlan1, gFourthLandUnit, 0, 0, 200); // Frost Giants
      aiPlanAddUnitType(gDefendPlan1, gFifthLandUnit, 0, 0, 200); // Fire Giants

      // Plan 2 (Near the west corner)
      gDefendPlan2 = createDefendPlan("Defense Plan 2", kbBaseGetMainID(cMyID), 10, vector(75.0, 0.0, 317.0), 30);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan2, gSeventhLandUnit, 0, 0, 200); // Throwing Axemen
      aiPlanAddUnitType(gDefendPlan2, gSixthLandUnit, 0, 0, 200); // Ballistae
      aiPlanAddUnitType(gDefendPlan2, gEighthLandUnit, 0, 0, 200); // Huskarls


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
         if (age == cAge3 && time >= gMythicAgeUpTime)
         {
            researchSimpleTech(cTechMythicAgeHel, cUnitTypeTownCenter, -1, 75);
         }
         if (age == cAge4 && reachedAge4 == false)
         {
            data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Start training Frost Giants.
            data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount); // Start training Ballistae.
            data.setTrainDelay(gFourthLandUnit, gTrainDelay); // Frost Giants
            data.setTrainDelay(gSixthLandUnit, gTrainDelay); // Ballistae
            gAttackWave.addAttackUnitType(gFourthLandUnit); // Start dispatching Frost Giants.
            gAttackWave.addAttackUnitType(gSixthLandUnit); // Start dispatching Ballistae.

            if (cDifficultyCurrent >= cDifficultyModerate)
            {
               data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount); // Start training Fire Giants.
               data.setTrainDelay(gFifthLandUnit, gTrainDelay); // Fire Giants
               gAttackWave.addAttackUnitType(gFifthLandUnit); // Start dispatching Fire Giants.
            }

            reachedAge4 = true;
            done = true;
         }
      }

      // Add Throwing Axemen and Huskarls on Hard/Titan.
      // Increase max attack size accordingly.
      static bool addExtraUnits = false;
      if (addExtraUnits == false && time >= gAddExtraUnitsDelay && cDifficultyCurrent >= cDifficultyHard)
      {
         data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount); // Start training Throwing Axemen.
         data.addUnitToMaintain(gEighthLandUnit, gMaintainEighthLandUnitAmount); // Start training Huskarls.
         data.setTrainDelay(gSeventhLandUnit, gTrainDelay); // Throwing Axemen
         data.setTrainDelay(gEighthLandUnit, gTrainDelay); // Huskarls
         gAttackWave.addAttackUnitType(gSeventhLandUnit); // Start dispatching Throwing Axemen.
         gAttackWave.addAttackUnitType(gEighthLandUnit); // Start dispatching Huskarls.

         gAttackMaxSize *= gDifficultyModifierAttackSizeMultiplier;
         gAttackWave.setMaxAttackSize(gAttackMaxSize);

         debugAttackWave("Training more land units and increasing maximum attack size.");
         debugAttackWave("Our new attack size maximum is:" + gAttackMaxSize + "! I repeat: our new attack size maximum is: " + gAttackMaxSize + "!");

         addExtraUnits = true;
      }

      // New Tech Rules
      static bool heroic_techs = false;
      if (age >= cAge3 && heroic_techs == false)
      {
         // All Difficulties:
         xsEnableRule("researchHeavyCavalry");
         xsEnableRule("researchBronzeWeapons");
         xsEnableRule("researchBronzeArmor");
         xsEnableRule("researchBronzeShields");
         xsEnableRule("researchBoilingOil");

         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchFortifiedTownCenter");
            xsEnableRule("researchBallistics");
            xsEnableRule("researchHeavyInfantry");
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchArchitects");
         }

         // Titan Only:
         heroic_techs = true;

      }
      static bool mythic_techs = false;
      if (age >= cAge4 && mythic_techs == false)
      {
         // All Difficulties:
         xsEnableRule("researchChampionCavalry");

         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchBurningPitch");
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchGraniteBlood");
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchChampionInfantry");
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchRampage");
            xsEnableRule("researchIronArmor");
            xsEnableRule("researchIronShields");
            xsEnableRule("researchEngineers");
         }
         mythic_techs = true;
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}


// Set up the strategy.
void tgg04StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(107.00, 0.00, 225.00), 30);
   createOverrideGatherBase(vector(113.00, 0.00, 303.00), 64);
   createOverrideGatherBase(vector(35.00, 0.00, 350.00), 94);

   setOverrideStrategy(tgg04StrategySetup);

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
   gRBDSystem.setMaxFarmsPerBase(32);
   gRBDSystem.setMaxFarmsPerIteration(32);
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

rule useWalkingWoods
inactive
minInterval 5
{
   // Don't attempt to invoke before 20 minutes have elapsed.
   if (xsGetTime() < 1200)
   {
       return;
   }

   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   int unitID = -1;
   int numEnemies = -1;
   int numTrees = -1;
   int treeID = -1;
   for (int i = 0; i < attackPlans.size(); i++)
   {
      if (aiPlanGetParentID(attackPlans[i]) == -1)
      {
         // We just take the first unit to scan from.
         unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
         if (unitID >= 0)
         {
           // Look for enemies.
            numEnemies = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 15.0);
            debugAttackWave("numEnemies for casting Walking Woods offensively: " + numEnemies);
            if (numEnemies >= 4)
            {
               // Look for nearby trees.
               numTrees = getUnitCountByLocation(cUnitTypeTree, 0, cUnitStateAlive, kbUnitGetPosition(unitID), 15.0);
               debugAttackWave("numTrees nearby: " + numTrees);
               if (numTrees >= 4)
               {
                   // Grab a nearby tree.
                   treeID = getUnitByLocation(cUnitTypeTree, 0, cUnitStateAlive, kbUnitGetPosition(unitID), 15.0);
                   if (treeID >= 0)
                   {
                       // Invoke god power!
                       if (aiCastGodPowerAtPosition(cProtoPowerWalkingWoods, kbUnitGetPosition(treeID)) == true)
                       {
                           debugAttackWave("Casted Walking Woods!");
                           xsDisableRule("useWalkingWoods");
                           return;
                       }
                   }
               }
            }
         }
      }
   }
}

rule useNidhogg
inactive
minInterval 5
{
   vector targetPoint = vector(239.0, 0.0, 285.0);
   // Invoke god power!
   if (aiCastGodPowerAtPosition(cProtoPowerNidhogg, targetPoint) == true)
   {
      debugAttackWave("Casted Nidhogg!");
      xsDisableRule("useNidhogg");
      return;
   }
}

// Move defend plans (when nearby buildings are destroyed)
   void updateDefendPlan1()
   {
      // Nearby buildings are destroyed. We will move our defend plan further inward.
      aiPlanSetVariableVector(gDefendPlan1, cDefendPlanTargetPoint, 0, vector(211.0, 0.0, 309.0));
      aiPlanSetVariableVector(gDefendPlan1, cDefendPlanGatherPoint, 0, vector(211.0, 0.0, 309.0));
      aiEcho("Contracted our defense plan.");
   }
   void updateDefendPlan2()
   {
      // Nearby buildings are destroyed. We will move our defend plan further inward.
      aiPlanSetVariableVector(gDefendPlan2, cDefendPlanTargetPoint, 0, vector(207.0, 0.0, 361.0));
      aiPlanSetVariableVector(gDefendPlan2, cDefendPlanGatherPoint, 0, vector(207.0, 0.0, 361.0));
      aiEcho("Contracted our defense plan.");
   }

// Move Gather plan (when the southeast TC is destroyed)
   void updateGatherPlan()
   {
      kbBaseDestroy(cMyID, gMainGatherBase);
      gMainGatherBase = createOverrideGatherBase(vector(113.00, 0.00, 303.00), 64);
      createOverrideGatherBase(vector(35.00, 0.00, 350.00), 94);
   }

   // TECH RULES //

// *** HEROIC AGE TECHS *** //
   // ALL DIFFICULTIES:
      // Bronze Weapons
         rule researchBronzeWeapons
         inactive
         minInterval 30
         {
            xsSetRuleMinInterval("researchBronzeWeapons", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechBronzeWeapons) == cTechStatusActive)
            {
               xsDisableRule("researchBronzeWeapons");
               return;
            }
            else if (kbTechGetStatus(cTechBronzeWeapons) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Bronze Weapons research plan.");
               researchSimpleTech(cTechBronzeWeapons, cUnitTypeArmory, -1, 50);
               return;
            }
         }
      // Bronze Armor
         rule researchBronzeArmor
         inactive
         minInterval 30
         {
            xsSetRuleMinInterval("researchBronzeArmor", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechBronzeArmor) == cTechStatusActive)
            {
               xsDisableRule("researchBronzeArmor");
               return;
            }
            else if (kbTechGetStatus(cTechBronzeArmor) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Bronze Armor research plan.");
               researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 50);
               return;
            }
         }
      // Bronze Shields
         rule researchBronzeShields
         inactive
         minInterval 30
         {
            xsSetRuleMinInterval("researchBronzeShields", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechBronzeShields) == cTechStatusActive)
            {
               xsDisableRule("researchBronzeShields");
               return;
            }
            else if (kbTechGetStatus(cTechBronzeShields) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Bronze Shields research plan.");
               researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 50);
               return;
            }
         }
         // Boiling Oil
         rule researchBoilingOil
         inactive
         minInterval 30
         {
            xsSetRuleMinInterval("researchBoilingOil", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechBoilingOil) == cTechStatusActive)
            {
               xsDisableRule("researchBoilingOil");
               return;
            }
            else if (kbTechGetStatus(cTechBoilingOil) == cTechStatusObtainable)
            {
               debugAttackWave("Starting BoilingOil research plan.");
               researchSimpleTech(cTechBoilingOil, cUnitTypeSentryTower, -1, 50);
               return;
            }
         }

   
   // MODERATE AND UP:
         // Fortified Town Center
         rule researchFortifiedTownCenter
         inactive
         minInterval 720
         {
            xsSetRuleMinInterval("researchFortifiedTownCenter", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechFortifiedTownCenter) == cTechStatusActive)
            {
               xsDisableRule("researchFortifiedTownCenter");
               return;
            }
            else if (kbTechGetStatus(cTechFortifiedTownCenter) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Fortified Town Center research plan.");
               researchSimpleTech(cTechFortifiedTownCenter, cUnitTypeTownCenter, -1, 50);
               return;
            }
         }
      // Ballistics
         rule researchBallistics
         inactive
         minInterval 550
         {
            xsSetRuleMinInterval("researchBallistics", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechBallistics) == cTechStatusActive)
            {
               xsDisableRule("researchBallistics");
               return;
            }
            else if (kbTechGetStatus(cTechBallistics) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Ballistics research plan.");
               researchSimpleTech(cTechBallistics, cUnitTypeArmory, -1, 50);
               return;
            }
         }
   // HARD AND TITAN:
      // Heavy Cavalry
         rule researchHeavyCavalry
         active
         minInterval 240
         {
            xsSetRuleMinInterval("researchHeavyCavalry", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechHeavyCavalry) == cTechStatusActive)
            {
               xsDisableRule("researchHeavyCavalry");
               return;
            }
            else if (kbTechGetStatus(cTechHeavyCavalry) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Heavy Cavalry research plan.");
               researchSimpleTech(cTechHeavyCavalry, cUnitTypeGreatHall, -1, 50);
               return;
            }
         }

      // Heavy Infantry
         rule researchHeavyInfantry
         active
         minInterval 360
         {
            xsSetRuleMinInterval("researchHeavyInfantry", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechHeavyInfantry) == cTechStatusActive)
            {
               xsDisableRule("researchHeavyInfantry");
               return;
            }
            else if (kbTechGetStatus(cTechHeavyInfantry) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Heavy Infantry research plan.");
               researchSimpleTech(cTechHeavyInfantry, cUnitTypeLonghouse, -1, 50);
               return;
            }
         }
      // Architects
         rule researchArchitects
         inactive
         minInterval 880
         {
            xsSetRuleMinInterval("researchArchitects", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechArchitects) == cTechStatusActive)
            {
               xsDisableRule("researchArchitects");
               return;
            }
            else if (kbTechGetStatus(cTechArchitects) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Architects research plan.");
               researchSimpleTech(cTechArchitects, cUnitTypeTownCenter, -1, 50);
               return;
            }
         }

// *** MYTHIC AGE TECHS *** //
   // ALL DIFFICULTIES
      // Champion Cavalry
         rule researchChampionCavalry
         inactive
         minInterval 30
         {
            xsSetRuleMinInterval("researchChampionCavalry", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechChampionCavalry) == cTechStatusActive)
            {
               xsDisableRule("researchChampionCavalry");
               return;
            }
            else if (kbTechGetStatus(cTechChampionCavalry) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Champion Cavalry research plan.");
               researchSimpleTech(cTechChampionCavalry, cUnitTypeGreatHall, -1, 50);
               return;
            }
         }

   // MODERATE AND UP
      // Burning Pitch
         rule researchBurningPitch
         inactive
         minInterval 300
         {
            xsSetRuleMinInterval("research___", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechBurningPitch) == cTechStatusActive)
            {
               xsDisableRule("researchBurningPitch");
               return;
            }
            else if (kbTechGetStatus(cTechBurningPitch) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Burning Pitch research plan.");
               researchSimpleTech(cTechBurningPitch, cUnitTypeArmory, -1, 50);
               return;
            }
         }

   // HARD AND TITAN
      // Granite Blood
         rule researchGraniteBlood
         inactive
         minInterval 15
         {
            xsSetRuleMinInterval("researchGraniteBlood", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechGraniteBlood) == cTechStatusActive)
            {
               xsDisableRule("researchGraniteBlood");
               return;
            }
            else if (kbTechGetStatus(cTechGraniteBlood) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Granite Blood research plan.");
               researchSimpleTech(cTechGraniteBlood, cUnitTypeTemple, -1, 50);
               return;
            }
         }
      // Iron Weapons
         rule researchIronWeapons
         inactive
         minInterval 15
         {
            xsSetRuleMinInterval("researchIronWeapons", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechIronWeapons) == cTechStatusActive)
            {
               xsDisableRule("researchIronWeapons");
               return;
            }
            else if (kbTechGetStatus(cTechIronWeapons) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Iron Weapons research plan.");
               researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 50);
               return;
            }
         }
      // Champion Infantry
         rule researchChampionInfantry
         active
         minInterval 15
         {
            xsSetRuleMinInterval("researchChampionInfantry", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusActive)
            {
               xsDisableRule("researchChampionInfantry");
               return;
            }
            else if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Champion Infantry research plan.");
               researchSimpleTech(cTechChampionInfantry, cUnitTypeLonghouse, -1, 50);
               return;
            }
         }

   // TITAN ONLY
      // Rampage
         rule researchRampage
         inactive
         minInterval 15
         {
            xsSetRuleMinInterval("researchRampage", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechRampage) == cTechStatusActive)
            {
               xsDisableRule("researchRampage");
               return;
            }
            else if (kbTechGetStatus(cTechRampage) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Rampage research plan.");
               researchSimpleTech(cTechRampage, cUnitTypeTemple, -1, 50);
               return;
            }
         }
      // Iron Armor
         rule researchIronArmor
         inactive
         minInterval 15
         {
            xsSetRuleMinInterval("researchIronArmor", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechIronArmor) == cTechStatusActive)
            {
               xsDisableRule("researchIronArmor");
               return;
            }
            else if (kbTechGetStatus(cTechIronArmor) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Iron Armor research plan.");
               researchSimpleTech(cTechIronArmor, cUnitTypeArmory, -1, 50);
               return;
            }
         }
      // Engineers
         rule researchEngineers
         active
         minInterval 15
         {
            xsSetRuleMinInterval("researchEngineers", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechEngineers) == cTechStatusActive)
            {
               xsDisableRule("researchEngineers");
               return;
            }
            else if (kbTechGetStatus(cTechEngineers) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Engineers research plan.");
               researchSimpleTech(cTechEngineers, cUnitTypeHillFort, -1, 50);
               return;
            }
         }
      // Iron Shields
         rule researchIronShields
         inactive
         minInterval 150
         {
            xsSetRuleMinInterval("researchIronShields", 10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechIronShields) == cTechStatusActive)
            {
               xsDisableRule("researchIronShields");
               return;
            }
            else if (kbTechGetStatus(cTechIronShields) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Iron Shields research plan.");
               researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 50);
               return;
            }
         }