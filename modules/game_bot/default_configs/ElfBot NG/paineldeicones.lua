setDefaultTab("Main")

ImperialElfBot = ImperialElfBot or {}

if PainelDeIconesController and PainelDeIconesController.shutdown then
  PainelDeIconesController.shutdown()
end

local function cleanupStalePICIcons()
  local mapPanel = modules and modules.game_interface and modules.game_interface.gameMapPanel
  if not mapPanel or not mapPanel.getChildren then
    return
  end

  local children = mapPanel:getChildren() or {}
  for i = #children, 1, -1 do
    local child = children[i]
    local childId = child and child.getId and child:getId()
    if child and child.botIcon and type(childId) == "string" and childId:sub(1, 4) == "PIC_" then
      child:destroy()
    end
  end
end

cleanupStalePICIcons()

local function nowMs()
  return now or (g_clock and g_clock.millis and g_clock.millis()) or os.time() * 1000
end

local function deepcopy(value)
  if type(value) ~= "table" then return value end
  local copy = {}
  for k, v in pairs(value) do
    copy[k] = deepcopy(v)
  end
  return copy
end

local function normalizeText(text)
  return string.lower(tostring(text or ""))
end

local function buildBilingualTooltip(ptText, enText)
  local pt = tostring(ptText or "")
  local en = tostring(enText or "")
  if en == "" then
    en = pt
  end
  local language = type(storage) == "table" and storage.elfbotLanguageExplicit == true and tostring(storage.elfbotLanguage):lower() or "en"
  return (language == "en" or language == "eng" or language == "english") and en or pt
end

local function normalizeElfLanguage(language)
  language = tostring(language or ""):lower()
  if language == "en" or language == "eng" or language == "english" then
    return "en"
  end
  if language == "pt" or language == "br" or language == "portuguese" or language == "portugues" then
    return "pt"
  end
  return "en"
end

local function getElfLanguage()
  if type(storage) ~= "table" then
    return "en"
  end
  if storage.elfbotLanguageExplicit ~= true then
    storage.elfbotLanguage = "en"
    return "en"
  end
  storage.elfbotLanguage = normalizeElfLanguage(storage.elfbotLanguage)
  return storage.elfbotLanguage
end

local function setElfLanguage(language)
  if type(storage) == "table" then
    storage.elfbotLanguage = normalizeElfLanguage(language)
    storage.elfbotLanguageExplicit = true
  end
  if type(saveConfig) == "function" then
    pcall(saveConfig)
  end
  return getElfLanguage()
end

local function picText(ptText, enText)
  if getElfLanguage() == "en" then
    return enText or ptText
  end
  return ptText
end

if type(ImperialElfBot_GetLanguage) ~= "function" then
  function ImperialElfBot_GetLanguage()
    return getElfLanguage()
  end
end

if type(ImperialElfBot_SetLanguage) ~= "function" then
  function ImperialElfBot_SetLanguage(language)
    setElfLanguage(language)
    if PainelDeIconesController and PainelDeIconesController.refreshLanguage then
      pcall(PainelDeIconesController.refreshLanguage)
    end
    if ImperialElfBot and ImperialElfBot.refreshLanguage then
      pcall(ImperialElfBot.refreshLanguage)
    end
    return getElfLanguage()
  end
end

local function normalizeBoolFlag(value, defaultValue)
  if type(value) == "boolean" then
    return value
  end
  if type(value) == "number" then
    return value ~= 0
  end
  if type(value) == "string" then
    local text = value:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if text == "true" or text == "1" or text == "on" or text == "yes" then
      return true
    end
    if text == "false" or text == "0" or text == "off" or text == "no" or text == "" then
      return false
    end
  end
  return defaultValue == true
end

local function clamp(value, minValue, maxValue)
  local v = tonumber(value) or 0
  if minValue ~= nil and v < minValue then v = minValue end
  if maxValue ~= nil and v > maxValue then v = maxValue end
  return v
end

local function showMessage(text)
  if modules and modules.game_textmessage and modules.game_textmessage.displayGameMessage then
    modules.game_textmessage.displayGameMessage(text)
    return
  end
  print(text)
end

local function safeCall(fn, ...)
  if type(fn) ~= "function" then
    return true
  end
  local ok, err = pcall(fn, ...)
  if not ok then
    warn("[PainelIcones] " .. tostring(err))
  end
  return ok
end

local function getPlayer()
  if g_game and g_game.getLocalPlayer then
    return g_game.getLocalPlayer()
  end
  return nil
end

local function distanceChebyshev(posA, posB)
  if not posA or not posB then return 999 end
  return math.max(math.abs(posA.x - posB.x), math.abs(posA.y - posB.y))
end

local function useWithItem(itemId, target)
  if type(useWith) == "function" then
    useWith(itemId, target)
    return true
  end
  if type(usewith) == "function" then
    usewith(itemId, target)
    return true
  end
  return false
end

local function findItemById(itemId)
  if type(findItem) == "function" then
    return findItem(itemId)
  end
  if not g_game or not g_game.getContainers then
    return nil
  end
  for _, container in pairs(g_game.getContainers() or {}) do
    for _, item in ipairs(container:getItems()) do
      if item:getId() == itemId then
        return item
      end
    end
  end
  return nil
end

function parseItemIdListToSet(textValue, defaultIds)
  local set = {}

  local function resolveEntryId(entry)
    if entry == nil then return nil end
    if type(entry) == "number" or type(entry) == "string" then
      return tonumber(entry)
    end
    if type(entry) == "table" then
      return tonumber(entry.id or entry.itemId or entry[1])
    end
    if entry.getId then
      local ok, id = pcall(function() return entry:getId() end)
      if ok then
        return tonumber(id)
      end
    end
    return nil
  end

  local function consumeTableEntries(tbl)
    for _, entry in pairs(tbl or {}) do
      local id = resolveEntryId(entry)
      if id and id >= 100 then
        set[math.floor(id)] = true
      elseif type(entry) == "table" then
        consumeTableEntries(entry)
      end
    end
  end

  if type(textValue) == "table" then
    consumeTableEntries(textValue)
  else
    for rawToken in string.gmatch(tostring(textValue or ""), "%d+") do
      local id = tonumber(rawToken)
      if id and id >= 100 then
        set[math.floor(id)] = true
      end
    end
  end
  for _ in pairs(set) do
    return set
  end
  for _, id in ipairs(defaultIds or {}) do
    local n = tonumber(id)
    if n and n >= 100 then
      set[math.floor(n)] = true
    end
  end
  return set
end

function resolveFirstContainerSlotPos()
  local containers = getContainers and getContainers() or {}
  for _, container in pairs(containers or {}) do
    if container and container.getSlotPosition then
      local count = 0
      if container.getItemsCount then
        count = tonumber(container:getItemsCount()) or 0
      end
      local slotPos = container:getSlotPosition(count)
      if slotPos then
        return slotPos
      end
    end
  end
  return nil
end

