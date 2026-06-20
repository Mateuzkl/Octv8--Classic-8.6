-- ElfBot original hotkeys interpreter for OTClient/vBot
-- Suporta as hotkeys mais comuns do ElfBot: auto, if, say, useoncreature, sd target,
-- equipring/equipamulet/equipammo, eatfood, playsound, screenshot, setcavebot/settargeting/setlooting.

local legacyHotkeysStop = modules and modules.game_bot and modules.game_bot.elfHotkeysStop

local function elfHotkeysLog(level, text)
  text = tostring(text)
  if g_logger and g_logger[level] then
    g_logger[level](text)
  elseif modules and modules.game_textmessage and modules.game_textmessage.displayGameMessage then
    modules.game_textmessage.displayGameMessage(text)
  elseif print then
    print(text)
  end
end

elfHotkeysWindow = nil
elfHotkeysEvents = elfHotkeysEvents or {}
elfHotkeysRunning = false
elfHotkeysText = ""
elfHotkeysLastSpell = 0
elfHotkeysLastUse = 0

local elfHotkeysNextEventId = 0

local presets = {
  knight = [[auto 200 if [$hppc <= 85] say exura ico
auto 200 if [$hppc <= 55] useoncreature 7643 self
auto 200 if [$mppc <= 70] useoncreature 268 self
auto 1000 if [$monstersaround.1 >= 2 && $strengthtime == 0] say utito tempo
auto 600 if [$monstersaround.1 >= 3] say exori
auto 900 if [$monstersaround.1 >= 4] say exori gran
auto 700 if [$target.hppc > 0] say exori hur
auto 200 if [$paralyzed] say utani hur
auto 1000 if [$hasted == 0] say utani hur
auto 200 if [$hppc <= 45] equipring 3048
auto 200 if [$hppc >= 80] unequip ring empty]],
  druid = [[auto 200 if [$hppc <= 75] say exura vita
auto 400 if [$hppc <= 65] say exura gran mas res
auto 200 if [$mppc <= 60] useoncreature 238 self
auto 800 if [$monstersaround.3 >= 4] say exevo gran mas frigo
auto 700 if [$target.hppc > 0] say exori frigo
auto 500 if [$target.hppc > 0] sd target
auto 1000 if [$target.hppc > 0] useoncreature 3165 target
auto 200 if [$hppc <= 55 && $manashielded == 0] say utamo vita
auto 1000 if [$hasted == 0] say utani gran hur
auto 200 if [$paralyzed] say utani gran hur
auto 60000 eatfood]],
  paladin = [[auto 200 if [$hppc <= 85] say exura san
auto 200 if [$hppc <= 65] say exura gran san
auto 200 if [$mppc <= 65] useoncreature 7642 self
auto 200 if [$hppc <= 55] useoncreature 8472 self
auto 700 if [$monstersaround.3 >= 4] say exevo mas san
auto 650 if [$target.hppc > 0] say exori con
auto 500 if [$target.hppc > 0] sd target
auto 300 equipammo 7368
auto 1000 if [$hasted == 0] say utani hur
auto 200 if [$paralyzed] say utani hur
auto 200 if [$hppc <= 45] equipring 3051]],
  sorcerer = [[auto 200 if [$hppc <= 75] say exura vita
auto 200 if [$mppc <= 60] useoncreature 238 self
auto 200 if [$mppc <= 40] useoncreature 23373 self
auto 60000 eatfood
auto 900 if [$monstersaround.3 >= 4] say exevo gran mas flam
auto 700 if [$target.hppc > 0] say exevo vis hur
auto 500 if [$target.hppc > 0] sd target
auto 650 if [$target.hppc > 0] say exori flam
auto 200 if [$hppc <= 60 && $manashielded == 0] say utamo vita
auto 1000 if [$hasted == 0] say utani gran hur
auto 200 if [$paralyzed] say utani gran hur
auto 200 if [$hppc <= 45] equipamulet 3081]],
  diversas = [[auto 1000 openbpitem
auto 60000 eatfood
auto 60000 turnn
auto 1000 if [$pzone == 0 && $playersaround.7 >= 1] screenshot
setlooting on
setcavebot on
settargeting on
auto 1000 if [$cap <= 100] gotolabel Depositer
auto 1000 if [$playersaround.7 >= 1] playsound player.wav
auto 1000 if [$gmaround] playsound alert.wav
auto 200 if [$hppc <= 35] playsound danger.wav
auto 1000 if [$itemcount.268 <= 10] playsound lowpots.wav]]
}

