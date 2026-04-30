//==============================================================================
/* bo_system.xs

   This file contains all functions/rules that BO files can directly call, excluding DM.

*/
//==============================================================================

void boVillager(int villagerUnitType = -1, int villagerResourceType = -1, void(int) afterQueue = [](int id = -1) {})
{
   BOStep newStep;
   newStep.type = cBOStepTypeVillager;
   int[] params = new int(cBOStepVillagerNumParams, -1);
   params[cBOStepVillagerResourceType] = villagerResourceType;
   params[cBOStepVillagerUnitType] = villagerUnitType;
   newStep.params = params;

   newStep.onPlanCreate = afterQueue;
   internalBOAddOrder(newStep);
}

void boBuild(int buildingPUID = -1, int builderPUID = -1, int numBuilders = -1, void(int) onCreate = internalBOBuildDefaultCreate,
   string onCompleteHandler = "internalBOBuildComplete")
{
   BOStep newStep;
   newStep.type = cBOStepTypeBuild;
   int[] params = new int(cBOStepBuildNumParams, -1);
   params[cBOStepBuildPUID] = buildingPUID;
   params[cBOStepBuilderPUID] = builderPUID;
   params[cBOStepNumBuilders] = numBuilders;
   newStep.params = params;

   newStep.onPlanCreate = onCreate;
   newStep.onCompleteHandler = onCompleteHandler;
   internalBOAddOrder(newStep);
}

void boTech(int techID = -1, int researcherPUID = -1, string onCompleteHandler = "")
{
   BOStep newStep;
   newStep.type = cBOStepTypeTech;
   int[] params = new int(cBOStepTechNumParams, -1);
   params[cBOStepTechTechID] = techID;
   params[cBOStepTechResearcherPUID] = researcherPUID;
   newStep.params = params;

   newStep.onCompleteHandler = onCompleteHandler;
   internalBOAddOrder(newStep);
}

void boUnit(int puid = -1, int trainMode = 0, int amount = 1, int blocking = cBOStepNotBlocking, int trainerPUID = -1,
   void(int) onCreate = internalBOUnitDefaultCreate, string onCompleteHandler = "")
{
   BOStep newStep;
   newStep.type = cBOStepTypeUnit;
   int[] params = new int(cBOStepUnitNumParams, -1);
   params[cBOStepUnitBlocking] = blocking;
   params[cBOStepUnitPUID] = puid;
   params[cBOStepUnitAmount] = amount;
   params[cBOStepUnitTrainMode] = trainMode;
   params[cBOStepUnitTrainerPUID] = trainerPUID;
   newStep.params = params;

   newStep.onPlanCreate = onCreate;
   newStep.onCompleteHandler = onCompleteHandler;
   internalBOAddOrder(newStep);
}

void boTransaction(int villagerIndex = -1, int newResourceType = -1, void(int) onTransaction = [](int id = -1) {})
{
   BOStep newStep;
   newStep.type = cBOStepTypeTransaction;
   int[] params = new int(cBOStepTransactionNumParams, -1);
   params[cBOStepTransactionVillagerIndex] = villagerIndex;
   params[cBOStepTransactionNewResource] = newResourceType;
   newStep.params = params;

   newStep.onPlanCreate = onTransaction;
   internalBOAddOrder(newStep);
}

void boAdvance(int minorGodTechID = -1, int blocking = cBOStepBlocking, void(int) onCreate = [](int planID = -1) {})
{
   BOStep newStep;
   newStep.type = cBOStepTypeAdvance;
   int[] params = new int(cBOStepAdvanceNumParams, -1);
   params[cBOStepAdvanceBlocking] = blocking;
   params[cBOStepAdvanceMinorGodTechID] = minorGodTechID;
   newStep.params = params;

   newStep.onPlanCreate = onCreate;
   internalBOAddOrder(newStep);
}

