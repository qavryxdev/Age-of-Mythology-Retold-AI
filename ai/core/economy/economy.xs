//==============================================================================
/* economy.xs

   This file is intended for economy related stuffs, such as gatherer
   management and resource building construction.

*/
//==============================================================================

//==============================================================================
// calculateNumberGatherers
//==============================================================================
int calculateNumberGatherers(int totalGatherers = -1, float percentage = 0.0)
{
   float temp = totalGatherers * percentage;
   return temp > 0.0 && temp < 1.0 ? 1 : temp;
}

//==============================================================================
/* updateResourceDistribution

   Predict our resource needs based on plan costs.
*/
//==============================================================================
void updateResourceDistribution()
{
   debugResourceDistribution("--- Running updateResourceDistribution() ---");
   static bool firstRun = true;

   float totalPlanFoodNeeded = 0.0;
   float totalPlanWoodNeeded = 0.0;
   float totalPlanGoldNeeded = 0.0;
   float totalPlanFavorNeeded = 0.0;
   int numPlans = aiPlanGetActiveCount();
   debugResourceDistribution("   Number plans: " + numPlans);

   for (int i = 0; i < numPlans; i++)
   {
      int planID = aiPlanGetIDByActiveIndex(i);
      int planType = aiPlanGetType(planID);
      float multiplier = 1.0;
      if (planType == cPlanTrain)
      {
         int trainUnitType = aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0);
         int trainCount = aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0);
         if (kbProtoUnitIsType(trainUnitType, cUnitTypeAbstractVillager) == true)
         {
            if (kbUnitCount(trainUnitType, cMyID, cUnitStateABQ) < trainCount && kbPlayerGetPop(cMyID) < kbPlayerGetPopCap(cMyID))
            {
               // BUG FIX v1.0: povoleno - prioritizuje vyrobu vesnicanu pro rychlejsi ekonomiku
               multiplier = 4.0;
            }
         }
         if (trainUnitType == gFishingUnit)
         {
            if (kbUnitCount(gFishingUnit, cMyID, cUnitStateABQ) < trainCount && kbPlayerGetPop(cMyID) < kbPlayerGetPopCap(cMyID))
            {
               // BUG FIX v1.0: povoleno - prioritizuje vyrobu rybaru
               multiplier = 2.0;
            }
         }
      }
      if (planType == cPlanTrain || planType == cPlanBuild || planType == cPlanBuildWall || planType == cPlanResearch || planType == cPlanRepair)
      {
         if (planType == cPlanResearch)
         {
            int techID = aiPlanGetVariableInt(planID, cResearchPlanTechID, 0);
            // For age upgrades we need to manually fetch the cost because we do want it to be included in these forecasts.
            // But if we haven't met the prereqs yet the standard fetching will give us back 0/0/0/0.
            // Only do this if we're in none state, the other states we already spent the resources and aiPlanGetFutureNeedsCost
            // will pick that up for us.
            if (kbTechGetFlag(techID, cTechFlagAgeUpgrade) == true && aiPlanGetState(planID) == cPlanStateNone)
            {
               float[] techNeeded = kbTechGetCost(techID);
               totalPlanFoodNeeded += techNeeded[cResourceFood] * multiplier;
               totalPlanWoodNeeded += techNeeded[cResourceWood] * multiplier;
               totalPlanGoldNeeded += techNeeded[cResourceGold] * multiplier;
               totalPlanFavorNeeded += techNeeded[cResourceFavor] * multiplier;

               debugResourceDistribution("   Plan: " + aiPlanGetName(planID) + ", needed = (food = " + techNeeded[cResourceFood] +
                  ", wood = " + techNeeded[cResourceWood] + ", gold = " + techNeeded[cResourceGold] +
                  ", favor = " + techNeeded[cResourceFavor] + ")");
               continue;
            }
         }

         float[] planNeeded = aiPlanGetFutureNeedsCost(planID);
         totalPlanFoodNeeded += planNeeded[cResourceFood] * multiplier;
         totalPlanWoodNeeded += planNeeded[cResourceWood] * multiplier;
         totalPlanGoldNeeded += planNeeded[cResourceGold] * multiplier;
         totalPlanFavorNeeded += planNeeded[cResourceFavor] * multiplier;

         debugResourceDistribution("   Plan: " + aiPlanGetName(planID) + ", needed = (food = " + planNeeded[cResourceFood] +
            ", wood = " + planNeeded[cResourceWood] + ", gold = " + planNeeded[cResourceGold] +
            ", favor = " + planNeeded[cResourceFavor] + ")");
      }
   }

   // Additional Houses need to be accounted for.
   if (checkStrategyFlag(cStrategyFlagBuildHouses) == true)
   {
      int numHousesNeeded = calculateNumberHousesNeeded();
      if (numHousesNeeded > 0)
      {
         float woodCost = kbProtoUnitCostPerResource(gHouseUnit, cResourceWood);
         float goldCost = kbProtoUnitCostPerResource(gHouseUnit, cResourceGold); // Atty.
         totalPlanWoodNeeded += woodCost * numHousesNeeded;
         totalPlanGoldNeeded += goldCost * numHousesNeeded; // Atty.
         debugResourceDistribution("   Planning for " + numHousesNeeded + " additional House(s)!");
      }
   }

   // Reserve 100 wood extra for dropsites.
   if (cMyCulture == cCultureGreek && totalPlanWoodNeeded <= 100.0)
   {
      debugResourceDistribution("   Reserving 100 extra wood for dropsites!");
      totalPlanWoodNeeded += 100.0;
   }

   // Keep at least ~30% on Food, which is presumably Farms.
   if (kbGodPowerCheckActive(cProtoPowerRain, cMyID) == true)
   {
      float totalNeed = totalPlanFoodNeeded + totalPlanWoodNeeded + totalPlanGoldNeeded;
      if (totalPlanFoodNeeded < (totalNeed * 0.30))
      {
         totalPlanFoodNeeded = totalNeed * 0.30; // Rough calc.
         debugResourceDistribution("   Artificially increasing our food needs because Rain is active!");
      }
   }
   // Artifically increase our need so we keep a good amount of gatherers on it.
   else if (kbGodPowerCheckActive(cProtoPowerProsperity, cMyID) == true)
   {
      float totalNeed = totalPlanFoodNeeded + totalPlanWoodNeeded + totalPlanGoldNeeded + totalPlanFavorNeeded;
      totalPlanGoldNeeded += (totalNeed / 3);
      debugResourceDistribution("   Artificially increasing our gold needs because Prosperity is active!");
   }

   if (cMyCulture == cCultureGreek)
   {
      // Artificially increase our favor need otherwise we put too few gatherers on it.
      const int favorFactor = 10;
      totalPlanFavorNeeded *= favorFactor;
      debugResourceDistribution("   Artificially increase our favor (x" + favorFactor + ") need otherwise we put too few gatherers on it.");
   }
   
   debugResourceDistribution("   Total plan needs = (food = " + totalPlanFoodNeeded + ", wood = " +
      totalPlanWoodNeeded + ", gold = " + totalPlanGoldNeeded + ", favor = " + totalPlanFavorNeeded +")");

   float foodAmount = kbResourceGet(cResourceFood);
   float woodAmount = kbResourceGet(cResourceWood);
   float goldAmount = kbResourceGet(cResourceGold);
   float favorAmount = kbResourceGet(cResourceFavor);

   debugResourceDistribution("   Total bank = (food = " + foodAmount + ", wood = " + woodAmount +
      ", gold = " + goldAmount + ", favor = " + favorAmount + ")");

   float foodNeeded = totalPlanFoodNeeded - foodAmount;
   float woodNeeded = totalPlanWoodNeeded - woodAmount;
   float goldNeeded = totalPlanGoldNeeded - goldAmount;
   float favorNeeded = totalPlanFavorNeeded - favorAmount;
   debugResourceDistribution("   Resources needed = (food = " + foodNeeded + ", wood = " + woodNeeded +
                             ", gold = " + goldNeeded + ", favor = " + favorNeeded + ")");

   gResourceNeeds[cResourceFood] = foodNeeded;
   gResourceNeeds[cResourceWood] = woodNeeded;
   gResourceNeeds[cResourceGold] = goldNeeded;
   gResourceNeeds[cResourceFavor] = favorNeeded;

   if (foodNeeded < 0.0)
   {
      foodNeeded = 0.0;
   }
   if (woodNeeded < 0.0)
   {
      woodNeeded = 0.0;
   }
   if (goldNeeded < 0.0)
   {
      goldNeeded = 0.0;
   }
   if (favorNeeded < 0.0)
   {
      favorNeeded = 0.0;
   }

   if (gOverrideOkToGatherFood == false)
   {
      foodNeeded = 0.0;
      totalPlanFoodNeeded = 0.0;
   }
   if (gOverrideOkToGatherWood == false)
   {
      woodNeeded = 0.0;
      totalPlanWoodNeeded = 0.0;
   }
   if (gOverrideOkToGatherGold == false)
   {
      goldNeeded = 0.0;
      totalPlanGoldNeeded = 0.0;
   }
   if (gOverrideOkToGatherFavor == false || cMyCulture != cCultureGreek || kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateAlive) == 0)
   {
      favorNeeded = 0.0;
      totalPlanFavorNeeded = 0.0;
   }

   const int cMaxGatherersOnFavor = 8;
   float totalNeeded = goldNeeded + woodNeeded + foodNeeded + favorNeeded;

   float foodPercentage = 0.0;
   float woodPercentage = 0.0;
   float goldPercentage = 0.0;
   float favorPercentage = 0.0;

   float lastFoodPercentage = aiGetResourcePercentage(cResourceFood);
   float lastWoodPercentage = aiGetResourcePercentage(cResourceWood);
   float lastGoldPercentage = aiGetResourcePercentage(cResourceGold);
   float lastFavorPercentage = aiGetResourcePercentage(cResourceFavor);

   // Assume we lose 5 seconds per half minute due to walking.
   const int gatherSeconds = 25;
   float actualFoodRateOverTime = 0.0;
   if (gTimeToFarm == true)
   {
      actualFoodRateOverTime = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeAbstractFarm) * gatherSeconds;
   }
   else
   {
      actualFoodRateOverTime = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeHuntable) * gatherSeconds;
   }
   float actualWoodRateOverTime = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeTree) * gatherSeconds;
   float actualGoldRateOverTime = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeGoldResource) * gatherSeconds;
   float actualFavorRateOverTime = kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeTemple) * gatherSeconds;
   debugResourceDistribution("   Actual gather rates per " + gatherSeconds + " seconds = (food = " + actualFoodRateOverTime + 
      ", wood = " + actualWoodRateOverTime + ", gold = " + actualGoldRateOverTime + ", favor = " + actualFavorRateOverTime + ")");
   if (actualFoodRateOverTime <= 0.0 || actualWoodRateOverTime <= 0.0 || actualGoldRateOverTime <= 0.0 ||
      (cMyCulture == cCultureGreek == true && actualFavorRateOverTime <= 0.0))
   {
      // Echo it as well so we can see where the issue is even if we don't have the right debug bool enabled.
      aiEcho("   Actual gather rates per " + gatherSeconds + " seconds = (food = " + actualFoodRateOverTime + 
      ", wood = " + actualWoodRateOverTime + ", gold = " + actualGoldRateOverTime + ", favor = " + actualFavorRateOverTime + ")");
      aiEchoWarning("Our kbProtoUnitGetGatherRate setup is no longer accurate and we have no rate towards the unit anymore.");
   }

   debugResourceDistribution("*** Calculating sensible gatherer distribution based on the needs/rates above. ***");

   if (totalNeeded > 0.0)
   {
      gAttackManager.mExcessResources = false;
      debugResourceDistribution("   We do NOT have surplus of all resources, calculate how best to split our gatherers to gather what we need.");
      foodPercentage = foodNeeded / totalNeeded;
      woodPercentage = woodNeeded / totalNeeded;
      goldPercentage = goldNeeded / totalNeeded;
      favorPercentage = favorNeeded / totalNeeded;

      debugResourceDistribution("   Initially wanted resource percentages = (food = " + foodPercentage + ", wood = " +
         woodPercentage + ", gold = " + goldPercentage + ", favor = " + favorPercentage + ")");

      int numGatherers = kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive);
      int originalNumGatherers = numGatherers;
      debugResourceDistribution("   numGatherers before any baselines: " + numGatherers);

      // There is rarely a situation where we want 0 gatherers on a resource.
      // But it could be that while we're calling this func our plans + stockpile just happen to say we need 0 of a resource.
      // Instead of then instantly pulling all gatherers off this resource it's best to always keep a baseline on the resource.
      // Because it's 99% sure that a need for that resource will pop up later again.
      const float reservedPercentage = 0.30;
      const float baselinePercentage = 0.15;
      const float baselineFavorPercentage = 0.05;

      int baselineFoodGatherers = 0;
      int baselineWoodGatherers = 0;
      int baselineGoldGatherers = 0;
      int baselineFavorGatherers = 0;
      if (originalNumGatherers > 15)
      {
         debugResourceDistribution("   We have more than 15 gatherers, insert baselines now.");
         baselineFoodGatherers = ceil(numGatherers * baselinePercentage);
         baselineWoodGatherers = ceil(numGatherers * baselinePercentage);
         baselineGoldGatherers = ceil(numGatherers * baselinePercentage);
         baselineFavorGatherers = 0;
         if (cMyCulture == cCultureGreek && kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateAlive) >= 1)
         {
            baselineFavorGatherers = ceil(numGatherers * baselineFavorPercentage);
         }

         foodNeeded -= baselineFoodGatherers * actualFoodRateOverTime;
         woodNeeded -= baselineWoodGatherers * actualWoodRateOverTime;
         goldNeeded -= baselineGoldGatherers * actualGoldRateOverTime;
         favorNeeded -= baselineFavorGatherers * actualFavorRateOverTime;

         numGatherers -= baselineFoodGatherers + baselineWoodGatherers + baselineGoldGatherers + baselineFavorGatherers;
      }
      debugResourceDistribution("   baselineFoodGatherers: " + baselineFoodGatherers);
      debugResourceDistribution("   baselineWoodGatherers: " + baselineWoodGatherers);
      debugResourceDistribution("   baselineGoldGatherers: " + baselineGoldGatherers);
      debugResourceDistribution("   baselineFavorGatherers: " + baselineFavorGatherers);
      debugResourceDistribution("   numGatherers before any reserving: " + numGatherers);

      int numCurrentFoodGatherers = calculateNumberGatherers(numGatherers, lastFoodPercentage);
      int numCurrentWoodGatherers = calculateNumberGatherers(numGatherers, lastWoodPercentage);
      int numCurrentGoldGatherers = calculateNumberGatherers(numGatherers, lastGoldPercentage);
      int numCurrentFavorGatherers = calculateNumberGatherers(numGatherers, lastFavorPercentage);

      debugResourceDistribution("   Current resource gatherer distribution = (food = " + numCurrentFoodGatherers + ", wood = " +
         numCurrentWoodGatherers + ", gold = " + numCurrentGoldGatherers + ", favor = " + numCurrentFavorGatherers + ")");
      
      // Apart from the baseline described above we should also guard against mass migrating the remaining gatherers each update.
      // This we "reserve" 50% of the gatherers on a resource so they're not moveable.
      // This means that over time we can focus on different resources, but it's not a fast process.
      int reservedFoodGatherers = 0;
      int reservedWoodGatherers = 0;
      int reservedGoldGatherers = 0;
      int reservedFavorGatherers = 0;
      if (originalNumGatherers > 30)
      {
         debugResourceDistribution("   We have more than 30 gatherers, insert reserves now.");
         reservedFoodGatherers = ceil(numCurrentFoodGatherers * reservedPercentage);
         reservedWoodGatherers = ceil(numCurrentWoodGatherers * reservedPercentage);
         reservedGoldGatherers = ceil(numCurrentGoldGatherers * reservedPercentage);
         reservedFavorGatherers = 0;
         if (cMyCulture == cCultureGreek && kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateAlive) >= 1)
         {
            reservedFavorGatherers = ceil(numCurrentFavorGatherers * reservedPercentage);
         }

         foodNeeded -= reservedFoodGatherers * actualFoodRateOverTime;
         woodNeeded -= reservedWoodGatherers * actualWoodRateOverTime;
         goldNeeded -= reservedGoldGatherers * actualGoldRateOverTime;
         favorNeeded -= reservedFavorGatherers * actualFavorRateOverTime;

         numCurrentFoodGatherers -= reservedFoodGatherers;
         numCurrentWoodGatherers -= reservedWoodGatherers;
         numCurrentGoldGatherers -= reservedGoldGatherers;
         numCurrentFavorGatherers -= reservedFavorGatherers;

         numGatherers -= reservedFoodGatherers + reservedWoodGatherers + reservedGoldGatherers + reservedFavorGatherers;
      }
      debugResourceDistribution("   reservedFoodGatherers: " + reservedFoodGatherers);
      debugResourceDistribution("   reservedWoodGatherers: " + reservedWoodGatherers);
      debugResourceDistribution("   reservedGoldGatherers: " + reservedGoldGatherers);
      debugResourceDistribution("   reservedFavorGatherers: " + reservedFavorGatherers);
      debugResourceDistribution("   numGatherers after baseline + reserving: " + numGatherers);

      int numForecastedFoodGatherers = calculateNumberGatherers(numGatherers, foodPercentage);
      int numForecastedWoodGatherers = calculateNumberGatherers(numGatherers, woodPercentage);
      int numForecastedGoldGatherers = calculateNumberGatherers(numGatherers, goldPercentage);
      int numForecastedFavorGatherers = calculateNumberGatherers(numGatherers, favorPercentage);

      // Due to that we're working with % and the rounding calculateNumberGatherers does it can happen that
      // our forecasted is bigger than current. We don't adjust here for it but in the end we will have too many
      // freeGatherers so we will reduce that number by our roundingError.
      int roundingError = (numForecastedFoodGatherers + numForecastedWoodGatherers + numForecastedGoldGatherers + numForecastedFavorGatherers)
                           -
                          (numCurrentFoodGatherers + numCurrentWoodGatherers + numCurrentGoldGatherers + numCurrentFavorGatherers);

      debugResourceDistribution("   Forecasted resource gatherer distribution = (food = " + numForecastedFoodGatherers + ", wood = " +
         numForecastedWoodGatherers + ", gold = " + numForecastedGoldGatherers + ", favor = " + numForecastedFavorGatherers + ")");

      int freedGatherers = 0;

      int deltaFoodGatherers = numForecastedFoodGatherers - numCurrentFoodGatherers;
      int deltaWoodGatherers = numForecastedWoodGatherers - numCurrentWoodGatherers;
      int deltaGoldGatherers = numForecastedGoldGatherers - numCurrentGoldGatherers;
      int deltaFavorGatherers = numForecastedFavorGatherers - numCurrentFavorGatherers;

      debugResourceDistribution("   Delta gatherers per resource = (food = " + deltaFoodGatherers + ", wood = " +
         deltaWoodGatherers + ", gold = " + deltaGoldGatherers + ", favor = " + deltaFavorGatherers + ")");

      int sensibleFoodGatherers = numForecastedFoodGatherers;
      int sensibleWoodGatherers = numForecastedWoodGatherers;
      int sensibleGoldGatherers = numForecastedGoldGatherers;
      int sensibleFavorGatherers = numForecastedFavorGatherers;
      if (sensibleFavorGatherers > cMaxGatherersOnFavor)
      {
         // Assign the gatherers that go above the favor cap to food, so we don't "lose" them.
         sensibleFoodGatherers += (sensibleFavorGatherers - cMaxGatherersOnFavor);
         debugResourceDistribution("   Removing " + (sensibleFavorGatherers - cMaxGatherersOnFavor) + " gatherers from favor since " + 
            "we've gone above our cap of " + cMaxGatherersOnFavor + ". Adding these gatherers to food instead. " + 
            "New sensibleFoodGatherers = " + sensibleFoodGatherers);
         sensibleFavorGatherers = cMaxGatherersOnFavor;
      }

      // If we're moving gatherers to another resource it needs to make sense with how much resources we need
      // no point in moving 10 gatherers to food if we just want to gather 25 food.
      if (deltaFoodGatherers > 0)
      {
         int numberSensibleFoodGatherers = ceil(foodNeeded / actualFoodRateOverTime);
         //debugResourceDistribution("   numberSensibleFoodGatherers = " + numberSensibleFoodGatherers + ".");
         if (numberSensibleFoodGatherers < numForecastedFoodGatherers)
         {
            sensibleFoodGatherers = max(numberSensibleFoodGatherers, numCurrentFoodGatherers);
            freedGatherers += (numForecastedFoodGatherers - sensibleFoodGatherers);

            debugResourceDistribution("   Food gatherers freed: " + (numForecastedFoodGatherers - sensibleFoodGatherers));
            debugResourceDistribution("   Overriding forecasted Food gatherers from " + numForecastedFoodGatherers + " to " +
                                      sensibleFoodGatherers + ".");
         }
         else
         {
            sensibleFoodGatherers = numForecastedFoodGatherers;
         }
      }

      if (deltaWoodGatherers > 0)
      {
         int numberSensibleWoodGatherers = ceil(woodNeeded / actualWoodRateOverTime);
         //debugResourceDistribution("   numberSensibleWoodGatherers = " + numberSensibleWoodGatherers + ".");
         if (numberSensibleWoodGatherers < numForecastedWoodGatherers)
         {
            sensibleWoodGatherers = max(numberSensibleWoodGatherers, numCurrentWoodGatherers);
            freedGatherers += (numForecastedWoodGatherers - sensibleWoodGatherers);

            debugResourceDistribution("   Wood gatherers freed: "  + (numForecastedWoodGatherers - sensibleWoodGatherers));
            debugResourceDistribution("   Overriding forecasted Wood gatherers from " + numForecastedWoodGatherers + " to " +
                                      sensibleWoodGatherers + ".");
         }
         else
         {
            sensibleWoodGatherers = numForecastedWoodGatherers;
         }
      }

      if (deltaGoldGatherers > 0)
      {
         int numberSensibleGoldGatherers = ceil(goldNeeded / actualGoldRateOverTime);
         //debugResourceDistribution("   numberSensibleGoldGatherers = " + numberSensibleGoldGatherers + ".");
         if (numberSensibleGoldGatherers < numForecastedGoldGatherers)
         {
            sensibleGoldGatherers = max(numberSensibleGoldGatherers, numCurrentGoldGatherers);
            freedGatherers += (numForecastedGoldGatherers - sensibleGoldGatherers);

            debugResourceDistribution("   Gold gatherers freed: "  + (numForecastedGoldGatherers - sensibleGoldGatherers));
            debugResourceDistribution("   Overriding forecasted Gold gatherers from " + numForecastedGoldGatherers + " to " +
                                      sensibleGoldGatherers + ".");
         }
         else
         {
            sensibleGoldGatherers = numForecastedGoldGatherers;
         }
      }

      if (deltaFavorGatherers > 0)
      {
         int numberSensibleFavorGatherers = ceil(favorNeeded / actualFavorRateOverTime);
         //debugResourceDistribution("   numberSensibleFavorGatherers = " + numberSensibleFavorGatherers + ".");
         if (numberSensibleFavorGatherers < numForecastedFavorGatherers)
         {
            sensibleFavorGatherers = min(max(numberSensibleFavorGatherers, numCurrentFavorGatherers), cMaxGatherersOnFavor);
            freedGatherers += (numForecastedFavorGatherers - sensibleFavorGatherers);

            debugResourceDistribution("   Favor gatherers freed: "  + (numForecastedFavorGatherers - sensibleFavorGatherers));
            debugResourceDistribution("   Overriding forecasted Favor gatherers from " + numForecastedFavorGatherers + " to " +
                                      sensibleFavorGatherers + ".");
         }
         else
         {
            sensibleFavorGatherers = numForecastedFavorGatherers;
         }
      }

      if (roundingError > 0 && freedGatherers > 0)
      {
         freedGatherers -= roundingError;
         debugResourceDistribution("   We had a rounding error of " + roundingError + ", subtracting it from our freedGatherers.");
      }

      debugResourceDistribution("   Total gatherers freed: "  + freedGatherers);
      for (int iFreeGatherer = 0; iFreeGatherer < freedGatherers; iFreeGatherer++)
      {
         if (deltaFoodGatherers < 0)
         {
            deltaFoodGatherers++;
            sensibleFoodGatherers++;
            debugResourceDistribution("   Assigned a free Villager to Food, new deltaFoodGatherers = " + deltaFoodGatherers + ".");
            continue;
         }
         if (deltaWoodGatherers < 0)
         {
            deltaWoodGatherers++;
            sensibleWoodGatherers++;
            debugResourceDistribution("   Assigned a free Villager to Wood, new deltaWoodGatherers = " + deltaWoodGatherers + ".");
            continue;
         }
         if (deltaGoldGatherers < 0)
         {
            deltaGoldGatherers++;
            sensibleGoldGatherers++;
            debugResourceDistribution("   Assigned a free Villager to Gold, new deltaGoldGatherers = " + deltaGoldGatherers + ".");
            continue;
         }
         if (deltaFavorGatherers < 0)
         {
            deltaFavorGatherers++;
            sensibleFavorGatherers++;
            debugResourceDistribution("   Assigned a free Villager to Favor, new deltaFavorGatherers = " + deltaFavorGatherers + ".");
            continue;
         }

         aiEchoWarning("   We have an error in our freed gatherers re-assignment logic!");
      }
      sensibleFoodGatherers += baselineFoodGatherers + reservedFoodGatherers;
      sensibleWoodGatherers += baselineWoodGatherers + reservedWoodGatherers;
      sensibleGoldGatherers += baselineGoldGatherers + reservedGoldGatherers;
      sensibleFavorGatherers += baselineFavorGatherers + reservedFavorGatherers;

      debugResourceDistribution("   FINAL sensible gatherer distribution = (food = " + sensibleFoodGatherers + ", wood = " +
         sensibleWoodGatherers + ", gold = " + sensibleGoldGatherers + ", favor = " + sensibleFavorGatherers + ")");

      foodPercentage = xsIntToFloat(sensibleFoodGatherers) / xsIntToFloat(originalNumGatherers);
      woodPercentage = xsIntToFloat(sensibleWoodGatherers) / xsIntToFloat(originalNumGatherers);
      goldPercentage = xsIntToFloat(sensibleGoldGatherers) / xsIntToFloat(originalNumGatherers);
      favorPercentage = xsIntToFloat(sensibleFavorGatherers) / xsIntToFloat(originalNumGatherers);
   }
   // If we have excess resources of everything we take what our old distribution was and blend it slowly to the inverse
   // of what our excess is
   else
   {
      gAttackManager.mExcessResources = true;
      debugResourceDistribution("   We HAVE surplus of resources, calculate how best to split our gatherers to keep gathering everything.");
      float foodExcess = gResourceNeeds[cResourceFood];
      float woodExcess = gResourceNeeds[cResourceWood];
      float goldExcess = gResourceNeeds[cResourceGold];
      float favorExcess = gResourceNeeds[cResourceFavor];
      
      float totalExcess = goldExcess + woodExcess + foodExcess + favorExcess;
      // Todo come up with a way to calculate a threshold where we just want the previous distribution
      if (totalExcess == 0.0)
      {
         debugResourceDistribution("   Current distribution was good enough");
         return;
      }

      float foodExcessInverseRatio = 1.0 - (foodExcess / totalExcess);
      float woodExcessInverseRatio = 1.0 - (woodExcess / totalExcess);
      float goldExcessInverseRatio = 1.0 - (goldExcess / totalExcess);
      float favorExcessInverseRatio = 1.0 - (favorExcess / totalExcess);

      if (gOverrideOkToGatherFood == false)
      {
         foodExcessInverseRatio = 0.0;
      }
      if (gOverrideOkToGatherWood == false)
      {
         woodExcessInverseRatio = 0.0;
      }
      if (gOverrideOkToGatherGold == false)
      {
         goldExcessInverseRatio = 0.0;
      }
      if (gOverrideOkToGatherFavor == false || cMyCulture != cCultureGreek)
      {
         favorExcessInverseRatio = 0.0;
      }

      // We need to normalize it again since the inverse ratio doesn't preserve normalized values
      float total = foodExcessInverseRatio + woodExcessInverseRatio + goldExcessInverseRatio + favorExcessInverseRatio;
      foodExcessInverseRatio /= total;
      woodExcessInverseRatio /= total;
      goldExcessInverseRatio /= total;
      favorExcessInverseRatio /= total;
      
      // Nothing to blend with
      if (firstRun == true)
      {
         firstRun = false;
         debugResourceDistribution("   We started with excess resources");
         foodPercentage = foodExcessInverseRatio;
         woodPercentage = woodExcessInverseRatio;
         goldPercentage = goldExcessInverseRatio;
         favorPercentage = favorExcessInverseRatio;
      }
      else
      {
         foodPercentage = (lastFoodPercentage + foodExcessInverseRatio) * 0.5;
         woodPercentage = (lastWoodPercentage + woodExcessInverseRatio) * 0.5;
         goldPercentage =  (lastGoldPercentage + goldExcessInverseRatio) * 0.5;
         favorPercentage = (lastFavorPercentage + favorExcessInverseRatio) * 0.5;
      }
   }

   debugResourceDistribution("*** Calculations ended, setting our newly calculated numbers now. ***");

   gRawResourcePercentages[cResourceFood] = foodPercentage;
   gRawResourcePercentages[cResourceWood] = woodPercentage;
   gRawResourcePercentages[cResourceGold] = goldPercentage;
   gRawResourcePercentages[cResourceFavor] = favorPercentage;

   aiSetResourcePercentage(cResourceFood, false, foodPercentage);
   aiSetResourcePercentage(cResourceWood, false, woodPercentage);
   aiSetResourcePercentage(cResourceGold, false, goldPercentage);
   aiSetResourcePercentage(cResourceFavor, false, favorPercentage);
   aiNormalizeResourcePercentages(); // Set them to 1.0 total, just in case these don't add up.

   debugResourceDistribution("   Resource percentages after calculations = (food = " + foodPercentage + 
                             ", wood = " + woodPercentage + ", gold = " + goldPercentage + ", favor = " + favorPercentage + ")");

   gAdjustBreakdownAttempts[cResourceFood] = gAdjustBreakdownAttempts[cResourceFood] + 1;
   gAdjustBreakdownAttempts[cResourceWood] = gAdjustBreakdownAttempts[cResourceWood] + 1;
   gAdjustBreakdownAttempts[cResourceGold] = gAdjustBreakdownAttempts[cResourceGold] + 1;
   gAdjustBreakdownAttempts[cResourceFavor] = gAdjustBreakdownAttempts[cResourceFavor] + 1;
   firstRun = false;
   debugResourceDistribution("--- updateResourceDistribution END ---");
}

