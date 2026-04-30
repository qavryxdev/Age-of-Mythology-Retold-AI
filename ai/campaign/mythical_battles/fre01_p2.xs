//==============================================================================
/* fre01_p2.xs

   Gargarensis (Loki)
   Owns a base in the north. Starts in Classical and advances all the way up to Mythic.
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

float gTrainDelay = 15; // In seconds.
int gFirstLandUnit = cUnitTypeHirdman; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 6;
int gSecondLandUnit = cUnitTypeRaidingCavalry; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 5;
int gThirdLandUnit = cUnitTypeHersir; // Gets trained after a delay.
float gMaintainThirdLandUnitAmount = 3;
int gFourthLandUnit = cUnitTypeThrowingAxeman; // Gets trained after a delay.
float gMaintainFourthLandUnitAmount = 5;
int gFifthLandUnit = cUnitTypeTroll; // Gets trained after a delay.
float gMaintainFifthLandUnitAmount = 1;
int gSixthLandUnit = cUnitTypePortableRam; // Gets trained when reaching the Heroic Age.
float gMaintainSixthLandUnitAmount = 2;
int gSeventhLandUnit = cUnitTypeMountainGiant; // Gets trained when reaching the Heroic Age.
float gMaintainSeventhLandUnitAmount = 1; // Not affected by multiplier.
int gEighthLandUnit = cUnitTypeRockGiant; // Gets trained when reaching the Mythic Age.
float gMaintainEighthLandUnitAmount = 1; // Not affected by multiplier.
int gNinthLandUnit = cUnitTypeFrostGiant; // Gets trained when reaching the Mythic Age.
float gMaintainNinthLandUnitAmount = 1; // Not affected by multiplier.
int gTenthLandUnit = cUnitTypeFireGiant; // Gets trained when reaching the Mythic Age.
float gMaintainTenthLandUnitAmount = 1; // Not affected by multiplier.

float gMaxVillagerCount = 20;
float gMaxFishingShipCount = 0;

float gAttackStartDelay = 480; // In seconds.
float gAttackWaveInterval = 600; // In seconds.
float gAttackStartSize = 5;
float gAttackMaxSize = 20;

float gSecondAttackStartDelay = 120; // In seconds.
float gSecondAttackWaveInterval = 180; // In seconds.
float gSecondAttackStartSize = 3;
float gSecondAttackMaxSize = 6;

float gMoreClassicalUnitsDelay = 180; // In seconds.
float gInitialFarmDelay = 300; // In seconds.

float gHeroicAgeUpTime = 960; // In seconds.
float gMythicAgeUpTime = 2280; // In seconds.
float gNidoggTime = 3000; // In seconds. Affected by the age up multiplier.

vector gOurTCLocation = vector(269.0, 0.0, 269.0);

Strategy scenarioAttackWaveStrategy()
{
   xsEnableRule("invokeHealingSpring");

   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugAttackWave("***Starting Scenario Attack Wave Strategy***");

      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================
      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      //gMaintainSeventhLandUnitAmount *= gDifficultyModifierMaintainUnit;
      //gMaintainEighthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      //gMaintainNinthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      //gMaintainTenthLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gTrainDelay *= gDifficultyModifierTrainDelay;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      gSecondAttackStartDelay *= gDifficultyModifierFirstAttack;
      gSecondAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gSecondAttackStartSize *= gDifficultyModifierAttackSizes;
      gSecondAttackMaxSize *= gDifficultyModifierAttackSizes;

      gHeroicAgeUpTime *= gDifficultyModifierAgeUp;
      gMythicAgeUpTime *= gDifficultyModifierAgeUp;
      gNidoggTime *= gDifficultyModifierAgeUp;

      // Since there's an intro cinematic, and we're booting up a while into the scenario, update the various non-attack delays we have.
      gMoreClassicalUnitsDelay = gMoreClassicalUnitsDelay + xsGetTime();
      gHeroicAgeUpTime = gHeroicAgeUpTime + xsGetTime();
      gMythicAgeUpTime = gMythicAgeUpTime + xsGetTime();

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.setMinAttackSize(gAttackStartSize);
      gAttackWave.addAttackUnitType(gFirstLandUnit);  // Hirdmen
      gAttackWave.addAttackUnitType(gSecondLandUnit); // Raiding Cavalry
      debugAttackWave("Main Attacks:");
      gAttackWave.displayFirstAttackStats();

      gSecondAttackWave.setName("gSecondAttackWave");
      gSecondAttackWave.setAttackStartTime(gSecondAttackStartDelay);
      gSecondAttackWave.setAttackInterval(gSecondAttackWaveInterval);
      gSecondAttackWave.setAttackSize(gSecondAttackStartSize);
      gSecondAttackWave.setMaxAttackSize(gSecondAttackMaxSize);
      gSecondAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gSecondAttackWave.setMinAttackSize(gSecondAttackStartSize);
      gSecondAttackWave.addAttackUnitType(gFirstLandUnit);  // Hirdmen
      gSecondAttackWave.addAttackUnitType(gSecondLandUnit); // Raiding Cavalry
      debugAttackWave("Small, Frequent Attacks:");
      gSecondAttackWave.displayFirstAttackStats();

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticOxCartTraining, true);
      data.setFlag(cStrategyFlagAutoBuildMilitaryBuildings, false);
      data.setFlag(cStrategyFlagAutoResearchEconomyUpgrades, true);
      data.setFlag(cStrategyFlagAutoResearchMilitaryUpgrades, true);
      data.setFlag(cStrategyFlagBuildArmory, false);
      data.setFlag(cStrategyFlagBuildTemple, false);
      data.setFlag(cStrategyFlagBuildHouses, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!
      gSecondAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start.
      vector startPoint = vector(247.0, 0.0, 258.0); // In our base.
      vector endPoint = vector(46.0, 0.0, 27.0); // In the enemy base.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, endPoint);

      // Path 1 - going west and along the shoreline.
      int pathID1 = kbPathCreate("Path 1");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(206.0, 0.0, 242.0));
      kbPathAddWaypoint(pathID1, vector(196.0, 0.0, 183.0));
      kbPathAddWaypoint(pathID1, vector(99.0, 0.0, 191.0));
      kbPathAddWaypoint(pathID1, vector(79.0, 0.0, 137.0));
      kbPathAddWaypoint(pathID1, vector(54.0, 0.0, 90.0));
      kbPathAddWaypoint(pathID1, vector(206.0, 0.0, 242.0));
      kbPathAddWaypoint(pathID1, endPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      // Path 2 - going straight down the middle.
      int pathID2 = kbPathCreate("Path 2");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(206.0, 0.0, 242.0));
      kbPathAddWaypoint(pathID2, vector(196.0, 0.0, 183.0));
      kbPathAddWaypoint(pathID2, vector(183.0, 0.0, 155.0));
      kbPathAddWaypoint(pathID2, vector(145.0, 0.0, 158.0));
      kbPathAddWaypoint(pathID2, vector(113.0, 0.0, 105.0));
      kbPathAddWaypoint(pathID2, vector(89.0, 0.0, 60.0));
      kbPathAddWaypoint(pathID2, endPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      // Path 3 - going east at first, but cutting through the woods to the middle.
      int pathID3 = kbPathCreate("Path 3");
      kbPathAddWaypoint(pathID3, startPoint);
      kbPathAddWaypoint(pathID3, vector(206.0, 0.0, 242.0));
      kbPathAddWaypoint(pathID3, vector(196.0, 0.0, 183.0));
      kbPathAddWaypoint(pathID3, vector(183.0, 0.0, 155.0));
      kbPathAddWaypoint(pathID3, vector(190.0, 0.0, 106.0));
      kbPathAddWaypoint(pathID3, vector(162.0, 0.0, 79.0));
      kbPathAddWaypoint(pathID3, vector(117.0, 0.0, 107.0));
      kbPathAddWaypoint(pathID3, vector(88.0, 0.0, 58.0));
      kbPathAddWaypoint(pathID3, endPoint);
      kbAttackRouteAddPath(routeID, pathID3);

      // Path 4 - going east past the cave and the settlement
      int pathID4 = kbPathCreate("Path 4");
      kbPathAddWaypoint(pathID4, startPoint);
      kbPathAddWaypoint(pathID4, vector(206.0, 0.0, 242.0));
      kbPathAddWaypoint(pathID4, vector(196.0, 0.0, 183.0));
      kbPathAddWaypoint(pathID4, vector(183.0, 0.0, 155.0));
      kbPathAddWaypoint(pathID4, vector(190.0, 0.0, 106.0));
      kbPathAddWaypoint(pathID4, vector(159.0, 0.0, 48.0));
      kbPathAddWaypoint(pathID4, vector(106.0, 0.0, 41.0));
      kbPathAddWaypoint(pathID4, endPoint);
      kbAttackRouteAddPath(routeID, pathID4);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(endPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      gSecondAttackWave.setGatherPoint(startPoint);
      gSecondAttackWave.setTargetPoint(endPoint);
      gSecondAttackWave.setAttackRouteID(routeID);
      gSecondAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      int landDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 20.0, startPoint);
      aiPlanAddUnitType(landDefendPlan, gFirstLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gSecondLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gThirdLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gFourthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gFifthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gSixthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gSeventhLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gEighthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gNinthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gTenthLandUnit, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      int age = kbPlayerGetAge(cMyID);
      static bool moreClassicalUnits = false;
      static bool goingHeroic = false;
      static bool isHeroic = false;
      static bool goingMythic = false;
      static bool isMythic = false;

      if (gTimeToFarm == false && xsGetTime() >= gInitialFarmDelay)
      {
         gTimeToFarm = true; // Start farming early.
      }

      if (moreClassicalUnits == false && xsGetTime() >= gMoreClassicalUnitsDelay)
      {
         moreClassicalUnits = true;
         debugAttackWave("We're adding more Classical Age units to our army composition!");
         data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
         data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
         data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
         data.setTrainDelay(gThirdLandUnit, gTrainDelay);
         data.setTrainDelay(gFourthLandUnit, gTrainDelay);
         data.setTrainDelay(gFifthLandUnit, gTrainDelay);
         gAttackWave.addAttackUnitType(gThirdLandUnit);  // Hersirs
         gAttackWave.addAttackUnitType(gFourthLandUnit);  // Throwing Axemen
         gAttackWave.addAttackUnitType(gFifthLandUnit);  // Trolls
      }

      if (goingHeroic == false && xsGetTime() >= gHeroicAgeUpTime)
      {
         goingHeroic = true;
         researchSimpleTech(cTechHeroicAgeNjord, cUnitTypeTownCenter, -1, 70);
      }

      if (isHeroic == false && age >= cAge3)
      {
         isHeroic = true;
         data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
         data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);
         data.setTrainDelay(gSixthLandUnit, gTrainDelay);
         data.setTrainDelay(gSeventhLandUnit, gTrainDelay);
         gAttackWave.addAttackUnitType(gSixthLandUnit);  // Portable Rams
         gAttackWave.addAttackUnitType(gSeventhLandUnit);  // Mountain Giants
         xsEnableRule("buildHillFort");
         xsEnableRule("buildHillFort2");
         xsEnableRule("buildHillFort3");
         xsEnableRule("buildTownCenter");
         xsEnableRule("invokeWalkingWoods");
         // TODO Activating the rule to invoke Walking Woods on the player.
      }

      if (goingMythic == false && xsGetTime() >= gMythicAgeUpTime)
      {
         goingMythic = true;
         researchSimpleTech(cTechMythicAgeHel, cUnitTypeTownCenter, -1, 70);
      }

      if (isMythic == false && age >= cAge4)
      {
         isMythic = true;
         data.addUnitToMaintain(gEighthLandUnit, gMaintainEighthLandUnitAmount);
         data.addUnitToMaintain(gNinthLandUnit, gMaintainNinthLandUnitAmount);
         data.addUnitToMaintain(gTenthLandUnit, gMaintainTenthLandUnitAmount);
         data.setTrainDelay(gEighthLandUnit, gTrainDelay);
         data.setTrainDelay(gNinthLandUnit, gTrainDelay);
         data.setTrainDelay(gTenthLandUnit, gTrainDelay);
         gAttackWave.addAttackUnitType(gEighthLandUnit);  // Rock Giants
         gAttackWave.addAttackUnitType(gNinthLandUnit);  // Frost Giants
         gAttackWave.addAttackUnitType(gTenthLandUnit);  // Fire Giants
         gAttackWave.addAttackUnitType(cUnitTypeNidhogg); // Nidhogg
         xsEnableRule("buildWonder");
      }

      static bool nidhogg_time = false;
      if(age == cAge4 && xsGetTime() >= gNidoggTime)
      {
         xsEnableRule("summonNidhogg");
         nidhogg_time = true;
      }

      gAttackWave.update();
      gSecondAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fre01StrategySetup()
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
   // Max out available military slots, we control this number via maintain plans anyway.
   gOverrideMaxMilitaryPop = 200;
   gMaxVillagerCount *= gDifficultyModifierMaintainVillager;
   //gMaxFishingShipCount *= gDifficultyModifierMaintainFishing;

   gOverrideMaxVillagerPop = gMaxVillagerCount;
   gOverrideMaxFishingShipPop = gMaxFishingShipCount;

   gMainGatherBase = createOverrideGatherBase(vector(269.00, 0.00, 268.00), 60); // Covering most of our large base.

   setOverrideStrategy(fre01StrategySetup);

   // We can't have too many farms due to space restrictions.
   gOverrideFarmCount = 10;
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
void postInit() {}

void buildBuilding(int type = cUnitTypeManor, vector location = cInvalidVector)
{
   int builder = cUnitTypeAbstractInfantry;
   int buildPlanID = aiPlanCreate("Build Plan", cPlanBuild, -1);
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID));
   kbBuildingPlacementSetBuildingPUID(bpID, type);
   kbBuildingPlacementSetCenterPosition(bpID, location, 10.0);
   kbBuildingPlacementSetStepSize(bpID, 2.0);
   kbBuildingPlacementSetBufferSpace(bpID, 0.0);
   kbBuildingPlacementAddPositionInfluence(bpID, location, 100.0, 50.0, cFalloffLinear);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, type);
   aiPlanAddUnitType(buildPlanID, builder, 1, 2, 2, false);
   aiPlanSetPriority(buildPlanID, 90);
}

rule buildHillFort
inactive
minInterval 10
{
   int building = cUnitTypeHillFort;
   vector location = vector(238.85, 0.0, 273.74);
   if (kbUnitCount(building, cMyID, cUnitStateABQ) < 1)
   {
      buildBuilding(cUnitTypeHillFort, location);
   }
   xsSetRuleMinInterval("buildHillFort", 60);
}

rule buildTownCenter
inactive
minInterval 10
{
   if (cDifficultyCurrent < cDifficultyModerate)
   {
      xsDisableRule("buildTownCenter");
   }

   int building = cUnitTypeTownCenter;
   vector location = vector(171.00, 4.0, 145.00);
   if (kbUnitCount(building, cMyID, cUnitStateABQ) < 2)
   {
      buildBuilding(cUnitTypeTownCenter, location);
   }
   xsSetRuleMinInterval("buildTownCenter", 60);
}

rule buildHillFort2
inactive
minInterval 600
{
   int building = cUnitTypeHillFort;
   vector location = vector(284.94, 0.0, 217.36);
   if (kbUnitCount(building, cMyID, cUnitStateABQ) < 2)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildHillFort2", 60);
}

rule buildHillFort3
inactive
minInterval 1200
{
   int building = cUnitTypeHillFort;
   vector location = vector(199.0, 0.0, 204.0);
   if (kbUnitCount(building, cMyID, cUnitStateABQ) < 3)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildHillFort3", 60);
}

rule buildWonder
inactive
minInterval 10
{
   if (cDifficultyCurrent < cDifficultyHard)
   {
      xsDisableRule("buildWonder");
   }

   int building = cUnitTypeWonder;
   vector location = vector(303.53, 0.0, 301.73);

   int numEnemies = -1;
   numEnemies = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, 1, cUnitStateAlive, gOurTCLocation, 75.0);
   debugAttackWave("Enemies found in our base: " + numEnemies);
   if (numEnemies < 5)
   {
      if (kbUnitCount(building, cMyID, cUnitStateABQ) < 1)
      {
         debugAttackWave("Our base isn't being threatened as far as we can tell - let's build a Wonder!");
         buildBuilding(building, location);
      }
   }
   
   xsSetRuleMinInterval("buildWonder", 120);
}

rule invokeHealingSpring
inactive 
minInterval 60
{
   vector springBlock = vector(275.01, 0.00, 238.25);
   if(kbLocationVisible(springBlock))
   {
      if (aiCastGodPowerAtPosition(cProtoPowerHealingSpring, springBlock) == true)
      {
         debugAttackWave("Casted Healing Spring!");
      xsDisableRule("invokeHealingSpring");
      }
   }
}

rule invokeWalkingWoods
inactive 
minInterval 5
{
   vector treeBlock = vector(81.0, 0.00, 79.0);
   if(kbLocationVisible(treeBlock))
   {
      if (aiCastGodPowerAtPosition(cProtoPowerWalkingWoods, treeBlock) == true)
      {
         debugAttackWave("Casted Walking Woods!");
      xsDisableRule("invokeWalkingWoods");
      }
   }
}

rule summonNidhogg
inactive 
minInterval 60
{
   vector nidhoggBlock = vector(247.19, 0.00, 258.43);
   if(kbLocationVisible(nidhoggBlock))
   {
      if (aiCastGodPowerAtPosition(cProtoPowerNidhogg, nidhoggBlock) == true)
      {
         debugAttackWave("Summoned Nidhogg!");
      xsDisableRule("summonNidhogg");
      }
   }
}