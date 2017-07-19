--[[ rpg_example game mode ]]

print( "Entering rpg_example's addon_game_mode.lua file." )

--------------------------------------------------------------------------------
-- Integer constants
--------------------------------------------------------------------------------
_G.nGOOD_TEAM = 2
_G.nBAD_TEAM = 3
_G.nNEUTRAL_TEAM = 4
_G.nDOTA_MAX_ABILITIES = 16
_G.nHERO_MAX_LEVEL = 25

_G.nROAMER_MAX_DIST_FROM_SPAWN = 2048
_G.nCAMPER_MAX_DIST_FROM_SPAWN = 256
_G.nPATROLLER_MAX_DIST_FROM_SPAWN = 128
_G.nBOSS_MAX_DIST_FROM_SPAWN = 0
_G.nCREATURE_RESPAWN_TIME = 60

------------------------------------------------------------------------------------------------------------------------------------------------------
-- RPGExample class
------------------------------------------------------------------------------------------------------------------------------------------------------
if CRPGExample == nil then
	_G.CRPGExample = class({}) -- put CRPGExample in the global scope
	--refer to: http://stackoverflow.com/questions/6586145/lua-require-with-global-local
end

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Required .lua files, which just exist to help organize functions contained in our addon.  Make sure to call these beneath the mode's class creation.
------------------------------------------------------------------------------------------------------------------------------------------------------
require( "utility_functions" ) -- require utility_functions first since some of the other required files may use its functions
require( "events" )
require( "rpg_example_spawning" )
require( "worlditem_spawning" )
require( "load_modifiers" )
-- require( "libraries/modifiers/modifier_strength_increase" )

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Precache files and folders
------------------------------------------------------------------------------------------------------------------------------------------------------
function Precache( context )
    GameRules.rpg_example = CRPGExample()
    GameRules.rpg_example:PrecacheSpawners( context )
    GameRules.rpg_example:PrecacheItemSpawners( context )
	PrecacheUnitByNameSync("npc_dota_hero_lina", context)
	PrecacheResource( "particle", "particles/addons_gameplay/player_deferred_light.vpcf", context )
	PrecacheResource( "particle", "particles/hw_fx/hw_rosh_fireball_fire_launch.vpcf", context )

    PrecacheResource( "particle", "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_life_stealer/life_stealer_infest_emerge_bloody.vpcf", context )

	PrecacheResource( "soundfile", "soundevents/game_sounds_main.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_triggers.vsndevts", context )
end

--------------------------------------------------------------------------------
-- Activate RPGExample mode
--------------------------------------------------------------------------------
function Activate()
	-- When you don't have access to 'self', use 'GameRules.rpg_example' instead
		-- example Function call: GameRules.rpg_example:Function()
		-- example Var access: GameRules.rpg_example.m_Variable = 1
    GameRules.rpg_example:InitGameMode()
		GameRules.AddonTemplate = CRPGExample()
    GameRules.AddonTemplate:InitGameMode()
end

--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------
function CRPGExample:InitGameMode()
	print( "Entering CRPGExample:InitGameMode" )
	self._GameMode = GameRules:GetGameModeEntity()

	self._GameMode:SetAnnouncerDisabled( true )
	self._GameMode:SetUnseenFogOfWarEnabled( true )
	self._GameMode:SetFixedRespawnTime( 4 )
	
	GameRules:SetStrategyTime( 0 )
	GameRules:SetHeroSelectionTime( 0.0 )
	GameRules:SetGoldPerTick( 0 )
	GameRules:SetPreGameTime( 0 )
	GameRules:SetCustomGameSetupTimeout( 0 ) -- skip the custom team UI with 0, or do indefinite duration with -1
	GameRules:SetCustomGameSetupAutoLaunchDelay( 0 )
	GameRules:SetCustomGameAccountRecordSaveFunction( Dynamic_Wrap( CRPGExample, "OnSaveAccountRecord" ), self )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )

	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( CRPGExample, 'OnGameRulesStateChange' ), self )
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CRPGExample, "OnNPCSpawned" ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( CRPGExample, "OnEntityKilled" ), self )
	ListenToGameEvent( "dota_player_gained_level", Dynamic_Wrap( CRPGExample, "OnPlayerGainedLevel" ), self )
	ListenToGameEvent( "dota_item_picked_up", Dynamic_Wrap( CRPGExample, "OnItemPickedUp" ), self )
	ListenToGameEvent( 'player_connect_full', Dynamic_Wrap( CRPGExample, 'OnPlayerConnectFull' ), self)
	CustomGameEventManager:RegisterListener('increase_hero_stat', IncreaseHeroStat)
	CustomGameEventManager:RegisterListener('get_unit_stats', GetUnitStats)
	CustomGameEventManager:RegisterListener('learn_ability', LearnSpell)
	CustomGameEventManager:RegisterListener('unlearn_ability', UnlearnSpell)

	-- LinkLuaModifier( "modifier_strength_increase", LUA_MODIFIER_MOTION_NONE )

	self:LoadModifiers()

	self._tPlayerHeroInitStatus = {}	
	self._tPlayerDeservesTPAtSpawn = {}	
	self._tPlayerIDToAccountRecord = {}


	for nPlayerID = 0, DOTA_MAX_PLAYERS do
		self._tPlayerHeroInitStatus[ nPlayerID ] = false
		self._tPlayerDeservesTPAtSpawn[ nPlayerID ] = false
	end

	self:SetupSpawners()
	self:SetupItemSpawners()
	self._GameMode:SetContextThink( "CRPGExample:GameThink", function() return self:GameThink() end, 0 )
