extern const int cBOStepTypeVillager = 0;
extern const int cBOStepVillagerResourceType = 0;
extern const int cBOStepVillagerUnitType = 1;
extern const int cBOStepVillagerNumParams = 2;

extern const int cBOStepTypeBuild = 1;
extern const int cBOStepBuildPUID = 0;
extern const int cBOStepBuilderPUID = 1;
extern const int cBOStepNumBuilders = 2;
extern const int cBOStepBuildNumParams = 3;

extern const int cBOStepTypeTech = 2;
extern const int cBOStepTechTechID = 0;
extern const int cBOStepTechResearcherPUID = 1;
extern const int cBOStepTechNumParams = 2;

extern const int cBOStepTypeUnit = 3;
extern const int cBOStepUnitBlocking = 0;
extern const int cBOStepUnitPUID = 1;
extern const int cBOStepUnitAmount = 2;
extern const int cBOStepUnitTrainMode = 3;
extern const int cBOStepUnitTrainerPUID = 4;
extern const int cBOStepUnitNumParams = 5;

extern const int cBOStepTypeTransaction = 4;
extern const int cBOStepTransactionVillagerIndex = 0;
extern const int cBOStepTransactionNewResource = 1;
extern const int cBOStepTransactionNumParams = 2;

extern const int cBOStepTypeAdvance = 5;
extern const int cBOStepAdvanceBlocking = 0;
extern const int cBOStepAdvanceMinorGodTechID = 1;
extern const int cBOStepAdvanceNumParams = 2;

extern const int cBOStepTypeEmpower = 6;
extern const int cBOStepEmpowerTargetPUID = 0;
extern const int cBOStepEmpowerNumParams = 1;

extern const int cBOStepTypeExplore = 7;
extern const int cBOStepExploreExplorerPUID = 0;
extern const int cBOStepExploreSearchShoreline = 1;
extern const int cBOStepExploreSearchEnemy = 2;
extern const int cBOStepExploreLoops = 3;
extern const int cBOStepExploreStartingSurroundings = 4;
extern const int cBOStepExploreNumParams = 5;

extern const int cBOStepTypeExecute = 8;
extern const int cBOStepExecuteNumParams = 0;

extern const int cBOStepTypeConditionalWait = 9;
extern const int cBOStepConditionalWaitTimeout = 0;
extern const int cBOStepConditionalWarning = 1;
extern const int cBOStepConditionalWaitNumParams = 2;

extern const int cBOStepTypeWait = 10;
extern const int cBOStepWaitTime = 0;
extern const int cBOStepWaitNumParams = 1;

extern const int cBOStepTypeActivateRule = 11;

extern const int cBOStepTypeTimeoutIncrease = 12;
extern const int cBOStepTimeoutTime = 0;
extern const int cBOStepTimeoutIncreaseNumParams = 1;

extern const int cBOStepTypeEnd = 13;

extern const int cBOStepUnit = 0;
extern const int cBOStepMaintain = 1;

extern const int cBOStepBlocking = 0;
extern const int cBOStepNotBlocking = 1;

extern const int cBOStepDontSearchShoreline = 0;
extern const int cBOStepSearchShoreline = 1;

extern const int cBOStepDontSearchEnemy = 0;
extern const int cBOStepSearchEnemy = 1;

extern const int cBOStepDontDoLoops = 0;
extern const int cBOStepDoLoops = 1;

extern const int cBOStepDontScoutSurroundings = 0;
extern const int cBOStepScoutStartingSurroundings = 1;

extern const int cWarning = 0;
extern const int cNoWarning = 1;

class BOStep
{
   int type = -1;
   int[] params = default;
   void(int) onPlanCreate = [](int planID = -1) {};
   bool() condition = []() -> bool {return true;};
   string onCompleteHandler = "";
};

mutable int internalBOQueueUpVillager(int resourceType = -1, int villagerUnitType = -1) { return -1; }
mutable void internalBOEndStrategy() { return; }
mutable int internalGetFoodVillagerTotal() { return 0; }
mutable int internalGetWoodVillagerTotal() { return 0; }
mutable int internalGetGoldVillagerTotal() { return 0; }
mutable int internalGetFavorVillagerTotal() { return 0; }
mutable int internalGetSecondBaseID() { return -1; }

