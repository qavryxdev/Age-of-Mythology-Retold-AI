//==============================================================================
/* military_defend.xs

   This file is intended for any land/air military unit defend handling.

*/
//==============================================================================

//==============================================================================
// monitorPrimaryDefendPlan
//==============================================================================
void monitorPrimaryDefendPlan(int planID = 1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateAttack)
   {
      gAttackManager.mPrimaryLandDefendPlanIsEngaged = true;
   }
   else
   {
      gAttackManager.mPrimaryLandDefendPlanIsEngaged = false;
   }
}

//==============================================================================
// createPrimaryDefendPlan
// Create our main defend plan.
//==============================================================================
void createPrimaryDefendPlan()
{
   if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == true)
   {
      return;
   }

   // Figure out if we have a base to defend or if we have nothing and just need to go wherever.
   bool baseMode = true;
   int mainBaseID = kbBaseGetMainID(cMyID);
   vector gatherPoint = cInvalidVector;
   if (mainBaseID != -1)
   {
      gatherPoint = kbBaseGetMilitaryGatherPoint(cMyID, mainBaseID);
      if (gatherPoint == cInvalidVector)
      {
         gatherPoint = kbBaseGetLocation(cMyID, mainBaseID);
      }
   }
   else
   {
      baseMode = false;
      gatherPoint = kbPlayerGetStartingPosition(cMyID);
      if (gatherPoint == cInvalidVector)
      {
         int unitID = getUnit(cUnitTypeUnit);
         if (unitID != -1)
         {
            gatherPoint = kbUnitGetPosition(unitID);
         }
         else // We have nothing lol.
         {
            gatherPoint = kbGetMapCenter();
         }
      }
   }
   gPrimaryLandDefendPlan = aiPlanCreate("Primary Land Defend", cPlanDefend, -1, gMilitaryDefendingCategoryID);

   if (baseMode == true)
   {
      aiPlanSetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetMode, 0, cDefendPlanTargetModeBase);
      aiPlanSetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetPlayerID, 0, cMyID);
      aiPlanSetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetBaseID, 0, mainBaseID);
      aiPlanSetVariableFloat(gPrimaryLandDefendPlan, cDefendPlanEngageRange, 0, kbBaseGetDistance(cMyID, mainBaseID) + 10.0);
      aiPlanSetBaseID(gPrimaryLandDefendPlan, mainBaseID);
   }
   else
   {
      aiPlanSetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetMode, 0, cDefendPlanTargetModePoint);
      aiPlanSetVariableVector(gPrimaryLandDefendPlan, cDefendPlanTargetPoint, 0, gatherPoint);
      aiPlanSetVariableFloat(gPrimaryLandDefendPlan, cDefendPlanEngageRange, 0, 30.0);
   }
    
   aiPlanAddUnitType(gPrimaryLandDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 999);
   // v2.2: Titan dostava explicitni slot v hlavnim defend planu - nespolihat na generic land military matching.
   aiPlanAddUnitType(gPrimaryLandDefendPlan, cUnitTypeAbstractTitan, 0, 0, 1);
   aiPlanSetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0, gatherPoint);
   aiPlanSetVariableFloat(gPrimaryLandDefendPlan, cDefendPlanGatherDistance, 0, 20.0);
   setDefaultDefendPlanTargetUnitTypes(gPrimaryLandDefendPlan);
   aiPlanSetPriority(gPrimaryLandDefendPlan, 10); // Very low priority, don't steal from attack plans.
   debugMilitaryDefending("Creating primary land defend plan.");
   aiPlanSetEventHandler(gPrimaryLandDefendPlan, cPlanEventStateChange, "monitorPrimaryDefendPlan");

   // Just make sure these are all reset here too.
   gDefenseReflex = false;
   gDefenseReflexBaseID = -1;
   gDefenseReflexGatherPoint = cInvalidVector;
}

//==============================================================================
// createKOTHDefendPlan
//==============================================================================
void createKOTHDefendPlan()
{
   debugMilitaryDefending("Creating KOTH defend plan.");
   gKOTHDefendPlanID = aiPlanCreate("Defend KOTH", cPlanDefend, -1, gMilitaryDefendingCategoryID);

   aiPlanSetVariableInt(gKOTHDefendPlanID, cDefendPlanTargetMode, 0, cDefendPlanTargetModePoint);
   aiPlanSetVariableVector(gKOTHDefendPlanID, cDefendPlanTargetPoint, 0, gKOTHPosition);
   aiPlanSetVariableVector(gKOTHDefendPlanID, cDefendPlanGatherPoint, 0, gKOTHPosition);
   aiPlanSetVariableFloat(gKOTHDefendPlanID, cDefendPlanGatherDistance, 0, 20.0);
   aiPlanSetVariableFloat(gKOTHDefendPlanID, cDefendPlanEngageRange, 0, 40.0);
   setDefaultDefendPlanTargetUnitTypes(gKOTHDefendPlanID);

   aiPlanSetPriority(gKOTHDefendPlanID, 100);
   // Add half of our allowed military pop to this defend plan.
   int allowedMilPop = aiGetMilitaryPop();
   int minSize = 0;
   if (kbUnitCount(cUnitTypeShadePredator, 0, cUnitStateAlive) > 0)
   {
      minSize = selectByDifficulty(3, 5, 7, 9, 10, 10);
   }
   aiPlanAddUnitType(gKOTHDefendPlanID, cUnitTypeLogicalTypeLandMilitary, minSize, minSize, allowedMilPop / 2);
}

//==============================================================================
// moveDefenseReflex
// Move the defend plan to the specified location.
//==============================================================================
void moveDefenseReflex(int baseID = -1)
{
   vector gatherPoint = kbBaseGetMilitaryGatherPoint(cMyID, baseID);

   aiPlanSetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetBaseID, 0, baseID);
   aiPlanSetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0, gatherPoint);
   aiPlanSetVariableFloat(gPrimaryLandDefendPlan, cDefendPlanEngageRange, 0, kbBaseGetDistance(cMyID, baseID) + 10.0);

   gDefenseReflex = true;
   gDefenseReflexBaseID = baseID;
   gDefenseReflexGatherPoint  = gatherPoint;

   debugMilitaryDefending("Defense reflex moved to base: " + kbBaseGetNameByID(cMyID, baseID) + ", at gather point: " + gatherPoint);
}

