//==============================================================================
/* techs.xs

   This file contains stuffs for managing techs including age upgrades.

*/
//==============================================================================

/*
Techs we never get:
- Oracle
- Temporal Chaos
- SafePassage
*/

//==============================================================================
/* ageUpgradeMonitor
   In this rule we decide what age up option we must go for,
   and what priority we must give it.
*/
//==============================================================================
rule ageUpgradeMonitor
inactive
group defaultArchaicRules
minInterval 10
{
   int currentAge = kbPlayerGetAge(cMyID);
   int maxAge = aiGetMaxAge(cMyID);
   if (maxAge == cAge5)
   {
      maxAge = cAge4; // Wonder age must be excluded here.
   }
   if (currentAge >= maxAge)
   {
      debugTechs("Disabling ageUpgradeMonitor because we're at our maximum allowed age.");
      xsDisableRule("ageUpgradeMonitor");
      return;
   }

   if (checkStrategyFlag(cStrategyFlagAutoAgeUp) == false || kbUnitGetIsIDValid(getUnit(cUnitTypeAbstractSocketedTownCenter)) == false)
   {
      if (aiPlanGetIsIDValid(gAgeUpResearchPlan) == true)
      {
         aiPlanDestroy(gAgeUpResearchPlan);
         gAgeUpResearchPlan = -1;
      }
      return;
   }

   debugTechs("--- Running Rule ageUpgradeMonitor. ---");

   // If there is a human in the game we can only age up if another player has done so before us.
   // If there is no human left in the game we just keep aging up.
   // And if there is another AI on higher difficulty that has already aged up we follow suit, not waiting on the human.
   if (cDifficultyCurrent <= cDifficultyModerate)
   {
      if (getHighestPlayerAge() <= currentAge && getHumanPresentInGame() == true)
      {
         debugTechs("Delaying age up because no player in the game has aged up before us.");
         return;
      }
   }

   int ageUpPriority = 48;
   int currentTime = xsGetTime();
   int fastestAgeUpTimeForNextAge = gFastestAgeUpTimes[currentAge + 1];

   if (fastestAgeUpTimeForNextAge != -1)
   {
      debugTechs("We're behind at least 1 age in comparison to another player in the age, we may need to bump our age up priority.");
      int timeDisparity = currentTime - fastestAgeUpTimeForNextAge;
      debugTechs("The fastest age up to " + getAgeName(currentAge + 1) + " was at " +
         turnNumberIntoTimeDisplay(fastestAgeUpTimeForNextAge) + ", we're " + turnNumberIntoTimeDisplay(timeDisparity) + " behind.");
      int maxDisparity = selectByDifficulty(15 * 60, 12 * 60, 9 * 60, 3 * 60, 3 * 60, 3 * 60);
      debugTechs("We're allowed to be max " + turnNumberIntoTimeDisplay(maxDisparity) + " behind.");
      if (timeDisparity > maxDisparity)
      {
         debugTechs("We're behind in ages for too long, bumping age up priority now.");
         ageUpPriority = 55;
      }
   }
   else
   {
      debugTechs("We're not behind an age, not increasing age up priority because of that.");
   }

   // If we've been in the current age for tresholdTime we start focusing on going to the next age.
   int tresholdTime = selectByDifficulty(15 * 60, 12 * 60, 9 * 60, 6 * 60, 5 * 60, 4 * 60);
   if (gAgeUpTimes[currentAge] + tresholdTime < currentTime)
   {
      debugTechs("We've been in the current age for " + turnNumberIntoTimeDisplay(currentTime - gAgeUpTimes[currentAge]) +
         ", this is longer than our treshold of " + turnNumberIntoTimeDisplay(tresholdTime) + ", bumping age up priority now.");
      ageUpPriority = 55;
   }
   else
   {
      debugTechs("We've been in the current age for " + turnNumberIntoTimeDisplay(currentTime - gAgeUpTimes[currentAge]) +
         ", our treshold for increasing age up prority is " + turnNumberIntoTimeDisplay(tresholdTime) + ".");
   }

   if (gDefenseReflexPanic == true)
   {
      debugTechs("We're currently in defense reflex panic, keep age up priority low until we deal with this threat.");
      ageUpPriority = 48;
   }
   else if (gAttackManager.mKOTHPanic == true)
   {
      debugTechs("We're currently panicking about losing the game to KOTH timer, keep age up priority low for now.");
      ageUpPriority = 48;
   }
   
   debugTechs("Our ageUpPriority is: " + ageUpPriority);
   if (aiPlanGetIsIDValid(gAgeUpResearchPlan) == true)
   {
      aiPlanSetPriority(gAgeUpResearchPlan, ageUpPriority);
   }

   // We have no plan yet so create one.
   else
   {
      int minorGod = -1;
      switch (currentAge)
      {
         case cAge1:
         {
            if (gOverrideClassicalMinorGod >= 0)
            {
               minorGod = gOverrideClassicalMinorGod;
            }
            break;
         }
         case cAge2:
         {
            if (gOverrideHeroicMinorGod >= 0)
            {
               minorGod = gOverrideHeroicMinorGod;
            }
            break;
         }
         case cAge3:
         {
            if (gOverrideMythicMinorGod >= 0)
            {
               minorGod = gOverrideMythicMinorGod;
            }
            break;
         }
      }
      if (minorGod >= 0)
      {
         debugTechs("Override age upgrade with " + kbTechGetName(minorGod) + ".");
      }
      else
      {
         minorGod = aiGetAgeUpListByIndex(currentAge + 1, xsRandBool() == true ? 0 : 1); // Randomly pick an index.
      }

      if (minorGod < 0) // We somehow failed to get a valid age up option so chose the one at index 0.
      {
         minorGod = aiGetAgeUpListByIndex(currentAge + 1, 0);
         aiEchoWarning("We failed to pick an age up option to create a plan for, " +
            "choosing first option from failsafe: " + kbTechGetName(minorGod) + ".");
      }

      // We have managed to pick a minor god (or got defaulted to index 0).
      // So let's create the research plan. If we somehow still don't have one we just don't make a plan.
      if (minorGod >= 0)
      {
         gAgeUpResearchPlan = createSimpleResearchPlan(minorGod, cUnitTypeAbstractSocketedTownCenter, ageUpPriority);
         aiPlanSetEventHandler(gAgeUpResearchPlan, cPlanEventStateChange, "ageUpPlanHandler");
      }
      else
      {
         aiEchoWarning("We completely failed to pick an age up option to make an age up plan for, how could this happen?");
      }
   }
}

//==============================================================================
// getWeightsPerCulture
//==============================================================================
void getWeightsPerCulture(ref int armoryUpgradeChance, ref int lineUpgradeChance, ref int mythUpgradeChance,
   ref int levyUpgradeChance, int currentAge = 0)
{
   switch (cMyCulture)
   {
      case cCultureGreek:
      {
         armoryUpgradeChance = 15;
         lineUpgradeChance = 40;
         mythUpgradeChance = 20 + (currentAge * 5);
         levyUpgradeChance = 55;
         break;
      }
      case cCultureEgyptian:
      {
         armoryUpgradeChance = 15;
         lineUpgradeChance = 50; // There are more line upgrades for Egyptians.
         mythUpgradeChance = 20 + (currentAge * 5);
         levyUpgradeChance = 55;
         break;
      }
      case cCultureNorse:
      {
         armoryUpgradeChance = 15;
         if (cMyCiv == cCivThor)
         {
            armoryUpgradeChance = 25;
         }
         lineUpgradeChance = 40;
         mythUpgradeChance = 20 + (currentAge * 5);
         levyUpgradeChance = 55;
         break;
      }
      case cCultureAtlantean:
      {
         armoryUpgradeChance = 15;
         lineUpgradeChance = 40;
         mythUpgradeChance = 20 + (currentAge * 5);
         levyUpgradeChance = 55;
         break;
      }
   }
}

//==============================================================================
// haveForcedMilitaryTechnologyToResearch
//==============================================================================
bool haveForcedMilitaryTechnologyToResearch(int currentAge = -1)
{
   if (cMyCulture == cCultureEgyptian)
   {
      if (kbTechGetStatus(cTechHandsOfThePharaoh) == cTechStatusObtainable)
      {
         gMilitaryResearchPlan = createSimpleResearchPlan(cTechHandsOfThePharaoh);
         return true;
      }
      if (cMyCiv == cCivRa)
      {
         if (kbTechGetStatus(cTechSkinOfTheRhino) == cTechStatusObtainable)
         {
            gMilitaryResearchPlan = createSimpleResearchPlan(cTechSkinOfTheRhino);
            return true;
         }
      }
   }

   if (cMyCiv == cCivZeus)
   {
      if (currentAge >= cAge3 && kbTechGetStatus(cTechOlympianParentage) == cTechStatusObtainable)
      {
         gMilitaryResearchPlan = createSimpleResearchPlan(cTechOlympianParentage);
         return true;
      }
   }

   if (cMyCulture == cCultureGreek && currentAge >= cAge4 &&
       kbTechGetStatus(cTechForgeOfOlympus) == cTechStatusObtainable)
   {
      gMilitaryResearchPlan = createSimpleResearchPlan(cTechForgeOfOlympus);
      return true;
   }

   if (kbTechGetStatus(cTechBallistics) == cTechStatusObtainable)
   {
      gMilitaryResearchPlan = createSimpleResearchPlan(cTechBallistics);
      return true;
   }

   return false;
}

