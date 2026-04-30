void villagerTrainedHandlerHelper(int unitID = -1)
{
   boSystem.villagers.add(unitID);
   boSystem.numVillagers++;
   boSystem.nextUpdate = xsGetTime();
}

void internalBOVillagerTrained(int unitID = -1)
{
   debugBOStep("currentVillagerStep: " + boSystem.currentVillagerStep + " to determine Villager assignment.");
   villagerTrainedHandlerHelper(unitID);
   // Skip all resource assignment during Deathmatch.
   if (cGameModeCurrent == cGameModeDeathmatch)
   {
      if (cMyCulture == cCultureAtlantean)
      {
         createSimpleResearchPlanSpecificResearcher(cTechVillagerAtlanteanToHero, unitID);
         // Tricky fixup. The maintain plans set their amount to maintain based on a kbUnitCount of the unitType we want to train.
         // But since we heroize all Citizens this count will be 0 and then +1 for new Citizen.
         // Now if we heroize this new Citizen the maintain plan still thinks it needs to train 1 since the regular Citizen is gone.
         // To prevent the plan queuing another Citizen we must decrement the amount to maintain by 1.
         int currentAmount = aiPlanGetVariableInt(boSystem.maintainPlans[0], cTrainPlanNumberToMaintain, 0);
         aiPlanSetVariableInt(boSystem.maintainPlans[0], cTrainPlanNumberToMaintain, 0, currentAmount - 1);
      }
      return;
   }
   BOStep order = boSystem.buildOrderSteps[boSystem.currentVillagerStep];
   int[] gatherPlans = boSystem.currentGatherPlans;
   int resourceType = order.params[cBOStepVillagerResourceType];
   switch(resourceType)
   {
      case cResourceFood:
      {
         boSystem.foodVillagers++;
         break;
      }
      case cResourceWood:
      {
         boSystem.woodVillagers++;
         break;
      }
      case cResourceGold:
      {
         boSystem.goldVillagers++;
         break;
      }
      case cResourceFavor:
      {
         boSystem.favorVillagers++;
         break;
      }
   }
   internalSetVillagerDistribution(boSystem.foodVillagers, boSystem.woodVillagers, boSystem.goldVillagers, boSystem.favorVillagers);
   int planID = gatherPlans[resourceType];
   aiPlanAddUnitType(planID, kbUnitGetProtoUnitID(unitID), 1, 1, 1, true);
   debugBOStep("Assigning newly trained Villager: " + unitID + ", to resource: " + kbGetResourceName(resourceType) + 
               ", planID: " + planID);
   aiPlanAddUnit(planID, unitID);

   // If we're adding to a gather plan that has a child build plan for a dropsite, we loan it to that plan.
   int numChildren = aiPlanGetNumberChildren(planID);
   if (numChildren > 0)
   {
      for (int i = 0; i < numChildren; i++)
      {
         int childID = aiPlanGetChildIDByIndex(planID, i);
         if (aiPlanGetType(childID) == cPlanBuild)
         {
            int puid = aiPlanGetVariableInt(childID, cBuildPlanBuildingTypeID, 0);
            if (kbProtoUnitIsType(puid, cUnitTypeDropsite) == true)
            {
               debugBOStep("Loaning newly trainined Villager: " + unitID + " to child build plan: " + aiPlanGetName(childID) + ".");
               aiPlanAddUnit(childID, unitID, true);
               break;
            }
         }
      }
   }
}

void internalBOBuildComplete(int buildPlanID = -1)
{
   int planState = aiPlanGetState(buildPlanID);
   if (planState == cPlanStateFailed)
   {
      int buildingTypeID = aiPlanGetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0);
      // This plan could've failed after the BO was already done.
      if (isBuildOrderDone() == false)
      {
         aiEcho("Our build plan for " + kbProtoUnitGetName(buildingTypeID) + " failed, we will end BO.");
         internalBODoEndStep();
      }
      return;
   }
}

