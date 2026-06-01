local defaultOptions = {
	leftPanels = 0,
	classicView = true,
	dontStretchShrink = false,
	fullscreen = false,
	showPing = true,
	showInfoBanner = true,
	showFps = true,
	hdmodeBox = true,
	vsync = true,
	botSoundVolume = 0,
	floorFading = 100,
	crosshair = 1,
	ambientLight = 50,
	optimizationLevel = 1,
	musicSoundVolume = 0,
	displayHealth = true,
	displayMana = false,
	displayHealthOnTop = false,
	showHealthManaCircle = false,
	antialiasing = true,
	profile = 1,
	actionbarLock = false,
	actionbar9 = false,
	actionbar8 = false,
	actionbar7 = false,
	actionbar6 = false,
	actionbar5 = false,
	actionbar4 = false,
	actionbar3 = false,
	actionbar2 = false,
	actionbar1 = false,
	topBar = false,
	walkCtrlTurnDelay = 150,
	walkTeleportDelay = 50,
	walkStairsDelay = 50,
	walkTurnDelay = 100,
	walkFirstStepDelay = 100,
	moveFullStack = false,
	wsadWalking = false,
	hotkeyDelay = 30,
	turnDelay = 100,
	displayText = true,
	displayFullHpMpPercent = false,
	topHealtManaBar = false,
	hidePlayerBars = true,
	enableMusicSound = false,
	enableAudio = true,
	backgroundFrameRate = 60,
	containerPanel = 8,
	minimapPosition = 1,
	displayNames = true,
	rightPanels = 1,
	showPrivateMessagesOnScreen = true,
	showPrivateMessagesInConsole = true,
	showLevelsInConsole = true,
	showTimestampsInConsole = true,
	showInfoMessagesInConsole = true,
	showEventMessagesInConsole = true,
	showStatusMessagesInConsole = true,
	autoChaseOverride = true,
	dash = false,
	smartWalk = false,
	layout = DEFAULT_LAYOUT,
	cacheMap = g_app.isMobile(),
	classicControl = not g_app.isMobile()
}
optionsWindow = nil
optionsButton = nil
options = {}
extraOptions = {}
subWindows = {}

local function createSubWindow(id, title, uiName, size)
	local window = g_ui.createWidget("MainWindow", rootWidget)

	window:setId(id)
	window:setText(title)
	window:setSize(size or {
		width = 350,
		height = 400
	})
	window:setDraggable(false)
	window:hide()

	if uiName then
		local panel = g_ui.loadUI(uiName, window)

		if panel then
			panel:fill("parent")
			panel:setMarginBottom(35)
		end
	end

	local closeBtn = g_ui.createWidget("Button", window)

	closeBtn:setText("Ok")
	closeBtn:setWidth(50)
	closeBtn:addAnchor(AnchorBottom, "parent", AnchorBottom)
	closeBtn:addAnchor(AnchorRight, "parent", AnchorRight)

	function closeBtn.onClick()
		window:hide()
		show()
	end

	function window.onEscape()
		window:hide()
		show()
	end

	function window.onEnter()
		window:hide()
		show()
	end

	return window
end

function init()
	for k, v in pairs(defaultOptions) do
		g_settings.setDefault(k, v)

		options[k] = v
	end

	for _, v in ipairs(g_extras.getAll()) do
		extraOptions[v] = g_extras.get(v)

		g_settings.setDefault("extras_" .. v, extraOptions[v])
	end

	optionsWindow = g_ui.displayUI("options")

	optionsWindow:setDraggable(false)
	optionsWindow:hide()

	function optionsWindow.onEnter()
		hide()
	end

	subWindows.general = createSubWindow("generalWindow", tr("General Options"), "game", {
		width = 280,
		height = 510
	})
	subWindows.graphics = createSubWindow("graphicsWindow", tr("Graphics"), "graphics", {
		width = 270,
		height = 470
	})
	subWindows.console = createSubWindow("consoleWindow", tr("Console"), "console", {
		width = 320,
		height = 280
	})
	subWindows.actionbars = createSubWindow("actionbarsWindow", tr("Actionbars"), "custom", {
		width = 300,
		height = 290
	})

	g_keyboard.bindKeyDown("Ctrl+Shift+F", function ()
		toggleOption("fullscreen")
	end)
	g_keyboard.bindKeyDown("Ctrl+N", toggleDisplays)

	optionsButton = modules.client_topmenu.addLeftButton("optionsButton", tr("Options"), "/images/topbuttons/options", toggle)
	audioButton = modules.client_topmenu.addLeftButton("audioButton", tr("Audio"), "/images/topbuttons/audio", function ()
		toggleOption("enableAudio")
	end)

	if g_app.isMobile() then
		audioButton:hide()
	end

	addEvent(function ()
		setup()
	end)
	connect(g_game, {
		onGameStart = online,
		onGameEnd = offline
	})
