class BOSystem
{
   BOStep[] buildOrderSteps = default;
   int currentStep = 0;
   int currentVillagerStep = 0;
   int[] maintainPlans = default;
   int numMaintainPlans = 0;
   int[] villagers = default;
   int numVillagers = 0;
   int startingVillagers = 0;
   int foodVillagers = 0;
   int woodVillagers = 0;
   int goldVillagers = 0;
   int favorVillagers = 0;
   int nextUpdate = -1;
   int nextForecast = -1;
   int[] currentGatherPlans = default;
   int timeout = 0;
   int timeoutBegin = 0;
   bool done = false;
   int mainBaseID = -1;
   vector mainBasePosition = cInvalidVector;
   int secondBaseID = -1;
   int secondBaseTCID = -1;
   vector secondBasePosition = cInvalidVector;
};
extern BOSystem boSystem;

void internalBOAddOrder(ref BOStep step)
{
   boSystem.buildOrderSteps.add(step);
}

void internalSetVillagerDistribution(float food = 1.0, float wood = 0.0, float gold = 0.0, float favor = 0.0)
{
   aiSetResourcePercentage(cResourceFood, false, food / boSystem.numVillagers);
   aiSetResourcePercentage(cResourceWood, false, wood / boSystem.numVillagers);
   aiSetResourcePercentage(cResourceGold, false, gold / boSystem.numVillagers);
   aiSetResourcePercentage(cResourceFavor, false, favor / boSystem.numVillagers);
   aiNormalizeResourcePercentages();
}

//==============================================================================
// On create defaults.
//==============================================================================
void internalBOUnitDefaultCreate(int planID = -1)
{
}

void internalBOBuildDefaultCreate(int planID = -1)
{
   aiEchoWarning("Never use internalBOBuildDefaultCreate because the BO just can't handle not knowing what parent plan to set.");
}

void internalBOEmpowerDefaultCreate(int planID = -1)
{
   debugBOStep("Empower: Default With Pharaoh " + planID);
   aiPlanAddUnitType(planID, cUnitTypePharaoh, 1, 1, 1);
   aiPlanAddUnit(planID, getUnit(cUnitTypePharaoh));
}

void internalBOExploreDefaultCreate(int planID = -1)
{
   debugBOStep("Explore: Default");
}

//==============================================================================
// internalBOQueueUpVillager
//==============================================================================
int internalBOQueueUpVillager(int resourceType = -1, int villagerPUID = -1)
{
   if (cGameModeCurrent == cGameModeDeathmatch)
   {
      debugBOStep("Queuing " + kbProtoUnitGetName(villagerPUID) + ".");
   }
   else
   {
      debugBOStep("Queuing " + kbProtoUnitGetName(villagerPUID) + " to " + kbGetResourceName(resourceType));
      // The economic rally point here only works as long as we only have 1 plan per resource type.
      switch (resourceType)
      {
         case cResourceFood:
         {
            int kbResourceID = aiPlanGetVariableInt(boSystem.currentGatherPlans[cResourceFood], cGatherPlanKBResourceID, 0);
            if (kbResourceGetIsIDValid(kbResourceID) == true)
            {
               aiUnitSetRallyPointToPosition(getUnit(cUnitTypeAbstractTownCenter), kbResourceGetPosition(kbResourceID));
            }
            break;
         }
         case cResourceWood:
         {
            int kbResourceID = aiPlanGetVariableInt(boSystem.currentGatherPlans[cResourceWood], cGatherPlanKBResourceID, 0);
            if (kbResourceGetIsIDValid(kbResourceID) == true)
            {
               aiUnitSetRallyPointToPosition(getUnit(cUnitTypeAbstractTownCenter), kbResourceGetPosition(kbResourceID));
            }
            break;
         }
         case cResourceGold:
         {
            int kbResourceID = aiPlanGetVariableInt(boSystem.currentGatherPlans[cResourceGold], cGatherPlanKBResourceID, 0);
            if (kbResourceGetIsIDValid(kbResourceID) == true)
            {
               aiUnitSetRallyPointToPosition(getUnit(cUnitTypeAbstractTownCenter), kbResourceGetPosition(kbResourceID));
            }
            break;
         }
         case cResourceFavor:
         {
            int templeID = getUnit(cUnitTypeTemple);
            if (kbUnitGetIsIDValid(templeID) == true)
            {
               aiUnitSetRallyPointToPosition(getUnit(cUnitTypeAbstractTownCenter), kbUnitGetPosition(templeID));
            }
            break;
         }
      }
   }
   
   // Find the maintain plan matching the unittype.
   int num = boSystem.numMaintainPlans;
   int[] maintainPlans = boSystem.maintainPlans;
   for (int i = 0; i < num; i++)
   {
      int planID = maintainPlans[i];
      int unittype = aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0);
      if (unittype != villagerPUID)
      {
         continue;
      }
      // We found it now just add 1 to train if we didn't already
      int oldNum = aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0);
      if (oldNum <= boSystem.numVillagers)
      {
         debugBOStep("Adding unforecasted Villager to our maintain plan.");
         aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, kbUnitCount(villagerPUID, cMyID) + 1);
      }
      else
      {
         debugBOStep("We already forecasted this Villager.");
      }
      return planID;
   }
   // We didn't find the puid yet so we need to create a maintain plan
   int newPlan = aiPlanCreate("BOMaintain: " + kbProtoUnitGetName(villagerPUID), cPlanTrain, -1, gEconomyCategoryID);
   aiPlanSetVariableInt(newPlan, cTrainPlanUnitType, 0, villagerPUID);
   aiPlanSetVariableInt(newPlan, cTrainPlanNumberToMaintain, 0, kbUnitCount(villagerPUID, cMyID) + 1);
   aiPlanSetVariableInt(newPlan, cTrainPlanMaxQueueSize, 0, 2);
   aiPlanSetEventHandler(newPlan, cTrainPlanEventUnitTrained, "internalBOVillagerTrained");
   aiPlanSetPriority(newPlan, 70);

   int newNum = num + 1;
   int[] newArray = new int(newNum, -1);
   for (int iCopy = 0; iCopy < num; iCopy++)
   {
      newArray[iCopy] = maintainPlans[iCopy];
   }
   newArray[num] = newPlan;
   boSystem.maintainPlans = newArray;
   boSystem.numMaintainPlans = boSystem.numMaintainPlans + 1;
   return newPlan;
}

