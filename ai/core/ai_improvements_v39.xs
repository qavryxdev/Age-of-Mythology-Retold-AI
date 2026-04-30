//==============================================================================
/* ai_improvements_v39.xs  -  v3.9 - KOGNICE A FEEDBACK LOOPS

   Osme kolo - 10 vylepseni vyssi urovne kognice nad 70 predchozimi.

   P1: 71 Risk-reward EV, 72 Plan abandonment, 73 Threshold smoothing
   P2: 74 Honeypot detect, 75 Resource memory, 76 Multi-sector threat,
       77 Pop shrink rebuild
   P3: 78 Idle hero realloc, 79 GP burst gaming, 80 Combo synergy
*/
//==============================================================================

//==============================================================================
// SEKCE 1 - Globaly
//==============================================================================

// --- 71: Risk-reward ---
extern float gRollingExpectedValue = 0.0;
extern int gLastEVCheckTime = 0;

// --- 72: Plan abandonment ---
extern int[] gAttackFailureCount = default;
extern int gLastTargetSwitch = 0;

// --- 74: Honeypot ---
extern int gLastHoneypotCheck = 0;
extern bool gHoneypotDetected = false;

// --- 75: Resource memory ---
extern vector[] gResourceMemoryPositions = default;
extern int[]    gResourceMemoryTypes = default;
extern int[]    gResourceMemoryLastSeen = default;
extern int gLastResourceMemoryUpdate = 0;

// --- 76: Multi-sector threat ---
extern float gThreatN = 0.0;
extern float gThreatE = 0.0;
extern float gThreatS = 0.0;
extern float gThreatW = 0.0;
extern int gLastSectorThreatTime = 0;

// --- 77: Pop shrink ---
extern int gLastPopCap = 0;
extern int gPopShrinkDetectedTime = 0;

// --- 78: Idle hero ---
extern int gLastIdleHeroCheck = 0;

// --- 79: GP burst gaming ---
extern int gGPBurstWindow = 0;

// --- 80: Combo synergy ---
extern int gLastComboCheck = 0;
extern bool gEnemyHasMythCombo = false;

//==============================================================================
// SEKCE 2 - P1: Risk-reward, plan abandonment, threshold smoothing
//==============================================================================

//------------------------------------------------------------------------------
// 71: Risk-reward expected value tracking
// Pred trigger utoku spocitej EV. Aktualizuj rolling average podle minulych
// vysledku.
//------------------------------------------------------------------------------
void updateExpectedValue()
{
   // Z adaptive_learning vime gAdaptLastWaveLossPop, gAdaptAvgLossRate
   // EV = (estimovany enemy loss * 1.0) - (myLoss * 1.5) * successProbability
   if (gAdaptAttackLaunched < 2) { return; }

   float successRate = 0.0;
   if (gAdaptAttackLaunched > 0)
   {
      successRate = xsIntToFloat(gAdaptAttackSucceeded) / xsIntToFloat(gAdaptAttackLaunched);
   }

   // Estimace per-wave (aproximace)
   float estimatedEnemyLoss = xsIntToFloat(gAdaptAttackEnemyBuildingsAtStart) * 0.3 * successRate;
   float estimatedMyLoss = xsIntToFloat(gAdaptLastWaveLossPop);

   float currentEV = (estimatedEnemyLoss * 1.0) - (estimatedMyLoss * 1.5) * successRate;
   // Rolling average (70/30)
   gRollingExpectedValue = (gRollingExpectedValue * 0.7) + (currentEV * 0.3);

   // Pri velmi negativnim EV bumpne attack interval
   if (gRollingExpectedValue < -10.0)
   {
      if (gAdaptAttackIntervalBonus < 60)
      {
         gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus + 15;
         debugStrategy("71: negative rolling EV " + gRollingExpectedValue +
            " - increased attack interval bonus to " + gAdaptAttackIntervalBonus);
      }
   }
   else if (gRollingExpectedValue > 5.0)
   {
      if (gAdaptAttackIntervalBonus > -30)
      {
         gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus - 5;
      }
   }
}

