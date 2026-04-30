void boAtlanteanPrometheusClassical()
{
   aiEcho("Picked BO: boAtlanteanPrometheusClassical");
   boIncreaseTimeout(150);

   boConditionalWait([]()->bool {return kbGetResourceAmount(cMyID, cResourceFood) >= 400.0;}, 25);
   // Advance.
   boAdvance(cTechClassicalAgePrometheus, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgePrometheus) >= 0.01;}, 15);
   boWait(20);
   // Already start the Manor plan now so that we don't potentially get building placement overlap issues.
   boBuild(cUnitTypeManor, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan, "internalBOBuildManorComplete");
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 45);

   boBuild(cUnitTypeCounterBarracks, cUnitTypeVillagerAtlantean, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeMilitaryBarracks, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan);

   boUnit(cUnitTypePromethean, cBOStepUnit, 2);
   boUnit(cUnitTypeMurmillo, cBOStepUnit, 2);
   boUnit(cUnitTypeCheiroballista, cBOStepUnit, 2);

   boVillager(cUnitTypeVillagerAtlantean, cResourceGold);
   boVillager(cUnitTypeVillagerAtlantean, cResourceWood);
   boBuild(cUnitTypeManor, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan, "internalBOBuildManorComplete");
   boVillager(cUnitTypeVillagerAtlantean, cResourceFood);

   boEnd();
}

void boAtlanteanLetoClassical()
{
   aiEcho("Picked BO: boAtlanteanLetoClassical");
   boIncreaseTimeout(150);

   boConditionalWait([]()->bool {return kbGetResourceAmount(cMyID, cResourceFood) >= 400.0;}, 25);
   // Advance.
   boAdvance(cTechClassicalAgeLeto, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeLeto) >= 0.01;}, 15);
   boWait(20);
   // Already start the Manor plan now so that we don't potentially get building placement overlap issues.
   boBuild(cUnitTypeManor, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan, "internalBOBuildManorComplete");
   boTransaction(2, cResourceGold); // Wood to gold for Automatons.
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 45);

   boBuild(cUnitTypeMilitaryBarracks, cUnitTypeVillagerAtlantean, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeCounterBarracks, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan);

   boUnit(cUnitTypeAutomaton, cBOStepUnit, 3);
   boUnit(cUnitTypeMurmillo, cBOStepUnit, 3);
   boUnit(cUnitTypeTurma, cBOStepUnit, 3);

   boVillager(cUnitTypeVillagerAtlantean, cResourceGold);
   boVillager(cUnitTypeVillagerAtlantean, cResourceWood);
   boBuild(cUnitTypeManor, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan, "internalBOBuildManorComplete");
   boVillager(cUnitTypeVillagerAtlantean, cResourceFood);

   boEnd();
}

void boAtlanteanOceanusClassical()
{
   aiEcho("Picked BO: boAtlanteanOceanusClassical");
   boIncreaseTimeout(150);

   boConditionalWait([]()->bool {return kbGetResourceAmount(cMyID, cResourceFood) >= 400.0;}, 25);
   // Advance.
   boAdvance(cTechClassicalAgeOceanus, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeOceanus) >= 0.01;}, 15);
   boWait(20);
   // Already start the Manor plan now so that we don't potentially get building placement overlap issues.
   boBuild(cUnitTypeManor, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan, "internalBOBuildManorComplete");
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 45);

   boBuild(cUnitTypeMilitaryBarracks, cUnitTypeVillagerAtlantean, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeCounterBarracks, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan);

   boUnit(cUnitTypeCaladria, cBOStepUnit, 1);
   boUnit(cUnitTypeMurmillo, cBOStepUnit, 3);
   boUnit(cUnitTypeTurma, cBOStepUnit, 3);

   boVillager(cUnitTypeVillagerAtlantean, cResourceGold);
   boVillager(cUnitTypeVillagerAtlantean, cResourceWood);
   boBuild(cUnitTypeManor, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan, "internalBOBuildManorComplete");
   boVillager(cUnitTypeVillagerAtlantean, cResourceFood);

   boEnd();
}

void boGaiaLetoClassical()
{
   aiEcho("Picked BO: boGaiaLetoClassical");
   boIncreaseTimeout(150);

   boConditionalWait([]()->bool {return kbGetResourceAmount(cMyID, cResourceFood) >= 400.0;}, 25);
   // Advance.
   boAdvance(cTechClassicalAgeLeto, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeLeto) >= 0.01;}, 15);
   boTech(cTechHandAxe);
   boWait(20);
   // Already start the Manor plan now so that we don't potentially get building placement overlap issues.
   boBuild(cUnitTypeManor, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan, "internalBOBuildManorComplete");
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 45);

   boBuild(cUnitTypeMilitaryBarracks, cUnitTypeVillagerAtlantean, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeCounterBarracks, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan);
   boUnit(cUnitTypeAutomaton, cBOStepUnit, 3);
   boUnit(cUnitTypeMurmillo, cBOStepUnit, 3);
   boUnit(cUnitTypeTurma, cBOStepUnit, 2);

   boVillager(cUnitTypeVillagerAtlantean, cResourceWood);
   boVillager(cUnitTypeVillagerAtlantean, cResourceGold);
   // This can be risky if we didn't swap to Gaia Trees since then it would be the second Manor next to the wood line + Eco Guild.
   boBuild(cUnitTypeManor, cUnitTypeVillagerAtlantean, 1, loanVillagerFromWoodPlan, "internalBOBuildManorComplete");
   boVillager(cUnitTypeVillagerAtlantean, cResourceWood);

   boTech(cTechWatchTower);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechWatchTower) >= 0.01;}, 5, cNoWarning);

   boEnd();
}

void boGaiaOceanusClassical()
{
   aiEcho("Picked BO: boGaiaOceanusClassical");
   boIncreaseTimeout(150);

   boConditionalWait([]()->bool {return kbGetResourceAmount(cMyID, cResourceFood) >= 400.0;}, 25);
   // Advance.
   boAdvance(cTechClassicalAgeOceanus, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeOceanus) >= 0.01;}, 15);
   boTech(cTechHandAxe);
   boWait(20);
   // Already start the Manor plan now so that we don't potentially get building placement overlap issues.
   boBuild(cUnitTypeManor, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan, "internalBOBuildManorComplete");
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 45);

   boBuild(cUnitTypeMilitaryBarracks, cUnitTypeVillagerAtlantean, 1, loanVillagerFromWoodPlan);
   boUnit(cUnitTypeCaladria, cBOStepUnit, 1);
   boUnit(cUnitTypeMurmillo, cBOStepUnit, 4);
   boUnit(cUnitTypeCheiroballista, cBOStepUnit, 1);

   boVillager(cUnitTypeVillagerAtlantean, cResourceWood);
   // Delay Counter Barracks, we really need the Military Barracks up first.
   boBuild(cUnitTypeCounterBarracks, cUnitTypeVillagerAtlantean, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerAtlantean, cResourceGold);
   // This can be risky if we didn't swap to Gaia Trees since then it would be the second Manor next to the wood line + Eco Guild.
   boBuild(cUnitTypeManor, cUnitTypeVillagerAtlantean, 1, loanVillagerFromWoodPlan, "internalBOBuildManorComplete");
   boVillager(cUnitTypeVillagerAtlantean, cResourceWood);

   boTech(cTechWatchTower);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechWatchTower) >= 0.01;}, 5, cNoWarning);

   boEnd();
}