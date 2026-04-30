//==============================================================================
/* globals.xs

   This file contains all global constants and variables.

*/
//==============================================================================

extern int gMicroFlags = 0;

//==============================================================================
// Unit types.
//==============================================================================
extern int gEconUnit = -1;
extern int gFishingUnit = -1;
extern int gFarmUnit = -1;
extern int gHouseUnit = -1;
extern int gMarketUnit = -1;
extern int gFortressUnit = -1;
extern int gCaravanUnit = -1;
extern int gArcherShip = -1;
extern int gCloseCombatShip = -1;
extern int gSiegeShip = -1;
extern int gArmoryUnit = -1;

//==============================================================================
// Buildings.
//==============================================================================
extern int gMainGatherBase = -1;
extern int[] gMilitaryBuildings = default;
extern int[] gArmyUnitBuildings = default;

extern bool(int, int, int) gFarmPlacementOverride = [](int planID = -1, int bpID = -1, int baseID = -1) -> bool { return (false); };
extern bool gFarmPlacementOverrideUsed = false;
extern const int cCalculateNumBuildersAutomatically = 999;
extern const int cCalculateNumberTowersAutomatically = -1;

extern vector gClosestFishLocation = cInvalidVector; // Used to determine Dock placement.

extern int gMainBaseTCBuildPlan = -1;

//==============================================================================
// Techs.
//==============================================================================
extern int gAgeUpResearchPlan = -1; // Plan used to detect if an age upgrade is in progress.
extern int[] gAgeUpTimes = default; // We save our age up times in this array.
extern int[] gFastestAgeUpTimes = default; // We save the fastest up times of other players in this array.

extern int gMilitaryResearchPlan = -1;
extern int gMilitaryDockResearchPlan = -1;
extern int gEconomyResearchPlan = -1;
extern int gNumMarketUsage = 0;

//==============================================================================
// Economy.
//==============================================================================
extern bool gTimeToFarm = false; // Set to true when we start to run out of cheap early food.
extern int gVillagerMaintainPlan = -1; // Main plan to control villager population.
extern int gSecondVillagerMaintainPlan = -1; // Second plan to control villager population, Dwarves.
extern int gCaravanMaintainPlan = -1;

extern int gFishingPlan = -1; // Plan ID for main fishing plan.
extern int gFishingShipMaintainPlan = -1; // Fishing boats to maintain
extern float gMaxFishDockScanRange = 110.0; // We perform our Fish/Dock logic within this range from our mainbase location.

extern float[] gResourceNeeds = default;
extern int[] gAdjustBreakdownAttempts = default;
extern float[] gMarketBuySellPercentages = default; // Array of resource percentages to exchange to another one.
extern float[] gRawResourcePercentages = default; // Raw resource percentages before market buy sell adjustments.

extern int gResourceCanExceedMaxDistance = 0;
extern bool gResourceSearchMatchAreaGroups = true;

extern bool gDelayUpdateDistributionAndBreakdowns = false;
extern int gBOEndTime = -1;

//==============================================================================
// Military.
//==============================================================================
// v1.0: zvyseny procenta hrdinu a mytickych - hrdinove/myticke jsou nejsilnejsi jednotky
#if (cDifficultyCurrent <= cDifficultyHard)
extern float gArmyHeroPercentage = 0.20; // bylo 0.10
#else
extern float gArmyHeroPercentage = 0.30; // bylo 0.20
#endif
extern float gArmyEarlyGameMythPercentage = 0.20; // bylo 0.10
extern float gArmyLateGameMythPercentage = 0.30;  // bylo 0.15
extern float gArmySiegePercentage = 0.15;          // bylo 0.10

#if (cMyCulture == cCultureNorse)
extern float gHumanArmyArcherPercentage = 0.20;
#else
extern float gHumanArmyArcherPercentage = 0.30;
#endif

extern const int gNumHumanArcherUnitTypes = 1; // Shared.
extern const int gNumHumanMeleeUnitTypes = 3; // Shared.

#if (cMyCulture == cCultureEgyptian)
extern const int gNumHeroUnitTypes = 1; // Priests.
#elif (cMyCulture == cCultureNorse)
extern const int gNumHeroUnitTypes = 2; // Godi and Hersir.
#else
extern const int gNumHeroUnitTypes = 0; // Greek + Atty uniquely handled without maintain plans.
#endif