//==============================================================================
// What the actual steps do.
//==============================================================================
void internalBODoVillagerStep(ref BOStep step)
{
   int[] params = step.params;
   int resourceType = params[cBOStepVillagerResourceType];
   int villagerUnitType = params[cBOStepVillagerUnitType];
   int planID = internalBOQueueUpVillager(resourceType, villagerUnitType);
   // This planID is of the maintain plan that we use for this Villager type, it most often is an existing plan, so not really onPlanCreate.
   step.onPlanCreate(planID);
   // Since these are maintain plans that only get created once and never "complete" we don't use the step.onCompleteHandler.
}

void internalBODoBuildStep(ref BOStep step)
{
   int[] params = step.params;
   int buildingPUID = params[cBOStepBuildPUID];
   int builderPUID = params[cBOStepBuilderPUID];
   int numBuilders = params[cBOStepNumBuilders];
   debugBOStep("Build: " + kbProtoUnitGetName(buildingPUID));
   int planID = aiPlanCreate("BOBuild: " + kbProtoUnitGetName(buildingPUID), cPlanBuild, -1, gBuildingsCategoryID);
   aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, buildingPUID);
   aiPlanAddUnitType(planID, builderPUID, numBuilders, numBuilders, numBuilders);
   step.onPlanCreate(planID);
   // Overwrite any potential handlers that could be set in the building placement process.
   aiPlanSetEventHandler(planID, cPlanEventStateChange, step.onCompleteHandler);
   // Prevents these units being kicked out if we end BO and auto assignment takes over and we have no foundation yet.
   aiPlanSetFlag(planID, cPlanFlagReadyForUnits, true);
}

void internalBODoTechStep(ref BOStep step)
{
   int[] params = step.params;
   int techID = params[cBOStepTechTechID];
   int researcherPUID = params[cBOStepTechResearcherPUID];
   int planID = aiPlanCreate("BOResearch: " + kbTechGetName(techID), cPlanResearch, -1, gTechsCategoryID);
   debugBOStep("Research technology: " + kbTechGetName(techID));
   aiPlanSetVariableInt(planID, cResearchPlanBuildingTypeID, 0, researcherPUID);
   aiPlanSetVariableInt(planID, cResearchPlanTechID, 0, techID);
   aiPlanSetEventHandler(planID, cPlanEventStateChange, step.onCompleteHandler);
}

void internalBODoUnitStep(ref BOStep step)
{
   int[] params = step.params;
   int unitPUID = params[cBOStepUnitPUID];
   int trainerPUID = params[cBOStepUnitTrainerPUID];
   int trainAmount = params[cBOStepUnitAmount];
   int planID = aiPlanCreate("BOUnit: " + kbProtoUnitGetName(unitPUID), cPlanTrain, -1, gMilitaryTrainingCategoryID);
   debugBOStep("Training unit: " + kbProtoUnitGetName(unitPUID));
   aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, unitPUID);
   aiPlanSetVariableInt(planID, cTrainPlanBuildFromType, 0, trainerPUID);
   if (params[cBOStepUnitTrainMode] == cBOStepUnit)
   {
      aiPlanSetVariableInt(planID, cTrainPlanNumberToTrain, 0, trainAmount);
   }
   else // Maintain mode.
   {
      aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, trainAmount);
   }
   // If we're blocking we need the special handler to unblock ourself.
   // ATTENTION: due to it being cTrainPlanEventUnitTrained you can't make a blocking unit step with multiple units in 1 order.
   // Because it will unblock after the first unit. If this ever needs to be fixed we need to check for UnitAmount and if it's
   // > 1 make it a handler based on cPlanEventStateChange instead, which would eliminate the option for a custom onCompleteHandler.
   if (step.params[cBOStepUnitBlocking] == cBOStepBlocking)
   {
      aiPlanSetEventHandler(planID, cTrainPlanEventUnitTrained, "internalBOUnitTrainedBlocking");
   }
   else
   {
      aiPlanSetEventHandler(planID, cTrainPlanEventUnitTrained, "internalBOUnitTrained");
   }
   // Higher than Villagers.
   aiPlanSetPriority(planID, 75);
   aiPlanSetEventHandler(planID, cPlanEventStateChange, step.onCompleteHandler);
   step.onPlanCreate(planID);
}

