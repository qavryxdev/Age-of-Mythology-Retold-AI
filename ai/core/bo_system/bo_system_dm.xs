//==============================================================================
/* bo_system_dm.xs

   This file contains all functions/rules that BO files can directly call, including DM.

*/
//==============================================================================


//==============================================================================
// dmHelpWithAgeUpBuildings
// This rule queries for builders that are either not doing anything or in the food plan and assigns them to
// the build plan for the buildings that are needed to advance: Temple / Armory / Fortress.
//==============================================================================
rule dmHelpWithAgeUpBuildings
inactive
minInterval 3
{
   if (isBuildOrderDone() == true)
   {
      xsDisableRule("dmHelpWithAgeUpBuildings");
      return;
   }
   int currentAge = kbPlayerGetAge(cMyID);
   int buildingPUID = cUnitTypeTemple;
   int builderPUID = cUnitTypeAbstractVillager;
   if (cMyCulture == cCultureNorse)
   {
      builderPUID = cUnitTypeLogicalTypeNorseSoldierThatBuilds;
   }

   if (currentAge == cAge2)
   {
      buildingPUID = gArmoryUnit;
   }

   if (currentAge == cAge3)
   {
      switch (cMyCulture)
      {
         case cCultureGreek:
         {
            buildingPUID = cUnitTypeFortress;
            break;
         }
         case cCultureEgyptian:
         {
            buildingPUID = cUnitTypeMigdolStronghold;
            break;
         }
         case cCultureNorse:
         {
            buildingPUID = cUnitTypeHillFort;
            // As Norse we make multiple Hill Forts, don't aid the consecutive Hill Forts.
            if (kbUnitCount(buildingPUID, cMyID, cUnitStateAlive) >= 1)
            {
               xsDisableRule("dmHelpWithAgeUpBuildings");
               return;
            }
            break;
         }
         case cCultureAtlantean:
         {
            buildingPUID = cUnitTypePalace;
            // As Atty we make multiple Palaces, don't aid the consecutive Palaces.
            if (kbUnitCount(buildingPUID, cMyID, cUnitStateAlive) >= 1)
            {
               xsDisableRule("dmHelpWithAgeUpBuildings");
               return;
            }
            break;
         }
      }
   }

   int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, buildingPUID, 0);
   if (aiPlanGetIsIDValid(planID) == false)
   {
      return;
   }

   int queryID = useSimpleUnitQuery(builderPUID);
   int numResults = kbUnitQueryExecute(queryID);
   int[] results = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < numResults; i++)
   {
      int unitID = results[i];
      int unitPlanID = kbUnitGetPlanID(unitID);
      if (aiPlanGetIsIDValid(unitPlanID) == false ||
          unitPlanID == gPrimaryLandDefendPlan ||
          aiPlanGetParentID(unitPlanID) == gPrimaryLandDefendPlan)
      {
         debugBOStep("dmHelpWithAgeUpBuildings - Adding " + unitID + " to plan " + aiPlanGetName(planID) + ".");
         aiPlanAddUnitType(planID, builderPUID, 1, 1, 1, true);
         aiPlanAddUnit(planID, unitID);
      }
   }
}

//==============================================================================
// dmAssignBuilderHelper
//==============================================================================
bool dmAssignBuilderHelper(int planID = -1, string caller = "ERROR")
{
   int builderPUID = cUnitTypeAbstractVillager;
   if (cMyCulture == cCultureNorse)
   {
      builderPUID = cUnitTypeLogicalTypeNorseSoldierThatBuilds;
   }

   int numNeeded = aiPlanGetNumberNeededUnits(planID, builderPUID);
   int queryID = useSimpleUnitQuery(builderPUID);
   int numResults = kbUnitQueryExecute(queryID);
   int[] results = kbUnitQueryGetResults(queryID);
   int numAdded = 0;
   for (int i = 0; i < numResults; i++)
   {
      int unitID = results[i];
      int unitPlanID = kbUnitGetPlanID(unitID);
      if (aiPlanGetIsIDValid(unitPlanID) == false ||
          unitPlanID == gPrimaryLandDefendPlan ||
          aiPlanGetParentID(unitPlanID) == gPrimaryLandDefendPlan)
      {
         debugBOStep(caller + " - Adding " + unitID + " to plan " + aiPlanGetName(planID) + ".");
         aiPlanAddUnit(planID, unitID);
         numAdded++;
         if (numAdded == numNeeded)
         {
            return true;
         }
      }
   }

   aiEcho("ATTENTION: " + caller + " - couldn't assign enough builders for " + aiPlanGetName(planID) + ", this makes the BO fail!!!");
   internalBODoEndStep();
   return false;
}

