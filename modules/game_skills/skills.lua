skillsWindow = nil
expLabel = nil

local wheelSkillWidgets = {
	"wheelOffenceHeader", "wheelLifeLeech", "wheelManaLeech", "wheelCriticalHeader", "wheelCriticalChance",
	"wheelCriticalDamage", "wheelDefenceHeader", "wheelPhysical", "wheelFire", "wheelEarth", "wheelEnergy",
	"wheelIce", "wheelHoly", "wheelDeath", "wheelDefence", "wheelArmor", "wheelMitigation"
}

local wheelAbsorbWidgets = {
	physical = "wheelPhysical",
	fire = "wheelFire",
	earth = "wheelEarth",
	energy = "wheelEnergy",
	ice = "wheelIce",
	holy = "wheelHoly",
	death = "wheelDeath"
}

local function setWheelSkillValue(id, value, percentage, color)
	local skill = skillsWindow:recursiveGetChildById(id)
	if not skill then
		return false
	end

	value = tonumber(value) or 0
	if math.abs(value) < 0.0001 then
		skill:hide()
		return false
	end

	local widget = skill:getChildById("value")
	if percentage then
		widget:setText(string.format("%+.2f%%", value * 100))
	else
		widget:setText(tostring(math.floor(value + 0.5)))
	end
	widget:setColor(color or "#00b800")
	skill:show()
	return true
end

local function onWheelSkillStats(protocol, opcode, data)
	if type(data) ~= "table" then
		return
	end

	local hasOffence = false
	hasOffence = setWheelSkillValue("wheelLifeLeech", data.lifeLeech, true) or hasOffence
	hasOffence = setWheelSkillValue("wheelManaLeech", data.manaLeech, true) or hasOffence
	local hasCritical = false
	hasCritical = setWheelSkillValue("wheelCriticalChance", data.criticalChance, true) or hasCritical
	hasCritical = setWheelSkillValue("wheelCriticalDamage", data.criticalDamage, true) or hasCritical
	skillsWindow:recursiveGetChildById("wheelCriticalHeader"):setVisible(hasCritical)
	hasOffence = hasCritical or hasOffence
	skillsWindow:recursiveGetChildById("wheelOffenceHeader"):setVisible(hasOffence)

	local hasDefence = false
	for absorb, id in pairs(wheelAbsorbWidgets) do
		hasDefence = setWheelSkillValue(id, data.absorbs and data.absorbs[absorb], true, "#44ad25") or hasDefence
	end
	hasDefence = setWheelSkillValue("wheelDefence", data.defense, false) or hasDefence
	hasDefence = setWheelSkillValue("wheelArmor", data.armor, false) or hasDefence
	hasDefence = setWheelSkillValue("wheelMitigation", data.mitigation, true) or hasDefence
	skillsWindow:recursiveGetChildById("wheelDefenceHeader"):setVisible(hasDefence)

	local baseHeight = g_game.getFeature(GameAdditionalSkills) and 464 or 355
	skillsWindow:setContentMaximumHeight((hasOffence or hasDefence) and 680 or baseHeight)
end

function init()
	connect(LocalPlayer, {
		onExperienceChange = onExperienceChange,
		onLevelChange = onLevelChange,
		onHealthChange = onHealthChange,
		onManaChange = onManaChange,
		onSoulChange = onSoulChange,
		onFreeCapacityChange = onFreeCapacityChange,
		onTotalCapacityChange = onTotalCapacityChange,
		onStaminaChange = onStaminaChange,
		onOfflineTrainingChange = onOfflineTrainingChange,
		onRegenerationChange = onRegenerationChange,
		onSpeedChange = onSpeedChange,
		onBaseSpeedChange = onBaseSpeedChange,
		onMagicLevelChange = onMagicLevelChange,
		onBaseMagicLevelChange = onBaseMagicLevelChange,
		onSkillChange = onSkillChange,
		onBaseSkillChange = onBaseSkillChange
	})
	connect(g_game, {
		onGameStart = refresh,
		onGameEnd = offline
	})
	g_keyboard.bindKeyDown("Ctrl+S", toggle)

	skillsWindow = g_ui.loadUI("skills", modules.game_interface.getRightPanel())
	ProtocolGame.registerExtendedJSONOpcode(ExtendedIds.WheelSkills, onWheelSkillStats)
	expLabel = skillsWindow:recursiveGetChildById("experience")
	local scrollbar = skillsWindow:getChildById("miniwindowScrollBar")

	scrollbar:mergeStyle({
		["$!on"] = {}
	})
	refresh()
	skillsWindow:setup()
