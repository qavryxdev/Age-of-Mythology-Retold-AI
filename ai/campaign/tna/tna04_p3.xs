//==============================================================================
/* tna04_p3.xs

   Pink Norse player that goes for a boom strategy using Berserks, Huskarls,
   and Mountain Giants.
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
float gValkyrieDelay = 30; // In seconds.



int gFirstLandUnit = cUnitTypeHirdman; // Trained from the beginning.
float gMaintainFirstLandUnitAmount = 7;
int gSecondLandUnit = cUnitTypeThrowingAxeman; // Trained from the beginning.
float gMaintainSecondLandUnitAmount = 7;
int gThirdLandUnit = cUnitTypeValkyrie; // Begins training once they reach the Heroic Age.
float gMaintainThirdLandUnitAmount = 3;   // Replaced the Valkyries with Frost Giants.
float gMaxVillagerCount = 12;
float gAttackStartDelay = 5; // Does not attack until there are Atlantean soldiers near Red's TC.
float gAttackWaveInterval = 240; // Time elapsed until they may send another SOS wave.
float gAttackStartSize = 6;
float gAttackMaxSize = 8;

float gHeroicAgeUpTime = 900; // In seconds. (15 minutes)  This was previously 20 minutes.
int gLandDefendPlan = -1;


Strategy scenarioAttackWaveStrategy()
{

   // Start enabling rules.
   xsEnableRule("researchCopperArmoryTechs");
   xsEnableRule("researchMediumInfantry");

   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugStrategy("***Starting Scenario Attack Wave Strategy***");
      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================

      if (cDifficultyCurrent >= cDifficultyHard)
      {
            gThirdLandUnit = cUnitTypeFrostGiant;
      }



      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;

      // gAttackStartDelay *= gDifficultyModifierFirstAttack; -- Not relevant, simply happens when Kastor attacks Red.
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;
      gValkyrieDelay *= gDifficultyModifierTrainDelay;
      gHeroicAgeUpTime *= gDifficultyModifierAgeUp;
      gHeroicAgeUpTime += xsGetTime(); // Offset for awake moment.


      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gValkyrieDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize); 
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);

      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      gAttackWave.addAttackUnitType(gThirdLandUnit);

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
      vector startPoint = vector(186.74, -2.77, 116.56); // In the southeast part of their base.
      vector targetPoint = vector(280.0, 0.0, 81.0); // Next to P1's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 start below the Town Center.");
      kbPathAddWaypoint(pathID1, startPoint);

      kbPathAddWaypoint(pathID1, vector(245.0, 0.0, 142.0)); // Purple Block #1.
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      gLandDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 30.0, startPoint, 10);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
      
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
      static bool heroic_done = false;

      // Don't Research Armory techs or Stone Wall on Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         xsEnableRule("researchCopperArmoryTechs");
         xsEnableRule("researchStoneWall");
      }

      // Only research Disablot on Hard and Titan.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         xsEnableRule("researchDisablot");
      }

      // Time to go to Heroic.
      if (age < cAge3 && xsGetTime() >= gHeroicAgeUpTime)
      {
         researchSimpleTech(cTechHeroicAgeSkadi, cUnitTypeTownCenter, -1, 75);
      }

      // We're in Heroic, now we can research Heroic techs.
      if (age >= cAge3 && heroic_done == false)
      {
         // Only research Heroic upgrades in Heroic.
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchHeavyInfantry");
            xsEnableRule("researchBronzeWeapons");
            xsEnableRule("researchBallistics");
         }
         // Only research Bronze Armor on Titan.
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchBronzeArmor");
         }
         heroic_done = true;
      }

      // We can't attack unless there are enemies near player 2.
      vector ally_tc = vector(273.0, -1.0, 89.0);
      static int numEnemies = 0;
      numEnemies = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, 1, cUnitStateAlive, ally_tc, 40.0);
      if (numEnemies >= 5)
      {
         xsEnableRule("UpdateAttack");
         
      }
   
      return true;
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

   gMainGatherBase = createOverrideGatherBase(vector(183.00, 0.00, 168.00), 51);

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

rule researchMediumInfantry
inactive
minInterval 180
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

rule researchDisablot
inactive
minInterval 360
{
   debugAttackWave("Starting Disablot research plan.");
   researchSimpleTech(cTechDisablot, cUnitTypeTemple, -1, 50);
   xsDisableRule("researchDisablot");
}

rule researchStoneWall
inactive
minInterval 360
{
   debugAttackWave("Starting Stone Wall research plan.");
   researchSimpleTech(cTechStoneWall, cUnitTypeWallGate, -1, 50);
   xsDisableRule("researchStoneWall");
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

rule researchHeavyInfantry
inactive
minInterval 240
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

rule researchBallistics
inactive
minInterval 50
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

rule UpdateAttack
inactive
{
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      xsSetRuleMinIntervalSelf(30);
   }
   if (cDifficultyCurrent <= cDifficultyModerate)
   {
      xsSetRuleMinIntervalSelf(180);
   }
   debugAttackWave("Updating the P3 Attack Plans");
   gAttackWave.update();
}