//==============================================================================
/* human_assist.xs

   Creates an AI for Retold that just prepares the kb & sets up some basic plans for the Human players to use for
   things like auto-scout and managing resource gatherers.

*/
//==============================================================================

mutable void setDistributionNumbers(int food = 0, int wood = 0, int gold = 0) {}

// To prevent error in dropsite placement.
bool isBuildOrderDone() { return true; }
// To prevent error in resource breakdown.
extern bool gOverrideOkToGatherFood = true;
extern bool gOverrideOkToGatherGold = true;
extern bool gOverrideOkToGatherWood = true;
extern bool gOverrideOkToGatherFavor = true;
void alertRanOutOfFoodResources() {}
void alertFoundFoodResources() {}

const bool cAllowManualDistribution = false;
const bool cAllowDropsiteConstruction = false;
include "core/utilities/debug.xs";
include "core/utilities/unit_queries.xs";
include "core/buildings/dropsite_placement.xs";
extern int gFarmUnit = -1;

bool gSentFoodNotification = false;
bool gSentWoodNotification = false;
bool gSentGoldNotification = false;

//==============================================================================
// createSimpleBuildPlan
// These variables are almost all unused in the function body, it's just so that the resource breakdowns
// don't compile error.
//==============================================================================
int createSimpleBuildPlan(int puid = -1, int numberWanted = 1, int pri = 100, int baseID = -1, int numberBuilders = 1,
   int parentPlanID = -1)
{
   int planID = aiPlanCreate("Place Farm", cPlanBuild);
   if (planID != -1)
   {
      vector loc = kbBaseGetLocation(cMyID, baseID);

      int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
      kbBuildingPlacementSetBuildingPUID(bpID, gFarmUnit);
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementSetStepSize(bpID, 0.5);
      kbBuildingPlacementSetCenterPosition(bpID, loc, 15.0);
      kbBuildingPlacementAddPositionInfluence(bpID, loc, 100.0, 15.0, cFalloffLinear);

      aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, gFarmUnit);
      aiPlanSetVariableBool(planID, cBuildPlanDoneWhenFoundationPlaced, 0, true);

      aiPlanSetBaseID(planID, baseID);
      aiPlanSetPriority(planID, 100);
   }
   return planID;
}

//==============================================================================
// getMainGatherBaseID
// Another stub function to get the script to compile
//==============================================================================
int getMainGatherBaseID()
{
   return kbBaseGetMainID(cMyID);
}
include "core/economy/resource_breakdown_system.xs";

int gReservePlan = -1;

float gTSFactorDistance = -100.0; // negative is good
float gTSFactorTotalResources = 10.0; // positive is good
float gTSFactorTimeToDone = 0.0; // positive is good
float gTSFactorDanger = -100.0; // negative is good

int gTotalNumber = 20;
int gFoodNumber = 0;
int gWoodNumber = 0;
int gGoldNumber = 0;
// This number is fetched by the engine to know what preset we're on.
int gPresetNumber = 0;

bool gForceUpdateBreakdowns = false;
int gDistributionTime = -1;
int gLastDistributionTime = -1;
bool gEnabled = false;
bool gAllowedToFarm = false;
const int cDistributionDelayUI = 1;
const int cDistributionDelayUser = 60;
const int cMaxAmountOfFarms = 15;

//==============================================================================
// disableFarmPlacement
//==============================================================================
void disableFarmPlacement()
{
   // This function is called from the UI, the UI doesn't know our context so we must set it explicitly.
   xsSetContextPlayer(cMyID);
   aiEcho("Disabling automatic Farm placement.");
   gAllowedToFarm = false;
   xsSetContextPlayer(-1);
}

//==============================================================================
// enableFarmPlacement
//==============================================================================
void enableFarmPlacement()
{
   // This function is called from the UI, the UI doesn't know our context so we must set it explicitly.
   xsSetContextPlayer(cMyID);
   aiEcho("Enabling automatic Farm placement.");
   gAllowedToFarm = true;
   xsSetContextPlayer(-1);
}

