//==============================================================================
/* naval_military.xs

   This file is intended for any naval military unit handling.

*/
//==============================================================================

//==============================================================================
// updateEnemyDocksArray
// Search for enemy Docks that we can potentially attack.
//==============================================================================
void updateEnemyDocksArray(ref int[] enemyDocks)
{
   static int dockQueryID = -1;
   if (dockQueryID == -1) // First run.
   {
      dockQueryID = kbUnitQueryCreate("updateEnemyDocksArray");
      kbUnitQuerySetPlayerRelation(dockQueryID, cPlayerRelationEnemyNotGaia);
      kbUnitQuerySetUnitType(dockQueryID, cUnitTypeAbstractDock);
      kbUnitQuerySetState(dockQueryID, cUnitStateABQ);
   }
   
   // Re-set areagroupID since it may change.
   kbUnitQuerySetAreaGroupID(dockQueryID, gMapInfo.mDockAreaGroupID);
   kbUnitQueryResetResults(dockQueryID);
   kbUnitQueryExecute(dockQueryID);
   enemyDocks = kbUnitQueryGetResults(dockQueryID);
}

//==============================================================================
// mostHatedNavalEnemy
// Determine who we should attack on water.
//==============================================================================
void mostHatedNavalEnemy(ref int targetDockID, ref int[] enemyDocks)
{
   debugNavalMilitary("--- Running mostHatedNavalEnemy ---");
   xsSetRuleMinInterval("navalMonitor", 30); // Reset interval.

   int numEnemies = getNumberEnemies();
   if (numEnemies == 0)
   {
      debugNavalMilitary("We currently have no enemies, setting MostHatedNavalPlayerID to cNoEnemies.");
      aiSetMostHatedNavalPlayerID(cNoEnemies);
      return;
   }

   int numEnemyDocks = enemyDocks.size();
   if (numEnemyDocks != 0)
   {
      int targetPlayerID = -1;
      if (gOverrideNavalTargetPlayer != -1)
      {
         targetPlayerID = gOverrideNavalTargetPlayer;
         if (targetPlayerID == cOverrideDontNavalAttackPlayerID)
         {
            debugNavalMilitary("Override found: changing MostHatedNavalPlayerID to: " + gOverrideTargetPlayerID +
               ", 700 means don't attack");
            aiSetMostHatedNavalPlayerID(cOverrideDontNavalAttackPlayerID);
            return;
         }
         for (int i = 0; i < enemyDocks.size(); i++)
         {
            if (kbUnitGetPlayerID(enemyDocks[i]) == targetPlayerID)
            {
               targetDockID = enemyDocks[i];
               break;
            }
         }
         if (targetDockID == -1)
         {
            debugNavalMilitary("We haven't scouted any enemy Docks for gOverrideNavalTargetPlayer, setting " +
               "MostHatedNavalPlayerID to cScoutingForEnemies.");
            aiSetMostHatedNavalPlayerID(cScoutingForEnemies);
            return;
         }
      }
      else
      {
         if (numEnemyDocks == 1)
         {
            targetPlayerID = kbUnitGetPlayerID(enemyDocks[0]);
            targetDockID = enemyDocks[0];
         }
         else
         {  // Randomly take a Dock from our array to attack.
            int rand = xsRandInt(0, numEnemyDocks - 1);
            targetPlayerID = kbUnitGetPlayerID(enemyDocks[rand]);
            targetDockID = enemyDocks[rand];
         }
      }

      aiSetMostHatedNavalPlayerID(targetPlayerID);
      debugNavalMilitary("Setting our MostHatedNavalPlayerID to " + targetPlayerID + ", determined via gEnemyDocks array.");
      return;
   }

   debugNavalMilitary("We haven't scouted any enemy Docks, start/keep scouting for them.");
   aiSetMostHatedNavalPlayerID(cScoutingForEnemies);

   // Update more often if we're scouting so we can get out of that state asap.
   xsSetRuleMinInterval("navalMonitor", 15);
}

