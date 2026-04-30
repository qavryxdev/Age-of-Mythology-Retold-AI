void boGreekStandardArchaic()
{
   aiEcho("Picked BO: boGreekStandardArchaic");
   // Starting Villagers.
   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boIncreaseTimeout(220);
   boBuild(cUnitTypeGranary, cUnitTypeVillagerGreek, 4, boBuildFoodDropsite, "internalBOBuildDropsiteComplete");
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeAbstractScout, cMyID, cUnitStateAlive) >= 1;}, 2);
   boExplore(cUnitTypeKataskopos, cBOStepDontSearchShoreline, cBOStepDontSearchEnemy, cBOStepDoLoops, cBOStepScoutStartingSurroundings);

   boExecute(useUnusedGodPowers); // Cast Sentinel / start checking for Bolt / cast Lure.

   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);

   boVillager(cUnitTypeVillagerGreek, cResourceGold);
   boBuild(cUnitTypeStorehouse, cUnitTypeVillagerGreek, 1, boBuildGoldDropsite, "internalBOBuildDropsiteComplete");

   boVillager(cUnitTypeVillagerGreek, cResourceWood);
   boBuild(cUnitTypeStorehouse, cUnitTypeVillagerGreek, 1, boBuildWoodDropsite, "internalBOBuildDropsiteComplete");
   boVillager(cUnitTypeVillagerGreek, cResourceWood);
   boVillager(cUnitTypeVillagerGreek, cResourceGold);

   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);

   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);
   boVillager(cUnitTypeVillagerGreek, cResourceFavor);
   boTransaction(6, cResourceFavor); // Must build Temple with 2 Villagers or we're too slow.
   boBuild(cUnitTypeTemple, cUnitTypeVillagerGreek, 2, loanVillagerFromFavorPlan);

   boVillager(cUnitTypeVillagerGreek, cResourceWood);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateABQ) >= 1;}, 30);
   boVillager(cUnitTypeVillagerGreek, cResourceWood);
   boVillager(cUnitTypeVillagerGreek, cResourceWood);

   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID) >= 1;}, 30);
   // Villager Distribution: 9 - 5 - 1 - 2.
}