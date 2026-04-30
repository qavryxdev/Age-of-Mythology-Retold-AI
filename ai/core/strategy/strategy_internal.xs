extern const int cStrategyDefault = 0;
mutable bool checkStrategyFlag(int flag = 0) { return false; }

bool strategyBuildingCanBuildDefault(int puid = -1, int number = 1)
{
   int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanBuild, cBuildPlanBuildingTypeID, puid);
   return ((aiPlanGetIsIDValid(planID) == false) && (kbUnitCount(puid, cMyID, cUnitStateAlive) < number));
}

class StrategyBuildingMaintainEntry
{
   int puid = -1;
   int number = 1;
   int pri = 50;
   bool(int, int) onCanBuild = strategyBuildingCanBuildDefault;
};

class StrategyData
{
   int mID = -1;
   int mFlags = 0;
   int mFlags2 = 0;
   StrategyBuildingMaintainEntry[] mBuildingsToMaintain = default;
   int[] mTrainPlans = default;
   int mTowerAmountPerTCBase = cCalculateNumberTowersAutomatically;
   int mWallCircleAmount = 0;

   void setFlag(int flag = 0, bool enable = true)
   {
      if (flag <= 31)
      {
         if (enable == true)
         {
            mFlags |= 1 << flag;
         }
         else
         {
            mFlags &= -1 ^ (1 << flag);
         }
         return;
      }
      flag -= 32;
      if (enable == true)
      {
         mFlags2 |= 1 << flag;
      }
      else
      {
         mFlags2 &= -1 ^ (1 << flag);
      }
   }

   void reserveResource(int resourceID = -1, float amount = 0) {}

   // Adds a building to maintain.
   void addBuildingToMaintain(int puid = -1, int number = 1, int pri = 50,
                              bool(int, int) onCanBuild = strategyBuildingCanBuildDefault)
   {
      bool found = false;
      int size = mBuildingsToMaintain.size();
      for (int i = 0; i < size; i++)
      {
         StrategyBuildingMaintainEntry entry = mBuildingsToMaintain[i];
         if (entry.puid != puid)
         {
            continue;
         }
         entry.number = number;
         entry.pri = pri;
         mBuildingsToMaintain[i] = entry;
         found = true;
         break;
      }

      if (found == false)
      {
         StrategyBuildingMaintainEntry entry;
         entry.puid = puid;
         entry.number = number;
         entry.pri = pri;
         entry.onCanBuild = onCanBuild;
         mBuildingsToMaintain.add(entry);
      }
   }

   void removeBuildingToMaintain(int puid = -1)
   {
      int size = mBuildingsToMaintain.size();
      for (int i = 0; i < size; i++)
      {
         StrategyBuildingMaintainEntry entry = mBuildingsToMaintain[i];
         if (entry.puid != puid)
         {
            continue;
         }

         mBuildingsToMaintain.removeIndex(i);
         break;
      }
   }

   // Adds a unit type to maintain.
   void addUnitToMaintain(int puid = -1, int numberToMaintain = 1, int pri = 50)
   {
      bool found = false;

      for (int i = 0; i < mTrainPlans.size(); i++)
      {
         int planID = mTrainPlans[i];
         if (aiPlanGetIsIDValid(planID) == false || aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0) != puid)
         {
            continue;
         }
         found = true;
         break;
      }

      if (found == true)
      {
         aiEchoWarning("addUnitToMaintain - Trying to create a new train plan for " + kbProtoUnitGetName(puid) +
            ", but we're already maintaining that unit, use adjustUnitToMaintainAmount instead.");
         return;
      }

