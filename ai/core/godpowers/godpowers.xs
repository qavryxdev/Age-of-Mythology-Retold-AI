//==============================================================================
/* godpowers.xs

   This file contains all logic for the management of god powers.

*/
//==============================================================================

//==============================================================================
// setUpGodPowerPlan
//==============================================================================
bool setUpGodPowerPlan(int protoPowerID = -1)
{
   // Unsupported god powers for now.
   if (protoPowerID == cProtoPowerUnderworldPassage)
   {
      debugGodPowers("Unsupported god power, exiting early.");
      return true;
   }

   int planID = aiPlanCreate("GodPower " + kbGodPowerGetName(protoPowerID), cPlanGodPower, -1, gGodpowersCategoryID);
   aiPlanSetVariableInt(planID, cGodPowerPlanPowerProtoID, 0, protoPowerID);
   aiPlanSetEventHandler(planID, cPlanEventStateChange, "godPowerStateChangeHandler");

   switch (protoPowerID)
   {
      case cProtoPowerBolt:
      case cProtoPowerSentinel:
      case cProtoPowerLure:
      case cProtoPowerRestoration:
      case cProtoPowerCeaseFire:
      case cProtoPowerPestilence:
      case cProtoPowerBronze:
      case cProtoPowerCurse:
      case cProtoPowerUnderworldPassage:
      case cProtoPowerPlentyVault:
      case cProtoPowerLightningStorm:
      case cProtoPowerEarthquake:
      {
         setupGreekGodPowerPlan(planID, protoPowerID);
         break;
      }
      case cProtoPowerVision:
      case cProtoPowerRain:
      case cProtoPowerProsperity:
      case cProtoPowerEclipse:
      case cProtoPowerShiftingSands:
      case cProtoPowerPlagueOfSerpents:
      case cProtoPowerLocustSwarm:
      case cProtoPowerAncestors:
      case cProtoPowerCitadel:
      case cProtoPowerSonOfOsiris:
      case cProtoPowerMeteor:
      case cProtoPowerTornado:
      {
         setupEgyptianGodPowerPlan(planID, protoPowerID);
         break;
      }
      case cProtoPowerDwarvenMine:
      case cProtoPowerSpy:
      case cProtoPowerGreatHunt:
      case cProtoPowerGullinbursti:
      case cProtoPowerForestFire:
      case cProtoPowerHealingSpring:
      case cProtoPowerUndermine:
      case cProtoPowerAsgardianBastion:
      case cProtoPowerFrost:
      case cProtoPowerFlamingWeapons:
      case cProtoPowerWalkingWoods:
      case cProtoPowerTempest:
      case cProtoPowerRagnarok:
      case cProtoPowerFimbulwinter:
      case cProtoPowerNidhogg:
      case cProtoPowerInferno:
      {
         setupNorseGodPowerPlan(planID, protoPowerID);
         break;
      }
      case cProtoPowerDeconstruction:
      case cProtoPowerShockwave:
      case cProtoPowerGaiaForest:
      case cProtoPowerCarnivora:
      case cProtoPowerValor:
      case cProtoPowerSpiderLair:
      case cProtoPowerTraitor:
      case cProtoPowerChaos:
      case cProtoPowerHesperidesTree:
      case cProtoPowerVortex:
      case cProtoPowerTartarianGate:
      case cProtoPowerImplode:
      {
         setupAtlanteanGodPowerPlan(planID, protoPowerID);
         break;
      }
      default:
      {
         aiEchoWarning("setUpGodPowerPlan - Received an unrecognized protoPowerID: " + protoPowerID + ", name: " +
            kbGodPowerGetName(protoPowerID) + ".");
         // Prevent endless error messages, destroy the plan and return true.
         aiPlanDestroy(planID);
         return true;
      }
   }

   debugGodPowers("Created a god power plan for: " + kbGodPowerGetName(protoPowerID) + ".");
   return true;
}

//==============================================================================
// Class GodPowerManager
//==============================================================================
class GodPowerManager
{
   int[] godPowerBank = default;

   void addGodPowerToBank(int protoPowerID = -1)
   {
      if (kbGodPowerGetIsIDValid(protoPowerID) == false)
      {
         aiEchoWarning("Calling addGodPowerToBank with an invalid protoPowerID: " + protoPowerID + ".");
         return;
      }
      debugGodPowers("Adding new god power: " + kbGodPowerGetName(protoPowerID) + " to the god power bank.");
      godPowerBank.add(protoPowerID);
   }

   // If you manually remove a GP, outside of useUnusedGodPowers, this also has some utility to tell you if the GP even existed.
   bool removeGodPowerFromBank(int protoPowerID = -1)
   {
      bool removed = godPowerBank.removeValue(protoPowerID);
      if (removed == true)
      {
         debugGodPowers("Removed god power: " + kbGodPowerGetName(protoPowerID) + " from the god power bank.");
      }
      else
      {
         aiEchoWarning("Attempted to remove " + kbGodPowerGetName(protoPowerID) + " from the god power bank but it was never in there.");
      }
      return removed;
   }