///////////////////////////////
const int cDebugNotDesired = -1;
const int cArmoryUpgrades = 0;
const int cDockUpgrades = 1;
const int cDockMythUpgrades = 2;
const int cLevyUpgrades = 3;
const int cLineUpgrades = 4;
const int cMythUpgrades = 5;
//==============================================================================
// fillOutMilitaryUpgradeArrays
//==============================================================================
void fillOutMilitaryUpgradeArrays(ref int[] array, int mode = -2)
{
   // ATTENTION: we get all obtainable technologies which means we need to do a lot of filtering + category sorting.
   // The order in which this is done MATTERS, some techs fulfill the condition of multiple types but should be added to the correct one.
   int[] obtainableTechs = kbTechTreeGetAllObtainableTechnologies(false);
   for (int i = 0; i < obtainableTechs.size(); i++)
   {
      int currentTechID = obtainableTechs[i];
      if (kbTechGetFlag(currentTechID, cTechFlagCountsTowardMilitaryScore) == false)
      {
         if (mode == cDebugNotDesired)
         {
            debugTechs(kbTechGetName(currentTechID) + " is not a desired technology for this logic.");
         }
         continue;
      }
      
      // Specific exclusions that we handle via custom logic.
      if (currentTechID == cTechMasons || currentTechID == cTechArchitects || currentTechID == cTechFortifiedTownCenter ||
          currentTechID == cTechOmniscience || currentTechID == cTechDraftHorses || currentTechID == cTechEngineers ||
          currentTechID == cTechTemporalChaos || currentTechID == cTechOracle || currentTechID == cTechYdalir ||
          currentTechID == cTechFeastsOfRenown)
      {
         if (mode == cDebugNotDesired)
         {
            debugTechs(kbTechGetName(currentTechID) + " is not a desired technology for this logic.");
         }
         continue;
      }
      if (currentTechID == cTechFreyrsGift)
      {
         float[] cost = kbTechGetCost(cTechFreyrsGift);
         if (cost[cResourceFavor] > 30.0)
         {
            if (mode == cDebugNotDesired)
            {
               debugTechs(kbTechGetName(currentTechID) + " is not a desired technology for this logic because it's still " + 
                  "costing more than 30.0 favor.");
            }
            continue;
         }
      }
      if (currentTechID == cTechRingOath && kbPlayerGetAge(cMyID) < cAge4)
      {
         if (mode == cDebugNotDesired)
         {
            debugTechs(kbTechGetName(currentTechID) + " is not a desired technology for this logic because we're not in Mythic yet.");
         }
         continue;
      }

      // towerOffensiveUpgradeMonitor handles these upgrades.
      if (kbProtoUnitCanResearch(cUnitTypeSentryTower, currentTechID) == true)
      {
         if (mode == cDebugNotDesired)
         {
            debugTechs(kbTechGetName(currentTechID) + " is not a desired technology for this logic.");
         }
         continue;
      }

      // wallUpgradeMonitor handles these upgrades.
      if (kbProtoUnitCanResearch(cUnitTypeWallLong, currentTechID) == true)
      {
         if (mode == cDebugNotDesired)
         {
            debugTechs(kbTechGetName(currentTechID) + " is not a desired technology for this logic.");
         }
         continue;
      }

      // The order here matters!
      if (kbProtoUnitCanResearch(cUnitTypeDock, currentTechID) == true)
      {
         if (kbTechGetFlag(currentTechID, cTechFlagMythTech) == true)
         {
            if (mode == cDockMythUpgrades)
            {
               debugTechs("Added " + kbTechGetName(currentTechID) + " to Dock myth tech array.");
               array.add(currentTechID);
            }
         }
         else if (mode == cDockUpgrades)
         {
            debugTechs("Added " + kbTechGetName(currentTechID) + " to Dock tech array.");
            array.add(currentTechID);
         }
         continue;
      }
      else if (kbTechGetFlag(currentTechID, cTechFlagMythTech) == true && currentTechID != cTechDwarvenWeapons &&
               currentTechID != cTechMeteoricIronArmor && currentTechID != cTechDragonscaleShields)
      {
         if (mode == cMythUpgrades)
         {
            debugTechs("Added " + kbTechGetName(currentTechID) + " to Myth tech array.");
            array.add(currentTechID);
         }
         continue;
      }
      else if (kbProtoUnitCanResearch(gArmoryUnit, currentTechID) == true)
      {
         if (mode == cArmoryUpgrades)
         {
            debugTechs("Added " + kbTechGetName(currentTechID) + " to Armory tech array.");
            array.add(currentTechID);
         }
         continue;
      }
      else
      {
         // A line/levy upgrade should always only have data effects, but guard against it anyway.
         if (kbTechGetEffectType(currentTechID, 0) != cEffectTypeData)
         {
            aiEchoWarning("Found a technology that we classify as either line or levy which has a non data effect: " +
               kbTechGetName(currentTechID) + ".");
            continue;
         }
         int effectType = kbTechGetDataEffectType(currentTechID, 0);
         if (effectType == cDataEffectTrainPoints)
         {
            if (mode == cLevyUpgrades)
            {
               debugTechs("Added " + kbTechGetName(currentTechID) + " to levy tech array.");
               array.add(currentTechID);
            }
            continue;
         }
         else
         {
            if (mode == cLineUpgrades)
            {
               debugTechs("Added " + kbTechGetName(currentTechID) + " to line tech array.");
               array.add(currentTechID);
            }
            continue;
         }
      }
   }
}

