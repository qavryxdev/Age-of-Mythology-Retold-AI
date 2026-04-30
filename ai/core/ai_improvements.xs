//==============================================================================
/* ai_improvements.xs  -  v3.0

   10 systemovych vylepseni AI nad ramec stavajici v2.9.

   Princip: aditivni vrstva - nove globaly + nove rules, ktere se cti existujici
   stav (gAttackManager, gStrategyManager, gAdapt*) a upravuji ho pres existujici
   modifikatory (gAdaptAttackIntervalBonus, gArmy*Percentage, gAdaptMinAttackSizeBonus).

   Zadne primer modifikace existujicich struct field nebo rules - vse pres
   modifikatory ktere existujici kod uz pouziva.

   Sekce:
     P1: Utility weights, situational god power triggers, smart counter decay
     P2: Dynamic strategy switching, tech-level opponent modeling,
         BO bias selection, scouting timeout
     P3: Personality tiers (5 levels), economy military urgency,
         emergency reactive defense
*/
//==============================================================================

//==============================================================================
// SEKCE 1 - Globaly (utility weights, urgency, tech tracking, timestamps)
//==============================================================================

// --- P1.1: Utility weights (rozsireni boolean strategy flagu) ---
// 0.0 = pasivni, 1.0 = totalne agresivni. Pocita se z personality + situace.
extern float gAggressionScore = 0.5;
extern float gEconomyFocus    = 0.5;
extern float gDefenseScore    = 0.5;

// --- P1.3: Timestamp pro decay counter ratios (kdy naposledy videno) ---
extern int gLastSeenEnemyRanged = 0;
extern int gLastSeenEnemyMyth   = 0;
extern int gLastSeenEnemySiege  = 0;
extern int gLastSeenEnemyMelee  = 0;

// --- P2.4: Dynamicke prepinani strategie ---
extern int gLastStrategySwitchTime = 0;
extern int gStrategySwitchCooldown = 90000; // 90s minimum mezi prepnutim

// --- P2.5: Tech-level opponent modeling ---
extern int gEnemyArmorLevel  = 0; // 0=zadny, 1=copper, 2=bronze, 3=iron
extern int gEnemyAttackLevel = 0;
extern int gEnemySpeedLevel  = 0;
extern int gMaxEnemyArmorPUID  = -1; // posledni nepritel s nejvyssim armor upgrade
extern int gMaxEnemyAttackPUID = -1;

// --- P2.6: BO selection bias (precteno BO modulem) ---
extern int gBOVariant = 0; // 0=balanced, 1=eco, 2=rush, 3=turtle
extern bool gBOVariantSelected = false;

// --- P2.7: Scouting timeout ---
extern int gScoutingStartTime  = 0;
extern int gScoutingTimeoutMs  = 90000; // 90s

// --- P3.8: Personality tier (5 stupnu, 0=ultra defensive .. 4=ultra aggressive) ---
extern int gPersonalityTier = 2; // default = balanced

// --- P3.9: Military urgency (0.0 = klid, 1.0 = totalni boj o existenci) ---
extern float gMilitaryUrgency = 0.0;

// --- P3.10: Emergency state ---
extern bool gEmergencyDefenseActive = false;
extern int  gEmergencyLastTriggerTime = 0;

//==============================================================================
// SEKCE 2 - Helper funkce
//==============================================================================

//------------------------------------------------------------------------------
// computeArmyValue - vrati "hodnotu" armady (pop * difficulty multiplier).
// Pouziva se pro porovnani sil pri dynamic strategy switch.
//------------------------------------------------------------------------------
int computeArmyValue(int playerID = -1)
{
   if (playerID < 0) { return 0; }
   if (kbPlayerHasLost(playerID)) { return 0; }
   int milPop  = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, playerID, cUnitStateAlive);
   int mythPop = kbUnitCount(cUnitTypeMythUnit, playerID, cUnitStateAlive);
   int siege   = kbUnitCount(cUnitTypeAbstractSiegeWeapon, playerID, cUnitStateAlive);
   // Myth a siege vazi 2x (vetsi pop slot, vetsi efekt v boji).
   return milPop + mythPop + siege;
}

int computeMaxEnemyArmyValue()
{
   int maxVal = 0;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      int v = computeArmyValue(p);
      if (v > maxVal) { maxVal = v; }
   }
   return maxVal;
}

