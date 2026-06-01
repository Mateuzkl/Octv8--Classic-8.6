Hotkeys = {}
HOTKEY_MANAGER_USE = nil
HOTKEY_MANAGER_USEONSELF = 1
HOTKEY_MANAGER_USEONTARGET = 2
HOTKEY_MANAGER_USEWITH = 3
HotkeyColors = {
	itemUseTarget = "#FF0000",
	itemUse = "#8888FF",
	itemUseWith = "#F5B325",
	textAutoSend = "#FFFFFF",
	extraAction = "#FFAA00",
	text = "#888888",
	itemUseSelf = "#00FF00"
}
hotkeysManagerLoaded = false
hotkeyPanel = nil
configSelector = nil
hotkeysButton = nil
currentHotkeyLabel = nil
currentItemPreview = nil
itemWidget = nil
addHotkeyButton = nil
removeHotkeyButton = nil
hotkeyText = nil
hotKeyTextLabel = nil
sendAutomatically = nil
actions = nil
selectObjectButton = nil
clearObjectButton = nil
useOnSelf = nil
useOnTarget = nil
useWith = nil
defaultComboKeys = nil
perCharacter = true
mouseGrabberWidget = nil
useRadioGroup = nil
currentHotkeys = nil
boundCombosCallback = {}
hotkeysList = {}
hotkeyConfigs = {}
currentConfig = 1
configValueChanged = false

function Hotkeys.init()
	g_keyboard.bindKeyDown("Ctrl+K", Hotkeys.show)

	optionsWindow = modules.client_options.optionsWindow
	hotkeyPanel = modules.client_options.hotkeyPanel
	configSelector = hotkeyPanel:getChildById("configSelector")
	currentHotkeys = hotkeyPanel:recursiveGetChildById("currentHotkeys")
	currentItemPreview = hotkeyPanel:recursiveGetChildById("itemPreview")
	addHotkeyButton = hotkeyPanel:recursiveGetChildById("addHotkeyButton")
	removeHotkeyButton = hotkeyPanel:recursiveGetChildById("removeHotkeyButton")
	hotkeyText = hotkeyPanel:recursiveGetChildById("hotkeyText")
	hotKeyTextLabel = hotkeyPanel:recursiveGetChildById("hotKeyTextLabel")
	sendAutomatically = hotkeyPanel:recursiveGetChildById("sendAutomatically")
	hotkeyAction = hotkeyPanel:recursiveGetChildById("action")
	selectObjectButton = hotkeyPanel:recursiveGetChildById("selectObjectButton")
	clearObjectButton = hotkeyPanel:recursiveGetChildById("clearObjectButton")
	useOnSelf = hotkeyPanel:recursiveGetChildById("useOnSelf")
	useOnTarget = hotkeyPanel:recursiveGetChildById("useOnTarget")
	useWith = hotkeyPanel:recursiveGetChildById("useWith")
	useRadioGroup = UIRadioGroup.create()

	useRadioGroup:addWidget(useOnSelf)
	useRadioGroup:addWidget(useOnTarget)
	useRadioGroup:addWidget(useWith)

	function useRadioGroup:onSelectionChange(selected)
		Hotkeys.onChangeUseType(selected)
	end

	mouseGrabberWidget = g_ui.createWidget("UIWidget")

	mouseGrabberWidget:setVisible(false)
	mouseGrabberWidget:setFocusable(false)

	mouseGrabberWidget.onMouseRelease = Hotkeys.onChooseItemMouseRelease

	function currentHotkeys:onChildFocusChange(hotkeyLabel)
		Hotkeys.onSelectHotkeyLabel(hotkeyLabel)
		currentHotkeys:ensureChildVisible(hotkeyLabel)
	end

	g_keyboard.bindKeyPress("Down", function ()
		currentHotkeys:focusNextChild(KeyboardFocusReason)
	end, hotkeyPanel)
	g_keyboard.bindKeyPress("Up", function ()
		currentHotkeys:focusPreviousChild(KeyboardFocusReason)
	end, hotkeyPanel)

	if hotkeyAction and setupExtraHotkeys then
		setupExtraHotkeys(hotkeyAction)
	end

	connect(g_game, {
		onGameStart = Hotkeys.online,
		onGameEnd = Hotkeys.offline
	})

	for i = 1, configSelector:getOptionsCount() do
		hotkeyConfigs[i] = g_configs.create("/hotkeys_" .. i .. ".otml")
	end

	addEvent(function ()
		Hotkeys.load()
	end)
