//==============================================================================
/* military_attack.xs

   This file is intended for any land/air military unit attack handling.

*/
//==============================================================================

class BAttackManager
{
   // Must attack reasons.
   bool mRagnarokActive = false;
   bool mUnderworldActive = false;
   bool mExcessResources = false;
   bool mKOTHAttack = false;
   bool mKOTHPanic = false;

   // Can't attack reasons.
   bool mCeasefireActive = false;
   bool mEnemyRagnarokActive = false;
   bool mPrimaryLandDefendPlanIsEngaged = false;

   // States.
   int mState = cStateNormal;
   int mScoutingState = cNoScoutingNeeded;

   void updateState()
   {
      bool haveTitan = kbUnitCount(cUnitTypeAbstractTitan, cMyID, cUnitStateAlive) >= 1;
      bool haveTitanGate = kbUnitCount(cUnitTypeTitanGate, cMyID, cUnitStateBuilding) >= 1;
      mRagnarokActive = (kbUnitCount(cUnitTypeHeroOfRagnarok, cMyID, cUnitStateAlive) +
                         kbUnitCount(cUnitTypeHeroOfRagnarokDwarf, cMyID, cUnitStateAlive)) >= 10;
                         
      if ((cVictoryTypesCurrent & cVictoryTypeKingOfTheHill) != 0)
      {
         if (gKOTHIsOwnedByAllies == false)
         {
            debugMilitaryAttacking("KOTH Attack!");
            mKOTHAttack = true;
            mKOTHPanic = false;
            mState = cStateNormal;
            if (getRemainingKOTHTime() < 240)
            {
               debugMilitaryAttacking("KOTH PANIC!");
               mKOTHPanic = true;
               mState = cStateForcedAttack;
            }
            return;
         }
         else
         {
            // BUG FIX v1.0: reset KOTH flags when allies own the hill
            mKOTHAttack = false;
            mKOTHPanic = false;
         }
      }
      if (mScoutingState == cScoutingForEnemies || mScoutingState == cNoEnemies)
      {
         mState = cStateNeedScouting;
         return;
      }
      if (mCeasefireActive == true || mEnemyRagnarokActive == true  ||
          mPrimaryLandDefendPlanIsEngaged == true || gDefenseReflexBaseID != -1 || haveTitanGate == true)
      {
         mState = cStateForcedCantAttack;
         return;
      }
      if (kbGodPowerCheckActive(cProtoPowerFlamingWeapons, cMyID) == true || mRagnarokActive == true ||
          mUnderworldActive == true || haveTitan == true)
      {
         mState = cStateForcedAttack;
         return;
      }
      // Age up has a lower "priority" than the forced attack states.
      if (aiPlanGetIsIDValid(gAgeUpResearchPlan) == true && aiPlanGetPriority(gAgeUpResearchPlan) > 50 &&
          kbTechGetPercentComplete(aiPlanGetVariableInt(gAgeUpResearchPlan, cResearchPlanTechID, 0)) == 0.0)
      {
         mState = cStateForcedCantAttack;
         return;
      }
      mState = cStateNormal;
   }

   // Timers.
   int mLastAttackTime = 0;
   int mBaseAttackInterval = 180;
   int mAttackInterval = 180;
   bool waitedLongEnough()
   {
      if (mLastAttackTime + mAttackInterval < xsGetTime())
      {
         return true;
      }
      return false;
   }

   // Minimum attack size.
   int mMinimumAttackSize = 0;

   // Even if our allowed military pop is 5 and we have 7 pop it doesn't mean we should attack.
   // Such a situation basically indicates that we lost all our eco and we should actually rebuild instead.
   // Based on difficulty set some minimum attack sizes.
   void calculateMinAttackSizes()
   {
      // Static numbers for lower difficulties, they never unlock full eco etc...
      switch (cDifficultyCurrent)
      {
         case cDifficultyEasy:
         {
            mMinimumAttackSize = 5;
            return;
         }
         case cDifficultyModerate:
         {
            mMinimumAttackSize = 10;
            return;
         }
         case cDifficultyHard:
         {
            mMinimumAttackSize = 15;
            return;
         }
      }
      // Dynamic calculation for difficulties that progress through the game unchecked.
      mMinimumAttackSize = (8 * kbPlayerGetAge(cMyID)) + (3 * cDifficultyCurrent);
   }
};
extern BAttackManager gAttackManager;

//==============================================================================
// mostHatedEnemy
// Determine who we should attack, checking gOverrideTargetPlayerID too.
//==============================================================================
rule mostHatedEnemy
minInterval 60
group defaultClassicalRules
inactive
{
   debugMilitaryAttacking("--- Running Rule mostHatedEnemy. ---");

   if (gOverrideTargetPlayerID > 0)
   {
      debugMilitaryAttacking("Override found: changing MostHatedPlayerID to: " + gOverrideTargetPlayerID + ", 700 means don't attack");
      aiSetMostHatedPlayerID(gOverrideTargetPlayerID);
      return;
   }

   int numberEnemiesWithVisibleBases = 0;
   int numberEnemies = 0;
   gArrayEnemyPlayerIDs.clear();
   int[] sameIslandEnemyPlayers = new int(0, 0);
   int ourAreaGroup = kbAreaGroupGetIDByPosition(aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0));
   // Add IDs of enemies who are still alive to the array.
   for (int i = 1; i <= cNumberPlayers; i++)
   {
      if (i != cMyID)
      {
         if (kbPlayerIsEnemy(i) == true)
         {
            if (kbPlayerHasLost(i) == false)
            {
               numberEnemies++;
               int numBases = kbBaseGetNumber(i); 
               if (numBases > 0)
               {
                  gArrayEnemyPlayerIDs.add(i);
                  numberEnemiesWithVisibleBases++;
                  for (int iBase = 0; iBase < numBases; iBase++)
                  {
                     vector loc = kbBaseGetLocation(i, kbBaseGetIDByIndex(i, iBase));
                     int areaGroup = kbAreaGroupGetIDByPosition(loc);
                     if (ourAreaGroup == areaGroup)
                     {
                        sameIslandEnemyPlayers.add(i);
                        break;
                     }
                  }
               }
               // No bases visible, but it's a random map, do some "cheating".
               else if (cGameTypeCurrent == cGameTypeRandomMap)
               {
                  vector startingPos = kbPlayerGetStartingPosition(i);
                  // If we have never scouted the starting position of the player we will still include them in the enemy array.
                  // Basically we can assume the player still has a base at this location.
                  // And human players also know where the players have spawned, so yes we cheat here a bit but players also know.
                  if (kbLocationFogged(startingPos) == true || kbLocationVisible(startingPos) == true)
                  {
                     continue;
                  }
                  gArrayEnemyPlayerIDs.add(i);
                  numberEnemiesWithVisibleBases++;
                  debugMilitaryAttacking("Including player " + i + " into the enemy array because we haven't scouted their starting position.");
               }
            }
         }
      }
   }
   if (numberEnemiesWithVisibleBases == 0)
   {
      if (numberEnemies > 0)
      {
         debugMilitaryAttacking("We currently have enemies, we just have no bases of them scouted, starting scouting logic.");
         gAttackManager.mScoutingState = cScoutingForEnemies;
         aiSetMostHatedPlayerID(-1);
         return;
      }
      else
      {
         debugMilitaryAttacking("We currently have no enemies, waiting.");
         gAttackManager.mScoutingState = cNoEnemies;
         aiSetMostHatedPlayerID(-1);
         return;
      }
   }
   gAttackManager.mScoutingState = cNoScoutingNeeded;
   int selectedEnemyPlayerID = 0;
   if (gIsFFA == true) // v1.0: v FFA vybirame nejslabsiho nepritele (nejmene vojenske populace)
   {
      // v2.6 IMP5: preferujeme nejslabsiho nepritele NA STEJNEM OSTROVE pred globalnim nejslabsim.
      // Bylo: vzdy globalne nejslabsi -> AI mohla preplouvat pro vzdaleneho nepritele misto toho na ostrove.
      int weakestPlayerID = gArrayEnemyPlayerIDs[0];
      int weakestMilPop = 999999;
      int weakestSameIslandID = -1;
      int weakestSameIslandPop = 999999;
      for (int ffa_i = 0; ffa_i < numberEnemiesWithVisibleBases; ffa_i++)
      {
         int candidateID = gArrayEnemyPlayerIDs[ffa_i];
         int candidateMilPop = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, candidateID, cUnitStateAlive);
         // Zkontroluj zda je kandidat na stejnem ostrove jako my
         bool candidateSameIsland = false;
         for (int si_check = 0; si_check < sameIslandEnemyPlayers.size(); si_check++)
         {
            if (sameIslandEnemyPlayers[si_check] == candidateID) { candidateSameIsland = true; break; }
         }
         if (candidateSameIsland == true && candidateMilPop < weakestSameIslandPop)
         {
            weakestSameIslandPop = candidateMilPop;
            weakestSameIslandID = candidateID;
         }
         if (candidateMilPop < weakestMilPop)
         {
            weakestMilPop = candidateMilPop;
            weakestPlayerID = candidateID;
         }
      }
      if (weakestSameIslandID != -1)
      {
         selectedEnemyPlayerID = weakestSameIslandID;
         debugMilitaryAttacking("FFA v2.6 IMP5: nejslabsi na stejnem ostrove ID=" + selectedEnemyPlayerID + " milpop=" + weakestSameIslandPop);
      }
      else
      {
         selectedEnemyPlayerID = weakestPlayerID;
         debugMilitaryAttacking("FFA v1.0: nejslabsi nepritel (zadny na ostrove) ID=" + selectedEnemyPlayerID + " milpop=" + weakestMilPop);
      }
   }
   else
   {
      int numEnemiesOnSameIsland = sameIslandEnemyPlayers.size();
      if (numEnemiesOnSameIsland != 0)
      {
         // v2.6 IMP4: zachovat aktualni cil pro kontinuitu utoku pokud je na stejnem ostrove.
         // Bylo: xsRandInt -> prepinani cile kazdu minutu v team hrach = roztristeny utocny tlak.
         // Nyni: preferujeme stávajici mostHatedPlayerID; zmena jen kdyz neni na stejnem ostrove.
         int currentTarget = aiGetMostHatedPlayerID();
         bool currentTargetOnSameIsland = false;
         for (int si_curr = 0; si_curr < numEnemiesOnSameIsland; si_curr++)
         {
            if (sameIslandEnemyPlayers[si_curr] == currentTarget)
            {
               currentTargetOnSameIsland = true;
               break;
            }
         }
         if (currentTargetOnSameIsland == true)
         {
            selectedEnemyPlayerID = currentTarget;
            debugMilitaryAttacking("v2.6 IMP4: Zachovavam aktualni cil ID=" + selectedEnemyPlayerID + " (na stejnem ostrove).");
         }
         else
         {
            // Aktualni cil neni na stejnem ostrove - vybrat nejslabsiho ze stejno-ostrovnich nepritratel
            int weakestSIID = sameIslandEnemyPlayers[0];
            int weakestSIPop = 999999;
            for (int si_w = 0; si_w < numEnemiesOnSameIsland; si_w++)
            {
               int siCandID = sameIslandEnemyPlayers[si_w];
               int siCandPop = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, siCandID, cUnitStateAlive);
               if (siCandPop < weakestSIPop)
               {
                  weakestSIPop = siCandPop;
                  weakestSIID = siCandID;
               }
            }
            selectedEnemyPlayerID = weakestSIID;
            debugMilitaryAttacking("v2.6 IMP4: Aktualni cil neni na ostrove, vybiram nejslabsiho ID=" + selectedEnemyPlayerID);
         }
      }
      else
      {
         debugMilitaryAttacking("Randomly picking from enemies on other islands.");
         selectedEnemyPlayerID = gArrayEnemyPlayerIDs[xsRandInt(0, numberEnemiesWithVisibleBases - 1)];
      }
   }
   aiSetMostHatedPlayerID(selectedEnemyPlayerID);
   debugMilitaryAttacking("Selected Player " + selectedEnemyPlayerID + " to be our MostHatedPlayerID.");
}

