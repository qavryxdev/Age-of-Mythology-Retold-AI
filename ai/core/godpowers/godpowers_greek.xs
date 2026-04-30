//==============================================================================
/* godpowers_greek.xs

   This file contains all logic for the Greek god powers.

*/
//==============================================================================

extern int gSentinelPlanID = -1;
extern int gLurePlanID = -1;
extern int gCeaseFirePlanID = -1;
extern int gEarthquakePlanID = -1;
extern int gPlentyVaultPlanID = -1;

//==============================================================================
// setupGreekGodPowerPlan
//==============================================================================
void setupGreekGodPowerPlan(int planID = -1, int protoPowerID = -1)
{
   aiPlanSetVariableInt(planID, cPlanGodPower, 0, protoPowerID);

   switch (protoPowerID)
   {
      case cProtoPowerBolt:
      {
         // We bolt the first enemy unit we see that has over 250.0 current hit points.
         // v1.7: zvyseno na 500 HP - setrit Bolt na hrdiny/myticke/siege, ne obycejne pesaky
         int queryID = kbUnitQueryCreate(aiPlanGetName(planID) + " Bolt Query");
         kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
         kbUnitQuerySetUnitType(queryID, cUnitTypeLogicalTypeValidBoltTarget);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         aiPlanSetVariableFloat(planID, cGodPowerPlanQueryMinimumHitpoints, 0, 500.0); // bylo: 250.0
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
         
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelQuery);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelUnit);
         break;
      }

      case cProtoPowerSentinel:
      {
         gSentinelPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelUnit);
         xsEnableRule("sentinelMonitor");
         break;
      }

      case cProtoPowerLure:
      {
         gLurePlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelBuildingPlacement);
         xsEnableRule("lureMonitor");
         break;
      }

      case cProtoPowerRestoration:
      {
         // v1.7: snizeno min nepritratel 10->6 a vlastni HP threshold 60->70 (lecci drive)
         // cGodPowerPlanRequiresCombatPlan=true = funguje pro utocne I obranneho plany (kdyz oba v cPlanStateAttack)
         int queryID = kbUnitQueryCreate(aiPlanGetName(planID) + " Restoration Query");
         kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
         kbUnitQuerySetUnitType(queryID, cUnitTypeMilitaryUnit);
         kbUnitQuerySetMaximumDistance(queryID, 20.0);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryMinimumCount, 0, 6);  // bylo: 10
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);

         aiPlanSetVariableFloat(planID, cGodPowerPlanOwnArmyMaximumPercentHealth, 0, 70); // bylo: 60 - leci drive (pri 30% ztrate)
         aiPlanSetVariableInt(planID, cGodPowerPlanOwnArmyMinimumCount, 0, selectByDifficulty(3, 4, 5, 6, 8, 8)); // bylo: 3,4,6,8,10,10

         aiPlanSetVariableBool(planID, cGodPowerPlanRequiresCombatPlan, 0, true);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelCombatPlanDistance);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocation);
         break;
      }

      case cProtoPowerCeaseFire:
      {
         gCeaseFirePlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelWorld);
         xsEnableRule("ceaseFireMonitor");
         break;
      }

      case cProtoPowerPestilence:
      {
         int queryID = kbUnitQueryCreate(aiPlanGetName(planID) + " Pestilence Query");
         kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
         kbUnitQuerySetUnitType(queryID, cUnitTypeLogicalTypeMilitaryProductionBuilding);
         kbUnitQuerySetMaximumDistance(queryID, 30.0);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateSeeable);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryMinimumCount, 0, 3);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);

         aiPlanSetVariableBool(planID, cGodPowerPlanRequiresCombatPlan, 0, true);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelCombatPlanDistance);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocation);
         break;
      }

      case cProtoPowerUnderworldPassage:
      {
         break;
      }

      case cProtoPowerCurse:
      {
         int queryID = kbUnitQueryCreate(aiPlanGetName(planID) + " Curse Query");
         kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
         kbUnitQuerySetUnitType(queryID, cUnitTypeLogicalTypeLandMilitary);
         kbUnitQuerySetMaximumDistance(queryID, 20.0);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryMinimumCount, 0, 10);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
         
         aiPlanSetVariableBool(planID, cGodPowerPlanRequiresCombatPlan, 0, true);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelCombatPlanDistance);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocation);
         break;
      }

      case cProtoPowerBronze:
      {
         int queryID = kbUnitQueryCreate(aiPlanGetName(planID) + " Bronze Query");
         kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
         kbUnitQuerySetUnitType(queryID, cUnitTypeMilitaryUnit);
         kbUnitQuerySetMaximumDistance(queryID, 20.0);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryMinimumCount, 0, 10);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);

         aiPlanSetVariableFloat(planID, cGodPowerPlanOwnArmyMinimumPercentHealth, 0, 70); // need some HP left to make this worth it.
         aiPlanSetVariableInt(planID, cGodPowerPlanOwnArmyMinimumCount, 0, selectByDifficulty(4, 6, 9, 11, 13, 15));

         aiPlanSetVariableBool(planID, cGodPowerPlanRequiresCombatPlan, 0, true);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelCombatPlanDistance);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelAttachedCombatPlanLocation);
         break;
      }

      case cProtoPowerPlentyVault:
      {
         gPlentyVaultPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelBuildingPlacement);
         xsEnableRule("plentyVaultMonitor");
         break;
      }
      
      case cProtoPowerLightningStorm:
      {
         int queryID = kbUnitQueryCreate(aiPlanGetName(planID) + " Lightning Storm Query");
         kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
         kbUnitQuerySetUnitType(queryID, cUnitTypeMilitaryUnit);
         kbUnitQuerySetMaximumDistance(queryID, 20.0);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryMinimumCount, 0, 10); // bylo: 15 - prilis konzervativni
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);

         aiPlanSetVariableBool(planID, cGodPowerPlanRequiresCombatPlan, 0, true);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelCombatPlanDistance);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocation);
         break;
      }

      case cProtoPowerEarthquake:
      {
         gEarthquakePlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
         xsEnableRule("earthquakeMonitor");
         break;
      }

      default:
      {
         aiEchoWarning("setupGreekGodPowerPlan called with unrecognized protoPowerID: " + protoPowerID + ", name: " +
            kbGodPowerGetName(protoPowerID) + ".");
         break;
      }
   }
}

