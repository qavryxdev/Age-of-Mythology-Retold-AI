//==============================================================================
/* military_units.xs

   This file is intended for land/air military unit training.

*/
//==============================================================================

//==============================================================================
// greekHeroTraining
//==============================================================================
void greekHeroTraining(ref int totalAvailablePop, int originalTotalMilitaryPop = -1)
{
   int archaicHeroPUID = cUnitTypeJason;
   int classicalHeroPUID = cUnitTypeHeracles;
   int heroicHeroPUID = cUnitTypeOdysseus;
   int mythicHeroPUID = cUnitTypeBellerophon;
   if (cMyCiv == cCivHades)
   {
      archaicHeroPUID = cUnitTypeAjax;
      classicalHeroPUID = cUnitTypeAchilles;
      heroicHeroPUID = cUnitTypeChiron;
      mythicHeroPUID = cUnitTypePerseus;
   }
   else if (cMyCiv == cCivPoseidon)
   {
      archaicHeroPUID = cUnitTypeTheseus;
      classicalHeroPUID = cUnitTypeAtalanta;
      heroicHeroPUID = cUnitTypeHippolyta;
      mythicHeroPUID = cUnitTypePolyphemus;
   }
   int archaicPopCost = kbPlayerGetProtoStatInt(cMyID, archaicHeroPUID, cProtoStatPopCost);
   int classicalPopCost = kbPlayerGetProtoStatInt(cMyID, classicalHeroPUID, cProtoStatPopCost);
   int heroicPopCost = kbPlayerGetProtoStatInt(cMyID, heroicHeroPUID, cProtoStatPopCost);
   int mythicPopCost = kbPlayerGetProtoStatInt(cMyID, mythicHeroPUID, cProtoStatPopCost);
   bool alreadyHaveArchaic = false;
   bool alreadyHaveClassical = false;
   bool alreadyHaveHeroic = false;
   bool alreadyHaveMythic = false;

   int currentHeroPop = 0;
   if (aiPlanGetIsIDValid(aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, archaicHeroPUID)) == true ||
       kbUnitCount(archaicHeroPUID, cMyID) >= 1)
   {
      alreadyHaveArchaic = true;
      currentHeroPop += archaicPopCost;
   }
   if (aiPlanGetIsIDValid(aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, classicalHeroPUID)) == true ||
       kbUnitCount(classicalHeroPUID, cMyID) >= 1)
   {
      alreadyHaveClassical = true;
      currentHeroPop += classicalPopCost;
   }
   if (aiPlanGetIsIDValid(aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, heroicHeroPUID)) == true ||
       kbUnitCount(heroicHeroPUID, cMyID) >= 1)
   {
      alreadyHaveHeroic = true;
      currentHeroPop += heroicPopCost;
   }
   if (aiPlanGetIsIDValid(aiPlanGetIDByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, mythicHeroPUID)) == true ||
       kbUnitCount(mythicHeroPUID, cMyID) >= 1)
   {
      alreadyHaveMythic = true;
      currentHeroPop += mythicPopCost;
   }
   if (alreadyHaveArchaic == true && alreadyHaveClassical == true && alreadyHaveHeroic == true && alreadyHaveMythic == true)
   {
      totalAvailablePop -= currentHeroPop;
      debugMilitaryTraining("Skipping greekHeroTraining because we already have or are training all the heroes.");
      return;
   }

   int availableHeroPop = originalTotalMilitaryPop * gArmyHeroPercentage;
   int minimumHeroPop = originalTotalMilitaryPop * (gArmyHeroPercentage / 2);
   debugMilitaryTraining("availableHeroPop is: " + availableHeroPop + ", minimumHeroPop is: " + minimumHeroPop + ".");
   debugMilitaryTraining("We're starting with currentHeroPop: " + currentHeroPop + ".");
   if (availableHeroPop <= currentHeroPop)
   {
      totalAvailablePop -= currentHeroPop;
      debugMilitaryTraining("We already have currentHeroPop, skipping. availableHeroPop: " + availableHeroPop + " currentHeroPop: "
         + currentHeroPop + ".");
      return;
   }

   int targetPlayer = aiGetMostHatedPlayerID();
   if (targetPlayer > 0)
   {
      int enemyMythPop = 0;
      int queryID = useSimpleUnitQuery(cUnitTypeMythUnit, targetPlayer);
      int numResults = kbUnitQueryExecute(queryID);
      for (int i = 0; i < numResults; i++)
      {
         int enemyID = kbUnitQueryGetResult(queryID, i);
         enemyMythPop += kbPlayerGetProtoStatInt(targetPlayer, kbUnitGetProtoUnitID(enemyID), cProtoStatPopCost);
      }
      debugMilitaryTraining("Scouted a total of enemyMythPop: " + enemyMythPop);
      // We match enemy myth pop or cap at our original.
      availableHeroPop = min(availableHeroPop, enemyMythPop);
      // If our matching of the enemy pop turned out to be a really low number we use our minimum instead.
      if (availableHeroPop < minimumHeroPop)
      {
         availableHeroPop = minimumHeroPop;
         debugMilitaryTraining("Using minimumHeroPop because we haven't scouted enough enemy myth units to warrant many heroes.");
      }
      else
      {
         debugMilitaryTraining("Adjusting our availableHeroPop to: " + availableHeroPop + ", because of our scouting reports.");
      }
   }

   if (availableHeroPop <= currentHeroPop)
   {
      totalAvailablePop -= currentHeroPop;
      debugMilitaryTraining("We already have enough currentHeroPop, skipping. availableHeroPop: " + availableHeroPop + 
         " currentHeroPop: " + currentHeroPop + ".");
      return;
   }

   int heroPopToTrain = availableHeroPop - currentHeroPop;
   debugMilitaryTraining("We're going to train heroes for heroPopToTrain: " + heroPopToTrain + 
      ". Calculation: availableHeroPop(" + availableHeroPop + ") - currentHeroPop(" + currentHeroPop + ").");
   int currentAge = kbPlayerGetAge(cMyID);
   int rand = xsRandInt(0, 3);
   int oldHeroPopToTrain = heroPopToTrain;
   for (int i = 0; i < 4; i++)
   {
      switch((i + rand) % 4)
      {
         case 0:
         {
            if (alreadyHaveArchaic == false)
            {
               createSimpleTrainPlan(archaicHeroPUID, 1);
               heroPopToTrain -= archaicPopCost;
               currentHeroPop += archaicPopCost;
            }
            break;
         }
         case 1:
         {
            if (alreadyHaveClassical == false)
            {
               createSimpleTrainPlan(classicalHeroPUID, 1);
               heroPopToTrain -= classicalPopCost;
               currentHeroPop += classicalPopCost;
            }
            break;
         }
         case 2:
         {
            if (currentAge >= cAge3)
            {
               if (alreadyHaveHeroic == false)
               {
                  createSimpleTrainPlan(heroicHeroPUID, 1);
                  heroPopToTrain -= heroicPopCost;
                  currentHeroPop += heroicPopCost;
               }
            }
            break;
         }
         case 3:
         {
            if (currentAge >= cAge4)
            {
               if (alreadyHaveMythic == false)
               {
                  createSimpleTrainPlan(mythicHeroPUID, 1);
                  heroPopToTrain -= mythicPopCost;
                  currentHeroPop += mythicPopCost;
               }
            }
            break;
         }
      }
      if (heroPopToTrain <= 0)
      {
         totalAvailablePop -= currentHeroPop;
         return;
      }
   }
   if (oldHeroPopToTrain == heroPopToTrain)
   {
      debugMilitaryTraining("We couldn't create a train plan for any hero, maybe we already have all that are available to us.");
   }
   totalAvailablePop -= currentHeroPop;
}

//==============================================================================
// egyptianHeroTraining
//==============================================================================
void egyptianHeroTraining(ref int totalAvailablePop, int originalTotalMilitaryPop = -1)
{
   int planID = gArmyUnitMaintainPlans[gMaintainPlanHeroStartIndex];
   if (aiPlanGetIsIDValid(planID) == false)
   {
      planID = createSimpleMaintainPlan(cUnitTypePriest, 0, -1, 50, -1, -1, true);
      gArmyUnitMaintainPlans[gMaintainPlanHeroStartIndex] = planID;
   }
   
   int availableHeroPop = originalTotalMilitaryPop * gArmyHeroPercentage;
   int minimumHeroPop = originalTotalMilitaryPop * (gArmyHeroPercentage / 2);
   debugMilitaryTraining("availableHeroPop is: " + availableHeroPop + ", minimumHeroPop is: " + minimumHeroPop + ".");

   int targetPlayer = aiGetMostHatedPlayerID();
   if (targetPlayer > 0)
   {
      int enemyMythPop = 0;
      int queryID = useSimpleUnitQuery(cUnitTypeMythUnit, targetPlayer);
      int numResults = kbUnitQueryExecute(queryID);
      for (int i = 0; i < numResults; i++)
      {
         int enemyID = kbUnitQueryGetResult(queryID, i);
         enemyMythPop += kbPlayerGetProtoStatInt(targetPlayer, kbUnitGetProtoUnitID(enemyID), cProtoStatPopCost);
      }
      debugMilitaryTraining("Scouted a total of enemyMythPop: " + enemyMythPop);
      // We match enemy myth pop or cap at our original.
      availableHeroPop = min(availableHeroPop, enemyMythPop);
      // If our matching of the enemy pop turned out to be a really low number we use our minimum instead.
      if (availableHeroPop < minimumHeroPop)
      {
         availableHeroPop = minimumHeroPop;
         debugMilitaryTraining("Using minimumHeroPop because we haven't scouted enough enemy myth units to warrant many heroes.");
      }
      else
      {
         debugMilitaryTraining("Adjusting our availableHeroPop to: " + availableHeroPop + ", because of our scouting reports.");
      }
   }

   int priestPopCost = kbPlayerGetProtoStatInt(cMyID, cUnitTypePriest, cProtoStatPopCost);
   int numberToMaintain = availableHeroPop / priestPopCost;
   // It could be that this plan is already perfectly set up, then don't do anything.
   if (aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0) == numberToMaintain)
   {
      debugMilitaryTraining("Maintain plan for " + numberToMaintain + " " + kbProtoUnitGetName(cUnitTypePriest) +
         " doesn't require any changes.");
   }
   else
   {
      aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);
      aiPlanSetName(planID, planID + ": Hero maintain: " + numberToMaintain + " " + kbProtoUnitGetName(cUnitTypePriest));
      debugMilitaryTraining("Adjusting maintain plan for " + kbProtoUnitGetName(cUnitTypePriest) + " to maintain " + numberToMaintain + ".");
   }
   totalAvailablePop -= numberToMaintain * priestPopCost;
}

