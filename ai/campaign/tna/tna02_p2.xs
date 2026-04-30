//==============================================================================
/* tna02_p2.xs

   Red Greek player that maintains the four Military Academies behind the gate and launches infantry attacks.
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
mutable void addNewRoutes() {}

float gHopliteDelay = 3; // In seconds.
float gHypaspistDelay = 5; // In seconds.

int gFirstLandUnit = cUnitTypeHoplite;
float gMaintainFirstLandUnitAmount = 6;
int gSecondLandUnit = cUnitTypeHypaspist;
float gMaintainSecondLandUnitAmount = 4;

float gMaxVillagerCount = 0; // No Villagers.
float gAttackStartDelay = 10; // In seconds.
float gAttackWaveInterval = 240; // In seconds.
float gAttackStartSize = 4;
float gAttackMaxSize = 10;

int gLandDefendPlan = -1;

vector gStartPoint  = vector(120.01, 0.03, 193.17); // Behind the gate.
vector gTargetPoint = vector(316.74, 6.19, 316.86); // Next to P1's TC.

Strategy scenarioAttackWaveStrategy()
{
   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugStrategy("***Starting Scenario Attack Wave Strategy***");

      // Start enabling rules.
      // There are no rules right now.

      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================

      // Make certain parameters way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         // Feeble attacks.
         gAttackStartSize = 3;
         gAttackMaxSize = 4;

         // Attacks takes longer to be dispatched.
         gAttackWaveInterval = 600;
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gHopliteDelay *= gDifficultyModifierTrainDelay;
      gHypaspistDelay *= gDifficultyModifierTrainDelay;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      // Don't give them a train delay on Hard and Titan; let them use all 4 Academies simultaneously.
      if (cDifficultyCurrent <= cDifficultyModerate)
      {
         data.setTrainDelay(gFirstLandUnit, gHopliteDelay);
         data.setTrainDelay(gSecondLandUnit, gHypaspistDelay);
      }

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(cWaitWithAttacking);
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

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", gStartPoint, gTargetPoint);
      int pathID1 = kbPathCreate("Left Entrance to P1");
      kbPathAddWaypoint(pathID1, gStartPoint);

      kbPathAddWaypoint(pathID1, vector(123.98, 0.01, 261.10)); // Waypoint #1
      kbPathAddWaypoint(pathID1, vector(154.56, 0.06, 294.05)); // Waypoint #2
      kbPathAddWaypoint(pathID1, vector(145.11, 0.06, 310.09)); // Waypoint #3
      kbPathAddWaypoint(pathID1, vector(161.85, 0.17, 336.97)); // Waypoint #4
      kbPathAddWaypoint(pathID1, vector(278.53, 6.14, 332.04)); // Waypoint #5

      kbPathAddWaypoint(pathID1, gTargetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      gAttackWave.setGatherPoint(gStartPoint);
      gAttackWave.setTargetPoint(gTargetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
            static int counter = 0;
            if (counter == 1)
            {
               addNewRoutes();
            }
            counter++;
         }
      );

      gLandDefendPlan = createDefendPlan("Primary Land Defend", -1, 15.0, gStartPoint, 20, gStartPoint);
      // Exclude Myrmidons, which need to stay in place.
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeHoplite, 0, 0, 200);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeHypaspist, 0, 0, 200);
      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool buffed_army = false;
      // Train more units after 900 seconds on harder difficulties.
      if (cDifficultyCurrent >= cDifficultyHard && buffed_army == false)
      {
         if (xsGetTime() >= 900)
         {
            gMaintainFirstLandUnitAmount *= 1.5; // Train +50% Hoplites.
            gMaintainSecondLandUnitAmount *= 1.5; // Train +50% Hypaspists.

            data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
            data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
                                 
            // Update attack size parameters based on the enlarged army composition.
            gAttackMaxSize *= 1.20; // Attack size increases by +20%
            gAttackWave.setMaxAttackSize(gAttackMaxSize);

            buffed_army = true;
         }
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void tna02StrategySetup()
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
   gOverrideMaxVillagerPop = gMaxVillagerCount;
   setOverrideStrategy(tna02StrategySetup);
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

// Called from the triggers to enable attacks. -> E04_P2_Attacks_Begin
void BeginAttacksP2()
{
   debugAttackWave("*** ATTACKS ARE NOW ENABLED ***");
   gAttackWave.setAttackStartTime(gAttackStartDelay);
   gAttackWave.displayFirstAttackStats();
}

// Called after the first attack plan is launched; causes the AI to alternate between the three paths leading to
// the player's main base.

void addNewRoutes()
{
   debugAttackWave("Added 2 new attack paths.");

   // Come from the path south of the TC.
   int pathID2 = kbPathCreate("Middle Entrance to P1");
   kbPathAddWaypoint(pathID2, gStartPoint);
   kbPathAddWaypoint(pathID2, vector(123.98, 0.01, 261.10)); // Waypoint #1
   kbPathAddWaypoint(pathID2, vector(154.56, 0.06, 294.05)); // Waypoint #2
   kbPathAddWaypoint(pathID2, vector(145.11, 0.06, 310.09)); // Waypoint #3
   kbPathAddWaypoint(pathID2, vector(161.85, 0.17, 336.97)); // Waypoint #4
   kbPathAddWaypoint(pathID2, vector(278.53, 6.14, 332.04)); // Waypoint #5
   kbPathAddWaypoint(pathID2, vector(271.03, 0.01, 283.28)); // Waypoint #6
   kbPathAddWaypoint(pathID2, gTargetPoint);
   kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID2);


   // Go around by the first Overgrown Temple by the eastern beach.
   int pathID3 = kbPathCreate("Right Entrance to P1");
   kbPathAddWaypoint(pathID3, gStartPoint);
   kbPathAddWaypoint(pathID3, vector(123.98, 0.01, 261.10)); // Waypoint #1
   kbPathAddWaypoint(pathID3, vector(154.56, 0.06, 294.05)); // Waypoint #2
   kbPathAddWaypoint(pathID3, vector(145.11, 0.06, 310.09)); // Waypoint #3
   kbPathAddWaypoint(pathID3, vector(161.85, 0.17, 336.97)); // Waypoint #4
   kbPathAddWaypoint(pathID3, vector(278.53, 6.14, 332.04)); // Waypoint #5
   kbPathAddWaypoint(pathID3, vector(271.03, 0.01, 283.28)); // Waypoint #6
   kbPathAddWaypoint(pathID3, vector(286.99, 0.00, 231.44)); // Waypoint #7
   kbPathAddWaypoint(pathID3, vector(329.42, 0.00, 248.70)); // Waypoint #8
   kbPathAddWaypoint(pathID3, gTargetPoint);
   kbAttackRouteAddPath(gAttackWave.mAttackRouteID, pathID3);
   return;
}