rule expectedValueMonitor
inactive
group defaultClassicalRules
minInterval 45
{
   updateExpectedValue();
}

//------------------------------------------------------------------------------
// 72: Plan abandonment after repeat failure
// Per-enemy failure counter. Po 3 failures switch most-hated.
//------------------------------------------------------------------------------
void monitorAttackFailures()
{
   // Detect attack failure z gAdaptAttackFailed delta
   static int lastAttackFailedCount = 0;
   int currentFailed = gAdaptAttackFailed;

   if (currentFailed > lastAttackFailedCount)
   {
      // Increment failure pre current target
      int target = gAdaptTrackTargetPlayerID;
      if (target > 0)
      {
         if (gAttackFailureCount.size() <= cNumberPlayers)
         {
            gAttackFailureCount.resize(cNumberPlayers + 1, 0);
         }
         gAttackFailureCount[target] = gAttackFailureCount[target] + 1;

         if (gAttackFailureCount[target] >= 3)
         {
            // Switch to alternative most-hated
            int altTarget = -1;
            int altScore = 0;
            for (int p = 1; p <= cNumberPlayers; p++)
            {
               if (p == cMyID || p == target) { continue; }
               if (kbPlayerIsEnemy(p) == false) { continue; }
               if (kbPlayerHasLost(p)) { continue; }
               int score = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, p, cUnitStateAlive);
               if (score > altScore)
               {
                  altScore = score;
                  altTarget = p;
               }
            }
            if (altTarget > 0)
            {
               aiSetMostHatedPlayerID(altTarget);
               gLastTargetSwitch = xsGetTime();
               // Reset failure counter pro povodneho targetu
               gAttackFailureCount[target] = 0;
               debugStrategy("72: 3 fails vs player " + target +
                  " - switching most-hated to " + altTarget);
            }
         }
      }
   }
   lastAttackFailedCount = currentFailed;
}

rule planAbandonmentMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   monitorAttackFailures();
}

//------------------------------------------------------------------------------
// 73: Threshold smoothing (linear ramp namisto hard cutoff)
// Aplikuje smooth ramp na klicove ratio thresholds. Misto if(ratio>0.40) bonus
// se pouzije linearne interpolovany bonus.
//------------------------------------------------------------------------------
float smoothRamp(float value = 0.0, float lowEdge = 0.30, float highEdge = 0.50)
{
   // Returns 0.0 below lowEdge, 1.0 above highEdge, smooth linear in between
   if (value <= lowEdge)  { return 0.0; }
   if (value >= highEdge) { return 1.0; }
   return (value - lowEdge) / (highEdge - lowEdge);
}

void applySmoothedThresholds()
{
   // Pomalu posouvat hero% smerem k cilove hodnote dle ratio (smooth)
   float archerRamp = smoothRamp(gAdaptEnemyAttackRangedRatio, 0.30, 0.50);
   float mythRamp   = smoothRamp(gAdaptEnemyAttackMythRatio, 0.20, 0.40);
   float siegeRamp  = smoothRamp(gAdaptEnemyAttackSiegeRatio, 0.15, 0.35);

   float targetHero = 0.30 + (archerRamp * 0.05) + (mythRamp * 0.08);
   float targetSiege = 0.15 + (siegeRamp * 0.10);

   if (targetHero > 0.45) { targetHero = 0.45; }
   if (targetSiege > 0.30) { targetSiege = 0.30; }

   // Posouvat smerem k target maly krok (eased)
   if (gArmyHeroPercentage < targetHero - 0.01)
   {
      gArmyHeroPercentage = gArmyHeroPercentage + 0.01;
   }
   else if (gArmyHeroPercentage > targetHero + 0.01)
   {
      gArmyHeroPercentage = gArmyHeroPercentage - 0.01;
   }
}