//==============================================================================
// militaryUpgradeManager
//==============================================================================
rule militaryUpgradeManager
inactive
group defaultClassicalRules
minInterval 30
{
   if (cGameModeCurrent == cGameModeDeathmatch)
   {
      xsDisableRule("militaryUpgradeManager");
      return;
   }
   static int progress = 0;
   static int lastAge = -1;
   static int[] techIDs = default;
   static int[] upgradeUnitTypes = default;
   static int[] unitTypesAlive = default;
   static int[] unitTypesPlanned = default;
   static int chosenSegment = -1;
   static int researchStartTime = -1;
   const float cLowPrioArmyPercentage = 0.2;
   const float cHighPrioArmyPercentage = 0.7;

   if (checkStrategyFlag(cStrategyFlagAutoResearchMilitaryUpgrades) == false)
   {
      progress = 0;
      chosenSegment = -1;
      researchStartTime = -1;
      if (aiPlanGetIsIDValid(gMilitaryResearchPlan) == true && aiPlanGetState(gMilitaryResearchPlan) != cPlanStateResearch)
      {
         aiPlanDestroy(gMilitaryResearchPlan);
         gMilitaryResearchPlan = -1;
      }
      return;
   }
   debugTechs("--- Running Rule militaryUpgradeManager. ---");

   int currentTime = xsGetTime();
   int currentMilitaryPop = aiGetCurrentMilitaryPop();
   int allowedMilitaryPop = aiGetMilitaryPop();
   if (aiPlanGetIsIDValid(gMilitaryResearchPlan) == true)
   {
      if (aiPlanGetState(gMilitaryResearchPlan) == cPlanStateResearch || (researchStartTime + 120) > currentTime)
      {
         // Low prio on upgrades when we're low on military, high prio when we have a lot of military.
         int prio = 50;
         float percentageMilitaryPopAliveQueued = xsIntToFloat(currentMilitaryPop) / xsIntToFloat(allowedMilitaryPop);
         if (percentageMilitaryPopAliveQueued < cLowPrioArmyPercentage)
         {
            prio = 49;
         }
         else if (percentageMilitaryPopAliveQueued > cHighPrioArmyPercentage)
         {
            prio = 51;
         }
         aiPlanSetPriority(gMilitaryResearchPlan, prio);
         debugTechs("We're currently already researching a military technology, " +
                    "plan name: " + aiPlanGetName(gMilitaryResearchPlan) + ". Adjusting its priority to " + prio + ".");
         return;
      }
      else
      {
         debugTechs("We had a research plan that didn't go into state research for 2 minutes, destroying it. " +
                    "Plan name: " + aiPlanGetName(gMilitaryResearchPlan) + ".");
         aiPlanDestroy(gMilitaryResearchPlan);
         gMilitaryResearchPlan = -1;
         researchStartTime = -1;
      }
   }
   
   if (progress == 0)
   {
      int currentAge = kbPlayerGetAge(cMyID);
      if (haveForcedMilitaryTechnologyToResearch(currentAge) == true)
      {
         aiPlanSetEventHandler(gMilitaryResearchPlan, cPlanEventStateChange, "resetMilitaryResearchPlan");
         debugTechs("Not running through the default logic because we have a forced technology to research.");
         return;
      }

      techIDs = new int(0, -1);
      if (lastAge == -1) // First run.
      {
         lastAge = currentAge;
      }
      static bool haveAllArmoryUpgrades = false;
      static bool haveAllLevyUpgrades = false;
      static bool haveAllLineUpgrades = false;
      static bool haveAllMythUpgrades = false;
      if (currentAge != cAge5 && lastAge < currentAge)
      {
         // We've aged up and unlocked more upgrades, reset the bools.
         debugTechs("Resetting haveAll bools because we aged up.");
         haveAllArmoryUpgrades = false;
         haveAllLevyUpgrades = false;
         haveAllLineUpgrades = false;
         haveAllMythUpgrades = false;
      }
      lastAge = currentAge;

      if (haveAllArmoryUpgrades == true && haveAllLineUpgrades == true && haveAllMythUpgrades == true && haveAllLevyUpgrades == true)
      {
         if (currentAge >= cAge4)
         {
            debugTechs("Disabling rule militaryUpgradeManager because we have all technologies from it and are in Mythic or Wonder age.");
            xsDisableRule("militaryUpgradeManager");
         }
         return;
      }

      // Base values.
      int armoryUpgradeChance = 0;
      int lineUpgradeChance = 0;
      int mythUpgradeChance = 0;
      int levyUpgradeChance = 0;
      getWeightsPerCulture(armoryUpgradeChance, lineUpgradeChance, mythUpgradeChance, levyUpgradeChance, currentAge);
      // Building an Armory could take as long as the interval of this rule, so guard against rolling that when not available atm.
      bool haveArmory = true;
      if (kbUnitCount(gArmoryUnit, cMyID, cUnitStateAlive) <= 0)
      {
         haveArmory = false;
         armoryUpgradeChance = 0;
      }

      // These will hold the "ranges" that the randInt can roll in.
      int armorySegmentCutoff = -1;
      int lineSegmentCutoff = -1;
      int mythSegmentCutoff = -1;
      int levySegmentCutoff = -1;

      int totalRoll = 0; // All ranges combined.
      if (haveAllArmoryUpgrades == false)
      {
         armorySegmentCutoff = totalRoll + armoryUpgradeChance;
         totalRoll += armoryUpgradeChance;
      }
      if (haveAllLineUpgrades == false)
      {
         lineSegmentCutoff = totalRoll + lineUpgradeChance;
         totalRoll += lineUpgradeChance;
      }
      if (haveAllMythUpgrades == false)
      {
         mythSegmentCutoff = totalRoll + mythUpgradeChance;
         totalRoll += mythUpgradeChance;
      }
      if (haveAllLevyUpgrades == false)
      {
         levySegmentCutoff = totalRoll + levyUpgradeChance;
         totalRoll += levyUpgradeChance;
      }

      debugTechs("totalRoll: " + totalRoll);
      if (totalRoll == 0)
      {
         debugTechs("We don't have everything yet but our totalRoll == 0 because of other limitations (like no Armory), quiting.");
         return;
      }
      debugTechs("armorySegmentCutoff: " + armorySegmentCutoff);
      debugTechs("lineSegmentCutoff: " + lineSegmentCutoff);
      debugTechs("mythSegmentCutoff: " + mythSegmentCutoff);
      debugTechs("levySegmentCutoff: " + levySegmentCutoff);

      // We roll between 1 and totalRoll.
      int rand = xsRandInt(1, totalRoll);
      debugTechs("rand " + rand);

      if (haveArmory == true && armorySegmentCutoff != -1 && rand <= armorySegmentCutoff)
      {
         debugTechs("Chosen to research an armory upgrade!");
         chosenSegment = cArmoryUpgrades;
      }
      else if (lineSegmentCutoff != -1 && rand <= lineSegmentCutoff)
      {
         debugTechs("Chosen to research a line upgrade!");
         chosenSegment = cLineUpgrades;
      }
      else if (mythSegmentCutoff != -1 && rand <= mythSegmentCutoff)
      {
         debugTechs("Chosen to research a myth upgrade!");
         chosenSegment = cMythUpgrades;
      }
      else if (levySegmentCutoff != -1 && rand <= levySegmentCutoff)
      {
         debugTechs("Chosen to research a levy upgrade!");
         chosenSegment = cLevyUpgrades;
      }
      else
      {
         aiEchoWarning("We should never not find a segment in militaryUpgradeManager!");
         return;
      }

      /*
      debugTechs("cDebugNotDesired");
      fillOutMilitaryUpgradeArrays(techIDs, cDebugNotDesired);
      debugTechs("cArmoryUpgrades");
      fillOutMilitaryUpgradeArrays(techIDs, cArmoryUpgrades);
      debugTechs("cDockUpgrades");
      fillOutMilitaryUpgradeArrays(techIDs, cDockUpgrades);
      debugTechs("cLevyUpgrades");
      fillOutMilitaryUpgradeArrays(techIDs, cLevyUpgrades);
      debugTechs("cLineUpgrades");
      fillOutMilitaryUpgradeArrays(techIDs, cLineUpgrades);
      debugTechs("cMythUpgrades");
      fillOutMilitaryUpgradeArrays(techIDs, cMythUpgrades);
      xsDisableSelf();
      return;
      */

      fillOutMilitaryUpgradeArrays(techIDs, chosenSegment);
      if (techIDs.size() == 0)
      {
         debugTechs("We rolled segment " + chosenSegment + " but we can't reserach any technologies in that segment anymore. " +
            "Marking it as completed for now.");
         switch (chosenSegment)
         {
            case cArmoryUpgrades:
            {
               haveAllArmoryUpgrades = true;
               break;
            }
            case cLineUpgrades:
            {
               haveAllLineUpgrades = true;
               break;
            }
            case cMythUpgrades:
            {
               haveAllMythUpgrades = true;
               break;
            }
            case cLevyUpgrades:
            {
               haveAllLevyUpgrades = true;
               break;
            }
         }
         // Go again instantly.
         xsRuleIgnoreIntervalOnce("militaryUpgradeManager");
         progress = 0;
         return;
      }

      progress = 1;
      // Go again instantly.
      xsRuleIgnoreIntervalOnce("militaryUpgradeManager");
      return;
   }

   if (progress == 1)
   {
      // Only line needs this analysis.
      if (chosenSegment == cLineUpgrades)
      {
         int numTechs = techIDs.size();
         upgradeUnitTypes = new int(numTechs, -1);
         unitTypesAlive = new int(numTechs, 0);
         unitTypesPlanned = new int(numTechs, 0);
         for (int i = 0; i < numTechs; i++)
         {
            // We assume here that the first effect of a line upgrade always holds the correct unit type.
            upgradeUnitTypes[i] = kbTechGetDataEffectTargetID(techIDs[i], 0);
            unitTypesAlive[i] = kbUnitCount(upgradeUnitTypes[i], cMyID, cUnitStateAlive);
            debugTechs("We have " + unitTypesAlive[i] + " units alive for " + kbTechGetName(techIDs[i]) + ".");
            // Loop through all our maintain plans, finding plans that train a puid that matches what we upgrade.
            for (int iPlan = 0; iPlan < gNumHumanArcherUnitTypes; iPlan++)
            {
               int planID = gArmyUnitMaintainPlans[gMaintainPlanHumanArcherStartIndex + iPlan];
               if (aiPlanGetIsIDValid(planID) == true)
               {
                  int planUnitType = aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0);
                  // Some line upgrades effect single unit types, find that out here.
                  if (upgradeUnitTypes[i] < cNumberProtoUnits)
                  {
                     if (upgradeUnitTypes[i] == planUnitType)
                     {
                        int numExistingUnits = kbUnitCount(planUnitType, cMyID, cUnitStateAlive);
                        int numLeftToTrain = max(0, aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0) - numExistingUnits);
                        unitTypesPlanned[i] = unitTypesPlanned[i] + numLeftToTrain;
                        debugTechs(aiPlanGetName(planID) + " added " + numLeftToTrain + " planned to " + kbTechGetName(techIDs[i]) + ".");
                     }
                  }
                  else if (kbProtoUnitIsType(planUnitType, upgradeUnitTypes[i]) == true)
                  {
                     int numExistingUnits = kbUnitCount(planUnitType, cMyID, cUnitStateAlive);
                     int numLeftToTrain = max(0, aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0) - numExistingUnits);
                     unitTypesPlanned[i] = unitTypesPlanned[i] + numLeftToTrain;
                     debugTechs(aiPlanGetName(planID) + " added " + numLeftToTrain + " planned to " + kbTechGetName(techIDs[i]) + ".");
                  }
               }
            }
            for (int iPlan = 0; iPlan < gNumHumanMeleeUnitTypes; iPlan++)
            {
               int planID = gArmyUnitMaintainPlans[gMaintainPlanHumanMeleeStartIndex + iPlan];
               if (aiPlanGetIsIDValid(planID) == true)
               {
                  int planUnitType = aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0);
                  // Some line upgrades effect single unit types, find that out here.
                  if (upgradeUnitTypes[i] < cNumberProtoUnits)
                  {
                     if (upgradeUnitTypes[i] == planUnitType)
                     {
                        int numExistingUnits = kbUnitCount(planUnitType, cMyID, cUnitStateAlive);
                        int numLeftToTrain = max(0, aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0) - numExistingUnits);
                        unitTypesPlanned[i] = unitTypesPlanned[i] + numLeftToTrain;
                        debugTechs(aiPlanGetName(planID) + " added " + numLeftToTrain + " planned to " + kbTechGetName(techIDs[i]) + ".");
                     }
                  }
                  else if (kbProtoUnitIsType(planUnitType, upgradeUnitTypes[i]) == true)
                  {
                     int numExistingUnits = kbUnitCount(planUnitType, cMyID, cUnitStateAlive);
                     int numLeftToTrain = max(0, aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0) - numExistingUnits);
                     unitTypesPlanned[i] = unitTypesPlanned[i] + numLeftToTrain;
                     debugTechs(aiPlanGetName(planID) + " added " + numLeftToTrain + " planned to " + kbTechGetName(techIDs[i]) + ".");
                  }
               }
            }
         }
      }

      progress = 2;
      // Go again instantly.
      xsRuleIgnoreIntervalOnce("militaryUpgradeManager");
      return;
   }

   // Actually pick a technology to research from the array we created previous run.
   if (progress == 2)
   {
      int choosenTechID = -1;
      switch (chosenSegment)
      {
         // For these we take the lowest cost one.
         case cArmoryUpgrades:
         case cLevyUpgrades:
         {
            float lowestCost = cMaxFloat;
            for (int i = 0; i < techIDs.size(); i++)
            {
               float cost = kbTechGetCostTotal(techIDs[i]);
               if (cost < lowestCost)
               {
                  lowestCost = cost;
                  choosenTechID = techIDs[i];
               }
            }
            break;
         }
         // Just rand for myth techs.
         case cMythUpgrades:
         {
            int rand = xsRandInt(0, techIDs.size() - 1);
            choosenTechID = techIDs[rand];
            break;
         }
         // Analyze cost / how many units we have / how many units we've planned for line upgrades.
         case cLineUpgrades:
         {
            const int costWeight = 1; // Every 1 resource the upgrade costs will reduce its score by 1.
            const int aliveUnitWeight = 45;
            const int plannedUnitWeight = 60;
            const int militaryUpgradeDamageWeight = 5; // For every 1% the upgrade adds this number gets added to the score.
            const int militaryUpgradeHitpointsWeight = 10; // For every 1% the upgrade adds this number gets added to the score.
            int minimumScoreNeeded = 300;
            debugTechs("Minimum score is: " + minimumScoreNeeded + ".");
            if (haveExcessResourceAmount(1000) == true)
            {
               debugTechs("We have 1000 excess across the board, removing minimum score.");
               minimumScoreNeeded = cMinInt;
            }
            // If we're close to popcap we will barely have any planned units so the minimum score may block upgrades while
            // we should be upgrading our big army.
            if (cDifficultyCurrent >= cDifficultyTitan &&
                buildingGetNumberAliveAndPlanned(gHouseUnit) == kbPlayerGetProtoStatInt(cMyID, gHouseUnit, cProtoStatBuildLimit) &&
                kbPlayerGetPop(cMyID) > (kbPlayerGetPopCap(cMyID) * 0.9))
            {
               debugTechs("We're close to max pop, removing minimum score.");
               minimumScoreNeeded = cMinInt;
            }
            int bestScore = cMinInt;
            for (int i = 0; i < techIDs.size(); i++)
            {
               int score = 0;
               debugTechs("Analyzing " + kbTechGetName(techIDs[i]) + ".");
               int cost = kbTechGetCostTotal(techIDs[i]);
               score -= cost * costWeight;
               debugTechs("   Cost subtracted: " + cost * costWeight);
               score += unitTypesAlive[i] * aliveUnitWeight;
               debugTechs("   Alive units added: " + unitTypesAlive[i] * aliveUnitWeight);
               score += unitTypesPlanned[i] * plannedUnitWeight;
               debugTechs("   Planned units added: " + unitTypesPlanned[i] * plannedUnitWeight);

               int numEffects = kbTechGetNumberEffects(techIDs[i]);
               for (int j = 0; j < numEffects; j++)
               {
                  // We can only analyze data affects.
                  if (kbTechGetEffectType(techIDs[i], j) != cEffectTypeData)
                  {
                     continue;
                  }
                  int effectType = kbTechGetDataEffectType(techIDs[i], j);
                  float amount = kbTechGetDataEffectAmount(techIDs[i], j);
                  switch (effectType)
                  {
                     case cDataEffectDamage:
                     {
                        // Get to the actual % it adds.
                        amount -= 1.0;
                        amount *= 100;
                        score += militaryUpgradeDamageWeight * amount;
                        debugTechs("   Damage weight added: " + militaryUpgradeDamageWeight * amount);
                        break;
                     }
                     case cDataEffectHitpoints:
                     {
                        // Get to the actual % it adds.
                        amount -= 1.0;
                        amount *= 100;
                        score += militaryUpgradeHitpointsWeight * amount;
                        debugTechs("   Hitpoints weight added: " + militaryUpgradeHitpointsWeight * amount);
                        break;
                     }
                  }
               }

               debugTechs(   kbTechGetName(techIDs[i]) + " gets score: " + score + ".");
               if (score > bestScore)
               {
                  bestScore = score;
                  choosenTechID = techIDs[i];
               }
            }
            if (bestScore < minimumScoreNeeded)
            {
               debugTechs("We couldn't find a line upgrade with a high enough score, not researching any now.");
               progress = 0;
               return;
            }
            break;
         }
      }

      // Low prio on upgrades when we're low on military, high prio when we have a lot of military.
      int prio = 50;
      float percentageMilitaryPopAliveQueued = xsIntToFloat(currentMilitaryPop) / xsIntToFloat(allowedMilitaryPop);
      if (percentageMilitaryPopAliveQueued < cLowPrioArmyPercentage)
      {
         prio = 49;
      }
      else if (percentageMilitaryPopAliveQueued > cHighPrioArmyPercentage)
      {
         prio = 51;
      }
      
      gMilitaryResearchPlan = createSimpleResearchPlan(choosenTechID, -1, prio);
      aiPlanSetEventHandler(gMilitaryResearchPlan, cPlanEventStateChange, "resetMilitaryResearchPlan");

      progress = 0;
      chosenSegment = -1;
      researchStartTime = currentTime;
   }
}

