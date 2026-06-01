

local OPEN_FRAMES = {
    "/game_notifications/assets/images/infobanner/backdrop-infobanner-anim0",
    "/game_notifications/assets/images/infobanner/backdrop-infobanner-anim1",
    "/game_notifications/assets/images/infobanner/backdrop-infobanner-anim2", 
    "/game_notifications/assets/images/infobanner/backdrop-infobanner-anim3",
    "/game_notifications/assets/images/infobanner/backdrop-infobanner-anim4",
    "/game_notifications/assets/images/infobanner/backdrop-infobanner-anim5",
    "/game_notifications/assets/images/infobanner/backdrop-infobanner-anim6", 
    "/game_notifications/assets/images/infobanner/backdrop-infobanner-anim7"
}

local MAX_WIDTH = 289
local BANNER_HEIGHT = 88
local FRAME_MS = 45
local DEFAULT_HOLD_MS = 3000
local FADE_IN_MS = 400
local FADE_OUT_MS = 300
local FADE_INTERVAL_MS = 20
local ICON_SHOW_PROGRESS = 0.25
local ICON_HIDE_PROGRESS = 0.25
local BANNER_MARGIN_OFFSET = 10
local ANIM_OFFSET = 10
local TOTAL_FRAMES = #OPEN_FRAMES

local eventCategory = {
    CLIENT_EVENT_TYPE_SIMPLE = 1,
    CLIENT_EVENT_TYPE_ACHIEVEMENT = 2,
    CLIENT_EVENT_TYPE_TITLE = 3,
    CLIENT_EVENT_TYPE_LEVEL = 4,
    CLIENT_EVENT_TYPE_SKILL = 5,
    CLIENT_EVENT_TYPE_BESTIARY = 6,
    CLIENT_EVENT_TYPE_BOSSTIARY = 7,
    CLIENT_EVENT_TYPE_QUEST = 8,
    CLIENT_EVENT_TYPE_COSMETIC = 9,
    CLIENT_EVENT_TYPE_PROFICIENCY = 10,
    CLIENT_EVENT_TYPE_LAST = 11
}

local eventType = {
    CLIENT_EVENT_NONE = 0,
    CLIENT_EVENT_BOSSDEFEATED = 1,
    CLIENT_EVENT_DEATHPVE = 2,
    CLIENT_EVENT_DEATHPVP = 3,
    CLIENT_EVENT_PLAYERKILLASSIST = 4,
    CLIENT_EVENT_PLAYERKILL = 5,
    CLIENT_EVENT_PLAYERATTACKING = 6,
    CLIENT_EVENT_TREASUREFOUND = 7,
    CLIENT_EVENT_GIFTOFLIFE = 8,
    CLIENT_EVENT_ATTACKSTOPPED = 9,
    CLIENT_EVENT_CAPACITYLIMIT = 10,
    CLIENT_EVENT_OUTOFAMMO = 11,
    CLIENT_EVENT_TARGETTOOCLOSE = 12,
    CLIENT_EVENT_OUTOFSOULPOINTS = 13,
    CLIENT_EVENT_TUTORIALCOMPLETE = 14,
    CLIENT_EVENT_LAST = 15
}

local skinType = {
    outfit = 0,
    addon1 = 1,
    addon2 = 2,
    mount = 3
}

local SkillId = {
    Magic = 1,
    Sword = 2,
    Club = 3,
    Axe = 4,
    Fist = 5,
    Distance = 6,
    Shielding = 7,
    Fishing = 8
}

local skillNames = {
    [SkillId.Magic]     = { name = "Magic Level",        icon = "magic" },
    [SkillId.Sword]     = { name = "Sword Fighting",     icon = "sword" },
    [SkillId.Club]      = { name = "Club Fighting",      icon = "club" },
    [SkillId.Axe]       = { name = "Axe Fighting",       icon = "axe" },
    [SkillId.Fist]      = { name = "Fist Fighting",      icon = "fist" },
    [SkillId.Distance]  = { name = "Distance Fighting",  icon = "distance" },
    [SkillId.Shielding] = { name = "Shielding",          icon = "shielding" },
    [SkillId.Fishing]   = { name = "Fishing",            icon = "fishing" }
}