//==============================================================================
// disableAutoScouting
//==============================================================================
void disableAutoScouting(int unitID = -1)
{
   // This function is called from the UI, the UI doesn't know our context so we must set it explicitly.
   xsSetContextPlayer(cMyID);
   aiEcho("Disabling automatic scouting for unit: " + unitID);
   int planID = kbUnitGetPlanID(unitID);
   if(planID != -1)
   {
      aiPlanDestroy(planID);
   }
   xsSetContextPlayer(-1);
}

//==============================================================================
// enableAutoScouting
//==============================================================================
void enableAutoScouting(int unitID = -1)
{
   // This function is called from the UI, the UI doesn't know our context so we must set it explicitly.
   xsSetContextPlayer(cMyID);
   aiEcho("Enabling automatic scouting for unit: " + unitID);
   int planID = aiPlanCreate("Autoscout with unit: " + unitID, cPlanExplore);
   aiPlanAddUnitType(planID, cUnitTypeUnit, 1,1,1);
   aiPlanAddUnit(planID, unitID);
   if (kbUnitIsType(unitID, cUnitTypeAbstractOracle) == true)
   {
      aiPlanSetVariableBool(planID, cExplorePlanDoLoops, 0, false);
      // Stand still if less or equal than 20% of our surrounding tiles are explored.
      aiPlanSetVariableFloat(planID, cExplorePlanStopLOSPercentage, 0, 0.2);
   }
   aiPlanSetFlag(planID, cPlanFlagNoMoreUnits, true);
   aiPlanSetFlag(planID, cPlanFlagRequiresAllNeedUnits, true);
   xsSetContextPlayer(-1);
}

//==============================================================================
// isFarmPlacementEnabled
// This function is called by the UI to know the state of the Farm toggle button.
//==============================================================================
bool isFarmPlacementEnabled() 
{
   return gAllowedToFarm;
}

//==============================================================================
// Distribution getters
//==============================================================================
int getFoodNumber() { return gFoodNumber; }
int getWoodNumber() { return gWoodNumber; }
int getGoldNumber() { return gGoldNumber; }

//==============================================================================
// updateBreakdown
//==============================================================================
rule updateBreakdown
minInterval 9
inactive
{
   aiEcho("--- Running Rule updateBreakdown. ---");
   bool canFarm = gAllowedToFarm && gEnabled;
   gRBDSystem.resourceBreakdownUpdateGatherPlanPriorities(canFarm);
   gRBDSystem.scanForBases();

   gRBDSystem.mAllowAutoRemoteCreation = false;
   int reserved = aiPlanGetNumberUnits(gReservePlan, cUnitTypeAbstractVillager);
   aiEcho("Reserved num gatherers: " + reserved + ".");
   int gathererCount = kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive) - reserved;
   // Omega hack to prevent 0 gatherers being assigned when only 1 lives and we have split priorities.
   if (gathererCount == 1)
   {
      gathererCount++;
   }
   aiEcho("gathererCount: " + gathererCount + ".");
   aiEcho("Planned Food gatherers: " + xsFloatToInt(round(aiGetResourcePercentage(cResourceFood) * gathererCount)) + ".");
   aiEcho("Planned Wood gatherers: " + xsFloatToInt(round(aiGetResourcePercentage(cResourceWood) * gathererCount)) + ".");
   aiEcho("Planned Gold gatherers: " + xsFloatToInt(round(aiGetResourcePercentage(cResourceGold) * gathererCount)) + ".");
   int previousUnassigned = 0;
   int totalAssigned = 0;
   int unassigned = gRBDSystem.resourceBreakdownUpdateExistingFood(gathererCount, false, totalAssigned);
   unassigned = gRBDSystem.resourceBreakdownUpdateFood(canFarm, cMaxAmountOfFarms, unassigned, gathererCount, totalAssigned, true, false);
   if (unassigned > 0)
   {
      if (gSentFoodNotification == false)
      {
         gSentFoodNotification = true;
         aiSendNotificationFoundNotEnoughFoodGatheringSpots();
      }
      previousUnassigned = unassigned;
   }

   unassigned = gRBDSystem.resourceBreakdownUpdateGold(gathererCount, unassigned);
   // If we now have more unassigned than before we couldn't assign all wanted gold gatherers.
   if (previousUnassigned < unassigned)
   {
      if (gSentGoldNotification == false)
      {
         gSentGoldNotification = true;
         aiSendNotificationFoundNotEnoughGoldGatheringSpots();
      }
   }
   previousUnassigned = unassigned;

   unassigned = gRBDSystem.resourceBreakdownUpdateWood(gathererCount, unassigned);
   // If we now have more unassigned than before we couldn't assign all wanted wood gatherers.
   if (previousUnassigned < unassigned)
   {
      if (gSentWoodNotification == false)
      {
         gSentWoodNotification = true;
         aiSendNotificationFoundNotEnoughWoodGatheringSpots();
      }
   }
   previousUnassigned = unassigned;

   // VPS can't set favor yet but it's here anyway.
   if (cMyCulture == cCultureGreek)
   {
      gRBDSystem.resourceBreakdownUpdateFavor(gathererCount, unassigned);
   }
}