//==============================================================================
// dockUpgradeManager
// This doesn't get Fishing upgrades, economyUpgradeManager does that instead.
// Enclosed Deck not covered yet.
//==============================================================================
rule dockUpgradeManager
inactive
group defaultHeroicRules
minInterval 45
{
   if (cGameModeCurrent == cGameModeDeathmatch)
   {
      xsDisableRule("dockUpgradeManager");
      return;
   }
   // Easy doesn't get upgrades.
   if (cDifficultyCurrent == cDifficultyEasy)
   {
      xsDisableRule("dockUpgradeManager");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutoResearchMilitaryUpgrades) == false)
   {
      return;
   }
   debugTechs("--- Running Rule dockUpgradeManager ---");
   
   if (kbTechGetStatus(cTechConscriptSailors) == cTechStatusActive)
   {
      debugTechs("Researched all Dock upgrades, disabling dockUpgradeManager.");
      xsDisableRule("dockUpgradeManager");
      return;
   }

   static int researchStartTime = 0;
   int currentTime = xsGetTime();
   int dockCount = kbUnitCount(cUnitTypeDock, cMyID, cUnitStateAlive);
   if (aiPlanGetIsIDValid(gMilitaryDockResearchPlan) == true)
   {
      if ((researchStartTime + 120) < currentTime && aiPlanGetState(gMilitaryDockResearchPlan) != cPlanStateResearch)
      {
         debugTechs("We had a research plan that didn't go into state research for 2 minutes, destroying it. " +
                    "Plan name: " + aiPlanGetName(gMilitaryDockResearchPlan) + ".");
         aiPlanDestroy(gMilitaryDockResearchPlan);
         gMilitaryDockResearchPlan = -1;
         researchStartTime = -1;
      }
      else
      {
         return;
      }
   }

   if (dockCount <= 0)
   {
      if (aiPlanGetIsIDValid(gMilitaryDockResearchPlan) == true)
      {
         debugTechs("We have no Docks left but had a Dock research plan, destroying it. " +
                    "Plan name: " + aiPlanGetName(gMilitaryDockResearchPlan) + ".");
         aiPlanDestroy(gMilitaryDockResearchPlan);
         gMilitaryDockResearchPlan = -1;
         researchStartTime = -1;
      }
      debugTechs("We have no Docks currently, not attempting to research any naval upgrades.");
      return;
   }

   if (areAtMaxConcurrentResearchPlans("dockUpgradeManager") == true)
   {
      return;
   }

   // First get the line upgrades.
   // Use the != cTechStatusActive here instead of obtainable so that we always enter this even in Heroic when we don't have
   // Champion Warships unlocked. This is so we early out on the age check and only get myth/levy upgrades in Mythic.
   if (kbTechGetStatus(cTechHeavyWarships) != cTechStatusActive ||
       kbTechGetStatus(cTechChampionWarships) != cTechStatusActive)
   {
      int numWarships = kbUnitCount(cUnitTypeAbstractWarship, cMyID, cUnitStateAlive);
      if (kbTechGetStatus(cTechHeavyWarships) == cTechStatusObtainable)
      {
         if (numWarships < 8)
         {
            debugTechs("We have too few war ships, not researching Heavy Warships: " + numWarships + "/8.");
            return;
         }
         gMilitaryDockResearchPlan = createSimpleResearchPlan(cTechHeavyWarships);
         aiPlanSetEventHandler(gMilitaryDockResearchPlan, cPlanEventStateChange, "resetMilitaryDockResearchPlan");
         return;
      }
      if (kbPlayerGetAge(cMyID) <= cAge3)
      {
         debugTechs("Still need to research Champion Warships but we're in Heroic, quiting.");
         return;
      }
      if (numWarships < 13)
      {
         debugTechs("We have too few war ships, not researching Champion Warships: " + numWarships + "/13.");
         return;
      }
      gMilitaryDockResearchPlan = createSimpleResearchPlan(cTechChampionWarships);
      aiPlanSetEventHandler(gMilitaryDockResearchPlan, cPlanEventStateChange, "resetMilitaryDockResearchPlan");
      return;
   }

   // Then get the myth upgrades.
   int[] mythUpgrades = new int(0, -1);
   fillOutMilitaryUpgradeArrays(mythUpgrades, cDockMythUpgrades);
   if (mythUpgrades.size() > 0)
   {
      float lowestCost = cMaxFloat;
      int choosenTechID = -1;
      for (int i = 0; i < mythUpgrades.size(); i++)
      {
         float cost = kbTechGetCostTotal(mythUpgrades[i]);
         if (cost < lowestCost)
         {
            lowestCost = cost;
            choosenTechID = mythUpgrades[i];
         }
      }

      gMilitaryDockResearchPlan = createSimpleResearchPlan(choosenTechID, -1, 49);
      aiPlanSetEventHandler(gMilitaryDockResearchPlan, cPlanEventStateChange, "resetMilitaryDockResearchPlan");
      return;
   }

   // Finally the levy upgrade. It's really unimportant...
   if (kbTechGetStatus(cTechConscriptSailors) == cTechStatusObtainable)
   {
      if (haveExcessResourceAmount(500, cResourceWood) == true)
      {
         gMilitaryDockResearchPlan = createSimpleResearchPlan(cTechConscriptSailors, -1, 49);
         aiPlanSetEventHandler(gMilitaryDockResearchPlan, cPlanEventStateChange, "resetMilitaryDockResearchPlan");
      }
      else
      {
         debugTechs("Not researching Conscript Sailors because we don't have 500 excess wood.");
      }
      return;
   }
}

