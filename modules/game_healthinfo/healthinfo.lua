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
healthInfoWindow = nil
healthBar = nil
manaBar = nil
experienceBar = nil
soulLabel = nil
capLabel = nil
healthTooltip = "Your character health is %d out of %d."
manaTooltip = "Your character mana is %d out of %d."
experienceTooltip = "You have %d%% to advance to level %d."
overlay = nil
healthCircleFront = nil
manaCircleFront = nil
healthCircle = nil
manaCircle = nil
topHealthBar = nil
topManaBar = nil

function init()
	connect(LocalPlayer, {
		onHealthChange = onHealthChange,
		onManaChange = onManaChange,
		onLevelChange = onLevelChange,
		onStatesChange = onStatesChange,
		onSoulChange = onSoulChange,
		onFreeCapacityChange = onFreeCapacityChange
	})
	connect(g_game, {
		onGameEnd = offline
	})

	healthInfoWindow = g_ui.loadUI("healthinfo", modules.game_interface.getRightPanel())

	healthInfoWindow:disableResize()

	if not healthInfoWindow.forceOpen then
		healthInfoButton = modules.client_topmenu.addRightGameToggleButton("healthInfoButton", tr("Health Information"), "/images/topbuttons/healthinfo", toggle)

		if g_app.isMobile() then
			healthInfoButton:hide()
		else
			healthInfoButton:setOn(true)
		end
	end

	healthBar = healthInfoWindow:recursiveGetChildById("healthBar")
	manaBar = healthInfoWindow:recursiveGetChildById("manaBar")
	experienceBar = healthInfoWindow:recursiveGetChildById("experienceBar")
	soulLabel = healthInfoWindow:recursiveGetChildById("soulLabel")
	capLabel = healthInfoWindow:recursiveGetChildById("capLabel")
	overlay = g_ui.createWidget("HealthOverlay", modules.game_interface.getMapPanel())
	healthCircleFront = overlay:getChildById("healthCircleFront")
	manaCircleFront = overlay:getChildById("manaCircleFront")
	healthCircle = overlay:getChildById("healthCircle")
	manaCircle = overlay:getChildById("manaCircle")
	topHealthBar = overlay:getChildById("topHealthBar")
	topManaBar = overlay:getChildById("topManaBar")

	connect(overlay, {
		onGeometryChange = onOverlayGeometryChange
	})

	for k, v in pairs(Icons) do
		g_textures.preload(v.path)
	end

	if g_game.isOnline() then
		local localPlayer = g_game.getLocalPlayer()

		onHealthChange(localPlayer, localPlayer:getHealth(), localPlayer:getMaxHealth())
		onManaChange(localPlayer, localPlayer:getMana(), localPlayer:getMaxMana())
		onLevelChange(localPlayer, localPlayer:getLevel(), localPlayer:getLevelPercent())
		onStatesChange(localPlayer, localPlayer:getStates(), 0)
		onSoulChange(localPlayer, localPlayer:getSoul())
		onFreeCapacityChange(localPlayer, localPlayer:getFreeCapacity())
	end

	healthInfoWindow:setup()
	healthInfoWindow:open()
	hideLabels()
	hideExperience()
	healthInfoWindow:setHeight(32)

	if g_app.isMobile() then
		healthInfoWindow:close()
		healthInfoButton:setOn(false)
	end
end

function terminate()
	disconnect(LocalPlayer, {
		onHealthChange = onHealthChange,
		onManaChange = onManaChange,
		onLevelChange = onLevelChange,
		onStatesChange = onStatesChange,
		onSoulChange = onSoulChange,
		onFreeCapacityChange = onFreeCapacityChange
	})
	disconnect(g_game, {
		onGameEnd = offline
	})
	disconnect(overlay, {
		onGeometryChange = onOverlayGeometryChange
	})
	healthInfoWindow:destroy()

	if healthInfoButton then
		healthInfoButton:destroy()
	end

	overlay:destroy()
end

function toggle()
	if not healthInfoButton then
		return
	end

	if healthInfoButton:isOn() then
		healthInfoWindow:close()
		healthInfoButton:setOn(false)
	else
		healthInfoWindow:open()
		healthInfoButton:setOn(true)
	end
end

function toggleIcon(bitChanged)
	local content = healthInfoWindow:recursiveGetChildById("conditionPanel")
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

function offline()
	healthInfoWindow:recursiveGetChildById("conditionPanel"):destroyChildren()
end

function onMiniWindowClose()
	if healthInfoButton then
		healthInfoButton:setOn(false)
	end
end

local function shouldForceFullHpMpLabels()
	return g_settings.getBoolean("displayFullHpMpPercent")
end

local function getDisplayedResourceText(value, maxValue)
	if shouldForceFullHpMpLabels() then
		if maxValue and maxValue > 0 then
			local percent = math.floor((value * 100) / maxValue)
			percent = math.max(0, math.min(100, percent))
			return percent .. "%"
		end

		return "0%"
	end

	return tostring(value)
end