end

function terminate()
	disconnect(LocalPlayer, {
		onExperienceChange = onExperienceChange,
		onLevelChange = onLevelChange,
		onHealthChange = onHealthChange,
		onManaChange = onManaChange,
		onSoulChange = onSoulChange,
		onFreeCapacityChange = onFreeCapacityChange,
		onTotalCapacityChange = onTotalCapacityChange,
		onStaminaChange = onStaminaChange,
		onOfflineTrainingChange = onOfflineTrainingChange,
		onRegenerationChange = onRegenerationChange,
		onSpeedChange = onSpeedChange,
		onBaseSpeedChange = onBaseSpeedChange,
		onMagicLevelChange = onMagicLevelChange,
		onBaseMagicLevelChange = onBaseMagicLevelChange,
		onSkillChange = onSkillChange,
		onBaseSkillChange = onBaseSkillChange
	})
	disconnect(g_game, {
		onGameStart = refresh,
		onGameEnd = offline
	})
	g_keyboard.unbindKeyDown("Ctrl+S")
	ProtocolGame.unregisterExtendedJSONOpcode(ExtendedIds.WheelSkills)
	skillsWindow:destroy()
end

function expForLevel(level)
	return math.floor(50 * level * level * level / 3 - 100 * level * level + 850 * level / 3 - 200)
end

function expToAdvance(currentLevel, currentExp)
	return expForLevel(currentLevel + 1) - currentExp
end

function resetSkillColor(id)
	local skill = skillsWindow:recursiveGetChildById(id)
	local widget = skill:getChildById("value")

	widget:setColor("#bbbbbb")
end

function toggleSkill(id, state)
	local skill = skillsWindow:recursiveGetChildById(id)

	skill:setVisible(state)
end

function setSkillBase(id, value, baseValue)
	if baseValue <= 0 or value < 0 then
		return
	end

	local skill = skillsWindow:recursiveGetChildById(id)
	local widget = skill:getChildById("value")

	if baseValue < value then
		widget:setColor("#008b00")
		skill:setTooltip(baseValue .. " +" .. value - baseValue)
	elseif value < baseValue then
		widget:setColor("#b22222")
		skill:setTooltip(baseValue .. " " .. value - baseValue)
	else
		widget:setColor("#bbbbbb")
		skill:removeTooltip()
	end
end

function setSkillValue(id, value)
	local skill = skillsWindow:recursiveGetChildById(id)
	local widget = skill:getChildById("value")

	widget:setText(value)
end

function setSkillColor(id, value)
	local skill = skillsWindow:recursiveGetChildById(id)
	local widget = skill:getChildById("value")

	widget:setColor(value)
end

function setSkillTooltip(id, value)
	local skill = skillsWindow:recursiveGetChildById(id)
	local widget = skill:getChildById("value")

	widget:setTooltip(value)
end

function setSkillPercent(id, percent, tooltip, color)
	local skill = skillsWindow:recursiveGetChildById(id)
	local widget = skill:getChildById("percent")

	if widget then
		widget:setPercent(math.floor(percent))

		if tooltip then
			widget:setTooltip(tooltip)
		end

		if color then
			widget:setBackgroundColor(color)
		end
	end
end

function checkAlert(id, value, maxValue, threshold, greaterThan)
	if greaterThan == nil then
		greaterThan = false
	end

	local alert = false

	if type(maxValue) == "boolean" then
		if maxValue then
			return
		end

		if greaterThan then
			if threshold < value then
				alert = true
			end
		elseif value < threshold then
			alert = true
		end
	elseif type(maxValue) == "number" then
		if maxValue < 0 then
			return
		end

		local percent = math.floor(value / maxValue * 100)

		if greaterThan then
			if threshold < percent then
				alert = true
			end
		elseif percent < threshold then
			alert = true
		end
	end

	if alert then
		setSkillColor(id, "#b22222")
	else
		resetSkillColor(id)
	end
end