end

function Hotkeys.terminate()
	disconnect(g_game, {
		onGameStart = online,
		onGameEnd = offline
	})
	g_keyboard.unbindKeyDown("Ctrl+K")
	Hotkeys.unload()
	hotkeyPanel:destroy()

	if hotkeysButton then
		hotkeysButton:destroy()
	end

	mouseGrabberWidget:destroy()
end

function Hotkeys.online()
	Hotkeys.reload()
	Hotkeys.hide()
end

function Hotkeys.offline()
	Hotkeys.unload()
	Hotkeys.hide()
end

function Hotkeys.show()
	if not g_game.isOnline() then
		return
	end

	if optionsWindow:isVisible() then
		return
	end

	optionsWindow:show()
	optionsWindow:raise()
	optionsWindow:focus()
	modules.client_options.optionsTabBar:selectTab(modules.client_options.hotkeyTab)
end

function Hotkeys.hide()
	optionsWindow:hide()
end

function Hotkeys.ok()
	Hotkeys.save()
	Hotkeys.hide()
end

function Hotkeys.cancel()
	Hotkeys.reload()
	Hotkeys.hide()
end

function Hotkeys.load(forceDefaults)
	hotkeysManagerLoaded = false
	currentConfig = 1
	local hotkeysNode = g_settings.getNode("hotkeys") or {}
	local index = g_game.getCharacterName() .. "_" .. g_game.getClientVersion()

	if hotkeysNode[index] ~= nil and hotkeysNode[index] > 0 and hotkeysNode[index] <= #hotkeyConfigs then
		currentConfig = hotkeysNode[index]
	end

	configSelector:setCurrentIndex(currentConfig, true)

	local hotkeySettings = hotkeyConfigs[currentConfig]:getNode("hotkeys")
	local hotkeys = {}

	if not table.empty(hotkeySettings) then
		hotkeys = hotkeySettings
	end

	hotkeyList = {}

	if not forceDefaults and not table.empty(hotkeys) then
		for keyCombo, setting in pairs(hotkeys) do
			keyCombo = tostring(keyCombo)

			Hotkeys.addKeyCombo(keyCombo, setting)

			hotkeyList[keyCombo] = setting
		end
	end

	if currentHotkeys:getChildCount() == 0 then
		Hotkeys.loadDefautComboKeys()
	end

	configValueChanged = false
	hotkeysManagerLoaded = true
end

function Hotkeys.unload()
	if modules.game_interface == nil then
		return
	end

	local gameRootPanel = modules.game_interface.getRootPanel()

	for keyCombo, callback in pairs(boundCombosCallback) do
		g_keyboard.unbindKeyPress(keyCombo, callback, gameRootPanel)
	end

	boundCombosCallback = {}

	currentHotkeys:destroyChildren()

	currentHotkeyLabel = nil

	Hotkeys.updateHotkeyForm(true)

	hotkeyList = {}
end

function Hotkeys.reset()
	Hotkeys.unload()
	Hotkeys.load(true)
end

function Hotkeys.reload()
	Hotkeys.unload()
	Hotkeys.load()
end