//==============================================================================
// norseHeroTraining
//==============================================================================
void norseHeroTraining(ref int totalAvailablePop, int originalTotalMilitaryPop = -1)
{
   int hersirPlanID = gArmyUnitMaintainPlans[gMaintainPlanHeroStartIndex];
   if (aiPlanGetIsIDValid(hersirPlanID) == false)
   {
      hersirPlanID = createSimpleMaintainPlan(cUnitTypeHersir, 0, -1, 50, -1, -1, true);
      gArmyUnitMaintainPlans[gMaintainPlanHeroStartIndex] = hersirPlanID;
   }

   int godiPlanID = gArmyUnitMaintainPlans[gMaintainPlanHeroStartIndex + 1];
   bool godiEnabled = false;
   if (kbProtoUnitAvailable(cUnitTypeGodi) == true)
   {
      if (aiPlanGetIsIDValid(godiPlanID) == false)
      {
         godiPlanID = createSimpleMaintainPlan(cUnitTypeGodi, 0, -1, 50, -1, -1, true);
      }
      gArmyUnitMaintainPlans[gMaintainPlanHeroStartIndex + 1] = godiPlanID;
      godiEnabled = true;
   }

   int availableHeroPop = originalTotalMilitaryPop * gArmyHeroPercentage;
   int minimumHeroPop = originalTotalMilitaryPop * (gArmyHeroPercentage / 2);
   debugMilitaryTraining("availableHeroPop is: " + availableHeroPop + ", minimumHeroPop is: " + minimumHeroPop + ".");

   int targetPlayer = aiGetMostHatedPlayerID();
   if (targetPlayer > 0)
   {
      int enemyMythPop = 0;
      int queryID = useSimpleUnitQuery(cUnitTypeMythUnit, targetPlayer);
      int numResults = kbUnitQueryExecute(queryID);
      for (int i = 0; i < numResults; i++)
      {
         int enemyID = kbUnitQueryGetResult(queryID, i);
         enemyMythPop += kbPlayerGetProtoStatInt(targetPlayer, kbUnitGetProtoUnitID(enemyID), cProtoStatPopCost);
      }
      debugMilitaryTraining("Scouted a total of enemyMythPop: " + enemyMythPop);
      // We match enemy myth pop or cap at our original.
      availableHeroPop = min(availableHeroPop, enemyMythPop);
      // If our matching of the enemy pop turned out to be a really low number we use our minimum instead.
      if (availableHeroPop < minimumHeroPop)
      {
         availableHeroPop = minimumHeroPop;
         debugMilitaryTraining("Using minimumHeroPop because we haven't scouted enough enemy myth units to warrant many heroes.");
      }
      else
      {
         debugMilitaryTraining("Adjusting our availableHeroPop to: " + availableHeroPop + ", because of our scouting reports.");
      }
   }

   int numMilitaryBuildings = gMilitaryBuildings.size();
   int buildingPUID = -1;
   int hersirPopCost = kbPlayerGetProtoStatInt(cMyID, cUnitTypeHersir, cProtoStatPopCost);
   int godiPopCost = kbPlayerGetProtoStatInt(cMyID, cUnitTypeGodi, cProtoStatPopCost);

   if (godiEnabled == false)
   {
      int numberToMaintain = 0;
      while (availableHeroPop > 0)
      {
         numberToMaintain++;
         availableHeroPop -= hersirPopCost;
      }
      // It could be that this plan is already perfectly set up, then don't do anything.
      if (aiPlanGetVariableInt(hersirPlanID, cTrainPlanNumberToMaintain, 0) == numberToMaintain)
      {
         debugMilitaryTraining("Maintain plan for " + numberToMaintain + " " + kbProtoUnitGetName(cUnitTypeHersir) +
            " doesn't require any changes.");
      }
      else
      {
         aiPlanSetVariableInt(hersirPlanID, cTrainPlanNumberToMaintain, 0, numberToMaintain);
         aiPlanSetName(hersirPlanID, hersirPlanID + ": Hero maintain: " + numberToMaintain + " " + kbProtoUnitGetName(cUnitTypeHersir));
         debugMilitaryTraining("Adjusting maintain plan for " + kbProtoUnitGetName(cUnitTypeHersir) + " to maintain " + numberToMaintain + ".");
      }
      for (int j = 0; j < numMilitaryBuildings; j++)
      {
         buildingPUID = gMilitaryBuildings[j];
         if (kbProtoUnitCanTrain(buildingPUID, cUnitTypeHersir) == true)
         {
            gArmyUnitBuildings[gMaintainPlanHeroStartIndex] = buildingPUID;
            break;
         }
      }
      totalAvailablePop -= numberToMaintain * hersirPopCost;
      return;
   }
   else
   {
      int maintainHersirAmount = 0;
      int maintainGodiAmount = 0;
      while (availableHeroPop > 0)
      {
         int rand = xsRandInt(0, 2);
         if (rand == 0)
         {
            maintainHersirAmount++;
            availableHeroPop -= hersirPopCost;
         }
         else if (rand == 1)
         {
            if (cMyCiv == cCivLoki)
            {
               maintainHersirAmount++;
               availableHeroPop -= hersirPopCost;
            }
            else
            {
               maintainGodiAmount++;
               availableHeroPop -= godiPopCost;
            }
         }
         else
         {
            maintainGodiAmount++;
            availableHeroPop -= godiPopCost;
         }
      }

      // It could be that this plan is already perfectly set up, then don't do anything.
      if (aiPlanGetVariableInt(hersirPlanID, cTrainPlanNumberToMaintain, 0) == maintainHersirAmount)
      {
         debugMilitaryTraining("Maintain plan for " + maintainHersirAmount + " " + kbProtoUnitGetName(cUnitTypeHersir) +
            " doesn't require any changes.");
      }
      else
      {
         aiPlanSetVariableInt(hersirPlanID, cTrainPlanNumberToMaintain, 0, maintainHersirAmount);
         aiPlanSetName(hersirPlanID, hersirPlanID + ": Hero maintain: " + maintainHersirAmount + " " + kbProtoUnitGetName(cUnitTypeHersir));
         debugMilitaryTraining("Adjusting maintain plan for " + kbProtoUnitGetName(cUnitTypeHersir) + " to maintain " + maintainHersirAmount + ".");
      }
      // v2.7 BUG34 FIX: bylo hersirPlanID (plan ID ≠ unit type) → kbProtoUnitCanTrain nikdy nenasel budovu.
      // Bylo gMaintainPlanSiegeStartIndex → budova se ulozila do siege slotu misto hero slotu.
      for (int j = 0; j < numMilitaryBuildings; j++)
      {
         buildingPUID = gMilitaryBuildings[j];
         if (kbProtoUnitCanTrain(buildingPUID, cUnitTypeHersir) == true)
         {
            gArmyUnitBuildings[gMaintainPlanHeroStartIndex] = buildingPUID;
            break;
         }
      }

      // It could be that this plan is already perfectly set up, then don't do anything.
      if (aiPlanGetVariableInt(godiPlanID, cTrainPlanNumberToMaintain, 0) == maintainGodiAmount)
      {
         debugMilitaryTraining("Maintain plan for " + maintainGodiAmount + " " + kbProtoUnitGetName(cUnitTypeGodi) +
            " doesn't require any changes.");
      }
      else
      {
         aiPlanSetVariableInt(godiPlanID, cTrainPlanNumberToMaintain, 0, maintainGodiAmount);
         aiPlanSetName(godiPlanID, godiPlanID + ": Hero maintain: " + maintainGodiAmount + " " + kbProtoUnitGetName(cUnitTypeGodi));
         debugMilitaryTraining("Adjusting maintain plan for " + kbProtoUnitGetName(cUnitTypeGodi) + " to maintain " + maintainGodiAmount + ".");
      }
      for (int j = 0; j < numMilitaryBuildings; j++)
      {
         buildingPUID = gMilitaryBuildings[j];
         if (kbProtoUnitCanTrain(buildingPUID, cUnitTypeGodi) == true)
         {
            // v2.7 BUG34 FIX: bylo gMaintainPlanSiegeStartIndex+1 → Godi budova psala do siege slotu.
            gArmyUnitBuildings[gMaintainPlanHeroStartIndex + 1] = buildingPUID;
            break;
         }
      }

      totalAvailablePop -= maintainHersirAmount * hersirPopCost;
      totalAvailablePop -= maintainGodiAmount * godiPopCost;
   }
}

