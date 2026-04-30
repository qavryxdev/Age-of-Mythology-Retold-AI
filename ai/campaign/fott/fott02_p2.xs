//==============================================================================
/* fott02_p2.xs

   Red Egyptian player owning the base. Sends attacks of Spearmen and Axemen.
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
int gFirstLandUnit = cUnitTypeSpearman; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 3;
int gSecondLandUnit = cUnitTypeAxeman; // Gets trained after gSecondLandUnitDelay.
float gMaintainSecondLandUnitAmount = 4;
int gSecondLandUnitDelay = 900; // In seconds.
int gFirstNavalUnit = cUnitTypeKebenit; // Gets trained instantly.
float gMaintainFirstNavalUnitAmount = 1;
float gMaxVillagerCount = 5;
float gMaxFishingShipCount = 2;
float gAttackStartDelay = 360; // In seconds.
float gAttackWaveInterval = 360; // In seconds.
float gAttackStartSize = 5;
float gAttackMaxSize = 12;
float gIntervalAttackStartSize = 4;
float gInitialFarmDelay = 300; // In seconds.
float gAttackSizeLimit = -1;

vector gOurTCLocation = vector(210.0, 1, 142.0);
vector gEnemyTCLocation = vector(95.0, 0.0, 197.0);

Strategy scenarioAttackWaveStrategy()
{
   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugAttackWave("***Starting Scenario Attack Wave Strategy***");

      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         xsEnableRule("researchMediumSpearmen");
      }
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         xsEnableRule("researchMediumAxemen");
      }
      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================

      // Make certain parameters way more lenient on Easy.
      if(cDifficultyCurrent == cDifficultyEasy)
      {
         gAttackStartDelay = 600; // Take longer to launch the first attack.
         gAttackWaveInterval = 900; // Barely attack at all after the first strike.
         gAttackStartSize = 3; // Very feeble attacks on Easy.
         gAttackMaxSize = 4; // Never let this be too high.
         gMaintainFirstLandUnitAmount = 3; // Not too many extra Spearmen.
         gMaintainSecondLandUnitAmount = 0; // Don't train any extra Hoplite killers.
         gMaxVillagerCount = 0; // Don't train more Villagers.
         gMaintainFirstNavalUnitAmount = 0; // Don't train more warships.
         gTrainDelay = 60; // Take really long to train new units.
      }

      // Attacks shouldn't be too feeble out the gate on Hard and Titan, since the AI doesn't attack until you get to Classical.
      if(cDifficultyCurrent >= cDifficultyHard)
      {
         gAttackStartSize *= 2; // Starting attacks are up to twice as large.
         if (gAttackStartSize > gAttackMaxSize)
         {
            gAttackStartSize = gAttackMaxSize;
         }
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFirstNavalUnitAmount *= gDifficultyModifierMaintainUnit;
      gTrainDelay *= gDifficultyModifierTrainDelay;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gIntervalAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      gInitialFarmDelay *= gDifficultyModifierFirstAttack; // Reusing first attack delay difficulty modifier.

      gSecondLandUnitDelay += xsGetTime();
      
      // Shorten the Axeman delay on Hard and Titan.
      if (cDifficultyCurrent == cDifficultyHard)
      {
         gSecondLandUnitDelay = 300;
      }
      else if (cDifficultyCurrent == cDifficultyTitan)
      {
         gSecondLandUnitDelay = 0;
      }

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gFirstNavalUnit, gMaintainFirstNavalUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gFirstNavalUnit, gTrainDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(cWaitWithAttacking); // Switch to the regular attack delay once Arkantos reaches Classical.
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.setMinAttackSize(gAttackStartSize);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.displayFirstAttackStats();

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticFishing, true);
      data.setFlag(cStrategyFlagBuildHouses, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start.
      vector startPoint = vector(178.0, 0.0, 140.0); // In front of the AI's Barracks.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, gEnemyTCLocation);
      int pathID1 = kbPathCreate("Path 1");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(157.0, 0.0, 176.0));
      kbPathAddWaypoint(pathID1, vector(146.0, 0.0, 205.0));
      kbPathAddWaypoint(pathID1, vector(119.0, 0.0, 215.0));
      kbPathAddWaypoint(pathID1, gEnemyTCLocation);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path 2");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(135.0, 0.0, 126.0));
      kbPathAddWaypoint(pathID2, vector(90.0, 0.0, 97.0));
      kbPathAddWaypoint(pathID2, vector(80.0, 0.0, 160.0));
      kbPathAddWaypoint(pathID2, gEnemyTCLocation);
      kbAttackRouteAddPath(routeID, pathID2);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(gEnemyTCLocation);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
            static bool firstAttack = true;
            if (firstAttack == true)
            {
               firstAttack = false;
               gAttackWave.setAttackSize(gIntervalAttackStartSize);
            }
         }
      );

      int landDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 20.0, startPoint);
      aiPlanAddUnitType(landDefendPlan, gFirstLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gSecondLandUnit, 0, 0, 200);

      int waterDefendPlan = createDefendPlan("Water Defend Plan", -1, 20.0, vector(184.0, 0.0, 110.0), 10, vector(184.0, 0.0, 110.0));
      aiPlanAddUnitType(waterDefendPlan, gFirstNavalUnit, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      if (done == false && xsGetTime() >= gSecondLandUnitDelay)
      {
         done = true;

         data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
         data.setTrainDelay(gSecondLandUnit, gTrainDelay);
         gAttackWave.addAttackUnitType(gSecondLandUnit);
      }

      if (gTimeToFarm == false && xsGetTime() >= gInitialFarmDelay) // 5 minutes, modified by difficulty as resources run out faster with more gatherers.
      {
         gTimeToFarm = true; // Start farming early, due to the lack of resources within our small base.
      }

      /***** Increase army sizes on harder difficulties deep into the mission. *****/
      static bool spearman_increase = false;
      static bool axeman_increase = false;

      // Start training more Spearmen after 12 minutes on Hard and Titan.
      if (cDifficultyCurrent >= cDifficultyHard && xsGetTime() >= 720)
      {
         if (spearman_increase == false)
         { 
            gMaintainFirstLandUnitAmount *= 1.75; // Train +75% Spearmen
            gAttackWave.removeAttackUnitType(gFirstLandUnit);
            data.removeUnitToMaintain(gFirstLandUnit); // Spearmen
            data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
            data.setTrainDelay(gFirstLandUnit, gTrainDelay);
            gAttackWave.addAttackUnitType(gFirstLandUnit);  
               
            // Update attack size parameters based on the addition of the Spearmen.
            gAttackMaxSize *= 1.10; // +10%

            // Limit maximum attack wave size to the amount of relevant units we maintain.
            gAttackSizeLimit = gMaintainFirstLandUnitAmount;
            gAttackSizeLimit += gMaintainSecondLandUnitAmount;
            if (gAttackMaxSize > gAttackSizeLimit)
            {
               gAttackMaxSize = gAttackSizeLimit;
               debugAttackWave("Limiting maximum attack wave size to: " + gAttackSizeLimit);
            }

            gAttackWave.setMaxAttackSize(gAttackMaxSize);

            spearman_increase = true;
         }
      }

      // Start training more Axemen after 18 minutes Titan.
      if (cDifficultyCurrent >= cDifficultyTitan && xsGetTime() >= 1080)
      {
         if (axeman_increase == false)
         { 
            gMaintainSecondLandUnitAmount *= 2.0; // Train +100% Axemen
            gAttackWave.removeAttackUnitType(gSecondLandUnit);
            data.removeUnitToMaintain(gSecondLandUnit); // Axemen
            data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
            data.setTrainDelay(gSecondLandUnit, gTrainDelay);
            gAttackWave.addAttackUnitType(gSecondLandUnit);
            
            // Update attack size parameters based on the addition of the Axemen.
            gAttackMaxSize *= 1.10; // +10%

            // Limit maximum attack wave size to the amount of relevant units we maintain.
            gAttackSizeLimit = gMaintainFirstLandUnitAmount;
            gAttackSizeLimit += gMaintainSecondLandUnitAmount;
            if (gAttackMaxSize > gAttackSizeLimit)
            {
               gAttackMaxSize = gAttackSizeLimit;
               debugAttackWave("Limiting maximum attack wave size to: " + gAttackSizeLimit);
            }

            gAttackWave.setMaxAttackSize(gAttackMaxSize);

            axeman_increase = true;
         }
      }

      // Don't use the Siege Tower until 15 minutes in.
      static bool use_siege_tower = false;
      if (cDifficultyCurrent >= cDifficultyTitan && xsGetTime() >= 1500)
         if (use_siege_tower == false)
         {
            {
               gAttackWave.addAttackUnitType(cUnitTypeSiegeTower); // Use the one Siege Tower the player starts with.
               use_siege_tower = true;
            }
         }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott02StrategySetup()
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
   gMaxFishingShipCount *= gDifficultyModifierMaintainFishing;

   gOverrideMaxVillagerPop = gMaxVillagerCount;
   gOverrideMaxFishingShipPop = gMaxFishingShipCount;

   gMainGatherBase = createOverrideGatherBase(vector(237.00, 0.00, 121.00), 90); // Covering most of our large base.
   gOverrideClosestFishLocation = vector(190.00, 0.00, 117.00);
   gMaxFishDockScanRange = 560;

   setOverrideStrategy(fott02StrategySetup);

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