rule smoothThresholdMonitor
inactive
group defaultClassicalRules
minInterval 25
{
   applySmoothedThresholds();
}

//==============================================================================
// SEKCE 3 - P2: Honeypot, memory, sectors, pop shrink
//==============================================================================

//------------------------------------------------------------------------------
// 74: Honeypot detection
// Pri detekci enemy unit u TC zkontroluje support v 40 tile. Pokud 1 unit
// + 0 v 40 tile = bait, ignore panic.
//------------------------------------------------------------------------------
void checkHoneypot()
{
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return; }
   vector basePos = kbBaseGetLocation(cMyID, mainBaseID);

   // Closest enemy do 25 tile
   int closeQ = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary,
      cPlayerRelationEnemyNotGaia, cUnitStateAlive, basePos, 25.0);
   int closeN = kbUnitQueryExecute(closeQ);

   if (closeN < 1 || closeN > 3)
   {
      // 0 = no threat, 4+ = real attack (not honeypot)
      gHoneypotDetected = false;
      return;
   }

   // 1-3 enemies near. Check support force in 40 tile
   int wideQ = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary,
      cPlayerRelationEnemyNotGaia, cUnitStateAlive, basePos, 40.0);
   int wideN = kbUnitQueryExecute(wideQ);

   // Support force = wideN - closeN
   int support = wideN - closeN;
   if (support == 0 && closeN <= 2)
   {
      // Honeypot bait
      if (gHoneypotDetected == false)
      {
         gHoneypotDetected = true;
         debugStrategy("74: honeypot detected - " + closeN + " bait + 0 support, NO panic");
         // Suprese panic
         gDefenseReflexPanic = false;
      }
   }
   else
   {
      gHoneypotDetected = false;
   }
}

rule honeypotMonitor
inactive
group defaultClassicalRules
minInterval 5
{
   checkHoneypot();
}

//------------------------------------------------------------------------------
// 75: Resource location memory beyond fog
// Pri startu scan a stredne jednou za 60s aktualizuje gResourceMemory*. Pri
// scout planu prefer pamet uzemi (pokud confidence > 0.3).
//------------------------------------------------------------------------------
void updateResourceMemory()
{
   int now = xsGetTime();

   // Scan visible gold mines
   int qID = kbUnitQueryCreate("resourceMemoryScan");
   kbUnitQuerySetUnitType(qID, cUnitTypeGoldResource);
   kbUnitQuerySetState(qID, cUnitStateAlive);
   kbUnitQuerySetVisibleState(qID, cUnitQueryVisibleStateVisible);
   kbUnitQueryResetResults(qID);
   int n = kbUnitQueryExecute(qID);

   for (int i = 0; i < n; i++)
   {
      int rID = kbUnitQueryGetResult(qID, i);
      if (kbUnitGetIsIDValid(rID) == false) { continue; }
      vector rPos = kbUnitGetPosition(rID);

      // Check zda uz neni v memory
      bool found = false;
      for (int j = 0; j < gResourceMemoryPositions.size(); j++)
      {
         vector mPos = gResourceMemoryPositions[j];
         float dist = xsVectorLength(rPos - mPos);
         if (dist < 5.0)
         {
            gResourceMemoryLastSeen[j] = now;
            found = true;
            break;
         }
      }
      if (found == false)
      {
         gResourceMemoryPositions.add(rPos);
         gResourceMemoryTypes.add(cUnitTypeGoldResource);
         gResourceMemoryLastSeen.add(now);
         debugStrategy("75: new resource memorized at " + rPos);
      }
   }

   gLastResourceMemoryUpdate = now;
}

rule resourceMemoryMonitor
inactive
group defaultArchaicRules
minInterval 60
{
   updateResourceMemory();
}