void boEmpower(int targetPUID = -1, void(int) onCreate = internalBOEmpowerDefaultCreate)
{
   BOStep newStep;
   newStep.type = cBOStepTypeEmpower;
   int[] params = new int(cBOStepEmpowerNumParams, -1);
   params[cBOStepEmpowerTargetPUID] = targetPUID;
   newStep.params = params;

   newStep.onPlanCreate = onCreate;
   internalBOAddOrder(newStep);
}

void boExplore(int explorerPUID = -1, int searchShoreline = cBOStepDontSearchShoreline, int searchEnemy = cBOStepDontSearchEnemy,
   int loops = cBOStepDoLoops, int startingSurroundings = cBOStepDontScoutSurroundings,
   void(int) onCreate = internalBOExploreDefaultCreate, string onCompleteHandler = "")
{
   BOStep newStep;
   newStep.type = cBOStepTypeExplore;
   int[] params = new int(cBOStepExploreNumParams, -1);
   params[cBOStepExploreExplorerPUID] = explorerPUID;
   params[cBOStepExploreSearchShoreline] = searchShoreline;
   params[cBOStepExploreSearchEnemy] = searchEnemy;
   params[cBOStepExploreLoops] = loops;
   params[cBOStepExploreStartingSurroundings] = startingSurroundings;
   newStep.params = params;

   newStep.onPlanCreate = onCreate;
   newStep.onCompleteHandler = onCompleteHandler;
   internalBOAddOrder(newStep);
}

void boExecute(void(int) onExecute = [](int dummy = -1){})
{
   BOStep newStep;
   newStep.type = cBOStepTypeExecute;

   newStep.onPlanCreate = onExecute;
   internalBOAddOrder(newStep);
}

void boConditionalWait(bool() condition = []() -> bool { aiEchoWarning("boConditionalWait - no lambda provided."); return true; },
   int timeout = 60, int warning = cWarning)
{
   BOStep newStep;
   newStep.type = cBOStepTypeConditionalWait;
   int[] params = new int(cBOStepConditionalWaitNumParams, -1);
   params[cBOStepConditionalWaitTimeout] = timeout;
   params[cBOStepConditionalWarning] = warning;
   newStep.params = params;

   newStep.condition = condition;
   internalBOAddOrder(newStep);
}

void boWait(int waitTime = 0)
{
   BOStep newStep;
   newStep.type = cBOStepTypeWait;
   int[] params = new int(cBOStepWaitNumParams, -1);
   params[cBOStepWaitTime] = waitTime;
   newStep.params = params;

   internalBOAddOrder(newStep);
}

void boIncreaseTimeout(int increment = 0)
{
   BOStep newStep;
   newStep.type = cBOStepTypeTimeoutIncrease;
   int[] params = new int(cBOStepTimeoutIncreaseNumParams, -1);
   params[cBOStepTimeoutTime] = increment;
   newStep.params = params;

   internalBOAddOrder(newStep);
}

void boActivateRule(string ruleName = "")
{
   BOStep newStep;
   newStep.type = cBOStepTypeActivateRule;

   newStep.onCompleteHandler = ruleName;
   internalBOAddOrder(newStep);
}

void boEnd()
{
   BOStep newStep;
   newStep.type = cBOStepTypeEnd;

   internalBOAddOrder(newStep);
}