//------------------------------------------------------------------------------
// distanceToMainBase - vzdalenost vektoru k hlavni zakladne nas hrac.
//------------------------------------------------------------------------------
float distanceToMainBase(vector loc = cInvalidVector)
{
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return 999.0; }
   vector basePos = kbBaseGetLocation(cMyID, mainBaseID);
   return xsVectorLength(loc - basePos);
}

//==============================================================================
// SEKCE 3 - P1: Rychle vyhry
//==============================================================================

//------------------------------------------------------------------------------
// P1.1: updateUtilityScores
// Pocita 0.0-1.0 utility skore z aktualni situace.
// Skore pak modifikuje vystup ostatnich rules pres bonusy.
//------------------------------------------------------------------------------
void updateUtilityScores()
{
   // Aggression: roste s vekem, naskokem ve veku, prebytkem armady
   float aggr = 0.40 + 0.05 * xsIntToFloat(kbPlayerGetAge(cMyID) - 1);
   if (gAdaptAgeAdvantage == 1)  { aggr = aggr + 0.15; }
   if (gAdaptAgeAdvantage == -1) { aggr = aggr - 0.15; }

   int myArmy    = computeArmyValue(cMyID);
   int enemyArmy = computeMaxEnemyArmyValue();
   if (enemyArmy > 0)
   {
      float ratio = xsIntToFloat(myArmy) / xsIntToFloat(enemyArmy);
      if (ratio > 1.5) { aggr = aggr + 0.20; }
      if (ratio < 0.7) { aggr = aggr - 0.20; }
   }

   // Personality tier nudge (0=defensive, 4=aggressive)
   aggr = aggr + (xsIntToFloat(gPersonalityTier - 2) * 0.10);

   // Clamp 0.0-1.0
   if (aggr < 0.0) { aggr = 0.0; }
   if (aggr > 1.0) { aggr = 1.0; }
   gAggressionScore = aggr;

   // Defense: roste se ztratami, ekonomickym tlakem, nizkym aggression
   float def = 1.0 - aggr;
   if (gAdaptEcoUnderPressure == true) { def = def + 0.15; }
   if (gAdaptTotalDefenseMode == true) { def = 1.0; }
   if (def > 1.0) { def = 1.0; }
   gDefenseScore = def;

   // Economy focus: vyssi v early game, nizsi pri urgent boji
   float econ = 0.7 - (0.10 * xsIntToFloat(kbPlayerGetAge(cMyID) - 1));
   econ = econ - gMilitaryUrgency * 0.3;
   if (econ < 0.2) { econ = 0.2; }
   if (econ > 0.9) { econ = 0.9; }
   gEconomyFocus = econ;
}

//------------------------------------------------------------------------------
// rule utilityScoreMonitor
// Aktualizuje utility skore kazdych 20s.
//------------------------------------------------------------------------------
rule utilityScoreMonitor
inactive
group defaultClassicalRules
minInterval 20
{
   updateUtilityScores();
   debugStrategy("UTILITY: aggr=" + gAggressionScore + " def=" + gDefenseScore +
      " econ=" + gEconomyFocus + " urgency=" + gMilitaryUrgency);
}

//------------------------------------------------------------------------------
// P1.2: God power situational triggers
// Standardni mechanismus volat godPowerManager.useUnusedGodPowers() pasivne pri
// strategy switch - pri klidne hre tedy power lezi v bank dlouho a aktivuje se
// "nahodne" na zaklade setupCulture* logiky.
// Vylepseni: pri detekci threat / vysokeho loss rate forciblne flushneme bank,
// takze setup* funkce vytvori plan jeste pred dalsim strategy switchem.
// Vysledek: power se vrhne pri threat (nebo brzy po), ne az pri pristim age up.
//------------------------------------------------------------------------------
bool detectGodPowerTrigger()
{
   // Trigger 1: nepratele v 35 tile od TC (>= 6 jednotek)
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID >= 0)
   {
      vector basePos = kbBaseGetLocation(cMyID, mainBaseID);
      int qID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary,
         cPlayerRelationEnemyNotGaia, cUnitStateAlive, basePos, 35.0);
      int n = kbUnitQueryExecute(qID);
      if (n >= 6) { return true; }
   }

   // Trigger 2: vysoky loss rate (defensive use)
   if (gAdaptAvgLossRate > 0.50) { return true; }

   // Trigger 3: total defense mode
   if (gAdaptTotalDefenseMode == true) { return true; }

   // Trigger 4: emergency reactive defense aktivni
   if (gEmergencyDefenseActive == true) { return true; }

   return false;
}

