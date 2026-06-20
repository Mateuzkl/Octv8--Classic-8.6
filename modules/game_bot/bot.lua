botWindow = nil
botButton = nil
contentsPanel = nil
editWindow = nil

local checkEvent = nil

local botStorage = {}
local botStorageFile = nil
local botWebSockets = {}
local botMessages = nil
local botTabs = nil
local botExecutor = nil

local configList = nil
local enableButton = nil
local executeEvent = nil
local statusLabel = nil

local configManagerUrl = "http://otclient.ovh/configs.php"
local defaultElfBotConfig = "ElfBot NG"

local function isElfBotNgConfig(configName)
  return configName == "ElfBot NG" or configName == "IMPERIALBOT"
end

local function isElfBotManualProfileLoad()
  return modules
    and modules.game_bot
    and (modules.game_bot.elfbotPendingManualProfileLoad == true or modules.game_bot.elfbotProfileLoadedThisSession == true)
end

local function getBotSettingsIndex()
  if not g_game or not g_game.getCharacterName or not g_game.getClientVersion then
    return nil
  end

  local characterName = g_game.getCharacterName()
  if not characterName or characterName:len() == 0 then
    return nil
  end

  return characterName .. "_" .. g_game.getClientVersion()
end

local function ensureBotSettings(settings, index)
  settings[index] = settings[index] or {
    enabled = false,
    config = defaultElfBotConfig
  }

  if settings[index].config == nil or settings[index].config == "" then
    settings[index].config = defaultElfBotConfig
  end

  return settings[index]
end

local function forceBotOffForLogin()
  local index = getBotSettingsIndex()
  if not index then
    return
  end

  local settings = g_settings.getNode('bot') or {}
  local entry = ensureBotSettings(settings, index)
  entry.enabled = false
  g_settings.setNode('bot', settings)
  g_settings.save()
end

local elfBotUserDataDirs = {
  storage = true,
  vBot_configs = true,
  cavebot_configs = true,
  targetbot_configs = true,
  elfbot_profiles = true
}

function init()
  dofile("executor")
  local hkOk, hkErr = pcall(function() dofile("elfbot_hotkeys") end)
  if not hkOk then
    if g_logger and g_logger.error then
      g_logger.error("[ElfBot Hotkeys] Falha ao carregar: " .. tostring(hkErr))
    end
  end
  local cbOk, cbErr = pcall(function() dofile("elfbot_cavebot") end)
  if not cbOk and g_logger and g_logger.error then
    g_logger.error("[ElfBot Cavebot] Falha ao carregar: " .. tostring(cbErr))
  end

  g_ui.importStyle("ui/basic.otui")
  g_ui.importStyle("ui/panels.otui")
  g_ui.importStyle("ui/config.otui")
  g_ui.importStyle("ui/icons.otui")
  g_ui.importStyle("ui/container.otui")

  connect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  initCallbacks()

  botButton = modules.client_topmenu.addRightGameToggleButton('botButton', tr('Bot'), '/images/topbuttons/bot', toggle, false, 99999)
  botButton:setOn(false)
  botButton:hide()

  botWindow = g_ui.loadUI('bot', modules.game_interface.getLeftPanel())
  botWindow:setup()
  if modules and modules.game_bot then
    modules.game_bot.botWindow = botWindow
    modules.game_bot.reload = refresh
    modules.game_bot.showElfBotNgWindow = showElfBotNgWindow
  end

  contentsPanel = botWindow.contentsPanel
  configList = contentsPanel.config
  enableButton = contentsPanel.enableButton
  statusLabel = contentsPanel.statusLabel
  botMessages = contentsPanel.messages
  botTabs = contentsPanel.botTabs
  botTabs:setContentWidget(contentsPanel.botPanel)

  editWindow = g_ui.displayUI('edit')
  editWindow:hide()

  if elfHotkeysInit then
    local ok, err = pcall(elfHotkeysInit)
    if not ok and g_logger and g_logger.error then
      g_logger.error("[ElfBot Hotkeys] Falha no init: " .. tostring(err))
    end
  end

  if elfCavebotInit then
    local ok, err = pcall(elfCavebotInit)
    if not ok and g_logger and g_logger.error then
      g_logger.error("[ElfBot Cavebot] Falha no init: " .. tostring(err))
    end
  end

  if g_game.isOnline() then
    clear()
    online()
  end