//==============================================================================
// atlanteanHeroTraining
//==============================================================================
void atlanteanHeroTraining(ref int totalAvailablePop, int originalTotalMilitaryPop = -1)
{
   static int murmilloHeroPop = -1;
   static int contariusHeroPop = -1;
   static int katapeltesHeroPop = -1;
   static int destroyerHeroPop = -1;
   static int fanaticHeroPop = -1;
   static int arcusHeroPop = -1;
   static int turmaHeroPop = -1;
   static int cheiroballistaHeroPop = -1;
   if (murmilloHeroPop == -1) // First run.
   {
      murmilloHeroPop = kbPlayerGetProtoStatInt(cMyID, cUnitTypeMurmillo, cProtoStatPopCost);
      contariusHeroPop = kbPlayerGetProtoStatInt(cMyID, cUnitTypeContarius, cProtoStatPopCost);
      katapeltesHeroPop = kbPlayerGetProtoStatInt(cMyID, cUnitTypeKatapeltes, cProtoStatPopCost);
      destroyerHeroPop = kbPlayerGetProtoStatInt(cMyID, cUnitTypeDestroyer, cProtoStatPopCost);
      fanaticHeroPop = kbPlayerGetProtoStatInt(cMyID, cUnitTypeFanatic, cProtoStatPopCost);
      arcusHeroPop = kbPlayerGetProtoStatInt(cMyID, cUnitTypeArcus, cProtoStatPopCost);
      turmaHeroPop = kbPlayerGetProtoStatInt(cMyID, cUnitTypeTurma, cProtoStatPopCost);
      cheiroballistaHeroPop = kbPlayerGetProtoStatInt(cMyID, cUnitTypeCheiroballista, cProtoStatPopCost);
   }

   int queryID = useSimpleUnitQuery(cUnitTypeHero);
   kbUnitQueryExecute(queryID);
   int currentHeroPop = kbUnitQueryGetPopulationSlots(queryID);
   int numPlans = 0;

   // Tally up all the hero research plans we've got going on.
   numPlans = aiPlanGetNumberByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechMurmilloToHero);
   currentHeroPop += numPlans * murmilloHeroPop;
   numPlans = aiPlanGetNumberByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechContariusToHero);
   currentHeroPop += numPlans * contariusHeroPop;
   numPlans = aiPlanGetNumberByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechKatapeltesToHero);
   currentHeroPop += numPlans * katapeltesHeroPop;
   numPlans = aiPlanGetNumberByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechDestroyerToHero);
   currentHeroPop += numPlans * destroyerHeroPop;
   numPlans = aiPlanGetNumberByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechFanaticToHero);
   currentHeroPop += numPlans * fanaticHeroPop;
   numPlans = aiPlanGetNumberByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechArcusToHero);
   currentHeroPop += numPlans * arcusHeroPop;
   numPlans = aiPlanGetNumberByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechTurmaToHero);
   currentHeroPop += numPlans * turmaHeroPop;
   numPlans = aiPlanGetNumberByTypeAndVariableIntValue(cPlanResearch, cResearchPlanTechID, cTechCheiroballistaToHero);
   currentHeroPop += numPlans * cheiroballistaHeroPop;

   // If we're too close to attacking we don't do anything because we only want to heroize idle units in our gPrimaryLandDefendPlan.
   // If we can't attack due to strategy flags we don't check this because the attack time may be unset.
   // v1.3 fix: use 20% of attack interval as cutoff window (was hardcoded 30s which blocked heroizing
   // with the aggressive 60s intervals introduced in v1.0).
   float heroizeCutoff = min(30.0, gAttackManager.mAttackInterval * 0.20);
   if (checkStrategyFlag(cStrategyFlagCanAttack) == true &&
       (xsGetTime() + heroizeCutoff > gAttackManager.mLastAttackTime + gAttackManager.mAttackInterval))
   {
      debugMilitaryTraining("Quiting atlanteanHeroTraining early because we're too close to launching an attack.");
      totalAvailablePop -= currentHeroPop;
      return;
   }

   int availableHeroPop = originalTotalMilitaryPop * gArmyHeroPercentage;
   int minimumHeroPop = originalTotalMilitaryPop * (gArmyHeroPercentage / 2);
   debugMilitaryTraining("availableHeroPop is: " + availableHeroPop + ", minimumHeroPop is: " + minimumHeroPop + ".");

   if (availableHeroPop <= currentHeroPop)
   {
      totalAvailablePop -= currentHeroPop;
      debugMilitaryTraining("We already have enough currentHeroPop, skipping. availableHeroPop: " + availableHeroPop + 
         " currentHeroPop: " + currentHeroPop + ".");
      return;
   }

   int targetPlayer = aiGetMostHatedPlayerID();
   if (targetPlayer > 0)
   {
      int enemyMythPop = 0;
      queryID = useSimpleUnitQuery(cUnitTypeMythUnit, targetPlayer);
      int numResults = kbUnitQueryExecute(queryID);
      for (int i = 0; i < numResults; i++)
      {
         int enemyID = kbUnitQueryGetResult(queryID, i);
         enemyMythPop += kbPlayerGetProtoStatInt(targetPlayer, kbUnitGetProtoUnitID(enemyID), cProtoStatPopCost);
      }
      debugMilitaryTraining("Scouted a total of enemyMythPop: " + enemyMythPop);
      // We match enemy myth pop or cap at our original.
      availableHeroPop = min(availableHeroPop, enemyMythPop);
      // If our matching of the enemy pop turned out to be a really low number we use our minimum instead.
      if (availableHeroPop < minimumHeroPop)
      {
         availableHeroPop = minimumHeroPop;
         debugMilitaryTraining("Using minimumHeroPop because we haven't scouted enough enemy myth units to warrant many heroes.");
      }
      else
      {
         debugMilitaryTraining("Adjusting our availableHeroPop to: " + availableHeroPop + ", because of our scouting reports.");
      }
   }

   if (availableHeroPop <= currentHeroPop)
   {
      totalAvailablePop -= currentHeroPop;
      debugMilitaryTraining("We already have enough currentHeroPop, skipping. availableHeroPop: " + availableHeroPop + 
         " currentHeroPop: " + currentHeroPop + ".");
      return;
   }

   int heroPopToTrain = availableHeroPop - currentHeroPop;
   debugMilitaryTraining("We're going to train heroes for heroPopToTrain: " + heroPopToTrain + 
      ". Calculation: availableHeroPop(" + availableHeroPop + ") - currentHeroPop(" + currentHeroPop + ").");

   int[] reserveUnits = aiPlanGetUnits(gPrimaryLandDefendPlan);
   int[] validMeleeUnits = new int(0, -1);
   int[] validRangedUnits = new int(0, -1);
   for (int i = 0; i < reserveUnits.size(); i++)
   {
      int unitID = reserveUnits[i];
      // Only want to heroize 100% HP units.
      if (kbUnitGetStatFloat(unitID, cUnitStatMaxHP) != kbUnitGetStatFloat(unitID, cUnitStatCurrHP))
      {
         continue;
      }
      int puid = kbUnitGetProtoUnitID(unitID);
      bool valid = false;
      bool melee = true;
      if (puid == cUnitTypeMurmillo || puid == cUnitTypeContarius || 
          puid == cUnitTypeKatapeltes ||  puid == cUnitTypeDestroyer || puid == cUnitTypeFanatic)
      {
         valid = true;
      }
      else if (puid == cUnitTypeArcus || puid == cUnitTypeTurma || puid == cUnitTypeCheiroballista)
      {
         valid = true;
         melee = false;
      }
      if (valid == true)
      {
         // Only if there are no enemies within range of this unit do we start the heroization, otherwise we may die during animation.
         // EXCEPTION: if we have 0 currentHeroPop we always let a unit go through so we always get at least 1 hero.
         if (currentHeroPop == 0 || getUnitCountByLocation(cUnitTypeMilitaryUnit, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
               kbUnitGetPosition(unitID), 20.0, cUnitQueryVisibleStateVisible) <= 0)
         {
            if (melee == true)
            {
               validMeleeUnits.add(unitID);
            }
            else
            {
               validRangedUnits.add(unitID);
            }
         }
         else
         {
            debugMilitaryTraining("Can't heroize " + unitID + " because there are enemies close.");
         }
      }
   }
   int numMeleeUnits = validMeleeUnits.size();
   int numRangedUnits = validRangedUnits.size();
   int totalUnits = numMeleeUnits + numRangedUnits;
   if (totalUnits <= 0)
   {
      totalAvailablePop -= currentHeroPop;
      debugMilitaryTraining("Quiting atlanteanHeroTraining early because there are no units in our defend plan that we can heroize.");
      return;
   }
   int meleeHeroesMade = 0;
   int rangedHeroesMade = 0;
   int unitsProcessed = 0;
   while (heroPopToTrain > 0)
   {
      static int i = 0;
      if (i % 2 == 0)
      {
         if (meleeHeroesMade < numMeleeUnits)
         {
            int prio = 50;
            if (meleeHeroesMade == 0)
            {
               prio = 51; // Put some emphasis on the first hero each run.
            }
            int unitID = validMeleeUnits[meleeHeroesMade];
            int puid = kbUnitGetProtoUnitID(unitID);
            switch (puid)
            {
               case cUnitTypeMurmillo:
               {
                  createSimpleResearchPlanSpecificResearcher(cTechMurmilloToHero, unitID, prio, true);
                  currentHeroPop += murmilloHeroPop;
                  heroPopToTrain -= murmilloHeroPop;
                  break;
               }
               case cUnitTypeContarius:
               {
                  createSimpleResearchPlanSpecificResearcher(cTechContariusToHero, unitID, prio, true);
                  currentHeroPop += contariusHeroPop;
                  heroPopToTrain -= contariusHeroPop;
                  break;
               }
               case cUnitTypeKatapeltes:
               {
                  createSimpleResearchPlanSpecificResearcher(cTechKatapeltesToHero, unitID, prio, true);
                  currentHeroPop += katapeltesHeroPop;
                  heroPopToTrain -= katapeltesHeroPop;
                  break;
               }
               case cUnitTypeDestroyer:
               {
                  createSimpleResearchPlanSpecificResearcher(cTechDestroyerToHero, unitID, prio, true);
                  currentHeroPop += destroyerHeroPop;
                  heroPopToTrain -= destroyerHeroPop;
                  break;
               }
               case cUnitTypeFanatic:
               {
                  createSimpleResearchPlanSpecificResearcher(cTechFanaticToHero, unitID, prio, true);
                  currentHeroPop += fanaticHeroPop;
                  heroPopToTrain -= fanaticHeroPop;
                  break;
               }
            }
            meleeHeroesMade++;
         }
      }
      else
      {
         if (rangedHeroesMade < numRangedUnits)
         {
            int prio = 50;
            if (rangedHeroesMade == 0)
            {
               prio = 51; // Put some emphasis on the first hero each run.
            }
            int unitID = validRangedUnits[rangedHeroesMade];
            int puid = kbUnitGetProtoUnitID(unitID);
            switch (puid)
            {
               case cUnitTypeArcus:
               {
                  createSimpleResearchPlanSpecificResearcher(cTechArcusToHero, unitID, prio, true);
                  currentHeroPop += arcusHeroPop;
                  heroPopToTrain -= arcusHeroPop;
                  break;
               }
               case cUnitTypeTurma:
               {
                  createSimpleResearchPlanSpecificResearcher(cTechTurmaToHero, unitID, prio, true);
                  currentHeroPop += turmaHeroPop;
                  heroPopToTrain -= turmaHeroPop;
                  break;
               }
               case cUnitTypeCheiroballista:
               {
                  createSimpleResearchPlanSpecificResearcher(cTechCheiroballistaToHero, unitID, prio, true);
                  currentHeroPop += cheiroballistaHeroPop;
                  heroPopToTrain -= cheiroballistaHeroPop;
                  break;
               }
            }
            rangedHeroesMade++;
         }
      }
      i++;

      unitsProcessed++;
      if (unitsProcessed == totalUnits && heroPopToTrain > 0)
      {
         debugMilitaryTraining("We don't have enough units to heroize to fully satisfy our needs.");
         break;
      }
   }
   // Finally we're done.
   totalAvailablePop -= currentHeroPop;
}

