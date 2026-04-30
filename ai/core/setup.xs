//==============================================================================
/* setup.xs

   This file contains all functions and rules for initialization.

*/

//==============================================================================
/* initCivUnitTypes
   Initialize all global civilisation specific unit types.
*/
//==============================================================================
void initCivUnitTypes()
{
   debugSetup("***Initializing civilisation specific unit types***");

   // Shared.
   gMarketUnit = cUnitTypeMarket;
   gFarmUnit = kbSharedFunctionUnitGetByIndex(cSharedUnitFunctionFarm, 0);

   gArmoryUnit = cUnitTypeArmory;
   if (cMyCiv == cCivThor)
   {
      gArmoryUnit = cUnitTypeDwarvenArmory;
   }

   switch (cMyCulture)
   {
      case cCultureGreek:
      {
         gEconUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionGatherer, 0);
         gFishingUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionFisher, 0);
         gHouseUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionHouse, 0);
         gFortressUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionFortress, 0);
         gCaravanUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionTrader, 0);
         gArcherShip = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionArcherShip, 0);
         gCloseCombatShip = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionCloseCombatShip, 0);
         gSiegeShip = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionSiegeShip, 0);
         break;
      }
      case cCultureEgyptian:
      {
         gEconUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionGatherer, 0);
         gFishingUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionFisher, 0);
         gHouseUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionHouse, 0);
         gFortressUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionFortress, 0);
         gCaravanUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionTrader, 0);
         gArcherShip = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionArcherShip, 0);
         gCloseCombatShip = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionCloseCombatShip, 0);
         gSiegeShip = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionSiegeShip, 0);
         break;
      }
      case cCultureNorse:
      {
         gEconUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionGatherer, 0);
         gFishingUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionFisher, 0);
         gHouseUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionHouse, 0);
         gFortressUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionFortress, 0);
         gCaravanUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionTrader, 0);
         gArcherShip = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionArcherShip, 0);
         gCloseCombatShip = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionCloseCombatShip, 0);
         gSiegeShip = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionSiegeShip, 0);
         break;
      }
      case cCultureAtlantean:
      {
         gEconUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionGatherer, 0);
         gFishingUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionFisher, 0);
         gHouseUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionHouse, 0);
         gFortressUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionFortress, 0);
         gCaravanUnit = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionTrader, 0);
         gArcherShip = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionArcherShip, 0);
         gCloseCombatShip = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionCloseCombatShip, 0);
         gSiegeShip = kbFunctionUnitGetByIndex(cMyCiv, cUnitFunctionSiegeShip, 0);
         break;
      }
      default:
      {
         aiEchoWarning("Invalid culture detected in the AI!");
         break;
      }
   }
}
void initArrays()
{
   //==============================================================================
   // Economy.
   //==============================================================================
   gResourceNeeds = new float(4, 0.0);
   gAdjustBreakdownAttempts = new int(4, 1);
   gMarketBuySellPercentages = new float(4, 0.0);
   gRawResourcePercentages = new float(4, 0.0);

   //==============================================================================
   // Buildings.
   //==============================================================================
   gArmyUnitBuildings = new int(gNumTotalArmyUnitTypes, -1);

   switch (cMyCulture)
   {
      case cCultureGreek:
      {
         gMilitaryBuildings = new int(4, -1);
         gMilitaryBuildings[0] = cUnitTypeMilitaryAcademy;
         gMilitaryBuildings[1] = cUnitTypeStable;
         gMilitaryBuildings[2] = cUnitTypeArcheryRange;
         gMilitaryBuildings[3] = cUnitTypeFortress;
         break;
      }
      case cCultureEgyptian:
      {
         gMilitaryBuildings = new int(3, -1);
         gMilitaryBuildings[0] = cUnitTypeBarracks;
         gMilitaryBuildings[1] = cUnitTypeMigdolStronghold;
         gMilitaryBuildings[2] = cUnitTypeSiegeWorks;
         break;
      }
      case cCultureNorse:
      {
         gMilitaryBuildings = new int(3, -1);
         gMilitaryBuildings[0] = cUnitTypeLonghouse;
         gMilitaryBuildings[1] = cUnitTypeGreatHall;
         gMilitaryBuildings[2] = cUnitTypeHillFort;
         break;
      }
      case cCultureAtlantean:
      {
         gMilitaryBuildings = new int(3, -1);
         gMilitaryBuildings[0] = cUnitTypeMilitaryBarracks;
         gMilitaryBuildings[1] = cUnitTypeCounterBarracks;
         gMilitaryBuildings[2] = cUnitTypePalace;
         break;
      }
   }

   //==============================================================================
   // Military.
   //==============================================================================
   gDefendTCBases = new int(0, 0);
   gDefendPlans = new int(0, 0);

   gArrayEnemyPlayerIDs = new int(0, 0);
   // These indexes match to player IDs, so we need to include mother nature at index 0 that just isn't used.
   gStartingPosDistances = new float(cNumberPlayersPlusNature, 0.0);
   vector startLoc = kbPlayerGetStartingPosition(cMyID);
   for (int i = 1; i < cNumberPlayersPlusNature; i++)
   {
      if (i == cMyID)
      {
         continue;
      }
      gStartingPosDistances[i] = xsVectorLength(startLoc - kbPlayerGetStartingPosition(i));
   }

   gArmyUnitMaintainPlans = new int(gNumTotalArmyUnitTypes, -1);
   gNavalUnitMaintainPlans = new int(cNumWarships, -1);

   // We don't use index 0 since tracking Archaic makes no sense.
   // And we use indexes 1-3 to track Classical/Heroic/Mythic, we don't track Wonder.
   gAgeUpTimes = new int(cAge5, -1);
   gFastestAgeUpTimes  = new int(cAge5, -1);

   //==============================================================================
   // Misc.
   //==============================================================================
   gDegrees.add(cDegrees0);
   gDegrees.add(cDegrees45);
   gDegrees.add(cDegrees90);
   gDegrees.add(cDegrees135);
   gDegrees.add(cDegrees180);
   gDegrees.add(cDegrees225);
   gDegrees.add(cDegrees270);
   gDegrees.add(cDegrees315);
}

