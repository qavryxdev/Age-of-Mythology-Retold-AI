//==============================================================================
/* handlers.xs

   This file contains all handlers.
*/

//==============================================================================
// houseMonumentBuildEventHandler
//==============================================================================
void houseMonumentBuildEventHandler(int buildPlanID = -1)
{
   int planState = aiPlanGetState(buildPlanID);
   if (planState != cPlanStateFailed)
   {
      return;
   }

   // We can't afford to have these build plans fail, especially Houses.
   // To prevent the AI getting stuck we have a failsafe below.
   // This failsafe creates a buildplan for the original building but now allows the entire base to be used.
   // In regular circumstances this should always succeed now.
   int buildingTypeID = aiPlanGetVariableInt(buildPlanID, cBuildPlanBuildingTypeID, 0);
   debugBuildings("Our " + kbProtoUnitGetName(buildingTypeID) + " placement failed, we're now activating our failsafe in " + 
      "houseMonumentBuildEventHandler.");

   int safestBaseID = getMostDefendedTCBase();
   if (safestBaseID == -1)
   {
      debugBuildings("We currently have no TC base, not activating our failsafe.");
      return;
   }

   int planID = aiPlanCreate("Failsafe Build " + kbDefaultGetProtoStatString(buildingTypeID, cProtoStatName), cPlanBuild, -1,
                             gBuildingsCategoryID);

   // Building placement.
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
   kbBuildingPlacementSetBuildingPUID(bpID, buildingTypeID);
   kbBuildingPlacementSetBaseID(bpID, safestBaseID);
   avoidBlockingImportantSpots(planID, bpID);

   // Plan.
   aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, buildingTypeID);
   aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
   int[] unitTypes = aiPlanGetUnitTypes(planID);
   if (unitTypes.size() != 0)
   {
      for (int i = 0; i < unitTypes.size(); i++)
      {
         int numNeeded = aiPlanGetNumberNeededUnits(planID, unitTypes[i]);
         int numWanted = aiPlanGetNumberWantedUnits(planID, unitTypes[i]);
         int numMax =  aiPlanGetNumberMaxUnits(planID, unitTypes[i]);
         aiPlanAddUnitType(planID, unitTypes[i], numNeeded, numWanted, numMax);
      }
   }
   else
   {
      if (cMyCulture != cCultureNorse)
      {
         aiPlanAddUnitType(planID, gEconUnit, 1, 1, 1);
      }
      else
      {
         aiPlanAddUnitType(planID, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, 1, 1);
      }
   }
   aiPlanSetPriority(planID, aiPlanGetPriority(buildPlanID));
}

//==============================================================================
// ageUpPlanHandler
//==============================================================================
void ageUpPlanHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateDone)
   {
      // We've aged up, need to reset our plan ID.
      gAgeUpResearchPlan = -1;
   }
   else if (state == cPlanStateFailed)
   {
      // This can basically never happen but take care of it anyway.
      gAgeUpResearchPlan = -1;
   }
   // currently not used for anything.
}