//==============================================================================
/* rule marketUsage
   Watch the resource balance, buy/sell imbalanced resources as needed.
*/
//==============================================================================
rule marketUsage
inactive
group defaultClassicalRules
minInterval 30
{
   if (checkStrategyFlag(cStrategyFlagAutomaticEco) == false)
   {
      return;
   }
   debugEconomy("--- Running Rule marketUsage. ---");

   if (kbUnitCount(gMarketUnit, cMyID, cUnitStateAlive) == 0)
   {
      debugEconomy("Found no alive Market, we can't trade resources now.");
      return;
   }
   bool goAgain = false; // Set this bool if we do a buy or sell and want to quickly evaluate.
   static bool fastMode = false; // Set this bool if we enter high-speed mode, clear it on leaving.

   debugEconomy("Food need: " + gResourceNeeds[cResourceFood] + ".");
   debugEconomy("Wood need: " + gResourceNeeds[cResourceWood] + ".");
   debugEconomy("Gold need: " + gResourceNeeds[cResourceGold] + ".");

   // v1.3: lowered minimum-before-trade from 500 to 350 so excess resources are sold sooner,
   // converting idle surpluses into gold for faster army production.
   float foodToTrade = 0.0;
   if (gResourceNeeds[cResourceFood] < 0.0 && kbResourceGet(cResourceFood) > 350.0)
   {
      foodToTrade = -1 * gResourceNeeds[cResourceFood] * 0.8;
   }
   float woodToTrade = 0.0;
   if (gResourceNeeds[cResourceWood] < 0.0 && kbResourceGet(cResourceWood) > 350.0)
   {
      woodToTrade = -1 * gResourceNeeds[cResourceWood] * 0.8;
   }
   float goldToTrade = 0.0;
   if (gResourceNeeds[cResourceGold] < 0.0 && kbResourceGet(cResourceGold) > 350.0)
   {
      goldToTrade = -1 * gResourceNeeds[cResourceGold] * 0.8;
   }

   debugEconomy("foodToTrade: " + foodToTrade + ".");
   debugEconomy("woodToTrade: " + woodToTrade + ".");
   debugEconomy("goldToTrade: " + goldToTrade + ".");

   float foodSellReward = kbGetMarketSellReward(cResourceFood);
   // Sell food if we need gold and have enough food to trade away. "Enough" is determnined by the sell reward.
   if (gResourceNeeds[cResourceGold] > 0.0 && 
       ((foodToTrade >= 100.0 && foodSellReward > 50.0) ||
        (foodToTrade >= 500.0)))
   {
      aiSellResourceOnMarket(cResourceFood);
      gNumMarketUsage++;
      gResourceNeeds[cResourceFood] = gResourceNeeds[cResourceFood] + 100.0;
      gResourceNeeds[cResourceGold] = gResourceNeeds[cResourceGold] - foodSellReward;
      debugEconomy("Selling 100 food for " + foodSellReward + " gold.");
      goAgain = true;
   }

   // TODO this needs an extra check for how many trees we have left to gather from, don't sell our last wood.
   float woodSellReward = kbGetMarketSellReward(cResourceWood);
   // Sell wood if we need gold and have enough wood to trade away. "Enough" is determnined by the sell reward.
   if (gResourceNeeds[cResourceGold] > 0.0 && 
       ((woodToTrade >= 100.0 && woodSellReward > 50.0) ||
        (woodToTrade >= 500.0)))
   {
      aiSellResourceOnMarket(cResourceWood);
      gNumMarketUsage++;
      gResourceNeeds[cResourceWood] = gResourceNeeds[cResourceWood] + 100.0;
      gResourceNeeds[cResourceGold] = gResourceNeeds[cResourceGold] - woodSellReward;
      debugEconomy("Selling 100 wood for " + woodSellReward + " gold.");
      goAgain = true;
   }

   // Be very careful with spending too much gold on buying food/wood.
   if (goldToTrade >= 100.0)
   {
      float foodBuyCost = kbGetMarketBuyCost(cResourceFood);
      float woodBuyCost = kbGetMarketBuyCost(cResourceWood);
      if (gResourceNeeds[cResourceFood] > 0.0 &&
          ((goldToTrade >= 200.0 && foodBuyCost < 50.0) ||
           (goldToTrade >= 500.0 && foodBuyCost < 75.0) ||
           (goldToTrade >= 1000.0 && foodBuyCost < 100.0)))
      {
         aiBuyResourceOnMarket(cResourceFood);
         gNumMarketUsage++;
         gResourceNeeds[cResourceGold] = gResourceNeeds[cResourceGold] + 100.0;
         gResourceNeeds[cResourceFood] = gResourceNeeds[cResourceFood] - foodBuyCost;
         debugEconomy("Buying 100 food for " + foodBuyCost + " gold.");
         goAgain = true;
      }
      else if (gResourceNeeds[cResourceWood] > 0.0 &&
               ((goldToTrade >= 200.0 && woodBuyCost < 50.0) ||
                (goldToTrade >= 500.0 && woodBuyCost < 75.0) ||
                (goldToTrade >= 1000.0))) // Wood is finite, if we have a ton of gold keep purchasing wood regardless.
      {
         aiBuyResourceOnMarket(cResourceWood);
         gNumMarketUsage++;
         gResourceNeeds[cResourceGold] = gResourceNeeds[cResourceGold] + 100.0;
         gResourceNeeds[cResourceWood] = gResourceNeeds[cResourceWood] - woodBuyCost;
         debugEconomy("Buying 100 wood for " + woodBuyCost + " gold.");
         goAgain = true;
      }
   }

   if ((goAgain == true) && (fastMode == false))
   {
      // We need to set fast mode.
      xsSetRuleMinIntervalSelf(1);
      debugEconomy("marketUsage going to fast mode. (1s interval)");
      fastMode = true;
   }
   if ((goAgain == false) && (fastMode == true))
   {
      // We need to slow down.
      xsSetRuleMinIntervalSelf(30);
      debugEconomy("marketUsage going to slow mode. (30s interval)");
      fastMode = false;
   }
}

