//==============================================================================
/* fott15_p5.xs

   Yellow Egyptian player owning the island in the north. Sends transport attacks of Spearmen, Axemen, and Scarabs.
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

int gFirstLandUnit = cUnitTypeSpearman; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 8;
int gSecondLandUnit = cUnitTypeAxeman; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 8;
int gThirdLandUnit = cUnitTypeScarab; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 3;
float gAttackStartDelay = 240; // In seconds.
float gAttackWaveInterval = 300; // In Seconds.
float gAttackStartSize = 6;
float gAttackMaxSize = 10;

int gWakeUpTime = 0; // Set to the current in-game time when the AI is told to 'wake up', after Arkantos gets a base.

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
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      // Train 4 Scarabs on Titan.
      if (cDifficultyCurrent == cDifficultyTitan)
      {
         gMaintainThirdLandUnitAmount = 4;
      }
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      // Make certain parameters way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         // Feeble attacks.
         gAttackStartSize = 3;
         gAttackMaxSize = 5;
         
         gMaintainFirstLandUnitAmount = 4; // 4 Spearmen
         gMaintainSecondLandUnitAmount = 4; // 4 Axemen
         gMaintainThirdLandUnitAmount = 1; // 1 Scarab

         // First attack takes longer to be dispatched.
         gAttackStartDelay = 400;
         gAttackWaveInterval = 400;
      }


      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(cWaitWithAttacking);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      gAttackWave.addAttackUnitType(gThirdLandUnit);

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(375.0, 2.76, 366.0); // Point between the center and eastern Docks.
      vector targetPoint = vector(41.0, 3.0, 262.0); // Point behind player's Town Center.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(349.0, 2.0, 324.0));
      kbPathAddWaypoint(pathID1, vector(334.0, 2.0, 298.0));
      kbPathAddWaypoint(pathID1, vector(310.0, 2.0, 298.0));
      kbPathAddWaypoint(pathID1, vector(281.0, 2.0, 273.0));
      kbPathAddWaypoint(pathID1, vector(87.0, 2.0, 255.0));
      kbPathAddWaypoint(pathID1, vector(81.0, 2.7, 255.0));
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
      gAttackWave.displayFirstAttackStats();
     
      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      // We must stop attacking if the Lighthouse is destroyed.
      static bool destroyed = false;
      if (destroyed == false)
      {
         if (kbUnitCount(cUnitTypeLighthouse, 4, cUnitStateAlive) < 1)
         {
            destroyed = true;
         }

      gAttackWave.update();
      }
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
   // Max out available military slots, we control this number via maintain plans anyway.
   gOverrideMaxMilitaryPop = 200;
   setOverrideStrategy(fott15StrategySetup);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

   // * * * TECH RULES * * * //
   // HARD ONLY
      // Iron Weapons
         rule researchIronWeapons
         inactive
         minInterval 10 // AI will attempt to get the technology every 10 seconds.
         {
            if (xsGetTime() >= 500 + gWakeUpTime)
               {
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
         }

   // HARD AND TITAN
         // Champion Spearmen
            rule researchChampionSpearmen
            inactive
            minInterval 10 // AI will attempt to get the technology every 10 seconds.
            {
               if (xsGetTime() >= 480 + gWakeUpTime)
                  {
                     // Cease if we have it. Otherwise, research it.
                     if (kbTechGetStatus(cTechChampionSpearmen) == cTechStatusActive)
                     {
                        xsDisableRule("researchChampionSpearmen");
                        return;
                     }
                     else if (kbTechGetStatus(cTechChampionSpearmen) == cTechStatusObtainable)
                     {
                        debugAttackWave("Starting Champion Spearmen research plan.");
                        researchSimpleTech(cTechChampionSpearmen, cUnitTypeBarracks, -1, 60);
                        return;
                     }
                  }
            }

   // TITAN ONLY
         // Champion Axemen
            rule researchChampionAxemen
            inactive
            minInterval 10 // AI will attempt to get the technology every 10 seconds.
            {
               if (xsGetTime() >= 600 + gWakeUpTime)
                  {
                     // Cease if we have it. Otherwise, research it.
                     if (kbTechGetStatus(cTechChampionAxemen) == cTechStatusActive)
                     {
                        xsDisableRule("researchChampionAxemen");
                        return;
                     }
                     else if (kbTechGetStatus(cTechChampionAxemen) == cTechStatusObtainable)
                     {
                        debugAttackWave("Starting Champion Axemen research plan.");
                        researchSimpleTech(cTechChampionAxemen, cUnitTypeBarracks, -1, 60);
                        return;
                     }
                  }
            }
         // Spear of Horus
            rule researchSpearOfHorus
            inactive
            minInterval 10 // AI will attempt to get the technology every 10 seconds.
            {
               if (xsGetTime() >= 720 + gWakeUpTime)
                  {
                     // Cease if we have it. Otherwise, research it.
                     if (kbTechGetStatus(cTechSpearOfHorus) == cTechStatusActive)
                     {
                        xsDisableRule("researchSpearOfHorus");
                        return;
                     }
                     else if (kbTechGetStatus(cTechSpearOfHorus) == cTechStatusObtainable)
                     {
                        debugAttackWave("Starting Spear of Horus research plan.");
                        researchSimpleTech(cTechSpearOfHorus, cUnitTypeBarracks, -1, 60);
                        return;
                     }
                  }
            }
         // Iron Armor
            rule researchIronArmor
            inactive
            minInterval 10 // AI will attempt to get the technology every 10 seconds.
            {
               if (xsGetTime() >= 700 + gWakeUpTime)
                  {
                     // Cease if we have it. Otherwise, research it.
                     if (kbTechGetStatus(cTechIronArmor) == cTechStatusActive)
                     {
                        xsDisableRule("researchIronArmor");
                        return;
                     }
                     else if (kbTechGetStatus(cTechIronArmor) == cTechStatusObtainable)
                     {
                        debugAttackWave("Starting Iron Armor research plan.");
                        researchSimpleTech(cTechIronArmor, cUnitTypeArmory, -1, 60);
                        return;
                     }
                  }
            }
         // Iron Shields
            rule researchIronShields
            inactive
            minInterval 10 // AI will attempt to get the technology every 10 seconds.
            {
            if (xsGetTime() >= 840 + gWakeUpTime)
               {
                  xsSetRuleMinIntervalSelf(10);
                  // Cease if we have it. Otherwise, research it.
                  if (kbTechGetStatus(cTechIronShields) == cTechStatusActive)
                  {
                     xsDisableRule("researchIronShields");
                     return;
                  }
                  else if (kbTechGetStatus(cTechIronShields) == cTechStatusObtainable)
                  {
                     debugAttackWave("Starting Iron Shields research plan.");
                     researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
                     return;
                  }
               }
            }

// Called from the triggers to enable attacks. Occurs when Arkantos gets a base.
void updateParameters()
{
   // Set the wakeup time and enable upgrade rules.
   gWakeUpTime = xsGetTime(); // Used to determine when to research upgrades.
   // ENABLE TECHS

   // Tech Rules for Hard only:
   if (cDifficultyCurrent == cDifficultyHard)
   {
      xsEnableRule("researchIronWeapons");
   }
   // Tech Rules for Hard and Titan:
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      xsEnableRule("researchChampionSpearmen");
   }
   // Tech Rules for Titan only:
   if (cDifficultyCurrent == cDifficultyTitan)
   {
      xsEnableRule("researchSpearOfHorus");
      xsEnableRule("researchChampionAxemen");
      xsEnableRule("researchIronArmor");
      xsEnableRule("researchIronShields");
   }
   // Define first attack.
   gAttackWave.setAttackStartTime(gAttackStartDelay);
   return;
}