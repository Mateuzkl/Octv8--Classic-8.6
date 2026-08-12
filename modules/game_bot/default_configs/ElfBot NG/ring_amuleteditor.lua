-- Ring/Amulet Editor
-- EQUP/UNEQUIP
--> Credits: SoyFabi_

local ui = setupUI([[
Panel
  height: 19

  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    font: verdana-11px-rounded
    !text: tr("Ring/Amulet: Editor")

  Button
    id: edit
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: "Config"
    font: verdana-9px-italic
]])

local config = setupUI([[
Panel
  height: 225

  Label
    id: configItemEquip
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    margin-left: 0
    margin-right: 83
    margin-top: 5
    text-align: center
    text: "Equip"
    font: verdana-11px-rounded

  BotItem
    id: defaultLeftItem
    anchors.left: parent.left
    anchors.top: configItemEquip.bottom
    margin-left: 30
    margin-top: 2

  Label
    id: configItemUnequip
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    margin-left: 86
    margin-right: 0
    margin-top: 5
    text-align: center
    text: "Unequip"
    font: verdana-11px-rounded

  BotItem
    id: defaultRightItem
    anchors.right: parent.right
    anchors.top: configItemUnequip.bottom
    margin-right: 30
    margin-top: 2

  CheckBox
    id: oldVersion
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: defaultRightItem.bottom
    text: "Old Version"
    color: #fe4400
    font: verdana-11px-rounded
    margin-left: 50
    margin-top: 10

  ComboBox
    id: slotComboBox
    anchors.left: parent.left
    anchors.top: oldVersion.bottom
    margin-left: 57
    margin-top: 10
    width: 65
    options: [Ring, Amulet]
    color: #41de17
    font: verdana-11px-rounded

  Label
    id: labelIMPERIALBAIAK
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: defaultRightItem.bottom
    margin-top: 70
    text-align: center
    text: "HP% Equip"
    font: verdana-11px-rounded

  HorizontalScrollBar
    id: scrollIMPERIALBAIAK
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: labelIMPERIALBAIAK.bottom
    margin-left: 5
    margin-right: 5
    margin-top: 5
    minimum: 1
    maximum: 100
    step: 1

  Label
    id: labelTwo
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: scrollIMPERIALBAIAK.bottom
    margin-top: 10
    text-align: center
    text: "HP% Unequip"
    font: verdana-11px-rounded

  HorizontalScrollBar
    id: scrollTwo
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: labelTwo.bottom
    margin-left: 5
    margin-right: 5
    margin-top: 5
    minimum: 1
    maximum: 100
    step: 1

  Label
    id: labelOwner
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: scrollTwo.bottom
    margin: 10 5 0 5
    text-align: center
    font: verdana-11px-rounded
]])
config:hide()

-- Storage
-- It will be saved in the Storage folder and choose your profile_1.json.
local panelStorage = "Ring/Amulet Settings"
storage[panelStorage] = storage[panelStorage] or
{
    enabled = false,
    defaultLeftItemId = 3051,
    defaultRightItemId = 3007,
    HPEQUIP = 50,
    HPUNEQUIP = 80,
    selectedItem = "Ring",
    oldVersion = true,
}

local actions = { ["Ring"] = "Ring", ["Amulet"] = "Amulet", }
macro(100, function()
    if not storage[panelStorage].enabled then
        return
    end

    local selectedOption = storage[panelStorage].selectedItem
    local action = actions[selectedOption]

    if action then
        local id
        if hppercent() >= storage[panelStorage].HPEQUIP then
            id = storage[panelStorage].defaultRightItemId
        elseif hppercent() <= storage[panelStorage].HPUNEQUIP then
            id = storage[panelStorage].defaultLeftItemId
        end

        if id then
            if action == "Ring" then
                if config.oldVersion:isChecked() then
                    if not getFinger() or getFinger():getId() ~= id then
                        moveToSlot(id, SlotFinger)
                    end
                else
                    g_game.equipItemId(id)
                end
            elseif action == "Amulet" then
                if config.oldVersion:isChecked() then
                    if not getNeck() or getNeck():getId() ~= id then
                        moveToSlot(id, SlotNeck)
                    end
                else
                    g_game.equipItemId(id)
                end
            end
        end
    end
end)
----------------->
config.slotComboBox.onOptionChange = function(widget)
    local selectedOption = widget:getText()
    storage[panelStorage].selectedItem = selectedOption
end

