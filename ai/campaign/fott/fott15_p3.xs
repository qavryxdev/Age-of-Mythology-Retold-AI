//==============================================================================
/* fott15_p3.xs

   Purple Egyptian player owning the base above the player. Sends attacks of Spearmen and Petsuchos.
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
int gFirstLandUnit = cUnitTypeSpearman; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 12;
int gSecondLandUnit = cUnitTypePetsuchos; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 2;
int gThirdLandUnit = cUnitTypeSlinger; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 8;
int gFourthLandUnit = cUnitTypePriest; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 2;

float gMaxVillagerCount = 18;
float gMaxFishingShipCount = 3;
float gAttackStartDelay = 360; // In seconds.
float gAttackWaveInterval = 360; // In Seconds.
float gAttackStartSize = 6;
float gAttackMaxSize = 15;

int gWakeUpTime = 0; // Set to the current in-game time when the AI is told to 'wake up', after Arkantos gets a base.

Strategy scenarioAttackWaveStrategy()
{

   // Tech Rules for Hard and Titan:
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      xsEnableRule("researchBronzeArmor");
      xsEnableRule("researchBronzeShields");
   }

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
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;

      // Only apply the multiplier to Priests on Titan.
      if (cDifficultyCurrent == cDifficultyTitan)
      {
         gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      }
      
      // Don't apply the multiplier to the attack intervals on Moderate.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gAttackStartDelay *= gDifficultyModifierFirstAttack;
         gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      }
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;

      // Make certain parameters way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         // Feeble attacks.
         gAttackStartSize = 3;
         gAttackMaxSize = 5;
         
         // First attack takes really long to be dispatched.
         gAttackStartDelay = 600;
      }

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);

      // Only maintain Slingers on Moderate and up.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      }
      // Only maintain Priests on Hard and Titan.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
         // Remove train delay on harder difficulties.
         gTrainDelay = 0;
      }

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);

      // Details about the attack waves.
      // Don't attack until Arkantos reaches the TC; updated by script call.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(cWaitWithAttacking);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         gAttackWave.addAttackUnitType(gThirdLandUnit);
      }
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gAttackWave.addAttackUnitType(gFourthLandUnit);
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

      // Where does our attack start and end.
      vector startPoint = vector(109.0, 3.0, 328.0); // Between the AI's 2 Barracks.
      vector targetPoint = vector(41.0, 3.0, 251.0); // Below player's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID = kbPathCreate("Path 1");
      kbPathAddWaypoint(pathID, startPoint);
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

      
      // But keep the eco researches going!
      data.setFlag(cStrategyFlagAutoResearchEconomyUpgrades, true);
      
      int landDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 30.0, startPoint, 10);
      aiPlanSetVariableFloat(landDefendPlan, cDefendPlanEngageRange, 0, 20.0);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };
   // Done.
   return strategy;
}

// Set up the strategy.
void fott15StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(134.00, 0.00, 352.00), 52);

   setOverrideStrategy(fott15StrategySetup);

   // We can't have too many farms due to space restrictions.
   gOverrideFarmCount = 12;
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// HEROIC AGE UPGRADES
   // *** MODERATE UPGRADES *** //
      // Research Architects 180 seconds after Arkantos reaches the TC.
      rule researchArchitects
      inactive
      minInterval 10 // AI will attempt to get the technology every 10 seconds.
      group ruleGroupUpgradesModerate
      {
         if (xsGetTime() >= 180 + gWakeUpTime)
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
      // Research Bronze Weapons 240 seconds after Arkantos reaches the TC.
      rule researchBronzeWeapons
      inactive
      minInterval 10 // AI will attempt to get the technology every 10 seconds.
      group ruleGroupUpgradesModerate
      {
         if (xsGetTime() >= 240 + gWakeUpTime)
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
      // Research Heavy Spearmen 120 seconds after Arkantos reaches the TC.
      rule researchHeavySpearmen
      inactive
      minInterval 10 // AI will attempt to get the technology every 10 seconds.
      group ruleGroupUpgradesModerate
      {
         if (xsGetTime() >= 120 + gWakeUpTime)
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechHeavySpearmen) == cTechStatusActive)
               {
                  xsDisableRule("researchHeavySpearmen");
                  return;
               }
               else if (kbTechGetStatus(cTechHeavySpearmen) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Heavy Spearmen research plan.");
                  researchSimpleTech(cTechHeavySpearmen, cUnitTypeBarracks, -1, 60);
                  return;
               }
            }
      }
      // Research Heavy Slingers 210 seconds after Arkantos reaches the TC (MODERATE AND HARD).
      rule researchHeavySlingersModHard
      inactive
      minInterval 10 // AI will attempt to get the technology every 10 seconds.
      group ruleGroupUpgradesModerate
      {
         if (xsGetTime() >= 210 + gWakeUpTime)
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechHeavySlingers) == cTechStatusActive)
               {
                  xsDisableRule("researchHeavySlingersModHard");
                  return;
               }
               else if (kbTechGetStatus(cTechHeavySlingers) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Heavy Slingers research plan.");
                  researchSimpleTech(cTechHeavySlingers, cUnitTypeBarracks, -1, 60);
                  return;
               }
            }
         else if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsDisableRule("researchHeavySlingersModHard"); // Disable self.
            return;
         }
      }

   // *** HARD UPGRADES *** //
      // Research Bronze Armor 360 seconds after Arkantos reaches the TC.
      rule researchBronzeArmor
      inactive
      minInterval 10 // AI will attempt to get the technology every 10 seconds.
      group ruleGroupUpgradesHard
      {
         if (xsGetTime() >= 360 + gWakeUpTime)
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
      // Research Bronze Shields 480 seconds after Arkantos reaches the TC.
      rule researchBronzeShields
      inactive
      minInterval 10 // AI will attempt to get the technology every 10 seconds.
      group ruleGroupUpgradesHard
      {
         if (xsGetTime() >= 480 + gWakeUpTime)
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
      // Research Fortified TC 480 seconds after Arkantos reaches the TC.
      rule researchFortifiedTownCenter
      inactive
      minInterval 10 // AI will attempt to get the technology every 10 seconds.
      group ruleGroupUpgradesHard
      {
         if (xsGetTime() >= 480 + gWakeUpTime)
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
   // *** TITAN UPGRADES *** //
      // Research Heavy Slingers 60 seconds after Arkantos reaches the TC (TITAN).
      rule researchHeavySlingersTitan
      inactive
      minInterval 10 // AI will attempt to get the technology every 10 seconds.
      group ruleGroupUpgradesTitan
      {
         if (xsGetTime() >= 60 + gWakeUpTime)
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechHeavySlingers) == cTechStatusActive)
               {
                  xsDisableRule("researchHeavySlingersTitan");
                  return;
               }
               else if (kbTechGetStatus(cTechHeavySlingers) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Heavy Slingers research plan.");
                  researchSimpleTech(cTechHeavySlingers, cUnitTypeBarracks, -1, 60);
                  return;
               }
            }
      }
      // Research Sun-dried Mud-brick 300 seconds after Arkantos reaches the TC.
      rule researchSunDriedMudBrick
      inactive
      minInterval 10 // AI will attempt to get the technology every 10 seconds.
      group ruleGroupUpgradesTitan
      {
         if (xsGetTime() >= 300 + gWakeUpTime)
            {
               researchSimpleTech(cTechSunDriedMudBrick, cUnitTypeTownCenter, -1, 60);
               xsDisableRule("researchSunDriedMudBrick"); // Disable self.
               return;
            }
      }

// Called from the triggers to enable attacks. Occurs when Arkantos gets a base.
void updateParameters()
{
   // Set the wakeup time and enable upgrade rules.
   gWakeUpTime = xsGetTime(); // Used to determine when to research upgrades.
   // ENABLE TECHS
      // Not Easy
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         xsEnableRuleGroup("ruleGroupUpgradesModerate");
      }
      // Hard and Titan
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         xsEnableRuleGroup("ruleGroupUpgradesHard");
      }
      // Titan Only
      if (cDifficultyCurrent == cDifficultyTitan)
      {
         xsEnableRuleGroup("ruleGroupUpgradesTitan");
      }
   // Define first attack.
   gAttackWave.setAttackStartTime(gAttackStartDelay);
   return;
}