//==============================================================================
/* buildings_economic.xs

   This file is intended for managing what economic buildings the AI should create and when.

*/
//==============================================================================

//==============================================================================
// House monitor
// Build extra houses if we need them.
//==============================================================================
rule houseMonitor
inactive
group defaultArchaicRules
minInterval 3
{
   if (checkStrategyFlag(cStrategyFlagBuildHouses) == false)
   {
      return;
   }
   debugBuildings("--- Running Rule houseMonitor. ---");

   int numHousesNeeded = calculateNumberHousesNeeded();
   if (numHousesNeeded == 0)
   {
      return;
   }
   // Spread out our houses over Town Center bases.
   int baseID = getRandomTownCenterBaseID();
   createSimpleBuildPlan(gHouseUnit, numHousesNeeded, 95, baseID, 1);
}

//==============================================================================
// mainBaseTCMonitor
// Always try to rebuild the TC in our mainbase.
//==============================================================================
rule mainBaseTCMonitor
group defaultArchaicRules
inactive
minInterval 5
{
   static bool firstRun = true;
   if (checkStrategyFlag(cStrategyFlagAutomaticMainBaseTCRebuild) == false)
   {
      if (aiPlanGetIsIDValid(gMainBaseTCBuildPlan) == true)
      {
         aiPlanDestroy(gMainBaseTCBuildPlan);
      }
      return;
   }
   debugBuildings("--- Running Rule mainBaseTCMonitor. ---");

   static int previousRunMainBaseID = -1;
   static bool previousRunMainBaseHadTC = false;
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID == -1)
   {
      // TODO somehow chose a settlement to rebuild?
      debugBuildings("We've lost all buildings on the map.");
      return;
   }
   vector mainBaseLocation = kbBaseGetLocation(cMyID, mainBaseID);
   bool mainBaseHasTC = kbBaseIsFlagSet(cMyID, mainBaseID, cBaseFlagTownCenter);
   if (previousRunMainBaseID != mainBaseID)
   {
      if (firstRun == true)
      {
         debugBuildings("Our first main base has ID: " + mainBaseID + ", and has a Town Center: " + mainBaseHasTC + ".");
      }
      else
      {
         debugBuildings("Our main base has swapped from " + previousRunMainBaseID + " to " + mainBaseID +
            ", this new main base has a Town Center: " + mainBaseHasTC + ".");
      }
      previousRunMainBaseID = mainBaseID;
      previousRunMainBaseHadTC = mainBaseHasTC;
      firstRun = false;
   }

   if (previousRunMainBaseHadTC == true && mainBaseHasTC == false)
   {
      // We've clearly lost our Town Center in our main base, we need to rebuild ASAP!
      debugBuildings("We lost our Town Center in our main base!");
       // Check if we already have a plan to rebuild our TC.
      if (aiPlanGetIsIDValid(gMainBaseTCBuildPlan) == false)
      {
         int settlementID = getClosestUnitByLocation(cUnitTypeSettlement, 0, cUnitStateAny, mainBaseLocation, kbBaseGetDistance(cMyID, mainBaseID));
         if (kbUnitGetIsIDValid(settlementID) == false)
         {
            debugBuildings("Somebody has stolen our Town Center, this is very bad!");
            // TODO react somehow.
            return;
         }
         debugBuildings("We will try and rebuild our Town Center now ASAP.");
         // Dropsite placement still has higher prio so we don't potentially block ourself from gathering the resources needed.
         // We set this build plan to having a high Need of builders.
         gMainBaseTCBuildPlan = createSocketBuildPlan(cUnitTypeTownCenter, settlementID, 90, cCalculateNumBuildersAutomatically, true);
         aiPlanSetEventHandler(gMainBaseTCBuildPlan, cPlanEventStateChange, "mainBaseTCBPHandler");
      }
      return;
   }
}

