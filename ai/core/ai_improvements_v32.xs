//==============================================================================
/* ai_improvements_v32.xs  -  v3.2

   Treti kolo systemovych vylepseni (#21 - #30) navazujici na v3.1.

   Princip stejny: aditivni vrstva, modifikace pres existujici knoby + runtime
   modifikace plánu pres aiPlanSet*.

   Vylepseni:
     P1: 21 Anti-myth focus, 22 Resource overflow, 23 Wall breach detection
     P2: 24 Settlement expansion, 25 Auto-trade rhythm, 26 Fishing rebuild,
         27 Titan offensive/defensive
     P3: 28 Hero relic competition, 29 Garrison on attack, 30 Enemy god reactions
*/
//==============================================================================

//==============================================================================
// SEKCE 1 - Globaly
//==============================================================================

// --- 21: Anti-myth focus ---
extern int gAntiMythLastApplyTime = 0;

// --- 22: Resource overflow ---
extern int gLastOverflowFarmTime = 0;
extern int gLastOverflowWallTime = 0;

// --- 23: Wall breach detection ---
extern int gLastWallCount = 0;
extern int gLastWallCheckTime = 0;
extern bool gWallBreachActive = false;
extern int  gWallBreachStartTime = 0;

// --- 24: Settlement expansion reactivity ---
extern int gLastEnemyTCCount = 0;
extern int gLastEnemyTCCheckTime = 0;

// --- 25: Auto-trade rhythm ---
extern float gLastFood = 0.0;
extern float gLastWood = 0.0;
extern float gLastGold = 0.0;
extern int   gLastTradeCheckTime = 0;
extern float gFoodVelocity = 0.0;
extern float gWoodVelocity = 0.0;
extern float gGoldVelocity = 0.0;

// --- 26: Fishing fleet rebuild ---
extern int gLastFishingBoatCount = 0;
extern int gFishingLossTriggerTime = 0;

// --- 27: Titan strategy ---
extern bool gTitanOffensiveMode = false;

// --- 28: Hero relic competition ---
extern int gLastRelicScanTime = 0;

// --- 29: Garrison on attack ---
extern int gLastGarrisonTime = 0;

// --- 30: Enemy god reactions ---
extern int gEnemyMainCiv = -1;
extern bool gEnemyCivAdaptApplied = false;

//==============================================================================
// SEKCE 2 - P1: Anti-myth focus, overflow, wall breach
//==============================================================================

//------------------------------------------------------------------------------
// 21: Anti-myth focus fire
// Pri kazdem aktivnim attack planu prepisem cAttackPlanTargetUnitTypes tak,
// aby Myth/Hero byly priorita 0/1 PRED Building/MilitaryUnit. Ovlivni runtime
// targeting jednotek v boji - heroes pak preferenecne mlati myth units.
//------------------------------------------------------------------------------
void applyAntiMythFocus()
{
   int heroCount = kbUnitCount(cUnitTypeHero, cMyID, cUnitStateAlive);
   if (heroCount < 2) { return; } // Nema smysl - nemame dost hrdinu

   // Aplikuj jen kdyz nepritel ma myth - jinak nezasahujeme do default targetingu
   int enemyMyth = 0;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      enemyMyth = enemyMyth + kbUnitCount(cUnitTypeMythUnit, p, cUnitStateAlive);
   }
   if (enemyMyth < 1) { return; }

   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   for (int i = 0; i < attackPlans.size(); i++)
   {
      int planID = attackPlans[i];
      if (aiPlanGetIsIDValid(planID) == false) { continue; }
      if (aiPlanGetParentID(planID) != -1) { continue; } // jen top-level plany

      // Reorder: Myth -> Hero -> MilitaryUnit -> Building
      aiPlanSetNumberVariableValues(planID, cAttackPlanTargetUnitTypes, 4, true);
      aiPlanSetVariableInt(planID, cAttackPlanTargetUnitTypes, 0, cUnitTypeMythUnit);
      aiPlanSetVariableInt(planID, cAttackPlanTargetUnitTypes, 1, cUnitTypeHero);
      aiPlanSetVariableInt(planID, cAttackPlanTargetUnitTypes, 2, cUnitTypeMilitaryUnit);
      aiPlanSetVariableInt(planID, cAttackPlanTargetUnitTypes, 3, cUnitTypeBuilding);
   }

   gAntiMythLastApplyTime = xsGetTime();
   debugStrategy("21: anti-myth focus applied to " + attackPlans.size() +
      " attack plans (heroes=" + heroCount + " enemyMyth=" + enemyMyth + ")");
}

