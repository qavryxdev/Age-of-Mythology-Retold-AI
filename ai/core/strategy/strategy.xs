extern const int cStrategyArchaic = cStrategyDefault;
extern const int cStrategyStartupBO = 1;
extern const int cStrategyClassical = 2;
extern const int cStrategyHeroic = 3;
extern const int cStrategyMythic = 4;
extern const int cStrategyWonder = 5;
extern const int cStrategyScenarioAttackWave = 7;
extern const int cStrategyInactive = 8;
extern const int cStrategySPCCustom = 9;
extern const int cStrategyClassicalRusher = 10;
extern const int cStrategyClassicalTurtler = 11;
extern const int cStrategyHeroicTurtler = 12;
extern const int cStrategyMythicTurtler = 13;
extern const int cStrategyMigrateMainBase = 14;
extern const int cStrategyNomad = 15;

extern const bool cStrategyContinue = true;
extern const bool cStrategyEnd = false;

extern Strategy gStartupBOStrategy;
extern Strategy gArchaicStrategy;
extern Strategy gClassicalStrategy;
extern Strategy gHeroicStrategy;
extern Strategy gMythicStrategy;
extern Strategy gWonderStrategy;

extern Strategy gClassicalRusherStrategy;
extern Strategy gClassicalTurtlerStrategy;
extern Strategy gHeroicTurtlerStrategy;
extern Strategy gMythicTurtlerStrategy;

extern Strategy gMigrateMainBase;
extern Strategy gNomadStrategy;

extern void() gStartupBOArchaic = []() {};
extern void() gStartupBOClassical = []() {};