end

function terminate()
	disconnect(g_game, {
		onGameStart = online,
		onGameEnd = offline
	})
	g_keyboard.unbindKeyDown("Ctrl+Shift+F")
	g_keyboard.unbindKeyDown("Ctrl+N")
	optionsWindow:destroy()
	optionsButton:destroy()
	audioButton:destroy()

	for _, win in pairs(subWindows) do
		win:destroy()
	end

	subWindows = {}
end

function toggleSubWindow(name)
	local win = subWindows[name]

	if win then
		if win:isVisible() then
			win:hide()
			show()
		else
			hide()
			win:show()
			win:raise()
			win:focus()

			if name == "general" then
				updatePanelCheckboxes()
			end
		end
	end
end

-- Side-panel column controls (General Options).
-- leftPanels is stored with a +1 offset (refreshViewMode subtracts 1), so the
-- real left column count is getNumber('leftPanels') - 1 (range 0..2).
-- rightPanels is stored as the real count (range 1..2).
function updatePanelCheckboxes()
	local win = subWindows and subWindows.general
	if not win then
		return
	end

	local lc = g_settings.getNumber('leftPanels') - 1
	local rc = g_settings.getNumber('rightPanels')

	local function set(id, checked)
		local w = win:recursiveGetChildById(id)
		if w then
			w:setChecked(checked)
		end
	end

	set('leftAll', lc >= 2)
	set('left1', lc >= 1)
	set('left2', lc >= 2)
	set('rightAll', rc >= 2)
	set('right1', rc >= 2)
	set('right2', true)
end

-- If the minimap is set to span 2 columns on a side that no longer has 2
-- columns, keep it on the same side when possible and fall back safely.
local function checkMinimapRevert()
	local p = g_settings.getNumber('minimapPosition')
	local leftCount = g_settings.getNumber('leftPanels') - 1
	local rightCount = g_settings.getNumber('rightPanels')
	local nextPosition = p

	if p == 4 and leftCount < 2 then
		nextPosition = (leftCount >= 1) and 3 or 1
	elseif p == 2 and rightCount < 2 then
		nextPosition = 1
	end

	if nextPosition ~= p then
		setOption('minimapPosition', nextPosition)

		local win = subWindows and subWindows.general
		if win then
			local w = win:recursiveGetChildById('minimapPosition')
			if w then
				w:setCurrentIndex(nextPosition, true)
			end
		end
	elseif modules.game_minimap and modules.game_minimap.applyMinimapPosition then
		modules.game_minimap.applyMinimapPosition()
	end
end

function validateMinimapPosition()
	checkMinimapRevert()
end

function setLeftColumns(which)
	local lc = g_settings.getNumber('leftPanels') - 1

	if which == 'all' then
		lc = (lc >= 2) and 0 or 2
	elseif which == '1' then
		lc = (lc >= 1) and 0 or 1
	elseif which == '2' then
		lc = (lc >= 2) and 1 or 2
	end

	setOption('leftPanels', lc + 1)
	updatePanelCheckboxes()
	checkMinimapRevert()

	if modules.game_minimap and modules.game_minimap.applyMinimapPosition then
		modules.game_minimap.applyMinimapPosition()
	end
end

function setRightColumns(which)
	local rc = g_settings.getNumber('rightPanels')

	if which == 'all' or which == '1' then
		rc = (rc >= 2) and 1 or 2
	else
		rc = math.max(1, rc)
	end

	setOption('rightPanels', rc)
	updatePanelCheckboxes()
	checkMinimapRevert()

	if modules.game_minimap and modules.game_minimap.applyMinimapPosition then
		modules.game_minimap.applyMinimapPosition()
	end