//==============================================================================
// mainBaseTCBPHandler
//==============================================================================
void mainBaseTCBPHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   switch (state)
   {
      case cPlanStateDone:
      {
         debugBuildings("Our main base TC build plan succeeded YAY!");
         sendStatementToAllies(cAICommPromptToAllyCompletedTownCenter);
         gMainBaseTCBuildPlan = -1;
         break;
      }
      case cPlanStateFailed:
      {
         debugBuildings("Our main base TC build plan somehow failed, trying to restart ASAP.");
         gMainBaseTCBuildPlan = -1;
         mainBaseTCMonitor();
         break;
      }
   }
}

//==============================================================================
// tcRepairMonitor
// Always repair our Town / Citadel Centers.
//==============================================================================
rule tcRepairMonitor
group defaultArchaicRules
inactive
minInterval 15
{
   if (checkStrategyFlag(cStrategyFlagAutomaticTCRepair) == false)
   {
      return;
   }
   debugBuildings("--- Running Rule tcRepairMonitor. ---");
   
   int queryID = useSimpleUnitQuery(cUnitTypeAbstractTownCenter, cMyID, cUnitStateAlive);
   kbUnitQueryExecute(queryID);
   int[] results = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < results.size(); i++)
   {
      int unitID = results[i];
      if (kbUnitGetStatFloat(unitID, cUnitStatCurrHP) < kbUnitGetStatFloat(unitID, cUnitStatMaxHP))
      {
         // We need to repair!
         if (aiPlanGetIDByTypeAndVariableIntValue(cPlanRepair, cRepairPlanTargetID, unitID) < 0)
         {
            debugBuildings("Found a TC/Citadel(" + unitID + ") that has been damaged, creating a repair plan for it.");
            int protoUnitID = kbUnitGetProtoUnitID(unitID);
            int planID = aiPlanCreate("Repair " + kbProtoUnitGetName(protoUnitID) + " ID: " + unitID, cPlanRepair, -1,
                                      gBuildingsCategoryID);
            aiPlanSetVariableInt(planID, cRepairPlanTargetID, 0, unitID);
            // Little bit higher prio since we need these buildings to remain alive.
            aiPlanSetPriority(planID, 60);
            // Repair a Citadel Center with a few more units since they're so valuable.
            addBuilderTypesToPlan(planID, protoUnitID, protoUnitID == cUnitTypeCitadelCenter ? 4 : 2, true);
            aiPlanSetBaseID(planID, kbUnitGetBaseID(unitID));
         }
      }
   }
}

//==============================================================================
// tcExpansionMonitor
// Create more Town Centers during the game.
//==============================================================================
rule tcExpansionMonitor
group defaultHeroicRules
inactive
minInterval 60
{
   // Lower difficulties only rebuild their main TC.
   if (cDifficultyCurrent <= cDifficultyModerate)
   {
      xsDisableRule("tcExpansionMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutomaticTCExpansion) == false)
   {
      return;
   }
   debugBuildings("--- Running Rule tcExpansionMonitor. ---");

   // We may delay this below, so reset every time.
   xsSetRuleMinInterval("tcExpansionMonitor", 60);

   int tcCount = buildingGetNumberAliveAndPlanned(cUnitTypeTownCenter);
   if (tcCount == 1)
   {
      int closestSettlementID = getClosestUnitByLocation(cUnitTypeSettlement, 0, cUnitStateAlive,
                                   kbBaseGetLocation(cMyID, getRandomTownCenterBaseID()), 100.0);
      if (kbUnitGetIsIDValid(closestSettlementID) == true)
      {
         int planID = aiPlanCreate("Build Plan for 1 Town Center", cPlanBuild, -1, gBuildingsCategoryID);
         // Building Placement.
         int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
         kbBuildingPlacementSetSocketID(bpID, closestSettlementID);
         kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeTownCenter);

         // Plan.
         aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypeTownCenter);
         aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
         aiPlanSetPriority(planID, 55);
         addBuilderTypesToPlan(planID, cUnitTypeTownCenter, 5);
         aiPlanSetEventHandler(planID, cPlanEventStateChange, "tcExpansionBPHandler");
         debugBuildings("Created a plan to create a new Town Center: " + aiPlanGetName(planID) + ".");
      }
      return;
   }

   if (kbUnitCount(cUnitTypeTownCenter, cMyID, cUnitStateAlive) < 2)
   {
      return;
   }

   if (kbPlayerGetAge(cMyID) >= cAge4)
   {
      if (tcCount < 4)
      {
         int closestSettlementID = getClosestUnitByLocation(cUnitTypeSettlement, 0, cUnitStateAlive,
                                   kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)), 150.0);
         if (kbUnitGetIsIDValid(closestSettlementID) == true)
         {
            int planID = aiPlanCreate("Build Plan for 1 Town Center", cPlanBuild, -1, gBuildingsCategoryID);
            // Building Placement.
            int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
            kbBuildingPlacementSetSocketID(bpID, closestSettlementID);
            kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeTownCenter);

            // Plan.
            aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypeTownCenter);
            aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
            aiPlanSetPriority(planID, 55);
            addBuilderTypesToPlan(planID, cUnitTypeTownCenter, 5);
            debugBuildings("Created a plan to create a new Town Center: " + aiPlanGetName(planID) + ".");
            aiPlanSetEventHandler(planID, cPlanEventStateChange, "tcExpansionBPHandler");
            xsSetRuleMinInterval("tcExpansionMonitor", 300);
            return;
         }
      }
   }
}

