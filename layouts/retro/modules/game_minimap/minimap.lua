local minimapWidget = nil
local minimapButton = nil
local minimapWindow = nil
local loaded = false

function init()
  minimapWindow = g_ui.loadUI('minimap', modules.game_interface.getRightPanel())
  if not minimapWindow then return end
  minimapWindow:setContentMinimumHeight(64)

  if not minimapWindow or not minimapWindow.forceOpen then
    minimapButton = modules.client_topmenu.addRightGameToggleButton('minimapButton', 
      tr('Minimap'), '/images/topbuttons/minimap', toggle)
    minimapButton:setOn(true)
  end

  minimapWidget = minimapWindow:recursiveGetChildById('minimap')
  modules.game_minimap.minimapWidget = minimapWidget

  -- Add big minimap button (opens big map modal)
  local bigMapButton = g_ui.createWidget('UIButton', minimapWidget)
  bigMapButton:setId('bigMapButton')
  bigMapButton:setWidth(20)
  bigMapButton:setHeight(20)
  bigMapButton:setMarginTop(-2)
  bigMapButton:setMarginRight(11)
  bigMapButton:addAnchor(AnchorRight, 'prev', AnchorLeft)
  bigMapButton:addAnchor(AnchorTop, 'prev', AnchorTop)
  bigMapButton:setTooltip(tr('Open big minimap'))
  bigMapButton:setIcon('/images/topbuttons/minimap')
  bigMapButton.onClick = function()
    modules.game_minimap_big.toggle()
  end

  local gameRootPanel = modules.game_interface.getRootPanel()

  Keybind.new("Windows", "Toggle Minimap", "", "")

  Keybind.new("Minimap", "Center", "", "")
  Keybind.new("Minimap", "One Floor Down", "Alt+PageDown", "")
  Keybind.new("Minimap", "One Floor Up", "Alt+PageUp", "")
  Keybind.new("Minimap", "Scroll East", "Alt+Right", "")
  Keybind.new("Minimap", "Scroll North", "Alt+Up", "")
  Keybind.new("Minimap", "Scroll South", "Alt+Down", "")
  Keybind.new("Minimap", "Scroll West", "Alt+Left", "")
  Keybind.new("Minimap", "Zoom In", "Alt+End", "")
  Keybind.new("Minimap", "Zoom Out", "Alt+Home", "")

  Keybind.bind("Windows", "Toggle Minimap", {
    {
      type = KEY_DOWN,
      callback = toggle,
    }
  })
  Keybind.bind("Minimap", "Center", {
    {
      type = KEY_DOWN,
      callback = center,
    }
  })
  Keybind.bind("Minimap", "One Floor Down", {
    {
      type = KEY_DOWN,
      callback = floorDown,
    }
  })
  Keybind.bind("Minimap", "One Floor Up", {
    {
      type = KEY_DOWN,
      callback = floorUp,
    }
  })
  Keybind.bind("Minimap", "Scroll East", {
    {
      type = KEY_PRESS,
      callback = function() minimapWidget:move(-1, 0) end,
    }
  }, gameRootPanel)
  Keybind.bind("Minimap", "Scroll North", {
    {
      type = KEY_PRESS,
      callback = function() minimapWidget:move(0, 1) end,
    }
  }, gameRootPanel)
  Keybind.bind("Minimap", "Scroll South", {
    {
      type = KEY_PRESS,
      callback = function() minimapWidget:move(0, -1) end,
    }
  }, gameRootPanel)
  Keybind.bind("Minimap", "Scroll West", {
    {
      type = KEY_PRESS,
      callback = function() minimapWidget:move(1, 0) end,
    }
  }, gameRootPanel)
  Keybind.bind("Minimap", "Zoom In", {
    {
      type = KEY_DOWN,
      callback = zoomIn,
    }
  })
  Keybind.bind("Minimap", "Zoom Out", {
    {
      type = KEY_DOWN,
      callback = zoomOut,
    }
  })

  minimapWindow:setup()

  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
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
    onGameEnd = offline,
  })

  disconnect(LocalPlayer, {
    onPositionChange = updateCameraPosition
  })

  Keybind.delete("Windows", "Toggle Minimap")

  Keybind.delete("Minimap", "Center")
  Keybind.delete("Minimap", "One Floor Down")
  Keybind.delete("Minimap", "One Floor Up")
  Keybind.delete("Minimap", "Scroll East")
  Keybind.delete("Minimap", "Scroll North")
  Keybind.delete("Minimap", "Scroll South")
  Keybind.delete("Minimap", "Scroll West")
  Keybind.delete("Minimap", "Zoom In")
  Keybind.delete("Minimap", "Zoom Out")

  minimapWindow:destroy()
  modules.game_minimap.minimapWidget = nil
  if minimapButton then
    minimapButton:destroy()
  end

  loaded = false
end

function toggle()
  if not minimapButton or not minimapWindow then return end
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
  loadMap()
  updateCameraPosition()
end

function offline()
  saveMap()
end

function loadMap()
  local clientVersion = g_game.getClientVersion()

  g_minimap.clean()
  loaded = false

  local minimapFile = '/minimap.otmm'
  local dataMinimapFile = '/data' .. minimapFile
  local versionedMinimapFile = '/minimap' .. clientVersion .. '.otmm'
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

function saveMap()
  if not minimapWidget then return end
  local clientVersion = g_game.getClientVersion()
  local minimapFile = '/minimap' .. clientVersion .. '.otmm' 
  g_minimap.saveOtmm(minimapFile)
  minimapWidget:save()
end

function updateCameraPosition()
  local player = g_game.getLocalPlayer()
  if not player then return end
  local pos = player:getPosition()
  if not pos then return end
  if not minimapWidget:isDragging() then
    minimapWidget:setCameraPosition(pos)
  end
  minimapWidget:setCrossPosition(pos)
end

function center()
  minimapWidget:reset()
end

function floorDown()
  minimapWidget:floorDown(1)
end

function floorUp()
  minimapWidget:floorUp(1)
end

function zoomIn()
  minimapWidget:zoomIn()
end

function zoomOut()
  minimapWidget:zoomOut()
end