function update()
	local offlineTraining = skillsWindow:recursiveGetChildById("offlineTraining")

	if not g_game.getFeature(GameOfflineTrainingTime) then
		offlineTraining:hide()
	else
		offlineTraining:show()
	end

	local regenerationTime = skillsWindow:recursiveGetChildById("regenerationTime")

	if not g_game.getFeature(GamePlayerRegenerationTime) then
		regenerationTime:hide()
	else
		regenerationTime:show()
	end
end

function refresh()
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	if expSpeedEvent then
		expSpeedEvent:cancel()
	end

	expSpeedEvent = cycleEvent(checkExpSpeed, 30000)

	onExperienceChange(player, player:getExperience())
	onLevelChange(player, player:getLevel(), player:getLevelPercent())
	onHealthChange(player, player:getHealth(), player:getMaxHealth())
	onManaChange(player, player:getMana(), player:getMaxMana())
	onSoulChange(player, player:getSoul())
	onFreeCapacityChange(player, player:getFreeCapacity())
	onStaminaChange(player, player:getStamina())
	onMagicLevelChange(player, player:getMagicLevel(), player:getMagicLevelPercent())
	onOfflineTrainingChange(player, player:getOfflineTrainingTime())
	onRegenerationChange(player, player:getRegenerationTime())
	onSpeedChange(player, player:getSpeed())

	local hasAdditionalSkills = g_game.getFeature(GameAdditionalSkills)

	for i = Skill.Fist, Skill.ManaLeechAmount do
		onSkillChange(player, i, player:getSkillLevel(i), player:getSkillLevelPercent(i))
		onBaseSkillChange(player, i, player:getSkillBaseLevel(i))

		if Skill.Fishing < i then
			toggleSkill("skillId" .. i, hasAdditionalSkills)
		end
	end

	local critHeader = skillsWindow:recursiveGetChildById("criticalHitHeader")
	if critHeader then
		critHeader:setVisible(hasAdditionalSkills)
	end

	local skillLeechChc1 = skillsWindow:recursiveGetChildById("skillId9")
	if skillLeechChc1 then skillLeechChc1:setVisible(false) end
	local skillLeechChc2 = skillsWindow:recursiveGetChildById("skillId11")
	if skillLeechChc2 then skillLeechChc2:setVisible(false) end

	update()

	local contentsPanel = skillsWindow:getChildById("contentsPanel")

	skillsWindow:setContentMinimumHeight(38)

	if hasAdditionalSkills then
		skillsWindow:setContentMaximumHeight(464)
	else
		skillsWindow:setContentMaximumHeight(355)
	end
end

function offline()
	if expSpeedEvent then
		expSpeedEvent:cancel()

		expSpeedEvent = nil
	end
	for _, id in ipairs(wheelSkillWidgets) do
		local widget = skillsWindow:recursiveGetChildById(id)
		if widget then widget:hide() end
	end
end

function toggle()
	if modules.game_sidebuttons.skillsButton:isOn() then
		skillsWindow:close()
		modules.game_sidebuttons.skillsButton:setOn(false)
	else
		skillsWindow:open()
		modules.game_sidebuttons.skillsButton:setOn(true)
	end
end

function checkExpSpeed()
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	local currentExp = player:getExperience()
	local currentTime = g_clock.seconds()

	if player.lastExps ~= nil then
		player.expSpeed = (currentExp - player.lastExps[1][1]) / (currentTime - player.lastExps[1][2])

		onLevelChange(player, player:getLevel(), player:getLevelPercent())
	else
		player.lastExps = {}
	end

	table.insert(player.lastExps, {
		currentExp,
		currentTime
	})

	if #player.lastExps > 30 then
		table.remove(player.lastExps, 1)
	end
end

function onMiniWindowClose()
	modules.game_sidebuttons.skillsButton:setOn(false)
end

function onSkillButtonClick(button)
	local percentBar = button:getChildById("percent")

	if percentBar then
		percentBar:setVisible(not percentBar:isVisible())

		if percentBar:isVisible() then
			button:setHeight(21)
		else
			button:setHeight(15)
		end
	end
end

