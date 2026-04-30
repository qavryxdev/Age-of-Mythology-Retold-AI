void scenarioAIStartInactive()
{
   aiEcho("Delaying startup for this AI!");
   gStartInactive = true;
}

void scenarioAIRemoveInactive()
{
   aiEcho("Activating this AI!");
   gStartInactive = false;
}

void scenarioDisableAI()
{
   aiEcho("Triggers set this AI to inactive.");
   gInactiveAI = true;
}

int scenarioCreateAttackPlan(
   int armyID = -1,
   string planName = "",
   int playerToAttack = 1,
   vector location = cOriginVector,
   float engageRange = 50.0,
   int evaluationFrequency = 5000,
   int pri = 50
)
{
   int numberUnits = kbArmyGetNumberUnits(armyID);
   if (numberUnits < 0)
   {
      return (-1);
   }

   int planID = aiPlanCreate(planName, cPlanAttack, -1, gMilitaryAttackingCategoryID);
   vector gatherPoint = kbUnitGetPosition(kbArmyGetUnitID(armyID, 0));

   aiPlanSetFlag(planID, cPlanFlagNoMoreUnits, true);

   for (int i = 0; i < numberUnits; i++)
   {
      int unitID = kbArmyGetUnitID(armyID, i);
      int puid = kbUnitGetProtoUnitID(unitID);
      aiPlanAddUnitType(planID, puid, 1, 1, 1, true);
      aiPlanAddUnit(planID, unitID);
   }

   aiPlanSetVariableInt(planID, cAttackPlanTargetMode, 0, cAttackPlanTargetModePoint);
   aiPlanSetVariableInt(planID, cAttackPlanTargetPlayerID, 0, playerToAttack);
   aiPlanSetVariableVector(planID, cAttackPlanTargetPoint, 0, location);
   aiPlanSetVariableVector(planID, cAttackPlanGatherPoint, 0, gatherPoint);
   aiPlanSetVariableFloat(planID, cAttackPlanGatherDistance, 0, 40.0);
   aiPlanSetVariableInt(planID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternBest);
   aiPlanSetVariableFloat(planID, cAttackPlanAttackModeEngageRange, 0, engageRange);
   aiPlanSetVariableInt(planID, cAttackPlanMovementIntervalTime, 0, evaluationFrequency);
   setDefaultAttackPlanTargetUnitTypes(planID);
   // Don't reduce this attack's size while underway.
   aiPlanSetFlag(planID, cPlanFlagCantBeStolenFrom, true);
   aiPlanSetPriority(planID, pri);

   return (planID);
}

int scenarioCreateDefendPlan(
   int armyID = -1,
   string planName = "",
   vector location = cOriginVector,
   float engageRange = 50.0,
   int evaluationFrequency = 5000,
   float gatherDistance = 25.0,
   int pri = 50
)
{
   int numberUnits = kbArmyGetNumberUnits(armyID);
   if (numberUnits < 0)
   {
      return (-1);
   }

   int planID = aiPlanCreate(planName, cPlanDefend, -1, gMilitaryDefendingCategoryID);
   vector gatherPoint = kbUnitGetPosition(kbArmyGetUnitID(armyID, 0));

   aiPlanSetFlag(planID, cPlanFlagNoMoreUnits, true);

   for (int i = 0; i < numberUnits; i++)
   {
      int unitID = kbArmyGetUnitID(armyID, i);
      int puid = kbUnitGetProtoUnitID(unitID);
      aiPlanAddUnitType(planID, puid, 1, 1, 1, true);
      aiPlanAddUnit(planID, unitID);
   }

   aiPlanSetVariableInt(planID, cDefendPlanTargetMode, 0, cDefendPlanTargetModePoint);
   aiPlanSetVariableInt(planID, cDefendPlanTargetPlayerID, 0, cMyID);
   aiPlanSetVariableVector(planID, cDefendPlanTargetPoint, 0, location);
   aiPlanSetVariableVector(planID, cDefendPlanGatherPoint, 0, gatherPoint);
   aiPlanSetVariableFloat(planID, cDefendPlanGatherDistance, 0, gatherDistance);
   aiPlanSetVariableFloat(planID, cDefendPlanEngageRange, 0, engageRange);
   aiPlanSetVariableInt(planID, cDefendPlanMovementIntervalTime, 0, evaluationFrequency);
   setDefaultDefendPlanTargetUnitTypes(planID);
   aiPlanSetPriority(planID, pri);

   return (planID);
}