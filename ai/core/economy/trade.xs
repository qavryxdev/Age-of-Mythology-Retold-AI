//==============================================================================
/* trade.xs

   This file is intended for everything related to trading, including scouting market areas.

*/
//==============================================================================

class TradeInformation
{
   // Created once.
   int mTradePlanID = -1;
   
   // Maintained each run of the tradeMonitor by manageTCArrays().
   int[] mTownCenterIDs = default;
   int[] mAlliedTownCenterIDs = default;
   int[] mAreaPaths = default;
   int[] mAlliedAreaPaths = default;
   int[] mBannedPathIDs = default;
   int[] mBannedPathIDStartTime = default;

   // Progress tracking.
   int mCurrentTownCenterID = -1;
   int mCurrentPathID = -1;
   int mCurrentMarketID = -1;
   int mBuildMarketAreaID = -1;
   bool mCreatedFirstBuildPlan = false;
   int mStartTimeBuildPlan = -1;
   int mBuildPlanID = -1;
   bool mFirstBuildPlanExecuted = false; // This is per area that we analyze, not only for the first ever build plan.
   bool mHaveFunctionalTradeRoute = false;
   int mStartTimeFunctionalTradeRoute = -1;

   void resetProgressData()
   {
      mCurrentTownCenterID = -1;
      mCurrentPathID = -1;
      mCurrentMarketID = -1;
      mBuildMarketAreaID = -1;
      mCreatedFirstBuildPlan = false;
      mStartTimeBuildPlan = -1;
      if (aiPlanGetIsIDValid(mBuildPlanID) == true)
      {
         aiPlanDestroy(mBuildPlanID);
      }
      mBuildPlanID = -1;
      mFirstBuildPlanExecuted = false;
      mHaveFunctionalTradeRoute = false;
      mStartTimeFunctionalTradeRoute = -1;
      debugTrade("Resetting all trade progress data to perform new analysis next time.");
   }

   // This actually makes the plans invalid, and stops them from doing anything new.
   void resetTradingData()
   {
      aiPlanSetVariableInt(mTradePlanID, cTradePlanMarketID, 0, -1);
      aiPlanSetVariableInt(mTradePlanID, cTradePlanTargetUnitID, 0, -1);
      aiPlanSetVariableInt(gCaravanMaintainPlan, cTrainPlanBuildingID, 0, -1);
      debugTrade("Resetting all trading data, trade + caravan train plans will go idle now.");
   }

   void addBannedPathID(int bannedPathID = -1)
   {
      mBannedPathIDs.add(bannedPathID);
      mBannedPathIDStartTime.add(xsGetTime());
      debugTrade("Adding pathID: " + bannedPathID + " to our banned list for 2 minutes.");
   }

   void clearArrays()
   {
      mTownCenterIDs.clear();
      mAlliedTownCenterIDs.clear();
      for (int i = 0; i < mAreaPaths.size(); i++)
      {
         kbPathDestroy(mAreaPaths[i]);
      }
      mAreaPaths.clear();
      mAlliedAreaPaths.clear();
      for (int i = 0; i < mAlliedAreaPaths.size(); i++)
      {
         kbPathDestroy(mAlliedAreaPaths[i]);
      }
      mBannedPathIDs.clear();
      mBannedPathIDStartTime.clear();
   }

   void marketCompleted(int newMarketID = -1, bool usingExistingMarket = false)
   {
      mCurrentMarketID = newMarketID;
      aiPlanSetVariableInt(mTradePlanID, cTradePlanMarketID, 0, newMarketID);
      aiPlanSetVariableInt(mTradePlanID, cTradePlanTargetUnitID, 0, mCurrentTownCenterID);
      aiPlanSetVariableInt(gCaravanMaintainPlan, cTrainPlanBuildingID, 0, newMarketID);

      // We need to make sure all Caravans will obey the new IDs, as such idle them so they're retasked properly.
      aiTaskStopUnits(aiPlanGetUnits(mTradePlanID));
      
      mCreatedFirstBuildPlan = true;
      mStartTimeBuildPlan = -1;
      mBuildPlanID = -1;
      mFirstBuildPlanExecuted = true;
      mHaveFunctionalTradeRoute = true;
      mStartTimeFunctionalTradeRoute = xsGetTime();
      
      if (usingExistingMarket == false)
      {
         debugTrade("Built our Market ID: " + newMarketID + ", in areaID: " + kbAreaGetIDByPosition(kbUnitGetPosition(newMarketID)) + ".");
      }
      else
      {
         debugTrade("Using existing Market ID: " + newMarketID + ", in areaID: " + kbAreaGetIDByPosition(kbUnitGetPosition(newMarketID)) + ".");
      }
      debugTrade("We will now keep an eye on this trade route to make sure it remains functional.");
   }
};
extern TradeInformation tradeInformation;

