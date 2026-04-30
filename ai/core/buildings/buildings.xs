//==============================================================================
/* buildings.xs

   This file is intended for managing what buildings the AI should create and when.

*/
//==============================================================================

// Greek have 3 different military buildings, * 2 = 6 total.
#if (cMyCulture == cCultureGreek)
const int cMaxOfRegularBuildingInOneBase = 2;
#else
// All others have 2 military buildings * 3 = 6 total.
const int cMaxOfRegularBuildingInOneBase = 3;
#endif
// We allow 2 Fortress per base, this is a rare occassion since we also expand other bases with one automatically.
const int cMaxOfFortressBuildingInOneBase = 2;
// Limit amount of concurrent build plans that still require resources, otherwise our wood need sky rockets out of control.
const int cMaxBuildPlansActive = 2;
// Keep track of the start time where the militaryBuildingManager didn't want any more buildings.
// This is then used to, after a delay, start expanding regardless.
int startTimeNoExtraBuildingsNeeded = cMaxInt;
//==============================================================================
// militaryBuildingManager 
//==============================================================================
rule militaryBuildingManager
inactive
group defaultClassicalRules
minInterval 10
{
   if (checkStrategyFlag(cStrategyFlagAutoBuildMilitaryBuildings) == false)
   {
      return;
   }
   debugBuildings("--- Running Rule militaryBuildingManager. ---");

   int totalNumberBuildPlansMade = 0;
   int totalBuildPlansActive = 0;

   // We scan here for all build plans in the gMilitaryBuildings array. This includes Fortress + Temple too while we also build those
   // outside of this rule. This means that those buildings get prio over regular military buildings since they don't cap themselves.
   int numberMilitaryBuildings = gMilitaryBuildings.size();
   for (int i = 0; i < numberMilitaryBuildings; i++)
   {
      int buildingPUID = gMilitaryBuildings[i];
      if (kbProtoUnitAvailable(buildingPUID) == false)
      {
         continue;
      }
      int[] existingBuildPlans = aiPlanGetIDsByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, buildingPUID);
      for (int iPlan = 0; iPlan < existingBuildPlans.size(); iPlan++)
      {
         // Build plans that are in the none state still require resources to be assigned to them, and we want to limit resource needs.
         if (aiPlanGetState(existingBuildPlans[iPlan]) == cPlanStateNone)
         {
            totalBuildPlansActive++;
         }
         // If we're in state place we've already claimed the resources but the placement can fail, and then we would stack plans again.
         if (aiPlanGetState(existingBuildPlans[iPlan]) == cPlanStatePlace)
         {
            totalBuildPlansActive++;
         }
      }
      if (totalBuildPlansActive >= 2)
      {
         debugBuildings("We already have 2 or more military build plans active, can't create any more.");
         return;
      }
   }

   // Go through all the buildings in our gMilitaryBuildings array.
   for (int i = 0; i < numberMilitaryBuildings; i++)
   {
      int buildingPUID = gMilitaryBuildings[i];
      if (kbProtoUnitAvailable(buildingPUID) == false)
      {
         continue;
      }

      // Limit how many of these we can make per base based on what kind of building it is.
      int maxOfBuildingInOneBase = cMaxOfRegularBuildingInOneBase;
      if (buildingPUID == gFortressUnit)
      {
         maxOfBuildingInOneBase = cMaxOfFortressBuildingInOneBase;
      }
      // Custom limit on Siege Works, you just don't need to spam these...
      else if (buildingPUID == cUnitTypeSiegeWorks)
      {
         maxOfBuildingInOneBase = 1;
      }

      int buildLimit = kbPlayerGetProtoStatInt(cMyID, buildingPUID, cProtoStatBuildLimit);
      int numberExistingBuildings = buildingGetNumberAliveAndPlanned(buildingPUID);
      if (numberExistingBuildings >= buildLimit && buildLimit != -1)
      {
         debugBuildings("We are already at the build limit for: " + kbProtoUnitGetName(buildingPUID) + ".");
         continue;
      }
      
      float numberBuildingsReq = 0.0;
      bool inUse = false;

      // Go through all maintain plans that we have and see if they require the current building from the buildings array.
      for (int j = 0; j < gNumTotalArmyUnitTypes; j++)
      {
         if (buildingPUID != gArmyUnitBuildings[j])
         {
            continue;
         }
         int maintainPlanID = gArmyUnitMaintainPlans[j];
         if (aiPlanGetIsIDValid(maintainPlanID) == false)
         {
            continue;
         }
         int numberToMaintain = aiPlanGetVariableInt(maintainPlanID, cTrainPlanNumberToMaintain, 0);
         if (numberToMaintain < 1)
         {
            continue;
         }

         // How many buildings do we want?
         // We aim to have enough buildings to train all our wanted units in < 2 minutes.
         int puid = aiPlanGetVariableInt(maintainPlanID, cTrainPlanUnitType, 0);
         float numPerMinute = 60 / kbPlayerGetProtoStatFloat(cMyID, puid, cProtoStatTrainPoints);
         float minutesToGoal = numberToMaintain / numPerMinute;
         debugBuildings("Maintain plan for " + kbProtoUnitGetName(puid) + " adds " + (minutesToGoal / 2.0) +
            " to our number buildings required.");
         numberBuildingsReq += minutesToGoal / 2.0;
         inUse = true;
      }

      if (inUse == false)
      {
         debugBuildings("We have completely no need for " + kbProtoUnitGetName(buildingPUID) + ".");
         continue;
      }

      // Always round upwards so we're sure we have enough buildings.
      int numberTotalBuildingsWanted = ceil(numberBuildingsReq); 
      // If we have a low eco pop we don't want to build that many buildings, clamp to 1.
      int numberEcoPop = aiGetCurrentEconomyPop() + aiGetCurrentNavalEconomyPop();
      if (numberEcoPop < 20)
      {
         debugBuildings("We have too few eco pop, capping how many buildings we can make of: " +
            kbProtoUnitGetName(buildingPUID) + " to 1.");
         numberTotalBuildingsWanted = 1;
      }
      debugBuildings("We want: " + numberTotalBuildingsWanted + " total " + kbProtoUnitGetName(buildingPUID) +
         ", we already have " + numberExistingBuildings + " of them.");
      numberTotalBuildingsWanted -= numberExistingBuildings;

      if (buildLimit != -1 && (numberExistingBuildings + numberTotalBuildingsWanted) > buildLimit)
      {
         numberTotalBuildingsWanted = buildLimit - numberExistingBuildings;
         debugBuildings("With the amount of buildings we wanted to make we would go over the build limit, capping at " +
            numberTotalBuildingsWanted + " buildings instead.");
      }
      if (totalBuildPlansActive + numberTotalBuildingsWanted > cMaxBuildPlansActive)
      {
         numberTotalBuildingsWanted = cMaxBuildPlansActive - totalBuildPlansActive;
         debugBuildings("We want more new buildings than we allow max concurrent build plans, limiting number wanted to "
            + numberTotalBuildingsWanted + ".");
      }
      if (numberTotalBuildingsWanted <= 0)
      {
         continue;
      }

      // Find TC bases that we can use.
      int numBases = kbBaseGetNumber(cMyID);
      for (int iBase = 0; iBase < numBases; iBase++)
      {
         int baseID = kbBaseGetIDByIndex(cMyID, iBase);
         if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
         {
            continue;
         }
         int numBuildingsInBase = getCountOfOwnAliveBuildingInBase(buildingPUID, baseID); 
         numBuildingsInBase += getAmountBuildPlansInBase(buildingPUID, baseID);
         if (numBuildingsInBase >= maxOfBuildingInOneBase)
         {
            continue;
         }

         debugBuildings(kbBaseGetNameByID(cMyID, baseID) + " already has : " + numBuildingsInBase + "/" +
            maxOfBuildingInOneBase + ".");
         int numBuildingsToMake = numberTotalBuildingsWanted;
         if (numBuildingsInBase + numBuildingsToMake > maxOfBuildingInOneBase)
         {
            numBuildingsToMake = maxOfBuildingInOneBase - numBuildingsInBase;
            debugBuildings("Capping number buildings to make to " + numBuildingsToMake + " in this base because otherwise " +
               "we would go over our max in one base.");
         }

         debugBuildings("Creating build plans for " + numBuildingsToMake + " " + kbProtoUnitGetName(buildingPUID) + ".");
         int prio = 70;
         // Don't have too high prio for a Fortress unit, it can block a lot of other expenses.
         if (buildingPUID == gFortressUnit)
         {
            prio = 50;
         }
         createSimpleBuildPlan(buildingPUID, numBuildingsToMake, prio, baseID, cCalculateNumBuildersAutomatically);
         totalNumberBuildPlansMade += numBuildingsToMake;
         totalBuildPlansActive += numBuildingsToMake;
         numberTotalBuildingsWanted -= numBuildingsToMake;
         if (numberTotalBuildingsWanted == 0)
         {
            break;
         }
      }
      if (totalBuildPlansActive >= 2)
      {
         debugBuildings("We already have 2 or more military build plans active, can't create any more.");
         break;
      }
   }
   if (totalNumberBuildPlansMade > 0)
   {
      startTimeNoExtraBuildingsNeeded = cMaxInt;
   }
   else
   {
      startTimeNoExtraBuildingsNeeded = xsGetTime();
   }
}

