//==============================================================================
/* exploration.xs

   This file is intended for any exploration implementation, including both land and
   naval exploration.

*/
//==============================================================================

//==============================================================================
// helperExploreOtherIslands
//==============================================================================
void helperExploreOtherIslands(int planID = -1)
{
   debugExploration("*** helperExploreOtherIslands ***");
   int ownAreaGroupID = kbAreaGroupGetIDByPosition(aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0));
   int numAreaGroups = kbAreaGroupGetNumber();
   int[] areaGroupsToExplore = new int(0, 0);
   areaGroupsToExplore.add(ownAreaGroupID);
   int[] landAreaGroups = new int(0, 0);
   // Find all land area groups.
   for (int iGroup = 0; iGroup < numAreaGroups; iGroup++)
   {
      if (iGroup == ownAreaGroupID)
      {
         continue;
      }
      if (kbAreaGroupGetType(iGroup) == cAreaGroupTypeWater || kbAreaGroupGetType(iGroup) == cAreaGroupTypeImpassableLand)
      {
         continue;
      }
      landAreaGroups.add(iGroup);
   }

   // Go through all land area groups and find their water borders, if they have them.
   for (int i = 0; i < landAreaGroups.size(); i++)
   {
      int landAreaGroupID = landAreaGroups[i];
      debugExploration("Analyzing if we should explore area group ID: " + landAreaGroupID + ".");
      int numBorders = kbAreaGroupGetNumberBorderAreaGroups(landAreaGroupID);
      bool shouldExplore = false;
      for (int iLandBorder = 0; iLandBorder < numBorders; iLandBorder++)
      {
         int borderGroup = kbAreaGroupGetBorderAreaGroupID(landAreaGroupID, iLandBorder);
         if (kbAreaGroupGetType(borderGroup) == cAreaGroupTypeWater)
         {
            int numLandBorders = 0;
            int numWaterBorders = kbAreaGroupGetNumberBorderAreaGroups(borderGroup);
            for (int iWaterBorder = 0; iWaterBorder < numWaterBorders; iWaterBorder++)
            {
               int waterBorderGroup = kbAreaGroupGetBorderAreaGroupID(borderGroup, iWaterBorder);
               if (kbAreaGroupGetType(waterBorderGroup) == cAreaGroupTypeLand)
               {
                  numLandBorders++;
                  if (numLandBorders == 2)
                  {
                     shouldExplore = true;
                     break;
                  }
               }
            }
            if (shouldExplore == true)
            {
               debugExploration("We found suitable bordering water area groups to land area group ID " + landAreaGroupID +
                  ", explore this area group now.");
               areaGroupsToExplore.add(landAreaGroupID);
               break;
            }
         }
      }
   }

   if (areaGroupsToExplore.size() == 1)
   {
      aiEchoWarning("helperExploreOtherIslands only found 1 area group to explore, when we call this we expect at least 2 or " + 
         "kbGetIsIslandMap is out of sync with our code above.");
      return;
   }

   aiPlanSetNumberVariableValues(planID, cExplorePlanExploreAreaGroupIDs, areaGroupsToExplore.size(), true);
   for (int iGroup = 0; iGroup < areaGroupsToExplore.size(); iGroup++)
   {
      aiPlanSetVariableInt(planID, cExplorePlanExploreAreaGroupIDs, iGroup, areaGroupsToExplore[iGroup]);
   }
}

//==============================================================================
// helperScoutDockShoreline
//==============================================================================
void helperScoutDockShoreline(int planID = -1)
{
   if (gMapInfo.mShouldBuildDock == false)
   {
      aiEchoWarning("Calling helperScoutDockShoreline while we don't want to build a Dock!");
      return;
   }

   vector[] shorelineCenters = new vector(3, cInvalidVector);
   vector[] waterCenters = new vector(3, cInvalidVector);
   shorelineCenters[1] = kbAreaGetCenter(gMapInfo.mClosestShorelineAreaID);
   waterCenters[1] = kbAreaGetCenter(gMapInfo.mClosestWaterAreaID);
   int numShorelinesFound = 0;
   // Dock placement takes 3 areas into account, hence we will try to explore 3 shoreline areas.
   // We already know the ID of our prefered shoreline area, we now just need to find the 2 adjacent areas that also border water.
   int numBorderAreas = kbAreaGetNumberBorderAreas(gMapInfo.mClosestShorelineAreaID);
   for (int i = 0; i < numBorderAreas; i++)
   {
      int areaID = kbAreaGetBorderAreaID(gMapInfo.mClosestShorelineAreaID, i);
      if (isAreaPassableByLand(areaID) == false)
      {
         continue; // We only want shoreline areas to scout, so it needs to be PassableLand.
      }
      int moreBorders = kbAreaGetNumberBorderAreas(areaID);
      for (int j = 0; j < moreBorders; j++)
      {
         if (kbAreaGetType(kbAreaGetBorderAreaID(areaID, j)) == cAreaTypeWater)
         {
            numShorelinesFound++;
            if (numShorelinesFound == 1)
            {
               shorelineCenters[0] = kbAreaGetCenter(areaID);
               waterCenters[0] = kbAreaGetCenter(kbAreaGetBorderAreaID(areaID, j));
            }
            else
            {
               shorelineCenters[2] = kbAreaGetCenter(areaID);
               waterCenters[2] = kbAreaGetCenter(kbAreaGetBorderAreaID(areaID, j));
            }
            break;
         }
      }
      if (numShorelinesFound == 2)
      {
         break; // 2 Is normally the max we can find due to how area generation works.
      }
   }

   // Our shorelineCenters array now holds the centers of our 3 shoreline areas.
   // Our waterCenters array now holds the centers of 3 water areas that are surely next to our shoreline area.
   // Now we step from our shoreline center towards the water center until we find water. We can't just path between all shoreline
   // centers because those areas could be big. And that would cause us to potentially not scout enough actual terrain where
   // Docks could be placed.
   for (int i = 0; i < 3; i++)
   {
      vector directionStep = xsVectorNormalize(waterCenters[i] - shorelineCenters[i]) * 5;
      for (int j = 1; j < 15; j++)
      {
         vector testLocation = shorelineCenters[i] + (directionStep * j);
         int testAreaID = kbAreaGetIDByPosition(testLocation);
         if (kbAreaGetType(testAreaID) == cAreaTypeWater)
         {
            // If we've found water it means that we've found the actual shoreline.
            // We must now add the point right before we found the water, to very closely scout the water's edge.
            aiPlanAddWaypoint(planID, shorelineCenters[i] + (directionStep * (j - 1)));
         }
      }
   }
}

