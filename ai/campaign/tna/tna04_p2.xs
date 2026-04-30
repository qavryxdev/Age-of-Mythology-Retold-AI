//==============================================================================
/* tna04_p2.xs

   Red Norse player that goes for an aggressive strategy using Norse cavalry and Einherjars.
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
float gEinherjarDelay = 90; // In seconds.
float gJarlDelay = 45; // In seconds.

int gFirstLandUnit = cUnitTypeRaidingCavalry; // Begins training once they reach the Classical Age.
float gMaintainFirstLandUnitAmount = 8;
int gSecondLandUnit = cUnitTypeEinheri; // Begins training once they reach the Classical Age.
float gMaintainSecondLandUnitAmount = 2;
int gThirdLandUnit = cUnitTypeJarl; // Begins training once they reach the Heroic Age.
float gMaintainThirdLandUnitAmount = 8;
float gMaxVillagerCount = 15;
float gAttackStartDelay = 120; // In seconds. This is what the multiplier is applied to, then 300 seconds are.
float gAttackWaveInterval = 180; // In seconds.
float gAttackStartSize = 4;
float gAttackMaxSize = 8;

float gInitialAttackStartSize = 4; // Used to calculate new values from increments before applying the multiplier.
float gInitialAttackMaxSize = 8; // Used to calculate new values from increments before applying the multiplier.

float gClassicalAgeUpTime = 180; // In seconds. (3 minutes)
float gHeroicAgeUpTime = 1200; // In seconds. (20 minutes)
int gLandDefendPlan = -1;

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;

Strategy scenarioAttackWaveStrategy()
{

   // Start enabling rules.
   // There are no rules right now.

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
      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;

      // The multiplier here needs to apply strictly to the two minutes after the first five (when Forest Fire is casted).
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackStartDelay += xsGetTime();
      gAttackStartDelay += 240; // It takes 4 minutes for Player 6 to invoke Forest Fire.

      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;
      gEinherjarDelay *= gDifficultyModifierTrainDelay;
      gJarlDelay *= gDifficultyModifierTrainDelay;
      // Classical Age time is the same on all difficulties.
      gClassicalAgeUpTime += xsGetTime(); // Offset for awake moment.
      gHeroicAgeUpTime *= gDifficultyModifierAgeUp;
      gHeroicAgeUpTime += xsGetTime(); // Offset for awake moment.


      // Set units to maintain from the start of the game.
      // We're not maintaining anything until we get out of Archaic.

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gEinherjarDelay);
      data.setTrainDelay(gThirdLandUnit, gJarlDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      // gAttackWave.addAttackUnitType(gFirstLandUnit);
      // gAttackWave.addAttackUnitType(gSecondLandUnit);
      // gAttackWave.addAttackUnitType(gThirdLandUnit);

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticOxCartTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(201.0, 0.0, 41.0); // Below the Relic.
      vector targetPoint = vector(34.0, 0.0, 86.0); // Next to P1's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 start below the Town Center.");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(141.0, 0.0, 49.0)); // Block #1.
      kbPathAddWaypoint(pathID1, vector(125.0, 0.0, 48.0)); // Block #2
      kbPathAddWaypoint(pathID1, vector(86.0, 0.0, 23.0)); // Block #3.
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
            static int counter = 0;
            static int old_counter = 0;
            counter++;
            if (counter >= counter + 1)
            {
               // We will decide whether or not to increase the attack size each time we launch an attack.
               // The amount goes up 4 times. (base Start reaches 8, base Max reaches 12)
               if (counter <= 5)
               {
                  gInitialAttackStartSize = gInitialAttackStartSize + 1; // Value to apply multiplier to.
                  gInitialAttackMaxSize = gInitialAttackMaxSize + 1; // Value to apply multiplier to.

                  gAttackStartSize = gInitialAttackStartSize * gDifficultyModifierAttackSizes; // Multiplier applied.
                  gAttackMaxSize = gInitialAttackMaxSize * gDifficultyModifierAttackSizes; // Multiplier applied.
               }
            }
            old_counter = counter;

         }
      );

      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 2; // Einheri

   // DEFINE THE PLANS
      // Plan 1 (Hill)
      gDefendPlan1 = createDefendPlan("Defense Plan 1", kbBaseGetMainID(cMyID), 15, vector(155.0, 0.0, 53.0), 30);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 45);
      // Don't add Raiding Cavalry to the defend plan until after the Forest Fire army dies.
      aiPlanAddUnitType(gDefendPlan1, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Einheri

      // Plan 2 (TC Area)
      gDefendPlan2 = createDefendPlan("Defense Plan 2", kbBaseGetMainID(cMyID), 15, vector(267.0, 0.0, 73.0), 30);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 45);
      aiPlanAddUnitType(gDefendPlan2, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Einheri
      aiPlanAddUnitType(gDefendPlan2, gThirdLandUnit, 0, 0, 200); // Jarls

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      int age = kbPlayerGetAge(cMyID);
      static bool classical_done = false;
      static bool heroic_done = false;

      // Time to go to Classical.
      if (age < cAge2 && xsGetTime() >= gClassicalAgeUpTime)
      {
         researchSimpleTech(cTechClassicalAgeHeimdall, cUnitTypeTownCenter, -1, 75);
      }
      // We're in Classical, now we can add Einherjars to our attack plan.
      if (age >= cAge2 && classical_done == false)
      {
         data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
         data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
         xsEnableRule("researchMediumCavalry");

         // Don't Research Armory techs on Easy.
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchCopperArmoryTechs");
         }

         // Only research Gjallarhorn on Titan.
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchGjallarhorn");
         }

         // Don't include Raiding Cavalry until the Forest Fire army dies.
         gAttackWave.addAttackUnitType(gSecondLandUnit);
         classical_done = true;
      }

      // Time to go to Heroic.
      if (age < cAge3 && xsGetTime() >= gHeroicAgeUpTime)
      {
         researchSimpleTech(cTechHeroicAgeSkadi, cUnitTypeTownCenter, -1, 75);
      }
      // We're in Heroic, now we can add Jarls to our attack plan.
      if (age >= cAge3 && heroic_done == false)
      {
         data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
         gAttackWave.addAttackUnitType(gThirdLandUnit);
         // Only research Heroic upgrades in Heroic.
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchHeavyCavalry");
            xsEnableRule("researchBronzeWeapons");
         }
         // Only research Bronze Shields on Titan.
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchBronzeShields");
         }

         heroic_done = true;
      }
      
      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void tna04StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(299.00, 0.00, 68.00), 84);

   gOverrideMaxVillagerPop = gMaxVillagerCount;
   setOverrideStrategy(tna04StrategySetup);

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

// Currently, we have no rules.

// Add Raiding Cavalry to the AI's defense plan once the Forest Fire horsemen are slain.
rule RaidingCavalryDefend
inactive
minInterval 5
{
   aiPlanAddUnitType(gDefendPlan1, cUnitTypeRaidingCavalry, 0, 0, 200);
   gAttackWave.addAttackUnitType(gFirstLandUnit);
   gAttackWave.update();
   xsDisableRule("RaidingCavalryDefend");
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

rule researchGjallarhorn
inactive
minInterval 360
{
   debugAttackWave("Starting Copper Weapons/Armor research plans.");
   researchSimpleTech(cTechGjallarhorn, cUnitTypeTemple, -1, 50);
   xsDisableRule("researchGjallarhorn");
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
minInterval 300
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

rule researchBronzeWeapons
inactive
minInterval 150
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

// Move defend plans (when nearby buildings are destroyed)
   void updateDefendPlan1()
   {
      // Nearby buildings are destroyed. We will move our defend plan further inward.
      aiPlanSetVariableVector(gDefendPlan1, cDefendPlanTargetPoint, 0, vector(285.0, 0.0, 113.0));
      aiPlanSetVariableVector(gDefendPlan1, cDefendPlanGatherPoint, 0, vector(285.0, 0.0, 113.0));
      aiEcho("Contracted our defense plan.");
   }