//==============================================================================
/* fott19_p2.xs
   Kamos (Player 2) is activated after they ‘discovers' the player’s presence. Only then may they begin managing their economy, train soldiers and attack. 
   They may receive some free villagers and military units to kick-start their base.

They attack regularly with Spearman, Scarabs and WarElephants, use slingers to protect their base.
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
float gNavalTrainDelay = 30; // In seconds.

// Gets trained from the start.
int gFirstLandUnit = cUnitTypeSpearman; 
float gMaintainFirstLandUnitAmount = 5;
int gSecondLandUnit = cUnitTypeSlinger; 
float gMaintainSecondLandUnitAmount = 5;
int gThirdLandUnit = cUnitTypeScarab; 
float gMaintainThirdLandUnitAmount = 2;
int gFourthLandUnit = cUnitTypeWarElephant;
float gMaintainFourthLandUnitAmount = 6;
int gFifthLandUnit = cUnitTypeAvenger;
float gMaintainFifthLandUnitAmount = 5; // No modifier.
int gSixthLandUnit = cUnitTypePriest;
float gMaintainSixthLandUnitAmount = 3;
int gSeventhLandUnit = cUnitTypeCamelRider;
float gMaintainSeventhLandUnitAmount = 2;

int gFirstNavalUnit = cUnitTypeKebenit;
float gMaintainFirstNavalUnitAmount = 4;
int gSecondNavalUnit = cUnitTypeLeviathan;
float gMaintainSecondNavalUnitAmount = 1;
int gThirdNavalUnit = cUnitTypeWarBarge;
float gMaintainThirdNavalUnitAmount = 2;

float gMaxVillagerCount = 14;
float gMaxFishingShipCount = 6;
float gAttackStartDelay = 300; // In seconds.
float gAttackWaveInterval = 300; // In Seconds.
float gAttackStartSize = 8;
float gAttackMaxSize = 14;

float gSecondAttackStartDelay = 360; // A few minutes after the first Colossus is made.
float gSecondAttackInterval = 600; // In Seconds.
float gSecondAttackStartSize = 4;
float gSecondAttackMaxSize = 8;

float gNavalAttackStartDelay = 480; // In seconds.
float gNavalAttackWaveInterval = 720; // In seconds.
float gNavalAttackStartSize = 3;
float gNavalAttackMaxSize = 5;

float gMythicAgeUpTime = 1800; // In seconds.

int gKamosDefendPlan = -1;
int gLandingDefendPlan = -1;
int gGateBuildPlan = -1;
int gGateDefendPlan = -1;
int gWaterDefendPlan = -1;
int gLeviathanDefendPlan = -1;

int gWakeUpTime = -1;
bool gAllowCamels = false;

Strategy scenarioAttackWaveStrategy()
{
   debugAttackWave("attack strategy");
   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugStrategy("***Starting Scenario Attack Wave Strategy***");
      xsEnableRuleGroup("ruleGroupTowers");
      xsEnableRuleGroup("ruleGroupGate");
      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================

      // Certain parameters are way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gMaintainFirstLandUnitAmount = 3;
         gMaintainSecondLandUnitAmount = 3;
         gMaintainFourthLandUnitAmount = 4;
         gMaintainSixthLandUnitAmount = 2;
         gMaintainFirstNavalUnitAmount = 3;

         gAttackStartSize = 4;
         gAttackMaxSize = 6;

         gNavalAttackStartSize = 2;
         gNavalAttackMaxSize = 3;
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      // No modifier for fifth land unit (Avenger).
      gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSeventhLandUnitAmount *= gDifficultyModifierMaintainUnit;

      gMaintainFirstNavalUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondNavalUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdNavalUnitAmount *= gDifficultyModifierMaintainUnit;

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      gSecondAttackInterval *= gDifficultyModifierAttackInterval;
      gSecondAttackStartSize *= gDifficultyModifierAttackSizes;
      gSecondAttackMaxSize *= gDifficultyModifierAttackSizes;

      gNavalAttackStartDelay *= gDifficultyModifierFirstAttack;
      gNavalAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gNavalAttackStartSize *= gDifficultyModifierAttackSizes;
      gNavalAttackMaxSize *= gDifficultyModifierAttackSizes;

      gTrainDelay *= gDifficultyModifierTrainDelay;
      gNavalTrainDelay *= gDifficultyModifierTrainDelay;

      gMythicAgeUpTime = gMythicAgeUpTime * gDifficultyModifierAgeUp;
      gWakeUpTime = xsGetTime();

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);

      data.addUnitToMaintain(gFirstNavalUnit, gMaintainFirstNavalUnitAmount);
      // Don't make Leviathans on Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         data.addUnitToMaintain(gSecondNavalUnit, gMaintainSecondNavalUnitAmount);
         data.setTrainDelay(gSecondNavalUnit, gNavalTrainDelay);
      }

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      // data.setTrainDelay(gFourthLandUnit, gTrainDelay);
      data.setTrainDelay(gSixthLandUnit, gTrainDelay);

      data.setTrainDelay(gFirstNavalUnit, gNavalTrainDelay);

      /*
      int explorePlanID = aiPlanCreate("Spearman Explore", cPlanExplore, -1);
      aiPlanSetPriority(explorePlanID, 99);
      aiPlanAddUnitType(explorePlanID, cUnitTypeSpearman, 1, 1, 1);
      */
      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      // Don't add Scarabs to attack waves until a bit later.
      gAttackWave.addAttackUnitType(gFourthLandUnit);
      // gAttackWave.addAttackUnitType(gFifthLandUnit);
      gAttackWave.addAttackUnitType(gSixthLandUnit);
      debugAttackWave("First Land Attack:");
      gAttackWave.displayFirstAttackStats();

      // Only deploy Leviathan landings on Hard and Titan.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gSecondAttackWave.setName("gSecondAttackWave");
         gSecondAttackWave.setAttackStartTime(gSecondAttackStartDelay);
         gSecondAttackWave.setAttackInterval(gSecondAttackInterval);
         gSecondAttackWave.setAttackSize(gSecondAttackStartSize);
         gSecondAttackWave.setMaxAttackSize(gSecondAttackMaxSize);
         gSecondAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
         gSecondAttackWave.addAttackUnitType(gThirdLandUnit);
         // gSecondAttackWave.addAttackUnitType(gFourthLandUnit);
         gSecondAttackWave.addAttackUnitType(gFifthLandUnit);
         // They use their Pharaoh to counter myth units.
         gSecondAttackWave.addAttackUnitType(cUnitTypePharaoh);

         debugAttackWave("Second Land Attack:");
         gSecondAttackWave.displayFirstAttackStats();
      }

      gNavalAttackWave.setName("gNavalAttackWave");
      gNavalAttackWave.setAttackStartTime(gNavalAttackStartDelay);   // Reduced to gNavalAttackStartDelay when called by trigger.
      gNavalAttackWave.setAttackInterval(gNavalAttackWaveInterval);
      gNavalAttackWave.setAttackSize(gNavalAttackStartSize);
      gNavalAttackWave.setMaxAttackSize(gNavalAttackMaxSize);
      gNavalAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gNavalAttackWave.addAttackUnitType(gFirstNavalUnit); // Kebenits
      // War Barges and Leviathans don't join attack waves until later.

      gNavalAttackWave.setIsNavalAttackWave();

      debugAttackWave("First Naval Attack:");
      gNavalAttackWave.displayFirstAttackStats();


      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticFishing, true);
      gTimeToFarm = true;

      gAttackWave.setPlayerToAttack(1); // Attack player 1!
      gSecondAttackWave.setPlayerToAttack(1); // Attack player 1!
      gNavalAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(173.0, 0.0, 209.0); // Center of base.
      vector targetPoint = vector(14.07, 3.67, 233.65); // Player's TC at the south-west.

      vector navalStartPoint = vector(145.0, 0.0, 103.0); // Above the Lighthouse.
      vector navalEndPoint = vector(28.19, 0.0, 203.01); // The shoreline closest to the enemy base.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Land Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Land Path");

      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(69.0, 0.0, 237.0));
      kbPathAddWaypoint(pathID1, targetPoint);

      kbAttackRouteAddPath(routeID,pathID1);

      // One route for attacks over the water.
      int navalRouteID = kbCreateAttackRouteWithPath("Naval Route To P1", navalStartPoint, navalEndPoint);
      int navalPathID = kbPathCreate("Naval Path");
      kbPathAddWaypoint(navalPathID, navalStartPoint);
      kbPathAddWaypoint(navalPathID, vector(19.0, 0.0, 155.0)); // Near the starting island.
      kbPathAddWaypoint(navalPathID, navalEndPoint);
      kbAttackRouteAddPath(navalRouteID, navalPathID);


      vector startPoint2 = vector(205.0, 0.0, 121.0); // Next to their eastern Dock.
      vector targetPoint2 = vector(31.0, 0.0, 125.0); // Western side of Arkantos' starting island.

      int routeID2 = kbCreateAttackRouteWithPath("Leviathan landings to Arkantos' starting island.", startPoint2, targetPoint2);
      int pathID2 = kbPathCreate("Leviathan path");

      kbPathAddWaypoint(pathID2, startPoint2);
      kbPathAddWaypoint(pathID2, vector(155.0, 0.0, 27.0));
      kbPathAddWaypoint(pathID2, vector(95.0, 0.0, 19.0));
      kbPathAddWaypoint(pathID2, vector(73.0, 0.0, 43.0));
      kbPathAddWaypoint(pathID2, vector(95.0, 0.0, 93.0));
      kbPathAddWaypoint(pathID2, targetPoint2);
      kbAttackRouteAddPath(routeID2,pathID2);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );
      gAttackWave.displayFirstAttackStats();

      aiUnitSetRallyPointToPosition(getUnit(cUnitTypeBarracks), startPoint);
      
      gSecondAttackWave.setGatherPoint(startPoint2);
      gSecondAttackWave.setTargetPoint(targetPoint2);
      gSecondAttackWave.setAttackRouteID(routeID2);
      gSecondAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );
      gSecondAttackWave.displayFirstAttackStats();

      gNavalAttackWave.setGatherPoint(navalStartPoint);
      gNavalAttackWave.setTargetPoint(navalEndPoint);
      gNavalAttackWave.setAttackRouteID(navalRouteID);
      gNavalAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      gKamosDefendPlan = createDefendPlan("TC 1 Land Defend", kbBaseGetMainID(cMyID), 50.0, vector(181.0, 0.0, 223.0), 10);
      
      aiPlanAddUnitType(gKamosDefendPlan, gFirstLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gKamosDefendPlan, gSecondLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gKamosDefendPlan, gFourthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gKamosDefendPlan, gSixthLandUnit, 0, 0, 200);

      gLandingDefendPlan = createDefendPlan("Transport Defend Plan", kbBaseGetMainID(cMyID), 10.0, vector(199.0, 0.0, 123.0), 10);
      aiPlanAddUnitType(gLandingDefendPlan, gThirdLandUnit, 0, 0, 200);
      aiPlanAddUnitType(gLandingDefendPlan, cUnitTypePharaoh, 0, 0, 200);

      gWaterDefendPlan = createDefendPlan("Water Defend Plan", -1, 12.0, vector(195.0, 0.0, 95.0), 15, vector(195.0, 0.0, 95.0));
      aiPlanAddUnitType(gWaterDefendPlan, gFirstNavalUnit, 0, 0, 200);

      gLeviathanDefendPlan = createDefendPlan("Leviathan Defend Plan", -1, 10.0, vector(209.0, 0.0, 117.0), 15, vector(209.0, 0.0, 117.0));
      aiPlanAddUnitType(gLeviathanDefendPlan, gSecondNavalUnit, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;
      static bool reachedMythic = false;

      int time = xsGetTime();
      if (done == false)
      {
         done = true;

         int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gSecondLandUnit);
         aiPlanSetVariableInt(
            planID,
            cTrainPlanFrequency,
            0,
            kbPlayerGetProtoStatFloat(cMyID, gSecondLandUnit, cProtoStatTrainPoints) + gTrainDelay
         );
         //gAttackWave.addAttackUnitType();
         //gAttackWave.addAttackUnitType(gSecondLandUnit);
      }

      static bool ageup = false;
      int age = kbPlayerGetAge(cMyID);
      if (ageup == false)
      {
         if (age < cAge4 && time >= gMythicAgeUpTime)
         {
            researchSimpleTech(cTechMythicAgeHorus, cUnitTypeTownCenter, -1, 75);
         }
         else if (age >= cAge4)
         {
            ageup = true;
         }
      }

      // * * * TECH RULES * * * //

      // HEROIC AGE //
      static bool heroic_techs = false;
      if (age >= cAge3 && heroic_techs == false)
      {
         // Tech Rules for All Difficulties:

         // Tech Rules for Moderate Only;
         if (cDifficultyCurrent == cDifficultyModerate)
         {
            xsEnableRule("researchHeavySpearmen");
            xsEnableRule("researchHeavySlingers");
         }

         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchBronzeWeapons");
            xsEnableRule("researchBronzeArmor");
            xsEnableRule("researchSlingsOfTheSun");
            xsEnableRule("researchBoilingOil");
            xsEnableRule("researchHeavyWarships");
            xsEnableRule("researchFortifiedTownCenter");
         }

         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchBronzeShields");
            xsEnableRule("researchGuardTower");
            xsEnableRule("researchBallistics");
            xsEnableRule("researchHeavyWarElephants");
            xsEnableRule("researchHeavyCamelRiders");
         }

         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchArchitects");
         }
         heroic_techs = true;
      }

      // MYTHIC AGE //
      if (age >= cAge4 && reachedMythic == false)
      {
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
            data.setTrainDelay(gFifthLandUnit, gTrainDelay);
            aiPlanAddUnitType(gLandingDefendPlan, gFifthLandUnit, 0, 0, 200);
            gAttackMaxSize += 5;
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
            gAttackWave.addAttackUnitType(gFifthLandUnit);
         }
         // Tech Rules for All Difficulties:
         xsEnableRule("researchFloodControl");
         xsEnableRule("researchQuarry");
         xsEnableRule("researchCarpenters");
         // Tech Rules for Moderate and Up:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchSaltAmphora");
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchBurningPitch");
            xsEnableRule("researchGreatestOfFifty");
            xsEnableRule("researchChampionWarships");
         }
         // Tech Rules for Hard and Titan:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchIronArmor");
            xsEnableRule("researchChampionSpearmen");
            xsEnableRule("researchChampionSlingers");
         }
         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchChampionWarElephants");
            xsEnableRule("researchChampionCamelRiders");
            xsEnableRule("researchSpearOfHorus");
            xsEnableRule("researchIronShields");
         }
         // Change the boolean back to false so the rules aren't enabled multiple times.
         reachedMythic = true;
      }

      // Start making War Barges after 10 minutes on Hard and Titan.
      static bool war_barges = false;
      if (time >= 600 + gWakeUpTime && war_barges == false)
      {
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            data.addUnitToMaintain(gThirdNavalUnit, gMaintainThirdNavalUnitAmount);
            data.setTrainDelay(gThirdNavalUnit, gNavalTrainDelay);
            aiPlanAddUnitType(gWaterDefendPlan, gThirdNavalUnit, 0, 0, 200);
            gNavalAttackMaxSize *= 1.15; // Increase naval attack size by +15%.
            gNavalAttackWave.setMaxAttackSize(gNavalAttackMaxSize);
         }
         war_barges = true;
      }
      // Leviathans join attack waves after 18 minutes on Hard and Titan.
      static bool leviathans = false;
      if (time >= 1080 + gWakeUpTime && leviathans == false)
      {
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            gNavalAttackWave.addAttackUnitType(gSecondNavalUnit); // Leviathans
            gNavalAttackMaxSize *= 1.05; // Increase naval attack size by +5%.
            gNavalAttackWave.setMaxAttackSize(gNavalAttackMaxSize);
         }
         leviathans = true;
      }

      // Start incorporating Scarabs into the attack waves after 12 minutes.
      static bool scarabs = false;
      if (scarabs == false)
      {
         if (time >= 720 + gWakeUpTime && cDifficultyCurrent != cDifficultyTitan)
         {
            data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
            gAttackWave.addAttackUnitType(gThirdLandUnit); // Scarabs
            gAttackMaxSize *= 1.05; // Increase attack size by +10%.
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
            scarabs = true;
         }
         else if (time >= 540 + gWakeUpTime && cDifficultyCurrent == cDifficultyTitan)
         {
            data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
            gAttackWave.addAttackUnitType(gThirdLandUnit); // Scarabs
            gAttackMaxSize *= 1.05; // Increase attack size by +5%.
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
            scarabs = true;
         }
      }

      // Make more Scarabs after 20 minutes.
      static bool more_scarabs = false;
      if (more_scarabs == false)
      {
         if (time >= 1200 + gWakeUpTime && cDifficultyCurrent >= cDifficultyHard)
         {
            gMaintainThirdLandUnitAmount *= 2; // Make +100% more Scarabs.
            data.adjustUnitToMaintainAmount(gThirdLandUnit, gMaintainThirdLandUnitAmount);
            gAttackMaxSize *= 1.05; // Increase attack size by +5%.
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }
      }

      // Make Camel Riders after the first scouts die.
      static bool added_camels = false;
      if (gAllowCamels == true && added_camels == false)
      {
         data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);
         aiPlanAddUnitType(gLandingDefendPlan, gSeventhLandUnit, 0, 0, 200);
         gSecondAttackWave.addAttackUnitType(gSeventhLandUnit);
         gSecondAttackWave.setMaxAttackSize(gSecondAttackMaxSize);
         added_camels = true;
      }


      gAttackWave.update();
      gSecondAttackWave.update();
      gNavalAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott19StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(197.00, 0.00, 152.00), 40);

   gOverrideClosestFishLocation = vector(210.00, 0.00, 91.00);
   gMaxFishDockScanRange = 90;

   setOverrideStrategy(fott19StrategySetup);

   // gOverrideFarmCount = 12;
   gRBDSystem.setMaxFarmsPerBase(32);
   gRBDSystem.setMaxFarmsPerIteration(32);
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, vector(191.0, 5.76, 159), 15.0); // Our TC.
      kbBuildingPlacementAddPositionInfluence(bpID, vector(191.0, 5.76, 159), 100.0, 15.0, cFalloffLinear); // Our TC.
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
void postInit() {}

