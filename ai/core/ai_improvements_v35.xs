//==============================================================================
/* ai_improvements_v35.xs  -  v3.5 - MULTI-HOP ISLAND ESCAPE

   Rozsireni v3.4: handle archipelagos kde mezi nami a enemy je vice vodnich
   ploch s mezilehlymi ostrovy (land-water-land-water-land...).

   Engine native podpora konci na 1 vodnim hopu - map_analysis.xs:392 explicitne
   pise "Map detected where we would need to cross multiple water area groups...
   we don't handle this."

   Strategie:
   1. BFS pres area group graph (kbAreaGroupGetBorderAreaGroupID) z naseho
      area group do enemy area group
   2. Reconstruct path: list IDs land->water->land->water->...->enemyLand
   3. Pro kazde water group v ceste registruj gMapInfo.mUsefulWaterAreaGroupIDs
      (engine pak povoluje transport pres ne)
   4. Pro kazdy mezilehly land marker pro expansion (TC settlement + dock)
   5. Re-run analyseNavalPositions per dock area
*/
//==============================================================================

//==============================================================================
// SEKCE 1 - Globaly
//==============================================================================
extern int[] gIslandChainPath = default;       // Sequence of AG IDs: ourLand, water, land, water, ..., enemyLand
extern int[] gIslandChainHopLands = default;   // Mezilehle land groups (kde stavet expansion)
extern bool  gIslandChainComputed = false;
extern int   gLastChainComputeTime = 0;
extern int   gIslandChainTargetEnemy = -1;

//==============================================================================
// SEKCE 2 - BFS pres area group graph
//==============================================================================

//------------------------------------------------------------------------------
// computeIslandChain
// BFS od naseho area group do enemy area group. Vyplni gIslandChainPath
// + gIslandChainHopLands + registruje water groups do gMapInfo.mUsefulWaterAreaGroupIDs.
// Vraci true pokud nasel cestu, false jinak.
//------------------------------------------------------------------------------
bool computeIslandChain(int targetEnemyAG = -1)
{
   if (targetEnemyAG < 0) { return false; }

   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return false; }
   int myAG = kbAreaGroupGetIDByPosition(kbBaseGetLocation(cMyID, mainBaseID));
   if (myAG == targetEnemyAG)
   {
      // No chain needed
      gIslandChainPath = new int(0, 0);
      gIslandChainHopLands = new int(0, 0);
      return true;
   }

   int totalAGs = kbAreaGroupGetNumber();
   if (totalAGs <= 0) { return false; }

   // BFS data structures (indexovane podle AG ID)
   int[] parent = new int(totalAGs, -1);
   bool[] visited = new bool(totalAGs, false);
   int[] queue = new int(0, 0);

   queue.add(myAG);
   visited[myAG] = true;

   bool found = false;
   int safetyMax = totalAGs * 2; // safety guard
   int iter = 0;

   while (queue.size() > 0 && iter < safetyMax)
   {
      iter = iter + 1;
      int cur = queue[0];
      queue.removeIndex(0);

      if (cur == targetEnemyAG)
      {
         found = true;
         break;
      }

      int numBorders = kbAreaGroupGetNumberBorderAreaGroups(cur);
      for (int i = 0; i < numBorders; i++)
      {
         int b = kbAreaGroupGetBorderAreaGroupID(cur, i);
         if (b < 0 || b >= totalAGs) { continue; }
         if (visited[b] == true) { continue; }
         // Pres impassable nemuzeme (land obstacles)
         if (kbAreaGroupGetType(b) == cAreaGroupTypeImpassableLand) { continue; }

         visited[b] = true;
         parent[b] = cur;
         queue.add(b);
      }
   }

   if (found == false)
   {
      debugStrategy("v3.5 chain: BFS nenalezena cesta z AG " + myAG +
         " do enemy AG " + targetEnemyAG + " (iter=" + iter + ")");
      return false;
   }

   // Reconstruct path zpetne (targetEnemyAG -> myAG)
   gIslandChainPath = new int(0, 0);
   int cur = targetEnemyAG;
   int reconstructIter = 0;
   while (cur != -1 && reconstructIter < totalAGs)
   {
      gIslandChainPath.add(cur);
      cur = parent[cur];
      reconstructIter = reconstructIter + 1;
   }

   // Path je nyni v opacnem poradi (enemy->us). Pro nase ucely staci znat
   // mezilehle land groups + vsechny water groups.

   gIslandChainHopLands = new int(0, 0);
   int waterRegistered = 0;

   for (int i = 0; i < gIslandChainPath.size(); i++)
   {
      int ag = gIslandChainPath[i];
      int agType = kbAreaGroupGetType(ag);

      if (agType == cAreaGroupTypeWater)
      {
         // Registruj jako useful water (jen pokud uz tam neni)
         bool alreadyIn = false;
         for (int j = 0; j < gMapInfo.mUsefulWaterAreaGroupIDs.size(); j++)
         {
            if (gMapInfo.mUsefulWaterAreaGroupIDs[j] == ag)
            {
               alreadyIn = true;
               break;
            }
         }
         if (alreadyIn == false)
         {
            gMapInfo.mUsefulWaterAreaGroupIDs.add(ag);
            waterRegistered = waterRegistered + 1;
         }
      }
      else if (agType == cAreaGroupTypeLand)
      {
         // Mezilehly land group (krome naseho a enemyho)
         if (ag != myAG && ag != targetEnemyAG)
         {
            gIslandChainHopLands.add(ag);
         }
      }
   }

   debugStrategy("v3.5 chain: nalezena cesta delky " + gIslandChainPath.size() +
      " (mezilehlych zemi=" + gIslandChainHopLands.size() +
      ", registrovanych water=" + waterRegistered + ")");
   return true;
}

