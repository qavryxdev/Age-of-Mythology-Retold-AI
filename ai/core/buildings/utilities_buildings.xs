//==============================================================================
/* utilities_buildings.xs

   This file is intended for picking the best spots to build a specific building.

*/
//==============================================================================

//==============================================================================
// avoidBlockingImportantSpots
//==============================================================================
void avoidBlockingImportantSpots(int buildPlanID = -1, int bpID = -1)
{
   /* We want to have certain restraints on our build plans in order to avoid blocking important spots.
      Mainly this means make sure we don't block our areas where we need to Farm, and don't box in gold mines.
   */
   debugBuildings(aiPlanGetName(buildPlanID) + ", avoiding important spots.");

   float halfObstruction = kbPlayerGetProtoStatFloat(cMyID, kbBuildingPlacementGetBuildingPUID(bpID), cProtoStatObstruction) / 2.0;

   // This distance means that buildings that are near the corners of a TC can still block Farms, but it's minimal impact.
   kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeAbstractTownCenter, -10000, 16.0 + halfObstruction, cFalloffNone);
   kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeSettlement, -10000, 16.0 + halfObstruction, cFalloffNone, -1, cPlayerMotherNatureID);
   // Avoid Granaries.
   kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeGranary, -10000, 10.0 + halfObstruction, cFalloffNone);
   // Avoid gold mines.
   kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeGoldResource, -10000, 8.0 + halfObstruction, cFalloffNone, -1, cPlayerMotherNatureID);
   // Avoid berry bushes.
   kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeBerryBush, -10000, 3.0 + halfObstruction, cFalloffNone, -1, cPlayerMotherNatureID);
}