local foodIds = {3725, 3723, 3724, 3726, 3727, 3728, 3729, 3730, 3731, 3732, 3582, 3577, 3578, 3579, 3580, 3581, 3592, 3593, 3594, 3595, 3600, 3606, 3607}

local function msg(text)
  if modules.game_textmessage then
    modules.game_textmessage.displayGameMessage(text)
  end
  elfHotkeysLog("info", "[ElfBot Hotkeys] " .. text)
end

local function trim(s)
  return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function splitLines(text)
  local t = {}
  text = tostring(text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
  for line in text:gmatch("([^\n]*)\n?") do
    if line == "" and #t > 0 and text:sub(-1) ~= "\n" then break end
    line = trim(line)
    if line:len() > 0 and line:sub(1,2) ~= "--" then
      table.insert(t, line)
    end
  end
  return t
end

local function getPlayer()
  if not g_game.isOnline() then return nil end
  return g_game.getLocalPlayer()
end

local function dist(a, b)
  if not a or not b then return 999 end
  if a.z ~= b.z then return 999 end
  return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y))
end

local function getSpectators()
  local player = getPlayer()
  if not player then return {} end
  return g_map.getSpectators(player:getPosition(), false) or {}
end

local function countMonsters(range)
  local player = getPlayer()
  if not player then return 0 end
  range = tonumber(range) or 1
  local count = 0
  for _, c in ipairs(getSpectators()) do
    if c and c ~= player and c.isMonster and c:isMonster() and dist(player:getPosition(), c:getPosition()) <= range then
      count = count + 1
    end
  end
  return count
end

local function countPlayers(range)
  local player = getPlayer()
  if not player then return 0 end
  range = tonumber(range) or 7
  local count = 0
  for _, c in ipairs(getSpectators()) do
    if c and c ~= player and c.isPlayer and c:isPlayer() and dist(player:getPosition(), c:getPosition()) <= range then
      count = count + 1
    end
  end
  return count
end

local function gmAround()
  local player = getPlayer()
  if not player then return false end
  for _, c in ipairs(getSpectators()) do
    if c and c ~= player and c.isPlayer and c:isPlayer() then
      local name = c:getName() or ""
      if name:lower():find("gm") or name:lower():find("adm") or name:lower():find("admin") then
        return true
      end
    end
  end
  return false
end

local function hasState(state)
  local player = getPlayer()
  if not player or not PlayerStates or not state then return false end
  return bit.band(player:getStates(), state) > 0
end

local function itemCount(itemId)
  itemId = tonumber(itemId) or 0
  if itemId <= 0 then return 0 end
  local total = 0
  local containers = g_game.getContainers() or {}
  for _, container in pairs(containers) do
    for _, item in ipairs(container:getItems() or {}) do
      if item and item:getId() == itemId then
        total = total + math.max(1, item:getCount())
      end
    end
  end
  local item = g_game.findPlayerItem(itemId, -1)
  if item then
    total = total + math.max(1, item:getCount())
  end
  return total
end