//==============================================================================
// updateVillagerDistributionFromNumbers
//==============================================================================
void updateVillagerDistributionFromNumbers()
{
   float total = gTotalNumber;
   float food = gFoodNumber;
   float wood = gWoodNumber;
   float gold = gGoldNumber;
   aiSetResourcePercentage(cResourceFood, false, food / total);
   aiSetResourcePercentage(cResourceWood, false, wood / total);
   aiSetResourcePercentage(cResourceGold, false, gold / total);
   aiNormalizeResourcePercentages();
}

//==============================================================================
// onAutoPlanCreate handler
//==============================================================================
void onAutoPlanCreate(int planID = -1)
{
   aiPlanSetVariableBool(planID, cGatherPlanAutoBuildDropsite, 0, cAllowDropsiteConstruction);
   
   if (cMyCulture == cCultureNorse &&
       aiPlanGetVariableInt(planID, cGatherPlanResourceSubType, 0) != cAIResourceSubTypeFarm &&
       aiPlanGetVariableInt(planID, cGatherPlanResourceSubType, 0) != cAIResourceSubTypeHerdable)
   {
      aiPlanAddUnitType(planID, cUnitTypeOxCart, 1, 1, 1);
   }
}

//==============================================================================
// applyDistribution
//==============================================================================
rule applyDistribution
inactive
minInterval 1
maxInterval 2
{
   aiEcho("--- Running Rule applyDistribution. ---");
   if (gDistributionTime == -1)
   {
      if (gForceUpdateBreakdowns == true)
      {
         updateVillagerDistributionFromNumbers();
         updateBreakdown();
         // Assignment timers are all reset when we're in a force.
         gForceUpdateBreakdowns = false;
      }
      return;
   }
   if (xsGetTime() >= gDistributionTime)
   {
      aiEcho("Applying new distribution, Food: " + gFoodNumber + ", Wood: " + gWoodNumber + ", Gold: " + gGoldNumber + ".");
      updateVillagerDistributionFromNumbers();
      updateBreakdown();
      aiSetNextGathererDistributionTime(0);
      aiSetFullUnitAssignmentTime(0);
      gLastDistributionTime = xsGetTime();
      gDistributionTime = -1;
   }
}

//==============================================================================
// checkReservePlan
//==============================================================================
const int cReserveTypeNone = 0;
const int cReserveTypeIdle = cReserveTypeNone + 1;
const int cReserveTypeGathering = cReserveTypeIdle + 1;

