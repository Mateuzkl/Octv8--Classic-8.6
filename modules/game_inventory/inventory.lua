Icons = {
    [PlayerStates.Poison] = {
        path = "/images/game/states/poisoned",
        id = "condition_poisoned",
        tooltip = tr("You are poisoned")
    },
    [PlayerStates.Burn] = {
        path = "/images/game/states/burning",
        id = "condition_burning",
        tooltip = tr("You are burning")
    },
    [PlayerStates.Energy] = {
        path = "/images/game/states/electrified",
        id = "condition_electrified",
        tooltip = tr("You are electrified")
    },
    [PlayerStates.Drunk] = {
        path = "/images/game/states/drunk",
        id = "condition_drunk",
        tooltip = tr("You are drunk")
    },
    [PlayerStates.ManaShield] = {
        path = "/images/game/states/magic_shield",
        id = "condition_magic_shield",
        tooltip = tr("You are protected by a magic shield")
    },
    [PlayerStates.Paralyze] = {
        path = "/images/game/states/slowed",
        id = "condition_slowed",
        tooltip = tr("You are paralysed")
    },
    [PlayerStates.Haste] = {
        path = "/images/game/states/haste",
        id = "condition_haste",
        tooltip = tr("You are hasted")
    },
    [PlayerStates.Swords] = {
        path = "/images/game/states/logout_block",
        id = "condition_logout_block",
        tooltip = tr("You may not logout during a fight")
    },
    [PlayerStates.Drowning] = {
        path = "/images/game/states/drowning",
        id = "condition_drowning",
        tooltip = tr("You are drowning")
    },
    [PlayerStates.Freezing] = {
        path = "/images/game/states/freezing",
        id = "condition_freezing",
        tooltip = tr("You are freezing")
    },
    [PlayerStates.Dazzled] = {
        path = "/images/game/states/dazzled",
        id = "condition_dazzled",
        tooltip = tr("You are dazzled")
    },
    [PlayerStates.Cursed] = {
        path = "/images/game/states/cursed",
        id = "condition_cursed",
        tooltip = tr("You are cursed")
    },
    [PlayerStates.PartyBuff] = {
        path = "/images/game/states/strengthened",
        id = "condition_strengthened",
        tooltip = tr("You are strengthened")
    },
    [PlayerStates.PzBlock] = {
        path = "/images/game/states/protection_zone_block",
        id = "condition_protection_zone_block",
        tooltip = tr("You may not logout or enter a protection zone")
    },
    [PlayerStates.Pz] = {
        path = "/images/game/states/protection_zone",
        id = "condition_protection_zone",
        tooltip = tr("You are within a protection zone")
    },
    [PlayerStates.Bleeding] = {
        path = "/images/game/states/bleeding",
        id = "condition_bleeding",
        tooltip = tr("You are bleeding")
    },
    [PlayerStates.Hungry] = {
        path = "/images/game/states/hungry",
        id = "condition_hungry",
        tooltip = tr("You are hungry")
    }
}
SkullIcons = {
    [SkullYellow] = {
        path = "/images/game/skulls/skull_yellow",
        id = "skullIcon",
        tooltip = tr("You are involved in a PvP situation")
    },
    [SkullGreen] = {
        path = "/images/game/skulls/skull_green",
        id = "skullIcon",
        tooltip = tr("You are a member of a party")
    },
    [SkullWhite] = {
        path = "/images/game/skulls/skull_white",
        id = "skullIcon",
        tooltip = tr("You have attacked an unmarked player")
    },
    [SkullRed] = {
        path = "/images/game/skulls/skull_red",
        id = "skullIcon",
        tooltip = tr("You have killed too many unmarked players")
    },
    [SkullBlack] = {
        path = "/images/game/skulls/skull_black",
        id = "skullIcon",
        tooltip = tr("You are a murderer")
    },
    [SkullOrange] = {
        path = "/images/game/skulls/skull_orange",
        id = "skullIcon",
        tooltip = tr("You are involved in a PvP situation")
    }
}
InventorySlotStyles = {
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
inventoryPanel = nil
inventoryButton = nil
purseButton = nil
combatControlsWindow = nil
fightOffensiveBox = nil
fightBalancedBox = nil
fightDefensiveBox = nil
chaseModeButton = nil
safeFightButton = nil
mountButton = nil
fightModeRadioGroup = nil
chaseModeRadioGroup = nil
chaseModeStandBox = nil
chaseModeChaseBox = nil
buttonPvp = nil
skillsButton = nil
battleButton = nil
vipButton = nil
questButton = nil
soulLabel = nil
capLabel = nil
conditionPanel = nil


function init()
    connect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onBlessingsChange = onBlessingsChange
    })
    connect(g_game, {
        onGameStart = refresh
    })

    inventoryWindow = g_ui.loadUI("inventory", modules.game_interface.getRightPanel())
    inventoryWindow:disableResize()
    inventoryPanel = inventoryWindow:recursiveGetChildById("inventorySlotsPanel")

    if not inventoryWindow.forceOpen then
        inventoryButton = modules.client_topmenu.addRightGameToggleButton("inventoryButton", tr("Inventory") .. " (Ctrl+I)", "/images/topbuttons/inventory", toggle)
        inventoryButton:setOn(true)
    end

    purseButton = inventoryWindow:recursiveGetChildById("purseButton")

    function purseButton.onClick()
        local purse = g_game.getLocalPlayer():getInventoryItem(InventorySlotPurse)
        if purse then
            g_game.use(purse)
        end
    end

    skillsButton = inventoryWindow:recursiveGetChildById("skillsButton")
    battleButton = inventoryWindow:recursiveGetChildById("battleButton")
    vipButton = inventoryWindow:recursiveGetChildById("vipButton")
    questButton = inventoryWindow:recursiveGetChildById("questButton")
    fightOffensiveBox = inventoryWindow:recursiveGetChildById("fightOffensiveBox")
    fightBalancedBox = inventoryWindow:recursiveGetChildById("fightBalancedBox")
    fightDefensiveBox = inventoryWindow:recursiveGetChildById("fightDefensiveBox")
    chaseModeStandBox = inventoryWindow:recursiveGetChildById("chaseModeBoxStand")
    chaseModeChaseBox = inventoryWindow:recursiveGetChildById("chaseModeBoxChase")
    chaseModeButton = inventoryWindow:recursiveGetChildById("chaseModeBox")
    safeFightButton = inventoryWindow:recursiveGetChildById("safeFightBox")
    buttonPvp = inventoryWindow:recursiveGetChildById("buttonPvp")
    mountButton = inventoryWindow:recursiveGetChildById("mountButton")
    mountButton.onClick = onMountButtonClick
    whiteDoveBox = inventoryWindow:recursiveGetChildById("whiteDoveBox")
    whiteHandBox = inventoryWindow:recursiveGetChildById("whiteHandBox")
    yellowHandBox = inventoryWindow:recursiveGetChildById("yellowHandBox")
    redFistBox = inventoryWindow:recursiveGetChildById("redFistBox")
    fightModeRadioGroup = UIRadioGroup.create()

    fightModeRadioGroup:addWidget(fightOffensiveBox)
    fightModeRadioGroup:addWidget(fightBalancedBox)
    fightModeRadioGroup:addWidget(fightDefensiveBox)

    chaseModeRadioGroup = UIRadioGroup.create()

    chaseModeRadioGroup:addWidget(chaseModeStandBox)
    chaseModeRadioGroup:addWidget(chaseModeChaseBox)
    connect(fightModeRadioGroup, {
        onSelectionChange = onSetFightMode
    })
    connect(chaseModeRadioGroup, {
        onSelectionChange = onSetChaseMode
    })
    connect(safeFightButton, {
        onCheckChange = onSetSafeFight
    })

    if buttonPvp then
        connect(buttonPvp, {
            onClick = onSetSafeFight2
        })
    end

    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onFightModeChange = update,
        onChaseModeChange = update,
        onSafeFightChange = update,
        onPVPModeChange = update,
        onWalk = check,
        onAutoWalk = check
    })
    connect(LocalPlayer, {
        onOutfitChange = onOutfitChange
    })

    if g_game.isOnline() then
        online()
    end

    soulLabel = inventoryWindow:recursiveGetChildById("soulLabel")
    capLabel = inventoryWindow:recursiveGetChildById("capLabel")
    conditionPanel = inventoryWindow:recursiveGetChildById("conditionPanel")

    connect(LocalPlayer, {
        onStatesChange = onStatesChange,
        onSoulChange = onSoulChange,
        onFreeCapacityChange = onFreeCapacityChange
    })
    connect(LocalPlayer, {
        onSkullChange = onSkullChange,
        onEmblemChange = onEmblemChange
    })
    refresh()
    inventoryWindow:setup()

    if g_settings.getBoolean("inventoryMinimized", false) then
        toggleInventoryMinimize(true)
    end

    inventoryWindow:open()
