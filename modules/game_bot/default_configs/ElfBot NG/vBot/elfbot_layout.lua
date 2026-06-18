-- ElfBot style layout for IMPERIALBOT
-- This file only changes the interface/shortcuts. Existing bot systems are preserved.

setDefaultTab("Main")

ImperialElfBot = ImperialElfBot or {}

local function logError(text)
  if g_logger and g_logger.error then
    g_logger.error(text)
  elseif modules and modules.game_textmessage and modules.game_textmessage.displayGameMessage then
    modules.game_textmessage.displayGameMessage(text)
  end
end

local function logInfo(text)
  if g_logger and g_logger.info then
    g_logger.info(text)
  elseif modules and modules.game_textmessage and modules.game_textmessage.displayGameMessage then
    modules.game_textmessage.displayGameMessage(text)
  end
end

local function safeCall(name, callback)
  local ok, err = pcall(callback)
  if not ok then
    logError("[ImperialElfBot] " .. name .. ": " .. tostring(err))
  end
end

local function showWidget(widget)
  if not widget then return false end
  if widget.open then
    widget:open()
  elseif widget.show then
    widget:show()
  end
  if widget.raise then widget:raise() end
  if widget.focus then widget:focus() end
  return true
end

local function showMessage(text)
  if modules and modules.game_textmessage and modules.game_textmessage.displayGameMessage then
    modules.game_textmessage.displayGameMessage(text)
  else
    logInfo("[ImperialElfBot] " .. text)
  end
end

local function tryTab(tabName)
  if setDefaultTab then
    pcall(setDefaultTab, tabName)
  end
end

local function findWidgetByIdRecursive(widget, id)
  if not widget or not id then return nil end
  if widget.getId and widget:getId() == id then return widget end
  if widget.recursiveGetChildById then
    local found = widget:recursiveGetChildById(id)
    if found then return found end
  end
  if widget.getChildren then
    for _, child in pairs(widget:getChildren()) do
      local found = findWidgetByIdRecursive(child, id)
      if found then return found end
    end
  end
  return nil
end

local function findBotWindow()
  local gb = modules and modules.game_bot
  if botWindow then return botWindow end
  if gb and gb.botWindow then return gb.botWindow end
  local root = g_ui and g_ui.getRootWidget and g_ui.getRootWidget()
  if root then
    local byId = findWidgetByIdRecursive(root, 'botWindow')
    if byId then return byId end
  end
  if modules and modules.game_interface then
    local panels = {
      modules.game_interface.getLeftPanel and modules.game_interface.getLeftPanel(),
      modules.game_interface.getRightPanel and modules.game_interface.getRightPanel(),
      modules.game_interface.getRootPanel and modules.game_interface.getRootPanel()
    }
    for _, panel in ipairs(panels) do
      local byId = findWidgetByIdRecursive(panel, 'botWindow')
      if byId then return byId end
    end
  end
  return nil
end

local function selectBotTab(tabName)
  local bw = findBotWindow()
  if not bw then return false end
  local tabs = findWidgetByIdRecursive(bw, 'botTabs')
  if not tabs then return false end

  -- OTClientV8 TabBar costuma aceitar getTab/selectTab.
  if tabs.getTab and tabs.selectTab then
    local ok, tab = pcall(function() return tabs:getTab(tabName) end)
    if ok and tab then
      pcall(function() tabs:selectTab(tab) end)
      return true
    end
  end

  -- Fallback: procura o botao da aba pelo texto e clica nele.
  if tabs.getChildren then
    for _, child in pairs(tabs:getChildren()) do
      if child.getText and child:getText() == tabName then
        if child.onClick then child.onClick(child) end
        if child.focus then child:focus() end
        return true
      end
    end
  end
  return false
end