//==============================================================================
// ageUpEventHandler
//==============================================================================
void ageUpEventHandler(int playerID = -1)
{
   if (playerID == cMyID)
   {
      // Chat about this.
      int newAge = kbPlayerGetAge(cMyID);
      for (int i = 1; i <= cNumberPlayers; i++)
      {
         if (i == cMyID || kbPlayerIsEnemy(i) == false || kbPlayerHasLost(i) == true || kbPlayerGetAge(i) >= newAge)
         {
            continue;
         }
         debugChats("Sending prompt " + cAICommPromptToEnemyTheyAreBehindInAge + " to " + i + ".");
         aiCommsSendStatement(i, cAICommPromptToEnemyTheyAreBehindInAge);
      }

      // An age up usually means we need to switch strategies, make sure that happens (nearly) instantly.
      // We don't call the strategyMonitor rule directly because we need to make sure that godPowerGrantedHandler is processed before.
      // And since all events are handled before rules we know by doing this that we for sure first ran godPowerGrantedHandler.
      // If we would call strategyMonitor directly here we run the risk of ageUpEventHandler firing before godPowerGrantedHandler and then it's toast.
      xsRuleIgnoreIntervalOnce("strategyMonitor");
      
      gAgeUpTimes[newAge] = xsGetTime();
      if (boSystem.done == false)
      {
         return; // Don't activate the new rule groups, boInternalEndStep takes care of that.
      }
      switch (newAge)
      {
         case cAge2:
         {
            xsEnableRuleGroup("defaultClassicalRules");
            break;
         }
         case cAge3:
         {
            xsEnableRuleGroup("defaultHeroicRules");
            break;
         }
         case cAge4:
         {
            xsEnableRuleGroup("defaultMythicRules");
            break;
         }
         case cAge5:
         {
            xsEnableRuleGroup("defaultWonderRules");
            break;
         }
      }
   }
   else
   {
      int age = kbPlayerGetAge(playerID);
      if (gFastestAgeUpTimes[age] == -1)
      {
         gFastestAgeUpTimes[age] = xsGetTime();
         debugTechs("Fastest age up recorded for " + getAgeName(age) + " at time " + turnNumberIntoTimeDisplay(gFastestAgeUpTimes[age]) + ".");
      }

      // Chat about this.
      if (kbPlayerIsEnemy(playerID) == true && age > kbPlayerGetAge(cMyID))
      {
         debugChats("Sending prompt " + cAICommPromptToEnemyIAmBehindInAge + " to " + playerID + ".");
         aiCommsSendStatement(playerID, cAICommPromptToEnemyIAmBehindInAge);
      }
   }
}

//==============================================================================
// resetMilitaryResearchPlan
//==============================================================================
void resetMilitaryResearchPlan(int planID = -1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateDone || state == cPlanStateFailed)
   {
      gMilitaryResearchPlan = -1;
      // Go again instantly.
      xsRuleIgnoreIntervalOnce("militaryUpgradeManager");
   }
}

//==============================================================================
// resetMilitaryDockResearchPlan
//==============================================================================
void resetMilitaryDockResearchPlan(int planID = -1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateDone || state == cPlanStateFailed)
   {
      gMilitaryDockResearchPlan = -1;
      // Go again instantly.
      xsRuleIgnoreIntervalOnce("dockUpgradeManager");
   }
}

//==============================================================================
// resetEconomyResearchPlan
//==============================================================================
void resetEconomyResearchPlan(int planID = -1)
{
   int state = aiPlanGetState(planID);
   if (state == cPlanStateDone || state == cPlanStateFailed)
   {
      gEconomyResearchPlan = -1;
      gAreResearchingForcedEconomicUpgrade = false;
   }
}

//==============================================================================
// onAutoPlanCreate
// This handler is called each time a new plan is created.
//==============================================================================
void onAutoPlanCreate(int planID = -1)
{
   int planType = aiPlanGetType(planID);
   switch (planType)
   {
      case cPlanGather:
      {
         if (gOverrideAutomaticDropsitePlacement == false ||
             // Favor gathering doesn't need a dropsite
             aiPlanGetVariableInt(planID, cGatherPlanResourceType, 0) == cResourceFavor)
         {
            aiPlanSetVariableBool(planID, cGatherPlanAutoBuildDropsite, 0, false);
         }
         // TODO Ox Carts should be added to Farm plans that have no more TC left.
         if (cMyCulture == cCultureNorse &&
             aiPlanGetVariableInt(planID, cGatherPlanResourceSubType, 0) != cAIResourceSubTypeFarm &&
             aiPlanGetVariableInt(planID, cGatherPlanResourceSubType, 0) != cAIResourceSubTypeHerdable)
         {
            aiPlanAddUnitType(planID, cUnitTypeOxCart, 1, 1, 1);
         }
         if (gMainGatherBase != -1)
         {
            aiPlanSetFlag(planID, cPlanFlagStopUnitsOnRemove, true);
         }
      }
   }
}