rule antiMythFocusMonitor
inactive
group defaultClassicalRules
minInterval 20
{
   applyAntiMythFocus();
}

//------------------------------------------------------------------------------
// 22: Resource overflow management
// Pri velkem prebytku dane suroviny aktivuje secondary plany (farm, wall,
// nebo tech research priority). Zabranuje resource cap waste.
//------------------------------------------------------------------------------
void manageResourceOverflow()
{
   float food = kbResourceGet(cResourceFood);
   float wood = kbResourceGet(cResourceWood);
   float gold = kbResourceGet(cResourceGold);
   int now = xsGetTime();

   // Food overflow: build extra farm pokud uz delsi dobu nestavime
   if (food > 2500.0 && (now - gLastOverflowFarmTime) > 60000)
   {
      // Pouzij existujici farm build mechanism
      if (gFarmUnit > 0)
      {
         int farmPlanID = createSimpleBuildPlan(gFarmUnit, 1, 65, -1, 1);
         if (farmPlanID >= 0)
         {
            gLastOverflowFarmTime = now;
            debugStrategy("22: food overflow " + food + " - building extra farm");
         }
      }
   }

   // Wood overflow: build wall pokud nemame dost a (now - last) cooldown
   if (wood > 2500.0 && (now - gLastOverflowWallTime) > 90000)
   {
      int existingWalls = kbUnitCount(cUnitTypeAbstractWall, cMyID, cUnitStateAlive);
      if (existingWalls < 30)
      {
         // Bumpne urgency a strategy wall amount - existujici wall logika reaguje
         gLastOverflowWallTime = now;
         debugStrategy("22: wood overflow " + wood + " - hint wall expansion (urgency boost)");
         // Indirect: zvys urgency aby buildings.xs zvazil walls
         if (gMilitaryUrgency < 0.5) { gMilitaryUrgency = 0.5; }
      }
   }

   // Gold overflow: prodej zlato za jine zdroje pokud market existuje
   if (gold > 3000.0 && kbUnitCount(gMarketUnit, cMyID, cUnitStateAlive) > 0)
   {
      // Sell wood/food back if those are LOW (stuck in gold)
      if (food < 300.0)
      {
         aiSellResourceOnMarket(cResourceGold);
         debugStrategy("22: gold overflow " + gold + " + low food - bought food");
      }
      else if (wood < 300.0)
      {
         aiSellResourceOnMarket(cResourceGold);
         debugStrategy("22: gold overflow + low wood - bought wood");
      }
   }
}

rule resourceOverflowMonitor
inactive
group defaultClassicalRules
minInterval 15
{
   manageResourceOverflow();
}