end

--------------------------------------------------------------------------------
-- Main Think
--------------------------------------------------------------------------------
function CRPGExample:GameThink()
	local flThinkTick = 0.2

	return flThinkTick
end

---------------------------------------------------------------------------
-- CreateWorldItemOnUnit
---------------------------------------------------------------------------
function CRPGExample:CreateWorldItemOnUnit( sItemName, unit )
    local newItem = CreateItem( sItemName, nil, nil )
	CreateItemOnPositionSync( unit:GetAbsOrigin(), newItem )
end

---------------------------------------------------------------------------
-- CreateWorldItemOnPosition
---------------------------------------------------------------------------
function CRPGExample:CreateWorldItemOnPosition( sItemName, vPos )
    local newItem = CreateItem( sItemName, nil, nil )
	CreateItemOnPositionSync( vPos, newItem )
	print( "Creating item " .. newItem:GetName() .. " on position: " .. tostring( vPos ) )
end

---------------------------------------------------------------------------
-- LaunchWorldItemFromUnit
---------------------------------------------------------------------------
function CRPGExample:LaunchWorldItemFromUnit( sItemName, flLaunchHeight, flDuration, hUnit )
    local newItem = CreateItem( sItemName, nil, nil )
    local newWorldItem = CreateItemOnPositionSync( hUnit:GetOrigin(), newItem )
	newItem:LaunchLoot( false, flLaunchHeight, flDuration, hUnit:GetOrigin() + RandomVector( RandomFloat( 200, 300 ) ) )
	print( "Launching " .. newItem:GetName() .. " near " .. hUnit:GetUnitName() )
	self._GameMode:SetContextThink( "CRPGExample:Think_PlayItemLandSound", function() return self:Think_PlayItemLandSound() end, flDuration )
end

function CRPGExample:Think_PlayItemLandSound()
	EmitGlobalSound( "ui.inv_drop_highvalue" )
end

---------------------------------------------------------------------------
-- Pick hero
---------------------------------------------------------------------------
function CRPGExample:OnThink()
    -- Reconnect heroes
    for _,hero in pairs( Entities:FindAllByClassname( "npc_dota_hero_lina")) do
        if hero:GetPlayerOwnerID() == -1 then
            local id = hero:GetPlayerOwner():GetPlayerID()
            if id ~= -1 then
                print("Reconnecting hero for player " .. id)
                hero:SetControllableByPlayer(id, true)
                hero:SetPlayerID(id)
            end
        end
    end

    -- (Rest of your code)

end

function CRPGExample:OnPlayerConnectFull(keys)
    local player = PlayerInstanceFromIndex(keys.index + 1)
    print("Creating hero.")
    -- local hero = CreateHeroForPlayer('npc_dota_hero_lina', player)
end

---------------------------------------------------------------------------
-- Increase Hero Stat
---------------------------------------------------------------------------
function IncreaseHeroStat( _, keys )
	if(IsServer()) then
		local npc = EntIndexToHScript( keys.hero )
		print("Increase stat: ");
		print(keys.stat);
		npc:SetAbilityPoints(npc:GetAbilityPoints() - 1)
		if(keys.stat == "str") then
			npc:SetBaseStrength(npc:GetBaseStrength() + 1)
		end
		if(keys.stat == "agi") then
			npc:SetBaseAgility(npc:GetBaseAgility() + 1)
		end 
		if(keys.stat == "int") then
			npc:SetBaseIntellect(npc:GetBaseIntellect() + 1)
		end
		npc:CalculateStatBonus()
		local data = {}
		data["unit"] = keys.hero;
		data["player"] = npc:GetPlayerOwnerID();
		GetUnitStats(nil, data)
	end
end

---------------------------------------------------------------------------
-- Get Unit Stats
---------------------------------------------------------------------------
function GetUnitStats( _, keys )
	if(IsServer()) then
		local npc = EntIndexToHScript( keys.unit )
		local stats = {}
		if(npc:IsHero()) then
			stats["baseStr"] = npc:GetBaseStrength()
			stats["baseAgi"] = npc:GetBaseAgility()
			stats["baseInt"] = npc:GetBaseIntellect()
			stats["str"] = npc:GetStrength()
			stats["agi"] = npc:GetAgility()
			stats["int"] = npc:GetIntellect()
		end
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(keys.player), "send_player_stats", stats )
	end
end

---------------------------------------------------------------------------
-- Learn Spell
---------------------------------------------------------------------------
function LearnSpell( _, keys )
  -- Add the ability
	local npc = EntIndexToHScript( keys.unit )
	local doesntKnowAbility = npc:FindAbilityByName(keys.abilityName) == nil
	if doesntKnowAbility then
		npc:AddAbility(keys.abilityName)
		-- Get the handle and level it up if possible
		local ability = npc:FindAbilityByName(keys.abilityName) 
		if ability then
			local MaxLevel = ability:GetMaxLevel()
			ability:SetLevel( MaxLevel )
		end
	end
end

---------------------------------------------------------------------------
-- UnLearn Spell
---------------------------------------------------------------------------
function UnlearnSpell( _, keys )
  -- Add the ability
	local npc = EntIndexToHScript( keys.unit )
  npc:RemoveAbility(keys.abilityName)
end