local infoPopUp = {
    [eventCategory.CLIENT_EVENT_TYPE_COSMETIC] = {
        --type(int), lookType(int), skinName(string), skinType(int)
        {
            title = "Outfit Unlocked",
            description = "You have unlocked '%s'", --skinName
            hasCreatureId = true,
            img = "/game_notifications/assets/images/nodo/icon-infobanner-unlock"
        }
    },
    [eventCategory.CLIENT_EVENT_TYPE_BOSSTIARY] = {
        --type(int), raceId(int), progressLevel(int)
        {
            title = "Bosstiary Progress",
            description = "You have progressed '%s'",--progressLevel
            hasRaceId = true,
            img = "/game_notifications/assets/images/nodo/icon-infobanner-unlock"
        }
    },
    [eventCategory.CLIENT_EVENT_TYPE_BESTIARY] = {
        --type(int), raceId(int), progressLevel(int)
        {
            title = "Bestiary Progress",
            description = "You have progressed '%s'", --progressLevel
            hasRaceId = true,
            img = "/game_notifications/assets/images/nodo/icon-infobanner-unlock"
        }
    },
    [eventCategory.CLIENT_EVENT_TYPE_ACHIEVEMENT] = {
        -- type(int), name(string)
        {
            title = "New Achievement",
            description = "You have earned '%s'", --name
            img = "/game_notifications/assets/images/nodo/icon-infobanner-achievements"
        }
    },
    [eventCategory.CLIENT_EVENT_TYPE_TITLE] = {
        -- type(int), name(string)
        {
            title = "Title Gained",
            description = "You have earned '%s'", --name
            img = "/game_notifications/assets/images/nodo/icon-infobanner-title"
        }
    },
    [eventCategory.CLIENT_EVENT_TYPE_PROFICIENCY] = {
        -- type(int), itemId(int), message(string)
        {
            title = "Weapon Proficiency",
            description = "you have improved '%s'", -- message
            hasItemId = true,
            img = "/game_notifications/assets/images/nodo/icon-infobanner-unlock"
        }
    },
    [eventCategory.CLIENT_EVENT_TYPE_QUEST] = {
        -- type(int), questName(string), isCompleted(bool)
        [true] = { -- isCompleted(bool)
            title = "Quest completed",
            description = "you have finished '%s'",
            img = "/game_notifications/assets/images/nodo/icon-infobanner-quests"
        },
        [false] = { -- isCompleted(bool)
            title = "Quest started",
            description = "you have begun '%s'",
            img = "/game_notifications/assets/images/nodo/icon-infobanner-quests"
        }
    },
    [eventCategory.CLIENT_EVENT_TYPE_LEVEL] = {
        {
            title = "Level %d!",
            description = "You gained hit points, mana, and capacity.",
            img = "/game_notifications/assets/images/nodo/icon-infobanner-levelup"
        }
    },
    [eventCategory.CLIENT_EVENT_TYPE_SKILL] = {
        -- type(int), skillId(int), level(int)
        {
            title = "%s",
            description = "your skill has advanced to level %d",
            img = "/game_notifications/assets/images/nodo/icon-infobanner-skill-%s"
        }
    },
    [eventCategory.CLIENT_EVENT_TYPE_SIMPLE] = {
        -- type(int), eventType(int)  
        [eventType.CLIENT_EVENT_CAPACITYLIMIT] = {
            title = "Capacity Limit",
            description = "Remove items before adding new ones.",
            img = "/game_notifications/assets/images/nodo/icon-infobanner-quests"
        },
        [eventType.CLIENT_EVENT_OUTOFAMMO] = {
            title = "Out of Ammunition",
            description = "You have no arrow or bolt equipped.",
            img = "/game_notifications/assets/images/nodo/icon-infobanner-hint"
        },
        [eventType.CLIENT_EVENT_TARGETTOOCLOSE] = {
            title = "Target Too Close",
            description = "You are using a ranged auto-attack at melee distance.",
            img = "/game_notifications/assets/images/nodo/icon-infobanner-hint"
        },
        [eventType.CLIENT_EVENT_OUTOFSOULPOINTS] = {
            title = "Out of Soul Points",
            description = "You don't have enough soul points to cast this spell.",
            img = "/game_notifications/assets/images/nodo/icon-infobanner-hint"
        },
        [eventType.CLIENT_EVENT_TUTORIALCOMPLETE] = {
            title = "Off to New Shores",
            description = "Leave the village and set sail to start your real adventure.",
            img = "/game_notifications/assets/images/nodo/icon-infobanner-offtonewshores"
        }
    }
}

-- LuaFormatter on

