//==============================================================================
/* fre01_p3.xs

   Folstag's Frost Giants (Loki)
   Owns a base in the west where it produces Mountain Giants, Frost Giants and a few Longhouse units. Doesn't attack until called upon.
   Also maintains a tiny amount of Longboats in the western waters, which it also attack with in a separate interval.
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
int gFirstLandUnit = cUnitTypeFrostGiant; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 2;
int gSecondLandUnit = cUnitTypeThrowingAxeman; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 2;
int gThirdLandUnit = cUnitTypeHirdman; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 4;
int gFourthLandUnit = cUnitTypeMountainGiant; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 1; // Base value that gets multiplied. They also train 1 more than this value.
int gFifthLandUnit = cUnitTypeBerserk; // Gets trained from the start.
float gMaintainFifthLandUnitAmount = 1;

float gMaxVillagerCount = 15; // Not affected by multiplier.
float gMaxFishingShipCount = 0;

float gAttackStartDelay = 60; // In seconds. Attacks are enabled by a trigger call.
float gAttackWaveInterval = 480; // In seconds.

float gAttackStartSize = 4;
float gAttackMaxSize = 7;

float gInitialFarmDelay = 300; // In seconds.

bool gInvokeFrost = false; // Every attack, we have a percentage chance to get to invoke Frost once.
int gFrostChance = 20; // The lower threshold a 100-sided die needs to roll under to succeed.

vector gOurTCLocation = vector(103.0, 0.0, 265.0);

Strategy scenarioAttackWaveStrategy()
{

   xsEnableRuleGroup("ruleGroupRebuild");
   
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

      gMaintainFourthLandUnitAmount += 1; // Train 1 more Mountain Giant than the multiplied value.

      gTrainDelay *= gDifficultyModifierTrainDelay;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;

      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      
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
      gAttackWave.setAttackStartTime(cWaitWithAttacking);  // Reduced to gAttackStartDelay when called by trigger.
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.setMinAttackSize(gAttackStartSize);
      gAttackWave.addAttackUnitType(gFirstLandUnit);  // Frost Giants
      gAttackWave.addAttackUnitType(gSecondLandUnit); // Huskarls
      gAttackWave.addAttackUnitType(gThirdLandUnit); // Hirdmen
      gAttackWave.addAttackUnitType(gFourthLandUnit); // Mountain Giants
      gAttackWave.addAttackUnitType(gFifthLandUnit); // Berserks
      debugAttackWave("Land Attacks:");
      gAttackWave.displayFirstAttackStats();

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticOxCartTraining, true);
      data.setFlag(cStrategyFlagBuildHouses, true);
      //data.setFlag(cStrategyFlagAutoBuildMilitaryBuildings, true);
      //data.setFlag(cStrategyFlagBuildTemple, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start.
      vector startPoint = vector(101.0, 0.0, 231.0); // In our base.
      vector endPoint = vector(38.0, 0.0, 37.0); // In the enemy base.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, endPoint);
      int pathID1 = kbPathCreate("Path 1");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(95.0, 0.0, 198.0));
      kbPathAddWaypoint(pathID1, vector(78.0, 0.0, 139.0));
      kbPathAddWaypoint(pathID1, vector(55.0, 0.0, 87.0));
      kbPathAddWaypoint(pathID1, endPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path 2");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID1, vector(95.0, 0.0, 198.0));
      kbPathAddWaypoint(pathID2, vector(78.0, 0.0, 139.0));
      kbPathAddWaypoint(pathID2, vector(110.0, 0.0, 102.0));
      kbPathAddWaypoint(pathID2, vector(87.0, 0.0, 60.0));
      kbPathAddWaypoint(pathID2, endPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      int pathID3 = kbPathCreate("Path 3");
      kbPathAddWaypoint(pathID3, startPoint);
      kbPathAddWaypoint(pathID1, vector(95.0, 0.0, 198.0));
      kbPathAddWaypoint(pathID3, vector(143.0, 0.0, 159.0));
      kbPathAddWaypoint(pathID3, vector(110.0, 0.0, 102.0));
      kbPathAddWaypoint(pathID3, vector(87.0, 0.0, 60.0));
      kbPathAddWaypoint(pathID3, endPoint);
      kbAttackRouteAddPath(routeID, pathID3);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(endPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
            // gFrostChance-percent chance to start using Frost.
            // When succeeding a roll, Frost gets to be invoked once before we have to roll again.
            if (gInvokeFrost == false)
            {
               int random = xsRandInt(99) + 1;
               debugAttackWave("Rolling a die to see if we can invoke Frost. The result is... " + random + "!");
               if (random <= gFrostChance)
               {
                  gInvokeFrost = true;
                  xsEnableRule("useFrost");
                  debugAttackWave("Success! The die roll beats the threshold of " + gFrostChance + "! Now we can invoke Frost once before rolling again.");
               }
               else
               {
                  debugAttackWave("No Frost invocations yet. The die roll needs to be under " + gFrostChance + " for use to start casting it.");
               }
            }
         }
      );

      int landDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 20.0, startPoint);
      aiPlanAddUnitType(landDefendPlan, gFirstLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gSecondLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gThirdLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gFourthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gFifthLandUnit, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      if (gTimeToFarm == false && xsGetTime() >= gInitialFarmDelay)
      {
         gTimeToFarm = true; // Start farming early.
      }

      gAttackWave.update();
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
   //gMaxVillagerCount *= gDifficultyModifierMaintainVillager;
   //gMaxFishingShipCount *= gDifficultyModifierMaintainFishing;

   gOverrideMaxVillagerPop = gMaxVillagerCount;
   gOverrideMaxFishingShipPop = gMaxFishingShipCount;

   gMainGatherBase = createOverrideGatherBase(vector(108.00, 0.00, 245.00), 47); // Covering most of our large base.

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

// Called by trigger "O2_Folstag_Open" to enable attacks.
void enableAttacks()
{
   debugAttackWave("Attacks have been enabled!");
   gAttackWave.setAttackStartTime(gAttackStartDelay);
   gAttackWave.displayFirstAttackStats();

   // Enable upgrades.
   xsEnableRuleGroup("ruleGroupUpgrades");
}

// Use Frost while attacking and P1 has more than 6 soldiers in sight.
rule useFrost
inactive
minInterval 5
{
   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   int unitID = -1;
   int numEnemies = -1;
   for (int i = 0; i < attackPlans.size(); i++)
   {
      if (aiPlanGetParentID(attackPlans[i]) == -1)
      {
         // We just take the first unit to scan from.
         unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
         if (unitID >= 0)
         {
            int queryID = useSimpleUnitQuery(cUnitTypeMilitaryUnit, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 15.0);
            numEnemies = kbUnitQueryExecute(queryID);
            debugAttackWave("numEnemies for invoking Frost: " + numEnemies);
            if (numEnemies >= 6)
            {
               if (aiCastGodPowerAtPosition(cProtoPowerFlamingWeapons, kbUnitGetPosition(kbUnitQueryGetResult(queryID, 0))) == true)
               {
                  debugAttackWave("Invoke Frost!");
                  xsDisableRule("useFrost");
                  gInvokeFrost = false;
               }
            }
         }
      }
   }
}

rule researchMediumInfantry
inactive
minInterval 60
group ruleGroupUpgrades
{
   debugAttackWave("Starting Medium Infantry research plan.");
   researchSimpleTech(cTechMediumInfantry, cUnitTypeLonghouse, -1, 50);
   xsDisableRule("researchMediumInfantry");
}

rule researchHeavyInfantry
inactive
minInterval 120
group ruleGroupUpgrades
{
   if (cDifficultyCurrent < cDifficultyHard)
   {
      xsDisableRule("researchHeavyInfantry");
      return;
   }

   debugAttackWave("Starting Heavy Infantry research plan.");
   researchSimpleTech(cTechHeavyInfantry, cUnitTypeLonghouse, -1, 50);
   xsDisableRule("researchHeavyInfantry");
}

rule researchCopperUpgrades
inactive
minInterval 90
group ruleGroupUpgrades
{
   debugAttackWave("Starting Copper Upgrades research plans.");
   researchSimpleTech(cTechCopperArmor, cUnitTypeArmory, -1, 50);
   researchSimpleTech(cTechCopperShields, cUnitTypeArmory, -1, 50);
   researchSimpleTech(cTechCopperWeapons, cUnitTypeArmory, -1, 50);
   xsDisableRule("researchCopperUpgrades");
}

rule researchBronzeUpgrades
inactive
minInterval 180
group ruleGroupUpgrades
{
   if (cDifficultyCurrent < cDifficultyModerate)
   {
      xsDisableRule("researchBronzeUpgrades");
      return;
   }
   debugAttackWave("Starting Bronze Upgrades research plans.");
   researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 50);
   researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 50);
   researchSimpleTech(cTechBronzeWeapons, cUnitTypeArmory, -1, 50);
   xsDisableRule("researchBronzeUpgrades");
}

rule researchIronUpgrades
inactive
minInterval 300
group ruleGroupUpgrades
{
   if (cDifficultyCurrent < cDifficultyModerate)
   {
      xsDisableRule("researchIronUpgrades");
      return;
   }
   debugAttackWave("Starting Iron Upgrades research plans.");
   researchSimpleTech(cTechIronArmor, cUnitTypeArmory, -1, 50);
   researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 50);
   researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 50);
   xsDisableRule("researchIronUpgrades");
}

void buildBuilding(int type = -1, vector location = cInvalidVector)
{
   int builder = cUnitTypeLogicalTypeNorseSoldierThatBuilds;
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

rule buildLonghouse
inactive
minInterval 10
group ruleGroupRebuild
{
   int building = cUnitTypeLonghouse;
   vector location = vector(93.0, 0.0, 245.0);
   if (kbUnitCount(building, cMyID, cUnitStateABQ) < 1)
   {
      buildBuilding(building, location);
   }
}

rule buildTemple
inactive
minInterval 10
group ruleGroupRebuild
{
   int building = cUnitTypeTemple;
   vector location = vector(127.0, 0.0, 235.0);
   if (kbUnitCount(building, cMyID, cUnitStateABQ) < 1)
   {
      buildBuilding(building, location);
   }
}