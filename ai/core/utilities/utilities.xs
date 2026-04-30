//==============================================================================
/* utilities.xs

   This file contains utility functions used among all files.

*/
//==============================================================================


//==============================================================================
//==============================================================================
//==============================================================================
//==============================================================================
//==============================================================================
// Algorithms
//==============================================================================
//==============================================================================
//==============================================================================
//==============================================================================
//==============================================================================
vector rotateByAngle(vector vec = cInvalidVector, float angle = 0.0)
{

   vector result = vector(
      vec.x * cos(angle) - vec.z * sin(angle),
      0.0,
      vec.x * sin(angle) + vec.z * cos(angle)
   );
   debugUtilities("rotateByAngle returned: " + result);
   return result;
}

//==============================================================================
// randomShuffleIntArray
//==============================================================================
void randomShuffleIntArray(ref int[] array, int size = 0)
{
   int i = size - 1;
   int j = 0;
   int temp = 0;
   while (i >= 0)
   {
      j = xsRandInt(0, i);
      temp = array[i];
      array[i] = array[j];
      array[j] = temp;
      i = i - 1;
   }
}

//==============================================================================
bool arraySortIntComp(int a = -1, int b = -1) { return (a < b); }
//==============================================================================
// arraySortInt
//==============================================================================
void arraySortInt(ref int[] array, int begin = 0, int end = -1, bool(int, int) comp = arraySortIntComp)
{
   int j = 0;
   int key = 0;

   if (end < 0)
   {
      end = array.size();
   }
   for (int i = begin + 1; i < end; i++)
   {
      key = array[i];
      j = i - 1;
      while ((j >= 0) && (comp(array[j], key) == false))
      {
         array[j + 1] = array[j];
         j--;
      }
      array[j + 1] = key;
   }
}

//==============================================================================
// createSimpleResearchPlan
//==============================================================================
int createSimpleResearchPlan(int techID = -1, int buildingPUID = -1, int prio = 50)
{
   int planID = aiPlanCreate("Research Plan: " + kbTechGetName(techID), cPlanResearch, -1, gTechsCategoryID);
   if (aiPlanGetIsIDValid(planID) == true)
   {
      aiPlanSetVariableInt(planID, cResearchPlanTechID, 0, techID);
      aiPlanSetVariableInt(planID, cResearchPlanBuildingTypeID, 0, buildingPUID);
      aiPlanSetPriority(planID, prio);
      debugTechs("Created a Research Plan for: " + kbTechGetName(techID) + " with plan number: " + planID + ", priority: " + prio + ".");
   }

   return planID;
}

//==============================================================================
// createSimpleResearchPlanSpecificResearcher
//==============================================================================
int createSimpleResearchPlanSpecificResearcher(int techID = -1, int buildingID = -1, int prio = 50, bool military = false)
{
   int planID = aiPlanCreate("Research Plan Specific Building: " + kbTechGetName(techID), cPlanResearch, -1, gTechsCategoryID);
   if (aiPlanGetIsIDValid(planID) == true)
   {
      aiPlanSetVariableInt(planID, cResearchPlanTechID, 0, techID);
      aiPlanSetVariableInt(planID, cResearchPlanResearcherID, 0, buildingID);
      aiPlanSetPriority(planID, prio);
      if (military == false)
      {
         debugTechs("Created a Research Plan Specific Researcher for: " + kbTechGetName(techID) + " with plan number: " + planID);
      }
      else
      {
         debugMilitaryTraining("Created a Research Plan Specific Researcher for: " + kbTechGetName(techID) + " with plan number: " + planID);
      }
   }

   return planID;
}

//==============================================================================
// researchSimpleTech
//==============================================================================
bool researchSimpleTech(int techID = -1, int buildingPUID = -1, int buildingID = -1, int prio = 50)
{
   if (buildingPUID >= 0 && buildingID >= 0)
   {
      aiEchoWarning("Calling researchSimpleTech with both a buildingPUID and buildingID defined, this doesn't work.");
   }
   int techStatus = kbTechGetStatus(techID);
   if (techStatus == cTechStatusActive)
   {
      aiEchoWarning("Technology is already active, can't start a new research plan: " + kbTechGetName(techID));
      return true;
   }
   if (techStatus == cTechStatusUnobtainable)
   {
      aiEchoWarning("Technology is unobtainable, can't start a new research plan: " + kbTechGetName(techID));
      return false;
   } // If it's Obtainable we continue with the logic.

   int upgradePlanID = aiPlanGetIDByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, techID);
   if (aiPlanGetIsIDValid(upgradePlanID) == false) // We have no plan yet, check if we should create one.
   {
      if (buildingPUID >= 0)
      {
         if (createSimpleResearchPlan(techID, buildingPUID, prio) >= 0)
         {
            return true;
         }
      }
      else
      {
         if (createSimpleResearchPlanSpecificResearcher(techID, buildingID, prio) >= 0)
         {
            return true;
         }
      }
   }
   return false;
}

