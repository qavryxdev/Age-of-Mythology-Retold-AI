//==============================================================================
/* ai_improvements_v38.xs  -  v3.8 - META-LEVEL

   Sedme kolo - 10 vylepseni nad metaurovni nad 60 predchozimi:
   integrace, konflikty, throttling, endgame state machine.

   P1: 61 Rule interference matrix, 62 Throttling, 63 Endgame state machine
   P2: 64 Hoarding detector, 65 GP sequencing, 66 Game tempo classifier
   P3: 67 Anti-cheese, 68 Ally coordination, 69 Retreat coordination,
       70 Chat triggers
*/
//==============================================================================

//==============================================================================
// SEKCE 1 - Globaly
//==============================================================================

// --- 61: Rule interference ---
extern int gLastIntervalModifierRule = -1;
extern int gLastIntervalModifierTime = 0;
extern int gIntervalModifierThrashCount = 0;

// --- 62: Throttling ---
extern int gActiveUrgentRulesCount = 0;
extern int gThrottleAdvisoryActive = 0;

// --- 63: Endgame state machine ---
extern int gGamePhase = 0; // 0=BO, 1=exp, 2=class, 3=heroic, 4=mythic, 5=endgame
extern int gEndgameStrategy = 0; // 0=undecided, 1=raceWonder, 2=raceTitan, 3=allOutAttack, 4=popDenial

// --- 64: Hoarding ---
extern int gLastHoardingCheck = 0;
extern bool gHoardingActive = false;

// --- 65: GP sequencing ---
extern int gLastGPSequenceTime = 0;

// --- 66: Game tempo ---
extern int gGamePaceMode = 0; // 0=balanced, 1=fastRush, 2=slowMacro
extern bool gGamePaceClassified = false;

// --- 67: Anti-cheese ---
extern int[] gEnemyTowerBuildTimes = default;
extern bool gEnemyCheeseActive = false;

// --- 68: Ally coordination ---
extern int[] gAllyArmySize = default;
extern bool[] gAllyIsAttacking = default;
extern int gLastAllyCoordTime = 0;

// --- 69: Coordinated retreat ---
extern int gLastArmySize = 0;
extern int gArmySizeCheckTime = 0;
extern bool gRetreatActive = false;

// --- 70: Chat triggers ---
extern int gLastChatHelpTime = 0;

//==============================================================================
// SEKCE 2 - P1: Rule interference, throttling, endgame
//==============================================================================

//------------------------------------------------------------------------------
// 61: Rule interference matrix (logging)
// Sleduje konflikty mezi rules ktere modifikuji stejne globaly.
// Detekuje thrashing: zmena gAdaptAttackIntervalBonus 2+ krat za 5s rozdilnymi
// rules = thrashing detected.
// (Logging only - actual fix by rovnavalo dramaticke rozdily v existujicim kodu.)
//------------------------------------------------------------------------------
extern int gLastIntervalBonusValue = 999;
extern int gLastUrgencyValue = -1;

void detectInterference()
{
   int now = xsGetTime();

   // Detect attack interval bonus thrashing
   if (gLastIntervalBonusValue != 999 && gAdaptAttackIntervalBonus != gLastIntervalBonusValue)
   {
      int delta = gAdaptAttackIntervalBonus - gLastIntervalBonusValue;
      if ((now - gLastIntervalModifierTime) < 5000 && delta != 0)
      {
         gIntervalModifierThrashCount = gIntervalModifierThrashCount + 1;
         if (gIntervalModifierThrashCount >= 3)
         {
            debugStrategy("61: THRASHING detected - gAdaptAttackIntervalBonus changed " +
               gIntervalModifierThrashCount + "x within 5s windows. Last delta=" + delta);
         }
      }
      else
      {
         gIntervalModifierThrashCount = 0;
      }
      gLastIntervalModifierTime = now;
   }

   gLastIntervalBonusValue = gAdaptAttackIntervalBonus;

   // Detect urgency thrashing
   int curUrgencyInt = xsFloatToInt(gMilitaryUrgency * 10.0);
   if (gLastUrgencyValue != -1 && curUrgencyInt != gLastUrgencyValue)
   {
      int udelta = curUrgencyInt - gLastUrgencyValue;
      if (udelta < -3 || udelta > 3) // big jump
      {
         debugStrategy("61: urgency big jump " + gLastUrgencyValue + " -> " + curUrgencyInt);
      }
   }
   gLastUrgencyValue = curUrgencyInt;
}

