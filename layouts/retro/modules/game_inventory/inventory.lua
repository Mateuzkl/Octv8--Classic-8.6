local Icons = {}
Icons[PlayerStates.Poison] = { tooltip = tr('You are poisoned'), path = '/images/game/states/poisoned', id = 'condition_poisoned' }
Icons[PlayerStates.Burn] = { tooltip = tr('You are burning'), path = '/images/game/states/burning', id = 'condition_burning' }
Icons[PlayerStates.Energy] = { tooltip = tr('You are electrified'), path = '/images/game/states/electrified', id = 'condition_electrified' }
Icons[PlayerStates.Drunk] = { tooltip = tr('You are drunk'), path = '/images/game/states/drunk', id = 'condition_drunk' }
Icons[PlayerStates.ManaShield] = { tooltip = tr('You are protected by a magic shield'), path = '/images/game/states/magic_shield', id = 'condition_magic_shield' }
Icons[PlayerStates.Paralyze] = { tooltip = tr('You are paralysed'), path = '/images/game/states/slowed', id = 'condition_slowed' }
Icons[PlayerStates.Haste] = { tooltip = tr('You are hasted'), path = '/images/game/states/haste', id = 'condition_haste' }
Icons[PlayerStates.Swords] = { tooltip = tr('You may not logout during a fight'), path = '/images/game/states/logout_block', id = 'condition_logout_block' }
Icons[PlayerStates.Drowning] = { tooltip = tr('You are drowning'), path = '/images/game/states/drowning', id = 'condition_drowning' }
Icons[PlayerStates.Freezing] = { tooltip = tr('You are freezing'), path = '/images/game/states/freezing', id = 'condition_freezing' }
Icons[PlayerStates.Dazzled] = { tooltip = tr('You are dazzled'), path = '/images/game/states/dazzled', id = 'condition_dazzled' }
Icons[PlayerStates.Cursed] = { tooltip = tr('You are cursed'), path = '/images/game/states/cursed', id = 'condition_cursed' }
Icons[PlayerStates.PartyBuff] = { tooltip = tr('You are strengthened'), path = '/images/game/states/strengthened', id = 'condition_strengthened' }
Icons[PlayerStates.PzBlock] = { tooltip = tr('You may not logout or enter a protection zone'), path = '/images/game/states/protection_zone_block', id = 'condition_protection_zone_block' }
Icons[PlayerStates.Pz] = { tooltip = tr('You are within a protection zone'), path = '/images/game/states/protection_zone', id = 'condition_protection_zone' }
Icons[PlayerStates.Bleeding] = { tooltip = tr('You are bleeding'), path = '/images/game/states/bleeding', id = 'condition_bleeding' }
Icons[PlayerStates.Hungry] = { tooltip = tr('You are hungry'), path = '/images/game/states/hungry', id = 'condition_hungry' }

local SkullIcons = {
  [SkullYellow] = { path = '/images/game/skulls/skull_yellow', id = 'skullIcon', tooltip = tr('You are involved in a PvP situation') },
  [SkullGreen]  = { path = '/images/game/skulls/skull_green',  id = 'skullIcon', tooltip = tr('You are a member of a party') },
  [SkullWhite]  = { path = '/images/game/skulls/skull_white',  id = 'skullIcon', tooltip = tr('You have attacked an unmarked player') },
  [SkullRed]    = { path = '/images/game/skulls/skull_red',    id = 'skullIcon', tooltip = tr('You have killed too many unmarked players') },
  [SkullBlack]  = { path = '/images/game/skulls/skull_black',  id = 'skullIcon', tooltip = tr('You are a murderer') },
  [SkullOrange] = { path = '/images/game/skulls/skull_orange', id = 'skullIcon', tooltip = tr('You are involved in a PvP situation') }
}

