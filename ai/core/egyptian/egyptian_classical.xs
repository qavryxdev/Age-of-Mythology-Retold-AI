void boEgyptianBastClassical()
{
   aiEcho("Picked BO: boEgyptianBastClassical");
   boIncreaseTimeout(150);

   // Advance.
   boAdvance(cTechClassicalAgeBast, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeBast) >= 0.01;}, 15);
   boTech(cTechPickaxe, cUnitTypeMiningCamp);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 65);

   // If we're Ra we haven't scouted yet, do some loops around the base with the Sphinx.
   if (cMyCiv == cCivRa)
   {
      boExplore(cUnitTypeSphinx, cBOStepDontSearchShoreline, cBOStepDontSearchEnemy, cBOStepDoLoops);
   }

   boBuild(cUnitTypeHouse, cUnitTypeVillagerEgyptian, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeBarracks, cUnitTypeVillagerEgyptian, 2, loanVillagerFromGoldPlan);
   boBuild(cUnitTypeBarracks, cUnitTypeVillagerEgyptian, 1, loanVillagerFromWoodPlan);

   boUnit(cUnitTypeSphinx, cBOStepUnit, 1); // We end up training this one after the BO.
   boUnit(cUnitTypeSlinger, cBOStepUnit, 3);
   boUnit(cUnitTypeAxeman, cBOStepUnit, 2);
   boUnit(cUnitTypeSpearman, cBOStepUnit, 2);

   boVillager(cUnitTypeVillagerEgyptian, cResourceFood);
   boVillager(cUnitTypeVillagerEgyptian, cResourceGold);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerEgyptian, 1, loanVillagerFromWoodPlan);
   boVillager(cUnitTypeVillagerEgyptian, cResourceGold);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerEgyptian, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerEgyptian, cResourceFood);
   boVillager(cUnitTypeVillagerEgyptian, cResourceGold);

   boEnd();
}

void boEgyptianPtahClassical()
{
   aiEcho("Picked BO: boEgyptianPtahClassical");
   boIncreaseTimeout(150);

   // Advance.
   boAdvance(cTechClassicalAgePtah, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgePtah) >= 0.01;}, 15);
   boTech(cTechHandAxe, cUnitTypeLumberCamp);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 60);

   // If we're Ra we haven't scouted yet, do some loops around the base with the Wadjet.
   if (cMyCiv == cCivRa)
   {
      boExplore(cUnitTypeWadjet, cBOStepDontSearchShoreline, cBOStepDontSearchEnemy, cBOStepDoLoops);
   }

   boBuild(cUnitTypeHouse, cUnitTypeVillagerEgyptian, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeBarracks, cUnitTypeVillagerEgyptian, 2, loanVillagerFromGoldPlan);
   boBuild(cUnitTypeBarracks, cUnitTypeVillagerEgyptian, 1, loanVillagerFromWoodPlan);

   boUnit(cUnitTypeWadjet, cBOStepUnit, 1); // We end up training this one after the BO most likely.
   boUnit(cUnitTypeSlinger, cBOStepUnit, 5);
   boUnit(cUnitTypeSpearman, cBOStepUnit, 2);
   boUnit(cUnitTypePriest, cBOStepUnit, 1, cBOStepNotBlocking, cUnitTypeTemple);

   boVillager(cUnitTypeVillagerEgyptian, cResourceWood);
   boVillager(cUnitTypeVillagerEgyptian, cResourceWood);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerEgyptian, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerEgyptian, cResourceGold);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerEgyptian, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerEgyptian, cResourceFood);
   boVillager(cUnitTypeVillagerEgyptian, cResourceGold);

   boEnd();
}

void boEgyptianAnubisClassical()
{
   aiEcho("Picked BO: boEgyptianAnubisClassical");
   boIncreaseTimeout(150);

   // Advance.
   boAdvance(cTechClassicalAgeAnubis);

   boBuild(cUnitTypeHouse, cUnitTypeVillagerEgyptian, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeBarracks, cUnitTypeVillagerEgyptian, 2, loanVillagerFromGoldPlan);
   boBuild(cUnitTypeBarracks, cUnitTypeVillagerEgyptian, 1, loanVillagerFromWoodPlan);

   boUnit(cUnitTypeSlinger, cBOStepUnit, 2);
   boUnit(cUnitTypeSpearman, cBOStepUnit, 5);
   boUnit(cUnitTypePriest, cBOStepUnit, 1, cBOStepNotBlocking, cUnitTypeTemple);

   boTech(cTechSerpentSpear, cUnitTypeBarracks);

   boVillager(cUnitTypeVillagerEgyptian, cResourceWood);
   boVillager(cUnitTypeVillagerEgyptian, cResourceWood);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerEgyptian, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerEgyptian, cResourceGold);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerEgyptian, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerEgyptian, cResourceFood);
   boVillager(cUnitTypeVillagerEgyptian, cResourceGold);

   boEnd();
}