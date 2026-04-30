//==============================================================================
/* fott04_p4.xs

   Purple Greek player owning the base in the east. Sends attacks of Toxotes and Triremes.
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

int gFirstLandUnit = cUnitTypeToxotes; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 15;
int gFirstNavalUnit = cUnitTypeTrireme; // Gets trained instantly.
float gTrainDelay = 0;
float gMaintainFirstNavalUnitAmount = 5;
float gMaxVillagerCount = 8;
float gMaxFishingShipCount = 2;
float gAttackStartDelay = 480; // In seconds.
float gAttackWaveInterval = 480; // In Seconds.
float gAttackStartSize = 6;
float gAttackMaxSize = 12;

float gHeroicAgeUpTime = 600; // In seconds.

float gNavalAttackStartDelay = 240; // In seconds.
float gNavalAttackWaveInterval = 480; // In Seconds.
float gNavalAttackStartSize = 2;
float gNavalAttackMaxSize = 4;

Strategy scenarioAttackWaveStrategy()
{
   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugAttackWave("***Starting Scenario Attack Wave Strategy***");
      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================
      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFirstNavalUnitAmount *= gDifficultyModifierMaintainUnit;
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gTrainDelay = 12;
      }
      gTrainDelay *= gDifficultyModifierTrainDelay;

      gNavalAttackStartDelay *= gDifficultyModifierFirstAttack;
      gNavalAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gNavalAttackStartSize *= gDifficultyModifierAttackSizes;
      gNavalAttackMaxSize *= gDifficultyModifierAttackSizes;

      gHeroicAgeUpTime = gHeroicAgeUpTime * gDifficultyModifierAgeUp + xsGetTime();

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gFirstNavalUnit, gMaintainFirstNavalUnitAmount);
      data.setTrainDelay(gFirstNavalUnit, gTrainDelay);

      // Details about the attack waves.

      // Don't dispatch land attacks on Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         gAttackWave.setName("gAttackWave");
         gAttackWave.setAttackStartTime(gAttackStartDelay);
         gAttackWave.setAttackInterval(gAttackWaveInterval);
         gAttackWave.setAttackSize(gAttackStartSize);
         gAttackWave.setMaxAttackSize(gAttackMaxSize);
         gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
         gAttackWave.addAttackUnitType(gFirstLandUnit);

         debugAttackWave("Land Attack Times:");
         gAttackWave.displayFirstAttackStats();
      }

      // Don't dispatch naval attacks on Easy or Moderate.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gNavalAttackWave.setName("gNavalAttackWave");
         gNavalAttackWave.setAttackStartTime(gNavalAttackStartDelay);
         gNavalAttackWave.setAttackInterval(gNavalAttackWaveInterval);
         gNavalAttackWave.setAttackSize(gNavalAttackStartSize);
         gNavalAttackWave.setMaxAttackSize(gNavalAttackMaxSize);
         gNavalAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
         gNavalAttackWave.addAttackUnitType(gFirstNavalUnit);
         gNavalAttackWave.setIsNavalAttackWave();
         
         debugAttackWave("Naval Attack Times:");
         gNavalAttackWave.displayFirstAttackStats();
      }

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticFishing, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!
      gNavalAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(268.0, 8.0, 41.0); // Above the AI's TC.
      vector targetPoint = vector(91.0, 0.0, 100.0); // Near the player's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(272.0, 0.0, 152.0));
      kbPathAddWaypoint(pathID1, vector(170.0, 0.0, 136.0));
      kbPathAddWaypoint(pathID1, vector(92.0, 0.0, 118.0));
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

      // Where does our attack start and end.
      vector navalStartPoint = vector(210.0, 0.0, 26.0); // Below the AI's Docks.
      vector navalTargetPoint = vector(60.0, 0.0, 21.0); // Near the player's southern Dock.

      int routeID2 = kbCreateAttackRouteWithPath("Route To P1 Dock", navalStartPoint, navalTargetPoint);
      int pathID2 = kbPathCreate("Path 2");
      kbPathAddWaypoint(pathID2, navalStartPoint);
      kbPathAddWaypoint(pathID2, vector(131.0, 0.0, 34.0));
      kbPathAddWaypoint(pathID2, navalTargetPoint);
      kbAttackRouteAddPath(routeID2, pathID2);

      gNavalAttackWave.setGatherPoint(navalStartPoint);
      gNavalAttackWave.setTargetPoint(navalTargetPoint);
      gNavalAttackWave.setAttackRouteID(routeID2);
      gNavalAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      aiUnitSetRallyPointToPosition(getUnit(cUnitTypeArcheryRange), startPoint);
      int landDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 15.0, startPoint, 10);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
      
      int waterDefendPlan = createDefendPlan("Water Defend Plan", -1, 15, navalStartPoint, 1, navalStartPoint);
      aiPlanAddUnitType(waterDefendPlan, cUnitTypeLogicalTypeNavalMilitary, 0, 0, 200);
      
      // Patrol plan.
      int waterPatrolPlan = createDefendPlan("Water Patrol Plan", -1, 5.0, vector(198.0, 0.0, 42.0), 15, vector(198.0, 0.0, 42.0));
      aiPlanAddUnitType(waterPatrolPlan, cUnitTypeLogicalTypeNavalMilitary, 0, 0, 200);
      aiPlanSetVariableBool(waterPatrolPlan, cDefendPlanPatrol, 0, true);
      aiPlanSetNumberVariableValues(waterPatrolPlan, cDefendPlanPatrolWaypoints, 2);
      aiPlanSetVariableVector(waterPatrolPlan, cDefendPlanPatrolWaypoints, 0, vector(198.0, 0.0, 42.0));
      aiPlanSetVariableVector(waterPatrolPlan, cDefendPlanPatrolWaypoints, 1, vector(206.0, 0.0, 16.0));
      aiPlanSetPriority(waterPatrolPlan, 10); // Very low priority, don't steal from attack plans.

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      static bool needResearchHeroic = true;
      static bool reachedHeroic = false;

      int age = kbPlayerGetAge(cMyID);

      int time = xsGetTime();

      // Only age up on Hard and Titan.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         if (done == false)
         {
            if (needResearchHeroic == true && age == cAge2 && time >= gHeroicAgeUpTime)
            {
               if (researchSimpleTech(cTechHeroicAgeApollo, cUnitTypeTownCenter, -1, 75) == true)
               {
                  debugAttackWave("Starting Heroic Age research plan.");
                  needResearchHeroic = false;
               }
            }
            else if (age == cAge3)
            {
               done = true;
            }
         }
      }

      // * * * TECH RULES * * * //

      static bool initial_techs = false;
      // CLASSICAL AGE //
      if (age >= cAge2 && initial_techs == false)
      {
         // Techs for all difficulties:

         // Tech Rules for Moderate and Up (Copper Armory techs already researched on Titan):
         if (cDifficultyCurrent >= 1 && cDifficultyCurrent != cDifficultyTitan)
         {
            xsEnableRule("researchCopperWeapons");
            xsEnableRule("researchMasons");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchPurseSeine");
         }

         // Tech Rules for Titan only:

         // Only Hard:
         if (cDifficultyCurrent == cDifficultyHard)
         {
            xsEnableRule("researchCopperArmor");
            xsEnableRule("researchCopperShields");
         }
         initial_techs = true;
      }

      // HEROIC AGE //
      if (reachedHeroic == false && kbPlayerGetAge(cMyID) == cAge3)
      {
         // Tech Rules for All Difficulties:
         // Tech Rules for Moderate and Up:

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchBronzeWeapons");
            xsEnableRule("researchHeavyArchers");
            xsEnableRule("researchBoilingOil");
            xsEnableRule("researchLevyRangedSoldiers");
            xsEnableRule("researchArchitects");
            xsEnableRule("researchBowSaw");
            xsEnableRule("researchShaftMine");
         }

         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchBronzeArmor");
            xsEnableRule("researchBronzeShields");
            xsEnableRule("researchFortifiedTownCenter");
            xsEnableRule("researchGuardTower");
            xsEnableRule("researchSunRay");
         }

         // Change the boolean back to true so the rules aren't enabled multiple times.
         reachedHeroic = true;
      }

      gNavalAttackWave.update();
      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott04StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(248.00, 0.00, 41.00), 61);
   gOverrideClosestFishLocation = vector(190.00, 0.00, 44.00);

   setOverrideStrategy(fott04StrategySetup);

   gOverrideFarmCount = 10; // Just don't make too many cuz we don't need them that much.
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// TECH RULES //

rule researchCopperWeapons
inactive
minInterval 300
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

rule researchCopperArmor
inactive
minInterval 420
{
   xsSetRuleMinIntervalSelf(10);
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

rule researchCopperShields
inactive
minInterval 600
{
   xsSetRuleMinIntervalSelf(10);
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

rule researchMasons
inactive
minInterval 400
{
   xsSetRuleMinIntervalSelf(10);
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

rule researchHeavyArchers
active
minInterval 210
{
   xsSetRuleMinIntervalSelf(10);
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

rule researchGuardTower
inactive
minInterval 150
{
   xsSetRuleMinIntervalSelf(10);
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

rule researchBoilingOil
inactive
minInterval 240
{
   xsSetRuleMinIntervalSelf(10);
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

rule researchArchitects
inactive
minInterval 120
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

rule researchFortifiedTownCenter
inactive
minInterval 180
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

rule researchSunRay
active
minInterval 480
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechSunRay) == cTechStatusActive)
   {
      xsDisableRule("researchSunRay");
      return;
   }
   else if (kbTechGetStatus(cTechSunRay) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Sun Ray research plan.");
      researchSimpleTech(cTechSunRay, cUnitTypeArcheryRange, -1, 60);
      return;
   }
}

rule researchPurseSeine
active
minInterval 300
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechPurseSeine) == cTechStatusActive)
   {
      xsDisableRule("researchPurseSeine");
      return;
   }
   else if (kbTechGetStatus(cTechPurseSeine) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Purse Seine research plan.");
      researchSimpleTech(cTechPurseSeine, cUnitTypeDock, -1, 60);
      return;
   }
}

rule researchBowSaw
active
minInterval 30
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechBowSaw) == cTechStatusActive)
   {
      xsDisableRule("researchBowSaw");
      return;
   }
   else if (kbTechGetStatus(cTechBowSaw) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Bow Saw research plan.");
      researchSimpleTech(cTechBowSaw, cUnitTypeLumberCamp, -1, 60);
      return;
   }
}

rule researchShaftMine
active
minInterval 30
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechShaftMine) == cTechStatusActive)
   {
      xsDisableRule("researchShaftMine");
      return;
   }
   else if (kbTechGetStatus(cTechShaftMine) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Shaft Mine research plan.");
      researchSimpleTech(cTechShaftMine, cUnitTypeMiningCamp, -1, 60);
      return;
   }
}

rule researchLevyRangedSoldiers
active
minInterval 110
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechLevyRangedSoldiers) == cTechStatusActive)
   {
      xsDisableRule("researchLevyRangedSoldiers");
      return;
   }
   else if (kbTechGetStatus(cTechLevyRangedSoldiers) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Levy Ranged Soldiers research plan.");
      researchSimpleTech(cTechLevyRangedSoldiers, cUnitTypeArcheryRange, -1, 60);
      return;
   }
}