local EmblemIcons = {
  [EmblemGreen]  = { path = '/images/game/emblems/emblem_green',  tooltip = tr('You are in a white war (green emblem)') },
  [EmblemRed]    = { path = '/images/game/emblems/emblem_red',    tooltip = tr('You are in a white war (red emblem)') },
  [EmblemBlue]   = { path = '/images/game/emblems/emblem_blue',   tooltip = tr('You are in a white war (blue emblem)') },
  [EmblemMember] = { path = '/images/game/emblems/emblem_member', tooltip = tr('You are a war member') },
  [EmblemOther]  = { path = '/images/game/emblems/emblem_other',  tooltip = tr('You are at war with this player') },
}

local InventorySlotStyles = {
  [InventorySlotHead] = "HeadSlot",
  [InventorySlotNeck] = "NeckSlot",
  [InventorySlotBack] = "BackSlot",
  [InventorySlotBody] = "BodySlot",
  [InventorySlotRight] = "RightSlot",
  [InventorySlotLeft] = "LeftSlot",
  [InventorySlotLeg] = "LegSlot",
  [InventorySlotFeet] = "FeetSlot",
  [InventorySlotFinger] = "FingerSlot",
  [InventorySlotAmmo] = "AmmoSlot"
}

inventoryWindow = nil
local inventoryPanel = nil
local inventoryButton = nil
local purseButton = nil

local fightOffensiveBox = nil
local fightBalancedBox = nil
local fightDefensiveBox = nil
local chaseModeButton = nil
local safeFightButton = nil
local mountButton = nil
local fightModeRadioGroup = nil
local buttonPvp = nil

local soulLabel = nil
local capLabel = nil
local conditionPanel = nil

function init()
  connect(LocalPlayer, {
    onInventoryChange = onInventoryChange,
    onBlessingsChange = onBlessingsChange
  })
  connect(g_game, { onGameStart = refresh })

  g_keyboard.bindKeyDown('Ctrl+I', toggle)


  inventoryWindow = g_ui.loadUI('inventory', modules.game_interface.getRightPanel())
  inventoryWindow:disableResize()
  inventoryPanel = inventoryWindow:recursiveGetChildById('inventoryPanel')
  if not inventoryWindow.forceOpen then
    inventoryButton = modules.client_topmenu.addRightGameToggleButton('inventoryButton', tr('Inventory') .. ' (Ctrl+I)', '/images/topbuttons/inventory', toggle)
    inventoryButton:setOn(true)
  end
  
  purseButton = inventoryWindow:recursiveGetChildById('purseButton')
  if purseButton then
    purseButton.onClick = function()
      local player = g_game.getLocalPlayer()
      if player then
        local purse = player:getInventoryItem(InventorySlotPurse)
        if purse then
          g_game.use(purse)
        end
      end
    end
  end
  
  -- controls
  fightOffensiveBox = inventoryWindow:recursiveGetChildById('fightOffensiveBox')
  fightBalancedBox = inventoryWindow:recursiveGetChildById('fightBalancedBox')
  fightDefensiveBox = inventoryWindow:recursiveGetChildById('fightDefensiveBox')

  chaseModeButton = inventoryWindow:recursiveGetChildById('chaseModeBox')
  safeFightButton = inventoryWindow:recursiveGetChildById('safeFightBox')
  buttonPvp = inventoryWindow:recursiveGetChildById('buttonPvp')

  mountButton = inventoryWindow:recursiveGetChildById('mountButton')
  if mountButton then
    mountButton.onClick = onMountButtonClick
  end

  fightModeRadioGroup = UIRadioGroup.create()
  fightModeRadioGroup:addWidget(fightOffensiveBox)
  fightModeRadioGroup:addWidget(fightBalancedBox)
  fightModeRadioGroup:addWidget(fightDefensiveBox)

  connect(fightModeRadioGroup, { onSelectionChange = onSetFightMode })
  connect(chaseModeButton, { onCheckChange = onSetChaseMode })
  connect(safeFightButton, { onCheckChange = onSetSafeFight })
  if buttonPvp then
    connect(buttonPvp, { onClick = onSetSafeFight2 })  
  end
  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
    onFightModeChange = update,
    onChaseModeChange = update,
    onSafeFightChange = update,
    onPVPModeChange   = update,
    onWalk = check,
    onAutoWalk = check
  })

  connect(LocalPlayer, { onOutfitChange = onOutfitChange })

  if g_game.isOnline() then
    online()
  end