//==============================================================================
// sentinelMonitor
//==============================================================================
rule sentinelMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule sentinelMonitor. ---");

   int baseID = getLeastDefendedTCBase();
   if (baseID == -1)
   {
      debugGodPowers("Can't cast Sentinel atm because we have no Town Center base.");
      return;
   }

   int tcID = getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, kbBaseGetLocation(cMyID, baseID), 20.0);
   if (tcID == -1)
   {
      aiEchoWarning("sentinelMonitor - getLeastDefendedTCBase saw a TC base that was valid for Sentinel but our getUnitByLocation " + 
         "couldn't find a TC in that base: " + kbBaseGetNameByID(cMyID, baseID) + ".");
      return;
   }

   aiPlanSetVariableBool(gSentinelPlanID, cGodPowerPlanAutoCast, 0, true);
   aiPlanSetVariableInt(gSentinelPlanID, cGodPowerPlanTargetUnit, 0, tcID);
   xsDisableRule("sentinelMonitor");
}

//==============================================================================
// lureMonitor
//==============================================================================
rule lureMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule lureMonitor. ---");

   int baseID = getMostDefendedTCBase();
   if (baseID == -1)
   {
      debugGodPowers("Can't cast Lure atm because we have no Town Center base.");
      return;
   }

   int bpID = kbBuildingPlacementCreate(aiPlanGetName(gLurePlanID) + " Lure Placement");
   kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeLure);
   kbBuildingPlacementSetBaseID(bpID, baseID, cBuildingPlacementOrientationPreferenceNone);
   kbBuildingPlacementSetStepSize(bpID, 2.0);
   kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeAbstractSocketedTownCenter, 100.0, 10.0);
   kbBuildingPlacementSetRequiresCompletelyUnobstructed(bpID, true);
   aiPlanSetVariableInt(gLurePlanID, cGodPowerPlanBPID, 0, bpID);

   aiPlanSetVariableBool(gLurePlanID, cGodPowerPlanAutoCast, 0, true);
   xsDisableRule("lureMonitor");
}

