local ProgressCallback = {
	update = 1,
	finish = 2
}
cooldownWindow = nil
cooldownButton = nil
cooldownWindow = nil
cooldownPanel = nil
lastPlayer = nil
cooldown = {}
cooldowns = {}
groupCooldown = {}

function init()
	connect(g_game, {
		onGameStart = online,
		onSpellGroupCooldown = onSpellGroupCooldown,
		onSpellCooldown = onSpellCooldown
	})

	cooldownButton = modules.client_topmenu.addRightGameToggleButton("cooldownButton", tr("Cooldowns"), "/images/topbuttons/cooldowns", toggle, false, 5)

	cooldownButton:setOn(true)
	cooldownButton:hide()

	cooldownWindow = g_ui.loadUI("cooldown", modules.game_interface.getBottomPanel())
	cooldownPanel = cooldownWindow:getChildById("cooldownPanel")
	local console = modules.game_console.consolePanel

	if console then
		console:addAnchor(AnchorTop, cooldownWindow:getId(), AnchorBottom)
	end

	for k, v in pairs(SpelllistSettings) do
		g_textures.preload(v.iconFile)
	end

	if g_game.isOnline() then
		online()
	end
end

function terminate()
	disconnect(g_game, {
		onGameStart = online,
		onSpellGroupCooldown = onSpellGroupCooldown,
		onSpellCooldown = onSpellCooldown
	})

	for key, val in pairs(cooldowns) do
		removeCooldown(key)
	end

	cooldowns = {}
	local console = modules.game_console.consolePanel

	if console then
		console:removeAnchor(AnchorTop)
		console:fill("parent")
	end

	cooldownWindow:destroy()
	cooldownButton:destroy()
end

function loadIcon(iconId)
	local spell, profile, spellName = Spells.getSpellByIcon(iconId)

	if not spellName then
		return
	end

	if not profile then
		return
	end

	clientIconId = Spells.getClientId(spellName)

	if not clientIconId then
		return
	end

	local icon = cooldownPanel:getChildById(iconId)

	if not icon then
		icon = g_ui.createWidget("SpellIcon")

		icon:setId(iconId)
	end

	local spellSettings = SpelllistSettings[profile]

	if spellSettings then
		icon:setImageSource(spellSettings.iconFile)
		icon:setImageClip(Spells.getImageClip(clientIconId, profile))
	else
		icon = nil
	end

	return icon
end

function onMiniWindowClose()
	cooldownButton:setOn(false)
end

function toggle()
	if cooldownButton:isOn() then
		cooldownWindow:close()
		cooldownButton:setOn(false)
	else
		cooldownWindow:open()
		cooldownButton:setOn(true)
	end
end

function online()
	if not lastPlayer or lastPlayer ~= g_game.getCharacterName() then
		refresh()

		lastPlayer = g_game.getCharacterName()
	end
end

function refresh()
	cooldownPanel:destroyChildren()
end

function removeCooldown(progressRect)
	removeEvent(progressRect.event)

	if progressRect.icon then
		progressRect.icon:destroy()

		progressRect.icon = nil
	end

	cooldowns[progressRect] = nil
	progressRect = nil
end

function turnOffCooldown(progressRect)
	removeEvent(progressRect.event)

	if progressRect.icon then
		progressRect.icon:setOn(false)

		progressRect.icon = nil
	end

	cooldowns[progressRect] = nil
	progressRect = nil
end

function initCooldown(progressRect, updateCallback, finishCallback)
	progressRect:setPercent(0)

	progressRect.callback = {
		[ProgressCallback.update] = updateCallback,
		[ProgressCallback.finish] = finishCallback
	}

	updateCallback()
end

function updateCooldown(progressRect, duration)
	progressRect:setPercent(progressRect:getPercent() + 10000 / duration)

	if progressRect:getPercent() < 100 then
		removeEvent(progressRect.event)

		progressRect.event = scheduleEvent(function ()
			if not progressRect.callback then
				return
			end

			progressRect.callback[ProgressCallback.update]()
		end, 100)
	else
		progressRect.callback[ProgressCallback.finish]()
	end
end

function isGroupCooldownIconActive(groupId)
	return groupCooldown[groupId]
end

function isCooldownIconActive(iconId)
	return cooldown[iconId]
end

function onSpellCooldown(iconId, duration)
	local icon = loadIcon(iconId)

	if not icon then
		return
	end

	icon:setParent(cooldownPanel)

	local progressRect = icon:getChildById(iconId)

	if not progressRect then
		progressRect = g_ui.createWidget("SpellProgressRect", icon)

		progressRect:setId(iconId)

		progressRect.icon = icon

		progressRect:fill("parent")
	else
		progressRect:setPercent(0)
	end

	local spell, profile, spellName = Spells.getSpellByIcon(iconId)

	progressRect:setTooltip(spellName)

	local function updateFunc()
		updateCooldown(progressRect, duration)
	end

	local function finishFunc()
		removeCooldown(progressRect)

		cooldown[iconId] = false
	end

	initCooldown(progressRect, updateFunc, finishFunc)

	cooldown[iconId] = true
	cooldowns[progressRect] = true
end

function onSpellGroupCooldown(groupId, duration)
	if not SpellGroups[groupId] then
		return
	end

	local icon = cooldownWindow:getChildById("groupIcon" .. SpellGroups[groupId])
	local progressRect = cooldownWindow:getChildById("progressRect" .. SpellGroups[groupId])

	if icon then
		icon:setOn(true)
		removeEvent(icon.event)
	end

	progressRect.icon = icon

	if progressRect then
		removeEvent(progressRect.event)

		local function updateFunc()
			updateCooldown(progressRect, duration)
		end

		local function finishFunc()
			turnOffCooldown(progressRect)

			groupCooldown[groupId] = false
		end

		initCooldown(progressRect, updateFunc, finishFunc)

		groupCooldown[groupId] = true
	end
end
