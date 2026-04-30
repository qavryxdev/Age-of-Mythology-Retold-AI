//==============================================================================
/* adaptive_learning.xs  -  v1.2

   Adaptivni system uceni a prizpusobeni AI podle situace na bojisti.

   System sleduje:
   - Vysledky utoku (uspech / neuspech / odrazeni)
   - Slozeni nepratelske armady a prizpusobuje protijedy
   - Ekonomicky tlak - prepina mezi eco/mil focus
   - Prubeh veku - reaguje na vyhodu / ztratu v tech pokroku
   - Miru ztrat a prizpusobuje minimalni velikost utocne armady

   Vse je ulozeno v globalnich promennych a aktualizovano pravidly.
*/
//==============================================================================

//==============================================================================
// SEKCE 1 - Datove struktury pro sledovani situace
//==============================================================================

// --- Vysledky utoku ---
// gAdaptAttackLaunched declared in globals.xs
extern int gAdaptAttackSucceeded  = 0;  // Utoku, ktere znicily alespon jednu budovu
// gAdaptAttackFailed declared in globals.xs
// gAdaptAttackInProgress declared in globals.xs
// gAdaptAttackEnemyBuildingsAtStart declared in globals.xs

// --- Ztraty ---
// gAdaptLastWaveStartPop declared in globals.xs
extern int gAdaptLastWaveLossPop   = 0;  // Ztraty za posledni utok
extern float gAdaptAvgLossRate     = 0.0; // Prumerna mira ztrat (0.0 - 1.0)

// --- Nepratelska armada ---
extern float gAdaptEnemyArcherRatio = 0.0;  // Pomer lucisniku u nepritele (detekce)
extern float gAdaptEnemyMythRatio   = 0.0;  // Pomer mytickych jednotek
extern float gAdaptEnemySiegeRatio  = 0.0;  // Pomer oblehacich zbrani
extern int gAdaptEnemyWallCount     = 0;    // Pocet hradeb nepritele

// --- Dynamicke prizpusobeni intervalu utoku ---
// gAdaptAttackIntervalBonus declared in globals.xs (forward decl for military_attack.xs)
// v1.5: Adaptivni bonus k minimalni velikosti utoku (pricten PO calculateMinAttackSizes())
// gAdaptMinAttackSizeBonus declared in globals.xs (forward decl for military_attack.xs)

// --- Ekonomicky stav ---
extern bool gAdaptEcoUnderPressure = false; // True = nepritel se nas snazi ekonomicky znicit
extern int gAdaptLastEcoCheckPop   = 0;     // Pocet vesnicanu pri poslednim mereni

// --- Vekovy naskok ---
extern int gAdaptAgeAdvantage = 0; // +1 = jsme napred, -1 = jsme pozadu, 0 = stejny vek
// v1.5: Aktualni prispevek vekove vyhody k gAdaptAttackIntervalBonus (pro undo pri zmene)
extern int gAdaptAgeBonus = 0;

//==============================================================================
// SEKCE 2 - Pomocne funkce
//==============================================================================

//------------------------------------------------------------------------------
// getEnemyMilitaryUnitCount
// Vrati odhadovany pocet vojenskych jednotek nepritele daneho typu.
//------------------------------------------------------------------------------
int getEnemyMilitaryUnitCount(int unitTypeID = -1)
{
   int total = 0;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      total += kbUnitCount(unitTypeID, p, cUnitStateAlive);
   }
   return total;
}

//------------------------------------------------------------------------------
// getTotalEnemyMilPop
// Vrati celkovou vojenskou populaci vsech nepratel.
//------------------------------------------------------------------------------
int getTotalEnemyMilPop()
{
   int total = 0;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      total += kbUnitCount(cUnitTypeLogicalTypeLandMilitary, p, cUnitStateAlive);
   }
   return total;
}