      int planID = createSimpleMaintainPlan(puid, numberToMaintain, -1, pri);
      if (planID >= 0)
      {
         mTrainPlans.add(planID);
      }
   }

   // Adds a unit type to maintain.
   void adjustUnitToMaintainAmount(int puid = -1, int numberToMaintain = 1, int pri = 50)
   {
      for (int i = 0; i < mTrainPlans.size(); i++)
      {
         int planID = mTrainPlans[i];
         if (aiPlanGetIsIDValid(planID) == false || aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0) != puid)
         {
            continue;
         }
         aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);
         aiPlanSetPriority(planID, pri);
         return;
      }
      aiEchoWarning("adjustUnitToMaintainAmount - Trying to adjust the maintain amount of " + kbProtoUnitGetName(puid) +
         ", but we're not maintaining that unit, use addUnitToMaintain instead.");
   }

   // Set train delay of an existing train plan.
   void setTrainDelay(int puid = -1, float delay = 0)
   {
      if (delay < 1.0)
      {
         delay = 1.0;
      }
      for (int i = 0; i < mTrainPlans.size(); i++)
      {
         int planID = mTrainPlans[i];
         if (aiPlanGetIsIDValid(planID) == false || aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0) != puid)
         {
            continue;
         }
         aiPlanSetVariableInt(planID, cTrainPlanFrequency, 0, delay);
         aiPlanSetVariableBool(planID, cTrainPlanUseMultipleBuildings, 0, false);
         return;
      }
      aiEchoWarning("setTrainDelay - Trying to set the train delay of " + kbProtoUnitGetName(puid) +
         ", but we're not maintaining that unit, use addUnitToMaintain first.");
   }

   // Set the gather point of an existing train plan.
   void setGatherPoint(int puid = -1, vector location = cInvalidVector)
   {
      for (int i = 0; i < mTrainPlans.size(); i++)
      {
         int planID = mTrainPlans[i];
         if (aiPlanGetIsIDValid(planID) == false || aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0) != puid)
         {
            continue;
         }
         aiPlanSetVariableVector(planID, cTrainPlanGatherPoint, 0, location);
         break;
      }
   }

   // Removes a unit type to maintain.
   void removeUnitToMaintain(int puid = -1)
   {
      for (int i = 0; i < mTrainPlans.size(); i++)
      {
         int planID = mTrainPlans[i];
         if (aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0) != puid)
         {
            continue;
         }

         aiPlanDestroy(planID);
         mTrainPlans.removeIndex(i);
         return;
      }
      aiEchoWarning("removeUnitToMaintain - Trying to remove the train plan of " + kbProtoUnitGetName(puid) +
         ", but we're not maintaining that unit.");
   }

   void initDefaultStrategy(int age = cAge1)
   {
      static int currentAge = cAge1;

      // only call once per age.
      if (currentAge < age)
      {
         aiPopulateAgeUpList();
         currentAge = age;
      }

      mFlags = -1;
      mFlags2 = -1;
   }
};

int[] gNextStrategyIDs = default;
int getNextStrategy(ref StrategyData data) { return (gNextStrategyIDs[data.mID]); }

int(ref StrategyData) gStrategyInterruptHandler = [](ref StrategyData data) -> int { return (-1); };
int getDefaultStrategyInterruptHandler(ref StrategyData data) { return (gStrategyInterruptHandler(data)); }

class Strategy
{
   StrategyData mData;
   // strategy setup.
   bool(ref StrategyData) mInitFunc = [](ref StrategyData data) -> bool { return (true); };
   // periodic checks and updates to keep the strategy intact.
   // When returning false, proceed with destroy otherwise continue running.
   bool(ref StrategyData) mUpdateFunc = [](ref StrategyData data) -> bool { return (true); };
   // clean up the strategy.
   void(ref StrategyData) mDestroyFunc = [](ref StrategyData data) {};
   // pick the next one to execute.
   int(ref StrategyData) mNextFunc = getNextStrategy;
   // When returning a valid strategy, interrupt the current strategy and proceed with it.
   int(ref StrategyData) mInterruptFunc = getDefaultStrategyInterruptHandler;
   string mName = "Missing Name";