//==============================================================================
// calculateHouseMonumentPlacement
//==============================================================================
void calculateHouseMonumentPlacement(int buildPlanID = -1, int bpID = -1, int baseID = -1, int resourceType = -1, int kbResourceID = -1)
{
   // If we're Atlantean we actually want to build our Manors as if we're building a dropsite if we have a resource ID.
   // Otherwise just randomly in the base, you can't wall in Towers with Manors and we want garrison spots everywhere.
   if (cMyCulture == cCultureAtlantean)
   {
      if (kbResourceID != -1)
      {
         if (resourceType == cResourceGold)
         {
            debugBuildings(aiPlanGetName(buildPlanID) + ", calculateHouseMonumentPlacement using gold dropsite placement.");
            calculateGoldDropsitePlacement(buildPlanID, bpID, kbResourceID, true);
         }
         else if (resourceType == cResourceWood)
         {
            debugBuildings(aiPlanGetName(buildPlanID) + ", calculateHouseMonumentPlacement using wood dropsite placement.");
            calculateWoodDropsitePlacement(buildPlanID, bpID, kbResourceID, true);
         }
         else // Food.
         {
            debugBuildings(aiPlanGetName(buildPlanID) + ", calculateHouseMonumentPlacement using food dropsite placement.");
            calculateFoodDropsitePlacement(buildPlanID, bpID, kbResourceID);
         }
      }
      else
      {
         debugBuildings(aiPlanGetName(buildPlanID) + ", going to use standard base placement.");
         kbBuildingPlacementSetBaseID(bpID, baseID);
         kbBuildingPlacementSetBufferSpace(bpID, 3.0);
         avoidBlockingImportantSpots(buildPlanID, bpID);
      }
      return;
   }

   static int towerQueryID = -1;
   static int mirrorTowerQueryID = -1;
   if (towerQueryID == -1)
   {
      towerQueryID = kbUnitQueryCreate("Tower House Query");
      kbUnitQuerySetUnitType(towerQueryID, cUnitTypeSentryTower);
      kbUnitQuerySetPlayerID(towerQueryID, cMyID, false);
      kbUnitQuerySetState(towerQueryID, cUnitStateABQ);

      mirrorTowerQueryID = kbUnitQueryCreate("Mirror Tower House Query");
      kbUnitQuerySetUnitType(mirrorTowerQueryID, cUnitTypeMirrorTower);
      kbUnitQuerySetPlayerID(mirrorTowerQueryID, cMyID, false);
      kbUnitQuerySetState(mirrorTowerQueryID, cUnitStateABQ);
   }
   kbUnitQuerySetBaseID(towerQueryID, baseID);
   kbUnitQueryResetResults(towerQueryID);
   kbUnitQuerySetBaseID(mirrorTowerQueryID, baseID);
   kbUnitQueryResetResults(mirrorTowerQueryID);

   int numResults = kbUnitQueryExecute(towerQueryID) + kbUnitQueryExecute(mirrorTowerQueryID);
   debugBuildings(aiPlanGetName(buildPlanID) + ", calculateHouseMonumentPlacement - number (Mirror)Towers found in base: " + numResults);
   if (numResults > 0)
   {
      // We now know we have at least 1 (Mirror)Tower in the provided base.
      // Now we need to figure out if that (Mirror)Tower isn't already obstructed.
      // And if we have a resourceID we should try building around the closest (Mirror)tower.
      int[] queryResults = kbUnitQueryGetResults(towerQueryID);
      vector militaryGatherPoint = kbBaseGetMilitaryGatherPoint(cMyID, baseID);
      const float mgpExclusionRange = 10.0;
      for (int i = 0; i < queryResults.size(); i++)
      {
         vector unitPosition = kbUnitGetPosition(queryResults[i]);
         if (getUnitCountByLocation(cUnitTypeBuilding, cPlayerRelationAny, cUnitStateABQ, unitPosition, 8.0) >= 4)
         {
            // We assume that if there are already 4 buildings/foundations within 8 range of the Tower it will most likely
            // be blocked from perfect placement.
            debugBuildings(aiPlanGetName(buildPlanID) + ", calculateHouseMonumentPlacement - Tower: " + queryResults[i] +
               " is most likely obstructed and will be skipped.");
            queryResults.removeIndex(i);
            i--;
            continue;
         }
         if (xsVectorDistanceXZ(unitPosition, militaryGatherPoint) < mgpExclusionRange)
         {
            debugBuildings(aiPlanGetName(buildPlanID) + ", calculateHouseMonumentPlacement - Tower: " + queryResults[i] +
               " is too close to our Military Gather Point and will be skipped.");
            queryResults.removeIndex(i);
            i--;
            continue;
         }
      }

      int[] mirrorQueryResults = kbUnitQueryGetResults(mirrorTowerQueryID);
      for (int i = 0; i < mirrorQueryResults.size(); i++)
      {
         if (getUnitCountByLocation(cUnitTypeBuilding, cPlayerRelationAny, cUnitStateABQ,kbUnitGetPosition(mirrorQueryResults[i]), 8.0) >= 4)
         {
            // We assume that if there are already 4 buildings/foundations within 8 range of the Tower it will most likely
            // be blocked from perfect placement.
            debugBuildings(aiPlanGetName(buildPlanID) + ", calculateHouseMonumentPlacement - Mirror Tower: "
               + mirrorQueryResults[i] + " is most likely obstructed and will be skipped.");
            mirrorQueryResults.removeIndex(i);
            i--;
         }
         else
         {
            queryResults.add(mirrorQueryResults[i]);
         }
      }

      if (queryResults.size() == 0)
      {
         debugBuildings(aiPlanGetName(buildPlanID) + ", All (Mirror)Towers were skipped, just building in base now.");
         kbBuildingPlacementSetBaseID(bpID, baseID);
         kbBuildingPlacementSetBufferSpace(bpID, 3.0);
         avoidBlockingImportantSpots(buildPlanID, bpID);
         return;
      }

      // We default this to index 0 of our remaining Towers.
      // If we have a resource we can overwrite this still.
      vector closestTowerLocation = kbUnitGetPosition(queryResults[0]);
      if (kbResourceID != -1)
      {
         vector resourceLocation = kbResourceGetPosition(kbResourceID);
         float closestLength = 100000.0;
         int closestTowerID = -1;
         for (int i = 0; i < queryResults.size(); i++)
         {
            int towerID = queryResults[i];
            vector towerLocation = kbUnitGetPosition(towerID);
            float length = xsVectorLength(resourceLocation - towerLocation);
            if (length < closestLength)
            {
               closestLength = length;
               closestTowerID = towerID;
               closestTowerLocation = towerLocation;
            }
         }
         debugBuildings(aiPlanGetName(buildPlanID) + ", calculateHouseMonumentPlacement - Calculated that (Mirror)Tower: " +
            closestTowerID + " is our closest (Mirror)Tower to our resource.");
      }
      else
      {
         debugBuildings("No kbResourceID was given, can't sort our Towers towards a position now.");
      }

      kbBuildingPlacementSetCenterPosition(bpID, closestTowerLocation, 10.0);
      kbBuildingPlacementSetStepSize(bpID, 1.0);
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);

      // Build around the Tower.
      kbBuildingPlacementAddPositionInfluence(bpID, closestTowerLocation, 100.0, 200.0, cFalloffLinear);

      // Avoid trees and wood dropsites.
      kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeWoodResource, -10000, 10.0, cFalloffLinear, -1, cPlayerMotherNatureID);
      kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeWoodDropsite, -1000, 6.0, cFalloffLinear);

      avoidBlockingImportantSpots(buildPlanID, bpID);
      aiPlanSetEventHandler(buildPlanID, cPlanEventStateChange, "houseMonumentBuildEventHandler");
   }
   else
   {
      debugBuildings(aiPlanGetName(buildPlanID) + ", going to use standard base placement now.");
      kbBuildingPlacementSetBaseID(bpID, baseID);
      kbBuildingPlacementSetBufferSpace(bpID, 3.0);
      avoidBlockingImportantSpots(buildPlanID, bpID);
   }
}