//------------------------------------------------------------------------------
// adaptArmyComposition
// Prizpusobi slozeni armady na zaklade detekovaneho slozeni nepritele.
// Vola se z adaptiveLearningMonitor.
//------------------------------------------------------------------------------
void adaptArmyComposition()
{
   // v2.1: keep hero baseline aligned with globals.xs difficulty defaults.
   float baseHeroPercentage = 0.30;
   if (cDifficultyCurrent <= cDifficultyHard)
   {
      baseHeroPercentage = 0.20;
   }

   int enemyArchers = getEnemyMilitaryUnitCount(cUnitTypeLogicalTypeRangedUnitsAttack); // v1.6.4 fix: RangedHandInfantry neexistuje
   int enemyMyth    = getEnemyMilitaryUnitCount(cUnitTypeMythUnit);                    // v1.6.4 fix: AbstractMythUnit neexistuje
   int enemySiege   = getEnemyMilitaryUnitCount(cUnitTypeAbstractSiegeWeapon);
   int enemyTotal   = getTotalEnemyMilPop();

   if (enemyTotal <= 0) { return; }

   // v1.4 BUG FIX: integer division davala vzdy 0 - bylo: enemyArchers/enemyTotal (int/int)
   gAdaptEnemyArcherRatio = xsIntToFloat(enemyArchers) / xsIntToFloat(enemyTotal);
   gAdaptEnemyMythRatio   = xsIntToFloat(enemyMyth)   / xsIntToFloat(enemyTotal);
   gAdaptEnemySiegeRatio  = xsIntToFloat(enemySiege)  / xsIntToFloat(enemyTotal);

   // Protiopatreni 1: hodne lucisniku nepritele -> zvysit hrdinsky podil (hrdinove jsou efektivni vs lucisnici)
   if (gAdaptEnemyArcherRatio > 0.40)
   {
      if (gArmyHeroPercentage < 0.35)
      {
         gArmyHeroPercentage = gArmyHeroPercentage + 0.05;
         debugStrategy("ADAPT: Detekovano hodne nepratelskych lucisniku, zvysuji gArmyHeroPercentage na " + gArmyHeroPercentage);
      }
   }
   // v2.1 BUG FIX: bylo 0.20 natvrdo - Titan/Legend tim padaly z bazovych 0.30 hrdinu zpet na 0.20.
   else if (gAdaptEnemyArcherRatio < 0.15 && gArmyHeroPercentage > baseHeroPercentage)
   {
      gArmyHeroPercentage = gArmyHeroPercentage - 0.02;
      if (gArmyHeroPercentage < baseHeroPercentage)
      {
         gArmyHeroPercentage = baseHeroPercentage;
      }
   }

   // Protiopatreni 2: hodne mytickych jednotek nepritele -> zvysit podil hrdinu (hrdinove jsou silni vs myticke)
   if (gAdaptEnemyMythRatio > 0.30)
   {
      if (gArmyHeroPercentage < 0.40)
      {
         gArmyHeroPercentage = gArmyHeroPercentage + 0.05;
         debugStrategy("ADAPT: Detekovano hodne nepratelskych mytickych, zvysuji hrdiny na " + gArmyHeroPercentage);
      }
   }

   // Protiopatreni 3: hodne oblehacich zbrani nepritele -> zvysit myticke (rychle jednotky rozbiji siege)
   if (gAdaptEnemySiegeRatio > 0.20)
   {
      if (gArmyLateGameMythPercentage < 0.40)
      {
         gArmyLateGameMythPercentage = gArmyLateGameMythPercentage + 0.05;
         debugStrategy("ADAPT: Detekovano hodne siege u nepritele, zvysuji myticke na " + gArmyLateGameMythPercentage);
      }
   }
   // v1.5 IMP: pridan decay - gArmyLateGameMythPercentage se drive nikdy nesnizoval zpet
   // bylo: zadne else/decay -> myticke % ratchetovalo nahoru a zustalo tam navzdy
   else if (gAdaptEnemySiegeRatio < 0.10 && gArmyLateGameMythPercentage > 0.30)
   {
      gArmyLateGameMythPercentage = gArmyLateGameMythPercentage - 0.02;
      debugStrategy("ADAPT v1.5: Malo siege u nepritele, snizuji myticke na " + gArmyLateGameMythPercentage);
   }

   // Omezeni: neprekrocit maximalni hodnoty
   if (gArmyHeroPercentage > 0.40) { gArmyHeroPercentage = 0.40; }
   if (gArmyHeroPercentage < baseHeroPercentage) { gArmyHeroPercentage = baseHeroPercentage; }
   if (gArmyLateGameMythPercentage > 0.40) { gArmyLateGameMythPercentage = 0.40; }
   if (gArmyEarlyGameMythPercentage > 0.30) { gArmyEarlyGameMythPercentage = 0.30; }
}

//------------------------------------------------------------------------------
// adaptAttackInterval
// Prizpusobi frekvenci utoku na zaklade uspesnosti a ztrat.
//------------------------------------------------------------------------------
void adaptAttackInterval()
{
   if (gAdaptAttackLaunched < 2) { return; } // Cekame na dostatek dat

   float successRate = 0.0;
   if (gAdaptAttackLaunched > 0)
   {
      // v1.4 BUG FIX: integer division davala 0 dokud successRate nebyl presne 100%
      // bylo: gAdaptAttackSucceeded / gAdaptAttackLaunched (int/int)
      successRate = xsIntToFloat(gAdaptAttackSucceeded) / xsIntToFloat(gAdaptAttackLaunched);
   }

   // Pokud mame >60% uspesnost -> utocime agresivneji (zkratit interval)
   if (successRate > 0.60 && gAdaptAttackIntervalBonus > -60)
   {
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus - 10;
      debugStrategy("ADAPT: Vysoka uspesnost utoku (" + successRate + "), zkracuji interval o 10s. Bonus=" + gAdaptAttackIntervalBonus);
   }
   // Pokud mame <30% uspesnost -> pockame dele (zvysit interval)
   else if (successRate < 0.30 && gAdaptAttackIntervalBonus < 120)
   {
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus + 15;
      debugStrategy("ADAPT: Nizka uspesnost utoku (" + successRate + "), zvysuji interval o 15s. Bonus=" + gAdaptAttackIntervalBonus);
   }

   // Aplikujeme bonus na aktualni interval
   int rawInterval = gAttackManager.mBaseAttackInterval + gAdaptAttackIntervalBonus;
   if (rawInterval < 30)  { rawInterval = 30;  } // Minimum 30s
   if (rawInterval > 600) { rawInterval = 600; } // Maximum 10 min
   gAttackManager.mAttackInterval = rawInterval;

   // v1.5 BUG FIX: bylo: prima modifikace mMinimumAttackSize, ale attackManager vola
   // calculateMinAttackSizes() kazdych 15s a prepisoval hodnotu - adaptivni nastaveni nikdy nefungovalo.
   // Oprava: misto prime modifikace pouzivame gAdaptMinAttackSizeBonus, ktery se pricte
   // v attackManager AZ po calculateMinAttackSizes().
   if (gAdaptAvgLossRate > 0.60)
   {
      if (gAdaptMinAttackSizeBonus < 15)  // cap: max +15 nad base
      {
         gAdaptMinAttackSizeBonus = gAdaptMinAttackSizeBonus + 5;
         debugStrategy("ADAPT v1.5: Vysoke ztraty (" + gAdaptAvgLossRate + "), zvysuji min. utok bonus na " + gAdaptMinAttackSizeBonus);
      }
   }
   else if (gAdaptAvgLossRate < 0.20 && gAdaptMinAttackSizeBonus > -5)
   {
      gAdaptMinAttackSizeBonus = gAdaptMinAttackSizeBonus - 2;
      debugStrategy("ADAPT v1.5: Nizke ztraty, snizuji min. utok bonus na " + gAdaptMinAttackSizeBonus);
   }
}