int checkReservePlan(bool reclaimGatheringVillagers = false)
{
   int foundType = cReserveTypeNone;
   int[] units = aiPlanGetUnits(gReservePlan);
   if (units.size() == 0)
   {
      return foundType;
   }
   for (int i = 0; i < units.size(); i++)
   {
      int unitID = units[i];
      int protoUnitID = kbUnitGetProtoUnitID(unitID);
      // We handle multiple kinds of units in this reserve plan but the reserve types only apply to Villagers.
      bool isVillager = kbProtoUnitIsType(protoUnitID, cUnitTypeAbstractVillager);
      int actionType = kbUnitGetActionType(unitID);
      switch (actionType)
      {
         case cActionTypeIdle:
         {
            if (kbUnitGetIdleTime(unitID) > 2000)
            {
               aiEcho("Found an idle " + kbProtoUnitGetName(protoUnitID) + "(" + unitID + ") to reclaim.");
               aiPlanRemoveUnit(gReservePlan, unitID);
               if (isVillager == true && foundType < cReserveTypeGathering)
               {
                  foundType = cReserveTypeIdle;
               }
            }
            break;
         }
         case cActionTypeGather:
         case cActionTypeHunting:
         {
            foundType = cReserveTypeGathering;
            //int resourceID = kbResourceGetIDByUnitID(kbUnitGetTargetUnitID(unitID));
            //if (resourceID == -1)
            //{
            //   break;
            //}

            if (reclaimGatheringVillagers == false || isVillager == false)
            {
               break;
            }
            // Don't remove Fishing Ships from the reserve plan if they're gathering.
            // Because leaving the Fishing Ship in the reserve plan versus the fish plan actually makes no difference at all
            // in terms of it gathering. So we only add Fishing Ships to the fish plan when they're idle.
            aiPlanRemoveUnit(gReservePlan, unitID);
         }
      }
   }
   return foundType;
}

//==============================================================================
// updateReserved
//==============================================================================
const int cReserveStateNormal = 0;
const int cReserveStateUserInput = cReserveStateNormal + 1;
int reserveState = cReserveStateNormal;

rule updateReserved
inactive
minInterval 1
maxInterval 10
{
   xsSetContextPlayer(cMyID);
   aiEcho("--- Running Rule updateReserved. ---");
   int reserveType = checkReservePlan(false);
   // We only want to force a change when our vills are gathering
   if (reserveType == cReserveTypeGathering && reserveState == cReserveStateUserInput)
   {
      // Recalculate distribution numbers from our current distribution
      int[] resources = new int(3, 0);
      int[] gatherPlans = aiPlanGetIDsByType(cPlanGather);
      for (int i = 0; i < gatherPlans.size(); i++)
      {
         int planID = gatherPlans[i];
         int resourceType = aiPlanGetVariableInt(planID, cGatherPlanResourceType, 0);
         if (resourceType < cResourceFavor && resourceType != -1)
         {
            resources[resourceType] = resources[resourceType] + aiPlanGetNumberUnits(planID, cUnitTypeAbstractVillager, true); 
         }
      }
      if (gFoodNumber > 0)
      {
         resources[cResourceFood] = max(resources[cResourceFood], 1);
      }
      if (gWoodNumber > 0)
      {
         resources[cResourceWood] = max(resources[cResourceWood], 1);
      }
      if (gGoldNumber > 0)
      {
         resources[cResourceGold] = max(resources[cResourceGold], 1);
      }
      float total = xsIntToFloat(resources[cResourceFood] + resources[cResourceWood] + resources[cResourceGold]);
      for (int i = 0; i < cResourceFavor; i++)
      {
         resources[i] = xsFloatToInt(round((xsIntToFloat(resources[i]) / total) * 19.99));// So we never somehow overflow
      }
      aiEcho("New Food:" + resources[cResourceFood] + " new wood: " + resources[cResourceWood] + " new gold: " + resources[cResourceGold]);
      setDistributionNumbers(resources[cResourceFood], resources[cResourceWood], resources[cResourceGold]);
      updateVillagerDistributionFromNumbers();
      xsRuleIgnoreIntervalOnce("updateBreakdown"); 
      aiSetFullUnitAssignmentTime(xsGetTimeMS() + cDistributionDelayUser * 1000);
      aiSetNextGathererDistributionTime(xsGetTimeMS() + cDistributionDelayUser * 1000);
      gDistributionTime = xsGetTime() + cDistributionDelayUser;
      aiEcho("Overriding distribution time to have a " + cDistributionDelayUI + " ms delay.");
   }
   reserveState = cReserveStateNormal;
}

