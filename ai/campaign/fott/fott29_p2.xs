//==============================================================================
/* fott29_p2.xs

   Gargarensis (Loki)

   Red Norse player that receives units for free in the form of Armies.
   Two Armies are used, trying to capture one half of Thor's hammer each.

   Once having captured either piece, the AI will pull units from the appropriate raider army to guard said piece, up
   to a customizable limit.

   The AI keeps track of how many units keep getting added into their respective Armies and how many of said Army units have
   already been assigned to defend a piece, to keep reinforcing from their limited pool of Army units.

   The AI can only process up to 50 Army units, so it counts on existing Army units to be cleared at some point so that it can
   assign units with a clean slate.

   TODO: The code can be improved in this script, by turning the two big rules handling unit assignment for each Army into a function
   and keep smaller rules around to trigger unit assigning (unless the AI requirements change into something less clunky).
   Currently, capturedHead and capturedHaft do the essentially the same thing.

   TODO: Make the Boulder Army's query for the Hammer Haft work. Currently, they find the wrong unit.

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

// Values that can be edited for balance/setup purposes:
string gArmyNameHaft = "Gargarensis Haft Raiders";
int gDefendSizeHaft = 50;     // How many Haft Raiders are allowed to defend the Hammer Haft at a time.
vector gHaftStorage = vector(47.0, 0.0, 246.0);    // In the far west.

string gArmyNameHead = "Gargarensis Head Raiders";
int gDefendSizeHead = 50;     // How many Head Raiders are allowed to defend the Hammer Head at a time.
vector gHeadStorage = vector(241.0, 0.0, 194.0);   // In the far north.

string gArmyNameBoulder = "Boulder Army";

// Global variables for functions and rules, not to be edited.
int gDefendHeadID = -1;
vector gDefendHeadPoint = cInvalidVector;
int gDefendHaftID = -1;
vector gDefendHaftPoint = cInvalidVector;
int gBoulderArmyDefendID = -1;


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

// *** FUNCTION - activateBoulderArmy ***
// Called by a trigger when the Boulder Army should move to defend the Hammer Haft.
void activateBoulderArmy()
{
   debugAttackWave("*** BOULDER ARMY ACTIVATED ***");
   xsEnableRule("boulderArmyAssign");
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

   debugAttackWave("*** I AM ACTIVATED ***");
   xsEnableRule("capturedHead");
   xsEnableRule("capturedHaft");
   xsDisableRule("awaitingStartup");
}

// *** RULE - capturedHead ***
// When the Thor Hammer Head has been captured, keep units defending it.
rule capturedHead
inactive
minInterval 10
{
   static int accountedUnitsHead = 0;
   static int assignedUnitsHead = 0;
   // Keep track of how many units are in our Army.
   int armyID = kbArmyGetID(gArmyNameHead);
   int armyCount = kbArmyGetNumberUnits(armyID);
   debugAttackWave("We have " + armyCount + " Head Raiders accounted for (dead or alive).");

   // If our Army size suddenly becomes smaller than the units we have taken into account, that means a new Army was spawned
   // that cleared existing units! When that happens, reset the count of assigned units.
   if (accountedUnitsHead > armyCount)
   {
      // Reset the count on how many units we have assigned in our Army, since this is a brand new Army!
      assignedUnitsHead = 0;
      accountedUnitsHead = armyCount;
      debugAttackWave("Resetting Head Raider ASSIGNED list! We're working with a CLEAN SLATE Army now!");
   }
   else if (accountedUnitsHead <= armyCount)
   {
      // Keep incrementing our accounted units as the member count steadily increases...
      accountedUnitsHead = armyCount;
   }

   // If we don't have the Head anymore, cancel (and end our defend plan, if we have an active one).
   if (kbUnitCount(cUnitTypeThorHammerHead, cMyID) < 1)
   {
      if (gDefendHeadID >= 0)
      {
         aiPlanDestroy(gDefendHeadID);
         gDefendHeadID = -1;
         debugAttackWave("We lost the Hammer Head. Ending defend plan.");
      }
      return;
   }

   // If we have the Head, get the location of it.
   debugAttackWave("We possess the Hammer Head!");
   int head = getUnit(cUnitTypeThorHammerHead);
   if (head == -1)
   {
      return;
   }

   // Move the Head to it's storage zone.
   aiTaskMoveUnit(head, gHeadStorage);

   // If we have an active defend plan, make sure the defending units follow the Head as it can move around.
   vector headPos = kbUnitGetPosition(head);
   if (gDefendHeadPoint != headPos && gDefendHeadID >= 0)
   {
      aiPlanSetVariableVector(gDefendHeadID, cDefendPlanTargetPoint, 0, headPos);
      aiPlanSetVariableVector(gDefendHeadID, cDefendPlanGatherPoint, 0, headPos);
   }
   gDefendHeadPoint = headPos;

   // If we don't have an active defend plan, create it.
   if (gDefendHeadID < 0)
   {
      debugAttackWave("We don't have an active defend plan for the Hammer Head anymore. Quick, make a new one!");
      gDefendHeadID = createDefendPlan("Guard Hammer Head", -1, 25.0, gDefendHeadPoint, 10, gDefendHeadPoint);
      aiPlanSetVariableFloat(gDefendHeadID, cDefendPlanEngageRange, 0, 30.0);
   }

   // If all of our members are already assigned, no sense in taking further action with them.
   if (assignedUnitsHead >= armyCount)
   {
      debugAttackWave("All of our Head Raiders are occupied (or dead), we've got no more free units to use.");
      return;
   }

   // If we have fewer defenders in our plan than desired, start grabbing new, unassigned members from the Army.
   int defendCount = aiPlanGetNumberUnits(gDefendHeadID);
   if (defendCount < gDefendSizeHead)
   {
      // Disallow the main AI to add new units after a short period of time.
      xsEnableRule("planNoMoreUnitsHead");

      // Establish how many empty slots in the plan we have to fill.
      int emptySlots = gDefendSizeHead - defendCount;
      debugAttackWave("We have " + defendCount + "/" + gDefendSizeHead + " Head defenders. We need to add " + emptySlots + " new units to our Head defense!");

      // Check all the units in our army.
      for (int i = 0; i < armyCount; i++)
      {
         // Early member indexes belong to already assigned units. These may be dead, or already belong to the defend plan. Ignore them.
         if (i < assignedUnitsHead)
         {
            continue;
         }

         // Pick the unit index from the army and put it into the plan.
         int unitID = kbArmyGetUnitID(armyID, i);
         int protoID = kbUnitGetProtoUnitID(unitID);
         aiPlanAddUnitType(gDefendHeadID, protoID, 1, 1, 1, false);
         aiPlanAddUnit(gDefendHeadID, unitID);

         // Increment how many Head Army members we have assigned in total.
         assignedUnitsHead++;

         // Decrement the number of available slots in the plan.
         emptySlots--;

         // If we run out of defend plan slots, stop assigning units.
         if (emptySlots <= 0)
         {
            break;
         }
      }
   }
}

// *** RULE - planNoMoreUnitsHead ***
// A few seconds after assigning new units to the Hammer Head defense plan, disallow additional units from being added to the plan.
rule planNoMoreUnitsHead
inactive
minInterval 5
{
   aiPlanSetFlag(gDefendHeadID, cPlanFlagNoMoreUnits, true);
   xsDisableRule("planNoMoreUnitsHead");
   return;
}

// *** RULE - capturedHaft ***
// When the Thor Hammer Haft has been captured, keep units defending it.
rule capturedHaft
inactive
minInterval 10
{
   static int accountedUnitsHaft = 0;
   static int assignedUnitsHaft = 0;
   // Keep track of how many units are in our Army.
   int armyID = kbArmyGetID(gArmyNameHaft);
   int armyCount = kbArmyGetNumberUnits(armyID);
   debugAttackWave("We have " + armyCount + " Haft Raiders accounted for (dead or alive).");

   // If our Army size suddenly becomes smaller than the units we have taken into account, that means a new Army was spawned
   // that cleared existing units! When that happens, reset the count of assigned units.
   if (accountedUnitsHaft > armyCount)
   {
      // Reset the count on how many units we have assigned in our Army, since this is a brand new Army!
      assignedUnitsHaft = 0;
      accountedUnitsHaft = armyCount;
      debugAttackWave("Resetting Haft Raider ASSIGNED list! We're working with a CLEAN SLATE Army now!");
   }
   else if (accountedUnitsHaft <= armyCount)
   {
      // Keep incrementing our accounted units as the member count steadily increases...
      accountedUnitsHaft = armyCount;
   }

   // If we don't have the Haft anymore, cancel (and end our defend plan, if we have an active one).
   if (kbUnitCount(cUnitTypeThorHammerShaft, cMyID) < 1)
   {
      if (gDefendHaftID >= 0)
      {
         aiPlanDestroy(gDefendHaftID);
         gDefendHaftID = -1;
         debugAttackWave("We lost the Hammer Haft. Ending defend plan.");
      }
      return;
   }

   // If we have the Haft, get the location of it.
   debugAttackWave("We possess the Hammer Haft!");
   int haft = getUnit(cUnitTypeThorHammerShaft);
   if (haft == -1)
   {
      return;
   }

   // Move the Haft to it's storage zone.
   aiTaskMoveUnit(haft, gHaftStorage);

   // If we have an active defend plan, make sure the defending units follow the Haft as it can move around.
   vector haftPos = kbUnitGetPosition(haft);
   if (gDefendHaftPoint != haftPos && gDefendHaftID >= 0)
   {
      aiPlanSetVariableVector(gDefendHaftID, cDefendPlanTargetPoint, 0, haftPos);
      aiPlanSetVariableVector(gDefendHaftID, cDefendPlanGatherPoint, 0, haftPos);
   }
   gDefendHaftPoint = haftPos;

   // If we don't have an active defend plan, create it.
   if (gDefendHaftID < 0)
   {
      debugAttackWave("We don't have an active defend plan for the Hammer Haft anymore. Quick, make a new one!");
      gDefendHaftID = createDefendPlan("Guard Hammer Haft", -1, 25.0, gDefendHeadPoint, 10, gDefendHeadPoint);
      aiPlanSetVariableFloat(gDefendHaftID, cDefendPlanEngageRange, 0, 30.0);
   }

   // If all of our members are already assigned, no sense in taking further action with them.
   if (assignedUnitsHaft >= armyCount)
   {
      debugAttackWave("All of our Haft Raiders are occupied (or dead), we've got no more free units to use.");
      return;
   }

   // If we have fewer defenders in our plan than desired, start grabbing new, unassigned members from the Army.
   int defendCount = aiPlanGetNumberUnits(gDefendHaftID);
   if (defendCount < gDefendSizeHaft)
   {
      // Disallow the main AI to add new units after a short period of time.
      xsEnableRule("planNoMoreUnitsHaft");

      // Establish how many empty slots in the plan we have to fill.
      int emptySlots = gDefendSizeHaft - defendCount;
      debugAttackWave("We have " + defendCount + "/" + gDefendSizeHaft + " Haft defenders. We need to add " + emptySlots + " new units to our Haft defense!");

      // Check all the units in our army.
      for (int i = 0; i < armyCount; i++)
      {
         // Early member indexes belong to already assigned units. These may be dead, or already belong to the defend plan. Ignore them.
         if (i < assignedUnitsHaft)
         {
            continue;
         }

         // Pick the unit index from the army and put it into the plan.
         int unitID = kbArmyGetUnitID(armyID, i);
         int protoID = kbUnitGetProtoUnitID(unitID);
         aiPlanAddUnitType(gDefendHaftID, protoID, 1, 1, 1, false);
         aiPlanAddUnit(gDefendHaftID, unitID);

         // Increment how many Haft Army members we have assigned in total.
         assignedUnitsHaft++;

         // Decrement the number of available slots in the plan.
         emptySlots--;

         // If we run out of defend plan slots, stop assigning units.
         if (emptySlots <= 0)
         {
            break;
         }
      }
   }
}

// *** RULE - planNoMoreUnitsHaft ***
// A few seconds after assigning new units to the Hammer Haft defense plan, disallow additional units from being added to the plan.
rule planNoMoreUnitsHaft
inactive
minInterval 5
{
   aiPlanSetFlag(gDefendHaftID, cPlanFlagNoMoreUnits, true);
   xsDisableRule("planNoMoreUnitsHaft");
   return;
}

// *** RULE - boulderArmyAssign ***
// Assigns the Boulder Army to defend a specified Hammer piece.
// We'll use all the units in this army at once, as it is a impending-doom-like force in the narrative.
// Unlike other defend plans, the Boulder Army will chase the Hammer piece no matter who controls it.
rule boulderArmyAssign
inactive
minInterval 15
{
   debugAttackWave("DEBUG - BOULDER RULE CHECK");
   int piece = cUnitTypeThorHammerShaft;

   // Any player might be controlling the piece! Look at each player's units and see if they they have it.
   vector piecePos = cInvalidVector;

   for (int i = 0; i <= cNumberPlayers; i++)
   {
      debugAttackWave("Checking Player " + i + " for piece...");
      int queryID = useSimpleUnitQuery(piece, i, cUnitStateAlive);
      kbUnitQueryExecute(queryID);
      int pieceID = kbUnitQueryGetResult(queryID, 0);
      if (pieceID < 0)
      {
         continue;
      }
      else
      {
         debugAttackWave("Player " + i + " has the piece!");
         piecePos = kbUnitGetPosition(pieceID);
         if (gBoulderArmyDefendID >= 0)
         {
            aiPlanSetVariableVector(gBoulderArmyDefendID, cDefendPlanTargetPoint, 0, piecePos);
            aiPlanSetVariableVector(gBoulderArmyDefendID, cDefendPlanGatherPoint, 0, piecePos);
         }
         break;
      }
   }

   // Create the defend plan if we haven't already.
   if (gBoulderArmyDefendID < 0)
   {
      gBoulderArmyDefendID = createDefendPlan("Boulder Army Plan", -1, 25.0, piecePos, 10, piecePos);
      aiPlanSetVariableFloat(gBoulderArmyDefendID, cDefendPlanEngageRange, 0, 30.0);

      // Add the units.
      int armyID = kbArmyGetID(gArmyNameBoulder);
      int armyCount = kbArmyGetNumberUnits(armyID);

      // Disallow the main AI to add new units after a short period of time.
      xsEnableRule("planNoMoreUnitsBoulder");

      for (int i = 0; i < armyCount; i++)
      {
         // Pick the unit index from the army and put it into the plan.
         int unitID = kbArmyGetUnitID(armyID, i);
         int protoID = kbUnitGetProtoUnitID(unitID);
         aiPlanAddUnitType(gBoulderArmyDefendID, protoID, 1, 1, 1, false);
         aiPlanAddUnit(gBoulderArmyDefendID, unitID);
      }
   }
}

// *** RULE - planNoMoreUnitsBoulder ***
// A few seconds after assigning new units to the Hammer Haft defense plan, disallow additional units from being added to the plan.
// Specific to the Boulder Army.
rule planNoMoreUnitsBoulder
inactive
minInterval 5
{
   aiPlanSetFlag(gBoulderArmyDefendID, cPlanFlagNoMoreUnits, true);
   xsDisableRule("planNoMoreUnitsBoulder");
   return;
}