//------------------------------------------------------------------------------
// 23: Wall breach detection
// Detekuje pokles wall countu jako proxy pro breach (nemame HP API).
// Pokles >2 walls za 30s = breach in progress -> bumpne defense urgency
// a force gather point na main base (existing defense routes pak doplnia).
//------------------------------------------------------------------------------
void monitorWallBreach()
{
   int wallCount = kbUnitCount(cUnitTypeAbstractWall, cMyID, cUnitStateAlive);
   int now = xsGetTime();

   // Inicializace pri prvnim spusteni
   if (gLastWallCount == 0 && wallCount > 0)
   {
      gLastWallCount = wallCount;
      gLastWallCheckTime = now;
      return;
   }

   // Detekce breach: pokles >= 2 walls za 30s
   int wallDrop = gLastWallCount - wallCount;
   if (wallDrop >= 2 && (now - gLastWallCheckTime) <= 30000)
   {
      if (gWallBreachActive == false)
      {
         gWallBreachActive = true;
         gWallBreachStartTime = now;
         gMilitaryUrgency = 1.0;
         gDefenseReflex = true;

         // Force attack manager to ignore interval
         xsRuleIgnoreIntervalOnce("attackManager");

         debugStrategy("23: WALL BREACH detected! " + wallDrop + " walls destroyed - max urgency");
         aiEchoWarning("23: wall breach!");
      }
   }
   // Cleanup: po 60s bez dalsiho poklesu deaktivovat
   else if (gWallBreachActive == true && (now - gWallBreachStartTime) > 60000)
   {
      gWallBreachActive = false;
      debugStrategy("23: wall breach mode ended");
   }

   gLastWallCount = wallCount;
   gLastWallCheckTime = now;
}

rule wallBreachMonitor
inactive
group defaultClassicalRules
minInterval 8
{
   monitorWallBreach();
}

//==============================================================================
// SEKCE 3 - P2: Settlement, trade, fishing, titan
//==============================================================================

//------------------------------------------------------------------------------
// 24: Settlement expansion reactivity
// Sleduje enemy TC count - pri expanze nepritele bumpne nasi prioritu
// vlastni TC expanze.
//------------------------------------------------------------------------------
void monitorEnemyExpansion()
{
   int totalEnemyTC = 0;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      totalEnemyTC = totalEnemyTC + kbUnitCount(cUnitTypeAbstractTownCenter, p, cUnitStateAlive);
   }

   int now = xsGetTime();
   int delta = totalEnemyTC - gLastEnemyTCCount;

   if (gLastEnemyTCCount > 0 && delta >= 1)
   {
      debugStrategy("24: enemy expanded TC count " + gLastEnemyTCCount + " -> " + totalEnemyTC);
      // Trigger force update plans - existing tcExpansion logic uvidi shortfall a expandne
      gDelayUpdateDistributionAndBreakdowns = false;
      // Bumpne attack interval bonus dolu o 20s aby AI utocila castejs (zabranit further expansion)
      if (gAdaptAttackIntervalBonus > -30)
      {
         gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus - 10;
      }
   }

   gLastEnemyTCCount = totalEnemyTC;
   gLastEnemyTCCheckTime = now;
}

rule settlementExpansionMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   monitorEnemyExpansion();
}

//------------------------------------------------------------------------------
// 25: Auto-trade rhythm
// Pocita resource velocity (rate of change) a aktivuje market trades pri
// nedostatku rate jedne suroviny pri prebytku jine.
//------------------------------------------------------------------------------
void monitorTradeRhythm()
{
   if (kbUnitCount(gMarketUnit, cMyID, cUnitStateAlive) == 0) { return; }

   float curFood = kbResourceGet(cResourceFood);
   float curWood = kbResourceGet(cResourceWood);
   float curGold = kbResourceGet(cResourceGold);
   int now = xsGetTime();

   // Pri prvni iteraci jen ulozit baseline
   if (gLastTradeCheckTime == 0)
   {
      gLastFood = curFood;
      gLastWood = curWood;
      gLastGold = curGold;
      gLastTradeCheckTime = now;
      return;
   }

   float dtSec = xsIntToFloat(now - gLastTradeCheckTime) / 1000.0;
   if (dtSec < 1.0) { return; }

   // Per-second rate
   gFoodVelocity = (curFood - gLastFood) / dtSec;
   gWoodVelocity = (curWood - gLastWood) / dtSec;
   gGoldVelocity = (curGold - gLastGold) / dtSec;

   // Trade pravidlo: pri rate < 0.5 res/sec u jednoho zdroje + > 1.0 u jineho -> obchod
   // (-0.5 znamena hladovime, > 1.0 prebytecne hromadime)
   if (gFoodVelocity < 0.5 && gGoldVelocity > 1.0 && curGold > 500.0)
   {
      aiSellResourceOnMarket(cResourceGold);
      debugStrategy("25: low foodRate " + gFoodVelocity + " + high goldRate - bought food");
   }
   if (gWoodVelocity < 0.5 && gGoldVelocity > 1.0 && curGold > 500.0)
   {
      aiSellResourceOnMarket(cResourceGold);
      debugStrategy("25: low woodRate " + gWoodVelocity + " + high goldRate - bought wood");
   }

   gLastFood = curFood;
   gLastWood = curWood;
   gLastGold = curGold;
   gLastTradeCheckTime = now;
}