end


function toggleInventoryMinimize(state)
    local minimized = state or not inventoryWindow:isOn()
    inventoryWindow:setOn(minimized)

    local contentsPanel = inventoryWindow:getChildById("contentsPanel")
    local slotsPanel = contentsPanel:getChildById("inventorySlotsPanel")
    local controlsPanel = contentsPanel:getChildById("inventoryControlsPanel")
    local minimizeButton = contentsPanel:getChildById("minimizeButton")
    local capLabel = contentsPanel:getChildById("capLabel")
    local soulLabel = contentsPanel:getChildById("soulLabel")
    local conditionPanel = contentsPanel:getChildById("conditionPanel")

    -- Utility buttons
    local storeButton = controlsPanel:getChildById("storeButton")
    local stopButton = controlsPanel:getChildById("stopButton")
    local purseButton = slotsPanel:getChildById("purseButton")
    local optionsButton = controlsPanel:getChildById("optionsButton")
    local ciclopediaButton = controlsPanel:getChildById("ciclopediaButton")
    local questsButton = controlsPanel:getChildById("questsButton")
    local mountButton = controlsPanel:getChildById("mountButton")

    -- Combat boxes
    local offensive = controlsPanel:getChildById("fightOffensiveBox")
    local balanced = controlsPanel:getChildById("fightBalancedBox")
    local defensive = controlsPanel:getChildById("fightDefensiveBox")
    local stand = controlsPanel:getChildById("chaseModeBoxStand")
    local chase = controlsPanel:getChildById("chaseModeBoxChase")
    local safe = controlsPanel:getChildById("safeFightBox")

    if minimized then
        slotsPanel:hide()
        if storeButton then
            storeButton:hide()
        end
        stopButton:hide()
        optionsButton:hide()
        ciclopediaButton:hide()
        questsButton:hide()
        mountButton:hide()
        if purseButton then
            purseButton:hide()
        end

        inventoryWindow:setHeight(62)
        inventoryWindow:setWidth(155)

        -- Cap and Soul placement (stacked)
        capLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
        capLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        capLabel:setMarginTop(5)
        capLabel:setMarginLeft(25)

        soulLabel:addAnchor(AnchorTop, 'parent', AnchorTop)
        soulLabel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        soulLabel:setMarginTop(25)
        soulLabel:setMarginLeft(25)

        -- Controls Panel layout (Grid 3x2)
        controlsPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
        controlsPanel:addAnchor(AnchorLeft, 'capLabel', AnchorRight)
        controlsPanel:setMarginTop(0)
        controlsPanel:setMarginLeft(5)

        offensive:addAnchor(AnchorTop, 'parent', AnchorTop)
        offensive:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        offensive:setMarginTop(3)
        offensive:setMarginLeft(0)

        balanced:addAnchor(AnchorTop, 'parent', AnchorTop)
        balanced:addAnchor(AnchorLeft, 'fightOffensiveBox', AnchorRight)
        balanced:setMarginTop(3)
        balanced:setMarginLeft(2)

        defensive:addAnchor(AnchorTop, 'parent', AnchorTop)
        defensive:addAnchor(AnchorLeft, 'fightBalancedBox', AnchorRight)
        defensive:setMarginTop(3)
        defensive:setMarginLeft(2)

        stand:addAnchor(AnchorTop, 'fightOffensiveBox', AnchorBottom)
        stand:addAnchor(AnchorLeft, 'fightOffensiveBox', AnchorLeft)
        stand:setMarginTop(2)
        stand:setMarginLeft(0)

        chase:addAnchor(AnchorTop, 'fightBalancedBox', AnchorBottom)
        chase:addAnchor(AnchorLeft, 'fightBalancedBox', AnchorLeft)
        chase:setMarginTop(2)
        chase:setMarginLeft(0)

        safe:addAnchor(AnchorTop, 'fightDefensiveBox', AnchorBottom)
        safe:addAnchor(AnchorLeft, 'fightDefensiveBox', AnchorLeft)
        safe:setMarginTop(2)
        safe:setMarginLeft(0)

        conditionPanel:removeAnchor(AnchorTop)
        conditionPanel:removeAnchor(AnchorBottom)
        conditionPanel:removeAnchor(AnchorLeft)
        conditionPanel:removeAnchor(AnchorRight)
        conditionPanel:removeAnchor(AnchorHorizontalCenter)
        conditionPanel:addAnchor(AnchorTop, 'chaseModeBoxStand', AnchorBottom)
        conditionPanel:addAnchor(AnchorHorizontalCenter, 'controlsPanel', AnchorHorizontalCenter)
        conditionPanel:setMarginTop(10)
        conditionPanel:setWidth(120)
        conditionPanel:setHeight(13)
        conditionPanel:setMarginLeft(0)

        minimizeButton:setImageClip("14 0 14 14") -- "+" icon
    else
        slotsPanel:show()
        if storeButton then
            storeButton:show()
        end
        stopButton:hide()
        optionsButton:hide()
        ciclopediaButton:hide()
        questsButton:hide()
        mountButton:show()
        if purseButton then
            purseButton:show()
        end

        inventoryWindow:setHeight(170)
        inventoryWindow:setWidth(170)

        -- Cap and Soul restoration
        capLabel:addAnchor(AnchorTop, 'inventorySlotsPanel', AnchorTop)
        capLabel:addAnchor(AnchorLeft, 'inventorySlotsPanel', AnchorLeft)
        capLabel:setMarginTop(130)
        capLabel:setMarginLeft(80)

        soulLabel:addAnchor(AnchorTop, 'inventorySlotsPanel', AnchorTop)
        soulLabel:addAnchor(AnchorLeft, 'inventorySlotsPanel', AnchorLeft)
        soulLabel:setMarginTop(130)
        soulLabel:setMarginLeft(5)

        conditionPanel:removeAnchor(AnchorTop)
        conditionPanel:removeAnchor(AnchorBottom)
        conditionPanel:removeAnchor(AnchorLeft)
        conditionPanel:removeAnchor(AnchorRight)
        conditionPanel:removeAnchor(AnchorHorizontalCenter)
        conditionPanel:addAnchor(AnchorTop, 'inventorySlotsPanel', AnchorTop)
        conditionPanel:addAnchor(AnchorHorizontalCenter, 'inventorySlotsPanel', AnchorHorizontalCenter)
        conditionPanel:setMarginTop(150)
        conditionPanel:setWidth(110)
        conditionPanel:setHeight(13)
        conditionPanel:setMarginLeft(0)


        -- Controls panel restoration
        controlsPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
        controlsPanel:addAnchor(AnchorLeft, 'inventorySlotsPanel', AnchorRight)
        controlsPanel:setMarginTop(0)
        controlsPanel:setMarginLeft(0)

        offensive:addAnchor(AnchorTop, 'parent', AnchorTop)
        offensive:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        offensive:setMarginTop(5)
        offensive:setMarginLeft(8)

        balanced:addAnchor(AnchorTop, 'fightOffensiveBox', AnchorBottom)
        balanced:addAnchor(AnchorLeft, 'fightOffensiveBox', AnchorLeft)
        balanced:setMarginTop(1)
        balanced:setMarginLeft(0)

        defensive:addAnchor(AnchorTop, 'fightBalancedBox', AnchorBottom)
        defensive:addAnchor(AnchorLeft, 'fightBalancedBox', AnchorLeft)
        defensive:setMarginTop(1)
        defensive:setMarginLeft(0)

        stand:addAnchor(AnchorTop, 'fightOffensiveBox', AnchorTop)
        stand:addAnchor(AnchorLeft, 'fightOffensiveBox', AnchorRight)
        stand:setMarginTop(0)
        stand:setMarginLeft(4)

        chase:addAnchor(AnchorTop, 'chaseModeBoxStand', AnchorBottom)
        chase:addAnchor(AnchorLeft, 'chaseModeBoxStand', AnchorLeft)
        chase:setMarginTop(1)
        chase:setMarginLeft(0)

        safe:addAnchor(AnchorTop, 'chaseModeBoxChase', AnchorBottom)
        safe:addAnchor(AnchorLeft, 'chaseModeBoxChase', AnchorLeft)
        safe:setMarginTop(1)
        safe:setMarginLeft(0)

        mountButton:addAnchor(AnchorTop, 'safeFightBox', AnchorBottom)
        mountButton:addAnchor(AnchorLeft, 'safeFightBox', AnchorLeft)
        mountButton:setMarginTop(1)
        mountButton:setMarginLeft(0)

        stopButton:addAnchor(AnchorTop, 'mountButton', AnchorBottom)
        stopButton:addAnchor(AnchorRight, 'safeFightBox', AnchorRight)
        stopButton:setMarginTop(5)

        questsButton:addAnchor(AnchorTop, 'stopButton', AnchorBottom)
        questsButton:addAnchor(AnchorLeft, 'stopButton', AnchorLeft)
        questsButton:addAnchor(AnchorRight, 'stopButton', AnchorRight)
        questsButton:setMarginTop(3)

        optionsButton:addAnchor(AnchorTop, 'questsButton', AnchorBottom)
        optionsButton:addAnchor(AnchorLeft, 'questsButton', AnchorLeft)
        optionsButton:addAnchor(AnchorRight, 'questsButton', AnchorRight)
        optionsButton:setMarginTop(3)

        ciclopediaButton:addAnchor(AnchorTop, 'optionsButton', AnchorBottom)
        ciclopediaButton:addAnchor(AnchorLeft, 'optionsButton', AnchorLeft)
        ciclopediaButton:addAnchor(AnchorRight, 'optionsButton', AnchorRight)
        ciclopediaButton:setMarginTop(3)

        minimizeButton:setImageClip("0 0 14 14") -- "-" icon
    end

    g_settings.set("inventoryMinimized", minimized)
