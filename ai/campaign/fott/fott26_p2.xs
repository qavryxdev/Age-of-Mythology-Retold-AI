//==============================================================================
/* fott26_p2.xs
   
   Loki's Minions (Loki)

   Red Norse player owning the base in the south. Trains Mountain Giants, Frost Giants and
   Ballistae to attack the player. They will maintain Temples in the back of their base
   (training Huskarls once rebuilding them becomes necessary).

   They do not attack until ActivateSouth() is called in the triggers.

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

float gTrainDelay = 30; // In seconds.
float gBallistaTrainDelay = 10; // In seconds.

int gFirstLandUnit = cUnitTypeMountainGiant; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 6;
int gSecondLandUnit = cUnitTypeFrostGiant; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 4;
int gThirdLandUnit = cUnitTypeBallista; // Gets trained from the start, on Moderate and above.
float gMaintainThirdLandUnitAmount = 2;
int gFourthLandUnit = cUnitTypeHuskarl; // Not trained from the start. Trained if we need to rebuild Temples.
float gMaintainFourthLandUnitAmount = 4;  // Not affected by Maintain Unit Difficulty Modifier.

int gFirstWaterUnit = cUnitTypeTransportShipNorse; 
float gMaintainFirstWaterUnitAmount = 1;  // Not affected by multiplier.

float gMaxVillagerCount = 7;
float gAttackStartDelay = 180; // In seconds.
float gAttackWaveInterval = 240; // In seconds.
float gAttackStartSize = 3;
float gAttackMaxSize = 8;

// Naval landings; these focus on the player instead of Forkbeard.
float gSecondAttackStartDelay = 30; // In seconds.
float gSecondAttackWaveInterval = 600; // In seconds.


float gAttackStartDelayLong = cWaitWithAttacking; // In seconds, effectively 'preventing' attacks until function ActivateSouth() is called.
bool gEnableAttacks = false; // Flipped by function ActivateSouth()
bool gEnableLandings = false; // Flipped by function EnableLandings()
bool gTechsEnabled = false; // Flipped by function GetStronger()
bool gBuffAmounts = false; // Flipped by function GetStronger()

int gMainDefendPlan = -1;  // The ID for the main defend plan. It is later disabled when the AI's Town Center is destroyed.
bool gMaintainHuskarls = false;  // Control variable for maintaining Huskarls (for Temple construction).
float gStartTime = 0.0; // Controls how soon the AI researches technologies.

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;

Strategy scenarioAttackWaveStrategy()
{

   xsEnableRule("moveDefendPoint");
   xsEnableRule("maintainBackTemples");

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
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gSecondAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gSecondAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Mountain Giants
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Frost Giants
      data.addUnitToMaintain(gFirstWaterUnit, gMaintainFirstWaterUnitAmount); // Transports

      // Only maintain Ballistae on Moderate and above.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Ballistae
      }

      // Train delay, how long the AI waits before queuing up another unit.
      int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gFirstLandUnit);
      aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gFirstLandUnit, cProtoStatTrainPoints) + gTrainDelay);
      planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gSecondLandUnit);
      aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gSecondLandUnit, cProtoStatTrainPoints) + gTrainDelay);
      planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gFourthLandUnit);
      aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gFourthLandUnit, cProtoStatTrainPoints) + gTrainDelay);


      // Only adjust Ballistae on Moderate and above.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gThirdLandUnit);
         aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gThirdLandUnit, cProtoStatTrainPoints) + gBallistaTrainDelay);
      }

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelayLong);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit); // Mountain Giants
      gAttackWave.addAttackUnitType(gSecondLandUnit); // Frost Giants

      // Only add Ballistae on Moderate and above.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         gAttackWave.addAttackUnitType(gThirdLandUnit); // Ballistae
      }

      // Make Huskarls regardless on Hard and Titan.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gMaintainHuskarls = true;
         if (cDifficultyCurrent == cDifficultyHard)
         {
            gMaintainFourthLandUnitAmount = 8;
         }
         else if (cDifficultyCurrent == cDifficultyTitan)
         {
            gMaintainFourthLandUnitAmount = 12;
         }
         // Landing waves
         gSecondAttackWave.setName("gSecondAttackWave");
         gSecondAttackWave.setAttackStartTime(gAttackStartDelayLong);
         gSecondAttackWave.setAttackInterval(gAttackStartDelayLong);
         gSecondAttackWave.setAttackSize(gAttackStartSize);
         gSecondAttackWave.setMaxAttackSize(gAttackMaxSize);
         gSecondAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
         gSecondAttackWave.addAttackUnitType(gFirstLandUnit); // Mountain Giants
         gSecondAttackWave.addAttackUnitType(gSecondLandUnit); // Frost Giants
         gSecondAttackWave.addAttackUnitType(gFourthLandUnit); // Huskarls
      }

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);

      // We want to research our military upgrades automatically.
      // data.setFlag(cStrategyFlagAutoResearchMilitaryUpgrades, true);
      xsEnableRule("militaryUpgradeManager");

      gAttackWave.setPlayerToAttack(1); // Attack Player 1!
      gSecondAttackWave.setPlayerToAttack(1); // Attack Player 1!

      // *** Anti-Forkbeard ***
      // Where does our attack start and end.
      vector startPoint = vector(95.0, 0.0, 63.0); // Right outside their gate.
      vector targetPoint = vector(140.0, 0.0, 120.0); // Lower entrance to Forkbeard's base.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a path to it.
      int routeID = kbCreateAttackRouteWithPath("Route to Forkbeard", startPoint, targetPoint);
      int pathID = kbPathCreate("Path to Forbeard");
      kbPathAddWaypoint(pathID, startPoint);
      kbPathAddWaypoint(pathID, vector(113.0, 0.0, 77.0));
      kbPathAddWaypoint(pathID, vector(113.0, 0.0, 85.0));
      kbPathAddWaypoint(pathID, targetPoint);
      kbAttackRouteAddPath(routeID, pathID);
      
      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      // *** Anti-Arkantos ***
      // Where does our attack start and end.
      vector targetPoint2 = vector(323.0, 0.0, 135.0); // Next to Blackhammer's Town Center.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a path to it.
      int routeID2 = kbCreateAttackRouteWithPath("Route to Blackhammer", startPoint, targetPoint);
      int pathID2 = kbPathCreate("Path to Blackhammer");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(113.0, 0.0, 77.0));
      kbPathAddWaypoint(pathID2, vector(141.0, 0.0, 67.0));
      kbPathAddWaypoint(pathID2, vector(183.0, 0.0, 59.0));
      kbPathAddWaypoint(pathID2, vector(245.0, 0.0, 115.0));
      kbPathAddWaypoint(pathID2, vector(363.0, 0.0, 103.0));
      kbPathAddWaypoint(pathID2, vector(323.0, 0.0, 135.0));
      kbPathAddWaypoint(pathID2, vector(219.0, 0.0, 247.0));
      kbPathAddWaypoint(pathID2, vector(329.0, 0.0, 199.0));
      kbPathAddWaypoint(pathID2, vector(373.0, 0.0, 311.0));
      kbPathAddWaypoint(pathID2, targetPoint2);
      kbAttackRouteAddPath(routeID2, pathID2);
      
      gSecondAttackWave.setGatherPoint(startPoint);
      gSecondAttackWave.setTargetPoint(targetPoint2);
      gSecondAttackWave.setAttackRouteID(routeID2);
      gSecondAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

   // SPLIT AMOUNTS
      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 2; // Mountain Giants
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 2; // Frost Giants
      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2; // Ballistae
      int fourthLandUnitSplitAmount = gMaintainFourthLandUnitAmount / 2; // Huskarls

   // DEFINE THE PLANS
      // Plan 1 (Guarding the west)
      gDefendPlan1 = createDefendPlan("Defense Plan 1", kbBaseGetMainID(cMyID), 15, vector(57.0, 0.0, 67.0), 10);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan1, cUnitTypeMountainGiant, 0, 0, firstLandUnitSplitAmount);
      aiPlanAddUnitType(gDefendPlan1, cUnitTypeFrostGiant, 0, 0, secondLandUnitSplitAmount);
      aiPlanAddUnitType(gDefendPlan1, cUnitTypeFireGiant, 0, 0, 50);
      aiPlanAddUnitType(gDefendPlan1, cUnitTypeBallista, 0, 0, thirdLandUnitSplitAmount);
      aiPlanAddUnitType(gDefendPlan1, cUnitTypeHuskarl, 0, 0, fourthLandUnitSplitAmount);

      // Plan 2 (Guarding the east)
      gDefendPlan2 = createDefendPlan("Defense Plan 2", kbBaseGetMainID(cMyID), 15, vector(79.0, 0.0, 29.0), 10);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan2, cUnitTypeMountainGiant, 0, 0, firstLandUnitSplitAmount);
      aiPlanAddUnitType(gDefendPlan2, cUnitTypeFrostGiant, 0, 0, secondLandUnitSplitAmount);
      aiPlanAddUnitType(gDefendPlan2, cUnitTypeBallista, 0, 0, thirdLandUnitSplitAmount);
      aiPlanAddUnitType(gDefendPlan2, cUnitTypeHuskarl, 0, 0, fourthLandUnitSplitAmount);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      if (done == false && gMaintainHuskarls == true)
      {
         done = true;
         data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Huskarls
      }

      if (gEnableAttacks == true)
      {
         gAttackWave.setAttackStartTime(gAttackStartDelay);
         gEnableAttacks = false; // Flip this back to false so we don't update AttackStartTime again.
      }

      if (gEnableLandings == true)
      {
         gSecondAttackWave.setAttackStartTime(gSecondAttackStartDelay);
         gSecondAttackWave.setAttackInterval(gSecondAttackWaveInterval);
         gEnableLandings = false; // Flip this back to false so we don't update AttackStartTime again.
      }

      // Start researching techs now that Lothbrok was recruited.
      if (gTechsEnabled == true)
      {
         xsEnableRuleGroup("ruleGroupUpgrades");   // All rules handling upgrades are contained in one group.
         gTechsEnabled = false; // Don't repeat.
      }

      // Start making more soldiers now that Lothbrok was recruited.
      if (gBuffAmounts == true)
      {
         gMaintainFirstLandUnitAmount *= 1.25; // +25% Mountain Giants.
         gMaintainSecondLandUnitAmount *= 1.5; // +50% Frost Giants.
         gMaintainThirdLandUnitAmount *= 1.25; // +25% Ballistae.
         gMaintainFourthLandUnitAmount *= 1.5;  // +50% Huskarls.

         data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
         data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
         data.adjustUnitToMaintainAmount(gThirdLandUnit, gMaintainThirdLandUnitAmount);
         data.adjustUnitToMaintainAmount(gFourthLandUnit, gMaintainFourthLandUnitAmount);
                                    
         // Update attack size parameters based on the enlarged army composition.
         gAttackMaxSize *= 1.15; // Attack size increases by +15%
         gAttackWave.setMaxAttackSize(gAttackMaxSize);
         gSecondAttackWave.setMaxAttackSize(gAttackMaxSize);

         // Train more Villagers to support the larger army.
         gMaxVillagerCount *= 2.50; // Train +150% more Villagers.
         gOverrideMaxVillagerPop = gMaxVillagerCount;

         gBuffAmounts = false; // Don't repeat.
      }

      gAttackWave.update();
      gSecondAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}


// Set up the strategy.
void fott26StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(25.00, 0.00, 61.00), 60);

   setOverrideStrategy(fott26StrategySetup);

   gOverrideFarmCount = 20; // Don't overdo the Farms.
   gRBDSystem.setMaxFarmsPerBase(20);
   gRBDSystem.setMaxFarmsPerIteration(20);
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

// *** FUNCTION - ActivateSouth ***
// Called from the triggers to enable attacks.
void ActivateSouth()
{
   gEnableAttacks = true;
   debugAttackWave("*** ATTACKS ARE NOW ENABLED ***");
}
	
// *** FUNCTION - ActivateLandings ***
// Called from the triggers to enable attacks.
void EnableLandings()
{
   gEnableLandings = true;
   debugAttackWave("*** LANDINGS ARE NOW ENABLED ***");
}

void GetStronger()
{
   gTechsEnabled = true;
   gBuffAmounts = true;

   gStartTime = xsGetTime();
   debugAttackWave("Our activation time (gStartTime) is " + gStartTime);
}


// *** FUNCTION - buildTemple ***
// Builds a Temple on the given location.
void buildTemple(vector buildPosition = cInvalidVector)
{
   int buildPlanID = aiPlanCreate("Temple Build Plan", cPlanBuild, -1);
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID));
   kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeTemple);
   kbBuildingPlacementSetCenterPosition(bpID, buildPosition, 10.0);
   kbBuildingPlacementSetStepSize(bpID, 2.0);
   kbBuildingPlacementSetBufferSpace(bpID, 0.0);
   kbBuildingPlacementAddPositionInfluence(bpID, buildPosition, 100.0, 50.0, cFalloffLinear);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, cUnitTypeTemple);
   aiPlanAddUnitType(buildPlanID, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, 2, 2, false);
   aiPlanSetPriority(buildPlanID, 90);
}

// *** RULE - moveDefendPoint ***
// Moves the defend point to the gate in the south of the base, near the objective tower.
rule moveDefendPoint
inactive
minInterval 10
{
   if (kbUnitCount(cUnitTypeTownCenter, cMyID, cUnitStateAlive) == 0)
   {
      vector towerGate = vector(25.0, 0.0, 22.0);
      aiPlanSetVariableVector(gDefendPlan1, cDefendPlanTargetPoint, 0, towerGate);
      aiPlanSetVariableVector(gDefendPlan2, cDefendPlanGatherPoint, 0, towerGate);
      debugAttackWave("Our Town Center is destroyed! Moving defend plan point to " + towerGate);
      xsDisableRule("moveDefendPoint");
   }
}

// *** RULE - maintainBackTemples ***
// Maintain temples in the back of our base, near the tower.
rule maintainBackTemples
inactive
minInterval 15
{
   vector templeWestPoint = vector(10.0, 0.0, 67.0);
   int templeWestCount = getUnitByLocation(cUnitTypeTemple, cMyID, cUnitStateABQ, templeWestPoint, 20.0);
   vector templeEastPoint = vector(53.0, 0.0, 10.0);
   int templeEastCount = getUnitByLocation(cUnitTypeTemple, cMyID, cUnitStateABQ, templeEastPoint, 20.0);

   // If it's the first time we're losing a Temple in the back, we gotta start creating some Huskarls.
   // Interacts with strategy.mUpdateFunc further up.
   if (gMaintainHuskarls == false && (templeWestCount < 1 || templeEastCount < 1))
   {
      debugAttackWave("I'm losing Temples! Time to start maintaining some Huskarls to construct new ones.");
      gMaintainHuskarls = true;
      return; // Exit so that we don't start off with a build plan immediately.
   }

   // Check if we're missing our West Temple.
   if (templeWestCount < 1)
   {
      debugAttackWave("I need to build a Temple in the west!");
      buildTemple(templeWestPoint);
      return;  // Exit so that we don't engage in different build plans too quickly.
   }

   // Check if we're missing our East Temple.
   if (templeEastCount < 1)
   {
      debugAttackWave("I need to build a Temple in the east!");
      buildTemple(templeEastPoint);
      return;  // Exit so that we don't engage in different build plans too quickly.
   }

   // If we run out of Hill Forts, we won't be able to make Huskarls to build our Temples... so we should stop processing this part.
   if (kbUnitCount(cUnitTypeHillFort, cMyID, cUnitStateAlive) < 1 && kbUnitCount(gFourthLandUnit, cMyID, cUnitStateAlive) < 1)
   {
      xsDisableRule("maintainBackTemples");
      return;
   }
}


// * * * * * * * * * * * //
//  TEMPLE TECHNOLOGIES  //
// * * * * * * * * * * * //

// Thurisaz Rune: improves Myth Unit speed and lets them regenerate health.
rule researchThurisazRune
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechThurisazRune;

   // Not before 3 minutes (after activation) have passed.
   if (xsGetTime() < 180 + gStartTime)
   {
      return;
   }

   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(techID) == cTechStatusActive)
   {
      xsDisableRule("researchThurisazRune");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Granite Blood: improves Mountain/Frost/Fire Giants' hitpoints.
rule researchGraniteBlood
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechGraniteBlood;

   // Don't get this tech on Easy or Moderate.
   if (cDifficultyCurrent <= cDifficultyModerate)
   {
      xsDisableRule("researchGraniteBlood");
      return;
   }

   // Not before 12 minutes (after activation) have passed.
   if (xsGetTime() < 720 + gStartTime)
   {
      return;
   }

   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(techID) == cTechStatusActive)
   {
      xsDisableRule("researchGraniteBlood");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Iron Weapons
rule researchIronWeapons
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechIronWeapons;

   // Don't get this tech on Easy or Moderate.
   if (cDifficultyCurrent <= cDifficultyModerate)
   {
      xsDisableRule("researchIronWeapons");
      return;
   }
   // Not before 5 minutes (after activation) have passed.
   if (xsGetTime() < 300 + gStartTime)
   {
      return;
   }
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(techID) == cTechStatusActive)
   {
      xsDisableRule("researchIronWeapons");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}
// Iron Armor
rule researchIronArmor
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechIronWeapons;

   // Titan Only
   if (cDifficultyCurrent <= cDifficultyHard)
   {
      xsDisableRule("researchIronArmor");
      return;
   }
   // Not before 10 minutes and 40 seconds (after activation) have passed.
   if (xsGetTime() < 640 + gStartTime)
   {
      return;
   }
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(techID) == cTechStatusActive)
   {
      xsDisableRule("researchIronArmor");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}
// Iron Shields
rule researchIronShields
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechIronShields;

   // Titan Only
   if (cDifficultyCurrent <= cDifficultyHard)
   {
      xsDisableRule("researchIronShields");
      return;
   }
   // Not before 14 minutes (after activation) have passed.
   if (xsGetTime() < 840 + gStartTime)
   {
      return;
   }
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(techID) == cTechStatusActive)
   {
      xsDisableRule("researchIronShields");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}
// Champion Infantry
rule researchChampionInfantry
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechChampionInfantry;

   // Don't get this tech on Easy or Moderate.
   if (cDifficultyCurrent <= cDifficultyModerate)
   {
      xsDisableRule("researchChampionInfantry");
      return;
   }
   // Not before 9 minutes (after activation) have passed.
   if (xsGetTime() < 540 + gStartTime)
   {
      return;
   }
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(techID) == cTechStatusActive)
   {
      xsDisableRule("researchChampionInfantry");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Conscript Hill Fort: improves Hill Fort unit training time.
rule researchConscriptHillFortSoldiers
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechConscriptHillFortSoldiers;

   // Only  get this tech on Titan.
   if (cDifficultyCurrent <= cDifficultyHard)
   {
      xsDisableRule("researchConscriptHillFortSoldiers");
      return;
   }

   // Not before 6 minutes (after activation) have passed.
   if (xsGetTime() < 360 + gStartTime)
   {
      return;
   }

   // Not below Moderate.
   if (cDifficultyCurrent < cDifficultyModerate)
   {
      return;
   }

   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(techID) == cTechStatusActive)
   {
      xsDisableRule("researchConscriptHillFortSoldiers");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Flood Control: improves the rate at which workers gather food from Farms.
rule researchFloodControl
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechFloodControl;

   // Not before 2 minutes (after activation) have passed.
   if (xsGetTime() < 120 + gStartTime)
   {
      return;
   }

   // Not below Hard.
   if (cDifficultyCurrent < cDifficultyHard)
   {
      return;
   }

   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(techID) == cTechStatusActive)
   {
      xsDisableRule("researchFloodControl");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Carpenters: improves workers' wood gather rate and carry capacity.
rule researchCarpenters
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechCarpenters;

   // Not before 4 minutes (after activation) have passed.
   if (xsGetTime() < 240 + gStartTime)
   {
      return;
   }

   // Not below Hard.
   if (cDifficultyCurrent < cDifficultyHard)
   {
      return;
   }

   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(techID) == cTechStatusActive)
   {
      xsDisableRule("researchCarpenters");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Quarry: improves workers' gold gather rate and carry capacity.
rule researchQuarry
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechQuarry;

   // Not before 5 minutes (after activation) have passed.
   if (xsGetTime() < 300 + gStartTime)
   {
      return;
   }

   // Not below Hard.
   if (cDifficultyCurrent < cDifficultyHard)
   {
      return;
   }

   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(techID) == cTechStatusActive)
   {
      xsDisableRule("researchQuarry");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Architects: Buildings are harder to destroy.
rule researchArchitects
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechArchitects;

   // Not before 6 minutes (after activation) have passed.
   if (xsGetTime() < 360 + gStartTime)
   {
      return;
   }

   // Not below Hard.
   if (cDifficultyCurrent < cDifficultyHard)
   {
      return;
   }

   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(techID) == cTechStatusActive)
   {
      xsDisableRule("researchArchitects");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}