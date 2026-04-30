void dmSelectEgyptianClassicalMinorGod(ref int ageUpTechID, ref int classicalMythPUID)
{
   switch (cMyCiv)
   {
      case cCivRa:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechClassicalAgeBast;
            classicalMythPUID = cUnitTypeSphinx;
         }
         else
         {
            ageUpTechID = cTechClassicalAgePtah;
            classicalMythPUID = cUnitTypeWadjet;
         }
         break;
      }
      case cCivIsis:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechClassicalAgeBast;
            classicalMythPUID = cUnitTypeSphinx;
         }
         else
         {
            ageUpTechID = cTechClassicalAgeAnubis;
            classicalMythPUID = cUnitTypeAnubite;
         }
         break;
      }
      case cCivSet:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechClassicalAgePtah;
            classicalMythPUID = cUnitTypeWadjet;
         }
         else
         {
            ageUpTechID = cTechClassicalAgeAnubis;
            classicalMythPUID = cUnitTypeAnubite;
         }
         break;
      }
   }
}

void dmSelectEgyptianHeroicMinorGod(ref int ageUpTechID, ref int heroicMythPUID)
{
   switch (cMyCiv)
   {
      case cCivRa:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechHeroicAgeSobek;
            heroicMythPUID = cUnitTypePetsuchos;
         }
         else
         {
            ageUpTechID = cTechHeroicAgeSekhmet;
            heroicMythPUID = cUnitTypeScarab;
         }
         break;
      }
      case cCivIsis:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechHeroicAgeSobek;
            heroicMythPUID = cUnitTypePetsuchos;
         }
         else
         {
            ageUpTechID = cTechHeroicAgeNephthys;
            heroicMythPUID = cUnitTypeScorpionMan;
         }
         break;
      }
      case cCivSet:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechHeroicAgeSekhmet;
            heroicMythPUID = cUnitTypeScarab;
         }
         else
         {
            ageUpTechID = cTechHeroicAgeNephthys;
            heroicMythPUID = cUnitTypeScorpionMan;
         }
         break;
      }
   }
}

void dmSelectEgyptianMythicMinorGod(ref int ageUpTechID, ref int mythicMythPUID)
{
   switch (cMyCiv)
   {
      case cCivRa:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechMythicAgeOsiris;
            mythicMythPUID = cUnitTypeMummy;
         }
         else
         {
            ageUpTechID = cTechMythicAgeHorus;
            mythicMythPUID = cUnitTypeAvenger;
         }
         break;
      }
      case cCivIsis:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechMythicAgeOsiris;
            mythicMythPUID = cUnitTypeMummy;
         }
         else
         {
            ageUpTechID = cTechMythicAgeThoth;
            mythicMythPUID = cUnitTypePhoenix;
         }
         break;
      }
      case cCivSet:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechMythicAgeHorus;
            mythicMythPUID = cUnitTypeAvenger;
         }
         else
         {
            ageUpTechID = cTechMythicAgeThoth;
            mythicMythPUID = cUnitTypePhoenix;
         }
         break;
      }
   }
}