rule godPowerSituationalTriggers
inactive
group defaultClassicalRules
minInterval 12
{
   if (checkStrategyFlag(cStrategyFlagAutomaticGodPowerUsage) == false) { return; }
   if (detectGodPowerTrigger() == false) { return; }

   // Force flush bank: setup* funkce vytvori plany hned, ne az pri pristim age up
   debugStrategy("P1.2: situational trigger active - flushing god power bank");
   godPowerManager.useUnusedGodPowers();
}

//------------------------------------------------------------------------------
// P1.3: Smart counter decay s timestamps
// Pridava timestamp tracking k existujicim adaptCounterComposition globaly.
// Pokud jsme videli enemy unit type behem poslednich 60s, decay se pozdrzi.
// Pokud uz neni 60s+ videt, decay se zrychli.
//------------------------------------------------------------------------------
void updateEnemySeenTimestamps()
{
   int now = xsGetTime();

   // Detekce: pokud existuje aktualni nenulovy ratio + jsme v defensive mode = videno ted
   if (gDefenseReflex == true || gDefenseReflexPanic == true)
   {
      if (gAdaptEnemyAttackRangedRatio > 0.10) { gLastSeenEnemyRanged = now; }
      if (gAdaptEnemyAttackMythRatio   > 0.10) { gLastSeenEnemyMyth   = now; }
      if (gAdaptEnemyAttackSiegeRatio  > 0.10) { gLastSeenEnemySiege  = now; }
      if (gAdaptEnemyAttackMeleeRatio  > 0.10) { gLastSeenEnemyMelee  = now; }
   }
}

float getDecayMultiplier(int lastSeenTime = 0)
{
   int sinceMs = xsGetTime() - lastSeenTime;
   if (sinceMs < 60000)  { return 0.95; }  // Stale ohrozeni: pomaly decay
   if (sinceMs < 180000) { return 0.85; }  // Standardni decay (puvodni)
   return 0.70; // Davno nevideno: rychly decay
}

rule smartCounterDecay
inactive
group defaultClassicalRules
minInterval 30
{
   updateEnemySeenTimestamps();
   if (gDefenseReflex == true || gDefenseReflexPanic == true) { return; }

   // Override decay v adaptiveLearningMonitor: nase verze respektuje "since last seen".
   gAdaptEnemyAttackRangedRatio = gAdaptEnemyAttackRangedRatio * getDecayMultiplier(gLastSeenEnemyRanged);
   gAdaptEnemyAttackMythRatio   = gAdaptEnemyAttackMythRatio   * getDecayMultiplier(gLastSeenEnemyMyth);
   gAdaptEnemyAttackSiegeRatio  = gAdaptEnemyAttackSiegeRatio  * getDecayMultiplier(gLastSeenEnemySiege);
   gAdaptEnemyAttackMeleeRatio  = gAdaptEnemyAttackMeleeRatio  * getDecayMultiplier(gLastSeenEnemyMelee);
}

//==============================================================================
// SEKCE 4 - P2: Strukturalni
//==============================================================================

//------------------------------------------------------------------------------
// P2.4: Dynamic strategy switching
// Pri vyrazne nevyhode armady prepne na turtler na 90s, pak re-evaluate.
// Misto primeho prepinani strategie pres gStrategyManager (riskantni) modifikujeme
// gAdaptAttackIntervalBonus + gAdaptMinAttackSizeBonus tak, aby AI defacto turtlovala.
//------------------------------------------------------------------------------
extern bool gDynamicTurtleActive = false;
extern int  gDynamicTurtleStart  = 0;