function Hotkeys.save()
	if not configValueChanged then
		return
	end

	local hotkeySettings = hotkeyConfigs[currentConfig]:getNode("hotkeys") or {}

	table.clear(hotkeySettings)

	for _, child in pairs(currentHotkeys:getChildren()) do
		hotkeySettings[child.keyCombo] = {
			autoSend = child.autoSend,
			itemId = child.itemId,
			subType = child.subType,
			useType = child.useType,
			value = child.value,
			action = child.action
		}
	end

	hotkeyList = hotkeySettings

	hotkeyConfigs[currentConfig]:setNode("hotkeys", hotkeySettings)
	hotkeyConfigs[currentConfig]:save()

	local index = g_game.getCharacterName() .. "_" .. g_game.getClientVersion()
	local hotkeysNode = g_settings.getNode("hotkeys") or {}
	hotkeysNode[index] = currentConfig

	g_settings.setNode("hotkeys", hotkeysNode)
	g_settings.save()
end

function Hotkeys.onConfigChange()
	if not configSelector then
		return
	end

	local index = g_game.getCharacterName() .. "_" .. g_game.getClientVersion()
	local hotkeysNode = g_settings.getNode("hotkeys") or {}
	hotkeysNode[index] = configSelector.currentIndex

	g_settings.setNode("hotkeys", hotkeysNode)
	Hotkeys.reload()
end

function Hotkeys.loadDefautComboKeys()
	if not defaultComboKeys then
		for i = 1, 12 do
			Hotkeys.addKeyCombo("F" .. i)
		end

		for i = 1, 4 do
			Hotkeys.addKeyCombo("Shift+F" .. i)
		end
	else
		for keyCombo, keySettings in pairs(defaultComboKeys) do
			Hotkeys.addKeyCombo(keyCombo, keySettings)
		end
	end
end

function Hotkeys.setDefaultComboKeys(combo)
	defaultComboKeys = combo
end

function Hotkeys:onChooseItemMouseRelease(mousePosition, mouseButton)
	local item = nil

	if mouseButton == MouseLeftButton then
		local clickedWidget = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePosition, false)

		if clickedWidget then
			if clickedWidget:getClassName() == "UIGameMap" then
				local tile = clickedWidget:getTile(mousePosition)

				if tile then
					local thing = tile:getTopMoveThing()

					if thing and thing:isItem() then
						item = thing
					end
				end
			elseif clickedWidget:getClassName() == "UIItem" and not clickedWidget:isVirtual() then
				item = clickedWidget:getItem()
			end
		end
	end

	if item and currentHotkeyLabel then
		currentHotkeyLabel.itemId = item:getId()

		if item:isFluidContainer() then
			currentHotkeyLabel.subType = item:getSubType()
		end

		if item:isMultiUse() then
			currentHotkeyLabel.useType = HOTKEY_MANAGER_USEWITH
		else
			currentHotkeyLabel.useType = HOTKEY_MANAGER_USE
		end

		currentHotkeyLabel.value = nil
		currentHotkeyLabel.autoSend = false

		Hotkeys.updateHotkeyLabel(currentHotkeyLabel)
		Hotkeys.updateHotkeyForm(true)
	end

	Hotkeys.show()
	g_mouse.popCursor("target")
	self:ungrabMouse()

	return true
end

function Hotkeys.startChooseItem()
	if g_ui.isMouseGrabbed() then
		return
	end

	mouseGrabberWidget:grabMouse()
	g_mouse.pushCursor("target")
	Hotkeys.hide()
end

function Hotkeys.clearObject()
	currentHotkeyLabel.action = nil
	currentHotkeyLabel.itemId = nil
	currentHotkeyLabel.subType = nil
	currentHotkeyLabel.useType = nil
	currentHotkeyLabel.autoSend = nil
	currentHotkeyLabel.value = nil

	Hotkeys.updateHotkeyLabel(currentHotkeyLabel)
	Hotkeys.updateHotkeyForm(true)
end

function Hotkeys.addHotkey()
	local assignWindow = g_ui.createWidget("HotkeyAssignWindow", rootWidget)

	assignWindow:grabKeyboard()

	local comboLabel = assignWindow:getChildById("comboPreview")
	comboLabel.keyCombo = ""
	assignWindow.onKeyDown = Hotkeys.hotkeyCapture
end