//==============================================================================
// calculateMilitaryBuildingplacement
//==============================================================================
void calculateMilitaryBuildingplacement(int buildPlanID = -1, int bpID = -1, int baseID = -1)
{
   kbBuildingPlacementSetBufferSpace(bpID, 3.0);

   // Build most of the military buildings forward, not all to prevent overcrowding.
   bool forward = xsRandBool();
   bool isFortress = kbBuildingPlacementGetBuildingPUID(bpID) == gFortressUnit;
   if (forward == true || isFortress == true) // Fortress always forward.
   {
      debugBuildings(aiPlanGetName(buildPlanID) + ", going to build this military building forward.");
      kbBuildingPlacementSetBaseID(bpID, baseID, cBuildingPlacementOrientationPreferenceFront);
      if (isFortress == true)
      {
         // Since we normally build these quite late they can get pushed really far out which isn't ideal.
         // Our entire base at this point is already 3.0 buffer space. We can allow 1 building to be 1.0 and hopefully still be fine.
         kbBuildingPlacementSetBufferSpace(bpID, 1.0);
      }
   }
   else
   {
      debugBuildings(aiPlanGetName(buildPlanID) + ", NOT going to build this military building forward.");
      kbBuildingPlacementSetBaseID(bpID, baseID, cBuildingPlacementOrientationPreferenceNone);
   }
   
   // Close to a tower at a forward location would be nice.
   kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeSentryTower, 150, 15.0, cFalloffLinear);
   kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeMirrorTower, 150, 15.0, cFalloffLinear);

   avoidBlockingImportantSpots(buildPlanID, bpID);
}