//==============================================================================
// heroMilitaryTraining
//==============================================================================
void heroMilitaryTraining(ref int totalAvailablePop, int originalTotalMilitaryPop = -1)
{
   switch (cMyCulture)
   {
      case cCultureGreek:
      {
         greekHeroTraining(totalAvailablePop, originalTotalMilitaryPop);
      }
      case cCultureEgyptian:
      {
         egyptianHeroTraining(totalAvailablePop, originalTotalMilitaryPop);
      }
      case cCultureNorse:
      {
         norseHeroTraining(totalAvailablePop, originalTotalMilitaryPop);
      }
      case cCultureAtlantean:
      {
         atlanteanHeroTraining(totalAvailablePop, originalTotalMilitaryPop);
      }
   }
}

//==============================================================================
// capUnwantedMythUnits
//==============================================================================
int capUnwantedMythUnits(int mythPUID = -1, int trainAmount = -1)
{
   if (mythPUID == cUnitTypeCaladria)
   {
      int existingUnits = kbUnitCount(mythPUID, cMyID, cUnitStateAlive);
      int[] planIDs = aiPlanGetIDsByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, mythPUID);
      for (int j = 0; j < planIDs.size(); j++)
      {
         existingUnits += aiPlanGetVariableInt(planIDs[j], cTrainPlanNumberToTrain, 0) -
                          aiPlanGetVariableInt(planIDs[j], cTrainPlanNumberTrained, 0);
      }
      return min(max(0, 2 - existingUnits), trainAmount);
   }
   return trainAmount;
}

//==============================================================================
// mythMilitaryTraining
//==============================================================================
void mythMilitaryTraining(ref int totalAvailablePop, int originalTotalMilitaryPop = -1)
{
   int[] enabledMythUnits = getAllEnabledMilitaryMythUnits(cUnitTypeTemple);
   int currentMythPop = 0;
   for (int i = 0; i < enabledMythUnits.size(); i++)
   {
      int mythPUID = enabledMythUnits[i];
      debugMilitaryTraining("mythMilitaryTraining - analyzing mythPUID: " + kbProtoUnitGetName(mythPUID));
      int popCost = kbPlayerGetProtoStatInt(cMyID, mythPUID, cProtoStatPopCost);
      currentMythPop += kbUnitCount(mythPUID, cMyID, cUnitStateABQ) * popCost;
      int[] planIDs = aiPlanGetIDsByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, mythPUID);
      for (int j = 0; j < planIDs.size(); j++)
      {
         int toTrain = aiPlanGetVariableInt(planIDs[j], cTrainPlanNumberToTrain, 0) -
                       aiPlanGetVariableInt(planIDs[j], cTrainPlanNumberTrained, 0);
         currentMythPop += toTrain * popCost;
      }
      debugMilitaryTraining("mythMilitaryTraining - currentMythPop: " + currentMythPop);
   }
   float currentMythPopPercentage = gArmyEarlyGameMythPercentage;
   if (kbPlayerGetAge(cMyID) >= cAge3) // From Heroic we start training more Myth.
   {
      currentMythPopPercentage = gArmyLateGameMythPercentage;
   }
   int availableMythPop = originalTotalMilitaryPop * currentMythPopPercentage;
   // v2.9 BUG35 FIX: bylo gArmyHeroPercentage / 2 — minimum mytickych pouzivalo procento HRDINU misto MYTICKYCH.
   // Kdyz se hero% adaptivne zvysilo (napr. proti myth-heavy nepriteli), minimum myth pop taky stouplo —
   // presny opak pozadovaneho chovani (chceme MENE mytickych proti hero-heavy nepriteli).
   int minimumMythPop = originalTotalMilitaryPop * (currentMythPopPercentage / 2);
   debugMilitaryTraining("availableMythPop is: " + availableMythPop + ", minimumMythPop is: " + minimumMythPop + ".");
   debugMilitaryTraining("We're starting with currentMythPop: " + currentMythPop + ".");
   if (availableMythPop <= currentMythPop)
   {
      totalAvailablePop -= currentMythPop;
      debugMilitaryTraining("We already have enough myth pop, skipping. Available availableMythPop: " + availableMythPop + " current: "
         + currentMythPop + ".");
      return;
   }
   
   int targetPlayer = aiGetMostHatedPlayerID();
   if (targetPlayer > 0)
   {
      int enemyHeroPop = 0;
      int queryID = useSimpleUnitQuery(cUnitTypeHero, targetPlayer);
      int numResults = kbUnitQueryExecute(queryID);
      for (int i = 0; i < numResults; i++)
      {
         int enemyID = kbUnitQueryGetResult(queryID, i);
         enemyHeroPop += kbPlayerGetProtoStatInt(targetPlayer, kbUnitGetProtoUnitID(enemyID), cProtoStatPopCost);
      }
      if (kbPlayerGetCulture(targetPlayer) == cCultureGreek)
      {
         enemyHeroPop *= 1.5;
         debugMilitaryTraining("Target player is Greek, multiplying scouted hero pop by 1.5 to account for their increased " + 
            " strength, new enemyHeroPop: " + enemyHeroPop + ".");
      }
      // If the enemy has more hero pop than 75% of our availableMythPop we use our minimumMythPop instead.
      // Because clearly the enemy has a lot of heroes, we don't want to get countered too hard.
      int treshold = availableMythPop * 0.75;
      debugMilitaryTraining("Scouted a total of enemyHeroPop: " + enemyHeroPop + ". If this number is >= " + 
         treshold + " we will use minimumMythPop.");
      if (enemyHeroPop >= treshold)
      {
         availableMythPop = minimumMythPop;
         debugMilitaryTraining("Using minimumMythPop because the enemy has too many heroes.");
      }
   }

   if (availableMythPop <= currentMythPop)
   {
      totalAvailablePop -= currentMythPop;
      debugMilitaryTraining("We already have enough currentMythPop, skipping. availableMythPop: " + availableMythPop + 
         " currentMythPop: " + currentMythPop + ".");
      return;
   }
   
   int mythPopToTrain = availableMythPop - currentMythPop;
   debugMilitaryTraining("We're going to train myth units for maximum mythPopToTrain: " + mythPopToTrain + 
      ". Calculation: availableMythPop(" + availableMythPop + ") - currentMythPop(" + currentMythPop + ").");

   // Randomly chose a myth unit to make a train plan for.
   int rand = 0;
   if (enabledMythUnits.size() > 1)
   {
      rand = xsRandInt(0, enabledMythUnits.size() - 1);
   }
   int mythPUID = enabledMythUnits[rand];
   int popCost = kbPlayerGetProtoStatInt(cMyID, mythPUID, cProtoStatPopCost);
   int trainAmount = mythPopToTrain / popCost; // Don't overshoot.
   if (trainAmount == 0)
   {
      trainAmount = 1;
   }
   else if (trainAmount > 3)
   {
      debugMilitaryTraining("Clamping our train amount to 3 because we wanted too many myth units at once.");
      trainAmount = 3; // Don't train too many of one type at once. Wait until next iteration to train more (maybe other type).
   }
   trainAmount = capUnwantedMythUnits(mythPUID, trainAmount);
   // TrainAmount could've been set to 0 by capUnwantedMythUnits.
   if (trainAmount >= 1)
   {
      createSimpleTrainPlan(mythPUID, trainAmount);
   }
   totalAvailablePop -= currentMythPop;
   totalAvailablePop -= trainAmount * popCost;
}