//==============================================================================
// attackPlanHasTitan
//==============================================================================
bool attackPlanHasTitan()
{
   return (kbUnitCount(cUnitTypeAbstractTitan, cMyID, cUnitStateAlive) >= 1);
}

//==============================================================================
// getVisibleEnemyLandMilitaryCountNearPosition
//==============================================================================
int getVisibleEnemyLandMilitaryCountNearPosition(vector location = cInvalidVector, float radius = 25.0)
{
   if (kbGetIsLocationOnMap(location) == false)
   {
      return 0;
   }

   return getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
                                 location, radius, cUnitQueryVisibleStateVisible);
}

//==============================================================================
// setTitanAttackPlanTargetUnitTypes
//==============================================================================
void setTitanAttackPlanTargetUnitTypes(int attackPlanID = -1, bool closeQuarters = false)
{
   if (aiPlanGetIsIDValid(attackPlanID) == false)
   {
      return;
   }

   if (closeQuarters == true)
   {
      // v2.3: v hustem surroundu zjednodus seznam cilu, aby Titan nepreskakoval mezi class-specific targety.
      aiPlanSetNumberVariableValues(attackPlanID, cAttackPlanTargetUnitTypes, 2); // bylo 3/5
      aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetUnitTypes, 0, cUnitTypeMilitaryUnit);
      aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetUnitTypes, 1, cUnitTypeAbstractTitan);
      return;
   }

   // v2.3: Titan plan pouziva sirsi, ale stale jednodussi unit set nez generic hand/ranged/myth/siege split.
   aiPlanSetNumberVariableValues(attackPlanID, cAttackPlanTargetUnitTypes, 3); // bylo 5 pres setDefaultAttackPlanTargetUnitTypes()
   aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetUnitTypes, 0, cUnitTypeMilitaryUnit);
   aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetUnitTypes, 1, cUnitTypeBuilding);
   aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetUnitTypes, 2, cUnitTypeAbstractTitan);
}

//==============================================================================
// setTitanDefendPlanTargetUnitTypes
//==============================================================================
void setTitanDefendPlanTargetUnitTypes(int defendPlanID = -1, bool closeQuarters = false)
{
   if (aiPlanGetIsIDValid(defendPlanID) == false)
   {
      return;
   }

   if (closeQuarters == true)
   {
      aiPlanSetNumberVariableValues(defendPlanID, cDefendPlanTargetUnitTypes, 2); // bylo 2/5
      aiPlanSetVariableInt(defendPlanID, cDefendPlanTargetUnitTypes, 0, cUnitTypeMilitaryUnit);
      aiPlanSetVariableInt(defendPlanID, cDefendPlanTargetUnitTypes, 1, cUnitTypeAbstractTitan);
      return;
   }

   aiPlanSetNumberVariableValues(defendPlanID, cDefendPlanTargetUnitTypes, 2); // bylo 5 pres setDefaultDefendPlanTargetUnitTypes()
   aiPlanSetVariableInt(defendPlanID, cDefendPlanTargetUnitTypes, 0, cUnitTypeMilitaryUnit);
   aiPlanSetVariableInt(defendPlanID, cDefendPlanTargetUnitTypes, 1, cUnitTypeAbstractTitan);
}

//==============================================================================
// getTitanPressureLevel
// 0 = normal, 1 = local melee, 2 = dense surround
//==============================================================================
int getTitanPressureLevel(int titanID = -1)
{
   if (kbUnitGetIsIDValid(titanID) == false)
   {
      return 0;
   }

   vector titanPosition = kbUnitGetPosition(titanID);
   int veryCloseEnemies = getVisibleEnemyLandMilitaryCountNearPosition(titanPosition, 20.0);
   int nearbyEnemies = getVisibleEnemyLandMilitaryCountNearPosition(titanPosition, 28.0);

   if (veryCloseEnemies >= 6 || nearbyEnemies >= 10)
   {
      return 2;
   }
   if (veryCloseEnemies >= 3 || nearbyEnemies >= 6)
   {
      return 1;
   }
   return 0;
}