notificationsController.event = nil
notificationsController.state = "idle"
notificationsController.queue = {}
notificationsController.widgets = {}
notificationsController.lastReceivedLevels = {}
-- Track recently received skill events to avoid enqueuing duplicates
notificationsController.lastReceivedSkills = {}
notificationsController.lastShownSkills = {}

function showLevelUpBanner(level)
    if notificationsController then
        notificationsController:showLevelUp(level)
    end
end

function notificationsController:showLevelUp(level)
    level = tonumber(level)
    if not level or level <= 0 then
        return
    end

    self:onClientEvent(eventCategory.CLIENT_EVENT_TYPE_LEVEL, level)
end

function notificationsController:onClientEvent(eventCat, ...)
    if modules.client_options and modules.client_options.getOption and modules.client_options.getOption("showInfoBanner") == false then
        g_logger.debug("The server has sent infobaner, but the checkbox in client_options is disabled..")
        return
    end
    local args = {...}
    if eventCat == eventCategory.CLIENT_EVENT_TYPE_LEVEL then
        local level = tonumber(args[1])
        if not level then
            return
        end

        local player = g_game.getLocalPlayer()
        local key = player and player:getName() or "_default"
        notificationsController.lastReceivedLevels = notificationsController.lastReceivedLevels or {}
        if notificationsController.lastReceivedLevels[key] == level then
            return
        end

        notificationsController.lastReceivedLevels[key] = level
        scheduleEvent(function()
            if notificationsController and notificationsController.lastReceivedLevels and notificationsController.lastReceivedLevels[key] == level then
                notificationsController.lastReceivedLevels[key] = nil
            end
        end, 3000)
    end

    -- Prevent duplicate skill notifications when identical events arrive
    -- in quick succession (e.g., both LocalPlayer and g_game emitting the same).
    if eventCat == eventCategory.CLIENT_EVENT_TYPE_SKILL then
        local skillId = args[1]
        local level = args[2]
        notificationsController.lastReceivedSkills = notificationsController.lastReceivedSkills or {}
        -- If we already received the same skill/level recently, skip it.
        if notificationsController.lastReceivedSkills[skillId] == level then
            return
        end
        -- Record it and schedule a cleanup so we can receive new levels later.
        notificationsController.lastReceivedSkills[skillId] = level
        scheduleEvent(function()
            if notificationsController and notificationsController.lastReceivedSkills then
                notificationsController.lastReceivedSkills[skillId] = nil
            end
        end, 3000)
        -- Also ignore if we've already shown this exact level previously.
        if notificationsController.lastShownSkills and notificationsController.lastShownSkills[skillId] == level then
            return
        end
    end
    local popupTemplate = nil
    if eventCat == eventCategory.CLIENT_EVENT_TYPE_SIMPLE then
        local eventType = args[1]
        popupTemplate = infoPopUp[eventCat] and infoPopUp[eventCat][eventType]

    elseif eventCat == eventCategory.CLIENT_EVENT_TYPE_QUEST then
        local isCompleted = args[2] == 1 or args[2] == true
        popupTemplate = infoPopUp[eventCat] and infoPopUp[eventCat][isCompleted]

    elseif infoPopUp[eventCat] and infoPopUp[eventCat][1] then
        popupTemplate = infoPopUp[eventCat][1]
    end

    if not popupTemplate then
        return
    end

    local title = popupTemplate.title
    local description = popupTemplate.description
    local img = popupTemplate.img

    local extraData = {}

    if eventCat == eventCategory.CLIENT_EVENT_TYPE_QUEST then
        local questName = args[1]
        title = type(title) == 'string' and title:format(questName) or title
        description = type(description) == 'string' and description:format(questName) or description

    elseif eventCat == eventCategory.CLIENT_EVENT_TYPE_PROFICIENCY then
        local itemId = args[1]
        local message = args[2]
        description = type(description) == 'string' and description:format(message) or description
        if popupTemplate.hasItemId then
            extraData.itemId = itemId
        end

    elseif eventCat == eventCategory.CLIENT_EVENT_TYPE_LEVEL then
        local level = args[1]
        title = type(title) == 'string' and title:format(level) or title

    elseif eventCat == eventCategory.CLIENT_EVENT_TYPE_SKILL then
        local skillId = args[1]
        local level = args[2]
        local data = skillNames[skillId] or {
            name = "Skill",
            icon = "fist"
        }
        title = type(title) == 'string' and title:format(data.name) or title
        description = type(description) == 'string' and description:format(level) or description
        img = type(img) == 'string' and img:format(data.icon) or img
        -- expose skill id/level to the show() call for dedupe logic
        extraData.skillId = skillId
        extraData.level = level

    elseif eventCat == eventCategory.CLIENT_EVENT_TYPE_COSMETIC then
        local lookType = args[1]
        local skinName = args[2]
        local skinType = tonumber(args[3])
        if skinType == 1 then
            skinName = skinName .. " (Addon 1)"
        elseif skinType == 2 then
            skinName = skinName .. " (Addon 2)"
        end
        description = type(description) == 'string' and description:format(skinName) or description
        if popupTemplate.hasCreatureId then
            extraData.creatureId = lookType
            extraData.skinType = skinType
        end
    elseif eventCat == eventCategory.CLIENT_EVENT_TYPE_BESTIARY or eventCat == eventCategory.CLIENT_EVENT_TYPE_BOSSTIARY then
        local raceId = args[1]
        local progressLevel = args[2]
        description = type(description) == 'string' and description:format(progressLevel) or description
        if popupTemplate.hasRaceId then
            extraData.raceId = raceId
        end

    elseif eventCat == eventCategory.CLIENT_EVENT_TYPE_ACHIEVEMENT then
        local name = args[1]
        description = type(description) == 'string' and description:format(name) or description

    elseif eventCat == eventCategory.CLIENT_EVENT_TYPE_TITLE then
        local name = args[1]
        description = type(description) == 'string' and description:format(name) or description
    end

    self:show(title, description, img, DEFAULT_HOLD_MS, extraData)
