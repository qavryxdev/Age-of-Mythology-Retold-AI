//==============================================================================
/* ai_improvements_v36.xs  -  v3.6

   Pate kolo systemovych vylepseni (#41 - #50).

   P1: 41 Hero promotion timing, 42 Resource starvation, 43 Repair priority matrix
   P2: 44 Counter-rush eco crisis, 45 Pharaoh positioning, 46 Tech queue resolver
   P3: 47 Bell garrison batch, 48 Berserk swap activation, 49 Ceasefire counterplay,
       50 Endgame Wonder/Titan race detection
*/
//==============================================================================

//==============================================================================
// SEKCE 1 - Globaly
//==============================================================================

// --- 41: Hero promotion timing ---
extern int gLastHeroPromoTime = 0;

// --- 42: Resource starvation ---
extern float gLastWoodAmount = 0.0;
extern int gWoodStarvationStreak = 0;
extern int gLastStarvationCheckTime = 0;

// --- 43: Repair priority ---
extern int gLastRepairPriorityTime = 0;

// --- 44: Counter-rush eco crisis ---
extern bool gEcoCrisisActive = false;
extern int  gEcoCrisisStartTime = 0;

// --- 45: Pharaoh positioning ---
extern int gPharaohCurrentEmpowerType = -1; // last empower target type
extern int gLastPharaohRotateTime = 0;

// --- 46: Tech queue resolver ---
extern int gLastTechResolverTime = 0;
extern bool gAgeUpSuspended = false;
extern int gAgeUpSuspendUntil = 0;

// --- 49: Ceasefire boom ---
extern bool gCeasefireBoomActive = false;
extern int gCeasefireBoomStart = 0;

// --- 50: Enemy wonder/titan race ---
extern bool gEnemyEndgameRaceActive = false;
extern int  gEnemyEndgameRaceStart = 0;

//==============================================================================
// SEKCE 2 - P1: Hero promo, starvation, repair priority
//==============================================================================

//------------------------------------------------------------------------------
// 41: Hero promotion timing
// Pri enemyHeroCount * 1.2 > myHeroCount + dostupnem hero plan, bumpne
// gArmyHeroPercentage agresivneji.
//------------------------------------------------------------------------------
void monitorHeroPromotion()
{
   int myHeroes = kbUnitCount(cUnitTypeHero, cMyID, cUnitStateAlive);

   int enemyHeroes = 0;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }
      enemyHeroes = enemyHeroes + kbUnitCount(cUnitTypeHero, p, cUnitStateAlive);
   }

   if (enemyHeroes <= 0) { return; }

   // Pomer enemy:my * 1.2 - jsme za "1.2x prahem"
   int trigger = xsFloatToInt(xsIntToFloat(myHeroes) * 1.2);
   if (enemyHeroes > trigger)
   {
      // Bump hero %
      if (gArmyHeroPercentage < 0.45)
      {
         gArmyHeroPercentage = gArmyHeroPercentage + 0.03;
         debugStrategy("41: hero promotion - enemy=" + enemyHeroes + " my=" + myHeroes +
            " - bumping hero%% to " + gArmyHeroPercentage);
      }
   }
}

rule heroPromotionMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   monitorHeroPromotion();
}

//------------------------------------------------------------------------------
// 42: Resource starvation recovery
// Detekce wood = 0 + woodRate ~ 0 + villagers existuji = wood line dryla.
// Force placement noveho dropsite plus reset breakdown attempts.
//------------------------------------------------------------------------------
void monitorStarvation()
{
   float curWood = kbResourceGet(cResourceWood);
   int villagers = kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive);
   int now = xsGetTime();

   // 30s window starvation streak
   if (curWood < 50.0 && villagers >= 10)
   {
      gWoodStarvationStreak = gWoodStarvationStreak + 1;
   }
   else
   {
      gWoodStarvationStreak = 0;
   }

   // 3+ konsekutivni iterace starvation = problem
   if (gWoodStarvationStreak >= 3)
   {
      // Force breakdown update + reset attempts
      gDelayUpdateDistributionAndBreakdowns = false;
      // Reset gAdjustBreakdownAttempts (allow nove pokusy)
      for (int i = 0; i < gAdjustBreakdownAttempts.size(); i++)
      {
         gAdjustBreakdownAttempts[i] = 0;
      }
      // Force market sell pokud mame jine zdroje
      if (kbUnitCount(gMarketUnit, cMyID, cUnitStateAlive) > 0)
      {
         if (kbResourceGet(cResourceFood) > 300.0)
         {
            aiSellResourceOnMarket(cResourceFood);
         }
         if (kbResourceGet(cResourceGold) > 300.0)
         {
            aiSellResourceOnMarket(cResourceGold);
         }
      }
      debugStrategy("42: WOOD STARVATION! streak=" + gWoodStarvationStreak +
         " - force breakdown reset + market emergency sell");
      gWoodStarvationStreak = 0; // Reset po akci
   }

   gLastWoodAmount = curWood;
   gLastStarvationCheckTime = now;
}

