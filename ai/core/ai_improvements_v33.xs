//==============================================================================
/* ai_improvements_v33.xs  -  v3.3

   Ctvrte kolo systemovych vylepseni (#31 - #40) navazujici na v3.2.

   P1: 31 Pop cap cascading, 32 Friendly fire awareness, 33 Build queue reprio
   P2: 34 Eco-mil sliding, 35 Late-game tech race, 36 Priest conversion targeting
   P3: 37 Ranged kiting, 38 Choke detection, 39 Fortress at choke, 40 Scout sacrifice
*/
//==============================================================================

//==============================================================================
// SEKCE 1 - Globaly
//==============================================================================

// --- 31: Pop cap cascading ---
extern int gLastPopCascadeTime = 0;
extern bool gPopCascadeActive = false;

// --- 32: Friendly fire awareness ---
extern int gLastFriendlyFireCheck = 0;
extern bool gFriendlyFireBlock = false;

// --- 33: Build queue reprio ---
extern int gLastBuildReprioTime = 0;

// --- 34: Eco-mil sliding ---
extern float gEcoTransitionPhase = 0.0; // 0.0=eco, 1.0=mil
extern int gLastEcoTransitionTime = 0;

// --- 35: Late-game tech race ---
extern int gLastTechRaceTime = 0;

// --- 36: Priest conversion targeting ---
extern int gLastPriestConvertTime = 0;
extern int gPriestConvertTargetID = -1;

// --- 37: Ranged kiting ---
extern int gLastKitingApplyTime = 0;

// --- 38: Choke points ---
extern vector[] gChokePoints = default;
extern bool gChokePointsScanned = false;

// --- 39: Fortress at choke ---
extern int gLastFortressChokeTime = 0;

// --- 40: Scout sacrifice ---
extern int gScoutCriticalInfoUntil = 0;

//==============================================================================
// SEKCE 2 - P1: Pop cap, friendly fire, build queue
//==============================================================================

//------------------------------------------------------------------------------
// 31: Population cap cascading replacement
// Pri popUsed >= popCap-5 redukuje villager training a bumpne hero priority.
//------------------------------------------------------------------------------
void cascadePopReplacement()
{
   int popCap = kbPlayerGetPopCap(cMyID);
   int popCur = kbPlayerGetPop(cMyID);
   int slack = popCap - popCur;

   if (slack > 5)
   {
      // Plenty of room - normal training
      if (gPopCascadeActive == true)
      {
         gPopCascadeActive = false;
         debugStrategy("31: pop cascade deactivated (slack=" + slack + ")");
      }
      return;
   }

   // Slack <= 5 - cascade mode
   if (gPopCascadeActive == false)
   {
      gPopCascadeActive = true;
      gLastPopCascadeTime = xsGetTime();

      // Bumpne hero/myth priority pres army percentages
      if (gArmyHeroPercentage < 0.40) { gArmyHeroPercentage = 0.40; }
      if (gArmyLateGameMythPercentage < 0.35) { gArmyLateGameMythPercentage = 0.35; }

      // Sniz villager maintain pokud existuje
      if (aiPlanGetIsIDValid(gVillagerMaintainPlan) == true)
      {
         int curMaintain = aiPlanGetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0);
         if (curMaintain > popCur - 10) // pravdepodobne over-set
         {
            aiPlanSetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0, popCur - 10);
            debugStrategy("31: pop cascade - villager maintain reduced to " + (popCur - 10));
         }
      }

      debugStrategy("31: POP CASCADE active (slack=" + slack +
         ", hero%=" + gArmyHeroPercentage + ", myth%=" + gArmyLateGameMythPercentage + ")");
   }
}

rule popCascadeMonitor
inactive
group defaultClassicalRules
minInterval 15
{
   cascadePopReplacement();
}

