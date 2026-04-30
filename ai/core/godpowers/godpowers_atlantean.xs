//==============================================================================
/* godpowers_atlantean.xs

   This file contains all logic for the Atlantean god powers.

*/

extern int gDeconstructionPlanID = -1;
extern int gShockwavePlanID = -1;
extern int gGaiaForestPlanID = -1;
extern int gCarnivoraPlanID = -1;
extern int gValorPlanID = -1;
extern int gSpiderLairPlanID = -1;
extern int gTraitorPlanID = -1;
extern int gTraitorPUID = -1;
extern vector gTraitorUnitPosition = cInvalidVector;
extern int gTraitorAssignToPlanID = -1;
extern int gHesperidesTreePlanID = -1;
extern int gVortexPlanID = -1;
extern int gTartarianGatePlanID = -1;
extern int gImplodePlanID = -1;

//==============================================================================
// setupAtlanteanGodPowerPlan
//==============================================================================
void setupAtlanteanGodPowerPlan(int planID = -1, int protoPowerID = -1)
{
   aiPlanSetVariableInt(planID, cPlanGodPower, 0, protoPowerID);

   switch (protoPowerID)
   {
      case cProtoPowerDeconstruction:
      {
         gDeconstructionPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelUnit);
         xsEnableRule("deconstructionMonitor");
         break;
      }

      case cProtoPowerShockwave:
      {
         gShockwavePlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
         xsEnableRule("shockwaveMonitor");
         break;
      }

      case cProtoPowerGaiaForest:
      {
         gGaiaForestPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
         xsEnableRule("gaiaForestMonitor");
         break;
      }

      case cProtoPowerCarnivora:
      {
         gCarnivoraPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
         xsEnableRule("carnivoraMonitor");
         break;
      }

      case cProtoPowerValor:
      {
         gValorPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelUnit);
         xsEnableRule("valorMonitor");
         break;
      }

      case cProtoPowerSpiderLair:
      {
         gSpiderLairPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationDual);
         xsEnableRule("spiderLairMonitor");
         break;
      }

      case cProtoPowerTraitor:
      {
         gTraitorPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelUnit);
         xsEnableRule("traitorMonitor");
         break;
      }

      case cProtoPowerChaos:
      {
         int queryID = kbUnitQueryCreate(aiPlanGetName(planID) + " Chaos Query");
         kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
         kbUnitQuerySetUnitType(queryID, cUnitTypeMilitaryUnit);
         kbUnitQuerySetMaximumDistance(queryID, 20.0);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         // v2.1: bylo 15 - Chaos setrime na skutecne velke polni bitvy 20+ nepratel.
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryMinimumCount, 0, 20); // bylo 15
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
         
         aiPlanSetVariableBool(planID, cGodPowerPlanRequiresCombatPlan, 0, true);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelCombatPlanDistance);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocation);
         break;
      }

      case cProtoPowerHesperidesTree:
      {
         gHesperidesTreePlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelBuildingPlacement);
         xsEnableRule("hesperidesTreeMonitor");
         break;
      }

      case cProtoPowerVortex:
      {
         gVortexPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
         xsEnableRule("vortexMonitor");
         break;
      }

      case cProtoPowerTartarianGate:
      {
         gTartarianGatePlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
         xsEnableRule("tartarianGateMonitor");
         break;
      }

      case cProtoPowerImplode:
      {
         gImplodePlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
         xsEnableRule("implodeMonitor");
         break;
      }
   }
}

