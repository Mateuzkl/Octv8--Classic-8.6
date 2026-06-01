notificationsController = Controller:new()
function notificationsController:onInit()
    self:registerEvents(g_game, {
        onClientEvent = function(...)
            self:onClientEvent(...)
        end,
    })
end
function notificationsController:onTerminate()
    infoBanner_onTerminate()
end

local playerLevels = {}
local playerSkills = {}
local playerMagicLevel = nil
-- Track last announced skill levels to avoid duplicate banners
notificationsController.lastShownSkills = {}

local otcToProtoSkill = {
    [0] = 5, -- Fist
    [1] = 3, -- Club
    [2] = 2, -- Sword
    [3] = 4, -- Axe
    [4] = 6, -- Distance
    [5] = 7, -- Shielding
    [6] = 8  -- Fishing
}

local function primePlayerStats()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    playerLevels[player:getName()] = player:getLevel()
    playerMagicLevel = player:getMagicLevel()

    for otcSkillId, protoSkillId in pairs(otcToProtoSkill) do
        playerSkills[protoSkillId] = player:getSkillLevel(otcSkillId)
    end
end

function notificationsController:onGameStart()
    playerLevels = {}
    playerSkills = {}
    playerMagicLevel = nil

    self:registerEvents(LocalPlayer, {
        onLevelChange = function(player, level, percent)
            local charName = player:getName()
            if not playerLevels[charName] then
                playerLevels[charName] = level
                return
            end
            if level > playerLevels[charName] then
                playerLevels[charName] = level
                self:onClientEvent(4, level)
            end
        end,
        onMagicLevelChange = function(player, level, percent)
            if not playerMagicLevel then
                playerMagicLevel = level
                return
            end
            if level > playerMagicLevel then
                playerMagicLevel = level
                self:onClientEvent(5, 1, level)
            end
        end,
        onSkillChange = function(player, id, level, percent)
            local protoId = otcToProtoSkill[id]
            if not protoId then return end
            if not playerSkills[protoId] then
                playerSkills[protoId] = level
                return
            end
            local oldLevel = playerSkills[protoId]
            if level > oldLevel then
                -- Send intermediate events for each level increment so banners
                -- show progression (11,12,13...) instead of jumping or repeating.
                for l = oldLevel + 1, level do
                    playerSkills[protoId] = l
                    g_logger.debug(string.format("notifications: emitting skill event protoId=%s level=%s (old=%s)", tostring(protoId), tostring(l), tostring(oldLevel)))
                    self:onClientEvent(5, protoId, l)
                end
            end
        end
    })

    primePlayerStats()
end

function notificationsController:onGameEnd()
    playerLevels = {}
    playerSkills = {}
    playerMagicLevel = nil
    infoBanner_onTerminate()
end
