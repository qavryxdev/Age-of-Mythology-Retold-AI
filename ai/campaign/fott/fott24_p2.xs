//==============================================================================
/* fott24_p2.xs

   Canyon Giants (Loki)

   Red Norse player owning a sprawling base of Temples in the west part of the map. Once the player has
   established a base, they send attacks containing Mountain Giants and Frost Giants.

   When the giantWave() function is called, they send all of their units to attack the player base in one big swarm.
   This is in conjunction with them getting large reinforcement waves of giants by the edges of the map.
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

float gTrainDelay = 1; // In seconds.
int gFirstLandUnit = cUnitTypeMountainGiant; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 6;
int gSecondLandUnit = cUnitTypeFrostGiant; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 8;

float gMaxVillagerCount = 0;
float gAttackStartDelay = 120; // In seconds.
float gAttackWaveInterval = 360; // In Seconds.

float gAttackStartSize = 4;
float gAttackMaxSize = 4;

bool gCeaseAttacks = false;
float gGiantWaveAttackSize = 20.0;
float gGiantWaveAttackMaxSize = 40.0;

int gWakeUpTime = -1;

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;
      int gDefendPlan3 = -1;

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

      // Certain parameters are way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gMaintainFirstLandUnitAmount = 2; // 2 Mountain Giants
         gMaintainSecondLandUnitAmount = 3; // 3 Frost Giants

         gAttackStartDelay = 500; // First attack takes longer.
         gAttackWaveInterval = 600; // Attacks are infrequent.
         gAttackStartSize = 3;
         gAttackMaxSize = 3;
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;

      gWakeUpTime = xsGetTime();

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
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
      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(119.0, 1.0, 268.0); // In the western mountain path.
      vector targetPoint = vector(212.0, 1.0, 220.0); // Player's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID = kbPathCreate("Path Left");
      kbPathAddWaypoint(pathID, startPoint);
      kbPathAddWaypoint(pathID, vector(167.0, 1.0, 206.0));
      kbPathAddWaypoint(pathID, targetPoint);
      kbAttackRouteAddPath(routeID, pathID);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      /*
      // Defend the upper part of the western base.
      vector defendPoint = vector(131.0, 1.0, 302.0);
      float defendAmount = 4 * gDifficultyModifierMaintainUnit;
      int landDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 200.0, defendPoint, 10);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, defendAmount);

      // Defend the lower part of the western base.
      defendPoint = vector(80.0, 1.0, 260.0);
      defendAmount = 4 * gDifficultyModifierMaintainUnit;
      landDefendPlan = createDefendPlan("Secondary Land Defend", kbBaseGetMainID(cMyID), 500.0, defendPoint, 10);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, defendAmount);

      // Keep units in reserve in the western base.
      defendPoint = vector(110.0, 1.0, 307.0);
      landDefendPlan = createDefendPlan("Reserve Land Defend", kbBaseGetMainID(cMyID), 500.0, defendPoint, 1);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
      */

   // SPLIT AMOUNTS
      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 3; // Mountain Giants
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 3; // Frost Giants

   // DEFINE THE PLANS
      // Plan 1 (Guarding their southern gate)
      gDefendPlan1 = createDefendPlan("Defense Plan 1", kbBaseGetMainID(cMyID), 10, vector(81.0, 0.0, 261.0), 10);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan1, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Mountain Giants
      aiPlanAddUnitType(gDefendPlan1, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Frost Giants

      // Plan 2 (Guarding their northwestern gate)
      gDefendPlan2 = createDefendPlan("Defense Plan 2", kbBaseGetMainID(cMyID), 10, vector(109.0, 0.0, 341.0), 10);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan2, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Mountain Giants
      aiPlanAddUnitType(gDefendPlan2, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Frost Giants

      // Plan 3 (Guarding their northeastern gate)
      gDefendPlan3 = createDefendPlan("Defense Plan 3", kbBaseGetMainID(cMyID), 10, vector(159.0, 0.0, 323.0), 10);
      aiPlanSetVariableFloat(gDefendPlan3, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan3, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Mountain Giants
      aiPlanAddUnitType(gDefendPlan3, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Frost Giants

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;

      // * * * TECH RULES * * * //
      static bool tech_progressions = false;
      if (tech_progressions == false)
      {
         // Tech Rules for All Difficulties:
         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRuleGroup("ruleGroupUpgrades1");
         }
         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRuleGroup("ruleGroupUpgrades2");
         }
         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRuleGroup("ruleGroupUpgrades3");
         }
         tech_progressions = true;
      }

      // Train more Giants 750 seconds in, and not on Easy.
      static bool giant_increase_1 = false;
      if (giant_increase_1 == false)
      {
         if (cDifficultyCurrent >= cDifficultyModerate && xsGetTime() >= 750)
         {
            gMaintainFirstLandUnitAmount *= 1.50; // Train +50% Mountain Giants.
            gMaintainSecondLandUnitAmount *= 1.50; // Train +50% Frost Giants.
            data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
            data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
            gAttackMaxSize *= 1.20; // Increase attack size by +20%.
            giant_increase_1 = true;
         }
      }

      // Train more Giants 1500 seconds in, and only on Hard and Titan.
      static bool giant_increase_2 = false;
      if (giant_increase_2 == false)
      {
         if (cDifficultyCurrent >= cDifficultyHard && xsGetTime() >= 1500)
         {
            gMaintainFirstLandUnitAmount *= 1.50; // Train +50% Mountain Giants.
            gMaintainSecondLandUnitAmount *= 1.50; // Train +50% Frost Giants.
            data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
            data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
            gAttackMaxSize *= 1.20; // Increase attack size by +20%.
            giant_increase_2 = true;
         }
      }

      // Halt all future attacks if the giant wave has arrived.
      if (done == false && gCeaseAttacks == true)
      {
         done = true;

         // Put an end to the normal attacks by setting attack sizes to 0.
         gAttackWave.setAttackSize(0);
         gAttackWave.setMaxAttackSize(0);
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott24StrategySetup()
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
   setOverrideStrategy(fott24StrategySetup);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

void giantWave()
{
   debugAttackWave("Time to send the giant army of giants!");

   // Modify the attack wave updater to hinder default attacks the next time we run by this code.
   gCeaseAttacks = true;

   vector gatherPoint = vector(210.0, 1.47, 210.0); // Player's TC.
   vector targetPoint = vector(282.0, 4.0, 311.0); // Forest by the northern river.

   // Get the size of the giant wave, affected by the difficulty multiplier.
   float size = gGiantWaveAttackSize * gDifficultyModifierAttackSizeMultiplier;
   float maxSize = gGiantWaveAttackMaxSize * gDifficultyModifierAttackSizeMultiplier;
   debugAttackWave("Our wave size is " + size + "/" + maxSize + ", wowee that's a lot of units!");

   int giantWaveID = aiPlanCreate("Giant attack wave!", cPlanAttack);
   aiPlanAddUnitType(giantWaveID, cUnitTypeLogicalTypeLandMilitary, 0, size, maxSize, false);
   aiPlanSetVariableInt(giantWaveID, cAttackPlanTargetMode, 0, cAttackPlanTargetModePoint);
   aiPlanSetVariableInt(giantWaveID, cAttackPlanTargetPlayerID, 0, 1); // Attack Player 1!
   aiPlanSetVariableVector(giantWaveID, cAttackPlanTargetPoint, 0, targetPoint);
   aiPlanSetVariableVector(giantWaveID, cAttackPlanGatherPoint, 0, gatherPoint);
   aiPlanSetVariableFloat(giantWaveID, cAttackPlanGatherDistance, 0, 2000.0);
   aiPlanSetVariableFloat(giantWaveID, cAttackPlanAttackModeEngageRange, 0, 100.0);
   //aiPlanSetVariableInt(giantWaveID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
   //aiPlanSetVariableInt(giantWaveID, cAttackPlanAttackRouteID, 0, mAttackRouteID);
   aiPlanSetVariableInt(giantWaveID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeNoTarget);
   aiPlanSetPriority(giantWaveID, 90); // Very high priority. Use plenty of units.
   
   return;
}

// Get Jotuns after a certain amount of time (not Easy).
rule researchJotuns
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgrades1
{
   // Wait 1200 seconds on Moderate.
   if (cDifficultyCurrent == cDifficultyModerate)
   {
      if (xsGetTime() >= 1200 + gWakeUpTime)
      {
         researchSimpleTech(cTechJotuns, cUnitTypeTemple, -1, 60);
         xsDisableRule("researchJotuns"); // Disable self.
         return;
      }
   }
   // Wait 900 seconds on Hard.
   else if (cDifficultyCurrent == cDifficultyHard)
   {
      if (xsGetTime() >= 900 + gWakeUpTime)
      {
         researchSimpleTech(cTechJotuns, cUnitTypeTemple, -1, 60);
         xsDisableRule("researchJotuns"); // Disable self.
         return;
      }
   }
   // Wait 640 seconds on Titan.
   else if (cDifficultyCurrent == cDifficultyTitan)
   {
      if (xsGetTime() >= 640 + gWakeUpTime)
      {
         researchSimpleTech(cTechJotuns, cUnitTypeTemple, -1, 60);
         xsDisableRule("researchJotuns"); // Disable self.
         return;
      }
   }
}

// Get Rime after a certain amount of time (not Easy).
rule researchRime
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgrades1
{
   // Wait 1240 seconds on Moderate.
   if (cDifficultyCurrent == cDifficultyModerate)
   {
      if (xsGetTime() >= 1240 + gWakeUpTime)
      {
         researchSimpleTech(cTechRime, cUnitTypeTemple, -1, 60);
         xsDisableRule("researchRime"); // Disable self.
         return;
      }
   }
   // Wait 880 seconds on Hard.
   else if (cDifficultyCurrent == cDifficultyHard)
   {
      if (xsGetTime() >= 880 + gWakeUpTime)
      {
         researchSimpleTech(cTechRime, cUnitTypeTemple, -1, 60);
         xsDisableRule("researchRime"); // Disable self.
         return;
      }
   }
   // Get it via triggers on Titan.
   else if (cDifficultyCurrent == cDifficultyTitan)
   {
      xsDisableRule("researchRime"); // Disable self.
      return;
   }
}

// Get GraniteBlood after a certain amount of time (Hard and Titan only)
rule researchGraniteBlood
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgrades2
{
   // Wait 1280 seconds on Hard.
   if (cDifficultyCurrent == cDifficultyHard)
   {
      if (xsGetTime() >= 1280 + gWakeUpTime)
      {
         researchSimpleTech(cTechGraniteBlood, cUnitTypeTemple, -1, 60);
         xsDisableRule("researchGraniteBlood"); // Disable self.
         return;
      }
   }
   // Wait 920 seconds on Titan.
   else if (cDifficultyCurrent == cDifficultyTitan)
   {
      if (xsGetTime() >= 920 + gWakeUpTime)
      {
         researchSimpleTech(cTechGraniteBlood, cUnitTypeTemple, -1, 60);
         xsDisableRule("researchGraniteBlood"); // Disable self.
         return;
      }
   }
}

// Get Rampage after a certain amount of time (Titan only)
rule researchRampage
inactive
minInterval 10 // AI will attempt to get the technology every 10 seconds.
group ruleGroupUpgrades3
{
   // Wait 1800 seconds on Hard.
   if (cDifficultyCurrent == cDifficultyTitan)
   {
      if (xsGetTime() >= 1800 + gWakeUpTime)
      {
         researchSimpleTech(cTechRampage, cUnitTypeTemple, -1, 60);
         xsDisableRule("researchRampage"); // Disable self.
         return;
      }
   }
}