//==============================================================================
// boAddUnitsToBuildPlan
//==============================================================================
bool boAddUnitsToBuildPlan(int buildPlanID = -1, int kbResourceID = -1, int parentPlanID = -1)
{
   aiPlanSetParentID(buildPlanID, parentPlanID, false);
   int buildingPUID = aiPlanGetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0);

   // See what units should help out, loaned out units can't help here.
   int[] units = aiPlanGetUnits(parentPlanID);
   int[] unitTypes = aiPlanGetUnitTypes(buildPlanID);
   if (unitTypes.size() == 0)
   {
      return false;
   }
   int numNeeded = aiPlanGetNumberNeededUnits(buildPlanID, unitTypes[0]);
   int numAdded = 0;
   for (int i = units.size() - 1; i >= 0; i--)
   {
      if (kbUnitGetPlanID(units[i]) != parentPlanID)
      {
         continue;
      }

      if (kbUnitIsType(units[i], unitTypes[0]) == false)
      {
         continue;
      }
      
      debugBOStep("Loaning Villager: " + units[i] + ", to Build plan: " + buildPlanID + ", to build: " + 
                  kbProtoUnitGetName(buildingPUID));
      aiPlanAddUnit(buildPlanID, units[i], true);
      numAdded++;
      if (numAdded >= numNeeded)
      {
         break;
      }
   }

   // We already set the unit types on this plan in the BO step, and now because we're loaning we've incremented it again, undo that.
   aiPlanAddUnitType(buildPlanID, unitTypes[0], numNeeded, numNeeded, numNeeded);

   if (numAdded == 0)
   {
      return false;
   }
   return true;
}

//==============================================================================
// boBuildDropsite
// Don't use this function directly, use the helpers below.
//==============================================================================
void boBuildDropsite(int planID = -1, int resourceType = -1)
{
   int[] gatherPlans = boSystem.currentGatherPlans;
   int parentPlanID = gatherPlans[resourceType];
   int kbResourceID = aiPlanGetVariableInt(parentPlanID, cGatherPlanKBResourceID, 0);
   if (boAddUnitsToBuildPlan(planID, kbResourceID, parentPlanID) == false)
   {
      aiEcho("ATTENTION: boBuildDropsite couldn't add a valid unit to its build plan, this makes the BO fail!!!");
      internalBODoEndStep();
      return;
   }
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
   kbBuildingPlacementSetBuildingPUID(bpID, aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0));
   aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
   aiPlanSetVariableInt(planID, cBuildPlanMaxRetries, 0, 0);

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
   if (cMyCulture == cCultureNorse)
   {
      // Ox Carts require no buffer space and can move.
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
   }
}

void boBuildFoodDropsite(int planID = -1) { boBuildDropsite(planID, cResourceFood); }
void boBuildWoodDropsite(int planID = -1) { boBuildDropsite(planID, cResourceWood); }
void boBuildGoldDropsite(int planID = -1) { boBuildDropsite(planID, cResourceGold); }

//==============================================================================
// loanVillagerFromResourcePlan
// Don't use this function directly, use the helpers below.
//==============================================================================
void loanVillagerFromResourcePlan(int planID = -1, int resourceType = -1)
{
   int[] gatherPlans = boSystem.currentGatherPlans;
   int parentPlanID = gatherPlans[resourceType];
   int kbResourceID = aiPlanGetVariableInt(parentPlanID, cGatherPlanKBResourceID, 0);
   if (boAddUnitsToBuildPlan(planID, kbResourceID, parentPlanID) == false)
   {
      aiEcho("ATTENTION: loanVillagerFromResourcePlan couldn't add a valid unit to its build plan, this makes the BO fail!!!");
      internalBODoEndStep();
      return;
   }

   int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
   int buildingPUID = aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0);
   kbBuildingPlacementSetBuildingPUID(bpID, buildingPUID);
   aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);

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
   if (isMilitaryBuilding == false)
   {
      debugBOStep("Using regular determineBuildingPlacementLogic for this placement.");
      determineBuildingPlacementLogic(planID, bpID, boSystem.mainBaseID, resourceType, kbResourceID);
      if (buildingPUID == cUnitTypeManor)
      {
         // We have a failsafe handler for Manors, so just try once like dropsites and then let the handler take care of it.
         aiPlanSetVariableInt(planID, cBuildPlanMaxRetries, 0, 0);
      }
   }
   else
   {
      debugBOStep("Using custom BO military building placement for this building.");
      aiPlanSetBaseID(planID, boSystem.mainBaseID);

      if (buildingPUID == cUnitTypeTemple)
      {
         // We can't afford to lose the Temple early on, we must allow it to be built close to a tower etc.
         // Since this is one of our first buildings we're very unlikely to block anything in with this.
         kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      }
      else
      {
         kbBuildingPlacementSetBufferSpace(bpID, 3.0);
      }
      kbBuildingPlacementSetBaseID(bpID, boSystem.mainBaseID, cBuildingPlacementOrientationPreferenceNone);
   
      // Close to a tower would be nice.
      kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeSentryTower, 150, 15.0, cFalloffLinear);
      int unitID = aiPlanGetUnitIDByIndex(planID, 0); // This must be valid or we error'd out already.
      vector unitPosition = kbUnitGetPosition(unitID);
      // Influence towards the unit we assigned to this plan, to limit walking time.
      kbBuildingPlacementAddPositionInfluence(bpID, unitPosition, 100.0, 100.0, cFalloffLinear);

      avoidBlockingImportantSpots(planID, bpID);
      if (resourceType == cResourceFood && kbResourceGetIsIDValid(kbResourceID) == true)
      {
         // Don't interfere with our food plans and potentially build over dead animals.
         kbBuildingPlacementAddPositionInfluence(bpID, kbResourceGetPosition(kbResourceID), -10000.0, 10.0, cFalloffNone);
      }
   }
}

