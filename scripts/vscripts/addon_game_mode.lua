---------------------------------------------------------------------------
if mastercrafters == nil then
    _G.mastercrafters = class({})
end
---------------------------------------------------------------------------

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
-- Required .lua files, which just exist to help organize functions contained in our addon.  Make sure to call these beneath the mode's class creation.
------------------------------------------------------------------------------------------------------------------------------------------------------
-- require( "utility_functions" ) -- require utility_functions first since some of the other required files may use its functions
-- require( "events" )
-- require( "rpg_example_spawning" )
-- require( "worlditem_spawning" )
require( 'libraries/timers' )
require( 'libraries/notifications' )
require( 'libraries/animations' )
require( 'libraries/attributes' )
require( 'libraries/attachments' )
-- require( "libraries/modifiers/modifier_strength_increase" )

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Precache files and folders
------------------------------------------------------------------------------------------------------------------------------------------------------
function Precache( context )
	GameRules.mastercrafters = mastercrafters()
	-- GameRules.rpg_example:PrecacheSpawners( context )
	-- GameRules.rpg_example:PrecacheItemSpawners( context )
	PrecacheUnitByNameSync("npc_dota_hero_lina", context)
	PrecacheUnitByNameSync("npc_dota_hero_omniknight", context)

	PrecacheResource( "soundfile", "soundevents/game_sounds_main.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_triggers.vsndevts", context )
end

--------------------------------------------------------------------------------
-- Activate RPGExample mode
--------------------------------------------------------------------------------
function Activate()
	-- When you don't have access to 'self', use 'GameRules.mastercrafters' instead
		-- example Function call: GameRules.mastercrafters:Function()
		-- example Var access: GameRules.mastercrafters.m_Variable = 1
		GameRules.mastercrafters = mastercrafters()
    GameRules.mastercrafters:InitGameMode()
end

XP_PER_LEVEL_TABLE = {
	0
}

HIDDEN_HEROS = {}

--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------
function mastercrafters:InitGameMode()
	print( "Entering mastercrafters:InitGameMode" )
	
	exp = 0;
	for i = 1, 500 do
		exp = exp + (i*100)
		XP_PER_LEVEL_TABLE[i] = exp
	end

	GameRules:SetStrategyTime( 0 )
	GameRules:SetCustomGameSetupTimeout( -1 ) -- skip the custom team UI with 0, or do indefinite duration with -1
	GameRules:SetCustomGameSetupAutoLaunchDelay( 0 )
	GameRules:SetHeroRespawnEnabled( true )
	GameRules:SetUseUniversalShopMode( false )
	GameRules:SetSameHeroSelectionEnabled( true )
	GameRules:SetHeroSelectionTime( 0 )
	GameRules:SetPreGameTime( 1 )
	GameRules:SetPostGameTime( 9001 )
	GameRules:SetTreeRegrowTime( 10000.0 )
	GameRules:SetUseCustomHeroXPValues ( true )
	GameRules:SetGoldPerTick(0)
	GameRules:SetUseBaseGoldBountyOnHeroes( false ) -- Need to check legacy values
	GameRules:SetHeroMinimapIconScale( 1 )
	GameRules:SetCreepMinimapIconScale( 1 )
	GameRules:SetRuneMinimapIconScale( 1 )
	GameRules:SetFirstBloodActive( false )
	GameRules:SetHideKillMessageHeaders( true )
	GameRules:EnableCustomGameSetupAutoLaunch( false )

	-- Set game mode rules
	GameMode = GameRules:GetGameModeEntity()  
	GameMode:SetUnseenFogOfWarEnabled( true )
	GameMode:SetFixedRespawnTime( 4 )
	GameMode:SetRecommendedItemsDisabled( true )
	GameMode:SetBuybackEnabled( false )
	GameMode:SetTopBarTeamValuesOverride ( true )
	GameMode:SetTopBarTeamValuesVisible( true )
	GameMode:SetTowerBackdoorProtectionEnabled( false )
	GameMode:SetGoldSoundDisabled( false )
	GameMode:SetAnnouncerDisabled( true )
	GameMode:SetLoseGoldOnDeath( false )
	GameMode:SetUseCustomHeroLevels ( true )
	GameMode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )
	GameMode:SetFogOfWarDisabled( false )
	GameMode:SetStashPurchasingDisabled( true )
	GameMode:SetMaximumAttackSpeed( 10000 )
