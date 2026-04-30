void dmSelectNorseClassicalMinorGod(ref int ageUpTechID, ref int classicalMythPUID)
{
   switch (cMyCiv)
   {
      case cCivThor:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechClassicalAgeFreyja;
            classicalMythPUID = cUnitTypeValkyrie;
         }
         else
         {
            ageUpTechID = cTechClassicalAgeForseti;
            classicalMythPUID = cUnitTypeTroll;
         }
         break;
      }
      case cCivOdin:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechClassicalAgeFreyja;
            classicalMythPUID = cUnitTypeValkyrie;
         }
         else
         {
            ageUpTechID = cTechClassicalAgeHeimdall;
            classicalMythPUID = cUnitTypeEinheri;
         }
         break;
      }
      case cCivLoki:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechClassicalAgeForseti;
            classicalMythPUID = cUnitTypeTroll;
         }
         else
         {
            ageUpTechID = cTechClassicalAgeHeimdall;
            classicalMythPUID = cUnitTypeEinheri;
         }
         break;
      }
      case cCivFreyr:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechClassicalAgeUllr;
            classicalMythPUID = cUnitTypeDraugr;
         }
         else
         {
            ageUpTechID = cTechClassicalAgeFreyja;
            classicalMythPUID = cUnitTypeValkyrie;
         }
         break;
      }
   }
}
void dmSelectNorseHeroicMinorGod(ref int ageUpTechID, ref int heroicMythPUID)
{
   switch (cMyCiv)
   {
      case cCivThor:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechHeroicAgeBragi;
            heroicMythPUID = cUnitTypeBattleBoar;
         }
         else
         {
            ageUpTechID = cTechHeroicAgeSkadi;
            heroicMythPUID = cUnitTypeFrostGiant;
         }
         break;
      }
      case cCivOdin:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechHeroicAgeSkadi;
            heroicMythPUID = cUnitTypeFrostGiant;
         }
         else
         {
            ageUpTechID = cTechHeroicAgeNjord;
            heroicMythPUID = cUnitTypeMountainGiant;
         }
         break;
      }
      case cCivLoki:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechHeroicAgeBragi;
            heroicMythPUID = cUnitTypeBattleBoar;
         }
         else
         {
            ageUpTechID = cTechHeroicAgeNjord;
            heroicMythPUID = cUnitTypeMountainGiant;
         }
         break;
      }
      case cCivFreyr:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechHeroicAgeBragi;
            heroicMythPUID = cUnitTypeBattleBoar;
         }
         else
         {
            ageUpTechID = cTechHeroicAgeAegir;
            heroicMythPUID = cUnitTypeRockGiant;
         }
         break;
      }
   }
}

void dmSelectNorseMythicMinorGod(ref int ageUpTechID, ref int mythicMythPUID)
{
   switch (cMyCiv)
   {
      case cCivThor:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechMythicAgeBaldr;
            mythicMythPUID = cUnitTypeFireGiant;
         }
         else
         {
            ageUpTechID = cTechMythicAgeTyr;
            mythicMythPUID = cUnitTypeFenrisWolfBrood;
         }
         break;
      }
      case cCivOdin:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechMythicAgeBaldr;
            mythicMythPUID = cUnitTypeFireGiant;
         }
         else
         {
            ageUpTechID = cTechMythicAgeTyr;
            mythicMythPUID = cUnitTypeFenrisWolfBrood;
         }
         break;
      }
      case cCivLoki:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechMythicAgeHel;
            mythicMythPUID = cUnitTypeFireGiant;
         }
         else
         {
            ageUpTechID = cTechMythicAgeTyr;
            mythicMythPUID = cUnitTypeFenrisWolfBrood;
         }
         break;
      }
      case cCivFreyr:
      {
         if (xsRandBool() == true)
         {
            ageUpTechID = cTechMythicAgeBaldr;
            mythicMythPUID = cUnitTypeFireGiant;
         }
         else
         {
            ageUpTechID = cTechMythicAgeVidar;
            mythicMythPUID = cUnitTypeFafnir;
         }
         break;
      }
   }
}