rule starvationMonitor
inactive
group defaultClassicalRules
minInterval 20
{
   monitorStarvation();
}

//------------------------------------------------------------------------------
// 43: Building repair priority matrix
// Iterujeme aktivni repair plany, prirazujeme jim priority dle typu budovy.
// Wonder=200, TC=100, Fortress=80, Tower=40, Farm=20.
//------------------------------------------------------------------------------
void prioritizeRepairs()
{
   int now = xsGetTime();
   if ((now - gLastRepairPriorityTime) < 8000) { return; }

   int[] repairPlans = aiPlanGetIDsByType(cPlanRepair);
   if (repairPlans.size() < 2) { return; }

   int reprioCount = 0;
   for (int i = 0; i < repairPlans.size(); i++)
   {
      int planID = repairPlans[i];
      if (aiPlanGetIsIDValid(planID) == false) { continue; }
      int targetID = aiPlanGetVariableInt(planID, cRepairPlanTargetID, 0);
      if (kbUnitGetIsIDValid(targetID) == false) { continue; }
      int targetPUID = kbUnitGetProtoUnitID(targetID);

      int newPri = 50; // default
      if (kbProtoUnitIsType(targetPUID, cUnitTypeWonder) == true)
      {
         newPri = 200;
      }
      else if (kbProtoUnitIsType(targetPUID, cUnitTypeAbstractTownCenter) == true)
      {
         newPri = 100;
      }
      else if (gFortressUnit > 0 && targetPUID == gFortressUnit)
      {
         newPri = 80;
      }
      else if (kbProtoUnitIsType(targetPUID, cUnitTypeAbstractTower) == true)
      {
         newPri = 40;
      }
      else if (gFarmUnit > 0 && targetPUID == gFarmUnit)
      {
         newPri = 20;
      }

      int curPri = aiPlanGetPriority(planID);
      if (curPri != newPri)
      {
         aiPlanSetPriority(planID, newPri);
         reprioCount++;
      }
   }

   if (reprioCount > 0)
   {
      gLastRepairPriorityTime = now;
      debugStrategy("43: reprioritized " + reprioCount + " repair plans by building type");
   }
}

rule repairPriorityMonitor
inactive
group defaultClassicalRules
minInterval 8
{
   prioritizeRepairs();
}

//==============================================================================
// SEKCE 3 - P2: Counter-rush, pharaoh, tech resolver
//==============================================================================

//------------------------------------------------------------------------------
// 44: Counter-rush eco crisis transition
// Pri rush detected v age 1-2 + my army < 50% enemy => boost food gather +
// snizi wood gather (zastav 60s aby pop generovala vojaky).
//------------------------------------------------------------------------------
void manageEcoCrisis()
{
   int myAge = kbPlayerGetAge(cMyID);
   int now = xsGetTime();

   if (gAdaptRushDetected == false || myAge > cAge2)
   {
      // Reset crisis pokud uz neni rush
      if (gEcoCrisisActive == true)
      {
         gEcoCrisisActive = false;
         debugStrategy("44: eco crisis ended");
      }
      return;
   }

   int myArmy    = computeArmyValue(cMyID);
   int enemyArmy = computeMaxEnemyArmyValue();

   if (enemyArmy > xsFloatToInt(xsIntToFloat(myArmy) * 2.0))
   {
      if (gEcoCrisisActive == false)
      {
         gEcoCrisisActive = true;
         gEcoCrisisStartTime = now;
         // Bumpne urgency
         gMilitaryUrgency = 1.0;
         // Sniz villager maintain (vetsina ekonomicke pop ide na food)
         if (aiPlanGetIsIDValid(gVillagerMaintainPlan) == true)
         {
            int curMaintain = aiPlanGetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0);
            // Drz villager pop ne vyssi nez 75% normal (zbytek pop pro vojaky)
            int newMaintain = xsFloatToInt(xsIntToFloat(curMaintain) * 0.75);
            aiPlanSetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0, newMaintain);
         }
         debugStrategy("44: ECO CRISIS - my=" + myArmy + " enemy=" + enemyArmy +
            " - villager maintain reduced for army production");
      }
   }
   else if (gEcoCrisisActive == true && (now - gEcoCrisisStartTime) > 60000)
   {
      // Po 60s uvolnit (vraci se k normalu via standardni logiku)
      gEcoCrisisActive = false;
      debugStrategy("44: eco crisis 60s window expired - resuming normal");
   }
}