//==============================================================================
// siegeMilitaryTraining
//==============================================================================
void siegeMilitaryTraining(ref int totalAvailablePop, int originalTotalMilitaryPop = -1)
{
   static int siegeMaintain1 = -1;
   static int siegeMaintain2 = -2;
   static int siegePUID1 = -1;
   static int siegePUID2 = -1;
   static int siege1PopCost = -1;
   static int siege2PopCost = -1;
   if (siegePUID1 == -1) // First run.
   {
      switch (cMyCulture)
      {
         case cCultureGreek:
         {
            siegePUID1 = cUnitTypePetrobolos;
            siegePUID2 = cUnitTypeHelepolis;
            siege1PopCost = kbPlayerGetProtoStatInt(cMyID, siegePUID1, cProtoStatPopCost);
            siege2PopCost = kbPlayerGetProtoStatInt(cMyID, siegePUID2, cProtoStatPopCost);
            break;
         }
         case cCultureEgyptian:
         {
            siegePUID1 = cUnitTypeSiegeTower;
            siegePUID2 = cUnitTypeCatapult;
            siege1PopCost = kbPlayerGetProtoStatInt(cMyID, siegePUID1, cProtoStatPopCost);
            siege2PopCost = kbPlayerGetProtoStatInt(cMyID, siegePUID2, cProtoStatPopCost);
            break;
         }
         case cCultureNorse:
         {
            siegePUID1 = cUnitTypePortableRam;
            siegePUID2 = cUnitTypeBallista;
            siege1PopCost = kbPlayerGetProtoStatInt(cMyID, siegePUID1, cProtoStatPopCost);
            siege2PopCost = kbPlayerGetProtoStatInt(cMyID, siegePUID2, cProtoStatPopCost);
            break;
         }
         case cCultureAtlantean:
         {
            siegePUID1 = cUnitTypeDestroyer;
            siegePUID2 = cUnitTypeFireSiphon;
            siege1PopCost = kbPlayerGetProtoStatInt(cMyID, siegePUID1, cProtoStatPopCost);
            siege2PopCost = kbPlayerGetProtoStatInt(cMyID, siegePUID2, cProtoStatPopCost);
            break;
         }
      }
   }

   bool siege1Enabled = false;
   if (kbProtoUnitAvailable(siegePUID1) == true)
   {
      if (aiPlanGetIsIDValid(gArmyUnitMaintainPlans[gMaintainPlanSiegeStartIndex]) == false)
      {
         gArmyUnitMaintainPlans[gMaintainPlanSiegeStartIndex] = createSimpleMaintainPlan(siegePUID1, 0, -1, 50, -1, -1, true);
      }
      siege1Enabled = true;
   }
   bool siege2Enabled = false;
   if (kbProtoUnitAvailable(siegePUID2) == true)
   {
      if (aiPlanGetIsIDValid(gArmyUnitMaintainPlans[gMaintainPlanSiegeStartIndex + 1]) == false)
      {
         gArmyUnitMaintainPlans[gMaintainPlanSiegeStartIndex + 1] = createSimpleMaintainPlan(siegePUID2, 0, -1, 50, -1, -1, true);
      }
      siege2Enabled = true;
   }
   if (siege1Enabled == false && siege2Enabled == false)
   {
      debugMilitaryTraining("Quiting siegeMilitaryTraining because we're not in a high enough age yet to train siege.");
      return;
   }

   int numMilitaryBuildings = gMilitaryBuildings.size();
   int buildingPUID = -1;
   int availableSiegePop = originalTotalMilitaryPop * gArmySiegePercentage;
   if (gDefenseReflexBaseID == kbBaseGetMainID(cMyID))
   {
      debugMilitaryTraining("Not training siege because our main base is under attack, we have no use for siege now.");
      availableSiegePop = 0;
   }
   debugMilitaryTraining("availableSiegePop is: " + availableSiegePop + ".");

   if (siege1Enabled == true && siege2Enabled == false)
   {
      int planID = gArmyUnitMaintainPlans[gMaintainPlanSiegeStartIndex];
      int numberToMaintain = availableSiegePop / siege1PopCost; // Undershoot in early ages.
      // It could be that this plan is already perfectly set up, then don't do anything.
      if (aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0) == numberToMaintain)
      {
         debugMilitaryTraining("Maintain plan for " + numberToMaintain + " " + kbProtoUnitGetName(siegePUID1) +
            " doesn't require any changes.");
      }
      else
      {
         aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);
         aiPlanSetName(planID, planID + ": Siege maintain: " + numberToMaintain + " " + kbProtoUnitGetName(siegePUID1));
         debugMilitaryTraining("Adjusting maintain plan for " + kbProtoUnitGetName(siegePUID1) + " to maintain " + numberToMaintain + ".");
      }
      for (int j = 0; j < numMilitaryBuildings; j++)
      {
         buildingPUID = gMilitaryBuildings[j];
         if (kbProtoUnitCanTrain(buildingPUID, siegePUID1) == true)
         {
            gArmyUnitBuildings[gMaintainPlanSiegeStartIndex] = buildingPUID;
            break;
         }
      }
      totalAvailablePop -= numberToMaintain * siege1PopCost;
   }
   else if (siege1Enabled == false && siege2Enabled == true)
   {
      int planID = gArmyUnitMaintainPlans[gMaintainPlanSiegeStartIndex + 1];
      int numberToMaintain = availableSiegePop / siege2PopCost; // Undershoot in early ages.
      // It could be that this plan is already perfectly set up, then don't do anything.
      if (aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0) == numberToMaintain)
      {
         debugMilitaryTraining("Maintain plan for " + numberToMaintain + " " + kbProtoUnitGetName(siegePUID2) +
            " doesn't require any changes.");
      }
      else
      {
         aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);
         aiPlanSetName(planID, planID + ": Siege maintain: " + numberToMaintain + " " + kbProtoUnitGetName(siegePUID2));
         debugMilitaryTraining("Adjusting maintain plan for " + kbProtoUnitGetName(siegePUID2) + " to maintain " + numberToMaintain + ".");
      }
      for (int j = 0; j < numMilitaryBuildings; j++)
      {
         buildingPUID = gMilitaryBuildings[j];
         if (kbProtoUnitCanTrain(buildingPUID, siegePUID2) == true)
         {
            gArmyUnitBuildings[gMaintainPlanSiegeStartIndex + 1] = buildingPUID;
            break;
         }
      }
      totalAvailablePop -= numberToMaintain * siege2PopCost;
   }
   else // Both are enabled.
   {
      int maintainSiege1Amount = 0;
      int maintainSiege2Amount = 0;
      while (availableSiegePop > 0)
      {
         if (xsRandBool() == true)
         {
            maintainSiege1Amount++; // Overshoot in later ages.
            availableSiegePop -= siege1PopCost;
         }
         else
         {
            maintainSiege2Amount++; // Overshoot in later ages.
            availableSiegePop -= siege2PopCost;
         }
      }

      int planID = gArmyUnitMaintainPlans[gMaintainPlanSiegeStartIndex];
      // It could be that this plan is already perfectly set up, then don't do anything.
      if (aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0) == maintainSiege1Amount)
      {
         debugMilitaryTraining("Maintain plan for " + maintainSiege1Amount + " " + kbProtoUnitGetName(siegePUID1) +
            " doesn't require any changes.");
      }
      else
      {
         aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, maintainSiege1Amount);
         aiPlanSetName(planID, planID + ": Siege maintain: " + maintainSiege1Amount + " " + kbProtoUnitGetName(siegePUID1));
         debugMilitaryTraining("Adjusting maintain plan for " + kbProtoUnitGetName(siegePUID1) + " to maintain " + maintainSiege1Amount + ".");
      }
      for (int j = 0; j < numMilitaryBuildings; j++)
      {
         buildingPUID = gMilitaryBuildings[j];
         if (kbProtoUnitCanTrain(buildingPUID, siegePUID1) == true)
         {
            gArmyUnitBuildings[gMaintainPlanSiegeStartIndex] = buildingPUID;
            break;
         }
      }

      planID = gArmyUnitMaintainPlans[gMaintainPlanSiegeStartIndex + 1];
      // It could be that this plan is already perfectly set up, then don't do anything.
      if (aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0) == maintainSiege2Amount)
      {
         debugMilitaryTraining("Maintain plan for " + maintainSiege2Amount + " " + kbProtoUnitGetName(siegePUID2) +
            " doesn't require any changes.");
      }
      else
      {
         aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, maintainSiege2Amount);
         aiPlanSetName(planID, planID + ": Siege maintain: " + maintainSiege2Amount + " " + kbProtoUnitGetName(siegePUID2));
         debugMilitaryTraining("Adjusting maintain plan for " + kbProtoUnitGetName(siegePUID2) + " to maintain " + maintainSiege2Amount + ".");
      }
      for (int j = 0; j < numMilitaryBuildings; j++)
      {
         buildingPUID = gMilitaryBuildings[j];
         if (kbProtoUnitCanTrain(buildingPUID, siegePUID2) == true)
         {
            gArmyUnitBuildings[gMaintainPlanSiegeStartIndex + 1] = buildingPUID;
            break;
         }
      }

      totalAvailablePop -= maintainSiege1Amount * siege1PopCost;
      totalAvailablePop -= maintainSiege2Amount * siege2PopCost;
   }
}

//==============================================================================
// setupArcherUnitPicker
//==============================================================================
void setupArcherUnitPicker(int upID = -1)
{
   kbUnitPickResetAll(upID);
   kbUnitPickSetMinimumCounterModePop(upID, 15);
   int targetPlayer = aiGetMostHatedPlayerID();
   kbUnitPickSetEnemyPlayerID(upID, targetPlayer);

   // We want to analyze all our Human Soldiers.
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractArcher, 0.5);

   // v1.9: counter preference - na zaklade slozeni utocici nepritelske armady
   if (gAdaptEnemyAttackMeleeRatio > 0.55)
   {
      // Nepritel posila hodne melee -> zvys preference lucisniku (luci counteri melee)
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractArcher, 0.75);
      debugMilitaryTraining("Counter: enemy melee heavy, boosting archer preference.");
   }
   else if (gAdaptEnemyAttackRangedRatio > 0.40)
   {
      // Nepritel posila hodne lucisniku -> sniz preference lucisniku (melee counteri luci)
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractArcher, 0.30);
      debugMilitaryTraining("Counter: enemy archer heavy, reducing archer preference.");
   }

   kbUnitPickSetPreferenceFactor(upID, cUnitTypeHero, 0.0);

   // Arcus are just much stronger than Turma/Cheiro normally. Give them an artificial boost.
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeArcus, 0.7);

   // Combat efficiency is twice as important as our preferences.
   kbUnitPickSetPreferenceWeight(upID, 1.0);
   kbUnitPickSetCombatEfficiencyWeight(upID, 2.0);

   // Default to scanning for enemy land military.
   kbUnitPickSetAttackUnitType(upID, cUnitTypeLogicalTypeLandMilitary);

   // Our Human Soldiers should be able to move over land.
   kbUnitPickSetMovementType(upID, cPassabilityLand);

   // Set the default target types and weights, for use until we've seen enough actual units.
   if (targetPlayer != -1)
   {
      int culture = kbPlayerGetCulture(targetPlayer);
      switch (culture)
      {
         case cCultureGreek:
         {
            kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeVillagerGreek, 1.0);
            break;
         }
         // BUG FIX v1.9: vsechny 4 case byly cCultureGreek (jen prvni se kdy spustil)
         case cCultureEgyptian:
         {
            kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeVillagerEgyptian, 1.0);
            break;
         }
         case cCultureNorse:
         {
            kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeVillagerNorse, 1.0);
            break;
         }
         case cCultureAtlantean:
         {
            kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeVillagerAtlantean, 1.0);
            break;
         }
      }
   }
}