end

function terminate()
  save()
  clear()

  disconnect(g_game, {
    onGameStart = online,
    onGameEnd = offline,
  })

  terminateCallbacks()
  editWindow:destroy()

  if elfHotkeysTerminate then
    pcall(elfHotkeysTerminate)
  end

  if elfCavebotTerminate then
    pcall(elfCavebotTerminate)
  end

  botWindow:destroy()
  botButton:destroy()
end

function clear()
  botExecutor = nil
  removeEvent(checkEvent)

  -- optimization, callback is not used when not needed
  g_game.enableTileThingLuaCallback(false)

  botTabs:clearTabs()
  botTabs:setOn(false)

  botMessages:destroyChildren()
  botMessages:updateLayout()

  for i, socket in pairs(botWebSockets) do
    g_http.cancel(socket)
    botWebSockets[i] = nil
  end

  for i, widget in pairs(g_ui.getRootWidget():getChildren()) do
    if widget.botWidget then
      widget:destroy()
    end
  end
  for i, widget in pairs(modules.game_interface.gameMapPanel:getChildren()) do
    if widget.botWidget then
      widget:destroy()
    end
  end
  for _, widget in pairs({modules.game_interface.getRightPanel(), modules.game_interface.getLeftPanel()}) do
    for i, child in pairs(widget:getChildren()) do
      if child.botWidget then
        child:destroy()
      end
    end
  end

  local gameMapPanel = modules.game_interface.getMapPanel()
  if gameMapPanel then
    gameMapPanel:unlockVisibleFloor()
  end

  if g_sounds then
    g_sounds.getChannel(SoundChannels.Bot):stop()
  end
end


function refresh()
  if not g_game.isOnline() then return end
  save()
  clear()

  -- create bot dir
  if not g_resources.directoryExists("/bot") then
    g_resources.makeDir("/bot")
    if not g_resources.directoryExists("/bot") then
      return onError("Can't create bot directory in " .. g_resources.getWriteDir())
    end
  end

  -- get list of configs
  createDefaultConfigs()
  local configs = g_resources.listDirectoryFiles("/bot", false, false)

  -- clean
  configList.onOptionChange = nil
  enableButton.onClick = nil
  configList:clearOptions()

  -- select active config based on settings
  local settings = g_settings.getNode('bot') or {}
  local index = getBotSettingsIndex()
  if not index then return end
  ensureBotSettings(settings, index)

  -- init list and buttons
  for i=1,#configs do
    configList:addOption(configs[i])
  end
  configList:setCurrentOption(settings[index].config)
  local currentOption = configList:getCurrentOption()
  if currentOption and currentOption.text ~= settings[index].config then
    settings[index].config = currentOption.text
    settings[index].enabled = false
  end

  enableButton:setOn(settings[index].enabled)

  configList.onOptionChange = function(widget)
    settings[index].config = widget:getCurrentOption().text
    g_settings.setNode('bot', settings)
    g_settings.save()
    refresh()
  end

  enableButton.onClick = function(widget)
    settings[index].enabled = not settings[index].enabled
    g_settings.setNode('bot', settings)
    g_settings.save()
    refresh()
  end

  if not g_game.isOnline() or not settings[index].enabled then
    if botButton then botButton:setOn(false) end
    statusLabel:setOn(true)
    statusLabel:setText("Status: disabled\nClick On to enable")
    return
  end

  local configName = settings[index].config

  -- Perfil ElfBot NG: esconder a janela grande antes de carregar os scripts.
  if isElfBotNgConfig(configName) and botWindow then
    botWindow:hide()
    if botButton then botButton:setOn(true) end
  end

  -- storage
  botStorage = {}

  local path = "/bot/" .. configName .. "/storage/"
  if not g_resources.directoryExists(path) then
    g_resources.makeDir(path)
  end

  botStorageFile = path.."profile_" .. g_settings.getNumber('profile') .. ".json"
  if g_resources.fileExists(botStorageFile) then
    local status, result = pcall(function()
      return json.decode(g_resources.readFileContents(botStorageFile))
    end)
    if not status then
      return onError("Error while reading storage (" .. botStorageFile .. "). To fix this problem you can delete storage.json. Details: " .. result)
    end
    botStorage = result
  end

  if isElfBotNgConfig(configName) then
    if isElfBotManualProfileLoad() then
      modules.game_bot.elfbotRuntimeOnlySession = false
    else
      modules.game_bot.elfbotRuntimeOnlySession = true
      botStorage = {}
    end
  elseif modules and modules.game_bot then
    modules.game_bot.elfbotRuntimeOnlySession = false
  end

  -- run script
  local status, result = pcall(function()
    return executeBot(configName, botStorage, botTabs, message, save, refresh, botWebSockets) end
  )
  if not status then
    return onError(result)
  end

  statusLabel:setOn(false)
  botExecutor = result

  -- Se estiver usando o perfil ElfBot NG, nao mostra a lista grande lateral.
  -- O loader do perfil cria/abre a janela compacta.
  if isElfBotNgConfig(configName) then
    scheduleEvent(function()
      if botWindow then botWindow:hide() end
      if ImperialElfBot and ImperialElfBot.show then
        ImperialElfBot.show()
      else
        showElfBotNgWindow()
      end
      if botButton then botButton:setOn(true) end
    end, 200)
  end

  check()