-- GameRules:SetCustomGameAccountRecordSaveFunction( Dynamic_Wrap( mastercrafters, "OnSaveAccountRecord" ), self )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )

	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( mastercrafters, 'OnGameRulesStateChange' ), self )
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( mastercrafters, "OnNPCSpawned" ), self )
	-- ListenToGameEvent( "entity_killed", Dynamic_Wrap( mastercrafters, "OnEntityKilled" ), self )
	-- ListenToGameEvent( "dota_player_gained_level", Dynamic_Wrap( mastercrafters, "OnPlayerGainedLevel" ), self )
	-- ListenToGameEvent( "dota_item_picked_up", Dynamic_Wrap( mastercrafters, "OnItemPickedUp" ), self )
	ListenToGameEvent( 'player_connect_full', Dynamic_Wrap( mastercrafters, 'OnPlayerConnectFull' ), self)
	CustomGameEventManager:RegisterListener('increase_hero_stat', IncreaseHeroStat)
	CustomGameEventManager:RegisterListener('get_unit_stats', GetUnitStats)
	CustomGameEventManager:RegisterListener('learn_ability', LearnSpell)
	CustomGameEventManager:RegisterListener('unlearn_ability', UnlearnSpell)
	CustomGameEventManager:RegisterListener('drop_item', DropItem)
	CustomGameEventManager:RegisterListener('activate_modifier', ActivateModifier)
	CustomGameEventManager:RegisterListener('remove_modifier', RemoveModifier)
	CustomGameEventManager:RegisterListener('attach_prop', AttachProp)
	CustomGameEventManager:RegisterListener('remove_prop', RemoveProp)
	CustomGameEventManager:RegisterListener('create_hero', CreateHero)
	-- self._tPlayerHeroInitStatus = {}	
	-- self._tPlayerDeservesTPAtSpawn = {}	
	-- self._tPlayerIDToAccountRecord = {}


	-- for nPlayerID = 0, DOTA_MAX_PLAYERS do
	-- 	self._tPlayerHeroInitStatus[ nPlayerID ] = false
	-- 	self._tPlayerDeservesTPAtSpawn[ nPlayerID ] = false
	-- end

	-- self:SetupSpawners()
	-- self:SetupItemSpawners()
	-- self._GameMode:SetContextThink( "mastercrafters:GameThink", function() return self:GameThink() end, 0 )
end

function mastercrafters:OnGameRulesStateChange(keys)
    local newState = GameRules:State_Get()

    print("[MASTERCRAFTERS] GameRules State Changed: ", newState)
    -- UI:GameStateManager(newState) -- ui game state manager
    if newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
				print( "OnGameRulesStateChange: Custom Game Setup" )
				GameRules:SetTimeOfDay( 0.25 )
				SendToServerConsole( "dota_daynightcycle_pause 1" )
				for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS do
					PlayerResource:SetCustomTeamAssignment( nPlayerID, 2 ) -- put each player on Radiant team

					-- self:OnLoadAccountRecord( nPlayerID )
				end
    elseif newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
			print("DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP")
        -- Scores:Init() -- Start score tracking for all players
    elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
			print("DOTA_GAMERULES_STATE_PRE_GAME")
        -- mastercrafters:OnPreGame()  --TODO: Fix staging
    elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
			print("DOTA_GAMERULES_STATE_GAME_IN_PROGRESS")
        -- mastercrafters:OnGameInProgress()
    end
end

--------------------------------------------------------------------------------
-- Main Think
--------------------------------------------------------------------------------
function mastercrafters:GameThink()
	local flThinkTick = 0.2

	return flThinkTick
end


-- An NPC has spawned somewhere in game.  This includes heroes
function mastercrafters:OnNPCSpawned(keys)
	local npc = EntIndexToHScript(keys.entindex)

	if npc:IsHero() then
		npc.strBonus = 0
		npc.intBonus = 0
		npc.agilityBonus = 0
		npc.attackspeedBonus = 0
	end

	if npc:IsRealHero() and npc.bFirstSpawned == nil then
		npc.bFirstSpawned = true
		local playerID = npc:GetPlayerID()
		if(HIDDEN_HEROS[playerID] == nil) then
			HIDDEN_HEROS[playerID] = true;
			npc:RemoveSelf()
			return
		end

		Attributes:ModifyBonuses(npc)
		npc:SetGold(100, false)
		for i,child in ipairs(npc:GetChildren()) do
			if child:GetClassname() == "dota_item_wearable" and child:GetModelName() ~= "models/heroes/omniknight/head.vmdl" then
				child:RemoveSelf()
			end
		end
	end