//==============================================================================
// fortressBuildingManager
// Even though our automatic military construction + base expansion also create Fortresses we still need this rule.
// Example: Egyptian military logic throws out all Migdol units if we have no Migdol -> auto military building construction
// sees no need for a Migdol -> base expansion is off for easy/moderate -> no Migdol is ever made -> stuck in Heroic. 
//==============================================================================
rule fortressBuildingManager
inactive
group defaultHeroicRules
minInterval 30
{
   if (checkStrategyFlag(cStrategyFlagAutoBuildMilitaryBuildings) == false)
   {
      return;
   }
   debugBuildings("--- Running Rule fortressBuildingManager. ---");
   
   // We never want to have more than 1 Fortress build plan active at the same time, just so expensive.
   int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, gFortressUnit);
   int fortressCount = kbUnitCount(gFortressUnit, cMyID, cUnitStateAlive);
   if (aiPlanGetIsIDValid(planID) == true)
   {
      // Make sure if we no Fortress alive that the priority is set correctly.
      if (fortressCount == 0)
      {
         aiPlanSetPriority(planID, 55);
      }
      debugBuildings("Already have a " + kbProtoUnitGetName(gFortressUnit) + " build plan, quiting.");
      return;
   }

   // If we're here we know we aren't already building a Fortress.
   if (fortressCount == 0)
   {
      // If we currently own no Fortresses, place one in our most fortified TC base.
      int baseID = getMostDefendedTCBase();
      if (baseID == -1)
      {
         debugBuildings("We have no TC bases, not building a " + kbProtoUnitGetName(gFortressUnit) + " now.");
      }
      else
      {
         // Get one back with some prio.
         createSimpleBuildPlan(gFortressUnit, 1, 55, baseID, cCalculateNumBuildersAutomatically);
      }
      return;
   }

   // If we're here we already have 1 Fortress at least.
   // Even though these buildings are strong they are also a big drain on the eco.
   // So if we really need them the militaryBuildingManager will create them, otherwise we do it here when we can afford it.
   if (haveExcessResourceAmount(450.0, cResourceGold) == false)
   {
      debugBuildings("We don't have enough excess gold to make more " + kbProtoUnitGetName(gFortressUnit) + ".");
      return;
   }
   if (cMyCulture != cCultureEgyptian && haveExcessResourceAmount(450.0, cResourceWood) == false)
   {
      debugBuildings("We don't have enough excess wood to make more " + kbProtoUnitGetName(gFortressUnit) + ".");
      return;
   }

   bool madePlan = false;
   // Find TC bases that we can use.
   int numBases = kbBaseGetNumber(cMyID);
   for (int iBase = 0; iBase < numBases; iBase++)
   {
      int baseID = kbBaseGetIDByIndex(cMyID, iBase);
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
      {
         continue;
      }
      // Just one per base for this logic.
      if (getCountOfOwnAliveBuildingInBase(gFortressUnit, baseID) >= 1)
      {
         continue;
      }
      // Not high prio because it's so expensive.
      createSimpleBuildPlan(gFortressUnit, 1, 50, baseID, cCalculateNumBuildersAutomatically);
      madePlan = true;
      break;
   }

   if (madePlan == false)
   {
      debugBuildings("Didn't find a suitable TC base to make a " + kbProtoUnitGetName(gFortressUnit) + " in.");
   }
}