//==============================================================================
// checkGatherRadius
// This rule is always on so that in the event of VPS being turned on later we have a proper base range.
//==============================================================================
const int cGatheringRangeStateNormal = 0;
const int cGatheringRangeStateExpand = 1;
const int cGatheringRangeStateShrink = 2;
int gatheringState = cGatheringRangeStateNormal;
const float maxRange = 100.0;
const float minRange = 30.0;

rule checkGatherRadius
active
minInterval 30
maxInterval 60
{
   aiEcho("--- Running Rule checkGatherRadius. ---");
   int numberBases = kbBaseGetNumber(cMyID);
   // Go through all our bases
   for (int i = 0; i < numberBases; i++)
   {
      int baseID = kbBaseGetIDByIndex(cMyID, i);
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
      {
         continue;
      }
      vector basePosition = kbBaseGetLocation(cMyID, baseID);
      float range = kbBaseGetDistance(cMyID, baseID);
      switch(gatheringState)
      {
         case cGatheringRangeStateNormal:
         {
            aiEcho("Checking for resources in range.");
            // We need to check if we're low on resources
            float numRes = kbGetAmountValidResourcesByPosition(basePosition, cResourceFood, cAIResourceSubTypeEasy, range);
            // Hack in case we have berries so we won't move off them
            if (numRes >= 10.0)
            {
               numRes = numRes + 500.0;
            }
            numRes += kbGetAmountValidResourcesByPosition(basePosition, cResourceFood, cAIResourceSubTypeHunt, range);
            numRes += kbGetAmountValidResourcesByPosition(basePosition, cResourceFood, cAIResourceSubTypeHerdable, range);
            aiEcho("  Food res left in main base: " + numRes);
            if (numRes < 500 && range < maxRange)
            {
               float newRange = range + 10.0;
               aiEcho("    We are low on resources, expanding gather range to: " + newRange);
               kbBaseSetDistance(cMyID, baseID, newRange);
               gatheringState = cGatheringRangeStateExpand;
               xsSetRuleMinInterval("checkGatherRadius", 0);
               xsSetRuleMaxInterval("checkGatherRadius", 0);
               return;
            } 
            // Now we need to check if we shrink
            // First we need to get all our gather plans
            float maxRangeSq = 0.0;
            float secondMaxRangeSq = 0.0;
            int numGatherPlans = aiPlanGetNumberByType(cPlanGather);
            for(int iPlan = 0; iPlan < numGatherPlans; iPlan++)
            {
               int planID = aiPlanGetIDByTypeIndex(cPlanGather, iPlan);
               if(aiPlanGetBaseID(planID) != baseID)
               {
                  continue;
               }
               float distanceSq = xsVectorDistanceXZSqr(aiPlanGetLocation(planID), basePosition); 
               if(distanceSq >= maxRangeSq)
               {
                  maxRangeSq = distanceSq;
                  secondMaxRangeSq = maxRangeSq;
               }
            }
            // Only shrink at most till our second plan so we blow up just one instead of many in rare cases
            // Also add 10 range buffer zone before we actually shrink
            float shrunkRange = range - 20.0; 
            if(secondMaxRangeSq < shrunkRange * shrunkRange)
            {
               numRes = kbGetAmountValidResourcesByPosition(kbBaseGetLocation(cMyID, baseID), cResourceFood, cAIResourceSubTypeEasy, shrunkRange);
               numRes += kbGetAmountValidResourcesByPosition(kbBaseGetLocation(cMyID, baseID), cResourceFood, cAIResourceSubTypeHunt, shrunkRange);
               numRes += kbGetAmountValidResourcesByPosition(kbBaseGetLocation(cMyID, baseID), cResourceFood, cAIResourceSubTypeHerdable, shrunkRange);
               if (numRes > 500 && range > minRange)
               {
                  float newRange = range - 10.0;
                  aiEcho("    We have found resources closer nearby, reducing gather range to: " + newRange);
                  kbBaseSetDistance(cMyID, baseID, newRange);
                  // Give it some time
                  xsSetRuleMinInterval("checkGatherRadius", 30);
                  xsSetRuleMaxInterval("checkGatherRadius", 60);
                  return;
               }
            }
            break; 
         }
         case cGatheringRangeStateExpand:
         {
            aiEcho("Checking for resources in expanding range");
            float numRes = kbGetAmountValidResourcesByPosition(kbBaseGetLocation(cMyID, baseID), cResourceFood, cAIResourceSubTypeEasy, range);
            numRes += kbGetAmountValidResourcesByPosition(kbBaseGetLocation(cMyID, baseID), cResourceFood, cAIResourceSubTypeHunt, range);
            numRes += kbGetAmountValidResourcesByPosition(kbBaseGetLocation(cMyID, baseID), cResourceFood, cAIResourceSubTypeHerdable, range);
            if (numRes > 500)
            {
               aiEcho("  Found enough resources");
               gatheringState = cGatheringRangeStateNormal;
               break;
            }
            else if (range >= maxRange)
            {
               aiEcho("  Maxed out our range");
               gatheringState = cGatheringRangeStateNormal;
               break;
            }
            float newRange = range + 10.0;
            aiEcho("  We are still low on resources, expanding gather range to: " + newRange);
            kbBaseSetDistance(cMyID, baseID, newRange);
            xsSetRuleMinInterval("checkGatherRadius", 0);
            xsSetRuleMaxInterval("checkGatherRadius", 0);
            return;
         }
      }
   }
   xsSetRuleMinInterval("checkGatherRadius", 30);
   xsSetRuleMaxInterval("checkGatherRadius", 60);
}