end

function infoBanner_onTerminate()
    notificationsController:hideImmediate()
    if notificationsController.ui then
        notificationsController:unloadHtml()
    end
end

function notificationsController:ensure()
    if self.ui and not self.ui:isDestroyed() then
        return
    end

    self:loadHtml("templates/infobanner.html", modules.game_interface.getMapPanel())
    self.ui:hide()

    self.widgets = {
        paper = self:findWidget("#paper"),
        anim = self:findWidget("#animation"),
        icon = self:findWidget("#icon"),
        title = self:findWidget("#title"),
        desc = self:findWidget("#desc"),
        append = self:findWidget("#append"),
        fadeTexts = self.ui:querySelectorAll(".fade-text"),
        fadeIcons = self.ui:querySelectorAll(".fade-icon")
    }

    -- HTML Widget initialized
end

function notificationsController:updateBannerPosition()
    if not self.ui or self.ui:isDestroyed() then
        return
    end

    local statsBarHeight = 0
    local statsBarApi = modules.game_interface and modules.game_interface.StatsBar
    if statsBarApi and statsBarApi.getCurrentStatsBar then
        local statsBar = statsBarApi.getCurrentStatsBar()
        if statsBar and not statsBar:isDestroyed() and type(statsBar.getHeight) == 'function' then
            statsBarHeight = statsBar:getHeight()
        end
    end

    local marginTop = statsBarHeight + BANNER_MARGIN_OFFSET
    self.ui:setMarginTop(marginTop)
    -- Banner margin-top set
end

function notificationsController:cancelEvent()
    if self.event then
        removeEvent(self.event)
        self.event = nil
    end
end

function notificationsController:show(title, desc, img, holdMs, extraData)
    self:ensure()
    -- Adding to queue -> title

    -- If this is a skill event, collapse existing queued entries for the
    -- same skill so we keep only the highest level. This prevents the
    -- banner from showing stale intermediate levels as the final one.
    local item = {
        title = title,
        desc = desc,
        img = img,
        holdMs = holdMs or DEFAULT_HOLD_MS,
        extraData = extraData or {}
    }

    if item.extraData and item.extraData.skillId and item.extraData.level then
        local skillId = item.extraData.skillId
        local newLevel = item.extraData.level
        local i = 1
        while i <= #self.queue do
            local q = self.queue[i]
            if q and q.extraData and q.extraData.skillId == skillId then
                local qLevel = q.extraData.level or 0
                if qLevel >= newLevel then
                    -- There's already a queued equal-or-higher level; skip adding
                    -- Skipping enqueue: existing queued level >= new level
                    return
                else
                    -- Remove the older queued lower level and continue
                    table.remove(self.queue, i)
                end
            else
                i = i + 1
            end
        end
    end

    table.insert(self.queue, item)
    if self.state == "idle" then
        self:processNext()
    end
end

function notificationsController:setWidgetsOpacity(widgets, opacity)
    for _, widget in ipairs(widgets) do
        widget:setOpacity(opacity)
    end
end