//==============================================================================
// configureAttackPlanTactics
//==============================================================================
void configureAttackPlanTactics(int planID = -1, bool titanAssault = false)
{
   if (aiPlanGetIsIDValid(planID) == false)
   {
      return;
   }

   // v2.2: nove explicitni engage/movement nastaveni - drive se spolehalo na implicitni defaulty.
   aiPlanSetVariableFloat(planID, cAttackPlanAttackModeEngageRange, 0, 45.0); // bylo: implicit/default
   aiPlanSetVariableInt(planID, cAttackPlanMovementIntervalTime, 0, 5000); // bylo: implicit/default

   if (titanAssault == true)
   {
      aiPlanSetVariableFloat(planID, cAttackPlanAttackModeEngageRange, 0, 55.0); // bylo 45.0
      aiPlanSetVariableInt(planID, cAttackPlanMovementIntervalTime, 0, 6000); // bylo 5000
      aiPlanSetVariableInt(planID, cAttackPlanGatherWaitTime, 0, 45 * 1000); // bylo 30 * 1000
      aiPlanSetVariableFloat(planID, cAttackPlanGatherDistance, 0, 20.0); // bylo 15.0
      aiPlanSetVariableBool(planID, cAttackPlanAllowMoreUnitsDuringAttack, 0, true); // bylo false
      aiPlanSetVariableInt(planID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternBest); // bylo Random v create*AttackPlan()
      aiPlanSetVariableBool(planID, cAttackPlanPersistentAttackRoute, 0, true); // bylo implicit false
      setTitanAttackPlanTargetUnitTypes(planID, false); // bylo generic 5-type target list
   }
}

//==============================================================================
// addTitanToPlan
//==============================================================================
void addTitanToPlan(int planID = -1)
{
   if (aiPlanGetIsIDValid(planID) == false)
   {
      return;
   }

   // v2.2: Titan dostava explicitni slot v hlavnim planu - nespolihat, ze spadne pod generic land military.
   aiPlanAddUnitType(planID, cUnitTypeAbstractTitan, 0, 0, 1);
   int titanID = getUnit(cUnitTypeAbstractTitan, cMyID, cUnitStateAlive);
   if (kbUnitGetIsIDValid(titanID) == true)
   {
      aiPlanAddUnit(planID, titanID);
   }
}

//==============================================================================
// getBestTitanAttackPlan
//==============================================================================
int getBestTitanAttackPlan()
{
   int titanID = getUnit(cUnitTypeAbstractTitan, cMyID, cUnitStateAlive);
   int currentPlanID = -1;
   if (kbUnitGetIsIDValid(titanID) == true)
   {
      currentPlanID = kbUnitGetPlanID(titanID);
   }

   int bestPlanID = -1;
   int bestScore = -1;
   int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
   for (int i = 0; i < attackPlans.size(); i++)
   {
      if (aiPlanGetParentID(attackPlans[i]) != -1)
      {
         continue;
      }

      int score = aiPlanGetNumberUnits(attackPlans[i], -1, false);
      if (aiPlanGetState(attackPlans[i]) == cPlanStateAttack)
      {
         score += 50;
      }
      if (aiPlanGetVariableBool(attackPlans[i], cAttackPlanAllowMoreUnitsDuringAttack, 0) == true)
      {
         score += 25;
      }
      if (attackPlans[i] == currentPlanID)
      {
         score += 15;
      }
      if (score > bestScore)
      {
         bestScore = score;
         bestPlanID = attackPlans[i];
      }
   }

   return bestPlanID;
}

//==============================================================================
// updateTitanAttackPlanPressureTactics
//==============================================================================
void updateTitanAttackPlanPressureTactics(int planID = -1, int titanID = -1)
{
   if (aiPlanGetIsIDValid(planID) == false || kbUnitGetIsIDValid(titanID) == false)
   {
      return;
   }

   int pressureLevel = getTitanPressureLevel(titanID);
   if (pressureLevel >= 2)
   {
      // v2.3: kdyz je Titan obklopen, radikalne zmensi engage radius a zpomal retarget.
      aiPlanSetVariableFloat(planID, cAttackPlanAttackModeEngageRange, 0, 18.0); // bylo 55.0
      aiPlanSetVariableInt(planID, cAttackPlanMovementIntervalTime, 0, 12000); // bylo 6000
      aiPlanSetVariableInt(planID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternBest); // bylo Random
      aiPlanSetVariableBool(planID, cAttackPlanPersistentAttackRoute, 0, true); // bylo implicit false
      setTitanAttackPlanTargetUnitTypes(planID, true); // bylo broad titan target set
      return;
   }
   if (pressureLevel == 1)
   {
      // v2.3: pri mensi tlaku stale omez retarget churn, ale nech plan trochu sirsi.
      aiPlanSetVariableFloat(planID, cAttackPlanAttackModeEngageRange, 0, 26.0); // bylo 55.0
      aiPlanSetVariableInt(planID, cAttackPlanMovementIntervalTime, 0, 9000); // bylo 6000
      aiPlanSetVariableInt(planID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternBest); // bylo Random
      aiPlanSetVariableBool(planID, cAttackPlanPersistentAttackRoute, 0, true); // bylo implicit false
      setTitanAttackPlanTargetUnitTypes(planID, false); // bylo generic 5-type target list
      return;
   }

   configureAttackPlanTactics(planID, true);
}

//==============================================================================
// updateTitanDefendPlanPressureTactics
//==============================================================================
void updateTitanDefendPlanPressureTactics(int planID = -1, int titanID = -1)
{
   if (aiPlanGetIsIDValid(planID) == false || kbUnitGetIsIDValid(titanID) == false)
   {
      return;
   }

   int pressureLevel = getTitanPressureLevel(titanID);
   if (pressureLevel >= 2)
   {
      aiPlanSetVariableFloat(planID, cDefendPlanEngageRange, 0, 18.0); // bylo: base distance + 10.0 / 30.0 / 40.0
      aiPlanSetVariableInt(planID, cDefendPlanMovementIntervalTime, 0, 12000); // bylo implicit/default
      setTitanDefendPlanTargetUnitTypes(planID, true); // bylo generic 5-type defend set
      return;
   }
   if (pressureLevel == 1)
   {
      aiPlanSetVariableFloat(planID, cDefendPlanEngageRange, 0, 26.0); // bylo: base distance + 10.0 / 30.0 / 40.0
      aiPlanSetVariableInt(planID, cDefendPlanMovementIntervalTime, 0, 9000); // bylo implicit/default
      setTitanDefendPlanTargetUnitTypes(planID, false); // bylo generic 5-type defend set
      return;
   }

   float defaultEngageRange = aiPlanGetVariableFloat(planID, cDefendPlanEngageRange, 0);
   int baseID = aiPlanGetBaseID(planID);
   if (kbBaseGetIsIDValid(cMyID, baseID) == true)
   {
      defaultEngageRange = kbBaseGetDistance(cMyID, baseID) + 10.0;
   }
   aiPlanSetVariableFloat(planID, cDefendPlanEngageRange, 0, defaultEngageRange);
   aiPlanSetVariableInt(planID, cDefendPlanMovementIntervalTime, 0, 5000); // bylo implicit/default
   setTitanDefendPlanTargetUnitTypes(planID, false); // bylo generic 5-type defend set
}