//==============================================================================
// baseBuildingExpansionMonitor 
//==============================================================================
rule baseBuildingExpansionMonitor
inactive
group defaultClassicalRules
minInterval 60
{
   // Low difficulties don't expand their base. 
   if (cDifficultyCurrent <= cDifficultyModerate)
   {
      xsDisableRule("baseBuildingExpansionMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutoBuildMilitaryBuildings) == false)
   {
      return;
   }
   if (startTimeNoExtraBuildingsNeeded + 120 > xsGetTime())
   {
      return;
   }
   debugBuildings("--- Running Rule baseBuildingExpansionMonitor. ---");

   static int queryID = -1;
   if (queryID == -1)
   {
      queryID = kbUnitQueryCreate("baseBuildingExpansionMonitor");
      kbUnitQuerySetPlayerID(queryID, cMyID);
      kbUnitQuerySetState(queryID, cUnitStateAlive);
   }

   int numBases = kbBaseGetNumber(cMyID);
   int numPlansCreated = 0;
   int maxBuildingsToCreate = 1;
   if (cDifficultyCurrent >= cDifficultyExtreme)
   {
      maxBuildingsToCreate = 2;
   }
   for (int i = 0; i < numBases; i++)
   {
      int baseID = kbBaseGetIDByIndex(cMyID, i);
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
      {
         continue; // We just expand TC bases.
      }
      debugBuildings("Analyzing base: " + kbBaseGetNameByID(cMyID, baseID) + ".");
      // Loop through our Military buildings and add some to our bases.
      for (int j = 0; j < gMilitaryBuildings.size(); j++)
      {
         int buildingPUID = gMilitaryBuildings[j];
         // Don't build Fortresses with this, those are very expensive and their construction needs to be really needed or controlled.
         if (kbProtoUnitAvailable(buildingPUID) == false || buildingPUID == gFortressUnit)
         {
            continue;
         }

         kbUnitQuerySetUnitType(queryID, buildingPUID);
         kbUnitQuerySetBaseID(queryID, baseID);
         kbUnitQueryResetResults(queryID);
         int numBuildingsInBase = kbUnitQueryExecute(queryID);
         numBuildingsInBase += getAmountBuildPlansInBase(buildingPUID, baseID);
         
         // Limit how many of these we can make per base based on what kind of building it is.
         int maxOfBuildingInOneBase = cMaxOfRegularBuildingInOneBase;
         if (buildingPUID == cUnitTypeSiegeWorks)
         {
            maxOfBuildingInOneBase = 1;
         }
         debugBuildings("We have " + numBuildingsInBase + "/" + maxOfBuildingInOneBase + " " +
            kbProtoUnitGetName(buildingPUID) + " in this base.");
         if (numBuildingsInBase >= maxOfBuildingInOneBase)
         {
            continue;
         }

         createSimpleBuildPlan(buildingPUID, 1, 70, baseID, cCalculateNumBuildersAutomatically);
         numPlansCreated++;
         // If we're building a Fortress type building, just out instantly since it costs a lot.
         // This isn't fully reliable since we could've built something before this but oh well.
         if (numPlansCreated >= maxBuildingsToCreate || buildingPUID == gFortressUnit)
         {
            return;
         }
      }
   }
}

//==============================================================================
// calculateTowerAmountPerTCBase
//==============================================================================
int calculateTowerAmountPerTCBase()
{
   int personalityModifier = 1; // Standard.
   if (cPersonalityCurrent == cPersonalityAttacker)
   {
      personalityModifier = 0;
   }
   else if (cPersonalityCurrent == cPersonalityDefender)
   {
      personalityModifier = 2;
   }
   int age = kbPlayerGetAge(cMyID);
   int ageModifier = 0;
   if (age == cAge3) // Heroic.
   {
      ageModifier = 1;
   }
   if (age == cAge4) // Mythic.
   {
      ageModifier = 2;
      if (cPersonalityCurrent == cPersonalityDefender)
      {
         personalityModifier = 3;
      }
   }
   int towerTotal = personalityModifier + ageModifier;

   switch (cDifficultyCurrent)
   {
      case cDifficultyModerate:
      {
         towerTotal = max(towerTotal, 2);
         break;
      }
      case cDifficultyHard:
      {
         towerTotal = max(towerTotal, 3);
         break;
      }
   }

   debugBuildings("calculateTowerAmountPerTCBase returned: " + towerTotal + ".");
   return towerTotal;
}

//==============================================================================
// towerManager
// Tries to maintain as many towers as the strategy says.
// Or as how many we calculated automatically.
// TODO: insert Mirror Towers. Call ourself recursively with a variable that saves tower type if we've aged up with Atlas.
//==============================================================================
rule towerManager
inactive
group defaultClassicalRules
minInterval 1 // We set the proper interval on the first run.
{
   if (checkStrategyFlag(cStrategyFlagBuildTowers) == false)
   {
      return;
   }
   if (cDifficultyCurrent == cDifficultyEasy)
   {
      xsDisableRule("towerManager");
      return;
   }
   debugBuildings("--- Running Rule towerManager. ---");
   static bool firstRun = true;
   if (firstRun == true)
   {
      int intervalTime = 120;
      if (cDifficultyCurrent <= cDifficultyHard)
      {
         intervalTime += 60;
      }
      if (cPersonalityCurrent == cPersonalityAttacker)
      {
         intervalTime += 30;
      }
      else if (cPersonalityCurrent == cPersonalityDefender)
      {
         intervalTime -= 30;
      }
      debugBuildings("Setting minInterval of towerManager to " + intervalTime + ".");
      xsSetRuleMinInterval("towerManager", intervalTime);
      firstRun = false;
   }
   
   // First fetch the strategy numbers. If the strategy hasn't set this number it's cCalculateNumberTowersAutomatically.
   int towersWanted = getStrategyTowerAmount();
   if (towersWanted == cCalculateNumberTowersAutomatically)
   {
      towersWanted = calculateTowerAmountPerTCBase();
   }
   if (towersWanted == 0)
   {
      debugBuildings("Quiting towerManager because we want to build 0 Towers right now.");
      return;
   }

   if (calculateNumPossibleToBuild(cUnitTypeSentryTower) == 0)
   {
      debugBuildings("Quiting towerManager because we're already at our build limit.");
      return;
   }
   debugBuildings("We want " + towersWanted + " " + kbProtoUnitGetName(cUnitTypeSentryTower) + "s per Town Center base.");

   int numTotalTowersBuilt = 0;
   int numMaxAllowedTowersPerIteration = 1;
   if (cDifficultyCurrent >= cDifficultyTitan && cPersonalityCurrent == cPersonalityDefender)
   {
      numMaxAllowedTowersPerIteration = 2;
   }

   int numBases = kbBaseGetNumber(cMyID);
   for (int i = 0; i < numBases; i++)
   {
      int baseID = kbBaseGetIDByIndex(cMyID, i);
      if (kbBaseGetOwner(baseID) != cMyID)
      {
         continue;
      }
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
      {
         debugBuildings("Skipping base: " + kbBaseGetNameByID(cMyID, baseID) + ", because it's not a Town Center base.");
         continue;
      }
      if (getCountOfOwnAliveBuildingInBase(cUnitTypeSentryTower, baseID) +
          getAmountBuildPlansInBase(cUnitTypeSentryTower, baseID) >= towersWanted)
      {
         debugBuildings("Skipping base: " + kbBaseGetNameByID(cMyID, baseID) + ", because it already has our max amount of Towers per base.");
         continue;
      }
      // Valid base to place a Tower!
      debugBuildings("Analyzing base: " + kbBaseGetNameByID(cMyID, baseID) + ", to place a Tower.");

      vector baseVec =  kbBaseGetLocation(cMyID, baseID);
      int numTestVecs = 12;
      float towerAngle = cTwoPi / numTestVecs;
      const float cBaseTowerRadius = 24.0;
      // half distance between each test vec.
      float exclusionRadius = cBaseTowerRadius * sin(towerAngle / 2.0);
      vector startingVec = rotateByAngle(vector(cBaseTowerRadius, 0.0, 0.0), xsRandFloat(0.0, cTwoPi));

      int towerQuery = useSimpleUnitQuery(cUnitTypeSentryTower, cMyID, cUnitStateABQ);
      kbUnitQuerySetBaseID(towerQuery, baseID);
      int numberFound = kbUnitQueryExecute(towerQuery);
      int[] towers = kbUnitQueryGetResults(towerQuery);
      int gatesQuery = useSimpleUnitQuery(cUnitTypeWallGate, cMyID, cUnitStateABQ);
      kbUnitQuerySetBaseID(towerQuery, baseID);
      int numberGates = kbUnitQueryExecute(gatesQuery);
      int[] gates = kbUnitQueryGetResults(gatesQuery);
      int testVecIndex = 0;

      bool createdBuildPlan = false;
      while (createdBuildPlan == false && testVecIndex < numTestVecs)
      {
         bool validPlacement = false;
         vector location = cInvalidVector;
         for (int j = 0; j < numberGates; j++)
         {
            validPlacement = true;
            location = kbUnitGetPosition(gates[j]);
            vector stepBack = baseVec - location;
            location = location + xsVectorNormalize(stepBack) * 3.0;
            for (int k = 0; k < numberFound; k++)
            {
               if (xsVectorLength(kbUnitGetPosition(towers[k]) - location) < exclusionRadius)
               {
                  validPlacement = false;
                  break;
               }
            }
            if (validPlacement == true)
            {
               debugBuildings("Gate method: valid Tower location: " + location + ".");
               break;
            }
         }

         // Fallback to old logic.
         if (validPlacement == false)
         {
            location = baseVec + rotateByAngle(startingVec, towerAngle * testVecIndex);
            validPlacement = true;
            // Check if location is used already.
            for (int j = 0; j < numberFound; j++)
            {
               if (xsVectorLength(kbUnitGetPosition(towers[j]) - location) < exclusionRadius)
               {
                  validPlacement = false;
                  break;
               }
            }
            if (kbGetIsLocationOnMap(location) == false)
            {
               validPlacement = false;
            }
            if (validPlacement == true)
            {
               debugBuildings("Circle around base method: valid Tower location: " + location + ".");
            }
         }

         if (validPlacement == true)
         {
            int prio = 50;
            if (cPersonalityCurrent == cPersonalityDefender)
            {
               prio = 51;
            }
            int planID = createLocationBuildPlan(cUnitTypeSentryTower, 1, prio, location, 7.5, 2.0);
            aiPlanSetBaseID(planID, baseID); // Force it to the current base so it properly gets put in that base too.
            createdBuildPlan = true;
            numTotalTowersBuilt++;
         }

         testVecIndex++;
      }

      if (createdBuildPlan == true)
      {
         debugBuildings("Created a Tower build plan for this base!.");
      }
      else
      {
         debugBuildings("Couldn't find a spot to build a Tower on for this base.");
      }

      if (numTotalTowersBuilt >= numMaxAllowedTowersPerIteration)
      {
         debugBuildings("Created " + numTotalTowersBuilt + " Tower build plans, which is also our max per iteration, not analyzing more bases.");
         return;
      }
   }
}

//==============================================================================
// wallManager
//==============================================================================
rule wallManager
inactive
minInterval 0
{
   xsSetRuleMinInterval("wallManager", 10);
   // Need a tiny bit smarter check here since we can be maintaining multiple rings
   if (aiPlanGetIDByTypeAndVariableIntValue(cPlanBuildWall, cBuildWallPlanWallType, cBuildWallPlanWallTypeRing) >= 0)
   {
      return;
   }
   debugBuildings("--- Running Rule wallManager. ---");

   int numWallCircles = getStrategyWallCircleAmount();
   // We want circles around our main base
   for (int iCircle = 0 ; iCircle < numWallCircles; iCircle++)
   {
      int wallPlanID = aiPlanCreate("WallInBase" + iCircle, cPlanBuildWall, -1, gBuildingsCategoryID);
      int mainID = kbBaseGetMainID(cMyID);
      if (mainID == -1)
      {
         return;
      }
      float radius = 30.0 + iCircle * 20.0;
      // Tiny nudge for our biggest level
      if (iCircle >= 2)
      {
         radius += 10.0;
      }
      if (wallPlanID != -1)
      {
         aiPlanSetVariableInt(wallPlanID, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeRing);
         // TODO: we should allow multiple workers but currently the plan doesn't support it
         if(cMyCulture != cCultureNorse)
         {
            aiPlanAddUnitType(wallPlanID, cUnitTypeAbstractVillager, 0, 1, 1);
         }
         else
         {
            aiPlanAddUnitType(wallPlanID, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 0, 1, 1);
         }
         aiPlanSetVariableVector(wallPlanID, cBuildWallPlanWallRingCenterPoint, 0, kbBaseGetLocation(cMyID, mainID));
         aiPlanSetVariableFloat(wallPlanID, cBuildWallPlanWallRingRadius, 0, radius);
         // gate obstruction size is 8, we want 1 gate every 3 walls.
         aiPlanSetVariableInt(wallPlanID, cBuildWallPlanNumberOfGates, 0, radius * cTwoPi / 36.0);
         aiPlanSetBaseID(wallPlanID, mainID);
         // Prioritize inner circles more than outer
         aiPlanSetPriority(wallPlanID, 82 - iCircle);
      }
   }
}

//==============================================================================
// templeMonitor
// We always maintain 1 Temple in our most defend base, and slowly build more if resources allow it and we have enough TC bases.
//==============================================================================
rule templeMonitor
inactive
group defaultArchaicRules
minInterval 30
{
   if (checkStrategyFlag(cStrategyFlagBuildTemple) == false)
   {
      return;
   }
   debugBuildings("--- Running Rule templeMonitor. ---");
   // We never want to have more than 1 Temple build plan active at the same time.
   // This also solves an issue in Nomad where your mainBase changes and then suddenly getAmountBuildPlansInBase can't 
   // find your existing build plan for the old mainBase anymore and you end up with 2.
   if (aiPlanGetIsIDValid(aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeTemple)) == true)
   {
      debugBuildings("Already have a Temple build plan, quiting.");
      return;
   }

   // If we're here we know we aren't already building a temple.
   int templeCount = kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateAlive);
   if (templeCount == 0)
   {
      // If we currently own no Temples, place one in our most fortified TC base.
      int baseID = getMostDefendedTCBase();
      if (baseID == -1)
      {
         debugBuildings("We have no TC bases, not building a Temple now.");
      }
      else
      {
         createSimpleBuildPlan(cUnitTypeTemple, 1, 55, baseID, cCalculateNumBuildersAutomatically);
      }
      return;
   }

   // If we're here we already have 1 Temple at least. We don't really need many more but will slowly build more in other TC bases.
   if (haveExcessResourceAmount(400.0, cResourceGold) == false)
   {
      debugBuildings("We don't have enough excess gold to make more Temples.");
      return;
   }
   if (cMyCulture != cCultureEgyptian && haveExcessResourceAmount(400.0, cResourceWood) == false)
   {
      debugBuildings("We don't have enough excess wood to make more Temples.");
      return;
   }

   bool madePlan = false;
   // Find TC bases that we can use.
   int numBases = kbBaseGetNumber(cMyID);
   for (int iBase = 0; iBase < numBases; iBase++)
   {
      int baseID = kbBaseGetIDByIndex(cMyID, iBase);
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
      {
         continue;
      }
      // Just one per base.
      if (getCountOfOwnAliveBuildingInBase(cUnitTypeTemple, baseID) >= 1)
      {
         continue;
      }
      createSimpleBuildPlan(cUnitTypeTemple, 1, 55, baseID, cCalculateNumBuildersAutomatically);
      madePlan = true;
      break;
   }

   if (madePlan == false)
   {
      debugBuildings("Didn't find a suitable TC base to make a Temple in.");
   }
}

