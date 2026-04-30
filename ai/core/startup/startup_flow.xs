// Includes.
include "core/startup/map_analysis.xs";
include "core/startup/game_settings_analysis.xs";

//==============================================================================
// initResourceBreakdowns
//==============================================================================
void initResourceBreakdowns()
{
   // Set initial gatherer percentages.
   aiSetResourcePercentage(cResourceFood, false, 1.0);
   aiSetResourcePercentage(cResourceWood, false, 0.0);
   aiSetResourcePercentage(cResourceGold, false, 0.0);
   // Set up the initial resource breakdowns.
   int mainBaseID = getMainGatherBaseID();
   if (kbBaseGetIsIDValid(cMyID, mainBaseID) == true) // Don't bother if we don't have a main base
   {
      if (gOverrideOkToGatherFood == true)
      {
         // All on hunt at the start.
         aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeEasy, 0, 49, 0.0, mainBaseID);
         aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeHunt, 0, 50, 0.34, mainBaseID);
         aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeHerdable, 0, 24, 0.0, mainBaseID);
         aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeHuntAggressive, 0, 48, 0.0, mainBaseID);
         aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeFarm, 0, 51, 0.0, mainBaseID);
      }
      if (gOverrideOkToGatherWood == true)
      {
         aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, 0, 50, 0.33, mainBaseID);
      }
      if (gOverrideOkToGatherGold == true)
      {
         aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, 0, 55, 0.33, mainBaseID);
      }
      if (cMyCulture == cCultureGreek && gOverrideOkToGatherFavor == true)
      {
         aiSetResourceBreakdown(cResourceFavor, cAIResourceSubTypeEasy, 0, 10, 0.0, mainBaseID);
      }
   }
}

//==============================================================================
// doStartupFlow
//==============================================================================
void doStartupFlow()
{
   doGameSettingsAnalysis();
   if (doMapAnalysis() == false)
   {
      gIncompatibleMap = true;
   }

   initResourceBreakdowns();
}