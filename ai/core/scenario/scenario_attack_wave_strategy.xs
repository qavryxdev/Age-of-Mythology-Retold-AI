void attackWaveDefaultCallback(int planID = -1) {}
extern const int cWaitWithAttacking = 9999999;

class AttackWave
{
   // Used for output to identify the wave.
   string mName = "MISSING";
   void setName(string newName = "ERROR") { mName = newName; }

   // Information about the actual attack waves.
   int mAttackInterval = 60;
   int mLastAttackTime = -10000;
   int mAttackRouteID = -1;
   float mAttackSize = 10.0;
   int mLastAttackPlan = -1;
   float mAttackSizeMultiplier = 1.0;
   float mMaxAttackSize = 20.0;
   float mMinAttackSize = 0.0;
   vector mGatherPoint = cInvalidVector;
   vector mTargetPoint = cInvalidVector;
   int mPlayerToAttack = 1;
   void(int) mWaveStartCallback = attackWaveDefaultCallback;
   int[] mAttackUnitTypes = default;

   // State tracking.
   bool mIsScouting = false;
   bool mIsNaval = false;

   // Scout plan tracking.
   int[] mScoutPlans = default;
   int mScoutPlanUpdateTimer = -1;

   // Debug messages.
   int mNoTargetsFoundSpam = 0;
   int mNotEnoughUnitsAddedSpam = 0;

   void displayFirstAttackStats()
   {
      debugAttackWave(mName + ": First attack minimum size: " + xsFloatToInt(mMinAttackSize));
      debugAttackWave(mName + ": First attack wanted size: " + xsFloatToInt(mAttackSize));
      debugAttackWave(mName + ": First attack max size: " + xsFloatToInt(mMaxAttackSize));
      if (mLastAttackTime > 999999)
      {
         debugAttackWave(mName + ": First attack wave is indefinitely delayed until other mechanism activate it.");
      }
      else
      {
         debugAttackWave(mName + ": First attack time: " + turnNumberIntoTimeDisplay(mLastAttackTime + mAttackInterval));
      }
   }
   
   // Setters.
   void setAttackStartTime(int v = 0) { mLastAttackTime = xsGetTime() - mAttackInterval + v; }
   void setAttackInterval(int v = 60)
   {
      mLastAttackTime += mAttackInterval;
      mAttackInterval = v;
      mLastAttackTime -= v;
   }
   void setAttackSize(float v = 10.0) 
   {
      mAttackSize = v;
      // This func also automatically sets the min size since we just always want that basically. But keep the override func alive.
      mMinAttackSize = v;
   }
   void setAttackSizeMultiplier(float v = 1.0) { mAttackSizeMultiplier = v; }
   void setMaxAttackSize(float v = 20.0) { mMaxAttackSize = v; }
   void setMinAttackSize(float v = 10.0) { mMinAttackSize = v; }
   void setGatherPoint(vector v = cInvalidVector) { mGatherPoint = v; }
   void setTargetPoint(vector v = cInvalidVector) { mTargetPoint = v; }
   void setPlayerToAttack(int v = 1) { mPlayerToAttack = v; }
   void setAttackRouteID(int v = -1) { mAttackRouteID = v; }
   void setWaveStartCallback(void(int) v = attackWaveDefaultCallback) { mWaveStartCallback = v; }
   void setIsNavalAttackWave() { mIsNaval = true; }
   
   void addAttackUnitType(int puid = -1)
   {
      if (puid < 0 || puid >= cNumberProtoUnits)
      {
         aiEchoWarning(mName + ": Invalid puid " + puid + " as input for addAttackUnitType.");
         return;
      }
      mAttackUnitTypes.add(puid);
   }

   void removeAttackUnitType(int puid = -1)
   {
      if (mAttackUnitTypes.removeValue(puid) == false)
      {
         aiEchoWarning(mName + ": Trying to remove puid " + puid + " from the attack unit types but it was never in there.");
      }
   }