//==============================================================================
// dmAssignBuilderMainBase
//==============================================================================
void dmAssignBuilderMainBase(int planID = -1)
{
   if (dmAssignBuilderHelper(planID, "dmAssignBuilderMainBase") == false)
   {
      aiPlanDestroy(planID);
      return;
   }

   int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
   int buildingPUID = aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0);
   if (buildingPUID == cUnitTypeTemple)
   {
      // Need to build the Temple fast, no buffer space, build close to the assigned builders.
      kbBuildingPlacementSetBuildingPUID(bpID, buildingPUID);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
      avoidBlockingImportantSpots(planID, bpID);
      kbBuildingPlacementSetBufferSpace(bpID, 0.0);
      kbBuildingPlacementSetBaseID(bpID, boSystem.mainBaseID);
      aiPlanSetBaseID(planID, boSystem.mainBaseID);
      kbBuildingPlacementAddPositionInfluence(bpID, kbUnitGetPosition(aiPlanGetUnitIDByIndex(planID, 0)), 1000.0, 35.0, cFalloffLinear);
   }
   else if (buildingPUID == gHouseUnit)
   {
      // DM Houses we need to build fast and close to each other, don't care about walling in Towers.
      kbBuildingPlacementSetBuildingPUID(bpID, buildingPUID);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
      avoidBlockingImportantSpots(planID, bpID);
      kbBuildingPlacementSetBufferSpace(bpID, 1.0); // Small buffer space, we just need speed...
      kbBuildingPlacementSetBaseID(bpID, boSystem.mainBaseID);
      aiPlanSetBaseID(planID, boSystem.mainBaseID);
      kbBuildingPlacementAddPositionInfluence(bpID, kbUnitGetPosition(aiPlanGetUnitIDByIndex(planID, 0)), 1000.0, 35.0, cFalloffLinear);
   }
   else
   {
      kbBuildingPlacementSetBuildingPUID(bpID, buildingPUID);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
      determineBuildingPlacementLogic(planID, bpID, boSystem.mainBaseID, -1, -1);
   }

   // Try to place close to second base.
   if (buildingPUID == gArmoryUnit)
   {
      kbBuildingPlacementAddPositionInfluence(bpID, boSystem.secondBasePosition, cMaxFloat, 100.0, cFalloffLinear);
   }
}

//==============================================================================
// dmAssignBuilderSecondBase
//==============================================================================
void dmAssignBuilderSecondBase(int planID = -1)
{
   if (dmAssignBuilderHelper(planID, "dmAssignBuilderSecondBase") == false)
   {
      aiPlanDestroy(planID);
      return;
   }

   int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
   kbBuildingPlacementSetBuildingPUID(bpID, aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0));
   aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
   determineBuildingPlacementLogic(planID, bpID, boSystem.secondBaseID, -1, -1);
}

//==============================================================================
// dmHelperNoBuilders
//==============================================================================
void dmHelperNoBuilders(int planID = -1, int baseID = -1)
{
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
   int puid = aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0);
   kbBuildingPlacementSetBuildingPUID(bpID, puid);
   aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
   if (puid == gHouseUnit)
   {
      aiPlanSetBaseID(planID, baseID);
      kbBuildingPlacementSetBaseID(bpID, baseID);
      avoidBlockingImportantSpots(planID, bpID);
      kbBuildingPlacementSetBufferSpace(bpID, 3.0);
      float halfObstruction = kbPlayerGetProtoStatFloat(cMyID, puid, cProtoStatObstruction) / 2.0;
      // Avoid gold mines more than regular...
      kbBuildingPlacementAddUnitInfluence(bpID, cUnitTypeGoldResource, -10000, 12.0 + halfObstruction, cFalloffNone, -1,
         cPlayerMotherNatureID);
   }
   else
   {
      determineBuildingPlacementLogic(planID, bpID, baseID, -1, -1);
   }
}

