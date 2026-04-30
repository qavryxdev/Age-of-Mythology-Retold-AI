void boNorseStandardArchaic()
{
   aiEcho("Picked BO: boNorseStandardArchaic");

   // Starting Villagers, 3 food, also assign Ox Cart to the food plan.
   if (cMyCiv == cCivThor)
   {
      boVillager(cUnitTypeVillagerDwarf, cResourceFood);
      boVillager(cUnitTypeVillagerDwarf, cResourceFood);
      boVillager(cUnitTypeVillagerDwarf, cResourceFood);
   }
   else
   {
      boVillager(cUnitTypeVillagerNorse, cResourceFood);
      boVillager(cUnitTypeVillagerNorse, cResourceFood);
      boVillager(cUnitTypeVillagerNorse, cResourceFood);
   }
   boIncreaseTimeout(230);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeOxCart, cMyID, cUnitStateAlive) >= 1;}, 2);
   boExecute(assignOxCartToFood);
   if (cMyCiv == cCivOdin)
   {
      boExecute(useUnusedGodPowers); // Cast Great Hunt instantly.
   }

   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeBerserk, cMyID, cUnitStateAlive) >= 1;}, 2);
   // Build House -> Scout -> build Temple when possible.
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan,
           "internalBOBerserkHouseCompleted");

   // Begin.
   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   boVillager(cUnitTypeVillagerNorse, cResourceFood);

   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boBuild(cUnitTypeOxCartBuilding, cUnitTypeVillagerDwarf, 1, boBuildGoldDropsite, "assignOxCartToGold");
   boVillager(cUnitTypeVillagerNorse, cResourceWood);
   boBuild(cUnitTypeOxCartBuilding, cUnitTypeVillagerNorse, 1, boBuildWoodDropsite, "assignOxCartToWood");

   boVillager(cUnitTypeVillagerNorse, cResourceWood);
   boVillager(cUnitTypeVillagerNorse, cResourceWood);
   boVillager(cUnitTypeVillagerNorse, cResourceGold);
   boVillager(cUnitTypeVillagerNorse, cResourceGold);

   if (cMyCiv == cCivOdin)
   {
      boActivateRule("assignRavensToExplorationPlans");
      boExecute(setupRavenScoutPlans); // The scout plans already exist at this point so this is safe.
   }
   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   
   // Temple is built via the chain that is starting by the Berserk exploration.

   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boTransaction(0, cResourceGold); // We collected enough food for age up, now we need more gold.
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID) >= 1;}, 10);
   // Be careful here that even if the condition above is true it can still mean that our Berserk is in the Temple plan
   // that will only go away next frame, so addNorseMilitaryBuilderToPlan can still fail the frame after this.
   
   // 8 - 3 - 5 - 0, with 2 Dwarves on gold.
}

/*
void boNorseFreyrStandardArchaic()
{
   aiEcho("Picked BO: boNorseFreyrStandardArchaic");

   // Starting Villagers, 3 food, also assign Ox Cart to the food plan.
   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   boIncreaseTimeout(220);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeOxCart, cMyID, cUnitStateAlive) >= 1;}, 2);
   boExecute(assignOxCartToFood);

   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeBerserk, cMyID, cUnitStateAlive) >= 1;}, 2);
   // Build House -> Scout -> build Temple when possible.
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan,
           "internalBOBerserkHouseCompleted");

   // Begin.
   boVillager(cUnitTypeVillagerNorse, cResourceFood);

   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boBuild(cUnitTypeOxCartBuilding, cUnitTypeVillagerDwarf, 1, boBuildGoldDropsite, "assignOxCartToGold");
   boVillager(cUnitTypeVillagerNorse, cResourceWood);
   boBuild(cUnitTypeOxCartBuilding, cUnitTypeVillagerNorse, 1, boBuildWoodDropsite, "assignOxCartToWood");

   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   boVillager(cUnitTypeVillagerNorse, cResourceWood);
   boVillager(cUnitTypeVillagerNorse, cResourceWood);
   boVillager(cUnitTypeVillagerNorse, cResourceGold);
   boVillager(cUnitTypeVillagerNorse, cResourceGold);

   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   boVillager(cUnitTypeVillagerNorse, cResourceFood);

   // Temple is built via the chain that is starting by the Berserk exploration.

   boVillager(cUnitTypeVillagerNorse, cResourceWood);
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID) >= 1;}, 10);
   // Be careful here that even if the condition above is true it can still mean that our Berserk is in the Temple plan
   // that will only go away next frame, so addNorseMilitaryBuilderToPlan can still fail the frame after this.

   // 7 - 4 - 4 - 0, with 2 Dwarves on gold.
}
*/