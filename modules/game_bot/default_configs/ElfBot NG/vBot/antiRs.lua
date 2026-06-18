setDefaultTab("Tools")

local function safeCancelAttackAndFollow()
  if g_game and g_game.cancelAttack then
    g_game.cancelAttack()
  end

  if g_game and g_game.cancelFollow then
    g_game.cancelFollow()
  end
end

safeCancelAttackAndFollow()

local frags = 0
local unequip = false
local m = macro(50, "AntiRS & Msg", function() end)

function safeExit()
  if CaveBot and CaveBot.setOff then
    CaveBot.setOff()
  end

  if TargetBot and TargetBot.setOff then
    TargetBot.setOff()
  end

  safeCancelAttackAndFollow()
  schedule(100, safeCancelAttackAndFollow)
  schedule(200, safeCancelAttackAndFollow)

  modules.game_interface.forceExit()
end

onTextMessage(function(mode, text)
  if not m.isOn() then return end
  if not text:find("Warning! The murder of") then return end

  frags = frags + 1

  if killsToRs() < 6 or frags > 1 then
    if EquipManager and EquipManager.setOff then
      EquipManager.setOff()
    end

    schedule(100, function()
      local id = getLeft() and getLeft():getId()

      if id and not unequip then
        unequip = true
        g_game.equipItemId(id)
      end

      safeExit()
    end)
  end
end)