end


function terminate()
    disconnect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onBlessingsChange = onBlessingsChange
    })
    disconnect(g_game, {
        onGameStart = refresh
    })

    if g_game.isOnline() then
        offline()
    end

    fightModeRadioGroup:destroy()
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onFightModeChange = update,
        onChaseModeChange = update,
        onSafeFightChange = update,
        onPVPModeChange = update,
        onWalk = check,
        onAutoWalk = check
    })
    disconnect(LocalPlayer, {
        onOutfitChange = onOutfitChange
    })
    disconnect(LocalPlayer, {
        onStatesChange = onStatesChange,
        onSoulChange = onSoulChange,
        onFreeCapacityChange = onFreeCapacityChange
    })
    disconnect(LocalPlayer, {
        onSkullChange = onSkullChange,
        onEmblemChange = onEmblemChange
    })
    inventoryWindow:destroy()

    if inventoryButton then
        inventoryButton:destroy()
    end
end


function toggleAdventurerStyle(hasBlessing)
    for slot = InventorySlotFirst, InventorySlotLast do
        local itemWidget = inventoryPanel:getChildById("slot" .. slot)
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

        toggleAdventurerStyle(player and Bit.hasBit(player:getBlessings(), Blessings.Adventurer) or false)
    end

    if player then
        onSoulChange(player, player:getSoul())
        onFreeCapacityChange(player, player:getFreeCapacity())
        onStatesChange(player, player:getStates(), 0)
    end

    purseButton:setVisible(g_game.getFeature(GamePurseSlot))
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