   // Create god power plans for each god power that we have in the bank.
   void useUnusedGodPowers()
   {
      for (int i = 0; i < godPowerBank.size(); i++)
      {
         if (kbGodPowerGetCost(godPowerBank[i], cMyID) != 0.0 &&
             kbGodPowerGetNumPrePurchasedUses(godPowerBank[i], cMyID) == 0)
         {
            debugGodPowers("Didn't create a god power plan for god power: " + kbGodPowerGetName(godPowerBank[i]) + 
               " because we have no charges, some other system must've already cast it.");
            removeGodPowerFromBank(godPowerBank[i]);
            i--;
            continue;
         }
         if (setUpGodPowerPlan(godPowerBank[i]) == true)
         {
            removeGodPowerFromBank(godPowerBank[i]);
            i--;
         }
      }
   }
};
extern GodPowerManager godPowerManager;

//==============================================================================
// godPowerGrantedHandler
// We can't just create plans for each god power that we get because our strategies may want to manually control them.
// Every time we pick a new strategy, and that strategy allows automatic god power casting, we clear out the bank.
// This gets called before the strategy system potentially reacts to an age up, so we already have the new GP in the bank then.
//==============================================================================
void godPowerGrantedHandler(int protoPowerID = -1)
{
   if (protoPowerID == cProtoPowerTitanGate)
   {
      debugGodPowers("Received a Titan Gate god power charge, starting the placement logic now.");
      xsEnableRule("titanGateConstructionMonitor");
      xsRuleIgnoreIntervalOnce("titanGateConstructionMonitor");
      return;
   }
   godPowerManager.addGodPowerToBank(protoPowerID);
}

//==============================================================================
// godPowerStateChangeHandler
// God powers can be blocked by various mechanics in the game.
// We can't check for all of them when we make our god power plans.
// So it's very plausible some of our GPs fail to cast.
// Catch that here and put them back into our GP bank.
// And sometimes we need to do something when we succeed in casting a GP too.
//==============================================================================
void godPowerStateChangeHandler(int planID = -1)
{
   int protoPowerID = aiPlanGetVariableInt(planID, cGodPowerPlanPowerProtoID, 0);
   if (kbGodPowerGetIsIDValid(protoPowerID) == false)
   {
      return; // We could've accidentally made an invalid plan, don't keep adding it back to the bank.
   }
   int planState = aiPlanGetState(planID);
   if (planState == cPlanStateFailed)
   {
      debugGodPowers(kbGodPowerGetName(protoPowerID) + " failed to be cast, adding it back to the bank.");
      godPowerManager.addGodPowerToBank(protoPowerID);
      // We will potentially try to recast via useUnusedGodPowersMonitor.
      return;
   }

   if (planState == cPlanStateDone)
   {
      switch (protoPowerID)
      {
         case cProtoPowerShiftingSands:
         {
            // We've shifted forwards to an attack plan, put units in that plan.
            if (aiPlanGetIsIDValid(gShiftingSandsAttackPlanID) == true)
            {
               xsEnableRule("addShiftedUnitsToAttackPlanMonitor");
            }
            break;
         }
         case cProtoPowerAncestors:
         {
            // Ancestors cast offensively will have this bool set to true.
            // We must now add these Minions to the attack plan.
            if (aiPlanGetVariableBool(planID, cGodPowerPlanRequiresCombatPlan, 0) == true)
            {
               // Save what plan we need to add them to.
               gAncestorsAttackPlanID = aiPlanGetVariableInt(planID, cGodPowerPlanCombatPlanID, 0);
               xsEnableRule("addMinionsToAttackPlanMonitor");
            }
            break;
         }
         case cProtoPowerSonOfOsiris:
         {
            int sooID = getUnit(cUnitTypeSonOfOsiris);
            if (kbUnitGetIsIDValid(sooID) == false)
            {
               return;
            }
            int empowerPlanID = kbUnitGetPlanID(sooID);
            if (aiPlanGetIsIDValid(empowerPlanID) == true)
            {
               // Free the SoO for combat.
               if (aiPlanGetType(empowerPlanID) == cPlanEmpower)
               {
                  aiPlanRemoveUnit(empowerPlanID, sooID);
               }
            }
            break;
         }
         case cProtoPowerGullinbursti:
         {
            xsEnableRule("gullinburstiDefendMonitor");
            break;
         }
         case cProtoPowerWalkingWoods:
         {
            xsEnableRule("addWalkingWoodsToAttackPlanMonitor");
            break;
         }
         case cProtoPowerGaiaForest:
         {
            if (isBuildOrderDone() == false)
            {
               xsEnableRule("gaiaForestTransition");
            }
            break;
         }
         case cProtoPowerTraitor:
         {
            // Traitor removes the unit completely and then instantiates a new one, we can't save the ID.
            if (aiPlanGetIsIDValid(gTraitorAssignToPlanID) == true)
            {
               xsEnableRule("addTraitorToPlanMonitor");
            }
            break;
         }
         case cProtoPowerVortex:
         {
            xsEnableRule("addVortexedUnitsToAttackPlanMonitor");
            break;
         }
      }
   }
}