extern const int gNumSiegeUnitTypes = 2; // Shared.

extern const int gNumTotalArmyUnitTypes = gNumHumanArcherUnitTypes + gNumHumanMeleeUnitTypes + gNumHeroUnitTypes + gNumSiegeUnitTypes;

extern const int gMaintainPlanHumanArcherStartIndex = 0;
extern const int gMaintainPlanHumanMeleeStartIndex = gMaintainPlanHumanArcherStartIndex + gNumHumanArcherUnitTypes;
extern const int gMaintainPlanHeroStartIndex = gMaintainPlanHumanMeleeStartIndex + gNumHumanMeleeUnitTypes;
extern const int gMaintainPlanSiegeStartIndex = gMaintainPlanHeroStartIndex + gNumHeroUnitTypes;

extern int gMaxMilitaryPop = -1;
extern float gMilitaryToEcoRatio = 1.5;

extern int[] gArmyUnitMaintainPlans = default;
extern int[] gNavalUnitMaintainPlans = default;
extern const int cNumWarships = 3;

extern int gTransportMaintainPlanID = -1;

// Defending
extern int gPrimaryLandDefendPlan = -1; // Primary land defend plan.
extern int gPrimaryNavalDefendPlan = -1; // Primary naval defend plan.

extern const float gWinningArmyPercentage = 1.2;
extern int[] gDefendTCBases = default;
extern int[] gDefendPlans = default;

// Only used for land defending, naval we just defend our gMapInfo.mWaterDefendPoint.
extern bool gDefenseReflex = false; // Set true when we're actively defending something.
extern int gDefenseReflexBaseID = -1; // Set to the base ID that we're defending.
extern vector gDefenseReflexGatherPoint = cInvalidVector; // Location we're gathering.
extern bool gDefenseReflexPanic = false; // If our main base is being overrun this goes to true.

extern int[] gArrayEnemyPlayerIDs = default; // Used to pick a target to attack.
extern float[] gStartingPosDistances = default; // Used to sort enemies from closest to furthest away for target picking in FFA.

// Attacking naval.
extern int gLastNavalAttackTime = 0;
extern int gNavalAttackInterval = 180; 

// Enemy scouting constants.
extern const int cNoScoutingNeeded = 0;
extern const int cNoEnemies = -2;
extern const int cScoutingForEnemies = 999;

// Attack manager states.
extern const int cStateNormal = 0;
extern const int cStateForcedAttack = 1;
extern const int cStateForcedCantAttack = 2;
extern const int cStateNeedScouting = 3;

// KOTH.
extern vector gKOTHPosition = cInvalidVector;
extern int gKOTHUnitID = -1;
extern int gKOTHTotalTime = -1;
extern int gKOTHStartTime = -1;
extern int gKOTHOwnedBy = -1;
extern bool gKOTHIsOwnedByAllies = false;
extern int gKOTHDefendPlanID = -1;

// Misc.
extern bool gIsFFA = false;

//==============================================================================
// Exploration.
//==============================================================================
extern bool gFullyExploredStartingSurroundings = false;

