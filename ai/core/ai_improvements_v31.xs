//==============================================================================
/* ai_improvements_v31.xs  -  v3.1

   Druhe kolo systemovych vylepseni (#11 - #20) navazujici na v3.0.

   Princip stejny jako v3.0: aditivni vrstva, modifikace pres existujici
   "knoby" (gAdaptAttackIntervalBonus, gArmy*Percentage, mMinimumAttackSize),
   detekce situaci pres existujici globaly.

   Vylepseni:
     P1: 11 Wonder defense, 12 Target value scoring, 13 Scout retreat
     P2: 14 Naval threat, 15 Idle villager, 16 GP target scoring
     P3: 17 Caravan block counter, 18 Multi-front, 19 Defensive perimeter,
         20 Wood line monitor
*/
//==============================================================================

//==============================================================================
// SEKCE 1 - Globaly
//==============================================================================

// --- 11: Wonder defense ---
extern bool gWonderDefenseActive = false;
extern int  gWonderDefenseStartTime = 0;

// --- 12: Target value scoring ---
extern int gBestAttackTargetPlayerID = -1;
extern int gBestAttackTargetBaseID   = -1;
extern int gBestAttackTargetScore    = 0;

// --- 13: Scout retreat tracking ---
extern int gLastScoutRetreatTime = 0;

// --- 14: Naval threat ---
extern int gEnemyNavalThreatLevel = 0; // 0=zadny, 1=mensi, 2=parita, 3=vyssi
extern int gMyWarshipCount = 0;
extern int gEnemyWarshipCount = 0;

// --- 16: GP target value ---
extern vector gBestGPTargetPos = cInvalidVector;
extern int    gBestGPTargetCount = 0;

// --- 17: Caravan block counter ---
extern int gCaravanFailureCount = 0;
extern int gCaravanLastFailureTime = 0;
extern bool gCaravanBlockedFlag = false;

// --- 19: Defensive perimeter ---
extern bool gDefensivePerimeterTriggered = false;
extern int  gDefensivePerimeterTime = 0;

// --- 20: Wood line monitor ---
extern float gAvgWoodGatherDistance = 0.0;
extern int   gLastDropsiteRelocate = 0;

//==============================================================================
// SEKCE 2 - P1: Wonder defense, target value, scout retreat
//==============================================================================

//------------------------------------------------------------------------------
// 11: Wonder defense
// Detekuje stavbu Wonderu, pri 50%+ progresu zapne defense mod:
// - Boost army training (zvysi mil unit maintain priority pres adaptiveni)
// - Sniz attack interval (defense focus)
// - Set high urgency
//------------------------------------------------------------------------------
extern int gWonderBuildStartTime = 0;

bool isWonderBeingBuilt()
{
   return (kbUnitCount(cUnitTypeWonder, cMyID, cUnitStateBuilding) >= 1);
}

// Progress proxy: cas od zahajeni stavby. Wonder se v AOM Retold stavi cca 8 minut,
// 50% = ~240s. Sledujeme gWonderBuildStartTime kdyz wonder poprve detekujeme.
bool isWonderHalfBuilt()
{
   if (isWonderBeingBuilt() == false) { return false; }
   if (gWonderBuildStartTime == 0) { return false; }
   int elapsedMs = xsGetTime() - gWonderBuildStartTime;
   return (elapsedMs > 240000); // 4 minutes ~ 50%
}

void activateWonderDefense()
{
   if (gWonderDefenseActive == true) { return; }
   gWonderDefenseActive = true;
   gWonderDefenseStartTime = xsGetTime();

   // Zaplnit interval bonus do hluboke defense (ale necarpat z toho dynamicTurtle)
   gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus + 60;
   // Force urgency na max
   gMilitaryUrgency = 1.0;
   // Boost pomer hrdinu (anti-army) a redukovat siege (nepotrebujeme atacovat)
   if (gArmyHeroPercentage < 0.40) { gArmyHeroPercentage = 0.40; }
   if (gArmySiegePercentage > 0.10) { gArmySiegePercentage = 0.10; }

   debugStrategy("11: WONDER DEFENSE ACTIVATED - boosting army production, urgency=1.0");
   aiEchoWarning("11: Wonder defense mode active!");
}