//==============================================================================
// deconstructionMonitor
// Try to find a Tower / Fortress to deconstruct.
//==============================================================================
rule deconstructionMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule deconstructionMonitor. ---");
   int[] plans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);

   for (int i = 0; i < plans.size(); i++)
   {
      if (aiPlanGetParentID(plans[i]) == -1) // Parent plan, no reinforcement.
      {
         for (int j = 0; j < 2; j++)
         {
            int unitType = cUnitTypeAbstractFortress;
            if (j == 1)
            {
               unitType = cUnitTypeAbstractTower;
            }
            int queryID = useSimpleUnitQuery(unitType, cPlayerRelationEnemyNotGaia, cUnitStateAlive, aiPlanGetLocation(plans[i]), 25.0);
            kbUnitQuerySetAscendingSort(queryID, true);
            kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
            int numResults = kbUnitQueryExecute(queryID);
            if (numResults < 1)
            {
               debugGodPowers(j + ": We didn't find any buildings to cast Deconstruction on for this plan: " + aiPlanGetName(plans[i]) + ".");
               continue;
            }

            debugGodPowers(j + ": We found a building to deconstruct near plan: " + aiPlanGetName(plans[i]) + ".");
            // Take closest building to cast on.
            aiPlanSetVariableInt(gDeconstructionPlanID, cGodPowerPlanTargetUnit, 0, kbUnitQueryGetResult(queryID, 0));
            aiPlanSetVariableBool(gDeconstructionPlanID, cGodPowerPlanAutoCast, 0, true);
            xsDisableRule("deconstructionMonitor");
            return;
         }
      }
   }
}

//==============================================================================
// shockwaveMonitor
// Try to find some enemy military and randomly shockwave one of them, pray it hits more.
//==============================================================================
rule shockwaveMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule shockwaveMonitor. ---");

   int[] plans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
   int[] defendPlans = aiPlanGetIDsByTypeAndState(cPlanDefend, cPlanStateAttack);
   for (int i = 0; i < defendPlans.size(); i++)
   {
      plans.add(defendPlans[i]);
   }

   for (int i = 0; i < plans.size(); i++)
   {
      if (aiPlanGetParentID(plans[i]) == -1) // Parent plan, no reinforcement.
      {
         int queryID = useSimpleUnitQuery(cUnitTypeLogicalTypeValidShockwaveTarget, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
            aiPlanGetLocation(plans[i]), 15.0);
         kbUnitQuerySetAscendingSort(queryID, true);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         kbUnitQueryExecute(queryID);
         int[] enemies = kbUnitQueryGetResults(queryID);
         if (enemies.size() < 6)
         {
            debugGodPowers("We didn't find enough enemies to cast Shockwave for this plan: " + aiPlanGetName(plans[i]) + ".");
            continue;
         }

         debugGodPowers("We found enough enemies near plan: " + aiPlanGetName(plans[i]) + " to cast Shockwave!");
         // Take closest unit to cast on.
         aiPlanSetVariableVector(gShockwavePlanID, cGodPowerPlanTargetLocation, 0, kbUnitGetPosition(enemies[0]));
         aiPlanSetVariableBool(gShockwavePlanID, cGodPowerPlanAutoCast, 0, true);
         xsDisableRule("shockwaveMonitor");
         return;
      }
   }
}

//==============================================================================
// gaiaForestMonitor
// Run a building placement to find a spot and then assign it to a wood plan if the BO is still active.
//==============================================================================
rule gaiaForestMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule gaiaForestMonitor. ---");

   static int bpID = -1;
   if (bpID == -1) // First run.
   {
      int tcBaseID = getMostDefendedTCBase();
      if (tcBaseID == -1)
      {
         debugGodPowers("We have no TC base atm, can't cast Gaia Forest for now.");
         return;
      }

      // If you change any of the logic here please also adjust the rebuy logic for this god power.
      bpID = kbBuildingPlacementCreate(aiPlanGetName(gGaiaForestPlanID) + " Gaia Forest Placement");
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeMilitaryBarracks); // Building with some size
      kbBuildingPlacementSetBaseID(bpID, tcBaseID, cBuildingPlacementOrientationPreferenceBack);
      kbBuildingPlacementSetRequiresCompletelyUnobstructed(bpID, true);
      kbBuildingPlacementSetStepSize(bpID, 3.0);
      kbBuildingPlacementStart(bpID);
      debugGodPowers("Created and started the building placement for Gaia Forest.");
      return;
   }

   int state = kbBuildingPlacementGetState(bpID);
   if (state == cBuildingPlacementPlacementStateProgress)
   {
      debugGodPowers("Building placement for Gaia Forest is still in progress, quiting.");
      return;
   }
   if (state != cBuildingPlacementPlacementStateDone)
   {
      debugGodPowers("Building placement for Gaia Forest failed, resetting everything.");
      kbBuildingPlacementDestroy(bpID);
      bpID = -1;
      return;
   }

   aiPlanSetVariableVector(gGaiaForestPlanID, cGodPowerPlanTargetLocation, 0, kbBuildingPlacementGetBestResultPosition(bpID));
   aiPlanSetVariableBool(gGaiaForestPlanID, cGodPowerPlanAutoCast, 0, true);
   kbBuildingPlacementDestroy(bpID);
   bpID = -1;
   xsDisableRule("gaiaForestMonitor");
}

