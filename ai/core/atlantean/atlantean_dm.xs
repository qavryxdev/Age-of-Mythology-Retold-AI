void dmSelectAtlanteanClassicalMinorGod(ref int ageUpTechID, ref int classicalMythPUID)
{
   switch (cMyCiv)
   {
      case cCivKronos:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechClassicalAgePrometheus;
            classicalMythPUID = cUnitTypePromethean;
         }
         else
         {
            ageUpTechID = cTechClassicalAgeLeto;
            classicalMythPUID = cUnitTypeAutomaton;
         }
         break;
      }
      case cCivOranos:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechClassicalAgePrometheus;
            classicalMythPUID = cUnitTypePromethean;
         }
         else
         {
            ageUpTechID = cTechClassicalAgeOceanus;
            classicalMythPUID = cUnitTypeCaladria;
         }
         break;
      }
      case cCivGaia:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechClassicalAgeOceanus;
            classicalMythPUID = cUnitTypeCaladria;
         }
         else
         {
            ageUpTechID = cTechClassicalAgeLeto;
            classicalMythPUID = cUnitTypeAutomaton;
         }
         break;
      }
   }
}

void dmSelectAtlanteanHeroicMinorGod(ref int ageUpTechID, ref int heroicMythPUID)
{
   switch (cMyCiv)
   {
      case cCivKronos:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechHeroicAgeHyperion;
            heroicMythPUID = cUnitTypeSatyr;
         }
         else
         {
            ageUpTechID = cTechHeroicAgeRheia;
            heroicMythPUID = cUnitTypeBehemoth;
         }
         break;
      }
      case cCivOranos:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechHeroicAgeHyperion;
            heroicMythPUID = cUnitTypeSatyr;
         }
         else
         {
            ageUpTechID = cTechHeroicAgeTheia;
            heroicMythPUID = cUnitTypeStymphalianBird;
         }
         break;
      }
      case cCivGaia:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechHeroicAgeRheia;
            heroicMythPUID = cUnitTypeBehemoth;
         }
         else
         {
            ageUpTechID = cTechHeroicAgeTheia;
            heroicMythPUID = cUnitTypeStymphalianBird;
         }
         break;
      }
   }
}

void dmSelectAtlanteanMythicMinorGod(ref int ageUpTechID, ref int mythicMythPUID)
{
   switch (cMyCiv)
   {
      case cCivKronos:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechMythicAgeAtlas;
            mythicMythPUID = cUnitTypeArgus;
         }
         else
         {
            ageUpTechID = cTechMythicAgeHelios;
            mythicMythPUID = cUnitTypeCentimanus;
         }
         break;
      }
      case cCivOranos:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechMythicAgeHelios;
            mythicMythPUID = cUnitTypeCentimanus;
         }
         else
         {
            ageUpTechID = cTechMythicAgeHekate;
            mythicMythPUID = cUnitTypeLampades;
         }
         break;
      }
      case cCivGaia:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechMythicAgeAtlas;
            mythicMythPUID = cUnitTypeArgus;
         }
         else
         {
            ageUpTechID = cTechMythicAgeHekate;
            mythicMythPUID = cUnitTypeLampades;
         }
         break;
      }
   }
}