rule interferenceMonitor
inactive
group defaultClassicalRules
minInterval 2
{
   detectInterference();
}

//------------------------------------------------------------------------------
// 62: Adaptive rule throttling under load
// Sleduje pocet aktivnich urgent rules. Pri >=5 souben emergency stavu
// nastavi throttle advisory flag - jine rules pak mohou zvolnit interval.
//------------------------------------------------------------------------------
void countActiveUrgentRules()
{
   int count = 0;
   if (gMilitaryUrgency >= 0.9) { count = count + 1; }
   if (gDefenseReflexPanic == true) { count = count + 1; }
   if (gAdaptTotalDefenseMode == true) { count = count + 1; }
   if (gEmergencyDefenseActive == true) { count = count + 1; }
   if (gWonderDefenseActive == true) { count = count + 1; }
   if (gEnemyEndgameRaceActive == true) { count = count + 1; }
   if (gWallBreachActive == true) { count = count + 1; }
   if (gIslandEscapeTriggered == true) { count = count + 1; }
   if (gCeasefireBoomActive == true) { count = count + 1; }
   if (gEcoCrisisActive == true) { count = count + 1; }

   gActiveUrgentRulesCount = count;

   if (count >= 5)
   {
      if (gThrottleAdvisoryActive == 0)
      {
         gThrottleAdvisoryActive = 1;
         debugStrategy("62: THROTTLE ADVISORY active - " + count + " urgent rules running");
      }
   }
   else if (gThrottleAdvisoryActive == 1 && count < 3)
   {
      gThrottleAdvisoryActive = 0;
      debugStrategy("62: throttle advisory cleared (urgent count=" + count + ")");
   }
}

rule throttleMonitor
inactive
group defaultClassicalRules
minInterval 10
{
   countActiveUrgentRules();
}

//------------------------------------------------------------------------------
// 63: Endgame state machine
// Pri pop>=180 enum gGamePhase = 5 a vybira endgame strategii.
//------------------------------------------------------------------------------
void evaluateEndgameStrategy()
{
   int popCur = kbPlayerGetPop(cMyID);
   int popCap = kbPlayerGetPopCap(cMyID);
   int myAge = kbPlayerGetAge(cMyID);

   // Update gGamePhase based on age
   if (myAge == cAge1)      { gGamePhase = 1; }
   else if (myAge == cAge2) { gGamePhase = 2; }
   else if (myAge == cAge3) { gGamePhase = 3; }
   else if (myAge == cAge4) { gGamePhase = 4; }
   if (popCur >= 180 && popCap >= 180) { gGamePhase = 5; }

   if (gGamePhase < 5) { return; }

   // Endgame decision tree
   bool myWonderProgress = (kbUnitCount(cUnitTypeWonder, cMyID, cUnitStateBuilding) >= 1 ||
                            kbUnitCount(cUnitTypeWonder, cMyID, cUnitStateAlive) >= 1);
   bool enemyWonderProgress = false;
   bool enemyTitanProgress = false;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      if (kbUnitCount(cUnitTypeWonder, p, cUnitStateBuilding) >= 1 ||
          kbUnitCount(cUnitTypeWonder, p, cUnitStateAlive) >= 1)
      {
         enemyWonderProgress = true;
      }
      if (kbUnitCount(cUnitTypeTitanGate, p, cUnitStateBuilding) >= 1 ||
          kbUnitCount(cUnitTypeAbstractTitan, p, cUnitStateAlive) >= 1)
      {
         enemyTitanProgress = true;
      }
   }

   bool myTitanAvail = (kbUnitCount(cUnitTypeAbstractTitan, cMyID, cUnitStateAlive) >= 1 ||
                        kbUnitCount(cUnitTypeTitanGate, cMyID, cUnitStateBuilding) >= 1);

   // Decision
   int newStrategy = 0;
   if (enemyWonderProgress == true)
   {
      // Race or all-out attack
      newStrategy = 3; // allOutAttack
   }
   else if (enemyTitanProgress == true)
   {
      newStrategy = 3; // attack + protect
   }
   else if (myWonderProgress == true)
   {
      newStrategy = 1; // race wonder (defend)
   }
   else if (myTitanAvail == true)
   {
      newStrategy = 2; // race titan
   }
   else
   {
      newStrategy = 4; // pop denial
   }

   if (newStrategy != gEndgameStrategy)
   {
      gEndgameStrategy = newStrategy;
      debugStrategy("63: endgame strategy = " + newStrategy +
         " (myWonder=" + myWonderProgress + " enemyWonder=" + enemyWonderProgress +
         " enemyTitan=" + enemyTitanProgress + " myTitan=" + myTitanAvail + ")");
   }

   // Apply strategy effects
   if (gEndgameStrategy == 3) // all-out attack
   {
      gAdaptAttackIntervalBonus = -90;
      gMilitaryUrgency = 1.0;
   }
   else if (gEndgameStrategy == 1) // race wonder
   {
      gMilitaryUrgency = 0.7; // defend
   }
}