// Build Gate

rule buildGate
inactive
minInterval 30
group ruleGroupGate
{
   xsSetRuleMinInterval("buildGate", 10);

   vector centerPosition = vector(106.00, 4.50, 223.00);
   int numPlayerUnits = getUnitCountByLocation(cUnitTypeUnit, 1, cUnitStateAlive, centerPosition, 15.0);
   int numPlayerBuildings = getUnitCountByLocation(cUnitTypeAbstractWall, 1, cUnitStateAlive, centerPosition, 15.0);
   int numPlayerTotal = numPlayerUnits + numPlayerBuildings;
   if (numPlayerTotal <= 0)
   {
      // Build plan.
      gGateBuildPlan = aiPlanCreate("Wall/Gate Plan", cPlanBuildWall);
      aiPlanSetVariableInt(gGateBuildPlan, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeStraight);
      aiPlanAddUnitType(gGateBuildPlan, cUnitTypeAbstractVillager, 0, 1, 1);
      aiPlanSetVariableVector(gGateBuildPlan, cBuildWallPlanWallStart, 0, vector(111.00, 5.59, 229.00));
      aiPlanSetVariableVector(gGateBuildPlan, cBuildWallPlanWallEnd, 0, vector(101.29, 4.08, 217.06));
      aiPlanSetVariableInt(gGateBuildPlan, cBuildWallPlanNumberOfGates, 0, 1);
      aiPlanSetPriority(gGateBuildPlan, 99);
      aiPlanSetEventHandler(gGateBuildPlan, cPlanEventStateChange, "gateBuildPlanEventHandler");
      xsEnableRule("killGatePlan");
      xsDisableRule("buildGate");
   }
   else
   {
      debugAttackWave("numPlayerTotal: " + numPlayerTotal + ", not building the Wall & Gate now.");
   }
}

void gateBuildPlanEventHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateDone || state == cPlanStateFailed) // We're done or it failed, whatever just end the defend plan.
   {
      debugAttackWave("Our gate build plan is done, destroying our accompanying defend plan.");
      if (gGateDefendPlan != -1)
      {
         aiPlanDestroy(gGateDefendPlan);
         aiPlanAddUnitType(gKamosDefendPlan, gFirstLandUnit, 0, 0, 200);
         aiPlanAddUnitType(gKamosDefendPlan, gSecondLandUnit, 0, 0, 200);
      }
      xsDisableRule("killGatePlan");
   }
}

rule gateDefenders
inactive
minInterval 30
group ruleGroupGate
{
   int firstLandUnitDefendAmount = selectByDifficulty(3, 6, 6, 6, 6, 6);
   int secondLandUnitDefendAmount = selectByDifficulty(2, 6, 6, 6, 6, 6);
   
   gGateDefendPlan = createDefendPlan("Gate Defense", kbBaseGetMainID(cMyID), 15.0, vector(111.00, 3.00, 215.00), 10);
   aiPlanSetVariableFloat(gGateDefendPlan, cDefendPlanEngageRange, 0, 20.0);
   aiPlanAddUnitType(gGateDefendPlan, gFirstLandUnit, 0, 0, firstLandUnitDefendAmount);
   aiPlanAddUnitType(gGateDefendPlan, gSecondLandUnit, 0, 0, secondLandUnitDefendAmount);

   xsDisableRule("gateDefenders");
}