//==============================================================================
// createSimpleMaintainPlan
//==============================================================================
int createSimpleMaintainPlan(int puid = -1, int numberWanted = 1, int baseID = -1, int prio = 50, int buildingID = -1,
   int buildingPUID = -1, bool allowZeroWanted = false)
{
   if (numberWanted <= 0 && allowZeroWanted == false)
   {
      aiEchoWarning("Calling createSimpleMaintainPlan with an invalid numberWanted: " + numberWanted + ", for puid: " + 
         kbProtoUnitGetName(puid) + ".");
      return -1;
   }
   // Create a the plan name.
   string planName = "Maintain " + numberWanted + " " + kbProtoUnitGetName(puid);
   // This could also be for eco units and then it should be different output.
   int planID = aiPlanCreate(planName, cPlanTrain, -1, gMilitaryTrainingCategoryID);
   if (aiPlanGetIsIDValid(planID) == false)
   {
      return (-1);
   }

   // Unit type.
   aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, puid);
   // numberWanted.
   aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberWanted);

   if (buildingID >= 0 && buildingPUID >= 0)
   {
      aiEchoWarning("Calling createSimpleTrainPlan with both a buildingID and buildingPUID.");
   }
   if (buildingID >= 0)
   {
      aiPlanSetVariableInt(planID, cTrainPlanBuildingID, 0, buildingID);
   }
   else if (buildingPUID >= 0)
   {
      aiPlanSetVariableInt(planID, cTrainPlanBuildFromType, 0, buildingPUID);
   }
   // If we provide no buildingID nor a buildingPUID the engine will figure out a building by itself.

   // If we have a base ID, use it.
   if (kbBaseGetIsIDValid(cMyID, baseID) == true)
   {
      aiPlanSetVariableVector(planID, cTrainPlanGatherPoint, 0, kbBaseGetMilitaryGatherPoint(cMyID, baseID));
   }

   aiPlanSetPriority(planID, prio);

   if (puid == gEconUnit || puid == gFishingUnit || puid == gCaravanUnit)
   {
      debugEconomy("Created a maintain plan for " + numberWanted + " " + kbProtoUnitGetName(puid));
   }
   else
   {
      debugMilitaryTraining("Created a maintain plan for " + numberWanted + " " + kbProtoUnitGetName(puid));
   }
   
   return planID;
}

//==============================================================================
// createSimpleTrainPlan
//==============================================================================
int createSimpleTrainPlan(int puid = -1, int numberWanted = 1, int baseID = -1, int prio = 50, int buildingID = -1, int buildingPUID = -1)
{
   if (numberWanted <= 0)
   {
      aiEchoWarning("Calling createSimpleTrainPlan with an invalid numberWanted: " + numberWanted + ", for puid: " + 
         kbProtoUnitGetName(puid) + ".");
      return -1;
   }
   // Create a the plan name.
   string planName = "Train " + numberWanted + " " + kbProtoUnitGetName(puid);
   // This could also be for eco units and then it should be different output.
   int planID = aiPlanCreate(planName, cPlanTrain, -1, gMilitaryTrainingCategoryID);
   if (aiPlanGetIsIDValid(planID) == false)
   {
      return (-1);
   }

   // Unit type.
   aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, puid);
   // numberWanted.
   aiPlanSetVariableInt(planID, cTrainPlanNumberToTrain, 0, numberWanted);

   if (buildingID >= 0 && buildingPUID >= 0)
   {
      aiEchoWarning("Calling createSimpleTrainPlan with both a buildingID and buildingPUID.");
   }
   if (buildingID >= 0)
   {
      aiPlanSetVariableInt(planID, cTrainPlanBuildingID, 0, buildingID);
   }
   else if (buildingPUID >= 0)
   {
      aiPlanSetVariableInt(planID, cTrainPlanBuildFromType, 0, buildingPUID);
   }
   // If we provide no buildingID nor a buildingPUID the engine will figure out a building by itself.

   // If we have a base ID, use it.
   if (kbBaseGetIsIDValid(cMyID, baseID) == true)
   {
      aiPlanSetVariableVector(planID, cTrainPlanGatherPoint, 0, kbBaseGetMilitaryGatherPoint(cMyID, baseID));
   }
   aiPlanSetPriority(planID, prio);

   debugMilitaryTraining("Created a train plan for " + numberWanted + " " + kbProtoUnitGetName(puid));
   return planID;
}

//==============================================================================
// buildingGetNumberAliveAndPlanned
//==============================================================================
int buildingGetNumberAliveAndPlanned(int puid = -1, bool planDoneWhenFoundationPlaced = false)
{
   int state = cUnitStateAlive;
   if (planDoneWhenFoundationPlaced == true)
   {
      state = cUnitStateABQ;
   }
   int num = kbUnitCount(puid, cMyID, state);
   num += aiPlanGetNumberByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, puid);
   return num;
}