function onInventoryChange(player, slot, item, oldItem)
    if InventorySlotPurse < slot then
        return
    end

    if slot == InventorySlotPurse then
        if g_game.getFeature(GamePurseSlot) then
            -- Nothing
        end
        return
    end

    local itemWidget = inventoryPanel:getChildById("slot" .. slot)

    if item then
        itemWidget:setStyle("InventoryItem")
        itemWidget:setItem(item)
    else
        itemWidget:setStyle(InventorySlotStyles[slot])
        itemWidget:setItem(nil)
    end

    ItemsDatabase.setTier(itemWidget, item)
end

function onBlessingsChange(player, blessings, oldBlessings)
    local hasAdventurerBlessing = Bit.hasBit(blessings, Blessings.Adventurer)

    if hasAdventurerBlessing ~= Bit.hasBit(oldBlessings, Blessings.Adventurer) then
        toggleAdventurerStyle(hasAdventurerBlessing)
    end
end


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

    if chaseMode == ChaseOpponent then
        chaseModeRadioGroup:selectWidget(chaseModeChaseBox)
    else
        chaseModeRadioGroup:selectWidget(chaseModeStandBox)
    end

    local safeFight = g_game.isSafeFight()
    safeFightButton:setChecked(not safeFight)

    if buttonPvp then
        if safeFight then
            buttonPvp:setOn(false)
        else
            buttonPvp:setOn(true)
        end
    end

    if g_game.getFeature(GamePVPMode) then
        local pvpMode = g_game.getPVPMode()
        local pvpWidget = getPVPBoxByMode(pvpMode)
    end