rule ecoCrisisMonitor
inactive
group defaultArchaicRules
minInterval 15
{
   manageEcoCrisis();
}

//------------------------------------------------------------------------------
// 45: Pharaoh positioning matrix (Egypt only)
// Cyklicky rotuje pharaoh empower mezi Granary -> MiningCamp -> LumberCamp
// dle aktualniho shortfall v ekonomice.
//------------------------------------------------------------------------------
void rotatePharaohEmpower()
{
   if (cMyCulture != cCultureEgyptian) { return; }
   int now = xsGetTime();
   if ((now - gLastPharaohRotateTime) < 60000) { return; } // Rotate kazdych 60s

   int pharaohID = getUnit(cUnitTypePharaoh, cMyID, cUnitStateAlive);
   if (pharaohID < 0) { return; }
   if (kbUnitGetIsIDValid(pharaohID) == false) { return; }

   // Identify shortfall: ktery resource ma nejnizsi velocity (z v3.2)
   int targetType = -1;
   if (gFoodVelocity < gWoodVelocity && gFoodVelocity < gGoldVelocity)
   {
      // Food shortfall
      targetType = cUnitTypeGranary;
   }
   else if (gWoodVelocity < gGoldVelocity)
   {
      targetType = cUnitTypeLumberCamp;
   }
   else
   {
      targetType = cUnitTypeMiningCamp;
   }

   if (targetType == gPharaohCurrentEmpowerType) { return; } // No rotation

   // Najdi target building of this type
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return; }
   vector basePos = kbBaseGetLocation(cMyID, mainBaseID);
   int targetID = getClosestUnitByLocation(targetType, cMyID, cUnitStateAlive, basePos, 80.0);
   if (targetID < 0) { return; }

   // Odeber pharaoh z aktualniho planu
   int planID = kbUnitGetPlanID(pharaohID);
   if (planID >= 0) { aiPlanRemoveUnit(planID, pharaohID); }

   aiTaskWorkUnit(pharaohID, targetID);
   gPharaohCurrentEmpowerType = targetType;
   gLastPharaohRotateTime = now;
   debugStrategy("45: pharaoh rotated to empower type " + targetType +
      " (foodV=" + gFoodVelocity + " woodV=" + gWoodVelocity + " goldV=" + gGoldVelocity + ")");
}

rule pharaohRotateMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   rotatePharaohEmpower();
}

//------------------------------------------------------------------------------
// 46: Tech queue resolver - age vs military
// Pri panic defense + active age-up bumpne dolu age priority, military research
// up. Po 60s revert.
//------------------------------------------------------------------------------
void resolveTechQueue()
{
   int now = xsGetTime();

   bool inPanic = (gDefenseReflexPanic == true || gAdaptTotalDefenseMode == true ||
                   gWallBreachActive == true);

   if (inPanic == true && gAgeUpSuspended == false)
   {
      if (aiPlanGetIsIDValid(gAgeUpResearchPlan) == true)
      {
         int curPri = aiPlanGetPriority(gAgeUpResearchPlan);
         if (curPri > 30)
         {
            aiPlanSetPriority(gAgeUpResearchPlan, curPri - 30);
            gAgeUpSuspended = true;
            gAgeUpSuspendUntil = now + 60000;
            debugStrategy("46: panic - age-up priority " + curPri + " -> " + (curPri - 30));
         }
      }
      // Bumpne military research priority
      if (aiPlanGetIsIDValid(gMilitaryResearchPlan) == true)
      {
         int milPri = aiPlanGetPriority(gMilitaryResearchPlan);
         if (milPri < 80)
         {
            aiPlanSetPriority(gMilitaryResearchPlan, milPri + 15);
         }
      }
   }
   else if (gAgeUpSuspended == true && now > gAgeUpSuspendUntil)
   {
      // Restore
      if (aiPlanGetIsIDValid(gAgeUpResearchPlan) == true)
      {
         int curPri = aiPlanGetPriority(gAgeUpResearchPlan);
         aiPlanSetPriority(gAgeUpResearchPlan, curPri + 30);
      }
      gAgeUpSuspended = false;
      debugStrategy("46: tech queue resolver - age-up priority restored");
   }
}

