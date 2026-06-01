local actionBars = {}
local extraHotkeys = {}
local settings = {}
local settingsFile = ""
local cachedSettings, window, mouseGrabberWidget = nil
local TYPE = {
	SPECIALACTION = 4,
	ITEM = 3,
	SPELL = 2,
	TEXT = 1,
	BLANK = 0
}
local ACTION = {
	EQUIP = 1,
	USE_SELF = 3,
	USE_CROSS = 5,
	USE_TARGET = 4,
	BLANK = 0,
	USE = 2
}

local function translateVocation(id)
	if id == 1 or id == 11 then
		return 8
	elseif id == 2 or id == 12 then
		return 7
	elseif id == 3 or id == 13 then
		return 5
	elseif id == 4 or id == 14 then
		return 6
	end
end

local function isSpell(text)
	text = text:lower():trim()

	for spellName, spellData in pairs(SpellInfo.Default) do
		local words = spellData.words
		local param = spellData.parameter
		local data = spellData
		data.spellName = spellName

		if not param then
			if words == text then
				return {
					data = data
				}
			end
		elseif text:find(words) then
			text = text:gsub(words, ""):trim()
			text = text:gsub("\"", "")
			text = text:gsub("'", "")

			return {
				data = data,
				param = text
			}
		end
	end

	return false
end

function init()
	connect(g_game, {
		onGameStart = online,
		onGameEnd = offline,
		onSpellGroupCooldown = onSpellGroupCooldown,
		onSpellCooldown = onSpellCooldown
	})

	if g_game.isOnline() then
		online()
	end

	mouseGrabberWidget = g_ui.createWidget("UIWidget")

	mouseGrabberWidget:setVisible(false)
	mouseGrabberWidget:setFocusable(false)

	mouseGrabberWidget.onMouseRelease = onDropActionButton
end

function terminate()
	disconnect(g_game, {
		onGameStart = online,
		onGameEnd = offline,
		onSpellGroupCooldown = onSpellGroupCooldown,
		onSpellCooldown = onSpellCooldown
	})
	mouseGrabberWidget:destroy()
end

function createActionBars()
	if false then
		return
	end

	local bottomPanel = modules.game_interface.getBottomActionPanel()
	local leftPanel = modules.game_interface.getLeftActionPanel()
	local rightPanel = modules.game_interface.getRightActionPanel()

	for i = 1, 9 do
		local parent, index, layout = nil

		if i <= 3 then
			parent = bottomPanel
			index = i
			layout = "actionbar"
		elseif i <= 6 then
			parent = leftPanel
			index = i - 3
			layout = "sideactionbar"
		else
			parent = rightPanel
			index = i - 6
			layout = "sideactionbar"
		end

		actionBars[i] = g_ui.loadUI(layout, parent)

		actionBars[i]:setId("actionbar." .. i)

		actionBars[i].n = i

		parent:moveChildToIndex(actionBars[i], index)
	end
end

function offline()
	save()
	destroyAssignWindows()

	for index, actionbar in ipairs(actionBars) do
		if actionbar.tabBar then
			for i, actionButton in ipairs(actionbar.tabBar:getChildren()) do
				local callback = actionButton.callback
				local hotkey = actionButton.hotkey and actionButton.hotkey:len() > 0 and actionButton.hotkey or false

				if callback and hotkey then
					local gameRootPanel = modules.game_interface.getRootPanel()

					g_keyboard.unbindKeyPress(hotkey, callback, gameRootPanel)
				end
			end
		end
	end

	for i, panel in ipairs(actionBars) do
		panel:destroy()
	end

	extraHotkeys = {}
end

function online()
	settingsFile = modules.client_profiles.getSettingsFilePath("actionbar_v2.json")

	load()
	createActionBars()
	show()
	destroyAssignWindows()
	setupExtraHotkeys()
end

function show()
	for i = 1, #actionBars do
		local actionbar = actionBars[i]
		local enabled = g_settings.getBoolean("actionbar" .. i, false)

		actionbar:setOn(enabled)
		setupActionBar(i)
	end
end

function refresh()
	save()

	settingsFile = modules.client_profiles.getSettingsFilePath("actionbar_v2.json")

	load()
	show()
	destroyAssignWindows()

	extraHotkeys = {}

	setupExtraHotkeys()
end

function translateHotkeyDesc(text)
	if not text then
		return ""
	end

	local values = {
		{
			"Shift",
			"S"
		},
		{
			"Ctrl",
			"C"
		},
		{
			"+",
			""
		},
		{
			"PageUp",
			"PgUp"
		},
		{
			"PageDown",
			"PgDown"
		},
		{
			"Enter",
			"Return"
		},
		{
			"Insert",
			"Ins"
		},
		{
			"Delete",
			"Del"
		},
		{
			"Escape",
			"Esc"
		}
	}

	for i, v in pairs(values) do
		text = text:gsub(v[1], v[2])
	end

	if text:len() > 6 then
		text = text:sub(text:len() - 3, text:len())
		text = "..." .. text
	end

	return text
end

function destroyAssignWindows()
	local windows = {
		"assignItemWindow",
		"assignSpellWindow",
		"assignTextWindow",
		"assignHotkeyWindow",
		"assignActionWindow"
	}
	local rootWidget = g_ui.getRootWidget()

	for i, id in ipairs(windows) do
		local widget = rootWidget[id]

		if widget then
			widget:destroy()
		end
	end