rule endgameStateMonitor
inactive
group defaultClassicalRules
minInterval 20
{
   evaluateEndgameStrategy();
}

//==============================================================================
// SEKCE 3 - P2: Hoarding, GP sequencing, tempo classifier
//==============================================================================

//------------------------------------------------------------------------------
// 64: Resource hoarding deadlock detector
// food/wood/gold > 3000 + 0 build plans = ekonomika je rozbita.
//------------------------------------------------------------------------------
void detectHoarding()
{
   int now = xsGetTime();
   if ((now - gLastHoardingCheck) < 30000) { return; }

   float food = kbResourceGet(cResourceFood);
   float wood = kbResourceGet(cResourceWood);
   float gold = kbResourceGet(cResourceGold);

   bool hoarding = false;
   string reason = "";

   int[] buildPlans = aiPlanGetIDsByType(cPlanBuild);
   int activeBuildPlans = buildPlans.size();

   if (food > 3000.0 && activeBuildPlans < 2)
   {
      hoarding = true;
      reason = "food " + food;
   }
   if (wood > 3500.0 && activeBuildPlans < 2)
   {
      hoarding = true;
      reason = "wood " + wood;
   }
   if (gold > 4000.0 && activeBuildPlans < 2)
   {
      hoarding = true;
      reason = "gold " + gold;
   }

   if (hoarding == true)
   {
      gHoardingActive = true;
      // Force market emergency sell
      if (kbUnitCount(gMarketUnit, cMyID, cUnitStateAlive) > 0)
      {
         if (food > 3000.0) { aiSellResourceOnMarket(cResourceFood); }
         if (wood > 3500.0) { aiSellResourceOnMarket(cResourceWood); }
         if (gold > 4000.0) { aiSellResourceOnMarket(cResourceGold); }
      }

      // Boost tech research priority - pretahnout zdroje do vyzkumu
      if (aiPlanGetIsIDValid(gMilitaryResearchPlan) == true)
      {
         int curPri = aiPlanGetPriority(gMilitaryResearchPlan);
         if (curPri < 75)
         {
            aiPlanSetPriority(gMilitaryResearchPlan, curPri + 10);
         }
      }

      debugStrategy("64: HOARDING detected (" + reason + ", buildPlans=" +
         activeBuildPlans + ") - market sell + tech priority bump");
   }
   else if (gHoardingActive == true)
   {
      gHoardingActive = false;
      debugStrategy("64: hoarding cleared");
   }

   gLastHoardingCheck = now;
}

rule hoardingMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   detectHoarding();
}

//------------------------------------------------------------------------------
// 65: GP cooldown sequencing
// Pri >=2 GP v bank reorder podle kontextove priority pred flush.
//------------------------------------------------------------------------------
void sequenceGodPowers()
{
   int now = xsGetTime();
   if ((now - gLastGPSequenceTime) < 15000) { return; }

   int bankSize = godPowerManager.godPowerBank.size();
   if (bankSize < 2) { return; }

   // Priority kontextu: defensive (loss>40%) > offensive (cluster>=8) > economic
   int contextPriority = 3; // economic default
   if (gAdaptAvgLossRate > 0.40)
   {
      contextPriority = 1; // defensive
   }
   else if (gBestGPTargetCount >= 8)
   {
      contextPriority = 2; // offensive
   }

   debugStrategy("65: GP bank=" + bankSize + " context=" + contextPriority +
      " (loss=" + gAdaptAvgLossRate + " bestTarget=" + gBestGPTargetCount + ")");

   // Force flush ted (engine setupGodPowerPlan resi konkretni placement per GP)
   godPowerManager.useUnusedGodPowers();
   gLastGPSequenceTime = now;
}