rule killGatePlan
inactive
minInterval 300
{
   if (gGateDefendPlan != -1)
   {
      aiPlanDestroy(gGateDefendPlan);
      xsEnableRule("templeDefenders");
   }
   xsDisableRule("killGatePlan");
}

// Build Watch Towers

rule buildWatchTower1
inactive
minInterval 720
group ruleGroupTowers
{
   xsSetRuleMinInterval("buildWatchTower1", 10);

   vector buildPosition1 = vector(185.0, 0.00, 225.0); // Upper-Left of Temple.
   int numPlayerUnits = getUnitCountByLocation(cUnitTypeUnit, 1, cUnitStateAlive, buildPosition1, 15.0);
   int numPlayerBuildings = getUnitCountByLocation(cUnitTypeBuilding, 1, cUnitStateAlive, buildPosition1, 15.0);
   int numPlayerTotal = numPlayerUnits + numPlayerBuildings;
   if (numPlayerTotal <= 0)
   {
      // Build plan.
      int buildPlanID = aiPlanCreate("Tower 1 Build Plan", cPlanBuild, -1);
      int bpID = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID));
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeSentryTower);
      kbBuildingPlacementSetCenterPosition(bpID, buildPosition1, 8.0);
      kbBuildingPlacementSetStepSize(bpID, 0.5);
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementAddPositionInfluence(bpID, buildPosition1, 100.0, 50.0, cFalloffLinear);
      aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, cUnitTypeSentryTower);
      aiPlanAddUnitType(buildPlanID, cUnitTypeVillagerEgyptian, 2, 2, 2);
      aiPlanSetPriority(buildPlanID, 99);
      xsDisableRule("buildWatchTower1");
   }
   else
   {
      debugAttackWave("numPlayerTotal: " + numPlayerTotal + ", not building the Tower now.");
   }
}