rule dynamicStrategySwitch
inactive
group defaultClassicalRules
minInterval 20
{
   int myArmy    = computeArmyValue(cMyID);
   int enemyArmy = computeMaxEnemyArmyValue();
   int now = xsGetTime();

   // Aktivovat turtle pri 1.5x vetsim nepritele a my mame >= 10 vojaku (jinak je to spis problem trainingu)
   if (gDynamicTurtleActive == false && myArmy >= 10 && enemyArmy > xsFloatToInt(xsIntToFloat(myArmy) * 1.5))
   {
      // Cooldown - neprepinat prilis casto
      if (now - gLastStrategySwitchTime < gStrategySwitchCooldown) { return; }

      gDynamicTurtleActive = true;
      gDynamicTurtleStart = now;
      gLastStrategySwitchTime = now;
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus + 90; // Vysoka pasivita
      gMilitaryUrgency = 0.7;
      debugStrategy("P2.4: DYNAMIC TURTLE ACTIVATED (myArmy=" + myArmy + ", enemyArmy=" + enemyArmy + ")");
   }
   // Deaktivovat po 90s
   else if (gDynamicTurtleActive == true && (now - gDynamicTurtleStart) > 90000)
   {
      gDynamicTurtleActive = false;
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus - 90;
      gMilitaryUrgency = 0.3;
      debugStrategy("P2.4: dynamic turtle expired, resuming normal");
   }
   // Brzke ukonceni pokud uz mame parity
   else if (gDynamicTurtleActive == true && myArmy >= xsFloatToInt(xsIntToFloat(enemyArmy) * 1.1))
   {
      gDynamicTurtleActive = false;
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus - 90;
      gMilitaryUrgency = 0.2;
      debugStrategy("P2.4: dynamic turtle ended early, parity reached");
   }
}

//------------------------------------------------------------------------------
// P2.5: Tech-level opponent modeling (proxy-based)
// Primy kbTechGetStatus na enemy hracich neni dostupny pres fog of war.
// Pouzivame proxy: pocet armoury budov + vek nepritele.
//   Vek 2 + 1 armoury = pravdepodobne copper upgrades (level 1)
//   Vek 3 + armoury = pravdepodobne bronze (level 2)
//   Vek 4 = pravdepodobne iron (level 3)
//------------------------------------------------------------------------------
void scanEnemyTechLevels()
{
   int maxLevel  = 0;
   int totalArmouries = 0;

   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }

      int eAge = kbPlayerGetAge(p);
      int armouriesVisible = kbUnitCount(cUnitTypeArmory, p, cUnitStateAlive);
      totalArmouries = totalArmouries + armouriesVisible;

      int level = 0;
      if (eAge >= cAge2 && armouriesVisible >= 1) { level = 1; } // copper
      if (eAge >= cAge3 && armouriesVisible >= 1) { level = 2; } // bronze
      if (eAge >= cAge4)                          { level = 3; } // iron

      if (level > maxLevel) { maxLevel = level; }
   }

   gEnemyArmorLevel  = maxLevel;
   gEnemyAttackLevel = maxLevel;

   // Counter logika: pokud nepritel ma vetsi armor nez my, zvys siege/myth podil
   if (gEnemyArmorLevel >= 2 && gArmySiegePercentage < 0.20)
   {
      gArmySiegePercentage = gArmySiegePercentage + 0.02;
      debugStrategy("P2.5: enemy upgrade level=" + gEnemyArmorLevel + " (armouries=" + totalArmouries +
         "), boosting siege to " + gArmySiegePercentage);
   }
   if (gEnemyAttackLevel >= 2 && gArmyHeroPercentage < 0.35)
   {
      gArmyHeroPercentage = gArmyHeroPercentage + 0.02;
      debugStrategy("P2.5: enemy upgrade level=" + gEnemyAttackLevel + ", boosting heroes to " + gArmyHeroPercentage);
   }
}

rule techLevelOpponentModeling
inactive
group defaultClassicalRules
minInterval 45
{
   scanEnemyTechLevels();
}