//==============================================================================
// dmCreateBuildPlanMainBaseNoBuilders
//==============================================================================
void dmCreateBuildPlanMainBaseNoBuilders(int planID = -1)
{
   dmHelperNoBuilders(planID, boSystem.mainBaseID);
}

//==============================================================================
// dmCreateBuildPlanSecondBaseNoBuilders
//==============================================================================
void dmCreateBuildPlanSecondBaseNoBuilders(int planID = -1)
{
   dmHelperNoBuilders(planID, boSystem.secondBaseID);
}

//==============================================================================
// dmBuildTownCenterSecondBase
//==============================================================================
void dmBuildTownCenterSecondBase()
{
   int numBuilders = 7;
   if (cMyCulture == cCultureAtlantean)
   {
      numBuilders = 4;
   }
   int planID = -1;
   if (cMyCulture == cCultureNorse)
   {
      planID = createSocketBuildPlan(cUnitTypeTownCenter, boSystem.secondBaseTCID, 100, 1, true);
   }
   else
   {
      planID = createSocketBuildPlan(cUnitTypeTownCenter, boSystem.secondBaseTCID, 100, numBuilders, true);
   }

   int builderPUID = cUnitTypeAbstractVillager;
   if (cMyCulture == cCultureNorse)
   {
      builderPUID = cUnitTypeLogicalTypeNorseSoldierThatBuilds;
   }
   // Try to add as many free builders as we can, this doesn't fail a BO if we can't find all.
   int queryID = useSimpleUnitQuery(builderPUID);
   int numResults = kbUnitQueryExecute(queryID);
   int[] results = kbUnitQueryGetResults(queryID);
   int numAdded = 0;
   for (int i = 0; i < numResults; i++)
   {
      int unitID = results[i];
      int unitPlanID = kbUnitGetPlanID(unitID);
      if (aiPlanGetIsIDValid(unitPlanID) == false ||
          unitPlanID == gPrimaryLandDefendPlan ||
          aiPlanGetParentID(unitPlanID) == gPrimaryLandDefendPlan)
      {
         debugBOStep("dmBuildTownCenterSecondBase - Adding " + unitID + " to plan " + aiPlanGetName(planID) + ".");
         if (cMyCulture == cCultureNorse)
         {
            aiPlanAddUnitType(planID, builderPUID, 1, 1, 1, true);
         }
         aiPlanAddUnit(planID, unitID);
         numAdded++;
         // Don't put a cap for Norse, just assign all builders we can find.
         if (cMyCulture != cCultureNorse && numAdded == numBuilders)
         {
            return;
         }
         // We don't want to assign all our builders to this TC on lower difficulties as Norse because we won't train any
         // new units any time soon and need some free units to build other stuff/fight.
         if (cMyCulture == cCultureNorse && cDifficultyCurrent <= cDifficultyHard && (i + 5 > numResults))
         {
            return;
         }
      }
   }
}

//==============================================================================
// moveDefendPlanSecondBase
//==============================================================================
void moveDefendPlanSecondBase()
{
   if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == true)
   {
      aiPlanSetVariableFloat(gPrimaryLandDefendPlan, cDefendPlanEngageRange, 0, kbBaseGetDistance(cMyID, boSystem.secondBaseID) + 10.0);
      aiPlanSetVariableInt(gPrimaryLandDefendPlan, cDefendPlanTargetBaseID, 0, boSystem.secondBaseID);
      aiPlanSetBaseID(gPrimaryLandDefendPlan, boSystem.secondBaseID);
      aiPlanSetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0, kbBaseGetMilitaryGatherPoint(cMyID, boSystem.secondBaseID));
   }
}

//==============================================================================
// dmHeroizeStartingCitizens
//==============================================================================
void dmHeroizeStartingCitizens()
{
   int queryID = useSimpleUnitQuery(cUnitTypeVillagerAtlantean);
   int numResults = kbUnitQueryExecute(queryID);
   int[] results = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < numResults; i++)
   {
      createSimpleResearchPlanSpecificResearcher(cTechVillagerAtlanteanToHero, results[i]);
   }
}

