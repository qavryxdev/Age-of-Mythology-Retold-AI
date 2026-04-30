//==============================================================================
/* tna04_p4.xs

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

float gHuskarlDelay = 45; // In seconds.
float gGiantDelay = 75; // In seconds.

int gFirstLandUnit = cUnitTypeBerserk; // Trained from the beginning.
float gMaintainFirstLandUnitAmount = 8;
int gSecondLandUnit = cUnitTypeHuskarl; // Begins training once they reach the Heroic Age.
float gMaintainSecondLandUnitAmount = 10;
int gThirdLandUnit = cUnitTypeMountainGiant; // Begins training once they reach the Heroic Age.
float gMaintainThirdLandUnitAmount = 3;
float gMaxVillagerCount = 20;
float gAttackStartDelay = 1320; // In seconds.
float gAttackWaveInterval = 480; // In seconds.
float gAttackStartSize = 8;
float gAttackMaxSize = 12;
float gAttackSizeLimiter = 0; // Used to ensure that we don't try to use more soldiers for attacks than we maintain.

float gBaseAttackMaxSize = 12; // Used to calculate new values from increments before applying the multiplier.

float gHeroicAgeUpTime = 1200; // In seconds. (20 minutes)
int gLandDefendPlan = -1;

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;

Strategy scenarioAttackWaveStrategy()
{

   // Start enabling rules.
   xsEnableRule("researchCopperArmoryTechs");
   xsEnableRule("researchStoneWall");
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
      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gHuskarlDelay *= gDifficultyModifierTrainDelay;
      gGiantDelay *= gDifficultyModifierTrainDelay;
      gHeroicAgeUpTime *= gDifficultyModifierAgeUp;
      gHeroicAgeUpTime += xsGetTime(); // Offset for awake moment.

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);

      // Limit attack size to the amount of units we maintain (with modifier).
      gAttackSizeLimiter = gMaintainFirstLandUnitAmount;
      if (gAttackStartSize > gAttackSizeLimiter)
      {
         gAttackStartSize = gAttackSizeLimiter;
      }
      if (gAttackMaxSize > gAttackSizeLimiter)
      {
         gAttackMaxSize = gAttackSizeLimiter;
      }

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);

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
      vector startPoint = vector(18.0, 0.0, 245.0); // On top of the hill in the mountain pass.
      vector targetPoint = vector(34.0, 0.0, 86.0); // Next to P1's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 start below the Town Center.");
      kbPathAddWaypoint(pathID1, startPoint);

      kbPathAddWaypoint(pathID1, vector(37.0, 0.0, 178.0)); // Pink Block #1.
      kbPathAddWaypoint(pathID1, vector(144.0, 0.0, 164.0)); // Pink Block #2.
      kbPathAddWaypoint(pathID1, vector(245.0, 0.0, 142.0)); // Purple Block #1.
      kbPathAddWaypoint(pathID1, vector(199.0, 0.0, 43.0)); // Red Block #1.
      kbPathAddWaypoint(pathID1, vector(125.0, 0.0, 48.0)); // Red Block #2
      kbPathAddWaypoint(pathID1, vector(86.0, 0.0, 23.0)); // Red Block #3.
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
            // We will decide whether or not to increase the base maximum attack size (up to 15) each time we launch an attack.
            // Before we do this, we ensure we plan on maintaining enough units which can be utilized by this size increase.
            if ((gAttackSizeLimiter > gAttackMaxSize) &&
                (gBaseAttackMaxSize < 15))
            {
               gBaseAttackMaxSize = gBaseAttackMaxSize + 1; // Value to apply multiplier to.
               gAttackMaxSize = gBaseAttackMaxSize * gDifficultyModifierAttackSizes; // Multiplier applied.

               if (gAttackStartSize > gAttackSizeLimiter)
               {
                  gAttackStartSize = gAttackSizeLimiter;
               }
               if (gAttackMaxSize > gAttackSizeLimiter)
               {
                  gAttackMaxSize = gAttackSizeLimiter;
               }
               
               gAttackWave.setMaxAttackSize(gAttackMaxSize);

            }
         }
      );

   int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2; // Mountain Giants

   // DEFINE THE PLANS
      // Plan 1 (Hill)
      gDefendPlan1 = createDefendPlan("Defense Plan 1", kbBaseGetMainID(cMyID), 10, vector(15.0, 0.0, 231.0), 30);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 40);

      aiPlanAddUnitType(gDefendPlan1, gSecondLandUnit, 0, 0, 200); // Huskarls
      aiPlanAddUnitType(gDefendPlan1, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Mountain Giants

      // Plan 2 (TC Area)
      gDefendPlan2 = createDefendPlan("Defense Plan 2", kbBaseGetMainID(cMyID), 10, vector(109.0, 0.0, 289.0), 30);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 40);
      aiPlanAddUnitType(gDefendPlan2, gFirstLandUnit, 0, 0, 200); // Berserks
      aiPlanAddUnitType(gDefendPlan2, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Mountain Giants

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

      // Don't Research Armory techs on Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         xsEnableRule("researchCopperArmoryTechs");
      }

      // Time to go to Heroic.
      if (age < cAge3 && xsGetTime() >= gHeroicAgeUpTime)
      {
         researchSimpleTech(cTechHeroicAgeNjord, cUnitTypeTownCenter, -1, 75);
      }

      // We're in Heroic, now we can research Heroic techs.
      if (age >= cAge3 && heroic_done == false)
      {
         // Start training Huskarls and Mountain Giants as well as add them to our attack waves.
         data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
         data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
         data.setTrainDelay(gSecondLandUnit, gHuskarlDelay);
         data.setTrainDelay(gThirdLandUnit, gGiantDelay);
         gAttackSizeLimiter += gMaintainSecondLandUnitAmount;
         gAttackSizeLimiter += gMaintainThirdLandUnitAmount;
         gAttackWave.addAttackUnitType(gSecondLandUnit);
         gAttackWave.addAttackUnitType(gThirdLandUnit);

         // Only research Heroic upgrades in Heroic.
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchHeavyInfantry");
            xsEnableRule("researchBronzeWeapons");
            xsEnableRule("researchBronzeArmor");
            xsEnableRule("researchArchitects");
         }
         // Only research Bronze Armor and Jotuns on Titan.
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchBronzeShields");
            xsEnableRule("researchJotuns");
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

   gMainGatherBase = createOverrideGatherBase(vector(122.00, 0.00, 312.00), 102);

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

rule researchStoneWall
inactive
minInterval 360
{
   debugAttackWave("Starting Stone Wall research plan.");
   researchSimpleTech(cTechStoneWall, cUnitTypeWallGate, -1, 50);
   xsDisableRule("researchStoneWall");
}

rule researchJotuns
inactive
minInterval 360
{
   debugAttackWave("Starting Jotuns research plan.");
   researchSimpleTech(cTechJotuns, cUnitTypeTemple, -1, 50);
   xsDisableRule("researchJotuns");
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

rule researchArchitects
inactive
minInterval 180
{
   xsSetRuleMinIntervalSelf(10);
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

// Move defend plans (when nearby buildings are destroyed)
   void updateDefendPlan1()
   {
      // Nearby buildings are destroyed. We will move our defend plan further inward.
      aiPlanSetVariableVector(gDefendPlan1, cDefendPlanTargetPoint, 0, vector(151.0, 0.0, 245.0));
      aiPlanSetVariableVector(gDefendPlan1, cDefendPlanGatherPoint, 0, vector(151.0, 0.0, 245.0));
      aiEcho("Contracted our defense plan.");
   }