//==============================================================================
// calculateFarmPlacement
//==============================================================================
void calculateFarmPlacement(int buildPlanID = -1, int bpID = -1, int baseID = -1)
{
   if (gFarmPlacementOverrideUsed == false)
   {
      debugBuildings(aiPlanGetName(buildPlanID) + ", calculateFarmPlacement NO Farm placement override used.");
      kbBuildingPlacementSetBaseID(bpID, baseID);
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeAbstractTownCenter, 2500, 16.0, cFalloffLinear);
      kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeGranary, 600, 10.0, cFalloffLinear);
      aiPlanSetVariableBool(buildPlanID, cBuildPlanDoneWhenFoundationPlaced, 0, true);

      // To prevent all our Farm plans finding the same spot we must do some random positional influences close to our dropsites.
      static int tcQueryID = -1;
      static int granaryQueryID = -1;
      static vector[] offsetsTC = default;
      static vector[] offsetsGranary = default;
      if (tcQueryID == -1)
      {
         tcQueryID = kbUnitQueryCreate("calculateFarmPlacement TC");
         kbUnitQuerySetPlayerID(tcQueryID, cMyID);
         kbUnitQuerySetUnitType(tcQueryID, cUnitTypeAbstractTownCenter);
         kbUnitQuerySetState(tcQueryID, cUnitStateABQ);

         granaryQueryID = kbUnitQueryCreate("calculateFarmPlacement Granary");
         kbUnitQuerySetPlayerID(granaryQueryID, cMyID);
         kbUnitQuerySetUnitType(granaryQueryID, cUnitTypeGranary);
         kbUnitQuerySetState(granaryQueryID, cUnitStateABQ);

         offsetsTC = new vector(8, cInvalidVector);
         offsetsGranary = new vector(8, cInvalidVector);

         float spacing = 4.0;
         float halfObstruction = kbPlayerGetProtoStatFloat(cMyID, cUnitTypeTownCenter, cProtoStatObstruction) / 2.0;
         offsetsTC[0] = vector(halfObstruction + spacing, 0.0, halfObstruction + spacing);
         offsetsTC[1] = vector(halfObstruction + spacing, 0.0, -halfObstruction - spacing);
         offsetsTC[2] = vector(-halfObstruction - spacing, 0.0, halfObstruction + spacing);
         offsetsTC[3] = vector(-halfObstruction - spacing, 0.0, -halfObstruction - spacing);
         offsetsTC[4] = vector(0.0, 0.0, halfObstruction + spacing);
         offsetsTC[5] = vector(0.0, 0.0, -halfObstruction - spacing);
         offsetsTC[6] = vector(halfObstruction + spacing, 0.0, 0.0);
         offsetsTC[7] = vector(-halfObstruction - spacing, 0.0, 0.0);

         halfObstruction = kbPlayerGetProtoStatFloat(cMyID, cUnitTypeGranary, cProtoStatObstruction) / 2.0;
         offsetsGranary[0] = vector(halfObstruction + spacing, 0.0, halfObstruction + spacing);
         offsetsGranary[1] = vector(halfObstruction + spacing, 0.0, -halfObstruction - spacing);
         offsetsGranary[2] = vector(-halfObstruction - spacing, 0.0, halfObstruction + spacing);
         offsetsGranary[3] = vector(-halfObstruction - spacing, 0.0, -halfObstruction - spacing);
         offsetsGranary[4] = vector(0.0, 0.0, halfObstruction + spacing);
         offsetsGranary[5] = vector(0.0, 0.0, -halfObstruction - spacing);
         offsetsGranary[6] = vector(halfObstruction + spacing, 0.0, 0.0);
         offsetsGranary[7] = vector(-halfObstruction - spacing, 0.0, 0.0);
      }
      kbUnitQuerySetBaseID(tcQueryID, baseID);
      kbUnitQuerySetBaseID(granaryQueryID, baseID);
      kbUnitQueryResetResults(tcQueryID);
      kbUnitQueryResetResults(granaryQueryID);
      int numResults = kbUnitQueryExecute(tcQueryID);
      int[] results = kbUnitQueryGetResults(tcQueryID);
      for (int i = 0; i < numResults; i++)
      {
         vector offset = offsetsTC[xsRandInt(0, 7)];
         kbBuildingPlacementAddPositionInfluence(bpID, kbUnitGetPosition(results[i]) + offset, xsRandFloat(1300, 1700), 3.0, cFalloffLinear);
      }

      numResults = kbUnitQueryExecute(granaryQueryID);
      results = kbUnitQueryGetResults(granaryQueryID);
      for (int i = 0; i < numResults; i++)
      {
         vector offset = offsetsGranary[xsRandInt(0, 7)];
         kbBuildingPlacementAddPositionInfluence(bpID, kbUnitGetPosition(results[i]) + offset, xsRandFloat(500, 900), 3.0, cFalloffLinear);
      }
   }
   else
   {
      debugBuildings(aiPlanGetName(buildPlanID) + ", determineBuildingPlacementLogic Farm placement override used.");
      gFarmPlacementOverride(buildPlanID, bpID, baseID);
   }
}