function normalizeItemIdArray(value, defaultIds)
  local out = {}
  local seen = {}

  local function resolveEntryId(entry)
    if entry == nil then return nil end
    if type(entry) == "number" or type(entry) == "string" then
      return tonumber(entry)
    end
    if type(entry) == "table" then
      return tonumber(entry.id or entry.itemId or entry[1])
    end
    if entry.getId then
      local ok, id = pcall(function() return entry:getId() end)
      if ok then
        return tonumber(id)
      end
    end
    return nil
  end

  local function pushId(idValue)
    local id = resolveEntryId(idValue)
    if not id then return end
    id = math.floor(id)
    if id < 100 then return end
    if seen[id] then return end
    seen[id] = true
    out[#out + 1] = id
  end

  local function consumeTableEntries(tbl)
    local numericKeys = {}
    local otherKeys = {}
    for key, _ in pairs(tbl or {}) do
      if type(key) == "number" then
        numericKeys[#numericKeys + 1] = key
      else
        otherKeys[#otherKeys + 1] = key
      end
    end
    table.sort(numericKeys)

    for _, key in ipairs(numericKeys) do
      local entry = tbl[key]
      local id = resolveEntryId(entry)
      if id then
        pushId(id)
      elseif type(entry) == "table" then
        consumeTableEntries(entry)
      end
    end

    for _, key in ipairs(otherKeys) do
      local entry = tbl[key]
      local id = resolveEntryId(entry)
      if id then
        pushId(id)
      elseif type(entry) == "table" then
        consumeTableEntries(entry)
      end
    end
  end

  if type(value) == "table" then
    consumeTableEntries(value)
  elseif type(value) == "string" then
    for rawToken in string.gmatch(value, "[^,%s;]+") do
      pushId(rawToken)
    end
  else
    pushId(value)
  end

  if #out == 0 then
    for _, id in ipairs(defaultIds or {}) do
      pushId(id)
    end
  end

  return out
end

local function getAttackingTarget(maxDistance)
  if not g_game or not g_game.isAttacking or not g_game.getAttackingCreature then
    return nil
  end
  if not g_game.isAttacking() then
    return nil
  end
  local target = g_game.getAttackingCreature()
  local player = getPlayer()
  if not target or not player then
    return nil
  end
  local tPos = target:getPosition()
  local pPos = player:getPosition()
  if not tPos or not pPos or tPos.z ~= pPos.z then
    return nil
  end
  if maxDistance and distanceChebyshev(tPos, pPos) > maxDistance then
    return nil
  end
  return target
end

local function countNearbyMonsters(maxDistance)
  local player = getPlayer()
  local playerPos = player and player:getPosition()
  if not playerPos then
    return 0
  end

  local maxDist = clamp(tonumber(maxDistance) or 7, 1, 15)
  local count = 0
  for _, spec in ipairs(getSpectators() or {}) do
    if spec and spec.isMonster and spec:isMonster() then
      local specPos = spec:getPosition()
      if specPos and specPos.z == playerPos.z and distanceChebyshev(specPos, playerPos) <= maxDist then
        count = count + 1
      end
    end
  end
  return count
end

local function shouldRunByMonsterCount(params, fallbackDistance)
  local minMonsters = clamp(tonumber(params and params.minMonsters) or 1, 1, 50)
  if minMonsters <= 1 then
    return true
  end
  local range = tonumber(params and params.maxDistance) or tonumber(fallbackDistance) or 7
  return countNearbyMonsters(range) >= minMonsters
end

local function isPlayerCreature(creature)
  if not creature then return false end
  if creature.isPlayer and creature:isPlayer() then
    return true
  end
  if creature.isLocalPlayer and creature:isLocalPlayer() then
    return true
  end
  return false
end

local potHelper = {}

function potHelper.trimText(value)
  local text = tostring(value or "")
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  return text
end

function potHelper.normalizeNameKey(value)
  return normalizeText(potHelper.trimText(value or ""))
end

function potHelper.getLocalPlayerName()
  local player = getPlayer()
  if player and player.getName then
    local okName, playerName = pcall(function() return player:getName() end)
    if okName then
      return tostring(playerName or "")
    end
  end

  if type(name) == "function" then
    local okName, fallbackName = pcall(name)
    if okName then
      return tostring(fallbackName or "")
    end
  end

  return ""
end

function potHelper.getCreatureNameSafe(creature)
  if not creature or not creature.getName then
    return ""
  end
  local okName, creatureName = pcall(function() return creature:getName() end)
  if not okName then
    return ""
  end
  return tostring(creatureName or "")
end

function potHelper.findVisiblePlayerByName(nameText)
  local expectedName = potHelper.normalizeNameKey(nameText)
  if expectedName == "" then
    return nil
  end

  for _, creature in ipairs(getSpectators() or {}) do
    if isPlayerCreature(creature) then
      if potHelper.normalizeNameKey(potHelper.getCreatureNameSafe(creature)) == expectedName then
        return creature
      end
    end
  end

  return nil
end

function potHelper.isPartyOrGuildAllyCreature(creature)
  if not isPlayerCreature(creature) then
    return false
  end

  local hasPartyFlag = false
  if creature.isPartyMember then
    hasPartyFlag = true
    local okParty, partyValue = pcall(function() return creature:isPartyMember() end)
    if okParty and partyValue == true then
      return true
    end
  end

  local hasGuildFlag = false
  if creature.getEmblem then
    hasGuildFlag = true
    local okEmblem, emblemValue = pcall(function() return creature:getEmblem() end)
    if okEmblem and tonumber(emblemValue) == 1 then
      return true
    end
  end

  if not hasPartyFlag and not hasGuildFlag and type(isAlly) == "function" then
    local okAlly, allyValue = pcall(isAlly, creature)
    if okAlly and allyValue == true then
      return true
    end
  end

  return false
end

function potHelper.getHpPercentSafe()
  if type(hppercent) == "function" then
    local okHp, hpValue = pcall(hppercent)
    if okHp and type(hpValue) == "number" then
      return clamp(math.floor(hpValue), 0, 100)
    end
  end

  local player = getPlayer()
  if player and player.getHealthPercent then
    local okHp, hpValue = pcall(function() return player:getHealthPercent() end)
    if okHp and type(hpValue) == "number" then
      return clamp(math.floor(hpValue), 0, 100)
    end
  end

  return 100
end

function potHelper.getManaPercentSafe()
  if type(manapercent) == "function" then
    local okMana, manaValue = pcall(manapercent)
    if okMana and type(manaValue) == "number" then
      return clamp(math.floor(manaValue), 0, 100)
    end
  end

  local player = getPlayer()
  if player and player.getManaPercent then
    local okMana, manaValue = pcall(function() return player:getManaPercent() end)
    if okMana and type(manaValue) == "number" then
      return clamp(math.floor(manaValue), 0, 100)
    end
  end

  return 100
end

function potHelper.resolveOpenChannelId(channelKind, preferredNameOrId)
  local kind = potHelper.normalizeNameKey(channelKind)
  if kind ~= "party" and kind ~= "guild" then
    return nil
  end

  local preferred = potHelper.trimText(preferredNameOrId)
  if preferred ~= "" then
    local directId = tonumber(preferred)
    if directId and directId > 0 then
      return math.floor(directId)
    end
  end

  if type(getChannelId) == "function" then
    local okChannelId, channelId = pcall(getChannelId, kind)
    if okChannelId and tonumber(channelId) and tonumber(channelId) > 0 then
      return math.floor(tonumber(channelId))
    end
  end

  local channels = modules and modules.game_console and modules.game_console.channels or nil
  if type(channels) ~= "table" then
    return nil
  end

  local function findChannelByName(matchText, allowPartial)
    local expected = potHelper.normalizeNameKey(matchText)
    if expected == "" then
      return nil
    end

    for channelId, channelName in pairs(channels) do
      if type(channelName) == "string" then
        local normalizedName = potHelper.normalizeNameKey(channelName)
        local matched = (not allowPartial and normalizedName == expected)
          or (allowPartial and normalizedName:find(expected, 1, true) ~= nil)
        if matched then
          local parsed = tonumber(channelId)
          if parsed and parsed > 0 then
            return math.floor(parsed)
          end
        end
      end
    end

    return nil
  end

  if preferred ~= "" then
    local exact = findChannelByName(preferred, false)
    if exact then
      return exact
    end
    return findChannelByName(preferred, true)
  end

  local fallbackKeys = kind == "party" and {"party"} or {"guild chat", "guild"}
  for _, keyword in ipairs(fallbackKeys) do
    local exact = findChannelByName(keyword, false)
    if exact then
      return exact
    end
  end
  for _, keyword in ipairs(fallbackKeys) do
    local partial = findChannelByName(keyword, true)
    if partial then
      return partial
    end
  end

  return nil
end

function potHelper.sendTextToConfiguredChat(chatMode, guildChannelName, messageText)
  local mode = potHelper.normalizeNameKey(chatMode)
  local text = potHelper.trimText(messageText)
  if text == "" then
    return false, "mensagem vazia", nil
  end

  if mode == "party" or mode == "guild" then
    local channelId = potHelper.resolveOpenChannelId(mode, mode == "guild" and guildChannelName or "")
    if not channelId then
      return false, string.format("canal %s nao encontrado", mode), nil
    end

    if type(sayChannel) == "function" then
      local okSayChannel = pcall(sayChannel, channelId, text)
      if okSayChannel then
        return true, nil, channelId
      end
    end

    if g_game and g_game.talkChannel then
      local okTalkChannel = pcall(function()
        g_game.talkChannel(7, channelId, text)
      end)
      if okTalkChannel then
        return true, nil, channelId
      end
    end

    return false, "talkChannel indisponivel", channelId
  end

  if type(say) == "function" then
    say(text)
    return true, nil, 0
  end

  return false, "say indisponivel", 0
end

function potHelper.talkMatchesConfiguredChannel(chatMode, guildChannelName, talkChannelId)
  local mode = potHelper.normalizeNameKey(chatMode)
  local currentChannelId = tonumber(talkChannelId) or 0
  if mode == "party" or mode == "guild" then
    local expectedChannelId = potHelper.resolveOpenChannelId(mode, mode == "guild" and guildChannelName or "")
    if not expectedChannelId then
      return false
    end
    return currentChannelId == expectedChannelId
  end
  return currentChannelId == 0
end

function potHelper.messageStartsWithTrigger(textValue, triggerValue)
  local message = potHelper.normalizeNameKey(textValue)
  local trigger = potHelper.normalizeNameKey(triggerValue)
  if message == "" or trigger == "" then
    return false
  end
  if message == trigger then
    return true
  end
  if message:sub(1, #trigger) ~= trigger then
    return false
  end
  local nextChar = message:sub(#trigger + 1, #trigger + 1)
  if nextChar == "" then
    return true
  end
  return nextChar:match("[%s%p]") ~= nil
end

local function hasOtherPlayerNear(pos, radius)
  if not pos then return false end
  local localPlayer = getPlayer()
  local localName = localPlayer and localPlayer:getName() or name()
  for _, spec in ipairs(getSpectators() or {}) do
    if isPlayerCreature(spec) then
      local specName = spec.getName and spec:getName() or ""
      if specName ~= localName then
        local specPos = spec:getPosition()
        if specPos and specPos.z == pos.z and distanceChebyshev(specPos, pos) <= radius then
          return true
        end
      end
    end
  end
  return false
end

local function castSpell(spellText)
  local text = tostring(spellText or "")
  if text == "" then return false end
  say(text)
  return true
end

local function useItemOnTilePos(itemId, targetPos)
  if not g_map or not targetPos then return false end
  local tile = g_map.getTile(targetPos)
  if not tile then return false end
  local targetThing = tile:getTopUseThing() or tile:getTopThing() or tile:getGround()
  if not targetThing then return false end
  return useWithItem(itemId, targetThing)
end

local function getOffsetPos(basePos, offsetX, offsetY)
  if not basePos then return nil end
  return {x = basePos.x + offsetX, y = basePos.y + offsetY, z = basePos.z}
end

local function resolveGlobal(name)
  if type(name) ~= "string" or name == "" then
    return nil
  end

  if type(_G) == "table" and _G[name] ~= nil then
    return _G[name]
  end

  if type(getfenv) == "function" then
    local ok, env = pcall(getfenv, 0)
    if ok and type(env) == "table" and env[name] ~= nil then
      return env[name]
    end
  end

  return nil
end

local function isObjectLike(value)
  local valueType = type(value)
  return valueType == "table" or valueType == "userdata"
end

local function setExternalToggle(apiName, desiredState)
  local api = resolveGlobal(apiName)
  if not isObjectLike(api) then
    return false
  end

  if desiredState then
    if type(api.setOn) ~= "function" then
      return false
    end
    if pcall(api.setOn, true) then return true end
    if pcall(api.setOn) then return true end
    if pcall(api.setOn, api, true) then return true end
    if pcall(api.setOn, api) then return true end
    return false
  end

  if type(api.setOff) == "function" then
    if pcall(api.setOff) then return true end
    if pcall(api.setOff, api) then return true end
  end

  if type(api.setOn) == "function" then
    if pcall(api.setOn, false) then return true end
    if pcall(api.setOn, api, false) then return true end
  end
  return false
end

local function trySetOff(target)
  if not isObjectLike(target) or type(target.setOff) ~= "function" then
    return false
  end
  if pcall(target.setOff) then return true end
  if pcall(target.setOff, target) then return true end
  return false
end

local function trySetOn(target)
  if not isObjectLike(target) or type(target.setOn) ~= "function" then
    return false
  end
  if pcall(target.setOn, true) then return true end
  if pcall(target.setOn) then return true end
  if pcall(target.setOn, target, true) then return true end
  if pcall(target.setOn, target) then return true end
  return false
end

local function readToggleState(target)
  if not isObjectLike(target) then
    return nil
  end
  if type(target.isOn) == "function" then
    local ok, value = pcall(target.isOn, target)
    if ok and type(value) == "boolean" then
      return value
    end
    ok, value = pcall(target.isOn)
    if ok and type(value) == "boolean" then
      return value
    end
  end
  if type(target.getState) == "function" then
    local ok, value = pcall(target.getState, target)
    if ok and type(value) == "boolean" then
      return value
    end
    ok, value = pcall(target.getState)
    if ok and type(value) == "boolean" then
      return value
    end
  end
  if type(target.isOff) == "function" then
    local ok, value = pcall(target.isOff, target)
    if ok and type(value) == "boolean" then
      return not value
    end
    ok, value = pcall(target.isOff)
    if ok and type(value) == "boolean" then
      return not value
    end
  end
  return nil
end

local function readExternalToggleState(apiName)
  return readToggleState(resolveGlobal(apiName))
end

function sanitizePainelBridgeStorage()
  local current = storage and storage.painelDeIconesBridge
  if type(current) ~= "table" then
    storage.painelDeIconesBridge = {}
    return
  end

  local cleaned = {}
  for key, value in pairs(current) do
    if type(key) == "string" then
      cleaned[key] = value
    end
  end
  storage.painelDeIconesBridge = cleaned
end

function sanitizeGlobalConfigsStorage()
  if type(storage._configs) ~= "table" then
    storage._configs = {}
    return
  end

  local cleaned = {}
  for key, value in pairs(storage._configs) do
    if type(key) == "string" then
      cleaned[key] = value
    end
  end
  storage._configs = cleaned

  local function sanitizeConfigBranch(key)
    local branch = storage._configs[key]
    if type(branch) ~= "table" then
      return
    end
    local branchClean = {}
    for branchKey, branchValue in pairs(branch) do
      if type(branchKey) == "string" then
        branchClean[branchKey] = branchValue
      end
    end
    storage._configs[key] = branchClean
  end

  sanitizeConfigBranch("cavebot_configs")
  sanitizeConfigBranch("targetbot_configs")
end

function sanitizeGlobalIconsStorage()
  if type(storage._icons) ~= "table" then
    storage._icons = {}
    return
  end

  local cleaned = {}
  for rawKey, rawValue in pairs(storage._icons) do
    local key = nil
    if type(rawKey) == "string" then
      key = rawKey
    elseif type(rawKey) == "number" then
      key = tostring(math.floor(rawKey))
    end

    if key then
      local iconCfg = type(rawValue) == "table" and rawValue or {}
      local iconCfgClean = {}
      for cfgKey, cfgValue in pairs(iconCfg) do
        if type(cfgKey) == "string" then
          iconCfgClean[cfgKey] = cfgValue
        end
      end
      cleaned[key] = iconCfgClean
    end
  end
  storage._icons = cleaned
end

function sanitizeStorageRootObject(rootKey)
  local rootTable = storage and storage[rootKey]
  if type(rootTable) ~= "table" then
    return
  end

  local cleaned = {}
  for key, value in pairs(rootTable) do
    if type(key) == "string" then
      cleaned[key] = value
    end
  end
  storage[rootKey] = cleaned
end

function sanitizeJsonCompatibleValue(value, seen)
  if type(value) ~= "table" then
    return value
  end
  seen = seen or {}
  if seen[value] then
    return {}
  end
  seen[value] = true

  local hasStringKey = false
  local hasNumericKey = false
  local maxNumericKey = 0

  for key, _ in pairs(value) do
    if type(key) == "string" then
      hasStringKey = true
    elseif type(key) == "number" and key >= 1 and math.floor(key) == key then
      hasNumericKey = true
      if key > maxNumericKey then
        maxNumericKey = key
      end
    end
  end

  if hasNumericKey and not hasStringKey then
    local arr = {}
    for index = 1, maxNumericKey do
      if value[index] ~= nil then
        arr[index] = sanitizeJsonCompatibleValue(value[index], seen)
      end
    end
    seen[value] = nil
    return arr
  end

  local obj = {}
  for key, entry in pairs(value) do
    local outKey = nil
    if type(key) == "string" then
      outKey = key
    elseif type(key) == "number" then
      outKey = tostring(math.floor(key))
    end
    if outKey ~= nil and outKey ~= "" then
      obj[outKey] = sanitizeJsonCompatibleValue(entry, seen)
    end
  end
  seen[value] = nil
  return obj
end

function sanitizeStorageRootRecursive(rootKey)
  if type(rootKey) ~= "string" or rootKey == "" then
    return
  end
  if type(storage[rootKey]) ~= "table" then
    return
  end
  storage[rootKey] = sanitizeJsonCompatibleValue(storage[rootKey])
end

local function queueExternalBridgeToggle(key, enabled)
  if type(key) ~= "string" or key == "" then
    return
  end
  sanitizePainelBridgeStorage()
  storage.painelDeIconesBridge[key] = enabled == true
  storage.painelDeIconesBridge.updatedAt = nowMs()
end

local function readExternalBridgeDesired(key)
  if type(key) ~= "string" or key == "" then
    return nil
  end
  sanitizePainelBridgeStorage()
  local bridge = storage and storage.painelDeIconesBridge
  if type(bridge) ~= "table" or bridge[key] == nil then
    return nil
  end
  return bridge[key] == true
end

sanitizePainelBridgeStorage()
sanitizeGlobalConfigsStorage()
sanitizeGlobalIconsStorage()
sanitizeStorageRootObject("painelDeIcones")
sanitizeStorageRootObject("swapSetConfig")
sanitizeStorageRootObject("swapSetProfiles")
sanitizeStorageRootObject("ringAmuletSetup")
sanitizeStorageRootObject("novoAtkUltraSafe")
sanitizeStorageRootObject("novoFollow")
sanitizeStorageRootObject("novoNav")
sanitizeStorageRootObject("pvpSystem")
sanitizeStorageRootRecursive("painelDeIcones")
sanitizeStorageRootRecursive("swapSetConfig")
sanitizeStorageRootRecursive("swapSetProfiles")
sanitizeStorageRootRecursive("ringAmuletSetup")
sanitizeStorageRootRecursive("analyzer")

local function setAttackEnabledExternal(enabled)
  local turnOn = enabled == true
  if ImperialElfBot.isAttackEnabledExternal() == turnOn then
    if type(storage.novoAtkUltraSafe) ~= "table" then
      storage.novoAtkUltraSafe = {}
    end
    storage.novoAtkUltraSafe.ultraSafeEnabled = turnOn
    storage.novoAtkUltraSafe.enabled = turnOn
    return true
  end

  queueExternalBridgeToggle("attackDesired", turnOn)

  if type(setAttackEnabled) == "function" then
    pcall(setAttackEnabled, turnOn)
  end

  if type(storage.novoAtkUltraSafe) ~= "table" then
    storage.novoAtkUltraSafe = {}
  end
  storage.novoAtkUltraSafe.ultraSafeEnabled = turnOn
  storage.novoAtkUltraSafe.enabled = turnOn

  if not turnOn and type(storage.lostSystem) == "table" then
    storage.lostSystem.enabled = false
  end
  return true
end

ImperialElfBot.isAttackEnabledExternal = function()
  local cfg = storage.novoAtkUltraSafe
  if type(cfg) ~= "table" then
    return false
  end
  if cfg.ultraSafeEnabled ~= nil then
    return normalizeBoolFlag(cfg.ultraSafeEnabled, false)
  end
  return normalizeBoolFlag(cfg.enabled, false)
end

local function setHpToolsEnabledExternal(enabled)
  local turnOn = enabled == true
  if ImperialElfBot.isHpToolsEnabledExternal() == turnOn and normalizeBoolFlag(storage.toolsEnabled, false) == turnOn then
    storage.healingSystemEnabled = turnOn
    storage.toolsEnabled = turnOn
    return true
  end

  queueExternalBridgeToggle("hpToolsDesired", turnOn)

  if type(setHealingEnabled) == "function" then
    pcall(setHealingEnabled, turnOn)
  end

  storage.healingSystemEnabled = turnOn
  storage.toolsEnabled = turnOn
  return true
end

ImperialElfBot.isHpToolsEnabledExternal = function()
  return normalizeBoolFlag(storage.healingSystemEnabled, false)
end

local function setFollowEnabledExternal(enabled)
  local turnOn = enabled == true
  if ImperialElfBot.isFollowEnabledExternal() == turnOn then
    return true
  end

  queueExternalBridgeToggle("followDesired", turnOn)

  if setExternalToggle("NovoFollowController", turnOn) then
    return true
  end

  if type(storage.novoFollow) == "table" then
    storage.novoFollow.enabled = turnOn
    storage.novoFollow.followEnabled = turnOn
  end

  if type(storage.novoNav) == "table" then
    storage.novoNav.follow = storage.novoNav.follow or {}
    storage.novoNav.follow.enabled = turnOn
    storage.novoNav.states = storage.novoNav.states or {}
    storage.novoNav.states.followEnabled = turnOn
  end

  local followMacro = resolveGlobal("followMacro")
  if turnOn then
    trySetOn(followMacro)
  else
    trySetOff(followMacro)
    trySetOff(resolveGlobal("ultimateFollow"))
  end

  return true
end

ImperialElfBot.isFollowEnabledExternal = function()
  local controllerState = readExternalToggleState("NovoFollowController")
  if type(controllerState) == "boolean" then
    return controllerState
  end

  local macroState = readToggleState(resolveGlobal("followMacro"))
  if type(macroState) == "boolean" then
    return macroState
  end

  if type(storage.novoFollow) == "table" then
    return normalizeBoolFlag(storage.novoFollow.enabled, false)
      and normalizeBoolFlag(storage.novoFollow.followEnabled, true)
  end
  if type(storage.novoNav) == "table" and type(storage.novoNav.follow) == "table" then
    return normalizeBoolFlag(storage.novoNav.enabled, false)
      and normalizeBoolFlag(storage.novoNav.follow.enabled, false)
  end
  return false
end

local function setNavigationEnabledExternal(enabled)
  local turnOn = enabled == true
  if ImperialElfBot.isNavigationEnabledExternal() == turnOn then
    if type(storage.novoFollow) == "table" then
      if turnOn then
        storage.novoFollow.enabled = true
      end
      storage.novoFollow.navLeaderEnabled = turnOn
    elseif type(storage.novoNav) == "table" then
      storage.novoNav.enabled = turnOn
    end
    return true
  end

  queueExternalBridgeToggle("navDesired", turnOn)

  if setExternalToggle("NovoNavController", turnOn) then
    return true
  end

  if type(storage.novoFollow) == "table" then
    if turnOn then
      storage.novoFollow.enabled = true
    end
    storage.novoFollow.navLeaderEnabled = turnOn
  end

  if type(storage.novoNav) == "table" then
    storage.novoNav.enabled = turnOn
    if not turnOn then
      storage.novoNav.follow = storage.novoNav.follow or {}
      storage.novoNav.follow.enabled = false
      storage.novoNav.attack = storage.novoNav.attack or {}
      storage.novoNav.attack.enabled = false
      storage.novoNav.states = storage.novoNav.states or {}
      storage.novoNav.states.followEnabled = false
      storage.novoNav.states.attackLeaderEnabled = false
    end
  end

  if not turnOn then
    trySetOff(resolveGlobal("targetAtkMacro"))
    trySetOff(resolveGlobal("areaAtkMacro"))
    trySetOff(resolveGlobal("lyzeMacro"))
  end

  return true
end

ImperialElfBot.isNavigationEnabledExternal = function()
  local controllerState = readExternalToggleState("NovoNavController")
  if type(controllerState) == "boolean" then
    return controllerState
  end

  if type(storage.novoFollow) == "table" then
    return normalizeBoolFlag(storage.novoFollow.enabled, false)
      and normalizeBoolFlag(storage.novoFollow.navLeaderEnabled, true)
  end

  if type(storage.novoNav) ~= "table" then
    return false
  end
  return normalizeBoolFlag(storage.novoNav.enabled, false)
end

local function setPvpEnabledExternal(enabled)
  local turnOn = enabled == true
  if ImperialElfBot.isPvpEnabledExternal() == turnOn then
    return true
  end

  queueExternalBridgeToggle("pvpDesired", turnOn)

  if setExternalToggle("PvpSystemController", turnOn) then
    return true
  end
  if type(storage.pvpSystem) ~= "table" then
    storage.pvpSystem = {}
  end
  if type(storage.pvpSystem.pushSystem) ~= "table" then
    storage.pvpSystem.pushSystem = {}
  end
  storage.pvpSystem.pushSystem.enabled = turnOn
  return true
end

ImperialElfBot.isPvpEnabledExternal = function()
  local controllerState = readExternalToggleState("PvpSystemController")
  if type(controllerState) == "boolean" then
    return controllerState
  end

  return type(storage.pvpSystem) == "table"
    and type(storage.pvpSystem.pushSystem) == "table"
    and normalizeBoolFlag(storage.pvpSystem.pushSystem.enabled, false)
end

local function ensureRingAmuletSetup()
  if type(storage.ringAmuletSetup) ~= "table" then
    storage.ringAmuletSetup = {}
  end
  local cfg = storage.ringAmuletSetup
  if cfg.ringsEnabled == nil then
    if cfg.enabled == nil then
      cfg.ringsEnabled = false
    else
      cfg.ringsEnabled = normalizeBoolFlag(cfg.enabled, false)
    end
  end
  if cfg.amuletsEnabled == nil then
    if cfg.enabled == nil then
      cfg.amuletsEnabled = false
    else
      cfg.amuletsEnabled = normalizeBoolFlag(cfg.enabled, false)
    end
  end
  cfg.ringsEnabled = normalizeBoolFlag(cfg.ringsEnabled, false)
  cfg.amuletsEnabled = normalizeBoolFlag(cfg.amuletsEnabled, false)
  cfg.enabled = cfg.ringsEnabled or cfg.amuletsEnabled
  return cfg
end

local function setRingEnabledExternal(enabled)
  local turnOn = enabled == true
  if ImperialElfBot.isRingEnabledExternal() == turnOn then
    local cfg = ensureRingAmuletSetup()
    cfg.ringsEnabled = turnOn
    cfg.enabled = cfg.ringsEnabled or cfg.amuletsEnabled
    return true
  end

  queueExternalBridgeToggle("ringDesired", turnOn)
  setExternalToggle("RingModuleController", turnOn)

  local cfg = ensureRingAmuletSetup()
  cfg.ringsEnabled = turnOn
  cfg.enabled = cfg.ringsEnabled or cfg.amuletsEnabled
  return true
end

ImperialElfBot.isRingEnabledExternal = function()
  local controllerState = readExternalToggleState("RingModuleController")
  if type(controllerState) == "boolean" then
    return controllerState
  end
  local cfg = ensureRingAmuletSetup()
  return normalizeBoolFlag(cfg.ringsEnabled, false)
end

local function setAmuletEnabledExternal(enabled)
  local turnOn = enabled == true
  if ImperialElfBot.isAmuletEnabledExternal() == turnOn then
    local cfg = ensureRingAmuletSetup()
    cfg.amuletsEnabled = turnOn
    cfg.enabled = cfg.ringsEnabled or cfg.amuletsEnabled
    return true
  end

  queueExternalBridgeToggle("amuletDesired", turnOn)
  setExternalToggle("AmuletModuleController", turnOn)

  local cfg = ensureRingAmuletSetup()
  cfg.amuletsEnabled = turnOn
  cfg.enabled = cfg.ringsEnabled or cfg.amuletsEnabled
  return true
end

ImperialElfBot.isAmuletEnabledExternal = function()
  local controllerState = readExternalToggleState("AmuletModuleController")
  if type(controllerState) == "boolean" then
    return controllerState
  end
  local cfg = ensureRingAmuletSetup()
  return normalizeBoolFlag(cfg.amuletsEnabled, false)
end

local function getSwapSetConfigRef()
  if type(storage.swapSetConfig) ~= "table" then
    if type(storage.SwapSetMana) == "table" then
      storage.swapSetConfig = storage.SwapSetMana
    else
      storage.swapSetConfig = {}
    end
  end
  storage.SwapSetMana = storage.swapSetConfig
  return storage.swapSetConfig
end

local function setSwapSetEnabledExternal(enabled)
  local turnOn = enabled == true
  local cfg = getSwapSetConfigRef()
  if ImperialElfBot.isSwapSetEnabledExternal() == turnOn then
    cfg.autoSwapEnabled = turnOn
    local controller = resolveGlobal("SwapSetController")
    if type(controller) == "table" and type(controller.refresh) == "function" then
      pcall(controller.refresh)
    end
    return true
  end

  queueExternalBridgeToggle("swapSetDesired", turnOn)

  cfg.autoSwapEnabled = turnOn
  local controller = resolveGlobal("SwapSetController")
  if type(controller) == "table" and type(controller.refresh) == "function" then
    pcall(controller.refresh)
  end
  return true
end

ImperialElfBot.isSwapSetEnabledExternal = function()
  local cfg = getSwapSetConfigRef()
  return normalizeBoolFlag(cfg.autoSwapEnabled, false)
end

local function getCavebotApi()
  if isObjectLike(CaveBot) then
    return CaveBot
  end
  local resolved = resolveGlobal("CaveBot")
  if isObjectLike(resolved) then
    return resolved
  end
  return nil
end

local function setCavebotEnabledExternal(enabled)
  local turnOn = enabled == true
  queueExternalBridgeToggle("cavebotDesired", turnOn)
  sanitizeGlobalConfigsStorage()
  if type(storage._configs.cavebot_configs) ~= "table" then
    storage._configs.cavebot_configs = {}
  end
  storage._configs.cavebot_configs.enabled = turnOn
  local api = getCavebotApi()
  if isObjectLike(api) then
    if turnOn then
      if trySetOn(api) then
        return true
      end
    else
      if trySetOff(api) then
        return true
      end
    end
  end
  return setExternalToggle("CaveBot", turnOn)
end

local function isCavebotEnabledExternal(moduleState)
  local api = getCavebotApi()
  local apiState = readToggleState(api)
  if type(apiState) == "boolean" then
    return apiState
  end
  local externalState = readExternalToggleState("CaveBot")
  if type(externalState) == "boolean" then
    return externalState
  end
  local cfgRoot = storage and storage._configs
  local cfg = type(cfgRoot) == "table" and cfgRoot.cavebot_configs or nil
  if type(cfg) == "table" and cfg.enabled ~= nil then
    return normalizeBoolFlag(cfg.enabled, false)
  end
  local bridgeState = readExternalBridgeDesired("cavebotDesired")
  if type(bridgeState) == "boolean" then
    return bridgeState
  end
  if type(moduleState) == "table" and type(moduleState.enabled) == "boolean" then
    return moduleState.enabled
  end
  return false
end

local function getTargetbotApi()
  if isObjectLike(TargetBot) then
    return TargetBot
  end
  local resolved = resolveGlobal("TargetBot")
  if isObjectLike(resolved) then
    return resolved
  end
  return nil
end

local function setTargetbotEnabledExternal(enabled)
  local turnOn = enabled == true
  queueExternalBridgeToggle("targetbotDesired", turnOn)
  sanitizeGlobalConfigsStorage()
  if type(storage._configs.targetbot_configs) ~= "table" then
    storage._configs.targetbot_configs = {}
  end
  storage._configs.targetbot_configs.enabled = turnOn
  local api = getTargetbotApi()
  if isObjectLike(api) then
    if turnOn then
      if trySetOn(api) then
        return true
      end
    else
      if trySetOff(api) then
        return true
      end
    end
  end
  return setExternalToggle("TargetBot", turnOn)
end

local function isTargetbotEnabledExternal(moduleState)
  local api = getTargetbotApi()
  local apiState = readToggleState(api)
  if type(apiState) == "boolean" then
    return apiState
  end
  local externalState = readExternalToggleState("TargetBot")
  if type(externalState) == "boolean" then
    return externalState
  end
  local cfgRoot = storage and storage._configs
  local cfg = type(cfgRoot) == "table" and cfgRoot.targetbot_configs or nil
  if type(cfg) == "table" and cfg.enabled ~= nil then
    return normalizeBoolFlag(cfg.enabled, false)
  end
  local bridgeState = readExternalBridgeDesired("targetbotDesired")
  if type(bridgeState) == "boolean" then
    return bridgeState
  end
  if type(moduleState) == "table" and type(moduleState.enabled) == "boolean" then
    return moduleState.enabled
  end
  return false
end

local function syncAddIconState(iconId, enabled)
  if type(iconId) ~= "string" or iconId == "" then
    return
  end
  sanitizeGlobalIconsStorage()
  if type(storage._icons[iconId]) ~= "table" then
    storage._icons[iconId] = {}
  end
  storage._icons[iconId].enabled = enabled == true
end

local function savePainelProfileStorage()
  if type(saveConfig) == "function" then
    pcall(saveConfig)
  end
end

local function ensureIconStorageConfig(iconId)
  if type(iconId) ~= "string" or iconId == "" then
    return nil
  end
  sanitizeGlobalIconsStorage()
  if type(storage._icons[iconId]) ~= "table" then
    storage._icons[iconId] = {}
  end
  return storage._icons[iconId]
end

local function getIconPositionPercent(iconId)
  local cfg = ensureIconStorageConfig(iconId)
  if not cfg then
    return 0, 0
  end
  local px = clamp((tonumber(cfg.x) or 0) * 100, 0, 100)
  local py = clamp((tonumber(cfg.y) or 0) * 100, 0, 100)
  return math.floor(px + 0.5), math.floor(py + 0.5)
end

local function applyIconPositionPercent(iconWidget, iconId, posXPercent, posYPercent)
  local cfg = ensureIconStorageConfig(iconId)
  if not cfg then
    return
  end
  cfg.x = clamp(tonumber(posXPercent) or 0, 0, 100) / 100
  cfg.y = clamp(tonumber(posYPercent) or 0, 0, 100) / 100

  if iconWidget and iconWidget.onGeometryChange then
    pcall(iconWidget.onGeometryChange, iconWidget)
  end
end

local function syncIconPositionPercentFromWidget(iconWidget, iconId)
  local cfg = ensureIconStorageConfig(iconId)
  if not cfg or not iconWidget or type(iconWidget.getParent) ~= "function" then
    return getIconPositionPercent(iconId)
  end

  local parent = iconWidget:getParent()
  if not parent or type(parent.getRect) ~= "function" then
    return getIconPositionPercent(iconId)
  end

  local parentRect = parent:getRect()
  if type(parentRect) ~= "table" then
    return getIconPositionPercent(iconId)
  end

  local iconX = tonumber(iconWidget:getX()) or tonumber(parentRect.x) or 0
  local iconY = tonumber(iconWidget:getY()) or tonumber(parentRect.y) or 0
  local parentX = tonumber(parentRect.x) or 0
  local parentY = tonumber(parentRect.y) or 0
  local width = math.max(1, (tonumber(parentRect.width) or 0) - (tonumber(iconWidget:getWidth()) or 0))
  local height = math.max(1, (tonumber(parentRect.height) or 0) - (tonumber(iconWidget:getHeight()) or 0))

  local posXPercent = clamp(((iconX - parentX) / width) * 100, 0, 100)
  local posYPercent = clamp(((iconY - parentY) / height) * 100, 0, 100)

  if iconWidget.breakAnchors and iconWidget.addAnchor then
    iconWidget:breakAnchors()
    iconWidget:addAnchor(AnchorHorizontalCenter, "parent", AnchorHorizontalCenter)
    iconWidget:addAnchor(AnchorVerticalCenter, "parent", AnchorVerticalCenter)
  end

  applyIconPositionPercent(iconWidget, iconId, posXPercent, posYPercent)
  return getIconPositionPercent(iconId)
end

g_ui.loadUIFromString([[
PICModuleRow < Panel
  height: 36
  margin-top: 2
  background-color: #4e4e4e
  border-width: 1
  border-color: #666666

  BotItem
    id: iconItem
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 4
    size: 24 24
    selectable: false
    editable: false

  Label
    id: statusLabel
    anchors.top: parent.top
    anchors.right: parent.right
    margin-top: 2
    margin-right: 6
    width: 46
    text-align: center
    color: #ef4444
    font: verdana-11px-rounded

  Label
    id: nameLabel
    anchors.left: iconItem.right
    anchors.top: parent.top
    anchors.right: statusLabel.left
    margin-left: 6
    margin-top: 2
    text-align: left
    color: #f0f0f0
    font: verdana-11px-rounded

  Label
    id: categoryLabel
    anchors.left: nameLabel.left
    anchors.top: nameLabel.bottom
    anchors.right: statusLabel.left
    margin-top: 0
    text-align: left
    color: #bfc8d3
    font: verdana-11px-rounded

  Label
    id: hintLabel
    anchors.left: nameLabel.left
    anchors.top: categoryLabel.bottom
    anchors.right: statusLabel.left
    margin-top: 0
    height: 0
    text: ""
    text-align: left
    color: #00000000
    font: verdana-11px-rounded

PICSetupTextRow < Panel
  height: 24
  margin-top: 2

  Label
    id: label
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 158
    height: 16
    color: #dbe8f5
    text-align: left
    font: verdana-11px-rounded

  TextEdit
    id: edit
    anchors.left: label.right
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 6
    height: 18
    background-color: #4e4e4e
    border-width: 1
    border-color: #666666
    color: #ffffff
    text-align: left
    font: verdana-11px-rounded

PICSetupNumberRow < Panel
  height: 24
  margin-top: 2

  Label
    id: label
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 158
    height: 16
    color: #dbe8f5
    text-align: left
    font: verdana-11px-rounded

  SpinBox
    id: spin
    anchors.left: label.right
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 6
    height: 18
    editable: true
    focusable: true
    text-align: center
    font: verdana-11px-rounded

PICSetupCheckRow < Panel
  height: 22
  margin-top: 2

  CheckBox
    id: check
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    color: #dbe8f5
    font: verdana-11px-rounded

PICSetupComboRow < Panel
  height: 24
  margin-top: 2

  Label
    id: label
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 158
    height: 16
    color: #dbe8f5
    text-align: left
    font: verdana-11px-rounded

  ComboBox
    id: combo
    anchors.left: label.right
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 6
    height: 18
    background-color: #4e4e4e
    border-width: 1
    border-color: #666666
    color: #ffffff
    font: verdana-11px-rounded

PICSetupItemRow < Panel
  height: 24
  margin-top: 2

  Label
    id: label
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 158
    height: 16
    color: #dbe8f5
    text-align: left
    font: verdana-11px-rounded

  BotItem
    id: item
    anchors.left: label.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 6
    size: 20 20

PICSetupIconIdentityRow < Panel
  height: 24
  margin-top: 2

  Label
    id: label
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 82
    height: 16
    color: #dbe8f5
    text-align: left
    font: verdana-11px-rounded

  TextEdit
    id: edit
    anchors.left: label.right
    anchors.right: item.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 6
    margin-right: 6
    height: 18
    background-color: #4e4e4e
    border-width: 1
    border-color: #666666
    color: #ffffff
    text-align: left
    font: verdana-11px-rounded

  BotItem
    id: item
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    size: 20 20

PICSetupInfoRow < Panel
  height: 128
  margin-top: 6
  background-color: #4e4e4e
  border-width: 1
  border-color: #666666
  padding-left: 4
  padding-right: 4
  padding-top: 8
  padding-bottom: 6

  Label
    id: text
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    margin-left: 2
    margin-right: 2
    margin-top: 2
    margin-bottom: 2
    color: #dbe8f5
    text-wrap: false
    text-auto-resize: false
    text-align: left
    font: verdana-11px-rounded

PainelDeIconesWindow < MainWindow
  text: Painel de Icones
  size: 370 438
  visible: false
  @onEscape: self:hide()

  Panel
    id: header
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 50
    margin-top: 6
    margin-left: 8
    margin-right: 8

    Label
      id: descriptionLabel
      anchors.top: parent.top
      anchors.left: parent.left
      height: 0
      text: ""
      color: #00000000
      font: verdana-11px-rounded
      text-align: left

    Label
      id: countLabel
      anchors.top: parent.top
      anchors.right: parent.right
      margin-top: 1
      margin-right: 168
      width: 110
      height: 14
      text: ""
      color: #9aa6b2
      font: verdana-11px-rounded
      text-align: right

    Button
      id: enButton
      anchors.top: parent.top
      anchors.right: parent.right
      margin-top: 0
      margin-right: 102
      width: 30
      height: 17
      text: EN
      font: verdana-11px-rounded

    Button
      id: ptButton
      anchors.top: parent.top
      anchors.right: enButton.left
      margin-top: 0
      margin-right: 3
      width: 30
      height: 17
      text: PT
      font: verdana-11px-rounded

    Label
      id: searchLabel
      anchors.left: parent.left
      anchors.top: parent.top
      margin-top: 1
      width: 58
      text: Busca:
      color: #9aa6b2
      font: verdana-11px-rounded

    Label
      id: categoryLabel
      anchors.right: parent.right
      anchors.top: parent.top
      margin-top: 1
      width: 96
      text: Categoria:
      color: #9aa6b2
      font: verdana-11px-rounded
      text-align: right

    ComboBox
      id: categoryCombo
      anchors.right: parent.right
      anchors.top: categoryLabel.bottom
      margin-top: 2
      width: 96
      height: 20
      background-color: #4e4e4e
      border-width: 1
      border-color: #666666
      color: #ffffff
      font: verdana-11px-rounded

    TextEdit
      id: searchEdit
      anchors.left: parent.left
      anchors.right: categoryCombo.left
      anchors.top: searchLabel.bottom
      margin-top: 2
      margin-right: 8
      height: 20
      background-color: #4e4e4e
      border-width: 1
      border-color: #666666
      color: #ffffff
      text-align: left
      font: verdana-11px-rounded

  VerticalScrollBar
    id: modulesScroll
    anchors.top: header.bottom
    anchors.right: parent.right
    anchors.bottom: footer.top
    margin-top: 4
    margin-right: 6
    step: 24
    pixels-scroll: true

  ScrollablePanel
    id: modulesList
    anchors.top: header.bottom
    anchors.left: parent.left
    anchors.right: modulesScroll.left
    anchors.bottom: footer.top
    margin-top: 4
    margin-left: 8
    margin-right: 4
    margin-bottom: 4
    background-color: #4e4e4e
    border-width: 1
    border-color: #676d75
    padding-left: 2
    padding-right: 2
    padding-top: 1
    padding-bottom: 1
    vertical-scrollbar: modulesScroll
    layout:
      type: verticalBox
      spacing: 2

  Panel
    id: footer
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 22
    margin-left: 8
    margin-right: 8
    margin-bottom: 6

    Button
      id: clearFilterButton
      text: Limpar filtros
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      size: 86 17

    Button
      id: toggleAllVisibilityButton
      text: Ocultar todos
      anchors.left: clearFilterButton.right
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 4
      size: 92 17

    Button
      id: helpButton
      text: Ajuda
      anchors.left: toggleAllVisibilityButton.right
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 4
      size: 52 17

    Label
      id: hintLabel
      anchors.left: helpButton.right
      anchors.right: closeButton.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 6
      margin-right: 8
      text: Esq: show/hide | Dir: setup
      color: #9aa6b2
      font: verdana-11px-rounded
      text-align: center

    Button
      id: closeButton
      text: Fechar
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      size: 72 17

PainelDeIconesSetupWindow < MainWindow
  text: Setup de Icone
  size: 392 458
  visible: false
  @onEscape: self:hide()

  Panel
    id: header
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 86
    margin-top: 6
    margin-left: 8
    margin-right: 8

    Label
      id: titleLabel
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      text: Modulo
      color: #dbe8f5
      font: verdana-11px-rounded
      text-align: left

    Label
      id: metaLabel
      anchors.top: titleLabel.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      margin-top: 2
      text: Categoria
      color: #9aa6b2
      font: verdana-11px-rounded
      text-align: left

    Label
      id: descriptionLabel
      anchors.top: metaLabel.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-top: 2
      text: Descricao
      color: #9aa6b2
      font: verdana-11px-rounded
      text-align: left
      text-wrap: true
      text-auto-resize: false

  Panel
    id: contentPanel
    anchors.top: header.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: footer.top
    margin-top: 4
    margin-left: 7
    margin-right: 7
    margin-bottom: 4
    background-color: #4e4e4e
    border-width: 1
    border-color: #676d75
    padding-left: 4
    padding-right: 4
    padding-top: 2
    padding-bottom: 2

    VerticalScrollBar
      id: setupScroll
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      step: 14
      pixels-scroll: false

    ScrollablePanel
      id: setupList
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: setupScroll.left
      anchors.bottom: parent.bottom
      margin-right: 4
      background-color: #4e4e4e
      border-width: 1
      border-color: #707985
      padding-left: 3
      padding-right: 3
      padding-top: 2
      padding-bottom: 2
      vertical-scrollbar: setupScroll
      layout:
        type: verticalBox
        spacing: 1

  Panel
    id: footer
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 25
    margin-left: 8
    margin-right: 8
    margin-bottom: 6

    Button
      id: resetButton
      text: Resetar
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      size: 80 19

    Button
      id: saveButton
      text: Salvar
      anchors.right: closeButton.left
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 6
      size: 80 19

    Button
      id: closeButton
      text: Fechar
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      size: 80 19
]])

if type(storage.painelDeIcones) ~= "table" then
  storage.painelDeIcones = {}
end
local panelStorage = storage.painelDeIcones
for key, _ in pairs(panelStorage) do
  if type(key) ~= "string" then
    panelStorage[key] = nil
  end
end
if type(panelStorage.modules) ~= "table" then
  panelStorage.modules = {}
end
if type(panelStorage.ui) ~= "table" then
  panelStorage.ui = {}
end
for key, _ in pairs(panelStorage.ui) do
  if type(key) ~= "string" then
    panelStorage.ui[key] = nil
  end
end
if panelStorage.ui.search == nil then
  panelStorage.ui.search = ""
else
  panelStorage.ui.search = tostring(panelStorage.ui.search)
end
if panelStorage.ui.category == nil then
  panelStorage.ui.category = "Todos"
else
  panelStorage.ui.category = tostring(panelStorage.ui.category)
end

local moduleDefinitions = {
  {
    key = "sdTarget",
    title = "Attack Rune",
    category = "Ataque",
    iconId = 3155,
    interval = 220,
    description = "Usa SD no target atual quando as condicoes forem atendidas.",
    tags = {"sd", "runa", "ataque"},
    fields = {
      {id = "runeId", type = "number", label = "Runa ID", default = 3155, min = 100, max = 50000},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 10, min = 0, max = 100},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 180, min = 50, max = 5000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end
      local target = getAttackingTarget(params.maxDistance)
      if not target then return end
      if not useWithItem(params.runeId, target) then return end
      if params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "uhSelf",
    title = "UH Self",
    category = "Defesa",
    iconId = 3161,
    interval = 120,
    description = "Usa UH no personagem quando o HP cair abaixo do limite.",
    tags = {"uh", "cura", "defesa"},
    fields = {
      {id = "runeId", type = "number", label = "Runa UH ID", default = 3161, min = 100, max = 50000},
      {id = "hpPercent", type = "number", label = "HP maximo (%)", default = 55, min = 1, max = 99},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 0, min = 0, max = 100},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 350, min = 50, max = 5000}
    },
    onTick = function(params)
      if hppercent() > params.hpPercent then return end
      if manapercent() < params.manaMin then return end
      local player = getPlayer()
      if not player then return end
      if not useWithItem(params.runeId, player) then return end
      if params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "paralyzeRune",
    title = "Paralyze",
    category = "Ataque",
    iconId = 3160,
    interval = 200,
    description = "Usa paralyze rune no target atual.",
    tags = {"paralyze", "runa", "ataque"},
    fields = {
      {id = "runeId", type = "number", label = "Runa ID", default = 3160, min = 100, max = 50000},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 20, min = 0, max = 100},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 250, min = 50, max = 5000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end
      local target = getAttackingTarget(params.maxDistance)
      if not target then return end
      if not useWithItem(params.runeId, target) then return end
      if params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "sdRune",
    title = "SD",
    category = "Ataque",
    iconId = 3155,
    interval = 220,
    description = "Usa SD no target atual.",
    tags = {"sd", "runa", "ataque"},
    fields = {
      {id = "runeId", type = "number", label = "Runa ID", default = 3155, min = 100, max = 50000},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 10, min = 0, max = 100},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 180, min = 50, max = 5000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end
      local target = getAttackingTarget(params.maxDistance)
      if not target then return end
      if not useWithItem(params.runeId, target) then return end
      if params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "avalancheRune",
    title = "Avalanche",
    category = "Ataque",
    iconId = 3161,
    interval = 260,
    description = "Usa Avalanche no target atual.",
    tags = {"avalanche", "runa", "ataque"},
    fields = {
      {id = "runeId", type = "number", label = "Runa ID", default = 3161, min = 100, max = 50000},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 10, min = 0, max = 100},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 220, min = 50, max = 5000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end
      local target = getAttackingTarget(params.maxDistance)
      if not target then return end
      if not useWithItem(params.runeId, target) then return end
      if params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "stoneShowerRune",
    title = "StoneShower",
    category = "Ataque",
    iconId = 3175,
    interval = 260,
    description = "Usa Stone Shower no target atual.",
    tags = {"stoneshower", "runa", "ataque"},
    fields = {
      {id = "runeId", type = "number", label = "Runa ID", default = 3175, min = 100, max = 50000},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 10, min = 0, max = 100},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 220, min = 50, max = 5000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end
      local target = getAttackingTarget(params.maxDistance)
      if not target then return end
      if not useWithItem(params.runeId, target) then return end
      if params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "thunderstormRune",
    title = "Thunderstorm",
    category = "Ataque",
    iconId = 3202,
    interval = 260,
    description = "Usa Thunderstorm no target atual.",
    tags = {"thunderstorm", "runa", "ataque"},
    fields = {
      {id = "runeId", type = "number", label = "Runa ID", default = 3202, min = 100, max = 50000},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 10, min = 0, max = 100},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 220, min = 50, max = 5000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end
      local target = getAttackingTarget(params.maxDistance)
      if not target then return end
      if not useWithItem(params.runeId, target) then return end
      if params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "gfbRune",
    title = "Great Fire Ball",
    category = "Ataque",
    iconId = 3191,
    interval = 260,
    description = "Usa Great Fire Ball no target atual.",
    tags = {"gfb", "runa", "ataque"},
    fields = {
      {id = "runeId", type = "number", label = "Runa ID", default = 3191, min = 100, max = 50000},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 10, min = 0, max = 100},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 220, min = 50, max = 5000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end
      local target = getAttackingTarget(params.maxDistance)
      if not target then return end
      if not useWithItem(params.runeId, target) then return end
      if params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "knightAttackSpell",
    title = "Knight Spell",
    category = "Ataque",
    iconId = 3271,
    interval = 240,
    description = "Spell de ataque para Knight (editavel).",
    tags = {"knight", "spell", "ataque"},
    fields = {
      {id = "spell", type = "text", label = "Spell", default = "exori"},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 15, min = 0, max = 100},
      {id = "requireTarget", type = "bool", label = "Exigir target", default = true},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 1, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos cast (ms)", default = 900, min = 100, max = 8000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end
      if params.requireTarget then
        local target = getAttackingTarget(params.maxDistance)
        if not target then return end
      end
      if not params.spell or params.spell == "" then return end
      if castSpell(params.spell) and params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "paladinAttackSpell",
    title = "Paladin Spell",
    category = "Ataque",
    iconId = 3447,
    interval = 240,
    description = "Spell de ataque para Paladin (editavel).",
    tags = {"paladin", "spell", "ataque"},
    fields = {
      {id = "spell", type = "text", label = "Spell", default = "exori con"},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 15, min = 0, max = 100},
      {id = "requireTarget", type = "bool", label = "Exigir target", default = true},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 6, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos cast (ms)", default = 900, min = 100, max = 8000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end
      if params.requireTarget then
        local target = getAttackingTarget(params.maxDistance)
        if not target then return end
      end
      if not params.spell or params.spell == "" then return end
      if castSpell(params.spell) and params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "druidAttackSpell",
    title = "Druid Spell",
    category = "Ataque",
    iconId = 3191,
    interval = 240,
    description = "Spell de ataque para Druid (editavel).",
    tags = {"druid", "spell", "ataque"},
    fields = {
      {id = "spell", type = "text", label = "Spell", default = "exevo tera hur"},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 20, min = 0, max = 100},
      {id = "requireTarget", type = "bool", label = "Exigir target", default = true},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos cast (ms)", default = 900, min = 100, max = 8000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end
      if params.requireTarget then
        local target = getAttackingTarget(params.maxDistance)
        if not target then return end
      end
      if not params.spell or params.spell == "" then return end
      if castSpell(params.spell) and params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "sorcererAttackSpell",
    title = "Sorcerer Spell",
    category = "Ataque",
    iconId = 3155,
    interval = 240,
    description = "Spell de ataque para Sorcerer (editavel).",
    tags = {"sorcerer", "spell", "ataque"},
    fields = {
      {id = "spell", type = "text", label = "Spell", default = "exevo vis hur"},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 20, min = 0, max = 100},
      {id = "requireTarget", type = "bool", label = "Exigir target", default = true},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos cast (ms)", default = 900, min = 100, max = 8000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end
      if params.requireTarget then
        local target = getAttackingTarget(params.maxDistance)
        if not target then return end
      end
      if not params.spell or params.spell == "" then return end
      if castSpell(params.spell) and params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "cavebotControl",
    title = "CaveBot",
    category = "Controle",
    iconId = 3081,
    interval = 1200,
    description = "Liga ou desliga o CaveBot.",
    tags = {"cavebot", "bot"},
    fields = {},
    tickWhenDisabled = true,
    getExternalEnabled = isCavebotEnabledExternal,
    onToggle = function(enabled)
      setCavebotEnabledExternal(enabled)
    end,
    onTick = function(params, moduleState)
      local desired = moduleState and moduleState.enabled == true
      local current = isCavebotEnabledExternal()
      if type(current) ~= "boolean" or current ~= desired then
        setCavebotEnabledExternal(desired)
      end
    end
  },
  {
    key = "targetbotControl",
    title = "TargetBot",
    category = "Controle",
    iconId = 16712,
    interval = 1200,
    description = "Liga ou desliga o TargetBot.",
    tags = {"targetbot", "bot"},
    fields = {},
    tickWhenDisabled = true,
    getExternalEnabled = isTargetbotEnabledExternal,
    onToggle = function(enabled)
      setTargetbotEnabledExternal(enabled)
    end,
    onTick = function(params, moduleState)
      local desired = moduleState and moduleState.enabled == true
      local current = isTargetbotEnabledExternal()
      if type(current) ~= "boolean" or current ~= desired then
        setTargetbotEnabledExternal(desired)
      end
    end
  },
  {
    key = "attackModuleOff",
    title = "Attack",
    category = "Controle",
    iconId = 3271,
    interval = 1200,
    description = "Liga ou desliga o modulo Attack.",
    tags = {"attack", "combat", "controle"},
    fields = {},
    tickWhenDisabled = true,
    getExternalEnabled = ImperialElfBot.isAttackEnabledExternal,
    onToggle = function(enabled)
      setAttackEnabledExternal(enabled)
    end,
    onTick = function(params, moduleState)
      setAttackEnabledExternal(moduleState and moduleState.enabled == true)
    end
  },
  {
    key = "hpToolsModuleOff",
    title = "HP/Tools",
    category = "Controle",
    iconId = 3162,
    interval = 1200,
    description = "Liga ou desliga o modulo HP/Tools.",
    tags = {"hp", "tools", "healing", "controle"},
    fields = {},
    tickWhenDisabled = true,
    getExternalEnabled = ImperialElfBot.isHpToolsEnabledExternal,
    onToggle = function(enabled)
      setHpToolsEnabledExternal(enabled)
    end,
    onTick = function(params, moduleState)
      setHpToolsEnabledExternal(moduleState and moduleState.enabled == true)
    end
  },
  {
    key = "superdashControl",
    title = "Superdash",
    category = "Controle",
    iconId = 3079,
    interval = 50,
    description = "Superdash standalone via icone (sem depender do HP/Tools).",
    tags = {"superdash", "dash", "hp", "tools", "controle"},
    onTick = function(params, moduleState)
      if not g_game or not g_game.isOnline or not g_game.isOnline() then
        return
      end
      local player = getPlayer()
      if not player or not g_map or not g_map.getTile then
        return
      end
      if not g_game.walk then
        return
      end

      local runtime = moduleState and moduleState.runtime or nil
      if not runtime then
        runtime = {
          lastStrafe = 0,
          offsets = {
            [North] = {x = 0, y = -1},
            [East] = {x = 1, y = 0},
            [South] = {x = 0, y = 1},
            [West] = {x = -1, y = 0},
            [NorthEast] = {x = 1, y = -1},
            [SouthEast] = {x = 1, y = 1},
            [SouthWest] = {x = -1, y = 1},
            [NorthWest] = {x = -1, y = -1}
          },
          sideByDir = {
            [North] = {NorthWest, NorthEast},
            [East] = {NorthEast, SouthEast},
            [South] = {SouthEast, SouthWest},
            [West] = {SouthWest, NorthWest}
          }
        }
        moduleState.runtime = runtime
      end

      local function keyPressed(key)
        if not g_keyboard or not g_keyboard.isKeyPressed then
          return false
        end
        local ok, pressed = pcall(function() return g_keyboard.isKeyPressed(key) end)
        if not ok then
          ok, pressed = pcall(function() return g_keyboard.isKeyPressed(g_keyboard, key) end)
        end
        return ok and pressed == true
      end

      local northPressed = keyPressed("Up") or keyPressed("ArrowUp") or keyPressed("North") or keyPressed("W") or keyPressed("w") or keyPressed("Numpad8") or keyPressed("Num8")
      local eastPressed = keyPressed("Right") or keyPressed("ArrowRight") or keyPressed("East") or keyPressed("D") or keyPressed("d") or keyPressed("Numpad6") or keyPressed("Num6")
      local southPressed = keyPressed("Down") or keyPressed("ArrowDown") or keyPressed("South") or keyPressed("S") or keyPressed("s") or keyPressed("Numpad2") or keyPressed("Num2")
      local westPressed = keyPressed("Left") or keyPressed("ArrowLeft") or keyPressed("West") or keyPressed("A") or keyPressed("a") or keyPressed("Numpad4") or keyPressed("Num4")

      local dir = nil
      if westPressed and not eastPressed and not northPressed and not southPressed then
        dir = West
      elseif eastPressed and not westPressed and not northPressed and not southPressed then
        dir = East
      elseif northPressed and not southPressed and not eastPressed and not westPressed then
        dir = North
      elseif southPressed and not northPressed and not eastPressed and not westPressed then
        dir = South
      end

      if not dir then
        return
      end

      local strafeDelay = 80
      local tNow = nowMs()
      if tNow - (runtime.lastStrafe or 0) < strafeDelay then
        return
      end

      local pos = player:getPosition()
      local forwardDelta = runtime.offsets[dir]
      if not pos or not forwardDelta then
        return
      end

      local function tileIsClear(p)
        local tile = g_map.getTile(p)
        if not tile then
          return false
        end
        if not tile:isWalkable(true) then
          return false
        end
        if tile:hasCreature() then
          return false
        end
        return true
      end

      local forwardPos = {x = pos.x + forwardDelta.x, y = pos.y + forwardDelta.y, z = pos.z}
      if tileIsClear(forwardPos) then
        return
      end

      local sideDirs = runtime.sideByDir[dir] or {}
      for _, sideDir in ipairs(sideDirs) do
        local sideDelta = runtime.offsets[sideDir]
        if sideDelta then
          local sidePos = {x = pos.x + sideDelta.x, y = pos.y + sideDelta.y, z = pos.z}
          if tileIsClear(sidePos) then
            g_game.walk(sideDir)
            runtime.lastStrafe = tNow
            return
          end
        end
      end
    end
  },
  {
    key = "followModuleOff",
    title = "Follow",
    category = "Controle",
    iconId = 1949,
    interval = 1200,
    description = "Liga ou desliga o Follow.",
    tags = {"follow", "nav", "controle"},
    fields = {},
    tickWhenDisabled = true,
    getExternalEnabled = ImperialElfBot.isFollowEnabledExternal,
    onToggle = function(enabled)
      setFollowEnabledExternal(enabled)
    end,
    onTick = function(params, moduleState)
      setFollowEnabledExternal(moduleState and moduleState.enabled == true)
    end
  },
  {
    key = "navModuleOff",
    title = "Navigation",
    category = "Controle",
    iconId = 10280,
    interval = 1200,
    description = "Liga ou desliga o modulo Navigation.",
    tags = {"navigation", "nav", "controle"},
    fields = {},
    tickWhenDisabled = true,
    getExternalEnabled = ImperialElfBot.isNavigationEnabledExternal,
    onToggle = function(enabled)
      setNavigationEnabledExternal(enabled)
    end,
    onTick = function(params, moduleState)
      setNavigationEnabledExternal(moduleState and moduleState.enabled == true)
    end
  },
  {
    key = "pvpModuleOff",
    title = "PVP",
    category = "Controle",
    iconId = 16778,
    interval = 1200,
    description = "Liga ou desliga o modulo PVP.",
    tags = {"pvp", "controle"},
    fields = {},
    tickWhenDisabled = true,
    getExternalEnabled = ImperialElfBot.isPvpEnabledExternal,
    onToggle = function(enabled)
      setPvpEnabledExternal(enabled)
    end,
    onTick = function(params, moduleState)
      setPvpEnabledExternal(moduleState and moduleState.enabled == true)
    end
  },
  {
    key = "ringModuleOff",
    title = "Ring",
    category = "Controle",
    iconId = 3048,
    interval = 1200,
    description = "Liga ou desliga Rings do modulo Ring/Amulet.",
    tags = {"ring", "ringamulet", "controle"},
    fields = {},
    tickWhenDisabled = true,
    getExternalEnabled = ImperialElfBot.isRingEnabledExternal,
    onToggle = function(enabled)
      setRingEnabledExternal(enabled)
    end,
    onTick = function(params, moduleState)
      setRingEnabledExternal(moduleState and moduleState.enabled == true)
    end
  },
  {
    key = "amuletModuleOff",
    title = "Amulet",
    category = "Controle",
    iconId = 3057,
    interval = 1200,
    description = "Liga ou desliga Amulets do modulo Ring/Amulet.",
    tags = {"amulet", "ringamulet", "controle"},
    fields = {},
    tickWhenDisabled = true,
    getExternalEnabled = ImperialElfBot.isAmuletEnabledExternal,
    onToggle = function(enabled)
      setAmuletEnabledExternal(enabled)
    end,
    onTick = function(params, moduleState)
      setAmuletEnabledExternal(moduleState and moduleState.enabled == true)
    end
  },
  {
    key = "swapSetModuleOff",
    title = "SwapSet",
    category = "Controle",
    iconId = 8061,
    interval = 1200,
    description = "Liga ou desliga o modulo SwapSet.",
    tags = {"swapset", "set", "equip", "controle"},
    fields = {},
    tickWhenDisabled = true,
    getExternalEnabled = ImperialElfBot.isSwapSetEnabledExternal,
    onToggle = function(enabled)
      setSwapSetEnabledExternal(enabled)
      local profiles = type(storage.swapSetProfiles) == "table" and storage.swapSetProfiles or nil
      local selectedId = profiles and profiles.meta and profiles.meta.activeProfile or nil
      if selectedId and selectedId ~= "" and type(profiles.configs) == "table" and type(profiles.configs[selectedId]) == "table" and type(profiles.configs[selectedId].data) == "table" then
        profiles.configs[selectedId].data.autoSwapEnabled = enabled == true
      end
    end,
    onTick = function(params, moduleState)
      setSwapSetEnabledExternal(moduleState and moduleState.enabled == true)
    end
  },
  {
    key = "utamoVita",
    title = "Utamo",
    category = "Defesa",
    iconId = 3548,
    interval = 180,
    description = "Controle de utamo vita com opcao de cancelar via utamo ina.",
    tags = {"utamo", "defesa", "spell"},
    fields = {
      {id = "hpBelow", type = "number", label = "HP abaixo de (%) usa utamo", default = 60, min = 1, max = 99},
      {id = "hpAboveCancel", type = "number", label = "HP acima de (%) usa cancel", default = 80, min = 1, max = 100},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 25, min = 0, max = 100},
      {id = "spell", type = "text", label = "Spell", default = "utamo vita"},
      {id = "cancelSpell", type = "text", label = "Spell cancelar", default = "utamo ina"},
      {id = "renewOnly", type = "bool", label = "Somente renovar utamo (sem cancelar)", default = false},
      {id = "delayMs", type = "number", label = "Delay apos cast (ms)", default = 1000, min = 100, max = 5000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end

      local hpNow = hppercent()
      local hasShield = false
      if type(hasManaShield) == "function" then
        local ok, value = pcall(hasManaShield)
        if ok and value == true then
          hasShield = true
        end
      end

      local hpBelow = clamp(tonumber(params.hpBelow) or 60, 1, 99)
      local hpAboveCancel = clamp(tonumber(params.hpAboveCancel) or 80, 1, 100)
      if hpAboveCancel <= hpBelow then
        hpAboveCancel = math.min(100, hpBelow + 1)
      end

      if hpNow <= hpBelow then
        if not hasShield and params.spell and params.spell ~= "" then
          say(params.spell)
          if params.delayMs > 0 then delay(params.delayMs) end
        end
        return
      end

      if params.renewOnly == true then
        return
      end

      if hpNow >= hpAboveCancel and hasShield and params.cancelSpell and params.cancelSpell ~= "" then
        say(params.cancelSpell)
        if params.delayMs > 0 then delay(params.delayMs) end
      end
    end
  },
  {
    key = "fireBomb",
    title = "Fire Bomb",
    category = "Utilidade",
    iconId = 3197,
    interval = 400,
    description = "Usa fire bomb em target ou no proprio personagem.",
    tags = {"bomb", "fire", "runa"},
    fields = {
      {id = "runeId", type = "number", label = "Runa ID", default = 3197, min = 100, max = 50000},
      {id = "mode", type = "combo", label = "Modo", default = "target", options = {
        {text = "Target", value = "target"},
        {text = "Self", value = "self"}
      }},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 10, min = 0, max = 100},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 800, min = 100, max = 6000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end

      if params.mode == "self" then
        local player = getPlayer()
        if not player then return end
        if not useWithItem(params.runeId, player) then return end
        if params.delayMs > 0 then delay(params.delayMs) end
        return
      end

      local target = getAttackingTarget(params.maxDistance)
      if not target then return end
      if not useWithItem(params.runeId, target) then return end
      if params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "holdTarget",
    title = "HoldTarget",
    category = "Ataque",
    iconId = 2854,
    interval = 140,
    description = "Tenta reatacar o ultimo target visivel quando o foco e perdido.",
    tags = {"target", "hold", "reattack"},
    fields = {
      {id = "maxDistance", type = "number", label = "Distancia de busca", default = 8, min = 1, max = 12},
      {id = "reacquireDelay", type = "number", label = "Intervalo de reataque (ms)", default = 450, min = 100, max = 5000}
    },
    onTick = function(params, state)
      state.runtime = state.runtime or {}
      local runtime = state.runtime
      local currentTarget = getAttackingTarget()

      if currentTarget then
        runtime.lastTargetId = currentTarget:getId()
        return
      end

      if not runtime.lastTargetId then return end

      local nowTime = nowMs()
      if runtime.nextTry and nowTime < runtime.nextTry then return end
      runtime.nextTry = nowTime + params.reacquireDelay

      local player = getPlayer()
      local playerPos = player and player:getPosition()
      if not playerPos then return end

      local spectators = getSpectators() or {}
      for _, creature in ipairs(spectators) do
        if creature and creature:getId() == runtime.lastTargetId then
          local cPos = creature:getPosition()
          if cPos and cPos.z == playerPos.z and distanceChebyshev(cPos, playerPos) <= params.maxDistance then
            attack(creature)
            return
          end
        end
      end
    end
  },
  {
    key = "antiPushCoin",
    title = "Antpush",
    category = "Utilidade",
    iconId = 3031,
    interval = 280,
    description = "Dropa coins no proprio tile para reduzir push.",
    tags = {"antipush", "coin", "tile"},
    fields = {
      {id = "itemId", type = "number", label = "Item ID", default = 3031, min = 100, max = 50000},
      {id = "maxStack", type = "number", label = "Maximo no tile", default = 7, min = 2, max = 10},
      {id = "dropAmount", type = "number", label = "Quantidade por drop", default = 1, min = 1, max = 10},
      {id = "delayMs", type = "number", label = "Delay apos drop (ms)", default = 1100, min = 100, max = 5000}
    },
    onTick = function(params)
      local player = getPlayer()
      if not player or not g_map then return end
      local position = player:getPosition()
      local tile = g_map.getTile(position)
      if not tile or tile:getThingCount() >= params.maxStack then return end

      local coin = findItemById(params.itemId)
      if not coin or not g_game or not g_game.move then return end

      local amount = math.max(1, math.floor(params.dropAmount))
      g_game.move(coin, position, amount)
      if params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "exetaRes",
    title = "ExetaRes",
    category = "Suporte",
    iconId = 3420,
    interval = 240,
    description = "Lanca exeta res pelas condicoes configuradas.",
    tags = {"exeta", "support", "spell"},
    fields = {
      {id = "hpBelow", type = "number", label = "HP maximo (%)", default = 92, min = 1, max = 99},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 20, min = 0, max = 100},
      {id = "spell", type = "text", label = "Spell", default = "exeta res"},
      {id = "delayMs", type = "number", label = "Delay apos cast (ms)", default = 1200, min = 100, max = 7000}
    },
    onTick = function(params)
      if hppercent() > params.hpBelow then return end
      if manapercent() < params.manaMin then return end
      if not params.spell or params.spell == "" then return end
      say(params.spell)
      if params.delayMs > 0 then delay(params.delayMs) end
    end
  },
  {
    key = "macheteAuto",
    title = "Machete",
    category = "Utilidade",
    iconId = 3308,
    interval = 350,
    description = "Usa machete automaticamente em itens proximos.",
    tags = {"machete", "utilidade"},
    fields = {
      {id = "itemId", type = "number", label = "Item ID", default = 3308, min = 100, max = 50000},
      {id = "range", type = "number", label = "Alcance", default = 1, min = 1, max = 3},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 600, min = 100, max = 5000}
    },
    onTick = function(params)
      if not g_map or not g_map.getTiles then return end
      local player = getPlayer()
      local playerPos = player and player:getPosition()
      if not playerPos then return end

      local targetIds = {
        [2130] = true,
        [3696] = true
      }
      for _, tile in pairs(g_map.getTiles(playerPos.z) or {}) do
        local tilePos = tile and tile.getPosition and tile:getPosition() or nil
        if tilePos and tilePos.z == playerPos.z and distanceChebyshev(playerPos, tilePos) <= params.range then
          for _, item in ipairs(tile:getItems() or {}) do
            local itemId = item:getId()
            if targetIds[itemId] then
              if useWithItem(params.itemId, item) and params.delayMs > 0 then
                delay(params.delayMs)
              end
              return
            end
          end
        end
      end
    end
  },
  {
    key = "sewerSystem",
    title = "Sewer",
    category = "Utilidade",
    iconId = 2128,
    interval = 180,
    description = "Usa runa no bueiro configurado quando estiver no alcance.",
    tags = {"sewer", "bueiro", "runa", "utilidade"},
    fields = {
      {id = "sewerId", type = "number", label = "ID do bueiro", default = 435, min = 100, max = 50000},
      {id = "runeId", type = "number", label = "Runa ID", default = 3180, min = 100, max = 50000},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 6, min = 1, max = 9}
    },
    onTick = function(params)
      if not g_map or not g_map.getTiles then return end

      local player = getPlayer()
      local playerPos = player and player:getPosition()
      if not playerPos then return end

      local sewerId = clamp(tonumber(params.sewerId) or 435, 100, 50000)
      local maxDistance = clamp(tonumber(params.maxDistance) or 6, 1, 9)
      local blockedTopId = 2128

      for _, tile in pairs(g_map.getTiles(playerPos.z) or {}) do
        local tilePos = tile and tile.getPosition and tile:getPosition() or nil
        if tilePos and tilePos.z == playerPos.z and distanceChebyshev(playerPos, tilePos) <= maxDistance then
          local hasSewer = false
          for _, thing in ipairs(tile:getThings() or {}) do
            if thing and thing.getId and tonumber(thing:getId()) == sewerId then
              hasSewer = true
              break
            end
          end

          if hasSewer then
            local topThing = tile:getTopUseThing() or tile:getTopThing() or tile:getGround()
            if topThing and topThing.getId and tonumber(topThing:getId()) ~= blockedTopId then
              useWithItem(params.runeId, topThing)
              return
            end
          end
        end
      end
    end
  },
  {
    key = "revideSystem",
    title = "Revide",
    category = "PVP",
    iconId = 33278,
    defaultPos = {x = 95, y = 39},
    interval = 100,
    description = "Revide PK: revida somente quando o hit e em voce.",
    tags = {"revide", "pk", "pvp"},
    fields = {
      {id = "targetTimeoutMs", type = "number", label = "Timeout alvo (ms)", default = 2500, min = 500, max = 20000},
      {id = "huntMode", type = "bool", label = "Desligar Cave/Target no revide", default = false},
      {id = "restoreHuntOnIdle", type = "bool", label = "Religar Cave/Target sem alvo", default = true},
      {id = "forceSafeFight", type = "bool", label = "SafeFight OFF no revide", default = true},
      {id = "forceChase", type = "bool", label = "Chase ON no revide", default = true},
      {id = "ignorePartyAttackers", type = "bool", label = "Ignorar atacante da party", default = true},
      {id = "ignoreSameGuildAttackers", type = "bool", label = "Ignorar atacante da mesma guild", default = true},
      {id = "ignoredNicknames", type = "nickCsv", label = "Nicks ignorados (separar por virgula)", default = ""},
      {id = "showDebug", type = "bool", label = "Mostrar logs", default = false}
    },
    onTick = function(params, moduleState)
      if not g_game or not g_game.isOnline or not g_game.isOnline() then
        return
      end

      moduleState.runtime = moduleState.runtime or {}
      local runtime = moduleState.runtime
      runtime.targetTime = tonumber(runtime.targetTime) or 0
      runtime.huntPaused = runtime.huntPaused == true
      local nowTime = nowMs()

      local function normalizeName(value)
        local text = normalizeText(value or "")
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        return text
      end

      local function isPartyMemberCreature(creature)
        if not creature then return false end
        if creature.isPartyMember then
          local okParty, partyValue = pcall(function() return creature:isPartyMember() end)
          if okParty and partyValue == true then
            return true
          end
        end
        return false
      end

      local function isSameGuildCreature(creature)
        if not creature then
          return false
        end
        if creature.getEmblem then
          local okEmblem, emblemValue = pcall(function() return creature:getEmblem() end)
          if okEmblem and tonumber(emblemValue) == 1 then
            return true
          end
        end
        return false
      end

      runtime.ignoredNamesSet = runtime.ignoredNamesSet or {}
      local ignoredSource = tostring(params.ignoredNicknames or "")
      if runtime.ignoredNamesSource ~= ignoredSource then
        runtime.ignoredNamesSource = ignoredSource
        runtime.ignoredNamesSet = {}
        local parsedSource = ignoredSource:gsub("[\r\n;]+", ",")
        for rawToken in string.gmatch(parsedSource, "[^,]+") do
          local cleaned = normalizeName(rawToken)
          if cleaned ~= "" then
            runtime.ignoredNamesSet[cleaned] = true
          end
        end
      end

      local function isIgnoredByNickname(nameText)
        local needle = normalizeName(nameText)
        if needle == "" or type(runtime.ignoredNamesSet) ~= "table" then
          return false
        end
        return runtime.ignoredNamesSet[needle] == true
      end

      local function findVisiblePlayerByName(nameText)
        local expected = normalizeName(nameText)
        if expected == "" then
          return nil
        end
        for _, creature in ipairs(getSpectators() or {}) do
          if creature and creature.isPlayer and creature:isPlayer() and creature.getName then
            local cName = normalizeName(creature:getName())
            if cName == expected then
              return creature
            end
          end
        end
        return nil
      end

      local function setAttackerByName(attackerName)
        local normalized = normalizeName(attackerName)
        if normalized == "" then
          return
        end
        runtime.attackerName = tostring(attackerName)
        runtime.targetTime = nowMs()
      end

      local function clearAttacker(reasonText)
        runtime.attackerName = nil
        runtime.targetTime = 0
        if params.showDebug and reasonText and reasonText ~= "" then
          showMessage(string.format("[Revide] %s", reasonText))
        end
      end

      if not runtime.missileRegistered and type(onMissle) == "function" then
        runtime.missileRegistered = true
        onMissle(function(missile)
          if moduleState.enabled ~= true then
            return
          end

          local cfg = moduleState.params or {}
          local localPlayer = getPlayer()
          local localPos = localPlayer and localPlayer:getPosition()
          if not localPlayer or not localPos then
            return
          end

          local src = missile and missile.getSource and missile:getSource() or nil
          local destination = missile and missile.getDestination and missile:getDestination() or nil
          if not src or not destination or src.z ~= localPos.z then
            return
          end

          local shooterTile = g_map and g_map.getTile and g_map.getTile(src) or nil
          if not shooterTile then
            return
          end

          local attacker = nil
          for _, creature in ipairs(shooterTile:getCreatures() or {}) do
            if isPlayerCreature(creature) then
              attacker = creature
              break
            end
          end
          if not attacker or not attacker.getName then
            return
          end

          local attackerName = attacker:getName()
          local localName = localPlayer.getName and localPlayer:getName() or ""
          if normalizeName(attackerName) == normalizeName(localName) then
            return
          end

          if cfg.ignorePartyAttackers and isPartyMemberCreature(attacker) then
            return
          end
          if cfg.ignoreSameGuildAttackers and isSameGuildCreature(attacker) then
            return
          end
          if isIgnoredByNickname(attackerName) then
            return
          end

          local hitsSelf = destination.x == localPos.x and destination.y == localPos.y and destination.z == localPos.z
          if not hitsSelf then
            return
          end

          setAttackerByName(attackerName)
        end)
      end

      if runtime.attackerName and runtime.targetTime > 0 then
        local timeoutMs = clamp(tonumber(params.targetTimeoutMs) or 2500, 500, 20000)
        if nowTime - runtime.targetTime > timeoutMs then
          clearAttacker("reset por timeout")
        end
      end

      local attacker = findVisiblePlayerByName(runtime.attackerName)
      local hasActiveTarget = runtime.attackerName ~= nil and runtime.attackerName ~= ""

      if attacker then
        local attackerNameNow = attacker.getName and attacker:getName() or ""
        if (params.ignorePartyAttackers and isPartyMemberCreature(attacker))
          or (params.ignoreSameGuildAttackers and isSameGuildCreature(attacker))
          or isIgnoredByNickname(attackerNameNow) then
          clearAttacker("alvo ignorado (party/guild/lista)")
          return
        end

        local attackerPos = attacker:getPosition()
        if attackerPos and attackerPos.z == posz() then
          if params.forceSafeFight and g_game.setSafeFight then
            g_game.setSafeFight(false)
          end
          if params.forceChase and g_game.setChaseMode then
            g_game.setChaseMode(1)
          end

          if g_game.attack then
            local currentTarget = g_game.getAttackingCreature and g_game.getAttackingCreature() or nil
            if not (g_game.isAttacking and g_game.isAttacking()) or currentTarget ~= attacker then
              g_game.attack(attacker)
            end
          end

          if params.huntMode and not runtime.huntPaused then
            setTargetbotEnabledExternal(false)
            setCavebotEnabledExternal(false)
            runtime.huntPaused = true
          end
        end
        return
      end

      if hasActiveTarget then
        return
      end

      if g_game.isAttacking and g_game.isAttacking() then
        return
      end

      if params.forceSafeFight and g_game.setSafeFight then
        g_game.setSafeFight(true)
      end
      if params.forceChase and g_game.setChaseMode then
        g_game.setChaseMode(0)
      end
      if params.huntMode and params.restoreHuntOnIdle and runtime.huntPaused then
        setTargetbotEnabledExternal(true)
        setCavebotEnabledExternal(true)
        runtime.huntPaused = false
      end
    end,
    onToggle = function(enabled, params, moduleState)
      if enabled then
        return
      end

      moduleState.runtime = moduleState.runtime or {}
      local runtime = moduleState.runtime
      runtime.attackerName = nil
      runtime.targetTime = 0

      if params and params.huntMode and params.restoreHuntOnIdle and runtime.huntPaused then
        setTargetbotEnabledExternal(true)
        setCavebotEnabledExternal(true)
      end
      runtime.huntPaused = false
    end
  },
  {
    key = "fullChaseSystem",
    title = "FullChase",
    category = "Utilidade",
    iconId = 1949,
    interval = 50,
    description = "Segue player alvo; se perder visao tenta usar rope/ladder/sewer para reencontrar.",
    tags = {"fullchase", "chase", "pvp", "follow", "target"},
    fields = {
      {id = "targetLostSeconds", type = "number", label = "Tempo max sem ver alvo (s)", default = 5, min = 1, max = 60},
      {id = "ropeId", type = "number", label = "Rope ID", default = 3003, min = 100, max = 50000},
      {id = "searchRange", type = "number", label = "Raio busca tile", default = 7, min = 1, max = 15},
      {id = "pathMaxDistance", type = "number", label = "Max distancia path", default = 10, min = 3, max = 30},
      {id = "nearTargetDistance", type = "number", label = "Distancia para lock chase", default = 2, min = 1, max = 8},
      {id = "actionLockMs", type = "number", label = "Lock apos acao (ms)", default = 200, min = 50, max = 2000},
      {id = "showStopMsg", type = "bool", label = "Mostrar aviso ao parar", default = true},
      {id = "laddersIds", type = "itemList", label = "Ladders IDs", default = {1948, 1968}},
      {id = "sewersIds", type = "itemList", label = "Sewers IDs", default = {435}},
      {id = "ropeHolesIds", type = "itemList", label = "Rope Holes IDs", default = {17238, 12202, 12935, 386, 421, 21966, 14238}}
    },
    onTick = function(params, moduleState)
      if not g_game or not g_game.isOnline or not g_game.isOnline() then
        return
      end

      local player = getPlayer()
      local playerPos = player and player:getPosition()
      if not playerPos then
        return
      end

      moduleState.runtime = moduleState.runtime or {}
      local runtime = moduleState.runtime
      runtime.lastTargetPos = runtime.lastTargetPos or {}
      runtime.autoWalk = runtime.autoWalk == true
      runtime.nextActionAt = tonumber(runtime.nextActionAt) or 0
      runtime.lastSeenAt = tonumber(runtime.lastSeenAt) or nowMs()
      runtime.isRunningAt = runtime.lastSeenAt
      runtime.lastTargetDir = tonumber(runtime.lastTargetDir) or 0

      local nowTime = nowMs()

      local laddersSet = parseItemIdListToSet(params.laddersIds, {1948, 1968})
      local sewersSet = parseItemIdListToSet(params.sewersIds, {435})
      local ropeHolesSet = parseItemIdListToSet(params.ropeHolesIds, {17238, 12202, 12935, 386, 421, 21966, 14238})

      local function thingId(thing)
        if not thing or not thing.getId then
          return nil
        end
        return tonumber(thing:getId())
      end

      local function isStairsPos(pos)
        if not g_map or not g_map.getMinimapColor then
          return false
        end
        local color = g_map.getMinimapColor(pos)
        return color and color >= 210 and color <= 213
      end

      local function samePos(a, b)
        return a and b and a.x == b.x and a.y == b.y and a.z == b.z
      end

      local function getLastPosAtFloor()
        return runtime.lastTargetPos[playerPos.z]
      end

      local function lockAction()
        local lockMs = clamp(tonumber(params.actionLockMs) or 200, 50, 2000)
        runtime.nextActionAt = nowTime + lockMs
      end

      local function setAutoWalk()
        runtime.autoWalk = true
      end

      local function setFullChaseWindow()
        local stamp = nowTime
        runtime.lastFullChaseStamp = stamp
        schedule(2000, function()
          if moduleState.enabled ~= true then
            return
          end
          local rt = runtime
          if not rt then
            return
          end
          if rt.lastFullChaseStamp == stamp then
            rt.autoWalk = false
          end
        end)
      end

      local function walkToPos(targetPos)
        if not targetPos then
          return
        end
        lockAction()
        setAutoWalk()

        if samePos(targetPos, playerPos) then
          if g_game and g_game.turn then
            g_game.turn(runtime.lastTargetDir)
          end
          return
        end

        local maxPath = clamp(tonumber(params.pathMaxDistance) or 10, 3, 30)
        if type(autoWalk) == "function" then
          autoWalk(targetPos, maxPath, {ignoreNonPathable = true})
          return
        end

        if type(findPath) == "function" and g_game and g_game.autoWalk then
          local path = findPath(playerPos, targetPos, maxPath, {ignoreNonPathable = true})
          if path then
            g_game.autoWalk(path, {x = 0, y = 0, z = 0})
          end
        end
      end

      local function getTileAction(tile)
        if not tile then
          return nil, nil
        end

        local topThing = tile:getTopUseThing() or tile:getTopThing() or tile:getGround()
        local topId = thingId(topThing)
        if topId then
          if ropeHolesSet[topId] then
            return "rope", topThing
          end
          if laddersSet[topId] or sewersSet[topId] then
            return "use", topThing
          end
        end

        local tilePos = tile:getPosition()
        if tilePos and isStairsPos(tilePos) then
          return "walk", topThing
        end
        return nil, topThing
      end

      local function getClosestTile()
        local lastPos = getLastPosAtFloor()
        if not lastPos or not g_map or not g_map.getTiles then
          return nil
        end

        local bestTile = nil
        local bestDistance = 999
        local searchRange = clamp(tonumber(params.searchRange) or 7, 1, 15)

        for _, tile in pairs(g_map.getTiles(playerPos.z) or {}) do
          local tilePos = tile and tile.getPosition and tile:getPosition() or nil
          if tilePos and tilePos.z == playerPos.z then
            local dist = distanceChebyshev(tilePos, lastPos)
            if dist <= searchRange then
              local actionType = getTileAction(tile)
              if actionType then
                local canPath = true
                if type(findPath) == "function" then
                  canPath = findPath(playerPos, tilePos, 20, {ignoreNonPathable = true}) ~= nil
                end
                if canPath and dist < bestDistance then
                  bestTile = tile
                  bestDistance = dist
                end
              end
            end
          end
        end

        return bestTile
      end

      local function followLastPos()
        if runtime.nextActionAt > nowTime then
          return
        end
        local lastPos = getLastPosAtFloor()
        if not lastPos then
          return
        end
        if distanceChebyshev(playerPos, lastPos) <= 1 then
          return
        end

        local maxPath = clamp(tonumber(params.pathMaxDistance) or 10, 3, 30)
        if type(findPath) == "function" and g_game and g_game.autoWalk then
          local path = findPath(playerPos, lastPos, maxPath, {ignoreLastCreature = true, ignoreNonPathable = true})
          if path then
            lockAction()
            g_game.autoWalk(path, {x = 0, y = 0, z = 0})
            return
          end
        end

        walkToPos(lastPos)
      end

      local function useNearby()
        if runtime.nextActionAt > nowTime then
          return
        end

        local closestTile = getClosestTile()
        if not closestTile then
          walkToPos(getLastPosAtFloor())
          return
        end

        local actionType, topThing = getTileAction(closestTile)
        local tilePos = closestTile:getPosition()

        if actionType == "rope" and topThing then
          if useWithItem(params.ropeId, topThing) then
            lockAction()
            setAutoWalk()
            return
          end
        elseif actionType == "use" and topThing and g_game and g_game.use then
          g_game.use(topThing)
          lockAction()
          setAutoWalk()
          return
        end

        walkToPos(tilePos)
      end

      local function findTargetByName(nameText)
        local targetName = normalizeText(nameText)
        if targetName == "" then
          return nil
        end
        for _, creature in ipairs(getSpectators() or {}) do
          if creature and creature.getName and creature.isPlayer and creature:isPlayer() then
            local cName = normalizeText(creature:getName())
            if cName == targetName then
              return creature
            end
          end
        end
        return nil
      end

      local function keyPressed(key)
        if not g_keyboard or not g_keyboard.isKeyPressed then
          return false
        end
        local ok, pressed = pcall(function() return g_keyboard.isKeyPressed(key) end)
        if not ok then
          ok, pressed = pcall(function() return g_keyboard.isKeyPressed(g_keyboard, key) end)
        end
        return ok and pressed == true
      end

      local function disableFullChase(reasonText)
        runtime.lastTargetName = nil
        runtime.autoWalk = false
        runtime.nextActionAt = nowTime + 250
        if g_game and g_game.cancelAttack then
          if not pcall(g_game.cancelAttack) then
            pcall(g_game.cancelAttack, g_game)
          end
        end
        if params.showStopMsg and reasonText and reasonText ~= "" then
          showMessage(string.format("[FullChase] %s", reasonText))
        end
      end

      local currentTarget = g_game.getAttackingCreature and g_game.getAttackingCreature() or nil
      if currentTarget and currentTarget.isPlayer and currentTarget:isPlayer() then
        runtime.lastTargetName = currentTarget:getName()
        runtime.lastTargetDir = currentTarget.getDirection and currentTarget:getDirection() or runtime.lastTargetDir
        local currentPos = currentTarget:getPosition()
        if currentPos then
          runtime.lastTargetPos[currentPos.z] = currentPos
        end
      end

      if keyPressed("Escape") or keyPressed("Esc") then
        if runtime.lastTargetName and runtime.lastTargetName ~= "" then
          disableFullChase("parado: ESC")
        end
        return
      end

      if not runtime.lastTargetName or runtime.lastTargetName == "" then
        return
      end

      local target = findTargetByName(runtime.lastTargetName)
      if target then
        local tPos = target:getPosition()
        if tPos then
          runtime.lastTargetPos[tPos.z] = tPos
        end
        runtime.lastSeenAt = nowTime
        runtime.isRunningAt = nowTime
      end

      local timeoutMs = clamp(tonumber(params.targetLostSeconds) or 5, 1, 60) * 1000
      if nowTime > ((tonumber(runtime.lastSeenAt) or nowTime) + timeoutMs) then
        disableFullChase("parado: timeout sem target")
        return
      end

      if not target then
        useNearby()
        return
      end

      if g_game and g_game.isAttacking and g_game.isAttacking() then
        runtime.lastTargetDir = target.getDirection and target:getDirection() or runtime.lastTargetDir
        local tPos = target:getPosition()
        local nearDistance = clamp(tonumber(params.nearTargetDistance) or 2, 1, 8)
        if tPos and distanceChebyshev(playerPos, tPos) <= nearDistance then
          setFullChaseWindow()
        end

        if runtime.autoWalk then
          followLastPos()
        elseif g_game.getChaseMode and g_game.setChaseMode and g_game.getChaseMode() ~= 1 then
          g_game.setChaseMode(1)
        end
        return
      end

      if g_game and g_game.attack then
        g_game.attack(target)
      end
    end,
    onToggle = function(enabled, _, moduleState)
      if enabled then
        return
      end
      moduleState.runtime = moduleState.runtime or {}
      moduleState.runtime.autoWalk = false
      moduleState.runtime.lastTargetName = nil
    end
  },
  {
    key = "attackSpell",
    title = "Attack Spell",
    category = "Ataque",
    iconId = 3271,
    interval = 220,
    description = "Ataque por spell no target.",
    tags = {"spell", "attack", "combat"},
    fields = {
      {id = "spell", type = "text", label = "Spell", default = "exori gran con"},
      {id = "needTarget", type = "bool", label = "Exigir target", default = true},
      {id = "maxDistance", type = "number", label = "Distancia maxima", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos cast (ms)", default = 350, min = 100, max = 6000}
    },
    onTick = function(params)
      if params.needTarget then
        local target = getAttackingTarget(params.maxDistance)
        if not target then return end
      end
      if castSpell(params.spell) and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "magnetSystem",
    title = "Magnet",
    category = "Utilidade",
    iconId = 2526,
    interval = 250,
    description = "Puxa itens ao redor para o tile do player.",
    tags = {"magnet", "push", "items"},
    fields = {
      {id = "range", type = "number", label = "Alcance", default = 1, min = 1, max = 2},
      {id = "delayMs", type = "number", label = "Delay apos mover (ms)", default = 450, min = 100, max = 5000}
    },
    onTick = function(params)
      if not g_map or not g_game or not g_game.move then return end
      if g_game.isOnline and not g_game.isOnline() then return end
      local player = getPlayer()
      local center = player and player:getPosition()
      if not center then return end

      local range = clamp(tonumber(params.range) or 1, 1, 2)
      local bestThing = nil
      local bestDist = 99

      local function isMagnetMovableItem(thing)
        if not thing or not thing.isItem or not thing:isItem() then
          return false
        end
        if thing.isNotMoveable and thing:isNotMoveable() then
          return false
        end
        if thing.isMoveable and not thing:isMoveable() then
          return false
        end
        local itemId = tonumber(thing.getId and thing:getId() or 0) or 0
        if itemId < 100 then
          return false
        end
        local thingPos = thing.getPosition and thing:getPosition() or nil
        if thingPos and thingPos.x == 65535 then
          return false
        end
        return true
      end

      for dx = -range, range do
        for dy = -range, range do
          if not (dx == 0 and dy == 0) then
            local tilePos = {x = center.x + dx, y = center.y + dy, z = center.z}
            local tile = g_map.getTile(tilePos)
            if tile then
              local dist = math.max(math.abs(dx), math.abs(dy))
              local things = tile:getThings() or {}
              for idx = #things, 1, -1 do
                local thing = things[idx]
                if isMagnetMovableItem(thing) then
                  if dist < bestDist then
                    bestDist = dist
                    bestThing = thing
                  end
                  break
                end
              end
            end
          end
        end
      end

      if not bestThing then
        return
      end

      local count = bestThing.getCount and bestThing:getCount() or 1
      local amount = math.max(1, tonumber(count) or 1)
      local ok = pcall(function()
        g_game.move(bestThing, center, amount)
      end)
      if ok and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "coletarSystem",
    title = "Coletar",
    category = "Utilidade",
    iconId = 3031,
    interval = 180,
    description = "Coleta itens configurados no chao e envia para backpack aberta.",
    tags = {"coletar", "collect", "loot", "utilidade"},
    fields = {
      {id = "range", type = "number", label = "Alcance (sqm)", default = 1, min = 0, max = 5},
      {id = "minCap", type = "number", label = "Cap minima", default = 200, min = 0, max = 100000},
      {id = "itemIds", type = "text", label = "IDs (virgula)", default = "3031,2854,6529"},
      {id = "delayMs", type = "number", label = "Delay apos coleta (ms)", default = 180, min = 0, max = 5000}
    },
    onTick = function(params, state)
      if not g_map or not g_game or not g_game.move then return end
      if not g_game.isOnline or not g_game.isOnline() then return end

      local minCap = math.max(0, tonumber(params.minCap) or 0)
      if freecap() < minCap then return end

      local player = getPlayer()
      local playerPos = player and player:getPosition()
      if not playerPos then return end

      local itemSet = parseItemIdListToSet(params.itemIds, {3031, 2854, 6529})
      local hasItems = false
      for _ in pairs(itemSet) do
        hasItems = true
        break
      end
      if not hasItems then return end

      local range = clamp(tonumber(params.range) or 1, 0, 5)
      for x = -range, range do
        for y = -range, range do
          local tile = g_map.getTile({x = playerPos.x + x, y = playerPos.y + y, z = playerPos.z})
          if tile then
            for _, thing in ipairs(tile:getThings() or {}) do
              if thing and thing.getId then
                local itemId = thing:getId()
                if itemSet[itemId] then
                  local canMove = true
                  if thing.isNotMoveable and thing:isNotMoveable() then
                    canMove = false
                  end
                  if canMove then
                    local destPos = resolveFirstContainerSlotPos()
                    if not destPos then return end
                    local amount = math.max(1, tonumber(thing.getCount and thing:getCount()) or 1)
                    g_game.move(thing, destPos, amount)
                    if params.delayMs > 0 then delay(params.delayMs) end
                    return
                  end
                end
              end
            end
          end
        end
      end
    end
  },
  {
    key = "safeRuneSpell",
    title = "Safe Rune Spell",
    category = "Safety",
    iconId = 3155,
    interval = 220,
    description = "Executa runa/spell apenas quando area estiver segura.",
    tags = {"safe", "rune", "spell"},
    fields = {
      {id = "mode", type = "combo", label = "Modo", default = "both", options = {
        {text = "Rune + Spell", value = "both"},
        {text = "Rune", value = "rune"},
        {text = "Spell", value = "spell"}
      }},
      {id = "runeId", type = "number", label = "Runa ID", default = 3155, min = 100, max = 50000},
      {id = "spell", type = "text", label = "Spell", default = "exori gran con"},
      {id = "safeRadius", type = "number", label = "Raio seguro", default = 2, min = 1, max = 5},
      {id = "maxDistance", type = "number", label = "Distancia target", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos acao (ms)", default = 280, min = 100, max = 5000}
    },
    onTick = function(params)
      local target = getAttackingTarget(params.maxDistance)
      if not target then return end
      local tPos = target:getPosition()
      if not tPos or hasOtherPlayerNear(tPos, params.safeRadius) then return end

      local acted = false
      if params.mode == "both" or params.mode == "rune" then
        acted = useWithItem(params.runeId, target) or acted
      end
      if params.mode == "both" or params.mode == "spell" then
        acted = castSpell(params.spell) or acted
      end
      if acted and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "safeSpells",
    title = "Safe Spells",
    category = "Safety",
    iconId = 3271,
    interval = 240,
    description = "Lanca spell apenas com area segura.",
    tags = {"safe", "spells"},
    fields = {
      {id = "spell", type = "text", label = "Spell", default = "exori gran con"},
      {id = "safeRadius", type = "number", label = "Raio seguro", default = 2, min = 1, max = 5},
      {id = "maxDistance", type = "number", label = "Distancia target", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos cast (ms)", default = 320, min = 100, max = 5000}
    },
    onTick = function(params)
      local target = getAttackingTarget(params.maxDistance)
      if not target then return end
      local tPos = target:getPosition()
      if not tPos or hasOtherPlayerNear(tPos, params.safeRadius) then return end
      if castSpell(params.spell) and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "safeRunes",
    title = "Safe Runes",
    category = "Safety",
    iconId = 3155,
    interval = 240,
    description = "Usa runa apenas com area segura.",
    tags = {"safe", "rune"},
    fields = {
      {id = "runeId", type = "number", label = "Runa ID", default = 3155, min = 100, max = 50000},
      {id = "safeRadius", type = "number", label = "Raio seguro", default = 2, min = 1, max = 5},
      {id = "maxDistance", type = "number", label = "Distancia target", default = 7, min = 1, max = 9},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 280, min = 100, max = 5000}
    },
    onTick = function(params)
      local target = getAttackingTarget(params.maxDistance)
      if not target then return end
      local tPos = target:getPosition()
      if not tPos or hasOtherPlayerNear(tPos, params.safeRadius) then return end
      if useWithItem(params.runeId, target) and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "fullSpell",
    title = "Full Spell",
    category = "Safety",
    iconId = 3197,
    interval = 260,
    description = "Rotacao de spells com checagem de seguranca.",
    tags = {"full", "spell", "rotation"},
    fields = {
      {id = "spellList", type = "text", label = "Lista (separar por ;)", default = "exori gran con;exori gran"},
      {id = "safeRadius", type = "number", label = "Raio seguro", default = 2, min = 1, max = 5},
      {id = "maxDistance", type = "number", label = "Distancia target", default = 7, min = 1, max = 9},
      {id = "stepDelay", type = "number", label = "Delay apos cast (ms)", default = 350, min = 100, max = 5000}
    },
    onTick = function(params, state)
      local target = getAttackingTarget(params.maxDistance)
      if not target then return end
      local tPos = target:getPosition()
      if not tPos or hasOtherPlayerNear(tPos, params.safeRadius) then return end

      state.runtime = state.runtime or {}
      local runtime = state.runtime
      runtime.spells = {}
      for token in tostring(params.spellList or ""):gmatch("[^;]+") do
        local spell = token:gsub("^%s+", ""):gsub("%s+$", "")
        if spell ~= "" then
          table.insert(runtime.spells, spell)
        end
      end
      if #runtime.spells == 0 then return end

      runtime.index = runtime.index or 1
      if runtime.index > #runtime.spells then runtime.index = 1 end
      local spell = runtime.spells[runtime.index]
      runtime.index = runtime.index + 1
      if castSpell(spell) and params.stepDelay > 0 then
        delay(params.stepDelay)
      end
    end
  },
  {
    key = "exivaSystem",
    title = "Exiva",
    category = "Suporte",
    iconId = 3200,
    interval = 700,
    description = "Exiva no player atual em target.",
    tags = {"exiva", "track", "player"},
    fields = {
      {id = "prefix", type = "text", label = "Prefixo", default = "exiva"},
      {id = "maxDistance", type = "number", label = "Distancia target", default = 8, min = 1, max = 9},
      {id = "onlyPlayers", type = "bool", label = "Somente players", default = true},
      {id = "delayMs", type = "number", label = "Delay apos exiva (ms)", default = 1000, min = 250, max = 10000}
    },
    onTick = function(params, state)
      local target = getAttackingTarget(params.maxDistance)
      if not target then return end
      if params.onlyPlayers and not isPlayerCreature(target) then return end
      local targetName = target.getName and target:getName() or ""
      if targetName == "" then return end

      state.runtime = state.runtime or {}
      local runtime = state.runtime
      local exivaText = string.format("%s %s", tostring(params.prefix or "exiva"), targetName)
      if runtime.lastText == exivaText and runtime.lastCast and nowMs() - runtime.lastCast < params.delayMs then
        return
      end
      if castSpell(exivaText) then
        runtime.lastText = exivaText
        runtime.lastCast = nowMs()
        if params.delayMs > 0 then delay(params.delayMs) end
      end
    end
  },
  {
    key = "guildPotHelper",
    title = "Pot Ally",
    category = "Suporte",
    iconId = 268,
    interval = 220,
    description = "Pede potion no chat e entrega potion para ally (guild/party) ate 1 sqm apos trigger. Requer potion em backpack/container aberto.",
    tags = {"pot", "potion", "guild", "party", "suporte"},
    fields = {
      {id = "potionId", type = "item", label = "Potion ID", default = 268, min = 100, max = 50000, tooltip = "PT:\nID da potion usada para entregar ao aliado.\n\nEN:\nPotion item ID used to supply allies."},
      {id = "requestTrigger", type = "text", label = "Trigger pedir potion", default = "pt", tooltip = "PT:\nPalavra que dispara o pedido e a fila de atendimento.\nExemplo: pt\n\nEN:\nKeyword that triggers requests and the assist queue.\nExample: pt"},
      {id = "hpRequestBelow", type = "number", label = "Pedir se HP <= (%)", default = 50, min = 0, max = 100, tooltip = "PT:\nSe HP ficar <= valor, envia pedido no chat.\n\nEN:\nIf HP is <= this value, it sends a chat request."},
      {id = "manaRequestBelow", type = "number", label = "Pedir se Mana <= (%)", default = 50, min = 0, max = 100, tooltip = "PT:\nSe Mana ficar <= valor, envia pedido no chat.\n\nEN:\nIf Mana is <= this value, it sends a chat request."},
      {id = "chatMode", type = "combo", label = "Canal pedido", default = "default", options = {
        {text = "Default", value = "default"},
        {text = "Party", value = "party"},
        {text = "Guild", value = "guild"}
      }, tooltip = "PT:\nEscolhe onde o bot vai pedir pot: Default, Party ou Guild.\n\nEN:\nChoose where the bot asks for pot: Default, Party, or Guild."},
      {id = "guildChannel", type = "text", label = "Canal Guild (nome/ID)", default = "", tooltip = "PT:\nQuando Canal=Guild, informe nome ou ID do canal aberto.\n\nEN:\nWhen Channel=Guild, set open channel name or ID."},
      {id = "requestCooldownMs", type = "number", label = "Delay novo pedido (ms)", default = 2000, min = 1000, max = 300000, tooltip = "PT:\nDelay minimo entre pedidos automaticos (anti-mute).\n\nEN:\nMinimum delay between auto requests (anti-mute)."},
      {id = "giveDelayMs", type = "number", label = "Delay apos dar pot (ms)", default = 900, min = 100, max = 10000, tooltip = "PT:\nDelay minimo entre um uso de pot e outro no aliado.\n\nEN:\nMinimum delay between each pot use on allies."}
    },
    onTick = function(params, moduleState)
      moduleState.runtime = moduleState.runtime or {}
      local runtime = moduleState.runtime
      runtime.pendingByName = runtime.pendingByName or {}
      runtime.lastRequestAt = tonumber(runtime.lastRequestAt) or 0
      runtime.lastGiveAt = tonumber(runtime.lastGiveAt) or 0
      runtime.lastWarnAt = tonumber(runtime.lastWarnAt) or 0

      if not runtime.talkRegistered and type(onTalk) == "function" then
        runtime.talkRegistered = true
        onTalk(function(sender, level, mode, text, channelId, talkPos)
          if moduleState.enabled ~= true then
            return
          end
          if not sender or not text then
            return
          end

          local cfg = moduleState.params or {}
          local triggerText = potHelper.trimText(cfg.requestTrigger or "")
          if triggerText == "" then
            return
          end

          local senderKey = potHelper.normalizeNameKey(sender)
          if senderKey == "" then
            return
          end
          if senderKey == potHelper.normalizeNameKey(potHelper.getLocalPlayerName()) then
            return
          end

          if not potHelper.talkMatchesConfiguredChannel(cfg.chatMode, cfg.guildChannel, channelId) then
            return
          end

          if not potHelper.messageStartsWithTrigger(text, triggerText) then
            return
          end

          runtime.pendingByName[senderKey] = {
            senderName = tostring(sender),
            requestedAt = nowMs()
          }
        end)
      end

      local nowTime = nowMs()
      local hpThreshold = clamp(tonumber(params.hpRequestBelow) or 0, 0, 100)
      local manaThreshold = clamp(tonumber(params.manaRequestBelow) or 0, 0, 100)
      local hpNow = potHelper.getHpPercentSafe()
      local manaNow = potHelper.getManaPercentSafe()
      local triggerText = potHelper.trimText(params.requestTrigger or "")
      local shouldRequest = (hpThreshold > 0 and hpNow <= hpThreshold)
        or (manaThreshold > 0 and manaNow <= manaThreshold)

      if shouldRequest and triggerText ~= "" then
        local requestCooldownMs = clamp(tonumber(params.requestCooldownMs) or 2000, 1000, 300000)
        if (nowTime - runtime.lastRequestAt) >= requestCooldownMs then
          local requestText = string.format("%s hp=%d mp=%d", triggerText, hpNow, manaNow)
          local sent, errText = potHelper.sendTextToConfiguredChat(params.chatMode, params.guildChannel, requestText)
          if sent then
            runtime.lastRequestAt = nowTime
          elseif (nowTime - runtime.lastWarnAt) >= 4000 then
            runtime.lastWarnAt = nowTime
            showMessage(string.format("[Pot Ally] %s", tostring(errText or "falha ao enviar pedido")))
          end
        end
      end

      local player = getPlayer()
      local playerPos = player and player:getPosition()
      if not playerPos then
        return
      end

      local potionId = clamp(tonumber(params.potionId) or 268, 100, 50000)
      local giveDelayMs = clamp(tonumber(params.giveDelayMs) or 900, 100, 10000)
      if (nowTime - runtime.lastGiveAt) < giveDelayMs then
        return
      end

      if not findItemById(potionId) then
        return
      end

      local bestKey = nil
      local bestCreature = nil
      local bestDistance = 99
      local bestRequestedAt = 0
      local expireKeys = {}
      local requestTimeoutMs = 8000

      for senderKey, requestData in pairs(runtime.pendingByName or {}) do
        local requestAt = tonumber(requestData and requestData.requestedAt) or 0
        if requestAt <= 0 or (nowTime - requestAt) > requestTimeoutMs then
          expireKeys[#expireKeys + 1] = senderKey
        else
          local senderName = requestData.senderName or senderKey
          local creature = potHelper.findVisiblePlayerByName(senderName)
          if creature and potHelper.isPartyOrGuildAllyCreature(creature) then
            local creaturePos = creature.getPosition and creature:getPosition() or nil
            if creaturePos and creaturePos.z == playerPos.z then
              local distance = distanceChebyshev(playerPos, creaturePos)
              if distance <= 1 then
                local betterByDistance = distance < bestDistance
                local betterByRecency = distance == bestDistance and requestAt > bestRequestedAt
                if not bestCreature or betterByDistance or betterByRecency then
                  bestKey = senderKey
                  bestCreature = creature
                  bestDistance = distance
                  bestRequestedAt = requestAt
                end
              end
            end
          end
        end
      end

      for _, expiredKey in ipairs(expireKeys) do
        runtime.pendingByName[expiredKey] = nil
      end

      if not bestCreature then
        return
      end

      local bestPos = bestCreature.getPosition and bestCreature:getPosition() or nil
      if not bestPos or bestPos.z ~= playerPos.z or distanceChebyshev(playerPos, bestPos) > 1 then
        return
      end

      if useWithItem(potionId, bestCreature) then
        runtime.lastGiveAt = nowTime
        if bestKey then
          runtime.pendingByName[bestKey] = nil
        end
        if giveDelayMs > 0 then
          delay(giveDelayMs)
        end
      end
    end,
    onToggle = function(enabled, params, moduleState)
      moduleState.runtime = moduleState.runtime or {}
      local runtime = moduleState.runtime
      if not enabled then
        runtime.pendingByName = {}
      end
    end
  },
  {
    key = "blessSystem",
    title = "Bless",
    category = "Suporte",
    iconId = 3241,
    interval = 1200,
    description = "Compra bless por comando.",
    tags = {"bless", "command"},
    fields = {
      {id = "buyAtLogin", type = "bool", label = "Comprar ao ligar", default = true},
      {id = "buyCommand", type = "text", label = "Comando bless", default = "!bless"},
      {id = "autoWhenZero", type = "bool", label = "Auto se bless=0", default = true},
      {id = "delayMs", type = "number", label = "Delay apos comando (ms)", default = 1200, min = 500, max = 15000}
    },
    onTick = function(params, state)
      state.runtime = state.runtime or {}
      local runtime = state.runtime

      if params.buyAtLogin and not runtime.loginBought then
        if castSpell(params.buyCommand) then
          runtime.loginBought = true
          if params.delayMs > 0 then delay(params.delayMs) end
          return
        end
      end

      if not params.autoWhenZero then return end
      local player = getPlayer()
      if not player or not player.getBlessings then return end
      local ok, blessings = pcall(function() return player:getBlessings() end)
      if ok and blessings == 0 then
        if castSpell(params.buyCommand) and params.delayMs > 0 then
          delay(params.delayMs)
        end
      end
    end
  },
  {
    key = "aolSystem",
    title = "AOL",
    category = "Suporte",
    iconId = 3057,
    interval = 900,
    description = "Equipa AOL automaticamente no slot de amuleto e pode controlar CaveBot/TargetBot pela disponibilidade de AOL.",
    tags = {"aol", "equip"},
    fields = {
      {id = "aolId", type = "number", label = "AOL ID", default = 3057, min = 100, max = 50000},
      {id = "buyCommand", type = "text", label = "Comando compra AOL", default = "!aol"},
      {id = "buyCooldownMs", type = "number", label = "Cooldown compra (ms)", default = 4000, min = 500, max = 30000},
      {id = "delayMs", type = "number", label = "Delay apos equipar (ms)", default = 1200, min = 250, max = 10000},
      {id = "disableCavebotNoAol", type = "bool", label = "Desligar CaveBot sem AOL", default = false},
      {id = "enableCavebotWithAol", type = "bool", label = "Ligar CaveBot com AOL", default = false},
      {id = "disableTargetbotNoAol", type = "bool", label = "Desligar TargetBot sem AOL", default = false},
      {id = "enableTargetbotWithAol", type = "bool", label = "Ligar TargetBot com AOL", default = false}
    },
    onTick = function(params, moduleState)
      if type(getSlot) ~= "function" or type(moveToSlot) ~= "function" then return end
      moduleState.runtime = moduleState.runtime or {}
      local runtime = moduleState.runtime
      local slotNeck = resolveGlobal("SlotNeck") or 2
      local neckItem = getSlot(slotNeck)
      local aolId = clamp(tonumber(params.aolId) or 3057, 100, 50000)
      local neckItemId = nil
      if neckItem and neckItem.getId then
        neckItemId = neckItem:getId()
      end

      local aolItem = nil
      local hasAolAvailable = (type(neckItemId) == "number" and neckItemId == aolId)
      if not hasAolAvailable then
        aolItem = findItemById(aolId)
        hasAolAvailable = aolItem ~= nil
      end

      local function applyBotToggleByAol(enableWhenHas, disableWhenMissing, setExternalFn, readExternalFn, runtimeKey)
        if type(setExternalFn) ~= "function" then
          return
        end

        local allowEnable = enableWhenHas == true
        local allowDisable = disableWhenMissing == true
        if not allowEnable and not allowDisable then
          runtime[runtimeKey] = nil
          return
        end

        local desiredState = nil
        if hasAolAvailable and allowEnable then
          desiredState = true
        elseif (not hasAolAvailable) and allowDisable then
          desiredState = false
        end

        if type(desiredState) ~= "boolean" then
          runtime[runtimeKey] = nil
          return
        end

        local currentState = nil
        if type(readExternalFn) == "function" then
          local okRead, value = pcall(readExternalFn)
          if okRead and type(value) == "boolean" then
            currentState = value
          end
        end

        if type(currentState) == "boolean" then
          if currentState == desiredState then
            runtime[runtimeKey] = desiredState
            return
          end
        elseif runtime[runtimeKey] == desiredState then
          return
        end

        setExternalFn(desiredState)
        runtime[runtimeKey] = desiredState
      end

      applyBotToggleByAol(
        params.enableCavebotWithAol,
        params.disableCavebotNoAol,
        setCavebotEnabledExternal,
        isCavebotEnabledExternal,
        "lastCavebotDesired"
      )

      applyBotToggleByAol(
        params.enableTargetbotWithAol,
        params.disableTargetbotNoAol,
        setTargetbotEnabledExternal,
        isTargetbotEnabledExternal,
        "lastTargetbotDesired"
      )

      if neckItem then return end
      if not aolItem then
        local commandText = tostring(params.buyCommand or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if commandText == "" then
          return
        end
        local nowTime = nowMs()
        local cooldown = clamp(tonumber(params.buyCooldownMs) or 4000, 500, 30000)
        if runtime.lastBuyAt and (nowTime - runtime.lastBuyAt) < cooldown then
          return
        end
        if castSpell(commandText) then
          runtime.lastBuyAt = nowTime
        end
        return
      end
      moveToSlot(aolItem, slotNeck, 1)
      if params.delayMs > 0 then delay(params.delayMs) end
    end,
    onToggle = function(enabled, params, moduleState)
      moduleState.runtime = moduleState.runtime or {}
      if not enabled then
        moduleState.runtime.lastCavebotDesired = nil
        moduleState.runtime.lastTargetbotDesired = nil
      end
    end
  },
  {
    key = "manaTraining",
    title = "Mana Training",
    category = "Suporte",
    iconId = 268,
    interval = 1500,
    description = "Treino simples por spell com mana minima.",
    tags = {"mana", "training", "spell"},
    fields = {
      {id = "spell", type = "text", label = "Spell", default = "utevo lux"},
      {id = "manaMin", type = "number", label = "Mana minima (%)", default = 80, min = 1, max = 100},
      {id = "delayMs", type = "number", label = "Delay apos cast (ms)", default = 1400, min = 250, max = 12000}
    },
    onTick = function(params)
      if manapercent() < params.manaMin then return end
      if castSpell(params.spell) and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "levitateSystem",
    title = "Levitate",
    category = "Utilidade",
    iconId = 3197,
    interval = 1200,
    description = "Cast automatico de levitate (up/down).",
    tags = {"levitate", "stairs", "utility"},
    fields = {
      {id = "mode", type = "combo", label = "Modo", default = "up", options = {
        {text = "Up", value = "up"},
        {text = "Down", value = "down"}
      }},
      {id = "spellUp", type = "text", label = "Spell Up", default = "exani hur up"},
      {id = "spellDown", type = "text", label = "Spell Down", default = "exani hur down"},
      {id = "delayMs", type = "number", label = "Delay apos cast (ms)", default = 1200, min = 250, max = 12000}
    },
    onTick = function(params)
      local spell = params.mode == "down" and params.spellDown or params.spellUp
      if castSpell(spell) and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "mwNorth",
    title = "MW North",
    category = "Walls",
    iconId = 2128,
    interval = 320,
    description = "Magic Wall no tile ao norte.",
    tags = {"mw", "wall", "north"},
    fields = {
      {id = "runeId", type = "number", label = "Runa MW ID", default = 3180, min = 100, max = 50000},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 600, min = 100, max = 5000}
    },
    onTick = function(params)
      local player = getPlayer()
      local pos = player and player:getPosition()
      if not pos then return end
      if useItemOnTilePos(params.runeId, getOffsetPos(pos, 0, -1)) and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "mwNorthEast",
    title = "MW NorthEast",
    category = "Walls",
    iconId = 2128,
    interval = 320,
    description = "Magic Wall no tile nordeste.",
    tags = {"mw", "wall", "ne"},
    fields = {
      {id = "runeId", type = "number", label = "Runa MW ID", default = 3180, min = 100, max = 50000},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 600, min = 100, max = 5000}
    },
    onTick = function(params)
      local player = getPlayer()
      local pos = player and player:getPosition()
      if not pos then return end
      if useItemOnTilePos(params.runeId, getOffsetPos(pos, 1, -1)) and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "mwNorthWest",
    title = "MW NorthWest",
    category = "Walls",
    iconId = 2128,
    interval = 320,
    description = "Magic Wall no tile noroeste.",
    tags = {"mw", "wall", "nw"},
    fields = {
      {id = "runeId", type = "number", label = "Runa MW ID", default = 3180, min = 100, max = 50000},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 600, min = 100, max = 5000}
    },
    onTick = function(params)
      local player = getPlayer()
      local pos = player and player:getPosition()
      if not pos then return end
      if useItemOnTilePos(params.runeId, getOffsetPos(pos, -1, -1)) and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "mwSouth",
    title = "MW South",
    category = "Walls",
    iconId = 2128,
    interval = 320,
    description = "Magic Wall no tile sul.",
    tags = {"mw", "wall", "south"},
    fields = {
      {id = "runeId", type = "number", label = "Runa MW ID", default = 3180, min = 100, max = 50000},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 600, min = 100, max = 5000}
    },
    onTick = function(params)
      local player = getPlayer()
      local pos = player and player:getPosition()
      if not pos then return end
      if useItemOnTilePos(params.runeId, getOffsetPos(pos, 0, 1)) and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "mwSouthEast",
    title = "MW SouthEast",
    category = "Walls",
    iconId = 2128,
    interval = 320,
    description = "Magic Wall no tile sudeste.",
    tags = {"mw", "wall", "se"},
    fields = {
      {id = "runeId", type = "number", label = "Runa MW ID", default = 3180, min = 100, max = 50000},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 600, min = 100, max = 5000}
    },
    onTick = function(params)
      local player = getPlayer()
      local pos = player and player:getPosition()
      if not pos then return end
      if useItemOnTilePos(params.runeId, getOffsetPos(pos, 1, 1)) and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "mwSouthWest",
    title = "MW SouthWest",
    category = "Walls",
    iconId = 2128,
    interval = 320,
    description = "Magic Wall no tile sudoeste.",
    tags = {"mw", "wall", "sw"},
    fields = {
      {id = "runeId", type = "number", label = "Runa MW ID", default = 3180, min = 100, max = 50000},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 600, min = 100, max = 5000}
    },
    onTick = function(params)
      local player = getPlayer()
      local pos = player and player:getPosition()
      if not pos then return end
      if useItemOnTilePos(params.runeId, getOffsetPos(pos, -1, 1)) and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "mwEast",
    title = "MW East",
    category = "Walls",
    iconId = 2128,
    interval = 320,
    description = "Magic Wall no tile leste.",
    tags = {"mw", "wall", "east"},
    fields = {
      {id = "runeId", type = "number", label = "Runa MW ID", default = 3180, min = 100, max = 50000},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 600, min = 100, max = 5000}
    },
    onTick = function(params)
      local player = getPlayer()
      local pos = player and player:getPosition()
      if not pos then return end
      if useItemOnTilePos(params.runeId, getOffsetPos(pos, 1, 0)) and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  },
  {
    key = "mwWest",
    title = "MW West",
    category = "Walls",
    iconId = 2128,
    interval = 320,
    description = "Magic Wall no tile oeste.",
    tags = {"mw", "wall", "west"},
    fields = {
      {id = "runeId", type = "number", label = "Runa MW ID", default = 3180, min = 100, max = 50000},
      {id = "delayMs", type = "number", label = "Delay apos uso (ms)", default = 600, min = 100, max = 5000}
    },
    onTick = function(params)
      local player = getPlayer()
      local pos = player and player:getPosition()
      if not pos then return end
      if useItemOnTilePos(params.runeId, getOffsetPos(pos, -1, 0)) and params.delayMs > 0 then
        delay(params.delayMs)
      end
    end
  }
}