function notificationsController:setContentOpacity(opacity)
    if self.widgets.fadeTexts then
        self:setWidgetsOpacity(self.widgets.fadeTexts, opacity)
    end
end

function notificationsController:setLeftIconsOpacity(opacity)
    if self.widgets.fadeIcons then
        self:setWidgetsOpacity(self.widgets.fadeIcons, opacity)
    end
end

function notificationsController:setPaperSize(width)
    local paper = self.widgets.paper
    paper:setWidth(width)
    paper:setImageRect({
        x = 0,
        y = 0,
        width = width,
        height = BANNER_HEIGHT
    })
end

function notificationsController:resetBanner()
    local w = self.ui
    w:setOpacity(1.0)
    w:setMarginLeft(0)
    w:show()
    self:setContentOpacity(0)
    self:setLeftIconsOpacity(0)
    self:setPaperSize(0)

    if self.widgets.append then
        self.widgets.append:destroyChildren()
    end

    local anim = self.widgets.anim
    anim:show()
    anim:setMarginLeft(0)
    anim:setImageSource(OPEN_FRAMES[1])
end

function notificationsController:processNext()
    self:cancelEvent()
    if #self.queue == 0 then
        -- Queue empty. Unloading UI.
        self.state = "idle"
        if self.ui then
            self:unloadHtml()
            self.widgets = {}
        end
        return
    end
    self:updateBannerPosition()
    -- Pop next non-duplicate item from the queue. If the next queued skill
    -- event was already shown, skip it and continue to the next.
    local data = nil
    while #self.queue > 0 do
        data = table.remove(self.queue, 1)
        if data and data.extraData and data.extraData.skillId and data.extraData.level and
           notificationsController.lastShownSkills and
           notificationsController.lastShownSkills[data.extraData.skillId] == data.extraData.level then
            -- Skipping queued already shown skill
            data = nil
        else
            break
        end
    end
    if not data then
        -- nothing to process after skipping duplicates
        if #self.queue == 0 then
            -- Queue empty after skipping duplicates. Unloading UI.
            self.state = "idle"
            if self.ui then
                self:unloadHtml()
                self.widgets = {}
            end
            return
        end
    end
    if not self.ui or self.ui:isDestroyed() then
        self.state = "idle"
        return
    end
    self:resetBanner()
    if data.img then
        self.widgets.icon:setImageSource(data.img)
    end
    self.widgets.title:setText(data.title or "")
    self.widgets.desc:setText(data.desc or "")

    if data.extraData and self.widgets.append then
        local appendW = self.widgets.append
        appendW:destroyChildren()

        if data.extraData.itemId then
            local itemId = data.extraData.itemId
            local html = string.format([[
            <uiitem item-id="%d" style="width: 64px; height: 64px"></uiitem>
            ]], itemId)
            appendW:append(html)
        elseif data.extraData.raceId then
            local raceId = data.extraData.raceId
            local raceData = g_things.getRaceData(raceId)
            if not raceData or (raceData.raceId == 0 and (not raceData.outfit or raceData.outfit.type == 0)) then
                g_logger.warning(string.format("Creature with race id %s was not found.", raceId))
            else
                local html = string.format([[
                <uicreature style="width: 64px; height: 64px"/>
                ]])
                local outfit = appendW:append(html)
                outfit:setOutfit(raceData.outfit)
            end
        elseif data.extraData.creatureId then
            local html = string.format([[
            <uicreature outfit-id="%d" style="width: 64px; height: 64px"/>
            ]], data.extraData.creatureId)
            if data.extraData.skinType == skinType.outfit then
                local outfit = appendW:append(html)
                outfit:setOutfit({
                    type = data.extraData.creatureId
                })
            elseif data.extraData.skinType == skinType.addon1 or data.extraData.skinType == skinType.addon2 then
                local outfit = appendW:append(html)
                outfit:setOutfit({
                    type = data.extraData.creatureId,
                    addons = data.extraData.skinType
                })
            elseif data.extraData.skinType == skinType.mount then
                local outfit = appendW:append(html)
                outfit:setOutfit({
                    type = data.extraData.creatureId
                })
            end
        end
    end

    -- Mark the skill/level as shown now that we're about to open its banner.
    if data.extraData and data.extraData.skillId and data.extraData.level then
        notificationsController.lastShownSkills = notificationsController.lastShownSkills or {}
        notificationsController.lastShownSkills[data.extraData.skillId] = data.extraData.level
        -- Marked shown skill
    end

    self.state = "opening"
    -- Starting Banner ->
    self:animateOpen(data.holdMs)
