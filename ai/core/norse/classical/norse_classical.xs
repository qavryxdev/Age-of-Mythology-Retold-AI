// There are conditions in which we don't have enough of builders on age up to make 2 military structures.
// This is why the second building is always delayed by 1 Villager.

void boOdinHeimdallClassical()
{
   aiEcho("Picked BO: boOdinHeimdallClassical");
   boIncreaseTimeout(140);

   // Advance.
   boAdvance(cTechClassicalAgeHeimdall, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeHeimdall) >= 0.01;}, 15);
   boBuild(cUnitTypeHouse, cUnitTypeBerserk, 1, addNorseMilitaryBuilderToPlan);
   boUnit(cUnitTypeHersir, cBOStepUnit, 2);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeHouse, cMyID) >= 2;}, 50);
   boWait(1); // Make sure the House plan is really gone.
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 45);

   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);

   boUnit(cUnitTypeThrowingAxeman, cBOStepUnit, 3);
   boUnit(cUnitTypeHirdman, cBOStepUnit, 2);
   boUnit(cUnitTypeRaidingCavalry, cBOStepUnit, 2);

   // Transfer our Villagers away from gold in favor of Dwarves.
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boTransaction(9, cResourceWood);
   boBuild(cUnitTypeGreatHall, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boTransaction(10, cResourceWood);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);

   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boVillager(cUnitTypeVillagerNorse, cResourceWood);

   boEnd();
}

void boLokiHeimdallClassical()
{
   aiEcho("Picked BO: boLokiHeimdallClassical");
   boIncreaseTimeout(140);

   // Advance.
   boAdvance(cTechClassicalAgeHeimdall, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeHeimdall) >= 0.01;}, 15);
   boBuild(cUnitTypeHouse, cUnitTypeBerserk, 1, addNorseMilitaryBuilderToPlan);
   boUnit(cUnitTypeHersir, cBOStepUnit, 2);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeHouse, cMyID) >= 2;}, 50);
   boWait(1); // Make sure the House plan is really gone.
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 45);

   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);

   boUnit(cUnitTypeThrowingAxeman, cBOStepUnit, 3);
   boUnit(cUnitTypeHirdman, cBOStepUnit, 2);
   boUnit(cUnitTypeHersir, cBOStepUnit, 2);

   // Transfer our Villagers away from gold in favor of Dwarves.
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boTransaction(9, cResourceWood);
   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boTransaction(10, cResourceWood);
   boBuild(cUnitTypeHouse, cUnitTypeHersir, 1, addNorseMilitaryBuilderToPlan);

   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boVillager(cUnitTypeVillagerNorse, cResourceWood);

   boEnd();
}

void boLokiForsetiClassical()
{
   aiEcho("Picked BO: boLokiForsetiClassical");
   boIncreaseTimeout(140);

   // Advance.
   boAdvance(cTechClassicalAgeForseti, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeForseti) >= 0.01;}, 15);
   boBuild(cUnitTypeHouse, cUnitTypeBerserk, 1, addNorseMilitaryBuilderToPlan);
   boUnit(cUnitTypeHersir, cBOStepUnit, 2);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeHouse, cMyID) >= 2;}, 50);
   boWait(1); // Make sure the House plan is really gone.
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) == cAge2;}, 65);

   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);

   boUnit(cUnitTypeThrowingAxeman, cBOStepUnit, 3);
   boUnit(cUnitTypeHersir, cBOStepUnit, 4);

   // Transfer our Villagers away from gold in favor of Dwarves.
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boTransaction(9, cResourceWood);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boTransaction(10, cResourceWood);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);

   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boVillager(cUnitTypeVillagerNorse, cResourceFood);

   boEnd();
}