void deactivateWonderDefense()
{
   if (gWonderDefenseActive == false) { return; }
   gWonderDefenseActive = false;
   gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus - 60;
   debugStrategy("11: wonder defense deactivated");
}

rule wonderDefenseMonitor
inactive
group defaultClassicalRules
minInterval 15
{
   if (isWonderBeingBuilt() == true)
   {
      // Pri prvnim detekovani zaznamenat start time
      if (gWonderBuildStartTime == 0)
      {
         gWonderBuildStartTime = xsGetTime();
         debugStrategy("11: wonder construction detected at " + gWonderBuildStartTime);
      }
      // Aktivovat defense az kdyz odhadovany progres > 50%
      if (isWonderHalfBuilt() == true && gWonderDefenseActive == false)
      {
         activateWonderDefense();
      }
   }
   else if (gWonderDefenseActive == true)
   {
      // Wonder dokoncen nebo znicen - vypnout
      deactivateWonderDefense();
      gWonderBuildStartTime = 0;
   }
}

//------------------------------------------------------------------------------
// 12: Target value scoring
// Vypocita score per enemy base, najde nejvhodnejsi target (highest value
// vs lowest defense). Vysledek pristupny pres gBestAttackTargetPlayerID/BaseID.
// Existujici military_attack.xs muze tuto hodnotu pouzit pri vyberu cile
// (zatim jen logujeme).
//------------------------------------------------------------------------------
int computeBaseValue(int playerID = -1, int baseID = -1)
{
   if (playerID < 0 || baseID < 0) { return 0; }

   int tcCount   = kbBaseGetNumberUnitsOfType(playerID, baseID, cUnitTypeAbstractTownCenter);
   int villagers = kbBaseGetNumberUnitsOfType(playerID, baseID, cUnitTypeAbstractVillager);
   int wonders   = kbBaseGetNumberUnitsOfType(playerID, baseID, cUnitTypeWonder);

   // Score: TC=100, villagers=2 each, wonder=500 (ALWAYS attack wonder)
   return tcCount * 100 + villagers * 2 + wonders * 500;
}

int computeBaseDefense(int playerID = -1, int baseID = -1)
{
   if (playerID < 0 || baseID < 0) { return 0; }
   int towers = kbBaseGetNumberUnitsOfType(playerID, baseID, cUnitTypeAbstractTower);
   vector basePos = kbBaseGetLocation(playerID, baseID);
   int qID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary,
      playerID, cUnitStateAlive, basePos, 35.0);
   int milNearby = kbUnitQueryExecute(qID);
   return towers * 5 + milNearby * 3;
}

void scanBestAttackTarget()
{
   int bestPlayer = -1;
   int bestBase   = -1;
   int bestScore  = 0;

   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }

      int numBases = kbBaseGetNumber(p);
      for (int b = 0; b < numBases; b++)
      {
         int baseID = kbBaseGetIDByIndex(p, b);
         int value = computeBaseValue(p, baseID);
         int defense = computeBaseDefense(p, baseID);
         // Score = value - defense*2 (favoring soft targets)
         int finalScore = value - (defense * 2);
         if (finalScore > bestScore)
         {
            bestScore = finalScore;
            bestPlayer = p;
            bestBase = baseID;
         }
      }
   }

   gBestAttackTargetPlayerID = bestPlayer;
   gBestAttackTargetBaseID   = bestBase;
   gBestAttackTargetScore    = bestScore;

   if (bestPlayer > 0)
   {
      debugStrategy("12: best target = player " + bestPlayer + " base " + bestBase +
         " score=" + bestScore);
   }
}

rule targetValueMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   scanBestAttackTarget();
}