//==============================================================================
// calculateDefaultNumberBuilders
//==============================================================================
int calculateDefaultNumberBuilders(int buildingPUID = -1, int builderPUID = -1)
{
   // If we didn't get a specified builder we must make a very educated guess.
   if (builderPUID == -1)
   {
      switch (cMyCulture)
      {
         case cCultureGreek:
         {
            builderPUID = cUnitTypeVillagerGreek;
         }
         case cCultureEgyptian:
         {
            builderPUID = cUnitTypeVillagerEgyptian;
         }
         case cCultureNorse:
         {
            if (buildingPUID == cUnitTypeHouse || buildingPUID == cUnitTypeOxCartBuilding || buildingPUID == gFarmUnit)
            {
               // Just take the Villager's workrate, not Dwarf.
               builderPUID = cUnitTypeVillagerNorse;
            }
            else
            {
               // Just take the Berserk's workrate.
               builderPUID = cUnitTypeBerserk;
            }
         }
         case cCultureAtlantean:
         {
            builderPUID = cUnitTypeVillagerAtlantean;
         }
      }
   }

   float buildPoints = kbPlayerGetProtoStatFloat(cMyID, buildingPUID, cProtoStatBuildPoints);
   float buildRate = kbPlayerGetProtoStatFloat(cMyID, builderPUID, cProtoStatBuildRate);
   float baseBuildRate = buildRate;
   float buildingEfficiency = kbPlayerGetBuildingEfficiency(cMyID);
   if (buildingEfficiency <= 0.0)
   {
      // Modders can put buildingEfficiency on 0.0 so we support that here.
      return 1;
   }
   if (buildPoints <= 0.0 || buildRate <= 0.0)
   {
      aiEchoWarning("calculateDefaultNumberBuilders - buildpoints (" +  buildPoints + ") and/or buildRate (" + buildRate + ") " +
                   "is negative. We're calling this utility function wrongly!");
      return 1;
   }

   int numberBuilders = 1;
   int numberExtraBuilders = 0;
   // We try to build everything sub 25 seconds.
   while (buildPoints / buildRate > 25)
   {
      numberExtraBuilders++;
      buildRate = baseBuildRate + (baseBuildRate * buildingEfficiency * numberExtraBuilders);
      // We don't want to disturb our eco too much with an insane amount of builders.
      if (numberExtraBuilders >= 9)
      {
         break;
      }
   }
   debugBuildings("calculateDefaultNumberBuilders returned: " + (numberBuilders + numberExtraBuilders));
   return numberBuilders + numberExtraBuilders;
}

//==============================================================================
// addBuilderTypesToPlan
//==============================================================================
void addBuilderTypesToPlan(int planID = -1, int puid = -1, int numberBuilders = 1, bool neededUnitsEqualsNumberBuilders = false)
{
   int builderType = cUnitTypeAbstractVillager;

   if (cMyCulture == cCultureNorse)
   {
      if (puid != cUnitTypeHouse && puid != cUnitTypeOxCartBuilding && puid != gFarmUnit)
      {
         builderType = cUnitTypeLogicalTypeNorseSoldierThatBuilds;
      }
   }

   if (numberBuilders == cCalculateNumBuildersAutomatically)
   {
      numberBuilders = calculateDefaultNumberBuilders(puid, -1);
   }
   aiPlanAddUnitType(planID, builderType, neededUnitsEqualsNumberBuilders == true ? numberBuilders : 1, numberBuilders, numberBuilders);
}

