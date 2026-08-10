minimapWidget = nil
minimapButton = nil
minimapWindow = nil
fullmapView = false
loaded = false
oldZoom = nil
oldPos = nil
local cameraUpdateEvent = nil

local function cancelCameraUpdate()
	if cameraUpdateEvent then
		removeEvent(cameraUpdateEvent)
		cameraUpdateEvent = nil
	end
end

function init()
	local minimapUi = "minimap"
	if g_resources.getLayout() == "retro" then
		minimapUi = "/layouts/retro/modules/game_minimap/minimap.otui"
	end
	minimapWindow = g_ui.loadUI(minimapUi, modules.game_interface.getRightPanel())

	minimapWindow:setContentMinimumHeight(64)

	if not minimapWindow.forceOpen then
		minimapButton = modules.client_topmenu.addRightGameToggleButton("minimapButton", tr("Minimap") .. " (Ctrl+M)", "/images/topbuttons/minimap", toggle)

		minimapButton:setOn(true)
	end

	minimapWidget = minimapWindow:recursiveGetChildById("minimap")
	local gameRootPanel = modules.game_interface.getRootPanel()

	g_keyboard.bindKeyPress("Alt+Left", function ()
		minimapWidget:move(1, 0)
	end, gameRootPanel)
	g_keyboard.bindKeyPress("Alt+Right", function ()
		minimapWidget:move(-1, 0)
	end, gameRootPanel)
	g_keyboard.bindKeyPress("Alt+Up", function ()
		minimapWidget:move(0, 1)
	end, gameRootPanel)
	g_keyboard.bindKeyPress("Alt+Down", function ()
		minimapWidget:move(0, -1)
	end, gameRootPanel)
	minimapWindow:setup()
	minimapWindow:open()
	connect(g_game, {
		onGameStart = online,
		onGameEnd = offline
	})
	connect(LocalPlayer, {
		onPositionChange = updateCameraPosition
	})

	if g_game.isOnline() then
		online()
	end
end

function terminate()
	cancelCameraUpdate()

	if g_game.isOnline() then
		saveMap()
	end

	disconnect(g_game, {
		onGameStart = online,
		onGameEnd = offline
	})
	disconnect(LocalPlayer, {
		onPositionChange = updateCameraPosition
	})

	local gameRootPanel = modules.game_interface.getRootPanel()

	g_keyboard.unbindKeyPress("Alt+Left", gameRootPanel)
	g_keyboard.unbindKeyPress("Alt+Right", gameRootPanel)
	g_keyboard.unbindKeyPress("Alt+Up", gameRootPanel)
	g_keyboard.unbindKeyPress("Alt+Down", gameRootPanel)
	minimapWindow:destroy()

	if minimapButton then
		minimapButton:destroy()
	end
end

function toggle()
	if not minimapButton then
		return
	end

	if minimapButton:isOn() then
		minimapWindow:close()
		minimapButton:setOn(false)
	else
		minimapWindow:open()
		minimapButton:setOn(true)
	end
end

function onMiniWindowClose()
	if minimapButton then
		minimapButton:setOn(false)
	end
end

function online()
	cancelCameraUpdate()
	loadMap()
	-- Give it a bit more time and check for layout
	local function safeUpdate()
		cameraUpdateEvent = nil
		if not g_game.isOnline() then
			return
		end
		if minimapWidget and not minimapWidget:isDestroyed() and minimapWidget:getLayout() then
			updateCameraPosition()
		else
			cameraUpdateEvent = scheduleEvent(safeUpdate, 100)
		end
	end
	safeUpdate()
end

function offline()
	cancelCameraUpdate()
	saveMap()
end

function loadMap()
	local clientVersion = g_game.getClientVersion()

	g_minimap.clean()

	loaded = false
	local characterFile = nil
	local minimapFile = "/minimap.otmm"
	local dataMinimapFile = "/data" .. minimapFile
	local versionedMinimapFile = "/minimap" .. clientVersion .. ".otmm"
	local localPlayer = g_game.getLocalPlayer()

	if localPlayer then
		local playerName = localPlayer:getName()

		if playerName then
			characterFile = "/minimap-" .. playerName .. ".otmm"
		end
	end

	if characterFile and g_resources.fileExists(characterFile) then
		loaded = g_minimap.loadOtmm(characterFile)
	end

	if not loaded and g_resources.fileExists(dataMinimapFile) then
		loaded = g_minimap.loadOtmm(dataMinimapFile)
	end

	if g_resources.fileExists(dataMinimapFile) then
		loaded = g_minimap.loadOtmm(dataMinimapFile)
	end

	if not loaded and g_resources.fileExists(versionedMinimapFile) then
		loaded = g_minimap.loadOtmm(versionedMinimapFile)
	end

	if not loaded and g_resources.fileExists(minimapFile) then
		loaded = g_minimap.loadOtmm(minimapFile)
	end

	if not loaded then
		print("Minimap couldn't be loaded, file missing?")
	end

	-- minimapWidget:load() -- This method does not exist in C++ UIMinimap
end

function saveMap()
	local localPlayer = g_game.getLocalPlayer()

	if localPlayer then
		local playerName = localPlayer:getName()

		if playerName then
			characterFile = "/minimap-" .. playerName .. ".otmm"

			g_minimap.saveOtmm(characterFile)
			minimapWidget:save()
		end
	else
		local clientVersion = g_game.getClientVersion()
		local minimapFile = "/minimap" .. clientVersion .. ".otmm"

		g_minimap.saveOtmm(minimapFile)
		minimapWidget:save()
	end
end

function updateCameraPosition()
	if not minimapWidget or not minimapWidget:isVisible() or not minimapWidget:getLayout() then
		return
	end

	local player = g_game.getLocalPlayer()
	if not player then
		return
	end

	local pos = player:getPosition()
	if not pos then
		return
	end

	if not minimapWidget:isDragging() then
		if not fullmapView then
			minimapWidget:setCameraPosition(pos)
		end

		minimapWidget:setCrossPosition(pos)
	end
end

function toggleFullMap()
	if not fullmapView then
		fullmapView = true

		minimapWindow:hide()
		minimapWidget:setParent(modules.game_interface.getRootPanel())
		minimapWidget:fill("parent")
		minimapWidget:setAlternativeWidgetsVisible(true)
	else
		fullmapView = false

		minimapWidget:setParent(minimapWindow:getChildById("contentsPanel"))
		minimapWidget:fill("parent")
		minimapWindow:show()
		minimapWidget:setAlternativeWidgetsVisible(false)
	end

	local zoom = oldZoom or 0
	local pos = oldPos or minimapWidget:getCameraPosition()
	oldZoom = minimapWidget:getZoom()
	oldPos = minimapWidget:getCameraPosition()

	minimapWidget:setZoom(zoom)
	minimapWidget:setCameraPosition(pos)
end
