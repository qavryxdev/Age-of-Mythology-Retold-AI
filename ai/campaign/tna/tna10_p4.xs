//==============================================================================
/* tna10_p4.xs

   Prometheus (Oranos)

   Tightly Scripted AI. They patrol between four points of the map, keeping a small posse of Prometheans
   with their main Titan. Every now and theyn, they launch attacks with their Promethean guards.

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

int gTitanDefendPlan = -1;
int gBodyguardPlan = -1;

vector gDefendPoint = vector(194.0, 0.0, 118.0); // Starts at the top settlement.
vector gPlayersTC = vector(58.0, 0.0, 279.0); // Player's Town Center in the west.
vector gAlliedTC = vector(200.0, 0.0, 247.0); // Allied town center in the north.

float gAttackStartDelay = 360; // In seconds.
float gAttackWaveInterval = 300; // In seconds.
float gAttackStartSize = 2;
float gAttackMaxSize = 4;

float gNextAttackTime = 0.0;
float gCurrentAttackSize = 0.0;

//==============================================================================
/*	preInit()

   This function is called in main() before any of the normal initialization
   happens. Use it to override default values of variables as needed for
   scenario effects.
*/
//==============================================================================
void preInit()
{
   gAttackStartDelay *= gDifficultyModifierFirstAttack;
   gAttackWaveInterval *= gDifficultyModifierAttackInterval;

   // Attack size multipliers are applied twice.
   gAttackStartSize *= (gDifficultyModifierAttackSizes * gDifficultyModifierAttackSizes);
   gAttackMaxSize *= (gDifficultyModifierAttackSizes * gDifficultyModifierAttackSizes);
   gCurrentAttackSize = gAttackStartSize;

   xsEnableRule("awaitingStartup");
   // This is a custom script that still wants everything included from the base AI so it can use it, but go inactive.
   debugAttackWave("This AI will go inactive as far as the main AI complex is concerned, but we will run custom logic anyway.");
   gInactiveAI = true;
}

//==============================================================================
// awaitingStartup
// Wait until "gStartInactive" becomes 'false', which is the case when using our designated AI activation triggers.
// That will activate us.
//==============================================================================
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

   // Assign my Titan to a defend plan. The defend point will change during the mission.
   gTitanDefendPlan = createDefendPlan("Titan Defend Plan", -1, 10.0, gDefendPoint, 10, gDefendPoint);
   aiPlanSetVariableFloat(gTitanDefendPlan, cDefendPlanEngageRange, 0, 20.0);
   aiPlanAddUnitType(gTitanDefendPlan, cUnitTypeTitanPrometheus, 1, 1, 1);

   // Assign the Titan's followers to follow the Titan around, no matter where it is.
   // (Also starts by the first village TC by default, which changes quickly).
   gBodyguardPlan = createDefendPlan("Bodyguard Defend Plan", -1, 20.0, gDefendPoint, 10, gDefendPoint);
   aiPlanSetVariableFloat(gBodyguardPlan, cDefendPlanEngageRange, 0, 50.0);
   aiPlanAddUnitType(gBodyguardPlan, cUnitTypePromethean, 0, 200, 200);
   aiPlanAddUnitType(gBodyguardPlan, cUnitTypePrometheanOffspring, 0, 200, 200);

   gNextAttackTime = gAttackStartDelay + xsGetTime();

   debugAttackWave("First Attack wanted size: " + xsFloatToInt(gAttackStartSize));
   debugAttackWave("First Attack max size: " + xsFloatToInt(gAttackMaxSize));
   debugAttackWave("First Attack time: " + turnNumberIntoTimeDisplay(gNextAttackTime));

   xsEnableRule("attackGenerator");
   xsSetRuleMinInterval("attackGenerator", gNextAttackTime - xsGetTime()); // This makes it fire at the intended time.
   xsEnableRule("updateBodyguardDefendPoint");
   xsEnableRule("rotateDefendPoint");
   
   xsDisableRule("awaitingStartup");
}