//==============================================================================
// calculateNumberHousesNeeded
//==============================================================================
int calculateNumberHousesNeeded()
{
   if (kbPlayerGetProtoStatInt(cMyID, gHouseUnit, cProtoStatBuildLimit) <= buildingGetNumberAliveAndPlanned(gHouseUnit))
   {
      debugBuildings("calculateNumberHousesNeeded we're at our build limit for " + kbProtoUnitGetName(gHouseUnit) + ".");
      return 0;
   }

   int existingPlans = aiPlanGetNumberByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, gHouseUnit);
   debugBuildings("calculateNumberHousesNeeded found " + existingPlans + " existing " + kbProtoUnitGetName(gHouseUnit) + " plans.");
   int age = kbPlayerGetAge(cMyID);
   int popCap = kbPlayerGetPopCap(cMyID);
   int currentPop = kbPlayerGetPop(cMyID);
   int numHousesNeeded = 0;

   // Special handling for Archaic age.
   if (age == cAge1)
   {
      if (popCap - currentPop < 5) // Less than 5 spaces means we want another House.
      {
         numHousesNeeded++;
      }
   }
   else // Start planning for houses earlier in later ages, since potentially we can gain a lot of pop fast then.
   {
      if (popCap - currentPop < 10 + 5 * age)
      {
         numHousesNeeded++;
         // If we're Titan and above and really close to getting housed, put 2 down.
         if ((cDifficultyCurrent >= cDifficultyTitan) && (popCap - currentPop < 10))
         {
            numHousesNeeded++;
         }
      }
   }

   numHousesNeeded = max(numHousesNeeded - existingPlans, 0);
   debugBuildings("calculateNumberHousesNeeded returned " + numHousesNeeded + ".");
   return numHousesNeeded;
}

//==============================================================================
// guessEnemyLocation
//==============================================================================
vector guessEnemyLocation(int playerID = -1)
{
   if (playerID <= 0)
   {
      playerID = aiGetMostHatedPlayerID();
   }
   vector position = cInvalidVector;
   if (playerID > 0)
   {
      position = kbPlayerGetStartingPosition(playerID);
   }

   if ((cDifficultyCurrent >= cDifficultyHard) && (position != cInvalidVector))
   {
      // For higher difficulties, assuming the AI played on this map before, it should have a rough idea of the enemy location.
      float xError = kbGetMapXSize() * 0.05;
      float zError = kbGetMapZSize() * 0.05;
      position.x += xsRandFloat(0.0 - xError, xError);
      position.z += xsRandFloat(0.0 - zError, zError);
   }
   else if (kbBaseGetMainID(cMyID) != -1)
   {
      // For lower difficulties or invalid playerID, just simply create a mirror image of our base.
      vector myBaseLocation = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)); // Main base location...need to find reflection.
      vector mapCenter = kbGetMapCenter();
      vector centerOffset = mapCenter - myBaseLocation;
      position = mapCenter + centerOffset;
   }
   else // We have no idea...
   {
      position = kbGetMapCenter();
   }

   debugExploration("guessEnemyLocation returned: " + position);
   return position;
}

//==============================================================================
// baseBuildingCount
// Returns how many buildings are in the base.
// If you need a count of how many allied buildings are in your own KB base
// then use a real query which can filter on that.
//==============================================================================
int baseBuildingCount(int playerID = -1, int baseID = -1, int relation = cPlayerRelationAny, int state = cUnitStateAlive)
{
   int retVal = -1;

   if (kbBaseGetIsIDValid(playerID, baseID) == true)
   {
      // Check for buildings in the base, regardless of player ID (only baseOwner can have buildings there)
      int owner = kbBaseGetOwner(baseID);
      retVal = getUnitCountByLocation(cUnitTypeBuilding, relation, state, kbBaseGetLocation(owner, baseID),
               kbBaseGetDistance(owner, baseID));
   }

   debugMilitaryDefending("baseBuildingCount returned: " + retVal + " amount of buildings in base " + kbBaseGetNameByID(playerID, baseID) + ".");
   return retVal;
}

//==============================================================================
// handleTributeRequest
// Checks whether we have enough resources to be able to afford a tribute.
// And if we have enough we also make the tribute here.
//==============================================================================
bool handleTributeRequest(int resourceToTribute = -1, int playerToTributeTo = -1)
{
   float amountAvailable = gResourceNeeds[resourceToTribute] * -0.85; // Leave room for tribute penalty.
   if (aiResourceIsLocked(resourceToTribute) == true)
   {
      amountAvailable = 0.0;
   }
   if (amountAvailable > 100.0) // We will tribute something.
   { 
      debugUtilities("We will tribute some: " + kbGetResourceName(resourceToTribute) + " to player: " + playerToTributeTo);
      if (amountAvailable > 200.0)
      {
         aiTribute(playerToTributeTo, resourceToTribute, amountAvailable / 2);
      }
      else
      {
         aiTribute(playerToTributeTo, resourceToTribute, 100.0);
      }
      return true;
   }
   debugUtilities("We don't have enough: "+ kbGetResourceName(resourceToTribute) + " to tribute to player: " + playerToTributeTo);
   return false;
}

//==============================================================================
/* isDefendingOrAttacking
   We only allow 1 "real" attack/defend plan to be active at a time.
   Filter out the persistent defend plans and the child reinforcing attack plans.
*/
//==============================================================================
bool isDefendingOrAttacking()
{
   int existingPlanID = -1;
   int[] plans = new int(0, 0);

   plans = aiPlanGetIDsByType(cPlanAttack);
   for (int i = 0; i < plans.size(); i++)
   {
      existingPlanID = plans[i];
      if (aiPlanGetParentID(existingPlanID) == -1)
      {
         debugMilitaryAttacking("isDefendingOrAttacking: found an attack plan named: " +
                       aiPlanGetName(existingPlanID));
         return true;
      }
   }

   plans = aiPlanGetIDsByType(cPlanDefend);
   for (int i = 0; i < plans.size(); i++)
   {
      existingPlanID = plans[i];
      if (existingPlanID != gPrimaryLandDefendPlan && 
          existingPlanID != gPrimaryNavalDefendPlan)
      {
         debugMilitaryAttacking("isDefendingOrAttacking: found a defend plan named: " +
                       aiPlanGetName(existingPlanID));
         return true;
      }
   }

   return false;
}