//==============================================================================
// setUpFishPlans
//==============================================================================
void setUpFishPlans()
{
   aiEcho("Setting up Fish plans.");
   int numAreaGroups = kbAreaGroupGetNumber();
   for (int i = 0; i < numAreaGroups; i++)
   {
      if (kbAreaGroupGetType(i) != cAreaGroupTypeWater)
      {
         continue;
      }
      xsSetContextPlayer(0);
      int queryID = useSimpleNatureUnitQuery(cUnitTypeFishResource);
      kbUnitQuerySetAreaGroupID(queryID, i);
      int numResults = kbUnitQueryExecute(queryID);
      xsSetContextPlayer(cMyID);
      aiEcho("Found " + numResults + " Fish for area group " + i +".");
      if (numResults == 0)
      {
         continue;
      }
      int planID = aiPlanCreate("Gather Fish areaGroup " + i, cPlanFish);
      aiEcho("Created Fishing plan: " + aiPlanGetName(planID) + ".");
      aiPlanAddUnitType(planID, cUnitTypeAbstractFishingShip, 0, 0, 200);
      aiPlanSetVariableInt(planID, cFishPlanResourceType, 0, cResourceFood);
      aiPlanSetVariableInt(planID, cFishPlanResourceSubType, 0, cAIResourceSubTypeFish);
      aiPlanSetVariableInt(planID, cFishPlanWaterGroupID, 0, i);
      // We need to set this initial position so that the assignment logic always knows what area group we belong to so it
      // doesn't assign Fishing Ships to it that are in another water area group.
      aiPlanSetInitialPosition(planID, kbAreaGetCenter(kbAreaGroupGetAreaID(i, 0)));
   }
}

//==============================================================================
// deleteFishPlans
//==============================================================================
void deleteFishPlans()
{
   aiEcho("Deleting Fish plans.");
   int[] plans = aiPlanGetIDsByType(cPlanFish);
   for (int i = 0; i < plans.size(); i++)
   {
      aiPlanDestroy(plans[i]);
   }
}