   void displayStrategyInformation()
   {
      debugStrategy("Name: " + mName);
      debugStrategy("ID: " + mData.mID);
      debugStrategy("cStrategyFlagAutoAgeUp: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutoAgeUp)));
      debugStrategy("cStrategyFlagAutoBuildMilitaryBuildings: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutoBuildMilitaryBuildings)));
      debugStrategy("cStrategyFlagAutoTrainMilitaryUnits: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutoTrainMilitaryUnits)));
      debugStrategy("cStrategyFlagAutoResearchEconomyUpgrades: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutoResearchEconomyUpgrades)));
      debugStrategy("cStrategyFlagAutoResearchMilitaryUpgrades: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutoResearchMilitaryUpgrades)));
      debugStrategy("cStrategyFlagCanAttack: " + xsBoolToString(checkStrategyFlag(cStrategyFlagCanAttack)));
      debugStrategy("cStrategyFlagBuildArmory: " + xsBoolToString(checkStrategyFlag(cStrategyFlagBuildArmory)));
      debugStrategy("cStrategyFlagBuildMonuments: " + xsBoolToString(checkStrategyFlag(cStrategyFlagBuildMonuments)));
      debugStrategy("cStrategyFlagAutomaticVillagerTraining: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticVillagerTraining)));
      debugStrategy("cStrategyFlagAutomaticHerding: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticHerding)));
      debugStrategy("cStrategyFlagAutomaticScouting: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticScouting)));
      debugStrategy("cStrategyFlagAutomaticOxCartTraining: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticOxCartTraining)));
      debugStrategy("cStrategyFlagBuildEconomicGuild: " + xsBoolToString(checkStrategyFlag(cStrategyFlagBuildEconomicGuild)));
      debugStrategy("cStrategyFlagBuildTemple: " + xsBoolToString(checkStrategyFlag(cStrategyFlagBuildTemple)));
      debugStrategy("cStrategyFlagBuildHouses: " + xsBoolToString(checkStrategyFlag(cStrategyFlagBuildHouses)));
      debugStrategy("cStrategyFlagCanDefend: " + xsBoolToString(checkStrategyFlag(cStrategyFlagCanDefend)));
      debugStrategy("cStrategyFlagBuildTowers: " + xsBoolToString(checkStrategyFlag(cStrategyFlagBuildTowers)));
      debugStrategy("cStrategyFlagAutomaticGodPowerUsage: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticGodPowerUsage)));
      debugStrategy("cStrategyFlagCanTrade: " + xsBoolToString(checkStrategyFlag(cStrategyFlagCanTrade)));
      debugStrategy("cStrategyFlagAutomaticEco: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticEco)));
      debugStrategy("cStrategyFlagAutomaticFishing: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticFishing)));
      debugStrategy("cStrategyFlagAutomaticDockBuilding: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticDockBuilding)));
      debugStrategy("cStrategyFlagAutomaticBaseGrowth: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticBaseGrowth)));
      debugStrategy("cStrategyFlagAutomaticNavalGameplay: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticNavalGameplay)));
      debugStrategy("cStrategyFlagAutomaticMainBaseTCRebuild: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticMainBaseTCRebuild)));
      debugStrategy("cStrategyFlagAutomaticTCRepair: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticTCRepair)));
      debugStrategy("cStrategyFlagAutomaticTCExpansion: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticTCExpansion)));
      debugStrategy("cStrategyFlagCollectRelics: " + xsBoolToString(checkStrategyFlag(cStrategyFlagCollectRelics)));
      debugStrategy("cStrategyFlagManageOracles: " + xsBoolToString(checkStrategyFlag(cStrategyFlagManageOracles)));
      debugStrategy("cStrategyFlagTrainOracles: " + xsBoolToString(checkStrategyFlag(cStrategyFlagTrainOracles)));
      debugStrategy("cStrategyFlagAutomaticDropsiteCleanup: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticDropsiteCleanup)));
      debugStrategy("cStrategyFlagAutomaticPopLimits: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticPopLimits)));
      debugStrategy("cStrategyFlagBuildTitan: " + xsBoolToString(checkStrategyFlag(cStrategyFlagBuildTitan)));
      debugStrategy("cStrategyFlagCanResign: " + xsBoolToString(checkStrategyFlag(cStrategyFlagCanResign)));
      debugStrategy("cStrategyFlagBuildWonder: " + xsBoolToString(checkStrategyFlag(cStrategyFlagBuildWonder)));
      debugStrategy("cStrategyFlagConvertVillagerToBerserk: " + xsBoolToString(checkStrategyFlag(cStrategyFlagConvertVillagerToBerserk)));
      debugStrategy("cStrategyFlagRebuysGodPowers: " + xsBoolToString(checkStrategyFlag(cStrategyFlagRebuysGodPowers)));
      debugStrategy("cStrategyFlagScoutWithStartingTransport: " + xsBoolToString(checkStrategyFlag(cStrategyFlagScoutWithStartingTransport)));
      debugStrategy("cStrategyFlagAutomaticFortressRepair: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticFortressRepair)));
      debugStrategy("cStrategyFlagAutomaticBuildingRepair: " + xsBoolToString(checkStrategyFlag(cStrategyFlagAutomaticBuildingRepair)));
   }
};

class StrategyManager
{
   Strategy[] mStrategies = default;
   int mCurrentID = -1;
   int mLastID = -1;
   int mStartingStrategy = cStrategyDefault;

   // Add a strategy, defaults to continuing with the next strategy added if no function is provided.
   void addStrategy(ref Strategy strategy)
   {
      int newCount = strategy.mData.mID + 1;
      if (newCount >= mStrategies.size())
      {
         mStrategies.resize(newCount);
         gNextStrategyIDs.resize(newCount, -1);
      }
      mStrategies[strategy.mData.mID] = strategy;
      if (mCurrentID != -1)
      {
         gNextStrategyIDs[mCurrentID] = strategy.mData.mID;
      }
      mCurrentID = strategy.mData.mID;
      debugStrategy("Adding strategy: " + strategy.mName + ", with ID: " + strategy.mData.mID);
   }

   void setInterruptHandler(int(ref StrategyData) interruptFunc = [](ref StrategyData data) -> int { return (-1); })
   {
      gStrategyInterruptHandler = interruptFunc;
   }

   void cleanUpStrategy(ref Strategy strategy)
   {
      // Destroy all train plans.
      for (int i = 0; i < strategy.mData.mTrainPlans.size(); i++)
      {
         aiPlanDestroy(strategy.mData.mTrainPlans[i]);
      }
      strategy.mData.mTrainPlans.clear();
      // We do not have an array of current strategy related build plans that we can use to destroy.
      // But luckily we also don't want to do that, because it could cause buildings in progress to
      // seemingly randomly be destroyed by the AI.
   }

   void update()
   {
      Strategy strategy;
      int newStrategyID = -1;

      // If we already have a strategy we need to update that one specifically.
      if (mCurrentID >= 0)
      {
         strategy = mStrategies[mCurrentID];
         int interruptStrategyID = strategy.mInterruptFunc(strategy.mData);

         if (interruptStrategyID < 0 || interruptStrategyID == mCurrentID)
         {
            if (strategy.mUpdateFunc(strategy.mData) == false)
            {
               debugStrategy("*** Strategy: " + strategy.mName + " is ending! ***");
               newStrategyID = strategy.mNextFunc(strategy.mData);
               strategy.mDestroyFunc(strategy.mData);
               cleanUpStrategy(strategy);
            }
         }
         else
         {
            debugStrategy("*** Activating interrupt strategy: " + interruptStrategyID + " ***");
            newStrategyID = interruptStrategyID;
            strategy.mDestroyFunc(strategy.mData);
            cleanUpStrategy(strategy);
         }

         // Save data back to array.
         mStrategies[mCurrentID] = strategy;
      }
      // If we don't have a strategy we assume we're just at the start of the game and need to start up.
      else
      {
         strategy = mStrategies[mStartingStrategy];
         newStrategyID = mStartingStrategy;
      }

      // If we're in need of selecting a new strategy, then do this.
      while (newStrategyID >= 0)
      {
         int lastID = mCurrentID;
         mCurrentID = newStrategyID;
         strategy = mStrategies[newStrategyID];
         setInterruptHandler();
         if (strategy.mInitFunc(strategy.mData) == false)
         {
            // If our init fails we need to pick the next strategy to continue with.
            debugStrategy("*** Failed to initialize new strategy: " + strategy.mName + 
               ", picking a new one instead. ***");
            mCurrentID = lastID;
            newStrategyID = strategy.mNextFunc(strategy.mData);
            strategy.mDestroyFunc(strategy.mData);
            cleanUpStrategy(strategy);
         }
         else
         {
            if (strategy.mUpdateFunc(strategy.mData) == false)
            {
               debugStrategy("*** New strategies' update func instantly returned false: " + strategy.mName + 
               ", picking a new one instead. ***");
               mCurrentID = lastID;
               newStrategyID = strategy.mNextFunc(strategy.mData);
               strategy.mDestroyFunc(strategy.mData);
               cleanUpStrategy(strategy);
               continue;
            }
            // Save data back to array.
            debugStrategy("*** Activated new strategy ***");
            mLastID = lastID;
            mStrategies[mCurrentID] = strategy;
            newStrategyID = -1;
            strategy.displayStrategyInformation();

            int currentAge = kbPlayerGetAge(cMyID);
            xsRuleGroupIgnoreIntervalOnce("defaultArchaicRules");
            if (currentAge >= cAge2)
            {
               xsRuleGroupIgnoreIntervalOnce("defaultClassicalRules");
            }
            if (currentAge >= cAge3)
            {
               xsRuleGroupIgnoreIntervalOnce("defaultHeroicRules");
            }
            if (currentAge >= cAge4)
            {
               xsRuleGroupIgnoreIntervalOnce("defaultMythicRules");
            }
            if (currentAge >= cAge5)
            {
               xsRuleGroupIgnoreIntervalOnce("defaultWonderRules");
            }

            // Don't do this when we enter the BO.
            if (strategy.mName != "BO")
            {
               // We have just ignored the interval on all rules BUT:
               // We don't want to instantly run updateDistributionAndBreakdowns after we enter a new strategy.
               // We first want to give all the other rules a chance to set up their needs and then we parse over those shortly after.
               // If we don't do this we update all our breakdowns with wrong information on what our new strategy actually wants to produce.
               gDelayUpdateDistributionAndBreakdowns = true;
               // Equally we must wait with a full re-assignment until all our new plans are created, including the breakdowns.
               aiSetFullUnitAssignmentTime(xsGetTimeMS() + 1500);
               // The idle reassignment gets set by updateDistributionAndBreakdowns.
            }

            // We potentially have unspent GPs lying around, clear the bank if this new strategy allows that.
            // If we just aged up our new GP will already be in the bank, see ageUpEventHandler for details.
            if (checkStrategyFlag(cStrategyFlagAutomaticGodPowerUsage) == true)
            {
               godPowerManager.useUnusedGodPowers();
            }
         }
      }
   }

   // Only called once during the startup chain, before start().
   void init()
   {
   }

   // Only called once during the startup chain.
   void start()
   {
      mCurrentID = -1;
      update();
      xsEnableRuleGroup("strategyMonitors");
   }

   Strategy getCurrentStrategy()
   {
      return mStrategies[mCurrentID];
   }
};

extern StrategyManager gStrategyManager;

int getLastStrategy(ref StrategyData data)
{
   return (gStrategyManager.mLastID);
}

bool checkStrategyFlag(int flag = 0)
{
   Strategy strategy = gStrategyManager.mStrategies[gStrategyManager.mCurrentID];
   if (flag <= 31)
   {
      return ((strategy.mData.mFlags & (1 << flag)) != 0);
   }
   flag -= 32;
   return ((strategy.mData.mFlags2 & (1 << flag)) != 0);
}
int getStrategyTowerAmount()
{
   Strategy s = gStrategyManager.getCurrentStrategy(); 
   return s.mData.mTowerAmountPerTCBase;
}
int getStrategyWallCircleAmount()
{
   Strategy s = gStrategyManager.getCurrentStrategy(); 
   return s.mData.mWallCircleAmount;
}
void updateStrategyMaintainBuildings(void)
{
   Strategy strategy = gStrategyManager.mStrategies[gStrategyManager.mCurrentID];
   StrategyBuildingMaintainEntry[] buildingsToMaintain = strategy.mData.mBuildingsToMaintain;
   bool autoBuildMilitaryBuildings = checkStrategyFlag(cStrategyFlagAutoBuildMilitaryBuildings);
   int buildingsToMaintainSize = buildingsToMaintain.size();

   for (int i = 0; i < buildingsToMaintainSize; i++)
   {
      StrategyBuildingMaintainEntry entry = buildingsToMaintain[i];
      if (entry.onCanBuild(entry.puid, entry.number) == true)
      {
         int planID = createSimpleBuildPlan(entry.puid, 1, 70, -1, 1);
         aiPlanSetPriority(planID, entry.pri);
      }
   }
}

rule strategyMonitor
group strategyMonitors
inactive
minInterval 1
{
   gStrategyManager.update();
}

rule strategyMonitorInfrequent
group strategyMonitors
inactive
minInterval 5
{
   updateStrategyMaintainBuildings();
}