local function applyAttackMonsterFilters()
  for _, definition in ipairs(moduleDefinitions) do
    if definition.category == "Ataque" and type(definition.onTick) == "function" then
      definition.fields = definition.fields or {}
      local hasField = false
      for _, field in ipairs(definition.fields) do
        if field.id == "minMonsters" then
          hasField = true
          break
        end
      end
      if not hasField then
        table.insert(definition.fields, {
          id = "minMonsters",
          type = "number",
          label = "Qtd monstros minima",
          default = 1,
          min = 1,
          max = 50
        })
      end

      if not definition._monsterFilterWrapped then
        local originalTick = definition.onTick
        definition.onTick = function(params, ...)
          if not shouldRunByMonsterCount(params, 7) then
            return
          end
          return originalTick(params, ...)
        end
        definition._monsterFilterWrapped = true
      end
    end
  end
end

applyAttackMonsterFilters()

table.sort(moduleDefinitions, function(a, b)
  if a.category == b.category then
    return a.title < b.title
  end
  return a.category < b.category
end)

local definitionsByKey = {}
local categories = {}
for _, definition in ipairs(moduleDefinitions) do
  definitionsByKey[definition.key] = definition
  categories[definition.category] = true
end

local alwaysSyncedControlModules = {
  cavebotControl = true,
  targetbotControl = true,
  attackModuleOff = true,
  followModuleOff = true,
  navModuleOff = true,
  pvpModuleOff = true,
  hpToolsModuleOff = true,
  ringModuleOff = true,
  amuletModuleOff = true,
  swapSetModuleOff = true
}