//==============================================================================
// createAttackPlan
// topBase indicates if we're attacking the base that is normally owned by our allies.
// If this is true we need to do create slightly different paths.
//==============================================================================
void createAttackPlan(int targetBaseID = -1, bool topBase = false)
{
   // Prevent creating duplicate attack route names, use a number to increment.
   static int attackRouteCounter = 1;
   int routeID = kbCreateAttackRouteWithPath("Route To P1 number " + attackRouteCounter, gDefendPoint, gPlayersTC);
   attackRouteCounter++;

   static int pathCounter = 1;
   int pathID1 = kbPathCreate(pathCounter + " Path 1 to P1 number " + pathCounter);  // Approaching from the east, but taking the upper path.
   kbPathAddWaypoint(pathID1, gDefendPoint);
   if (topBase == true)
   {
      kbPathAddWaypoint(pathID1, vector(215.0, 0.0, 135.0));
      kbPathAddWaypoint(pathID1, gAlliedTC);
   }
   else
   {
      kbPathAddWaypoint(pathID1, vector(92.0, 0.0, 175.0));
      kbPathAddWaypoint(pathID1, gPlayersTC);
   }
   kbAttackRouteAddPath(routeID, pathID1);
   pathCounter++;

   // Approaching from the east, but taking the lower path. OR approaching from the south.
   int pathID2 = kbPathCreate("Path 2 to P1 number " + pathCounter);
   kbPathAddWaypoint(pathID2, gDefendPoint);
   if (topBase == true)
   {
      kbPathAddWaypoint(pathID2, vector(92.0, 0.0, 175.0));
      kbPathAddWaypoint(pathID2, vector(102.0, 0.0, 268.0));
      kbPathAddWaypoint(pathID2, gAlliedTC);
   }
   else
   {
      kbPathAddWaypoint(pathID2, vector(56.0, 0.0, 161.0));
      kbPathAddWaypoint(pathID2, gPlayersTC);
   }
   kbAttackRouteAddPath(routeID, pathID2);
   pathCounter++;

   int planID = aiPlanCreate("Promethean Attack Wave", cPlanAttack);
   aiPlanSetVariableInt(planID, cAttackPlanTargetMode, 0, cAttackPlanTargetModeBase);
   aiPlanSetVariableInt(planID, cAttackPlanTargetBaseID, 0, targetBaseID);
   aiPlanSetVariableInt(planID, cAttackPlanTargetPlayerID, 0, 1);
   aiPlanSetVariableVector(planID, cAttackPlanGatherPoint, 0, gDefendPoint);
   aiPlanSetVariableInt(planID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
   aiPlanSetVariableInt(planID, cAttackPlanAttackRouteID, 0, routeID);
   aiPlanSetVariableInt(planID, cAttackPlanTargetUnitTypes, 0, cUnitTypeLogicalTypeHandUnitsAttack); // We can't attack ranged.

   // We want our units to clump up before sending out the attack.
   // We try to group everybody to within 15 range from the gather point. (after that the move command clumps them properly)
   // If all the units haven't reached this spot after 60 seconds we go ahead anyway.
   aiPlanSetVariableFloat(planID, cAttackPlanGatherDistance, 0, 15.0);
   aiPlanSetVariableBool(planID, cAttackPlanGatherWaitForAllUnits, 0, true);
   aiPlanSetVariableInt(planID, cAttackPlanGatherWaitTime, 0, 60000);

   // Don't search for more bases, just kill that specific TC.
   aiPlanSetVariableInt(planID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeBaseGone);
   aiPlanSetPriority(planID, 99);
   // Don't reduce this attack's size while underway.
   aiPlanSetFlag(planID, cPlanFlagCantBeStolenFrom, true);

   // Use a number of Prometheans equal to our desired attack size... but use every offspring we can find!
   aiPlanAddUnitType(planID, cUnitTypePromethean, 0, gCurrentAttackSize, gCurrentAttackSize, false);
   aiPlanAddUnitType(planID, cUnitTypePrometheanOffspring, 0, 200, 200, false);
   int[] units = aiPlanGetUnits(gBodyguardPlan, cUnitTypePromethean, true);
   if (units.size() < gCurrentAttackSize)
   {
      debugAttackWave("We just checked that we had enough Prometheans in the bodyguard plan, but now we don't have enough?!");
      return;
   }
   for (int i = 0; i < gCurrentAttackSize; i++)
   {
      aiPlanAddUnit(planID, units[i]);
   }
   units = aiPlanGetUnits(gBodyguardPlan, cUnitTypePrometheanOffspring, true);
   for (int i = 0; i < units.size(); i++)
   {
      aiPlanAddUnit(planID, units[i]);
   }

   debugAttackWave("Launching an attack on player " + 1 + ", base: " + kbBaseGetNameByID(1, targetBaseID) + ", using plan " +
      aiPlanGetName(planID) + ".");
}

//==============================================================================
// attackGenerator
// Generate attacks after attack intervals.
//==============================================================================
rule attackGenerator
inactive
minInterval 10 // Dummy, changed dynamically.
{
   int numAvailablePrometheans = aiPlanGetNumberUnits(gBodyguardPlan, cUnitTypePromethean, true);
   if (numAvailablePrometheans < xsFloatToInt(gCurrentAttackSize))
   {
      debugAttackWave("We don't have enough Prometheans for this attack: " + numAvailablePrometheans + "/" +
         xsFloatToInt(gCurrentAttackSize) + ".");
      debugAttackWave("Trying again at: " + turnNumberIntoTimeDisplay(xsGetTime() + 10));
      xsSetRuleMinInterval("attackGenerator", 10); // Try every 10 seconds.
      return;
   }

   int baseID = kbFindClosestBase(1, -1, gPlayersTC);
   if (baseID == -1)
   {
      debugAttackWave("We couldn't find a base near our target point to attack.");
      debugAttackWave("Trying again at: " + turnNumberIntoTimeDisplay(xsGetTime() + 10));
      xsSetRuleMinInterval("attackGenerator", 10); // Try every 10 seconds.
      return;
   }

   bool topBase = false;
   if (xsVectorDistanceXZ(gPlayersTC, kbBaseGetLocation(1, baseID)) > 60.0)
   {
      debugAttackWave("We found an enemy base, it just wasn't close enough to our original target point. Seeing if the player took over " +
         " our ally now.");
      // Shift our scan point towards our allied TC's base, in case the player has taken that over.
      baseID = kbFindClosestBase(1, -1, gAlliedTC);
      if (xsVectorDistanceXZ(gAlliedTC, kbBaseGetLocation(1, baseID)) > 60.0)
      {
         debugAttackWave("Also couldn't find an enemy base near our allied TC.");
         debugAttackWave("Trying again at: " + turnNumberIntoTimeDisplay(xsGetTime() + 10));
         xsSetRuleMinInterval("attackGenerator", 10); // Try every 10 seconds.
         return;
      }
      topBase = true;
   }

   createAttackPlan(baseID, topBase);

   gCurrentAttackSize *= gDifficultyModifierAttackSizeMultiplier;
   gCurrentAttackSize = min(gCurrentAttackSize, gAttackMaxSize); // Cap it.
   gNextAttackTime += gAttackWaveInterval;
   xsSetRuleMinInterval("attackGenerator", gAttackWaveInterval);

   debugAttackWave("New wanted attack size: " + xsFloatToInt(gCurrentAttackSize));
   debugAttackWave("New Wanted max size: " + xsFloatToInt(gAttackMaxSize));
   debugAttackWave("New attack time: " + turnNumberIntoTimeDisplay(gNextAttackTime));
}

//==============================================================================
// updateBodyguardDefendPoint
// Refresh the bodyguard plan's points to where the Titan is at.
//==============================================================================
rule updateBodyguardDefendPoint
inactive
minInterval 7
{
   int titanID = getUnit(cUnitTypeTitanPrometheus);
   if (titanID >= 0)
   {
      // If we're fighting, don't run after the Titan but instead finishing fighting before catching up to him.
      if (aiPlanGetState(gBodyguardPlan) != cPlanStateAttack)
      {
         vector titanLocation = kbUnitGetPosition(titanID);
         aiPlanSetVariableVector(gBodyguardPlan, cDefendPlanTargetPoint, 0, titanLocation);
         aiPlanSetVariableVector(gBodyguardPlan, cDefendPlanGatherPoint, 0, titanLocation);
      }
   }
   else
   {
      // Without a Titan these rules are obsolete.
      xsDisableRule("updateBodyguardDefendPoint");
      xsDisableRule("rotateDefendPoint");
   }
}

//==============================================================================
// rotateDefendPoint
// Rotate the Titan + Prometheans along the map.
//==============================================================================
rule rotateDefendPoint
inactive
minInterval 60
{
   // We can't move the defend plans if we're in attack state. Since that would mess up our point from which we scan for enemies
   // and cause us to start moving away while in combat seemingly randomly.
   if (aiPlanGetState(gBodyguardPlan) == cPlanStateAttack || aiPlanGetState(gTitanDefendPlan) == cPlanStateAttack)
   {
      debugAttackWave("Either of our 2 defend plans is in combat, we can't move them around now, try again in 10 seconds.");
      xsSetRuleMinInterval("rotateDefendPoint", 10); // Try every 10 seconds.
      return;
   }

   xsSetRuleMinInterval("rotateDefendPoint", 60); // Reset interval.
   static int waypoint = 0; // Starts at the top settlement.

   // Increment or reset the waypoint index.
   waypoint++;
   waypoint %= 4;

   // These vectors aren't precisely on the Town Center since that's bad for pathing (can't reach the spot obviously).
   switch (waypoint)
   {
      case 0:
      {
         gDefendPoint = vector(140.0, 0.0, 48.0); // Right settlement.
         debugAttackWave("Next defend waypoint: Right Settlement.");
         break;
      }
      case 1:
      {
         gDefendPoint = vector(194.0, 0.0, 118.0); // Top settlement.
         debugAttackWave("Next defend waypoint: Top Settlement.");
         break;
      }
      case 2:
      {
         gDefendPoint = vector(107.0, 0.0, 133.0); // Left settlement.
         debugAttackWave("Next defend waypoint: Left Settlement.");
         break;
      }
      case 3:
      {
         gDefendPoint = vector(52.0, 0.0, 40.0); // Bottom settlement.
         debugAttackWave("Next defend waypoint: Bottom Settlement.");
         break;
      }
   }

   aiPlanSetVariableVector(gTitanDefendPlan, cDefendPlanTargetPoint, 0, gDefendPoint);
   aiPlanSetVariableVector(gTitanDefendPlan, cDefendPlanGatherPoint, 0, gDefendPoint);
}