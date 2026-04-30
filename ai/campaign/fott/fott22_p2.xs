//==============================================================================
/* fott22_p2.xs
   
   Instead of entering specific military building types I entered "logicaltypemilitarybuilding" for the infantry techs.

   Instead of Bronze Techs AI is researching the Copper Technologies. (In order to research Bronze AI needs to research copper techs first, which is not done)

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
int gFirstLandUnit = cUnitTypeBerserk; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 5;
int gSecondLandUnit = cUnitTypeRaidingCavalry; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 4;
int gThirdLandUnit = cUnitTypeThrowingAxeman; // Starts training after 480 seconds (Not Easy).
float gMaintainThirdLandUnitAmount = 4;
int gFourthLandUnit = cUnitTypeHersir; // Starts training after 720 seconds (Hard and Titan only).
float gMaintainFourthLandUnitAmount = 2;
int gFifthLandUnit = cUnitTypeHuskarl; // Starts training after 1080 seconds.
float gMaintainFifthLandUnitAmount = 3;

float gMaxVillagerCount = 15;
vector gOurTCLocation = vector(457.0, 0.0, 159.0);

float gAttackStartDelay = cWaitWithAttacking; // Updates to 300 once they build a Hill Fort.
float gAttackWaveInterval = 480; // In seconds.

float gAttackStartSize = 5;
float gAttackMaxSize = 7;

int gHeroicAgeUpTime = 30; // In seconds.
int gMythicAgeUpTime = 1200; // In seconds.

int gHeroicArrival = 999999;
int gMythicArrival = 999999;

Strategy scenarioAttackWaveStrategy()
{
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

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;

      // Certain Parameters are much more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gAttackStartSize = 3;
         gAttackMaxSize = 5;
      }

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      // Throwing Axemen, Hersirs, and Huskarls come later.

      // Train delay, how long the AI waits before queuing up another unit.
      int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gFirstLandUnit);
      aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gFirstLandUnit, cProtoStatTrainPoints) + gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      gTimeToFarm = true;

      gAttackWave.setPlayerToAttack(1); // Attack player 1!
      
      // Where does our attack start and end.
      vector startPoint = vector(445.0, 0.0, 185.0); // Left of the TC.
      vector targetPoint = vector(251.0, 0.0, 225.0); // Right of Arkantos' TC

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 counterclockwise");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(427.0, 0.0, 237.0)); // 1st Waypoint
      kbPathAddWaypoint(pathID1, vector(209.0, 0.0, 277.0)); // 2nd Waypoint
      kbPathAddWaypoint(pathID1, vector(179.0, 0.0, 123.0)); // 3rd Waypoint
      kbPathAddWaypoint(pathID1, vector(351.49, 0.0, 105.0)); // 4th Waypoint
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path 2 clockwise");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(351.49, 0.0, 105.0)); // 1st Waypoint
      kbPathAddWaypoint(pathID2, vector(179.0, 0.0, 123.0)); // 2nd Waypoint
      kbPathAddWaypoint(pathID2, vector(209.0, 0.0, 277.0)); // 3rd Waypoint
      kbPathAddWaypoint(pathID2, vector(341.49, 0.0, 255.0)); // 4th Waypoint
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });
       
// Defend Points (Divided to ensure a more natural distribution of guards)
      int gTCDefendPlan = -1;
      int gHillFortDefendPlan = -1;

   // SPLIT AMOUNTS
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 2; // Raiding Cavalry
      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2; // Throwing Axemen
      int fourthLandUnitSplitAmount = gMaintainFourthLandUnitAmount / 2; // Hersirs

   // DEFINE THE PLANS
      // Town Center
      gTCDefendPlan = createDefendPlan("Town Center Defense Plan", kbBaseGetMainID(cMyID), 25, vector(445.0, 0.0, 171.0), 20);
      aiPlanSetVariableFloat(gTCDefendPlan, cDefendPlanEngageRange, 0, 30);

      aiPlanAddUnitType(gTCDefendPlan, gFirstLandUnit, 0, 0, 200); // Berserks
      aiPlanAddUnitType(gTCDefendPlan, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Raiding Cavalry
      aiPlanAddUnitType(gTCDefendPlan, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Throwing Axemen
      aiPlanAddUnitType(gTCDefendPlan, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount); // Hersirs

      // Hill Fort
      gHillFortDefendPlan = createDefendPlan("Defense Plan 2", kbBaseGetMainID(cMyID), 10, vector(513.0, 0.0, 141.0), 20);
      aiPlanSetVariableFloat(gHillFortDefendPlan, cDefendPlanEngageRange, 0, 30);

      aiPlanAddUnitType(gHillFortDefendPlan, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Raiding Cavalry
      aiPlanAddUnitType(gHillFortDefendPlan, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Throwing Axemen
      aiPlanAddUnitType(gHillFortDefendPlan, gFourthLandUnit, 0, 0, fourthLandUnitSplitAmount); // Hersirs
      aiPlanAddUnitType(gHillFortDefendPlan, gFifthLandUnit, 0, 0, 200); // Huskarls

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      int time = xsGetTime();
      int age = kbPlayerGetAge(cMyID);

      // Add Throwing Axemen at 600 seconds; doesn't occur on Easy.
      static bool axemenAdded = false;
      if (axemenAdded == false && cDifficultyCurrent >= cDifficultyModerate)
      {
         if (time >= 600)
         {
            data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
            data.setTrainDelay(gThirdLandUnit, gTrainDelay);
            gAttackWave.addAttackUnitType(gThirdLandUnit);
            if (cDifficultyCurrent == cDifficultyHard)
            {
               gAttackMaxSize *= 1.10; // Attack size increases by +10%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);
            }
            else if (cDifficultyCurrent == cDifficultyTitan)
            {
               gAttackMaxSize *= 1.20; // Attack size increases by +20%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);
            }
            axemenAdded = true;
         }
      }

      // Add Hersirs at 720 seconds; Hard and Titan only.
      static bool hersirsAdded = false;
      if (hersirsAdded == false && cDifficultyCurrent >= cDifficultyHard)
      {
         if (time >= 900)
         {
            data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
            data.setTrainDelay(gFourthLandUnit, gTrainDelay);
            gAttackWave.addAttackUnitType(gFourthLandUnit);
            hersirsAdded = true;
         }
      }

      // Add Huskarls at 1080 seconds.
      static bool huskarlsAdded = false;
      if (huskarlsAdded == false && kbUnitCount(cUnitTypeHillFort, cMyID, cUnitStateAlive) >= 1)
      {
         if (time >= 1080)
         {
            // We add the Huskarls only if we have a Hill Fort
            data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
            data.setTrainDelay(gFifthLandUnit, gTrainDelay);
            gAttackWave.addAttackUnitType(gFifthLandUnit);
            // Accelerate the attacks on Hard and Titan. The player should have gotten past the initial disorientation by now.
            if (cDifficultyCurrent >= cDifficultyHard)
            {
               gAttackWaveInterval *= 0.75; // Attacks are dispatched more frequently.
               gAttackWave.setAttackInterval(gAttackWaveInterval);
            }

            // Train more Villagers to support the larger army.
            gMaxVillagerCount *= 1.20; // Train +20% more Villagers.
            gOverrideMaxVillagerPop = gMaxVillagerCount;

            huskarlsAdded = true;
         }
      }

      static bool needResearchHeroic = true;

      static bool reachedHeroic = false;
      static bool reachedMythic = false;

      if (needResearchHeroic == true && age == cAge2 && time >= gHeroicAgeUpTime)
      {
         if (researchSimpleTech(cTechHeroicAgeNjord, cUnitTypeTownCenter, -1, 60) == true)
         {
            debugAttackWave("Starting Heroic Age research plan.");
            needResearchHeroic = false;
         }
      }
      static bool needResearchMythic = true;
      if (needResearchMythic == true && age == cAge3 && time >= gMythicAgeUpTime)
      {
         if (researchSimpleTech(cTechMythicAgeTyr, cUnitTypeTownCenter, -1, 60) == true)
         {
            debugAttackWave("Starting Mythic Age research plan.");
            needResearchMythic = false;
         }
      }

      static bool done = false;
      if (done == false && age >= cAge3)
      {
         xsEnableRule("buildHillFort");
         done = true;
      }

      // * * * TECH RULES * * * //

      // CLASSICAL AGE //
      static bool classical_techs = false;
      if (age >= cAge2 && classical_techs == false)
      {
         // Techs for all difficulties:
         xsEnableRule("researchCopperWeapons");
         xsEnableRule("researchCopperArmor");
         xsEnableRule("researchCopperShields");
         xsEnableRule("researchMediumInfantry");
         xsEnableRule("researchMediumCavalry");

         // Tech Rules for Moderate and Up:
         // Tech Rules for Hard and Titan:
         // Tech Rules for Titan only:

         classical_techs = true;
      }

      // HEROIC AGE //
      if (reachedHeroic == false && kbPlayerGetAge(cMyID) == cAge3)
      {
         // Tech Rules for All Difficulties:
         xsEnableRule("researchIrrigation");
         xsEnableRule("researchShaftMine");
         xsEnableRule("researchBowSaw");

         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchBronzeArmor");
            xsEnableRule("researchBronzeShields");
            xsEnableRule("researchHeavyInfantry");
            xsEnableRule("researchHeavyCavalry");
            xsEnableRule("researchLevyLonghouseSoldiers");
            xsEnableRule("researchLevyGreatHallSoldiers");
            xsEnableRule("researchLevyHillFortSoldiers");
            xsEnableRule("researchMasons");
            xsEnableRule("researchCrenellations");
            xsEnableRule("researchBallistics");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchBronzeWeapons");
            xsEnableRule("researchSafeguard");
            xsEnableRule("researchArchitects");
            xsEnableRule("researchFortifiedTownCenter");
            xsEnableRule("researchBoilingOil");
         }

         // Tech Rules for Titan only:

         gHeroicArrival = xsGetTime();
         // Change the boolean back to true so the rules aren't enabled multiple times.
         reachedHeroic = true;
      }

      // MYTHIC AGE //
      if (reachedMythic == false && kbPlayerGetAge(cMyID) == cAge4)
      {
         // Tech Rules for All Difficulties:
         xsEnableRule("researchFloodControl");
         xsEnableRule("researchQuarry");
         xsEnableRule("researchCarpenters");

         // Tech Rules for Moderate and Up:
         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchChampionInfantry");
            xsEnableRule("researchChampionCavalry");
            xsEnableRule("researchConscriptLonghouseSoldiers");
         }

         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchBerserkergang");
            xsEnableRule("researchConscriptGreatHallSoldiers");
            xsEnableRule("researchConscriptHillFortSoldiers");
         }
         gMythicArrival = xsGetTime();
         // Change the boolean back to true so the rules aren't enabled multiple times.
         reachedMythic = true;
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott22StrategySetup()
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

   // gOverrideFarmCount = 12;
   gOverrideMaxVillagerPop = gMaxVillagerCount;

   gMainGatherBase = createOverrideGatherBase(vector(457.00, 0.00, 159.00), 35);
   createOverrideGatherBase(vector(524.00, 0.00, 126.00), 35);

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

   setOverrideStrategy(fott22StrategySetup);
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

// Try to build a Hill Fort to the left of the wild Boars.
rule buildHillFort
inactive
minInterval 10
{
   int buildPlanID = aiPlanCreate("Hill Fort Build Plan", cPlanBuild);
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID));
   vector buildPosition = vector(522.62, 1.10, 154.93); // Red cinematic start block to the left of the wild Boars.
   kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeHillFort);
   kbBuildingPlacementSetCenterPosition(bpID, buildPosition, 10.0);
   kbBuildingPlacementSetStepSize(bpID, 2.0);
   kbBuildingPlacementSetBufferSpace(bpID, 0.0);
   kbBuildingPlacementAddPositionInfluence(bpID, buildPosition, 100.0, 50.0, cFalloffLinear);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
   aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, cUnitTypeHillFort);
   aiPlanAddUnitType(buildPlanID, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 2, 2, 2);
   aiPlanSetPriority(buildPlanID, 99);
   debugAttackWave("Building that Hill Fort now.");
   xsDisableRule("buildHillFort");
}

rule updateParameters
inactive
minInterval 5
{
   // Define first attack.
   gAttackStartDelay = 300;
   gAttackStartDelay *= gDifficultyModifierFirstAttack;
   gAttackStartDelay += xsGetTime();
   gAttackWave.setAttackStartTime(gAttackStartDelay);
   gAttackWave.update();

   debugAttackWave("It should take longer for the attacks to begin now.");
   debugAttackWave("Attack Start Delay should be " + gAttackStartDelay + ".");
   xsDisableRule("updateParameters");
}

// TECH RULES //
   // *** CLASSICAL AGE ***
      // ALL DIFFICULTIES:
         // Research Copper Weapons 1120 seconds after waking up; occurs on all difficulties.
         rule researchCopperWeapons
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (cDifficultyCurrent <= cDifficultyModerate && xsGetTime() >= 1120)
               {
                  xsSetRuleMinIntervalSelf(10);
                  // Cease if we have it. Otherwise, research it.
                  if (kbTechGetStatus(cTechCopperWeapons) == cTechStatusActive)
                  {
                     xsDisableRule("researchCopperWeapons");
                     return;
                  }
                  else if (kbTechGetStatus(cTechCopperWeapons) == cTechStatusObtainable)
                  {
                     debugAttackWave("Starting Copper Weapons research plans.");
                     researchSimpleTech(cTechCopperWeapons, cUnitTypeArmory, -1, 60);
                  }
               }
            // Upgrade happens sooner on harder levels.
            else if (cDifficultyCurrent >= cDifficultyHard && xsGetTime() >= 120)
               {
                  // Cease if we have it. Otherwise, research it.
                  if (kbTechGetStatus(cTechCopperWeapons) == cTechStatusActive)
                  {
                     xsDisableRule("researchCopperWeapons");
                     return;
                  }
                  else if (kbTechGetStatus(cTechCopperWeapons) == cTechStatusObtainable)
                  {
                     debugAttackWave("Starting Copper Weapons research plans.");
                     researchSimpleTech(cTechCopperWeapons, cUnitTypeArmory, -1, 60);
                  }
               }
         }
         // Research Copper Armor 1280 seconds after waking up; occurs on all difficulties.
         rule researchCopperArmor
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (cDifficultyCurrent == cDifficultyEasy && xsGetTime() >= 1280)
               {
                  // Cease if we have it. Otherwise, research it.
                  if (kbTechGetStatus(cTechCopperArmor) == cTechStatusActive)
                  {
                     xsDisableRule("researchCopperArmor");
                     return;
                  }
                  else if (kbTechGetStatus(cTechCopperArmor) == cTechStatusObtainable)
                  {
                     debugAttackWave("Starting Copper Armor research plans.");
                     researchSimpleTech(cTechCopperArmor, cUnitTypeArmory, -1, 60);
                  }
               }
            // Upgrade happens sooner on harder levels.
            else if (cDifficultyCurrent >= cDifficultyModerate && xsGetTime() >= 180)
               {
                  // Cease if we have it. Otherwise, research it.
                  if (kbTechGetStatus(cTechCopperArmor) == cTechStatusActive)
                  {
                     xsDisableRule("researchCopperArmor");
                     return;
                  }
                  else if (kbTechGetStatus(cTechCopperArmor) == cTechStatusObtainable)
                  {
                     debugAttackWave("Starting Copper Armor research plans.");
                     researchSimpleTech(cTechCopperArmor, cUnitTypeArmory, -1, 60);
                  }
               }
         }
         // Research Copper Shields 1400 seconds after waking up; occurs on all difficulties.
         rule researchCopperShields
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (cDifficultyCurrent == cDifficultyEasy && xsGetTime() >= 1400)
               {
                  // Cease if we have it. Otherwise, research it.
                  if (kbTechGetStatus(cTechCopperShields) == cTechStatusActive)
                  {
                     xsDisableRule("researchCopperShields");
                     return;
                  }
                  else if (kbTechGetStatus(cTechCopperShields) == cTechStatusObtainable)
                  {
                     debugAttackWave("Starting Copper Shields research plan.");
                     researchSimpleTech(cTechCopperShields, cUnitTypeArmory, -1, 60);
                     return;
                  }
               }
            // Upgrade happens sooner on harder levels.
            else if (cDifficultyCurrent >= cDifficultyModerate && xsGetTime() >= 300)
               {
                  // Cease if we have it. Otherwise, research it.
                  if (kbTechGetStatus(cTechCopperShields) == cTechStatusActive)
                  {
                     xsDisableRule("researchCopperShields");
                     return;
                  }
                  else if (kbTechGetStatus(cTechCopperShields) == cTechStatusObtainable)
                  {
                     debugAttackWave("Starting Copper Shields research plan.");
                     researchSimpleTech(cTechCopperShields, cUnitTypeArmory, -1, 60);
                     return;
                  }
               }
         }
         // Research Medium Infantry 1140 seconds after waking up; occurs on all difficulties.
         rule researchMediumInfantry
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (cDifficultyCurrent == cDifficultyEasy && xsGetTime() >= 1140)
               {
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
            // Upgrade happens sooner on harder levels.
            else if (cDifficultyCurrent >= cDifficultyModerate && xsGetTime() >= 240)
               {
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
                  return;
               }
         }
         // Research Medium Cavalry 1200 seconds after waking up; occurs on all difficulties.
         rule researchMediumCavalry
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (cDifficultyCurrent == cDifficultyEasy && xsGetTime() >= 1200)
               {
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
            // Upgrade happens sooner on harder levels.
            else if (cDifficultyCurrent >= cDifficultyModerate && xsGetTime() >= 300)
               {
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
         }

   // *** HEROIC AGE ***
      // ALL DIFFICULTIES:
         // Research Irrigation 180 seconds after waking up; occurs on all difficulties.
         rule researchIrrigation
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 180 + gHeroicArrival && kbTechGetStatus(cTechPlow) == cTechStatusActive)
               {
                  researchSimpleTech(cTechIrrigation, cUnitTypeOxCart, -1, 60);
                  xsDisableRule("researchIrrigation"); // Disable self.
                  return;
               }
         }
         // Research Shaft Mine 180 seconds after waking up; occurs on all difficulties.
         rule researchShaftMine
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 180 + gHeroicArrival)
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
         }
         // Research Bow Saw 180 seconds after waking up; occurs on all difficulties.
         rule researchBowSaw
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 180 + gHeroicArrival)
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
         }

      // MODERATE AND UP:
         // Research Heavy Infantry 1240 seconds after reaching Heroic; doesn't occur on Easy.
         rule researchHeavyInfantry
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (cDifficultyCurrent == cDifficultyModerate)
            {
               if (xsGetTime() >= 1240 + gHeroicArrival)
               {
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
            }
            // Upgrade happens sooner on harder levels.
            else if (cDifficultyCurrent >= cDifficultyHard)
            {
               if (xsGetTime() >= 860 + gHeroicArrival)
               {
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
            }
         }
         // Research Heavy Cavalry 1310 seconds after reaching Heroic; doesn't occur on Easy.
         rule researchHeavyCavalry
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (cDifficultyCurrent == cDifficultyModerate)
            {
               if (xsGetTime() >= 1310 + gHeroicArrival)
               {
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
            }
            // Upgrade happens sooner on harder levels.
            else if (cDifficultyCurrent >= cDifficultyHard)
            {
               if (xsGetTime() >= 900 + gHeroicArrival)
               {
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
            }
         }
         // Research Bronze Armor 1200 seconds after reaching Heroic; doesn't occur on Easy.
         rule researchBronzeArmor
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (cDifficultyCurrent == cDifficultyModerate)
            {
               if (xsGetTime() >= 1200 + gHeroicArrival)
               {
                  // Cease if we have it. Otherwise, research it.
                  if (kbTechGetStatus(cTechBronzeArmor) == cTechStatusActive)
                  {
                     xsDisableRule("researchBronzeArmor");
                     return;
                  }
                  else if (kbTechGetStatus(cTechBronzeArmor) == cTechStatusObtainable)
                  {
                     debugAttackWave("Starting Bronze Armor research plan.");
                     researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 60);
                     return;
                  }
               }
            }
            // Upgrade happens sooner on harder levels.
            else if (cDifficultyCurrent >= cDifficultyHard)
            {
               if (xsGetTime() >= 820 + gHeroicArrival)
               {
                  // Cease if we have it. Otherwise, research it.
                  if (kbTechGetStatus(cTechBronzeArmor) == cTechStatusActive)
                  {
                     xsDisableRule("researchBronzeArmor");
                     return;
                  }
                  else if (kbTechGetStatus(cTechBronzeArmor) == cTechStatusObtainable)
                  {
                     debugAttackWave("Starting Bronze Armor research plan.");
                     researchSimpleTech(cTechBronzeArmor, cUnitTypeArmory, -1, 60);
                     return;
                  }
               }
            }
         }
         // Research Bronze Shields 1500 seconds after reaching Heroic; doesn't occur on Easy.
         rule researchBronzeShields
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (cDifficultyCurrent == cDifficultyModerate)
            {
               if (xsGetTime() >= 1500 + gHeroicArrival)
               {
                  // Cease if we have it. Otherwise, research it.
                  if (kbTechGetStatus(cTechBronzeShields) == cTechStatusActive)
                  {
                     xsDisableRule("researchBronzeShields");
                     return;
                  }
                  else if (kbTechGetStatus(cTechBronzeShields) == cTechStatusObtainable)
                  {
                     debugAttackWave("Starting Bronze Shields research plan.");
                     researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 60);
                     return;
                  }
               }
            }
            // Upgrade happens sooner on harder levels.
            else if (cDifficultyCurrent >= cDifficultyHard)
            {
               if (xsGetTime() >= 1010 + gHeroicArrival)
               {
                  // Cease if we have it. Otherwise, research it.
                  if (kbTechGetStatus(cTechBronzeShields) == cTechStatusActive)
                  {
                     xsDisableRule("researchBronzeShields");
                     return;
                  }
                  else if (kbTechGetStatus(cTechBronzeShields) == cTechStatusObtainable)
                  {
                     debugAttackWave("Starting Bronze Shields research plan.");
                     researchSimpleTech(cTechBronzeShields, cUnitTypeArmory, -1, 60);
                     return;
                  }
               }
            }
         }
         // Research Levy Longhouse Soldiers 350 seconds after waking up; doesn't occur on Easy.
         rule researchLevyLonghouseSoldiers
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 350 + gHeroicArrival)
            {
               researchSimpleTech(cTechLevyLonghouseSoldiers, cUnitTypeLonghouse, -1, 60);
               xsDisableRule("researchLevyLonghouseSoldiers"); // Disable self.
               return;
            }
         }
         // Research Levy Great Hall Soldiers 480 seconds after waking up; doesn't occur on Easy.
         rule researchLevyGreatHallSoldiers
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 480 + gHeroicArrival)
            {
               researchSimpleTech(cTechLevyGreatHallSoldiers, cUnitTypeGreatHall, -1, 60);
               xsDisableRule("researchLevyGreatHallSoldiers"); // Disable self.
               return;
            }
         }
         // Research Levy Hill Fort Soldiers 720 seconds after waking up; doesn't occur on Easy.
         rule researchLevyHillFortSoldiers
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 720 + gHeroicArrival)
            {
               researchSimpleTech(cTechLevyHillFortSoldiers, cUnitTypeHillFort, -1, 60);
               xsDisableRule("researchLevyHillFortSoldiers"); // Disable self.
               return;
            }
         }
         // Research Masons 400 seconds after waking up; doesn't occur on Easy.
         rule researchMasons
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 480)
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
         // Research Crenellations 600 seconds after waking up; doesn't occur on Easy.
         rule researchCrenellations
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 600)
            {
               researchSimpleTech(cTechCrenellations, cUnitTypeSentryTower, -1, 60);
               xsDisableRule("researchCrenellations"); // Disable self.
               return;
            }
         }
         // Research Ballistics 780 seconds after waking up; doesn't occur on Easy.
         rule researchBallistics
         inactive
         minInterval 780
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechBallistics) == cTechStatusActive)
            {
               xsDisableRule("researchBallistics");
               return;
            }
            else if (kbTechGetStatus(cTechBallistics) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Ballistics research plan.");
               researchSimpleTech(cTechBallistics, cUnitTypeArmory, -1, 60);
               return;
            }
         }

      // HARD AND UP:
         // Research Bronze Weapons 1350 seconds after reaching Heroic; Hard and Titan only.
         rule researchBronzeWeapons
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 1350 + gHeroicArrival)
            {
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
         }
         // Safeguard
         rule researchSafeguard
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 200 + gHeroicArrival)
            {
               researchSimpleTech(cTechSafeguard, cUnitTypeTemple, -1, 60);
               xsDisableRule("researchSafeguard"); // Disable self.
               return;
            }
         }
         // Architects
         rule researchArchitects
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 1400 + gHeroicArrival)
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
         }
         // Fortified Town Center
         rule researchFortifiedTownCenter
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 1600 + gHeroicArrival)
            {
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
         }
         // Boiling Oil
         rule researchBoilingOil
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 720 + gHeroicArrival)
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

   // *** MYTHIC AGE ***
      // ALL DIFFICULTIES:
         // Flood Control
         rule researchFloodControl
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 5 + gMythicArrival)
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechFloodControl) == cTechStatusActive)
               {
                  xsDisableRule("researchFloodControl");
                  return;
               }
               else if (kbTechGetStatus(cTechFloodControl) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Flood Control research plan.");
                  researchSimpleTech(cTechFloodControl, cUnitTypeOxCart, -1, 60);
                  return;
               }
            }
         }
         // Quarry
         rule researchQuarry
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 5 + gMythicArrival)
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechQuarry) == cTechStatusActive)
               {
                  xsDisableRule("researchQuarry");
                  return;
               }
               else if (kbTechGetStatus(cTechQuarry) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Quarry research plan.");
                  researchSimpleTech(cTechQuarry, cUnitTypeOxCart, -1, 60);
                  return;
               }
            }
         }
         // Carpenters
         rule researchCarpenters
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 5 + gMythicArrival && kbTechGetStatus(cTechBowSaw) == cTechStatusActive)
            {
               researchSimpleTech(cTechCarpenters, cUnitTypeOxCart, -1, 60);
               xsDisableRule("researchCarpenters"); // Disable self.
               return;
            }
         }
      // HARD AND TITAN ONLY:
         // Champion Infantry
         rule researchChampionInfantry
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 720 + gMythicArrival)
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionInfantry");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Infantry research plan.");
                  researchSimpleTech(cTechChampionInfantry, cUnitTypeLonghouse, -1, 60);
                  return;
               }
            }
         }
         // Champion Cavalry
         rule researchChampionCavalry
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 960 + gMythicArrival)
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionCavalry) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionCavalry");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionCavalry) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Cavalry research plan.");
                  researchSimpleTech(cTechChampionCavalry, cUnitTypeGreatHall, -1, 60);
                  return;
               }
            }
         }
         // Conscript Longhouse Soldiers
         rule researchConscriptLonghouseSoldiers
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 30 + gMythicArrival && kbTechGetStatus(cTechLevyLonghouseSoldiers) == cTechStatusActive)
            {
               researchSimpleTech(cTechConscriptLonghouseSoldiers, cUnitTypeLonghouse, -1, 60);
               xsDisableRule("researchConscriptLonghouseSoldiers"); // Disable self.
               return;
            }
         }
      // TITAN ONLY:
         // Berserkergang
         rule researchBerserkergang
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 300 + gMythicArrival)
            {
               researchSimpleTech(cTechBerserkergang, cUnitTypeLonghouse, -1, 60);
               xsDisableRule("researchBerserkergang"); // Disable self.
               return;
            }
         }
         // Conscript Great Hall Soldiers
         rule researchConscriptGreatHallSoldiers
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 30 + gMythicArrival && kbTechGetStatus(cTechLevyGreatHallSoldiers) == cTechStatusActive)
            {
               researchSimpleTech(cTechConscriptGreatHallSoldiers, cUnitTypeGreatHall, -1, 60);
               xsDisableRule("researchConscriptGreatHallSoldiers"); // Disable self.
               return;
            }
         }
         // Conscript Hill Fort Soldiers
         rule researchConscriptHillFortSoldiers
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 30 + gMythicArrival && kbTechGetStatus(cTechLevyHillFortSoldiers) == cTechStatusActive)
            {
               researchSimpleTech(cTechConscriptHillFortSoldiers, cUnitTypeHillFort, -1, 60);
               xsDisableRule("researchConscriptHillFortSoldiers"); // Disable self.
               return;
            }
         }