//------------------------------------------------------------------------------
// adaptAgeStrategy
// Reaguje na vekovy rozdil mezi AI a nepritelem.
//------------------------------------------------------------------------------
void adaptAgeStrategy()
{
   int myAge = kbPlayerGetAge(cMyID);
   int maxEnemyAge = 0;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      int eAge = kbPlayerGetAge(p);
      if (eAge > maxEnemyAge) { maxEnemyAge = eAge; }
   }

   int prevAdvantage = gAdaptAgeAdvantage;
   if (myAge > maxEnemyAge)      { gAdaptAgeAdvantage = 1; }
   else if (myAge < maxEnemyAge) { gAdaptAgeAdvantage = -1; }
   else                           { gAdaptAgeAdvantage = 0; }

   if (prevAdvantage != gAdaptAgeAdvantage)
   {
      // v1.5 IMP: undo predchozi prispevek pred aplikaci noveho.
      // Bylo: delta se pridavala bez undo -> bonus se hromadil pres vice age transitions
      // (napr.: napred(-30), zrovna(0), pozadu(+45), zrovna(0) = net+15 misto 0).
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus - gAdaptAgeBonus;

      if (gAdaptAgeAdvantage == 1)
      {
         gAdaptAgeBonus = -30;
         debugStrategy("ADAPT v1.5: Jsme napred ve veku! Zvysuji agresivitu (interval " + gAdaptAgeBonus + "s).");
      }
      else if (gAdaptAgeAdvantage == -1)
      {
         gAdaptAgeBonus = 45;
         debugStrategy("ADAPT v1.5: Jsme pozadu ve veku! Snizuji agresivitu (interval +" + gAdaptAgeBonus + "s).");
      }
      else
      {
         gAdaptAgeBonus = 0;
         debugStrategy("ADAPT v1.5: Vekovy naskok vyrovnan, vekovy bonus nulovan.");
      }
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus + gAdaptAgeBonus;
   }
}

//------------------------------------------------------------------------------
// trackAttackResult
// Volat pred zahajenim a po skonceni utoku pro sledovani vysledku.
//------------------------------------------------------------------------------
void trackAttackStart()
{
   gAdaptLastWaveStartPop = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive); // Celkova vojenska populace pri odeslani
   gAdaptAttackLaunched++;
   // v1.6 BUG FIX: zaznamenat pocet nepratelskych budov pro vyhodnoceni uspesnosti utoku
   // bylo: trackAttackEnd(true) se volal hned pri odeslani -> success vzdy 100%
   gAdaptAttackEnemyBuildingsAtStart = 0;
   int targetPlayer = aiGetMostHatedPlayerID();
   if (targetPlayer > 0)
   {
      gAdaptAttackEnemyBuildingsAtStart = kbUnitCount(cUnitTypeBuilding, targetPlayer, cUnitStateAlive);
   }
   gAdaptAttackInProgress = true;
   debugStrategy("ADAPT v1.6: Zahajuji sledovani utoku #" + gAdaptAttackLaunched +
      ", startPop=" + gAdaptLastWaveStartPop + ", enemyBuildings=" + gAdaptAttackEnemyBuildingsAtStart);
}

// v1.6: trackAttackEnd je nyni volano az z pravidla adaptiveAttackResultMonitor, ne ihned po odeslani.
void trackAttackEnd(bool success = false)
{
   gAdaptAttackInProgress = false;
   int currentPop = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive);
   int losses = gAdaptLastWaveStartPop - currentPop;
   if (losses < 0) { losses = 0; }
   gAdaptLastWaveLossPop = losses;

   float lossRate = 0.0;
   if (gAdaptLastWaveStartPop > 0)
   {
      lossRate = xsIntToFloat(losses) / xsIntToFloat(gAdaptLastWaveStartPop);
   }
   gAdaptAvgLossRate = (gAdaptAvgLossRate * 0.7) + (lossRate * 0.3);

   if (success)
   {
      gAdaptAttackSucceeded++;
      debugStrategy("ADAPT v1.6: Utok uspesny! Ztraty=" + losses + " (" + lossRate + "), avgLoss=" + gAdaptAvgLossRate);
   }
   else
   {
      gAdaptAttackFailed++;
      debugStrategy("ADAPT v1.6: Utok neuspesny! Ztraty=" + losses + " (" + lossRate + "), avgLoss=" + gAdaptAvgLossRate);
   }
}

