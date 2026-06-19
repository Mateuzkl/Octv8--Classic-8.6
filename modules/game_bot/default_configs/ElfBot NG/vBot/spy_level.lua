local keyUp = "="
local keyDown = "-"

setDefaultTab("Tools")

if CreatureSpyController and CreatureSpyController.destroy then
  pcall(CreatureSpyController.destroy)
end

g_ui.loadUIFromString([[
CreatureSpyRow < UIWidget
  height: 16
  background-color: alpha
  text-offset: 4 1
  text-align: left
  font: verdana-11px-rounded
  focusable: false

CreatureSpyWindow < MainWindow
  text: Creature Spy
  size: 555 220
  @onEscape: self:hide()

  Label
    id: info
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 18
    text-align: center
    font: verdana-11px-rounded
    text: Creature Spy

  FlatPanel
    id: listFrame
    anchors.top: info.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    margin-top: 4
    margin-bottom: 8
    padding: 2

    ScrollablePanel
      id: creatureList
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: creatureScroll.left
      anchors.bottom: parent.bottom
      vertical-scrollbar: creatureScroll
      layout:
        type: verticalBox
        spacing: 0

    VerticalScrollBar
      id: creatureScroll
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      step: 16
      pixels-scroll: true

  Button
    id: closeButton
    !text: tr('Close')
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    size: 60 21
]])

local lockedLevel = pos().z
local creatureSpyWindow
local creatureSpyList
local creatureSpyInfo
local rowWidgets = {}
local lastSignature = ""

local function safeValue(callback, fallback)
  local ok, value = pcall(callback)
  if ok and value ~= nil then
    return value
  end
  return fallback
end

local function getLocalPlayer()
  return safeValue(function() return g_game.getLocalPlayer() end, nil)
end

local function getMapPanel()
  if not modules or not modules.game_interface or not modules.game_interface.getMapPanel then
    return nil
  end
  return safeValue(function() return modules.game_interface.getMapPanel() end, nil)
end

local function formatSigned(value)
  value = tonumber(value) or 0
  if value >= 0 then
    return "+" .. value
  end
  return tostring(value)
end

local function creaturePosition(creature)
  return safeValue(function() return creature:getPosition() end, nil)
end

local function creatureName(creature)
  return tostring(safeValue(function() return creature:getName() end, "Unknown"))
end

local function creatureHealth(creature)
  local health = tonumber(safeValue(function() return creature:getHealthPercent() end, 100)) or 100
  if health < 0 then
    return 0
  elseif health > 100 then
    return 100
  end
  return math.floor(health)
end

local function creatureSpeed(creature)
  return tonumber(safeValue(function() return creature:getSpeed() end, 0)) or 0
end

local function isLocalCreature(creature, player)
  if creature and creature.isLocalPlayer then
    return safeValue(function() return creature:isLocalPlayer() end, false)
  end
  return player and creature == player
end

local function getVisibleSpectators()
  if type(getSpectators) == "function" then
    return safeValue(function() return getSpectators(true) end, {}) or {}
  end

  local player = getLocalPlayer()
  if player and g_map and g_map.getSpectators then
    return safeValue(function() return g_map.getSpectators(player:getPosition(), true) end, {}) or {}
  end

  return {}
end

local function buildRows()
  local player = getLocalPlayer()
  local playerPos = player and creaturePosition(player) or pos()
  local rows = {
    {
      text = string.format("***Level %s***", tostring(lockedLevel)),
      header = true
    }
  }

  if not playerPos then
    table.insert(rows, { text = "No local player." })
    return rows, 0
  end

  local entries = {}
  for _, creature in ipairs(getVisibleSpectators()) do
    local cpos = creaturePosition(creature)
    if cpos and cpos.z == lockedLevel then
      table.insert(entries, {
        name = creatureName(creature),
        dx = (cpos.x or playerPos.x) - playerPos.x,
        dy = (cpos.y or playerPos.y) - playerPos.y,
        health = creatureHealth(creature),
        speed = creatureSpeed(creature),
        localPlayer = isLocalCreature(creature, player)
      })
    end
  end

  table.sort(entries, function(a, b)
    if a.localPlayer ~= b.localPlayer then
      return not a.localPlayer
    end
    local da = math.abs(a.dx) + math.abs(a.dy)
    local db = math.abs(b.dx) + math.abs(b.dy)
    if da ~= db then
      return da < db
    end
    return a.name:lower() < b.name:lower()
  end)

  for _, entry in ipairs(entries) do
    table.insert(rows, {
      text = string.format("%-18s Pos: (%s,%s)  Health: %3d%%  Speed: %s",
        entry.name,
        formatSigned(entry.dx),
        formatSigned(entry.dy),
        entry.health,
        tostring(entry.speed)),
      localPlayer = entry.localPlayer
    })
  end

  if #rows == 1 then
    table.insert(rows, { text = "No creatures visible on this level." })
  end

  return rows, #entries