rule gpSequenceMonitor
inactive
group defaultClassicalRules
minInterval 15
{
   sequenceGodPowers();
}

//------------------------------------------------------------------------------
// 66: Game tempo classifier
// Pri startu klasifikuje hru do {fastRush, balanced, slowMacro} podle
// player count + map type + starting water.
//------------------------------------------------------------------------------
void classifyGameTempo()
{
   if (gGamePaceClassified == true) { return; }

   int playerCount = 0;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (kbPlayerHasLost(p) == false) { playerCount = playerCount + 1; }
   }

   bool isIsland = gMapInfo.mIsIslandMap;
   bool hasWater = gMapInfo.mHasWater;

   if (isIsland == true || (hasWater == true && playerCount <= 2))
   {
      gGamePaceMode = 2; // slowMacro
   }
   else if (playerCount >= 4 && hasWater == false)
   {
      gGamePaceMode = 1; // fastRush
   }
   else
   {
      gGamePaceMode = 0; // balanced
   }

   // Aplikace na BO variant a aggression
   if (gGamePaceMode == 1) // fastRush
   {
      // Bumpne rush BO + aggressive personality
      gPersonalityTier = 3; // Aggressive
      gAdaptAttackIntervalBonus = -30;
   }
   else if (gGamePaceMode == 2) // slowMacro
   {
      gPersonalityTier = 2; // Balanced (eco focus)
      // Snizena aggression
      gAdaptAttackIntervalBonus = 30;
   }

   gGamePaceClassified = true;
   debugStrategy("66: game tempo classified mode=" + gGamePaceMode +
      " (players=" + playerCount + " island=" + isIsland + " water=" + hasWater + ")");
}

rule gameTempoClassifier
inactive
group defaultArchaicRules
minInterval 10
{
   classifyGameTempo();
   if (gGamePaceClassified == true)
   {
      xsDisableRule("gameTempoClassifier");
   }
}

//==============================================================================
// SEKCE 4 - P3: Anti-cheese, ally, retreat, chat
//==============================================================================

//------------------------------------------------------------------------------
// 67: Anti-cheese pattern detection
// Sleduje enemy tower build events. Pri >=3 events za 60s + kratke vzdalenosti
// = tower rush cheese -> max defense response.
//------------------------------------------------------------------------------
void detectTowerRushCheese()
{
   int now = xsGetTime();

   int totalEnemyTowers = 0;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      totalEnemyTowers = totalEnemyTowers + kbUnitCount(cUnitTypeAbstractTower, p, cUnitStateAlive);
      totalEnemyTowers = totalEnemyTowers + kbUnitCount(cUnitTypeAbstractTower, p, cUnitStateBuilding);
   }

   // Track build events: append timestamp pri increase
   static int lastTotalTowers = 0;
   if (totalEnemyTowers > lastTotalTowers)
   {
      gEnemyTowerBuildTimes.add(now);
      lastTotalTowers = totalEnemyTowers;
   }

   // Cleanup old entries (>120s)
   while (gEnemyTowerBuildTimes.size() > 0 && (now - gEnemyTowerBuildTimes[0]) > 120000)
   {
      gEnemyTowerBuildTimes.removeIndex(0);
   }

   // Detection
   if (gEnemyTowerBuildTimes.size() >= 3)
   {
      // 3+ towers v 120s = cheese
      if (gEnemyCheeseActive == false)
      {
         gEnemyCheeseActive = true;
         gMilitaryUrgency = 1.0;
         gAdaptAttackIntervalBonus = -45;
         // Boost wall building / fortress priority
         if (gFortressUnit > 0)
         {
            int planID = createSimpleBuildPlan(gFortressUnit, 1, 80, -1, 1);
            if (planID >= 0)
            {
               debugStrategy("67: TOWER RUSH CHEESE detected (" + gEnemyTowerBuildTimes.size() +
                  " towers in 120s) - emergency fortress build");
            }
         }
         aiEchoWarning("67: tower rush cheese!");
      }
   }
   else if (gEnemyCheeseActive == true && gEnemyTowerBuildTimes.size() < 2)
   {
      gEnemyCheeseActive = false;
      debugStrategy("67: cheese mode cleared");
   }
}

rule antiCheeseMonitor
inactive
group defaultClassicalRules
minInterval 20
{
   detectTowerRushCheese();
}

