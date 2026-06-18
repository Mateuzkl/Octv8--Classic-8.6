elfCavebotWindow = nil
local cavebotStatusEvent = nil

local function getBotWindow()
  if botWindow then return botWindow end
  return g_ui.getRootWidget():recursiveGetChildById('botWindow')
end

local function getCaveTabPanel()
  local bw = getBotWindow()
  if not bw then return nil end
  local tabs = bw:recursiveGetChildById('botTabs')
  if not tabs then return nil end
  local tab = tabs:getTab("Cave")
  if tab then
    return tab.tabPanel
  end
  return nil
end

local function hideCaveTab()
  local bw = getBotWindow()
  if not bw then return end
  local tabs = bw:recursiveGetChildById('botTabs')
  if not tabs then return end
  local tab = tabs:getTab("Cave")
  if tab then
    tab:setVisible(false)
  end
end

local function showCaveTab()
  local bw = getBotWindow()
  if not bw then return end
  local tabs = bw:recursiveGetChildById('botTabs')
  if not tabs then return end
  local tab = tabs:getTab("Cave")
  if tab then
    tab:setVisible(true)
  end
end

local function getBotTabsContent()
  local bw = getBotWindow()
  if not bw then return nil end
  local tabs = bw:recursiveGetChildById('botTabs')
  if not tabs then return nil end
  return tabs.contentPanel or tabs:recursiveGetChildById('botPanel')
end

local function getElfCavebotChild(id)
  if not elfCavebotWindow or not elfCavebotWindow.recursiveGetChildById then
    return nil
  end
  return elfCavebotWindow:recursiveGetChildById(id)
end

local function callCavebotBridge(name)
  local fn = modules and modules.game_bot and modules.game_bot[name]
  if type(fn) ~= "function" then
    return nil
  end

  local ok, result = pcall(fn)
  if ok then
    return result
  end

  if g_logger and g_logger.error then
    g_logger.error("[ElfBot Cavebot] " .. name .. ": " .. tostring(result))
  end
  return nil
end

local function updateCavebotStatus()
  removeEvent(cavebotStatusEvent)
  cavebotStatusEvent = nil

  if not elfCavebotWindow or not elfCavebotWindow:isVisible() then
    return
  end

  local enabled = callCavebotBridge("elfCavebotBridgeIsOn") == true
  local profile = callCavebotBridge("elfCavebotBridgeProfile") or "-"
  local status = getElfCavebotChild("cavebotStatus")
  if status then
    status:setText((enabled and "On" or "Off") .. "  |  " .. profile)
    status:setColor(enabled and "#65d16e" or "#ff6b6b")
  end

  local startButton = getElfCavebotChild("startButton")
  if startButton and startButton.setEnabled then startButton:setEnabled(not enabled) end
  local stopButton = getElfCavebotChild("stopButton")
  if stopButton and stopButton.setEnabled then stopButton:setEnabled(enabled) end

  cavebotStatusEvent = scheduleEvent(updateCavebotStatus, 1000)
end

function elfCavebotInit()
  elfCavebotWindow = g_ui.displayUI('elfcavebot')
  elfCavebotWindow:disable()
  elfCavebotWindow:hide()
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
  local content = getElfCavebotChild("cavebotContent")
  if not content then return end
  local cavePanel = getCaveTabPanel()
  if cavePanel then
    cavePanel:setParent(content)
    cavePanel:setVisible(true)
    cavePanel:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    cavePanel:addAnchor(AnchorRight, 'parent', AnchorRight)
    cavePanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    cavePanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
  end
  hideCaveTab()
  elfCavebotWindow:enable()
  elfCavebotWindow:show()
  elfCavebotWindow:raise()
  elfCavebotWindow:focus()
  updateCavebotStatus()
end

function elfCavebotClose()
  removeEvent(cavebotStatusEvent)
  cavebotStatusEvent = nil

  local cavePanel = getCaveTabPanel()
  if cavePanel then
    local tabsContent = getBotTabsContent()
    if tabsContent then
      cavePanel:removeAnchor(AnchorLeft)
      cavePanel:removeAnchor(AnchorRight)
      cavePanel:removeAnchor(AnchorTop)
      cavePanel:removeAnchor(AnchorBottom)
      cavePanel:setParent(tabsContent)
    end
  end
  showCaveTab()
  if elfCavebotWindow then
    elfCavebotWindow:hide()
  end
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

if not modules then modules = {} end
if not modules.game_bot then modules.game_bot = {} end
modules.game_bot.elfCavebotOpen = elfCavebotOpen
modules.game_bot.elfCavebotClose = elfCavebotClose
modules.game_bot.elfCavebotStart = elfCavebotStart
modules.game_bot.elfCavebotStop = elfCavebotStop
modules.game_bot.elfCavebotToggleEditor = elfCavebotToggleEditor
modules.game_bot.elfCavebotToggleConfig = elfCavebotToggleConfig
modules.game_bot.elfCavebotSave = elfCavebotSave