rule tradeRhythmMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   monitorTradeRhythm();
}

//------------------------------------------------------------------------------
// 26: Fishing fleet rebuild after loss
// Sleduje pocet rybarskych lodi. Pri poklesu > 50% za 20s se snazi triggrovat
// rebuild via gFishingShipMaintainPlan (priority boost).
//------------------------------------------------------------------------------
void monitorFishingLoss()
{
   if (gFishingUnit < 0) { return; }
   int curFish = kbUnitCount(gFishingUnit, cMyID, cUnitStateAlive);
   int now = xsGetTime();

   if (gLastFishingBoatCount == 0 && curFish > 0)
   {
      gLastFishingBoatCount = curFish;
      return;
   }

   int loss = gLastFishingBoatCount - curFish;
   if (loss >= 2 && curFish > 0)
   {
      gFishingLossTriggerTime = now;
      // Bumpne priority maintain planu pokud existuje
      if (aiPlanGetIsIDValid(gFishingShipMaintainPlan) == true)
      {
         aiPlanSetPriority(gFishingShipMaintainPlan, 80);
         debugStrategy("26: fishing fleet loss " + loss + " - boosted maintain plan priority to 80");
      }
   }
   // Reset priority po 180s
   else if ((now - gFishingLossTriggerTime) > 180000 && gFishingLossTriggerTime > 0)
   {
      if (aiPlanGetIsIDValid(gFishingShipMaintainPlan) == true)
      {
         aiPlanSetPriority(gFishingShipMaintainPlan, 50);
      }
      gFishingLossTriggerTime = 0;
   }

   if (curFish > gLastFishingBoatCount)
   {
      // Update baseline pri rebuild
      gLastFishingBoatCount = curFish;
   }
}

rule fishingLossMonitor
inactive
group defaultClassicalRules
minInterval 20
{
   monitorFishingLoss();
}

//------------------------------------------------------------------------------
// 27: Titan offensive/defensive switching
// Pri pritomnosti Titan switchne mezi offensive (push do enemy base) a
// defensive (garrison u TC) podle parity armad.
//------------------------------------------------------------------------------
void manageTitanStrategy()
{
   int titanCount = kbUnitCount(cUnitTypeAbstractTitan, cMyID, cUnitStateAlive);
   if (titanCount == 0)
   {
      gTitanOffensiveMode = false;
      return;
   }

   int myArmy    = computeArmyValue(cMyID);
   int enemyArmy = computeMaxEnemyArmyValue();

   // Pokud mame > 70% enemy army value -> push (offensive)
   if (myArmy > xsFloatToInt(xsIntToFloat(enemyArmy) * 0.7))
   {
      if (gTitanOffensiveMode == false)
      {
         gTitanOffensiveMode = true;
         gAdaptAttackIntervalBonus = -45; // Aggressive push
         debugStrategy("27: TITAN offensive mode (myArmy=" + myArmy + " enemyArmy=" + enemyArmy + ")");
      }
   }
   // Pokud jsme slabsi - drz Titan u baze (defensive, urgency high)
   else
   {
      if (gTitanOffensiveMode == true)
      {
         gTitanOffensiveMode = false;
         gAdaptAttackIntervalBonus = 30;
         gMilitaryUrgency = 1.0;
         debugStrategy("27: TITAN defensive mode (army parity unfavorable)");
      }
   }
}