end

function save()
  if not botExecutor then
    return
  end

  if modules
    and modules.game_bot
    and modules.game_bot.elfbotRuntimeOnlySession == true
    and not isElfBotManualProfileLoad() then
    return
  end

  local settings = g_settings.getNode('bot') or {}
  local index = g_game.getCharacterName() .. "_" .. g_game.getClientVersion()
  if settings[index] == nil then
    return
  end

  local status, result = pcall(function()
    return json.encode(botStorage, 2)
  end)
  if not status then
    return onError("Error while saving bot storage. Storage won't be saved. Details: " .. result)
  end

  if result:len() > 100 * 1024 * 1024 then
    return onError("Storage file is too big, above 100MB, it won't be saved")
  end

  g_resources.writeFileContents(botStorageFile, result)
end

function onMiniWindowClose()
  botButton:setOn(false)
end

function findElfBotNgWindow()
  local root = g_ui and g_ui.getRootWidget and g_ui.getRootWidget()
  if not root then
    return nil
  end

  if root.recursiveGetChildById then
    local w = root:recursiveGetChildById("imperialElfBotWindow")
    if w and (not w.isDestroyed or not w:isDestroyed()) then
      return w
    end
  end

  local function scan(widget)
    if not widget or not widget.getChildren then return nil end
    if widget.getId and widget:getId() == "imperialElfBotWindow" then
      return widget
    end
    for _, child in pairs(widget:getChildren()) do
      local found = scan(child)
      if found then return found end
    end
    return nil
  end

  return scan(root)
end

function showElfBotNgWindow()
  local elfWindow = findElfBotNgWindow()
  if elfWindow then
    if botWindow then botWindow:hide() end
    if elfWindow.open then elfWindow:open() else elfWindow:show() end
    if elfWindow.raise then elfWindow:raise() end
    if elfWindow.focus then elfWindow:focus() end
    if botButton then botButton:setOn(true) end
    return true
  end
  return false
end

