//==============================================================================
/* godpowers_norse.xs

   This file contains all logic for the Norse god powers.

*/

extern int gDwarvenMinePlanID = -1;
extern int gGreatHuntPlanID = -1;
extern int gSpyPlanID = -1;
extern int gGullinburstiPlanID = -1;
extern int gUnderminePlanID = -1;
extern int gHealingSpringPlanID = -1;
extern int gForestFirePlanID = -1;
extern int gAsgardianBastonPlanID = -1;
extern int gWalkingWoodsPlanID = -1;
extern int gWalkingWoodsAttackPlanID = -1;
extern int gRagnarokPlanID = -1;
extern int gInfernoPlanID = -1;

//==============================================================================
// setupNorseGodPowerPlan
//==============================================================================
void setupNorseGodPowerPlan(int planID = -1, int protoPowerID = -1)
{
   aiPlanSetVariableInt(planID, cPlanGodPower, 0, protoPowerID);

   switch (protoPowerID)
   {
      case cProtoPowerDwarvenMine:
      {
         gDwarvenMinePlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelBuildingPlacement);
         xsEnableRule("dwarvenMineMonitor");
         break;
      }

      case cProtoPowerGreatHunt:
      {
         gGreatHuntPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
         xsEnableRule("greatHuntMonitor");
         xsRuleIgnoreIntervalOnce("greatHuntMonitor"); // Cast fast during BO.
         break;
      }

      case cProtoPowerSpy:
      {
         gSpyPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelUnit);
         xsEnableRule("spyMonitor");
         break;
      }

      case cProtoPowerGullinbursti:
      {
         gGullinburstiPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
         xsEnableRule("gullinburstiMonitor");
      }

      case cProtoPowerForestFire:
      {
         gForestFirePlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelUnit);
         xsEnableRule("forestFireMonitor");
         break;
      }

      case cProtoPowerHealingSpring:
      {
         gHealingSpringPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelBuildingPlacement);
         xsEnableRule("healingSpringMonitor");
         break;
      }

      case cProtoPowerUndermine:
      {
         gUnderminePlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationDual);
         xsEnableRule("undermineMonitor");
         break;
      }

      case cProtoPowerAsgardianBastion:
      {
         gAsgardianBastonPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelBuildingPlacement);
         xsEnableRule("asgardianBastionMonitor");
         xsRuleIgnoreIntervalOnce("asgardianBastionMonitor");
         break;
      }

      case cProtoPowerFrost:
      {
         // TODO: defender personality only defensive.
         int queryID = kbUnitQueryCreate(aiPlanGetName(planID) + " Frost Query");
         kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
         kbUnitQuerySetUnitType(queryID, cUnitTypeMilitaryUnit);
         kbUnitQuerySetMaximumDistance(queryID, kbGodPowerGetRadius(cProtoPowerFrost, cMyID));
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         // v1.8: snizeny min. pocet ze 10 na 7 - Frost se casta drive pri mensi skupince nepritratel
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryMinimumCount, 0, 7); // bylo 10
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);

         // v1.8: snizeny min. vlastni armada - cast i s mensi silou
         aiPlanSetVariableInt(planID, cGodPowerPlanOwnArmyMinimumCount, 0, selectByDifficulty(2, 3, 4, 6, 8, 8)); // bylo (3,4,6,8,10,10)

         aiPlanSetVariableBool(planID, cGodPowerPlanRequiresCombatPlan, 0, true);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelCombatPlanDistance);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocation);
         break;
      }

      case cProtoPowerFlamingWeapons:
      {
         int queryID = kbUnitQueryCreate(aiPlanGetName(planID) + " Flaming Weapons Query");
         kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
         kbUnitQuerySetUnitType(queryID, cUnitTypeMilitaryUnit);
         kbUnitQuerySetMaximumDistance(queryID, 20.0);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryMinimumCount, 0, 15);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);

         // Be healthy before we cast.
         aiPlanSetVariableFloat(planID, cGodPowerPlanOwnArmyMinimumPercentHealth, 0, 70);
         aiPlanSetVariableInt(planID, cGodPowerPlanOwnArmyMinimumCount, 0, selectByDifficulty(5, 8, 11, 15, 18, 20));

         aiPlanSetVariableBool(planID, cGodPowerPlanRequiresCombatPlan, 0, true);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelCombatPlanDistance);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelWorld);
         break;
      }

      case cProtoPowerWalkingWoods:
      {
         gWalkingWoodsPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
         xsEnableRule("walkingWoodsMonitor");
         break;
      }

      case cProtoPowerTempest:
      {
         int queryID = kbUnitQueryCreate(aiPlanGetName(planID) + " Tempest Query");
         kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
         kbUnitQuerySetUnitType(queryID, cUnitTypeLogicalTypeLandMilitary);
         kbUnitQuerySetMaximumDistance(queryID, kbGodPowerGetRadius(cProtoPowerTempest, cMyID));
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryMinimumCount, 0, 10);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
         
         aiPlanSetVariableBool(planID, cGodPowerPlanRequiresCombatPlan, 0, true);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelCombatPlanDistance);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocation);
         break;
      }

      case cProtoPowerRagnarok:
      {
         gRagnarokPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelWorld);
         xsEnableRule("ragnarokMonitor");
         // v2.0 FIX: odstranen xsRuleIgnoreIntervalOnce - predchazel okamzitemu castu
         // pri odemknuti moci bez overeni takticky vhodneho momentu.
         break;
      }

      case cProtoPowerFimbulwinter:
      {
         // Just insta cast.
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelWorld);
         break;
      }

      case cProtoPowerNidhogg:
      {
         // v1.7 BUG FIX: bylo: cil na vlastni gather point (nesmyslne - drak utoci na nasi zakladnu)
         // Oprava: cil na nepratelskou zakladnu pokud utocime, jinak vlastni gather point jako fallback
         vector nidhoggLocation = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);
         int nidhoggEnemy = aiGetMostHatedPlayerID();
         if (nidhoggEnemy > 0 && kbBaseGetNumber(nidhoggEnemy) > 0)
         {
            int enemyBaseID = kbBaseGetIDByIndex(nidhoggEnemy, 0);
            nidhoggLocation = kbBaseGetLocation(nidhoggEnemy, enemyBaseID);
            debugGodPowers("v1.7: Nidhogg miri na zakladnu nepritele " + nidhoggEnemy);
         }
         aiPlanSetVariableVector(planID, cGodPowerPlanTargetLocation, 0, nidhoggLocation);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
         break;
      }

      case cProtoPowerInferno:
      {
         gInfernoPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationDual);
         xsEnableRule("infernoMonitor");
         break;
      }

      default:
      {
         aiEchoWarning("setupNorseGodPowerPlan called with unrecognized protoPowerID: " + protoPowerID + ", name: " +
            kbGodPowerGetName(protoPowerID) + ".");
         break;
      }
   }
}