//==============================================================================
// alertRanOutOfFoodResources / alertFoundFoodResources
//==============================================================================
int cantFindFoodResourcesCounter = 0;
void alertRanOutOfFoodResources()
{
   const int thresholdToStartFarming = 2;
   cantFindFoodResourcesCounter++;
   debugResourceBreakdown("Current cantFindFoodResourcesCounter is at " + cantFindFoodResourcesCounter +
      ". Threshold to start farming is " + thresholdToStartFarming + ".");
   if (cantFindFoodResourcesCounter >= thresholdToStartFarming)
   {
      debugResourceBreakdown("!!! We will start farming now !!!");
      gTimeToFarm = true;
   }
}
void alertFoundFoodResources()
{
   cantFindFoodResourcesCounter = 0;
}

//==============================================================================
/* updateDistributionAndBreakdowns

   Performs top-level economic analysis and direction.
*/
//==============================================================================
rule updateDistributionAndBreakdowns
inactive
group defaultArchaicRules
minInterval 0
{
   if (cStartingResourcesCurrent == cStartingResourcesInfinite)
   {
      aiSetNextGathererDistributionTime(-1);
      xsDisableRule("updateDistributionAndBreakdowns");
      return;
   }

   static int progress = 0;
   static int unassigned = 0;

   if (xsIsRuleGroupEnabled("groupBOSystem") == true || kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive) <= 0)
   {
      unassigned = 0;
      progress = 0;
      return;
   }
   // We use this bool if we want to run our resource distribution a bit later than some other stuff so we have updated resource needs.
   if (gDelayUpdateDistributionAndBreakdowns == true)
   {
      unassigned = 0;
      progress = 0;
      gDelayUpdateDistributionAndBreakdowns = false;
      // If you change this interval number then also change internalBODoEndStep or they're out of sync.
      xsSetRuleMinInterval("updateDistributionAndBreakdowns", 1);
      return;
   }
   // Wait 1 minute after the BO ends with gathering resources in DM, need to build some more.
   if (cGameModeCurrent == cGameModeDeathmatch && (gBOEndTime + 60) > xsGetTime())
   {
      // Just put down as if we have a big surplus, which we have, so other systems can see we got a ton of resources banked.
      gResourceNeeds[cResourceFood] = -5000.0;
      gResourceNeeds[cResourceWood] = -5000.0;
      gResourceNeeds[cResourceGold] = -5000.0;
      gResourceNeeds[cResourceFavor] = -5000.0;
      return;
   }

   if (checkStrategyFlag(cStrategyFlagAutomaticEco) == false)
   {
      unassigned = 0;
      progress = 0;
      gRBDSystem.applyResourceFlags(false, false, false, false);
      aiSetNextGathererDistributionTime(-1);
      return;
   }
   debugEconomy("--- Running Rule updateDistributionAndBreakdowns. ---");

   static int gathererCount = 0;
   static int totalAssigned = 0;
   switch (progress)
   {
      case 0:
      {
         gathererCount = kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive);
         updateResourceDistribution();
         break;
      }
      case 1:
      {
         gRBDSystem.resourceBreakdownUpdateGatherPlanPriorities(gTimeToFarm);
         gRBDSystem.applyResourceFlags(gOverrideOkToGatherFood, gOverrideOkToGatherWood, gOverrideOkToGatherGold, gOverrideOkToGatherFavor);
         gRBDSystem.scanForBases();
         break;
      }
      case 2:
      {
         totalAssigned = 0;
         unassigned = gRBDSystem.resourceBreakdownUpdateExistingFood(gathererCount, (gMicroFlags & cMicroHuntMicro) != 0,
                                                                              totalAssigned);
         break;
      }
      case 3:
      {
         unassigned = gRBDSystem.resourceBreakdownUpdateFood(gTimeToFarm, gOverrideFarmCount, unassigned, gathererCount,
                                                            totalAssigned, (gMicroFlags & cMicroHuntMicro) != 0);
         break;
      }
      case 4:
      {
         unassigned = gRBDSystem.resourceBreakdownUpdateGold(gathererCount, unassigned);
         break;
      }
      case 5:
      {
         unassigned = gRBDSystem.resourceBreakdownUpdateWood(gathererCount, unassigned);
         if (cMyCulture == cCultureGreek)
         {
            gRBDSystem.resourceBreakdownUpdateFavor(gathererCount, unassigned);
         }

         // For all gather plans to update.
         aiSetNextGathererDistributionTime(0);
         // Force all idle Villagers that may now have gone idle due to disappearing plans to find a new plan instantly.
         aiSetUnassignedUnitAssignmentTime(0);
         xsSetRuleMinInterval("updateDistributionAndBreakdowns", 30);
         progress = 0;
         unassigned = 0;
         return; // RETURN.
      }
   }
   xsRuleIgnoreIntervalOnce("updateDistributionAndBreakdowns");
   progress++;
}