//==============================================================================
// metRequirementsToAttackNaval
//==============================================================================
bool metRequirementsToAttackNaval()
{
   bool metRequirements = true;
   // If our defend plan is already in combat we won't send our navy to attack yet.
   if (aiPlanGetState(gPrimaryNavalDefendPlan) == cPlanStateAttack)
   {
      debugNavalMilitary("We can't attack because our naval defend plan is in state attack, meaning we're in danger already.");
      metRequirements = false;
   }

   // We need at least 30% of our wanted navy size to be able to launch an attack.
   int targetNavalMilitaryPop = aiGetNavalMilitaryPop();
   int currentNavalMilitaryPop = aiPlanGetCurrentPopulation(gPrimaryNavalDefendPlan);
   const float neededNavalRatio = 0.3;
   if (currentNavalMilitaryPop < targetNavalMilitaryPop * neededNavalRatio)
   {
      debugNavalMilitary("We can't attack because we have too few naval units. We have: " + currentNavalMilitaryPop + ", pop " + 
         "and we need: " + targetNavalMilitaryPop * neededNavalRatio + ".");
      metRequirements = false;
   }
   
   int currentTime = xsGetTime();
   // Hard and below must always perform the time check if they're not the attacker personality.
   // Titan and above, or below but attacker, can skip the timecheck if they have more than 70% of their wanted naval military.
   if ((cDifficultyCurrent <= cDifficultyHard && cPersonalityCurrent != cPersonalityAttacker) ||
       currentNavalMilitaryPop < (targetNavalMilitaryPop * 0.7))
   {
      // Let's do a time check now against our global interval.
      if (gLastNavalAttackTime + gNavalAttackInterval > currentTime)
      {
         debugNavalMilitary("It's too early to launch a naval attack, next attack will happen at: " +
            turnNumberIntoTimeDisplay(gLastNavalAttackTime + gNavalAttackInterval));
         metRequirements = false;
      }
   }

   return metRequirements;
}