//==============================================================================
// dwarvenMineMonitor
//==============================================================================
rule dwarvenMineMonitor
inactive
minInterval 15
{
   debugGodPowers("--- Running Rule dwarvenMineMonitor. ---");
   int queryID = useSimpleUnitQuery(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateAlive);
   int numResults = kbUnitQueryExecute(queryID);
   if (numResults == 0)
   {
      debugGodPowers("We have no Town Centers to orient our Dwarven Mine around, not casting now.");
      return;
   }
   int safestBaseID = -1;
   float safestBaseRating = cMinFloat;
   int[] results = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < numResults; i++)
   {
      int tcID = results[i];
      if (getUnitCountByLocation(cUnitTypeGoldResource, 0, cUnitStateAlive, kbUnitGetPosition(tcID), 55.0) >= 1)
      {
         debugGodPowers("Found a gold mine near TC " + tcID + ", not casting Dwarven Mine now.");
         return;
      }
      int baseID = kbUnitGetBaseID(tcID);
      float defenseRating = kbBaseGetDefenseRating(cMyID, baseID);
      if (defenseRating > safestBaseRating)
      {
         safestBaseRating = defenseRating;
         safestBaseID = baseID;
      }
   }

   debugGodPowers("Attempt to cast Dwarven Mine for base: " + kbBaseGetNameByID(cMyID, safestBaseID) + ".");
   aiPlanSetVariableBool(gDwarvenMinePlanID, cGodPowerPlanAutoCast, 0, true);
   aiPlanSetVariableInt(gDwarvenMinePlanID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(gDwarvenMinePlanID) + " Dwarven Mine Placement");
   kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeMineDwarvenLarge);
   addSafeBackAreasToBuildingPlacement(bpID, safestBaseID, true);
   kbBuildingPlacementSetRequiresCompletelyUnobstructed(bpID, true);
   // Risky 2.0, but this one is difficult to place.
   kbBuildingPlacementSetBufferSpace(bpID, 2.0);
   aiPlanSetVariableInt(gDwarvenMinePlanID, cGodPowerPlanBPID, 0, bpID);

   xsDisableRule("dwarvenMineMonitor");
}

//==============================================================================
// greatHuntMonitor
// TODO: atm no support for just casting it randomly on the map when all hunt is gone, we shouldn't need this either really...
//==============================================================================
rule greatHuntMonitor
inactive
minInterval 15
{
   debugGodPowers("--- Running Rule greatHuntMonitor. ---");
   int[] gatherPlans = aiPlanGetIDsByTypeAndVariableIntValue(cPlanGather, cGatherPlanResourceType, cResourceFood);

   // Closest distance to nearby TC.
   float closestDistance = cMaxFloat;
   int bestKBResourceID = -1;
   for (int i = 0; i < gatherPlans.size(); i++)
   {
      int subtype = aiPlanGetVariableInt(gatherPlans[i], cGatherPlanResourceSubType, 0);
      if (subtype != cAIResourceSubTypeHunt && subtype != cAIResourceSubTypeHuntAggressive)
      {
         continue;
      }
      int kbResourceID = aiPlanGetVariableInt(gatherPlans[i], cGatherPlanKBResourceID, 0);
      if (kbResourceGetTotalResources(kbResourceID) < 500.0)
      {
         debugGodPowers("Too few resources left in KB Resource: " + kbResourceID + ", belonging to plan: " +
            aiPlanGetName(gatherPlans[i]) + ".");
         continue;
      }

      vector resourcePosition = kbResourceGetPosition(kbResourceID);
      // This can happen if the gather plan is still walking towards this resource.
      if (kbLocationVisible(resourcePosition) == false)
      {
         debugGodPowers("Location of KB Resource: " + kbResourceID + " isn't visible, belonging to plan: "
            + aiPlanGetName(gatherPlans[i]) + ".");
         continue;
      }
      int closestTCID = getClosestUnitByLocation(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateAlive, resourcePosition, 100.0);
      float distance = 500.0 * 500.0; // If we have no TC we still cast this basically because we don't discard this distance.
      if (closestTCID != -1)
      {
         distance = xsVectorDistanceXZSqr(resourcePosition, kbUnitGetPosition(closestTCID));
      }
      
      if (distance < closestDistance)
      {
         closestDistance = distance;
         bestKBResourceID = kbResourceID;
      }
   }

   if (bestKBResourceID == -1)
   {
      debugGodPowers("Found no KB Resource to use Great Hunt on.");
      return;
   }

   debugGodPowers("Casting Great Hunt on KB Resource ID: " + bestKBResourceID + ".");
   aiPlanSetVariableVector(gGreatHuntPlanID, cGodPowerPlanTargetLocation, 0, kbResourceGetPosition(bestKBResourceID));
   aiPlanSetVariableBool(gGreatHuntPlanID, cGodPowerPlanAutoCast, 0, true);
   xsDisableRule("greatHuntMonitor");
}