//==============================================================================
// turnNumberIntoTimeDisplay
//==============================================================================
string turnNumberIntoTimeDisplay(int input = -1)
{
   int minutes = input / 60;
   int seconds = input % 60;
   return "minutes: " + minutes + " seconds: " + seconds;
}

//==============================================================================
// getMainGatherBaseID
//==============================================================================
int getMainGatherBaseID()
{
   return gMainGatherBase != -1 ? gMainGatherBase : kbBaseGetMainID(cMyID);
}

//==============================================================================
// selectByDifficulty
//==============================================================================
int selectByDifficulty(int easy = -1, int moderate = -1, int hard = -1, int titan = -1, int extreme = -1, int legendary = -1)
{
#if (cDifficultyCurrent == cDifficultyEasy)
   return easy;
#elif (cDifficultyCurrent == cDifficultyModerate)
   return moderate;
#elif (cDifficultyCurrent == cDifficultyHard)
   return hard;
#elif (cDifficultyCurrent == cDifficultyTitan)
   return titan;
#elif (cDifficultyCurrent == cDifficultyExtreme)
   return extreme;
#elif (cDifficultyCurrent == cDifficultyLegendary)
   return legendary;
#endif
}

//==============================================================================
// getHumanPresentInGame
//==============================================================================
bool getHumanPresentInGame()
{
   for (int i = 1; i <= cNumberPlayers; i++)
   {
      if (i != cMyID)
      {
         if (kbPlayerIsHuman(i) == true)
         {
            if (kbPlayerHasLost(i) == false)
            {
               return true;
            }
         }
      }
   }
   return false;
}

//==============================================================================
// getHighestPlayerAge
//==============================================================================
int getHighestPlayerAge()
{
   int highestAge = cAge1;
   for (int i = 1; i <= cNumberPlayers; i++)
   {
      if (i != cMyID)
      {
         if (kbPlayerHasLost(i) == false)
         {
            if (kbPlayerGetAge(i) > highestAge)
            {
               highestAge = kbPlayerGetAge(i);
            }
         }
      }
   }
   return highestAge;
}

//==============================================================================
// transferAllUnitsBetweenTwoPlans
//==============================================================================
void transferAllUnitsBetweenTwoPlans(int providerID = -1, int receiverID = -1)
{
   if (aiPlanGetIsIDValid(providerID) == false)
   {
      aiEchoWarning("Calling transferAllUnitsBetweenTwoPlans with an invalid providerID: " + providerID);
      return;
   }
   if (aiPlanGetIsIDValid(receiverID) == false)
   {
      aiEchoWarning("Calling transferAllUnitsBetweenTwoPlans with an invalid receiverID: " + receiverID);
      return;
   }
   if (providerID == receiverID)
   {
      return;
   }

   int[] providerUnits = aiPlanGetUnits(providerID);
   for (int i = 0; i < providerUnits.size(); i++)
   {
      int unitID = providerUnits[i];
      if (kbUnitGetIsIDValid(unitID) == true)
      {
         // v2.2 BUG FIX: bylo jen aiPlanAddUnit(receiverID, unitID) - jednotka mohla zustat ve dvou planech najednou.
         aiPlanRemoveUnit(providerID, unitID);
         aiPlanAddUnit(receiverID, unitID);
      }
   }
}

//==============================================================================
// isTitanUnit
//==============================================================================
bool isTitanUnit(int unitID = -1)
{
   if (kbUnitGetIsIDValid(unitID) == false)
   {
      return false;
   }
   return kbProtoUnitIsType(kbUnitGetProtoUnitID(unitID), cUnitTypeAbstractTitan);
}

//==============================================================================
// planContainsTitan
//==============================================================================
bool planContainsTitan(int planID = -1)
{
   if (aiPlanGetIsIDValid(planID) == false)
   {
      return false;
   }
   int[] units = aiPlanGetUnits(planID);
   for (int i = 0; i < units.size(); i++)
   {
      if (isTitanUnit(units[i]) == true)
      {
         return true;
      }
   }
   return false;
}