function updateExpTooltip(localPlayer, playerLevel, playerExp)
	if playerLevel < 1 or playerExp < 0 then
		return
	end

	local expString = tr("%s exp. for next level", expToAdvance(playerLevel, playerExp))

	if localPlayer.expSpeed ~= nil then
		local expPerHour = math.floor(localPlayer.expSpeed * 3600)

		if expPerHour > 0 then
			local nextLevelExp = expForLevel(playerLevel + 1)
			local hoursLeft = (nextLevelExp - playerExp) / expPerHour
			local minutesLeft = math.floor((hoursLeft - math.floor(hoursLeft)) * 60)
			hoursLeft = math.floor(hoursLeft)
			expString = expString .. tr(", currently %s exp. per hour", comma_value(expPerHour))
			expString = expString .. tr(", next level in %d hours and %d minutes", hoursLeft, minutesLeft)
		end
	end

	expLabel:setTooltip(expString)
end

function formatExpNumber(value)
	if value >= 1000000000000 then -- 1 Trillion
		return string.format("%.3f T", value / 1000000000000)
	elseif value >= 1000000000 then -- 1 Billion
		return string.format("%.3f B", value / 1000000000)
	elseif value >= 1000000 then -- 1 Million
		local formatted = string.format("%.3f M", value / 1000000)
		-- Add commas to the thousands part before the decimal 
		-- e.g. 4485.123 -> 4,485.123
		local k = formatted:reverse()
		k = string.gsub(k, "^(M%s%d+%.%d%d%d)(%d+)", function(prefix, rest)
			local withCommas = rest:gsub("(%d%d%d)", "%1,")
			return prefix .. withCommas
		end)
		k = k:reverse()
		k = k:gsub("^,", "")
		return k
	elseif value >= 1000 then -- 1 Thousand
		return string.format("%.1f k", value / 1000)
	else
		return comma_value(value)
	end
end

function formatLargeExp(value)
	if value >= 1000000 then 
		-- Always format as M if it's over 1 Million, e.g. 4,485 M instead of 4 B
		local mill = math.floor(value / 1000000)
		return comma_value(mill) .. " M"
	elseif value >= 1000 then 
		local thou = math.floor(value / 1000)
		return comma_value(thou) .. " K"
	else
		return comma_value(value)
	end
end

function onExperienceChange(localPlayer, value)
	if value < 0 then
		return
	end

	setSkillValue("experience", formatLargeExp(value))
	addEvent(function ()
		local localPlayer = g_game.getLocalPlayer()

		if not localPlayer then
			return
		end

		updateExpTooltip(localPlayer, localPlayer:getLevel(), localPlayer:getExperience())
	end)
end

function onLevelChange(localPlayer, value, percent)
	setSkillValue("level", comma_value(value))
	setSkillPercent("level", percent, tr("You have %s percent to go", 100 - percent))
end

function onHealthChange(localPlayer, health, maxHealth)
	setSkillValue("health", health)
	checkAlert("health", health, maxHealth, 30)
end

function onManaChange(localPlayer, mana, maxMana)
	setSkillValue("mana", mana)
	checkAlert("mana", mana, maxMana, 30)
end

function onSoulChange(localPlayer, soul)
	setSkillValue("soul", soul)
end

function onFreeCapacityChange(localPlayer, freeCapacity)
	if not freeCapacity then
		return
	end

	local adjustedCapacity = freeCapacity

	if adjustedCapacity > 100000 then
		adjustedCapacity = 0
	end

	adjustedCapacity = math.floor(adjustedCapacity)

	if adjustedCapacity > 99999 then
		adjustedCapacity = math.min(9999, math.floor(adjustedCapacity / 1000)) .. "k"
	end

	setSkillValue("capacity", adjustedCapacity)
	checkAlert("capacity", freeCapacity, localPlayer:getTotalCapacity(), 20)
end

function onTotalCapacityChange(localPlayer, totalCapacity)
	checkAlert("capacity", localPlayer:getFreeCapacity(), totalCapacity, 20)
end