   //==============================================================================
   // findUnitsToAddToPlan
   //==============================================================================
   int findUnitsToAddToPlan(ref int[] unitsAdded)
   {
      // Prevent duplicate unit queries and track a num.
      static int num = 0;
      int[] unitQueries = new int(mAttackUnitTypes.size(), -1);
      int[] unitQueryNums = new int(mAttackUnitTypes.size(), -1);
      int numProcessedQueries = 0;
      for (int i = 0; i < mAttackUnitTypes.size(); i++)
      {
         int queryID = kbUnitQueryCreate(num + " attackWaveQuery: " + kbProtoUnitGetName(mAttackUnitTypes[i]));
         num++;
         kbUnitQuerySetPlayerID(queryID, cMyID);
         kbUnitQuerySetUnitType(queryID, mAttackUnitTypes[i]);
         kbUnitQuerySetState(queryID, cUnitStateAlive);
         int queryNum = kbUnitQueryExecute(queryID);
         if (queryNum == 0)
         {
            // This query has been "processed" already since there is nothing.
            numProcessedQueries++;
         }
         unitQueries[i] = queryID;
         unitQueryNums[i] = queryNum;
      }

      int numRemaining = mAttackSize;
      while (numRemaining > 0)
      {
         for (int i = 0; i < mAttackUnitTypes.size(); i++)
         {
            int queryID = unitQueries[i];
            while (unitQueryNums[i] > 0)
            {
               int unitID = kbUnitQueryGetResult(queryID, unitQueryNums[i] - 1);
               int unitPlanID = kbUnitGetPlanID(unitID);
               int queryNum = unitQueryNums[i] - 1;
               // No units left after this iteration? Then this query has been processed fully now.
               if (queryNum == 0)
               {
                  numProcessedQueries++;
               }
               unitQueryNums[i] = queryNum;
               if (aiPlanGetIsIDValid(unitPlanID) == true)
               {
                  if (aiPlanIsFlagSet(unitPlanID, cPlanFlagCantBeStolenFrom) == true)
                  {
                     continue;
                  }
                  // Dont steal from a child reinforce plan that belongs to another attack wave.
                  int parentPlanID = aiPlanGetParentID(unitPlanID);
                  if (parentPlanID != -1 && aiPlanGetType(unitPlanID) == cPlanAttack && aiPlanGetType(parentPlanID) == cPlanAttack)
                  {
                     continue;
                  }
               }

               unitsAdded.add(unitID);
               numRemaining--;
               break;
            }
            if (numRemaining == 0)
            {
               break;
            }
         }
         if (numProcessedQueries == mAttackUnitTypes.size())
         {
            break;
         }
      }

      for (int i = 0; i < unitQueries.size(); i++)
      {
         kbUnitQueryDestroy(unitQueries[i]);
      }
      return numRemaining;
   }

