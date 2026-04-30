//==============================================================================
/* core.xs

   This file includes all other files in the core folder, and will be included
   by main.xs.

*/
//==============================================================================

//==============================================================================
// Function forward declarations.
//==============================================================================
// Used in loader file to override default values, called at start of main().
mutable void preInit() {}

// Used in loader file to override initialization decisions, called at end of main().
mutable void postInit() {}

// Strategy.
mutable bool checkStrategyFlag(int flag = 0) { return false; }
mutable int getStrategyTowerAmount() { return 0; }
mutable int getStrategyWallCircleAmount() { return 0; }

// BO.
mutable bool isBuildOrderDone() { return true; }

// Economy
mutable void alertRanOutOfFoodResources() {}
mutable void alertFoundFoodResources() {}

//==============================================================================
// Includes.
//==============================================================================
include "core/utilities/debug.xs";
include "core/globals.xs";
include "core/globals_override.xs";
include "core/utilities/unit_queries.xs";
include "core/utilities/utilities.xs";
include "core/buildings/dropsite_placement.xs";
include "core/buildings/utilities_buildings.xs";
include "core/startup/startup_flow.xs";
include "core/buildings/buildings.xs";
include "core/buildings/buildings_economic.xs";
include "core/economy/resource_breakdown_system.xs";
include "core/godpowers/godpowers_utility.xs";
include "core/godpowers/godpowers_greek.xs";
include "core/godpowers/godpowers_egyptian.xs";
include "core/godpowers/godpowers_norse.xs";
include "core/godpowers/godpowers_atlantean.xs";
include "core/godpowers/godpowers.xs";
include "core/military/military_attack.xs";
include "core/military/military_defend.xs";
include "core/military/military_units.xs";
include "core/military/naval_military.xs";
include "core/military/naval_military_units.xs";
include "core/economy/trade.xs";
include "core/techs.xs";
include "core/economy/economy.xs";
include "core/exploration.xs";
include "core/bo_system/bo_system_internal_steps.xs";
include "core/bo_system/bo_system_internal.xs";
include "core/bo_system/bo_system_dm.xs";
include "core/bo_system/bo_system.xs";
include "core/strategy/strategy_internal.xs";
include "core/strategy/strategy.xs";
include "core/chats.xs";

// Shared
include "core/shared/archaic/archaic_default_strategy.xs";
include "core/shared/classical/classical_default_strategy.xs";
include "core/shared/heroic/heroic_default_strategy.xs";
include "core/shared/mythic/mythic_default_strategy.xs";
include "core/shared/wonder/wonder_default_strategy.xs";
include "core/shared/migrate_main_base.xs";
include "core/shared/archaic/nomad_strategy.xs";
// Culture specific includes
// Greek
include "core/greek/archaic/greek_archaic.xs";
include "core/greek/classical/greek_classical.xs";
include "core/greek/greek_dm.xs";
// Egyptian
include "core/egyptian/egyptian_archaic.xs";
include "core/egyptian/egyptian_classical.xs";
include "core/egyptian/egyptian_dm.xs";
// Norse
include "core/norse/archaic/norse_archaic.xs";
include "core/norse/classical/norse_classical.xs";
include "core/norse/norse_dm.xs";
// Atlantean
include "core/atlantean/atlantean_archaic.xs";
include "core/atlantean/atlantean_classical.xs";
include "core/atlantean/atlantean_dm.xs";

include "core/scenario/scenario_library.xs";
include "core/setup.xs";
include "core/scenario/scenario_attack_wave_strategy.xs";

include "core/handlers.xs";
include "core/bo_system/bo_system_internal_handler.xs";

// v1.1: Adaptivni system uceni - musi byt jako posledni (potrebuje vsechny globaly)
include "core/adaptive_learning.xs";

// v3.0: AI improvements - 10 systemovych vylepseni nad ramec adaptive_learning
// Musi byt po adaptive_learning protoze ctie jeho globaly.
include "core/ai_improvements.xs";

// v3.1: Druhe kolo vylepseni (#11-20: wonder defense, target value, scout retreat,
// naval threat, idle villager, GP target, caravan block, multi-front, perimeter, woodline)
include "core/ai_improvements_v31.xs";

// v3.2: Treti kolo (#21-30: anti-myth focus, resource overflow, wall breach, settlement reactivity,
// auto-trade, fishing rebuild, titan strategy, relic competition, garrison, enemy god reactions)
include "core/ai_improvements_v32.xs";

// v3.3: Ctvrte kolo (#31-40: pop cap cascading, friendly fire awareness, build queue reprio,
// eco-mil sliding, tech race, priest conversion, ranged kiting, choke detection, fortress, scout sacrifice)
include "core/ai_improvements_v33.xs";

// v3.4: BUG FIX - AI uveznena na startovnim ostrove (force naval logic kdyz vsichni enemy
// jsou na jinem area group)
include "core/ai_improvements_v34.xs";

// v3.5: Multi-hop island chain - BFS pres area group graph, intermediate expansion
// pro archipelagos (land-water-land-water-land scenare)
include "core/ai_improvements_v35.xs";

// v3.6: Pate kolo (#41-50: hero promo, starvation recovery, repair priority,
// counter-rush eco crisis, pharaoh rotation, tech queue resolver, batch garrison,
// berserk swap, ceasefire boom, endgame race detection)
include "core/ai_improvements_v36.xs";

// v3.7: Seste kolo (#51-60: hero death, favor velocity, dock cleanup, island sequencing,
// mythic counter, brittleness, spell placement, forward base, civ bonuses, raid scanner)
include "core/ai_improvements_v37.xs";

// v3.8: Sedme kolo META-LEVEL (#61-70: rule interference, throttling, endgame state machine,
// hoarding, GP sequencing, tempo classifier, anti-cheese, ally coord, retreat, chat triggers)
include "core/ai_improvements_v38.xs";