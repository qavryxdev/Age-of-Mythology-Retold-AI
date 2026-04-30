//==============================================================================
/* fott25_p4.xs

   Vibald's Clan (Thor)

   Red Norse player owning a compact base in the east of the map. They have a mixed force of Norse units,
   with a single Clan Leader (Hersir) in the center. Some of their units have been assigned to an Army in the editor, which will protect
   the Clan Leader.

   They are set to be inactive, only following the commands in this AI file.

   The AI frequently looks for the player's Folstag Flag bearer near their base entrances, launching a small attack if they
   manage to find it. The search radius if smaller on higher difficulties, requiring the Flag Bearer to go closer.
   
   If they have more units available than just the ones defending the Clan Leader, or if they have sent X amount of waves,
   they only send a handful of troops. Otherwise, they send everything they've got.

   When the Clan Leader dies, they cease everything.

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

float gAttackSize = 4;
float gAttackSizeMax = 30;
float gAttackWaveInterval = 10;   // In seconds.
float gFolstagFlagSearchRadius = 80.0;    // The search radius around the entirety of the base.
vector gEntranceMiddle = vector(122.0, 6.0, 262.0);    // By Eirik's center gate. Used as a starting point for launching attacks.
vector gBaseCenter = vector(121.0, 1.0, 282.0);     // The center of Eirik's base. Used as the center of the Flag search radius.
string gArmyNameGuards = "Vibald Guards";  // The Army name of the units assigned to guard the Clan Leader.

// The max amount of waves that can be sent only containing a small amount of units (triggered by the Flag Bearer's proximity).
// After having sent this many attacks, any future attacks will pull all the Clan's units to attack - including the Hersir!
int gSmallWaveMax = 4;

// Global variables for functions and rules, not to be edited.
int gBodyguardCount = 0;
vector gClanLeaderPosition = cInvalidVector;
float gNextAttackTime = 0.0;


//==============================================================================
/*	preInit()

   This function is called in main() before any of the normal initialization
   happens. Use it to override default values of variables as needed for
   scenario effects.
*/
//==============================================================================
void preInit()
{
   gAttackWaveInterval *= gDifficultyModifierAttackInterval;
   gAttackSize *= gDifficultyModifierAttackSizes;
   gAttackSizeMax *= gDifficultyModifierAttackSizes;

   gFolstagFlagSearchRadius = selectByDifficulty(80, 72, 64, 56, 56, 56);

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

// *** FUNCTION - miniAttack ***
// Launches an attack using a relatively small amount of this player's available reserve (non-bodyguards).
void miniAttack(float size = 0.0, vector targetPoint = cInvalidVector, bool isBigAttack = false)
{
   // Cancel if we haven't received proper parameters.
   if (targetPoint == cInvalidVector)
   {
      debugAttackWave("Alas, we couldn't establish our target point (Flag Bearer's position). Can't launch the attack.");
      return;
   }
   if (size == 0.0)
   {
      debugAttackWave("Alas, we do not have enough units. Can't launch the attack.");
      return;
   }

   // Limit the amount of units that will actually be attacking to this wave's attack size.
   // Unless it's the final attack featuring the Clan Leader, of course.
   if (size > gAttackSize && isBigAttack == false)
   {
      size = gAttackSize;
   }

   // Create the Attack plan.
   int attackID = aiPlanCreate("Tiny Attack Wave", cPlanAttack);
   aiPlanAddUnitType(attackID, cUnitTypeLogicalTypeLandMilitary, 0, size, size, false);
   aiPlanSetVariableInt(attackID, cAttackPlanTargetMode, 0, cAttackPlanTargetModePoint);
   aiPlanSetVariableInt(attackID, cAttackPlanTargetPlayerID, 0, 1); // Attack Player 1!
   aiPlanSetVariableVector(attackID, cAttackPlanTargetPoint, 0, targetPoint);
   aiPlanSetVariableVector(attackID, cAttackPlanGatherPoint, 0, gEntranceMiddle);
   aiPlanSetVariableFloat(attackID, cAttackPlanGatherDistance, 0, 40.0);
   aiPlanSetVariableFloat(attackID, cAttackPlanAttackModeEngageRange, 0, 40.0);
   setDefaultAttackPlanTargetUnitTypes(attackID);

   // Setup a route that uses the Flag Bearer's position as a waypoint in a path leading to the hill in the center of the map.
   vector startPoint = gEntranceMiddle;
   vector hilltop = vector(148.0, 12.0, 153.0);
   int routeID = kbCreateAttackRouteWithPath("Route to Hilltop via Flag Bearer", startPoint, hilltop);
   int pathID = kbPathCreate("Attack Path");
   kbPathAddWaypoint(pathID, startPoint);
   //kbPathAddWaypoint(pathID, targetPoint);
   kbPathAddWaypoint(pathID, hilltop);
   kbAttackRouteAddPath(routeID, pathID);
   aiPlanSetVariableInt(attackID, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternRandom);
   aiPlanSetVariableInt(attackID, cAttackPlanAttackRouteID, 0, routeID);

   //aiPlanSetVariableInt(attackID, cAttackPlanDoneMode, 0, cAttackPlanDoneModeNoTarget);
   aiPlanSetPriority(attackID, 50); // Moderate priority, higher than any other plans.
   
   debugAttackWave("Launching an attack with " + size + " units.");

   // Increase the size of the next attack wave.
   gAttackSize *= gDifficultyModifierAttackSizeMultiplier;
   if (gAttackSize > gAttackSizeMax)
   {
      gAttackSize = gAttackSizeMax;
   }
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

   // Look for Hersirs. The first one we find is our Clan Leader!
   int clanLeader = getUnit(cUnitTypeHersir);
   if (clanLeader == -1)
   {
      xsDisableRule("awaitingStartup");
      debugAttackWave("Hang on, we don't have a Hersir...");
      return;  // Abort all if we can't find a suitable Clan Leader...
   }

   // Get the clan leader's position in the game world.
   gClanLeaderPosition = kbUnitGetPosition(clanLeader);

   // Get the amount of units in the guarding army.
   int armyID = kbArmyGetID(gArmyNameGuards);
   gBodyguardCount = kbArmyGetNumberUnits(armyID);
   gBodyguardCount += 1;      // Count the Clan Leader as a defender.
   debugAttackWave("My Hersir has " + gBodyguardCount + " bodyguards, plus himself (Army ID: " + armyID + ")");

   // Enable other rules, looking for the Folstag Flag and detecting if our Clan Leader dies.
   xsEnableRule("scanForFolstagFlag");
   xsEnableRule("isClanLeaderKilled");

   xsDisableRule("awaitingStartup");
}

// *** RULE - scanForFolstagFlag ***
// Search for the player's Folstag Flag near our army. When it's found, send units from our main force in tiny attack waves.
// Only allowed to attack every X seconds (based on difficulty).
rule scanForFolstagFlag
inactive
minInterval 3
{
   if (xsGetTime() < gNextAttackTime)
   {
      return;     // Not time to attack yet.
   }

   // Track how many units we have in total, and how many of them are defenders.
   int queryID = useSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary);
   float unitsTotal = kbUnitQueryExecute(queryID);
   float unitsDefenders = gBodyguardCount;  // All the units in the guard army & the Clan Leader himself.
   debugAttackWave("I have " + unitsTotal + " units in total, " + unitsDefenders + " of which are defenders. Searching for flag...");

   // Prepare variables for the Folstag Flag position and available attackers.
   vector flagPosition = cInvalidVector;
   float unitsAttackers = 0.0;
   static int wavesSent = 0;

   // Check if the Folstag Flag is close enough to my base.
   int flagID = getUnitByLocation(cUnitTypeFolstagFlagBearer, 1, cUnitStateAlive, gBaseCenter, gFolstagFlagSearchRadius);
   if (flagID >= 0)
   {
      debugAttackWave("Found the flag!");

      flagPosition = kbUnitGetPosition(flagID);

      if (unitsTotal > unitsDefenders && wavesSent < gSmallWaveMax)    // If we have more units available than just our bodyguards, send a small wave.
      {
         unitsAttackers = unitsTotal - unitsDefenders;
         debugAttackWave("We have " + unitsAttackers + " unit(s) available to attack.");
         miniAttack(unitsAttackers, flagPosition, false);
      }
      else  // If we only have our bodyguards (and Clan Leader) left, send them all!
      {
         unitsAttackers = 200.0;
         debugAttackWave("We only have the Hersir and his bodyguards left! Send 'em all!");
         miniAttack(unitsAttackers, flagPosition, true);
      }
      
      // Update the number of attack waves sent in total.
      wavesSent += 1;

      // Establish at what time we're allowed to attack again.
      gNextAttackTime = xsGetTime() + gAttackWaveInterval;
      debugAttackWave("Waiting " + gAttackWaveInterval + " seconds until I'm allowed to attack again.");
      return;
   }
}

// *** RULE - isClanLeaderKilled ***
// Check if we no longer own a Hersir. If so, terminate our defend plan and the search for Folstag Flags.
rule isClanLeaderKilled
inactive
minInterval 5
{
   if (kbUnitCount(cUnitTypeHersir, cMyID, cUnitStateAlive) == 0)
   {
      debugAttackWave("OUR CLAN LEADER HAS FALLEN. END EVERYTHING!");
      xsDisableRule("scanForFolstagFlag");
      xsDisableRule("isClanLeaderKilled");
   }
}