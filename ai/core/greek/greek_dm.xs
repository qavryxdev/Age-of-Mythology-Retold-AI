void selectClassicalMinorGod(ref int ageUpTechID, ref int classicalMythPUID)
{
   switch (cMyCiv)
   {
      case cCivZeus:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechClassicalAgeAthena;
            classicalMythPUID = cUnitTypeMinotaur;
         }
         else
         {
            ageUpTechID = cTechClassicalAgeHermes;
            classicalMythPUID = cUnitTypeCentaur;
         }
         break;
      }
      case cCivHades:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechClassicalAgeAthena;
            classicalMythPUID = cUnitTypeMinotaur;
         }
         else
         {
            ageUpTechID = cTechClassicalAgeAres;
            classicalMythPUID = cUnitTypeCyclops;
         }
         break;
      }
      case cCivPoseidon:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechClassicalAgeAres;
            classicalMythPUID = cUnitTypeCyclops;
         }
         else
         {
            ageUpTechID = cTechClassicalAgeHermes;
            classicalMythPUID = cUnitTypeCentaur;
         }
         break;
      }
   }
}
void selectHeroicMinorGod(ref int ageUpTechID, ref int heroicMythPUID)
{
   switch (cMyCiv)
   {
      case cCivZeus:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechHeroicAgeApollo;
            heroicMythPUID = cUnitTypeManticore;
         }
         else
         {
            ageUpTechID = cTechHeroicAgeDionysus;
            heroicMythPUID = cUnitTypeHydra;
         }
         break;
      }
      case cCivHades:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechHeroicAgeAphrodite;
            heroicMythPUID = cUnitTypeNemeanLion;
         }
         else
         {
            ageUpTechID = cTechHeroicAgeApollo;
            heroicMythPUID = cUnitTypeManticore;
         }
         break;
      }
      case cCivPoseidon:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechHeroicAgeAphrodite;
            heroicMythPUID = cUnitTypeNemeanLion;
         }
         else
         {
            ageUpTechID = cTechHeroicAgeDionysus;
            heroicMythPUID = cUnitTypeHydra;
         }
         break;
      }
   }
}

void selectMythicMinorGod(ref int ageUpTechID, ref int mythicMythPUID)
{
   switch (cMyCiv)
   {
      case cCivZeus:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechMythicAgeHephaestus;
            mythicMythPUID = cUnitTypeColossus;
         }
         else
         {
            ageUpTechID = cTechMythicAgeHera;
            mythicMythPUID = cUnitTypeMedusa;
         }
         break;
      }
      case cCivHades:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechMythicAgeHephaestus;
            mythicMythPUID = cUnitTypeColossus;
         }
         else
         {
            ageUpTechID = cTechMythicAgeArtemis;
            mythicMythPUID = cUnitTypeChimera;
         }
         break;
      }
      case cCivPoseidon:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechMythicAgeHephaestus;
            mythicMythPUID = cUnitTypeColossus;
         }
         else
         {
            ageUpTechID = cTechMythicAgeArtemis;
            mythicMythPUID = cUnitTypeChimera;
         }
         break;
      }
   }
}