//==============================================================================
// helperExploreStartingSurroundings
// In the source this mechanic will skip areas that we consider too dangerous or can't path to at that moment.
// Meaning that it's not guaranteed that we scout all areas we assign to the plan here.
// Which in turn means that we have to keep running this in all scouting rules until we finally scout everything.
//==============================================================================
void helperExploreStartingSurroundings(int planID = -1)
{
   if (gFullyExploredStartingSurroundings == true)
   {
      aiEchoWarning("We shouldn't be calling helperExploreStartingSurroundings when gFullyExploredStartingSurroundings == true.");
      return;
   }
   debugExploration("helperExploreStartingSurroundings:");

   vector startingPosition = kbPlayerGetStartingPosition(cMyID);
   if (startingPosition == cInvalidVector)
   {
      int mainBaseID = kbBaseGetMainID(cMyID);
      if (mainBaseID != -1)
      {
         startingPosition = kbBaseGetLocation(cMyID, mainBaseID);
      }
   }
   if (startingPosition == cInvalidVector)
   {
      debugExploration("We couldn't find a vector that can serve as a starting position, can't scout surroundings now.");
      gFullyExploredStartingSurroundings = true;
      return;
   }
   int startAreaID = kbAreaGetIDByPosition(startingPosition);
   if (kbAreaGetIsIDValid(startAreaID) == false)
   {
      return;
   }

   int[] areasToScout = new int(0, 0);
   int[] areasToAnalyze = new int(0, 0);
   for (int iFirstBorder = 0; iFirstBorder < kbAreaGetNumberBorderAreas(startAreaID); iFirstBorder++)
   {
      int firstBorderAreaID = kbAreaGetBorderAreaID(startAreaID, iFirstBorder);
      if (isAreaPassableByLand(firstBorderAreaID) == false)
      {
         continue;
      }
      areasToAnalyze.uniqueAdd(firstBorderAreaID);
      for (int iSecondBorder = 0; iSecondBorder < kbAreaGetNumberBorderAreas(firstBorderAreaID); iSecondBorder++)
      {
         // Because we check all borders of borders we don't have to specifically add the second layer.
         int secondBorderAreaID = kbAreaGetBorderAreaID(firstBorderAreaID, iSecondBorder);
         if (isAreaPassableByLand(secondBorderAreaID) == false)
         {
            continue;
         }
         for (int iThirdBorder = 0; iThirdBorder < kbAreaGetNumberBorderAreas(secondBorderAreaID); iThirdBorder++)
         {
            areasToAnalyze.uniqueAdd(kbAreaGetBorderAreaID(secondBorderAreaID, iThirdBorder));
         }
      }
   }

   for (int i = 0; i < areasToAnalyze.size(); i++)
   {
      int areaID = areasToAnalyze[i];
      if (isAreaPassableByLand(areaID) == false ||
          kbAreaGetPercentExplored(areaID) == 1.0)
      {
         debugExploration("   AreaID: " + areaID + " is already fully explored or not passable by land.");
         continue;
      }
      if (xsVectorLength(startingPosition - kbAreaGetCenter(areaID)) > 85.0)
      {
         debugExploration("   AreaID: " + areaID + " is too far away from our starting position to scout for this mechanic.");
         continue;
      }
      areasToScout.add(areaID);
      debugExploration("   Added areaID: " + areaID + " to the array of arrays we want to explore.");
   }

   if (areasToScout.size() == 0)
   {
      debugExploration("Scouted all of our starting surroundings!");
      gFullyExploredStartingSurroundings = true;
      return;
   }
   aiPlanSetNumberVariableValues(planID, cExplorePlanExploreAreaIDs, areasToScout.size());
   for (int i = 0; i < areasToScout.size(); i++)
   {
      aiPlanSetVariableInt(planID, cExplorePlanExploreAreaIDs, i, areasToScout[i]);
   }
}

//==============================================================================
// scoutingMonitor
//==============================================================================
rule scoutingMonitor
inactive
group defaultArchaicRules
minInterval 10
{
   // Greeks use Pegasus + Kataskopos in another rule, Odin uses Ravens in another rule.
   if (cMyCulture == cCultureGreek ||
       cMyCiv == cCivOdin)
   {
      xsDisableRule("scoutingMonitor");
      return;
   }

   static int[] scoutPlans = default;
   if (checkStrategyFlag(cStrategyFlagAutomaticScouting) == false)
   {
      for (int i = 0; i < scoutPlans.size(); i++)
      {
         if (aiPlanGetIsIDValid(scoutPlans[i]) == true)
         {
            aiPlanDestroy(scoutPlans[i]);
         }
      }
      scoutPlans.clear();
      return;
   }
   debugExploration("--- Running Rule scoutingMonitor. ---");

   // Clear out dead plans.
   for (int i = scoutPlans.size() - 1; i >= 0 ; i--)
   {
      if (aiPlanGetIsIDValid(scoutPlans[i]) == false)
      {
         scoutPlans.removeIndex(i);
      }
   }

   // Fixup starting surrounding if we have plan(s).
   if (gFullyExploredStartingSurroundings == false)
   {
      if (scoutPlans.size() >= 1)
      {
         int planID = scoutPlans[0];
         // If we don't have an areaID saved in this plan yet we know we need to set it up still.
         // Only do this for the first plan otherwise we create a useless train.
         if (aiPlanGetVariableInt(planID, cExplorePlanExploreAreaIDs, 0) == -1)
         {
            helperExploreStartingSurroundings(planID);
         }
      }
   }

   int requiredScoutPlans = 1; // Just making this structure so it's easier to change later.
   // If we already have all the plans that we want we need to make sure they have units.
   if (scoutPlans.size() == requiredScoutPlans)
   {
      if (aiPlanGetState(gPrimaryLandDefendPlan) == cPlanStateAttack)
      {
         debugExploration("Our primary land defend plan is engaged, can't pick new scouts now.");
         return;
      }

      int[] units = new int(0, 0);
      if (cMyCulture == cCultureEgyptian)
      {
         units = aiPlanGetUnits(gPrimaryLandDefendPlan, cUnitTypePriest);
      }
      else
      {
         // Don't scout with heroes / myth units, they're too valuable.
         units = aiPlanGetUnits(gPrimaryLandDefendPlan, cUnitTypeHumanSoldier);
      }
      if (units.size() == 0)
      {
         debugExploration("Our primary land defend plan has no valid scout units in it, can't pick new scouts now.");
         return;
      }

      for (int i = 0; i < scoutPlans.size(); i++)
      {
         if (cMyCulture == cCultureEgyptian)
         {
            int planID = scoutPlans[i];
            // Already at max capacity.
            if (aiPlanGetNumberUnits(planID) >= 1)
            {
               continue;
            }
            debugExploration("Added Priest(" + units[0] + ") to " + aiPlanGetName(planID) + ".");
            aiPlanAddUnit(planID, units[0]);
            units.removeIndex(0);
            if (units.size() == 0)
            {
               break;
            }
         }
         else
         {
            int planID = scoutPlans[i];
            // Already at max capacity.
            if (aiPlanGetNumberUnits(planID) >= 1)
            {
               continue;
            }
            for (int j = 0; j < units.size(); j++)
            {
               if (kbProtoUnitGetCostTotal(kbUnitGetProtoUnitID(units[j])) < 120.0)
               {
                  debugExploration("Added " + kbProtoUnitGetName(kbUnitGetProtoUnitID(units[j])) + " to " + aiPlanGetName(planID) + ".");
                  aiPlanAddUnit(planID, units[j]);
                  units.removeIndex(j);
                  break;
               }
            }
         }
      }
      return;
   }

   for (int i = scoutPlans.size(); i < requiredScoutPlans; i++)
   {
      // Create the plans needed.
      int planID = -1;
      if (cMyCulture == cCultureEgyptian)
      {
         // We scout with Priests and build Obelisks.
         planID = aiPlanCreate("Default Explore", cPlanExplore, -1, gExplorationCategoryID);
         aiPlanSetPriority(planID, 50);
         aiPlanAddUnitType(planID, cUnitTypePriest, 1, 1, 1);
         aiPlanSetVariableBool(planID, cExplorePlanCanBuildOutpost, 0, true);
         aiPlanSetVariableInt(planID, cExplorePlanOutpostPUID, 0, cUnitTypeObelisk);
         aiPlanSetFlag(planID, cPlanFlagNoMoreUnits, true); // Manual assignment.
         scoutPlans.add(planID);
      }
      else
      {
         planID = aiPlanCreate("Default Explore", cPlanExplore, -1, gExplorationCategoryID);
         aiPlanSetPriority(planID, 50);
         aiPlanAddUnitType(planID, cUnitTypeHumanSoldier, 1, 1, 1);
         aiPlanSetFlag(planID, cPlanFlagNoMoreUnits, true); // Manual assignment.
         scoutPlans.add(planID);
      }
      // Explore other islands if we need to.
      if (gMapInfo.mIsIslandMap == true)
      {
         helperExploreOtherIslands(planID);
      }
   }

   // Run again to populate the plans with units.
   xsRuleIgnoreIntervalOnce("scoutingMonitor");
}