end

function setup()
	for k, v in pairs(defaultOptions) do
		if type(v) == "boolean" then
			setOption(k, g_settings.getBoolean(k), true)
		elseif type(v) == "number" then
			setOption(k, g_settings.getNumber(k), true)
		elseif type(v) == "string" then
			setOption(k, g_settings.getString(k), true)
		end
	end

	for _, v in ipairs(g_extras.getAll()) do
		g_extras.set(v, g_settings.getBoolean("extras_" .. v))
	end

	if g_game.isOnline() then
		online()
	end
end

function toggle()
	if optionsWindow:isVisible() then
		hide()
	else
		show()
	end
end

function show()
	optionsWindow:show()
	optionsWindow:raise()
	optionsWindow:focus()
end

function hide()
	optionsWindow:hide()
end

function cancel()
	optionsWindow:hide()
end

function toggleDisplays()
	if options.displayNames and options.displayHealth and options.displayMana then
		setOption("displayNames", false)
	elseif options.displayHealth then
		setOption("displayHealth", false)
		setOption("displayMana", false)
	elseif not options.displayNames and not options.displayHealth then
		setOption("displayNames", true)
	else
		setOption("displayHealth", true)
		setOption("displayMana", true)
	end
end

function toggleOption(key)
	setOption(key, not getOption(key))
end

local function resolveOptionKeyValue(key, value)
	if key == "mapView" then
		return "classicView", not value
	end

	return key, value
end

local function syncOptionWidget(widget, value)
	if widget:getStyle().__class == "UICheckBox" then
		widget:setChecked(value)
	elseif widget:getStyle().__class == "UIScrollBar" then
		widget:setValue(value)
	elseif widget:getStyle().__class == "UIComboBox" then
		if type(value) == "string" then
			widget:setCurrentOption(value, true)
		else
			if value == nil or value < 1 then
				value = 1
			end

			if widget.currentIndex ~= value then
				widget:setCurrentIndex(value, true)
			end
		end
	end
end

local function syncAliasOptionWidget(window, key, value)
	local aliasKey
	local aliasValue

	if key == "classicView" then
		aliasKey = "mapView"
		aliasValue = not value
	elseif key == "mapView" then
		aliasKey = "classicView"
		aliasValue = not value
	end

	if not aliasKey then
		return
	end

	local aliasWidget = window:recursiveGetChildById(aliasKey)
	if aliasWidget then
		syncOptionWidget(aliasWidget, aliasValue)
	end
end