//------------------------------------------------------------------------------
// 32: Friendly fire awareness pre-cast
// Pred godPowerManager.useUnusedGodPowers() check pocet vlastnich vojaku v 40
// tile od gBestGPTargetPos. Pri >20 pop nastavi gFriendlyFireBlock - bo
// godpower trigger v v3.0 pak skip flush.
//------------------------------------------------------------------------------
void checkFriendlyFireRisk()
{
   if (gBestGPTargetPos == cInvalidVector)
   {
      gFriendlyFireBlock = false;
      return;
   }

   int qID = useSimpleUnitQuery(cUnitTypeMilitaryUnit, cMyID,
      cUnitStateAlive, gBestGPTargetPos, 40.0);
   int ownNearby = kbUnitQueryExecute(qID);

   if (ownNearby > 20)
   {
      if (gFriendlyFireBlock == false)
      {
         gFriendlyFireBlock = true;
         debugStrategy("32: friendly fire risk detected (" + ownNearby +
            " own units near GP target) - blocking AOE casts");
      }
   }
   else
   {
      if (gFriendlyFireBlock == true)
      {
         gFriendlyFireBlock = false;
         debugStrategy("32: friendly fire risk cleared - GP casts re-enabled");
      }
   }
}

rule friendlyFireMonitor
inactive
group defaultClassicalRules
minInterval 8
{
   checkFriendlyFireRisk();
}

//------------------------------------------------------------------------------
// 33: Build queue reprioritization on resource shortage
// Pri wood < 200 reprioritizuje aktivni build plany: farmy +50, walls +30,
// military -10 (delsi cas na dokonceni vyssi-priority neceho).
//------------------------------------------------------------------------------
void reprioritizeBuildQueue()
{
   float wood = kbResourceGet(cResourceWood);
   float food = kbResourceGet(cResourceFood);
   if (wood >= 200.0 && food >= 150.0) { return; }

   int now = xsGetTime();
   if ((now - gLastBuildReprioTime) < 30000) { return; }

   int[] buildPlans = aiPlanGetIDsByType(cPlanBuild);
   if (buildPlans.size() < 2) { return; } // Jen pri queue 2+

   int reprioCount = 0;
   for (int i = 0; i < buildPlans.size(); i++)
   {
      int planID = buildPlans[i];
      if (aiPlanGetIsIDValid(planID) == false) { continue; }
      int buildingPUID = aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0);
      int curPri = aiPlanGetPriority(planID);

      // Eco buildings priority up
      if (buildingPUID == gFarmUnit && curPri < 80)
      {
         aiPlanSetPriority(planID, curPri + 30);
         reprioCount++;
      }
      // Military buildings priority down (let eco finish first)
      else if (buildingPUID == gFortressUnit && curPri > 30)
      {
         aiPlanSetPriority(planID, curPri - 10);
         reprioCount++;
      }
   }

   if (reprioCount > 0)
   {
      gLastBuildReprioTime = now;
      debugStrategy("33: resource shortage - reprioritized " + reprioCount +
         " build plans (wood=" + wood + " food=" + food + ")");
   }
}

rule buildQueueReprioMonitor
inactive
group defaultClassicalRules
minInterval 10
{
   reprioritizeBuildQueue();
}

//==============================================================================
// SEKCE 3 - P2: Eco-mil sliding, tech race, priest conversion
//==============================================================================

//------------------------------------------------------------------------------
// 34: Eco-mil sliding transition
// Pri vysoke urgency (gMilitaryUrgency > 0.7) postupne presune pop slot
// z eco do mil. Adjust gArmy*Percentage smerem nahoru, redukce villager maintain.
//------------------------------------------------------------------------------
void slideEcoToMil()
{
   int now = xsGetTime();

   if (gMilitaryUrgency > 0.7)
   {
      // Slide phase up
      if (gEcoTransitionPhase < 1.0)
      {
         gEcoTransitionPhase = gEcoTransitionPhase + 0.10;
         if (gEcoTransitionPhase > 1.0) { gEcoTransitionPhase = 1.0; }
      }
   }
   else if (gMilitaryUrgency < 0.3)
   {
      // Slide phase down
      if (gEcoTransitionPhase > 0.0)
      {
         gEcoTransitionPhase = gEcoTransitionPhase - 0.05;
         if (gEcoTransitionPhase < 0.0) { gEcoTransitionPhase = 0.0; }
      }
   }

   // Aplikace: pri vysokem phase bumpne mil percentages
   if (gEcoTransitionPhase > 0.5 && (now - gLastEcoTransitionTime) > 30000)
   {
      gLastEcoTransitionTime = now;
      // Boost early myth (rapid mil production)
      if (gArmyEarlyGameMythPercentage < 0.30)
      {
         gArmyEarlyGameMythPercentage = gArmyEarlyGameMythPercentage + 0.02;
      }
      debugStrategy("34: eco-mil slide phase=" + gEcoTransitionPhase +
         " - boost myth% to " + gArmyEarlyGameMythPercentage);
   }
}