// Only use these helpers alongside a build plan BO Step.
void loanVillagerFromFoodPlan(int planID = -1) { loanVillagerFromResourcePlan(planID, cResourceFood); }
void loanVillagerFromWoodPlan(int planID = -1) { loanVillagerFromResourcePlan(planID, cResourceWood); }
void loanVillagerFromGoldPlan(int planID = -1) { loanVillagerFromResourcePlan(planID, cResourceGold); }
void loanVillagerFromFavorPlan(int planID = -1) { loanVillagerFromResourcePlan(planID, cResourceFavor); }

//==============================================================================
// empowerWithPriest
//==============================================================================
void empowerWithPriest(int planID = -1)
{
   debugBOStep("Empower: With Priest: " + planID);
   aiPlanAddUnitType(planID, cUnitTypePriest, 1, 1, 1);
   aiPlanAddUnit(planID, getUnit(cUnitTypePriest));
}

//==============================================================================
// assignOxCartToGatherPlan
// We can't use the build plan to fetch our Ox Cart ID instantly.
// This is because the Ox Cart foundation gets transformed, which the plan doesn't know about.
// Don't use this function directly, use the helpers below.
//==============================================================================
void assignOxCartToGatherPlan(int buildPlanID = -1, int resourceType = -1)
{
   // We can also call this in a BOExecute and then we don't have a buildPlanID attached.
   if (buildPlanID != -1)
   {
      int state = aiPlanGetState(buildPlanID);
      if (state == cPlanStateFailed)
      {
         int buildingTypeID = aiPlanGetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0);
         aiEcho("Our build plan for " + kbDefaultGetProtoStatString(buildingTypeID, cProtoStatName) + " failed, we will end BO.");
         internalBODoEndStep();
         return;
      }
      if (state != cPlanStateDone)
      {
         return;
      }
   }
   int gatherPlanID = boSystem.currentGatherPlans[resourceType];
   // Unit type is already added for us, also means you can't assign 2 Ox Carts to the same plan, but that is a bug anyway...
   int queryID = useSimpleUnitQuery(cUnitTypeOxCart);
   int numResults = kbUnitQueryExecute(queryID);
   int unitID = -1;
   for (int i = 0; i < numResults; i++)
   {
      unitID = kbUnitQueryGetResult(queryID, i);
      if (aiPlanGetIsIDValid(kbUnitGetPlanID(unitID)) == true)
      {
         unitID = -1;
         continue;
      }
      break;
   }
   if (unitID == -1)
   {
      aiEcho("ATTENTION: assignOxCartToGatherPlan - we don't have enough Ox Carts to be calling this!!!");
      internalBODoEndStep();
      return;
   }
   debugBOStep("Assigned Ox Cart: " + unitID + ", to resource: " + kbGetResourceName(resourceType) + ", planID: " + gatherPlanID);
   aiPlanAddUnit(gatherPlanID, unitID);
}