local function openMainBotTab(tabName)
  local bw = findBotWindow()
  if bw then
    if bw.open then bw:open() elseif bw.show then bw:show() end
    if bw.raise then bw:raise() end
    if bw.focus then bw:focus() end
  end

  -- setDefaultTab tambem ajuda em alguns scripts do vBot.
  tryTab(tabName)
  schedule(50, function() selectBotTab(tabName) end)
  schedule(200, function() selectBotTab(tabName) end)

  if botButton and botButton.setOn then
    botButton:setOn(true)
  end
  return true
end

local function findWidgetByText(parent, text)
  if not parent or not parent.getChildren then return nil end
  for _, child in pairs(parent:getChildren()) do
    if child.getText then
      local childText = child:getText()
      if childText == text then
        return child
      end
    end
    local found = findWidgetByText(child, text)
    if found then return found end
  end
  return nil
end

local function clickWidgetByText(text, tabName)
  if tabName then openMainBotTab(tabName) end
  local roots = {}
  if botWindow then table.insert(roots, botWindow) end
  if modules and modules.game_interface then
    if modules.game_interface.getRootPanel then table.insert(roots, modules.game_interface.getRootPanel()) end
    if modules.game_interface.getLeftPanel then table.insert(roots, modules.game_interface.getLeftPanel()) end
    if modules.game_interface.getRightPanel then table.insert(roots, modules.game_interface.getRightPanel()) end
  end
  if g_ui and g_ui.getRootWidget then table.insert(roots, g_ui.getRootWidget()) end

  for _, root in ipairs(roots) do
    local widget = findWidgetByText(root, text)
    if widget then
      if widget.onClick then
        widget.onClick(widget)
      elseif widget.callLuaField then
        widget:callLuaField('onClick')
      end
      return true
    end
  end
  return false
end

local function saveAll()
  safeCall("save heal", function() if vBotConfigSave then vBotConfigSave("heal") end end)
  safeCall("save attack", function() if vBotConfigSave then vBotConfigSave("atk") end end)
  safeCall("save supply", function() if vBotConfigSave then vBotConfigSave("supply") end end)
  safeCall("save cavebot", function() if CaveBot and CaveBot.save then CaveBot.save() end end)
  safeCall("save targetbot", function() if TargetBot and TargetBot.save then TargetBot.save() end end)
  showMessage("ImperialBot: configuracoes salvas.")
end