//==============================================================================
// armyScoutingMonitor
//==============================================================================
rule armyScoutingMonitor
inactive
group defaultClassicalRules
minInterval 10
{
   static int[] armyScoutPlans = default;
   if (checkStrategyFlag(cStrategyFlagAutomaticScouting) == false)
   {
      for (int i = 0; i < armyScoutPlans.size(); i++)
      {
         if (aiPlanGetIsIDValid(armyScoutPlans[i]) == true)
         {
            aiPlanDestroy(armyScoutPlans[i]);
         }
      }
      armyScoutPlans.clear();
      return;
   }
   debugExploration("--- Running Rule armyScoutingMonitor. ---");
   
   bool attackKOTH = false;
   if ((cVictoryTypesCurrent & cVictoryTypeKingOfTheHill) != 0 && gKOTHIsOwnedByAllies == false)
   {
      debugExploration("KOTH isn't owned by us/allies, don't scout but send all units to it.");
      attackKOTH = true;
   }

   if (gAttackManager.mScoutingState == cScoutingForEnemies && attackKOTH == false)
   {
      // Clear out invalid plans or plans whose units all have died, since automatic assignment is disabled we need to create a new plan.
      for (int i = 0; i < armyScoutPlans.size(); i++)
      {
         if (aiPlanGetIsIDValid(armyScoutPlans[i]) == false || aiPlanGetNumberUnits(armyScoutPlans[i]) == 0)
         {
            aiPlanDestroy(armyScoutPlans[i]);
            armyScoutPlans.removeIndex(i);
         }
      }

      int scoutingGroupSize = selectByDifficulty(1, 2, 3, 5, 6, 7);
      int[] units = aiPlanGetUnits(gPrimaryLandDefendPlan);
      // Filter out all siege, we're not scouting with those slow units.
      for (int i = units.size() - 1; i >= 0; i--)
      {
         if (kbProtoUnitIsType(kbUnitGetProtoUnitID(units[i]), cUnitTypeAbstractSiegeWeapon) == true)
         {
            units.removeIndex(i);
         }
      }
      int maxScoutGroups = selectByDifficulty(1, 2, 4, 8, 10, 12);
      int scoutGroupsToCreate = min(maxScoutGroups - armyScoutPlans.size(), units.size() / scoutingGroupSize);
      debugExploration("Scouting with army, creating " + scoutGroupsToCreate + " new army scout groups.");
      int ownAreaGroupID = kbAreaGroupGetIDByPosition(aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0));
      for (int i = 0; i < scoutGroupsToCreate; i++)
      {
         // Create explore plans.
         int planID = aiPlanCreate("Army Explore: " + armyScoutPlans.size() + 1, cPlanExplore, -1, gExplorationCategoryID);
         aiPlanSetPriority(planID, 50);
         aiPlanSetVariableBool(planID, cExplorePlanAggressiveScouts, 0, true);
         setDefaultExplorePlanTargetUnitTypes(planID);
         for (int iUnit = units.size() - 1; iUnit >= 0; iUnit--)
         {
            aiPlanAddUnitType(planID, kbUnitGetProtoUnitID(units[iUnit]), 1, 1, 1, true);
            aiPlanAddUnit(planID, units[iUnit]);
         }
         aiPlanSetFlag(planID, cPlanFlagNoMoreUnits, true);
         // Explore other islands if we need to.
         if (gMapInfo.mIsIslandMap == true)
         {
            helperExploreOtherIslands(planID);
         }

         armyScoutPlans.add(planID);
      }
   }
   else
   {
      for (int i = 0; i < armyScoutPlans.size(); i++)
      {
         if (aiPlanGetIsIDValid(armyScoutPlans[i]) == true)
         {
            if (aiPlanGetState(armyScoutPlans[i]) != cPlanStateAttack)
            {
               aiPlanDestroy(armyScoutPlans[i]);
            }
         }
      }
      armyScoutPlans.clear();
   }
}

//==============================================================================
// navalScoutingMonitor
//==============================================================================
rule navalScoutingMonitor
inactive
group defaultClassicalRules
minInterval 10
{
   if (gMapInfo.mHasWater == false)
   {
      xsDisableRule("navalScoutingMonitor");
      return;
   }
   static int[] navalScoutPlans = default;
   if (checkStrategyFlag(cStrategyFlagAutomaticNavalGameplay) == false)
   {
      for (int i = 0; i < navalScoutPlans.size(); i++)
      {
         if (aiPlanGetIsIDValid(navalScoutPlans[i]) == true)
         {
            aiPlanDestroy(navalScoutPlans[i]);
         }
      }
      navalScoutPlans.clear();
      return;
   }

   debugExploration("--- Running Rule navalScoutingMonitor. ---");

   // Current max is 1 plans, but have the setup for more. If this is increased the distribution of Ships must be changed.
   const int cMaxNavalScoutPlans = 1;
   if (navalScoutPlans.size() < cMaxNavalScoutPlans) // First run.
   {
      navalScoutPlans.add(-1);
   }
   
   if (checkStrategyFlag(cStrategyFlagAutomaticNavalGameplay) == false)
   {
      for (int i = 0; i < cMaxNavalScoutPlans; i++)
      {
         if (aiPlanGetIsIDValid(navalScoutPlans[i]) == true)
         {
            aiPlanDestroy(navalScoutPlans[i]);
         }
         navalScoutPlans[i] = -1;
      }
      return;
   }

   if (aiGetMostHatedNavalPlayerID() == cScoutingForEnemies)
   {
      for (int i = 0; i < cMaxNavalScoutPlans; i++)
      {
         // Clear out plans whose units all have died, since automatic assignment is disabled we need to create a new plan.
         if (aiPlanGetIsIDValid(navalScoutPlans[i]) == true && aiPlanGetNumberUnits(navalScoutPlans[i]) == 0)
         {
            aiPlanDestroy(navalScoutPlans[i]);
            navalScoutPlans[i] = -1;
         }
         if (aiPlanGetIsIDValid(navalScoutPlans[i]) == false)
         {
            if (aiPlanGetNumberUnits(gPrimaryNavalDefendPlan) == 0)
            {
               debugExploration("Can't create a new army naval explore plan because our naval defend plan is empty.");
               return;
            }
            // Create water explore plan.
            int planID = aiPlanCreate("Army Naval Explore: ", cPlanExplore, -1, gExplorationCategoryID);
            aiPlanSetPriority(planID, 50);
            aiPlanAddUnitType(planID, cUnitTypeLogicalTypeNavalMilitary, 0, 0, 200);
            transferAllUnitsBetweenTwoPlans(gPrimaryNavalDefendPlan, planID);
            aiPlanSetInitialPosition(planID, gMapInfo.mWaterDefendPoint);
            aiPlanSetVariableBool(planID, cExplorePlanAggressiveScouts, 0, true);
            setDefaultExplorePlanTargetUnitTypes(planID);
            aiPlanSetFlag(planID, cPlanFlagNoMoreUnits, true);
            navalScoutPlans[i] = planID;
            debugExploration("Created new army naval explore plan: " + aiPlanGetName(planID) + ".");
         }
      }
   }
   else
   {
      for (int i = 0; i < cMaxNavalScoutPlans; i++)
      {
         if (aiPlanGetIsIDValid(navalScoutPlans[i]) == true && aiPlanGetState(navalScoutPlans[i]) != cPlanStateAttack)
         {
            aiPlanDestroy(navalScoutPlans[i]);
            navalScoutPlans[i] = -1;
         }
      }
   }
}