//==============================================================================
// Strategy.
//==============================================================================
extern const int cStrategyFlagAutoAgeUp = 0;
extern const int cStrategyFlagAutoBuildMilitaryBuildings = 1;
extern const int cStrategyFlagAutoTrainMilitaryUnits = 2;
extern const int cStrategyFlagAutoResearchEconomyUpgrades = 3;
extern const int cStrategyFlagAutoResearchMilitaryUpgrades = 4;
extern const int cStrategyFlagCanAttack = 5;
extern const int cStrategyFlagBuildArmory = 6;
extern const int cStrategyFlagBuildMonuments = 7;
extern const int cStrategyFlagAutomaticVillagerTraining = 8;
extern const int cStrategyFlagAutomaticHerding = 9;
extern const int cStrategyFlagAutomaticScouting = 10;
extern const int cStrategyFlagAutomaticOxCartTraining = 11;
extern const int cStrategyFlagBuildEconomicGuild = 12;
extern const int cStrategyFlagBuildTemple = 13;
extern const int cStrategyFlagBuildHouses = 14;
extern const int cStrategyFlagCanDefend = 15;
extern const int cStrategyFlagBuildTowers = 16;
extern const int cStrategyFlagAutomaticMigration = 17;
extern const int cStrategyFlagAutomaticGodPowerUsage = 18;
extern const int cStrategyFlagCanTrade = 19;
extern const int cStrategyFlagAutomaticEco = 20;
extern const int cStrategyFlagAutomaticFishing = 21;
extern const int cStrategyFlagAutomaticDockBuilding = 22;
extern const int cStrategyFlagAutomaticBaseGrowth = 23;
extern const int cStrategyFlagAutomaticNavalGameplay = 24;
extern const int cStrategyFlagAutomaticMainBaseTCRebuild = 25;
extern const int cStrategyFlagAutomaticTCRepair = 26;
extern const int cStrategyFlagAutomaticTCExpansion = 27;
extern const int cStrategyFlagCollectRelics = 28;
extern const int cStrategyFlagManageOracles = 29;
extern const int cStrategyFlagTrainOracles = 30;
extern const int cStrategyFlagAutomaticDropsiteCleanup = 31;
extern const int cStrategyFlagAutomaticPopLimits = 32; // If you set this to false you need to manually set all economy limits + gMaxMilitaryPop.
extern const int cStrategyFlagBuildTitan = 33;
extern const int cStrategyFlagCanResign = 34;
extern const int cStrategyFlagBuildWonder = 35;
extern const int cStrategyFlagConvertVillagerToBerserk = 36;
extern const int cStrategyFlagRebuysGodPowers = 37;
extern const int cStrategyFlagScoutWithStartingTransport = 38;
extern const int cStrategyFlagAutomaticFortressRepair = 39;
extern const int cStrategyFlagAutomaticBuildingRepair = 40;
// If you add a flag here then also update strategy.displayStrategyInformation

//==============================================================================
// Location consts.
//==============================================================================
extern vector[] gDegrees = default;
extern const vector cDegrees0 = vector(1.0, 0.0, 0.0);
extern const vector cDegrees45 = vector(0.707107, 0.0, 0.707107);
extern const vector cDegrees90 = vector(0.0, 0.0, 1.0);
extern const vector cDegrees135 = vector(-0.707107, 0.0, 0.707107);
extern const vector cDegrees180 = vector(-1.0, 0.0, 0.0);
extern const vector cDegrees225 = vector(-0.707107, 0.0, -0.707107);
extern const vector cDegrees270 = vector(0.0, 0.0, -1.0);

// v1.6.2: Adaptive learning forward declarations (used by military_attack.xs before adaptive_learning.xs is included)
extern int  gAdaptAttackIntervalBonus        = 0;
extern int  gAdaptMinAttackSizeBonus         = 0;
extern bool gAdaptAttackInProgress           = false;
extern int  gAdaptAttackFailed               = 0;
extern int  gAdaptAttackLaunched             = 0;
extern int  gAdaptLastWaveStartPop           = 0;
extern int  gAdaptAttackEnemyBuildingsAtStart = 0;

// v1.7: Counter detekce - pomer typu jednotek v nepritels utocici armade (blizko nasi zakladny)
extern float gAdaptEnemyAttackRangedRatio = 0.0; // pomer lucisniku/dalkovych v utoku
extern float gAdaptEnemyAttackMeleeRatio  = 0.0; // pomer melee pesoty v utoku
extern float gAdaptEnemyAttackMythRatio   = 0.0; // pomer mytickych jednotek v utoku
extern float gAdaptEnemyAttackSiegeRatio  = 0.0; // pomer oblehacich zbrani v utoku

// v2.5: ID ciloveho hrace pri zahajeni utoku - pouzito v adaptiveAttackResultMonitor pro spravne vyhodnoceni
// BUG31: aiGetMostHatedPlayerID() se muze zmenit behem utoku (cil eliminovan/prepnut v FFA)
// Reseni: ulozit ID cile pri spusteni a pouzit ho pri vyhodnoceni - ne aktualne nenavideho hrace
extern int gAdaptTrackTargetPlayerID = -1;

extern const vector cDegrees315 = vector(0.707107, 0.0, -0.707107);