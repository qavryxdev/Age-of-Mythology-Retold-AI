void boZeusHermesClassical()
{
   aiEcho("Picked BO: boZeusHermesClassical");
   boIncreaseTimeout(170);

   // Advance.
   boAdvance(cTechClassicalAgeHermes, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeHermes) >= 0.01;}, 15);
   // Villager Distribution we need to have: 6 - 7 - 2 - 2.
   boTransaction(0, cResourceWood);
   boTransaction(1, cResourceWood);
   boTransaction(2, cResourceGold);
   boTech(cTechHandAxe, cUnitTypeStorehouse);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 65);

   // Get some Centaurs and then transition into Hippeus.
   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeStable, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);

   boUnit(cUnitTypeCentaur, cBOStepUnit, 2);
   boUnit(cUnitTypeJason, cBOStepUnit, 1);
   boWait(1); // Make sure the hero is queued, and then we can add another Villager into the same queue.
   boUnit(cUnitTypeHippeus, cBOStepUnit, 3);

   // We have enough wood for Centaurs, but we need food for Villagers and later more gold for Hippeus.
   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerGreek, cResourceGold);
   boVillager(cUnitTypeVillagerGreek, cResourceGold);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerGreek, cResourceGold);

   if (cDifficultyCurrent >= cDifficultyExtreme)
   {
      boTech(cTechSylvanLore, cUnitTypeTemple);
      boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechSylvanLore) >= 0.01;}, 10, cNoWarning);
   }

   boEnd();
}

void boZeusAthenaClassical()
{
   aiEcho("Picked BO: boZeusAthenaClassical");
   boIncreaseTimeout(165);

   // Advance.
   boAdvance(cTechClassicalAgeAthena, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeAthena) >= 0.01;}, 15);
   // Villager Distribution we need to have: 6 - 6 - 3 - 2.
   boTransaction(0, cResourceWood);
   boTransaction(1, cResourceGold);
   boTransaction(2, cResourceGold);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 65);

   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeMilitaryAcademy, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeArcheryRange, cUnitTypeVillagerGreek, 1, loanVillagerFromGoldPlan);

   // Build many Toxotes + Hoplites, and get all our heroes + 1 Minotaur.
   boUnit(cUnitTypeJason, cBOStepUnit, 1);
   boWait(1); // Make sure the hero is queued, and then we can add another Villager into the same queue.
   boUnit(cUnitTypeHeracles, cBOStepUnit, 1);
   boUnit(cUnitTypeMinotaur, cBOStepUnit, 1);
   boUnit(cUnitTypeHoplite, cBOStepUnit, 3);
   boUnit(cUnitTypeToxotes, cBOStepUnit, 3);

   // Make sure we can maintain all these unit commands.
   boVillager(cUnitTypeVillagerGreek, cResourceGold);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromFoodPlan);
   boVillager(cUnitTypeVillagerGreek, cResourceGold);
   boVillager(cUnitTypeVillagerGreek, cResourceGold);

   boTech(cTechSarissa, cUnitTypeMilitaryAcademy);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechSarissa) >= 0.01;}, 5, cNoWarning);

   boEnd();
}

void boHadesAthenaClassical()
{
   aiEcho("Picked BO: boHadesAthenaClassical");
   boIncreaseTimeout(165);

   // Advance.
   boAdvance(cTechClassicalAgeAthena, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeAthena) >= 0.01;}, 15);
   // Villager Distribution we need to have: 6 - 7 - 3 - 1.
   boTransaction(0, cResourceWood);
   boTransaction(1, cResourceGold);
   boTransaction(2, cResourceGold);
   // Need a bit more favor before we transition, so we can get Sarissa in the end.
   boWait(30);
   boTransaction(6, cResourceWood);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 65);

   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeMilitaryAcademy, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeArcheryRange, cUnitTypeVillagerGreek, 1, loanVillagerFromGoldPlan);

   // Build many Toxotes + Hoplites, and get all our heroes + 1 Minotaur.
   boUnit(cUnitTypeAjax, cBOStepUnit, 1);
   boWait(1); // Make sure the hero is queued, and then we can add another Villager into the same queue.
   boUnit(cUnitTypeAchilles, cBOStepUnit, 1);
   boUnit(cUnitTypeMinotaur, cBOStepUnit, 1);
   boUnit(cUnitTypeHoplite, cBOStepUnit, 3);
   boUnit(cUnitTypeToxotes, cBOStepUnit, 3);

   // Make sure we can maintain all these unit commands.
   boVillager(cUnitTypeVillagerGreek, cResourceGold);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);
   boVillager(cUnitTypeVillagerGreek, cResourceWood);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);
   boVillager(cUnitTypeVillagerGreek, cResourceGold);
   boVillager(cUnitTypeVillagerGreek, cResourceGold);

   boTech(cTechSarissa, cUnitTypeMilitaryAcademy);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechSarissa) >= 0.01;}, 5, cNoWarning);

   boEnd();
}

