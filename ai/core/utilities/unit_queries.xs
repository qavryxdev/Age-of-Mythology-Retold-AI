//==============================================================================
/* unit_queries.xs

   This file contains any unit query related functions.

*/
//==============================================================================

//==============================================================================
// getUnit
// Will return a random unit matching the parameters
//==============================================================================
int getUnit(int unitTypeID = -1, int playerRelationOrID = cMyID, int state = cUnitStateAlive,
            int visibleState = cUnitQueryVisibleStateAllValid, int[] excludeTypes = default)
{
   static int unitQueryID = -1;

   // If we don't have the query yet, create one.
   if (unitQueryID < 0)
   {
      unitQueryID = kbUnitQueryCreate("getUnit");
   }

   // Define a query to get all matching units
   if (unitQueryID != -1)
   {
      if (playerRelationOrID > 1000) // Too big for player ID number
      {
         kbUnitQuerySetPlayerID(unitQueryID, -1); // Clear the player ID, so playerRelation takes precedence.
         kbUnitQuerySetPlayerRelation(unitQueryID, playerRelationOrID);
      }
      else
      {
         kbUnitQuerySetPlayerRelation(unitQueryID, cPlayerRelationAny);
         kbUnitQuerySetPlayerID(unitQueryID, playerRelationOrID);
      }
      if (visibleState != cUnitQueryVisibleStateAllValid)
      {
         kbUnitQuerySetVisibleState(unitQueryID, visibleState);
      }
      if (excludeTypes.size() > 0)
      {
         kbUnitQuerySetExcludeTypes(unitQueryID, excludeTypes);
      }
      kbUnitQuerySetUnitType(unitQueryID, unitTypeID);
      kbUnitQuerySetState(unitQueryID, state);
   }
   else
   {
      return (-1);
   }

   kbUnitQueryResetResults(unitQueryID);
   int numberFound = kbUnitQueryExecute(unitQueryID);
   if (numberFound > 0)
   {
      return (kbUnitQueryGetResult(unitQueryID, xsRandInt(0, numberFound - 1))); // Return a random dude(tte)
   }
   return (-1);
}

//==============================================================================
// useSimpleUnitQuery
//==============================================================================
int useSimpleUnitQuery(int unitTypeID = -1, int playerRelationOrID = cMyID, int state = cUnitStateAlive,
   vector position = cInvalidVector, float radius = -1.0)
{
   static int unitQueryID = -1;

   // If we don't have the query yet, create one.
   if (unitQueryID < 0)
   {
      unitQueryID = kbUnitQueryCreate("useSimpleUnitQuery");
   }

   // Define a query to get all matching units.
   if (unitQueryID != -1)
   {
      if (playerRelationOrID > 1000) // Too big for player ID number.
      {
         kbUnitQuerySetPlayerID(unitQueryID, -1); // Clear the player ID, so playerRelation takes precedence.
         kbUnitQuerySetPlayerRelation(unitQueryID, playerRelationOrID);
      }
      else
      {
         kbUnitQuerySetPlayerRelation(unitQueryID, cPlayerRelationAny);
         kbUnitQuerySetPlayerID(unitQueryID, playerRelationOrID);
      }
      kbUnitQuerySetUnitType(unitQueryID, unitTypeID);
      kbUnitQuerySetState(unitQueryID, state);
      kbUnitQuerySetPosition(unitQueryID, position);
      kbUnitQuerySetMaximumDistance(unitQueryID, radius);
   }
   else
   {
      return -1;
   }

   kbUnitQueryResetResults(unitQueryID);
   return unitQueryID;
}

//==============================================================================
// getUnitByLocation
// Will return a random unit matching the parameters
//==============================================================================
int getUnitByLocation(int unitTypeID = -1, int playerRelationOrID = cMyID, int state = cUnitStateAlive,
   vector location = cInvalidVector, float radius = 20.0)
{
   static int unitQueryID = -1;

   // If we don't have the query yet, create one.
   if (unitQueryID < 0)
   {
      unitQueryID = kbUnitQueryCreate("getUnitByLocation");
   }

   if (kbGetIsLocationOnMap(location) == false)
   {
      aiEchoWarning("Calling getUnitByLocation with an invalid position, this makes no sense to do.");
      return -1;
   }
   if (radius <= 0.0)
   {
      aiEchoWarning("Calling getUnitByLocation with a radius that is too small: " + radius + ".");
      return -1;
   }

   // Define a query to get all matching units.
   if (unitQueryID != -1)
   {
      if (playerRelationOrID > 1000) // Too big for player ID number.
      {
         kbUnitQuerySetPlayerID(unitQueryID, -1);
         kbUnitQuerySetPlayerRelation(unitQueryID, playerRelationOrID);
      }
      else
      {
         kbUnitQuerySetPlayerRelation(unitQueryID, cPlayerRelationAny);
         kbUnitQuerySetPlayerID(unitQueryID, playerRelationOrID);
      }
      kbUnitQuerySetUnitType(unitQueryID, unitTypeID);
      kbUnitQuerySetState(unitQueryID, state);
      kbUnitQuerySetPosition(unitQueryID, location);
      kbUnitQuerySetMaximumDistance(unitQueryID, radius);
   }
   else
   {
      return -1;
   }

   kbUnitQueryResetResults(unitQueryID);
   int numberFound = kbUnitQueryExecute(unitQueryID);
   if (numberFound > 0)
   {
      return kbUnitQueryGetResult(unitQueryID, xsRandInt(0, numberFound - 1)); // Return a random dude.
   }
   return -1;
}