//==============================================================================
// determineBuildingPlacementLogic
//==============================================================================
bool determineBuildingPlacementLogic(int buildPlanID = -1, int bpID = -1, int baseID = -1, int resourceType = -1, int kbResourceID = -1)
{
   bool result = true;
   if (kbBaseGetIsIDValid(cMyID, baseID) == true)
   {
      aiPlanSetBaseID(buildPlanID, baseID);
   }
   int buildingPUID = kbBuildingPlacementGetBuildingPUID(bpID);
   int numMilitaryBuildings = gMilitaryBuildings.size();
   bool isMilitaryBuilding = false;
   for (int i = 0; i < numMilitaryBuildings; i++)
   {
      if (buildingPUID == gMilitaryBuildings[i])
      {
         isMilitaryBuilding = true;
         break;
      }
   }
   if (buildingPUID == cUnitTypeTemple)
   {
      isMilitaryBuilding = true;
   }

   bool isHouseOrMonument = false;
   if (buildingPUID == gHouseUnit ||
       buildingPUID == cUnitTypeMonumentToVillagers ||
       buildingPUID == cUnitTypeMonumentToSoldiers ||
       buildingPUID == cUnitTypeMonumentToPriests ||
       buildingPUID == cUnitTypeMonumentToPharaohs ||
       buildingPUID == cUnitTypeMonumentToGods)
   {
      isHouseOrMonument = true;
   }

   if (isHouseOrMonument == true && cDifficultyCurrent >= cDifficultyHard && baseID != -1)
   {
      debugBuildings(aiPlanGetName(buildPlanID) + ", determineBuildingPlacementLogic decided we use House or Monument placement.");
      calculateHouseMonumentPlacement(buildPlanID, bpID, baseID, resourceType, kbResourceID);
   }
   else if (buildingPUID == cUnitTypeOxCartBuilding && resourceType != -1) // We can just build this not next to the resource too.
   {
      switch (resourceType)
      {
         case cResourceFood:
         {
            debugBuildings(aiPlanGetName(buildPlanID) + ", determineBuildingPlacementLogic decided we use food dropsite placement.");
            calculateFoodDropsitePlacement(buildPlanID, bpID, kbResourceID);
            break;
         }
         case cResourceWood:
         {
            debugBuildings(aiPlanGetName(buildPlanID) + ", determineBuildingPlacementLogic decided we use wood dropsite placement.");
            calculateWoodDropsitePlacement(buildPlanID, bpID, kbResourceID);
            break;
         }
         case cResourceGold:
         {
            debugBuildings(aiPlanGetName(buildPlanID) + ", determineBuildingPlacementLogic decided we use gold dropsite placement.");
            calculateGoldDropsitePlacement(buildPlanID, bpID, kbResourceID);
            break;
         }
         default:
         {
            aiEchoWarning(aiPlanGetName(buildPlanID) + " Calling determineBuildingPlacementLogic for an Ox Cart Building with " +
               "an unsupported resourceType.");
            break;
         }
      }
   }
   else if (isMilitaryBuilding == true)
   {
      debugBuildings(aiPlanGetName(buildPlanID) + ", determineBuildingPlacementLogic decided we use military building placement.");
      calculateMilitaryBuildingplacement(buildPlanID, bpID, baseID);
   }
   else if (buildingPUID == cUnitTypeDock)
   {
      aiEchoWarning("Calling determineBuildingPlacementLogic for a Dock, this is not supported.");
      result = false;
   }
   else if (buildingPUID == gFarmUnit)
   {
      debugBuildings(aiPlanGetName(buildPlanID) + ", determineBuildingPlacementLogic decided we use Farm placement.");
      calculateFarmPlacement(buildPlanID, bpID, baseID);
   }
   else if (buildingPUID == cUnitTypeTownCenter)
   {
      aiEchoWarning("Calling determineBuildingPlacementLogic for a Town Center, this isn't supported!");
      result = false;
   }
   else // We do this logic if we have something not handled above.
   {
      debugBuildings(aiPlanGetName(buildPlanID) + ", determineBuildingPlacementLogic no specific logic used.");
      if (baseID != -1)
      {
         kbBuildingPlacementSetBaseID(bpID, baseID);
      }
      else
      {
         int randomTCBaseID = getRandomTownCenterBaseID();
         if (randomTCBaseID == -1)
         {
            debugBuildings(aiPlanGetName(buildPlanID) + ", no TC bases available, can't build with this setup.");
            aiPlanDestroy(buildPlanID);
            return false;
         }
         kbBuildingPlacementSetBaseID(bpID, baseID);
      }
      avoidBlockingImportantSpots(buildPlanID, bpID);
      kbBuildingPlacementSetBufferSpace(bpID, 3.0);
      if (isBuildOrderDone() == false)
      {
         // Influence towards the unit we assigned to this plan, to limit walking time.
         if (aiPlanGetNumberUnits(buildPlanID) >= 1)
         {
            int unitID = aiPlanGetUnitIDByIndex(buildPlanID, 0);
            vector influencePosition = kbUnitGetPosition(unitID); 
            kbBuildingPlacementAddPositionInfluence(bpID, influencePosition, 100.0, 100.0, cFalloffLinear);
            debugBuildings("BO is not yet done so adding an influence towards the assigned builder.");
         }
      }
   }

   return result;
}

