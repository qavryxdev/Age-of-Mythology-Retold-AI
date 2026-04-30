//==============================================================================
/* globals_override.xs

   This file contains all global variables that can be used to override default behavior.

*/
//==============================================================================

//==============================================================================
// Techs.
//==============================================================================
extern int gOverrideClassicalMinorGod = -1;
extern int gOverrideHeroicMinorGod = -1;
extern int gOverrideMythicMinorGod = -1;

//==============================================================================
// Economy.
//==============================================================================
extern int gOverrideFarmCount = 1000;
// If you disable any flag that auto creates maintain plans for any of the 3 units below but keep cStrategyFlagAutomaticPopLimits active,
// then you must still set the override for that unit so the cStrategyFlagAutomaticPopLimits flag can properly function still.
extern int gOverrideMaxVillagerPop = -1;
extern int gOverrideMaxFishingShipPop = -1;
extern int gOverrideMaxCaravanPop = -1;
extern bool gOverrideAutomaticDropsitePlacement = true;

extern vector gOverrideClosestFishLocation = cInvalidVector;

extern bool gOverrideOkToGatherFood = true; // Setting it false will turn off food gathering. True turns it on.
extern bool gOverrideOkToGatherGold = true; // Setting it false will turn off gold gathering. True turns it on.
extern bool gOverrideOkToGatherWood = true; // Setting it false will turn off wood gathering. True turns it on.
extern bool gOverrideOkToGatherFavor = true; // Setting it false will turn off favor gathering. True turns it on.

//==============================================================================
// Military.
//==============================================================================
extern const int cUnlimitedMilitaryPop = -1;
extern const int cCalculateMilitaryPop = -2;
extern int gOverrideMaxMilitaryPop = cCalculateMilitaryPop;
extern int gOverrideTargetPlayerID = -1;
extern const int cOverrideDontAttackPlayerID = 700; // Use this if you want the naval attacking logic to do nothing.

extern const int cUnlimitedNavalMilitaryPop = -1;
extern const int cCalculateNavalMilitaryPop = -2;
extern int gOverrideNavalMaxMilitaryPop = cCalculateNavalMilitaryPop;
extern int gOverrideNavalTargetPlayer = -1;
extern const int cOverrideDontNavalAttackPlayerID = 700; // Use this if you want the naval attacking logic to do nothing.

//==============================================================================
// Misc.
//==============================================================================
extern bool gInactiveAI = false; // If set to true the AI will never go past init and won't do anything.
extern bool gIncompatibleMap = false;
extern bool gStartInactive = false;
extern void() gOverrideStrategy = []() {};
extern bool gOverrideStrategyUsed = false;
void setOverrideStrategy(void() overrideStrat = []() {})
{
   aiEcho("Setting an override strategy!");
   gOverrideStrategy = overrideStrat;
   gOverrideStrategyUsed = true;
}
extern bool forceBOStrat = false;