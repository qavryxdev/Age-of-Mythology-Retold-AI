//==============================================================================
/* tgg09_p5.xs
   
   Ymir's Followers (Loki)

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

int gFirstLandUnit = cUnitTypeHersir; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 3;
int gSecondLandUnit = cUnitTypeHirdman; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 5;
int gThirdLandUnit = cUnitTypeTroll; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 2;
int gFourthLandUnit = cUnitTypeJarl; // Gets trained starting in Heroic.
float gMaintainFourthLandUnitAmount = 2;
int gFifthLandUnit = cUnitTypeBattleBoar; // Gets trained starting in Heroic.
float gMaintainFifthLandUnitAmount = 1;
int gSixthLandUnit = cUnitTypeHuskarl; // Gets trained starting in Mythic.
float gMaintainSixthLandUnitAmount = 3;
int gSeventhLandUnit = cUnitTypeFenrisWolfBrood; // Gets trained starting in Mythic.
float gMaintainSeventhLandUnitAmount = 2;

float gMaxVillagerCount = 14;

float gAttackStartDelayLong = cWaitWithAttacking; // In seconds.
float gAttackStartDelay = 180; // In seconds.
float gAttackWaveInterval = 360; // In seconds.
float gAttackStartSize = 7;
float gAttackMaxSize = 16;

float gHeroicAgeUpTime = 620; // In seconds.
float gMythicAgeUpTime = 1080; // In seconds.

vector gOurTCLocation = vector(105.0, 0.0, 239.0);

int gUpperDefendPlan = -1;
int gLowerDefendPlan = -1;


Strategy scenarioAttackWaveStrategy()
{

   xsEnableRule("useHealingSpring");
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

      // Certain parameters are way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gAttackStartSize = 3;
         gAttackMaxSize = 4;
         gAttackWaveInterval = 600; // In seconds.
      }
      // The first attack happens sooner on Titan.
      if (cDifficultyCurrent == cDifficultyTitan)
      {
         gAttackStartDelay = 60;
      }

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
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Hersir
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Hirdman
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Troll

      // Arcus and Satyrs are maintained upon reaching Heroic.
      // Centimanus and Fire Siphons are maintained upon reaching Mythic.
   
      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);      // Hersir
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);     // Hirdman
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);      // Troll
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);     // Jarl
      data.setTrainDelay(gFifthLandUnit, gTrainDelay);      // Battle Boar
      data.setTrainDelay(gSixthLandUnit, gTrainDelay);      // Huskarl
      data.setTrainDelay(gSeventhLandUnit, gTrainDelay);    // Fenris Wolf

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelayLong);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);  // Hersir
      gAttackWave.addAttackUnitType(gSecondLandUnit); // Hirdman
      gAttackWave.addAttackUnitType(gThirdLandUnit);  // Troll

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      gAttackWave.setPlayerToAttack(1); // Attack P1!

      // Where does our attack start and end.
      vector startPoint = vector(55.0, 0.0, 217.0); // By our town.
      // vector startPoint = vector(63.0, 0.0, 251.0); // Closer inside
      vector targetPoint = vector(253.0, 0.0, 50.0); // Player's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 - Up and Above");  // Running along the northern edge of the map, then attacking the player's northern pass.
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(202.0, 0.0, 221.0));
      kbPathAddWaypoint(pathID1, vector(246.0, 0.0, 153.0));
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path 2 - Middle and Above");  // Going through the middle of the map, then attacking the player's northern pass.
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(86.0, 0.0, 157.0));
      kbPathAddWaypoint(pathID2, vector(246.0, 0.0, 153.0));
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      int pathID3 = kbPathCreate("Path 3 - Middle and Below");  // Going through the middle of the map, then attacking the player's southern pass.
      kbPathAddWaypoint(pathID3, startPoint);
      kbPathAddWaypoint(pathID3, vector(86.0, 0.0, 157.0));
      kbPathAddWaypoint(pathID3, vector(144.0, 0.0, 54.0));
      kbPathAddWaypoint(pathID3, targetPoint);
      kbAttackRouteAddPath(routeID, pathID3);

      int pathID4 = kbPathCreate("Path 4 - Down and Below");  // Running along the southern edge of the map, then attacking the player's southern pass.
      kbPathAddWaypoint(pathID4, startPoint);
      kbPathAddWaypoint(pathID4, vector(36.0, 0.0, 92.0));
      kbPathAddWaypoint(pathID4, vector(144.0, 0.0, 54.0));
      kbPathAddWaypoint(pathID4, targetPoint);
      kbAttackRouteAddPath(routeID, pathID4);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });


      // Create TWO general purpose plans, using two halves of our army to protect two separate spots.
      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 2;
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 2;
      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2;
      int fourthLandUnitSplitAmount = gMaintainFourthLandUnitAmount / 2;
      int fifthLandUnitSplitAmount = gMaintainFifthLandUnitAmount / 2;
      int sixthLandUnitSplitAmount = gMaintainSixthLandUnitAmount / 2;
      int seventhLandUnitSplitAmount = gMaintainSeventhLandUnitAmount / 2;
   
      // Upper Plan:
      vector defendPoint = vector(81.0, 0.0, 243.0);
      gUpperDefendPlan = createDefendPlan("Upper Land Defend", -1, 30.0, defendPoint, 10, defendPoint);
      aiPlanSetVariableFloat(gUpperDefendPlan, cDefendPlanEngageRange, 0, 50.0);
      aiPlanAddUnitType(gUpperDefendPlan, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount);
      aiPlanAddUnitType(gUpperDefendPlan, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount);
      aiPlanAddUnitType(gUpperDefendPlan, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount);
      aiPlanAddUnitType(gUpperDefendPlan, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount);
      aiPlanAddUnitType(gUpperDefendPlan, gFifthLandUnit, 0, 0, fifthLandUnitSplitAmount);
      aiPlanAddUnitType(gUpperDefendPlan, gSixthLandUnit, 0, 0, sixthLandUnitSplitAmount);
      aiPlanAddUnitType(gUpperDefendPlan, gSeventhLandUnit, 0, 0, seventhLandUnitSplitAmount);

      // Lower Plan:
      defendPoint = vector(43.0, 0.0, 185.0);
      // defendPoint = vector(59.0, 0.0, 223.0); Closer inside their base
      gLowerDefendPlan = createDefendPlan("Lower Land Defend", -1, 30.0, defendPoint, 10, defendPoint);
      aiPlanSetVariableFloat(gLowerDefendPlan, cDefendPlanEngageRange, 0, 50.0);
      aiPlanAddUnitType(gLowerDefendPlan, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount);
      aiPlanAddUnitType(gLowerDefendPlan, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount);
      aiPlanAddUnitType(gLowerDefendPlan, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount);
      aiPlanAddUnitType(gLowerDefendPlan, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount);
      aiPlanAddUnitType(gLowerDefendPlan, gFifthLandUnit, 0, 0, fifthLandUnitSplitAmount);
      aiPlanAddUnitType(gLowerDefendPlan, gSixthLandUnit, 0, 0, sixthLandUnitSplitAmount);
      aiPlanAddUnitType(gLowerDefendPlan, gSeventhLandUnit, 0, 0, seventhLandUnitSplitAmount);
      
      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      static bool enableAttacks = false;
      static bool reachedAge3 = false;
      static bool reachedAge4 = false;
      int age = kbPlayerGetAge(cMyID);
      int time = xsGetTime();
      if (done == false)
      {
         if (age < cAge3 && time >= gHeroicAgeUpTime)
         {
            researchSimpleTech(cTechHeroicAgeBragi, cUnitTypeTownCenter, -1, 75);
         }
         else if (age < cAge4 && time >= gMythicAgeUpTime)
         {
            researchSimpleTech(cTechMythicAgeTyr, cUnitTypeTownCenter, -1, 75);
         }
         
         if (age >= cAge3 && reachedAge3 == false)
         {
            data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Jarl
            gAttackWave.addAttackUnitType(gFourthLandUnit);
            reachedAge3 = true;
         }

         // Start dispatching Battle Boars only after 480 seconds (Not Easy)
         static bool battle_boars = false;
         if (battle_boars == false)
         {
            if (cDifficultyCurrent >= cDifficultyModerate && xsGetTime() >= 480)
            {
               data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount); // Battle Boar
               gAttackWave.addAttackUnitType(gFifthLandUnit);
               battle_boars = true;
            }
         }

         // Don't use Flaming Weapons until around 640 seconds.
         static bool flaming_weapons = false;
         if (flaming_weapons == false && xsGetTime() >= 640)
         {
            xsEnableRule("useFlamingWeapons");
            flaming_weapons = true;
         }

         if (age >= cAge4 && reachedAge4 == false)
         {
            data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount); // Huskarl
            data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount); // Fenris Wolf
            gAttackWave.addAttackUnitType(gSixthLandUnit);
            gAttackWave.addAttackUnitType(gSeventhLandUnit);
            reachedAge4 = true;
            done = true;
         }
      }

      if (enableAttacks == false && kbUnitCount(cUnitTypeTownCenter, cMyID, cUnitStateAlive) >= 1)
      {
         gAttackWave.setAttackStartTime(gAttackStartDelay);
         enableAttacks = true;
         
         // Set flags for automatic resource gathering.
         data.setFlag(cStrategyFlagAutomaticEco, true);
         data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
         data.setFlag(cStrategyFlagBuildHouses, true);
         data.setFlag(cStrategyFlagAutomaticOxCartTraining, true);
         data.setFlag(cStrategyFlagAutomaticTCRepair, true);
         data.setFlag(cStrategyFlagAutomaticMainBaseTCRebuild, true);
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}


// Set up the strategy.
void tna09StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(85.00, 0.00, 245.00), 83);
   // Since we start without a base in this mission, we must promote this base to be main to avoid issues.
   kbBaseSetFlag(cMyID, gMainGatherBase, cBaseFlagMain, true);

   setOverrideStrategy(tna09StrategySetup);

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

rule useHealingSpring
inactive
minInterval 10
{
   // Don't attempt to invoke before 3 minutes have elapsed.
   if (xsGetTime() < 180)
   {
      return;
   }

   // Invoke god power!
   vector location = vector(64.0, 0.0, 235.0);
   if (aiCastGodPowerAtPosition(cProtoPowerHealingSpring, location) == true)
   {
      debugAttackWave("Casted Healing Spring!");
      xsDisableRule("useHealingSpring");
      return;
   }
}

// When reaching Heroic, look to invoke Chaos during an attack.
// Upon a successful invocation, wait 10 minutes before doing it again.
rule useFlamingWeapons
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
            // Look for enemies.
            numEnemies = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 20.0);
            debugAttackWave("numEnemies for casting Flaming Weapons offensively: " + numEnemies);
            if (numEnemies >= 6)
            {
               // Invoke god power!
               if (aiCastGodPowerAtPosition(cProtoPowerFlamingWeapons, kbUnitGetPosition(unitID)) == true)
               {
                  debugAttackWave("Casted Flaming Weapons!");
                  xsDisableRule("useFlamingWeapons");
                  return;
               }
            }
         }
      }
   }
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
   aiPlanAddUnitType(buildPlanID, builder, 1, 2, 2, false);
   aiPlanSetPriority(buildPlanID, 90);
}

rule buildTownCenter
inactive
minInterval 10
group ruleGroupBuildPlans
{
   if (getUnit(cUnitTypeLogicalTypeNorseSoldierThatBuilds, cMyID, cUnitStateAlive) < 1)
   {
      return;
   }
   int building = cUnitTypeTownCenter;
   vector location = vector(105.0, 0.0, 239.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 1)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildTownCenter", 30);
}

rule buildLonghouse
inactive
minInterval 10
group ruleGroupBuildPlans
{
   if (getUnit(cUnitTypeLogicalTypeNorseSoldierThatBuilds, cMyID, cUnitStateAlive) < 1)
   {
      return;
   }
   int building = cUnitTypeLonghouse;
   vector location = vector(100.0, 0.0, 268.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 1)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildLonghouse", 30);
}

rule buildGreatHall
inactive
minInterval 10
group ruleGroupBuildPlans
{
   if (getUnit(cUnitTypeLogicalTypeNorseSoldierThatBuilds, cMyID, cUnitStateAlive) < 1)
   {
      return;
   }
   int building = cUnitTypeGreatHall;
   vector location = vector(104.0, 0.0, 215.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 1)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildGreatHall", 30);
}

rule buildTemple
inactive
minInterval 10
group ruleGroupBuildPlans
{
   if (getUnit(cUnitTypeLogicalTypeNorseSoldierThatBuilds, cMyID, cUnitStateAlive) < 1)
   {
      return;
   }
   int building = cUnitTypeTemple;
   vector location = vector(85.0, 0.0, 252.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 1)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildTemple", 30);
}

rule buildArmory
inactive
minInterval 10
group ruleGroupBuildPlans
{
   if (getUnit(cUnitTypeLogicalTypeNorseSoldierThatBuilds, cMyID, cUnitStateAlive) < 1)
   {
      return;
   }
   int building = cUnitTypeArmory;
   vector location = vector(73.0, 0.0, 267.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 1)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildArmory", 30);
}

rule buildHillFort
inactive
minInterval 10
group ruleGroupBuildPlans
{
   if (getUnit(cUnitTypeLogicalTypeNorseSoldierThatBuilds, cMyID, cUnitStateAlive) < 1)
   {
      return;
   }
   if (kbPlayerGetAge(cMyID) < cAge3)
   {
      return;
   }

   int building = cUnitTypeHillFort;
   vector location = vector(129.0, 0.0, 237.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 1)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildHillFort", 30);
}