//==============================================================================
/* fott32_p5.xs

   Gargarensis (Poseidon)

   Red Greek player owning all the buildings in the WEST beneath the acropolis. Trains Greek infantry and archers,
   as well as the Hero Theseus.

   They stop attacking once they lose one of their Fortresses.
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
float gHeroTrainDelay = 1080; // In seconds.

int gFirstLandUnit = cUnitTypeHypaspist; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 9;
int gSecondLandUnit = cUnitTypeHippeus; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 4;
int gThirdLandUnit = cUnitTypePeltast; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 6;
int gFourthLandUnit = cUnitTypeHydra; // Gets trained from the start.
float gMaintainFourthLandUnitAmount = 1;
int gFifthLandUnit = cUnitTypeColossus; // Gets trained from the start.
float gMaintainFifthLandUnitAmount = 1;
int gSixthLandUnit = cUnitTypeHelepolis; // Gets trained from the start.
float gMaintainSixthLandUnitAmount = 1;
int gSeventhLandUnit = cUnitTypeTheseus; // Gets trained from the start.
float gMaintainSeventhLandUnitAmount = 1;

float gMaxVillagerCount = 3;
float gAttackStartDelay = 210; // In seconds, used after the activation of attacks (by losing a Fortress).
float gAttackWaveInterval = 300; // In Seconds.
float gAttackStartSize = 6;
float gAttackMaxSize = 12;

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;
      int gDefendPlan3 = -1;
      int gDefendPlan4 = -1;



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
       // Certain parameters are way more lenient on Easy.
      if (cDifficultyCurrent == cDifficultyEasy)
      {
         gMaintainFirstLandUnitAmount = 4; // Hypaspists
         gMaintainSecondLandUnitAmount = 2; // Hetairoi
         gMaintainThirdLandUnitAmount = 3; // Peltasts

         gAttackStartDelay = 500;
         gAttackWaveInterval = 600; // In Seconds.
         gAttackStartSize = 3;
         gAttackMaxSize = 5;
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
      gHeroTrainDelay *= gDifficultyModifierTrainDelay;

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);
      data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
      data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
      data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
      data.addUnitToMaintain(gSeventhLandUnit, gMaintainSeventhLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);
      data.setTrainDelay(gFourthLandUnit, gTrainDelay);
      data.setTrainDelay(gFifthLandUnit, gTrainDelay);
      data.setTrainDelay(gSixthLandUnit, gTrainDelay);
      data.setTrainDelay(gSeventhLandUnit, gHeroTrainDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);

      gAttackWave.addAttackUnitType(gFirstLandUnit);  // Hoplites
      gAttackWave.addAttackUnitType(gSecondLandUnit);  // Hypaspists
      gAttackWave.addAttackUnitType(gThirdLandUnit);  // Hippeus
      gAttackWave.addAttackUnitType(gFourthLandUnit); // Toxotes
      gAttackWave.addAttackUnitType(gFifthLandUnit); // Peltasts
      gAttackWave.addAttackUnitType(gSeventhLandUnit); // Cyclopses

      // TECH PROGRESSION RULES

      // Moderate Only
      if (cDifficultyCurrent == cDifficultyModerate)
      {
         xsEnableRule("researchHandOfTalosMod");
         xsEnableRule("researchChampionInfantryMOD");
         xsEnableRule("researchChampionArchersMOD");
         xsEnableRule("researchChampionCavalryMOD");
      }
      // Moderate and Hard
      if (cDifficultyCurrent >= cDifficultyModerate && cDifficultyCurrent != cDifficultyTitan)
      {
         xsEnableRule("researchIronWeaponsMH");
         xsEnableRule("researchIronArmorMH");
         xsEnableRule("researchIronShieldsMH");
      }

      // Hard and Titan
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         xsEnableRule("researchHandOfTalos");
         xsEnableRule("researchShoulderOfTalos");
         xsEnableRule("researchChampionInfantryHT");
         xsEnableRule("researchChampionArchersHT");
         xsEnableRule("researchChampionCavalryHT");
         xsEnableRule("researchBurningPitch");
      }

      // Titan only
      if (cDifficultyCurrent == cDifficultyTitan)
      {
         xsEnableRule("researchOlympianWeapons");
         xsEnableRule("researchIronWeaponsTITAN");
         xsEnableRule("researchIronArmorTITAN");
         xsEnableRule("researchIronShieldsTITAN");
      }

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);
      data.setFlag(cStrategyFlagAutomaticMainBaseTCRebuild, true);
      data.setFlag(cStrategyFlagAutoResearchMilitaryUpgrades, true);

      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start and end.
      vector startPoint = vector(133.0, 1.0, 337.0); // The start point block in the west, below the acropolis (first waypoint in Norse attack route).
      vector targetPoint = vector(46.0, 1.0, 232.0); // Player's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 Norse");
      kbPathAddWaypoint(pathID1, startPoint);
      // kbPathAddWaypoint(pathID1, vector(119.0, 1.0, 333.0));
      kbPathAddWaypoint(pathID1, vector(78.0, 1.0, 364.0));
      kbPathAddWaypoint(pathID1, vector(45.0, 1.0, 340.0));
      kbPathAddWaypoint(pathID1, vector(89.0, 1.0, 259.0));
      kbPathAddWaypoint(pathID1, vector(48.0, 1.0, 242.0));
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path 2 Egyptians");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(135.0, 1.0, 149.0));
      kbPathAddWaypoint(pathID2, vector(107.0, 1.0, 168.0));
      kbPathAddWaypoint(pathID2, vector(36.0, 1.0, 167.0));
      kbPathAddWaypoint(pathID2, vector(33.0, 1.0, 219.0));
      kbPathAddWaypoint(pathID2, vector(27.0, 1.0, 27.0));
      kbPathAddWaypoint(pathID2, targetPoint);
      kbAttackRouteAddPath(routeID, pathID2);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
         }
      );

      // DEFEND PLANS
      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 2; // Hypaspists
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 2; // Hippeis
      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2; // Peltasts
      int fifthLandUnitSplitAmount = gMaintainFifthLandUnitAmount / 2; // Colossi
      int sixthLandUnitSplitAmount = gMaintainSixthLandUnitAmount / 2; // Helepoli

      vector Defend_1 = vector(89.0, 0.0, 365.0); // In the west.
      vector Defend_2 = vector(145.0, 0.0, 311.0); // Below their Town Center.
      vector Defend_3 = vector(191.0, 0.0, 257.0); // Near their right Plenty Vault.

      gDefendPlan1 = createDefendPlan("Defend Plan 1", kbBaseGetMainID(cMyID), 20.0, Defend_1, 10, Defend_1);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 25.0);
      aiPlanAddUnitType(gDefendPlan1, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Hippeis
      aiPlanAddUnitType(gDefendPlan1, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Peltasts
      aiPlanAddUnitType(gDefendPlan1, gFifthLandUnit, 0, 0, fifthLandUnitSplitAmount); // Colossi
      aiPlanAddUnitType(gDefendPlan1, gSixthLandUnit, 0, 0, sixthLandUnitSplitAmount); // Helepoli

      gDefendPlan2 = createDefendPlan("Defend Plan 2", kbBaseGetMainID(cMyID), 20.0, Defend_2, 10, Defend_2);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 25.0);
      aiPlanAddUnitType(gDefendPlan2, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Hypaspists      
      aiPlanAddUnitType(gDefendPlan2, gSecondLandUnit, 0, 0, secondLandUnitSplitAmount); // Hippeis
      aiPlanAddUnitType(gDefendPlan2, gFourthLandUnit, 0, 0, 200); // Hydrai
      aiPlanAddUnitType(gDefendPlan2, gSixthLandUnit, 0, 0, sixthLandUnitSplitAmount); // Helepoli

      gDefendPlan3 = createDefendPlan("Defend Plan 3", kbBaseGetMainID(cMyID), 20.0, Defend_3, 10, Defend_3);
      aiPlanSetVariableFloat(gDefendPlan3, cDefendPlanEngageRange, 0, 25.0);
      aiPlanAddUnitType(gDefendPlan3, gFirstLandUnit, 0, 0, firstLandUnitSplitAmount); // Hypaspists
      aiPlanAddUnitType(gDefendPlan3, gThirdLandUnit, 0, 0, thirdLandUnitSplitAmount); // Peltasts
      aiPlanAddUnitType(gDefendPlan3, gFifthLandUnit, 0, 0, fifthLandUnitSplitAmount); // Colossi
      aiPlanAddUnitType(gDefendPlan3, gSeventhLandUnit, 0, 0, 200); // Theseus

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool done = false;

      // Get our starting amount of Fortresses.
      static int fortCountAtStart = 0;
      if (fortCountAtStart == 0)
      {
         fortCountAtStart = kbUnitCount(cUnitTypeFortress, cMyID, cUnitStateAlive);
      }

      if (done == false)
      {
         // Check if we have lost a Fortress.
         int fortCountNow = kbUnitCount(cUnitTypeFortress, cMyID, cUnitStateAlive);
         //debugAttackWave("FORTRESSES: " + fortCountNow + "/" + fortCountAtStart);

         // If we have...
         if (fortCountNow < fortCountAtStart)
         {
            done = true;
            debugAttackWave("WE LOST A FORTRESS?? Okay, I give up! No more attacks...");

            // Stop attacks by setting the attack sizes to 0.
            gAttackWave.setAttackSize(0);
            gAttackWave.setMaxAttackSize(0);
         }
      }

         // Attack buffs

         // Don't dispatch Helepoli until 600 seconds in.
         static bool helepoli = false;
         if (helepoli == false && xsGetTime() >= 600)
         {
            helepoli = true;
            gAttackWave.addAttackUnitType(gSixthLandUnit);
            gAttackMaxSize *= 1.05; // Attack size increases by +05%
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }

         static bool army_buffed = false;
         if (army_buffed == false && xsGetTime() >= 1500)
         {
            // Smaller increase on Moderate.
            if (cDifficultyCurrent == cDifficultyModerate)
            {
               gMaintainSecondLandUnitAmount *= 1.25; // Train +25% Hippeis.
               gMaintainThirdLandUnitAmount *= 1.5; // Train +50% Peltasts.
               gMaintainFourthLandUnitAmount *= 1.5; // Train +50% Hydrai.

               data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
               data.adjustUnitToMaintainAmount(gThirdLandUnit, gMaintainThirdLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFourthLandUnit, gMaintainFourthLandUnitAmount);
                              
               // Update attack size parameters based on the enlarged army composition.
               gAttackMaxSize *= 1.10; // Attack size increases by +10%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);

               // Train more Villagers to support the larger army.
               gMaxVillagerCount *= 2.0; // Train +100% more Villagers.
               gOverrideMaxVillagerPop = gMaxVillagerCount;
            }
            // Larger increase on Hard.
            if (cDifficultyCurrent == cDifficultyHard)
            {
               gMaintainFirstLandUnitAmount *= 1.25; // Train +25% Hypaspists.
               gMaintainSecondLandUnitAmount *= 1.5; // Train +50% Hippeis.
               gMaintainThirdLandUnitAmount *= 1.75; // Train +75% Peltasts.
               gMaintainFourthLandUnitAmount *= 2.0; // Train +100% Hydrai.
               gMaintainFifthLandUnitAmount *= 2.0; // Train +100% Helepoli.

               data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
               data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
               data.adjustUnitToMaintainAmount(gThirdLandUnit, gMaintainThirdLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFourthLandUnit, gMaintainFourthLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFifthLandUnit, gMaintainFifthLandUnitAmount);
                              
               // Update attack size parameters based on the enlarged army composition.
               gAttackMaxSize *= 1.25; // Attack size increases by +25%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);

               // Train more Villagers to support the larger army.
               gMaxVillagerCount *= 2.5; // Train +150% more Villagers.
               gOverrideMaxVillagerPop = gMaxVillagerCount;
            }

            // Larger increase on Titan.
            if (cDifficultyCurrent == cDifficultyTitan)
            {
               gMaintainFirstLandUnitAmount *= 1.5; // Train +50% Hypaspists.
               gMaintainSecondLandUnitAmount *= 2.0; // Train +100% Hippeis.
               gMaintainThirdLandUnitAmount *= 2.0; // Train +100% Peltasts.
               gMaintainFourthLandUnitAmount *= 2.5; // Train +150% Hydrai.
               gMaintainFifthLandUnitAmount *= 2.0; // Train +100% Helepoli.

               data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
               data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
               data.adjustUnitToMaintainAmount(gThirdLandUnit, gMaintainThirdLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFourthLandUnit, gMaintainFourthLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFifthLandUnit, gMaintainFifthLandUnitAmount);
                              
               gAttackWave.addAttackUnitType(gFirstLandUnit);
               gAttackWave.addAttackUnitType(gSecondLandUnit);
               gAttackWave.addAttackUnitType(gThirdLandUnit);
               gAttackWave.addAttackUnitType(gFourthLandUnit);
               gAttackWave.addAttackUnitType(gFifthLandUnit);
               gAttackWave.addAttackUnitType(gSixthLandUnit);
               gAttackWave.addAttackUnitType(gSeventhLandUnit);

               // Update attack size parameters based on the enlarged army composition.
               gAttackMaxSize *= 1.40; // Attack size increases by +40%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);

               // Train more Villagers to support the larger army.
               gMaxVillagerCount *= 3.0; // Train +200% more Villagers.
               gOverrideMaxVillagerPop = gMaxVillagerCount;
            }

            army_buffed = true;
         }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}

// Set up the strategy.
void fott32StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(164.00, 0.00, 329.00), 45);
   createOverrideGatherBase(vector(103.00, 0.00, 387.00), 25);

   setOverrideStrategy(fott32StrategySetup);

   gOverrideFarmCount = 25; // We can't have too many farms due to space restrictions.
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, vector(161.0, 3.53, 317.0), 15.0); // Our TC.
      kbBuildingPlacementAddPositionInfluence(bpID, vector(161.0, 3.53, 317.0), 100.0, 15.0, cFalloffLinear); // Our TC.
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

// TECHS
   // MYTHIC
         // Hand Of Talos (15 minutes in on Moderate)
            rule researchHandOfTalosMod
            inactive
            minInterval 900
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechHandOfTalos) == cTechStatusActive)
               {
                  xsDisableRule("researchHandOfTalosMod");
                  return;
               }
               else if (kbTechGetStatus(cTechHandOfTalos) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Hand of Talos research plan.");
                  researchSimpleTech(cTechHandOfTalos, cUnitTypeTemple, -1, 60);
                  return;
               }
            }
         // Hand Of Talos (6 minutes in)
            rule researchHandOfTalos
            inactive
            minInterval 360
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechHandOfTalos) == cTechStatusActive)
               {
                  xsDisableRule("researchHandOfTalos");
                  return;
               }
               else if (kbTechGetStatus(cTechHandOfTalos) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Hand of Talos research plan.");
                  researchSimpleTech(cTechHandOfTalos, cUnitTypeTemple, -1, 60);
                  return;
               }
            }
         // Shoulder of Talos (16 minutes in)
            rule researchShoulderOfTalos
            inactive
            minInterval 960
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechShoulderOfTalos) == cTechStatusActive)
               {
                  xsDisableRule("researchShoulderOfTalos");
                  return;
               }
               else if (kbTechGetStatus(cTechShoulderOfTalos) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Shoulder of Talos research plan.");
                  researchSimpleTech(cTechShoulderOfTalos, cUnitTypeTemple, -1, 60);
                  return;
               }
            }

// *** HUMAN UNIT UPGRADES ***
   // MYTHIC AGE
      // FASTER TIMES
         // Champion Infantry (Hard and Titan)
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
         // Champion Archers (Hard and Titan)
            rule researchChampionArchersHT
            inactive
            minInterval 700
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
         // Champion Cavalry (Hard and Titan)
            rule researchChampionCavalryHT
            inactive
            minInterval 800
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
         // Iron Weapons (Titan)
            rule researchIronWeaponsTITAN
            inactive
            minInterval 380
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechIronWeapons) == cTechStatusActive)
               {
                  xsDisableRule("researchIronWeaponsTITAN");
                  return;
               }
               else if (kbTechGetStatus(cTechIronWeapons) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Iron Weapons research plan.");
                  researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 60);
                  return;
               }
            }
         // Iron Armor (Titan)
            rule researchIronArmorTITAN
            inactive
            minInterval 510
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechIronArmor) == cTechStatusActive)
               {
                  xsDisableRule("researchIronArmorTITAN");
                  return;
               }
               else if (kbTechGetStatus(cTechIronArmor) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Iron Armor research plan.");
                  researchSimpleTech(cTechIronArmor, cUnitTypeArmory, -1, 60);
                  return;
               }
            }
         // Iron Shields (Titan)
            rule researchIronShieldsTITAN
            inactive
            minInterval 640
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechIronShields) == cTechStatusActive)
               {
                  xsDisableRule("researchIronShieldsTITAN");
                  return;
               }
               else if (kbTechGetStatus(cTechIronShields) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Iron Shields research plan.");
                  researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
                  return;
               }
            }
      // SLOWER TIMES
         // Champion Infantry (Moderate)
            rule researchChampionInfantryMOD
            inactive
            minInterval 1000
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionInfantryMOD");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Infantry research plan.");
                  researchSimpleTech(cTechChampionInfantry, cUnitTypeMilitaryAcademy, -1, 60);
                  return;
               }
            }
         // Champion Archers (Moderate)
            rule researchChampionArchersMOD
            inactive
            minInterval 1100
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionArchers) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionArchersMOD");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionArchers) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Archers research plan.");
                  researchSimpleTech(cTechChampionArchers, cUnitTypeArcheryRange, -1, 60);
                  return;
               }
            }
         // Champion Cavalry (MOD)
            rule researchChampionCavalryMOD
            inactive
            minInterval 1200
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechChampionCavalry) == cTechStatusActive)
               {
                  xsDisableRule("researchChampionCavalryMOD");
                  return;
               }
               else if (kbTechGetStatus(cTechChampionCavalry) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Champion Cavalry research plan.");
                  researchSimpleTech(cTechChampionCavalry, cUnitTypeStable, -1, 60);
                  return;
               }
            }
         // Iron Weapons (MOD HARD)
            rule researchIronWeaponsMH
            inactive
            minInterval 840
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechIronWeapons) == cTechStatusActive)
               {
                  xsDisableRule("researchIronWeaponsMH");
                  return;
               }
               else if (kbTechGetStatus(cTechIronWeapons) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Iron Weapons research plan.");
                  researchSimpleTech(cTechIronWeapons, cUnitTypeArmory, -1, 60);
                  return;
               }
            }
         // Iron Armor (MOD HARD)
            rule researchIronArmorMH
            inactive
            minInterval 960
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechIronArmor) == cTechStatusActive)
               {
                  xsDisableRule("researchIronArmorMH");
                  return;
               }
               else if (kbTechGetStatus(cTechIronArmor) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Iron Armor research plan.");
                  researchSimpleTech(cTechIronArmor, cUnitTypeArmory, -1, 60);
                  return;
               }
            }
         // Iron Shields (MOD HARD)
            rule researchIronShieldsMH
            inactive
            minInterval 1140
            {
               xsSetRuleMinIntervalSelf(10);
               // Cease if we have it. Otherwise, research it.
               if (kbTechGetStatus(cTechIronShields) == cTechStatusActive)
               {
                  xsDisableRule("researchIronShieldsMH");
                  return;
               }
               else if (kbTechGetStatus(cTechIronShields) == cTechStatusObtainable)
               {
                  debugAttackWave("Starting Iron Shields research plan.");
                  researchSimpleTech(cTechIronShields, cUnitTypeArmory, -1, 60);
                  return;
               }
            }

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
      // TITAN ONLY:
         // Olympian Weapons
            rule researchOlympianWeapons
            inactive
            minInterval 1200
            {
               debugAttackWave("Starting Olympian Weapons research plan.");
               researchSimpleTech(cTechOlympianWeapons, cUnitTypeArmory, -1, 60);
               xsDisableRule("researchOlympianWeapons");
            }