//==============================================================================
// humanArcherMilitaryTraining
//==============================================================================
void humanArcherMilitaryTraining(ref int totalAvailablePop, int originalTotalMilitaryPop = -1)
{
   static int archerUnitPicker = -1;
   if (kbUnitPickGetIsIDValid(archerUnitPicker) == false)
   {
      archerUnitPicker = kbUnitPickCreate("Human archer military units");
   }
   // Update preferences in case something changed inbetween.
   setupArcherUnitPicker(archerUnitPicker);
   kbUnitPickRun(archerUnitPicker);

   int totalArcherPop = totalAvailablePop * gHumanArmyArcherPercentage;
   debugMilitaryTraining("Available archer pop is: " + totalArcherPop + ".");

   // Reset the building(s) we want to use for archers.
   for (int i = 0; i < gNumHumanArcherUnitTypes; i++)
   {
      gArmyUnitBuildings[gMaintainPlanHumanArcherStartIndex + i] = -1;
   }
   
   float totalFactor = 0.0;
   int puid = -1;
   int buildingPUID = -1;
   int trainBuildingPUID = -1;
   int numberToMaintain = 0;
   int popCount = 0;
   int existingPlanID = -1;
   int planID = -1;
   int[] temp = new int(gNumHumanArcherUnitTypes, -1);
   int[] unitPickResults = kbUnitPickGetResults(archerUnitPicker);
   float[] unitPickResultFactors = kbUnitPickGetResultFactors(archerUnitPicker);
   int numUnitPickerResults = unitPickResults.size();
   if (numUnitPickerResults <= 0)
   {
      aiEchoWarning("Human archer unit picker was unable to get any valid results!!!");
      return;
   }

   // Guard against wanting to train Chariot Archers when we have no Migdol Stronghold.
   if (cMyCulture == cCultureEgyptian && kbPlayerGetAge(cMyID) >= cAge3 && kbUnitCount(cUnitTypeMigdolStronghold, cMyID, cUnitStateAlive) <= 0)
   {
      for (int i = 0; i < numUnitPickerResults; i++)
      {
         if (unitPickResults[i] == cUnitTypeChariotArcher)
         {
            debugMilitaryTraining("We are Egyptians and don't have a Migdol Stronghold, removing Chariot Archers from the uP.");
            unitPickResults.removeIndex(i);
            unitPickResultFactors.removeIndex(i);
            numUnitPickerResults--;
            break;
         }
      }
   }

   debugMilitaryTraining("Unit picker results:");
   for (int i = 0; i < numUnitPickerResults; i++)
   {
      debugMilitaryTraining("   # " + i + " = " + kbProtoUnitGetName(unitPickResults[i]) + ", factor = " + unitPickResultFactors[i] + ".");
   }

   if (kbUnitPickGetCounterMode(archerUnitPicker) == true)
   {
      if (unitPickResultFactors[0] < 1.2)
      {
         debugMilitaryTraining("Our most wanted archer has too low of a result factor, not training any archers now.");
         for (int i = 0; i < gNumHumanArcherUnitTypes; i++)
         {
            if (aiPlanGetIsIDValid(gArmyUnitMaintainPlans[i]) == true)
            {
               aiPlanDestroy(gArmyUnitMaintainPlans[i]);
            }
            gArmyUnitMaintainPlans[i] = -1;
            gArmyUnitBuildings[i] = -1;
         }
         return;
      }
   }

   // If we can maintain more archers than our unit picker returned it can be that we've just removed a unit from the unitPicker.
   // Make sure we also update the gArmyUnitBuildings array accordingly.
   if (gNumHumanArcherUnitTypes > numUnitPickerResults)
   {
      for (int i = numUnitPickerResults; i < gNumHumanArcherUnitTypes; i++)
      {
         gArmyUnitBuildings[i] = -1;
      }
   }

   // We loop through all the units our human archer unit picker returned.
   // We see if we already have a maintain plan for said unit and save that information.
   for (int i = 0; i < min(gNumHumanArcherUnitTypes, numUnitPickerResults); i++)
   {
      totalFactor += unitPickResultFactors[i];
      puid = unitPickResults[i];
      if (kbProtoUnitGetIsValidID(puid) == false)
      {
         aiEchoWarning("Our human archer unit picker returned an invalid puid.");
         continue;
      }
      existingPlanID = -1;
      for (int j = 0; j < gNumHumanArcherUnitTypes; j++)
      {
         existingPlanID = gArmyUnitMaintainPlans[j];
         // If we already have a plan for this unit, re-use it.
         if (aiPlanGetIsIDValid(existingPlanID) == true && puid == aiPlanGetVariableInt(existingPlanID, cTrainPlanUnitType, 0))
         {
            temp[j] = existingPlanID;
            break;
         }
      }
   }

   // We destroy any maintain plans that are no longer needed because our unit picker preference has changed.
   for (int i = 0; i < gNumHumanArcherUnitTypes; i++)
   {
      // If temp[i] == -1 it means that we looped through our unit picker results and the plan at that index was training
      // a unit that we no longer want to train, thus we should destroy the plan.
      existingPlanID = gArmyUnitMaintainPlans[i];
      if (temp[i] == -1 && aiPlanGetIsIDValid(existingPlanID) == true)
      {
         debugMilitaryTraining("Destroying plan " + aiPlanGetName(existingPlanID) + ", because we no longer want that unit.");
         aiPlanDestroy(existingPlanID);
      }
   }

   debugMilitaryTraining("Total factor: " + totalFactor);
   for (int i = 0; i < min(gNumHumanArcherUnitTypes, numUnitPickerResults); i++)
   {
      puid = unitPickResults[i];
      if (kbProtoUnitGetIsValidID(puid) == false)
      {
         continue; // We already error'd above for this.
      }
      trainBuildingPUID = -1;
      numberToMaintain = 0;

      // If we still have a maintain plan for this puid, re-use it.
      for (int j = 0; j < temp.size(); j++)
      {
         planID = temp[j];
         if (aiPlanGetIsIDValid(planID) == true && puid == aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0))
         {
            break;
         }
         planID = -1;
      }

      popCount = kbPlayerGetProtoStatInt(cMyID, puid, cProtoStatPopCost);
      if (popCount > 0)
      {
         // Round up, never get into a situation where we don't train enough.
         numberToMaintain = ceil((unitPickResultFactors[i] / totalFactor) * totalArcherPop / popCount);
         debugMilitaryTraining("Unit: " + kbProtoUnitGetName(puid) + ", number to maintain: " + numberToMaintain + ".");
         debugMilitaryTraining("Factor: " + unitPickResultFactors[i] + ", popCount: " + popCount + ".");
      }
      else
      {
         numberToMaintain = ceil((unitPickResultFactors[i] / totalFactor) * totalArcherPop /
            (kbProtoUnitCostPerResource(puid, cResourceFood) + kbProtoUnitCostPerResource(puid, cResourceWood) +
             kbProtoUnitCostPerResource(puid, cResourceGold)));
         debugMilitaryTraining("Unit: " + kbProtoUnitGetName(puid) + ", number to maintain: " + numberToMaintain + ".");
      }
      
      if (planID < 0)
      {
         planID = aiPlanCreate("Land military archer maintain: " + numberToMaintain + " " + kbProtoUnitGetName(puid), cPlanTrain,
            -1, gMilitaryTrainingCategoryID);
         aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, puid);
         aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);
         debugMilitaryTraining("Creating maintain plan for " + kbProtoUnitGetName(puid) + ".");
      }
      else
      {
         // It could be that this plan is already perfectly set up, then don't do anything.
         if (aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0) == numberToMaintain)
         {
            debugMilitaryTraining("Existing maintain plan for " + kbProtoUnitGetName(puid) + " doesn't require changes.");
         }
         else
         {
            aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);
            aiPlanSetName(planID, planID + ": Land military archer maintain: " + numberToMaintain + " " + kbProtoUnitGetName(puid));
            debugMilitaryTraining("Adjusting existing maintain plan for " + kbProtoUnitGetName(puid) + ".");
         }
      }
      
      // Finally update our real array.
      gArmyUnitMaintainPlans[i] = planID;

      int numMilitaryBuildings = gMilitaryBuildings.size();
      for (int j = 0; j < numMilitaryBuildings; j++)
      {
         buildingPUID = gMilitaryBuildings[j];
         if (kbProtoUnitCanTrain(buildingPUID, puid) == true)
         {
            trainBuildingPUID = buildingPUID;
            break;
         }
      }

      gArmyUnitBuildings[i] = trainBuildingPUID;

      totalAvailablePop -= numberToMaintain * popCount;
   }
}

