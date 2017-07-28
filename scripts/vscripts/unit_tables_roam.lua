--[[ Roam types and their units ]]
local tITEMS_ALL = require( "item_tables" )

--------------------------------------------------------------------------------
-- Camp lists for each roamer group type
--------------------------------------------------------------------------------
local kMIN_CAMP_COUNT = 10
local kMAX_CAMP_COUNT = 10
local nROAMER_MAX_DIST_FROM_SPAWN = 2048

--------------------------------------------------------------------------------
-- All roamer lists
--------------------------------------------------------------------------------
return {
	water_spirit_spawn = {
		unitNames = { "npc_dota_creature_water_spirit" },
		minCount = kMIN_CAMP_COUNT, maxCount = kMAX_CAMP_COUNT,
		maxDistanceFromSpawn = nROAMER_MAX_DIST_FROM_SPAWN,
		itemTable = tITEMS_ALL.worlditems_tier01
	},
}