-- controls end

-- status
  soulLabel = inventoryWindow:recursiveGetChildById('soulLabel')
  capLabel = inventoryWindow:recursiveGetChildById('capLabel')
  conditionPanel = inventoryWindow:recursiveGetChildById('conditionPanel')


  connect(LocalPlayer, { onStatesChange = onStatesChange,
                         onSoulChange = onSoulChange,
                         onFreeCapacityChange = onFreeCapacityChange,
                         onSkullChange = onSkullChange,
                         onEmblemChange = onEmblemChange })
-- status end
  
  refresh()
  inventoryWindow:setup()
end

function terminate()
  disconnect(LocalPlayer, {
    onInventoryChange = onInventoryChange,
    onBlessingsChange = onBlessingsChange
  })
  disconnect(g_game, { onGameStart = refresh })

  g_keyboard.unbindKeyDown('Ctrl+I')

  -- controls
  if g_game.isOnline() then
    offline()
  end

  if fightModeRadioGroup then
    disconnect(fightModeRadioGroup, { onSelectionChange = onSetFightMode })
    fightModeRadioGroup:destroy()
  end
  if chaseModeButton then
    disconnect(chaseModeButton, { onCheckChange = onSetChaseMode })
  end
  if safeFightButton then
    disconnect(safeFightButton, { onCheckChange = onSetSafeFight })
  end
  if buttonPvp then
    disconnect(buttonPvp, { onClick = onSetSafeFight2 })
  end

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
    onFightModeChange = update,
    onChaseModeChange = update,
    onSafeFightChange = update,
    onPVPModeChange   = update,
    onWalk = check,
    onAutoWalk = check
  })

  disconnect(LocalPlayer, { onOutfitChange = onOutfitChange })
  -- controls end
  -- status
  disconnect(LocalPlayer, { onStatesChange = onStatesChange,
                           onSoulChange = onSoulChange,
                           onFreeCapacityChange = onFreeCapacityChange,
                           onSkullChange = onSkullChange,
                           onEmblemChange = onEmblemChange })
  -- status end

  if inventoryWindow then
    inventoryWindow:destroy()
    inventoryWindow = nil
  end
  if inventoryButton then
    inventoryButton:destroy()
    inventoryButton = nil
  end
end

function toggleAdventurerStyle(hasBlessing)
  for slot = InventorySlotFirst, InventorySlotLast do
    local itemWidget = inventoryPanel:getChildById('slot' .. slot)
    if itemWidget then
      itemWidget:setOn(hasBlessing)
    end
  end
end

function refresh()
  local player = g_game.getLocalPlayer()
  for i = InventorySlotFirst, InventorySlotPurse do
    if g_game.isOnline() then
      onInventoryChange(player, i, player:getInventoryItem(i))
    else
      onInventoryChange(player, i, nil)
    end
  end
  toggleAdventurerStyle(player and Bit.hasBit(player:getBlessings(), Blessings.Adventurer) or false)
  if player then
    onSoulChange(player, player:getSoul())
    onFreeCapacityChange(player, player:getFreeCapacity())
    onStatesChange(player, player:getStates(), 0)
  end

  if purseButton then
    purseButton:setVisible(g_game.getFeature(GamePurseSlot))
  end
end

function toggle()
  if not inventoryButton then
    return
  end
  if inventoryButton:isOn() then
    inventoryWindow:close()
    inventoryButton:setOn(false)
  else
    inventoryWindow:open()
    inventoryButton:setOn(true)
  end
end

