//==============================================================================
/* tna09_p2.xs

   Ymir (Loki)

   Controls the Titan that roams between villages and destroys them one by one.

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

int gDefendPlan = -1;

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

   // Assign my Titan (and its bodyguards) to a defend plan. The defend point will change during the mission.
   vector defendPoint = vector(105.0, 0.0, 239.0); // The first Folstag Village Town Center by default.
   gDefendPlan = createDefendPlan("Roaming Defend Plan", -1, 10.0, defendPoint, 10, defendPoint);
   aiPlanSetVariableFloat(gDefendPlan, cDefendPlanEngageRange, 0, 50.0);
   aiPlanAddUnitType(gDefendPlan, cUnitTypeLogicalTypeLandMilitary, 0, 200, 200);

   xsEnableRule("useUndermine");
   
   xsDisableRule("awaitingStartup");
}

void attackVillage(int village = 1)
{
   vector newDefendPoint = cInvalidVector;
   switch (village)
   {
      case 1:
      {
         newDefendPoint = vector(104.35, 4.00, 229.90);
         break;
      }
      case 2:
      {
         newDefendPoint = vector(190.34, 4.01, 262.82);
         break;
      }
      case 3:
      {
         newDefendPoint = vector(217.30, 4.00, 201.40);
         break;
      }
      case 4:
      {
         newDefendPoint = vector(132.92, 4.00, 142.82);
         break;
      }
      case 5:
      {
         newDefendPoint = vector(105.09, 4.00, 36.68);
         break;
      }
      case 6:
      {
         newDefendPoint = vector(193.05, 4.00, 75.20);
         break;
      }
   }
   debugAttackWave("We're attacking Village " + village + " now!");
   aiPlanSetVariableVector(gDefendPlan, cDefendPlanTargetPoint, 0, newDefendPoint);
   aiPlanSetVariableVector(gDefendPlan, cDefendPlanGatherPoint, 0, newDefendPoint);
   return;
}

// See if we can find some player walls and crumble them!
rule useUndermine
inactive
minInterval 5
{
   int titanID = -1;
   int numWalls = -1;
   int targetID = -1;
   // Get our Titan.
   titanID = getUnit(cUnitTypeTitanYmir);
   if (titanID >= 0)
   {
      // Look for walls.
      numWalls = getUnitCountByLocation(cUnitTypeAbstractWall, 1, cUnitStateAlive, kbUnitGetPosition(titanID), 15.0);
      debugAttackWave("numWalls near our Titan: " + numWalls);
      if (numWalls >= 5)
      {
         // Grab an enemy wall.
         targetID = getUnitByLocation(cUnitTypeAbstractWall, 1, cUnitStateAlive, kbUnitGetPosition(titanID), 15.0);
         if (targetID >= 0)
         {
            // Invoke god power!
            if (aiCastGodPowerAtDualPosition(cProtoPowerUndermine, kbUnitGetPosition(titanID), kbUnitGetPosition(targetID)) == true)
            {
               debugAttackWave("Casted Undermine!");
               xsDisableRule("useUndermine");
               return;
            }
         }
      }
   }
}