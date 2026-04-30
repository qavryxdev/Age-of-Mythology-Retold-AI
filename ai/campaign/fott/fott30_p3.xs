//==============================================================================
/* fott22_p2.xs
   
   Instead of entering specific military building types I entered "logicaltypemilitarybuilding" for the infantry techs.

   Instead of Bronze Techs AI is reserching the Copper Technologies. (In order to research Bronze AI needs to research copper techs first, which is not done)
   The paths need to be double checked and compared to the legacy pathing. The path branched into 2 initial paths, and there were 3 different paths after that which creates a large number of possibilities to choose from.

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

float gTrainDelay = 0; // In seconds.
int gFirstLandUnit = cUnitTypeCyclops; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 3;
int gSecondLandUnit = cUnitTypeManticore; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 2;
int gThirdLandUnit = cUnitTypePeltast; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 5;
int gFourthLandUnit = cUnitTypeProdromos; // Gets trained starting from the Mythic Age.
float gMaintainFourthLandUnitAmount = 5;
int gFifthLandUnit = cUnitTypeGastraphetoros; // Gets trained starting from the Mythic Age.
float gMaintainFifthLandUnitAmount = 7;
int gSixthLandUnit = cUnitTypeHelepolis; // Gets trained starting from the Mythic Age.
float gMaintainSixthLandUnitAmount = 1;

int gExtraLandUnitDelay = 0;

float gMaxVillagerCount = 0;
float gAttackStartDelay = 120; // In seconds.
float gSecondAttackStartDelay = 150; // In seconds.
float gAttackWaveInterval = 300; // In seconds.
float gAttackStartSize = 5;
float gAttackMaxSize = 18;

int gLandDefendPlan = -1;

float gAttackStartDelayLong = cWaitWithAttacking; // In seconds, effectively 'preventing' attacks until function ActivateP3() is called.
bool gEnableAttacks = false; // Flipped by function P3()
bool gOdysseus_Here = false;

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
      // Certain parameters are much more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gAttackStartSize = 4;
         gAttackMaxSize = 8;
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;     

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gSecondAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;
      gExtraLandUnitDelay += xsGetTime(); // Offset for starting time.

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      // Don't make Helepoli on Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
      }

      // Train delay, how long the AI waits before queuing up another unit.
      int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gFirstLandUnit);
      aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, kbPlayerGetProtoStatFloat(cMyID, gFirstLandUnit, cProtoStatTrainPoints) + gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);
      data.setTrainDelay(gFifthLandUnit, gTrainDelay);
      data.setTrainDelay(gSixthLandUnit, gTrainDelay);

      // Fast/Combat Attack Wave (Manticores, Peltasts, Hippeis)
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMinAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      gAttackWave.addAttackUnitType(gThirdLandUnit);
      gAttackWave.addAttackUnitType(gFourthLandUnit);

      // Slow/Siege Attack Wave (Cyclopes, Helepoli, Gastraphetori, Shades)
      gSecondAttackWave.setName("gSecondAttackWave");
      gSecondAttackWave.setAttackStartTime(gSecondAttackStartDelay);
      gSecondAttackWave.setAttackInterval(gAttackWaveInterval);
      gSecondAttackWave.setAttackSize(gAttackStartSize);
      gSecondAttackWave.setMinAttackSize(gAttackStartSize);
      gSecondAttackWave.setMaxAttackSize(gAttackMaxSize);
      gSecondAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gSecondAttackWave.addAttackUnitType(gFirstLandUnit);
      gSecondAttackWave.addAttackUnitType(gFifthLandUnit);
      // Don't add Helepoli until later.
      gSecondAttackWave.addAttackUnitType(cUnitTypeHadesShade);

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(343.15, 0.00, 136.96); // Behind the gates.
      vector startPoint2 = vector(339.0, 0.00, 129.0); // Right of the Temple.
      vector targetPoint = vector(39.47, 14.45, 21.72); // P1's base.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a path to it.
      int routeID = kbCreateAttackRouteWithPath("Army 1 Route", startPoint, targetPoint);
      int routeID2 = kbCreateAttackRouteWithPath("Army 2 Route", startPoint2, targetPoint);
      int pathID2 = kbPathCreate("First Attack (Combat Army)");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(349.0, 0.0, 173.0)); // 1st Waypoint
      kbPathAddWaypoint(pathID2, vector(307.0, 0.0, 209.0)); // 2nd Waypoint
      kbPathAddWaypoint(pathID2, vector(263.0, 0.0, 193.0));  // 3rd Waypoint
      kbPathAddWaypoint(pathID2, vector(247.0, 0.0, 133.0));  // 4th Waypoint
      kbPathAddWaypoint(pathID2, vector(203.0, 0.0, 105.0));   // 5th Waypoint
      kbPathAddWaypoint(pathID2, vector(167.0, 0.0, 33.0));    // 6th Waypoint
      kbPathAddWaypoint(pathID2, vector(145.0, 0.0, 31.0));   // 7th Waypoint
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      int pathID3 = kbPathCreate("First Attack (Siege Army)");
      kbPathAddWaypoint(pathID3, vector(349.0, 0.0, 173.0)); // 1st Waypoint
      kbPathAddWaypoint(pathID3, vector(307.0, 0.0, 209.0)); // 2nd Waypoint
      kbPathAddWaypoint(pathID3, vector(263.0, 0.0, 193.0));  // 3rd Waypoint
      kbPathAddWaypoint(pathID3, vector(247.0, 0.0, 133.0));  // 4th Waypoint
      kbPathAddWaypoint(pathID3, vector(203.0, 0.0, 105.0));   // 5th Waypoint
      kbPathAddWaypoint(pathID3, vector(99.0, 0.0, 113.0));    // 6th Waypoint
      kbAttackRouteAddPath(routeID2, pathID2);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
         static int counter = 0;
            if (counter == 0)
            {
               xsEnableRule("expandAttackRoutes");
               counter++; // Only do this for the first attack.
            }
      });

      gSecondAttackWave.setGatherPoint(startPoint2);
      gSecondAttackWave.setTargetPoint(targetPoint);
      gSecondAttackWave.setAttackRouteID(routeID2);
      gSecondAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });       
      
      gLandDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 12.0, vector(333.78, 0.00, 120.28), 10);
      aiPlanSetVariableFloat(gLandDefendPlan, cDefendPlanEngageRange, 0, 25.0);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
 strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static int elapsed_time = 99999;
      static int elapsed_time_2 = 99999;
      static bool increase_size = false;

      if (gEnableAttacks == true)
      {
         gAttackWave.setAttackStartTime(gAttackStartDelay);
         gSecondAttackWave.setAttackStartTime(gAttackStartDelay);
         elapsed_time = xsGetTime(); // We can now initiate the attack size increase mechanic.
         elapsed_time_2 = xsGetTime(); // We can now wait to increase the number of units trained.

         // Only begin researching technologies once we're allowed to attack.

         // Moderate only:
         if (cDifficultyCurrent == cDifficultyModerate)
         {
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchChampionInfantry");
            xsEnableRule("researchChampionCavalry");
            xsEnableRule("researchChampionArchers");
         }

         // Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchChampionInfantryHT");
            xsEnableRule("researchChampionCavalryHT");
            xsEnableRule("researchChampionArchersHT");
            xsEnableRule("researchIronWeaponsHT");
            xsEnableRule("researchBurningPitch");
         }
         // Hard Only:
         if (cDifficultyCurrent == cDifficultyHard)
         {
            xsEnableRule("researchIronShields");
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchBravery");
            xsEnableRule("researchIronShieldsTitan");
            xsEnableRule("researchEngineers");
         }

         gEnableAttacks = false; // Flip this back to false so we don't update AttackStartTime again.
      }

      int increase_interval = xsGetTime() - elapsed_time;
      int attack_buff = xsGetTime() - elapsed_time_2;
      
      // Only add siege weapons 5 minutes in.
      static bool siege_added = false;
      if (cDifficultyCurrent >= cDifficultyModerate && attack_buff >= 300)
      {
         if (siege_added == false)
         {
            gSecondAttackWave.addAttackUnitType(gSixthLandUnit);
            gSecondAttackWave.addAttackUnitType(gFirstLandUnit);
            gSecondAttackWave.addAttackUnitType(gFifthLandUnit);
            gSecondAttackWave.addAttackUnitType(cUnitTypeHadesShade);
            gSecondAttackWave.update();

            siege_added = true;
         }
      }

      // More siege weapons 14 minutes in (Hard and Titan only)
      static bool more_siege = false;
      if (attack_buff >= 840 && cDifficultyCurrent >= cDifficultyHard)
      {
         if (more_siege == false)
         {
            gMaintainSixthLandUnitAmount *= 2.0;
            data.adjustUnitToMaintainAmount(gSixthLandUnit, gMaintainSixthLandUnitAmount);
            gSecondAttackWave.update();

            more_siege = true;
         }
      }

      // Train more soldiers towards the end.
      if (elapsed_time_2 != 99999)
      {
         if (attack_buff >= 600 && increase_size == false)
         {
            // Moderate Increases
            if (cDifficultyCurrent == cDifficultyModerate)
            {
               gMaintainThirdLandUnitAmount *= 1.25;
               gMaintainFourthLandUnitAmount *= 1.25;
               gMaintainFifthLandUnitAmount *= 1.25;

               data.adjustUnitToMaintainAmount(gThirdLandUnit, gMaintainThirdLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFourthLandUnit, gMaintainFourthLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFifthLandUnit, gMaintainFifthLandUnitAmount);

               gAttackMaxSize *= 1.05; // +5%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);
               gSecondAttackWave.setMaxAttackSize(gAttackMaxSize);

               increase_size = true;

               gAttackWave.update();
               gSecondAttackWave.update();
            }
            // Hard Increases
            if (cDifficultyCurrent == cDifficultyHard)
            {
               gMaintainThirdLandUnitAmount *= 1.5;
               gMaintainFourthLandUnitAmount *= 1.5;
               gMaintainFifthLandUnitAmount *= 1.5;

               data.adjustUnitToMaintainAmount(gThirdLandUnit, gMaintainThirdLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFourthLandUnit, gMaintainFourthLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFifthLandUnit, gMaintainFifthLandUnitAmount);

               gAttackMaxSize *= 1.10; // +10%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);
               gSecondAttackWave.setMaxAttackSize(gAttackMaxSize);

               increase_size = true;

               gAttackWave.update();
               gSecondAttackWave.update();
            }
            // Titan Increases
            if (cDifficultyCurrent == cDifficultyTitan)
            {
               gMaintainFirstLandUnitAmount *= 1.5;
               gMaintainSecondLandUnitAmount *= 1.5;
               gMaintainThirdLandUnitAmount *= 2.0;
               gMaintainFourthLandUnitAmount *= 2.0;
               gMaintainFifthLandUnitAmount *= 1.5;

               data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
               data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
               data.adjustUnitToMaintainAmount(gThirdLandUnit, gMaintainThirdLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFourthLandUnit, gMaintainFourthLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFifthLandUnit, gMaintainFifthLandUnitAmount);

               gAttackMaxSize *= 1.15; // +15%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);
               gSecondAttackWave.setMaxAttackSize(gAttackMaxSize);

               increase_size = true;

               gAttackWave.update();
               gSecondAttackWave.update();
            }
         }
      }

      // Once Odysseus arrives, we're meant to no longer attack.
      static bool Defense_Changed = false;
      if (gOdysseus_Here == false && Defense_Changed == false)
      {
         gAttackWave.update();
         gSecondAttackWave.update();
      }
      else
      {
         if (gOdysseus_Here == true && Defense_Changed == false)
         {
            Defense_Changed = true;
            debugAttackWave("Odysseus is here! Stopping all attacks.");
            updateDefendPlans();
         }
      }

      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott30StrategySetup()
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
   gOverrideMaxMilitaryPop = 300; // Max out available military slots, we control this number via maintain plans anyway.

   setOverrideStrategy(fott30StrategySetup);
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

// *** FUNCTION - ActivateP3 ***
// Called from the triggers to enable attacks.
void ActivateP3()
{
   gEnableAttacks = true;
   debugAttackWave("*** ATTACKS ARE NOW ENABLED ***");
}

// After the first attack goes out we expand our possible routes.
rule expandAttackRoutes
inactive
minInterval 30
{
   int routeID = gAttackWave.mAttackRouteID;
   int routeID2 = gSecondAttackWave.mAttackRouteID;

      int pathID1 = kbPathCreate("Attack Interval 1");
      kbPathAddWaypoint(pathID1, vector(349.0, 0.0, 173.0)); // 1st Waypoint
      kbPathAddWaypoint(pathID1, vector(307.0, 0.0, 209.0)); // 2nd Waypoint
      kbPathAddWaypoint(pathID1, vector(263.0, 0.0, 193.0));  // 3rd Waypoint
      kbPathAddWaypoint(pathID1, vector(171.0, 0.0, 167.0));  // 4th Waypoint
      kbPathAddWaypoint(pathID1, vector(143.0, 0.0, 205.0));  // 5th Waypoint
      kbPathAddWaypoint(pathID1, vector(111.0, 0.0, 201.0));  // 6th Waypoint
      kbPathAddWaypoint(pathID1, vector(85.0, 0.0, 129.0));  // 7th Waypoint
      kbAttackRouteAddPath(routeID, pathID1);
      kbAttackRouteAddPath(routeID2, pathID1);

      int pathID2 = kbPathCreate("Attack Interval 2");
      kbPathAddWaypoint(pathID2, vector(349.0, 0.0, 173.0)); // 1st Waypoint
      kbPathAddWaypoint(pathID2, vector(307.0, 0.0, 209.0)); // 2nd Waypoint
      kbPathAddWaypoint(pathID2, vector(263.0, 0.0, 193.0));  // 3rd Waypoint
      kbPathAddWaypoint(pathID2, vector(247.0, 0.0, 133.0));  // 4th Waypoint
      kbPathAddWaypoint(pathID2, vector(203.0, 0.0, 105.0));   // 5th Waypoint
      kbPathAddWaypoint(pathID2, vector(167.0, 0.0, 33.0));    // 6th Waypoint
      kbPathAddWaypoint(pathID2, vector(145.0, 0.0, 31.0));   // 7th Waypoint
      kbAttackRouteAddPath(routeID2, pathID2);

      int pathID3 = kbPathCreate("Attack Interval 3");
      kbPathAddWaypoint(pathID3, vector(349.0, 0.0, 173.0)); // 1st Waypoint
      kbPathAddWaypoint(pathID3, vector(307.0, 0.0, 209.0)); // 2nd Waypoint
      kbPathAddWaypoint(pathID3, vector(263.0, 0.0, 193.0));  // 3rd Waypoint
      kbPathAddWaypoint(pathID3, vector(247.0, 0.0, 133.0));  // 4th Waypoint
      kbPathAddWaypoint(pathID3, vector(203.0, 0.0, 105.0));   // 5th Waypoint
      kbPathAddWaypoint(pathID3, vector(99.0, 0.0, 113.0));    // 6th Waypoint
      kbAttackRouteAddPath(routeID, pathID3);

   debugAttackWave("Expanded attack routes.");
   xsDisableRule("expandAttackRoutes");
}

void UnderworldRoute()
{
   int routeID = gAttackWave.mAttackRouteID;
   int routeID2 = gSecondAttackWave.mAttackRouteID;

   int pathID4 = kbPathCreate("Underworld Passage");
   kbPathAddWaypoint(pathID4, vector(99.0, 0.0, 113.0));    // 6th Waypoint
   kbAttackRouteAddPath(routeID, pathID4);
   kbAttackRouteAddPath(routeID2, pathID4);
}

void updateDefendPlans()
{
   // We move it to in front of our Citadel that's not on the hill.
   aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanTargetPoint, 0, vector(323.0, 5.0, 265.0));
   aiPlanSetVariableVector(gLandDefendPlan, cDefendPlanGatherPoint, 0, vector(323.0, 5.0, 265.0));
   debugAttackWave("Moved our defend plan towards Kemsyt.");
}

void Odysseus_Is_Here()
{
   gOdysseus_Here = true;
}

// *** TECHS ***
   // MYTHIC AGE
      // ALL DIFFICULTIES:
      // MODERATE ONLY:
         // Iron Weapons
            rule researchIronWeapons
            inactive
            minInterval 720
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
         // Champion Infantry
            rule researchChampionInfantry
            inactive
            minInterval 840
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
                  researchSimpleTech(cTechChampionInfantry, cUnitTypeMilitaryAcademy, -1, 60);
                  return;
               }
            }
         // Champion Cavalry
            rule researchChampionCavalry
            inactive
            minInterval 960
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionCavalry) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionCavalry");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionCavalry) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Cavalry research plan.");
                  researchSimpleTech(cTechChampionCavalry, cUnitTypeStable, -1, 60);
                  return;
               }
            }
         // Champion Archers
            rule researchChampionArchers
            inactive
            minInterval 960
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
                  researchSimpleTech(cTechChampionArchers, cUnitTypeArcheryRange, -1, 60);
                  return;
               }
            }

      // HARD AND UP:
         // Burning Pitch
            rule researchBurningPitch
            inactive
            minInterval 600
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechBurningPitch) == cTechStatusActive)
               {
                  xsDisableRule("researchBurningPitch");
                  return;
               }
               else if (kbTechGetStatus(cTechBurningPitch) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Burning Pitch research plan.");
                  researchSimpleTech(cTechBurningPitch, cUnitTypeArmory, -1, 60);
                  return;
               }
            }
         // Champion Infantry
            rule researchChampionInfantryHT
            inactive
            minInterval 480
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionInfantryHT");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Infantry research plan.");
                  researchSimpleTech(cTechChampionInfantry, cUnitTypeMilitaryAcademy, -1, 60);
                  return;
               }
            }
         // Champion Cavalry
            rule researchChampionCavalryHT
            inactive
            minInterval 520
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionCavalry) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionCavalryHT");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionCavalry) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Cavalry research plan.");
                  researchSimpleTech(cTechChampionCavalry, cUnitTypeStable, -1, 60);
                  return;
               }
            }
         // Champion Archers
            rule researchChampionArchersHT
            inactive
            minInterval 440
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionArchers) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionArchersHT");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionArchers) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Archers research plan.");
                  researchSimpleTech(cTechChampionArchers, cUnitTypeArcheryRange, -1, 60);
                  return;
               }
            }
         // Iron Weapons
            rule researchIronWeaponsHT
            inactive
            minInterval 360
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechIronWeapons) == cTechStatusActive)
               {
                  xsDisableRule("researchIronWeaponsHT");
                  return;
               }
               else if (kbTechGetStatus(cTechIronWeapons) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Iron Weapons research plan.");
                  researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 60);
                  return;
               }
            }

      // HARD ONLY:
         // Iron Shields
            rule researchIronShields
            inactive
            minInterval 900
            {
               xsSetRuleMinIntervalSelf(10);
               if (kbTechGetStatus(cTechBronzeShields) == cTechStatusActive)
               {
                  debugAttackWave("Starting Iron Shields research plan.");
                  researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
                  xsDisableRule("researchIronShields");
               }
            }

      // TITAN ONLY:
         // Shafts of Plague
            rule researchShaftsOfPlague
            inactive
            minInterval 640
            {
               debugAttackWave("Starting Shafts of Plague research plan.");
               researchSimpleTech(cTechShaftsOfPlague, cUnitTypeArcheryRange, -1, 60);
               xsDisableRule("researchShaftsOfPlague");
            }
         // Iron Shields
            rule researchIronShieldsTitan
            inactive
            minInterval 480
            {
               xsSetRuleMinIntervalSelf(10);
               if (kbTechGetStatus(cTechBronzeShields) == cTechStatusActive)
               {
                  debugAttackWave("Starting Iron Shields research plan.");
                  researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
                  xsDisableRule("researchIronShieldsTitan");
               }
            }
         // Engineers
            rule researchEngineers
            inactive
            minInterval 900
            {
               debugAttackWave("Starting Engineers research plan.");
               researchSimpleTech(cTechEngineers, cUnitTypeFortress, -1, 60);
               xsDisableRule("researchEngineers");
            }