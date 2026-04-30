//==============================================================================
/* tgg11_p7.xs
   
   Citadel of Krios (Kronos)

   Description

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

float gTrainDelay = 20; // In seconds.

int gFirstLandUnit = cUnitTypeDestroyer; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 4;
int gSecondLandUnit = cUnitTypeContarius; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 4;
int gThirdLandUnit = cUnitTypeAutomaton; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 3;
int gFourthLandUnit = cUnitTypeFanatic; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 4;
int gFifthLandUnit = cUnitTypeSatyr; // Gets trained from the start.
float gMaintainFifthLandUnitAmount = 2;
int gSixthLandUnit = cUnitTypeFireSiphon; // Gets trained from the start.
float gMaintainSixthLandUnitAmount = 1;

float gMaxVillagerCount = 12;  // 10 Citizens.

float gAttackStartDelayLong = cWaitWithAttacking; // In seconds.
float gAttackStartDelay = 300; // In seconds.
float gAttackWaveInterval = 300; // In seconds.
float gAttackStartSize = 8;
float gAttackMaxSize = 12;

bool gAllowedToAttack = false;

vector gOurTCLocation = vector(281.0, 0.0, 113.0);


Strategy scenarioAttackWaveStrategy()
{

   xsEnableRule("enemiesInMyBase");

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
         gAttackStartDelay = 600; // In seconds.
         gAttackWaveInterval = 600; // In seconds.
         gAttackStartSize = 4;
         gAttackMaxSize = 6;
      }

      // Hard and Titan parameters are much less forgiving.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gTrainDelay = 0;
         // Start attacking pretty much immediately, since Kastor already has a decent army.
         gAttackStartDelay = 10; // In seconds.
         // Super frequent intervals are most faithful to legacy.
         gAttackWaveInterval = 120; // In seconds.
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

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Destroyer
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Arcus
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Automaton
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Fanatic
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount); // Satyr
      data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount); // Fire Siphon
   
      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);
      data.setTrainDelay(gFifthLandUnit, gTrainDelay);
      data.setTrainDelay(gFifthLandUnit, gTrainDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelayLong);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);  // Destroyer
      gAttackWave.addAttackUnitType(gSecondLandUnit); // Arcus
      gAttackWave.addAttackUnitType(gThirdLandUnit);  // Automaton
      gAttackWave.addAttackUnitType(gFourthLandUnit);  // Fanatic
      gAttackWave.addAttackUnitType(gFifthLandUnit);  // Satyr
      gAttackWave.addAttackUnitType(gSixthLandUnit);  // Fire Siphon

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      
      /*
      if (cDifficultyCurrent >= cDifficultyHard)
      {
            gAttackStartSize = 10;
            gAttackMaxSize = 15;
      }
      */

      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);

      gAttackWave.setPlayerToAttack(1); // Attack P1!

      // Where does our attack start and end.
      vector startPoint = vector(223.0, 0.0, 191.0); // In the open area northeast of the Sky Passage.
      vector targetPoint = vector(216.0, 0.0, 101.0); // By the Southern Atlanteans' hideout.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 Upper Exit");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(247.0, 0.0, 261.0));
      kbPathAddWaypoint(pathID1, vector(320.0, 0.0, 312.0));
      kbPathAddWaypoint(pathID1, vector(289.0, 0.0, 341.0));
      kbPathAddWaypoint(pathID1, vector(140.0, 0.0, 340.0));
      kbPathAddWaypoint(pathID1, vector(120.0, 0.0, 160.0));
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path 2 West Exit");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(187.0, 0.0, 207.0));
      kbPathAddWaypoint(pathID2, vector(185.0, 0.0, 279.0));
      kbPathAddWaypoint(pathID2, vector(125.0, 0.0, 331.0));
      kbPathAddWaypoint(pathID2, vector(93.0, 0.0, 319.0));
      kbPathAddWaypoint(pathID2, vector(120.0, 0.0, 160.0));
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });

      // Create a general-purpose defend plan to keep existing military occupied and gathered.
      int landDefendPlan = createDefendPlan("Primary Land Defend", -1, 50.0, startPoint, 10, startPoint);
      aiPlanSetVariableFloat(landDefendPlan, cDefendPlanEngageRange, 0, 50.0);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      int time = xsGetTime();
      if (gAllowedToAttack == false && time >= 600)
      {
         debugAttackWave("10 minutes have passed!");
         gAllowedToAttack = true;
      }
      if (done == false && gAllowedToAttack == true)
      {
         debugAttackWave("Enabling attacks.");
         debugAttackWave("New attack time: " + turnNumberIntoTimeDisplay(time + gAttackStartDelay));
         gAttackWave.setAttackStartTime(gAttackStartDelay);
         xsEnableRule("useDeconstruction");
         xsEnableRule("useChaos");
         xsEnableRuleGroup("ruleGroupUpgrades");
         done = true;
      }

      // Increase attack size after 15 minutes on Hard, 12 minutes on Titan.
      static bool buff_attacks = false;
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         if (buff_attacks == false)
         {
            if (cDifficultyCurrent == cDifficultyHard && time >= 900)
            {
               gAttackMaxSize *= 1.25; // Increase attack size by +25%.
               gAttackWave.setMaxAttackSize(gAttackMaxSize);

               // Train more Villagers to support the larger army.
               gMaxVillagerCount *= 1.20; // Train +20% more Villagers.
               gOverrideMaxVillagerPop = gMaxVillagerCount;

               buff_attacks = true;
            }
            if (cDifficultyCurrent == cDifficultyTitan && time >= 720)
            {
               gAttackMaxSize *= 1.25; // Increase attack size by +25%.
               gAttackWave.setMaxAttackSize(gAttackMaxSize);

               // Train more Villagers to support the larger army.
               gMaxVillagerCount *= 1.20; // Train +20% more Villagers.
               gOverrideMaxVillagerPop = gMaxVillagerCount;

               buff_attacks = true;
            }
         }
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}


