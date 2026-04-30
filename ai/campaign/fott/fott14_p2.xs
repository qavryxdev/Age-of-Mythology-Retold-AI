//==============================================================================
/* fott14_p2.xs

   Red Egyptian player owning the large base. Sends attacks of (Spearmen, Slingers, or Axemen), War Elephants,
   Priests, Myth Units (Scorpion Men, Wadjets), Scarabs, Son of Osiris
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
mutable void updateDefendPlans() {}

float gTrainDelay = 10; // In seconds.
float gPriestTrainDelay = 60; // In seconds.

int gFirstLandUnit = -1; // Gets trained from the start -> randomly decided between Barracks units.
float gMaintainFirstLandUnitAmount = 15;
int gSecondLandUnit = cUnitTypeWarElephant; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 6;
int gThirdLandUnit = cUnitTypePriest; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 1;
int gFourthLandUnit = -1; // Gets trained from the start -> randomly decided between Scorpion Man and Wadjet.
float gMaintainFourthLandUnitAmount = 3;
int gFifthLandUnit = cUnitTypeSiegeTower; // Gets trained from the start.
float gMaintainFifthLandUnitAmount = 1;
float gMaxVillagerCount = 15;
float gAttackStartDelay = 240; // In seconds.
float gAttackWaveInterval = 300; // In seconds.
float gAttackStartSize = 6;
float gAttackMaxSize = 16;
float gMythicAgeUpTime = 1500; // In seconds. (25 minutes)
int gLandDefendPlan = -1;
int gPatrolDefendPlan = -1;

Strategy scenarioAttackWaveStrategy()
{
   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugAttackWave("***Starting Scenario Attack Wave Strategy***");

      // This should never fail.
      xsEnableRule("useLocustSwarm");

      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================
      
      // Certain parameters are considerably tougher on Titan. (These parameters are pre-multiplier)
      if (cDifficultyCurrent == cDifficultyTitan)
      {
         gMaintainThirdLandUnitAmount = 2; // There are slightly more Priests to fight on the highest difficulty.
         gAttackStartDelay = 80; // Gargarensis is after you very quickly.
         gMythicAgeUpTime = 800; // Gargarensis clicks up to Mythic much sooner than on Hard.
         gAttackStartSize = 10; // First attack should be reasonably strong.
      }

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
      gMythicAgeUpTime = gMythicAgeUpTime * gDifficultyModifierAgeUp + xsGetTime();

      int random = xsRandInt(0, 2);
      if (random == 0)
      {
         gFirstLandUnit = cUnitTypeSpearman;
      }
      else if (random == 1)
      {
         gFirstLandUnit = cUnitTypeAxeman;
      }
      else // 2.
      {
         gFirstLandUnit = cUnitTypeSlinger;
      }

      if (xsRandBool() == true)
      {
         gFourthLandUnit = cUnitTypeWadjet;
      }
      else
      {
         gFourthLandUnit = cUnitTypeScorpionMan;
      }

// Certain parameters are way more lenient on Easy.
   if (cDifficultyCurrent == cDifficultyEasy)
   {
   // Fewer units trained.
      gMaintainFirstLandUnitAmount = 10; // 10 Barracks units
      gMaintainSecondLandUnitAmount = 5; // 5 War Elephants
      gMaintainThirdLandUnitAmount = 0; // No Priests - use as many myth units as you want.
      gMaintainFourthLandUnitAmount = 1; // 1 Wood Myth Unit
      gMaintainFifthLandUnitAmount = 1; // 1 Siege Tower

      // Don't attack too hard or frequently.
      // Early attack can be the same because the player starts with a whole bunch of myth units.
      gAttackWaveInterval = 600;

      // Weaker attacks (higher than previous missions due to infinite favor for myth units)
      gAttackStartSize = 5;
      gAttackMaxSize = 10;

      gMythicAgeUpTime = 2100;
   }

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      // No Priests on Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      }
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gPriestTrainDelay);

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
      // We don't attack with the Siege Towers we train.
      // We do however attack with the Scarabs we spawn with.
      gAttackWave.addAttackUnitType(cUnitTypeScarab);
      gAttackWave.displayFirstAttackStats();

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      
      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(182.0, 14.0, 119.0); // To the south of the forward Migdol Stronghold.
      vector targetPoint = vector(361.0, 8.0, 135.0); // P1's Citadel.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 right gate to pig pen");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(263.0, 13.0, 104.0)); // Walk through the right gate.
      kbPathAddWaypoint(pathID1, vector(270.0, 8.0, 62.0));
      kbPathAddWaypoint(pathID1, vector(334.0, 8.0, 59.0)); // Between P1's Migdols.
      kbPathAddWaypoint(pathID1, vector(342.0, 8.0, 182.0)); // To the Pig pen.
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
            static int counter = 0;
            counter++;
            // Add the new paths on the second iteration. The second attack can use these now.
            if (counter == 2)
            {
               vector startPointTemp = vector(182.0, 14.0, 119.0); // To the south of the forward Migdol Stronghold.
               vector targetPointTemp = vector(361.0, 8.0, 135.0); // P1's Citadel.

               int pathID2 = kbPathCreate("Path 2 center to Migdols");
               kbPathAddWaypoint(pathID2, startPointTemp);
               kbPathAddWaypoint(pathID2, vector(332.0, 9.0, 114.0)); // Walk through the center to the Armory.
               kbPathAddWaypoint(pathID2, vector(361.0, 8.0, 136.0)); // P1 Citadel.
               kbPathAddWaypoint(pathID2, vector(353.0, 8.0, 45.0)); // Right side P1 base.
               kbPathAddWaypoint(pathID2, targetPointTemp);
               kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID2);

               int pathID3 = kbPathCreate("Path 3 left gate to right side of base");
               kbPathAddWaypoint(pathID3, startPointTemp);
               kbPathAddWaypoint(pathID3, vector(248.0, 12.0, 168.0)); // Walk through the left gate.
               kbPathAddWaypoint(pathID3, vector(255.0, 7.0, 201.0));
               kbPathAddWaypoint(pathID3, vector(302.0, 8.0, 215.0));
               kbPathAddWaypoint(pathID3, vector(342.0, 8.0, 184.0));
               kbPathAddWaypoint(pathID3, vector(352.0, 8.0, 45.0)); // Starting position of the Osiris Piece Cart.
               kbPathAddWaypoint(pathID3, targetPointTemp);
               kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID3);
            }
         }
      );

      
      

      gLandDefendPlan = createDefendPlan("Primary Land Defend", -1, 20.0, startPoint, 20, startPoint);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
      aiPlanSetVariableFloat(gPatrolDefendPlan, cDefendPlanEngageRange, 0, 40.0);
      
      // Patrol plan.
      gPatrolDefendPlan = createDefendPlan("Patrol", -1, 40.0, vector(112.0, 12.0, 121.0),
                                           25, vector(112.0, 12.0, 121.0));
      aiPlanSetVariableFloat(gPatrolDefendPlan, cDefendPlanEngageRange, 0, 20.0);
      aiPlanAddUnitType(gPatrolDefendPlan, cUnitTypePharaoh, 0, 200, 200);
      aiPlanAddUnitType(gPatrolDefendPlan, cUnitTypeSonOfOsiris, 0, 200, 200);
      aiPlanAddUnitType(gPatrolDefendPlan, cUnitTypeSiegeTower, 0, 200, 200);
      aiPlanAddUnitType(gPatrolDefendPlan, cUnitTypeAnimalOfSet, 0, 200, 200);
      aiPlanSetVariableBool(gPatrolDefendPlan, cDefendPlanGatherWaitForAllUnits, 0, true);
      aiPlanSetVariableBool(gPatrolDefendPlan, cDefendPlanPatrol, 0, true);
      aiPlanSetNumberVariableValues(gPatrolDefendPlan, cDefendPlanPatrolWaypoints, 5);
      aiPlanSetVariableVector(gPatrolDefendPlan, cDefendPlanPatrolWaypoints, 0, vector(112.0, 12.0, 121.0));
      aiPlanSetVariableVector(gPatrolDefendPlan, cDefendPlanPatrolWaypoints, 1, vector(186.0, 14.0, 135.0)); // North of Migdol
      aiPlanSetVariableVector(gPatrolDefendPlan, cDefendPlanPatrolWaypoints, 2, vector(244.0, 14.0, 118.0));
      aiPlanSetVariableVector(gPatrolDefendPlan, cDefendPlanPatrolWaypoints, 3, vector(191.0, 14.0, 106.0)); // South of Migdol
      aiPlanSetVariableVector(gPatrolDefendPlan, cDefendPlanPatrolWaypoints, 4, vector(112.0, 12.0, 121.0));

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      static bool needResearchMythic = true;
      static bool reachedMythic = false;

      int age = kbPlayerGetAge(cMyID);
      int time = xsGetTime();
      if (needResearchMythic == true && kbPlayerGetAge(cMyID) < cAge4 && xsGetTime() >= gMythicAgeUpTime)
      {
         if (researchSimpleTech(cTechMythicAgeThoth, cUnitTypeCitadelCenter, -1, 60) == true)
         {
            debugAttackWave("Starting Mythic Age research plan.");
            needResearchMythic = false;
         }
      }
      if (done == false && kbPlayerGetAge(cMyID) == cAge4)
      {
         done = true;

         // Remove train plans for our previous choices, but allow utilizing remainders in future attack waves.
         data.removeUnitToMaintain(gFirstLandUnit);
         data.removeUnitToMaintain(gFourthLandUnit);

         gFourthLandUnit = gFourthLandUnit == cUnitTypeWadjet ? cUnitTypeScorpionMan : cUnitTypeWadjet;

         data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
         data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
         gAttackWave.addAttackUnitType(gFirstLandUnit);
         gAttackWave.addAttackUnitType(gFourthLandUnit);
      }

      // Rain
      static bool used_rain = false;
      if (used_rain == false && time >= 360)
      {
         aiCastGodPowerAtPosition(cProtoPowerRain, vector(95.0, 0.0, 173.0));
         used_rain = true;
      }

      // * * * TECH RULES * * * //
      static bool heroic_techs = false;

      // HEROIC AGE //
      if (age >= cAge3 && heroic_techs == false)
      {
         // Tech Rules for All Difficulties:
         xsEnableRule("researchBronzeWeapons");

         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchHeavyWarElephants");
            xsEnableRule("researchBronzeArmor");
            xsEnableRule("researchBronzeShields");
            xsEnableRule("researchBallistics");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchTusksOfApedemak");
         }

         // Tech Rules for Titan only:
         heroic_techs = true;
      }

      // MYTHIC AGE //
      if (age >= cAge3 && reachedMythic == false)
      {
         // Tech Rules for All Difficulties:
            xsEnableRule("researchQuarry");
            xsEnableRule("researchFloodControl");

         // Tech Rules for Moderate and Up:
         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchEngineers");
            xsEnableRule("researchBallistaTower");
            xsEnableRule("researchConscriptMigdolSoldiers");
         }
         // Tech Rules for Titan only:
         // Change the boolean back to true so the rules aren't enabled multiple times.
         reachedMythic = true;
      }

      // Once we lose our forward Migdol Stronghold we're meant to no longer attack.
      static bool migdolDead = false;
      if (migdolDead == false && getUnitCountByLocation(cUnitTypeMigdolStronghold, cMyID, cUnitStateAlive,
                                                        vector(193.0, 0.0, 118.0), 5.0) == 1)
      {
         gAttackWave.update();
      }
      else
      {
         if (migdolDead == false)
         {
            migdolDead = true;
            debugAttackWave("We've lost our foward Migdol! Stopping all attacks.");
            updateDefendPlans();
         }
      }

      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott14StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(51.00, 0.00, 201.00), 80);
   createOverrideGatherBase(vector(68.00, 0.00, 122.00), 80);
   createOverrideGatherBase(vector(80.00, 0.00, 249.00), 30);
   createOverrideGatherBase(vector(86.00, 0.00, 207.00), 30);
   gTimeToFarm = true;

   gOverrideMaxVillagerPop = gMaxVillagerCount;
   setOverrideStrategy(fott14StrategySetup);

   gRBDSystem.setMaxFarmsPerBase(32);
   gRBDSystem.setMaxFarmsPerIteration(32);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// Use Locust Swarm while attacking and P1 has more than 6 Farms in sight.
rule useLocustSwarm
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
            int queryID = useSimpleUnitQuery(gFarmUnit, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 15.0);
            numEnemies = kbUnitQueryExecute(queryID);
            debugAttackWave("numEnemies for casting Locust Swarm: " + numEnemies);
            if (numEnemies >= 6)
            {
               if (aiCastGodPowerAtPosition(cProtoPowerLocustSwarm, kbUnitGetPosition(kbUnitQueryGetResult(queryID, 0))) == true)
               {
                  debugAttackWave("Casted Locust Swarm!");
                  xsDisableRule("useLocustSwarm");
               }
            }
         }
      }
   }
}

void updateDefendPlans()
{
   // We move it to in front of our Citadel that's not on the hill.
   aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanTargetPoint, 0, vector(99.0, 5.0, 161.0));
   aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanGatherPoint, 0, vector(99.0, 5.0, 161.0));
   debugAttackWave("Moved our defend plan towards our Citadel Centers.");
   aiPlanDestroy(gPatrolDefendPlan);
   debugAttackWave("Deleted our patrol plan.");
}

// TECH RULES //

rule researchHeavyWarElephants
inactive
minInterval 300
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechHeavyWarElephants) == cTechStatusActive)
   {
      xsDisableRule("researchHeavyWarElephants");
      return;
   }
   else if (kbTechGetStatus(cTechHeavyWarElephants) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Heavy War Elephants research plan.");
      researchSimpleTech(cTechHeavyWarElephants, cUnitTypeMigdolStronghold, -1, 60);
      return;
   }
}

rule researchTusksOfApedemak
inactive
minInterval 240
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechTusksOfApedemak) == cTechStatusActive)
   {
      xsDisableRule("researchTusksOfApedemak");
      return;
   }
   else if (kbTechGetStatus(cTechTusksOfApedemak) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Tusks of Apedemak research plan.");
      researchSimpleTech(cTechTusksOfApedemak, cUnitTypeMigdolStronghold, -1, 60);
      return;
   }
}

rule researchEngineers
inactive
minInterval 180
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechEngineers) == cTechStatusActive)
   {
      xsDisableRule("researchEngineers");
      return;
   }
   else if (kbTechGetStatus(cTechEngineers) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Engineers research plan.");
      researchSimpleTech(cTechEngineers, cUnitTypeSiegeWorks, -1, 60);
      return;
   }
}

rule researchBallistaTower
inactive
minInterval 270
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechBallistaTower) == cTechStatusActive)
   {
      xsDisableRule("researchBallistaTower");
      return;
   }
   else if (kbTechGetStatus(cTechBallistaTower) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Ballista Tower research plan.");
      researchSimpleTech(cTechBallistaTower, cUnitTypeSentryTower, -1, 60);
      return;
   }
}

rule researchBronzeWeapons
inactive
minInterval 120
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

rule researchBronzeArmor
inactive
minInterval 240
{
   xsSetRuleMinIntervalSelf(10);
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

rule researchBronzeShields
inactive
minInterval 360
{
   xsSetRuleMinIntervalSelf(10);
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

rule researchIronWeapons
inactive
minInterval 320
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechIronWeapons) == cTechStatusActive)
   {
      xsDisableRule("researchIronWeapons");
      return;
   }
   else if (kbTechGetStatus(cTechIronWeapons) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Iron Weapons research plan.");
      researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 60);
      return;
   }
}

rule researchBallistics
active
minInterval 300
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

// *** MYTHIC AGE UPGRADES *** //
   // MODERATE AND UP
         // Quarry
            rule researchQuarry
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
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
                  researchSimpleTech(cTechQuarry, cUnitTypeMiningCamp, -1, 60);
                  return;
               }
            }
         // Flood Control
            rule researchFloodControl
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
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
                  researchSimpleTech(cTechFloodControl, cUnitTypeGranary, -1, 60);
                  return;
               }
            }
            // Conscript Migdol Soldiers
            rule researchConscriptMigdolSoldiers
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechConscriptMigdolSoldiers) == cTechStatusActive)
               {
                  xsDisableRule("researchConscriptMigdolSoldiers");
                  return;
               }
               else if (kbTechGetStatus(cTechConscriptMigdolSoldiers) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Conscript Migdol Soldiers research plan.");
                  researchSimpleTech(cTechConscriptMigdolSoldiers, cUnitTypeMigdolStronghold, -1, 60);
                  return;
               }
            }