//==============================================================================
/* tgg03_p2.xs
   
   Red Norse player owning a base in the western half of the map. Trains
   a mix of human soldiers and myth units.

   They ignore any existing Heroes of Ragnarok or Eitri himself.

   Upon reaching Heroic Age, they randomize which infantry unit to train, Berserks or Huskarls.
    
*/
//==============================================================================
// Includes
include "core\main.xs";      // The bulk of the AI.
include "campaign\global_spc_modifiers.xs"; // global modifiers for difficulties.

//==============================================================================
/*	Rules

   Add scenario-specific rules & functions in the section below.
*/
//==============================================================================

float gTrainDelay = 10; // In seconds.
float gTrainDelayLong = 20; // In seconds.

int gFirstLandUnit = cUnitTypeRaidingCavalry; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 3;
int gSecondLandUnit = cUnitTypeThrowingAxeman; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 4;
int gThirdLandUnit = cUnitTypeHersir; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 3;

int gFourthLandUnit = cUnitTypeEinheri; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 1;
float gMaintainFourthLandUnitAdditional = 1; // Static number added to the maintain amount after multiplier has modified it.

int gFifthLandUnit = cUnitTypeBerserk; // Gets trained starting in Heroic. Has a 50/50 chance to be Berserks or Huskarls.
float gMaintainFifthLandUnitAmount = 0; // Set once the infantry unit type is decided.
float gMaintainFifthLandUnitAmountBerserk = 4;
float gMaintainFifthLandUnitAmountHuskarl = 4;

int gSixthLandUnit = cUnitTypeJarl; // Gets trained starting in Heroic.
float gMaintainSixthLandUnitAmount = 2;
float gMaintainSixthLandUnitAdditional = 1; // Static number added to the maintain amount after multiplier has modified it.
int gSeventhLandUnit = cUnitTypePortableRam; // Gets trained starting in Heroic.
float gMaintainSeventhLandUnitAmount = 1;
float gMaintainSeventhLandUnitAdditional = 1; // Static number added to the maintain amount after multiplier has modified it.

int gEighthLandUnit = cUnitTypeGodi; // Gets trained starting in Mythic.
float gMaintainEighthLandUnitAmount = 2;
int gNinthLandUnit = cUnitTypeBallista; // Gets trained starting in Mythic.
float gMaintainNinthLandUnitAmount = 1;
int gTenthLandUnit = cUnitTypeFenrisWolfBrood; // Gets trained starting in Mythic.
float gMaintainTenthLandUnitAmount = 2;

float gMaxVillagerCount = 12;
float gAttackStartDelay = 480; // In seconds.
float gAttackWaveInterval = 300; // In seconds.
float gAttackStartSize = 8;
float gAttackMaxSize = 20;

float gHeroicAgeUpTime = 720; // In seconds.
float gMythicAgeUpTime = 1440; // In seconds.

vector gForgeDefendPoint = vector(185.0, 0.0, 192.0);
float gForgeDefenders = 4; // Minimum amount of units defending the forge. Adjusted by difficulty.
float gForgeDefendersMax = 10; // Maxmimum amount of units dedfending the forge. Adjusted by difficulty.
float gForgeDefendersGrowthInterval = 240; // Every interval, the defender count grows depending on difficulty.

vector gOurTCLocation = vector(50.0, 0.0, 352.0);
int gForgeDefendPlan = -1;