//==============================================================================
// createUnitAttackPlan
//==============================================================================
int createUnitAttackPlan()
{
   // TODO this gather point should actually be the base our defend plan is active at later.
   vector gatherPoint = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);
   bool titanAssault = attackPlanHasTitan();
    
   int planID = aiPlanCreate("Attacking Units", cPlanAttack, -1, gMilitaryAttackingCategoryID);
   aiPlanSetVariableInt(planID, cAttackPlanTargetMode, 0, cAttackPlanTargetModePoint);

   aiPlanSetVariableVector(planID, cAttackPlanGatherPoint, 0, gatherPoint);
   aiPlanSetVariableFloat(planID, cAttackPlanGatherDistance, 0, 15.0);
   aiPlanSetVariableInt(planID, cAttackPlanGatherWaitTime, 0, 30 * 1000);
   aiPlanSetVariableInt(planID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
   aiPlanSetVariableInt(planID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeNoTarget);
   aiPlanAddUnitType(planID, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

   // Manually add all our defending units to this attack plan to make sure they all go attack.
   transferAllUnitsBetweenTwoPlans(gPrimaryLandDefendPlan, planID);
   addTitanToPlan(planID);
   setDefaultAttackPlanTargetUnitTypes(planID);
   configureAttackPlanTactics(planID, titanAssault);

   // If we have god power plans that need a combat plan to function we assign them this plan now.
   int[] godPowerPlans = aiPlanGetIDsByTypeAndVariableBoolValue(cPlanGodPower, cGodPowerPlanRequiresCombatPlan, true);
   for (int i = 0; i < godPowerPlans.size(); i++)
   {
      // If we already have a combat plan assigned to this god power plan we skip.
      if (aiPlanGetVariableInt(godPowerPlans[i], cGodPowerPlanCombatPlanID, 0) != -1)
      {
         continue;
      }
      aiPlanSetVariableInt(godPowerPlans[i], cGodPowerPlanCombatPlanID, 0, planID);
      debugMilitaryAttacking("Added god power plan: " + aiPlanGetName(godPowerPlans[i]) + ", to our new attack plan.");
   }

   // Find our enemies and put max 5 in our plan.
   int queryID = useSimpleUnitQuery(cUnitTypeLogicalTypeNeededForVictory, cPlayerRelationEnemyNotGaia, cUnitStateAlive);
   int[] excludeTypes = new int(1, cUnitTypeNavalUnit);
   kbUnitQuerySetExcludeTypes(queryID, excludeTypes);
   kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateRecentPositionKnown);
   int numResults = kbUnitQueryExecute(queryID);
   int[] results = kbUnitQueryGetResults(queryID);
   if (numResults <= 0)
   {
      aiEchoWarning("Calling createUnitAttackPlan but there are no valid units to go attack, check this beforehand.");
      aiPlanDestroy(planID);
      return -1;
   }

   bool needToTransport = false;
   int ownAreaGroupID = kbAreaGroupGetIDByPosition(gatherPoint);
   aiPlanSetNumberVariableValues(planID, cAttackPlanTargetPoint, min(numResults, 5));
   if (numResults <= 5)
   {
      for (int i = 0; i < numResults; i++)
      {
         vector unitPosition = kbUnitGetPosition(results[i]);
         aiPlanSetVariableVector(planID, cAttackPlanTargetPoint, i, unitPosition);
         if (needToTransport == false && ownAreaGroupID != kbAreaGroupGetIDByPosition(unitPosition))
         {
            needToTransport = true;
         }
      }
   }
   else
   {
      // If we hit this again with another attack plan we hope we don't walk towards the same enemies basically.
      int startIndex = xsRandInt(0, numResults - 1);
      for (int i = 0; i < 5; i++)
      {
         if (startIndex >= numResults)
         {
            startIndex = 0;
         }
         vector unitPosition = kbUnitGetPosition(results[startIndex]); // BUG FIX v1.0: bylo results[i], spravne results[startIndex]
         aiPlanSetVariableVector(planID, cAttackPlanTargetPoint, i, unitPosition);
         if (needToTransport == false && ownAreaGroupID != kbAreaGroupGetIDByPosition(unitPosition))
         {
            needToTransport = true;
         }
         startIndex++;
      }
   }

   if (needToTransport == true)
   {
      aiPlanSetVariableInt(planID, cAttackPlanMovementTypeFlags, 0, cPassabilityLand | cPassabilityWater);
   }
   else
   {
      aiPlanSetVariableInt(planID, cAttackPlanMovementTypeFlags, 0, cPassabilityLand);
   }
   
   aiPlanSetPriority(planID, 99);
   // Don't reduce this attack's size while underway.
   aiPlanSetFlag(planID, cPlanFlagCantBeStolenFrom, true);
   return planID;
}