//==============================================================================
// isOffensiveGodPower - v1.2
// Vrati true pokud je dany GP primarne ofenzivni.
// Ofenzivni GP by mely cekat na aktivni utocny plan.
//==============================================================================
bool isOffensiveGodPower(int protoPowerID = -1)
{
   switch (protoPowerID)
   {
      case cProtoPowerBolt:
      case cProtoPowerLightningStorm:
      case cProtoPowerEarthquake:
      case cProtoPowerEclipse:
      case cProtoPowerPlagueOfSerpents:
      case cProtoPowerLocustSwarm:
      case cProtoPowerMeteor:
      case cProtoPowerTornado:
      case cProtoPowerForestFire:
      case cProtoPowerUndermine:
      case cProtoPowerFrost:
      case cProtoPowerFlamingWeapons:
      case cProtoPowerNidhogg:
      case cProtoPowerInferno:
      case cProtoPowerDeconstruction:
      case cProtoPowerShockwave:
      case cProtoPowerChaos:
      case cProtoPowerTraitor:
      case cProtoPowerVortex:
      case cProtoPowerImplode:
      case cProtoPowerWalkingWoods:
      case cProtoPowerShiftingSands:
      {
         return true;
      }
   }
   return false;
}

//==============================================================================
// useUnusedGodPowersMonitor
// Keep clearing out our bank if we're allowed to.
// We don't do this too often because if a GP instantly fails and we then
// instantly create another plan for it, most likely it will fail again.
// So to prevent a casting fail loop we wait a bit.
//==============================================================================
rule useUnusedGodPowersMonitor
group defaultArchaicRules
inactive
minInterval 10
{
   if (checkStrategyFlag(cStrategyFlagAutomaticGodPowerUsage) == false) { return; }

   // v2.5 BUG30 FIX: bylo: smycka hledajici cPlanStateAttack (plan v tomto stavu jen pri samotnem boji u nepritele).
   // Ofenzivni GP se tedy vytvarily az kdyz armada jiz bojovala, ale 10s interval monitoru
   // celou bitvu castokrat zmeskl. gAdaptAttackInProgress je true po cely prubehu utoku
   // (od spusteni createDefaultAttackPlan az po ukonceni), coz je spravne okno pro spousteni GP.
   // bylo: bool haveActiveAttack = false; + smycka s cPlanStateAttack
   bool haveActiveAttack = gAdaptAttackInProgress;

   // Pouzij vsechny GP v bance - ale ofenzivni pouze pokud utocime NEBO jsme v panice
   for (int gpIdx = 0; gpIdx < godPowerManager.godPowerBank.size(); gpIdx++)
   {
      int gp = godPowerManager.godPowerBank[gpIdx];
      if (isOffensiveGodPower(gp) == true && haveActiveAttack == false && gDefenseReflexPanic == false)
      {
         debugGodPowers("v2.5: Zadrzuji ofenzivni GP " + kbGodPowerGetName(gp) + " - cekam na spusteni utoku (gAdaptAttackInProgress).");
         continue; // Preskocit, nedelat plan pro tento GP zatim
      }
      // v2.1 Frost-specificka kontrola odstranerana v2.5: haveActiveAttack=gAdaptAttackInProgress pokryva to same.
      if (setUpGodPowerPlan(gp) == true)
      {
         godPowerManager.removeGodPowerFromBank(gp);
         gpIdx--;
      }
   }
}

//==============================================================================
// godPowerCastedHandler
//==============================================================================
void godPowerCastedHandler(int index = -1)
{
   debugGodPowers("God power was cast!");
   //debugGodPowers("Index: " + index);
   //debugGodPowers("Location: " + kbGodPowerCastEventGetCastLocation(index));
   int casterID = kbGodPowerCastEventInfoGetCaster(index);
   debugGodPowers("Caster: " + casterID);
   int godPowerID = kbGodPowerCastEventInfoGetProtoPower(index);
   debugGodPowers("Proto Power: " + kbGodPowerGetName(godPowerID));

   if (casterID == cMyID)
   {
      // Generic / offensive / eco god powers all have unique chats.
      switch (godPowerID)
      {
         case cProtoPowerSentinel:
         case cProtoPowerRestoration:
         case cProtoPowerCeaseFire:
         case cProtoPowerBronze:
         case cProtoPowerUnderworldPassage:
         case cProtoPowerVision:
         case cProtoPowerEclipse:
         case cProtoPowerShiftingSands:
         case cProtoPowerPlagueOfSerpents:
         case cProtoPowerCitadel:
         case cProtoPowerSonOfOsiris:
         case cProtoPowerSpy:
         case cProtoPowerHealingSpring:
         case cProtoPowerRagnarok:
         case cProtoPowerDeconstruction:
         case cProtoPowerValor:
         case cProtoPowerSpiderLair:
         case cProtoPowerHesperidesTree:
         {
            sendStatementToEverybody(cAICommPromptToEverybodyGenericGodPower);
         }
         case cProtoPowerBolt:
         case cProtoPowerPestilence:
         case cProtoPowerCurse:
         case cProtoPowerLightningStorm:
         case cProtoPowerEarthquake:
         case cProtoPowerLocustSwarm:
         case cProtoPowerAncestors:
         case cProtoPowerMeteor:
         case cProtoPowerTornado:
         case cProtoPowerForestFire:
         case cProtoPowerUndermine:
         case cProtoPowerFrost:
         case cProtoPowerFlamingWeapons:
         case cProtoPowerWalkingWoods:
         case cProtoPowerFimbulwinter:
         case cProtoPowerNidhogg:
         case cProtoPowerShockwave:
         case cProtoPowerCarnivora:
         case cProtoPowerTraitor:
         case cProtoPowerChaos:
         case cProtoPowerVortex:
         case cProtoPowerTartarianGate:
         case cProtoPowerImplode:
         {
            sendStatementToEnemies(cAICommPromptToEnemyOffensiveGodPower);
         }
         case cProtoPowerLure:
         case cProtoPowerPlentyVault:
         case cProtoPowerRain:
         case cProtoPowerProsperity:
         case cProtoPowerDwarvenMine:
         case cProtoPowerGreatHunt:
         case cProtoPowerGaiaForest:
         {
            sendStatementToEverybody(cAICommPromptToEverybodyEconomicGodPower);
         }
      }
   }
}