   //==============================================================================
   // updateExplorePlans
   //==============================================================================
   void updateExplorePlans()
   {
      mScoutPlanUpdateTimer++;
      if (mScoutPlanUpdateTimer != 0)
      {
         // Reset, only do this every 20 seconds.
         if (mScoutPlanUpdateTimer == 19)
         {
            mScoutPlanUpdateTimer = -1;
         }
         return;
      }
      if (mScoutPlans.size() == 0)
      {
         mScoutPlans = new int(3, -1);
      }
      int ownAreaGroupID = kbAreaGroupGetIDByPosition(mGatherPoint);
      // 3 Plans.
      for (int i = 0; i < 3; i++)
      {
         if (aiPlanGetIsIDValid(mScoutPlans[i]) == true)
         {
            // We create the explore plans but for scenarios we have no idea what units we can assign to it, so we let
            // auto assignment do it. But how explore plan combat works we can't have new units join these plans really...
            // So if a plan is valid and already has at least 1 unit, set the flag.
            if (aiPlanGetNumberUnits(mScoutPlans[i]) != 0)
            {
               aiPlanSetFlag(mScoutPlans[i], cPlanFlagNoMoreUnits, true);
               continue;
            }
            else
            {
               // No units, destroy.
               aiPlanDestroy(mScoutPlans[i]);
            }
         }
         // Create explore plans.
         int planID = aiPlanCreate("Attack Wave Explore: " + i, cPlanExplore, -1, gExplorationCategoryID);
         debugAttackWave(mName + ": Created new land army explore plan: " + aiPlanGetName(planID) + ".");

         // Explore other islands if we need to.
         if (gMapInfo.mStartOnDifferentIslands == true)
         {
            int numAreaGroups = kbAreaGroupGetNumber();
            int[] areaGroupsToExplore = new int(0, -1);
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
               areaGroupsToExplore.add(iGroup);
            }
            aiPlanSetNumberVariableValues(planID, cExplorePlanExploreAreaGroupIDs, areaGroupsToExplore.size(), true);
            for (int iGroup = 0; iGroup < areaGroupsToExplore.size(); iGroup++)
            {
   	         aiPlanSetVariableInt(planID, cExplorePlanExploreAreaGroupIDs, iGroup, areaGroupsToExplore[iGroup]);
            }
         }

         // Add the unit types equal to what our attack wave would use.
         for (int iUnitType = 0; iUnitType < mAttackUnitTypes.size(); iUnitType++)
         {
            aiPlanAddUnitType(planID, mAttackUnitTypes[iUnitType], 1, 1, 1);
         }

         aiPlanSetVariableBool(planID, cExplorePlanAggressiveScouts, 0, true);
         setDefaultExplorePlanTargetUnitTypes(planID);

         aiPlanSetPriority(planID, 99);
         // Don't take away scouts.
         aiPlanSetFlag(planID, cPlanFlagCantBeStolenFrom, true);
         mScoutPlans[i] = planID;
      }
   }

   //==============================================================================
   // updateExplorePlansNaval
   //==============================================================================
   void updateExplorePlansNaval()
   {
      mScoutPlanUpdateTimer++;
      if (mScoutPlanUpdateTimer != 0)
      {
         // Reset, only do this every 20 seconds.
         if (mScoutPlanUpdateTimer == 19)
         {
            mScoutPlanUpdateTimer = -1;
         }
         return;
      }
      if (mScoutPlans.size() == 0)
      {
         mScoutPlans = new int(3, -1);
      }

      // 3 Plans.
      for (int i = 0; i < 3; i++)
      {
         if (aiPlanGetIsIDValid(mScoutPlans[i]) == true)
         {
            // We create the explore plans but for scenarios we have no idea what units we can assign to it, so we let
            // auto assignment do it. But how explore plan combat works we can't have new units join these plans really...
            // So if a plan is valid and already has at least 1 unit, set the flag.
            if (aiPlanGetNumberUnits(mScoutPlans[i]) != 0)
            {
               aiPlanSetFlag(mScoutPlans[i], cPlanFlagNoMoreUnits, true);
               continue;
            }
            else
            {
               // No units, destroy.
               aiPlanDestroy(mScoutPlans[i]);
            }
         }

         // Create explore plans.
         int planID = aiPlanCreate("Naval Attack Wave Explore: " + i, cPlanExplore, -1, gExplorationCategoryID);
         debugAttackWave(mName + ": Created new naval army explore plan: " + aiPlanGetName(planID) + ".");

         // Add the unit types equal to what our attack wave would use.
         for (int iUnitType = 0; iUnitType < mAttackUnitTypes.size(); iUnitType++)
         {
            aiPlanAddUnitType(planID, mAttackUnitTypes[iUnitType], 1, 1, 1);
         }

         aiPlanSetVariableBool(planID, cExplorePlanAggressiveScouts, 0, true);
         setDefaultExplorePlanTargetUnitTypes(planID);
         aiPlanSetInitialPosition(planID, mGatherPoint);

         aiPlanSetPriority(planID, 99);
         // Don't take away scouts.
         aiPlanSetFlag(planID, cPlanFlagCantBeStolenFrom, true);
         mScoutPlans[i] = planID;
      }
   }

   //==============================================================================
   // destroyScoutPlans
   //==============================================================================
   void destroyScoutPlans()
   {
      debugAttackWave(mName + ": Destroying scout plans because we either found a base or units to attack instead.");
      for (int i = mScoutPlans.size() - 1; i >= 0; i--)
      {
         if (aiPlanGetIsIDValid(mScoutPlans[i]) == true)
         {
            aiPlanDestroy(mScoutPlans[i]);
         }
      }
      mScoutPlans.clear();
   }

   //==============================================================================
   // attackWaveCreateUnitAttackPlan
   //==============================================================================
   int attackWaveCreateUnitAttackPlan()
   {
      // See if we have enough units to actually attack.
      int[] addUnits = new int(0, 0);
      // numRemaining is the number of units we couldn't add compared to our mAttackSize.
      // So if mAttackSize is 20 and we only found 15 units then numRemaining is 5.
      int numRemaining = findUnitsToAddToPlan(addUnits);

      // We added 0 units, to prevent our plan from being stuck we must delete it, guards against 0 minAttackSize attacks.
      if (numRemaining == mAttackSize)
      {
         if (mNotEnoughUnitsAddedSpam % 10 == 0)
         {
            debugAttackWave(mName + ": We found 0 units to add to the attack wave, delaying it.");
         }
         mNotEnoughUnitsAddedSpam++;
         return -1;
      }

      // If we didn't add enough units we must delete it too.
      if (xsFloatToInt(mAttackSize) - numRemaining < xsFloatToInt(mMinAttackSize))
      {
         if (mNotEnoughUnitsAddedSpam % 10 == 0)
         {
            debugAttackWave(mName + ": We added too few units to the attack wave: " + (xsFloatToInt(mAttackSize) - numRemaining) + "/" +
               xsFloatToInt(mMinAttackSize) + ", delaying it.");
         }
         mNotEnoughUnitsAddedSpam++;
         return -1;
      }
      mNotEnoughUnitsAddedSpam = 0;

      int planID = aiPlanCreate("Attack Wave: Attacking Units", cPlanAttack, -1, mIsNaval == true ? gNavalMilitaryCategoryID :
         gMilitaryAttackingCategoryID);

      for (int i = 0; i < addUnits.size(); i++)
      {
         aiPlanAddUnitType(planID, kbUnitGetProtoUnitID(addUnits[i]), 1, 1, 1, true);
         aiPlanAddUnit(planID, addUnits[i]);
      }

      aiPlanSetVariableInt(planID, cAttackPlanTargetMode, 0, cAttackPlanTargetModePoint);
      aiPlanSetVariableInt(planID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeNoTarget);
      if (mIsNaval == true)
      {
         aiPlanSetVariableInt(planID, cAttackPlanMovementTypeFlags, 0, cPassabilityWater);
      }
      else
      {
         aiPlanSetVariableInt(planID, cAttackPlanMovementTypeFlags, 0, cPassabilityLand | cPassabilityWater);
      }
      aiPlanSetVariableVector(planID, cAttackPlanGatherPoint, 0, mGatherPoint);
      aiPlanSetVariableInt(planID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
      setDefaultAttackPlanTargetUnitTypes(planID);

      // We want our units to clump up before sending out the attack.
      // We try to group everybody to within 15 range from the gather point. (after that the move command clumps them properly)
      // If all the units haven't reached this spot after 60 seconds we go ahead anyway.
      aiPlanSetVariableFloat(planID, cAttackPlanGatherDistance, 0, 15.0);
      aiPlanSetVariableInt(planID, cAttackPlanGatherWaitTime, 0, 60 * 1000);
      
      int numResults = 0;
      int[] results = new int(0, 0);

      if (mIsNaval == true)
      {
         static int queryID = -1;
         if (queryID == -1)
         {
            queryID = kbUnitQueryCreate("Attack Wave Target Units");
            kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
            kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateRecentPositionKnown);
            kbUnitQuerySetUnitType(queryID, cUnitTypeNavalUnit);
            kbUnitQuerySetState(queryID, cUnitStateAlive);
         }
         // Reset since this could change.
         kbUnitQuerySetAreaGroupID(queryID, kbAreaGroupGetIDByPosition(mTargetPoint));
         kbUnitQueryResetResults(queryID);
         numResults = kbUnitQueryExecute(queryID);
         results = kbUnitQueryGetResults(queryID);
      }
      else
      {
         int queryID = useSimpleUnitQuery(cUnitTypeLogicalTypeNeededForVictory, mPlayerToAttack, cUnitStateAlive);
         int[] excludeTypes = new int(1, cUnitTypeNavalUnit);
         kbUnitQuerySetExcludeTypes(queryID, excludeTypes);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateRecentPositionKnown);
         numResults = kbUnitQueryExecute(queryID);
         results = kbUnitQueryGetResults(queryID);
      }

      if (numResults <= 0)
      {
         aiEchoWarning(mName + ": Calling attackWaveCreateUnitAttackPlan but there are no valid units to go attack, check this beforehand.");
         aiPlanDestroy(planID);
         return -1;
      }

      // For the attack wave plans we just path to all units we know a position of, cuz we don't do multiple attack like the regular AI.
      aiPlanSetNumberVariableValues(planID, cAttackPlanTargetPoint, numResults);
      for (int i = 0; i < numResults; i++)
      {
         aiPlanSetVariableVector(planID, cAttackPlanTargetPoint, i, kbUnitGetPosition(results[i]));
      }
      
      mWaveStartCallback(planID);
      aiPlanSetPriority(planID, 99);
      // Don't reduce this attack's size while underway.
      aiPlanSetFlag(planID, cPlanFlagCantBeStolenFrom, true);

      // Update attack size.
      mAttackSize = min(mAttackSize * mAttackSizeMultiplier, mMaxAttackSize);
      mLastAttackTime = xsGetTime();
      mLastAttackPlan = planID;

      if (mIsNaval == true)
      {
         debugAttackWave(mName + ": We found units to attack, sailing to every last known unit position now.");
      }
      else
      {
         debugAttackWave(mName + ":  We found units to attack, walking to every last known unit position now.");
      }
      debugAttackWave(mName + ": Launching an attack on " + mPlayerToAttack + " using plan " + aiPlanGetName(mLastAttackPlan) + ".");
      debugAttackWave(mName + ": New attack minimum size: " + xsFloatToInt(mMinAttackSize));
      debugAttackWave(mName + ": New attack wanted size: " + xsFloatToInt(mAttackSize));
      debugAttackWave(mName + ": New attack max size: " + xsFloatToInt(mMaxAttackSize));
      debugAttackWave(mName + ": New attack time: " + turnNumberIntoTimeDisplay(mLastAttackTime + mAttackInterval));
      return planID;
   }

   //==============================================================================
   // update
   //==============================================================================
   void update()
   {
      // If we have any attack wave active we enable this.
      xsEnableRule("outputAttackWaveInformation");

      int time = xsGetTime();
      if (time - mLastAttackTime < mAttackInterval)
      {
         return;
      }

      // Check if we have a valid base to attack.
      int targetBaseID = kbFindClosestBase(mPlayerToAttack, -1, mTargetPoint, false);
      if (targetBaseID == -1)
      {
         // We didn't find a single base belonging to our target player.
         // We must now either attack units that are still visible or scout.
         if (mIsNaval == true)
         {
            static int queryID = -1;
            if (queryID == -1)
            {
               queryID = kbUnitQueryCreate("Attack Wave Naval Unit");
               kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
               kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateRecentPositionKnown);
               kbUnitQuerySetUnitType(queryID, cUnitTypeNavalUnit);
               kbUnitQuerySetState(queryID, cUnitStateAlive);
            }
            // Reset since this could change.
            kbUnitQuerySetAreaGroupID(queryID, kbAreaGroupGetIDByPosition(mTargetPoint));
            kbUnitQueryResetResults(queryID);
            int numResults = kbUnitQueryExecute(queryID);
            if (numResults > 0)
            {
               if (mIsScouting == true)
               {
                  mIsScouting = false;
                  destroyScoutPlans();
               }
               mNoTargetsFoundSpam = 0;
               attackWaveCreateUnitAttackPlan();
               return;
            }
            else
            {
               mIsScouting = true;
               updateExplorePlansNaval();
            }

            if (mNoTargetsFoundSpam % 10 == 0)
            {
               debugAttackWave(mName + ": Delaying attack wave, no targets found!!!");
            }
            mNoTargetsFoundSpam++;
            return;
         }
         else
         {
            int[] excludeTypes = new int(1, cUnitTypeNavalUnit);
            if (getUnit(cUnitTypeLogicalTypeNeededForVictory, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
                  cUnitQueryVisibleStateRecentPositionKnown, excludeTypes) != -1)
            {
               if (mIsScouting == true)
               {
                  mIsScouting = false;
                  destroyScoutPlans();
               }
               mNoTargetsFoundSpam = 0;
               attackWaveCreateUnitAttackPlan();
               return;
            }
            else
            {
               mIsScouting = true;
               updateExplorePlans();
            }

            if (mNoTargetsFoundSpam % 10 == 0)
            {
               debugAttackWave(mName + ": Delaying attack wave, no targets found!!!");
            }
            mNoTargetsFoundSpam++;
            return;
         }
      }

      mNoTargetsFoundSpam = 0;
      if (mIsScouting == true)
      {
         mIsScouting = false;
         destroyScoutPlans();
      }

      // See if we have enough units to actually attack.
      int[] addUnits = new int(0, 0);
      // numRemaining is the number of units we couldn't add compared to our mAttackSize.
      // So if mAttackSize is 20 and we only found 15 units then numRemaining is 5.
      int numRemaining = findUnitsToAddToPlan(addUnits);

      // We added 0 units, to prevent our plan from being stuck we must delete it, guards against 0 minAttackSize attacks.
      if (numRemaining == mAttackSize)
      {
         if (mNotEnoughUnitsAddedSpam % 10 == 0)
         {
            debugAttackWave(mName + ": We found 0 units to add to the attack wave, delaying it.");
         }
         mNotEnoughUnitsAddedSpam++;
         return;
      }
      
      // If we didn't add enough units we must delete it too.
      if (xsFloatToInt(mAttackSize) - numRemaining < xsFloatToInt(mMinAttackSize))
      {
         if (mNotEnoughUnitsAddedSpam % 10 == 0)
         {
            debugAttackWave(mName + ": We added too few units to the attack wave: " + (xsFloatToInt(mAttackSize) - numRemaining) + "/" +
            xsFloatToInt(mMinAttackSize) + ", delaying it.");
         }
         mNotEnoughUnitsAddedSpam++;
         return;
      }
      mNotEnoughUnitsAddedSpam = 0;

      int planID = aiPlanCreate("Attack Wave: " + kbBaseGetNameByID(mPlayerToAttack, targetBaseID), cPlanAttack, -1,
         mIsNaval == true ? gNavalMilitaryCategoryID : gMilitaryAttackingCategoryID);

      for (int i = 0; i < addUnits.size(); i++)
      {
         aiPlanAddUnitType(planID, kbUnitGetProtoUnitID(addUnits[i]), 1, 1, 1, true);
         aiPlanAddUnit(planID, addUnits[i]);
      }

      aiPlanSetVariableInt(planID, cAttackPlanTargetMode, 0, cAttackPlanTargetModeBase);
      aiPlanSetVariableInt(planID, cAttackPlanTargetBaseID, 0, targetBaseID);
      aiPlanSetVariableInt(planID, cAttackPlanTargetPlayerID, 0, mPlayerToAttack);
      aiPlanSetVariableVector(planID, cAttackPlanGatherPoint, 0, mGatherPoint);
      aiPlanSetVariableInt(planID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
      aiPlanSetVariableInt(planID, cAttackPlanAttackRouteID, 0, mAttackRouteID);
      aiPlanSetVariableBool(planID, cAttackPlanPersistentAttackRoute, 0, true);
      setDefaultAttackPlanTargetUnitTypes(planID);

      // We want our units to clump up before sending out the attack.
      // We try to group everybody to within 15 range from the gather point. (after that the move command clumps them properly)
      // If all the units haven't reached this spot after 60 seconds we go ahead anyway.
      aiPlanSetVariableFloat(planID, cAttackPlanGatherDistance, 0, 15.0);
      aiPlanSetVariableInt(planID, cAttackPlanGatherWaitTime, 0, 60 * 1000);

      aiPlanSetVariableInt(planID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeCantFindMoreEnemyBases);
      if (mIsNaval == true)
      {
         aiPlanSetVariableInt(planID, cAttackPlanMovementTypeFlags, 0, cPassabilityWater);
      }
      else
      {
         aiPlanSetVariableInt(planID, cAttackPlanMovementTypeFlags, 0, cPassabilityLand | cPassabilityWater);
      }

      mWaveStartCallback(planID);
      aiPlanSetPriority(planID, 99);
      // Don't reduce this attack's size while underway.
      aiPlanSetFlag(planID, cPlanFlagCantBeStolenFrom, true);

      // Update attack size.
      mAttackSize = min(mAttackSize * mAttackSizeMultiplier, mMaxAttackSize);
      mLastAttackTime = time;
      mLastAttackPlan = planID;

      debugAttackWave(mName + ": We found a base to attack: " + kbBaseGetNameByID(mPlayerToAttack, targetBaseID) + ".");
      debugAttackWave(mName + ": Launching an attack on player " + mPlayerToAttack + ", base: " +
         kbBaseGetNameByID(mPlayerToAttack, targetBaseID) + ", using plan " + aiPlanGetName(mLastAttackPlan) + ".");
      debugAttackWave(mName + ": New attack minimum size: " + xsFloatToInt(mMinAttackSize));
      debugAttackWave(mName + ": New attack wanted size: " + xsFloatToInt(mAttackSize));
      debugAttackWave(mName + ": New attack max size: " + xsFloatToInt(mMaxAttackSize));
      debugAttackWave(mName + ": New attack time: " + turnNumberIntoTimeDisplay(mLastAttackTime + mAttackInterval));
   }
};

