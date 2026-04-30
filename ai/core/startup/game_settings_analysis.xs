// We do not have a class for the game settings since there are so few we need to save. So we use globals instead.
void doGameSettingsAnalysis()
{
   debugStartAnalysis("***Analyzing Game Settings***");

   if ((cGameTypeCurrent == cGameTypeCampaign) || (cGameTypeCurrent == cGameTypeScenario))
   {
      aiCommsAllowChat(false);
   }
   else if (cGameTypeCurrent == cGameTypeRandomMap)
   {
      debugStartAnalysis("Map name is: " + cRandomMapName + ".");
      aiCommsSetEventHandler("commHandler");
      xsEnableRule("delayedStartupChat");
      xsEnableRuleGroup("chatRules");
      xsEnableRule("resignMonitor");

      // If we're starting with walls but no gates we're going to assume this is an Arena type map and get some gates.
      if (kbUnitCount(cUnitTypeWallLong, cMyID, cUnitStateAlive) > 0 &&
          kbUnitCount(cUnitTypeWallGate, cMyID, cUnitStateAlive) <= 0 )
      {
         debugStartAnalysis("Arena type map detected, will try to get some gates going soon.");
         xsEnableRule("arenaGates");
      }
   }

   if ((cVictoryTypesCurrent & cVictoryTypeRegicide) != 0)
   {
      xsEnableRule("regicideGarrisonPlanSetup");
   }
   if ((cVictoryTypesCurrent & cVictoryTypeKingOfTheHill) != 0)
   {
      gKOTHTotalTime = kbGetKOTHVictoryTime();
      // CHEAT: lookup the KOTH position.
      xsSetContextPlayer(0);
      int queryID = kbUnitQueryCreate("KOTH");
      kbUnitQuerySetPlayerID(queryID, 0);
      kbUnitQuerySetUnitType(queryID, cUnitTypePlentyVaultKOTH);
      if (kbUnitQueryExecute(queryID) < 1)
      {
         xsSetContextPlayer(cMyID);
         aiEchoWarning("We're in KOTH mode but can't find the Plenty!");
         xsSetContextPlayer(0);
      }
      gKOTHUnitID = kbUnitQueryGetResult(queryID, 0);
      gKOTHPosition = kbUnitGetPosition(gKOTHUnitID);
      kbUnitQueryDestroy(queryID);
      xsSetContextPlayer(cMyID);
      debugStartAnalysis("KOTH plenty ID: " + gKOTHUnitID + ".");
      debugStartAnalysis("KOTH plenty position: " + gKOTHPosition + ".");
   }

   gIsFFA = kbGetIsFFA();

   switch (cDifficultyCurrent)
   {
      case cDifficultyEasy:
      {
         break;
      }
      case cDifficultyModerate:
      {
         break;
      }
      case cDifficultyHard:
      {
         aiSetMicroFlags(cMicroLevelNormal);
         gMicroFlags = cMicroLevelNormal;
         break;
      }
      case cDifficultyTitan:
      {
         aiSetMicroFlags(cMicroLevelHigh);
         gMicroFlags = cMicroLevelHigh;
         break;
      }
      case cDifficultyExtreme:
      {
         float existingHandicap = kbPlayerGetHandicap(cMyID);
         kbPlayerSetHandicap(cMyID, existingHandicap + 0.25); // 25% handicap on top of whatever the lobby set.
         aiSetMicroFlags(cMicroLevelHigh);
         gMicroFlags = cMicroLevelHigh;
         break;
      }
      case cDifficultyLegendary:
      {
         float existingHandicap = kbPlayerGetHandicap(cMyID);
         kbPlayerSetHandicap(cMyID, existingHandicap + 0.50); // 50% handicap on top of whatever the lobby set.
         aiSetMicroFlags(cMicroLevelHigh);
         gMicroFlags = cMicroLevelHigh;
         break;
      }
   }
   // Can't output the handicap here since the handicap is set via a command that is on a little delay.

   // If we have other players that started in a later age we need to fix up the age up arrays.
   int highestOtherPlayerAge = getHighestPlayerAge();
   if (highestOtherPlayerAge >= cAge2)
   {
      gFastestAgeUpTimes[cAge2] = 0;
   }
   if (highestOtherPlayerAge >= cAge3)
   {
      gFastestAgeUpTimes[cAge3] = 0;
   }
   if (highestOtherPlayerAge >= cAge4)
   {
      gFastestAgeUpTimes[cAge4] = 0;
   }

   debugStartAnalysis("Difficulty is " + aiGetWorldDifficultyName(cDifficultyCurrent) + ".");
}