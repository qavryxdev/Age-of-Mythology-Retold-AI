class MigrationStrategyData
{
   int mBuildPlanID = -1;
   int mInterruptedStrategyID = -1;
};
MigrationStrategyData internalMigrateData;
void addMigrateMainBaseStrategy()
{
   // Init Wonder Age strategy.
   gMigrateMainBase.mData.mID = cStrategyMigrateMainBase;

   gMigrateMainBase.mInitFunc = [](ref StrategyData data) -> bool
   {
      xsDisableRule("checkForBaseMigration");
      boSystem.done = true;
      return true;
   };

   gMigrateMainBase.mUpdateFunc = [](ref StrategyData data) -> bool 
   {
      if (aiPlanGetIsIDValid(internalMigrateData.mBuildPlanID))
      {
         return true;
      }
      debugMigrationStrategy("Migration build plan gone");
      return false;
   };
   gMigrateMainBase.mNextFunc = [](ref StrategyData data) -> int 
   {
      xsEnableRule("checkForBaseMigration");
      debugMigrationStrategy("Continuing interrupted strategy: "+  internalMigrateData.mInterruptedStrategyID);
      return internalMigrateData.mInterruptedStrategyID;
   };
   gMigrateMainBase.mName = "Migrate Main Base";
}

rule checkForBaseMigration
inactive
group defaultClassicalRules
minInterval 5
{
   if (checkStrategyFlag(cStrategyFlagAutomaticMigration) == false)
   {
      if (aiPlanGetIsIDValid(internalMigrateData.mBuildPlanID) == true)
      {
         aiPlanDestroy(internalMigrateData.mBuildPlanID);
      }
      return;
   }
   if (aiPlanGetIsIDValid(internalMigrateData.mBuildPlanID) == true)
   {
      return;
   }
   if (boSystem.done == false)
   {
      return;
   }
   
   // A couple of scenarios when we want to consider this:
   // 1. Our mainbase got destroyed and we do not have the army to fight it
   // 2. Our mainbase is under attack and we are hard out matched so time to flee
   // 3. Our mainbase is on an island and we ran out of resources
   int mainBaseID = kbBaseGetMainID(cMyID);
   // Todo handle the case where we do not have a base
   vector currentLocation = kbBaseGetLocation(cMyID, mainBaseID);
   // 1.
   //if (not implemented)

   // 3. Our mainbase is on an island and we ran out of resources
   if (gMapInfo.mIsIslandMap == true)
   {
      int areaGroupID = kbAreaGroupGetIDByPosition(currentLocation);
      float[] resources = kbGetAmountResourcesByAreaGroup(areaGroupID);
      // Ignoring favor but if any resource doesn't meet the threshold 
      // we try and find a new mainbase
      for (int iResource = 0; iResource < cResourceFavor; iResource++)
      {
         const float resourceThreshold = 500.0;
         if (resources[iResource] < resourceThreshold)
         {
            debugMigrationStrategy("Trying to migrate");
            // Find the area group with the most amount of resources
            int numAreaGroups = kbAreaGroupGetNumber();
            float maxResources = 0;
            int bestIsland = -1;
            for (int iGroup = 0; iGroup < numAreaGroups; iGroup++)
            {
               if (iGroup == areaGroupID)
               {
                  continue;
               }
               float[] otherIslandResources = kbGetAmountResourcesByAreaGroup(iGroup);
               bool valid = true;
               float numResources = 0.0;
               for (int iIslandResource = 0; iIslandResource < cResourceFavor; iIslandResource++)
               {
                  if (otherIslandResources[iIslandResource] < resourceThreshold)
                  {
                     valid = false;
                     break;
                  }
                  numResources += otherIslandResources[iIslandResource];
               }
               if (valid == false)
               {
                  continue;
               }
               if (numResources > maxResources)
               {
                  maxResources = numResources;
                  bestIsland = iGroup;
               }
            }
            if (bestIsland != -1)
            {
               debugMigrationStrategy("Trying to migrate to area group: " + bestIsland + " with: " + maxResources +" resources.");
               bool canBuildSettlement = calculateNumPossibleToBuild(cUnitTypeTownCenter) > 0;
               if (canBuildSettlement == true)
               {
                  int numBuilders = 3;
                  // Find an unclaimed settlement on the area group
                  int queryID = useSimpleUnitQuery(cUnitTypeSettlement, 0, cUnitStateAlive, currentLocation);
                  int numResults = kbUnitQueryExecute(queryID);
                  int[] results = kbUnitQueryGetResults(queryID);
                  debugMigrationStrategy("Found "+numResults+" settlements.");
                  for(int iResult = 0; iResult < numResults; iResult++)
                  {
                     int settlementUnitID = results[iResult];
                     vector position = kbUnitGetPosition(settlementUnitID);
                     int settlementAreaGroupID = kbAreaGroupGetIDByPosition(position);
                     if ( settlementAreaGroupID == bestIsland)
                     {
                        debugMigrationStrategy("Found settlement: " + settlementUnitID + " at position: " + position);

                        int planID = aiPlanCreate("Migration Build Plan for " + kbProtoUnitGetName(cUnitTypeTownCenter),
                           cPlanBuild, -1, gMigrationCategoryID);
                        if (aiPlanGetIsIDValid(planID) == true) 
                        {
                           // Building Placement.
                           int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
                           kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeTownCenter);
                           kbBuildingPlacementSetBufferSpace(bpID, 2.0);
                           // Just find closest one.
                           kbBuildingPlacementSetSocketID(bpID,settlementUnitID);
                           addBuilderTypesToPlan(planID, cUnitTypeSettlement, numBuilders);
                           aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypeTownCenter);
                           aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
                           aiPlanSetPriority(planID, 100);
                           debugMigrationStrategy(aiPlanGetName(planID) + ", migration picked socket ID: " + settlementUnitID);
                           aiPlanSetEventHandler(planID, cPlanEventStateChange,"migrationBuildHandler");
                           internalMigrateData.mBuildPlanID = planID;
                           break;
                        }
                     }
                  }
               }
               if (aiPlanGetIsIDValid(internalMigrateData.mBuildPlanID))
               {
                  // Time to migrate to this island
                  internalMigrateData.mInterruptedStrategyID = gStrategyManager.mCurrentID;
                  gStrategyManager.setInterruptHandler([](ref StrategyData data) -> int { return cStrategyMigrateMainBase; });
               }
               break;
            }
            else
            {
               debugMigrationStrategy("Could not find another island to migrate to");
            }
            break;
         }
      }
   }
}

void migrationBuildHandler(int planID = -1)
{
   if (aiPlanGetState(planID) == cPlanStateDone)
   {
      int newBaseUnitID = aiPlanGetVariableInt(planID, cBuildPlanFoundationID, 0);
      debugMigrationStrategy("Migration completed with new base unit: " + newBaseUnitID);
      aiSwitchMainBase(kbUnitGetBaseID(newBaseUnitID));
   }
}