void internalBODoTransactionStep(int villagerID = -1, int newResourceType = -1, int targetPlanID = -1,
   void(int) onTransaction = [](int dummy = -1) {})
{
   debugBOStep("Transaction of: " + villagerID + " to resource: " + kbGetResourceName(newResourceType));
   // Move it from the old plan into the new one and then call onTransaction.
   int planID = kbUnitGetPlanID(villagerID);
   int puid = kbUnitGetProtoUnitID(villagerID);
   aiPlanRemoveUnit(planID, villagerID);
   aiPlanAddUnitType(planID, puid, -1, -1, -1, true);
   if (newResourceType != -1)
   {
      aiPlanAddUnitType(targetPlanID, puid, 1, 1, 1, true);
      aiPlanAddUnit(targetPlanID, villagerID);
   }
   // We assumed that we only had 1 gather plan per resource when we picked targetPlanID.
   // You could override the correct targetPlanID in the onTransaction.
   onTransaction(villagerID);
}

void internalBODoAdvanceStep(ref BOStep step)
{
   int planID = aiPlanCreate("BOAdvance", cPlanResearch, -1, gTechsCategoryID);
   aiPlanSetVariableInt(planID, cResearchPlanBuildingTypeID, 0, cUnitTypeAbstractTownCenter);
   aiPlanSetVariableInt(planID, cResearchPlanTechID, 0, step.params[cBOStepAdvanceMinorGodTechID]);
   debugBOStep("Advancing to " + kbTechGetName(step.params[cBOStepAdvanceMinorGodTechID]));
   aiPlanSetPriority(planID, 80);
   if (step.params[cBOStepAdvanceBlocking] == cBOStepBlocking) // If we're blocking we need the special handler to unblock ourself.
   {
      aiPlanSetEventHandler(planID, cPlanEventStateChange, "internalAdvanceCompletedBlocking");
   }
   else
   {
      aiPlanSetEventHandler(planID, cPlanEventStateChange, "internalAdvanceCompleted");
   }
   step.onPlanCreate(planID);
}

void internalBODoEmpowerStep(ref BOStep step)
{
   int[] params = step.params;
   int targetPUID = params[cBOStepEmpowerTargetPUID];
   debugBOStep("Empower: " + kbProtoUnitGetName(targetPUID));
   int planID = aiPlanCreate("BOEmpower: " + kbProtoUnitGetName(targetPUID), cPlanEmpower, -1, gEconomyCategoryID);
   aiPlanSetVariableInt(planID, cEmpowerPlanTargetTypeID, 0, targetPUID);
   // Longer timeout because placement of a building may fail and since this is a BO we can't then assign back the empowerer that got kicked out.
   aiPlanSetVariableInt(planID, cEmpowerPlanNoTargetUnitRemovalTimeout, 0, 30);
   step.onPlanCreate(planID); // In here we actually assign a unit to the plan, this can be Pharaoh or Priest.
}

void internalBODOExploreStep(ref BOStep step)
{
   int[] params = step.params;
   int explorerPUID = params[cBOStepExploreExplorerPUID];
   debugBOStep("Explore: " + kbProtoUnitGetName(explorerPUID));
   int planID = aiPlanCreate("BOExplore: " + kbProtoUnitGetName(explorerPUID), cPlanExplore, -1, gExplorationCategoryID);
   if (params[cBOStepExploreSearchShoreline] == cBOStepSearchShoreline)
   {
      helperScoutDockShoreline(planID);
   }
   if (params[cBOStepExploreSearchEnemy] == cBOStepSearchEnemy)
   {
      vector enemyPosition = guessEnemyLocation(getRandomEnemyID());
      aiPlanAddWaypoint(planID, enemyPosition);
   }
   if (params[cBOStepExploreLoops] == cBOStepDoLoops)
   {
      aiPlanSetVariableBool(planID, cExplorePlanDoLoops, 0, true);
      aiPlanSetVariableInt(planID, cExplorePlanNumberOfLoops, 0, 3);
      aiPlanSetVariableVector(planID, cExplorePlanLoopStartPoint, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
   }
   if (params[cBOStepExploreStartingSurroundings] == cBOStepScoutStartingSurroundings && gFullyExploredStartingSurroundings == false)
   {
      helperExploreStartingSurroundings(planID);
   }

   aiPlanAddUnitType(planID, explorerPUID, 1, 1, 1);
   int queryID = useSimpleUnitQuery(explorerPUID);
   int numResults = kbUnitQueryExecute(queryID);
   int[] results = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < numResults; i++)
   {
      int unitID = results[i];
      int unitPlanID = kbUnitGetPlanID(unitID);
      if (aiPlanGetIsIDValid(unitPlanID) == false || unitPlanID == gPrimaryLandDefendPlan)
      {
         aiPlanAddUnit(planID, unitID);
         break;
      }
   }

   // Temp hack to get migration maps working for BOs
   int numExploreAreas = gMapInfo.mMigratableAreaGroups.size();
   aiPlanSetNumberVariableValues(planID, cExplorePlanExploreAreaGroupIDs, numExploreAreas, true);
   for(int i = 0; i < numExploreAreas; i++)
   {
      aiPlanSetVariableInt(planID, cExplorePlanExploreAreaGroupIDs, i, gMapInfo.mMigratableAreaGroups[i]);
   }
   aiPlanSetEventHandler(planID, cPlanEventStateChange, step.onCompleteHandler);
   step.onPlanCreate(planID);
}