//------------------------------------------------------------------------------
// P2.6: BO variant selection bias
// Vybere BO variantu na startu hry podle distance to enemy + map type.
// BO modul muze precist gBOVariant a podle toho menit zaznamy mBuildingsToMaintain.
//------------------------------------------------------------------------------
void selectBOVariant()
{
   if (gBOVariantSelected == true) { return; }

   // Vychozi: balanced
   gBOVariant = 0;

   // Najdi nejblizsiho nepritele
   float minEnemyDist = 999.0;
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return; }
   vector myBase = kbBaseGetLocation(cMyID, mainBaseID);

   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      int eBaseID = kbBaseGetMainID(p);
      if (eBaseID < 0) { continue; }
      vector eBase = kbBaseGetLocation(p, eBaseID);
      float d = xsVectorLength(eBase - myBase);
      if (d < minEnemyDist) { minEnemyDist = d; }
   }

   bool isIslandMap = gMapInfo.mIsIslandMap;

   // Heuristika: blizko (<150 tile) + ne ostrov + agresivni personality = rush
   //             ostrov nebo daleko + defensivni = eco
   //             defensivni personality = turtle
   if (gPersonalityTier <= 1)
   {
      gBOVariant = 3; // turtle
   }
   else if (gPersonalityTier >= 3 && minEnemyDist < 150.0 && isIslandMap == false)
   {
      gBOVariant = 2; // rush
   }
   else if (isIslandMap == true || minEnemyDist > 200.0)
   {
      gBOVariant = 1; // eco
   }

   gBOVariantSelected = true;
   debugStrategy("P2.6: BO variant = " + gBOVariant +
      " (enemyDist=" + minEnemyDist + ", island=" + isIslandMap +
      ", personality=" + gPersonalityTier + ")");

   // Aplikace: rush variant zkrati intervaly utoku, eco variant zvysi farm cap
   if (gBOVariant == 2) // rush
   {
      gAdaptAttackIntervalBonus = -45;
   }
   else if (gBOVariant == 3) // turtle
   {
      gAdaptAttackIntervalBonus = 60;
   }
}

rule boVariantSelector
inactive
group defaultArchaicRules
minInterval 5
{
   selectBOVariant();
   if (gBOVariantSelected == true)
   {
      xsDisableRule("boVariantSelector");
   }
}

//------------------------------------------------------------------------------
// P2.7: Scouting timeout
// Pokud gAttackManager.mScoutingState zustane v cScoutingForEnemies > 90s,
// vynutime prechod do cStateNormal a let attack proceed na poslednich znamych pozicich.
//------------------------------------------------------------------------------
rule scoutingTimeout
inactive
group defaultClassicalRules
minInterval 15
{
   int now = xsGetTime();
   bool isScouting = (gAttackManager.mScoutingState == cScoutingForEnemies ||
                      gAttackManager.mScoutingState == cNoEnemies);

   if (isScouting == true)
   {
      if (gScoutingStartTime == 0)
      {
         gScoutingStartTime = now;
         return;
      }
      if ((now - gScoutingStartTime) > gScoutingTimeoutMs)
      {
         debugStrategy("P2.7: scouting timeout (" + ((now - gScoutingStartTime) / 1000) +
            "s) - forcing normal state, attack will proceed on last known positions");
         gAttackManager.mScoutingState = cNoScoutingNeeded;
         gAttackManager.mState = cStateNormal;
         gScoutingStartTime = 0;
      }
   }
   else
   {
      gScoutingStartTime = 0;
   }
}

//==============================================================================
// SEKCE 5 - P3: Vetsi redesign
//==============================================================================

//------------------------------------------------------------------------------
// P3.8: Personality tier (5 stupnu)
// 0 = UltraDefensive  : zadny utok dokud nemame 2x vojska, max walls/towers, fast titan
// 1 = Defensive       : podobne jako Turtler, ale utoci pri parity
// 2 = Balanced        : default
// 3 = Aggressive      : podobne Rusher, krati intervaly
// 4 = UltraAggressive : 4-min rush, zadny eco upgrade dokud nemame 1. utok
//------------------------------------------------------------------------------
void applyPersonalityTier()
{
   switch (gPersonalityTier)
   {
      case 0: // UltraDefensive
      {
         gAdaptAttackIntervalBonus = 90;
         gArmySiegePercentage      = 0.05; // Zadny siege - bunkerujem
         gArmyHeroPercentage       = 0.40; // Max hero (anti-myth)
         debugStrategy("P3.8: UltraDefensive applied");
         break;
      }
      case 1: // Defensive
      {
         gAdaptAttackIntervalBonus = 45;
         gArmySiegePercentage      = 0.10;
         debugStrategy("P3.8: Defensive applied");
         break;
      }
      case 2: // Balanced - default, no override
      {
         debugStrategy("P3.8: Balanced (default) applied");
         break;
      }
      case 3: // Aggressive
      {
         gAdaptAttackIntervalBonus = -30;
         gArmyEarlyGameMythPercentage = 0.25;
         debugStrategy("P3.8: Aggressive applied");
         break;
      }
      case 4: // UltraAggressive
      {
         gAdaptAttackIntervalBonus = -60;
         gAdaptMinAttackSizeBonus  = -3; // Mensi "min attack" pro rychly start
         gArmyEarlyGameMythPercentage = 0.30;
         debugStrategy("P3.8: UltraAggressive applied (4-min rush mode)");
         break;
      }
   }
}