extern bool gAreResearchingForcedEconomicUpgrade = false;
//==============================================================================
// haveForcedEconomicTechnologyToResearch
//==============================================================================
bool haveForcedEconomicTechnologyToResearch(ref int techID)
{
   int currentAge = kbPlayerGetAge(cMyID);
   if ((cMyCiv == cCivRa || cMyCiv == cCivSet) && gTimeToFarm == true &&
       kbTechGetStatus(cTechShaduf) == cTechStatusObtainable)
   {
      techID = cTechShaduf;
      return true;
   }

   if (currentAge >= cAge2 && gTimeToFarm == true &&
       kbTechGetStatus(cTechPlow) == cTechStatusObtainable)
   {
      techID = cTechPlow;
      return true;
   }

   if (currentAge >= cAge3 &&
       kbTechGetStatus(cTechHuntingEquipment) == cTechStatusObtainable)
   {
      techID = cTechHuntingEquipment;
      return true;
   }

   if ((cMyCiv == cCivHades || cMyCiv == cCivPoseidon) && currentAge >= cAge3)
   {
      if (kbTechGetStatus(cTechDivineBlood) == cTechStatusObtainable)
      {
         techID = cTechDivineBlood;
         return true;
      }
      if (kbTechGetStatus(cTechGoldenApples) == cTechStatusObtainable)
      {
         techID = cTechGoldenApples;
         return true;
      }
   }

   return false;
}

//==============================================================================
// economyUpgradeManager
//==============================================================================
rule economyUpgradeManager
inactive
group defaultClassicalRules
minInterval 30
{
   if (cGameModeCurrent == cGameModeDeathmatch)
   {
      xsDisableRule("economyUpgradeManager");
      return;
   }
   static bool initialized = false;
   static int[] gatherTargets = default;
   static int[] gatherTargetTypes = default;
   static string[] gatherNames = default;
   const int numGatheringCategories = 7;

   if (checkStrategyFlag(cStrategyFlagAutoResearchEconomyUpgrades) == false)
   {
      if (aiPlanGetIsIDValid(gEconomyResearchPlan) == true && aiPlanGetState(gEconomyResearchPlan) != cPlanStateResearch)
      {
         aiPlanDestroy(gEconomyResearchPlan);
         gEconomyResearchPlan = -1;
      }
      return;
   }

   debugTechs("--- Running Rule economyUpgradeManager. ---");
   // Still in research, wait for it to complete, we never cancel midway.
   if (aiPlanGetIsIDValid(gEconomyResearchPlan) == true && aiPlanGetState(gEconomyResearchPlan) == cPlanStateResearch)
   {
      debugTechs("We still have a research plan that is actually researching, quiting early: " + aiPlanGetName(gEconomyResearchPlan));
      return;
   }

   if (initialized == false) // First run.
   {
      gatherTargets = new int(numGatheringCategories, -1);
      gatherTargetTypes = new int(numGatheringCategories, -1);
      gatherNames = new string(numGatheringCategories, "");

      gatherTargets[0] = cUnitTypeBerryBush;
      gatherTargetTypes[0] = cResourceFood;
      gatherNames[0] = "Berries";

      gatherTargets[1] = cUnitTypeHuntable;
      gatherTargetTypes[1] = cResourceFood;
      gatherNames[1] = "Hunters";

      gatherTargets[2] = cUnitTypeHerdable;
      gatherTargetTypes[2] = cResourceFood;
      gatherNames[2] = "Herders";

      gatherTargets[3] = cUnitTypeTree;
      gatherTargetTypes[3] = cResourceWood;
      gatherNames[3] = "Lumberjacks";

      gatherTargets[4] = cUnitTypeGoldResource;
      gatherTargetTypes[4] = cResourceGold;
      gatherNames[4] = "Gold Miners";

      gatherTargets[5] = cUnitTypeFishResource;
      gatherTargetTypes[5] = cResourceFood;
      gatherNames[5] = "Fishing Ships";

      gatherTargets[6] = gFarmUnit;
      gatherTargetTypes[6] = cResourceFood;
      gatherNames[6] = "Farmers";

      initialized = true;
   }

   if (gAreResearchingForcedEconomicUpgrade == true)
   {
      debugTechs("Not running through the default logic because we're already researching a forced technology.");
      return;
   }

   int techID = -1;
   if (haveForcedEconomicTechnologyToResearch(techID) == true)
   {
      if (aiPlanGetIsIDValid(gEconomyResearchPlan) == true)
      {
         debugTechs("Cancelling old research plan since we have a forced tech now, cancelling: " + aiPlanGetName(gEconomyResearchPlan));
         aiPlanDestroy(gEconomyResearchPlan);
      }
      gEconomyResearchPlan = createSimpleResearchPlan(techID);
      aiPlanSetEventHandler(gEconomyResearchPlan, cPlanEventStateChange, "resetEconomyResearchPlan");
      gAreResearchingForcedEconomicUpgrade = true;
      debugTechs("Not running through the default logic because we have a forced technology to research.");
      return;
   }

   int numVillagers = kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive);
   int[] gatherersByTarget = new int(numGatheringCategories, 0);

   for (int i = 0; i < numGatheringCategories; i++)
   {
      if (i == 5)
      {
         gatherersByTarget[i] = kbUnitCount(gFishingUnit, cMyID, cUnitStateAlive);
      }
      else
      {
         gatherersByTarget[i] = aiGetNumberGatherers(cUnitTypeAbstractVillager, gatherTargetTypes[i], -1, gatherTargets[i]);
      }
      debugTechs(gatherNames[i] + " = " + gatherersByTarget[i] + ".");
   }
   
   int bestScore = cMinInt;
   int bestTechID = -1;
   int minimumScoreNeeded = 150;
   if (haveExcessResourceAmount(1000) == true)
   {
      debugTechs("We have 1000 excess across the board, removing minimum score.");
      minimumScoreNeeded = cMinInt;
   }
   const float costWeight = 0.5;
   const int workRateWeight = 50;
   // Double worker weight for Atlanteans because of their Citizens.
   /*const*/ int affectedGatherersWeight = cMyCulture == cCultureAtlantean ? 50 : 25;
   /*const*/ int carryCapacityWeight = cMyCulture == cCultureAtlantean ? 0 : 5;
   /*const*/ int carryCapacityWoodWeight = cMyCulture == cCultureAtlantean ? 0 : 10;
   const int trickleRateWeight = 500;
   int prio = 50;

   int[] obtainableTechs = kbTechTreeGetAllObtainableTechnologies(false);
   for (int i = 0; i < obtainableTechs.size(); i++)
   {
      int currentTechID = obtainableTechs[i];
      if (kbTechGetFlag(currentTechID, cTechFlagCountsTowardEconomicScore) == false)
      {
         continue;
      }
      int numEffects = kbTechGetNumberEffects(currentTechID);
      if (kbTechAffectsUnitType(currentTechID, cUnitTypeAbstractVillager) == false)
      {
         bool resourceTrickle = false;
         for (int j = 0; j < numEffects; j++)
         {
            // We can only analyze data affects.
            if (kbTechGetEffectType(currentTechID, j) != cEffectTypeData)
            {
               continue;
            }
            if (kbTechGetDataEffectType(currentTechID, j) == cDataEffectResourceTrickleRate)
            {
               resourceTrickle = true;
               break;
            }
         }
         if (resourceTrickle == false)
         {
            continue;
         }
      }

      // No support for Hero Citizens yet, so don't get this.
      if (currentTechID == cTechTheftOfFire)
      {
         continue;
      }

      int score = 0;
      int numGatherersAffected = 0;
      score -= kbTechGetCostTotal(currentTechID) * costWeight;

      for (int j = 0; j < numEffects; j++)
      {
         // We can only analyze data affects.
         int effectType = kbTechGetEffectType(currentTechID, j);
         if (effectType != cEffectTypeData)
         {
            continue;
         }

         int dataEffectType = kbTechGetDataEffectType(currentTechID, j);
         float amount = kbTechGetDataEffectAmount(currentTechID, j);

         switch (dataEffectType)
         {
            case cDataEffectWorkRate:
            {
               int unitType = kbTechGetDataEffectData3(currentTechID, j);
               for (int k = 0; k < numGatheringCategories; k++)
               {
                  if (unitType == gatherTargets[k])
                  {
                     score += gatherersByTarget[k] * affectedGatherersWeight;
                     score += amount * workRateWeight;
                     numGatherersAffected += gatherersByTarget[k];
                  }
               }
               break;
            }
            case cDataEffectCarryCapacity:
            {
               int carryCapacityResourceID = kbTechGetDataEffectData2(currentTechID, j);
               if (carryCapacityResourceID == cResourceWood)
               {
                  score += amount * carryCapacityWoodWeight;
               }
               else
               {
                  score += amount * carryCapacityWeight;
               }
               break;
            }
            case cDataEffectResourceTrickleRate:
            {
               //int trickleResourceID = kbTechGetDataEffectData2(currentTechID, j);
               score += amount * trickleRateWeight;
               break;
            }
         }
      }

      debugTechs(kbTechGetName(currentTechID) + " has a total score of: " + score + ".");

      if (score < minimumScoreNeeded)
      {
         continue;
      }

      if (bestScore < score)
      {
         bestTechID = currentTechID;
         bestScore = score;

         if (numGatherersAffected > 10)
         {
            prio = 51;
         }
         else
         {
            prio = 50;
         }
      }
   }

   debugTechs("Minimum score needed: " + minimumScoreNeeded + ".");

   // Reset the plan if we've chosen a new one tech to research.
   if (aiPlanGetIsIDValid(gEconomyResearchPlan) == true)
   {
      if (aiPlanGetVariableInt(gEconomyResearchPlan, cResearchPlanTechID, 0) != bestTechID)
      {
         debugTechs("Cancelling old research plan since our needs have changed, cancelling: " + aiPlanGetName(gEconomyResearchPlan));
         aiPlanDestroy(gEconomyResearchPlan);
         gEconomyResearchPlan = -1;
      }
      else
      {
         aiPlanSetPriority(gEconomyResearchPlan, prio);
         return;
      }
   }

   if (aiPlanGetIsIDValid(gEconomyResearchPlan) == false && bestTechID >= 0)
   {
      gEconomyResearchPlan = createSimpleResearchPlan(bestTechID, -1, prio);
      aiPlanSetEventHandler(gEconomyResearchPlan, cPlanEventStateChange, "resetEconomyResearchPlan");
      debugTechs("Research tech: " + kbTechGetName(bestTechID) + ", it had the highest value of = " + bestScore + ".");      
   }   
}