rule techQueueResolver
inactive
group defaultClassicalRules
minInterval 15
{
   resolveTechQueue();
}

//==============================================================================
// SEKCE 4 - P3: Bell garrison batch, berserk swap, ceasefire, endgame race
//==============================================================================

//------------------------------------------------------------------------------
// 47: Bell garrison batch
// Rozsireni v3.2 #29 - pri aktivni defense + 8+ villagers + 5+ enemies blizko TC,
// garrisonuje 3-5 villagers najednou (misto 1-2 per cycle z #29).
//------------------------------------------------------------------------------
void batchGarrisonOnAttack()
{
   if (gDefenseReflex == false && gDefenseReflexPanic == false) { return; }
   if (gEmergencyDefenseActive == false) { return; } // Jen pri opravdove emergency

   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0) { return; }
   vector basePos = kbBaseGetLocation(cMyID, mainBaseID);

   // Najdi enemies nearby
   int eqID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary,
      cPlayerRelationEnemyNotGaia, cUnitStateAlive, basePos, 25.0);
   int enemiesNearby = kbUnitQueryExecute(eqID);
   if (enemiesNearby < 5) { return; }

   int tcID = getClosestUnitByLocation(cUnitTypeAbstractTownCenter, cMyID,
      cUnitStateAlive, basePos, 50.0);
   if (tcID < 0) { return; }

   // Spocti villagers do 30 tile
   int qID = kbUnitQueryCreate("batchGarrisonScan");
   kbUnitQuerySetPlayerID(qID, cMyID);
   kbUnitQuerySetUnitType(qID, cUnitTypeAbstractVillager);
   kbUnitQuerySetState(qID, cUnitStateAlive);
   kbUnitQuerySetPosition(qID, basePos);
   kbUnitQuerySetMaximumDistance(qID, 30.0);
   kbUnitQueryResetResults(qID);
   int n = kbUnitQueryExecute(qID);
   if (n < 8) { return; }

   // Batch garrison vsechny do TC (max 8, vetsi nez v3.2 #29 limit 5)
   int garrisoned = 0;
   for (int i = 0; i < n && garrisoned < 8; i++)
   {
      int vID = kbUnitQueryGetResult(qID, i);
      if (kbUnitGetIsIDValid(vID) == false) { continue; }
      aiTaskWorkUnit(vID, tcID);
      garrisoned++;
   }

   if (garrisoned > 0)
   {
      debugStrategy("47: batch garrison - " + garrisoned + " villagers to TC " + tcID +
         " (enemies near=" + enemiesNearby + ")");
   }
}

rule batchGarrisonMonitor
inactive
group defaultClassicalRules
minInterval 4
{
   batchGarrisonOnAttack();
}

//------------------------------------------------------------------------------
// 48: Norse berserk villager swap activation
// Pri Norse + emergency + low berserk count + high villager count, set strategy
// flag cStrategyFlagConvertVillagerToBerserk = true (engine pak konvertuje).
//------------------------------------------------------------------------------
void manageBerserkSwap()
{
   if (cMyCulture != cCultureNorse) { return; }
   if (gDefenseReflex == false && gDefenseReflexPanic == false) { return; }

   int berserkCount = kbUnitCount(cUnitTypeBerserk, cMyID, cUnitStateAlive);
   int villagerCount = kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive);

   if (berserkCount < 5 && villagerCount > 30)
   {
      // Aktivuj flag pres aktualni strategy data
      if (gStrategyManager.mCurrentID >= 0)
      {
         Strategy s = gStrategyManager.getCurrentStrategy();
         s.mData.setFlag(cStrategyFlagConvertVillagerToBerserk, true);
         debugStrategy("48: Norse berserk swap activated - berserks=" + berserkCount +
            " vils=" + villagerCount);
      }
   }
}

