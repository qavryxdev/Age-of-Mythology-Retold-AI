//==============================================================================
/* tgg08_p5.xs
   
   Sebennytos (Ra)

   Ally to the player that maintains their own economy in the corner of the map, mainly serving as a trading partner.
   They will create Camel Caravans and trade with the player.

   On easier difficulties, they send out some of their units to guard the trade route between their base and the player's base.
   They maintain fewer units on harder difficulties.

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

// Unit maintain amounts and train delays in the section below are REVERSED - the given amounts below are the number of units maintained on TITAN.
float gTrainDelay = 30; // In seconds.

int gFirstLandUnit = cUnitTypeAxeman; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 4;
int gSecondLandUnit = cUnitTypePriest; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 1;
int gThirdLandUnit = cUnitTypeWadjet; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 1;
int gFourthLandUnit = cUnitTypePetsuchos; // Gets trained starting in Heroic.
float gMaintainFourthLandUnitAmount = 1;

float gMaxVillagerCount = 10;  // Not affected by multiplier.
float gMaxCaravanCount = 4;   // Not affected by multiplier.

// The AI has two defend points in the trade route. This is how many units are assigned to each point.
// For each difficulty level above Easy, defender count is reduced by 2 (no defenders on Titan).
float gTradeDefenderCount = 6;

float gHeroicAgeUpTime = 1500; // In seconds. Not affected by multiplier.

vector gOurTCLocation = vector(241.0, 0.0, 25.0);

Strategy scenarioAttackWaveStrategy()
{

   xsEnableRuleGroup("ruleGroupBuildPlans");
   xsEnableRule("createTradeDefendPlans");
   xsEnableRule("researchMediumAxemen");
   xsEnableRule("empowerTownCenter");
   xsEnableRule("setupTradeRoute");

   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugStrategy("***Starting Scenario Attack Wave Strategy***");
      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================
      float reversedMaintainModifier = 2.5;
      float reversedTrainDelayModifier = 0.5;

      if (cDifficultyCurrent == cDifficultyModerate)
      {
         reversedMaintainModifier = 2.0;
         reversedTrainDelayModifier = 0.75;
         gTradeDefenderCount = 4.0;
      }
      else if (cDifficultyCurrent == cDifficultyHard)
      {
         reversedMaintainModifier = 1.5;
         reversedTrainDelayModifier = 1.0;
         gTradeDefenderCount = 2.0;
      }
      else if (cDifficultyCurrent >= cDifficultyTitan)
      {
         reversedMaintainModifier = 1.0;
         reversedTrainDelayModifier = 1.0;
         gTradeDefenderCount = 0.0;
      }

      gMaintainFirstLandUnitAmount *= reversedMaintainModifier;
      gMaintainSecondLandUnitAmount *= reversedMaintainModifier;
      gMaintainThirdLandUnitAmount *= reversedMaintainModifier;
      gMaintainFourthLandUnitAmount *= reversedMaintainModifier;

      gTrainDelay *= reversedTrainDelayModifier;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Axemen
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Priests
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Wadjets

      // Petsuchos are maintained upon reaching Heroic.
   
      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);      // Axemen
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);     // Priests
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);      // Wadjets
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);     // Petsuchos

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticMainBaseTCRebuild, true);

      // Create a general-purpose defend plan to keep existing military occupied and gathered.
      vector defendPoint = vector(230.0, 0.0, 57.0);
      int landDefendPlan = createDefendPlan("Primary Land Defend", -1, 20.0, defendPoint, 10, defendPoint);
      aiPlanSetVariableFloat(landDefendPlan, cDefendPlanEngageRange, 0, 60.0);
      aiPlanAddUnitType(landDefendPlan, gFirstLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gSecondLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gThirdLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gFourthLandUnit, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      int age = kbPlayerGetAge(cMyID);
      int time = xsGetTime();
      if (done == false)
      {
         if (age == cAge2 && time >= gHeroicAgeUpTime)
         {
            researchSimpleTech(cTechHeroicAgeSobek, cUnitTypeTownCenter, -1, 75);
         }
         if (age >= cAge3)
         {
            data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Petsuchos
            data.addUnitToMaintain(cUnitTypeCaravanEgyptian, gMaxCaravanCount); // Camel Caravans
            done = true;
         }
      }

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
   //gMaxVillagerCount *= gDifficultyModifierMaintainVillager;

   gOverrideMaxVillagerPop = gMaxVillagerCount;

   gMainGatherBase = createOverrideGatherBase(vector(253.00, 0.00, 1.00), 78);

   setOverrideStrategy(tna08StrategySetup);

   gOverrideFarmCount = 10; // Don't overdo the Farms.
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

rule createTradeDefendPlans
inactive
minInterval 30
{
   // No defenders on Titan.
   if (cDifficultyCurrent >= cDifficultyTitan)
   {
      xsDisableRule("createTradeDefendPlans");
      return;
   }

   static bool nearDefenseActive = false;
   static bool farDefenseActive = false;

   int unitCount = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive);
   int buffer = 3; // A small buffer to ensure that we still keep some units in our base.

   vector defendPoint = cInvalidVector;

   if (unitCount > gTradeDefenderCount + buffer && nearDefenseActive == false)
   {
      debugAttackWave("*** ACTIVATING NEAR DEFENSE ***");
      // Create a small defense plan by the entrance to the trade route nearest our base.
      defendPoint = vector(235.0, 0.0, 102.0);
      int nearDefendPlan = createDefendPlan("Roaming Defend Plan", -1, 10.0, defendPoint, 10, defendPoint);
      aiPlanSetVariableFloat(nearDefendPlan, cDefendPlanEngageRange, 0, 35.0);
      aiPlanAddUnitType(nearDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, gTradeDefenderCount, gTradeDefenderCount);

      nearDefenseActive = true;
      return; // Don't activate both at the same time.
   }

   if (unitCount > (gTradeDefenderCount * 2) + buffer && farDefenseActive == false)
   {
      debugAttackWave("*** ACTIVATING FAR DEFENSE ***");
      // Create a small defense plan by the entrance to the trade route furthest from our base.
      defendPoint = vector(241.0, 0.0, 167.0);
      int farDefendPlan = createDefendPlan("Roaming Defend Plan", -1, 20.0, defendPoint, 10, defendPoint);
      aiPlanAddUnitType(farDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, gTradeDefenderCount, gTradeDefenderCount);

      farDefenseActive = true;
      return; // Don't activate both at the same time.
   }

   // Disable rule once both plans are active.
   if (nearDefenseActive == true && farDefenseActive == true)
   {
      xsDisableRule("createTradeDefendPlans");
      return;
   }
}

rule setupTradeRoute
inactive
minInterval 15
{
   int marketID = getUnit(cUnitTypeMarket);
   if (marketID < 0)
   {
      return;
   }

   int targetTownCenterID = -1;
   int tradePlan = -1;

   // Trade to the Player's town center.
   targetTownCenterID = getUnit(cUnitTypeTownCenter, 1);
   tradePlan = aiPlanCreate("Trade With P1", cPlanTrade);
   aiPlanSetVariableInt(tradePlan, cTradePlanTargetUnitTypeID, 0, cUnitTypeTownCenter);
   aiPlanSetVariableInt(tradePlan, cTradePlanTargetUnitID, 0, targetTownCenterID);
   aiPlanSetPriority(tradePlan, 100);
   aiPlanAddUnitType(tradePlan, cUnitTypeCaravanEgyptian, 0, 0, 200);
   aiPlanSetVariableInt(tradePlan, cTradePlanMarketID, 0, marketID);
   aiPlanSetVariableBool(tradePlan, cTradePlanUpdateTarget, 0, false);
   //aiPlanSetFlag(tradePlan, cPlanFlagNoMoreUnits, true);

   if (tradePlan >= 1)
   {
      xsDisableRule("setupTradeRoute");
      return;
   }
}

rule empowerTownCenter
inactive
minInterval 10
{
   int pharaoh = getUnit(cUnitTypePharaoh);
   int tc = getUnit(cUnitTypeTownCenter);
   aiTaskWorkUnit(pharaoh, tc, false);
   xsDisableRule("empowerTownCenter");
   return;
}

rule researchMediumAxemen
inactive
minInterval 120
{
   debugAttackWave("Starting Medium Axemen research plan.");
   researchSimpleTech(cTechMediumAxemen, cUnitTypeBarracks, -1, 50);
   xsDisableRule("researchMediumAxemen");
}

void buildBuilding(int type = cUnitTypeManor, vector location = cInvalidVector)
{
   if (getUnit(cUnitTypeVillagerEgyptian) >= 0)
   {
      int builder = cUnitTypeVillagerEgyptian;
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
}

rule buildBarracks
inactive
minInterval 10
group ruleGroupBuildPlans
{
    int building = cUnitTypeBarracks;
    vector location = vector(222.0, 0.0, 36.0);
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
    vector location = vector(196.0, 0.0, 21.0);
    if (getUnit(building, cMyID, cUnitStateABQ) < 1)
    {
        buildBuilding(building, location);
    }
}

rule buildMonumentToVillagers
inactive
minInterval 30
group ruleGroupBuildPlans
{
    int building = cUnitTypeMonumentToVillagers;
    vector location = vector(252.0, 0.0, 24.0);
    if (getUnit(building, cMyID, cUnitStateABQ) < 1)
    {
        buildBuilding(building, location);
    }
}

rule buildMonumentToSoldiers
inactive
minInterval 30
group ruleGroupBuildPlans
{
    int building = cUnitTypeMonumentToSoldiers;
    vector location = vector(256.0, 0.0, 24.0);
    if (getUnit(building, cMyID, cUnitStateABQ) < 1)
    {
        buildBuilding(building, location);
    }
}

rule buildMarketMonitor
inactive
minInterval 30
group ruleGroupBuildPlans
{
    int building = cUnitTypeMarket;
    vector location = vector(228.0, 0.0, 9.0);
    if (getUnit(building, cMyID, cUnitStateABQ) < 1)
    {
        buildBuilding(building, location);
    }
}