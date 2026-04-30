//==============================================================================
/* fott03_p2.xs

   Red Greek player owning the base on the northern hill. Sends attacks of  Hoplites & Hippeus & Minotaurs.
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
float gTrainDelay2 = 12; // In seconds.
int gFirstLandUnit = cUnitTypeHoplite; // Gets trained from the start.
float gMaintainFirstLandUnitAmount = 8;
int gSecondLandUnit = cUnitTypeHippeus; // Gets trained from the start.
float gMaintainSecondLandUnitAmount = 5;
int gThirdLandUnit = cUnitTypeMinotaur; // Gets trained from the start.
float gMaintainThirdLandUnitAmount = 1;
int gFourthLandUnit = cUnitTypeNemeanLion; // Gets trained after reaching the Heroic Age.
float gMaintainFourthLandUnitAmount = 1;
int gFifthLandUnit = cUnitTypePeltast; // Gets trained after reaching the Heroic Age.
float gMaintainFifthLandUnitAmount = 3;

float gMaxVillagerCount = 10;
float gAttackStartDelay = 180; // In seconds.
float gAttackWaveInterval = 500; // In Seconds.
float gAttackFirstAttackStartSize = 5;
float gAttackIntervalAttackStartSize = 6;
float gAttackMaxSize = 10;
float gAttackSizeLimit = -1;

float gHeroicAgeUpTime = 720; // In seconds.

bool gDockDestroyed = false; // Flipped by function troyBuff()

vector gOurTCLocation = vector(196.0, 13.0, 263.0);
vector gEnemyTCLocation = vector(60.0, 2.0, 114.0);

Strategy scenarioAttackWaveStrategy()
{
   Strategy strategy;
   strategy.mData.mID = cStrategyScenarioAttackWave;
   strategy.mName = "Scenario Attack Wave";
   strategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      debugAttackWave("***Starting Scenario Attack Wave Strategy***");
      xsEnableRule("researchCopperShields");
      xsEnableRule("researchCopperWeaponsArmor");
      if (cDifficultyCurrent >= cDifficultyModerate)
      {
         xsEnableRule("researchMasons");
      }
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         xsEnableRule("researchLabyrinth");
      }
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         xsEnableRule("researchMediumCavalry");
      }

      //==============================================================================
      // Init Difficulty specific part.
      //==============================================================================

      // Make certain parameters way more lenient on Easy.
      if(cDifficultyCurrent == cDifficultyEasy)
      {
         gAttackStartDelay = 600; // Don't launch the first wave of cavalry until well into the mission.
         gAttackWaveInterval = 720; // Barely attack at all after the first strike.


         gAttackFirstAttackStartSize = 3; // Early Hippeis attack is not strong.
         gAttackIntervalAttackStartSize = 3; // Very feeble attacks on Easy.
         gAttackMaxSize = 6; // Never let this be too high.
      }

      gMaintainFirstLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainSecondLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainThirdLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFourthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gMaintainFifthLandUnitAmount *= gDifficultyModifierMaintainUnit;
      gTrainDelay *= gDifficultyModifierTrainDelay;
      gTrainDelay2 *= gDifficultyModifierTrainDelay;

      // Train delays are removed on harder difficulties.
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         gTrainDelay = 0;
         gTrainDelay2 = 0;
      }

      gAttackStartDelay *= gDifficultyModifierFirstAttack;
      gAttackWaveInterval *= gDifficultyModifierAttackInterval;
      gAttackFirstAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackIntervalAttackStartSize *= gDifficultyModifierAttackSizes;
      gAttackMaxSize *= gDifficultyModifierAttackSizes;

      // Early Hippeis attack is still not too tough on Moderate.
      if(cDifficultyCurrent == cDifficultyModerate)
      {
         gAttackStartDelay = 300;
      }

      gHeroicAgeUpTime = gHeroicAgeUpTime * gDifficultyModifierAgeUp + xsGetTime();

      // Set units to maintain from the start of the game.
      data.addUnitToMaintain(gFirstLandUnit, gMaintainFirstLandUnitAmount);
      data.addUnitToMaintain(gSecondLandUnit, gMaintainSecondLandUnitAmount);
      data.addUnitToMaintain(gThirdLandUnit, gMaintainThirdLandUnitAmount);

      // Train delay, how long the AI waits before queuing up another unit.
      data.setTrainDelay(gFirstLandUnit, gTrainDelay);
      data.setTrainDelay(gSecondLandUnit, gTrainDelay);
      data.setTrainDelay(gThirdLandUnit, gTrainDelay);

      // Details about the attack waves.
      gAttackWave.setName("gAttackWave");
      gAttackWave.setAttackStartTime(gAttackStartDelay);
      gAttackWave.setAttackInterval(gAttackWaveInterval);
      gAttackWave.setAttackSize(gAttackFirstAttackStartSize);
      gAttackWave.setMinAttackSize(gAttackFirstAttackStartSize);
      gAttackWave.setMaxAttackSize(gAttackMaxSize);
      gAttackWave.setAttackSizeMultiplier(gDifficultyModifierAttackSizeMultiplier);
      gAttackWave.addAttackUnitType(gSecondLandUnit); // Add Hippeus instantly.
      gAttackWave.displayFirstAttackStats();

      //==============================================================================
      // Init Shared part.
      //==============================================================================
      // Set flags for automatic resource gathering.
      data.setFlag(cStrategyFlagAutomaticEco, true);
      data.setFlag(cStrategyFlagAutomaticVillagerTraining, true);
      
      gAttackWave.setPlayerToAttack(1); // Attack player 1!

      // Where does our attack start.
      vector startPoint = vector(200.0, 10.0, 214.0); // Between the AI's 2 Fortresses.

      // Create the routes along which the AI attacks. Every route has equal chance of being choosen.
      // If you need a route to only become availabe later in the game you need to fetch gAttackWave.mAttackRouteID and add a
      // path to it.
      int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, gEnemyTCLocation);
      int pathID1 = kbPathCreate("Path 1 Left");
      kbPathAddWaypoint(pathID1, startPoint);
      kbPathAddWaypoint(pathID1, vector(153.0, 3.0, 149.0));
      kbPathAddWaypoint(pathID1, vector(74.0, 2.0, 148.0));
      kbPathAddWaypoint(pathID1, gEnemyTCLocation);
      kbAttackRouteAddPath(routeID, pathID1);

      int pathID2 = kbPathCreate("Path 2 Right");
      kbPathAddWaypoint(pathID2, startPoint);
      kbPathAddWaypoint(pathID2, vector(123.0, 5.5, 70.0));
      kbPathAddWaypoint(pathID2, vector(153.0, 3.0, 149.0));
      kbPathAddWaypoint(pathID2, vector(88.0, 2.0, 83.0));
      kbPathAddWaypoint(pathID2, gEnemyTCLocation);
      kbAttackRouteAddPath(routeID, pathID2);

      gAttackWave.setGatherPoint(startPoint);
      gAttackWave.setTargetPoint(gEnemyTCLocation);
      gAttackWave.setAttackRouteID(routeID);
      gAttackWave.setWaveStartCallback(
         [](int planID = -1)
         {
            static bool firstAttack = true;
            if (firstAttack == true)
            {
               gAttackWave.setAttackSize(gAttackIntervalAttackStartSize);
               gAttackWave.setMinAttackSize(gAttackIntervalAttackStartSize);
               // Add the Hoplites + Minotaurs + Shades in.
               gAttackWave.addAttackUnitType(gFirstLandUnit);
               gAttackWave.addAttackUnitType(gThirdLandUnit);
               gAttackWave.addAttackUnitType(cUnitTypeHadesShade);
               firstAttack = false;
            }
         }
      );

      int landDefendPlan = createDefendPlan("Primary Land Defend", kbBaseGetMainID(cMyID), 20.0, startPoint);
      aiPlanAddUnitType(landDefendPlan, gFirstLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gSecondLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gThirdLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gFourthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, gFifthLandUnit, 0, 0, 200);
      aiPlanAddUnitType(landDefendPlan, cUnitTypeHadesShade, 0, 0, 200);

      return true;
   };

   //==============================================================================
   // Update part.
   //==============================================================================
   // This function is ran every second by the strategy system. Use this to update your attack waves based on time/conditions.
   strategy.mUpdateFunc = [](ref StrategyData data) -> bool
   {
      static bool reachedHeroic = false;
      static bool needResearchHeroic = true;

      if (needResearchHeroic == true && xsGetTime() > gHeroicAgeUpTime)
      {
         if (researchSimpleTech(cTechHeroicAgeAphrodite, cUnitTypeTownCenter, -1, 75) == true)
         {
            debugAttackWave("Starting Heroic Age research plan.");
            needResearchHeroic = false;
         }
      }
      if (reachedHeroic == false && kbPlayerGetAge(cMyID) == cAge3)
      {
         data.addUnitToMaintain(gFourthLandUnit, gMaintainFourthLandUnitAmount);
         data.addUnitToMaintain(gFifthLandUnit, gMaintainFifthLandUnitAmount);
         data.setTrainDelay(gFourthLandUnit, gTrainDelay2);
         data.setTrainDelay(gFifthLandUnit, gTrainDelay2);

         // Increase attack size now that our army is larger.
         if (cDifficultyCurrent == cDifficultyModerate)
         {
            gAttackMaxSize += 4;
         }
         else if (cDifficultyCurrent == cDifficultyHard)
         {
            gAttackMaxSize += 6;
         }
         else if (cDifficultyCurrent == cDifficultyTitan)
         {
            gAttackMaxSize += 8;
         }
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            // Limit maximum attack wave size to the amount of relevant units we maintain.
            gAttackSizeLimit = gMaintainFirstLandUnitAmount;
            gAttackSizeLimit += gMaintainSecondLandUnitAmount;
            gAttackSizeLimit += gMaintainThirdLandUnitAmount;
            if (gAttackMaxSize > gAttackSizeLimit)
            {
               gAttackMaxSize = gAttackSizeLimit;
               debugAttackWave("Limiting maximum attack wave size to: " + gAttackSizeLimit);
            }
            gAttackWave.setMaxAttackSize(gAttackMaxSize);
         }

         xsEnableRule("addHeroicUnitsToAttack");

         // Easy Heroic Techs

         // Moderate Heroic Techs
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            xsEnableRule("researchBoilingOil");
            xsEnableRule("researchHeavyArchers");
            xsEnableRule("researchHeavyInfantry");
         }

         // Hard Heroic Techs
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            xsEnableRule("researchBronzeWeapons");
            xsEnableRule("researchGuardTower");
            xsEnableRule("researchArchitects");
            xsEnableRule("researchRoarOfOrthus");
         }

         // Titan Heroic Techs
         if (cDifficultyCurrent == cDifficultyTitan)
         {
            xsEnableRule("researchBronzeArmor");
            xsEnableRule("researchBronzeShields");
            xsEnableRule("researchHeavyCavalry");
         }

         reachedHeroic = true;
      }

      /***** Increase army sizes on harder difficulties deep into the mission. *****/
      static bool lion_peltast_increase = false;

      // Start training more Nemean Lions and Peltasts after 20 minutes on Titan.
      if (cDifficultyCurrent == cDifficultyTitan && xsGetTime() >= 1200)
      {
         if (lion_peltast_increase == false && reachedHeroic == true)
         { 
            gMaintainFourthLandUnitAmount *= 2.0; // Train +100% Nemean Lions.
            gMaintainFifthLandUnitAmount *= 2.0; // Train +100% Peltasts.

            data.adjustUnitToMaintainAmount(gFourthLandUnit, gMaintainFourthLandUnitAmount);
            data.adjustUnitToMaintainAmount(gFifthLandUnit, gMaintainFifthLandUnitAmount);

            // Update attack size parameters based on the addition of the Nemean Lions and Peltasts.
            gAttackMaxSize *= 1.05; // Increase attack size by +5%.
            gAttackWave.setMaxAttackSize(gAttackMaxSize);

            lion_peltast_increase = true;
         }
      }

      static bool army_buffed = false;

      if (army_buffed == false && gDockDestroyed == true)
      {
         // Increase does not occur on Easy.
         if (cDifficultyCurrent >= cDifficultyModerate)
         {
            gMaintainFirstLandUnitAmount *= 1.5; // Train +50% Hoplites.
            gMaintainSecondLandUnitAmount *= 1.5; // Train +50% Hippeis.
            gMaintainThirdLandUnitAmount *= 1.5; // Train +50% Minotaurs.

            data.adjustUnitToMaintainAmount(gFirstLandUnit, gMaintainFirstLandUnitAmount);
            data.adjustUnitToMaintainAmount(gSecondLandUnit, gMaintainSecondLandUnitAmount);
            data.adjustUnitToMaintainAmount(gThirdLandUnit, gMaintainThirdLandUnitAmount);
                           
            // Update attack size parameters based on the enlarged army composition.
            gAttackMaxSize *= 1.10; // Attack size increases by +10%
            gAttackWave.setMaxAttackSize(gAttackMaxSize);

            // Train more Villagers to support the larger army.
            gMaxVillagerCount *= 1.25; // Train +25% more Villagers.
            gOverrideMaxVillagerPop = gMaxVillagerCount;

            debugAttackWave("An allied dock has been destroyed, increasing army as well as villager numbers.");
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
void fott03StrategySetup()
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
   gMaxVillagerCount *= gDifficultyModifierMaintainVillager;

   gOverrideMaxVillagerPop = gMaxVillagerCount;

   gMainGatherBase = createOverrideGatherBase(vector(197.00, 0.00, 263.00), 40);

   gTimeToFarm = true;

   setOverrideStrategy(fott03StrategySetup);

   // We can't have too many farms due to space restrictions.
   gOverrideFarmCount = 15; 
   gFarmPlacementOverrideUsed = true;
   gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool
   {
      kbBuildingPlacementSetCenterPosition(bpID, gOurTCLocation, 15.0);
      kbBuildingPlacementAddPositionInfluence(bpID, gOurTCLocation, 100.0, 15.0, cFalloffLinear);
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

rule addHeroicUnitsToAttack
inactive
minInterval 240
{
   gAttackWave.addAttackUnitType(gFourthLandUnit);
   gAttackWave.addAttackUnitType(gFifthLandUnit);
   gAttackMaxSize = 12 * gDifficultyModifierAttackSizes;

   // Limit maximum attack wave size to the amount of relevant units we maintain.
   gAttackSizeLimit = gMaintainFirstLandUnitAmount;
   gAttackSizeLimit += gMaintainSecondLandUnitAmount;
   gAttackSizeLimit += gMaintainThirdLandUnitAmount;
   gAttackSizeLimit += gMaintainFourthLandUnitAmount;
   gAttackSizeLimit += gMaintainFifthLandUnitAmount;
   if (gAttackMaxSize > gAttackSizeLimit)
   {
      gAttackMaxSize = gAttackSizeLimit;
      debugAttackWave("Limiting maximum attack wave size to: " + gAttackSizeLimit);
   }

   gAttackWave.setMaxAttackSize(gAttackMaxSize);
   xsDisableRule("addHeroicUnitsToAttack");
}

rule researchCopperShields
inactive
minInterval 300
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

rule researchCopperWeaponsArmor
inactive
minInterval 360
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

rule researchMediumCavalry
inactive
minInterval 270
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

rule researchLabyrinth
inactive
minInterval 340
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechLabyrinthOfMinos) == cTechStatusActive)
   {
      xsDisableRule("researchLabyrinth");
      return;
   }
   else if (kbTechGetStatus(cTechLabyrinthOfMinos) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Labyrinth of Minos research plan.");
      researchSimpleTech(cTechLabyrinthOfMinos, cUnitTypeTemple, -1, 60);
      return;
   }
}

rule researchRoarOfOrthus
inactive
minInterval 300
{
   xsSetRuleMinIntervalSelf(10);
   // Cease if we have it. Otherwise, research it.
   if (kbTechGetStatus(cTechRoarOfOrthus) == cTechStatusActive)
   {
      xsDisableRule("researchRoarOfOrthus");
      return;
   }
   else if (kbTechGetStatus(cTechRoarOfOrthus) == cTechStatusObtainable)
   {
      debugAttackWave("Starting Roar of Orthus research plan.");
      researchSimpleTech(cTechRoarOfOrthus, cUnitTypeTemple, -1, 60);
      return;
   }
}

rule researchHeavyArchers
active
minInterval 360
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

rule researchHeavyInfantry
active
minInterval 360
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

rule researchHeavyCavalry
active
minInterval 480
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

rule researchBronzeShields
inactive
minInterval 600
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

rule researchBronzeArmor
inactive
minInterval 600
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

rule researchBronzeWeapons
inactive
minInterval 600
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

rule researchArchitects
inactive
minInterval 180
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

rule researchGuardTower
inactive
minInterval 320
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


// Called from triggers once Troy loses their first Dock.
void troyBuff()
{
   gDockDestroyed = true;
}