//==============================================================================
// endDefenseReflex
// Move the gPrimaryLandDefendPlan to its default position.
//==============================================================================
void endDefenseReflex()
{
   int mainBaseID = kbBaseGetMainID(cMyID);
   vector gatherPoint = kbBaseGetMilitaryGatherPoint(cMyID, mainBaseID);

   aiPlanSetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetBaseID, 0, mainBaseID);
   aiPlanSetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0, gatherPoint);
   aiPlanSetVariableFloat(gPrimaryLandDefendPlan, cDefendPlanEngageRange, 0, kbBaseGetDistance(cMyID, mainBaseID) + 10.0);

   debugMilitaryDefending("Defense reflex terminated for base: " + kbBaseGetNameByID(cMyID, gDefenseReflexBaseID) + 
      ", at gather point: " + gDefenseReflexGatherPoint);
   debugMilitaryDefending("Returning to main base: " + kbBaseGetNameByID(cMyID, mainBaseID) + ", at gather point: " + gatherPoint);

   gDefenseReflex = false;
   gDefenseReflexBaseID = -1;
   gDefenseReflexGatherPoint = cInvalidVector;
}

//==============================================================================
// endDefenseReflexDelay
// Use this instead of calling endDefenseReflex in the createMainBase function, so that the new BaseID will be available.
//==============================================================================
rule endDefenseReflexDelay 
inactive
minInterval 1
{
   xsDisableRule("endDefenseReflexDelay");
   if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == true)
   {
      endDefenseReflex();
   }
}

//==============================================================================
// enemiesAreOnlyScouts
//==============================================================================
bool enemiesAreOnlyScouts(int numEnemies = -1, int queryID = -1)
{
   for (int i = 0; i < numEnemies; i++)
   {
      int unitID = kbUnitQueryGetResult(queryID, i);
      if (kbUnitIsType(unitID, cUnitTypeAbstractScout) == false)
      {
         return false;
      }
   }
   return true;
}