local categoryList = {"Todos"}
for categoryName, _ in pairs(categories) do
  table.insert(categoryList, categoryName)
end
table.sort(categoryList, function(a, b)
  if a == "Todos" then return true end
  if b == "Todos" then return false end
  return a < b
end)

local categoryLabels = {
  pt = {
    Todos = "Todos",
    Ataque = "Ataque",
    Controle = "Controle",
    Defesa = "Defesa",
    Suporte = "Suporte",
    Utilidade = "Utilidade",
    Safety = "Safety",
    Walls = "Walls",
    PVP = "PVP"
  },
  en = {
    Todos = "All",
    Ataque = "Attack",
    Controle = "Control",
    Defesa = "Defense",
    Suporte = "Support",
    Utilidade = "Utility",
    Safety = "Safety",
    Walls = "Walls",
    PVP = "PVP"
  }
}

local titleLabelsEn = {
  coletarSystem = "Collect",
  revideSystem = "Retaliate",
  antiPushCoin = "AntiPush",
  exetaRes = "Exeta Res"
}

ImperialElfBot = ImperialElfBot or {}
ImperialElfBot.fieldLabelsEn = {
  actionLockMs = "Action lock (ms)",
  aolId = "AOL ID",
  autoWhenZero = "Auto when bless is 0",
  buyAtLogin = "Buy on login",
  buyCommand = "AOL purchase command",
  buyCooldownMs = "Purchase cooldown (ms)",
  cancelSpell = "Cancel spell",
  chatMode = "Request channel",
  delayMs = "Delay after use (ms)",
  disableCavebotNoAol = "Disable CaveBot without AOL",
  disableTargetbotNoAol = "Disable TargetBot without AOL",
  dropAmount = "Amount per drop",
  enableCavebotWithAol = "Enable CaveBot with AOL",
  enableTargetbotWithAol = "Enable TargetBot with AOL",
  forceChase = "Force chase on retaliation",
  forceSafeFight = "Disable safe fight on retaliation",
  giveDelayMs = "Potion give delay (ms)",
  guildChannel = "Guild channel (name/ID)",
  hpAboveCancel = "HP above (%) to cancel",
  hpBelow = "HP below (%)",
  hpPercent = "Maximum HP (%)",
  hpRequestBelow = "Request below HP (%)",
  huntMode = "Disable Cave/Target on retaliation",
  ignoredNicknames = "Ignored nicknames (comma-separated)",
  ignorePartyAttackers = "Ignore party attackers",
  ignoreSameGuildAttackers = "Ignore same-guild attackers",
  itemId = "Item ID",
  itemIds = "IDs (comma-separated)",
  laddersIds = "Ladder IDs",
  manaMin = "Minimum mana (%)",
  manaRequestBelow = "Request below mana (%)",
  maxDistance = "Target distance",
  maxStack = "Maximum items on tile",
  minCap = "Minimum capacity",
  mode = "Mode",
  nearTargetDistance = "Distance to lock chase",
  needTarget = "Require target",
  onlyPlayers = "Players only",
  pathMaxDistance = "Maximum path distance",
  potionId = "Potion ID",
  prefix = "Prefix",
  range = "Range (sqm)",
  reacquireDelay = "Re-attack interval (ms)",
  renewOnly = "Renew utamo only (do not cancel)",
  requestCooldownMs = "New request delay (ms)",
  requestTrigger = "Potion request trigger",
  requireTarget = "Require target",
  restoreHuntOnIdle = "Restore Cave/Target without target",
  ropeHolesIds = "Rope hole IDs",
  ropeId = "Rope ID",
  runeId = "Rune ID",
  safeRadius = "Safe radius",
  searchRange = "Tile search radius",
  sewerId = "Sewer ID",
  sewersIds = "Sewer IDs",
  showDebug = "Show logs",
  showStopMsg = "Show stop message",
  spell = "Spell",
  spellDown = "Down spell",
  spellList = "List (semicolon-separated)",
  spellUp = "Up spell",
  stepDelay = "Delay after cast (ms)",
  targetLostSeconds = "Maximum target lost time (s)",
  targetTimeoutMs = "Target timeout (ms)"
}

local function categoryDisplayName(categoryName)
  local language = getElfLanguage()
  local labels = categoryLabels[language] or categoryLabels.pt
  return labels[categoryName] or categoryName
end

local function categoryFromDisplay(displayName)
  local text = tostring(displayName or "")
  for internalName, translatedName in pairs(categoryLabels.en) do
    if text == translatedName then
      return internalName
    end
  end
  for internalName, translatedName in pairs(categoryLabels.pt) do
    if text == translatedName then
      return internalName
    end
  end
  return text ~= "" and text or "Todos"
end

local function isKnownCategory(categoryName)
  if categoryName == "Todos" then
    return true
  end
  return categories[categoryName] == true
end

local function moduleDisplayTitle(definition)
  if not definition then
    return ""
  end
  if getElfLanguage() == "en" then
    return titleLabelsEn[definition.key] or definition.enTitle or definition.title
  end
  return definition.ptTitle or definition.title
end

function ImperialElfBot.fieldDisplayLabel(field)
  if not field then
    return ""
  end
  if getElfLanguage() == "en" then
    return field.enLabel or ImperialElfBot.fieldLabelsEn[field.id] or field.label or field.id
  end
  return field.label or field.id
end

local function moduleDisplayDescription(definition)
  if not definition then
    return ""
  end
  if getElfLanguage() == "en" then
    return definition.enDescription or ("Configure " .. moduleDisplayTitle(definition) .. ".")
  end
  return definition.description or moduleDisplayTitle(definition)
end

local function setupMetaText(definition, itemId)
  if getElfLanguage() == "en" then
    return string.format("Category: %s | Current icon ID: %d", categoryDisplayName(definition.category), itemId)
  end
  return string.format("Categoria: %s | Icon atual ID: %d", categoryDisplayName(definition.category), itemId)
end

local function defaultFromField(field)
  if field.default ~= nil then
    return deepcopy(field.default)
  end
  if field.type == "number" then return 0 end
  if field.type == "bool" then return false end
  if field.type == "itemList" then return {} end
  if field.type == "item" then return 0 end
  if field.type == "combo" and field.options and field.options[1] then
    return deepcopy(field.options[1].value or field.options[1].text)
  end
  return ""
end

function sanitizeNicknameCsv(value)
  local normalized = {}
  local seen = {}
  local source = tostring(value or "")
  source = source:gsub("[\r\n;]+", ",")

  for rawName in string.gmatch(source, "[^,]+") do
    local cleaned = tostring(rawName):gsub("^%s+", ""):gsub("%s+$", "")
    if cleaned ~= "" then
      local key = normalizeText(cleaned)
      if key ~= "" and not seen[key] then
        seen[key] = true
        table.insert(normalized, cleaned)
      end
    end
  end

  return table.concat(normalized, ",")
end

function countNicknameCsvEntries(value)
  local csv = sanitizeNicknameCsv(value)
  if csv == "" then
    return 0
  end
  local count = 0
  for _ in string.gmatch(csv, "[^,]+") do
    count = count + 1
  end
  return count
end