rule buildWatchTower2
inactive
minInterval 720
group ruleGroupTowers
{
   xsSetRuleMinInterval("buildWatchTower2", 10);

   vector buildPosition2 = vector(196.0, 0.00, 209.0); // Upper-Right of Temple.
   int numPlayerUnits = getUnitCountByLocation(cUnitTypeUnit, 1, cUnitStateAlive, buildPosition2, 15.0);
   int numPlayerBuildings = getUnitCountByLocation(cUnitTypeBuilding, 1, cUnitStateAlive, buildPosition2, 15.0);
   int numPlayerTotal = numPlayerUnits + numPlayerBuildings;
   if (numPlayerTotal <= 0)
   {
      // Build plan.
      int buildPlanID = aiPlanCreate("Tower 2 Build Plan", cPlanBuild, -1);
      int bpID = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID));
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeSentryTower);
      kbBuildingPlacementSetCenterPosition(bpID, buildPosition2, 8.0);
      kbBuildingPlacementSetStepSize(bpID, 0.5);
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementAddPositionInfluence(bpID, buildPosition2, 100.0, 50.0, cFalloffLinear);
      aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, cUnitTypeSentryTower);
      aiPlanAddUnitType(buildPlanID, cUnitTypeVillagerEgyptian, 2, 2, 2);
      aiPlanSetPriority(buildPlanID, 99);
      xsDisableRule("buildWatchTower2");
   }
   else
   {
      debugAttackWave("numPlayerTotal: " + numPlayerTotal + ", not building the Tower now.");
   }
}