//==============================================================================
// villagerToBerserk
// If we have no more builders as Norse we need to check if we can still train some, and otherwise convert a Villager/Dwarf.
//==============================================================================
rule villagerToBerserk
inactive
group defaultArchaicRules
minInterval 30
{
   if (cMyCulture != cCultureNorse)
   {
      xsDisableRule("villagerToBerserk");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagConvertVillagerToBerserk) == false)
   {
      return;
   }
   debugEconomy("--- Running Rule villagerToBerserk. ---");

   if (aiPlanGetIDByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechVillagerNorseToBerserk) >= 0 ||
       aiPlanGetIDByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechVillagerDwarfToBerserk) >= 0)
   {
      debugEconomy("Already have a research plan going to convert a Villager to a Berserk.");
      return;
   }

   // We can't just query for existing train plans. Because what if we have a train plan for Throwing Axeman but have no Longhouses
   // left, then we would wrongly early out. Due to the interval of this rule and the prio 100 of the train plans the chance
   // of creating duplicate train plans isn't high, and also wouldn't be a big problem...

   // Still have one?
   if (kbUnitCount(cUnitTypeLogicalTypeNorseSoldierThatBuilds, cMyID, cUnitStateABQ) >= 1)
   {
      debugEconomy("Still have an alive builder.");
      return;
   }

   // We have no builders alive but maybe do have buildings to create them.
   // We most likely already have a maintain plan lying around for a builder due to automatic military etc...
   // But still we create a new train plan with highest prio to at least crank out 1 builder.

   // Can still train one? Here we need to do a lot of checks because different builders can be build from different buildings.
   int tcCount = kbUnitCount(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateAlive);
   int villageCenterCount =  kbUnitCount(cUnitTypeVillageCenter, cMyID, cUnitStateAlive);
   int longhouseCount = kbUnitCount(cUnitTypeLonghouse, cMyID, cUnitStateAlive);
   int greatHallCount = kbUnitCount(cUnitTypeGreatHall, cMyID, cUnitStateAlive);
   int templeCount = kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateAlive);
   int hillFortCount = kbUnitCount(cUnitTypeHillFort, cMyID, cUnitStateAlive);
   if (tcCount + villageCenterCount + hillFortCount >= 1) // Chose Berserk from TC/VC/HillFort.
   {
      createSimpleTrainPlan(cUnitTypeBerserk, 1, -1, 100);
      debugEconomy("Training a Berserk with highest prio.");
      return;
   }
   if (longhouseCount >= 1) // Chose TA from Longhouse.
   {
      createSimpleTrainPlan(cUnitTypeThrowingAxeman, 1, -1, 100);
      debugEconomy("Training a Berserk with highest prio.");
      return;
   }
   if (templeCount + greatHallCount >= 1) // Chose Hersir from Temple/GreatHall.
   {
      createSimpleTrainPlan(cUnitTypeHersir, 1, -1, 100);
      debugEconomy("Training a Berserk with highest prio.");
      return;
   }

   // Actually no buildings left to train with either, panic!!!

   bool dwarf = false;
   int toTransformID = getUnit(cUnitTypeVillagerNorse);
   if (toTransformID == -1)
   {
      toTransformID = getUnit(cUnitTypeVillagerDwarf);
      dwarf = true;
      if (toTransformID == -1)
      {
         debugEconomy("Can't find any Gatherer/Dwarf to transform.");
         return;
      }
   }

   if (dwarf == true)
   {
      createSimpleResearchPlanSpecificResearcher(cTechVillagerDwarfToBerserk, toTransformID, 100, false);
   }
   else
   {
      createSimpleResearchPlanSpecificResearcher(cTechVillagerNorseToBerserk, toTransformID, 100, false);
   }
}