//==============================================================================
// getRandomEnabledMilitaryMythUnit
//==============================================================================
int getRandomEnabledMilitaryMythUnit(int trainerPUID = -1)
{
   static int unitPicker = -1;
   int[] results = new int(0, 0);
   if (kbUnitPickGetIsIDValid(unitPicker) == false)
   {
      unitPicker = kbUnitPickCreate("Random Myth Unit");
   }

   kbUnitPickResetAll(unitPicker);
   kbUnitPickSetMovementType(unitPicker, cPassabilityAmphibious);
   kbUnitPickSetMovementType(unitPicker, cPassabilityAir);
   kbUnitPickSetPreferenceFactor(unitPicker, cUnitTypeMythUnit, 1.0);
   // We handle Dryads differently.
   kbUnitPickSetPreferenceFactor(unitPicker, cUnitTypeDryad, 0.0);
   // Exclude non fighting myths.
   kbUnitPickSetPreferenceFactor(unitPicker, cUnitTypePegasus, 0.0);
   kbUnitPickSetPreferenceFactor(unitPicker, cUnitTypeRoc, 0.0);

   int numResults = kbUnitPickRun(unitPicker);
   for (int i = 0; i < numResults; i++)
   {
      int resultPUID = kbUnitPickGetResult(unitPicker, i);
      if (kbProtoUnitCanTrain(trainerPUID, resultPUID) == true)
      {
         results.add(resultPUID);
      }
   }
   if (results.size() == 0)
   {
      return -1;
   }
   if (results.size() == 1)
   {
      return results[0];
   }
   int randomIndex = xsRandInt(0, results.size() -1);
   return results[randomIndex];
}

//==============================================================================
// getAllEnabledMilitaryMythUnits
//==============================================================================
int[] getAllEnabledMilitaryMythUnits(int trainerPUID = -1)
{
   static int unitPicker = -1;
   if (kbUnitPickGetIsIDValid(unitPicker) == false)
   {
      unitPicker = kbUnitPickCreate("All Myth Units");
   }

   kbUnitPickResetAll(unitPicker);
   kbUnitPickSetMovementType(unitPicker, cPassabilityAmphibious);
   kbUnitPickSetMovementType(unitPicker, cPassabilityAir);
   kbUnitPickSetPreferenceFactor(unitPicker, cUnitTypeMythUnit, 1.0);
   // We handle Dryads differently.
   kbUnitPickSetPreferenceFactor(unitPicker, cUnitTypeDryad, 0.0);
   // Exclude non fighting myths.
   kbUnitPickSetPreferenceFactor(unitPicker, cUnitTypePegasus, 0.0);
   kbUnitPickSetPreferenceFactor(unitPicker, cUnitTypeRoc, 0.0);
   kbUnitPickRun(unitPicker);

   int[] results = kbUnitPickGetResults(unitPicker);
   for (int i = 0; i < results.size(); i++)
   {
      int resultPUID = results[i];
      if (kbProtoUnitCanTrain(trainerPUID, resultPUID) == false)
      {
         results.removeIndex(i);
         i--;
      }
   }

   return results;
}

//==============================================================================
// getNumberEnemies
//==============================================================================
int getNumberEnemies()
{
   int numberEnemies = 0;
   for (int i = 1; i <= cNumberPlayers; i++)
   {
      if (i != cMyID)
      {
         if (kbPlayerIsEnemy(i) == true)
         {
            if (kbPlayerHasLost(i) == false)
            {
               numberEnemies++;
            }
         }
      }
   }
   return numberEnemies;
}

//==============================================================================
// getRandomEnemyID
//==============================================================================
int getRandomEnemyID()
{
   int[] enemyIDs = new int(0, 0);
   for (int i = 1; i <= cNumberPlayers; i++)
   {
      if (i != cMyID)
      {
         if (kbPlayerIsEnemy(i) == true)
         {
            if (kbPlayerHasLost(i) == false)
            {
               enemyIDs.add(i);
            }
         }
      }
   }
   if (enemyIDs.size() == 0)
   {
      return -1;
   }
   if (enemyIDs.size() == 1)
   {
      return enemyIDs[0];
   }
   int rand = xsRandInt(0, enemyIDs.size() - 1);
   return enemyIDs[rand];
}

//==============================================================================
// isAreaPassableByLand
//==============================================================================
bool isAreaPassableByLand(int areaID = -1)
{
   if (kbAreaGetIsIDValid(areaID) == false)
   {
      aiEchoWarning("Calling isAreaPassableByLand with an invalid areaID: " + areaID + ".");
      return false;
   }
   int type = kbAreaGetType(areaID);
   if (type == cAreaTypePassableLand || type == cAreaTypeSettlement || type == cAreaTypeGold)
   {
      return true;
   }
   return false;
}

//==============================================================================
// isLocationTooCloseToTheEdge
//==============================================================================
bool isLocationTooCloseToTheEdge(vector input = cInvalidVector, float distance = 0.0)
{
   if (kbGetIsLocationOnMap(input) == false)
   {
      return false;
   }
   if ((input.x - distance < 0.0) || (input.x + distance > kbGetMapXSize()))
   {
      return false;
   }
   if ((input.z - distance < 0.0) || (input.z + distance > kbGetMapZSize()))
   {
      return false;
   }
   return true;
}