//==============================================================================
// tcExpansionBPHandler
//==============================================================================
void tcExpansionBPHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   switch (state)
   {
      case cPlanStateDone:
      {
         sendStatementToAllies(cAICommPromptToAllyCompletedTownCenter);
         break;
      }
   }
}

//==============================================================================
// cleanupDropsiteType
// Delete dropsites that have no resources nearby.
//==============================================================================
void cleanupDropsiteType(int puid = -1)
{
   int queryID = useSimpleUnitQuery(puid);
   int numResults = kbUnitQueryExecute(queryID);
   int[] results = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < numResults; i++)
   {
      int dropsiteID = results[i];
      int numSurroundingTrees = getUnitCountByLocation(cUnitTypeTree, 0, cUnitStateAlive | cUnitStateDead, kbUnitGetPosition(dropsiteID), 15.0);
      debugBuildings("Number Surrounding Trees = " + numSurroundingTrees + ".");
      int numSurroundingMines = getUnitCountByLocation(cUnitTypeGoldResource, 0, cUnitStateAlive, kbUnitGetPosition(dropsiteID), 15.0);
      debugBuildings("Number surrounder mines = " + numSurroundingMines + ".");
      if (numSurroundingTrees + numSurroundingMines == 0)
      {
         debugBuildings("Deleting dropsite with ID: " + dropsiteID + ".");
         aiTaskDeleteUnit(dropsiteID);
      }
   }
}

//==============================================================================
// dropsiteCleanupMonitor
// Cleans up wood/gold dropsites.
//==============================================================================
rule dropsiteCleanupMonitor
group defaultClassicalRules
inactive
minInterval 180
{
   if (cMyCulture == cCultureAtlantean)
   {
      xsDisableRule("dropsiteCleanupMonitor");
      return;
   }

   if (checkStrategyFlag(cStrategyFlagAutomaticDropsiteCleanup) == false)
   {
      return;
   }
   debugBuildings("--- Running Rule dropsiteCleanupMonitor. ---");

   switch (cMyCulture)
   {
      case cCultureGreek:
      {
         cleanupDropsiteType(cUnitTypeStorehouse);
         break;
      }
      case cCultureEgyptian:
      {
         cleanupDropsiteType(cUnitTypeLumberCamp);
         cleanupDropsiteType(cUnitTypeMiningCamp);
         break;
      }
   }
   // TODO something with deleting excess Ox Carts?
}

