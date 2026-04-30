//==============================================================================
/* godpowers_egyptian.xs

   This file contains all logic for the Egyptian god powers.

*/
//==============================================================================

extern int gRainPlanID = -1;
extern int gProsperityPlanID = -1;
extern int gEclipsePlanID = -1;
extern int gShiftingSandsPlanID = -1;
extern int gShiftingSandsAttackPlanID = -1;
extern vector gShiftingSandsLocation = cInvalidVector;
extern int gPlagueOfSerpentsPlanID = -1;
extern int gLocustSwarmPlanID = -1;
extern int gAncestorsPlanID = -1;
extern int gAncestorsAttackPlanID = -1;
extern int gCitadelPlanID = -1;
extern int gSonOfOsirisPlanID = -1;
extern int gMeteorPlanID = -1;
extern int gTornadoPlanID = -1;

//==============================================================================
// setupEgyptianGodPowerPlan
//==============================================================================
void setupEgyptianGodPowerPlan(int planID = -1, int protoPowerID = -1)
{
   aiPlanSetVariableInt(planID, cPlanGodPower, 0, protoPowerID);

   switch (protoPowerID)
   {
      case cProtoPowerVision:
      {
         vector castLocation = cInvalidVector;
         if (cDifficultyCurrent >= cDifficultyHard)
         {
            castLocation = guessEnemyLocation(getRandomEnemyID()); // Call on an enemy.
         }
         else
         {
            // Center of the map with an offset so not all AI overlap each other.
            castLocation = kbGetMapCenter();
            vector offset = getRandom45DegreesOffset();
            castLocation += (offset * 40); // Magic number.
         }
         aiPlanSetVariableVector(planID, cGodPowerPlanTargetLocation, 0, castLocation);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationNoLOSCheck);
         break;
      }

      case cProtoPowerRain:
      {
         gRainPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelWorld);
         xsEnableRule("rainMonitor");
         break;
      }

      case cProtoPowerProsperity:
      {
         gProsperityPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelWorld);
         xsEnableRule("prosperityMonitor");
         break;
      }

      case cProtoPowerEclipse:
      {
         gEclipsePlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelWorld);
         xsEnableRule("eclipseMonitor");
         break;
      }

      case cProtoPowerShiftingSands:
      {
         gShiftingSandsPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationDual);
         xsEnableRule("shiftingSandsMonitor");
         break;
      }

      case cProtoPowerPlagueOfSerpents:
      {
         // Atm no support for casting it on water.

         // Defenders always cast in own base, normal personality 1/2 chance to do so too.
         if (cPersonalityCurrent == cPersonalityDefender ||
             (cPersonalityCurrent == cPersonalityStandard && xsRandBool() == true))
         {
            gPlagueOfSerpentsPlanID = planID;
            aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
            aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
            aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
            xsEnableRule("plagueOfSerpentsMonitor");
            break;
         }

         // We query for some buildings to prevent us casting this just randomly in the middle of the map.
         int queryID = kbUnitQueryCreate(aiPlanGetName(planID) + " Plague Of Serpents Query");
         kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
         kbUnitQuerySetUnitType(queryID, cUnitTypeLogicalTypeMilitaryProductionBuilding);
         kbUnitQuerySetMaximumDistance(queryID, 20.0);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateSeeable);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryMinimumCount, 0, 3);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
         
         aiPlanSetVariableBool(planID, cGodPowerPlanRequiresCombatPlan, 0, true);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelCombatPlanDistance);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocation);
         break;
      }

      case cProtoPowerLocustSwarm:
      {
         gLocustSwarmPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationDual);
         xsEnableRule("locustSwarmMonitor");
         break;
      }

      case cProtoPowerAncestors:
      {
         // Atm no support for casting it on water.

         // Defenders always cast in own base, normal personality 1/2 chance to do so too.
         if (cPersonalityCurrent == cPersonalityDefender ||
             (cPersonalityCurrent == cPersonalityStandard && xsRandBool() == true))
         {
            gAncestorsPlanID = planID;
            aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
            aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
            aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
            xsEnableRule("ancestorsDefensivelyMonitor");
            break;
         }

         int queryID = kbUnitQueryCreate(aiPlanGetName(planID) + " Ancestors Query");
         kbUnitQuerySetPlayerRelation(queryID, cPlayerRelationEnemyNotGaia);
         kbUnitQuerySetUnitType(queryID, cUnitTypeLogicalTypeLandMilitary);
         kbUnitQuerySetMaximumDistance(queryID, 20.0);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryMinimumCount, 0, 10);
         aiPlanSetVariableInt(planID, cGodPowerPlanQueryID, 0, queryID);
         
         aiPlanSetVariableBool(planID, cGodPowerPlanRequiresCombatPlan, 0, true);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelCombatPlanDistance);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocation);
         break;
      }

      case cProtoPowerCitadel:
      {
         gCitadelPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelUnit);
         xsEnableRule("citadelMonitor");
         break;
      }

      case cProtoPowerSonOfOsiris:
      {
         gSonOfOsirisPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelUnit);
         xsEnableRule("sooMonitor");
         break;
      }
      
      case cProtoPowerMeteor:
      {
         gMeteorPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
         xsEnableRule("meteorMonitor");
         break;
      }

      case cProtoPowerTornado:
      {
         gTornadoPlanID = planID;
         aiPlanSetVariableBool(planID, cGodPowerPlanAutoCast, 0, false);
         aiPlanSetVariableInt(planID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(planID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelLocationManually);
         xsEnableRule("tornadoMonitor");
         break;
      }

      default:
      {
         aiEchoWarning("setupEgyptianGodPowerPlan called with unrecognized protoPowerID: " + protoPowerID + ", name: " +
            kbGodPowerGetName(protoPowerID) + ".");
         break;
      }
   }
}

