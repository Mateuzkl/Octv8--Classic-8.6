setDefaultTab("Main")

local panelName = "fbnModule"
if not storage[panelName] then
  storage[panelName] = {}
end
local settings = storage[panelName]

fbnWindows = UI.createWindow('FbnWindow', rootWidget)
fbnWindows:hide()
fbnWindows.closeButton.onClick = function(widget)
    fbnWindows:hide()
end

fbnWindows.onGeometryChange = function(widget, old, new)
    if old.height == 0 then return end
    settings.height = new.height
end

fbnWindows:setHeight(settings.height or 360)

local rightPanel = fbnWindows.content.right
local leftPanel = fbnWindows.content.left

local addCheckBox = function(id, title, defaultValue, dest, tooltip)
    local widget = UI.createWidget('FbnCheckBox', dest)
        widget.onClick = function()
        widget:setOn(not widget:isOn())
        settings[id] = widget:isOn()
        if id == "checkPlayer" then
            local label = rootWidget.newHealer.targetSettings.vocations.title
            if not widget:isOn() then
                label:setColor("#d9321f")
                label:setTooltip("! WARNING ! \nTurn on check players in extras to use this feature!")
            else
                label:setColor("#dfdfdf")
                label:setTooltip("")
            end
        end
    end
    widget:setText(title)
    widget:setTooltip(tooltip)
    if settings[id] == nil then
        widget:setOn(defaultValue)
    else
        widget:setOn(settings[id])
    end
    settings[id] = widget:isOn()
end

local addItem = function(id, title, defaultItem, dest, tooltip)
    local widget = UI.createWidget('FbnItem', dest)
        widget.text:setText(title)
        widget.text:setTooltip(tooltip)
        widget.item:setTooltip(tooltip)
        widget.item:setItemId(settings[id] or defaultItem)
        widget.item.onItemChange = function(widget)
        settings[id] = widget:getItemId()
    end
    settings[id] = settings[id] or defaultItem
end

local addTextEdit = function(id, title, defaultValue, dest, tooltip)
    local widget = UI.createWidget('FbnTextEdit', dest)
        widget.text:setText(title)
        widget.textEdit:setText(settings[id] or defaultValue or "")
        widget.text:setTooltip(tooltip)
        widget.textEdit.onTextChange = function(widget,text)
        settings[id] = text
    end
    settings[id] = settings[id] or defaultValue or ""
end

local addScrollBar = function(id, title, min, max, defaultValue, dest, tooltip)
    local widget = UI.createWidget('FbnScrollBar', dest)
    widget.text:setTooltip(tooltip)
    widget.scroll.onValueChange = function(scroll, value)
    widget.text:setText(title .. ": " .. value)
        if value == 0 then
            value = 1
        end
        settings[id] = value
    end
    widget.scroll:setRange(min, max)
    widget.scroll:setTooltip(tooltip)

    if max-min > 1000 then
        widget.scroll:setStep(100)
    elseif max-min > 100 then
        widget.scroll:setStep(10)
    end

    widget.scroll:setValue(settings[id] or defaultValue)
    widget.scroll.onValueChange(widget.scroll, widget.scroll:getValue())
end

UI.Button("ElfBot Scripts: Module v1", function()
    fbnWindows:show()
    fbnWindows:raise()
    fbnWindows:focus()
end)
UI.Separator()


-- ! Scripts !----------! Scripts !--------------! Scripts !--------------! Scripts !------------

addCheckBox("hideText", "Hide: Text Spells", false, leftPanel, "It is used to hide spell texts.")
if true then
    macro(100, function()
        onStaticText(function(thing, text)
            if not settings.hideText then return end
            if not text:find('says:') then
                g_map.cleanTexts()
            end
        end)
    end)
end

addCheckBox("antiRed", "AntiRed/StopBot", false, leftPanel, "When it reaches 10 frags the bot automatically stops.")
local fragtext = "Warning! the murder of"
local frags = 0

if true then
    macro(100, function()
        onTextMessage(function(mode, text)
            if not settings.antiRed then return end
            if text:lower():find(fragtext) then
                frags = frags + 1
                if frags >= 10 then
                    TargetBot.setOff()
                    CaveBot.setOff()
                end
            end
        end)
    end)
end

addCheckBox("dance", "Dance: AntiAFK", false, leftPanel, "To avoid kick.")
if true then
    macro(100, function()
        if not settings.dance then return end
        turn(math.random(0,3))
    end)
end

addCheckBox("fasthands", "Fast Hands: Pickup", false, leftPanel, "Automatically picks up items around you.")
local pickUp = {268, 236, 11692,11684,11658,11479,10227,9642,9586,9087,9058,8778,8153,8150,8150,7443,6526,5952,5904,3483,3233,3150,3043,3040,3035,944,819,126,3031} -- lista de items

if true then
    macro(100, function()
        if not settings.fasthands then return end
        if freecap() < 200 then return end
        for x = -1, 1 do
            for y = -1, 1 do
                local tile = g_map.getTile({x = posx() + x, y = posy() + y, z = posz()})
                if tile then
                    local things = tile:getThings()
                    for _, item in pairs(things) do
                        if table.find(pickUp, item:getId()) then
                            local containers = getContainers()
                            for _, container in pairs(containers) do
                                g_game.move(item, container:getSlotPosition(container:getItemsCount()), item:getCount())
                            end
                        end
                    end
                end
            end
        end
    end)
end

addCheckBox("autoExani", "AutoExaniHur", false, leftPanel, "Automatically does exani hur, when near a wall.")
local function WallDetect(pos, dir)
    local tile = g_map.getTile(pos)

    if not tile then
        return
    end
    use(tile:getTopUseThing())
    if not tile:isWalkable() then
        turn(dir)
        say('exani hur "up') -- jump "up"
        say('exani hur "down') -- jump "down"
    end
end

if true then
    local playerPos = pos()
    onKeyPress(function(keys)
        if not settings.autoExani then return end
        if keys == "Up" then
            playerPos = pos()
            playerPos.y = playerPos.y - 5
            WallDetect(playerPos, 0)
        elseif keys == "Down" then
            playerPos = pos()
            playerPos.y = playerPos.y + 5
            WallDetect(playerPos, 2)
        elseif keys == "Left" then
            playerPos = pos()
            playerPos.x = playerPos.x - 5
            WallDetect(playerPos, 3)
        elseif keys == "Right" then
            playerPos = pos()
            playerPos.x = playerPos.x + 5
            WallDetect(playerPos, 1)
        end
    end)
end