//==============================================================================
// spyMonitor
// This GP barely helps us...
//==============================================================================
rule spyMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule spyMonitor. ---");

   int toSpyID = -1;
   int[] explorePlans = aiPlanGetIDsByType(cPlanExplore);
   for (int i = 0; i < explorePlans.size(); i++)
   {
      if (aiPlanGetNumberUnits(explorePlans[i]) <= 0)
      {
         debugGodPowers(aiPlanGetName(explorePlans[i]) + " currently has no units in it, skipping.");
         continue;
      }
      int scoutID = aiPlanGetUnitIDByIndex(explorePlans[i], 0);
      vector scoutPosition = kbUnitGetPosition(scoutID);
      int villagerID = getClosestUnitByLocation(cUnitTypeAbstractVillager, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
         scoutPosition, kbUnitGetStatFloat(scoutID, cUnitStatLOS));
      if (villagerID == -1)
      {
         debugGodPowers("Found no Villager near plan " + aiPlanGetName(explorePlans[i]) + " to use Spy on.");
         continue;
      }
      toSpyID = villagerID;
      break;
   }

   if (toSpyID == -1)
   {
      debugGodPowers("Found no Villager to cast Spy on.");
      return;
   }

   debugGodPowers("Casting Spy on unit: " + toSpyID + ".");
   aiPlanSetVariableInt(gSpyPlanID, cGodPowerPlanTargetUnit, 0, toSpyID);
   aiPlanSetVariableBool(gSpyPlanID, cGodPowerPlanAutoCast, 0, true);
   xsDisableRule("spyMonitor");
}

int gGullinburstiBaseID = -1;
//==============================================================================
// gullinburstiMonitor
// TEMP until defend rework is done and we can properly assess if a base is in danger TODO.
//==============================================================================
rule gullinburstiMonitor
inactive
minInterval 15
{
   debugGodPowers("--- Running Rule gullinburstiMonitor. ---");

   float radius = kbGodPowerGetRadius(cProtoPowerGullinbursti, cMyID);
   int numberBases = kbBaseGetNumber(cMyID);
   for (int i = 0; i < numberBases; i++)
   {
      int baseID = kbBaseGetIDByIndex(cMyID, i);
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
      {
         continue;
      }
      vector baseLocation = kbBaseGetLocation(cMyID, baseID);
      int alliedQueryID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationAlly, cUnitStateAlive, baseLocation,
                                             radius);
      int numAllied = kbUnitQueryExecute(alliedQueryID);
      // ATTENTION: after this point alliedQueryID can't be used for anything anymore since the next useSimpleUnitQuery overwrites
      // its results.
      int enemyQueryID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
         baseLocation, radius);
      int numEnemies = kbUnitQueryExecute(enemyQueryID);
      debugGodPowers("Found " + numEnemies + " enemies and " + numAllied + " allies in base: " + kbBaseGetNameByID(cMyID, baseID));
      if (numEnemies > 5 && (numEnemies * 0.6) > numAllied)
      {
         debugGodPowers("We're severely outnumbered in base " + kbBaseGetNameByID(cMyID, baseID) + ", casting Gullinbursti here!");
         vector castLocation = kbUnitGetPosition(kbUnitQueryGetResult(enemyQueryID, 0));
         // We just cast it on the first enemy from the query.
         aiPlanSetVariableVector(gGullinburstiPlanID, cGodPowerPlanTargetLocation, 0, castLocation);
         aiPlanSetVariableBool(gGullinburstiPlanID, cGodPowerPlanAutoCast, 0, true);
         gGullinburstiBaseID = baseID;
         xsDisableRule("gullinburstiMonitor");
         break;
      }
   }
}

//==============================================================================
// gullinburstiDefendMonitor
//==============================================================================
rule gullinburstiDefendMonitor
inactive
minInterval 5
{
   debugGodPowers("--- Running Rule gullinburstiDefendMonitor. ---");

   static int defendPlanID = -1;
   if (defendPlanID == -1) // First run this Gullinbursti cast.
   {
      defendPlanID = aiPlanCreate("Gullinbursti Defend", cPlanDefend, -1, gMilitaryDefendingCategoryID);
      aiPlanAddUnitType(defendPlanID, cUnitTypeAbstractGullinbursti, 1, 1, 1);
      aiPlanSetVariableInt(defendPlanID, cDefendPlanTargetMode, 0, cDefendPlanTargetModeBase);
      aiPlanSetVariableInt(defendPlanID, cDefendPlanTargetPlayerID, 0, cMyID);
      aiPlanSetVariableInt(defendPlanID, cDefendPlanTargetBaseID, 0, gGullinburstiBaseID);
      aiPlanSetVariableVector(defendPlanID, cDefendPlanGatherPoint, 0, kbBaseGetMilitaryGatherPoint(cMyID, gGullinburstiBaseID));
      aiPlanSetVariableFloat(defendPlanID, cDefendPlanGatherDistance, 0, 20.0);
      aiPlanSetVariableFloat(defendPlanID, cDefendPlanEngageRange, 0, kbBaseGetDistance(cMyID, gGullinburstiBaseID) + 10.0);
      setDefaultDefendPlanTargetUnitTypes(defendPlanID);
      aiPlanSetPriority(defendPlanID, 99);
      aiPlanSetFlag(defendPlanID, cPlanFlagCantBeStolenFrom, true);
      debugGodPowers("Creating Gullinbursti defend plan.");
   }

   if (aiPlanGetNumberUnits(defendPlanID) == 0)
   {
      int unitID = getUnit(cUnitTypeAbstractGullinbursti);
      if (unitID == -1)
      {
         debugGodPowers("We've lost our Gullinbursti, destroying the defend plan and disabling this rule.");
         aiPlanDestroy(defendPlanID);
         defendPlanID = -1;
         xsDisableRule("gullinburstiDefendMonitor");
      }
      else
      {
         aiPlanAddUnit(defendPlanID, unitID);
      }
   }
   else
   {
      debugGodPowers("Defend plan for Gullinbursti is still operating as normal.");
   }
}