rule titanStrategyMonitor
inactive
group defaultClassicalRules
minInterval 15
{
   manageTitanStrategy();
}

//==============================================================================
// SEKCE 4 - P3: Relics, garrison, enemy god
//==============================================================================

//------------------------------------------------------------------------------
// 28: Hero relic competition tracking
// Pri detekovani relic pres scout pohledu force-bumpne hero pomer + log.
// Pretvari priority hero pretty bonus.
//------------------------------------------------------------------------------
void scanRelicCompetition()
{
   // Najdi relics na mape (cUnitTypeRelic exists v AOM Retold)
   int qID = kbUnitQueryCreate("relicScan");
   kbUnitQuerySetUnitType(qID, cUnitTypeRelic);
   kbUnitQuerySetState(qID, cUnitStateAlive);
   kbUnitQueryResetResults(qID);
   int n = kbUnitQueryExecute(qID);

   if (n == 0) { return; }

   // Spocti kolik je collected by us vs enemies (relic owned = held)
   int myRelics = 0;
   int enemyRelics = 0;
   int freeRelics = 0;
   for (int i = 0; i < n; i++)
   {
      int rID = kbUnitQueryGetResult(qID, i);
      if (kbUnitGetIsIDValid(rID) == false) { continue; }
      int owner = kbUnitGetPlayerID(rID);
      if (owner == cMyID) { myRelics++; }
      else if (owner > 0 && kbPlayerIsEnemy(owner) == true) { enemyRelics++; }
      else { freeRelics++; }
   }

   // Pri free relics + me malo hrdinu, force bumpne hero %
   if (freeRelics > 0 && myRelics < freeRelics)
   {
      if (gArmyHeroPercentage < 0.35)
      {
         gArmyHeroPercentage = gArmyHeroPercentage + 0.03;
         debugStrategy("28: " + freeRelics + " free relics on map (we have " + myRelics +
            ") - boosting hero%% to " + gArmyHeroPercentage);
      }
   }
}

rule relicCompetitionMonitor
inactive
group defaultArchaicRules
minInterval 25
{
   scanRelicCompetition();
}

//------------------------------------------------------------------------------
// 29: Garrison logic on attack
// Pri gDefenseReflex || gDefenseReflexPanic protocol garrisonovat villagery
// do nejblizsiho TC. (aiTaskWorkUnit do TC v AOM Retold triggers garrison.)
//------------------------------------------------------------------------------
void garrisonVillagersInTC()
{
   if (gDefenseReflex == false && gDefenseReflexPanic == false) { return; }

   int now = xsGetTime();
   if ((now - gLastGarrisonTime) < 20000) { return; } // Cooldown 20s

   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return; }
   vector basePos = kbBaseGetLocation(cMyID, mainBaseID);

   int tcID = getClosestUnitByLocation(cUnitTypeAbstractTownCenter, cMyID,
      cUnitStateAlive, basePos, 50.0);
   if (tcID < 0) { return; }

   // Najdi villagery do 30 tile od TC, ktere je v boji ohrozuje
   int qID = kbUnitQueryCreate("villagerGarrisonScan");
   kbUnitQuerySetPlayerID(qID, cMyID);
   kbUnitQuerySetUnitType(qID, cUnitTypeAbstractVillager);
   kbUnitQuerySetState(qID, cUnitStateAlive);
   kbUnitQuerySetPosition(qID, basePos);
   kbUnitQuerySetMaximumDistance(qID, 30.0);
   kbUnitQueryResetResults(qID);
   int n = kbUnitQueryExecute(qID);

   int garrisoned = 0;
   for (int i = 0; i < n && garrisoned < 5; i++) // Max 5 vesnicanu
   {
      int vID = kbUnitQueryGetResult(qID, i);
      if (kbUnitGetIsIDValid(vID) == false) { continue; }
      vector vPos = kbUnitGetPosition(vID);

      // Garrison jen kdyz je villager < 15 tile od enemy
      int eqID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary,
         cPlayerRelationEnemyNotGaia, cUnitStateAlive, vPos, 15.0);
      int enemiesNearby = kbUnitQueryExecute(eqID);
      if (enemiesNearby == 0) { continue; }

      aiTaskWorkUnit(vID, tcID);
      garrisoned++;
   }

   if (garrisoned > 0)
   {
      gLastGarrisonTime = now;
      debugStrategy("29: garrisoned " + garrisoned + " villagers into TC " + tcID);
   }
}