rule buildWatchTower3
inactive
minInterval 720
group ruleGroupTowers
{
   xsSetRuleMinInterval("buildWatchTower3", 10);

   vector buildPosition3 = vector(170.0, 0.00, 213.0); // Bottom-Left of Temple.
   int numPlayerUnits = getUnitCountByLocation(cUnitTypeUnit, 1, cUnitStateAlive, buildPosition3, 15.0);
   int numPlayerBuildings = getUnitCountByLocation(cUnitTypeBuilding, 1, cUnitStateAlive, buildPosition3, 15.0);
   int numPlayerTotal = numPlayerUnits + numPlayerBuildings;
   if (numPlayerTotal <= 0)
   {
      // Build plan.
      int buildPlanID = aiPlanCreate("Tower 3 Build Plan", cPlanBuild, -1);
      int bpID = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID));
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeSentryTower);
      kbBuildingPlacementSetCenterPosition(bpID, buildPosition3, 8.0);
      kbBuildingPlacementSetStepSize(bpID, 0.5);
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementAddPositionInfluence(bpID, buildPosition3, 100.0, 50.0, cFalloffLinear);
      aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, cUnitTypeSentryTower);
      aiPlanAddUnitType(buildPlanID, cUnitTypeVillagerEgyptian, 2, 2, 2);
      aiPlanSetPriority(buildPlanID, 99);
      xsDisableRule("buildWatchTower3");
   }
   else
   {
      debugAttackWave("numPlayerTotal: " + numPlayerTotal + ", not building the Tower now.");
   }
}

rule buildWatchTower4
inactive
minInterval 720
group ruleGroupTowers
{
   xsSetRuleMinInterval("buildWatchTower4", 10);

   vector buildPosition4 = vector(188.0, 0.00, 197.0); // Bottom-Right of Temple.
   int numPlayerUnits = getUnitCountByLocation(cUnitTypeUnit, 1, cUnitStateAlive, buildPosition4, 15.0);
   int numPlayerBuildings = getUnitCountByLocation(cUnitTypeBuilding, 1, cUnitStateAlive, buildPosition4, 15.0);
   int numPlayerTotal = numPlayerUnits + numPlayerBuildings;
   if (numPlayerTotal <= 0)
   {
      // Build plan.
      int buildPlanID = aiPlanCreate("Tower 4 Build Plan", cPlanBuild, -1);
      int bpID = kbBuildingPlacementCreate(aiPlanGetName(buildPlanID));
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeSentryTower);
      kbBuildingPlacementSetCenterPosition(bpID, buildPosition4, 8.0);
      kbBuildingPlacementSetStepSize(bpID, 0.5);
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementAddPositionInfluence(bpID, buildPosition4, 100.0, 50.0, cFalloffLinear);
      aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0, cUnitTypeSentryTower);
      aiPlanAddUnitType(buildPlanID, cUnitTypeVillagerEgyptian, 2, 2, 2);
      aiPlanSetPriority(buildPlanID, 99);
      xsDisableRule("buildWatchTower4");
   }
   else
   {
      debugAttackWave("numPlayerTotal: " + numPlayerTotal + ", not building the Tower now.");
   }
}