//==============================================================================
// internalBOEndStrategy
//==============================================================================
void internalBOEndStrategy()
{
   boSystem.done = true;
}

//==============================================================================
// isBuildOrderDone
//==============================================================================
bool isBuildOrderDone()
{
   return boSystem.done;
}

//==============================================================================
// internalGetFoodVillagerTotal
//==============================================================================
int internalGetFoodVillagerTotal()
{
   return boSystem.foodVillagers;
}

//==============================================================================
// internalGetWoodVillagerTotal
//==============================================================================
int internalGetWoodVillagerTotal()
{
   return boSystem.woodVillagers;
}

//==============================================================================
// internalGetGoldVillagerTotal
//==============================================================================
int internalGetGoldVillagerTotal()
{
   return boSystem.goldVillagers;
}

//==============================================================================
// internalGetFavorVillagerTotal
//==============================================================================
int internalGetFavorVillagerTotal()
{
   return boSystem.favorVillagers;
}

//==============================================================================
// internalGetFavorVillagerTotal
//==============================================================================
int internalGetSecondBaseID()
{
   return boSystem.secondBaseID;
}

//==============================================================================
// updateBOSystem
//==============================================================================
void updateBOSystem()
{
   debugBO("updateBOSystem step: " + boSystem.currentStep);
   BOStep currentOrder = boSystem.buildOrderSteps[boSystem.currentStep];
   switch (currentOrder.type)
   {
      case cBOStepTypeVillager:
      {
         internalBODoVillagerStep(currentOrder);
         // Save what step this Villager belongs to so that the internalBOVillagerTrained handler knows what resource to assign to.
         boSystem.currentVillagerStep = boSystem.currentStep;
         // We must wait on the Villager to be trained to progress the BO, otherwise all the steps get messed up.
         // The callback that happens on completion of the Villager will set the nextUpdate correcty for us,
         // we must just prevent it here from updating too early!
         boSystem.nextUpdate = cMaxInt;
         // Just do this 1 second later.
         boSystem.nextForecast = xsGetTime() + 1;
         break;
      }

      case cBOStepTypeBuild:
      {
         internalBODoBuildStep(currentOrder);
         break;
      }

      case cBOStepTypeTech:
      {
         internalBODoTechStep(currentOrder);
         break;
      }

      case cBOStepTypeUnit:
      {
         internalBODoUnitStep(currentOrder);
         if (currentOrder.params[cBOStepUnitBlocking] == cBOStepBlocking)
         {
            // We must wait befor the unit is trained like explained for the Villager above too.
            boSystem.nextUpdate = cMaxInt;
            boSystem.nextForecast = cMaxInt;
         }
         else
         {
            // Just do this 1 second later.
            boSystem.nextForecast = xsGetTime() + 1;
         }
         break;
      }

      case cBOStepTypeTransaction:
      {
         int newResourceType = currentOrder.params[cBOStepTransactionNewResource];
         internalBODoTransactionStep(
            boSystem.villagers[currentOrder.params[cBOStepTransactionVillagerIndex]],
            newResourceType,
            boSystem.currentGatherPlans[newResourceType],
            currentOrder.onPlanCreate
         );
         break;
      }

      case cBOStepTypeAdvance:
      {
         internalBODoAdvanceStep(currentOrder);
         if (currentOrder.params[cBOStepAdvanceBlocking] == cBOStepBlocking)
         {
            boSystem.nextUpdate = cMaxInt;
         }
         boSystem.nextForecast = cMaxInt;
         break;
      }

      case cBOStepTypeEmpower:
      {
         internalBODoEmpowerStep(currentOrder);
         break;
      }

      case cBOStepTypeExplore:
      {
         internalBODOExploreStep(currentOrder);
         break;
      }

      case cBOStepTypeExecute:
      {
         internalBODOExecuteStep(currentOrder);
         break;
      }

      case cBOStepTypeConditionalWait:
      {
         static int timeout = 0;
         if (internalBODoConditionalWait(currentOrder) == false)
         {
            // Return so we keep repeating the order until the condition is met
            boSystem.nextUpdate = xsGetTime() + 1;
            boSystem.nextForecast = cMaxInt;
            if (timeout > currentOrder.params[cBOStepConditionalWaitTimeout])
            {
               if (currentOrder.params[cBOStepConditionalWarning] == cWarning)
               {
                  aiEcho("We didn't meet our condition within the timeout, failing BO!");
               }
               internalBODoEndStep();
               return;
            }
            timeout++;
            return;
         }
         timeout = 0;
         break;
      }

      case cBOStepTypeWait:
      {
         static bool doneWait = false;
         if (doneWait == false)
         {
            debugBOStep("Waiting for " + currentOrder.params[cBOStepWaitTime] + " seconds.");
            boSystem.nextUpdate = xsGetTime() + currentOrder.params[cBOStepWaitTime];
            doneWait = true;
            return;
         }
         doneWait = false;
         break;
      }

      case cBOStepTypeActivateRule:
      {
         xsEnableRule(currentOrder.onCompleteHandler);
         break;
      }

      case cBOStepTypeTimeoutIncrease:
      {
         int time = xsGetTime();
         debugBOStep("New timeout total time: " + currentOrder.params[cBOStepTimeoutTime] + " seconds, we need to complete " +
            "the next part of the BO before " + turnNumberIntoTimeDisplay(time + currentOrder.params[cBOStepTimeoutTime]) + ".");
         boSystem.timeout = currentOrder.params[cBOStepTimeoutTime];
         boSystem.timeoutBegin = time;
         break;
      }

      case cBOStepTypeEnd:
      {
         internalBODoEndStep();
         break;
      }
   }
   boSystem.currentStep++;
}