end


function check()
    if modules.client_options.getOption("autoChaseOverride") and g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
        g_game.setChaseMode(DontChase)
    end
end


function online()
    local player = g_game.getLocalPlayer()

    if player then
        local char = g_game.getCharacterName()
        local lastCombatControls = g_settings.getNode("LastCombatControls")

        if not table.empty(lastCombatControls) and lastCombatControls[char] then
            g_game.setFightMode(lastCombatControls[char].fightMode)
            g_game.setChaseMode(lastCombatControls[char].chaseMode)
            g_game.setSafeFight(lastCombatControls[char].safeFight)

            if lastCombatControls[char].pvpMode then
                g_game.setPVPMode(lastCombatControls[char].pvpMode)
            end
        end

        if g_game.getFeature(GamePlayerMounts) then
            mountButton:setVisible(true)
            mountButton:setChecked(player:isMounted())
        else
            mountButton:setVisible(false)
        end
    end

    update()
end


function offline()
    local lastCombatControls = g_settings.getNode("LastCombatControls")
    lastCombatControls = lastCombatControls or {}

    conditionPanel:destroyChildren()

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

        g_settings.setNode("LastCombatControls", lastCombatControls)
    end
end


function onSetFightMode(self, selectedFightButton)
    if selectedFightButton == nil then
        return
    end

    local buttonId = selectedFightButton:getId()
    local fightMode = nil

    if buttonId == "fightOffensiveBox" then
        fightMode = FightOffensive
    elseif buttonId == "fightBalancedBox" then
        fightMode = FightBalanced
    else
        fightMode = FightDefensive
    end

    g_game.setFightMode(fightMode)