//==============================================================================
// wonderBuildStateChangeHandler
//==============================================================================
void wonderBuildStateChangeHandler(int planID = -1)
{
   static int numTries = 0;
   int state = aiPlanGetState(planID);
   switch (state)
   {
      case cPlanStateDone:
      {
         debugGodPowers("Wonder construction succeeded!");
         xsEnableRuleGroup("defaultWonderRules");
         xsRuleIgnoreIntervalOnce("defaultWonderRules");
         numTries = 0;
         break;
      }
      case cPlanStateFailed:
      {
         debugGodPowers("Wonder construction failed, need to see if we must change our build plan parameters.");
         // TODO new logic with adding more safe back areas later.
         numTries++;
         break;
      }
   }
}

//==============================================================================
// haveEnoughExcessForWonder
//==============================================================================
bool haveEnoughExcessForWonder()
{
   float[] costs = kbProtoUnitGetCost(cUnitTypeWonder);
   for (int i = 0; i < cNumberResources; i++)
   {
      if (costs[i] == 0.0)
      {
         continue;
      }
      // Need to have an excess of all resources, Wonder doesn't cost the same for all civs so dynamically check it all.
      if (haveExcessResourceAmount(costs[i], i) == false)
      {
         debugBuildings("Don't have enough excess resources of " + kbGetResourceName(i) + " to build a Wonder.");
         return false;
      }
   }
   return true;
}

//==============================================================================
// wonderConstructionMonitor
//==============================================================================
rule wonderConstructionMonitor
group defaultMythicRules
inactive
minInterval 60
{
   if (checkStrategyFlag(cStrategyFlagBuildWonder) == false)
   {
      return;
   }
   debugBuildings("--- Running Rule wonderConstructionMonitor. ---");

   if (buildingGetNumberAliveAndPlanned(cUnitTypeWonder) >= 1)
   {
      debugBuildings("We already have a Wonder or are planning to build one, quiting.");
      return;
   }

   if (haveEnoughExcessForWonder() == false)
   {
      return;
   }

   int planID = aiPlanCreate("Wonder Build Plan", cPlanBuild, -1, gBuildingsCategoryID);
   int bpID = kbBuildingPlacementCreate(aiPlanGetName(planID));
   kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeWonder);
   addSafeBackAreasToBuildingPlacement(bpID, getMostDefendedTCBase(), true);
   aiPlanSetVariableInt(planID, cBuildPlanBuildingPlacementID, 0, bpID);
   aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypeWonder);
   
   int unitType = cUnitTypeAbstractVillager;
   int amount = 0;
   if (cMyCulture == cCultureNorse)
   {
      unitType = cUnitTypeLogicalTypeNorseSoldierThatBuilds;
      amount = max(5, kbUnitCount(unitType, cMyID, cUnitStateAlive) / 2); // 50%.
   }
   else
   {
      amount = max(5, kbUnitCount(unitType, cMyID, cUnitStateAlive) / 5); // 20%.
   }
   aiPlanAddUnitType(planID, unitType, amount, amount, amount);

   aiPlanSetPriority(planID, 99);
   aiPlanSetEventHandler(planID, cPlanEventStateChange, "wonderBuildStateChangeHandler");
   debugBuildings("Created Wonder build plan!!!");
}