//==============================================================================
// forecastBOSystem
//==============================================================================
void forecastBOSystem()
{
   boSystem.nextForecast = cMaxInt;
   debugBO("forecastBOSystem step: " + boSystem.currentStep);
   debugBO("forecastBOSystem Villager step: " + boSystem.currentVillagerStep);
   int forecastStep = boSystem.currentStep;
   int size = boSystem.buildOrderSteps.size();
   while (forecastStep < size)
   {
      BOStep forecastOrder = boSystem.buildOrderSteps[forecastStep];
      switch (forecastOrder.type)
      {
         case cBOStepTypeVillager:
         {
            // Queue up the Villager.
            int[] params = forecastOrder.params;
            int villagerUnitType = params[cBOStepVillagerUnitType];
            int[] maintainPlans = boSystem.maintainPlans;
            bool found = false;
            for (int i = 0; i < boSystem.numMaintainPlans; i++)
            {
               int planID = maintainPlans[i];
               int unittype = aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0);
               if (unittype != villagerUnitType)
               {
                  continue;
               }
               // We found it now just add 1 to train.
               found = true;
               int oldNum = aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0);
               aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, oldNum + 1);
            }
            if (found == false)
            {
               debugBO("forecastBOSystem we have a Villager forecast but don't have a maintain plan for that unitType, not forecasting.");
            }
            else
            {
               debugBO("ForecastBOSystem forecasted villager type: " + kbProtoUnitGetName(villagerUnitType));
            }
            return;
         }

         // If there is a blocking unit or just an advance next in the queue we don't forecast.
         // Every advance here is causes us to skip the forecast because otherwise we run the risk of queueing up Villagers forever
         // and not getting enough food to age up.
         case cBOStepTypeUnit:
         {
            if (forecastOrder.params[cBOStepUnitBlocking] == 1)
            {
               return;
            }
            break;
         }
         case cBOStepTypeConditionalWait:
         case cBOStepTypeAdvance:
         {
            return;
         }
      }
      forecastStep++;
   }
}