end


function onSetChaseMode(self, selectedButton)
    if selectedButton == nil then
        return
    end

    local buttonId = selectedButton:getId()
    local chaseMode = nil

    if buttonId == "chaseModeBoxChase" then
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


function onSetPVPMode(self, selectedPVPButton)
    if selectedPVPButton == nil then
        return
    end

    local buttonId = selectedPVPButton:getId()
    local pvpMode = PVPWhiteDove

    if buttonId == "whiteDoveBox" then
        pvpMode = PVPWhiteDove
    elseif buttonId == "whiteHandBox" then
        pvpMode = PVPWhiteHand
    elseif buttonId == "yellowHandBox" then
        pvpMode = PVPYellowHand
    elseif buttonId == "redFistBox" then
        pvpMode = PVPRedFist
    end

    g_game.setPVPMode(pvpMode)
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

    mountButton:setChecked(outfit.mount ~= nil and outfit.mount > 0)
end


function getPVPBoxByMode(mode)
    local widget = nil

    if mode == PVPWhiteDove then
        widget = whiteDoveBox
    elseif mode == PVPWhiteHand then
        widget = whiteHandBox
    elseif mode == PVPYellowHand then
        widget = yellowHandBox
    elseif mode == PVPRedFist then
        widget = redFistBox
    end

    return widget
