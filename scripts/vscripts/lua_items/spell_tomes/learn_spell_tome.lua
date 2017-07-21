function learn_spell_on_spell_start( event )
    if IsServer() then
        CustomGameEventManager:Send_ServerToPlayer( event.caster:GetPlayerOwner(), "hero_learns_spell", event )
    end
end

-- function learn_spell_on_spell_start( event )
--     -- Add the ability
--     event.caster:AddAbility(event.SpellName)
--      -- Get the handle and level it up if possible
--     local ability = event.caster:FindAbilityByName(event.SpellName) 
--     if ability then
--         local MaxLevel = ability:GetMaxLevel()
--         ability:SetLevel( MaxLevel )
--     end
-- end