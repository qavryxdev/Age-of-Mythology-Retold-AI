int gFromID = -1;
int gAnswer = -1;

//==============================================================================
// delayedResponse
//==============================================================================
rule delayedResponse
inactive
minInterval 2
{
   if (gAnswer == 1)
   {
      aiChat(gFromID, "1");
   }
   else
   {
      aiChat(gFromID, "2");
   }
   gFromID = -1;
   gAnswer = -1;
   xsDisableRule("delayedResponse");
}

//==============================================================================
// commHandler
//==============================================================================
void commHandler(int tauntID = -1)
{
   if (xsIsRuleEnabled("delayedResponse") == true)
   {
      return; // We can't handle many requests fast after one another. That would mess with our respond system.
   }

   int fromID = aiCommsGetSendingPlayer(tauntID); // Which player sent this?
   if (fromID == cMyID)
   {
      return;  // DO NOT react to my own taunts.
   }
   if ((kbPlayerIsEnemy(fromID) == true) && (fromID != 0))
   {
      return;  // DO NOT accept taunts from enemies.
   }
   if (boSystem.done == false)
   {
      gAnswer = 2;
      gFromID = fromID;
      xsEnableRule("delayedResponse");
      return;
   }

   int tauntCode = aiCommsGetTauntCode(tauntID); // What taunt was it?
   debugChats("fromID: " + fromID);
   debugChats("tauntCode: " + tauntCode);
   
   switch (tauntCode)
   {
      // "Food please"
      case 3:
      {
         if (handleTributeRequest(cResourceFood, fromID) == true)
         {
            gAnswer = 1;
         }
         else
         {
            gAnswer = 2;
         }
         break;
      }   

      // "Wood please"   
      case 4:
      {
         if (handleTributeRequest(cResourceWood, fromID) == true)
         {
            gAnswer = 1;
         }
         else
         {
            gAnswer = 2;
         }
         break;
      }

      // "Gold please"
      case 5:
      {
         if (handleTributeRequest(cResourceGold, fromID) == true)
         {
            gAnswer = 1;
         }
         else
         {
            gAnswer = 2;
         }
         break;
      }

      // "I need help"
      case 12:
      {
         // For this one we're going to check if any of our allied TC bases is under attack.
         // If it is we can send some help, surely :P
         if (aiPlanGetState(gPrimaryLandDefendPlan) == cPlanStateAttack)
         {
            gAnswer = 2;
            break;
         }

         int defendPlayer = fromID;
         int enemyPopCount = 0;
         int defendBaseID = calculateAlliedBaseToDefend(enemyPopCount, defendPlayer);
         if (defendBaseID == -1)
         {
            gAnswer = 2;
            break;
         }
         
         createDefaultAllyDefendPlan(defendPlayer, defendBaseID, enemyPopCount);
         gAnswer = 1;
         break;
      }

      // "Attack now"
      case 15:
      {
         gAttackManager.updateState();
         if (gAttackManager.mState != cStateNormal)
         {
            gAnswer = 2;
            break;
         }
         if (metRequirementsToAttack(true) == false)
         {
            gAnswer = 2;
            break;
         }
         int targetPlayer = aiGetMostHatedPlayerID();
         if (targetPlayer == -1)
         {
            gAnswer = 2;
            break;
         }
         int targetBaseID = calculateTargetBase(targetPlayer);
         if (targetBaseID == -1)
         {
            gAnswer = 2;
            break;
         }
         createDefaultAttackPlan(targetPlayer, targetBaseID);
         gAnswer = 1;
         break;
      }

      // "Build a wonder"
      case 16:
      {
         if (checkStrategyFlag(cStrategyFlagBuildWonder) == false)
         {
            gAnswer = 2;
            break;
         }
         if (buildingGetNumberAliveAndPlanned(cUnitTypeWonder) >= 1)
         {
            gAnswer = 2;
            break;
         }
         if (haveEnoughExcessForWonder() == false)
         {
            gAnswer = 2;
            break;
         }

         wonderConstructionMonitor();
         gAnswer = 1;
         break;
      }
      default:
      {
         return; // Don't react to any chat that isn't an order like above.
      }
   }

   // Set up our response.
   gFromID = fromID;
   xsEnableRule("delayedResponse");
}

//==============================================================================
// delayedStartupChat
//==============================================================================
rule delayedStartupChat
inactive
minInterval 5
{
   sendStatementToEnemies(cAICommPromptToEnemyWhenGameStarts);
   xsDisableRule("delayedStartupChat");
}