//==============================================================================
// carnivoraMonitor
// Run a building placement to find a spot around the MGP, just place it then.
// Since this GP requires a building placement it's impossible to reactively use it.
// If we would run a BP during a fight the chances of it being obstructed are so large it becomes useless.
//==============================================================================
rule carnivoraMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule carnivoraMonitor. ---");

   static int bpID = -1;
   if (bpID == -1) // First run.
   {
      int tcBaseID = getRandomTownCenterBaseID();
      if (tcBaseID == -1)
      {
         debugGodPowers("Currently can't cast Carnivora because we have no TC bases left.");
         return;
      }
      vector MGP = kbBaseGetMilitaryGatherPoint(cMyID, tcBaseID);
      if (MGP == cInvalidVector)
      {
         // No MGP defined. TODO loop all TC bases...
         debugGodPowers("   Can't cast Carnivora since " + kbBaseGetNameByID(cMyID, tcBaseID) + " has no MGP defined.");
         return;
      }

      // If you change any of the logic here please also adjust the rebuy logic for this god power.
      bpID = kbBuildingPlacementCreate(aiPlanGetName(gCarnivoraPlanID) + " Carnivora Placement");
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeCarnivora);
      kbBuildingPlacementSetCenterPosition(bpID, MGP, 10.0);
      kbBuildingPlacementSetRequiresCompletelyUnobstructed(bpID, true);
      kbBuildingPlacementSetStepSize(bpID, 1.0);
      kbBuildingPlacementStart(bpID);
      debugGodPowers("Created and started the building placement for Carnivora.");
      return;
   }

   int state = kbBuildingPlacementGetState(bpID);
   if (state == cBuildingPlacementPlacementStateProgress)
   {
      debugGodPowers("Building placement for Carnivora is still in progress, quiting.");
      return;
   }
   if (state != cBuildingPlacementPlacementStateDone)
   {
      debugGodPowers("Building placement for Carnivora failed, resetting everything.");
      kbBuildingPlacementDestroy(bpID);
      bpID = -1;
      return;
   }

   aiPlanSetVariableVector(gCarnivoraPlanID, cGodPowerPlanTargetLocation, 0, kbBuildingPlacementGetBestResultPosition(bpID));
   aiPlanSetVariableBool(gCarnivoraPlanID, cGodPowerPlanAutoCast, 0, true);
   kbBuildingPlacementDestroy(bpID);
   bpID = -1;
   xsDisableRule("carnivoraMonitor");
}

//==============================================================================
// valorMonitor
// Try to find a unit in the defend plan that has a high cost to heroize.
//==============================================================================
rule valorMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule valorMonitor. ---");

   int[] units = aiPlanGetUnits(gPrimaryLandDefendPlan);
   float highestCost = 0.0;
   int bestUnitID = -1;
   for (int i = 0; i < units.size(); i++)
   {
      int unitID = units[i];
      if (kbUnitIsType(unitID, cUnitTypeHumanSoldier) == false)
      {
         continue;
      }
      int puid = kbUnitGetProtoUnitID(unitID);
      float cost = kbProtoUnitGetCostTotal(puid);
      if (cost > highestCost)
      {
         highestCost = cost;
         bestUnitID = unitID;
      }
   }

   if (bestUnitID != -1)
   {
      aiPlanSetVariableInt(gValorPlanID, cGodPowerPlanTargetUnit, 0, bestUnitID);
      aiPlanSetVariableBool(gValorPlanID, cGodPowerPlanAutoCast, 0, true);
      xsDisableRule("valorMonitor");
   }
   else
   {
      debugGodPowers("Found no unit to heroize.");
   }
}