// TECH RULES //

// *** HEROIC AGE TECHS *** //
   // MODERATE ONLY:
      // Heavy Spearmen
         rule researchHeavySpearmen
         active
         minInterval 240
         {
            xsSetRuleMinIntervalSelf(10);
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
      // Heavy Slingers
      rule researchHeavySlingers
      active
      minInterval 360
      {
         xsSetRuleMinIntervalSelf(10);
         // Cease if we have it. Otherwise, research it.
         if (kbTechGetStatus(cTechHeavySlingers) == cTechStatusActive)
         {
            xsDisableRule("researchHeavySlingers");
            return;
         }
         else if (kbTechGetStatus(cTechHeavySlingers) == cTechStatusObtainable)
         {
            debugAttackWave("Starting Heavy Slingers research plan.");
            researchSimpleTech(cTechHeavySlingers, cUnitTypeBarracks, -1, 60);
            return;
         }
      }

   // MODERATE AND UP:
      // Bronze Weapons
         rule researchBronzeWeapons
         inactive
         minInterval 300
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
      // Bronze Armor
         rule researchBronzeArmor
         inactive
         minInterval 300
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
      // Bronze Shields
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
         // Boiling Oil
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
         // Slings of the Sun
         rule researchSlingsOfTheSun
         active
         minInterval 360
         {
            debugAttackWave("Starting Slings Of The Sun research plan.");
            researchSimpleTech(cTechSlingsOfTheSun, cUnitTypeBarracks, -1, 50);
            xsDisableRule("researchSlingsOfTheSun");
         }
         // Heavy Warships
         rule researchHeavyWarships
         active
         minInterval 300
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechHeavyWarships) == cTechStatusActive)
            {
               xsDisableRule("researchHeavyWarships");
               return;
            }
            else if (kbTechGetStatus(cTechHeavyWarships) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Heavy Warships research plan.");
               researchSimpleTech(cTechHeavyWarships, cUnitTypeDock, -1, 60);
               return;
            }
         }
         // Fortified Town Center
         rule researchFortifiedTownCenter
         inactive
         minInterval 720
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

   // HARD AND TITAN
      // Guard Tower
         rule researchGuardTower
         inactive
         minInterval 950
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
      // Ballistics
         rule researchBallistics
         inactive
         minInterval 550
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
      // Heavy War Elephants
         rule researchHeavyWarElephants
         active
         minInterval 360
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechHeavyWarElephants) == cTechStatusActive)
            {
               xsDisableRule("researchHeavyWarElephants");
               return;
            }
            else if (kbTechGetStatus(cTechHeavyWarElephants) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Heavy War Elephants research plan.");
               researchSimpleTech(cTechHeavyWarElephants, cUnitTypeMigdolStronghold, -1, 60);
               return;
            }
         }
      // Heavy Camel Riders
         rule researchHeavyCamelRiders
         active
         minInterval 480
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechHeavyCamelRiders) == cTechStatusActive)
            {
               xsDisableRule("researchHeavyCamelRiders");
               return;
            }
            else if (kbTechGetStatus(cTechHeavyCamelRiders) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Heavy Camel Riders research plan.");
               researchSimpleTech(cTechHeavyCamelRiders, cUnitTypeMigdolStronghold, -1, 60);
               return;
            }
         }

   // TITAN ONLY
      // Architects
         rule researchArchitects
         inactive
         minInterval 880
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