//==============================================================================
// createFishingPlan
//==============================================================================
void createFishingPlan()
{
   debugEconomy("Creating gather plan for Fish.");
   gFishingPlan = aiPlanCreate("Gather Fish", cPlanFish, -1, gEconomyCategoryID);
   aiPlanAddUnitType(gFishingPlan, gFishingUnit, 0, 0, 200);
   aiPlanSetVariableInt(gFishingPlan, cFishPlanResourceType, 0, cResourceFood);
   aiPlanSetVariableInt(gFishingPlan, cFishPlanResourceSubType, 0, cAIResourceSubTypeFish);
   aiPlanSetVariableInt(gFishingPlan, cFishPlanWaterGroupID, 0, kbAreaGetGroupID(kbAreaGetIDByPosition(gClosestFishLocation)));
   aiPlanSetInitialPosition(gFishingPlan, gClosestFishLocation);
}

bool gHaveValidFishingDock = false;
//==============================================================================
// fishManager
// Updates the Fishing Ship maintain plan.
//==============================================================================
rule fishManager
inactive
group defaultArchaicRules
minInterval 30
{
   if (gMapInfo.mShouldFish == false)
   {
      debugEconomy("Map is not suited for fishing for us, disabling fishManager.");
      xsDisableRule("fishManager");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutomaticFishing) == false)
   {
      if (aiPlanGetIsIDValid(gFishingShipMaintainPlan) == true)
      {
         aiPlanDestroy(gFishingShipMaintainPlan);
      }
      gFishingShipMaintainPlan = -1;
      if (aiPlanGetIsIDValid(gFishingPlan) == true)
      {
         aiPlanDestroy(gFishingPlan);
      }
      gFishingPlan = -1;
      return;
   }
   debugEconomy("--- Running Rule fishManager. ---");

   // Create the plan if it isn't valid (anymore).
   // TODO this needs to change if we swap area groups we fish in.
   if (aiPlanGetIsIDValid(gFishingPlan) == false)
   {
      createFishingPlan();
   }

   int dockID = getClosestUnitByLocation(cUnitTypeDock, cMyID, cUnitStateAlive, gClosestFishLocation, gMaxFishDockScanRange);
   if (dockID == -1)
   {
      debugEconomy("Found no valid Dock to anchor our fishing around, not training any Fishing Ships now.");
      if (aiPlanGetIsIDValid(gFishingShipMaintainPlan) == true)
      {
         aiPlanSetVariableInt(gFishingShipMaintainPlan, cTrainPlanNumberToMaintain, 0, 0);
      }
      gHaveValidFishingDock = false;
      return;
   }

   gHaveValidFishingDock = true;
   // We need to make sure our closest Dock is attached to our fish plan for optimal functionality.
   aiPlanSetVariableInt(gFishingPlan, cFishPlanDockID, 0, dockID);

   int wantedShipsThisAge = 0;

   if (gOverrideMaxFishingShipPop >= 0)
   {
      debugEconomy("Found an override for Fishing Ship maintain, setting it to: " + gOverrideMaxFishingShipPop + ".");
      wantedShipsThisAge = gOverrideMaxFishingShipPop;
   }
   else
   {
      int age = kbPlayerGetAge(cMyID);
      static int wantedShipsArchaicAge = -1;
      static int wantedShipsOtherAges = -1;
      if (wantedShipsArchaicAge == -1)
      {
         wantedShipsArchaicAge = selectByDifficulty(2, 3, 5, 7, 9, 9);
         wantedShipsOtherAges = selectByDifficulty(3, 5, 7, 10, 12, 15);
         if (cGameModeCurrent == cGameModeLightning)
         {
            wantedShipsArchaicAge /= 2;
            wantedShipsOtherAges /= 2;
         }
      }
      int buildLimit = kbPlayerGetProtoStatInt(cMyID, gFishingUnit, cProtoStatBuildLimit);
      if (buildLimit >= 0)
      {
         if (wantedShipsArchaicAge > buildLimit)
         {
            aiEchoWarning("Trying to maintain more Fishing Ships in Archaic than our build limit allows: " + wantedShipsArchaicAge
               + "/" + buildLimit + ".");
            wantedShipsArchaicAge = buildLimit;
         }
         if (wantedShipsOtherAges > buildLimit)
         {
            aiEchoWarning("Trying to maintain more Fishing Ships in >= Classical than our build limit allows: "
               + wantedShipsOtherAges + "/" + buildLimit + ".");
            wantedShipsOtherAges = buildLimit;
         }
      }
      wantedShipsThisAge = age == cAge1 ? wantedShipsArchaicAge : wantedShipsOtherAges;

      // In order for kbGetNumberValidResourcesByPosition to work for Fish we need to provide a point in the water to search from.
      // But we want to do that from the Dock's position, so we need to do some vector math.
      int fishID = getClosestUnitByLocation(cUnitTypeFishResource, 0, cUnitStateAlive, gClosestFishLocation, 10.0);
      if (kbUnitGetIsIDValid(fishID) == false)
      {
         return;
      }
      vector dockPosition = kbUnitGetPosition(dockID);
      vector fishPosition = kbUnitGetPosition(fishID);
      vector step = xsVectorNormalize(fishPosition - dockPosition) * 5; // Big steps, this doesn't need to be mega precise.
      vector scanPosition = cInvalidVector;

      // Let's try 5 times.
      for (int i = 1; i < 6; i++)
      {
         scanPosition = dockPosition + (step * i);
         int areaID = kbAreaGetIDByPosition(scanPosition);
         if (kbAreaGetType(areaID) == cAreaTypeWater)
         {
            break;
         }
      }

      int numberSuitableFishingSpots = kbGetNumberValidResourcesByPosition(scanPosition, cResourceFood,
         cAIResourceSubTypeFish, 50.0) * 3; // Every Fish KB resource has 3 spots normally. TODO this can't handle single spots atm.
      debugEconomy("Found " + numberSuitableFishingSpots + " available fishing spots in range of our Dock.");

      if (wantedShipsThisAge > numberSuitableFishingSpots)
      {
         wantedShipsThisAge = numberSuitableFishingSpots;
      }

      int fishingBoatQuery = useSimpleUnitQuery(gFishingUnit, cMyID, cUnitStateAlive);
      kbUnitQuerySetActionType(fishingBoatQuery, cActionTypeIdle);

      // We have idle ships indicating we don't know what to use them for so don't train more.
      if (kbUnitQueryExecute(fishingBoatQuery) > 1)
      {
         debugEconomy("We found idle Fishing Ships, not training any more now.");
         wantedShipsThisAge = 0;
      }

      if (gMapInfo.mStartOnDifferentIslands == true && wantedShipsThisAge < 1)
      {
         debugEconomy("We were planning on training 0 Fishing Ships but this is an island map, always training 1 for scouting.");
         wantedShipsThisAge = 1; // Train at least 1 Fishing Ship on these maps to explore.
      }
   }

   if (aiPlanGetIsIDValid(gFishingShipMaintainPlan) == false)
   {
      gFishingShipMaintainPlan = createSimpleMaintainPlan(gFishingUnit, 0, -1, 50, -1, cUnitTypeDock, true);
      aiPlanSetName(gFishingShipMaintainPlan, gFishingShipMaintainPlan + " Maintain " + wantedShipsThisAge + " " +
         kbProtoUnitGetName(gFishingUnit));
   }
   else
   {
      if (aiPlanGetVariableInt(gFishingShipMaintainPlan, cTrainPlanNumberToMaintain, 0) != wantedShipsThisAge)
      {
         debugEconomy("Adjusting " + kbProtoUnitGetName(gCaravanUnit) + " Maintain plan to maintain: " + wantedShipsThisAge + ".");
         aiPlanSetVariableInt(gFishingShipMaintainPlan, cTrainPlanNumberToMaintain, 0, wantedShipsThisAge);
         aiPlanSetName(gFishingShipMaintainPlan, gFishingShipMaintainPlan + " Maintain " + wantedShipsThisAge + " " +
            kbProtoUnitGetName(gFishingUnit));
      }
   }

   // Priority based on how many Fishing Ships we already have alive, below 80% alive we have high prio.
   if (kbUnitCount(gFishingUnit, cMyID, cUnitStateAlive) >= (wantedShipsThisAge * 0.8))
   {
      aiPlanSetPriority(gFishingShipMaintainPlan, 50);
   }
   else
   {
      aiPlanSetPriority(gFishingShipMaintainPlan, 70);
   }
}