//==============================================================================
// spiderLairMonitor
//==============================================================================
rule spiderLairMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule spiderLairMonitor. ---");

   int tcBaseID = getRandomTownCenterBaseID();
   if (tcBaseID == -1)
   {
      debugGodPowers("Currently can't cast Spider Lair because we have no TC bases left.");
      return;
   }

   // Just cast it around our MGP, at least we know that's unobstructed.
   vector MGP = kbBaseGetMilitaryGatherPoint(cMyID, tcBaseID);
   if (MGP == cInvalidVector)
   {
      debugGodPowers("Can't cast Spider Lair because base " + kbBaseGetNameByID(cMyID, tcBaseID) + " has no valid MGP defined.");
      return;
   }

   // TODO validate these position remain on the map / same area group.

   // Try to not overlap with recasts.
   float randomX = xsRandFloat(0, 7.5);
   float randomZ = xsRandFloat(0, 7.5);
   if (xsRandBool() == true)
   {
      MGP.x += randomX;
   }
   else
   {
      MGP.x -= randomX;
   }
   if (xsRandBool() == true)
   {
      MGP.z += randomZ;
   }
   else
   {
      MGP.z -= randomZ;
   }
   vector direction = xsVectorNormalize(MGP - kbGetMapCenter());
   vector secondPosition = MGP + (direction * 5);
   aiPlanSetVariableVector(gSpiderLairPlanID, cGodPowerPlanTargetLocation, 0, MGP);
   aiPlanSetVariableVector(gSpiderLairPlanID, cGodPowerPlanTargetLocation, 1, secondPosition);
   
   aiPlanSetVariableBool(gSpiderLairPlanID, cGodPowerPlanAutoCast, 0, true);
   xsDisableRule("spiderLairMonitor");
}

//==============================================================================
// traitorMonitor
// Traitor an enemy units close to one of our combat plans that has some high max HP.
//==============================================================================
rule traitorMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule traitorMonitor. ---");

   int[] plans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
   int[] defendPlans = aiPlanGetIDsByTypeAndState(cPlanDefend, cPlanStateAttack);
   for (int i = 0; i < defendPlans.size(); i++)
   {
      plans.add(defendPlans[i]);
   }

   float highestHP = 0.0;
   int bestUnitID = -1;
   for (int i = 0; i < plans.size(); i++)
   {
      if (aiPlanGetParentID(plans[i]) == -1) // Parent plan, no reinforcement.
      {
         int queryID = useSimpleUnitQuery(cUnitTypeLogicalTypeValidTraitorTarget, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
            aiPlanGetLocation(plans[i]), 25.0);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         kbUnitQueryExecute(queryID);
         int[] enemies = kbUnitQueryGetResults(queryID);
         for (int j = 0; j < enemies.size(); j++)
         {
            float maxHP = kbUnitGetStatFloat(enemies[j], cUnitStatMaxHP);
            if (maxHP > 300.0 && maxHP > highestHP)
            {
               highestHP = maxHP;
               bestUnitID = enemies[j];
               gTraitorAssignToPlanID = plans[i];
            }
         }
      }
   }

   if (bestUnitID != -1)
   {
      gTraitorUnitPosition = kbUnitGetPosition(bestUnitID);
      gTraitorPUID = kbUnitGetProtoUnitID(bestUnitID);
      debugGodPowers("Found a unit to cast Traitor on: " + kbProtoUnitGetName(kbUnitGetProtoUnitID(bestUnitID)) + ", ID: " +
         bestUnitID + ".");
      aiPlanSetVariableInt(gTraitorPlanID, cGodPowerPlanTargetUnit, 0, bestUnitID);
      aiPlanSetVariableBool(gTraitorPlanID, cGodPowerPlanAutoCast, 0, true);
      xsDisableRule("traitorMonitor");
   }
}

//==============================================================================
// addTraitorToPlanMonitor
// Traitor removes the unit completely and then instantiates a new one, we can't save the ID.
//==============================================================================
rule addTraitorToPlanMonitor
inactive
minInterval 1
{
   // Search for all units matching the puid and add them to the plan, assume we don't accidentally get a unit we weren't meant to.
   int queryID = useSimpleUnitQuery(gTraitorPUID, cMyID, cUnitStateAlive, gTraitorUnitPosition, 5.0);
   int numResults = kbUnitQueryExecute(queryID);
   int[] units = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < numResults; i++)
   {
      if (kbUnitGetPlanID(units[i]) != gTraitorAssignToPlanID)
      {
         aiPlanAddUnit(gTraitorAssignToPlanID, units[i]);
      }
   }
   xsDisableRule("addTraitorToPlanMonitor");
}