//==============================================================================
// setDefaultDefendPlanTargetUnitTypes
//==============================================================================
void setDefaultDefendPlanTargetUnitTypes(int defendPlanID = -1)
{
   if (aiPlanGetIsIDValid(defendPlanID) == false)
   {
      aiEchoWarning("Calling setDefaultDefendPlanTargetUnitTypes with an invalid planID: " + defendPlanID + ".");
      return;
   } 
   // v2.2 BUG FIX: bylo jen hand+ranged - plany pak hur reagovaly na myth/siege/Titana v boji.
   aiPlanSetNumberVariableValues(defendPlanID, cDefendPlanTargetUnitTypes, 5); // bylo 2
   aiPlanSetVariableInt(defendPlanID, cDefendPlanTargetUnitTypes, 0, cUnitTypeLogicalTypeHandUnitsAttack);
   aiPlanSetVariableInt(defendPlanID, cDefendPlanTargetUnitTypes, 1, cUnitTypeLogicalTypeRangedUnitsAttack);
   aiPlanSetVariableInt(defendPlanID, cDefendPlanTargetUnitTypes, 2, cUnitTypeMythUnit);
   aiPlanSetVariableInt(defendPlanID, cDefendPlanTargetUnitTypes, 3, cUnitTypeAbstractSiegeWeapon);
   aiPlanSetVariableInt(defendPlanID, cDefendPlanTargetUnitTypes, 4, cUnitTypeAbstractTitan);
}

//==============================================================================
// setDefaultAttackPlanTargetUnitTypes
//==============================================================================
void setDefaultAttackPlanTargetUnitTypes(int attackPlanID = -1)
{
   if (aiPlanGetIsIDValid(attackPlanID) == false)
   {
      aiEchoWarning("Calling setDefaultAttackPlanTargetUnitTypes with an invalid planID: " + attackPlanID + ".");
      return;
   } 
   // v2.2 BUG FIX: bylo jen hand+ranged - utocne plany pak ignorovaly cast hrozeb na fronte.
   aiPlanSetNumberVariableValues(attackPlanID, cAttackPlanTargetUnitTypes, 5); // bylo 2
   aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetUnitTypes, 0, cUnitTypeLogicalTypeHandUnitsAttack);
   aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetUnitTypes, 1, cUnitTypeLogicalTypeRangedUnitsAttack);
   aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetUnitTypes, 2, cUnitTypeMythUnit);
   aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetUnitTypes, 3, cUnitTypeAbstractSiegeWeapon);
   aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetUnitTypes, 4, cUnitTypeAbstractTitan);
}

//==============================================================================
// setDefaultExplorePlanTargetUnitTypes
//==============================================================================
void setDefaultExplorePlanTargetUnitTypes(int explorePlanID = -1)
{
   if (aiPlanGetIsIDValid(explorePlanID) == false)
   {
      aiEchoWarning("Calling setDefaultExplorePlanTargetUnitTypes with an invalid planID: " + explorePlanID + ".");
      return;
   } 
   aiPlanSetNumberVariableValues(explorePlanID, cExplorePlanTargetUnitTypes, 2);
   aiPlanSetVariableInt(explorePlanID, cExplorePlanTargetUnitTypes, 0, cUnitTypeLogicalTypeHandUnitsAttack);
   aiPlanSetVariableInt(explorePlanID, cExplorePlanTargetUnitTypes, 1, cUnitTypeLogicalTypeRangedUnitsAttack);
}

//==============================================================================
// calculateNumPossibleToBuild
// Calculates the number still possible to build considering currently planned
// buildings. Returns 100000 if there's no build limit
//==============================================================================
int calculateNumPossibleToBuild(int buildingPUID = -1)
{
   int buildLimit = kbPlayerGetProtoStatInt(cMyID, buildingPUID, cProtoStatBuildLimit);
   if (buildLimit == -1)
   {
      return 100000;
   }
   int numberExistingBuildings = buildingGetNumberAliveAndPlanned(buildingPUID);
   if (numberExistingBuildings >= buildLimit)
   {
      return 0;
   }
   return buildLimit - numberExistingBuildings;
}

//==============================================================================
// getRandom45DegreesOffset
//==============================================================================
vector getRandom45DegreesOffset()
{
   int rand = xsRandInt(0, 7);
   switch (rand)
   {
      case 0:
      {
         return cDegrees0;
      }
      case 1:
      {
         return cDegrees45;
      }
      case 2:
      {
         return cDegrees90;
      }
      case 3:
      {
         return cDegrees135;
      }
      case 4:
      {
         return cDegrees180;
      }
      case 5:
      {
         return cDegrees225;
      }
      case 6:
      {
         return cDegrees270;
      }
      case 7:
      {
         return cDegrees315;
      }
   }
   return cInvalidVector;
}

//==============================================================================
// getAmountBuildPlansInBase
//==============================================================================
int getAmountBuildPlansInBase(int buildingPUID = -1, int baseID = -1)
{
   int numBuildingsInBase = 0;
   int[] existingBuildPlans = aiPlanGetIDsByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, buildingPUID);
   for (int iPlan = 0; iPlan < existingBuildPlans.size(); iPlan++)
   {
      if (aiPlanGetBaseID(existingBuildPlans[iPlan]) == baseID)
      {
         numBuildingsInBase++;
      }
   }
   return numBuildingsInBase;
}

//==============================================================================
// getRandomTownCenterBaseID
//==============================================================================
int getRandomTownCenterBaseID()
{
   int numBases = kbBaseGetNumber(cMyID);
   int[] tcBases = new int(0, 0);
   for (int i = 0; i < numBases; i++)
   {
      int baseID = kbBaseGetIDByIndex(cMyID, i);
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
      {
         continue;
      }
      tcBases.add(baseID);
   }
   if (tcBases.size() == 0)
   {
      return -1;
   }
   else if (tcBases.size() == 1)
   {
      return tcBases[0];
   }
   int rand = xsRandInt(0, tcBases.size() - 1);
   return tcBases[rand];
}