//------------------------------------------------------------------------------
// rule adaptiveAttackResultMonitor - v1.6
// Sleduje probiha jici utok a vola trackAttackEnd se spravnym vysledkem
// az kdyz armada prestane utocit (vrati se nebo je znicena).
// Uspech = nepritele ubylo budov. Neuspech = armada se vratila bez ztraty budov.
//------------------------------------------------------------------------------
rule adaptiveAttackResultMonitor
inactive
group defaultClassicalRules
minInterval 10
{
   if (gAdaptAttackInProgress == false) { return; }

   // Zjistime zda stale bezi nejaky utocny plan
   bool stillAttacking = false;
   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   for (int i = 0; i < attackPlans.size(); i++)
   {
      if (aiPlanGetParentID(attackPlans[i]) == -1)
      {
         stillAttacking = true;
         break;
      }
   }

   if (stillAttacking == true) { return; } // Armada stale pochoduje, cekame

   // Utok skoncil - vyhodnotime vysledek
   // v2.5 BUG31 FIX: bylo aiGetMostHatedPlayerID() - cil se muze zmenit behem utoku (eliminace, FFA prepnuti)
   // Pouzivame gAdaptTrackTargetPlayerID ktery byl ulozen pri zahajeni utoku (v military_attack.xs)
   int trackedTarget = gAdaptTrackTargetPlayerID;

   // Specialni pripad: cil byl eliminovan behem utoku = jednoznacny uspech!
   if (trackedTarget > 0 && kbPlayerHasLost(trackedTarget) == true)
   {
      debugStrategy("ADAPT v2.5: Cilovy hrac " + trackedTarget + " byl eliminovan behem utoku - uspech!");
      trackAttackEnd(true);
      return;
   }

   int enemyBuildingsNow = 0;
   if (trackedTarget > 0)
   {
      enemyBuildingsNow = kbUnitCount(cUnitTypeBuilding, trackedTarget, cUnitStateAlive);
   }
   bool success = (enemyBuildingsNow < gAdaptAttackEnemyBuildingsAtStart);
   trackAttackEnd(success);
}

//==============================================================================
// SEKCE 3 - Pravidla (rules) - automaticky se spousteji
//==============================================================================

//------------------------------------------------------------------------------
// adaptiveLearningMonitor - hlavni smycka adaptivniho systemu
// Spousti se kazdych 30 sekund po prechodu do Classical veku.
//------------------------------------------------------------------------------
rule adaptiveLearningMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   debugStrategy("--- ADAPT: Running adaptiveLearningMonitor ---");
   adaptArmyComposition();
   adaptAttackInterval();
   adaptAgeStrategy();

   // v1.8: decay counter ratio kdyz nejsme pod utokem - zabranova prilis trvale zmene slozeni armady
   if (gDefenseReflex == false && gDefenseReflexPanic == false)
   {
      gAdaptEnemyAttackRangedRatio = gAdaptEnemyAttackRangedRatio * 0.85;
      gAdaptEnemyAttackMeleeRatio  = gAdaptEnemyAttackMeleeRatio  * 0.85;
      gAdaptEnemyAttackMythRatio   = gAdaptEnemyAttackMythRatio   * 0.85;
      gAdaptEnemyAttackSiegeRatio  = gAdaptEnemyAttackSiegeRatio  * 0.85;

      // v2.1: decay counter-forced composition back to baseline after pressure ends.
      float baseHeroPercentage = 0.30;
      if (cDifficultyCurrent <= cDifficultyHard)
      {
         baseHeroPercentage = 0.20;
      }
      if (gAdaptEnemyAttackMythRatio < 0.20 && gAdaptEnemyAttackRangedRatio < 0.25 &&
          gArmyHeroPercentage > baseHeroPercentage)
      {
         gArmyHeroPercentage = gArmyHeroPercentage - 0.02;
         if (gArmyHeroPercentage < baseHeroPercentage)
         {
            gArmyHeroPercentage = baseHeroPercentage;
         }
      }
      if (gAdaptEnemyAttackSiegeRatio < 0.15 && gArmyLateGameMythPercentage > 0.30)
      {
         gArmyLateGameMythPercentage = gArmyLateGameMythPercentage - 0.02;
         if (gArmyLateGameMythPercentage < 0.30)
         {
            gArmyLateGameMythPercentage = 0.30;
         }
      }
   }
}

//------------------------------------------------------------------------------
// adaptiveWallDetection - detekuje hradby nepritele a prizpusobuje podil siege
//------------------------------------------------------------------------------
rule adaptiveWallDetection
inactive
group defaultClassicalRules
minInterval 60
{
   int totalEnemyWalls = 0;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      totalEnemyWalls += kbUnitCount(cUnitTypeWallLong, p, cUnitStateAlive);  // v1.6.4 fix: cUnitTypeWall neexistuje
      totalEnemyWalls += kbUnitCount(cUnitTypeWallGate, p, cUnitStateAlive); // v1.6.4 fix: cUnitTypeFortification neexistuje
   }

   if (totalEnemyWalls != gAdaptEnemyWallCount)
   {
      gAdaptEnemyWallCount = totalEnemyWalls;
      if (totalEnemyWalls > 20)
      {
         // Hodne hradeb -> vice siege k prolomeni obrany
         if (gArmySiegePercentage < 0.25)
         {
            gArmySiegePercentage = gArmySiegePercentage + 0.03;
            debugStrategy("ADAPT: Nepritel ma " + totalEnemyWalls + " hradeb, zvysuji siege na " + gArmySiegePercentage);
         }
      }
      else if (totalEnemyWalls < 5 && gArmySiegePercentage > 0.12)
      {
         gArmySiegePercentage = gArmySiegePercentage - 0.02;
      }
      if (gArmySiegePercentage > 0.30) { gArmySiegePercentage = 0.30; }
   }
}