//==============================================================================
/* rule defenseReflex

   Monitor each base we own. Move and reconfigure the gPrimaryLandDefendPlan as needed.

   gPrimaryLandDefendPlan is the main defend plan and gets all units assigned to it.

   We move gPrimaryLandDefendPlan around to where we're threatened.
   If we're not threatened it will be located in the main base.
*/
//==============================================================================
rule defenseReflex
inactive
//group defaultArchaicRules
minInterval 10
{
   if (checkStrategyFlag(cStrategyFlagCanDefend) == false)
   {
      if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == true)
      {
         aiPlanDestroy(gPrimaryLandDefendPlan);
      }
      gPrimaryLandDefendPlan = -1;
      gDefenseReflex = false;
      gDefenseReflexBaseID = -1;
      gDefenseReflexGatherPoint = cInvalidVector;
      gDefenseReflexPanic = false;
      return;
   }

   debugMilitaryDefending("--- Running Rule defenseReflex. ---");
   // If our globals are invalid we need to set up new plans.
   if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == false)
   {
      createPrimaryDefendPlan();
   }

   if ((cVictoryTypesCurrent & cVictoryTypeKingOfTheHill) != 0 && gKOTHIsOwnedByAllies == true)
   {
      if (aiPlanGetIsIDValid(gKOTHDefendPlanID) == true)
      {
         debugMilitaryDefending("Allowing units on the KOTH defend plan and updating its max amount of units.");
         aiPlanSetFlag(gKOTHDefendPlanID, cPlanFlagNoMoreUnits, false);
         int allowedMilPop = aiGetMilitaryPop();
         int minSize = 0;
         if (kbUnitCount(cUnitTypeShadePredator, 0, cUnitStateAlive) > 0)
         {
            minSize = selectByDifficulty(3, 5, 7, 9, 10, 10);
         }
         aiPlanAddUnitType(gKOTHDefendPlanID, cUnitTypeLogicalTypeLandMilitary, minSize, minSize, max(allowedMilPop / 2, minSize));
      }
      else
      {
         createKOTHDefendPlan();
      }
   }

   float ownArmyPop = aiPlanGetCurrentPopulation(gPrimaryLandDefendPlan);
   float enemyArmyPop = 0;
   int unitID = -1;
   int protoUnitID = -1;
   int planID = -1;
   int mainBaseID = kbBaseGetMainID(cMyID);
   bool scoutsInBase = false;
   int numEnemies = 0;
   static int enemyArmyQuery = -1;
   float scanRadius = kbBaseGetDistance(cMyID, mainBaseID);
   if (enemyArmyQuery < 0) // First run.
   {
      enemyArmyQuery = kbUnitQueryCreate("defenseReflex Enemy army query");
      kbUnitQuerySetPlayerRelation(enemyArmyQuery, cPlayerRelationEnemyNotGaia);
      kbUnitQuerySetUnitType(enemyArmyQuery, cUnitTypeLogicalTypeLandMilitary);
      kbUnitQuerySetState(enemyArmyQuery, cUnitStateAlive);
      kbUnitQuerySetVisibleState(enemyArmyQuery, cUnitQueryVisibleStateVisible);
   }

   // Check main base first.
   kbUnitQuerySetPosition(enemyArmyQuery, kbBaseGetLocation(cMyID, mainBaseID));
   kbUnitQuerySetMaximumDistance(enemyArmyQuery, scanRadius);
   kbUnitQueryResetResults(enemyArmyQuery);
   numEnemies = kbUnitQueryExecute(enemyArmyQuery);
   enemyArmyPop = kbUnitQueryGetPopulationSlots(enemyArmyQuery);

   // If we find very few units in our base it could be that it's just a scout.
   if (numEnemies <= 2)
   {
      scoutsInBase = enemiesAreOnlyScouts(numEnemies, enemyArmyQuery);
   }

   gDefenseReflexPanic = false;
   if (numEnemies >= 1 && scoutsInBase == false)
   {
      // Main base is under attack.
      debugMilitaryDefending("Main base (" + kbBaseGetNameByID(cMyID, mainBaseID) + ") under attack.");
      debugMilitaryDefending("Enemy pop count: " + enemyArmyPop + ", my army pop count: " + ownArmyPop);
      
      // We're already in a defense reflex for the main base.
      if (gDefenseReflexBaseID == mainBaseID)
      {
         // We're outnumbered too much, recall any attack that we may have immediately.
         if (enemyArmyPop > (ownArmyPop * 1.2))
         {
            // Chat about this.
            sendStatementToEnemies(cAICommPromptToEnemyOutnumbered);
            sendStatementToAlliesWithVector(cAICommPromptToAllyINeedHelp, kbBaseGetLocation(cMyID, mainBaseID));

            gDefenseReflexPanic = true;
            int[] planIDs = aiPlanGetIDsByType(cPlanAttack);
            for (int i = 0; i < planIDs.size(); i++)
            {
               planID = planIDs[i];
               // Don't destroy child reinforce plans.
               if (aiPlanGetParentID(planID) != -1)
               {
                  continue;
               }
               // Don't interrupt an attack plan that is currently fighting.
               if (aiPlanGetState(planID) == cPlanStateAttack)
               {
                  continue;
               }
               // Any attack plan that is close to an enemy TC base should also be left as is.
                if (getUnitCountByLocation(cUnitTypeAbstractSocketedTownCenter, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
                    aiPlanGetLocation(planID), 50.0) >= 1)
                {
                   continue;
                }
                // v2.2: nenerusuj Titan attack - zruseni planu Titanu casto vede k idle/prechazeni sem a tam.
                if (planContainsTitan(planID) == true)
                {
                   debugMilitaryDefending("Keeping attack plan " + aiPlanGetName(planID) + " because it contains our Titan.");
                   continue;
                }
                debugMilitaryDefending("Found plan: " + aiPlanGetName(planID) + ", to destroy because we need to defend!");
                aiPlanDestroy(planID);
            }
            // v1.2: PROTIUTOK pri panice - "nejlepsi obrana je utok"
            // Pokud jsme presile (utocnik ma >1.2x nasi armady), donutime attackManager
            // k okamzitemu protiutoku aby nepritel musel branit vlastni zakladnu.
            if (cDifficultyCurrent >= cDifficultyHard)
            {
               gAttackManager.mLastAttackTime = 0; // Reset casovace -> attackManager povoli utok ihned
               xsRuleIgnoreIntervalOnce("attackManager");
               debugMilitaryDefending("v1.2: Panika zakladny! Vynucuji okamzity protiutok na nepratelskou zakladnu.");
            }
         }
      }

      // Defense reflex wasn't set to main base.
      // Need to set the defense reflex to home base...doesn't matter if it was inactive or guarding another base,
      // home base trumps all.
      else 
      { 
         moveDefenseReflex(mainBaseID);
         // This is a new defense reflex in the main base. Consider making a chat about it.
         int enemyPlayerID = kbUnitGetPlayerID(kbUnitQueryGetResult(enemyArmyQuery, 0));
         if (enemyPlayerID > 0)
         {
            // TODO send a chat.
         }
      }
      return; // Do not check other bases since our main base trumps all.
   }

   // If we're this far, the main base is OK. If we're in a defense reflex, see if we should stay in it, or change from
   // passive to active.

   if (gDefenseReflex == true) // Currently in a defense mode, let's see if it should remain
   {
      scanRadius = kbBaseGetDistance(cMyID, gDefenseReflexBaseID);
      kbUnitQuerySetPosition(enemyArmyQuery, gDefenseReflexGatherPoint);
      kbUnitQuerySetMaximumDistance(enemyArmyQuery, scanRadius);
      kbUnitQueryResetResults(enemyArmyQuery);
      numEnemies = kbUnitQueryExecute(enemyArmyQuery);
      // v2.9 IMP11: bylo: enemyArmyPop drzelo starou hodnotu 0 z main base query (radek ~277).
      // Debug log ukazoval "Enemy pop count: 0" i kdyz v obranene zakladne bylo 30+ pop nepritele.
      enemyArmyPop = kbUnitQueryGetPopulationSlots(enemyArmyQuery);

      debugMilitaryDefending("Defense reflex in base: " + kbBaseGetNameByID(cMyID, gDefenseReflexBaseID) + ", at: " + gDefenseReflexGatherPoint);
      debugMilitaryDefending("Enemy pop count: " + enemyArmyPop + ", my army pop count: " + ownArmyPop);

      if (numEnemies <= 0)
      {
         debugMilitaryDefending("Ending defense reflex, base: " + kbBaseGetNameByID(cMyID, gDefenseReflexBaseID) + ", has no enemies.");
         endDefenseReflex();
         return;
      }

      if (numEnemies <= 2)
      {
         scoutsInBase = enemiesAreOnlyScouts(numEnemies, enemyArmyQuery);
         // Abort, we are not under threat.
         if (scoutsInBase == true)
         {
            debugMilitaryDefending("Ending defense reflex, base: " + kbBaseGetNameByID(cMyID, gDefenseReflexBaseID) +
                          ", the enemies inside the base are only scouts.");
            endDefenseReflex();
            return;
         }
      }

      // Abort, no alive ally buildings.
      if (baseBuildingCount(cMyID, gDefenseReflexBaseID, cPlayerRelationAlly, cUnitStateAlive) <= 0)
      {
         debugMilitaryDefending("Ending defense reflex, base: " + kbBaseGetNameByID(cMyID, gDefenseReflexBaseID) + ", has no buildings.");
         endDefenseReflex();
         return;
      }

      // Abort, base doesn't exist.
      if (kbBaseGetIsIDValid(cMyID, gDefenseReflexBaseID) == false)
      {
         debugMilitaryDefending("Ending defense reflex, base doesn't exist anymore.");
         endDefenseReflex();
         return;
      }
      return; // Done, we're staying in defense mode for this base.
   }

   // Not in a defense reflex, see if one is needed.

   // Check other bases
   int baseID = -1;
   vector baseLoc = cInvalidVector;

   int baseCount = kbBaseGetNumber(cMyID);
   if (baseCount > 0)
   {
      debugMilitaryDefending("Mainbase is not under attack and we're not actively defending any bases, scan to see if we should.");
      for (int baseIndex = 0; baseIndex < baseCount; baseIndex++)
      {
         baseID = kbBaseGetIDByIndex(cMyID, baseIndex);
         if (baseID == mainBaseID)
         {
            continue; // Already checked main at top of function.
         }

         debugMilitaryDefending("Analyzing base: " + kbBaseGetNameByID(cMyID, baseID) + ".");

         if (baseBuildingCount(cMyID, baseID, cPlayerRelationAlly, cUnitStateAlive) <= 0)
         {
            debugMilitaryDefending("Skipping base: " + kbBaseGetNameByID(cMyID, baseID) + ", since it has has no alive buildings.");
            continue;
         }

         // Check for overrun base.
         baseLoc = kbBaseGetLocation(cMyID, baseID);
         scanRadius = kbBaseGetDistance(cMyID, baseID);
         kbUnitQuerySetPosition(enemyArmyQuery, baseLoc);
         kbUnitQuerySetMaximumDistance(enemyArmyQuery, scanRadius);
         kbUnitQueryResetResults(enemyArmyQuery);
         numEnemies = kbUnitQueryExecute(enemyArmyQuery);
         // v2.6 BUG33 FIX: bylo: enemyArmyPop nikdy neprepocitano pro sekundarni zakladny.
         // Promenna drzela hodnotu z main base query (radek ~277) ktera vracela 0 (jinak bychom tu nebyli).
         // (0 * 0.8) > ownArmyPop = vzdy false -> AI vzdy brani sekundarni zakladny bez ohledu na presilu.
         // Oprava: nacist spravnou hodnotu enemy pop pro tuto zakladnu.
         enemyArmyPop = kbUnitQueryGetPopulationSlots(enemyArmyQuery); // bylo: stale 0 z main base query

         if (numEnemies <= 0)
         {
            debugMilitaryDefending("Skipping base: " + kbBaseGetNameByID(cMyID, baseID) + ", there are no enemies inside the base.");
            continue;
         }

         if (numEnemies <= 2)
         {
            scoutsInBase = enemiesAreOnlyScouts(numEnemies, enemyArmyQuery);
            if (scoutsInBase == true)
            {
               debugMilitaryDefending("Skipping base: " + kbBaseGetNameByID(cMyID, baseID) + ", the enemies inside the base are only scouts.");
               continue;
            }
         }

         debugMilitaryDefending("Enemy pop count: " + enemyArmyPop + ", my army pop count: " + ownArmyPop);
         if ((enemyArmyPop * 0.8) > ownArmyPop)
         {
            debugMilitaryDefending("We're outnumbered to much to defend effectively defend this base, skipping.");
            continue;
         }

         moveDefenseReflex(baseID);
         return; // If we're in trouble in any base, ignore the others.
      }
   }
   debugMilitaryDefending("Found no base worth defending!");
}

