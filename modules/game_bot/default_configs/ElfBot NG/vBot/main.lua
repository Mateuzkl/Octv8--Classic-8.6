local botName = "<@!--^ Imperial Baiak ^--!@>"
local botName2 = "Discord: "
local lName = UI.Label(botName)
local lName2 = UI.Label(botName2)

function setRainbowColor(time)
    local r = math.floor(127 * math.sin(time) + 128)
    local g = math.floor(127 * math.sin(time + 2 * math.pi / 3) + 128)
    local b = math.floor(127 * math.sin(time + 4 * math.pi / 3) + 128)
    return string.format("#%02X%02X%02X", r, g, b)
end

function setOrangeGlowColor()
    return "#FFD700"
end

local glowPosition = 1
local glowDirection = 1

macro(10, function()
    local text = botName
    local coloredText = {}

    local numChars = #text
    local glowRange = math.max(1, math.floor(numChars / 20))
    local time = os.clock() * 4

    for i = 1, numChars do
        local char = text:sub(i, i)
        local color = setRainbowColor(time + (i / 2))
        if math.abs(i - glowPosition) <= glowRange then
            color = setOrangeGlowColor()
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

    if lName and lName.setColoredText then
        lName:setColoredText(coloredText)
    end

    local text2 = botName2
    local coloredText2 = {}

    local numChars2 = #text2

    for i = 1, numChars2 do
        local char = text2:sub(i, i)
        local color = setRainbowColor(time + (i / 2))
        table.insert(coloredText2, char)
        table.insert(coloredText2, color)
    end

    if lName2 and lName2.setColoredText then
        lName2:setColoredText(coloredText2)
    end
end)

UI.Separator()