//==============================================================================
// dockMonitor
// Tries to maintain the wanted amount of Docks on water maps.
//==============================================================================
rule dockMonitor
inactive
group defaultArchaicRules
minInterval 30
{
   if (checkStrategyFlag(cStrategyFlagAutomaticDockBuilding) == false)
   {
      return;
   }
   if (gMapInfo.mHasWater == false)
   {
      debugBuildings("Map has no water, disabling dockMonitor.");
      xsDisableRule("dockMonitor");
      return;
   }
   if (gMapInfo.mShouldBuildDock == false)
   {
      return;
   }
   debugBuildings("--- Running Rule dockMonitor. ---");

   vector waterPoint = gClosestFishLocation;
   if (waterPoint == cInvalidVector)
   {
      waterPoint = gMapInfo.mWaterDefendPoint;
   }
   if (waterPoint == cInvalidVector)
   {
      aiEchoWarning("We can't find a valid vector to orient ourself around while we're meant to build a Dock.");
      return;
   }

   // Don't create Docks while we're under serious attack.
   if (gDefenseReflexPanic == true)
   {
      debugBuildings("Not building a Dock right now because we're in serious danger on the land.");
      return;
   }
   int currentAge = kbPlayerGetAge(cMyID);
   int currentDockCount = buildingGetNumberAliveAndPlanned(cUnitTypeDock);
   if (currentDockCount >= 1 && currentAge == cAge1)
   {
      debugBuildings("Not building a Dock right now because we already have one and are in the Archaic age.");
      return;
   }
   // Not completely reliable since we don't do a path, but oh well.
   float dangerRating = kbAreaGetDangerLevel(gMapInfo.mClosestShorelineAreaID, false);
   if (dangerRating >= 100.0)
   {
      debugBuildings("Not building a Dock right now because our wanted shoreline area is too dangerous.");
      return;
   }

   int numDocksToBuild = 1;
   int maxNavalPop = aiGetNavalMilitaryPop();
   debugBuildings("We already have " + currentDockCount + " alive/planned Docks.");
   switch (cDifficultyCurrent)
   {
      case cDifficultyEasy:
      case cDifficultyModerate:
      {
         // Max 1 Dock for these.
         debugBuildings("We want a minimum of " + numDocksToBuild + " Docks as a baseline.");
         numDocksToBuild -= currentDockCount;
         break;
      }
      case cDifficultyHard:
      case cDifficultyTitan:
      {
         if (currentAge >= cAge3)
         {
            numDocksToBuild = 2; // Baseline of 2 from Heroic onwards.
         }
         int numDocksNeeded = ceil(xsIntToFloat(maxNavalPop) / 15.0); 
         debugBuildings("We want a minimum of " + numDocksToBuild + " Docks as a baseline.");
         debugBuildings("We have a need of " + numDocksNeeded + " Docks for naval unit production.");
         // Every 15 naval military pop we want another Dock.
         numDocksToBuild = max(numDocksToBuild, numDocksNeeded);
         numDocksToBuild -= currentDockCount;
         break;
      }
      case cDifficultyExtreme:
      case cDifficultyLegendary:
      {
         if (currentAge >= cAge3)
         {
            numDocksToBuild = 2; // Baseline of 2 from Heroic onwards.
         }
         if (currentAge >= cAge4)
         {
            numDocksToBuild = 3; // Baseline of 3 from Mythic onwards.
         }
         // Every 10 naval military pop we want another Dock.
         int numDocksNeeded = ceil(xsIntToFloat(maxNavalPop) / 10.0);
         debugBuildings("We want a minimum of " + numDocksToBuild + " Docks as a baseline.");
         debugBuildings("We have a need of " + numDocksNeeded + " Docks for naval unit production.");
         numDocksToBuild = max(numDocksToBuild, numDocksNeeded);
         numDocksToBuild -= currentDockCount;
         break;
      }
   }

   debugBuildings("We want to build " + numDocksToBuild + " new Docks.");

   for (int i = 0; i < numDocksToBuild; i++)
   {
      int planID = createDockBuildPlan(kbAreaGetCenter(gMapInfo.mClosestShorelineAreaID), waterPoint);
      aiPlanSetEventHandler(planID, cPlanEventStateChange, "dockAnalysis");
   }
}