//==============================================================================
// createKOTHAttackPlan
//==============================================================================
int createKOTHAttackPlan()
{
   vector gatherPoint = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);
   bool titanAssault = attackPlanHasTitan();
    
   int planID = aiPlanCreate("Attack: recapture KOTH", cPlanAttack, -1, gMilitaryAttackingCategoryID);
   aiPlanSetVariableInt(planID, cAttackPlanTargetMode, 0, cAttackPlanTargetModePoint);
   aiPlanSetVariableVector(planID, cAttackPlanTargetPoint, 0, gKOTHPosition);

   if (gMapInfo.mKOTHIsOnDifferentIsland == true)
   {
      aiPlanSetVariableInt(planID, cAttackPlanMovementTypeFlags, 0, cPassabilityLand | cPassabilityWater);
   }
   else
   {
      aiPlanSetVariableInt(planID, cAttackPlanMovementTypeFlags, 0, cPassabilityLand);
   }
   aiPlanSetVariableVector(planID, cAttackPlanGatherPoint, 0, gatherPoint);
   aiPlanSetVariableFloat(planID, cAttackPlanGatherDistance, 0, 15.0);
   aiPlanSetVariableInt(planID, cAttackPlanGatherWaitTime, 0, 30 * 1000);
   aiPlanSetVariableInt(planID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
   aiPlanSetVariableInt(planID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeNoTarget);
   if (gAttackManager.mKOTHPanic == true)
   {
      aiPlanSetVariableBool(planID, cAttackPlanAllowMoreUnitsDuringAttack, 0 , true);
   }
   aiPlanAddUnitType(planID, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

   // Manually add all our defending units to this attack plan to make sure they all go attack.
   transferAllUnitsBetweenTwoPlans(gPrimaryLandDefendPlan, planID);
   addTitanToPlan(planID);
   setDefaultAttackPlanTargetUnitTypes(planID);
   configureAttackPlanTactics(planID, titanAssault);

   // If we have god power plans that need a combat plan to function we assign them this plan now.
   int[] godPowerPlans = aiPlanGetIDsByTypeAndVariableBoolValue(cPlanGodPower, cGodPowerPlanRequiresCombatPlan, true);
   for (int i = 0; i < godPowerPlans.size(); i++)
   {
      // If we already have a combat plan assigned to this god power plan we skip.
      if (aiPlanGetVariableInt(godPowerPlans[i], cGodPowerPlanCombatPlanID, 0) != -1)
      {
         continue;
      }
      aiPlanSetVariableInt(godPowerPlans[i], cGodPowerPlanCombatPlanID, 0, planID);
      debugMilitaryAttacking("Added god power plan: " + aiPlanGetName(godPowerPlans[i]) + ", to our new attack plan.");
   }

   aiPlanSetPriority(planID, 99);
   // Don't reduce this attack's size while underway.
   aiPlanSetFlag(planID, cPlanFlagCantBeStolenFrom, true);
   return planID;
}

//==============================================================================
// createDefaultAttackPlan
//==============================================================================
int createDefaultAttackPlan(int targetPlayer = -1, int targetBaseID = -1)
{
   vector gatherPoint = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);
   bool titanAssault = attackPlanHasTitan();
   int planID = aiPlanCreate("Attack Player " + targetPlayer + " Base " + kbBaseGetNameByID(targetPlayer, targetBaseID),
                              cPlanAttack, -1, gMilitaryAttackingCategoryID);

   aiPlanSetVariableInt(planID, cAttackPlanTargetMode, 0, cAttackPlanTargetModeBase);
   aiPlanSetVariableInt(planID, cAttackPlanTargetBaseID, 0, targetBaseID);
   aiPlanSetVariableInt(planID, cAttackPlanTargetPlayerID, 0, targetPlayer);

   if (kbAreaGroupGetIDByPosition(gatherPoint) != kbAreaGroupGetIDByPosition(kbBaseGetLocation(targetPlayer, targetBaseID)))
   {
      aiPlanSetVariableInt(planID, cAttackPlanMovementTypeFlags, 0, cPassabilityLand | cPassabilityWater);
   }
   else
   {
      aiPlanSetVariableInt(planID, cAttackPlanMovementTypeFlags, 0, cPassabilityLand);
   }
   aiPlanSetVariableVector(planID, cAttackPlanGatherPoint, 0, gatherPoint);
   aiPlanSetVariableFloat(planID, cAttackPlanGatherDistance, 0, 15.0);
   aiPlanSetVariableInt(planID, cAttackPlanGatherWaitTime, 0, 30 * 1000);
   aiPlanSetVariableInt(planID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
   aiPlanSetVariableInt(planID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeCantFindMoreEnemyBases);

   aiPlanAddUnitType(planID, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

   // Keep behind some builders so we don't get stuck.
   if (cDifficultyCurrent >= cDifficultyHard && cMyCulture == cCultureNorse)
   {
      int[] units = aiPlanGetUnits(gPrimaryLandDefendPlan);
      int numRemoved = 0;
      for (int i = 0; i < units.size(); i++)
      {
         if (kbUnitIsType(units[i], cUnitTypeLogicalTypeNorseSoldierThatBuilds) == true)
         {
            debugMilitaryAttacking("Removing " + kbProtoUnitGetName(kbUnitGetProtoUnitID(units[i])) + " " + units[i] +
               " from attack plan to remain as an available builder.");
            numRemoved++;
            aiPlanRemoveUnit(gPrimaryLandDefendPlan, units[i]);
         }
         if (numRemoved >= 2)
         {
            break;
         }
      }
   }
   // Manually add all our defending units to this attack plan to make sure they all go attack.
   transferAllUnitsBetweenTwoPlans(gPrimaryLandDefendPlan, planID);
   addTitanToPlan(planID);
   setDefaultAttackPlanTargetUnitTypes(planID);
   configureAttackPlanTactics(planID, titanAssault);

   // If we have god power plans that need a combat plan to function we assign them this plan now.
   int[] godPowerPlans = aiPlanGetIDsByTypeAndVariableBoolValue(cPlanGodPower, cGodPowerPlanRequiresCombatPlan, true);
   for (int i = 0; i < godPowerPlans.size(); i++)
   {
      // If we already have a combat plan assigned to this god power plan we skip.
      if (aiPlanGetVariableInt(godPowerPlans[i], cGodPowerPlanCombatPlanID, 0) != -1)
      {
         continue;
      }
      aiPlanSetVariableInt(godPowerPlans[i], cGodPowerPlanCombatPlanID, 0, planID);
      debugMilitaryAttacking("Added god power plan: " + aiPlanGetName(godPowerPlans[i]) + ", to our new attack plan.");
   }

   aiPlanSetPriority(planID, 99);
   // Don't reduce this attack's size while underway.
   aiPlanSetFlag(planID, cPlanFlagCantBeStolenFrom, true);
   return planID;
}

//==============================================================================
// createAttackPlanToPoint
//==============================================================================
int createAttackPlanToPoint(int targetPlayer = -1, vector targetPosition = cInvalidVector)
{
   vector gatherPoint = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);
   bool titanAssault = attackPlanHasTitan();
   int planID = aiPlanCreate("Attack Player " + targetPlayer + " Position " + targetPosition, cPlanAttack, -1,
                              gMilitaryAttackingCategoryID);

   aiPlanSetVariableInt(planID, cAttackPlanTargetMode, 0, cAttackPlanTargetModePoint);
   aiPlanSetVariableVector(planID, cAttackPlanTargetPoint, 0, targetPosition);

   aiPlanSetVariableVector(planID, cAttackPlanGatherPoint, 0, gatherPoint);
   aiPlanSetVariableFloat(planID, cAttackPlanGatherDistance, 0, 15.0);
   aiPlanSetVariableInt(planID, cAttackPlanGatherWaitTime, 0, 30 * 1000);
   aiPlanSetVariableInt(planID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
   aiPlanSetVariableInt(planID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeNoTarget);
   aiPlanAddUnitType(planID, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

   // Keep behind some builders so we don't get stuck.
   if (cDifficultyCurrent >= cDifficultyHard && cMyCulture == cCultureNorse)
   {
      int[] units = aiPlanGetUnits(gPrimaryLandDefendPlan);
      int numRemoved = 0;
      for (int i = 0; i < units.size(); i++)
      {
         if (kbUnitIsType(units[i], cUnitTypeLogicalTypeNorseSoldierThatBuilds) == true)
         {
            debugMilitaryAttacking("Removing " + kbProtoUnitGetName(kbUnitGetProtoUnitID(units[i])) + " " + units[i] +
               " from attack plan to remain as an available builder.");
            numRemoved++;
            aiPlanRemoveUnit(gPrimaryLandDefendPlan, units[i]);
         }
         if (numRemoved >= 2)
         {
            break;
         }
      }
   }
   // Manually add all our defending units to this attack plan to make sure they all go attack.
   transferAllUnitsBetweenTwoPlans(gPrimaryLandDefendPlan, planID);
   addTitanToPlan(planID);
   setDefaultAttackPlanTargetUnitTypes(planID);
   configureAttackPlanTactics(planID, titanAssault);

   // If we have god power plans that need a combat plan to function we assign them this plan now.
   int[] godPowerPlans = aiPlanGetIDsByTypeAndVariableBoolValue(cPlanGodPower, cGodPowerPlanRequiresCombatPlan, true);
   for (int i = 0; i < godPowerPlans.size(); i++)
   {
      // If we already have a combat plan assigned to this god power plan we skip.
      if (aiPlanGetVariableInt(godPowerPlans[i], cGodPowerPlanCombatPlanID, 0) != -1)
      {
         continue;
      }
      aiPlanSetVariableInt(godPowerPlans[i], cGodPowerPlanCombatPlanID, 0, planID);
      debugMilitaryAttacking("Added god power plan: " + aiPlanGetName(godPowerPlans[i]) + ", to our new attack plan.");
   }

   aiPlanSetPriority(planID, 99);
   // Don't reduce this attack's size while underway.
   aiPlanSetFlag(planID, cPlanFlagCantBeStolenFrom, true);
   return planID;
}

//==============================================================================
// calculateTargetBase
//==============================================================================
int calculateTargetBase(int targetPlayer = -1)
{
   int numberBases = kbBaseGetNumber(targetPlayer);
   if (numberBases == 0)
   {
      // If this happens our mostHatedEnemy rule will notify the scouting code soon.
      debugMilitaryAttacking("Our targetPlayer (" + targetPlayer + ") has no bases to attack!");
      return -1;
   }

   vector ownArmyPosition = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);
   int ownAreaGroupID = kbAreaGroupGetIDByPosition(ownArmyPosition);
   bool titanAssault = attackPlanHasTitan();
   int targetBaseID = -1;
   float highestScore = 0.0; // BUG FIX v1.0: bylo int, spravne float

   debugMilitaryAttacking("calculateTargetBase - Calculating player: " + targetPlayer + ", who has numberBases: " + numberBases);
   // Go through all players' bases and calculate values for comparison.
   for (int baseIndex = 0; baseIndex < numberBases; baseIndex++)
   {
      int baseID = kbBaseGetIDByIndex(targetPlayer, baseIndex);
      vector baseLocation = kbBaseGetLocation(targetPlayer, baseID);
      float baseAssets = 0.0; // BUG FIX v1.0: bylo int, spravne float

      int queryID = useSimpleUnitQuery(cUnitTypeTartarianGate, cPlayerRelationAny, cUnitStateAlive, baseLocation, 45.0);
      if (kbUnitQueryExecute(queryID) >= 1)
      {
         debugMilitaryAttacking("Skipping base: " + kbBaseGetNameByID(targetPlayer, baseID) + ", because it has a Tartarian Gate in it.");
         continue;
      }

      int numberTC = kbBaseGetNumberUnitsOfType(targetPlayer, baseID, cUnitTypeAbstractSocketedTownCenter);
      baseAssets += numberTC * 1000;

      int numberTrainBuildings = kbBaseGetNumberUnitsOfType(targetPlayer, baseID, cUnitTypeLogicalTypeMilitaryProductionBuilding);
      baseAssets += numberTrainBuildings * 100;

      int numberEcoUnits = kbBaseGetNumberUnitsOfType(targetPlayer, baseID, cUnitTypeEconomicUnit);
      baseAssets += numberEcoUnits * 400; // v1.2: zvyseno z 200 - zniceni ekonomiky = rychlejsi vyhra

      if (titanAssault == true)
      {
         // v2.2: Titan ma preferovat tezke strukturialni cile a husta jadra zakladen.
         int numberFortresses = kbBaseGetNumberUnitsOfType(targetPlayer, baseID, cUnitTypeAbstractFortress);
         baseAssets += numberFortresses * 350.0; // bylo: 0.0
         int numberTowers = kbBaseGetNumberUnitsOfType(targetPlayer, baseID, cUnitTypeLogicalTypeBuildingsThatShoot);
         baseAssets += numberTowers * 80.0; // bylo: 0.0
         int numberWonders = kbBaseGetNumberUnitsOfType(targetPlayer, baseID, cUnitTypeWonder);
         baseAssets += numberWonders * 3000.0; // bylo: 0.0
      }

      if (baseAssets == 0)
      {
         int numberBuildings = kbBaseGetNumberUnitsOfType(targetPlayer, baseID, cUnitTypeBuilding);
         baseAssets += numberBuildings * 10.0;
      }

      // Ignore base when we have no good targets to attack.
      if (baseAssets == 0)
      {
         debugMilitaryAttacking("Skipping base: " + kbBaseGetNameByID(targetPlayer, baseID) + ", because it has nothing in it.");
         continue;
      }
      
      // Adjust for distance, over 400 meters away is 40% penalty.
      float distancePenalty = xsVectorLength(ownArmyPosition - baseLocation) / 1000.0;
      if (distancePenalty > 0.4)
      {
         distancePenalty = 0.4;
      }
      // Increase penalty by 40% if transporting is required.
      int baseAreaGroup = kbAreaGroupGetIDByPosition(baseLocation);
      if (ownAreaGroupID != baseAreaGroup)
      {
         distancePenalty = distancePenalty + 0.4;
      }
      distancePenalty = 1.0 - distancePenalty;

      float score = baseAssets * distancePenalty; // BUG FIX v1.0: bylo int, spravne float

      // v1.9: penalizuj zakladny s hodne siege kdyz detekovano ze nepritel pouziva hodne siege
      // Preferuj utocit na zakladny s mene obrannymi siege stroji
      if (gAdaptEnemyAttackSiegeRatio > 0.25)
      {
         int numSiegeInBase = kbBaseGetNumberUnitsOfType(targetPlayer, baseID, cUnitTypeAbstractSiegeWeapon);
         float siegePenaltyFactor = 1.0 - (xsIntToFloat(numSiegeInBase) * gAdaptEnemyAttackSiegeRatio * 0.05);
         if (siegePenaltyFactor < 0.5) { siegePenaltyFactor = 0.5; }
         score = score * siegePenaltyFactor;
         debugMilitaryAttacking("Base: " + kbBaseGetNameByID(targetPlayer, baseID) + " siege penalty: " + siegePenaltyFactor);
      }

      debugMilitaryAttacking("Base: " + kbBaseGetNameByID(targetPlayer, baseID) + ", has a score of: " + score);
      if (score > highestScore)
      {
         targetBaseID = baseID;
         highestScore = score;
      }
   }

   if (targetBaseID == -1)
   {
      debugMilitaryAttacking("We found no good base to attack. A base needs more than 0.0 score to be worth it.");
   }
   return targetBaseID;
}

//==============================================================================
// tryLaunchSecondFront - v1.2
// Pokud mame velkou armadu a jiz utocime, vysleme druhy utok na jinou zakladnu.
//==============================================================================
void tryLaunchSecondFront(int primaryTargetPlayer = -1, int primaryTargetBase = -1)
{
   if (cDifficultyCurrent < cDifficultyHard) { return; } // Pouze Hard+
   // v2.2: Titan ma zustat v jednom stabilnim hlavnim assaulte, ne splitovat armadu na vice front.
   if (attackPlanHasTitan() == true) { return; }

   // v2.4 BUG29 FIX: bylo aiPlanGetCurrentPopulation(gPrimaryLandDefendPlan) - vzdy vracelo 0,
   // protoze createDefaultAttackPlan() uz prevedl vsechny jednotky do utocneho planu pred volanim
   // tryLaunchSecondFront(). Check byl vzdy splnen -> druha fronta se nikdy nespustila.
   // Oprava: merime celkovy pocet zivych pozemnich vojaku (vcetne tech v utocnem planu).
   int armyPop = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive); // bylo: aiPlanGetCurrentPopulation(gPrimaryLandDefendPlan)
   int wantedPop = aiGetMilitaryPop();
   if (wantedPop <= 0) { return; }
   // Potrebujeme 1.5x minimalni velikost utoku navic
   if (armyPop < (gAttackManager.mMinimumAttackSize * 2)) { return; }

   // Overit ze jiz mame alespon jeden aktivni utocny plan
   int[] existingAttacks = aiPlanGetIDsByType(cPlanAttack);
   int activeAttackCount = 0;
   for (int i = 0; i < existingAttacks.size(); i++)
   {
      if (aiPlanGetParentID(existingAttacks[i]) == -1)
      {
         activeAttackCount++;
      }
   }
   if (activeAttackCount == 0) { return; } // Nespoustime druhou frontu bez prvni

   // Urcit ciloveho hrace a pocet zakladen pro druhou frontu
   int secondFrontTargetPlayer = primaryTargetPlayer; // Vychozi: druha zakladna tehoz hrace
   int numBases = kbBaseGetNumber(primaryTargetPlayer);

   if (numBases < 2)
   {
      // v2.5 IMP3: V FFA kdyz primarni cil ma jen 1 zakladnu, zkus cilit druheho nejslabsiho hrace.
      // Drive: okamzity return -> druha fronta v FFA se skoro nikdy nespustila.
      // Nyni: najdi nejslabsiho nepritele (krome primarniho cile) a zahlaj na nej druhou frontu.
      if (gIsFFA == false)
      {
         return; // Non-FFA: jen 1 zakladna, neni druha fronta
      }
      int ffa2EnemyID = -1;
      int ffa2WeakestPop = 999999;
      for (int ffaP = 1; ffaP <= cNumberPlayers; ffaP++)
      {
         if (ffaP == cMyID) { continue; }
         if (ffaP == primaryTargetPlayer) { continue; }
         if (kbPlayerIsEnemy(ffaP) == false) { continue; }
         if (kbPlayerHasLost(ffaP)) { continue; }
         if (kbBaseGetNumber(ffaP) == 0) { continue; }
         int ffaMP = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, ffaP, cUnitStateAlive);
         if (ffaMP < ffa2WeakestPop)
         {
            ffa2WeakestPop = ffaMP;
            ffa2EnemyID = ffaP;
         }
      }
      if (ffa2EnemyID == -1) { return; } // Zadny dalsi nepritel s viditelnou zakladnou
      secondFrontTargetPlayer = ffa2EnemyID;
      numBases = kbBaseGetNumber(secondFrontTargetPlayer);
      debugMilitaryAttacking("v2.5 FFA SecondFront: primarni cil ma 1 zakladnu, ciluji druheho nejslabsiho hrace ID=" + secondFrontTargetPlayer);
   }

   float secondHighestScore = 0.0;
   int secondTargetBase = -1;
   vector ownPos = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);
   int ownAreaGroup = kbAreaGroupGetIDByPosition(ownPos);

   for (int bi = 0; bi < numBases; bi++)
   {
      int bID = kbBaseGetIDByIndex(secondFrontTargetPlayer, bi);
      // Preskocit primarni zakladnu pouze kdyz ciluji stejneho hrace
      if (secondFrontTargetPlayer == primaryTargetPlayer && bID == primaryTargetBase) { continue; }
      float score = kbBaseGetNumberUnitsOfType(secondFrontTargetPlayer, bID, cUnitTypeAbstractSocketedTownCenter) * 1000.0;
      score += kbBaseGetNumberUnitsOfType(secondFrontTargetPlayer, bID, cUnitTypeEconomicUnit) * 400.0;
      score += kbBaseGetNumberUnitsOfType(secondFrontTargetPlayer, bID, cUnitTypeLogicalTypeMilitaryProductionBuilding) * 100.0;
      if (score > secondHighestScore)
      {
         secondHighestScore = score;
         secondTargetBase = bID;
      }
   }

   if (secondTargetBase == -1) { return; }

   // Vytvorime druhy utocny plan s mensi casti armady (max 40% dostupne populace)
   vector gatherPoint = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);
   int plan2ID = aiPlanCreate("SecondFront Player " + secondFrontTargetPlayer + " Base " + secondTargetBase, cPlanAttack,
                              -1, gMilitaryAttackingCategoryID);
   aiPlanSetVariableInt(plan2ID, cAttackPlanTargetMode, 0, cAttackPlanTargetModeBase);
   aiPlanSetVariableInt(plan2ID, cAttackPlanTargetBaseID, 0, secondTargetBase);
   aiPlanSetVariableInt(plan2ID, cAttackPlanTargetPlayerID, 0, secondFrontTargetPlayer);
   aiPlanSetVariableVector(plan2ID, cAttackPlanGatherPoint, 0, gatherPoint);
   aiPlanSetVariableFloat(plan2ID, cAttackPlanGatherDistance, 0, 15.0);
   aiPlanSetVariableInt(plan2ID, cAttackPlanGatherWaitTime, 0, 20 * 1000);
   aiPlanSetVariableInt(plan2ID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
   aiPlanSetVariableInt(plan2ID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeCantFindMoreEnemyBases);
   if (ownAreaGroup != kbAreaGroupGetIDByPosition(kbBaseGetLocation(secondFrontTargetPlayer, secondTargetBase)))
   {
      aiPlanSetVariableInt(plan2ID, cAttackPlanMovementTypeFlags, 0, cPassabilityLand | cPassabilityWater);
   }
   else
   {
      aiPlanSetVariableInt(plan2ID, cAttackPlanMovementTypeFlags, 0, cPassabilityLand);
   }
   int maxUnits = ceil(armyPop * 0.40);
   if (maxUnits < gAttackManager.mMinimumAttackSize) { maxUnits = gAttackManager.mMinimumAttackSize; }
   aiPlanAddUnitType(plan2ID, cUnitTypeLogicalTypeLandMilitary, gAttackManager.mMinimumAttackSize, gAttackManager.mMinimumAttackSize, maxUnits);
   setDefaultAttackPlanTargetUnitTypes(plan2ID);
   configureAttackPlanTactics(plan2ID, false);
   aiPlanSetPriority(plan2ID, 90); // Nizsi priorita nez primarni utok (99)
   debugMilitaryAttacking("v2.5 SecondFront: utocime zaroven na hrace " + secondFrontTargetPlayer + " zakladna " + kbBaseGetNameByID(secondFrontTargetPlayer, secondTargetBase));
}

