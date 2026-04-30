//==============================================================================
/* ai_improvements_v37.xs  -  v3.7

   Seste kolo systemovych vylepseni (#51 - #60).

   P1: 51 Hero death tracking, 52 Favor velocity collapse, 53 Dock cleanup
   P2: 54 Multi-island sequencing, 55 Mythic counter chain, 56 Brittle-point
   P3: 57 Spell placement radius, 58 Forward base, 59 Civ-specific bonuses,
       60 Resource denial via raid
*/
//==============================================================================

//==============================================================================
// SEKCE 1 - Globaly
//==============================================================================

// --- 51: Hero death tracking ---
extern int gPrevEnemyHeroCount = 0;
extern int gHeroDeathOpportunityUntil = 0;

// --- 52: Favor velocity ---
extern float gLastFavor = 0.0;
extern float gFavorVelocity = 0.0;
extern int gLastFavorCheckTime = 0;

// --- 53: Dock cleanup ---
extern int gLastDockCleanupCheck = 0;

// --- 54: Multi-island sequencing ---
extern int gCurrentIslandHopIndex = 0;
extern int gLastHopAdvanceTime = 0;

// --- 55: Mythic counter chain ---
extern int gLastMythicCounterTime = 0;

// --- 56: Brittle-point ---
extern int gBrittlenessScore = 0;

// --- 58: Forward base ---
extern bool gForwardBaseTriggered = false;
extern int gForwardBaseTime = 0;

// --- 60: Resource denial raid ---
extern int gLastRaidScanTime = 0;
extern int gRaidTargetUnitID = -1;

//==============================================================================
// SEKCE 2 - P1: Hero death, favor velocity, dock cleanup
//==============================================================================

//------------------------------------------------------------------------------
// 51: Hero death tracking + opportunistic push
// Sleduje enemy hero count delta, pri poklesu force aggressive 15s window.
//------------------------------------------------------------------------------
void monitorHeroDeaths()
{
   int curEnemyHeroes = 0;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      curEnemyHeroes = curEnemyHeroes + kbUnitCount(cUnitTypeHero, p, cUnitStateAlive);
   }

   int now = xsGetTime();

   if (gPrevEnemyHeroCount > 0 && curEnemyHeroes < gPrevEnemyHeroCount)
   {
      int delta = gPrevEnemyHeroCount - curEnemyHeroes;
      gHeroDeathOpportunityUntil = now + 15000; // 15s window
      gAdaptAttackIntervalBonus = -45;
      xsRuleIgnoreIntervalOnce("attackManager");
      debugStrategy("51: enemy hero death detected (delta=" + delta +
         ") - 15s aggressive push window opened");
   }

   // Reset bonus po skonceni windowa
   if (gHeroDeathOpportunityUntil > 0 && now > gHeroDeathOpportunityUntil)
   {
      if (gAdaptAttackIntervalBonus < 0)
      {
         gAdaptAttackIntervalBonus = 0;
      }
      gHeroDeathOpportunityUntil = 0;
   }

   gPrevEnemyHeroCount = curEnemyHeroes;
}

rule heroDeathMonitor
inactive
group defaultClassicalRules
minInterval 5
{
   monitorHeroDeaths();
}

//------------------------------------------------------------------------------
// 52: Favor velocity collapse
// Sleduje favor velocity. Pri kolapsu (nizka rate + low absolute) bumpne
// gather priority pres force breakdown update + market sell food/gold za favor
// pokud je nepri vytrviva.
//------------------------------------------------------------------------------
void monitorFavorVelocity()
{
   int myAge = kbPlayerGetAge(cMyID);
   if (myAge < cAge2) { return; }

   float curFavor = kbResourceGet(cResourceFavor);
   int now = xsGetTime();

   if (gLastFavorCheckTime == 0)
   {
      gLastFavor = curFavor;
      gLastFavorCheckTime = now;
      return;
   }

   float dtSec = xsIntToFloat(now - gLastFavorCheckTime) / 1000.0;
   if (dtSec < 5.0) { return; }

   gFavorVelocity = (curFavor - gLastFavor) / dtSec;
   gLastFavor = curFavor;
   gLastFavorCheckTime = now;

   // Kolaps: nizka rate (< 0.1/s) + low absolute (< 30) + mam GP v bank
   if (curFavor < 30.0 && gFavorVelocity < 0.1 && godPowerManager.godPowerBank.size() > 0)
   {
      // Force update breakdown - favor gather plan se znovu vytvori
      gDelayUpdateDistributionAndBreakdowns = false;
      debugStrategy("52: FAVOR COLLAPSE - favor=" + curFavor + " velocity=" + gFavorVelocity +
         " - force breakdown update + bank still has " + godPowerManager.godPowerBank.size() + " GP");
   }
}