//==============================================================================
// rainMonitor
//==============================================================================
rule rainMonitor
inactive
minInterval 10
{
   if (kbPlayerGetAge(cMyID) == cAge1 || aiPlanGetIsIDValid(gVillagerMaintainPlan) == false)
   {
      return; // Not worth now.
   }
   debugGodPowers("--- Running Rule rainMonitor. ---");

   float numGatherers = aiGetNumberGatherers(cUnitTypeAbstractVillager, cResourceFood, -1, gFarmUnit);
   float maxGatherers = aiPlanGetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0);
   float aliveGatherers = kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive);
   aliveGatherers += kbUnitCount(cUnitTypeTradeUnit, cMyID, cUnitStateAlive);
   debugGodPowers("numGatherers: " + numGatherers + ", maxGatherers: " + maxGatherers + ", aliveGatherers: " + aliveGatherers + ".");
   // Need more than 30% of our max Villagers alive to consider this.
   if (aliveGatherers < (maxGatherers * 0.3))
   {
      return;
   }
   // We need to already be on at least 30% Farms to cast this, to get instant benefit.
   if (numGatherers > (aliveGatherers * 0.3))
   {
      aiPlanSetVariableBool(gRainPlanID, cGodPowerPlanAutoCast, 0, true);
      debugGodPowers("Casting Rain!");
      xsDisableRule("rainMonitor");
   }
}

//==============================================================================
// prosperityMonitor
//==============================================================================
rule prosperityMonitor
inactive
minInterval 10
{
   if (kbPlayerGetAge(cMyID) == cAge1 || aiPlanGetIsIDValid(gVillagerMaintainPlan) == false)
   {
      return; // Not worth now.
   }
   debugGodPowers("--- Running Rule prosperityMonitor. ---");

   static bool castProsperity = false;
   if (castProsperity == true)
   {
      // Force a quick redistribution.
      xsRuleIgnoreIntervalOnce("updateDistributionAndBreakdowns");
      xsDisableRule("prosperityMonitor");
      castProsperity = false;
      return;
   }

   float numGatherers = aiGetNumberGatherers(cUnitTypeAbstractVillager, cResourceGold, -1, cUnitTypeGoldResource);
   float maxGatherers = aiPlanGetVariableInt(gVillagerMaintainPlan, cTrainPlanNumberToMaintain, 0);
   float aliveGatherers = kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive);
   aliveGatherers += kbUnitCount(cUnitTypeTradeUnit, cMyID, cUnitStateAlive);
   debugGodPowers("numGatherers: " + numGatherers + ", maxGatherers: " + maxGatherers + ", aliveGatherers: " + aliveGatherers + ".");
   // Need more than 30% of our max Villagers alive to consider this.
   if (aliveGatherers < (maxGatherers * 0.3))
   {
      return;
   }
   // We need to already be on at least 30% gold to cast this, to get instant benefit.
   if (numGatherers > (aliveGatherers * 0.3))
   {
      aiPlanSetVariableBool(gProsperityPlanID, cGodPowerPlanAutoCast, 0, true);
      castProsperity = true;
      xsSetRuleMinInterval("prosperityMonitor", 3); // Wait for the cast to go off.
      debugGodPowers("Casting Prosperity!");
   }
}