void internalBOBerserkHouseCompleted(int buildPlanID = -1)
{
   int planState = aiPlanGetState(buildPlanID);
   if (planState == cPlanStateFailed)
   {
      int buildingTypeID = aiPlanGetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0);
      // This plan could've failed after the BO was already done.
      if (isBuildOrderDone() == false)
      {
         aiEcho("Our build plan for " + kbProtoUnitGetName(buildingTypeID) + " failed, we will end BO.");
         internalBODoEndStep();
      }
      return;
   }
   else if (planState == cPlanStateDone)
   {
      debugBO("Starting explore plan for our Berserk.");
      int planID = aiPlanCreate("BOExplore: " + kbProtoUnitGetName(cUnitTypeBerserk), cPlanExplore, -1, gExplorationCategoryID);
      aiPlanSetVariableBool(planID, cExplorePlanDoLoops, 0, true);
      aiPlanSetVariableInt(planID, cExplorePlanNumberOfLoops, 0, 4);
      aiPlanSetVariableVector(planID, cExplorePlanLoopStartPoint, 0, boSystem.mainBasePosition);
      aiPlanAddUnitType(planID, cUnitTypeBerserk, 1, 1, 1);
      // Can fully assume the Berserk is alive now.
      aiPlanAddUnit(planID, getUnit(cUnitTypeBerserk));
      xsEnableRule("returnBerserkForTemple");
   }
}

void internalBOBuildDropsiteComplete(int buildPlanID = -1)
{
   if (isBuildOrderDone() == true)
   {
      return;
   }
   int planState = aiPlanGetState(buildPlanID);
   if (planState == cPlanStateFailed)
   {
      int buildingTypeID = aiPlanGetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0);
      float currentBufferSpace = kbBuildingPlacementGetBufferSpace(aiPlanGetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0));
      if (currentBufferSpace < 1.0)
      {
         aiEcho(kbProtoUnitGetName(buildingTypeID) + " build plan failed, it was already at 0.0 buffer space, ending BO now.");
         internalBODoEndStep();
         return;
      }
      float newBufferSpace = currentBufferSpace - 1.0;
      debugBOStep(kbProtoUnitGetName(buildingTypeID) + " build plan failed, starting another one now with " + newBufferSpace +
         " bufferspace .");

      int parentPlanID = aiPlanGetParentID(buildPlanID);
      int planID = aiPlanCreate("BOBuild: " + kbProtoUnitGetName(buildingTypeID), cPlanBuild, parentPlanID, gBuildingsCategoryID);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, buildingTypeID);

      // The units are at this point not back at their parent, but still in the previous build plan.
      int[] builderPUIDs = aiPlanGetUnitTypes(buildPlanID);
      int firstUnitID = -1;
      for (int i = 0; i < builderPUIDs.size(); i++)
      {
         int numUnits = aiPlanGetNumberNeededUnits(buildPlanID, builderPUIDs[i]);
         for (int iUnit = 0; iUnit < numUnits; iUnit++)
         {
            int unitID = aiPlanGetUnitIDByIndex(buildPlanID, iUnit);
            if (firstUnitID == -1)
            {
               firstUnitID = unitID;
            }
            // Remove from the build plan otherwise we loan it from that plan to the new build plan which goes wrong.
            aiPlanRemoveUnit(buildPlanID, unitID);
            aiPlanAddUnit(planID, unitID, true);
         }
      }
      if (firstUnitID == -1)
      {
         aiEcho(kbProtoUnitGetName(buildingTypeID) + " build plan failed, and it has no units assigned to it so can't start another plan.");
         aiPlanDestroy(planID);
         internalBODoEndStep();
         return;
      }

      int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID) + " " + newBufferSpace);
      kbBuildingPlacementSetBuildingPUID(bpID, aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0));
      aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
      
      int resourceType = aiPlanGetVariableInt(parentPlanID, cGatherPlanResourceType, 0);
      int kbResourceID = aiPlanGetVariableInt(parentPlanID, cGatherPlanKBResourceID, 0);
      // Determine where to actually build.
      if (resourceType == cResourceGold)
      {
         calculateGoldDropsitePlacement(planID, bpID, kbResourceID);
      }
      else if (resourceType == cResourceWood)
      {
         calculateWoodDropsitePlacement(planID, bpID, kbResourceID);
      }
      else // Food.
      {
         calculateFoodDropsitePlacement(planID, bpID, kbResourceID);
      }

      kbBuildingPlacementSetBufferSpace(bpID, newBufferSpace);
      aiPlanSetVariableInt(planID, cBuildPlanMaxRetries, 0, 0);

      // Set handler to ourself again for a potential retry with 0.0 bufferspace.
      aiPlanSetEventHandler(planID, cPlanEventStateChange, "internalBOBuildDropsiteComplete");
   }
   else if (planState == cPlanStateDone)
   {
      // We must sort the resource manually here since the parent gather plan won't do it during BO.
      int parentPlanID = aiPlanGetParentID(buildPlanID);
      int newDropsiteID = aiPlanGetVariableInt(buildPlanID, cBuildPlanFoundationID, 0);
      int kbResourceID = aiPlanGetVariableInt(parentPlanID, cGatherPlanKBResourceID, 0);
      kbResourceSortTowardsPosition(kbResourceID, kbUnitGetPosition(newDropsiteID));
   }
}