//==============================================================================
// undermineMonitor
//==============================================================================
rule undermineMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule undermineMonitor. ---");

   // v1.8: detekuj zda ma nepritel hodne hradeb - pokud ano, preferuj je jako cil Undermine
   int undTargetPlayer = aiGetMostHatedPlayerID();
   bool undPreferWalls = false;
   if (undTargetPlayer > 0)
   {
      int undWallCount = kbUnitCount(cUnitTypeWallLong, undTargetPlayer, cUnitStateAlive);
      if (undWallCount >= 5)
      {
         undPreferWalls = true;
         debugGodPowers("Undermine: enemy has " + undWallCount + " walls, preferring wall target.");
      }
   }

   int[] plans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
   for (int i = 0; i < plans.size(); i++)
   {
      if (aiPlanGetParentID(plans[i]) != -1) // Parent plan, no reinforcement.
      {
         continue;
      }
      vector planPosition = aiPlanGetLocation(plans[i]);

      // v1.8: kdyz nepritel stavi hodne hradeb, zkus nejdriv najit zed jako cil
      int targetID = -1;
      if (undPreferWalls == true)
      {
         // v2.1: neber nejblizsi zed - vyber cluster s nejvice vezemi/strel. budovami.
         int wallQueryID = useSimpleUnitQuery(cUnitTypeWallLong, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
            planPosition, 45.0);
         int wallResults = kbUnitQueryExecute(wallQueryID);
         int[] wallIDs = kbUnitQueryGetResults(wallQueryID);
         int bestWallTowers = -1;
         int bestWallShooters = -1;
         for (int wi = 0; wi < wallResults; wi++)
         {
            vector wallPos = kbUnitGetPosition(wallIDs[wi]);
            int nearbyTowers = getUnitCountByLocation(cUnitTypeAbstractTower, cPlayerRelationEnemyNotGaia,
               cUnitStateAlive, wallPos, 18.0, cUnitQueryVisibleStateVisible);
            int nearbyShooters = getUnitCountByLocation(cUnitTypeLogicalTypeBuildingsThatShoot, cPlayerRelationEnemyNotGaia,
               cUnitStateAlive, wallPos, 18.0, cUnitQueryVisibleStateVisible);
            if (nearbyTowers > bestWallTowers || (nearbyTowers == bestWallTowers && nearbyShooters > bestWallShooters))
            {
               targetID = wallIDs[wi];
               bestWallTowers = nearbyTowers;
               bestWallShooters = nearbyShooters;
            }
         }
         if (targetID != -1)
            debugGodPowers("Undermine: found wall cluster target. Towers=" + bestWallTowers + ", shooters=" + bestWallShooters + ".");
      }
      if (targetID == -1)
      {
         targetID = getClosestUnitByLocation(cUnitTypeLogicalTypeBuildingsThatShoot, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
            planPosition, 25.0, cUnitQueryVisibleStateVisible);
      }
      if (targetID == -1)
      {
         debugGodPowers("Found no closeby buildings that shoot for plan " + aiPlanGetName(plans[i]) + ", skipping.");
         continue;
      }
      
      vector firstTargetPosition = kbUnitGetPosition(targetID);
      vector secondTargetPosition = cOriginVector;

      // Try to find another build that shoots around our first target. Doesn't have to be visible since we normalize.
      int queryID = useSimpleUnitQuery(cUnitTypeLogicalTypeBuildingsThatShoot, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
         firstTargetPosition, 25.0);
      kbUnitQuerySetAscendingSort(queryID, true);
      int numResults = kbUnitQueryExecute(queryID);
      if (numResults == 1)
      {
         debugGodPowers("We didn't find another building that shoots to angle our Undermine towards, " +
            "just sending it to the bottom of the map now.");
      }
      else
      {
         int secondTargetID = kbUnitQueryGetResult(queryID, 1);
         secondTargetPosition = kbUnitGetPosition(secondTargetID);
         debugGodPowers("Found a second building that shoots to angle our Undermine towards: " + secondTargetID + ".");
      }

      // We only need to provide a direction, not an end point. So make sure this direction position is close to the first position
      // which then in turn ensures we have vision over it.
      secondTargetPosition = firstTargetPosition - xsVectorNormalize(firstTargetPosition - secondTargetPosition);

      aiPlanSetVariableVector(gUnderminePlanID, cGodPowerPlanTargetLocation, 0, firstTargetPosition);
      aiPlanSetVariableVector(gUnderminePlanID, cGodPowerPlanTargetLocation, 1, secondTargetPosition);
      aiPlanSetVariableBool(gUnderminePlanID, cGodPowerPlanAutoCast, 0, true);
      xsDisableRule("undermineMonitor");
      return;
   }
}