void boGreekAresClassical()
{
   aiEcho("Picked BO: boGreekAresClassical");
   boIncreaseTimeout(165);

   // Advance.
   boAdvance(cTechClassicalAgeAres, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeAres) >= 0.01;}, 15);
   // Villager Distribution we need to have: 7 - 6 - 3 - 1.
   boTransaction(0, cResourceWood);
   boTransaction(1, cResourceGold);
   boTransaction(6, cResourceGold); // Back to gold from favor.
   boTech(cTechHandAxe, cUnitTypeStorehouse);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechHandAxe) >= 0.01;}, 30);
   boTech(cTechPickaxe, cUnitTypeStorehouse);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 65);

   // Get some Toxotes and heroes, together with the Cyclops we're well set up.
   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeArcheryRange, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);

   if (cMyCiv == cCivHades)
   {
      boUnit(cUnitTypeAjax, cBOStepUnit, 1);
      boWait(1); // Make sure the hero is queued, and then we can add another Villager into the same queue.
      boUnit(cUnitTypeAchilles, cBOStepUnit, 1);
   }
   else // Poseidon.
   {
      boUnit(cUnitTypeTheseus, cBOStepUnit, 1);
      boWait(1); // Make sure the hero is queued, and then we can add another Villager into the same queue.
      boUnit(cUnitTypeAtalanta, cBOStepUnit, 1);
   }
   boUnit(cUnitTypeToxotes, cBOStepUnit, 4);

   boVillager(cUnitTypeVillagerGreek, cResourceWood);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);
   boVillager(cUnitTypeVillagerGreek, cResourceWood);
   boVillager(cUnitTypeVillagerGreek, cResourceGold);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);

   boTech(cTechEnyosBowOfHorror, cUnitTypeArcheryRange);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechEnyosBowOfHorror) >= 0.01;}, 5, cNoWarning);

   boEnd();
}

void boPoseidonHermesClassical()
{
   aiEcho("Picked BO: boPoseidonHermesClassical");
   boIncreaseTimeout(160);

   // Advance.
   boAdvance(cTechClassicalAgeHermes, cBOStepNotBlocking);
   boConditionalWait([]()->bool {return kbTechGetPercentComplete(cTechClassicalAgeHermes) >= 0.01;}, 15);
   // Villager Distribution we need to have: 7 - 6 - 3 - 1.
   boTransaction(1, cResourceWood);
   boTransaction(2, cResourceGold);
   // We get the required favor for Centaur mid-way through Classical Age, which is fine cuz we need more gold for Hippeus.
   boTransaction(6, cResourceGold);
   boTech(cTechHandAxe, cUnitTypeStorehouse);
   boConditionalWait([]()->bool {return kbPlayerGetAge(cMyID) >= cAge2;}, 65);

   // Heavy Hippeus focus with a set up for Toxotes.
   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromWoodPlan);
   boBuild(cUnitTypeStable, cUnitTypeVillagerGreek, 1, loanVillagerFromGoldPlan);
   boBuild(cUnitTypeArcheryRange, cUnitTypeVillagerGreek, 1, loanVillagerFromGoldPlan);

   boUnit(cUnitTypeTheseus, cBOStepUnit, 1);
   boWait(1); // Make sure the hero is queued, and then we can add another Villager into the same queue.
   boUnit(cUnitTypeHippeus, cBOStepUnit, 3);
   boUnit(cUnitTypeToxotes, cBOStepUnit, 1);
   boUnit(cUnitTypeCentaur, cBOStepUnit, 1);

   // We have enough wood for Centaurs, but we need food for Villagers and later more gold for Hippeus.
   boVillager(cUnitTypeVillagerGreek, cResourceGold);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerGreek, cResourceFood);
   boVillager(cUnitTypeVillagerGreek, cResourceGold);
   boBuild(cUnitTypeHouse, cUnitTypeVillagerGreek, 1, loanVillagerFromGoldPlan);
   boVillager(cUnitTypeVillagerGreek, cResourceGold);

   boEnd();
}