end

function changeLockState(widget)
	local actionbar = widget:getParent():getParent()

	widget:setOn(not widget:isOn())
	widget.image:setOn(widget:isOn())

	actionbar.locked = not widget:isOn()
	settings[actionbar:getId()] = not widget:isOn() or nil
end

function moveActionButtons(widget)
	local dir = widget:getId()
	local actionBar = widget:getParent():getParent()
	local scroll = actionBar.actionScroll
	local buttons = {
		actionBar.prevPanel.prev,
		actionBar.prevPanel.first,
		actionBar.nextPanel.next,
		actionBar.nextPanel.last
	}

	if dir == "next" then
		scroll:increment(37)
	elseif dir == "last" then
		scroll:setValue(scroll:getMaximum())
	elseif dir == "prev" then
		scroll:decrement(37)
	else
		scroll:setValue(scroll:getMinimum())
	end

	local prevEnabled = scroll:getValue() > 0
	local nextEnabled = scroll:getValue() < scroll:getMaximum()

	buttons[1]:setOn(prevEnabled)
	buttons[2]:setOn(prevEnabled)
	buttons[3]:setOn(nextEnabled)
	buttons[4]:setOn(nextEnabled)
	buttons[1].image:setOn(prevEnabled)
	buttons[2].image:setOn(prevEnabled)
	buttons[3].image:setOn(nextEnabled)
	buttons[4].image:setOn(nextEnabled)
end

function onDropActionButton(self, mousePosition, mouseButton)
	if not g_ui.isMouseGrabbed() then
		return
	end

	local clickedWidget = modules.game_interface.getRootPanel():recursiveGetChildByPos(mousePosition, false)

	if clickedWidget and clickedWidget:getParent() and clickedWidget:getParent():getStyleName():find("ActionButton") and cachedSettings then
		clickedWidget = clickedWidget:getParent()

		if clickedWidget ~= cachedSettings.widget then
			local clickedHotkey = clickedWidget.hotkey
			local cachedHotkey = cachedSettings.widget.hotkey
			settings[cachedSettings.id] = settings[clickedWidget:getId()]
			settings[clickedWidget:getId()] = cachedSettings.data
			local clickedTill = clickedWidget.cooldownTill or 0
			local clickedStart = clickedWidget.cooldownStart or 0
			local cachedTill = cachedSettings.widget.cooldownTill or 0
			local cachedStart = cachedSettings.widget.cooldownStart or 0
			cachedSettings.widget.cooldownTill = clickedTill
			cachedSettings.widget.cooldownStart = clickedStart
			clickedWidget.cooldownTill = cachedTill
			clickedWidget.cooldownStart = cachedStart
			settings[cachedSettings.id] = settings[cachedSettings.id] or {}
			settings[cachedSettings.id].hotkey = cachedHotkey
			settings[clickedWidget:getId()] = settings[clickedWidget:getId()] or {}
			settings[clickedWidget:getId()].hotkey = clickedHotkey

			updateCooldown(clickedWidget)
			updateCooldown(cachedSettings.widget)
			setupButton(cachedSettings.widget)
			setupButton(clickedWidget)
		end
	end

	cachedSettings.widget.item:setBorderColor("#00000000")

	cachedSettings = nil

	g_mouse.popCursor("target")
	self:ungrabMouse()
end

function setupActionBar(n)
	local actionbar = actionBars[n]
	local visible = actionbar:isVisible()
	locked = settings[actionbar:getId()]
	actionbar.tabBar.onMouseWheel = nil
	actionbar.locked = locked

	actionbar.nextPanel.lock:setOn(not locked)
	actionbar.nextPanel.lock.image:setOn(not locked)

	if not visible then
		return actionbar.tabBar:destroyChildren()
	else
		actionbar.tabBar:destroyChildren()

		for i = 1, 50 do
			local layout = n < 4 and "ActionButton" or "SideActionButton"
			local widget = g_ui.createWidget(layout, actionbar.tabBar)

			widget:setId(actionbar.n .. "." .. i)
			setupButton(widget)
		end
	end
end

