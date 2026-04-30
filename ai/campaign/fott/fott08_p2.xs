//==============================================================================
/* fott08_p2.xs
   
   Red Greek player owning the base in the west (Gargarensis). Trains Hoplites,
   Toxotes, Cyclopes, and Hydrai to attack Ajax's base.

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
float gMythTrainDelay = 60; // In seconds.

int gFirstLandUnit = cUnitTypeHoplite; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 7;
int gSecondLandUnit = cUnitTypeToxotes; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 7;
int gThirdLandUnit = cUnitTypeCyclops; // Begins training at 600 seconds
float gMaintainThirdLandUnitAmount = 2;
int gFourthLandUnit = cUnitTypeHydra; // Begins training at 600 seconds
float gMaintainFourthLandUnitAmount = 2;
int gFifthLandUnit = cUnitTypePetrobolos; // Gets trained from the start, but not on Easy.
float gMaintainFifthLandUnitAmount = 2;
int gSixthLandUnit = cUnitTypeAtalanta; // Begins training at 540 seconds; wait 420 to retrain after death.
float gMaintainSixthLandUnitAmount = 1;

float gMaxVillagerCount = 15;
float gAttackStartDelay = 240; // In seconds.
float gAttackWaveInterval = 720; // In seconds.
float gAttackStartSize = 8;
float gAttackMaxSize = 12;

float gInitialAttackStartSize = 8; // Used to calculate new values from increments before applying the multiplier.
float gInitialAttackMaxSize = 12; // Used to calculate new values from increments before applying the multiplier.

float gMythicAgeUpTime = 900; // In seconds.

// Defend Points (Divided to ensure a more natural distribution of guards)
      int gDefendPlan1 = -1;
      int gDefendPlan2 = -1;
      int gDefendPlan3 = -1;

Strategy scenarioAttackWaveStrategy()
{
   xsEnableRule("maintainAtalanta");

   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugStrategy("***Starting Scenario Attack Wave Strategy***");

      // Tech progression rules.

      // All difficulties.
      xsEnableRule("researchBronzeShields");

      // Not Easy.
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         xsEnableRule("researchBronzeArmor");
         xsEnableRule("researchBronzeWeapons");
         xsEnableRule("researchHeavyInfantry");
         xsEnableRule("useMeteor");
      }
      // Hard and Titan
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         xsEnableRule("researchChthonicRites");
      }

      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================
      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;

      // Cyclopes, Hydrai, and Atalanta not affected by multiplier.

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;
      gTrainDelay *= gDifficultyModifierTrainDelay;
      gMythicAgeUpTime *= gDifficultyModifierAgeUp;

      // Attack wave interval is not affected by the multiplier on Easy or Moderate.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      }

      // Make certain parameters way more lenient on Easy.
      if(cDifficultyCurrent == cDifficultyEasy)
      {
         gAttackStartDelay = 600; // Don't launch the first attack until well into the mission; it's tricky managing 2 bases.
         gAttackWaveInterval = 900; // Barely attack at all after the first strike.

         gAttackStartSize = 3; // Very feeble attacks on Easy.
         gAttackMaxSize = 6; // Never let this be too high.

         gMaintainFirstLandUnitAmount = 5; // More like legacy.
         gMaintainSecondLandUnitAmount = 5; // More like legacy.
      }

      // No train delay on Hard and Titan.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gTrainDelay = 0;
         gMythTrainDelay = 0;
      }
      // First attack occurs even sooner on Titan.
      if (cDifficultyCurrent == cDifficultyTitan)
      {
         gAttackStartDelay -= 90;
      }

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount); // Hoplites
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount); // Toxotes

      // Cyclopes and Hydra are not produced until later.

      // Petroboli are not produced until later.
      
      // Atalanta is not produced until later.

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gFirstLandUnit); // Hoplites
      gAttackWave.addAttackUnitType(gSecondLandUnit); // Toxotes

      // Cyclopes and Hydrai only join attack waves on Hard and Titan, and only 10 minutes into the mission.
      // Atalanta only joins attack waves 9 minutes into the mission.

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      data.setFlag(cStrategyFlagAutomaticTCRepair, true);

      gAttackWave.setPlayerToAttack(1); // Attack P1-Ajax!

      // Where does our attack start and end.
      vector startPoint = vector(143.0, 0.0, 207.0); // Above P5 Fortress in west.
      vector targetPoint = vector(35.0, 0.0, 181.0); // Ajax's TC.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
      int pathID1 = kbPathCreate("Path 1 to Town Center");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(115.0, 0.0, 205.0)); // Block #1
      kbPathAddWaypoint(pathID1, vector(100.0, 0.0, 181.0)); // Block #2
      kbPathAddWaypoint(pathID1, vector(110.0, 0.0, 158.0)); // Block #3
      kbPathAddWaypoint(pathID1, vector(89.0, 0.0, 135.0)); // Block #4
      kbPathAddWaypoint(pathID1, targetPoint);
      kbAttackRouteAddPath(routeID, pathID1);
      
      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(targetPoint);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback([](int planID = -1)
      {
      });


   // SPLIT AMOUNTS
      int firstLandUnitSplitAmount = gMaintainFirstLandUnitAmount / 3; // Hoplites
      int secondLandUnitSplitAmount = gMaintainSecondLandUnitAmount / 3; // Toxotai
      int thirdLandUnitSplitAmount = gMaintainThirdLandUnitAmount / 2; // Cyclopes
      int fourthLandUnitSplitAmount = gMaintainFourthLandUnitAmount / 2; // Hydrai


   // DEFINE THE PLANS
      // Plan 1 (First production buildings, later moved up)
      gDefendPlan1 = createDefendPlan("Defense Plan 1", kbBaseGetMainID(cMyID), 10, vector(105.0, 0.0, 179.0), 30);
      aiPlanSetVariableFloat(gDefendPlan1, cDefendPlanEngageRange, 0, 25);
      aiPlanAddUnitType(gDefendPlan1, gFirstLandUnit, 0, firstLandUnitSplitAmount, 200); // Hoplites
      aiPlanAddUnitType(gDefendPlan1, gSecondLandUnit, 0, secondLandUnitSplitAmount, 200); // Toxotai
      aiPlanAddUnitType(gDefendPlan1, gThirdLandUnit, 0, thirdLandUnitSplitAmount, 200); // Cyclopes

      // Plan 2 (In front of their economy)
      gDefendPlan2 = createDefendPlan("Defense Plan 2", kbBaseGetMainID(cMyID), 10, vector(193.0, 0.0, 239.0), 30);
      aiPlanSetVariableFloat(gDefendPlan2, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan2, gFirstLandUnit, 0, firstLandUnitSplitAmount, 200); // Hoplites
      aiPlanAddUnitType(gDefendPlan2, gSecondLandUnit, 0, secondLandUnitSplitAmount, 200); // Toxotai      
      aiPlanAddUnitType(gDefendPlan2, gThirdLandUnit, 0, thirdLandUnitSplitAmount, 200); // Cyclopes
      aiPlanAddUnitType(gDefendPlan2, gFourthLandUnit, 0, fourthLandUnitSplitAmount, 200); // Hydrai
      aiPlanAddUnitType(gDefendPlan2, gFifthLandUnit, 0, 0, 200); // Petroboli

      // Plan 3 (Near their main Fortress)
      gDefendPlan3 = createDefendPlan("Defense Plan 3", kbBaseGetMainID(cMyID), 10, vector(261.0, 0.0, 271.0), 30);
      aiPlanSetVariableFloat(gDefendPlan3, cDefendPlanEngageRange, 0, 30);
      aiPlanAddUnitType(gDefendPlan3, gFirstLandUnit, 0, firstLandUnitSplitAmount, 200); // Hoplites
      aiPlanAddUnitType(gDefendPlan3, gSecondLandUnit, 0, secondLandUnitSplitAmount, 200); // Toxotai
      aiPlanAddUnitType(gDefendPlan3, gFourthLandUnit, 0, fourthLandUnitSplitAmount, 200); // Hydrai
      aiPlanAddUnitType(gDefendPlan3, cUnitTypeAtalanta, 0, 0, 200); // Atalanta

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      int age = kbPlayerGetAge(cMyID);
      int time = xsGetTime();

      // Update Bools
      static bool Reached_Mythic = false;
      static bool Added_Cyclopes = false;
      static bool Added_Hydrai = false;
      static bool Added_Petroboli = false;
      static bool Added_Atalanta = false;
      static bool army_buffed = false;

      static bool reachedMythic = false;
      static bool needResearchMythic = true;

      if (needResearchMythic == true && xsGetTime() > gMythicAgeUpTime)
      {
         if (researchSimpleTech(cTechMythicAgeArtemis, cUnitTypeTownCenter, -1, 75) == true)
         {
            debugAttackWave("Starting Mythic Age research plan.");
            needResearchMythic = false;
         }
      }

      // Cyclopes
      if (time >= 600 && Added_Cyclopes == false)
         {
            data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount); // Start training Cyclopes.
            data.setTrainDelay(gThirdLandUnit, gMythTrainDelay);
            gAttackWave.addAttackUnitType(gThirdLandUnit); // Start dispatching Cyclopes.
            Added_Cyclopes = true;
         }

      // Atalanta
      if (time >= 540 && Added_Atalanta == false)
      {
         data.addUnitToMaintain(gSixthLandUnit, gMaintainSixthLandUnitAmount);
         data.setTrainDelay(gSixthLandUnit, gTrainDelay);
         gAttackWave.addAttackUnitType(gSixthLandUnit); // Start dispatching Atalanta.
         xsEnableRule("maintainAtalanta");
         Added_Atalanta = true;
      }

      // Non-Easy Updates   
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         // Hydrai (Not on Easy)
         if (time >= 600 && cDifficultyCurrent >= cDifficultyModerate)
         {
            if (Added_Hydrai == false)
            {
               data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount); // Start training Hydrai.
               data.setTrainDelay(gFourthLandUnit, gMythTrainDelay);
               gAttackWave.addAttackUnitType(gFourthLandUnit); // Start dispatching Hydrai.
               gAttackMaxSize *= 1.05; // Attack size increases by +5%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);
               Added_Hydrai = true;        
            }
         }
         // Petroboli (Not on Easy)
         if (time >= 720 && cDifficultyCurrent >= cDifficultyModerate)
         {
            if (Added_Petroboli == false)
            {
               data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
               data.setTrainDelay(gFifthLandUnit, gTrainDelay);
               gAttackWave.addAttackUnitType(gFifthLandUnit); // Start dispatching Petroboli.
               // Update attack size parameters based on the enlarged army composition.
               gAttackMaxSize *= 1.05; // Attack size increases by +5%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);
               Added_Petroboli = true;
            }
         }
         
         // Attack buffs
         if (army_buffed == false && time >= 1500)
         {
            // Smaller increase on Moderate.
            if (cDifficultyCurrent == cDifficultyModerate)
            {
               gMaintainFirstLandUnitAmount *= 1.15; // Train +15% Hoplites.
               gMaintainSecondLandUnitAmount *= 1.15; // Train +15% Toxotai.

               data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
               data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);

               // Update attack size parameters based on the enlarged army composition.
               gAttackMaxSize *= 1.10; // Attack size increases by +10%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);

               // Train more Villagers to support the larger army.
               gMaxVillagerCount *= 1.15; // Train +15% more Villagers.
               gOverrideMaxVillagerPop = gMaxVillagerCount;
            }
            // Larger increase on Hard.
            if (cDifficultyCurrent == cDifficultyHard)
            {
               gMaintainFirstLandUnitAmount *= 1.20; // Train +20% Hoplites.
               gMaintainSecondLandUnitAmount *= 1.20; // Train +20% Toxotai.
               gMaintainFifthLandUnitAmount *= 1.20; // Train +20% Petroboli.

               data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
               data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
               data.adjustUnitToMaintainAmount(gThirdLandUnit, gMaintainThirdLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFourthLandUnit, gMaintainFourthLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFifthLandUnit, gMaintainFifthLandUnitAmount);
               data.adjustUnitToMaintainAmount(gSixthLandUnit, gMaintainSixthLandUnitAmount);

               // Update attack size parameters based on the enlarged army composition.
               gAttackMaxSize *= 1.15; // Attack size increases by +15%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);

               // Train more Villagers to support the larger army.
               gMaxVillagerCount *= 1.25; // Train +25% more Villagers.
               gOverrideMaxVillagerPop = gMaxVillagerCount;
            }

            // Larger increase on Titan.
            if (cDifficultyCurrent == cDifficultyTitan)
            {
               gMaintainFirstLandUnitAmount *= 1.30; // Train +30% Hoplites.
               gMaintainSecondLandUnitAmount *= 1.30; // Train +30% Toxotai.
               gMaintainThirdLandUnitAmount *= 2.00; // Train +100% Cyclopes.
               gMaintainFourthLandUnitAmount *= 2.00; // Train +100% Hydrai.
               gMaintainFifthLandUnitAmount *= 1.50; // Train +50% Petroboli.

               data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
               data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
               data.adjustUnitToMaintainAmount(gThirdLandUnit, gMaintainThirdLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFourthLandUnit, gMaintainFourthLandUnitAmount);
               data.adjustUnitToMaintainAmount(gFifthLandUnit, gMaintainFifthLandUnitAmount);

               // Update attack size parameters based on the enlarged army composition.
               gAttackMaxSize *= 1.25; // Attack size increases by +25%
               gAttackWave.setMaxAttackSize(gAttackMaxSize);

               // Train more Villagers to support the larger army.
               gMaxVillagerCount *= 1.40; // Train +40% more Villagers.
               gOverrideMaxVillagerPop = gMaxVillagerCount;
            }
            // Accelerate attacks from this point on - Arkantos should be built up now.
            if (cDifficultyCurrent >= cDifficultyHard)
            {
               gAttackWaveInterval = 480;
               gAttackWaveInterval *= gDifficultyModifierAttackInterval;
            }

            army_buffed = true;
         }
      }

      // Train more 

      // MYTHIC AGE //
      if (age >= cAge4 && Reached_Mythic == false)
      {
         // Tech Rules for Hard and Titan only:
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchIronWeapons");
            xsEnableRule("researchEngineers");
            xsEnableRule("researchQuarry");
         }
         // Tech Rules for Hard only:
         if (cDifficultyCurrent == cDifficultyHard)
         {
            xsEnableRule("researchChampionInfantryHard");
            xsEnableRule("researchChampionArchersHard");
         }
         // Tech Rules for Titan only:
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchChampionInfantryTitan");
            xsEnableRule("researchChampionArchersTitan");
            xsEnableRule("researchIronArmor");
            xsEnableRule("researchIronShields");
            xsEnableRule("researchConscriptRangedSoldiers");
            xsEnableRule("researchConscriptInfantry");
         }
         
         Reached_Mythic = true;
      }

      gAttackWave.update();
      return true; // Always return true, if we return false this strategy ends and we don't want that!
   };

   // Done.
   return strategy;
}


// Set up the strategy.
void fott08StrategySetup()
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

   gMainGatherBase = createOverrideGatherBase(vector(211.00, 0.00, 251.00), 80);

   setOverrideStrategy(fott08StrategySetup);

   gOverrideFarmCount = 20; // Don't overdo the Farms.
   gRBDSystem.setMaxFarmsPerBase(20);
   gRBDSystem.setMaxFarmsPerIteration(20);
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

rule maintainAtalanta
inactive
minInterval 10
{
   static bool trainAtalanta = false;
   int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, gSixthLandUnit);
   if (trainAtalanta == true)
   {
      // Bump the maintain amount to 1 again and reset our own interval to keep checking for her death often.
      aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, 1);
      xsSetRuleMinIntervalSelf(10);
      trainAtalanta = false;
      return;
   }
   if (kbUnitCount(cUnitTypeAtalanta, cMyID, cUnitStateAlive) >= 1)
   {
      // If we have an Atalanta alive, null out the maintain plan.
      aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, 0);
   }
   else
   {
      if (aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0) == 1)
      {
         // We currently don't have an Atalanta but we're trying to train her.
         return;
      }
      // Our Atalanta is dead so now we must retrain her in 7 minutes.
      trainAtalanta = true;
      xsSetRuleMinIntervalSelf(420);
   }
}

// Use Meteor when asked to.
rule useMeteor
inactive
minInterval 5
{
   int numEnemies =
   getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, 1, cUnitStateAlive, vector(242.0, 0.0, 249.0), 44.0);
   debugAttackWave("numEnemies for casting Meteor: " + numEnemies);
   if (numEnemies >= 5)
   {
      if (aiCastGodPowerAtPosition(cProtoPowerMeteor, vector(242.0, 0.0, 249.0)) == true)
      {
         debugAttackWave("Casted Meteor!");
         xsDisableRule("useMeteor");
      }
   }
}

// * * * * * * * * * * * //
//  ARMORY TECHNOLOGIES  //
// * * * * * * * * * * * //

// Research Bronze Shields at 500 seconds; Easy and Moderate only.
rule researchBronzeShields
inactive
minInterval 500
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

// Research Bronze Weapons at 400 seconds; Moderate only.
rule researchBronzeWeapons
inactive
minInterval 400
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

// Research Bronze Armor at 620 seconds; Moderate only.
rule researchBronzeArmor
inactive
minInterval 620
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

// Research Iron Weapons at 650 seconds; Hard and Titan only.
rule researchIronWeapons
inactive
minInterval 650
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

// Research Iron Armor at 500 seconds; Titan only.
rule researchIronArmor
inactive
minInterval 500
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

// Research Iron Shields at 1000 seconds; Titan only.
rule researchIronShields
inactive
minInterval 1000
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

// * * * * * * * * * * * * * * //
// ARCHERY RANGE TECHNOLOGIES  //
// * * * * * * * * * * * * * * //

// Research Heavy Archers at 560 seconds; Moderate only.
rule researchHeavyArchers
inactive
minInterval 560
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

// Research Champion Archers at 480 seconds; Titan only.
rule researchChampionArchersTitan
inactive
minInterval 480
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechChampionArchers) == cTechStatusActive)
   {
      xsDisableRule("researchChampionArchersTitan");
      return;
   }
   else if (kbTechGetStatus(cTechChampionArchers) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Champion Archers research plan.");
      researchSimpleTech(cTechChampionArchers, cUnitTypeArcheryRange, -1, 60);
      return;
   }
}
// Research Champion Archers at 960 seconds; Hard only.
rule researchChampionArchersHard
inactive
minInterval 480
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechChampionArchers) == cTechStatusActive)
   {
      xsDisableRule("researchChampionArchersHard");
      return;
   }
   else if (kbTechGetStatus(cTechChampionArchers) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Champion Archers research plan.");
      researchSimpleTech(cTechChampionArchers, cUnitTypeArcheryRange, -1, 60);
      return;
   }
}

// Research Conscript Ranged Soldiers at 900 seconds; Titan only.
rule researchConscriptRangedSoldiers
inactive
minInterval 900
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechConscriptRangedSoldiers) == cTechStatusActive)
   {
      xsDisableRule("researchConscriptRangedSoldiers");
      return;
   }
   else if (kbTechGetStatus(cTechConscriptRangedSoldiers) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Conscript Ranged Soldiers research plan.");
      researchSimpleTech(cTechConscriptRangedSoldiers, cUnitTypeArcheryRange, -1, 60);
      return;
   }
}

// * * * * * * * * * * * * * * * * //
//  MILITARY ACADEMY TECHNOLOGIES  //
// * * * * * * * * * * * * * * * * //

// Research Heavy Infantry at 750 seconds; Moderate only.
rule researchHeavyInfantry
inactive
minInterval 750
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

// Research Champion Infantry at 1440/720 seconds; Hard and Titan only.
rule researchChampionInfantryTitan
inactive
minInterval 720
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusActive)
   {
      xsDisableRule("researchChampionInfantryTitan");
      return;
   }
   else if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Champion Infantry research plan.");
      researchSimpleTech(cTechChampionInfantry, cUnitTypeMilitaryAcademy, -1, 60);
      return;
   }
}

// Research Champion Infantry at 1440 seconds; Hard only.
rule researchChampionInfantryHard
inactive
minInterval 1440
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusActive)
   {
      xsDisableRule("researchChampionInfantryHard");
      return;
   }
   else if (kbTechGetStatus(cTechChampionInfantry) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Champion Infantry research plan.");
      researchSimpleTech(cTechChampionInfantry, cUnitTypeMilitaryAcademy, -1, 60);
      return;
   }
}

// Research Conscript Infantry at 900 seconds; Titan only.
rule researchConscriptInfantry
inactive
minInterval 900
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechConscriptInfantry) == cTechStatusActive)
   {
      xsDisableRule("researchConscriptInfantry");
      return;
   }
   else if (kbTechGetStatus(cTechConscriptInfantry) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Conscript Infantry research plan.");
      researchSimpleTech(cTechConscriptInfantry, cUnitTypeMilitaryAcademy, -1, 60);
      return;
   }
}

// * * * * * * * * * * * //
//  TEMPLE TECHNOLOGIES  //
// * * * * * * * * * * * //

// Research Chthonic Rights at 1000 seconds; Hard and Titan only.
rule researchChthonicRites
inactive
minInterval 1000
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechChthonicRites) == cTechStatusActive)
   {
      xsDisableRule("researchChthonicRites");
      return;
   }
   else if (kbTechGetStatus(cTechChthonicRites) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Chthonic Ritres research plan.");
      researchSimpleTech(cTechChthonicRites, cUnitTypeTemple, -1, 60);
      return;
   }
}

// * * * * * * * * * * * * //
//  FORTRESS TECHNOLOGIES  //
// * * * * * * * * * * * * //

// Research Engineers at 1500 seconds; Hard and Titan only.
rule researchEngineers
inactive
minInterval 1500
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechEngineers) == cTechStatusActive)
   {
      xsDisableRule("researchEngineers");
      return;
   }
   else if (kbTechGetStatus(cTechEngineers) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Engineers research plan.");
      researchSimpleTech(cTechEngineers, cUnitTypeFortress, -1, 60);
      return;
   }
}

// * * * * * * * * * * * * //
//  ECONOMIC TECHNOLOGIES  //
// * * * * * * * * * * * * //

rule researchQuarry
active
minInterval 10
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
      researchSimpleTech(cTechQuarry, cUnitTypeStorehouse, -1, 60);
      return;
   }
}

void updateDefendPlans()
{
   // Ajax drove us in. Move defend point 1 north.
   aiPlanSetVariableVector(gDefendPlan1, cDefendPlanTargetPoint, 0, vector(215.0, 5.0, 239.0));
   aiPlanSetVariableVector(gDefendPlan1, cDefendPlanGatherPoint, 0, vector(215.0, 5.0, 239.0));
   debugAttackWave("Moved our defend plan next to our TC.");
}