void boEgyptianDeathMatch()
{
   aiEcho("Picked BO: boEgyptianDeathMatch.");
   // 13 Starting Villagers.
   for (int i = 0; i < 13; i++)
   {
      boVillager(cUnitTypeVillagerEgyptian);
   }

   boIncreaseTimeout(120);
   // ARCHAIC.
   boActivateRule("dmHelpWithAgeUpBuildings");
   boBuild(cUnitTypeTemple, cUnitTypeAbstractVillager, 9, dmAssignBuilderMainBase);
   boBuild(cUnitTypeHouse, cUnitTypeAbstractVillager, 3, dmAssignBuilderMainBase, "internalBOHouseChainDM");
   boBuild(cUnitTypeMonumentToVillagers, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   boEmpower(cUnitTypeTemple);
   boVillager(cUnitTypeVillagerEgyptian);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateAlive) >= 1;}, 20);

   // Age up.
   int ageUpTechID = -1;
   int classicalMythPUID = -1;
   dmSelectEgyptianClassicalMinorGod(ageUpTechID, classicalMythPUID);
   boAdvance(ageUpTechID, cBOStepBlocking);

   //////////////////////////////////////////////////////////////////
   // CLASSICAL.
   boUnit(classicalMythPUID, cBOStepUnit, selectByDifficulty(1, 1, 1, 2, 2, 2));
   boUnit(cUnitTypeAxeman, cBOStepUnit, selectByDifficulty(2, 4, 6, 8, 10, 12));
   boUnit(cUnitTypeSpearman, cBOStepUnit, selectByDifficulty(2, 4, 6, 8, 10, 12));
   boUnit(cUnitTypeSlinger, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
   boUnit(cUnitTypeChariotArcher, cBOStepUnit, selectByDifficulty(2, 4, 6, 8, 10, 12));
   boUnit(cUnitTypeCamelRider, cBOStepUnit, selectByDifficulty(1, 2, 2, 2, 3, 3));
   boUnit(cUnitTypeWarElephant, cBOStepUnit, selectByDifficulty(1, 2, 2, 2, 3, 3));
   boUnit(cUnitTypeSiegeTower, cBOStepUnit, selectByDifficulty(1, 1, 2, 3, 4, 5));

   // 14 Villagers alive, 3 on Houses, 1 that could still be occupied -> 10 to task.
   boBuild(gArmoryUnit, cUnitTypeAbstractVillager, 8, dmAssignBuilderMainBase);
   boEmpower(gArmoryUnit);
   boBuild(cUnitTypeBarracks, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   boBuild(cUnitTypeBarracks, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);

   boExecute(moveDefendPlanSecondBase);
   boVillager(cUnitTypeVillagerEgyptian);
   boConditionalWait([]()->bool {return kbUnitCount(gArmoryUnit, cMyID, cUnitStateAlive) >= 1;}, 20);

   // Age up.
   int heroicMythPUID = -1;
   dmSelectEgyptianHeroicMinorGod(ageUpTechID, heroicMythPUID);
   boAdvance(ageUpTechID, cBOStepBlocking);

   //////////////////////////////////////////////////////////////////
   // HEROIC.
   boUnit(heroicMythPUID, cBOStepUnit, selectByDifficulty(1, 1, 1, 2, 2, 2));

   // 15 Villagers alive, 3 on Houses, 2 that could still be occupied -> 10 to task.
   boBuild(cUnitTypeMonumentToSoldiers, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   boBuild(cUnitTypeMigdolStronghold, cUnitTypeAbstractVillager, 7, dmAssignBuilderSecondBase);
   boEmpower(cUnitTypeMigdolStronghold);
   boBuild(cUnitTypeSiegeWorks, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      boBuild(cUnitTypeSiegeWorks, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   }
   boVillager(cUnitTypeVillagerEgyptian);
   boVillager(cUnitTypeVillagerEgyptian);
   // We train a lot of Vills, Migdol Stronghold should be nearly done by now.
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeMigdolStronghold, cMyID, cUnitStateAlive) >= 1;}, 20);

   // Age up.
   int mythicMythPUID = -1;
   dmSelectEgyptianMythicMinorGod(ageUpTechID, mythicMythPUID);
   boAdvance(ageUpTechID, cBOStepBlocking);

   //////////////////////////////////////////////////////////////////
   // MYTHIC.
   boUnit(mythicMythPUID, cBOStepUnit, selectByDifficulty(1, 1, 1, 2, 2, 2));

   // 17 Villagers alive, 2 on Houses, 4 that could still be occupied -> 11 to task.
   boBuild(cUnitTypeMonumentToPriests, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   boBuild(cUnitTypeMigdolStronghold, cUnitTypeAbstractVillager, 3, dmAssignBuilderMainBase);
   if (cPersonalityCurrent == cPersonalityDefender)
   {
      boBuild(cUnitTypeSentryTower, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
   }
   if (cDifficultyCurrent >= cDifficultyTitan)
   {
      boBuild(cUnitTypeSentryTower, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
      boBuild(cUnitTypeSentryTower, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
      boBuild(cUnitTypeHouse, cUnitTypeAbstractVillager, 1, dmCreateBuildPlanMainBaseNoBuilders);
      boBuild(cUnitTypeHouse, cUnitTypeAbstractVillager, 1, dmCreateBuildPlanMainBaseNoBuilders);
      boBuild(cUnitTypeHouse, cUnitTypeAbstractVillager, 1, dmCreateBuildPlanMainBaseNoBuilders);
      boBuild(cUnitTypeHouse, cUnitTypeAbstractVillager, 1, dmCreateBuildPlanMainBaseNoBuilders);

      boBuild(cUnitTypeBarracks, cUnitTypeAbstractVillager, 1, dmCreateBuildPlanSecondBaseNoBuilders);
      boBuild(cUnitTypeBarracks, cUnitTypeAbstractVillager, 1, dmCreateBuildPlanSecondBaseNoBuilders);
   }
   
   boExecute(dmBuildTownCenterSecondBase);
   boActivateRule("dmEmpowerSecondTownCenterConstruction");
   boEnd();
}