rule ecoMilSlideMonitor
inactive
group defaultClassicalRules
minInterval 20
{
   slideEcoToMil();
}

//------------------------------------------------------------------------------
// 35: Late-game tech priority race
// V Mythic+ pri vekove nevyhode bumpne tech research priority.
//------------------------------------------------------------------------------
void manageTechRace()
{
   int myAge = kbPlayerGetAge(cMyID);
   if (myAge < cAge4) { return; } // Jen Mythic+

   int now = xsGetTime();
   if ((now - gLastTechRaceTime) < 60000) { return; }

   if (gAdaptAgeAdvantage == -1)
   {
      // Jsme pozadu - bumpne research planu priority
      if (aiPlanGetIsIDValid(gMilitaryResearchPlan) == true)
      {
         int curPri = aiPlanGetPriority(gMilitaryResearchPlan);
         if (curPri < 75)
         {
            aiPlanSetPriority(gMilitaryResearchPlan, curPri + 10);
            debugStrategy("35: tech race - bumped military research priority to " + (curPri + 10));
         }
      }
      if (aiPlanGetIsIDValid(gEconomyResearchPlan) == true)
      {
         int curPri = aiPlanGetPriority(gEconomyResearchPlan);
         if (curPri < 70)
         {
            aiPlanSetPriority(gEconomyResearchPlan, curPri + 5);
         }
      }
      gLastTechRaceTime = now;
   }
}

rule techRaceMonitor
inactive
group defaultMythicRules
minInterval 45
{
   manageTechRace();
}

//------------------------------------------------------------------------------
// 36: Egyptian priest conversion targeting
// Egypt only. Pri >=3 priests + visible enemy siege, route 1-2 priests
// na enemy siege unit (siege > hero > military priority).
//------------------------------------------------------------------------------
void targetPriestConversion()
{
   if (cMyCulture != cCultureEgyptian) { return; }

   int priestCount = kbUnitCount(cUnitTypePriest, cMyID, cUnitStateAlive);
   if (priestCount < 3) { return; }

   int now = xsGetTime();
   if ((now - gLastPriestConvertTime) < 25000) { return; }

   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return; }
   vector basePos = kbBaseGetLocation(cMyID, mainBaseID);

   // Find enemy siege unit prioritne (>1 hero >2 military>3)
   int targetID = -1;

   // Priority 1: Siege
   int qID = useSimpleUnitQuery(cUnitTypeAbstractSiegeWeapon,
      cPlayerRelationEnemyNotGaia, cUnitStateAlive, basePos, 50.0);
   int n = kbUnitQueryExecute(qID);
   if (n > 0)
   {
      targetID = kbUnitQueryGetResult(qID, 0);
   }

   // Priority 2: Hero (jen pokud nemam siege target)
   if (targetID < 0)
   {
      int qIDHero = useSimpleUnitQuery(cUnitTypeHero,
         cPlayerRelationEnemyNotGaia, cUnitStateAlive, basePos, 50.0);
      int nHero = kbUnitQueryExecute(qIDHero);
      if (nHero > 0)
      {
         targetID = kbUnitQueryGetResult(qIDHero, 0);
      }
   }

   if (targetID < 0) { return; }

   // Najdi 1 priest (z defend planu) ktery je blizko cile
   int[] defenders = aiPlanGetUnits(gPrimaryLandDefendPlan, cUnitTypePriest);
   if (defenders.size() == 0) { return; }

   int chosenPriest = defenders[0];
   if (kbUnitGetIsIDValid(chosenPriest) == false) { return; }

   // Odebrat priest z planu pro free task
   int planID = kbUnitGetPlanID(chosenPriest);
   if (planID >= 0) { aiPlanRemoveUnit(planID, chosenPriest); }

   aiTaskWorkUnit(chosenPriest, targetID);
   gPriestConvertTargetID = targetID;
   gLastPriestConvertTime = now;
   debugStrategy("36: priest " + chosenPriest + " converting enemy unit " + targetID);
}