if modules and modules.game_bot then
  local function elfCavebotActionList()
    if CaveBotList then
      local ok, list = pcall(CaveBotList)
      if ok then return list end
    end
    if CaveBot and CaveBot.actionList then
      return CaveBot.actionList
    end
    return nil
  end

  local function elfCavebotCurrentPosition()
    local player = g_game and g_game.getLocalPlayer and g_game.getLocalPlayer()
    if player then
      return player:getPosition()
    end
    if pos then
      return pos()
    end
    return nil
  end

  local function elfCavebotPositionValue(position, exact)
    if not position then return nil end
    local value = position.x .. "," .. position.y .. "," .. position.z
    if exact then
      value = value .. ",0"
    end
    return value
  end

  local function elfCavebotCollectData()
    local data = {}
    local list = elfCavebotActionList()
    if list then
      for _, child in ipairs(list:getChildren()) do
        if child.action and child.value then
          table.insert(data, { child.action, child.value })
        end
      end
    end

    if CaveBot and CaveBot.Config and CaveBot.Config.save then
      table.insert(data, { "config", json.encode(CaveBot.Config.save()) })
    end

    local extensionData = {}
    if CaveBot and CaveBot.Extensions then
      for extension, callbacks in pairs(CaveBot.Extensions) do
        if callbacks.onSave then
          local extData = callbacks.onSave()
          if type(extData) == "table" then
            extensionData[extension] = extData
          end
        end
      end
    end
    table.insert(data, { "extensions", json.encode(extensionData, 2) })

    return data
  end

  local function elfCavebotApplyData(name, enabled, data)
    if type(storage._configs) ~= "table" then
      storage._configs = {}
    end
    if type(storage._configs.cavebot_configs) ~= "table" then
      storage._configs.cavebot_configs = {}
    end

    storage._configs.cavebot_configs.selected = name
    storage._configs.cavebot_configs.enabled = enabled == true

    if CaveBot and CaveBot.setOff then
      pcall(CaveBot.setOff)
    end

    local list = elfCavebotActionList()
    if list then
      list:destroyChildren()
    end

    local cavebotConfig = nil
    local extensionConfig = {}
    for _, entry in ipairs(data or {}) do
      if type(entry) == "table" and #entry == 2 then
        if entry[1] == "config" then
          local ok, decoded = pcall(function() return json.decode(entry[2]) end)
          if ok and type(decoded) == "table" then
            cavebotConfig = decoded
          end
        elseif entry[1] == "extensions" then
          local ok, decoded = pcall(function() return json.decode(entry[2]) end)
          if ok and type(decoded) == "table" then
            extensionConfig = decoded
          end
        elseif CaveBot and CaveBot.addAction then
          pcall(CaveBot.addAction, entry[1], entry[2])
        end
      end
    end

    if CaveBot and CaveBot.Config and CaveBot.Config.onConfigChange then
      pcall(CaveBot.Config.onConfigChange, name, enabled == true, cavebotConfig)
    end

    if CaveBot and CaveBot.Extensions then
      for extension, callbacks in pairs(CaveBot.Extensions) do
        if callbacks.onConfigChange then
          pcall(callbacks.onConfigChange, name, enabled == true, extensionConfig[extension])
        end
      end
    end

    if CaveBot and CaveBot.resetWalking then
      pcall(CaveBot.resetWalking)
    end

    return true
  end

  local function elfCavebotValidProfileName(name)
    if type(name) ~= "string" then return nil end
    name = name:gsub("%s+", "_")
    if name:len() == 0 or name:len() >= 30 or name:find("/") or name:find("\\") then
      return nil
    end
    return name
  end

  modules.game_bot.elfCavebotBridgeIsOn = function()
    if not CaveBot or not CaveBot.isOn then
      return false
    end
    local ok, result = pcall(CaveBot.isOn)
    return ok and result == true
  end

  modules.game_bot.elfCavebotBridgeProfile = function()
    if CaveBot and CaveBot.getCurrentProfile then
      local ok, result = pcall(CaveBot.getCurrentProfile)
      if ok and result then
        return tostring(result)
      end
    end
    return "-"
  end

  modules.game_bot.elfCavebotBridgeSetOn = function()
    if CaveBot and CaveBot.setOn then
      pcall(CaveBot.setOn)
    end
  end

  modules.game_bot.elfCavebotBridgeSetOff = function()
    if CaveBot and CaveBot.setOff then
      pcall(CaveBot.setOff)
    end
  end

  modules.game_bot.elfCavebotBridgeToggleEditor = function()
    if not CaveBot or not CaveBot.Editor then return end
    local editor = CaveBot.Editor
    local visible = editor.ui and editor.ui.isVisible and editor.ui:isVisible()
    if visible and editor.hide then
      pcall(editor.hide)
    elseif editor.show then
      pcall(editor.show)
    end
  end

  modules.game_bot.elfCavebotBridgeToggleConfig = function()
    if not CaveBot or not CaveBot.Config then return end
    local config = CaveBot.Config
    local visible = config.ui and config.ui.isVisible and config.ui:isVisible()
    if visible and config.hide then
      pcall(config.hide)
    elseif config.show then
      pcall(config.show)
    end
  end

  modules.game_bot.elfCavebotBridgeSave = function()
    if CaveBot and CaveBot.save then
      pcall(CaveBot.save)
    end
  end

  modules.game_bot.elfCavebotBridgeRecorderIsOn = function()
    if CaveBot and CaveBot.Recorder and CaveBot.Recorder.isOn then
      local ok, result = pcall(CaveBot.Recorder.isOn)
      return ok and result == true
    end
    return false
  end

  modules.game_bot.elfCavebotBridgeToggleRecorder = function()
    if not CaveBot or not CaveBot.Recorder then return false end
    if CaveBot.Recorder.isOn and CaveBot.Recorder.isOn() then
      if CaveBot.Recorder.disable then
        return pcall(CaveBot.Recorder.disable)
      end
    elseif CaveBot.Recorder.enable then
      return pcall(CaveBot.Recorder.enable)
    end
    return false
  end

  modules.game_bot.elfCavebotBridgeProfiles = function()
    local profiles = {}
    if Config and Config.list then
      local ok, list = pcall(Config.list, "cavebot_configs")
      if ok and type(list) == "table" then
        profiles = list
        table.sort(profiles)
      end
    end

    local selected = nil
    if storage._configs and storage._configs.cavebot_configs then
      selected = storage._configs.cavebot_configs.selected
    end

    return {
      profiles = profiles,
      selected = selected
    }
  end

  modules.game_bot.elfCavebotBridgeActions = function()
    local result = {}
    local list = elfCavebotActionList()
    if not list then return result end

    local focused = list:getFocusedChild()
    for index, child in ipairs(list:getChildren()) do
      table.insert(result, {
        index = index,
        action = child.action or "",
        value = child.value or "",
        text = child.getText and child:getText() or "",
        focused = focused == child
      })
    end
    return result
  end

  modules.game_bot.elfCavebotBridgeFocusAction = function(index)
    local list = elfCavebotActionList()
    if not list then return false end
    local child = list:getChildByIndex(tonumber(index) or 0)
    if not child then return false end
    list:focusChild(child)
    list:ensureChildVisible(child)
    return true
  end

  modules.game_bot.elfCavebotBridgeAddRaw = function(action, value)
    if not CaveBot or not CaveBot.addAction then return false end
    local widget = CaveBot.addAction(action, value, true)
    if widget and CaveBot.save then
      CaveBot.save()
    end
    return widget ~= nil
  end

  modules.game_bot.elfCavebotBridgeAddAt = function(kind, position, extra)
    if not position then return false end

    if kind == "goto" then
      return modules.game_bot.elfCavebotBridgeAddRaw("goto", elfCavebotPositionValue(position, false))
    elseif kind == "gotoExact" then
      return modules.game_bot.elfCavebotBridgeAddRaw("goto", elfCavebotPositionValue(position, true))
    elseif kind == "use" then
      return modules.game_bot.elfCavebotBridgeAddRaw("use", elfCavebotPositionValue(position, false))
    elseif kind == "usewith" and extra then
      return modules.game_bot.elfCavebotBridgeAddRaw("usewith", extra .. "," .. elfCavebotPositionValue(position, false))
    end

    return false
  end

  modules.game_bot.elfCavebotBridgeAddCurrent = function(kind)
    return modules.game_bot.elfCavebotBridgeAddAt(kind, elfCavebotCurrentPosition())
  end

  modules.game_bot.elfCavebotBridgeEditFocused = function()
    local list = elfCavebotActionList()
    local action = list and list:getFocusedChild()
    if action and action.onDoubleClick then
      action:onDoubleClick()
      return true
    end
    return false
  end

  modules.game_bot.elfCavebotBridgeRemoveFocused = function()
    local list = elfCavebotActionList()
    local action = list and list:getFocusedChild()
    if not action then return false end
    action:destroy()
    if CaveBot and CaveBot.save then CaveBot.save() end
    return true
  end

  modules.game_bot.elfCavebotBridgeMoveFocused = function(direction)
    local list = elfCavebotActionList()
    local action = list and list:getFocusedChild()
    if not action then return false end
    local index = list:getChildIndex(action)
    local nextIndex = index + (tonumber(direction) or 0)
    if nextIndex < 1 or nextIndex > list:getChildCount() then
      return false
    end
    list:moveChildToIndex(action, nextIndex)
    list:focusChild(action)
    list:ensureChildVisible(action)
    if CaveBot and CaveBot.save then CaveBot.save() end
    return true
  end

  modules.game_bot.elfCavebotBridgeSaveProfile = function(name)
    name = elfCavebotValidProfileName(name)
    if not name or not Config or not Config.save then return false end
    if type(storage._configs) ~= "table" then storage._configs = {} end
    if type(storage._configs.cavebot_configs) ~= "table" then storage._configs.cavebot_configs = {} end
    storage._configs.cavebot_configs.selected = name
    Config.save("cavebot_configs", name, elfCavebotCollectData(), "cfg")
    return true
  end

  modules.game_bot.elfCavebotBridgeLoadProfile = function(name)
    name = elfCavebotValidProfileName(name)
    if not name or not Config or not Config.load then return false end
    local data = Config.load("cavebot_configs", name)
    if type(data) ~= "table" then return false end
    return elfCavebotApplyData(name, false, data)
  end

  modules.game_bot.elfCavebotBridgeDeleteProfile = function(name)
    name = elfCavebotValidProfileName(name)
    if not name or not Config or not Config.remove then return false end
    local removed = Config.remove("cavebot_configs", name)
    if not removed then return false end

    if storage._configs and storage._configs.cavebot_configs and storage._configs.cavebot_configs.selected == name then
      storage._configs.cavebot_configs.selected = nil
      local profiles = Config.list("cavebot_configs")
      table.sort(profiles)
      if #profiles > 0 then
        local data = Config.load("cavebot_configs", profiles[1])
        elfCavebotApplyData(profiles[1], false, data)
      else
        local list = elfCavebotActionList()
        if list then list:destroyChildren() end
      end
    end

    return true
  end
