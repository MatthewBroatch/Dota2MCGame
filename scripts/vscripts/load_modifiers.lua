print( "Entering load_modifiers.lua file." )

require( "libraries/modifiers/modifier_strength_increase" )

function CRPGExample:LoadModifiers()
  print( "Loading modifiers" )
	LinkLuaModifier( "modifier_strength_increase", LUA_MODIFIER_MOTION_NONE )
end