//==============================================================================
// shiftingSandsMonitor
// We shift towards our attack if we're in an even battle and we can turn the tide.
//==============================================================================
rule shiftingSandsMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule shiftingSandsMonitor. ---");
   if (aiPlanGetState(gPrimaryLandDefendPlan) == cPlanStateAttack)
   {
      debugGodPowers("Primary land defend plan is in combat, can't shift away its defenders.");
      return;
   }
   vector gatherPoint = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);
   int numUnitsAtGatherPoint = getUnitCountByLocation(cUnitTypeMilitaryUnit, cMyID, cUnitStateAlive, gatherPoint,
      kbGodPowerGetRadius(cProtoPowerShiftingSands, cMyID));
   debugGodPowers("We found " + numUnitsAtGatherPoint + " units at our defend plan's gather point to potentially shift.");
   if ((cDifficultyCurrent <= cDifficultyModerate && numUnitsAtGatherPoint < 3) ||
       (cDifficultyCurrent >= cDifficultyHard && numUnitsAtGatherPoint < 5))
   {
      debugGodPowers("Too few units at our defend plan's gather point for casting Shifting Sands.");
      return;
   }

   int[] plans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
   int numPlans = plans.size();
   if (numPlans <= 0)
   {
      debugGodPowers("Found 0 attack plans in attack state to analyze.");
      return;
   }
   for (int i = 0; i < plans.size(); i++)
   {
      if (aiPlanGetParentID(plans[i]) != -1)
      {
         continue; // Skip reinforcement plans.
      }

      vector planLocation = aiPlanGetLocation(plans[i]);
      if (xsVectorDistanceXZ(planLocation, gatherPoint) < 75.0)
      {
         debugGodPowers("Our defend plan's gather point is too close to our plan's position, not worth to shift.");
         continue;
      }
      int numAttackingTroops = aiPlanGetNumberUnits(plans[i], -1, false);
      debugGodPowers("We found " + numAttackingTroops + " units belonging to our: " + aiPlanGetName(plans[i]));
      if ((cDifficultyCurrent <= cDifficultyModerate && numAttackingTroops < 3) ||
          (cDifficultyCurrent >= cDifficultyHard && numAttackingTroops < 5))
      {
         debugGodPowers("Too few attacking units to casting Shifting Sands.");
         continue; // Too few units left in our attack.
      }

      int numEnemies = getUnitCountByLocation(cUnitTypeMilitaryUnit, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
         planLocation, aiPlanGetVariableFloat(plans[i], cAttackPlanAttackModeEngageRange, 0), cUnitQueryVisibleStateVisible);
      debugGodPowers("We found " + numEnemies + " units belonging to the enemy.");
      // v2.7 IMP10: bylo > 0.8 → castuj jen kdyz jsme vicemene rovnocenni.
      // Zlepseni: castuj i kdyz jsme mirne presilovani (>= 0.6) - GP je nejcennejsi prave tehdy.
      if (numAttackingTroops > (numEnemies * 0.6) && numAttackingTroops < (numEnemies * 1.2))
      {
         debugGodPowers("Casting Shifting Sands to reinforce: " + aiPlanGetName(plans[i]));
         aiPlanSetVariableVector(gShiftingSandsPlanID, cGodPowerPlanTargetLocation, 0, gatherPoint);
         // Pick the first unit to have a better chance of not shifting at an invalid location which can happen with center point.
         vector shiftLocation = aiPlanGetLocation(plans[i], true);
         aiPlanSetVariableVector(gShiftingSandsPlanID, cGodPowerPlanTargetLocation, 1, shiftLocation);
         aiPlanSetVariableBool(gShiftingSandsPlanID, cGodPowerPlanAutoCast, 0, true);
         gShiftingSandsAttackPlanID = plans[i];
         gShiftingSandsLocation = shiftLocation;
         xsDisableRule("shiftingSandsMonitor");
         return;
      }
      else
      {
         debugGodPowers("Our units versus enemy units isn't in the right range to use Shifting Sands.");
      }
   }
}

//==============================================================================
// addShiftedUnitsToAttackPlanMonitor
//==============================================================================
rule addShiftedUnitsToAttackPlanMonitor
inactive
minInterval 1
{
   if (aiPlanGetIsIDValid(gShiftingSandsAttackPlanID) == false)
   {
      xsDisableRule("addShiftedUnitsToAttackPlanMonitor");
      return;
   }
   debugGodPowers("--- Running Rule addShiftedUnitsToAttackPlanMonitor. ---");

   static int runCount = 0;
   int queryID = useSimpleUnitQuery(cUnitTypeMilitaryUnit, cMyID, cUnitStateAlive, gShiftingSandsLocation,
                                    kbGodPowerGetRadius(cProtoPowerShiftingSands, cMyID));
   int numUnits = kbUnitQueryExecute(queryID);
   int[] units = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < numUnits; i++)
   {
      if (kbUnitGetPlanID(units[i]) != gShiftingSandsAttackPlanID)
      {
         aiPlanAddUnit(gShiftingSandsAttackPlanID, units[i]);
         debugGodPowers("Added unitID: " + units[i] + " to: " +  aiPlanGetName(gShiftingSandsAttackPlanID) + ".");
      }
   }

   runCount++;
   if (runCount >= 4)
   {
      // We have picked up all the units by now, reset ourself for a potential next run.
      runCount = 0;
      xsDisableRule("addShiftedUnitsToAttackPlanMonitor");
   }
}