//==============================================================================
// wonderRepairMonitor
// Makes sure we keep our Wonder at full HP.
//==============================================================================
rule wonderRepairMonitor
group defaultWonderRules
inactive
minInterval 10
{
   debugBuildings("--- Running Rule wonderRepairMonitor. ---");

   int wonderID = getUnit(cUnitTypeWonder);
   if (wonderID == -1)
   {
      debugBuildings("We lost our Wonder, disabling all Wonder age rules now.");
      xsDisableRuleGroup("defaultWonderRules");
      return;
   }

   if (aiPlanGetIDByTypeAndVariableIntValue(cPlanRepair, cRepairPlanTargetID, wonderID) >= 0)
   {
      debugBuildings("We're already repairing our Wonder!");
      return;
   }

   // Start repairing if we took 10%+ damage.
   if (kbUnitGetStatFloat(wonderID, cUnitStatCurrHP) < (kbUnitGetStatFloat(wonderID, cUnitStatMaxHP) * 0.9))
   {
      // We need to repair!
      debugBuildings("Our Wonder has been significantly damaged, creating a repair plan for it.");
      int planID = aiPlanCreate("Repair Wonder", cPlanRepair, -1, gBuildingsCategoryID);
      aiPlanSetVariableInt(planID, cRepairPlanTargetID, 0, wonderID);
      // Higher prio cuz we don't want to lose our Wonder obviously.
      aiPlanSetPriority(planID, 99);

      int unitType = cUnitTypeAbstractVillager;
      int amount = 0;
      if (cMyCulture == cCultureNorse)
      {
         unitType = cUnitTypeLogicalTypeNorseSoldierThatBuilds;
         amount = max(5, kbUnitCount(unitType, cMyID, cUnitStateAlive) / 4); // 25%.
      }
      else
      {
         amount = max(5, kbUnitCount(unitType, cMyID, cUnitStateAlive) / 10); // 10%.
      }
      aiPlanAddUnitType(planID, unitType, amount, amount, amount);
   }
}

//==============================================================================
// armoryMonitor
//==============================================================================
rule armoryMonitor
inactive
group defaultClassicalRules
minInterval 30
{
   if (checkStrategyFlag(cStrategyFlagBuildArmory) == false)
   {
      return;
   }
   debugBuildings("--- Running Rule armoryMonitor. ---");
   int currentAge = kbPlayerGetAge(cMyID);

   // Baseline upgrades active.
   if (kbTechGetStatus(cTechIronWeapons) == cTechStatusActive &&
       kbTechGetStatus(cTechIronArmor) == cTechStatusActive &&
       kbTechGetStatus(cTechIronShields) == cTechStatusActive &&
       kbTechGetStatus(cTechBallistics) == cTechStatusActive &&
       kbTechGetStatus(cTechBurningPitch) == cTechStatusActive)
   {
      if (cMyCulture == cCultureGreek)
      {
         if (currentAge >= cAge4)
         {
            if (kbTechGetStatus(cTechMythicAgeArtemis) == cTechStatusActive)
            {
               if (kbTechGetStatus(cTechShaftsOfPlague) == cTechStatusActive)
               {
                  xsDisableRule("armoryMonitor");
                  return;
               }
            }
            else if (kbTechGetStatus(cTechMythicAgeHephaestus) == cTechStatusActive)
            {
               if (kbTechGetStatus(cTechOlympianWeapons) == cTechStatusActive &&
                   kbTechGetStatus(cTechForgeOfOlympus) == cTechStatusActive)
               {
                  xsDisableRule("armoryMonitor");
                  return;
               }
            }
            else
            {
               // Aged up with Hera, can just disable now.
               xsDisableRule("armoryMonitor");
               return;
            }
         }
      }
      else if (cMyCiv == cCivLoki)
      {
         if (kbTechGetStatus(cTechClassicalAgeForseti) == cTechStatusActive)
         {
            if (kbTechGetStatus(cTechDwarvenBreastplate) == cTechStatusActive)
            {
               xsDisableRule("armoryMonitor");
               return;
            }
         }
         else
         {
            xsDisableRule("armoryMonitor");
            return;
         }
      }
      else if (cMyCiv == cCivThor)
      {
         bool canDisable = true;
         if (kbTechGetStatus(cTechClassicalAgeForseti) == cTechStatusActive)
         {
            if (kbTechGetStatus(cTechDwarvenBreastplate) == cTechStatusActive)
            {
               canDisable = false;
            }
         }
         if (kbTechGetStatus(cTechDwarvenBreastplate) == cTechStatusActive)
         {
            canDisable = false;
         }
         if (kbTechGetStatus(cTechDwarvenBreastplate) == cTechStatusActive)
         {
            canDisable = false;
         }
         if (kbTechGetStatus(cTechDwarvenBreastplate) == cTechStatusActive)
         {
            canDisable = false;
         }
         if (canDisable == true)
         {
            xsDisableRule("armoryMonitor");
            return;
         }
      }
      else
      {
         // No unique upgrades to get, can just disable.
         xsDisableRule("armoryMonitor");
         return;
      }
   }

   int numberExistingBuildings = kbUnitCount(gArmoryUnit, cMyID, cUnitStateAlive);
   if (numberExistingBuildings >= 1)
   {
      return;
   }
   
   int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, gArmoryUnit, 0);
   if (currentAge == cAge2 && (kbResourceGet(cResourceFood) > 800 && kbResourceGet(cResourceGold) > 500) ||
       (aiPlanGetIsIDValid(gAgeUpResearchPlan) == true && aiPlanGetPriority(gAgeUpResearchPlan) > 50))
   {
      debugBuildings("We have enough resources to age up to Heroic/have high age up prio but have no Armory, creating one with all haste!");
      if (aiPlanGetIsIDValid(planID) == true)
      {
         if (aiPlanGetPriority(planID) != 100)
         {
            debugBuildings("Existing Armory build plan found that we're now bumping the priority on to 100.");
            aiPlanSetPriority(planID, 100);
         }
      }
      else
      {
         createSimpleBuildPlan(gArmoryUnit, 1, 100, getRandomTownCenterBaseID());
      }
      return;
   }
   else
   {
      if (aiPlanGetIsIDValid(planID) == true && aiPlanGetPriority(planID) != 50)
      {
         debugBuildings("Existing Armory build plan found that doesn't require the highest priority anymore, setting it to 50.");
         aiPlanSetPriority(planID, 50);
      }
   }

   if (numberExistingBuildings >= 1 || aiPlanGetIsIDValid(planID) == true)
   {
      return;
   }
   
   if (kbResourceGet(cResourceWood) > 500)
   {
      debugBuildings("We have a lot of wood, building an Armory now!");
      createSimpleBuildPlan(gArmoryUnit, 1, 50, getRandomTownCenterBaseID());
      return;
   }

   if (gAgeUpTimes[cAge2] + 240 < xsGetTime())
   {
      debugBuildings("We're already in Classical for 4 minutes, start building an Armory.");
      createSimpleBuildPlan(gArmoryUnit, 1, 50, getRandomTownCenterBaseID());
   }
}

