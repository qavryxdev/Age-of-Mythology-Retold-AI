void boEgyptianStandardArchaic()
{
   aiEcho("Picked BO: boEgyptianStandardArchaic");

   // Starting Villagers.
   boVillager(cUnitTypeVillagerEgyptian, cResourceFood);
   boVillager(cUnitTypeVillagerEgyptian, cResourceFood);
   boVillager(cUnitTypeVillagerEgyptian, cResourceFood);
   
   boIncreaseTimeout(210);
   if (cMyCiv == cCivSet)
   {
      boExecute(useUnusedGodPowers); // Cast Vision.
   }
   boBuild(cUnitTypeGranary, cUnitTypeVillagerEgyptian, 3, boBuildFoodDropsite, "internalBOBuildDropsiteComplete");
   boEmpower(cUnitTypeGranary);
   if (cMyCiv != cCivRa)
   {
      boConditionalWait([]()->bool { return kbUnitCount(cUnitTypePriest, cMyID, cUnitStateAlive) >= 1; }, 3);
      if (cMyCiv == cCivSet)
      {
         boExplore(cUnitTypePriest, cBOStepDontSearchShoreline, cBOStepDontSearchEnemy, cBOStepDoLoops);
         boExplore(cUnitTypeBaboonOfSet, cBOStepDontSearchShoreline, cBOStepDontSearchEnemy, cBOStepDontDoLoops, cBOStepScoutStartingSurroundings);
      }
      else
      {
         boExplore(cUnitTypePriest, cBOStepDontSearchShoreline, cBOStepDontSearchEnemy, cBOStepDoLoops, cBOStepScoutStartingSurroundings);
      }
   }

   boVillager(cUnitTypeVillagerEgyptian, cResourceFood);
   boVillager(cUnitTypeVillagerEgyptian, cResourceFood);
   boVillager(cUnitTypeVillagerEgyptian, cResourceFood);

   boVillager(cUnitTypeVillagerEgyptian, cResourceGold);
   boBuild(cUnitTypeMiningCamp, cUnitTypeVillagerEgyptian, 1, boBuildGoldDropsite, "internalBOBuildDropsiteComplete");
   if (cMyCiv == cCivRa)
   {
      boEmpower(cUnitTypeMiningCamp, empowerWithPriest); // TODO this should be done like Berserk starting scout
   }
   boVillager(cUnitTypeVillagerEgyptian, cResourceGold);
   boVillager(cUnitTypeVillagerEgyptian, cResourceGold);

   boVillager(cUnitTypeVillagerEgyptian, cResourceFood);
   boVillager(cUnitTypeVillagerEgyptian, cResourceFood);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerEgyptian, 1, loanVillagerFromFoodPlan);
   boBuild(cUnitTypeTemple, cUnitTypeVillagerEgyptian, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerEgyptian, cResourceFood);

   boVillager(cUnitTypeVillagerEgyptian, cResourceWood);
   boBuild(cUnitTypeLumberCamp, cUnitTypeVillagerEgyptian, 1, boBuildWoodDropsite, "internalBOBuildDropsiteComplete");
   boBuild(cUnitTypeMonumentToVillagers, cUnitTypeVillagerEgyptian, 1, loanVillagerFromFoodPlan);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateABQ) >= 1;}, 10);
   boVillager(cUnitTypeVillagerEgyptian, cResourceGold);
   boVillager(cUnitTypeVillagerEgyptian, cResourceGold);
   boVillager(cUnitTypeVillagerEgyptian, cResourceWood);

   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID) >= 1;}, 15);
   boConditionalWait([]()->bool {return kbGetResourceAmount(cMyID, cResourceFood) >= 400.0;}, 25);

   boTransaction(0, cResourceWood);
   // Villager Distribution: 8 - 3 - 5 - 0.
}