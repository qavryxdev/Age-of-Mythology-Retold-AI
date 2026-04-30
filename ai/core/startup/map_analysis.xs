class MapInfo
{
   bool mIsNomadMap = false;
   bool mHasFish = false;
   bool mShouldFish = false;
   bool mHasWater = false;
   bool mIsIslandMap = false;
   bool mStartsWithTransport = false;
   
   // Area groups related.
   bool mStartOnDifferentIslands = false;
   bool mKOTHIsOnDifferentIsland = false;
   bool mIsMigrationMap = false;
   int[] mMigratableAreaGroups = default;
   int[] mUsefulWaterAreaGroupIDs = default;

   // Dock related.
   bool mShouldBuildDock = false;
   int mDockAreaGroupID = -1;
   int mClosestShorelineAreaID = -1;
   int mClosestWaterAreaID = -1;
   vector mWaterDefendPoint = cInvalidVector;

   void displayMapInfo()
   {
      debugStartAnalysis("*** displayMapInfo ***");
      debugStartAnalysis("mIsNomadMap: " + xsBoolToString(mIsNomadMap));
      debugStartAnalysis("mHasFish: " + xsBoolToString(mHasFish));
      debugStartAnalysis("mShouldFish: " + xsBoolToString(mShouldFish));
      debugStartAnalysis("mHasWater: " + xsBoolToString(mHasWater));
      debugStartAnalysis("mIsIslandMap: " + xsBoolToString(mIsIslandMap));
      debugStartAnalysis("mStartsWithTransport: " + xsBoolToString(mStartsWithTransport));

      // Area groups related.
      debugStartAnalysis("mStartOnDifferentIslands: " + xsBoolToString(mStartOnDifferentIslands));
      debugStartAnalysis("mKOTHIsOnDifferentIsland: " + xsBoolToString(mKOTHIsOnDifferentIsland));
      debugStartAnalysis("mIsMigrationMap: " + xsBoolToString(mIsMigrationMap));
      for (int i = 0; i < mMigratableAreaGroups.size(); i++)
      {
         debugStartAnalysis("Migratable area groups: " + mMigratableAreaGroups[i]);
      }
      for (int i = 0; i < mUsefulWaterAreaGroupIDs.size(); i++)
      {
         debugStartAnalysis("Useful water area groups: " + mUsefulWaterAreaGroupIDs[i]);
      }
      
      // Dock related.
      debugStartAnalysis("mShouldBuildDock: " + xsBoolToString(mShouldBuildDock));
      debugStartAnalysis("mDockAreaGroupID: " + mDockAreaGroupID);
      debugStartAnalysis("mClosestShorelineAreaID: " + mClosestShorelineAreaID);
      debugStartAnalysis("mClosestWaterAreaID: " + mClosestWaterAreaID);
      debugStartAnalysis("mWaterDefendPoint: X=" + mWaterDefendPoint);
   }
   // We can use this after we've lost our mainbase to reset all info that was calculated using our main base and then call
   // analyseNavalPositions() again to fill it up with new accurate information.
   void resetDynamicWaterInfo()
   {
      mShouldFish = false;
      mShouldBuildDock = false;
      mDockAreaGroupID = -1;
      mClosestShorelineAreaID = -1;
      mClosestWaterAreaID = -1;
      mWaterDefendPoint = cInvalidVector;
   }
};
extern MapInfo gMapInfo;