void assignOxCartToFood(int buildPlanID = -1) { assignOxCartToGatherPlan(buildPlanID, cResourceFood); }
void assignOxCartToWood(int buildPlanID = -1) { assignOxCartToGatherPlan(buildPlanID, cResourceWood); }
void assignOxCartToGold(int buildPlanID = -1) { assignOxCartToGatherPlan(buildPlanID, cResourceGold); }

//==============================================================================
// ReturnBerserkForTemple
//==============================================================================
rule returnBerserkForTemple
inactive
minInterval 3
{
   // Wait until we've passed 2:20.
   if (xsGetTime() <= 140)
   {
      return;
   }

   debugBO("We have done enough scouting with the Berserk, pull him back for the Temple now.");
   int berserkID = getUnit(cUnitTypeBerserk);
   if (berserkID != -1)
   {
      int explorePlanID = kbUnitGetPlanID(berserkID);
      if (explorePlanID != -1) // Explore plan may have died, shouldn't have but could.
      {
         aiPlanRemoveUnit(explorePlanID, berserkID);
         aiPlanDestroy(explorePlanID);
      }
      aiTaskMoveUnit(berserkID, boSystem.mainBasePosition);

      int planID = aiPlanCreate("BOBuild: " + kbProtoUnitGetName(cUnitTypeTemple), cPlanBuild, -1, gBuildingsCategoryID);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypeTemple);
      aiPlanAddUnitType(planID, cUnitTypeBerserk, 1, 1, 1);
      aiPlanAddUnit(planID, berserkID);
      
      // Prevents these units being kicked out if we end BO and auto assignment takes over and we have no foundation yet.
      aiPlanSetFlag(planID, cPlanFlagReadyForUnits, true);
      int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
      kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeTemple);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
      
      debugBOStep("Using custom BO military building placement for this building.");
      // We can't afford to lose the Temple early on, we must allow it to be built close to a tower etc.
      // Since this is one of our first buildings we're very unlikely to block anything in with this.
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      aiPlanSetBaseID(planID, boSystem.mainBaseID);
      kbBuildingPlacementSetBaseID(bpID, boSystem.mainBaseID, cBuildingPlacementOrientationPreferenceNone);
      // Close to a Tower would be nice.
      kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeSentryTower, 150, 15.0, cFalloffLinear);
      vector unitPosition = kbUnitGetPosition(berserkID);
      // Influence towards the unit we assigned to this plan, to limit walking time.
      kbBuildingPlacementAddPositionInfluence(bpID, unitPosition, 100.0, 100.0, cFalloffLinear);
      avoidBlockingImportantSpots(planID, bpID);
      int foodPlanID = boSystem.currentGatherPlans[cResourceFood];
      int kbResourceID = aiPlanGetVariableInt(foodPlanID, cGatherPlanKBResourceID, 0);
      if (kbResourceGetIsIDValid(kbResourceID) == true)
      {
         // Don't interfere with our food plans and potentially build over dead animals.
         kbBuildingPlacementAddPositionInfluence(bpID, kbResourceGetPosition(kbResourceID), -10000.0, 10.0, cFalloffNone);
      }
      aiPlanSetEventHandler(planID, cPlanEventStateChange, "internalBOBuildComplete");
   }
   // else, well BO will end soon...
   xsDisableRule("returnBerserkForTemple");
}