rule priestConvertTargetingMonitor
inactive
group defaultClassicalRules
minInterval 15
{
   targetPriestConversion();
}

//==============================================================================
// SEKCE 4 - P3: Ranged kiting, choke points, fortress, scout sacrifice
//==============================================================================

//------------------------------------------------------------------------------
// 37: Ranged unit kiting (group dispersion)
// Pri velkem mnozstvi enemy melee blizko nasi armady bumpne gather distance
// na attack planech - skupiny se rozprosti misto stane na hrude.
//------------------------------------------------------------------------------
void applyRangedKiting()
{
   int now = xsGetTime();
   if ((now - gLastKitingApplyTime) < 20000) { return; }

   // Najdi attack plans
   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   for (int i = 0; i < attackPlans.size(); i++)
   {
      int planID = attackPlans[i];
      if (aiPlanGetIsIDValid(planID) == false) { continue; }
      if (aiPlanGetParentID(planID) != -1) { continue; }

      // Bumpne gather distance na 25 (default ~15)
      aiPlanSetVariableFloat(planID, cAttackPlanGatherDistance, 0, 25.0);
   }

   gLastKitingApplyTime = now;
}

rule rangedKitingMonitor
inactive
group defaultClassicalRules
minInterval 25
{
   // Aplikuj jen pokud mame >= 30% ranged units
   int totalMil = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive);
   int rangedMil = kbUnitCount(cUnitTypeLogicalTypeRangedUnitsAttack, cMyID, cUnitStateAlive);
   if (totalMil < 5) { return; }
   float ratio = xsIntToFloat(rangedMil) / xsIntToFloat(totalMil);
   if (ratio < 0.30) { return; }

   applyRangedKiting();
}

//------------------------------------------------------------------------------
// 38: Choke point detection
// Pri startu identifikuje narrow area group borders (proxy pro choke pointy).
// Vysledek do gChokePoints[] pro pouziti fortress placement (39).
//------------------------------------------------------------------------------
void scanChokePoints()
{
   if (gChokePointsScanned == true) { return; }

   int numAreaGroups = kbAreaGroupGetNumber();
   gChokePoints = new vector(0, cInvalidVector);

   for (int g = 0; g < numAreaGroups; g++)
   {
      if (kbAreaGroupGetType(g) != cAreaGroupTypeLand) { continue; }

      int numBorders = kbAreaGroupGetNumberBorderAreaGroups(g);
      // Land area s 1-2 land bordery a small total area = potencialni choke
      if (numBorders <= 2)
      {
         int areaCount = kbAreaGroupGetNumberAreas(g);
         if (areaCount > 0 && areaCount < 8)
         {
            // Maly land "plug" - centroid prvni oblasti je choke point proxy
            int firstAreaID = kbAreaGroupGetAreaID(g, 0);
            vector center = kbAreaGetCenter(firstAreaID);
            if (center != cInvalidVector)
            {
               gChokePoints.add(center);
               debugStrategy("38: choke point detected at " + center +
                  " (area group " + g + ", areas=" + areaCount + ")");
            }
         }
      }
   }

   gChokePointsScanned = true;
   debugStrategy("38: choke point scan complete, found " + gChokePoints.size() + " points");
}

rule chokePointScanner
inactive
group defaultArchaicRules
minInterval 30
{
   scanChokePoints();
   if (gChokePointsScanned == true)
   {
      xsDisableRule("chokePointScanner");
   }
}