//==============================================================================
// ceaseFireMonitor
//==============================================================================
rule ceaseFireMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule ceaseFireMonitor. ---");
   static int defCon = 0;
   int mainBaseID = kbBaseGetMainID(cMyID);
   bool nowUnderAttack = kbBaseGetTimeUnderAttack(cMyID, mainBaseID) > 0;

   //Not in a state of alert.
   if (defCon == 0)
   {
      //Just get out if we are safe.
      if (nowUnderAttack == false)
      {
         return;
      }

      //Up the alert level and come back later.
      defCon += 1;
      return;
   }

   //If we are no longer under attack and below this point, then reset and get out.
   if (nowUnderAttack == false)
   {
      defCon = 0;
      return;
   }

   //Otherwise handle the different alert levels.
   //Do we have any help in the area that we can use?
   //If we don't have a query ID, create it.
   static int allyQueryID = -1;
   if (allyQueryID < 0)
   {
      allyQueryID = kbUnitQueryCreate("AllyCount");
      kbUnitQuerySetPlayerRelation(allyQueryID, cPlayerRelationAlly);
      kbUnitQuerySetUnitType(allyQueryID, cUnitTypeMilitaryUnit);
      kbUnitQuerySetState(allyQueryID, cUnitStateAlive);
      //If we still don't have one, bail.
      if (allyQueryID < 0)
      {
         return;
      }
   }

   kbUnitQuerySetBaseID(allyQueryID, mainBaseID);
   kbUnitQueryResetResults(allyQueryID);
   int count = kbUnitQueryExecute(allyQueryID);

   //If there are still allies in the area, then just stay at this alert level.
   if (count > 0)
   {
      return;
   }

   //Defcon 2. Cast the god power.
   aiPlanSetVariableBool(gCeaseFirePlanID, cGodPowerPlanAutoCast, 0, true);
   kbUnitQueryDestroy(allyQueryID);
   xsDisableRule("ceaseFireMonitor");
}

