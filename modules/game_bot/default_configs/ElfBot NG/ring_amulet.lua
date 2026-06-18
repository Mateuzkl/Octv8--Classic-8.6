-- ============================================
-- SOULEWORKER3.LUA - SISTEMA DE RING/AMULET AVANCADO
-- Documentacao completa: docs/items/README_RING_AMULET_ADVANCED.md
-- ============================================

setDefaultTab("Main")

local isRingModuleEnabled
local isAmuletModuleEnabled
local getSelectedRingProfileId
local getRingProfileName

do

local function cloneTable(value)
  if type(value) ~= "table" then
    return value
  end

  local copy = {}
  for key, entry in pairs(value) do
    copy[key] = cloneTable(entry)
  end
  return copy
end

local function applyTableData(target, source)
  if type(target) ~= "table" then
    return
  end
  for key in pairs(target) do
    target[key] = nil
  end
  for key, value in pairs(source or {}) do
    target[key] = cloneTable(value)
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

-- ============================================
-- INICIALIZACAO DE STORAGE
-- ============================================

if type(storage.ringAmuletSetup) ~= "table" then
  storage.ringAmuletSetup = {
    enabled = false,
    rings = {},
    amulets = {},
    swapDelay = 1000,  -- Delay padrão entre trocas (ms)
    priority = {
      playerDetect = {
        enabled = false,
        ring = 0,
        ringEquipped = 0,
        amulet = 0,
        amuletEquipped = 0,
        minPlayers = 1
      },
      pkDetect = {
        enabled = false,
        ring = 0,
        ringEquipped = 0,
        amulet = 0,
        amuletEquipped = 0,
        minPks = 1
      },
      monsterDetect = {
        enabled = false,
        ring = 0,
        ringEquipped = 0,
        amulet = 0,
        amuletEquipped = 0,
        monsterList = {},
        minMonsters = 1
      },
      enemyDetect = {
        enabled = false,
        ring = 0,
        ringEquipped = 0,
        amulet = 0,
        amuletEquipped = 0,
        enemyList = {},
        includeEnemyGuild = false
      }
    }
  }
end

-- Garantir que swapDelay exista (compatibilidade com storage antigo)
if storage.ringAmuletSetup.swapDelay == nil then
  storage.ringAmuletSetup.swapDelay = 1000
end

-- Garantir que priority exista (compatibilidade com storage antigo)
if type(storage.ringAmuletSetup.priority) ~= "table" then
  storage.ringAmuletSetup.priority = {
    playerDetect = {enabled = false, ring = 0, ringEquipped = 0, amulet = 0, amuletEquipped = 0, minPlayers = 1},
    pkDetect = {enabled = false, ring = 0, ringEquipped = 0, amulet = 0, amuletEquipped = 0, minPks = 1},
    monsterDetect = {enabled = false, ring = 0, ringEquipped = 0, amulet = 0, amuletEquipped = 0, monsterList = {}, minMonsters = 1},
    enemyDetect = {enabled = false, ring = 0, ringEquipped = 0, amulet = 0, amuletEquipped = 0, enemyList = {}, includeEnemyGuild = false}
  }
end

-- Garantir que os IDs equipados existam em prioridades antigas
if type(storage.ringAmuletSetup.priority.enemyDetect) == "table" and storage.ringAmuletSetup.priority.enemyDetect.ringEquipped == nil then
  storage.ringAmuletSetup.priority.enemyDetect.ringEquipped = 0
  storage.ringAmuletSetup.priority.enemyDetect.amuletEquipped = 0
end
if type(storage.ringAmuletSetup.priority.pkDetect) == "table" and storage.ringAmuletSetup.priority.pkDetect.ringEquipped == nil then
  storage.ringAmuletSetup.priority.pkDetect.ringEquipped = 0
  storage.ringAmuletSetup.priority.pkDetect.amuletEquipped = 0
end
if type(storage.ringAmuletSetup.priority.monsterDetect) == "table" and storage.ringAmuletSetup.priority.monsterDetect.ringEquipped == nil then
  storage.ringAmuletSetup.priority.monsterDetect.ringEquipped = 0
  storage.ringAmuletSetup.priority.monsterDetect.amuletEquipped = 0
end
if type(storage.ringAmuletSetup.priority.playerDetect) == "table" and storage.ringAmuletSetup.priority.playerDetect.ringEquipped == nil then
  storage.ringAmuletSetup.priority.playerDetect.ringEquipped = 0
  storage.ringAmuletSetup.priority.playerDetect.amuletEquipped = 0
end

-- Garantir que whiteList exista
if type(storage.ringAmuletSetup.priority.whiteList) ~= "table" then
  storage.ringAmuletSetup.priority.whiteList = {}
end

-- Garantir que amulets exista (compatibilidade com storage antigo)
if type(storage.ringAmuletSetup.amulets) ~= "table" then
  storage.ringAmuletSetup.amulets = {}
end

-- Garantir que rings exista
if type(storage.ringAmuletSetup.rings) ~= "table" then
  storage.ringAmuletSetup.rings = {}
end

-- Inicializar configurações dos 5 slots de rings
for i = 1, 5 do
  if type(storage.ringAmuletSetup.rings[i]) ~= "table" then
    storage.ringAmuletSetup.rings[i] = {
      itemId = 0,
      itemIdEquipped = 0,
      hpMin = 0,
      hpMax = 100,
      mpMin = 0,
      mpMax = 100
    }
  end
  -- Garantir que mpMin e mpMax existam em slots existentes
  if storage.ringAmuletSetup.rings[i].mpMin == nil then
    storage.ringAmuletSetup.rings[i].mpMin = 0
  end
  if storage.ringAmuletSetup.rings[i].mpMax == nil then
    storage.ringAmuletSetup.rings[i].mpMax = 100
  end
  -- Garantir que itemIdEquipped exista (para compatibilidade com slots antigos)
  if storage.ringAmuletSetup.rings[i].itemIdEquipped == nil then
    storage.ringAmuletSetup.rings[i].itemIdEquipped = 0
  end
end

-- Inicializar configurações dos 5 slots de amulets
for i = 1, 5 do
  if type(storage.ringAmuletSetup.amulets[i]) ~= "table" then
    storage.ringAmuletSetup.amulets[i] = {
      itemId = 0,
      itemIdEquipped = 0,
      hpMin = 0,
      hpMax = 100,
      mpMin = 0,
      mpMax = 100
    }
  end
  -- Garantir que mpMin e mpMax existam em slots existentes
  if storage.ringAmuletSetup.amulets[i].mpMin == nil then
    storage.ringAmuletSetup.amulets[i].mpMin = 0
  end
  if storage.ringAmuletSetup.amulets[i].mpMax == nil then
    storage.ringAmuletSetup.amulets[i].mpMax = 100
  end
  -- Garantir que itemIdEquipped exista
  if storage.ringAmuletSetup.amulets[i].itemIdEquipped == nil then
    storage.ringAmuletSetup.amulets[i].itemIdEquipped = 0
  end
end

local config = storage.ringAmuletSetup

if config.ringsEnabled == nil then
  config.ringsEnabled = normalizeBoolFlag(config.enabled, false)
end
if config.amuletsEnabled == nil then
  config.amuletsEnabled = normalizeBoolFlag(config.enabled, false)
end
config.ringsEnabled = normalizeBoolFlag(config.ringsEnabled, false)
config.amuletsEnabled = normalizeBoolFlag(config.amuletsEnabled, false)
config.enabled = normalizeBoolFlag(config.enabled, config.ringsEnabled or config.amuletsEnabled)

function isRingModuleEnabled()
  return normalizeBoolFlag(config.ringsEnabled, false)
end

function isAmuletModuleEnabled()
  return normalizeBoolFlag(config.amuletsEnabled, false)
end

local function syncSystemEnabled()
  config.ringsEnabled = isRingModuleEnabled()
  config.amuletsEnabled = isAmuletModuleEnabled()
  config.enabled = config.ringsEnabled or config.amuletsEnabled
end
syncSystemEnabled()

local UNIVERSAL_BP_SLOT_COUNT = 3

local function buildDefaultUniversalBpConfigs()
  return {
    { name = "Backpack 1", id = 0, autoOpen = true, keepSlotFree = false, targetItem = 0 },
    { name = "Backpack 2", id = 0, autoOpen = true, keepSlotFree = false, targetItem = 0 },
    { name = "Backpack 3", id = 0, autoOpen = true, keepSlotFree = false, targetItem = 0 }
  }
end

if type(storage.UniversalBPManager) ~= "table" then
  storage.UniversalBPManager = {
    enabled = false,
    bpConfigs = buildDefaultUniversalBpConfigs()
  }
end

local universalBpConfig = storage.UniversalBPManager

local function normalizeUniversalBpConfig()
  if type(universalBpConfig) ~= "table" then
    storage.UniversalBPManager = {
      enabled = false,
      bpConfigs = buildDefaultUniversalBpConfigs()
    }
    universalBpConfig = storage.UniversalBPManager
  end

  universalBpConfig.enabled = universalBpConfig.enabled == true

  local defaults = buildDefaultUniversalBpConfigs()
  local sourceConfigs = type(universalBpConfig.bpConfigs) == "table" and universalBpConfig.bpConfigs or {}
  local normalizedConfigs = {}
  for i = 1, UNIVERSAL_BP_SLOT_COUNT do
    local entry = sourceConfigs[i]
    if entry == nil then
      entry = sourceConfigs[tostring(i)]
    end
    if type(entry) ~= "table" then
      entry = {}
    end

    entry.name = tostring(entry.name or defaults[i].name)
    if entry.name == "" then
      entry.name = defaults[i].name
    end
    if entry.name == "Main BP" or entry.name == "Main Backpack" then
      entry.name = "Backpack 1"
    elseif entry.name == "Secondary BP" or entry.name == "Secondary Backpack" then
      entry.name = "Backpack 2"
    elseif entry.name == "Extra BP" or entry.name == "Extra Backpack" then
      entry.name = "Backpack 3"
    end
    entry.id = tonumber(entry.id or 0) or 0
    entry.autoOpen = entry.autoOpen ~= false
    entry.keepSlotFree = entry.keepSlotFree == true
    entry.targetItem = tonumber(entry.targetItem or 0) or 0

    normalizedConfigs[i] = entry
  end
  universalBpConfig.bpConfigs = normalizedConfigs
end

normalizeUniversalBpConfig()

local setupWindow = nil
local priorityWindow = nil
local backpacksWindow = nil
local backpacksHelpWindow = nil
local ringAmuletHelpWindow = nil
local openPriorityWindow
local openBackpacksWindow
local openBackpacksHelpWindow
local openRingAmuletHelpWindow
local createSetupWindow
local ringProfileRefreshPending = false
local ringHeaderToggleRef = nil
local amuletHeaderToggleRef = nil
local universalBpUi = nil
local universalBpState = { lastActionMs = 0 }

if souleUniversalBpsWindow and souleUniversalBpsWindow.destroy then
  souleUniversalBpsWindow:destroy()
  souleUniversalBpsWindow = nil
end

if souleBackpacksHelpWindow and souleBackpacksHelpWindow.destroy then
  souleBackpacksHelpWindow:destroy()
  souleBackpacksHelpWindow = nil
end

if souleRingAmuletHelpWindow and souleRingAmuletHelpWindow.destroy then
  souleRingAmuletHelpWindow:destroy()
  souleRingAmuletHelpWindow = nil
end

local function refreshRingAmuletHeaderToggles()
  local ringEnabled = isRingModuleEnabled()
  local amuletEnabled = isAmuletModuleEnabled()

  if ringHeaderToggleRef then
    ringHeaderToggleRef:setOn(ringEnabled)
    ringHeaderToggleRef:setText(ringEnabled and "ON" or "OFF")
  end

  if amuletHeaderToggleRef then
    amuletHeaderToggleRef:setOn(amuletEnabled)
    amuletHeaderToggleRef:setText(amuletEnabled and "ON" or "OFF")
  end
end

local function nowMsUniversal()
  if g_clock and type(g_clock.millis) == "function" then
    return g_clock.millis()
  end
  return os.time() * 1000
end

local function getAllContainersSafe()
  if type(getContainers) == "function" then
    local ok, containers = pcall(function()
      return getContainers()
    end)
    if ok and type(containers) == "table" then
      return containers
    end
  end

  if g_game and type(g_game.getContainers) == "function" then
    local ok, containers = pcall(function()
      return g_game.getContainers()
    end)
    if ok and type(containers) == "table" then
      return containers
    end
  end

  return {}
end

local function getContainerItemsSafe(container)
  if container and type(container.getItems) == "function" then
    local ok, items = pcall(function()
      return container:getItems()
    end)
    if ok and type(items) == "table" then
      return items
    end
  end
  return {}
end

local function getContainerItemsCountSafe(container)
  if container and type(container.getItemsCount) == "function" then
    local ok, count = pcall(function()
      return container:getItemsCount()
    end)
    if ok and type(count) == "number" then
      return count
    end
  end
  return #getContainerItemsSafe(container)
end

local function getContainerCapacitySafe(container)
  if container and type(container.getCapacity) == "function" then
    local ok, capacity = pcall(function()
      return container:getCapacity()
    end)
    if ok and type(capacity) == "number" then
      return capacity
    end
  end
  return 20
end

local function getContainerItemIdSafe(container)
  if not container or type(container.getContainerItem) ~= "function" then
    return 0
  end

  local ok, cItem = pcall(function()
    return container:getContainerItem()
  end)
  if not ok or not cItem or type(cItem.getId) ~= "function" then
    return 0
  end

  local okId, cId = pcall(function()
    return cItem:getId()
  end)
  if okId and type(cId) == "number" then
    return cId
  end
  return 0
end

local function isContainerItem(item)
  if not item then
    return false
  end
  if type(item.isContainer) ~= "function" then
    return false
  end
  local ok, result = pcall(function()
    return item:isContainer()
  end)
  return ok and result == true
end

local function hasOpenBpContainer(bpId)
  for _, container in pairs(getAllContainersSafe()) do
    if getContainerItemIdSafe(container) == bpId then
      return true
    end
  end
  return false
end

local function findOpenBpContainer(bpId, requireFreeSlot)
  local fallback = nil
  for _, container in pairs(getAllContainersSafe()) do
    if getContainerItemIdSafe(container) == bpId then
      fallback = fallback or container
      if not requireFreeSlot then
        return container
      end
      if getContainerItemsCountSafe(container) < getContainerCapacitySafe(container) then
        return container
      end
    end
  end
  return fallback
end

local function tryOpenContainerItem(item)
  if not item or not g_game or type(g_game.open) ~= "function" then
    return false
  end
  local ok = pcall(function()
    g_game.open(item, nil)
  end)
  return ok
end

local function tryOpenBackpackById(bpId)
  if bpId < 100 or hasOpenBpContainer(bpId) then
    return false
  end

  local item = nil
  if type(findItem) == "function" then
    local ok, found = pcall(function()
      return findItem(bpId)
    end)
    if ok and found then
      item = found
    end
  end

  if not item and g_game and type(g_game.findPlayerItem) == "function" then
    local ok, found = pcall(function()
      return g_game.findPlayerItem(bpId, -1)
    end)
    if ok and found then
      item = found
    end
  end

  if not isContainerItem(item) then
    return false
  end

  return tryOpenContainerItem(item)
end

local function tryOpenNextBackpack(slotCfg)
  local bpId = tonumber(slotCfg.id or 0) or 0
  if bpId < 100 then
    return false
  end

  for _, container in pairs(getAllContainersSafe()) do
    if getContainerItemIdSafe(container) == bpId then
      local items = getContainerItemsSafe(container)
      if #items == 1 then
        local nested = items[1]
        if nested and isContainerItem(nested) and nested:getId() == bpId then
          return tryOpenContainerItem(nested)
        end
      end
    end
  end

  return false
end

local function moveItemToContainerSafe(item, destination)
  if not item or not destination then
    return false
  end
  if not g_game or type(g_game.move) ~= "function" then
    return false
  end
  if type(destination.getSlotPosition) ~= "function" then
    return false
  end

  local destinationPos = destination:getSlotPosition(getContainerItemsCountSafe(destination))
  if not destinationPos then
    return false
  end

  local amount = 1
  if type(item.getCount) == "function" then
    amount = math.max(1, tonumber(item:getCount()) or 1)
  end

  local ok = pcall(function()
    g_game.move(item, destinationPos, amount)
  end)
  return ok
end

local function tryOrganizeItem(slotCfg)
  local bpId = tonumber(slotCfg.id or 0) or 0
  local targetItemId = tonumber(slotCfg.targetItem or 0) or 0
  if bpId < 100 or targetItemId < 100 then
    return false
  end

  local destination = findOpenBpContainer(bpId, true)
  if not destination then
    return false
  end

  for _, source in pairs(getAllContainersSafe()) do
    if source ~= destination and getContainerItemIdSafe(source) ~= bpId then
      for _, item in ipairs(getContainerItemsSafe(source)) do
        if item and item:getId() == targetItemId then
          return moveItemToContainerSafe(item, destination)
        end
      end
    end
  end

  return false
end

local function tryKeepSlotFree(slotCfg)
  if slotCfg.keepSlotFree ~= true then
    return false
  end

  local bpId = tonumber(slotCfg.id or 0) or 0
  local targetItemId = tonumber(slotCfg.targetItem or 0) or 0
  if bpId < 100 or targetItemId < 100 then
    return false
  end

  local container = findOpenBpContainer(bpId, false)
  if not container then
    return false
  end

  local count = getContainerItemsCountSafe(container)
  local capacity = getContainerCapacitySafe(container)
  if count < capacity then
    return false
  end

  local groundPos = type(pos) == "function" and pos() or nil
  if not groundPos or not g_game or type(g_game.move) ~= "function" then
    return false
  end

  for _, item in ipairs(getContainerItemsSafe(container)) do
    if item and item:getId() == targetItemId then
      local ok = pcall(function()
        g_game.move(item, groundPos, 1)
      end)
      if ok then
        return true
      end
    end
  end

  return false
end

local function forceOpenConfiguredBackpacks()
  local waitMs = 0
  for i = 1, UNIVERSAL_BP_SLOT_COUNT do
    local slotCfg = universalBpConfig.bpConfigs[i]
    if slotCfg and slotCfg.autoOpen and (tonumber(slotCfg.id or 0) or 0) >= 100 then
      local bpId = tonumber(slotCfg.id or 0) or 0
      if type(schedule) == "function" then
        schedule(waitMs, function()
          tryOpenBackpackById(bpId)
        end)
      else
        tryOpenBackpackById(bpId)
      end
      waitMs = waitMs + 180
    end
  end
end

local function runUniversalBpCycle()
  if universalBpConfig.enabled ~= true then
    return
  end

  local now = nowMsUniversal()
  if now - (universalBpState.lastActionMs or 0) < 180 then
    return
  end

  for i = 1, UNIVERSAL_BP_SLOT_COUNT do
    local slotCfg = universalBpConfig.bpConfigs[i]
    if slotCfg then
      local bpId = tonumber(slotCfg.id or 0) or 0
      if bpId >= 100 then
        if slotCfg.autoOpen then
          if tryOpenNextBackpack(slotCfg) then
            universalBpState.lastActionMs = now
            return
          end
          if tryOpenBackpackById(bpId) then
            universalBpState.lastActionMs = now
            return
          end
        end

        if tryOrganizeItem(slotCfg) then
          universalBpState.lastActionMs = now
          return
        end

        if tryKeepSlotFree(slotCfg) then
          universalBpState.lastActionMs = now
          return
        end
      end
    end
  end
end

local function setUniversalBpToggleStyle(widget, label, enabled)
  if not widget then
    return
  end
  local isOn = enabled == true
  widget:setText(label .. ": " .. (isOn and "ON" or "OFF"))
  widget:setColor(isOn and "#9FE36A" or "#FF6B6B")
  if widget.setBackgroundColor then
    widget:setBackgroundColor("#2b2b2b")
  end
  if widget.setBorderColor then
    widget:setBorderColor("#4A4A4A")
  end
end

local function buildDefaultPriorityConfig()
  return {
    playerDetect = {
      enabled = false,
      ring = 0,
      ringEquipped = 0,
      amulet = 0,
      amuletEquipped = 0,
      minPlayers = 1
    },
    pkDetect = {
      enabled = false,
      ring = 0,
      ringEquipped = 0,
      amulet = 0,
      amuletEquipped = 0,
      minPks = 1
    },
    monsterDetect = {
      enabled = false,
      ring = 0,
      ringEquipped = 0,
      amulet = 0,
      amuletEquipped = 0,
      monsterList = {},
      minMonsters = 1
    },
    enemyDetect = {
      enabled = false,
      ring = 0,
      ringEquipped = 0,
      amulet = 0,
      amuletEquipped = 0,
      enemyList = {},
      includeEnemyGuild = false
    },
    whiteList = {}
  }
end

local function normalizeSlotConfig(slot)
  local source = type(slot) == "table" and slot or {}
  local normalized = {
    itemId = tonumber(source.itemId) or 0,
    itemIdEquipped = tonumber(source.itemIdEquipped) or 0,
    hpMin = math.max(0, math.min(100, tonumber(source.hpMin) or 0)),
    hpMax = math.max(0, math.min(100, tonumber(source.hpMax) or 100)),
    mpMin = math.max(0, math.min(100, tonumber(source.mpMin) or 0)),
    mpMax = math.max(0, math.min(100, tonumber(source.mpMax) or 100))
  }

  if normalized.hpMin > normalized.hpMax then
    normalized.hpMin, normalized.hpMax = normalized.hpMax, normalized.hpMin
  end
  if normalized.mpMin > normalized.mpMax then
    normalized.mpMin, normalized.mpMax = normalized.mpMax, normalized.mpMin
  end

  return normalized
end