//==============================================================================
// hesperidesTreeMonitor
//==============================================================================
rule hesperidesTreeMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule hesperidesTreeMonitor. ---");

   int baseID = getMostDefendedTCBase();
   if (baseID == -1)
   {
      debugGodPowers("Can't cast Hesperides Tree atm because we have no Town Center base.");
      return;
   }
   vector basePosition = kbBaseGetLocation(cMyID, baseID);
   if (getUnitCountByLocation(cUnitTypeMilitaryUnit, cPlayerRelationEnemyNotGaia, cUnitStateAlive, basePosition,
         kbBaseGetDistance(cMyID, baseID)) > 0)
   {
      debugGodPowers("Can't cast Hesperides Tree atm because we see enemies in base " + kbBaseGetNameByID(cMyID, baseID) + ".");
      return;
   }

   int bpID = kbBuildingPlacementCreate(aiPlanGetName(gHesperidesTreePlanID) + " Hesperides Tree Placement");
   kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeHesperidesTree);
   kbBuildingPlacementSetBaseID(bpID, baseID);
   kbBuildingPlacementSetLOSType(bpID, cBuildingPlacementFullVisible);
   kbBuildingPlacementSetRequiresCompletelyUnobstructed(bpID, true);
   // This guarantees we build it at the back. We don't want to have no vision on a good spot at the back and then just put it forward.
   kbBuildingPlacementSetMinimumValue(bpID, 1000);
   kbBuildingPlacementSetInnerRingRange(bpID, kbBaseGetDistance(cMyID, baseID)); // Remove inner ring so we always go to the back.
   kbBuildingPlacementAddBaseInfluence(bpID, baseID, cBuildingPlacementOrientationPreferenceBack, 10.0, cFalloffLinear);
   aiPlanSetVariableInt(gHesperidesTreePlanID, cGodPowerPlanBPID, 0, bpID);
   aiPlanSetVariableBool(gHesperidesTreePlanID, cGodPowerPlanAutoCast, 0, true);
   xsDisableRule("hesperidesTreeMonitor");
}