//==============================================================================
// metRequirementsToAttack
//==============================================================================
bool metRequirementsToAttack(bool skipTimeCheck = false)
{
   bool result = true;
   int wantedMilitaryPop = aiGetMilitaryPop();
   // It can be that we run attackManager before the militaryManager and then metRequirementsToAttack doesn't work.
   if (wantedMilitaryPop == -1 && checkStrategyFlag(cStrategyFlagAutoTrainMilitaryUnits) == true)
   {
      debugMilitaryAttacking("We need to wait with attacking since we haven't run our militaryManager yet.");
      xsRuleIgnoreIntervalOnce("attackManager");
      return false;
   }
   int armyPopPower = aiPlanGetCurrentPopulation(gPrimaryLandDefendPlan);
   const float neededArmyRatio = 0.35; // v1.0: snizeno z 0.50 - AI utoci drive s mensi armadou
   int minPop = ceil(wantedMilitaryPop * neededArmyRatio);
   // If we're Norse we're going to keep 2 infantry at home to have builders available, so need more minpop to compensate.
   if (cDifficultyCurrent >= cDifficultyHard && cMyCulture == cCultureNorse)
   {
      minPop += 4;
   }
   if (armyPopPower < minPop)
   {
      debugMilitaryAttacking("Dynamic military pop calculation: can't attack: " + armyPopPower + "/" + minPop + ".");
      result = false;
   }
   else
   {
      debugMilitaryAttacking("Dynamic military pop calculation: allowed to attack: " + armyPopPower + "/" + minPop + ".");
   }

   if (armyPopPower < gAttackManager.mMinimumAttackSize)
   {
      debugMilitaryAttacking("Static military pop minimum limit: can't attack: " + armyPopPower + "/" + gAttackManager.mMinimumAttackSize + ".");
      result = false;
   }
   else
   {
      debugMilitaryAttacking("Static military pop minimum limit: allowed to attack: " + armyPopPower + "/" + gAttackManager.mMinimumAttackSize + ".");
   }

   // Hard and below must always perform the time check if they're not the attacker personality.
   // Titan and above, or below but attacker, can skip the timecheck if they have more than 70% of their wanted military or
   // if they have more than 1k excess in all resources (excluding favor).
   if (skipTimeCheck == false && ((cDifficultyCurrent <= cDifficultyHard && cPersonalityCurrent != cPersonalityAttacker) ||
       (armyPopPower < (wantedMilitaryPop * 0.70) && haveExcessResourceAmount(1000, cAllResources) == false)))
   {
      if (gAttackManager.waitedLongEnough() == false)
      {
         debugMilitaryAttacking("It's too early to launch an attack.");
         debugMilitaryAttacking("Next attack will happen at: " + turnNumberIntoTimeDisplay(gAttackManager.mLastAttackTime +
                                                                                           gAttackManager.mAttackInterval));
         result = false;
      }
      else
      {
         debugMilitaryAttacking ("We have waited long enough, we can attack.");
      }
   }
   else
   {
      debugMilitaryAttacking("Skipping the time check.");
   }

   debugMilitaryAttacking("metRequirementsToAttack returned " + xsBoolToString(result) + ".");
   return result;
}

