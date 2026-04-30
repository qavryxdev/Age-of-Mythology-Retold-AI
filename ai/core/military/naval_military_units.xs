//==============================================================================
/* naval_military_units.xs

   This file is intended for naval military unit training.

*/
//==============================================================================

//==============================================================================
// trainNavalMythUnit
//==============================================================================
void trainNavalMythUnit()
{
   // We only want 1 naval myth unit at a time, quit if we find one.
   int[] enabledMythUnits = getAllEnabledMilitaryMythUnits(cUnitTypeDock);
   int num = enabledMythUnits.size();
   if (num == 0)
   {
      return;
   }

   int currentAmount = 0;
   for (int i = 0; i < num; i++)
   {
      int mythPUID = enabledMythUnits[i];
      debugNavalMilitaryTraining("trainNavalMythUnit - analyzing mythPUID: " + kbProtoUnitGetName(mythPUID));
      currentAmount += kbUnitCount(mythPUID, cMyID, cUnitStateABQ);
      int[] planIDs = aiPlanGetIDsByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, mythPUID);
      for (int j = 0; j < planIDs.size(); j++)
      {
         int toTrain = aiPlanGetVariableInt(planIDs[j], cTrainPlanNumberToTrain, 0) -
                       aiPlanGetVariableInt(planIDs[j], cTrainPlanNumberTrained, 0);
         currentAmount += toTrain;
      }
   }
   debugNavalMilitaryTraining("trainNavalMythUnit - currentAmount: " + currentAmount);
   if (currentAmount >= 1)
   {
      debugNavalMilitaryTraining("We already have a naval myth unit, don't try to train more.");
      return;
   }

   int index = 0;
   if (num > 1)
   {
      index = xsRandInt(0, num -1);
   }
   int puid = enabledMythUnits[index];
   createSimpleTrainPlan(puid, 1);
   debugMilitaryTraining("Created a train plan for 1 " + kbProtoUnitGetName(puid) + ".");
}

//==============================================================================
// adjustNavalMaintainPlans
//==============================================================================
void adjustNavalMaintainPlans(int archerShipMaintain = 0, int closeCombatShipMaintain = 0,
   int siegeShipMaintain = 0)
{
   debugNavalMilitaryTraining("Setting our naval maintain plans to: ");
   int originalMaintainArcherShip = aiPlanGetVariableInt(gNavalUnitMaintainPlans[0], cTrainPlanNumberToMaintain, 0);
   int originalMaintainCloseCombatShip = aiPlanGetVariableInt(gNavalUnitMaintainPlans[1], cTrainPlanNumberToMaintain, 0);
   int originalMaintainSiegeShip = aiPlanGetVariableInt(gNavalUnitMaintainPlans[2], cTrainPlanNumberToMaintain, 0);
   for (int i = 0; i < cNumWarships; i++)
   {
      int planID = gNavalUnitMaintainPlans[i];
      if (aiPlanGetIsIDValid(planID) == true)
      {
         switch (i)
         {
            case 0:
            {
               if (originalMaintainArcherShip == archerShipMaintain)
               {
                  debugNavalMilitaryTraining("Existing maintain plan for " + kbProtoUnitGetName(gArcherShip) +
                     " doesn't require changes. Current amount: " + archerShipMaintain + ".");
               }
               else
               {
                  aiPlanSetName(planID, planID + ": Naval military maintain: " + archerShipMaintain + " " + kbProtoUnitGetName(gArcherShip));
                  debugNavalMilitaryTraining("Adjusting " + kbProtoUnitGetName(gArcherShip) + " plan to maintain: " + archerShipMaintain + ".");
                  aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, archerShipMaintain);
               }
               break;
            }
            case 1:
            {
               if (originalMaintainCloseCombatShip == closeCombatShipMaintain)
               {
                  debugNavalMilitaryTraining("Existing maintain plan for " + kbProtoUnitGetName(gCloseCombatShip) +
                     " doesn't require changes. Current amount: " + closeCombatShipMaintain + ".");
               }
               else
               {
                  aiPlanSetName(planID, planID + ": Naval military maintain: " + closeCombatShipMaintain + " " + kbProtoUnitGetName(gCloseCombatShip));
                  debugNavalMilitaryTraining("Adjusting " + kbProtoUnitGetName(gCloseCombatShip) + " plan to maintain: " + closeCombatShipMaintain + ".");
                  aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, closeCombatShipMaintain);
               }
               break;
            }
            case 2:
            {
               if (originalMaintainSiegeShip == siegeShipMaintain)
               {
                  debugNavalMilitaryTraining("Existing maintain plan for " + kbProtoUnitGetName(gSiegeShip) +
                     " doesn't require changes. Current amount: " + siegeShipMaintain + ".");
               }
               else
               {
                  aiPlanSetName(planID, planID + ": Naval military maintain: " + siegeShipMaintain + " " + kbProtoUnitGetName(gSiegeShip));
                  debugNavalMilitaryTraining("Adjusting " + kbProtoUnitGetName(gSiegeShip) + " plan to maintain: " + siegeShipMaintain + ".");
                  aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, siegeShipMaintain);
               }
               break;
            }
         }
      }
   }
}