//==============================================================================
// valorRebuyMonitor
// Valor is a special GP that we want to get a lot early on and thus isn't suited for the other logic.
//==============================================================================
rule valorRebuyMonitor
group defaultClassicalRules
inactive
minInterval 30
{
   if (kbTechGetStatus(cTechClassicalAgePrometheus) != cTechStatusActive)
   {
      xsDisableRule("valorRebuyMonitor");
      return;
   }
   if (checkStrategyFlag(cStrategyFlagRebuysGodPowers) == false)
   {
      return;
   }
   debugGodPowers("--- Running Rule valorRebuyMonitor ---");

   float rebuyCost = kbGodPowerGetPrePurchaseCost(cProtoPowerValor, 1, cMyID);
   if (rebuyCost >= 15.0)
   {
      debugGodPowers("Valor now costs " + rebuyCost + " which is too expensive, never rebuying again.");
      xsDisableRule("valorRebuyMonitor");
      return;
   }
   if (kbGodPowerIsOnCooldown(cProtoPowerValor, cMyID) == true)
   {
      debugGodPowers("Valor is still on cooldown, can't rebuy.");
      return;
   }
   if (kbGodPowerIsRepeatable(cProtoPowerValor, cMyID) == false)
   {
      debugGodPowers("Valor can't be rebought at all.");
      return;
   }
   if (kbGodPowerGetCost(cProtoPowerValor, cMyID) == 0.0)
   {
      if (aiPlanGetIDByTypeAndVariableIntValue(cPlanGodPower, cGodPowerPlanPowerProtoID, cProtoPowerValor, 0) == -1)
      {
         godPowerGrantedHandler(cProtoPowerValor);
         debugGodPowers("Valor still had a free charge but didn't have a plan, created one now.");
         return;
      }
      debugGodPowers("We still have charges on Valor, can't rebuy.");
      return;
   }
   if (kbGodPowerCanPrePurchase(cProtoPowerValor, cMyID) == false)
   {
      debugGodPowers("Valor can't be rebought at this moment.");
      return;
   }
   if (rebuyCost > (-gResourceNeeds[cResourceFavor]))
   {
      debugGodPowers("Don't have enough excess favor to buy Valor.");
      return;
   }

   debugGodPowers("Decided to buy another charge for Valor.");
   aiPrePurchaseGodPower(cProtoPowerValor, 1);
   godPowerGrantedHandler(cProtoPowerValor);
}