function onStaminaChange(localPlayer, stamina)
	local hours = math.floor(stamina / 60)
	local minutes = stamina % 60

	if minutes < 10 then
		minutes = "0" .. minutes
	end

	local percent = math.floor(100 * stamina / (42 * 60))

	setSkillValue("stamina", hours .. ":" .. minutes)

	if stamina > 2400 and g_game.getClientVersion() >= 1038 and localPlayer:isPremium() then
		local text = tr("You have %s hours and %s minutes left", hours, minutes) .. "\n" .. tr("Now you will gain 50%% more experience")

		setSkillPercent("stamina", percent, text, "green")
	elseif stamina > 2400 and g_game.getClientVersion() >= 1038 and not localPlayer:isPremium() then
		local text = tr("You have %s hours and %s minutes left", hours, minutes) .. "\n" .. tr("You will not gain 50%% more experience because you aren't premium player, now you receive only 1x experience points")

		setSkillPercent("stamina", percent, text, "#89F013")
	elseif stamina > 2400 and g_game.getClientVersion() < 1038 then
		local text = tr("You have %s hours and %s minutes left", hours, minutes) .. "\n" .. tr("If you are premium player, you will gain 50%% more experience")

		setSkillPercent("stamina", percent, text, "green")
	elseif stamina <= 2400 and stamina > 840 then
		setSkillPercent("stamina", percent, tr("You have %s hours and %s minutes left", hours, minutes), "orange")
	elseif stamina <= 840 and stamina > 0 then
		local text = tr("You have %s hours and %s minutes left", hours, minutes) .. "\n" .. tr("You gain only 50%% experience and you don't may gain loot from monsters")

		setSkillPercent("stamina", percent, text, "red")
	elseif stamina == 0 then
		local text = tr("You have %s hours and %s minutes left", hours, minutes) .. "\n" .. tr("You don't may receive experience and loot from monsters")

		setSkillPercent("stamina", percent, text, "black")
	end
end

function onOfflineTrainingChange(localPlayer, offlineTrainingTime)
	if not g_game.getFeature(GameOfflineTrainingTime) then
		return
	end

	local hours = math.floor(offlineTrainingTime / 60)
	local minutes = offlineTrainingTime % 60

	if minutes < 10 then
		minutes = "0" .. minutes
	end

	local percent = math.floor((offlineTrainingTime / 720) * 100)

	setSkillValue("offlineTraining", hours .. ":" .. minutes)
	setSkillPercent("offlineTraining", percent, tr("You have %d percent", percent))
end

function onRegenerationChange(localPlayer, regenerationTime)
	if not g_game.getFeature(GamePlayerRegenerationTime) or regenerationTime < 0 then
		return
	end

	local minutes = math.floor(regenerationTime / 60)
	local seconds = regenerationTime % 60

	if seconds < 10 then
		seconds = "0" .. seconds
	end

	setSkillValue("regenerationTime", minutes .. ":" .. seconds)
	checkAlert("regenerationTime", regenerationTime, false, 300)
end

function onSpeedChange(localPlayer, speed)
	setSkillValue("speed", speed)
	onBaseSpeedChange(localPlayer, localPlayer:getBaseSpeed())
end

function onBaseSpeedChange(localPlayer, baseSpeed)
	setSkillBase("speed", localPlayer:getSpeed(), baseSpeed)
end

function onMagicLevelChange(localPlayer, magiclevel, percent)
	setSkillValue("magiclevel", magiclevel)
	setSkillPercent("magiclevel", percent, tr("You have %s percent to go", 100 - percent))
	onBaseMagicLevelChange(localPlayer, localPlayer:getBaseMagicLevel())
end

function onBaseMagicLevelChange(localPlayer, baseMagicLevel)
	setSkillBase("magiclevel", localPlayer:getMagicLevel(), baseMagicLevel)
end

function formatSkillValue(id, value)
	if id >= Skill.CriticalChance and id <= Skill.ManaLeechAmount then
		return string.format("%.2f%%", value / 100)
	end
	return value
end

function onSkillChange(localPlayer, id, level, percent)
	local skill = skillsWindow:recursiveGetChildById("skillId" .. id)
	local widget = skill:getChildById("value")
	widget:setText(formatSkillValue(id, level))
	if id < Skill.CriticalChance then
		setSkillPercent("skillId" .. id, percent, tr("You have %s percent to go", 100 - percent))
	end
	onBaseSkillChange(localPlayer, id, localPlayer:getSkillBaseLevel(id))
end

function onBaseSkillChange(localPlayer, id, baseLevel)
	local currentLevel = localPlayer:getSkillLevel(id)
	if id >= Skill.CriticalChance and id <= Skill.ManaLeechAmount then
		local skill = skillsWindow:recursiveGetChildById("skillId" .. id)
		local widget = skill:getChildById("value")
		if currentLevel > 0 then
			widget:setColor("#008b00")
		else
			widget:setColor("#bbbbbb")
		end
	else
		setSkillBase("skillId" .. id, currentLevel, baseLevel)
	end
end
