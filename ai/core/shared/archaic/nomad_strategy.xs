//==============================================================================
// initNomadStrategy
//==============================================================================
void initNomadStrategy()
{
   gNomadStrategy.mData.mID = cStrategyNomad;

   gNomadStrategy.mInitFunc = [](ref StrategyData data) -> bool
   {
      data.mFlags = 0;
      data.mFlags2 = 0;
      xsEnableRule("nomadScoutingStartup");
      return (true);
   };

   gNomadStrategy.mUpdateFunc = [](ref StrategyData data) -> bool { return kbUnitCount(cUnitTypeTownCenter, cMyID) == 0; };
   gNomadStrategy.mName = "Nomad";
}

rule nomadScoutingStartup
inactive
minInterval 1
{
   int queryID = useSimpleUnitQuery(cUnitTypeUnit, cMyID, cUnitStateAlive);
   int numUnits = kbUnitQueryExecute(queryID);
   int[] units = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < numUnits; i++)
   {
      // We can hit this rule multiple times, mostly if our Socket is stolen, so don't overlap plans.
      if (aiPlanGetIsIDValid(kbUnitGetPlanID(units[i])) == true)
      {
         continue;
      }
      int planID = aiPlanCreate("Explore unit ID: " + units[i], cPlanExplore, -1, gExplorationCategoryID);
      aiPlanAddUnitType(planID, kbUnitGetProtoUnitID(units[i]), 1, 1, 1, false);
      aiPlanAddUnit(planID, units[i], false);
   }
   aiEcho("Created Nomad scouting plans.");

   // Advance the chain.
   xsEnableRule("nomadWatchForSettlements");
   xsDisableRule("nomadScoutingStartup");
}

rule nomadWatchForSettlements
inactive
minInterval 3
{
   int settlementID = getUnit(cUnitTypeSettlement, 0);
   if (kbUnitGetIsIDValid(settlementID) == true)
   {
      int planID = aiPlanCreate("Build Plan for 1 Town Center", cPlanBuild, -1, gBuildingsCategoryID);
      // Building Placement.
      int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
      kbBuildingPlacementSetSocketID(bpID, settlementID);
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeTownCenter);
      // Plan.
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypeTownCenter);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetPriority(planID, 100);
      aiPlanSetFlag(planID, cPlanFlagAllowUnderAttackResponse, false);

      // Add builders.
      int queryID = useSimpleUnitQuery(cUnitTypeUnit, cMyID, cUnitStateAlive);
      int numUnits = kbUnitQueryExecute(queryID);
      int[] units = kbUnitQueryGetResults(queryID);
      for (int i = 0; i < numUnits; i++)
      {
         if (kbProtoUnitCanTrain(kbUnitGetProtoUnitID(units[i]), cUnitTypeTownCenter) == true)
         {
            if (aiPlanGetIsIDValid(kbUnitGetPlanID(units[i])) == true)
            {
               // Destroy the scout plan.
               aiPlanDestroy(kbUnitGetPlanID(units[i]));
            }

            aiPlanAddUnitType(planID, kbUnitGetProtoUnitID(units[i]), 1, 1, 1, true);
            aiPlanAddUnit(planID, units[i], false);
            aiEcho("Adding " + kbProtoUnitGetName(kbUnitGetProtoUnitID(units[i])) + " " + units[i] + " to the Town Center build plan.");
         }
      }

      aiPlanSetEventHandler(planID, cPlanEventStateChange, "nomadTCBuildPlanHandler");

      debugBuildings("Created a plan to create a new Town Center: " + aiPlanGetName(planID) + ".");
      xsDisableRule("nomadWatchForSettlements");
   }
   else
   {
      aiEcho("no TC found.");
   }
}

void nomadTCBuildPlanHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateFailed)
   {
      aiEcho("Nomad TC build plan failed, restarting the searching progress.");
      xsEnableRule("nomadScoutingStartup");
      return;
   }
   if (state == cPlanStateDone)
   {
      analyseNavalPositions(kbAreaGetIDByPosition(kbUnitGetPosition(getUnit(cUnitTypeTownCenter))), cInvalidVector, true);
   }
}