//==============================================================================
// healingSpringMonitor
//==============================================================================
rule healingSpringMonitor
inactive
minInterval 15
{
   debugGodPowers("--- Running Rule healingSpringMonitor. ---");

   int safestBaseID = -1;
   float bestDefenseRating = cMinFloat;
   int numberBases = kbBaseGetNumber(cMyID);
   for (int i = 0; i < numberBases; i++)
   {
      int baseID = kbBaseGetIDByIndex(cMyID, i);
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == true)
      {
         float defenseRating = kbBaseGetDefenseRating(cMyID, baseID);
         // If you change any of the logic here please also adjust the rebuy logic for this god power.
         vector MGP = kbBaseGetMilitaryGatherPoint(cMyID, baseID);
         if (MGP == cInvalidVector)
         {
            debugGodPowers("Skipping Town Center base: " + kbBaseGetNameByID(cMyID, baseID) + " because it has no MGP set.");
            continue;
         }
         if (getUnitCountByLocation(cUnitTypeHealingSpring, cPlayerRelationAny, cUnitStateAlive, MGP, 50.0) >= 1)
         {
            debugGodPowers("Skipping Town Center base: " + kbBaseGetNameByID(cMyID, baseID) + " because there is already a " +
               "Healing Spring there.");
            continue;
         }
         if (defenseRating > bestDefenseRating)
         {
            bestDefenseRating = defenseRating;
            safestBaseID = baseID;
         }
      }
   }
   // v1.8: pri aktivnim utoku preferuj zakladnu nejbliz fronte - spring opravuje vojsko pred utokem
   if (gAdaptAttackInProgress == true)
   {
      int[] hsAttackPlans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
      int hsBestAttackPlan = -1;
      int hsBestAttackUnits = -1;
      for (int hap = 0; hap < hsAttackPlans.size(); hap++)
      {
         if (aiPlanGetParentID(hsAttackPlans[hap]) != -1)
            continue;
         int hsPlanUnits = aiPlanGetNumberUnits(hsAttackPlans[hap], -1, false);
         if (hsPlanUnits > hsBestAttackUnits)
         {
            hsBestAttackUnits = hsPlanUnits;
            hsBestAttackPlan = hsAttackPlans[hap];
         }
      }
      if (hsBestAttackPlan != -1)
      {
         // v2.1 BUG FIX: bylo hsAttackPlans[0] - pri vice frontach mohl Spring jit na vedlejsi nebo child plan.
         vector hsAttackPos = aiPlanGetLocation(hsBestAttackPlan);
         float hsBestDist = 999999.0;
         int hsClosestBase = -1;
         for (int hsi = 0; hsi < numberBases; hsi++)
         {
            int hsBid = kbBaseGetIDByIndex(cMyID, hsi);
            if (kbBaseIsFlagSet(cMyID, hsBid, cBaseFlagTownCenter) == false)
               continue;
            vector hsMGP = kbBaseGetMilitaryGatherPoint(cMyID, hsBid);
            if (hsMGP == cInvalidVector)
               continue;
            if (getUnitCountByLocation(cUnitTypeHealingSpring, cPlayerRelationAny, cUnitStateAlive, hsMGP, 50.0) >= 1)
               continue;
            float hsDist = xsVectorDistanceXZ(hsMGP, hsAttackPos);
            if (hsDist < hsBestDist)
            {
               hsBestDist = hsDist;
               hsClosestBase = hsBid;
            }
         }
         if (hsClosestBase != -1)
         {
            safestBaseID = hsClosestBase;
            debugGodPowers("HealingSpring: attack in progress, using forward base for main attack.");
         }
      }
   }

   if (safestBaseID == -1)
   {
      debugGodPowers("Currently have no Town Center bases to orient our Healing Spring around, not casting now.");
      return;
   }

   debugGodPowers("Best base to orient our Healing Spring around: " + kbBaseGetNameByID(cMyID, safestBaseID) + ".");

   vector MGP = kbBaseGetMilitaryGatherPoint(cMyID, safestBaseID);
   if (getUnitCountByLocation(cUnitTypeMilitaryUnit, cPlayerRelationEnemyNotGaia, cUnitStateAlive, MGP, 30.0,
         cUnitQueryVisibleStateVisible) > 0)
   {
      debugGodPowers("Can't cast Healing Spring in the best base now since there are enemies around!");
      return;
   }
   
   debugGodPowers("Attempt to cast Healing Spring for base: " + kbBaseGetNameByID(cMyID, safestBaseID) + ".");

   aiPlanSetVariableBool(gHealingSpringPlanID, cGodPowerPlanAutoCast, 0, true);
   aiPlanSetVariableInt(gHealingSpringPlanID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(gHealingSpringPlanID) + " Healing Spring Placement");
   kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeHealingSpring);
   kbBuildingPlacementSetCenterPosition(bpID, MGP, 20.0);
   kbBuildingPlacementAddPositionInfluence(bpID, MGP, 100.0, 20.0, cFalloffLinear);
   kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeAbstractSocketedTownCenter, 15.0, 20.0, cFalloffLinear);
   kbBuildingPlacementSetStepSize(bpID, 1.0);
   kbBuildingPlacementSetRequiresCompletelyUnobstructed(bpID, true);
   // Risky 1.0, but this one is difficult to place.
   kbBuildingPlacementSetBufferSpace(bpID, 1.0);
   aiPlanSetVariableInt(gHealingSpringPlanID, cGodPowerPlanBPID, 0, bpID);

   xsDisableRule("healingSpringMonitor");
}