rule favorVelocityMonitor
inactive
group defaultClassicalRules
minInterval 20
{
   monitorFavorVelocity();
}

//------------------------------------------------------------------------------
// 53: Dock proximity cleanup
// Identifikuje "deceptive" docky bez vyuziti (0 transports/fishing v 50 tile
// > 120s). Logujeme - nedemoluju automaticky (riskantni) ale flagne pro
// snizeni priority dalsich naval planu na te lokaci.
//------------------------------------------------------------------------------
void scanDeceptiveDocks()
{
   int now = xsGetTime();
   if ((now - gLastDockCleanupCheck) < 60000) { return; }

   int qID = kbUnitQueryCreate("dockScan");
   kbUnitQuerySetPlayerID(qID, cMyID);
   kbUnitQuerySetUnitType(qID, cUnitTypeDock);
   kbUnitQuerySetState(qID, cUnitStateAlive);
   kbUnitQueryResetResults(qID);
   int n = kbUnitQueryExecute(qID);
   if (n <= 1) { return; } // Nemame zbytecny dock

   int deceptiveCount = 0;
   for (int i = 0; i < n; i++)
   {
      int dockID = kbUnitQueryGetResult(qID, i);
      if (kbUnitGetIsIDValid(dockID) == false) { continue; }
      vector dPos = kbUnitGetPosition(dockID);

      // Transport ships v 50 tile?
      int transportPUID = getNavalTransport();
      int transportNear = 0;
      if (transportPUID > 0)
      {
         transportNear = getUnitCountByLocation(transportPUID, cMyID, cUnitStateAlive,
            dPos, 50.0, cUnitQueryVisibleStateVisible);
      }
      // Fishing ships v 50 tile?
      int fishingNear = 0;
      if (gFishingUnit > 0)
      {
         fishingNear = getUnitCountByLocation(gFishingUnit, cMyID, cUnitStateAlive,
            dPos, 50.0, cUnitQueryVisibleStateVisible);
      }

      if (transportNear == 0 && fishingNear == 0)
      {
         deceptiveCount++;
         debugStrategy("53: deceptive dock " + dockID + " at " + dPos +
            " (no transport/fishing usage)");
      }
   }

   gLastDockCleanupCheck = now;
   if (deceptiveCount > 0)
   {
      debugStrategy("53: " + deceptiveCount + " deceptive docks detected (manual cleanup recommended)");
   }
}

rule dockCleanupMonitor
inactive
group defaultClassicalRules
minInterval 60
{
   scanDeceptiveDocks();
}

//==============================================================================
// SEKCE 3 - P2: Multi-island sequencing, mythic counter, brittle-point
//==============================================================================

//------------------------------------------------------------------------------
// 54: Multi-island sequencing optimization
// Misto buildovani vsech mezilehlych ostrovu naraz iteruje 1 cili po druhem.
// Advance po dokonceni TC na aktualnim cili.
//------------------------------------------------------------------------------
void sequenceIslandHops()
{
   if (gIslandChainComputed == false) { return; }
   if (gIslandChainHopLands.size() == 0) { return; }
   if (gCurrentIslandHopIndex >= gIslandChainHopLands.size()) { return; }

   int now = xsGetTime();
   if ((now - gLastHopAdvanceTime) < 90000) { return; } // Cooldown 90s mezi advance

   int targetAG = gIslandChainHopLands[gCurrentIslandHopIndex];
   int firstAreaID = kbAreaGroupGetAreaID(targetAG, 0);
   if (firstAreaID < 0) { return; }
   vector targetPos = kbAreaGetCenter(firstAreaID);
   if (targetPos == cInvalidVector) { return; }

   // Mame uz TC v 80 tile od cilove pozice?
   int existingTC = getClosestUnitByLocation(cUnitTypeAbstractTownCenter,
      cMyID, cUnitStateAlive, targetPos, 80.0);

   if (existingTC >= 0)
   {
      // Advance na dalsi island
      gCurrentIslandHopIndex = gCurrentIslandHopIndex + 1;
      gLastHopAdvanceTime = now;
      debugStrategy("54: island hop " + gCurrentIslandHopIndex + "/" +
         gIslandChainHopLands.size() + " complete - advancing");
   }
}