local function varValue(var)
  var = tostring(var or ""):lower()
  local player = getPlayer()
  if not player then return 0 end

  if var == "hppc" then return player:getHealthPercent() or 0 end
  if var == "mppc" then
    local maxMana = player:getMaxMana() or 0
    if maxMana <= 0 then return 100 end
    return math.floor((player:getMana() or 0) * 100 / maxMana)
  end
  if var == "hp" then return player:getHealth() or 0 end
  if var == "mp" or var == "mana" then return player:getMana() or 0 end
  if var == "cap" then return player:getFreeCapacity() or player:getCapacity() or 0 end
  if var == "pzone" then return hasState(PlayerStates.Pz) and 1 or 0 end
  if var == "paralyzed" then return hasState(PlayerStates.Paralyze) and true or false end
  if var == "hasted" then return hasState(PlayerStates.Haste) and 1 or 0 end
  if var == "manashielded" then return hasState(PlayerStates.ManaShield) and 1 or 0 end
  if var == "gmaround" then return gmAround() end
  if var == "strengthtime" then return 0 end

  local r = var:match("^monstersaround%.(%d+)$")
  if r then return countMonsters(tonumber(r)) end

  r = var:match("^playersaround%.(%d+)$")
  if r then return countPlayers(tonumber(r)) end

  r = var:match("^itemcount%.(%d+)$")
  if r then return itemCount(tonumber(r)) end

  if var == "target.hppc" then
    local target = g_game.getAttackingCreature()
    if target then return target:getHealthPercent() or 0 end
    return 0
  end

  return 0
end

local function evalCondition(cond)
  cond = trim(cond)
  if cond == "" then return true end
  cond = cond:gsub("%$([%w_%.]+)", function(v)
    local val = varValue(v)
    if type(val) == "boolean" then return val and "true" or "false" end
    return tostring(tonumber(val) or 0)
  end)
  cond = cond:gsub("&&", " and "):gsub("%|%|", " or ")
  cond = cond:gsub("!%s*", " not ")
  local fn, err = loadstring("return (" .. cond .. ")")
  if not fn then
    elfHotkeysLog("warning", "[ElfBot Hotkeys] Condicao invalida: " .. cond .. " | " .. tostring(err))
    return false
  end
  local ok, result = pcall(fn)
  return ok and result and true or false
end

local function moveItemToSlot(itemId, slot)
  local item = g_game.findPlayerItem(tonumber(itemId), -1)
  if item then
    g_game.move(item, {x = 65535, y = slot, z = 0}, math.max(1, item:getCount()))
  end
end

local function moveSlotToContainer(slot)
  local player = getPlayer()
  if not player then return end
  local item = player:getInventoryItem(slot)
  if not item then return end
  for _, container in pairs(g_game.getContainers() or {}) do
    if container:getItemsCount() < container:getCapacity() then
      g_game.move(item, container:getSlotPosition(container:getItemsCount()), math.max(1, item:getCount()))
      return
    end
  end
end

local function eatFood()
  for _, id in ipairs(foodIds) do
    local item = g_game.findPlayerItem(id, -1)
    if item then
      g_game.use(item)
      return true
    end
  end
  return false
end

local function useOnCreature(itemId, targetName)
  itemId = tonumber(itemId)
  if not itemId then return end
  local target = nil
  targetName = tostring(targetName or ""):lower()
  if targetName == "self" then
    target = getPlayer()
  elseif targetName == "target" then
    target = g_game.getAttackingCreature()
  end
  if target then
    g_game.useInventoryItemWith(itemId, target, -1)
  end
end

local function playSound(file)
  if not g_sounds then return end
  local channel = g_sounds.getChannel(SoundChannels.Bot)
  if not channel then return end
  file = tostring(file or "alarm.ogg")
  if not file:find("/") then
    file = "/sounds/" .. file
  end
  channel:setEnabled(true)
  channel:stop(0)
  channel:play(file, 0, 1.0)
end