function setupButton(widget)
	local id = widget:getId()
	local config = settings[id]
	local actionbar = widget:getParent():getParent()

	widget.item:setShowCount(false)

	widget.item.onItemChange = nil
	widget.type = TYPE.BLANK

	widget.text:setText("")
	widget.parameterText:setText("")

	if widget.item:getItemId() ~= 0 then
		widget.item:setItemId(0)
	end

	ItemsDatabase.setTier(widget.item, nil)
	widget.item:setOn(false)

	widget.autoSay = nil
	widget.action = ACTION.BLANK
	widget.spellData = nil
	widget.specialAction = nil
	widget.specialActionDesc = nil

	widget.item:setItemVisible(true)
	widget.text:setImageSource("")

	widget.hotkey = config and config.hotkey or ""
	widget.callback = nil

	if config and config.type then
		widget.item:setOn(true)

		widget.type = config.type

		widget.text:setText(config.sayText or "")

		if config.itemId and config.itemId > 100 then
			local item = Item.create(config.itemId, 50)
			if config.tier and item.setTier then
				item:setTier(config.tier)
			end
			widget.item:setItem(item)
			ItemsDatabase.setTier(widget.item, item)
		end

		widget.sayText = config.sayText
		widget.autoSay = config.autoSay
		widget.action = config.action
		widget.specialAction = config.specialAction
		widget.specialActionDesc = config.specialActionDesc
		widget.spellData = config.spellData

		if config.type ~= 0 and config.type ~= 3 then
			widget.item:setItemVisible(false)
		end
	end

	setupAction(widget)
	widget.hotkeyLabel:setText(translateHotkeyDesc(widget.hotkey))

	if widget.specialAction then
		widget.text:setText(widget.specialActionDesc)
	end

	if widget.spellData then
		widget.text:setImageSource(widget.spellData.source)
		widget.text:setImageClip(widget.spellData.clip)

		local param = widget.spellData.param

		if param and param:len() > 6 then
			param = param:sub(1, 5) .. "..."
		end

		widget.parameterText:setText(param or "")
	else
		widget.text:setImageSource("")
	end

	function widget.item:onDragEnter()
		if g_ui.isMouseGrabbed() or actionbar.locked then
			return
		end

		mouseGrabberWidget:grabMouse()
		g_mouse.pushCursor("target")
		self:setBorderColor("#FFFFFF")

		cachedSettings = {
			id = widget:getId(),
			data = settings[widget:getId()],
			widget = widget
		}
	end

	function widget.onMouseRelease(widget, mousePos, mouseButton)
		if false then
			return
		end

		if mouseButton == MouseRightButton then
			local menu = g_ui.createWidget("PopupMenu")

			menu:setGameMenu(true)
			menu:addOption(widget.spellId and tr("Edit Spell") or tr("Assign Spell"), function ()
				assignSpell(widget)
			end)
			menu:addOption(widget.item:getItemId() > 100 and tr("Edit Object") or tr("Assign Object"), function ()
				assignItem(widget)
			end)
			menu:addOption(widget.text:getText():len() > 0 and tr("Edit Text") or tr("Assign Text"), function ()
				assignText(widget)
			end)
			menu:addOption(widget.hotkey and tr("Edit Hotkey") or tr("Assign Hotkey"), function ()
				assignHotkey(widget)
			end)
			menu:addOption(widget.specialAction and tr("Edit Action") or tr("Assign Action"), function ()
				assignAction(widget)
			end)

			if widget.type > 0 then
				menu:addSeparator()
				menu:addOption(tr("Clear Action"), function ()
					resetSlot(widget)
				end)
			end

			menu:display(mousePos)
		elseif mouseButton == MouseLeftButton and widget.callback then
			widget.callback()
		end
	end

	function widget.item.onItemChange(widget)
		widget:setOn(true)
		assignItem(widget:getParent())
	end

	local itemAction = nil

	if widget.type == TYPE.ITEM then
		if widget.action == ACTION.EQUIP then
			itemAction = "Equip/Unequip this object"
		elseif widget.action == ACTION.USE then
			itemAction = "Use this object"
		elseif widget.action == ACTION.USE_SELF then
			itemAction = "Use this object on Yourself"
		elseif widget.action == ACTION.USE_TARGET then
			itemAction = "Use this object on Attack Target"
		elseif widget.action == ACTION.USE_CROSS then
			itemAction = "Use this object with Crosshair"
		end
	end

	local actionDesc = nil
	local spellData = widget.spellData

	if widget.type == TYPE.BLANK then
		actionDesc = "None"
	elseif widget.type == TYPE.TEXT then
		actionDesc = "Say: \"" .. widget.text:getText() .. "\"\n"
		actionDesc = actionDesc .. "Auto sent:  " .. (widget.autoSay and "Yes" or "No")
	elseif widget.type == TYPE.SPELL then
		local paramText = nil

		if spellData.param and spellData.param:len() > 0 then
			paramText = " \"" .. spellData.param .. "\""
		else
			paramText = ""
		end

		actionDesc = "Cast " .. spellData.name .. "\n"
		actionDesc = actionDesc .. "Formula:  " .. spellData.words .. paramText .. "\n"
		actionDesc = actionDesc .. "Cooldown:  " .. spellData.cd .. "s\n"
		actionDesc = actionDesc .. "Mana:  " .. spellData.mana
	elseif widget.type == TYPE.ITEM then
		actionDesc = itemAction
	elseif widget.type == TYPE.SPECIALACTION then
		actionDesc = widget.specialActionDesc
	end

	local hotkeyDesc = widget.hotkey and widget.hotkey:len() > 0 and widget.hotkey or "None"
	local tooltip = "Action Button " .. id
	tooltip = tooltip .. "\n\n\tAction:  " .. (actionDesc or "None")
	tooltip = tooltip .. "\nHotkeys:  " .. hotkeyDesc

	widget.item:setTooltip(tooltip)
end

function resetSlot(widget)
	local hotkey = settings[widget:getId()] and settings[widget:getId()].hotkey or nil

	if hotkey and hotkey:len() > 0 and widget.callback then
		local gameRootPanel = modules.game_interface.getRootPanel()

		g_keyboard.unbindKeyPress(widget.hotkey, widget.callback, gameRootPanel)
	end

	if hotkey then
		settings[widget:getId()] = {
			hotkey = hotkey
		}
	else
		settings[widget:getId()] = nil
	end

	setupButton(widget)
end

