//==============================================================================
/* fott22_p6.xs

   Fenris Wolves (Loki)

   Tightly scripted AI that grabs all of its Fenris Wolf Broods when called by attack().

*/
//==============================================================================
// Includes

include "core\main.xs"; // The bulk of the AI.
include "campaign\global_spc_modifiers.xs"; // global modifiers for difficulties.

//==============================================================================
/*	Rules

   Add scenario-specific rules & functions in the section below.
*/
//==============================================================================


//==============================================================================
/*	preInit()

   This function is called in main() before any of the normal initialization
   happens. Use it to override default values of variables as needed for
   scenario effects.
*/
//==============================================================================
void preInit()
{
   xsEnableRule("awaitingStartup");
   gInactiveAI = true;
}

//==============================================================================
/*	postInit()

   This function is called in main() after the normal initialization is
   complete. Use it to override settings and decisions made by the startup logic.
*/
//==============================================================================
void postInit() {}

void attack()
{
   debugAttackWave("We've been ordered to attack! Let's go!");

   vector startPoint = vector(407.0, 0.0, 69.0); // Spawn point, at the den.
   vector targetPoint = vector(175.0, 0.0, 123.0); // Amanra Settlement, the last one in their path.

   int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
   int pathID1 = kbPathCreate("Path 1 to P1");  // Passes by all unused Settlements that Arkantos can claim at the start.
   kbPathAddWaypoint(pathID1, startPoint);
   kbPathAddWaypoint(pathID1, vector(351.0, 0.0, 109.0)); // Block #1, Settlement near the den. 
   kbPathAddWaypoint(pathID1, vector(288.0, 0.0, 211.0)); // Block #2, Settlement near Ajax.
   kbPathAddWaypoint(pathID1, vector(211.0, 0.0, 265.0)); // Block #3, Settlement near Arkantos.
   kbPathAddWaypoint(pathID1, targetPoint);
   kbAttackRouteAddPath(routeID, pathID1);

   int attackPlanID = aiPlanCreate("Massive attack wave!", cPlanAttack);
   aiPlanAddUnitType(attackPlanID, cUnitTypeMythUnit, 0, 200, 200, false);
   int targetBaseID = kbFindClosestBase(1, -1, startPoint);
   if (targetBaseID == -1)
   {
      debugAttackWave("We couldn't find a base to attack.");
      aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetMode, 0, cAttackPlanTargetModePoint);
      aiPlanSetVariableVector(attackPlanID, cAttackPlanTargetPoint, 0, targetPoint);
   }
   else
   {
      debugAttackWave("Found a base to attack.");
      aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetMode, 0, cAttackPlanTargetModeBase);
      aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetBaseID, 0, targetBaseID);
   }
   aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetPlayerID, 0, 1); // Attack Player 1!
   aiPlanSetVariableVector(attackPlanID, cAttackPlanGatherPoint, 0, startPoint);
   aiPlanSetVariableFloat(attackPlanID, cAttackPlanGatherDistance, 0, 40.0);
   aiPlanSetVariableFloat(attackPlanID, cAttackPlanAttackModeEngageRange, 0, 50.0);
   aiPlanSetVariableInt(attackPlanID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
   aiPlanSetVariableInt(attackPlanID, cAttackPlanAttackRouteID, 0, routeID);
   setDefaultAttackPlanTargetUnitTypes(attackPlanID);

   aiPlanSetVariableInt(attackPlanID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeNoTarget);
   aiPlanSetPriority(attackPlanID, 90); // Very high priority. Use plenty of units.

   return;
}

// *** RULE - awaitingStartup ***
// Wait until "gStartInactive" becomes 'false', is the case when using our designated AI activation triggers.
// That will activate us.
rule awaitingStartup
inactive
minInterval 5
{
   // Keep cancelling if the AI is not yet activated.
   if (gStartInactive == true)
   {
      return;
   }

   // Once it is activated...
   debugAttackWave("*** I AM ACTIVATED ***");
   
   xsDisableRule("awaitingStartup");
}