//==============================================================================
// economicGuildMonitor
// Build only 1 Economic Guild at a time max.
//==============================================================================
rule economicGuildMonitor
inactive
group defaultClassicalRules
minInterval 60
{
   if (cMyCulture != cCultureAtlantean)
   {
      xsDisableRule("economicGuildMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagBuildEconomicGuild) == false)
   {
      return;
   }
   debugBuildings("--- Running Rule economicGuildMonitor. ---");

   int planID = -1;
   if (kbTechGetStatus(cTechHusbandry) == cTechStatusActive &&
       kbTechGetStatus(cTechPlow) == cTechStatusActive &&
       kbTechGetStatus(cTechIrrigation) == cTechStatusActive &&
       kbTechGetStatus(cTechFloodControl) == cTechStatusActive &&
       kbTechGetStatus(cTechHuntingEquipment) == cTechStatusActive &&
       kbTechGetStatus(cTechHandAxe) == cTechStatusActive &&
       kbTechGetStatus(cTechBowSaw) == cTechStatusActive &&
       kbTechGetStatus(cTechCarpenters) == cTechStatusActive &&
       kbTechGetStatus(cTechPickaxe) == cTechStatusActive &&
       kbTechGetStatus(cTechShaftMine) == cTechStatusActive &&
       kbTechGetStatus(cTechQuarry) == cTechStatusActive)
   {
      // If we can get Prometheus we must make sure we also get Theft of Fire.
      // If we're Kronos or Oranos we can't hit this part until we're at least in Classical because
      // Hunting Equipment is locked behind Heroic. So we don't need to do an age check.
      if (kbTechGetStatus(cTechClassicalAgePrometheus) == cTechStatusActive)
      {
         if (kbTechGetStatus(cTechTheftOfFire) == cTechStatusActive)
         {
            planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeEconomicGuild);
            if (aiPlanGetIsIDValid(planID) == true)
            {
               aiPlanDestroy(planID);
            }
            xsDisableRule("economicGuildMonitor");
            return;
         }
      }
      else
      {
         planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeEconomicGuild);
         if (aiPlanGetIsIDValid(planID) == true)
         {
            aiPlanDestroy(planID);
         }
         xsDisableRule("economicGuildMonitor");
         return;
      }
   }

   int baseID = getRandomTownCenterBaseID();
   if (baseID == -1)
   {
      debugBuildings("We have no TC base, not building Economic Guild.");
      return;
   }

   if (kbUnitCount(cUnitTypeEconomicGuild, cMyID, cUnitStateAlive) <= 0 &&
       aiPlanGetIsIDValid(aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeEconomicGuild)) == false)
   {
      createSimpleBuildPlan(cUnitTypeEconomicGuild, 1, 50, baseID, 1);
   }
}

