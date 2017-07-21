--[[ Events ]]

--------------------------------------------------------------------------------
-- GameEvent:OnGameRulesStateChange
--------------------------------------------------------------------------------
function CRPGExample:OnGameRulesStateChange()
	local nNewState = GameRules:State_Get()

	if nNewState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		print( "OnGameRulesStateChange: Custom Game Setup" )
		GameRules:SetTimeOfDay( 0.25 )
		SendToServerConsole( "dota_daynightcycle_pause 1" )
		for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS do
			PlayerResource:SetCustomTeamAssignment( nPlayerID, 2 ) -- put each player on Radiant team

			self:OnLoadAccountRecord( nPlayerID )
		end

	elseif nNewState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		print( "OnGameRulesStateChange: Hero Selection" )

	elseif nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
		print( "OnGameRulesStateChange: Pre Game" )

	elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		print( "OnGameRulesStateChange: Game In Progress" )

	end
end

--------------------------------------------------------------------------------
-- GameEvent: OnNPCSpawned
--------------------------------------------------------------------------------
function CRPGExample:OnNPCSpawned( event )

end

--------------------------------------------------------------------------------
-- GameEvent: OnEntityKilled
--------------------------------------------------------------------------------
function CRPGExample:OnEntityKilled( event )
	hDeadUnit = EntIndexToHScript( event.entindex_killed )
	hAttackerUnit = EntIndexToHScript( event.entindex_attacker )

	if hDeadUnit:IsCreature() then
		self:PlayDeathSound( hDeadUnit )
		self:GrantItemDrop( hDeadUnit )

		if hAttackerUnit.PlayKillEffect ~= nil then
			hAttackerUnit:PlayKillEffect( hDeadUnit )
		end
	end
end

--------------------------------------------------------------------------------
-- GrantItemDrop
--------------------------------------------------------------------------------
function CRPGExample:GrantItemDrop( hDeadUnit )
	if hDeadUnit.itemTable == nil then
		return
	end

	local flMaxHeight = RandomFloat( 300, 450 )

	if RandomFloat( 0, 1 ) > 0.6 then
		local sItemName = GetRandomElement( hDeadUnit.itemTable )
		self:LaunchWorldItemFromUnit( sItemName, flMaxHeight, 0.5, hDeadUnit )
	end
end

--------------------------------------------------------------------------------
-- PlayDeathSound
--------------------------------------------------------------------------------
function CRPGExample:PlayDeathSound( hDeadUnit )
	if hDeadUnit:GetUnitName() == "npc_dota_creature_zombie" or hDeadUnit:GetUnitName() == "npc_dota_creature_zombie_crawler" then
		EmitSoundOn( "Zombie.Death", hDeadUnit )

	elseif hDeadUnit:GetUnitName() == "npc_dota_creature_bear" then
		EmitSoundOn( "Bear.Death", hDeadUnit )

	elseif hDeadUnit:GetUnitName() == "npc_dota_creature_bear_large" then
		EmitSoundOn( "BearLarge.Death", hDeadUnit )

	end
end

--------------------------------------------------------------------------------
-- GameEvent: OnPlayerGainedLevel
--------------------------------------------------------------------------------
function CRPGExample:OnPlayerGainedLevel( event )
	local hPlayer = EntIndexToHScript( event.player )
	local hPlayerHero = hPlayer:GetAssignedHero()

	hPlayerHero:SetHealth( hPlayerHero:GetMaxHealth() )
	hPlayerHero:SetMana( hPlayerHero:GetMaxMana() )
end

function CRPGExample:OnItemPickedUp( event )
	local hPlayerHero = EntIndexToHScript( event.HeroEntityIndex )
	EmitGlobalSound( "ui.inv_equip_highvalue" )
end

--------------------------------------------------------------------------------
-- GameEvent: OnSaveAccountRecord
--------------------------------------------------------------------------------
function CRPGExample:OnSaveAccountRecord( nPlayerID )

	print( "OnSaveAccountRecord: " .. nPlayerID );

	return self._tPlayerIDToAccountRecord[nPlayerID]
end

function CRPGExample:RecordActivatedCheckpoint( nPlayerID, strCheckpoint )
	tblAccountRecord = {}
	if self._tPlayerIDToAccountRecord[nPlayerID] then
		tblAccountRecord = self._tPlayerIDToAccountRecord[nPlayerID]
	else
		self._tPlayerIDToAccountRecord[nPlayerID] = tblAccountRecord
	end

	if not tblAccountRecord["checkpoints"] then
		tblAccountRecord["checkpoints"] = strCheckpoint
	else
		tblAccountRecord["checkpoints"] = tblAccountRecord["checkpoints"] .. "," .. strCheckpoint
	end
end

function CRPGExample:OnLoadAccountRecord( nPlayerID )
	local tblAccountRecord = GameRules:GetPlayerCustomGameAccountRecord( nPlayerID )
	if not tblAccountRecord then
		return
	end

	print( "OnLoadAccountRecord: " .. nPlayerID );

	-- Store off their account record, if found, we may be changing/saving it later
	if tblAccountRecord then
		PrintTable( tblAccountRecord, " " )
		self._tPlayerIDToAccountRecord[nPlayerID] = tblAccountRecord
	end
end

---------------------------------------------------------------------------
-- Increase Hero Stat
---------------------------------------------------------------------------
function CRPGExample:IncreaseHeroStat( keys )
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
		self:GetUnitStats(nil, data)
	end
end

---------------------------------------------------------------------------
-- Get Unit Stats
---------------------------------------------------------------------------
function CRPGExample:GetUnitStats( keys )
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