void boAtlanteanDeathMatch()
{
   aiEcho("Picked BO: boAtlanteanDeathMatch.");
   // 6 Starting Villagers.
   for (int i = 0; i < 6; i++)
   {
      boVillager(cUnitTypeVillagerAtlantean);
   }

   boIncreaseTimeout(150);
   boActivateRule("dmHeroizeStartingOracles");
   if (cMyCiv != cCivGaia)
   {
      boExecute(dmHeroizeStartingCitizens);
   }
   // ARCHAIC.
   boActivateRule("dmHelpWithAgeUpBuildings");
   boBuild(cUnitTypeTemple, cUnitTypeAbstractVillager, 5, dmAssignBuilderMainBase);
   boBuild(cUnitTypeManor, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase, "internalBOHouseChainDM");
   boVillager(cUnitTypeVillagerAtlantean, -1, dmFixupCitizenMaintainPlan);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateAlive) >= 1;}, 15);
   boUnit(cUnitTypeOracle, cBOStepUnit, 1, cBOStepNotBlocking, cUnitTypeTemple, internalBOUnitDefaultCreate, "internalBOOracleTrainedDM");

   // Age up.
   int ageUpTechID = -1;
   int classicalMythPUID = -1;
   dmSelectAtlanteanClassicalMinorGod(ageUpTechID, classicalMythPUID);
   boAdvance(ageUpTechID, cBOStepBlocking);

   //////////////////////////////////////////////////////////////////
   // CLASSICAL.
   boUnit(classicalMythPUID, cBOStepUnit, selectByDifficulty(1, 1, 2, 3, 3, 3));
   if (cMyCiv == cCivKronos)
   {
      boUnit(cUnitTypeMurmillo, cBOStepUnit, selectByDifficulty(3, 6, 9, 12, 15, 18));
      boUnit(cUnitTypeArcus, cBOStepUnit, selectByDifficulty(2, 4, 6, 8, 10, 12));
      boUnit(cUnitTypeContarius, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeKatapeltes, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeTurma, cBOStepUnit, selectByDifficulty(1, 1, 1, 2, 2, 3));
      boUnit(cUnitTypeCheiroballista, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeDestroyer, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeFanatic, cBOStepUnit, selectByDifficulty(3, 6, 9, 12, 15, 18));
   }
   else if (cMyCiv == cCivOranos)
   {
      boUnit(cUnitTypeMurmillo, cBOStepUnit, selectByDifficulty(3, 6, 9, 12, 15, 18));
      boUnit(cUnitTypeArcus, cBOStepUnit, selectByDifficulty(2, 4, 6, 8, 10, 12));
      boUnit(cUnitTypeContarius, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeKatapeltes, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeTurma, cBOStepUnit, selectByDifficulty(1, 1, 1, 2, 2, 3));
      boUnit(cUnitTypeCheiroballista, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeDestroyer, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeFanatic, cBOStepUnit, selectByDifficulty(3, 6, 9, 12, 15, 18));
   }
   else // Gaia.
   {
      boUnit(cUnitTypeMurmillo, cBOStepUnit, selectByDifficulty(3, 6, 9, 12, 15, 18));
      boUnit(cUnitTypeArcus, cBOStepUnit, selectByDifficulty(2, 4, 6, 8, 10, 12));
      boUnit(cUnitTypeContarius, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeKatapeltes, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeTurma, cBOStepUnit, selectByDifficulty(1, 1, 1, 2, 2, 3));
      boUnit(cUnitTypeCheiroballista, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeDestroyer, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
      boUnit(cUnitTypeFanatic, cBOStepUnit, selectByDifficulty(3, 6, 9, 12, 15, 18));
   }

   // 7 Villagers alive, 1 on Houses -> 6 to task.
   boBuild(gArmoryUnit, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   boBuild(cUnitTypeCounterBarracks, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   boBuild(cUnitTypeCounterBarracks, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
   boBuild(cUnitTypeMilitaryBarracks, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   boBuild(cUnitTypeMilitaryBarracks, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      boBuild(cUnitTypeSentryTower, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
   }

   boExecute(moveDefendPlanSecondBase);
   boVillager(cUnitTypeVillagerAtlantean, -1, dmFixupCitizenMaintainPlan);
   boConditionalWait([]()->bool {return kbUnitCount(gArmoryUnit, cMyID, cUnitStateAlive) >= 1;}, 25);

   // Age up.
   int heroicMythPUID = -1;
   dmSelectAtlanteanHeroicMinorGod(ageUpTechID, heroicMythPUID);
   boAdvance(ageUpTechID, cBOStepBlocking);

   //////////////////////////////////////////////////////////////////
   // HEROIC.
   boUnit(heroicMythPUID, cBOStepUnit, selectByDifficulty(1, 1, 2, 3, 3, 3));
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      boUnit(cUnitTypeOracle, cBOStepUnit, 1, cBOStepNotBlocking, cUnitTypeTemple, internalBOUnitDefaultCreate, "internalBOOracleTrainedDM");
   }

   // 8 Villagers alive, 1 on Houses, 4 that could still be occupied -> 3 to task.
   boBuild(cUnitTypePalace, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      boBuild(cUnitTypePalace, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
      if (cDifficultyCurrent >= cDifficultyExtreme)
      {
         boBuild(cUnitTypePalace, cUnitTypeAbstractVillager, 1, dmAssignBuilderSecondBase);
      }
   }

   boVillager(cUnitTypeVillagerAtlantean, -1, dmFixupCitizenMaintainPlan);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypePalace, cMyID, cUnitStateAlive) >= 1;}, 30);

   // Age up.
   int mythicMythPUID = -1;
   dmSelectAtlanteanMythicMinorGod(ageUpTechID, mythicMythPUID);
   boAdvance(ageUpTechID, cBOStepBlocking);

   //////////////////////////////////////////////////////////////////
   // MYTHIC.
   boUnit(mythicMythPUID, cBOStepUnit, selectByDifficulty(1, 1, 2, 3, 3, 3));
   if (cDifficultyCurrent >= cDifficultyExtreme)
   {
      boUnit(cUnitTypeOracle, cBOStepUnit, 1, cBOStepNotBlocking, cUnitTypeTemple, internalBOUnitDefaultCreate, "internalBOOracleTrainedDM");
   }

   // 9 Villagers alive, 1 on Houses, 2 that could still be occupied -> 6 to task (3 TC).
   boBuild(cUnitTypePalace, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      boBuild(cUnitTypeMilitaryBarracks, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
      boBuild(cUnitTypeMilitaryBarracks, cUnitTypeAbstractVillager, 1, dmAssignBuilderMainBase);
   }
   
   boExecute(dmHeroizeMilitary);
   boUnit(cUnitTypeFireSiphon, cBOStepUnit, selectByDifficulty(1, 1, 2, 3, 4, 5));
   boExecute(dmBuildTownCenterSecondBase);
   boEnd();
}