//==============================================================================
// eclipseMonitor
//==============================================================================
rule eclipseMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule eclipseMonitor. ---");
   // We need more or equal to this amount of myth units to cast Eclipse.
   int treshold = 1;
   if (cDifficultyCurrent >= cDifficultyHard)
   {
      treshold = 2;
   }

   if (cPersonalityCurrent != cPersonalityDefender) // Standard and attacker.
   {
      int[] plans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
      for (int i = 0; i < plans.size(); i++)
      {
         if (aiPlanGetParentID(plans[i]) == -1) // Parent plan, no reinforcement.
         {
            if (getUnitCountByLocation(cUnitTypeMilitaryUnit, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
                  aiPlanGetLocation(plans[i]), aiPlanGetVariableFloat(plans[i], cAttackPlanAttackModeEngageRange, 0)) > 10)
            {
               int[] planUnits = aiPlanGetUnits(plans[i]);
               int count = 0;
               for (int j = 0; j < planUnits.size(); j++)
               {
                  if (kbUnitIsType(planUnits[j], cUnitTypeMythUnit) == true)
                  {
                     count++;
                     if (count >= treshold)
                     {
                        break;
                     }
                  }
               }
               if (count >= treshold)
               {
                  debugGodPowers("We found enough myth units in plan: " + aiPlanGetName(plans[i]) + " to cast Eclipse offensively!");
                  aiPlanSetVariableBool(gEclipsePlanID, cGodPowerPlanAutoCast, 0, true);
                  xsDisableRule("eclipseMonitor");
                  return;
               }
               else
               {
                  debugGodPowers("We didn't find enough myth units to cast Eclipse offensively for this plan: " + aiPlanGetName(plans[i]) + ".");
               }
            }
         }
      }
   }

   if (cPersonalityCurrent != cPersonalityAttacker) // Standard and defender.
   {
      if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == false)
      {
         return;
      }
      // We cast Eclipse defensively if our main base is under severe threat.
      if (gDefenseReflexPanic == true)
      {
         int[] planUnits = aiPlanGetUnits(gPrimaryLandDefendPlan);
         int count = 0;
         for (int i = 0; i < planUnits.size(); i++)
         {
            if (kbUnitIsType(planUnits[i], cUnitTypeMythUnit) == true)
            {
               count++;
               if (count >= treshold)
               {
                  break;
               }
            }
         }
         if (count >= treshold)
         {
            debugGodPowers("We found enough myth units to cast Eclipse defensively!");
            aiPlanSetVariableBool(gEclipsePlanID, cGodPowerPlanAutoCast, 0, true);
            xsDisableRule("eclipseMonitor");
            return;
         }
         else
         {
            debugGodPowers("We didn't find enough myth units to cast Eclipse defensively.");
         }
      } 
   }
}

//==============================================================================
// plagueOfSerpentsMonitor
//==============================================================================
rule plagueOfSerpentsMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule plagueOfSerpentsMonitor. ---");

   // v2.0: cast serpents tam kde jsou potreba - u aktivniho utoku nebo obrany
   vector serpentTarget = cInvalidVector;

   if (gAdaptAttackInProgress == true)
   {
      // Cast u aktivniho utoku - hadi se pridaji k armade
      int[] serpPlans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
      for (int sp = 0; sp < serpPlans.size(); sp++)
      {
         if (aiPlanGetParentID(serpPlans[sp]) != -1) { continue; }
         if (aiPlanGetNumberUnits(serpPlans[sp], -1, false) >= 3)
         {
            serpentTarget = aiPlanGetLocation(serpPlans[sp]);
            debugGodPowers("Plague of Serpents: casting at attack plan location.");
            break;
         }
      }
   }
   else if (gDefenseReflexPanic == true)
   {
      // Cast u obranny gatherpointu - hadi pomohou branit zakladnu
      serpentTarget = aiPlanGetVariableVector(gPrimaryLandDefendPlan, cDefendPlanGatherPoint, 0);
      if (serpentTarget != cInvalidVector)
         debugGodPowers("Plague of Serpents: casting at defense point (panic).");
   }

   // Fallback: puvodni logika (vlastni TC)
   if (serpentTarget == cInvalidVector)
   {
      int tcBaseID = getRandomTownCenterBaseID();
      if (tcBaseID == -1)
      {
         debugGodPowers("Currently can't cast Plague of Serpents because we have no TC bases left.");
         return;
      }
      serpentTarget = kbBaseGetMilitaryGatherPoint(cMyID, tcBaseID);
      debugGodPowers("Plague of Serpents: casting at own TC gather point (fallback).");
   }

   aiPlanSetVariableVector(gPlagueOfSerpentsPlanID, cGodPowerPlanTargetLocation, 0, serpentTarget);
   aiPlanSetVariableBool(gPlagueOfSerpentsPlanID, cGodPowerPlanAutoCast, 0, true);
   xsDisableRule("plagueOfSerpentsMonitor");
}