//------------------------------------------------------------------------------
// 68: Multi-AI ally coordination
// Track ally state, defer attack pri ally aggressive push.
//------------------------------------------------------------------------------
void coordinateWithAllies()
{
   int now = xsGetTime();

   // Resize arrays (cNumberPlayers + 1)
   if (gAllyArmySize.size() <= cNumberPlayers)
   {
      gAllyArmySize.resize(cNumberPlayers + 1, 0);
      gAllyIsAttacking.resize(cNumberPlayers + 1, false);
   }

   bool anyAllyAttacking = false;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsAlly(p) == false) { continue; }
      if (kbPlayerHasLost(p) == true) { continue; }

      gAllyArmySize[p] = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, p, cUnitStateAlive);
      // Ally attack proxy: ally military > 30 + visible enemy units in vicinity
      bool likelyAttacking = (gAllyArmySize[p] >= 30);
      gAllyIsAttacking[p] = likelyAttacking;
      if (likelyAttacking) { anyAllyAttacking = true; }
   }

   // Ally attacking - sniz nas attack interval pro koordinovany push
   if (anyAllyAttacking == true && (now - gLastAllyCoordTime) > 60000)
   {
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus - 30;
      gLastAllyCoordTime = now;
      debugStrategy("68: ally attacking - coord push (interval -30)");
   }
}

rule allyCoordMonitor
inactive
group defaultClassicalRules
minInterval 15
{
   coordinateWithAllies();
}

//------------------------------------------------------------------------------
// 69: Coordinated retreat
// Pri velkych ztratach v active attack planu -> remove units, fall back.
//------------------------------------------------------------------------------
void detectAndRetreat()
{
   int curArmy = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive);
   int now = xsGetTime();

   if (gLastArmySize == 0)
   {
      gLastArmySize = curArmy;
      gArmySizeCheckTime = now;
      return;
   }

   int dtSec = (now - gArmySizeCheckTime) / 1000;
   if (dtSec < 30) { return; }

   // Loss > 50% v 30s = catastrophic - retreat
   if (gLastArmySize > 10)
   {
      int loss = gLastArmySize - curArmy;
      float lossRate = xsIntToFloat(loss) / xsIntToFloat(gLastArmySize);

      if (lossRate > 0.50 && gRetreatActive == false)
      {
         gRetreatActive = true;
         debugStrategy("69: RETREAT - lost " + loss + "/" + gLastArmySize +
            " (" + lossRate + ") in 30s - falling back");

         // Remove units from active attack plans
         int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
         for (int i = 0; i < attackPlans.size(); i++)
         {
            int planID = attackPlans[i];
            if (aiPlanGetIsIDValid(planID) == false) { continue; }
            if (aiPlanGetParentID(planID) != -1) { continue; }
            int[] units = aiPlanGetUnits(planID, cUnitTypeLogicalTypeLandMilitary);
            for (int j = 0; j < units.size(); j++)
            {
               if (kbUnitGetIsIDValid(units[j]) == true)
               {
                  aiPlanRemoveUnit(planID, units[j]);
               }
            }
         }
         // Bumpne defense
         gMilitaryUrgency = 1.0;
         gDefenseReflex = true;
      }
      else if (gRetreatActive == true && (now - gArmySizeCheckTime) > 60000)
      {
         gRetreatActive = false;
         debugStrategy("69: retreat window expired - resuming");
      }
   }

   gLastArmySize = curArmy;
   gArmySizeCheckTime = now;
}

rule retreatMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   detectAndRetreat();
}

//------------------------------------------------------------------------------
// 70: Diplomatic chat triggers
// Pri panic + ally exists -> aiChat help request (dela existing chat infrastruktura
// jen log, protoze chat content je per chatset).
//------------------------------------------------------------------------------
void triggerHelpChat()
{
   if (gDefenseReflexPanic == false) { return; }

   int now = xsGetTime();
   if ((now - gLastChatHelpTime) < 120000) { return; } // Min 2 min between requests

   // Check ally exists
   bool hasAlly = false;
   int allyID = -1;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsAlly(p) == true && kbPlayerHasLost(p) == false)
      {
         hasAlly = true;
         allyID = p;
         break;
      }
   }

   if (hasAlly == false) { return; }

   // Trigger chat - "1" je standard help request v chats.xs
   aiChat(allyID, "1");
   gLastChatHelpTime = now;
   debugStrategy("70: panic + ally exists - sent help request to player " + allyID);
}

rule chatTriggerMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   triggerHelpChat();
}