rule garrisonMonitor
inactive
group defaultClassicalRules
minInterval 5
{
   garrisonVillagersInTC();
}

//------------------------------------------------------------------------------
// 30: Enemy god pick reactions
// Detekuje enemy civ a aplikuje counter strategii (Loki -> wood boost, Hades ->
// extra siege, Set -> hunt animals first, Thor -> tech race).
//------------------------------------------------------------------------------
void detectEnemyMainCiv()
{
   if (gEnemyCivAdaptApplied == true) { return; }
   if (gEnemyMainCiv > 0) { return; }

   int firstEnemy = aiGetMostHatedPlayerID();
   if (firstEnemy <= 0) { return; }

   int civID = kbPlayerGetCiv(firstEnemy);
   if (civID < 0) { return; }
   gEnemyMainCiv = civID;

   debugStrategy("30: detected primary enemy civ ID " + civID);

   // Aplikuj counter
   if (civID == cCivLoki)
   {
      // Loki: trickster, raids -> potrebujeme wall + obrana
      gMilitaryUrgency = 0.5;
      if (gArmyHeroPercentage < 0.35) { gArmyHeroPercentage = 0.35; }
      debugStrategy("30: enemy=Loki - boost defense + heroes (anti-myth raids)");
   }
   else if (civID == cCivHades)
   {
      // Hades: army revival - potrebujeme vetsi siege + clear bodies
      if (gArmySiegePercentage < 0.20) { gArmySiegePercentage = 0.20; }
      debugStrategy("30: enemy=Hades - boost siege (clear revival armies)");
   }
   else if (civID == cCivSet)
   {
      // Set: animal control - hunt animals first nez nam je preda
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus - 15; // attack drive
      debugStrategy("30: enemy=Set - aggressive playstyle (deny resources)");
   }
   else if (civID == cCivThor)
   {
      // Thor: tech advantage - pretahnout tech race
      if (gArmyEarlyGameMythPercentage < 0.25) { gArmyEarlyGameMythPercentage = 0.25; }
      debugStrategy("30: enemy=Thor - boost myth (counter dwarf eco)");
   }
   else if (civID == cCivOdin)
   {
      // Odin: ravens (good scouting) - need to push fast nez bude readlocked
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus - 10;
      debugStrategy("30: enemy=Odin - aggressive (raven gives him info advantage)");
   }
   else if (civID == cCivPoseidon)
   {
      // Poseidon: hippocampus + naval - boost naval threat detection
      debugStrategy("30: enemy=Poseidon - watch for naval/hippocampus rush");
   }

   gEnemyCivAdaptApplied = true;
}

rule enemyCivAdaptMonitor
inactive
group defaultArchaicRules
minInterval 20
{
   detectEnemyMainCiv();
   if (gEnemyCivAdaptApplied == true)
   {
      xsDisableRule("enemyCivAdaptMonitor");
   }
}