//------------------------------------------------------------------------------
// adaptCounterComposition - v1.7
// Analyzuje slozeni nepritelske utocici armady blizko nasi zakladny
// a prizpusobuje vlastni slozeni armady pro efektivni counter.
//------------------------------------------------------------------------------
void adaptCounterComposition()
{
   if (kbBaseGetNumber(cMyID) <= 0) { return; }
   vector baseLocation = kbBaseGetLocation(cMyID, kbBaseGetIDByIndex(cMyID, 0));

   // Hledej nepratelske vojenske jednotky v okruhu 60 jednotek od nasi zakladny
   int qID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary,
      cPlayerRelationEnemyNotGaia, cUnitStateAlive, baseLocation, 60.0);
   int numEnemies = kbUnitQueryExecute(qID);
   if (numEnemies < 5) { return; } // Prilis malo jednotek - neni pruhledny utok

   int[] units = kbUnitQueryGetResults(qID);
   int attackRanged = 0;
   int attackMelee  = 0;
   int attackMyth   = 0;
   int attackSiege  = 0;

   for (int i = 0; i < numEnemies; i++)
   {
      int puid = kbUnitGetProtoUnitID(units[i]);
      if (kbProtoUnitIsType(puid, cUnitTypeMythUnit) == true)
         attackMyth++;
      else if (kbProtoUnitIsType(puid, cUnitTypeAbstractSiegeWeapon) == true)
         attackSiege++;
      else if (kbProtoUnitIsType(puid, cUnitTypeLogicalTypeRangedUnitsAttack) == true)
         attackRanged++;
      else
         attackMelee++;
   }

   // Klouzavy prumer ratio (70% stara hodnota, 30% nova) - stabilni reakce bez trhanek
   float invN = xsIntToFloat(numEnemies);
   gAdaptEnemyAttackRangedRatio = (gAdaptEnemyAttackRangedRatio * 0.7) + (xsIntToFloat(attackRanged) / invN * 0.3);
   gAdaptEnemyAttackMeleeRatio  = (gAdaptEnemyAttackMeleeRatio  * 0.7) + (xsIntToFloat(attackMelee)  / invN * 0.3);
   gAdaptEnemyAttackMythRatio   = (gAdaptEnemyAttackMythRatio   * 0.7) + (xsIntToFloat(attackMyth)   / invN * 0.3);
   gAdaptEnemyAttackSiegeRatio  = (gAdaptEnemyAttackSiegeRatio  * 0.7) + (xsIntToFloat(attackSiege)  / invN * 0.3);

   // v2.9 IMP12: Counter logika zmenena z exkluzivniho if/else if na nezavisle bloky.
   // Bylo: pouze JEDEN counter se aplikoval. Kdyz nepritel poslal 40% myth + 30% siege,
   // jen anti-myth (hero+) se aktivoval; anti-siege (myth+) zustal ignorovan.
   // Nyni: kazdy counter se vyhodnocuje nezavisle se zmensenym krokem (0.04 misto 0.08)
   // aby se mohly stackovat bez prekoreceni.
   if (gAdaptEnemyAttackMythRatio > 0.35)
   {
      // Hodne mytickych -> zvysit hrdiny (hrdinove jsou anti-myth)
      if (gArmyHeroPercentage < 0.40)
         gArmyHeroPercentage = gArmyHeroPercentage + 0.04; // bylo 0.08
      if (gArmyHeroPercentage > 0.40) { gArmyHeroPercentage = 0.40; }
      debugStrategy("ADAPT v2.9: Counter myth utok (" + gAdaptEnemyAttackMythRatio + ") - hero% " + gArmyHeroPercentage);
   }
   if (gAdaptEnemyAttackRangedRatio > 0.40)
   {
      // Hodne lucisniku -> zvysit hrdiny (efektivni vs ranged)
      if (gArmyHeroPercentage < 0.35)
         gArmyHeroPercentage = gArmyHeroPercentage + 0.03; // bylo 0.05
      if (gArmyHeroPercentage > 0.40) { gArmyHeroPercentage = 0.40; }
      debugStrategy("ADAPT v2.9: Counter ranged utok (" + gAdaptEnemyAttackRangedRatio + ") - hero% " + gArmyHeroPercentage);
   }
   if (gAdaptEnemyAttackSiegeRatio > 0.25)
   {
      // Hodne siege -> zvysit myticke (rychle, dobre vs oblehaci)
      if (gArmyLateGameMythPercentage < 0.40)
         gArmyLateGameMythPercentage = gArmyLateGameMythPercentage + 0.03; // bylo 0.05
      if (gArmyLateGameMythPercentage > 0.40) { gArmyLateGameMythPercentage = 0.40; }
      debugStrategy("ADAPT v2.9: Counter siege utok (" + gAdaptEnemyAttackSiegeRatio + ") - myth% " + gArmyLateGameMythPercentage);
   }
   if (gAdaptEnemyAttackMeleeRatio > 0.60)
   {
      // Prevazne melee -> zvysit siege (oblehaci stroje jsou anti-melee)
      if (gArmySiegePercentage < 0.25)
         gArmySiegePercentage = gArmySiegePercentage + 0.03;
      debugStrategy("ADAPT v2.9: Counter melee utok (" + gAdaptEnemyAttackMeleeRatio + ") - siege% " + gArmySiegePercentage);
   }
}

//------------------------------------------------------------------------------
// adaptiveIncomingAttackMonitor - v1.7
// Aktivuje counter detekci kdyz jsme v obranne situaci.
//------------------------------------------------------------------------------
rule adaptiveIncomingAttackMonitor
inactive
group defaultClassicalRules
minInterval 15
{
   // Spustit pouze kdyz nepritel fakticky utoci na nasi zakladnu
   if (gDefenseReflex == false && gDefenseReflexPanic == false) { return; }
   adaptCounterComposition();
}