config.oldVersion:setChecked(storage[panelStorage].oldVersion or false)
config.oldVersion.onClick = function(widget)
    local currentCheckedState = widget:isChecked()
    storage[panelStorage].oldVersion = not currentCheckedState
    widget:setChecked(not currentCheckedState)
end

config.scrollIMPERIALBAIAK.onValueChange = function(scroll, value)
    storage[panelStorage].HPEQUIP = value
    config.labelIMPERIALBAIAK:setText("HP% Equip: " .. value)

    if value < 50 then
        config.labelIMPERIALBAIAK:setColor("#FF0000")
    elseif value < 80 then
        config.labelIMPERIALBAIAK:setColor("#FFFF00")
    else
        config.labelIMPERIALBAIAK:setColor("#00FF00")
    end
end

config.scrollIMPERIALBAIAK:setValue(storage[panelStorage].HPEQUIP)
config.labelIMPERIALBAIAK:setText("HP% Equip: " .. storage[panelStorage].HPEQUIP)

local initialValue = storage[panelStorage].HPEQUIP
if initialValue < 50 then
    config.labelIMPERIALBAIAK:setColor("#FF0000")
elseif initialValue < 80 then
    config.labelIMPERIALBAIAK:setColor("#FFFF00")
else
    config.labelIMPERIALBAIAK:setColor("#00FF00")
end

config.scrollTwo.onValueChange = function(scroll, value)
    storage[panelStorage].HPUNEQUIP = value
    config.labelTwo:setText("HP% Unequip: " .. value)

    if value < 50 then
        config.labelTwo:setColor("#FF0000")
    elseif value < 80 then
        config.labelTwo:setColor("#FFFF00")
    else
        config.labelTwo:setColor("#00FF00")
    end
end

config.scrollTwo:setValue(storage[panelStorage].HPUNEQUIP)
config.labelTwo:setText("HP% Unequip: " .. storage[panelStorage].HPUNEQUIP)

local initialValue = storage[panelStorage].HPUNEQUIP
if initialValue < 50 then
    config.labelTwo:setColor("#FF0000")
elseif initialValue < 80 then
    config.labelTwo:setColor("#FFFF00")
else
    config.labelTwo:setColor("#00FF00")
end

do
    config.defaultLeftItem:setItemId(storage[panelStorage].defaultLeftItemId)
    config.defaultLeftItem.onItemChange = function(self)
        storage[panelStorage].defaultLeftItemId = self:getItemId()
    end

    config.defaultRightItem:setItemId(storage[panelStorage].defaultRightItemId)
    config.defaultRightItem.onItemChange = function(self)
        storage[panelStorage].defaultRightItemId = self:getItemId()
    end
end
----------------->

-- Show or Hide Edit
local showEdit = false
ui.edit.onClick = function(widget)
    showEdit = not showEdit
    if showEdit then
        config:show()
    else
        config:hide()
    end
end

-- Main Window UI
ui.title:setOn(storage[panelStorage].enabled)
ui.title.onClick = function(widget)
    storage[panelStorage].enabled = not storage[panelStorage].enabled
    widget:setOn(storage[panelStorage].enabled)
end

-- Trade Mark --// FUNCTION
function setRainbowColor(time)
    local r = math.floor(127 * math.sin(time) + 128)
    local g = math.floor(127 * math.sin(time + 2 * math.pi / 3) + 128)
    local b = math.floor(127 * math.sin(time + 4 * math.pi / 3) + 128)
    return string.format("#%02X%02X%02X", r, g, b)
end

function setBrightWhiteGlowColor()
    return "#dfbae9"
end

local glowPosition = 1
local glowDirection = 1

macro(5, function()
    local text = "<@!--^ Imperial Baiak ^--!@>"
    local coloredText = {}

    local numChars = #text
    local glowRange = math.max(1, math.floor(numChars / 20))
    local time = os.clock() * 4

    for i = 1, numChars do
        local char = text:sub(i, i)
        local color = setRainbowColor(time + (i / 2))
        if math.abs(i - glowPosition) <= glowRange then
            color = setBrightWhiteGlowColor()
        end
        table.insert(coloredText, char)
        table.insert(coloredText, color)
    end

    glowPosition = glowPosition + glowDirection
    if glowPosition > numChars then
        glowPosition = numChars - 1
        glowDirection = -1
    elseif glowPosition < 1 then
        glowPosition = 2
        glowDirection = 1
    end

    if config.labelOwner and config.labelOwner.setColoredText then
        config.labelOwner:setColoredText(coloredText)
    end
end)
-- End Trade Mark

UI.Separator()