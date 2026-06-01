Icons = {
	[PlayerStates.Poison] = {
		id = "condition_poisoned",
		path = "/images/game/states/poisoned",
		tooltip = tr("You are poisoned")
	},
	[PlayerStates.Burn] = {
		id = "condition_burning",
		path = "/images/game/states/burning",
		tooltip = tr("You are burning")
	},
	[PlayerStates.Energy] = {
		id = "condition_electrified",
		path = "/images/game/states/electrified",
		tooltip = tr("You are electrified")
	},
	[PlayerStates.Drunk] = {
		id = "condition_drunk",
		path = "/images/game/states/drunk",
		tooltip = tr("You are drunk")
	},
	[PlayerStates.ManaShield] = {
		id = "condition_magic_shield",
		path = "/images/game/states/magic_shield",
		tooltip = tr("You are protected by a magic shield")
	},
	[PlayerStates.Paralyze] = {
		id = "condition_slowed",
		path = "/images/game/states/slowed",
		tooltip = tr("You are paralysed")
	},
	[PlayerStates.Haste] = {
		id = "condition_haste",
		path = "/images/game/states/haste",
		tooltip = tr("You are hasted")
	},
	[PlayerStates.Swords] = {
		id = "condition_logout_block",
		path = "/images/game/states/logout_block",
		tooltip = tr("You may not logout during a fight")
	},
	[PlayerStates.Drowning] = {
		id = "condition_drowning",
		path = "/images/game/states/drowning",
		tooltip = tr("You are drowning")
	},
	[PlayerStates.Freezing] = {
		id = "condition_freezing",
		path = "/images/game/states/freezing",
		tooltip = tr("You are freezing")
	},
	[PlayerStates.Dazzled] = {
		id = "condition_dazzled",
		path = "/images/game/states/dazzled",
		tooltip = tr("You are dazzled")
	},
	[PlayerStates.Cursed] = {
		id = "condition_cursed",
		path = "/images/game/states/cursed",
		tooltip = tr("You are cursed")
	},
	[PlayerStates.PartyBuff] = {
		id = "condition_strengthened",
		path = "/images/game/states/strengthened",
		tooltip = tr("You are strengthened")
	},
	[PlayerStates.PzBlock] = {
		id = "condition_protection_zone_block",
		path = "/images/game/states/protection_zone_block",
		tooltip = tr("You may not logout or enter a protection zone")
	},
	[PlayerStates.Pz] = {
		id = "condition_protection_zone",
		path = "/images/game/states/protection_zone",
		tooltip = tr("You are within a protection zone")
	},
	[PlayerStates.Bleeding] = {
		id = "condition_bleeding",
		path = "/images/game/states/bleeding",
		tooltip = tr("You are bleeding")
	},
	[PlayerStates.Hungry] = {
		id = "condition_hungry",
		path = "/images/game/states/hungry",
		tooltip = tr("You are hungry")
	}
}
local iconsTable = {
	Fishing = 7,
	Distance = 3,
	Shielding = 5,
	Fist = 4,
	Axe = 2,
	Club = 1,
	Sword = 6,
	Magic = 0,
	Experience = 8
}
local healthBar, manaBar, topBar, states = nil
local experienceTooltip = "You have %d%% to advance to level %d."
local settings = {}

function init()
	connect(LocalPlayer, {
		onHealthChange = onHealthChange,
		onManaChange = onManaChange,
		onLevelChange = onLevelChange,
		onStatesChange = onStatesChange,
		onMagicLevelChange = onMagicLevelChange,
		onBaseMagicLevelChange = onBaseMagicLevelChange,
		onSkillChange = onSkillChange,
		onBaseSkillChange = onBaseSkillChange
	})
	connect(g_game, {
		onGameStart = refresh,
		onGameEnd = offline
	})

	for k, v in pairs(Icons) do
		g_textures.preload(v.path)
	end

	if g_game.isOnline() then
		refresh()
	end
end

function terminate()
	disconnect(LocalPlayer, {
		onHealthChange = onHealthChange,
		onManaChange = onManaChange,
		onLevelChange = onLevelChange,
		onStatesChange = onStatesChange,
		onMagicLevelChange = onMagicLevelChange,
		onBaseMagicLevelChange = onBaseMagicLevelChange,
		onSkillChange = onSkillChange,
		onBaseSkillChange = onBaseSkillChange
	})
	disconnect(g_game, {
		onGameStart = refresh,
		onGameEnd = offline
	})
end

function setupTopBar()
	local topPanel = modules.game_interface.getTopBar()
	topBar = topBar or g_ui.loadUI("topbar", topPanel)
	manaBar = topBar.stats.mana
	healthBar = topBar.stats.health
	states = topBar.stats.states.box

	function topBar.onMouseRelease(widget, mousePos, mouseButton)
		menu(mouseButton)
	end
end