//==============================================================================
// forestFireMonitor
// Yes we will walk into our own flames XD
// TODO this is really bad...
//==============================================================================
rule forestFireMonitor
inactive
minInterval 15
{
   debugGodPowers("--- Running Rule forestFireMonitor. ---");

   int toBurn = -1;

   // v2.7 IMP7: skenujeme VSECHNY zakladny nepritele, bereme tu s nejvice sekaci vesnicany.
   // bylo: vzdy jen kbBaseGetIDByIndex(0) → mohla to byt forward base bez eco activity.
   int ffTargetPlayer = aiGetMostHatedPlayerID();
   if (ffTargetPlayer > 0 && kbBaseGetNumber(ffTargetPlayer) > 0)
   {
      int ffBestVill = 0;
      int ffNumBases = kbBaseGetNumber(ffTargetPlayer);
      for (int ffb = 0; ffb < ffNumBases; ffb++)
      {
         int ffBaseID = kbBaseGetIDByIndex(ffTargetPlayer, ffb);
         vector ffEnemyBase = kbBaseGetLocation(ffTargetPlayer, ffBaseID);
         int ffCandTree = getClosestUnitByLocation(cUnitTypeTree, cPlayerMotherNatureID, cUnitStateAlive,
            ffEnemyBase, 60.0);
         if (ffCandTree == -1) { continue; }
         int ffNearbyVill = getUnitCountByLocation(cUnitTypeAbstractVillager, cPlayerRelationEnemyNotGaia,
            cUnitStateAlive, kbUnitGetPosition(ffCandTree), 30.0);
         if (ffNearbyVill < 2 || ffNearbyVill <= ffBestVill) { continue; }
         int ffKBResID = kbUnitGetKBResourceID(ffCandTree);
         if (kbResourceGetIsIDValid(ffKBResID) == false) { continue; }
         int ffNumTrees = 0;
         int ffTotalTrees = kbResourceGetNumberUnits(ffKBResID);
         for (int fft = 0; fft < ffTotalTrees; fft++)
         {
            if (kbUnitGetIsIDValid(kbResourceGetUnit(ffKBResID, fft)) == true)
               ffNumTrees++;
            if (ffNumTrees >= 10) { break; }
         }
         if (ffNumTrees >= 10)
         {
            debugGodPowers("ForestFire: eco target base " + ffb + " - " + ffNearbyVill + " villagers near tree cluster.");
            toBurn = ffCandTree;
            ffBestVill = ffNearbyVill;
         }
      }
   }

   if (toBurn != -1)
   {
      aiPlanSetVariableInt(gForestFirePlanID, cGodPowerPlanTargetUnit, 0, toBurn);
      aiPlanSetVariableBool(gForestFirePlanID, cGodPowerPlanAutoCast, 0, true);
      xsDisableRule("forestFireMonitor");
      return;
   }

   // Analyze both exploration plans as attack plans that barely have any units left (reduce chance of burning ourself).
   int[] plans = aiPlanGetIDsByType(cPlanExplore);
   int[] attackPlans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
   for (int i = 0; i < attackPlans.size(); i++)
   {
      if (aiPlanGetCurrentPopulation(attackPlans[i]) >= 8)
      {
         continue;
      }
      plans.add(attackPlans[i]);
   }

   for (int i = 0; i < plans.size(); i++)
   {
      if (aiPlanGetNumberUnits(plans[i]) <= 0)
      {
         debugGodPowers(aiPlanGetName(plans[i]) + " currently has no units in it, skipping.");
         continue;
      }
      int scoutID = aiPlanGetUnitIDByIndex(plans[i], 0);
      vector scoutPosition = kbUnitGetPosition(scoutID);
      int tcID = getClosestUnitByLocation(cUnitTypeAbstractSocketedTownCenter, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
         scoutPosition, 60.0);
      if (tcID == -1)
      {
         debugGodPowers("Found no TC near plan " + aiPlanGetName(plans[i]) + " to search for trees.");
         continue;
      }
      int treeID = getClosestUnitByLocation(cUnitTypeTree, cPlayerMotherNatureID, cUnitStateAlive,
         scoutPosition, kbUnitGetStatFloat(scoutID, cUnitStatLOS));
      if (treeID == -1)
      {
         debugGodPowers("Found no tree near plan " + aiPlanGetName(plans[i]) + " to analyze.");
         continue;
      }
      int kbResourceID = kbUnitGetKBResourceID(treeID);
      if (kbResourceGetIsIDValid(kbResourceID) == false)
      {
         aiEchoWarning("forestFireMonitor - found tree " + treeID + " has no valid KB Resource associated with it.");
         continue;
      }
      int numTrees = kbResourceGetNumberUnits(kbResourceID);
      int numAliveTrees = 0;
      for (int iTree = 0; iTree < numTrees; iTree++)
      {
         if (kbUnitGetIsIDValid(kbResourceGetUnit(kbResourceID, iTree)) == true)
         {
            numAliveTrees++;
            if (numAliveTrees >= 10)
            {
               break;
            }
         }
      }
      if (numAliveTrees < 10)
      {
         debugGodPowers("Found only " + numAliveTrees + " alive trees, can't cast Forest Fire on kb resource id: " + kbResourceID + ".");
         continue;
      }
      toBurn = treeID;
      break;
   }

   if (toBurn == -1)
   {
      debugGodPowers("Found no Tree to cast Forest Fire on.");
      return;
   }

   debugGodPowers("Casting Forest Fire  on tree: " + toBurn + ".");
   aiPlanSetVariableInt(gForestFirePlanID, cGodPowerPlanTargetUnit, 0, toBurn);
   aiPlanSetVariableBool(gForestFirePlanID, cGodPowerPlanAutoCast, 0, true);
   xsDisableRule("forestFireMonitor");
}