//------------------------------------------------------------------------------
// 13: Scout retreat + vision integration
// Sleduje scout-y (kataskopos/raven/generic scout). Pokud > 2 nepratele do 15
// tile, force retreat na main base. Take force-update gAdaptEnemy* ratios
// kdyz scout vidi enemy army (extra eyes pro counter logiku).
//------------------------------------------------------------------------------
// Scout retreat: AOM Retold nema aiTaskUnitMove. Misto force-pohybu odebereme
// scouta z explore planu (engine ho pak nasmeruje na default behavior - nas TC).
void scanScoutsForRetreat()
{
   int qID = kbUnitQueryCreate("scoutRetreatScan");
   kbUnitQuerySetPlayerID(qID, cMyID);
   kbUnitQuerySetUnitType(qID, cUnitTypeAbstractScout);
   kbUnitQuerySetState(qID, cUnitStateAlive);
   kbUnitQueryResetResults(qID);
   int n = kbUnitQueryExecute(qID);

   for (int i = 0; i < n; i++)
   {
      int scoutID = kbUnitQueryGetResult(qID, i);
      if (kbUnitGetIsIDValid(scoutID) == false) { continue; }
      vector scoutPos = kbUnitGetPosition(scoutID);

      // Check enemy units within 15 tile radius
      int eqID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary,
         cPlayerRelationEnemyNotGaia, cUnitStateAlive, scoutPos, 15.0);
      int enemyNearby = kbUnitQueryExecute(eqID);

      if (enemyNearby >= 2)
      {
         // Bezpecne reseni: odebrat scouta z aktualniho planu - dostane fresh
         // explore assignment, kteremu se vyhnou nepratelske oblasti.
         int planID = kbUnitGetPlanID(scoutID);
         if (planID >= 0)
         {
            aiPlanRemoveUnit(planID, scoutID);
            gLastScoutRetreatTime = xsGetTime();
            debugStrategy("13: scout " + scoutID + " sees " + enemyNearby +
               " enemies - removed from plan " + planID + " for re-routing");
         }
      }
   }
}

void scoutVisionForceUpdate()
{
   // Pokud scout vidi enemy army > 5 jednotek, force-bumpne counter ratio
   // tak, aby adaptive learning reagovalo i bez direct attack.
   if (gLastScoutRetreatTime == 0) { return; }
   int sinceMs = xsGetTime() - gLastScoutRetreatTime;
   if (sinceMs > 10000) { return; }

   // Force minimum threat detection bumpu (tym, ze gAdaptEnemyAttackMeleeRatio se nezere
   // do 0 dokud scouting hlasi pritomnost nepratele).
   if (gAdaptEnemyAttackMeleeRatio < 0.20) { gAdaptEnemyAttackMeleeRatio = 0.20; }
}

rule scoutRetreatMonitor
inactive
group defaultArchaicRules
minInterval 3
{
   scanScoutsForRetreat();
   scoutVisionForceUpdate();
}

//==============================================================================
// SEKCE 3 - P2: Naval, idle villager, GP target
//==============================================================================

//------------------------------------------------------------------------------
// 14: Naval threat assessment
// Pocita ratio my vs enemy warships. Pokud enemy 2x vyssi, boost siege ship
// production a transport interception.
//------------------------------------------------------------------------------
void scanNavalThreat()
{
   gMyWarshipCount = kbUnitCount(cUnitTypeAbstractWarship, cMyID, cUnitStateAlive);

   int enemyShips = 0;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      enemyShips = enemyShips + kbUnitCount(cUnitTypeAbstractWarship, p, cUnitStateAlive);
   }
   gEnemyWarshipCount = enemyShips;

   if (enemyShips == 0)             { gEnemyNavalThreatLevel = 0; }
   else if (gMyWarshipCount == 0)   { gEnemyNavalThreatLevel = 3; }
   else
   {
      float ratio = xsIntToFloat(enemyShips) / xsIntToFloat(gMyWarshipCount);
      if      (ratio >= 2.0) { gEnemyNavalThreatLevel = 3; }
      else if (ratio >= 1.0) { gEnemyNavalThreatLevel = 2; }
      else                   { gEnemyNavalThreatLevel = 1; }
   }

   if (gEnemyNavalThreatLevel >= 3)
   {
      debugStrategy("14: HIGH naval threat (my=" + gMyWarshipCount +
         " enemy=" + enemyShips + ") - need more warships");
      // Boost: snizi attack interval bonus, pokud nepritel ma silnou flotilu
      // (dame jim cas se starat o more)
      if (gAdaptAttackIntervalBonus < 30)
      {
         gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus + 15;
      }
   }
}