//==============================================================================
// tradePlanEventPathingMonitor
//==============================================================================
void tradePlanEventPathingMonitor(int planID = -1)
{
   // v1.3 fix: re-enabled pathing recovery. When a Caravan gets stuck we reset progress
   // so the tradeMonitor picks a new route on the next run. The banned-path list in
   // manageTCArrays already prevents us from immediately retrying the same bad route.
   debugTrade("We have encountered a pathing issue with one of our Caravans, resetting trade route.");
   tradeInformation.resetProgressData();
   tradeInformation.resetTradingData();
}

//==============================================================================
// marketBPEventHandler
//==============================================================================
void marketBPEventHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   switch (state)
   {
      case cPlanStateFailed:
      {
         int failureCause = aiPlanGetVariableInt(planID, cBuildPlanFailureCause, 0);
         if (failureCause == cBuildPlanFailureCauseFailedBP)
         {
            if (kbAreaGetPercentExplored(tradeInformation.mBuildMarketAreaID) > 0.50)
            {
               debugTrade("Our Market building placement failed because we couldn't find a valid spot in our designated areaID. " + 
                  "We have already see > 50 percent of this area though, so assume it's completely blocked off.");
            }
            else
            {
               // This is our only "success", all the others perform the resetting steps below.
               debugTrade("Our Market building placement failed because we couldn't find a valid spot in our designated areaID. " + 
                  "We have not yet scouted this area enough, going to do that next run.");
               tradeInformation.mFirstBuildPlanExecuted = true;
               return;
            }
         }
         else if (failureCause == cBuildPlanFailureCauseCantPath)
         {
            debugTrade("Our Market building placement failed because we couldn't path to our foundation.");
         }
         else if (failureCause == cBuildPlanFailureCauseDidNotBuildFoundation)
         {
            debugTrade("Our Market building placement failed because our foundation got destroyed (or was obstructed so we couldn't place).");
         }
         else
         {
            debugTrade("marketBPEventHandler - we failed but not with any handled failure type " + failureCause +
               ", resetting all trade information.");
         }
         tradeInformation.addBannedPathID(tradeInformation.mCurrentPathID);
         tradeInformation.resetProgressData();
         break;
      }
      case cPlanStateDone:
      {
         int newMarketID = aiPlanGetVariableInt(planID, cBuildPlanFoundationID, 0);
         tradeInformation.marketCompleted(newMarketID, false);
         break;
      }
   }
}

//==============================================================================
// buildMarket
//==============================================================================
void buildMarket(int currentAreaID = -1)
{
   static bool firstRun = true;
   static vector[] corners = default;
   if (firstRun == true)
   {
      corners = new vector(4, cInvalidVector);
      float zSize = kbGetMapZSize() - 1.0; // Offset so it's actually on the map according to the area search.
      float xSize = kbGetMapXSize() - 1.0; // Offset so it's actually on the map according to the area search.
      corners[0] = vector(1.0, 0.0, zSize); // Top left.
      corners[1] = vector(xSize, 0.0, zSize); // Top right.
      corners[2] = vector(xSize, 0.0, 1.0); // Bottom right.
      corners[3] = vector(1.0, 0.0, 1.0); // Bottom left.
   }

   debugTrade("Attempting to build a Market.");
   if (kbAreaGetIsIDValid(currentAreaID) == false)
   {
      debugTrade("Provided currentAreaID is invalid, can't build a new Market!");
      return;
   }

   tradeInformation.mBuildPlanID = aiPlanCreate("Market Build Plan", cPlanBuild, -1, gBuildingsCategoryID);
   // Building Placement.
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(tradeInformation.mBuildPlanID));
   kbBuildingPlacementSetBuildingPUID(bpID, gMarketUnit);
   kbBuildingPlacementAddAreaID(bpID, currentAreaID);
   kbBuildingPlacementSetStepSize(bpID, 2.0);
   kbBuildingPlacementSetBufferSpace(bpID, 2.0);

   // Add all corners as an influence.
   kbBuildingPlacementAddPositionInfluence(bpID, corners[0], 200.0, 100.0, cFalloffLinear);
   kbBuildingPlacementAddPositionInfluence(bpID, corners[1], 200.0, 100.0, cFalloffLinear);
   kbBuildingPlacementAddPositionInfluence(bpID, corners[2], 200.0, 100.0, cFalloffLinear);
   kbBuildingPlacementAddPositionInfluence(bpID, corners[3], 200.0, 100.0, cFalloffLinear);

   // Plan.
   aiPlanSetVariableInt(tradeInformation.mBuildPlanID, cBuildPlanBuildingTypeID, 0, gMarketUnit);
   aiPlanSetVariableInt(tradeInformation.mBuildPlanID, cBuildPlanBuildingPlacementID, 0, bpID);
   aiPlanSetVariableInt(tradeInformation.mBuildPlanID, cBuildPlanMaxCanPaths, 0, 0); // We only attempt to path once.
   aiPlanSetVariableInt(tradeInformation.mBuildPlanID, cBuildPlanMaxRetries, 0, 2); // 3 Total attempts, we want to be notified quickly.
   aiPlanSetPriority(tradeInformation.mBuildPlanID, 50);
   addBuilderTypesToPlan(tradeInformation.mBuildPlanID, gMarketUnit, cCalculateNumBuildersAutomatically);
   aiPlanSetEventHandler(tradeInformation.mBuildPlanID, cPlanEventStateChange, "marketBPEventHandler");
   debugBuildings("Created a Build Plan for: " + kbProtoUnitGetName(gMarketUnit) + " with planID: " + tradeInformation.mBuildPlanID);
   tradeInformation.mCreatedFirstBuildPlan = true;
   tradeInformation.mStartTimeBuildPlan = xsGetTime();
}