//==============================================================================
// initXSHandlers
//==============================================================================
void initXSHandlers()
{
   debugSetup("***Setting up XSHandlers***");
   aiSetHandler("selectDropsitePlacement", cXSResourceBuildPlanHandler);
   aiSetHandler("onAutoPlanCreate", cXSAutoCreatePlanHandler);
   aiSetHandler("godPowerGrantedHandler", cXSGodPowerGrantedHandler);
   aiSetHandler("ageUpEventHandler", cXSPlayerAgeHandler);
   aiSetHandler("godPowerCastedHandler", cXSGodPowerCastedHandler);
   aiSetHandler("kothChangedOwnerHandler", cXSKOTHStartHandler);
   aiSetHandler("relicGarrisonedHandler", cXSRelicGarrisonedHandler);
   aiSetHandler("relicPickedUpHandler", cXSRelicPickedUpHandler);
   aiSetHandler("resignHandler", cXSResignQuestionHandler);
}

//==============================================================================
// selectGreekBO
//==============================================================================
void selectGreekBO()
{
   if (cGameModeCurrent == cGameModeSupremacy)
   {
      switch (cMyCiv)
      {
         case cCivZeus:
         {
            gStartupBOArchaic = boGreekStandardArchaic;
            if (xsRandBool() == true)
            {
               gStartupBOClassical = boZeusAthenaClassical;
            }
            else
            {
               gStartupBOClassical = boZeusHermesClassical;
            }
            break;
         }
         case cCivHades:
         {
            gStartupBOArchaic = boGreekStandardArchaic;
            if (xsRandBool() == true)
            {
               gStartupBOClassical = boHadesAthenaClassical;
            }
            else
            {
               gStartupBOClassical = boGreekAresClassical;
            }
            break;
         }
         case cCivPoseidon:
         {
            gStartupBOArchaic = boGreekStandardArchaic;
            if (xsRandBool() == true)
            {
               gStartupBOClassical = boGreekAresClassical;
            }
            else
            {
               gStartupBOClassical = boPoseidonHermesClassical;
            }
            break;
         }
      }
   }
   else // Deathmatch.
   {
      gStartupBOArchaic = boGreekDeathMatch;
   }
}