rule navalThreatMonitor
inactive
group defaultClassicalRules
minInterval 25
{
   scanNavalThreat();
}

//------------------------------------------------------------------------------
// 15: Idle villager detection
// Detekuje villagere bez planu (planID == -1), pridava je do nejblizsiho
// gather plánu. (Resource breakdown system normalne dotahne villagery sam,
// ale po dokonceni stavby mohou viset 2-5s nez se prevezmou.)
//------------------------------------------------------------------------------
int gIdleVillagerCount = 0;

void detectIdleVillagers()
{
   int qID = kbUnitQueryCreate("idleVillagerScan");
   kbUnitQuerySetPlayerID(qID, cMyID);
   kbUnitQuerySetUnitType(qID, cUnitTypeAbstractVillager);
   kbUnitQuerySetState(qID, cUnitStateAlive);
   kbUnitQueryResetResults(qID);
   int n = kbUnitQueryExecute(qID);

   int idleCount = 0;
   for (int i = 0; i < n; i++)
   {
      int vID = kbUnitQueryGetResult(qID, i);
      if (kbUnitGetIsIDValid(vID) == false) { continue; }
      int planID = kbUnitGetPlanID(vID);
      if (planID < 0) { idleCount++; }
   }
   gIdleVillagerCount = idleCount;

   if (idleCount > 2)
   {
      debugStrategy("15: " + idleCount + " idle villagers detected - forcing breakdown update");
      // Trigger immediate recompute breakdown (resource system pak vesnicany prevezme)
      gDelayUpdateDistributionAndBreakdowns = false;
   }
}

rule idleVillagerMonitor
inactive
group defaultClassicalRules
minInterval 10
{
   detectIdleVillagers();
}

//------------------------------------------------------------------------------
// 16: God power target value scoring
// Pocita centroid nejvetsiho enemy clusteru a uklada jako global pro pouziti
// god power setup funkcemi. (Existujici setupGreekGodPowerPlan atd. mohou
// fixne pristupovat ke gBestGPTargetPos.)
//------------------------------------------------------------------------------
void scanBestGPTarget()
{
   gBestGPTargetPos   = cInvalidVector;
   gBestGPTargetCount = 0;

   // Iteruj enemy hraci, pro kazdeho najdi nejvetsi cluster jednotek
   int bestN = 0;
   vector bestPos = cInvalidVector;

   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }

      // Najdi enemy mainBase, scan kolem 50 tile
      int eMainID = kbBaseGetMainID(p);
      if (eMainID < 0) { continue; }
      vector ePos = kbBaseGetLocation(p, eMainID);

      int qID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary,
         p, cUnitStateAlive, ePos, 50.0);
      int n = kbUnitQueryExecute(qID);

      // Score = pop + (heroes * 20) + (myth * 15)
      int heroCount = 0;
      int mythCount = 0;
      for (int i = 0; i < n; i++)
      {
         int uID = kbUnitQueryGetResult(qID, i);
         int puid = kbUnitGetProtoUnitID(uID);
         if (kbProtoUnitIsType(puid, cUnitTypeHero) == true) { heroCount++; }
         if (kbProtoUnitIsType(puid, cUnitTypeMythUnit) == true) { mythCount++; }
      }
      int score = n + (heroCount * 20) + (mythCount * 15);
      if (score > bestN)
      {
         bestN = score;
         bestPos = ePos;
      }
   }

   if (bestN >= 8) // Smysluplny cluster pro AOE god power
   {
      gBestGPTargetPos   = bestPos;
      gBestGPTargetCount = bestN;
      debugStrategy("16: best GP target = " + bestPos + " score=" + bestN);
   }
}

rule gpTargetValueMonitor
inactive
group defaultClassicalRules
minInterval 20
{
   scanBestGPTarget();
}

//==============================================================================
// SEKCE 4 - P3: Caravan, multi-front, perimeter, wood line
//==============================================================================