//==============================================================================
// createTradePlan
//==============================================================================
void createTradePlan()
{
   tradeInformation.mTradePlanID = aiPlanCreate("MarketTrade", cPlanTrade, -1, gTradeCategoryID);
   aiPlanSetVariableBool(tradeInformation.mTradePlanID, cTradePlanUpdateTarget, 0, false); // We decide in the script.
   aiPlanSetVariableBool(tradeInformation.mTradePlanID, cTradePlanDeleteCantPathToTC, 0, false); // Pathing unreliable atm.
   aiPlanSetPriority(tradeInformation.mTradePlanID, 99);
   aiPlanAddUnitType(tradeInformation.mTradePlanID, gCaravanUnit, 1, 1, 200);
   debugTrade("Created the trade plan with ID: " + tradeInformation.mTradePlanID + ".");
   aiPlanSetEventHandler(tradeInformation.mTradePlanID, cTradePlanEventCantPath, "tradePlanEventPathingMonitor");
   // What Market + TC we're trading with is set dynamically by the trading logic.
}

//==============================================================================
// calculatePaths
//==============================================================================
void calculatePaths(int townCenterID = -1, bool allied = false)
{
   debugTrade("We have not yet calculated the best trading positions for this Town Center ID: " + townCenterID + ", do it now!");
   
   static int numPaths = 0;
   int pathID1 = kbPathCreate("Trade Path " + numPaths);
   numPaths++;
   int pathID2 = kbPathCreate("Trade Path " + numPaths);
   numPaths++;
   
   if (allied == false)
   {
      tradeInformation.mTownCenterIDs.add(townCenterID);
      tradeInformation.mAreaPaths.add(pathID1);
      tradeInformation.mAreaPaths.add(pathID2);
   }
   else
   {
      tradeInformation.mAlliedTownCenterIDs.add(townCenterID);
      tradeInformation.mAlliedAreaPaths.add(pathID1);
      tradeInformation.mAlliedAreaPaths.add(pathID2);
   }

   static bool firstRun = true;
   static vector[] corners = default;
   if (firstRun == true)
   {
      corners = new vector(4, cInvalidVector);
      float zSize = kbGetMapZSize() - 0.01; // Offset so it's actually on the map according to the area search.
      float xSize = kbGetMapXSize() - 0.01; // Offset so it's actually on the map according to the area search.
      corners[0] = vector(0.0, 0.0, zSize); // Top left.
      corners[1] = vector(xSize, 0.0, zSize); // Top right.
      corners[2] = vector(xSize, 0.0, 0.0); // Bottom right.
      corners[3] = vector(0.0, 0.0, 0.0); // Bottom left.
   }

   // Find our closest corner to start calculating our 2 furthest away corners from.
   // Also find our second closest corner to determine if we've spawned in the "middle" of the map instead.
   vector tcPosition = kbUnitGetPosition(townCenterID);
   float closestDistance = 10000.0;
   float secondClosestDistance = 10000.0;
   int closestIndex = -1;
   int secondClosestIndex = -1;
   for (int i = 0; i < 4; i++)
   {
      float distance = xsVectorDistance(tcPosition, corners[i]);
      if (distance < closestDistance)
      {
         // Update second closest with what was closest.
         secondClosestIndex = closestIndex;
         secondClosestDistance = closestDistance;
         // Update closest.
         closestIndex = i;
         closestDistance = distance;
      }
      else if (distance < secondClosestDistance)
      {
         secondClosestIndex = i;
         secondClosestDistance = distance;
      }
   }
   debugTrade("Closest index = " + closestIndex + ", second closest index = " + secondClosestIndex +
         ".    0 = Top Left,   1 = Top Right,   2 = Bottom Right,   3 = Bottom Left.");

   int index1 = -1;
   int index2 = -1;

   // It could be that our TC is practically between two corners, so our TC is in the "middle" of the map.
   // Then we need to analyze our closest two corners instead. Because otherwise we will walk across the map to the enemy most likely.
   float path1Length = xsVectorDistance(tcPosition, corners[closestIndex]);
   float path2Length = xsVectorDistance(tcPosition, corners[secondClosestIndex]);
   debugTrade("Distance to our closest corner =  " + path1Length + ".");
   debugTrade("Distance to our second closest corner =  " + path2Length + ".");
   if (path2Length < path1Length * 1.6  && path2Length > path1Length * 0.4)
   {
      debugTrade("TC is NOT in a corner of the map, analyzing 2 closest corners now.");
      // We can just take the results from the loop above since we won't analyze any new corners.
      index1 = secondClosestIndex;
      index2 = closestIndex;
   }
   else
   {
      debugTrade("TC is in a corner of the map, analyzing the 2 adjecent corners now.");
      int myCornerIndex = closestIndex;
      debugTrade("My corner index = " + myCornerIndex + ".");
      // Our closest index means that we're "in that corner". We now need to pick our closest 2 corners, but not the opposite corner
      // since it can be expected that the enemy is there.
      int adjacentCornerIndex1 = myCornerIndex - 1;
      if (adjacentCornerIndex1 == -1)
      {
         adjacentCornerIndex1 = 3;
      }
      debugTrade("Adjacent corner index 1 = " + adjacentCornerIndex1 + ".");
      int adjacentCornerIndex2 = myCornerIndex + 1;
      if (adjacentCornerIndex2 == 4)
      {
         adjacentCornerIndex2 = 0;
      }
      debugTrade("Adjacent corner index 2 = " + adjacentCornerIndex2 + ".");
      index1 = adjacentCornerIndex1;
      index2 = adjacentCornerIndex2;
   }

   // At this point we have 2 corners that we need to analyze.
   // In furthestCornerIndex we saved the corner that is furthest away from us, and in closestCornerIndex the one closest to us.
   // Now we need to generate area paths to both points and analyze the dangers of those paths.
   int tcAreaID = kbAreaGetIDByPosition(tcPosition);
   int goalAreaID = kbAreaGetIDByPosition(corners[index1]);
   kbPathCreateAreaPath(pathID1, tcAreaID, goalAreaID, cPassabilityLand, 100.0, true);
   goalAreaID = kbAreaGetIDByPosition(corners[index2]);
   kbPathCreateAreaPath(pathID2, tcAreaID, goalAreaID, cPassabilityLand, 100.0, true);
   
   debugTrade("End of finding two trade routes for this TC.");
}