function assignItem(widget)
	destroyAssignWindows()

	local radio = UIRadioGroup.create()
	local item = widget.item:getItem()
	local id = widget.item:getItemId()

	if id == 0 and widget.item:isOn() then
		return resetSlot(widget)
	end

	window = g_ui.loadUI("object", g_ui.getRootWidget())

	window:show()
	window:raise()
	window:focus()
	window:setText("Assign Object to Action Button " .. widget:getId())
	window:setId("assignItemWindow")

	function window.select.onClick()
		modules.game_itemselector.show(widget.item)
	end

	window.item:setShowCount(false)

	function window.item.onItemChange(widget)
		local item = window.item:getItem()

		if item then
			for i, child in ipairs(window.checks:getChildren()) do
				radio:addWidget(child)

				if item:getId() < 100 then
					child:setEnabled(false)
				elseif i < 4 then
					local check = item:isMultiUse()

					child:setEnabled(check)

					if check then
						radio:selectWidget(child)
					end
				elseif g_game.getClientVersion() >= 860 then
					if i == 4 then
						local check = true

						child:setEnabled(check)

						if check then
							radio:selectWidget(child)
						end
					else
						child:setEnabled(true)
						radio:selectWidget(child)
					end
				else
					child:setVisible(false)
				end
			end
		end

		window.buttonOk:setEnabled(item and item:getId() > 100)
		window.buttonApply:setEnabled(item and item:getId() > 100)
	end

	window.item:setItemId(id)

	local actionType = widget.action or 0

	if ACTION.BLANK < actionType then
		local id = nil

		if actionType == ACTION.USE_SELF then
			id = "useSelf"
		elseif actionType == ACTION.USE_TARGET then
			id = "useTarget"
		elseif actionType == ACTION.USE_CROSS then
			id = "useCross"
		elseif actionType == ACTION.EQUIP then
			id = "equip"
		elseif actionType == ACTION.USE then
			id = "use"
		end

		for i, child in ipairs(radio.widgets) do
			local childId = child:getId()

			if childId == id then
				radio:selectWidget(child)

				break
			end
		end
	end

	local function okFunc(destroy)
		local hotkey = settings[widget:getId()] and settings[widget:getId()].hotkey

		if hotkey and hotkey:len() > 0 and widget.callback then
			local gameRootPanel = modules.game_interface.getRootPanel()

			g_keyboard.unbindKeyPress(widget.hotkey, widget.callback, gameRootPanel)
		end

		settings[widget:getId()] = {
			hotkey = hotkey
		}
		settings[widget:getId()].itemId = window.item:getItemId()
		settings[widget:getId()].type = TYPE.ITEM
		local assignedItem = window.item:getItem()
		if assignedItem and assignedItem.getTier then
			settings[widget:getId()].tier = assignedItem:getTier()
		end
		local selected = radio:getSelectedWidget():getId()

		if selected == "useSelf" then
			settings[widget:getId()].action = ACTION.USE_SELF
		elseif selected == "useTarget" then
			settings[widget:getId()].action = ACTION.USE_TARGET
		elseif selected == "useCross" then
			settings[widget:getId()].action = ACTION.USE_CROSS
		elseif selected == "equip" then
			settings[widget:getId()].action = ACTION.EQUIP
		else
			settings[widget:getId()].action = ACTION.USE
		end

		if destroy then
			window:destroy()
			radio:destroy()
		end

		setupButton(widget)
		focusRoot()
	end

	local function cancelFunc()
		setupButton(widget)
		window:destroy()
		radio:destroy()
		focusRoot()
	end

	function window.buttonOk.onClick()
		okFunc(true)
	end

	function window.onEnter()
		okFunc(true)
	end

	function window.buttonApply.onClick()
		okFunc(false)
	end

	window.buttonClose.onClick = cancelFunc
	window.onEscape = cancelFunc
	local actionbar = widget:getParent():getParent()

	if actionbar.locked then
		cancelFunc()
	end
end

function assignText(widget)
	destroyAssignWindows()

	window = g_ui.loadUI("text", g_ui.getRootWidget())

	window:show()
	window:raise()
	window:focus()

	function window.text:onTextChange(text)
		window.buttonOk:setEnabled(text:len() > 0)
		window.buttonApply:setEnabled(text:len() > 0)
	end

	window.text:setText(widget.text:getText())

	if widget.type > 0 then
		window.checkPanel.tick:setChecked(widget.autoSay)
	end

	local function okFunc(destroy)
		local autoSay = window.checkPanel.tick:isChecked()
		local text = window.text:getText()
		local hotkey = settings[widget:getId()] and settings[widget:getId()].hotkey

		if hotkey and hotkey:len() > 0 and widget.callback then
			local gameRootPanel = modules.game_interface.getRootPanel()

			g_keyboard.unbindKeyPress(hotkey, widget.callback, gameRootPanel)
		end

		settings[widget:getId()] = {
			hotkey = hotkey
		}
		local spell = isSpell(text)

		if spell then
			local paramText = spell.param
			local spellData = spell.data
			local newGroup = {}

			for groupId, duration in pairs(spellData.group) do
				table.insert(newGroup, groupId)
			end

			spellData.group = newGroup
			settings[widget:getId()].type = TYPE.SPELL
			settings[widget:getId()].spellData = {
				words = spellData.words,
				cd = spellData.exhaustion / 1000,
				mana = spellData.mana,
				source = SpelllistSettings.Default.iconFile,
				clip = Spells.getImageClip(SpellIcons[spellData.icon][1], "Default"),
				name = spellData.spellName,
				param = paramText,
				group = spellData.group,
				id = spellData.id
			}
		else
			settings[widget:getId()].sayText = text
			settings[widget:getId()].type = TYPE.TEXT
			settings[widget:getId()].autoSay = autoSay
		end

		if destroy then
			window:destroy()
		end

		setupButton(widget)
	end

	local function cancelFunc()
		window:destroy()
		setupButton(widget)
	end

	function window.buttonOk.onClick()
		okFunc(true)
	end

	function window.buttonApply.onClick()
		okFunc(false)
	end

	window.buttonClose.onClick = cancelFunc
	window.onEscape = cancelFunc

	function window.onEnter()
		okFunc(true)
	end

	local actionbar = widget:getParent():getParent()

	if actionbar.locked then
		cancelFunc()
	end