//==============================================================================
// transportScoutingMonitor
// Explore with transport in Archaic, keep it at home later since it's likely we need to transport.
//==============================================================================
rule transportScoutingMonitor
inactive
group defaultArchaicRules
minInterval 10
{
   static int planID = -1;
   if (gMapInfo.mStartsWithTransport == false)
   {
      if (aiPlanGetIsIDValid(planID) == true)
      {
         aiPlanDestroy(planID);
         planID = -1;
      }
      xsDisableRule("transportScoutingMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagScoutWithStartingTransport) == false)
   {
      if (aiPlanGetIsIDValid(planID) == true)
      {
         aiPlanDestroy(planID);
         planID = -1;
      }
      return;
   }
   debugExploration("--- Running Rule transportScoutingMonitor. ---");

   if (kbPlayerGetAge(cMyID) >= cAge2)
   {
      if (aiPlanGetIsIDValid(planID) == true)
      {
         if (aiPlanGetNumberUnits(planID) > 0)
         {
            int unitID = aiPlanGetUnitIDByIndex(planID, 0);
            // Remove the unit from the plan so that the move command works properly.
            aiPlanRemoveUnit(planID, unitID);
            aiTaskMoveUnit(unitID, gMapInfo.mWaterDefendPoint);
         }
         aiPlanDestroy(planID);
      }
      planID = -1;
      xsDisableRule("transportScoutingMonitor");
      return;
   }

   if (planID == -1)
   {
      // Create explore plan.
      planID = aiPlanCreate("Transport Explore", cPlanExplore, -1, gExplorationCategoryID);
      aiPlanSetPriority(planID, 1);
      aiPlanAddUnitType(planID, cUnitTypeTransport, 1, 1, 1);
   }

   if (aiPlanGetNumberUnits(planID) == 0)
   {
      int transportID = getUnit(cUnitTypeAbstractTransportShip);
      if (transportID == -1)
      {
         aiPlanDestroy(planID);
         planID = -1;
         xsDisableRule("transportScoutingMonitor");
         return;
      }
      // Only assign if we're not already in a plan, this is to prevent stealing from BO plans / real transport plans.
      if (kbUnitGetPlanID(transportID) == -1)
      {
         debugExploration("Added " + kbProtoUnitGetName(kbUnitGetProtoUnitID(transportID)) + " to " + aiPlanGetName(planID) + ".");
         aiPlanAddUnit(planID, transportID);
      }
   }
}

//==============================================================================
// kataskoposManager
//==============================================================================
rule kataskoposManager
inactive
minInterval 30
{
   debugExploration("--- Running Rule kataskoposManager. ---");

   static int kataskoposScoutPlanID = -1;
   if (checkStrategyFlag(cStrategyFlagAutomaticScouting) == false)
   {
      if (aiPlanGetIsIDValid(kataskoposScoutPlanID) == true)
      {
         aiPlanDestroy(kataskoposScoutPlanID);
      }
      return;
   }

   int kataskoposID = getUnit(cUnitTypeKataskopos);
   if (kataskoposID == -1)
   {
      if (aiPlanGetIsIDValid(kataskoposScoutPlanID) == true)
      {
         aiPlanDestroy(kataskoposScoutPlanID);
      }
      kataskoposScoutPlanID = -1;
      debugExploration("We lost our Kataskopos, disabling kataskoposManager");
      xsDisableRule("kataskoposManager");
      return;
   }

   // We let the Pegasus that we train do the starting surrounding scouting since it can fly...
   if (aiPlanGetIsIDValid(kataskoposScoutPlanID) == false)
   {
      kataskoposScoutPlanID = aiPlanCreate("Kataskopos Explore", cPlanExplore, -1, gExplorationCategoryID);
      aiPlanSetPriority(kataskoposScoutPlanID, 50);
      aiPlanAddUnitType(kataskoposScoutPlanID, cUnitTypeKataskopos, 1, 1, 1);
      aiPlanSetFlag(kataskoposScoutPlanID, cPlanFlagCantBeStolenFrom, true);
      // Explore other islands if we need to.
      if (gMapInfo.mIsIslandMap == true)
      {
         helperExploreOtherIslands(kataskoposScoutPlanID);
      }
   }

   int currentKataskoposPlanID = kbUnitGetPlanID(kataskoposID);
   if (currentKataskoposPlanID != kataskoposScoutPlanID)
   {
      // Forcibly add the unit since we always want it to be in this plan.
      aiPlanAddUnit(kataskoposScoutPlanID, kataskoposID);
   }
}

//==============================================================================
// hippocampusManager
//==============================================================================
rule hippocampusManager
inactive
minInterval 30
{
   if (gMapInfo.mHasWater == false)
   {
      debugExploration("Disabling hippocampusManager because there is no water on the map.");
      xsDisableRule("hippocampusManager");
      return;
   }
   debugExploration("--- Running Rule hippocampusManager. ---");

   static int hippocampusScoutPlan = -1;
   if (checkStrategyFlag(cStrategyFlagAutomaticScouting) == false)
   {
      if (aiPlanGetIsIDValid(hippocampusScoutPlan) == true)
      {
         aiPlanDestroy(hippocampusScoutPlan);
      }
      return;
   }

   if (aiPlanGetIsIDValid(hippocampusScoutPlan) == false)
   {
      hippocampusScoutPlan = aiPlanCreate("Hippocampus Explore", cPlanExplore, -1, gExplorationCategoryID);
      aiPlanSetPriority(hippocampusScoutPlan, 50);
      aiPlanAddUnitType(hippocampusScoutPlan, cUnitTypeHippocampus, 1, 1, 1);
   }
}

//==============================================================================
// pegasusScoutingMonitor
//==============================================================================
rule pegasusScoutingMonitor
group defaultArchaicRules
inactive
minInterval 30
{
   if (checkStrategyFlag(cStrategyFlagAutomaticScouting) == false)
   {
      return;
   }
   debugExploration("--- Running Rule pegasusScoutingMonitor ---");
   
   int[] pegasi = new int(0, 0);
   int queryID = useSimpleUnitQuery(cUnitTypePegasus);
   int numberFound = kbUnitQueryExecute(queryID);
   for (int i = 0; i < numberFound; i++)
   {
      pegasi.add(kbUnitQueryGetResult(queryID, i));
   }

   useSimpleUnitQuery(cUnitTypePegasusWingedMessenger);
   numberFound = kbUnitQueryExecute(queryID);
   for (int i = 0; i < numberFound; i++)
   {
      pegasi.add(kbUnitQueryGetResult(queryID, i));
   }

   useSimpleUnitQuery(cUnitTypePegasusBridleOfPegasus);
   numberFound = kbUnitQueryExecute(queryID);
   for (int i = 0; i < numberFound; i++)
   {
      pegasi.add(kbUnitQueryGetResult(queryID, i));
   }

   for (int i = 0; i < pegasi.size(); i++)
   {
      if (aiPlanGetIsIDValid(kbUnitGetPlanID(pegasi[i])) == false)
      {
         int puid = kbUnitGetProtoUnitID(pegasi[i]);
         int planID = aiPlanCreate(kbProtoUnitGetName(puid) + " Explore", cPlanExplore, -1, gExplorationCategoryID);
         aiPlanSetPriority(planID, 50);
         aiPlanSetFlag(planID, cPlanFlagCantBeStolenFrom, true);
         aiPlanAddUnitType(planID, puid, 1, 1, 1);
         aiPlanAddUnit(planID, pegasi[i]);
         // Explore other islands if we need to.
         if (gMapInfo.mIsIslandMap == true)
         {
            helperExploreOtherIslands(planID);
         }
      }
      // Only first Pegasus does this, otherwise we're forming a useless train.
      if (i == 0)
      {
         // Sanity check.
         int planID = kbUnitGetPlanID(pegasi[i]);
         if (aiPlanGetType(planID) == cPlanExplore && gFullyExploredStartingSurroundings == false)
         {
            // If we don't have an areaID saved in this plan yet we know we need to set it up still.
            if (aiPlanGetVariableInt(planID, cExplorePlanExploreAreaIDs, 0) == -1)
            {
               helperExploreStartingSurroundings(planID);
            }
         }
      }
   }
}

//////////////////////////////
void pegasusTrained(int pegasusID = -1)
{
   // Instantly scout with our new pegasus.
   xsRuleIgnoreIntervalOnce("pegasusScoutingMonitor");
}
//==============================================================================
// pegasusMaintainMonitor
//==============================================================================
rule pegasusMaintainMonitor
group defaultClassicalRules
inactive
minInterval 60 // We're not doing much here, check very infrequently if we got Winged Messenger or a strat flag changed.
{
   if (cMyCulture != cCultureGreek)
   {
      xsDisableRule("pegasusMaintainMonitor");
      return;
   }

   static int maintainPlanID = -1;
   if (checkStrategyFlag(cStrategyFlagAutomaticScouting) == false)
   {
      if (aiPlanGetIsIDValid(maintainPlanID) == true)
      {
         aiPlanDestroy(maintainPlanID);
         maintainPlanID = -1;
      }
      return;
   }
   debugExploration("--- Running Rule pegasusMaintainMonitor. ---");

   if (cMyCiv == cCivZeus || cMyCiv == cCivPoseidon)
   {
      if (kbTechGetStatus(cTechWingedMessenger) == cTechStatusActive)
      {
         debugExploration("We researched Winged Messenger, no longer need to train Pegasi ourself.");
         xsDisableRule("pegasusMaintainMonitor");
         if (aiPlanGetIsIDValid(maintainPlanID) == true)
         {
            aiPlanDestroy(maintainPlanID);
         }
         return;
      }
   }

   if (aiPlanGetIsIDValid(maintainPlanID) == false)
   {
      maintainPlanID = createSimpleMaintainPlan(cUnitTypePegasus, 1);
      aiPlanSetEventHandler(maintainPlanID, cTrainPlanEventUnitTrained, "pegasusTrained"); 
   }
}

//==============================================================================
// ravenManager
//==============================================================================
rule ravenManager
inactive
minInterval 30
{
   static int ravenScoutPlan1 = -1;
   static int ravenScoutPlan2 = -1;
   if (checkStrategyFlag(cStrategyFlagAutomaticScouting) == false)
   {
      if (aiPlanGetIsIDValid(ravenScoutPlan1) == true)
      {
         aiPlanDestroy(ravenScoutPlan1);
      }
      if (aiPlanGetIsIDValid(ravenScoutPlan2) == true)
      {
         aiPlanDestroy(ravenScoutPlan2);
      }
      return;
   }
   debugExploration("--- Running Rule ravenManager. ---");

   if (aiPlanGetIsIDValid(ravenScoutPlan1) == false)
   {
      ravenScoutPlan1 = aiPlanCreate("Raven Explore 1", cPlanExplore, -1, gExplorationCategoryID);
      aiPlanSetPriority(ravenScoutPlan1, 50);
      aiPlanAddUnitType(ravenScoutPlan1, cUnitTypeRaven, 1, 1, 1);
      // Explore other islands if we need to.
      if (gMapInfo.mIsIslandMap == true)
      {
         helperExploreOtherIslands(ravenScoutPlan1);
      }
   }
   if (aiPlanGetIsIDValid(ravenScoutPlan2) == false)
   {
      ravenScoutPlan2 = aiPlanCreate("Raven Explore 2", cPlanExplore, -1, gExplorationCategoryID);
      aiPlanSetPriority(ravenScoutPlan2, 50);
      aiPlanAddUnitType(ravenScoutPlan2, cUnitTypeRaven, 1, 1, 1);
      // Explore other islands if we need to.
      if (gMapInfo.mIsIslandMap == true)
      {
         helperExploreOtherIslands(ravenScoutPlan2);
      }
   }

   if (gFullyExploredStartingSurroundings == false)
   {
      // If we don't have an areaID saved in this plan yet we know we need to set it up still.
      if (aiPlanGetVariableInt(ravenScoutPlan1, cExplorePlanExploreAreaIDs, 0) == -1)
      {
         helperExploreStartingSurroundings(ravenScoutPlan1);
      }
   }
}

//////////////////////////////////////////////////////
/////////////////////// Oracles ///////////////////////
//////////////////////////////////////////////////////

//==============================================================================
// startupOracleScoutingMonitor
//==============================================================================
rule startupOracleScoutingMonitor
group defaultArchaicRules
inactive
minInterval 1
{
   if (cMyCulture != cCultureAtlantean)
   {
      xsDisableRule("startupOracleScoutingMonitor");
      return;
   }
   static int[] planIDs = default;
   if (getHighestPlayerAge() > cAge1)
   {
      debugExploration("Disabling startupOracleScoutingMonitor because somebody reached Classical or higher, we need to be safe now.");
      for (int i = 0; i < planIDs.size(); i++)
      {
         if (aiPlanGetIsIDValid(planIDs[i]) == true)
         {
            aiPlanDestroy(planIDs[i]);
         }
      }
      xsDisableRule("startupOracleScoutingMonitor");
      xsEnableRule("oracleMonitor");
      xsEnableRule("oracleMaintainMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutomaticScouting) == false)
   {
      return;
   }
   debugExploration("--- Running Rule startupOracleScoutingMonitor. ---");

   int oracleQuery = useSimpleUnitQuery(cUnitTypeOracle, cMyID, cUnitStateAlive);
   int numberFound = kbUnitQueryExecute(oracleQuery);
   int masterPlanID = aiPlanGetIDByTypeAndVariableIntValue(cPlanExplore, cExplorePlanMasterExploreAreasPlan, -1);
   for (int i = 0; i < numberFound; i++)
   {
      int unitID = kbUnitQueryGetResult(oracleQuery, i);
      int planID = kbUnitGetPlanID(unitID);
      if (aiPlanGetIsIDValid(planID) == true && (aiPlanGetType(planID) == cPlanExplore || aiPlanGetPriority(planID) > 50))
      {
         continue;
      }
      planID = aiPlanCreate("Oracle Explore, unitID:" + unitID, cPlanExplore, -1, gExplorationCategoryID);
      aiPlanSetPriority(planID, 50);
      aiPlanSetFlag(planID, cPlanFlagNoMoreUnits, true);
      aiPlanAddUnitType(planID, cUnitTypeOracle, 1, 1, 1);
      aiPlanAddUnit(planID, unitID);
      // Stand still if less or equal than 20% of our surrounding tiles are explored.
      aiPlanSetVariableFloat(planID, cExplorePlanStopLOSPercentage, 0, 0.2);
      if (aiPlanGetIsIDValid(masterPlanID) == true)
      {
         aiPlanSetVariableInt(planID, cExplorePlanMasterExploreAreasPlan, 0, masterPlanID);
      }
      planIDs.add(planID);
   }

   static bool increasedInterval = false;
   if (numberFound == 3 && increasedInterval == false)
   {
      debugExploration("We've handled all our starting Oracles, checking for if we need to pull our Oracles back from now on.");
      xsSetRuleMinInterval("startupOracleScoutingMonitor", 5);
      increasedInterval = true;
   }
}

//==============================================================================
// Class OracleInformation
//==============================================================================
class OracleInformation
{
   int[] oracleIDs = default;
   int[] takenAreaIDs = default; // Indexes in sync with oracleIDs.
   int[] validAreaIDs = default;
   int numValidAreas = 0;
   int reservePlanID = -1;
   int[] mTownCenterIDs = default;
   bool needToRecalculateAreas = true;
   int maxAmountOfOracles = 0;
   int oracleMaintainPlanID = -1;

   vector findClosestTCPosition(vector searchPosition = cInvalidVector)
   {
      vector closestPosition = cInvalidVector;
      float closestDistance = cMaxFloat;
      for (int i = 0; i < mTownCenterIDs.size(); i++)
      {
         if (kbUnitGetIsIDValid(mTownCenterIDs[i]) == false)
         {
            // Let manageTownCenter handle this properly.
            continue;
         }
         vector tcPosition = kbUnitGetPosition(mTownCenterIDs[i]);
         float distance = xsVectorLength(searchPosition - tcPosition);
         if (distance < closestDistance)
         {
            closestPosition = tcPosition;
            closestDistance = distance;
         }
      }
      return closestPosition;
   }

   void addValidAreaID(int areaID = -1)
   {
      if (validAreaIDs.find(areaID) == -1)
      {
         validAreaIDs.add(areaID);
         debugExploration("Adding " + areaID + " to the Oracle's list of valid areas.");
      }
   }

   void createReservePlan()
   {
      if (aiPlanGetIsIDValid(reservePlanID) == false)
      {
         reservePlanID = aiPlanCreate("Oracle reserve plan", cPlanReserve, -1, gExplorationCategoryID);
         aiPlanSetPriority(reservePlanID, 100);
         aiPlanAddUnitType(reservePlanID, cUnitTypeOracle, 100, 100, 100);
         aiPlanAddUnitType(reservePlanID, cUnitTypeOracleHero, 100, 100, 100);
         aiPlanSetFlag(reservePlanID, cPlanFlagNoMoreUnits, true); // Prevent auto assignment.
      }
   }

   bool manageTownCenter()
   {
      for (int i = mTownCenterIDs.size() - 1; i >= 0; i--)
      {
         if (kbUnitGetIsIDValid(mTownCenterIDs[i]) == false)
         {
            debugExploration("Town Center with ID " + mTownCenterIDs[i] + " is no longer valid, we need to recalculate areas.");
            mTownCenterIDs.removeIndex(i);
            needToRecalculateAreas = true;
         }
      }
      int queryID = useSimpleUnitQuery(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateAlive);
      kbUnitQuerySetAreaGroupID(queryID, kbAreaGroupGetIDByPosition(aiPlanGetVariableVector(gPrimaryLandDefendPlan,
         cDefendPlanGatherPoint, 0)));
      int numResults = kbUnitQueryExecute(queryID);
      int[] results = kbUnitQueryGetResults(queryID);
      for (int i = 0; i < numResults; i++)
      {
         if (mTownCenterIDs.find(results[i]) == -1)
         {
            debugExploration("Town Center with ID " + results[i] + " is new to our array, we need to recalculate areas.");
            mTownCenterIDs.add(results[i]);
            needToRecalculateAreas = true;
         }
      }

      if (mTownCenterIDs.size() == 0)
      {
         debugExploration("We have no Town Centers alive, just leaving the Oracles now.");
         return false;
      }

      if (needToRecalculateAreas == true)
      {
         validAreaIDs.clear();
         takenAreaIDs.clear();
         oracleIDs.clear();
      }
      return true;
   }

   void recalculateAreas()
   {
      bool[] knownUnwalkableAreas = new bool(kbAreaGetNumber(), false);
      if (needToRecalculateAreas == true)
      {
         int minAreaSize = 200;
         int numTCs =  mTownCenterIDs.size();
         // We want some more areas if we only have 1 TC, yes we will overlap a lot...
         if (numTCs == 1)
         {
            minAreaSize = 175;
         }
         for (int iTC = 0; iTC < numTCs; iTC++)
         {
            bool[] alreadyAnalyzedAreas = new bool(kbAreaGetNumber(), false);
            // TC is the first valid AreaID and also the start point of our search.
            vector tcPosition = kbUnitGetPosition(mTownCenterIDs[iTC]);
            debugExploration("Analyzing TC " + mTownCenterIDs[iTC] + " at " + tcPosition + ".");
            int tcAreaID = kbAreaGetIDByPosition(tcPosition);
            // Always add TC area.
            addValidAreaID(tcAreaID);
            alreadyAnalyzedAreas[tcAreaID] = true;

            // We take the border areas of the TC.
            int numTCBorderAreas = kbAreaGetNumberBorderAreas(tcAreaID);
            int[] tcBorderAreas = new int(0, 0);
            for (int borderOne = 0; borderOne < numTCBorderAreas; borderOne++)
            {
               tcBorderAreas.add(kbAreaGetBorderAreaID(tcAreaID, borderOne));
            }
            for (int borderOne = 0; borderOne < numTCBorderAreas; borderOne++)
            {
               int tcBorderAreaID = tcBorderAreas[borderOne];
               //debugExploration("Analyzing border area of TC " + tcBorderAreaID + ".");
               if (alreadyAnalyzedAreas[tcBorderAreaID] == false && knownUnwalkableAreas[tcBorderAreaID] == false)
               {
                  bool shouldAddBorderArea = true;
                  if (isAreaPassableByLand(tcBorderAreaID) == false)
                  {
                     debugExploration("Skipping areaID " + tcBorderAreaID + " because it's not a walkable land area.");
                     knownUnwalkableAreas[tcBorderAreaID] = true;
                     shouldAddBorderArea = false;
                  }
                  if (kbAreaGetNumberTiles(tcBorderAreaID) <= minAreaSize)
                  {
                     debugExploration("Skipping areaID " + tcBorderAreaID + " because it's too small.");
                     shouldAddBorderArea = false;
                  }
                  if (xsVectorLength(tcPosition - kbAreaGetCenter(tcBorderAreaID)) > 75.0)
                  {
                     debugExploration("Skipping areaID " + tcBorderAreaID + " because it's too far away from the TC.");
                     shouldAddBorderArea = false;
                  }
                  if (shouldAddBorderArea == true)
                  {
                     addValidAreaID(tcBorderAreaID);
                  }
               }
               alreadyAnalyzedAreas[tcBorderAreaID] = true;

               int numOneBorderAreas = kbAreaGetNumberBorderAreas(tcBorderAreaID);
               for (int borderTwo = 0; borderTwo < numOneBorderAreas; borderTwo++)
               {
                  int secondAreaID = kbAreaGetBorderAreaID(tcBorderAreaID, borderTwo);
                  // Don't backtrack and analyze other border areas of the TC or the TC itself.
                  if (secondAreaID == tcAreaID || tcBorderAreas.find(secondAreaID) != -1)
                  {
                     continue;
                  }
                  //debugExploration("Analyzing second border area " + secondAreaID + ".");
                  bool shouldAddSecondBorderArea = true;
                  if (alreadyAnalyzedAreas[secondAreaID] == false && knownUnwalkableAreas[secondAreaID] == false)
                  {
                     if (isAreaPassableByLand(secondAreaID) == false)
                     {
                        debugExploration("Skipping areaID " + secondAreaID + " because it's not a walkable land area.");
                        knownUnwalkableAreas[secondAreaID] = true;
                        shouldAddSecondBorderArea = false;
                     }
                     if (kbAreaGetNumberTiles(secondAreaID) <= minAreaSize)
                     {
                        debugExploration("Skipping areaID " + secondAreaID + " because it's too small.");
                        shouldAddSecondBorderArea = false;
                     }
                     if (xsVectorLength(tcPosition - kbAreaGetCenter(secondAreaID)) > 75.0)
                     {
                        debugExploration("Skipping areaID " + secondAreaID + " because it's too far away from the TC.");
                        shouldAddSecondBorderArea = false;
                     }
                     if (shouldAddSecondBorderArea == true)
                     {
                        addValidAreaID(secondAreaID);
                     }
                  }
                  alreadyAnalyzedAreas[secondAreaID] = true;

                  int numTwoBorderAreas = kbAreaGetNumberBorderAreas(secondAreaID);
                  // Now some trickery, if we don't add the second layer, we will always add the area furthest away in the third
                  // layer since we're going to assume that it's relatively far away from the rest and thus favourable.
                  bool addedSecondBorder = false;
                  int furthestAwayAreaID = -1;
                  float furthestAwayAreaDistance = cMinFloat;
                  bool addedThirdArea = false;
                  for (int borderThree = 0; borderThree < numTwoBorderAreas; borderThree++)
                  {
                     int thirdAreaID = kbAreaGetBorderAreaID(secondAreaID, borderThree);
                     //debugExploration("Analyzing third border area " + thirdAreaID + ".");
                     if (alreadyAnalyzedAreas[thirdAreaID] == true || knownUnwalkableAreas[thirdAreaID] == true)
                     {
                        continue;
                     }
                     alreadyAnalyzedAreas[thirdAreaID] = true;

                     if (isAreaPassableByLand(thirdAreaID) == false)
                     {
                        knownUnwalkableAreas[thirdAreaID] = true;
                        debugExploration("Skipping areaID " + thirdAreaID + " because it's not a walkable land area.");
                        continue;
                     }
                     float distance = xsVectorLength(tcPosition - kbAreaGetCenter(thirdAreaID));
                     if (addedThirdArea == false && shouldAddSecondBorderArea == false && distance > furthestAwayAreaDistance)
                     {
                        // Track a potential candidate to be added regardless of size.
                        furthestAwayAreaDistance = distance;
                        furthestAwayAreaID = thirdAreaID;
                     }
                     if (kbAreaGetNumberTiles(thirdAreaID) <= minAreaSize)
                     {
                        debugExploration("Skipping areaID " + thirdAreaID + " because it's too small.");
                        continue;
                     }
                     if (distance > 75.0)
                     {
                        debugExploration("Skipping areaID " + thirdAreaID + " because it's too far away from the TC.");
                        continue;
                     }
                     addValidAreaID(thirdAreaID);
                     addedThirdArea = true;
                  }

                  // We didn't add any areas in these 2 loops, just add the furthest now.
                  if (furthestAwayAreaID != -1 && addedThirdArea == false && shouldAddSecondBorderArea == false &&
                      tcBorderAreas.find(furthestAwayAreaID) == -1)
                  {
                     addValidAreaID(furthestAwayAreaID);
                  }
               }
            }
         }
         debugExploration("We ended up with " + validAreaIDs.size() + " of valid areas, this is also our Oracle cap.");
         maxAmountOfOracles = validAreaIDs.size();
         numValidAreas = maxAmountOfOracles;
         needToRecalculateAreas = false;
      }
   }
};
extern OracleInformation oracleInformation;

//==============================================================================
// oracleMonitor
// Manage all our alive Oracles during the game.
// Send them to safe areas to gather favor, retreat them from dangerous areas.
//==============================================================================
rule oracleMonitor
group defaultClassicalRules
inactive
minInterval 10 // Reduced based on current difficulty during first run.
{
   if (cMyCulture != cCultureAtlantean)
   {
      xsDisableRule("oracleMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagManageOracles) == false)
   {
      return;
   }
   debugExploration("--- Running Rule oracleMonitor. ---");
   static bool firstRun = true;
   if (firstRun == true)
   {
      // Reduce more the higher the difficulty.
      xsSetRuleMinInterval("oracleMonitor", 10 - cDifficultyCurrent);
   }

   oracleInformation.createReservePlan();
   if (oracleInformation.manageTownCenter() == false)
   {
      // We can't do anything without a valid TC to orient ourself around.
      return;
   }
   oracleInformation.recalculateAreas();

   for (int i = oracleInformation.oracleIDs.size() - 1; i >= 0; i--)
   {
      int oracleID = oracleInformation.oracleIDs[i];
      if (kbUnitGetIsIDValid(oracleID) == false)
      {
         debugExploration("One of our Oracles died/got transformed, removing him from the oracleIDs array.");
         oracleInformation.oracleIDs.removeIndex(i);
         if (oracleInformation.takenAreaIDs[i] != -1)
         {
            oracleInformation.validAreaIDs.add(oracleInformation.takenAreaIDs[i]);
         }
         oracleInformation.takenAreaIDs.removeIndex(i);
      }
   }

   int queryID = useSimpleUnitQuery(cUnitTypeAbstractOracle);
   int numAliveOracles = kbUnitQueryExecute(queryID);
   int[] aliveOracleIDs = kbUnitQueryGetResults(queryID);
   
   bool shouldTryFindNewArea = true;
   for (int i = 0; i < numAliveOracles; i++)
   {
      int oracleID = aliveOracleIDs[i];
      int index = oracleInformation.oracleIDs.find(oracleID);
      if (index == -1)
      {
         index = oracleInformation.oracleIDs.add(oracleID);
         oracleInformation.takenAreaIDs.add(-1);
         aiPlanAddUnit(oracleInformation.reservePlanID, oracleID);
         debugExploration("Adding Oracle " + oracleID + " to the oracleIDs array at index " + index +  ".");
      }

      int currentAreaID = oracleInformation.takenAreaIDs[index];
      if (currentAreaID != -1 && kbAreaGetDangerLevel(currentAreaID, false) > 100.0)
      {
         debugExploration("Oracle " + oracleID + " is standing in a dangerous areaID " + currentAreaID + ", retreating him to TC now.");
         aiTaskMoveUnit(oracleID, oracleInformation.findClosestTCPosition(kbUnitGetPosition(oracleID)));
         oracleInformation.validAreaIDs.add(currentAreaID);
         oracleInformation.takenAreaIDs[index] = -1;
         continue;
      }

      // If this Oracle doesn't have an area assigned, we try to find one for it.
      // This happens when the Oracle is first added to the array and when we had to retreat the Oracle from a danger area.
      if (shouldTryFindNewArea == true && oracleInformation.takenAreaIDs[index] == -1)
      {
         debugExploration("Oracle " + oracleID + " doesn't have an area assigned yet, try to find one.");
         for (int j = 0; j < oracleInformation.validAreaIDs.size(); j++)
         {
            int validAreaID = oracleInformation.validAreaIDs[j];
            if (kbAreaGetDangerLevel(validAreaID, false) > 100.0)
            {
               debugExploration("Skipping " + validAreaID + " because it's too dangerous.");
               continue;
            }
            debugExploration("Found valid areaID " + validAreaID + " for this Oracle, adding it to the takenAreaIDs array at index "
               + index + ".");
            oracleInformation.takenAreaIDs[index] = validAreaID;
            oracleInformation.validAreaIDs.removeIndex(j);
            aiTaskMoveUnit(oracleID, kbAreaGetCenter(validAreaID));
            break;
         }
         if (oracleInformation.takenAreaIDs[index] == -1)
         {
            debugExploration("Didn't find a valid areaID for Oracle " + oracleID + ", we will try again next time. " +
               "Skipping this check for any other potential Oracles since they won't find any areas either.");
            shouldTryFindNewArea = false;
         }
      }
   }

   // Every 30 seconds we move our Oracles back to their intended position, various things could've forced them to move away.
   // We don't do this on the first run because presumably we've already just given all our alive Oracles a move command.
   static int lastRepositionUpdate = 0;
   if (lastRepositionUpdate + 30 < xsGetTime() && firstRun == false)
   {
      for (int i = 0; i < oracleInformation.oracleIDs.size(); i++)
      {
         int oracleID = oracleInformation.oracleIDs[i];
         vector position = cInvalidVector;
         vector oraclePosition = kbUnitGetPosition(oracleID);
         if (kbAreaGetIsIDValid(oracleInformation.takenAreaIDs[i]) == false)
         {
            position = oracleInformation.findClosestTCPosition(oraclePosition);
         }
         else
         {
            position = kbAreaGetCenter(oracleInformation.takenAreaIDs[i]);
         }
         if (xsVectorLength(oraclePosition - position) > 5.0)
         {
            aiTaskMoveUnit(oracleID, position);
         }
      }
      lastRepositionUpdate = xsGetTime();
   }
   firstRun = false;
}

//==============================================================================
// oracleMaintainMonitor
//==============================================================================
rule oracleMaintainMonitor
group defaultClassicalRules
inactive
minInterval 30
{
   if (cMyCulture != cCultureAtlantean)
   {
      xsDisableRule("oracleMaintainMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagTrainOracles) == false)
   {
      if (aiPlanGetIsIDValid(oracleInformation.oracleMaintainPlanID) == true)
      {
         aiPlanDestroy(oracleInformation.oracleMaintainPlanID);
      }
      return;
   }
   debugExploration("--- Running Rule oracleMaintainMonitor. ---");

   if (aiPlanGetIsIDValid(oracleInformation.oracleMaintainPlanID) == false)
   {
      oracleInformation.oracleMaintainPlanID = aiPlanCreate("Oracle Maintain", cPlanTrain, -1, gMilitaryTrainingCategoryID);
      aiPlanSetVariableInt(oracleInformation.oracleMaintainPlanID, cTrainPlanUnitType, 0, cUnitTypeOracle);
      aiPlanSetVariableBool(oracleInformation.oracleMaintainPlanID, cTrainPlanUseMultipleBuildings, 0, false);
      // Don't train Oracles too fast after one another. They cost a lot of gold and other army should take prio.
      aiPlanSetVariableInt(oracleInformation.oracleMaintainPlanID, cTrainPlanFrequency, 0, selectByDifficulty(60, 50, 40, 30, 30, 20));
   }

   if (oracleInformation.mTownCenterIDs.size() == 0)
   {
      // We shouldn't train  Oracles now.
      aiPlanSetVariableInt(oracleInformation.oracleMaintainPlanID, cTrainPlanNumberToMaintain, 0, 0);
      return;
   }

   // Never train Oracles in Archaic
   int numOraclesWanted = 0;
   int currentAge = kbPlayerGetAge(cMyID);
   if (currentAge >= cAge2)
   {
      switch (cDifficultyCurrent)
      {
         case cDifficultyEasy:
         {
            numOraclesWanted = 1;
            break;
         }
         case cDifficultyModerate:
         {
            numOraclesWanted = 2;
            break;
         }
         case cDifficultyHard:
         {
            numOraclesWanted = 3;
            break;
         }
         case cDifficultyTitan:
         case cDifficultyExtreme:
         case cDifficultyLegendary:
         {
            numOraclesWanted = 4;
            break;
         }
      }
   }
   if (currentAge == cAge3 && cDifficultyCurrent >= cDifficultyTitan)
   {
      numOraclesWanted += 1;
   }
   if (currentAge >= cAge4 && cDifficultyCurrent >= cDifficultyExtreme)
   {
      numOraclesWanted += 2;
   }
   // If we have more TCs available to us we can place more Oracles.
   if (cDifficultyCurrent >= cDifficultyTitan)
   {
      if (oracleInformation.mTownCenterIDs.size() > 1)
      {
         numOraclesWanted += 2;
      }
   }
   if (numOraclesWanted > oracleInformation.maxAmountOfOracles)
   {
      debugExploration("Clamping our wanted number of Oracles from " + numOraclesWanted + " to " +
         oracleInformation.maxAmountOfOracles + " since we don't have enough valid areas.");
      numOraclesWanted = oracleInformation.maxAmountOfOracles;
   }
   // Hero and regular Oracles share a build limit.
   int buildLimit = kbPlayerGetProtoStatInt(cMyID, cUnitTypeOracle, cProtoStatBuildLimit);
   if (numOraclesWanted > buildLimit)
   {
      debugExploration("Clamping our wanted number of Oracles from " + numOraclesWanted + " to " +
         buildLimit + " since that's our build limit.");
      numOraclesWanted = buildLimit;
   }
   debugExploration("We want to maintain " + numOraclesWanted + " Oracles.");
   int aliveHeroOracles = kbUnitCount(cUnitTypeOracleHero, cMyID, cUnitStateAlive);
   if (aliveHeroOracles > 0)
   {
      numOraclesWanted -= aliveHeroOracles;
      debugExploration("We already have " + aliveHeroOracles + " Hero Oracles, reducing our wanted Oracle number by that amount. " +
         "New amount: " + numOraclesWanted + ".");
   }
   aiPlanSetVariableInt(oracleInformation.oracleMaintainPlanID, cTrainPlanNumberToMaintain, 0, numOraclesWanted);
}

//////////////////////////////////////////////////////
/////////////////////// Relics ///////////////////////
//////////////////////////////////////////////////////

//==============================================================================
// Relic management
//==============================================================================
int gRelicReservePlanID = -1;
bool gWalkingBackToTemple = false;
int gRelicTempleID = -1;
int gRelicID = -1;
vector gRelicPosition = cInvalidVector;
void resetRelicData()
{
   debugExploration("Resetting all Relic collection process.");
   aiPlanDestroy(gRelicReservePlanID);
   gRelicReservePlanID = -1;
   gWalkingBackToTemple = false;
   gRelicTempleID = -1;
   gRelicID = -1;
   gRelicPosition = cInvalidVector;
}

//==============================================================================
// relicCollectionMonitor
//==============================================================================
rule relicCollectionMonitor
group defaultClassicalRules
inactive
minInterval 30
{
   if (checkStrategyFlag(cStrategyFlagCollectRelics) == false)
   {
      if (aiPlanGetIsIDValid(gRelicReservePlanID) == true)
      {
         aiPlanDestroy(gRelicReservePlanID);
      }
      gWalkingBackToTemple = false;
      return;
   }
   debugExploration("--- Running Rule relicCollectionMonitor. ---");

   if (aiPlanGetIsIDValid(gRelicReservePlanID) == true)
   {
      debugExploration("We already have a Relic retrieval order going on currently, check in on it.");
      if (aiPlanGetNumberUnits(gRelicReservePlanID, -1, false) <= 0)
      {
         debugExploration("We've lost all heroes that we assigned to our reserve plan, restarting process.");
         resetRelicData();
         // Wait a bit longer, enemy may be camping the relic etc...
         xsSetRuleMinInterval("relicCollectionMonitor", 60);
         return;
      }
      else
      {
         int heroID = aiPlanGetUnitIDByIndex(gRelicReservePlanID, 0);
         debugExploration("Our reserve plan is still operational.");
         if (gWalkingBackToTemple == false)
         {
            if (xsVectorDistanceXZSqr(kbUnitGetPosition(heroID), gRelicPosition) < 5.0 * 5.0)
            {
               debugExploration("We're within 5 meters of our Relic, try to pick it up.");
               if (xsVectorDistanceXZSqr(kbUnitGetPosition(gRelicID), gRelicPosition) > 5.0 * 5.0)
               {
                  debugExploration("The Relic is no longer at the spot we thought it was.");
                  resetRelicData();
               }
               else
               {
                  debugExploration("The Relic is at the spot we thought it was, try to pick it up now.");
                  aiTaskWorkUnit(heroID, gRelicID);
               }
            }
            else
            {
               debugExploration("We're not close enough to our Relic, sending another move command.");
               aiTaskMoveUnit(heroID, gRelicPosition);
            }
         }
         else
         {
            if (kbUnitGetIsIDValid(gRelicTempleID) == false)
            {
               debugExploration("We've lost the Temple we wanted to deposit at, trying to find a new one now.");
               int templeID = getClosestUnitByLocation(cUnitTypeTemple, cMyID, cUnitStateAlive, kbUnitGetPosition(heroID), cMaxFloat);
               if (kbUnitGetIsIDValid(templeID) == false)
               {
                  // We just drop the Relic here, we could also bring it back to our base potentially if we want to complicate this.
                  aiTaskUngarrisonUnit(heroID);
                  debugExploration("Couldn't find a new Temple to deposit the Relic at.");
                  resetRelicData();
               }
               else
               {
                  debugExploration("Found a new Temple " + templeID + " to deposit the Relic at.");
                  gRelicTempleID = templeID;
                  aiTaskWorkUnit(heroID, gRelicTempleID);
               }
            }
            else
            {
               aiTaskWorkUnit(heroID, gRelicTempleID);
            }
         }
         return;
      }
   }

   xsSetRuleMinInterval("relicCollectionMonitor", 30);
   if (aiPlanGetState(gPrimaryLandDefendPlan) == cPlanStateAttack)
   {
      debugExploration("Defend plan is in attack state, can't take heroes from it to collect Relics now, quiting.");
      return;
   }
   if (kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateAlive) <= 0)
   {
      debugExploration("We have no alive Temple, can't collect Relics, quiting.");
      return;
   }

   int searchUnitType = cUnitTypeHero;
   if (cMyCulture == cCultureEgyptian && kbTechGetStatus(cTechHandsOfThePharaoh) != cTechStatusActive)
   {
      searchUnitType = cUnitTypePharaoh;
   }

   int[] units = aiPlanGetUnits(gPrimaryLandDefendPlan);
   int heroID = -1;
   int heroProtoUnitID = -1;
   for (int i = 0; i < units.size(); i++)
   {
      if (kbUnitIsType(units[i], searchUnitType) == true)
      {
         heroID = units[i];
         heroProtoUnitID = kbUnitGetProtoUnitID(heroID);
      }
   }
   if (heroID == -1)
   {
      debugExploration("No heroes in defend plan to collect Relics with, quiting.");
      return;
   }
   else
   {
      debugExploration("Found " + kbProtoUnitGetName(heroProtoUnitID) + " (" + heroID + ") in defend plan to collect a Relic with.");
   }

   // Search entire map, area path danger should prevent us suiciding.
   vector searchPosition = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);
   int startAreaID = kbAreaGetIDByPosition(searchPosition);
   int queryID = useSimpleUnitQuery(cUnitTypeRelic, 0, cUnitStateAlive, searchPosition, cMaxFloat);
   // Area group of our defend plan.
   kbUnitQuerySetAreaGroupID(queryID, kbAreaGetGroupID(startAreaID));
   // Want to collect closest relics first.
   kbUnitQuerySetAscendingSort(queryID, true);
   // We could've scouted a Relic that is now taken by the enemy, it will now go to unknown position, guard against it.
   kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateRecentPositionKnown);
   int numResults = kbUnitQueryExecute(queryID);
   int[] relics = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < relics.size(); i++)
   {
      debugExploration("Found Relic, ID: " + relics[i]);
      // Don't allow partial paths and avoid danger.
      if (kbCanAreaPath(searchPosition, kbUnitGetPosition(relics[i]), cPassabilityLand, 100.0, false) == false)
      {
         debugExploration("Couldn't find an area path to this Relic, skipping.");
         continue;
      }
      gRelicID = relics[i];
      gRelicPosition = kbUnitGetPosition(gRelicID);
      gRelicReservePlanID = aiPlanCreate("Relic reserve plan", cPlanReserve, -1, gExplorationCategoryID);
      aiPlanSetPriority(gRelicReservePlanID, 100);
      aiPlanAddUnitType(gRelicReservePlanID, heroProtoUnitID, 1, 1, 1);
      aiPlanAddUnit(gRelicReservePlanID, heroID);
      aiPlanSetFlag(gRelicReservePlanID, cPlanFlagNoMoreUnits, true); // Prevent auto assignment.
      aiPlanSetFlag(gRelicReservePlanID, cPlanFlagCantBeStolenFrom, true);
      aiTaskMoveUnit(heroID, gRelicPosition);
      xsSetRuleMinInterval("relicCollectionMonitor", 5);
      break;
   }
}

//==============================================================================
// relicGarrisonedHandler
//==============================================================================
void relicGarrisonedHandler(int techID = -1)
{
   sendStatementToEnemies(cAICommPromptToEnemyITookARelic);
   if (aiPlanGetIsIDValid(gRelicReservePlanID) == true)
   {
      resetRelicData();
   }
   debugExploration("Relic garrisoned: " + kbTechGetName(techID) + ".");
}

//==============================================================================
// relicPickedUpHandler
//==============================================================================
void relicPickedUpHandler(int techID = -1)
{
   sendStatementToAllies(cAICommPromptToAllyITookARelic);
   debugExploration("Relic picked up: " + kbTechGetName(techID) + ".");
   if (aiPlanGetIsIDValid(gRelicReservePlanID) == false)
   {
      return;
   }
   // If we're here we're going to assume this plan picked up a Relic.
   int heroID = aiPlanGetUnitIDByIndex(gRelicReservePlanID, 0);
   int templeID = getClosestUnitByLocation(cUnitTypeTemple, cMyID, cUnitStateAlive, kbUnitGetPosition(heroID), cMaxFloat);
   if (kbUnitGetIsIDValid(templeID) == false)
   {
      debugExploration("We must've lost our Temple while we were collecting our Relic...");
      resetRelicData();
   }
   else
   {
      debugExploration("Tasking hero " + heroID + " back to Temple " + templeID + ".");
      aiTaskWorkUnit(heroID, templeID);
      gWalkingBackToTemple = true;
      gRelicTempleID = templeID;
   }
}