//==============================================================================
// attackManager
// This rule analyzes the current situation in the game and decides if we should
// attack an enemy.
//==============================================================================
rule attackManager
inactive
group defaultClassicalRules
minInterval 15
{
   if (cDifficultyCurrent == cDifficultyEasy && cPersonalityCurrent != cPersonalityAttacker)
   {
      xsDisableRule("attackManager");
      return;
   }
   static bool firstRun = true;
   if (firstRun == true)
   {
      // During the first run the mostHatedEnemy rule is executed after the attackManager, so hack switch that order around.
      xsRuleIgnoreIntervalOnce("attackManager");
      firstRun = false;
      return;
   }
   if (checkStrategyFlag(cStrategyFlagCanAttack) == false)
   {
      return;
   }
   debugMilitaryAttacking("--- Running Rule attackManager. ---");
   
   gAttackManager.calculateMinAttackSizes();
   // v1.5 BUG FIX: pricteme adaptivni bonus AZ po base vypoctu, aby ho neprepisoval.
   // bylo: adaptAttackInterval() menil mMinimumAttackSize primo, ale tato linea ho kazdych 15s resetovala.
   gAttackManager.mMinimumAttackSize = max(5, gAttackManager.mMinimumAttackSize + gAdaptMinAttackSizeBonus);

   int targetPlayer = aiGetMostHatedPlayerID();
   if (targetPlayer == cOverrideDontAttackPlayerID)
   {
      debugMilitaryAttacking("Can't attack because of global override.");
      return;
   }
   // We run the mostHatedEnemy rule less frequent than the attackManager. Things could've changed inbetween.
   if (targetPlayer != -1 && kbPlayerHasLost(targetPlayer) == true)
   {
      debugMilitaryAttacking("Can't attack because our target player has already lost: " + targetPlayer + ".");
      return;
   }
   if (targetPlayer != -1 && kbPlayerIsAlly(targetPlayer) == true)
   {
      aiEchoWarning("Can't attack because our target player is an ally of ours: " + targetPlayer + ".");
      return;
   }

   int currentDefendPlanPop = aiPlanGetCurrentPopulation(gPrimaryLandDefendPlan);
   if (currentDefendPlanPop <= 0)
   {
      debugMilitaryAttacking("We have 0 units in our defend plan, we must quit regardless of state.");
      return;
   }

   // Based on all information that has been fed into the attack manager we now determine what state we're in.
   gAttackManager.updateState();

   bool targetUnits = false;
   switch (gAttackManager.mState)
   {
      case cStateNormal:
      {
         debugMilitaryAttacking("We're in state cStateNormal, performing the regular checks now.");
         // Default checking.
         if (metRequirementsToAttack() == false)
         {
            return;
         }
         break;
      }

      case cStateForcedAttack:
      {
         // If we already have an attack plan with reinforcements to true we can quit.
         int[] attackPlans = aiPlanGetIDsByType(cPlanAttack);
         for (int i = 0; i < attackPlans.size(); i++)
         {
            if (aiPlanGetParentID(attackPlans[i]) == -1)
            {
               if (aiPlanGetVariableBool(attackPlans[i], cAttackPlanAllowMoreUnitsDuringAttack, 0) == true)
               {
                  debugMilitaryAttacking("We're in state cStateForcedAttack but already have an attack plan that accepts reinforcements, quiting.");
                  return;
               }
            }
         }
         debugMilitaryAttacking("We're in state cStateForcedAttack and have no attack plan yet that accept reinforcements, continuing.");
         
         break;
      }

      case cStateForcedCantAttack:
      {
         debugMilitaryAttacking("We're in state cStateForcedCantAttack, quiting.");
         return;
      }

      case cStateNeedScouting:
      {
         debugMilitaryAttacking("We're in state cStateNeedScouting, details:");
         if ((cVictoryTypesCurrent & cVictoryTypeKingOfTheHill) != 0 && gKOTHIsOwnedByAllies == false)
         {
            debugMilitaryAttacking("We're not seeing any enemies but the KOTH isn't owned by us, attacking that instead.");
         }
         else
         {
            switch (gAttackManager.mScoutingState)
            {
               case cScoutingForEnemies:
               {
                  int[] excludeTypes = new int(1, cUnitTypeNavalUnit);
                  if (getUnit(cUnitTypeLogicalTypeNeededForVictory, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
                        cUnitQueryVisibleStateRecentPositionKnown, excludeTypes) != -1)
                  {
                     targetUnits = true;
                     debugMilitaryAttacking("We're scouting for enemies and have found some, attacking those units now.");
                     // Need to have at least some pop in here to go.
                     // TODO if such a plan actually dies we know there are still many enemies and we need to send more units etc...
                     if (currentDefendPlanPop <= 10)
                     {
                        debugMilitaryAttacking("We have less than 10 pop in our defend plan, quit anyway.");
                        return;
                     }
                     break;
                  }
                  debugMilitaryAttacking("Can't attack because we're still in need of scouting new targets");
                  return;
               }
               case cNoEnemies:
               {
                  debugMilitaryAttacking("Can't attack because we have no enemies at this moment.");
                  return;
               }
               case cNoScoutingNeeded:
               {
                  aiEchoWarning("gAttackManager.mScoutingState == cNoScoutingNeeded and gAttackManager.mState == cStateNeedScouting.");
                  break; // Just continue with the attack, potentially to unstuck some dodgy state.
               }
            }
         }
      }
   }

   // Here we actually calculate what we're going to attack.
   // v1.6.2: inline trackAttackStart() - cannot call cross-file function before adaptive_learning.xs is included
   gAdaptLastWaveStartPop = kbUnitCount(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive);
   gAdaptAttackLaunched++;
   gAdaptAttackEnemyBuildingsAtStart = 0;
   int trackTargetPlayer = aiGetMostHatedPlayerID();
   // v2.5 BUG31 FIX: uloz ID cile - aiGetMostHatedPlayerID() se muze zmenit behem utoku (eliminace, FFA prepnuti)
   // adaptiveAttackResultMonitor pouziva toto ulozene ID misto cerstveho dotazu
   gAdaptTrackTargetPlayerID = trackTargetPlayer;
   if (trackTargetPlayer > 0)
      gAdaptAttackEnemyBuildingsAtStart = kbUnitCount(cUnitTypeBuilding, trackTargetPlayer, cUnitStateAlive);
   gAdaptAttackInProgress = true;

   if (gAttackManager.mKOTHAttack == true)
   {
      createKOTHAttackPlan();
      debugMilitaryAttacking("**** ATTACKING TO RECAPTURE THE KOTH!!! ****");
   }
   else if (targetUnits == true)
   {
      createUnitAttackPlan();
      debugMilitaryAttacking("**** ATTACKING UNIT POSITIONS!!! ****");
   }
   else
   {
      int numBases = kbBaseGetNumber(targetPlayer);
      if (numBases > 0)
      {
         int targetBaseID = calculateTargetBase(targetPlayer);
         if (targetBaseID == -1)
         {
            // v1.6: zadna zakladna k utoku = okamzity neuspech (armada ani neodesla)
            gAdaptAttackInProgress = false; // Zrusit tracking - utok se nekonal
            gAdaptAttackFailed++;
            return;
         }
         createDefaultAttackPlan(targetPlayer, targetBaseID);
         tryLaunchSecondFront(targetPlayer, targetBaseID); // v1.2: druha fronta pokud mame dost armady
         sendStatementToAlliesWithVector(cAICommPromptToAllyIAmAttackingHere, kbBaseGetLocation(targetPlayer, targetBaseID));
         sendStatementToEnemies(cAICommPromptToEnemyIStartAnAttack);
         debugMilitaryAttacking("***** LAUNCHING ATTACK on player: " + targetPlayer + ", base: " + kbBaseGetNameByID(targetPlayer, targetBaseID));
      }
      else
      {
         vector startingPosition = kbPlayerGetStartingPosition(targetPlayer);
         createAttackPlanToPoint(targetPlayer, startingPosition);
         sendStatementToAlliesWithVector(cAICommPromptToAllyIAmAttackingHere, startingPosition);
         sendStatementToEnemies(cAICommPromptToEnemyIStartAnAttack);
         debugMilitaryAttacking("***** LAUNCHING ATTACK on player: " + targetPlayer + ", Starting Position: " + startingPosition);
      }
   }
   // v1.6 BUG FIX: odstranen trackAttackEnd(true) z tohoto mista.
   // Bylo: volano ihned po odeslani armady -> success vzdy 100%, ztraty vzdy 0.
   // Nyni: vysledek se vyhodnocuje v rule adaptiveAttackResultMonitor az po dokonceni boje.
   gAttackManager.mLastAttackTime = xsGetTime();
   // We don't want to keep attacking in the same interval, that's too predicatable, offset a little using the base time.
   // v1.1: adaptivni interval zahrnuje bonus z uciciho systemu (gAdaptAttackIntervalBonus)
   int randTime = xsRandInt(-20, 20);
   debugMilitaryAttacking("Randomly adjusting our attack interval by " + randTime + ".");
   gAttackManager.mAttackInterval = gAttackManager.mBaseAttackInterval + gAdaptAttackIntervalBonus + randTime;
   debugMilitaryAttacking("Next attack will happen at: " + turnNumberIntoTimeDisplay(gAttackManager.mLastAttackTime +
                                                                                     gAttackManager.mAttackInterval));
}