//==============================================================================
// getClosestUnitByLocation
// Will return a random unit matching the parameters
//==============================================================================
int getClosestUnitByLocation(int unitTypeID = -1, int playerRelationOrID = cMyID, int state = cUnitStateAlive,
   vector location = cInvalidVector, float radius = 20.0, int visibleState = cUnitQueryVisibleStateAllValid)
{
   static int unitQueryID = -1;

   // If we don't have the query yet, create one.
   if (unitQueryID < 0)
   {
      unitQueryID = kbUnitQueryCreate("getClosestUnitByLocation");
   }

   if (kbGetIsLocationOnMap(location) == false)
   {
      aiEchoWarning("Calling getClosestUnitByLocation with an invalid position, this makes no sense to do.");
      return -1;
   }
   if (radius <= 0.0)
   {
      aiEchoWarning("Calling getClosestUnitByLocation with a radius that is too small: " + radius + ".");
      return -1;
   }

   // Define a query to get all matching units.
   if (unitQueryID != -1)
   {
      if (playerRelationOrID > 1000) // Too big for player ID number.
      {
         kbUnitQuerySetPlayerID(unitQueryID, -1);
         kbUnitQuerySetPlayerRelation(unitQueryID, playerRelationOrID);
      }
      else
      {
         kbUnitQuerySetPlayerRelation(unitQueryID, cPlayerRelationAny);
         kbUnitQuerySetPlayerID(unitQueryID, playerRelationOrID);
      }
      if (visibleState != cUnitQueryVisibleStateAllValid)
      {
         kbUnitQuerySetVisibleState(unitQueryID, visibleState);
      }
      kbUnitQuerySetUnitType(unitQueryID, unitTypeID);
      kbUnitQuerySetState(unitQueryID, state);
      kbUnitQuerySetPosition(unitQueryID, location);
      kbUnitQuerySetMaximumDistance(unitQueryID, radius);
      kbUnitQuerySetAscendingSort(unitQueryID, true);
   }
   else
   {
      return -1;
   }

   kbUnitQueryResetResults(unitQueryID);
   int numberFound = kbUnitQueryExecute(unitQueryID);
   if (numberFound > 0)
   {
      return kbUnitQueryGetResult(unitQueryID, 0); // Return the first unit.
   }
   return -1;
}

//==============================================================================
// getUnitCountByLocation
// Returns the number of matching units in the point/radius specified
//==============================================================================
int getUnitCountByLocation(int unitTypeID = -1, int playerRelationOrID = cMyID, int state = cUnitStateAlive,
   vector location = cInvalidVector, float radius = 20.0, int visibleState = cUnitQueryVisibleStateAllValid)
{
   static int unitQueryID = -1;

   // If we don't have the query yet, create one.
   if (unitQueryID < 0)
   {
      unitQueryID = kbUnitQueryCreate("getUnitCountByLocation");
   }

   if (kbGetIsLocationOnMap(location) == false)
   {
      aiEchoWarning("Calling getUnitCountByLocation with an invalid position, this makes no sense to do.");
      return -1;
   }
   if (radius <= 0.0)
   {
      aiEchoWarning("Calling getUnitCountByLocation with a radius that is too small: " + radius + ".");
      return -1;
   }

   // Define a query to get all matching units.
   if (unitQueryID != -1)
   {
      if (playerRelationOrID > 1000) // Too big for player ID number.
      {
         kbUnitQuerySetPlayerID(unitQueryID, -1);
         kbUnitQuerySetPlayerRelation(unitQueryID, playerRelationOrID);
      }
      else
      {
         kbUnitQuerySetPlayerRelation(unitQueryID, cPlayerRelationAny);
         kbUnitQuerySetPlayerID(unitQueryID, playerRelationOrID);
      }
      if (visibleState != cUnitQueryVisibleStateAllValid)
      {
         kbUnitQuerySetVisibleState(unitQueryID, visibleState);
      }
      kbUnitQuerySetUnitType(unitQueryID, unitTypeID);
      kbUnitQuerySetState(unitQueryID, state);
      kbUnitQuerySetPosition(unitQueryID, location);
      kbUnitQuerySetMaximumDistance(unitQueryID, radius);
   }
   else
   {
      return -1;
   }

   kbUnitQueryResetResults(unitQueryID);
   return kbUnitQueryExecute(unitQueryID);
}