end

function assignSpell(widget)
	destroyAssignWindows()

	local radio = UIRadioGroup.create()
	window = g_ui.loadUI("spell", g_ui.getRootWidget())

	window:show()
	window:raise()
	window:focus()
	window:setText("Assign Spell to Action Button " .. widget:getId())

	local searchText = window:recursiveGetChildById("searchText")
	local spells = modules.gamelib.SpellInfo.Default

	for spellName, spellData in pairs(spells) do
		local widget = g_ui.createWidget("SpellPreview", window.spellList)

		radio:addWidget(widget)

		local newGroup = {}

		for groupId, duration in pairs(spellData.group) do
			table.insert(newGroup, groupId)
		end

		spellData.group = newGroup

		widget:setId(spellData.id)
		widget:setText(spellName .. "\n" .. spellData.words)

		widget.voc = spellData.vocations
		widget.param = spellData.parameter
		widget.source = SpelllistSettings.Default.iconFile
		widget.clip = Spells.getImageClip(SpellIcons[spellData.icon][1], "Default")

		widget.image:setImageSource(widget.source)
		widget.image:setImageClip(widget.clip)

		widget.spellData = {
			words = spellData.words,
			cd = spellData.exhaustion / 1000,
			mana = spellData.mana,
			source = widget.source,
			clip = widget.clip,
			name = spellName,
			param = spellData.parameter,
			group = spellData.group,
			id = spellData.id
		}
	end

	local widgets = window.spellList:getChildren()

	table.sort(widgets, function (a, b)
		return a.spellData.name < b.spellData.name
	end)

	for i, widget in ipairs(widgets) do
		window.spellList:moveChildToIndex(widget, i)
	end

	function searchText.onTextChange()
		local s = window.spellList:getChildren()
		local checked = window.checkPanel.tick:isChecked()
		local searchFilter = searchText:getText():lower()

		if checked then
			for _, value in ipairs(s) do
				local vocation = translateVocation(g_game.getLocalPlayer():getVocation())
				local viable = table.find(value.voc, vocation) and true or false
				local searchCondition = searchFilter == "" or searchFilter ~= "" and string.find(value.spellData.name:lower(), searchFilter) ~= nil or string.find(value.spellData.words:lower(), searchFilter)

				value:setVisible(searchCondition and viable)
			end
		else
			for _, value in ipairs(s) do
				local searchCondition = searchFilter == "" or searchFilter ~= "" and string.find(value.spellData.name:lower(), searchFilter) ~= nil or string.find(value.spellData.words:lower(), searchFilter)

				value:setVisible(searchCondition)
			end
		end
	end

	local function filterByVocation(a, filter)
		window.spellList.onChildFocusChange = nil
		local widgets = window.spellList:getChildren()
		local vocation = translateVocation(g_game.getLocalPlayer():getVocation())
		local fistVisible = nil

		for i, widget in ipairs(widgets) do
			local viable = not filter or table.find(widget.voc, vocation) and true or false

			widget:setVisible(viable)

			if viable and not fistVisible then
				fistVisible = widget

				radio:selectWidget(fistVisible)
			end
		end

		local currentSpell = widget.spellData and widget.spellData.id or 0

		if currentSpell > 0 then
			for i, child in ipairs(radio.widgets) do
				local childId = child.spellData.id

				if childId == currentSpell then
					child:setVisible(true)
					window.spellList:ensureChildVisible(child)
					radio:selectWidget(child)

					break
				end
			end
		end
	end

	function radio.onSelectionChange(nothing, selected)
		if selected then
			local name = selected:getText()
			local source = selected.source
			local clip = selected.clip
			local param = selected.param

			window.preview:setText(name)
			window.preview.image:setImageSource(source)
			window.preview.image:setImageClip(clip)
			window.paramLabel:setOn(param)
			window.paramText:setEnabled(param)
			window.spellList:ensureChildVisible(selected)
		end
	end

	window.checkPanel.tick.onCheckChange = filterByVocation

	filterByVocation(nil, true)

	local function okFunc(destroy)
		local selected = radio:getSelectedWidget()
		local paramWidgetText = window.paramText:getText()

		if not selected then
			return
		end

		selected.spellData.param = paramWidgetText
		local hotkey = settings[widget:getId()] and settings[widget:getId()].hotkey

		if hotkey and hotkey:len() > 0 and widget.callback then
			local gameRootPanel = modules.game_interface.getRootPanel()

			g_keyboard.unbindKeyPress(widget.hotkey, widget.callback, gameRootPanel)
		end

		settings[widget:getId()] = {
			hotkey = hotkey
		}
		settings[widget:getId()].spellData = selected.spellData
		settings[widget:getId()].type = TYPE.SPELL

		if destroy then
			window:destroy()
		end

		setupButton(widget)
	end

	local function cancelFunc()
		window:destroy()
		setupButton(widget)
	end

	function window.buttonOk.onClick()
		okFunc(true)
	end

	function window.buttonApply.onClick()
		okFunc(false)
	end

	window.buttonClose.onClick = cancelFunc
	window.onEscape = cancelFunc

	function window.onEnter()
		okFunc(true)
	end

	local actionbar = widget:getParent():getParent()

	if actionbar.locked then
		cancelFunc()
	end