end

local function createCreatureSpyWindow()
  if creatureSpyWindow then
    return creatureSpyWindow
  end

  local ok, window = pcall(function()
    return UI.createWindow("CreatureSpyWindow", rootWidget)
  end)
  if not ok or not window then
    window = UI.createWindow("CreatureSpyWindow")
  end

  creatureSpyWindow = window
  creatureSpyList = window:recursiveGetChildById("creatureList")
  creatureSpyInfo = window:recursiveGetChildById("info")
  local closeButton = window:recursiveGetChildById("closeButton")

  if closeButton then
    closeButton.onClick = function()
      window:hide()
    end
  end

  window:hide()
  return window
end

local function clearUnusedRows(count)
  while #rowWidgets > count do
    local widget = rowWidgets[#rowWidgets]
    table.remove(rowWidgets)
    if widget then
      widget:destroy()
    end
  end
end

local function updateCreatureSpy(force)
  local window = createCreatureSpyWindow()
  if not window or not creatureSpyList then
    return
  end

  local rows, creatureCount = buildRows()
  local signatureParts = {}
  for index, row in ipairs(rows) do
    signatureParts[index] = row.text .. tostring(row.localPlayer == true)
  end
  local signature = table.concat(signatureParts, "\n")
  if not force and signature == lastSignature then
    return
  end
  lastSignature = signature

  if creatureSpyInfo then
    creatureSpyInfo:setText("Visible level: " .. tostring(lockedLevel) .. "    " .. tostring(creatureCount or 0) .. " creature(s)")
  end

  clearUnusedRows(#rows)
  for index, row in ipairs(rows) do
    local widget = rowWidgets[index]
    if not widget then
      widget = UI.createWidget("CreatureSpyRow", creatureSpyList)
      rowWidgets[index] = widget
    end

    widget:setText(row.text)
    if row.header then
      widget:setColor("#d7d7d7")
      if widget.setBackgroundColor then widget:setBackgroundColor("#00000000") end
    elseif row.localPlayer then
      widget:setColor("#ffffff")
      if widget.setBackgroundColor then widget:setBackgroundColor("#00000077") end
    else
      widget:setColor("#d7d7d7")
      if widget.setBackgroundColor then widget:setBackgroundColor("#00000000") end
    end
  end
end

local function openCreatureSpy()
  local window = createCreatureSpyWindow()
  if not window then
    return
  end

  updateCreatureSpy(true)
  window:show()
  window:raise()
  window:focus()
end

local function lockVisibleLevel(level)
  lockedLevel = level
  local mapPanel = getMapPanel()
  if mapPanel and mapPanel.lockVisibleFloor then
    mapPanel:lockVisibleFloor(lockedLevel)
  end
  updateCreatureSpy(true)
end

CreatureSpyController = {
  open = openCreatureSpy,
  show = openCreatureSpy,
  update = function() updateCreatureSpy(true) end,
  close = function()
    if creatureSpyWindow then
      creatureSpyWindow:hide()
    end
  end,
  destroy = function()
    if creatureSpyWindow then
      creatureSpyWindow:destroy()
    end
    creatureSpyWindow = nil
    creatureSpyList = nil
    creatureSpyInfo = nil
    rowWidgets = {}
    lastSignature = ""
  end
}

ImperialElfBot_OpenCreatureSpy = openCreatureSpy

onPlayerPositionChange(function()
  lockedLevel = pos().z
  lastSignature = ""

  local mapPanel = getMapPanel()
  if mapPanel and mapPanel.unlockVisibleFloor then
    mapPanel:unlockVisibleFloor()
  end

  if creatureSpyWindow and (not creatureSpyWindow.isVisible or creatureSpyWindow:isVisible()) then
    updateCreatureSpy(true)
  end
end)

onKeyPress(function(keys)
  if keys == keyDown then
    lockVisibleLevel(lockedLevel + 1)
  elseif keys == keyUp then
    lockVisibleLevel(lockedLevel - 1)
  end
end)

macro(500, function()
  if creatureSpyWindow and (not creatureSpyWindow.isVisible or creatureSpyWindow:isVisible()) then
    updateCreatureSpy(false)
  end
end)