rule berserkSwapMonitor
inactive
group defaultClassicalRules
minInterval 20
{
   manageBerserkSwap();
}

//------------------------------------------------------------------------------
// 49: Ceasefire counterplay (Atlantean enemy ceasefire)
// Pri mCeasefireActive aktivuje boom mode: bumpne villager maintain +5,
// economy research priority +15, snizi attack pripravu.
//------------------------------------------------------------------------------
void manageCeasefireBoom()
{
   int now = xsGetTime();

   if (gAttackManager.mCeasefireActive == true)
   {
      if (gCeasefireBoomActive == false)
      {
         gCeasefireBoomActive = true;
         gCeasefireBoomStart = now;
         // Boom: bumpne villager maintain
         if (aiPlanGetIsIDValid(gVillagerMaintainPlan) == true)
         {
            int cur = aiPlanGetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0);
            aiPlanSetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0, cur + 5);
         }
         // Boost economy research
         if (aiPlanGetIsIDValid(gEconomyResearchPlan) == true)
         {
            int curPri = aiPlanGetPriority(gEconomyResearchPlan);
            aiPlanSetPriority(gEconomyResearchPlan, curPri + 15);
         }
         debugStrategy("49: CEASEFIRE BOOM activated - +5 villager maintain, +15 eco research priority");
      }
   }
   else if (gCeasefireBoomActive == true)
   {
      // Ceasefire skoncil - reset
      if (aiPlanGetIsIDValid(gVillagerMaintainPlan) == true)
      {
         int cur = aiPlanGetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0);
         aiPlanSetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0, cur - 5);
      }
      if (aiPlanGetIsIDValid(gEconomyResearchPlan) == true)
      {
         int curPri = aiPlanGetPriority(gEconomyResearchPlan);
         aiPlanSetPriority(gEconomyResearchPlan, curPri - 15);
      }
      gCeasefireBoomActive = false;
      debugStrategy("49: ceasefire ended - boom mode reverted");
   }
}

rule ceasefireBoomMonitor
inactive
group defaultClassicalRules
minInterval 10
{
   manageCeasefireBoom();
}

//------------------------------------------------------------------------------
// 50: Endgame Wonder/Titan race detection
// Pokud enemy stavi Wonder/Titan Gate, force max-aggressive attack mode -
// musime to znicit jeste pred dokoncenim.
//------------------------------------------------------------------------------
void monitorEnemyEndgameRace()
{
   int now = xsGetTime();

   bool enemyBuildingThreat = false;
   for (int p = 1; p <= cNumberPlayers; p++)
   {
      if (p == cMyID) { continue; }
      if (kbPlayerIsEnemy(p) == false) { continue; }
      if (kbPlayerHasLost(p)) { continue; }

      int wonderBuild = kbUnitCount(cUnitTypeWonder, p, cUnitStateBuilding);
      int titanGate   = kbUnitCount(cUnitTypeTitanGate, p, cUnitStateBuilding);
      if (wonderBuild >= 1 || titanGate >= 1)
      {
         enemyBuildingThreat = true;
         break;
      }
   }

   if (enemyBuildingThreat == true)
   {
      if (gEnemyEndgameRaceActive == false)
      {
         gEnemyEndgameRaceActive = true;
         gEnemyEndgameRaceStart = now;
         // Max aggressive
         gAdaptAttackIntervalBonus = -90;
         gMilitaryUrgency = 1.0;
         // Force attack interval ignore
         xsRuleIgnoreIntervalOnce("attackManager");
         debugStrategy("50: ENEMY ENDGAME RACE detected (Wonder/TitanGate) - max aggressive!");
         aiEchoWarning("50: enemy building Wonder/Titan - emergency attack!");
      }
      else
      {
         // Stale aktivni - retry attack manager kazdou iteraci
         xsRuleIgnoreIntervalOnce("attackManager");
      }
   }
   else if (gEnemyEndgameRaceActive == true)
   {
      gEnemyEndgameRaceActive = false;
      gAdaptAttackIntervalBonus = 0;
      debugStrategy("50: enemy endgame race ended");
   }
}

rule enemyEndgameRaceMonitor
inactive
group defaultClassicalRules
minInterval 12
{
   monitorEnemyEndgameRace();
}