//==============================================================================
// setupNavalUnitPicker
//==============================================================================
void setupNavalUnitPicker(int upID = -1, int targetPlayer = -1)
{
   kbUnitPickResetAll(upID);
   kbUnitPickSetMinimumCounterModePop(upID, 10);
   kbUnitPickSetEnemyPlayerID(upID, targetPlayer);

   // We want to analyze all our war ships.
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractWarship, 0.5);
   // Exclude The Argo.
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeTheArgo, 0.0);

   // Combat efficiency is twice as important as our preferences.
   kbUnitPickSetPreferenceWeight(upID, 1.0);
   kbUnitPickSetCombatEfficiencyWeight(upID, 2.0);

   // Default to scanning for enemy naval military.
   kbUnitPickSetAttackUnitType(upID, cUnitTypeLogicalTypeNavalMilitary);

   // Our ships should be able to move over water.
   kbUnitPickSetMovementType(upID, cPassabilityWater);

   // Set the default target types and weights, for use until we've seen enough actual units.
   kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeLogicalTypeNavalMilitary, 1.0);
}

//==============================================================================
// calculateNavalMilitaryPopAndTargetPlayer
//==============================================================================
void calculateNavalMilitaryPopAndTargetPlayer(ref int targetPlayer, ref int maxNavalMilitaryPop)
{
   // Updating of naval military pop to have realistic maintain numbers.
   int maxPop = 0;
   int villagerCount = kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive);
   if (cMyCulture == cCultureAtlantean)
   {
      maxPop = villagerCount * 1.5;
   }
   else
   {
      maxPop = villagerCount;
   }

   // Clamp our number determined by Villagers to a difficulty specific max number.
   maxPop = min(maxPop, selectByDifficulty(5, 10, 15, 25, 40, 50));

   int enemyWarshipPop = 0;
   if (targetPlayer == cScoutingForEnemies)
   {
      // If we're here we have no valid enemy but we still want to train ships.
      // We're going to base everything off enemy military naval units that we do have scouted.
      // We will also adjust targetPlayer during the process for our unitPicker to use.
      int queryID = useSimpleUnitQuery(cUnitTypeLogicalTypeNavalMilitary, cPlayerRelationEnemyNotGaia, cUnitStateAlive);
      kbUnitQueryExecute(queryID);
      enemyWarshipPop = kbUnitQueryGetPopulationSlots(queryID);
      int numEnemies = getNumberEnemies();
      if (numEnemies == 1)
      {
         targetPlayer = getRandomEnemyID();
         debugNavalMilitaryTraining("There is only one enemy in the game currently so we will target him for the unitPicker.");
      }
      else if (enemyWarshipPop < 10)
      {
         // There is nothing to counter and we don't need to figure out a weighted enemyWarshipPop either, just move on.
         targetPlayer = -1;
         debugNavalMilitaryTraining("The enemies have too few combined naval military pop that we've scouted, use -1 for the unitPicker.");
      }
      else
      {
         // Figure out who we are going to counter and with how much pop.
         int[] enemyNaval = kbUnitQueryGetResults(queryID);
         int[] enemyPlayerIDs = new int(0, 0);
         int[] enemyCounts = new int(0, 0);
         for (int i = 0; i < enemyNaval.size(); i++)
         {
            int unitID = enemyNaval[i];
            int playerID = kbUnitGetPlayerID(unitID);
            int index = enemyPlayerIDs.find(playerID);
            if (index == -1)
            {
               enemyPlayerIDs.add(playerID);
               enemyCounts.add(1);
            }
            else
            {
               int temp = enemyCounts[index];
               enemyCounts[index] = temp + 1;
            }
         }
         int highestAmount = 0;
         for (int i = 0; i < enemyPlayerIDs.size(); i++)
         {
            if (enemyCounts[i] > highestAmount)
            {
               highestAmount = enemyCounts[i];
               targetPlayer = enemyPlayerIDs[i];
            }
         }
         enemyWarshipPop /= numEnemies; // We calculate using an average per player.
         debugNavalMilitaryTraining("We have queried over all scouted enemy naval military and an average enemy navy pop size " +
            "seems to be: " + enemyWarshipPop + ".");
         debugNavalMilitaryTraining("Player " + targetPlayer + " has the biggest scouted navy, we will use him for our unit picker.");
      }
   }
   else
   {
      int queryID = useSimpleUnitQuery(cUnitTypeLogicalTypeNavalMilitary, targetPlayer, cUnitStateAlive);
      kbUnitQueryExecute(queryID);
      enemyWarshipPop = kbUnitQueryGetPopulationSlots(queryID);
      debugNavalMilitaryTraining("Using our targetPlayer: " + targetPlayer + " to query for enemy naval military pop and found: " +
         enemyWarshipPop + ".");
   }

   enemyWarshipPop += 5; // We always want to train more ships than the enemy, but just by a little bit, be reactive.
   if (enemyWarshipPop < maxPop)
   {
      maxPop = enemyWarshipPop;
      debugNavalMilitaryTraining("We've scouted fewer enemy naval military than our allowed maximum, reducing to match.");
   }

   maxNavalMilitaryPop = maxPop;
   debugNavalMilitaryTraining("Setting naval military pop to: " + maxNavalMilitaryPop);
   aiSetNavalMilitaryPop(maxNavalMilitaryPop);
}