//==============================================================================
// wantToRebuyGodPower
// This idea is that the really strong GPs like Lightning Storm + Son of Osiris are always valid.
// And stuff like Bolt + Undermine become invalid on cost after some time.
// Thus we re-use a lot of GPs, but in the end only the most powerful remain.
//==============================================================================
bool wantToRebuyGodPower(int protoPowerID = -1, float rebuyCost = 0.0)
{
   switch (protoPowerID)
   {
      // Greek.
      case cProtoPowerBolt:
      {
         if (rebuyCost >= 125.0)
         {
            debugGodPowers("   Not rebuying Bolt since it's too expensive now.");
            return false;
         }
         break;
      }
      case cProtoPowerSentinel:
      {
         if (rebuyCost >= 75.0)
         {
            debugGodPowers("   Not rebuying Sentinels since it's too expensive now.");
            return false;
         }
         if (kbUnitCount(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateAlive) == 0)
         {
            debugGodPowers("   Not rebuying Sentinels since we have no TC to cast it on.");
            return false;
         }
         break;
      }
      case cProtoPowerPestilence:
      {
         if (rebuyCost >= 100.0)
         {
            debugGodPowers("   Not rebuying Pestilence since it's too expensive now.");
            return false;
         }
         break;
      }
      case cProtoPowerUnderworldPassage:
      {
         if (kbUnitCount(cUnitTypeUnderworldPassage, cMyID, cUnitStateAlive) > 0)
         {
            debugGodPowers("   Not rebuying Underworld since we already have one set alive.");
            return false;
         }
         break;
      }
      case cProtoPowerPlentyVault:
      {
         if (kbUnitCount(cUnitTypePlentyVault, cMyID, cUnitStateAlive) >= 5)
         {
            debugGodPowers("   Not rebuying Plenty Vault since we already have 5 or more alive.");
            return false;
         }
         break;
      }

      // Egyptian.
      case cProtoPowerRain:
      {
         if (rebuyCost >= 60.0)
         {
            debugGodPowers("   Not rebuying Rain since it's too expensive now.");
            return false;
         }
         break;
      }
      case cProtoPowerProsperity:
      {
         if (aiPlanGetIDByTypeAndVariableIntValue(cPlanGather, cGatherPlanResourceType, cResourceGold, 0) == -1)
         {
            debugGodPowers("   Not rebuying Prosperity because we have no gather plans on gold left.");
            return false;
         }
         break;
      }
      case cProtoPowerPlagueOfSerpents:
      {
         if (rebuyCost >= 100.0)
         {
            debugGodPowers("   Not rebuying Plague of Serpents since it's too expensive now.");
            return false;
         }
         if (kbUnitCount(cUnitTypeSerpent, cMyID, cUnitStateAlive) > 0)
         {
            debugGodPowers("   Not rebuying Plague Of Serpents since we still have some alive.");
            return false;
         }
         break;
      }
      case cProtoPowerShiftingSands:
      {
         // We're not so good with this power, limit on cost.
         if (rebuyCost >= 100.0)
         {
            debugGodPowers("   Not rebuying Shifting Sands since it's too expensive now.");
            return false;
         }
         break;
      }
      case cProtoPowerEclipse:
      {
         if (rebuyCost >= 165.0)
         {
            debugGodPowers("   Not rebuying Eclipse since it's too expensive now.");
            return false;
         }
         break;
      }
      case cProtoPowerCitadel:
      {
         if (kbUnitCount(cUnitTypeTownCenter, cMyID, cUnitStateAlive) == 0)
         {
            debugGodPowers("   Not rebuying Citadel since we have no TC to cast it on.");
            return false;
         }
         break;
      }

      // Norse.
      case cProtoPowerDwarvenMine:
      {
         if (rebuyCost >= 160.0)
         {
            debugGodPowers("   Not rebuying Dwarven Mine since it's too expensive now.");
            return false;
         }
         break;
      }
      case cProtoPowerHealingSpring:
      {
         bool foundValidBase = false;
         int numberBases = kbBaseGetNumber(cMyID);
         for (int i = 0; i < numberBases; i++)
         {
            int baseID = kbBaseGetIDByIndex(cMyID, i);
            if (kbBaseIsFlagSet(cMyID, baseID, cBaseFlagTownCenter) == true)
            {
               vector MGP = kbBaseGetMilitaryGatherPoint(cMyID, baseID);
               if (MGP == cInvalidVector)
               {
                  continue;
               }
               if (getUnitCountByLocation(cUnitTypeHealingSpring, cPlayerRelationAny, cUnitStateAlive, MGP, 30.0) >= 1)
               {
                  continue;
               }
               foundValidBase = true;
               break;
            }
         }
         if (foundValidBase == false)
         {
            debugGodPowers("   Not Rebuying Healing Spring because we found na valid TC base to cast it on.");
            return false;
         }
         break;
      }
      case cProtoPowerUndermine:
      {
         if (rebuyCost >= 100.0)
         {
            debugGodPowers("   Not rebuying Undermine since it's too expensive now.");
            return false;
         }
         break;
      }
      case cProtoPowerAsgardianBastion:
      {
         if (kbUnitCount(cUnitTypeAbstractSocketedTownCenter, cMyID, cUnitStateAlive) == 0)
         {
            debugGodPowers("   Not rebuying Asgardian Bastion since we have no TC to cast it on.");
            return false;
         }
         break;
      }
      case cProtoPowerWalkingWoods:
      {
         // 3 total casts, hopefully also guards against not buying it when no trees are left.
         if (rebuyCost >= 200.0)
         {
            debugGodPowers("   Not rebuying Walking Woods since it's too expensive now.");
            return false;
         }
         break;
      }
      case cProtoPowerRagnarok:
      {
         int wantedEcoPop = aiGetEconomyPop();
         int villagerCount = kbUnitCount(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive);
         int caravanCount = kbUnitCount(gCaravanUnit, cMyID, cUnitStateAlive);
         // Reduce wantedEcoPop by the Caravan count first.
         float percentageVillsAlive = xsIntToFloat(villagerCount) / xsIntToFloat(wantedEcoPop - caravanCount);

         if (percentageVillsAlive < 0.50)
         {
            debugGodPowers("   Not rebuying Ragnraok because we don't have enough Villagers alive to cast Ragnarok effectively.");
            return false;
         }
         break;
      }

      // Atlantean.
      case cProtoPowerDeconstruction:
      {
         if (rebuyCost > 40.0)
         {
            debugGodPowers("   Not rebuying Deconstruction since it's too expensive now.");
            return false;
         }
         break;
      }
      case cProtoPowerGaiaForest:
      {
         int baseID = getMostDefendedTCBase();
         if (baseID == -1)
         {
            debugGodPowers("   Not rebuying Gaia Forest since we have no TC base left.");
            return false;
         }
         vector location = kbBaseGetLocation(cMyID, baseID);
         float range = kbBaseGetDistance(cMyID, baseID) + 10.0;
         if (getUnitCountByLocation(cUnitTypeTreeGaia, 0, cUnitStateAlive, location, range) >= 10)
         {
            debugGodPowers("   Not rebuying Gaia Forest since we have enough trees left for now.");
            return false;
         }
         break;
      }
      case cProtoPowerShockwave:
      {
         if (rebuyCost >= 90.0)
         {
            debugGodPowers("   Not rebuying Shockwave since it's too expensive now.");
            return false;
         }
         break;
      }
      case cProtoPowerCarnivora:
      {
         if (rebuyCost >= 50.0)
         {
            debugGodPowers("   Not rebuying Carnivora since it's too expensive now.");
            return false;
         }
         // TODO could loop through all TC bases etc...
         int baseID = getRandomTownCenterBaseID();
         if (baseID == -1)
         {
            debugGodPowers("   Not rebuying Carnivora since we have no TC bases left.");
            return false;
         }
         vector MGP = kbBaseGetMilitaryGatherPoint(cMyID, baseID);
         if (MGP == cInvalidVector)
         {
            // No MGP defined.
            debugGodPowers("   Not rebuying Carnivora since " + kbBaseGetNameByID(cMyID, baseID) + " has no MGP defined.");
            return false;
         }
         if (getUnitCountByLocation(cUnitTypeCarnivora, cMyID, cUnitStateAlive, MGP, 15.0) > 0)
         {
            debugGodPowers("   Not rebuying Carnivora since we still have one alive at " + kbBaseGetNameByID(cMyID, baseID) + ".");
            return false;
         }
         break;
      }
      case cProtoPowerSpiderLair:
      {
         if (rebuyCost >= 30.0)
         {
            debugGodPowers("   Not rebuying Spider Lair since it's too expensive now.");
            return false;
         }
         break;
      }
      case cProtoPowerHesperidesTree:
      {
         // Only need 1.
         if (kbUnitCount(cUnitTypeHesperidesTree, cMyID, cUnitStateAlive) >= 1)
         {
            return false;
         }
         break;
      }
      case cProtoPowerVortex:
      {
         // We're not really good with this GP, so limit it on cost.
         if (rebuyCost > 100.0)
         {
            debugGodPowers("   Not rebuying Vortex since it's too expensive now.");
            return false;
         }
         break;
      }
   }
   return true;
}