//==============================================================================
// moveHerdablesToBase
// Moves all the herdables we own and aren't next to the Town Center to our Town Center.
// God powers can create herdables in whatever game we're in, so keep this running.
//==============================================================================
rule moveHerdablesToBase
inactive
group defaultArchaicRules
minInterval 5
{
   if (cStartingResourcesCurrent == cStartingResourcesInfinite)
   {
      xsDisableRule("moveHerdablesToBase");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutomaticHerding) == false)
   {
      return;
   }
   debugEconomy("--- Running Rule moveHerdablesToBase. ---");

   vector searchLocation = kbPlayerGetStartingPosition(cMyID);
   if (searchLocation == cInvalidVector)
   {
      int mainBaseID = kbBaseGetMainID(cMyID);
      if (mainBaseID != -1)
      {
         searchLocation = kbBaseGetLocation(cMyID, mainBaseID);
      }
   }
   int townCenterID = -1;
   if (searchLocation == cInvalidVector)
   {
      townCenterID = getUnit(cUnitTypeAbstractSocketedTownCenter, cMyID);
   }
   else
   {
      townCenterID = getClosestUnitByLocation(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateAlive, searchLocation , 9999.0);
   }
   if (kbUnitGetIsIDValid(townCenterID) == false)
   {
      return;
   }
   int queryID = useSimpleUnitQuery(cUnitTypeHerdable);
   int numResults = kbUnitQueryExecute(queryID);
   vector townCenterLocation = kbUnitGetPosition(townCenterID);
   for (int i = 0; i < numResults; i++)
   {
      int herdableID = kbUnitQueryGetResult(queryID, i);
      float distanceFromTC = xsVectorLength(townCenterLocation - kbUnitGetPosition(herdableID));
      // Anything further away than 13 distance should be sent to the Town Center.
      // This distance means that herdables that are properly next to the Town Center won't be picked up.
      if (distanceFromTC > 13.0)
      {
         // TODO proper system for herding on multiple islands.
         if (gMapInfo.mIsIslandMap == true)
         {
            int tcAreaGroupID = kbAreaGroupGetIDByPosition(kbUnitGetPosition(townCenterID));
            int herdableAreaGroupID = kbAreaGroupGetIDByPosition(kbUnitGetPosition(herdableID));
            if (tcAreaGroupID != herdableAreaGroupID)
            {
               continue;
            }
         }
         debugEconomy("Sent herdable: " + herdableID + " to Town Center: " + townCenterID);
         aiTaskWorkUnit(herdableID, townCenterID);
      }
   }

   kbResourceCombineHerdableResourcesAroundUnit(townCenterID, 13.0);
}

//==============================================================================
// oxCartMaintainMonitor
// Ox Carts are neither economicUnit nor militaryUnit, meaning they can always be trained and have no pop limits like aiSetEconomyPop().
//==============================================================================
rule oxCartMaintainMonitor
inactive
group defaultArchaicRules
minInterval 5
{
   if (cStartingResourcesCurrent == cStartingResourcesInfinite)
   {
      xsDisableRule("oxCartMaintainMonitor");
      return;
   }
   if (cMyCulture != cCultureNorse)
   {
      xsDisableRule("oxCartMaintainMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutomaticOxCartTraining) == false)
   {
      return;
   }
   debugEconomy("--- Running Rule oxCartMaintainMonitor. ---");

   int[] gatherPlans = aiPlanGetIDsByType(cPlanGather);
   int[] plansThatRequireOxCart = new int(0, -1);
   for (int i = 0; i < gatherPlans.size(); i++)
   {
      // These types require no Ox Carts.
      if (aiPlanGetVariableInt(gatherPlans[i], cGatherPlanResourceSubType, 0) == cAIResourceSubTypeFarm ||
          aiPlanGetVariableInt(gatherPlans[i], cGatherPlanResourceSubType, 0) == cAIResourceSubTypeFish||
          aiPlanGetVariableInt(gatherPlans[i], cGatherPlanResourceSubType, 0) == cAIResourceSubTypeHerdable)
      {
         debugEconomy(aiPlanGetName(gatherPlans[i]) + " doesn't require an Ox Cart due to resource subtype.");
         continue;
      }
      if (aiPlanGetVariableInt(gatherPlans[i], cGatherPlanKBResourceID, 0) == -1)
      {
         debugEconomy(aiPlanGetName(gatherPlans[i]) + " can't get an Ox Cart yet due to invalid KB Resource ID.");
         continue;
      }
      // Do we already have an Ox Cart? Count loans because we could be in a garrison child plan situation.
      int[] planUnits = aiPlanGetUnits(gatherPlans[i], cUnitTypeOxCart, true);
      if (planUnits.size() >= 1)
      {
         debugEconomy(aiPlanGetName(gatherPlans[i]) + " already has an Ox Cart.");
         continue;
      }
      int numChildren = aiPlanGetNumberChildren(gatherPlans[i]);
      bool foundOxCartBuildPlan = false;
      for (int iChild = 0; iChild < numChildren; iChild++)
      {
         int childPlanID = aiPlanGetChildIDByIndex(gatherPlans[i], iChild);
         if (aiPlanGetType(childPlanID) != cPlanBuild)
         {
            continue;
         }
         if (aiPlanGetVariableInt(childPlanID, cBuildPlanBuildingTypeID, 0) == cUnitTypeOxCartBuilding)
         {
            foundOxCartBuildPlan = true;
            break;
         }
      }
      if (foundOxCartBuildPlan == true)
      {
         debugEconomy(aiPlanGetName(gatherPlans[i]) + " already has an Ox Cart build plan going.");
         continue;
      }
      // Finally, this gather plan needs an Ox Cart!
      plansThatRequireOxCart.add(gatherPlans[i]);
   }

   if (plansThatRequireOxCart.size() == 0)
   {
      debugEconomy("Found no gather plans that require an Ox Cart build plan.");
      return;
   }

   // Try to find idles and assign them to the closest gather plan.
   int queryID = useSimpleUnitQuery(cUnitTypeOxCart);
   int numOxCarts = kbUnitQueryExecute(queryID);
   int[] units = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < numOxCarts; i++)
   {
      if (kbUnitGetPlanID(units[i]) != -1)
      {
         continue; // Is already in a plan.
      }

      float closestDistance = cMaxFloat;
      int closestPlanID = -1;
      vector oxCartPosition = kbUnitGetPosition(units[i]);
      int[] forbiddenList = aiUnitGetForbiddenPlanIDs(units[i]);
      for (int iPlan = 0; iPlan < plansThatRequireOxCart.size(); iPlan++)
      {
         if (forbiddenList.find(plansThatRequireOxCart[iPlan]) != -1)
         {
            debugEconomy("Ox Cart(" + units[i] + ") is in the forbidden list of " + aiPlanGetName(plansThatRequireOxCart[iPlan]) + ".");
            continue;
         }
         int resourceID = aiPlanGetVariableInt(plansThatRequireOxCart[iPlan], cGatherPlanKBResourceID, 0);
         // Since we need to do pathing we need to fetch the first unit, the center position could be in another area group etc...
         vector resourcePosition = kbUnitGetPosition(kbResourceGetUnit(resourceID, 0));
         float distance = xsVectorDistanceSqr(oxCartPosition, resourcePosition);
         if (distance < closestDistance)
         {
            if (kbCanPath(oxCartPosition, resourcePosition, cUnitTypeOxCart, 1.0) == false)
            {
               debugEconomy("Ox Cart(" + units[i] + ") can't path to " + aiPlanGetName(plansThatRequireOxCart[iPlan]) + ".");
               continue;
            }
            distance = closestDistance;
            closestPlanID = plansThatRequireOxCart[iPlan];
         }
      }
      if (closestPlanID == -1)
      {
         debugEconomy("Couldn't find a suitable plan to add Ox Cart(" + units[i] + ") to.");
         continue;
      }

      aiPlanAddUnit(closestPlanID, units[i]);
      debugEconomy("Assigning idle Ox Cart " + units[i] + " to " + aiPlanGetName(closestPlanID) + ".");
      plansThatRequireOxCart.removeValue(closestPlanID);
      if (plansThatRequireOxCart.size() == 0)
      {
         return;
      }
   }

   for (int i = 0; i < plansThatRequireOxCart.size(); i++)
   {
      if (aiPlanGetNumberUnits(plansThatRequireOxCart[i], -1, false) == 0)
      {
         debugEconomy(aiPlanGetName(plansThatRequireOxCart[i]) + " can't create a build plan because the plan has no units in it.");
         continue;
      }
      debugEconomy("Creating an Ox Cart build plan for " + aiPlanGetName(plansThatRequireOxCart[i]) + ".");
      int planID = aiPlanCreate("Build Dropsite", cPlanBuild, plansThatRequireOxCart[i], gBuildingsCategoryID);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypeOxCartBuilding);
      // Prevents the builers we assign in selectDropsitePlacement being kicked out by the auto assignment before we have a foundation.
      aiPlanSetFlag(planID, cPlanFlagReadyForUnits, true);
      selectDropsitePlacement(planID);
   }
}