extern AttackWave gAttackWave;
extern AttackWave gSecondAttackWave;
extern AttackWave gNavalAttackWave;
extern AttackWave gSecondNavalAttackWave;

//==============================================================================
// createDefendPlan
// We most often defend a base in the campaign so those paramters are defined first,
// so we can leave the point related parameters on default during most calls.
//==============================================================================
int createDefendPlan(string planName = "", int baseID = -1, float gatherDistance = 5.0, vector gatherPoint = cInvalidVector,
   int prio = 20, vector defendPoint = cInvalidVector)
{
   // TODO verify positions on map.
   bool isNaval = false;
   if (kbAreaGetType(kbAreaGetIDByPosition(gatherPoint)) == cAreaTypeWater)
   {
      isNaval = true;
   }
   int planID = aiPlanCreate(planName, cPlanDefend, -1, isNaval == true ? gNavalMilitaryCategoryID : gMilitaryDefendingCategoryID);

   // We either defend the defined base or we must defend a point.
   if (baseID != -1)
   {
      aiPlanSetVariableInt(planID, cDefendPlanTargetMode, 0, cDefendPlanTargetModeBase);
      aiPlanSetVariableInt(planID, cDefendPlanTargetBaseID, 0, baseID);
      aiPlanSetVariableInt(planID, cDefendPlanTargetPlayerID, 0, cMyID);
   }
   else
   {
      aiPlanSetVariableInt(planID, cDefendPlanTargetMode, 0, cDefendPlanTargetModePoint);
      aiPlanSetVariableVector(planID, cDefendPlanTargetPoint, 0, defendPoint);
   }
   aiPlanSetVariableVector(planID, cDefendPlanGatherPoint, 0, gatherPoint);
   aiPlanSetVariableFloat(planID, cDefendPlanGatherDistance, 0, gatherDistance);
   setDefaultDefendPlanTargetUnitTypes(planID);
   aiPlanSetInitialPosition(planID, gatherPoint);
   aiPlanSetPriority(planID, prio);

   return (planID);
}