//==============================================================================
// calculateAlliedBaseToDefend
//==============================================================================
int calculateAlliedBaseToDefend(ref int popCount, int defendPlayerID = -1)
{
   static int baseQuery = -1;
   if (baseQuery < 0) // First run.
   {
      baseQuery = kbUnitQueryCreate("defendBaseQuery");
      kbUnitQuerySetUnitType(baseQuery, cUnitTypeLogicalTypeLandMilitary);
      kbUnitQuerySetState(baseQuery, cUnitStateAlive);
   }
   kbUnitQuerySetPlayerRelation(baseQuery, cPlayerRelationEnemy);
   kbUnitQuerySetVisibleState(baseQuery, cUnitQueryVisibleStateVisible);

   vector ownArmyLocation = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);
   int ownAreaGroupID = kbAreaGroupGetIDByPosition(ownArmyLocation);
   int defendBaseID = -1;
   int numberBases = kbBaseGetNumber(defendPlayerID);
   int highestPopScore = 0;
   debugMilitaryDefending("calculateAlliedBaseToDefend - Calculating player: " + defendPlayerID + ", who has numberBases: " + numberBases);
   // Go through all players' bases and calculate values for comparison.
   for (int baseIndex = 0; baseIndex < numberBases; baseIndex++)
   {
      int baseID = kbBaseGetIDByIndex(defendPlayerID, baseIndex);
      vector baseLocation = kbBaseGetLocation(defendPlayerID, baseID);
      float baseDistance = kbBaseGetDistance(defendPlayerID, baseID);
    
      kbUnitQuerySetPosition(baseQuery, baseLocation);
      kbUnitQuerySetMaximumDistance(baseQuery, baseDistance);
      kbUnitQueryResetResults(baseQuery);
      int numberEnemiesFound = kbUnitQueryExecute(baseQuery);
      debugMilitaryDefending("numberEnemiesFound: " + numberEnemiesFound);
      float popScore = 0;
      
      for (int i = 0; i < numberEnemiesFound; i++)
      {
         int unitID = kbUnitQueryGetResult(baseQuery, i);
         
         int puid = kbUnitGetProtoUnitID(unitID);
         debugMilitaryDefending("Puid: " + puid);
         debugMilitaryDefending("pop: " + kbDefaultGetProtoStatInt(puid, cProtoStatPopCost));
         popScore += kbDefaultGetProtoStatInt(puid, cProtoStatPopCost);
         debugMilitaryDefending("popScore: " + popScore);
      }

      // Ignore base when we have no good targets to attack.
      if (popScore == 0)
      {
         debugMilitaryDefending("Skipping base: " + kbBaseGetNameByID(defendPlayerID, baseID) + ", because it has no enemies in it.");
         continue;
      }
      
      // Adjust for distance. If < 100m, leave as is.  Over 100m to 400m, penalize 10% per 100m.
      float distancePenalty = xsVectorLength(ownArmyLocation - baseLocation) / 1000.0;
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
      popScore *= distancePenalty;
      debugMilitaryDefending("Base: " + kbBaseGetNameByID(defendPlayerID, baseID) + ", has a popScore of: " + popScore);
      if (popScore > highestPopScore)
      {
         defendBaseID = baseID;
         highestPopScore = popScore;
      }
   }

   if (defendBaseID == -1)
   {
      debugMilitaryDefending("We found no good base to defend. A base needs more than 0 popScore to be worth it.");
   }
   popCount = highestPopScore;
   return defendBaseID;
}