end

function notificationsController:animateOpen(holdMs)
    local frame = 1
    local iconsShown = false
    local anim = self.widgets.anim
    local function animate()
        if not self.ui or self.ui:isDestroyed() then
            return
        end
        frame = frame + 1
        if frame > TOTAL_FRAMES then
            self:finishOpening(holdMs)
            return
        end
        local progress = (frame - 1) / (TOTAL_FRAMES - 1)
        local currentWidth = MAX_WIDTH * progress
        self:setPaperSize(currentWidth)
        anim:setMarginLeft(currentWidth - ANIM_OFFSET)
        anim:setImageSource(OPEN_FRAMES[frame])
        if not iconsShown and progress >= ICON_SHOW_PROGRESS then
            self:setLeftIconsOpacity(1)
            iconsShown = true
        end
        self.event = scheduleEvent(animate, FRAME_MS)
    end
    self.event = scheduleEvent(animate, FRAME_MS)
end

function notificationsController:finishOpening(holdMs)
    -- Opening finished. Holding.
    self:setPaperSize(MAX_WIDTH)
    self.widgets.anim:hide()
    self.ui:setMarginLeft(0)
    self.state = "holding"
    self:fadeIn(holdMs)
end

function notificationsController:fadeIn(holdMs)
    local startTime = g_clock.millis()
    local function fadeInText()
        if not self.ui or self.ui:isDestroyed() then
            self:cancelEvent()
            self.state = "idle"
            return
        end
        local elapsed = g_clock.millis() - startTime
        local t = math.min(1, elapsed / FADE_IN_MS)
        self:setContentOpacity(t)
        if t < 1 then
            self.event = scheduleEvent(fadeInText, FADE_INTERVAL_MS)
        else
            self.event = scheduleEvent(function()
                self:close()
            end, holdMs)
        end
    end
    self.event = scheduleEvent(fadeInText, FADE_INTERVAL_MS)
end

function notificationsController:close()
    if not self.ui or self.ui:isDestroyed() then
        return
    end
    self:cancelEvent()
    self.state = "closing"
    -- Closing phase.
    self:fadeOut()
end

function notificationsController:fadeOut()
    local startTime = g_clock.millis()
    local function fadeOutText()
        if not self.ui or self.ui:isDestroyed() then
            self:cancelEvent()
            self.state = "idle"
            return
        end
        local elapsed = g_clock.millis() - startTime
        local t = math.min(1, elapsed / FADE_OUT_MS)
        self:setContentOpacity(1 - t)
        if t < 1 then
            self.event = scheduleEvent(fadeOutText, FADE_INTERVAL_MS)
        else
            self:animateClose()
        end
    end
    self.event = scheduleEvent(fadeOutText, FADE_INTERVAL_MS)
end

function notificationsController:animateClose()
    local frame = TOTAL_FRAMES
    local iconsHidden = false
    local anim = self.widgets.anim
    anim:show()
    local function retract()
        if not self.ui or self.ui:isDestroyed() then
            self:cancelEvent()
            self.state = "idle"
            return
        end
        frame = frame - 1
        if frame < 1 then
            -- Retract finished. Running Exit.
            self:setPaperSize(0)
            anim:setMarginLeft(0)
            anim:setImageSource(OPEN_FRAMES[1])
            self:exit()
            return
        end
        local progress = (frame - 1) / (TOTAL_FRAMES - 1)
        local currentWidth = MAX_WIDTH * progress
        self:setPaperSize(currentWidth)
        anim:setMarginLeft(currentWidth - ANIM_OFFSET)
        anim:setImageSource(OPEN_FRAMES[frame])
        if not iconsHidden and progress <= ICON_HIDE_PROGRESS then
            self:setLeftIconsOpacity(0)
            iconsHidden = true
        end
        self.event = scheduleEvent(retract, FRAME_MS)
    end
    self.event = scheduleEvent(retract, FRAME_MS)
end

function notificationsController:exit()
    if not self.ui or self.ui:isDestroyed() then
        return
    end
    self:cancelEvent()
    -- Exit finished.
    self.ui:hide()
    self.ui:setOpacity(1)
    self.state = "idle"
    self:processNext()
end

function notificationsController:hideImmediate()
    self:cancelEvent()
    if self.ui then
        self:unloadHtml()
        self.widgets = {}
    end
    self.queue = {}
    self.state = "idle"
    -- Reset Immediate and Unloaded.
end