//==============================================================================
// dmFixupCitizenMaintainPlan
//==============================================================================
void dmFixupCitizenMaintainPlan(int planID = -1)
{
   aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, 1);
}

//==============================================================================
// dmHeroizeStartingOracles
//==============================================================================
rule dmHeroizeStartingOracles
inactive
minInterval 1
{
   int queryID = useSimpleUnitQuery(cUnitTypeOracle);
   int numResults = kbUnitQueryExecute(queryID);
   int[] results = kbUnitQueryGetResults(queryID);
   // Goofy stuff, we first move our Oracles back to the TC before we heroize, otherwise we run the risk of them heroizing
   // while standing on the Temple foundation and failing the BO... We have no haste with heroizing these luckily...
   if (xsGetTime() < 10)
   {
      for (int i = 0; i < numResults; i++)
      {
         aiTaskMoveUnit(results[i], kbUnitGetPosition(getUnit(cUnitTypeTownCenter)));
      }
      return;
   }
   for (int i = 0; i < numResults; i++)
   {
      createSimpleResearchPlanSpecificResearcher(cTechOracleToHero, results[i]);
   }
   xsDisableRule("dmHeroizeStartingOracles");
}

//==============================================================================
// dmHeroizeMilitary
//==============================================================================
void dmHeroizeMilitary()
{
   int queryID = useSimpleUnitQuery(cUnitTypeMurmillo);
   int numResults = kbUnitQueryExecute(queryID);
   int[] results = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < results.size() && i < 2; i++)
   {
      int unitID = results[i];
      createSimpleResearchPlanSpecificResearcher(cTechMurmilloToHero, unitID, 100, true);
   }
   queryID = useSimpleUnitQuery(cUnitTypeArcus);
   numResults = kbUnitQueryExecute(queryID);
   results = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < results.size() && i < 2; i++)
   {
      int unitID = results[i];
      createSimpleResearchPlanSpecificResearcher(cTechArcusToHero, unitID, 100, true);
   }
}

//==============================================================================
// dmEmpowerSecondTownCenterConstruction
// Empowers the second Town Center and destroys itself after that is done.
//==============================================================================
rule dmEmpowerSecondTownCenterConstruction
inactive
minInterval 1
{
   static int empowerPlanID = -1;
   if (aiPlanGetIsIDValid(empowerPlanID) == false)
   {
      empowerPlanID = aiPlanCreate("DM Empower Second TC", cPlanEmpower, -1, gEconomyCategoryID);
      aiPlanSetVariableInt(empowerPlanID, cEmpowerPlanTargetTypeID, 0, cUnitTypeSettlement);
      aiPlanSetVariableInt(empowerPlanID, cEmpowerPlanNoTargetUnitRemovalTimeout, 0, 30);
      aiPlanSetVariableBool(empowerPlanID, cEmpowerPlanRequiresTargetUsedByAnotherPlan, 0, false);
      aiPlanAddUnitType(empowerPlanID, cUnitTypePharaoh, 1, 1, 1);
      aiPlanSetPriority(empowerPlanID, 100);
   }

   // We end after we get our TC up or 5 minutes passed (which means we somehow got blocked on the TC :( );
   if (kbUnitCount(cUnitTypeTownCenter, cMyID, cUnitStateAlive) == 2 || xsGetTime() > 300)
   {
      aiPlanDestroy(empowerPlanID);
      empowerPlanID = -1;
      debugBO("Destroying empower plan for second TC.");
      xsDisableRule("dmEmpowerSecondTownCenterConstruction");
      return;
   }

   if (aiPlanGetNumberUnits(empowerPlanID) <= 0)
   {
      aiPlanAddUnit(empowerPlanID, getUnit(cUnitTypePharaoh));
   }

   int tcID = getUnit(cUnitTypeSettlement, cMyID, cUnitStateBuilding);
   if (kbUnitGetIsIDValid(tcID) == false)
   {
      return;
   }
   aiPlanSetVariableInt(empowerPlanID, cEmpowerPlanTargetID, 0, tcID);
}