//==============================================================================
// locustSwarmMonitor
// Try to find 2 Villagers near an attack plan and just hope we get a good cast.
// Casting on Farms not supported atm.
//==============================================================================
rule locustSwarmMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule locustSwarmMonitor. ---");

   int[] plans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
   for (int i = 0; i < plans.size(); i++)
   {
      if (aiPlanGetParentID(plans[i]) == -1) // Parent plan, no reinforcement.
      {
         int queryID = useSimpleUnitQuery(cUnitTypeAbstractVillager, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
            aiPlanGetLocation(plans[i]), 29.0);
         kbUnitQuerySetAscendingSort(queryID, true);
         kbUnitQuerySetVisibleState(queryID, cUnitQueryVisibleStateVisible);
         kbUnitQueryExecute(queryID);
         int[] villagers = kbUnitQueryGetResults(queryID);
         if (villagers.size() < 2)
         {
            debugGodPowers("We didn't find enough Villagers to cast Locust Swarm for this plan: " + aiPlanGetName(plans[i]) + ".");
            continue;
         }

         debugGodPowers("We found enough Villagers near plan: " + aiPlanGetName(plans[i]) + " to cast Locust Swarm!");
         // Take closest + furthest, hope our direction catches something inbetween.
         aiPlanSetVariableVector(gLocustSwarmPlanID, cGodPowerPlanTargetLocation, 0, kbUnitGetPosition(villagers[0]));
         aiPlanSetVariableVector(gLocustSwarmPlanID, cGodPowerPlanTargetLocation, 1, kbUnitGetPosition(villagers[villagers.size() - 1]));
         aiPlanSetVariableBool(gLocustSwarmPlanID, cGodPowerPlanAutoCast, 0, true);
         xsDisableRule("locustSwarmMonitor");
         return;
      }
   }
}

//==============================================================================
// ancestorsDefensivelyMonitor
//==============================================================================
rule ancestorsDefensivelyMonitor
inactive
minInterval 10
{
   debugGodPowers("--- Running Rule ancestorsDefensivelyMonitor. ---");
   
   if (aiPlanGetIsIDValid(gPrimaryLandDefendPlan) == false)
   {
      return;
   }
   
   // We cast Ancestors defensively if our main base is under severe threat.
   if (gDefenseReflexPanic == true)
   {
      int closestUnit = getClosestUnitByLocation(cUnitTypeMilitaryUnit, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
                           kbBaseGetLocation(cMyID, gDefenseReflexBaseID), 100.0);
      if (kbUnitGetIsIDValid(closestUnit) == true)
      {
         aiPlanSetVariableVector(gAncestorsPlanID, cGodPowerPlanTargetLocation, 0, kbUnitGetPosition(closestUnit));
         aiPlanSetVariableBool(gAncestorsPlanID, cGodPowerPlanAutoCast, 0, true);
         debugGodPowers("Casting Ancestors defensively!");
         xsDisableRule("ancestorsDefensivelyMonitor");
      }
   }
}

//==============================================================================
// addMinionsToAttackPlanMonitor
//==============================================================================
rule addMinionsToAttackPlanMonitor
inactive
minInterval 1
{
   if (aiPlanGetIsIDValid(gAncestorsAttackPlanID) == false)
   {
      xsDisableRule("addMinionsToAttackPlanMonitor");
      return;
   }
   debugGodPowers("--- Running Rule addMinionsToAttackPlanMonitor. ---");
   static int runCount = 0;
   int queryID = useSimpleUnitQuery(cUnitTypeMinion);
   int numMinions = kbUnitQueryExecute(queryID);
   int[] units = kbUnitQueryGetResults(queryID);
   for (int i = 0; i < numMinions; i++)
   {
      if (kbUnitGetPlanID(units[i]) != gAncestorsAttackPlanID)
      {
         aiPlanAddUnit(gAncestorsAttackPlanID, units[i]);
         debugGodPowers("Added unitID: " + units[i] + " to: " +  aiPlanGetName(gAncestorsAttackPlanID) + ".");
      }
   }

   runCount++;
   if (runCount >= 16)
   {
      // We have picked up all the Minions by now, reset ourself for a potential next run.
      runCount = 0;
      xsDisableRule("addMinionsToAttackPlanMonitor");
   }
}