local function executeOneCommand(cmd)
  cmd = trim(cmd)
  if cmd == "" then return end
  local lcmd = cmd:lower()

  local sayText = cmd:match("^[Ss][Aa][Yy]%s+(.+)$")
  if sayText then
    g_game.talk(sayText:gsub('^"', ''):gsub('"$', ''))
    return
  end

  local itemId, targetName = lcmd:match("^useoncreature%s+(%d+)%s+([%w_]+)$")
  if itemId then return useOnCreature(itemId, targetName) end

  if lcmd == "sd target" then return useOnCreature(3155, "target") end
  if lcmd == "eatfood" then return eatFood() end
  if lcmd == "turnn" then return g_game.turn(math.random(0, 3)) end
  if lcmd == "screenshot" then return g_app.doScreenshot("elfbot_hotkey_" .. os.time() .. ".png") end
  if lcmd == "setcavebot on" then return modules.game_bot.elfOpen({"Cave", "CaveBot"}) end
  if lcmd == "settargeting on" then return modules.game_bot.elfOpen({"Target", "Attack"}) end
  if lcmd == "setlooting on" then return modules.game_bot.elfOpen({"Cave", "Target"}) end
  if lcmd == "setcavebot off" or lcmd == "settargeting off" or lcmd == "setlooting off" then return end
  if lcmd == "openbpitem" then return end

  itemId = lcmd:match("^equipring%s+(%d+)$")
  if itemId then return moveItemToSlot(itemId, InventorySlotFinger) end
  itemId = lcmd:match("^equipamulet%s+(%d+)$")
  if itemId then return moveItemToSlot(itemId, InventorySlotNeck) end
  itemId = lcmd:match("^equipammo%s+(%d+)$")
  if itemId then return moveItemToSlot(itemId, InventorySlotAmmo) end
  if lcmd == "unequip ring empty" then return moveSlotToContainer(InventorySlotFinger) end

  local label = cmd:match("^[Gg][Oo][Tt][Oo][Ll][Aa][Bb][Ee][Ll]%s+(.+)$")
  if label then
    msg("gotolabel '" .. label .. "' is recognized, but it must be connected to this pack's CaveBot.")
    return
  end

  local sound = cmd:match("^[Pp][Ll][Aa][Yy][Ss][Oo][Uu][Nn][Dd]%s+(.+)$")
  if sound then return playSound(sound) end

  local spell = cmd:match("^[Ss][Aa][Yy][Nn][Pp][Cc]%s+(.+)$")
  if spell then return g_game.talk(spell) end

  elfHotkeysLog("warning", "[ElfBot Hotkeys] Unsupported command: " .. cmd)
end

local function executeCommand(cmd)
  for part in tostring(cmd or ""):gmatch("[^|]+") do
    executeOneCommand(part)
  end
end

local SETTINGS_KEY = "elfbot_custom_hotkeys"
local hotkeysConfig = nil
local hotkeyEvents = {}
local hotkeyBindings = {}
local hotkeyRows = {}
local captureEntryId = nil
local selectedEntryId = nil
local nextScheduleId = 0

local function getHotkeysLanguage()
  if type(ImperialElfBot_GetLanguage) == "function" then
    local ok, language = pcall(ImperialElfBot_GetLanguage)
    if ok and tostring(language):lower() == "pt" then
      return "pt"
    end
  end
  if type(storage) == "table" and storage.elfbotLanguageExplicit == true and tostring(storage.elfbotLanguage):lower() == "pt" then
    return "pt"
  end
  return "en"
end

local function hotkeyText(ptText, enText)
  return getHotkeysLanguage() == "pt" and ptText or enText
end

local function getEntry(entryId)
  for _, entry in ipairs(hotkeysConfig.entries or {}) do
    if entry.id == entryId then
      return entry
    end
  end
  return nil
end

local function saveConfig()
  g_settings.setNode(SETTINGS_KEY, hotkeysConfig)
  g_settings.save()
end