rule researchMediumSpearmen
inactive
minInterval 90
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechMediumSpearmen) == cTechStatusActive)
   {
      xsDisableRule("researchMediumSpearmen");
      return;
   }
   else if (kbTechGetStatus(cTechMediumSpearmen) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Medium Spearmen research plan.");
      researchSimpleTech(cTechMediumSpearmen, cUnitTypeBarracks, -1, 60);
      return;
   }
}

rule researchMediumAxemen
inactive
minInterval 60
{
   xsSetRuleMinIntervalSelf(10);
   // On Hard difficulty, we wait until 5 minutes (after activation) have passed.
   if (cDifficultyCurrent == cDifficultyHard && xsGetTime() < 300)
   {
      return;
   }

   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechMediumAxemen) == cTechStatusActive)
   {
      xsDisableRule("researchMediumAxemen");
      return;
   }
   else if (kbTechGetStatus(cTechMediumAxemen) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Medium Axemen research plan.");
      researchSimpleTech(cTechMediumAxemen, cUnitTypeBarracks, -1, 60);
      return;
   }
}

// Called from the triggers to enable attacks. Occurs when Arkantos reaches the Classical Age.
void updateParameters()
{
   // Define first attack.
   gAttackWave.setAttackStartTime(gAttackStartDelay);
   return;
}