Strategy scenarioAttackWaveStrategy()
{

   xsEnableRuleGroup("ruleGroupBuildPlans");
   xsEnableRule("stopReinforcingForgeAfterDelay"); // Stop units from joining this defend plan after short period of time.

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
      gMaintainFourthLandUnitAmount += gMaintainFourthLandUnitAdditional;

      // Upon reaching the Heroic Age, it is randomized whether to train Berserks or Huskarls.

      gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSixthLandUnitAmount += gMaintainSixthLandUnitAdditional;
      gMaintainSeventhLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSeventhLandUnitAmount += gMaintainSeventhLandUnitAdditional;

      gMaintainEighthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainNinthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainTenthLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gMaxVillagerCount *= gDifficultyModifierMaintainVillager;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;
      gTrainDelayLong *= gDifficultyModifierTrainDelay;
      gHeroicAgeUpTime *= gDifficultyModifierAgeUp;
      gMythicAgeUpTime *= gDifficultyModifierAgeUp;

      gForgeDefenders *= gDifficultyModifierAttackSizes;
      gForgeDefendersMax *= gDifficultyModifierAttackSizes;
      gForgeDefendersGrowthInterval *= gDifficultyModifierAttackInterval;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Raiding Cavalry
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Throwing Axemen
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Hersirs
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Einheri

      data.addUnitToMaintain(cUnitTypeVillagerDwarf, gMaxVillagerCount, 70);
      data.setTrainDelay(cUnitTypeVillagerDwarf, gTrainDelay); 

      // Berserks/Huskarls, Jarls, Portable Rams, Godi, Ballistas and Fenris Wolves are not produced until later.

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);         // Raiding Cavalry
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);        // Throwing Axemen
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);         // Hersirs
      data.setTrainDelay(gFourthLandUnit, gTrainDelayLong);    // Einheri

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
      data.setFlag(cStrategyFlagBuildHouses, true);
      data.setFlag(cStrategyFlagAutomaticOxCartTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticMainBaseTCRebuild, true);
      data.setFlag(cStrategyFlagAutoResearchEconomyUpgrades, true);

      gAttackWave.setPlayerToAttack(1); // Attack P1!

      // Where does our attack start and end.
      vector startPoint = vector(60.0, 0.0, 337.0); // By our town.
      vector targetPoint = vector(336.0, 0.0, 85.0); // Brokk's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 to Town Center");  // Going straight through the forge, then to Brokk.
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(111.0, 0.0, 313.0));
      kbPathAddWaypoint(pathID1, vector(139.0, 0.0, 222.0));
      kbPathAddWaypoint(pathID1, vector(188.0, 0.0, 190.0));
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      /* Disabling Path 2 as Eitri's attacking forces become too distracted by the player's Fishing Ships in that area to pose a proper threat.
      int pathID2 = kbPathCreate("Path 2 to Town Center");  // Going above the forge, into the forge and then to Brokk.
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(111.0, 0.0, 313.0));
      kbPathAddWaypoint(pathID2, vector(224.0, 0.0, 266.0));
      kbPathAddWaypoint(pathID2, vector(252.0, 0.0, 235.0));
      kbPathAddWaypoint(pathID2, vector(188.0, 0.0, 190.0));
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);
      */

      int pathID3 = kbPathCreate("Path 3 to Town Center");  // Going below the forge, into the forge and then to Brokk.
      kbPathAddWaypoint(pathID3, startPoint);
      kbPathAddWaypoint(pathID3, vector(111.0, 0.0, 313.0));
      kbPathAddWaypoint(pathID3, vector(81.0, 0.0, 201.0));
      kbPathAddWaypoint(pathID3, vector(131.0, 0.0, 153.0));
      kbPathAddWaypoint(pathID3, vector(188.0, 0.0, 190.0));
      kbPathAddWaypoint(pathID3, targetPoint);
      kbAttackRouteAddPath(routeID, pathID3);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      int landDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 30.0, startPoint, 10);
      aiPlanSetVariableFloat(landDefendPlan, cDefendPlanEngageRange, 0, 50.0);
      // Create a basic defend plan to keep military units defending our base.
      // We'll be pulling very specific unit types to prevent Eitri and Heroes of Ragnarok to become part of this plan.
      aiPlanAddUnitType(landDefendPlan, cUnitTypeHumanSoldier, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeHersir, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeGodi, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeAbstractSiegeWeapon, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeMythUnit, 0, 0, 200);

      // Create a high priority defend plan for use at the Forge.
      gForgeDefendPlan = createDefendPlan("Forge Defense", -1, 15.0, gForgeDefendPoint, 80, gForgeDefendPoint);
      aiPlanSetVariableFloat(gForgeDefendPlan, cDefendPlanEngageRange, 0, 30.0);
      aiPlanAddUnitType(gForgeDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, gForgeDefenders, gForgeDefenders);
      aiPlanSetEventHandler(gForgeDefendPlan, cPlanEventStateChange, "forgeDefendPlanEventHandler");

      // Set up an explore plan for a Raiding Cav.
      int explorePlanID = aiPlanCreate("Berserk Explore", cPlanExplore, -1);
      aiPlanSetPriority(explorePlanID, 99);
      aiPlanAddUnitType(explorePlanID, cUnitTypeRaidingCavalry, 1, 1, 1);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
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
            // Decide which Heroic Age infantry to use: Berserks or Huskarls.
            int unit = xsRandInt(0, 1);
            if (unit == 0)
            {
               debugAttackWave("I will be training Berserks as my infantry unit in Heroic Age.");
               gFifthLandUnit = cUnitTypeBerserk;
               gMaintainFifthLandUnitAmount = gMaintainFifthLandUnitAmountBerserk;
            }
            else if (unit == 1)
            {
               debugAttackWave("I will be training Huskarls as my infantry unit in Heroic Age.");
               gFifthLandUnit = cUnitTypeHuskarl;
               gMaintainFifthLandUnitAmount = gMaintainFifthLandUnitAmountHuskarl;
            }
            gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;

            data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount); // Start training Berserks/Huskarls.
            data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount); // Start training Jarls.
            data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount); // Start training Portable Rams.
            data.setTrainDelay(gFifthLandUnit, gTrainDelay);         // Berserks/Huskarls
            data.setTrainDelay(gSixthLandUnit, gTrainDelayLong);     // Jarls
            data.setTrainDelay(gSeventhLandUnit, gTrainDelayLong);   // Portable Rams
            gAttackWave.addAttackUnitType(gFifthLandUnit); // Start dispatching Berserks/Huskarls.
            gAttackWave.addAttackUnitType(gSixthLandUnit); // Start dispatching Jarls.
            gAttackWave.addAttackUnitType(gSeventhLandUnit); // Start dispatching Portable Rams.
            reachedAge3 = true;
         }
         if (age >= cAge4 && reachedAge4 == false)
         {
            data.addUnitToMaintain(gEighthLandUnit, gMaintainEighthLandUnitAmount); // Start training Godi.
            data.addUnitToMaintain(gNinthLandUnit, gMaintainNinthLandUnitAmount); // Start training Ballistas.
            data.addUnitToMaintain(gTenthLandUnit, gMaintainTenthLandUnitAmount); // Start training Fenris Wolves.
            data.setTrainDelay(gEighthLandUnit, gTrainDelayLong);    // Godi
            data.setTrainDelay(gNinthLandUnit, gTrainDelayLong);     // Ballistas
            data.setTrainDelay(gTenthLandUnit, gTrainDelayLong);     // Fenris Wolves
            gAttackWave.addAttackUnitType(gEighthLandUnit); // Start dispatching Godi.
            gAttackWave.addAttackUnitType(gNinthLandUnit); // Start dispatching Ballistas.
            gAttackWave.addAttackUnitType(gTenthLandUnit); // Start dispatching Fenris Wolves.
            reachedAge4 = true;
            done = true;
         }
      }

      // New Tech Rules
      bool classical_techs = false;
      if (age >= cAge2 && classical_techs == false)
      {
         // All Difficulties:
         researchSimpleTech(cTechMasons, cUnitTypeTownCenter, -1, 60);

         // Moderate and Up:

         // Hard and Up:

         // Titan Only:         
         
         classical_techs = true;
      }

      bool heroic_techs = false;
      if (age >= cAge3 && heroic_techs == false)
      {
         // All Difficulties:
         researchSimpleTech(cTechThurisazRune, cUnitTypeTemple, -1, 60);

         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            researchSimpleTech(cTechBronzeWeapons, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechHeavyInfantry, cUnitTypeLonghouse, -1, 60);
            researchSimpleTech(cTechHeavyCavalry, cUnitTypeGreatHall, -1, 60);
            researchSimpleTech(cTechBoilingOil, cUnitTypeSentryTower, -1, 60);
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            researchSimpleTech(cTechArchitects, cUnitTypeTownCenter, -1, 60);
            researchSimpleTech(cTechCallOfValhalla, cUnitTypeLonghouse, -1, 60);
            researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 60);
            researchSimpleTech(cTechHeavyInfantry, cUnitTypeLonghouse, -1, 60);
            researchSimpleTech(cTechHeavyCavalry, cUnitTypeGreatHall, -1, 60);
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            researchSimpleTech(cTechLevyHillFortSoldiers, cUnitTypeHillFort, -1, 60);
            researchSimpleTech(cTechLevyLonghouseSoldiers, cUnitTypeLonghouse, -1, 60);
            researchSimpleTech(cTechLevyGreatHallSoldiers, cUnitTypeGreatHall, -1, 60);
         }

         heroic_techs = true;
      }

      bool mythic_techs = false;
      if (age >= cAge4 && mythic_techs == false)
      {
         // All Difficulties:

         // Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            researchSimpleTech(cTechBurningPitch, cUnitTypeArmory, -1, 60);
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            researchSimpleTech(cTechChampionInfantry, cUnitTypeLonghouse, -1, 60);
            researchSimpleTech(cTechChampionCavalry, cUnitTypeGreatHall, -1, 60);

            // Only acquire the Huskarl tech if we are actually training Huskarls.
            if(gFifthLandUnit == cUnitTypeHuskarl)
            {
               researchSimpleTech(cTechBravery, cUnitTypeHillFort, -1, 60);
            }
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 60);
         }

         mythic_techs = true;
      }

      static int elapsed_time = 0;
      int growth_interval = xsGetTime() - elapsed_time;

      // Increase the Forge Defender count on a regular basis, adjusted by difficulty.
      if (growth_interval >= gForgeDefendersGrowthInterval)
      {
         // Run this as long as the minimum size is lower than the max size.
         if (gForgeDefenders < gForgeDefendersMax)
         {
            gForgeDefenders *= gDifficultyModifierAttackSizes;
            debugAttackWave("Increasing minimum Forge Defender amount to: " + gForgeDefenders);
         }
         if (gForgeDefenders > gForgeDefendersMax)
         {
            gForgeDefenders = gForgeDefendersMax;
            debugAttackWave("We have reached our maximum Forge Defender capacity: " + gForgeDefenders);
         }

         // If we have enough troops, we will attempt to replenish missing defenders on the same interval.
         // The troop check might also include attacking soldiers, but these may cover the potential smaller amount of new Forge Defenders.
         if (kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive) >= gForgeDefenders)
         {
            if (gForgeDefendPlan < 0)
            {
               gForgeDefendPlan = createDefendPlan("Forge Defense", -1, 15.0, gForgeDefendPoint, 80, gForgeDefendPoint);
               aiPlanSetVariableFloat(gForgeDefendPlan, cDefendPlanEngageRange, 0, 30.0);
               aiPlanSetEventHandler(gForgeDefendPlan, cPlanEventStateChange, "forgeDefendPlanEventHandler");
            }
            debugAttackWave("Allowing units to join the Forge Defense.");
            aiPlanAddUnitType(gForgeDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, gForgeDefenders, gForgeDefenders);
            aiPlanSetFlag(gForgeDefendPlan, cPlanFlagNoMoreUnits, false);
            xsEnableRule("stopReinforcingForgeAfterDelay"); // Stop units from joining this defend plan after short period of time.
         }

         elapsed_time = xsGetTime();
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}