//==============================================================================
// findBOFoodKBResource
//==============================================================================
int findBOFoodKBResource(ref int returnSubtype, int planID = -1)
{
   debugBO("Searching for the best available food resource subtype.");
   int[] validResources = new int(0, 0);
   for (int i = 0; i <= cAIResourceSubTypeHuntAggressive; i++)
   {
      float maxDistance = 55.0;
      if (i == cAIResourceSubTypeHunt || i == cAIResourceSubTypeHuntAggressive)
      {
         maxDistance += 25.0; // We must also gather a second hunt if it's relatively close.
      }
      int[] resources = kbGetValidResourcesByPosition(boSystem.mainBasePosition, cResourceFood, i, maxDistance, 9999.0);
      for (int iResource = 0; iResource < resources.size(); iResource++)
      {
         validResources.add(resources[iResource]);
      }
   }
   float[] startingFoodDistances = new float(cAIResourceSubTypeHuntAggressive + 1, cMaxFloat);
   int[] startingFoodKBs = new int(cAIResourceSubTypeHuntAggressive + 1, -1);
   bool foundChickenBerry = false;
   bool foundHerdable = false;
   bool foundPassiveHunt = false;
   bool foundReactiveHunt = false;
   int numResources = validResources.size();
   for (int i = 0; i < numResources; i++)
   {
      int id = validResources[i];
      float resourceAmount = kbResourceGetTotalResources(id);
      if (resourceAmount < 100.0)
      {
         debugBO("Skipping food spot below 100 food total: " + id + ".");
         continue;
      }
      vector loc = kbResourceGetPosition(id);
      float distance = xsVectorDistanceXZ(boSystem.mainBasePosition, loc);
      // Dont take food that is too close to the TC, that is for later (basically don't take food attracted by Lure);
      if (distance < 15.0)
      {
         debugBO("Food resource is too close to TC: " + id + ".");
         continue;
      }

      int subtype = kbResourceGetSubType(id);
      switch (subtype)
      {
         case cAIResourceSubTypeEasy:
         {
            foundChickenBerry = true;
            break;
         }
         case cAIResourceSubTypeHerdable:
         {
            foundHerdable = true;
            break;
         }
         case cAIResourceSubTypeHunt:
         {
            foundPassiveHunt = true;
            break;
         }
         case cAIResourceSubTypeHuntAggressive:
         {
            foundReactiveHunt = true;
            break;
         }
      }
      
      if (startingFoodDistances[subtype] > distance)
      {
         debugBO("Resouce ID " + id + " for subtype: " + subtype + " is now our best option for that subtype.");
         startingFoodKBs[subtype] = id;
         startingFoodDistances[subtype] = distance;
      }
   }
   // If we can't micro we can only go to reactive hunt if we have sufficient Villagers.
   bool areAllowedReactiveHunt = (gMicroFlags & cMicroHuntMicro) != 0;
   if (areAllowedReactiveHunt == false && aiPlanGetIsIDValid(planID) == true)
   {
      int planUnits = aiPlanGetNumberUnits(planID, -1, false);
      int threshold = cMyCulture == cCultureAtlantean ? 4 : 8;
      if (planUnits >= threshold)
      {
         areAllowedReactiveHunt = true;
      }
   }
   if (areAllowedReactiveHunt == true && foundReactiveHunt == true)
   {
      debugBO("Best subtype found: reactive hunt.");
      returnSubtype = cAIResourceSubTypeHuntAggressive;
      return startingFoodKBs[cAIResourceSubTypeHuntAggressive];
   }
   if (foundPassiveHunt == true)
   {
      debugBO("Best subtype found: passive hunt.");
      returnSubtype = cAIResourceSubTypeHunt;
      return startingFoodKBs[cAIResourceSubTypeHunt];
   }
   if (foundChickenBerry == true)
   {
      debugBO("Best subtype found: chickens/berries.");
      returnSubtype = cAIResourceSubTypeEasy;
      return startingFoodKBs[cAIResourceSubTypeEasy];
   }
   if (foundHerdable == true)
   {
      debugBO("Best subtype found: herdables.");
      returnSubtype = cAIResourceSubTypeHerdable;
      return startingFoodKBs[cAIResourceSubTypeHerdable];
   }

   debugBO("findBOFoodKBResourceSubtype - couldn't find any food resources anymore, failing BO!");
   internalBODoEndStep();
   return -1;
}

//==============================================================================
// findBOWoodKBResourceHelper
//==============================================================================
int findBOWoodKBResourceHelper(vector searchPosition = cInvalidVector)
{
   int[] resources = kbGetValidResourcesByPosition(searchPosition, cResourceWood, cAIResourceSubTypeEasy, 55.0, 9999.0);
   int bestResourceID = -1;
   float bestDistance = cMaxFloat;
   int numResources = resources.size();
   for (int i = 0; i < numResources; i++)
   {
      int id = resources[i];
      float resourceAmount = kbResourceGetTotalResources(id);
      if (resourceAmount < 600.0)
      {
         debugBO("Skipping forest below 600 wood total: " + id + ".");
         continue;
      }
      vector loc = kbResourceGetPosition(id);
      int areaID = kbAreaGetIDByPosition(loc);
      if (kbAreaGetType(areaID) != cAreaTypeForest)
      {
         debugBO("Skipping stragglers kbResource: " + id + ".");
         continue;
      }

      float resDistance = xsVectorLength(searchPosition - loc);
      if (resDistance < bestDistance)
      {
         bestDistance = resDistance;
         bestResourceID = id;
      }
   }
   return bestResourceID;
}