end

function assignHotkey(widget)
	destroyAssignWindows()

	window = g_ui.loadUI("hotkey", g_ui.getRootWidget())

	window:show()
	window:raise()
	window:focus()

	local barN = widget:getParent():getParent().n
	local barDesc = nil

	if barN < 4 then
		barDesc = "Bottom"
	elseif barN < 7 then
		barDesc = "Left"
	else
		barDesc = "Right"
	end

	barDesc = barDesc .. " Action Bar: Action Button " .. widget:getId()

	window:setText("Edit Hotkey for \"" .. barDesc)
	window.desc:setText(window.desc:getText() .. barDesc .. "\"")
	window.display:setText(widget.hotkey or "")
	window:grabKeyboard()

	function window.onKeyDown(window, keyCode, keyboardModifiers)
		local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers)

		window.display:setText(keyCombo)

		return true
	end

	local function okFunc()
		local hotkey = window.display:getText()

		if settings[widget:getId()] and settings[widget:getId()].hotkey and settings[widget:getId()].hotkey:len() > 0 and widget.callback then
			local gameRootPanel = modules.game_interface.getRootPanel()

			g_keyboard.unbindKeyPress(widget.hotkey, widget.callback, gameRootPanel)
		end

		settings[widget:getId()] = settings[widget:getId()] or {}
		settings[widget:getId()].hotkey = hotkey

		window:destroy()
		setupButton(widget)
	end

	local function clearFunc()
		window.display:setText("")

		local hotkey = window.display:getText()

		if settings[widget:getId()].hotkey and settings[widget:getId()].hotkey:len() > 0 and widget.callback then
			local gameRootPanel = modules.game_interface.getRootPanel()

			g_keyboard.unbindKeyPress(widget.hotkey, widget.callback, gameRootPanel)
		end

		settings[widget:getId()] = settings[widget:getId()] or {}
		settings[widget:getId()].hotkey = hotkey

		window:destroy()
		setupButton(widget)
	end

	local function closeFunc()
		window:destroy()
		setupButton(widget)
	end

	window.buttonOk.onClick = okFunc
	window.buttonClear.onClick = clearFunc
	window.buttonClose.onClick = closeFunc
	local actionbar = widget:getParent():getParent()

	if actionbar.locked then
		cancelFunc()
	end
end

function assignAction(widget)
	destroyAssignWindows()

	window = g_ui.loadUI("actionwindow", g_ui.getRootWidget())

	window:show()
	window:raise()
	window:focus()
	setupComboBox(window.action)

	function window.action.onOptionChange(x, selected)
		widget.specialAction = translateActionComboboxIndexToAction(x.currentIndex)
		widget.specialActionDesc = getActionDescription(widget.specialAction)
		widget.type = TYPE.SPECIALACTION
	end

	local function okFunc()
		settings[widget:getId()] = settings[widget:getId()] or {}
		settings[widget:getId()].specialAction = widget.specialAction
		settings[widget:getId()].type = widget.type
		settings[widget:getId()].specialActionDesc = widget.specialActionDesc

		window:destroy()
		setupButton(widget)
	end

	local function closeFunc()
		window:destroy()
		setupButton(widget)
	end

	window.buttonOk.onClick = okFunc
	window.buttonClose.onClick = closeFunc

	local function cancelFunc()
		setupButton(widget)
		window:destroy()
	end

	local actionbar = widget:getParent():getParent()

	if actionbar.locked then
		cancelFunc()
	end
end