//------------------------------------------------------------------------------
// 76: Multi-zone threat aggregation
// XS nema xsVectorGetX/Z accessory pro decompose delta vektoru, takze N/E/S/W
// sectory nelze spolehlive identifikovat. Misto toho mereni threat ve dvou
// koncentrickych zonach (close 25 tile, mid 80 tile) - detect splitting attacks.
//------------------------------------------------------------------------------
void computeSectorThreats()
{
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return; }
   vector basePos = kbBaseGetLocation(cMyID, mainBaseID);

   int qClose = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary,
      cPlayerRelationEnemyNotGaia, cUnitStateAlive, basePos, 25.0);
   int closeN = kbUnitQueryExecute(qClose);

   int qMid = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary,
      cPlayerRelationEnemyNotGaia, cUnitStateAlive, basePos, 80.0);
   int midN = kbUnitQueryExecute(qMid);

   // Inner zone is "main attack", outer-but-not-inner = "second front incoming"
   gThreatN = xsIntToFloat(closeN);
   gThreatE = xsIntToFloat(midN - closeN);

   // Multi-front threshold: aspon 5 enemy v close + aspon 5 enemy v outer = 2 fronty
   if (closeN >= 5 && (midN - closeN) >= 5)
   {
      gMilitaryUrgency = 1.0;
      debugStrategy("76: multi-zone threat: close=" + closeN +
         " outer=" + (midN - closeN) + " - 2 fronts likely, max urgency");
   }
}

rule sectorThreatMonitor
inactive
group defaultClassicalRules
minInterval 12
{
   computeSectorThreats();
}

//------------------------------------------------------------------------------
// 77: Population shrink responsive rebuild
// Detekuje pokles popCap (zniceny dum). Force house build priority bump.
//------------------------------------------------------------------------------
void detectPopShrink()
{
   int curPopCap = kbPlayerGetPopCap(cMyID);
   int now = xsGetTime();

   if (gLastPopCap == 0)
   {
      gLastPopCap = curPopCap;
      return;
   }

   int drop = gLastPopCap - curPopCap;
   if (drop >= 5)
   {
      gPopShrinkDetectedTime = now;
      // Force house build plan (gHouseUnit existing)
      if (gHouseUnit > 0)
      {
         int planID = createSimpleBuildPlan(gHouseUnit, 1, 80, -1, 1);
         if (planID >= 0)
         {
            debugStrategy("77: pop cap drop " + drop + " (" + gLastPopCap + " -> " +
               curPopCap + ") - emergency house build at priority 80");
         }
      }
      // Force breakdown update aby villager train resumes
      gDelayUpdateDistributionAndBreakdowns = false;
   }
   gLastPopCap = curPopCap;
}

rule popShrinkMonitor
inactive
group defaultClassicalRules
minInterval 8
{
   detectPopShrink();
}

//==============================================================================
// SEKCE 4 - P3: Idle hero realloc, GP burst, combo synergy
//==============================================================================

//------------------------------------------------------------------------------
// 78: Idle hero detection + reallocation
// Heroes mimo any plan -> task na nejvyssi sektor threat (z #76).
//------------------------------------------------------------------------------
void reallocateIdleHeroes()
{
   int qID = kbUnitQueryCreate("idleHeroScan");
   kbUnitQuerySetPlayerID(qID, cMyID);
   kbUnitQuerySetUnitType(qID, cUnitTypeHero);
   kbUnitQuerySetState(qID, cUnitStateAlive);
   kbUnitQueryResetResults(qID);
   int n = kbUnitQueryExecute(qID);

   int idleCount = 0;
   for (int i = 0; i < n; i++)
   {
      int hID = kbUnitQueryGetResult(qID, i);
      if (kbUnitGetIsIDValid(hID) == false) { continue; }
      int planID = kbUnitGetPlanID(hID);
      if (planID < 0) { idleCount++; }
   }

   if (idleCount > 0)
   {
      debugStrategy("78: " + idleCount + " idle heroes detected - hint to defend plan");
      // Force plan reassignment - pridej do gPrimaryLandDefendPlan pokud exists
      if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == true)
      {
         for (int j = 0; j < n; j++)
         {
            int hID = kbUnitQueryGetResult(qID, j);
            if (kbUnitGetIsIDValid(hID) == false) { continue; }
            if (kbUnitGetPlanID(hID) < 0)
            {
               aiPlanAddUnit(gPrimaryLandDefendPlan, hID);
            }
         }
      }
   }
}