//==============================================================================
// navalMilitaryManager
//==============================================================================
rule navalMilitaryManager
inactive
group defaultClassicalRules
minInterval 30
{
   if (checkStrategyFlag(cStrategyFlagAutomaticNavalGameplay) == false)
   {
      // Destroy all plans...
      for (int i = 0; i < cNumWarships; i++)
      {
         int planID = gNavalUnitMaintainPlans[i];
         if (aiPlanGetIsIDValid(planID) == true)
         {
            aiPlanDestroy(planID);
            gNavalUnitMaintainPlans[i] = -1;
         }
      }
      return;
   }
   if (gMapInfo.mHasWater == false)
   {
      xsDisableRule("navalMilitaryManager");
      return;
   }
   if (gMapInfo.mShouldBuildDock == false)
   {
      // Destroy all plans...
      for (int i = 0; i < cNumWarships; i++)
      {
         int planID = gNavalUnitMaintainPlans[i];
         if (aiPlanGetIsIDValid(planID) == true)
         {
            aiPlanDestroy(planID);
            gNavalUnitMaintainPlans[i] = -1;
         }
      }
      return;
   }
   debugNavalMilitaryTraining("--- Running Rule navalMilitaryManager. ---");



   debugNavalMilitaryTraining("Current maintain plans:");
   for (int i = 0; i < cNumWarships; i++)
   {
      int planID = gNavalUnitMaintainPlans[i];
      if (aiPlanGetIsIDValid(planID) == true)
      {
         debugNavalMilitaryTraining("   " + aiPlanGetName(planID));
      }
      else
      {
         int unitType = -1;
         switch (i)
         {
            case 0:
            {
               unitType = gArcherShip;
               break;
            }
            case 1:
            {
               unitType = gCloseCombatShip;
               break;
            }
            case 2:
            {
               unitType = gSiegeShip;
               break;
            }
         }
         planID = aiPlanCreate("Naval military maintain: " + kbProtoUnitGetName(unitType), cPlanTrain, -1,
            gNavalMilitaryTrainingCategoryID);
         aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, unitType);
         aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, 0);
         debugNavalMilitaryTraining("   Creating maintain plan for " + kbProtoUnitGetName(unitType) + ".");
         gNavalUnitMaintainPlans[i] = planID;
      }
   }

   if (kbUnitGetIsIDValid(getUnit(cUnitTypeDock)) == false)
   {
      adjustNavalMaintainPlans(); // Calling it like this resets them all to 0 maintain.
      return;
   }

   // Obviously if we have no enemy we don't need any naval military.
   // If we're in serious trouble in our main base we halt all naval production, land > water.
   int targetPlayer = aiGetMostHatedNavalPlayerID();
   if (targetPlayer == cNoEnemies || gDefenseReflexPanic == true)
   {
      adjustNavalMaintainPlans(); // Calling it like this resets them all to 0 maintain.
      return;
   }
   
   int maxNavalMilitaryPop = 0;
   if (gOverrideNavalMaxMilitaryPop >= cUnlimitedNavalMilitaryPop)
   {
      maxNavalMilitaryPop = gOverrideNavalMaxMilitaryPop;
      aiSetNavalMilitaryPop(maxNavalMilitaryPop);
      debugMilitaryTraining("Override - Setting our naval military pop to: " + gOverrideNavalMaxMilitaryPop + ", -1 means unlimited.");
   }
   else
   {
      calculateNavalMilitaryPopAndTargetPlayer(targetPlayer, maxNavalMilitaryPop);
   }
   
   // 20% Chance that we try to train a myth unit.
   if (xsRandInt(0, 99) <= 20)
   {
      debugNavalMilitaryTraining("We've randomly decided to try and train 1 naval myth unit!");
      trainNavalMythUnit();
   }

   static int navalUnitPicker = -1;
   if (kbUnitPickGetIsIDValid(navalUnitPicker) == false)
   {
      navalUnitPicker = kbUnitPickCreate("Naval military units");
   }

   // Update preferences in case something changed inbetween.
   setupNavalUnitPicker(navalUnitPicker, targetPlayer);
   kbUnitPickRun(navalUnitPicker);

   float totalFactor = 0.0;
   for (int i = 0; i < cNumWarships; i++)
   {
      totalFactor += kbUnitPickGetResultFactor(navalUnitPicker, i);
      int puid = kbUnitPickGetResult(navalUnitPicker, i);
      if (puid != gArcherShip && puid != gCloseCombatShip && puid != gSiegeShip)
      {
         aiEchoWarning("Our naval unit picker returned a puid that doesn't match with our function units???");
         continue;
      }
   }

   int numArcherShipMaintain = 0;
   int numCloseCombatShipMaintain = 0;
   int numSiegeShipMaintain = 0;
   for (int i = 0; i < cNumWarships; i++)
   {
      int puid = kbUnitPickGetResult(navalUnitPicker, i);
      // We round all of these numbers because otherwise we often end up with far fewer ships than we want due to
      // the combination of high pop costs + low amount of available pop.
      if (puid == gArcherShip)
      {
         int popCount = kbPlayerGetProtoStatInt(cMyID, puid, cProtoStatPopCost);
         numArcherShipMaintain = round((kbUnitPickGetResultFactor(navalUnitPicker, i) / totalFactor) * maxNavalMilitaryPop / popCount);
         if (numArcherShipMaintain < 1)
         {
            numArcherShipMaintain = 1;
         }
      }
      else if (puid == gCloseCombatShip)
      {
         int popCount = kbPlayerGetProtoStatInt(cMyID, puid, cProtoStatPopCost);
         numCloseCombatShipMaintain = round((kbUnitPickGetResultFactor(navalUnitPicker, i) / totalFactor) * maxNavalMilitaryPop / popCount);
         if (numCloseCombatShipMaintain < 1)
         {
            numCloseCombatShipMaintain = 1;
         }
      }
      else
      {
         int popCount = kbPlayerGetProtoStatInt(cMyID, puid, cProtoStatPopCost);
         numSiegeShipMaintain = round((kbUnitPickGetResultFactor(navalUnitPicker, i) / totalFactor) * maxNavalMilitaryPop / popCount);
         if (numSiegeShipMaintain < 1)
         {
            numSiegeShipMaintain = 1;
         }
      }
   }
   adjustNavalMaintainPlans(numArcherShipMaintain, numCloseCombatShipMaintain, numSiegeShipMaintain);
}