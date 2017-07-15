print( "Entering modifier_strength_increase.lua file." )

modifier_strength_increase = class({})
 
function modifier_strength_increase:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    }
    return funcs
end

function modifier_strength_increase:GetModifierBonusStats_Strength()
	if IsServer() then
		local hero = self:GetParent()
		hero:ModifyStrength(hero:GetStrength()+1)
    return self:GetStackCount()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- function modifier_strength_increase:IsDebuff()
-- 	return false
-- end

-- function modifier_strength_increase:IsHidden()
--     return false
-- end