//------------------------------------------------------------------------------
// adaptiveEcoPressureMonitor - detekuje ztraty vesnicanu a prepina na obranny mod
//------------------------------------------------------------------------------
rule adaptiveEcoPressureMonitor
inactive
group defaultClassicalRules
minInterval 45
{
   int currentEcoPop = kbUnitCount(gEconUnit, cMyID, cUnitStateAlive);
   int ecoDrop = gAdaptLastEcoCheckPop - currentEcoPop;

   if (gAdaptLastEcoCheckPop > 0 && ecoDrop > 3)
   {
      // Ztratili jsme 3+ vesnicany za 45s -> jsme pod ekonomickym tlakem
      if (gAdaptEcoUnderPressure == false)
      {
         gAdaptEcoUnderPressure = true;
         // Prodlouzit utocny interval - soustredit se na obranu
         gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus + 60;
         debugStrategy("ADAPT: Ekonomicky tlak detekovan! Ztrata " + ecoDrop + " vesnicanu. Prepinam na obranny mod (+60s interval).");
      }
   }
   else if (gAdaptEcoUnderPressure == true && ecoDrop <= 0)
   {
      gAdaptEcoUnderPressure = false;
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus - 60;
      debugStrategy("ADAPT: Ekonomicky tlak pominul, vracim se do utocneho modu.");
   }
   gAdaptLastEcoCheckPop = currentEcoPop;
}

// --- Totalni obranny mod (deklarace predem - pouzivano drive nez v SEKCI 4) ---
extern bool gAdaptTotalDefenseMode = false; // True pokud je AI v totalnim obrannem modu (ztraty >90%)
extern int  gAdaptTotalDefenseModeStart = 0;

//------------------------------------------------------------------------------
// adaptiveResourceSurplusAttack
// Pokud mame velky prebytek zdroju -> okamzity utok bez cekani na interval
//------------------------------------------------------------------------------
rule adaptiveResourceSurplusAttack
inactive
group defaultClassicalRules
minInterval 20
{
   if (checkStrategyFlag(cStrategyFlagCanAttack) == false) { return; }
   if (gAdaptTotalDefenseMode == true) { return; } // v2.4 IMP1: pri katastrofalnich ztratach neutocit ani pri prebytku zdroju

   // v1.4 BUG FIX: kbGetResourceAmountAvailable vraci mnozstvi v mapovych nodech (ne banku AI!)
   // bylo: kbGetResourceAmountAvailable - spravne: kbResourceGet (aktualni zasoba AI)
   float food = kbResourceGet(cResourceFood);
   float wood = kbResourceGet(cResourceWood);
   float gold = kbResourceGet(cResourceGold);

   // v1.4 ZLEPSENI: snizen prah z 2000 -> 1200; s market-sellingem z v1.3 se 2000 skoro nedosahne.
   // Take zmeneno na OR logiku pro gold: utocime pokud mame hodne zlata (klicovy zdroj) i bez prebytku jidla/dreva.
   if ((food > 1200.0 && wood > 1200.0 && gold > 800.0) || (gold > 2000.0))
   {
      // v2.9 BUG36 FIX: bylo aiPlanGetCurrentPopulation(gPrimaryLandDefendPlan) — vzdy ~0 kdyz probiha utok
      // (jednotky prevedeny do utocneho planu). Surplus attack se nikdy nespustil v mid/late game.
      // Oprava: merime celkovy pocet zivych pozemnich vojaku (stejne jako BUG29 fix v tryLaunchSecondFront).
      int armyPop = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive);
      if (armyPop >= gAttackManager.mMinimumAttackSize)
      {
         debugStrategy("ADAPT: Prebytek zdroju F=" + food + " W=" + wood + " G=" + gold + " - vynucuji okamzity utok!");
         // Zkratime cas posledniho utoku abychom prosli casovym checkem
         gAttackManager.mLastAttackTime = 0;
         xsRuleIgnoreIntervalOnce("attackManager");
      }
   }
}

//==============================================================================
// SEKCE 4 - Nove funkce a pravidla v1.2
//==============================================================================

// --- Rush detekce ---
extern bool gAdaptRushDetected    = false; // True pokud nepritel rushuje v early game
extern int  gAdaptRushDetectedTime = 0;   // Cas kdy byl rush detekovan
// gAdaptTotalDefenseMode + gAdaptTotalDefenseModeStart deklarovany drive (pred adaptiveResourceSurplusAttack)

//------------------------------------------------------------------------------
// adaptFailSafe - v1.2
// Ochrana pred extremnimi hodnotami adaptivniho systemu.
//------------------------------------------------------------------------------
void adaptFailSafe()
{
   // Omezit interval bonus na rozumny rozsah
   if (gAdaptAttackIntervalBonus < -90)
   {
      gAdaptAttackIntervalBonus = -90;
      debugStrategy("ADAPT v1.2: gAdaptAttackIntervalBonus oriznuto na -90 (ochrana proti spam utokum).");
   }
   if (gAdaptAttackIntervalBonus > 180)
   {
      gAdaptAttackIntervalBonus = 180;
      debugStrategy("ADAPT v1.2: gAdaptAttackIntervalBonus oriznuto na 180 (ochrana proti pasivite).");
   }

   // Totalni obranny mod pri katastrofalnich ztratach
   if (gAdaptAvgLossRate > 0.90 && gAdaptTotalDefenseMode == false)
   {
      gAdaptTotalDefenseMode = true;
      gAdaptTotalDefenseModeStart = xsGetTime();
      gAdaptAttackIntervalBonus = 180; // Max pauza
      debugStrategy("ADAPT v1.2: Katastrofalni ztraty! Prechod do totalniho obranneho modu na 3 minuty.");
   }
   // Opustit totalni obranny mod po 3 minutach
   if (gAdaptTotalDefenseMode == true && (xsGetTime() - gAdaptTotalDefenseModeStart) > 180000)
   {
      gAdaptTotalDefenseMode = false;
      gAdaptAttackIntervalBonus = 60; // Opatrny restart
      debugStrategy("ADAPT v1.2: Totalni obranny mod ukoncen, opatrne restartuji utoky.");
   }
}