//==============================================================================
// godPowerRebuyMonitor
//==============================================================================
rule godPowerRebuyMonitor
#if (cMyCulture == cCultureAtlantean)
group defaultArchaicRules
#else
group defaultMythicRules
#endif
inactive
#if (cMyCulture == cCultureAtlantean)
minInterval 30
#else
minInterval 120
#endif
{
   if (checkStrategyFlag(cStrategyFlagRebuysGodPowers) == false)
   {
      return;
   }
   
   // We want to quickly rebuy Archaic + Classical Atty GPs, afterwards we slow it all down to normal level.
   if (cMyCulture == cCultureAtlantean && kbPlayerGetAge(cMyID) >= cAge3)
   {
      xsSetRuleMinInterval("godPowerRebuyMonitor", 120);
   }
   debugGodPowers("--- Running Rule godPowerRebuyMonitor ---");

   int[] buyableGodPowers = new int(0, 0);
   for (int i = 0; i < 4; i++)
   {
      int protoPowerID = kbGodPowerGetIDInSlot(i, cMyID);
      if (protoPowerID == -1)
      {
         continue; // Needed against invalid entries + Atlanteans who activate this early on.
      }
      debugGodPowers("Analyzing slot " + i + " which contains " + kbGodPowerGetName(protoPowerID) + " to potentially rebuy.");
      // Forbid list.
      if (protoPowerID == cProtoPowerLure || protoPowerID == cProtoPowerVision || protoPowerID == cProtoPowerSpy ||
          protoPowerID == cProtoPowerGreatHunt || protoPowerID == cProtoPowerForestFire || protoPowerID == cProtoPowerValor ||
          protoPowerID == cProtoPowerGullinbursti)
      {
         debugGodPowers("   We never want to rebuy this GP.");
         continue;
      }
      float rebuyCost = kbGodPowerGetPrePurchaseCost(protoPowerID, 1, cMyID);
      if (wantToRebuyGodPower(protoPowerID, rebuyCost) == false)
      {
         continue;
      }
      // If we have used the god power 0 times we assume it will be added to the bank this or next frame still.
      if (godPowerManager.godPowerBank.find(protoPowerID) != -1 || kbGodPowerGetNumUsedTimes(protoPowerID, cMyID) == 0)
      {
         // We can hit this if we run the rebuy monitor the same frame as receiving the new god power (mostly for Atty).
         debugGodPowers("   GP is still in the god power bank, can't rebuy.");
         continue;
      }
      if (kbGodPowerIsOnCooldown(protoPowerID, cMyID) == true)
      {
         debugGodPowers("   GP is still on cooldown, can't rebuy.");
         continue;
      }
      if (kbGodPowerIsRepeatable(protoPowerID, cMyID) == false)
      {
         debugGodPowers("   GP can't be rebought at all.");
         continue;
      }
      if (kbGodPowerGetCost(protoPowerID, cMyID) == 0.0)
      {
         if (aiPlanGetIDByTypeAndVariableIntValue(cPlanGodPower, cGodPowerPlanPowerProtoID, protoPowerID, 0) == -1)
         {
            godPowerGrantedHandler(protoPowerID);
            debugGodPowers("This power still had a free charge but didn't have a plan, created one now.");
            continue;
         }
         debugGodPowers("   We still have charges on this GP, can't rebuy.");
         continue;
      }
      if (kbGodPowerCanPrePurchase(protoPowerID, cMyID) == false)
      {
         debugGodPowers("   GP can't be rebought at this moment.");
         continue;
      }
      if (rebuyCost > (-gResourceNeeds[cResourceFavor]))
      {
         debugGodPowers("   Don't have enough excess favor to buy this GP.");
         debugGodPowers("We can only rebuy a god power if we have enough favor to buy all we would potentially want, quiting.");
         return;
      }
      buyableGodPowers.add(protoPowerID);
   }

   if (buyableGodPowers.size() == 0)
   {
      debugGodPowers("Found no god powers we can rebuy this time.");
      return;
   }
   int toBuyID = buyableGodPowers[xsRandInt(0, buyableGodPowers.size() - 1)];
   debugGodPowers("Decided to buy another charge for: " + kbGodPowerGetName(toBuyID) + ".");
   aiPrePurchaseGodPower(toBuyID, 1);
   godPowerGrantedHandler(toBuyID);
}