//==============================================================================
// createDefaultAllyDefendPlan
//==============================================================================
int createDefaultAllyDefendPlan(int defendPlayerID = -1, int defendBaseID = -1, int enemyPopCount = -1)
{
   int planID = aiPlanCreate("Defend Player " + defendPlayerID + " Base " + kbBaseGetNameByID(defendPlayerID, defendBaseID),
                             cPlanDefend, -1, gMilitaryDefendingCategoryID);

   aiPlanSetVariableInt(planID, cDefendPlanTargetMode, 0, cDefendPlanTargetModeBase);
   aiPlanSetVariableInt(planID, cDefendPlanTargetBaseID, 0, defendBaseID);
   aiPlanSetVariableInt(planID, cDefendPlanTargetPlayerID, 0, defendPlayerID);
   aiPlanSetVariableVector(planID, cDefendPlanGatherPoint, 0, kbBaseGetLocation(defendPlayerID, defendBaseID));
   aiPlanSetVariableFloat(planID, cDefendPlanGatherDistance, 0, 8.0);
   aiPlanSetVariableInt(planID, cDefendPlanNoTargetTimeout, 0, 30 * 1000);
   aiPlanSetVariableInt(planID, cDefendPlanDoneMode, 0, cDefendPlanDoneModeNoTarget);
   setDefaultDefendPlanTargetUnitTypes(planID);

   aiPlanSetPriority(planID, 100);
   aiPlanSetBaseID(planID, defendBaseID);
   aiPlanAddUnitType(planID, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);

   // Match enemy pop count to defend with.
   int[] units = aiPlanGetUnits(gPrimaryLandDefendPlan);
   for (int i = 0; i < units.size(); i++)
   {
      if (enemyPopCount <= 0)
      {
         break;
      }
      int unitID = units[i];
      if (isTitanUnit(unitID) == true)
      {
         continue;
      }
      int popCount = kbPlayerGetProtoStatInt(cMyID, kbUnitGetProtoUnitID(unitID), cProtoStatPopCost);
      enemyPopCount -= popCount;
      aiPlanAddUnit(planID, unitID);
   }

   aiPlanSetFlag(planID, cPlanFlagNoMoreUnits, true);
   return planID;
}

//==============================================================================
// regicideGarrisonPlanSetup
//==============================================================================
rule regicideGarrisonPlanSetup
inactive
minInterval 5
{
   int planID = aiPlanCreate("Regicide Garrison Plan", cPlanGarrison, -1, gMilitaryDefendingCategoryID);
   aiPlanAddUnitType(planID, cUnitTypeRegent, 1, 1, 1);
   aiPlanAddUnit(planID, getUnit(cUnitTypeRegent));
   aiPlanSetVariableFloat(planID, cGarrisonPlanSearchRadius, 0, cMaxFloat);
   aiPlanSetVariableBool(planID, cGarrisonPlanNeverUngarrison, 0, true);
   aiPlanSetPriority(planID, 100);
   aiPlanSetFlag(planID, cPlanFlagCantBeStolenFrom, true);
   xsDisableRule("regicideGarrisonPlanSetup");
}








//==============================================================================
// responseDefendPlanHandler
//==============================================================================
void responseDefendPlanHandler(int planID = -1)
{
   int planState = aiPlanGetState(planID);
   if (planState == cPlanStateDone || planState == cPlanStateFailed)
   {
      int index = gDefendPlans.find(planID);
      if (index == -1)
      {
         aiEchoWarning("responseDefendPlanHandler - " + aiPlanGetName(planID) + " couldn't be found in the gDefendPlans array.");
         return;
      }
      gDefendPlans.removeIndex(index);
   }
}

//==============================================================================
// createOrReinforcecBaseDefendResponsePlan
//==============================================================================
int createOrReinforcecBaseDefendResponsePlan(int existingPlanID = -1, int baseID = -1, int wantedSize = -1, bool isAlreadyEngaged = false)
{
   int planID = existingPlanID;
   if (existingPlanID == -1)
   {
      planID = aiPlanCreate("Defend Response: " + kbBaseGetNameByID(cMyID, baseID), cPlanDefend, -1, gMilitaryDefendingCategoryID);
      aiPlanAddUnitType(planID, cUnitTypeLogicalTypeLandMilitary, 0, 0, 999);
      aiPlanSetVariableInt(planID, cDefendPlanTargetMode, 0, cDefendPlanTargetModeBase);
      aiPlanSetVariableInt(planID, cDefendPlanNoTargetTimeout, 0, 15 * 1000);
      aiPlanSetVariableInt(planID, cDefendPlanDoneMode, 0, cDefendPlanDoneModeNoTarget | cDefendPlanDoneModeBaseGone);
      aiPlanSetVariableInt(planID, cDefendPlanTargetPlayerID, 0, cMyID);
      aiPlanSetVariableInt(planID, cDefendPlanTargetBaseID, 0, baseID);
      aiPlanSetVariableVector(planID, cDefendPlanGatherPoint, 0, kbBaseGetMilitaryGatherPoint(cMyID, baseID));
      aiPlanSetVariableFloat(planID, cDefendPlanGatherDistance, 0, 20.0);
      aiPlanSetVariableFloat(planID, cDefendPlanEngageRange, 0, kbBaseGetDistance(cMyID, baseID) + 10.0);
      setDefaultDefendPlanTargetUnitTypes(planID);
      aiPlanSetPriority(planID, 10);
      aiPlanSetFlag(planID, cPlanFlagNoMoreUnits, true); // We don't auto assign for these plans, only manual.
      aiPlanSetFlag(planID, cPlanFlagCantBeStolenFrom, true);
      aiPlanSetBaseID(planID, baseID);
      aiPlanSetEventHandler(planID, cPlanEventStateChange, "responseDefendPlanHandler");

      gDefendPlans.add(planID);
      debugMilitaryDefending("      Creating base defend response plan for base: " + kbBaseGetNameByID(cMyID, baseID));
   }

   int popCountAssigned = 0;
   if (isAlreadyEngaged == true)
   {
      int[] units = new int(0, 0);
      int numReinforcementPlans = aiPlanGetNumberChildren(gPrimaryLandDefendPlan);
      for (int i = 0; i < numReinforcementPlans; i++)
      {
         units = aiPlanGetUnits(aiPlanGetChildIDByIndex(gPrimaryLandDefendPlan, i));
         for (int iUnit = 0; iUnit < units.size(); iUnit++)
         {
            if (kbProtoUnitIsType(kbUnitGetProtoUnitID(units[iUnit]), cUnitTypeAbstractSiegeWeapon) == true)
            {
               continue;
            }
            if (isTitanUnit(units[iUnit]) == true)
            {
               continue;
            }
            int popCount = kbPlayerGetProtoStatInt(cMyID, kbUnitGetProtoUnitID(units[iUnit]), cProtoStatPopCost);
            aiPlanAddUnit(planID, units[iUnit]);
            popCountAssigned += popCount;
            if (popCountAssigned >= wantedSize)
            {
               debugMilitaryDefending("      Found enough units in the reinforcement plans to fulfill our needs.");
               return popCountAssigned;
            }
         }
      }

      debugMilitaryDefending("      We couldn't find enough pop in the reinforcement plans, looking at the main plan now.");

      int primaryLandDefendPopCount = aiPlanGetCurrentPopulation(gPrimaryLandDefendPlan);
      units = aiPlanGetUnits(gPrimaryLandDefendPlan);
      for (int iUnit = 0; iUnit < units.size(); iUnit++)
      {
         if (kbProtoUnitIsType(kbUnitGetProtoUnitID(units[iUnit]), cUnitTypeAbstractSiegeWeapon) == true)
         {
            continue;
         }
         if (isTitanUnit(units[iUnit]) == true)
         {
            continue;
         }
         int popCount = kbPlayerGetProtoStatInt(cMyID, kbUnitGetProtoUnitID(units[iUnit]), cProtoStatPopCost);
         aiPlanAddUnit(planID, units[iUnit]);
         popCountAssigned += popCount;
         if (popCountAssigned >= wantedSize)
         {
            debugMilitaryDefending("      Found enough units in the main plan to fulfill our needs.");
            return popCountAssigned;
         }
      }
   }
   else // We're not under attack and should aim for 1 big group of soldiers, so prefer taking from the grouped units.
   {
      int primaryLandDefendPopCount = aiPlanGetCurrentPopulation(gPrimaryLandDefendPlan);
      int[] units = aiPlanGetUnits(gPrimaryLandDefendPlan);
      for (int iUnit = 0; iUnit < units.size(); iUnit++)
      {
         if (kbProtoUnitIsType(kbUnitGetProtoUnitID(units[iUnit]), cUnitTypeAbstractSiegeWeapon) == true)
         {
            continue;
         }
         if (isTitanUnit(units[iUnit]) == true)
         {
            continue;
         }
         int popCount = kbPlayerGetProtoStatInt(cMyID, kbUnitGetProtoUnitID(units[iUnit]), cProtoStatPopCost);
         aiPlanAddUnit(planID, units[iUnit]);
         popCountAssigned += popCount;
         if (popCountAssigned >= wantedSize)
         {
            debugMilitaryDefending("      Took enough pop from gPrimaryLandDefendPlan without needing to look at its reinforcement plans.");
            return popCountAssigned;
         }
      }
      debugMilitaryDefending("      We couldn't find enough pop in the main gPrimaryLandDefendPlan, looking at reinforcement plans now.");
      int numReinforcementPlans = aiPlanGetNumberChildren(gPrimaryLandDefendPlan);
      for (int i = 0; i < numReinforcementPlans; i++)
      {
         units = aiPlanGetUnits(aiPlanGetChildIDByIndex(gPrimaryLandDefendPlan, i));
         for (int iUnit = 0; iUnit < units.size(); iUnit++)
         {
            if (kbProtoUnitIsType(kbUnitGetProtoUnitID(units[iUnit]), cUnitTypeAbstractSiegeWeapon) == true)
            {
               continue;
            }
            if (isTitanUnit(units[iUnit]) == true)
            {
               continue;
            }
            int popCount = kbPlayerGetProtoStatInt(cMyID, kbUnitGetProtoUnitID(units[iUnit]), cProtoStatPopCost);
            aiPlanAddUnit(planID, units[iUnit]);
            popCountAssigned += popCount;
            if (popCountAssigned >= wantedSize)
            {
               debugMilitaryDefending("      Found enough units in the reinforcement plans to fulfill our needs.");
               return popCountAssigned;
            }
         }
      }
   }
   return 0;
}