//==============================================================================
// findBOWoodKBResource
// Using custom function for this so we can prioritize woodlines at the back.
//==============================================================================
int findBOWoodKBResource()
{
   debugBO("Searching for valid wood KB resources.");
   static bool canUseBackVector = true;
   // We want to prio forests that are at the back of our base at the start, for safety.
   vector searchPosition = cInvalidVector;
   if (canUseBackVector == true)
   {
      vector backVector = kbBaseGetBackVector(cMyID, boSystem.mainBaseID);
      vector backVectorNormalized = xsVectorNormalize(backVector);
      searchPosition = boSystem.mainBasePosition + (backVectorNormalized * 20);
      if (kbGetIsLocationOnMap(searchPosition) == false)
      {
         debugBO("findBOWoodKBResource - our calculated back vector search point wasn't on the map anymore.");
         searchPosition = boSystem.mainBasePosition;
         canUseBackVector = false;
      }
   }
   else
   {
      searchPosition = boSystem.mainBasePosition;
   }

   int bestResourceID = findBOWoodKBResourceHelper(searchPosition);
   
   if (bestResourceID == -1 && canUseBackVector == true)
   {
      debugBO("findBOWoodKBResource - couldn't find a resource using the back vector, using main base location now.");
      canUseBackVector = false;
      bestResourceID = findBOWoodKBResourceHelper(boSystem.mainBasePosition);
   }
   if (bestResourceID == -1 && canUseBackVector == false)
   {
      aiEcho("findBOWoodKBResource - couldn't find a valid resource, this makes the BO fail!");
      internalBODoEndStep();
      return -1;
   }
   return bestResourceID;
}

