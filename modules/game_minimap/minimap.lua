minimapWidget = nil
minimapButton = nil
minimapWindow = nil
fullmapView = false
loaded = false
oldZoom = nil
oldPos = nil

function init()
	minimapWindow = g_ui.loadUI("minimap", modules.game_interface.getRightPanel())

	minimapWindow:setContentMinimumHeight(64)

	-- Disable the built-in resize border so it doesn't interfere with the
	-- wide (2-column) minimap sizing.
	local resizeBorder = minimapWindow:getChildById("bottomResizeBorder")
	if resizeBorder then
		resizeBorder:setHeight(0)
		resizeBorder:setEnabled(false)
		resizeBorder:setVisible(false)
	end

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

-- minimapPosition: 1 = Right/1col, 2 = Right/2col, 3 = Left/1col, 4 = Left/2col
function getMinimapSideSpan()
	local p = g_settings.getNumber('minimapPosition')

	local side = (p >= 3) and 'left' or 'right'
	local span = (p == 2 or p == 4) and 2 or 1

	return side, span
end

local function getMinimapPosition(side, span)
	if side == 'left' then
		return (span == 2) and 4 or 3
	end

	return (span == 2) and 2 or 1
end

local function updateMinimapSideButtons()
	if not minimapWidget then
		return
	end

	local side = getMinimapSideSpan()
	local leftButton = minimapWidget:recursiveGetChildById('minimapMoveLeft')
	local rightButton = minimapWidget:recursiveGetChildById('minimapMoveRight')

	if leftButton then
		leftButton:setEnabled(side ~= 'left')
	end
	if rightButton then
		rightButton:setEnabled(side ~= 'right')
	end
end

local function setMinimapSide(side)
	if side ~= 'left' and side ~= 'right' then
		return
	end

	local _, span = getMinimapSideSpan()
	if modules.game_interface and modules.game_interface.ensureMinPanels then
		modules.game_interface.ensureMinPanels(side, span)
	end

	local position = getMinimapPosition(side, span)
	if modules.client_options and modules.client_options.setOption then
		modules.client_options.setOption('minimapPosition', position)
	else
		g_settings.set('minimapPosition', position)
		applyMinimapPosition()
	end

	updateMinimapSideButtons()
end

function moveMinimapLeft()
	setMinimapSide('left')
end

function moveMinimapRight()
	setMinimapSide('right')
end

local DEFAULT_HEIGHT = 117
local DEFAULT_MAP_SIZE = 106

local COMPACT_IDS = {
	'circle', 'panLeft', 'panRight', 'panUp', 'panDown', 'panReset',
	'compactZoomOut', 'compactZoomIn', 'compactFloorUp', 'compactFloorDown', 'compactCentre'
}
local WIDE_IDS = {
	'resetWidget', 'floorUpWidget', 'floorDownWidget', 'zoomOutWidget', 'zoomInWidget'
}

-- Switch between the original compact layout (1 column: 106x106 map + compass
-- cluster) and the wide layout (2 columns: map fills the window + corner
-- controls).
function setMinimapWideLayout(wide)
	if not minimapWindow or not minimapWidget then
		return
	end

	for _, id in ipairs(COMPACT_IDS) do
		local w = minimapWindow:recursiveGetChildById(id)
		if w then
			w:setVisible(not wide)
		end
	end

	for _, id in ipairs(WIDE_IDS) do
		local w = minimapWindow:recursiveGetChildById(id)
		if w then
			w:setVisible(wide)
		end
	end

	minimapWidget:breakAnchors()
	minimapWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
	minimapWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
	minimapWidget:setMarginTop(1)
	minimapWidget:setMarginLeft(1)

	if wide then
		minimapWidget:addAnchor(AnchorRight, 'parent', AnchorRight)
		minimapWidget:addAnchor(AnchorBottom, 'parent', AnchorBottom)
		minimapWidget:setMarginRight(1)
		minimapWidget:setMarginBottom(1)
	else
		minimapWidget:setWidth(DEFAULT_MAP_SIZE)
		minimapWidget:setHeight(DEFAULT_MAP_SIZE)
	end
end

function applyMinimapHeight(span, side)
	if not minimapWindow then
		return
	end

	if span == 2 then
		minimapWindow:setFixedSize(false)
		local w = modules.game_interface.getSideColumnsWidth(side or 'right')
		if w > 0 then
			minimapWindow:setHeight(math.floor(w * 0.5))
		end
	else
		minimapWindow:setFixedSize(false)
		minimapWindow:setHeight(DEFAULT_HEIGHT)
	end

	updateCameraPosition()
end

-- Docks the minimap window either in the wide panel (2 columns) or in the
-- normal side panel (1 column).
function applyMinimapPosition()
	if not minimapWindow then
		return
	end

	local side, span = getMinimapSideSpan()
	local isWide = (span == 2)
	local gi = modules.game_interface

	if isWide then
		gi.ensureMinPanels(side, 2)
	end

	local target
	if isWide then
		target = (side == 'left') and gi.getWideLeftPanel() or gi.getWideRightPanel()
	else
		target = (side == 'left') and gi.getLeftPanel() or gi.getRightPanel()
	end

	if not target then
		target = gi.getRightPanel()
	end

	if target and minimapWindow:getParent() ~= target then
		minimapWindow:setParent(target)
	end

	if target then
		target:moveChildToIndex(minimapWindow, 1)
		minimapWindow:raise()
	end

	scheduleEvent(function ()
		if not minimapWindow then
			return
		end

		gi.syncWidePanels()
		setMinimapWideLayout(isWide)
		updateMinimapSideButtons()
		applyMinimapHeight(span, side)

		local p = minimapWindow:getParent()
		if p then
			p:moveChildToIndex(minimapWindow, 1)
		end

		addEvent(function ()
			if not minimapWindow then
				return
			end

			gi.syncWidePanels()
			updateMinimapSideButtons()
			applyMinimapHeight(span, side)
		end)
	end, 60)
end

function online()
	loadMap()
	-- Give it a bit more time and check for layout
	local function safeUpdate()
		if minimapWidget and minimapWidget:getLayout() then
			updateCameraPosition()
		else
			scheduleEvent(safeUpdate, 100)
		end
	end
	safeUpdate()

	-- Apply the saved minimap column position once the game UI is ready.
	scheduleEvent(function ()
		applyMinimapPosition()
	end, 200)
end

function offline()
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