//==============================================================================
// updateBaseArrays
//==============================================================================
void updateBaseArrays()
{
   for (int i = gDefendTCBases.size() - 1; i >= 0 ; i--)
   {
      int baseID = gDefendTCBases[i];
      // Remove invalid bases as well as bases that are no longer a TC base.
      if (kbBaseGetIsIDValid(cMyID, baseID) == false)
      {
         debugMilitaryDefending("removing base with ID " + gDefendTCBases[i] +
            " from gDefendTCBases because it no longer exists (destroyed/merged).");
         gDefendTCBases.removeIndex(i);
         continue;
      }
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
      {
         debugMilitaryDefending(kbBaseGetNameByID(cMyID, gDefendTCBases[i]) + " removing this base from gDefendTCBases " + 
            "because it's no longer a TC base.");
         gDefendTCBases.removeIndex(i);
      }
   }
   // Add bases to our TC array if we didn't have them already.
   int numberBases = kbBaseGetNumber(cMyID);
   for (int i = 0; i < numberBases; i++)
   {
      int baseID = kbBaseGetIDByIndex(cMyID, i);
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
      {
         continue;
      }
      if (gDefendTCBases.find(baseID) != -1)
      {
         continue;
      }
      gDefendTCBases.add(baseID);
      debugMilitaryDefending(kbBaseGetNameByID(cMyID, baseID) + " adding this base to gDefendTCBases.");
   }
}

