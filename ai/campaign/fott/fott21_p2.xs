//==============================================================================
/* fott21_p2.xs

   Greek Greek player owning a base that dominates the center of the island.
   Attacks with Hypaspists, Hippeis, Toxotes, and Petroboli. Has some static
   Hoplites.
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

float gTrainDelay = 0; // In seconds.
int gFirstLandUnit = cUnitTypeHypaspist;
float gMaintainFirstLandUnitAmount = 8;
int gSecondLandUnit = cUnitTypeHippeus;
float gMaintainSecondLandUnitAmount = 8;
int gThirdLandUnit = cUnitTypeToxotes;
float gMaintainThirdLandUnitAmount = 4;
int gFourthLandUnit = cUnitTypePetrobolos;
float gMaintainFourthLandUnitAmount = 1; // Only trained on Hard and Titan; lowest amount will be 2.
int gFifthLandUnit = cUnitTypeNemeanLion;
float gMaintainFifthLandUnitAmount = 2;
int gSixthLandUnit = cUnitTypeHippolyta; // Gets trained from the start.
float gMaintainSixthLandUnitAmount = 1; // Not affected by the multiplier.
int gSeventhLandUnit = cUnitTypeAtalanta; // Gets trained from the start.
float gMaintainSeventhLandUnitAmount = 1; // Not affected by the multiplier.
int gEighthLandUnit = cUnitTypePolyphemus; // Gets trained from the start, only on Hard and Titan.
float gMaintainEighthLandUnitAmount = 1; // Not affected by modifier.

int gFirstNavalUnit = cUnitTypeTrireme; // Starts training once player 1 reaches the Temple of Zeus.
float gMaintainFirstNavalUnitAmount = 2;
int gSecondNavalUnit = cUnitTypeScylla; // Starts training once player 1 reaches the Temple of Zeus.
float gMaintainSecondNavalUnitAmount = 1;

float gMaxVillagerCount = 0; // Updates to 12 later.
float gMaxFishingShipCount = 0; // Updates to 4 later.

float gAttackStartDelay = 640; // Updates to current xsGetTime() + this once you reach the Zeus Temple.
float gAttackWaveInterval = 360; // In seconds; left flank only.

float gSecondAttackStartDelay = 640; // Updates to xsGetTime() + this once you reach the Zeus Temple.
float gSecondAttackInterval = 360; // In seconds; right flank only.

float gAttackStartSize = 4;
float gAttackMaxSize = 6;

float gSecondAttackStartSize = 3;
float gSecondAttackMaxSize = 5;

int gLandDefendPlan = -1;

int gWakeUpTime = 0; // Set to the current in-game time when the AI is told to 'wake up', after Arkantos reaches the Zeus Temple.

Strategy scenarioAttackWaveStrategy()
{
   // This should never fail.

   // Technologies don't start being researched until P1 reaches the Temple of Zeus.

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

      // gMaintainFirstNavalUnitAmount *= gDifficultyModifierMaintainUnit;
      // gMaintainSecondNavalUnitAmount *= gDifficultyModifierMaintainUnit;

      // Naval unit amounts are handled manually, rather than through multipliers.
      if (cDifficultyCurrent == cDifficultyHard)
      {
         gMaintainFirstNavalUnitAmount = 3;
         gMaintainSecondNavalUnitAmount = 1;
      }
      if (cDifficultyCurrent == cDifficultyTitan)
      {
         gMaintainFirstNavalUnitAmount = 4;
         gMaintainSecondNavalUnitAmount = 2;
      }

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gSecondAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gSecondAttackInterval *= gDifficultyModifierAttackInterval;

      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gSecondAttackStartSize *= gDifficultyModifierAttackSizes;
      gSecondAttackMaxSize *= gDifficultyModifierAttackSizes;

      gTrainDelay *= gDifficultyModifierTrainDelay;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      // Don't make Nemean Lions or Petroboli until later.
      // data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         // data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
         data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
         data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);
      }

      // Maintain Triremes after attacks are enabled.

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         data.setTrainDelay(gSixthLandUnit, gTrainDelay);
         data.setTrainDelay(gSeventhLandUnit, gTrainDelay);
      }

      // Details about the attack waves.
      // Left flank; all units except Hippeis and Nemean Lions.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(cWaitWithAttacking);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gThirdLandUnit);
      gAttackWave.addAttackUnitType(gFourthLandUnit);
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gAttackWave.addAttackUnitType(gSixthLandUnit);
         gAttackWave.addAttackUnitType(gSeventhLandUnit);
      }

      // Right flank; Hippeis and Nemean Lions.
      gSecondAttackWave.setName("gSecondAttackWave");
      gSecondAttackWave.setAttackStartTime(cWaitWithAttacking);
      gSecondAttackWave.setAttackInterval(gSecondAttackInterval);
      gSecondAttackWave.setAttackSize(gSecondAttackStartSize);
      gSecondAttackWave.setMaxAttackSize(gSecondAttackMaxSize);
      gSecondAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gSecondAttackWave.addAttackUnitType(gSecondLandUnit);
      gSecondAttackWave.addAttackUnitType(gFifthLandUnit);

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticFishing, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);

      // * * * * * * * * * * * * * //
      //  Attack Plan - Left Flank //
      // * * * * * * * * * * * * * //

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector gatherPoint1 = vector(175.0, 0.0, 201.0); // Between two towers and Archery Range.
      vector targetPoint = vector(186.0, 0.0, 299.0); // At the Zeus Temple.
      // vector targetPoint = vector(101.0, 0.0, 333.0); // West TC
      vector targetPoint2 = vector(285.0, 0.0, 307.0); // North TC

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Hypaspists, Toxotes, Petroboli and Heroes", gatherPoint1, targetPoint);

      // Paths are only added to the attack plan once P1 decides where to settle.
      gAttackWave.setGatherPoint(gatherPoint1);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      // * * * * * * * * * * * * * //
      //  Attack Plan - Right Flank //
      // * * * * * * * * * * * * * //

      gSecondAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector gatherPoint2 = vector(251.0, 0.0, 190.0); // Left of the hilltop Stables.
      // Target point has to be the same.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID2 = kbCreateAttackRouteWithPath("Hippeis and Nemean Lions", gatherPoint2, targetPoint);

      // Paths are only added to the attack plan once P1 decides where to settle.
      gSecondAttackWave.setGatherPoint(gatherPoint2);
      gSecondAttackWave.setTargetPoint(targetPoint);
      gSecondAttackWave.setAttackRouteID(routeID2);
      gSecondAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      // Set rally point for some of the military buildings.
      aiUnitSetRallyPointToPosition(getUnit(cUnitTypeMilitaryAcademy), gatherPoint1);
      aiUnitSetRallyPointToPosition(getUnit(cUnitTypeArcheryRange), gatherPoint1);
      aiUnitSetRallyPointToPosition(getUnit(cUnitTypeFortress), gatherPoint1);
      aiUnitSetRallyPointToPosition(getUnit(cUnitTypeStable), gatherPoint2);
      
      // Patrol plan.
      int scyllaPatrolPlan = createDefendPlan("Scylla Patrol Plan", -1, 5.0, vector(360.0, 0.0, 218.0), 10, vector(360.0, 0.0, 218.0));
      aiPlanAddUnitType(scyllaPatrolPlan, cUnitTypeScylla, 0, 0, 200);
      aiPlanSetVariableBool(scyllaPatrolPlan, cDefendPlanPatrol, 0, true);
      aiPlanSetNumberVariableValues(scyllaPatrolPlan, cDefendPlanPatrolWaypoints, 4);
      aiPlanSetVariableVector(scyllaPatrolPlan, cDefendPlanPatrolWaypoints, 0, vector(360.0, 0.0, 218.0));
      aiPlanSetVariableVector(scyllaPatrolPlan, cDefendPlanPatrolWaypoints, 1, vector(385.0, 0.0, 129.0));
      aiPlanSetVariableVector(scyllaPatrolPlan, cDefendPlanPatrolWaypoints, 2, vector(333.0, 0.0, 60.0));
      aiPlanSetVariableVector(scyllaPatrolPlan, cDefendPlanPatrolWaypoints, 3, vector(298.0, 0.0, 115.0));
      aiPlanSetVariableInt(scyllaPatrolPlan, 0, 0, 1000);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      // Start maintaining navy after we've 'woken up' as Arkantos becomes human again. We're checking gWakeUpTime for this.
      static bool done = false;
      static int elapsed_time = 0; // Depends on when Circe wakes up.
      static int vill_increase_threshold = 0; // Depends on when Circe wakes up.
      int vill_elapsed_time = 99999; // Changes later.

      static bool toxotes_increase = false;
      static bool hippeus_increase = false;
      static bool hypaspist_petrobolos_increase = false;
      static bool nemean_lion_increase = false;
      static bool more_vills = false;

      if (done == false && gWakeUpTime > 0)
      {
         // Enable navy maintenance.
         data.addUnitToMaintain(gFirstNavalUnit, gMaintainFirstNavalUnitAmount);
         data.addUnitToMaintain(gSecondNavalUnit, gMaintainSecondNavalUnitAmount);
         data.setTrainDelay(gFirstNavalUnit, gTrainDelay);
         data.setTrainDelay(gSecondNavalUnit, gTrainDelay);
         elapsed_time += gWakeUpTime;
         vill_increase_threshold += gWakeUpTime;
         vill_elapsed_time = 0; // Restart
         done = true;
      }

      // Begin training more Villagers 8 minutes after waking up.
      vill_elapsed_time = xsGetTime() - vill_increase_threshold;

      if (vill_elapsed_time >= 480 && done == true)
      {
         if (more_vills == false)
         {
            gMaxVillagerCount *= 1.5; // Train +50% more Villagers.
            gOverrideMaxVillagerPop = gMaxVillagerCount;
            more_vills = true;
         }
      }

      // *** Gradually increase the minimum attack size as the mission progresses. ***

      // Don't scale the attacks like this on Easy.
      // Must be awake before proceeding.
      if (cDifficultyCurrent >= 1 && done == true)
      {
         int increase_interval = xsGetTime() - elapsed_time;
         static int total_increases = 0;

         // Increase the Attack Size every 300 seconds.
         if (increase_interval >= 300)
         {
            // Stop doing this after 5 increases.
            if (total_increases < 5)
            {
               elapsed_time = xsGetTime();
               total_increases++;

               // Begin training more Toxotai with the second increase (Hard and Titan only).
               if (cDifficultyCurrent >= cDifficultyHard && toxotes_increase == false)
               {
                  // Occurs after the second attack size increase.
                  if (total_increases == 2)
                  {
                     gMaintainThirdLandUnitAmount *= 1.5; // Train +50% Toxotai.
                     data.removeUnitToMaintain(gThirdLandUnit); // Toxotes
                     data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
                     data.setTrainDelay(gThirdLandUnit, gTrainDelay);

                     toxotes_increase = true;
                     gAttackWave.update();
                  }
               }

               // Begin training more Hippeis with the third increase (Hard and Titan only). Also start making Polyphemus.
               if (cDifficultyCurrent >= cDifficultyHard && hippeus_increase == false)
               {
                  // Occurs after the third attack size increase.
                  if (total_increases == 3)
                  {
                     gMaintainSecondLandUnitAmount *= 1.25; // Train +25% Hippeis.
                     data.removeUnitToMaintain(gSecondLandUnit); // Hippeus
                     data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
                     data.setTrainDelay(gSecondLandUnit, gTrainDelay);
                     // Start dispatching Polyphemus.
                     data.addUnitToMaintain(gEighthLandUnit, gMaintainEighthLandUnitAmount);
                     gAttackWave.addAttackUnitType(gEighthLandUnit);
                     data.setTrainDelay(gEighthLandUnit, gTrainDelay);
                     hippeus_increase = true;
                     gSecondAttackWave.update();
                  }
               }


         static bool nemeans_added = false;
         static bool petroboli_added = false;
         if (total_increases >= 2 && nemeans_added == false)
         {
            data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
            data.setTrainDelay(gFifthLandUnit, gTrainDelay);
            nemeans_added = true;
         }
         if (total_increases >= 5 && petroboli_added == false)
         {
            data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
            data.setTrainDelay(gFourthLandUnit, gTrainDelay);
            petroboli_added = true;
         }


               // Begin training more Hypaspists + Petroboli with the fourth increase (Titan only).
               if (cDifficultyCurrent == cDifficultyTitan && hypaspist_petrobolos_increase == false)
               {
                  // Occurs after the fourth attack size increase.
                  if (total_increases == 4)
                  {
                     gMaintainFirstLandUnitAmount *= 1.20; // Train +20% Hypaspists.
                     gMaintainFourthLandUnitAmount *= 2.0; // Train +100% Petroboli.
                     data.removeUnitToMaintain(gFirstLandUnit); // Hypaspist
                     data.removeUnitToMaintain(gFourthLandUnit); // Petrobolos
                     data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
                     data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
                     data.setTrainDelay(gFirstLandUnit, gTrainDelay);
                     data.setTrainDelay(gFourthLandUnit, gTrainDelay);

                     hypaspist_petrobolos_increase = true;
                     gAttackWave.update();
                  }
               }

               // Begin training more Nemean Lions with the fifth increase (Titan only).
               if (cDifficultyCurrent == cDifficultyTitan && nemean_lion_increase == false)
               {
                  // Occurs after the fifth attack size increase.
                  if (total_increases == 5)
                  {
                     gMaintainFifthLandUnitAmount *= 1.20; // Train +20% Nemean Lions.
                     data.removeUnitToMaintain(gFifthLandUnit); // Nemean Lions
                     data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
                     data.setTrainDelay(gFifthLandUnit, gTrainDelay);

                     nemean_lion_increase = true;
                     gAttackWave.update();
                  }
               }

               // Calculate attack size limiter for the first attack wave.
               int size_limiter1 = gMaintainFirstLandUnitAmount;
               size_limiter1 += gMaintainThirdLandUnitAmount;
               size_limiter1 += gMaintainSixthLandUnitAmount;
               size_limiter1 += gMaintainSeventhLandUnitAmount;
               if (cDifficultyCurrent >= cDifficultyHard)
               {
                  size_limiter1 += gMaintainFourthLandUnitAmount;
                  size_limiter1 += gMaintainEighthLandUnitAmount;
               }

               // Calculate attack size limiter for the second attack wave.
               int size_limiter2 = gMaintainSecondLandUnitAmount;
               size_limiter2 += gMaintainFifthLandUnitAmount;

               // Slower attack size increase on Moderate.
               if (cDifficultyCurrent == cDifficultyModerate)
               {
                  gAttackStartSize *= 1.10; // Increases by 10 percent.
                  gAttackMaxSize *= 1.10; // Increases by 10 percent.
                  gSecondAttackStartSize *= 1.10; // Increases by 10 percent.
                  gSecondAttackMaxSize *= 1.10; // Increases by 10 percent.
               }
               else if (cDifficultyCurrent == cDifficultyHard)
               {
                  gAttackStartSize *= 1.20; // Increases by 20 percent.
                  gAttackMaxSize *= 1.20; // Increases by 20 percent.
                  gSecondAttackStartSize *= 1.20; // Increases by 20 percent.
                  gSecondAttackMaxSize *= 1.20; // Increases by 20 percent.
               }
               else if (cDifficultyCurrent == cDifficultyTitan)
               {
                  gAttackStartSize *= 1.25; // Increases by 25 percent.
                  gAttackMaxSize *= 1.25; // Increases by 25 percent.
                  gSecondAttackStartSize *= 1.25; // Increases by 25 percent.
                  gSecondAttackMaxSize *= 1.25; // Increases by 25 percent.
               }
               if (cDifficultyCurrent >= cDifficultyModerate)
               {
                  // Apply first attack size limiter for the first attack wave.
                  if (gAttackStartSize > size_limiter1)
                  {
                     gAttackStartSize = size_limiter1;
                     debugAttackWave("Limiting first attack wave size to: " + size_limiter1);
                  }
                  if (gAttackMaxSize > size_limiter1)
                  {
                     gAttackMaxSize = size_limiter1;
                  }
                  gAttackWave.setAttackSize(gAttackStartSize);
                  gAttackWave.setMaxAttackSize(gAttackMaxSize);
                  gAttackWave.update();

                  // Apply second attack size limiter for the smaller second attack wave.
                  if (gSecondAttackStartSize > size_limiter2)
                  {
                     gSecondAttackStartSize = size_limiter2;
                     debugAttackWave("Limiting second attack wave size to: " + size_limiter2);
                  }
                  if (gSecondAttackMaxSize > size_limiter2)
                  {
                     gSecondAttackMaxSize = size_limiter2;
                  }
                  gSecondAttackWave.setAttackSize(gSecondAttackStartSize);
                  gSecondAttackWave.setMaxAttackSize(gSecondAttackMaxSize);
                  gSecondAttackWave.update();
               }
            }
         }
      }

      gAttackWave.update();
      gSecondAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott21StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(345.00, 0.00, 133.00), 55);

   gOverrideClosestFishLocation = vector(318.00, 0.00, 105.00);
   gMaxFishDockScanRange = 560;

   setOverrideStrategy(fott21StrategySetup);

   gOverrideFarmCount = 20; // We can't have too many farms due to space restrictions.
   gRBDSystem.setMaxFarmsPerBase(20);
   gRBDSystem.setMaxFarmsPerIteration(20);
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, vector(337.0, 0, 135.0), 15.0); // Our TC.
      kbBuildingPlacementAddPositionInfluence(bpID, vector(337.0, 0, 135.0), 100.0, 15.0, cFalloffLinear); // Our TC.
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

// * * * * * * * * * * * //
//  ARMORY TECHNOLOGIES  //
// * * * * * * * * * * * //

// Research Bronze Weapons 480 seconds after waking up; occurs on all difficulties.
rule researchBronzeWeapons
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgrades
{
   if (xsGetTime() >= 480 + gWakeUpTime)
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
            xsEnableRule("researchBronzeShields"); // Bronze Shields is the next Armory tech.
            return;
         }
         return;
      }
}

// Research Bronze Shields at 600 seconds after waking up; occurs on all difficulties.
rule researchBronzeShields
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgrades
{
   // int current_time = xsGetTime();
   if (xsGetTime() >= 600 + gWakeUpTime)
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

// * * * * * * * * * * * * * * * * //
//  MILITARY ACADEMY TECHNOLOGIES  //
// * * * * * * * * * * * * * * * * //

// Research Medium Infantry 300 seconds after waking up; occurs on all difficulties.
rule researchMediumInfantry
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgrades
{
   if (xsGetTime() >= 300 + gWakeUpTime)
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
            researchSimpleTech(cTechMediumInfantry, cUnitTypeMilitaryAcademy, -1, 60);
            xsEnableRule("researchHeavyInfantry"); // Heavy Infantry is the next Academy tech.
            return;
         }
      }
}

// Research Heavy Infantry 480 seconds after waking up; occurs on all difficulties.
rule researchHeavyInfantry
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgrades
{
   if (xsGetTime() >= 480 + gWakeUpTime)
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
            researchSimpleTech(cTechHeavyInfantry, cUnitTypeMilitaryAcademy, -1, 60);
            return;
         }
      }
}

// * * * * * * * * * * * * * * * //
//   ARCHERY RANGE TECHNOLOGIES  //
// * * * * * * * * * * * * * * * //

// Research Medium Archers 420 seconds after waking up; occurs on all difficulties.
rule researchMediumArchers
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgrades
{
   if (cDifficultyCurrent <= cDifficultyModerate && xsGetTime() >= 420 + gWakeUpTime)
      {
         researchSimpleTech(cTechMediumArchers, cUnitTypeArcheryRange, -1, 60);
         xsEnableRule("researchHeavyArchers"); // Heavy Infantry is the next Academy tech.
         xsDisableRule("researchMediumArchers"); // Disable self.
         return;
      }
   // Upgrade happens sooner on harder levels.
   else if (cDifficultyCurrent >= cDifficultyHard && xsGetTime() >= 120 + gWakeUpTime)
      {
         researchSimpleTech(cTechMediumArchers, cUnitTypeArcheryRange, -1, 60);
         xsEnableRule("researchHeavyArchers"); // Heavy Infantry is the next Academy tech.
         xsDisableRule("researchMediumArchers"); // Disable self.
         return;
      }
}

// Research Heavy Archers 540 seconds after waking up; occurs on all difficulties.
rule researchHeavyArchers
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgrades
{
   if (cDifficultyCurrent <= cDifficultyModerate && xsGetTime() >= 540 + gWakeUpTime)
      {
         // Cease if we have it. Otherwise, research it.
         if (kbTechGetStatus(cTechHeavyArchers) == cTechStatusActive)
         {
            xsDisableRule("researchHeavyArchers");
            return;
         }
         else if (kbTechGetStatus(cTechHeavyArchers) == cTechStatusObtainable)
         {
            debugAttackWave("Starting Heavy Archers research plan.");
            researchSimpleTech(cTechHeavyArchers, cUnitTypeArcheryRange, -1, 60);
            return;
         }
      }
   // Upgrade happens sooner on harder levels.
   else if (cDifficultyCurrent >= cDifficultyHard && xsGetTime() >= 300 + gWakeUpTime)
      {
         // Cease if we have it. Otherwise, research it.
         if (kbTechGetStatus(cTechHeavyArchers) == cTechStatusActive)
         {
            xsDisableRule("researchHeavyArchers");
            return;
         }
         else if (kbTechGetStatus(cTechHeavyArchers) == cTechStatusObtainable)
         {
            debugAttackWave("Starting Heavy Archers research plan.");
            researchSimpleTech(cTechHeavyArchers, cUnitTypeArcheryRange, -1, 60);
            return;
         }
      }
}

// * * * * * * * * * * * * //
//   STABLE TECHNOLOGIES   //
// * * * * * * * * * * * * //

// Research Medium Cavalry 420 seconds after waking up; occurs on all difficulties.
rule researchMediumCavalry
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgrades
{
   if (cDifficultyCurrent <= cDifficultyModerate && xsGetTime() >= 420 + gWakeUpTime)
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
            researchSimpleTech(cTechMediumCavalry, cUnitTypeStable, -1, 60);
            return;
         }
      }
   // Upgrade happens sooner on harder levels.
   else if (cDifficultyCurrent >= cDifficultyHard && xsGetTime() >= 240 + gWakeUpTime)
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
            researchSimpleTech(cTechMediumCavalry, cUnitTypeStable, -1, 60);
            return;
         }
      }
}

// Research Heavy Cavalry 600 seconds after waking up; occurs on Hard and Titan only.
rule researchHeavyCavalry
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgradesHard
{
   if (xsGetTime() >= 600 + gWakeUpTime)
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
            researchSimpleTech(cTechHeavyCavalry, cUnitTypeStable, -1, 60);
            return;
         }
      }
}

// * * * * * * * * * * //
//  TOWER TECHNOLOGIES  //
// * * * * * * * * * * //

// Research Boiling Oil 720 seconds after waking up; occurs on all difficulties.
rule researchBoilingOil
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgrades
{
   if (xsGetTime() >= 540 + gWakeUpTime)
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

// Research Guard Tower 1500 seconds after waking up; occurs on Hard and Titan Only.
rule researchGuardTower
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgradesHard
{
   if (xsGetTime() >= 1500 + gWakeUpTime)
      {
         // Cease if we have it. Otherwise, research it.
         if (kbTechGetStatus(cTechGuardTower) == cTechStatusActive)
         {
            xsDisableRule("researchGuardTower");
            return;
         }
         else if (kbTechGetStatus(cTechGuardTower) == cTechStatusObtainable)
         {
            debugAttackWave("Starting GuardTower research plan.");
            researchSimpleTech(cTechGuardTower, cUnitTypeSentryTower, -1, 60);
            return;
         }
      }
}

// * * * * * * * * * * //
//  OTHER TECHNOLOGIES  //
// * * * * * * * * * * //

// Research Draft Horses 120 seconds after waking up; occurs on all difficulties.
rule researchDraftHorses
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgrades
{
   if (xsGetTime() >= 120 + gWakeUpTime)
      {
         xsSetRuleMinIntervalSelf(10);
         // Cease if we have it. Otherwise, research it.
         if (kbTechGetStatus(cTechDraftHorses) == cTechStatusActive)
         {
            xsDisableRule("researchDraftHorses");
            return;
         }
         else if (kbTechGetStatus(cTechDraftHorses) == cTechStatusObtainable)
         {
            debugAttackWave("Starting Draft Horses research plan.");
            researchSimpleTech(cTechDraftHorses, cUnitTypeFortress, -1, 60);
            return;
         }
         return;
      }
}

// Research Masons 120 seconds after waking up; doesn't occur on Easy.
rule researchMasons
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgradesModerate
{
   if (xsGetTime() >= 120 + gWakeUpTime)
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

// Research Ballistics 480 seconds after waking up; doesn't occur on Easy.
rule researchBallistics
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgradesModerate
{
   if (xsGetTime() >= 480 + gWakeUpTime)
      {
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
}

// Research Fortified TC 640 seconds after waking up; doesn't occur on Easy.
rule researchFortifiedTownCenter
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgradesModerate
{
   if (xsGetTime() >= 640 + gWakeUpTime)
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

// Research Crenellations 420 seconds after waking up; doesn't occur on Easy.
rule researchCrenellations
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgradesModerate
{
   if (xsGetTime() >= 420 + gWakeUpTime)
      {
         researchSimpleTech(cTechCrenellations, cUnitTypeSentryTower, -1, 60);
         xsDisableRule("researchCrenellations"); // Disable self.
         return;
      }
}

// Research Architects 540 seconds after waking up; occurs on Hard and Titan only.
rule researchArchitects
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgradesHard
{
   if (xsGetTime() >= 540 + gWakeUpTime)
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

// Research Spirited Charge 800 seconds after waking up; occurs on Hard and Titan only.
rule researchSpiritedCharge
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgradesHard
{
   if (xsGetTime() >= 800 + gWakeUpTime)
      {
         researchSimpleTech(cTechSpiritedCharge, cUnitTypeStable, -1, 60);
         xsDisableRule("researchSpiritedCharge"); // Disable self.
         return;
      }
}

// Research Roar of Orthus 1440 seconds after waking up; occurs on Hard and Titan only.
rule researchRoarOfOrthus
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgradesHard
{
   if (xsGetTime() >= 1440 + gWakeUpTime)
      {
         // Cease if we have it. Otherwise, research it.
         if (kbTechGetStatus(cTechRoarOfOrthus) == cTechStatusActive)
         {
            xsDisableRule("researchRoarOfOrthus");
            return;
         }
         else if (kbTechGetStatus(cTechRoarOfOrthus) == cTechStatusObtainable)
         {
            debugAttackWave("Starting Roar of Orthus research plan.");
            researchSimpleTech(cTechRoarOfOrthus, cUnitTypeTemple, -1, 60);
            return;
         }
      }
}

// ---- ATTACK ROUTE RULES --- //
// Circe will take different attack routes depending on which Settlement you chose. If there are multiple Villagers near the
// other Settlement, then she'll start attacking that area as well.

// Called from the triggers to start looking where the player's set up their base. -> E12_Attack_Route_Rules
void startSearchingForPlayer()
{
   xsEnableRule("startAttackingWest");
   xsEnableRule("startAttackingNorth");
   return;
}

rule startAttackingWest
inactive 
minInterval 10
{
   vector west_settlement = vector(100.0, 0.0, 331.0);
   static int numEnemyBuildingsWest = -1;
   static int numEnemyVillagersWest = -1;
   static int totalEnemiesWest = 0;

   numEnemyBuildingsWest = getUnitCountByLocation(cUnitTypeBuilding, 1, cUnitStateAlive, west_settlement, 20.0);
   numEnemyVillagersWest = getUnitCountByLocation(cUnitTypeAbstractVillager, 1, cUnitStateAlive, west_settlement, 20);

   totalEnemiesWest += numEnemyBuildingsWest;
   totalEnemiesWest += numEnemyVillagersWest;

   if (totalEnemiesWest >= 1)
   {
      vector gatherPoint1 = vector(175.0, 0.0, 201.0); // Between two towers and Archery Range.
      vector gatherPoint2 = vector(251.0, 0.0, 190.0); // Left of the hilltop Stables.
      vector targetPoint = vector(186.0, 0.0, 299.0); // At the Zeus Temple.
      // vector targetPoint = vector(101.0, 0.0, 333.0); // West TC

      // Left flank route.
      int pathID1 = kbPathCreate("Left flank, go west.");
      kbPathAddWaypoint(pathID1, gatherPoint1);
      kbPathAddWaypoint(pathID1, vector(201.0, 0.0, 201.0)); // Block #1
      kbPathAddWaypoint(pathID1, vector(200.0, 0.0, 267.0)); // Block #2
      kbPathAddWaypoint(pathID1, vector(150.0, 0.0, 265.0)); // Block #3
      kbPathAddWaypoint(pathID1, vector(99.0, 0.0, 322.0)); // Block #4
      kbPathAddWaypoint(pathID1, vector(57.0, 0.0, 184.0)); // Block #5
      kbPathAddWaypoint(pathID1, vector(198.0, 0.0, 270.0)); // Block #6.
      kbPathAddWaypoint(pathID1, targetPoint); // End point.
      kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID1);
      debugAttackWave("We've added a new route!");

      // Right flank route.
      int pathID2 = kbPathCreate("Right flank, go west.");
      kbPathAddWaypoint(pathID2, gatherPoint2);
      kbPathAddWaypoint(pathID2, vector(251.0, 0.0, 239.0)); // Block #1
      kbPathAddWaypoint(pathID2, vector(200.0, 0.0, 267.0)); // Block #2
      kbPathAddWaypoint(pathID2, vector(150.0, 0.0, 265.0)); // Block #3
      kbPathAddWaypoint(pathID2, vector(99.0, 0.0, 322.0)); // Block #4
      kbPathAddWaypoint(pathID2, vector(57.0, 0.0, 184.0)); // Block #5
      kbPathAddWaypoint(pathID2, vector(198.0, 0.0, 270.0)); // Block #6.
      kbPathAddWaypoint(pathID2, targetPoint); // End point.
      kbAttackRouteAddPath(gSecondAttackWave.mAttackRouteID, pathID2);

      xsDisableRule("startAttackingWest"); // Disable self.
      return;
   }
}

rule startAttackingNorth
inactive 
minInterval 10
{
   vector north_settlement = vector(283.0, 0.0, 305.0);
   static int numEnemyBuildingsNorth = -1;
   static int numEnemyVillagersNorth = -1;
   static int totalEnemiesNorth = 0;

   numEnemyBuildingsNorth = getUnitCountByLocation(cUnitTypeBuilding, 1, cUnitStateAlive, north_settlement, 20.0);
   numEnemyVillagersNorth = getUnitCountByLocation(cUnitTypeAbstractVillager, 1, cUnitStateAlive, north_settlement, 20);

   totalEnemiesNorth += numEnemyBuildingsNorth;
   totalEnemiesNorth += numEnemyVillagersNorth;

   if (totalEnemiesNorth >= 1)
   {
      vector gatherPoint1 = vector(175.0, 0.0, 201.0); // Between two towers and Archery Range.
      vector gatherPoint2 = vector(251.0, 0.0, 190.0); // Left of the hilltop Stables.
      vector targetPoint = vector(186.0, 0.0, 299.0); // At the Zeus Temple.
      // vector targetPoint = vector(285.0, 0.0, 307.0); // North TC

      // Left flank route.
      int pathID3 = kbPathCreate("Left flank, go north.");
      kbPathAddWaypoint(pathID3, gatherPoint1);
      kbPathAddWaypoint(pathID3, vector(201.0, 0.0, 201.0)); // Block #1.
      kbPathAddWaypoint(pathID3, vector(264.0, 0.0, 280.0)); // Block #2.
      kbPathAddWaypoint(pathID3, vector(275.0, 0.0, 303.0)); // Block #3.
      kbPathAddWaypoint(pathID3, vector(195.0, 0.0, 271.0)); // Block #4.
      kbPathAddWaypoint(pathID3, targetPoint);
      kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID3);
      debugAttackWave("We have a route!");

      // Right flank route.
      int pathID4 = kbPathCreate("Right flank, go north.");
      kbPathAddWaypoint(pathID4, gatherPoint2);
      kbPathAddWaypoint(pathID4, vector(251.0, 0.0, 239.0)); // Block #1.
      kbPathAddWaypoint(pathID4, vector(264.0, 0.0, 280.0)); // Block #2.
      kbPathAddWaypoint(pathID4, vector(275.0, 0.0, 303.0)); // Block #3.
      kbPathAddWaypoint(pathID4, vector(195.0, 0.0, 271.0)); // Block #4.
      kbPathAddWaypoint(pathID4, targetPoint);
      kbAttackRouteAddPath(gSecondAttackWave.mAttackRouteID, pathID4);

      xsDisableRule("startAttackingNorth"); // Disable self.
      return;
   }
}

// Called from the triggers to enable attacks. -> E12_Attack_Route_Rules
void updateParameters()
{
   // Set the wakeup time and enable upgrade rules.
   gWakeUpTime = xsGetTime(); // Used to determine when to research upgrades.
   xsEnableRuleGroup("ruleGroupUpgrades");

   // Enable techs that aren't researched on easy.
   if (cDifficultyCurrent >= cDifficultyModerate)
   {
      xsEnableRuleGroup("ruleGroupUpgradesModerate");
   }

   // Enable techs for Hard and Titan only.
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      xsEnableRuleGroup("ruleGroupUpgradesHard");
   }

   // Define first attack.
   // gAttackStartDelay += xsGetTime();
   gAttackWave.setAttackStartTime(gAttackStartDelay);

   // Define second attack.
   // gSecondAttackStartDelay += xsGetTime();
   gSecondAttackWave.setAttackStartTime(gSecondAttackStartDelay);

   debugAttackWave("*** First Attack Wave Activated ***");
   gAttackWave.displayFirstAttackStats();

   debugAttackWave("*** Second Attack Wave Activated ***");
   gSecondAttackWave.displayFirstAttackStats();

   // Enable the defend plan.

   /*
   vector TC_Area = vector(337.0, 0.0, 135.0);
   gLandDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 200.0, TC_Area, 10, TC_Area);
   aiPlanAddUnitType(gLandDefendPlan, gFirstLandUnit, 0, 0, 200);
   aiPlanAddUnitType(gLandDefendPlan, gSecondLandUnit, 0, 0, 200);
   aiPlanAddUnitType(gLandDefendPlan, gThirdLandUnit, 0, 0, 200);
   aiPlanAddUnitType(gLandDefendPlan, gFifthLandUnit, 0, 0, 200);
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      aiPlanAddUnitType(gLandDefendPlan, gFourthLandUnit, 0, 0, 200);
   }
   */

   // DEFINE THE PLANS

      int refreshFrequency = selectByDifficulty(1000, 1000, 300, 300, 300, 300);

      // PLAN 1 (Slow Attack Wave)
      int gDefensePlan1 = createDefendPlan("Defense Plan 1", kbBaseGetMainID(cMyID), 10, vector(161, 0, 203), 10);
      aiPlanSetVariableFloat(gDefensePlan1, cDefendPlanEngageRange, 0, 30);

      aiPlanAddUnitType(gDefensePlan1, gFirstLandUnit, 0, 0, 200); // Hypaspists
      aiPlanAddUnitType(gDefensePlan1, gThirdLandUnit, 0, 0, 200); // Toxotai
      aiPlanAddUnitType(gDefensePlan1, gFourthLandUnit, 0, 0, 200); // Petroboli

      // PLAN 2 (Fast Attack Wave)
      int gDefensePlan2 = createDefendPlan("Defense Plan 2", kbBaseGetMainID(cMyID), 10, vector(251.01, 0, 189.71), 10);
      aiPlanSetVariableFloat(gDefensePlan2, cDefendPlanEngageRange, 0, 30);

      aiPlanAddUnitType(gDefensePlan2, gSecondLandUnit, 0, 0, 200); // Hippeis
      aiPlanAddUnitType(gDefensePlan2, gFifthLandUnit, 0, 0, 200); // Nemean Lions

   // Keep the heroes near the gather point of the first attack wave.
   int heroDefendPlan = createDefendPlan("Hero Land Defend", kbBaseGetMainID(cMyID), 25.0, vector(175.0, 0.0, 201.0), 10);
   aiPlanAddUnitType(heroDefendPlan, gSixthLandUnit, 0, 0, 200);
   aiPlanAddUnitType(heroDefendPlan, gSeventhLandUnit, 0, 0, 200);
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      aiPlanAddUnitType(heroDefendPlan, gEighthLandUnit, 0, 0, 200);
   }

   // Start training Villagers.
   gMaxVillagerCount = 12;
   gMaxFishingShipCount = 4;

   gMaxVillagerCount *= gDifficultyModifierMaintainVillager;
   gMaxFishingShipCount *= gDifficultyModifierMaintainFishing;

   gOverrideMaxVillagerPop = gMaxVillagerCount;
   gOverrideMaxFishingShipPop = gMaxFishingShipCount;
   xsDisableRule("bootUpEconomy");

   // Move Temple gather point now, not earlier to avoid having Lions run into Piggies.
   aiUnitSetRallyPointToPosition(getUnit(cUnitTypeTemple), vector(251.0, 0.0, 190.0));
   return;
}

rule bootUpEconomy
active
minInterval 10
{
   int elapsed_time = xsGetTime();
   if (elapsed_time > 300)
   {
      gMaxVillagerCount = 12;
      gMaxFishingShipCount = 4;

      gMaxVillagerCount *= gDifficultyModifierMaintainVillager;
      gMaxFishingShipCount *= gDifficultyModifierMaintainFishing;

      gOverrideMaxVillagerPop = gMaxVillagerCount;
      gOverrideMaxFishingShipPop = gMaxFishingShipCount;
      xsDisableRule("bootUpEconomy");
   }
}