//==============================================================================
// vortexMonitor
// We vortex towards our attack if we're in an even battle and we can turn the tide.
//==============================================================================
rule vortexMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule vortexMonitor. ---");

   // v1.8: defenzivni Vortex - pri panice teleportuj utocici armadu zpet k obrane
   if (gDefenseReflexPanic == true)
   {
      vector panicGatherPt = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);
      if (panicGatherPt != cInvalidVector)
      {
         int[] panicAtk = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
         int panicBestPlan = -1;
         int panicBestUnits = 0;
         for (int pp = 0; pp < panicAtk.size(); pp++)
         {
            if (aiPlanGetParentID(panicAtk[pp]) != -1)
               continue;
            int panicU = aiPlanGetNumberUnits(panicAtk[pp], -1, false);
            if (panicU > panicBestUnits)
            {
               panicBestUnits = panicU;
               panicBestPlan = panicAtk[pp];
            }
         }
         int panicMinUnits = selectByDifficulty(3, 4, 5, 6, 8, 8);
         if (panicBestPlan != -1 && panicBestUnits >= panicMinUnits)
         {
            debugGodPowers("Panic defense! Vortexing attack force back to defend.");
            aiPlanSetVariableVector(gVortexPlanID, cGodPowerPlanTargetLocation, 0, panicGatherPt);
            aiPlanSetVariableBool(gVortexPlanID, cGodPowerPlanAutoCast, 0, true);
            xsDisableRule("vortexMonitor");
            return;
         }
      }
   }

   if (aiPlanGetState(gPrimaryLandDefendPlan) == cPlanStateAttack)
   {
      debugGodPowers("Primary defend plan is under attack, can't Vortex away its units.");
      return;
   }

   int numUnitsInDefendPlan = aiPlanGetNumberUnits(gPrimaryLandDefendPlan);
   debugGodPowers("We found " + numUnitsInDefendPlan + " units in our defend plan to potentially Vortex.");
   if ((cDifficultyCurrent <= cDifficultyModerate && numUnitsInDefendPlan < 3) ||
       (cDifficultyCurrent >= cDifficultyHard && numUnitsInDefendPlan < 5))
   {
      debugGodPowers("Too few units in our defend plan for casting Vortex.");
      return;
   }
   vector gatherPoint = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);

   int[] plans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
   int numPlans = plans.size();
   if (numPlans <= 0)
   {
      debugGodPowers("Found 0 attack plans in attack state to analyze.");
      return;
   }
   for (int i = 0; i < plans.size(); i++)
   {
      if (aiPlanGetParentID(plans[i]) != -1)
      {
         continue; // Skip reinforcement plans.
      }

      vector planPosition = aiPlanGetLocation(plans[i]);
      if (xsVectorDistanceXZ(planPosition, gatherPoint) < 75.0)
      {
         debugGodPowers("Our defend plan's position is too close to our attack plan's position, not worth to Vortex.");
         continue;
      }
      int numAttackingTroops = aiPlanGetNumberUnits(plans[i], -1, false);
      debugGodPowers("We found " + numAttackingTroops + " units belonging to our: " + aiPlanGetName(plans[i]));
      if ((cDifficultyCurrent <= cDifficultyModerate && numAttackingTroops < 3) ||
          (cDifficultyCurrent >= cDifficultyHard && numAttackingTroops < 5))
      {
         debugGodPowers("Too few attacking units to casting Vortex.");
         continue;
      }

      int numEnemies = getUnitCountByLocation(cUnitTypeMilitaryUnit, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
         planPosition, aiPlanGetVariableFloat(plans[i], cAttackPlanAttackModeEngageRange, 0), cUnitQueryVisibleStateVisible);
      debugGodPowers("We found " + numEnemies + " units belonging to the enemy.");
      // v2.7 IMP10: bylo > 0.8 → shodna logika jako ShiftingSands. Castuj i kdyz jsme mirne presilovani (>= 0.6).
      if (numAttackingTroops > (numEnemies * 0.6) && numAttackingTroops < (numEnemies * 1.2))
      {
         debugGodPowers("Casting Vortex to reinforce: " + aiPlanGetName(plans[i]));
         aiPlanSetVariableVector(gVortexPlanID, cGodPowerPlanTargetLocation, 0, planPosition);
         aiPlanSetVariableBool(gVortexPlanID, cGodPowerPlanAutoCast, 0, true);
         
         // Add all units on the map that we're going to shift to this attack plan already.
         int queryID = useSimpleUnitQuery(cUnitTypeMilitaryUnit);
         int numResults = kbUnitQueryExecute(queryID);
         int[] units = kbUnitQueryGetResults(queryID);
         for (int j = 0; j < numResults; j++)
         {
            // All military but not oracles get shifted.
            if (kbUnitIsType(units[j], cUnitTypeAbstractOracle) == false)
            {
               aiPlanAddUnit(plans[i], units[j]);
            }
         }
         xsDisableRule("vortexMonitor");
         return;
      }
      else
      {
         debugGodPowers("Our units versus enemy units isn't in the right range to use Vortex.");
      }
   }
}