//==============================================================================
// setupHumanUnitPicker
//==============================================================================
void setupHumanUnitPicker(int upID = -1)
{
   kbUnitPickResetAll(upID);
   kbUnitPickSetMinimumCounterModePop(upID, 15);
   int targetPlayer = aiGetMostHatedPlayerID();
   kbUnitPickSetEnemyPlayerID(upID, targetPlayer);

   // We want to analyze all our Human Soldiers.
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeHumanSoldier, 0.5);

   // v1.9: counter preference - na zaklade slozeni utocici nepritelske armady
   if (gAdaptEnemyAttackRangedRatio > 0.40)
   {
      // Nepritel posila hodne lucisniku -> zvys preference melee (melee counteri luci)
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeHumanSoldier, 0.75);
      debugMilitaryTraining("Counter: enemy archer heavy, boosting melee preference.");
   }
   else if (gAdaptEnemyAttackMeleeRatio > 0.55)
   {
      // Nepritel posila hodne melee -> sniz melee, luci budou efektivnejsi
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeHumanSoldier, 0.30);
      debugMilitaryTraining("Counter: enemy melee heavy, reducing melee preference.");
   }

   // War Elephants are always considered to be very strong by the AI, but don't keep training them too often since they're so expensive.
   if (xsRandInt(0, 2) <= 1)
   {
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeWarElephant, 0.1);
   }

   // We can build Huskarls earlier when we're Ullr, but if we lost the Asgardian Hill Fort we can't train them anymore in Classical.
   if (cMyCiv == cCivFreyr && kbPlayerGetAge(cMyID) == cAge2 && kbTechGetStatus(cTechClassicalAgeUllr) == cTechStatusActive &&
       getUnit(cUnitTypeAsgardianHillFort) == -1)
   {
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeHuskarl, 0.0);
   }

   // We want to exclude these Human Soldiers.
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractArcher, 0.0);
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeMercenary, 0.0);
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeMercenaryCavalry, 0.0);
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeDestroyer, 0.0);
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeOracle, 0.0);

   // Combat efficiency is twice as important as our preferences.
   kbUnitPickSetPreferenceWeight(upID, 1.0);
   kbUnitPickSetCombatEfficiencyWeight(upID, 2.0);

   // Default to scanning for enemy land military.
   kbUnitPickSetAttackUnitType(upID, cUnitTypeLogicalTypeLandMilitary);

   // Our Human Soldiers should be able to move over land.
   kbUnitPickSetMovementType(upID, cPassabilityLand);

   // Set the default target types and weights, for use until we've seen enough actual units.
   if (targetPlayer != -1)
   {
      int culture = kbPlayerGetCulture(targetPlayer);
      // BUG FIX v1.9: vsechny 4 case byly cCultureGreek (jen prvni se kdy spustil)
      switch (culture)
      {
         case cCultureGreek:
         {
            kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeVillagerGreek, 1.0);
            break;
         }
         case cCultureEgyptian:
         {
            kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeVillagerEgyptian, 1.0);
            break;
         }
         case cCultureNorse:
         {
            kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeVillagerNorse, 1.0);
            break;
         }
         case cCultureAtlantean:
         {
            kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeVillagerAtlantean, 1.0);
            break;
         }
      }
   }
}

//==============================================================================
// humanMilitaryTraining
//==============================================================================
void humanMilitaryTraining(ref int totalAvailablePop, int originalTotalMilitaryPop = -1)
{
   static int humanUnitPicker = -1;
   if (kbUnitPickGetIsIDValid(humanUnitPicker) == false)
   {
      humanUnitPicker = kbUnitPickCreate("Human military units");
   }
   
   debugMilitaryTraining("We have : " + totalAvailablePop + " pop left to fill with melee human soldiers.");

   // Update preferences in case something changed inbetween.
   setupHumanUnitPicker(humanUnitPicker);
   kbUnitPickRun(humanUnitPicker);

   float totalFactor = 0.0;
   int puid = -1;
   int buildingPUID = -1;
   int trainBuildingPUID = -1;
   int numberToMaintain = 0;
   int popCount = 0;
   int existingPlanID = -1;
   int planID = -1;
   int numFortresses = kbUnitCount(gFortressUnit, cMyID, cUnitStateAlive);
   int[] temp = new int(gNumHumanMeleeUnitTypes, -1);
   int[] unitPickResults = kbUnitPickGetResults(humanUnitPicker);
   float[] unitPickResultFactors = kbUnitPickGetResultFactors(humanUnitPicker);
   int numUnitPickerResults = unitPickResults.size();
   if (numUnitPickerResults <= 0)
   {
      aiEchoWarning("Human unit picker was unable to get any valid results!!!");
      return;
   }

   debugMilitaryTraining("Unit picker results:");
   for (int i = 0; i < numUnitPickerResults; i++)
   {
      debugMilitaryTraining("   # " + i + " = " + kbProtoUnitGetName(unitPickResults[i]) + ", factor = " + unitPickResultFactors[i] + ".");
   }

   // We have a unique case where Fortress buildings are quite expensive but also have the best units.
   // So upon aging up to Heroic it's very possible that we suddenly want to train those units but have 0 Fortresses, especially Eggy.
   // We need to guard against this by checking if we have Fortresses, and if not remove the index.
   bool removedMigdolUnits = false;
   if (numUnitPickerResults > 3)
   {
      for (int i = 0; i < numUnitPickerResults && numUnitPickerResults >= 3 && i < 3; i++)
      {
         puid = unitPickResults[i];
         int[] trainers = kbProtoUnitGetTrainers(puid);
         if (trainers.size() == 1 && trainers[0] == gFortressUnit && numFortresses == 0)
         {
            debugMilitaryTraining("Skipping the training of " + kbProtoUnitGetName(puid) + ", because it can only be trained in " +
               "a " + kbProtoUnitGetName(gFortressUnit) + " and we have none of those now.");
            unitPickResults.removeIndex(i);
            unitPickResultFactors.removeIndex(i);
            numUnitPickerResults--;
            i--;
            removedMigdolUnits = true;
         }
      }
   }

   // We have a potential problem with Egyptians. Since the Migdol units are so strong the unit picker may select all of them.
   // We will often not have enough Migdols to support such a big need and it would be better if we utilised our Barracks as well.
   // We need 1 Migdol for 2 unit types and 2 Migdols if we want to train all 3.
   if (cMyCulture == cCultureEgyptian && numFortresses == 1 && removedMigdolUnits == false && numUnitPickerResults > 3)
   {
      bool trainingChariotArchers = false;
      for (int i = 0; i < gNumHumanArcherUnitTypes; i++)
      {
         planID = gArmyUnitMaintainPlans[i];
         if (aiPlanGetIsIDValid(planID) == true && aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0) == cUnitTypeChariotArcher)
         {
            debugMilitaryTraining("Found that we are also planning to train Chariot Archers.");
            trainingChariotArchers = true;
            break;
         }
      }

      // If we're not training a Chariot Archer it means we can quit.
      // Becaus we already know we have 1 Migdol and can now only potentially train Camel Riders + War Elephants == 2 unit types.
      if (trainingChariotArchers == true)
      {
         int numMigdolUnitsFound = 0;
         for (int i = 0; i < 3; i++)
         {
            puid = unitPickResults[i];
            if (puid == cUnitTypeCamelRider || puid == cUnitTypeWarElephant)
            {
               numMigdolUnitsFound++;
            }
         }

         // If we found both a Camel Rider and a War Elephant it means we're wanting to train all Migdol units but have just 2 Migdol.
         if (numMigdolUnitsFound == 2)
         {
            debugMilitaryTraining("We're also planning for both other Migdol Stronghold units.");
            for (int i = 2; i >= 0; i--)
            {
               puid = unitPickResults[i];
               if (puid == cUnitTypeCamelRider || puid == cUnitTypeWarElephant)
               {
                  debugMilitaryTraining("Deleting unit pick results index " + i + " because we have too few Migdols.");
                  unitPickResults.removeIndex(i);
                  unitPickResultFactors.removeIndex(i);
                  numUnitPickerResults--;
                  break;
               }
            }
         }
      }
   }

   // We loop through all the units our human unit picker returned.
   // We see if we already have a maintain plan for said unit and save that information.
   for (int i = 0; i < min(gNumHumanMeleeUnitTypes, numUnitPickerResults); i++)
   {
      totalFactor += unitPickResultFactors[i];
      puid = unitPickResults[i];
      if (kbProtoUnitGetIsValidID(puid) == false)
      {
         aiEchoWarning("Our human unit picker returned an invalid puid.");
         continue;
      }
      existingPlanID = -1;
      for (int j = gMaintainPlanHumanMeleeStartIndex; j < gMaintainPlanHumanMeleeStartIndex + gNumHumanMeleeUnitTypes; j++)
      {
         existingPlanID = gArmyUnitMaintainPlans[j];
         // If we already have a plan for this unit, re-use it.
         if (aiPlanGetIsIDValid(existingPlanID) == true && puid == aiPlanGetVariableInt(existingPlanID, cTrainPlanUnitType, 0))
         {
            // Offset j for the temp array, since that array's index starts at 0.
            temp[j - gNumHumanArcherUnitTypes] = existingPlanID;
            break;
         }
      }
   }

   // We destroy any maintain plans that are no longer needed because our unit picker preference has changed.
   for (int i = gMaintainPlanHumanMeleeStartIndex; i < gMaintainPlanHumanMeleeStartIndex + gNumHumanMeleeUnitTypes; i++)
   {
      // If temp[i] == -1 it means that we looped through our unit picker results and the plan at that index was training
      // a unit that we no longer want to train, thus we should destroy the plan.
      existingPlanID = gArmyUnitMaintainPlans[i];
      // Offset i for the temp array, since that array's index starts at 0.
      if (temp[i - gNumHumanArcherUnitTypes] == -1 && aiPlanGetIsIDValid(existingPlanID) == true)
      {
         debugMilitaryTraining("Destroying plan " + aiPlanGetName(existingPlanID) + ", because we no longer want that unit.");
         aiPlanDestroy(existingPlanID);
      }
   }

   debugMilitaryTraining("Total factor: " + totalFactor);
   for (int i = 0; i < min(gNumHumanMeleeUnitTypes, numUnitPickerResults); i++)
   {
      puid = unitPickResults[i];
      if (kbProtoUnitGetIsValidID(puid) == false)
      {
         continue; // We already error'd above for this.
      }
      trainBuildingPUID = -1;
      numberToMaintain = 0;

      // If we still have a maintain plan for this puid, re-use it.
      for (int j = 0; j < temp.size(); j++)
      {
         planID = temp[j];
         if (aiPlanGetIsIDValid(planID) == true && puid == aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0))
         {
            break;
         }
         planID = -1;
      }

      popCount = kbPlayerGetProtoStatInt(cMyID, puid, cProtoStatPopCost);
      if (popCount > 0)
      {
         // Round up, never get into a situation where we don't train enough.
         numberToMaintain = ceil((unitPickResultFactors[i] / totalFactor) * totalAvailablePop / popCount);
         debugMilitaryTraining("Unit: " + kbProtoUnitGetName(puid) + ", number to maintain: " + numberToMaintain + ".");
         debugMilitaryTraining("Factor: " + unitPickResultFactors[i] + ", popCount: " + popCount + ".");
      }
      else
      {
         numberToMaintain = ceil((unitPickResultFactors[i] / totalFactor) * totalAvailablePop /
            (kbProtoUnitCostPerResource(puid, cResourceFood) + kbProtoUnitCostPerResource(puid, cResourceWood) +
             kbProtoUnitCostPerResource(puid, cResourceGold)));
         debugMilitaryTraining("Unit: " + kbProtoUnitGetName(puid) + ", number to maintain: " + numberToMaintain + ".");
      }

      if (planID < 0)
      {
         planID = aiPlanCreate("Land military maintain: " + numberToMaintain + " " + kbProtoUnitGetName(puid), cPlanTrain,-1
            -1, gMilitaryTrainingCategoryID);
         aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, puid);
         aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);
         debugMilitaryTraining("Creating maintain plan for " + kbProtoUnitGetName(puid) + ".");
      }
      else
      {
         // It could be that this plan is already perfectly set up, then don't do anything.
         if (aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0) == numberToMaintain)
         {
            debugMilitaryTraining("Existing maintain plan for " + kbProtoUnitGetName(puid) + " doesn't require changes.");
         }
         else
         {
            aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);
            aiPlanSetName(planID, planID + ": Land military maintain: " + numberToMaintain + " " + kbProtoUnitGetName(puid));
            debugMilitaryTraining("Adjusting existing maintain plan for " + kbProtoUnitGetName(puid) + ".");
         }
      }
      
      // Finally update our real array.
      gArmyUnitMaintainPlans[gMaintainPlanHumanMeleeStartIndex + i] = planID;

      int numMilitaryBuildings = gMilitaryBuildings.size();
      for (int j = 0; j < numMilitaryBuildings; j++)
      {
         buildingPUID = gMilitaryBuildings[j];
         if (kbProtoUnitCanTrain(buildingPUID, puid) == true)
         {
            trainBuildingPUID = buildingPUID;
            break;
         }
      }

      gArmyUnitBuildings[gMaintainPlanHumanMeleeStartIndex + i] = trainBuildingPUID;
   }
}