//==============================================================================
// initBOSystem
//==============================================================================
bool initBOSystem()
{
   debugBO("BOSystem init");
   boSystem.mainBaseID = kbBaseGetMainID(cMyID);
   boSystem.mainBasePosition = kbBaseGetLocation(cMyID, boSystem.mainBaseID);
   internalSetVillagerDistribution();
   debugBO("Main Base ID: " + boSystem.mainBaseID);

   aiSetNextGathererDistributionTime(-1);
   aiSetUnassignedUnitAssignmentTime(-1);
   aiSetFullUnitAssignmentTime(-1);
   xsEnableRule("addMilitaryToDefendPlanDuringBO");

   if (cGameModeCurrent != cGameModeDeathmatch)
   {
      // Reduce our base's size so build plans go much faster.
      kbBaseSetDistance(cMyID, boSystem.mainBaseID, 37.50);

      // We should just make this big enough for all.
      boSystem.currentGatherPlans = new int(4, -1);
      int[] gatherPlans = boSystem.currentGatherPlans;
      int numResources = 3;
      if (cMyCulture == cCultureGreek)
      {
         numResources++; // Favor plan.
      }
      for (int resourceType = 0; resourceType < numResources; resourceType++)
      {
         int planID = aiPlanCreate("GatherPlan: " + kbGetResourceName(resourceType), cPlanGather, -1, gEconomyCategoryID);
         aiPlanSetVariableBool(planID, cGatherPlanAutoBuildDropsite, 0, false);
         aiPlanSetVariableInt(planID, cGatherPlanResourceType, 0, resourceType);

         // For food we need to find the optimal subtype + kbResourceID.
         int subtype = cAIResourceSubTypeEasy;
         if (resourceType == cResourceFood)
         {
            int kbResourceID = findBOFoodKBResource(subtype);
            if (kbResourceID == -1)
            {
               // We ended the BO already.
               return false;
            }
            aiPlanSetVariableInt(planID, cGatherPlanKBResourceID, 0, kbResourceID);
         }
         aiPlanSetVariableInt(planID, cGatherPlanResourceSubType, 0, subtype);

         // For wood we manually find the woodline, because it should be at the back.
         if (resourceType == cResourceWood)
         {
            int kbResourceID = findBOWoodKBResource();
            if (kbResourceID == -1)
            {
               // We ended the BO already.
               return false;
            }
            aiPlanSetVariableInt(planID, cGatherPlanKBResourceID, 0, kbResourceID);
         }

         // The gold plan searches for closest gold mine itself.
         
         // Already add the Ox Cart unit type here, this makes sure that if the BO fails it's still properly added and not blank.
         if (cMyCulture == cCultureNorse &&
             subtype != cAIResourceSubTypeFarm &&
             subtype != cAIResourceSubTypeHerdable)
         {
            aiPlanAddUnitType(planID, cUnitTypeOxCart, 1, 1, 1);
         }

         // This handler will search for new resources for us via the same BO find system if we run out + enable dropsites if needed.
         aiPlanSetEventHandler(planID, cGatherPlanEventResourceUpdate, "internalBO" + kbGetResourceName(resourceType) +
            "ResourceUpdate");
         aiPlanSetBaseID(planID, boSystem.mainBaseID);
         gatherPlans[resourceType] = planID;
      }
   }
   else
   {
      // Reduce our base's size a lot so that the Temple placement goes really fast, increase in Classical again.
      kbBaseSetDistance(cMyID, boSystem.mainBaseID, 25.00);

      // For Deathmatch we need to instantly start building at a second Settlement, create a base for that.
      // Deathmatch has a revealed map so this will work.
      int settlementID = -1;
      if (cMyCulture == cCultureAtlantean && cNumberPlayers == 2)
      {
         // If we're in a 1v1 as Atlantean, build on a forward TC.
         int queryID = useSimpleUnitQuery(cUnitTypeSettlement, 0, cUnitStateAlive, boSystem.mainBasePosition, 100.0);
         kbUnitQuerySetAscendingSort(queryID, true);
         int numResults = kbUnitQueryExecute(queryID);
         int[] results = kbUnitQueryGetResults(queryID);
         if (numResults == 0)
         {
            aiEcho("initBOSystem - couldn't find a valid settlement for a second base, this makes the BO fail!");
            internalBODoEndStep();
            return false;
         }
         else if (numResults == 1)
         {
            settlementID = results[0];
         }
         else
         {
            settlementID = results[1];
         }
         if (kbAreaGroupGetIDByPosition(boSystem.mainBasePosition) != kbAreaGroupGetIDByPosition(kbUnitGetPosition(settlementID)))
         {
            aiEcho("initBOSystem - settlement for a second base isn't in the same area group, this makes the BO fail!");
            internalBODoEndStep();
            return false;
         }
      }
      else
      {
         settlementID = getClosestUnitByLocation(cUnitTypeSettlement, 0, cUnitStateAlive, boSystem.mainBasePosition, 100.0);
         if (kbUnitGetIsIDValid(settlementID) == false)
         {
            aiEcho("initBOSystem - couldn't find a valid settlement for a second base, this makes the BO fail!");
            internalBODoEndStep();
            return false;
         }
         if (kbAreaGroupGetIDByPosition(boSystem.mainBasePosition) != kbAreaGroupGetIDByPosition(kbUnitGetPosition(settlementID)))
         {
            aiEcho("initBOSystem - settlement for a second base isn't in the same area group, this makes the BO fail!");
            internalBODoEndStep();
            return false;
         }
      }
      boSystem.secondBaseTCID = settlementID;
      vector basePosition = kbUnitGetPosition(settlementID);
      // Create another base so that we can put build/defend plans in there.
      // 42.50 range so buildings have space to go into but it's not too big that it slows placement too much.
      int baseID = kbBaseCreate(cMyID, kbBaseGetNextID() + " DM Second Base", basePosition, 42.50);
      kbBaseSetFrontVector(cMyID, baseID, kbGetMapCenter() - basePosition);
      kbBaseSetMilitaryGatherPoint(cMyID, baseID, (kbBaseGetFrontVector(cMyID, baseID) * 30) + basePosition);
      if (kbBaseGetIsIDValid(cMyID, baseID) == false)
      {
         aiEcho("initBOSystem - couldn't create a base for the DM settlement base, this makes the BO fail!");
         internalBODoEndStep();
         return false;
      }
      // Make sure the base isn't instantly deleted too, kinda abuse the gatherbase flag.
      kbBaseSetFlag(cMyID, baseID, cBaseFlagRemoteGatherBase, true);
      boSystem.secondBaseID = baseID;
      boSystem.secondBasePosition = basePosition;

      // Oracles must gather favor instantly.
      xsDisableRule("startupOracleScoutingMonitor");
      xsEnableRule("oracleMonitor");
      xsEnableRule("oracleMaintainMonitor");
   }
   return true;
}

//==============================================================================
// startBOSystem
// This gets called after our BO steps are already filled.
//==============================================================================
void startBOSystem() 
{
   if (cGameModeCurrent != cGameModeDeathmatch)
   {
      // Set our start of game rally point on the resource the first Villager wants to gather.
      int i = 0;
      int size = boSystem.buildOrderSteps.size();
      bool found = false;
      while (i < size && found == false)
      {
         BOStep nextOrder = boSystem.buildOrderSteps[i];
         switch (nextOrder.type)
         {
            case cBOStepTypeVillager:
            {
               int resourceType = nextOrder.params[cBOStepVillagerResourceType];
               // We know this resourceID is valid because otherwise we wouldn't reach here.
               aiUnitSetRallyPointToPosition(getUnit(cUnitTypeAbstractTownCenter),
                  kbResourceGetPosition(aiPlanGetVariableInt(boSystem.currentGatherPlans[resourceType], cGatherPlanKBResourceID, 0)));
               found = true;
               break;
            }
         }
         i++;
      }
   }
   xsEnableRule("monitorBO");
}