//==============================================================================
// dockAnalysis
// This will be called each time we create a Dock to update the positions.
// If we already have an alive dock we don't do anything since those positions are still valid then.
//==============================================================================
void dockAnalysis(int planID = -1)
{
   int planState = aiPlanGetState(planID);
   switch (planState)
   {
      case cPlanStateDone:
      {
         if (kbUnitCount(cUnitTypeDock, cMyID, cUnitStateAlive) >= 1)
         {
            debugBuildings("dockAnalysis - we already had a Dock, not analyzing positions again.");
            return;
         }
         int unitID = aiPlanGetVariableInt(planID, cBuildPlanFoundationID, 0);
         vector dockPosition = kbUnitGetPosition(unitID);
         int areaID = kbAreaGetIDByPosition(dockPosition);
         vector preferedPosition = dockPosition;
         if (isAreaPassableByLand(areaID) == false)
         {
            debugBuildings("dockAnalysis - our new Dock isn't on land, analyzing a new spot.");
            // If our Dock is not located on a land area, which can happen.
            // We try 8 positions around the Dock, of which some must be land areas.
            // We then use that position to get an update on our map info.
            preferedPosition = cInvalidVector;
            vector[] offsets = new vector(8, cInvalidVector);
            offsets[0] = dockPosition + vector(5.0, 0.0, 5.0);
            offsets[1] = dockPosition + vector(5.0, 0.0, -5.0);
            offsets[2] = dockPosition + vector(5.0, 0.0, 0.0);
            offsets[3] = dockPosition + vector(-5.0, 0.0, 5.0);
            offsets[4] = dockPosition + vector(-5.0, 0.0, -5.0);
            offsets[5] = dockPosition + vector(-5.0, 0.0, 0.0);
            offsets[6] = dockPosition + vector(0.0, 0.0, 5.0);
            offsets[7] = dockPosition + vector(0.0, 0.0, -5.0);
            for (int i = 0; i < 8; i++)
            {
               if (isAreaPassableByLand(kbAreaGetIDByPosition(offsets[i])) == true)
               {
                  preferedPosition = offsets[i];
                  break;
               }
            }
            if (preferedPosition == cInvalidVector)
            {
               return;
            }
            areaID = kbAreaGetIDByPosition(preferedPosition);
            debugBuildings("dockAnalysis - close shoreline area found with ID: " + areaID);
         }
         analyseNavalPositions(areaID, preferedPosition, true);
         break;
      }
   }
}

//==============================================================================
// kothChangedOwnerHandler
//==============================================================================
void kothChangedOwnerHandler(int playerID = -1)
{
   int currentTime = xsGetTime();
   if (playerID == cMyID)
   {
      gKOTHIsOwnedByAllies = true;
   }
   else
   {
      gKOTHIsOwnedByAllies = kbPlayerIsAlly(playerID) == true;
   }
   // Panic always false, since it just got captured timer reset.
   gAttackManager.mKOTHPanic = false;
   gKOTHOwnedBy = playerID;
   gKOTHStartTime = currentTime;
   aiEcho("KOTH got captured by playerID: " + playerID + ", who is an ally of ours: " +
      xsBoolToString(gKOTHIsOwnedByAllies) + ", at time " + turnNumberIntoTimeDisplay(currentTime) + ".");

   if (gKOTHIsOwnedByAllies == false && aiPlanGetIsIDValid(gKOTHDefendPlanID) == true)
   {
      debugMilitaryDefending("We lost the KOTH, setting the defend plan to no more units.");
      aiPlanSetFlag(gKOTHDefendPlanID, cPlanFlagNoMoreUnits, true);
   }
}