function onMiniWindowClose()
  if not inventoryButton then
    return
  end
  inventoryButton:setOn(false)
end

-- hooked events
function onInventoryChange(player, slot, item, oldItem)
  if slot > InventorySlotPurse then return end

  if slot == InventorySlotPurse then
    return
  end

  local itemWidget = inventoryPanel:getChildById('slot' .. slot)
  if not itemWidget then return end
  if item then
    itemWidget:setStyle('InventoryItem')
    itemWidget:setItem(item)
    if ItemsDatabase and ItemsDatabase.setTier then
      ItemsDatabase.setTier(itemWidget, item)
    end
  else
    itemWidget:setStyle(InventorySlotStyles[slot])
    itemWidget:setItem(nil)
    itemWidget:setTooltip(nil)
  end
  if ItemsDatabase and ItemsDatabase.setTier then
    ItemsDatabase.setTier(itemWidget, item or nil)
  end
end

function onBlessingsChange(player, blessings, oldBlessings)
  local hasAdventurerBlessing = Bit.hasBit(blessings, Blessings.Adventurer)
  if hasAdventurerBlessing ~= Bit.hasBit(oldBlessings, Blessings.Adventurer) then
    toggleAdventurerStyle(hasAdventurerBlessing)
  end
end


-- controls
function update()
  local fightMode = g_game.getFightMode()
  if fightMode == FightOffensive then
    fightModeRadioGroup:selectWidget(fightOffensiveBox)
  elseif fightMode == FightBalanced then
    fightModeRadioGroup:selectWidget(fightBalancedBox)
  else
    fightModeRadioGroup:selectWidget(fightDefensiveBox)
  end

  local chaseMode = g_game.getChaseMode()
  chaseModeButton:setChecked(chaseMode == ChaseOpponent)

  local safeFight = g_game.isSafeFight()
  safeFightButton:setChecked(not safeFight)
  if buttonPvp then
    if safeFight then
      buttonPvp:setOn(false)
    else
      buttonPvp:setOn(true)  
    end
  end
  
end

function check()
  if modules.client_options.getOption('autoChaseOverride') then
    if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
      g_game.setChaseMode(DontChase)
    end
  end
end

function online()
  local player = g_game.getLocalPlayer()
  if player then
    local char = g_game.getCharacterName()

    local lastCombatControls = g_settings.getNode('LastCombatControls')

    if not table.empty(lastCombatControls) then
      if lastCombatControls[char] then
        g_game.setFightMode(lastCombatControls[char].fightMode)
        g_game.setChaseMode(lastCombatControls[char].chaseMode)
        g_game.setSafeFight(lastCombatControls[char].safeFight)
        if lastCombatControls[char].pvpMode then
          g_game.setPVPMode(lastCombatControls[char].pvpMode)
        end
      end
    end

    if g_game.getFeature(GamePlayerMounts) then
      if mountButton then
        mountButton:setVisible(true)
        mountButton:setChecked(player:isMounted())
      end
    elseif mountButton then
      mountButton:setVisible(false)
    end
  end

  update()
end

function offline()
  local lastCombatControls = g_settings.getNode('LastCombatControls')
  if not lastCombatControls then
    lastCombatControls = {}
  end

  if conditionPanel then
    conditionPanel:destroyChildren()
  end

  local player = g_game.getLocalPlayer()
  if player then
    local char = g_game.getCharacterName()
    lastCombatControls[char] = {
      fightMode = g_game.getFightMode(),
      chaseMode = g_game.getChaseMode(),
      safeFight = g_game.isSafeFight()
    }

    if g_game.getFeature(GamePVPMode) then
      lastCombatControls[char].pvpMode = g_game.getPVPMode()
    end

    -- save last combat control settings
    g_settings.setNode('LastCombatControls', lastCombatControls)
  end
end