//==============================================================================
// displayIntArray
//==============================================================================
void displayIntArray(ref int[] array)
{
   for (int i = 0; i < array.size(); i++)
   {
      aiEcho("" + array[i]);
   }
}

//==============================================================================
// getAgeName
//==============================================================================
string getAgeName(int age = -1)
{
   if (age == 0)
   {
      return "Archaic Age";
   }
   if (age == 1)
   {
      return "Classical Age";
   }
   if (age == 2)
   {
      return "Heroic Age";
   }
   if (age == 3)
   {
      return "Mythic Age";
   }
   if (age == 4)
   {
      return "Wonder Age";
   }
   return "getAgeName - invalid paramater of: " + age;
}

//==============================================================================
// getRemainingKOTHTime
//==============================================================================
int getRemainingKOTHTime()
{
   if (gKOTHStartTime == -1)
   {
      return cMaxInt;
   }
   return (gKOTHStartTime + gKOTHTotalTime) - xsGetTime();
}

//==============================================================================
// sendStatementToEverybody
//==============================================================================
void sendStatementToEverybody(int promptType = -1)
{
   debugChats("Sending prompt " + promptType + " to everybody.");
   for (int i = 1; i <= cNumberPlayers; i++)
   {
      if (i != cMyID)
      {
         aiCommsSendStatement(i, promptType);
      }
   }
}

//==============================================================================
// sendStatementToAllies
//==============================================================================
void sendStatementToAllies(int promptType = -1)
{
   debugChats("Sending prompt " + promptType + " to allies.");
   for (int i = 1; i <= cNumberPlayers; i++)
   {
      if (i != cMyID && kbPlayerIsAlly(i) == true && kbPlayerHasLost(i) == false)
      {
         aiCommsSendStatement(i, promptType);
      }
   }
}

//==============================================================================
// sendStatementToAlliesWithVector
//==============================================================================
void sendStatementToAlliesWithVector(int promptType = -1, vector position = cInvalidVector)
{
   debugChats("Sending prompt " + promptType + " to allies with vector " + position + ".");
   for (int i = 1; i <= cNumberPlayers; i++)
   {
      if (i != cMyID && kbPlayerIsAlly(i) == true && kbPlayerHasLost(i) == false)
      {
         aiCommsSendStatementWithVector(i, promptType, position);
      }
   }
}

//==============================================================================
// sendStatementToEnemies
//==============================================================================
void sendStatementToEnemies(int promptType = -1)
{
   debugChats("Sending prompt " + promptType + " to enemies.");
   for (int i = 1; i <= cNumberPlayers; i++)
   {
      if (i != cMyID && kbPlayerIsEnemy(i) == true && kbPlayerHasLost(i) == false)
      {
         aiCommsSendStatement(i, promptType);
      }
   }
}

//==============================================================================
// haveExcessResourceAmount
//==============================================================================
bool haveExcessResourceAmount(float excessThreshold = 0.0, int resourceType = cAllResources)
{
   if (excessThreshold < 0.0)
   {
      aiEchoWarning("haveExcessResourceAmount - excessTreshold can't be a negative value.");
      return false;
   }
   // If we have an excess of a resource then that's saved in gResourceNeeds as a negative value.
   switch (resourceType)
   {
      case cAllResources:
      {
         return gResourceNeeds[cResourceFood] < (-excessThreshold) &&
                gResourceNeeds[cResourceWood] < (-excessThreshold) &&
                gResourceNeeds[cResourceGold] < (-excessThreshold);
      }
      case cResourceFood:
      {
         return gResourceNeeds[cResourceFood] < (-excessThreshold);
      }
      case cResourceWood:
      {
         return gResourceNeeds[cResourceWood] < (-excessThreshold);
      }
      case cResourceGold:
      {
         return gResourceNeeds[cResourceGold] < (-excessThreshold);
      }
   }
   aiEchoWarning("haveExcessResourceAmount - Wrong resourceType input : " + resourceType + ".");
   return false;
}

//==============================================================================
// areAtMaxConcurrentResearchPlans
//==============================================================================
bool areAtMaxConcurrentResearchPlans(string caller = "ERROR")
{
   if (haveExcessResourceAmount(2000) == true)
   {
      debugTechs(caller + ", we have 2k excess resources across the board, allowed to research a tech regardless.");
      return false;
   }
   // Get how many research plans we have going on, excluding transformation/heroization plans.
   int[] plans = aiPlanGetIDsByTypeAndVariableBoolValue(cPlanResearch, cResearchPlanIsProtoUnitCommand, false);
   int numPlans = plans.size();
   // Age up is a permament plan, have 2 concurrent research plans outside of that.
   int limit = 3;
   if (kbPlayerGetAge(cMyID) >= cAge4)
   {
      limit = 2;
   }
   if (numPlans >= limit)
   {
      debugTechs(caller + ", can't research a technology because we're at our global limit.");
      return true;
   }
   debugTechs(caller + ", allowed to research a technology, not at our global limit.");
   return false;
}