//------------------------------------------------------------------------------
// adaptRushDetection - v1.2
// Detekuje nepratelsky rush v prvnich 8 minutach a reaguje.
//------------------------------------------------------------------------------
void adaptRushDetection()
{
   // Rush detekujeme pouze v prvnich 8 minutach hry
   if (xsGetTime() > 480000) { return; }
   if (gAdaptRushDetected == true) { return; }

   // Rush = nepritel ma vojenske jednotky blizko nasi zakladny v early game
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID == -1) { return; }

   vector mainBaseLoc = kbBaseGetLocation(cMyID, mainBaseID);
   float rushScanRadius = 60.0;

   static int rushQuery = -1;
   if (rushQuery < 0)
   {
      rushQuery = kbUnitQueryCreate("adaptRushDetection query");
      kbUnitQuerySetPlayerRelation(rushQuery, cPlayerRelationEnemyNotGaia);
      kbUnitQuerySetUnitType(rushQuery, cUnitTypeLogicalTypeLandMilitary);
      kbUnitQuerySetState(rushQuery, cUnitStateAlive);
      kbUnitQuerySetVisibleState(rushQuery, cUnitQueryVisibleStateVisible);
   }
   kbUnitQuerySetPosition(rushQuery, mainBaseLoc);
   kbUnitQuerySetMaximumDistance(rushQuery, rushScanRadius);
   kbUnitQueryResetResults(rushQuery);
   int numRushers = kbUnitQueryExecute(rushQuery);

   if (numRushers >= 4) // 4+ vojaci u nasi zakladny = rush
   {
      gAdaptRushDetected = true;
      gAdaptRushDetectedTime = xsGetTime();
      // Reakce: zkratit interval utoku - vratit uder co nejdriv
      gAdaptAttackIntervalBonus = gAdaptAttackIntervalBonus - 45;
      debugStrategy("ADAPT v1.2: RUSH DETEKOVAN! " + numRushers + " nepratelskych vojaku u zakladny. Zkracuji utocny interval o 45s!");
      aiEchoWarning("ADAPT v1.2: Rush detekovan!");
   }
}

// v2.5 BUG32 FIX (final): adaptAgeResourceShift() a rule adaptiveAgeResourceShift odstranovany.
// Puvodni problem: staticke procento jidla (60%/45%/35%...) predavane do
// aiNormalizeResourcePercentages() zpusobovalo, ze engine priradil vice sberacu na farmy
// nez je dostupnych faremnich budov (1 sberac/farma max) -> spam hlasek
// "Z Farma se muze najednou shromadzit pouze 1 jednotek" v kazde hre.
// Prvni pokus o opravu (spustit jen pri zmene veku, v2.5 BUG32 rev1) tez nestacil - i jedno
// spusteni generovalo burst zprav pro vsechny zbytecne sberace.
// Skutecna oprava: economy.xs:updateResourceDistribution() uz obsahuje sofistikovanou
// dynamickou alokaci (pocita food/wood/gold/favor% podle aktualnich zdroju a nedostatku).
// Nase staticke hodnoty jsou horsi nez dynamicka logika economy.xs A zaroven ji rusily.
// Reseni: odstranit vsechny nase volani aiSetResourcePercentage/aiNormalizeResourcePercentages
// a nechat economy.xs ridit rozdeleni zdroju sam.

//------------------------------------------------------------------------------
// rule adaptiveLearningMonitorV12 - rozsireni monitoru o v1.2 funkce
//------------------------------------------------------------------------------
rule adaptiveLearningMonitorV12
inactive
group defaultArchaicRules
minInterval 15
{
   adaptFailSafe();
   adaptRushDetection();
}

//------------------------------------------------------------------------------
// rule adaptiveEmergencyMarketSell - v1.3
// Kdyz je AI v gAdaptTotalDefenseMode (ztraty >90%), proda prebytecne jidlo/drevo
// na trhu pro rychly prijem zlata na prestavbu armady.
// Vyzaduje existenci trhu (gMarketUnit). Bezi kazdych 10s v Classicalu.
//------------------------------------------------------------------------------
rule adaptiveEmergencyMarketSell
inactive
group defaultClassicalRules
minInterval 10
{
   if (gAdaptTotalDefenseMode == false)
   {
      return;
   }
   if (kbUnitCount(gMarketUnit, cMyID, cUnitStateAlive) == 0)
   {
      return;
   }
   // Prodej prebytecne jidlo za zlato pokud mame vice nez 400 jednotek.
   if (kbResourceGet(cResourceFood) > 400.0)
   {
      aiSellResourceOnMarket(cResourceFood);
      debugStrategy("ADAPT v1.3 EmergencyMarket: prodavame jidlo za zlato (TotalDefenseMode)");
   }
   // Prodej prebytecne drevo za zlato pokud mame vice nez 400 jednotek.
   if (kbResourceGet(cResourceWood) > 400.0)
   {
      aiSellResourceOnMarket(cResourceWood);
      debugStrategy("ADAPT v1.3 EmergencyMarket: prodavame drevo za zlato (TotalDefenseMode)");
   }
}

//------------------------------------------------------------------------------
// priestConvertAnimalsMonitor - v2.8 (v2.9 BUG37 FIX)
// Egyptsti knezi konvertuji neutralni lovena zvirata (Mother Nature) pobliz nasi zakladny.
// Konvertovane zvirata se stanou herdable a existujici moveHerdablesToBase je dotahne k TC.
// Funguje pouze pro Egyptian kulturu - ostatni se pravidlo okamzite vypne.
//------------------------------------------------------------------------------
// v2.9 BUG37 FIX: staticke promenne pro sledovani aktivniho tasku.
// Bylo: aiTaskWorkUnit se volal kazych 10s bez kontroly — prepisoval probihajici konverzi
// a potencialne resetoval konverzni animaci, coz zpusobovalo nekonecnou smycku.
int gConvertLastPriestID = -1;
int gConvertLastAnimalID = -1;