//==============================================================================
// selectEgyptianBO
//==============================================================================
void selectEgyptianBO()
{
   if (cGameModeCurrent == cGameModeSupremacy)
   {
      switch (cMyCiv)
      {
         case cCivRa:
         {
            gStartupBOArchaic = boEgyptianStandardArchaic;
            if (xsRandBool() == true)
            {
               gStartupBOClassical = boEgyptianBastClassical;
            }
            else
            {
               gStartupBOClassical = boEgyptianPtahClassical;
            }
            break;
         }
         case cCivIsis:
         {
            gStartupBOArchaic = boEgyptianStandardArchaic;
            if (xsRandBool() == true)
            {
               gStartupBOClassical = boEgyptianBastClassical;
            }
            else
            {
               gStartupBOClassical = boEgyptianAnubisClassical;
            }
            break;
         }
         case cCivSet:
         {
            gStartupBOArchaic = boEgyptianStandardArchaic;
            if (xsRandBool() == true)
            {
               gStartupBOClassical = boEgyptianPtahClassical;
            }
            else
            {
               gStartupBOClassical = boEgyptianAnubisClassical;
            }
            break;
         }
      }
   }
   else // Deathmatch.
   {
      gStartupBOArchaic = boEgyptianDeathMatch;
   }
}

//==============================================================================
// selectNorseBO
//==============================================================================
void selectNorseBO()
{
   if (cGameModeCurrent == cGameModeSupremacy)
   {
      switch (cMyCiv)
      {
         case cCivThor:
         {
            gStartupBOArchaic = boNorseStandardArchaic;
            if (xsRandBool() == true)
            {
               gStartupBOClassical = boThorFreyaClassical;
            }
            else
            {
               gStartupBOClassical = boThorForsetiClassical;
            }
            break;
         }
         case cCivOdin:
         {
            gStartupBOArchaic = boNorseStandardArchaic;
            if (xsRandBool() == true)
            {
               gStartupBOClassical = boOdinFreyaClassical;
            }
            else
            {
               gStartupBOClassical = boOdinHeimdallClassical;
            }
            break;
         }
         case cCivLoki:
         {
            gStartupBOArchaic = boNorseStandardArchaic;
            if (xsRandBool() == true)
            {
               gStartupBOClassical = boLokiForsetiClassical;
            }
            else
            {
               gStartupBOClassical = boLokiHeimdallClassical;
            }
            break;
         }
         case cCivFreyr:
         {
            gStartupBOArchaic = boNorseStandardArchaic;
            if (xsRandBool() == true)
            {
               gStartupBOClassical = boFreyrFreyaClassical;
            }
            else
            {
               gStartupBOClassical = boFreyrUllrClassical;
            }
            break;
         }
      }
   }
   else // Deathmatch.
   {
      gStartupBOArchaic = boNorseDeathMatch;
   }
}