//==============================================================================
//==============================================================================
//==============================================================================
//==============================================================================
// ACTUAL BUILD PLAN CREATION.
//==============================================================================
//==============================================================================
//==============================================================================
//==============================================================================

//==============================================================================
// createSimpleBuildPlan
// Does all the necessary set up to get a valid build plan at the position we want.
// It returns the plan ID of the last made plan (in the case of multiple plans in 1 go).
//==============================================================================
int createSimpleBuildPlan(int puid = -1, int numberWanted = 1, int prio = 50, int baseID = -1,
   int numberBuilders = cCalculateNumBuildersAutomatically, int parentPlanID = -1)
{
   if (numberWanted <= 0)
   {
      aiEchoWarning("Calling createSimpleBuildPlan with an invalid numberWanted: " + numberWanted + ", for puid: " + 
         kbProtoUnitGetName(puid) + ".");
      return -1;
   }
   int planID = -1;
   int bpID = -1;

   // Create the right number of plans.
   for (int i = 0; i < numberWanted; i++)
   {
      planID = aiPlanCreate("Build Plan for " + numberWanted + " " + kbProtoUnitGetName(puid), cPlanBuild, parentPlanID,
                            gBuildingsCategoryID);
      if (aiPlanGetIsIDValid(planID) == false) // We somehow failed to create a plan.
      {
         return (-1);
      }

      // Building Placement.
      bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
      kbBuildingPlacementSetBuildingPUID(bpID, puid);
      determineBuildingPlacementLogic(planID, bpID, baseID);

      // Plan.
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, puid);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetPriority(planID, prio);
      // Add builders to the plan if that is requested.
      // This only adds the needed/wanted/minimum variables of the unittype to the plan not the actual builders.
      if (numberBuilders > 0)
      {
         addBuilderTypesToPlan(planID, puid, numberBuilders);
      }
      debugBuildings("Created a Build Plan for: " + numberWanted + " " + kbProtoUnitGetName(puid) + " with planID: " + planID);
   }
   return (planID); // Only really useful if numberWanted == 1, otherwise returns last plan ID.
}