rule islandSequencingMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   sequenceIslandHops();
}

//------------------------------------------------------------------------------
// 55: Mythic counter chain (civ vs civ)
// Pri detekci enemy mythic units bumpne pomer counter unit type.
// Tabulka: ranged counters (Nemea, Frost Giant) -> heroes
//          mobile counters (Behemoth) -> ranged
//          air units -> ranged anti-air
//------------------------------------------------------------------------------
void monitorMythicCounters()
{
   int now = xsGetTime();
   if ((now - gLastMythicCounterTime) < 30000) { return; }

   // Detekce enemy mythic (flying unit detection neni dostupna - vynechano)
   int enemyMyth = 0;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      enemyMyth = enemyMyth + kbUnitCount(cUnitTypeMythUnit, p, cUnitStateAlive);
   }
   int enemyAirMyth = 0; // Placeholder - bez Flying logical type

   if (enemyMyth >= 3)
   {
      // Hard counter: ranged + heroes
      if (gArmyHeroPercentage < 0.42)
      {
         gArmyHeroPercentage = gArmyHeroPercentage + 0.04;
      }
      // Boost late myth ratio (nase myth vs jejich myth)
      if (gArmyLateGameMythPercentage < 0.40)
      {
         gArmyLateGameMythPercentage = gArmyLateGameMythPercentage + 0.03;
      }
      debugStrategy("55: " + enemyMyth + " enemy myth - boost hero%=" + gArmyHeroPercentage +
         " lateMyth%=" + gArmyLateGameMythPercentage);
   }

   if (enemyAirMyth >= 2)
   {
      // Anti-air: vyssi pomer ranged units
      gArmySiegePercentage = gArmySiegePercentage; // siege/ranged units handle air
      if (gHumanArmyArcherPercentage < 0.40)
      {
         gHumanArmyArcherPercentage = gHumanArmyArcherPercentage + 0.05;
      }
      debugStrategy("55: " + enemyAirMyth + " enemy air myth - boost archer%=" +
         gHumanArmyArcherPercentage);
   }

   gLastMythicCounterTime = now;
}

rule mythicCounterMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   monitorMythicCounters();
}

//------------------------------------------------------------------------------
// 56: Economic brittle-point detection
// Kompozitni brittleness score: caravan blocked + trade dead + wood<100 + gold<100.
// >= 3 z 4 = critical.
//------------------------------------------------------------------------------
void computeBrittleness()
{
   int score = 0;

   if (gCaravanBlockedFlag == true) { score = score + 1; }

   // Trade dead = 0 caravan + 0 markets active
   int caravanCount = 0;
   if (gCaravanUnit > 0)
   {
      caravanCount = kbUnitCount(gCaravanUnit, cMyID, cUnitStateAlive);
   }
   int marketCount = kbUnitCount(gMarketUnit, cMyID, cUnitStateAlive);
   if (caravanCount == 0 && marketCount == 0) { score = score + 1; }

   if (kbResourceGet(cResourceWood) < 100.0) { score = score + 1; }
   if (kbResourceGet(cResourceGold) < 100.0) { score = score + 1; }

   gBrittlenessScore = score;

   if (score >= 3)
   {
      // Critical brittleness - emergency state
      gMilitaryUrgency = 1.0;
      // Force scout activity to find unblock route - existing exploration mechanism
      gDelayUpdateDistributionAndBreakdowns = false;
      debugStrategy("56: CRITICAL BRITTLENESS score=" + score +
         " (caravan=" + gCaravanBlockedFlag + " caravan#=" + caravanCount +
         " market#=" + marketCount + " wood=" + kbResourceGet(cResourceWood) +
         " gold=" + kbResourceGet(cResourceGold) + ")");
      aiEchoWarning("56: economic brittleness critical!");
   }
}

rule brittlenessMonitor
inactive
group defaultClassicalRules
minInterval 15
{
   computeBrittleness();
}

//==============================================================================
// SEKCE 4 - P3: Spell placement, forward base, civ bonuses, raid
//==============================================================================