function setupAction(widget)
	if widget.type == TYPE.BLANK then
		return
	end

	if widget.type == TYPE.SPECIALACTION then
		function widget.callback()
			executeExtraHotkey(widget.specialAction, false)
		end
	elseif widget.type == TYPE.TEXT then
		function widget.callback()
			if modules.game_interface.isChatVisible() then
				if widget.autoSay then
					modules.game_console.sendMessage(widget.sayText)
				else
					modules.game_console.setTextEditText(widget.sayText)
				end
			elseif widget.autoSay then
				g_game.talk(widget.sayText)
			end
		end
	elseif widget.type == TYPE.SPELL then
		function widget.callback()
			if g_app.isMobile() then
				local target = g_game.getAttackingCreature()

				if target then
					local pos = g_game.getLocalPlayer():getPosition()
					local tpos = target:getPosition()

					if pos and tpos then
						local offx = tpos.x - pos.x
						local offy = tpos.y - pos.y

						if offy < 0 and offx <= 0 and math.abs(offx) < math.abs(offy) then
							g_game.turn(Directions.North)
						elseif offy > 0 and offx >= 0 and math.abs(offx) < math.abs(offy) then
							g_game.turn(Directions.South)
						elseif offx < 0 and offy <= 0 and math.abs(offy) < math.abs(offx) then
							g_game.turn(Directions.West)
						elseif offx > 0 and offy >= 0 and math.abs(offy) < math.abs(offx) then
							g_game.turn(Directions.East)
						end
					end
				end
			end

			local paramText = nil

			if widget.spellData and widget.spellData.param and widget.spellData.param:len() > 0 then
				paramText = " \"" .. widget.spellData.param .. "\""
			else
				paramText = ""
			end

			g_game.talk(widget.spellData.words .. paramText)
		end
	elseif widget.type == TYPE.ITEM then
		function widget.callback()
			if widget.action == ACTION.BLANK then
				return
			elseif widget.action == ACTION.EQUIP then
				if g_game.getClientVersion() >= 860 then
					local item = Item.create(widget.item:getItemId())
					local actionItem = widget.item:getItem()
					if actionItem and actionItem.getTier and item.setTier then
						item:setTier(actionItem:getTier())
					end

					return g_game.equipItem(item)
				end
			elseif widget.action == ACTION.USE then
				if g_game.getClientVersion() < 780 then
					local item = g_game.findPlayerItem(widget.item:getItemId(), widget.item:getItemSubType() or -1)

					if item then
						g_game.use(item)
					end
				else
					g_game.useInventoryItem(widget.item:getItemId())
				end
			elseif widget.action == ACTION.USE_SELF then
				if g_game.getClientVersion() < 780 then
					local item = g_game.findPlayerItem(widget.item:getItemId(), widget.item:getItemSubType() or -1)

					if item then
						g_game.useWith(item, g_game.getLocalPlayer())
					end
				else
					g_game.useInventoryItemWith(widget.item:getItemId(), g_game.getLocalPlayer(), widget.item:getItemSubType() or -1)
				end
			elseif widget.action == ACTION.USE_TARGET then
				local attackingCreature = g_game.getAttackingCreature()

				if not attackingCreature then
					local item = Item.create(widget.item:getItemId())

					if g_game.getClientVersion() < 780 then
						local tmpItem = g_game.findPlayerItem(widget.item:getItemId(), widget.item:getItemSubType() or -1)

						if not tmpItem then
							return
						end

						item = tmpItem
					end

					modules.game_interface.startUseWith(item, widget.item:getItemSubType() or -1)

					return
				end

				if not attackingCreature:getTile() then
					return
				end

				if g_game.getClientVersion() < 780 then
					local item = g_game.findPlayerItem(widget.item:getItemId(), widget.item:getItemSubType() or -1)

					if item then
						g_game.useWith(item, attackingCreature, widget.item:getItemSubType() or -1)
					end
				else
					g_game.useInventoryItemWith(widget.item:getItemId(), attackingCreature, widget.item:getItemSubType() or -1)
				end
			elseif widget.action == ACTION.USE_CROSS then
				local item = Item.create(widget.item:getItemId())

				if g_game.getClientVersion() < 780 then
					local tmpItem = g_game.findPlayerItem(widget.item:getItemId(), widget.item:getItemSubType() or -1)

					if not tmpItem then
						return true
					end

					item = tmpItem
				end

				modules.game_interface.startUseWith(item, widget.item:getItemSubType() or -1)
			end
		end
	end

	if widget.hotkey and widget.hotkey:len() > 0 and widget.callback then
		local gameRootPanel = modules.game_interface.getRootPanel()

		g_keyboard.unbindKeyPress(widget.hotkey, gameRootPanel)
		g_keyboard.bindKeyPress(widget.hotkey, widget.callback, gameRootPanel)
	end
end

function onSpellCooldown(iconId, duration)
	for index, actionbar in ipairs(actionBars) do
		for i, child in ipairs(actionbar.tabBar:getChildren()) do
			if child.type == 2 and child.spellData.id == iconId then
				startCooldown(child, duration)
			end
		end
	end
end

function onSpellGroupCooldown(groupId, duration)
	for index, actionbar in ipairs(actionBars) do
		for i, child in ipairs(actionbar.tabBar:getChildren()) do
			if child.type == 2 and child.spellData.group then
				for i, group in ipairs(child.spellData.group) do
					if groupId == group then
						startCooldown(child, duration)
					end
				end
			end
		end
	end
end

function startCooldown(action, duration)
	if type(action.cooldownTill) == "number" and action.cooldownTill > g_clock.millis() + duration then
		return
	end

	action.cooldownStart = g_clock.millis()
	action.cooldownTill = g_clock.millis() + duration

	updateCooldown(action)
end