// Set up the strategy.
void tna11StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(281.00, 0.00, 113.00), 12);
   createOverrideGatherBase(vector(305.00, 0.00, 104.00), 36);

   setOverrideStrategy(tna11StrategySetup);

   gOverrideFarmCount = 14; // Don't overdo the Farms.
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, gOurTCLocation, 10.0);
      kbBuildingPlacementAddPositionInfluence(bpID, gOurTCLocation, 100.0, 10.0, cFalloffLinear);
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
void postInit()
{
}

void enableAttacks()
{
   debugAttackWave("Attacks enabled via trigger call.");
   gAllowedToAttack = true;
}

rule enemiesInMyBase
inactive
minInterval 10
{
   if (gAllowedToAttack == true)
   {
      xsDisableRule("enemiesInMyBase");
      return;
   }

   vector checkOrigin = vector(187.0, 0.0, 191.0); // Our Sky Passage
   int numEnemies = getUnitCountByLocation(cUnitTypeUnit, 1, cUnitStateAlive, checkOrigin, 50.0);
   if (numEnemies >= 1)
   {
      debugAttackWave("We have found " + numEnemies + " enemies approaching our base!");
      gAllowedToAttack = true;
      xsDisableRule("enemiesInMyBase");
      return;
   }
}

rule useDeconstruction
inactive
minInterval 10
{
   static int casts = 0;
   static int delay = 0;
   if (delay > 0)
   {
      delay -= 10;   // Same as rule interval.
      return;
   }

   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   int unitID = -1;
   int targetID = -1;
   for (int i = 0; i < attackPlans.size(); i++)
   {
      if (aiPlanGetParentID(attackPlans[i]) == -1)
      {
         // We just take the first unit to scan from.
         unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
         if (unitID >= 0)
         {
            // Grab an enemy unit.
            targetID = getUnitByLocation(cUnitTypePalace, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 30.0);
            if (targetID >= 0)
            {
               // Invoke god power!
               if (aiCastGodPowerAtUnit(cProtoPowerDeconstruction, targetID) == true)
               {
                  debugAttackWave("Casted Deconstruction! (" + casts + "/2)");
                  casts++;
                  if (casts < 2)
                  {
                     delay = 300;   // 5-minute delay before getting to invoke this again.
                     return;
                  }
                  else if (casts >= 2)
                  {
                     xsDisableRule("useDeconstruction");
                     return;
                  }
               }
            }
         }
      }
   }
}