//==============================================================================
// manageTCArrays
//==============================================================================
bool manageTCArrays()
{
   // We search for new Town Centers only on the area group of our main base.
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID == -1)
   {
      debugTrade("We have no main base, we can't trade due to this.");
      tradeInformation.resetProgressData();
      tradeInformation.resetTradingData();
      tradeInformation.clearArrays();
      return false;
   }

   for (int i = 0; i < tradeInformation.mTownCenterIDs.size(); i++)
   {
      if (kbUnitGetIsIDValid(tradeInformation.mTownCenterIDs[i]) == false)
      {
         debugTrade("We've lost a Town Center, removing it from our array.");
         if (tradeInformation.mCurrentTownCenterID == tradeInformation.mTownCenterIDs[i])
         {
            debugTrade("We were trading with this TC! We need to perform all the construction logic again.");
            tradeInformation.resetProgressData();
            tradeInformation.resetTradingData();
         }
         // If this is a banned path we need to remove it from that array.
         int pathID1 = tradeInformation.mAreaPaths[i * 2];
         tradeInformation.mBannedPathIDs.removeValue(pathID1);
         int pathID2 = tradeInformation.mAreaPaths[i * 2 + 1];
         tradeInformation.mBannedPathIDs.removeValue(pathID2);
         kbPathDestroy(pathID1);
         kbPathDestroy(pathID2);
         // Cleanup this TC + 2 associated routes from the arrays.
         tradeInformation.mTownCenterIDs.removeIndex(i);
         tradeInformation.mAreaPaths.removeIndex(i * 2);
         tradeInformation.mAreaPaths.removeIndex(i * 2);
      }
   }

   for (int i = 0; i < tradeInformation.mAlliedTownCenterIDs.size(); i++)
   {
      if (kbUnitGetIsIDValid(tradeInformation.mAlliedTownCenterIDs[i]) == false)
      {
         debugTrade("Our ally lost a Town Center, removing it from our array.");
         if (tradeInformation.mCurrentTownCenterID == tradeInformation.mAlliedTownCenterIDs[i])
         {
            debugTrade("We were trading with this TC! We need to perform all the construction logic again.");
            tradeInformation.resetProgressData();
            tradeInformation.resetTradingData();
         }
         // If this is a banned path we need to remove it from that array.
         int pathID1 = tradeInformation.mAlliedAreaPaths[i * 2];
         tradeInformation.mBannedPathIDs.removeValue(pathID1);
         int pathID2 = tradeInformation.mAlliedAreaPaths[i * 2 + 1];
         tradeInformation.mBannedPathIDs.removeValue(pathID2);
         kbPathDestroy(pathID1);
         kbPathDestroy(pathID2);
         // Cleanup this TC + 2 associated routes from the arrays.
         tradeInformation.mAlliedTownCenterIDs.removeIndex(i);
         tradeInformation.mAlliedAreaPaths.removeIndex(i * 2);
         tradeInformation.mAlliedAreaPaths.removeIndex(i * 2);
      }
   }

   int areaGroupID = kbAreaGroupGetIDByPosition(kbBaseGetLocation(cMyID, mainBaseID));
   int queryID = useSimpleUnitQuery(cUnitTypeTradeableTo);
   kbUnitQuerySetAreaGroupID(queryID, areaGroupID);
   int numResults = kbUnitQueryExecute(queryID);
   int[] townCenters = kbUnitQueryGetResults(queryID);
   if (numResults != tradeInformation.mTownCenterIDs.size())
   {
      // Add Town Centers to our arrays.
      for (int i = 0; i < numResults; i++)
      {
         if (tradeInformation.mTownCenterIDs.find(townCenters[i]) == -1)
         {
            debugTrade("Found a new TC to add to our arrays: " + townCenters[i] +
               ", reducing time till next trade route analysis by 30 seconds.");
            calculatePaths(townCenters[i], false);
            tradeInformation.mStartTimeFunctionalTradeRoute -= 30;
         }
      }
   }

   queryID = useSimpleUnitQuery(cUnitTypeTradeableTo, cPlayerRelationAllyExcludingSelf);
   kbUnitQuerySetAreaGroupID(queryID, areaGroupID);
   numResults = kbUnitQueryExecute(queryID);
   int[] alliedTownCenters = kbUnitQueryGetResults(queryID);
   if (numResults != tradeInformation.mAlliedTownCenterIDs.size())
   {
      // Add allied Town Centers to our arrays.
      for (int i = 0; i < numResults; i++)
      {
         if (tradeInformation.mAlliedTownCenterIDs.find(alliedTownCenters[i]) == -1)
         {
            debugTrade("Found a new Allied TC to add to our arrays: " + alliedTownCenters[i] +
               ", reducing time till next trade route analysis by 30 seconds.");
            calculatePaths(alliedTownCenters[i], true);
            tradeInformation.mStartTimeFunctionalTradeRoute -= 30;
         }
      }
   }

   // Spit it all out for debugging.
   for (int i = 0; i < tradeInformation.mTownCenterIDs.size(); i++)
   {
      debugTrade("tradeInformation.mTownCenterIDs[" + i + "] = " + tradeInformation.mTownCenterIDs[i]);
   }
   for (int i = 0; i < tradeInformation.mAreaPaths.size(); i++)
   {
      debugTrade("tradeInformation.mAreaPaths[" + i + "] = " + tradeInformation.mAreaPaths[i]);
   }
   for (int i = 0; i < tradeInformation.mAlliedTownCenterIDs.size(); i++)
   {
      debugTrade("tradeInformation.mAlliedTownCenterIDs[" + i + "] = " + tradeInformation.mAlliedTownCenterIDs[i]);
   }
   for (int i = 0; i < tradeInformation.mAlliedAreaPaths.size(); i++)
   {
      debugTrade("tradeInformation.mAlliedAreaPaths[" + i + "] = " + tradeInformation.mAlliedAreaPaths[i]);
   }
   return true;
}