//==============================================================================
// citadelMonitor
//==============================================================================
rule citadelMonitor
inactive
minInterval 15
{
   debugGodPowers("--- Running Rule citadelMonitor. ---");

   // Get the most defended base that doesn't have a Citadel yet.
   int numBases = kbBaseGetNumber(cMyID);
   int safestBaseID = -1;
   float safestBaseRating = cMinFloat;

   for (int i = 0; i < numBases; i++)
   {
      int baseID = kbBaseGetIDByIndex(cMyID, i);
      if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == false)
      {
         continue;
      }
      // Already has a Citadel.
      if (kbBaseGetNumberUnitsOfType(cMyID, baseID, cUnitTypeTownCenter) == 0)
      {
         continue;
      }
      float defenseRating = kbBaseGetDefenseRating(cMyID, baseID);
      if (defenseRating > safestBaseRating)
      {
         safestBaseRating = defenseRating;
         safestBaseID = baseID;
      }
   }

   if (safestBaseID == -1)
   {
      debugGodPowers("Couldn't find a TC to cast Citadel on.");
      return;
   }

   int tcID = getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, kbBaseGetLocation(cMyID, safestBaseID), 20.0);
   if (tcID == -1)
   {
      aiEchoWarning("citadelMonitor - Our loop saw a TC base that was valid for Citadel but our getUnitByLocation couldn't " + 
         "find a TC in that base: " + kbBaseGetNameByID(cMyID, safestBaseID) + ".");
      return;
   }

   aiPlanSetVariableBool(gCitadelPlanID, cGodPowerPlanAutoCast, 0, true);
   aiPlanSetVariableInt(gCitadelPlanID, cGodPowerPlanTargetUnit, 0, tcID);
   xsDisableRule("citadelMonitor");
}

//==============================================================================
// sooMonitor
// Fetch a Pharaoh, potentially heal him with a Priest, then turn him into a SoO.
//==============================================================================
rule sooMonitor
inactive
minInterval 5
{
   debugGodPowers("--- Running Rule sooMonitor. ---");
   static int reservePlanID = -1;
   
   if (aiPlanGetIsIDValid(reservePlanID) == false)
   {
      reservePlanID = aiPlanCreate("SOO reserve plan", cPlanReserve, -1, gGodpowersCategoryID);
      aiPlanSetPriority(reservePlanID, 100);
      aiPlanAddUnitType(reservePlanID, cUnitTypeAbstractPharaoh, 1, 1, 1);
      aiPlanAddUnitType(reservePlanID, cUnitTypePriest, 1, 1, 1);
      aiPlanSetFlag(reservePlanID, cPlanFlagNoMoreUnits, true); // Prevent auto assignment.
   }

   static int pharaohID = -1;
   static int priestID = -1;
   if (kbUnitGetIsIDValid(pharaohID) == false)
   {
      pharaohID = getUnit(cUnitTypePharaoh);
      if (kbUnitGetIsIDValid(pharaohID) == false)
      {
         pharaohID = getUnit(cUnitTypePharaohNewKingdom);
      }
      if (kbUnitGetIsIDValid(pharaohID) == false)
      {
         pharaohID = -1;
         debugGodPowers("Found no alive Pharaoh to turn into SOO.");
         return;
      }
   }

   if (kbUnitGetStatFloat(pharaohID, cUnitStatCurrHP) == kbUnitGetStatFloat(pharaohID, cUnitStatMaxHP))
   {
      aiPlanSetVariableInt(gSonOfOsirisPlanID, cGodPowerPlanTargetUnit, 0, pharaohID);
      aiPlanSetVariableBool(gSonOfOsirisPlanID, cGodPowerPlanAutoCast, 0, true);
      aiPlanDestroy(reservePlanID);
      pharaohID = -1;
      priestID = -1;
      xsDisableRule("sooMonitor");
      return;
   }

   // Move to a "safe" spot.
   int baseID = getClosestTCBase(kbUnitGetPosition(pharaohID));
   if (baseID == -1)
   {
      aiPlanSetFlag(reservePlanID, cPlanFlagReadyForUnits, false); // This throws out the units if they were assigned before.
      debugGodPowers("We have no TC base to move our Pharaoh / Priest to to heal, can't cast SoO now.");
      return;
   }
   aiPlanSetFlag(reservePlanID, cPlanFlagReadyForUnits, true);
   
   if (kbUnitGetPlanID(pharaohID) != reservePlanID)
   {
      debugGodPowers("Added Pharaoh with ID " + pharaohID + " to the reserve plan, also moving him to main TC.");
      aiPlanAddUnit(reservePlanID, pharaohID, true);
   }
   aiTaskMoveUnit(pharaohID, kbBaseGetMilitaryGatherPoint(cMyID, baseID));

   // We will always be having Priests, since we train them as our only hero supply.
   if (kbUnitGetIsIDValid(priestID) == false)
   {
      int[] units = aiPlanGetUnits(gPrimaryLandDefendPlan, cUnitTypePriest);
      if (units.size() == 0)
      {
         priestID = -1;
         debugGodPowers("Found no alive Priest in our defend plan to heal our Pharaoh, quiting.");
         return;
      }
      priestID = units[0];
   }
   if (kbUnitGetPlanID(priestID) != reservePlanID)
   {
      debugGodPowers("Added Priest with ID " + priestID + " to the reserve plan.");
      aiPlanAddUnit(reservePlanID, priestID, true);
   }
   debugGodPowers("Tasking the Priest to heal the Pharaoh.");
   // Heal the Pharaoh.
   aiTaskWorkUnit(priestID, pharaohID);
}