local function normalizePriorityConfig(priority)
  local sourcePriority = type(priority) == "table" and priority or {}
  local defaults = buildDefaultPriorityConfig()
  local normalizedPriority = {}

  local function normalizeNameList(value)
    local source = type(value) == "table" and value or {}
    local normalized = {}
    local seen = {}
    for _, rawName in pairs(source) do
      if type(rawName) == "string" or type(rawName) == "number" then
        local name = tostring(rawName or ""):gsub("^%s+", ""):gsub("%s+$", "")
        local key = name:lower()
        if name ~= "" and not seen[key] then
          seen[key] = true
          normalized[#normalized + 1] = name
        end
      end
    end
    table.sort(normalized, function(a, b)
      return a:lower() < b:lower()
    end)
    return normalized
  end

  local function ensureEntry(key)
    local entry = sourcePriority[key]
    if type(entry) ~= "table" then
      entry = {}
    end

    local normalizedEntry = {
      enabled = entry.enabled == true,
      ring = tonumber(entry.ring) or tonumber(defaults[key].ring) or 0,
      ringEquipped = tonumber(entry.ringEquipped) or tonumber(defaults[key].ringEquipped) or 0,
      amulet = tonumber(entry.amulet) or tonumber(defaults[key].amulet) or 0,
      amuletEquipped = tonumber(entry.amuletEquipped) or tonumber(defaults[key].amuletEquipped) or 0
    }

    if key == "pkDetect" then
      normalizedEntry.minPks = math.max(1, tonumber(entry.minPks) or tonumber(defaults[key].minPks) or 1)
    elseif key == "playerDetect" then
      normalizedEntry.minPlayers = math.max(1, tonumber(entry.minPlayers) or tonumber(defaults[key].minPlayers) or 1)
    elseif key == "monsterDetect" then
      normalizedEntry.minMonsters = math.max(1, tonumber(entry.minMonsters) or tonumber(defaults[key].minMonsters) or 1)
      normalizedEntry.monsterList = normalizeNameList(entry.monsterList)
    elseif key == "enemyDetect" then
      normalizedEntry.enemyList = normalizeNameList(entry.enemyList)
      normalizedEntry.includeEnemyGuild = entry.includeEnemyGuild == true
    end

    normalizedPriority[key] = normalizedEntry
  end

  ensureEntry("playerDetect")
  ensureEntry("pkDetect")
  ensureEntry("monsterDetect")
  ensureEntry("enemyDetect")
  normalizedPriority.whiteList = normalizeNameList(sourcePriority.whiteList)

  return normalizedPriority
end

local function normalizeRingAmuletData(data)
  if type(data) ~= "table" then
    return
  end

  for key, _ in pairs(data) do
    if type(key) ~= "string" then
      data[key] = nil
    end
  end

  data.swapDelay = tonumber(data.swapDelay) or 1000
  data.priority = normalizePriorityConfig(data.priority)

  local sourceRings = type(data.rings) == "table" and data.rings or {}
  local sourceAmulets = type(data.amulets) == "table" and data.amulets or {}
  local normalizedRings = {}
  local normalizedAmulets = {}

  for i = 1, 5 do
    normalizedRings[i] = normalizeSlotConfig(sourceRings[i] or sourceRings[tostring(i)])
    normalizedAmulets[i] = normalizeSlotConfig(sourceAmulets[i] or sourceAmulets[tostring(i)])
  end
  data.rings = normalizedRings
  data.amulets = normalizedAmulets

  if data.ringsEnabled == nil then
    data.ringsEnabled = normalizeBoolFlag(data.enabled, false)
  end
  if data.amuletsEnabled == nil then
    data.amuletsEnabled = normalizeBoolFlag(data.enabled, false)
  end
  data.ringsEnabled = normalizeBoolFlag(data.ringsEnabled, false)
  data.amuletsEnabled = normalizeBoolFlag(data.amuletsEnabled, false)
  data.enabled = normalizeBoolFlag(data.enabled, data.ringsEnabled or data.amuletsEnabled)
end

local function buildPresetSlot(itemId, equippedId, hpMin, hpMax, mpMin, mpMax)
  return normalizeSlotConfig({
    itemId = itemId or 0,
    itemIdEquipped = equippedId or itemId or 0,
    hpMin = hpMin or 0,
    hpMax = hpMax or 100,
    mpMin = mpMin or 0,
    mpMax = mpMax or 100
  })
end

local function buildEmptyPresetSlots()
  local slots = {}
  for i = 1, 5 do
    slots[i] = buildPresetSlot()
  end
  return slots
end

local function showRingProfileMessage(message, color)
  if modules and modules.game_textmessage and modules.game_textmessage.displayBroadcastMessage then
    modules.game_textmessage.displayBroadcastMessage(message, color or "#FFFFFF")
  end
end

local function captureRingProfileState()
  return cloneTable(config)
end

local ringProfileDebugState = {
  bootLogged = false,
  lastSanitizedProfile = nil
}

--[[
PROFILE PERSISTENCE STANDARD (2026-03)
- Canonical state: storage.ringAmuletProfiles.meta.activeProfile
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
local function trimRingProfileText(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function isRingProfileIdValid(profiles, profileId)
  local id = trimRingProfileText(profileId)
  if id == "" then
    return false
  end
  return type(profiles.configs[id]) == "table"
end

local function getFirstRingProfileId(profiles)
  for _, id in ipairs(profiles.order or {}) do
    if type(profiles.configs[id]) == "table" then
      return id
    end
  end
  return ""
end

local function setRingActiveProfile(profiles, profileId)
  local id = trimRingProfileText(profileId)
  if not isRingProfileIdValid(profiles, id) then
    id = getFirstRingProfileId(profiles)
  end
  profiles.meta.activeProfile = id
  return id
end

local function ensureRingProfiles()
  if type(storage.ringAmuletProfiles) ~= "table" then
    storage.ringAmuletProfiles = {}
  end

  local profiles = storage.ringAmuletProfiles
  local legacyList = type(profiles.list) == "table" and profiles.list or {}
  local legacyData = type(profiles.data) == "table" and profiles.data or {}
  local legacySelectedId = trimRingProfileText(profiles.selectedId)
  local existingConfigs = type(profiles.configs) == "table" and profiles.configs or {}
  local existingOrder = type(profiles.order) == "table" and profiles.order or {}

  local normalizedConfigs = {}
  local normalizedOrder = {}
  local seenIds = {}

  local function addProfileEntry(rawId, rawName, rawData)
    local id = trimRingProfileText(rawId)
    if id == "" or seenIds[id] then
      return
    end
    seenIds[id] = true
    local name = trimRingProfileText(rawName)
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
    normalizeRingAmuletData(dataTable)

    normalizedConfigs[id] = {
      name = name,
      data = dataTable
    }
    table.insert(normalizedOrder, id)
  end

  for _, rawId in ipairs(existingOrder) do
    local id = trimRingProfileText(rawId)
    local entry = type(existingConfigs[id]) == "table" and existingConfigs[id] or nil
    addProfileEntry(id, entry and entry.name or id, entry and entry.data or nil)
  end

  for _, entry in ipairs(legacyList) do
    local id = trimRingProfileText(entry and entry.id)
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
  profiles.meta.activeProfile = trimRingProfileText(profiles.meta.activeProfile)

  if #profiles.order == 0 then
    local defaultId = "cfg_1"
    profiles.configs[defaultId] = profiles.configs[defaultId] or {
      name = "Config 1",
      data = captureRingProfileState()
    }
    normalizeRingAmuletData(profiles.configs[defaultId].data)
    table.insert(profiles.order, defaultId)
    if profiles.nextId < 2 then
      profiles.nextId = 2
    end
  end

  local maxProfileNum = 0
  for _, id in ipairs(profiles.order) do
    local num = tonumber(tostring(id):match("^cfg_(%d+)$"))
    if num and num > maxProfileNum then
      maxProfileNum = num
    end
  end
  if profiles.nextId <= maxProfileNum then
    profiles.nextId = maxProfileNum + 1
  end

  if trimRingProfileText(profiles.meta.activeProfile) == "" then
    profiles.meta.activeProfile = legacySelectedId
  end
  local activeId = setRingActiveProfile(profiles, profiles.meta.activeProfile)
  if activeId ~= "" and type(profiles.configs[activeId].data) ~= "table" then
    profiles.configs[activeId].data = captureRingProfileState()
    normalizeRingAmuletData(profiles.configs[activeId].data)
  end

  if not profiles.presetsInstalled then
    local baseSnapshot = captureRingProfileState()

    local function addPreset(name, mutator)
      for _, id in ipairs(profiles.order) do
        local entry = profiles.configs[id]
        if type(entry) == "table" and entry.name == name then
          return
        end
      end

      local id = "cfg_" .. tostring(profiles.nextId)
      profiles.nextId = profiles.nextId + 1

      local presetData = cloneTable(baseSnapshot)
      if type(mutator) == "function" then
        mutator(presetData)
      end
      normalizeRingAmuletData(presetData)
      profiles.configs[id] = { name = name, data = presetData }
      table.insert(profiles.order, id)
    end

    addPreset("Ring Invertido", function(data)
      data.swapDelay = 650
      data.ringsEnabled = true
      data.amuletsEnabled = true
      data.rings = buildEmptyPresetSlots()
      data.amulets = buildEmptyPresetSlots()
      data.priority = buildDefaultPriorityConfig()

      data.rings[1] = buildPresetSlot(3051, 3051, 51, 100, 0, 100)
      data.rings[2] = buildPresetSlot(3048, 3048, 0, 50, 0, 100)
      data.amulets[1] = buildPresetSlot(3081, 3081, 0, 55, 0, 100)
      data.amulets[2] = buildPresetSlot(3055, 3055, 56, 100, 0, 100)

      data.priority.enemyDetect.enabled = true
      data.priority.enemyDetect.ring = 3048
      data.priority.enemyDetect.ringEquipped = 3048
      data.priority.enemyDetect.amulet = 3081
      data.priority.enemyDetect.amuletEquipped = 3081
      data.priority.enemyDetect.includeEnemyGuild = true

      data.priority.pkDetect.enabled = true
      data.priority.pkDetect.ring = 3048
      data.priority.pkDetect.ringEquipped = 3048
      data.priority.pkDetect.amulet = 3081
      data.priority.pkDetect.amuletEquipped = 3081
      data.priority.pkDetect.minPks = 1
    end)

    addPreset("SSA/Might", function(data)
      data.swapDelay = 450
      data.ringsEnabled = true
      data.amuletsEnabled = true
      data.rings = buildEmptyPresetSlots()
      data.amulets = buildEmptyPresetSlots()
      data.priority = buildDefaultPriorityConfig()

      data.rings[1] = buildPresetSlot(3048, 3048, 0, 100, 0, 100)
      data.amulets[1] = buildPresetSlot(3081, 3081, 0, 100, 0, 100)

      data.priority.enemyDetect.enabled = true
      data.priority.enemyDetect.ring = 3048
      data.priority.enemyDetect.ringEquipped = 3048
      data.priority.enemyDetect.amulet = 3081
      data.priority.enemyDetect.amuletEquipped = 3081
      data.priority.enemyDetect.includeEnemyGuild = true

      data.priority.pkDetect.enabled = true
      data.priority.pkDetect.ring = 3048
      data.priority.pkDetect.ringEquipped = 3048
      data.priority.pkDetect.amulet = 3081
      data.priority.pkDetect.amuletEquipped = 3081
      data.priority.pkDetect.minPks = 1
    end)

    profiles.presetsInstalled = true
    activeId = setRingActiveProfile(profiles, profiles.meta.activeProfile)
  end

  if not ringProfileDebugState.bootLogged then
    print("BOOT Active profile loaded: " .. activeId)
    ringProfileDebugState.bootLogged = true
  end
  if ringProfileDebugState.lastSanitizedProfile ~= activeId then
    print("SANITIZE Active profile after sanitize: " .. activeId)
    ringProfileDebugState.lastSanitizedProfile = activeId
  end

  return profiles
end

function getSelectedRingProfileId()
  local profiles = ensureRingProfiles()
  return setRingActiveProfile(profiles, profiles.meta.activeProfile)
end

function getRingProfileName(profileId)
  if not profileId or profileId == "" then
    return "Sem perfil"
  end
  local profiles = ensureRingProfiles()
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

local function saveRingProfileState(profileId)
  if not profileId or profileId == "" then
    return
  end
  local profiles = ensureRingProfiles()
  local id = setRingActiveProfile(profiles, profileId)
  if id == "" or type(profiles.configs[id]) ~= "table" then
    return
  end
  profiles.configs[id].data = captureRingProfileState()
  normalizeRingAmuletData(profiles.configs[id].data)
end

local function applyRingProfileState(profileId)
  if not profileId or profileId == "" then
    return
  end

  local profiles = ensureRingProfiles()
  local id = setRingActiveProfile(profiles, profileId)
  if id == "" then
    return
  end
  print("APPLY Applying profile: " .. id)
  local entry = profiles.configs[id]
  local data = type(entry) == "table" and entry.data or nil
  if type(data) ~= "table" then
    if type(entry) == "table" then
      entry.data = captureRingProfileState()
      normalizeRingAmuletData(entry.data)
    end
    return
  end

  applyTableData(config, data)
  normalizeRingAmuletData(config)
  syncSystemEnabled()
end

local function addRingProfile(name)
  local cleaned = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if cleaned == "" then
    return nil
  end

  local profiles = ensureRingProfiles()
  local id = "cfg_" .. tostring(profiles.nextId)
  profiles.nextId = profiles.nextId + 1
  profiles.configs[id] = { name = cleaned, data = captureRingProfileState() }
  normalizeRingAmuletData(profiles.configs[id].data)
  table.insert(profiles.order, id)
  setRingActiveProfile(profiles, id)
  return id
end

local function refreshRingAmuletWindows()
  ringProfileRefreshPending = false

  local reopenSetup = setupWindow and setupWindow:isVisible()
  local reopenPriority = priorityWindow and priorityWindow:isVisible()

  if setupWindow then
    setupWindow:destroy()
    setupWindow = nil
    ringHeaderToggleRef = nil
    amuletHeaderToggleRef = nil
  end
  if priorityWindow then
    priorityWindow:destroy()
    priorityWindow = nil
  end

  if reopenSetup and createSetupWindow then
    createSetupWindow()
  end
  if reopenPriority and openPriorityWindow then
    openPriorityWindow()
  end
end

local function scheduleRingAmuletUiRefresh()
  if ringProfileRefreshPending then
    return
  end
  ringProfileRefreshPending = true

  if addEvent then
    addEvent(refreshRingAmuletWindows)
  else
    refreshRingAmuletWindows()
  end
end

normalizeRingAmuletData(config)
syncSystemEnabled()

local function setRingModuleEnabled(enabled)
  local turnOn = enabled == true
  local changed = isRingModuleEnabled() ~= turnOn
  config.ringsEnabled = turnOn
  syncSystemEnabled()
  refreshRingAmuletHeaderToggles()
  if changed then
    scheduleRingAmuletUiRefresh()
  end
  return changed
end

local function setAmuletModuleEnabled(enabled)
  local turnOn = enabled == true
  local changed = isAmuletModuleEnabled() ~= turnOn
  config.amuletsEnabled = turnOn
  syncSystemEnabled()
  refreshRingAmuletHeaderToggles()
  if changed then
    scheduleRingAmuletUiRefresh()
  end
  return changed
end

local function consumePainelRingAmuletBridge()
  local bridge = storage and storage.painelDeIconesBridge
  if type(bridge) ~= "table" then
    return
  end

  if bridge.ringDesired ~= nil then
    local desiredRing = bridge.ringDesired == true
    bridge.ringDesired = nil
    setRingModuleEnabled(desiredRing)
  end

  if bridge.amuletDesired ~= nil then
    local desiredAmulet = bridge.amuletDesired == true
    bridge.amuletDesired = nil
    setAmuletModuleEnabled(desiredAmulet)
  end
end

consumePainelRingAmuletBridge()
local ringAmuletBridgeSyncMacro = macro(250, function()
  consumePainelRingAmuletBridge()
end)

RingModuleController = {
  setOn = function(...)
    local value = true
    local args = {...}
    if type(args[1]) == "boolean" then
      value = args[1]
    elseif type(args[2]) == "boolean" then
      value = args[2]
    end
    setRingModuleEnabled(value == true)
  end,
  setOff = function()
    setRingModuleEnabled(false)
  end,
  isOn = function()
    return isRingModuleEnabled()
  end
}

AmuletModuleController = {
  setOn = function(...)
    local value = true
    local args = {...}
    if type(args[1]) == "boolean" then
      value = args[1]
    elseif type(args[2]) == "boolean" then
      value = args[2]
    end
    setAmuletModuleEnabled(value == true)
  end,
  setOff = function()
    setAmuletModuleEnabled(false)
  end,
  isOn = function()
    return isAmuletModuleEnabled()
  end
}


-- Desativa flags do sistema legado (SmartRing/SmartAmulet) para evitar travar o macro novo
if type(storage.SmartRingPanel) == "table" and storage.SmartRingPanel.enabled then
  storage.SmartRingPanel.enabled = false
end
if type(storage.SmartAmuletPanel) == "table" and storage.SmartAmuletPanel.enabled then
  storage.SmartAmuletPanel.enabled = false
end

-- Retorna a primeira posicao livre em containers abertos (para mover item ao unequip)
local function getFirstFreeContainerPos()
  for _, container in pairs(getContainers() or {}) do
    local items = container:getItems() or {}
    if #items < container:getCapacity() then
      return container:getSlotPosition(#items)
    end
  end
  return nil
end

-- ============================================
-- FUNCOES AUXILIARES DE DETECCAO
-- Sistema de deteccao de prioridades com suporte a White List
-- ============================================

-- Verifica se um player esta na White List (ignorado em todas prioridades)

local function isInWhiteList(playerName)
  if not playerName then return false end
  local whiteList = config.priority.whiteList or {}
  for _, name in ipairs(whiteList) do
    if name:lower() == playerName:lower() then
      return true
    end
  end
  return false
end

local priorityScanCache = {
  checkedAt = 0,
  players = 0,
  pks = 0,
  monsters = 0,
  enemy = false
}

local function buildLowerNameSet(list)
  local set = {}
  if type(list) ~= "table" then
    return set
  end
  for _, rawName in ipairs(list) do
    local normalized = tostring(rawName or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if normalized ~= "" then
      set[normalized] = true
    end
  end
  return set
end

local function getPriorityScan()
  local nowMs = nowMsUniversal()
  if (nowMs - (priorityScanCache.checkedAt or 0)) < 220 then
    return priorityScanCache
  end

  priorityScanCache.checkedAt = nowMs
  priorityScanCache.players = 0
  priorityScanCache.pks = 0
  priorityScanCache.monsters = 0
  priorityScanCache.enemy = false

  local localPlayer = g_game and g_game.getLocalPlayer and g_game.getLocalPlayer() or nil
  if not localPlayer then
    return priorityScanCache
  end

  if not g_map or not g_map.getSpectators then
    return priorityScanCache
  end

  local playerPos = localPlayer:getPosition()
  if not playerPos then
    return priorityScanCache
  end

  local enemySet = buildLowerNameSet(config.priority.enemyDetect and config.priority.enemyDetect.enemyList or {})
  local whiteListSet = buildLowerNameSet(config.priority.whiteList or {})
  local includeGuildEnemy = config.priority.enemyDetect and config.priority.enemyDetect.includeEnemyGuild == true
  local monsterList = config.priority.monsterDetect and config.priority.monsterDetect.monsterList or {}
  local creatures = g_map.getSpectators(playerPos, false) or {}

  for _, creature in ipairs(creatures) do
    if creature and creature ~= localPlayer then
      if creature.isPlayer and creature:isPlayer() then
        local creatureName = creature.getName and creature:getName() or ""
        local creatureNameLower = creatureName:lower()
        if not whiteListSet[creatureNameLower] then
          if not (creature.isPartyMember and creature:isPartyMember()) then
            priorityScanCache.players = priorityScanCache.players + 1
          end

          local skull = creature.getSkull and creature:getSkull() or 0
          if skull == 3 then
            priorityScanCache.pks = priorityScanCache.pks + 1
          end

          if enemySet[creatureNameLower] then
            priorityScanCache.enemy = true
          elseif includeGuildEnemy then
            local emblem = creature.getEmblem and creature:getEmblem() or 0
            if emblem == 1 then
              priorityScanCache.enemy = true
            end
          end
        end
      elseif creature.isMonster and creature:isMonster() and type(monsterList) == "table" and #monsterList > 0 then
        local creatureNameLower = (creature.getName and creature:getName() or ""):lower()
        for _, monsterName in ipairs(monsterList) do
          local filterName = tostring(monsterName or ""):lower()
          if filterName ~= "" and creatureNameLower:find(filterName, 1, true) then
            priorityScanCache.monsters = priorityScanCache.monsters + 1
            break
          end
        end
      end
    end
  end

  return priorityScanCache
end

local function countPlayersOnScreen()
  return getPriorityScan().players or 0
end

local function countPksOnScreen()
  return getPriorityScan().pks or 0
end

local function countMonstersOnScreen()
  return getPriorityScan().monsters or 0
end

local function hasEnemyOnScreen()
  return getPriorityScan().enemy == true
end

-- ============================================
-- UI PRINCIPAL (Painel Lateral)
-- ============================================

setDefaultTab("Main")

local mainUI = setupUI([[
Panel
  height: 20

  Button
    id: setupBtn
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 18
    text: Ring/Amulet
    font: verdana-11px-rounded
]], parent)

-- ============================================
-- CONSTRUIR SLOT RING/AMULET (REUTILIZAVEL)
-- ============================================

local function buildRingSlot(panel, slotIndex)
  local slotConfig = config.rings[slotIndex]

  -- Label do slot
  local slotLabel = g_ui.createWidget('BotLabel', panel)
  slotLabel:setText('Slot ' .. slotIndex)
  slotLabel:setColor('#FFD700')

  -- Container do slot (BotItems + SpinBoxes compactos)
  local slotContainer = setupUI([[
Panel
  height: 54

  BotItem
    id: ringItem
    anchors.left: parent.left
    anchors.top: parent.top
    size: 32 32

  BotItem
    id: ringItemEquipped
    anchors.left: ringItem.right
    anchors.top: parent.top
    margin-left: 2
    size: 32 32

  BotLabel
    id: ringEquipLabel
    anchors.top: ringItem.bottom
    anchors.left: ringItem.left
    margin-top: 3
    width: 36
    height: 12
    text: Equip
    text-align: center
    color: #AAAAAA

  BotLabel
    id: ringNoEquipLabel
    anchors.top: ringItemEquipped.bottom
    anchors.left: ringItemEquipped.left
    margin-top: 3
    width: 36
    height: 12
    text: NoEquip
    text-align: center
    color: #AAAAAA

  Panel
    id: rangePanel
    anchors.left: ringItemEquipped.right
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-left: 3
    margin-right: 1
    layout:
      type: verticalBox
      spacing: 1

    Panel
      height: 17
      layout:
        type: horizontalBox
        spacing: 1

      BotLabel
        id: hpLabel
        text: HP%
        width: 30
        text-align: left
        color: #FFFFFF

      SpinBox
        id: hpMinSpin
        width: 48
        height: 18
        text-align: center
        background-color: #1a1a2e
        color: #FFFFFF
        border-color: #87CEEB
        minimum: 0
        maximum: 100
        step: 1
        editable: true
        focusable: true

      BotLabel
        id: hpToLabel
        text: ate
        width: 20
        text-align: center
        color: #AAAAAA

      SpinBox
        id: hpMaxSpin
        width: 48
        height: 18
        text-align: center
        background-color: #1a1a2e
        color: #FFFFFF
        border-color: #87CEEB
        minimum: 0
        maximum: 100
        step: 1
        editable: true
        focusable: true

    Panel
      height: 17
      layout:
        type: horizontalBox
        spacing: 1

      BotLabel
        id: mpLabel
        text: MP%
        width: 30
        text-align: left
        color: #FFFFFF

      SpinBox
        id: mpMinSpin
        width: 48
        height: 18
        text-align: center
        background-color: #1a1a2e
        color: #FFFFFF
        border-color: #87CEEB
        minimum: 0
        maximum: 100
        step: 1
        editable: true
        focusable: true

      BotLabel
        id: mpToLabel
        text: ate
        width: 20
        text-align: center
        color: #AAAAAA

      SpinBox
        id: mpMaxSpin
        width: 48
        height: 18
        text-align: center
        background-color: #1a1a2e
        color: #FFFFFF
        border-color: #87CEEB
        minimum: 0
        maximum: 100
        step: 1
        editable: true
        focusable: true
]], panel)

  -- Configurar BotItems (desequipado e equipado)
  if slotConfig.itemId and slotConfig.itemId > 0 then
    slotContainer.ringItem:setItemId(slotConfig.itemId)
  end
  slotContainer.ringItem.onItemChange = function(widget)
    slotConfig.itemId = widget:getItemId()
  end

  if slotConfig.itemIdEquipped and slotConfig.itemIdEquipped > 0 then
    slotContainer.ringItemEquipped:setItemId(slotConfig.itemIdEquipped)
  end
  slotContainer.ringItemEquipped.onItemChange = function(widget)
    slotConfig.itemIdEquipped = widget:getItemId()
  end

  slotContainer.hpMinSpin = slotContainer:recursiveGetChildById('hpMinSpin')
  slotContainer.hpMaxSpin = slotContainer:recursiveGetChildById('hpMaxSpin')
  slotContainer.mpMinSpin = slotContainer:recursiveGetChildById('mpMinSpin')
  slotContainer.mpMaxSpin = slotContainer:recursiveGetChildById('mpMaxSpin')

  if slotContainer.hpMinSpin and slotContainer.hpMaxSpin and slotContainer.mpMinSpin and slotContainer.mpMaxSpin then
    -- Configurar SpinBoxes de HP%
    slotContainer.hpMinSpin:setValue(slotConfig.hpMin or 0)
    slotContainer.hpMaxSpin:setValue(slotConfig.hpMax or 100)

    -- Configurar SpinBoxes de MP%
    slotContainer.mpMinSpin:setValue(slotConfig.mpMin or 0)
    slotContainer.mpMaxSpin:setValue(slotConfig.mpMax or 100)

    local function updateHPRange()
      local minVal = slotContainer.hpMinSpin:getValue()
      local maxVal = slotContainer.hpMaxSpin:getValue()
      if minVal > maxVal then
        if slotContainer.hpMinSpin:isFocused() then
          slotContainer.hpMaxSpin:setValue(minVal)
          maxVal = minVal
        else
          slotContainer.hpMinSpin:setValue(maxVal)
          minVal = maxVal
        end
      end
      slotConfig.hpMin = minVal
      slotConfig.hpMax = maxVal
    end

    local function updateMPRange()
      local minVal = slotContainer.mpMinSpin:getValue()
      local maxVal = slotContainer.mpMaxSpin:getValue()
      if minVal > maxVal then
        if slotContainer.mpMinSpin:isFocused() then
          slotContainer.mpMaxSpin:setValue(minVal)
          maxVal = minVal
        else
          slotContainer.mpMinSpin:setValue(maxVal)
          minVal = maxVal
        end
      end
      slotConfig.mpMin = minVal
      slotConfig.mpMax = maxVal
    end

    slotContainer.hpMinSpin.onValueChange = function()
      updateHPRange()
    end

    slotContainer.hpMaxSpin.onValueChange = function()
      updateHPRange()
    end

    slotContainer.mpMinSpin.onValueChange = function()
      updateMPRange()
    end

    slotContainer.mpMaxSpin.onValueChange = function()
      updateMPRange()
    end

    updateHPRange()
    updateMPRange()
  end
end


local function buildAmuletSlot(panel, slotIndex)
  local slotConfig = config.amulets[slotIndex]

  -- Label do slot
  local slotLabel = g_ui.createWidget('BotLabel', panel)
  slotLabel:setText('Slot ' .. slotIndex)
  slotLabel:setColor('#FFD700')

  -- Container do slot (BotItems + SpinBoxes compactos)
  local slotContainer = setupUI([[
Panel
  height: 54

  BotItem
    id: amuletItem
    anchors.left: parent.left
    anchors.top: parent.top
    size: 32 32

  BotItem
    id: amuletItemEquipped
    anchors.left: amuletItem.right
    anchors.top: parent.top
    margin-left: 2
    size: 32 32

  BotLabel
    id: amuletEquipLabel
    anchors.top: amuletItem.bottom
    anchors.left: amuletItem.left
    margin-top: 3
    width: 36
    height: 12
    text: Equip
    text-align: center
    color: #AAAAAA

  BotLabel
    id: amuletNoEquipLabel
    anchors.top: amuletItemEquipped.bottom
    anchors.left: amuletItemEquipped.left
    margin-top: 3
    width: 36
    height: 12
    text: NoEquip
    text-align: center
    color: #AAAAAA

  Panel
    id: rangePanel
    anchors.left: amuletItemEquipped.right
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-left: 3
    margin-right: 1
    layout:
      type: verticalBox
      spacing: 1

    Panel
      height: 17
      layout:
        type: horizontalBox
        spacing: 1

      BotLabel
        id: hpLabel
        text: HP%
        width: 30
        text-align: left
        color: #FFFFFF

      SpinBox
        id: hpMinSpin
        width: 48
        height: 18
        text-align: center
        background-color: #1a1a2e
        color: #FFFFFF
        border-color: #87CEEB
        minimum: 0
        maximum: 100
        step: 1
        editable: true
        focusable: true

      BotLabel
        id: hpToLabel
        text: ate
        width: 20
        text-align: center
        color: #AAAAAA

      SpinBox
        id: hpMaxSpin
        width: 48
        height: 18
        text-align: center
        background-color: #1a1a2e
        color: #FFFFFF
        border-color: #87CEEB
        minimum: 0
        maximum: 100
        step: 1
        editable: true
        focusable: true

    Panel
      height: 17
      layout:
        type: horizontalBox
        spacing: 1

      BotLabel
        id: mpLabel
        text: MP%
        width: 30
        text-align: left
        color: #FFFFFF

      SpinBox
        id: mpMinSpin
        width: 48
        height: 18
        text-align: center
        background-color: #1a1a2e
        color: #FFFFFF
        border-color: #87CEEB
        minimum: 0
        maximum: 100
        step: 1
        editable: true
        focusable: true

      BotLabel
        id: mpToLabel
        text: ate
        width: 20
        text-align: center
        color: #AAAAAA

      SpinBox
        id: mpMaxSpin
        width: 48
        height: 18
        text-align: center
        background-color: #1a1a2e
        color: #FFFFFF
        border-color: #87CEEB
        minimum: 0
        maximum: 100
        step: 1
        editable: true
        focusable: true
]], panel)

  -- Configurar BotItems (desequipado e equipado)
  if slotConfig.itemId and slotConfig.itemId > 0 then
    slotContainer.amuletItem:setItemId(slotConfig.itemId)
  end
  slotContainer.amuletItem.onItemChange = function(widget)
    slotConfig.itemId = widget:getItemId()
  end

  if slotConfig.itemIdEquipped and slotConfig.itemIdEquipped > 0 then
    slotContainer.amuletItemEquipped:setItemId(slotConfig.itemIdEquipped)
  end
  slotContainer.amuletItemEquipped.onItemChange = function(widget)
    slotConfig.itemIdEquipped = widget:getItemId()
  end

  slotContainer.hpMinSpin = slotContainer:recursiveGetChildById('hpMinSpin')
  slotContainer.hpMaxSpin = slotContainer:recursiveGetChildById('hpMaxSpin')
  slotContainer.mpMinSpin = slotContainer:recursiveGetChildById('mpMinSpin')
  slotContainer.mpMaxSpin = slotContainer:recursiveGetChildById('mpMaxSpin')

  if slotContainer.hpMinSpin and slotContainer.hpMaxSpin and slotContainer.mpMinSpin and slotContainer.mpMaxSpin then
    -- Configurar SpinBoxes de HP%
    slotContainer.hpMinSpin:setValue(slotConfig.hpMin or 0)
    slotContainer.hpMaxSpin:setValue(slotConfig.hpMax or 100)

    -- Configurar SpinBoxes de MP%
    slotContainer.mpMinSpin:setValue(slotConfig.mpMin or 0)
    slotContainer.mpMaxSpin:setValue(slotConfig.mpMax or 100)

    local function updateHPRange()
      local minVal = slotContainer.hpMinSpin:getValue()
      local maxVal = slotContainer.hpMaxSpin:getValue()
      if minVal > maxVal then
        if slotContainer.hpMinSpin:isFocused() then
          slotContainer.hpMaxSpin:setValue(minVal)
          maxVal = minVal
        else
          slotContainer.hpMinSpin:setValue(maxVal)
          minVal = maxVal
        end
      end
      slotConfig.hpMin = minVal
      slotConfig.hpMax = maxVal
    end

    local function updateMPRange()
      local minVal = slotContainer.mpMinSpin:getValue()
      local maxVal = slotContainer.mpMaxSpin:getValue()
      if minVal > maxVal then
        if slotContainer.mpMinSpin:isFocused() then
          slotContainer.mpMaxSpin:setValue(minVal)
          maxVal = minVal
        else
          slotContainer.mpMinSpin:setValue(maxVal)
          minVal = maxVal
        end
      end
      slotConfig.mpMin = minVal
      slotConfig.mpMax = maxVal
    end

    slotContainer.hpMinSpin.onValueChange = function()
      updateHPRange()
    end

    slotContainer.hpMaxSpin.onValueChange = function()
      updateHPRange()
    end

    slotContainer.mpMinSpin.onValueChange = function()
      updateMPRange()
    end

    slotContainer.mpMaxSpin.onValueChange = function()
      updateMPRange()
    end

    updateHPRange()
    updateMPRange()
  end
end

-- ============================================
-- EDITORES DE LISTA
-- ============================================

local function openMonsterListEditor(updateCallback)
  local listWindow = g_ui.createWidget("EnemyListWindow", g_ui.getRootWidget())
  listWindow:setText("Lista de Monstros")

  local infoLabel = listWindow:getChildById("infoLabel")
  infoLabel:setText("Digite os nomes dos monstros, separados por virgula:")

  local namesInput = listWindow:getChildById("namesInput")
  if #config.priority.monsterDetect.monsterList > 0 then
    namesInput:setText(table.concat(config.priority.monsterDetect.monsterList, ", "))
  end

  local buttonsPanel = listWindow:getChildById("buttonsPanel")
  local saveButton = buttonsPanel:getChildById("saveButton")
  saveButton.onClick = function()
    local text = namesInput:getText()
    local newList = {}

    if text and text ~= "" then
      for name in string.gmatch(text, "([^,]+)") do
        local trimmedName = name:match("^%s*(.-)%s*$")
        if trimmedName and #trimmedName > 0 then
          table.insert(newList, trimmedName)
        end
      end
    end

    config.priority.monsterDetect.monsterList = newList
    print("[RING/AMULET] Lista de monstros atualizada: " .. #newList .. " monstros")

    if updateCallback then updateCallback() end
    listWindow:destroy()
  end

  local cancelButton = buttonsPanel:getChildById("cancelButton")
  cancelButton.onClick = function()
    listWindow:destroy()
  end

  listWindow:show()
  listWindow:raise()
  listWindow:focus()
  namesInput:focus()
end

local function openEnemyListEditor(updateCallback)
  local listWindow = g_ui.createWidget("EnemyListWindow", g_ui.getRootWidget())
  listWindow:setText("Enemy List - PKs Conhecidos")

  local infoLabel = listWindow:getChildById("infoLabel")
  infoLabel:setText("Digite os nomes dos PKs conhecidos, separados por virgula:")

  local namesInput = listWindow:getChildById("namesInput")
  if #config.priority.enemyDetect.enemyList > 0 then
    namesInput:setText(table.concat(config.priority.enemyDetect.enemyList, ", "))
  end

  local buttonsPanel = listWindow:getChildById("buttonsPanel")
  local saveButton = buttonsPanel:getChildById("saveButton")
  saveButton.onClick = function()
    local text = namesInput:getText()
    local newList = {}

    if text and text ~= "" then
      for name in string.gmatch(text, "([^,]+)") do
        local trimmedName = name:match("^%s*(.-)%s*$")
        if trimmedName and #trimmedName > 0 then
          table.insert(newList, trimmedName)
        end
      end
    end

    config.priority.enemyDetect.enemyList = newList
    print("[RING/AMULET] Enemy list atualizada: " .. #newList .. " players")

    if updateCallback then updateCallback() end
    listWindow:destroy()
  end

  local cancelButton = buttonsPanel:getChildById("cancelButton")
  cancelButton.onClick = function()
    listWindow:destroy()
  end

  listWindow:show()
  listWindow:raise()
  listWindow:focus()
  namesInput:focus()
end

local function openWhiteListEditor(updateCallback)
  local listWindow = g_ui.createWidget("EnemyListWindow", g_ui.getRootWidget())
  listWindow:setText("White List - Players Ignorados")

  local infoLabel = listWindow:getChildById("infoLabel")
  infoLabel:setText("Digite os nomes dos players que serao ignorados em TODAS as prioridades, separados por virgula:")

  local namesInput = listWindow:getChildById("namesInput")
  if #config.priority.whiteList > 0 then
    namesInput:setText(table.concat(config.priority.whiteList, ", "))
  end

  local buttonsPanel = listWindow:getChildById("buttonsPanel")
  local saveButton = buttonsPanel:getChildById("saveButton")
  saveButton.onClick = function()
    local text = namesInput:getText()
    local newList = {}

    if text and text ~= "" then
      for name in string.gmatch(text, "([^,]+)") do
        local trimmedName = name:match("^%s*(.-)%s*$")
        if trimmedName and #trimmedName > 0 then
          table.insert(newList, trimmedName)
        end
      end
    end

    config.priority.whiteList = newList
    print("[RING/AMULET] White list atualizada: " .. #newList .. " players ignorados")

    if updateCallback then updateCallback() end
    listWindow:destroy()
  end

  local cancelButton = buttonsPanel:getChildById("cancelButton")
  cancelButton.onClick = function()
    listWindow:destroy()
  end

  listWindow:show()
  listWindow:raise()
  listWindow:focus()
  namesInput:focus()
end

-- ============================================
-- CONSTRUIR ABA SETUP PRIORIDADES
-- Interface para configurar todas as 4 prioridades
-- Cada prioridade pode ter ring e amulet especificos (deseq + equip)
-- ============================================

local function buildPriorityTab(panel)
  local scrollContent = panel

  local function setTip(widget, ptText, enText)
    if widget and widget.setTooltip then
      widget:setTooltip(string.format("PT: %s\nEN: %s", tostring(ptText or ""), tostring(enText or "")))
    end
  end

  local function addCompactSeparator()
    setupUI([[
Panel
  height: 1
  background-color: #3f3f3f
]], scrollContent)
  end

  -- Separador
  addCompactSeparator()

  -- Titulo
  local titleLabel = g_ui.createWidget('BotLabel', scrollContent)
  titleLabel:setText('Configuracoes de Prioridade')
  titleLabel:setColor('#FFD700')
  setTip(titleLabel, "Configura os gatilhos de troca por prioridade.", "Configure swap triggers by priority.")

  addCompactSeparator()

  -- ========== WHITE LIST ==========
  local whiteListLabel = g_ui.createWidget('BotLabel', scrollContent)
  whiteListLabel:setText('White List - Players Ignorados')
  whiteListLabel:setColor('#CCCCCC')
  setTip(whiteListLabel, "Players ignorados por todas as prioridades.", "Players ignored by all priorities.")

  local whiteListBtn = g_ui.createWidget('Button', scrollContent)
  whiteListBtn:setText('Gerenciar White List (' .. #config.priority.whiteList .. ')')
  whiteListBtn:setHeight(20)
  setTip(whiteListBtn, "Abre o editor da White List.", "Opens the White List editor.")
  whiteListBtn.onClick = function()
    openWhiteListEditor(function()
      whiteListBtn:setText('Gerenciar White List (' .. #config.priority.whiteList .. ')')
    end)
  end

  local whiteListInfo = g_ui.createWidget('BotLabel', scrollContent)
  whiteListInfo:setText('Players da White List sao ignorados em TODAS as prioridades (Enemy, PK, Monstro, Player)')
  whiteListInfo:setColor('#888888')
  whiteListInfo:setTextWrap(true)
  setTip(whiteListInfo, "Ignora deteccao de Enemy/PK/Player/Monstro para nomes da lista.", "Skips Enemy/PK/Player/Monster detection for names in the list.")

  addCompactSeparator()

  -- ========== PRIORIDADE 1: ENEMY NA TELA ==========
  local enemyLabel = g_ui.createWidget('BotLabel', scrollContent)
  enemyLabel:setText('Prioridade 1: Enemy na Tela')
  enemyLabel:setColor('#FF0000')
  setTip(enemyLabel, "Maior prioridade de troca quando detectar enemy.", "Highest swap priority when an enemy is detected.")

  local enemyCheck = g_ui.createWidget('CategoryCheckBox', scrollContent)
  enemyCheck:setText('Detectar Enemies')
  enemyCheck:setChecked(config.priority.enemyDetect.enabled)
  setTip(enemyCheck, "Liga/desliga a prioridade Enemy.", "Enable/disable Enemy priority.")
  enemyCheck.onClick = function()
    config.priority.enemyDetect.enabled = not config.priority.enemyDetect.enabled
    enemyCheck:setChecked(config.priority.enemyDetect.enabled)
  end

  local enemyContainer = setupUI([[
Panel
  height: 64

  BotItem
    id: ring
    anchors.left: parent.left
    anchors.top: parent.top
    size: 32 32

  BotItem
    id: ringEquipped
    anchors.left: ring.right
    anchors.top: parent.top
    margin-left: 3
    size: 32 32

  BotLabel
    id: ringLabel
    anchors.left: ringEquipped.right
    anchors.top: parent.top
    anchors.right: parent.horizontalCenter
    margin-left: 3
    margin-top: 4
    text: Ring
    color: #FFFFFF

  BotItem
    id: amulet
    anchors.left: parent.horizontalCenter
    anchors.top: parent.top
    margin-left: 6
    size: 32 32

  BotItem
    id: amuletEquipped
    anchors.left: amulet.right
    anchors.top: parent.top
    margin-left: 3
    size: 32 32

  BotLabel
    id: amuletLabel
    anchors.left: amuletEquipped.right
    anchors.top: parent.top
    anchors.right: parent.right
    margin-left: 3
    margin-top: 4
    text: Amulet
    color: #FFFFFF

  Button
    id: manageBtn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: ring.bottom
    margin-top: 3
    height: 18
    text: Gerenciar Enemy List (0)
]], scrollContent)

  enemyContainer.ring:setItemId(config.priority.enemyDetect.ring)
  enemyContainer.ring.onItemChange = function(widget)
    config.priority.enemyDetect.ring = widget:getItemId()
  end

  enemyContainer.ringEquipped:setItemId(config.priority.enemyDetect.ringEquipped)
  enemyContainer.ringEquipped.onItemChange = function(widget)
    config.priority.enemyDetect.ringEquipped = widget:getItemId()
  end

  enemyContainer.amulet:setItemId(config.priority.enemyDetect.amulet)
  enemyContainer.amulet.onItemChange = function(widget)
    config.priority.enemyDetect.amulet = widget:getItemId()
  end

  enemyContainer.amuletEquipped:setItemId(config.priority.enemyDetect.amuletEquipped)
  enemyContainer.amuletEquipped.onItemChange = function(widget)
    config.priority.enemyDetect.amuletEquipped = widget:getItemId()
  end

  enemyContainer.manageBtn:setText('Gerenciar Enemy List (' .. #config.priority.enemyDetect.enemyList .. ')')
  setTip(enemyContainer.ring, "Ring base da prioridade Enemy.", "Base ring for Enemy priority.")
  setTip(enemyContainer.ringEquipped, "ID do ring quando equipado (Enemy).", "Equipped ring ID (Enemy).")
  setTip(enemyContainer.ringLabel, "Descricao do ring da prioridade Enemy.", "Ring description for Enemy priority.")
  setTip(enemyContainer.amulet, "Amulet base da prioridade Enemy.", "Base amulet for Enemy priority.")
  setTip(enemyContainer.amuletEquipped, "ID do amulet quando equipado (Enemy).", "Equipped amulet ID (Enemy).")
  setTip(enemyContainer.amuletLabel, "Descricao do amulet da prioridade Enemy.", "Amulet description for Enemy priority.")
  setTip(enemyContainer.manageBtn, "Abre a lista de enemies monitorados.", "Open monitored enemies list.")
  enemyContainer.manageBtn.onClick = function()
    openEnemyListEditor(function()
      enemyContainer.manageBtn:setText('Gerenciar Enemy List (' .. #config.priority.enemyDetect.enemyList .. ')')
    end)
  end

  local enemyGuildCheck = g_ui.createWidget('CategoryCheckBox', scrollContent)
  enemyGuildCheck:setText('Incluir Guild Inimiga (Emblem)')
  enemyGuildCheck:setChecked(config.priority.enemyDetect.includeEnemyGuild)
  setTip(enemyGuildCheck, "Inclui guild inimiga via emblem.", "Include enemy guild by emblem.")
  enemyGuildCheck.onClick = function()
    config.priority.enemyDetect.includeEnemyGuild = not config.priority.enemyDetect.includeEnemyGuild
    enemyGuildCheck:setChecked(config.priority.enemyDetect.includeEnemyGuild)
  end

  addCompactSeparator()

  -- ========== PRIORIDADE 2: PK NA TELA ==========
  local pkLabel = g_ui.createWidget('BotLabel', scrollContent)
  pkLabel:setText('Prioridade 2: PK na Tela (White Skull)')
  pkLabel:setColor('#FF6600')
  setTip(pkLabel, "Troca quando quantidade de PKs atingir o limite.", "Swap when PK count reaches the threshold.")

  local pkCheck = g_ui.createWidget('CategoryCheckBox', scrollContent)
  pkCheck:setText('Detectar PKs')
  pkCheck:setChecked(config.priority.pkDetect.enabled)
  setTip(pkCheck, "Liga/desliga a prioridade por PK.", "Enable/disable PK priority.")
  pkCheck.onClick = function()
    config.priority.pkDetect.enabled = not config.priority.pkDetect.enabled
    pkCheck:setChecked(config.priority.pkDetect.enabled)
  end

  local pkContainer = setupUI([[
Panel
  height: 76

  BotItem
    id: ring
    anchors.left: parent.left
    anchors.top: parent.top
    size: 32 32

  BotItem
    id: ringEquipped
    anchors.left: ring.right
    anchors.top: parent.top
    margin-left: 3
    size: 32 32

  BotLabel
    id: ringLabel
    anchors.left: ringEquipped.right
    anchors.top: parent.top
    anchors.right: parent.horizontalCenter
    margin-left: 3
    margin-top: 4
    text: Ring
    color: #FFFFFF

  BotItem
    id: amulet
    anchors.left: parent.horizontalCenter
    anchors.top: parent.top
    margin-left: 6
    size: 32 32

  BotItem
    id: amuletEquipped
    anchors.left: amulet.right
    anchors.top: parent.top
    margin-left: 3
    size: 32 32

  BotLabel
    id: amuletLabel
    anchors.left: amuletEquipped.right
    anchors.top: parent.top
    anchors.right: parent.right
    margin-left: 3
    margin-top: 4
    text: Amulet
    color: #FFFFFF

  BotLabel
    id: countLabel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: ring.bottom
    margin-top: 3
    text: Quantidade minima: 1 PKs
    color: #87CEEB
    background-color: #000000
    text-align: center

  HorizontalScrollBar
    id: countScroll
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: countLabel.bottom
    margin-top: 2
    height: 16
    minimum: 1
    maximum: 10
    step: 1
]], scrollContent)

  pkContainer.ring:setItemId(config.priority.pkDetect.ring)
  pkContainer.ring.onItemChange = function(widget)
    config.priority.pkDetect.ring = widget:getItemId()
  end

  pkContainer.ringEquipped:setItemId(config.priority.pkDetect.ringEquipped)
  pkContainer.ringEquipped.onItemChange = function(widget)
    config.priority.pkDetect.ringEquipped = widget:getItemId()
  end

  pkContainer.amulet:setItemId(config.priority.pkDetect.amulet)
  pkContainer.amulet.onItemChange = function(widget)
    config.priority.pkDetect.amulet = widget:getItemId()
  end

  pkContainer.amuletEquipped:setItemId(config.priority.pkDetect.amuletEquipped)
  pkContainer.amuletEquipped.onItemChange = function(widget)
    config.priority.pkDetect.amuletEquipped = widget:getItemId()
  end
  setTip(pkContainer.ring, "Ring base da prioridade PK.", "Base ring for PK priority.")
  setTip(pkContainer.ringEquipped, "ID do ring quando equipado (PK).", "Equipped ring ID (PK).")
  setTip(pkContainer.ringLabel, "Descricao do ring da prioridade PK.", "Ring description for PK priority.")
  setTip(pkContainer.amulet, "Amulet base da prioridade PK.", "Base amulet for PK priority.")
  setTip(pkContainer.amuletEquipped, "ID do amulet quando equipado (PK).", "Equipped amulet ID (PK).")
  setTip(pkContainer.amuletLabel, "Descricao do amulet da prioridade PK.", "Amulet description for PK priority.")
  setTip(pkContainer.countScroll, "Quantidade minima de PKs para ativar.", "Minimum PK amount to activate.")
  setTip(pkContainer.countLabel, "Exibe o minimo atual de PKs.", "Shows current PK minimum.")

  pkContainer.countScroll:setValue(config.priority.pkDetect.minPks)
  pkContainer.countLabel:setText('Quantidade minima: ' .. config.priority.pkDetect.minPks .. ' PKs')
  pkContainer.countScroll.onValueChange = function(scroll, value)
    config.priority.pkDetect.minPks = value
    pkContainer.countLabel:setText('Quantidade minima: ' .. value .. ' PKs')
  end

  addCompactSeparator()

  -- ========== PRIORIDADE 3: PLAYER NA TELA ==========
  local playerLabel = g_ui.createWidget('BotLabel', scrollContent)
  playerLabel:setText('Prioridade 3: Player na Tela')
  playerLabel:setColor('#87CEEB')
  setTip(playerLabel, "Troca quando quantidade de players atingir o limite.", "Swap when player count reaches the threshold.")

  local playerCheck = g_ui.createWidget('CategoryCheckBox', scrollContent)
  playerCheck:setText('Detectar Players')
  playerCheck:setChecked(config.priority.playerDetect.enabled)
  setTip(playerCheck, "Liga/desliga a prioridade por players.", "Enable/disable player priority.")
  playerCheck.onClick = function()
    config.priority.playerDetect.enabled = not config.priority.playerDetect.enabled
    playerCheck:setChecked(config.priority.playerDetect.enabled)
  end

  local playerContainer = setupUI([[
Panel
  height: 76

  BotItem
    id: ring
    anchors.left: parent.left
    anchors.top: parent.top
    size: 32 32

  BotItem
    id: ringEquipped
    anchors.left: ring.right
    anchors.top: parent.top
    margin-left: 3
    size: 32 32

  BotLabel
    id: ringLabel
    anchors.left: ringEquipped.right
    anchors.top: parent.top
    anchors.right: parent.horizontalCenter
    margin-left: 3
    margin-top: 4
    text: Ring
    color: #FFFFFF

  BotItem
    id: amulet
    anchors.left: parent.horizontalCenter
    anchors.top: parent.top
    margin-left: 6
    size: 32 32

  BotItem
    id: amuletEquipped
    anchors.left: amulet.right
    anchors.top: parent.top
    margin-left: 3
    size: 32 32

  BotLabel
    id: amuletLabel
    anchors.left: amuletEquipped.right
    anchors.top: parent.top
    anchors.right: parent.right
    margin-left: 3
    margin-top: 4
    text: Amulet
    color: #FFFFFF

  BotLabel
    id: countLabel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: ring.bottom
    margin-top: 3
    text: Quantidade minima: 1 players
    color: #87CEEB
    background-color: #000000
    text-align: center

  HorizontalScrollBar
    id: countScroll
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: countLabel.bottom
    margin-top: 2
    height: 16
    minimum: 1
    maximum: 10
    step: 1
]], scrollContent)

  playerContainer.ring:setItemId(config.priority.playerDetect.ring)
  playerContainer.ring.onItemChange = function(widget)
    config.priority.playerDetect.ring = widget:getItemId()
  end

  playerContainer.ringEquipped:setItemId(config.priority.playerDetect.ringEquipped)
  playerContainer.ringEquipped.onItemChange = function(widget)
    config.priority.playerDetect.ringEquipped = widget:getItemId()
  end

  playerContainer.amulet:setItemId(config.priority.playerDetect.amulet)
  playerContainer.amulet.onItemChange = function(widget)
    config.priority.playerDetect.amulet = widget:getItemId()
  end

  playerContainer.amuletEquipped:setItemId(config.priority.playerDetect.amuletEquipped)
  playerContainer.amuletEquipped.onItemChange = function(widget)
    config.priority.playerDetect.amuletEquipped = widget:getItemId()
  end
  setTip(playerContainer.ring, "Ring base da prioridade Player.", "Base ring for Player priority.")
  setTip(playerContainer.ringEquipped, "ID do ring quando equipado (Player).", "Equipped ring ID (Player).")
  setTip(playerContainer.ringLabel, "Descricao do ring da prioridade Player.", "Ring description for Player priority.")
  setTip(playerContainer.amulet, "Amulet base da prioridade Player.", "Base amulet for Player priority.")
  setTip(playerContainer.amuletEquipped, "ID do amulet quando equipado (Player).", "Equipped amulet ID (Player).")
  setTip(playerContainer.amuletLabel, "Descricao do amulet da prioridade Player.", "Amulet description for Player priority.")
  setTip(playerContainer.countScroll, "Quantidade minima de players para ativar.", "Minimum player amount to activate.")
  setTip(playerContainer.countLabel, "Exibe o minimo atual de players.", "Shows current player minimum.")

  playerContainer.countScroll:setValue(config.priority.playerDetect.minPlayers)
  playerContainer.countLabel:setText('Quantidade minima: ' .. config.priority.playerDetect.minPlayers .. ' players')
  playerContainer.countScroll.onValueChange = function(scroll, value)
    config.priority.playerDetect.minPlayers = value
    playerContainer.countLabel:setText('Quantidade minima: ' .. value .. ' players')
  end

  addCompactSeparator()

  -- ========== PRIORIDADE 4: MONSTRO NA TELA ==========
  local monsterLabel = g_ui.createWidget('BotLabel', scrollContent)
  monsterLabel:setText('Prioridade 4: Monstro na Tela')
  monsterLabel:setColor('#00FF00')
  setTip(monsterLabel, "Troca quando monstros da lista atingirem o minimo.", "Swap when listed monsters reach the minimum.")

  local monsterCheck = g_ui.createWidget('CategoryCheckBox', scrollContent)
  monsterCheck:setText('Detectar Monstros')
  monsterCheck:setChecked(config.priority.monsterDetect.enabled)
  setTip(monsterCheck, "Liga/desliga a prioridade por monstros.", "Enable/disable monster priority.")
  monsterCheck.onClick = function()
    config.priority.monsterDetect.enabled = not config.priority.monsterDetect.enabled
    monsterCheck:setChecked(config.priority.monsterDetect.enabled)
  end

  local monsterContainer = setupUI([[
Panel
  height: 94

  BotItem
    id: ring
    anchors.left: parent.left
    anchors.top: parent.top
    size: 32 32

  BotItem
    id: ringEquipped
    anchors.left: ring.right
    anchors.top: parent.top
    margin-left: 3
    size: 32 32

  BotLabel
    id: ringLabel
    anchors.left: ringEquipped.right
    anchors.top: parent.top
    anchors.right: parent.horizontalCenter
    margin-left: 3
    margin-top: 4
    text: Ring
    color: #FFFFFF

  BotItem
    id: amulet
    anchors.left: parent.horizontalCenter
    anchors.top: parent.top
    margin-left: 6
    size: 32 32

  BotItem
    id: amuletEquipped
    anchors.left: amulet.right
    anchors.top: parent.top
    margin-left: 3
    size: 32 32

  BotLabel
    id: amuletLabel
    anchors.left: amuletEquipped.right
    anchors.top: parent.top
    anchors.right: parent.right
    margin-left: 3
    margin-top: 4
    text: Amulet
    color: #FFFFFF

  Button
    id: manageBtn
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: ring.bottom
    margin-top: 3
    height: 18
    text: Gerenciar Lista de Monstros (0)

  BotLabel
    id: countLabel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: manageBtn.bottom
    margin-top: 3
    text: Quantidade minima: 1 monstros
    color: #87CEEB
    background-color: #000000
    text-align: center

  HorizontalScrollBar
    id: countScroll
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: countLabel.bottom
    margin-top: 2
    height: 16
    minimum: 1
    maximum: 20
    step: 1
]], scrollContent)

  monsterContainer.ring:setItemId(config.priority.monsterDetect.ring)
  monsterContainer.ring.onItemChange = function(widget)
    config.priority.monsterDetect.ring = widget:getItemId()
  end

  monsterContainer.ringEquipped:setItemId(config.priority.monsterDetect.ringEquipped)
  monsterContainer.ringEquipped.onItemChange = function(widget)
    config.priority.monsterDetect.ringEquipped = widget:getItemId()
  end

  monsterContainer.amulet:setItemId(config.priority.monsterDetect.amulet)
  monsterContainer.amulet.onItemChange = function(widget)
    config.priority.monsterDetect.amulet = widget:getItemId()
  end

  monsterContainer.amuletEquipped:setItemId(config.priority.monsterDetect.amuletEquipped)
  monsterContainer.amuletEquipped.onItemChange = function(widget)
    config.priority.monsterDetect.amuletEquipped = widget:getItemId()
  end

  monsterContainer.manageBtn:setText('Gerenciar Lista de Monstros (' .. #config.priority.monsterDetect.monsterList .. ')')
  setTip(monsterContainer.ring, "Ring base da prioridade Monstro.", "Base ring for Monster priority.")
  setTip(monsterContainer.ringEquipped, "ID do ring quando equipado (Monstro).", "Equipped ring ID (Monster).")
  setTip(monsterContainer.ringLabel, "Descricao do ring da prioridade Monstro.", "Ring description for Monster priority.")
  setTip(monsterContainer.amulet, "Amulet base da prioridade Monstro.", "Base amulet for Monster priority.")
  setTip(monsterContainer.amuletEquipped, "ID do amulet quando equipado (Monstro).", "Equipped amulet ID (Monster).")
  setTip(monsterContainer.amuletLabel, "Descricao do amulet da prioridade Monstro.", "Amulet description for Monster priority.")
  setTip(monsterContainer.manageBtn, "Abre a lista de monstros monitorados.", "Open monitored monsters list.")
  setTip(monsterContainer.countScroll, "Quantidade minima de monstros para ativar.", "Minimum monster amount to activate.")
  setTip(monsterContainer.countLabel, "Exibe o minimo atual de monstros.", "Shows current monster minimum.")
  monsterContainer.manageBtn.onClick = function()
    openMonsterListEditor(function()
      monsterContainer.manageBtn:setText('Gerenciar Lista de Monstros (' .. #config.priority.monsterDetect.monsterList .. ')')
    end)
  end

  monsterContainer.countScroll:setValue(config.priority.monsterDetect.minMonsters)
  monsterContainer.countLabel:setText('Quantidade minima: ' .. config.priority.monsterDetect.minMonsters .. ' monstros')
  monsterContainer.countScroll.onValueChange = function(scroll, value)
    config.priority.monsterDetect.minMonsters = value
    monsterContainer.countLabel:setText('Quantidade minima: ' .. value .. ' monstros')
  end
end

openPriorityWindow = function()
  local rootWidget = g_ui.getRootWidget()
  if not priorityWindow then
    priorityWindow = g_ui.createWidget('RingAmuletPriorityWindow', rootWidget)
    priorityWindow.closeButton.onClick = function()
      priorityWindow:hide()
    end

    local scrollWrapper = setupUI([[
Panel
  anchors.fill: parent
  margin: 1
]], priorityWindow.content)

    setupUI([[
VerticalScrollBar
  id: priorityScrollBar
  anchors.top: parent.top
  anchors.bottom: parent.bottom
  anchors.right: parent.right
  step: 28
  pixels-scroll: true
]], scrollWrapper)

    local scrollPanel = setupUI([[
ScrollablePanel
  id: priorityScroll
  anchors.top: parent.top
  anchors.left: parent.left
  anchors.right: priorityScrollBar.left
  anchors.bottom: parent.bottom
  margin-right: 1
  padding: 2
  vertical-scrollbar: priorityScrollBar
  layout:
    type: verticalBox
    spacing: 2
]], scrollWrapper)

    buildPriorityTab(scrollPanel)
    if priorityWindow.closeButton and priorityWindow.closeButton.setTooltip then
      priorityWindow.closeButton:setTooltip("PT: Fecha a janela de Prioridades.\nEN: Closes the Priorities window.")
    end
  end

  priorityWindow:show()
  priorityWindow:raise()
  priorityWindow:focus()
end

-- ============================================
-- ESTILOS CUSTOMIZADOS (UI Definitions)
-- ============================================

g_ui.loadUIFromString([[
EnemyListWindow < MainWindow
  !text: tr('Editor de Lista')
  size: 450 225
  @onEscape: self:destroy()

  Label
    id: infoLabel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text-align: center
    margin-top: 10
    margin-left: 10
    margin-right: 10

  TextEdit
    id: namesInput
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonsPanel.top
    margin: 10

  Panel
    id: buttonsPanel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 40

    Button
      id: saveButton
      text: Salvar
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      width: 100
      margin-left: 10
      margin-bottom: 10

    Button
      id: cancelButton
      text: Cancelar
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      width: 100
      margin-right: 10
      margin-bottom: 10

RingAmuletMainWindow < MainWindow
  !text: tr('Ring/Amulet Setup')
  size: 547 500
  visible: false
  @onEscape: self:hide()

  Panel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: footer.top
    margin-bottom: 4

  Panel
    id: footer
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 30

  BotLabel
    id: delayLabel
    text: Delay (ms)
    anchors.left: parent.left
    anchors.verticalCenter: footer.verticalCenter
    margin-left: 6
    color: #FFFFFF

  SpinBox
    id: delaySpin
    anchors.left: delayLabel.right
    anchors.verticalCenter: footer.verticalCenter
    margin-left: 4
    width: 62
    height: 20
    text-align: center
    background-color: #1a1a2e
    color: #FFFFFF
    border-color: #87CEEB
    minimum: 0
    maximum: 3000
    step: 100
    editable: true
    focusable: true

  Button
    id: priorityBtn
    text: Prioridades
    anchors.left: delaySpin.right
    anchors.verticalCenter: footer.verticalCenter
    margin-left: 4
    size: 92 20

  Button
    id: backpacksBtn
    text: Backpacks
    anchors.left: priorityBtn.right
    anchors.verticalCenter: footer.verticalCenter
    margin-left: 4
    size: 88 20

  Button
    id: helpButton
    text: Ajuda / Help
    anchors.right: closeButton.left
    anchors.verticalCenter: footer.verticalCenter
    margin-right: 6
    size: 95 21

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.verticalCenter: footer.verticalCenter
    size: 60 21
    margin-right: 6

RingAmuletHelpWindow < MainWindow
  !text: tr('Ring/Amulets Help')
  size: 520 395
  visible: false
  @onEscape: self:hide()

  Panel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top

  VerticalScrollBar
    id: helpScroll
    anchors.top: content.top
    anchors.right: content.right
    anchors.bottom: content.bottom
    step: 28
    pixels-scroll: true
    margin-top: 6
    margin-right: 6
    margin-bottom: 6

  ScrollablePanel
    id: helpPanel
    anchors.top: content.top
    anchors.left: content.left
    anchors.right: helpScroll.left
    anchors.bottom: content.bottom
    margin-top: 6
    margin-left: 6
    margin-right: 4
    margin-bottom: 6
    padding: 4
    vertical-scrollbar: helpScroll
    layout:
      type: verticalBox
      spacing: 2

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 60 21
    margin-right: 6
    margin-bottom: 6

RingAmuletPriorityWindow < MainWindow
  !text: tr('Prioridades - Ring/Amulet')
  size: 486 440
  visible: false
  @onEscape: self:hide()

  Panel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 60 21
    margin-right: 6
    margin-bottom: 6

UniversalBpsWindow < MainWindow
  !text: tr('Backpacks by Kelus')
  size: 390 360
  visible: false
  @onEscape: self:hide()

  Panel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: footer.top
    margin-bottom: 4

  Panel
    id: footer
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 30

  Button
    id: helpButton
    text: Ajuda / Help
    anchors.right: closeButton.left
    anchors.verticalCenter: footer.verticalCenter
    margin-right: 6
    size: 95 21

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.verticalCenter: footer.verticalCenter
    size: 60 21
    margin-right: 6

BackpacksHelpWindow < MainWindow
  !text: tr('Backpacks Help')
  size: 480 370
  visible: false
  @onEscape: self:hide()

  Panel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top

  VerticalScrollBar
    id: helpScroll
    anchors.top: content.top
    anchors.right: content.right
    anchors.bottom: content.bottom
    step: 28
    pixels-scroll: true
    margin-top: 6
    margin-right: 6
    margin-bottom: 6

  ScrollablePanel
    id: helpPanel
    anchors.top: content.top
    anchors.left: content.left
    anchors.right: helpScroll.left
    anchors.bottom: content.bottom
    margin-top: 6
    margin-left: 6
    margin-right: 4
    margin-bottom: 6
    padding: 4
    vertical-scrollbar: helpScroll
    layout:
      type: verticalBox
      spacing: 2

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 60 21
    margin-right: 6
    margin-bottom: 6
]])

local function buildUniversalBpStatusText(slotCfg)
  local bpId = tonumber(slotCfg.id or 0) or 0
  local targetItem = tonumber(slotCfg.targetItem or 0) or 0
  if bpId < 100 then
    return "Configure backpack item."
  end

  local opened = 0
  local freeSlots = 0
  for _, container in pairs(getAllContainersSafe()) do
    if getContainerItemIdSafe(container) == bpId then
      opened = opened + 1
      local cap = getContainerCapacitySafe(container)
      local cnt = getContainerItemsCountSafe(container)
      if cap > cnt then
        freeSlots = freeSlots + (cap - cnt)
      end
    end
  end

  if targetItem < 100 then
    return string.format("Open: %d | Free slots: %d", opened, freeSlots)
  end

  return string.format("Open: %d | Free: %d | Item: %d", opened, freeSlots, targetItem)
end

local function updateUniversalBpWindow()
  if not universalBpUi then
    return
  end

  normalizeUniversalBpConfig()

  universalBpUi.stateLabel:setText("Backpacks: " .. (universalBpConfig.enabled and "ON" or "OFF"))
  universalBpUi.stateLabel:setColor(universalBpConfig.enabled and "#9FE36A" or "#FF6B6B")
  setUniversalBpToggleStyle(universalBpUi.enableBtn, "Backpacks", universalBpConfig.enabled)

  for i = 1, UNIVERSAL_BP_SLOT_COUNT do
    local row = universalBpUi.rows[i]
    local slotCfg = universalBpConfig.bpConfigs[i]
    if row and slotCfg then
      if row.slotNameLabel then
        row.slotNameLabel:setText(slotCfg.name or ("Backpack " .. i))
      end
      local bpItemId = tonumber(slotCfg.id or 0) or 0
      local targetItemId = tonumber(slotCfg.targetItem or 0) or 0
      if row.bpItem:getItemId() ~= bpItemId then
        row.bpItem:setItemId(bpItemId)
      end
      if row.targetItem:getItemId() ~= targetItemId then
        row.targetItem:setItemId(targetItemId)
      end
      setUniversalBpToggleStyle(row.autoOpenBtn, "Auto Open", slotCfg.autoOpen)
      setUniversalBpToggleStyle(row.keepSlotBtn, "Keep Slot", slotCfg.keepSlotFree)
      row.statusLabel:setText(buildUniversalBpStatusText(slotCfg))
    end
  end
end

local function buildUniversalBpWindowContent(parent)
  local contentPanel = setupUI([[
Panel
  anchors.fill: parent
  margin: 4
  layout:
    type: verticalBox
    spacing: 3
]], parent)

  local headerRow = setupUI([[
Panel
  height: 18
  layout:
    type: horizontalBox
    spacing: 3
  fit-children: true

  BotLabel
    id: stateLabel
    width: 104
    text: Backpacks: OFF
    color: #FF6B6B

  Button
    id: enableBtn
    width: 106
    height: 17
    text: Backpacks: OFF

  Button
    id: reopenBtn
    width: 106
    height: 17
    text: Reopen Backpacks
]], contentPanel)

  local infoLabel = g_ui.createWidget("BotLabel", contentPanel)
  infoLabel:setText("Configure Backpack and Item to organize.")
  infoLabel:setColor("#87CEEB")

  setupUI([[
Panel
  height: 1
  background-color: #3f3f3f
]], contentPanel)

  local columns = setupUI([[
Panel
  height: 14
  layout:
    type: horizontalBox
    spacing: 3
  fit-children: true

  BotLabel
    width: 30
    text: BP
    color: #FFD700

  BotLabel
    width: 30
    text: Item
    color: #FFD700

  BotLabel
    width: 106
    text: Auto Open
    color: #FFD700

  BotLabel
    width: 106
    text: Keep Slot
    color: #FFD700
]], contentPanel)

  local rows = {}

  for i = 1, UNIVERSAL_BP_SLOT_COUNT do
    local slotIndex = i
    local slotCfg = universalBpConfig.bpConfigs[slotIndex]
    local slotNameLabel = g_ui.createWidget("BotLabel", contentPanel)
    slotNameLabel:setText(slotCfg.name or ("Backpack " .. slotIndex))
    slotNameLabel:setColor("#E8E8E8")
    if slotNameLabel.setTooltip then
      slotNameLabel:setTooltip("PT: Slot de configuracao da Backpack " .. slotIndex .. ".\nEN: Configuration slot for Backpack " .. slotIndex .. ".")
    end

    local row = setupUI([[
Panel
  height: 28
  layout:
    type: horizontalBox
    spacing: 3
  fit-children: true

  BotItem
    id: bpItem
    size: 28 28

  BotItem
    id: targetItem
    size: 28 28

  Button
    id: autoOpenBtn
    width: 106
    height: 17
    text: Auto Open

  Button
    id: keepSlotBtn
    width: 106
    height: 17
    text: Keep Slot
]], contentPanel)

    local statusLabel = g_ui.createWidget("BotLabel", contentPanel)
    statusLabel:setText("Status")
    statusLabel:setColor("#AAAAAA")
    statusLabel:setWidth(344)
    if statusLabel.setTooltip then
      statusLabel:setTooltip("PT: Resumo de backpacks abertas e slots livres.\nEN: Summary of opened backpacks and free slots.")
    end

    row.bpItem.onItemChange = function(widget)
      local entry = universalBpConfig.bpConfigs[slotIndex]
      if not entry then
        return
      end
      entry.id = tonumber(widget:getItemId() or 0) or 0
      updateUniversalBpWindow()
    end

    row.targetItem.onItemChange = function(widget)
      local entry = universalBpConfig.bpConfigs[slotIndex]
      if not entry then
        return
      end
      entry.targetItem = tonumber(widget:getItemId() or 0) or 0
      updateUniversalBpWindow()
    end

    row.autoOpenBtn.onClick = function()
      local entry = universalBpConfig.bpConfigs[slotIndex]
      if not entry then
        return
      end
      entry.autoOpen = not (entry.autoOpen == true)
      updateUniversalBpWindow()
    end

    row.keepSlotBtn.onClick = function()
      local entry = universalBpConfig.bpConfigs[slotIndex]
      if not entry then
        return
      end
      entry.keepSlotFree = not (entry.keepSlotFree == true)
      updateUniversalBpWindow()
    end

    row.bpItem:setTooltip("PT: Backpack para organizar.\nEN: Backpack used as destination.")
    row.targetItem:setTooltip("PT: Item que sera organizado nessa backpack.\nEN: Item that will be organized into this backpack.")
    row.autoOpenBtn:setTooltip("PT: Abre automaticamente a proxima backpack quando necessario.\nEN: Automatically opens the next backpack when needed.")
    row.keepSlotBtn:setTooltip("PT: Mantem 1 slot livre dropando 1 unidade do item alvo.\nEN: Keeps 1 free slot by dropping 1 unit of target item.")

    rows[slotIndex] = {
      slotNameLabel = slotNameLabel,
      bpItem = row.bpItem,
      targetItem = row.targetItem,
      autoOpenBtn = row.autoOpenBtn,
      keepSlotBtn = row.keepSlotBtn,
      statusLabel = statusLabel
    }
  end

  headerRow.enableBtn.onClick = function()
    universalBpConfig.enabled = not (universalBpConfig.enabled == true)
    updateUniversalBpWindow()
  end

  headerRow.reopenBtn.onClick = function()
    forceOpenConfiguredBackpacks()
    updateUniversalBpWindow()
  end

  headerRow.enableBtn:setTooltip("PT: Liga/desliga o sistema Backpacks.\nEN: Enables/disables the Backpacks system.")
  headerRow.reopenBtn:setTooltip("PT: Tenta reabrir todas as BPs configuradas.\nEN: Tries to reopen all configured backpacks.")
  if headerRow.stateLabel and headerRow.stateLabel.setTooltip then
    headerRow.stateLabel:setTooltip("PT: Estado atual do modulo Backpacks.\nEN: Current Backpacks module state.")
  end
  if infoLabel and infoLabel.setTooltip then
    infoLabel:setTooltip("PT: Configure BP alvo e item para organizacao automatica.\nEN: Configure target backpack and item for automatic organization.")
  end
  if columns and columns.setTooltip then
    columns:setTooltip("PT: BP destino, item alvo e opcoes de automacao por slot.\nEN: Destination BP, target item and automation options per slot.")
  end

  universalBpUi = {
    stateLabel = headerRow.stateLabel,
    enableBtn = headerRow.enableBtn,
    reopenBtn = headerRow.reopenBtn,
    rows = rows
  }

  updateUniversalBpWindow()
end

local function buildBackpacksHelpContent(panel)
  if not panel then
    return
  end

  local lines = {
    { text = "PT - Backpacks by Kelus", color = "#FFD700" },
    { text = "1) Backpacks: ON liga o sistema automatico.", color = "#E8E8E8" },
    { text = "2) Backpack Item: arraste a backpack de destino.", color = "#E8E8E8" },
    { text = "3) Item: arraste o item que deseja organizar.", color = "#E8E8E8" },
    { text = "4) Auto Open: abre a proxima backpack quando necessario.", color = "#E8E8E8" },
    { text = "5) Keep Slot: se lotar, dropa 1 item alvo para liberar 1 slot.", color = "#E8E8E8" },
    { text = "6) Reopen Backpacks: tenta reabrir todas as backpacks configuradas.", color = "#E8E8E8" },
    { text = "7) Use os 3 slots (Backpack 1, 2 e 3) para separar itens por tipo.", color = "#E8E8E8" },
    { text = " ", color = "#E8E8E8" },
    { text = "EN - Backpacks by Kelus", color = "#87CEEB" },
    { text = "1) Backpacks: ON enables the automatic system.", color = "#E8E8E8" },
    { text = "2) Backpack Item: drag the destination backpack.", color = "#E8E8E8" },
    { text = "3) Item: drag the item you want to organize.", color = "#E8E8E8" },
    { text = "4) Auto Open: opens the next backpack when needed.", color = "#E8E8E8" },
    { text = "5) Keep Slot: when full, drops 1 target item to free 1 slot.", color = "#E8E8E8" },
    { text = "6) Reopen Backpacks: tries to reopen all configured backpacks.", color = "#E8E8E8" },
    { text = "7) Use all 3 slots (Backpack 1, 2 and 3) to split items by type.", color = "#E8E8E8" }
  }

  for _, line in ipairs(lines) do
    local label = g_ui.createWidget("BotLabel", panel)
    label:setText(line.text)
    label:setColor(line.color or "#E8E8E8")
  end
end

local function buildRingAmuletHelpContent(panel)
  if not panel then
    return
  end

  local lines = {
    { text = "PT - Ring/Amulets Setup", color = "#FFD700" },
    { text = "1) Ring e Amulet: use os toggles ON/OFF no topo para ativar cada modulo.", color = "#E8E8E8" },
    { text = "2) Cada slot aceita dois IDs: Item (mochila) e Equipped (ID quando equipado).", color = "#E8E8E8" },
    { text = "3) Defina ranges de HP/MP por slot; quando entrar no range, o item sera equipado.", color = "#E8E8E8" },
    { text = "4) Prioridades sobrepoem os ranges: Enemy > PK > Players > Monsters.", color = "#E8E8E8" },
    { text = "5) Use a whitelist para ignorar nomes especificos na deteccao de prioridade.", color = "#E8E8E8" },
    { text = "6) Aba Priority: configure itens para cada gatilho (enemy/pk/player/monster).", color = "#E8E8E8" },
    { text = "7) Botao Backpacks: abre o organizador automatico de backpacks (3 setups).", color = "#E8E8E8" },
    { text = "8) Dica: comece com 1 slot por modulo e expanda apos validar em hunt.", color = "#E8E8E8" },
    { text = " ", color = "#E8E8E8" },
    { text = "EN - Ring/Amulets Setup", color = "#87CEEB" },
    { text = "1) Ring and Amulet: use top ON/OFF toggles to enable each module.", color = "#E8E8E8" },
    { text = "2) Each slot supports two IDs: Item (backpack) and Equipped (equipped ID).", color = "#E8E8E8" },
    { text = "3) Set HP/MP ranges per slot; item is equipped when range matches.", color = "#E8E8E8" },
    { text = "4) Priorities override ranges: Enemy > PK > Players > Monsters.", color = "#E8E8E8" },
    { text = "5) Use whitelist to ignore specific names in priority detection.", color = "#E8E8E8" },
    { text = "6) Priority tab: configure items for each trigger (enemy/pk/player/monster).", color = "#E8E8E8" },
    { text = "7) Backpacks button opens the automatic backpack organizer (3 setups).", color = "#E8E8E8" },
    { text = "8) Tip: start with one slot per module and expand after hunt validation.", color = "#E8E8E8" }
  }

  for _, line in ipairs(lines) do
    local label = g_ui.createWidget("BotLabel", panel)
    label:setText(line.text)
    label:setColor(line.color or "#E8E8E8")
  end
end

openRingAmuletHelpWindow = function()
  if not ringAmuletHelpWindow then
    local rootWidget = g_ui.getRootWidget()
    ringAmuletHelpWindow = g_ui.createWidget("RingAmuletHelpWindow", rootWidget)
    souleRingAmuletHelpWindow = ringAmuletHelpWindow
    local helpPanel = ringAmuletHelpWindow.helpPanel or ringAmuletHelpWindow:recursiveGetChildById("helpPanel")
    buildRingAmuletHelpContent(helpPanel)

    ringAmuletHelpWindow.closeButton.onClick = function()
      ringAmuletHelpWindow:hide()
    end
  end

  local helpScroll = ringAmuletHelpWindow.helpScroll or ringAmuletHelpWindow:recursiveGetChildById("helpScroll")
  if helpScroll and helpScroll.setValue then
    helpScroll:setValue(0)
  end

  ringAmuletHelpWindow:show()
  ringAmuletHelpWindow:raise()
  ringAmuletHelpWindow:focus()
end

openBackpacksHelpWindow = function()
  if not backpacksHelpWindow then
    local rootWidget = g_ui.getRootWidget()
    backpacksHelpWindow = g_ui.createWidget("BackpacksHelpWindow", rootWidget)
    souleBackpacksHelpWindow = backpacksHelpWindow
    local helpPanel = backpacksHelpWindow.helpPanel or backpacksHelpWindow:recursiveGetChildById("helpPanel")
    buildBackpacksHelpContent(helpPanel)

    backpacksHelpWindow.closeButton.onClick = function()
      backpacksHelpWindow:hide()
    end
  end

  local helpScroll = backpacksHelpWindow.helpScroll or backpacksHelpWindow:recursiveGetChildById("helpScroll")
  if helpScroll and helpScroll.setValue then
    helpScroll:setValue(0)
  end

  backpacksHelpWindow:show()
  backpacksHelpWindow:raise()
  backpacksHelpWindow:focus()
end

openBackpacksWindow = function()
  if not backpacksWindow then
    local rootWidget = g_ui.getRootWidget()
    backpacksWindow = g_ui.createWidget("UniversalBpsWindow", rootWidget)
    souleUniversalBpsWindow = backpacksWindow
    buildUniversalBpWindowContent(backpacksWindow.content)
    backpacksWindow.closeButton.onClick = function()
      backpacksWindow:hide()
    end
    if backpacksWindow.closeButton and backpacksWindow.closeButton.setTooltip then
      backpacksWindow.closeButton:setTooltip("PT: Fecha a janela Backpacks.\nEN: Closes the Backpacks window.")
    end
    if backpacksWindow.helpButton then
      backpacksWindow.helpButton.onClick = function()
        openBackpacksHelpWindow()
      end
      backpacksWindow.helpButton:setTooltip("PT: Abre o tutorial do sistema Backpacks.\nEN: Opens the Backpacks system tutorial.")
    end
  end

  updateUniversalBpWindow()
  backpacksWindow:show()
  backpacksWindow:raise()
  backpacksWindow:focus()
end

local function buildRingAmuletCombined(panel)
  local scrollWrapper = setupUI([[
Panel
  anchors.fill: parent
  margin: 1
]], panel)

  setupUI([[
VerticalScrollBar
  id: combinedScrollBar
  anchors.top: parent.top
  anchors.bottom: parent.bottom
  anchors.right: parent.right
  step: 28
  pixels-scroll: true
]], scrollWrapper)

  local scrollPanel = setupUI([[
ScrollablePanel
  id: combinedScroll
  anchors.top: parent.top
  anchors.left: parent.left
  anchors.right: combinedScrollBar.left
  anchors.bottom: parent.bottom
  margin-right: 0
  padding: 1
  vertical-scrollbar: combinedScrollBar
  layout:
    type: verticalBox
    spacing: 1
]], scrollWrapper)

  local profiles = ensureRingProfiles()

  local profileLabel = g_ui.createWidget('BotLabel', scrollPanel)
  profileLabel:setText('Perfis Ring/Amulet')
  profileLabel:setColor('#E8E8E8')

  local profileRow = setupUI([[
Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 2
  fit-children: true

  ComboBox
    id: profilesCombo
    width: 170
    height: 18
    margin: 0
    font: verdana-11px-rounded

  TextEdit
    id: nameInput
    height: 18
    width: 110
    placeholder: Nome
    font: verdana-11px-rounded

  Button
    id: newBtn
    width: 42
    height: 18
    text: New

  Button
    id: deleteBtn
    width: 46
    height: 18
    text: Delete

  Button
    id: saveBtn
    width: 42
    height: 18
    text: Save
]], scrollPanel)

  profileRow.nameInput:setTooltip("PT: Digite um nome para o novo perfil.\nEN: Enter a name for the new profile.")
  profileRow.newBtn:setTooltip("PT: Cria um novo perfil com esse nome.\nEN: Create a new profile with this name.")
  profileRow.deleteBtn:setTooltip("PT: Remove o perfil atual selecionado.\nEN: Remove the currently selected profile.")
  profileRow.saveBtn:setTooltip("PT: Salva toda a configuracao atual (Setup + Prioridades).\nEN: Save the full current setup (Setup + Priorities).")

  local function renderProfileList()
    profiles = ensureRingProfiles()
    local combo = profileRow.profilesCombo
    combo:clearOptions()
    local selectedIndex = 1
    local activeId = getSelectedRingProfileId()
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

      local previousId = getSelectedRingProfileId()
      if previousId ~= option.data then
        saveRingProfileState(previousId)
      end

      setRingActiveProfile(profiles, option.data)
      applyRingProfileState(option.data)
      scheduleRingAmuletUiRefresh()
    end
  end

  profileRow.newBtn.onClick = function()
    local currentId = getSelectedRingProfileId()
    saveRingProfileState(currentId)

    local id = addRingProfile(profileRow.nameInput:getText())
    if not id then
      warn('[Ring/Amulet] Nome de perfil invalido.')
      return
    end

    profileRow.nameInput:setText("")
    applyRingProfileState(id)
    showRingProfileMessage('Perfil criado: ' .. getRingProfileName(id), '#00FF00')
    scheduleRingAmuletUiRefresh()
  end

  profileRow.deleteBtn.onClick = function()
    local currentId = getSelectedRingProfileId()
    if not currentId or currentId == "" then
      return
    end

    local updated = ensureRingProfiles()
    for i = #updated.order, 1, -1 do
      if updated.order[i] == currentId then
        table.remove(updated.order, i)
        break
      end
    end
    updated.configs[currentId] = nil

    if #updated.order == 0 then
      updated.configs["cfg_1"] = updated.configs["cfg_1"] or { name = "Config 1", data = captureRingProfileState() }
      normalizeRingAmuletData(updated.configs["cfg_1"].data)
      table.insert(updated.order, "cfg_1")
      if updated.nextId < 2 then
        updated.nextId = 2
      end
    end

    local nextId = setRingActiveProfile(updated, updated.meta.activeProfile)
    applyRingProfileState(nextId)
    showRingProfileMessage('Perfil removido.', '#FF0000')
    scheduleRingAmuletUiRefresh()
  end

  profileRow.saveBtn.onClick = function()
    local currentId = getSelectedRingProfileId()
    if not currentId or currentId == "" then
      return
    end
    saveRingProfileState(currentId)
    showRingProfileMessage('Perfil salvo: ' .. getRingProfileName(currentId), '#00FF00')
  end

  renderProfileList()
  local currentId = getSelectedRingProfileId()
  if currentId ~= "" then
    local stored = ensureRingProfiles()
    if type(stored.configs[currentId]) ~= "table" or type(stored.configs[currentId].data) ~= "table" then
      saveRingProfileState(currentId)
    end
  end

  setupUI([[
Panel
  height: 1
  background-color: #3f3f3f
]], scrollPanel)

  local titleRow = setupUI([[
Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 0
]], scrollPanel)

  local ringTitlePanel = setupUI([[
Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 2

  BotLabel
    id: title
    text: Rings
    color: #FFD700

  SmallBotSwitch
    id: toggle
    width: 34
    height: 18
    text-align: center
    text: ON
]], titleRow)

  local amuletTitlePanel = setupUI([[
Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 2

  BotLabel
    id: title
    text: Amulets
    color: #FFD700

  SmallBotSwitch
    id: toggle
    width: 34
    height: 18
    text-align: center
    text: ON
]], titleRow)

  local function setRingToggleState(enabled)
    ringTitlePanel.toggle:setOn(enabled)
    ringTitlePanel.toggle:setText(enabled and "ON" or "OFF")
  end
  if ringTitlePanel.title and ringTitlePanel.title.setTooltip then
    ringTitlePanel.title:setTooltip("PT: Estado global do modulo Rings.\nEN: Global state for Rings module.")
  end
  if ringTitlePanel.toggle and ringTitlePanel.toggle.setTooltip then
    ringTitlePanel.toggle:setTooltip("PT: Liga/desliga o modulo Rings.\nEN: Enables/disables Rings module.")
  end
  ringHeaderToggleRef = ringTitlePanel.toggle
  setRingToggleState(isRingModuleEnabled())
  ringTitlePanel.toggle.onClick = function()
    setRingModuleEnabled(not isRingModuleEnabled())
    refreshRingAmuletHeaderToggles()
  end

  local function setAmuletToggleState(enabled)
    amuletTitlePanel.toggle:setOn(enabled)
    amuletTitlePanel.toggle:setText(enabled and "ON" or "OFF")
  end
  if amuletTitlePanel.title and amuletTitlePanel.title.setTooltip then
    amuletTitlePanel.title:setTooltip("PT: Estado global do modulo Amulets.\nEN: Global state for Amulets module.")
  end
  if amuletTitlePanel.toggle and amuletTitlePanel.toggle.setTooltip then
    amuletTitlePanel.toggle:setTooltip("PT: Liga/desliga o modulo Amulets.\nEN: Enables/disables Amulets module.")
  end
  amuletHeaderToggleRef = amuletTitlePanel.toggle
  setAmuletToggleState(isAmuletModuleEnabled())
  amuletTitlePanel.toggle.onClick = function()
    setAmuletModuleEnabled(not isAmuletModuleEnabled())
    refreshRingAmuletHeaderToggles()
  end

  local slotRows = {}

  for slotIndex = 1, 5 do
    if slotIndex > 1 then
      setupUI([[
Panel
  height: 1
  background-color: #3f3f3f
]], scrollPanel)
    end
    local rowPanel = setupUI([[
Panel
  height: 68
  layout:
    type: horizontalBox
    spacing: 0
]], scrollPanel)

    local ringCell = setupUI([[
Panel
  height: 68
  layout:
    type: verticalBox
    spacing: 0
]], rowPanel)

    local amuletCell = setupUI([[
Panel
  height: 68
  layout:
    type: verticalBox
    spacing: 0
]], rowPanel)

    buildRingSlot(ringCell, slotIndex)
    buildAmuletSlot(amuletCell, slotIndex)
    slotRows[#slotRows + 1] = {row = rowPanel, left = ringCell, right = amuletCell}
  end

  local function syncLayout()
    local totalW = scrollPanel:getWidth() or 0
    if totalW > 0 then
      local innerW = totalW
      local colW = math.floor(innerW / 2)
      ringTitlePanel:setWidth(colW)
      amuletTitlePanel:setWidth(colW)
      titleRow:setWidth(innerW)
      for _, entry in ipairs(slotRows) do
        entry.row:setWidth(innerW)
        entry.left:setWidth(colW)
        entry.right:setWidth(colW)
      end
    end
  end

  syncLayout()
  if schedule then
    schedule(10, syncLayout)
    schedule(100, syncLayout)
  end
  scrollPanel.onGeometryChange = syncLayout
end

createSetupWindow = function()
  local rootWidget = g_ui.getRootWidget()
  setupWindow = g_ui.createWidget('RingAmuletMainWindow', rootWidget)
  buildRingAmuletCombined(setupWindow.content)

  if setupWindow.delaySpin then
    setupWindow.delaySpin:setValue(config.swapDelay or 1000)
    setupWindow.delaySpin.onValueChange = function()
      config.swapDelay = setupWindow.delaySpin:getValue()
    end
    if setupWindow.delaySpin.setTooltip then
      setupWindow.delaySpin:setTooltip("PT: Delay minimo entre trocas/equips automaticos (ms).\nEN: Minimum delay between automatic swaps/equips (ms).")
    end
  end

  if setupWindow.delayLabel and setupWindow.delayLabel.setTooltip then
    setupWindow.delayLabel:setTooltip("PT: Define o delay global de troca do modulo.\nEN: Defines the module global swap delay.")
  end

  if setupWindow.priorityBtn then
    setupWindow.priorityBtn.onClick = function()
      if priorityWindow then
        priorityWindow:show()
        priorityWindow:raise()
        priorityWindow:focus()
      else
        openPriorityWindow()
      end
    end
    setupWindow.priorityBtn:setTooltip("PT: Abre configuracao de prioridades de troca.\nEN: Opens swap priorities setup.")
  end

  if setupWindow.backpacksBtn then
    setupWindow.backpacksBtn.onClick = function()
      openBackpacksWindow()
    end
    setupWindow.backpacksBtn:setTooltip("PT: Abre a janela Backpacks.\nEN: Opens the Backpacks window.")
  end

  setupWindow.closeButton.onClick = function()
    setupWindow:hide()
  end
  if setupWindow.closeButton and setupWindow.closeButton.setTooltip then
    setupWindow.closeButton:setTooltip("PT: Fecha a janela de configuracao Ring/Amulet.\nEN: Closes Ring/Amulet setup window.")
  end
  if setupWindow.helpButton then
    setupWindow.helpButton.onClick = function()
      openRingAmuletHelpWindow()
    end
    setupWindow.helpButton:setTooltip("PT: Abre o tutorial de Ring/Amulets.\nEN: Opens the Ring/Amulets tutorial.")
  end

  setupWindow:show()
  setupWindow:raise()
  setupWindow:focus()
end

-- Conectar botão Setup
mainUI.setupBtn.onClick = function()
  if setupWindow then
    setupWindow:show()
    setupWindow:raise()
    setupWindow:focus()
  else
    createSetupWindow()
  end
end

-- ============================================
-- MACRO PRINCIPAL
-- ============================================

local function isRangeConfigured(minValue, maxValue)
  local minNum = tonumber(minValue) or 0
  local maxNum = tonumber(maxValue) or 100
  return minNum > 0 or maxNum < 100
end

local function slotMatchesThreshold(slotConfig, hpPercent, mpPercent)
  local hpMin = tonumber(slotConfig.hpMin) or 0
  local hpMax = tonumber(slotConfig.hpMax) or 100
  local mpMin = tonumber(slotConfig.mpMin) or 0
  local mpMax = tonumber(slotConfig.mpMax) or 100

  local hpOk = (hpPercent >= hpMin and hpPercent <= hpMax)
  local mpOk = (mpPercent >= mpMin and mpPercent <= mpMax)
  local hpConfigured = isRangeConfigured(hpMin, hpMax)
  local mpConfigured = isRangeConfigured(mpMin, mpMax)

  if hpConfigured and mpConfigured then
    return hpOk or mpOk
  elseif hpConfigured then
    return hpOk
  elseif mpConfigured then
    return mpOk
  end

  return hpOk or mpOk
end

local lastHotkeyEquipAttemptBySlot = {
  [SlotFinger] = 0,
  [SlotNeck] = 0
}

local function buildEquipCandidateIds(primaryId, equippedId)
  local ids = {}
  local seen = {}

  local function addId(rawId)
    local itemId = tonumber(rawId) or 0
    if itemId > 0 and not seen[itemId] then
      seen[itemId] = true
      table.insert(ids, itemId)
    end
  end

  addId(primaryId)
  addId(equippedId)
  return ids
end

local function tryEquipAccessory(primaryId, equippedId, slotId, swapDelay)
  local candidateIds = buildEquipCandidateIds(primaryId, equippedId)
  if #candidateIds == 0 then
    return false
  end

  if type(findItem) == "function" then
    for _, itemId in ipairs(candidateIds) do
      local item = findItem(itemId)
      if item then
        g_game.move(item, {x = 65535, y = slotId, z = 0}, 1)
        return true
      end
    end
  end

  if g_game and type(g_game.useInventoryItem) == "function" then
    local nowMs = nowMsUniversal()
    local lastAttempt = tonumber(lastHotkeyEquipAttemptBySlot[slotId]) or 0
    if (nowMs - lastAttempt) >= math.max(60, tonumber(swapDelay) or 1000) then
      for _, itemId in ipairs(candidateIds) do
        local ok = pcall(function()
          g_game.useInventoryItem(itemId)
        end)
        if ok then
          lastHotkeyEquipAttemptBySlot[slotId] = nowMs
          return true
        end
      end
    end
  end

  return false
end

macro(100, function()
  if not g_game or not g_game.move then return end
  if g_game and g_game.isOnline and not g_game.isOnline() then return end
  local ringEnabled = isRingModuleEnabled()
  local amuletEnabled = isAmuletModuleEnabled()
  if not ringEnabled and not amuletEnabled then return end
  local swapDelay = math.max(60, tonumber(config.swapDelay) or 1000)

  local fingerItem = getInventoryItem(SlotFinger)
  local fingerId = fingerItem and fingerItem:getId() or 0
  local neckItem = getInventoryItem(SlotNeck)
  local neckId = neckItem and neckItem:getId() or 0
  local hpPercent = hppercent()
  local mpPercent = manapercent()

  local targetRingId = nil
  local targetAmuletId = nil
  local targetRingIdEquipped = nil
  local targetAmuletIdEquipped = nil

  -- ========== VERIFICAR PRIORIDADES (SOBREPOE HP/MP) ==========

  -- PRIORIDADE 1: Enemy na tela
  if config.priority.enemyDetect.enabled and hasEnemyOnScreen() then
    if ringEnabled and config.priority.enemyDetect.ring > 0 then
      targetRingId = config.priority.enemyDetect.ring
      targetRingIdEquipped = (config.priority.enemyDetect.ringEquipped and config.priority.enemyDetect.ringEquipped > 0) and config.priority.enemyDetect.ringEquipped or config.priority.enemyDetect.ring
    end
    if amuletEnabled and config.priority.enemyDetect.amulet > 0 then
      targetAmuletId = config.priority.enemyDetect.amulet
      targetAmuletIdEquipped = (config.priority.enemyDetect.amuletEquipped and config.priority.enemyDetect.amuletEquipped > 0) and config.priority.enemyDetect.amuletEquipped or config.priority.enemyDetect.amulet
    end
  end

  -- PRIORIDADE 2: PK na tela
  if not targetRingId and not targetAmuletId then
    if config.priority.pkDetect.enabled and countPksOnScreen() >= config.priority.pkDetect.minPks then
      if ringEnabled and config.priority.pkDetect.ring > 0 then
        targetRingId = config.priority.pkDetect.ring
        targetRingIdEquipped = (config.priority.pkDetect.ringEquipped and config.priority.pkDetect.ringEquipped > 0) and config.priority.pkDetect.ringEquipped or config.priority.pkDetect.ring
      end
      if amuletEnabled and config.priority.pkDetect.amulet > 0 then
        targetAmuletId = config.priority.pkDetect.amulet
        targetAmuletIdEquipped = (config.priority.pkDetect.amuletEquipped and config.priority.pkDetect.amuletEquipped > 0) and config.priority.pkDetect.amuletEquipped or config.priority.pkDetect.amulet
      end
    end
  end

  -- PRIORIDADE 3: Player na tela
  if not targetRingId and not targetAmuletId then
    if config.priority.playerDetect.enabled and countPlayersOnScreen() >= config.priority.playerDetect.minPlayers then
      if ringEnabled and config.priority.playerDetect.ring > 0 then
        targetRingId = config.priority.playerDetect.ring
        targetRingIdEquipped = (config.priority.playerDetect.ringEquipped and config.priority.playerDetect.ringEquipped > 0) and config.priority.playerDetect.ringEquipped or config.priority.playerDetect.ring
      end
      if amuletEnabled and config.priority.playerDetect.amulet > 0 then
        targetAmuletId = config.priority.playerDetect.amulet
        targetAmuletIdEquipped = (config.priority.playerDetect.amuletEquipped and config.priority.playerDetect.amuletEquipped > 0) and config.priority.playerDetect.amuletEquipped or config.priority.playerDetect.amulet
      end
    end
  end

  -- PRIORIDADE 4: Monstro na tela
  if not targetRingId and not targetAmuletId then
    if config.priority.monsterDetect.enabled and countMonstersOnScreen() >= config.priority.monsterDetect.minMonsters then
      if ringEnabled and config.priority.monsterDetect.ring > 0 then
        targetRingId = config.priority.monsterDetect.ring
        targetRingIdEquipped = (config.priority.monsterDetect.ringEquipped and config.priority.monsterDetect.ringEquipped > 0) and config.priority.monsterDetect.ringEquipped or config.priority.monsterDetect.ring
      end
      if amuletEnabled and config.priority.monsterDetect.amulet > 0 then
        targetAmuletId = config.priority.monsterDetect.amulet
        targetAmuletIdEquipped = (config.priority.monsterDetect.amuletEquipped and config.priority.monsterDetect.amuletEquipped > 0) and config.priority.monsterDetect.amuletEquipped or config.priority.monsterDetect.amulet
      end
    end
  end

  -- ========== SE NAO TEM PRIORIDADE ATIVA, USAR SISTEMA HP/MP ==========

  if ringEnabled and not targetRingId then
    -- Determinar qual ring deve estar equipado (slots 1 a 5)
    for slotIndex = 1, 5 do
      local slotConfig = config.rings[slotIndex]

      if slotConfig and slotConfig.itemId and slotConfig.itemId > 0 then
        if slotMatchesThreshold(slotConfig, hpPercent, mpPercent) then
          targetRingId = slotConfig.itemId
          targetRingIdEquipped = (slotConfig.itemIdEquipped and slotConfig.itemIdEquipped > 0) and slotConfig.itemIdEquipped or slotConfig.itemId
          break
        end
      end
    end
  end

  if amuletEnabled and not targetAmuletId then
    -- Determinar qual amulet deve estar equipado (slots 1 a 5)
    for slotIndex = 1, 5 do
      local slotConfig = config.amulets[slotIndex]

      if slotConfig and slotConfig.itemId and slotConfig.itemId > 0 then
        if slotMatchesThreshold(slotConfig, hpPercent, mpPercent) then
          targetAmuletId = slotConfig.itemId
          targetAmuletIdEquipped = (slotConfig.itemIdEquipped and slotConfig.itemIdEquipped > 0) and slotConfig.itemIdEquipped or slotConfig.itemId
          break
        end
      end
    end
  end

  -- ========== EQUIPAR RING ==========
  if ringEnabled then
    if targetRingId then
      -- Se JA esta com um dos dois IDs equipados, NAO FAZ NADA
      if fingerId == targetRingId or fingerId == targetRingIdEquipped then
        -- Ja equipado corretamente, nao fazer nada
      else
        -- Nao esta equipado, buscar e equipar (com fallback para itemId alternativo/hotkey)
        if tryEquipAccessory(targetRingId, targetRingIdEquipped, SlotFinger, swapDelay) then
          delay(swapDelay)
          return
        else
          -- Item alvo indisponivel: remove ring atual para nao manter item fora do range.
          if fingerItem then
            local freePos = getFirstFreeContainerPos()
            if freePos then
              g_game.move(fingerItem, freePos, 1)
              delay(swapDelay)
              return
            end
          end
        end
      end
    else
      -- Nenhum ring casou: unequip se houver algo equipado
      if fingerItem then
        local freePos = getFirstFreeContainerPos()
        if freePos then
          g_game.move(fingerItem, freePos, 1)
          delay(swapDelay)
          return
        end
      end
    end
  end

  -- ========== EQUIPAR AMULET ==========
  if amuletEnabled then
    if targetAmuletId then
      -- Se JA esta com um dos dois IDs equipados, NAO FAZ NADA
      if neckId == targetAmuletId or neckId == targetAmuletIdEquipped then
        -- Ja equipado corretamente, nao fazer nada
      else
        -- Nao esta equipado, buscar e equipar (com fallback para itemId alternativo/hotkey)
        if tryEquipAccessory(targetAmuletId, targetAmuletIdEquipped, SlotNeck, swapDelay) then
          delay(swapDelay)
          return
        else
          -- Item alvo indisponivel: remove amulet atual para nao manter item fora do range.
          if neckItem then
            local freePos = getFirstFreeContainerPos()
            if freePos then
              g_game.move(neckItem, freePos, 1)
              delay(swapDelay)
              return
            end
          end
        end
      end
    else
      -- Nenhum amulet casou: unequip se houver algo equipado
      if neckItem then
        local freePos = getFirstFreeContainerPos()
        if freePos then
          g_game.move(neckItem, freePos, 1)
          delay(swapDelay)
          return
        end
      end
    end
  end
end)

macro(450, function()
  runUniversalBpCycle()
end)

macro(1000, function()
  if backpacksWindow and backpacksWindow:isVisible() then
    updateUniversalBpWindow()
  end
end)

-- ============================================
-- MENSAGEM DE CARREGAMENTO
-- ============================================

modules.game_textmessage.displayGameMessage("[Ring/Amulet Setup] Sistema carregado! Configure Rings/Amulets e use o botao Backpacks.")


end

-- Analyzer HUD (EXP session tracker)
-- Keeps the analyzer calculations and migrates visual output to map HUD style.

if souleAnalyzerHud and souleAnalyzerHud.destroy then
    souleAnalyzerHud:destroy()
    souleAnalyzerHud = nil
end

if souleAnalyzerMainUI and souleAnalyzerMainUI.destroy then
    souleAnalyzerMainUI:destroy()
    souleAnalyzerMainUI = nil
end

if souleAnalyzerOthersWindow and souleAnalyzerOthersWindow.destroy then
    souleAnalyzerOthersWindow:destroy()
    souleAnalyzerOthersWindow = nil
end

if souleAnalyzerHelpWindow and souleAnalyzerHelpWindow.destroy then
    souleAnalyzerHelpWindow:destroy()
    souleAnalyzerHelpWindow = nil
end

souleAnalyzerHudRuntime = {}

local POT_EXP_SLOT_COUNT = 20
local POT_EXP_ROW_SIZE = 10
local POT_EXP_ROW_COUNT = math.floor(POT_EXP_SLOT_COUNT / POT_EXP_ROW_SIZE)
local DEFAULT_DEATH_LOGOUT = 5
local DEFAULT_KILL_LIMIT = 50
local ANALYZER_ITEM_COUNTER_SLOTS = 3
local ANALYZER_ITEM_COUNTER_INTERVAL_MINUTES = 1

local function getAnalyzerInitialLevel()
    if player and type(player.getLevel) == "function" then
        local ok, value = pcall(function()
            return player:getLevel()
        end)
        if ok and type(value) == "number" then
            return value
        end
    end
    if type(level) == "function" then
        local ok, value = pcall(level)
        if ok and type(value) == "number" then
            return value
        end
    end
    return 0
end

local function getAnalyzerInitialExp()
    if type(exp) == "function" then
        local ok, value = pcall(exp)
        if ok and type(value) == "number" then
            return value
        end
    end
    if player and type(player.getExperience) == "function" then
        local ok, value = pcall(function()
            return player:getExperience()
        end)
        if ok and type(value) == "number" then
            return value
        end
    end
    return 0
end

if type(storage.analyzer) ~= "table" then
    storage.analyzer = {
        enabled = false,
        session = {
            startTime = os.time(),
            initialLevel = getAnalyzerInitialLevel(),
            initialExp = getAnalyzerInitialExp(),
            totalExpGained = 0,
            lastExpGain = 0,
            expHistory = {}
        }
    }
end

local cfg = storage.analyzer

local function dropNonStringKeys(tbl)
    if type(tbl) ~= "table" then
        return
    end
    for key, _ in pairs(tbl) do
        if type(key) ~= "string" then
            tbl[key] = nil
        end
    end
end

dropNonStringKeys(cfg)

if not cfg.session then
    cfg.session = {
        startTime = os.time(),
        initialLevel = getAnalyzerInitialLevel(),
        initialExp = getAnalyzerInitialExp(),
        totalExpGained = 0,
        lastExpGain = 0,
        expHistory = {}
    }
end
dropNonStringKeys(cfg.session)

if not cfg.session.expHistory then
    cfg.session.expHistory = {}
end
local expHistory = {}
for _, entry in ipairs(type(cfg.session.expHistory) == "table" and cfg.session.expHistory or {}) do
    if type(entry) == "table" then
        expHistory[#expHistory + 1] = entry
    end
end
cfg.session.expHistory = expHistory

if not cfg.hud then
    cfg.hud = {
        showSkills = true,
        compact = false
    }
end
dropNonStringKeys(cfg.hud)

if cfg.hud.showSkills == nil then
    cfg.hud.showSkills = true
end

if cfg.hud.compact == nil then
    cfg.hud.compact = false
end

if cfg.hud.collapsed == nil then
    cfg.hud.collapsed = false
end

if cfg.hud.posX == nil then
    cfg.hud.posX = 18
end

if cfg.hud.posY == nil then
    cfg.hud.posY = 120
end

cfg.hud.posX = math.max(0, math.min(5000, tonumber(cfg.hud.posX) or 18))
cfg.hud.posY = math.max(0, math.min(5000, tonumber(cfg.hud.posY) or 120))
cfg.hud.collapsed = cfg.hud.collapsed == true
cfg.hud.waveStep = math.max(0, tonumber(cfg.hud.waveStep or 0) or 0)
cfg.hud._hudContent = nil
cfg.hud._hudMarks = nil
cfg.hud.applyAnalyzerHudPosition = nil
cfg.hud.refreshAnalyzerHudWave = nil
cfg.hud._hudPosUiSyncing = nil

if not cfg.potExp then
    cfg.potExp = {
        enabled = false,
        delayMinutes = 1,
        useInPz = false,
        onlyNoTarget = false,
        onlyNoMonsters = false,
        useMode = "AUTO",
        items = {},
        lastUseMs = 0,
        lastTryMs = 0,
        nextItemIndex = 1,
        pendingUse = false
    }
end
dropNonStringKeys(cfg.potExp)

if type(cfg.potExp.items) ~= "table" then
    cfg.potExp.items = {}
end

local normalizedPotItems = {}
for i = 1, POT_EXP_SLOT_COUNT do
    local rawItemId = cfg.potExp.items[i]
    if rawItemId == nil then
        rawItemId = cfg.potExp.items[tostring(i)]
    end
    local itemId = tonumber(rawItemId or 0) or 0
    normalizedPotItems[i] = itemId
end
cfg.potExp.items = normalizedPotItems

cfg.potExp.delayMinutes = math.max(1, math.min(120, tonumber(cfg.potExp.delayMinutes or 1) or 1))
cfg.potExp.useInPz = cfg.potExp.useInPz == true
cfg.potExp.onlyNoTarget = cfg.potExp.onlyNoTarget == true
cfg.potExp.onlyNoMonsters = cfg.potExp.onlyNoMonsters == true
cfg.potExp.enabled = cfg.potExp.enabled == true
cfg.potExp.lastUseMs = tonumber(cfg.potExp.lastUseMs or 0) or 0
cfg.potExp.lastTryMs = tonumber(cfg.potExp.lastTryMs or 0) or 0
cfg.potExp.nextItemIndex = math.max(1, tonumber(cfg.potExp.nextItemIndex or 1) or 1)
cfg.potExp.pendingUse = cfg.potExp.pendingUse == true

if cfg.potExp.useMode ~= "AUTO" and cfg.potExp.useMode ~= "USE" and cfg.potExp.useMode ~= "SELF" then
    cfg.potExp.useMode = "AUTO"
end

local function normalizeItemCounterSlotData(rawSlot)
    local slot = rawSlot
    if type(slot) ~= "table" then
        if type(slot) == "number" or type(slot) == "string" then
            slot = { itemId = slot }
        else
            slot = {}
        end
    end

    local itemId = math.floor(tonumber(slot.itemId or slot.id or slot.item or slot.targetItem or 0) or 0)
    if itemId < 100 then
        itemId = 0
    elseif itemId > 65535 then
        itemId = 65535
    end

    local displayName = tostring(slot.displayName or slot.name or slot.label or "")
    displayName = displayName:gsub("^%s+", ""):gsub("%s+$", "")
    if #displayName > 24 then
        displayName = displayName:sub(1, 24)
    end

    local showOnHud = slot.showOnHud
    if showOnHud == nil then
        showOnHud = slot.hud
    end
    if showOnHud == nil then
        showOnHud = true
    else
        showOnHud = showOnHud == true
    end

    local count = tonumber(slot.count or 0) or 0
    local previousCount = tonumber(slot.previousCount or slot.lastCount or count) or count

    return {
        itemId = itemId,
        count = count,
        previousCount = previousCount,
        delta = tonumber(slot.delta or 0) or 0,
        ready = slot.ready == true,
        lastUpdateMs = tonumber(slot.lastUpdateMs or 0) or 0,
        showOnHud = showOnHud,
        displayName = displayName
    }
end

local function readLegacyItemCounterSlot(container, index)
    if type(container) ~= "table" then
        return nil
    end

    local function firstNonNil(...)
        local args = {...}
        local maxIndex = 0
        for key, _ in pairs(args) do
            if type(key) == "number" and key > maxIndex then
                maxIndex = key
            end
        end
        for argIndex = 1, maxIndex do
            local value = args[argIndex]
            if value ~= nil then
                return value
            end
        end
        return nil
    end

    local direct = firstNonNil(
        container["itemCounter" .. index],
        container["counter" .. index],
        container["slot" .. index]
    )
    if direct ~= nil then
        return direct
    end

    local itemId = firstNonNil(
        container["itemCounter" .. index .. "ItemId"],
        container["itemCounter" .. index .. "Item"],
        container["counter" .. index .. "ItemId"],
        container["counter" .. index .. "Item"],
        container["slot" .. index .. "ItemId"],
        container["slot" .. index .. "Item"]
    )

    local displayName = firstNonNil(
        container["itemCounter" .. index .. "Name"],
        container["counter" .. index .. "Name"],
        container["slot" .. index .. "Name"]
    )

    local showOnHud = firstNonNil(
        container["itemCounter" .. index .. "ShowOnHud"],
        container["itemCounter" .. index .. "Hud"],
        container["counter" .. index .. "ShowOnHud"],
        container["counter" .. index .. "Hud"],
        container["slot" .. index .. "ShowOnHud"],
        container["slot" .. index .. "Hud"]
    )

    if itemId ~= nil or displayName ~= nil or showOnHud ~= nil then
        return {
            itemId = itemId,
            displayName = displayName,
            showOnHud = showOnHud
        }
    end

    return nil
end

if type(cfg.itemCounters) ~= "table" then
    cfg.itemCounters = {
        intervalMinutes = ANALYZER_ITEM_COUNTER_INTERVAL_MINUTES,
        nextScanMs = 0,
        slots = {}
    }
end

if type(cfg.itemCounters.slots) ~= "table" then
    cfg.itemCounters.slots = {}
end

local counterIntervalMinutes = ANALYZER_ITEM_COUNTER_INTERVAL_MINUTES
local counterNextScanMs = tonumber(cfg.itemCounters.nextScanMs or 0) or 0

local rawCounterSlots = cfg.itemCounters.slots
local normalizedCounterSlots = {}
for i = 1, ANALYZER_ITEM_COUNTER_SLOTS do
    local slot = rawCounterSlots[i]
    if slot == nil then
        slot = rawCounterSlots[tostring(i)]
    end
    if slot == nil then
        slot = rawCounterSlots[i - 1]
    end
    if slot == nil then
        slot = rawCounterSlots[tostring(i - 1)]
    end
    if slot == nil then
        slot = readLegacyItemCounterSlot(rawCounterSlots, i)
    end
    if slot == nil then
        slot = readLegacyItemCounterSlot(cfg.itemCounters, i)
    end
    if slot == nil then
        slot = readLegacyItemCounterSlot(cfg, i)
    end
    normalizedCounterSlots[i] = normalizeItemCounterSlotData(slot)
end

for i = 1, ANALYZER_ITEM_COUNTER_SLOTS do
    cfg["itemCounter" .. i] = nil
    cfg["itemCounter" .. i .. "ItemId"] = nil
    cfg["itemCounter" .. i .. "Item"] = nil
    cfg["itemCounter" .. i .. "Name"] = nil
    cfg["itemCounter" .. i .. "ShowOnHud"] = nil
    cfg["itemCounter" .. i .. "Hud"] = nil

    cfg.itemCounters["itemCounter" .. i] = nil
    cfg.itemCounters["counter" .. i] = nil
    cfg.itemCounters["slot" .. i] = nil
    cfg.itemCounters[i] = nil
    cfg.itemCounters[tostring(i)] = nil
    cfg.itemCounters[i - 1] = nil
    cfg.itemCounters[tostring(i - 1)] = nil
end
cfg.itemCounters = {
    intervalMinutes = counterIntervalMinutes,
    nextScanMs = counterNextScanMs,
    slots = normalizedCounterSlots
}

if type(storage.death) ~= "table" then
    storage.death = { count = 0 }
end

if type(storage.death.count) ~= "number" then
    storage.death.count = tonumber(storage.death.count) or 0
end

if type(storage.kill) ~= "table" then
    storage.kill = { count = 0 }
end

if type(storage.kill.count) ~= "number" then
    storage.kill.count = tonumber(storage.kill.count) or 0
end

if not cfg.deathCounter then
    cfg.deathCounter = {
        enabled = true,
        logoutDeaths = DEFAULT_DEATH_LOGOUT,
        actionLogout = true,
        actionDisableBots = false,
        actionForceExit = false,
        actionGotoTrainer = false,
        actionMode = "logout",
        trainerLabel = "Trainer",
        actionPending = false
    }
end

cfg.deathCounter.enabled = cfg.deathCounter.enabled ~= false
cfg.deathCounter.logoutDeaths = math.max(1, tonumber(cfg.deathCounter.logoutDeaths or DEFAULT_DEATH_LOGOUT) or DEFAULT_DEATH_LOGOUT)

if type(cfg.deathCounter.actionMode) ~= "string" or cfg.deathCounter.actionMode == "" then
    if cfg.deathCounter.actionDisableBots == true then
        cfg.deathCounter.actionMode = "bots"
    elseif cfg.deathCounter.actionGotoTrainer == true then
        cfg.deathCounter.actionMode = "trainer"
    elseif cfg.deathCounter.actionForceExit == true then
        cfg.deathCounter.actionMode = "exit"
    else
        cfg.deathCounter.actionMode = "logout"
    end
end

if cfg.deathCounter.actionMode ~= "logout"
    and cfg.deathCounter.actionMode ~= "bots"
    and cfg.deathCounter.actionMode ~= "trainer"
    and cfg.deathCounter.actionMode ~= "exit" then
    cfg.deathCounter.actionMode = "logout"
end

cfg.deathCounter.actionLogout = cfg.deathCounter.actionMode == "logout"
cfg.deathCounter.actionDisableBots = cfg.deathCounter.actionMode == "bots"
cfg.deathCounter.actionGotoTrainer = cfg.deathCounter.actionMode == "trainer"
cfg.deathCounter.actionForceExit = cfg.deathCounter.actionMode == "exit"
cfg.deathCounter.trainerLabel = tostring(cfg.deathCounter.trainerLabel or "Trainer")
if cfg.deathCounter.trainerLabel == "" then
    cfg.deathCounter.trainerLabel = "Trainer"
end
cfg.deathCounter.actionPending = cfg.deathCounter.actionPending == true or cfg.deathCounter.logoutPending == true
cfg.deathCounter.logoutPending = nil

if not cfg.killCounter then
    cfg.killCounter = {
        enabled = false,
        killLimit = DEFAULT_KILL_LIMIT,
        actionLogout = true,
        actionDisableBots = false,
        actionForceExit = false,
        actionGotoTrainer = false,
        actionMode = "logout",
        trainerLabel = "Trainer",
        actionPending = false
    }
end

cfg.killCounter.enabled = cfg.killCounter.enabled == true
cfg.killCounter.killLimit = math.max(1, tonumber(cfg.killCounter.killLimit or DEFAULT_KILL_LIMIT) or DEFAULT_KILL_LIMIT)

if type(cfg.killCounter.actionMode) ~= "string" or cfg.killCounter.actionMode == "" then
    if cfg.killCounter.actionDisableBots == true then
        cfg.killCounter.actionMode = "bots"
    elseif cfg.killCounter.actionGotoTrainer == true then
        cfg.killCounter.actionMode = "trainer"
    elseif cfg.killCounter.actionForceExit == true then
        cfg.killCounter.actionMode = "exit"
    else
        cfg.killCounter.actionMode = "logout"
    end
end

if cfg.killCounter.actionMode ~= "logout"
    and cfg.killCounter.actionMode ~= "bots"
    and cfg.killCounter.actionMode ~= "trainer"
    and cfg.killCounter.actionMode ~= "exit" then
    cfg.killCounter.actionMode = "logout"
end

cfg.killCounter.actionLogout = cfg.killCounter.actionMode == "logout"
cfg.killCounter.actionDisableBots = cfg.killCounter.actionMode == "bots"
cfg.killCounter.actionGotoTrainer = cfg.killCounter.actionMode == "trainer"
cfg.killCounter.actionForceExit = cfg.killCounter.actionMode == "exit"
cfg.killCounter.trainerLabel = tostring(cfg.killCounter.trainerLabel or "Trainer")
if cfg.killCounter.trainerLabel == "" then
    cfg.killCounter.trainerLabel = "Trainer"
end
cfg.killCounter.actionPending = cfg.killCounter.actionPending == true

if not cfg.battleList then
    cfg.battleList = {
        enabled = true,
        monsters = true,
        players = true,
        party = true,
        npc = true,
        guild = true,
        enemy = true,
        noGuild = true,
        skull = false
    }
end

if cfg.battleList.noGuild == nil and cfg.battleList.NoGuild ~= nil then
    cfg.battleList.noGuild = cfg.battleList.NoGuild
end

if cfg.battleList.party == nil and cfg.battleList.Party ~= nil then
    cfg.battleList.party = cfg.battleList.Party
end

cfg.battleList.enabled = cfg.battleList.enabled ~= false
cfg.battleList.monsters = cfg.battleList.monsters ~= false
cfg.battleList.players = cfg.battleList.players ~= false
cfg.battleList.party = cfg.battleList.party ~= false
cfg.battleList.npc = cfg.battleList.npc ~= false
cfg.battleList.guild = cfg.battleList.guild ~= false
cfg.battleList.enemy = cfg.battleList.enemy ~= false
cfg.battleList.noGuild = cfg.battleList.noGuild ~= false
if cfg.battleList.skull == nil then
    cfg.battleList.skull = (cfg.battleList.skullWhite == true)
        or (cfg.battleList.skullRed == true)
        or (cfg.battleList.skullBlack == true)
        or (cfg.battleList.skullYellow == true)
end
cfg.battleList.skull = cfg.battleList.skull == true
cfg.battleList.skullWhite = nil
cfg.battleList.skullRed = nil
cfg.battleList.skullBlack = nil
cfg.battleList.skullYellow = nil
cfg.battleList.NoGuild = nil
cfg.battleList.Party = nil

if not cfg.hud.skillSelection then
    cfg.hud.skillSelection = {
        magic = true,
        fist = true,
        club = true,
        sword = true,
        axe = true,
        distance = true,
        shielding = true,
        fishing = false
    }
end

if not cfg.hud.systemSelection then
    cfg.hud.systemSelection = {
        hpTools = true,
        attack = true,
        rings = true,
        amulets = true,
        cavebot = true,
        targetbot = true
    }
end

cfg.hud.systemSelection.hpTools = cfg.hud.systemSelection.hpTools ~= false
cfg.hud.systemSelection.attack = cfg.hud.systemSelection.attack ~= false
cfg.hud.systemSelection.rings = cfg.hud.systemSelection.rings ~= false
cfg.hud.systemSelection.amulets = cfg.hud.systemSelection.amulets ~= false
cfg.hud.systemSelection.cavebot = cfg.hud.systemSelection.cavebot ~= false
cfg.hud.systemSelection.targetbot = cfg.hud.systemSelection.targetbot ~= false

if not cfg.lastSession then
    cfg.lastSession = nil
end

local function resetSessionState()
    cfg.session.startTime = os.time()
    cfg.session.initialLevel = player:getLevel()
    cfg.session.initialExp = exp()
    cfg.session.totalExpGained = 0
    cfg.session.lastExpGain = 0
    cfg.session.expHistory = {}
end

local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function formatNumber(number)
    if not number or number == 0 then
        return "0"
    end

    local suffixes = { "", "k", "M", "B", "T" }
    local suffixIndex = 1

    while number >= 1000 and suffixIndex < #suffixes do
        number = number / 1000
        suffixIndex = suffixIndex + 1
    end

    if suffixIndex == 1 then
        return string.format("%d", number)
    end

    return string.format("%.2f%s", number, suffixes[suffixIndex])
end

local function sessionTime()
    local uptime = math.floor(os.time() - cfg.session.startTime)
    return formatTime(uptime)
end

local function expGained()
    return cfg.session.totalExpGained
end

local function pruneExpHistory(nowTs, windowSeconds)
    local kept = {}
    for i = 1, #cfg.session.expHistory do
        local entry = cfg.session.expHistory[i]
        if nowTs - entry.t <= windowSeconds then
            kept[#kept + 1] = entry
        end
    end
    cfg.session.expHistory = kept
end

local function expPerHourReal(windowSeconds)
    local nowTs = os.time()
    pruneExpHistory(nowTs, windowSeconds)

    local sum = 0
    for i = 1, #cfg.session.expHistory do
        sum = sum + cfg.session.expHistory[i].v
    end

    return math.floor(sum * (3600 / windowSeconds))
end

local function currentSessionDuration()
    return math.max(1, os.time() - cfg.session.startTime)
end

local function buildSessionSnapshot()
    local duration = currentSessionDuration()
    local levelsGained = player:getLevel() - cfg.session.initialLevel
    local expHour = math.floor((cfg.session.totalExpGained / duration) * 3600)
    return {
        exp = cfg.session.totalExpGained,
        expPerHour = expHour,
        levels = levelsGained,
        duration = duration,
        endedAt = os.time()
    }
end

local function calcLevelStats()
    local currentLevel = player:getLevel()
    local levelsGained = currentLevel - cfg.session.initialLevel
    local elapsedTime = os.time() - cfg.session.startTime
    local hoursPlayed = elapsedTime / 3600

    local levelsPerHour = hoursPlayed > 0 and levelsGained / hoursPlayed or 0
    local levelsPerDay = levelsPerHour * 24

    return levelsGained, levelsPerHour, levelsPerDay
end

local function timeToNextLevel()
    local levelsGained = player:getLevel() - cfg.session.initialLevel
    local elapsedTime = os.time() - cfg.session.startTime

    if levelsGained == 0 then
        return elapsedTime
    end

    return elapsedTime / levelsGained
end

local function calcStamina()
    local stam = stamina()
    local hours = math.floor(stam / 60)
    local minutes = stam % 60
    local percent = math.floor(100 * stam / (42 * 60))
    return string.format("%d:%02d", hours, minutes), string.format(" (%d%%)", percent)
end

local function getNowMs()
    if g_clock and type(g_clock.millis) == "function" then
        return g_clock.millis()
    end
    return os.time() * 1000
end

local function formatDelayMinutes(minutes)
    local mins = math.max(1, tonumber(minutes or 1) or 1)
    if mins >= 60 then
        local hours = math.floor(mins / 60)
        local remain = mins % 60
        if remain > 0 then
            return string.format("%dh %dm", hours, remain)
        end
        return string.format("%dh", hours)
    end
    return string.format("%dm", mins)
end

local function setTooltipPair(widget, ptText, enText)
    if not widget or not widget.setTooltip then
        return
    end
    local pt = tostring(ptText or "")
    local en = tostring(enText or "")
    if en ~= "" then
        widget:setTooltip(string.format("PT: %s\nEN: %s", pt, en))
    else
        widget:setTooltip("PT: " .. pt)
    end
end

local function setOnOffButtonStyle(button, label, isOn)
    if not button then
        return
    end
    button:setText(string.format("%s: %s", label, isOn and "ON" or "OFF"))
    if button.setColor then
        button:setColor(isOn and "#98BF64" or "#FF6B6B")
    end
end

local function setStatusLabelStyle(label, isOn, text)
    if not label then
        return
    end
    if text ~= nil and label.setText then
        label:setText(tostring(text))
    end
    if label.setColor then
        label:setColor(isOn and "#9FE36A" or "#FF6B6B")
    end
end

local function resolveNamedConfig(configList, selectedId, emptyLabel)
    if type(selectedId) ~= "string" or selectedId == "" then
        return emptyLabel or "Sem config"
    end
    if type(configList) == "table" then
        for _, entry in ipairs(configList) do
            if type(entry) == "table" and entry.id == selectedId then
                return tostring(entry.name or selectedId)
            end
        end
    end
    return selectedId
end

local function trimProfileLabelText(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function getHpToolsProfileName()
    local profiles = type(storage.hpToolsProfiles) == "table" and storage.hpToolsProfiles or nil
    if not profiles then
        return "Sem perfil"
    end
    local activeId = trimProfileLabelText(((profiles.meta or {}).activeProfile))
    local configs = type(profiles.configs) == "table" and profiles.configs or {}
    local order = type(profiles.order) == "table" and profiles.order or {}
    if activeId == "" then
        for _, id in ipairs(order) do
            if type(configs[id]) == "table" then
                activeId = id
                break
            end
        end
    end
    if activeId == "" then
        return "Sem perfil"
    end
    local entry = configs[activeId]
    if type(entry) == "table" then
        return tostring(entry.name or activeId)
    end
    return activeId
end

local function getAttackConfigName()
    local attackCfg = type(storage.novoAtkUltraSafe) == "table" and storage.novoAtkUltraSafe or nil
    if not attackCfg then
        return "Sem config"
    end
    local selectedId = trimProfileLabelText(((attackCfg.meta or {}).activeProfile))
    local configList = attackCfg.configs and attackCfg.configs.list
    if selectedId == "" and type(configList) == "table" then
        for _, entry in ipairs(configList) do
            if type(entry) == "table" and trimProfileLabelText(entry.id) ~= "" then
                selectedId = trimProfileLabelText(entry.id)
                break
            end
        end
    end
    return resolveNamedConfig(configList, selectedId, "Sem config")
end

local function getRingAmuletProfileName()
    if type(getSelectedRingProfileId) == "function" and type(getRingProfileName) == "function" then
        local selectedId = getSelectedRingProfileId()
        return tostring(getRingProfileName(selectedId))
    end
    return "Sem perfil"
end

local function safeIsBotOn(botRef)
    if not botRef then
        return false
    end

    if type(botRef.isOn) == "function" then
        local ok, result = pcall(botRef.isOn)
        if not ok then
            ok, result = pcall(function()
                return botRef:isOn()
            end)
        end
        if ok then
            return result == true
        end
    end

    if type(botRef.isOff) == "function" then
        local ok, result = pcall(botRef.isOff)
        if not ok then
            ok, result = pcall(function()
                return botRef:isOff()
            end)
        end
        if ok then
            return result ~= true
        end
    end

    return false
end

local function isCaveBotRunning()
    return safeIsBotOn(CaveBot)
end

local function isTargetBotRunning()
    if safeIsBotOn(TargetBot) then
        return true
    end
    if modules and modules.targetbot then
        return safeIsBotOn(modules.targetbot)
    end
    return false
end

local function buildSystemStatusEntries()
    local function normalizeConfigLabel(rawValue, emptyLabel)
        local text = tostring(rawValue or "")
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then
            return emptyLabel or "Sem config"
        end
        return text
    end

    local function readCurrentBotProfileName(botRef)
        if not botRef then
            return nil
        end
        if type(botRef.getCurrentProfile) == "function" then
            local ok, value = pcall(botRef.getCurrentProfile)
            if not ok then
                ok, value = pcall(function()
                    return botRef:getCurrentProfile()
                end)
            end
            if ok then
                local profileName = normalizeConfigLabel(value, "")
                if profileName ~= "" then
                    return profileName
                end
            end
        end
        return nil
    end

    local function readStoredBotProfileName(configKey)
        local configRoot = type(storage._configs) == "table" and storage._configs or nil
        local configData = configRoot and type(configRoot[configKey]) == "table" and configRoot[configKey] or nil
        if not configData then
            return "Sem config"
        end
        return normalizeConfigLabel(configData.selected, "Sem config")
    end

    local hpEnabled = storage.healingSystemEnabled == true
    local toolsEnabled = storage.toolsEnabled == true
    local hpToolsActive = hpEnabled or toolsEnabled

    local attackCfg = type(storage.novoAtkUltraSafe) == "table" and storage.novoAtkUltraSafe or {}
    local attackEnabled = attackCfg.ultraSafeEnabled == true

    local ringProfileName = getRingAmuletProfileName()
    local cavebotProfileName = readCurrentBotProfileName(CaveBot) or readStoredBotProfileName("cavebot_configs")
    local targetbotProfileName = readCurrentBotProfileName(TargetBot)
    if not targetbotProfileName and modules and modules.targetbot then
        targetbotProfileName = readCurrentBotProfileName(modules.targetbot)
    end
    if not targetbotProfileName then
        targetbotProfileName = readStoredBotProfileName("targetbot_configs")
    end
    local ringsEnabled = isRingModuleEnabled()
    local amuletsEnabled = isAmuletModuleEnabled()
    local cavebotEnabled = isCaveBotRunning()
    local targetbotEnabled = isTargetBotRunning()

    return {
        {
            key = "hpTools",
            title = "HP/Tools",
            isOn = hpToolsActive,
            value = tostring(getHpToolsProfileName())
        },
        {
            key = "attack",
            title = "Attack",
            isOn = attackEnabled,
            value = tostring(getAttackConfigName())
        },
        {
            key = "rings",
            title = "Rings",
            isOn = ringsEnabled,
            value = tostring(ringProfileName)
        },
        {
            key = "amulets",
            title = "Amulets",
            isOn = amuletsEnabled,
            value = tostring(ringProfileName)
        },
        {
            key = "cavebot",
            title = "Cave",
            isOn = cavebotEnabled,
            value = tostring(cavebotProfileName)
        },
        {
            key = "targetbot",
            title = "Target",
            isOn = targetbotEnabled,
            value = tostring(targetbotProfileName)
        }
    }
end

local function isSystemSelectedForHud(key)
    return cfg.hud
        and cfg.hud.systemSelection
        and cfg.hud.systemSelection[key] == true
end

local function setSystemHudSelection(key, enabled)
    if not cfg.hud then
        cfg.hud = {}
    end
    if type(cfg.hud.systemSelection) ~= "table" then
        cfg.hud.systemSelection = {}
    end
    cfg.hud.systemSelection[key] = enabled == true
end

local function setDeathActionMode(mode)
    if mode ~= "logout" and mode ~= "bots" and mode ~= "trainer" and mode ~= "exit" then
        mode = "logout"
    end

    cfg.deathCounter.actionMode = mode
    cfg.deathCounter.actionLogout = mode == "logout"
    cfg.deathCounter.actionDisableBots = mode == "bots"
    cfg.deathCounter.actionGotoTrainer = mode == "trainer"
    cfg.deathCounter.actionForceExit = mode == "exit"
end

local function setKillActionMode(mode)
    if mode ~= "logout" and mode ~= "bots" and mode ~= "trainer" and mode ~= "exit" then
        mode = "logout"
    end

    cfg.killCounter.actionMode = mode
    cfg.killCounter.actionLogout = mode == "logout"
    cfg.killCounter.actionDisableBots = mode == "bots"
    cfg.killCounter.actionGotoTrainer = mode == "trainer"
    cfg.killCounter.actionForceExit = mode == "exit"
end

local function getDeathCount()
    return math.max(0, tonumber(storage.death and storage.death.count or 0) or 0)
end

local function setDeathCount(value)
    if type(storage.death) ~= "table" then
        storage.death = {}
    end
    storage.death.count = math.max(0, tonumber(value) or 0)
end

local function getKillCount()
    return math.max(0, tonumber(storage.kill and storage.kill.count or 0) or 0)
end

local function setKillCount(value)
    if type(storage.kill) ~= "table" then
        storage.kill = {}
    end
    storage.kill.count = math.max(0, tonumber(value) or 0)
end

local function deathCountColor(count)
    if count >= 4 then
        return "red"
    elseif count >= 2 then
        return "orange"
    end
    return "green"
end

local function killCountColor(count, limit)
    local safeLimit = math.max(1, tonumber(limit or 1) or 1)
    if count >= safeLimit then
        return "red"
    elseif count >= math.ceil(safeLimit * 0.5) then
        return "orange"
    end
    return "green"
end

local function setCaveBotOff()
    if not CaveBot then
        return
    end
    if type(CaveBot.isOn) == "function" then
        local ok, onValue = pcall(CaveBot.isOn)
        if not ok then
            ok, onValue = pcall(function()
                return CaveBot:isOn()
            end)
        end
        if ok and not onValue then
            return
        end
    end
    if type(CaveBot.setOff) == "function" then
        local ok = pcall(CaveBot.setOff)
        if not ok then
            pcall(function()
                CaveBot:setOff()
            end)
        end
    end
end

local function setTargetBotOff()
    if TargetBot and type(TargetBot.isOn) == "function" and type(TargetBot.setOff) == "function" then
        local ok, onValue = pcall(TargetBot.isOn)
        if not ok then
            ok, onValue = pcall(function()
                return TargetBot:isOn()
            end)
        end
        if ok and onValue then
            local ok = pcall(TargetBot.setOff)
            if not ok then
                pcall(function()
                    TargetBot:setOff()
                end)
            end
        end
        return
    end
    if modules and modules.targetbot and type(modules.targetbot.isOn) == "function" and type(modules.targetbot.setOff) == "function" then
        local ok, onValue = pcall(modules.targetbot.isOn)
        if ok and onValue then
            pcall(modules.targetbot.setOff)
        end
    end
end

local function ensureCaveBotOn()
    if not CaveBot then
        return
    end
    local isOff = nil
    if type(CaveBot.isOff) == "function" then
        local ok, value = pcall(CaveBot.isOff)
        if not ok then
            ok, value = pcall(function()
                return CaveBot:isOff()
            end)
        end
        if ok then
            isOff = value
        end
    end
    if isOff == true and type(CaveBot.setOn) == "function" then
        local ok = pcall(CaveBot.setOn)
        if not ok then
            pcall(function()
                CaveBot:setOn()
            end)
        end
        return
    end
    local isOn = nil
    if type(CaveBot.isOn) == "function" then
        local ok, value = pcall(CaveBot.isOn)
        if not ok then
            ok, value = pcall(function()
                return CaveBot:isOn()
            end)
        end
        if ok then
            isOn = value
        end
    end
    if isOn == false and type(CaveBot.setOn) == "function" then
        local ok = pcall(CaveBot.setOn)
        if not ok then
            pcall(function()
                CaveBot:setOn()
            end)
        end
    end
end

local function gotoCaveLabel(label)
    local targetLabel = tostring(label or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if targetLabel == "" then
        targetLabel = "Trainer"
    end
    if type(gotoLabel) == "function" then
        pcall(gotoLabel, targetLabel)
        return true
    end
    if CaveBot and type(CaveBot.gotoLabel) == "function" then
        pcall(CaveBot.gotoLabel, targetLabel)
        return true
    end
    return false
end

local function forceExitClient()
    if g_app and type(g_app.exit) == "function" then
        g_app.exit()
        return true
    end
    if type(exit) == "function" then
        exit()
        return true
    end
    return false
end

local function performDeathActions()
    local mode = cfg.deathCounter.actionMode or "logout"

    if mode == "bots" then
        setCaveBotOff()
        setTargetBotOff()
        return
    end

    if mode == "trainer" then
        ensureCaveBotOn()
        gotoCaveLabel(cfg.deathCounter.trainerLabel or "Trainer")
        return
    end

    if mode == "exit" then
        schedule(800, function()
            forceExitClient()
        end)
        return
    end

    schedule(5000, function()
        if modules and modules.game_interface and modules.game_interface.tryLogout then
            modules.game_interface.tryLogout(false)
        end
    end)
end

local function performKillActions()
    local mode = cfg.killCounter.actionMode or "logout"

    if mode == "bots" then
        setCaveBotOff()
        setTargetBotOff()
        return
    end

    if mode == "trainer" then
        ensureCaveBotOn()
        gotoCaveLabel(cfg.killCounter.trainerLabel or "Trainer")
        return
    end

    if mode == "exit" then
        schedule(800, function()
            forceExitClient()
        end)
        return
    end

    schedule(5000, function()
        if modules and modules.game_interface and modules.game_interface.tryLogout then
            modules.game_interface.tryLogout(false)
        end
    end)
end

local function tryDeathActions()
    if not cfg.deathCounter.enabled then
        cfg.deathCounter.actionPending = false
        return
    end

    local deathCount = getDeathCount()
    if deathCount < cfg.deathCounter.logoutDeaths then
        cfg.deathCounter.actionPending = false
        return
    end

    if cfg.deathCounter.actionPending then
        return
    end

    cfg.deathCounter.actionPending = true
    if type(warn) == "function" then
        warn("Death Counter Triggered")
    end
    performDeathActions()
end

local function tryKillActions()
    if not cfg.killCounter.enabled then
        cfg.killCounter.actionPending = false
        return
    end

    local killCount = getKillCount()
    if killCount < cfg.killCounter.killLimit then
        cfg.killCounter.actionPending = false
        return
    end

    if cfg.killCounter.actionPending then
        return
    end

    cfg.killCounter.actionPending = true
    if type(warn) == "function" then
        warn("Kill Counter Triggered")
    end
    performKillActions()
end

local function callCreatureMethod(creature, methodName, defaultValue)
    if not creature or type(creature) ~= "userdata" and type(creature) ~= "table" then
        return defaultValue
    end
    local fn = creature[methodName]
    if type(fn) ~= "function" then
        return defaultValue
    end
    local ok, result = pcall(function()
        return fn(creature)
    end)
    if ok then
        return result
    end
    return defaultValue
end

local function callBaseBattleFilter(creature)
    if type(souleAnalyzerBaseBattleFilter) == "function" then
        local ok, result = pcall(souleAnalyzerBaseBattleFilter, creature)
        if ok and type(result) == "boolean" then
            return result
        end
    end
    return true
end

local function battleListAllowsCreature(creature)
    if not creature or creature == player then
        return false
    end

    if callCreatureMethod(creature, "isLocalPlayer", false) then
        return false
    end

    local healthPercent = tonumber(callCreatureMethod(creature, "getHealthPercent", 100)) or 100
    if healthPercent <= 0 then
        return false
    end

    local creaturePos = callCreatureMethod(creature, "getPosition", nil)
    if creaturePos and creaturePos.z and type(posz) == "function" and creaturePos.z ~= posz() then
        return false
    end

    if callCreatureMethod(creature, "canBeSeen", true) == false then
        return false
    end

    local isMonster = callCreatureMethod(creature, "isMonster", false) == true
    local isPlayer = callCreatureMethod(creature, "isPlayer", false) == true
    local isNpc = callCreatureMethod(creature, "isNpc", false) == true
    if not isNpc then
        isNpc = callCreatureMethod(creature, "isNPC", false) == true
    end

    if isMonster then
        return cfg.battleList.monsters == true
    end

    if isNpc then
        return cfg.battleList.npc == true
    end

    if isPlayer then
        if cfg.battleList.players ~= true then
            return false
        end

        local playerAllowed = false
        if callCreatureMethod(creature, "isPartyMember", false) == true then
            playerAllowed = cfg.battleList.party == true
        else
            local emblem = tonumber(callCreatureMethod(creature, "getEmblem", 0)) or 0
            if emblem == 1 then
                playerAllowed = cfg.battleList.guild == true
            elseif emblem == 2 or emblem == 3 then
                playerAllowed = cfg.battleList.enemy == true
            else
                playerAllowed = cfg.battleList.noGuild == true
            end
        end
        if not playerAllowed then
            return false
        end

        if cfg.battleList.skull ~= true then
            return true
        end

        local skull = tonumber(callCreatureMethod(creature, "getSkull", 0)) or 0
        return skull == 1 or skull == 3 or skull == 4 or skull == 5
    end

    return true
end

local function analyzerBattleCreatureFilter(creature)
    if not cfg.battleList.enabled then
        return callBaseBattleFilter(creature)
    end

    if not callBaseBattleFilter(creature) then
        return false
    end

    return battleListAllowsCreature(creature)
end

local function ensureBattleListFilterInstalled()
    if not modules or not modules.game_battle then
        return
    end

    local currentFilter = modules.game_battle.doCreatureFitFilters
    if not souleAnalyzerBaseBattleFilter
        and type(currentFilter) == "function"
        and currentFilter ~= souleAnalyzerBattleFilterRef then
        souleAnalyzerBaseBattleFilter = currentFilter
    end

    souleAnalyzerBattleFilterRef = analyzerBattleCreatureFilter
    modules.game_battle.doCreatureFitFilters = analyzerBattleCreatureFilter
end

local function refreshBattleList()
    if not modules or not modules.game_battle then
        return
    end

    if type(modules.game_battle.checkCreatures) == "function" then
        pcall(modules.game_battle.checkCreatures)
    end
    if type(modules.game_battle.updateBattleList) == "function" then
        pcall(modules.game_battle.updateBattleList)
    end
end

local function hasActiveAttackTarget()
    if g_game and type(g_game.getAttackingCreature) == "function" then
        local creature = g_game.getAttackingCreature()
        if creature then
            return true
        end
    end
    return false
end

local function hasMonsterOnScreen()
    if type(getSpectators) ~= "function" then
        return false
    end

    local spectators = nil
    local okArg, resultArg = pcall(function()
        return getSpectators(false)
    end)
    if okArg and type(resultArg) == "table" then
        spectators = resultArg
    else
        local okNoArg, resultNoArg = pcall(function()
            return getSpectators()
        end)
        if okNoArg and type(resultNoArg) == "table" then
            spectators = resultNoArg
        end
    end

    if type(spectators) ~= "table" then
        return false
    end

    for _, spec in pairs(spectators) do
        if spec and spec ~= player and type(spec.isMonster) == "function" then
            local ok, isMonster = pcall(function()
                return spec:isMonster()
            end)
            if ok and isMonster then
                return true
            end
        end
    end
    return false
end

local function itemCountById(itemId)
    if type(itemId) ~= "number" or itemId < 100 then
        return 0
    end

    if player and type(player.getItemsCount) == "function" then
        local ok, count = pcall(function()
            return player:getItemsCount(itemId)
        end)
        if ok and type(count) == "number" then
            return count
        end
    end

    if g_game and type(g_game.findPlayerItem) == "function" then
        local item = g_game.findPlayerItem(itemId, -1)
        if item then
            return 1
        end
    end

    return 0
end

local function getItemCounterSlot(index)
    local slotIndex = tonumber(index)
    if not slotIndex then
        return nil
    end
    slotIndex = math.floor(slotIndex)
    if slotIndex < 1 or slotIndex > ANALYZER_ITEM_COUNTER_SLOTS then
        return nil
    end

    if type(cfg.itemCounters) ~= "table" then
        cfg.itemCounters = {
            intervalMinutes = ANALYZER_ITEM_COUNTER_INTERVAL_MINUTES,
            nextScanMs = 0,
            slots = {}
        }
    end
    dropNonStringKeys(cfg.itemCounters)
    if type(cfg.itemCounters.slots) ~= "table" then
        cfg.itemCounters.slots = {}
    end

    local slotsSource = cfg.itemCounters.slots
    local normalizedSlots = {}
    for i = 1, ANALYZER_ITEM_COUNTER_SLOTS do
        local slot = slotsSource[i]
        if slot == nil then
            slot = slotsSource[tostring(i)]
        end
        if slot == nil then
            slot = slotsSource[i - 1]
        end
        if slot == nil then
            slot = slotsSource[tostring(i - 1)]
        end
        normalizedSlots[i] = normalizeItemCounterSlotData(slot)
    end
    cfg.itemCounters.slots = normalizedSlots

    return cfg.itemCounters.slots[slotIndex]
end

local function sanitizeItemCounterId(value)
    local itemId = math.floor(tonumber(value) or 0)
    if itemId < 100 then
        return 0
    end
    if itemId > 65535 then
        return 65535
    end
    return itemId
end

local function setItemCounterItemId(index, rawValue)
    local slot = getItemCounterSlot(index)
    if not slot then
        return
    end
    local itemId = sanitizeItemCounterId(rawValue)
    if slot.itemId == itemId then
        return
    end
    slot.itemId = itemId
    slot.count = 0
    slot.previousCount = 0
    slot.delta = 0
    slot.ready = false
    slot.lastUpdateMs = 0
    cfg.itemCounters.nextScanMs = 0
end

local function scanItemCounters(force)
    if type(cfg.itemCounters) ~= "table" then
        return
    end

    local nowMs = getNowMs()
    local intervalMs = ANALYZER_ITEM_COUNTER_INTERVAL_MINUTES * 60 * 1000
    if not force and nowMs < (tonumber(cfg.itemCounters.nextScanMs or 0) or 0) then
        return
    end

    for i = 1, ANALYZER_ITEM_COUNTER_SLOTS do
        local slot = getItemCounterSlot(i)
        if slot then
            local itemId = sanitizeItemCounterId(slot.itemId)
            if itemId >= 100 then
                local count = itemCountById(itemId)
                if slot.ready then
                    slot.delta = count - (tonumber(slot.count or count) or count)
                else
                    slot.delta = 0
                    slot.ready = true
                end
                slot.previousCount = tonumber(slot.count or count) or count
                slot.count = count
                slot.itemId = itemId
                slot.lastUpdateMs = nowMs
            else
                slot.itemId = 0
                slot.count = 0
                slot.previousCount = 0
                slot.delta = 0
                slot.ready = false
                slot.lastUpdateMs = nowMs
            end
        end
    end

    cfg.itemCounters.nextScanMs = nowMs + intervalMs
end

local function sendInventoryUse(itemId)
    if type(itemId) ~= "number" or itemId < 100 then
        return false
    end

    local clientVersion = g_game and type(g_game.getClientVersion) == "function" and g_game.getClientVersion() or 0
    if clientVersion >= 780 and g_game and type(g_game.useInventoryItem) == "function" then
        g_game.useInventoryItem(itemId)
        return true
    end

    if g_game and type(g_game.findPlayerItem) == "function" and type(g_game.use) == "function" then
        local item = g_game.findPlayerItem(itemId, -1)
        if item then
            g_game.use(item)
            return true
        end
    end

    if type(use) == "function" then
        use(itemId)
        return true
    end

    return false
end

local function sendInventoryUseOnSelf(itemId)
    if type(itemId) ~= "number" or itemId < 100 then
        return false
    end

    local localPlayer = g_game and type(g_game.getLocalPlayer) == "function" and g_game.getLocalPlayer() or nil
    if not localPlayer then
        return false
    end

    local clientVersion = g_game and type(g_game.getClientVersion) == "function" and g_game.getClientVersion() or 0
    if clientVersion >= 780 and g_game and type(g_game.useInventoryItemWith) == "function" then
        g_game.useInventoryItemWith(itemId, localPlayer, -1)
        return true
    end

    if g_game and type(g_game.findPlayerItem) == "function" and type(g_game.useWith) == "function" then
        local item = g_game.findPlayerItem(itemId, -1)
        if item then
            g_game.useWith(item, localPlayer, -1)
            return true
        end
    end

    if type(useWith) == "function" then
        useWith(itemId, localPlayer)
        return true
    end

    return false
end

local function getConfiguredPotItems()
    local orderedItems = {}
    for i = 1, POT_EXP_SLOT_COUNT do
        local itemId = tonumber(cfg.potExp.items[i] or 0) or 0
        if itemId >= 100 then
            orderedItems[#orderedItems + 1] = itemId
        end
    end
    return orderedItems
end

local function pickNextPotItemId()
    local orderedItems = getConfiguredPotItems()
    if #orderedItems == 0 then
        return nil
    end

    local startIndex = tonumber(cfg.potExp.nextItemIndex or 1) or 1
    if startIndex < 1 or startIndex > #orderedItems then
        startIndex = 1
    end

    for offset = 0, #orderedItems - 1 do
        local idx = ((startIndex + offset - 1) % #orderedItems) + 1
        local itemId = orderedItems[idx]
        if itemCountById(itemId) > 0 then
            cfg.potExp.nextItemIndex = (idx % #orderedItems) + 1
            return itemId
        end
    end

    return nil
end

local function checkItemConsumed(itemId, beforeCount, callback)
    schedule(250, function()
        local consumed = itemCountById(itemId) < beforeCount
        callback(consumed)
    end)
end

local function tryUsePotItem(itemId, mode, callback)
    local beforeCount = itemCountById(itemId)
    if beforeCount <= 0 then
        if callback then
            callback(false)
        end
        return
    end

    local function finish(success)
        cfg.potExp.pendingUse = false
        if success then
            cfg.potExp.lastUseMs = getNowMs()
        end
        if callback then
            callback(success)
        end
    end

    cfg.potExp.pendingUse = true

    if mode == "AUTO" then
        if not sendInventoryUseOnSelf(itemId) then
            if not sendInventoryUse(itemId) then
                finish(false)
                return
            end
            checkItemConsumed(itemId, beforeCount, finish)
            return
        end

        checkItemConsumed(itemId, beforeCount, function(success)
            if success then
                finish(true)
                return
            end

            if not sendInventoryUse(itemId) then
                finish(false)
                return
            end

            checkItemConsumed(itemId, beforeCount, finish)
        end)
        return
    end

    if mode == "SELF" then
        if not sendInventoryUseOnSelf(itemId) then
            finish(false)
            return
        end
        checkItemConsumed(itemId, beforeCount, finish)
        return
    end

    if not sendInventoryUse(itemId) then
        finish(false)
        return
    end
    checkItemConsumed(itemId, beforeCount, finish)
end

local mapPanel = modules and modules.game_interface and modules.game_interface.getMapPanel and modules.game_interface.getMapPanel()
local hudParent = g_ui and g_ui.getRootWidget and g_ui.getRootWidget() or mapPanel
if not hudParent then
    print("[ANALYZER] HUD parent unavailable, HUD not started.")
    return
end

local analyzerHud = setupUI([[
OutlineLabel < Label
  height: 12
  background-color: #00000044
  opacity: 0.89
  text-auto-resize: true
  font: verdana-11px-rounded
  anchors.left: parent.left
  margin-left: 2
  $first:
    anchors.top: parent.top
  $!first:
    anchors.top: prev.bottom

Panel
  id: analyzerHud
  visible: false
  focusable: false
  phantom: false
  draggable: true
  image-border: 1
  border-width: 1
  border-color: #202327
  background: #00000066
  size: 181 142

  Label
    id: hudTitle
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 16
    background-color: #d4af37
    text-align: center
    color: #1a1a1a
    text: Analyzer by Kelus

  Button
    id: hudCollapseButton
    anchors.right: hudTitle.right
    anchors.verticalCenter: hudTitle.verticalCenter
    margin-right: 1
    size: 14 14
    text: -
    font: verdana-11px-rounded

  Button
    id: hudResetButton
    anchors.right: hudCollapseButton.left
    anchors.verticalCenter: hudTitle.verticalCenter
    margin-right: 1
    size: 14 14
    text: R
    font: verdana-11px-rounded

  HorizontalSeparator
    id: hudSeparator
    anchors.top: hudTitle.bottom
    anchors.left: parent.left
    anchors.right: parent.right

  Panel
    id: hudContent
    anchors.top: hudSeparator.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-left: 2
    margin-right: 2
    margin-top: 2
    margin-bottom: 2
    padding-left: 1
]], hudParent)

souleAnalyzerHud = analyzerHud
souleAnalyzerHudRuntime.hudContent = analyzerHud:getChildById("hudContent")
souleAnalyzerHudRuntime.hudTitle = analyzerHud:getChildById("hudTitle")
souleAnalyzerHudRuntime.hudSeparator = analyzerHud:getChildById("hudSeparator")
souleAnalyzerHudRuntime.hudCollapseButton = analyzerHud:getChildById("hudCollapseButton")
souleAnalyzerHudRuntime.hudResetButton = analyzerHud:getChildById("hudResetButton")
souleAnalyzerHudRuntime.raiseHud = function()
    if analyzerHud and analyzerHud.raise then
        analyzerHud:raise()
    end
end

souleAnalyzerHudRuntime.applyHudPosition = function()
    cfg.hud.posX = math.max(0, math.min(5000, tonumber(cfg.hud.posX) or 18))
    cfg.hud.posY = math.max(0, math.min(5000, tonumber(cfg.hud.posY) or 120))
    analyzerHud:setPosition({ x = cfg.hud.posX, y = cfg.hud.posY })
end

souleAnalyzerHudRuntime.applyHudCollapsedState = function()
    cfg.hud.collapsed = cfg.hud.collapsed == true
    local collapsed = cfg.hud.collapsed == true

    if souleAnalyzerHudRuntime.hudContent and souleAnalyzerHudRuntime.hudContent.setVisible then
        souleAnalyzerHudRuntime.hudContent:setVisible(not collapsed)
    end
    if souleAnalyzerHudRuntime.hudSeparator and souleAnalyzerHudRuntime.hudSeparator.setVisible then
        souleAnalyzerHudRuntime.hudSeparator:setVisible(not collapsed)
    end
    if souleAnalyzerHudRuntime.hudCollapseButton and souleAnalyzerHudRuntime.hudCollapseButton.setText then
        souleAnalyzerHudRuntime.hudCollapseButton:setText(collapsed and "+" or "-")
    end
    if collapsed and analyzerHud and analyzerHud.setHeight then
        analyzerHud:setHeight(18)
    end
end

souleAnalyzerHudRuntime.applyHudPosition()
souleAnalyzerHudRuntime.applyHudCollapsedState()

souleAnalyzerHudRuntime.syncHudPosFromWidget = function()
    if not analyzerHud or not analyzerHud.getPosition then
        return
    end

    local currentPos = analyzerHud:getPosition()
    if not currentPos then
        return
    end

    cfg.hud.posX = math.max(0, math.min(5000, tonumber(currentPos.x) or cfg.hud.posX or 18))
    cfg.hud.posY = math.max(0, math.min(5000, tonumber(currentPos.y) or cfg.hud.posY or 120))

    local syncWindow = souleAnalyzerOthersWindow
    if syncWindow and syncWindow.hudPosXSpin and syncWindow.hudPosYSpin then
        souleAnalyzerHudRuntime.hudPosUiSyncing = true
        if syncWindow.hudPosXSpin:getValue() ~= cfg.hud.posX then
            syncWindow.hudPosXSpin:setValue(cfg.hud.posX)
        end
        if syncWindow.hudPosYSpin:getValue() ~= cfg.hud.posY then
            syncWindow.hudPosYSpin:setValue(cfg.hud.posY)
        end
        souleAnalyzerHudRuntime.hudPosUiSyncing = false
    end
end

analyzerHud.onDragEnter = function(widget, mousePos)
    if widget.getX and widget.getY then
        widget.movingReference = { x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY() }
    end
    return true
end

souleAnalyzerHudRuntime.baseHudDragLeave = analyzerHud.onDragLeave
analyzerHud.onDragLeave = function(widget, pos)
    local consumed = false
    if type(souleAnalyzerHudRuntime.baseHudDragLeave) == "function" then
        consumed = souleAnalyzerHudRuntime.baseHudDragLeave(widget, pos) == true
    end
    if souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.syncHudPosFromWidget then
        souleAnalyzerHudRuntime.syncHudPosFromWidget()
    end
    return consumed
end

if souleAnalyzerHudRuntime.hudTitle then
    souleAnalyzerHudRuntime.baseHudTitleMousePress = souleAnalyzerHudRuntime.hudTitle.onMousePress
    souleAnalyzerHudRuntime.hudTitle.onMousePress = function(widget, mousePos, mouseButton)
        if mouseButton == 1 then
            if analyzerHud.getX and analyzerHud.getY then
                analyzerHud._manualDragOffset = {
                    x = mousePos.x - analyzerHud:getX(),
                    y = mousePos.y - analyzerHud:getY()
                }
            end
            return true
        end

        if type(souleAnalyzerHudRuntime.baseHudTitleMousePress) == "function" then
            return souleAnalyzerHudRuntime.baseHudTitleMousePress(widget, mousePos, mouseButton) == true
        end
        return false
    end
end

souleAnalyzerHudRuntime.baseHudMouseMove = analyzerHud.onMouseMove
analyzerHud.onMouseMove = function(widget, mousePos, mouseMoved)
    local ref = widget and widget._manualDragOffset or nil
    if ref and mousePos then
        cfg.hud.posX = math.max(0, math.min(5000, tonumber(mousePos.x - ref.x) or cfg.hud.posX or 18))
        cfg.hud.posY = math.max(0, math.min(5000, tonumber(mousePos.y - ref.y) or cfg.hud.posY or 120))
        if widget.setPosition then
            widget:setPosition({ x = cfg.hud.posX, y = cfg.hud.posY })
        end
        return true
    end

    if type(souleAnalyzerHudRuntime.baseHudMouseMove) == "function" then
        return souleAnalyzerHudRuntime.baseHudMouseMove(widget, mousePos, mouseMoved) == true
    end
    return false
end

souleAnalyzerHudRuntime.baseHudMouseRelease = analyzerHud.onMouseRelease
analyzerHud.onMouseRelease = function(widget, mousePos, mouseButton)
    if mouseButton == 1 and widget and widget._manualDragOffset then
        widget._manualDragOffset = nil
        if souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.syncHudPosFromWidget then
            souleAnalyzerHudRuntime.syncHudPosFromWidget()
        end
        return true
    end

    if type(souleAnalyzerHudRuntime.baseHudMouseRelease) == "function" then
        return souleAnalyzerHudRuntime.baseHudMouseRelease(widget, mousePos, mouseButton) == true
    end
    return false
end

local defaultColor = "white"
local defaultHighlight = "green"
local SKILL_LINE_PREFIX = "skill_"
local ITEM_COUNTER_LINE_PREFIX = "item_counter_"
local SYSTEM_STATUS_LINE_PREFIX = "system_status_"
local EXP_WINDOW_SECONDS = 300
local POT_USE_MODES = { "AUTO", "USE", "SELF" }

local trackedSkills = {
    { key = "fist", name = "Fist", id = 0, fallbackIds = { 1 }, enabled = true, color = "#FFFFFF", highlight = "#7CFC00" },
    { key = "club", name = "Club", id = 1, fallbackIds = { 2 }, enabled = true, color = "#FFFFFF", highlight = "#7CFC00" },
    { key = "sword", name = "Sword", id = 2, fallbackIds = { 3 }, enabled = true, color = "#FFFFFF", highlight = "#7CFC00" },
    { key = "axe", name = "Axe", id = 3, fallbackIds = { 4 }, enabled = true, color = "#FFFFFF", highlight = "#7CFC00" },
    { key = "distance", name = "Distance", id = 4, fallbackIds = {}, enabled = true, color = "#FFFFFF", highlight = "#7CFC00" },
    { key = "shielding", name = "Shielding", id = 5, fallbackIds = {}, enabled = true, color = "#FFFFFF", highlight = "#7CFC00" },
    { key = "fishing", name = "Fishing", id = 6, fallbackIds = { 7 }, enabled = false, color = "#FFFFFF", highlight = "#7CFC00" }
}

local function applySkillSelection()
    local selection = cfg.hud.skillSelection or {}
    for _, skill in ipairs(trackedSkills) do
        if selection[skill.key] == nil then
            selection[skill.key] = skill.enabled == true
        end
        skill.enabled = selection[skill.key] == true
    end
    if selection.magic == nil then
        selection.magic = true
    end
    cfg.hud.skillSelection = selection
end

applySkillSelection()

local function getHudLabel(id)
    local root = (souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.hudContent) or analyzerHud
    local label = root:getChildById(id)
    if not label then
        label = UI.createWidget("OutlineLabel", root)
        label:setId(id)
    end
    return label
end

local function displayLine(id, title, value, suffix, color, highlight)
    local label = getHudLabel(id)
    label:setVisible(true)
    label:setColoredText({
        title .. ": ", (color or defaultColor),
        tostring(value), (highlight or defaultHighlight),
        suffix or "", (color or defaultColor)
    })
end

local function readSkillValues(skill)
    local candidates = { skill.id }
    if skill.fallbackIds then
        for i = 1, #skill.fallbackIds do
            candidates[#candidates + 1] = skill.fallbackIds[i]
        end
    end

    for i = 1, #candidates do
        local sid = candidates[i]
        local level = player:getSkillLevel(sid)
        local percent = player:getSkillLevelPercent(sid)
        if type(level) == "number" and type(percent) == "number" then
            return level, percent
        end
    end

    return nil, nil
end

local function hideSkillLines()
    local root = (souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.hudContent) or analyzerHud
    for _, skill in ipairs(trackedSkills) do
        local label = root:getChildById(SKILL_LINE_PREFIX .. skill.id)
        if label then
            label:setVisible(false)
        end
    end
end

local function updateHud()
    if not cfg.enabled then
        return
    end

    if souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.applyHudCollapsedState then
        souleAnalyzerHudRuntime.applyHudCollapsedState()
    end
    if cfg.hud and cfg.hud.collapsed == true then
        return
    end

    scanItemCounters(false)

    local root = (souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.hudContent) or analyzerHud
    local children = root:getChildren()
    for i = 1, #children do
        children[i]:setVisible(false)
    end

    local levelsGained, _, levelsPerDay = calcLevelStats()
    local staminaValue, staminaPercent = calcStamina()
    local levelPercent = player:getLevelPercent()
    local magicLevel = player:getMagicLevel()
    local magicPercent = player:getMagicLevelPercent()
    local visibleLines = 0

    if cfg.hud.compact then
        displayLine("sessionTimeLabel", "Session", sessionTime(), "", "#FFFFFF", "#87CEFA")
        visibleLines = visibleLines + 1
        displayLine("expPerHourLabel", "Exp/h", formatNumber(expPerHourReal(EXP_WINDOW_SECONDS)), "", "#00FF00", "#00FF00")
        visibleLines = visibleLines + 1
        displayLine("expGainedLabel", "Exp gained", formatNumber(expGained()), "", "#00FF00", "#00FF00")
        visibleLines = visibleLines + 1
        displayLine("staminaLabel", "Stamina", staminaValue, staminaPercent, "#00BFFF", "#00BFFF")
        visibleLines = visibleLines + 1
    else
        displayLine("sessionTimeLabel", "Session", sessionTime(), "", "#FFFFFF", "#87CEFA")
        visibleLines = visibleLines + 1
        displayLine("expGainedLabel", "Exp gained", formatNumber(expGained()), "", "#00FF00", "#00FF00")
        visibleLines = visibleLines + 1
        displayLine("lastExpGainLabel", "Last gain", formatNumber(cfg.session.lastExpGain), "", "#00FF00", "#7CFC00")
        visibleLines = visibleLines + 1
        displayLine("expPerHourLabel", "Exp/h", formatNumber(expPerHourReal(EXP_WINDOW_SECONDS)), "", "#00FF00", "#00FF00")
        visibleLines = visibleLines + 1
        if cfg.lastSession then
            displayLine("prevExpHourLabel", "Prev Exp/h", formatNumber(cfg.lastSession.expPerHour or 0), "", "#00FF00", "#7CFC00")
            visibleLines = visibleLines + 1
        end
        displayLine("levelsGainedLabel", "Levels gained", levelsGained, "", "#FFD700", "orange")
        visibleLines = visibleLines + 1
        displayLine("levelsPerDayLabel", "Levels/day", string.format("%.2f", levelsPerDay), "", "#FFD700", "#FFD700")
        visibleLines = visibleLines + 1
        displayLine("nextLevelLabel", "Next level", formatTime(math.floor(timeToNextLevel())), "", "#FFD700", "orange")
        visibleLines = visibleLines + 1
        displayLine("levelLabel", "Level", level(), string.format(" (%d%%)", levelPercent), "#ABA71E", "orange")
        visibleLines = visibleLines + 1
        displayLine("staminaLabel", "Stamina", staminaValue, staminaPercent, "#00BFFF", "#00BFFF")
        visibleLines = visibleLines + 1
        if cfg.hud.showSkills and cfg.hud.skillSelection and cfg.hud.skillSelection.magic then
            displayLine("magicLabel", "Magic level", magicLevel, string.format(" (%d%%)", magicPercent), "#FFFFFF", "#7CFC00")
            visibleLines = visibleLines + 1
        end
    end

    if cfg.hud.showSkills and not cfg.hud.compact then
        for _, skill in ipairs(trackedSkills) do
            if skill.enabled then
                local skillLevel, skillPercent = readSkillValues(skill)
                displayLine(
                    SKILL_LINE_PREFIX .. skill.id,
                    skill.name,
                    skillLevel or "--",
                    skillPercent and string.format(" (%d%%)", skillPercent) or "",
                    skill.color,
                    skill.highlight
                )
                visibleLines = visibleLines + 1
            end
        end
    else
        hideSkillLines()
    end

    for _, systemEntry in ipairs(buildSystemStatusEntries()) do
        if isSystemSelectedForHud(systemEntry.key) then
            local statusColor = systemEntry.isOn and "#7CFC00" or "#FF6B6B"
            displayLine(
                SYSTEM_STATUS_LINE_PREFIX .. systemEntry.key,
                systemEntry.title,
                systemEntry.value,
                "",
                "#FFFFFF",
                statusColor
            )
            visibleLines = visibleLines + 1
        end
    end

    for i = 1, ANALYZER_ITEM_COUNTER_SLOTS do
        local slot = getItemCounterSlot(i)
        local itemId = sanitizeItemCounterId(slot and slot.itemId or 0)
        if slot and slot.showOnHud == true then
            local customName = tostring(slot.displayName or "")
            customName = customName:gsub("^%s+", ""):gsub("%s+$", "")
            if itemId >= 100 then
                local count = tonumber(slot.count or 0) or 0
                local delta = tonumber(slot.delta or 0) or 0
                local hudName = customName
                if hudName == "" then
                    hudName = string.format("ID %d", itemId)
                    if g_things and type(g_things.getThingType) == "function" then
                        local okThing, thing = pcall(g_things.getThingType, itemId)
                        if okThing and thing then
                            if type(thing.getName) == "function" then
                                local okName, resolvedName = pcall(function()
                                    return thing:getName()
                                end)
                                if okName and type(resolvedName) == "string" and resolvedName:gsub("^%s+", ""):gsub("%s+$", "") ~= "" then
                                    hudName = resolvedName:gsub("^%s+", ""):gsub("%s+$", "")
                                end
                            elseif type(thing.name) == "string" and thing.name:gsub("^%s+", ""):gsub("%s+$", "") ~= "" then
                                hudName = thing.name:gsub("^%s+", ""):gsub("%s+$", "")
                            end
                        end
                    end
                end
                local deltaColor = "#87CEFA"
                if delta > 0 then
                    deltaColor = "#7CFC00"
                elseif delta < 0 then
                    deltaColor = "#FF6B6B"
                end
                displayLine(
                    ITEM_COUNTER_LINE_PREFIX .. i,
                    string.format("C%d[%s]", i, hudName),
                    count,
                    string.format(" (D/m %+d)", delta),
                    "#FFFFFF",
                    deltaColor
                )
            else
                local emptyTitle = customName ~= "" and string.format("C%d[%s]", i, customName) or string.format("C%d", i)
                displayLine(
                    ITEM_COUNTER_LINE_PREFIX .. i,
                    emptyTitle,
                    "Set item",
                    " (D/m --)",
                    "#FFFFFF",
                    "#FFA500"
                )
            end
            visibleLines = visibleLines + 1
        end
    end

    local contentHeight = math.max(98, visibleLines * 13)
    analyzerHud:setHeight(contentHeight + 22)
end

local function setHudState()
    if souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.applyHudPosition then
        souleAnalyzerHudRuntime.applyHudPosition()
    end
    analyzerHud:setVisible(cfg.enabled)
    if cfg.enabled and souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.raiseHud then
        souleAnalyzerHudRuntime.raiseHud()
    end
    if cfg.enabled then
        updateHud()
    end
end

if souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.hudCollapseButton then
    souleAnalyzerHudRuntime.baseHudCollapseMousePress = souleAnalyzerHudRuntime.hudCollapseButton.onMousePress
    souleAnalyzerHudRuntime.hudCollapseButton.onMousePress = function(widget, mousePos, mouseButton)
        if mouseButton == 1 then
            cfg.hud.collapsed = not (cfg.hud.collapsed == true)
            if souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.applyHudCollapsedState then
                souleAnalyzerHudRuntime.applyHudCollapsedState()
            end
            if cfg.enabled and cfg.hud.collapsed ~= true then
                updateHud()
            end
            return true
        end
        if type(souleAnalyzerHudRuntime.baseHudCollapseMousePress) == "function" then
            return souleAnalyzerHudRuntime.baseHudCollapseMousePress(widget, mousePos, mouseButton) == true
        end
        return false
    end
    setTooltipPair(
        souleAnalyzerHudRuntime.hudCollapseButton,
        "Minimiza/maximiza o HUD do Analyzer.",
        "Minimizes/maximizes the Analyzer HUD."
    )
end

local resetSessionAndNotify
if souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.hudResetButton then
    souleAnalyzerHudRuntime.baseHudResetMousePress = souleAnalyzerHudRuntime.hudResetButton.onMousePress
    souleAnalyzerHudRuntime.hudResetButton.onMousePress = function(widget, mousePos, mouseButton)
        if mouseButton == 1 then
            resetSessionAndNotify()
            return true
        end
        if type(souleAnalyzerHudRuntime.baseHudResetMousePress) == "function" then
            return souleAnalyzerHudRuntime.baseHudResetMousePress(widget, mousePos, mouseButton) == true
        end
        return false
    end
    setTooltipPair(
        souleAnalyzerHudRuntime.hudResetButton,
        "Reseta a sessao do Analyzer.",
        "Resets the Analyzer session."
    )
end

resetSessionAndNotify = function()
    cfg.lastSession = buildSessionSnapshot()
    resetSessionState()
    updateHud()
    modules.game_textmessage.displayBroadcastMessage("Session reset successfully!", "#00FF00")
end

local function parseExpGainFromText(text)
    if type(text) ~= "string" then
        return nil
    end
    local expValueText = text:match("You gained ([%d,%.]+) experience points?")
    if not expValueText then
        return nil
    end
    local expValue = tonumber((expValueText:gsub("[^%d]", "")))
    if expValue and expValue > 0 then
        return expValue
    end
    return nil
end

onTextMessage(function(mode, text, channelId)
    if text and cfg.deathCounter.enabled and text:lower():find("you are dead") then
        setDeathCount(getDeathCount() + 1)
        tryDeathActions()
    end

    local expValue = parseExpGainFromText(text)
    if expValue and cfg.killCounter.enabled then
        setKillCount(getKillCount() + 1)
        tryKillActions()
    end

    if expValue and cfg.enabled then
        cfg.session.lastExpGain = expValue
        cfg.session.totalExpGained = cfg.session.totalExpGained + expValue
        cfg.session.expHistory[#cfg.session.expHistory + 1] = { t = os.time(), v = expValue }
    end
end)

macro(1000, function()
    if not cfg.enabled then
        return
    end
    if souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.raiseHud then
        souleAnalyzerHudRuntime.raiseHud()
    end
    updateHud()
end)

macro(500, function()
    if not cfg.potExp.enabled then
        return
    end

    if not cfg.potExp.useInPz and isInPz() then
        return
    end

    if cfg.potExp.pendingUse then
        return
    end

    if cfg.potExp.onlyNoTarget and hasActiveAttackTarget() then
        return
    end

    if cfg.potExp.onlyNoMonsters and hasMonsterOnScreen() then
        return
    end

    local nowMs = getNowMs()
    local delayMs = (tonumber(cfg.potExp.delayMinutes or 1) or 1) * 60 * 1000
    if nowMs - (cfg.potExp.lastUseMs or 0) < delayMs then
        return
    end

    if nowMs - (cfg.potExp.lastTryMs or 0) < 3000 then
        return
    end

    local itemId = pickNextPotItemId()
    if not itemId then
        return
    end

    cfg.potExp.lastTryMs = nowMs
    tryUsePotItem(itemId, cfg.potExp.useMode or "AUTO")
end)

if type(onLevelChange) == "function" then
    onLevelChange(function()
        if cfg.enabled then
            updateHud()
        end
    end)
end

if type(onMagicLevelChange) == "function" then
    onMagicLevelChange(function()
        if cfg.enabled then
            updateHud()
        end
    end)
end

if type(onSkillChange) == "function" then
    onSkillChange(function()
        if cfg.enabled then
            updateHud()
        end
    end)
end

if type(onStaminaChange) == "function" then
    onStaminaChange(function()
        if cfg.enabled then
            updateHud()
        end
    end)
end

onTalk(function(name, levelValue, mode, text)
    if text and text:lower() == "!resetsession" then
        resetSessionAndNotify()
    end
end)

g_ui.loadUIFromString([[
AnalyzerItemsRow10 < Panel
  height: 33

  BotItem
    id: item1
    anchors.top: parent.top
    anchors.left: parent.left

  BotItem
    id: item2
    anchors.top: item1.top
    anchors.left: item1.right
    margin-left: 2

  BotItem
    id: item3
    anchors.top: item2.top
    anchors.left: item2.right
    margin-left: 2

  BotItem
    id: item4
    anchors.top: item3.top
    anchors.left: item3.right
    margin-left: 2

  BotItem
    id: item5
    anchors.top: item4.top
    anchors.left: item4.right
    margin-left: 2

  BotItem
    id: item6
    anchors.top: item5.top
    anchors.left: item5.right
    margin-left: 2

  BotItem
    id: item7
    anchors.top: item6.top
    anchors.left: item6.right
    margin-left: 2

  BotItem
    id: item8
    anchors.top: item7.top
    anchors.left: item7.right
    margin-left: 2

  BotItem
    id: item9
    anchors.top: item8.top
    anchors.left: item8.right
    margin-left: 2

  BotItem
    id: item10
    anchors.top: item9.top
    anchors.left: item9.right
    margin-left: 2

AnalyzerOthersWindow < MainWindow
  anchors.centerIn: parent
  text: Others
  size: 820 486
  visible: false
  @onEscape: self:hide()

  Panel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeBtn.top
    margin-top: 6
    margin-left: 8
    margin-right: 8
    margin-bottom: 5

  Label
    id: stateLabel
    anchors.top: content.top
    anchors.left: content.left
    margin-top: 6
    margin-left: 8
    color: #FFFFFF
    text: Analyzer: OFF

  Button
    id: enableBtn
    anchors.top: stateLabel.bottom
    anchors.left: content.left
    margin-top: 6
    margin-left: 8
    size: 108 20
    text: Enable

  Button
    id: resetBtn
    anchors.top: prev.top
    anchors.left: prev.right
    margin-left: 6
    size: 72 20
    text: Reset

  Button
    id: skillsBtn
    anchors.top: prev.top
    anchors.left: prev.right
    margin-left: 6
    size: 92 20
    text: Skills

  Button
    id: compactBtn
    anchors.top: prev.top
    anchors.left: prev.right
    margin-left: 6
    size: 98 20
    text: Compact

  Button
    id: helpBtn
    anchors.top: closeBtn.top
    anchors.right: closeBtn.left
    margin-right: 6
    size: 100 18
    text: Ajuda / Help

  Label
    id: skillsLabel
    anchors.top: enableBtn.bottom
    anchors.left: content.left
    anchors.right: content.horizontalCenter
    margin-top: 10
    margin-left: 8
    margin-right: 12
    text-align: center
    color: #FFD700
    text: Skill filters

  Label
    id: skillsHelpLabel
    anchors.top: skillsLabel.bottom
    anchors.left: content.left
    anchors.right: content.horizontalCenter
    margin-top: 2
    margin-left: 8
    margin-right: 12
    text-align: center
    color: #87CEFA
    text: Check to show skill on HUD

  CheckBox
    id: skillMagicCheck
    anchors.top: skillsHelpLabel.bottom
    anchors.left: content.left
    margin-top: 4
    margin-left: 8
    color: #FFFFFF
    text: ""

  Label
    id: skillMagicLabel
    anchors.top: skillMagicCheck.top
    anchors.left: skillMagicCheck.right
    margin-left: 4
    color: #FFFFFF
    text: Magic level

  CheckBox
    id: skillFistCheck
    anchors.top: skillMagicCheck.top
    anchors.left: content.left
    margin-left: 180
    color: #FFFFFF
    text: ""

  Label
    id: skillFistLabel
    anchors.top: skillFistCheck.top
    anchors.left: skillFistCheck.right
    margin-left: 4
    color: #FFFFFF
    text: Fist

  CheckBox
    id: skillClubCheck
    anchors.top: skillMagicCheck.bottom
    anchors.left: content.left
    margin-top: 4
    margin-left: 8
    color: #FFFFFF
    text: ""

  Label
    id: skillClubLabel
    anchors.top: skillClubCheck.top
    anchors.left: skillClubCheck.right
    margin-left: 4
    color: #FFFFFF
    text: Club

  CheckBox
    id: skillSwordCheck
    anchors.top: skillClubCheck.top
    anchors.left: skillFistCheck.left
    color: #FFFFFF
    text: ""

  Label
    id: skillSwordLabel
    anchors.top: skillSwordCheck.top
    anchors.left: skillSwordCheck.right
    margin-left: 4
    color: #FFFFFF
    text: Sword

  CheckBox
    id: skillAxeCheck
    anchors.top: skillClubCheck.bottom
    anchors.left: content.left
    margin-top: 4
    margin-left: 8
    color: #FFFFFF
    text: ""

  Label
    id: skillAxeLabel
    anchors.top: skillAxeCheck.top
    anchors.left: skillAxeCheck.right
    margin-left: 4
    color: #FFFFFF
    text: Axe

  CheckBox
    id: skillDistanceCheck
    anchors.top: skillAxeCheck.top
    anchors.left: skillFistCheck.left
    color: #FFFFFF
    text: ""

  Label
    id: skillDistanceLabel
    anchors.top: skillDistanceCheck.top
    anchors.left: skillDistanceCheck.right
    margin-left: 4
    color: #FFFFFF
    text: Distance

  CheckBox
    id: skillShieldCheck
    anchors.top: skillAxeCheck.bottom
    anchors.left: content.left
    margin-top: 4
    margin-left: 8
    color: #FFFFFF
    text: ""

  Label
    id: skillShieldLabel
    anchors.top: skillShieldCheck.top
    anchors.left: skillShieldCheck.right
    margin-left: 4
    color: #FFFFFF
    text: Shielding

  CheckBox
    id: skillFishingCheck
    anchors.top: skillShieldCheck.top
    anchors.left: skillFistCheck.left
    color: #FFFFFF
    text: ""

  Label
    id: skillFishingLabel
    anchors.top: skillFishingCheck.top
    anchors.left: skillFishingCheck.right
    margin-left: 4
    color: #FFFFFF
    text: Fishing

  Label
    id: hudPosLabel
    anchors.top: skillMagicCheck.top
    anchors.left: content.left
    margin-left: 258
    color: #FFD700
    text: HUD Pos

  Label
    id: hudPosXLabel
    anchors.top: hudPosLabel.bottom
    anchors.left: hudPosLabel.left
    margin-top: 4
    color: #FFFFFF
    text: X:

  SpinBox
    id: hudPosXSpin
    anchors.top: hudPosXLabel.top
    anchors.left: hudPosXLabel.right
    margin-left: 4
    width: 58
    height: 20
    minimum: 0
    maximum: 5000
    step: 1
    editable: true
    focusable: true

  Label
    id: hudPosYLabel
    anchors.top: hudPosXSpin.bottom
    anchors.left: hudPosXLabel.left
    margin-top: 4
    color: #FFFFFF
    text: Y:

  SpinBox
    id: hudPosYSpin
    anchors.top: hudPosYLabel.top
    anchors.left: hudPosYLabel.right
    margin-left: 4
    width: 58
    height: 20
    minimum: 0
    maximum: 5000
    step: 1
    editable: true
    focusable: true

  Label
    id: systemsLabel
    anchors.top: skillFishingCheck.bottom
    anchors.left: content.left
    anchors.right: content.horizontalCenter
    margin-top: 10
    margin-left: 8
    margin-right: 12
    text-align: center
    color: #FFD700
    text: Systems status

  Label
    id: systemsHelpLabel
    anchors.top: systemsLabel.bottom
    anchors.left: content.left
    anchors.right: content.horizontalCenter
    margin-top: 2
    margin-left: 8
    margin-right: 12
    text-align: center
    color: #87CEFA
    text: Active modules + selected config

  CheckBox
    id: sysHpToolsCheck
    anchors.top: systemsHelpLabel.bottom
    anchors.left: content.left
    margin-top: 4
    margin-left: 8
    color: #FFFFFF
    text: ""

  Label
    id: sysHpToolsLabel
    anchors.top: sysHpToolsCheck.top
    anchors.left: sysHpToolsCheck.right
    margin-left: 4
    width: 198
    color: #FFFFFF
    text: HP/Tools

  CheckBox
    id: sysAttackCheck
    anchors.top: sysHpToolsCheck.bottom
    anchors.left: content.left
    margin-top: 4
    margin-left: 8
    color: #FFFFFF
    text: ""

  Label
    id: sysAttackLabel
    anchors.top: sysAttackCheck.top
    anchors.left: sysAttackCheck.right
    margin-left: 4
    width: 198
    color: #FFFFFF
    text: Attack

  CheckBox
    id: sysRingsCheck
    anchors.top: sysAttackCheck.bottom
    anchors.left: content.left
    margin-top: 4
    margin-left: 8
    color: #FFFFFF
    text: ""

  Label
    id: sysRingsLabel
    anchors.top: sysRingsCheck.top
    anchors.left: sysRingsCheck.right
    margin-left: 4
    width: 198
    color: #FFFFFF
    text: Rings

  CheckBox
    id: sysAmuletsCheck
    anchors.top: sysRingsCheck.bottom
    anchors.left: content.left
    margin-top: 4
    margin-left: 8
    color: #FFFFFF
    text: ""

  Label
    id: sysAmuletsLabel
    anchors.top: sysAmuletsCheck.top
    anchors.left: sysAmuletsCheck.right
    margin-left: 4
    width: 198
    color: #FFFFFF
    text: Amulets

  CheckBox
    id: sysCavebotCheck
    anchors.top: sysAmuletsCheck.bottom
    anchors.left: content.left
    margin-top: 4
    margin-left: 8
    color: #FFFFFF
    text: ""

  Label
    id: sysCavebotLabel
    anchors.top: sysCavebotCheck.top
    anchors.left: sysCavebotCheck.right
    margin-left: 4
    width: 198
    color: #FFFFFF
    text: Cave

  CheckBox
    id: sysTargetbotCheck
    anchors.top: sysCavebotCheck.bottom
    anchors.left: content.left
    margin-top: 4
    margin-left: 8
    color: #FFFFFF
    text: ""

  Label
    id: sysTargetbotLabel
    anchors.top: sysTargetbotCheck.top
    anchors.left: sysTargetbotCheck.right
    margin-left: 4
    width: 198
    color: #FFFFFF
    text: Target

  Label
    id: potSectionLabel
    anchors.top: stateLabel.top
    anchors.left: content.horizontalCenter
    anchors.right: content.right
    margin-left: 12
    margin-right: 8
    text-align: center
    color: #FFD700
    text: Pot Exp

  Label
    id: potHelpLabel
    anchors.top: potSectionLabel.bottom
    anchors.left: content.horizontalCenter
    anchors.right: content.right
    margin-top: 2
    margin-left: 12
    margin-right: 8
    text-align: center
    color: #87CEFA
    text: Slot order: 1 -> 20 (top then bottom)

  Button
    id: potEnableBtn
    anchors.top: potHelpLabel.bottom
    anchors.left: content.horizontalCenter
    margin-top: 4
    margin-left: 12
    size: 90 20
    text: Pot: OFF

  Button
    id: potPzBtn
    anchors.top: potEnableBtn.top
    anchors.left: potEnableBtn.right
    margin-left: 6
    size: 96 20
    text: PZ: OFF

  Button
    id: potModeBtn
    anchors.top: potEnableBtn.top
    anchors.left: potPzBtn.right
    margin-left: 6
    size: 110 20
    text: Mode: AUTO

  Button
    id: potNoTargetBtn
    anchors.top: potEnableBtn.bottom
    anchors.left: content.horizontalCenter
    margin-top: 4
    margin-left: 12
    size: 126 20
    text: No target: OFF

  Button
    id: potNoMonstersBtn
    anchors.top: potNoTargetBtn.top
    anchors.left: potNoTargetBtn.right
    margin-left: 6
    size: 176 20
    text: No monster: OFF

  HorizontalScrollBar
    id: potDelayScroll
    anchors.top: potNoTargetBtn.bottom
    anchors.left: content.horizontalCenter
    anchors.right: content.right
    margin-top: 6
    margin-left: 12
    margin-right: 8
    minimum: 1
    maximum: 120
    step: 1

  Label
    id: potDelayLabel
    anchors.top: potDelayScroll.bottom
    anchors.left: content.horizontalCenter
    anchors.right: content.right
    margin-top: 2
    margin-left: 12
    margin-right: 8
    color: #FFFFFF
    text: Delay: 1m

  AnalyzerItemsRow10
    id: potItemsRow1
    anchors.top: potDelayLabel.bottom
    anchors.left: content.horizontalCenter
    anchors.right: content.right
    margin-top: 4
    margin-left: 12
    margin-right: 8

  AnalyzerItemsRow10
    id: potItemsRow2
    anchors.top: potItemsRow1.bottom
    anchors.left: content.horizontalCenter
    anchors.right: content.right
    margin-top: 2
    margin-left: 12
    margin-right: 8

  Label
    id: deathSectionLabel
    anchors.top: potItemsRow2.bottom
    anchors.left: content.horizontalCenter
    margin-top: 10
    margin-left: 12
    width: 182
    text-align: center
    color: #FFD700
    text: Death Counter

  Label
    id: deathHelpLabel
    anchors.top: deathSectionLabel.bottom
    anchors.left: deathSectionLabel.left
    margin-top: 2
    width: 182
    text-align: center
    color: #87CEFA
    text: Choose limit and action

  Label
    id: deathLimitLabel
    anchors.top: deathHelpLabel.bottom
    anchors.left: deathSectionLabel.left
    margin-top: 4
    color: #FFFFFF
    text: Death limit:

  SpinBox
    id: deathLimitSpin
    anchors.top: deathLimitLabel.top
    anchors.left: deathLimitLabel.right
    margin-left: 6
    width: 90
    height: 20
    text-align: center
    minimum: 1
    maximum: 999
    step: 1
    editable: true
    focusable: true

  Label
    id: deathCountLabel
    anchors.top: deathLimitLabel.bottom
    anchors.left: deathSectionLabel.left
    margin-top: 4
    color: #00FF00
    text: Death count: 0

  Button
    id: deathMacroBtn
    anchors.top: deathCountLabel.bottom
    anchors.left: deathSectionLabel.left
    margin-top: 4
    size: 182 20
    text: Death: ON

  Button
    id: deathResetBtn
    anchors.top: deathMacroBtn.bottom
    anchors.left: deathSectionLabel.left
    margin-top: 4
    size: 182 20
    text: Reset Deaths

  Button
    id: deathActionLogoutBtn
    anchors.top: deathResetBtn.bottom
    anchors.left: deathSectionLabel.left
    margin-top: 4
    size: 182 20
    text: Action Logout: ON

  Button
    id: deathActionBotsBtn
    anchors.top: deathActionLogoutBtn.bottom
    anchors.left: deathSectionLabel.left
    margin-top: 4
    size: 182 20
    text: Action Cave+Target: OFF

  Button
    id: deathActionTrainerBtn
    anchors.top: deathActionBotsBtn.bottom
    anchors.left: deathSectionLabel.left
    margin-top: 4
    size: 182 20
    text: Action Trainer: OFF

  Button
    id: deathActionExitBtn
    anchors.top: deathActionTrainerBtn.bottom
    anchors.left: deathSectionLabel.left
    margin-top: 4
    size: 182 20
    text: Action Exit: OFF

  Label
    id: killSectionLabel
    anchors.top: deathSectionLabel.top
    anchors.left: deathSectionLabel.right
    margin-left: 10
    width: 182
    text-align: center
    color: #FFD700
    text: Kill Counter

  Label
    id: killHelpLabel
    anchors.top: killSectionLabel.bottom
    anchors.left: killSectionLabel.left
    margin-top: 2
    width: 182
    text-align: center
    color: #87CEFA
    text: Counts experience messages

  Label
    id: killLimitLabel
    anchors.top: killHelpLabel.bottom
    anchors.left: killSectionLabel.left
    margin-top: 4
    color: #FFFFFF
    text: Kill limit:

  SpinBox
    id: killLimitSpin
    anchors.top: killLimitLabel.top
    anchors.left: killLimitLabel.right
    margin-left: 6
    width: 90
    height: 20
    text-align: center
    minimum: 1
    maximum: 99999
    step: 1
    editable: true
    focusable: true

  Label
    id: killCountLabel
    anchors.top: killLimitLabel.bottom
    anchors.left: killSectionLabel.left
    margin-top: 4
    color: #00FF00
    text: Kill count: 0

  Button
    id: killMacroBtn
    anchors.top: killCountLabel.bottom
    anchors.left: killSectionLabel.left
    margin-top: 4
    size: 182 20
    text: Kill: OFF

  Button
    id: killResetBtn
    anchors.top: killMacroBtn.bottom
    anchors.left: killSectionLabel.left
    margin-top: 4
    size: 182 20
    text: Reset Kills

  Button
    id: killActionLogoutBtn
    anchors.top: killResetBtn.bottom
    anchors.left: killSectionLabel.left
    margin-top: 4
    size: 182 20
    text: Action Logout: ON

  Button
    id: killActionBotsBtn
    anchors.top: killActionLogoutBtn.bottom
    anchors.left: killSectionLabel.left
    margin-top: 4
    size: 182 20
    text: Action Cave+Target: OFF

  Button
    id: killActionTrainerBtn
    anchors.top: killActionBotsBtn.bottom
    anchors.left: killSectionLabel.left
    margin-top: 4
    size: 182 20
    text: Action Trainer: OFF

  Button
    id: killActionExitBtn
    anchors.top: killActionTrainerBtn.bottom
    anchors.left: killSectionLabel.left
    margin-top: 4
    size: 182 20
    text: Action Exit: OFF

  Label
    id: battleSectionLabel
    anchors.top: sysTargetbotCheck.bottom
    anchors.left: content.left
    margin-top: 12
    margin-left: 8
    width: 386
    text-align: center
    color: #FFD700
    text: Battle List

  Label
    id: battleHelpLabel
    anchors.top: battleSectionLabel.bottom
    anchors.left: content.left
    margin-top: 2
    margin-left: 8
    width: 386
    text-align: center
    color: #87CEFA
    text: Filter creatures shown on battle window

  Button
    id: battleEnableBtn
    anchors.top: battleHelpLabel.bottom
    anchors.left: content.left
    margin-top: 4
    margin-left: 8
    size: 92 20
    text: Battle: ON

  Button
    id: battleMonstersBtn
    anchors.top: battleEnableBtn.bottom
    anchors.left: content.left
    margin-top: 4
    margin-left: 8
    size: 92 20
    text: Monsters: ON

  Button
    id: battlePlayersBtn
    anchors.top: battleMonstersBtn.top
    anchors.left: battleMonstersBtn.right
    margin-left: 6
    size: 92 20
    text: Players: ON

  Button
    id: battleNpcBtn
    anchors.top: battleMonstersBtn.top
    anchors.left: battlePlayersBtn.right
    margin-left: 6
    size: 92 20
    text: NPC: ON

  Button
    id: battlePartyBtn
    anchors.top: battleMonstersBtn.top
    anchors.left: battleNpcBtn.right
    margin-left: 6
    size: 92 20
    text: Party: ON

  Button
    id: battleGuildBtn
    anchors.top: battleMonstersBtn.bottom
    anchors.left: content.left
    margin-top: 4
    margin-left: 8
    size: 92 20
    text: Guild: ON

  Button
    id: battleEnemyBtn
    anchors.top: battleGuildBtn.top
    anchors.left: battleGuildBtn.right
    margin-left: 6
    size: 92 20
    text: Enemy: ON

  Button
    id: battleNoGuildBtn
    anchors.top: battleGuildBtn.top
    anchors.left: battleEnemyBtn.right
    margin-left: 6
    size: 92 20
    text: No Guild: ON

  Button
    id: battleSkullBtn
    anchors.top: battleGuildBtn.top
    anchors.left: battleNoGuildBtn.right
    margin-left: 6
    size: 92 20
    text: Skull: OFF

  Label
    id: itemCounterSectionLabel
    anchors.top: systemsHelpLabel.bottom
    anchors.left: content.left
    margin-top: 0
    margin-left: 228
    width: 158
    text-align: center
    color: #FFD700
    text: Item Counters (1m)

  Label
    id: itemCounterHelpLabel
    anchors.top: itemCounterSectionLabel.bottom
    anchors.left: content.left
    margin-top: 2
    margin-left: 228
    width: 158
    text-align: center
    color: #87CEFA
    text: Drag items to track

  CheckBox
    id: itemCounter1HudCheck
    anchors.top: itemCounterHelpLabel.bottom
    anchors.left: content.left
    margin-top: 3
    margin-left: 232
    color: #FFFFFF
    text: ""

  Label
    id: itemCounter1Label
    anchors.top: itemCounter1HudCheck.top
    anchors.left: itemCounter1HudCheck.right
    margin-left: 4
    color: #FFFFFF
    text: C1

  BotItem
    id: itemCounter1Item
    anchors.top: itemCounter1HudCheck.top
    anchors.left: itemCounter1Label.right
    margin-left: 6
    size: 20 20

  TextEdit
    id: itemCounter1NameEdit
    anchors.top: itemCounter1HudCheck.top
    anchors.left: itemCounter1Item.right
    margin-left: 4
    width: 92
    height: 20
    text-align: left
    font: verdana-11px-rounded
    placeholder: Name HUD
    text: ""

  CheckBox
    id: itemCounter2HudCheck
    anchors.top: itemCounter1NameEdit.bottom
    anchors.left: content.left
    margin-top: 2
    margin-left: 232
    color: #FFFFFF
    text: ""

  Label
    id: itemCounter2Label
    anchors.top: itemCounter2HudCheck.top
    anchors.left: itemCounter2HudCheck.right
    margin-left: 4
    color: #FFFFFF
    text: C2

  BotItem
    id: itemCounter2Item
    anchors.top: itemCounter2HudCheck.top
    anchors.left: itemCounter2Label.right
    margin-left: 6
    size: 20 20

  TextEdit
    id: itemCounter2NameEdit
    anchors.top: itemCounter2HudCheck.top
    anchors.left: itemCounter2Item.right
    margin-left: 4
    width: 92
    height: 20
    text-align: left
    font: verdana-11px-rounded
    placeholder: Name HUD
    text: ""

  CheckBox
    id: itemCounter3HudCheck
    anchors.top: itemCounter2NameEdit.bottom
    anchors.left: content.left
    margin-top: 2
    margin-left: 232
    color: #FFFFFF
    text: ""

  Label
    id: itemCounter3Label
    anchors.top: itemCounter3HudCheck.top
    anchors.left: itemCounter3HudCheck.right
    margin-left: 4
    color: #FFFFFF
    text: C3

  BotItem
    id: itemCounter3Item
    anchors.top: itemCounter3HudCheck.top
    anchors.left: itemCounter3Label.right
    margin-left: 6
    size: 20 20

  TextEdit
    id: itemCounter3NameEdit
    anchors.top: itemCounter3HudCheck.top
    anchors.left: itemCounter3Item.right
    margin-left: 4
    width: 92
    height: 20
    text-align: left
    font: verdana-11px-rounded
    placeholder: Name HUD
    text: ""

  Button
    id: closeBtn
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-right: 8
    margin-bottom: 8
    size: 80 18
    text: Close

AnalyzerHelpWindow < MainWindow
  !text: tr('Others Help')
  size: 640 560
  visible: false
  @onEscape: self:hide()

  Panel
    id: helpContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonPanel.top
    margin-top: 6
    margin-left: 8
    margin-right: 8

    VerticalScrollBar
      id: helpScroll
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      step: 28
      pixels-scroll: true

    ScrollablePanel
      id: helpScrollContent
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-right: 10
      padding-top: 3
      padding-bottom: 3
      padding-left: 4
      vertical-scrollbar: helpScroll
      layout:
        type: verticalBox
        spacing: 4

      Label
        id: helpTextLabel
        width: 600
        text-align: left
        text-wrap: true
        multiline: true
        text-auto-resize: true
        text: ""

  Panel
    id: buttonPanel
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 24
    margin: 5
    layout:
      type: horizontalBox
      spacing: 6

    Button
      id: closeButton
      text: Fechar
      size: 80 18
      @onClick: self:getParent():getParent():hide()
]])

local othersWindow = g_ui.createWidget("AnalyzerOthersWindow", g_ui.getRootWidget())
souleAnalyzerOthersWindow = othersWindow

local analyzerHelpWindow = g_ui.createWidget("AnalyzerHelpWindow", g_ui.getRootWidget())
analyzerHelpWindow:hide()
souleAnalyzerHelpWindow = analyzerHelpWindow

local analyzerHelpUi = {
    window = analyzerHelpWindow,
    scrollBar = analyzerHelpWindow:recursiveGetChildById("helpScroll"),
    scrollContent = analyzerHelpWindow:recursiveGetChildById("helpScrollContent"),
    textLabel = analyzerHelpWindow:recursiveGetChildById("helpTextLabel"),
    closeButton = analyzerHelpWindow:recursiveGetChildById("closeButton")
}

local ANALYZER_HELP_TEXT = table.concat({
    "PT - Others (Analyzer) Tutorial",
    "===============================",
    "1) Analyzer HUD",
    "- Analyzer: liga/desliga o HUD no mapa.",
    "- Reset: zera a sessao de exp atual.",
    "- Skills: mostra/oculta bloco de skills no HUD.",
    "- Compact: usa versao reduzida do HUD.",
    "- HUD Pos X/Y: define a posicao do HUD no mapa.",
    "",
    "2) Skill filters",
    "- Marque/desmarque cada skill para decidir o que aparece no HUD.",
    "",
    "3) Systems status",
    "- Exibe status de HP/Tools, Attack, Rings, Amulets, Cave e Target.",
    "- Marque/desmarque o checkbox para mostrar/ocultar cada status no HUD do Analyzer.",
    "- Cada linha mostra a config/perfil atual (cor verde/vermelha indica status).",
    "",
    "4) Pot Exp",
    "- Configure os itens nos 20 slots, da esquerda para direita (linha 1 e linha 2).",
    "- Delay define intervalo minimo de uso.",
    "- Mode AUTO tenta SELF e depois USE.",
    "- No target / No monster restringe uso por situacao de combate.",
    "",
    "5) Death Counter",
    "- Conta mortes por mensagem 'you are dead'.",
    "- Ao bater o limite, executa 1 acao exclusiva:",
    "  Logout | Cave+Target OFF | Trainer label | Exit client.",
    "",
    "6) Kill Counter",
    "- Conta kills por mensagem de ganho de exp.",
    "- Ao bater o limite, executa 1 acao exclusiva (mesmas opcoes do Death).",
    "",
    "7) Battle List",
    "- Battle: liga/desliga filtro customizado.",
    "- Filtros: Monsters, Players, NPC, Party, Guild, Enemy, No Guild.",
    "- Skull: quando ON, filtra players com skull (White/Red/Black/Yellow).",
    "",
    "8) Item Counters (1 min)",
    "- Arraste um item em cada um dos 3 contadores para monitorar SSA, Might Ring, etc.",
    "- Em cada contador, defina um nome no campo de texto para exibir no HUD.",
    "- Marque/desmarque o checkbox de cada contador para aparecer no HUD.",
    "- A cada 1 minuto atualiza quantidade e delta (consumo/ganho por minuto).",
    "",
    "EN - Others (Analyzer) Tutorial",
    "===============================",
    "1) Analyzer HUD",
    "- Analyzer: enables/disables the map HUD.",
    "- Reset: resets current exp session.",
    "- Skills: shows/hides skills block on HUD.",
    "- Compact: uses compact HUD mode.",
    "- HUD Pos X/Y: sets the HUD position on the map.",
    "",
    "2) Skill filters",
    "- Toggle each skill to decide what is shown on HUD.",
    "",
    "3) Systems status",
    "- Shows status for HP/Tools, Attack, Rings, Amulets, Cave and Target.",
    "- Toggle each checkbox to show/hide that status line on the Analyzer HUD.",
    "- Each line shows current config/profile (green/red color indicates status).",
    "",
    "4) Pot Exp",
    "- Configure items in 20 slots, left to right (row 1 and row 2).",
    "- Delay sets minimum use interval.",
    "- AUTO tries SELF first, then USE.",
    "- No target / No monster restricts use by combat state.",
    "",
    "5) Death Counter",
    "- Counts deaths by 'you are dead' message.",
    "- When limit is reached, it runs one exclusive action:",
    "  Logout | Cave+Target OFF | Trainer label | Exit client.",
    "",
    "6) Kill Counter",
    "- Counts kills by experience gain messages.",
    "- When limit is reached, it runs one exclusive action (same as Death).",
    "",
    "7) Battle List",
    "- Battle: enables/disables custom filtering.",
    "- Filters: Monsters, Players, NPC, Party, Guild, Enemy, No Guild.",
    "- Skull: when ON, filters players with skull (White/Red/Black/Yellow).",
    "",
    "8) Item Counters (1 min)",
    "- Drag one item into each of the 3 counters to track SSA, Might Ring, etc.",
    "- In each counter, set a custom text name to be shown on HUD.",
    "- Toggle each counter checkbox to show/hide it on HUD.",
    "- Every minute it refreshes quantity and delta (consumed/gained per minute)."
}, "\n")

local function refreshAnalyzerHelpWindow()
    if analyzerHelpUi.textLabel then
        analyzerHelpUi.textLabel:setText(ANALYZER_HELP_TEXT)
    end
end

local function resetAnalyzerHelpScrollToTop()
    if analyzerHelpUi.scrollBar and analyzerHelpUi.scrollBar.setValue then
        local minValue = 0
        if analyzerHelpUi.scrollBar.getMinimum then
            local currentMin = analyzerHelpUi.scrollBar:getMinimum()
            if type(currentMin) == "number" then
                minValue = currentMin
            end
        end
        analyzerHelpUi.scrollBar:setValue(minValue)
    end
    if analyzerHelpUi.scrollContent and analyzerHelpUi.scrollContent.getVirtualOffset and analyzerHelpUi.scrollContent.setVirtualOffset then
        local off = analyzerHelpUi.scrollContent:getVirtualOffset() or { x = 0, y = 0 }
        off.x = 0
        off.y = 0
        analyzerHelpUi.scrollContent:setVirtualOffset(off)
    end
end

local function openAnalyzerHelpWindow()
    refreshAnalyzerHelpWindow()
    analyzerHelpWindow:show()
    analyzerHelpWindow:raise()
    analyzerHelpWindow:focus()
    resetAnalyzerHelpScrollToTop()
    schedule(30, resetAnalyzerHelpScrollToTop)
    schedule(120, resetAnalyzerHelpScrollToTop)
    schedule(260, resetAnalyzerHelpScrollToTop)
end

if analyzerHelpUi.closeButton then
    analyzerHelpUi.closeButton.onClick = function()
        analyzerHelpWindow:hide()
    end
end

setTooltipPair(othersWindow.skillMagicCheck, "Mostra/oculta o Magic level no HUD.", "Shows/hides Magic level on the HUD.")
setTooltipPair(othersWindow.skillFistCheck, "Mostra/oculta o skill Fist no HUD.", "Shows/hides Fist skill on the HUD.")
setTooltipPair(othersWindow.skillClubCheck, "Mostra/oculta o skill Club no HUD.", "Shows/hides Club skill on the HUD.")
setTooltipPair(othersWindow.skillSwordCheck, "Mostra/oculta o skill Sword no HUD.", "Shows/hides Sword skill on the HUD.")
setTooltipPair(othersWindow.skillAxeCheck, "Mostra/oculta o skill Axe no HUD.", "Shows/hides Axe skill on the HUD.")
setTooltipPair(othersWindow.skillDistanceCheck, "Mostra/oculta o skill Distance no HUD.", "Shows/hides Distance skill on the HUD.")
setTooltipPair(othersWindow.skillShieldCheck, "Mostra/oculta o skill Shielding no HUD.", "Shows/hides Shielding skill on the HUD.")
setTooltipPair(othersWindow.skillFishingCheck, "Mostra/oculta o skill Fishing no HUD.", "Shows/hides Fishing skill on the HUD.")
setTooltipPair(othersWindow.hudPosLabel, "Posicao manual do HUD no mapa.", "Manual HUD position on the map.")
setTooltipPair(othersWindow.hudPosXLabel, othersWindow.hudPosXSpin, "Coordenada X do HUD do Analyzer.", "Analyzer HUD X coordinate.")
setTooltipPair(othersWindow.hudPosYLabel, othersWindow.hudPosYSpin, "Coordenada Y do HUD do Analyzer.", "Analyzer HUD Y coordinate.")
setTooltipPair(othersWindow.sysHpToolsCheck, "Marca para mostrar o status de HP/Tools no HUD.", "Check to show HP/Tools status on the HUD.")
setTooltipPair(othersWindow.sysAttackCheck, "Marca para mostrar o status de Attack no HUD.", "Check to show Attack status on the HUD.")
setTooltipPair(othersWindow.sysRingsCheck, "Marca para mostrar o status de Rings no HUD.", "Check to show Rings status on the HUD.")
setTooltipPair(othersWindow.sysAmuletsCheck, "Marca para mostrar o status de Amulets no HUD.", "Check to show Amulets status on the HUD.")
setTooltipPair(othersWindow.sysCavebotCheck, "Marca para mostrar o status de Cave no HUD.", "Check to show Cave status on the HUD.")
setTooltipPair(othersWindow.sysTargetbotCheck, "Marca para mostrar o status de Target no HUD.", "Check to show Target status on the HUD.")
setTooltipPair(othersWindow.battleEnableBtn, "Liga/desliga o filtro customizado da Battle List.", "Enables/disables custom Battle List filtering.")
setTooltipPair(othersWindow.battleMonstersBtn, "Mostra/oculta monstros na Battle List.", "Shows/hides monsters on Battle List.")
setTooltipPair(othersWindow.battlePlayersBtn, "Mostra/oculta players na Battle List.", "Shows/hides players on Battle List.")
setTooltipPair(othersWindow.battleNpcBtn, "Mostra/oculta NPCs na Battle List.", "Shows/hides NPCs on Battle List.")
setTooltipPair(othersWindow.battlePartyBtn, "Mostra/oculta party members na Battle List.", "Shows/hides party members on Battle List.")
setTooltipPair(othersWindow.battleGuildBtn, "Quando players estiver ON, mostra/oculta membros da guild.", "When players is ON, shows/hides guild members.")
setTooltipPair(othersWindow.battleEnemyBtn, "Quando players estiver ON, mostra/oculta enemy guild.", "When players is ON, shows/hides enemy guild.")
setTooltipPair(othersWindow.battleNoGuildBtn, "Quando players estiver ON, mostra/oculta players sem guild.", "When players is ON, shows/hides no-guild players.")
setTooltipPair(othersWindow.battleSkullBtn, "Quando ON, inclui players com skull (white/red/black/yellow).", "When ON, includes players with skull (white/red/black/yellow).")
setTooltipPair(othersWindow.enableBtn, "Liga/desliga o Analyzer HUD.", "Enables/disables Analyzer HUD.")
setTooltipPair(othersWindow.resetBtn, "Reseta os dados da sessao de EXP.", "Resets EXP session data.")
setTooltipPair(othersWindow.skillsBtn, "Liga/desliga o bloco de skills no HUD.", "Enables/disables the skills block on HUD.")
setTooltipPair(othersWindow.compactBtn, "Alterna entre modo completo e compacto.", "Toggles between full and compact mode.")
setTooltipPair(othersWindow.helpBtn, "Abre o tutorial completo do Others.", "Opens the full Others tutorial.")
setTooltipPair(othersWindow.potEnableBtn, "Liga/desliga o uso automatico de Pot Exp.", "Enables/disables automatic Pot Exp usage.")
setTooltipPair(othersWindow.potPzBtn, "Se OFF, nao usa Pot Exp em Protection Zone.", "If OFF, Pot Exp is not used in Protection Zone.")
setTooltipPair(othersWindow.potModeBtn, "AUTO tenta SELF e depois USE.", "AUTO tries SELF first, then USE.")
setTooltipPair(othersWindow.potNoTargetBtn, "Se ON, so tenta sem target ativo.", "If ON, only tries with no active target.")
setTooltipPair(othersWindow.potNoMonstersBtn, "Se ON, so tenta sem monstro na tela.", "If ON, only tries with no monsters on screen.")
setTooltipPair(othersWindow.potDelayScroll, "Define o delay de uso em minutos.", "Sets usage delay in minutes.")
setTooltipPair(othersWindow.potItemsRow1, "Arraste itens em ordem: slots 1 a 10.", "Drag items in order: slots 1 to 10.")
setTooltipPair(othersWindow.potItemsRow2, "Arraste itens em ordem: slots 11 a 20.", "Drag items in order: slots 11 to 20.")
setTooltipPair(othersWindow.deathMacroBtn, "Liga/desliga o contador de mortes.", "Enables/disables the death counter.")
setTooltipPair(othersWindow.deathResetBtn, "Reseta o contador de mortes para zero.", "Resets death count to zero.")
setTooltipPair(othersWindow.deathLimitSpin, "Define a quantidade de mortes para acionar as acoes.", "Sets how many deaths trigger the actions.")
setTooltipPair(othersWindow.deathActionLogoutBtn, "Seleciona modo exclusivo: deslogar ao bater o limite.", "Selects exclusive mode: logout when limit is reached.")
setTooltipPair(othersWindow.deathActionBotsBtn, "Seleciona modo exclusivo: desligar CaveBot e TargetBot.", "Selects exclusive mode: disable CaveBot and TargetBot.")
setTooltipPair(othersWindow.deathActionTrainerBtn, "Seleciona modo exclusivo: ir para label 'Trainer'.", "Selects exclusive mode: go to 'Trainer' label.")
setTooltipPair(othersWindow.deathActionExitBtn, "Seleciona modo exclusivo: fechar o client.", "Selects exclusive mode: close the client.")
setTooltipPair(othersWindow.killMacroBtn, "Liga/desliga o contador de kills.", "Enables/disables the kill counter.")
setTooltipPair(othersWindow.killResetBtn, "Reseta o contador de kills para zero.", "Resets kill count to zero.")
setTooltipPair(othersWindow.killLimitSpin, "Define a quantidade de kills para acionar as acoes.", "Sets how many kills trigger the actions.")
setTooltipPair(othersWindow.killActionLogoutBtn, "Seleciona modo exclusivo: deslogar ao bater o limite.", "Selects exclusive mode: logout when limit is reached.")
setTooltipPair(othersWindow.killActionBotsBtn, "Seleciona modo exclusivo: desligar CaveBot e TargetBot.", "Selects exclusive mode: disable CaveBot and TargetBot.")
setTooltipPair(othersWindow.killActionTrainerBtn, "Seleciona modo exclusivo: ir para label 'Trainer'.", "Selects exclusive mode: go to 'Trainer' label.")
setTooltipPair(othersWindow.killActionExitBtn, "Seleciona modo exclusivo: fechar o client.", "Selects exclusive mode: close the client.")
setTooltipPair(othersWindow.itemCounter1Item, "Arraste o item para o contador 1 (atualiza a cada 1 minuto).", "Drag the item for counter 1 (updates every 1 minute).")
setTooltipPair(othersWindow.itemCounter2Item, "Arraste o item para o contador 2 (atualiza a cada 1 minuto).", "Drag the item for counter 2 (updates every 1 minute).")
setTooltipPair(othersWindow.itemCounter3Item, "Arraste o item para o contador 3 (atualiza a cada 1 minuto).", "Drag the item for counter 3 (updates every 1 minute).")
setTooltipPair(othersWindow.itemCounter1NameEdit, "Nome exibido no HUD para o contador 1.", "Name shown on HUD for counter 1.")
setTooltipPair(othersWindow.itemCounter2NameEdit, "Nome exibido no HUD para o contador 2.", "Name shown on HUD for counter 2.")
setTooltipPair(othersWindow.itemCounter3NameEdit, "Nome exibido no HUD para o contador 3.", "Name shown on HUD for counter 3.")
setTooltipPair(othersWindow.itemCounter1HudCheck, "Marca para mostrar o contador 1 no HUD.", "Check to show counter 1 on HUD.")
setTooltipPair(othersWindow.itemCounter2HudCheck, "Marca para mostrar o contador 2 no HUD.", "Check to show counter 2 on HUD.")
setTooltipPair(othersWindow.itemCounter3HudCheck, "Marca para mostrar o contador 3 no HUD.", "Check to show counter 3 on HUD.")
setTooltipPair(othersWindow.closeBtn, "Fecha a janela Others.", "Closes the Others window.")
setTooltipPair(analyzerHelpUi.textLabel, "Tutorial completo dos recursos desta janela.", "Complete tutorial for this window features.")
setTooltipPair(analyzerHelpUi.closeButton, "Fecha a janela de ajuda.", "Closes the help window.")

local function getPotSlotWidgetByIndex(index)
    local rowIndex = math.floor((index - 1) / POT_EXP_ROW_SIZE) + 1
    local colIndex = ((index - 1) % POT_EXP_ROW_SIZE) + 1
    if rowIndex < 1 or rowIndex > POT_EXP_ROW_COUNT then
        return nil
    end
    local rowWidget = othersWindow:recursiveGetChildById("potItemsRow" .. rowIndex) or othersWindow:getChildById("potItemsRow" .. rowIndex)
    if not rowWidget then
        return nil
    end
    return rowWidget:getChildByIndex(colIndex)
end

for i = 1, POT_EXP_SLOT_COUNT do
    local slotIndex = i
    local itemSlot = getPotSlotWidgetByIndex(slotIndex)
    if itemSlot then
        itemSlot.onItemChange = function(widget)
            cfg.potExp.items[slotIndex] = tonumber(widget:getItemId() or 0) or 0
        end
        itemSlot:setItemId(cfg.potExp.items[slotIndex] or 0)
    end
end

local itemCounterUiSyncing = false

local function bindItemCounterSlot(slotIndex)
    local itemWidget = othersWindow:recursiveGetChildById("itemCounter" .. slotIndex .. "Item")
    local hudCheck = othersWindow:recursiveGetChildById("itemCounter" .. slotIndex .. "HudCheck")
    local nameEdit = othersWindow:recursiveGetChildById("itemCounter" .. slotIndex .. "NameEdit")

    if hudCheck then
        hudCheck.onClick = function(widget)
            if itemCounterUiSyncing then
                return
            end
            local slot = getItemCounterSlot(slotIndex)
            if slot then
                slot.showOnHud = not (slot.showOnHud == true)
                widget:setChecked(slot.showOnHud == true)
                if cfg.enabled then
                    updateHud()
                end
            end
        end
    end

    if itemWidget then
        itemWidget.onItemChange = function(widget)
            if itemCounterUiSyncing then
                return
            end
            local sanitizedItemId = sanitizeItemCounterId(widget:getItemId())
            if widget and widget.setItemId and widget.getItemId and widget:getItemId() ~= sanitizedItemId then
                itemCounterUiSyncing = true
                widget:setItemId(sanitizedItemId)
                itemCounterUiSyncing = false
            end
            setItemCounterItemId(slotIndex, sanitizedItemId)
            scanItemCounters(true)
            if cfg.enabled then
                updateHud()
            end
        end
        local slot = getItemCounterSlot(slotIndex)
        itemWidget:setItemId(sanitizeItemCounterId(slot and slot.itemId or 0))
    end

    if nameEdit then
        nameEdit.onTextChange = function(widget, text)
            if itemCounterUiSyncing then
                return
            end
            local slot = getItemCounterSlot(slotIndex)
            if not slot then
                return
            end
            local cleanedText = tostring(text or "")
            cleanedText = cleanedText:gsub("^%s+", ""):gsub("%s+$", "")
            if #cleanedText > 24 then
                cleanedText = cleanedText:sub(1, 24)
                itemCounterUiSyncing = true
                widget:setText(cleanedText)
                itemCounterUiSyncing = false
            end
            slot.displayName = cleanedText
            if cfg.enabled then
                updateHud()
            end
        end
        local slot = getItemCounterSlot(slotIndex)
        nameEdit:setText(slot and tostring(slot.displayName or "") or "")
    end

    if hudCheck then
        local slot = getItemCounterSlot(slotIndex)
        hudCheck:setChecked(slot and slot.showOnHud == true)
    end
end

for i = 1, ANALYZER_ITEM_COUNTER_SLOTS do
    bindItemCounterSlot(i)
end

scanItemCounters(true)

local function setAnalyzerEnabled(enabled)
    cfg.enabled = enabled == true
    setHudState()
    if cfg.enabled then
        modules.game_textmessage.displayBroadcastMessage("Analyzer HUD ENABLED", "#00FF00")
    else
        modules.game_textmessage.displayBroadcastMessage("Analyzer HUD DISABLED", "#FF0000")
    end
end

local function updateOthersWindow()
    if not othersWindow then
        return
    end
    applySkillSelection()
    scanItemCounters(false)
    othersWindow.stateLabel:setText("Analyzer: " .. (cfg.enabled and "ON" or "OFF"))
    othersWindow.stateLabel:setColor(cfg.enabled and "#98BF64" or "#FF6B6B")
    setOnOffButtonStyle(othersWindow.enableBtn, "Analyzer", cfg.enabled)
    setOnOffButtonStyle(othersWindow.skillsBtn, "Skills", cfg.hud.showSkills)
    setOnOffButtonStyle(othersWindow.compactBtn, "Compact", cfg.hud.compact)
    othersWindow.skillMagicCheck:setChecked(cfg.hud.skillSelection.magic == true)
    othersWindow.skillFistCheck:setChecked(cfg.hud.skillSelection.fist == true)
    othersWindow.skillClubCheck:setChecked(cfg.hud.skillSelection.club == true)
    othersWindow.skillSwordCheck:setChecked(cfg.hud.skillSelection.sword == true)
    othersWindow.skillAxeCheck:setChecked(cfg.hud.skillSelection.axe == true)
    othersWindow.skillDistanceCheck:setChecked(cfg.hud.skillSelection.distance == true)
    othersWindow.skillShieldCheck:setChecked(cfg.hud.skillSelection.shielding == true)
    othersWindow.skillFishingCheck:setChecked(cfg.hud.skillSelection.fishing == true)
    souleAnalyzerHudRuntime.hudPosUiSyncing = true
    if othersWindow.hudPosXSpin:getValue() ~= cfg.hud.posX then
        othersWindow.hudPosXSpin:setValue(cfg.hud.posX)
    end
    if othersWindow.hudPosYSpin:getValue() ~= cfg.hud.posY then
        othersWindow.hudPosYSpin:setValue(cfg.hud.posY)
    end
    souleAnalyzerHudRuntime.hudPosUiSyncing = false

    local systemEntries = buildSystemStatusEntries()
    local systemByKey = {}
    for _, entry in ipairs(systemEntries) do
        systemByKey[entry.key] = entry
    end

    if not cfg.hud then
        cfg.hud = {}
    end
    cfg.hud._systemStatusUiSyncing = true
    othersWindow.sysHpToolsCheck:setChecked(isSystemSelectedForHud("hpTools"))
    setStatusLabelStyle(othersWindow.sysHpToolsLabel, systemByKey.hpTools and systemByKey.hpTools.isOn, systemByKey.hpTools and (systemByKey.hpTools.title .. " | " .. systemByKey.hpTools.value) or "HP/Tools")

    othersWindow.sysAttackCheck:setChecked(isSystemSelectedForHud("attack"))
    setStatusLabelStyle(othersWindow.sysAttackLabel, systemByKey.attack and systemByKey.attack.isOn, systemByKey.attack and (systemByKey.attack.title .. " | " .. systemByKey.attack.value) or "Attack")

    othersWindow.sysRingsCheck:setChecked(isSystemSelectedForHud("rings"))
    setStatusLabelStyle(othersWindow.sysRingsLabel, systemByKey.rings and systemByKey.rings.isOn, systemByKey.rings and (systemByKey.rings.title .. " | " .. systemByKey.rings.value) or "Rings")

    othersWindow.sysAmuletsCheck:setChecked(isSystemSelectedForHud("amulets"))
    setStatusLabelStyle(othersWindow.sysAmuletsLabel, systemByKey.amulets and systemByKey.amulets.isOn, systemByKey.amulets and (systemByKey.amulets.title .. " | " .. systemByKey.amulets.value) or "Amulets")

    othersWindow.sysCavebotCheck:setChecked(isSystemSelectedForHud("cavebot"))
    setStatusLabelStyle(othersWindow.sysCavebotLabel, systemByKey.cavebot and systemByKey.cavebot.isOn, systemByKey.cavebot and (systemByKey.cavebot.title .. " | " .. systemByKey.cavebot.value) or "Cave")

    othersWindow.sysTargetbotCheck:setChecked(isSystemSelectedForHud("targetbot"))
    setStatusLabelStyle(othersWindow.sysTargetbotLabel, systemByKey.targetbot and systemByKey.targetbot.isOn, systemByKey.targetbot and (systemByKey.targetbot.title .. " | " .. systemByKey.targetbot.value) or "Target")
    cfg.hud._systemStatusUiSyncing = false

    setOnOffButtonStyle(othersWindow.battleEnableBtn, "Battle", cfg.battleList.enabled)
    setOnOffButtonStyle(othersWindow.battleMonstersBtn, "Monsters", cfg.battleList.monsters)
    setOnOffButtonStyle(othersWindow.battlePlayersBtn, "Players", cfg.battleList.players)
    setOnOffButtonStyle(othersWindow.battleNpcBtn, "NPC", cfg.battleList.npc)
    setOnOffButtonStyle(othersWindow.battlePartyBtn, "Party", cfg.battleList.party)
    setOnOffButtonStyle(othersWindow.battleGuildBtn, "Guild", cfg.battleList.guild)
    setOnOffButtonStyle(othersWindow.battleEnemyBtn, "Enemy", cfg.battleList.enemy)
    setOnOffButtonStyle(othersWindow.battleNoGuildBtn, "No Guild", cfg.battleList.noGuild)
    setOnOffButtonStyle(othersWindow.battleSkullBtn, "Skull", cfg.battleList.skull)
    setOnOffButtonStyle(othersWindow.potEnableBtn, "Pot", cfg.potExp.enabled)
    setOnOffButtonStyle(othersWindow.potPzBtn, "PZ", cfg.potExp.useInPz)
    othersWindow.potModeBtn:setText("Mode: " .. (cfg.potExp.useMode or "AUTO"))
    setOnOffButtonStyle(othersWindow.potNoTargetBtn, "No target", cfg.potExp.onlyNoTarget)
    setOnOffButtonStyle(othersWindow.potNoMonstersBtn, "No monster", cfg.potExp.onlyNoMonsters)
    othersWindow.potDelayLabel:setText("Delay: " .. formatDelayMinutes(cfg.potExp.delayMinutes))
    if othersWindow.potDelayScroll:getValue() ~= cfg.potExp.delayMinutes then
        othersWindow.potDelayScroll:setValue(cfg.potExp.delayMinutes)
    end
    local deathCount = getDeathCount()
    if deathCount < cfg.deathCounter.logoutDeaths then
        cfg.deathCounter.actionPending = false
    end
    othersWindow.deathCountLabel:setText(string.format("Death count: %d / Limit: %d", deathCount, cfg.deathCounter.logoutDeaths))
    othersWindow.deathCountLabel:setColor(deathCountColor(deathCount))
    setOnOffButtonStyle(othersWindow.deathMacroBtn, "Death", cfg.deathCounter.enabled)
    if othersWindow.deathLimitSpin:getValue() ~= cfg.deathCounter.logoutDeaths then
        othersWindow.deathLimitSpin:setValue(cfg.deathCounter.logoutDeaths)
    end
    setOnOffButtonStyle(othersWindow.deathActionLogoutBtn, "Action Logout", cfg.deathCounter.actionMode == "logout")
    setOnOffButtonStyle(othersWindow.deathActionBotsBtn, "Action Cave+Target", cfg.deathCounter.actionMode == "bots")
    setOnOffButtonStyle(othersWindow.deathActionTrainerBtn, "Action Trainer", cfg.deathCounter.actionMode == "trainer")
    setOnOffButtonStyle(othersWindow.deathActionExitBtn, "Action Exit", cfg.deathCounter.actionMode == "exit")
    local killCount = getKillCount()
    if killCount < cfg.killCounter.killLimit then
        cfg.killCounter.actionPending = false
    end
    othersWindow.killCountLabel:setText(string.format("Kill count: %d / Limit: %d", killCount, cfg.killCounter.killLimit))
    othersWindow.killCountLabel:setColor(killCountColor(killCount, cfg.killCounter.killLimit))
    setOnOffButtonStyle(othersWindow.killMacroBtn, "Kill", cfg.killCounter.enabled)
    if othersWindow.killLimitSpin:getValue() ~= cfg.killCounter.killLimit then
        othersWindow.killLimitSpin:setValue(cfg.killCounter.killLimit)
    end
    setOnOffButtonStyle(othersWindow.killActionLogoutBtn, "Action Logout", cfg.killCounter.actionMode == "logout")
    setOnOffButtonStyle(othersWindow.killActionBotsBtn, "Action Cave+Target", cfg.killCounter.actionMode == "bots")
    setOnOffButtonStyle(othersWindow.killActionTrainerBtn, "Action Trainer", cfg.killCounter.actionMode == "trainer")
    setOnOffButtonStyle(othersWindow.killActionExitBtn, "Action Exit", cfg.killCounter.actionMode == "exit")
    for i = 1, POT_EXP_SLOT_COUNT do
        local itemSlot = getPotSlotWidgetByIndex(i)
        if itemSlot and itemSlot:getItemId() ~= (cfg.potExp.items[i] or 0) then
            itemSlot:setItemId(cfg.potExp.items[i] or 0)
        end
    end

    itemCounterUiSyncing = true
    for i = 1, ANALYZER_ITEM_COUNTER_SLOTS do
        local slot = getItemCounterSlot(i)
        local itemWidget = othersWindow:recursiveGetChildById("itemCounter" .. i .. "Item")
        local hudCheck = othersWindow:recursiveGetChildById("itemCounter" .. i .. "HudCheck")
        local nameEdit = othersWindow:recursiveGetChildById("itemCounter" .. i .. "NameEdit")
        if itemWidget and slot and itemWidget.getItemId and itemWidget.setItemId then
            local targetValue = sanitizeItemCounterId(slot.itemId)
            if itemWidget:getItemId() ~= targetValue then
                itemWidget:setItemId(targetValue)
            end
        end
        if nameEdit and slot and nameEdit.getText and nameEdit.setText then
            local targetText = tostring(slot.displayName or "")
            if nameEdit:getText() ~= targetText then
                nameEdit:setText(targetText)
            end
        end
        if hudCheck and hudCheck.setChecked and slot then
            hudCheck:setChecked(slot.showOnHud == true)
        end
    end
    itemCounterUiSyncing = false
end

local function cyclePotUseMode()
    local currentMode = cfg.potExp.useMode or "AUTO"
    for i = 1, #POT_USE_MODES do
        if POT_USE_MODES[i] == currentMode then
            cfg.potExp.useMode = POT_USE_MODES[(i % #POT_USE_MODES) + 1]
            return
        end
    end
    cfg.potExp.useMode = POT_USE_MODES[1]
end

local function setSkillEnabled(skillKey, enabled)
    if not cfg.hud.skillSelection then
        cfg.hud.skillSelection = {}
    end
    cfg.hud.skillSelection[skillKey] = enabled == true
    applySkillSelection()
    if cfg.enabled then
        updateHud()
    end
    updateOthersWindow()
end

othersWindow.enableBtn.onClick = function()
    setAnalyzerEnabled(not cfg.enabled)
    updateOthersWindow()
end

othersWindow.resetBtn.onClick = function()
    resetSessionAndNotify()
    updateOthersWindow()
end

othersWindow.skillsBtn.onClick = function()
    cfg.hud.showSkills = not cfg.hud.showSkills
    if cfg.enabled then
        updateHud()
    end
    updateOthersWindow()
end

othersWindow.compactBtn.onClick = function()
    cfg.hud.compact = not cfg.hud.compact
    if cfg.enabled then
        updateHud()
    end
    updateOthersWindow()
end

othersWindow.helpBtn.onClick = function()
    openAnalyzerHelpWindow()
end

othersWindow.skillMagicCheck.onClick = function(widget)
    setSkillEnabled("magic", not (cfg.hud.skillSelection.magic == true))
end

othersWindow.skillFistCheck.onClick = function(widget)
    setSkillEnabled("fist", not (cfg.hud.skillSelection.fist == true))
end

othersWindow.skillClubCheck.onClick = function(widget)
    setSkillEnabled("club", not (cfg.hud.skillSelection.club == true))
end

othersWindow.skillSwordCheck.onClick = function(widget)
    setSkillEnabled("sword", not (cfg.hud.skillSelection.sword == true))
end

othersWindow.skillAxeCheck.onClick = function(widget)
    setSkillEnabled("axe", not (cfg.hud.skillSelection.axe == true))
end

othersWindow.skillDistanceCheck.onClick = function(widget)
    setSkillEnabled("distance", not (cfg.hud.skillSelection.distance == true))
end

othersWindow.skillShieldCheck.onClick = function(widget)
    setSkillEnabled("shielding", not (cfg.hud.skillSelection.shielding == true))
end

othersWindow.skillFishingCheck.onClick = function(widget)
    setSkillEnabled("fishing", not (cfg.hud.skillSelection.fishing == true))
end

othersWindow.hudPosXSpin.onValueChange = function(widget, value)
    if souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.hudPosUiSyncing == true then
        return
    end
    cfg.hud.posX = math.max(0, math.min(5000, tonumber(value) or cfg.hud.posX or 18))
    widget:setValue(cfg.hud.posX)
    if souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.applyHudPosition then
        souleAnalyzerHudRuntime.applyHudPosition()
    end
end

othersWindow.hudPosYSpin.onValueChange = function(widget, value)
    if souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.hudPosUiSyncing == true then
        return
    end
    cfg.hud.posY = math.max(0, math.min(5000, tonumber(value) or cfg.hud.posY or 120))
    widget:setValue(cfg.hud.posY)
    if souleAnalyzerHudRuntime and souleAnalyzerHudRuntime.applyHudPosition then
        souleAnalyzerHudRuntime.applyHudPosition()
    end
end

local function applySystemHudSelection(key, checked)
    if cfg.hud and cfg.hud._systemStatusUiSyncing == true then
        return
    end
    setSystemHudSelection(key, checked == true)
    if cfg.enabled then
        updateHud()
    end
    updateOthersWindow()
end

othersWindow.sysHpToolsCheck.onClick = function(widget)
    applySystemHudSelection("hpTools", not isSystemSelectedForHud("hpTools"))
end

othersWindow.sysAttackCheck.onClick = function(widget)
    applySystemHudSelection("attack", not isSystemSelectedForHud("attack"))
end

othersWindow.sysRingsCheck.onClick = function(widget)
    applySystemHudSelection("rings", not isSystemSelectedForHud("rings"))
end

othersWindow.sysAmuletsCheck.onClick = function(widget)
    applySystemHudSelection("amulets", not isSystemSelectedForHud("amulets"))
end

othersWindow.sysCavebotCheck.onClick = function(widget)
    applySystemHudSelection("cavebot", not isSystemSelectedForHud("cavebot"))
end

othersWindow.sysTargetbotCheck.onClick = function(widget)
    applySystemHudSelection("targetbot", not isSystemSelectedForHud("targetbot"))
end

othersWindow.battleEnableBtn.onClick = function()
    cfg.battleList.enabled = not cfg.battleList.enabled
    ensureBattleListFilterInstalled()
    refreshBattleList()
    updateOthersWindow()
end

othersWindow.battleMonstersBtn.onClick = function()
    cfg.battleList.monsters = not cfg.battleList.monsters
    ensureBattleListFilterInstalled()
    refreshBattleList()
    updateOthersWindow()
end

othersWindow.battlePlayersBtn.onClick = function()
    cfg.battleList.players = not cfg.battleList.players
    ensureBattleListFilterInstalled()
    refreshBattleList()
    updateOthersWindow()
end

othersWindow.battleNpcBtn.onClick = function()
    cfg.battleList.npc = not cfg.battleList.npc
    ensureBattleListFilterInstalled()
    refreshBattleList()
    updateOthersWindow()
end

othersWindow.battlePartyBtn.onClick = function()
    cfg.battleList.party = not cfg.battleList.party
    ensureBattleListFilterInstalled()
    refreshBattleList()
    updateOthersWindow()
end

othersWindow.battleGuildBtn.onClick = function()
    cfg.battleList.guild = not cfg.battleList.guild
    ensureBattleListFilterInstalled()
    refreshBattleList()
    updateOthersWindow()
end

othersWindow.battleEnemyBtn.onClick = function()
    cfg.battleList.enemy = not cfg.battleList.enemy
    ensureBattleListFilterInstalled()
    refreshBattleList()
    updateOthersWindow()
end

othersWindow.battleNoGuildBtn.onClick = function()
    cfg.battleList.noGuild = not cfg.battleList.noGuild
    ensureBattleListFilterInstalled()
    refreshBattleList()
    updateOthersWindow()
end

othersWindow.battleSkullBtn.onClick = function()
    cfg.battleList.skull = not cfg.battleList.skull
    ensureBattleListFilterInstalled()
    refreshBattleList()
    updateOthersWindow()
end

othersWindow.potEnableBtn.onClick = function()
    cfg.potExp.enabled = not cfg.potExp.enabled
    cfg.potExp.pendingUse = false
    if cfg.potExp.enabled then
        cfg.potExp.lastUseMs = 0
        cfg.potExp.lastTryMs = 0
    end
    updateOthersWindow()
end

othersWindow.potPzBtn.onClick = function()
    cfg.potExp.useInPz = not cfg.potExp.useInPz
    updateOthersWindow()
end

othersWindow.potModeBtn.onClick = function()
    cyclePotUseMode()
    updateOthersWindow()
end

othersWindow.potNoTargetBtn.onClick = function()
    cfg.potExp.onlyNoTarget = not cfg.potExp.onlyNoTarget
    updateOthersWindow()
end

othersWindow.potNoMonstersBtn.onClick = function()
    cfg.potExp.onlyNoMonsters = not cfg.potExp.onlyNoMonsters
    updateOthersWindow()
end

othersWindow.potDelayScroll.onValueChange = function(widget, value)
    cfg.potExp.delayMinutes = math.max(1, math.min(120, tonumber(value) or 1))
    othersWindow.potDelayLabel:setText("Delay: " .. formatDelayMinutes(cfg.potExp.delayMinutes))
end

othersWindow.deathMacroBtn.onClick = function()
    cfg.deathCounter.enabled = not cfg.deathCounter.enabled
    if not cfg.deathCounter.enabled then
        cfg.deathCounter.actionPending = false
    else
        tryDeathActions()
    end
    updateOthersWindow()
end

othersWindow.deathLimitSpin.onValueChange = function(widget, value)
    cfg.deathCounter.logoutDeaths = math.max(1, tonumber(value) or DEFAULT_DEATH_LOGOUT)
    cfg.deathCounter.actionPending = false
    tryDeathActions()
    updateOthersWindow()
end

othersWindow.deathActionLogoutBtn.onClick = function()
    setDeathActionMode("logout")
    cfg.deathCounter.actionPending = false
    tryDeathActions()
    updateOthersWindow()
end

othersWindow.deathActionBotsBtn.onClick = function()
    setDeathActionMode("bots")
    cfg.deathCounter.actionPending = false
    tryDeathActions()
    updateOthersWindow()
end

othersWindow.deathActionTrainerBtn.onClick = function()
    setDeathActionMode("trainer")
    cfg.deathCounter.actionPending = false
    tryDeathActions()
    updateOthersWindow()
end

othersWindow.deathActionExitBtn.onClick = function()
    setDeathActionMode("exit")
    cfg.deathCounter.actionPending = false
    tryDeathActions()
    updateOthersWindow()
end

othersWindow.deathResetBtn.onClick = function()
    setDeathCount(0)
    cfg.deathCounter.actionPending = false
    updateOthersWindow()
end

othersWindow.killMacroBtn.onClick = function()
    cfg.killCounter.enabled = not cfg.killCounter.enabled
    if not cfg.killCounter.enabled then
        cfg.killCounter.actionPending = false
    else
        tryKillActions()
    end
    updateOthersWindow()
end

othersWindow.killLimitSpin.onValueChange = function(widget, value)
    cfg.killCounter.killLimit = math.max(1, tonumber(value) or DEFAULT_KILL_LIMIT)
    cfg.killCounter.actionPending = false
    tryKillActions()
    updateOthersWindow()
end

othersWindow.killActionLogoutBtn.onClick = function()
    setKillActionMode("logout")
    cfg.killCounter.actionPending = false
    tryKillActions()
    updateOthersWindow()
end

othersWindow.killActionBotsBtn.onClick = function()
    setKillActionMode("bots")
    cfg.killCounter.actionPending = false
    tryKillActions()
    updateOthersWindow()
end

othersWindow.killActionTrainerBtn.onClick = function()
    setKillActionMode("trainer")
    cfg.killCounter.actionPending = false
    tryKillActions()
    updateOthersWindow()
end

othersWindow.killActionExitBtn.onClick = function()
    setKillActionMode("exit")
    cfg.killCounter.actionPending = false
    tryKillActions()
    updateOthersWindow()
end

othersWindow.killResetBtn.onClick = function()
    setKillCount(0)
    cfg.killCounter.actionPending = false
    updateOthersWindow()
end

othersWindow.closeBtn.onClick = function()
    othersWindow:hide()
end

macro(1000, function()
    scanItemCounters(false)
    if othersWindow and othersWindow:isVisible() then
        updateOthersWindow()
    end
end)

local mainUI = setupUI([[
Panel
  height: 20

  Button
    id: othersBtn
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    text-align: center
    font: verdana-11px-rounded
    text: Others
]])

souleAnalyzerMainUI = mainUI

setTooltipPair(mainUI.othersBtn, "Abre a janela Others com configuracoes do Analyzer.", "Opens the Others window with Analyzer settings.")

mainUI.othersBtn.onClick = function()
    updateOthersWindow()
    othersWindow:show()
    othersWindow:raise()
    othersWindow:focus()
end

ensureBattleListFilterInstalled()
refreshBattleList()
setHudState()
tryDeathActions()
tryKillActions()
updateOthersWindow()