//==============================================================================
// monumentMonitor
// Build only 1 Monument at a time max.
// Also artificially lock Monuments behind ages.
//==============================================================================
rule monumentMonitor
inactive
group defaultArchaicRules
minInterval 60
{
   if (cMyCulture != cCultureEgyptian)
   {
      xsDisableRule("monumentMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagBuildMonuments) == false)
   {
      return;
   }
   int baseID = getRandomTownCenterBaseID();
   int age = kbPlayerGetAge(cMyID);

   bool monumentVillagersAlive = kbUnitCount(cUnitTypeMonumentToVillagers, cMyID, cUnitStateAlive) >= 1;
   if (monumentVillagersAlive == false)
   {
      if (aiPlanGetIsIDValid(
          aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMonumentToVillagers)) == false)
      {
         createSimpleBuildPlan(cUnitTypeMonumentToVillagers, 1, 50, baseID, cCalculateNumBuildersAutomatically);
      }
      return;
   }

   if (age < cAge2)
   {
      return;
   }

   bool monumentSoldiersAlive = kbUnitCount(cUnitTypeMonumentToSoldiers, cMyID, cUnitStateAlive) >= 1;
   if (monumentSoldiersAlive == false)
   {
      if (aiPlanGetIsIDValid(
          aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMonumentToSoldiers)) == false)
      {
         createSimpleBuildPlan(cUnitTypeMonumentToSoldiers, 1, 50, baseID, cCalculateNumBuildersAutomatically);
      }
      return;
   }

   if (age < cAge3)
   {
      return;
   }

   bool monumentPriestsAlive = kbUnitCount(cUnitTypeMonumentToPriests, cMyID, cUnitStateAlive) >= 1;
   if (monumentPriestsAlive == false)
   {
      if (aiPlanGetIsIDValid(
          aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMonumentToPriests)) == false)
      {
         createSimpleBuildPlan(cUnitTypeMonumentToPriests, 1, 50, baseID, cCalculateNumBuildersAutomatically);
      }
      return;
   }

   if (age < cAge4)
   {
      return;
   }

   bool monumentPharaohsAlive = kbUnitCount(cUnitTypeMonumentToPharaohs, cMyID, cUnitStateAlive) >= 1;
   if (monumentPharaohsAlive == false)
   {
      if (aiPlanGetIsIDValid(
          aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMonumentToPharaohs)) == false)
      {
         createSimpleBuildPlan(cUnitTypeMonumentToPharaohs, 1, 50, baseID, cCalculateNumBuildersAutomatically);
      }
      return;
   }
   
   bool monumentGodsAlive = kbUnitCount(cUnitTypeMonumentToGods, cMyID, cUnitStateAlive) >= 1;
   if (monumentGodsAlive == false)
   {
      if (aiPlanGetIsIDValid(
          aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMonumentToGods)) == false)
      {
         createSimpleBuildPlan(cUnitTypeMonumentToGods, 1, 50, baseID, cCalculateNumBuildersAutomatically);
      }
      return;
   }
}