end


function toggleIcon(bitChanged)
    local icon = conditionPanel:getChildById(Icons[bitChanged].id)

    if icon then
        icon:destroy()
    else
        if bitChanged == PlayerStates.Swords then
            if conditionPanel:getChildById(Icons[PlayerStates.PzBlock].id) then
                return
            end
        elseif bitChanged == PlayerStates.PzBlock then
            local swordsIcon = conditionPanel:getChildById(Icons[PlayerStates.Swords].id)
            if swordsIcon then
                swordsIcon:destroy()
            end
        end

        icon = loadIcon(bitChanged)
        icon:setParent(conditionPanel)
    end
end


function loadIcon(bitChanged)
    local icon = g_ui.createWidget("ConditionWidget", conditionPanel)

    icon:setId(Icons[bitChanged].id)
    icon:setImageSource(Icons[bitChanged].path)
    icon:setTooltip(Icons[bitChanged].tooltip)

    return icon
end


function onSoulChange(localPlayer, soul)
    if not soul then
        return
    end

    soulLabel:setText(tr("Soul") .. ":\n" .. soul)
end


function onFreeCapacityChange(player, freeCapacity)
    if not freeCapacity then
        return
    end

    if freeCapacity > 100000 then
        freeCapacity = 0
    end

    freeCapacity = math.floor(freeCapacity)

    if freeCapacity > 99999 then
        freeCapacity = math.min(9999, math.floor(freeCapacity / 1000)) .. "k"
    end

    capLabel:setText(tr("Cap") .. ":\n" .. freeCapacity)
end


function onStatesChange(localPlayer, now, old)
    if now == old then
        return
    end

    local bitsChanged = bit32.bxor(now, old)

    for i = 1, 32 do
        local pow = math.pow(2, i - 1)

        if bitsChanged < pow then
            break
        end

        local bitChanged = bit32.band(bitsChanged, pow)

        if bitChanged ~= 0 then
            toggleIcon(bitChanged)
        end
    end
end


function onEmblemChange(localPlayer, emblem)
    local icon = conditionPanel:getChildById("emblemIcon")

    if emblem == EmblemNone then
        if icon then
            icon:destroy()
        end
        return
    end

    local emblems = {
        [EmblemGreen]  = { path = "/images/game/emblems/emblem_green",  tooltip = tr("You are in a white war (green emblem)") },
        [EmblemRed]    = { path = "/images/game/emblems/emblem_red",    tooltip = tr("You are in a white war (red emblem)") },
        [EmblemBlue]   = { path = "/images/game/emblems/emblem_blue",   tooltip = tr("You are in a white war (blue emblem)") },
        [EmblemMember] = { path = "/images/game/emblems/emblem_member", tooltip = tr("You are a war member") },
        [EmblemOther]  = { path = "/images/game/emblems/emblem_other",  tooltip = tr("You are at war with this player") },
    }

    local emblemData = emblems[emblem]
    if emblemData then
        icon = icon or g_ui.createWidget("ConditionWidget", conditionPanel)
        icon:setId("emblemIcon")
        icon:setImageSource(emblemData.path)
        icon:setTooltip(emblemData.tooltip)
    end
end

function onSkullChange(localPlayer, skull)
    local icon = conditionPanel:getChildById("skullIcon")

    if skull == SkullNone then
        if icon then
            icon:destroy()
        end
        return
    end

    local skullIcon = SkullIcons[skull]
    if skullIcon then
        icon = icon or g_ui.createWidget("ConditionWidget", conditionPanel)
        icon:setId(skullIcon.id)
        icon:setImageSource(skullIcon.path)
        icon:setTooltip(skullIcon.tooltip)
    end
end

if g_resources.getLayout() == "retro" then
    dofile("/layouts/retro/modules/game_inventory/inventory.lua")
end