function toggle()
  local cfg = defaultElfBotConfig
  if configList and configList.getCurrentOption and configList:getCurrentOption() then
    cfg = configList:getCurrentOption().text or defaultElfBotConfig
  end

  -- Se a janela compacta do ElfBot NG existe, o botao Bot/game_bot controla ela diretamente.
  -- Isso funciona mesmo quando o script do bot roda em sandbox e a global ImperialElfBot nao fica visivel aqui.
  local elfWindow = findElfBotNgWindow()
  if elfWindow then
    if botWindow then botWindow:hide() end

    if elfWindow:isVisible() then
      elfWindow:hide()
      if botButton then botButton:setOn(false) end
    else
      if elfWindow.open then elfWindow:open() else elfWindow:show() end
      if elfWindow.raise then elfWindow:raise() end
      if elfWindow.focus then elfWindow:focus() end
      if botButton then botButton:setOn(true) end
    end
    return
  end

  -- Perfil ElfBot NG selecionado, mas a janela ainda nao foi criada.
  -- Aqui o botao Bot/game_bot tambem liga o perfil, porque sem o perfil ligado
  -- o loader nao cria a janela compacta.
  if isElfBotNgConfig(cfg) then
    if botWindow then botWindow:hide() end
    if botButton then botButton:setOn(true) end

    local settings = g_settings.getNode('bot') or {}
    local index = getBotSettingsIndex()
    if not index then return end
    settings[index] = settings[index] or { enabled = false, config = cfg }
    settings[index].config = cfg
    settings[index].enabled = true
    g_settings.setNode('bot', settings)
    g_settings.save()
    if enableButton and enableButton.setOn then enableButton:setOn(true) end

    scheduleEvent(function()
      if refresh then refresh() end
      scheduleEvent(showElfBotNgWindow, 500)
    end, 50)
    return
  end

  if botButton:isOn() then
    botWindow:close()
    botButton:setOn(false)
  else
    botWindow:open()
    botButton:setOn(true)
  end
end

function online()
  if modules and modules.game_bot then
    modules.game_bot.elfbotPendingManualProfileLoad = nil
    modules.game_bot.elfbotProfileLoadedThisSession = false
    modules.game_bot.elfbotRuntimeOnlySession = false
    modules.game_bot.elfbotSelectedProfileName = nil
  end
  botButton:show()
  botButton:setOn(false)
  if botWindow then botWindow:hide() end
  forceBotOffForLogin()
  if statusLabel then
    statusLabel:setOn(true)
    statusLabel:setText("Status: disabled\nClick Bot to enable")
  end
end

if modules and modules.game_bot then
  modules.game_bot.reload = refresh
  modules.game_bot.showElfBotNgWindow = showElfBotNgWindow
end

function offline()
  save()
  clear()
  botButton:hide()
  editWindow:hide()
end

function onError(message)
  statusLabel:setOn(true)
  statusLabel:setText("Error:\n" .. message)
  if g_logger and g_logger.error then
    g_logger.error("[BOT] " .. message)
  end

  local currentConfig = ""
  if configList and configList.getCurrentOption and configList:getCurrentOption() then
    currentConfig = configList:getCurrentOption().text or ""
  end
  if currentConfig == "ElfBot NG" and botWindow then
    botWindow:hide()
  end
end

function edit()
  local configs = g_resources.listDirectoryFiles("/bot", false, false)
  editWindow.manager.upload.config:clearOptions()
  for i=1,#configs do
    editWindow.manager.upload.config:addOption(configs[i])
  end
  editWindow.manager.download.config:setText("")

  editWindow:show()
  editWindow:focus()
  editWindow:raise()
end