mutable void internalBOVillagerTrained(int unitID = -1) {}
//==============================================================================
// handleStartingVillagers
// Your first orders inside the BO MUST be handling your starting Villagers.
// If you have 4 starting Villagers your first 4 steps MUST BE 4 Villager steps, or it all crumbles.
//==============================================================================
bool handleStartingVillagers()
{
   int villagerUnitQuery = useSimpleUnitQuery(cUnitTypeAbstractVillager);
   int numberVillagers = -1;
   if (villagerUnitQuery != -1)
   {
      numberVillagers = kbUnitQueryExecute(villagerUnitQuery);
   }
   else
   {
      // We can't function if the query failed.
      aiEchoWarning("handleStartingVillagers - We couldn't create a query.");
      internalBODoEndStep();
      return false;
   }

   if (cGameModeCurrent == cGameModeDeathmatch)
   {
      boSystem.currentVillagerStep = numberVillagers;
      boSystem.currentStep = numberVillagers;
      boSystem.startingVillagers = numberVillagers;
      boSystem.numVillagers = numberVillagers;
      return true;
   }

   debugBO("Handling our starting Villagers.");

   // If we have different resources for each villager
   // we need to figure out who's close to what.
   int lastResource = -1;
   bool oneResource = true;
   for (int i = 0; i < numberVillagers; i++)
   {
      BOStep step = boSystem.buildOrderSteps[i];
      if (step.type != cBOStepTypeVillager)
      {
         aiEchoWarning("A non Villager type step found during the handling of starting Villagers, this isn't allowed.");
         internalBODoEndStep();
         return false;
      }
      int resourceType = step.params[cBOStepVillagerResourceType];
      if (lastResource == -1)
      {
         lastResource = resourceType;
      }
      else if (lastResource != resourceType)
      {
         oneResource = false;
         break;
      }
   }

   if (oneResource == true)
   {
      for (int i = 0; i < numberVillagers; i++)
      {
         int id = kbUnitQueryGetResult(villagerUnitQuery, i);
         BOStep step = boSystem.buildOrderSteps[i];
         internalBOVillagerTrained(id); // Here we do the default assignment.
         boSystem.currentVillagerStep++;
         boSystem.currentStep++;
      }
   }
   else
   {
      debugBO("Villagers will be distributed based on resource distance since not all our starting Villager steps have the same resource.");
      // We do the reverse we go over the steps and match a villager.
      int[] villagers = kbUnitQueryGetResults(villagerUnitQuery);
      for (int i = 0; i < numberVillagers; i++) // Loop through the steps.
      {
         BOStep step = boSystem.buildOrderSteps[i];
         int resourceType = step.params[cBOStepVillagerResourceType];
         int resourceID = aiPlanGetVariableInt(boSystem.currentGatherPlans[resourceType], cGatherPlanKBResourceID, 0);
         vector pos = kbResourceGetPosition(resourceID);
         // Find closest Villager.
         int closestID = -1;
         float distance = cMaxFloat;
         for (int iVillager = 0; iVillager < numberVillagers; iVillager++) // Loop through the Villagers.
         {
            int villagerID = villagers[iVillager];
            if (villagerID == -1) // Skip Villagers we've already assigned.
            {
               continue;
            }
            float newDistance = xsVectorLength(pos - kbUnitGetPosition(villagerID));
            if (newDistance < distance)
            {
               distance = newDistance;
               closestID = villagerID;
            }
         }
         debugBO("Villager: " + closestID + " will be sent to: " + resourceID + " " + kbGetResourceName(resourceType) + ".");
         villagers[closestID] = -1; // Remove Villager from the array basically.
         internalBOVillagerTrained(closestID);
         boSystem.currentVillagerStep++;
         boSystem.currentStep++;
      }
   
      boSystem.startingVillagers = numberVillagers;
      boSystem.numVillagers = numberVillagers;
   }
   return true;
}

