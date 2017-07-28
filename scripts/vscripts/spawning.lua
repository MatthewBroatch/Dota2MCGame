unit_tables_roam = require( "unit_tables_roam" )
tSPAWNERS_ALL = {}
--------------------------------------------------------------------------------
-- PrecacheSpawners
--------------------------------------------------------------------------------
function mastercrafters:PrecacheSpawners( context )	
	for _, tSpawnType in pairs( unit_tables_roam ) do
		for _, unitName in pairs( tSpawnType.unitNames ) do
			PrecacheUnitByNameSync( unitName, context )
		end
	end
end

--------------------------------------------------------------------------------
-- SetupSpawners
--------------------------------------------------------------------------------
function mastercrafters:SetupSpawners()
	print("SetupSpawners")
	for name, unitTable in pairs( unit_tables_roam ) do
		local spawners = Entities:FindAllByName( name.."*" )
		PrintTable( spawners, "  " )
		table.insert( tSPAWNERS_ALL, { spawners = spawners, unitTable = unitTable } )
	end
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( mastercrafters, "OnEntityKilled_Spawner" ), self )
end

--------------------------------------------------------------------------------
-- OnEntityKilled_Spawner
--------------------------------------------------------------------------------
function mastercrafters:OnEntityKilled_Spawner( event )
	hDeadUnit = EntIndexToHScript( event.entindex_killed )

	if hDeadUnit.hSpawner ~= nil then
		-- Use the creature's entindex to create a unique thinker for it that gets called on the world (since the dead creature will get destroyed)
		local sCreatureName = hDeadUnit:GetUnitName()
		local hSpawner = hDeadUnit.hSpawner
		local sState = hDeadUnit.sState
		local itemTable = hDeadUnit.itemTable
		self._GameMode:SetContextThink( string.format( "CreatureThink_%d", event.entindex_killed ), function() return self:Think_RespawnCreature( sCreatureName, hSpawner, sState, itemTable ) end, nCREATURE_RESPAWN_TIME )
	end
end

--------------------------------------------------------------------------------
-- Think_RespawnCreature
--------------------------------------------------------------------------------
function mastercrafters:Think_RespawnCreature( sCreatureName, hSpawner, sState, itemTable )
	self:SpawnUnit( sCreatureName, nNEUTRAL_TEAM, hSpawner, sState, nil, nil, nROAMER_MAX_DIST_FROM_SPAWN, itemTable )
end

--------------------------------------------------------------------------------
-- SpawnCreatures
--------------------------------------------------------------------------------
function mastercrafters:SpawnCreatures()
	for _, spawnerInfo in pairs( tSPAWNERS_ALL ) do
		local unitTable = spawnerInfo.unitTable
		for _, hSpawner in pairs( spawnerInfo.spawners ) do
			local nUnitCount = RandomInt( unitTable.minCount, unitTable.maxCount )
			for k = 1, nUnitCount do
				local sUnitName = GetRandomElement( unitTable.unitNames )
				local hUnit = self:SpawnUnit( sUnitName, nNEUTRAL_TEAM, hSpawner, "RoamState", nil, nil, unitTable.maxDistanceFromSpawn, unitTable.itemTable )
			end
		end
	end
end

--------------------------------------------------------------------------------
-- SpawnUnit
--------------------------------------------------------------------------------
function mastercrafters:SpawnUnit( sUnitName, nTeam, hSpawner, sUnitState, hInitialWaypoint, bKeepDefaultAcqRng, nMaxDistanceFromSpawner, itemTable )
	if sUnitName == nil then
		-- handle nil unitname passed
	end

	if nTeam == nil then
		nTeam = nNEUTRAL_TEAM
	end

	if hSpawner == nil then
		-- find a decent spawn location
	end

	local vSpawnLoc = nil
	local retrys = 100;
	while vSpawnLoc == nil do
		vSpawnLoc = hSpawner:GetOrigin() + RandomVector( RandomFloat( 0, nMaxDistanceFromSpawner ) )
		if ( GridNav:CanFindPath( hSpawner:GetOrigin(), vSpawnLoc ) == false ) then
			retrys = retrys - 1;
			print( "Choosing new unit spawnloc.  Bad spawnloc was: " .. tostring( vSpawnLoc ) )
			vSpawnLoc = nil
		end
		if retrys <= 0 then
			break
		end
	end
	if retrys <= 0 then
		print( "Failed to find location" )
		return
	end
	-- Actually make the unit
	local hUnit = CreateUnitByName( sUnitName, vSpawnLoc, true, nil, nil, nTeam )
	hUnit.hSpawner = hSpawner

	if sUnitState == nil then
		hUnit.sState = "RoamState"
	else
		hUnit.sState = sUnitState
	end

	if hInitialWaypoint == nil then
		-- handle nil waypoint passed
	end

	if bKeepDefaultAcqRng == nil then
    	hUnit.bKeepDefaultAcquisitionRange = false
    else
		hUnit.bKeepDefaultAcquisitionRange = bKeepDefaultAcqRng
	end

	local nWaypointSearchRadius = 1000
    if sUnitState == "PatrolState" and hUnit.hInitialWaypoint == nil then
        hUnit.hInitialWaypoint = Entities:FindByClassnameNearest( "path_corner", hSpawner:GetOrigin(), nWaypointSearchRadius )
        if hUnit.hInitialWaypoint == nil then
        	print( "Couldn't find a path_corner within " .. nWaypointSearchRadius .. " units of " .. hUnit:GetUnitName() )
        end
    end

    hUnit.itemTable = itemTable

    return hUnit
end