// Set up the strategy.
void tgg03StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(40.00, 0.00, 362.00), 91);

   setOverrideStrategy(tgg03StrategySetup);

   gOverrideFarmCount = 0; // No farms.
   gTimeToFarm = false;
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

// Disables additional units from being added to the plan after a short period of time.
/*
   This is in order to prevent having units 'trickle' one-by-one from our base to the forge when we
   start losing defenders. It looks and plays better if we send our reinforcements in chunks.
*/
rule stopReinforcingForgeAfterDelay
inactive
minInterval 10
{
   if (gForgeDefendPlan < 0)
   {
      xsDisableRule("stopReinforcingForgeAfterDelay");
      return;
   }

   debugAttackWave("Stopping units from joining the Forge Defense.");
   aiPlanSetFlag(gForgeDefendPlan, cPlanFlagNoMoreUnits, true);
   xsDisableRule("stopReinforcingForgeAfterDelay");
   return;
}

void forgeDefendPlanEventHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateDone || state == cPlanStateFailed) // We're done or it failed, whatever just end the defend plan.
   {
      debugAttackWave("Our Forge Defend plan is done for now, get rid of it.");
      aiPlanDestroy(planID);
      gForgeDefendPlan = -1;
   }
}

// *** BUILD PLANS *** //
// Builds a given building on the given location.
void buildBuilding(int type = cUnitTypeHouse, vector location = cInvalidVector)
{
   int builder = cUnitTypeLogicalTypeNorseSoldierThatBuilds;
   if (getUnit(cUnitTypeBerserk, cMyID, cUnitStateAlive) >= 0)
   {
      builder = cUnitTypeBerserk; // Prefer using one of the Berserks we start out with, rather than pull from the Forge Defense plan.
   }
   int buildPlanID = aiPlanCreate("Build Plan", cPlanBuild, -1);
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID));
   kbBuildingPlacementSetBuildingPUID(bpID, type);
   kbBuildingPlacementSetCenterPosition(bpID, location, 15.0);
   kbBuildingPlacementSetStepSize(bpID, 1.0);
   kbBuildingPlacementSetBufferSpace(bpID, 0.0);
   kbBuildingPlacementAddPositionInfluence(bpID, location, 100.0, 50.0, cFalloffLinear);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, type);
   aiPlanAddUnitType(buildPlanID, builder, 1, 1, 1, false);
   aiPlanSetPriority(buildPlanID, 99);
}