//==============================================================================
// Utility functions for switching bases to defend.
//==============================================================================
bool gBaseMode = true;
void defendReaddAllUnits()
{
   // Don't need to look at loans, the child reinforcement will fix itself.
   int[] units = aiPlanGetUnits(gPrimaryLandDefendPlan);
   for (int i = 0; i < units.size(); i++)
   {
      // This causes the units to be placed in a child reinforcement plan since they need to orderly move to the new spot.
      aiPlanRemoveUnit(gPrimaryLandDefendPlan, units[i]);
      aiPlanAddUnit(gPrimaryLandDefendPlan, units[i]);
   }
}
void defendTransformToPoint()
{
   if (gBaseMode == false) // Already in point mode? Quit.
   {
      return;
   }
   aiPlanSetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetMode, 0, cDefendPlanTargetModePoint);
   aiPlanSetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetBaseID, 0, -1);
   aiPlanSetVariableVector(gPrimaryLandDefendPlan, cDefendPlanTargetPoint, 0, aiPlanGetVariableVector(gPrimaryLandDefendPlan,
                                                                              cDefendPlanGatherPoint, 0));
   gBaseMode = false;
}
void defendTransformToBase()
{
   if (gBaseMode == true) // Already in base mode? Quit.
   {
      return;
   }
   aiPlanSetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetMode, 0, cDefendPlanTargetModeBase);
   gBaseMode = true;
}
//==============================================================================
// determinePrimaryBaseToStationUnits
//==============================================================================
void determinePrimaryBaseToStationUnits()
{
   bool forcedNewDefendBase = false;
   if (kbBaseGetIsIDValid(cMyID, aiPlanGetBaseID(gPrimaryLandDefendPlan)) == false)
   {
      debugMilitaryDefending("The base we were defending with gPrimaryLandDefendPlan no longer exists.");
      forcedNewDefendBase = true;
      if (gDefendTCBases.size() == 1)
      {
         aiPlanSetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0, kbBaseGetMilitaryGatherPoint(cMyID, gDefendTCBases[0]));
         aiPlanSetVariableFloat(gPrimaryLandDefendPlan, cDefendPlanEngageRange, 0, kbBaseGetDistance(cMyID, gDefendTCBases[0]) + 10.0);
         aiPlanSetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetBaseID, 0, gDefendTCBases[0]);
         aiPlanSetBaseID(gPrimaryLandDefendPlan, gDefendTCBases[0]);
         defendTransformToBase();
         defendReaddAllUnits();
         debugMilitaryDefending("Moving our gPrimaryLandDefendPlan to " + kbBaseGetNameByID(cMyID, gDefendTCBases[0]) + ".");
         return;
      }
      else if (gDefendTCBases.size() == 0)
      {
         // No TC base left to orient ourself around, transform to a defend point on the current gather point.
         defendTransformToPoint();
         debugMilitaryDefending("We have no TC base left to orient our gPrimaryLandDefendPlan around, " +
            "just defend our current gather point then.");
         return;
      }
   }

   defendTransformToBase();
   // We want our primary defend plan to be positioned at the base that is most likely to be attacked (closest to enemy).
   // We can only move this plan to another base if we're not engaged in combat.
   if ((gDefendTCBases.size() > 1 && aiPlanGetState(gPrimaryLandDefendPlan) != cPlanStateAttack) || forcedNewDefendBase == true)
   {
      float closestDistance = cMaxFloat;
      int mostForwardOwnBaseID = -1;
      for (int i = 0; i < gDefendTCBases.size(); i++)
      {
         // Find the closest enemy military base.
         int enemyBaseID = kbFindClosestBase(-1, cPlayerRelationEnemy, kbBaseGetLocation(cMyID, gDefendTCBases[i]), true);
         if (enemyBaseID != -1)
         {
            float distance = xsVectorLength(kbBaseGetLocation(cMyID, gDefendTCBases[i]) -
                                            kbBaseGetLocation(kbBaseGetOwner(enemyBaseID), enemyBaseID));
            if (distance < closestDistance)
            {
               closestDistance = distance;
               mostForwardOwnBaseID = gDefendTCBases[i];
            }
         }
         else
         {
            break; // If we don't find a base once we won't find it ever.
         }
      }
      if (mostForwardOwnBaseID == -1)
      {
         debugMilitaryDefending("Didn't find an enemy base to orient ourself around, moving defend plan to first base in the " +
            " array now if it wasn't already there.");
         if (aiPlanGetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetBaseID, 0) != aiPlanGetBaseID(gDefendTCBases[0]))
         {
            aiPlanSetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0, kbBaseGetMilitaryGatherPoint(cMyID, gDefendTCBases[0]));
            aiPlanSetVariableFloat(gPrimaryLandDefendPlan, cDefendPlanEngageRange, 0, kbBaseGetDistance(cMyID, gDefendTCBases[0]) + 10.0);
            aiPlanSetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetBaseID, 0, gDefendTCBases[0]);
            aiPlanSetBaseID(gPrimaryLandDefendPlan, gDefendTCBases[0]);
            defendReaddAllUnits();
            debugMilitaryDefending("Moving our gPrimaryLandDefendPlan to " + kbBaseGetNameByID(cMyID, gDefendTCBases[0]) + ".");
         }
      }
      else if (aiPlanGetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetBaseID, 0) != mostForwardOwnBaseID)
      {
         aiPlanSetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0, kbBaseGetMilitaryGatherPoint(cMyID, mostForwardOwnBaseID));
         aiPlanSetVariableFloat(gPrimaryLandDefendPlan, cDefendPlanEngageRange, 0, kbBaseGetDistance(cMyID, mostForwardOwnBaseID) + 10.0);
         aiPlanSetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetBaseID, 0, mostForwardOwnBaseID);
         aiPlanSetBaseID(gPrimaryLandDefendPlan, mostForwardOwnBaseID);
         defendReaddAllUnits();
         debugMilitaryDefending("Moving our gPrimaryLandDefendPlan to " + kbBaseGetNameByID(cMyID, mostForwardOwnBaseID) + ".");
      }
      else
      {
         // Set the engage range again, in case the base grew in the meantime.
         aiPlanSetVariableFloat(gPrimaryLandDefendPlan, cDefendPlanEngageRange, 0, kbBaseGetDistance(cMyID, mostForwardOwnBaseID) + 10.0);
         debugMilitaryDefending("Found an enemy base to orient ourself around but we were already defending the closest base.");
      }
   }
   else
   {
      // Set the engage range again, in case the base grew in the meantime.
      aiPlanSetVariableFloat(gPrimaryLandDefendPlan, cDefendPlanEngageRange, 0,
         kbBaseGetDistance(cMyID, aiPlanGetBaseID(gPrimaryLandDefendPlan)) + 10.0);
      debugMilitaryDefending("Not moving our gPrimaryLandDefendPlan to another base for now.");
   }
}