//==============================================================================
// towerOffensiveUpgradeMonitor
// Gets all the offensive Tower upgrades.
//==============================================================================
rule towerOffensiveUpgradeMonitor
inactive
group defaultClassicalRules
minInterval 60
{
   if (cGameModeCurrent == cGameModeDeathmatch)
   {
      xsDisableRule("towerOffensiveUpgradeMonitor");
      return;
   }
   // Easy doesn't get upgrades.
   if (cDifficultyCurrent == cDifficultyEasy)
   {
      xsDisableRule("towerOffensiveUpgradeMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutoResearchMilitaryUpgrades) == false)
   {
      return;
   }
   debugTechs("--- Running Rule towerOffensiveUpgradeMonitor ---");

   if (areAtMaxConcurrentResearchPlans("towerOffensiveUpgradeMonitor") == true)
   {
      return;
   }

   int towerCount = kbUnitCount(cUnitTypeSentryTower, cMyID, cUnitStateAlive);
   if (towerCount <= 1)
   {
      debugTechs("Not researching any Tower upgrades because we have 1 or fewer Towers left.");
      return;
   }

   int age = kbPlayerGetAge(cMyID);
   if (cPersonalityCurrent == cPersonalityAttacker && age == cAge2)
   {
      debugTechs("Not researching any Tower upgrades because we're attacker personality and still in the Classical Age.");
      return;
   }

   int prio = 51; // Actually get the upgrades with some haste.
   if (cPersonalityCurrent == cPersonalityDefender)
   {
      prio = 55;
   }

   bool researchUpgrade = false;

   if (kbTechGetStatus(cTechWatchTower) == cTechStatusObtainable)
   {
      // Research Watch Tower after 4 minutes being in Classical.
      int time = gAgeUpTimes[cAge2] + 240;
      if (cPersonalityCurrent == cPersonalityDefender)
      {
         time -= 60; // Minute faster.
      }
      if (time < xsGetTime())
      {
         debugTechs("Researching Watch Tower because 4 (3 defender) minutes have passed since we reached the Classical Age.");
         researchUpgrade = true;
      }

      // Get the upgrade if our main base is in peril.
      if (researchUpgrade == false && gDefenseReflexPanic == true)
      {
         debugTechs("Researching Watch Tower because gDefenseReflexPanic == true.");
         researchUpgrade = true;
      }

      // Just always get it if we've aged up further already.
      if (researchUpgrade == false && age >= cAge3)
      {
         debugTechs("Researching Watch Tower because we're already in the Heroic/Mythic Age and don't have it yet.");
         researchUpgrade = true;
      }

      if (researchUpgrade == true)
      {
         researchSimpleTech(cTechWatchTower, cUnitTypeSentryTower, -1, prio);
      }
      else
      {
         debugTechs("We're not ready to research Watch Tower yet.");
      }
      return;
   }

   if (kbTechGetStatus(cTechCrenellations) == cTechStatusObtainable)
   {
      int queryID = useSimpleUnitQuery(cUnitTypeAbstractCavalry, cPlayerRelationEnemyNotGaia);
      int numCavalry = kbUnitQueryExecute(queryID);
      debugTechs("Found " + numCavalry + "/10 for researching Crenellations");
      if (numCavalry >= 10)
      {
         researchSimpleTech(cTechCrenellations, cUnitTypeSentryTower, -1, prio);
         return;
      }
      // We can potentially skip crenellations so don't always return here.
   }

   // Norse can only get Watch Tower / Crenellations.
   // Don't allow moderate to get strong Tower upgrades.
   if (cMyCulture == cCultureNorse || cDifficultyCurrent == cDifficultyModerate)
   {
      if (kbTechGetStatus(cTechCrenellations) == cTechStatusActive)
      {
         debugTechs("Disabling rule towerOffensiveUpgradeMonitor because we got all upgrades we can get/are allowed to get.");
         xsDisableRule("towerOffensiveUpgradeMonitor");
      }
      return;
   }

   if (age <= cAge2)
   {
      return; // Wait for Heroic.
   }

   if (towerCount <= 4)
   {
      debugTechs("Not researching Guard Tower upgrade because we have 4 or fewer Towers left.");
      return;
   }

   if (kbTechGetStatus(cTechGuardTower) == cTechStatusObtainable)
   {
      // Research Guard Tower after 5 minutes being in Heroic.
      int time = 300;
      if (cPersonalityCurrent == cPersonalityDefender)
      {
         time -= 90; // Minute and a half faster.
      }
      if (time < xsGetTime())
      {
         debugTechs("Researching Guard Tower because 5 (3.5 defender) minutes have passed since we reached the Heroic Age.");
         researchUpgrade = true;
      }

      // Get the upgrade if our main base is in peril.
      if (researchUpgrade == false && gDefenseReflexPanic == true)
      {
         debugTechs("Researching Guard Tower because gDefenseReflexPanic == true.");
         researchUpgrade = true;
      }

      // Just always get it if we've aged up further already.
      if (researchUpgrade == false && age >= cAge4)
      {
         debugTechs("Researching Guard Tower because we're already in the Mythic Age and don't have it yet.");
         researchUpgrade = true;
      }

      if (researchUpgrade == true)
      {
         researchSimpleTech(cTechGuardTower, cUnitTypeSentryTower, -1, prio);
      }
      else
      {
         debugTechs("We're not ready to research Guard Tower yet.");
      }
      return;
   }

   // Only Egyptians can get Ballista Tower.
   // Don't allow Hard to get the strongest Tower upgrades.
   if (cMyCulture != cCultureEgyptian || cDifficultyCurrent == cDifficultyHard)
   {
      if (kbTechGetStatus(cTechCrenellations) == cTechStatusActive)
      {
         debugTechs("Disabling rule towerOffensiveUpgradeMonitor because we got all upgrades we can get/are allowed to get.");
         xsDisableRule("towerOffensiveUpgradeMonitor");
      }
      return;
   }

   if (age <= cAge3)
   {
      return; // Wait for Mythic.
   }

   if (towerCount <= 6)
   {
      debugTechs("Not researching Ballista Tower upgrade because we have 6 or fewer Towers left.");
      return;
   }

   if (kbTechGetStatus(cTechBallistaTower) == cTechStatusObtainable)
   {
      // Research Ballista Tower after 8 minutes being in Mythic.
      int time = gAgeUpTimes[cAge4] + 240;
      if (cPersonalityCurrent == cPersonalityDefender)
      {
         time -= 120; // 2 Minutes faster.
      }
      if (time < xsGetTime())
      {
         debugTechs("Researching Ballista Tower because 8 (6 defender) minutes have passed since we reached the Mythic Age.");
         researchUpgrade = true;
      }

      // Get the upgrade if our main base is in peril.
      if (researchUpgrade == false && gDefenseReflexPanic == true)
      {
         debugTechs("Researching Ballista Tower because gDefenseReflexPanic == true.");
         researchUpgrade = true;
      }

      if (researchUpgrade == true)
      {
         researchSimpleTech(cTechBallistaTower, cUnitTypeSentryTower, -1, prio);
      }
      else
      {
         debugTechs("We're not ready to research Ballista Tower yet.");
      }
      return;
   }

   if (kbTechGetStatus(cTechCrenellations) == cTechStatusActive)
   {
      debugTechs("Disabling rule towerOffensiveUpgradeMonitor because we got all upgrades we can get.");
      xsDisableRule("towerOffensiveUpgradeMonitor");
   }
}

//==============================================================================
// towerLOSUpgradeMonitor
// Gets all the LOS Tower upgrades.
//==============================================================================
rule towerLOSUpgradeMonitor
inactive
group defaultClassicalRules
minInterval 60
{
   if (cGameModeCurrent == cGameModeDeathmatch)
   {
      xsDisableRule("towerLOSUpgradeMonitor");
      return;
   }
   // Easy doesn't get upgrades.
   if (cDifficultyCurrent == cDifficultyEasy)
   {
      xsDisableRule("towerLOSUpgradeMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutoResearchEconomyUpgrades) == false)
   {
      return;
   }
   debugTechs("--- Running Rule towerLOSUpgradeMonitor ---");

   if (kbTechGetStatus(cTechSignalFires) == cTechStatusActive &&
       kbTechGetStatus(cTechCarrierPigeons) == cTechStatusActive)
   {
      xsDisableRule("towerLOSUpgradeMonitor");
      return;
   }

   if (areAtMaxConcurrentResearchPlans("towerLOSUpgradeMonitor") == true)
   {
      return;
   }

   int towerCount = kbUnitCount(cUnitTypeSentryTower, cMyID, cUnitStateAlive);
   if (towerCount <= 0)
   {
      debugTechs("Not researching any LOS upgrades atm because we have no Towers left to research them in.");
      return;
   }

   int age = kbPlayerGetAge(cMyID);
   if (cPersonalityCurrent == cPersonalityAttacker && age == cAge2)
   {
      debugTechs("Not researching any LOS upgrades because we're attacker personality and still in the Classical Age.");
      return;
   }

   float currentWoodStockpile = kbResourceGet(cResourceWood);
   if (kbTechGetStatus(cTechSignalFires) == cTechStatusObtainable)
   {
      if (aiPlanGetIDByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechSignalFires) != -1)
      {
         return; // Already getting the upgrade.
      }
      // Not really a useful upgrade, only get if we have a big stockpile of wood.
      if (currentWoodStockpile > 600)
      {
         researchSimpleTech(cTechSignalFires, cUnitTypeSentryTower, -1, 50);
      }
      else
      {
         debugTechs("Not enough stockpiled wood yet to research Signal Fires. " + currentWoodStockpile + "/600.");
      }
      return;
   }

   // Don't get Carrier Pigeons on lower difficulties.
   if (cDifficultyCurrent <= cDifficultyHard)
   {
      xsDisableRule("towerLOSUpgradeMonitor");
      return;
   }

   // Carrier Pigeons is unlocked in Heroic.
   if (age <= cAge2)
   {
      return;
   }

   if (aiPlanGetIDByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechCarrierPigeons) != -1)
   {
      return; // Already getting the upgrade.
   }
   // Carrier Pigeons is not really useful and very expensive. Just make it random when we get it and already have a lot of wood.
   if (haveExcessResourceAmount(500, cResourceWood) == true)
   {
      if (xsRandInt(0, 9) == 0)
      {
         researchSimpleTech(cTechCarrierPigeons, cUnitTypeSentryTower, -1, 50);
      }
      else
      {
         debugTechs("Didn't roll right to start researching Carrier Pigeons.");
      }
   }
   else
   {
      debugTechs("Not enough excess wood yet to attempt researching Carrier Pidgeons.");
   }
}

//==============================================================================
// townCenterUpgradeMonitor
// Gets all the Town Center upgrades.
//==============================================================================
rule townCenterUpgradeMonitor
inactive
group defaultHeroicRules
minInterval 60
{
   if (cGameModeCurrent == cGameModeDeathmatch)
   {
      xsDisableRule("townCenterUpgradeMonitor");
      return;
   }
   // Easy doesn't get upgrades.
   if (cDifficultyCurrent == cDifficultyEasy)
   {
      xsDisableRule("townCenterUpgradeMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutoResearchEconomyUpgrades) == false)
   {
      return;
   }
   debugTechs("--- Running Rule townCenterUpgradeMonitor ---");

   if (kbTechGetStatus(cTechFortifiedTownCenter) == cTechStatusActive &&
       kbTechGetStatus(cTechMasons) == cTechStatusActive &&
       kbTechGetStatus(cTechArchitects) == cTechStatusActive)
   {
      xsDisableRule("townCenterUpgradeMonitor");
      return;
   }

   int tcCount = kbUnitCount(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateAlive);
   if (tcCount <= 0)
   {
      debugTechs("Not researching any Town Center upgrades atm because we have no TCs left to research them in.");
      return;
   }

   if (kbTechGetStatus(cTechFortifiedTownCenter) == cTechStatusObtainable)
   {
      int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechFortifiedTownCenter);
      if (planID >= 0)
      {
         // Potentially bump priority if we already have a plan.
         if (cDifficultyCurrent >= cDifficultyTitan && aiPlanGetPriority(planID) <= 50)
         {
            if (buildingGetNumberAliveAndPlanned(gHouseUnit) == kbPlayerGetProtoStatInt(cMyID, gHouseUnit, cProtoStatBuildLimit) &&
                kbPlayerGetPop(cMyID) > (kbPlayerGetPopCap(cMyID) * 0.9))
            {
               aiPlanSetPriority(planID, 51);
               debugTechs("Found a Fortified Town Center plan that will be bumped in priority to 51 because we're nearly maxed out.");
            }
         }
         debugTechs("Already researching Fortified Town Center, not doing anything else.");
         return;
      }
      else
      {
         bool shouldResearch = false;
         int prio = 50;
         if (cDifficultyCurrent >= cDifficultyTitan &&
             buildingGetNumberAliveAndPlanned(gHouseUnit) == kbPlayerGetProtoStatInt(cMyID, gHouseUnit, cProtoStatBuildLimit) &&
             kbPlayerGetPop(cMyID) > (kbPlayerGetPopCap(cMyID) * 0.9))
         {
            debugTechs("We're at our House build limit and are close to maxing out, getting Fortified Town Center now with high prio.");
            shouldResearch = true;
            prio = 51;
         }
         int time = gAgeUpTimes[cAge3] + 600; // 10 minutes. 
         if (time < xsGetTime())
         {
            shouldResearch = true;
            debugTechs("Researching Fortified Town Center because 10 minutes have passed since we reached the Heroic Age.");
         }
         if (shouldResearch == true)
         {
            researchSimpleTech(cTechFortifiedTownCenter, cUnitTypeAbstractSocketedTownCenter, -1, prio);
         }
      }
      return;
   }

   // Masons + Architects in Mythic for now.
   if (kbPlayerGetAge(cMyID) <= cAge3)
   {
      return;
   }

   // Put Masons + Architects behind the global limit, not fortified.
   if (areAtMaxConcurrentResearchPlans("townCenterUpgradeMonitor") == true)
   {
      return;
   }

   if (kbTechGetStatus(cTechMasons) == cTechStatusObtainable)
   {
      researchSimpleTech(cTechMasons, cUnitTypeAbstractSocketedTownCenter, -1, 50);
   }
   if (kbTechGetStatus(cTechArchitects) == cTechStatusObtainable)
   {
      // If we're already researching we don't want to analyze it again.
      if (aiPlanGetIDByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechArchitects) == -1)
      {
         // Need at least a part of the cost as excess before we get this, cuz it's very expensive.
         if (haveExcessResourceAmount(300, cResourceFood) == true &&
             haveExcessResourceAmount(400, cResourceWood) == true)
         {
            researchSimpleTech(cTechArchitects, cUnitTypeAbstractSocketedTownCenter, -1, 50);
         }
         else
         {
            debugTechs("We don't have enough excess resources to start an Architects research plan.");
         }
      }
   }
}

//==============================================================================
// wallUpgradeMonitor
// Gets all the Wall upgrades.
//==============================================================================
rule wallUpgradeMonitor
inactive
group defaultHeroicRules
minInterval 60
{
   if (cGameModeCurrent == cGameModeDeathmatch)
   {
      xsDisableRule("wallUpgradeMonitor");
      return;
   }
   // Easy doesn't get upgrades.
   if (cDifficultyCurrent == cDifficultyEasy)
   {
      xsDisableRule("wallUpgradeMonitor");
      return;
   }
   // Only defenders currently build walls.
   if (cPersonalityCurrent != cPersonalityDefender)
   {
      xsDisableRule("wallUpgradeMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutoResearchMilitaryUpgrades) == false)
   {
      return;
   }
   debugTechs("--- Running Rule wallUpgradeMonitor ---");

   if (areAtMaxConcurrentResearchPlans("wallUpgradeMonitor") == true)
   {
      return;
   }

   int wallCount = kbUnitCount(cMyID, cUnitTypeAbstractWall, cUnitStateAlive);
   if (wallCount < 5)
   {
      return;
   }
   if (kbTechGetStatus(cTechStoneWall) == cTechStatusObtainable)
   {
      researchSimpleTech(cTechStoneWall);
      return;
   }

   if (cMyCulture == cCultureNorse)
   {
      xsDisableRule("wallUpgradeMonitor");
      return;
   }

   if (wallCount < 10)
   {
      return;
   }

   int wallTech = cTechFortifiedWall;
   if (cMyCulture == cCultureAtlantean)
   {
      wallTech = cTechBronzeWall;
   }
   if (kbTechGetStatus(wallTech) == cTechStatusObtainable)
   {
      researchSimpleTech(wallTech);
      return;
   }

   if (cMyCulture == cCultureGreek)
   {
      xsDisableRule("wallUpgradeMonitor");
      return;
   }
   int currentAge = kbPlayerGetAge(cMyID);
   if (currentAge < cAge4)
   {
      return;
   }

   if (wallCount < 20)
   {
      return;
   }

   if (cMyCulture == cCultureEgyptian)
   {
      if (kbTechGetStatus(cTechCitadelWall) == cTechStatusObtainable)
      {
         if (xsRandInt(0, 9) == 0)
         {
            researchSimpleTech(cTechCitadelWall);
         }
      }
      else
      {
         xsDisableRule("wallUpgradeMonitor");
         return;
      }
   }

   if (cMyCulture == cCultureAtlantean)
   {
      if (kbTechGetStatus(cTechIronWall) == cTechStatusObtainable)
      {
         if (xsRandInt(0, 9) == 0)
         {
            researchSimpleTech(cTechIronWall);
         }
         return;
      }
      
      if (kbTechGetStatus(cTechOrichalcumWall) == cTechStatusObtainable)
      {
         if (xsRandInt(0, 9) == 0)
         {
            researchSimpleTech(cTechOrichalcumWall);
         }
      }
      else
      {
         xsDisableRule("wallUpgradeMonitor");
      }
   }
}

//==============================================================================
// siegeUpgradeMonitor
// Gets all the Siege upgrades.
//==============================================================================
rule siegeUpgradeMonitor
inactive
group defaultMythicRules
minInterval 60
{
   if (cGameModeCurrent == cGameModeDeathmatch)
   {
      xsDisableRule("siegeUpgradeMonitor");
      return;
   }
   // Easy doesn't get upgrades.
   if (cDifficultyCurrent == cDifficultyEasy)
   {
      xsDisableRule("siegeUpgradeMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutoResearchMilitaryUpgrades) == false)
   {
      return;
   }
   debugTechs("--- Running Rule siegeUpgradeMonitor ---");

   if (areAtMaxConcurrentResearchPlans("siegeUpgradeMonitor") == true)
   {
      return;
   }

   // We really want Engineers...
   if (kbTechGetStatus(cTechEngineers) == cTechStatusObtainable)
   {
      researchSimpleTech(cTechEngineers);
      return;
   }

   // That's enough for moderate.
   if (cDifficultyCurrent == cDifficultyModerate)
   {
      xsDisableRule("siegeUpgradeMonitor");
      return;
   }

   if (kbTechGetStatus(cTechDraftHorses) == cTechStatusActive)
   {
      xsDisableRule("siegeUpgradeMonitor");
      return;
   }
   // If we're already researching we don't want to analyze it again.
   if (aiPlanGetIDByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechDraftHorses) == -1)
   {
      // Draft Horses we care less about, only get it if we have some excess.
      if (haveExcessResourceAmount(500, cResourceFood) == true &&
          haveExcessResourceAmount(500, cResourceGold) == true)
      {
         researchSimpleTech(cTechDraftHorses);
      }
   }
}

//==============================================================================
// omniscienceMonitor
//==============================================================================
rule omniscienceMonitor
inactive
group defaultMythicRules
minInterval 60
{
   if (cGameModeCurrent == cGameModeDeathmatch)
   {
      xsDisableRule("omniscienceMonitor");
      return;
   }
   // Easy doesn't get upgrades.
   if (cDifficultyCurrent == cDifficultyEasy)
   {
      xsDisableRule("omniscienceMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutoResearchMilitaryUpgrades) == false)
   {
      return;
   }
   debugTechs("--- Running Rule omniscienceMonitor ---");

   if (kbTechGetStatus(cTechOmniscience) == cTechStatusActive)
   {
      xsDisableRule("omniscienceMonitor");
      return;
   }

   // Already researching?
   if (aiPlanGetIDByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechOmniscience) != -1)
   {
      return;
   }

   float omniscienceCost = kbTechGetCostTotal(cTechOmniscience);
   if (haveExcessResourceAmount(omniscienceCost, cResourceGold) == true)
   {
      researchSimpleTech(cTechOmniscience);
   }
   else
   {
      debugTechs("Don't have enough excess gold to get Omniscience: " + gResourceNeeds[cResourceGold] + "/" + omniscienceCost + ".");
   }
}

//==============================================================================
// secretsOfTheTitansMonitor
// Via the Wonder we can obtain more chances to research Secrets of the Titans, don't disable this rule.
//==============================================================================
rule secretsOfTheTitansMonitor
inactive
group defaultMythicRules
minInterval 60
{
   if (cGameAllowTitans == false)
   {
      xsDisableRule("secretsOfTheTitansMonitor");
      return;
   }
   // We allow Easy to get a titan.
   if (checkStrategyFlag(cStrategyFlagBuildTitan) == false)
   {
      return;
   }
   debugTechs("--- Running Rule secretsOfTheTitansMonitor ---");

   // If we already have a charge of this god power, don't obtain another one.
   if (kbGodPowerGetNumCharges(cProtoPowerTitanGate, cMyID) >= 1)
   {
      return;
   }
   if (kbTechGetStatus(cTechSecretsOfTheTitans) != cTechStatusObtainable)
   {
      return;
   }

   // Are we already researching?
   if (aiPlanGetIDByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechSecretsOfTheTitans) != -1)
   {
      return;
   }

   if (haveExcessResourceAmount(1500) == false)
   {
      debugTechs("We don't have 1.5k excess resources across the board, can't research Secrets of the Titans.");
      return;
   }
   if (kbResourceGet(cResourceFavor) < 50)
   {
      debugTechs("We don't have 50 favor banked, can't research Secrets of the Titans.");
      return;
   }
   // Get this fast now that we have the resources.
   researchSimpleTech(cTechSecretsOfTheTitans, -1, -1, 99);
}

//==============================================================================
// marketUpgradeMonitor
//==============================================================================
rule marketUpgradeMonitor
inactive
group defaultMythicRules
minInterval 60
{
   if (cGameModeCurrent == cGameModeDeathmatch)
   {
      xsDisableRule("marketUpgradeMonitor");
      return;
   }
   // Easy doesn't get upgrades.
   if (cDifficultyCurrent == cDifficultyEasy)
   {
      xsDisableRule("marketUpgradeMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutoResearchEconomyUpgrades) == false)
   {
      return;
   }
   debugTechs("--- Running Rule marketUpgradeMonitor ---");

   if (kbTechGetStatus(cTechTaxCollectors) == cTechStatusActive &&
       kbTechGetStatus(cTechAmbassadors) == cTechStatusActive &&
       kbTechGetStatus(cTechCoinage) == cTechStatusActive)
   {
      xsDisableRule("marketUpgradeMonitor");
      return;
   }

   if (kbUnitCount(gMarketUnit, cMyID, cUnitStateAlive) <= 0)
   {
      debugTechs("We have no Markets currently, not attempting to research any Market upgrades.");
      return;
   }

   if (areAtMaxConcurrentResearchPlans("marketUpgradeMonitor") == true)
   {
      return;
   }

   if (kbTechGetStatus(cTechCoinage) == cTechStatusObtainable &&
       checkStrategyFlag(cStrategyFlagCanTrade) == true)
   {
      int planID = aiPlanGetIDByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechCoinage);
      int numCaravans = kbUnitCount(gCaravanUnit, cMyID, cUnitStateAlive);
      int treshold = 8;
      if (planID != -1)
      {
         if (numCaravans < treshold)
         {
            aiPlanDestroy(planID);
            debugTechs("Destroying Coinage plan because we have too few " + kbProtoUnitGetName(gCaravanUnit) + " left.");
         }
         else if (tradeInformation.mHaveFunctionalTradeRoute == false)
         {
            aiPlanDestroy(planID);
            debugTechs("Destroying Coinage plan because we have no functional trade route left.");
         }
      }
      else // Don't have a plan.
      {
         if (tradeInformation.mHaveFunctionalTradeRoute == false)
         {
            debugTechs("Can't start researching Coinage because we have no functional trade route.");
         }
         else if (numCaravans >= treshold)
         {
            researchSimpleTech(cTechCoinage);
         }
         else
         {
            debugTechs("We have too few " + kbProtoUnitGetName(gCaravanUnit) + ", not researching Coinage: " + numCaravans + "/" +
               treshold + ".");
         }
      }
   }

   if (kbTechGetStatus(cTechTaxCollectors) == cTechStatusObtainable &&
       checkStrategyFlag(cStrategyFlagAutomaticEco) == true)
   {
      if (aiPlanGetIDByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechTaxCollectors) != -1)
      {
         return;
      }
      if (gNumMarketUsage >= 10)
      {
         researchSimpleTech(cTechTaxCollectors);
      }
      else
      {
         debugTechs("We haven't used the Market trading enough, not researching Tax Collectors: " + gNumMarketUsage + "/10.");
      }
      return;
   }

   if (kbTechGetStatus(cTechAmbassadors) == cTechStatusObtainable &&
       checkStrategyFlag(cStrategyFlagAutomaticEco) == true)
   {
      if (aiPlanGetIDByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechAmbassadors) != -1)
      {
         return;
      }
      if (gNumMarketUsage >= 20)
      {
         researchSimpleTech(cTechAmbassadors);
      }
      else
      {
         debugTechs("We haven't used the Market trading enough, not researching Ambassadors: " + gNumMarketUsage + "/20.");
      }
   }
}