void internalBOBuildManorComplete(int buildPlanID = -1)
{
   if (isBuildOrderDone() == true)
   {
      return;
   }
   int planState = aiPlanGetState(buildPlanID);
   if (planState == cPlanStateFailed)
   {
      float currentBufferSpace = kbBuildingPlacementGetBufferSpace(aiPlanGetVariableInt(buildPlanID, cBuildPlanBuildingPlacementID, 0));
      if (currentBufferSpace < 1.0)
      {
         aiEcho("Manor build plan failed, it was already at 0.0 buffer space, ending BO now.");
         internalBODoEndStep();
         return;
      }
      float newBufferSpace = currentBufferSpace - 1.0;
      debugBOStep("Manor build plan failed, starting another one now with " + newBufferSpace +
         " bufferspace .");

      int parentPlanID = aiPlanGetParentID(buildPlanID);
      int planID = aiPlanCreate("BOBuild: Manor", cPlanBuild, parentPlanID, gBuildingsCategoryID);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypeManor);

      // The units are at this point not back at their parent, but still in the previous build plan.
      int[] builderPUIDs = aiPlanGetUnitTypes(buildPlanID);
      int firstUnitID = -1;
      for (int i = 0; i < builderPUIDs.size(); i++)
      {
         int numUnits = aiPlanGetNumberNeededUnits(buildPlanID, builderPUIDs[i]);
         for (int iUnit = 0; iUnit < numUnits; iUnit++)
         {
            int unitID = aiPlanGetUnitIDByIndex(buildPlanID, iUnit);
            if (firstUnitID == -1)
            {
               firstUnitID = unitID;
            }
            // Remove from the build plan otherwise we loan it from that plan to the new build plan which goes wrong.
            aiPlanRemoveUnit(buildPlanID, unitID);
            aiPlanAddUnit(planID, unitID, true);
         }
      }
      if (firstUnitID == -1)
      {
         aiEcho("Manor build plan failed, and it has no units assigned to it so can't start another plan.");
         internalBODoEndStep();
         return;
      }

      int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID) + " " + newBufferSpace);
      kbBuildingPlacementSetBuildingPUID(bpID, aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0));
      aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);

      // Making assumption here that the first unit is closely positioned towards the resource still.
      // Aka we're not taking the resource's position here because we don't have all the logic to determine proper placement here.
      kbBuildingPlacementSetCenterPosition(bpID, kbUnitGetPosition(firstUnitID), 14.0); // Big range, this should succeed.
      kbBuildingPlacementSetBufferSpace(bpID, newBufferSpace);
      aiPlanSetVariableInt(planID, cBuildPlanMaxRetries, 0, 0);

      // Set handler to ourself again for a potential retry with 0.0 bufferspace.
      aiPlanSetEventHandler(planID, cPlanEventStateChange, "internalBOBuildManorComplete");
   }
}