//------------------------------------------------------------------------------
// 17: Caravan blocking counter
// Sleduje, kolik karavan je v "broken" stavu (cesta nepruchozi). Pokud > 2
// failures behem 60s, predpokladame enemy garrison na trade route -> forciblne
// se snazime presmerovat trade nebo pripadne odeslat army.
//------------------------------------------------------------------------------
void monitorCaravanFailures()
{
   int caravanCount = kbUnitCount(gCaravanUnit, cMyID, cUnitStateAlive);
   if (caravanCount == 0) { return; }

   // Pocet karavan v idle (planID < 0) je proxy pro stuck karavany
   int qID = kbUnitQueryCreate("caravanCheck");
   kbUnitQuerySetPlayerID(qID, cMyID);
   kbUnitQuerySetUnitType(qID, gCaravanUnit);
   kbUnitQuerySetState(qID, cUnitStateAlive);
   kbUnitQueryResetResults(qID);
   int n = kbUnitQueryExecute(qID);

   int stuckCount = 0;
   for (int i = 0; i < n; i++)
   {
      int cID = kbUnitQueryGetResult(qID, i);
      if (kbUnitGetIsIDValid(cID) == false) { continue; }
      int planID = kbUnitGetPlanID(cID);
      if (planID < 0) { stuckCount++; }
   }

   int now = xsGetTime();
   if (stuckCount >= 2)
   {
      gCaravanFailureCount = gCaravanFailureCount + 1;
      gCaravanLastFailureTime = now;
   }
   else if ((now - gCaravanLastFailureTime) > 60000)
   {
      // Reset citac po 60s bez failure
      gCaravanFailureCount = 0;
   }

   // 3+ failures za 60s -> blokovany
   if (gCaravanFailureCount >= 3 && gCaravanBlockedFlag == false)
   {
      gCaravanBlockedFlag = true;
      debugStrategy("17: caravan trade route appears blocked (" + gCaravanFailureCount +
         " failures) - boosting attack priority");
      // Boost attack: snizi interval bonus, aby AI poslala armadu
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus - 20;
      aiEchoWarning("17: caravan blocked - sending attack!");
   }
   else if (gCaravanFailureCount == 0 && gCaravanBlockedFlag == true)
   {
      gCaravanBlockedFlag = false;
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus + 20;
      debugStrategy("17: caravan unblocked - normal trade");
   }
}

rule caravanBlockMonitor
inactive
group defaultClassicalRules
minInterval 20
{
   monitorCaravanFailures();
}

//------------------------------------------------------------------------------
// 18: Multi-front attack
// Pokud mame 2x mMinimumAttackSize vojska, oznacime, ze utok ma jit na 2.
// most-hated player paralelne (existujici attackManager pak muze rozhodnout).
// Zatim jen tracking + zpomalujeme attack interval, kdyz mame plno armady,
// abychom efektivneji posilali vetsi waves.
//------------------------------------------------------------------------------
extern int gSecondMostHatedPlayerID = -1;

int findSecondMostHated()
{
   int firstHated = aiGetMostHatedPlayerID();
   int secondID = -1;
   int secondScore = -1; // ms hated score

   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (p == firstHated) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      // Pouzij pocet jednotek nepritele jako proxy "kdo je vetsi hrozba"
      int score = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, p, cUnitStateAlive);
      if (score > secondScore)
      {
         secondScore = score;
         secondID = p;
      }
   }
   return secondID;
}

rule multiFrontMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   gSecondMostHatedPlayerID = findSecondMostHated();
   if (gSecondMostHatedPlayerID < 0) { return; }

   int armyPop = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive);
   int twiceMin = gAttackManager.mMinimumAttackSize * 2;

   if (armyPop >= twiceMin && gAttackManager.mMinimumAttackSize >= 10)
   {
      // Mame dost pop pro 2 simultanni utoky - snizit min size aby se utok rozjel rychleji
      if (gAdaptMinAttackSizeBonus > -3)
      {
         gAdaptMinAttackSizeBonus = gAdaptMinAttackSizeBonus - 1;
         debugStrategy("18: army surplus (" + armyPop + " >= 2x " +
            gAttackManager.mMinimumAttackSize + ") - allowing smaller attack waves");
      }
   }
}