//==============================================================================
// setPresetNumber
//==============================================================================
void setPresetNumber(int preset = 0) 
{
   if (preset < 0) 
   {
      aiEcho("WARNING: Received an invalid VP preset number.");
      preset = 0;
   }
   else 
   {
      gPresetNumber = preset;
   }
}

//==============================================================================
// getPresetNumber
//==============================================================================
int getPresetNumber() 
{
   if (gEnabled == true) 
   {
      return gPresetNumber;
   }
   return 0; // None,
}

//==============================================================================
// userControlledVillagers
//==============================================================================
void userControlledVillagers(int unused = -1)
{
   aiEcho("User controlled villager(s)");
   if (cAllowManualDistribution)
   {
      xsRuleIgnoreIntervalOnce("updateReserved");
      reserveState = cReserveStateUserInput;
   }
   // We need to offset this by last update time
   aiEcho("Last Update time: " + gLastDistributionTime);
   
   int newTimeMS = min(gLastDistributionTime * 1000 + cDistributionDelayUser * 1000, xsGetTimeMS() + cDistributionDelayUser * 1000); 
   aiEcho("New Update time: " + newTimeMS / 1000);
   aiSetFullUnitAssignmentTime(newTimeMS);
   //aiSetUnassignedUnitAssignmentTime(newTimeMS);
   //aiSetNextGathererDistributionTime(newTimeMS);
   gDistributionTime = newTimeMS / 1000;
}

//==============================================================================
// disableVillagerAssist
// This turns off all automatic behavior and destroys all the plans.
//==============================================================================
void disableVillagerAssist()
{
   // This function is called from the UI, the UI doesn't know our context so we must set it explicitly.
   xsSetContextPlayer(cMyID);
   gEnabled = false;
   aiEcho("Disabling Villager Assist.");
   aiSetNextGathererDistributionTime(-1);
   aiSetFullUnitAssignmentTime(-1);
   aiSetUnassignedUnitAssignmentTime(-1);
   // This removes all the gather plans.
   gRBDSystem.applyResourceFlags(false, false, false, false);
   xsDisableRule("updateBreakdown");
   xsDisableRule("applyDistribution");
   xsDisableRule("updateReserved");
   deleteFishPlans();
   gDistributionTime = -1;
   xsSetContextPlayer(-1);
}

//==============================================================================
// enableVillagerAssist
// This turns on all automatic behavior and creates the reserve plan (gather plans are auto created).
//==============================================================================
void enableVillagerAssist()
{
   // Remove idle Villagers from the reserve plan so that we can instantly task them.
   int[] units = aiPlanGetUnits(gReservePlan);
   for (int i = 0; i < units.size(); i++)
   {
      int unitID = units[i];
      int actionType = kbUnitGetActionType(unitID); 
      if (actionType == cActionTypeIdle)
      {
         aiPlanRemoveUnit(gReservePlan, unitID);
      }
   }
   gEnabled = true;
   aiEcho("Enabling Villager Assist.");
   xsEnableRule("updateBreakdown");
   xsEnableRule("applyDistribution");
   gDistributionTime = -1;
   gForceUpdateBreakdowns = true;
   // Instantly run it so our activation instantly takes effect.
   applyDistribution();
   xsEnableRule("updateReserved");
   setUpFishPlans();
   aiSetNextGathererDistributionTime(0);
   aiSetFullUnitAssignmentTime(0);
}

