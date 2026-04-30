void boAtlanteanStandardArchaic()
{
   aiEcho("Picked BO: boAtlanteanStandardArchaic");
   
   // Starting Villagers, 2 food.
   boVillager(cUnitTypeVillagerAtlantean, cResourceFood);
   boVillager(cUnitTypeVillagerAtlantean, cResourceFood);
   
   boIncreaseTimeout(210);
   if (cMyCiv == cCivGaia)
   {
      boExecute(useUnusedGodPowers); // Cast Gaia Forest.
   }

   boVillager(cUnitTypeVillagerAtlantean, cResourceWood);
   boVillager(cUnitTypeVillagerAtlantean, cResourceGold);
   boBuild(cUnitTypeManor, cUnitTypeVillagerAtlantean, 1, loanVillagerFromWoodPlan);
   boVillager(cUnitTypeVillagerAtlantean, cResourceFood);
   boVillager(cUnitTypeVillagerAtlantean, cResourceFood);
   boVillager(cUnitTypeVillagerAtlantean, cResourceWood);
   boBuild(cUnitTypeTemple, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerAtlantean, cResourceFood);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateABQ) >= 1;}, 10);
   boVillager(cUnitTypeVillagerAtlantean, cResourceGold);
   boVillager(cUnitTypeVillagerAtlantean, cResourceWood);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID) >= 1;}, 10);
   // Villager Distribution: 5 - 3 - 2 - 0.
}

void boAtlanteanGaiaEcoArchaic()
{
   aiEcho("Picked BO: boAtlanteanGaiaEcoArchaic");
   
   // Starting Villagers, 2 food.
   boVillager(cUnitTypeVillagerAtlantean, cResourceFood);
   boVillager(cUnitTypeVillagerAtlantean, cResourceFood);
   
   boIncreaseTimeout(240);
   boExecute(useUnusedGodPowers); // Cast Gaia Forest.

   boVillager(cUnitTypeVillagerAtlantean, cResourceWood);
   boVillager(cUnitTypeVillagerAtlantean, cResourceGold);
   boBuild(cUnitTypeManor, cUnitTypeVillagerAtlantean, 1, loanVillagerFromWoodPlan, "internalBOBuildManorComplete");
   boVillager(cUnitTypeVillagerAtlantean, cResourceFood);
   boVillager(cUnitTypeVillagerAtlantean, cResourceFood);
   boVillager(cUnitTypeVillagerAtlantean, cResourceWood);
   boBuild(cUnitTypeTemple, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerAtlantean, cResourceWood);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateABQ) >= 1;}, 10);
   boVillager(cUnitTypeVillagerAtlantean, cResourceGold);
   boBuild(cUnitTypeEconomicGuild, cUnitTypeVillagerAtlantean, 1, loanVillagerFromWoodPlan);
   boVillager(cUnitTypeVillagerAtlantean, cResourceGold);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID) >= 1;}, 10);
   boVillager(cUnitTypeVillagerAtlantean, cResourceFood);
   // Villager Distribution: 5 - 3 - 3 - 0.
}