// *** MYTHIC AGE TECHS *** //
   // ALL DIFFICULTIES
         // Quarry
            rule researchQuarry
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechQuarry) == cTechStatusActive)
               {
                  xsDisableRule("researchQuarry");
                  return;
               }
               else if (kbTechGetStatus(cTechQuarry) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Quarry research plan.");
                  researchSimpleTech(cTechQuarry, cUnitTypeMiningCamp, -1, 60);
                  return;
               }
            }
         // Flood Control
            rule researchFloodControl
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
            {
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechFloodControl) == cTechStatusActive)
               {
                  xsDisableRule("researchFloodControl");
                  return;
               }
               else if (kbTechGetStatus(cTechFloodControl) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Flood Control research plan.");
                  researchSimpleTech(cTechFloodControl, cUnitTypeGranary, -1, 60);
                  return;
               }
            }
         // Carpenters
            rule researchCarpenters
            inactive
            minInterval 10 // Get the tech right after the rule is enabled
            {
               researchSimpleTech(cTechCarpenters, cUnitTypeLumberCamp, -1, 60);
               xsDisableRule("researchCarpenters"); // Disable self.
            }

   // MODERATE AND UP
      // Salt Amphora
         rule researchSaltAmphora
         inactive
         minInterval 30
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechSaltAmphora) == cTechStatusActive)
            {
               xsDisableRule("researchSaltAmphora");
               return;
            }
            else if (kbTechGetStatus(cTechSaltAmphora) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Salt Amphora research plan.");
               researchSimpleTech(cTechSaltAmphora, cUnitTypeDock, -1, 60);
               return;
            }
         }
      // Iron Weapons
         rule researchIronWeapons
         inactive
         minInterval 120
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
      // Burning Pitch
         rule researchBurningPitch
         inactive
         minInterval 300
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
      // Greatest of Fifty
         rule researchGreatestOfFifty
         inactive
         minInterval 480
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechGreatestOfFifty) == cTechStatusActive)
            {
               xsDisableRule("researchGreatestOfFifty");
               return;
            }
            else if (kbTechGetStatus(cTechGreatestOfFifty) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Greatest of Fifty research plan.");
               researchSimpleTech(cTechGreatestOfFifty, cUnitTypeBarracks, -1, 60);
               return;
            }
         }
      // Champion Warships
         rule researchChampionWarships
         inactive
         minInterval 320
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechChampionWarships) == cTechStatusActive)
            {
               xsDisableRule("researchChampionWarships");
               return;
            }
            else if (kbTechGetStatus(cTechChampionWarships) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Champion Warships research plan.");
               researchSimpleTech(cTechChampionWarships, cUnitTypeDock, -1, 60);
               return;
            }
         }

   // HARD AND TITAN
      // Iron Armor
         rule researchIronArmor
         inactive
         minInterval 240
         {
            xsSetRuleMinIntervalSelf(10);
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
      // Champion Spearmen
         rule researchChampionSpearmen
         active
         minInterval 120
         {
            xsSetRuleMinIntervalSelf(10);
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
      // Champion Slingers
         rule researchChampionSlingers
         active
         minInterval 120
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechChampionSlingers) == cTechStatusActive)
            {
               xsDisableRule("researchChampionSlingers");
               return;
            }
            else if (kbTechGetStatus(cTechChampionSlingers) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Champion Slingers research plan.");
               researchSimpleTech(cTechChampionSlingers, cUnitTypeBarracks, -1, 60);
               return;
            }
         }

   // TITAN ONLY
         // Champion War Elephants
         rule researchChampionWarElephants
         active
         minInterval 540
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechChampionWarElephants) == cTechStatusActive)
            {
               xsDisableRule("researchChampionWarElephants");
               return;
            }
            else if (kbTechGetStatus(cTechChampionWarElephants) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Champion War Elephants research plan.");
               researchSimpleTech(cTechChampionWarElephants, cUnitTypeMigdolStronghold, -1, 60);
               return;
            }
         }
         // Champion Camel Riders
         rule researchChampionCamelRiders
         active
         minInterval 640
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechChampionCamelRiders) == cTechStatusActive)
            {
               xsDisableRule("cTechChampionCamelRiders");
               return;
            }
            else if (kbTechGetStatus(cTechChampionCamelRiders) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Champion Camel Riders research plan.");
               researchSimpleTech(cTechChampionCamelRiders, cUnitTypeMigdolStronghold, -1, 60);
               return;
            }
         }

      // Spear of Horus
         rule researchSpearOfHorus
         active
         minInterval 500
         {
            xsSetRuleMinIntervalSelf(10);
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
      // Iron Shields
         rule researchIronShields
         inactive
         minInterval 360
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

// Move defend plan (when nearby buildings are destroyed)
   void updateLandingPlan()
   {
      // Nearby buildings are destroyed. We will move our defend plan behind the inner walls.
      aiPlanSetVariableVector(gLandingDefendPlan, cDefendPlanTargetPoint, 0, vector(199.0, 0.0, 195.0));
      aiPlanSetVariableVector(gLandingDefendPlan, cDefendPlanGatherPoint, 0, vector(199.0, 0.0, 195.0));
      debugAttackWave("Contracted our defense plan.");
   }

// Start making new Camel Riders after the initial scouts die.
   void newCamels()
   {
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gAllowCamels = true;
      }
   }