function updateCooldown(action)
	if not action or not action.cooldownTill then
		return
	end

	local timeleft = action.cooldownTill - g_clock.millis()

	if timeleft <= 50 then
		action.cooldown:setPercent(100)

		action.cooldownEvent = nil

		action.cooldown:setText("")

		return
	end

	local duration = action.cooldownTill - action.cooldownStart
	local formattedText = nil

	if timeleft > 60000 then
		formattedText = math.floor(timeleft / 60000) .. "m"
	else
		formattedText = timeleft / 1000
		formattedText = math.floor(formattedText * 10) / 10
		formattedText = math.floor(formattedText) .. "." .. math.floor(formattedText * 10) % 10
	end

	local retry = nil

	if timeleft > 60000 then
		retry = math.min(math.floor(timeleft * 0.1), 60000)
		retry = math.max(retry, 100)
	elseif timeleft > 1000 then
		retry = 100
	else
		retry = 30
	end

	action.cooldown:setText(formattedText)
	action.cooldown:setPercent(100 - math.floor(100 * timeleft / duration))

	action.cooldownEvent = scheduleEvent(function ()
		updateCooldown(action)
	end, retry)
end

function save()
	if not settingsFile or settingsFile == "" then
		return
	end

	local status, result = pcall(function ()
		return json.encode(settings, 2)
	end)

	if not status then
		return g_logger.error("Error while saving top bar settings. Data won't be saved. Details: " .. result)
	end

	if result:len() > 104857600 then
		return g_logger.error("Something went wrong, file is above 100MB, won't be saved")
	end

	local directory = settingsFile:match("^(.+)/[^/]+$") or "/settings/"
	if not g_resources.directoryExists(directory) then
		g_resources.makeDir(directory)
	end

	g_resources.writeFileContents(settingsFile, result)
end

function load()
	if g_resources.fileExists(settingsFile) then
		local status, result = pcall(function ()
			return json.decode(g_resources.readFileContents(settingsFile))
		end)

		if not status then
			return g_logger.error("Error while reading top bar settings file. To fix this problem you can delete storage.json. Details: " .. result)
		end

		settings = result
	else
		settings = {}
	end
end

function addExtraHotkey(name, description, callback)
	table.insert(extraHotkeys, {
		name = name:lower(),
		description = tr(description),
		callback = callback
	})
end

function setupExtraHotkeys()
	addExtraHotkey("none", "none", nil)
	addExtraHotkey("cancelAttack", "stop attacking", function (repeated)
		if not repeated then
			g_game.attack(nil)
		end
	end)
	addExtraHotkey("attackNext", "attack next target in battle", function (repeated)
		if repeated or not modules.game_battle then
			return
		end

		local battlePanel = modules.game_battle.battlePanel
		local attackedCreature = g_game.getAttackingCreature()
		local nextChild = nil
		local breakNext = false

		for i, child in ipairs(battlePanel:getChildren()) do
			if not child.creature or not child:isOn() then
				break
			end

			nextChild = child

			if breakNext then
				break
			end

			if child.creature == attackedCreature then
				breakNext = true
				nextChild = battlePanel:getFirstChild()
			end
		end

		if not breakNext then
			nextChild = battlePanel:getFirstChild()
		end

		if nextChild and nextChild.creature ~= attackedCreature then
			g_game.attack(nextChild.creature)
		end
	end)
	addExtraHotkey("attackPrevious", "attack previous target in battle", function (repeated)
		if repeated or not modules.game_battle then
			return
		end

		local battlePanel = modules.game_battle.battlePanel
		local attackedCreature = g_game.getAttackingCreature()
		local prevChild = nil

		for i, child in ipairs(battlePanel:getChildren()) do
			if not child.creature or not child:isOn() then
				break
			end

			if child.creature == attackedCreature then
				break
			end

			prevChild = child
		end

		if prevChild and prevChild.creature ~= attackedCreature then
			g_game.attack(prevChild.creature)
		end
	end)
	addExtraHotkey("toogleWsad", "toggle wsad walking", function (repeated)
		if repeated or not modules.game_console then
			return
		end

		if not modules.game_console.consoleToggleChat:isChecked() then
			modules.game_console.disableChat(true)
		else
			modules.game_console.enableChat(true)
		end
	end)
	addExtraHotkey("lootnearestbody", "Loot bodies near you", function (repeated)
		local protocolGame = g_game.getProtocolGame()

		protocolGame:sendExtendedOpcode(ExtendedIds.AutoLoot_Nearest, 1)
	end)
end

function setupComboBox(combobox)
	for index, actionDetails in ipairs(extraHotkeys) do
		combobox:addOption(actionDetails.description)
	end
end

function executeExtraHotkey(action, repeated)
	action = action:lower()

	for index, actionDetails in ipairs(extraHotkeys) do
		if actionDetails.name == action and actionDetails.callback then
			actionDetails.callback(repeated)
		end
	end
end

function translateActionToActionComboboxIndex(action)
	action = action:lower()

	for index, actionDetails in ipairs(extraHotkeys) do
		if actionDetails.name == action then
			return index
		end
	end

	return 1
end

function translateActionComboboxIndexToAction(index)
	if index > 1 and index <= #extraHotkeys then
		return extraHotkeys[index].name
	end

	return nil
end

function getActionDescription(action)
	action = action:lower()

	for index, actionDetails in ipairs(extraHotkeys) do
		if actionDetails.name == action then
			return actionDetails.description
		end
	end

	return "invalid action"
end

function getBottomPanelHeight()
	local bottomPanel = modules.game_interface.getBottomActionPanel()
	local rect = 0

	for index, child in ipairs(bottomPanel:getChildren()) do
		if child:isOn() then
			rect = rect + child:getChildrenRect().height
		end
	end

	return rect
end