//==============================================================================
// saveOxCartsMonitor
//==============================================================================
rule saveOxCartsMonitor
inactive
group defaultArchaicRules
minInterval 15
{
   if (cMyCulture != cCultureNorse)
   {
      xsDisableRule("saveOxCartsMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagAutomaticOxCartTraining) == false)
   {
      return;
   }
   debugEconomy("--- Running Rule saveOxCartsMonitor. ---");

   int queryID = useSimpleUnitQuery(cUnitTypeOxCart);
   int numOxCarts = kbUnitQueryExecute(queryID);
   int[] units = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < numOxCarts; i++)
   {
      if (kbUnitGetPlanID(units[i]) != -1)
      {
         continue; // Is already in a plan.
      }
      vector unitPosition = kbUnitGetPosition(units[i]);
      int tcID = getClosestUnitByLocation(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateAlive, unitPosition, 9999.0);
      if (getUnitCountByLocation(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateAlive, unitPosition, 15.0) >= 1)
      {
         continue; // Don't keep spamming move commands for Ox Carts that are already close to a TC.
      }
      if (tcID != -1)
      {
         aiTaskMoveUnit(units[i], kbUnitGetPosition(tcID));
      }
   }
}

//==============================================================================
// monitorCaravanCounts
//==============================================================================
rule monitorCaravanCounts
inactive
group defaultHeroicRules
minInterval 30
{
   if (cStartingResourcesCurrent == cStartingResourcesInfinite)
   {
      xsDisableRule("monitorCaravanCounts");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagCanTrade) == false)
   {
      if (aiPlanGetIsIDValid(gCaravanMaintainPlan) == true)
      {
         aiPlanDestroy(gCaravanMaintainPlan);
      }
      gCaravanMaintainPlan = -1;
      return;
   }
   debugEconomy("--- Running Rule monitorCaravanCounts. ---");

   int buildLimit = kbPlayerGetProtoStatInt(cMyID, gCaravanUnit, cProtoStatBuildLimit);
   int numCaravansToTrain = 0;
   if (gOverrideMaxCaravanPop >= 0)
   {
      debugEconomy("Override - Setting our wanted Caravans to: " + gOverrideMaxCaravanPop + ".");
      numCaravansToTrain = gOverrideMaxCaravanPop;
   }
   else
   {
      // TODO these maintain amounts should be dynamic based on gold mines available etc.
      numCaravansToTrain = selectByDifficulty(3, 5, 10, 20, 25, 30);
      if (cGameModeCurrent == cGameModeLightning)
      {
         numCaravansToTrain /= 2;
         if (buildLimit >= 0)
         {
            numCaravansToTrain = min(numCaravansToTrain, buildLimit); // BL of 10 in Lightning.
         }
      }
   }
   
   if (buildLimit >= 0 && numCaravansToTrain > buildLimit)
   {
      aiEchoWarning("Trying to maintain more Caravans than our build limit allows: " + numCaravansToTrain + "/" + buildLimit + ".");
      numCaravansToTrain = buildLimit;
   }

   // Create the plan if it isn't valid (anymore).
   if (aiPlanGetIsIDValid(gCaravanMaintainPlan) == false)
   {
      gCaravanMaintainPlan = createSimpleMaintainPlan(gCaravanUnit, numCaravansToTrain, -1, 50, -1, -1, true);
      // The Market ID (buildingID) gets updated dynamically by the trading logic.
      // We also need to set number here explicitly because this variable isn't auto created so we must create it via this too.
      aiPlanSetNumberVariableValues(gCaravanMaintainPlan, cTrainPlanBuildingID, 1);
   }
   else
   {
      if (aiPlanGetVariableInt(gCaravanMaintainPlan, cTrainPlanNumberToMaintain, 0) != numCaravansToTrain)
      {
         debugEconomy("Adjusting " + kbProtoUnitGetName(gCaravanUnit) + " Maintain plan to maintain: " + numCaravansToTrain + ".");
         aiPlanSetVariableInt(gCaravanMaintainPlan, cTrainPlanNumberToMaintain, 0, numCaravansToTrain);
         aiPlanSetName(gCaravanMaintainPlan, gCaravanMaintainPlan + " Maintain " + numCaravansToTrain + " " +
            kbProtoUnitGetName(gCaravanUnit));
      }
   }

   // Priority based on how many Caravans we already have alive, below 80% alive we have high prio.
   if (kbUnitCount(gCaravanUnit, cMyID, cUnitStateAlive) >= (numCaravansToTrain * 0.8))
   {
      aiPlanSetPriority(gCaravanMaintainPlan, 50);
   }
   else
   {
      aiPlanSetPriority(gCaravanMaintainPlan, 70);
   }
}

//==============================================================================
// monitorVillagerCounts
// Sets the Villager maintain plans.
//==============================================================================
rule monitorVillagerCounts
inactive
group defaultArchaicRules
minInterval 30
{
   if (checkStrategyFlag(cStrategyFlagAutomaticVillagerTraining) == false)
   {
      if (aiPlanGetIsIDValid(gVillagerMaintainPlan) == true)
      {
         aiPlanDestroy(gVillagerMaintainPlan);
      }
      gVillagerMaintainPlan = -1;
      if (aiPlanGetIsIDValid(gSecondVillagerMaintainPlan) == true)
      {
         aiPlanDestroy(gSecondVillagerMaintainPlan);
      }
      gSecondVillagerMaintainPlan = -1;
      return;
   }
   debugEconomy("--- Running Rule monitorVillagerCounts. ---");

   // Figure out how many Villagers we want to maintain based on current age + build limits.
   int age = kbPlayerGetAge(cMyID);
   int wantedVilsArchaicAge = selectByDifficulty(15, 15, 20, 20, 20, 20);
   // wantedShipsOtherAges = selectByDifficulty(3,  5,  7,  10, 12,  15);
   // numCaravansToTrain =   selectByDifficulty(3,  5,  10, 20, 25,  30);
   //                                           9,  20, 33, 45, 63,  55.
   int wantedVilsOtherAges = selectByDifficulty(15, 30, 50, 75, 100, 100);
   // Reduce this number by how many Caravans / Fishing Ships we have.
   int numCaravans = kbUnitCount(gCaravanUnit, cMyID, cUnitStateABQ);
   int numFishingShips = kbUnitCount(gFishingUnit, cMyID, cUnitStateABQ);
   wantedVilsOtherAges -= (numCaravans + numFishingShips);
   debugEconomy("Reducing wantedVilsOtherAges(" + wantedVilsOtherAges + ") by " + (numCaravans + numFishingShips) +
      " because of existing Caravans + Fishing Ships.");

   // Don't train too many Villagers when we don't have to gather.
   if (cStartingResourcesCurrent == cStartingResourcesInfinite)
   {
      if (wantedVilsOtherAges > 15)
      {
         wantedVilsOtherAges = 15;
      }
   }

   if (cMyCulture == cCultureAtlantean)
   {
      wantedVilsArchaicAge /= 2;
      wantedVilsOtherAges /= 2;
      debugEconomy("Dividing Villager numbers by 2 because we're Atlantean.");
   }
   if (cGameModeCurrent == cGameModeLightning)
   {
      wantedVilsArchaicAge /= 2;
      wantedVilsOtherAges /= 2;
      debugEconomy("Dividing Villager numbers by 2 because we're playing lightning.");
   }
   
   // This only works since Gatherers have a 100 limit and we never go above this, if done properly we would do this later
   // once we determine that we're going to build > 1 types of Villagers.
   int buildLimit = kbPlayerGetProtoStatInt(cMyID, gEconUnit, cProtoStatBuildLimit);
   if (buildLimit >= 0)
   {
      if (wantedVilsArchaicAge > buildLimit)
      {
         aiEchoWarning("Trying to maintain more Villagers in Archaic than our build limit allows: " + wantedVilsArchaicAge + "/" +
            buildLimit + ".");
         wantedVilsArchaicAge = buildLimit;
      }
      if (wantedVilsOtherAges > buildLimit)
      {
         aiEchoWarning("Trying to maintain more Villagers in >= Classical than our build limit allows: " + wantedVilsOtherAges +
            "/" + buildLimit + ".");
         wantedVilsOtherAges = buildLimit;
      }
   }
   int wantedVilsThisAge = age == cAge1 ? wantedVilsArchaicAge : wantedVilsOtherAges;
   
   // Take our override into account if requested.
   if (gOverrideMaxVillagerPop >= 0)
   {
      debugEconomy("Override - Setting our wanted Vills this age to: " + gOverrideMaxVillagerPop + ".");
      wantedVilsThisAge = gOverrideMaxVillagerPop;
      if (gOverrideMaxVillagerPop > buildLimit)
      {
         aiEchoWarning("Override - Trying to maintain more Villagers than our build limit allows: " + wantedVilsThisAge + "/" +
            buildLimit + ".");
         wantedVilsThisAge = buildLimit;
      }
   }
   else
   {
      debugEconomy("Setting our wanted Vills this age to: " + wantedVilsThisAge + ".");
   }

   if (cMyCulture != cCultureNorse)
   {
      // Create the plan if it isn't valid (anymore).
      if (aiPlanGetIsIDValid(gVillagerMaintainPlan) == false)
      {
         gVillagerMaintainPlan = createSimpleMaintainPlan(gEconUnit, wantedVilsThisAge, -1, 50, -1, -1, true);
      }

      // Adjust the name/maintain numbers if it differs from before.
      if (aiPlanGetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0) != wantedVilsThisAge)
      {
         debugEconomy("Adjusting " + kbProtoUnitGetName(gEconUnit) + " Maintain plan to maintain: " + wantedVilsThisAge + ".");
         aiPlanSetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0, wantedVilsThisAge);
         aiPlanSetName(gVillagerMaintainPlan, gVillagerMaintainPlan + ": Maintain " + wantedVilsThisAge + " " +
                       kbProtoUnitGetName(gEconUnit));
      }

      // Priority based on how many Villagers we already have alive, below 80% alive we have high prio.
      if (kbUnitCount(gEconUnit, cMyID, cUnitStateAlive) >= (wantedVilsThisAge * 0.8))
      {
         aiPlanSetPriority(gVillagerMaintainPlan, 50);
      }
      else
      {
         aiPlanSetPriority(gVillagerMaintainPlan, 70);
      }
   }
   else // Norse.
   {
      // Ceil one here to not lose a Villager.
      int plan1Number = wantedVilsThisAge * 0.7;
      int plan2Number = ceil(wantedVilsThisAge * 0.3);
      if (cMyCiv == cCivThor)
      {
         plan1Number = wantedVilsThisAge * 0.6;
         plan2Number = ceil(wantedVilsThisAge * 0.4);
      }
      // Create the plan if it isn't valid (anymore).
      if (aiPlanGetIsIDValid(gVillagerMaintainPlan) == false)
      {
         gVillagerMaintainPlan = createSimpleMaintainPlan(gEconUnit, plan1Number, -1, 50, -1, -1, true);
      }
      // Create the plan if it isn't valid (anymore).
      if (aiPlanGetIsIDValid(gSecondVillagerMaintainPlan) == false)
      {
         gSecondVillagerMaintainPlan = createSimpleMaintainPlan(cUnitTypeVillagerDwarf, plan2Number, -1, 50, -1, -1, true);
      }

      // Adjust the name/maintain numbers if it differs from before.
      if (aiPlanGetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0) != plan1Number)
      {
         debugEconomy("Adjusting " + kbProtoUnitGetName(gEconUnit) + " Maintain plan to maintain: " + plan1Number + ".");
         aiPlanSetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0, plan1Number);
         aiPlanSetName(gVillagerMaintainPlan, gVillagerMaintainPlan + " Maintain " + plan1Number + " " +
                       kbProtoUnitGetName(gEconUnit));
      }
      if (aiPlanGetVariableInt(gSecondVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0) != plan2Number)
      {
         debugEconomy("Adjusting " + kbProtoUnitGetName(cUnitTypeVillagerDwarf) + " Maintain plan to maintain: " + plan2Number + ".");
         aiPlanSetVariableInt(gSecondVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0, plan2Number);
         aiPlanSetName(gSecondVillagerMaintainPlan, gSecondVillagerMaintainPlan + ": Maintain " + plan2Number + " " +
                       kbProtoUnitGetName(cUnitTypeVillagerDwarf));
      }

      // Priority based on how many Villagers we already have alive, below 80% alive we have high prio.
      if (kbUnitCount(gEconUnit, cMyID, cUnitStateAlive) >= (plan1Number * 0.8))
      {
         aiPlanSetPriority(gVillagerMaintainPlan, 50);
      }
      else
      {
         aiPlanSetPriority(gVillagerMaintainPlan, 70);
      }
      if (kbUnitCount(cUnitTypeVillagerDwarf, cMyID, cUnitStateAlive) >= (plan2Number * 0.8))
      {
         aiPlanSetPriority(gSecondVillagerMaintainPlan, 50);
      }
      else
      {
         aiPlanSetPriority(gSecondVillagerMaintainPlan, 70);
      }
   }
}