void internalBOUnitTrainedBlocking(int unitID = -1)
{
   debugBO("Unit trained: " + unitID + ", unblocking BO now!");
   boSystem.nextUpdate = xsGetTime();
}

void internalBOUnitTrained(int unitID = -1)
{
   debugBO("Unit trained: " + unitID);
}

void internalAdvanceCompleted(int planID = -1)
{
   if (aiPlanGetState(planID) == cPlanStateDone)
   {
      debugBO("Researched not blocking age up: " + kbTechGetName(aiPlanGetVariableInt(planID, cResearchPlanTechID, 0)));
      int currentAge = kbPlayerGetAge(cMyID);
      gAgeUpTimes[currentAge] = xsGetTime();
      if (cMyCulture != cCultureNorse)
      {
         // We want this rule active but it's a Classical age rule so it doesn't get auto activated upon age up cuz we're in BO.
         xsEnableRule("relicCollectionMonitor");
      }
      // Increase base size if we hit this for the first time.
      if (currentAge == cAge2)
      {
         kbBaseSetDistance(cMyID, boSystem.mainBaseID, 42.50);
      }
   }
}

void internalAdvanceCompletedBlocking(int planID = -1)
{
   if (aiPlanGetState(planID) == cPlanStateDone)
   {
      debugBO("Researched blocking age up: " + kbTechGetName(aiPlanGetVariableInt(planID, cResearchPlanTechID, 0))); 
      boSystem.nextUpdate = xsGetTime();
      int currentAge = kbPlayerGetAge(cMyID);
      gAgeUpTimes[currentAge] = xsGetTime();
      if (cMyCulture != cCultureNorse)
      {
         // We want this rule active but it's a Classical age rule so it doesn't get auto activated upon age up cuz we're in BO.
         xsEnableRule("relicCollectionMonitor");
      }
      // Increase base size if we hit this for the first time.
      if (currentAge == cAge2)
      {
         kbBaseSetDistance(cMyID, boSystem.mainBaseID, 42.50);
      }
   }
}

// These 3 are set in initBOSystem, but can't be found via direct name search.
void internalBOGoldResourceUpdate(int planID = -1)
{
   // Go back to the default placement for dropsites already now.
   if (cMyCulture != cCultureNorse && cMyCulture != cCultureAtlantean)
   {
      aiPlanSetVariableBool(planID, cGatherPlanAutoBuildDropsite, 0, true);
   }
}

void internalBOWoodResourceUpdate(int planID = -1)
{
   // If we're transitioning to Gaia Forest then don't run this.
   if (cMyCiv == cCivGaia && aiPlanGetVariableInt(planID, cGatherPlanKBResourceID, 0) != -1)
   {
      return;
   }
   debugBO("Resource depleted for plan: " + aiPlanGetName(planID) + ".");
   int kbResourceID = findBOWoodKBResource();
   if (kbResourceID == -1)
   {
      // We've failed the BO by now.
      return;
   }
   aiPlanSetVariableInt(planID, cGatherPlanKBResourceID, 0, kbResourceID);

   // Go back to the default placement for dropsites already now.
   if (cMyCulture != cCultureNorse && cMyCulture != cCultureAtlantean)
   {
      aiPlanSetVariableBool(planID, cGatherPlanAutoBuildDropsite, 0, true);
   }
}

void internalBOFoodResourceUpdate(int planID = -1)
{
   debugBO("Resource depleted for plan: " + aiPlanGetName(planID) + ".");
   int subType = -1;
   int kbResourceID = findBOFoodKBResource(subType, planID);
   if (kbResourceID == -1)
   {
      // We've failed the BO by now.
      return;
   }
   aiPlanSetVariableInt(planID, cGatherPlanKBResourceID, 0, kbResourceID);
   aiPlanSetVariableInt(planID, cGatherPlanResourceSubType, 0, subType);
  
   // Go back to the default placement for dropsites already now.
   if (cMyCulture != cCultureNorse && cMyCulture != cCultureAtlantean)
   {
      aiPlanSetVariableBool(planID, cGatherPlanAutoBuildDropsite, 0, true);
   }
}

