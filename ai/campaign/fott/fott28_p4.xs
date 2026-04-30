//==============================================================================
/* fott28_p2.xs

   Teal Norse player that builds up a small base on the mainland. Builds and maintains some production buildings,
   eventually attacking player 1 with Hirdmen, Raiding Cavalry, Berserks, and Mountain Giants.
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
int gFirstLandUnit = cUnitTypeHirdman; // Begins training once the Longhouse is built, but not on Easy.
float gMaintainFirstLandUnitAmount = 4;
int gSecondLandUnit = cUnitTypeRaidingCavalry; // Begins training once the Great Hall is built.
float gMaintainSecondLandUnitAmount = 4;
int gThirdLandUnit = cUnitTypeBerserk; // Trained from the beginning.
float gMaintainThirdLandUnitAmount = 2;
int gFourthLandUnit = cUnitTypeMountainGiant; // Starts getting trained in Heroic.
float gMaintainFourthLandUnitAmount = 1;
int gFifthLandUnit = cUnitTypeHuskarl; // Begins training once the Hill Fort is built.
float gMaintainFifthLandUnitAmount = 4;
int gSixthLandUnit = cUnitTypeEinheri; // Begins training in Classical on harder difficulties.
float gMaintainSixthLandUnitAmount = 1;
float gMaxVillagerCount = 14;
float gAttackStartDelay = 300; // In seconds.
float gAttackWaveInterval = 300; // In seconds.
float gAttackStartSize = 6;
float gAttackMaxSize = 9;

vector gOurTCLocation = vector(230.0, 0.0, 237.0);

// float gClassicalAgeUpTime = 600; // In seconds. (10 minutes)
// float gHeroicAgeUpTime = 720; // In seconds. (12 minutes)

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;

Strategy scenarioAttackWaveStrategy()
{

   // Start enabling rules.
   xsEnableRule("buildTemple");

   int explorePlanID = aiPlanCreate("Berserk Explore", cPlanExplore, -1);
   aiPlanSetPriority(explorePlanID, 99);
   aiPlanAddUnitType(explorePlanID, cUnitTypeBerserk, 1, 1, 1);

   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugStrategy("***Starting Scenario Attack Wave Strategy***");
      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================
      // Certain Parameters are way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gAttackStartSize = 4;
         gAttackMaxSize = 6;
         gAttackWaveInterval = 480;
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;
      // gClassicalAgeUpTime *= gDifficultyModifierAgeUp;
      // gClassicalAgeUpTime += xsGetTime(); // Offset for awake moment.
      // gHeroicAgeUpTime *= gDifficultyModifierAgeUp;
      // gHeroicAgeUpTime += xsGetTime(); // Offset for awake moment.


      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);

      // We don't maintain Hirdmen, Huskarls or Mountain Giants on Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
         data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
         data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      }
      // Only make Einheri on Hard and Titan.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
      }

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);

      // We don't care about train delay on Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gFirstLandUnit);
         aiPlanSetVariableInt(
            planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gFirstLandUnit, cProtoStatTrainPoints) + gTrainDelay
         );
         planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gFourthLandUnit);
         aiPlanSetVariableInt(
            planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gFourthLandUnit, cProtoStatTrainPoints) + gTrainDelay
         );
      }

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      // gAttackWave.addAttackUnitType(gThirdLandUnit); Berserks are for exploring and building.

      // We don't add Hirdmen, Mountain Giants, or Huskarls to the attack waves on Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         gAttackWave.addAttackUnitType(gFirstLandUnit);
         gAttackWave.addAttackUnitType(gFourthLandUnit);
         gAttackWave.addAttackUnitType(gFifthLandUnit);
      }
      // Einheri are only for Hard and Titan.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gAttackWave.addAttackUnitType(gSixthLandUnit);
      }

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticOxCartTraining, true);
      gTimeToFarm = true; // Stay within our base.

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(197.0, 0.0, 209.0); // Below the Temple
      vector targetPoint = vector(55.0, 0.0, 179.0); // Next to P1's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 start below the Town Center.");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(159.0, 0.0, 193.0)); // Block #1.
      kbPathAddWaypoint(pathID1, vector(15.0, 0.0, 163.0)); // Block #2.
      kbPathAddWaypoint(pathID1, vector(37.0, 0.0, 91.0)); // Block #3.
      kbPathAddWaypoint(pathID1, vector(85.0, 0.0, 125.0)); // Block #4.
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path 2 go west.");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(133.0, 0.0, 279.0)); // Block #1.
      kbPathAddWaypoint(pathID2, vector(51.0, 0.0, 271.0)); // Block #2.
      kbPathAddWaypoint(pathID2, vector(49.0, 0.0, 227.0)); // Block #3.
      kbPathAddWaypoint(pathID2, vector(11.0, 0.0, 209.0)); // Block #4.
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

   // SPLIT AMOUNTS
      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 2; // Hirdmen
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 2; // Raiding Cavalry

      gDefendPlan1 = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 30.0, vector(207.0, 0.0, 221.0), 20);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 40.0);
      // Exclude Berserks from the Land Defend Plan, otherwise they won't build.
      aiPlanAddUnitType(gDefendPlan1, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount);
      aiPlanAddUnitType(gDefendPlan1, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount);
      aiPlanAddUnitType(gDefendPlan1, gFourthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gDefendPlan1, gFifthLandUnit, 0, 0, 200);

      gDefendPlan2 = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 30.0, vector(181.0, 0.0, 259.0), 20);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 40.0);
      // Exclude Berserks from the Land Defend Plan, otherwise they won't build.
      aiPlanAddUnitType(gDefendPlan2, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount);
      aiPlanAddUnitType(gDefendPlan2, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount);
      aiPlanAddUnitType(gDefendPlan2, gSixthLandUnit, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      int age = kbPlayerGetAge(cMyID);
      static bool done = false;
      static bool Reached_Classical = false;
      static bool Reached_Heroic = false;

      // Must have a Temple to go to Classical.
      if (age == cAge1 && kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateAlive) == 1)
      {
         researchSimpleTech(cTechClassicalAgeHeimdall, cUnitTypeTownCenter, -1, 75);
      }
      // We're in Classical, now we can build a Longhouse, Great Hall, and Armory.
      if (age >= cAge2 && Reached_Classical == false)
      {
         // We don't build the Longhouse on Easy.
         // We also don't research any technologies on Easy.
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("buildLonghouse");
            xsEnableRule("researchMediumInfantry");
            xsEnableRule("researchMediumCavalry");
            xsEnableRule("researchCrenellations");
            xsEnableRule("researchMasons");
            xsEnableRule("researchCopperArmoryTechs");
         }
         // Only research Safeguard on Hard and Titan.
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchSafeguard");
         }
         // Only get Gjallarhorn on Titan.
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchGjallarhorn");
         }
         xsEnableRule("buildArmory");
         xsEnableRule("buildGreatHall");
         xsEnableRuleGroup("ClassicalEcoTechs");

         Reached_Classical = true;
      }

      // Time to go to Heroic.
      if (age == cAge2 && kbUnitCount(cUnitTypeArmory, cMyID, cUnitStateAlive) == 1)
      {
         researchSimpleTech(cTechHeroicAgeNjord, cUnitTypeTownCenter, -1, 75);
      }
      // We're in Heroic, now we can build a Hill Fort.
      if (age >= cAge3 && Reached_Heroic == false)
      {
         xsEnableRule("buildHillFort");
         xsEnableRule("researchBoilingOil");
         xsEnableRule("researchLevyLonghouseSoldiers");
         xsEnableRule("researchLevyGreatHallSoldiers");
         xsEnableRule("researchLevyHillFortSoldiers");
         xsEnableRuleGroup("HeroicEcoTechs");

         // Hard and Titan Techs
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchBronzeWeapons");
            xsEnableRule("researchArchitects");
            xsEnableRule("researchFortifiedTownCenter");
         }

         // Don't research Heroic Age techs except on Titan.
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchHeavyInfantry");
            xsEnableRule("researchHeavyCavalry");
            xsEnableRule("researchBronzeArmorShields");
         } 
         Reached_Heroic = true;
      }   
      
      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott28StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(246.00, 0.00, 254.00), 59);

   setOverrideStrategy(fott28StrategySetup);

   gOverrideFarmCount = 12; // Don't overdo the Farms.
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

// * * * * * * * * * * * * * * * * * * * * * * * * //
//                 BUILDING RULES                  //
// * * * * * * * * * * * * * * * * * * * * * * * * //

void buildBuilding(int type = cUnitTypeManor, vector location = cInvalidVector)
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

// Try to build a Temple to the south of the Town Center.
rule buildTemple
inactive
minInterval 10
{
   vector location = vector(209.0, 0.00, 208.0); // Teal area waypoint south of the teal TC.
   if (buildingGetNumberAliveAndPlanned(cUnitTypeTemple) < 1)
   {
      buildBuilding(cUnitTypeTemple, location);
   }
}

rule buildLonghouse
inactive
minInterval 10
{
   vector location = vector(155.0, 0.00, 283.0); // Teal area waypoint at the west end of the dirt-road path.
   if (buildingGetNumberAliveAndPlanned(cUnitTypeLonghouse) < 1)
   {
      buildBuilding(cUnitTypeLonghouse, location);
   }
}

// Try to build a Great Hall in the middle of the dirt-road path.
rule buildGreatHall
inactive
minInterval 10
{
   vector location = vector(166.0, 0.00, 250.0); // Teal area waypoint in the middle of the dirt-road path.
   if (buildingGetNumberAliveAndPlanned(cUnitTypeGreatHall) < 1)
   {
      buildBuilding(cUnitTypeGreatHall, location);
   }
}

rule buildArmory
inactive
minInterval 10
{
   vector location = vector(228.0, 0.00, 287.0); // Teal area waypoint in the northern edge of the map.
   if (buildingGetNumberAliveAndPlanned(cUnitTypeArmory) < 1)
   {
      buildBuilding(cUnitTypeArmory, location);
   }
}

// Try to build a Hill Fort near the deer.
rule buildHillFort
inactive
minInterval 10
{
   vector location = vector(174.0, 0.00, 205.0); // Teal area waypoint by the deer.
   if (buildingGetNumberAliveAndPlanned(cUnitTypeHillFort) < 1)
   {
      buildBuilding(cUnitTypeHillFort, location);
   }
}

// * * * * * * * * * * * * * * * * * * * * * * * * //
//                   TECH RULES                    //
// * * * * * * * * * * * * * * * * * * * * * * * * //


// CLASSICAL AGE TECHS

rule researchCopperArmoryTechs
inactive
minInterval 90
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if ((kbTechGetStatus(cTechCopperWeapons) == cTechStatusActive) &&
       (kbTechGetStatus(cTechCopperArmor) == cTechStatusActive) &&
       (kbTechGetStatus(cTechCopperShields) == cTechStatusActive))
   {
      xsDisableRule("researchCopperArmoryTechs");
      return;
   }
   if (kbTechGetStatus(cTechCopperWeapons) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Copper Weapons research plan.");
      researchSimpleTech(cTechCopperWeapons, cUnitTypeArmory, -1, 60);
      return;
   }
   if (kbTechGetStatus(cTechCopperArmor) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Copper Armor research plan.");
      researchSimpleTech(cTechCopperArmor, cUnitTypeArmory, -1, 60);
      return;
   }
   if (kbTechGetStatus(cTechCopperShields) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Copper Shields research plan.");
      researchSimpleTech(cTechCopperShields, cUnitTypeArmory, -1, 60);
      return;
   }
}

rule researchMediumCavalry
inactive
minInterval 180
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechMediumCavalry) == cTechStatusActive)
   {
      xsDisableRule("researchMediumCavalry");
      return;
   }
   else if (kbTechGetStatus(cTechMediumCavalry) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Medium Cavalry research plan.");
      researchSimpleTech(cTechMediumCavalry, cUnitTypeGreatHall, -1, 60);
      return;
   }
}

rule researchMediumInfantry
active
minInterval 120
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechMediumInfantry) == cTechStatusActive)
   {
      xsDisableRule("researchMediumInfantry");
      return;
   }
   else if (kbTechGetStatus(cTechMediumInfantry) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Medium Infantry research plan.");
      researchSimpleTech(cTechMediumInfantry, cUnitTypeLonghouse, -1, 60);
      return;
   }
}

// HEROIC AGE TECHS

rule researchBronzeWeapons
inactive
minInterval 180
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

rule researchBronzeArmorShields
inactive
minInterval 300
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if ((kbTechGetStatus(cTechBronzeArmor) == cTechStatusActive) &&
       (kbTechGetStatus(cTechBronzeShields) == cTechStatusActive))
   {
      xsDisableRule("researchBronzeArmorShields");
      return;
   }
   if (kbTechGetStatus(cTechBronzeArmor) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Bronze Armor research plan.");
      researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 60);
      return;
   }
   if (kbTechGetStatus(cTechBronzeShields) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Bronze Shields research plan.");
      researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 60);
      return;
   }
}

rule researchHeavyInfantry
inactive
minInterval 180
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechHeavyInfantry) == cTechStatusActive)
   {
      xsDisableRule("researchHeavyInfantry");
      return;
   }
   else if (kbTechGetStatus(cTechHeavyInfantry) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Heavy Infantry research plan.");
      researchSimpleTech(cTechHeavyInfantry, cUnitTypeLonghouse, -1, 60);
      return;
   }
}

rule researchHeavyCavalry
inactive
minInterval 240
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechHeavyCavalry) == cTechStatusActive)
   {
      xsDisableRule("researchHeavyCavalry");
      return;
   }
   else if (kbTechGetStatus(cTechHeavyCavalry) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Heavy Cavalry research plan.");
      researchSimpleTech(cTechHeavyCavalry, cUnitTypeGreatHall, -1, 60);
      return;
   }
}


// BUILDING TECHS
   // *** CLASSICAL AGE ***
      // MODERATE AND UP
         // Research Masons 340 seconds into the game; not Easy.
         rule researchMasons
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 340)
               {
                  // Cease if we have it. Otherwise, research it.
                  if (kbTechGetStatus(cTechMasons) == cTechStatusActive)
                  {
                     xsDisableRule("researchMasons");
                     return;
                  }
                  else if (kbTechGetStatus(cTechMasons) == cTechStatusObtainable)
                  {
                     debugAttackWave("Starting Masons research plan.");
                     researchSimpleTech(cTechMasons, cUnitTypeTownCenter, -1, 60);
                     return;
                  }
               }
         }
         // Research Crenellations 410 seconds into the game; not Easy.
         rule researchCrenellations
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 410)
               {
                  researchSimpleTech(cTechCrenellations, cUnitTypeSentryTower, -1, 60);
                  xsDisableRule("researchCrenellations"); // Disable self.
                  return;
               }
         }

      // HARD AND UP
         // Research Safeguard 300 seconds into the game; Hard and Titan only.
         rule researchSafeguard
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 300)
               {
                  researchSimpleTech(cTechSafeguard, cUnitTypeTemple, -1, 60);
                  xsDisableRule("researchSafeguard"); // Disable self.
                  return;
               }
         }

      // TITAN ONLY
         // Research Gjallarhorn 480 seconds into the game; Titan only.
         rule researchGjallarhorn
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 480)
               {
                  researchSimpleTech(cTechGjallarhorn, cUnitTypeTemple, -1, 60);
                  xsDisableRule("researchGjallarhorn"); // Disable self.
                  return;
               }
         }

   // *** HEROIC AGE ***
      // MODERATE AND UP
         // Research Boiling Oil 640 seconds into the game; not Easy.
         rule researchBoilingOil
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 640)
               {
                  // Cease if we have it. Otherwise, research it.
                  if (kbTechGetStatus(cTechBoilingOil) == cTechStatusActive)
                  {
                     xsDisableRule("researchBoilingOil");
                     return;
                  }
                  else if (kbTechGetStatus(cTechBoilingOil) == cTechStatusObtainable)
                  {
                     debugAttackWave("Starting BoilingOil research plan.");
                     researchSimpleTech(cTechBoilingOil, cUnitTypeSentryTower, -1, 60);
                     return;
                  }
               }
         }
         // Research Levy Longhouse Soldiers 300 seconds after waking up; doesn't occur on Easy.
         rule researchLevyLonghouseSoldiers
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 350)
            {
               researchSimpleTech(cTechLevyLonghouseSoldiers, cUnitTypeLonghouse, -1, 60);
               xsDisableRule("researchLevyLonghouseSoldiers"); // Disable self.
               return;
            }
         }
         // Research Levy Great Hall Soldiers 400 seconds after waking up; doesn't occur on Easy.
         rule researchLevyGreatHallSoldiers
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 480)
            {
               researchSimpleTech(cTechLevyGreatHallSoldiers, cUnitTypeGreatHall, -1, 60);
               xsDisableRule("researchLevyGreatHallSoldiers"); // Disable self.
               return;
            }
         }
         // Research Levy Hill Fort Soldiers 500 seconds after waking up; doesn't occur on Easy.
         rule researchLevyHillFortSoldiers
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 720)
            {
               researchSimpleTech(cTechLevyHillFortSoldiers, cUnitTypeHillFort, -1, 60);
               xsDisableRule("researchLevyHillFortSoldiers"); // Disable self.
               return;
            }
         }


      // HARD AND TITAN ONLY
         // Architects
         rule researchArchitects
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
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
         // Fortified Town Center
         rule researchFortifiedTownCenter
         inactive
         minInterval 600
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechFortifiedTownCenter) == cTechStatusActive)
            {
               xsDisableRule("researchFortifiedTownCenter");
               return;
            }
            else if (kbTechGetStatus(cTechFortifiedTownCenter) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Fortified TownCenter research plan.");
               researchSimpleTech(cTechFortifiedTownCenter, cUnitTypeTownCenter, -1, 60);
               return;
            }
         }
      // TITAN ONLY
         // Research Jotuns 1080 seconds into the game; Titan only.
         rule researchJotuns
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 1080)
               {
                  researchSimpleTech(cTechJotuns, cUnitTypeTemple, -1, 60);
                  xsDisableRule("researchJotuns"); // Disable self.
                  return;
               }
         }

// ECO TECHS

   // *** CLASSICAL AGE ***
      // ALL DIFFICULTIES:
         // Research Plow; occurs on all difficulties.
         rule researchPlow
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         group ClassicalEcoTechs
         {
            researchSimpleTech(cTechPlow, cUnitTypeOxCart, -1, 60);
            xsDisableRule("researchPlow"); // Disable self.
         }
         // Research Pickaxe; occurs on all difficulties.
         rule researchPickaxe
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         group ClassicalEcoTechs
         {
            researchSimpleTech(cTechPickaxe, cUnitTypeOxCart, -1, 60);
            xsDisableRule("researchPickaxe"); // Disable self.
         }
         // Research Hand Axe; occurs on all difficulties.
         rule researchHandAxe
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         group ClassicalEcoTechs
         {
            researchSimpleTech(cTechHandAxe, cUnitTypeOxCart, -1, 60);
            xsDisableRule("researchHandAxe"); // Disable self.
         }

   // *** HEROIC AGE ***
      // ALL DIFFICULTIES:
         // Research Irrigation; occurs on all difficulties.
         rule researchIrrigation
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         group HeroicEcoTechs
         {
            if (kbTechGetStatus(cTechPlow) == cTechStatusActive)
               {
                  researchSimpleTech(cTechIrrigation, cUnitTypeOxCart, -1, 60);
                  xsDisableRule("researchIrrigation"); // Disable self.
               }
         }
         // Research Shaft Mine; occurs on all difficulties.
         rule researchShaftMine
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         group HeroicEcoTechs
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
               researchSimpleTech(cTechShaftMine, cUnitTypeOxCart, -1, 60);
               return;
            }
         }
         // Research Bow Saw; occurs on all difficulties.
         rule researchBowSaw
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         group HeroicEcoTechs
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
               researchSimpleTech(cTechBowSaw, cUnitTypeOxCart, -1, 60);
               return;
            }
         }