//==============================================================================
// newDefend
//==============================================================================
rule newDefend
inactive
group defaultArchaicRules
minInterval 5
{
   if (checkStrategyFlag(cStrategyFlagCanDefend) == false)
   {
      if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == true)
      {
         aiPlanDestroy(gPrimaryLandDefendPlan);
      }
      gPrimaryLandDefendPlan = -1;
      gDefenseReflex = false;
      gDefenseReflexBaseID = -1;
      gDefenseReflexGatherPoint = cInvalidVector;
      gDefenseReflexPanic = false;
      return;
   }

   debugMilitaryDefending("--- Running Rule newDefend. ---");

   static int enemyArmyQuery = -1;
   if (enemyArmyQuery < 0) // First run.
   {
      enemyArmyQuery = kbUnitQueryCreate("newDefend Enemy army query");
      kbUnitQuerySetPlayerRelation(enemyArmyQuery, cPlayerRelationEnemyNotGaia);
      kbUnitQuerySetUnitType(enemyArmyQuery, cUnitTypeLogicalTypeLandMilitary);
      kbUnitQuerySetState(enemyArmyQuery, cUnitStateAlive);
      kbUnitQuerySetVisibleState(enemyArmyQuery, cUnitQueryVisibleStateVisible);
   }

   // If our globals are invalid we need to set up new plans.
   if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == false)
   {
      createPrimaryDefendPlan();
   }

   // Get our arrays in order.
   updateBaseArrays();

   // Move our gPrimaryLandDefendPlan to the base we think we're most likely to get attacked at.
   determinePrimaryBaseToStationUnits();

   int currentAvailablePopToDefendWith = aiPlanGetCurrentPopulation(gPrimaryLandDefendPlan, -1, true);
   if (currentAvailablePopToDefendWith == 0)
   {
      debugMilitaryDefending("We currently have no pop at all in our gPrimaryLandDefendPlan, can't do any other defending.");
      return;
   }

   int maxToSteal = -1;
   if (aiPlanGetState(gPrimaryLandDefendPlan) == cPlanStateAttack)
   {
      kbUnitQuerySetPosition(enemyArmyQuery, kbBaseGetLocation(cMyID, aiPlanGetBaseID(gPrimaryLandDefendPlan)));
      kbUnitQuerySetMaximumDistance(enemyArmyQuery, aiPlanGetVariableFloat(gPrimaryLandDefendPlan, cDefendPlanEngageRange, 0));
      kbUnitQueryResetResults(enemyArmyQuery);
      kbUnitQueryExecute(enemyArmyQuery);
      int enemyPopCountAttackingPrimaryDefend = kbUnitQueryGetPopulationSlots(enemyArmyQuery);
      debugMilitaryDefending("gPrimaryLandDefendPlan is currently in combat inside base "
         + kbBaseGetNameByID(cMyID, aiPlanGetBaseID(gPrimaryLandDefendPlan)) + " and sees : " +
         enemyPopCountAttackingPrimaryDefend + " enemy population to fight against.");
      if (enemyPopCountAttackingPrimaryDefend * gWinningArmyPercentage > currentAvailablePopToDefendWith)
      {
         debugMilitaryDefending("Our gPrimaryLandDefendPlan is currently engaged and we're not decisively winning, " + 
            "can't defend other spots atm.");
         return;
      }
      maxToSteal = currentAvailablePopToDefendWith - enemyPopCountAttackingPrimaryDefend * gWinningArmyPercentage;
      if (maxToSteal <= 4)
      {
         debugMilitaryDefending("Our gPrimaryLandDefendPlan is currently engaged and we don't have enough units left to defer.");
         return;
      }
   }
   else
   {
      debugMilitaryDefending("gPrimaryLandDefendPlan currently sees no enemies in base: " +
         kbBaseGetNameByID(cMyID, aiPlanGetBaseID(gPrimaryLandDefendPlan)) + ".");
   }

   // Loop through our other TC bases, to see if they need to be defended.
   if (gDefendTCBases.size() > 1)
   {
      for (int i = 0; i < gDefendTCBases.size(); i++)
      {
         int baseID = gDefendTCBases[i];
         if (baseID == aiPlanGetBaseID(gPrimaryLandDefendPlan))
         {
            continue;
         }
         debugMilitaryDefending("*** Analyzing Base: " + kbBaseGetNameByID(cMyID, baseID) + " ***");
         kbUnitQuerySetPosition(enemyArmyQuery, kbBaseGetLocation(cMyID, baseID));
         kbUnitQuerySetMaximumDistance(enemyArmyQuery, kbBaseGetDistance(cMyID, baseID));
         kbUnitQueryResetResults(enemyArmyQuery);
         int numEnemies = kbUnitQueryExecute(enemyArmyQuery);
         if (numEnemies == 0)
         {
            debugMilitaryDefending("      No enemies in this base, skipping.");
            continue;
         }
         // If these scouts will actually attack us we will find that when we check last damage stuff.
         if (enemiesAreOnlyScouts(numEnemies, enemyArmyQuery) == true)
         {
            debugMilitaryDefending("      Enemies in the base are scouts, skipping.");
            continue;
         }
         int enemyArmyPopCount = kbUnitQueryGetPopulationSlots(enemyArmyQuery);
         int wantedSize = ceil(enemyArmyPopCount * gWinningArmyPercentage);
         int existingPlanID = -1;
         for (int iPlan = 0; iPlan < gDefendPlans.size(); iPlan++)
         {
            if (aiPlanGetBaseID(gDefendPlans[iPlan]) == baseID)
            {
               debugMilitaryDefending("      We're being attacked in base " + kbBaseGetNameByID(cMyID, baseID) + ", but we already " +
                  "have a defend plan going for this base.");
               int alreadyAssignedPop = aiPlanGetCurrentPopulation(gDefendPlans[iPlan], -1, true);
               wantedSize -= alreadyAssignedPop;
               debugMilitaryDefending("      Reducing newly wanted pop number by " + alreadyAssignedPop + " because of already " +
                  "assigned units to the plan.");
               existingPlanID = gDefendPlans[iPlan];
               break;
            }
         }
         if (wantedSize <= 0)
         {
            debugMilitaryDefending("      Our existing defend plan requires no further units.");
            continue;
         }
         if (maxToSteal != -1 && wantedSize > maxToSteal)
         {
            debugMilitaryDefending("      We're under attack in base: " + kbBaseGetNameByID(cMyID, baseID) + ", but gPrimaryLandDefendPlan " +
               "is already engaged. We don't have enough units to spare to satisfy this base's needs: " + maxToSteal + "/" + wantedSize);
            continue;
         }
         int actuallyStolen = createOrReinforcecBaseDefendResponsePlan(existingPlanID, baseID, wantedSize, maxToSteal != -1);
         debugMilitaryDefending("      Managed to assign " + actuallyStolen + " pop to the defend plan.");
         currentAvailablePopToDefendWith -= actuallyStolen;
         if (currentAvailablePopToDefendWith == 0)
         {
            debugMilitaryDefending("We have no pop left in our gPrimaryLandDefendPlan, can't do any other defending.");
            return;
         }

         if (maxToSteal != -1)
         {
            maxToSteal -= actuallyStolen;
            if (maxToSteal <= 4)
            {
               debugMilitaryDefending("We don't have enough troops left new to defend another base, quiting.");
               return;
            }
         }
      }
   }
}
