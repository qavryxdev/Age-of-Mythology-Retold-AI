//==============================================================================
/* ai_improvements_v34.xs  -  v3.4 - ISLAND ESCAPE FIX

   BUG FIX: AI zustava trvale uveznena na startovnim ostrove.

   Root cause:
   - gMapInfo.mShouldBuildDock se nastavuje JEDNOU pri startu na zaklade
     mStartOnDifferentIslands (tj. kdyz vsichni hraci NESTARTUJI ve stejne zone)
   - Pokud vsichni startuji v jedne zone na vetsim ostrove, ale mapa MA voda
     a enemy je dosazitelny pouze pres vodu (po explorace), AI nikdy nepostavi dock
   - exploration.xs:398-400 skautuje jine ostrovy jen pri mIsIslandMap == true
   - naval_military.xs:314 navalMonitor() vrati se pokud mShouldBuildDock == false

   Fix strategie:
   1. Periodicky (45s) detekovat: maji enemy hraci NA STEJNEM area group jako my?
   2. Pokud NEMAJI enemy v naseho area group + mapa ma vodu -> force mShouldBuildDock = true
   3. Re-enable navalMonitor + analyseNavalPositions runtime
   4. Force exploration of other islands
*/
//==============================================================================

//==============================================================================
// SEKCE 1 - Globaly
//==============================================================================
extern bool gIslandEscapeTriggered = false;
extern int  gIslandEscapeCheckTime = 0;
extern int  gLastIslandEscapeRetry = 0;

//==============================================================================
// SEKCE 2 - Detekce
//==============================================================================

//------------------------------------------------------------------------------
// areAnyEnemiesReachableByLand
// Vraci true pokud aspon jeden zivy enemy je v nasem area group (tj. ma land
// path k nam). Vraci false pokud vsichni enemy jsou na jinem area group nebo
// nejsou viditelni.
//------------------------------------------------------------------------------
bool areAnyEnemiesReachableByLand()
{
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return true; } // Bez baze nelze rozhodnout, fail safe

   vector myBase = kbBaseGetLocation(cMyID, mainBaseID);
   int myAreaGroup = kbAreaGroupGetIDByPosition(myBase);

   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }

      int eMainID = kbBaseGetMainID(p);
      if (eMainID < 0) { continue; }
      vector ePos = kbBaseGetLocation(p, eMainID);
      int eAreaGroup = kbAreaGroupGetIDByPosition(ePos);

      // Stejna area group = land path existuje
      if (eAreaGroup == myAreaGroup)
      {
         return true;
      }
   }
   return false; // Vsichni viditelni enemy jsou na jinem area group
}

//==============================================================================
// SEKCE 3 - Trigger island escape
//==============================================================================

//------------------------------------------------------------------------------
// triggerIslandEscape
// Force enable naval logiku: nastavi mShouldBuildDock, znovu spusti
// analyseNavalPositions a navalMonitor.
//------------------------------------------------------------------------------
void triggerIslandEscape()
{
   if (gMapInfo.mHasWater == false)
   {
      // Mapa nema vodu - nelze postavit dock, jsme bezndejne uvezneni
      debugStrategy("ISLAND ESCAPE: map has no water, cannot escape - stuck");
      return;
   }

   if (gMapInfo.mShouldBuildDock == false)
   {
      gMapInfo.mShouldBuildDock = true;
      debugStrategy("ISLAND ESCAPE: forcing mShouldBuildDock = true");
   }

   // Force naval analysis (najde shoreline + water defend point)
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID >= 0)
   {
      vector myBase = kbBaseGetLocation(cMyID, mainBaseID);
      int landAreaID = kbAreaGetIDByPosition(myBase);
      analyseNavalPositions(landAreaID);
      debugStrategy("ISLAND ESCAPE: re-running analyseNavalPositions for land area " + landAreaID);
   }

   // Re-enable navalMonitor pokud byl vypnut
   xsEnableRule("navalMonitor");
   xsRuleIgnoreIntervalOnce("navalMonitor");

   // Boost build dock priority pres existujici building logic
   if (gMilitaryUrgency < 0.5) { gMilitaryUrgency = 0.5; }

   // Ekonomicky tlak - prepnout do agresivni naval expanze
   if (gAdaptAttackIntervalBonus > 0)
   {
      gAdaptAttackIntervalBonus = 0;
   }

   gIslandEscapeTriggered = true;
   gLastIslandEscapeRetry = xsGetTime();
   aiEchoWarning("ISLAND ESCAPE: stuck on island detected - building dock + naval forces");
}

