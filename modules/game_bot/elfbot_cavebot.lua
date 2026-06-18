elfCavebotWindow = nil

local cavebotStatusEvent = nil
local selectedProfile = nil
local selectedWaypointIndex = nil

local function getBotWindow()
  if botWindow then return botWindow end
  return g_ui.getRootWidget():recursiveGetChildById('botWindow')
end

local function getElfCavebotChild(id)
  if not elfCavebotWindow or not elfCavebotWindow.recursiveGetChildById then
    return nil
  end
  return elfCavebotWindow:recursiveGetChildById(id)
end

local function callCavebotBridge(name, ...)
  local fn = modules and modules.game_bot and modules.game_bot[name]
  if type(fn) ~= "function" then
    return nil
  end

  local ok, result = pcall(fn, ...)
  if ok then
    return result
  end

  if g_logger and g_logger.error then
    g_logger.error("[ElfBot Cavebot] " .. name .. ": " .. tostring(result))
  end
  return nil
end

local function getPlayerPosition()
  local player = g_game.getLocalPlayer()
  if player then
    return player:getPosition()
  end
  return nil
end

local function parseActionPosition(action)
  if not action or type(action.value) ~= "string" then return nil end

  local x, y, z = nil, nil, nil
  if action.action == "goto" or action.action == "use" then
    x, y, z = action.value:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
  elseif action.action == "usewith" then
    local _, px, py, pz = action.value:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    x, y, z = px, py, pz
  end

  if not x or not y or not z then return nil end
  return { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
end

local function clearMapFlags(map)
  if not map or not map.flags then return end
  local flags = table.copy(map.flags)
  for _, flag in ipairs(flags) do
    if flag.temporary then
      flag:destroy()
    end
  end
end

local function setProfileName(name)
  local profileName = getElfCavebotChild("profileName")
  if profileName and name then
    profileName:setText(name)
  end
end

local function setStatusText(enabled, recording, profile, count)
  local status = getElfCavebotChild("cavebotStatus")
  if status then
    local state = enabled and "On" or "Off"
    local rec = recording and "Recording" or "Idle"
    status:setText(state .. " | " .. rec .. " | " .. (profile or "-") .. " | " .. tostring(count or 0) .. " wp")
    status:setColor(enabled and "#65d16e" or "#ff6b6b")
  end

  local recordButton = getElfCavebotChild("recordButton")
  if recordButton then
    recordButton:setText(recording and "Stop Rec" or "Record")
    recordButton:setColor(recording and "#65d16e" or "#d7d7d7")
  end
end

local function addListItem(list, text, color, onClick, onDoubleClick)
  local item = g_ui.createWidget("ElfCavebotListItem", list)
  item:setText(text)
  if color then item:setColor(color) end
  item.onMouseRelease = function(widget, mousePos, button)
    if button == MouseLeftButton and onClick then
      onClick(widget)
      return true
    end
    return false
  end
  item.onDoubleClick = function(widget)
    if onDoubleClick then
      onDoubleClick(widget)
      return true
    end
    return false
  end
  return item
end

local function refreshProfiles()
  local list = getElfCavebotChild("profileList")
  if not list then return end

  list:destroyChildren()

  local data = callCavebotBridge("elfCavebotBridgeProfiles") or {}
  selectedProfile = data.selected or selectedProfile
  if selectedProfile then
    setProfileName(selectedProfile)
  end

  for _, name in ipairs(data.profiles or {}) do
    addListItem(list, name, name == selectedProfile and "#65d16e" or "#d7d7d7", function(widget)
      selectedProfile = name
      list:focusChild(widget)
      setProfileName(name)
    end, function()
      selectedProfile = name
      modules.game_bot.elfCavebotLoadProfile()
    end)
  end
end

local function refreshWaypoints()
  local list = getElfCavebotChild("helperWaypointList")
  local map = getElfCavebotChild("cavebotMap")
  if not list then return 0 end

  list:destroyChildren()
  clearMapFlags(map)

  local actions = callCavebotBridge("elfCavebotBridgeActions") or {}
  local count = 0
  local firstPos = nil
  local playerPos = getPlayerPosition()

  if map and playerPos and not map.elfCavebotCameraReady then
    map:setCameraPosition(playerPos)
    map.elfCavebotCameraReady = true
  end

  for _, action in ipairs(actions) do
    count = count + 1
    local text = string.format("%02d  %s", action.index or count, action.text or "")
    local color = action.focused and "#65d16e" or nil
    local item = addListItem(list, text, color, function(widget)
      selectedWaypointIndex = action.index
      list:focusChild(widget)
      callCavebotBridge("elfCavebotBridgeFocusAction", action.index)
      modules.game_bot.elfCavebotFocusMapPosition(action.index)
    end, function()
      selectedWaypointIndex = action.index
      callCavebotBridge("elfCavebotBridgeFocusAction", action.index)
      modules.game_bot.elfCavebotEditSelected()
    end)
    item.actionIndex = action.index

    if action.focused then
      selectedWaypointIndex = action.index
      list:focusChild(item)
    end

    local pos = parseActionPosition(action)
    if pos and map then
      local icon = action.action == "goto" and 0 or 1
      if action.action == "usewith" then icon = 2 end
      map:addFlag(pos, icon, tostring(action.index or count) .. " " .. (action.action or ""), true)
      firstPos = firstPos or pos
    end
  end

  if map then
    if not map.elfCavebotCameraReady then
      if firstPos then
        map:setCameraPosition(firstPos)
        map.elfCavebotCameraReady = true
      end
    end
    if playerPos and map:getCameraPosition() then
      map:setCrossPosition({ x = playerPos.x, y = playerPos.y, z = playerPos.z })
    end
  end

  local positionLabel = getElfCavebotChild("positionLabel")
  if positionLabel then
    if playerPos then
      positionLabel:setText("Position: " .. playerPos.x .. ", " .. playerPos.y .. ", " .. playerPos.z)
    else
      positionLabel:setText("Position: -")
    end
  end

  return count
end

local function resetMapCamera()
  local map = getElfCavebotChild("cavebotMap")
  if map then
    map.elfCavebotCameraReady = nil
  end
end

local function updateCavebotStatus()
  removeEvent(cavebotStatusEvent)
  cavebotStatusEvent = nil

  if not elfCavebotWindow or not elfCavebotWindow:isVisible() then
    return
  end

  refreshProfiles()
  local count = refreshWaypoints()

  local enabled = callCavebotBridge("elfCavebotBridgeIsOn") == true
  local recording = callCavebotBridge("elfCavebotBridgeRecorderIsOn") == true
  local profile = callCavebotBridge("elfCavebotBridgeProfile") or selectedProfile or "-"
  setStatusText(enabled, recording, profile, count)

  local startButton = getElfCavebotChild("startButton")
  if startButton and startButton.setEnabled then startButton:setEnabled(not enabled) end
  local stopButton = getElfCavebotChild("stopButton")
  if stopButton and stopButton.setEnabled then stopButton:setEnabled(enabled) end

  cavebotStatusEvent = scheduleEvent(updateCavebotStatus, 1000)
end

local function promptText(defaultText, title, callback)
  if modules.client_textedit and modules.client_textedit.show then
    modules.client_textedit.show(defaultText, { title = title }, callback)
    return
  end
  if modules.client_textedit and modules.client_textedit.singlelineEditor then
    modules.client_textedit.singlelineEditor(defaultText, callback)
    return
  end
  callback(defaultText)
end

local function setupMap()
  local map = getElfCavebotChild("cavebotMap")
  if not map then return end

  map.onMouseRelease = function(widget, mousePos, button)
    if button ~= MouseRightButton then
      return UIMinimap.onMouseRelease(widget, mousePos, button)
    end

    local mapPos = widget:getTilePosition(mousePos)
    if not mapPos then return true end

    local menu = g_ui.createWidget('PopupMenu')
    menu:setGameMenu(true)
    menu:addOption(tr('Add GoTo'), function() modules.game_bot.elfCavebotAddAt('goto', mapPos) end)
    menu:addOption(tr('Add GoTo exact'), function() modules.game_bot.elfCavebotAddAt('gotoExact', mapPos) end)
    menu:addOption(tr('Add Use'), function() modules.game_bot.elfCavebotAddAt('use', mapPos) end)
    menu:addOption(tr('Add UseWith'), function()
      promptText("ITEMID", "UseWith", function(value)
        modules.game_bot.elfCavebotAddAt('usewith', mapPos, value)
      end)
    end)
    menu:addOption(tr('Create mark'), function() widget:createFlagWindow(mapPos) end)
    menu:display(mousePos)
    return true
  end
end

function elfCavebotInit()
  elfCavebotWindow = g_ui.displayUI('elfcavebot')
  elfCavebotWindow:disable()
  elfCavebotWindow:hide()
  setupMap()
end

function elfCavebotTerminate()
  elfCavebotClose()
  removeEvent(cavebotStatusEvent)
  cavebotStatusEvent = nil
  if elfCavebotWindow then
    elfCavebotWindow:destroy()
    elfCavebotWindow = nil
  end
end

function elfCavebotOpen()
  if not elfCavebotWindow then return end

  local bw = getBotWindow()
  if bw then
    local tabs = bw:recursiveGetChildById('botTabs')
    local tab = tabs and tabs:getTab("Cave")
    if tab then tab:setVisible(false) end
  end

  resetMapCamera()
  elfCavebotWindow:enable()
  elfCavebotWindow:show()
  elfCavebotWindow:raise()
  elfCavebotWindow:focus()
  updateCavebotStatus()
end

function elfCavebotClose()
  removeEvent(cavebotStatusEvent)
  cavebotStatusEvent = nil

  local bw = getBotWindow()
  if bw then
    local tabs = bw:recursiveGetChildById('botTabs')
    local tab = tabs and tabs:getTab("Cave")
    if tab then tab:setVisible(true) end
  end

  if elfCavebotWindow then
    elfCavebotWindow:hide()
  end
end

function elfCavebotRefresh()
  updateCavebotStatus()
end

function elfCavebotStart()
  callCavebotBridge("elfCavebotBridgeSetOn")
  updateCavebotStatus()
end

function elfCavebotStop()
  callCavebotBridge("elfCavebotBridgeSetOff")
  updateCavebotStatus()
end

function elfCavebotToggleEditor()
  callCavebotBridge("elfCavebotBridgeToggleEditor")
  updateCavebotStatus()
end

function elfCavebotToggleConfig()
  callCavebotBridge("elfCavebotBridgeToggleConfig")
  updateCavebotStatus()
end

function elfCavebotSave()
  callCavebotBridge("elfCavebotBridgeSave")
  updateCavebotStatus()
end

function elfCavebotSaveProfile()
  local profileName = getElfCavebotChild("profileName")
  local name = profileName and profileName:getText() or selectedProfile
  if not name or name:len() < 1 then
    return
  end
  selectedProfile = name:gsub("%s+", "_")
  callCavebotBridge("elfCavebotBridgeSaveProfile", selectedProfile)
  updateCavebotStatus()
end

function elfCavebotLoadProfile()
  local profileName = getElfCavebotChild("profileName")
  local name = selectedProfile or (profileName and profileName:getText())
  if not name or name:len() < 1 then
    return
  end
  selectedProfile = name
  resetMapCamera()
  callCavebotBridge("elfCavebotBridgeLoadProfile", name)
  updateCavebotStatus()
end

function elfCavebotDeleteProfile()
  local profileName = getElfCavebotChild("profileName")
  local name = selectedProfile or (profileName and profileName:getText())
  if not name or name:len() < 1 then
    return
  end
  callCavebotBridge("elfCavebotBridgeDeleteProfile", name)
  selectedProfile = nil
  updateCavebotStatus()
end

function elfCavebotToggleRecord()
  callCavebotBridge("elfCavebotBridgeToggleRecorder")
  updateCavebotStatus()
end

function elfCavebotAddAt(kind, mapPos, extra)
  if not mapPos then return end
  callCavebotBridge("elfCavebotBridgeAddAt", kind, mapPos, extra)
  updateCavebotStatus()
end

function elfCavebotAddCurrent(kind)
  callCavebotBridge("elfCavebotBridgeAddCurrent", kind)
  updateCavebotStatus()
end

function elfCavebotAddUseWith()
  local pos = getPlayerPosition()
  local defaultText = pos and ("ITEMID," .. pos.x .. "," .. pos.y .. "," .. pos.z) or "ITEMID,0,0,0"
  promptText(defaultText, "UseWith", function(value)
    callCavebotBridge("elfCavebotBridgeAddRaw", "usewith", value)
    updateCavebotStatus()
  end)
end

function elfCavebotAddLabel()
  promptText("start", "Label", function(value)
    callCavebotBridge("elfCavebotBridgeAddRaw", "label", value)
    updateCavebotStatus()
  end)
end

function elfCavebotEditSelected()
  callCavebotBridge("elfCavebotBridgeEditFocused")
  updateCavebotStatus()
end

function elfCavebotRemoveSelected()
  callCavebotBridge("elfCavebotBridgeRemoveFocused")
  updateCavebotStatus()
end

function elfCavebotMoveSelected(direction)
  callCavebotBridge("elfCavebotBridgeMoveFocused", direction)
  updateCavebotStatus()
end

function elfCavebotCenterPlayer()
  local map = getElfCavebotChild("cavebotMap")
  local pos = getPlayerPosition()
  if map and pos then
    map:setCameraPosition(pos)
    if map:getCameraPosition() then
      map:setCrossPosition({ x = pos.x, y = pos.y, z = pos.z })
    end
    map.elfCavebotCameraReady = true
  end
end

function elfCavebotFocusMapPosition(index)
  local actions = callCavebotBridge("elfCavebotBridgeActions") or {}
  local map = getElfCavebotChild("cavebotMap")
  if not map then return end
  for _, action in ipairs(actions) do
    if action.index == index then
      local pos = parseActionPosition(action)
      if pos then
        map:setCameraPosition(pos)
        map.elfCavebotCameraReady = true
      end
      return
    end
  end
end

if not modules then modules = {} end
if not modules.game_bot then modules.game_bot = {} end
modules.game_bot.elfCavebotOpen = elfCavebotOpen
modules.game_bot.elfCavebotClose = elfCavebotClose
modules.game_bot.elfCavebotRefresh = elfCavebotRefresh
modules.game_bot.elfCavebotStart = elfCavebotStart
modules.game_bot.elfCavebotStop = elfCavebotStop
modules.game_bot.elfCavebotToggleEditor = elfCavebotToggleEditor
modules.game_bot.elfCavebotToggleConfig = elfCavebotToggleConfig
modules.game_bot.elfCavebotSave = elfCavebotSave
modules.game_bot.elfCavebotSaveProfile = elfCavebotSaveProfile
modules.game_bot.elfCavebotLoadProfile = elfCavebotLoadProfile
modules.game_bot.elfCavebotDeleteProfile = elfCavebotDeleteProfile
modules.game_bot.elfCavebotToggleRecord = elfCavebotToggleRecord
modules.game_bot.elfCavebotAddAt = elfCavebotAddAt
modules.game_bot.elfCavebotAddCurrent = elfCavebotAddCurrent
modules.game_bot.elfCavebotAddUseWith = elfCavebotAddUseWith
modules.game_bot.elfCavebotAddLabel = elfCavebotAddLabel
modules.game_bot.elfCavebotEditSelected = elfCavebotEditSelected
modules.game_bot.elfCavebotRemoveSelected = elfCavebotRemoveSelected
modules.game_bot.elfCavebotMoveSelected = elfCavebotMoveSelected
modules.game_bot.elfCavebotCenterPlayer = elfCavebotCenterPlayer
modules.game_bot.elfCavebotFocusMapPosition = elfCavebotFocusMapPosition