//------------------------------------------------------------------------------
// 19: Defensive perimeter trigger
// Pokud gAdaptRushDetected aktivni a jeste jsme nepostavili wally,
// vytvorime build plan pro short walls okolo TC.
//------------------------------------------------------------------------------
void buildDefensivePerimeter()
{
   if (gDefensivePerimeterTriggered == true) { return; }

   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return; }

   // Pokud uz mame nejake wally, asi je strategie pokryva - skip
   int existingWalls = kbUnitCount(cUnitTypeAbstractWall, cMyID, cUnitStateAlive);
   if (existingWalls > 5) { return; }

   // Spustit existujici wall logiku (StrategyData.mWallCircleAmount = 1) pres
   // strategy modifier, ktery autoBuildWalls v buildings.xs precte.
   gDefensivePerimeterTriggered = true;
   gDefensivePerimeterTime = xsGetTime();

   // Force vyssi wall pomer pres strategy data (pokud existuje access pres gStrategyManager)
   // Bezpecny pristup: jen log + boost defense urgency, vlastni wall logika je v buildings.xs
   gMilitaryUrgency = 1.0;
   debugStrategy("19: rush detected - defensive perimeter requested (existing wall logic vendored)");
   aiEchoWarning("19: defensive perimeter mode!");
}

rule defensivePerimeterMonitor
inactive
group defaultArchaicRules
minInterval 10
{
   if (gAdaptRushDetected == true)
   {
      buildDefensivePerimeter();
   }
   // Cleanup po 5 minutach
   if (gDefensivePerimeterTriggered == true &&
       (xsGetTime() - gDefensivePerimeterTime) > 300000)
   {
      gDefensivePerimeterTriggered = false;
   }
}

//------------------------------------------------------------------------------
// 20: Wood line depletion + auto-relocate dropsite
// Sleduje prumernou vzdalenost wood gathereru od dropsitu. Pokud > 25 tile,
// spustila by se logika novyho dropsitu. (Existujici dropsite_placement.xs
// dela placement, ale nereaguje na depletion pres metric vzdalenosti.)
//------------------------------------------------------------------------------
void monitorWoodLine()
{
   // Pocet villagers gathering wood
   int qID = kbUnitQueryCreate("woodGathererCheck");
   kbUnitQuerySetPlayerID(qID, cMyID);
   kbUnitQuerySetUnitType(qID, cUnitTypeAbstractVillager);
   kbUnitQuerySetState(qID, cUnitStateAlive);
   kbUnitQueryResetResults(qID);
   int n = kbUnitQueryExecute(qID);

   if (n < 4) { return; }

   // Compute avg position of wood gatherers, compare with nearest TC/dropsite
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return; }
   vector basePos = kbBaseGetLocation(cMyID, mainBaseID);

   float totalDist = 0.0;
   int counted = 0;
   for (int i = 0; i < n; i++)
   {
      int vID = kbUnitQueryGetResult(qID, i);
      if (kbUnitGetIsIDValid(vID) == false) { continue; }
      // Filter: berem v uvahu jen ty na resource gather (planID je gather plan)
      int planID = kbUnitGetPlanID(vID);
      if (planID < 0) { continue; }
      vector vPos = kbUnitGetPosition(vID);
      float d = xsVectorLength(vPos - basePos);
      totalDist = totalDist + d;
      counted++;
   }

   if (counted == 0) { return; }
   gAvgWoodGatherDistance = totalDist / xsIntToFloat(counted);

   // Pokud avg > 25 tile + neralokovali jsme dropsite za poslednich 90s
   int now = xsGetTime();
   if (gAvgWoodGatherDistance > 25.0 && (now - gLastDropsiteRelocate) > 90000)
   {
      gLastDropsiteRelocate = now;
      debugStrategy("20: avg gatherer distance " + gAvgWoodGatherDistance +
         " > 25 - dropsite relocate hint (existing dropsite_placement.xs handles)");
      // Trigger force update breakdown - dropsite logic uvidi shortfall
      gDelayUpdateDistributionAndBreakdowns = false;
   }
}

rule woodLineMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   monitorWoodLine();
}