function onHealthChange(localPlayer, health, maxHealth)
	if maxHealth < health then
		maxHealth = health
	end

	healthInfoWindow:recursiveGetChildById("healthLabel"):setText(getDisplayedResourceText(health, maxHealth))
	healthBar:setTooltip(tr(healthTooltip, health, maxHealth))
	healthBar:setValue(health, 0, maxHealth)
	topHealthBar:setText(health .. " / " .. maxHealth)
	topHealthBar:setTooltip(tr(healthTooltip, health, maxHealth))
	topHealthBar:setValue(health, 0, maxHealth)

	local healthPercent = math.floor(g_game.getLocalPlayer():getHealthPercent())
	local Yhppc = math.floor(208 * (1 - healthPercent / 100))
	local rect = {
		x = 0,
		width = 63,
		y = Yhppc,
		height = 208 - Yhppc + 1
	}

	healthCircleFront:setImageClip(rect)
	healthCircleFront:setImageRect(rect)

	if healthPercent > 92 then
		healthCircleFront:setImageColor("#00BC00FF")
	elseif healthPercent > 60 then
		healthCircleFront:setImageColor("#50A150FF")
	elseif healthPercent > 30 then
		healthCircleFront:setImageColor("#A1A100FF")
	elseif healthPercent > 8 then
		healthCircleFront:setImageColor("#BF0A0AFF")
	elseif healthPercent > 3 then
		healthCircleFront:setImageColor("#910F0FFF")
	else
		healthCircleFront:setImageColor("#850C0CFF")
	end
end

function onManaChange(localPlayer, mana, maxMana)
	if maxMana < mana then
		maxMana = mana
	end

	healthInfoWindow:recursiveGetChildById("manaLabel"):setText(getDisplayedResourceText(mana, maxMana))
	manaBar:setTooltip(tr(manaTooltip, mana, maxMana))
	manaBar:setValue(mana, 0, maxMana)
	topManaBar:setText(mana .. " / " .. maxMana)
	topManaBar:setTooltip(tr(manaTooltip, mana, maxMana))
	topManaBar:setValue(mana, 0, maxMana)

	local Ymppc = math.floor(208 * (1 - math.floor((maxMana - (maxMana - mana)) * 100 / maxMana) / 100))
	local rect = {
		x = 0,
		width = 63,
		y = Ymppc,
		height = 208 - Ymppc + 1
	}

	manaCircleFront:setImageClip(rect)
	manaCircleFront:setImageRect(rect)
end

function refreshHealthManaDisplay()
	if not g_game.isOnline() then
		return
	end

	local localPlayer = g_game.getLocalPlayer()

	if not localPlayer then
		return
	end

	onHealthChange(localPlayer, localPlayer:getHealth(), localPlayer:getMaxHealth())
	onManaChange(localPlayer, localPlayer:getMana(), localPlayer:getMaxMana())
end

function onLevelChange(localPlayer, value, percent)
	experienceBar:setText(percent .. "%")
	experienceBar:setTooltip(tr(experienceTooltip, percent, value + 1))
	experienceBar:setPercent(percent)
end

function onSoulChange(localPlayer, soul)
	soulLabel:setText(tr("Soul") .. ": " .. soul)
end

function onFreeCapacityChange(player, freeCapacity)
	capLabel:setText(tr("Cap") .. ": " .. freeCapacity)
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

function hideLabels()
	local content = healthInfoWindow:recursiveGetChildById("conditionPanel")
	local removeHeight = math.max(capLabel:getMarginRect().height, soulLabel:getMarginRect().height) + content:getMarginRect().height - 3

	capLabel:setOn(false)
	soulLabel:setOn(false)
	content:setVisible(false)
	healthInfoWindow:setHeight(math.max(healthInfoWindow.minimizedHeight, healthInfoWindow:getHeight() - removeHeight))
end

function hideExperience()
	local removeHeight = experienceBar:getMarginRect().height

	experienceBar:setOn(false)
	healthInfoWindow:setHeight(math.max(healthInfoWindow.minimizedHeight, healthInfoWindow:getHeight() - removeHeight))
end

function setHealthTooltip(tooltip)
	healthTooltip = tooltip
	local localPlayer = g_game.getLocalPlayer()

	if localPlayer then
		healthBar:setTooltip(tr(healthTooltip, localPlayer:getHealth(), localPlayer:getMaxHealth()))
	end
end

function setManaTooltip(tooltip)
	manaTooltip = tooltip
	local localPlayer = g_game.getLocalPlayer()

	if localPlayer then
		manaBar:setTooltip(tr(manaTooltip, localPlayer:getMana(), localPlayer:getMaxMana()))
	end
end

function setExperienceTooltip(tooltip)
	experienceTooltip = tooltip
	local localPlayer = g_game.getLocalPlayer()

	if localPlayer then
		experienceBar:setTooltip(tr(experienceTooltip, localPlayer:getLevelPercent(), localPlayer:getLevel() + 1))
	end
end

function onOverlayGeometryChange()
	if g_app.isMobile() then
		topHealthBar:setMarginTop(35)
		topManaBar:setMarginTop(35)

		local width = overlay:getWidth()
		local margin = width / 3 + 10

		topHealthBar:setMarginLeft(margin)
		topManaBar:setMarginRight(margin)

		return
	end

	local classic = g_settings.getBoolean("classicView")
	local minMargin = 40

	if classic then
		topHealthBar:setMarginTop(15)
		topManaBar:setMarginTop(15)
	else
		topHealthBar:setMarginTop(45 - overlay:getParent():getMarginTop())
		topManaBar:setMarginTop(45 - overlay:getParent():getMarginTop())

		minMargin = 200
	end

	local height = overlay:getHeight()
	local width = overlay:getWidth()

	topHealthBar:setMarginLeft(math.max(minMargin, (width - height + 50) / 2 + 2))
	topManaBar:setMarginRight(math.max(minMargin, (width - height + 50) / 2 + 2))
end