//------------------------------------------------------------------------------
// rule islandEscapeMonitor
// Kazdych 45s zkontroluje, zda nejsme uvezneni. Pokud ano, force naval logiku.
// Re-trigger kazdych 90s pokud stale uvezneni (engine moze potrebovat pripomenuti
// pri opakovanych failech build planu).
//------------------------------------------------------------------------------
rule islandEscapeMonitor
inactive
group defaultArchaicRules
minInterval 45
{
   int now = xsGetTime();
   gIslandEscapeCheckTime = now;

   bool reachable = areAnyEnemiesReachableByLand();
   if (reachable == true)
   {
      // OK - mame enemy v nasem area group, neuviznuti
      if (gIslandEscapeTriggered == true)
      {
         debugStrategy("ISLAND ESCAPE: enemies now reachable by land - mode deactivated");
         gIslandEscapeTriggered = false;
      }
      return;
   }

   // Vsichni enemy jsou nedosazitelni po zemi
   if (gIslandEscapeTriggered == false)
   {
      // Prvni detekce - spustit
      triggerIslandEscape();
      return;
   }

   // Uz triggered - retry kazdych 90s pokud stale uvezneni
   if ((now - gLastIslandEscapeRetry) > 90000)
   {
      // Check: postavili jsme dock?
      int dockCount = kbUnitCount(cUnitTypeDock, cMyID, cUnitStateAlive);
      int dockBuilding = kbUnitCount(cUnitTypeDock, cMyID, cUnitStateBuilding);

      if (dockCount == 0 && dockBuilding == 0)
      {
         debugStrategy("ISLAND ESCAPE: still no dock 90s after trigger - retrying");
         triggerIslandEscape();
      }
      else if (dockCount > 0)
      {
         // Mame dock - check transports a vojsko na vode
         int transportPUID = getNavalTransport();
         int transportCount = 0;
         if (transportPUID > 0)
         {
            transportCount = kbUnitCount(transportPUID, cMyID, cUnitStateAlive);
         }
         int warshipCount = kbUnitCount(cUnitTypeAbstractWarship, cMyID, cUnitStateAlive);

         debugStrategy("ISLAND ESCAPE: dock built, transports=" + transportCount +
            " warships=" + warshipCount);

         // Pokud nemame transporty po 90s od dock built, force priority
         if (transportCount == 0 && aiPlanGetIsIDValid(gTransportMaintainPlanID))
         {
            aiPlanSetPriority(gTransportMaintainPlanID, 80);
            debugStrategy("ISLAND ESCAPE: bumped transport maintain priority to 80");
         }
      }
      gLastIslandEscapeRetry = now;
   }
}

//------------------------------------------------------------------------------
// rule forceIslandExploration
// Pokud mIsIslandMap == false ale jsme island-stuck, force scout vsechny
// area groups (jako kdyby mIsIslandMap == true).
//------------------------------------------------------------------------------
rule forceIslandExploration
inactive
group defaultArchaicRules
minInterval 60
{
   if (gIslandEscapeTriggered == false) { return; }
   if (gMapInfo.mIsIslandMap == true) { return; } // Existing logic handles this

   // Mam scout? Use existing helperExploreOtherIslands cestou pres aktivni explore plan
   int[] explorePlans = aiPlanGetIDsByType(cPlanExplore);
   for (int i = 0; i < explorePlans.size(); i++)
   {
      int planID = explorePlans[i];
      if (aiPlanGetIsIDValid(planID) == false) { continue; }
      if (aiPlanGetParentID(planID) != -1) { continue; } // Top-level

      // Force re-call helperExploreOtherIslands na tomto planu
      helperExploreOtherIslands(planID);
      debugStrategy("ISLAND ESCAPE: forced re-exploration of all area groups on plan " + planID);
      return; // Dostacuje jeden plan
   }
}