local function sanitizeFieldValue(field, value)
  if field.id == "itemIds" and field.type == "text" then
    local ordered = {}
    local seen = {}
    local source = tostring(value or "")
    for rawToken in string.gmatch(source, "%d+") do
      local id = tonumber(rawToken)
      if id and id >= 100 then
        id = math.floor(id)
        if not seen[id] then
          seen[id] = true
          ordered[#ordered + 1] = id
        end
      end
    end
    if #ordered == 0 then
      source = tostring(defaultFromField(field) or "")
      for rawToken in string.gmatch(source, "%d+") do
        local id = tonumber(rawToken)
        if id and id >= 100 then
          id = math.floor(id)
          if not seen[id] then
            seen[id] = true
            ordered[#ordered + 1] = id
          end
        end
      end
    end
    return table.concat(ordered, ",")
  end

  if field.id == "ignoredNicknames" then
    local fallback = sanitizeNicknameCsv(defaultFromField(field))
    local normalized = sanitizeNicknameCsv(value)
    if normalized == "" then
      return fallback
    end
    return normalized
  end

  if field.type == "number" then
    local numberValue = tonumber(value)
    if numberValue == nil then
      numberValue = tonumber(defaultFromField(field)) or 0
    end
    return clamp(numberValue, field.min, field.max)
  end
  if field.type == "bool" then
    return value == true
  end
  if field.type == "combo" then
    local validMap = {}
    for _, option in ipairs(field.options or {}) do
      validMap[option.value or option.text] = true
    end
    if validMap[value] then
      return value
    end
    return defaultFromField(field)
  end
  if field.type == "item" then
    local fallback = tonumber(defaultFromField(field)) or 0
    local min = tonumber(field.min) or 100
    local max = tonumber(field.max) or 50000
    return clamp(tonumber(value) or fallback, min, max)
  end
  if field.type == "itemList" then
    local defaults = normalizeItemIdArray(defaultFromField(field), {})
    return normalizeItemIdArray(value, defaults)
  end
  if type(value) == "table" then
    local ids = normalizeItemIdArray(value, {})
    if #ids > 0 then
      return table.concat(ids, ",")
    end
  end
  if value == nil then
    return tostring(defaultFromField(field))
  end
  return tostring(value)
end

local ICON_TEXT_MAX_CHARS = 10

local function painelProfileLoaded()
  if type(ImperialElfBot_IsProfileLoaded) == "function" then
    local ok, loaded = pcall(ImperialElfBot_IsProfileLoaded)
    return ok and loaded == true
  end
  return modules and modules.game_bot and modules.game_bot.elfbotProfileLoadedThisSession == true
end

local function sanitizeIconText(value)
  if value == nil then
    return ""
  end

  local text = tostring(value)
  text = text:gsub("[\r\n\t]+", " ")
  text = text:gsub("%s+", " ")
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  if #text > ICON_TEXT_MAX_CHARS then
    text = text:sub(1, ICON_TEXT_MAX_CHARS)
  end
  return text
end

local function ensureModuleState(definition)
  for key, value in pairs(panelStorage.modules or {}) do
    if type(key) ~= "string" or not definitionsByKey[key] or type(value) ~= "table" then
      panelStorage.modules[key] = nil
    end
  end

  if type(panelStorage.modules[definition.key]) ~= "table" then
    panelStorage.modules[definition.key] = {}
  end
  local moduleState = panelStorage.modules[definition.key]
  if moduleState.enabled == nil then
    moduleState.enabled = false
  else
    moduleState.enabled = moduleState.enabled == true
  end

  if moduleState.showIcon == nil then
    moduleState.showIcon = true
  else
    moduleState.showIcon = moduleState.showIcon == true
  end

  moduleState.iconItemId = clamp(tonumber(moduleState.iconItemId) or definition.iconId, 100, 50000)
  moduleState.iconText = sanitizeIconText(moduleState.iconText)
  local iconPosX, iconPosY = getIconPositionPercent("PIC_" .. definition.key)
  moduleState.iconPosX = clamp(tonumber(moduleState.iconPosX) or iconPosX, 0, 100)
  moduleState.iconPosY = clamp(tonumber(moduleState.iconPosY) or iconPosY, 0, 100)

  if type(moduleState.params) ~= "table" then
    moduleState.params = {}
  end
  local allowedParamKeys = {}
  for _, field in ipairs(definition.fields or {}) do
    allowedParamKeys[field.id] = true
    moduleState.params[field.id] = sanitizeFieldValue(field, moduleState.params[field.id])
  end
  if alwaysSyncedControlModules[definition.key] then
    allowedParamKeys.keepSynced = true
    moduleState.params.keepSynced = true
  else
    moduleState.params.keepSynced = nil
  end
  for key, _ in pairs(moduleState.params) do
    if allowedParamKeys[key] ~= true then
      moduleState.params[key] = nil
    end
  end

  for key, _ in pairs(moduleState) do
    if key ~= "enabled"
      and key ~= "showIcon"
      and key ~= "iconItemId"
      and key ~= "iconText"
      and key ~= "iconPosX"
      and key ~= "iconPosY"
      and key ~= "params" then
      moduleState[key] = nil
    end
  end

  -- Runtime data must not stay inside storage-backed tables.
  moduleState.runtime = nil
  moduleState._superdashRuntime = nil
  return moduleState
end

for _, definition in ipairs(moduleDefinitions) do
  ensureModuleState(definition)
end

local function applyDefaultIconLayoutByCategory()
  local fillOnlyMissing = panelStorage.ui.iconLayoutVersion and panelStorage.ui.iconLayoutVersion >= 5

  local categoryPriority = {
    Controle = 1,
    Ataque = 2,
    Defesa = 3,
    Suporte = 4,
    Utilidade = 5,
    Safety = 6,
    Walls = 7
  }

  local grouped = {}
  for _, definition in ipairs(moduleDefinitions) do
    grouped[definition.category] = grouped[definition.category] or {}
    table.insert(grouped[definition.category], definition)
  end

  local orderedCategories = {}
  for categoryName, _ in pairs(grouped) do
    table.insert(orderedCategories, categoryName)
  end
  table.sort(orderedCategories, function(a, b)
    local pa = categoryPriority[a] or 999
    local pb = categoryPriority[b] or 999
    if pa == pb then
      return a < b
    end
    return pa < pb
  end)

  local xColumns = {0, 6, 12, 17, 86, 90, 95, 100}
  local yRows = {}
  for y = 4, 96, 9 do
    table.insert(yRows, y)
  end
  local rowsPerColumn = #yRows

  local categoryColumnsMap = {}
  local totalColumns = 0
  for _, categoryName in ipairs(orderedCategories) do
    local defs = grouped[categoryName]
    local columns = math.max(1, math.ceil(#defs / rowsPerColumn))
    categoryColumnsMap[categoryName] = columns
    totalColumns = totalColumns + columns
  end

  local function resolveColumnX(columnIndex)
    local idx = columnIndex + 1
    if idx < 1 then
      idx = 1
    end
    if idx > #xColumns then
      idx = #xColumns
    end
    return xColumns[idx]
  end

  local globalColumn = 0

  for categoryIndex, categoryName in ipairs(orderedCategories) do
    local defs = grouped[categoryName]
    table.sort(defs, function(a, b) return a.title < b.title end)

    local categoryColumns = categoryColumnsMap[categoryName] or 1
    local categoryBaseColumn = globalColumn

    for i, definition in ipairs(defs) do
      local itemCol = math.floor((i - 1) / rowsPerColumn)
      local rowIndex = ((i - 1) % rowsPerColumn) + 1
      local posX = resolveColumnX(categoryBaseColumn + itemCol)
      local posY = yRows[rowIndex]
      local preferredPos = definition.defaultPos
      if type(preferredPos) == "table" then
        posX = clamp(tonumber(preferredPos.x) or posX, 0, 100)
        posY = clamp(tonumber(preferredPos.y) or posY, 0, 100)
      end

      local iconId = "PIC_" .. definition.key
      local cfg = ensureIconStorageConfig(iconId)
      local hasStoredPos = cfg and type(cfg.x) == "number" and type(cfg.y) == "number"
      if cfg and (not fillOnlyMissing or not hasStoredPos) then
        cfg.x = posX / 100
        cfg.y = posY / 100

        local moduleState = panelStorage.modules[definition.key]
        if type(moduleState) == "table" then
          moduleState.iconPosX = posX
          moduleState.iconPosY = posY
        end
      end
    end

    globalColumn = globalColumn + categoryColumns
  end

  if not fillOnlyMissing then
    panelStorage.ui.iconLayoutVersion = 5
  end
end

applyDefaultIconLayoutByCategory()

local rootWidget = g_ui.getRootWidget()
if not rootWidget then
  warn("[PainelIcones] root widget indisponivel")
  return
end

local mainWindow = g_ui.createWidget("PainelDeIconesWindow", rootWidget)
mainWindow:hide()

local setupWindow = g_ui.createWidget("PainelDeIconesSetupWindow", rootWidget)
setupWindow:hide()

local state = {
  mainWindow = mainWindow,
  setupWindow = setupWindow,
  rows = {},
  icons = {},
  runners = {},
  setupFields = {},
  currentSetupKey = nil,
  nickCsvEditorWindow = nil,
  moduleRuntime = {}
}

local function updateRowVisual(moduleKey)
  local definition = definitionsByKey[moduleKey]
  local row = state.rows[moduleKey]
  if not definition or not row then return end

  local moduleState = ensureModuleState(definition)
  if row.iconItem and row.iconItem.setItemId then
    row.iconItem:setItemId(moduleState.iconItemId)
  end
  local captionPreview = moduleState.iconText ~= "" and moduleState.iconText or picText("padrao automatico", "automatic default")
  local ptTooltip = string.format("%s\nItem ID atual: %d\nTexto do icone: %s", definition.description, moduleState.iconItemId, captionPreview)
  local enTooltip = string.format("Module: %s\nCurrent item ID: %d\nIcon text: %s", moduleDisplayTitle(definition), moduleState.iconItemId, captionPreview)
  if definition.key == "guildPotHelper" then
    local p = moduleState.params or {}
    local trigger = tostring(p.requestTrigger or "pt")
    local hpThreshold = clamp(tonumber(p.hpRequestBelow) or 50, 0, 100)
    local manaThreshold = clamp(tonumber(p.manaRequestBelow) or 50, 0, 100)
    local requestCooldown = clamp(tonumber(p.requestCooldownMs) or 2000, 1000, 300000)
    local chatMode = tostring(p.chatMode or "default")
    local guildChannel = tostring(p.guildChannel or "")
    local guildSuffix = guildChannel ~= "" and (" | Guild: " .. guildChannel) or ""
    ptTooltip = string.format(
      "%s\nTrigger: %s | HP<=%d%% ou Mana<=%d%% | Delay pedido: %dms\nCanal: %s%s\nEntrega somente para Party/Guild ate 1 SQM.\nRequer potion em backpack/container aberto.\nItem ID atual: %d\nTexto do icone: %s",
      definition.description,
      trigger,
      hpThreshold,
      manaThreshold,
      requestCooldown,
      chatMode,
      guildSuffix,
      moduleState.iconItemId,
      captionPreview
    )
    enTooltip = string.format(
      "%s\nTrigger: %s | HP<=%d%% or Mana<=%d%% | Request delay: %dms\nChannel: %s%s\nSupplies only Party/Guild allies within 1 SQM.\nRequires potion in an open backpack/container.\nCurrent item ID: %d\nIcon text: %s",
      definition.title,
      trigger,
      hpThreshold,
      manaThreshold,
      requestCooldown,
      chatMode,
      guildSuffix,
      moduleState.iconItemId,
      captionPreview
    )
  end
  row:setTooltip(buildBilingualTooltip(ptTooltip, enTooltip))

  if moduleState.showIcon then
    row.statusLabel:setText(picText("SHOW", "SHOW"))
    row.statusLabel:setColor("#22c55e")
  else
    row.statusLabel:setText(picText("HIDE", "HIDE"))
    row.statusLabel:setColor("#ef4444")
  end

  if row.setBackgroundColor then
    row:setBackgroundColor("#4e4e4e")
  end
  if row.setImageColor then
    row:setImageColor("#4e4e4e")
  end
  row:setBorderColor("#666666")
end

local function setIconItemId(iconWidget, itemId)
  if not iconWidget then
    return false
  end

  local visualId = clamp(tonumber(itemId) or 0, 0, 50000)
  if iconWidget.item and iconWidget.item.setItemId then
    iconWidget.item:setItemId(visualId)
    if iconWidget.item.setItemCount then
      iconWidget.item:setItemCount(1)
    end
    if iconWidget.item.setShowCount then
      iconWidget.item:setShowCount(false)
    end
    return true
  end

  if iconWidget.setItemId then
    iconWidget:setItemId(visualId)
    return true
  end

  return false
end

local function buildIconCaption(definition, moduleState)
  if moduleState and moduleState.iconText and moduleState.iconText ~= "" then
    return sanitizeIconText(moduleState.iconText)
  end

  local shortCaptions = {
    sdTarget = "AttackRune",
    uhSelf = "UHSelf",
    paralyzeRune = "Paralyze",
    sdRune = "SD",
    avalancheRune = "Avalanch",
    stoneShowerRune = "StoneShwr",
    thunderstormRune = "Thunder",
    gfbRune = "GFB",
    knightAttackSpell = "KSpell",
    paladinAttackSpell = "PSpell",
    druidAttackSpell = "DSpell",
    sorcererAttackSpell = "SSpell",
    cavebotControl = "CaveBot",
    targetbotControl = "TargetBot",
    attackModuleOff = "Attack",
    hpToolsModuleOff = "HPTools",
    superdashControl = "Superdash",
    followModuleOff = "Follow",
    navModuleOff = "Nav",
    pvpModuleOff = "PVP",
    ringModuleOff = "Ring",
    amuletModuleOff = "Amulet",
    utamoVita = "Utamo",
    fireBomb = "FireBomb",
    holdTarget = "HoldTarget",
    antiPushCoin = "AntPush",
    exetaRes = "ExetaRes",
    macheteAuto = "Machete",
    sewerSystem = "Sewer",
    revideSystem = "Revide",
    fullChaseSystem = "FullChase",
    attackSpell = "AtkSpell",
    magnetSystem = "Magnet",
    coletarSystem = "Coletar",
    safeRuneSpell = "SafeRune",
    safeSpells = "SafeSpells",
    safeRunes = "SafeRunes",
    fullSpell = "FullSpell",
    exivaSystem = "Exiva",
    guildPotHelper = "PotAlly",
    blessSystem = "Bless",
    aolSystem = "AOL",
    manaTraining = "ManaTrain",
    levitateSystem = "Levitate",
    mwNorth = "MWNorth",
    mwNorthEast = "MWNEast",
    mwNorthWest = "MWNWest",
    mwSouth = "MWSouth",
    mwSouthEast = "MWSEast",
    mwSouthWest = "MWSWest",
    mwEast = "MWEast",
    mwWest = "MWWest"
  }

  if shortCaptions[definition.key] then
    return sanitizeIconText(shortCaptions[definition.key])
  end

  return sanitizeIconText(definition.title or "Icon")
end

local function configureIconLayout(iconWidget)
  if not iconWidget then
    return
  end

  local widgetWidth = 76
  if iconWidget.setWidth then
    iconWidget:setWidth(widgetWidth)
  elseif iconWidget.setSize and iconWidget.getHeight then
    iconWidget:setSize({width = widgetWidth, height = iconWidget:getHeight()})
  end

  if iconWidget.item then
    local itemWidth = (iconWidget.item.getWidth and iconWidget.item:getWidth()) or 32
    local centeredX = math.max(0, math.floor((widgetWidth - itemWidth) / 2))
    if iconWidget.item.setX then
      iconWidget.item:setX(centeredX)
    end
    if iconWidget.item.setPhantom then
      iconWidget.item:setPhantom(true)
    end
    if iconWidget.item.setDraggable then
      iconWidget.item:setDraggable(false)
    end
  end

  if iconWidget.text then
    if iconWidget.text.setTextWrap then
      iconWidget.text:setTextWrap(false)
    end
    if iconWidget.text.setTextAutoResize then
      iconWidget.text:setTextAutoResize(false)
    end
    if iconWidget.text.setWidth then
      iconWidget.text:setWidth(widgetWidth)
    end
    if iconWidget.text.setX then
      iconWidget.text:setX(0)
    end
    local centerAlign = AlignCenter or AlignHCenter
    if iconWidget.text.setTextAlign and centerAlign then
      iconWidget.text:setTextAlign(centerAlign)
    end
    if iconWidget.text.setPhantom then
      iconWidget.text:setPhantom(true)
    end
    if iconWidget.text.setDraggable then
      iconWidget.text:setDraggable(false)
    end
    iconWidget.text:setFont("verdana-11px-rounded")
  end
end

local function updateIconVisual(moduleKey)
  local definition = definitionsByKey[moduleKey]
  local icon = state.icons[moduleKey]
  if not definition or not icon then return end

  local moduleState = ensureModuleState(definition)
  local enabled = moduleState.enabled == true

  setIconItemId(icon, moduleState.iconItemId)
  configureIconLayout(icon)

  if icon.text then
    icon.text:setText(buildIconCaption(definition, moduleState))
    icon.text:setColor(enabled and "#2cff2c" or "#ff4040")
    icon.text:show()
  end
  if icon.status then
    icon.status:hide()
  end

  if moduleState.showIcon then
    icon:show()
  else
    icon:hide()
  end

  if icon.setTooltip then
    icon:setTooltip("")
  end
end

local function isLeftMouseButton(mouseButton)
  if type(MouseLeftButton) == "number" and mouseButton == MouseLeftButton then
    return true
  end
  if type(mouseButton) == "string" then
    local normalized = mouseButton:lower()
    return normalized == "left" or normalized == "leftbutton" or normalized == "mouseleftbutton"
  end
  return mouseButton == 1
end

local function isRightMouseButton(mouseButton)
  if type(MouseRightButton) == "number" and mouseButton == MouseRightButton then
    return true
  end
  if type(mouseButton) == "string" then
    local normalized = mouseButton:lower()
    return normalized == "right" or normalized == "rightbutton" or normalized == "mouserightbutton"
  end
  return mouseButton == 2
end

local function refreshVisibleCount()
  local visible = 0
  for _, definition in ipairs(moduleDefinitions) do
    local row = state.rows[definition.key]
    if row and row:isVisible() then
      visible = visible + 1
    end
  end
  if mainWindow.header.countLabel then
    mainWindow.header.countLabel:setText(string.format("%d/%d", visible, #moduleDefinitions))
  end
end

local function moduleMatches(definition, query, category)
  if category ~= "Todos" and definition.category ~= category then
    return false
  end
  if query == "" then
    return true
  end

  local moduleState = ensureModuleState(definition)
  local pool = {
    definition.title,
    definition.category,
    moduleDisplayTitle(definition),
    categoryDisplayName(definition.category),
    definition.description,
    moduleDisplayDescription(definition),
    tostring(definition.iconId),
    tostring(moduleState.iconItemId),
    moduleState.iconText
  }
  for _, tag in ipairs(definition.tags or {}) do
    table.insert(pool, tag)
  end
  local haystack = normalizeText(table.concat(pool, " "))
  return haystack:find(query, 1, true) ~= nil
end

local function applyFilters()
  local query = normalizeText(panelStorage.ui.search or "")
  local category = panelStorage.ui.category or "Todos"

  for _, definition in ipairs(moduleDefinitions) do
    local row = state.rows[definition.key]
    if row then
      row:setVisible(moduleMatches(definition, query, category))
    end
  end
  refreshVisibleCount()
end

local function syncStateFromExternal(definition)
  if type(definition.getExternalEnabled) ~= "function" then
    return
  end

  local moduleState = ensureModuleState(definition)
  local isAlwaysSyncedControl = alwaysSyncedControlModules[definition.key] == true
  if moduleState and moduleState.params and moduleState.params.keepSynced == false and not isAlwaysSyncedControl then
    return
  end
  local ok, externalEnabled = pcall(definition.getExternalEnabled, moduleState, definition)
  if not ok or type(externalEnabled) ~= "boolean" then
    return
  end

  if moduleState.enabled == externalEnabled then
    return
  end

  moduleState.enabled = externalEnabled
  syncAddIconState("PIC_" .. definition.key, moduleState.enabled)
  updateRowVisual(definition.key)
  updateIconVisual(definition.key)

  local runner = state.runners[definition.key]
  if runner then
    if moduleState.enabled or definition.tickWhenDisabled == true then
      runner.setOn()
    else
      runner.setOff()
    end
  end
end

local function applyToggle(definition, enabled, silent)
  local moduleState = ensureModuleState(definition)
  moduleState.enabled = enabled == true
  syncAddIconState("PIC_" .. definition.key, moduleState.enabled)

  local runner = state.runners[definition.key]
  if runner then
    if moduleState.enabled or definition.tickWhenDisabled == true then
      runner.setOn()
    else
      runner.setOff()
    end
  end

  updateIconVisual(definition.key)

  local runtimeRef = state.moduleRuntime and state.moduleRuntime[definition.key]
  if type(runtimeRef) ~= "table" then
    runtimeRef = {}
  end

  local callbackState = {}
  for key, value in pairs(moduleState) do
    callbackState[key] = value
  end
  callbackState.runtime = runtimeRef

  safeCall(definition.onToggle, moduleState.enabled, moduleState.params, callbackState, definition)

  if type(callbackState.runtime) == "table" then
    runtimeRef = callbackState.runtime
  end
  if type(callbackState.enabled) == "boolean" then
    moduleState.enabled = callbackState.enabled
  end
  if type(callbackState.params) == "table" then
    moduleState.params = callbackState.params
  end
  if state.moduleRuntime then
    state.moduleRuntime[definition.key] = runtimeRef
  end

  updateRowVisual(definition.key)
  savePainelProfileStorage()

  if not silent then
    showMessage(string.format("[Painel] %s: %s", definition.title, moduleState.enabled and "ON" or "OFF"))
  end
end

local updateToggleAllVisibilityButton

local function setIconVisibility(definition, visible, silent)
  local moduleState = ensureModuleState(definition)
  moduleState.showIcon = visible == true

  if not moduleState.showIcon and moduleState.enabled then
    applyToggle(definition, false, true)
  end

  updateIconVisual(definition.key)
  updateRowVisual(definition.key)
  updateToggleAllVisibilityButton()
  savePainelProfileStorage()

  if not silent then
    showMessage(string.format("[Painel] %s: %s", definition.title, moduleState.showIcon and "SHOW" or "HIDE"))
  end
end

local function areAllIconsHidden()
  for _, definition in ipairs(moduleDefinitions) do
    local moduleState = ensureModuleState(definition)
    if moduleState.showIcon == true then
      return false
    end
  end
  return true
end

updateToggleAllVisibilityButton = function()
  local button = mainWindow and mainWindow.footer and mainWindow.footer.toggleAllVisibilityButton
  if not button then
    return
  end
  local allHidden = areAllIconsHidden()
  button:setText(allHidden and picText("Mostrar todos", "Show all") or picText("Ocultar todos", "Hide all"))
end

local function setAllIconsVisibility(visible)
  for _, definition in ipairs(moduleDefinitions) do
    setIconVisibility(definition, visible, true)
  end
  updateToggleAllVisibilityButton()
  showMessage(string.format("[Painel] Icones: %s", visible and "SHOW ALL" or "HIDE ALL"))
end

local function getNumberFieldWidgetValue(widget)
  if not widget then
    return nil
  end
  if widget.getValue then
    local ok, value = pcall(function() return widget:getValue() end)
    if ok then
      return tonumber(value)
    end
  end
  if widget.getText then
    local ok, text = pcall(function() return widget:getText() end)
    if ok then
      return tonumber(text)
    end
  end
  return nil
end

local function setNumberFieldWidgetValue(widget, value)
  if not widget then
    return
  end
  if widget.setValue then
    pcall(function() widget:setValue(tonumber(value) or 0) end)
    return
  end
  if widget.setText then
    pcall(function() widget:setText(tostring(tonumber(value) or 0)) end)
  end
end

function refreshNickCsvFieldWidget(rowWidget)
  if not rowWidget then
    return
  end

  local csv = sanitizeNicknameCsv(rowWidget.picValue or "")
  rowWidget.picValue = csv
  local count = countNicknameCsvEntries(csv)

  if rowWidget.valueLabel and rowWidget.valueLabel.setText then
    rowWidget.valueLabel:setText(string.format("%d nick(s)", count))
  end

  local tooltipText = csv ~= "" and csv or "Nenhum nick cadastrado"
  if rowWidget.valueLabel and rowWidget.valueLabel.setTooltip then
    rowWidget.valueLabel:setTooltip(tooltipText)
  end
  if rowWidget.editButton and rowWidget.editButton.setTooltip then
    rowWidget.editButton:setTooltip("PT: Abrir janela para editar nicks ignorados (separar por virgula).\nEN: Open editor window for ignored nicknames (comma separated).")
  end
end

function openNickCsvEditor(definition, moduleState, field, rowWidget)
  local parent = rootWidget or (g_ui and g_ui.getRootWidget and g_ui.getRootWidget())
  if not parent then
    return
  end

  local editor = state.nickCsvEditorWindow
  if editor and editor.isDestroyed and editor:isDestroyed() then
    editor = nil
    state.nickCsvEditorWindow = nil
  end

  if not editor then
    editor = setupUI([[
MainWindow
  text: Nicks ignorados
  size: 440 205
  @onEscape: self:hide()

  Panel
    id: contentPanel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: footer.top
    margin-left: 8
    margin-right: 8
    margin-top: 8
    margin-bottom: 6
    background-color: #4e4e4e
    border-width: 1
    border-color: #676d75
    padding-left: 6
    padding-right: 6
    padding-top: 6
    padding-bottom: 6

    Label
      id: hintLabel
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: 16
      text: Separar nicks por virgula: nick1,nick2,nick3
      color: #dbe8f5
      font: verdana-11px-rounded
      text-align: left

    TextEdit
      id: namesEdit
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: hintLabel.bottom
      anchors.bottom: parent.bottom
      margin-top: 6
      font: verdana-11px-rounded

  Panel
    id: footer
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 26
    margin-left: 8
    margin-right: 8
    margin-bottom: 6

    Button
      id: saveButton
      anchors.right: closeButton.left
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 6
      width: 74
      height: 18
      text: Salvar
      font: verdana-11px-rounded

    Button
      id: closeButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: 74
      height: 18
      text: Fechar
      font: verdana-11px-rounded
]], parent)

    if not editor then
      return
    end

    state.nickCsvEditorWindow = editor
    if editor.footer and editor.footer.closeButton then
      editor.footer.closeButton.onClick = function()
        editor:hide()
      end
    end
  end

  local currentCsv = sanitizeNicknameCsv((rowWidget and rowWidget.picValue) or (moduleState and moduleState.params and moduleState.params[field.id]) or "")
  if editor.setText then
    local moduleTitle = definition and definition.title or "Modulo"
    editor:setText(string.format("Nicks ignorados - %s", moduleTitle))
  end
  if editor.contentPanel and editor.contentPanel.namesEdit and editor.contentPanel.namesEdit.setText then
    editor.contentPanel.namesEdit:setText(currentCsv)
  end

  if editor.footer and editor.footer.saveButton then
    editor.footer.saveButton.onClick = function()
      local raw = ""
      if editor.contentPanel and editor.contentPanel.namesEdit and editor.contentPanel.namesEdit.getText then
        raw = editor.contentPanel.namesEdit:getText() or ""
      end

      local sanitized = sanitizeNicknameCsv(raw)
      if rowWidget then
        rowWidget.picValue = sanitized
        refreshNickCsvFieldWidget(rowWidget)
      end
      if moduleState and moduleState.params then
        moduleState.params[field.id] = sanitized
      end
      editor:hide()
    end
  end

  editor:show()
  editor:raise()
  editor:focus()
end

local function saveSetupValues()
  local definition = definitionsByKey[state.currentSetupKey]
  if not definition then
    return
  end

  local moduleState = ensureModuleState(definition)
  for _, fieldRef in ipairs(state.setupFields) do
    local field = fieldRef.field
    local value

    if field.type == "item" then
      value = fieldRef.widget:getItemId()
    elseif field.type == "itemList" then
      local currentItems = nil
      if fieldRef.widget and fieldRef.widget.getItems then
        local ok, items = pcall(function() return fieldRef.widget:getItems() end)
        if ok then
          currentItems = items
        end
      end
      value = currentItems or fieldRef.widget.picItems or moduleState.params[field.id]
    elseif field.type == "nickCsv" then
      value = (fieldRef.widget and fieldRef.widget.picValue) or moduleState.params[field.id]
    elseif field.type == "bool" then
      value = fieldRef.widget:isChecked()
    elseif field.type == "number" then
      value = getNumberFieldWidgetValue(fieldRef.widget)
    elseif field.type == "combo" then
      local currentOption = fieldRef.widget:getCurrentOption()
      value = currentOption and (currentOption.data or currentOption.text) or nil
    else
      value = fieldRef.widget:getText()
    end

    if field.id == "__showIcon" then
      setIconVisibility(definition, value == true, true)
    elseif field.id == "__iconItemId" then
      moduleState.iconItemId = clamp(tonumber(value) or definition.iconId, 100, 50000)
      if fieldRef.widget and fieldRef.widget.setText then
        fieldRef.widget:setText(tostring(moduleState.iconItemId))
      end
      if setupWindow and setupWindow.header and setupWindow.header.metaLabel then
        setupWindow.header.metaLabel:setText(setupMetaText(definition, moduleState.iconItemId))
      end
      updateRowVisual(definition.key)
      updateIconVisual(definition.key)
    elseif field.id == "__iconText" then
      moduleState.iconText = sanitizeIconText(value)
      if fieldRef.widget and fieldRef.widget.setText then
        fieldRef.widget:setText(moduleState.iconText)
      end
      updateRowVisual(definition.key)
      updateIconVisual(definition.key)
    else
      moduleState.params[field.id] = sanitizeFieldValue(field, value)

      if field.type == "number" then
        setNumberFieldWidgetValue(fieldRef.widget, moduleState.params[field.id])
      elseif field.type == "itemList" then
        if fieldRef.widget and fieldRef.widget.setItems then
          fieldRef.widget.picItems = normalizeItemIdArray(moduleState.params[field.id], normalizeItemIdArray(defaultFromField(field), {}))
          fieldRef.widget:setItems(fieldRef.widget.picItems)
        end
      elseif field.type == "nickCsv" then
        if fieldRef.widget then
          fieldRef.widget.picValue = sanitizeNicknameCsv(moduleState.params[field.id])
          refreshNickCsvFieldWidget(fieldRef.widget)
        end
      elseif field.type == "text" then
        fieldRef.widget:setText(moduleState.params[field.id])
      end
    end
  end

  safeCall(definition.onConfigChanged, moduleState.params, moduleState, definition)
  showMessage(string.format("[Painel] setup salvo: %s", definition.title))
end

local function clearSetupRows()
  local children = setupWindow.contentPanel.setupList:getChildren()
  for i = #children, 1, -1 do
    children[i]:destroy()
  end
  state.setupFields = {}
end

local function addSetupField(definition, moduleState, field)
  local value = moduleState.params[field.id]

  if field.type == "bool" then
    local row = g_ui.createWidget("PICSetupCheckRow", setupWindow.contentPanel.setupList)
    row.check:setText(ImperialElfBot.fieldDisplayLabel(field))
    row.check:setChecked(value == true)
    if field.tooltip and row.check and row.check.setTooltip then
      row.check:setTooltip(tostring(field.tooltip))
    end
    table.insert(state.setupFields, {field = field, widget = row.check})
    return
  end

  if field.type == "combo" then
    local row = g_ui.createWidget("PICSetupComboRow", setupWindow.contentPanel.setupList)
    row.label:setText(ImperialElfBot.fieldDisplayLabel(field))
    local selectedText

    for _, option in ipairs(field.options or {}) do
      local optionText = option.text or tostring(option)
      local optionValue = option.value or optionText
      row.combo:addOption(optionText, optionValue)
      if optionValue == value then
        selectedText = optionText
      end
    end

    if selectedText then
      row.combo:setCurrentOption(selectedText, true)
    elseif row.combo:getOptionsCount() > 0 then
      row.combo:setCurrentIndex(1, true)
    end
    if field.tooltip and row.combo and row.combo.setTooltip then
      row.combo:setTooltip(tostring(field.tooltip))
    end

    table.insert(state.setupFields, {field = field, widget = row.combo})
    return
  end

  if field.type == "number" then
    local row = g_ui.createWidget("PICSetupNumberRow", setupWindow.contentPanel.setupList)
    row.label:setText(ImperialElfBot.fieldDisplayLabel(field))
    if row.spin and row.spin.setMinimum then
      row.spin:setMinimum(tonumber(field.min) or 0)
    end
    if row.spin and row.spin.setMaximum then
      row.spin:setMaximum(tonumber(field.max) or 999999)
    end
    if row.spin and row.spin.setStep then
      row.spin:setStep(1)
    end
    setNumberFieldWidgetValue(row.spin, value)
    if field.tooltip and row.spin and row.spin.setTooltip then
      row.spin:setTooltip(tostring(field.tooltip))
    end
    table.insert(state.setupFields, {field = field, widget = row.spin})
    return
  end

  if field.type == "itemList" then
    local holder = setupUI([[
Panel
  height: 76
  layout:
    type: verticalBox
    spacing: 3

  Label
    id: title
    height: 16
    font: verdana-11px-rounded
    color: #e2e8f0
]], setupWindow.contentPanel.setupList)
    holder.title:setText(ImperialElfBot.fieldDisplayLabel(field) ~= "" and ImperialElfBot.fieldDisplayLabel(field) or picText("Itens", "Items"))

    local listContainer
    listContainer = UI.Container(function(_, items)
      local normalized = normalizeItemIdArray(items, {})
      moduleState.params[field.id] = normalized
      if listContainer then
        listContainer.picItems = normalized
      end
    end, true, holder)
    listContainer:setWidth(240)
    listContainer:setHeight(56)
    listContainer.picItems = normalizeItemIdArray(value, normalizeItemIdArray(defaultFromField(field), {}))
    if listContainer.setItems then
      listContainer:setItems(listContainer.picItems)
    end
    if field.tooltip and listContainer.setTooltip then
      listContainer:setTooltip(tostring(field.tooltip))
    elseif listContainer.setTooltip then
      listContainer:setTooltip(picText("Arraste/solte itens para cadastrar IDs.", "Drag/drop items to register IDs."))
    end

    table.insert(state.setupFields, {field = field, widget = listContainer})
    return
  end

  if field.type == "nickCsv" then
    local row = setupUI([[
Panel
  height: 22

  Label
    id: label
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 168
    height: 16
    color: #dbe8f5
    font: verdana-11px-rounded
    text-align: left

  Button
    id: editButton
    anchors.left: label.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 4
    width: 54
    height: 18
    text: Editar
    font: verdana-11px-rounded

  Label
    id: valueLabel
    anchors.left: editButton.right
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 6
    height: 16
    color: #9aa6b2
    font: verdana-11px-rounded
    text-align: left
]], setupWindow.contentPanel.setupList)

    row.label:setText(ImperialElfBot.fieldDisplayLabel(field) ~= "" and ImperialElfBot.fieldDisplayLabel(field) or picText("Nicks ignorados", "Ignored nicknames"))
    row.editButton:setText(picText("Editar", "Edit"))
    row.picValue = sanitizeNicknameCsv(value)
    row.editButton.onClick = function()
      openNickCsvEditor(definition, moduleState, field, row)
    end
    if field.tooltip and row.editButton and row.editButton.setTooltip then
      row.editButton:setTooltip(tostring(field.tooltip))
    end
    refreshNickCsvFieldWidget(row)
    table.insert(state.setupFields, {field = field, widget = row})
    return
  end

  local row = g_ui.createWidget("PICSetupTextRow", setupWindow.contentPanel.setupList)
  row.label:setText(ImperialElfBot.fieldDisplayLabel(field))
  row.edit:setText(tostring(value))
  if field.tooltip and row.edit and row.edit.setTooltip then
    row.edit:setTooltip(tostring(field.tooltip))
  end
  table.insert(state.setupFields, {field = field, widget = row.edit})
end

local function buildFieldGuideLine(field)
  local label = tostring((field and field.label) or "Parametro")
  local fieldType = field and field.type or "text"

  if fieldType == "number" then
    local minText = field.min ~= nil and tostring(field.min) or "livre"
    local maxText = field.max ~= nil and tostring(field.max) or "livre"
    return string.format("- %s: numero (%s..%s).", label, minText, maxText)
  end

  if fieldType == "bool" then
    return string.format("- %s: liga/desliga a opcao.", label)
  end

  if fieldType == "combo" then
    local options = {}
    for i, option in ipairs(field.options or {}) do
      options[#options + 1] = tostring(option.text or option.value or option)
      if i >= 4 then
        break
      end
    end
    if #options > 0 then
      return string.format("- %s: escolha um modo (%s).", label, table.concat(options, ", "))
    end
    return string.format("- %s: escolha um modo.", label)
  end

  if fieldType == "itemList" then
    return string.format("- %s: box de itens (arrastar e soltar).", label)
  end

  if fieldType == "nickCsv" then
    return string.format("- %s: usar botao Editar e separar por virgula.", label)
  end

  return string.format("- %s: texto livre.", label)
end

local function buildFieldGuideLineEn(field)
  local label = tostring(ImperialElfBot.fieldDisplayLabel(field) ~= "" and ImperialElfBot.fieldDisplayLabel(field) or "Parameter")
  local fieldType = field and field.type or "text"

  if fieldType == "number" then
    local minText = field.min ~= nil and tostring(field.min) or "free"
    local maxText = field.max ~= nil and tostring(field.max) or "free"
    return string.format("- %s: numeric value (%s..%s).", label, minText, maxText)
  end

  if fieldType == "bool" then
    return string.format("- %s: toggle this option on/off.", label)
  end

  if fieldType == "combo" then
    local options = {}
    for i, option in ipairs(field.options or {}) do
      options[#options + 1] = tostring(option.text or option.value or option)
      if i >= 4 then
        break
      end
    end
    if #options > 0 then
      return string.format("- %s: choose a mode (%s).", label, table.concat(options, ", "))
    end
    return string.format("- %s: choose one mode.", label)
  end

  if fieldType == "itemList" then
    return string.format("- %s: item box (drag and drop).", label)
  end

  if fieldType == "nickCsv" then
    return string.format("- %s: use Edit button and separate names with commas.", label)
  end

  return string.format("- %s: free text field.", label)
end

local function buildSetupGuideText(definition)
  local ptDescription = tostring((definition and definition.description) or "Executa o macro conforme os parametros configurados.")
  local enDescription = "Configure and run this macro according to the fields below."
  local lines = {
    "Como funciona (PT):",
    ptDescription,
    "",
    "How it works (EN):",
    enDescription,
    "",
    "Mini tutorial (PT):",
    "1) Ajuste Texto do icone e Item ID do icone.",
    "2) Configure os campos abaixo.",
    "3) Clique em Salvar.",
    "4) Clique esquerdo no icone: ON/OFF.",
    "5) Clique direito no icone: abrir setup.",
    "",
    "Mini tutorial (EN):",
    "1) Set Icon Text and Icon Item ID.",
    "2) Configure the fields below.",
    "3) Click Save.",
    "4) Left click on icon: ON/OFF.",
    "5) Right click on icon: open setup."
  }

  local fields = (definition and definition.fields) or {}
  if #fields > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Campos deste macro (PT):"
    for i, field in ipairs(fields) do
      lines[#lines + 1] = buildFieldGuideLine(field)
      if i >= 4 and #fields > 4 then
        lines[#lines + 1] = string.format("- ... e mais %d campo(s) abaixo.", #fields - 4)
        break
      end
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Macro fields (EN):"
    for i, field in ipairs(fields) do
      lines[#lines + 1] = buildFieldGuideLineEn(field)
      if i >= 4 and #fields > 4 then
        lines[#lines + 1] = string.format("- ... and %d more field(s) below.", #fields - 4)
        break
      end
    end
  end

  if definition and definition.key == "guildPotHelper" then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Detalhes Pot Ally (PT):"
    lines[#lines + 1] = "- Escuta trigger no canal configurado e cria fila de pedidos."
    lines[#lines + 1] = "- So entrega para player de Party/Guild, no mesmo andar e ate 1 SQM."
    lines[#lines + 1] = "- Pede automaticamente quando HP<=limite OU Mana<=limite."
    lines[#lines + 1] = "- Delay de pedido evita spam/mute."
    lines[#lines + 1] = "- Necessario potion no container/backpack aberto."
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Pot Ally details (EN):"
    lines[#lines + 1] = "- Listens to trigger on configured channel and queues requests."
    lines[#lines + 1] = "- Supplies only Party/Guild players, same floor, within 1 SQM."
    lines[#lines + 1] = "- Auto-requests when HP<=threshold OR Mana<=threshold."
    lines[#lines + 1] = "- Request delay helps avoid spam/mute."
    lines[#lines + 1] = "- Potion must be in an open backpack/container."
  end

  return table.concat(lines, "\n")
end

local function wrapTextLine(line, maxChars)
  local source = tostring(line or "")
  local limit = math.max(8, tonumber(maxChars) or 36)
  if source == "" then
    return {""}
  end

  local out = {}
  local remaining = source
  while #remaining > limit do
    local cutPos = limit
    for i = limit, 1, -1 do
      if remaining:sub(i, i) == " " then
        cutPos = i - 1
        break
      end
    end

    if cutPos < 1 then
      cutPos = limit
    end

    out[#out + 1] = remaining:sub(1, cutPos)
    remaining = remaining:sub(cutPos + 1):gsub("^%s+", "")
  end

  out[#out + 1] = remaining
  return out
end

local function wrapMultilineText(text, maxChars)
  local lines = {}
  for rawLine in tostring(text or ""):gmatch("([^\n]*)\n?") do
    if rawLine == nil then
      break
    end
    local wrapped = wrapTextLine(rawLine, maxChars)
    for _, entry in ipairs(wrapped) do
      lines[#lines + 1] = entry
    end
  end
  return table.concat(lines, "\n"), #lines
end

local SETUP_INFO_WRAP_CHARS = 30
local SETUP_INFO_LINE_HEIGHT = 14
local SETUP_INFO_BASE_PADDING = 48
local SETUP_INFO_MIN_HEIGHT = 240
local SETUP_INFO_MAX_HEIGHT = 3200

local function addSetupInfoRow(definition)
  local infoRow = g_ui.createWidget("PICSetupInfoRow", setupWindow.contentPanel.setupList)
  if not infoRow or not infoRow.text then
    return
  end

  local rawText = buildSetupGuideText(definition)
  local wrappedText, lineCount = wrapMultilineText(rawText, SETUP_INFO_WRAP_CHARS)
  infoRow.text:setText(wrappedText)

  local dynamicHeight = math.max(1, lineCount) * SETUP_INFO_LINE_HEIGHT + SETUP_INFO_BASE_PADDING
  dynamicHeight = clamp(dynamicHeight, SETUP_INFO_MIN_HEIGHT, SETUP_INFO_MAX_HEIGHT)
  infoRow:setHeight(dynamicHeight)
end

local tutorialWindowRef

local function buildPainelTutorialText()
  local lines = {
    "Painel de Icones - Tutorial (PT)",
    "",
    "1) Clique esquerdo na lista: SHOW/HIDE do icone na tela.",
    "2) Clique direito na lista ou no icone: abre Setup.",
    "3) No Setup, ajuste Item ID, Texto e campos do macro.",
    "4) Clique em Salvar para aplicar.",
    "5) Clique esquerdo no icone da tela: ON/OFF do macro.",
    "",
    "Novo modulo - Pot Ally (PT):",
    "- Trigger padrao: pt.",
    "- Pede pot quando HP<=limite OU Mana<=limite.",
    "- Delay entre pedidos (anti-mute) configuravel.",
    "- Entrega so para Party/Guild ate 1 SQM.",
    "- Potion precisa estar em backpack/container aberto.",
    "",
    "Icon Panel - Tutorial (EN)",
    "",
    "1) Left click on list row: SHOW/HIDE icon on screen.",
    "2) Right click on row or icon: open Setup.",
    "3) In Setup, adjust Item ID, Text and macro fields.",
    "4) Click Save to apply.",
    "5) Left click on screen icon: macro ON/OFF.",
    "",
    "New module - Pot Ally (EN):",
    "- Default trigger: pt.",
    "- Requests pot when HP<=threshold OR Mana<=threshold.",
    "- Request delay (anti-mute) is configurable.",
    "- Supplies only Party/Guild within 1 SQM.",
    "- Potion must be in an open backpack/container."
  }
  return table.concat(lines, "\n")
end

local function buildSwapSetTutorialText()
  local lines = {
    "SwapSet - Tutorial (PT)",
    "",
    "1) Ligue o switch Auto SwapSet.",
    "2) Configure o Raio de Verificacao e salve no perfil.",
    "3) Em cada SET, clique em Clonar equipado ou ajuste os slots manualmente.",
    "4) Marque os filtros desejados (Player, PK, Target, HP, Mana, Enemy, Monstros).",
    "5) Use Add para cadastrar nomes de Enemy/Monstro (opcional).",
    "6) Defina Prioridade do Set para fallback quando nenhum filtro bater.",
    "7) Clique Save no perfil para persistir toda configuracao.",
    "",
    "SwapSet - Tutorial (EN)",
    "",
    "1) Turn on Auto SwapSet switch.",
    "2) Set Verification Radius and save profile.",
    "3) For each SET, click Clone equipped or configure slots manually.",
    "4) Enable desired filters (Player, PK, Target, HP, Mana, Enemy, Monsters).",
    "5) Use Add to register Enemy/Monster names (optional).",
    "6) Set Set Priority as fallback when no filters match.",
    "7) Click profile Save to persist full configuration."
  }
  return table.concat(lines, "\n")
end

local function closeTutorialWindow()
  if not tutorialWindowRef then
    return
  end
  if tutorialWindowRef.hide then
    pcall(function() tutorialWindowRef:hide() end)
  end
  if tutorialWindowRef.destroy then
    pcall(function() tutorialWindowRef:destroy() end)
  end
  tutorialWindowRef = nil
end

local function openTutorialWindow(titleText, contentText)
  local parent = rootWidget or (g_ui and g_ui.getRootWidget and g_ui.getRootWidget())
  if not parent then
    return
  end

  closeTutorialWindow()

  local tutorialWindow = setupUI([[
MainWindow
  text: Tutorial
  size: 520 390
  @onEscape: self:destroy()

  Panel
    id: contentPanel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: footer.top
    margin-left: 8
    margin-right: 8
    margin-top: 8
    margin-bottom: 6
    background-color: #4e4e4e
    border-width: 1
    border-color: #676d75
    padding-left: 4
    padding-right: 4
    padding-top: 4
    padding-bottom: 4

    VerticalScrollBar
      id: contentScroll
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      step: 14
      pixels-scroll: true

    ScrollablePanel
      id: contentList
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: contentScroll.left
      anchors.bottom: parent.bottom
      margin-right: 4
      background-color: #4e4e4e
      border-width: 1
      border-color: #707985
      padding-left: 6
      padding-right: 6
      padding-top: 6
      padding-bottom: 6
      vertical-scrollbar: contentScroll
      layout:
        type: verticalBox
        spacing: 2

      Label
        id: textLabel
        anchors.left: parent.left
        anchors.right: parent.right
        color: #dbe8f5
        text-wrap: false
        text-auto-resize: false
        text-align: left
        font: verdana-11px-rounded

  Panel
    id: footer
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 28
    margin-left: 8
    margin-right: 8
    margin-bottom: 6

    Button
      id: closeButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: 78
      height: 18
      text: Fechar
      font: verdana-11px-rounded
]], parent)

  if not tutorialWindow then
    return
  end
  tutorialWindowRef = tutorialWindow

  if tutorialWindow.setText then
    tutorialWindow:setText(titleText or "Tutorial")
  end

  local wrappedText, lineCount = wrapMultilineText(contentText or "", 64)
  local textLabel = tutorialWindow.contentPanel and tutorialWindow.contentPanel.contentList and tutorialWindow.contentPanel.contentList.textLabel
  if textLabel and textLabel.setText then
    textLabel:setText(wrappedText)
  end
  if textLabel and textLabel.setHeight then
    textLabel:setHeight(math.max(220, (lineCount * 14) + 24))
  end

  if tutorialWindow.footer and tutorialWindow.footer.closeButton then
    tutorialWindow.footer.closeButton.onClick = function()
      closeTutorialWindow()
    end
  end

  tutorialWindow:show()
  tutorialWindow:raise()
  tutorialWindow:focus()
end

local function refreshSetupScrollLayout()
  local content = setupWindow and setupWindow.contentPanel
  local list = content and content.setupList
  local scroll = content and content.setupScroll
  if list and list.updateLayout then
    pcall(function() list:updateLayout() end)
  end
  if scroll and scroll.updateLayout then
    pcall(function() scroll:updateLayout() end)
  end
end

local function resetSetupScrollToTop()
  local content = setupWindow and setupWindow.contentPanel
  local scroll = content and content.setupScroll
  if scroll and scroll.setValue then
    scroll:setValue(0)
  end
end

local function openSetup(definition)
  local moduleState = ensureModuleState(definition)
  state.currentSetupKey = definition.key

  setupWindow.header.titleLabel:setText(moduleDisplayTitle(definition))
  setupWindow.header.metaLabel:setText(setupMetaText(definition, moduleState.iconItemId))
  setupWindow.header.descriptionLabel:setText(moduleDisplayDescription(definition))

  clearSetupRows()

  local showIconRow = g_ui.createWidget("PICSetupCheckRow", setupWindow.contentPanel.setupList)
  showIconRow.check:setText(picText("Mostrar icone na tela", "Show icon on screen"))
  showIconRow.check:setChecked(moduleState.showIcon == true)
  table.insert(state.setupFields, {
    field = {id = "__showIcon", type = "bool"},
    widget = showIconRow.check
  })

  local iconIdentityRow = g_ui.createWidget("PICSetupIconIdentityRow", setupWindow.contentPanel.setupList)
  iconIdentityRow.label:setText(picText("Icone", "Icon"))
  iconIdentityRow.edit:setText(moduleState.iconText or "")
  iconIdentityRow.item:setItemId(moduleState.iconItemId)
  iconIdentityRow.item.onItemChange = function(widget)
    local newId = clamp(tonumber(widget:getItemId()) or definition.iconId, 100, 50000)
    moduleState.iconItemId = newId
    if setupWindow and setupWindow.header and setupWindow.header.metaLabel then
      setupWindow.header.metaLabel:setText(setupMetaText(definition, newId))
    end
    updateRowVisual(definition.key)
    updateIconVisual(definition.key)
  end
  table.insert(state.setupFields, {
    field = {id = "__iconText", type = "text"},
    widget = iconIdentityRow.edit
  })
  table.insert(state.setupFields, {
    field = {id = "__iconItemId", type = "item", min = 100, max = 50000},
    widget = iconIdentityRow.item
  })

  for _, field in ipairs(definition.fields or {}) do
    addSetupField(definition, moduleState, field)
  end

  addSetupInfoRow(definition)
  refreshSetupScrollLayout()

  if addEvent then
    addEvent(function()
      refreshSetupScrollLayout()
      resetSetupScrollToTop()
      if schedule then
        schedule(30, function()
          refreshSetupScrollLayout()
          resetSetupScrollToTop()
        end)
        schedule(120, function()
          refreshSetupScrollLayout()
          resetSetupScrollToTop()
        end)
      end
    end)
  else
    resetSetupScrollToTop()
  end

  setupWindow:show()
  setupWindow:raise()
  setupWindow:focus()
end

local function resetSetupToDefault()
  local definition = definitionsByKey[state.currentSetupKey]
  if not definition then return end
  local moduleState = ensureModuleState(definition)

  moduleState.showIcon = true
  moduleState.iconItemId = definition.iconId
  moduleState.iconText = ""
  for _, field in ipairs(definition.fields or {}) do
    moduleState.params[field.id] = defaultFromField(field)
  end

  setIconVisibility(definition, true, true)
  updateRowVisual(definition.key)
  updateIconVisual(definition.key)

  openSetup(definition)
  showMessage(string.format("[Painel] setup resetado: %s", definition.title))
end

local function createRow(definition)
  local row = g_ui.createWidget("PICModuleRow", mainWindow.modulesList)
  local moduleState = ensureModuleState(definition)
  row.iconItem:setItemId(moduleState.iconItemId)
  if row.iconItem.setSelectable then
    row.iconItem:setSelectable(false)
  end
  if row.iconItem.setEditable then
    row.iconItem:setEditable(false)
  end
  row.nameLabel:setText(moduleDisplayTitle(definition))
  row.categoryLabel:setText(categoryDisplayName(definition.category))
  row.hintLabel:setText("")
  local captionPreview = moduleState.iconText ~= "" and moduleState.iconText or picText("padrao automatico", "automatic default")
  local ptTooltip = string.format("%s\nItem ID atual: %d\nTexto do icone: %s", definition.description, moduleState.iconItemId, captionPreview)
  local enTooltip = string.format("Module: %s\nCurrent item ID: %d\nIcon text: %s", moduleDisplayTitle(definition), moduleState.iconItemId, captionPreview)
  if definition.key == "guildPotHelper" then
    local p = moduleState.params or {}
    local trigger = tostring(p.requestTrigger or "pt")
    local hpThreshold = clamp(tonumber(p.hpRequestBelow) or 50, 0, 100)
    local manaThreshold = clamp(tonumber(p.manaRequestBelow) or 50, 0, 100)
    local requestCooldown = clamp(tonumber(p.requestCooldownMs) or 2000, 1000, 300000)
    local chatMode = tostring(p.chatMode or "default")
    local guildChannel = tostring(p.guildChannel or "")
    local guildSuffix = guildChannel ~= "" and (" | Guild: " .. guildChannel) or ""
    ptTooltip = string.format(
      "%s\nTrigger: %s | HP<=%d%% ou Mana<=%d%% | Delay pedido: %dms\nCanal: %s%s\nEntrega somente para Party/Guild ate 1 SQM.\nRequer potion em backpack/container aberto.\nItem ID atual: %d\nTexto do icone: %s",
      definition.description,
      trigger,
      hpThreshold,
      manaThreshold,
      requestCooldown,
      chatMode,
      guildSuffix,
      moduleState.iconItemId,
      captionPreview
    )
    enTooltip = string.format(
      "%s\nTrigger: %s | HP<=%d%% or Mana<=%d%% | Request delay: %dms\nChannel: %s%s\nSupplies only Party/Guild allies within 1 SQM.\nRequires potion in an open backpack/container.\nCurrent item ID: %d\nIcon text: %s",
      definition.title,
      trigger,
      hpThreshold,
      manaThreshold,
      requestCooldown,
      chatMode,
      guildSuffix,
      moduleState.iconItemId,
      captionPreview
    )
  end
  row:setTooltip(buildBilingualTooltip(ptTooltip, enTooltip))

  local function onRowMousePress(widget, mousePos, mouseButton)
    if isLeftMouseButton(mouseButton) then
      local moduleState = ensureModuleState(definition)
      setIconVisibility(definition, not moduleState.showIcon, false)
      return true
    end
    if isRightMouseButton(mouseButton) then
      return true
    end
    return false
  end

  local function onRowMouseRelease(widget, mousePos, mouseButton)
    if isRightMouseButton(mouseButton) then
      openSetup(definition)
      return true
    end
    return false
  end

  row.onMousePress = onRowMousePress
  row.onMouseRelease = onRowMouseRelease
  row.iconItem.onMousePress = onRowMousePress
  row.iconItem.onMouseRelease = onRowMouseRelease
  row.iconItem.onClick = function()
    return true
  end
  row.nameLabel.onMousePress = onRowMousePress
  row.nameLabel.onMouseRelease = onRowMouseRelease
  row.categoryLabel.onMousePress = onRowMousePress
  row.categoryLabel.onMouseRelease = onRowMouseRelease
  row.hintLabel.onMousePress = onRowMousePress
  row.hintLabel.onMouseRelease = onRowMouseRelease
  row.statusLabel.onMousePress = onRowMousePress
  row.statusLabel.onMouseRelease = onRowMouseRelease

  state.rows[definition.key] = row
  updateRowVisual(definition.key)
end

for _, definition in ipairs(moduleDefinitions) do
  createRow(definition)
end

local function createScreenIcon(definition)
  if not painelProfileLoaded() then
    return
  end
  if type(addIcon) ~= "function" then
    return
  end

  local moduleState = ensureModuleState(definition)
  local iconId = "PIC_" .. definition.key
  syncAddIconState(iconId, moduleState.enabled)

  local iconWidget = addIcon(iconId, {
    item = {id = moduleState.iconItemId, count = 1},
    switchable = false,
    movable = true,
    phantom = true
  }, function()
    local currentState = ensureModuleState(definition)
    applyToggle(definition, not currentState.enabled, true)
  end)
  if not iconWidget then
    return
  end

  configureIconLayout(iconWidget)
  applyIconPositionPercent(iconWidget, iconId, moduleState.iconPosX, moduleState.iconPosY)

  if iconWidget.text then
    iconWidget.text:setText(buildIconCaption(definition, moduleState))
    iconWidget.text:show()
  end
  if iconWidget.status then
    iconWidget.status:hide()
  end
  iconWidget.picStorageId = iconId

  local function syncModulePositionFromWidget(targetWidget)
    local posX, posY = syncIconPositionPercentFromWidget(targetWidget or iconWidget, iconId)
    moduleState.iconPosX = posX
    moduleState.iconPosY = posY
    savePainelProfileStorage()
  end

  iconWidget.onDragEnter = function(widget, mousePos)
    widget:breakAnchors()
    widget.movingReference = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
    return true
  end
  local baseDragLeave = iconWidget.onDragLeave
  iconWidget.onDragLeave = function(widget, pos)
    local consumed = false
    if type(baseDragLeave) == "function" then
      consumed = baseDragLeave(widget, pos) == true
    end
    syncModulePositionFromWidget(widget)
    return consumed
  end
  local function onIconMousePress(widget, mousePos, mouseButton)
    if isRightMouseButton(mouseButton) then
      return true
    end
    return false
  end
  local function onIconMouseRelease(widget, mousePos, mouseButton)
    if isRightMouseButton(mouseButton) then
      openSetup(definition)
      return true
    end
    if isLeftMouseButton(mouseButton) then
      syncModulePositionFromWidget(iconWidget)
    end
    return false
  end
  iconWidget.onMousePress = onIconMousePress
  iconWidget.onMouseRelease = onIconMouseRelease
  if iconWidget.item then
    iconWidget.item.onMousePress = onIconMousePress
    iconWidget.item.onMouseRelease = onIconMouseRelease
  end
  if iconWidget.text then
    iconWidget.text.onMousePress = onIconMousePress
    iconWidget.text.onMouseRelease = onIconMouseRelease
  end
  state.icons[definition.key] = iconWidget
  updateIconVisual(definition.key)
end

for _, definition in ipairs(moduleDefinitions) do
  createScreenIcon(definition)
end

function ImperialElfBot_SaveIconPositions()
  if not painelProfileLoaded() then
    return false
  end
  local changed = false
  for _, definition in ipairs(moduleDefinitions) do
    local iconWidget = state.icons[definition.key]
    if iconWidget then
      local moduleState = ensureModuleState(definition)
      local iconId = "PIC_" .. definition.key
      local posX, posY = syncIconPositionPercentFromWidget(iconWidget, iconId)
      moduleState.iconPosX = posX
      moduleState.iconPosY = posY
      changed = true
    end
  end
  if changed then
    savePainelProfileStorage()
  end
  return changed
end

local function createRunner(definition)
  local moduleState = ensureModuleState(definition)
  local isAlwaysSyncedControl = alwaysSyncedControlModules[definition.key] == true
    and type(definition.getExternalEnabled) == "function"
  local runner
  runner = macro(definition.interval or 200, function()
    if not moduleState.enabled and definition.tickWhenDisabled ~= true then
      return
    end
    -- For synced control modules, external state is authoritative.
    if isAlwaysSyncedControl then
      syncStateFromExternal(definition)
      return
    end
    local runtimeRef = state.moduleRuntime and state.moduleRuntime[definition.key]
    if type(runtimeRef) ~= "table" then
      runtimeRef = {}
    end

    local callbackState = {}
    for key, value in pairs(moduleState) do
      callbackState[key] = value
    end
    callbackState.runtime = runtimeRef

    local ok = safeCall(definition.onTick, callbackState.params, callbackState, definition)

    if type(callbackState.runtime) == "table" then
      runtimeRef = callbackState.runtime
    end
    if type(callbackState.enabled) == "boolean" then
      moduleState.enabled = callbackState.enabled
    end
    if type(callbackState.params) == "table" then
      moduleState.params = callbackState.params
    end
    if state.moduleRuntime then
      state.moduleRuntime[definition.key] = runtimeRef
    end

    if not ok then
      moduleState.enabled = false
      runner.setOff()
      updateRowVisual(definition.key)
      updateIconVisual(definition.key)
    end
  end)
  if painelProfileLoaded() and (moduleState.enabled or definition.tickWhenDisabled == true) then
    runner.setOn()
  else
    runner.setOff()
  end
  if painelProfileLoaded() and moduleState.enabled and not isAlwaysSyncedControl then
    local runtimeRef = state.moduleRuntime and state.moduleRuntime[definition.key]
    if type(runtimeRef) ~= "table" then
      runtimeRef = {}
    end

    local callbackState = {}
    for key, value in pairs(moduleState) do
      callbackState[key] = value
    end
    callbackState.runtime = runtimeRef

    safeCall(definition.onToggle, true, moduleState.params, callbackState, definition)

    if type(callbackState.runtime) == "table" then
      runtimeRef = callbackState.runtime
    end
    if type(callbackState.enabled) == "boolean" then
      moduleState.enabled = callbackState.enabled
    end
    if type(callbackState.params) == "table" then
      moduleState.params = callbackState.params
    end
    if state.moduleRuntime then
      state.moduleRuntime[definition.key] = runtimeRef
    end
  end
  return runner
end

for _, definition in ipairs(moduleDefinitions) do
  state.runners[definition.key] = createRunner(definition)
end

-- Apply saved desired state before external synchronization to avoid boot-time reactivation.
if painelProfileLoaded() then
  for _, definition in ipairs(moduleDefinitions) do
    if alwaysSyncedControlModules[definition.key] == true and type(definition.getExternalEnabled) == "function" then
    local moduleState = ensureModuleState(definition)
    local runtimeRef = state.moduleRuntime and state.moduleRuntime[definition.key]
    if type(runtimeRef) ~= "table" then
      runtimeRef = {}
    end

    local callbackState = {}
    for key, value in pairs(moduleState) do
      callbackState[key] = value
    end
    callbackState.runtime = runtimeRef

    safeCall(definition.onToggle, moduleState.enabled, moduleState.params, callbackState, definition)

    if type(callbackState.runtime) == "table" then
      runtimeRef = callbackState.runtime
    end
    if type(callbackState.enabled) == "boolean" then
      moduleState.enabled = callbackState.enabled
    end
    if type(callbackState.params) == "table" then
      moduleState.params = callbackState.params
    end
    if state.moduleRuntime then
      state.moduleRuntime[definition.key] = runtimeRef
    end
  end
  end
end

local externalSyncDefinitions = {}
for _, definition in ipairs(moduleDefinitions) do
  if type(definition.getExternalEnabled) == "function" then
    table.insert(externalSyncDefinitions, definition)
  end
end

if painelProfileLoaded() then
  for _, definition in ipairs(externalSyncDefinitions) do
    syncStateFromExternal(definition)
  end
end

state.runners.__externalSync = macro(500, function()
  if not painelProfileLoaded() then
    return
  end
  for _, definition in ipairs(externalSyncDefinitions) do
    syncStateFromExternal(definition)
  end
end)

local function setLanguageButtonState(button, active)
  if not button then
    return
  end
  if button.setColor then
    button:setColor(active and "#22c55e" or "#dbe8f5")
  end
end

local function refreshLanguageButtons()
  local header = mainWindow and mainWindow.header
  if not header then
    return
  end
  local language = getElfLanguage()
  setLanguageButtonState(header.ptButton, language == "pt")
  setLanguageButtonState(header.enButton, language == "en")
  if header.ptButton and header.ptButton.setTooltip then
    header.ptButton:setTooltip(picText("Mostrar interface em portugues.", "Show interface in Portuguese."))
  end
  if header.enButton and header.enButton.setTooltip then
    header.enButton:setTooltip(picText("Mostrar interface em ingles.", "Show interface in English."))
  end
end

local function rebuildCategoryCombo()
  local combo = mainWindow and mainWindow.header and mainWindow.header.categoryCombo
  if not combo then
    return
  end

  combo:clearOptions()
  for _, categoryName in ipairs(categoryList) do
    combo:addOption(categoryDisplayName(categoryName), categoryName)
  end

  if not isKnownCategory(panelStorage.ui.category) then
    panelStorage.ui.category = "Todos"
  end
  combo:setCurrentOption(categoryDisplayName(panelStorage.ui.category), true)
end

local function refreshPainelLanguage()
  if mainWindow and mainWindow.setText then
    mainWindow:setText(picText("Painel de Icones", "Icon Panel"))
  end

  local header = mainWindow and mainWindow.header
  if header then
    if header.searchLabel then header.searchLabel:setText(picText("Busca:", "Search:")) end
    if header.categoryLabel then header.categoryLabel:setText(picText("Categoria:", "Category:")) end
  end

  local footer = mainWindow and mainWindow.footer
  if footer then
    if footer.clearFilterButton then footer.clearFilterButton:setText(picText("Limpar filtros", "Clear filters")) end
    if footer.helpButton then footer.helpButton:setText(picText("Ajuda", "Help")) end
    if footer.closeButton then footer.closeButton:setText(picText("Fechar", "Close")) end
    if footer.hintLabel then footer.hintLabel:setText(picText("E: show | D: setup", "L: show | R: setup")) end
  end

  if setupWindow and setupWindow.setText then
    setupWindow:setText(picText("Setup de Icone", "Icon Setup"))
  end
  if setupWindow and setupWindow.footer then
    if setupWindow.footer.resetButton then setupWindow.footer.resetButton:setText(picText("Resetar", "Reset")) end
    if setupWindow.footer.saveButton then setupWindow.footer.saveButton:setText(picText("Salvar", "Save")) end
    if setupWindow.footer.closeButton then setupWindow.footer.closeButton:setText(picText("Fechar", "Close")) end
  end

  for _, definition in ipairs(moduleDefinitions) do
    local row = state.rows[definition.key]
    if row then
      row.nameLabel:setText(moduleDisplayTitle(definition))
      row.categoryLabel:setText(categoryDisplayName(definition.category))
      updateRowVisual(definition.key)
    end
  end

  local currentDefinition = definitionsByKey[state.currentSetupKey]
  if currentDefinition and setupWindow and setupWindow.header then
    local moduleState = ensureModuleState(currentDefinition)
    setupWindow.header.titleLabel:setText(moduleDisplayTitle(currentDefinition))
    setupWindow.header.metaLabel:setText(setupMetaText(currentDefinition, moduleState.iconItemId))
    setupWindow.header.descriptionLabel:setText(moduleDisplayDescription(currentDefinition))
    if setupWindow.isVisible and setupWindow:isVisible() then
      openSetup(currentDefinition)
    end
  end

  rebuildCategoryCombo()
  refreshLanguageButtons()
  updateToggleAllVisibilityButton()
  applyFilters()

  if state.openButton and state.openButton.setText then
    state.openButton:setText(picText("Painel de Icones", "Icon Panel"))
  end

  return getElfLanguage()
end

mainWindow.header.searchEdit:setText(panelStorage.ui.search or "")
mainWindow.header.searchEdit.onTextChange = function(widget, text)
  panelStorage.ui.search = text or ""
  applyFilters()
end

rebuildCategoryCombo()
mainWindow.header.categoryCombo.onOptionChange = function(widget, text)
  local option = widget.getCurrentOption and widget:getCurrentOption() or nil
  panelStorage.ui.category = (option and option.data) or categoryFromDisplay(text)
  if not isKnownCategory(panelStorage.ui.category) then
    panelStorage.ui.category = "Todos"
  end
  applyFilters()
end

mainWindow.footer.clearFilterButton.onClick = function()
  panelStorage.ui.search = ""
  panelStorage.ui.category = "Todos"
  mainWindow.header.searchEdit:setText("")
  mainWindow.header.categoryCombo:setCurrentOption(categoryDisplayName("Todos"), true)
  applyFilters()
end

if mainWindow.header.ptButton then
  mainWindow.header.ptButton.onClick = function()
    ImperialElfBot_SetLanguage("pt")
  end
end

if mainWindow.header.enButton then
  mainWindow.header.enButton.onClick = function()
    ImperialElfBot_SetLanguage("en")
  end
end

mainWindow.footer.toggleAllVisibilityButton.onClick = function()
  local shouldShowAll = areAllIconsHidden()
  setAllIconsVisibility(shouldShowAll)
end

if mainWindow.footer.helpButton then
  if mainWindow.footer.helpButton.setTooltip then
    mainWindow.footer.helpButton:setTooltip(picText("Abre tutorial rapido do Painel de Icones.", "Open quick Icon Panel tutorial."))
  end
  mainWindow.footer.helpButton.onClick = function()
    openTutorialWindow(picText("Tutorial - Painel de Icones", "Tutorial - Icon Panel"), buildPainelTutorialText())
  end
end

mainWindow.footer.closeButton.onClick = function()
  mainWindow:hide()
end

setupWindow.footer.saveButton.onClick = function()
  saveSetupValues()
end

setupWindow.footer.resetButton.onClick = function()
  resetSetupToDefault()
end

setupWindow.footer.closeButton.onClick = function()
  if state.nickCsvEditorWindow and state.nickCsvEditorWindow.hide then
    state.nickCsvEditorWindow:hide()
  end
  setupWindow:hide()
end

local openButton = UI.Button("Painel de Icones", function()
  mainWindow:show()
  mainWindow:raise()
  mainWindow:focus()
end)
state.openButton = openButton
if openButton then
  if openButton.setFont then
    openButton:setFont("verdana-11px-rounded")
  end
end

updateToggleAllVisibilityButton()

refreshPainelLanguage()

PainelDeIconesController = {
  state = state,
  openButton = openButton,
  mainWindow = mainWindow,
  setupWindow = setupWindow,
  open = function()
    if mainWindow then
      mainWindow:show()
      mainWindow:raise()
      mainWindow:focus()
    end
  end,
  show = function()
    if mainWindow then
      mainWindow:show()
      mainWindow:raise()
      mainWindow:focus()
    end
  end,
  refreshLanguage = refreshPainelLanguage,
  setLanguage = function(language)
    return ImperialElfBot_SetLanguage(language)
  end,
  getLanguage = function()
    return getElfLanguage()
  end,
  shutdown = function()
    closeTutorialWindow()
    for _, runner in pairs(state.runners or {}) do
      if runner and runner.setOff then
        runner.setOff()
      end
    end

    for _, iconWidget in pairs(state.icons or {}) do
      if iconWidget and iconWidget.destroy then
        iconWidget:destroy()
      end
    end

    if state.setupWindow then
      state.setupWindow:destroy()
    end
    if state.nickCsvEditorWindow then
      state.nickCsvEditorWindow:destroy()
    end
    if state.mainWindow then
      state.mainWindow:destroy()
    end

    if openButton then
      openButton:destroy()
    end
  end
}


-- Bridge para o layout estilo ElfBot abrir diretamente o Painel de Icones.
ImperialElfBot_OpenIcons = function()
  if PainelDeIconesController and PainelDeIconesController.open then
    PainelDeIconesController.open()
  elseif mainWindow then
    mainWindow:show()
    mainWindow:raise()
    mainWindow:focus()
  end
end

-- =================================================================
-- SWAPSET (integrado ao Painel de Icones)
-- =================================================================
if SwapSetController and SwapSetController.shutdown then
  SwapSetController.shutdown()
end

if type(storage.swapSetConfig) ~= "table" then
  if type(storage.SwapSetMana) == "table" then
    storage.swapSetConfig = deepcopy(storage.SwapSetMana)
  else
    storage.swapSetConfig = {}
  end
end

local swapSettings = storage.swapSetConfig
storage.SwapSetMana = swapSettings

local swapParts = {
  { id = "head", label = "Head", slot = SlotHead },
  { id = "body", label = "Body", slot = SlotBody },
  { id = "legs", label = "Legs", slot = SlotLeg },
  { id = "feet", label = "Feet", slot = SlotFeet },
  { id = "left-hand", label = "Left Hand", slot = SlotLeft },
  { id = "right-hand", label = "Right Hand", slot = SlotRight },
  { id = "ammo", label = "Ammo", slot = SlotAmmo }
}

local swapSetupWindow
local swapMainUi
local swapEnableSwitch
local swapProfileRow
local swapConfigRow
local swapPriorityButton
local swapSetPanels = {}
local swapEqRows = { SET1 = {}, SET2 = {} }
local swapLastEquippedSet = nil
local swapAutoMacro
local swapBridgeSyncMacro
local swapNamesWindow
local swapNamesEditorWindow
local swapNamesListContext = { setKey = nil, listKey = nil, title = "" }

local function normalizeSwapNameValue(value)
  local text = tostring(value or "")
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  text = text:gsub("%s+", " ")
  return text
end

local function normalizeSwapNameKey(value)
  return normalizeText(normalizeSwapNameValue(value))
end

local function normalizeSwapNameList(value)
  local source = type(value) == "table" and value or {}
  local normalized = {}
  local seen = {}
  for _, entry in ipairs(source) do
    local cleaned = normalizeSwapNameValue(entry)
    local key = normalizeSwapNameKey(cleaned)
    if cleaned ~= "" and key ~= "" and not seen[key] then
      seen[key] = true
      table.insert(normalized, cleaned)
    end
  end
  table.sort(normalized, function(a, b)
    return normalizeSwapNameKey(a) < normalizeSwapNameKey(b)
  end)
  return normalized
end

local function buildSwapNameLookup(list)
  local lookup = {}
  for _, entry in ipairs(type(list) == "table" and list or {}) do
    local key = normalizeSwapNameKey(entry)
    if key ~= "" then
      lookup[key] = true
    end
  end
  return lookup
end

local function findSwapWidgetByIdRecursive(root, childId)
  if not root or not childId then
    return nil
  end

  local direct = root.getChildById and root:getChildById(childId) or nil
  if direct then
    return direct
  end

  local children = root.getChildren and root:getChildren() or nil
  if not children then
    return nil
  end

  for _, child in ipairs(children) do
    local found = findSwapWidgetByIdRecursive(child, childId)
    if found then
      return found
    end
  end

  return nil
end

local function getSwapScenarioWidget(panel, childId)
  if not panel or not childId then
    return nil
  end

  local scenarioPanel = panel.scenarioPanel or findSwapWidgetByIdRecursive(panel, "scenarioPanel") or panel
  local widget = findSwapWidgetByIdRecursive(scenarioPanel, childId)
  if widget then
    return widget
  end
  return findSwapWidgetByIdRecursive(panel, childId)
end

local function swapMessage(message, color)
  local text = tostring(message or "")
  if text == "" then
    return
  end

  if modules and modules.game_textmessage and modules.game_textmessage.displayBroadcastMessage then
    modules.game_textmessage.displayBroadcastMessage(text, color or "#9dd1ff")
    return
  end
  if modules and modules.game_textmessage and modules.game_textmessage.displayGameMessage then
    modules.game_textmessage.displayGameMessage(text)
    return
  end
  print(text)
end

local function normalizeSwapSetConfig()
  for key, _ in pairs(swapSettings) do
    if type(key) ~= "string" then
      swapSettings[key] = nil
    end
  end

  swapSettings.autoSwapEnabled = normalizeBoolFlag(swapSettings.autoSwapEnabled, false)
  swapSettings.safeRange = clamp(math.floor(tonumber(swapSettings.safeRange) or 8), 1, 15)
  swapSettings.prioritySet = tostring(swapSettings.prioritySet or swapSettings.pzPrioritySet or "SET1")
  if swapSettings.prioritySet ~= "SET2" then
    swapSettings.prioritySet = "SET1"
  end
  swapSettings.pzPrioritySet = nil

  swapSettings.SET1 = type(swapSettings.SET1) == "table" and swapSettings.SET1 or {}
  swapSettings.SET2 = type(swapSettings.SET2) == "table" and swapSettings.SET2 or {}
  swapSettings.scenarios = type(swapSettings.scenarios) == "table" and swapSettings.scenarios or {}

  local scenarioDefaults = {
    SET1 = {
      safeNoPlayers = false,
      playersRangeEnabled = true,
      playersMin = 0,
      playersMax = 200,
      hasPk = false,
      pkRangeEnabled = false,
      pkMin = 1,
      pkMax = 200,
      targetEnabled = false,
      targetHpEnabled = false,
      targetHpBelow = 40,
      hasEnemy = false,
      enemyNames = {},
      hpEnabled = false,
      hpBelow = 40,
      manaEnabled = false,
      manaBelow = 40,
      hasMonster = false,
      monsterMin = 1,
      monsterMax = 200,
      monsterNames = {}
    },
    SET2 = {
      safeNoPlayers = false,
      playersRangeEnabled = true,
      playersMin = 1,
      playersMax = 200,
      hasPk = false,
      pkRangeEnabled = false,
      pkMin = 1,
      pkMax = 200,
      targetEnabled = false,
      targetHpEnabled = false,
      targetHpBelow = 40,
      hasEnemy = false,
      enemyNames = {},
      hpEnabled = false,
      hpBelow = 40,
      manaEnabled = false,
      manaBelow = 40,
      hasMonster = false,
      monsterMin = 1,
      monsterMax = 200,
      monsterNames = {}
    }
  }

  for setKey, defaults in pairs(scenarioDefaults) do
    local scenarioData = swapSettings.scenarios[setKey]
    if type(scenarioData) ~= "table" then
      scenarioData = {}
      swapSettings.scenarios[setKey] = scenarioData
    end
    for key, _ in pairs(scenarioData) do
      if type(key) ~= "string" then
        scenarioData[key] = nil
      end
    end

    local hasAnyNewField = (
      scenarioData.safeNoPlayers ~= nil or
      scenarioData.playersRangeEnabled ~= nil or
      scenarioData.hasPk ~= nil or
      scenarioData.pkRangeEnabled ~= nil or
      scenarioData.targetEnabled ~= nil or
      scenarioData.targetHpEnabled ~= nil or
      scenarioData.hasEnemy ~= nil or
      scenarioData.enemyNames ~= nil or
      scenarioData.hpEnabled ~= nil or
      scenarioData.manaEnabled ~= nil or
      scenarioData.hasMonster ~= nil or
      -- legado
      scenarioData.monsterRangeEnabled ~= nil or
      scenarioData.monsterNames ~= nil
    )

    if not hasAnyNewField and scenarioData.mode ~= nil then
      local legacyMode = tostring(scenarioData.mode)
      local legacyMin = clamp(math.floor(tonumber(scenarioData.minPlayers) or defaults.playersMin), 0, 200)
      local legacyMax = clamp(math.floor(tonumber(scenarioData.maxPlayers) or defaults.playersMax), 0, 200)
      if legacyMax < legacyMin then
        legacyMax = legacyMin
      end

      if legacyMode == "without_players" then
        scenarioData.safeNoPlayers = true
      elseif legacyMode == "with_players" then
        scenarioData.playersRangeEnabled = true
        scenarioData.playersMin = 1
        scenarioData.playersMax = 200
      elseif legacyMode == "players_between" or legacyMode == "between_players" or legacyMode == "min_players" or legacyMode == "max_players" then
        scenarioData.playersRangeEnabled = true
        scenarioData.playersMin = legacyMin
        scenarioData.playersMax = legacyMax
      elseif legacyMode == "with_pk" then
        scenarioData.hasPk = true
      elseif legacyMode == "pk_between" then
        scenarioData.pkRangeEnabled = true
        scenarioData.pkMin = legacyMin
        scenarioData.pkMax = legacyMax
      elseif legacyMode == "with_enemy" then
        scenarioData.hasEnemy = true
      elseif legacyMode == "hp_below" then
        scenarioData.hpEnabled = true
        scenarioData.hpBelow = clamp(legacyMin, 0, 100)
      elseif legacyMode == "mana_below" then
        scenarioData.manaEnabled = true
        scenarioData.manaBelow = clamp(legacyMin, 0, 100)
      elseif legacyMode == "with_monster" then
        scenarioData.hasMonster = true
      elseif legacyMode == "monsters_between" then
        scenarioData.hasMonster = true
        scenarioData.monsterMin = legacyMin
        scenarioData.monsterMax = legacyMax
      end
    end

    -- Compatibilidade com versoes antigas:
    -- safeNoPlayers => Player na Tela com quantidade 0.
    if normalizeBoolFlag(scenarioData.safeNoPlayers, false) then
      scenarioData.playersRangeEnabled = true
      scenarioData.playersMin = 0
    end
    -- hasPk => PK na Tela com quantidade minima 1.
    if normalizeBoolFlag(scenarioData.hasPk, false) and scenarioData.pkRangeEnabled ~= true then
      scenarioData.pkRangeEnabled = true
      scenarioData.pkMin = math.max(1, tonumber(scenarioData.pkMin) or 1)
    end

    scenarioData.playersRangeEnabled = normalizeBoolFlag(scenarioData.playersRangeEnabled, defaults.playersRangeEnabled)
    scenarioData.playersMin = clamp(math.floor(tonumber(scenarioData.playersMin) or defaults.playersMin), 0, 200)
    scenarioData.playersMax = clamp(math.floor(tonumber(scenarioData.playersMax) or defaults.playersMax), 0, 200)
    if scenarioData.playersMax < scenarioData.playersMin then
      scenarioData.playersMax = scenarioData.playersMin
    end

    scenarioData.pkRangeEnabled = normalizeBoolFlag(scenarioData.pkRangeEnabled, defaults.pkRangeEnabled)
    scenarioData.pkMin = clamp(math.floor(tonumber(scenarioData.pkMin) or defaults.pkMin), 0, 200)
    scenarioData.pkMax = clamp(math.floor(tonumber(scenarioData.pkMax) or defaults.pkMax), 0, 200)
    if scenarioData.pkMax < scenarioData.pkMin then
      scenarioData.pkMax = scenarioData.pkMin
    end

    scenarioData.targetEnabled = normalizeBoolFlag(scenarioData.targetEnabled, defaults.targetEnabled)
    scenarioData.targetHpEnabled = normalizeBoolFlag(scenarioData.targetHpEnabled, defaults.targetHpEnabled)
    scenarioData.targetHpBelow = clamp(math.floor(tonumber(scenarioData.targetHpBelow) or defaults.targetHpBelow), 0, 100)

    scenarioData.hasEnemy = normalizeBoolFlag(scenarioData.hasEnemy, defaults.hasEnemy)
    scenarioData.enemyNames = normalizeSwapNameList(scenarioData.enemyNames or defaults.enemyNames)

    scenarioData.hpEnabled = normalizeBoolFlag(scenarioData.hpEnabled, defaults.hpEnabled)
    scenarioData.hpBelow = clamp(math.floor(tonumber(scenarioData.hpBelow) or defaults.hpBelow), 0, 100)

    scenarioData.manaEnabled = normalizeBoolFlag(scenarioData.manaEnabled, defaults.manaEnabled)
    scenarioData.manaBelow = clamp(math.floor(tonumber(scenarioData.manaBelow) or defaults.manaBelow), 0, 100)

    -- Compatibilidade com versoes antigas: monsterRangeEnabled => hasMonster.
    if normalizeBoolFlag(scenarioData.monsterRangeEnabled, false) then
      scenarioData.hasMonster = true
    end
    scenarioData.hasMonster = normalizeBoolFlag(scenarioData.hasMonster, defaults.hasMonster)
    scenarioData.monsterMin = clamp(math.floor(tonumber(scenarioData.monsterMin) or defaults.monsterMin), 1, 200)
    scenarioData.monsterMax = clamp(math.floor(tonumber(scenarioData.monsterMax) or defaults.monsterMax), 0, 200)
    scenarioData.monsterNames = normalizeSwapNameList(scenarioData.monsterNames or defaults.monsterNames)
    if scenarioData.monsterMax < scenarioData.monsterMin then
      scenarioData.monsterMax = scenarioData.monsterMin
    end

    scenarioData.mode = nil
    scenarioData.minPlayers = nil
    scenarioData.maxPlayers = nil
    scenarioData.safeNoPlayers = nil
    scenarioData.hasPk = nil
    scenarioData.noAllies = nil
    scenarioData.monsterRangeEnabled = nil
  end

  for _, part in ipairs(swapParts) do
    local set1Id = clamp(tonumber(swapSettings.SET1[part.id]) or 0, 0, 50000)
    if set1Id < 100 then
      set1Id = 0
    end
    swapSettings.SET1[part.id] = set1Id

    local set2Id = clamp(tonumber(swapSettings.SET2[part.id]) or 0, 0, 50000)
    if set2Id < 100 then
      set2Id = 0
    end
    swapSettings.SET2[part.id] = set2Id
  end

  swapSettings.SET1.neck = nil
  swapSettings.SET1.finger = nil
  swapSettings.SET2.neck = nil
  swapSettings.SET2.finger = nil

  for key, _ in pairs(swapSettings.SET1) do
    if type(key) ~= "string" then
      swapSettings.SET1[key] = nil
    end
  end
  for key, _ in pairs(swapSettings.SET2) do
    if type(key) ~= "string" then
      swapSettings.SET2[key] = nil
    end
  end
end

local function captureSwapProfileState()
  return deepcopy({
    autoSwapEnabled = swapSettings.autoSwapEnabled == true,
    safeRange = swapSettings.safeRange,
    prioritySet = swapSettings.prioritySet,
    scenarios = deepcopy(swapSettings.scenarios),
    SET1 = deepcopy(swapSettings.SET1),
    SET2 = deepcopy(swapSettings.SET2)
  })
end

swapProfileDebugState = swapProfileDebugState or {
  bootLogged = false,
  lastSanitizedProfile = nil
}

--[[
PROFILE PERSISTENCE STANDARD (2026-03)
- Canonical state: storage.swapSetProfiles.meta.activeProfile
- Profile model: configs[id] + order + nextId + meta
- Fallback rule: first valid profile id from order/configs
- "Config 1" is created only when profiles are empty
- Legacy list/data/selectedId is migrated and then cleared
- Runtime switch flow: save previous -> set activeProfile -> apply selected
- Temporary audit logs:
  BOOT Active profile loaded
  SANITIZE Active profile after sanitize
  APPLY Applying profile
]]
function trimSwapProfileText(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function isSwapProfileIdValid(profiles, profileId)
  local id = trimSwapProfileText(profileId)
  if id == "" then
    return false
  end
  return type(profiles.configs[id]) == "table"
end

function getFirstSwapProfileId(profiles)
  for _, id in ipairs(profiles.order or {}) do
    if type(profiles.configs[id]) == "table" then
      return id
    end
  end
  return ""
end

function setSwapActiveProfile(profiles, profileId)
  local id = trimSwapProfileText(profileId)
  if not isSwapProfileIdValid(profiles, id) then
    id = getFirstSwapProfileId(profiles)
  end
  profiles.meta.activeProfile = id
  return id
end

function ensureSwapProfiles()
  if type(storage.swapSetProfiles) ~= "table" then
    storage.swapSetProfiles = {}
  end

  local profiles = storage.swapSetProfiles
  local legacyList = type(profiles.list) == "table" and profiles.list or {}
  local legacyData = type(profiles.data) == "table" and profiles.data or {}
  local legacySelectedId = trimSwapProfileText(profiles.selectedId)
  local existingConfigs = type(profiles.configs) == "table" and profiles.configs or {}
  local existingOrder = type(profiles.order) == "table" and profiles.order or {}

  local normalizedConfigs = {}
  local normalizedOrder = {}
  local seenIds = {}

  local function addProfileEntry(rawId, rawName, rawData)
    local id = trimSwapProfileText(rawId)
    if id == "" or seenIds[id] then
      return
    end
    seenIds[id] = true
    local name = trimSwapProfileText(rawName)
    if name == "" then
      name = id
    end

    local dataTable = nil
    if type(rawData) == "table" then
      dataTable = rawData
    elseif type(existingConfigs[id]) == "table" and type(existingConfigs[id].data) == "table" then
      dataTable = existingConfigs[id].data
    elseif type(legacyData[id]) == "table" then
      dataTable = legacyData[id]
    end
    if type(dataTable) ~= "table" then
      dataTable = {}
    end

    normalizedConfigs[id] = {
      name = name,
      data = dataTable
    }
    table.insert(normalizedOrder, id)
  end

  for _, rawId in ipairs(existingOrder) do
    local id = trimSwapProfileText(rawId)
    local entry = type(existingConfigs[id]) == "table" and existingConfigs[id] or nil
    addProfileEntry(id, entry and entry.name or id, entry and entry.data or nil)
  end

  for _, entry in ipairs(legacyList) do
    local id = trimSwapProfileText(entry and entry.id)
    addProfileEntry(id, entry and entry.name or id, legacyData[id])
  end

  for rawId, entry in pairs(existingConfigs) do
    if type(rawId) == "string" and type(entry) == "table" then
      addProfileEntry(rawId, entry.name or rawId, entry.data)
    end
  end

  for rawId, dataValue in pairs(legacyData) do
    if type(rawId) == "string" and type(dataValue) == "table" then
      addProfileEntry(rawId, rawId, dataValue)
    end
  end

  profiles.configs = normalizedConfigs
  profiles.order = normalizedOrder
  profiles.list = nil
  profiles.data = nil
  profiles.selectedId = nil
  profiles.nextId = tonumber(profiles.nextId) or 1
  if profiles.nextId < 1 then
    profiles.nextId = 1
  end
  profiles.meta = type(profiles.meta) == "table" and profiles.meta or {}
  profiles.meta.activeProfile = trimSwapProfileText(profiles.meta.activeProfile)

  if #profiles.order == 0 then
    local defaultId = "cfg_1"
    profiles.configs[defaultId] = profiles.configs[defaultId] or {
      name = "Config 1",
      data = captureSwapProfileState()
    }
    table.insert(profiles.order, defaultId)
    if profiles.nextId < 2 then
      profiles.nextId = 2
    end
  end

  local maxProfileNumber = 0
  for _, id in ipairs(profiles.order) do
    local num = tonumber(tostring(id):match("^cfg_(%d+)$"))
    if num and num > maxProfileNumber then
      maxProfileNumber = num
    end
  end
  if profiles.nextId <= maxProfileNumber then
    profiles.nextId = maxProfileNumber + 1
  end

  if trimSwapProfileText(profiles.meta.activeProfile) == "" then
    profiles.meta.activeProfile = legacySelectedId
  end

  local activeId = setSwapActiveProfile(profiles, profiles.meta.activeProfile)
  if activeId ~= "" and type(profiles.configs[activeId].data) ~= "table" then
    profiles.configs[activeId].data = captureSwapProfileState()
  end

  if not swapProfileDebugState.bootLogged then
    if painelProfileLoaded() then
      print("BOOT Active profile loaded: " .. activeId)
    end
    swapProfileDebugState.bootLogged = true
  end
  if swapProfileDebugState.lastSanitizedProfile ~= activeId then
    if painelProfileLoaded() then
      print("SANITIZE Active profile after sanitize: " .. activeId)
    end
    swapProfileDebugState.lastSanitizedProfile = activeId
  end

  return profiles
end

function getSelectedSwapProfileId()
  local profiles = ensureSwapProfiles()
  return setSwapActiveProfile(profiles, profiles.meta.activeProfile)
end

function getSwapProfileName(profileId)
  if not profileId or profileId == "" then
    return "Sem perfil"
  end
  local profiles = ensureSwapProfiles()
  for _, id in ipairs(profiles.order) do
    if id == profileId then
      local entry = profiles.configs[id]
      if type(entry) == "table" then
        return entry.name or id
      end
      return id
    end
  end
  return profileId
end

function saveSwapProfileState(profileId)
  if not profileId or profileId == "" then
    return
  end
  local profiles = ensureSwapProfiles()
  local id = setSwapActiveProfile(profiles, profileId)
  if id == "" or type(profiles.configs[id]) ~= "table" then
    return
  end
  profiles.configs[id].data = captureSwapProfileState()
end

function applySwapProfileState(profileId)
  if not profileId or profileId == "" then
    return
  end

  local profiles = ensureSwapProfiles()
  local id = setSwapActiveProfile(profiles, profileId)
  if id == "" then
    return
  end
  if painelProfileLoaded() then
    print("APPLY Applying profile: " .. id)
  end
  local cfg = profiles.configs[id]
  local data = type(cfg) == "table" and cfg.data or nil
  if type(data) ~= "table" then
    if type(cfg) == "table" then
      cfg.data = captureSwapProfileState()
    end
    return
  end

  swapSettings.autoSwapEnabled = normalizeBoolFlag(data.autoSwapEnabled, false)
  swapSettings.safeRange = clamp(math.floor(tonumber(data.safeRange) or 8), 1, 15)
  swapSettings.prioritySet = tostring(data.prioritySet or data.pzPrioritySet or "SET1")
  if swapSettings.prioritySet ~= "SET2" then
    swapSettings.prioritySet = "SET1"
  end
  swapSettings.pzPrioritySet = nil
  swapSettings.scenarios = deepcopy(type(data.scenarios) == "table" and data.scenarios or {})
  swapSettings.SET1 = deepcopy(type(data.SET1) == "table" and data.SET1 or {})
  swapSettings.SET2 = deepcopy(type(data.SET2) == "table" and data.SET2 or {})
  normalizeSwapSetConfig()
  swapLastEquippedSet = nil
end

function addSwapProfile(name)
  local cleaned = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if cleaned == "" then
    return nil
  end

  local profiles = ensureSwapProfiles()
  local id = "cfg_" .. tostring(profiles.nextId)
  profiles.nextId = profiles.nextId + 1
  profiles.configs[id] = { name = cleaned, data = captureSwapProfileState() }
  table.insert(profiles.order, id)
  setSwapActiveProfile(profiles, id)
  return id
end

local function getInventoryItemSafe(slot)
  if type(getInventoryItem) == "function" then
    return getInventoryItem(slot)
  end
  local player = g_game and g_game.getLocalPlayer and g_game.getLocalPlayer()
  if player and player.getInventoryItem then
    return player:getInventoryItem(slot)
  end
  return nil
end

local function copyCurrentEquipmentToSet(setKey)
  local targetSet = swapSettings[setKey]
  if type(targetSet) ~= "table" then
    swapSettings[setKey] = {}
    targetSet = swapSettings[setKey]
  end

  for _, part in ipairs(swapParts) do
    local item = getInventoryItemSafe(part.slot)
    local itemId = item and item:getId() or 0
    if itemId < 100 then
      itemId = 0
    end
    targetSet[part.id] = clamp(itemId, 0, 50000)
  end
  swapLastEquippedSet = nil
end

local function refreshEqRows(setKey)
  local rows = swapEqRows[setKey]
  local data = swapSettings[setKey]
  if type(rows) ~= "table" or type(data) ~= "table" then
    return
  end

  for _, part in ipairs(swapParts) do
    local slotWidget = rows[part.id]
    if slotWidget then
      local itemId = clamp(tonumber(data[part.id]) or 0, 0, 50000)
      if itemId < 100 then
        itemId = 0
      end
      if slotWidget.setItemId then
        slotWidget:setItemId(itemId)
      end
      if slotWidget.setOn then
        slotWidget:setOn(itemId > 0)
      end
    end
  end
end

local function getSwapScenarioNameCountLabel(list)
  local count = #(type(list) == "table" and list or {})
  return tostring(count)
end

local function refreshScenarioRows(setKey)
  local panel = swapSetPanels[setKey]
  local scenarios = swapSettings.scenarios
  local scenarioData = scenarios and scenarios[setKey]
  if not panel or type(scenarioData) ~= "table" then
    return
  end

  scenarioData.enemyNames = normalizeSwapNameList(scenarioData.enemyNames or {})
  scenarioData.monsterNames = normalizeSwapNameList(scenarioData.monsterNames or {})

  local playersRangeCheck = getSwapScenarioWidget(panel, "playersRangeCheck")
  local playersMin = getSwapScenarioWidget(panel, "playersMin")
  local pkRangeCheck = getSwapScenarioWidget(panel, "pkRangeCheck")
  local pkMin = getSwapScenarioWidget(panel, "pkMin")
  local targetOnCheck = getSwapScenarioWidget(panel, "targetOnCheck")
  local targetHpCheck = getSwapScenarioWidget(panel, "targetHpCheck")
  local targetHpLimit = getSwapScenarioWidget(panel, "targetHpLimit")
  local hasEnemyCheck = getSwapScenarioWidget(panel, "hasEnemyCheck")
  local enemyNamesCount = getSwapScenarioWidget(panel, "enemyNamesCount")
  local hpCheck = getSwapScenarioWidget(panel, "hpCheck")
  local hpLimit = getSwapScenarioWidget(panel, "hpLimit")
  local manaCheck = getSwapScenarioWidget(panel, "manaCheck")
  local manaLimit = getSwapScenarioWidget(panel, "manaLimit")
  local hasMonsterCheck = getSwapScenarioWidget(panel, "hasMonsterCheck")
  local monsterMin = getSwapScenarioWidget(panel, "monsterMin")
  local monsterNamesCount = getSwapScenarioWidget(panel, "monsterNamesCount")

  if playersRangeCheck then playersRangeCheck:setChecked(scenarioData.playersRangeEnabled == true) end
  if playersMin and playersMin.setValue then playersMin:setValue(tonumber(scenarioData.playersMin) or 0) end

  if pkRangeCheck then pkRangeCheck:setChecked(scenarioData.pkRangeEnabled == true) end
  if pkMin and pkMin.setValue then pkMin:setValue(tonumber(scenarioData.pkMin) or 0) end

  if targetOnCheck then targetOnCheck:setChecked(scenarioData.targetEnabled == true) end
  if targetHpCheck then targetHpCheck:setChecked(scenarioData.targetHpEnabled == true) end
  if targetHpLimit and targetHpLimit.setValue then targetHpLimit:setValue(tonumber(scenarioData.targetHpBelow) or 0) end

  if hasEnemyCheck then hasEnemyCheck:setChecked(scenarioData.hasEnemy == true) end
  if enemyNamesCount then
    enemyNamesCount:setText(getSwapScenarioNameCountLabel(scenarioData.enemyNames))
  end

  if hpCheck then hpCheck:setChecked(scenarioData.hpEnabled == true) end
  if hpLimit and hpLimit.setValue then hpLimit:setValue(tonumber(scenarioData.hpBelow) or 0) end

  if manaCheck then manaCheck:setChecked(scenarioData.manaEnabled == true) end
  if manaLimit and manaLimit.setValue then manaLimit:setValue(tonumber(scenarioData.manaBelow) or 0) end

  if hasMonsterCheck then hasMonsterCheck:setChecked(scenarioData.hasMonster == true) end
  if monsterMin and monsterMin.setValue then monsterMin:setValue(tonumber(scenarioData.monsterMin) or 1) end
  if monsterNamesCount then
    monsterNamesCount:setText(getSwapScenarioNameCountLabel(scenarioData.monsterNames))
  end
end

local function updatePrioritySetButton()
  local longText = "Prioridade do Set: " .. swapSettings.prioritySet

  if swapPriorityButton then
    swapPriorityButton:setText(longText)
  end
end

local function syncSwapSetControlIconState()
  local definition = definitionsByKey and definitionsByKey.swapSetModuleOff
  if not definition then
    return
  end
  syncStateFromExternal(definition)
end

local function refreshSwapUi()
  normalizeSwapSetConfig()

  if swapEnableSwitch then
    swapEnableSwitch:setOn(swapSettings.autoSwapEnabled == true)
  end

  if swapConfigRow and swapConfigRow.rangeEdit then
    swapConfigRow.rangeEdit:setText(tostring(swapSettings.safeRange))
  end

  updatePrioritySetButton()
  refreshEqRows("SET1")
  refreshEqRows("SET2")
  refreshScenarioRows("SET1")
  refreshScenarioRows("SET2")

  if swapSetupWindow and swapSetupWindow.header and swapSetupWindow.header.statusLabel then
    local profileName = getSwapProfileName(getSelectedSwapProfileId())
    local statusText = string.format("Status: %s | Perfil: %s", swapSettings.autoSwapEnabled and "ON" or "OFF", profileName)
    swapSetupWindow.header.statusLabel:setText(statusText)
  end

  syncSwapSetControlIconState()
end

local function togglePrioritySet()
  if swapSettings.prioritySet == "SET1" then
    swapSettings.prioritySet = "SET2"
  else
    swapSettings.prioritySet = "SET1"
  end
  swapLastEquippedSet = nil
  updatePrioritySetButton()
end

local function swapIsSafe(range)
  local checkRange = clamp(tonumber(range) or 8, 1, 15)
  if type(isSafe) == "function" then
    local ok, value = pcall(isSafe, checkRange)
    if ok and type(value) == "boolean" then
      return value
    end
  end

  local player = g_game and g_game.getLocalPlayer and g_game.getLocalPlayer()
  local playerPos = player and player:getPosition()
  if not playerPos then
    return true
  end

  for _, creature in ipairs(getSpectators() or {}) do
    if creature and creature ~= player then
      local isPlayer = creature.isPlayer and creature:isPlayer()
      if isPlayer then
        local pos = creature:getPosition()
        if pos and pos.z == playerPos.z and distanceChebyshev(playerPos, pos) <= checkRange then
          return false
        end
      end
    end
  end
  return true
end

local function getLocalHpPercent()
  if type(hppercent) == "function" then
    local ok, value = pcall(hppercent)
    if ok and type(value) == "number" then
      return clamp(math.floor(value), 0, 100)
    end
  end

  local player = g_game and g_game.getLocalPlayer and g_game.getLocalPlayer()
  if player and player.getHealthPercent then
    return clamp(math.floor(tonumber(player:getHealthPercent()) or 100), 0, 100)
  end

  return 100
end

local function getLocalManaPercent()
  if type(manapercent) == "function" then
    local ok, value = pcall(manapercent)
    if ok and type(value) == "number" then
      return clamp(math.floor(value), 0, 100)
    end
  end

  local player = g_game and g_game.getLocalPlayer and g_game.getLocalPlayer()
  if player and player.getManaPercent then
    return clamp(math.floor(tonumber(player:getManaPercent()) or 100), 0, 100)
  end

  return 100
end

local function isSwapAllyCreature(creature)
  if not creature or not creature.isPlayer or not creature:isPlayer() then
    return false
  end

  if creature.isLocalPlayer and creature:isLocalPlayer() then
    return true
  end

  local localPlayer = g_game and g_game.getLocalPlayer and g_game.getLocalPlayer() or nil
  if localPlayer and localPlayer.getName and creature.getName then
    local okLocalName, localName = pcall(function() return localPlayer:getName() end)
    local okCreatureName, creatureName = pcall(function() return creature:getName() end)
    if okLocalName and okCreatureName and normalizeSwapNameKey(localName) ~= "" and normalizeSwapNameKey(localName) == normalizeSwapNameKey(creatureName) then
      return true
    end
  end

  if type(isAlly) == "function" then
    local okAlly, allyValue = pcall(isAlly, creature)
    if okAlly and allyValue == true then
      return true
    end
  end

  if creature.isPartyMember then
    local okParty, partyValue = pcall(function() return creature:isPartyMember() end)
    if okParty and partyValue == true then
      return true
    end
  end

  if creature.getEmblem then
    local okEmblem, emblemValue = pcall(function() return creature:getEmblem() end)
    if okEmblem and tonumber(emblemValue) == 1 then
      return true
    end
  end

  return false
end

local function isSwapEnemyCreature(creature)
  if not creature or not creature.isPlayer or not creature:isPlayer() then
    return false
  end
  if creature.isLocalPlayer and creature:isLocalPlayer() then
    return false
  end
  if isSwapAllyCreature(creature) then
    return false
  end

  if type(isEnemy) == "function" then
    local okCreature, creatureValue = pcall(isEnemy, creature)
    if okCreature and creatureValue == true then
      return true
    end

    local creatureName = ""
    if creature.getName then
      local okNameRead, nameValue = pcall(function() return creature:getName() end)
      if okNameRead and type(nameValue) == "string" then
        creatureName = nameValue
      end
    end
    if creatureName ~= "" then
      local okName, nameValue = pcall(isEnemy, creatureName)
      if okName and nameValue == true then
        return true
      end
    end
  end

  if creature.getEmblem then
    local okEmblem, emblemValue = pcall(function() return creature:getEmblem() end)
    if okEmblem and tonumber(emblemValue) == 2 then
      return true
    end
  end

  return false
end

local function isSwapPkCreature(creature)
  if not creature or not creature.getSkull then
    return false
  end
  local okSkull, skullValue = pcall(function() return creature:getSkull() end)
  if not okSkull then
    return false
  end
  return (tonumber(skullValue) or 0) > 0
end

local function getSwapCreatureName(creature)
  if not creature or not creature.getName then
    return ""
  end
  local okName, nameValue = pcall(function() return creature:getName() end)
  if not okName then
    return ""
  end
  return normalizeSwapNameValue(nameValue)
end

local function collectSwapScenarioStats()
  local checkRange = clamp(tonumber(swapSettings.safeRange) or 8, 1, 15)
  local target = g_game and g_game.getAttackingCreature and g_game.getAttackingCreature() or nil
  local targetOn = target ~= nil
  local targetHpPercent = 100
  if targetOn and target and target.getHealthPercent then
    local okTargetHp, hpValue = pcall(function() return target:getHealthPercent() end)
    if okTargetHp and type(hpValue) == "number" then
      targetHpPercent = clamp(math.floor(hpValue), 0, 100)
    end
  end
  local stats = {
    playersOnScreen = 0,
    pksOnScreen = 0,
    enemiesOnScreen = 0,
    monstersOnScreen = 0,
    enemyNameCounts = {},
    monsterNameCounts = {},
    hpPercent = getLocalHpPercent(),
    manaPercent = getLocalManaPercent(),
    targetOn = targetOn,
    targetHpPercent = targetHpPercent
  }

  local player = g_game and g_game.getLocalPlayer and g_game.getLocalPlayer()
  local playerPos = player and player:getPosition()

  for _, creature in ipairs(getSpectators() or {}) do
    if creature and creature ~= player then
      local creaturePos = creature.getPosition and creature:getPosition() or nil
      local sameFloor = not playerPos or (creaturePos and creaturePos.z == playerPos.z)
      local inCheckRange = true
      if playerPos and creaturePos then
        inCheckRange = distanceChebyshev(playerPos, creaturePos) <= checkRange
      end
      if sameFloor then
        if creature.isPlayer and creature:isPlayer() then
          local allyPlayer = isSwapAllyCreature(creature)
          if not allyPlayer and inCheckRange then
            stats.playersOnScreen = stats.playersOnScreen + 1

            if isSwapPkCreature(creature) then
              stats.pksOnScreen = stats.pksOnScreen + 1
            end
          end

          if inCheckRange and isSwapEnemyCreature(creature) then
            stats.enemiesOnScreen = stats.enemiesOnScreen + 1
            local enemyNameKey = normalizeSwapNameKey(getSwapCreatureName(creature))
            if enemyNameKey ~= "" then
              stats.enemyNameCounts[enemyNameKey] = (tonumber(stats.enemyNameCounts[enemyNameKey]) or 0) + 1
            end
          end
        elseif creature.isMonster and creature:isMonster() then
          local healthPercent = 100
          if creature.getHealthPercent then
            local okHp, hpValue = pcall(function() return creature:getHealthPercent() end)
            if okHp then
              healthPercent = tonumber(hpValue) or 100
            end
          end
          if inCheckRange and (not healthPercent or healthPercent > 0) then
            stats.monstersOnScreen = stats.monstersOnScreen + 1
            local monsterNameKey = normalizeSwapNameKey(getSwapCreatureName(creature))
            if monsterNameKey ~= "" then
              stats.monsterNameCounts[monsterNameKey] = (tonumber(stats.monsterNameCounts[monsterNameKey]) or 0) + 1
            end
          end
        end
      end
    end
  end

  return stats
end

local swapScenarioStatsCache = {
  timestamp = 0,
  stats = nil
}

local function getSwapScenarioStatsCached()
  local currentTime = nowMs()
  if swapScenarioStatsCache.stats and (currentTime - (swapScenarioStatsCache.timestamp or 0) < 700) then
    return swapScenarioStatsCache.stats
  end

  local stats = collectSwapScenarioStats()
  swapScenarioStatsCache.stats = stats
  swapScenarioStatsCache.timestamp = currentTime
  return stats
end

local function doesSwapScenarioMatch(setKey, stats)
  local scenarioData = swapSettings.scenarios and swapSettings.scenarios[setKey]
  if type(scenarioData) ~= "table" then
    return false
  end

  local enemyNameLookup = buildSwapNameLookup(scenarioData.enemyNames)
  local enemyFilterCount = 0
  for _, _ in pairs(enemyNameLookup) do
    enemyFilterCount = enemyFilterCount + 1
  end

  local monsterNameLookup = buildSwapNameLookup(scenarioData.monsterNames)
  local monsterFilterCount = 0
  for _, _ in pairs(monsterNameLookup) do
    monsterFilterCount = monsterFilterCount + 1
  end

  local matchedEnemyCount = stats.enemiesOnScreen
  if enemyFilterCount > 0 then
    matchedEnemyCount = 0
    for nameKey, count in pairs(stats.enemyNameCounts or {}) do
      if enemyNameLookup[nameKey] then
        matchedEnemyCount = matchedEnemyCount + (tonumber(count) or 0)
      end
    end
  end

  local matchedMonsterCount = stats.monstersOnScreen
  if monsterFilterCount > 0 then
    matchedMonsterCount = 0
    for nameKey, count in pairs(stats.monsterNameCounts or {}) do
      if monsterNameLookup[nameKey] then
        matchedMonsterCount = matchedMonsterCount + (tonumber(count) or 0)
      end
    end
  end

  if scenarioData.playersRangeEnabled == true then
    local minPlayers = clamp(math.floor(tonumber(scenarioData.playersMin) or 0), 0, 200)
    if minPlayers <= 0 then
      if stats.playersOnScreen ~= 0 then
        return false
      end
    else
      if stats.playersOnScreen < minPlayers then
        return false
      end
    end
  end

  if scenarioData.pkRangeEnabled == true then
    local minPk = clamp(math.floor(tonumber(scenarioData.pkMin) or 0), 0, 200)
    if minPk <= 0 then
      if stats.pksOnScreen ~= 0 then
        return false
      end
    else
      if stats.pksOnScreen < minPk then
        return false
      end
    end
  end

  if scenarioData.targetEnabled == true and stats.targetOn ~= true then
    return false
  end

  if scenarioData.targetHpEnabled == true then
    if stats.targetOn ~= true then
      return false
    end
    local targetHpLimit = clamp(math.floor(tonumber(scenarioData.targetHpBelow) or 0), 0, 100)
    if (tonumber(stats.targetHpPercent) or 100) > targetHpLimit then
      return false
    end
  end

  if scenarioData.hasEnemy == true then
    if matchedEnemyCount <= 0 then
      return false
    end
  end

  if scenarioData.hpEnabled == true then
    local hpLimit = clamp(math.floor(tonumber(scenarioData.hpBelow) or 0), 0, 100)
    if stats.hpPercent > hpLimit then
      return false
    end
  end

  if scenarioData.manaEnabled == true then
    local manaLimit = clamp(math.floor(tonumber(scenarioData.manaBelow) or 0), 0, 100)
    if stats.manaPercent > manaLimit then
      return false
    end
  end

  if scenarioData.hasMonster == true then
    local minMonsters = clamp(math.floor(tonumber(scenarioData.monsterMin) or 1), 1, 200)
    if matchedMonsterCount < minMonsters then
      return false
    end
  end

  return true
end

local function resolveSwapScenarioSet()
  local stats = getSwapScenarioStatsCached()

  local set1Match = doesSwapScenarioMatch("SET1", stats)
  local set2Match = doesSwapScenarioMatch("SET2", stats)

  if set1Match and not set2Match then
    return "SET1"
  end
  if set2Match and not set1Match then
    return "SET2"
  end

  if set1Match and set2Match then
    if swapLastEquippedSet == "SET1" or swapLastEquippedSet == "SET2" then
      return swapLastEquippedSet
    end
    return swapSettings.prioritySet == "SET2" and "SET2" or "SET1"
  end

  return swapSettings.prioritySet == "SET2" and "SET2" or "SET1"
end

local function equipItemToSlot(itemId, slot)
  local targetId = clamp(tonumber(itemId) or 0, 0, 50000)
  if targetId <= 0 then
    return false
  end

  local current = getInventoryItemSafe(slot)
  if current and current:getId() == targetId then
    return true
  end

  if g_game and g_game.getClientVersion and g_game.getClientVersion() >= 870 and g_game.equipItemId then
    g_game.equipItemId(targetId)
    return true
  end

  local itemToEquip = nil
  if type(findItem) == "function" then
    itemToEquip = findItem(targetId)
  end
  if not itemToEquip then
    itemToEquip = findItemById(targetId)
  end

  if itemToEquip and type(moveToSlot) == "function" then
    moveToSlot(itemToEquip, slot, itemToEquip:getCount())
    return true
  end

  return false
end

local function equipSet(setData)
  if type(setData) ~= "table" then
    return false
  end

  local desiredLeft = clamp(tonumber(setData["left-hand"]) or 0, 0, 50000)
  local desiredRight = clamp(tonumber(setData["right-hand"]) or 0, 0, 50000)
  local leftHand = getInventoryItemSafe(SlotLeft)
  local rightHand = getInventoryItemSafe(SlotRight)

  if desiredRight > 0 and leftHand and rightHand then
    if rightHand:getId() ~= desiredRight and leftHand:getId() ~= desiredLeft and type(moveToSlot) == "function" then
      moveToSlot(leftHand, SlotBack, leftHand:getCount())
    end
  end

  if desiredLeft > 0 and leftHand and rightHand then
    if leftHand:getId() ~= desiredLeft and rightHand:getId() ~= desiredRight and type(moveToSlot) == "function" then
      moveToSlot(rightHand, SlotBack, rightHand:getCount())
    end
  end

  local hasChange = false
  local allMatched = true

  for _, part in ipairs(swapParts) do
    local desiredId = clamp(tonumber(setData[part.id]) or 0, 0, 50000)
    if desiredId > 0 then
      local equipped = getInventoryItemSafe(part.slot)
      local equippedId = equipped and equipped:getId() or 0
      if equippedId ~= desiredId then
        allMatched = false
        if equipItemToSlot(desiredId, part.slot) then
          hasChange = true
        end
      end
    end
  end

  return hasChange or allMatched
end

g_ui.loadUIFromString([[
SwapSetSlotItem < BotItem
  size: 28 28
  border-width: 1
  border-color: #666666
  background-color: #4e4e4e
  selectable: true
  editable: true
  $on:
    border-color: #5fb7ff

SwapSetEqPanel < Panel
  anchors.fill: parent
  background-color: #4e4e4e
  border-width: 1
  border-color: #676d75
  padding-left: 4
  padding-right: 4
  padding-top: 3
  padding-bottom: 3

  Label
    id: title
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: 16
    color: #9aa6b2
    text-align: center
    font: verdana-11px-rounded

  Panel
    id: slotsGrid
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: title.bottom
    margin-top: 8
    size: 232 28

    SwapSetSlotItem
      id: left-hand
      image-source: /images/game/slots/left-hand
      anchors.left: parent.left
      anchors.top: parent.top

    SwapSetSlotItem
      id: head
      image-source: /images/game/slots/head
      anchors.left: left-hand.right
      anchors.top: parent.top
      margin-left: 6

    SwapSetSlotItem
      id: body
      image-source: /images/game/slots/body
      anchors.left: head.right
      anchors.top: parent.top
      margin-left: 6

    SwapSetSlotItem
      id: right-hand
      image-source: /images/game/slots/right-hand
      anchors.left: body.right
      anchors.top: parent.top
      margin-left: 6

    SwapSetSlotItem
      id: legs
      image-source: /images/game/slots/legs
      anchors.left: right-hand.right
      anchors.top: parent.top
      margin-left: 6

    SwapSetSlotItem
      id: feet
      image-source: /images/game/slots/feet
      anchors.left: legs.right
      anchors.top: parent.top
      margin-left: 6

    SwapSetSlotItem
      id: ammo
      image-source: /images/game/slots/ammo
      anchors.left: feet.right
      anchors.top: parent.top
      margin-left: 6

  Button
    id: cloneButton
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: slotsGrid.bottom
    margin-top: 6
    height: 18
    text: Clonar equipado
    font: verdana-11px-rounded
    tooltip: PT: Copia o equipamento atual para este set.\nEN: Copy current equipment into this set.

  Panel
    id: scenarioPanel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: cloneButton.bottom
    anchors.bottom: parent.bottom
    margin-top: 4
    border-width: 1
    border-color: #6b727a
    background-color: #4e4e4e
    padding-left: 3
    padding-right: 3
    padding-top: 2
    padding-bottom: 2

    Label
      id: scenarioTitle
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: 14
      text: Filtros de equip
      color: #cfd8e1
      text-align: center
      font: verdana-11px-rounded

    Panel
      id: playersRangeRow
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: scenarioTitle.bottom
      margin-top: 1
      height: 18

      CheckBox
        id: playersRangeCheck
        anchors.left: parent.left
        anchors.top: parent.top
        width: 112
        height: 14
        text: Player Tela
        color: #dbe8f5
        font: verdana-11px-rounded
        tooltip: PT: Ativa filtro de Player na tela (ignora guild/party). Qtd=0 exige tela limpa; Qtd>0 exige no minimo esse valor.\nEN: Enable player-on-screen filter (guild/party ignored). Qty=0 requires clear screen; Qty>0 requires at least this value.

      SpinBox
        id: playersMin
        anchors.left: playersRangeCheck.right
        anchors.top: parent.top
        margin-left: 2
        width: 50
        height: 16
        text-align: center
        step: 1
        editable: true
        focusable: true
        font: verdana-11px-rounded
        tooltip: PT: Quantidade de players para este filtro.\nEN: Player amount for this filter.

    Panel
      id: pkRangeRow
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: playersRangeRow.bottom
      margin-top: 1
      height: 18

      CheckBox
        id: pkRangeCheck
        anchors.left: parent.left
        anchors.top: parent.top
        width: 112
        height: 14
        text: PK Tela
        color: #dbe8f5
        font: verdana-11px-rounded
        tooltip: PT: Ativa filtro de PK na tela (ignora guild/party). Qtd=0 exige sem PK; Qtd>0 exige no minimo esse valor.\nEN: Enable PK-on-screen filter (guild/party ignored). Qty=0 requires no PK; Qty>0 requires at least this value.

      SpinBox
        id: pkMin
        anchors.left: pkRangeCheck.right
        anchors.top: parent.top
        margin-left: 2
        width: 50
        height: 16
        text-align: center
        step: 1
        editable: true
        focusable: true
        font: verdana-11px-rounded
        tooltip: PT: Quantidade de PKs para este filtro.\nEN: PK amount for this filter.

    Panel
      id: targetOnRow
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: pkRangeRow.bottom
      margin-top: 1
      height: 18

      CheckBox
        id: targetOnCheck
        anchors.left: parent.left
        anchors.top: parent.top
        width: 112
        height: 14
        text: Target ON
        color: #dbe8f5
        font: verdana-11px-rounded
        tooltip: PT: Exige ter target ativo no momento.\nEN: Require an active attack target right now.

    Panel
      id: targetHpRow
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: targetOnRow.bottom
      margin-top: 1
      height: 18

      CheckBox
        id: targetHpCheck
        anchors.left: parent.left
        anchors.top: parent.top
        width: 112
        height: 14
        text: HP Target <=
        color: #dbe8f5
        font: verdana-11px-rounded
        tooltip: PT: Exige HP do target menor ou igual ao valor.\nEN: Require target HP lower than or equal to the value.

      SpinBox
        id: targetHpLimit
        anchors.left: targetHpCheck.right
        anchors.top: parent.top
        margin-left: 2
        width: 50
        height: 16
        text-align: center
        step: 1
        editable: true
        focusable: true
        font: verdana-11px-rounded
        tooltip: PT: Limite de HP do target.\nEN: Target HP threshold.

      Label
        id: targetHpPercentLabel
        anchors.left: targetHpLimit.right
        anchors.top: parent.top
        margin-left: 1
        width: 12
        height: 14
        text: %
        color: #dbe8f5
        font: verdana-11px-rounded

    Panel
      id: hpRow
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: targetHpRow.bottom
      margin-top: 1
      height: 18

      CheckBox
        id: hpCheck
        anchors.left: parent.left
        anchors.top: parent.top
        width: 112
        height: 14
        text: HP <=
        color: #dbe8f5
        font: verdana-11px-rounded
        tooltip: PT: Exige HP menor ou igual ao valor.\nEN: Require HP lower than or equal to the value.

      SpinBox
        id: hpLimit
        anchors.left: hpCheck.right
        anchors.top: parent.top
        margin-left: 2
        width: 50
        height: 16
        text-align: center
        step: 1
        editable: true
        focusable: true
        font: verdana-11px-rounded
        tooltip: PT: Limite de HP.\nEN: HP threshold.

      Label
        id: hpPercentLabel
        anchors.left: hpLimit.right
        anchors.top: parent.top
        margin-left: 1
        width: 12
        height: 14
        text: %
        color: #dbe8f5
        font: verdana-11px-rounded

    Panel
      id: manaRow
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: hpRow.bottom
      margin-top: 1
      height: 18

      CheckBox
        id: manaCheck
        anchors.left: parent.left
        anchors.top: parent.top
        width: 112
        height: 14
        text: Mana <=
        color: #dbe8f5
        font: verdana-11px-rounded
        tooltip: PT: Exige Mana menor ou igual ao valor.\nEN: Require Mana lower than or equal to the value.

      SpinBox
        id: manaLimit
        anchors.left: manaCheck.right
        anchors.top: parent.top
        margin-left: 2
        width: 50
        height: 16
        text-align: center
        step: 1
        editable: true
        focusable: true
        font: verdana-11px-rounded
        tooltip: PT: Limite de Mana.\nEN: Mana threshold.

      Label
        id: manaPercentLabel
        anchors.left: manaLimit.right
        anchors.top: parent.top
        margin-left: 1
        width: 12
        height: 14
        text: %
        color: #dbe8f5
        font: verdana-11px-rounded

    Panel
      id: enemyHeaderRow
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: manaRow.bottom
      margin-top: 1
      height: 18

      CheckBox
        id: hasEnemyCheck
        anchors.left: parent.left
        anchors.top: parent.top
        width: 74
        height: 14
        text: Enemy
        color: #dbe8f5
        font: verdana-11px-rounded
        tooltip: PT: Exige ao menos 1 enemy na tela (ou da lista). Ignora players da mesma party/guild.\nEN: Require at least 1 enemy on screen (or from the list). Ignore same party/guild players.

      Button
        id: enemyNamesButton
        anchors.left: hasEnemyCheck.right
        anchors.top: parent.top
        margin-left: 2
        width: 38
        height: 16
        text: Add
        font: verdana-11px-rounded
        tooltip: PT: Abrir cadastro de nomes de enemy.\nEN: Open enemy names editor.

      Label
        id: enemyNamesCount
        anchors.left: enemyNamesButton.right
        anchors.top: parent.top
        margin-left: 3
        width: 30
        height: 16
        text: 0
        color: #dbe8f5
        font: verdana-11px-rounded
        text-align: left
        tooltip: PT: Quantidade de nomes de enemy cadastrados.\nEN: Number of registered enemy names.

    Panel
      id: monsterHeaderRow
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: enemyHeaderRow.bottom
      margin-top: 1
      height: 18

      CheckBox
        id: hasMonsterCheck
        anchors.left: parent.left
        anchors.top: parent.top
        width: 112
        height: 14
        text: Monstros
        color: #dbe8f5
        font: verdana-11px-rounded
        tooltip: PT: Ativa filtro de monstros na tela usando a quantidade ao lado.\nEN: Enable monsters-on-screen filter using the amount on the side.

      SpinBox
        id: monsterMin
        anchors.left: hasMonsterCheck.right
        anchors.top: parent.top
        margin-left: 2
        width: 50
        height: 16
        text-align: center
        step: 1
        editable: true
        focusable: true
        font: verdana-11px-rounded
        tooltip: PT: Quantidade de monstros para este filtro.\nEN: Monsters amount for this filter.

      Button
        id: monsterNamesButton
        anchors.left: monsterMin.right
        anchors.top: parent.top
        margin-left: 2
        width: 38
        height: 16
        text: Add
        font: verdana-11px-rounded
        tooltip: PT: Abrir cadastro de nomes de monstro.\nEN: Open monster names editor.

      Label
        id: monsterNamesCount
        anchors.left: monsterNamesButton.right
        anchors.top: parent.top
        margin-left: 3
        width: 30
        height: 16
        text: 0
        color: #dbe8f5
        font: verdana-11px-rounded
        text-align: left
        tooltip: PT: Quantidade de nomes de monstro cadastrados.\nEN: Number of registered monster names.

SwapSetSetupWindow < MainWindow
  text: Setup SwapSet
  size: 612 560
  visible: false
  @onEscape: self:hide()

  Panel
    id: header
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 42
    margin-top: 6
    margin-left: 8
    margin-right: 8

    Label
      id: titleLabel
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      text: Auto swap com cenarios personalizados por set.
      color: #dbe8f5
      font: verdana-11px-rounded
      text-align: left

    Label
      id: statusLabel
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: titleLabel.bottom
      margin-top: 2
      text: Status
      color: #9aa6b2
      font: verdana-11px-rounded
      text-align: left

  Panel
    id: contentPanel
    anchors.top: header.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: footer.top
    margin-top: 4
    margin-left: 8
    margin-right: 8
    margin-bottom: 4
    background-color: #4e4e4e
    border-width: 1
    border-color: #676d75
    padding-left: 3
    padding-right: 3
    padding-top: 2
    padding-bottom: 2

    VerticalScrollBar
      id: contentScroll
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      step: 14
      pixels-scroll: false

    ScrollablePanel
      id: content
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: contentScroll.left
      anchors.bottom: parent.bottom
      margin-right: 5
      background-color: #4e4e4e
      border-width: 1
      border-color: #707985
      padding-left: 3
      padding-right: 3
      padding-top: 2
      padding-bottom: 2
      vertical-scrollbar: contentScroll
      layout:
        type: verticalBox
        spacing: 4

  Panel
    id: footer
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 24
    margin-left: 8
    margin-right: 8
    margin-bottom: 6

    Button
      id: helpButton
      anchors.right: closeButton.left
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 6
      size: 70 18
      text: Ajuda
      font: verdana-11px-rounded

    Button
      id: closeButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      size: 74 18
      text: Fechar
      font: verdana-11px-rounded

SwapSetNamesWindow < MainWindow
  text: Lista de nomes
  size: 330 320
  visible: false
  @onEscape: self:hide()

  Panel
    id: header
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    margin-top: 6
    margin-left: 8
    margin-right: 8
    height: 36

    Label
      id: titleLabel
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: 16
      text: Configurar nomes
      color: #dbe8f5
      font: verdana-11px-rounded
      text-align: left

    Label
      id: hintLabel
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: titleLabel.bottom
      margin-top: 1
      height: 14
      text: Um nome por linha
      color: #9aa6b2
      font: verdana-11px-rounded
      text-align: left

  Panel
    id: controls
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: header.bottom
    margin-top: 3
    margin-left: 8
    margin-right: 8
    height: 20

    Button
      id: addButton
      anchors.right: parent.right
      anchors.top: parent.top
      width: 56
      height: 18
      text: Adicionar
      font: verdana-11px-rounded

    TextEdit
      id: nameInput
      anchors.left: parent.left
      anchors.right: addButton.left
      anchors.top: parent.top
      margin-right: 4
      height: 18
      font: verdana-11px-rounded
      placeholder: Nome

  Panel
    id: listPanel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: controls.bottom
    anchors.bottom: footer.top
    margin-top: 4
    margin-left: 8
    margin-right: 8
    margin-bottom: 4
    background-color: #4e4e4e
    border-width: 1
    border-color: #676d75
    padding-left: 3
    padding-right: 3
    padding-top: 2
    padding-bottom: 2

    VerticalScrollBar
      id: listScroll
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      step: 14
      pixels-scroll: false

    ScrollablePanel
      id: list
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: listScroll.left
      anchors.bottom: parent.bottom
      margin-right: 5
      background-color: #4e4e4e
      border-width: 1
      border-color: #707985
      padding-left: 2
      padding-right: 2
      padding-top: 2
      padding-bottom: 2
      vertical-scrollbar: listScroll
      layout:
        type: verticalBox
        spacing: 2

  Panel
    id: footer
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-left: 8
    margin-right: 8
    margin-bottom: 6
    height: 22

    Button
      id: clearButton
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: 74
      height: 18
      text: Limpar
      font: verdana-11px-rounded

    Button
      id: closeButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: 74
      height: 18
      text: Fechar
      font: verdana-11px-rounded

    Label
      id: countLabel
      anchors.left: clearButton.right
      anchors.right: closeButton.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 6
      margin-right: 6
      height: 14
      text: 0 nome(s)
      color: #dbe8f5
      font: verdana-11px-rounded
      text-align: center
]])

swapSetupWindow = g_ui.createWidget("SwapSetSetupWindow", rootWidget)
swapSetupWindow:hide()
swapNamesWindow = g_ui.createWidget("SwapSetNamesWindow", rootWidget)
if swapNamesWindow and swapNamesWindow.hide then
  swapNamesWindow:hide()
end

local swapContent = swapSetupWindow.contentPanel.content

function getSwapScenarioData(setKey)
  swapSettings.scenarios = type(swapSettings.scenarios) == "table" and swapSettings.scenarios or {}
  swapSettings.scenarios[setKey] = type(swapSettings.scenarios[setKey]) == "table" and swapSettings.scenarios[setKey] or {}
  return swapSettings.scenarios[setKey]
end

function getSwapScenarioNameList(setKey, listKey)
  local scenarioData = getSwapScenarioData(setKey)
  scenarioData[listKey] = normalizeSwapNameList(scenarioData[listKey] or {})
  return scenarioData[listKey]
end

function addNamesToSwapScenario(setKey, listKey, textValue)
  local list = getSwapScenarioNameList(setKey, listKey)
  local existing = buildSwapNameLookup(list)
  local added = 0
  local parsedAny = false

  for rawName in string.gmatch(tostring(textValue or ""), "[^\r\n,;]+") do
    parsedAny = true
    local cleaned = normalizeSwapNameValue(rawName)
    local key = normalizeSwapNameKey(cleaned)
    if cleaned ~= "" and key ~= "" and not existing[key] then
      existing[key] = true
      table.insert(list, cleaned)
      added = added + 1
    end
  end

  if not parsedAny then
    local cleaned = normalizeSwapNameValue(textValue)
    local key = normalizeSwapNameKey(cleaned)
    if cleaned ~= "" and key ~= "" and not existing[key] then
      existing[key] = true
      table.insert(list, cleaned)
      added = 1
    end
  end

  if added > 0 then
    table.sort(list, function(a, b)
      return normalizeSwapNameKey(a) < normalizeSwapNameKey(b)
    end)
    swapLastEquippedSet = nil
  end

  return added
end

function removeNameFromSwapScenario(setKey, listKey, index)
  local list = getSwapScenarioNameList(setKey, listKey)
  if index < 1 or index > #list then
    return false
  end
  table.remove(list, index)
  swapLastEquippedSet = nil
  return true
end

function clearSwapScenarioNames(setKey, listKey)
  local list = getSwapScenarioNameList(setKey, listKey)
  if #list <= 0 then
    return false
  end
  for i = #list, 1, -1 do
    table.remove(list, i)
  end
  swapLastEquippedSet = nil
  return true
end

local refreshSwapNamesWindow
function getSwapNamesWindowWidget(childId)
  return findSwapWidgetByIdRecursive(swapNamesWindow, childId)
end

function isSwapNamesWindowReady()
  if not swapNamesWindow then
    return false
  end
  return getSwapNamesWindowWidget("header")
    and getSwapNamesWindowWidget("titleLabel")
    and getSwapNamesWindowWidget("hintLabel")
    and getSwapNamesWindowWidget("nameInput")
    and getSwapNamesWindowWidget("addButton")
    and getSwapNamesWindowWidget("list")
    and getSwapNamesWindowWidget("clearButton")
    and getSwapNamesWindowWidget("closeButton")
    and getSwapNamesWindowWidget("countLabel")
end

function bindSwapNamesWindowHandlers()
  if not swapNamesWindow or swapNamesWindow.__picNamesHandlersBound == true then
    return
  end

  local addButton = getSwapNamesWindowWidget("addButton")
  local nameInput = getSwapNamesWindowWidget("nameInput")
  local clearButton = getSwapNamesWindowWidget("clearButton")
  local closeButton = getSwapNamesWindowWidget("closeButton")

  if addButton then
    addButton:setTooltip("PT: Adiciona nomes na lista (aceita virgula, ';' e quebra de linha).\nEN: Add names to the list (supports comma, ';' and line breaks).")
    addButton.onClick = function()
      local setKey = swapNamesListContext.setKey
      local listKey = swapNamesListContext.listKey
      if not setKey or not listKey then
        return
      end

      local input = nameInput and nameInput.getText and nameInput:getText() or ""
      local added = addNamesToSwapScenario(setKey, listKey, input)
      if added > 0 then
        if nameInput and nameInput.setText then
          nameInput:setText("")
        end
        refreshSwapNamesWindow()
        refreshScenarioRows(setKey)
      end
    end
  end

  if clearButton then
    clearButton:setTooltip("PT: Remove todos os nomes cadastrados.\nEN: Remove all registered names.")
    clearButton.onClick = function()
      local setKey = swapNamesListContext.setKey
      local listKey = swapNamesListContext.listKey
      if not setKey or not listKey then
        return
      end

      if clearSwapScenarioNames(setKey, listKey) then
        refreshSwapNamesWindow()
        refreshScenarioRows(setKey)
      end
    end
  end

  if closeButton then
    closeButton:setTooltip("PT: Fecha esta janela.\nEN: Close this window.")
    closeButton.onClick = function()
      swapNamesWindow:hide()
    end
  end

  swapNamesWindow.__picNamesHandlersBound = true
end

function ensureSwapNamesWindow()
  if swapNamesWindow and (not swapNamesWindow.isDestroyed or not swapNamesWindow:isDestroyed()) then
    if isSwapNamesWindowReady() then
      bindSwapNamesWindowHandlers()
      return true
    end
    if swapNamesWindow.destroy then
      swapNamesWindow:destroy()
    end
    swapNamesWindow = nil
  end

  local parent = rootWidget or (g_ui and g_ui.getRootWidget and g_ui.getRootWidget())
  if not parent then
    return false
  end

  swapNamesWindow = g_ui.createWidget("SwapSetNamesWindow", parent)
  if not swapNamesWindow then
    swapNamesWindow = setupUI([[
MainWindow
  text: Lista de nomes
  size: 330 320
  visible: false

  Panel
    id: header
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    margin-top: 6
    margin-left: 8
    margin-right: 8
    height: 36

    Label
      id: titleLabel
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: 16
      text: Configurar nomes
      color: #dbe8f5
      font: verdana-11px-rounded
      text-align: left

    Label
      id: hintLabel
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: titleLabel.bottom
      margin-top: 1
      height: 14
      text: Um nome por linha
      color: #9aa6b2
      font: verdana-11px-rounded
      text-align: left

  Panel
    id: controls
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: header.bottom
    margin-top: 3
    margin-left: 8
    margin-right: 8
    height: 20

    Button
      id: addButton
      anchors.right: parent.right
      anchors.top: parent.top
      width: 56
      height: 18
      text: Adicionar
      font: verdana-11px-rounded

    TextEdit
      id: nameInput
      anchors.left: parent.left
      anchors.right: addButton.left
      anchors.top: parent.top
      margin-right: 4
      height: 18
      font: verdana-11px-rounded
      placeholder: Nome

  Panel
    id: listPanel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: controls.bottom
    anchors.bottom: footer.top
    margin-top: 4
    margin-left: 8
    margin-right: 8
    margin-bottom: 4
    background-color: #4e4e4e
    border-width: 1
    border-color: #676d75
    padding-left: 3
    padding-right: 3
    padding-top: 2
    padding-bottom: 2

    VerticalScrollBar
      id: listScroll
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      step: 14
      pixels-scroll: false

    ScrollablePanel
      id: list
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: listScroll.left
      anchors.bottom: parent.bottom
      margin-right: 5
      background-color: #4e4e4e
      border-width: 1
      border-color: #707985
      padding-left: 2
      padding-right: 2
      padding-top: 2
      padding-bottom: 2
      vertical-scrollbar: listScroll
      layout:
        type: verticalBox
        spacing: 2

  Panel
    id: footer
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-left: 8
    margin-right: 8
    margin-bottom: 6
    height: 22

    Button
      id: clearButton
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: 74
      height: 18
      text: Limpar
      font: verdana-11px-rounded

    Button
      id: closeButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: 74
      height: 18
      text: Fechar
      font: verdana-11px-rounded

    Label
      id: countLabel
      anchors.left: clearButton.right
      anchors.right: closeButton.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 6
      margin-right: 6
      height: 14
      text: 0 nome(s)
      color: #dbe8f5
      font: verdana-11px-rounded
      text-align: center
]], parent)
  end

  if swapNamesWindow and not isSwapNamesWindowReady() then
    if swapNamesWindow.destroy then
      swapNamesWindow:destroy()
    end
    swapNamesWindow = nil
  end

  if not swapNamesWindow then
    return false
  end

  if swapNamesWindow.hide then
    swapNamesWindow:hide()
  end
  bindSwapNamesWindowHandlers()
  return true
end

refreshSwapNamesWindow = function()
  if not ensureSwapNamesWindow() then
    return
  end

  local listPanel = getSwapNamesWindowWidget("list")
  local countLabel = getSwapNamesWindowWidget("countLabel")
  if not listPanel then
    return
  end

  local setKey = swapNamesListContext.setKey
  local listKey = swapNamesListContext.listKey
  if not setKey or not listKey then
    return
  end

  local list = getSwapScenarioNameList(setKey, listKey)
  listPanel:destroyChildren()

  for index, name in ipairs(list) do
    local row = setupUI([[
Panel
  height: 18

  Label
    id: nameLabel
    anchors.left: parent.left
    anchors.right: removeButton.left
    anchors.top: parent.top
    margin-right: 3
    height: 16
    color: #dbe8f5
    font: verdana-11px-rounded
    text-align: left

  Button
    id: removeButton
    anchors.right: parent.right
    anchors.top: parent.top
    width: 20
    height: 16
    text: X
    font: verdana-11px-rounded
]], listPanel)

    row.nameLabel:setText(tostring(name))
    row.removeButton:setTooltip("PT: Remove este nome da lista.\nEN: Remove this name from the list.")
    row.removeButton.onClick = function()
      if removeNameFromSwapScenario(setKey, listKey, index) then
        refreshSwapNamesWindow()
        refreshScenarioRows(setKey)
      end
    end
  end

  if countLabel then
    countLabel:setText(string.format("%d nome(s)", #list))
  end
end

function openSwapNamesWindow(setKey, listKey, titleText, hintText)
  if not ensureSwapNamesWindow() then
    swapMessage("[SwapSet] Janela de nomes nao disponivel.", "#ff8080")
    return
  end

  swapNamesListContext.setKey = setKey
  swapNamesListContext.listKey = listKey
  swapNamesListContext.title = titleText or "Lista de nomes"

  local titleLabel = getSwapNamesWindowWidget("titleLabel")
  local hintLabel = getSwapNamesWindowWidget("hintLabel")
  local nameInput = getSwapNamesWindowWidget("nameInput")

  if titleLabel then
    titleLabel:setText(string.format("%s | %s", tostring(setKey), swapNamesListContext.title))
  end
  if hintLabel then
    hintLabel:setText(tostring(hintText or "Digite nomes separados por virgula, ';' ou quebra de linha."))
  end
  if nameInput and nameInput.setText then
    nameInput:setText("")
  end

  refreshSwapNamesWindow()
  refreshScenarioRows(setKey)
  swapNamesWindow:show()
  swapNamesWindow:raise()
  swapNamesWindow:focus()
end

local swapNamesEditorStyleLoaded = false
function ensureSwapNamesEditorStyle()
  if swapNamesEditorStyleLoaded then
    return true
  end
  if not g_ui or not g_ui.loadUIFromString then
    return false
  end

  local ok = pcall(function()
    g_ui.loadUIFromString([[
SwapSetNamesEditorWindow < MainWindow
  text: Lista de nomes
  size: 420 230
  @onEscape: self:destroy()

  Label
    id: infoLabel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text-align: center
    margin-top: 8
    margin-left: 8
    margin-right: 8
    height: 30
    color: #dbe8f5
    font: verdana-11px-rounded

  TextEdit
    id: namesInput
    anchors.top: infoLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonsPanel.top
    margin-left: 8
    margin-right: 8
    margin-top: 4
    margin-bottom: 6
    font: verdana-11px-rounded

  Panel
    id: buttonsPanel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 30

    Button
      id: saveButton
      text: Salvar
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      width: 80
      height: 18
      margin-left: 8
      margin-bottom: 6
      font: verdana-11px-rounded

    Button
      id: cancelButton
      text: Cancelar
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      width: 80
      height: 18
      margin-right: 8
      margin-bottom: 6
      font: verdana-11px-rounded
]])
  end)

  swapNamesEditorStyleLoaded = ok and true or false
  return swapNamesEditorStyleLoaded
end

function buildSwapNamesListFromText(textValue)
  local list = {}
  local seen = {}
  for rawName in string.gmatch(tostring(textValue or ""), "[^\r\n,;]+") do
    local cleaned = normalizeSwapNameValue(rawName)
    local key = normalizeSwapNameKey(cleaned)
    if cleaned ~= "" and key ~= "" and not seen[key] then
      seen[key] = true
      table.insert(list, cleaned)
    end
  end
  table.sort(list, function(a, b)
    return normalizeSwapNameKey(a) < normalizeSwapNameKey(b)
  end)
  return list
end

function closeSwapNamesEditorWindow()
  if not swapNamesEditorWindow then
    return
  end
  if swapNamesEditorWindow.hide then
    pcall(function()
      swapNamesEditorWindow:hide()
    end)
  end
  if swapNamesEditorWindow.destroy then
    pcall(function()
      swapNamesEditorWindow:destroy()
    end)
  end
  swapNamesEditorWindow = nil
end

function openSwapNamesEditorWindow(setKey, listKey, titleText, hintText)
  local parent = rootWidget or (g_ui and g_ui.getRootWidget and g_ui.getRootWidget())
  if not parent then
    warn("[SwapSet] Falha ao abrir editor de nomes: rootWidget indisponivel.")
    swapMessage("[SwapSet] Janela de nomes nao disponivel.", "#ff8080")
    return
  end

  closeSwapNamesEditorWindow()

  local editorWindow
  if ensureSwapNamesEditorStyle() then
    editorWindow = g_ui.createWidget("SwapSetNamesEditorWindow", parent)
  end

  if not editorWindow then
    editorWindow = setupUI([[
MainWindow
  text: Lista de nomes
  size: 420 230
  @onEscape: self:destroy()

  Label
    id: infoLabel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text-align: center
    margin-top: 8
    margin-left: 8
    margin-right: 8
    height: 30
    color: #dbe8f5
    font: verdana-11px-rounded

  TextEdit
    id: namesInput
    anchors.top: infoLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonsPanel.top
    margin-left: 8
    margin-right: 8
    margin-top: 4
    margin-bottom: 6
    font: verdana-11px-rounded

  Panel
    id: buttonsPanel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 30

    Button
      id: saveButton
      text: Salvar
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      width: 80
      height: 18
      margin-left: 8
      margin-bottom: 6
      font: verdana-11px-rounded

    Button
      id: cancelButton
      text: Cancelar
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      width: 80
      height: 18
      margin-right: 8
      margin-bottom: 6
      font: verdana-11px-rounded
]], parent)
  end

  if not editorWindow then
    warn("[SwapSet] Falha ao criar janela de nomes do SwapSet.")
    swapMessage("[SwapSet] Janela de nomes nao disponivel.", "#ff8080")
    return
  end
  swapNamesEditorWindow = editorWindow

  local infoLabel = findSwapWidgetByIdRecursive(editorWindow, "infoLabel")
  local namesInput = findSwapWidgetByIdRecursive(editorWindow, "namesInput")
  local saveButton = findSwapWidgetByIdRecursive(editorWindow, "saveButton")
  local cancelButton = findSwapWidgetByIdRecursive(editorWindow, "cancelButton")

  local currentList = getSwapScenarioNameList(setKey, listKey)
  if editorWindow.setText then
    editorWindow:setText(titleText or "Lista de nomes")
  end
  if infoLabel and infoLabel.setText then
    infoLabel:setText(tostring(hintText or "Digite os nomes separados por virgula, ';' ou quebra de linha."))
  end
  if namesInput and namesInput.setText then
    namesInput:setText(table.concat(currentList, ", "))
  end

  if saveButton then
    saveButton:setTooltip("PT: Salva a lista de nomes para este set.\nEN: Save the names list for this set.")
    saveButton.onMousePress = nil
    saveButton.onClick = function()
      local typed = namesInput and namesInput.getText and namesInput:getText() or ""
      local scenarioData = getSwapScenarioData(setKey)
      scenarioData[listKey] = buildSwapNamesListFromText(typed)
      swapLastEquippedSet = nil
      local currentProfileId = getSelectedSwapProfileId()
      if currentProfileId and currentProfileId ~= "" then
        saveSwapProfileState(currentProfileId)
      end
      refreshScenarioRows(setKey)
      closeSwapNamesEditorWindow()
    end
  end

  if cancelButton then
    cancelButton:setTooltip("PT: Fecha sem salvar alteracoes.\nEN: Close without saving changes.")
    cancelButton.onMousePress = nil
    cancelButton.onClick = function()
      closeSwapNamesEditorWindow()
    end
  end

  editorWindow:show()
  editorWindow:raise()
  editorWindow:focus()
  if namesInput and namesInput.focus then
    namesInput:focus()
  end
end

-- handlers da janela de nomes sao definidos em bindSwapNamesWindowHandlers()

local swapProfileLabel = g_ui.createWidget("BotLabel", swapContent)
swapProfileLabel:setText("Perfis SwapSet")
swapProfileLabel:setColor("#E8E8E8")
if swapProfileLabel.setMarginLeft then
  swapProfileLabel:setMarginLeft(1)
end
swapProfileLabel:setTooltip("PT: Gerencie perfis completos do SwapSet.\nEN: Manage full SwapSet profiles.")

local swapEnableRow = setupUI([[
Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 6
  fit-children: true

  SmallBotSwitch
    id: enableSwitch
    width: 34
    height: 18
    text-align: center
    text: ON

  Label
    id: enableLabel
    width: 150
    height: 18
    text: Auto SwapSet
    color: #dbe8f5
    text-align: left
    font: verdana-11px-rounded
]], swapContent)

swapEnableSwitch = swapEnableRow.enableSwitch
if swapEnableSwitch then
  swapEnableSwitch:setTooltip("PT: Liga/desliga a troca automatica.\nEN: Enable/disable automatic swapping.")
  swapEnableSwitch.onClick = function(widget)
    local enabled = not widget:isOn()
    swapSettings.autoSwapEnabled = enabled
    widget:setOn(enabled)
    if enabled then
      swapLastEquippedSet = nil
    end
    refreshSwapUi()
  end
end

swapProfileRow = setupUI([[
Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 3
  fit-children: true

  ComboBox
    id: profilesCombo
    width: 120
    height: 18
    margin: 0
    font: verdana-11px-rounded

  TextEdit
    id: nameInput
    height: 18
    width: 78
    placeholder: Nome
    font: verdana-11px-rounded

  Button
    id: newBtn
    width: 40
    height: 18
    text: New
    font: verdana-11px-rounded

  Button
    id: deleteBtn
    width: 48
    height: 18
    text: Delete
    font: verdana-11px-rounded

  Button
    id: saveBtn
    width: 40
    height: 18
    text: Save
    font: verdana-11px-rounded
]], swapContent)

swapProfileRow.nameInput:setTooltip("PT: Digite o nome do novo perfil.\nEN: Enter the new profile name.")
swapProfileRow.newBtn:setTooltip("PT: Cria perfil a partir da configuracao atual.\nEN: Create profile from current setup.")
swapProfileRow.deleteBtn:setTooltip("PT: Remove o perfil selecionado.\nEN: Remove selected profile.")
swapProfileRow.saveBtn:setTooltip("PT: Salva a configuracao atual no perfil.\nEN: Save current setup into profile.")

swapConfigRow = setupUI([[
Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 3
  fit-children: true

  Label
    id: rangeLabel
    width: 150
    height: 18
    text: Raio de Verificacao:
    color: #dbe8f5
    text-align: left
    font: verdana-11px-rounded

  TextEdit
    id: rangeEdit
    width: 44
    height: 18
    text: 8
    font: verdana-11px-rounded
    text-align: center

  Label
    id: saveHintLabel
    width: 102
    height: 18
    text: Save no perfil
    color: #9aa6b2
    text-align: left
    font: verdana-11px-rounded
]], swapContent)

swapConfigRow.rangeLabel:setTooltip("PT: Raio usado para leitura dos filtros de tela.\nEN: Radius used to evaluate on-screen filters.")
swapConfigRow.rangeEdit:setTooltip("PT: Valor entre 1 e 15.\nEN: Value between 1 and 15.")
swapConfigRow.saveHintLabel:setTooltip("PT: O valor e salvo quando voce clicar em Save.\nEN: Value is stored when you click Save.")

swapPriorityRow = setupUI([[
Panel
  height: 20

  Button
    id: prioritySetButton
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: 18
    text: Prioridade do Set: SET1
    font: verdana-11px-rounded
]], swapContent)

swapPriorityButton = swapPriorityRow.prioritySetButton
if swapPriorityButton then
  swapPriorityButton:setTooltip("PT: Define o set fallback quando nenhum filtro bater.\nEN: Select fallback set when no filters match.")
end

swapHelpLabel = g_ui.createWidget("BotLabel", swapContent)
swapHelpLabel:setText("Marque os filtros de cada set (linhas abaixo).")
swapHelpLabel:setColor("#9aa6b2")
swapHelpLabel:setTooltip("PT: Ative apenas os filtros que deseja aplicar em cada set.\nEN: Enable only the filters you want to apply for each set.")

swapSetsRow = setupUI([[
Panel
  height: 320

  Panel
    id: leftHolder
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    margin-right: 4

  Panel
    id: rightHolder
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    margin-left: 4

  VerticalSeparator
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.horizontalCenter
]], swapContent)

swapSetPanels.SET1 = g_ui.createWidget("SwapSetEqPanel", swapSetsRow.leftHolder)
swapSetPanels.SET2 = g_ui.createWidget("SwapSetEqPanel", swapSetsRow.rightHolder)
if swapSetPanels.SET1 and swapSetPanels.SET1.title then
  swapSetPanels.SET1.title:setText("SET1")
end
if swapSetPanels.SET2 and swapSetPanels.SET2.title then
  swapSetPanels.SET2.title:setText("SET2")
end

function buildEqRowsForSet(setKey)
  local panel = swapSetPanels[setKey]
  if not panel then
    return
  end

  swapSettings[setKey] = type(swapSettings[setKey]) == "table" and swapSettings[setKey] or {}
  local setData = swapSettings[setKey]
  local function scenarioWidget(childId)
    return getSwapScenarioWidget(panel, childId)
  end

  local function getScenarioData()
    swapSettings.scenarios = type(swapSettings.scenarios) == "table" and swapSettings.scenarios or {}
    swapSettings.scenarios[setKey] = type(swapSettings.scenarios[setKey]) == "table" and swapSettings.scenarios[setKey] or {}
    local scenarioData = swapSettings.scenarios[setKey]
    scenarioData.enemyNames = normalizeSwapNameList(scenarioData.enemyNames or {})
    scenarioData.monsterNames = normalizeSwapNameList(scenarioData.monsterNames or {})
    return scenarioData
  end

  for _, part in ipairs(swapParts) do
    local slotWidget = panel[part.id] or findSwapWidgetByIdRecursive(panel, part.id)
    if slotWidget then
      slotWidget:setItemId(clamp(tonumber(setData[part.id]) or 0, 0, 50000))
      if slotWidget.setOn then
        slotWidget:setOn((tonumber(setData[part.id]) or 0) > 0)
      end

      slotWidget.onItemChange = function(widget)
        local itemId = clamp(tonumber(widget:getItemId()) or 0, 0, 50000)
        if itemId < 100 then
          itemId = 0
        end
        swapSettings[setKey] = type(swapSettings[setKey]) == "table" and swapSettings[setKey] or {}
        swapSettings[setKey][part.id] = itemId
        if widget.setOn then
          widget:setOn(itemId > 0)
        end
        swapLastEquippedSet = nil
      end

      swapEqRows[setKey][part.id] = slotWidget
    end
  end

  if panel.cloneButton then
    panel.cloneButton.onClick = function()
      copyCurrentEquipmentToSet(setKey)
      refreshEqRows(setKey)
      swapMessage(string.format("[SwapSet] Equipamento clonado para %s.", setKey), "#00FF7F")
    end
  end

  local function bindScenarioCheck(widget, key, tooltipText)
    if not widget then
      return
    end
    if widget.setTooltip and tooltipText then
      widget:setTooltip(tooltipText)
    end
    widget.onClick = function(checkWidget)
      local scenarioData = getScenarioData()
      scenarioData[key] = not (scenarioData[key] == true)
      checkWidget:setChecked(scenarioData[key] == true)
      swapLastEquippedSet = nil
    end
  end

  local function bindScenarioLimit(widget, key, minLimit, maxLimit, tooltipText)
    if not widget then
      return
    end
    if widget.setTooltip and tooltipText then
      widget:setTooltip(tooltipText)
    end
    widget.onValueChange = function(_, value)
      local numeric = tonumber(value) or minLimit
      local scenarioData = getScenarioData()
      scenarioData[key] = clamp(math.floor(numeric), minLimit, maxLimit)
      swapLastEquippedSet = nil
    end
  end

  local function bindScenarioMinimum(widget, key, minLimit, maxLimit, tooltipText)
    if not widget then
      return
    end
    if widget.setTooltip and tooltipText then
      widget:setTooltip(tooltipText)
    end
    widget.onValueChange = function(_, value)
      local numeric = tonumber(value) or minLimit
      local scenarioData = getScenarioData()
      scenarioData[key] = clamp(math.floor(numeric), minLimit, maxLimit)
      swapLastEquippedSet = nil
    end
  end

  local function bindScenarioNamesButton(buttonWidget, listKey, titleText, hintText, tooltipText)
    if not buttonWidget then
      return
    end
    local function openEditor()
      openSwapNamesEditorWindow(setKey, listKey, titleText, hintText)
    end
    if buttonWidget.setTooltip and tooltipText then
      buttonWidget:setTooltip(tooltipText)
    end
    buttonWidget.onClick = openEditor
    buttonWidget.onMousePress = nil
  end

  bindScenarioCheck(scenarioWidget("playersRangeCheck"), "playersRangeEnabled", "PT: Ativa filtro de Player na tela (ignora guild/party). Qtd=0 exige tela limpa; Qtd>0 exige no minimo esse valor.\nEN: Enable player-on-screen filter (guild/party ignored). Qty=0 requires clear screen; Qty>0 requires at least this value.")
  bindScenarioCheck(scenarioWidget("pkRangeCheck"), "pkRangeEnabled", "PT: Ativa filtro de PK na tela (ignora guild/party). Qtd=0 exige sem PK; Qtd>0 exige no minimo esse valor.\nEN: Enable PK-on-screen filter (guild/party ignored). Qty=0 requires no PK; Qty>0 requires at least this value.")
  bindScenarioCheck(scenarioWidget("targetOnCheck"), "targetEnabled", "PT: Exige target ativo.\nEN: Require active target.")
  bindScenarioCheck(scenarioWidget("targetHpCheck"), "targetHpEnabled", "PT: Exige HP do target <= valor configurado.\nEN: Require target HP <= configured value.")
  bindScenarioCheck(scenarioWidget("hasEnemyCheck"), "hasEnemy", "PT: Exige ao menos 1 Enemy na tela (ignora party/guild).\nEN: Require at least 1 Enemy on screen (party/guild ignored).")
  bindScenarioCheck(scenarioWidget("hpCheck"), "hpEnabled", "PT: Exige HP <= valor configurado.\nEN: Require HP <= configured value.")
  bindScenarioCheck(scenarioWidget("manaCheck"), "manaEnabled", "PT: Exige Mana <= valor configurado.\nEN: Require Mana <= configured value.")
  bindScenarioCheck(scenarioWidget("hasMonsterCheck"), "hasMonster", "PT: Ativa filtro de Monstros na tela usando a quantidade ao lado.\nEN: Enable monsters-on-screen filter using the amount on the side.")

  bindScenarioMinimum(scenarioWidget("playersMin"), "playersMin", 0, 200, "PT: Quantidade de players para este filtro (0 = sem players).\nEN: Players amount for this filter (0 = no players).")
  bindScenarioMinimum(scenarioWidget("pkMin"), "pkMin", 0, 200, "PT: Quantidade de PKs para este filtro (0 = sem PK).\nEN: PK amount for this filter (0 = no PK).")
  bindScenarioMinimum(scenarioWidget("monsterMin"), "monsterMin", 1, 200, "PT: Quantidade de monstros para este filtro.\nEN: Monsters amount for this filter.")
  bindScenarioLimit(scenarioWidget("targetHpLimit"), "targetHpBelow", 0, 100, "PT: Dispara quando HP do target estiver menor ou igual a este valor.\nEN: Trigger when target HP is lower than or equal to this value.")
  bindScenarioLimit(scenarioWidget("hpLimit"), "hpBelow", 0, 100, "PT: Dispara quando HP estiver menor ou igual a este valor.\nEN: Trigger when HP is lower than or equal to this value.")
  bindScenarioLimit(scenarioWidget("manaLimit"), "manaBelow", 0, 100, "PT: Dispara quando Mana estiver menor ou igual a este valor.\nEN: Trigger when Mana is lower than or equal to this value.")
  bindScenarioNamesButton(
    scenarioWidget("enemyNamesButton"),
    "enemyNames",
    "Nomes de Enemy",
    "Digite os nomes de Enemy para este set (separados por virgula, ';' ou quebra de linha).",
    "PT: Cadastra nomes de Enemy para filtrar este set.\nEN: Register Enemy names to filter this set."
  )
  bindScenarioNamesButton(
    scenarioWidget("monsterNamesButton"),
    "monsterNames",
    "Nomes de Monstro",
    "Digite os nomes de monstro para este set (separados por virgula, ';' ou quebra de linha).",
    "PT: Cadastra nomes de monstro para filtrar este set.\nEN: Register monster names to filter this set."
  )
  local enemyNamesCount = scenarioWidget("enemyNamesCount")
  if enemyNamesCount and enemyNamesCount.setTooltip then
    enemyNamesCount:setTooltip("PT: Quantidade de nomes cadastrados para Enemy.\nEN: Number of registered Enemy names.")
  end
  local monsterNamesCount = scenarioWidget("monsterNamesCount")
  if monsterNamesCount and monsterNamesCount.setTooltip then
    monsterNamesCount:setTooltip("PT: Quantidade de nomes cadastrados para monstro.\nEN: Number of registered monster names.")
  end
end

buildEqRowsForSet("SET1")
buildEqRowsForSet("SET2")

function renderSwapProfileList()
  local profiles = ensureSwapProfiles()
  local combo = swapProfileRow.profilesCombo
  combo:clearOptions()

  local selectedIndex = 1
  local activeId = getSelectedSwapProfileId()
  for index, id in ipairs(profiles.order) do
    local entry = profiles.configs[id]
    combo:addOption((entry and entry.name) or id, id)
    if id == activeId then
      selectedIndex = index
    end
  end

  combo:setCurrentIndex(selectedIndex, true)
  combo.onOptionChange = function(widget)
    local option = widget:getCurrentOption()
    if not option then
      return
    end

    local previousId = getSelectedSwapProfileId()
    if previousId ~= option.data then
      saveSwapProfileState(previousId)
    end

    setSwapActiveProfile(profiles, option.data)
    applySwapProfileState(option.data)
    refreshSwapUi()
  end
end

swapProfileRow.newBtn.onClick = function()
  local currentId = getSelectedSwapProfileId()
  saveSwapProfileState(currentId)

  local id = addSwapProfile(swapProfileRow.nameInput:getText())
  if not id then
    warn("[SwapSet] Nome de perfil invalido.")
    return
  end

  swapProfileRow.nameInput:setText("")
  applySwapProfileState(id)
  renderSwapProfileList()
  refreshSwapUi()
  swapMessage("Perfil criado: " .. getSwapProfileName(id), "#00FF00")
end

swapProfileRow.deleteBtn.onClick = function()
  local currentId = getSelectedSwapProfileId()
  if not currentId or currentId == "" then
    return
  end

  local profiles = ensureSwapProfiles()
  for i = #profiles.order, 1, -1 do
    if profiles.order[i] == currentId then
      table.remove(profiles.order, i)
      break
    end
  end
  profiles.configs[currentId] = nil

  if #profiles.order == 0 then
    local defaultId = "cfg_1"
    profiles.configs[defaultId] = profiles.configs[defaultId] or {
      name = "Config 1",
      data = captureSwapProfileState()
    }
    table.insert(profiles.order, defaultId)
    if profiles.nextId < 2 then
      profiles.nextId = 2
    end
  end

  local nextId = setSwapActiveProfile(profiles, profiles.meta.activeProfile)
  applySwapProfileState(nextId)
  renderSwapProfileList()
  refreshSwapUi()
  swapMessage("Perfil removido.", "#FF4040")
end

swapProfileRow.saveBtn.onClick = function()
  local currentId = getSelectedSwapProfileId()
  if not currentId or currentId == "" then
    return
  end
  saveSwapProfileState(currentId)
  swapMessage("Perfil salvo: " .. getSwapProfileName(currentId), "#00FF00")
end

swapConfigRow.rangeEdit.onTextChange = function(_, text)
  local numeric = tonumber(text)
  if not numeric then
    return
  end
  local clampedValue = clamp(math.floor(numeric), 1, 15)
  if clampedValue ~= swapSettings.safeRange then
    swapSettings.safeRange = clampedValue
    swapLastEquippedSet = nil
  end
end

swapConfigRow.rangeEdit.onFocusChange = function(widget, focused)
  if not focused then
    widget:setText(tostring(swapSettings.safeRange))
  end
end

if swapPriorityButton then
  swapPriorityButton.onClick = function()
    togglePrioritySet()
    refreshSwapUi()
  end
end

swapSetupWindow.footer.closeButton.onClick = function()
  swapSetupWindow:hide()
  if swapNamesWindow and swapNamesWindow.hide then
    swapNamesWindow:hide()
  end
  closeSwapNamesEditorWindow()
end

if swapSetupWindow.footer and swapSetupWindow.footer.helpButton then
  if swapSetupWindow.footer.helpButton.setTooltip then
    swapSetupWindow.footer.helpButton:setTooltip("PT: Abre tutorial rapido do SwapSet.\nEN: Open quick SwapSet tutorial.")
  end
  swapSetupWindow.footer.helpButton.onClick = function()
    openTutorialWindow("Tutorial - SwapSet", buildSwapSetTutorialText())
  end
end

swapMainUi = UI.Button("SwapSet", function()
  renderSwapProfileList()
  refreshSwapUi()
  if swapNamesWindow and swapNamesWindow.hide then
    swapNamesWindow:hide()
  end
  closeSwapNamesEditorWindow()
  swapSetupWindow:show()
  swapSetupWindow:raise()
  swapSetupWindow:focus()
end)
if swapMainUi and swapMainUi.setFont then
  swapMainUi:setFont("verdana-11px-rounded")
end
if swapMainUi and swapMainUi.setTooltip then
  swapMainUi:setTooltip("PT: Abre o setup do SwapSet.\nEN: Open SwapSet setup.")
end

normalizeSwapSetConfig()
if painelProfileLoaded() then
  initialProfileId = getSelectedSwapProfileId()
  initialProfiles = ensureSwapProfiles()
  if initialProfileId ~= "" and type(initialProfiles.configs[initialProfileId]) == "table" and type(initialProfiles.configs[initialProfileId].data) == "table" then
    applySwapProfileState(initialProfileId)
  else
    saveSwapProfileState(initialProfileId)
  end
end
renderSwapProfileList()
refreshSwapUi()
if painelProfileLoaded() then
  swapMessage("ElfBot: Auto SwapSet loaded.", "#9dd1ff")
end

function consumePainelSwapSetBridge()
  local bridge = storage and storage.painelDeIconesBridge
  if type(bridge) ~= "table" or bridge.swapSetDesired == nil then
    return
  end

  local desired = bridge.swapSetDesired == true
  bridge.swapSetDesired = nil

  if swapSettings.autoSwapEnabled == desired then
    refreshSwapUi()
    return
  end

  swapSettings.autoSwapEnabled = desired
  if desired then
    swapLastEquippedSet = nil
  end
  refreshSwapUi()
end

if painelProfileLoaded() then
  consumePainelSwapSetBridge()
end
swapBridgeSyncMacro = macro(250, function()
  if not painelProfileLoaded() then
    return
  end
  consumePainelSwapSetBridge()
end)

swapAutoRuntime = {
  lastEvalAt = 0,
  nextEquipTryAt = 0
}

swapAutoMacro = macro(500, function()
  if not painelProfileLoaded() then
    return
  end
  if swapSettings.autoSwapEnabled ~= true then
    return
  end
  if g_game and g_game.isOnline and not g_game.isOnline() then
    return
  end

  local nowTime = nowMs()
  if (nowTime - (swapAutoRuntime.lastEvalAt or 0)) < 650 then
    return
  end
  swapAutoRuntime.lastEvalAt = nowTime

  local targetSetName = resolveSwapScenarioSet()

  if targetSetName == swapLastEquippedSet then
    return
  end

  if nowTime < (swapAutoRuntime.nextEquipTryAt or 0) then
    return
  end

  local targetSet = swapSettings[targetSetName]
  if equipSet(targetSet) then
    swapLastEquippedSet = targetSetName
    swapAutoRuntime.nextEquipTryAt = nowTime + 900
    refreshSwapUi()
  else
    swapAutoRuntime.nextEquipTryAt = nowTime + 1300
  end
end)

SwapSetController = {
  settings = swapSettings,
  setupWindow = swapSetupWindow,
  mainUi = swapMainUi,
  macro = swapAutoMacro,
  setOn = function(...)
    local desired = true
    local args = {...}
    if type(args[1]) == "boolean" then
      desired = args[1]
    elseif type(args[2]) == "boolean" then
      desired = args[2]
    end
    swapSettings.autoSwapEnabled = desired
    if desired then
      swapLastEquippedSet = nil
    end
    refreshSwapUi()
    return true
  end,
  setOff = function(...)
    swapSettings.autoSwapEnabled = false
    refreshSwapUi()
    return true
  end,
  isOn = function(...)
    return swapSettings.autoSwapEnabled == true
  end,
  refresh = function(...)
    refreshSwapUi()
    return true
  end,
  shutdown = function()
    closeTutorialWindow()
    if swapAutoMacro and swapAutoMacro.setOff then
      swapAutoMacro.setOff()
    end
    if swapBridgeSyncMacro and swapBridgeSyncMacro.setOff then
      swapBridgeSyncMacro.setOff()
    end
    if swapSetupWindow and swapSetupWindow.destroy then
      swapSetupWindow:destroy()
    end
    if swapNamesWindow and swapNamesWindow.destroy then
      swapNamesWindow:destroy()
    end
    closeSwapNamesEditorWindow()
    if swapMainUi and swapMainUi.destroy then
      swapMainUi:destroy()
    end
  end
}