//==============================================================================
// addNorseMilitaryBuilderToPlan
//==============================================================================
void addNorseMilitaryBuilderToPlan(int planID = -1)
{
   int[] unitTypes = aiPlanGetUnitTypes(planID);
   if (unitTypes.size() == 0)
   {
      aiEchoWarning("addNorseMilitaryBuilderToPlan had no valid unit types added to its build plan.");
      internalBODoEndStep();
      return;
   }
   int numNeeded = aiPlanGetNumberNeededUnits(planID, unitTypes[0]);
   int numAdded = 0;
   int queryID = useSimpleUnitQuery(unitTypes[0]);
   int numResults = kbUnitQueryExecute(queryID);
   for (int i = 0; i < numResults; i++)
   {
      int unitID = kbUnitQueryGetResult(queryID, i);
      int unitPlanID = kbUnitGetPlanID(unitID);
      bool goodToAdd = false;
      debugBOStep("Found unit " + kbProtoUnitGetName(kbUnitGetProtoUnitID(unitID)) + "(" + unitID + ").");
      if (aiPlanGetIsIDValid(unitPlanID) == false)
      {
         debugBOStep("This unit is currently not in a plan, we can take it for our build plan.");
         goodToAdd = true;
      }
      if (goodToAdd == false)
      {
         debugBOStep("This unit is in plan " + aiPlanGetName(unitPlanID) + ".");
         // We can steal from our defend + child reinforcement plans.
         if (unitPlanID == gPrimaryLandDefendPlan || aiPlanGetParentID(unitPlanID) == gPrimaryLandDefendPlan)
         {
            debugBOStep("Unit is in the defend plan or a child reinforcement plan of the defend plan, we can steal it for our build plan.");
            goodToAdd = true;
         }
      }
      if (goodToAdd == true)
      {
         // Just assign away the unit, it will go idle after this plan but will be picked up for defend plan soon.
         aiPlanAddUnit(planID, unitID, false);
         numAdded++;
         if (numAdded >= numNeeded)
         {
            break;
         }
      }
   }
   if (numAdded < numNeeded)
   {
      aiEcho("ATTENTION: addNorseMilitaryBuilderToPlan couldn't add enough units to its build plan, this makes the BO fail!!!");
      internalBODoEndStep();
      return;
   }

   int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
   kbBuildingPlacementSetBuildingPUID(bpID, aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0));
   aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);

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
   if (isMilitaryBuilding == false)
   {
      debugBOStep("Using regular determineBuildingPlacementLogic for this placement.");
      determineBuildingPlacementLogic(planID, bpID, boSystem.mainBaseID);
   }
   else
   {
      debugBOStep("Using custom BO military building placement for this building.");
      aiPlanSetBaseID(planID, boSystem.mainBaseID);

      kbBuildingPlacementSetBufferSpace(bpID, 3.0);
      kbBuildingPlacementSetBaseID(bpID, boSystem.mainBaseID, cBuildingPlacementOrientationPreferenceNone);
   
      // Close to a tower would be nice.
      kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeSentryTower, 150, 15.0, cFalloffLinear);
      int unitID = aiPlanGetUnitIDByIndex(planID, 0); // This must be valid or we error'd out already.
      vector unitPosition = kbUnitGetPosition(unitID);
      // Influence towards the unit we assigned to this plan, to limit walking time.
      kbBuildingPlacementAddPositionInfluence(bpID, unitPosition, 100.0, 100.0, cFalloffLinear);

      avoidBlockingImportantSpots(planID, bpID);
      int foodPlanID = boSystem.currentGatherPlans[cResourceFood];
      int kbResourceID = aiPlanGetVariableInt(foodPlanID, cGatherPlanKBResourceID, 0);
      if (kbResourceGetIsIDValid(kbResourceID) == true)
      {
         // Don't interfere with our food plans and potentially build over dead animals.
         kbBuildingPlacementAddPositionInfluence(bpID, kbResourceGetPosition(kbResourceID), -10000.0, 10.0, cFalloffNone);
      }
   }
}

