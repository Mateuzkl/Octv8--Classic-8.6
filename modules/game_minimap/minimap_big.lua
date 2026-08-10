minimapWidget = nil
minimapWindowBig = nil
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
	minimapWindowBig = g_ui.loadUI("minimap_big", modules.game_interface.getRootPanel())
	minimapWidget = minimapWindowBig:recursiveGetChildById("minimapWidgetBig")
	minimapWidget.onMousePress = onMinimapMousePress

	g_keyboard.bindKeyDown("Ctrl+M", toggle)
	minimapWindowBig:hide()
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

	disconnect(g_game, {
		onGameStart = online,
		onGameEnd = offline
	})
	disconnect(LocalPlayer, {
		onPositionChange = updateCameraPosition
	})
	g_keyboard.unbindKeyDown("Ctrl+M")
	minimapWindowBig:destroy()
end

function toggle()
	if minimapWindowBig:isVisible() then
		minimapWindowBig:hide()
	else
		minimapWindowBig:show()
		updateCameraPosition()
	end
end

function close()
	if minimapWindowBig:isVisible() then
		minimapWindowBig:hide()
	end
end

function online()
	cancelCameraUpdate()
	loadMap()
	local function safeUpdate()
		cameraUpdateEvent = nil
		if not g_game.isOnline() then
			return
		end
		if minimapWidget and not minimapWidget:isDestroyed() and minimapWidget:getLayout() then
			if minimapWidget:isVisible() then
				updateCameraPosition()
			end
		else
			cameraUpdateEvent = scheduleEvent(safeUpdate, 100)
		end
	end
	safeUpdate()
end

function offline()
	cancelCameraUpdate()
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

	minimapWidget:load()
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
		minimapWidget:setCameraPosition(pos)
		minimapWidget:setCrossPosition(pos)
	end
end
