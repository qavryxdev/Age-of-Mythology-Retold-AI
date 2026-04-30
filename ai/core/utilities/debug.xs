//==============================================================================
// Debug category variables
//==============================================================================
extern int gUtilitiesCategoryID = -1;
extern int gBuildingsCategoryID = -1;
extern int gTechsCategoryID = -1;
extern int gExplorationCategoryID = -1;
extern int gEconomyCategoryID = -1;
extern int gResourceBreakdownCategoryID = -1;
extern int gResourceDistributionCategoryID = -1;
extern int gMilitaryAttackingCategoryID = -1;
extern int gMilitaryDefendingCategoryID = -1;
extern int gMilitaryTrainingCategoryID = -1;
extern int gNavalMilitaryCategoryID = -1;
extern int gNavalMilitaryTrainingCategoryID = -1;
extern int gChatsCategoryID = -1;
extern int gSetupCategoryID = -1;
extern int gStartAnalysisCategoryID = -1;
extern int gStrategyCategoryID = -1;
extern int gBoCategoryID = -1;
extern int gBoStepCategoryID = -1;
extern int gGodpowersCategoryID = -1;
extern int gBaseCategoryID = -1;
extern int gMigrationCategoryID = -1;
extern int gTradeCategoryID = -1;
extern int gAttackWaveCategoryID = -1;

//==============================================================================
// setupDebugCategories
//==============================================================================
void setupDebugCategories()
{
   gUtilitiesCategoryID = aiAddEchoCategory("Utilities");
   gBuildingsCategoryID = aiAddEchoCategory("Buildings"); // Some hardcoded mechanisms look this up by name, don't change.
   gTechsCategoryID = aiAddEchoCategory("Techs");
   gExplorationCategoryID = aiAddEchoCategory("Exploration");
   gEconomyCategoryID = aiAddEchoCategory("Economy"); // Some hardcoded mechanisms look this up by name, don't change.
   gResourceBreakdownCategoryID = aiAddEchoCategory("Resource Breakdown");
   gResourceDistributionCategoryID = aiAddEchoCategory("Resource Distribution");
   gMilitaryAttackingCategoryID = aiAddEchoCategory("Military Attacking");
   gMilitaryDefendingCategoryID = aiAddEchoCategory("Military Defending");
   gMilitaryTrainingCategoryID = aiAddEchoCategory("Military Training");
   gNavalMilitaryCategoryID = aiAddEchoCategory("Naval Military");
   gNavalMilitaryTrainingCategoryID = aiAddEchoCategory("Naval Military Training");
   gChatsCategoryID = aiAddEchoCategory("Chats");
   gSetupCategoryID = aiAddEchoCategory("Setup");
   gStartAnalysisCategoryID = aiAddEchoCategory("Start Analysis");
   gStrategyCategoryID = aiAddEchoCategory("Strategy");
   gBoCategoryID = aiAddEchoCategory("BO");
   gBoStepCategoryID = aiAddEchoCategory("BO Step");
   gGodpowersCategoryID = aiAddEchoCategory("Godpower");
   gBaseCategoryID = aiAddEchoCategory("Base");
   gMigrationCategoryID = aiAddEchoCategory("Migration");
   gTradeCategoryID = aiAddEchoCategory("Trade");
   gAttackWaveCategoryID = aiAddEchoCategory("Attack Wave");
}

//==============================================================================
// Debug output functions.
//==============================================================================
void debugUtilities(string message = "")
{
   aiEchoCategory(gUtilitiesCategoryID, message);
}
void debugBuildings(string message = "")
{
   aiEchoCategory(gBuildingsCategoryID, message);
}
void debugTechs(string message = "")
{
   aiEchoCategory(gTechsCategoryID, message);
}
void debugExploration(string message = "")
{
   aiEchoCategory(gExplorationCategoryID, message);
}
void debugEconomy(string message = "")
{
   aiEchoCategory(gEconomyCategoryID, message);
}
void debugResourceBreakdown(string msg = "")
{
   aiEchoCategory(gResourceBreakdownCategoryID, "Resource Breakdown: " + msg);
}
void debugResourceDistribution(string message = "")
{
   aiEchoCategory(gResourceDistributionCategoryID, message);
}
void debugMilitaryAttacking(string message = "")
{
   aiEchoCategory(gMilitaryAttackingCategoryID, message);
}
void debugMilitaryDefending(string message = "")
{
   aiEchoCategory(gMilitaryDefendingCategoryID, message);
}
void debugMilitaryTraining(string message = "")
{
   aiEchoCategory(gMilitaryTrainingCategoryID, message);
}
void debugNavalMilitary(string message = "")
{
   aiEchoCategory(gNavalMilitaryCategoryID, message);
}
void debugNavalMilitaryTraining(string message = "")
{
   aiEchoCategory(gNavalMilitaryTrainingCategoryID, message);
}
void debugChats(string message = "")
{
   aiEchoCategory(gChatsCategoryID, message);
}
void debugSetup(string message = "")
{
   aiEchoCategory(gSetupCategoryID, message);
}
void debugStartAnalysis(string message = "")
{
   aiEchoCategory(gStartAnalysisCategoryID, "Start Analysis: " + message);
}
void debugStrategy(string message = "")
{
   aiEchoCategory(gStrategyCategoryID, message);
}
void debugBO(string message = "")
{
   aiEchoCategory(gBoCategoryID, "BOSystem: " + message);
}
void debugBOStep(string message = "")
{
   aiEchoCategory(gBoStepCategoryID, "BO Step: " + message);
}
void debugGodPowers(string message = "")
{
   aiEchoCategory(gGodpowersCategoryID, message);
}
void debugBase(string message = "")
{
   aiEchoCategory(gBaseCategoryID, message);
}
void debugMigrationStrategy(string message = "")
{
   aiEchoCategory(gMigrationCategoryID, message);
}
void debugTrade(string message = "")
{
   aiEchoCategory(gTradeCategoryID, message);
}
void debugAttackWave(string message = "")
{
   aiEchoCategory(gAttackWaveCategoryID, message);
}