void boThorForsetiClassical()
{
   aiEcho("Picked BO: boThorForsetiClassical");
   boIncreaseTimeout(140);
   
   // Advance.
   boAdvance(cTechClassicalAgeForseti, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeForseti) >= 0.01;}, 15);
   boBuild(cUnitTypeHouse, cUnitTypeBerserk, 1, addNorseMilitaryBuilderToPlan);
   // Switch starting Dwarves to gold, and Villagers to food.
   boTransaction(0, cResourceGold);
   boTransaction(1, cResourceGold);
   boTransaction(2, cResourceGold);
   boTransaction(9, cResourceWood);
   boTransaction(10, cResourceWood);
   boUnit(cUnitTypeHersir, cBOStepUnit, 2);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeHouse, cMyID) >= 2;}, 50);
   boWait(1); // Make sure the House plan is really gone.
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) == cAge2;}, 65);

   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);

   boUnit(cUnitTypeThrowingAxeman, cBOStepUnit, 2);
   boUnit(cUnitTypeHirdman, cBOStepUnit, 2);
   boUnit(cUnitTypeRaidingCavalry, cBOStepUnit, 3);

   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   // There are conditions in which we just don't have 2 builders free on age up, so delay Great Hall.
   boBuild(cUnitTypeGreatHall, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerNorse, 1, loanVillagerFromWoodPlan);
   boVillager(cUnitTypeVillagerDwarf, cResourceFood);
   boVillager(cUnitTypeVillagerDwarf, cResourceWood);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerNorse, cResourceFood);

   boEnd();
}

void boThorFreyaClassical()
{
   aiEcho("Picked BO: boThorFreyaClassical");
   boIncreaseTimeout(140);

   // Advance.
   boAdvance(cTechClassicalAgeFreyja, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeFreyja) >= 0.01;}, 15);
   boBuild(cUnitTypeHouse, cUnitTypeBerserk, 1, addNorseMilitaryBuilderToPlan);
   // Switch starting Dwarves to gold, and Villagers to food.
   boTransaction(0, cResourceGold);
   boTransaction(1, cResourceGold);
   boTransaction(2, cResourceGold);
   boTransaction(9, cResourceWood);
   boTransaction(10, cResourceWood);
   boUnit(cUnitTypeHersir, cBOStepUnit, 2);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeHouse, cMyID) >= 2;}, 50);
   boWait(1); // Make sure the House plan is really gone.
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) == cAge2;}, 65);

   boBuild(cUnitTypeGreatHall, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boUnit(cUnitTypeRaidingCavalry, cBOStepUnit, 4);

   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerNorse, 1, loanVillagerFromWoodPlan);
   boVillager(cUnitTypeVillagerDwarf, cResourceFood);
   boVillager(cUnitTypeVillagerDwarf, cResourceFood);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   
   boEnd();
}

void boOdinFreyaClassical()
{
   aiEcho("Picked BO: boOdinFreyaClassical");
   boIncreaseTimeout(140);

   // Advance.
   boAdvance(cTechClassicalAgeFreyja, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeFreyja) >= 0.01;}, 15);
   boBuild(cUnitTypeHouse, cUnitTypeBerserk, 1, addNorseMilitaryBuilderToPlan);
   boUnit(cUnitTypeHersir, cBOStepUnit, 2);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeHouse, cMyID) >= 2;}, 50);
   boWait(1); // Make sure the House plan is really gone.
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) == cAge2;}, 65);

   boBuild(cUnitTypeGreatHall, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boUnit(cUnitTypeRaidingCavalry, cBOStepUnit, 4);

   // Transfer our Villagers away from gold in favor of Dwarves.
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boTransaction(9, cResourceFood);
   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boTransaction(10, cResourceWood);

   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerNorse, cResourceWood);
   
   boEnd();
}

void boFreyrFreyaClassical()
{
   aiEcho("Picked BO: boFreyrFreyaClassical");
   boIncreaseTimeout(140);

   // Advance.
   boAdvance(cTechClassicalAgeFreyja, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeFreyja) >= 0.01;}, 15);
   boBuild(cUnitTypeHouse, cUnitTypeBerserk, 1, addNorseMilitaryBuilderToPlan);
   boUnit(cUnitTypeHersir, cBOStepUnit, 2);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeHouse, cMyID) >= 2;}, 50);
   boWait(1); // Make sure the House plan is really gone.
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) == cAge2;}, 65);

   boBuild(cUnitTypeGreatHall, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boUnit(cUnitTypeRaidingCavalry, cBOStepUnit, 4);

   // Transfer our Villagers away from gold in favor of Dwarves.
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boTransaction(9, cResourceFood);
   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boTransaction(10, cResourceWood);

   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerNorse, cResourceWood);
   
   boEnd();
}