//==============================================================================
// fortressRepairMonitor
//==============================================================================
rule fortressRepairMonitor
group defaultHeroicRules
inactive
minInterval 30
{
   if (checkStrategyFlag(cStrategyFlagAutomaticFortressRepair) == false)
   {
      return;
   }
   debugBuildings("--- Running Rule fortressRepairMonitor. ---");
   
   if (kbUnitCount(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateABQ) == 0)
   {
      debugBuildings("Can't look to repair any Fortresses because we have no Town Centers left, focus on that fully.");
      return;
   }

   int queryID = useSimpleUnitQuery(cUnitTypeAbstractFortress, cMyID, cUnitStateAlive);
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
            int areaID = kbUnitGetAreaID(unitID);
            // Dont start repairing in a warzone.
            if (kbAreaGetDangerLevel(areaID) >= 100.0)
            {
               debugBuildings("Won't repair " + kbProtoUnitGetName(gFortressUnit) + "(" + unitID +
                              ") right now because the area is too dangerous.");
               continue;
            }
            debugBuildings("Found a " + kbProtoUnitGetName(gFortressUnit) + "(" + unitID +
                           ") that has been damaged, creating a repair plan for it.");
            int planID = aiPlanCreate("Repair " + kbProtoUnitGetName(gFortressUnit) + " ID: " + unitID, cPlanRepair, -1,
                                      gBuildingsCategoryID);
            aiPlanSetVariableInt(planID, cRepairPlanTargetID, 0, unitID);
            // Little bit higher prio since we need these buildings to compete.
            aiPlanSetPriority(planID, 51);
            addBuilderTypesToPlan(planID, gFortressUnit, 2);
            aiPlanSetBaseID(planID, kbUnitGetBaseID(unitID));
         }
      }
   }
}