local function copyDefaultConfigDir(src, dst, forceOverwrite)
  if not g_resources.directoryExists(dst) then
    g_resources.makeDir(dst)
    if not g_resources.directoryExists(dst) then
      return onError("Can't create " .. dst .. " directory in " .. g_resources.getWriteDir())
    end
  end

  local files = g_resources.listDirectoryFiles(src, true, false)
  for i, file in ipairs(files) do
    local parts = file:split("/")
    local baseName = parts[#parts]
    local target = dst .. "/" .. baseName

    if g_resources.directoryExists(file) then
      local preserveUserData = forceOverwrite
        and (src == "default_configs/ElfBot NG" or src == "default_configs/IMPERIALBOT")
        and elfBotUserDataDirs[baseName] == true
        and g_resources.directoryExists(target)
      if not preserveUserData then
        copyDefaultConfigDir(file, target, forceOverwrite and not elfBotUserDataDirs[baseName])
      end
    else
      local contents = g_resources.fileExists(file) and g_resources.readFileContents(file) or ""
      if contents:len() > 0 and (forceOverwrite or not g_resources.fileExists(target)) then
        g_resources.writeFileContents(target, contents)
      end
    end
  end
end

function createDefaultConfigs()
  local defaultConfigFiles = g_resources.listDirectoryFiles("default_configs", false, false)
  for i, config_name in ipairs(defaultConfigFiles) do
    -- Sincroniza os scripts do ZIP novo sem sobrescrever perfis/configs salvos pelo jogador.
    local forceOverwrite = (config_name == "ElfBot NG" or config_name == "IMPERIALBOT")
    copyDefaultConfigDir("default_configs/" .. config_name, "/bot/" .. config_name, forceOverwrite)
  end
end

function uploadConfig()
  local config = editWindow.manager.upload.config:getCurrentOption().text
  local archive = compressConfig(config)
  if not archive then
      return displayErrorBox(tr("Config upload failed"), tr("Config %s is invalid (can't be compressed)", config))
  end
  if archive:len() > 1024 * 1024 then
      return displayErrorBox(tr("Config upload failed"), tr("Config %s is too big, maximum size is 1024KB. Now it has %s KB.", config, math.floor(archive:len() / 1024)))
  end

  local infoBox = displayInfoBox(tr("Uploading config"), tr("Uploading config %s. Please wait.", config))

  HTTP.postJSON(configManagerUrl .. "?config=" .. config:gsub("%s+", "_"), archive, function(data, err)
    if infoBox then
      infoBox:destroy()
    end
    if err or data["error"] then
      return displayErrorBox(tr("Config upload failed"), tr("Error while upload config %s:\n%s", config, err or data["error"]))
    end
    displayInfoBox(tr("Succesful config upload"), tr("Config %s has been uploaded.\n%s", config, data["message"]))
  end)
end

function downloadConfig()
  local hash = editWindow.manager.download.config:getText()
  if hash:len() == 0 then
      return displayErrorBox(tr("Config download error"), tr("Enter correct config hash"))
  end
  local infoBox = displayInfoBox(tr("Downloading config"), tr("Downloading config with hash %s. Please wait.", hash))
  HTTP.download(configManagerUrl .. "?hash=" .. hash, hash .. ".zip", function(path, checksum, err)
    if infoBox then
      infoBox:destroy()
    end
    if err then
      return displayErrorBox(tr("Config download error"), tr("Config with hash %s cannot be downloaded", hash))
    end
    modules.client_textedit.show("", {
      title="Enter name for downloaded config",
      description="Config with hash " .. hash .. " has been downloaded. Enter name for new config.\nWarning: if config with same name already exist, it will be overwritten!",
      width=500
    }, function(configName)
      decompressConfig(configName, "/downloads/" .. path)
      refresh()
      edit()
    end)
  end)
end

function compressConfig(configName)
  if not g_resources.directoryExists("/bot/" .. configName) then
    return onError("Config " .. configName .. " doesn't exist")
  end
  local forArchive = {}
  for _, file in ipairs(g_resources.listDirectoryFiles("/bot/" .. configName)) do
    local fullPath = "/bot/" .. configName .. "/" .. file
    if g_resources.fileExists(fullPath) then -- regular file
        forArchive[file] = g_resources.readFileContents(fullPath)
    else -- dir
      for __, file2 in ipairs(g_resources.listDirectoryFiles(fullPath)) do
        local fullPath2 = fullPath .. "/" .. file2
        if g_resources.fileExists(fullPath2) then -- regular file
            forArchive[file .. "/" .. file2] = g_resources.readFileContents(fullPath2)
        end
      end
    end
  end
  return g_resources.createArchive(forArchive)
end

function decompressConfig(configName, archive)
  if g_resources.directoryExists("/bot/" .. configName) then
    g_resources.deleteFile("/bot/" .. configName) -- also delete dirs
  end
  local files = g_resources.decompressArchive(archive)
  g_resources.makeDir("/bot/" .. configName)
  if not g_resources.directoryExists("/bot/" .. configName) then
    return onError("Can't create /bot/" .. configName .. " directory in " .. g_resources.getWriteDir())
  end

  for file, contents in pairs(files) do
    local split = file:split("/")
    split[#split] = nil -- remove file name
    local dirPath = "/bot/" .. configName
    for _, s in ipairs(split) do
      dirPath = dirPath .. "/" .. s
      if not g_resources.directoryExists(dirPath) then
        g_resources.makeDir(dirPath)
        if not g_resources.directoryExists(dirPath) then
          return onError("Can't create " .. dirPath .. " directory in " .. g_resources.getWriteDir())
        end
      end
    end
    g_resources.writeFileContents("/bot/" .. configName .. file, contents)
  end
end

-- Executor
function message(category, msg)
  local widget = g_ui.createWidget('BotLabel', botMessages)
  widget.added = g_clock.millis()
  if category == 'error' then
    widget:setText(msg)
    widget:setColor("red")
    g_logger.error("[BOT] " .. msg)
  elseif category == 'warn' then
    widget:setText(msg)
    widget:setColor("yellow")
    g_logger.warning("[BOT] " .. msg)
  elseif category == 'info' then
    widget:setText(msg)
    widget:setColor("white")
    g_logger.info("[BOT] " .. msg)
  end

  if botMessages:getChildCount() > 5 then
    botMessages:getFirstChild():destroy()
  end
end

function check()
  removeEvent(checkEvent)
  if not botExecutor then
    return
  end

  checkEvent = scheduleEvent(check, 10)

  local status, result = pcall(function()
    return botExecutor.script()
  end)
  if not status then
    botExecutor = nil -- critical
    return onError(result)
  end

  -- remove old messages
  local widget = botMessages:getFirstChild()
  if widget and widget.added + 5000 < g_clock.millis() then
    widget:destroy()
  end
end

-- Callbacks
function initCallbacks()
  connect(rootWidget, {
    onKeyDown = botKeyDown,
    onKeyUp = botKeyUp,
    onKeyPress = botKeyPress
  })

  connect(g_game, {
    onTalk = botOnTalk,
    onTextMessage = botOnTextMessage,
    onLoginAdvice = botOnLoginAdvice,
    onUse = botOnUse,
    onUseWith = botOnUseWith,
    onChannelList = botChannelList,
    onOpenChannel = botOpenChannel,
    onCloseChannel = botCloseChannel,
    onChannelEvent = botChannelEvent,
    onImbuementWindow = botImbuementWindow,
    onModalDialog = botModalDialog,
    onAttackingCreatureChange = botAttackingCreatureChange,
    onAddItem = botContainerAddItem,
    onRemoveItem = botContainerRemoveItem,
    onGameEditText = botGameEditText,
    onSpellCooldown = botSpellCooldown,
    onSpellGroupCooldown = botGroupSpellCooldown
  })

  connect(Tile, {
    onAddThing = botAddThing,
    onRemoveThing = botRemoveThing
  })

  connect(Creature, {
    onAppear = botCreatureAppear,
    onDisappear = botCreatureDisappear,
    onPositionChange = botCreaturePositionChange,
    onHealthPercentChange = botCraetureHealthPercentChange,
    onTurn = botCreatureTurn,
    onWalk = botCreatureWalk,
  })

  connect(LocalPlayer, {
    onPositionChange = botCreaturePositionChange,
    onHealthPercentChange = botCraetureHealthPercentChange,
    onTurn = botCreatureTurn,
    onWalk = botCreatureWalk,
    onManaChange = botManaChange,
    onStatesChange = botStatesChange,
    onInventoryChange = botInventoryChange
  })

  connect(Container, {
    onOpen = botContainerOpen,
    onClose = botContainerClose,
    onUpdateItem = botContainerUpdateItem,
    onAddItem = botContainerAddItem,
    onRemoveItem = botContainerRemoveItem,
  })

  connect(g_map, {
    onMissle = botOnMissle,
    onAnimatedText = botOnAnimatedText,
    onStaticText = botOnStaticText
  })
end

function terminateCallbacks()
  disconnect(rootWidget, {
    onKeyDown = botKeyDown,
    onKeyUp = botKeyUp,
    onKeyPress = botKeyPress
  })

  disconnect(g_game, {
    onTalk = botOnTalk,
    onTextMessage = botOnTextMessage,
    onLoginAdvice = botOnLoginAdvice,
    onUse = botOnUse,
    onUseWith = botOnUseWith,
    onChannelList = botChannelList,
    onOpenChannel = botOpenChannel,
    onCloseChannel = botCloseChannel,
    onChannelEvent = botChannelEvent,
    onImbuementWindow = botImbuementWindow,
    onModalDialog = botModalDialog,
    onAttackingCreatureChange = botAttackingCreatureChange,
    onGameEditText = botGameEditText,
    onSpellCooldown = botSpellCooldown,
    onSpellGroupCooldown = botGroupSpellCooldown
  })

  disconnect(Tile, {
    onAddThing = botAddThing,
    onRemoveThing = botRemoveThing
  })

  disconnect(Creature, {
    onAppear = botCreatureAppear,
    onDisappear = botCreatureDisappear,
    onPositionChange = botCreaturePositionChange,
    onHealthPercentChange = botCraetureHealthPercentChange,
    onTurn = botCreatureTurn,
    onWalk = botCreatureWalk,
  })

  disconnect(LocalPlayer, {
    onPositionChange = botCreaturePositionChange,
    onHealthPercentChange = botCraetureHealthPercentChange,
    onTurn = botCreatureTurn,
    onWalk = botCreatureWalk,
    onManaChange = botManaChange,
    onStatesChange = botStatesChange,
    onInventoryChange = botInventoryChange
  })

  disconnect(Container, {
    onOpen = botContainerOpen,
    onClose = botContainerClose,
    onUpdateItem = botContainerUpdateItem,
    onAddItem = botContainerAddItem,
    onRemoveItem = botContainerRemoveItem
  })

  disconnect(g_map, {
    onMissle = botOnMissle,
    onAnimatedText = botOnAnimatedText,
    onStaticText = botOnStaticText
  })
end

function safeBotCall(func)
  local status, result = pcall(func)
  if not status then
    onError(result)
  end
end

function botKeyDown(widget, keyCode, keyboardModifiers)
  if botExecutor == nil then return false end
  if keyCode == KeyUnknown then return end
  safeBotCall(function() botExecutor.callbacks.onKeyDown(keyCode, keyboardModifiers) end)
end

function botKeyUp(widget, keyCode, keyboardModifiers)
  if botExecutor == nil then return false end
  if keyCode == KeyUnknown then return end
  safeBotCall(function() botExecutor.callbacks.onKeyUp(keyCode, keyboardModifiers) end)
end

function botKeyPress(widget, keyCode, keyboardModifiers, autoRepeatTicks)
  if botExecutor == nil then return false end
  if keyCode == KeyUnknown then return end
  safeBotCall(function() botExecutor.callbacks.onKeyPress(keyCode, keyboardModifiers, autoRepeatTicks) end)
end

function botOnTalk(name, level, mode, text, channelId, pos)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onTalk(name, level, mode, text, channelId, pos) end)
end

function botOnTextMessage(mode, text)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onTextMessage(mode, text) end)
end