//==============================================================================
// meteorMonitor
//==============================================================================
rule meteorMonitor
inactive
minInterval 5
{
   debugGodPowers("--- Running Rule meteorMonitor. ---");
   static int reservePlanID = -1;
   if (aiPlanGetIsIDValid(reservePlanID) == false)
   {
      reservePlanID = aiPlanCreate("Meteor reserve plan", cPlanReserve, -1, gGodpowersCategoryID);
      aiPlanSetPriority(reservePlanID, 100);
      aiPlanSetFlag(reservePlanID, cPlanFlagNoMoreUnits, true); // Prevent auto assignment.
   }

   static int currentState = cGPStateBegin;
   static int scoutID = -1;
   static int targetID = -1;
   static int iterator = 0; // Used to only send a move command/debug output every 5 iterations.
   bool castGodPower = false;

   switch (currentState)
   {
      // BUG FIX v1.8: bylo cGPStateCleanup - zpusobovalo ze Meteor NIKDY nevystrelil
      // (state zacinak jako cGPStateBegin=0, ale case cGPStateCleanup=2 nikdy nenastal)
      case cGPStateBegin:
      {
         // v2.1: prefer visible Town Center clusters near our active attack.
         int[] meteorPlans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
         int meteorBestCluster = 0;
         vector meteorBestPos = cInvalidVector;
         for (int mpi = 0; mpi < meteorPlans.size(); mpi++)
         {
            if (aiPlanGetParentID(meteorPlans[mpi]) != -1)
            {
               continue;
            }
            vector meteorAttackPos = aiPlanGetLocation(meteorPlans[mpi]);
            float meteorSearchRange = aiPlanGetVariableFloat(meteorPlans[mpi], cAttackPlanAttackModeEngageRange, 0) + 35.0;
            int meteorTCQueryID = useSimpleUnitQuery(cUnitTypeAbstractSocketedTownCenter, cPlayerRelationEnemyNotGaia,
               cUnitStateAlive, meteorAttackPos, meteorSearchRange);
            int meteorNumTCs = kbUnitQueryExecute(meteorTCQueryID);
            int[] meteorTCs = kbUnitQueryGetResults(meteorTCQueryID);
            for (int mti = 0; mti < meteorNumTCs; mti++)
            {
               vector meteorTCPos = kbUnitGetPosition(meteorTCs[mti]);
               if (kbLocationVisible(meteorTCPos) == false)
               {
                  continue;
               }
               int meteorClusterSize = getUnitCountByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia,
                  cUnitStateAlive, meteorTCPos, 28.0, cUnitQueryVisibleStateVisible);
               if (meteorClusterSize > meteorBestCluster)
               {
                  meteorBestCluster = meteorClusterSize;
                  meteorBestPos = meteorTCPos;
               }
            }
         }
         if (meteorBestCluster >= 5 && meteorBestPos != cInvalidVector)
         {
            debugGodPowers("Meteor: targeting TC cluster near attack (" + meteorBestCluster + " buildings).");
            aiPlanSetVariableVector(gMeteorPlanID, cGodPowerPlanTargetLocation, 0, meteorBestPos);
            aiPlanSetVariableBool(gMeteorPlanID, cGodPowerPlanAutoCast, 0, true);
            xsDisableRule("meteorMonitor");
            return;
         }

         bool foundTC = godPowerFindTCInRangeAndScout(gMeteorPlanID, scoutID, targetID, castGodPower);
         // TC can already be in range, then we're already done!
         if (castGodPower == true)
         {
            xsSetRuleMinInterval("meteorMonitor", 5);
            currentState = cGPStateCleanup;
            return;
         }
         if (foundTC == true)
         {
            currentState = cGPStatePathingToLocation;
            // Need to keep checking godPowerExploreTargetPosition often.
            xsSetRuleMinInterval("meteorMonitor", 1);
         }
         break;
      }

      case cGPStatePathingToLocation:
      {
         bool pathingToLocation = godPowerExploreTargetPosition(gMeteorPlanID, scoutID, targetID, iterator, reservePlanID, castGodPower);
         if (castGodPower == true)
         {
            xsSetRuleMinInterval("meteorMonitor", 5);
            currentState = cGPStateCleanup;
            return;
         }
         if (pathingToLocation == false)
         {
            iterator = 0;
            currentState = cGPStateBegin;
            xsSetRuleMinInterval("meteorMonitor", 5);
         }
         break;
      }

      case cGPStateCleanup:
      {
         // Remove scout from reserve plan a bit later otherwise we might lose vision too fast.
         if (aiPlanGetIsIDValid(reservePlanID) == true)
         {
            aiPlanDestroy(reservePlanID);
         }
         iterator = 0;
         xsDisableRule("meteorMonitor");
         break;
      }
   }
}