//==============================================================================
// createDefendPlanForBase
//==============================================================================
int createDefendPlanForBase(string planName = "", int baseID = -1, float gatherDistance = 5.0, vector gatherPoint = cInvalidVector,
   int prio = 20)
{
   if (kbBaseGetIsIDValid(cMyID, baseID) == false)
   {
      aiEchoWarning("createDefendPlanForBase - invalid baseID input of " + baseID + ".");
      return -1;
   }
   if (kbGetIsLocationOnMap(gatherPoint) == false)
   {
      aiEchoWarning("createDefendPlanForBase - invalid gatherPoint input of " + gatherPoint + ", it's not on the map.");
      return -1;
   }
   if (gatherDistance < 1.0)
   {
      aiEchoWarning("createDefendPlanForBase - invalid gatherDistance input of " + gatherDistance + ", minimum is 1.0.");
      return -1;
   }
   if (prio < 0 || prio > 100)
   {
      aiEchoWarning("createDefendPlanForBase - invalid prio input of " + prio + ", minimum is 0 and maximum is 100.");
      return -1;
   }

   bool isNaval = false;
   if (kbAreaGetType(kbAreaGetIDByPosition(gatherPoint)) == cAreaTypeWater)
   {
      isNaval = true;
   }
   int planID = aiPlanCreate(planName, cPlanDefend, -1, isNaval == true ? gNavalMilitaryCategoryID : gMilitaryDefendingCategoryID);

   aiPlanSetVariableInt(planID, cDefendPlanTargetMode, 0, cDefendPlanTargetModeBase);
   aiPlanSetVariableInt(planID, cDefendPlanTargetBaseID, 0, baseID);
   aiPlanSetVariableInt(planID, cDefendPlanTargetPlayerID, 0, cMyID);

   aiPlanSetVariableVector(planID, cDefendPlanGatherPoint, 0, gatherPoint);
   aiPlanSetVariableFloat(planID, cDefendPlanGatherDistance, 0, gatherDistance);
   setDefaultDefendPlanTargetUnitTypes(planID);
   aiPlanSetInitialPosition(planID, gatherPoint);
   aiPlanSetPriority(planID, prio);

   return planID;
}