//==============================================================================
// titanAttackMonitor
// Keep the Titan in the primary assault / defend plan so it doesn't get stranded
// between response plans or stale orders.
//==============================================================================
rule titanAttackMonitor
inactive
group defaultClassicalRules
minInterval 5
{
   int titanID = getUnit(cUnitTypeAbstractTitan, cMyID, cUnitStateAlive);
   if (kbUnitGetIsIDValid(titanID) == false)
   {
      return;
   }

   int titanPlanID = kbUnitGetPlanID(titanID);
   int titanPressureLevel = getTitanPressureLevel(titanID);
   if (aiPlanGetIsIDValid(titanPlanID) == true && aiPlanGetType(titanPlanID) == cPlanAttack)
   {
      updateTitanAttackPlanPressureTactics(titanPlanID, titanID);
      if (titanPressureLevel > 0)
      {
         debugMilitaryAttacking("v2.3: Titan in local combat, skipping reassignment.");
         return;
      }
   }
   else if (aiPlanGetIsIDValid(titanPlanID) == true && aiPlanGetType(titanPlanID) == cPlanDefend)
   {
      updateTitanDefendPlanPressureTactics(titanPlanID, titanID);
      if (titanPressureLevel > 0)
      {
         debugMilitaryAttacking("v2.3: Titan in local defense combat, skipping reassignment.");
         return;
      }
   }
   else if (titanPressureLevel > 0)
   {
      debugMilitaryAttacking("v2.3: Titan under pressure without stable attack plan, preserving current target.");
      return;
   }

   int bestAttackPlanID = getBestTitanAttackPlan();
   if (bestAttackPlanID != -1)
   {
      if (kbUnitGetPlanID(titanID) != bestAttackPlanID)
      {
         debugMilitaryAttacking("v2.3: Titan monitor reassigning Titan to primary assault plan.");
         aiPlanAddUnit(bestAttackPlanID, titanID);
      }
      return;
   }

   if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == true && kbUnitGetPlanID(titanID) != gPrimaryLandDefendPlan)
   {
      debugMilitaryAttacking("v2.3: Titan monitor returning Titan to primary defend plan.");
      aiPlanAddUnit(gPrimaryLandDefendPlan, titanID);
   }
}
