// Includes.
include "core/core.xs";

//==============================================================================
/* main
   This function is called during the loading screen before the game has started.
   Some stuff isn't initialised yet at this point so we must account for this.
*/
//==============================================================================

void main(void)
{
   aiEcho("Main is starting");
   aiEcho("Seed for Rand: " + xsRandGetSeed() + ".");
   
   setupDebugCategories();

   // Initialise all global civilisation specific unit types. (g****Unit variables)
   initCivUnitTypes();

   // Create the global arrays.
   initArrays();

   // Call the function that campaign loaders can overwrite to already set some values
   // we can use during our entire startup flow.
   preInit();

   if (gInactiveAI == true)
   {
      aiEcho("gInactiveAI = true, we stop all logic now.");
      aiSetAutomaticallyUngarrisonUnits(false);
      return; // If we got set to inactive by scenario loaders we're done now.
   }

   // Analyze the map to see what we're dealing with this time.
   doStartupFlow();

   if (gIncompatibleMap == true)
   {
      aiEcho("Our startup flow has determined that the AI is incompatible with the current map!!!");
      aiEcho("We won't shut ourself down but what will happen now is probably very bad.");
   }

   // Set up all XS handlers.
   initXSHandlers();

   // Set some global values.
   aiSetAttackResponseDistance(65.0);
   aiSetExploreDangerThreshold(110.0);
   kbSetResourceSelectorFactor(cTSFactorTotalResources, cResourceWood, 100);
   aiSetOutpostLimit(10);

   // Populate the list of which age ups we have available.
   aiPopulateAgeUpList();

   // From here we move to setup.xs to either start up our BO/Strategies or wait if we're ordered to by a trigger.
   prepareForInit();
}