rule buildLonghouse
inactive
minInterval 15
group ruleGroupBuildPlans
{
   int building = cUnitTypeLonghouse;
   vector location = vector(48.0, 0.0, 332.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 0)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildLonghouse", 60);
}

rule buildGreatHall
inactive
minInterval 30
group ruleGroupBuildPlans
{
   int building = cUnitTypeGreatHall;
   vector location = vector(69.0, 0.0, 350.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 0)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildGreatHall", 60);
}

rule buildTemple
inactive
minInterval 45
group ruleGroupBuildPlans
{
   int building = cUnitTypeTemple;
   vector location = vector(42.0, 0.0, 313.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 0)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildTemple", 60);
}

rule buildArmory
inactive
minInterval 60
group ruleGroupBuildPlans
{
   int building = cUnitTypeArmory;
   vector location = vector(37.0, 0.0, 370.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 0)
   {
      buildBuilding(building, location);
   }
}

rule buildHillFort
inactive
minInterval 60
group ruleGroupBuildPlans
{
   if (kbPlayerGetAge(cMyID) < cAge3)
   {
      return;
   }

   int building = cUnitTypeHillFort;
   vector location = vector(57.0, 0.0, 316.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 0)
   {
      buildBuilding(building, location);
   }
}

rule buildMarketMonitor
inactive
minInterval 120
group ruleGroupBuildPlans
{
   int building = cUnitTypeMarket;
   vector location = vector(52.0, 0.0, 375.0);
   if (getUnit(building, cMyID, cUnitStateABQ) < 0)
   {
      buildBuilding(building, location);
   }
   xsSetRuleMinInterval("buildMarketMonitor", 60);
}