//==============================================================================
// lostAllVillagersChat
//==============================================================================
rule lostAllVillagersChat
group chatRules
inactive
minInterval 5
{
   static bool everHadVillagers = false;
   if (everHadVillagers == false)
   {
      if (kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive) >= 1)
      {
         everHadVillagers = true;
      }
      return;
   }
   if (kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive) == 0)
   {
      sendStatementToEverybody(cAICommPromptToEverybodyLostAllVillagers);
      everHadVillagers = false;
      xsSetRuleMinInterval("lostAllVillagersChat", 180); // Don't run this when we can't chat about this again soon anyway.
   }
}

//==============================================================================
// lostTownCentersChat
//==============================================================================
rule lostownCentersChat
group chatRules
inactive
minInterval 5
{
   static int previousTCCount = 0;
   int currentTCCount = kbUnitCount(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateAlive);

   if (previousTCCount != 0 && currentTCCount == 0)
   {
      sendStatementToEnemies(cAICommPromptToEnemyILostMyLastTownCenter);
   }
   else if (previousTCCount > currentTCCount)
   {
      sendStatementToEnemies(cAICommPromptToEnemyILostTownCenterButStillHaveOne);
   }
   previousTCCount = currentTCCount;
}

//==============================================================================
// enemyIsBuildingWallsChat
//==============================================================================
rule enemyIsBuildingWallsChat
group chatRules
inactive
minInterval 30
{
   for (int i = 1; i <= cNumberPlayers; i++)
   {
      if (i == cMyID ||kbPlayerIsEnemy(i) == false || kbPlayerHasLost(i) == true)
      {
         continue;
      }
      if (kbUnitCount(cUnitTypeAbstractWall, cMyID, cUnitStateAlive) > 10)
      {
         debugChats("Sending prompt " + cAICommPromptToEnemyTheyAreBuildingWalls + " to " + i + ".");
         aiCommsSendStatement(i, cAICommPromptToEnemyTheyAreBuildingWalls);
         xsSetRuleMinInterval("enemyIsBuildingWallsChat", 180); // Don't run this when we can't chat about this again soon anyway.
         return;
      }
   }
}

//==============================================================================
// enemyLostTheirLastTC
// This doesn't really have to be their last TC since we don't cheat KB switch to verify that.
//==============================================================================
rule enemyLostTheirLastTC
group chatRules
inactive
minInterval 5
{
   static int enemyID = -1;
   if (enemyID == -1)
   {
      enemyID = getRandomEnemyID();
      if (enemyID == -1)
      {
         return; // No enemies atm?
      }
   }

   static int previousTCCount = 0;
   int currentTCCount = kbUnitCount(cUnitTypeAbstractSocketedTownCenter, enemyID, cUnitStateAlive);

   if (previousTCCount != 0 && currentTCCount == 0)
   {
      debugChats("Sending prompt " + cAICommPromptToEnemyTheyLostTheirFinalTownCenter + " to " + enemyID + ".");
      aiCommsSendStatement(enemyID, cAICommPromptToEnemyTheyLostTheirFinalTownCenter);
      enemyID = -1; // Potentially switch enemies we analyze.
      xsSetRuleMinInterval("enemyLostTheirLastTC", 180); // Don't run this when we can't chat about this again soon anyway.
   }
   previousTCCount = currentTCCount;
}