//==============================================================================
// dryadTraining
//==============================================================================
void dryadTraining(int originalTotalMilitaryPop = -1)
{
   int hesperidesTreeID = getUnit(cUnitTypeHesperidesTree);
   if (kbUnitGetIsIDValid(hesperidesTreeID) == false)
   {
      debugMilitaryTraining("We have no Hesperides Tree in our possession, can't train Dryads.");
      return;
   }
   int currentDryadCount = kbUnitCount(cUnitTypeDryad, cMyID, cUnitStateAlive);
   int[] planIDs = aiPlanGetIDsByTypeAndVariableIntValue(cPlanTrain, cTrainPlanUnitType, cUnitTypeDryad);
   for (int j = 0; j < planIDs.size(); j++)
   {
      currentDryadCount += aiPlanGetVariableInt(planIDs[j], cTrainPlanNumberToTrain, 0) -
                           aiPlanGetVariableInt(planIDs[j], cTrainPlanNumberTrained, 0);
   }
   debugMilitaryTraining("dryadTraining - currentDryadCount: " + currentDryadCount);

   int wantedDryadCount = originalTotalMilitaryPop / 10;
   if (cDifficultyCurrent <= cDifficultyModerate && wantedDryadCount > 1)
   {
      wantedDryadCount = 1;
   }
   debugMilitaryTraining("dryadTraining - wantedDryadCount: " + wantedDryadCount);
   int dryadCountToTrain = max(0, wantedDryadCount - currentDryadCount);
   int buildLimit = kbPlayerGetProtoStatInt(cMyID, cUnitTypeDryad, cProtoStatBuildLimit);
   if (currentDryadCount + dryadCountToTrain > buildLimit)
   {
      dryadCountToTrain = buildLimit - currentDryadCount;
      debugMilitaryTraining("dryadTraining - needing to clamp dryadCountToTrain because of BL to: " + dryadCountToTrain + ".");
   }
   if (dryadCountToTrain <= 0)
   {
      debugMilitaryTraining("dryadTraining - dryadCountToTrain: " + dryadCountToTrain + ", do nothing.");
   }
   else
   {
      // We must set the buildingPUID because the Hesperides Tree can't be found by the automatic train plan systems.
      createSimpleTrainPlan(cUnitTypeDryad, dryadCountToTrain, -1, 50, -1, cUnitTypeHesperidesTree);
   }
}

//==============================================================================
/* militaryManager
   Manages how much military population should be trained.
   And then makes sure that actually gets trained.
*/
//==============================================================================
rule militaryManager
inactive
group defaultClassicalRules
minInterval 30
{
   if (checkStrategyFlag(cStrategyFlagAutoTrainMilitaryUnits) == false)
   {
      // Destroy all plans...
      // TODO extend for all train plans potentially.
      for (int i = 0; i < gNumTotalArmyUnitTypes; i++)
      {
         int planID = gArmyUnitMaintainPlans[i];
         if (aiPlanGetIsIDValid(planID) == true)
         {
            aiPlanDestroy(planID);
            gArmyUnitMaintainPlans[i] = -1;
         }
         gArmyUnitBuildings[i] = -1;
      }
      return;
   }

   debugMilitaryTraining("--- Running Rule militaryManager. ---");

   debugMilitaryTraining("Current maintain plans:");
   for (int i = 0; i < gNumTotalArmyUnitTypes; i++)
   {
      int planID = gArmyUnitMaintainPlans[i];
      if (aiPlanGetIsIDValid(planID) == true)
      {
         debugMilitaryTraining("" + aiPlanGetName(planID));
      }
      else
      {
         debugMilitaryTraining("Currently Invalid plan.");
      }
   }

   if (gOverrideMaxMilitaryPop >= cUnlimitedMilitaryPop)
   {
      debugMilitaryTraining("Override - Setting our military pop to: " + gOverrideMaxMilitaryPop + ", -1 means unlimited.");
      aiSetMilitaryPop(gOverrideMaxMilitaryPop);
   }
   else
   {
      // Updating of military pop to have realistic maintain numbers.
      bool unlockMilitaryPop = false;
      int militaryPop = 0;
      int currentEconomicPop = aiGetCurrentEconomyPop() + aiGetCurrentNavalEconomyPop();
      // Put a minimum of 5 on this so that Norse AI who have no eco left can still train a builder.
      militaryPop = max(5, currentEconomicPop * gMilitaryToEcoRatio);
      // If we're >= Titan and Mythic and have > 90% of our wanted economic pop we unlock our military pop.
      if (cDifficultyCurrent >= cDifficultyTitan && kbPlayerGetAge(cMyID) >= cAge4 && currentEconomicPop > (aiGetEconomyPop() * 0.9))
      {
         unlockMilitaryPop = true;
         debugMilitaryTraining("Unlocking military population because we're >= Mythic and nearly have all our wanted economic pop.");
      }
      if (haveExcessResourceAmount(1000, cAllResources) == true)
      {
         unlockMilitaryPop = true;
         debugMilitaryTraining("Unlocking military population because we have 1000 excess in all resources (excluding favor).");
      }
      if (unlockMilitaryPop == true)
      {
         militaryPop = kbPlayerGetPopCap(cMyID) - currentEconomicPop;
         militaryPop = max(0, militaryPop); // This is needed because we could lose a lot of Houses and hit this.
         if (cDifficultyCurrent <= cDifficultyHard)
         {
            debugMilitaryTraining("Seeing if we need to take gMaxMilitaryPop (" + gMaxMilitaryPop + 
               ") into account because we're on a lower difficulty.");
            militaryPop = min(gMaxMilitaryPop, militaryPop); // Cap this appropriately again.
         }
      }
      aiSetMilitaryPop(militaryPop);
      debugMilitaryTraining("Setting our military pop to: " + militaryPop + ".");
   }

   int originalTotalMilitaryPop = aiGetMilitaryPop();
   if (originalTotalMilitaryPop == 0)
   {
      debugMilitaryTraining("We are allowed 0 max military pop, can't train anything now.");
      return;
   }
   int currentMilitaryPop = aiGetCurrentMilitaryPop();
   if (originalTotalMilitaryPop < currentMilitaryPop)
   {
      debugMilitaryTraining("We are allowed " + originalTotalMilitaryPop + " max military pop but already have " + currentMilitaryPop +
         " military pop, not training any more now.");
      return;
   }
   int remainingMilitaryPop = originalTotalMilitaryPop;
   debugMilitaryTraining("*** remainingMilitaryPop before any training: " + remainingMilitaryPop + ". ***");

   heroMilitaryTraining(remainingMilitaryPop, originalTotalMilitaryPop);
   debugMilitaryTraining("*** remainingMilitaryPop after hero training: " + remainingMilitaryPop + ". ***");

   mythMilitaryTraining(remainingMilitaryPop, originalTotalMilitaryPop);
   debugMilitaryTraining("*** remainingMilitaryPop after myth training: " + remainingMilitaryPop + ". ***");

   siegeMilitaryTraining(remainingMilitaryPop, originalTotalMilitaryPop);
   debugMilitaryTraining("*** remainingMilitaryPop after siege training: " + remainingMilitaryPop + ". ***");

   humanArcherMilitaryTraining(remainingMilitaryPop, originalTotalMilitaryPop);
   debugMilitaryTraining("*** remainingMilitaryPop after human archer training: " + remainingMilitaryPop + ". ***");

   humanMilitaryTraining(remainingMilitaryPop, originalTotalMilitaryPop);

   dryadTraining(originalTotalMilitaryPop);
}