//==============================================================================
// createLocationBuildPlan
// Todo add baseID
//==============================================================================
int createLocationBuildPlan(int puid = -1, int numberWanted = 1, int prio = 50, vector position = cInvalidVector,
   float centerPositionDistance = 5.0, float bufferSpace = 0.0, float stepSize = 0.5, int numberBuilders = cCalculateNumBuildersAutomatically)
{
   if (numberWanted <= 0)
   {
      aiEchoWarning("Calling createLocationBuildPlan with an invalid numberWanted: " + numberWanted + ", for puid: " + 
         kbProtoUnitGetName(puid) + ".");
      return -1;
   }
   int planID = -1;
   int bpID = -1;

   // Create the right number of plans.
   for (int i = 0; i < numberWanted; i++)
   {
      planID = aiPlanCreate("Location Build Plan " + numberWanted + " " + kbProtoUnitGetName(puid), cPlanBuild, -1, gBuildingsCategoryID);
      if (aiPlanGetIsIDValid(planID) == false)
      {
         return (-1);
      }

      // Building Placement.
      bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
      kbBuildingPlacementSetBuildingPUID(bpID, puid);
      kbBuildingPlacementSetCenterPosition(bpID, position, centerPositionDistance);
      kbBuildingPlacementSetStepSize(bpID, stepSize);
      kbBuildingPlacementSetBufferSpace(bpID, bufferSpace);
      kbBuildingPlacementAddPositionInfluence(bpID, position, 200.0, centerPositionDistance, cFalloffLinear);

      // Plan.
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, puid);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetPriority(planID, prio);
      // Add builders to the plan if that is requested.
      // This only adds the needed/wanted/minimum variables of the unittype to the plan not the actual builders.
      if (numberBuilders > 0)
      {
         addBuilderTypesToPlan(planID, puid, numberBuilders);
      }

      debugBuildings("Created a Location Build Plan for: " + kbProtoUnitGetName(puid) + " with planID: " + planID);
   }
   return (planID); // Only really useful if numberWanted == 1, otherwise returns last value.
}

//==============================================================================
// createDockBuildPlan
// Todo add baseID
//==============================================================================
int createDockBuildPlan(vector landPosition = cInvalidVector, vector waterPosition = cInvalidVector, int numberWanted = 1, int prio = 50, 
   int numberBuilders = cCalculateNumBuildersAutomatically)
{
   if (numberWanted <= 0)
   {
      aiEchoWarning("Calling createDockBuildPlan with an invalid numberWanted: " + numberWanted + ".");
      return -1;
   }
   int planID = -1;
   int bpID = -1;

   // Create the right number of plans.
   for (int i = 0; i < numberWanted; i++)
   {
      planID = aiPlanCreate("Build Plan for " + numberWanted + " Dock", cPlanBuild, -1, gBuildingsCategoryID);
      if (aiPlanGetIsIDValid(planID) == false)
      {
         return (-1);
      }

      // Building Placement.
      bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeDock);
      kbBuildingPlacementSetDockPositions(bpID, landPosition, waterPosition);

      // Plan.
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypeDock);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetPriority(planID, prio);

      // Add builders to the plan if that is requested.
      // This only adds the needed/wanted/minimum variables of the unittype to the plan not the actual builders.
      if (numberBuilders > 0)
      {
         addBuilderTypesToPlan(planID, cUnitTypeDock, numberBuilders);
      }
      debugBuildings("Created a Dock Build Plan with planID: " + planID);
   }
   return (planID); // Only really useful if numberWanted == 1, otherwise returns last value.
}

//==============================================================================
// createSocketBuildPlan
//==============================================================================
int createSocketBuildPlan(int puid = -1, int socketID = -1, int prio = 50, int numberBuilders = cCalculateNumBuildersAutomatically, 
   bool neededUnitsEqualsNumberBuilders = false)
{
   int planID = aiPlanCreate("Build Plan for " + kbProtoUnitGetName(puid), cPlanBuild, -1, gBuildingsCategoryID);
   // Building Placement.
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
   kbBuildingPlacementSetBuildingPUID(bpID, puid);
   kbBuildingPlacementSetSocketID(bpID, socketID);
   // Plan.
   aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, puid);
   aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
   aiPlanSetPriority(planID, prio);
   // Add builders to the plan if that is requested.
   // This only adds the needed/wanted/minimum variables of the unittype to the plan not the actual builders.
   if (numberBuilders > 0)
   {
      addBuilderTypesToPlan(planID, puid, numberBuilders, neededUnitsEqualsNumberBuilders);
   }
   debugBuildings("Created a " + kbProtoUnitGetName(puid) + " Build Plan with planID: " + planID);
   return planID;
}