//==============================================================================
// assignRavensToExplorationPlans
//==============================================================================
rule assignRavensToExplorationPlans
inactive
minInterval 5
{
   int queryID = useSimpleUnitQuery(cUnitTypeRaven);
   kbUnitQueryExecute(queryID);
   int[] ravens = kbUnitQueryGetResults(queryID);
   int numRavens = ravens.size();
   if (numRavens == 0)
   {
      return; // Wait until our Ravens have spawned.
   }

   int[] explorePlans = aiPlanGetIDsByType(cPlanExplore);
   int[] ravenPlans = new int(0, 0);
   for (int i = 0; i < explorePlans.size(); i++)
   {
      int planID = explorePlans[i];
      int[] unitTypes = aiPlanGetUnitTypes(planID);
      if (unitTypes.size() == 0)
      {
         continue;
      }
      if (unitTypes[0] == cUnitTypeRaven)
      {
         ravenPlans.add(planID);
      }
   }

   int iterations = min(numRavens, ravenPlans.size());
   for (int i = 0; i < iterations; i++)
   {
      aiPlanAddUnit(ravenPlans[i], ravens[i]);
   }
   xsDisableRule("assignRavensToExplorationPlans");
}

//==============================================================================
// setupRavenScoutPlans
//==============================================================================
void setupRavenScoutPlans(int dummy = -1)
{
   int[] explorePlans = aiPlanGetIDsByType(cPlanExplore);
   for (int i = 0; i < explorePlans.size(); i++)
   {
      int planID = explorePlans[i];
      int[] unitTypes = aiPlanGetUnitTypes(planID);
      if (unitTypes.size() == 0)
      {
         continue;
      }
      if (unitTypes[0] == cUnitTypeRaven)
      {
         // First plan explores starting surroundings, second just regular plan.
         if (gFullyExploredStartingSurroundings == false)
         {
            helperExploreStartingSurroundings(planID);
         }
         return;
      }
   }
}

//==============================================================================
// useUnusedGodPowers
//==============================================================================
void useUnusedGodPowers(int dummy = -1)
{
   godPowerManager.useUnusedGodPowers();
}

//==============================================================================
// gaiaForestTransition
//==============================================================================
rule gaiaForestTransition
inactive
minInterval 60 // This is how long the GP takes to spawn all trees.
{
   if (isBuildOrderDone() == true)
   {
      xsDisableRule("gaiaForestTransition");
      return;
   }
   int woodPlanID = boSystem.currentGatherPlans[cResourceWood];
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID == -1)
   {
      xsDisableRule("gaiaForestTransition");
      return;
   }
   int gaiaTreeID = getClosestUnitByLocation(cUnitTypeTreeGaia, 0, cUnitStateAlive, kbBaseGetLocation(cMyID, mainBaseID),
      kbBaseGetDistance(cMyID, mainBaseID));
   if (kbUnitGetIsIDValid(gaiaTreeID) == false)
   {
      aiEchoWarning("We were meant to shift our BO wood plan to Gaia Trees but can't find any close to TC.");
      xsDisableRule("gaiaForestTransition");
      return;
   }
   int kbResourceID = kbUnitGetKBResourceID(gaiaTreeID);
   if (kbResourceGetIsIDValid(kbResourceID) == false)
   {
      aiEchoWarning("We found a Gaia Tree to shift our BO wood plan to, but that tree has no valid KB resource ID somehow.");
      xsDisableRule("gaiaForestTransition");
      return;
   }

   vector planPosition = aiPlanGetLocation(woodPlanID);
   if (xsVectorDistance(planPosition, kbUnitGetPosition(gaiaTreeID)) > 40.0)
   {
      debugBOStep("Our current wood plan is too far away from the Gaia Trees, don't transition now due to walking time.");
      xsDisableRule("gaiaForestTransition");
      return;
   }

   kbResourceSortTowardsPosition(kbResourceID, boSystem.mainBasePosition);
   // This unlinks us from the previous KBResourceID.
   aiPlanSetState(woodPlanID, cPlanStateNone);
   // Set a new KBResourceID manually.
   aiPlanSetVariableInt(woodPlanID, cGatherPlanKBResourceID, 0, kbResourceID);
   debugBOStep(aiPlanGetName(woodPlanID) + " adjusting its KB Resource to be the Gaia trees with ID: " + kbResourceID + ".");
   xsDisableRule("gaiaForestTransition");
}