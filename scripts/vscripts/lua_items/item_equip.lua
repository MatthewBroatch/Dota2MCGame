
slots = {}
slots["main-hand"]=0
slots["off-hand"]=1
slots["head"]=2
slots["cape"]=3
slots["body"]=4
slots["feat"]=5 

function tell_panormana_item_equip( event )
  if IsServer() then
    local data = {}
    data["ItemName"] = event.ability:GetAbilityName()
    data["Slot"] = event.Slot
    data["Consumable"] = event.Consumable
    data["ActiveModifier"] = event.ActiveModifier
    data["PassiveModifier"] = event.PassiveModifier
    CustomGameEventManager:Send_ServerToPlayer( event.caster:GetPlayerOwner(), "hero_picked_up_item", data )
    event.caster:RemoveItem(event.ability)
  end
end

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      -- tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      print(formatting .. tostring(v))      
    else
      print(formatting .. v)
    end
  end
end