//==============================================================================
// createDefendPlanForPoint
//==============================================================================
int createDefendPlanForPoint(string planName = "", vector point = cInvalidVector, float gatherDistance = 5.0, int prio = 20)
{
   if (kbGetIsLocationOnMap(point) == false)
   {
      aiEchoWarning("createDefendPlanForPoint - invalid point input of " + point + ", it's not on the map.");
      return -1;
   }
   if (gatherDistance < 1.0)
   {
      aiEchoWarning("createDefendPlanForPoint - invalid gatherDistance input of " + gatherDistance + ", minimum is 1.0.");
      return -1;
   }
   if (prio < 0 || prio > 100)
   {
      aiEchoWarning("createDefendPlanForPoint - invalid prio input of " + prio + ", minimum is 0 and maximum is 100.");
      return -1;
   }

   bool isNaval = false;
   if (kbAreaGetType(kbAreaGetIDByPosition(point)) == cAreaTypeWater)
   {
      isNaval = true;
   }
   int planID = aiPlanCreate(planName, cPlanDefend, -1, isNaval == true ? gNavalMilitaryCategoryID : gMilitaryDefendingCategoryID);

   aiPlanSetVariableInt(planID, cDefendPlanTargetMode, 0, cDefendPlanTargetModePoint);
   aiPlanSetVariableVector(planID, cDefendPlanTargetPoint, 0, point);

   aiPlanSetVariableVector(planID, cDefendPlanGatherPoint, 0, point);
   aiPlanSetVariableFloat(planID, cDefendPlanGatherDistance, 0, gatherDistance);
   setDefaultDefendPlanTargetUnitTypes(planID);
   aiPlanSetInitialPosition(planID, point);
   aiPlanSetPriority(planID, prio);

   return planID;
}