//------------------------------------------------------------------------------
// 39: Fortress at choke point
// Pokud jsou znamy choke pointy a mame zdroje, postavi fortress na nejblizsim
// choke pointu (fallback: max defended TC base, ktery uz dela existing kod).
//------------------------------------------------------------------------------
void buildFortressAtChoke()
{
   if (gChokePoints.size() == 0) { return; }
   if (gFortressUnit < 0) { return; }

   int now = xsGetTime();
   if ((now - gLastFortressChokeTime) < 120000) { return; }

   // Nemame uz fortress?
   int existingFortresses = kbUnitCount(gFortressUnit, cMyID, cUnitStateAlive);
   if (existingFortresses >= 2) { return; }

   // Najdi nejblizsi choke point
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return; }
   vector basePos = kbBaseGetLocation(cMyID, mainBaseID);

   vector chosenChoke = cInvalidVector;
   float minDist = 999.0;
   for (int i = 0; i < gChokePoints.size(); i++)
   {
      vector cp = gChokePoints[i];
      if (cp == cInvalidVector) { continue; }
      float d = xsVectorLength(cp - basePos);
      if (d < minDist && d < 200.0) // Jen choke v dosahu
      {
         minDist = d;
         chosenChoke = cp;
      }
   }

   if (chosenChoke == cInvalidVector) { return; }

   // Build fortress plan na lokaci choke pointu
   int planID = createSimpleBuildPlan(gFortressUnit, 1, 60, -1, 1);
   if (planID >= 0)
   {
      aiPlanSetInitialPosition(planID, chosenChoke);
      gLastFortressChokeTime = now;
      debugStrategy("39: fortress build plan at choke " + chosenChoke +
         " (distance " + minDist + " from main base)");
   }
}

rule fortressChokeMonitor
inactive
group defaultHeroicRules
minInterval 60
{
   buildFortressAtChoke();
}

//------------------------------------------------------------------------------
// 40: Scout sacrifice for critical info
// Pokud scout vidi enemy wonder/TC (high value info) a je pod hrozbou,
// odlozi scout retreat (#13). Engine vyziska info nez scout zemre.
//------------------------------------------------------------------------------
void checkScoutCriticalInfo()
{
   int qID = kbUnitQueryCreate("scoutCriticalScan");
   kbUnitQuerySetPlayerID(qID, cMyID);
   kbUnitQuerySetUnitType(qID, cUnitTypeAbstractScout);
   kbUnitQuerySetState(qID, cUnitStateAlive);
   kbUnitQueryResetResults(qID);
   int n = kbUnitQueryExecute(qID);

   for (int i = 0; i < n; i++)
   {
      int sID = kbUnitQueryGetResult(qID, i);
      if (kbUnitGetIsIDValid(sID) == false) { continue; }
      vector sPos = kbUnitGetPosition(sID);

      // Vidi scout enemy wonder do 30 tile?
      int wonderQ = useSimpleUnitQuery(cUnitTypeWonder,
         cPlayerRelationEnemyNotGaia, cUnitStateAlive, sPos, 30.0);
      int wonderN = kbUnitQueryExecute(wonderQ);

      // Vidi scout enemy TC do 30 tile?
      int tcQ = useSimpleUnitQuery(cUnitTypeAbstractTownCenter,
         cPlayerRelationEnemyNotGaia, cUnitStateAlive, sPos, 30.0);
      int tcN = kbUnitQueryExecute(tcQ);

      if (wonderN > 0 || tcN > 0)
      {
         // Critical info - protahnout scout na 10s
         gScoutCriticalInfoUntil = xsGetTime() + 10000;
         debugStrategy("40: scout " + sID + " sees critical info (wonder=" + wonderN +
            " tc=" + tcN + ") - retreat blocked for 10s");
         break;
      }
   }
}

rule scoutCriticalInfoMonitor
inactive
group defaultArchaicRules
minInterval 7
{
   checkScoutCriticalInfo();
}