rule idleHeroMonitor
inactive
group defaultClassicalRules
minInterval 15
{
   reallocateIdleHeroes();
}

//------------------------------------------------------------------------------
// 79: GP cooldown burst gaming
// Pri 2+ GP v bank odlozit cast 30s aby se akumulovaly multiple ready powers.
// (Realisticky engine GP bank ma "ready" status - pokud >=2 ready a posledni
// burst byl > 60s zpet, force flush; jinak counter for next interval.)
//------------------------------------------------------------------------------
void manageGPBurst()
{
   int now = xsGetTime();
   int bankSize = godPowerManager.godPowerBank.size();
   if (bankSize < 2) { return; }

   // Pri velkem threat (loss > 0.5 nebo emergency) immediate flush, zadny burst delay
   if (gAdaptAvgLossRate > 0.50 || gEmergencyDefenseActive == true)
   {
      godPowerManager.useUnusedGodPowers();
      gGPBurstWindow = 0;
      debugStrategy("79: GP burst - immediate flush (high threat)");
      return;
   }

   // Nizky threat - delay window: pokud bank>=2 a checking 60s, flush vsechno najednou
   if (gGPBurstWindow == 0)
   {
      gGPBurstWindow = now;
      return;
   }

   int sinceWindow = now - gGPBurstWindow;
   if (sinceWindow > 60000)
   {
      // 60s burst window expired - flush
      godPowerManager.useUnusedGodPowers();
      debugStrategy("79: GP burst window expired (" + bankSize + " powers, " +
         sinceWindow + "ms wait) - flush");
      gGPBurstWindow = 0;
   }
}

rule gpBurstMonitor
inactive
group defaultClassicalRules
minInterval 20
{
   manageGPBurst();
}

//------------------------------------------------------------------------------
// 80: Combo unit synergy detection
// Pri detekci enemy hero + enemy myth >= 5 v armade aktivuje combo counter:
// vyssi hero + myth pomer pro nas (1.5x weight).
//------------------------------------------------------------------------------
void detectComboSynergy()
{
   int now = xsGetTime();
   if ((now - gLastComboCheck) < 30000) { return; }

   bool comboDetected = false;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }

      int eHeroes = kbUnitCount(cUnitTypeHero, p, cUnitStateAlive);
      int eMyth = kbUnitCount(cUnitTypeMythUnit, p, cUnitStateAlive);

      if (eHeroes >= 1 && eMyth >= 5)
      {
         comboDetected = true;
         break;
      }
   }

   if (comboDetected == true)
   {
      if (gEnemyHasMythCombo == false)
      {
         gEnemyHasMythCombo = true;
         // 1.5x weight on counters
         if (gArmyHeroPercentage < 0.45)
         {
            gArmyHeroPercentage = gArmyHeroPercentage + 0.05;
         }
         if (gArmyLateGameMythPercentage < 0.45)
         {
            gArmyLateGameMythPercentage = gArmyLateGameMythPercentage + 0.05;
         }
         debugStrategy("80: ENEMY COMBO (hero + 5+ myth) detected - boost hero/myth%");
      }
   }
   else if (gEnemyHasMythCombo == true)
   {
      gEnemyHasMythCombo = false;
   }

   gLastComboCheck = now;
}

rule comboSynergyMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   detectComboSynergy();
}