//==============================================================================
// asgardianBastionMonitor
//==============================================================================
rule asgardianBastionMonitor
inactive
minInterval 30
{
   debugGodPowers("--- Running Rule asgardianBastionMonitor. ---");

   // v2.7 IMP9: bylo nahodna zakladna (xsRandInt) → preferuj nejlepe branenon zakladnu.
   // getMostDefendedTCBase() vraci TC zakladnu s nejvyssim defense ratingem (stejna logika jako healingSpringMonitor).
   int baseID = getMostDefendedTCBase();
   if (baseID == -1)
   {
      debugGodPowers("Currently have no Town Center bases to orient our Asgardian Bastion around, not casting now.");
      return;
   }
   debugGodPowers("Base chosen to place our Asgardian Bastion in: " + kbBaseGetNameByID(cMyID, baseID) + ".");

   aiPlanSetVariableBool(gAsgardianBastonPlanID, cGodPowerPlanAutoCast, 0, true);
   aiPlanSetVariableInt(gAsgardianBastonPlanID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(gAsgardianBastonPlanID) + " Asgardian Bastion Placement");
   kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeAsgardianHillFort);
   kbBuildingPlacementSetBaseID(bpID, baseID);
   kbBuildingPlacementSetRequiresCompletelyUnobstructed(bpID, true);
   avoidBlockingImportantSpots(gAsgardianBastonPlanID, bpID);
   // Risky 1.0, but this one is difficult to place.
   kbBuildingPlacementSetBufferSpace(bpID, 1.0);
   aiPlanSetVariableInt(gAsgardianBastonPlanID, cGodPowerPlanBPID, 0, bpID);

   xsDisableRule("asgardianBastionMonitor");
}

//==============================================================================
// walkingWoodsMonitor
// If we're close to an enemy TC and still have some army left, cast!
//==============================================================================
rule walkingWoodsMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule walkingWoodsMonitor. ---");

   int[] plans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
   int numPlans = plans.size();
   if (numPlans <= 0)
   {
      debugGodPowers("Found 0 attack plans in attack state to analyze.");
      return;
   }

   for (int i = 0; i < plans.size(); i++)
   {
      if (aiPlanGetParentID(plans[i]) != -1) // Parent plan, no reinforcement.
      {
         continue;
      }

      vector planLocation = aiPlanGetLocation(plans[i]);

      int numAttackingTroops = aiPlanGetNumberUnits(plans[i], -1, false);
      debugGodPowers("We found " + numAttackingTroops + " units belonging to: " + aiPlanGetName(plans[i]) + ".");
      if (numAttackingTroops < selectByDifficulty(3, 5, 7, 9, 11, 13))
      {
         debugGodPowers("Too few attacking units to casting Walking Woods.");
         continue;
      }

      int numEnemies = getUnitCountByLocation(cUnitTypeMilitaryUnit, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
         planLocation, aiPlanGetVariableFloat(plans[i], cAttackPlanAttackModeEngageRange, 0), cUnitQueryVisibleStateVisible);
      debugGodPowers("We found " + numEnemies + " units belonging to the enemy close to this plan.");
      // If we're outnumbering the enemy or are close to we proceed.
      if (numAttackingTroops < (numEnemies * 0.8))
      {
         debugGodPowers("Our units versus enemy units isn't in the right range to use Walking Woods.");
         continue;
      }

      int treeID = getClosestUnitByLocation(cUnitTypeTree, cPlayerMotherNatureID, cUnitStateAlive, planLocation, 30.0, cUnitQueryVisibleStateVisible);
      if (treeID == -1)
      {
         debugGodPowers("Found no tree near plan " + aiPlanGetName(plans[i]) + " to analyze.");
         continue;
      }

      vector treePosition = kbUnitGetPosition(treeID);
      int count = getUnitCountByLocation(cUnitTypeTree, cPlayerMotherNatureID, cUnitStateAlive, treePosition, 6.0);
      if (count < 6)
      {
         debugGodPowers("Didn't find enough trees near " + aiPlanGetName(plans[i]) + " to cast Walking Woods on to be worth it.");
         continue;
      }

      debugGodPowers("Casting Walking Woods to reinforce: " + aiPlanGetName(plans[i]));
      aiPlanSetVariableVector(gWalkingWoodsPlanID, cGodPowerPlanTargetLocation, 0, treePosition);
      aiPlanSetVariableBool(gWalkingWoodsPlanID, cGodPowerPlanAutoCast, 0, true);
      gWalkingWoodsAttackPlanID = plans[i];
      xsDisableRule("walkingWoodsMonitor");
      return;
   }
}

//==============================================================================
// addWalkingWoodsToAttackPlanMonitor
//==============================================================================
rule addWalkingWoodsToAttackPlanMonitor
inactive
minInterval 2
{
   if (aiPlanGetIsIDValid(gWalkingWoodsAttackPlanID) == false)
   {
      xsDisableRule("addWalkingWoodsToAttackPlanMonitor");
      return;
   }
   debugGodPowers("--- Running Rule addWalkingWoodsToAttackPlanMonitor. ---");

   // We are going to make the assumption that we only have this new fresh batch of Walking Woods and aren't somehow involving
   // Walking woods that were alive for some time already.
   int queryID = useSimpleUnitQuery(cUnitTypeAbstractWalkingWoods);
   int numUnits = kbUnitQueryExecute(queryID);
   int[] units = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < numUnits; i++)
   {
      aiPlanAddUnit(gWalkingWoodsAttackPlanID, units[i]);
      debugGodPowers("Added unitID: " + units[i] + " to: " +  aiPlanGetName(gWalkingWoodsAttackPlanID) + ".");
   }

   // All units spawn at the same time, only need 1 run.
   xsDisableRule("addWalkingWoodsToAttackPlanMonitor");
}