//==============================================================================
// selectAtlanteanBO
//==============================================================================
void selectAtlanteanBO()
{
   if (cGameModeCurrent == cGameModeSupremacy)
   {
      switch (cMyCiv)
      {
         case cCivKronos:
         {
            gStartupBOArchaic = boAtlanteanStandardArchaic;
            if (xsRandBool() == true)
            {
               gStartupBOClassical = boAtlanteanPrometheusClassical;
            }
            else
            {
               gStartupBOClassical = boAtlanteanLetoClassical;
            }
            break;
         }
         case cCivOranos:
         {
            gStartupBOArchaic = boAtlanteanStandardArchaic;
            if (xsRandBool() == true)
            {
               gStartupBOClassical = boAtlanteanPrometheusClassical;
            }
            else
            {
               gStartupBOClassical = boAtlanteanOceanusClassical;
            }
            break;
         }
         case cCivGaia:
         {
            if (xsRandBool() == true)
            {
               gStartupBOArchaic = boAtlanteanStandardArchaic;
               if (xsRandBool() == true)
               {
                  gStartupBOClassical = boAtlanteanLetoClassical;
               }
               else
               {
                  gStartupBOClassical = boAtlanteanOceanusClassical;
               }
            }
            else
            {
               gStartupBOArchaic = boAtlanteanGaiaEcoArchaic;
               if (xsRandBool() == true)
               {
                  gStartupBOClassical = boGaiaLetoClassical;
               }
               else
               {
                  gStartupBOClassical = boGaiaOceanusClassical;
               }
            }
            break;
         }
      }
   }
   else // Deathmatch.
   {
      gStartupBOArchaic = boAtlanteanDeathMatch;
   }
}

//==============================================================================
// selectBOAndStrat
// Select build order and strategy
//==============================================================================
void selectBOAndStrat()
{
   if (gOverrideStrategyUsed == true)
   {
      void() scenarioStrategySetup = gOverrideStrategy;
      scenarioStrategySetup();
      // Make sure we flag the BO as done so other systems can properly fetch that info too.
      boSystem.done = true;
      return;
   }

   int startingStrategy = cStrategyStartupBO;
   if (forceBOStrat == false)
   {
      if (kbPlayerGetAge(cMyID) != cAge1 ||
          cGameTypeCurrent != cGameTypeRandomMap ||
          cStartingResourcesCurrent != cStartingResourcesStandard ||
          cGameModeCurrent == cGameModeLightning)
      {
         startingStrategy = cStrategyArchaic;
      }
      if (gMapInfo.mIsNomadMap == true)
      {
         initNomadStrategy();
         gStrategyManager.addStrategy(gNomadStrategy);
         startingStrategy = cStrategyNomad;
      }
   }

   if (startingStrategy == cStrategyStartupBO)
   {
      if (cMyCulture == cCultureGreek)
      {
         selectGreekBO();
      }
      else if (cMyCulture == cCultureEgyptian)
      {
         selectEgyptianBO();
      }
      else if (cMyCulture == cCultureNorse)
      {
         selectNorseBO();
      }
      else if (cMyCulture == cCultureAtlantean)
      {
         selectAtlanteanBO();
      }
   }
   else
   {
      // Make sure we flag the BO as done so other systems can properly fetch that info too.
      boSystem.done = true;
   }
   
   gStrategyManager.mStartingStrategy = startingStrategy;
   addDefaultArchaicStrategies();
   addDefaultClassicalStrategies();
   addDefaultHeroicStrategies();
   addDefaultMythicStrategies();
   addDefaultWonderStrategies();
   addMigrateMainBaseStrategy();
   if (startingStrategy == cStrategyStartupBO)
   {
      gStrategyManager.addStrategy(gStartupBOStrategy);
   }
   gStrategyManager.addStrategy(gArchaicStrategy);
   switch (cPersonalityCurrent)
   {
      case cPersonalityStandard:
      {
         gStrategyManager.addStrategy(gClassicalStrategy);
         gStrategyManager.addStrategy(gHeroicStrategy);
         gStrategyManager.addStrategy(gMythicStrategy);
         break;
      }
      case cPersonalityAttacker:
      {
         gStrategyManager.addStrategy(gClassicalRusherStrategy);
         gStrategyManager.addStrategy(gHeroicStrategy);
         gStrategyManager.addStrategy(gMythicStrategy);
         break;
      }
      case cPersonalityDefender:
      {
         gStrategyManager.addStrategy(gClassicalTurtlerStrategy);
         gStrategyManager.addStrategy(gHeroicTurtlerStrategy);
         gStrategyManager.addStrategy(gMythicTurtlerStrategy);
         break;
      }                  
   }
   gStrategyManager.addStrategy(gWonderStrategy);
   gStrategyManager.addStrategy(gMigrateMainBase);
}