//==============================================================================
// navalAttackManager
// This nalyzes the current situation in the game and decides if we should
// attack an enemy OR defend an ally in need.
//==============================================================================
void navalAttackManager()
{
   if (cDifficultyCurrent == cDifficultyEasy && cPersonalityCurrent != cPersonalityAttacker)
   {
      return;
   }
   debugNavalMilitary("--- Running navalAttackManager. ---");

   // Run all the pre-req functions first so we know precisely what we're dealing with.
   int targetDockID = -1;
   int[] enemyDocks = new int(0, 0);
   updateEnemyDocksArray(enemyDocks);
   mostHatedNavalEnemy(targetDockID, enemyDocks);

   // Out if we don't meet the requirements.
   if (metRequirementsToAttackNaval() == false)
   {
      return;
   }

   int targetPlayer = aiGetMostHatedNavalPlayerID();
   if (targetPlayer == cOverrideDontNavalAttackPlayerID)
   {
      debugNavalMilitary("Can't attack because of global override.");
      return;
   }

   if (targetPlayer == cNoEnemies)
   {
      // We're waiting for a remaining player to become an enemy now.
      debugNavalMilitary("Can't perform a naval attack because we have no enemy players at the moment.");
      return;
   }
   if (targetPlayer == cScoutingForEnemies)
   {
      // We're scouting for the enemy now.
      debugNavalMilitary("Can't perform a naval attack because we haven't scouted any enemy Docks yet.");
      return;
   }

   if (targetDockID == -1)
   {
      aiEchoWarning("navalAttackManager - we passed all our targetPlayer checks but still have an invalid " + 
         " targetDockID: " + targetDockID + ".");
      return;
   }
   if (kbAreaGetType(kbAreaGetIDByPosition(kbBaseGetLocation(targetPlayer, kbUnitGetBaseID(targetDockID)))) != cAreaTypeWater)
   {
      aiEchoWarning("navalAttackManager - we found a Dock to attack but the base it's in is not on the water.");
      return;
   }
   
   // If we're here we're clear to make an attack!
   
   int planID = aiPlanCreate("Naval Attack Player: " + targetPlayer + ", Dock: " + targetDockID, cPlanAttack, -1,
      gNavalMilitaryCategoryID);
   aiPlanSetVariableInt(planID, cAttackPlanTargetPlayerID, 0, targetPlayer);
   aiPlanSetVariableInt(planID, cAttackPlanTargetBaseID, 0, kbUnitGetBaseID(targetDockID));

   aiPlanSetVariableInt(planID, cAttackPlanTargetMode, 0, cAttackPlanTargetModeBase);
   aiPlanSetVariableInt(planID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
   aiPlanSetVariableInt(planID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeCantFindMoreEnemyBases);
   aiPlanSetVariableInt(planID, cAttackPlanMovementTypeFlags, 0, cPassabilityWater);
   
   aiPlanSetInitialPosition(planID, gMapInfo.mWaterDefendPoint);
   aiPlanSetVariableVector(planID, cAttackPlanGatherPoint, 0, gMapInfo.mWaterDefendPoint);
   aiPlanSetVariableFloat(planID, cAttackPlanGatherDistance, 0, 15.0);
   aiPlanSetVariableInt(planID, cAttackPlanGatherWaitTime, 0, 30 * 1000);
   setDefaultAttackPlanTargetUnitTypes(planID);

   aiPlanAddUnitType(planID, cUnitTypeLogicalTypeNavalMilitary, 0, 0, 200);
   // Manually add all our naval military to this attack plan to make sure they all go attack.
   transferAllUnitsBetweenTwoPlans(gPrimaryNavalDefendPlan, planID);
   aiPlanSetPriority(planID, 30);
   aiPlanSetFlag(planID, cPlanFlagNoMoreUnits, true);

   sendStatementToAlliesWithVector(cAICommPromptToAllyIAmAttackingHere, kbUnitGetPosition(targetDockID));
   sendStatementToEnemies(cAICommPromptToEnemyIStartAnAttack);
   gLastNavalAttackTime = xsGetTime();
   debugNavalMilitary("***** LAUNCHING NAVAL ATTACK on player: " + targetPlayer + ", Dock: " + targetDockID + ", Base: " +
      kbBaseGetNameByID(targetPlayer, kbUnitGetBaseID(targetDockID)) + ".");
}

//==============================================================================
// createPrimaryNavalDefendPlan
// Create our main naval defend plan.
//==============================================================================
void createPrimaryNavalDefendPlan()
{
   if (aiPlanGetIsIDValid(gPrimaryNavalDefendPlan) == false)
   {
      gPrimaryNavalDefendPlan = aiPlanCreate("Primary naval Defend", cPlanDefend, -1, gNavalMilitaryCategoryID);
   
      aiPlanSetVariableInt(gPrimaryNavalDefendPlan, cDefendPlanTargetMode, 0, cDefendPlanTargetModePoint);
      aiPlanSetVariableInt(gPrimaryNavalDefendPlan, cDefendPlanTargetPlayerID, 0, cMyID);
      aiPlanSetVariableFloat(gPrimaryNavalDefendPlan, cDefendPlanGatherDistance, 0, 20.0);
      aiPlanSetVariableFloat(gPrimaryNavalDefendPlan, cDefendPlanEngageRange, 0, 50.0);
      setDefaultDefendPlanTargetUnitTypes(gPrimaryNavalDefendPlan);

      aiPlanAddUnitType(gPrimaryNavalDefendPlan, cUnitTypeLogicalTypeNavalMilitary, 0, 0, 200);
      aiPlanSetPriority(gPrimaryNavalDefendPlan, 10); // Very low priority, don't steal from attack plans.
      debugNavalMilitary("Creating primary naval defend plan.");
   }

   // Dynamic data gets reset each time.
   // TODO remove all units if this point changes and is then in another area group.
   aiPlanSetInitialPosition(gPrimaryNavalDefendPlan, gMapInfo.mWaterDefendPoint);
   aiPlanSetVariableVector(gPrimaryNavalDefendPlan, cDefendPlanTargetPoint, 0, gMapInfo.mWaterDefendPoint);
   aiPlanSetVariableVector(gPrimaryNavalDefendPlan, cDefendPlanGatherPoint, 0, gMapInfo.mWaterDefendPoint);
}

//==============================================================================
// getNavalTransport
//==============================================================================
int getNavalTransport()
{
   switch(cMyCulture)
   {
      case cCultureGreek:
      {
         return cUnitTypeTransportShipGreek;
      }
      case cCultureEgyptian:
      {
         return cUnitTypeTransportShipEgyptian;
      }
      case cCultureNorse:
      {
         return cUnitTypeTransportShipNorse;
      }
      case cCultureAtlantean:
      {
         return cUnitTypeTransportShipAtlantean;
      }
   }
   return -1;
}

//==============================================================================
// navalMonitor
//==============================================================================
rule navalMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   if (gMapInfo.mHasWater == false)
   {
      debugNavalMilitary("Disabling navalMonitor because there is no water on the map.");
      xsDisableRule("navalMonitor");
      return;
   }

   if (checkStrategyFlag(cStrategyFlagAutomaticNavalGameplay) == false)
   {
      if (aiPlanGetIsIDValid(gPrimaryNavalDefendPlan) == true)
      {
         aiPlanDestroy(gPrimaryNavalDefendPlan);
      }
      return;
   }

   if (gMapInfo.mShouldBuildDock == false)
   {
      debugNavalMilitary("Not running navalMonitor because currently we're not wanting to have a Dock.");
      return;
   }
   if (kbGetIsLocationOnMap(gMapInfo.mWaterDefendPoint) == false)
   {
      aiEchoWarning("Somehow we're thinking we need to be running naval logic but our water defend point is invalid!");
      return;
   }

   // Perform the entire naval military chain.
   createPrimaryNavalDefendPlan();
   navalAttackManager();

   // TODO actually train transports on demand somehow.
   if (aiPlanGetIsIDValid(gTransportMaintainPlanID) == false)
   {
      int planID = aiPlanCreate("Naval Transport Maintain", cPlanTrain, -1, gNavalMilitaryTrainingCategoryID);
      if (planID == -1)
      {
         return;
      }
      int transportPUID = getNavalTransport();
      aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, transportPUID);
      aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, 2);
      gTransportMaintainPlanID = planID;
   }
}