end

---------------------------------------------------------------------------
-- Pick hero
---------------------------------------------------------------------------
function mastercrafters:OnThink()
    -- Reconnect heroes
    for _,hero in pairs( Entities:FindAllByClassname( "npc_dota_hero_omniknight")) do
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

function mastercrafters:OnPlayerConnectFull(keys)
    local player = PlayerInstanceFromIndex(keys.index + 1)
    print("Creating hero.")
    local hero = CreateHeroForPlayer('npc_dota_hero_omniknight', player)
		-- for i,child in ipairs(hero:GetChildren()) do
		-- 	if child:GetClassname() == "dota_item_wearable" then
		-- 		print(child:GetModelName())
		-- 		child:RemoveSelf()
		-- 	end
		-- end
end

function CreateHero( _, keys )
    print("Creating hero.")
    local player = PlayerInstanceFromIndex(keys.player)
    -- local hero = CreateHeroForPlayer('npc_dota_hero_omniknight', player)
		-- local hiddenHero = HIDDEN_HEROS[keys.player]
		-- local origin = hiddenHero:GetOrigin()
		-- hero:SetOrigin(origin)
		-- hiddenHero:RemoveSelf()
end


---------------------------------------------------------------------------
-- Increase Hero Stat
---------------------------------------------------------------------------
function IncreaseHeroStat( _, keys )
	if(IsServer()) then
		local npc = EntIndexToHScript( keys.hero )
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
		if(npc ~= nil and npc:IsHero()) then
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
	local npc = EntIndexToHScript( keys.unit )
	local doesntKnowAbility = npc:FindAbilityByName( keys.abilityName ) == nil
	print( doesntKnowAbility )
	if doesntKnowAbility then
		print( keys.abilityName )
		npc:AddAbility( keys.abilityName )
		-- Get the handle and level it up if possible
		local ability = npc:FindAbilityByName( keys.abilityName ) 
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
	local npc = EntIndexToHScript( keys.unit )
  npc:RemoveAbility(keys.abilityName)
end

---------------------------------------------------------------------------
-- Drop Item
---------------------------------------------------------------------------
function DropItem( _, keys )
	local npc = EntIndexToHScript( keys.unit )
	GameRules.mastercrafters:LaunchWorldItemFromUnit( keys.itemName, 200, 1, npc )
end
function mastercrafters:LaunchWorldItemFromUnit( sItemName, flLaunchHeight, flDuration, hUnit )
	local newItem = CreateItem( sItemName, nil, nil )
	local newWorldItem = CreateItemOnPositionSync( hUnit:GetOrigin(), newItem )
	newItem:LaunchLoot( false, flLaunchHeight, flDuration, hUnit:GetOrigin() + RandomVector( RandomFloat( 200, 300 ) ) )
	print( "Launching " .. newItem:GetName() .. " near " .. hUnit:GetUnitName() )
	GameRules:GetGameModeEntity():SetContextThink( "mastercrafters:Think_PlayItemLandSound", function() return self:Think_PlayItemLandSound() end, flDuration )
end
function mastercrafters:Think_PlayItemLandSound()
	EmitGlobalSound( "ui.inv_drop_highvalue" )
end

---------------------------------------------------------------------------
-- Activate Modifier
---------------------------------------------------------------------------
function ActivateModifier( _, keys )
	local npc = EntIndexToHScript( keys.unit )
	local item = CreateItem( keys.abilityName, npc, npc )
	if(npc:FindModifierByName( keys.modifierName ) == nil) then
		item:ApplyDataDrivenModifier( npc, npc, keys.modifierName, nil )
	end
end

---------------------------------------------------------------------------
-- Remove Modifier
---------------------------------------------------------------------------
function RemoveModifier( _, keys )
	local npc = EntIndexToHScript( keys.unit )
	if(npc:FindModifierByName( keys.modifierName ) ~= nil) then
		npc:RemoveModifierByName( keys.modifierName )
	end
end

---------------------------------------------------------------------------
-- Props
---------------------------------------------------------------------------
function AttachProp( _, keys )
	local npc = EntIndexToHScript( keys.unit )
	Attachments:AttachProp(npc, keys.attach, keys.model, 1.0)
end

function RemoveProp( _, keys )
	local npc = EntIndexToHScript( keys.unit )
	local prop = Attachments:GetCurrentAttachment(npc, keys.attach, keys.model)
	if(prop ~= nil) then
		prop:RemoveSelf() 
	end
end