//==============================================================================
// calculateBestTradeRoute
//==============================================================================
int calculateBestTradeRoute()
{
   float furthestDistance = 0.0;
   int bestAreaID = -1;
   int bestTCID = -1;
   int bestPathID = -1;
   
   for (int i = 0; i < tradeInformation.mAreaPaths.size(); i++)
   {
      int tcID = tradeInformation.mTownCenterIDs[i / 2];
      int pathID = tradeInformation.mAreaPaths[i];
      if (tradeInformation.mBannedPathIDs.find(pathID) != -1)
      {
         debugTrade("PathID " + pathID + " belonging to tcID " + tcID + " is currently banned, skipping.");
         continue;
      }
      debugTrade ("tcID: " + tcID + ", pathID: " + pathID);
      vector tcPosition = kbUnitGetPosition(tcID);
      int numberWaypoints = kbPathGetNumberWaypoints(pathID);
      for (int iWaypoint = 0; iWaypoint < numberWaypoints; iWaypoint++) 
      {
         vector waypoint = kbPathGetWaypoint(pathID, iWaypoint);
         int areaID = kbAreaGetIDByPosition(waypoint);
         // If we're not at the last index we need to analyze the next index to see if we should stop.
         if (iWaypoint != numberWaypoints - 1)
         {
            vector nextWaypoint = kbPathGetWaypoint(pathID, iWaypoint + 1);
            int nextAreaID = kbAreaGetIDByPosition(nextWaypoint);
            float dangerLevel = kbAreaGetDangerLevel(nextAreaID, false);
            if (dangerLevel > 120.0)
            {
               debugTrade("Danger level above 120.0 at next waypoint " + (iWaypoint + 1) + ", stop analyzing more waypoints.");
            }
            else
            {
               continue; // Progress to next waypoint.
            }
         }
         else
         {
            debugTrade("This is our last waypoint on the path.");
         }
         
         float distance = xsVectorDistanceXZ(tcPosition, waypoint);
         if (distance > furthestDistance)
         {
            bestTCID = tcID;
            bestPathID = pathID;
            bestAreaID = areaID;
            furthestDistance = distance;
            debugTrade("This is now our furthest away trade route.");
         }
         else
         {
            debugTrade("This route is not the best.");
         }
         break;
      }
   }

   float alliedTradingBonus = kbGetAlliedTradingBonus();
   for (int i = 0; i < tradeInformation.mAlliedAreaPaths.size(); i++)
   {
      int tcID = tradeInformation.mAlliedTownCenterIDs[i / 2];
      int pathID = tradeInformation.mAlliedAreaPaths[i];
      if (tradeInformation.mBannedPathIDs.find(pathID) != -1)
      {
         debugTrade("PathID " + pathID + " belonging to tcID " + tcID + " is currently banned, skipping.");
         continue;
      }
      debugTrade ("tcID: " + tcID + ", pathID: " + pathID);
      vector tcPosition = kbUnitGetPosition(tcID);
      int numberWaypoints = kbPathGetNumberWaypoints(pathID);
      for (int iWaypoint = 0; iWaypoint < numberWaypoints; iWaypoint++)
      {
         vector waypoint = kbPathGetWaypoint(pathID, iWaypoint);
         int areaID = kbAreaGetIDByPosition(waypoint);
         // If we're not at the last index we need to analyze the next index to see if we should stop.
         if (iWaypoint != numberWaypoints - 1)
         {
            vector nextWaypoint = kbPathGetWaypoint(pathID, iWaypoint + 1);
            int nextAreaID = kbAreaGetIDByPosition(nextWaypoint);
            float dangerLevel = kbAreaGetDangerLevel(nextAreaID, false);
            if (dangerLevel > 120.0)
            {
               debugTrade("Danger level above 120.0 at next waypoint " + (iWaypoint + 1) + ", stop analyzing more waypoints.");
            }
            else
            {
               continue; // Progress to next waypoint.
            }
         }
         else
         {
            debugTrade("This is our last waypoint on the path.");
         }
         
         float distance = xsVectorDistanceXZ(tcPosition, waypoint);
         if (distance > furthestDistance)
         {
            bestTCID = tcID;
            bestPathID = pathID;
            bestAreaID = areaID;
            furthestDistance = distance;
            debugTrade("This is now our furthest away trade route.");
         }
         else
         {
            debugTrade("This route is not the best.");
         }
         break;
      }
   }

   if (furthestDistance <= 75.0)
   {
      debugTrade("Our found waypoint is < 75.0 meters away from our TC. This means all routes are too short " + 
         "to be effective anymore. Restarting the entire process with a 2 minute delay.");
      xsSetRuleMinInterval("tradeMonitor", 120); // 2 Minute wait.
      tradeInformation.resetProgressData();
      bestAreaID = -1;
   }
   else
   {
      debugTrade("Our best area to build a Market in is: " + bestAreaID + ".");
      tradeInformation.mBuildMarketAreaID = bestAreaID;
      tradeInformation.mCurrentTownCenterID = bestTCID;
      tradeInformation.mCurrentPathID = bestPathID;
   }

   return bestAreaID;
}