//==============================================================================
// tornadoMonitor
//==============================================================================
rule tornadoMonitor
inactive
minInterval 5
{
   debugGodPowers("--- Running Rule tornadoMonitor. ---");
   static int reservePlanID = -1;
   if (aiPlanGetIsIDValid(reservePlanID) == false)
   {
      reservePlanID = aiPlanCreate("Tornado reserve plan", cPlanReserve, -1, gGodpowersCategoryID);
      aiPlanSetPriority(reservePlanID, 100);
      aiPlanSetFlag(reservePlanID, cPlanFlagNoMoreUnits, true); // Prevent auto assignment.
   }

   static int currentState = cGPStateBegin;
   static int scoutID = -1;
   static int targetID = -1;
   static int iterator = 0; // Used to only send a move command/debug output every 5 iterations.
   bool castGodPower = false;

   switch (currentState)
   {
      case cGPStateBegin:
      {
         // v1.8: preferuj vojenskou budovu bliz aktivniho utoku - nici vyrobni kapacitu nepritele
         int[] tornadoPlans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
         for (int tp = 0; tp < tornadoPlans.size(); tp++)
         {
            if (aiPlanGetParentID(tornadoPlans[tp]) != -1)
               continue;
            vector tornadoAttackPos = aiPlanGetLocation(tornadoPlans[tp]);
            int tornadoMilBldg = getClosestUnitByLocation(
               cUnitTypeLogicalTypeMilitaryProductionBuilding,
               cPlayerRelationEnemyNotGaia, cUnitStateAlive,
               tornadoAttackPos, 50.0, cUnitQueryVisibleStateVisible);
            if (tornadoMilBldg != -1)
            {
               vector tornadoMilPos = kbUnitGetPosition(tornadoMilBldg);
               debugGodPowers("Tornado: targeting military building near attack.");
               aiPlanSetVariableVector(gTornadoPlanID, cGodPowerPlanTargetLocation, 0, tornadoMilPos);
               aiPlanSetVariableBool(gTornadoPlanID, cGodPowerPlanAutoCast, 0, true);
               xsDisableRule("tornadoMonitor");
               return;
            }
         }
         // Fallback: puvodne cili na TC (pokud nejsou viditelne vojenske budovy)
         bool foundTC = godPowerFindTCInRangeAndScout(gTornadoPlanID, scoutID, targetID, castGodPower);
         // TC can already be in range, then we're already done!
         if (castGodPower == true)
         {
            xsSetRuleMinInterval("tornadoMonitor", 5);
            currentState = cGPStateCleanup;
            return;
         }
         if (foundTC == true)
         {
            currentState = cGPStatePathingToLocation;
            // Need to keep checking godPowerExploreTargetPosition often.
            xsSetRuleMinInterval("tornadoMonitor", 1);
         }
         break;
      }

      case cGPStatePathingToLocation:
      {
         bool pathingToLocation = godPowerExploreTargetPosition(gTornadoPlanID, scoutID, targetID, iterator, reservePlanID, castGodPower);
         if (castGodPower == true)
         {
            xsSetRuleMinInterval("tornadoMonitor", 5);
            currentState = cGPStateCleanup;
            return;
         }
         if (pathingToLocation == false)
         {
            iterator = 0;
            currentState = cGPStateBegin;
            xsSetRuleMinInterval("tornadoMonitor", 5);
         }
         break;
      }

      case cGPStateCleanup:
      {
         // Remove scout from reserve plan a bit later otherwise we might lose vision too fast.
         if (aiPlanGetIsIDValid(reservePlanID) == true)
         {
            aiPlanDestroy(reservePlanID);
         }
         iterator = 0;
         xsDisableRule("tornadoMonitor");
         break;
      }
   }
}