//==============================================================================
// getIdleUnit
// Will return the first unit with matching parameters.
//==============================================================================
int getIdleUnit(int unitTypeID = -1, int playerRelationOrID = cMyID, int state = cUnitStateAlive)
{
   int unitQueryID = useSimpleUnitQuery(unitTypeID, playerRelationOrID, state);
   int numberFound = kbUnitQueryExecute(unitQueryID);
   for (int i = 0; i < numberFound; i++)
   {
      int unitID = kbUnitQueryGetResult(unitQueryID, i);
      if (aiPlanGetIsIDValid(kbUnitGetPlanID(unitID)) == true)
      {
         continue;
      }
      return unitID;
   }

   return -1;
}

//==============================================================================
// useSimpleNatureUnitQuery
// ATTENTION: before you call this function switch your context to nature(0) otherwise this won't work.
// Then in your code first kbUnitQueryExecute the query BEFORE you switch back to cMyID.
//==============================================================================
int useSimpleNatureUnitQuery(int unitTypeID = -1, int state = cUnitStateAlive,
   vector position = cInvalidVector, float radius = -1.0)
{
   static int unitQueryID = -1;

   // If we don't have the query yet, create one.
   if (unitQueryID < 0)
   {
      unitQueryID = kbUnitQueryCreate("useSimpleNatureUnitQuery");
      kbUnitQuerySetPlayerID(unitQueryID, 0);
   }

   // Define a query to get all matching units.
   if (unitQueryID != -1)
   {
      kbUnitQuerySetUnitType(unitQueryID, unitTypeID);
      kbUnitQuerySetState(unitQueryID, state);
      kbUnitQuerySetPosition(unitQueryID, position);
      kbUnitQuerySetMaximumDistance(unitQueryID, radius);
   }
   else
   {
      return -1;
   }

   kbUnitQueryResetResults(unitQueryID);
   return unitQueryID;
}

//==============================================================================
// getNatureUnitCount
// Unit count from nature's perspective, use with caution to avoid cheating.
//==============================================================================
int getNatureUnitCount(int unitTypeID = -1, int unitState = cUnitStateAlive)
{
   xsSetContextPlayer(0);
   int numberFound = kbUnitCount(unitTypeID, 0, unitState);
   xsSetContextPlayer(cMyID);
   return numberFound;
}

//==============================================================================
// getClosestNatureUnitPosition
// Query closest unit's position from nature's perspective, use with caution to avoid cheating.
//==============================================================================
vector getClosestNatureUnitPosition(int unitTypeID = -1, vector position = cInvalidVector, float radius = -1.0)
{
   xsSetContextPlayer(0);
   static int unitQueryID = -1;

   // If we don't have the query yet, create one.
   if (unitQueryID < 0)
   {
      unitQueryID = kbUnitQueryCreate("getClosestNatureUnitPosition");
      kbUnitQuerySetPlayerID(unitQueryID, 0);
      kbUnitQuerySetState(unitQueryID, cUnitStateAlive);
      kbUnitQuerySetAscendingSort(unitQueryID, true);
   }

   // Define a query to get all matching units.
   if (unitQueryID != -1)
   {
      kbUnitQuerySetUnitType(unitQueryID, unitTypeID);
      kbUnitQuerySetPosition(unitQueryID, position);
      kbUnitQuerySetMaximumDistance(unitQueryID, radius);
   }
   else
   {
      xsSetContextPlayer(cMyID);
      return cInvalidVector;
   }

   kbUnitQueryResetResults(unitQueryID);

   if (kbUnitQueryExecute(unitQueryID) > 0)
   {
      // Get the location of the first(closest) unit.
      vector closestFishPosition = kbUnitGetPosition(kbUnitQueryGetResult(unitQueryID, 0));
      xsSetContextPlayer(cMyID);
      return (closestFishPosition);
   }
   xsSetContextPlayer(cMyID);
   return cInvalidVector;
}


//==============================================================================
// getCountOfOwnAliveBuildingInBase
//==============================================================================
int getCountOfOwnAliveBuildingInBase(int puid = -1, int baseID = -1)
{
   static int queryID = -1;
   // If we don't have the query yet, create one.
   if (queryID < 0)
   {
      queryID = kbUnitQueryCreate("getCountOfOwnAliveBuildingInBase");
      kbUnitQuerySetPlayerID(queryID, cMyID);
      kbUnitQuerySetState(queryID, cUnitStateAlive);
   }
   if (kbProtoUnitGetIsValidID(puid) == false)
   {
      aiEchoWarning("Calling getCountOfOwnAliveBuildingInBase with an invalid puid: " + puid + ".");
      return -1;
   }
   if (kbBaseGetIsIDValid(cMyID, baseID) == false)
   {
      aiEchoWarning("Calling getCountOfOwnAliveBuildingInBase with an invalid baseID: " + baseID + ".");
      return -1;
   }
   kbUnitQuerySetUnitType(queryID, puid);
   kbUnitQuerySetBaseID(queryID, baseID);
   kbUnitQueryResetResults(queryID);
   return kbUnitQueryExecute(queryID);
}