local minimapWidgetBig = nil
local minimapWindowBig = nil
local loaded = false
local minimapUpdateEvent

function init()
  minimapWindowBig = g_ui.loadUI('minimap_big', modules.game_interface.getRootPanel())
  minimapWidgetBig = minimapWindowBig:recursiveGetChildById('minimapWidgetBig')
  minimapWidgetBig.onMousePress = onMinimapMousePress

  Keybind.new("Windows", "Toggle Big Minimap", "Ctrl+Shift+M", "")
  Keybind.bind("Windows", "Toggle Big Minimap", {
    {
      type = KEY_DOWN,
      callback = toggle,
    }
  })

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
  if minimapUpdateEvent then
    removeEvent(minimapUpdateEvent)
    minimapUpdateEvent = nil
  end

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline
  })
  disconnect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  Keybind.delete("Windows", "Toggle Big Minimap")

  if minimapWindowBig then
    minimapWindowBig:destroy()
  end

  loaded = false
end

function toggle()
  if not minimapWindowBig then return end
  if minimapWindowBig:isVisible() then
    minimapWindowBig:hide()
  else
    minimapWindowBig:show()
    updateCameraPosition()
  end
end

function close()
  if not minimapWindowBig then return end
  if minimapWindowBig:isVisible() then
    minimapWindowBig:hide()
  end
end

function online()
  loadMap()
  local function safeUpdate()
    if minimapWidgetBig and not minimapWidgetBig:isDestroyed() and minimapWidgetBig:isVisible() and minimapWidgetBig:getLayout() then
      updateCameraPosition()
    else
      if minimapUpdateEvent then
        removeEvent(minimapUpdateEvent)
      end
      minimapUpdateEvent = scheduleEvent(safeUpdate, 100)
    end
  end
  safeUpdate()
end

function offline()
  if minimapUpdateEvent then
    removeEvent(minimapUpdateEvent)
    minimapUpdateEvent = nil
  end
end

function loadMap()
  local clientVersion = g_game.getClientVersion()

  loaded = false
  g_minimap.clean()
  local characterFile = nil
  local minimapFile = '/minimap.otmm'
  local dataMinimapFile = '/data' .. minimapFile
  local versionedMinimapFile = '/minimap' .. clientVersion .. '.otmm'
  local localPlayer = g_game.getLocalPlayer()

  if localPlayer then
    local playerName = localPlayer:getName()

    if playerName then
      characterFile = '/minimap-' .. playerName .. '.otmm'
    end
  end

  if characterFile and g_resources.fileExists(characterFile) then
    loaded = g_minimap.loadOtmm(characterFile)
  end

  if not loaded and g_resources.fileExists(dataMinimapFile) then
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

  minimapWidgetBig:load()
end

function updateCameraPosition()
  if not minimapWidgetBig or not minimapWidgetBig:isVisible() or not minimapWidgetBig:getLayout() then
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

  if not minimapWidgetBig:isDragging() then
    minimapWidgetBig:setCameraPosition(pos)
  end
  minimapWidgetBig:setCrossPosition(pos)
end

function onMinimapMousePress(widget, mousePosition, mouseButton)
  if mouseButton == MouseRightButton then
    -- Map marks not implemented in this version
    return
  end

  local pos = minimapWidgetBig:getTilePosition(mousePosition)
  if pos then
    local player = g_game.getLocalPlayer()
    if player and pos ~= player:getPosition() then
      player:autoWalk(pos)
    end
  end
end