//==============================================================================
// ragnarokMonitor
//==============================================================================
rule ragnarokMonitor
inactive
minInterval 15
{
   debugGodPowers("--- Running Rule ragnarokMonitor. ---");

   // If you change any of the logic here please also adjust the rebuy logic for this god power.
   int wantedEcoPop = aiGetEconomyPop();
   int villagerCount = kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive);
   int caravanCount = kbUnitCount(gCaravanUnit, cMyID, cUnitStateAlive);

   // v2.0: minimum absolutni pocet vesnicanu - pod 8 nema smysl konvertovat
   if (villagerCount < 8)
   {
      debugGodPowers("Ragnarok: too few villagers (" + villagerCount + "), waiting for 8+.");
      return;
   }

   // v2.0: cast az v Heroic age+ (pred tim je prilis brzo)
   if (kbPlayerGetAge(cMyID) < cAge3)
   {
      debugGodPowers("Ragnarok: waiting for Heroic age.");
      return;
   }

   // Reduce wantedEcoPop by the Caravan count first.
   int effectiveEcoPop = wantedEcoPop - caravanCount;
   if (effectiveEcoPop <= 0) { effectiveEcoPop = 1; }
   float percentageVillsAlive = xsIntToFloat(villagerCount) / xsIntToFloat(effectiveEcoPop);
   debugGodPowers("Have " + percentageVillsAlive + " percentage Villagers alive.");

   if (percentageVillsAlive < 0.50)
   {
      debugGodPowers("Don't have enough Villagers alive to cast Ragnarok effectively.");
      return;
   }

   // v2.0: castuj jen ve vhodne situaci - velka bitva nebo panika nebo Mythic age
   bool ragnarokSituation = false;
   if (kbPlayerGetAge(cMyID) >= cAge4) { ragnarokSituation = true; } // Mythic = vzdy dobry cas
   if (gAdaptAttackInProgress == true) { ragnarokSituation = true; } // Aktivni utok = posil armadu
   if (gDefenseReflexPanic == true) { ragnarokSituation = true; }    // Panika = zesileni obrany
   if (ragnarokSituation == false)
   {
      debugGodPowers("Ragnarok: waiting for a tactical moment (big battle or Mythic age).");
      return;
   }

   // TODO custom set up a ton of attack if need be.
   //xsDisableRule("attackManager"); // We set up custom attacks for this and enable this again later.
   debugGodPowers("Casting Ragnarok, prepare to die!");
   aiPlanSetVariableBool(gRagnarokPlanID, cGodPowerPlanAutoCast, 0, true);
   xsDisableRule("ragnarokMonitor");
}

//==============================================================================
// infernoMonitor
//==============================================================================
rule infernoMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule infernoMonitor. ---");

   int[] plans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);

   for (int i = 0; i < plans.size(); i++)
   {
      if (aiPlanGetParentID(plans[i]) != -1) // Don't want reinforcement plans.
      {
         continue;
      }

      int queryID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
         aiPlanGetLocation(plans[i]), 25.0);
      kbUnitQuerySetAscendingSort(queryID, true);
      kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
      int numResults = kbUnitQueryExecute(queryID);
      int numEnemiesRequired = selectByDifficulty(6, 8, 10, 12, 14, 16);
      if (numResults < numEnemiesRequired)
      {
         debugGodPowers("We didn't find enough enemies to cast Inferno for this plan: " + aiPlanGetName(plans[i]) + ".");
         continue;
      }
      int[] enemies = kbUnitQueryGetResults(queryID);
      debugGodPowers("We found enough enemies near plan: " + aiPlanGetName(plans[i]) + " to cast Inferno!");

      // Take closest unit to cast on.
      vector explosionPosition = kbUnitGetPosition(enemies[0]);
      aiPlanSetVariableVector(gInfernoPlanID, cGodPowerPlanTargetLocation, 1, explosionPosition);
      // Now we need to calculate the start point, luckily this doesn't deal so much friendly damage because the point we find here
      // is pretty random...
      bool foundValidPosition = false;
      vector startPosition = explosionPosition;
      // TODO could scan here for enemies / allies on these points to give them a rating.
      for (int j = 0; j < 4; j++)
      {
         vector temp = startPosition;
         switch (j)
         {
            case 0:
            {
               temp.x += 35.0;
               break;
            }
            case 1:
            {
               temp.x -= 35.0;
               break;
            }
            case 2:
            {
               temp.z += 35.0;
               break;
            }
            case 3:
            {
               temp.z -= 35.0;
               break;
            }
         }
         if (kbGetIsLocationOnMap(temp) == true)
         {
            startPosition = temp;
            foundValidPosition = true;
            break;
         }
      }
      if (foundValidPosition == false)
      {
         debugGodPowers("Couldn't find a start position for Inferno that's on the map, can't cast now.");
         return;
      }
      aiPlanSetVariableVector(gInfernoPlanID, cGodPowerPlanTargetLocation, 0, startPosition);
      aiPlanSetVariableBool(gInfernoPlanID, cGodPowerPlanAutoCast, 0, true);
      xsDisableRule("infernoMonitor");
      return;
   }
}