function botOnLoginAdvice(message)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onLoginAdvice(message) end)
end

function botAddThing(tile, thing)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onAddThing(tile, thing) end)
end

function botRemoveThing(tile, thing)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onRemoveThing(tile, thing) end)
end

function botCreatureAppear(creature)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onCreatureAppear(creature) end)
end

function botCreatureDisappear(creature)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onCreatureDisappear(creature) end)
end

function botCreaturePositionChange(creature, newPos, oldPos)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onCreaturePositionChange(creature, newPos, oldPos) end)
end

function botCraetureHealthPercentChange(creature, healthPercent)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onCreatureHealthPercentChange(creature, healthPercent) end)
end

function botOnUse(pos, itemId, stackPos, subType)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onUse(pos, itemId, stackPos, subType) end)
end

function botOnUseWith(pos, itemId, target, subType)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onUseWith(pos, itemId, target, subType) end)
end

function botContainerOpen(container, previousContainer)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onContainerOpen(container, previousContainer) end)
end

function botContainerClose(container)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onContainerClose(container) end)
end

function botContainerUpdateItem(container, slot, item, oldItem)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onContainerUpdateItem(container, slot, item, oldItem) end)
end

function botOnMissle(missle)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onMissle(missle) end)
end

function botOnAnimatedText(thing, text)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onAnimatedText(thing, text) end)
end