//==============================================================================
// setDistributionNumbers
// This function is called by the UI to set our new distribution.
//==============================================================================
void setDistributionNumbers(int food = 0, int wood = 0, int gold = 0)
{
   // Check invalid inputs.
   int total = food + wood + gold;
   if (food < 0 || wood < 0 || gold < 0 || total > 20 || total == 0)
   {
      aiEchoWarning("DETECTED AN INVALID INPUT FROM THE UI FOR THE DISTRIBUTION.");
      return;
   }
   // This function is called from the UI, the UI doesn't know our context so we must set it explicitly.
   xsSetContextPlayer(cMyID);
   aiEcho("*** Running setDistributionNumbers. ***");

   gRBDSystem.applyResourceFlags(true, true, true, true);
   gTotalNumber = total;
   gFoodNumber = food;
   gWoodNumber = wood;
   gGoldNumber = gold;
   aiEcho("New distribution (point system): Food: " + food + ", Wood: " + wood + ", Gold: " + gold + ".");

   // We can send notifications again for this preset.
   gSentFoodNotification = false;
   gSentWoodNotification = false;
   gSentGoldNotification = false;

   // Reclaim all Villagers that were gathering while in the reserve plan.
   aiEcho("Reclaiming all reserved Gatherers that are actually gathering.");
   checkReservePlan(true);

   if (gEnabled == true)
   {
      gDistributionTime = xsGetTime() + cDistributionDelayUI;
      aiEcho("Villager Assist was already on, just changing the distribution after " + cDistributionDelayUI + " second delay.");
   }
   else
   {
      aiEcho("Villager Assist was off, enabling it now and setting the distribution instantly.");
      enableVillagerAssist();
   }
   xsSetContextPlayer(-1);
}

//==============================================================================
// main
//==============================================================================
void main()
{
   aiEcho("Villager Priority startup.");
   aiEcho("Game type is " + cGameTypeCurrent + ", 0 = Scenario, 1 = Save Game, 2 = Random Map, 3 = Campaign, 4 = Recorded Game.");
   aiEcho("Map name is " + cRandomMapName);

   setupDebugCategories();

   aiSetHandler("onAutoPlanCreate", cXSAutoCreatePlanHandler);
   gFarmUnit = kbSharedFunctionUnitGetByIndex(cSharedUnitFunctionFarm, 0);

   // Reserve plan to allow player control.
   gReservePlan = aiPlanCreate("Reserve", cPlanReserve);
   aiPlanSetPriority(gReservePlan, 100);
   aiPlanAddUnitType(gReservePlan, cUnitTypeAffectedByTownBell, 1000, 1000, 1000);
   aiPlanAddUnitType(gReservePlan, cUnitTypeAbstractFishingShip, 1000, 1000, 1000);
   aiPlanSetFlag(gReservePlan, cPlanFlagNoMoreUnits, true);
   aiSetHandler("selectDropsitePlacement", cXSResourceBuildPlanHandler);

   // Set the default Resource Selector factor.
   kbSetResourceSelectorFactor(cTSFactorDistance, cResourceFood, gTSFactorDistance);
   kbSetResourceSelectorFactor(cTSFactorTotalResources, cResourceFood, gTSFactorTotalResources);
   kbSetResourceSelectorFactor(cTSFactorTimeToDone, cResourceFood, gTSFactorTimeToDone);
   kbSetResourceSelectorFactor(cTSFactorDanger, cResourceFood, gTSFactorDanger);

   kbSetResourceSelectorFactor(cTSFactorDistance, cResourceWood, gTSFactorDistance);
   kbSetResourceSelectorFactor(cTSFactorTotalResources, cResourceWood, gTSFactorTotalResources);
   kbSetResourceSelectorFactor(cTSFactorTimeToDone, cResourceWood, gTSFactorTimeToDone);
   kbSetResourceSelectorFactor(cTSFactorDanger, cResourceWood, gTSFactorDanger);

   kbSetResourceSelectorFactor(cTSFactorDistance, cResourceGold, gTSFactorDistance);
   kbSetResourceSelectorFactor(cTSFactorTotalResources, cResourceGold, 0);
   kbSetResourceSelectorFactor(cTSFactorTimeToDone, cResourceGold, gTSFactorTimeToDone);
   kbSetResourceSelectorFactor(cTSFactorDanger, cResourceGold, gTSFactorDanger);

   aiNormalizeResourcePercentages();
   if (kbBaseGetMainID(cMyID) != -1)
   {
      kbBaseSetDistance(cMyID, kbBaseGetMainID(cMyID), 50.0);
   }
   // The system starts off by default.
   disableVillagerAssist();
}