rule priestConvertAnimalsMonitor
inactive
group defaultArchaicRules
minInterval 10
{
   if (cMyCulture != cCultureEgyptian)
   {
      xsDisableRule("priestConvertAnimalsMonitor");
      return;
   }

   // Nerusit kneze pri aktivni obrane
   if (gDefenseReflex == true || gDefenseReflexPanic == true) { return; }

   // v2.9 BUG37 FIX: Kontrola zda posledni prirazeny knez stale konvertuje stejne zvire.
   // Pokud ano, nedelej nic — neprerusuj probihajici konverzi.
   if (gConvertLastPriestID != -1 && gConvertLastAnimalID != -1)
   {
      bool priestAlive = kbUnitGetIsIDValid(gConvertLastPriestID);
      // Zvire stale Mother Nature a alive = konverze jeste neskoncila
      bool animalStillWild = false;
      if (kbUnitGetIsIDValid(gConvertLastAnimalID) == true)
      {
         animalStillWild = (kbUnitGetPlayerID(gConvertLastAnimalID) == cPlayerMotherNatureID);
      }
      if (priestAlive == true && animalStillWild == true)
      {
         // Knez zije a zvire je stale neutralni — konverze pravdepodobne probiha, preskakujeme.
         debugStrategy("ADAPT v2.9: Knez " + gConvertLastPriestID + " stale konvertuje zvire " + gConvertLastAnimalID + ", preskakuji.");
         return;
      }
      // Konverze skoncila (zvire skonvertovano, zemrelo, nebo knez zemrel).
      // Vrat kneze zpet do defend planu pokud jeste zije a neni v zadnem planu.
      if (priestAlive == true)
      {
         int currentPlan = kbUnitGetPlanID(gConvertLastPriestID);
         if (currentPlan == -1 && aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == true)
         {
            aiPlanAddUnit(gPrimaryLandDefendPlan, gConvertLastPriestID);
            debugStrategy("ADAPT v2.9: Konverze hotova, knez " + gConvertLastPriestID + " vracen do defend planu.");
         }
      }
      gConvertLastPriestID = -1;
      gConvertLastAnimalID = -1;
   }

   // Najdi hlavni zakladnu
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID == -1) { return; }
   vector basePos = kbBaseGetLocation(cMyID, mainBaseID);

   // Najdi nejblizsi nekonvertovane lovene zvire pobliz nasi zakladny (owner = Mother Nature)
   int animalID = getClosestUnitByLocation(cUnitTypeHuntable, cPlayerMotherNatureID, cUnitStateAlive, basePos, 60.0);
   if (animalID == -1)
   {
      debugStrategy("ADAPT v2.9: Zadne huntable zvirata v dosahu 60 od zakladny.");
      return;
   }

   // Preferuj kneze z defend planu (nechceme brat obranare kdyz neni treba)
   int priestID = -1;
   int[] defenders = aiPlanGetUnits(gPrimaryLandDefendPlan, cUnitTypePriest);
   for (int pi = 0; pi < defenders.size(); pi++)
   {
      int pid = defenders[pi];
      if (kbUnitGetIsIDValid(pid) == false) { continue; }
      // Preskoc kneze kteri jsou v boji nebo maji pobliz nepratele
      if (getUnitCountByLocation(cUnitTypeMilitaryUnit, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
            kbUnitGetPosition(pid), 20.0, cUnitQueryVisibleStateVisible) > 0) { continue; }
      priestID = pid;
      break;
   }

   // Fallback: prvni zijici knez v dosahu zakladny (treba jeste neni v defend planu - early game)
   if (priestID == -1)
   {
      int qID = useSimpleUnitQuery(cUnitTypePriest, cMyID, cUnitStateAlive, basePos, 80.0);
      int n = kbUnitQueryExecute(qID);
      for (int pi = 0; pi < n; pi++)
      {
         int pid = kbUnitQueryGetResult(qID, pi);
         if (kbUnitGetIsIDValid(pid) == false) { continue; }
         if (getUnitCountByLocation(cUnitTypeMilitaryUnit, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
               kbUnitGetPosition(pid), 20.0, cUnitQueryVisibleStateVisible) > 0) { continue; }
         priestID = pid;
         break;
      }
   }

   if (priestID == -1)
   {
      debugStrategy("ADAPT v2.9: Zadny volny knez pro konverzi zvire.");
      return;
   }

   debugStrategy("ADAPT v2.9: Knez " + priestID + " konvertuje zvire " + animalID + " (pos " + kbUnitGetPosition(animalID) + ").");
   // v2.9 BUG38 FIX: odebrat kneze z defend planu pred tasknutim.
   // Bylo: knez zustal v gPrimaryLandDefendPlan → plan ho kazdy tick pretahoval zpet na gather point
   // a prepisoval aiTaskWorkUnit prikaz → konverze se nikdy nedokoncila.
   // Oprava: odebrat z planu → knez je volny pro konverzi → po dokonceni ho vratime zpet (viz nahore).
   int priestPlanID = kbUnitGetPlanID(priestID);
   if (priestPlanID != -1)
   {
      aiPlanRemoveUnit(priestPlanID, priestID);
      debugStrategy("ADAPT v2.9: Knez " + priestID + " odebran z planu " + priestPlanID + " pro konverzi.");
   }
   aiTaskWorkUnit(priestID, animalID);
   // v2.9 BUG37 FIX: zapamatuj si prirazeni aby se neprepisovalo priste
   gConvertLastPriestID = priestID;
   gConvertLastAnimalID = animalID;
}