function setOption(key, value, force)
	local requestedKey = key
	local requestedValue = value
	key, value = resolveOptionKeyValue(key, value)

	if extraOptions[key] ~= nil then
		g_extras.set(key, value)
		g_settings.set("extras_" .. key, value)

		if key == "debugProxy" and modules.game_proxy then
			if value then
				modules.game_proxy.show()
			else
				modules.game_proxy.hide()
			end
		end

		return
	end

	if modules.game_interface == nil then
		return
	end

	if not force and options[key] == value then
		return
	end

	local gameMapPanel = modules.game_interface.getMapPanel()

	if key == "vsync" then
		g_window.setVerticalSync(value)
	elseif key == "showFps" then
		modules.client_topmenu.setFpsVisible(value)
	elseif key == "showPing" then
		modules.client_topmenu.setPingVisible(value)
	elseif key == "fullscreen" then
		g_window.setFullscreen(value)
	elseif key == "dontStretchShrink" then
		addEvent(function ()
			modules.game_interface.updateStretchShrink()
		end)
	elseif key == "enableAudio" then
		if g_sounds ~= nil then
			g_sounds.setAudioEnabled(value)
		end

		if value then
			audioButton:setIcon("/images/topbuttons/audio")
		else
			audioButton:setIcon("/images/topbuttons/audio_mute")
		end
	elseif key == "enableMusicSound" then
		if g_sounds ~= nil then
			g_sounds.getChannel(SoundChannels.Music):setEnabled(value)
		end
	elseif key == "musicSoundVolume" then
		if g_sounds ~= nil then
			g_sounds.getChannel(SoundChannels.Music):setGain(value / 100)
		end

		for _, win in pairs(subWindows) do
			local label = win:recursiveGetChildById("musicSoundVolumeLabel")

			if label then
				label:setText(tr("Music volume: %d", value))
			end
		end
	elseif key == "botSoundVolume" then
		if g_sounds ~= nil then
			g_sounds.getChannel(SoundChannels.Bot):setGain(value / 100)
		end
	elseif key == "backgroundFrameRate" then
		local text = value
		local v = value

		if value <= 0 or value >= 201 then
			text = "max"
			v = 0
		end

		g_app.setMaxFps(v)

		for _, win in pairs(subWindows) do
			local label = win:recursiveGetChildById("backgroundFrameRateLabel")

			if label then
				label:setText(tr("Adjust framerate limit: %s", text))
			end
		end
	elseif key == "crosshair" then
		gameMapPanel:setCrosshair("")
	elseif key == "ambientLight" then
		gameMapPanel:setMinimumAmbientLight(value / 100)
		gameMapPanel:setDrawLights(value < 100)

		for _, win in pairs(subWindows) do
			local label = win:recursiveGetChildById("ambientLightLabel")

			if label then
				label:setText(tr("Ambient light: %s%%", value))
			end
		end
	elseif key == "optimizationLevel" then
		g_adaptiveRenderer.setLevel(value - 2)
	elseif key == "displayNames" then
		gameMapPanel:setDrawNames(value)
	elseif key == "displayHealth" then
		gameMapPanel:setDrawHealthBars(value)
	elseif key == "displayMana" then
		gameMapPanel:setDrawManaBar(value)
	elseif key == "displayHealthOnTop" then
		gameMapPanel:setDrawHealthBarsOnTop(value)
	elseif key == "displayText" then
		gameMapPanel:setDrawTexts(value)
	elseif key == "displayFullHpMpPercent" then
		if modules.game_healthinfo and modules.game_healthinfo.refreshHealthManaDisplay then
			modules.game_healthinfo.refreshHealthManaDisplay()
		end
	elseif key == "dash" then
		g_game.setMaxPreWalkingSteps(2)
	elseif key == "wsadWalking" then
		if modules.game_console and modules.game_console.consoleToggleChat:isChecked() ~= value then
			modules.game_console.consoleToggleChat:setChecked(value)
		end
	elseif key == "antialiasing" then
		g_app.setSmooth(value)
	elseif key == "hdmodeBox" then
		if g_sprites and g_sprites.setScaleFactor then
			g_sprites.setScaleFactor(value and 2 or 1)
		end
	end

	for _, win in pairs(subWindows) do
		local widget = win:recursiveGetChildById(key)

		if widget then
			syncOptionWidget(widget, value)
		end

		syncAliasOptionWidget(win, key, value)

		if requestedKey ~= key then
			local requestedWidget = win:recursiveGetChildById(requestedKey)

			if requestedWidget then
				syncOptionWidget(requestedWidget, requestedValue)
			end
		end
	end

	g_settings.set(key, value)

	options[key] = value

	if key == "profile" then
		modules.client_profiles.onProfileChange()
	end

	if key == "classicView" or key == "rightPanels" or key == "leftPanels" or key == "cacheMap" or key == "hdmodeBox" then
		modules.game_interface.refreshViewMode()
	elseif key == "minimapPosition" then
		if modules.game_minimap and modules.game_minimap.applyMinimapPosition then
			modules.game_minimap.applyMinimapPosition()
		end
	elseif key:find("actionbar") then
		if modules.game_actionbar then
			modules.game_actionbar.refresh()
		end
	end
end

function getOption(key)
	if key == "mapView" then
		return not options.classicView
	end

	return options[key]
end

function online()
	setLightOptionsVisibility(not g_game.getFeature(GameForceLight))
	g_app.setSmooth(g_settings.getBoolean("antialiasing"))
end

function offline()
	setLightOptionsVisibility(true)
end

function setLightOptionsVisibility(value)
	if subWindows.graphics then
		local lbl = subWindows.graphics:recursiveGetChildById("ambientLightLabel")
		local pnl = subWindows.graphics:recursiveGetChildById("ambientLight")

		if lbl then
			lbl:setEnabled(value)
		end

		if pnl then
			pnl:setEnabled(value)
		end
	end
end