void internalBODOExecuteStep(ref BOStep step) 
{
   step.onPlanCreate(-1);
}

bool internalBODoConditionalWait(ref BOStep step) 
{
   if (step.condition() == true)
   {
      debugBOStep("Conditional wait completed.");
      return true;
   }
   debugBOStep("Conditionally waiting.");
   return false;
}

void internalBODoEndStep()
{
   // It can be that we fail somewhere and cause a chain reaction that ends the BO in multiple spots, guard against this.
   if (isBuildOrderDone() == true)
   {
      return;
   }
   aiEcho("ENDING BO!");
   internalBOEndStrategy(); // This must be a mutable function because we don't have access to the boSystem class here.
   int mainBaseID = kbBaseGetMainID(cMyID);
   // Remove the second base. If we had units there they will now just become part of an auto created base.
   if (kbBaseGetIsIDValid(cMyID, internalGetSecondBaseID()) == true)
   {
      kbBaseDestroy(cMyID, internalGetSecondBaseID());
   }

   // Reset our base size.
   kbBaseSetDistance(cMyID, mainBaseID, kbGetAutoMyBaseCreationDistanceTC());

   int[] dummy = new int(1, 0);
   for (int i = 0; i < aiPlanGetActiveCount(); i++)
   {
      // Never delete the defend plan here.
      int planID = aiPlanGetIDByActiveIndex(i);
      switch (aiPlanGetType(planID))
      {
         case cPlanGather:
         {
            // Set params needed for auto managed eco transition.
            int kbResourceID = aiPlanGetVariableInt(planID, cGatherPlanKBResourceID, 0);
            // We got unlucky and are searching a resource atm.
            if (kbResourceGetIsIDValid(kbResourceID) == false)
            {
               aiPlanDestroy(planID);
               i--;
               continue;
            }
            int resourceType = kbResourceGetType(kbResourceID);
            int resourceSubType = kbResourceGetSubType(kbResourceID);
            int prio = aiGetResourceBreakdownPlanPriority(resourceType, resourceSubType, mainBaseID);
            aiPlanSetPriority(planID, prio);

            // Figure out what base this food resource is in... Default to main.
            // We only do this for food since we would never deplete our starting gold + wood and make a remote base for this during BO.
            
            int baseID = mainBaseID;
            if (resourceType == cResourceFood)
            {
               // No dropsites / moveable dropsites means there won't be bases auto created for them, we must do it manually.
               if (cMyCulture == cCultureAtlantean || cMyCulture == cCultureNorse)
               {
                  vector resourceLocation = kbResourceGetPosition(kbResourceID);
                  vector mainBasePosition = kbBaseGetLocation(cMyID, mainBaseID);
                  // This distance may change instantly due to strategy system base growth and be in range anyway, it is what it is...
                  float mainBaseDistance = kbBaseGetDistance(cMyID, mainBaseID);
                  if (xsVectorDistance(resourceLocation, mainBasePosition) > mainBaseDistance)
                  {
                     baseID = gRBDSystem.createRemoteGatherBase(resourceLocation, 20.0);
                     // Set a dummy breakdown so we don't warn below.
                     aiSetResourceBreakdown(resourceType, resourceSubType, 1, prio, 0.0, baseID, dummy, dummy, dummy);
                     debugBOStep("Creating a new remote gather base for " + aiPlanGetName(planID) + ".");
                  }
               }
               else
               {
                  int dropsiteID = kbResourceGetClosestDropsiteID(kbResourceID);
                  if (kbUnitGetIsIDValid(dropsiteID) == true)
                  {
                     vector closestDropsitePosition = kbUnitGetPosition(dropsiteID);
                     vector resourcePosition = kbResourceGetPosition(kbResourceID);
                     // Filter dropsites that are far away, cuz they aren't really for us...
                     if (xsVectorDistance(closestDropsitePosition, resourcePosition) < 15.0)
                     {
                        baseID = kbUnitGetBaseID(dropsiteID);
                     }
                     else
                     {
                        // We destroy here because this food plan has no real dropsite close.
                        // But this plan will hold a kbResourceID "hostage".
                        debugBOStep("Destroying " + aiPlanGetName(planID) + " because it has no close dropsite.");
                        aiPlanDestroy(planID);
                        i--;
                        continue;
                     }
                     if (baseID != mainBaseID)
                     {
                        // The distance for this remote gather base would've already been set at 37.50, reduce that to our wanted 20.0.
                        kbBaseSetDistance(cMyID, baseID, 20.0);
                        kbBaseSetFlag(cMyID, baseID, cBaseFlagRemoteGatherBase, true);
                        kbBaseSetFlag(cMyID, baseID, cBaseFlagRemoteFoodGatherBase, true);
                        // Set a dummy breakdown so we don't warn below.
                        aiSetResourceBreakdown(resourceType, resourceSubType, 1, prio, 0.0, baseID, dummy, dummy, dummy);
                        gRBDSystem.addRemoteGatherBase(baseID);
                        debugBOStep("Creating a new remote gather base for " + aiPlanGetName(planID) + ".");
                     }
                  }
                  else // Don't think this can ever hit since our TC would to need have died etc...
                  {
                     debugBOStep("Destroying gather plan because it has no valid dropsite ID.");
                     aiPlanDestroy(planID);
                     i--;
                     continue;
                  }
               }
            }
            aiPlanSetBaseID(planID, baseID);

            if (cMyCulture != cCultureNorse && cMyCulture != cCultureAtlantean && resourceType != cResourceFavor)
            {
               aiPlanSetVariableBool(planID, cGatherPlanAutoBuildDropsite, 0, true);
            }
            aiPlanSetVariableInt(planID, cGatherPlanResourceSubType, 0, resourceSubType);
            int breakdownID = aiGetResourceBreakdownID(resourceType, resourceSubType, baseID);
            if (breakdownID == -1)
            {
               aiEchoWarning("Breakdown missing when transitioning from BO to the next strategy. Losing gather plans now.");
               aiPlanDestroy(planID);
               i--;
               continue;
            }
            aiPlanSetVariableInt(planID, cGatherPlanBreakDownID, 0, breakdownID);
            aiPlanSetVariableBool(planID, cGatherPlanQuitWhenResourceIsInvalid, 0, true);
            int numVillagers = 0;
            switch (resourceType)
            {
               case cResourceFood:
               {
                  numVillagers = aiGetNumberGatherers(cUnitTypeAbstractVillager, cResourceFood);
                  break;
               }
               case cResourceWood:
               {
                  numVillagers = aiGetNumberGatherers(cUnitTypeAbstractVillager, cResourceWood);
                  break;
               }
               case cResourceGold:
               {
                  numVillagers = aiGetNumberGatherers(cUnitTypeAbstractVillager, cResourceGold);
                  break;
               }
               case cResourceFavor:
               {
                  numVillagers = aiGetNumberGatherers(cUnitTypeAbstractVillager, cResourceFavor);
                  break;
               }
            }

            // We have 1 plan per resource during BOs, for now.
            int[] numNeeded = new int(1, max(1, numVillagers - 2));
            int[] numWanted = new int(1, numVillagers);
            int[] numMax = new int(1, numVillagers + 2);
            numNeeded[0] = max(1, numVillagers - 2);
            numWanted[0] = max(1, numVillagers);
            numMax[0] = max(1, numVillagers + 2);
            int planPrio = aiGetResourceBreakdownPlanPriority(resourceType, resourceSubType, baseID);
            float percentage = aiGetResourceBreakdownPercentage(resourceType, resourceSubType, baseID);
            aiSetResourceBreakdown(resourceType, resourceSubType, 1, planPrio, percentage, baseID, numNeeded, numWanted, numMax);
            break;
         }
         case cPlanBuild:
         {
            // Break out build plans from parent plan.
            int parentPlanID = aiPlanGetParentID(planID);
            if (aiPlanGetIsIDValid(parentPlanID) == true)
            {
               // But not for gather plans...
               if (aiPlanGetType(parentPlanID) != cPlanGather)
               {
                  aiPlanRemoveParent(planID);
               }
            }
            // Finish the buildings we want during DM, Fortresses/Towers/TC/military production etc...
            if (cGameModeCurrent == cGameModeDeathmatch)
            {
               aiPlanSetPriority(planID, 100);
            }
            break;
         }
         case cPlanResearch:
         {
            // Check for age upgrades, save it back to the global.
            aiPopulateAgeUpList();

            int age = kbPlayerGetAge(cMyID);
            int num = aiGetAgeUpListCount(age + 1);
            int planTechID = aiPlanGetVariableInt(planID, cResearchPlanTechID, 0);

            for (int j = 0; j < num; j++)
            {
               int techID = aiGetAgeUpListByIndex(age + 1, j);
               if (techID == planTechID)
               {
                  aiPlanSetEventHandler(planID, cPlanEventStateChange, "ageUpPlanHandler");
                  gAgeUpResearchPlan = planID;
                  break;
               }
            }
            break;
         }
         case cPlanTrain:
         {
            // Unset the event handler.
            aiPlanSetEventHandler(planID, cTrainPlanEventUnitTrained, "");
            int puid = aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0);
            int numFunctionUnits = kbFunctionUnitGetNumber(kbPlayerGetCiv(cMyID), cUnitFunctionGatherer);
            for (int j = 0; j < numFunctionUnits; j++)
            {
               int functionUnitID = kbFunctionUnitGetByIndex(kbPlayerGetCiv(cMyID), cUnitFunctionGatherer, j);
               if (puid == functionUnitID)
               {
                  aiPlanDestroy(planID);
                  i--;
               }
            }
            break;
         }
         case cPlanExplore:
         {
            aiPlanDestroy(planID);
            i--;
            break;
         }
         case cPlanEmpower:
         {
            if (cGameModeCurrent == cGameModeDeathmatch)
            {
               if (aiPlanGetVariableInt(planID, cEmpowerPlanTargetTypeID, 0) == cUnitTypeSettlement)
               {
                  continue;
               }
            }
            aiPlanDestroy(planID);
            i--;
            break;
         }
      }
   }
   
   xsDisableRuleGroup("groupBOSystem");
   xsDisableRule("addMilitaryToDefendPlanDuringBO");
   // We disabled these rules during BO system init, turn it on again.
   xsEnableRule("scoutingMonitor");
   if (cMyCulture == cCultureGreek)
   {
      xsEnableRule("kataskoposManager");
   }
   //xsEnableRule("defenseReflex");
   xsEnableRule("newDefend");
   // If we've quit early we need to fix up the Oracles.
   if (cMyCulture == cCultureAtlantean && xsIsRuleEnabled("startupOracleScoutingMonitor") == true)
   {
      int oracleQuery = useSimpleUnitQuery(cUnitTypeOracle, cMyID, cUnitStateAlive);
      int numberFound = kbUnitQueryExecute(oracleQuery);
      for (int i = 0; i < numberFound; i++)
      {
         int unitID = kbUnitQueryGetResult(oracleQuery, i);
         int planID = kbUnitGetPlanID(unitID);
         if (aiPlanGetIsIDValid(planID) == true)
         {
            aiPlanDestroy(planID);
         }
      }
      xsDisableRule("startupOracleScoutingMonitor");
      xsEnableRule("oracleMonitor");
      xsEnableRule("oracleMaintainMonitor");
   }
   
   // We didn't activate the new rule groups yet since ageUpEventHandler early outs during BOs.
   int age = kbPlayerGetAge(cMyID);
   if (age >= cAge2)
   {
      xsEnableRuleGroup("defaultClassicalRules");
   }
   if (age >= cAge3)
   {
      xsEnableRuleGroup("defaultHeroicRules");
   }
   if (age >= cAge4)
   {
      xsEnableRuleGroup("defaultMythicRules");
   }
   if (age >= cAge5)
   {
      xsEnableRuleGroup("defaultWonderRules");
   }
   gBOEndTime = xsGetTime();
}