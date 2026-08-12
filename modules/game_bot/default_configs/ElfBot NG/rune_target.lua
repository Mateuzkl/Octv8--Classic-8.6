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
    !text: tr('Rune: Target')

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
RevideBox < CheckBox
  font: verdana-11px-rounded
  margin-top: 5
  margin-left: 5
  anchors.top: prev.bottom
  anchors.left: parent.left
  anchors.right: parent.right
  color: lightGray

Panel
  height: 60

  Label
    id: lureLabelLeft
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    margin-left: 0
    margin-right: 83
    margin-top: 5
    text-align: center
    text: "Area"
    font: verdana-11px-rounded

  BotItem
    id: defaultLeftItem
    anchors.left: parent.left
    anchors.top: lureLabelLeft.bottom
    margin-left: 30
    margin-top: 2

  Label
    id: lureLabelRight
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    margin-left: 80
    margin-right: 0
    margin-top: 5
    text-align: center
    text: "No Area"
    font: verdana-11px-rounded

  BotItem
    id: defaultRightItem
    anchors.right: parent.right
    anchors.top: lureLabelRight.bottom
    margin-right: 30
    margin-top: 2
]])
config:hide()

local bottonEdit = setupUI([[
RevideBox < CheckBox
  font: verdana-11px-rounded
  margin-top: 5
  margin-left: 5
  anchors.top: prev.bottom
  anchors.left: parent.left
  anchors.right: parent.right
  color: lightGray

Panel
  height: 20

  CheckBox
    id: playerScreen
    anchors.top: parent.top
    text: playerinScreen
    anchors.left: parent.left
    anchors.top: parent.top
    margin-left: 30
    margin-top: 5

  Label
    id: playerScreenLabel
    anchors.left: playerScreen.right
    anchors.top: playerScreen.top
    margin-left: 5
    text: "Player in Screen"
    color: #fe4400
    font: verdana-11px-rounded
]])
bottonEdit:hide()

local targetCountPanel = setupUI([[
Panel
  id: targetPanel
  height: 60
  margin-top: 15

  Label
    id: labelIMPERIALBAIAK
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    margin: 0 5 0 5
    text-align: center
    text: "Monsters Count"
    font: verdana-11px-rounded

  HorizontalScrollBar
    id: scrollIMPERIALBAIAK
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-top: 5
    minimum: 2
    maximum: 10
    step: 1

  Label
    id: labelOwner
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: scrollIMPERIALBAIAK.bottom
    margin: 10 5 0 5
    text-align: center
    font: verdana-11px-rounded
]])
targetCountPanel:hide()

-- Storage
-- It will be saved in the Storage folder and choose your profile_1.json.
local panelStorage = "Rune Settings"
storage[panelStorage] = storage[panelStorage] or
    {
        enabled = false,
        defaultLeftItemId = 3161,
        defaultRightItemId = 3155,
        playersinScreen = false,
        targetCount = 2,
    }

macro(500, function()
    local target = g_game.getAttackingCreature()
    if not target then return end

    if not storage[panelStorage].enabled then
        return
    end

    local playerPosition = g_game.getLocalPlayer():getPosition()
    local monstersScreen = g_map.getSpectators(playerPosition, false)

    local function playerinScreen()
        for _, spec in ipairs(getSpectators()) do
            if spec ~= g_game.getLocalPlayer() and spec:isPlayer() then
                return true
            end
        end
        return false
    end

    local monsterCount = 0
    for _, creature in ipairs(monstersScreen) do
        if creature:isMonster() then
            local creaturePosition = creature:getPosition()
            local distance = math.sqrt((creaturePosition.x - playerPosition.x) ^ 2 +
                (creaturePosition.y - playerPosition.y) ^ 2)
            if distance <= 7 then
                monsterCount = monsterCount + 1
            end
        end
    end

    if bottonEdit.playerScreen:isChecked() then
        if monsterCount >= storage[panelStorage].targetCount then
            if findItem(storage[panelStorage].defaultLeftItemId) then
                useWith(storage[panelStorage].defaultLeftItemId, target)
            else
                print("> (Player in Screen) You dont have the left item in your backpack.")
            end
        else
            if findItem(storage[panelStorage].defaultRightItemId) then
                useWith(storage[panelStorage].defaultRightItemId, target)
            else
                print("> (Player in Screen) You dont have the right item in your backpack.")
            end
        end
    else
        if playerinScreen() then
            if findItem(storage[panelStorage].defaultRightItemId) then
                useWith(storage[panelStorage].defaultRightItemId, target)
            else
                print("> (Player in Screen (Option Unchecked)) You dont have the left item in your backpack.")
            end
        else
            if monsterCount >= storage[panelStorage].targetCount then
                if findItem(storage[panelStorage].defaultLeftItemId) then
                    useWith(storage[panelStorage].defaultLeftItemId, target)
                else
                    print("> (No Players) You dont have the left item in your backpack.")
                end
            else
                if findItem(storage[panelStorage].defaultRightItemId) then
                    useWith(storage[panelStorage].defaultRightItemId, target)
                else
                    print("> (No Players) You dont have the right item in your backpack.")
                end
            end
        end
    end
end)

targetCountPanel.scrollIMPERIALBAIAK.onValueChange = function(scroll, value)
    targetCount = value
    storage[panelStorage].targetCount = targetCount
    targetCountPanel.labelIMPERIALBAIAK:setText("Monsters Count: " .. targetCount)
end

targetCountPanel.scrollIMPERIALBAIAK:setValue(storage[panelStorage].targetCount)
targetCountPanel.labelIMPERIALBAIAK:setText("Monsters Count: " .. storage[panelStorage].targetCount)

bottonEdit.playerScreen:setChecked(storage[panelStorage].playersinScreen or false)
bottonEdit.playerScreen.onClick = function(widget)
    local currentCheckedState = widget:isChecked()
    storage[panelStorage].playersinScreen = not currentCheckedState
    widget:setChecked(not currentCheckedState)
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

-- Show or Hide Edit
local showEdit = false
ui.edit.onClick = function(widget)
    showEdit = not showEdit
    if showEdit then
        config:show()
        bottonEdit:show()
        targetCountPanel:show()
    else
        config:hide()
        bottonEdit:hide()
        targetCountPanel:hide()
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

    if targetCountPanel.labelOwner and targetCountPanel.labelOwner.setColoredText then
        targetCountPanel.labelOwner:setColoredText(coloredText)
    end
end)
-- End Trade Mark

UI.Separator()