function onSetFightMode(self, selectedFightButton)
  if selectedFightButton == nil then return end
  local buttonId = selectedFightButton:getId()
  local fightMode
  if buttonId == 'fightOffensiveBox' then
    fightMode = FightOffensive
  elseif buttonId == 'fightBalancedBox' then
    fightMode = FightBalanced
  else
    fightMode = FightDefensive
  end
  g_game.setFightMode(fightMode)
end

function onSetChaseMode(self, checked)
  local chaseMode
  if checked then
    chaseMode = ChaseOpponent
  else
    chaseMode = DontChase
  end
  g_game.setChaseMode(chaseMode)
end

function onSetSafeFight(self, checked)
  g_game.setSafeFight(not checked)
  if buttonPvp then
    if not checked then
      buttonPvp:setOn(false)
    else
      buttonPvp:setOn(true)  
    end
  end
end

function onSetSafeFight2(self)
  onSetSafeFight(self, not safeFightButton:isChecked())
end

function onMountButtonClick(self, mousePos)
  local player = g_game.getLocalPlayer()
  if player then
    player:toggleMount()
  end
end

function onOutfitChange(localPlayer, outfit, oldOutfit)
  if outfit.mount == oldOutfit.mount then
    return
  end

  if mountButton then
    mountButton:setChecked(outfit.mount ~= nil and outfit.mount > 0)
  end
end

-- status
function toggleIcon(bitChanged)
  local iconData = Icons[bitChanged]
  if not iconData then return end
  local icon = conditionPanel:getChildById(iconData.id)
  if icon then
    icon:destroy()
  else
    loadIcon(bitChanged)
  end
end

function loadIcon(bitChanged)
  local icon = g_ui.createWidget('ConditionWidget', conditionPanel)
  icon:setId(Icons[bitChanged].id)
  icon:setImageSource(Icons[bitChanged].path)
  icon:setTooltip(Icons[bitChanged].tooltip)
  return icon
end

function onSoulChange(localPlayer, soul)
  if not soul or not soulLabel then return end
  soulLabel:setText(tr('Soul') .. ':\n' .. soul)
end

function onFreeCapacityChange(player, freeCapacity)
  if not freeCapacity or not capLabel then return end
  if freeCapacity > 99 then
    freeCapacity = math.floor(freeCapacity * 10) / 10
  end
  if freeCapacity > 999 then
    freeCapacity = math.floor(freeCapacity)
  end
  if freeCapacity > 99999 then
    freeCapacity = math.min(9999, math.floor(freeCapacity/1000)) .. "k"
  end
  capLabel:setText(tr('Cap') .. ':\n' .. freeCapacity)
end

function onStatesChange(localPlayer, now, old)
  if now == old then return end

  local bitsChanged = bit.bxor(now, old)
  for i = 1, 32 do
    local pow = bit.lshift(1, i-1)
    if pow > bitsChanged then break end
    local bitChanged = bit.band(bitsChanged, pow)
    if bitChanged ~= 0 then
      toggleIcon(bitChanged)
    end
  end
end

function onSkullChange(localPlayer, skull)
  local icon = conditionPanel:getChildById('skullIcon')

  if skull == SkullNone then
    if icon then
      icon:destroy()
    end
    return
  end

  local skullIcon = SkullIcons[skull]
  if skullIcon then
    icon = icon or g_ui.createWidget('ConditionWidget', conditionPanel)
    icon:setId(skullIcon.id)
    icon:setImageSource(skullIcon.path)
    icon:setTooltip(skullIcon.tooltip)
  end
end

function onEmblemChange(localPlayer, emblem)
  local icon = conditionPanel:getChildById('emblemIcon')

  if emblem == EmblemNone then
    if icon then
      icon:destroy()
    end
    return
  end

  local emblemData = EmblemIcons[emblem]
  if emblemData then
    icon = icon or g_ui.createWidget('ConditionWidget', conditionPanel)
    icon:setId('emblemIcon')
    icon:setImageSource(emblemData.path)
    icon:setTooltip(emblemData.tooltip)
  end
end