//==============================================================================
// tartarianGateMonitor
// If we see a good building to destroy with our Tartarian Gate close to an attack we cast it.
//==============================================================================
rule tartarianGateMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule tartarianGateMonitor. ---");

   int[] plans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
   int numPlans = plans.size();
   if (numPlans <= 0)
   {
      debugGodPowers("Found 0 attack plans in attack state to analyze.");
      return;
   }
   for (int i = 0; i < plans.size(); i++)
   {
      if (aiPlanGetParentID(plans[i]) == -1) // Parent plan, no reinforcement.
      {
         int numAttackingTroops = aiPlanGetNumberUnits(plans[i], -1, false);
         debugGodPowers("We found " + numAttackingTroops + " units belonging to our: " + aiPlanGetName(plans[i]));
         if (numAttackingTroops > 5)
         {
            debugGodPowers("Too many attacking units to casting Tartarian Gate.");
            continue;
         }
         vector targetPosition = cInvalidVector;
         vector planPosition = aiPlanGetLocation(plans[i]);
         int queryID = useSimpleUnitQuery(cUnitTypeAbstractFortress, cPlayerRelationEnemyNotGaia, cUnitStateABQ, planPosition, 25.0);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         kbUnitQuerySetAscendingSort(queryID, true);
         if (kbUnitQueryExecute(queryID) >= 1)
         {
            debugGodPowers("Found building " + kbUnitQueryGetResult(queryID, 0) + " to cast Tartarian Gate on.");
            targetPosition = kbUnitGetPosition(kbUnitQueryGetResult(queryID, 0));
         }
         if (targetPosition == cInvalidVector)
         {
            queryID = useSimpleUnitQuery(cUnitTypeAbstractTower, cPlayerRelationEnemyNotGaia, cUnitStateABQ, planPosition, 25.0);
            kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
            kbUnitQuerySetAscendingSort(queryID, true);
            if (kbUnitQueryExecute(queryID) >= 1)
            {
               debugGodPowers("Found building " + kbUnitQueryGetResult(queryID, 0) + " to cast Tartarian Gate on.");
               targetPosition = kbUnitGetPosition(kbUnitQueryGetResult(queryID, 0));
            }
         }
         
         if (targetPosition != cInvalidVector)
         {
            aiPlanSetVariableVector(gTartarianGatePlanID, cGodPowerPlanTargetLocation, 0, targetPosition);
            aiPlanSetVariableBool(gTartarianGatePlanID, cGodPowerPlanAutoCast, 0, true);
            xsDisableRule("tartarianGateMonitor");
            return;
         }
      }
   }
}

//==============================================================================
// implodeMonitor
//==============================================================================
rule implodeMonitor
inactive
minInterval 5
{
   debugGodPowers("--- Running Rule implodeMonitor. ---");
   static int reservePlanID = -1;
   if (aiPlanGetIsIDValid(reservePlanID) == false)
   {
      reservePlanID = aiPlanCreate("Implode reserve plan", cPlanReserve, -1, gGodpowersCategoryID);
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
         // v1.8: cekej az bude u neprit zakladny alespon 5 vojaku - Implode je ucinne jen na skupinu
         int implodeTargetPlayer = aiGetMostHatedPlayerID();
         bool implodeEnoughEnemies = false;
         if (implodeTargetPlayer > 0 && kbBaseGetNumber(implodeTargetPlayer) > 0)
         {
            int implodeEnemyBaseID = kbBaseGetIDByIndex(implodeTargetPlayer, 0);
            vector implodeEnemyBase = kbBaseGetLocation(implodeTargetPlayer, implodeEnemyBaseID);
            int implodeNearby = getUnitCountByLocation(cUnitTypeMilitaryUnit, cPlayerRelationEnemyNotGaia,
               cUnitStateAlive, implodeEnemyBase, 50.0, cUnitQueryVisibleStateVisible);
            if (implodeNearby >= 5)
               implodeEnoughEnemies = true;
         }
         if (implodeEnoughEnemies == false)
         {
            debugGodPowers("Implode: waiting for 5+ enemies near target base.");
            break;
         }
         bool foundTC = godPowerFindTCInRangeAndScout(gImplodePlanID, scoutID, targetID, castGodPower);
         // TC can already be in range, then we're already done!
         if (castGodPower == true)
         {
            xsSetRuleMinInterval("implodeMonitor", 5);
            currentState = cGPStateCleanup;
            return;
         }
         if (foundTC == true)
         {
            currentState = cGPStatePathingToLocation;
            // Need to keep checking godPowerExploreTargetPosition often.
            xsSetRuleMinInterval("implodeMonitor", 1);
         }
         break;
      }

      case cGPStatePathingToLocation:
      {
         bool pathingToLocation = godPowerExploreTargetPosition(gImplodePlanID, scoutID, targetID, iterator, reservePlanID, castGodPower);
         if (castGodPower == true)
         {
            xsSetRuleMinInterval("implodeMonitor", 5);
            currentState = cGPStateCleanup;
            return;
         }
         if (pathingToLocation == false)
         {
            iterator = 0;
            currentState = cGPStateBegin;
            xsSetRuleMinInterval("implodeMonitor", 5);
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
         xsDisableRule("implodeMonitor");
         break;
      }
   }
}