//==============================================================================
// analyseNavalPositions
// The idea of shorelineSpecificPoint is that when you have a Dock built already in the provided landAreaID
// that you can make sure the defend point lies close to the Dock instead of being generated from area center.
//==============================================================================
void analyseNavalPositions(int landAreaID = -1, vector shorelineSpecificPoint = cInvalidVector, bool showInfo = false)
{
   debugStartAnalysis("Calling analyseNavalPositions with: landAreaID: " + landAreaID + ", shorelineSpecificPoint: " + 
      shorelineSpecificPoint + ".");
   // Reset everything.
   gMapInfo.resetDynamicWaterInfo();
   gClosestFishLocation = cInvalidVector;

   int startAreaID = -1;
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (gMapInfo.mHasFish == true && mainBaseID != -1)
   {
      if (gOverrideClosestFishLocation == cInvalidVector)
      {
         vector searchStartPosition = kbBaseGetLocation(cMyID, mainBaseID);
         xsSetContextPlayer(0);
         int natureQueryID = useSimpleNatureUnitQuery(cUnitTypeFishResource, cUnitStateAny, searchStartPosition, gMaxFishDockScanRange);
         kbUnitQuerySetAscendingSort(natureQueryID, true);
         int numResults = kbUnitQueryExecute(natureQueryID);
         for (int i = 0; i < numResults; i++)
         {
            vector resultPosition = kbUnitGetPosition(kbUnitQueryGetResult(natureQueryID, i));
            int waterAreaID = kbAreaGetIDByPosition(resultPosition);
            if (gMapInfo.mUsefulWaterAreaGroupIDs.find(kbAreaGetGroupID(waterAreaID)) != -1)
            {
               debugStartAnalysis("Fish " + kbUnitQueryGetResult(natureQueryID, i) + " is the closest fish we can find that is " +
                  "in an area group that we think is useful to have a Dock in.");
               gClosestFishLocation = resultPosition;
               break;
            }
         }
         xsSetContextPlayer(cMyID);
      }
      else
      {
         // We assume we always want to fish if we have an override.
         gClosestFishLocation = gOverrideClosestFishLocation;
      }

      // If we have a closest fish location, we will fish.
      gMapInfo.mShouldFish = gClosestFishLocation != cInvalidVector;
      if (gMapInfo.mShouldFish == true)
      {
         debugStartAnalysis("gClosestFishLocation is: " + gClosestFishLocation);
         startAreaID = kbAreaGetIDByPosition(gClosestFishLocation);
      }
   }

   if (((cVictoryTypesCurrent & cVictoryTypeKingOfTheHill) != 0) && mainBaseID != -1)
   {
      int ownAreaGroupID = kbAreaGroupGetIDByPosition(kbBaseGetLocation(cMyID, mainBaseID));
      int kothAreaGroupID = kbAreaGroupGetIDByPosition(gKOTHPosition);
      if (ownAreaGroupID != kothAreaGroupID)
      {
         gMapInfo.mKOTHIsOnDifferentIsland = true;
      }
   }

   if ((gMapInfo.mStartOnDifferentIslands == true || gMapInfo.mKOTHIsOnDifferentIsland == true) && startAreaID == -1 && mainBaseID != -1)
   {
      if (gMapInfo.mStartOnDifferentIslands == true)
      {
         debugStartAnalysis("We found no close Fish but some other player is not on the same island as us, we should build a Dock regardless.");
      }
      if (gMapInfo.mKOTHIsOnDifferentIsland == true)
      {
         debugStartAnalysis("We found no close Fish but the KOTH is not on the same island as us, we should build a Dock regardless.");
      }
      // This means we found no fish to gather from but we definitely should have a Dock because we need to transport.
      // Now we do a mental loop to find the closest water area ID that is useful.
      float closestDistance = cMaxFloat;
      vector searchStartPosition = kbBaseGetLocation(cMyID, mainBaseID);
      for (int i = 0; i < gMapInfo.mUsefulWaterAreaGroupIDs.size(); i++)
      {
         int numAreas = kbAreaGroupGetNumberAreas(gMapInfo.mUsefulWaterAreaGroupIDs[i]);
         for (int iArea = 0; iArea < numAreas; iArea++)
         {
            vector center = kbAreaGetCenter(kbAreaGroupGetAreaID(gMapInfo.mUsefulWaterAreaGroupIDs[i], iArea));
            float distance = xsVectorLength(center - searchStartPosition);
            if (distance < closestDistance)
            {
               closestDistance = distance;
               startAreaID = kbAreaGroupGetAreaID(gMapInfo.mUsefulWaterAreaGroupIDs[i], iArea);
            }
         }
      }
   }

   if (startAreaID != -1) // This means that we do want a Dock, either because of fishing or because we need to transport.
   {
      gMapInfo.mShouldBuildDock = true;
      int pathID = kbPathCreate("Calculate Dock Position");
      kbPathCreateAreaPath(pathID, startAreaID, landAreaID, cPassabilityAmphibious);
      int shorelineAreaID = -1;
      int waterAreaID = -1;
      // We start at i = 1 because we already know waypoint 0 will be in the water at the fish/area group center.
      for (int i = 1; i < kbPathGetNumberWaypoints(pathID); i++)
      {
         vector waypoint = kbPathGetWaypoint(pathID, i);
         int areaID = kbAreaGetIDByPosition(waypoint);
         if (isAreaPassableByLand(areaID) == true)
         {
            shorelineAreaID = areaID;
            waterAreaID = kbAreaGetIDByPosition(kbPathGetWaypoint(pathID, i -1));
            debugStartAnalysis("Found a land area on our path with ID: " + shorelineAreaID + ", closest water area ID: " + waterAreaID);
            break;
         }
      }
      kbPathDestroy(pathID);
      if (shorelineAreaID == -1 || waterAreaID == -1)
      {
         aiEchoWarning("analyseNavalPositions - couldn't find a shorelineAreaID/waterAreaID, this shouldn't be possible ever!");
         gMapInfo.mShouldBuildDock = false;
         return;
      }

      vector shorelineCenter = cInvalidVector;
      if (shorelineSpecificPoint != cInvalidVector)
      {
         shorelineAreaID = kbAreaGetIDByPosition(shorelineSpecificPoint);
         shorelineCenter = shorelineSpecificPoint;
         debugStartAnalysis("Using a specific shoreline point override, point: " + shorelineCenter + ", area ID: " + shorelineAreaID);
      }
      else
      {
         shorelineCenter = kbAreaGetCenter(shorelineAreaID);
      }
      
      gMapInfo.mClosestShorelineAreaID = shorelineAreaID;
      gMapInfo.mClosestWaterAreaID = waterAreaID;
      gMapInfo.mDockAreaGroupID = kbAreaGetGroupID(waterAreaID);
      
      // Now we still start stepping from the shoreline area until we reach the water twice.
      // This second point will be used for our naval defend logic.
      vector waterCenter = kbAreaGetCenter(waterAreaID);
      vector directionStep = xsVectorNormalize(waterCenter - shorelineCenter) * 5;
      gMapInfo.mWaterDefendPoint = waterCenter;
      bool foundWater = false;
      for (int i = 1; i < 15; i++)
      {
         vector testLocation = shorelineCenter + (directionStep * i);
         // Once we find water we perform one more loop to get a position that is firmly inside the water instead of maybe
         // being on the edge of it, afterwards we're done.
         if (foundWater == true)
         {
            gMapInfo.mWaterDefendPoint = testLocation;
            break;
         }
         int testAreaID = kbAreaGetIDByPosition(testLocation);
         if (kbAreaGetType(testAreaID) == cAreaTypeWater)
         {
            foundWater = true;
         }
      }
      if (foundWater == false)
      {
         aiEchoWarning("analyseNavalPositions - our stepping couldn't find water at all, this shouldn't be possible!");
      }
   }
   
   if (showInfo == true)
   {
      gMapInfo.displayMapInfo();
   }
}