//==============================================================================
// resignMonitor
//==============================================================================
rule resignMonitor
inactive
minInterval 30
{
   if (checkStrategyFlag(cStrategyFlagCanResign) == false)
   {
      return;
   }
   debugChats("--- Running Rule resignMonitor ---");

   // Reset our interval again, resignHandler could've increased it.
   xsSetRuleMinInterval("resignMonitor", 30);
   bool haveEnemyHuman = false;
   for (int i = 1; i <= cNumberPlayers; i++)
   {
      if (i != cMyID)
      {
         if (kbPlayerIsHuman(i) == false || kbPlayerHasLost(i) == true)
         {
            continue;
         }
         if (kbPlayerIsAlly(i) == true)
         {
            debugChats("We still have a human ally in the game, we can't resign.");
            return;
         }
         else
         {
            haveEnemyHuman = true;
         }
      }
   }
   
   static int numResignRequests = 0;
   if (numResignRequests == 3)
   {
      debugChats("We've tried to resign 3 times and got denied each time, assume the player doesn't want us to resign.");
      xsDisableRule("resignMonitor");
      return;
   }

   if (xsGetTime() < 600)
   {
      debugChats("Won't resign now since we're not yet 10 minutes in-game.");
      return;
   }

   if (kbUnitCount(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateAlive) >= 1)
   {
      debugChats("Won't resign now since we still have >= 1 Town Centers left.");
      return;
   }

   if (kbResourceGet(cResourceFood) >= 1000.0 &&
       kbResourceGet(cResourceWood) >= 1000.0 &&
       kbResourceGet(cResourceGold) >= 1000.0 &&
      (kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive) >= 1 ||
       kbUnitCount(cUnitTypeLogicalTypeNorseSoldierThatBuilds, cMyID, cUnitStateAlive) >= 1))
   {
      debugChats("Won't resign now since we still have more than 1000.0 of each resource (excluding favor) and a builder left.");
      return;
   }

   // On a land map the naval syscalls will give back -1 and skew the calc a little, it's fine...
   int currentEconomyPop = aiGetCurrentEconomyPop() + aiGetCurrentNavalEconomyPop();
   if (currentEconomyPop >= 5) // Less than 5, we're in trouble...
   {
      int wantedEconomyPop = aiGetEconomyPop() + aiGetNavalEconomyPop();
      if (wantedEconomyPop < 0)
      {
         aiEchoWarning("Resign logic is still activated while the aiSetEconmyPop syscalls aren't being used, resigning can't function.");
         return;
      }
      float currentEconomicPopPercentage = xsIntToFloat(currentEconomyPop) / xsIntToFloat(wantedEconomyPop);
      debugChats("wantedEconomyPop: " + wantedEconomyPop + ", currentEconomyPop: " + currentEconomyPop +
         ", currentEconomicPopPercentage: " + currentEconomicPopPercentage + ".");
      if (currentEconomicPopPercentage >= 0.20)
      {
         debugChats("We have more or equal to 20 percent of our eco pop, can't resign currently.");
         return;
      }
   }

   // On a land map the naval syscalls will give back -1 and skew the calc a little, it's fine...
   int currentMilitaryPop = aiGetCurrentMilitaryPop() + aiGetCurrentNavalMilitaryPop();
   if (currentMilitaryPop >= 10)  // Less than 10, we're in trouble...
   {
      int wantedMilitaryPop = aiGetMilitaryPop() + aiGetNavalMilitaryPop();
      if (wantedMilitaryPop < 0)
      {
         aiEchoWarning("Resign logic is still activated while the aiSetMilitaryPop syscalls aren't being used, resigning can't function.");
         return;
      }
      float currentMilitaryPopPercentage = xsIntToFloat(currentMilitaryPop) / xsIntToFloat(wantedMilitaryPop);
      debugChats("wantedMilitaryPop: " + wantedMilitaryPop + ", currentMilitaryPop: " + currentMilitaryPop +
         ", currentMilitaryPopPercentage: " + currentMilitaryPopPercentage + ".");
      if (currentMilitaryPopPercentage >= 0.10)
      {
         debugChats("We have more or equal to 10 percent of our military pop, can't resign currently.");
         return;
      }
   }

   // This is mostly relevant for 1v1 situations.
   int queryID = useSimpleUnitQuery(cUnitTypeMilitaryUnit, cPlayerRelationEnemyNotGaia, cUnitStateAlive);
   int numResults = kbUnitQueryExecute(queryID);
   if (numResults < 5)
   {
      debugChats("We don't see more or equal to 5 enemy units, can't resign currently.");
      return;
   }

   // Finally we're rekt, let's try to resign.
   if (haveEnemyHuman == false)
   {
      debugChats("There is no enemy human player in the game, we will instantly resign.");
      aiResign();
      return;
   }
   else
   {
      debugChats("Trying to resign now.");
      aiAttemptResign(cAICommPromptToPlayerAskToResign);
   }
   numResignRequests++;
}

//==============================================================================
// resignHandler
//==============================================================================
void resignHandler(int answerInt = 0)
{
   bool answer = answerInt == 0 ? false : true;
   debugChats("Resign request answer: " + xsBoolToString(answer) + ".");
   if (answer == true)
   {
      aiResign();
   }
   // Don't attempt to resign too quickly again.
   xsSetRuleMinInterval("resignMonitor", 180);
}