end


local function elfNowSeconds()
  if g_clock and g_clock.seconds then
    return g_clock.seconds()
  end
  if os and os.time then
    return os.time()
  end
  return 0
end

local rootWidget = g_ui.getRootWidget()
if rootWidget then
  local old = rootWidget:recursiveGetChildById("imperialElfBotWindow")
  if old then old:destroy() end

  local elfWindow = UI.createWindow("ImperialElfBotWindow", rootWidget)
  elfWindow:setId("imperialElfBotWindow")
  elfWindow:hide()
  ImperialElfBot.window = elfWindow

  local elfStartExp = 0
  local elfStartTime = 0

  local function formatExpHour(value)
    value = tonumber(value) or 0
    if value >= 1000000 then
      return string.format("%.1fkk", value / 1000000)
    elseif value >= 1000 then
      return string.format("%.1fk", value / 1000)
    end
    return tostring(math.floor(value))
  end

  local function getExpHour()
    if not g_game or not g_game.isOnline or not g_game.isOnline() then
      return 0
    end

    local player = g_game.getLocalPlayer and g_game.getLocalPlayer()
    if not player or not player.getExperience then
      return 0
    end

    local now = elfNowSeconds()
    local exp = player:getExperience() or 0

    if elfStartTime == 0 or elfStartExp == 0 or exp < elfStartExp then
      elfStartExp = exp
      elfStartTime = now
      return 0
    end

    local elapsed = now - elfStartTime
    if elapsed <= 0 then
      return 0
    end

    return math.floor(((exp - elfStartExp) * 3600) / elapsed)
  end

  local function getPing()
    if g_game and g_game.getPing then
      return tonumber(g_game.getPing()) or 0
    end
    return 0
  end

  local function updateElfTitle()
    if not elfWindow or elfWindow:isDestroyed() then
      return
    end

    elfWindow:setText("ElfBot NG 4.5.9 - Startup - " .. getPing() .. " ms - " .. formatExpHour(getExpHour()) .. " exp/hour")
    ImperialElfBot.statusEvent = schedule(1000, updateElfTitle)
  end

  if ImperialElfBot.statusEvent then
    removeEvent(ImperialElfBot.statusEvent)
    ImperialElfBot.statusEvent = nil
  end

  updateElfTitle()

  ImperialElfBot.show = function()
    showWidget(elfWindow)
  end

  ImperialElfBot.hide = function()
    if elfWindow then elfWindow:hide() end
  end

  ImperialElfBot.toggle = function()
    if elfWindow:isVisible() then
      elfWindow:hide()
    else
      showWidget(elfWindow)
    end
  end

  ImperialElfBot.locked = false

  if elfWindow.closeButton then
    elfWindow.closeButton.onClick = function()
      elfWindow:hide()
      -- nao desliga o bot; o botao game_bot/Bot reabre a janela compacta
      if botButton and botButton.setOn then
        botButton:setOn(false)
      end
    end
  end

  if elfWindow.minimizeButton then
    elfWindow.minimizeButton.onClick = function()
      elfWindow:hide()
    end
  end

  if elfWindow.lockButton then
    elfWindow.lockButton.onClick = function()
      ImperialElfBot.locked = not ImperialElfBot.locked
      elfWindow.lockButton:setText(ImperialElfBot.locked and "U" or "L")
      if elfWindow.setDraggable then
        elfWindow:setDraggable(not ImperialElfBot.locked)
      elseif elfWindow.setPhantom then
        -- fallback only changes visual state; some OTC builds do not expose setDraggable to Lua
      end
      showMessage(ImperialElfBot.locked and "ElfBot NG: janela travada." or "ElfBot NG: janela destravada.")
    end
  end

  elfWindow.healingButton.onClick = function()
    safeCall("Healing", function()
      if HealBot and HealBot.show then
        HealBot.show()
      else
        tryTab("HP")
      end
    end)
  end

  elfWindow.aimbotButton.onClick = function()
    safeCall("Aimbot", function()
      if AttackBot and AttackBot.show then
        AttackBot.show()
      else
        tryTab("Main")
      end
    end)
  end

  elfWindow.listsButton.onClick = function()
    safeCall("Lists", function()
      if ImperialElfBot_OpenPlayerLists then
        ImperialElfBot_OpenPlayerLists()
      elseif ListWindow then
        ListWindow:show()
        ListWindow:raise()
        ListWindow:focus()
      else
        tryTab("Main")
      end
    end)
  end

  elfWindow.hudButton.onClick = function()
    safeCall("HUD", function()
      if ImperialElfBot_OpenAnalyzer then
        ImperialElfBot_OpenAnalyzer()
      else
        tryTab("Main")
      end
    end)
  end

  for i = 1, 5 do
    local btn = elfWindow["profile" .. i .. "Button"]
    if btn then
      btn.onClick = function()
        safeCall("Profile " .. i, function()
          if HealBot and HealBot.setActiveProfile then HealBot.setActiveProfile(i) end
          if AttackBot and AttackBot.setActiveProfile then AttackBot.setActiveProfile(i) end
          showMessage("ImperialBot: profile " .. i .. " selecionado.")
        end)
      end
    end
  end

  elfWindow.extrasButton.onClick = function()
    safeCall("Extras", function()
      if extrasWindow then showWidget(extrasWindow) else tryTab("Tools") end
    end)
  end

  elfWindow.hotkeysButton.onClick = function()
    safeCall("Hotkeys", function()
      if elfHotkeysOpen then
        elfHotkeysOpen()
      elseif modules.game_bot and modules.game_bot.elfHotkeysOpen then
        modules.game_bot.elfHotkeysOpen()
      else
        showMessage("Hotkeys ElfBot ainda nao carregou.")
      end
    end)
  end

  elfWindow.shortkeysButton.onClick = function()
    safeCall("Shortkeys", function()
      UI.MultilineEditorWindow(storage.ingame_shortkeys or "", {
        title = "Shortkeys editor",
        description = "Area para shortkeys/scripts rapidos customizados. Ao salvar, o bot sera recarregado."
      }, function(text)
        storage.ingame_shortkeys = text
        reload()
      end)
    end)
  end

  elfWindow.reconnectButton.onClick = function()
    safeCall("Reconnect", function()
      tryTab("Tools")
    end)
  end

  elfWindow.saveButton.onClick = function()
    saveAll()
  end

  elfWindow.customButton.onClick = function()
    safeCall("Custom", function()
      if fbnWindows then
        showWidget(fbnWindows)
      elseif extrasWindow then
        showWidget(extrasWindow)
      else
        tryTab("Main")
      end
    end)
  end

  elfWindow.cavebotButton.onClick = function()
    safeCall("Cavebot", function()
      if elfCavebotOpen then
        elfCavebotOpen()
      elseif modules and modules.game_bot and modules.game_bot.elfCavebotOpen then
        modules.game_bot.elfCavebotOpen()
      else
        openMainBotTab("Cave")
      end
    end)
  end

  elfWindow.navigationButton.onClick = function()
    safeCall("Navigation", function()
      if ImperialElfBot_OpenNavigation then
        ImperialElfBot_OpenNavigation()
      elseif NovoFollowController and NovoFollowController.open then
        NovoFollowController.open()
      elseif NovoFollowController and NovoFollowController.show then
        NovoFollowController.show()
      else
        tryTab("Main")
        showMessage("Navigation ainda nao carregou. Abra pelo botao Navigation na aba Main.")
      end
    end)
  end

  elfWindow.linksButton.onClick = function()
    safeCall("Links", function()
      tryTab("Tools")
    end)
  end

  elfWindow.creatureSpyButton.onClick = function()
    safeCall("Creature Spy", function()
      showMessage("Creature Spy ativo pelo script spy_level.lua: use '-' e '=' para trocar o andar visivel.")
    end)
  end

  elfWindow.loadButton.onClick = function()
    safeCall("Load", function()
      if modules and modules.game_bot and modules.game_bot.reload then
        modules.game_bot.reload()
      else
        reload()
      end
    end)
  end

  elfWindow.helpButton.onClick = function()
    safeCall("Help", function()
      showMessage("ImperialBot ElfLayout: Healing=HealBot, Aimbot=AttackBot, HUD=Analyzer, Cavebot/Targeting usam os sistemas ja existentes.")
    end)
  end

  elfWindow.targetingButton.onClick = function()
    safeCall("Targeting", function()
      if TargetBot and TargetBot.Creature and TargetBot.Creature.edit then
        TargetBot.Creature.edit(nil, function(newConfig)
          if newConfig then
            TargetBot.Creature.addConfig(newConfig, true)
            TargetBot.save()
          end
        end)
      else
        tryTab("Target")
      end
    end)
  end

  elfWindow.proxyButton.onClick = function()
    safeCall("Proxy", function()
      showMessage("Proxy nao existe nesse pack do IMPERIALBOT. Botao mantido apenas para layout ElfBot.")
    end)
  end

  elfWindow.iconsButton.onClick = function()
    safeCall("Icons", function()
      if ImperialElfBot_OpenIcons then
        ImperialElfBot_OpenIcons()
      elseif PainelDeIconesController and PainelDeIconesController.open then
        PainelDeIconesController.open()
      elseif PainelDeIconesController and PainelDeIconesController.openButton and PainelDeIconesController.openButton.onClick then
        PainelDeIconesController.openButton.onClick(PainelDeIconesController.openButton)
      else
        tryTab("Main")
        showMessage("Painel de Icones ainda nao carregou. Abra pelo botao Painel de Icones na aba Main.")
      end
    end)
  end

  if elfWindow.pvpButton then
    elfWindow.pvpButton.onClick = function()
      safeCall("PVP", function()
        if PvpSystemController and PvpSystemController.open then
          PvpSystemController.open()
        elseif PvpSystemController and PvpSystemController.show then
          PvpSystemController.show()
        else
          showMessage("PVP ainda nao carregou. Verifique se pvp.lua esta no perfil.")
        end
      end)
    end
  end

  UI.Button("ElfBot NG Layout", function()
    ImperialElfBot.toggle()
  end)
  UI.Separator()

  if storage.imperialElfBotAutoOpen == nil then
    storage.imperialElfBotAutoOpen = true
  end
  if storage.imperialElfBotAutoOpen then
    schedule(500, function()
      if ImperialElfBot and ImperialElfBot.show then ImperialElfBot.show() end
    end)
  end
end