function Hotkeys.addKeyCombo(keyCombo, keySettings, focus)
	if keyCombo == nil or #keyCombo == 0 then
		return
	end

	if not keyCombo then
		return
	end

	local hotkeyLabel = currentHotkeys:getChildById(keyCombo)

	if not hotkeyLabel then
		hotkeyLabel = g_ui.createWidget("HotkeyListLabel")

		hotkeyLabel:setId(keyCombo)

		local children = currentHotkeys:getChildren()
		children[#children + 1] = hotkeyLabel

		table.sort(children, function (a, b)
			if a:getId():len() < b:getId():len() then
				return true
			elseif a:getId():len() == b:getId():len() then
				return a:getId() < b:getId()
			else
				return false
			end
		end)

		for i = 1, #children do
			if children[i] == hotkeyLabel then
				currentHotkeys:insertChild(i, hotkeyLabel)

				break
			end
		end

		if keySettings then
			currentHotkeyLabel = hotkeyLabel
			hotkeyLabel.keyCombo = keyCombo
			hotkeyLabel.autoSend = toboolean(keySettings.autoSend)
			hotkeyLabel.action = keySettings.action
			hotkeyLabel.itemId = tonumber(keySettings.itemId)
			hotkeyLabel.subType = tonumber(keySettings.subType)
			hotkeyLabel.useType = tonumber(keySettings.useType)

			if keySettings.value then
				hotkeyLabel.value = tostring(keySettings.value)
			end
		else
			hotkeyLabel.keyCombo = keyCombo
			hotkeyLabel.autoSend = false
			hotkeyLabel.itemId = nil
			hotkeyLabel.subType = nil
			hotkeyLabel.useType = nil
			hotkeyLabel.action = nil
			hotkeyLabel.value = ""
		end

		Hotkeys.updateHotkeyLabel(hotkeyLabel)

		local gameRootPanel = modules.game_interface.getRootPanel()

		if keyCombo:lower():find("ctrl") and boundCombosCallback[keyCombo] then
			g_keyboard.unbindKeyPress(keyCombo, boundCombosCallback[keyCombo], gameRootPanel)
		end

		boundCombosCallback[keyCombo] = function (k, c, ticks)
			Hotkeys.prepareKeyCombo(keyCombo, ticks)
		end

		g_keyboard.bindKeyPress(keyCombo, boundCombosCallback[keyCombo], gameRootPanel)

		if not keyCombo:lower():find("ctrl") then
			local keyComboCtrl = "Ctrl+" .. keyCombo

			if not boundCombosCallback[keyComboCtrl] then
				boundCombosCallback[keyComboCtrl] = function (k, c, ticks)
					Hotkeys.prepareKeyCombo(keyComboCtrl, ticks)
				end

				g_keyboard.bindKeyPress(keyComboCtrl, boundCombosCallback[keyComboCtrl], gameRootPanel)
			end
		end
	end

	if focus then
		currentHotkeys:focusChild(hotkeyLabel)
		currentHotkeys:ensureChildVisible(hotkeyLabel)
		Hotkeys.updateHotkeyForm(true)
	end

	configValueChanged = true
end

function Hotkeys.prepareKeyCombo(keyCombo, ticks)
	local hotKey = hotkeyList[keyCombo]

	if keyCombo:lower():find("ctrl") and not hotKey or hotKey and hotKey.itemId == nil and (not hotKey.value or #hotKey.value == 0) and not hotKey.action then
		keyCombo = keyCombo:gsub("Ctrl%+", "")
		keyCombo = keyCombo:gsub("ctrl%+", "")
		hotKey = hotkeyList[keyCombo]
	end

	if not hotKey then
		return
	end

	if hotKey.itemId == nil and hotKey.action == nil then
		scheduleEvent(function ()
			Hotkeys.doKeyCombo(keyCombo, ticks >= 5)
		end, g_settings.getNumber("hotkeyDelay"))
	else
		Hotkeys.doKeyCombo(keyCombo, ticks >= 5)
	end
end

function Hotkeys.doKeyCombo(keyCombo, repeated)
	if not g_game.isOnline() then
		return
	end

	if modules.game_console and modules.game_console.isChatEnabled() and keyCombo:len() == 1 then
		return
	end

	if modules.game_walking then
		modules.game_walking.checkTurn()
	end

	local hotKey = hotkeyList[keyCombo]

	if not hotKey then
		return
	end

	local hotkeyDelay = 100

	if hotKey.hotkeyDelayTo == nil or g_clock.millis() > hotKey.hotkeyDelayTo + hotkeyDelay then
		hotkeyDelay = 200
	end

	if hotKey.hotkeyDelayTo ~= nil and g_clock.millis() < hotKey.hotkeyDelayTo then
		return
	end

	if hotKey.action then
		executeExtraHotkey(hotKey.action, repeated)
	elseif hotKey.itemId == nil then
		if not hotKey.value or #hotKey.value == 0 then
			return
		end

		if hotKey.autoSend then
			modules.game_console.sendMessage(hotKey.value)
		else
			modules.game_console.setTextEditText(hotKey.value)
		end

		hotKey.hotkeyDelayTo = g_clock.millis() + hotkeyDelay
	elseif hotKey.useType == HOTKEY_MANAGER_USE then
		if g_game.getClientVersion() < 780 then
			local item = g_game.findPlayerItem(hotKey.itemId, hotKey.subType or -1)

			if item then
				g_game.use(item)
			end
		else
			g_game.useInventoryItem(hotKey.itemId)
		end

		hotKey.hotkeyDelayTo = g_clock.millis() + hotkeyDelay
	elseif hotKey.useType == HOTKEY_MANAGER_USEONSELF then
		if g_game.getClientVersion() < 780 then
			local item = g_game.findPlayerItem(hotKey.itemId, hotKey.subType or -1)

			if item then
				g_game.useWith(item, g_game.getLocalPlayer())
			end
		else
			g_game.useInventoryItemWith(hotKey.itemId, g_game.getLocalPlayer(), hotKey.subType or -1)
		end

		hotKey.hotkeyDelayTo = g_clock.millis() + hotkeyDelay
	elseif hotKey.useType == HOTKEY_MANAGER_USEONTARGET then
		local attackingCreature = g_game.getAttackingCreature()

		if not attackingCreature then
			local item = Item.create(hotKey.itemId)

			if g_game.getClientVersion() < 780 then
				local tmpItem = g_game.findPlayerItem(hotKey.itemId, hotKey.subType or -1)

				if not tmpItem then
					return
				end

				item = tmpItem
			end

			modules.game_interface.startUseWith(item, hotKey.subType or -1)

			return
		end

		if not attackingCreature:getTile() then
			return
		end

		if g_game.getClientVersion() < 780 then
			local item = g_game.findPlayerItem(hotKey.itemId, hotKey.subType or -1)

			if item then
				g_game.useWith(item, attackingCreature, hotKey.subType or -1)
			end
		else
			g_game.useInventoryItemWith(hotKey.itemId, attackingCreature, hotKey.subType or -1)
		end

		hotKey.hotkeyDelayTo = g_clock.millis() + hotkeyDelay
	elseif hotKey.useType == HOTKEY_MANAGER_USEWITH then
		local item = Item.create(hotKey.itemId)

		if g_game.getClientVersion() < 780 then
			local tmpItem = g_game.findPlayerItem(hotKey.itemId, hotKey.subType or -1)

			if not tmpItem then
				return true
			end

			item = tmpItem
		end

		modules.game_interface.startUseWith(item, hotKey.subType or -1)
	end
end

function Hotkeys.updateHotkeyLabel(hotkeyLabel)
	if not hotkeyLabel then
		return
	end

	if hotkeyLabel.action ~= nil then
		hotkeyLabel:setText(tr("%s: (%s)", hotkeyLabel.keyCombo, getActionDescription(hotkeyLabel.action)))
		hotkeyLabel:setColor(HotkeyColors.extraAction)
	elseif hotkeyLabel.useType == HOTKEY_MANAGER_USEONSELF then
		hotkeyLabel:setText(tr("%s: (use object on yourself)", hotkeyLabel.keyCombo))
		hotkeyLabel:setColor(HotkeyColors.itemUseSelf)
	elseif hotkeyLabel.useType == HOTKEY_MANAGER_USEONTARGET then
		hotkeyLabel:setText(tr("%s: (use object on target)", hotkeyLabel.keyCombo))
		hotkeyLabel:setColor(HotkeyColors.itemUseTarget)
	elseif hotkeyLabel.useType == HOTKEY_MANAGER_USEWITH then
		hotkeyLabel:setText(tr("%s: (use object with crosshair)", hotkeyLabel.keyCombo))
		hotkeyLabel:setColor(HotkeyColors.itemUseWith)
	elseif hotkeyLabel.itemId ~= nil then
		hotkeyLabel:setText(tr("%s: (use object)", hotkeyLabel.keyCombo))
		hotkeyLabel:setColor(HotkeyColors.itemUse)
	else
		local text = hotkeyLabel.keyCombo .. ": "

		if hotkeyLabel.value then
			text = text .. hotkeyLabel.value
		end

		hotkeyLabel:setText(text)

		if hotkeyLabel.autoSend then
			hotkeyLabel:setColor(HotkeyColors.autoSend)
		else
			hotkeyLabel:setColor(HotkeyColors.text)
		end
	end
end

function Hotkeys.updateHotkeyForm(reset)
	configValueChanged = true

	if hotkeyAction then
		if currentHotkeyLabel then
			hotkeyAction:enable()

			if currentHotkeyLabel.action then
				hotkeyAction:setCurrentIndex(translateActionToActionComboboxIndex(currentHotkeyLabel.action), true)
			else
				hotkeyAction:setCurrentIndex(1, true)
			end
		else
			hotkeyAction:disable()
			hotkeyAction:setCurrentIndex(1, true)
		end
	end

	local hasCustomAction = hotkeyAction and hotkeyAction.currentIndex > 1

	if currentHotkeyLabel and not hasCustomAction then
		removeHotkeyButton:enable()

		if currentHotkeyLabel.itemId ~= nil then
			hotkeyText:clearText()
			hotkeyText:disable()
			hotKeyTextLabel:disable()
			sendAutomatically:setChecked(false)
			sendAutomatically:disable()
			currentItemPreview:setItemId(currentHotkeyLabel.itemId)

			if currentHotkeyLabel.subType then
				currentItemPreview:setItemSubType(currentHotkeyLabel.subType)
			end

			if currentItemPreview:getItem():isMultiUse() then
				useOnSelf:enable()
				useOnTarget:enable()
				useWith:enable()

				if currentHotkeyLabel.useType == HOTKEY_MANAGER_USEONSELF then
					useRadioGroup:selectWidget(useOnSelf)
				elseif currentHotkeyLabel.useType == HOTKEY_MANAGER_USEONTARGET then
					useRadioGroup:selectWidget(useOnTarget)
				elseif currentHotkeyLabel.useType == HOTKEY_MANAGER_USEWITH then
					useRadioGroup:selectWidget(useWith)
				end
			else
				useOnSelf:disable()
				useOnTarget:disable()
				useWith:disable()
				useRadioGroup:clearSelected()
			end
		else
			useOnSelf:disable()
			useOnTarget:disable()
			useWith:disable()
			useRadioGroup:clearSelected()
			hotKeyTextLabel:enable()
			hotkeyText:setText(currentHotkeyLabel.value)
			addEvent(function (reset)
				if not hotkeyText then
					return
				end

				hotkeyText:enable()
				hotkeyText:focus()

				if reset then
					hotkeyText:setCursorPos(-1)
				else
					hotkeyText:setCursorPos(string.len(hotkeyText:getText()))
				end
			end, reset)
			sendAutomatically:setChecked(currentHotkeyLabel.autoSend)
			sendAutomatically:setEnabled(currentHotkeyLabel.value and #currentHotkeyLabel.value > 0)
			currentItemPreview:clearItem()
		end
	else
		removeHotkeyButton:disable()
		hotkeyText:disable()
		sendAutomatically:disable()
		useOnSelf:disable()
		useOnTarget:disable()
		useWith:disable()
		hotkeyText:clearText()
		useRadioGroup:clearSelected()
		sendAutomatically:setChecked(false)
		currentItemPreview:clearItem()
	end
end

function Hotkeys.removeHotkey()
	if currentHotkeyLabel == nil then
		return
	end

	if modules.game_interface == nil then
		return
	end

	local gameRootPanel = modules.game_interface.getRootPanel()
	configValueChanged = true

	g_keyboard.unbindKeyPress(currentHotkeyLabel.keyCombo, boundCombosCallback[currentHotkeyLabel.keyCombo], gameRootPanel)

	boundCombosCallback[currentHotkeyLabel.keyCombo] = nil

	currentHotkeyLabel:destroy()

	currentHotkeyLabel = nil
end

function Hotkeys.updateHotkeyAction()
	if not hotkeysManagerLoaded then
		return
	end

	if currentHotkeyLabel == nil then
		return
	end

	configValueChanged = true
	currentHotkeyLabel.action = translateActionComboboxIndexToAction(hotkeyAction.currentIndex)

	Hotkeys.updateHotkeyLabel(currentHotkeyLabel)
	Hotkeys.updateHotkeyForm()
end

function Hotkeys.onHotkeyTextChange(value)
	if not hotkeysManagerLoaded then
		return
	end

	if currentHotkeyLabel == nil then
		return
	end

	currentHotkeyLabel.value = value

	if value == "" then
		currentHotkeyLabel.autoSend = false
	end

	configValueChanged = true

	Hotkeys.updateHotkeyLabel(currentHotkeyLabel)
	Hotkeys.updateHotkeyForm()
end

function Hotkeys.onSendAutomaticallyChange(autoSend)
	if not hotkeysManagerLoaded then
		return
	end

	if currentHotkeyLabel == nil then
		return
	end

	if not currentHotkeyLabel.value or #currentHotkeyLabel.value == 0 then
		return
	end

	configValueChanged = true
	currentHotkeyLabel.autoSend = autoSend

	Hotkeys.updateHotkeyLabel(currentHotkeyLabel)
	Hotkeys.updateHotkeyForm()
end

function Hotkeys.onChangeUseType(useTypeWidget)
	if not hotkeysManagerLoaded then
		return
	end

	if currentHotkeyLabel == nil then
		return
	end

	configValueChanged = true

	if useTypeWidget == useOnSelf then
		currentHotkeyLabel.useType = HOTKEY_MANAGER_USEONSELF
	elseif useTypeWidget == useOnTarget then
		currentHotkeyLabel.useType = HOTKEY_MANAGER_USEONTARGET
	elseif useTypeWidget == useWith then
		currentHotkeyLabel.useType = HOTKEY_MANAGER_USEWITH
	else
		currentHotkeyLabel.useType = HOTKEY_MANAGER_USE
	end

	Hotkeys.updateHotkeyLabel(currentHotkeyLabel)
	Hotkeys.updateHotkeyForm()
end

function Hotkeys.onSelectHotkeyLabel(hotkeyLabel)
	currentHotkeyLabel = hotkeyLabel

	Hotkeys.updateHotkeyForm(true)
end

function Hotkeys.hotkeyCapture(assignWindow, keyCode, keyboardModifiers)
	local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers)
	local comboPreview = assignWindow:getChildById("comboPreview")

	comboPreview:setText(tr("Current hotkey to add: %s", keyCombo))

	comboPreview.keyCombo = keyCombo

	comboPreview:resizeToText()
	assignWindow:getChildById("addButton"):enable()

	return true
end

function Hotkeys.hotkeyCaptureOk(assignWindow, keyCombo)
	Hotkeys.addKeyCombo(keyCombo, nil, true)
	assignWindow:destroy()
end