void boNorseDeathMatch()
{
   aiEcho("Picked BO: boNorseDeathMatch.");
   boIncreaseTimeout(180);

   // ARCHAIC.
   boBuild(cUnitTypeTemple, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 4, dmAssignBuilderMainBase);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmAssignBuilderMainBase, "internalBOHouseChainDM");
   boUnit(cUnitTypeBerserk, cBOStepUnit, 2);
   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeTemple, cMyID, cUnitStateAlive) >= 1;}, 40);
   // Move the defend plan now, otherwise fixupDefendPlanMGP will overwrite us again.
   boExecute(moveDefendPlanSecondBase);
   if (cMyCiv == cCivThor)
   {
      boWait(1); // Make sure the Berserks are really available and not stuck last frame in build plan.
      boBuild(gArmoryUnit, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmAssignBuilderMainBase);
   }

   // Age up.
   int ageUpTechID = -1;
   int classicalMythPUID = -1;
   dmSelectNorseClassicalMinorGod(ageUpTechID, classicalMythPUID);
   boAdvance(ageUpTechID, cBOStepBlocking);

   //////////////////////////////////////////////////////////////////
   // CLASSICAL.
   if (cMyCiv == cCivOdin)
   {
      boActivateRule("assignRavensToExplorationPlans");
      boExecute(setupRavenScoutPlans); // The scout plans already exist at this point so this is safe.
   }
   
   boUnit(classicalMythPUID, cBOStepUnit, selectByDifficulty(1, 1, 1, 2, 2, 2));
   boUnit(cUnitTypeBerserk, cBOStepUnit, cMyCiv == cCivThor ? 3 : 4); // We get Armory earlier as Thor so less time here.
   boUnit(cUnitTypeHersir, cBOStepUnit, selectByDifficulty(1, 1, 2, 3, 4, 4), cBOStepNotBlocking, cUnitTypeGreatHall);
   boUnit(cUnitTypeThrowingAxeman, cBOStepUnit, selectByDifficulty(2, 4, 6, 8, 10, 12));
   boUnit(cUnitTypeHirdman, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));

   // 7 Berserks alive, 1 on Houses -> 6 to task (5 if Thor cuz 1 is one Armory).
   if (cMyCiv != cCivThor)
   {
      boBuild(gArmoryUnit, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmAssignBuilderMainBase);
   }
   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmAssignBuilderMainBase);
   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmAssignBuilderSecondBase);
   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmAssignBuilderSecondBase);
   boBuild(cUnitTypeGreatHall, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmAssignBuilderSecondBase);
   boBuild(cUnitTypeGreatHall, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmAssignBuilderSecondBase);

   boActivateRule("dmHelpWithAgeUpBuildings");
   boConditionalWait([]()->bool {return kbUnitCount(gArmoryUnit, cMyID, cUnitStateAlive) >= 1;}, 55);

   // Age up.
   int heroicMythPUID = -1;
   dmSelectNorseHeroicMinorGod(ageUpTechID, heroicMythPUID);
   boAdvance(ageUpTechID, cBOStepBlocking);

   //////////////////////////////////////////////////////////////////
   // HEROIC.
   boUnit(heroicMythPUID, cBOStepUnit, selectByDifficulty(1, 1, 1, 2, 2, 2));
   boUnit(cUnitTypeBerserk, cBOStepUnit, 4, cBOStepNotBlocking, cUnitTypeTownCenter);
   boUnit(cUnitTypeGodi, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
   boUnit(cUnitTypeBerserk, cBOStepUnit, selectByDifficulty(3, 6, 9, 12, 15, 18), cBOStepNotBlocking, cUnitTypeLonghouse);
   boUnit(cUnitTypeThrowingAxeman, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));
   boUnit(cUnitTypeHuskarl, cBOStepUnit, selectByDifficulty(1, 2, 3, 4, 5, 6));

   // 5 Berserks available. (4 if Thor since we built 1 fewer in Classical)
   boBuild(cUnitTypeHillFort, cUnitTypeLogicalTypeNorseSoldierThatBuilds, cMyCiv == cCivThor ? 1 : 2, dmAssignBuilderSecondBase);
   boBuild(cUnitTypeHillFort, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmAssignBuilderMainBase);
   boBuild(cUnitTypeLonghouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmAssignBuilderMainBase);
   boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmAssignBuilderMainBase, "internalBOHouseChainDM");

   boConditionalWait([]()->bool {return kbUnitCount(cUnitTypeHillFort, cMyID, cUnitStateAlive) >= 1;}, 60);

   // Age up.
   int mythicMythPUID = -1;
   dmSelectNorseMythicMinorGod(ageUpTechID, mythicMythPUID);
   boAdvance(ageUpTechID, cBOStepBlocking);

   //////////////////////////////////////////////////////////////////
   // MYTHIC.
   boUnit(mythicMythPUID, cBOStepUnit, selectByDifficulty(1, 1, 1, 2, 2, 2));

   // LOTS of builders...
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      boBuild(cUnitTypeHillFort, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 2, dmAssignBuilderSecondBase);
      if (cPersonalityCurrent == cPersonalityDefender)
      {
         boBuild(cUnitTypeSentryTower, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 2, dmAssignBuilderSecondBase);
      }
      if (cDifficultyCurrent >= cDifficultyExtreme)
      {
         boBuild(cUnitTypeSentryTower, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 2, dmAssignBuilderSecondBase);
         boBuild(cUnitTypeSentryTower, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 2, dmAssignBuilderSecondBase);
         boBuild(cUnitTypeSentryTower, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 2, dmAssignBuilderSecondBase);
      }
   }
   
   if (cDifficultyCurrent >= cDifficultyTitan)
   {
      boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmCreateBuildPlanMainBaseNoBuilders);
      boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmCreateBuildPlanMainBaseNoBuilders);
      boBuild(cUnitTypeHouse, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmCreateBuildPlanMainBaseNoBuilders);

      if (cDifficultyCurrent >= cDifficultyExtreme)
      {
         boBuild(cUnitTypeGreatHall, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmAssignBuilderMainBase);
         boBuild(cUnitTypeGreatHall, cUnitTypeLogicalTypeNorseSoldierThatBuilds, 1, dmAssignBuilderMainBase);
      }
   }

   boExecute(dmBuildTownCenterSecondBase);
   boEnd();
}