//==============================================================================
// fixupDefendPlanMGP
// We create the gPrimaryLandDefendPlan in init but our MGP isn't properly set up on frame 0.
// So to properly fix it up we reset the gather point here.
//==============================================================================
rule fixupDefendPlanMGP
inactive
minInterval 5
{
   if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == true)
   {
      int mainBaseID = kbBaseGetMainID(cMyID);
      if (mainBaseID != -1)
      {
         vector gatherPoint = kbBaseGetMilitaryGatherPoint(cMyID, mainBaseID);
         aiPlanSetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0, gatherPoint);
      }
   }
   xsDisableRule("fixupDefendPlanMGP");
}

//==============================================================================
// init
//==============================================================================
void init()
{
   debugSetup("***Running init()***");

   // IMPORTANT: we activate all our startup rules here:
   // 1. We know we will have a strategy right after enabling these rules, meaning that any strategy fetcher won't error.
   // 2. We activate it BEFORE the strategy system inits so that the init functions of the strategies can mess with disabling these rules.
   int currentAge = kbPlayerGetAge(cMyID);
   if (currentAge >= cAge1)
   {
      xsEnableRuleGroup("defaultArchaicRules");
   }
   if (currentAge >= cAge2)
   {
      gAgeUpTimes[cAge2] = 0;
      xsEnableRuleGroup("defaultClassicalRules");
   }
   if (currentAge >= cAge3)
   {
      gAgeUpTimes[cAge3] = 0;
      xsEnableRuleGroup("defaultHeroicRules");
   }
   if (currentAge >= cAge4)
   {
      gAgeUpTimes[cAge4] = 0;
      xsEnableRuleGroup("defaultMythicRules");
   }
   if (currentAge >= cAge5)
   {
      xsEnableRuleGroup("defaultWonderRules");
   }

   // Maybe this gets its own file later?
   if (cMyCulture == cCultureGreek)
   {
      xsEnableRule("kataskoposManager");
   }
   if (cMyCiv == cCivPoseidon)
   {
      xsEnableRule("hippocampusManager");
   }
   if (cMyCiv == cCivOdin)
   {
      xsEnableRule("ravenManager");
      xsRuleIgnoreIntervalOnce("ravenManager"); // Need to run fast for DM fast Temple.
   }
   
   gStrategyManager.init();
   selectBOAndStrat();
   gStrategyManager.start();

   // If our starting strategy allows defending / is a BO, create the first defend plan.
   if (checkStrategyFlag(cStrategyFlagCanDefend) == true || isBuildOrderDone() == false)
   {
      createPrimaryDefendPlan();
      xsEnableRule("fixupDefendPlanMGP");
   }

   postInit();
}

//==============================================================================
// prepareForInit
//==============================================================================
void prepareForInit()
{
   if (forceBOStrat == false && (cGameTypeCurrent == cGameTypeCampaign || cGameTypeCurrent == cGameTypeScenario))
   {
      xsEnableRule("waitForStartup");
   }
   else // Random Map game, instantly start everything.
   {
      init();
   }
}

//==============================================================================
/* waitForStartup
   During Campaigns and Scenarios we wait at least 1 second before we startup everything.
   In this time the "gStartInactive" can be set to true, meaning we
   are not allowed to start until this variable is set to false via another trigger.
*/
//==============================================================================
rule waitForStartup
inactive
minInterval 1
{
   if (gStartInactive == true)
   {
      return;
   }
   init();
   xsDisableRule("waitForStartup");
}