//==============================================================================
/* fott26_p6.xs
   
   Loki's Minions (Loki)

   Red Norse player owning the base in the southwest. Trains Raiding Cavalry and either
   Berserks or Throwing Axemen based on difficulty.

   They also research many available techs based on difficulty.

   They do not attack until GiantsBegin() is called in the triggers.

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

float gTrainDelay = 3; // In seconds.

int gFirstLandUnit = cUnitTypeRaidingCavalry; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 5;
int gSecondLandUnit = cUnitTypeBerserk; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 3;
int gThirdLandUnit = cUnitTypeGodi; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 3;
int gFourthLandUnit = cUnitTypeThrowingAxeman; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 3;

float gMaxVillagerCount = 0;
float gAttackStartDelay = 30; // In seconds.
float gAttackWaveInterval = 120; // In seconds.
float gAttackStartSize = 3;
float gAttackMaxSize = 5;

float gSecondAttackStartDelay = 25; // In seconds.
float gSecondAttackWaveInterval = 120; // In seconds.
float gSecondAttackStartSize = 3;
float gSecondAttackMaxSize = 3;

float gAttackStartDelayLong = cWaitWithAttacking; // In seconds, effectively 'preventing' attacks until function GiantsBegin() is called.
bool gEnableAttacks = false; // Flipped by function GiantsBegin()

bool gTechsEnabled = false; // Flipped by function GetStronger()
bool gBuffAmounts = false; // Flipped by function GetStronger()

int gMainDefendPlan = -1;  // The ID for the main defend plan. It is later disabled when the AI's Town Center is destroyed.
float gStartTime = 0.0; // Controls how soon the AI researches technologies.

Strategy scenarioAttackWaveStrategy()
{

   // xsEnableRuleGroup("ruleGroupUpgrades");   // All rules handling upgrades are contained in one group.
   // gStartTime = xsGetTime();

   // debugAttackWave("Our activation time (gStartTime) is " + gStartTime);

   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugStrategy("***Starting Scenario Attack Wave Strategy***");
      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================
      
      // On Hard/Titan, the unit composition is different, and there are more units.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         //gFirstLandUnit = cUnitTypeRaidingCavalry;
         gMaintainFirstLandUnitAmount = 10;
         gAttackStartSize = 8;
         gAttackMaxSize = 10;
         gMaintainSecondLandUnitAmount = 5;
         gMaintainFourthLandUnitAmount = 5;
         gSecondAttackStartSize = 8;
         gSecondAttackMaxSize = 10;

         gAttackWaveInterval = 60; // In seconds.
         gSecondAttackWaveInterval = 120; // In seconds.

         debugAttackWave("I will be producing Raiding Cavalry and Throwing Axemen, because we're on Hard or Titan difficulty.");
      }
      else
      {
         debugAttackWave("I will be producing Raiding Cavalry and Berserks, because we're on Easy or Moderate difficulty.");
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Raiding Cavalry
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Berserks
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Goðar
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Throwing Axemen

      // Train delay, how long the AI waits before queuing up another unit.
      int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gFirstLandUnit);
      aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gFirstLandUnit, cProtoStatTrainPoints) + gTrainDelay);
      planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gSecondLandUnit);
      aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gSecondLandUnit, cProtoStatTrainPoints) + gTrainDelay);
      planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gThirdLandUnit);
      aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gThirdLandUnit, cProtoStatTrainPoints) + gTrainDelay);
      planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gFourthLandUnit);
      aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gFourthLandUnit, cProtoStatTrainPoints) + gTrainDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelayLong);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit); // Raiding Cavalry
      gAttackWave.addAttackUnitType(gFourthLandUnit); // Throwing Axemen
      gSecondAttackWave.setName("gSecondAttackWave");
      gSecondAttackWave.setAttackStartTime(gAttackStartDelayLong);
      gSecondAttackWave.setAttackInterval(gSecondAttackWaveInterval);
      gSecondAttackWave.setAttackSize(gSecondAttackStartSize);
      gSecondAttackWave.setMaxAttackSize(gSecondAttackMaxSize);
      gSecondAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gSecondAttackWave.addAttackUnitType(gSecondLandUnit); // Berserks
      gSecondAttackWave.addAttackUnitType(gThirdLandUnit); // Goðar

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // We want to research our military upgrades automatically.
      data.setFlag(cStrategyFlagAutoResearchMilitaryUpgrades, true);
      xsEnableRule("militaryUpgradeManager");

      gAttackWave.setPlayerToAttack(1); // Attack Player 1!
      gSecondAttackWave.setPlayerToAttack(1); // Attack Player 1!

      // Where does our attack start and end.
      vector startPoint = vector(27.0, 0.0, 155.0); // Right before the hill dips down.
      vector targetPoint = vector(83.0, 0.0, 236.0); // Lothbrok's base.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a path to it.
      int routeID = kbCreateAttackRouteWithPath("Route to Lothbrok", startPoint, targetPoint);
      int pathID = kbPathCreate("Path to Lothbrok");
      kbPathAddWaypoint(pathID, startPoint);
      kbPathAddWaypoint(pathID, vector(49.0, 0.0, 185.0));
      kbPathAddWaypoint(pathID, targetPoint);
      kbAttackRouteAddPath(routeID, pathID);
      
      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });
      
      gSecondAttackWave.setGatherPoint(startPoint);
      gSecondAttackWave.setTargetPoint(targetPoint);
      gSecondAttackWave.setAttackRouteID(routeID);
      gSecondAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      gMainDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 12.0, vector(29.0, 0.0, 127.0), 10);
      aiPlanSetVariableFloat(gMainDefendPlan, cDefendPlanEngageRange, 0, 25.0);
      aiPlanAddUnitType(gMainDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {

      if (gEnableAttacks == true)
      {
         /*gAttackStartDelay += xsGetTime();
         gSecondAttackStartDelay += xsGetTime();*/
         gAttackWave.setAttackStartTime(gAttackStartDelay);
         gSecondAttackWave.setAttackStartTime(gSecondAttackStartDelay);
         gEnableAttacks = false; // Flip this back to false so we don't update AttackStartTime again.
         debugAttackWave("Attack times for both waves:");
         gAttackWave.displayFirstAttackStats();
         gSecondAttackWave.displayFirstAttackStats();
      }

      // Start researching techs now that Hallgerd was rescued.
      if (gTechsEnabled == true)
      {
         xsEnableRuleGroup("ruleGroupUpgrades");   // All rules handling upgrades are contained in one group.
         gTechsEnabled = false; // Don't repeat.
      }

      // Start making more soldiers now that Hallgerd was rescued.
      if (gBuffAmounts == true)
      {
         gMaintainFirstLandUnitAmount *= 2; // Twice as many Raiding Cavalry.
         gMaintainSecondLandUnitAmount *= 2; // Twice as many Berserks.
         gMaintainThirdLandUnitAmount *= 2; // Twice as many Goðar.
         gMaintainFourthLandUnitAmount *= 2; // Twice as many Throwing Axemen.

         data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
         data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
         data.adjustUnitToMaintainAmount(gThirdLandUnit, gMaintainThirdLandUnitAmount);
         data.adjustUnitToMaintainAmount(gFourthLandUnit, gMaintainFourthLandUnitAmount);

         // Update attack size parameters based on the enlarged army composition.
         gAttackMaxSize *= 1.25; // Attack sizes increase by +25%.
         gAttackWave.setMaxAttackSize(gAttackMaxSize);
         gSecondAttackWave.setMaxAttackSize(gAttackMaxSize);

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
   setOverrideStrategy(fott26StrategySetup);
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
void GiantsBegin()
{
   gEnableAttacks = true;
   debugAttackWave("*** ATTACKS ARE NOW ENABLED ***");
}

void GetStronger()
{
   gTechsEnabled = true;
   gBuffAmounts = true;

   gStartTime = xsGetTime();
   debugAttackWave("Our activation time (gStartTime) is " + gStartTime);
}

// * * * * * * * * * * * //
//  TEMPLE TECHNOLOGIES  //
// * * * * * * * * * * * //

// Hall of Thanes: improves foot soldier speed.
rule researchHallOfThanes
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechHallOfThanes;

   // Not before 5 minutes (after activation) have passed.
   if (xsGetTime() < 300 + gStartTime)
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
      xsDisableRule("researchHallOfThanes");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// * * * * * * * * //
//  UNIT UPGRADES  //
// * * * * * * * * //

// Medium Infantry: improves infantry hitpoints and damage.
rule researchMediumInfantry
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechMediumInfantry;

   // Not before 2 minutes (after activation) have passed.
   if (xsGetTime() < 120 + gStartTime)
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
      xsDisableRule("researchMediumInfantry");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Heavy Infantry: improves infantry hitpoints and damage.
rule researchHeavyInfantry
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechHeavyInfantry;

   // Not before 7 minutes (after activation) have passed.
   if (xsGetTime() < 420 + gStartTime)
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
      xsDisableRule("researchHeavyInfantry");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Champion Infantry: improves infantry hitpoints and damage.
rule researchChampionInfantry
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechChampionInfantry;

   // Not before 12 minutes (after activation) have passed.
   if (xsGetTime() < 720 + gStartTime)
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
      xsDisableRule("researchChampionInfantry");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Medium Cavalry: improves cavalry hitpoints and damage.
rule researchMediumCavalry
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechMediumCavalry;

   // Not before 3 minutes (after activation) have passed.
   if (xsGetTime() < 180 + gStartTime)
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
      xsDisableRule("researchMediumCavalry");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Heavy Cavalry: improves cavalry hitpoints and damage.
rule researchHeavyCavalry
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechHeavyCavalry;

   // Not before 9 minutes (after activation) have passed.
   if (xsGetTime() < 540 + gStartTime)
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
      xsDisableRule("researchHeavyCavalry");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Champion Cavalry: improves cavalry hitpoints and damage.
rule researchChampionCavalry
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechChampionCavalry;

   // Not before 11 minutes (after activation) have passed.
   if (xsGetTime() < 660 + gStartTime)
   {
      return;
   }

   // Not below Titan.
   if (cDifficultyCurrent < cDifficultyTitan)
   {
      return;
   }

   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(techID) == cTechStatusActive)
   {
      xsDisableRule("researchChampionCavalry");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Levy Longhouse Soldiers: Longhouse units train faster.
rule researchLevyLonghouse
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechLevyLonghouseSoldiers;

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
      xsDisableRule("researchLevyLonghouse");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Conscript Longhouse Soldiers: Longhouse units train faster.
rule researchConscriptLonghouse
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechConscriptLonghouseSoldiers;

   // Not before 10 minutes (after activation) have passed.
   if (xsGetTime() < 600 + gStartTime)
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
      xsDisableRule("researchConscriptLonghouse");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Levy Great Hall Soldiers: Great Hall units train faster.
rule researchLevyGreatHall
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechLevyGreatHallSoldiers;

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
      xsDisableRule("researchLevyGreatHall");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}

// Conscript Great Hall Soldiers: Great Hall units train faster.
rule researchConscriptGreatHall
inactive
minInterval 30
group ruleGroupUpgrades
{
   int techID = cTechConscriptLonghouseSoldiers;

   // Not before 10 minutes (after activation) have passed.
   if (xsGetTime() < 600 + gStartTime)
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
      xsDisableRule("researchConscriptGreatHall");
      return;
   }
   else if (kbTechGetStatus(techID) == cTechStatusObtainable)
   {
      researchSimpleTech(techID);
      return;
   }
}