void boGreekDeathMatch()
{
   aiEcho("Picked BO: boGreekDeathMatch.");
   // 9 Starting Villagers.
   for (int i = 0; i < 9; i++)
   {
      boVillager(cUnitTypeVillagerGreek);
   }

   boIncreaseTimeout(160);
   // ARCHAIC.
   boActivateRule("dmHelpWithAgeUpBuildings");
   boBuild(cUnitTypeTemple, cUnitTypeAbstractVillager, 7, dmAssignBuilderMainBase);
   boBuild(cUnitTypeHouse, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase, "internalBOHouseChainDM");
   boBuild(cUnitTypeHouse, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase, "internalBOHouseChainDM");
   boVillager(cUnitTypeVillagerGreek);
   boExplore(cUnitTypeKataskopos); // Regular explore, don't do anything special.
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateAlive) >= 1;}, 30);

   // Age up.
   int ageUpTechID = -1;
   int classicalMythPUID = -1;
   selectClassicalMinorGod(ageUpTechID, classicalMythPUID);
   boAdvance(ageUpTechID, cBOStepBlocking);

   //////////////////////////////////////////////////////////////////
   // CLASSICAL.
   if (cMyCiv == cCivZeus)
   {
      boUnit(cUnitTypeJason, cBOStepUnit, 1);
      boUnit(cUnitTypeHeracles, cBOStepUnit, 1);
   }
   else if (cMyCiv == cCivHades)
   {
      boUnit(cUnitTypeAjax, cBOStepUnit, 1);
      boUnit(cUnitTypeAchilles, cBOStepUnit, 1);
   }
   else // Poseidon.
   {
      boUnit(cUnitTypeTheseus, cBOStepUnit, 1);
      boUnit(cUnitTypeAtalanta, cBOStepUnit, 1);
   }
   boUnit(classicalMythPUID, cBOStepUnit, selectByDifficulty(1, 1, 1, 2, 2, 2));
   if (cMyCiv == cCivZeus)
   {
      boUnit(cUnitTypeHoplite, cBOStepUnit, selectByDifficulty(3, 6, 9, 12, 15, 18));
      boUnit(cUnitTypeHypaspist, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeToxotes, cBOStepUnit, selectByDifficulty(2, 4, 6, 8, 10, 12));
      boUnit(cUnitTypePeltast, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeHippeus, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeProdromos, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
   }
   else if (cMyCiv == cCivHades)
   {
      boUnit(cUnitTypeHoplite, cBOStepUnit, selectByDifficulty(2, 4, 6, 8, 10, 12));
      boUnit(cUnitTypeHypaspist, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeToxotes, cBOStepUnit, selectByDifficulty(3, 6, 9, 12, 15, 18));
      boUnit(cUnitTypePeltast, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeHippeus, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeProdromos, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
   }
   else // Poseidon.
   {
      boUnit(cUnitTypeHoplite, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeHypaspist, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeToxotes, cBOStepUnit, selectByDifficulty(2, 4, 6, 8, 10, 12));
      boUnit(cUnitTypePeltast, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeHippeus, cBOStepUnit, selectByDifficulty(3, 6, 9, 12, 15, 18));
      boUnit(cUnitTypeProdromos, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
   }

   // 10 Villagers alive, 2 on Houses -> 8 to task.
   boBuild(gArmoryUnit, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   boBuild(cUnitTypeStable, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
   boBuild(cUnitTypeArcheryRange, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
   boBuild(cUnitTypeMilitaryAcademy, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
   if (cMyCiv == cCivZeus)
   {
      boBuild(cUnitTypeMilitaryAcademy, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         boBuild(cUnitTypeMilitaryAcademy, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
      }
      if (cDifficultyCurrent >= cDifficultyExtreme)
      {
         boBuild(cUnitTypeMilitaryAcademy, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
         boBuild(cUnitTypeMilitaryAcademy, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
      }
   }
   else if (cMyCiv == cCivHades)
   {
      boBuild(cUnitTypeArcheryRange, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         boBuild(cUnitTypeArcheryRange, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
      }
      if (cDifficultyCurrent >= cDifficultyExtreme)
      {
         boBuild(cUnitTypeArcheryRange, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
         boBuild(cUnitTypeArcheryRange, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
      }
   }
   else // Poseidon.
   {
      boBuild(cUnitTypeStable, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         boBuild(cUnitTypeStable, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
      }
      if (cDifficultyCurrent >= cDifficultyExtreme)
      {
         boBuild(cUnitTypeStable, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
         boBuild(cUnitTypeStable, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
      }
   }
   boExecute(moveDefendPlanSecondBase);

   boVillager(cUnitTypeVillagerGreek);
   boVillager(cUnitTypeVillagerGreek);
   boVillager(cUnitTypeVillagerGreek);
   boConditionalWait([]()->bool {return kbUnitCount(gArmoryUnit, cMyID, cUnitStateAlive) >= 1;}, 35);

   // Age up.
   int heroicMythPUID = -1;
   selectHeroicMinorGod(ageUpTechID, heroicMythPUID);
   boAdvance(ageUpTechID, cBOStepBlocking);

   //////////////////////////////////////////////////////////////////
   // HEROIC.
   if (cMyCiv == cCivZeus)
   {
      boUnit(cUnitTypeOdysseus, cBOStepUnit, 1);
   }
   else if (cMyCiv == cCivHades)
   {
      boUnit(cUnitTypeChiron, cBOStepUnit, 1);
   }
   else // Poseidon.
   {
      boUnit(cUnitTypeHippolyta, cBOStepUnit, 1);
   }
   boUnit(heroicMythPUID, cBOStepUnit, selectByDifficulty(1, 1, 1, 2, 2, 2));

   // 12 Villagers alive, 2 on Houses, 3 that could still be occupied -> 8 to task. Play it safe and not assign all.
   boBuild(cUnitTypeFortress, cUnitTypeAbstractVillager, 2, dmAssignBuilderSecondBase);
   boBuild(cUnitTypeStable, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
   boBuild(cUnitTypeArcheryRange, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
   boBuild(cUnitTypeMilitaryAcademy, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      boBuild(cUnitTypeSentryTower, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
   }

   boVillager(cUnitTypeVillagerGreek);
   boVillager(cUnitTypeVillagerGreek);
   // ATTENTION 1 less Vill.
   if (ageUpTechID != cTechHeroicAgeAphrodite)
   {
      boVillager(cUnitTypeVillagerGreek);
   }
   // We train a lot of Vills, Fortress should be nearly done by now.
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeFortress, cMyID, cUnitStateAlive) >= 1;}, 30);

   // Age up.
   int mythicMythPUID = -1;
   selectMythicMinorGod(ageUpTechID, mythicMythPUID);
   boAdvance(ageUpTechID, cBOStepBlocking);

   //////////////////////////////////////////////////////////////////
   // MYTHIC.
   if (cMyCiv == cCivZeus)
   {
      boUnit(cUnitTypeBellerophon, cBOStepUnit, 1);
   }
   else if (cMyCiv == cCivHades)
   {
      boUnit(cUnitTypePerseus, cBOStepUnit, 1);
   }
   else // Poseidon.
   {
      boUnit(cUnitTypePolyphemus, cBOStepUnit, 1);
   }
   boUnit(mythicMythPUID, cBOStepUnit, selectByDifficulty(1, 1, 1, 2, 2, 2));

   // 15 Villagers alive, 2 on Houses, 4 that could still be occupied -> 9 to task. Play it safe and not assign all.
   boBuild(cUnitTypeStable, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   boBuild(cUnitTypeArcheryRange, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   boBuild(cUnitTypeMilitaryAcademy, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      boBuild(cUnitTypeFortress, cUnitTypeAbstractVillager, 2, dmAssignBuilderMainBase);
      
   }
   // Extreme and above always 2 Towers, otherwise need to be defender.
   if (cDifficultyCurrent >= cDifficultyExtreme)
   {
      boBuild(cUnitTypeSentryTower, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
      boBuild(cUnitTypeSentryTower, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
   }
   else if (cPersonalityCurrent == cPersonalityDefender)
   {
      boBuild(cUnitTypeSentryTower, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
      if (cDifficultyCurrent >= cDifficultyHard)
      {
         boBuild(cUnitTypeSentryTower, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
      }
   }
   
   if (xsRandBool() == true)
   {
      boUnit(cUnitTypePetrobolos, cBOStepUnit, selectByDifficulty(1, 1, 2, 3, 3, 3));
   }
   else
   {
      boUnit(cUnitTypeHelepolis, cBOStepUnit, selectByDifficulty(1, 1, 2, 3, 3, 3));
   }

   boExecute(dmBuildTownCenterSecondBase);
   boEnd();
}