//==============================================================================
// monitorEconomyPopCounts
//==============================================================================
rule monitorEconomyPopCounts
inactive
group defaultArchaicRules
minInterval 10
{
   if (checkStrategyFlag(cStrategyFlagAutomaticPopLimits) == false)
   {
      // Dont reset the economy pop limits in this if block.
      // The strategy is now fully responsible for setting these, we don't want to override that.
      return;
   }
   debugEconomy("--- Running Rule monitorEconomyPopCounts. ---");

   // Total land eco pop.
   int wantedLandEcoPop = 0;
   int num = 0;

   // Incorporate our Villager counts.
   // TODO this could also check for if we even own a building that can train Villagers.
   if (aiPlanGetIsIDValid(gVillagerMaintainPlan) == true)
   {
      num = aiPlanGetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0);
      wantedLandEcoPop += num;
      debugEconomy("First Villager maintain plan is valid and added " + num + " to our total wantedLandEcoPop, which now is: " +
         wantedLandEcoPop + ".");
      if (aiPlanGetIsIDValid(gSecondVillagerMaintainPlan) == true)
      {
         num = aiPlanGetVariableInt(gSecondVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0);
         wantedLandEcoPop += num;
         debugEconomy("Second Villager maintain plan is valid and added " + num + " to our total wantedLandEcoPop, which now is: " +
            wantedLandEcoPop + ".");
      }
   }
   else if (gOverrideMaxVillagerPop >= 0)
   {
      wantedLandEcoPop += gOverrideMaxVillagerPop;
      debugEconomy("No valid first Villager maintain plan but found an override that added " + gOverrideMaxVillagerPop +
         " to our total wantedLandEcoPop, which now is: " + wantedLandEcoPop + ".");
   }
   else
   {
      debugEconomy("No valid first Villager maintain plan and no override, not taking first Villagers into account now.");
   }

   // Offest the Villager part for Atlanteans.
   if (cMyCulture == cCultureAtlantean)
   {
      wantedLandEcoPop *= kbPlayerGetProtoStatInt(cMyID, gEconUnit, cProtoStatPopCost); // Offset for 2 pop cost.
      debugEconomy("We're Atlantean, adjusting our wantedLandEcoPop for our special Villagers, new wantedLandEcoPop: " +
         wantedLandEcoPop + ".");
      // Any Hero Citizens we have just increases our total numbers. This means that heroizing a Citizen will increase our total
      // economy cap.
      num = kbUnitCount(cUnitTypeVillagerAtlanteanHero, cMyID, cUnitStateAlive);
      num *= kbPlayerGetProtoStatInt(cMyID, cUnitTypeVillagerAtlanteanHero, cProtoStatPopCost);
      debugEconomy("We're Atlantean, adjusting our wantedLandEcoPop for our existing Hero Citizens, this adds " + num +
         ", new wantedLandEcoPop: " + wantedLandEcoPop + ".");
   }

   // Incorporate our Caravan counts.
   if (aiPlanGetIsIDValid(gCaravanMaintainPlan) == true)
   {
      // If we don't have a valid Market assigned to train from we take our current Caravan count instead.
      if (kbUnitGetIsIDValid(aiPlanGetVariableInt(gCaravanMaintainPlan, cTrainPlanBuildingID, 0)) == false)
      {
         num = kbUnitCount(gCaravanUnit, cMyID, cUnitStateAlive);
         wantedLandEcoPop += num;
         debugEconomy("Caravan maintain plan is valid BUT we have no valid Market. Adding our current Caravan count of: " + num +
            " to our total wantedLandEcoPop, which now is: " + wantedLandEcoPop + ".");
      }
      else
      {
         num = aiPlanGetVariableInt(gCaravanMaintainPlan, cTrainPlanNumberToMaintain, 0);
         wantedLandEcoPop += num;
         debugEconomy("Caravan maintain plan is valid and added " + num + " to our total wantedLandEcoPop, which now is: " +
            wantedLandEcoPop + ".");
      }
   }
   else if (gOverrideMaxCaravanPop >= 0)
   {
      wantedLandEcoPop += gOverrideMaxCaravanPop;
      debugEconomy("No valid Caravan maintain plan but found an override that added " + gOverrideMaxCaravanPop +
         " to our total wantedLandEcoPop, which now is: " + wantedLandEcoPop + ".");
   }
   else
   {
      debugEconomy("No valid Caravan maintain plan and no override, not taking Caravans into account now.");
   }

   // Actually set how many LAND eco pop units we're allowed to train.
   debugEconomy("Wanted land economy pop: " + wantedLandEcoPop + ".");
   aiSetEconomyPop(wantedLandEcoPop);

   // Total naval eco pop.
   int wantedNavalEcoPop = 0;

   if (aiPlanGetIsIDValid(gFishingShipMaintainPlan) == true)
   {
      if (gHaveValidFishingDock == false)
      {
         num = kbUnitCount(gFishingUnit, cMyID, cUnitStateAlive);
         wantedNavalEcoPop += num;
         debugEconomy("Fishing Ship maintain plan is valid BUT we have no valid Dock. Adding our current Fishing Ship count of: "
            + num + " to our total wantedNavalEcoPop, which now is: " + wantedNavalEcoPop + ".");
      }
      else
      {
         num = aiPlanGetVariableInt(gFishingShipMaintainPlan, cTrainPlanNumberToMaintain, 0);
         wantedNavalEcoPop += num;
         debugEconomy("Fishing Ship maintain plan is valid and added " + num + " to our total wantedNavalEcoPop, which now is: " +
               wantedNavalEcoPop + ".");
      }
   }
   else if (gOverrideMaxFishingShipPop >= 0)
   {
      wantedNavalEcoPop += gOverrideMaxFishingShipPop;
      debugEconomy("No valid Fishing Ship maintain plan but found an override that added " + gOverrideMaxFishingShipPop +
         " to our total wantedNavalEcoPop, which now is: " + wantedNavalEcoPop + ".");
   }
   else
   {
      debugEconomy("No valid Fishing Ship maintain plan and no override, not taking Fishing Ships into account now.");
   }

   // Actually set how many NAVAL eco pop units we're allowed to train.
   debugEconomy("Wanted naval economy pop: " + wantedNavalEcoPop + ".");
   aiSetNavalEconomyPop(wantedNavalEcoPop);

   // gMaxMilitaryPop is used to control how much military lower difficulties are allowed to make period.
   // Even if the AI has tons of excess resources or max eco pop we never want to unlock military pop for these lower difficulties,
   // we will use this number instead. This number is calculated by multiplying our total eco (land + naval) * gMilitaryToEcoRatio.
   if (cDifficultyCurrent <= cDifficultyHard)
   {
      gMaxMilitaryPop = (wantedLandEcoPop + wantedNavalEcoPop) * gMilitaryToEcoRatio;
      debugEconomy("Max military pop (lower difficulties) ((" + wantedLandEcoPop + "+" + wantedNavalEcoPop + ") * " +
         gMilitaryToEcoRatio + "): " + gMaxMilitaryPop + ".");
   }
}