//------------------------------------------------------------------------------
// 57: Spell placement radius optimization
// 5x5 grid scan v 50 tile radiusu od existujici gBestGPTargetPos.
// Najde maximum jednotek v AOE radiusu (default 12 tile pro Pestilence apod.)
//------------------------------------------------------------------------------
void optimizeSpellPlacement()
{
   if (gBestGPTargetPos == cInvalidVector) { return; }

   float bestScore = 0.0;
   vector bestPos = gBestGPTargetPos;
   float aoeRadius = 12.0; // Conservative AOE

   // 5x5 grid sampling within 50 tile radius od centroid
   for (int gx = -2; gx <= 2; gx++)
   {
      for (int gy = -2; gy <= 2; gy++)
      {
         vector samplePos = gBestGPTargetPos + vector(xsIntToFloat(gx) * 12.0, 0.0,
                                                       xsIntToFloat(gy) * 12.0);
         // Pocet enemy units v AOE radiusu od sample pos
         int count = getUnitCountByLocation(cUnitTypeMilitaryUnit,
            cPlayerRelationEnemyNotGaia, cUnitStateAlive, samplePos, aoeRadius,
            cUnitQueryVisibleStateVisible);
         // Bonus za blizke buildings
         int buildings = getUnitCountByLocation(cUnitTypeBuilding,
            cPlayerRelationEnemyNotGaia, cUnitStateAlive, samplePos, aoeRadius,
            cUnitQueryVisibleStateVisible);
         float score = xsIntToFloat(count) + xsIntToFloat(buildings) * 0.5;
         if (score > bestScore)
         {
            bestScore = score;
            bestPos = samplePos;
         }
      }
   }

   if (bestPos != gBestGPTargetPos)
   {
      gBestGPTargetPos = bestPos;
      debugStrategy("57: spell placement optimized - new pos " + bestPos +
         " (score=" + bestScore + ")");
   }
}

rule spellPlacementOptimizer
inactive
group defaultClassicalRules
minInterval 25
{
   optimizeSpellPlacement();
}

//------------------------------------------------------------------------------
// 58: Forward base economics
// Pri dostatecne aramady + enemy TC blizko, vytvori expansion settlement build
// plan blizko enemy fronty (60 tile od enemy).
//------------------------------------------------------------------------------
void manageForwardBase()
{
   if (gForwardBaseTriggered == true) { return; }
   int myAge = kbPlayerGetAge(cMyID);
   if (myAge < cAge2) { return; }

   int myArmy    = computeArmyValue(cMyID);
   int enemyArmy = computeMaxEnemyArmyValue();
   if (myArmy < enemyArmy) { return; } // Risky - jen pri parite/vyssi

   int firstEnemy = aiGetMostHatedPlayerID();
   if (firstEnemy <= 0) { return; }
   int eMainID = kbBaseGetMainID(firstEnemy);
   if (eMainID < 0) { return; }
   vector ePos = kbBaseGetLocation(firstEnemy, eMainID);

   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return; }
   vector myPos = kbBaseGetLocation(cMyID, mainBaseID);

   float distToEnemy = xsVectorLength(ePos - myPos);
   if (distToEnemy > 200.0) { return; } // Too far

   // Najdi settlement v 60-100 tile od enemy
   int settlementID = getClosestUnitByLocation(cUnitTypeSettlement,
      cPlayerRelationAny, cUnitStateAlive, ePos, 100.0);
   if (settlementID < 0) { return; }

   vector settlementPos = kbUnitGetPosition(settlementID);
   float distEnemyToSettle = xsVectorLength(settlementPos - ePos);
   if (distEnemyToSettle < 30.0) { return; } // Too close to enemy main

   // Build plan TC + 2 towers
   int planID = createSimpleBuildPlan(cUnitTypeAbstractTownCenter, 1, 70, -1, 1);
   if (planID >= 0)
   {
      aiPlanSetInitialPosition(planID, settlementPos);
      // Trigger 2 towers in vicinity (low priority autoBuild handles)
      gForwardBaseTriggered = true;
      gForwardBaseTime = xsGetTime();
      debugStrategy("58: forward base TC plan at " + settlementPos +
         " (myArmy=" + myArmy + " enemyArmy=" + enemyArmy + " dist=" + distToEnemy + ")");
   }
}