//==============================================================================
// titanGateRebuyMonitor
//==============================================================================
rule titanGateRebuyMonitor
group defaultWonderRules
inactive
minInterval 60
{
   if (checkStrategyFlag(cStrategyFlagRebuysGodPowers) == false)
   {
      return;
   }
   debugGodPowers("--- Running Rule titanGateRebuyMonitor ---");

   if (kbGodPowerGetCost(cProtoPowerTitanGate, cMyID) == 0.0)
   {
      debugGodPowers("Titan Gate still has a charge left, can't rebuy.");
      return;
   }
   if (kbGodPowerIsOnCooldown(cProtoPowerTitanGate, cMyID) == true)
   {
      debugGodPowers("Titan Gate is still on cooldown, can't rebuy.");
      return;
   }
   if (kbGodPowerCanPrePurchase(cProtoPowerTitanGate, cMyID) == false)
   {
      debugGodPowers("Titan Gate can't be rebought at this moment.");
      return;
   }
   aiPrePurchaseGodPower(cProtoPowerTitanGate, 1);
   debugGodPowers("Buying another charge for the Titan Gate.");
   godPowerGrantedHandler(cProtoPowerTitanGate);
}

//////////////////////
int gTitanGatePlanID = -1;
int gTitanGateRepairPlanID = -1;
const int cStateBegin = 0;
const int cStateWaitingForFoundation = 1;
const int cStateFoundationPlaced = 2;
const int cStateBuilding = 3;
const int cStateDone = 4;
int gTitanGateCurrentState = cStateBegin;
int gTitanGateID = -1;
//==============================================================================
// titanGateStateChangeHandler
//==============================================================================
void titanGateStateChangeHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   switch (state)
   {
      case cPlanStateDone:
      {
         debugGodPowers("Titan Gate placement succeeded, going to build it now!");
         gTitanGatePlanID = -1;
         gTitanGateCurrentState = cStateFoundationPlaced;
         break;
      }
      case cPlanStateFailed:
      {
         debugGodPowers("Titan Gate placement failed, restarting the chain!");
         gTitanGatePlanID = -1;
         gTitanGateCurrentState = cStateBegin;
         break;
      }
   }
}

//==============================================================================
// titanGateRepairStateChangeHandler
//==============================================================================
void titanGateRepairStateChangeHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   switch (state)
   {
      case cPlanStateDone:
      {
         debugGodPowers("Titan Gate repair succeeded, we have a Titan now!");
         gTitanGateRepairPlanID = -1;
         gTitanGateCurrentState = cStateDone;
         break;
      }
      case cPlanStateFailed:
      {
         debugGodPowers("Titan Gate repair failed, titanGateConstructionMonitor will reset us soon!");
         gTitanGateRepairPlanID = -1;
         break;
      }
   }
}