//==============================================================================
// addSafeBackAreasToBuildingPlacement
//==============================================================================
bool addSafeBackAreasToBuildingPlacement(int bpID = -1, int baseID = -1, bool godPowerCall = false)
{
   vector basePosition = kbBaseGetLocation(cMyID, baseID);
   int baseAreaID = kbAreaGetIDByPosition(basePosition);
   vector backVector = kbBaseGetBackVector(cMyID, baseID);
   int backAreaID = -1;
   for (int i = 4; i < 10; i++)
   {
      vector newPos = basePosition + (backVector * (i * 5));
      if (kbGetIsLocationOnMap(newPos) == false)
      {
         break;
      }
      int newAreaID = kbAreaGetIDByPosition(newPos);
      if (newAreaID != baseAreaID)
      {
         backAreaID = newAreaID;
         break;
      }
   }
   // Failed to find a back area, very rare case with edge of the map.
   if (backAreaID == -1)
   {
      if (godPowerCall == false)
      {
         debugBuildings("addSafeBackAreasToBuildingPlacement - Found no back area to orient ourselves around.");
      }
      else
      {
         debugGodPowers("addSafeBackAreasToBuildingPlacement - Found no back area to orient ourselves around.");
      }
      kbBuildingPlacementSetBaseID(bpID, baseID, cBuildingPlacementOrientationPreferenceBack);
      return false;
   }

   if (godPowerCall == false)
   {
      debugBuildings("Added backAreaID: " + backAreaID + " to the safe back area placement.");
   }
   else
   {
      debugGodPowers("Added backAreaID: " + backAreaID + " to the safe back area placement.");
   }
   kbBuildingPlacementAddAreaID(bpID, backAreaID, 0, false);
   vector backAreaPosition = kbAreaGetCenter(backAreaID);
   int[] areaIDs = new int(0, -1);
   areaIDs.add(backAreaID);
   for (int i = 0; i < kbAreaGetNumberBorderAreas(backAreaID); i++)
   {
      int borderAreaID = kbAreaGetBorderAreaID(backAreaID, i);
      for (int j = 0; j < kbAreaGetNumberBorderAreas(borderAreaID); j++)
      {
         int secondBorderAreaID = kbAreaGetBorderAreaID(borderAreaID, j);
         if (kbAreaGetDangerLevel(secondBorderAreaID) < 100.0 &&
             isAreaPassableByLand(secondBorderAreaID) == true &&
             xsVectorDistanceXZSqr(backAreaPosition, kbAreaGetCenter(secondBorderAreaID)) < 50.0 * 50.0 &&
             areaIDs.find(secondBorderAreaID) == -1)
         {
            areaIDs.add(secondBorderAreaID);
            if (godPowerCall == false)
            {
               debugBuildings("Added areaID: " + secondBorderAreaID + " to the safe back area placement.");
            }
            else
            {
               debugGodPowers("Added areaID: " + secondBorderAreaID + " to the safe back area placement.");
            }
            kbBuildingPlacementAddAreaID(bpID, secondBorderAreaID, 0, false);
         }
      }
   }
   kbBuildingPlacementAddPositionInfluence(bpID, basePosition, 500.0, 150.0, cFalloffLinear);
   kbBuildingPlacementAddPositionInfluence(bpID, backAreaPosition, 1000.0, 150.0, cFalloffLinear);
   return true;
}

//==============================================================================
// getMostDefendedTCBase
//==============================================================================
int getMostDefendedTCBase()
{
   int numBases = kbBaseGetNumber(cMyID);
   int safestBaseID = -1;
   float safestBaseRating = cMinFloat;

   for (int i = 0; i < numBases; i++)
   {
      int baseID = kbBaseGetIDByIndex(cMyID, i);
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
      {
         continue;
      }
      float defenseRating = kbBaseGetDefenseRating(cMyID, baseID);
      if (defenseRating > safestBaseRating)
      {
         safestBaseRating = defenseRating;
         safestBaseID = baseID;
      }
   }
   return safestBaseID;
}

//==============================================================================
// getLeastDefendedTCBase
//==============================================================================
int getLeastDefendedTCBase()
{
   int numBases = kbBaseGetNumber(cMyID);
   int unsafestBaseID = -1;
   float unsafestBaseRating = cMaxFloat;

   for (int i = 0; i < numBases; i++)
   {
      int baseID = kbBaseGetIDByIndex(cMyID, i);
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
      {
         continue;
      }
      float defenseRating = kbBaseGetDefenseRating(cMyID, baseID);
      if (defenseRating < unsafestBaseRating)
      {
         unsafestBaseRating = defenseRating;
         unsafestBaseID = baseID;
      }
   }
   return unsafestBaseID;
}

//==============================================================================
// getClosestTCBase
//==============================================================================
int getClosestTCBase(vector position = cInvalidVector)
{
   int numBases = kbBaseGetNumber(cMyID);
   int closestBaseID = -1;
   float closestBaseDistance = cMaxFloat;

   for (int i = 0; i < numBases; i++)
   {
      int baseID = kbBaseGetIDByIndex(cMyID, i);
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
      {
         continue;
      }
      float distance = xsVectorDistanceSqr(position, kbBaseGetLocation(cMyID, baseID));
      if (distance < closestBaseDistance)
      {
         closestBaseDistance = distance;
         closestBaseID = baseID;
      }
   }
   return closestBaseID;
}