//==============================================================================
// monitorBO
//==============================================================================
rule monitorBO
inactive
highFrequency
group groupBOSystem
{
   static bool firstUnitsSpawned = false;
   if (firstUnitsSpawned == false)
   {
      if (kbUnitGetIsIDValid(getUnit(cUnitTypeAbstractVillager)) == true)
      {
         if (handleStartingVillagers() == true)
         {
            firstUnitsSpawned = true;
         }
      }
      else if (cGameModeCurrent == cGameModeDeathmatch && cMyCulture == cCultureNorse)
      {
         if (kbUnitGetIsIDValid(getUnit(cUnitTypeBerserk)) == true)
         {
            firstUnitsSpawned = true;
         }
      }
      else
      {
         // If it takes longer than normal to have units spawn we must be in some custom situation, BOs aren't great for that.
         if (xsGetTime() > 10)
         {
            aiEchoWarning("Our Villagers haven't spawned after 10 seconds, we shouldn't have picked the BO strategy.");
            internalBODoEndStep();
         }
      }
      // Even if we found our starting units we MUST return still.
      // This is because the frame these units are spawned their position is still set to the TCs center point.
      // And that means we can't use their position to influence anything, but if we wait 1 frame it's fine.
      return;
   }

   // Do our steps.
   // boSystem.nextUpdate sometimes gets set to cMaxInt to wait for a step to complete before continuing.
   // And sometimes it's not set to cMaxInt and then steps follow each other up quite rapidly.
   int time = xsGetTime();
   int size = boSystem.buildOrderSteps.size();
   bool ageUpDelayed = false;
   while (time >= boSystem.nextUpdate && boSystem.currentStep < size)
   {
      // If one of our steps fails but we were going to execute multiple steps in the same frame, we need to stop those next steps.
      if (boSystem.done == true)
      {
         return;
      }
      // We can only age up on lower difficulties if a human has done so before us.
      // If there is no human left in the game we just age up.
      // And if there is another AI on higher difficulty that has already aged up we follow suit, not waiting on the human.
      if (cDifficultyCurrent <= cDifficultyModerate)
      {
         static int timeBlockedStart = 0;
         BOStep currentOrder = boSystem.buildOrderSteps[boSystem.currentStep];
         if (currentOrder.type == cBOStepTypeAdvance)
         {
            if (getHighestPlayerAge() == cAge1 && getHumanPresentInGame() == true) // Heroic BOs are not waiting on player age ups.
            {
               if (timeBlockedStart == 0)
               {
                  timeBlockedStart = xsGetTime();
                  debugBO("Waiting on human/higher difficulty AI to age up, timeBlockedStart = " + timeBlockedStart + ".");
               }
               ageUpDelayed = true;
               break;
            }
            else
            {
               if (timeBlockedStart != 0)
               {
                  int totalTimeBlocked = xsGetTime() - timeBlockedStart;
                  debugBO("Increasing our timeout by: " + totalTimeBlocked + ", because of waiting on AgeUp.");
                  boSystem.timeout += totalTimeBlocked;
                  timeBlockedStart = 0;
               }
            }
         }
      }
      updateBOSystem();
   }

   if (time >= boSystem.nextForecast)
   {
      forecastBOSystem();
   }
   
   if (kbUnitGetIsIDValid(getUnit(cUnitTypeAbstractTownCenter)) == false)
   {
      aiEcho("LOST OUR TOWN CENTER / CITADEL CENTER, ENDING BO!");
      internalBODoEndStep();
      return;
   }

   if (boSystem.numVillagers != kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive))
   {
      aiEcho("LOST A VILLAGER, ENDING BO!");
      internalBODoEndStep();
      return;
   }

   if (cMyCulture == cCultureNorse)
   {
      static int lastOxCartCount = 0;
      int currentOxCartCount = kbUnitCount(cUnitTypeOxCart, cMyID, cUnitStateAlive);
      if (currentOxCartCount >= lastOxCartCount)
      {
         lastOxCartCount = currentOxCartCount;
      }
      else
      {
         aiEcho("LOST AN OX CART, ENDING BO!");
         internalBODoEndStep();
         return;
      }
   }

   if (cMyCulture == cCultureNorse && xsGetTime() >= 10 &&
       kbUnitCount(cUnitTypeLogicalTypeNorseSoldierThatBuilds, cMyID, cUnitStateABQ) <= 0)
   {
      aiEcho("LOST ALL OUR BUILDERS, ENDING BO!");
      internalBODoEndStep();
      return;
   }
   // TODO insert ending logic for when we're under serious threat.
   //if (???)
   //{
   //   aiEcho("WE'RE UNDER ATTACK, ENDING BO!");
   //   internalBODoEndStep();
   //   return;
   //}

   if (ageUpDelayed == false && boSystem.timeout != 0)
   {
      int timeSpentInCurrentSection = time - boSystem.timeoutBegin;
      if (timeSpentInCurrentSection >= boSystem.timeout)
      {
         aiEcho("BO TIMED OUT, ENDING!");
         internalBODoEndStep();
         return;
      }
   }
}

//==============================================================================
// addMilitaryToDefendPlanDuringBO
// We want all our military in the defend plan but can't assign them onCreate
// because that messes with parent-child logic and sometimes overwrites existing plans.
// So just assign free military to the plan here, and if you take a military unit you must loan it from gPrimaryLandDefendPlan.
//==============================================================================
rule addMilitaryToDefendPlanDuringBO
inactive
minInterval 5
{
   if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == false)
   {
      return;
   }
   int queryID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary);
   int numResults = kbUnitQueryExecute(queryID);
   int[] results = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < numResults; i++)
   {
      int unitID = results[i];
      int unitPlanID = kbUnitGetPlanID(unitID);
      if (aiPlanGetIsIDValid(unitPlanID) == false)
      {
         aiPlanAddUnit(gPrimaryLandDefendPlan, unitID);
      }
   }
}