rule useChaos
inactive
minInterval 10
{
   static int casts = 0;
   static int delay = 0;
   if (delay > 0)
   {
      delay -= 10;   // Same as rule interval.
      return;
   }

   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   int unitID = -1;
   int numEnemies = -1;
   int targetID = -1;
   for (int i = 0; i < attackPlans.size(); i++)
   {
      if (aiPlanGetParentID(attackPlans[i]) == -1)
      {
         // We just take the first unit to scan from.
         unitID = aiPlanGetUnitIDByIndex(attackPlans[i], 0);
         if (unitID >= 0)
         {
            // Look for enemies.
            numEnemies = getUnitCountByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 20.0);
            debugAttackWave("numEnemies for casting Chaos offensively: " + numEnemies);
            if (numEnemies >= 10)
            {
               // Grab an enemy unit.
               targetID = getUnitByLocation(cUnitTypeHumanSoldier, 1, cUnitStateAlive, kbUnitGetPosition(unitID), 20.0);
               if (targetID >= 0)
               {
                  // Invoke god power!
                  if (aiCastGodPowerAtPosition(cProtoPowerChaos, kbUnitGetPosition(targetID)) == true)
                  {
                     debugAttackWave("Casted Chaos! (" + casts + "/2)");
                     casts++;
                     if (casts < 2)
                     {
                        delay = 600;   // 10-minute delay before getting to invoke this again.
                        return;
                     }
                     else if (casts >= 2)
                     {
                        xsDisableRule("useChaos");
                        return;
                     }
                  }
               }
            }
         }
      }
   }
}

rule researchIronWeaponsArmorShields
inactive
minInterval 30
group ruleGroupUpgrades
{
   if (gAllowedToAttack == true)
   {
      xsSetRuleMinIntervalSelf(10);
      // Cease if we have it. Otherwise, research it.
      if ((kbTechGetStatus(cTechIronWeapons) == cTechStatusActive) &&
         (kbTechGetStatus(cTechIronArmor) == cTechStatusActive) &&
         (kbTechGetStatus(cTechIronShields) == cTechStatusActive))
      {
         xsDisableRule("researchIronWeaponsArmorShields");
         return;
      }
      if (kbTechGetStatus(cTechIronWeapons) == cTechStatusObtainable)
      {
         debugAttackWave("Starting Iron Weapons research plan.");
         researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 60);
         return;
      }
      if (kbTechGetStatus(cTechIronArmor) == cTechStatusObtainable)
      {
         debugAttackWave("Starting Iron Armor research plan.");
         researchSimpleTech(cTechIronArmor, cUnitTypeArmory, -1, 60);
         return;
      }
      if (kbTechGetStatus(cTechIronShields) == cTechStatusObtainable)
      {
         debugAttackWave("Starting Iron Shields research plan.");
         researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
         return;
      }
   }
}

rule researchChampionInfantry
inactive
minInterval 30
group ruleGroupUpgrades
{
   if (gAllowedToAttack == true)
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
         researchSimpleTech(cTechChampionInfantry, cUnitTypePalace, -1, 60);
         return;
      }
   }
}

rule researchChampionArchers
inactive
minInterval 30
group ruleGroupUpgrades
{
   if (gAllowedToAttack == true)
   {
      xsSetRuleMinIntervalSelf(10);
      // Cease if we have it. Otherwise, research it.
      if (kbTechGetStatus(cTechChampionArchers) == cTechStatusActive)
      {
         xsDisableRule("researchChampionArchers");
         return;
      }
      else if (kbTechGetStatus(cTechChampionArchers) == cTechStatusObtainable)
      {
         debugAttackWave("Starting Champion Archers research plan.");
         researchSimpleTech(cTechChampionArchers, cUnitTypeMilitaryBarracks, -1, 60);
         return;
      }
   }
}

rule researchFireSiphonTechs
inactive
minInterval 30
group ruleGroupUpgrades
{
   if (gAllowedToAttack == true)
   {
      debugAttackWave("Starting Engineers/Halo of the Sun/Petrification research plans.");
      researchSimpleTech(cTechEngineers, cUnitTypePalace, -1, 60);
      researchSimpleTech(cTechHaloOfTheSun, cUnitTypePalace, -1, 60);
      researchSimpleTech(cTechPetrification, cUnitTypePalace, -1, 60);
      xsDisableRule("researchFireSiphonTechs");
   }
}