function botOnStaticText(thing, text)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onStaticText(thing, text) end)
end

function botChannelList(channels)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onChannelList(channels) end)
end

function botOpenChannel(channelId, name)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onOpenChannel(channelId, name) end)
end

function botCloseChannel(channelId)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onCloseChannel(channelId) end)
end

function botChannelEvent(channelId, name, event)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onChannelEvent(channelId, name, event) end)
end

function botCreatureTurn(creature, direction)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onTurn(creature, direction) end)
end

function botCreatureWalk(creature, oldPos, newPos)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onWalk(creature, oldPos, newPos) end)
end

function botImbuementWindow(itemId, slots, activeSlots, imbuements, needItems)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onImbuementWindow(itemId, slots, activeSlots, imbuements, needItems) end)
end

function botModalDialog(id, title, message, buttons, enterButton, escapeButton, choices, priority)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onModalDialog(id, title, message, buttons, enterButton, escapeButton, choices, priority) end)
end

function botGameEditText(id, itemId, maxLength, text, writer, time)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onGameEditText(id, itemId, maxLength, text, writer, time) end)
end

function botAttackingCreatureChange(creature, oldCreature)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onAttackingCreatureChange(creature,oldCreature) end)
end

function botManaChange(player, mana, maxMana, oldMana, oldMaxMana)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onManaChange(player, mana, maxMana, oldMana, oldMaxMana) end)
end