//==============================================================================
// buildingRepairMonitor
// This rule is very infrequent and tries to repair our lesser important buildings.
// Also this rule has more limitations, if we're already repairing something we just quit.
//==============================================================================
rule buildingRepairMonitor
group defaultClassicalRules
inactive
minInterval 60
{
   if (checkStrategyFlag(cStrategyFlagAutomaticBuildingRepair) == false)
   {
      return;
   }
   debugBuildings("--- Running Rule buildingRepairMonitor. ---");
   
   if (kbUnitCount(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateABQ) == 0)
   {
      debugBuildings("Can't look to repair any new buildings because we have no Town Centers left, focus on that fully.");
      return;
   }
   if (aiPlanGetNumberByType(cPlanRepair) != 0)
   {
      debugBuildings("Can't look to repair any new buildings because we already have an active repair plan.");
      return;
   }

   static bool firstRun = true;
   static int[] excludes = default;
   if (firstRun == true)
   {
      firstRun = false;
      excludes = new int(4, -1);
      // We repair these buildings in other rules.
      excludes[0] = cUnitTypeAbstractSocketedTownCenter;
      excludes[1] = cUnitTypeAbstractFortress;
      excludes[2] = cUnitTypeTitanGate;
      excludes[3] = cUnitTypeWonder;
   }
   
   int queryID = useSimpleUnitQuery(cUnitTypeBuilding, cMyID, cUnitStateAlive);
   kbUnitQuerySetExcludeTypes(queryID, excludes);
   kbUnitQueryExecute(queryID);
   int[] results = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < results.size(); i++)
   {
      int unitID = results[i];
      if (kbUnitGetStatBool(unitID, cUnitStatRepairable) == false)
      {
         continue;
      }
      if (kbUnitGetStatFloat(unitID, cUnitStatCurrHP) < kbUnitGetStatFloat(unitID, cUnitStatMaxHP))
      {
         // We need to repair!
         int protoUnitID = kbUnitGetProtoUnitID(unitID);
         int areaID = kbUnitGetAreaID(unitID);
         // Dont start repairing in a warzone.
         if (kbAreaGetDangerLevel(areaID) >= 100.0)
         {
            debugBuildings("Won't repair " + kbProtoUnitGetName(protoUnitID) + "(" + unitID +
                           ") right now because the area is too dangerous.");
            continue;
         }
         debugBuildings("Found a " + kbProtoUnitGetName(protoUnitID) + "(" + unitID +
                        ") that has been damaged, creating a repair plan for it.");
         int planID = aiPlanCreate("Repair " + kbProtoUnitGetName(protoUnitID) + " ID: " + unitID, cPlanRepair, -1,
                                   gBuildingsCategoryID);
         aiPlanSetVariableInt(planID, cRepairPlanTargetID, 0, unitID);
         aiPlanSetPriority(planID, 50);
         addBuilderTypesToPlan(planID, protoUnitID, 1);
         aiPlanSetBaseID(planID, kbUnitGetBaseID(unitID));
         // One plan at a time.
         return;
      }
   }
}