local function normalizeConfig()
  local saved = g_settings.getNode(SETTINGS_KEY)
  hotkeysConfig = type(saved) == "table" and saved or {}
  hotkeysConfig.enabled = hotkeysConfig.enabled == true
  hotkeysConfig.persistent = hotkeysConfig.persistent == true
  hotkeysConfig.nextId = math.max(1, tonumber(hotkeysConfig.nextId) or 1)
  hotkeysConfig.entries = type(hotkeysConfig.entries) == "table" and hotkeysConfig.entries or {}

  local entries = {}
  for _, rawEntry in ipairs(hotkeysConfig.entries) do
    if type(rawEntry) == "table" then
      local entry = {
        id = tostring(rawEntry.id or hotkeysConfig.nextId),
        hotkey = tostring(rawEntry.hotkey or ""),
        name = tostring(rawEntry.name or hotkeyText("Nova hotkey", "New hotkey")),
        script = tostring(rawEntry.script or ""),
        enabled = rawEntry.enabled == true
      }
      entries[#entries + 1] = entry
      hotkeysConfig.nextId = hotkeysConfig.nextId + 1
    end
  end
  hotkeysConfig.entries = entries

  if #entries == 0 then
    local legacyScript = tostring(g_settings.get("elfbot_hotkeys_text") or "")
    if legacyScript ~= "" then
      entries[1] = {
        id = tostring(hotkeysConfig.nextId),
        hotkey = "",
        name = hotkeyText("Script legado importado", "Imported legacy script"),
        script = legacyScript,
        enabled = false
      }
      hotkeysConfig.nextId = hotkeysConfig.nextId + 1
    end
  end

  if not hotkeysConfig.persistent then
    hotkeysConfig.enabled = false
    for _, entry in ipairs(entries) do
      entry.enabled = false
    end
  end
end

local function stopEntry(entryId)
  local events = hotkeyEvents[entryId]
  if events then
    for _, event in pairs(events) do
      removeEvent(event)
    end
  end
  hotkeyEvents[entryId] = nil
end

local function stopAllEntries()
  for entryId in pairs(hotkeyEvents) do
    stopEntry(entryId)
  end
end

local function isEntryRunning(entryId)
  local entry = getEntry(entryId)
  return hotkeysConfig.enabled and entry and entry.enabled
end

local function scheduleEntryCommand(entryId, interval, condition, action)
  nextScheduleId = nextScheduleId + 1
  local scheduleId = nextScheduleId
  hotkeyEvents[entryId] = hotkeyEvents[entryId] or {}

  local function loop()
    if not isEntryRunning(entryId) then
      return
    end
    pcall(function()
      if g_game.isOnline() and evalCondition(condition) then
        executeCommand(action)
      end
    end)
    if isEntryRunning(entryId) then
      hotkeyEvents[entryId][scheduleId] = scheduleEvent(loop, interval)
    end
  end

  hotkeyEvents[entryId][scheduleId] = scheduleEvent(loop, interval)
end

local function startEntry(entry)
  if not entry or not hotkeysConfig.enabled or not entry.enabled then
    return
  end
  stopEntry(entry.id)

  for _, line in ipairs(splitLines(entry.script)) do
    local interval, condition, action = line:match("^[Aa][Uu][Tt][Oo]%s+(%d+)%s+[Ii][Ff]%s+%[(.-)%]%s+(.+)$")
    if interval and action then
      scheduleEntryCommand(entry.id, math.max(50, tonumber(interval) or 1000), condition, action)
    else
      interval, action = line:match("^[Aa][Uu][Tt][Oo]%s+(%d+)%s+(.+)$")
      if interval and action then
        scheduleEntryCommand(entry.id, math.max(50, tonumber(interval) or 1000), "true", action)
      else
        pcall(function() executeCommand(line) end)
      end
    end
  end
end

local function getGameRoot()
  if modules and modules.game_interface and modules.game_interface.getRootPanel then
    return modules.game_interface.getRootPanel()
  end
  return nil
end

local function unbindEntry(entry)
  local binding = entry and hotkeyBindings[entry.id]
  if not binding then
    return
  end
  g_keyboard.unbindKeyPress(binding.hotkey, binding.callback, getGameRoot())
  hotkeyBindings[entry.id] = nil
end

local refreshWindow
local setEntryEnabled

local function bindEntry(entry)
  unbindEntry(entry)
  if not entry or not hotkeysConfig.enabled or entry.hotkey == "" then
    return
  end

  local callback = function()
    local currentEntry = getEntry(entry.id)
    if currentEntry then
      setEntryEnabled(currentEntry.id, not currentEntry.enabled)
    end
    return true
  end
  hotkeyBindings[entry.id] = {hotkey = entry.hotkey, callback = callback}
  g_keyboard.bindKeyPress(entry.hotkey, callback, getGameRoot())
end

local function bindAllEntries()
  for _, entry in ipairs(hotkeysConfig.entries) do
    bindEntry(entry)
  end
end

local function unbindAllEntries()
  for _, entry in ipairs(hotkeysConfig.entries) do
    unbindEntry(entry)
  end
end

local function updateStatus()
  if not elfHotkeysWindow or not elfHotkeysWindow.footer or not elfHotkeysWindow.footer.status then
    return
  end
  local active = 0
  for _, entry in ipairs(hotkeysConfig.entries) do
    if entry.enabled then active = active + 1 end
  end
  local status = elfHotkeysWindow.footer.status
  status:setText(hotkeysConfig.enabled
    and string.format(hotkeyText("Ligado - %d/%d hotkeys ativas", "Enabled - %d/%d hotkeys active"), active, #hotkeysConfig.entries)
    or hotkeyText("Desligado", "Disabled"))
  status:setColor(hotkeysConfig.enabled and "#00ff66" or "#ff5555")
end

local function setMasterEnabled(enabled)
  hotkeysConfig.enabled = enabled == true
  elfHotkeysRunning = hotkeysConfig.enabled
  stopAllEntries()
  unbindAllEntries()
  if hotkeysConfig.enabled then
    bindAllEntries()
    for _, entry in ipairs(hotkeysConfig.entries) do
      startEntry(entry)
    end
  end
  saveConfig()
  if refreshWindow then refreshWindow() end
end

setEntryEnabled = function(entryId, enabled)
  local entry = getEntry(entryId)
  if not entry then return end
  entry.enabled = enabled == true
  stopEntry(entry.id)
  if entry.enabled and hotkeysConfig.enabled then
    startEntry(entry)
  end
  saveConfig()
  if refreshWindow then refreshWindow() end
end

local function scriptPreview(script)
  local preview = tostring(script or ""):gsub("[\r\n]+", " ")
  if #preview > 70 then
    return preview:sub(1, 67) .. "..."
  end
  return preview
end

local function setCaptureHint(text)
  if elfHotkeysWindow and elfHotkeysWindow.footer and elfHotkeysWindow.footer.status then
    elfHotkeysWindow.footer.status:setText(text)
    elfHotkeysWindow.footer.status:setColor("#f4cd50")
  end
end

local function assignHotkey(entryId, hotkey)
  local entry = getEntry(entryId)
  if not entry then return end
  hotkey = tostring(hotkey or "")

  for _, otherEntry in ipairs(hotkeysConfig.entries) do
    if otherEntry.id ~= entry.id and otherEntry.hotkey == hotkey then
      unbindEntry(otherEntry)
      otherEntry.hotkey = ""
    end
  end
  unbindEntry(entry)
  entry.hotkey = hotkey
  if hotkeysConfig.enabled then
    bindEntry(entry)
  end
  saveConfig()
  if refreshWindow then refreshWindow() end
end

local function beginCapture(entry)
  if not entry or not elfHotkeysWindow then return end
  captureEntryId = entry.id
  setCaptureHint(hotkeyText("Pressione uma tecla para " .. entry.name .. ". Pressione Escape para cancelar.", "Press a key for " .. entry.name .. ". Press Escape to cancel."))
  elfHotkeysWindow:grabKeyboard()
end

local function editScript(entry)
  if not entry or not modules.client_textedit then return end
  modules.client_textedit.multilineEditor(hotkeyText("Script da Hotkey - ", "Hotkey Script - ") .. entry.name, entry.script or "", function(newText)
    entry.script = tostring(newText or "")
    if entry.enabled and hotkeysConfig.enabled then
      startEntry(entry)
    end
    saveConfig()
    if refreshWindow then refreshWindow() end
  end)
end

local function createRow(entry)
  local row = g_ui.createWidget("ElfHotkeyRow", elfHotkeysWindow.hotkeyList)
  hotkeyRows[entry.id] = row
  row.enabled:setChecked(entry.enabled)
  row.keyButton:setText(entry.hotkey ~= "" and entry.hotkey or hotkeyText("Definir tecla", "Set key"))
  row.name:setText(entry.name)
  row.enabled.onClick = function()
    setEntryEnabled(entry.id, not entry.enabled)
    return true
  end
  row.keyButton.onClick = function()
    beginCapture(entry)
    return true
  end
  row.name.onTextChange = function(_, text)
    entry.name = tostring(text or "")
  end
  row.name.onFocusChange = function(_, focused)
    if focused then
      selectedEntryId = entry.id
    end
  end
  row.onMousePress = function()
    selectedEntryId = entry.id
    return false
  end
end

refreshWindow = function()
  if not elfHotkeysWindow then return end
  elfHotkeysWindow:setText(hotkeyText("Hotkeys Personalizadas", "Custom Hotkeys"))
  elfHotkeysWindow.header.listLabel:setText(hotkeyText("Lista de Hotkeys", "Hotkey List"))
  elfHotkeysWindow.header.masterEnabled:setText(hotkeyText("Hotkeys ligadas", "Hotkeys enabled"))
  elfHotkeysWindow.header.persistent:setText(hotkeyText("Persistente", "Persistent"))
  elfHotkeysWindow.header.editButton:setText(hotkeyText("Editar", "Edit"))
  elfHotkeysWindow.header.addButton:setText(hotkeyText("Criar Hotkey", "Create Hotkey"))
  elfHotkeysWindow.header.masterEnabled:setChecked(hotkeysConfig.enabled)
  elfHotkeysWindow.header.persistent:setChecked(hotkeysConfig.persistent)
  elfHotkeysWindow.hotkeyList:destroyChildren()
  hotkeyRows = {}
  for _, entry in ipairs(hotkeysConfig.entries) do
    createRow(entry)
  end
  updateStatus()
  if elfHotkeysWindow.hotkeyList.updateLayout then
    elfHotkeysWindow.hotkeyList:updateLayout()
  end
end

local function addHotkey(script)
  local entry = {
    id = tostring(hotkeysConfig.nextId),
    hotkey = "",
    name = hotkeyText("Utamo Vita", "Utamo Vita"),
    script = script or "auto 1000 if [$manashielded == 0] say utamo vita",
    enabled = false
  }
  hotkeysConfig.nextId = hotkeysConfig.nextId + 1
  table.insert(hotkeysConfig.entries, entry)
  selectedEntryId = entry.id
  saveConfig()
  if refreshWindow then refreshWindow() end
  beginCapture(entry)
end

function elfHotkeysInit()
  if legacyHotkeysStop then
    pcall(legacyHotkeysStop)
    legacyHotkeysStop = nil
  end
  normalizeConfig()

  local rootWidget = g_ui.getRootWidget()
  if rootWidget and rootWidget.recursiveGetChildById then
    local oldWindow = rootWidget:recursiveGetChildById("elfHotkeysWindow")
    if oldWindow then oldWindow:destroy() end
  end
  elfHotkeysWindow = g_ui.createWidget("ElfHotkeysWindow", rootWidget)
  elfHotkeysWindow:hide()

  elfHotkeysWindow.closeButton.onClick = elfHotkeysClose
  elfHotkeysWindow.header.editButton.onClick = function()
    local entry = getEntry(selectedEntryId) or hotkeysConfig.entries[1]
    if entry then
      selectedEntryId = entry.id
      editScript(entry)
    else
      addHotkey()
    end
    return true
  end
  elfHotkeysWindow.header.addButton.onClick = function()
    addHotkey()
  end
  elfHotkeysWindow.header.masterEnabled.onClick = function()
    setMasterEnabled(not hotkeysConfig.enabled)
    return true
  end
  elfHotkeysWindow.header.persistent.onClick = function()
    hotkeysConfig.persistent = not hotkeysConfig.persistent
    saveConfig()
    refreshWindow()
    return true
  end
  elfHotkeysWindow.onKeyDown = function(_, keyCode, keyboardModifiers)
    if not captureEntryId then return false end
    local hotkey = determineKeyComboDesc(keyCode, keyboardModifiers)
    local capturedEntryId = captureEntryId
    captureEntryId = nil
    elfHotkeysWindow:ungrabKeyboard()
    if hotkey ~= "Escape" then
      assignHotkey(capturedEntryId, hotkey)
    else
      refreshWindow()
    end
    return true
  end

  if hotkeysConfig.enabled then
    bindAllEntries()
    for _, entry in ipairs(hotkeysConfig.entries) do
      startEntry(entry)
    end
  end
  elfHotkeysRunning = hotkeysConfig.enabled
  if type(ImperialElfBot_RegisterLanguageRefresher) == "function" then
    ImperialElfBot_RegisterLanguageRefresher("customHotkeys", refreshWindow)
  end
  refreshWindow()
end

function elfHotkeysTerminate()
  stopAllEntries()
  unbindAllEntries()
  if elfHotkeysWindow then
    elfHotkeysWindow:destroy()
    elfHotkeysWindow = nil
  end
end

function elfHotkeysOpen()
  if not elfHotkeysWindow then return end
  refreshWindow()
  elfHotkeysWindow:show()
  elfHotkeysWindow:raise()
  elfHotkeysWindow:focus()
end

function elfHotkeysClose()
  if elfHotkeysWindow then
    captureEntryId = nil
    elfHotkeysWindow:ungrabKeyboard()
    elfHotkeysWindow:hide()
  end
end

function elfHotkeysSave()
  saveConfig()
  if hotkeysConfig.enabled then
    stopAllEntries()
    for _, entry in ipairs(hotkeysConfig.entries) do
      if entry.enabled then startEntry(entry) end
    end
  end
  refreshWindow()
  msg(hotkeyText("Hotkeys personalizadas salvas.", "Custom hotkeys saved."))
end

function elfHotkeysLoadPreset(name)
  if presets[name] then
    addHotkey(presets[name])
  end
end

function elfHotkeysEdit()
  addHotkey()
end

function elfHotkeysStop()
  setMasterEnabled(false)
end

function elfHotkeysStart()
  setMasterEnabled(true)
end

function elfHotkeysToggle()
  setMasterEnabled(not hotkeysConfig.enabled)
end

schedule(50, elfHotkeysInit)

if modules and modules.game_bot then
  modules.game_bot.elfHotkeysOpen = elfHotkeysOpen
  modules.game_bot.elfHotkeysClose = elfHotkeysClose
  modules.game_bot.elfHotkeysEdit = elfHotkeysEdit
  modules.game_bot.elfHotkeysSave = elfHotkeysSave
  modules.game_bot.elfHotkeysStop = elfHotkeysStop
  modules.game_bot.elfHotkeysStart = elfHotkeysStart
  modules.game_bot.elfHotkeysToggle = elfHotkeysToggle
  modules.game_bot.elfHotkeysLoadPreset = elfHotkeysLoadPreset
  modules.game_bot.elfHotkeysCustom = true
end