//==============================================================================
// manageBannedPaths
// Every 2 minutes we clear a path from the banned list so we can try it again.
//==============================================================================
void manageBannedPaths()
{
   int currentTime = xsGetTime();
   for (int i = tradeInformation.mBannedPathIDStartTime.size() - 1; i >= 0; i--)
   {
      if (tradeInformation.mBannedPathIDStartTime[i] + 120 < currentTime)
      {
         debugTrade("Unbanning pathID: " + tradeInformation.mBannedPathIDs[i] + ".");
         tradeInformation.mBannedPathIDStartTime.removeIndex(i);
         tradeInformation.mBannedPathIDs.removeIndex(i);
      }
   }
}

//==============================================================================
// tradeMonitor
//==============================================================================
rule tradeMonitor
inactive
group defaultHeroicRules
minInterval 1 // Set by first run to a different value.
{
   if (cStartingResourcesCurrent == cStartingResourcesInfinite)
   {
      xsDisableRule("tradeMonitor");
      return;
   }

   if (checkStrategyFlag(cStrategyFlagCanTrade) == false)
   {
      if (aiPlanGetIsIDValid(tradeInformation.mTradePlanID) == true)
      {
         aiPlanDestroy(tradeInformation.mTradePlanID);
      }
      return;
   }

   // We manage our trading on a difficulty based timer.
   // Keep resetting this because we may delay it during execution again.
   xsSetRuleMinInterval("tradeMonitor", selectByDifficulty(50, 40, 30, 20, 10, 5));

   debugTrade("--- Running Rule tradeMonitor. ---");

   if (aiPlanGetIsIDValid(tradeInformation.mTradePlanID) == false)
   {
      createTradePlan();
   }

   // Remove dead TCs and add new ones.
   if (manageTCArrays() == false)
   {
      return;
   }

   // Manage our banned paths.
   manageBannedPaths();

   if (tradeInformation.mTownCenterIDs.size() == 0 && tradeInformation.mAlliedTownCenterIDs.size() == 0)
   {
      debugTrade("There are no TCs on the map we can trade with, quiting.");
      return;
   }

   // If we're currently trading we must make sure our Market stays alive, checking for TC alive happens in manageTCArrays.
   // If we've been trading on this current route for some time we reset and analyze again to potentially find a better route.
   if (tradeInformation.mHaveFunctionalTradeRoute == true)
   {
      if (kbUnitGetIsIDValid(tradeInformation.mCurrentMarketID) == false)
      {
         debugTrade("Our Market has been destroyed! We need to perform all the construction logic again.");
         tradeInformation.resetProgressData();
         tradeInformation.resetTradingData();
      }
      else if (tradeInformation.mStartTimeFunctionalTradeRoute + 180 < xsGetTime())
      {
         debugTrade("We've had this functional trade for at least 3 minutes now, analyze if better routes have opened up for us.");
         tradeInformation.resetProgressData();
      }
      else
      {
         debugTrade("We have a functional trade route, nothing to do for now, next analysis at: " +
            turnNumberIntoTimeDisplay(tradeInformation.mStartTimeFunctionalTradeRoute + 180));
         return;
      }
   }

   if (tradeInformation.mCreatedFirstBuildPlan == false)
   {
      int bestAreaID = calculateBestTradeRoute();
      if (bestAreaID == -1)
      {
         debugTrade("Didn't find an area to build the Market in, quiting.");
         return;
      }

      int queryID = useSimpleUnitQuery(gMarketUnit, cMyID, cUnitStateAlive);
      kbUnitQuerySetAreaID(queryID, bestAreaID);
      int numResults = kbUnitQueryExecute(queryID);
      if (numResults >= 1)
      {
         debugTrade("Found an existing Market in our best area, market ID: " + kbUnitQueryGetResult(queryID, 0) + ".");
         tradeInformation.marketCompleted(kbUnitQueryGetResult(queryID, 0), true);
      }
      else
      {
         buildMarket(bestAreaID);
      }
      return;
   }

   if (tradeInformation.mFirstBuildPlanExecuted == false)
   {
      if (tradeInformation.mStartTimeBuildPlan + 300 < xsGetTime())
      {
         debugTrade("We've waited for 5 minutes after starting our build plan, assume something is stuck.");
         tradeInformation.resetProgressData();
      }
      else
      {
         debugTrade("Waiting on our first build plan for this areaID to do its thing.");
      }
      return; // Let the build plan do its thing for now.
   }

   // If we haven't scouted the < 80% of the area we must scout more.
   static int scoutPlanID = -1;
   static int scoutPlanCreationTime = -1;
   float percentExplored = kbAreaGetPercentExplored(tradeInformation.mBuildMarketAreaID);
   if (percentExplored < 0.80)
   {
      debugTrade("We have scouted " + percentExplored + " percent of our market area: " + tradeInformation.mBuildMarketAreaID +
         ", this isn't enough, scouts are underway.");
      if (aiPlanGetIsIDValid(scoutPlanID) == false)
      {
         // This is not hidden behind the exploration strategy flag cuz then the entire system would stall.
         scoutPlanID = aiPlanCreate("Explore Market", cPlanExplore, -1, gExplorationCategoryID);
         aiPlanSetPriority(scoutPlanID, 51);
         aiPlanAddUnitType(scoutPlanID, cUnitTypeLogicalTypeLandMilitary, 1, 1, 1);
         aiPlanSetVariableInt(scoutPlanID, cExplorePlanExploreAreaIDs, 0, tradeInformation.mBuildMarketAreaID);
         debugTrade("Creating explore plan to explore area: " + tradeInformation.mBuildMarketAreaID + ", plan name: " +
            aiPlanGetName(scoutPlanID) + ".");
         scoutPlanCreationTime = xsGetTime();
      }
      else // We already have a plan, we can perform some unstuck / speed up logic now.
      {
         // Unstuck timer.
         if (scoutPlanCreationTime + 180 < xsGetTime())
         {
            debugTrade("Our scouting plan has been alive for at least 3 minutes but we haven't scouted the area enough yet.");
            debugTrade("We're going to assume we're having difficulties scouting this spot, aborting.");
            aiPlanDestroy(scoutPlanID);
            scoutPlanID = -1;
            scoutPlanCreationTime = -1;
            tradeInformation.resetProgressData();
            return;
         }

         int[] units = aiPlanGetUnits(scoutPlanID);
         if (units.size() != 0)
         {
            // Pathing check for if we have units to path with.
            int scoutID = units[0];
            if (kbCanPath(kbUnitGetPosition(scoutID), kbAreaGetCenter(tradeInformation.mBuildMarketAreaID), kbUnitGetProtoUnitID(scoutID), 5.0) == false)
            {
               debugTrade("Our scout can't path to the area center, it must've been blocked off outside our LOS.");
               aiPlanDestroy(scoutPlanID);
               scoutPlanID = -1;
               scoutPlanCreationTime = -1;
               tradeInformation.resetProgressData();
               return;
            }
         }
      }
   }
   else
   {
      // We restart the entire process after scouting this area because very clearly before it was in fog.
      // Who knows what we found on our way there, maybe it's behind an enemy base. We need to assess dangers again.
      debugTrade("We have scouted " + percentExplored + " percent of our market area: " + tradeInformation.mBuildMarketAreaID +
         ", this suffices. Restarting the trade route finding process.");
      tradeInformation.resetProgressData();
      if (aiPlanGetIsIDValid(scoutPlanID) == true)
      {
         aiPlanDestroy(scoutPlanID);
      }
      scoutPlanID = -1;
      scoutPlanCreationTime = -1;
   }

   // If we're here it means we have a build plan going and if something goes wrong with it we will get notified.
}