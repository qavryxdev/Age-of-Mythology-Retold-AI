//==============================================================================
/* tna07_p6.xs
   
   Kastor (Oranos)

   Maintains a basic base and a handful of units. Never attacks.
   They are forced to keep their units away from the enemy base, and keep Kastor close to the Town Center after a while.

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

int gFirstLandUnit = cUnitTypeDestroyer; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 4;   // Not affected by multiplier.
int gSecondLandUnit = cUnitTypeContarius; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 4;  // Not affected by multiplier.
int gThirdLandUnit = cUnitTypeArcus; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 4;   // Not affected by multiplier.

float gMaxVillagerCount = 5;  // Not affected by multiplier.

vector gOurTCLocation = vector(185.0, 0.0, 273.0);

Strategy scenarioAttackWaveStrategy()
{

   xsEnableRule("pullMyUnitsBack");
   xsEnableRule("restrainKastor");
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

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Destroyer
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Contarius
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Arcus
   
      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);      // Destroyer
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);     // Contarius
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);      // Arcus

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticMainBaseTCRebuild, true);
      data.setFlag(cStrategyFlagAutomaticFortressRepair, true);
      data.setFlag(cStrategyFlagAutomaticBuildingRepair, true);
      
      vector defendPoint = vector(176.0, 0.0, 264.0);
      int lastStand = createDefendPlan("Last Stand", kbBaseGetMainID(cMyID), 15.0, defendPoint);
      aiPlanAddUnitType(lastStand, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}


// Set up the strategy.
void tna07StrategySetup()
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

   gOverrideMaxVillagerPop = gMaxVillagerCount;

   gMainGatherBase = createOverrideGatherBase(vector(190.00, 0.00, 285.00), 32);
   createOverrideGatherBase(vector(243.00, 0.00, 249.00), 32);

   setOverrideStrategy(tna07StrategySetup);

   gOverrideFarmCount = 5; // Don't overdo the Farms.
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

rule pullMyUnitsBack
inactive
minInterval 5
{
   vector enemyBase = vector(98.0, 0.0, 292.0); // By Player 2's collection of military buildings.
   vector retreatPoint = vector(176.0, 0.0, 264.0);   // By our Town Center. This is where we send units who wander too close to the enemy.

   int queryID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive, enemyBase, 50.0);
   int numUnits = kbUnitQueryExecute(queryID);
   if (numUnits >= 1)
   {
      debugAttackWave("We have " + numUnits + " units going too close to the enemy. Pull them back!");
      int unitID = -1;

      for (int i = 0; i < numUnits; i++)
      {
         unitID = kbUnitQueryGetResult(queryID, i);
         aiTaskMoveUnit(unitID, retreatPoint);
      }
   }
}

rule restrainKastor
inactive
minInterval 8
{
   // Let Kastor move freely for the first 5 minutes.
   if (xsGetTime() < 300)
   {
      return;
   }

   vector restrainPoint = vector(185.0, 0.0, 273.0);   // Centered on our Town Center.
   if (getUnitByLocation(cUnitTypeKastor, cMyID, cUnitStateAlive, restrainPoint, 20.0) <= 0)
   {
      debugAttackWave("Keep Kastor close to the TC so he's less likely to die.");
      int kastorID = getUnit(cUnitTypeKastor);
      aiTaskMoveUnit(kastorID, restrainPoint);
   }
}

void buildBuilding(int type = cUnitTypeManor, vector location = cInvalidVector)
{
   if (getUnit(cUnitTypeVillagerAtlantean) >= 0)
   {
      int builder = cUnitTypeVillagerAtlantean;
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

rule buildPalace
inactive
minInterval 40
group ruleGroupBuildPlans
{
   int building = cUnitTypePalace;
   vector location = vector(175.0, 0.0, 293.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 0)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildPalace", 20);
}

rule buildMilitaryBarracks
inactive
minInterval 75
group ruleGroupBuildPlans
{
   int building = cUnitTypeMilitaryBarracks;
   vector location = vector(195.0, 0.0, 293.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 0)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildMilitaryBarracks", 20);
}

rule buildManors
inactive
minInterval 110
group ruleGroupBuildPlans
{
   // We're going to need a manor to be able to train all of our desired units.
   if ((getUnit(cUnitTypeManor, cMyID, cUnitStateABQ) < 0) &&
       (getUnit(cUnitTypePalace, cMyID, cUnitStateABQ) >= 0) &&
       (getUnit(cUnitTypeMilitaryBarracks, cMyID, cUnitStateABQ) >= 0))
   {
      int building = cUnitTypeManor;
      vector location = vector(176.0, 0.0, 256.0);
      if (getUnit(building, cMyID, cUnitStateABQ) < 0)
      {
         buildBuilding(building, location);
      }
   }
   xsSetRuleMinInterval("buildManors", 20);
}