function refresh(profileChange)
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	setupTopBar()
	load()
	setupSkills()
	show()
	refreshVisibleBars()
	onLevelChange(player, player:getLevel(), player:getLevelPercent())
	onHealthChange(player, player:getHealth(), player:getMaxHealth())
	onManaChange(player, player:getMana(), player:getMaxMana())
	onMagicLevelChange(player, player:getMagicLevel(), player:getMagicLevelPercent())

	if not profileChange then
		onStatesChange(player, player:getStates(), 0)
	end

	onHealthChange(player, player:getHealth(), player:getMaxHealth())
	onManaChange(player, player:getMana(), player:getMaxMana())
	onLevelChange(player, player:getLevel(), player:getLevelPercent())

	for i = Skill.Fist, Skill.ManaLeechAmount do
		onSkillChange(player, i, player:getSkillLevel(i), player:getSkillLevelPercent(i))
		onBaseSkillChange(player, i, player:getSkillBaseLevel(i))
	end

	topBar.skills.onGeometryChange = setSkillsLayout
end

function refreshVisibleBars()
	local ids = {
		"Experience",
		"Magic",
		"Axe",
		"Club",
		"Distance",
		"Fist",
		"Shielding",
		"Sword",
		"Fishing"
	}

	for i, id in ipairs(ids) do
		local panel = topBar[id] or topBar.skills[id]

		if panel then
			if id == "Experience" then
				if not settings[id] then
					panel:setVisible(true)
				end
			else
				panel:setVisible(settings[id] or false)
			end
		end
	end
end

function setSkillsLayout()
	local visible = 0
	local skills = topBar.skills
	local width = skills:getWidth()

	for i, child in ipairs(skills:getChildren()) do
		if child:isVisible() then
			visible = visible + 1
		end
	end

	local many = visible > 1

	if many then
		width = width / 2
	end

	skills:getLayout():setCellSize({
		height = 19,
		width = width
	})
end

function offline()
	local player = g_game.getLocalPlayer()

	if player then
		onStatesChange(player, 0, player:getStates())
	end

	save()
end

function toggleIcon(bitChanged)
	local content = states

	if not content then
		return
	end

	local icon = content:getChildById(Icons[bitChanged].id)

	if icon then
		icon:destroy()
	else
		icon = loadIcon(bitChanged)

		icon:setParent(content)
	end
end

function loadIcon(bitChanged)
	local icon = g_ui.createWidget("ConditionWidget", content)

	icon:setId(Icons[bitChanged].id)
	icon:setImageSource(Icons[bitChanged].path)
	icon:setTooltip(Icons[bitChanged].tooltip)

	return icon
end

function onHealthChange(localPlayer, health, maxHealth)
	if not healthBar then
		return
	end

	if maxHealth < health then
		maxHealth = health
	end

	local healthPercent = health / maxHealth * 100

	healthBar:setText(comma_value(health) .. " / " .. comma_value(maxHealth))
	healthBar:setValue(health, 0, maxHealth)
	healthBar:setPercent(healthPercent)

	if healthPercent > 92 then
		healthBar:setBackgroundColor("#00BC00FF")
	elseif healthPercent > 60 then
		healthBar:setBackgroundColor("#50A150FF")
	elseif healthPercent > 30 then
		healthBar:setBackgroundColor("#A1A100FF")
	elseif healthPercent > 8 then
		healthBar:setBackgroundColor("#BF0A0AFF")
	elseif healthPercent > 3 then
		healthBar:setBackgroundColor("#910F0FFF")
	else
		healthBar:setBackgroundColor("#850C0CFF")
	end
end

function onManaChange(localPlayer, mana, maxMana)
	if not manaBar then
		return
	end

	if maxMana < mana then
		maxMana = mana
	end

	local manaPercent = mana / maxMana * 100

	if manaPercent < 0 then
		return
	end

	manaBar:setText(comma_value(mana) .. " / " .. comma_value(maxMana))
	manaBar:setValue(mana, 0, maxMana)
	manaBar:setPercent(manaPercent)
end

function onLevelChange(localPlayer, value, percent)
	if not topBar then
		return
	end

	local experienceBar = topBar.Experience.progress
	local levelLabel = topBar.Experience.level

	experienceBar:setTooltip(tr(experienceTooltip, 100 - percent, value + 1))
	experienceBar:setPercent(percent)
	levelLabel:setText(value)
	levelLabel:setTextAutoResize(true)
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

function show()
	if not g_game.isOnline() then
		return
	end

	topBar:setVisible(g_settings.getBoolean("topBar", false))
end

function setupSkillPanel(id, parent, experience, defaultOff)
	local widget = g_ui.createWidget("SkillPanel", parent)

	widget:setId(id)
	widget.level:setTooltip(id)
	widget.icon:setTooltip(id)
	widget.icon:setImageClip({
		height = 9,
		width = 9,
		y = 0,
		x = iconsTable[id] * 9
	})

	if not experience then
		widget.progress:setBackgroundColor("#00c000")
		widget.shop:setVisible(false)
		widget.shop:disable()
		widget.shop:setWidth(0)
		widget.progress:setMarginRight(1)
	end

	settings[id] = settings[id] ~= nil and settings[id] or defaultOff

	if settings[id] == false then
		widget:setVisible(false)
	end

	function widget.onGeometryChange()
		local margin = widget.progress:getWidth() / 4
		local left = widget.left
		local right = widget.right

		left:setMarginRight(margin)
		right:setMarginRight(margin)
	end