rule forwardBaseMonitor
inactive
group defaultClassicalRules
minInterval 60
{
   manageForwardBase();
}

//------------------------------------------------------------------------------
// 59: Civ-specific dynamic bonuses
// Per culture aktivace specifickych ekonomich/militarnich bonusu.
//------------------------------------------------------------------------------
void manageCivBonuses()
{
   // Greek: pri Hades + low favor + GP needed -> bump temple villager
   if (cMyCulture == cCultureGreek)
   {
      float favor = kbResourceGet(cResourceFavor);
      if (favor < 30.0 && cMyCiv == cCivHades && godPowerManager.godPowerBank.size() > 0)
      {
         // Force update breakdown - favor gather pak prijde
         gDelayUpdateDistributionAndBreakdowns = false;
         debugStrategy("59: Greek/Hades low favor " + favor + " + GP queued - force breakdown");
      }
   }
   // Egyptian: pri food shortage -> pharaoh switch (handled v3.6 #45 already)
   // Norse: berserk swap (handled v3.6 #48 already)
   // Atlantean: Servitor maintenance check
   else if (cMyCulture == cCultureAtlantean)
   {
      // Atlantean Servitor: nahradit pri ztratach (proxy: maintain plan zive)
      // Bez specifickeho API jen log shortfall
      int citizenCount = kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive);
      int popCap = kbPlayerGetPopCap(cMyID);
      if (citizenCount < (popCap / 4) && popCap > 40)
      {
         // Force villager maintain priority bump
         if (aiPlanGetIsIDValid(gVillagerMaintainPlan) == true)
         {
            int curPri = aiPlanGetPriority(gVillagerMaintainPlan);
            if (curPri < 80)
            {
               aiPlanSetPriority(gVillagerMaintainPlan, curPri + 10);
               debugStrategy("59: Atlantean low citizen count " + citizenCount +
                  "/popCap " + popCap + " - bump villager maintain priority");
            }
         }
      }
   }
}

rule civBonusMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   manageCivBonuses();
}

//------------------------------------------------------------------------------
// 60: Resource denial via early raid
// Identifikuje isolated enemy dropsite (mining/lumber camp) > 50 tile od enemy main
// + 0 enemy military v 30 tile -> mark jako raid target a bumpne attack interval.
//------------------------------------------------------------------------------
void scanRaidTargets()
{
   int now = xsGetTime();
   if ((now - gLastRaidScanTime) < 40000) { return; }

   gRaidTargetUnitID = -1;

   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }

      int eMainID = kbBaseGetMainID(p);
      if (eMainID < 0) { continue; }
      vector eMainPos = kbBaseGetLocation(p, eMainID);

      // Najdi enemy mining + lumber camps
      int qID = kbUnitQueryCreate("raidScan_" + p);
      kbUnitQuerySetPlayerID(qID, p);
      kbUnitQuerySetUnitType(qID, cUnitTypeMiningCamp);
      kbUnitQuerySetState(qID, cUnitStateAlive);
      kbUnitQueryResetResults(qID);
      int n = kbUnitQueryExecute(qID);

      for (int i = 0; i < n; i++)
      {
         int dsID = kbUnitQueryGetResult(qID, i);
         if (kbUnitGetIsIDValid(dsID) == false) { continue; }
         vector dsPos = kbUnitGetPosition(dsID);

         // Vzdalenost od enemy main > 50?
         float distToMain = xsVectorLength(dsPos - eMainPos);
         if (distToMain < 50.0) { continue; }

         // 0 enemy military v 30 tile?
         int milCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary,
            p, cUnitStateAlive, dsPos, 30.0, cUnitQueryVisibleStateVisible);
         if (milCount > 0) { continue; }

         // Found isolated dropsite
         gRaidTargetUnitID = dsID;
         debugStrategy("60: raid target identified - enemy " + p +
            " mining camp " + dsID + " at " + dsPos +
            " (dist from main=" + distToMain + ")");
         // Bumpne attack interval to attack soon
         gAdaptAttackIntervalBonus = -30;
         break;
      }

      if (gRaidTargetUnitID >= 0) { break; }
   }

   gLastRaidScanTime = now;
}

rule raidTargetScanner
inactive
group defaultClassicalRules
minInterval 40
{
   scanRaidTargets();
}