//==============================================================================
// arenaGates
// Transform some of our Wall Longs into Gates.
//==============================================================================
rule arenaGates
inactive
minInterval 10
{
   debugBuildings("--- Running Rule arenaGates. ---");

   static int[] toTransform = default;
   static bool firstRun = true;
   if (firstRun == true)
   {
      toTransform = new int (2, -1);
      int queryID = useSimpleUnitQuery(cUnitTypeWallLong);
      int numResults = kbUnitQueryExecute(queryID);
      // Few Wall Longs? Just transform 1 and be done otherwise the index math below doesn't work out anymore.
      if (numResults < 7)
      {
         aiTransformWallIntoGate(kbUnitQueryGetResult(queryID, numResults / 2));
         debugBuildings("Disabling rule arenaGates because we started with few Wall Longs and just transformed 1.");
         xsDisableRule("arenaGates");
         return;
      }
      // On the Arena maps this makes sure we get Gates in all corners of our Wall.
      toTransform[0] = kbUnitQueryGetResult(queryID, 2);
      toTransform[1] = kbUnitQueryGetResult(queryID, numResults - 3);
      // We start with 15 extra gold on Arena to make 1 Gate, do so now.
      aiTransformWallIntoGate(kbUnitQueryGetResult(queryID, numResults / 2));
      firstRun = false;
   }

   // Don't need extra Gates in Archaic and don't want to mess with BO resource management.
   if (kbPlayerGetAge(cMyID) == cAge1 || isBuildOrderDone() == false)
   {
      return;
   }

   for (int i = 0; i < toTransform.size(); i++)
   {
      // Remove Wall Longs that died or have already been transformed into Gates.
      if (kbUnitGetIsIDValid(toTransform[i]) == false ||
          kbUnitIsType(toTransform[i], cUnitTypeWallLong) == false)
      {
         toTransform.removeIndex(i);
         i--;
         continue;
      }
      aiTransformWallIntoGate(toTransform[i]);
   }

   if (toTransform.size() == 0)
   {
      debugBuildings("Disabling rule arenaGates because we either got our 3 gates or the Wall Longs went invalid.");
      xsDisableRule("arenaGates");
   }
}