end

function menu(mouseButton)
	if mouseButton ~= 2 then
		return
	end

	local menu = g_ui.createWidget("PopupMenu")

	menu:setId("topBarMenu")
	menu:setGameMenu(true)

	local expPanel = topBar.Experience
	local start = expPanel:isVisible() and "Hide" or "Show"

	menu:addOption(start .. " Experience Level", function ()
		toggleSkillPanel(id)
	end)

	for i, child in ipairs(topBar.skills:getChildren()) do
		local id = child:getId()

		if id ~= "stats" then
			local start = child:isVisible() and "Hide" or "Show"

			menu:addOption(start .. " " .. id .. " Level", function ()
				toggleSkillPanel(id)
			end)
		end
	end

	menu:display(mousePos)

	return true
end

function setupSkills()
	local t = {
		"Experience",
		"Magic",
		"Axe",
		"Club",
		"Distance",
		"Fist",
		"Shielding",
		"Sword",
		"Fishing"
	}

	for i, id in ipairs(t) do
		if not topBar[id] and not topBar.skills[id] then
			setupSkillPanel(id, i == 1 and topBar or topBar.skills, i == 1, i == 1)
		end
	end

	local child = topBar.Experience

	topBar:moveChildToIndex(child, 2)
end

function toggleSkillPanel(id)
	if not topBar then
		return
	end

	local panel = topBar.skills[id]
	panel = panel or topBar.Experience

	if not panel then
		return
	end

	panel:setVisible(not panel:isVisible())

	settings[id] = panel:isVisible()

	setSkillsLayout()
end

function setSkillValue(id, value)
	if not topBar then
		return
	end

	local panel = topBar.skills[id]

	if not panel then
		return
	end

	panel.level:setText(value)
	panel.level:setTextAutoResize(true)
end

function setSkillPercent(id, percent, tooltip)
	if not topBar then
		return
	end

	local panel = topBar.skills[id]

	if not panel then
		return
	end

	panel.progress:setPercent(math.floor(percent))
end

function setSkillBase(id, value, baseValue)
	if not topBar then
		return
	end

	local panel = topBar.skills[id]

	if not panel then
		return
	end

	local progress = topBar.skills[id].progress
	local progressDesc = "You have " .. 100 - math.floor(progress:getPercent()) .. " percent to go"
	local level = topBar.skills[id].level

	if baseValue <= 0 or value < 0 then
		return
	end

	if baseValue < value then
		level:setColor("#008b00")
		progress:setTooltip(value .. " = " .. baseValue .. " + " .. value - baseValue .. "\n" .. progressDesc)
	elseif value < baseValue then
		level:setColor("#b22222")
		progress:setTooltip(baseValue .. " " .. value - baseValue)
	else
		level:setColor("#bbbbbb")
		progress:removeTooltip()
	end
end

function onMagicLevelChange(localPlayer, magiclevel, percent)
	setSkillValue("Magic", magiclevel)
	setSkillPercent("Magic", percent)
	onBaseMagicLevelChange(localPlayer, localPlayer:getBaseMagicLevel())
end

function onBaseMagicLevelChange(localPlayer, baseMagicLevel)
	setSkillBase("Magic", localPlayer:getMagicLevel(), baseMagicLevel)
end

function onSkillChange(localPlayer, id, level, percent)
	id = id + 1
	local t = {
		"Fist",
		"Club",
		"Sword",
		"Axe",
		"Distance",
		"Shielding",
		"Fishing"
	}

	if id > #t then
		return
	end

	setSkillValue(t[id], level)
	setSkillPercent(t[id], percent)
	setSkillBase(t[id], level, localPlayer:getSkillBaseLevel(id - 1))
end

function onBaseSkillChange(localPlayer, id, baseLevel)
	id = id + 1
	local t = {
		"Fist",
		"Club",
		"Sword",
		"Axe",
		"Distance",
		"Shielding",
		"Fishing"
	}

	if id > #t then
		return
	end

	setSkillBase(id, localPlayer:getSkillLevel(id), baseLevel)
end

function save()
	local settingsFile = modules.client_profiles.getSettingsFilePath("topbar.json")
	local status, result = pcall(function ()
		return json.encode(settings, 2)
	end)

	if not status then
		return onError("Error while saving top bar settings. Data won't be saved. Details: " .. result)
	end

	if result:len() > 104857600 then
		return onError("Something went wrong, file is above 100MB, won't be saved")
	end

	local directory = settingsFile:match("^(.+)/[^/]+$") or "/settings/"
	if not g_resources.directoryExists(directory) then
		g_resources.makeDir(directory)
	end

	g_resources.writeFileContents(settingsFile, result)
end

function load()
	local settingsFile = modules.client_profiles.getSettingsFilePath("topbar.json")

	if g_resources.fileExists(settingsFile) then
		local status, result = pcall(function ()
			return json.decode(g_resources.readFileContents(settingsFile))
		end)

		if not status then
			return onError("Error while reading top bar settings file. To fix this problem you can delete storage.json. Details: " .. result)
		end

		settings = result
	else
		settings = {}
	end
end