function botStatesChange(player, states, oldStates)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onStatesChange(player, states, oldStates) end)
end

function botContainerAddItem(container, slot, item, oldItem)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onAddItem(container, slot, item, oldItem) end)
end

function botContainerRemoveItem(container, slot, item)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onRemoveItem(container, slot, item) end)
end

function botSpellCooldown(iconId, duration)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onSpellCooldown(iconId, duration) end)
end

function botGroupSpellCooldown(iconId, duration)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onGroupSpellCooldown(iconId, duration) end)
end

function botInventoryChange(player, slot, item, oldItem)
  if botExecutor == nil then return false end
  safeBotCall(function() botExecutor.callbacks.onInventoryChange(player, slot, item, oldItem) end)
end

function elfButton(name)
  if name == "Healing" then
    return elfOpen({"HP", "Heal", "Healing", "Tools"})
  elseif name == "Aimbot" then
    return elfOpen({"Target", "Attack", "Cave"})
  elseif name == "Lists" then
    return elfOpen({"Main", "Tools"})
  elseif name == "HUD" then
    return elfOpen({"Main", "Tools"})
  elseif name == "Extras" then
    return elfOpen({"Tools", "Main"})
  elseif name == "Hotkeys" then
    return elfHotkeysOpen()
  elseif name == "Shortkeys" then
    return edit()
  elseif name == "Reconnect" then
    return elfOpen({"Main", "Tools"})
  elseif name == "Save" then
    return elfSave()
  elseif name == "Custom" then
    return edit()
  elseif name == "Cavebot" then
    if elfCavebotOpen then
      return elfCavebotOpen()
    end
    return elfOpen({"Cave", "CaveBot"})
  elseif name == "Navigation" then
    return elfOpen({"Cave", "Navigation"})
  elseif name == "Links" then
    return elfOpen({"Tools", "Main"})
  elseif name == "Creature Spy" then
    return elfOpen({"Tools", "Main"})
  elseif name == "Load" then
    return loadConfig()
  elseif name == "Help" then
    return help()
  elseif name == "Targeting" then
    return elfOpen({"Target", "Attack"})
  elseif name == "Proxy" then
    return openSettings()
  elseif name == "Icons" then
    return elfOpen({"Tools", "Main"})
  elseif name == "Outros" then
    return elfOpen({"Tools", "Main"})
  end
end