void internalBOHouseChainDM(int buildPlanID = -1)
{
   if (isBuildOrderDone() == true)
   {
      return;
   }

   int planState = aiPlanGetState(buildPlanID);
   if (planState == cPlanStateFailed)
   {
      // This plan could've failed after the BO was already done.
      if (isBuildOrderDone() == false)
      {
         int buildingPUID = aiPlanGetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0);
         aiEcho("Our build plan for " + kbProtoUnitGetName(buildingPUID) + " failed, we will end BO.");
         internalBODoEndStep();
      }
      return;
   }
   else if (planState == cPlanStateDone)
   {
      int buildingPUID = aiPlanGetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0);
      if (cDifficultyCurrent <= cDifficultyHard)
      {
         int count = buildingGetNumberAliveAndPlanned(buildingPUID);
         if (cMyCulture == cCultureAtlantean)
         {
            count *= 2;
         }
         bool stop = false;
         if (cDifficultyCurrent == cDifficultyEasy && count >= 6)
         {
            stop = true;
         }
         else if (cDifficultyCurrent == cDifficultyModerate && count >= 8)
         {
            stop = true;
         }
         else if (cDifficultyCurrent == cDifficultyHard && count >= 10)
         {
            stop = true;
         }
         if (stop == true)
         {
            debugBO("We have enough houses for this difficulty, not chaining more.");
            return;
         }
      }
      int[] builderPUIDs = aiPlanGetUnitTypes(buildPlanID);
      debugBO("House plan finished, starting another one now as we're meant to chain Houses.");
      int planID = aiPlanCreate("BOBuild: " + kbProtoUnitGetName(buildingPUID), cPlanBuild, -1, gBuildingsCategoryID);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, buildingPUID);
      int numUnits = aiPlanGetNumberNeededUnits(buildPlanID, builderPUIDs[0]);
      aiPlanAddUnitType(planID, builderPUIDs[0], numUnits, numUnits, numUnits);
      for (int i = 0; i < numUnits; i++)
      {
         aiPlanAddUnit(planID, aiPlanGetUnitIDByIndex(buildPlanID, 0));
      }
      // Prevents these units being kicked out if we end BO and auto assignment takes over and we have no foundation yet.
      aiPlanSetFlag(planID, cPlanFlagReadyForUnits, true);

      int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
      kbBuildingPlacementSetBuildingPUID(bpID, buildingPUID);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
      avoidBlockingImportantSpots(planID, bpID);
      kbBuildingPlacementSetBufferSpace(bpID, 1.0); // Small buffer space, we just need speed...
      kbBuildingPlacementSetBaseID(bpID, boSystem.mainBaseID);
      aiPlanSetBaseID(planID, boSystem.mainBaseID);
      kbBuildingPlacementAddPositionInfluence(bpID, kbUnitGetPosition(aiPlanGetUnitIDByIndex(planID, 0)), 1000.0, 35.0, cFalloffLinear);

      // Overwrite any potential handlers that could be set in the building placement process.
      aiPlanSetEventHandler(planID, cPlanEventStateChange, "internalBOHouseChainDM");
   }
}

void internalBOOracleTrainedDM(int planID = -1)
{
   int planState = aiPlanGetState(planID);
   if (planState == cPlanStateDone)
   {
      int numVariables = aiPlanGetNumberVariableValues(planID, cTrainPlanTrainedUnitID);
      int unitID = aiPlanGetVariableInt(planID, cTrainPlanTrainedUnitID, numVariables -1);
      debugBO("Oracle trained: " + unitID + ", instantly heroizing it.");
      createSimpleResearchPlanSpecificResearcher(cTechOracleToHero, unitID);
   }
}