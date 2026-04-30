//==============================================================================
/* tna07_p4.xs

   Army of Melagius (Zeus)

   Tightly scripted AI that grabs all of its units when called by attack().

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

   vector startPoint = vector(474.0, 0.0, 207.0); // Start Point.
   vector targetPoint = vector(46.0, 0.0, 136.0); // Kastor's Starting Area.

   int routeID = kbCreateAttackRouteWithPath("Route To P1", startPoint, targetPoint);
   int pathID1 = kbPathCreate("Path 1 to P1");  // Far Left Path.
   kbPathAddWaypoint(pathID1, startPoint);
   kbPathAddWaypoint(pathID1, vector(381.0, 0.0, 265.0)); // Block #1.
   kbPathAddWaypoint(pathID1, vector(326.0, 0.0, 295.0)); // Block #2.
   kbPathAddWaypoint(pathID1, vector(240.0, 0.0, 280.0)); // Block #3.
   kbPathAddWaypoint(pathID1, vector(178.0, 0.0, 325.0)); // Block #4.
   kbPathAddWaypoint(pathID1, vector(141.0, 0.0, 230.0)); // Block #5.
   kbPathAddWaypoint(pathID1, vector(130.0, 0.0, 188.0)); // Block #6.
   kbPathAddWaypoint(pathID1, targetPoint);
   kbAttackRouteAddPath(routeID, pathID1);

   int pathID2 = kbPathCreate("Path 2 to P1");  // Middle Left Path.
   kbPathAddWaypoint(pathID2, startPoint);
   kbPathAddWaypoint(pathID2, vector(381.0, 0.0, 265.0)); // Block #1.
   kbPathAddWaypoint(pathID2, vector(216.0, 0.0, 220.0)); // Block #2.
   kbPathAddWaypoint(pathID2, targetPoint);
   kbAttackRouteAddPath(routeID, pathID2);

   int pathID3 = kbPathCreate("Path 3 to P1");  // Middle Right Path.
   kbPathAddWaypoint(pathID3, startPoint);
   kbPathAddWaypoint(pathID3, vector(62.0, 0.0, 228.0)); // Block #1.
   kbPathAddWaypoint(pathID3, vector(220.0, 0.0, 178.0)); // Block #2.
   kbPathAddWaypoint(pathID3, targetPoint);
   kbAttackRouteAddPath(routeID, pathID3);

   int pathID4 = kbPathCreate("Path 4 to P1");  // Far Right Path.
   kbPathAddWaypoint(pathID4, startPoint);
   kbPathAddWaypoint(pathID4, vector(62.0, 0.0, 228.0)); // Block #1.
   kbPathAddWaypoint(pathID4, vector(186.0, 0.0, 112.0)); // Block #2.
   kbPathAddWaypoint(pathID4, vector(134.0, 0.0, 65.0)); // Block #3.
   kbPathAddWaypoint(pathID4, targetPoint);
   kbAttackRouteAddPath(routeID, pathID4);

   int attackPlanID = aiPlanCreate("Giant attack wave!", cPlanAttack);
   aiPlanAddUnitType(attackPlanID, cUnitTypeLogicalTypeLandMilitary, 2, 10, 16, false);
   aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetMode, 0, cAttackPlanTargetModePoint);
   aiPlanSetVariableInt(attackPlanID, cAttackPlanTargetPlayerID, 0, 1); // Attack Player 1!
   aiPlanSetVariableVector(attackPlanID, cAttackPlanTargetPoint, 0, targetPoint);
   aiPlanSetVariableVector(attackPlanID, cAttackPlanGatherPoint, 0, startPoint);
   aiPlanSetVariableFloat(attackPlanID, cAttackPlanGatherDistance, 0, 20.0);
   aiPlanSetVariableFloat(attackPlanID, cAttackPlanAttackModeEngageRange, 0, 25.0);
   aiPlanSetVariableInt(attackPlanID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
   aiPlanSetVariableInt(attackPlanID, cAttackPlanAttackRouteID, 0, routeID);
   setDefaultAttackPlanTargetUnitTypes(attackPlanID);

   aiPlanSetVariableInt(attackPlanID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeNoTarget);
   aiPlanSetPriority(attackPlanID, 90); // Very high priority. Use plenty of units.

   return;
}

// *** RULE - awaitingStartup ***
// Wait until "gStartInactive" becomes 'false', which is the case when using our designated AI activation triggers.
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