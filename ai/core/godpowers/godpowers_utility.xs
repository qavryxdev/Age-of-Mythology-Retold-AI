//==============================================================================
/* godpowers_utility.xs

   This file contains all helper functions for god powers.

*/
//==============================================================================

extern const int cGPStateBegin = 0;
extern const int cGPStatePathingToLocation = 1;
extern const int cGPStateCleanup = 2;
//==============================================================================
// godPowerExploreTargetPosition
//==============================================================================
bool godPowerExploreTargetPosition(int gpPlanID = -1, int scoutID = -1, int targetID = -1, int iterator = 0, int reservePlanID = -1,
   ref bool castGodPower)
{
   if (kbUnitGetIsIDValid(scoutID) == false || kbUnitGetIsIDValid(targetID) == false)
   {
      debugGodPowers("godPowerExploreTargetPosition - Our scout/target died, can't path anymore - " + aiPlanGetName(gpPlanID));
      return false;
   }
   if (kbUnitGetPlanID(scoutID) != reservePlanID)
   {
      aiPlanAddUnitType(reservePlanID, kbUnitGetProtoUnitID(scoutID), 1, 1, 1);
      aiPlanAddUnit(reservePlanID, scoutID, true);
   }

   // If this target is already visible, just cast!
   if (kbLocationVisible(kbUnitGetPosition(targetID)) == true)
   {
      debugGodPowers("godPowerExploreTargetPosition - target unit is visible, casting God Power now.");
      aiPlanSetVariableVector(gpPlanID, cGodPowerPlanTargetLocation, 0, kbUnitGetPosition(targetID));
      aiPlanSetVariableBool(gpPlanID, cGodPowerPlanAutoCast, 0, true);
      castGodPower = true;
      return false;
   }

   // We need to walk towards the TC.
   // Dont send too many move commands or the pather gets confused.
   if (iterator % 5 == 0)
   {
      debugGodPowers("godPowerExploreTargetPosition - tasked our scout again - " + aiPlanGetName(gpPlanID));
      aiTaskMoveUnit(scoutID, kbUnitGetPosition(targetID));
   }
   return true;
}

//==============================================================================
// godPowerFindTCInRangeAndScout
//==============================================================================
bool godPowerFindTCInRangeAndScout(int gpPlanID = -1, ref int scoutID, ref int targetID, ref bool castGodPower)
{
   int[] plans = aiPlanGetIDsByTypeAndState(cPlanAttack, cPlanStateAttack);
   for (int i = 0; i < plans.size(); i++)
   {
      if (aiPlanGetParentID(plans[i]) == -1) // Parent plan, no reinforcement.
      {
         targetID = getClosestUnitByLocation(cUnitTypeAbstractSocketedTownCenter, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
                       aiPlanGetLocation(plans[i]), aiPlanGetVariableFloat(plans[i], cAttackPlanAttackModeEngageRange, 0) + 30.0);
         if (kbUnitGetIsIDValid(targetID) == true)
         {
            if (kbLocationVisible(kbUnitGetPosition(targetID)) == true)
            {
               debugGodPowers("Found TC: " + targetID + " for plan: " + aiPlanGetName(plans[i]) + ", and it's already visible! " + 
                  "Instantly casting god power for " + aiPlanGetName(gpPlanID) + ".");
               aiPlanSetVariableVector(gpPlanID, cGodPowerPlanTargetLocation, 0, kbUnitGetPosition(targetID));
               aiPlanSetVariableBool(gpPlanID, cGodPowerPlanAutoCast, 0, true);
               castGodPower = true;
               return false;
            }

            debugGodPowers("Found TC: " + targetID + " for plan: " + aiPlanGetName(plans[i]));

            // Make sure they're on the same area group.
            int ownAreaGroupID = kbAreaGroupGetIDByPosition(aiPlanGetLocation(plans[i], true));
            int tcAreaID = kbAreaGroupGetIDByPosition(kbUnitGetPosition(targetID));
            if (kbAreaGetGroupID(ownAreaGroupID) != kbAreaGetGroupID(tcAreaID))
            {
               debugGodPowers("TC is not on the same land mass as we are.");
               continue;
            }

            // Make sure we don't take a base that has just been conquered by the enemy.
            if (getUnitCountByLocation(cUnitTypeBuilding, cPlayerRelationAlly, cUnitStateABQ, kbUnitGetPosition(targetID), 40.0) > 5)
            {
               debugGodPowers("TC is in an allied base, don't target it.");
               continue;
            }

            // Find the best unit to scout with.
            scoutID = -1; // Reset so we know if we found a new scout yes or no.
            int[] planUnits = aiPlanGetUnits(plans[i]);
            float fastestSpeed = 0.0;
            for (int j = 0; j < planUnits.size(); j++)
            {
               float speed = kbUnitGetStatFloat(planUnits[j], cUnitStatMaxVelocity);
               // Fast unit that isn't heavily damaged, so we have a higher chance of successfully reaching the TC.
               if (speed > fastestSpeed &&
                   kbUnitGetStatFloat(planUnits[j], cUnitStatCurrHP) > (kbUnitGetStatFloat(planUnits[j], cUnitStatMaxHP) * 0.7) &&
                   // Guard against midway transport plans.
                   kbAreaGroupGetIDByPosition(kbUnitGetPosition(planUnits[j])) == tcAreaID)
               {
                  fastestSpeed = speed;
                  scoutID = planUnits[j];
               }
            }

            // Could be that we found no unit, continue then.
            if (scoutID == -1)
            {
               debugGodPowers("Couldn't find a suitable scouting unit, skipping.");
               continue;
            }

            debugGodPowers("TC is valid to send a scout (" + scoutID + ") to for this plan: " + aiPlanGetName(plans[i]) + ".");
            return true;
         }
         else
         {
            debugGodPowers("We didn't find enough close enemy Town Centers to move some units forward to " + 
               "for this plan: " + aiPlanGetName(plans[i]) + ".");
         }
      }
   }
   return false;
}