//==============================================================================
// outputAttackWaveInformation
//==============================================================================
rule outputAttackWaveInformation
inactive
minInterval 120
{
   debugAttackWave("--- Running Rule outputAttackWaveInformation ---");
   AttackWave wave;
   for (int i = 0; i < 3; i++)
   {
      if (i == 0)
      {
         wave = gAttackWave;
      }
      else if (i == 1)
      {
         wave = gSecondAttackWave;
      }
      else if (i == 2)
      {
         wave = gNavalAttackWave;
      }
      else
      {
         wave = gSecondNavalAttackWave;
      }
      // Only output waves that are in use.
      if (wave.mAttackRouteID == -1)
      {
         continue;
      }

      debugAttackWave("--- Outputting information for " + wave.mName + " ---");
      debugAttackWave("Attack Interval: " + wave.mAttackInterval);
      debugAttackWave("Attack Route ID: " + wave.mAttackRouteID);
      debugAttackWave("Attack Size Multiplier: " + wave.mAttackSizeMultiplier);
      debugAttackWave("Unit Types Added For Attack:");
      for (int j = 0; j < wave.mAttackUnitTypes.size(); j++)
      {
         debugAttackWave("" + kbProtoUnitGetName(wave.mAttackUnitTypes[j]));
      }
   }

   debugAttackWave("--- Outputting unit maintain information ---");
   Strategy currentStrategy = gStrategyManager.getCurrentStrategy();
   StrategyData currentStrategyData = currentStrategy.mData;
   debugAttackWave("Maintaining These Units:");
   for (int i = 0; i < currentStrategyData.mTrainPlans.size(); i++)
   {
      int planID = currentStrategyData.mTrainPlans[i];
      debugAttackWave(aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0) + " " +
         kbProtoUnitGetName(aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0)) + ", Train Delay: " +
            aiPlanGetVariableInt(planID, cTrainPlanFrequency, 0));
   }
   if (currentStrategyData.mTrainPlans.size() == 0)
   {
      debugAttackWave("Maintaining 0 units!");
   }
   if (checkStrategyFlag(cStrategyFlagAutomaticVillagerTraining) == true)
   {
      if (aiPlanGetIsIDValid(gVillagerMaintainPlan) == true)
      {
         debugAttackWave(aiPlanGetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0) + " " +
            kbProtoUnitGetName(aiPlanGetVariableInt(gVillagerMaintainPlan, cTrainPlanUnitType, 0)) + ", Train Delay: " +
            aiPlanGetVariableInt(gVillagerMaintainPlan, cTrainPlanFrequency, 0));
      }

      if (aiPlanGetIsIDValid(gSecondVillagerMaintainPlan) == true)
      {
         debugAttackWave(aiPlanGetVariableInt(gSecondVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0) + " " +
            kbProtoUnitGetName(aiPlanGetVariableInt(gSecondVillagerMaintainPlan, cTrainPlanUnitType, 0)) + ", Train Delay: " +
            aiPlanGetVariableInt(gSecondVillagerMaintainPlan, cTrainPlanFrequency, 0));
      }
   }
   
   if (checkStrategyFlag(cStrategyFlagAutomaticFishing) == true)
   {
      if (aiPlanGetIsIDValid(gFishingShipMaintainPlan) == true)
      {
         debugAttackWave(aiPlanGetVariableInt(gFishingShipMaintainPlan, cTrainPlanNumberToMaintain, 0) + " " +
            kbProtoUnitGetName(aiPlanGetVariableInt(gFishingShipMaintainPlan, cTrainPlanUnitType, 0)) + ", Train Delay: " +
            aiPlanGetVariableInt(gFishingShipMaintainPlan, cTrainPlanFrequency, 0));
      }
   }
}