//==============================================================================
// titanGateConstructionMonitor
// Place -> Construct
//==============================================================================
rule titanGateConstructionMonitor
inactive
minInterval 5
{
   debugGodPowers("--- Running Rule titanGateConstructionMonitor ---");
   switch (gTitanGateCurrentState)
   {
      case cStateBegin:
      {
         if (gTitanGatePlanID != -1)
         {
            aiEchoWarning("titanGateConstructionMonitor - in cStateBegin gTitanGatePlanID should be -1.");
            if (aiPlanGetIsIDValid(gTitanGatePlanID) == true)
            {
               aiPlanDestroy(gTitanGatePlanID);
            }
            gTitanGatePlanID = -1;
         }
         gTitanGatePlanID = aiPlanCreate("Titan Gate Placement", cPlanGodPower, -1, gBuildingsCategoryID);
         aiPlanSetVariableInt(gTitanGatePlanID, cGodPowerPlanPowerProtoID, 0, cProtoPowerTitanGate);

         aiPlanSetVariableInt(gTitanGatePlanID, cGodPowerPlanEvaluationModel, 0, cGodPowerPlanEvaluationModelNone);
         aiPlanSetVariableInt(gTitanGatePlanID, cGodPowerPlanTargetingModel, 0, cGodPowerPlanTargetingModelBuildingPlacement);
         int bpID = kbBuildingPlacementCreate(aiPlanGetName(gTitanGatePlanID) + " Titan Gate Placement");
         kbBuildingPlacementSetBuildingPUID(bpID, cUnitTypeTitanGate);
         
         addSafeBackAreasToBuildingPlacement(bpID, getMostDefendedTCBase(), true);
         // Risky cuz it can block builders but this thing is hard enough to place as it is.
         kbBuildingPlacementSetBufferSpace(bpID, 0.0);
         kbBuildingPlacementSetRequiresCompletelyUnobstructed(bpID, true);
         aiPlanSetVariableInt(gTitanGatePlanID, cGodPowerPlanBPID, 0, bpID);
         
         aiPlanSetEventHandler(gTitanGatePlanID, cPlanEventStateChange, "titanGateStateChangeHandler");
         gTitanGateCurrentState = cStateWaitingForFoundation;
         debugGodPowers("Created: " + aiPlanGetName(gTitanGatePlanID));
         break;
      }
      
      case cStateWaitingForFoundation:
      {
         debugGodPowers("Waiting for the Titan Gate foundation to be placed.");
         break;
      }

      case cStateFoundationPlaced:
      {
         if (gTitanGateRepairPlanID != -1)
         {
            aiEchoWarning("titanGateConstructionMonitor - in cStateFoundationPlaced gTitanGateRepairPlanID should be -1.");
            if (aiPlanGetIsIDValid(gTitanGateRepairPlanID) == true)
            {
               aiPlanDestroy(gTitanGateRepairPlanID);
            }
            gTitanGateRepairPlanID = -1;
         }
         // Sometimes we get here too quickly after placing the Gate and we can't see it yet, don't fail.
         static bool firstRunInFoundation = true;
         gTitanGateID = getUnit(cUnitTypeTitanGate, cMyID, cUnitStateBuilding);
         if (kbUnitGetIsIDValid(gTitanGateID) == false)
         {
            if (firstRunInFoundation == true)
            {
               firstRunInFoundation = false;
               return;
            }
            aiEchoWarning("titanGateConstructionMonitor - in cStateFoundationPlaced gTitanGateID isn't valid! Resetting " + 
               "everything and quiting.");
            gTitanGateID = -1;
            xsDisableRule("titanGateConstructionMonitor");
            return;
         }

         gTitanGateRepairPlanID = aiPlanCreate("Repair Titan Gate", cPlanRepair, -1, gBuildingsCategoryID);
         aiPlanSetVariableInt(gTitanGateRepairPlanID, cRepairPlanTargetID, 0, gTitanGateID);
         aiPlanSetPriority(gTitanGateRepairPlanID, 100); // GOOOOO.
         int unitType = cUnitTypeAbstractVillager;
         int amount = 0;
         if (cMyCulture == cCultureNorse)
         {
            unitType = cUnitTypeLogicalTypeNorseSoldierThatBuilds;
            amount = max(5, kbUnitCount(unitType, cMyID, cUnitStateAlive) / 2); // 50%.
         }
         else
         {
            amount = max(5, kbUnitCount(unitType, cMyID, cUnitStateAlive) / 5); // 20%.
         }

         aiPlanAddUnitType(gTitanGateRepairPlanID, unitType, amount, amount, amount);
         aiPlanSetBaseID(gTitanGateRepairPlanID, kbUnitGetBaseID(gTitanGateID));
         aiPlanSetEventHandler(gTitanGateRepairPlanID, cPlanEventStateChange, "titanGateRepairStateChangeHandler");

         firstRunInFoundation = true; // Reset this.
         debugGodPowers("Created: " + aiPlanGetName(gTitanGateRepairPlanID));
         gTitanGateCurrentState = cStateBuilding;
         break;
      }

      case cStateBuilding:
      {
         if (kbUnitGetIsIDValid(gTitanGateID) == false)
         {
            debugGodPowers("In cStateBuilding gTitanGateID isn't valid anymore, we must've " + 
               "lost the Gate! Resetting everything and quiting.");
            gTitanGateID = -1;
            xsDisableRule("titanGateConstructionMonitor");
            return;
         }
         debugGodPowers("Waiting for the Gate to be completed.");
         break;
      }

      case cStateDone:
      {
         debugGodPowers("Titan has been successfully unleashed, disabling now to wait for a potential next run.");
         gTitanGateID = -1;
         gTitanGateCurrentState = cStateBegin;
         xsDisableRule("titanGateConstructionMonitor");
         break;
      }
   }
}