void boFreyrUllrClassical()
{
   aiEcho("Picked BO: boFreyrUllrClassical");
   boIncreaseTimeout(140);

   // Advance.
   boAdvance(cTechClassicalAgeUllr, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeUllr) >= 0.01;}, 15);
   boBuild(cUnitTypeHouse, cUnitTypeBerserk, 1, addNorseMilitaryBuilderToPlan);
   boUnit(cUnitTypeHersir, cBOStepUnit, 2);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeHouse, cMyID) >= 2;}, 50);
   boWait(1); // Make sure the House plan is really gone.
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) == cAge2;}, 65);

   boBuild(cUnitTypeGreatHall, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boUnit(cUnitTypeRaidingCavalry, cBOStepUnit, 4);

   // Transfer our Villagers away from gold in favor of Dwarves.
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boTransaction(9, cResourceFood);
   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boTransaction(10, cResourceWood);

   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerNorse, cResourceWood);
   
   boEnd();
}

/*
void boFreyrFreyaClassical()
{
   aiEcho("Picked BO: boFreyrFreyaClassical");
   boIncreaseTimeout(170);

   // Advance.
   boAdvance(cTechClassicalAgeFreyja, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeFreyja) >= 0.01;}, 15);
   boBuild(cUnitTypeHouse, cUnitTypeBerserk, 1, addNorseMilitaryBuilderToPlan);
   boUnit(cUnitTypeHersir, cBOStepUnit, 3);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeHouse, cMyID) >= 2;}, 50);
   boWait(1); // Make sure the House plan is really gone.
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   // Get all Archaic eco upgrades, we do a 1 second wait so we know for sure they won't all be researched in the same Ox Cart.
   boTech(cTechPickaxe, cUnitTypeOxCart);
   boWait(1);
   boTech(cTechHandAxe, cUnitTypeOxCart);
   boWait(1);
   boTech(cTechHusbandry, cUnitTypeOxCart);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) == cAge2;}, 95);

   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   // Since our age up is so long, we can expect to have 2 Hersirs available for this.
   boBuild(cUnitTypeGreatHall, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 2, addNorseMilitaryBuilderToPlan);

   boUnit(cUnitTypeThrowingAxeman, cBOStepUnit, 2);
   boUnit(cUnitTypeRaidingCavalry, cBOStepUnit, 4);

   boVillager(cUnitTypeVillagerNorse, cResourceWood);
   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   
   boEnd();
}

void boFreyrUllrClassical()
{
   aiEcho("Picked BO: boFreyrUllrClassical");
   boIncreaseTimeout(170);

   // Advance.
   boAdvance(cTechClassicalAgeUllr, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeUllr) >= 0.01;}, 15);
   boBuild(cUnitTypeHouse, cUnitTypeBerserk, 1, addNorseMilitaryBuilderToPlan);
   boUnit(cUnitTypeHersir, cBOStepUnit, 3);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeHouse, cMyID) >= 2;}, 50);
   boWait(1); // Make sure the House plan is really gone.
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   // Get all Archaic eco upgrades, we do a 1 second wait so we know for sure they won't all be researched in the same Ox Cart.
   boTech(cTechPickaxe, cUnitTypeOxCart);
   boWait(1);
   boTech(cTechHandAxe, cUnitTypeOxCart);
   boWait(1);
   boTech(cTechHusbandry, cUnitTypeOxCart);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) == cAge2;}, 95);

   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   // Since our age up is so long, we can expect to have 2 Hersirs available for this.
   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 2, addNorseMilitaryBuilderToPlan);

   boUnit(cUnitTypeThrowingAxeman, cBOStepUnit, 2);
   boUnit(cUnitTypeBerserk, cBOStepUnit, 4, cBOStepNotBlocking, cUnitTypeLonghouse);

   boVillager(cUnitTypeVillagerNorse, cResourceWood);
   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerNorse, cResourceFood);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, addNorseMilitaryBuilderToPlan);
   boVillager(cUnitTypeVillagerDwarf, cResourceGold);
   
   boEnd();
}
*/