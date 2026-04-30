//==============================================================================
/* tna02_p3.xs

   Red Greek player that owns a large, well-defended base and launches
   occasional attacks.
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
float gHopliteDelay = 5; // In seconds.
float gToxotesDelay = 5; // In seconds.
float gHippeusDelay = 8; // In seconds.
float gMythUnitDelay = 30; // In seconds.
float gPetrobolosDelay = 10; // In seconds.
float gDonkeyDelay = 10; // In seconds.

float gTriremeDelay = 5; // In seconds.

int gFirstLandUnit = cUnitTypeHoplite;
float gMaintainFirstLandUnitAmount = 5;
int gSecondLandUnit = cUnitTypeToxotes;
float gMaintainSecondLandUnitAmount = 5;
int gThirdLandUnit = cUnitTypeHippeus;
float gMaintainThirdLandUnitAmount = 4;
int gFourthLandUnit = cUnitTypeManticore;
float gMaintainFourthLandUnitAmount = 1;
int gFifthLandUnit = cUnitTypeMinotaur;
float gMaintainFifthLandUnitAmount = 1;
int gSixthLandUnit = cUnitTypePetrobolos;
float gMaintainSixthLandUnitAmount = 1;

int gSeventhLandUnit = cUnitTypeCaravanGreek;
float gMaintainSeventhLandUnitAmount = 3;

int gFirstNavalUnit = cUnitTypeTrireme;
float gMaintainFirstNavalUnitAmount = 4;

float gMaxVillagerCount = 12;
float gAttackStartDelay = 1200;
float gAttackWaveInterval = 600; // In seconds.
float gAttackStartSize = 6;
float gAttackMaxSize = 15;

float gNavalAttackStartDelay = 99999; // Does not attack unless Kastor owns 4 naval military units.
float gNavalAttackWaveInterval = 480; // In Seconds.
float gNavalAttackStartSize = 3;
float gNavalAttackMaxSize = 4; // Up to 10, but it only trains 4. 

float gInitialAttackStartSize = 6; // Used to calculate new values from increments before applying the multiplier.
float gInitialAttackMaxSize = 15; // Used to calculate new values from increments before applying the multiplier.

bool gEnableAttacks = false; // Flipped by function EnableNavalAttacks()

int gLandDefendPlan = -1;
int gNavalDefendPlan = -1;

int gTradePlanP3 = -1;

float gHeroicAgeUpTime = 1500; // In seconds.

Strategy scenarioAttackWaveStrategy()
{

   // Start enabling rules.

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
         gAttackStartSize = 3;
         gAttackMaxSize = 5;

         gInitialAttackStartSize = 3;
         gInitialAttackMaxSize = 5;

         gNavalAttackWaveInterval = 900; // In Seconds.
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSixthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSeventhLandUnitAmount *= gDifficultyModifierMaintainUnit;
      if (gMaintainSeventhLandUnitAmount > 10)
      {
         gMaintainSeventhLandUnitAmount = 10; // Can't be higher than 10.
      }

      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackStartDelay += xsGetTime(); // Offset for wakeup.

      gHopliteDelay *= gDifficultyModifierTrainDelay;
      gToxotesDelay *= gDifficultyModifierTrainDelay;
      gHippeusDelay *= gDifficultyModifierTrainDelay;
      gMythUnitDelay *= gDifficultyModifierTrainDelay;
      gPetrobolosDelay *= gDifficultyModifierTrainDelay;
      gDonkeyDelay *= gDifficultyModifierTrainDelay;
      gTriremeDelay *= gDifficultyModifierTrainDelay;

      gHeroicAgeUpTime = gHeroicAgeUpTime * gDifficultyModifierAgeUp;
      gHeroicAgeUpTime += xsGetTime();

      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
      data.addUnitToMaintain(gFirstNavalUnit, gMaintainFirstNavalUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.

      // Only myth units have train delays on Titan.
      if (cDifficultyCurrent != cDifficultyTitan)
      {
         data.setTrainDelay(gFirstLandUnit, gHopliteDelay);
         data.setTrainDelay(gSecondLandUnit, gToxotesDelay);
         data.setTrainDelay(gThirdLandUnit, gHippeusDelay);
         data.setTrainDelay(gSixthLandUnit, gPetrobolosDelay);
         data.setTrainDelay(gSeventhLandUnit, gDonkeyDelay);
         data.setTrainDelay(gFirstNavalUnit, gTriremeDelay);
      }
      data.setTrainDelay(gFourthLandUnit, gMythUnitDelay);
      data.setTrainDelay(gFifthLandUnit, gMythUnitDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit);
      gAttackWave.addAttackUnitType(gSecondLandUnit);
      gAttackWave.addAttackUnitType(gThirdLandUnit);
      gAttackWave.addAttackUnitType(gFourthLandUnit);
      gAttackWave.addAttackUnitType(gFifthLandUnit);
      // Avoid Petroboli until way later.

      gNavalAttackWave.setName("gNavalAttackWave");
      gNavalAttackWave.setAttackStartTime(gNavalAttackStartDelay);
      gNavalAttackWave.setAttackInterval(gNavalAttackWaveInterval);
      gNavalAttackWave.setAttackSize(gNavalAttackStartSize);
      gNavalAttackWave.setMaxAttackSize(gNavalAttackMaxSize);
      gNavalAttackWave.setMinAttackSize(gNavalAttackStartSize);
      gNavalAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gNavalAttackWave.setMinAttackSize(gNavalAttackStartSize);
      gNavalAttackWave.addAttackUnitType(gFirstNavalUnit);
      gNavalAttackWave.setIsNavalAttackWave();

   // Trade Plans.
      int marketID = getUnit(cUnitTypeMarket);
      int targetTownCenterID = -1;

      // Trade to P3 Town Center.
      targetTownCenterID = getUnit(cUnitTypeTownCenter, 3);
      gTradePlanP3 = aiPlanCreate("Trade With P3", cPlanTrade);
      aiPlanSetVariableInt(gTradePlanP3, cTradePlanTargetUnitTypeID, 0, cUnitTypeTownCenter);
      aiPlanSetVariableInt(gTradePlanP3, cTradePlanTargetUnitID, 0, targetTownCenterID);
      aiPlanSetPriority(gTradePlanP3, 100);
      aiPlanAddUnitType(gTradePlanP3, cUnitTypeCaravanGreek, 0, 0, 200);
      aiPlanSetVariableInt(gTradePlanP3, cTradePlanMarketID, 0, marketID);
      aiPlanSetVariableBool(gTradePlanP3, cTradePlanUpdateTarget, 0, false);

      // Techs
      xsEnableRule("researchPlow");
      xsEnableRule("researchCopperShields");
      xsEnableRule("researchCopperWeaponsArmor");
      if(cDifficultyCurrent == cDifficultyEasy)
      {
         xsEnableRule("researchMediumInfantryEasy");
      }

      // Not Easy
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         xsEnableRule("researchMediumCavalry");
         xsEnableRule("researchMediumArchers");
         // Medium Infantry is already researched on Hard and Titan.
         if (cDifficultyCurrent == cDifficultyModerate)
         {
            xsEnableRule("researchMediumInfantry");
         }
      }

      // Hard and Titan Only
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         xsEnableRule("researchMasons");
         xsEnableRule("researchLabyrinthOfMinos");
      }

      // Titan Only
      if (cDifficultyCurrent == cDifficultyTitan)
      {
         xsEnableRule("researchSarissa");
         xsEnableRule("researchAegisShield");
      }

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticFishing, true); // Utilize starting fishing boats.

      gAttackWave.setPlayerToAttack(1); // Attack player 1!
      gNavalAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(180.69, 0.00, 117.29); // Next to the Armory.
      vector targetPoint = vector(316.74, 6.19, 316.86); // Next to P1's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Left Entrance to P1");
      kbPathAddWaypoint(pathID1, startPoint);

      kbPathAddWaypoint(pathID1, vector(123.98, 0.01, 261.10)); // Waypoint #1
      kbPathAddWaypoint(pathID1, vector(154.56, 0.06, 294.05)); // Waypoint #2
      kbPathAddWaypoint(pathID1, vector(145.11, 0.06, 310.09)); // Waypoint #3
      kbPathAddWaypoint(pathID1, vector(161.85, 0.17, 336.97)); // Waypoint #4
      kbPathAddWaypoint(pathID1, vector(278.53, 6.14, 332.04)); // Waypoint #5

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
      vector startPoint2 = vector(304.79, -0.52, 40.24); // At the eastern Dock.
      vector targetPoint2 = vector(354.75, -0.52, 358.27); // Above P1's starting Sky Passage.

      int routeID2 = kbCreateAttackRouteWithPath("Naval Route To P1", startPoint2, targetPoint2);
      int pathID2 = kbPathCreate("Naval Path 1");
      kbPathAddWaypoint(pathID2, startPoint2);

      kbPathAddWaypoint(pathID2, vector(390.82, -0.52, 51.62)); // Waypoint #1
      kbPathAddWaypoint(pathID2, vector(350.69, -0.52, 252.03)); // Waypoint #2

      kbPathAddWaypoint(pathID2, targetPoint2);
      kbAttackRouteAddPath(routeID2, pathID2);

      int pathID3 = kbPathCreate("Naval Path 2");
      kbPathAddWaypoint(pathID3, startPoint2);

      kbPathAddWaypoint(pathID3, vector(21.06, -0.52, 16.03)); // Waypoint #1
      kbPathAddWaypoint(pathID3, vector(48.24, -0.52, 260.79)); // Waypoint #2
      kbPathAddWaypoint(pathID3, vector(136.50, -0.52, 358.91)); // Waypoint #3

      kbPathAddWaypoint(pathID3, targetPoint2);
      kbAttackRouteAddPath(routeID2, pathID3);

      gNavalAttackWave.setGatherPoint(startPoint2);
      gNavalAttackWave.setTargetPoint(targetPoint2);
      gNavalAttackWave.setAttackRouteID(routeID2);
      gNavalAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      gLandDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 50.0, startPoint, 10);
      aiPlanSetVariableFloat(gLandDefendPlan, cDefendPlanEngageRange, 0, 40.0);
      aiPlanAddUnitType(gLandDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

      gNavalDefendPlan = createDefendPlan("Primary Naval Defend", kbBaseGetMainID(cMyID), 150.0, startPoint2, 10);
      aiPlanSetVariableFloat(gNavalDefendPlan, cDefendPlanEngageRange, 0, 40.0);
      aiPlanAddUnitType(gNavalDefendPlan, cUnitTypeLogicalTypeNavalMilitary, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      if (gEnableAttacks == true)
      {
         gNavalAttackWave.setAttackStartTime(1); // 1 second buffer for functionality.
         gEnableAttacks = false; // Flip this back to false so we don't update AttackStartTime again.
      }

      static bool needResearchHeroic = true;

      if (needResearchHeroic == true && xsGetTime() > gHeroicAgeUpTime)
      {
         if (researchSimpleTech(cTechHeroicAgeApollo, cUnitTypeTownCenter, -1, 75) == true)
         {
            debugAttackWave("Starting Heroic Age research plan.");
            needResearchHeroic = false;
         }
      }

      // Don't dispatch Petroboli until 1440 seconds in.
      static bool petroboli = false;
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         if (petroboli == false && xsGetTime() >= 1440)
         {
            petroboli = true;
            gAttackWave.addAttackUnitType(gSixthLandUnit);
            gAttackMaxSize *= 1.10; // Attack size increases by +10%
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }
      }
      if (cDifficultyCurrent <= cDifficultyModerate)
      {
         if (petroboli == false && xsGetTime() >= 2400)
         {
            petroboli = true;
            gAttackWave.addAttackUnitType(gSixthLandUnit);
         }
      }

      int age = kbPlayerGetAge(cMyID);
      // New Tech Rules
      static bool reached_heroic = false; 
      if (age >= cAge3 && reached_heroic == false)
      {
         // All Difficulties:
         xsEnableRule("researchIrrigation");
         xsEnableRule("researchBowSaw");
         xsEnableRule("researchShaftMine");

         // Not Easy:
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchHeavyInfantry");
            xsEnableRule("researchHeavyArchers");
            xsEnableRule("researchBoilingOil");
            xsEnableRule("researchCrenellations");
            xsEnableRule("researchBronzeWeapons");
            xsEnableRule("researchBronzeArmor");
         }

         // Hard and Up:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchHeavyCavalry");
            xsEnableRule("researchHeavyWarships");
            xsEnableRule("researchGuardTower");
            xsEnableRule("researchArchitects");
            xsEnableRule("researchFortifiedTownCenter");
            xsEnableRule("researchBronzeShields");
         }

         // Titan Only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchSunRay");
            xsEnableRule("researchHeroicFleet");
         }
         reached_heroic = true; 
      }

      gAttackWave.update();
      gNavalAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void tna02StrategySetup()
{
   // TODO - The current Archaic strategy just causes the AI to do several things it's not supposed to.
   gStrategyManager.mStartingStrategy = cStrategyScenarioAttackWave;
   // We're not activating the attack strategy until our first army attacks.
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

   gMainGatherBase = createOverrideGatherBase(vector(236.00, 0.00, 105.00), 60);

   setOverrideStrategy(tna02StrategySetup);

   gOverrideFarmCount = 31; // We can't have too many farms due to space restrictions. Note: We already start with 31 farms.
   gRBDSystem.setMaxFarmsPerBase(31);
   gRBDSystem.setMaxFarmsPerIteration(31);
   gTimeToFarm = true;
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, vector(227.0, 0, 99.0), 15.0); // Our TC.
      kbBuildingPlacementAddPositionInfluence(bpID, vector(227.0, 0, 99.0), 100.0, 15.0, cFalloffLinear); // Our TC.
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

void BeginAttacksP3()
{
   gEnableAttacks = true;
   debugAttackWave("*** ATTACKS ARE NOW ENABLED ***");
}

void EnableNavalAttacks()
{
   gEnableAttacks = true;
   debugAttackWave("*** NAVAL ATTACKS ARE NOW ENABLED ***");
}

// * * * // TECH RULES // * * * //

// CLASSICAL AGE UPGRADES
   // *** ALL DIFFICULTIES *** //
      // Copper Shields
         rule researchCopperShields
         inactive
         minInterval 480
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

         // Copper Weapons + Armor
            rule researchCopperWeaponsArmor
            inactive
            minInterval 240
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if ((kbTechGetStatus(cTechCopperWeapons) == cTechStatusActive) &&
                  (kbTechGetStatus(cTechCopperArmor) == cTechStatusActive))
               {
                  xsDisableRule("researchCopperWeaponsArmor");
                  return;
               }
               if (kbTechGetStatus(cTechCopperWeapons) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Copper Weapons research plans.");
                  researchSimpleTech(cTechCopperWeapons, cUnitTypeArmory, -1, 60);
               }
               if (kbTechGetStatus(cTechCopperArmor) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Copper Armor research plans.");
                  researchSimpleTech(cTechCopperArmor, cUnitTypeArmory, -1, 60);
               }
            }

         // Medium Infantry
            rule researchMediumInfantryEasy
            inactive
            minInterval 600
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
                  researchSimpleTech(cTechMediumInfantry, cUnitTypeMilitaryAcademy, -1, 60);
                  return;
               }
            }
            rule researchMediumInfantry
            inactive
            minInterval 300
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
                  researchSimpleTech(cTechMediumInfantry, cUnitTypeMilitaryAcademy, -1, 60);
                  return;
               }
            }


         // Plow
            rule researchPlow
            inactive
            minInterval 30
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechPlow) == cTechStatusActive)
               {
                  xsDisableRule("researchPlow");
                  return;
               }
               else if (kbTechGetStatus(cTechPlow) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Plow research plan.");
                  researchSimpleTech(cTechPlow, cUnitTypeGranary, -1, 60);
                  return;
               }
            }

   // *** MODERATE UPGRADES *** //
      // Medium Archers
         rule researchMediumArchers
         inactive
         minInterval 540
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechMediumArchers) == cTechStatusActive)
            {
               xsDisableRule("researchMediumArchers");
               return;
            }
            else if (kbTechGetStatus(cTechMediumArchers) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Medium Archers research plan.");
               researchSimpleTech(cTechMediumArchers, cUnitTypeArcheryRange, -1, 60);
               return;
            }
         }

      // Medium Cavalry
         rule researchMediumCavalry
         inactive
         minInterval 640
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
               researchSimpleTech(cTechMediumCavalry, cUnitTypeStable, -1, 60);
               return;
            }
         }

   // *** HARD UPGRADES *** //
      // Masons
         rule researchMasons
         inactive
         minInterval 900
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
      // Labyrinth of Minos
         rule researchLabyrinthOfMinos
         inactive
         minInterval 1080
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechLabyrinthOfMinos) == cTechStatusActive)
            {
               xsDisableRule("researchLabyrinthOfMinos");
               return;
            }
            else if (kbTechGetStatus(cTechLabyrinthOfMinos) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Labyrinth of Minos research plan.");
               researchSimpleTech(cTechLabyrinthOfMinos, cUnitTypeTemple, -1, 60);
               return;
            }
         }

   // *** TITAN UPGRADES *** //
      // Sarissa
         rule researchSarissa
         inactive
         minInterval 750
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechSarissa) == cTechStatusActive)
            {
               xsDisableRule("researchSarissa");
               return;
            }
            else if (kbTechGetStatus(cTechSarissa) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Sarissa research plan.");
               researchSimpleTech(cTechSarissa, cUnitTypeMilitaryAcademy, -1, 60);
               return;
            }
         }
      // Aegis Shield
         rule researchAegisShield
         inactive
         minInterval 960
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechAegisShield) == cTechStatusActive)
            {
               xsDisableRule("researchAegisShield");
               return;
            }
            else if (kbTechGetStatus(cTechAegisShield) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Aegis Shield research plan.");
               researchSimpleTech(cTechAegisShield, cUnitTypeMilitaryAcademy, -1, 60);
               return;
            }
         }

// HEROIC AGE UPGRADES
   // *** ALL DIFFICULTIES *** //
      // Irrigation
         rule researchIrrigation
         inactive
         minInterval 30
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechIrrigation) == cTechStatusActive)
            {
               xsDisableRule("researchIrrigation");
               return;
            }
            else if (kbTechGetStatus(cTechIrrigation) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Irrigation research plan.");
               researchSimpleTech(cTechIrrigation, cUnitTypeGranary, -1, 60);
               return;
            }
         }
      // Bow Saw
         rule researchBowSaw
         inactive
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
               researchSimpleTech(cTechBowSaw, cUnitTypeStorehouse, -1, 60);
               return;
            }
         }
      // Shaft Mine
         rule researchShaftMine
         inactive
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
               researchSimpleTech(cTechShaftMine, cUnitTypeStorehouse, -1, 60);
               return;
            }
         }
   // *** MODERATE UPGRADES ***
      // Heavy Infantry
         rule researchHeavyInfantry
         active
         minInterval 300
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
               researchSimpleTech(cTechHeavyInfantry, cUnitTypeMilitaryAcademy, -1, 60);
               return;
            }
         }
      // Heavy Archers
         rule researchHeavyArchers
         active
         minInterval 300
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
      // Bronze Weapons
         rule researchBronzeWeapons
         inactive
         minInterval 480
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
         minInterval 480
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
      // Crenellations
         rule researchCrenellations
         inactive
         minInterval 320
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechCrenellations) == cTechStatusActive)
            {
               xsDisableRule("researchCrenellations");
               return;
            }
            else if (kbTechGetStatus(cTechCrenellations) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Crenellations research plan.");
               researchSimpleTech(cTechCrenellations, cUnitTypeSentryTower, -1, 60);
               return;
            }
         }

   // *** HARD UPGRADES *** //
      // Heavy Warships
         rule researchHeavyWarships
         inactive
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
      // Heavy Cavalry
         rule researchHeavyCavalry
         active
         minInterval 300
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
               researchSimpleTech(cTechHeavyCavalry, cUnitTypeStable, -1, 60);
               return;
            }
         }
      // Bronze Shields
         rule researchBronzeShields
         inactive
         minInterval 640
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
      // Architects
         rule researchArchitects
         inactive
         minInterval 600
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
      // FortifiedTownCenter
         rule researchFortifiedTownCenter
         inactive
         minInterval 300
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
      // Guard Tower
         rule researchGuardTower
         inactive
         minInterval 360
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
   // *** TITAN UPGRADES *** //
      // Sun Ray
         rule researchSunRay
         inactive
         minInterval 720
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
               researchSimpleTech(cTechSunRay, cUnitTypeArmory, -1, 60);
               return;
            }
         }
      // Heroic Fleet
         rule researchHeroicFleet
         inactive
         minInterval 300
         {
            xsSetRuleMinIntervalSelf(10);
            // Cease if we have it. Otherwise, research it.
            if (kbTechGetStatus(cTechHeroicFleet) == cTechStatusActive)
            {
               xsDisableRule("researchHeroicFleet");
               return;
            }
            else if (kbTechGetStatus(cTechHeroicFleet) == cTechStatusObtainable)
            {
               debugAttackWave("Starting Sun Ray research plan.");
               researchSimpleTech(cTechHeroicFleet, cUnitTypeDock, -1, 60);
               return;
            }
         }