//==============================================================================
// doMapAnalysis
//==============================================================================
bool doMapAnalysis()
{
   debugStartAnalysis("*** Analyzing Map ***");

   // See what kind of start we're dealing with this time.
   int townCenterID = getUnit(cUnitTypeAbstractTownCenter, cMyID, cUnitStateAlive);
   vector baseVec = cInvalidVector;
   if (kbUnitGetIsIDValid(townCenterID) == false)
   {
      int unitID = getUnit(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive);
      if (kbUnitGetIsIDValid(unitID) == false)
      {
         debugStartAnalysis("**** I give up... I can't find a TC/Villager. How do you expect me to play?! ****");
         return false;
      }
      else
      {
         gMapInfo.mIsNomadMap = true;
         baseVec = kbUnitGetPosition(unitID);
         debugStartAnalysis("We're starting without a TC but have Villagers, Nomad style map.");
      }
   }
   else
   {
      baseVec = kbUnitGetPosition(townCenterID);
   }

   int numAreaGroups = kbAreaGroupGetNumber();
   for (int i = 0; i < numAreaGroups; i++)
   {
      if (kbAreaGroupGetType(i) == cAreaGroupTypeWater)
      {
         debugStartAnalysis("Map has water.");
         gMapInfo.mHasWater = true;
         break;
      }
   }

   if (getUnit(cUnitTypeAbstractTransportShip) != -1)
   {
      gMapInfo.mStartsWithTransport = true;
   }

   int[] startingAreaGroupIDs = new int(0, 0);
   // Check for island map and starting on different islands.
   int tempBaseVecAreaGroupID = kbAreaGroupGetIDByPosition(baseVec);
   gMapInfo.mIsIslandMap = kbGetIslandMap();
   for (int player = 1; player <= cNumberPlayers; player++)
   {
      if (player == cMyID)
      {
         continue;
      }
      vector otherStartingPosition = kbPlayerGetStartingPosition(player);
      if (otherStartingPosition == cInvalidVector)
      {
         if (cGameTypeCurrent == cGameTypeRandomMap)
         {
            aiEchoWarning("Player " + player + " has no valid starting position set.");
            continue;
         }
         else
         {
            // Scenarios and campaigns don't set the starting position as RMs do, figure it out ourself cheat style. (but it's a static map so fine)
            xsSetContextPlayer(player);
            int queryID = kbUnitQueryCreate("doMapAnalysis");
            kbUnitQuerySetPlayerID(queryID, player);
            kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateSeeable);
            kbUnitQuerySetUnitType(queryID, cUnitTypeAbstractTownCenter);
            kbUnitQuerySetState(queryID, cUnitStateAlive);
            kbUnitQueryResetResults(queryID);
            int numResults = kbUnitQueryExecute(queryID);
            if (numResults > 0)
            {
               otherStartingPosition = kbUnitGetPosition(kbUnitQueryGetResult(queryID, 0));
            }
            else
            {
               kbUnitQuerySetUnitType(queryID, cUnitTypeUnit);
               kbUnitQueryResetResults(queryID);
               numResults = kbUnitQueryExecute(queryID);
               if (numResults > 0)
               {
                  otherStartingPosition = kbUnitGetPosition(kbUnitQueryGetResult(queryID, 0));
               }
            }
            kbUnitQueryDestroy(queryID);
            xsSetContextPlayer(cMyID);
            if (otherStartingPosition == cInvalidVector)
            {
               debugStartAnalysis("Couldn't find a starting position for player " + player + ".");
               continue;
            }
         }
      }

      int otherAreaGroupID = kbAreaGroupGetIDByPosition(otherStartingPosition);
      if (tempBaseVecAreaGroupID != otherAreaGroupID)
      {
         startingAreaGroupIDs.uniqueAdd(otherAreaGroupID);
         if (gMapInfo.mStartOnDifferentIslands == false)
         {
            gMapInfo.mStartOnDifferentIslands = true;
            debugStartAnalysis("We're starting on different islands.");
         }
      }
   }

   int startingAreaGroupID = kbAreaGroupGetIDByPosition(baseVec);
   float surfaceArea = kbAreaGroupGetSurfaceArea(startingAreaGroupID);
   for (int i = 0; i < numAreaGroups; i++)
   {
      int areaGroupType = kbAreaGroupGetType(i);
      if (kbAreaGroupGetType(i) == cAreaGroupTypeWater)
      {
         // If we're not starting on different islands we don't have to bother with picking an area group that we can transport from.
         if (gMapInfo.mStartOnDifferentIslands == false)
         {
            gMapInfo.mUsefulWaterAreaGroupIDs.add(i);
         }
         else
         {
            bool useful = true;
            for (int iAreaGroup = 0; iAreaGroup < startingAreaGroupIDs.size(); iAreaGroup++)
            {
               if (kbAreaGroupsBordersAreaGroupID(i, startingAreaGroupIDs[iAreaGroup]) == false)
               {
                  useful = false;
                  break;
               }
            }
            if (useful == true)
            {
               gMapInfo.mUsefulWaterAreaGroupIDs.add(i);
            }
         }
      }

      // If this is another land mass we need to check if we should migrate to there potentially.
      if (startingAreaGroupID != i && areaGroupType == cAreaGroupTypeLand && (surfaceArea * 5) < kbAreaGroupGetSurfaceArea(i))
      {
         if (gMapInfo.mIsMigrationMap == false)
         {
            gMapInfo.mIsMigrationMap = true;
            debugStartAnalysis("We should migrate on this map.");
         }
         gMapInfo.mMigratableAreaGroups.add(i);
      }
   }

   if (gMapInfo.mStartOnDifferentIslands == true && gMapInfo.mUsefulWaterAreaGroupIDs.size() == 0)
   {
      // If we're in SPC we continue because we're going to assume everything is custom scripted to handle this.
      if (cGameTypeCurrent == cGameTypeRandomMap)
      {
         aiEchoWarning("Map detected where we would need to cross multiple water area groups to reach some enemies, we don't handle this.");
         return false;
      }
      else
      {
         debugStartAnalysis("Map detected where we would need to cross multiple water area groups to reach some enemies, " +
            "we don't natively handle this. Your campaign script must write custom code for this.");
      }
   }

   gMapInfo.mHasFish = getNatureUnitCount(cUnitTypeFishResource) > 0;
   if ((gMapInfo.mHasWater == true || gMapInfo.mStartOnDifferentIslands == true) && gMapInfo.mIsNomadMap == false)
   {
      analyseNavalPositions(kbAreaGetIDByPosition(baseVec));
   }

   // Can't block all our buildings on Tiny.
   if (cRandomMapName == "tiny")
   {
      aiSetMilitaryGatherPointBlocksBP(false);
   }

   // Sum it all up
   gMapInfo.displayMapInfo();
   return true;
}