rule personalityTierApply
inactive
group defaultArchaicRules
minInterval 10
{
   applyPersonalityTier();
   xsDisableRule("personalityTierApply"); // Aplikuj jen jednou na startu
}

//------------------------------------------------------------------------------
// P3.9: Economy military urgency multiplier
// gMilitaryUrgency 0.0-1.0 modifikuje resource alokaci.
// Pri vysoke urgency (boj o existenci) snizujeme food/wood gather priority,
// preferujeme gold (ktery jde rovnou na vojaky).
//------------------------------------------------------------------------------
void updateMilitaryUrgency()
{
   float urgency = 0.0;

   // Defensive reflex = strednai urgency
   if (gDefenseReflex == true)      { urgency = urgency + 0.4; }
   if (gDefenseReflexPanic == true) { urgency = urgency + 0.6; }

   // Total defense mode = max urgency
   if (gAdaptTotalDefenseMode == true) { urgency = 1.0; }

   // Vekova nevyhoda + nepritele blizko = vyssi urgency
   if (gAdaptAgeAdvantage == -1) { urgency = urgency + 0.2; }

   // KOTH panic
   if (gAttackManager.mKOTHPanic == true) { urgency = 1.0; }

   if (urgency > 1.0) { urgency = 1.0; }
   if (urgency < 0.0) { urgency = 0.0; }

   gMilitaryUrgency = urgency;
}

rule militaryUrgencyMonitor
inactive
group defaultClassicalRules
minInterval 10
{
   updateMilitaryUrgency();
}

//------------------------------------------------------------------------------
// P3.10: Emergency reactive defense
// Krate-rychly check (3s) jestli enemy military jsou < 25 tile od TC.
// Pokud ano, ignoruje normal interval a forces full defensive reflex.
//------------------------------------------------------------------------------
rule emergencyReactiveDefense
inactive
group defaultClassicalRules
minInterval 3
{
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return; }
   vector basePos = kbBaseGetLocation(cMyID, mainBaseID);

   int qID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary,
      cPlayerRelationEnemyNotGaia, cUnitStateAlive, basePos, 25.0);
   int n = kbUnitQueryExecute(qID);

   int now = xsGetTime();

   if (n >= 3) // 3+ vojaci v 25 tile od TC = krize
   {
      if (gEmergencyDefenseActive == false || (now - gEmergencyLastTriggerTime) > 30000)
      {
         gEmergencyDefenseActive = true;
         gEmergencyLastTriggerTime = now;

         // Vynut okamzitou prepnuti militaryUrgency a defensiveReflex
         gMilitaryUrgency = 1.0;

         // Trigger defense reflex via existing mechanism
         gDefenseReflex = true;

         // Force vsechna pravidla spojena s utokem ignore interval
         xsRuleIgnoreIntervalOnce("attackManager");
         xsRuleIgnoreIntervalOnce("adaptiveIncomingAttackMonitor");

         debugStrategy("P3.10: EMERGENCY! " + n + " enemies < 25 tiles from TC - activating max defense");
         aiEchoWarning("P3.10: emergency defense activated!");
      }
   }
   else if (gEmergencyDefenseActive == true && n == 0)
   {
      // Klid - cleanup po 60s
      if ((now - gEmergencyLastTriggerTime) > 60000)
      {
         gEmergencyDefenseActive = false;
         debugStrategy("P3.10: emergency defense deactivated (no enemies near TC)");
      }
   }
}

//==============================================================================
// SEKCE 6 - Aktivace pravidel
// Pravidla v groupach defaultArchaicRules / defaultClassicalRules se aktivuji
// automaticky pres xsEnableRuleGroup() volane v setup.xs / handlers.xs pri vstupu
// do prislusneho veku (stejny pattern jako adaptive_learning.xs).
// Zadny explicitni xsEnableRule neni potreba.
//==============================================================================