//==============================================================================
// earthquakeMonitor
//==============================================================================
rule earthquakeMonitor
inactive
minInterval 5
{
   debugGodPowers("--- Running Rule earthquakeMonitor. ---");
   static int reservePlanID = -1;
   if (aiPlanGetIsIDValid(reservePlanID) == false)
   {
      reservePlanID = aiPlanCreate("Earthquake reserve plan", cPlanReserve, -1, gGodpowersCategoryID);
      aiPlanSetPriority(reservePlanID, 100);
      aiPlanSetFlag(reservePlanID, cPlanFlagNoMoreUnits, true); // Prevent auto assignment.
   }

   static int currentState = cGPStateBegin;
   static int scoutID = -1;
   static int targetID = -1;
   static int iterator = 0; // Used to only send a move command/debug output every 5 iterations.
   bool castGodPower = false;

   switch (currentState)
   {
      case cGPStateBegin:
      {
         // v1.9: cil nejhustsi shluk budov bliz utoku - Earthquake nici budovy v oblasti
         int[] eqPlans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
         for (int eqi = 0; eqi < eqPlans.size(); eqi++)
         {
            if (aiPlanGetParentID(eqPlans[eqi]) != -1)
               continue;
            vector eqAttackPos = aiPlanGetLocation(eqPlans[eqi]);
            int eqBldgCount = getUnitCountByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia,
               cUnitStateAlive, eqAttackPos, 35.0, cUnitQueryVisibleStateVisible);
            if (eqBldgCount >= 5)
            {
               debugGodPowers("Earthquake: targeting building cluster near attack (" + eqBldgCount + " buildings).");
               aiPlanSetVariableVector(gEarthquakePlanID, cGodPowerPlanTargetLocation, 0, eqAttackPos);
               aiPlanSetVariableBool(gEarthquakePlanID, cGodPowerPlanAutoCast, 0, true);
               xsDisableRule("earthquakeMonitor");
               return;
            }
         }
         // Fallback: puvodni TC targeting (skaut se pohybuje k TC)
         bool foundTC = godPowerFindTCInRangeAndScout(gEarthquakePlanID, scoutID, targetID, castGodPower);
         // TC can already be in range, then we're already done!
         if (castGodPower == true)
         {
            xsSetRuleMinInterval("earthquakeMonitor", 5);
            currentState = cGPStateCleanup;
            return;
         }
         if (foundTC == true)
         {
            currentState = cGPStatePathingToLocation;
            // Need to keep checking godPowerExploreTargetPosition often.
            xsSetRuleMinInterval("earthquakeMonitor", 1);
         }
         break;
      }

      case cGPStatePathingToLocation:
      {
         bool pathingToLocation = godPowerExploreTargetPosition(gEarthquakePlanID, scoutID, targetID, iterator, reservePlanID, castGodPower);
         if (castGodPower == true)
         {
            xsSetRuleMinInterval("earthquakeMonitor", 5);
            currentState = cGPStateCleanup;
            return;
         }
         if (pathingToLocation == false)
         {
            iterator = 0;
            currentState = cGPStateBegin;
            xsSetRuleMinInterval("earthquakeMonitor", 5);
         }
         break;
      }

      case cGPStateCleanup:
      {
         // Remove scout from reserve plan a bit later otherwise we might lose vision too fast.
         if (aiPlanGetIsIDValid(reservePlanID) == true)
         {
            aiPlanDestroy(reservePlanID);
         }
         iterator = 0;
         xsDisableRule("earthquakeMonitor");
         break;
      }
   }
}

//==============================================================================
// plentyVaultMonitor
//==============================================================================
rule plentyVaultMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule plentyVaultMonitor. ---");

   // v1.9: Plenty Vault pouzij jen kdyz mame malo zlata - generuje trickling
   if (kbResourceGet(cResourceGold) > 300)
   {
      debugGodPowers("Plenty Vault: gold above 300, saving for when truly needed.");
      return;
   }

   int baseID = getMostDefendedTCBase();
   if (baseID == -1)
   {
      debugGodPowers("Can't cast Plenty Vault atm because we have no Town Center base.");
      return;
   }
   vector basePosition = kbBaseGetLocation(cMyID, baseID);
   if (getUnitCountByLocation(cUnitTypeMilitaryUnit, cPlayerRelationEnemyNotGaia, cUnitStateAlive, basePosition,
         kbBaseGetDistance(cMyID, baseID)) > 0)
   {
      debugGodPowers("Can't cast Plenty Vault atm because we see enemies in base " + kbBaseGetNameByID(cMyID, baseID) + ".");
      return;
   }

   int bpID = kbBuildingPlacementCreate(aiPlanGetName(gPlentyVaultPlanID) + " Plenty Vault Placement");
   kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypePlentyVault);
   addSafeBackAreasToBuildingPlacement(bpID, baseID, true);
   kbBuildingPlacementSetRequiresCompletelyUnobstructed(bpID, true);
   // Risky cuz it can block builders but this thing is hard enough to place as it is.
   kbBuildingPlacementSetBufferSpace(bpID, 0.0);
   aiPlanSetVariableInt(gPlentyVaultPlanID, cGodPowerPlanBPID, 0, bpID);
   aiPlanSetVariableBool(gPlentyVaultPlanID, cGodPowerPlanAutoCast, 0, true);
   xsDisableRule("plentyVaultMonitor");
}