//==============================================================================
// SEKCE 3 - Hop expansion management
//==============================================================================

//------------------------------------------------------------------------------
// triggerIntermediateExpansion
// Pro kazdy mezilehly land group: pokud tam nemame TC, vytvoz expansion
// build plan (cilove pozice = centroid prvni oblasti land groupu).
//------------------------------------------------------------------------------
void triggerIntermediateExpansion()
{
   for (int i = 0; i < gIslandChainHopLands.size(); i++)
   {
      int landAG = gIslandChainHopLands[i];
      int firstAreaID = kbAreaGroupGetAreaID(landAG, 0);
      if (firstAreaID < 0) { continue; }
      vector landPos = kbAreaGetCenter(firstAreaID);
      if (landPos == cInvalidVector) { continue; }

      // Mame uz TC v 80 tile od landPos?
      int existingTC = getClosestUnitByLocation(cUnitTypeAbstractTownCenter,
         cMyID, cUnitStateAlive, landPos, 80.0);
      if (existingTC >= 0)
      {
         // Mame TC - registruj nas analyseNavalPositions z teto land area
         // pro novou dock placement, pokud uz tam neni dock
         int existingDock = getClosestUnitByLocation(cUnitTypeDock, cMyID,
            cUnitStateAlive, landPos, 80.0);
         if (existingDock < 0)
         {
            analyseNavalPositions(firstAreaID);
            debugStrategy("v3.5 hop: re-analyseNavalPositions for land area " +
               firstAreaID + " (TC exists, dock missing)");
         }
         continue;
      }

      // Nemame TC - zkus vytvorit expansion build plan na settlement v teto oblasti
      // (na ostrove musi byt zlaty Settlement bod aby TC slo postavit)
      int settlementID = getClosestUnitByLocation(cUnitTypeSettlement,
         cPlayerRelationAny, cUnitStateAlive, landPos, 80.0);
      if (settlementID < 0)
      {
         debugStrategy("v3.5 hop: land AG " + landAG + " nema settlement v 80 tile - skip");
         continue;
      }

      // Build plan TC na settlement pos
      vector settlementPos = kbUnitGetPosition(settlementID);
      int planID = createSimpleBuildPlan(cUnitTypeAbstractTownCenter, 1, 75, -1, 1);
      if (planID >= 0)
      {
         aiPlanSetInitialPosition(planID, settlementPos);
         debugStrategy("v3.5 hop: TC build plan for intermediate land " + landAG +
            " at settlement " + settlementID + " pos " + settlementPos);
      }
   }
}

//------------------------------------------------------------------------------
// rule islandChainMonitor
// Periodicky zkousi BFS k enemy area group + spousti hop expansion.
// Aktivuje se jen kdyz gIslandEscapeTriggered == true (z v3.4).
//------------------------------------------------------------------------------
rule islandChainMonitor
inactive
group defaultArchaicRules
minInterval 60
{
   // Spousti se jen pokud jsme detekovali island stuck stav (z v3.4)
   if (gIslandEscapeTriggered == false) { return; }
   if (gMapInfo.mHasWater == false) { return; }

   int now = xsGetTime();
   if (gIslandChainComputed == true && (now - gLastChainComputeTime) < 120000)
   {
      // Recently computed - jen exec hop expansion
      triggerIntermediateExpansion();
      return;
   }

   // (Re)compute chain k aktualnimu most-hated enemy
   int firstEnemy = aiGetMostHatedPlayerID();
   if (firstEnemy <= 0) { return; }
   int eMainID = kbBaseGetMainID(firstEnemy);
   if (eMainID < 0) { return; }
   vector ePos = kbBaseGetLocation(firstEnemy, eMainID);
   int enemyAG = kbAreaGroupGetIDByPosition(ePos);

   gIslandChainTargetEnemy = firstEnemy;
   bool ok = computeIslandChain(enemyAG);
   if (ok == true)
   {
      gIslandChainComputed = true;
      gLastChainComputeTime = now;
      triggerIntermediateExpansion();
   }
   else
   {
      debugStrategy("v3.5 chain: nelze najit cestu k AG " + enemyAG +
         " - hraje se moc daleko nebo bez vodniho prepojeni");
   }
}

//------------------------------------------------------------------------------
// rule islandChainTransportSeed
// Pri zname chain ale 0 transportech, force aktualizovat priority transport
// maintain planu - dulezite pri vice-hop scenarech (potrebujeme transporty
// nejen pro 1. hop, ale neustale).
//------------------------------------------------------------------------------
rule islandChainTransportSeed
inactive
group defaultClassicalRules
minInterval 30
{
   if (gIslandChainComputed == false) { return; }
   if (gIslandChainHopLands.size() == 0) { return; }

   int dockCount = kbUnitCount(cUnitTypeDock, cMyID, cUnitStateAlive);
   if (dockCount == 0) { return; }

   // Mame dock + chain ma mezilehly hop -> potrebujeme transports stale
   if (aiPlanGetIsIDValid(gTransportMaintainPlanID) == true)
   {
      int curPri = aiPlanGetPriority(gTransportMaintainPlanID);
      if (curPri < 75)
      {
         aiPlanSetPriority(gTransportMaintainPlanID, 75);
         // Maintain 3 transports misto 2 (vice hop)
         aiPlanSetVariableInt(gTransportMaintainPlanID, cTrainPlanNumberToMaintain, 0, 3);
         debugStrategy("v3.5 chain: transport priority -> 75, maintain count -> 3 (multi-hop chain)");
      }
   }
}
