-- CAVEBOT FUNCTIONS - SISTEMA DE CHECKERS
-- Sistema configuravel de checks para o CaveBot
-- Ultima modificacao: 2025-10-28
-- Autor: Dev Team
-- ============================================
Checker = {}
local TASKER_MAX_MONSTERS = 5

-- ============================================
-- SISTEMA DE STORAGE E CONFIGURACOES
-- ============================================

-- Storage padrao (valores iniciais)
if type(storage.cavebotChecks) ~= "table" then
  storage.cavebotChecks = {}
end

-- Remove configuracoes legadas do Market (desativado por enquanto) apenas uma vez.
if storage.cavebotChecks._legacyMarketCleared ~= true then
  storage.marketSupplies = nil
  storage.marketBuy = nil
  storage.marketItems = nil
  storage.market = nil
  storage.cavebotChecks.market = nil
  storage.cavebotChecks.marketBuy = nil
  storage.cavebotChecks.marketSupplies = nil
  storage.cavebotChecks._legacyMarketCleared = true
end

-- Inicializar configuracoes se nao existirem
if type(storage.cavebotChecks.cap) ~= "table" then
  storage.cavebotChecks.cap = {
    enabled = true,
    minCap = 500,
    labelSair = "loot",
    labelContinuar = "capboas"
  }
end

if type(storage.cavebotChecks.cap2) ~= "table" then
  storage.cavebotChecks.cap2 = {
    enabled = true,
    minCap = 500,
    labelSair = "loot1",
    labelContinuar = "capboas2"
  }
end

if type(storage.cavebotChecks.cap3) ~= "table" then
  storage.cavebotChecks.cap3 = {
    enabled = true,
    minCap = 500,
    labelSair = "loot2",
    labelContinuar = "capboas3"
  }
end

if type(storage.cavebotChecks.stamina) ~= "table" then
  storage.cavebotChecks.stamina = {
    enabled = true,
    minStamina = 960,
    labelDescansar = "descansar",
    labelContinuar = "staminaok"
  }
end

if type(storage.cavebotChecks.stamina2) ~= "table" then
  storage.cavebotChecks.stamina2 = {
    enabled = true,
    minStamina = 960,
    labelDescansar = "descansar",
    labelContinuar = "staminaok"
  }
end

if type(storage.cavebotChecks.stamina3) ~= "table" then
  storage.cavebotChecks.stamina3 = {
    enabled = true,
    minStamina = 960,
    labelDescansar = "descansar",
    labelContinuar = "staminaok"
  }
end

if type(storage.cavebotStats) ~= "table" then
  storage.cavebotStats = {}
end

local function normalizeStaminaEntry(entry, index)
  if not entry then
    return nil
  end
  local suffix = index and tostring(index) or ""
  local name = entry.name
  if not name or name == "" then
    name = "Stamina" .. suffix
  end

  local hours = tonumber(entry.hours)
  local minutes = tonumber(entry.minutes)
  if hours == nil or minutes == nil then
    local total = tonumber(entry.minStamina) or 0
    hours = hours or math.floor(total / 60)
    minutes = minutes or (total % 60)
  end

  entry.name = name
  entry.hours = hours or 0
  entry.minutes = minutes or 0
  entry.labelRest = entry.labelRest or entry.labelDescansar or "descansar"
  entry.labelContinue = entry.labelContinue or entry.labelContinuar or "staminaok"
  if entry.enabled == nil then
    entry.enabled = true
  end
  entry.minStamina = (entry.hours * 60) + entry.minutes
  return entry
end

local function isDefaultStaminaEntry(entry, index)
  if not entry then
    return true
  end
  normalizeStaminaEntry(entry, index)
  return entry.name == ("Stamina" .. tostring(index or "")) and
    tonumber(entry.hours) == 16 and
    tonumber(entry.minutes) == 0 and
    entry.labelRest == "descansar" and
    entry.labelContinue == "staminaok" and
    entry.enabled ~= false
end

local function trimDefaultEntries(list, isDefaultFn)
  if not list or #list <= 1 then
    return
  end
  for i = #list, 2, -1 do
    local entry = list[i]
    if entry and entry.userAdded then
      -- Preserve user-added entries even if they match defaults.
    elseif isDefaultFn(entry, i) then
      table.remove(list, i)
    end
  end
end

local function normalizeNumericIndexedArray(value)
  if type(value) ~= "table" then
    return {}
  end

  local indexed = {}
  for key, entry in pairs(value) do
    if entry ~= nil then
      local idx = nil
      if type(key) == "number" then
        idx = key
      elseif type(key) == "string" then
        idx = tonumber(key)
      end
      if idx and idx > 0 and idx == math.floor(idx) and indexed[idx] == nil then
        indexed[idx] = entry
      end
    end
  end

  local orderedKeys = {}
  for idx, _ in pairs(indexed) do
    orderedKeys[#orderedKeys + 1] = idx
  end
  table.sort(orderedKeys)

  local out = {}
  for _, idx in ipairs(orderedKeys) do
    out[#out + 1] = indexed[idx]
  end
  return out
end

local function staminaEntryFromLegacy(cfg, defaultName)
  cfg = cfg or {}
  local total = tonumber(cfg.minStamina) or 0
  return normalizeStaminaEntry({
    name = defaultName,
    hours = math.floor(total / 60),
    minutes = total % 60,
    labelRest = cfg.labelDescansar or cfg.labelRest or "descansar",
    labelContinue = cfg.labelContinuar or cfg.labelContinue or "staminaok",
    enabled = cfg.enabled ~= false,
    minStamina = total
  })
end

local function applyStaminaEntryToLegacy(entry, legacy)
  legacy = legacy or {}
  if not entry then
    legacy.enabled = false
    return legacy
  end
  normalizeStaminaEntry(entry)
  legacy.enabled = entry.enabled ~= false
  legacy.minStamina = entry.minStamina or ((entry.hours or 0) * 60 + (entry.minutes or 0))
  legacy.labelDescansar = entry.labelRest or "descansar"
  legacy.labelContinuar = entry.labelContinue or "staminaok"
  return legacy
end

local function ensureStaminaStatsList()
  if type(storage.cavebotStats) ~= "table" then
    storage.cavebotStats = {}
  end
  local list = normalizeNumericIndexedArray(storage.cavebotStats.stamina)
  storage.cavebotStats.stamina = list

  if #list == 0 then
    list[1] = staminaEntryFromLegacy(storage.cavebotChecks.stamina, "Stamina1")
  else
    for index, entry in ipairs(list) do
      normalizeStaminaEntry(entry, index)
    end
  end
  trimDefaultEntries(list, isDefaultStaminaEntry)
  return list
end

local function syncStaminaLegacyFromList()
  local list = storage.cavebotStats and storage.cavebotStats.stamina
  if not list then
    return
  end
  storage.cavebotChecks.stamina = applyStaminaEntryToLegacy(list[1], storage.cavebotChecks.stamina)
  storage.cavebotChecks.stamina2 = applyStaminaEntryToLegacy(list[2], storage.cavebotChecks.stamina2)
  storage.cavebotChecks.stamina3 = applyStaminaEntryToLegacy(list[3], storage.cavebotChecks.stamina3)
end

ensureStaminaStatsList()
syncStaminaLegacyFromList()

local function getCapDefaults(index)
  local minCap = 500
  local labelSair = "loot"
  local labelContinuar = "capboas"
  if index and index > 1 then
    labelSair = "loot" .. tostring(index - 1)
    labelContinuar = "capboas" .. tostring(index)
  end
  return minCap, labelSair, labelContinuar
end

local function normalizeCapEntry(entry, index)
  if not entry then
    return nil
  end
  local suffix = index and tostring(index) or ""
  local name = entry.name
  if not name or name == "" then
    name = "Cap" .. suffix
  end

  local defaultMin, defaultSair, defaultContinuar = getCapDefaults(index)
  entry.name = name
  entry.minCap = tonumber(entry.minCap) or tonumber(entry.min) or defaultMin
  entry.labelSair = entry.labelSair or entry.labelExit or defaultSair
  entry.labelContinuar = entry.labelContinuar or entry.labelContinue or defaultContinuar
  if entry.enabled == nil then
    entry.enabled = true
  end
  return entry
end

local function isDefaultCapEntry(entry, index)
  if not entry then
    return true
  end
  normalizeCapEntry(entry, index)
  local defaultMin, defaultSair, defaultContinuar = getCapDefaults(index)
  return entry.name == ("Cap" .. tostring(index or "")) and
    tonumber(entry.minCap) == defaultMin and
    entry.labelSair == defaultSair and
    entry.labelContinuar == defaultContinuar and
    entry.enabled ~= false
end

local function capEntryFromLegacy(cfg, defaultName)
  cfg = cfg or {}
  local index = tonumber(defaultName:match("(%d+)$") or "")
  local defaultMin, defaultSair, defaultContinuar = getCapDefaults(index)
  return normalizeCapEntry({
    name = defaultName,
    minCap = tonumber(cfg.minCap) or defaultMin,
    labelSair = cfg.labelSair or defaultSair,
    labelContinuar = cfg.labelContinuar or defaultContinuar,
    enabled = cfg.enabled ~= false
  })
end

local function applyCapEntryToLegacy(entry, legacy, index)
  legacy = legacy or {}
  if not entry then
    legacy.enabled = false
    return legacy
  end
  normalizeCapEntry(entry, index)
  local defaultMin, defaultSair, defaultContinuar = getCapDefaults(index)
  legacy.enabled = entry.enabled ~= false
  legacy.minCap = tonumber(entry.minCap) or defaultMin
  legacy.labelSair = entry.labelSair or defaultSair
  legacy.labelContinuar = entry.labelContinuar or defaultContinuar
  return legacy
end

local function ensureCapStatsList()
  if type(storage.cavebotStats) ~= "table" then
    storage.cavebotStats = {}
  end
  local list = normalizeNumericIndexedArray(storage.cavebotStats.cap)
  storage.cavebotStats.cap = list

  if #list == 0 then
    list[1] = capEntryFromLegacy(storage.cavebotChecks.cap, "Cap1")
  else
    for index, entry in ipairs(list) do
      normalizeCapEntry(entry, index)
    end
  end
  trimDefaultEntries(list, isDefaultCapEntry)
  return list
end

local function syncCapLegacyFromList()
  local list = storage.cavebotStats and storage.cavebotStats.cap
  if not list then
    return
  end
  storage.cavebotChecks.cap = applyCapEntryToLegacy(list[1], storage.cavebotChecks.cap, 1)
  storage.cavebotChecks.cap2 = applyCapEntryToLegacy(list[2], storage.cavebotChecks.cap2, 2)
  storage.cavebotChecks.cap3 = applyCapEntryToLegacy(list[3], storage.cavebotChecks.cap3, 3)
end

ensureCapStatsList()
syncCapLegacyFromList()

local function getLevelDefaults(index)
  if index == 1 then
    return 1000, "reset", "hunt"
  elseif index == 2 then
    return 500, "depot", "hunt2"
  elseif index == 3 then
    return 2000, "bank", "hunt3"
  elseif index == 4 then
    return 3000, "temple", "hunt4"
  elseif index == 5 then
    return 5000, "logout", "hunt5"
  end
  return 1000, "reset" .. tostring(index or ""), "hunt" .. tostring(index or "")
end

local function normalizeLevelEntry(entry, index)
  if not entry then
    return nil
  end
  local suffix = index and tostring(index) or ""
  local name = entry.name
  if not name or name == "" then
    name = "Level" .. suffix
  end

  local defaultMin, defaultSair, defaultContinuar = getLevelDefaults(index)
  entry.name = name
  entry.minLevel = tonumber(entry.minLevel) or defaultMin
  entry.labelSair = entry.labelSair or entry.labelExit or defaultSair
  entry.labelContinuar = entry.labelContinuar or entry.labelContinue or defaultContinuar
  if entry.enabled == nil then
    entry.enabled = true
  end
  return entry
end

local function isDefaultLevelEntry(entry, index)
  if not entry then
    return true
  end
  normalizeLevelEntry(entry, index)
  local defaultMin, defaultSair, defaultContinuar = getLevelDefaults(index)
  return entry.name == ("Level" .. tostring(index or "")) and
    tonumber(entry.minLevel) == defaultMin and
    entry.labelSair == defaultSair and
    entry.labelContinuar == defaultContinuar and
    entry.enabled ~= false
end

local function levelEntryFromLegacy(cfg, defaultName, index)
  cfg = cfg or {}
  local defaultMin, defaultSair, defaultContinuar = getLevelDefaults(index)
  return normalizeLevelEntry({
    name = defaultName,
    minLevel = tonumber(cfg.minLevel) or defaultMin,
    labelSair = cfg.labelSair or defaultSair,
    labelContinuar = cfg.labelContinuar or defaultContinuar,
    enabled = cfg.enabled ~= false
  }, index)
end

local function applyLevelEntryToLegacy(entry, legacy, index)
  legacy = legacy or {}
  if not entry then
    legacy.enabled = false
    return legacy
  end
  normalizeLevelEntry(entry, index)
  local defaultMin, defaultSair, defaultContinuar = getLevelDefaults(index)
  legacy.enabled = entry.enabled ~= false
  legacy.minLevel = tonumber(entry.minLevel) or defaultMin
  legacy.labelSair = entry.labelSair or defaultSair
  legacy.labelContinuar = entry.labelContinuar or defaultContinuar
  return legacy
end

local function ensureLevelStatsList()
  if type(storage.cavebotStats) ~= "table" then
    storage.cavebotStats = {}
  end
  local list = normalizeNumericIndexedArray(storage.cavebotStats.level)
  storage.cavebotStats.level = list

  if #list == 0 then
    list[1] = levelEntryFromLegacy(storage.cavebotChecks.level1, "Level1", 1)
  else
    for index, entry in ipairs(list) do
      normalizeLevelEntry(entry, index)
    end
  end
  trimDefaultEntries(list, isDefaultLevelEntry)
  return list
end

local function syncLevelLegacyFromList()
  local list = storage.cavebotStats and storage.cavebotStats.level
  if not list then
    return
  end
  storage.cavebotChecks.level1 = applyLevelEntryToLegacy(list[1], storage.cavebotChecks.level1, 1)
  storage.cavebotChecks.level2 = applyLevelEntryToLegacy(list[2], storage.cavebotChecks.level2, 2)
  storage.cavebotChecks.level3 = applyLevelEntryToLegacy(list[3], storage.cavebotChecks.level3, 3)
  storage.cavebotChecks.level4 = applyLevelEntryToLegacy(list[4], storage.cavebotChecks.level4, 4)
  storage.cavebotChecks.level5 = applyLevelEntryToLegacy(list[5], storage.cavebotChecks.level5, 5)
end

ensureLevelStatsList()
syncLevelLegacyFromList()

local function normalizeTimeEntry(entry, index, defaultInvert)
  if not entry then
    return nil
  end
  local suffix = index and tostring(index) or ""
  local name = entry.name
  if not name or name == "" then
    name = "Time" .. suffix
  end

  local invert = entry.invert
  if invert == nil then
    invert = defaultInvert == true
  end
  entry.invert = invert
  entry.name = name
  entry.hourStart = tonumber(entry.hourStart) or 0
  entry.minuteStart = tonumber(entry.minuteStart) or 0
  entry.hourEnd = tonumber(entry.hourEnd) or 23
  entry.minuteEnd = tonumber(entry.minuteEnd) or 59
  if invert then
    entry.labelInside = entry.labelInside or "hunt"
    entry.labelOutside = entry.labelOutside or "wait"
  else
    entry.labelInside = entry.labelInside or "event"
    entry.labelOutside = entry.labelOutside or "wait"
  end
  if entry.enabled == nil then
    entry.enabled = true
  end
  return entry
end

local function getTimeDefaults(index)
  local invert = (index == 1)
  local labelInside = invert and "hunt" or "event"
  local labelOutside = "wait"
  return invert, labelInside, labelOutside
end

local function isDefaultTimeEntry(entry, index)
  if not entry then
    return true
  end
  local defaultInvert, defaultInside, defaultOutside = getTimeDefaults(index)
  normalizeTimeEntry(entry, index, defaultInvert)
  return entry.name == ("Time" .. tostring(index or "")) and
    tonumber(entry.hourStart) == 0 and
    tonumber(entry.minuteStart) == 0 and
    tonumber(entry.hourEnd) == 23 and
    tonumber(entry.minuteEnd) == 59 and
    entry.invert == defaultInvert and
    entry.labelInside == defaultInside and
    entry.labelOutside == defaultOutside and
    entry.enabled ~= false
end

local function timeEntryFromLegacy(cfg, defaultName, index, invert)
  cfg = cfg or {}
  return normalizeTimeEntry({
    name = defaultName,
    hourStart = tonumber(cfg.hourStart) or 0,
    minuteStart = tonumber(cfg.minuteStart) or 0,
    hourEnd = tonumber(cfg.hourEnd) or 23,
    minuteEnd = tonumber(cfg.minuteEnd) or 59,
    labelInside = cfg.labelInside,
    labelOutside = cfg.labelOutside,
    enabled = cfg.enabled ~= false,
    invert = invert == true
  }, index, invert)
end

local function applyTimeEntryToLegacy(entry, legacy, index, defaultInvert)
  legacy = legacy or {}
  if not entry then
    legacy.enabled = false
    return legacy
  end
  normalizeTimeEntry(entry, index, defaultInvert)
  legacy.enabled = entry.enabled ~= false
  legacy.hourStart = tonumber(entry.hourStart) or 0
  legacy.minuteStart = tonumber(entry.minuteStart) or 0
  legacy.hourEnd = tonumber(entry.hourEnd) or 23
  legacy.minuteEnd = tonumber(entry.minuteEnd) or 59
  legacy.labelInside = entry.labelInside or legacy.labelInside
  legacy.labelOutside = entry.labelOutside or legacy.labelOutside
  return legacy
end

local function ensureTimeStatsList()
  if type(storage.cavebotStats) ~= "table" then
    storage.cavebotStats = {}
  end
  local list = normalizeNumericIndexedArray(storage.cavebotStats.time)
  storage.cavebotStats.time = list

  if #list == 0 then
    list[1] = timeEntryFromLegacy(storage.cavebotChecks.time1, "Time1", 1, true)
  else
    for index, entry in ipairs(list) do
      local invert = (index == 1)
      normalizeTimeEntry(entry, index, invert)
    end
  end
  trimDefaultEntries(list, isDefaultTimeEntry)
  return list
end

local function syncTimeLegacyFromList()
  local list = storage.cavebotStats and storage.cavebotStats.time
  if not list then
    return
  end
  storage.cavebotChecks.time1 = applyTimeEntryToLegacy(list[1], storage.cavebotChecks.time1, 1, true)
  storage.cavebotChecks.time2 = applyTimeEntryToLegacy(list[2], storage.cavebotChecks.time2, 2, false)
  storage.cavebotChecks.time3 = applyTimeEntryToLegacy(list[3], storage.cavebotChecks.time3, 3, false)
  storage.cavebotChecks.time4 = applyTimeEntryToLegacy(list[4], storage.cavebotChecks.time4, 4, false)
end

ensureTimeStatsList()
syncTimeLegacyFromList()

if type(storage.cavebotChecks.sairTrainer) ~= "table" then
  storage.cavebotChecks.sairTrainer = {
    enabled = true,
    minStamina = 960,
    labelSair = "sair",
    labelContinuar = "continuar"
  }
end

if storage.cavebotChecks.sairTrainerMacroEnabled == nil then
  storage.cavebotChecks.sairTrainerMacroEnabled = false
end

if storage.cavebotChecks.sairTrainer and storage.cavebotChecks.sairTrainer.trainerName == nil then
  storage.cavebotChecks.sairTrainer.trainerName = ""
end

if storage.cavebotChecks.sairTrainer and storage.cavebotChecks.sairTrainer.macroActive == nil then
  storage.cavebotChecks.sairTrainer.macroActive = false
end

if type(storage.cavebotChecks.pz) ~= "table" then
  storage.cavebotChecks.pz = {
    enabled = true,
    labelPZ = "Templo"
  }
end

if type(storage.cavebotChecks.level1) ~= "table" then
  storage.cavebotChecks.level1 = {
    enabled = true,
    minLevel = 1000,
    labelSair = "reset",
    labelContinuar = "hunt"
  }
end

if type(storage.cavebotChecks.level2) ~= "table" then
  storage.cavebotChecks.level2 = {
    enabled = true,
    minLevel = 500,
    labelSair = "depot",
    labelContinuar = "hunt2"
  }
end

if type(storage.cavebotChecks.level3) ~= "table" then
  storage.cavebotChecks.level3 = {
    enabled = true,
    minLevel = 2000,
    labelSair = "bank",
    labelContinuar = "hunt3"
  }
end

if type(storage.cavebotChecks.level4) ~= "table" then
  storage.cavebotChecks.level4 = {
    enabled = true,
    minLevel = 3000,
    labelSair = "temple",
    labelContinuar = "hunt4"
  }
end

if type(storage.cavebotChecks.level5) ~= "table" then
  storage.cavebotChecks.level5 = {
    enabled = true,
    minLevel = 5000,
    labelSair = "logout",
    labelContinuar = "hunt5"
  }
end

if type(storage.cavebotChecks.random) ~= "table" then
  storage.cavebotChecks.random = {
    enabled = true,
    labels = "Hunt1,Hunt2,Hunt3",
    currentIndex = 1
  }
end

if type(storage.cavebotChecks.closeBackpacks) ~= "table" then
  storage.cavebotChecks.closeBackpacks = {
    enabled = true
  }
end

if type(storage.cavebotChecks.levitate) ~= "table" then
  storage.cavebotChecks.levitate = {
    upSpell = "exani hur up",
    downSpell = "exani hur down"
  }
end

if type(storage.cavebotChecks.toolWaypoints) ~= "table" then
  storage.cavebotChecks.toolWaypoints = {
    shovelId = 3457,
    ropeId = 3003,
    macheteId = 3308
  }
end

storage.cavebotChecks.toolWaypoints.shovelId = tonumber(storage.cavebotChecks.toolWaypoints.shovelId) or 3457
storage.cavebotChecks.toolWaypoints.ropeId = tonumber(storage.cavebotChecks.toolWaypoints.ropeId) or 3003
storage.cavebotChecks.toolWaypoints.macheteId = tonumber(storage.cavebotChecks.toolWaypoints.macheteId) or 3308

if type(storage.cavebotChecks.supply) ~= "table" then
  storage.cavebotChecks.supply = {
    enabled = true,
    okLabel = "hunt",
    lowLabel = "resupply",
    items = {}
  }
end

local function defaultBuySupplyConfig()
  return {
    enabled = true,
    npcName = "",
    npcNames = "",
    currentNpcIdx = 1,
    talkDelay = 500,
    maxPerBuy = 1000,
    items = {}
  }
end

if type(storage.cavebotChecks.buySupply) ~= "table" then
  storage.cavebotChecks.buySupply = defaultBuySupplyConfig()
end

if type(storage.cavebotChecks.buySupply2) ~= "table" then
  storage.cavebotChecks.buySupply2 = defaultBuySupplyConfig()
end

if type(storage.cavebotChecks.buySupply3) ~= "table" then
  storage.cavebotChecks.buySupply3 = defaultBuySupplyConfig()
end

if type(storage.cavebotChecks.buySupply4) ~= "table" then
  storage.cavebotChecks.buySupply4 = defaultBuySupplyConfig()
end

if type(storage.buySupplies) ~= "table" then
  storage.buySupplies = {
    enabled = true,
    talkDelay = 500,
    currentNpcIdx = 1,
    tradeRetries = 0,
    reachRetries = 0,
    lastNpcName = nil,
    items = {}
  }
end

local function migrateBuySupplies()
  local cfg = storage.buySupplies
  if cfg._migrated then
    return
  end
  if cfg.items and #cfg.items > 0 then
    cfg._migrated = true
    return
  end

  local sources = {
    storage.cavebotChecks.buySupply,
    storage.cavebotChecks.buySupply2,
    storage.cavebotChecks.buySupply3,
    storage.cavebotChecks.buySupply4
  }

  local priority = 1
  for _, src in ipairs(sources) do
    if src then
      if src.talkDelay and cfg.talkDelay == 500 then
        cfg.talkDelay = src.talkDelay
      end
      if src.enabled == false then
        cfg.enabled = false
      end
      local npcName = (src.npcName and src.npcName ~= "" and src.npcName) or (src.npcNames or "")
      if npcName ~= "" then
        local commaPos = npcName:find(",", 1, true)
        if commaPos then
          npcName = npcName:sub(1, commaPos - 1)
        end
      end
      for _, entry in ipairs(normalizeNumericIndexedArray(src.items)) do
        local id = tonumber(entry.id) or 0
        local amount = tonumber(entry.amount) or 0
        local entryNpc = (entry.npcName and entry.npcName ~= "" and entry.npcName) or npcName or ""
        if id > 0 or amount > 0 or entryNpc ~= "" then
          table.insert(cfg.items, {
            enabled = entry.enabled ~= false,
            id = id,
            amount = amount,
            npcName = entryNpc,
            maxPerBuy = tonumber(entry.maxPerBuy) or tonumber(src.maxPerBuy) or 1000,
            priority = tonumber(entry.priority) or priority
          })
          priority = priority + 1
        end
      end
    end
  end

  cfg._migrated = true
end

migrateBuySupplies()

if type(storage.cavebotChecks.time1) ~= "table" then
  storage.cavebotChecks.time1 = {
    enabled = true,
    hourStart = 0,
    minuteStart = 0,
    hourEnd = 23,
    minuteEnd = 59,
    labelInside = "hunt",
    labelOutside = "wait"
  }
end

if type(storage.cavebotChecks.time2) ~= "table" then
  storage.cavebotChecks.time2 = {
    enabled = true,
    hourStart = 0,
    minuteStart = 0,
    hourEnd = 23,
    minuteEnd = 59,
    labelInside = "event",
    labelOutside = "wait"
  }
end

if type(storage.cavebotChecks.time3) ~= "table" then
  storage.cavebotChecks.time3 = {
    enabled = true,
    hourStart = 0,
    minuteStart = 0,
    hourEnd = 23,
    minuteEnd = 59,
    labelInside = "event",
    labelOutside = "wait"
  }
end

if type(storage.cavebotChecks.time4) ~= "table" then
  storage.cavebotChecks.time4 = {
    enabled = true,
    hourStart = 0,
    minuteStart = 0,
    hourEnd = 23,
    minuteEnd = 59,
    labelInside = "event",
    labelOutside = "wait"
  }
end

if type(storage.cavebotChecks.tasker) ~= "table" then
  storage.cavebotChecks.tasker = {
    enabled = true,
    checkAllMonsters = true,
    labelEntrega = "entregartask",
    labelContinuar = "continuartask",
    monsters = {}
  }
end

if type(storage.cavebotChecks.trainer) ~= "table" then
  storage.cavebotChecks.trainer = {
    enabled = true,
    minHours = 16,
    minStamina = 960,
    labelTrainer = "irtreinar",
    labelContinuar = "aindanaotreinar",
    labelSairTrainer = "sairdotrainer",
    macroEnabled = false
  }
end

-- ===============================
-- UNIVERSAL BP MANAGER (STORAGE)
-- ===============================
local function compactNumericArray(tbl)
  return normalizeNumericIndexedArray(tbl)
end

local function sanitizeSupplyItems(options)
  options = options or {}
  local keepPlaceholders = options.keepPlaceholders == true
  local limit = options.limit or 10
  local cfg = storage.cavebotChecks.supply
  if not cfg or not cfg.items then
    return
  end

  local sanitized = {}
  local compactItems = compactNumericArray(cfg.items)
  for index, entry in ipairs(compactItems) do
    if entry then
      local itemId = tonumber(entry.id) or 0
      local amount = math.max(0, tonumber(entry.amount) or 0)
      local enabled = entry.enabled ~= false
      if keepPlaceholders or itemId > 100 then
        table.insert(sanitized, { id = itemId, amount = amount, enabled = enabled })
      end
      if #sanitized >= limit then
        break
      end
    end
  end

  cfg.items = sanitized
end

local function sanitizeBuySuppliesItems(options, cfgOverride)
  options = options or {}
  local keepPlaceholders = options.keepPlaceholders == true
  local cfg = cfgOverride or storage.buySupplies

  if not cfg or not cfg.items then
    return
  end

  local sanitized = {}
  local compactItems = compactNumericArray(cfg.items)
  for index, entry in ipairs(compactItems) do
    if entry then
      local itemId = tonumber(entry.id) or 0
      local amount = math.max(0, tonumber(entry.amount) or 0)
      local enabled = entry.enabled ~= false
      local npcName = entry.npcName or ""
      local maxPerBuy = tonumber(entry.maxPerBuy) or 1000
      local priority = tonumber(entry.priority) or index
      if keepPlaceholders or itemId > 100 or npcName ~= "" then
        table.insert(sanitized, {
          id = itemId,
          amount = amount,
          enabled = enabled,
          npcName = npcName,
          maxPerBuy = maxPerBuy,
          priority = priority
        })
      end
    end
  end

  cfg.items = sanitized
end

sanitizeSupplyItems()
sanitizeBuySuppliesItems(nil, storage.buySupplies)
sanitizeBuySuppliesItems(nil, storage.cavebotChecks.buySupply)
sanitizeBuySuppliesItems(nil, storage.cavebotChecks.buySupply2)
sanitizeBuySuppliesItems(nil, storage.cavebotChecks.buySupply3)
sanitizeBuySuppliesItems(nil, storage.cavebotChecks.buySupply4)

if storage.cavebotChecks and storage.cavebotChecks.tasker and type(storage.cavebotChecks.tasker.monsters) == "table" then
  storage.cavebotChecks.tasker.monsters = compactNumericArray(storage.cavebotChecks.tasker.monsters)
end

local taskerKills = {}
local taskerAnalyzerBaseline = {}
local taskerHasGlobalReset = false

local function normalizeTaskerMonsterName(name)
  local value = tostring(name or ""):lower()
  value = value:gsub("^%s+", ""):gsub("%s+$", "")
  value = value:gsub("%s+", " ")
  return value
end

local function normalizeTaskerMonsterEntry(entry)
  if type(entry) ~= "table" then
    entry = {}
  end
  if entry.enabled == nil then
    entry.enabled = true
  end
  entry.name = tostring(entry.name or "")
  entry.amount = math.max(0, tonumber(entry.amount) or 0)
  return entry
end

local function ensureTaskerConfig()
  if type(storage.cavebotChecks) ~= "table" then
    storage.cavebotChecks = {}
  end
  local cfg = storage.cavebotChecks.tasker
  if type(cfg) ~= "table" then
    cfg = {}
    storage.cavebotChecks.tasker = cfg
  end

  if cfg.enabled == nil then
    cfg.enabled = true
  end
  if cfg.checkAllMonsters == nil then
    cfg.checkAllMonsters = cfg.checkAll ~= false
  end
  cfg.checkAll = cfg.checkAllMonsters
  cfg.labelEntrega = cfg.labelEntrega or cfg.labelDone or "entregartask"
  cfg.labelContinuar = cfg.labelContinuar or cfg.labelContinue or "continuartask"

  if type(cfg.monsters) ~= "table" then
    cfg.monsters = {}
  end

  cfg.monsters = normalizeNumericIndexedArray(cfg.monsters)
  local normalizedList = {}
  for _, entry in ipairs(cfg.monsters) do
    if #normalizedList >= TASKER_MAX_MONSTERS then
      break
    end
    table.insert(normalizedList, normalizeTaskerMonsterEntry(entry))
  end
  cfg.monsters = normalizedList

  return cfg
end

local function ensureTrainerConfig()
  if type(storage.cavebotChecks) ~= "table" then
    storage.cavebotChecks = {}
  end
  local cfg = storage.cavebotChecks.trainer
  if type(cfg) ~= "table" then
    cfg = {}
    storage.cavebotChecks.trainer = cfg
  end

  if cfg.enabled == nil then
    cfg.enabled = true
  end

  local minHours = tonumber(cfg.minHours)
  if minHours == nil then
    minHours = tonumber(cfg.hours) or math.floor((tonumber(cfg.minStamina) or 960) / 60)
  end
  minHours = math.max(0, math.floor(minHours))
  cfg.minHours = minHours
  cfg.minStamina = minHours * 60

  cfg.labelTrainer = cfg.labelTrainer or cfg.labelTreinar or "irtreinar"
  cfg.labelContinuar = cfg.labelContinuar or cfg.labelContinue or "aindanaotreinar"
  cfg.labelSairTrainer = cfg.labelSairTrainer or cfg.labelExitTrainer or "sairdotrainer"

  if cfg.macroEnabled == nil then
    cfg.macroEnabled = storage.cavebotChecks.trainerMacroEnabled == true
  end
  storage.cavebotChecks.trainerMacroEnabled = cfg.macroEnabled and true or false

  if cfg.exitTriggered == nil then
    cfg.exitTriggered = false
  end

  return cfg
end

local function extractTaskerMonsterFromLoot(text)
  if type(text) ~= "string" then
    return nil
  end

  local rawName = text:match("[Ll]oot of%s+([^:]+):")
  if not rawName then
    return nil
  end

  local normalized = normalizeTaskerMonsterName(rawName)
  normalized = normalized:gsub("^an%s+", "")
  normalized = normalized:gsub("^a%s+", "")
  normalized = normalized:gsub("^the%s+", "")
  normalized = normalizeTaskerMonsterName(normalized)

  if normalized == "" then
    return nil
  end

  return normalized
end

local function getTaskerAnalyzerKills(monsterName, normalizedName)
  if not Analyzer or not Analyzer.getKillsAmount then
    return 0
  end

  local normalized = normalizedName or normalizeTaskerMonsterName(monsterName)
  return math.max(
    tonumber(Analyzer.getKillsAmount(monsterName or "")) or 0,
    tonumber(Analyzer.getKillsAmount(normalized)) or 0
  )
end

local function getTaskerMonsterKills(monsterName)
  local normalized = normalizeTaskerMonsterName(monsterName)
  if normalized == "" then
    return 0
  end

  local localCount = tonumber(taskerKills[normalized]) or 0
  local analyzerCount = getTaskerAnalyzerKills(monsterName, normalized)

  local baseline = tonumber(taskerAnalyzerBaseline[normalized])
  if baseline == nil then
    baseline = taskerHasGlobalReset and analyzerCount or 0
    taskerAnalyzerBaseline[normalized] = baseline
  end

  local analyzerAdjusted = analyzerCount - baseline
  if analyzerAdjusted < 0 then
    analyzerAdjusted = 0
  end

  return math.max(localCount, analyzerAdjusted)
end

onTextMessage(function(mode, text)
  local monsterName = extractTaskerMonsterFromLoot(text)
  if not monsterName then
    return
  end
  taskerKills[monsterName] = (tonumber(taskerKills[monsterName]) or 0) + 1
end)

ensureTaskerConfig()
ensureTrainerConfig()

-- ============================================
-- FUNCOES DOS CHECKERS
-- ============================================

-- Capacidade
local function runCapChecker(index)
  local list = storage.cavebotStats and storage.cavebotStats.cap
  local cfg
  if list and list[index] then
    cfg = normalizeCapEntry(list[index], index)
  elseif index == 1 then
    cfg = storage.cavebotChecks.cap
  elseif index == 2 then
    cfg = storage.cavebotChecks.cap2
  elseif index == 3 then
    cfg = storage.cavebotChecks.cap3
  end

  if not cfg or cfg.enabled == false then
    return true
  end

  local cap = freecap()
  if not cap or cap < 0 then
    return true
  end

  local minCap = tonumber(cfg.minCap) or 500
  local labelSair = cfg.labelSair or cfg.labelExit or "loot"
  local labelContinuar = cfg.labelContinuar or cfg.labelContinue or "hunt"
  local label = (cap < minCap) and labelSair or labelContinuar

  if gotoLabel then
    gotoLabel(label)
  elseif CaveBot and CaveBot.gotoLabel then
    CaveBot.gotoLabel(label)
  end

  return true
end

Checker.cap = function()
  return runCapChecker(1)
end

-- Funcao alternativa para CaveBot (sem namespace)
function capChecker()
  return runCapChecker(1)
end

-- Funcao alternativa para CaveBot (sem namespace)
function capChecker2()
  return runCapChecker(2)
end

-- Funcao alternativa para CaveBot (sem namespace)
function capChecker3()
  return runCapChecker(3)
end

-- Funcao alternativa para CaveBot (sem namespace)
function capCheckerIndex(index)
  local idx = tonumber(index) or 1
  return runCapChecker(idx)
end

-- Stamina
local function runStaminaChecker(index)
  local list = storage.cavebotStats and storage.cavebotStats.stamina
  local cfg
  if list and list[index] then
    cfg = normalizeStaminaEntry(list[index], index)
  elseif index == 1 then
    cfg = storage.cavebotChecks.stamina
  elseif index == 2 then
    cfg = storage.cavebotChecks.stamina2
  elseif index == 3 then
    cfg = storage.cavebotChecks.stamina3
  end

  if not cfg or cfg.enabled == false then
    return true
  end

  local stam = stamina()
  if not stam or stam < 0 then
    return true
  end

  local minStamina = cfg.minStamina
  if minStamina == nil then
    local hours = tonumber(cfg.hours) or 0
    local minutes = tonumber(cfg.minutes) or 0
    minStamina = (hours * 60) + minutes
  end
  local restLabel = cfg.labelDescansar or cfg.labelRest or "descansar"
  local contLabel = cfg.labelContinuar or cfg.labelContinue or "staminaok"
  local label = (stam < minStamina) and restLabel or contLabel

  if gotoLabel then
    gotoLabel(label)
  elseif CaveBot and CaveBot.gotoLabel then
    CaveBot.gotoLabel(label)
  end

  return true
end

Checker.stamina = function()
  return runStaminaChecker(1)
end

-- Funcao alternativa para CaveBot (sem namespace)
function staminaChecker()
  return runStaminaChecker(1)
end

-- Funcao alternativa para CaveBot (sem namespace)
function staminaChecker2()
  return runStaminaChecker(2)
end

-- Funcao alternativa para CaveBot (sem namespace)
function staminaChecker3()
  return runStaminaChecker(3)
end

-- Funcao alternativa para CaveBot (sem namespace)
function staminaCheckerIndex(index)
  local idx = tonumber(index) or 1
  return runStaminaChecker(idx)
end

-- Sair do Trainer
Checker.sairTrainer = function()
  local cfg = storage.cavebotChecks.sairTrainer
  if not cfg or not cfg.enabled then
    return true
  end

  local stam = stamina()
  if not stam or stam < 0 then
    return true
  end

  local minStamina = cfg.minStamina or 960
  local label
  if stam >= minStamina then
    if g_game and g_game.cancelAttack then
      g_game.cancelAttack()
    end
    if TargetBot and TargetBot.isOn and TargetBot.setOff then
      if TargetBot.isOn() then
        TargetBot.setOff()
      end
    elseif modules.targetbot and modules.targetbot.isOn and modules.targetbot.setOff then
      if modules.targetbot.isOn() then
        modules.targetbot.setOff()
      end
    end
    label = cfg.labelSair or "sair"
  else
    label = cfg.labelContinuar or "continuar"
  end

  if gotoLabel then
    gotoLabel(label)
  elseif CaveBot and CaveBot.gotoLabel then
    CaveBot.gotoLabel(label)
  end

  return true
end

-- Funcao alternativa para CaveBot (sem namespace)
function sairTrainerChecker()
  local cfg = storage.cavebotChecks.sairTrainer
  if not cfg or not cfg.enabled then
    return true
  end

  local stam = stamina()
  if not stam or stam < 0 then
    return true
  end

  local minStamina = cfg.minStamina or 960
  local label
  if stam >= minStamina then
    if g_game and g_game.cancelAttack then
      g_game.cancelAttack()
    end
    if TargetBot and TargetBot.isOn and TargetBot.setOff then
      if TargetBot.isOn() then
        TargetBot.setOff()
      end
    elseif modules.targetbot and modules.targetbot.isOn and modules.targetbot.setOff then
      if modules.targetbot.isOn() then
        modules.targetbot.setOff()
      end
    end
    label = cfg.labelSair or "sair"
  else
    label = cfg.labelContinuar or "continuar"
  end

  if gotoLabel then
    gotoLabel(label)
  elseif CaveBot and CaveBot.gotoLabel then
    CaveBot.gotoLabel(label)
  end

  return true
end

local function disableTargetBot()
  if TargetBot and TargetBot.isOn and TargetBot.setOff then
    if TargetBot.isOn() then
      TargetBot.setOff()
    end
  elseif modules.targetbot and modules.targetbot.isOn and modules.targetbot.setOff then
    if modules.targetbot.isOn() then
      modules.targetbot.setOff()
    end
  end
end

local function cancelAttackAndDisableTarget()
  if g_game and g_game.cancelAttack then
    g_game.cancelAttack()
  end
  disableTargetBot()
end

local function isTrainerTarget(cfg)
  local trainerName = (cfg.trainerName or ""):trim():lower()
  if trainerName == "" then
    return false
  end
  if not g_game or not g_game.getAttackingCreature then
    return false
  end
  local target = g_game.getAttackingCreature()
  if not target then
    return false
  end
  local targetName = (target:getName() or ""):trim():lower()
  if not targetName then
    return false
  end
  if targetName == trainerName then
    return true
  end
  return targetName:find(trainerName, 1, true) ~= nil
end

local sairTrainerMacro = nil

local function setSairTrainerMacroEnabled(enabled)
  storage.cavebotChecks.sairTrainerMacroEnabled = enabled and true or false

  local cfg = storage.cavebotChecks.sairTrainer

  if storage.cavebotChecks.sairTrainerMacroEnabled then
    if not sairTrainerMacro then
      sairTrainerMacro = macro(500, "", function()
        local cfg = storage.cavebotChecks.sairTrainer
        if not cfg then
          return
        end
        if g_game and g_game.isOnline and not g_game.isOnline() then
          return
        end

        local stam = stamina()
        if not stam or stam < 0 then
          return
        end

        local minStamina = cfg.minStamina or 960
        if stam < minStamina then
          cfg.macroActive = false
          return
        end

        if cfg.macroActive then
          disableTargetBot()
          if g_game and g_game.cancelAttack then
            g_game.cancelAttack()
          end
          return
        end

        if isTrainerTarget(cfg) then
          cfg.macroActive = true
          cancelAttackAndDisableTarget()
        end
      end)
      sairTrainerMacro:setOn()
    else
      sairTrainerMacro:setOn()
    end
  else
    if cfg then
      cfg.macroActive = false
    end
    if sairTrainerMacro then
      sairTrainerMacro:setOff()
      sairTrainerMacro = nil
    end
  end
end

local function updateSairTrainerMacroButton(button)
  if not button then
    return
  end

  if storage.cavebotChecks.sairTrainerMacroEnabled then
    button:setText("Macro Sair Trainer: ON")
    button:setColor("#98BF64")
  else
    button:setText("Macro Sair Trainer: OFF")
    button:setColor("#FF6B6B")
  end
end

if storage.cavebotChecks.sairTrainerMacroEnabled then
  setSairTrainerMacroEnabled(true)
end

-- Mover 1 SQM (passo simples)
function moveStepNorth()
  if g_game and g_game.walk then
    g_game.walk(0)
  end
  return true
end

function moveStepSouth()
  if g_game and g_game.walk then
    g_game.walk(2)
  end
  return true
end

function moveStepEast()
  if g_game and g_game.walk then
    g_game.walk(1)
  end
  return true
end

function moveStepWest()
  if g_game and g_game.walk then
    g_game.walk(3)
  end
  return true
end

function moveStepNorthEast()
  if g_game and g_game.walk then
    g_game.walk(4)
  end
  return true
end

function moveStepSouthEast()
  if g_game and g_game.walk then
    g_game.walk(5)
  end
  return true
end

function moveStepSouthWest()
  if g_game and g_game.walk then
    g_game.walk(6)
  end
  return true
end

function moveStepNorthWest()
  if g_game and g_game.walk then
    g_game.walk(7)
  end
  return true
end

-- PZ
Checker.PZ = function()
  local cfg = storage.cavebotChecks.pz
  if not cfg then
    return true
  end

  if isInPz() then
    local label = cfg.labelPZ or "Templo"
    if gotoLabel then
      gotoLabel(label)
    elseif CaveBot and CaveBot.gotoLabel then
      CaveBot.gotoLabel(label)
    end
  end

  return true
end

-- Funcao alternativa para CaveBot (sem namespace)
function pzChecker()
  local cfg = storage.cavebotChecks.pz
  if not cfg then
  return true
end

  if isInPz() then
    local label = cfg.labelPZ or "Templo"
    if gotoLabel then
      gotoLabel(label)
    elseif CaveBot and CaveBot.gotoLabel then
      CaveBot.gotoLabel(label)
    end
  end

  return true
end


-- Hunt Rotation
Checker.Random = function()
  local cfg = storage.cavebotChecks.random
  if not cfg or not cfg.enabled then return true end

  -- Processar lista de labels
  local labelsList = string.split(cfg.labels or "Hunt1,Hunt2,Hunt3", ",")
  local cleanLabels = {}

  for _, label in ipairs(labelsList) do
    local trimmed = label:trim()
    if trimmed ~= "" then
      table.insert(cleanLabels, trimmed)
    end
  end

  if #cleanLabels > 0 then
    -- Sistema de Rotacao Sequencial
    local currentIndex = cfg.currentIndex or 1

    -- Garantir que o indice esta dentro dos limites
    if currentIndex > #cleanLabels then
      currentIndex = 1
    end

    -- Ir para o label atual
    local label = cleanLabels[currentIndex]
    if gotoLabel then
      gotoLabel(label)
    elseif CaveBot and CaveBot.gotoLabel then
  CaveBot.gotoLabel(label)
    end

    -- Incrementar para o proximo
    currentIndex = currentIndex + 1
    if currentIndex > #cleanLabels then
      currentIndex = 1
    end

    -- Salvar o novo indice
    storage.cavebotChecks.random.currentIndex = currentIndex
  end

  return true
end


local function runLevelChecker(index, debug)
  local list = storage.cavebotStats and storage.cavebotStats.level
  local cfg
  if list and list[index] then
    cfg = normalizeLevelEntry(list[index], index)
  elseif index == 1 then
    cfg = storage.cavebotChecks.level1
  elseif index == 2 then
    cfg = storage.cavebotChecks.level2
  elseif index == 3 then
    cfg = storage.cavebotChecks.level3
  elseif index == 4 then
    cfg = storage.cavebotChecks.level4
  elseif index == 5 then
    cfg = storage.cavebotChecks.level5
  end

  local prefix = "[levelChecker" .. tostring(index or 1) .. "]"
  if not cfg then
    if debug then
      print(prefix .. " Config nao encontrada!")
    end
    return true
  end
  if cfg.enabled == false then
    if debug then
      print(prefix .. " Checker desabilitado!")
    end
    return true
  end

  local lvl = level()
  if debug then
    print(prefix .. " Level atual: " .. tostring(lvl))
  end
  if not lvl or lvl < 0 then
    if debug then
      print(prefix .. " Level invalido!")
    end
    return true
  end

  local defaultMin, defaultSair, defaultContinuar = getLevelDefaults(index)
  local minLevel = tonumber(cfg.minLevel) or defaultMin
  if debug then
    print(prefix .. " Level minimo configurado: " .. tostring(minLevel))
  end

  local label = (lvl < minLevel) and (cfg.labelContinuar or defaultContinuar) or (cfg.labelSair or defaultSair)
  if debug then
    print(prefix .. " Level " .. lvl .. " < " .. minLevel .. " = " .. tostring(lvl < minLevel))
    print(prefix .. " Indo para label: " .. label)
  end

  if gotoLabel then
    local result = gotoLabel(label)
    if debug then
      print(prefix .. " gotoLabel() resultado: " .. tostring(result))
    end
  elseif CaveBot and CaveBot.gotoLabel then
    local result = CaveBot.gotoLabel(label)
    if debug then
      print(prefix .. " CaveBot.gotoLabel() resultado: " .. tostring(result))
    end
  else
    if debug then
      print(prefix .. " ERRO: gotoLabel nao encontrado!")
    end
  end

  return true
end

-- Funcao alternativa para CaveBot (sem namespace) - Level Checker 1
function levelChecker1()
  return runLevelChecker(1, true)
end

-- Funcao alternativa para CaveBot (sem namespace) - Level Checker 2
function levelChecker2()
  return runLevelChecker(2, true)
end

-- Funcao alternativa para CaveBot (sem namespace) - Level Checker 3
function levelChecker3()
  return runLevelChecker(3, true)
end

-- Funcao alternativa para CaveBot (sem namespace) - Level Checker 4
function levelChecker4()
  return runLevelChecker(4, false)
end

-- Funcao alternativa para CaveBot (sem namespace) - Level Checker 5
function levelChecker5()
  return runLevelChecker(5, false)
end

-- Funcao alternativa para CaveBot (sem namespace)
function levelCheckerIndex(index)
  local idx = tonumber(index) or 1
  return runLevelChecker(idx, false)
end

-- Funcao alternativa para CaveBot (sem namespace)
function randomHuntChecker()
  local cfg = storage.cavebotChecks.random
  if not cfg or not cfg.enabled then return true end

  -- Processar lista de labels
  local labelsList = string.split(cfg.labels or "Hunt1,Hunt2,Hunt3", ",")
  local cleanLabels = {}

  for _, label in ipairs(labelsList) do
    local trimmed = label:trim()
    if trimmed ~= "" then
      table.insert(cleanLabels, trimmed)
    end
  end

  if #cleanLabels > 0 then
    -- Sistema de Rotacao Sequencial
    local currentIndex = cfg.currentIndex or 1

    -- Garantir que o indice esta dentro dos limites
    if currentIndex > #cleanLabels then
      currentIndex = 1
    end

    -- Ir para o label atual
    local label = cleanLabels[currentIndex]
    if gotoLabel then
      gotoLabel(label)
    elseif CaveBot and CaveBot.gotoLabel then
      CaveBot.gotoLabel(label)
    end

    -- Incrementar para o proximo
    currentIndex = currentIndex + 1
    if currentIndex > #cleanLabels then
      currentIndex = 1
    end

    -- Salvar o novo indice
    storage.cavebotChecks.random.currentIndex = currentIndex

    print("[Hunt Rotation] Indo para: " .. label .. " (proxima: " .. (cleanLabels[currentIndex] or cleanLabels[1]) .. ")")
  end

  return true
end

-- Fechar todas as backpacks
Checker.closeBackpacks = function()
  local cfg = storage.cavebotChecks.closeBackpacks
  if not cfg or not cfg.enabled then return true end

  print("Fechando todas as backpacks...")
  if g_game and g_game.getContainers then
    for _, container in pairs(g_game.getContainers() or {}) do
      g_game.close(container)
    end
    delay(3000)
  else
    print("Funcao g_game.getContainers nao encontrada!")
  end
  return true
end

function closeBackpacks()
  return Checker.closeBackpacks()
end

local function resolveDirection(dirName)
  if Direction and Direction[dirName] ~= nil then
    return Direction[dirName]
  end
  local fallback = {
    North = 0,
    East = 1,
    South = 2,
    West = 3
  }
  return fallback[dirName]
end

local function turnTo(dirName)
  local dir = resolveDirection(dirName)
  if dir == nil then
    return
  end
  if g_game and g_game.turn then
    g_game.turn(dir)
  elseif turn then
    turn(dir)
  end
end

local function castSpell(words)
  if not words or words == '' then
    return
  end
  if say then
    say(words)
  elseif g_game and g_game.talk then
    g_game.talk(words)
  elseif g_game and g_game.say then
    g_game.say(words)
  end
end

Checker.levitate = function(direction, mode)
  local cfg = storage.cavebotChecks.levitate or {}
  local spell = (mode == 'up') and cfg.upSpell or cfg.downSpell
  turnTo(direction)
  schedule(120, function()
    castSpell(spell)
  end)
  return true
end

-- Helper function para converter hora:minuto em minutos totais do dia
local function timeToMinutes(hour, minute)
  return (hour * 60) + minute
end

-- Helper function para obter minutos totais do horario atual
local function getCurrentTimeMinutes()
  local currentTime = os.date("%H:%M")
  local hour, minute = currentTime:match("(%d+):(%d+)")
  return timeToMinutes(tonumber(hour) or 0, tonumber(minute) or 0)
end

local function runTimeChecker(index)
  local list = storage.cavebotStats and storage.cavebotStats.time
  local cfg
  if list and list[index] then
    cfg = normalizeTimeEntry(list[index], index, index == 1)
  elseif index == 1 then
    cfg = storage.cavebotChecks.time1
  elseif index == 2 then
    cfg = storage.cavebotChecks.time2
  elseif index == 3 then
    cfg = storage.cavebotChecks.time3
  elseif index == 4 then
    cfg = storage.cavebotChecks.time4
  end

  if not cfg or cfg.enabled == false then
    return true
  end

  local invert = cfg.invert
  if invert == nil then
    invert = (index == 1)
  end

  local hourStart = math.max(0, math.min(23, tonumber(cfg.hourStart) or 0))
  local minuteStart = math.max(0, math.min(59, tonumber(cfg.minuteStart) or 0))
  local hourEnd = math.max(0, math.min(23, tonumber(cfg.hourEnd) or 23))
  local minuteEnd = math.max(0, math.min(59, tonumber(cfg.minuteEnd) or 59))

  local startMinutes = timeToMinutes(hourStart, minuteStart)
  local endMinutes = timeToMinutes(hourEnd, minuteEnd)
  local currentMinutes = getCurrentTimeMinutes()

  local isInsideInterval = false
  if startMinutes <= endMinutes then
    isInsideInterval = (currentMinutes >= startMinutes and currentMinutes <= endMinutes)
  else
    isInsideInterval = (currentMinutes >= startMinutes or currentMinutes <= endMinutes)
  end

  local label
  if invert then
    label = isInsideInterval and (cfg.labelOutside or "wait") or (cfg.labelInside or "hunt")
  else
    label = isInsideInterval and (cfg.labelInside or "event") or (cfg.labelOutside or "wait")
  end

  if gotoLabel then
    gotoLabel(label)
  elseif CaveBot and CaveBot.gotoLabel then
    CaveBot.gotoLabel(label)
  end

  return true
end

-- Time Checker 1 - Para tirar da hunt antes do evento
Checker.time1 = function()
  return runTimeChecker(1)
end

-- Funcao alternativa para CaveBot (sem namespace)
function timeChecker1()
  return runTimeChecker(1)
end

-- Time Checker 2 - Para entrar no evento quando abrir
Checker.time2 = function()
  return runTimeChecker(2)
end

-- Funcao alternativa para CaveBot (sem namespace)
function timeChecker2()
  return runTimeChecker(2)
end

-- Time Checker 3 - Intervalo generico
Checker.time3 = function()
  return runTimeChecker(3)
end

-- Funcao alternativa para CaveBot (sem namespace)
function timeChecker3()
  return runTimeChecker(3)
end

-- Time Checker 4 - Intervalo generico
Checker.time4 = function()
  return runTimeChecker(4)
end

-- Funcao alternativa para CaveBot (sem namespace)
function timeChecker4()
  return runTimeChecker(4)
end

-- Funcao alternativa para CaveBot (sem namespace)
function timeCheckerIndex(index)
  local idx = tonumber(index) or 1
  return runTimeChecker(idx)
end

local trainerExitMacro = nil
local TRAINER_EXIT_MACRO_INTERVAL_MS = 60000

local function runTrainerChecker()
  local cfg = ensureTrainerConfig()
  if not cfg or cfg.enabled == false then
    return true
  end

  local stam = stamina()
  if not stam or stam < 0 then
    return true
  end

  local minStamina = (tonumber(cfg.minHours) or 16) * 60
  cfg.minStamina = minStamina

  local trainerLabel = (cfg.labelTrainer and cfg.labelTrainer ~= "") and cfg.labelTrainer or "irtreinar"
  local continueLabel = (cfg.labelContinuar and cfg.labelContinuar ~= "") and cfg.labelContinuar or "aindanaotreinar"
  local targetLabel = (stam < minStamina) and trainerLabel or continueLabel

  if gotoLabel then
    gotoLabel(targetLabel)
  elseif CaveBot and CaveBot.gotoLabel then
    CaveBot.gotoLabel(targetLabel)
  end

  return true
end

local function setTrainerExitMacroEnabled(enabled)
  local cfg = ensureTrainerConfig()
  cfg.macroEnabled = enabled and true or false
  storage.cavebotChecks.trainerMacroEnabled = cfg.macroEnabled and true or false

  if cfg.macroEnabled then
    if not trainerExitMacro then
      trainerExitMacro = macro(TRAINER_EXIT_MACRO_INTERVAL_MS, "", function()
        local cfg = ensureTrainerConfig()
        if not cfg or cfg.macroEnabled ~= true then
          return
        end
        if g_game and g_game.isOnline and not g_game.isOnline() then
          return
        end

        local stam = stamina()
        if not stam or stam < 0 then
          return
        end

        local minStamina = (tonumber(cfg.minHours) or 16) * 60
        cfg.minStamina = minStamina
        if stam < minStamina then
          cfg.exitTriggered = false
          return
        end

        cancelAttackAndDisableTarget()

        local exitLabel = (cfg.labelSairTrainer and cfg.labelSairTrainer ~= "") and cfg.labelSairTrainer or "sairdotrainer"
        if not cfg.exitTriggered then
          if gotoLabel then
            gotoLabel(exitLabel)
          elseif CaveBot and CaveBot.gotoLabel then
            CaveBot.gotoLabel(exitLabel)
          end
          cfg.exitTriggered = true
          print(string.format("[Trainer Checker] Macro de saida acionado. Indo para label '%s'.", exitLabel))
        end
      end)
    end
    trainerExitMacro:setOn()
  else
    cfg.exitTriggered = false
    if trainerExitMacro then
      trainerExitMacro:setOff()
      trainerExitMacro = nil
    end
  end
end

local function updateTrainerExitMacroButton(button)
  if not button then
    return
  end
  local cfg = ensureTrainerConfig()
  if cfg.macroEnabled then
    button:setText("Macro Saida: ON")
    button:setColor("#98BF64")
  else
    button:setText("Macro Saida: OFF")
    button:setColor("#FF6B6B")
  end
end

if ensureTrainerConfig().macroEnabled then
  setTrainerExitMacroEnabled(true)
end

Checker.trainer = function()
  return runTrainerChecker()
end

function trainerChecker()
  return runTrainerChecker()
end

local function runTaskerChecker()
  local cfg = ensureTaskerConfig()
  if not cfg or cfg.enabled == false then
    return true
  end

  local checkAll = cfg.checkAllMonsters ~= false
  local labelEntrega = (cfg.labelEntrega and cfg.labelEntrega ~= "") and cfg.labelEntrega or "entregartask"
  local labelContinuar = (cfg.labelContinuar and cfg.labelContinuar ~= "") and cfg.labelContinuar or "continuartask"

  local hasAnyRule = false
  local allReached = true
  local anyReached = false

  for _, entry in ipairs(cfg.monsters or {}) do
    normalizeTaskerMonsterEntry(entry)
    local monsterName = normalizeTaskerMonsterName(entry.name)
    local goal = tonumber(entry.amount) or 0
    if entry.enabled ~= false and monsterName ~= "" and goal > 0 then
      hasAnyRule = true
      local kills = getTaskerMonsterKills(monsterName)
      local reached = kills >= goal
      if reached then
        anyReached = true
      else
        allReached = false
      end
    end
  end

  local goEntrega = false
  if hasAnyRule then
    if checkAll then
      goEntrega = allReached
    else
      goEntrega = anyReached
    end
  end

  local targetLabel = goEntrega and labelEntrega or labelContinuar
  if gotoLabel then
    gotoLabel(targetLabel)
  elseif CaveBot and CaveBot.gotoLabel then
    CaveBot.gotoLabel(targetLabel)
  end

  return true
end

Checker.tasker = function()
  return runTaskerChecker()
end

function taskerChecker()
  return runTaskerChecker()
end

local function getSupplyItemName(itemId)
  if not itemId or itemId <= 0 then
    return "Item desconhecido"
  end
  local created = Item.create(itemId)
  if created and created:getName() and created:getName() ~= "" then
    return created:getName()
  end
  return "Item " .. tostring(itemId)
end

local function isRingOrAmuletName(name)
  if not name then
    return false
  end
  local lowerName = name:lower()
  return lowerName:find("ring") or lowerName:find("amulet")
end

local function getBuySupplyItemCount(itemId)
  local total = player:getItemsCount(itemId)
  local baseName = getSupplyItemName(itemId)
  if not isRingOrAmuletName(baseName) then
    return total
  end

  for _, delta in ipairs({ -1, 1 }) do
    local candidateId = itemId + delta
    if candidateId > 0 then
      local candidateName = getSupplyItemName(candidateId)
      if candidateName == baseName then
        total = total + player:getItemsCount(candidateId)
      end
    end
  end

  return total
end

Checker.supply = function()
  local cfg = storage.cavebotChecks.supply
  if not cfg or not cfg.enabled then
    return true
  end

  local okLabel = (cfg.okLabel and cfg.okLabel ~= "") and cfg.okLabel or "hunt"
  local lowLabel = (cfg.lowLabel and cfg.lowLabel ~= "") and cfg.lowLabel or "resupply"

  local allOk = true
  local missing = {}

  for _, entry in ipairs(cfg.items) do
    local entryId = tonumber(entry.id) or 0
    local entryAmount = tonumber(entry.amount) or 0
    local entryEnabled = entry.enabled ~= false

    if entryEnabled and entryId > 100 and entryAmount > 0 then
      local current = getBuySupplyItemCount(entryId)
      if current < entryAmount then
        allOk = false
        table.insert(missing, {
          id = entryId,
          current = current,
          required = entryAmount
        })
      end
    end
  end

  local targetLabel = allOk and okLabel or lowLabel

  if gotoLabel then
    gotoLabel(targetLabel)
  elseif CaveBot and CaveBot.gotoLabel then
    CaveBot.gotoLabel(targetLabel)
  end

  if allOk then
    print(string.format("[Supply Checker] Suprimentos ok. Indo para label '%s'.", targetLabel))
  else
    local parts = {}
    for _, info in ipairs(missing) do
      table.insert(parts, string.format("%s (%d/%d)", getSupplyItemName(info.id), info.current, info.required))
    end
    print(string.format("[Supply Checker] Itens faltando: %s. Indo para label '%s'.", table.concat(parts, ", "), targetLabel))
  end

  return true
end

local function runBuySupply(cfg)
  if not cfg or not cfg.enabled then
    return true
  end

  sanitizeBuySuppliesItems(nil, cfg)

  local items = cfg.items or {}
  local npcMap = {}
  local npcList = {}
  local hasTargets = false

  for _, entry in ipairs(items) do
    if entry and entry.enabled ~= false then
      local entryId = tonumber(entry.id) or 0
      local entryAmount = tonumber(entry.amount) or 0
      local npcName = (entry.npcName or ""):trim()
      if entryId > 100 and entryAmount > 0 and npcName ~= "" then
        hasTargets = true
        local key = npcName:lower()
        if not npcMap[key] then
          npcMap[key] = npcName
          table.insert(npcList, npcName)
        end
      end
    end
  end

  if not hasTargets then
    print("[Buy Supply] Nenhum item configurado para compra.")
    return true
  end

  if not CaveBot or not CaveBot.ReachNPC or not CaveBot.OpenNpcTrade then
    warn("[Buy Supply] Funcoes do CaveBot indisponiveis para comprar no NPC.")
    return false
  end

  if #npcList == 0 then
    warn("[Buy Supply] NPC nao configurado.")
    return false
  end

  local npcCount = #npcList
  local currentNpcIdx = tonumber(cfg.currentNpcIdx) or 1
  if currentNpcIdx < 1 or currentNpcIdx > npcCount then
    currentNpcIdx = 1
  end
  local tradeRetries = tonumber(cfg.tradeRetries) or 0
  local reachRetries = tonumber(cfg.reachRetries) or 0

  local activeNpc = npcList[currentNpcIdx]
  if not activeNpc then
    return "retry"
  end

  local activeItems = {}
  local activeNpcLower = activeNpc:lower()
  for _, entry in ipairs(items) do
    if entry and entry.enabled ~= false then
      local entryId = tonumber(entry.id) or 0
      local entryAmount = tonumber(entry.amount) or 0
      local npcName = (entry.npcName or ""):trim()
      if entryId > 100 and entryAmount > 0 and npcName ~= "" and npcName:lower() == activeNpcLower then
        table.insert(activeItems, entry)
      end
    end
  end

  if #activeItems == 0 then
    cfg.currentNpcIdx = (currentNpcIdx % npcCount) + 1
    return "retry"
  end

  table.sort(activeItems, function(a, b)
    local pa = tonumber(a.priority) or 0
    local pb = tonumber(b.priority) or 0
    if pa == pb then
      return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end
    return pa < pb
  end)

  if cfg.lastNpcName and cfg.lastNpcName ~= activeNpc and NPC.isTrading() then
    NPC.closeTrade()
    delay(300)
  end

  local reachResult = CaveBot.ReachNPC(activeNpc)
  if reachResult == false then
    if npcCount > 1 then
      if NPC.isTrading() then
        NPC.closeTrade()
        delay(300)
      end
      cfg.lastNpcName = nil
      cfg.reachRetries = 0
      cfg.currentNpcIdx = (currentNpcIdx % npcCount) + 1
      return "retry"
    end
    reachRetries = reachRetries + 1
    cfg.reachRetries = reachRetries
    cfg.currentNpcIdx = currentNpcIdx
    if reachRetries >= 5 then
      warn("[Buy Supply] NPC nao encontrado apos varias tentativas.")
      cfg.reachRetries = 0
      return true
    end
    return "retry"
  end

  if reachResult ~= true then
    cfg.currentNpcIdx = currentNpcIdx
    return "retry"
  end

  cfg.reachRetries = 0
  cfg.lastNpcName = activeNpc

  if not NPC.isTrading() then
    CaveBot.OpenNpcTrade()
    local talkDelay = tonumber(cfg.talkDelay) or 500
    delay(talkDelay)
    tradeRetries = tradeRetries + 1
    cfg.tradeRetries = tradeRetries
    if tradeRetries >= 5 then
      warn("[Buy Supply] Nao conseguiu abrir trade. Pulando checker.")
      if npcCount > 1 then
        cfg.lastNpcName = nil
        cfg.tradeRetries = 0
        cfg.currentNpcIdx = (currentNpcIdx % npcCount) + 1
        return "retry"
      end
      cfg.tradeRetries = 0
      return true
    end
    return "retry"
  end

  cfg.tradeRetries = 0

  local npcItems = NPC.getBuyItems() or {}
  local availableIds = {}
  for _, data in pairs(npcItems) do
    if data and data.id then
      availableIds[data.id] = true
    end
  end

  local missingNpcItems = {}
  local missingList = {}
  local triedToBuy = false

  for _, entry in ipairs(activeItems) do
    local entryId = tonumber(entry.id) or 0
    local targetAmount = math.max(0, tonumber(entry.amount) or 0)
    local entryEnabled = entry.enabled ~= false
    local entryChunkLimit = math.max(0, tonumber(entry.maxPerBuy) or 1000)

    if entryEnabled and entryId > 100 and targetAmount > 0 then
      local current = getBuySupplyItemCount(entryId)
      local need = targetAmount - current

      if need > 0 then
        table.insert(missingList, { id = entryId, need = need, target = targetAmount, current = current })
        if availableIds[entryId] then
          local toBuy = need
          if entryChunkLimit > 0 then
            toBuy = math.min(need, entryChunkLimit)
          end
          NPC.buy(entryId, toBuy)
          print(string.format("[Buy Supply] Comprando %d de %s (atual: %d/%d).", toBuy, getSupplyItemName(entryId), current, targetAmount))
          triedToBuy = true
        else
          table.insert(missingNpcItems, entryId)
        end
      end
    end
  end

  if #missingNpcItems > 0 then
    local names = {}
    for _, id in ipairs(missingNpcItems) do
      table.insert(names, getSupplyItemName(id))
    end
    warn(string.format("[Buy Supply] NPC %s nao vende: %s.", activeNpc, table.concat(names, ", ")))
    if NPC.isTrading() then
      NPC.closeTrade()
    end
    cfg.lastNpcName = nil
    cfg.tradeRetries = 0
    cfg.reachRetries = 0
    cfg.currentNpcIdx = 1
    return true
  end

  -- Se comprou algo agora, sai do checker para seguir o CaveBot.
  if triedToBuy then
    delay(600)
    if NPC.isTrading() then
      NPC.closeTrade()
    end
    cfg.lastNpcName = nil
    cfg.tradeRetries = 0
    cfg.reachRetries = 0
    cfg.currentNpcIdx = 1
    return "retry"
  end

  -- Se ainda falta item (vendido pelo NPC), continua no checker.
  if #missingList > 0 then
    return "retry"
  end

  print("[Buy Supply] Estoque completo. Seguindo.")
  if NPC.isTrading() then
    NPC.closeTrade()
  end
  cfg.lastNpcName = nil
  cfg.tradeRetries = 0
  cfg.reachRetries = 0
  cfg.currentNpcIdx = 1
  return true
end
Checker.buySupply = function()
  return runBuySupply(storage.buySupplies)
end

function supplyChecker()
  return Checker.supply()
end

function buySupplyChecker()
  return Checker.buySupply()
end

function buySupplyChecker2()
  return Checker.buySupply()
end

function buySupplyChecker3()
  return Checker.buySupply()
end

function buySupplyChecker4()
  return Checker.buySupply()
end

-- Registra BuySupply como acao nativa do CaveBot (similar ao buysupplies padrao)
local function registerBuySupplyAction()
  if not CaveBot or not CaveBot.registerAction then
    schedule(500, registerBuySupplyAction)
    return
  end

  if CaveBot.Actions and CaveBot.Actions["buysupplychecker"] then
    return
  end

  CaveBot.registerAction("buysupplychecker", "#87CEFA", function(value, retries, prev)
    -- Mantem a mesma semantica do CaveBot: "retry" repete, false para bloquear, true para seguir.
    return buySupplyChecker()
  end)

  if CaveBot.Editor and CaveBot.Editor.registerAction then
    CaveBot.Editor.registerAction("buysupplychecker", "buy supply checker", {
      value = "",
      title = "Buy Supply Checker",
      description = "Compra itens configurados ate o alvo no NPC definido.",
    })
  end

  print("[Buy Supply] Acao 'buysupplychecker' registrada no CaveBot.")
end

if CaveBot and CaveBot.registerAction then
  registerBuySupplyAction()
else
  schedule(500, registerBuySupplyAction)
end

-- ============================================
-- INTERFACE PRINCIPAL - BOTOES
-- ============================================

-- (Codigo antigo removido)


-- ============================================
-- INTERFACE BASEADA NO HP.LUA
-- ============================================

-- Definir estilo da janela com abas
g_ui.loadUIFromString([[
tPanel < Panel
  margin: 3

  VerticalScrollBar
    id: panelScroll
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    step: 28
    pixels-scroll: true

  ScrollablePanel
    id: panelContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-left: 8
    margin-right: 18
    padding-top: 8
    padding-bottom: 40
    vertical-scrollbar: panelScroll
    layout:
      type: verticalBox
      spacing: 5

FunctionsMainWindow < MainWindow
  !text: tr('CaveBOT by Kelus Scripts')
  size: 547 444
  visible: false
  @onEscape: self:hide()

  TabBar
    id: tabBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 25

  Panel
    id: contentPanel
    anchors.top: tabBar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonPanel.top
    margin-top: 5
    margin-bottom: 5
    margin-left: 10
    margin-right: 10

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
      id: saveBtn
      text: Salvar
      size: 80 18

    Button
      id: helpBtn
      text: Ajuda / Help
      size: 80 18

    Button
      id: closeBtn
      text: Fechar
      size: 80 18
      @onClick: self:getParent():getParent():hide()

]])

g_ui.loadUIFromString([[
FunctionsHelpWindow < MainWindow
  !text: tr('CaveBOT Help')
  size: 700 560
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
        width: 660
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

local functionsWindow = nil
local functionsHelpWindow = nil
local FUNCTIONS_LAYOUT_VERSION = 29

local function isWidgetAlive(widget)
  if not widget then
    return false
  end
  if widget.isDestroyed and widget:isDestroyed() then
    return false
  end
  return true
end

local function findWidgetByIdRecursive(root, childId)
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
    local found = findWidgetByIdRecursive(child, childId)
    if found then
      return found
    end
  end
  return nil
end

local CAVEBOT_FUNCTIONS_HELP_TEXT = table.concat({
  "PT - CaveBOT Functions (Resumo)",
  "================================",
  "1) Objetivo",
  "- Organizar checkers e utilitarios para controlar fluxo do CaveBot.",
  "- Automacao por condicao: cap, stamina, level, horario, supply, task e trainer.",
  "",
  "2) Uso rapido",
  "- Abra Main > CaveBOT.",
  "- Ajuste os campos por aba e salve no CaveBot quando adicionar actions/labels.",
  "",
  "3) Basicos",
  "- Steps inserem movimento manual rapido.",
  "- Levitate gera acao pronta por direcao (up/down).",
  "",
  "4) Checkers",
  "- Stamina/Cap/Level/Time alternam labels conforme regra configurada.",
  "",
  "5) Supply / Buy / Tasker / Trainer",
  "- Supply e Buy controlam reposicao e compra.",
  "- Tasker monitora kills e metas.",
  "- Trainer alterna fluxo de treino por regras de stamina/labels.",
  "",
  "EN - CaveBOT Functions (Summary)",
  "=================================",
  "1) Goal",
  "- Organize checkers and utilities to control CaveBot flow.",
  "- Condition-based automation: cap, stamina, level, time, supply, task and trainer.",
  "",
  "2) Quick usage",
  "- Open Main > CaveBOT.",
  "- Adjust tab fields and save in CaveBot when adding actions/labels.",
  "",
  "3) Basics",
  "- Step buttons insert quick manual movement actions.",
  "- Levitate creates ready actions by direction (up/down).",
  "",
  "4) Checkers",
  "- Stamina/Cap/Level/Time switch labels based on configured rules.",
  "",
  "5) Supply / Buy / Tasker / Trainer",
  "- Supply and Buy handle refill and purchases.",
  "- Tasker tracks kills and goals.",
  "- Trainer controls training flow with stamina/label rules."
}, "\n")

local function ensureFunctionsHelpWindow()
  if isWidgetAlive(functionsHelpWindow) then
    return functionsHelpWindow
  end
  local parent = rootWidget or g_ui.getRootWidget()
  functionsHelpWindow = g_ui.createWidget('FunctionsHelpWindow', parent)
  if functionsHelpWindow then
    functionsHelpWindow:hide()
  end
  return functionsHelpWindow
end

local function refreshFunctionsHelpWindow()
  local helpWindow = ensureFunctionsHelpWindow()
  if not helpWindow then
    return nil
  end
  local helpTextLabel = findWidgetByIdRecursive(helpWindow, 'helpTextLabel')
  if helpTextLabel then
    helpTextLabel:setText(CAVEBOT_FUNCTIONS_HELP_TEXT)
  end
  return {
    window = helpWindow,
    scrollBar = findWidgetByIdRecursive(helpWindow, 'helpScroll'),
    scrollContent = findWidgetByIdRecursive(helpWindow, 'helpScrollContent'),
    textLabel = helpTextLabel,
    closeButton = findWidgetByIdRecursive(helpWindow, 'closeButton')
  }
end

local function resetFunctionsHelpScrollToTop(helpUi)
  if not helpUi then
    return
  end
  if helpUi.scrollBar and helpUi.scrollBar.setValue then
    local minValue = 0
    if helpUi.scrollBar.getMinimum then
      local currentMin = helpUi.scrollBar:getMinimum()
      if type(currentMin) == 'number' then
        minValue = currentMin
      end
    end
    helpUi.scrollBar:setValue(minValue)
  end
  if helpUi.scrollContent and helpUi.scrollContent.getVirtualOffset and helpUi.scrollContent.setVirtualOffset then
    local off = helpUi.scrollContent:getVirtualOffset() or { x = 0, y = 0 }
    off.x = 0
    off.y = 0
    helpUi.scrollContent:setVirtualOffset(off)
  end
end

local function openFunctionsHelpWindow()
  local helpUi = refreshFunctionsHelpWindow()
  if not helpUi or not helpUi.window then
    return
  end
  if helpUi.closeButton then
    helpUi.closeButton.onClick = function()
      helpUi.window:hide()
    end
  end
  helpUi.window:show()
  helpUi.window:raise()
  helpUi.window:focus()
  resetFunctionsHelpScrollToTop(helpUi)
  schedule(30, function() resetFunctionsHelpScrollToTop(helpUi) end)
  schedule(120, function() resetFunctionsHelpScrollToTop(helpUi) end)
  schedule(260, function() resetFunctionsHelpScrollToTop(helpUi) end)
end

local function destroyFunctionsWindow()
  if not functionsWindow then
    return
  end
  if functionsWindow._restoreCaveUi then
    functionsWindow._restoreCaveUi()
  end
  if functionsWindow.destroy then
    functionsWindow:destroy()
  end
  functionsWindow = nil
end

local function openFunctionsWindow()
  if functionsWindow and functionsWindow._layoutVersion ~= FUNCTIONS_LAYOUT_VERSION then
    destroyFunctionsWindow()
  end
  if functionsWindow then
    local contentPanel = functionsWindow.contentPanel
    local hasContent = contentPanel and contentPanel.getChildren and #contentPanel:getChildren() > 0
    local completeBuild = functionsWindow._buildComplete == true
    if not hasContent or not completeBuild then
      destroyFunctionsWindow()
    end
  end
  if functionsWindow then
    if functionsWindow._moveCaveUi then
      functionsWindow._moveCaveUi()
    end
    functionsWindow:show()
    functionsWindow:raise()
    functionsWindow:focus()
    return
  end

  -- Criar janela modal
  functionsWindow = g_ui.createWidget('FunctionsMainWindow', rootWidget)
  functionsWindow._layoutVersion = FUNCTIONS_LAYOUT_VERSION

  local contentPanel = functionsWindow.contentPanel
  local tabBar = functionsWindow.tabBar
  if tabBar and tabBar.setContentWidget then
    tabBar:setContentWidget(contentPanel)
  end

  local MAX_STATS_ROWS = 5
  local MAX_BUY_ITEMS = 10

  -- Funcao para criar campos menores
  local function createSmallField(container, labelText, defaultValue, onChange)
    local panel = setupUI([[
Panel
  height: 22
  margin-right: 4
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: label
    width: 100
    text-auto-resize: false
    text-align: left

  TextEdit
    id: field
    width: 100
    height: 18
]], container)

    panel.label:setText(labelText)
    panel.field:setText(tostring(defaultValue))
    panel.field.onTextChange = onChange
    return panel.field
  end

  local function createSmallFieldWithAdd(container, labelText, defaultValue, onChange, addHandler)
    local panel = setupUI([[
Panel
  height: 22
  margin-right: 4
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: label
    width: 100
    text-auto-resize: false
    text-align: left

  TextEdit
    id: field
    width: 100
    height: 18

  Button
    id: add
    text: +
    width: 20
    height: 18
]], container)

    panel.label:setText(labelText)
    panel.field:setText(tostring(defaultValue))
    panel.field.onTextChange = onChange
    if addHandler then
      panel.add.onClick = function()
        addHandler(panel.field:getText())
      end
    end
    return panel.field, panel.add
  end

  local function createSmallSpinBox(container, labelText, defaultValue, minValue, maxValue, stepValue, onChange)
    local panel = setupUI([[
Panel
  height: 22
  margin-right: 4
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: label
    width: 100
    text-auto-resize: false
    text-align: left

  SpinBox
    id: field
    width: 100
    height: 18
    text-align: center
    minimum: 0
    maximum: 999999
    step: 1
    editable: true
    focusable: true
]], container)

    panel.label:setText(labelText)
    panel.field:setMinimum(minValue or 0)
    panel.field:setMaximum(maxValue or 999999)
    panel.field:setStep(stepValue or 1)
    panel.field:setValue(tonumber(defaultValue) or (minValue or 0))
    panel.field.onValueChange = onChange
    return panel.field
  end

  local function addLabelToCaveBot(label)
    if not CaveBot or not CaveBot.addAction then
      warn('[CaveBot Functions] CaveBot nao encontrado!')
      return
    end
    if not label or label:match('^%s*$') then
      warn('[CaveBot Functions] Label vazia.')
      return
    end
    CaveBot.addAction('label', label, true)
    if CaveBot.save then
      CaveBot.save()
    end
    print(string.format("[CaveBot Functions] Label '%s' adicionada ao CaveBot.", label))
  end

  local function setBilingualTooltip(widget, ptText, enText)
    if not widget or not widget.setTooltip then
      return
    end
    widget:setTooltip(string.format("PT: %s\nEN: %s", ptText, enText))
  end

  local function setBilingualFieldTooltip(field, ptText, enText)
    setBilingualTooltip(field, ptText, enText)
    local panel = field and field:getParent()
    if panel and panel.label and panel.label.setTooltip then
      panel.label:setTooltip(string.format("PT: %s\nEN: %s", ptText, enText))
    end
  end

  local function createStaminaTimeFields(container, cfg)
    local total = tonumber(cfg.minStamina) or 0
    local hours = math.floor(total / 60)
    local minutes = total % 60
    local minuteField
    local hourField = createSmallSpinBox(container, 'Stamina Horas:', hours, 0, 42, 1, function(widget, value)
      local hour = tonumber(value) or 0
      local minute = minuteField:getValue() or 0
      cfg.minStamina = (hour * 60) + minute
    end)

    minuteField = createSmallSpinBox(container, 'Stamina Minutos:', minutes, 0, 59, 1, function(widget, value)
      local minute = tonumber(value) or 0
      local hour = hourField:getValue() or 0
      cfg.minStamina = (hour * 60) + minute
    end)
    setBilingualFieldTooltip(
      hourField,
      "Horas minimas de stamina (ex: 14).",
      "Minimum stamina hours (e.g., 14)."
    )
    setBilingualFieldTooltip(
      minuteField,
      "Minutos minimos de stamina (ex: 30 para 14:30).",
      "Minimum stamina minutes (e.g., 30 for 14:30)."
    )
  end

  local function findScrollBar(widget)
    local current = widget
    for _ = 1, 6 do
      if not current then
        break
      end
      if current.getChildById then
        local sb = current:getChildById('panelScroll')
        if sb then
          return sb
        end
      end
      current = current.getParent and current:getParent() or nil
    end
    return nil
  end

  local function refreshLayout(widget)
    local scrollBar = findScrollBar(widget)
    local scrollValue
    if scrollBar and scrollBar.getValue then
      scrollValue = scrollBar:getValue()
    end
    local current = widget
    for i = 1, 6 do
      if not current then
        break
      end
      if current.updateLayout then
        current:updateLayout()
      end
      if i == 1 and current.fitChildren then
        current:fitChildren()
      end
      if i == 1 and current.resizeToFitChildren then
        current:resizeToFitChildren()
      end
      current = current:getParent()
    end
    if scrollBar and scrollValue ~= nil and scrollBar.setValue then
      local function restoreScroll()
        if scrollBar.isDestroyed and scrollBar:isDestroyed() then
          return
        end
        local value = scrollValue
        if scrollBar.getMaximum then
          local max = scrollBar:getMaximum()
          if max and value > max then
            value = max
          end
        end
        scrollBar:setValue(value)
      end
      if addEvent then
        addEvent(restoreScroll)
      else
        restoreScroll()
      end
    end
  end

  local function ensurePanelHeight(panel)
    if not panel or not panel.getChildren or not panel.setHeight then
      return
    end
    local total = 0
    for _, child in ipairs(panel:getChildren() or {}) do
      if child.isVisible and not child:isVisible() then
        -- Ignora filhos ocultos para nao inflar a altura.
      elseif child.getHeight then
        total = total + (child:getHeight() or 0)
      end
    end
    if total > 0 then
      panel:setHeight(total + 4)
    end
  end

  local function createCheckerSection(parent, opts)
    opts = opts or {}
    local label
    if opts.showTitle then
      label = g_ui.createWidget('BotLabel', parent)
      label:setText(opts.title or 'CHECKER')
      label:setColor('#FFFFFF')
      if opts.labelTooltip then
        label:setTooltip(opts.labelTooltip)
      end
    end

    local info
    if opts.showInfo then
      info = g_ui.createWidget('BotLabel', parent)
      info:setText(opts.infoText or '')
      info:setColor('#FFFFFF')
      if opts.infoTooltip then
        info:setTooltip(opts.infoTooltip)
      end
    end

    local actionPanel = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4
  fit-children: true
]], parent)

    local addBtn = g_ui.createWidget('Button', actionPanel)
    addBtn:setText(opts.addBtnText or 'Adicionar no CaveBot')
    addBtn:setSize({width = opts.addBtnWidth or 150, height = 20})
    addBtn:setColor(opts.addBtnColor or '#98BF64')
    if opts.addBtnTooltip then
      addBtn:setTooltip(opts.addBtnTooltip)
    end
    if opts.addHandler then
      addBtn.onClick = opts.addHandler
    end
    if opts.addBtnMarginRight then
      addBtn:setMarginRight(opts.addBtnMarginRight)
    else
      addBtn:setMarginRight(4)
    end

    local setupBtn
    local configPanel
    if opts.showSetup ~= false and (opts.buildConfig or opts.placeholderText) then
      local inlineConfig = opts.inlineConfig == true
      if not inlineConfig then
        setupBtn = g_ui.createWidget('Button', actionPanel)
        setupBtn:setText('+')
        setupBtn:setSize({width = opts.setupBtnWidth or 20, height = 20})
        if opts.setupTooltip then
          setupBtn:setTooltip(opts.setupTooltip)
        end
      end

      configPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 6
  fit-children: true
]], parent)
      configPanel:setMarginTop(4)
      configPanel:setMarginBottom(8)
      configPanel:setVisible(inlineConfig)

      if opts.buildConfig then
        opts.buildConfig(configPanel)
      else
        local placeholder = g_ui.createWidget('BotLabel', configPanel)
        placeholder:setText(opts.placeholderText or 'Nenhuma configuracao adicional.')
        placeholder:setColor('#FFFFFF')
      end

      if inlineConfig then
        ensurePanelHeight(configPanel)
        if parent then
          ensurePanelHeight(parent)
        end
        refreshLayout(configPanel)
        if opts.onLayoutChanged then
          opts.onLayoutChanged()
        end
      else
        local function toggleConfig()
          local visible = not configPanel:isVisible()
          configPanel:setVisible(visible)
          setupBtn:setText(visible and '-' or '+')
          if visible then
            ensurePanelHeight(configPanel)
          end
          if parent then
            ensurePanelHeight(parent)
          end
          refreshLayout(configPanel)
          if opts.onLayoutChanged then
            opts.onLayoutChanged()
          end
        end

        setupBtn.onMousePress = function(widget, mousePos, mouseButton)
          if MouseLeftButton and mouseButton and mouseButton ~= MouseLeftButton then
            return false
          end
          toggleConfig()
          return true
        end
        setupBtn.onClick = nil
      end
    end

    return {
      label = label,
      info = info,
      addBtn = addBtn,
      setupBtn = setupBtn,
      configPanel = configPanel
    }
  end

  local function createTab(tabBar, tabName, tabId)
    local panel = g_ui.createWidget('tPanel')
    panel:setId('panel_' .. tabId)
    if tabBar and tabBar.addTab then
      tabBar:addTab(tabName, panel)
    end
    return panel:getChildById('panelContent') or panel
  end

  local tabPanels = {}
  tabPanels['Basics'] = createTab(tabBar, 'Basics', 1)
  tabPanels['Stats'] = createTab(tabBar, 'Stats', 2)
  tabPanels['Supply'] = createTab(tabBar, 'Supply', 3)
  tabPanels['Imbuiments'] = createTab(tabBar, 'Imbuiments', 4)
  tabPanels['Tasker'] = createTab(tabBar, 'Tasker', 5)
  tabPanels['Trainer'] = createTab(tabBar, 'Trainer', 6)
  tabPanels['STA'] = tabPanels['Stats']
  tabPanels['CAP'] = tabPanels['Stats']
  tabPanels['Level'] = tabPanels['Stats']
  tabPanels['Time'] = tabPanels['Stats']
  if tabBar and tabBar.getTab and tabBar.selectTab then
    local firstTab = tabBar:getTab('Basics')
    if firstTab then
      tabBar:selectTab(firstTab)
    end
  end

  -- ABA 1: Basics
  local basicosPanel = tabPanels['Basics']
  basicosPanel = basicosPanel:getChildById('panelContent') or basicosPanel

  local basicsColumns = setupUI([[
Panel
  layout:
    type: horizontalBox
    spacing: 10
  fit-children: true

  Panel
    id: leftColumn
    width: 220
    layout:
      type: verticalBox
      spacing: 5
    fit-children: true

  Panel
    id: rightColumn
    width: 220
    layout:
      type: verticalBox
      spacing: 5
    fit-children: true
]], basicosPanel)
  local basicsLeftColumn = basicsColumns.leftColumn or basicsColumns:getChildById('leftColumn') or basicosPanel
  local basicsRightColumn = basicsColumns.rightColumn or basicsColumns:getChildById('rightColumn') or basicosPanel

  local function measureChildrenHeight(panel)
    if not panel or not panel.getChildren then
      return 0
    end
    local total = 0
    for _, child in ipairs(panel:getChildren() or {}) do
      if child.isVisible and not child:isVisible() then
        -- ignora filhos ocultos
      else
        local childHeight = (child.getHeight and child:getHeight()) or 0
        if childHeight <= 0 then
          if child.fitChildren then
            child:fitChildren()
          end
          if child.resizeToFitChildren then
            child:resizeToFitChildren()
          end
          if child.updateLayout then
            child:updateLayout()
          end
          childHeight = (child.getHeight and child:getHeight()) or 0
        end
        if childHeight <= 0 then
          childHeight = 22
        end
        total = total + childHeight
      end
    end
    return total
  end

  local function refreshBasicsColumnsLayout()
    local leftHeight = measureChildrenHeight(basicsLeftColumn)
    local rightHeight = measureChildrenHeight(basicsRightColumn)
    local minColumnHeight = 360
    local finalLeftHeight = math.max(leftHeight + 8, minColumnHeight)
    local finalRightHeight = math.max(rightHeight + 8, minColumnHeight)
    if basicsLeftColumn and basicsLeftColumn.setHeight then
      basicsLeftColumn:setHeight(finalLeftHeight)
    end
    if basicsRightColumn and basicsRightColumn.setHeight then
      basicsRightColumn:setHeight(finalRightHeight)
    end
    if basicsColumns and basicsColumns.setHeight then
      basicsColumns:setHeight(math.max(finalLeftHeight, finalRightHeight, 24))
    end
    refreshLayout(basicsColumns)
    refreshLayout(basicosPanel)
  end

  local function scheduleBasicsColumnsLayoutRefresh()
    if addEvent then
      addEvent(function()
        if not isWidgetAlive(functionsWindow) then
          return
        end
        refreshBasicsColumnsLayout()
      end)
    else
      refreshBasicsColumnsLayout()
    end
  end

  -- === PZ CHECKER ===
  createCheckerSection(basicsLeftColumn, {
    title = 'PZ CHECKER',
    labelTooltip = "PT: Verifica se esta em PZ. Se sim, vai para a label configurada (ex: Templo).\nEN: Checks if in PZ. If yes, goes to the configured label (e.g., Temple).",
    infoText = 'Verifica se esta em PZ. Clique abaixo para adicionar.',
    addBtnText = 'PZ Checker',
    addBtnTooltip = 'PT: Adiciona o pzChecker direto no CaveBot. Verifica se esta em PZ e muda a label automaticamente.\nEN: Adds pzChecker to the CaveBot. Checks if in PZ and switches the label automatically.',
    setupTooltip = 'PT: Define a label usada quando o personagem estiver em PZ.\nEN: Defines the label used when the character is in PZ.',
    onLayoutChanged = scheduleBasicsColumnsLayoutRefresh,
    addHandler = function()
      if CaveBot and CaveBot.addAction then
        CaveBot.addAction("delay", "500", false)
        CaveBot.addAction("function", "pzChecker()\nreturn true", true)
        if CaveBot.save then
          CaveBot.save()
        end
        print('[CaveBot Functions] pzChecker + delay adicionado ao CaveBot!')
      else
        warn('[CaveBot Functions] CaveBot nao encontrado!')
      end
    end,
    buildConfig = function(panel)
      local pzLabelField = createSmallField(panel, 'Label PZ:', storage.cavebotChecks.pz.labelPZ or 'Templo', function(widget, text)
        storage.cavebotChecks.pz.labelPZ = text
      end)
      setBilingualFieldTooltip(
        pzLabelField,
        "Label usada quando estiver em PZ. Crie essa label no CaveBot.",
        "Label used when in PZ. Create this label in the CaveBot."
      )
    end
  })

  -- === HUNT ROTATION ===
  createCheckerSection(basicsLeftColumn, {
    title = 'HUNT ROTATION',
    labelTooltip = "PT: Rotaciona entre as hunts na ordem configurada. Evita repetir consecutivamente.\nEN: Rotates between hunts in the configured order. Avoids consecutive repeats.",
    infoText = 'Rotaciona entre as hunts na ordem. Clique abaixo para adicionar.',
    addBtnText = 'Hunt Rotation',
    addBtnTooltip = 'PT: Adiciona Hunt Rotation direto no CaveBot. Alterna hunts em sequencia.\nEN: Adds Hunt Rotation to the CaveBot. Rotates hunts sequentially.',
    setupTooltip = 'PT: Configure a ordem do loop de hunts.\nEN: Configures the hunt loop order.',
    onLayoutChanged = scheduleBasicsColumnsLayoutRefresh,
    addHandler = function()
      if CaveBot and CaveBot.addAction then
        CaveBot.addAction("delay", "500", false)
        CaveBot.addAction("function", "randomHuntChecker()\nreturn true", true)
        if CaveBot.save then
          CaveBot.save()
        end
        print('[CaveBot Functions] randomHuntChecker + delay adicionado ao CaveBot!')
      else
        warn('[CaveBot Functions] CaveBot nao encontrado!')
      end
    end,
    buildConfig = function(panel)
      local randomEdit = createSmallField(panel, 'Hunts:', storage.cavebotChecks.random.labels or 'Hunt1,Hunt2,Hunt3', function(widget, text)
        storage.cavebotChecks.random.labels = text
      end)
      setBilingualFieldTooltip(
        randomEdit,
        "Hunts na ordem (separadas por virgula). Ex: Hunt1,Hunt2,Hunt3.",
        "Hunts in order (comma-separated). Example: Hunt1,Hunt2,Hunt3."
      )
    end
  })

  -- === CLOSE BACKPACKS ===
  createCheckerSection(basicsLeftColumn, {
    title = 'CLOSE BACKPACKS',
    labelTooltip = "PT: Fecha todas as backpacks abertas. Util antes de depositar ou resetar.\nEN: Closes all open backpacks. Useful before depositing or resetting.",
    infoText = 'Fecha todas as backpacks automaticamente. Clique abaixo para adicionar.',
    addBtnText = 'Close Backpacks',
    addBtnTooltip = 'PT: Adiciona closeBackpacks direto no CaveBot. Fecha todas as backpacks abertas.\nEN: Adds closeBackpacks to the CaveBot. Closes all open backpacks.',
    showSetup = false,
    addHandler = function()
      if CaveBot and CaveBot.addAction then
        CaveBot.addAction("delay", "500", false)
        CaveBot.addAction("function", "Checker.closeBackpacks()\nreturn true", true)
        if CaveBot.save then
          CaveBot.save()
        end
        print('[CaveBot Functions] closeBackpacks + delay adicionado ao CaveBot!')
      else
        warn('[CaveBot Functions] CaveBot nao encontrado!')
      end
    end
  })

  local function getCurrentPlayerPosition()
    local localPlayer = nil
    if g_game and g_game.getLocalPlayer then
      localPlayer = g_game.getLocalPlayer()
    end
    if not localPlayer and player then
      localPlayer = player
    end
    if localPlayer and localPlayer.getPosition then
      return localPlayer:getPosition()
    end
    if pos then
      return pos()
    end
    return nil
  end

  local function addToolUseWithAction(toolName, itemId)
    if not CaveBot or not CaveBot.addAction then
      warn('[CaveBot Functions] CaveBot nao encontrado!')
      return
    end

    local id = tonumber(itemId)
    if not id or id <= 0 then
      warn('[CaveBot Functions] ID de item invalido para ' .. tostring(toolName) .. '.')
      return
    end

    local targetPos = getCurrentPlayerPosition()
    if not targetPos then
      warn('[CaveBot Functions] Nao foi possivel obter a posicao atual.')
      return
    end

    local actionValue = string.format("%d,%d,%d,%d", id, targetPos.x, targetPos.y, targetPos.z)
    CaveBot.addAction("usewith", actionValue, true)
    if CaveBot.save then
      CaveBot.save()
    end
    print(string.format(
      "[CaveBot Functions] %s usewith adicionado em %d,%d,%d (item %d).",
      tostring(toolName),
      targetPos.x,
      targetPos.y,
      targetPos.z,
      id
    ))
  end

  local toolWaypointButtons = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4

  Button
    id: addShovel
    text: Shovel
    size: 66 20

  Button
    id: addRope
    text: Rope
    size: 66 20

  Button
    id: addMachete
    text: Machete
    size: 74 20
]], basicsLeftColumn)

  local toolWaypointCfg = storage.cavebotChecks.toolWaypoints
  local shovelIdField = createSmallSpinBox(basicsLeftColumn, 'Shovel ID:', toolWaypointCfg.shovelId or 3457, 1, 65535, 1, function(widget, value)
    toolWaypointCfg.shovelId = tonumber(value) or toolWaypointCfg.shovelId or 3457
  end)
  local ropeIdField = createSmallSpinBox(basicsLeftColumn, 'Rope ID:', toolWaypointCfg.ropeId or 3003, 1, 65535, 1, function(widget, value)
    toolWaypointCfg.ropeId = tonumber(value) or toolWaypointCfg.ropeId or 3003
  end)
  local macheteIdField = createSmallSpinBox(basicsLeftColumn, 'Machete ID:', toolWaypointCfg.macheteId or 3308, 1, 65535, 1, function(widget, value)
    toolWaypointCfg.macheteId = tonumber(value) or toolWaypointCfg.macheteId or 3308
  end)

  setBilingualTooltip(
    toolWaypointButtons.addShovel,
    "Adiciona um waypoint usewith de shovel na coordenada atual.",
    "Adds a shovel usewith waypoint at the current position."
  )
  setBilingualTooltip(
    toolWaypointButtons.addRope,
    "Adiciona um waypoint usewith de rope na coordenada atual.",
    "Adds a rope usewith waypoint at the current position."
  )
  setBilingualTooltip(
    toolWaypointButtons.addMachete,
    "Adiciona um waypoint usewith de machete na coordenada atual.",
    "Adds a machete usewith waypoint at the current position."
  )

  setBilingualFieldTooltip(
    shovelIdField,
    "ID do item para o botao de shovel.",
    "Item ID used by the shovel button."
  )
  setBilingualFieldTooltip(
    ropeIdField,
    "ID do item para o botao de rope.",
    "Item ID used by the rope button."
  )
  setBilingualFieldTooltip(
    macheteIdField,
    "ID do item para o botao de machete.",
    "Item ID used by the machete button."
  )

  toolWaypointButtons.addShovel.onClick = function()
    addToolUseWithAction("Shovel", toolWaypointCfg.shovelId)
  end
  toolWaypointButtons.addRope.onClick = function()
    addToolUseWithAction("Rope", toolWaypointCfg.ropeId)
  end
  toolWaypointButtons.addMachete.onClick = function()
    addToolUseWithAction("Machete", toolWaypointCfg.macheteId)
  end

  ensurePanelHeight(toolWaypointButtons)
  ensurePanelHeight(basicsRightColumn)
  ensurePanelHeight(basicsLeftColumn)
  ensurePanelHeight(basicosPanel)
  refreshLayout(toolWaypointButtons)
  refreshLayout(basicsRightColumn)
  refreshLayout(basicsLeftColumn)
  refreshLayout(basicosPanel)
  refreshBasicsColumnsLayout()
  scheduleBasicsColumnsLayoutRefresh()

  local stepGrid = setupUI([[
Panel
  height: 78
  layout:
    type: verticalBox
    spacing: 4
  fit-children: true

  Panel
    height: 22
    layout:
      type: horizontalBox
      spacing: 6

    Button
      id: northWest
      text: NO
      size: 49 20

    Button
      id: north
      text: Norte
      size: 49 20

    Button
      id: northEast
      text: NE
      size: 49 20

  Panel
    height: 22
    layout:
      type: horizontalBox
      spacing: 6

    Button
      id: west
      text: Oeste
      size: 49 20

    UIWidget
      id: center
      width: 49
      height: 20

    Button
      id: east
      text: Leste
      size: 49 20

  Panel
    height: 22
    layout:
      type: horizontalBox
      spacing: 6

    Button
      id: southWest
      text: SO
      size: 49 20

    Button
      id: south
      text: Sul
      size: 49 20

    Button
      id: southEast
      text: SE
      size: 49 20
]], basicsRightColumn)

  local function addStepAction(fnName)
    if CaveBot and CaveBot.addAction then
      CaveBot.addAction("delay", "200", false)
      CaveBot.addAction("function", fnName .. "()\nreturn true", true)
      if CaveBot.save then
        CaveBot.save()
      end
      print('[CaveBot Functions] ' .. fnName .. ' + delay adicionado ao CaveBot!')
    else
      warn('[CaveBot Functions] CaveBot nao encontrado!')
    end
  end

  local function addLevitateAction(dirName, mode)
    if CaveBot and CaveBot.addAction then
      CaveBot.addAction("delay", "200", false)
      CaveBot.addAction("function", string.format("Checker.levitate('%s','%s')\nreturn true", dirName, mode), true)
      if CaveBot.save then
        CaveBot.save()
      end
      print(string.format('[CaveBot Functions] Levitate %s %s + delay adicionado ao CaveBot!', dirName, mode))
    else
      warn('[CaveBot Functions] CaveBot nao encontrado!')
    end
  end

  local function findChildById(root, childId)
    if not root then
      return nil
    end
    local direct = root:getChildById(childId)
    if direct then
      return direct
    end
    for _, child in ipairs(root:getChildren() or {}) do
      local found = findChildById(child, childId)
      if found then
        return found
      end
    end
    return nil
  end

  local function bindStepButton(button, fnName, tooltip)
    if not button then
      return
    end
    button.onClick = function()
      addStepAction(fnName)
    end
    button:setTooltip(tooltip)
  end

  local stepNorth = findChildById(stepGrid, 'north')
  local stepSouth = findChildById(stepGrid, 'south')
  local stepEast = findChildById(stepGrid, 'east')
  local stepWest = findChildById(stepGrid, 'west')
  local stepNorthEast = findChildById(stepGrid, 'northEast')
  local stepSouthEast = findChildById(stepGrid, 'southEast')
  local stepSouthWest = findChildById(stepGrid, 'southWest')
  local stepNorthWest = findChildById(stepGrid, 'northWest')

  bindStepButton(stepNorth, "moveStepNorth", "PT: Adiciona um passo de 1 sqm para Norte. Clique para inserir no CaveBot.\nEN: Adds a 1 sqm step to North. Click to insert into the CaveBot.")
  bindStepButton(stepSouth, "moveStepSouth", "PT: Adiciona um passo de 1 sqm para Sul. Clique para inserir no CaveBot.\nEN: Adds a 1 sqm step to South. Click to insert into the CaveBot.")
  bindStepButton(stepEast, "moveStepEast", "PT: Adiciona um passo de 1 sqm para Leste. Clique para inserir no CaveBot.\nEN: Adds a 1 sqm step to East. Click to insert into the CaveBot.")
  bindStepButton(stepWest, "moveStepWest", "PT: Adiciona um passo de 1 sqm para Oeste. Clique para inserir no CaveBot.\nEN: Adds a 1 sqm step to West. Click to insert into the CaveBot.")
  bindStepButton(stepNorthEast, "moveStepNorthEast", "PT: Adiciona um passo de 1 sqm para Nordeste. Clique para inserir no CaveBot.\nEN: Adds a 1 sqm step to Northeast. Click to insert into the CaveBot.")
  bindStepButton(stepSouthEast, "moveStepSouthEast", "PT: Adiciona um passo de 1 sqm para Sudeste. Clique para inserir no CaveBot.\nEN: Adds a 1 sqm step to Southeast. Click to insert into the CaveBot.")
  bindStepButton(stepSouthWest, "moveStepSouthWest", "PT: Adiciona um passo de 1 sqm para Sudoeste. Clique para inserir no CaveBot.\nEN: Adds a 1 sqm step to Southwest. Click to insert into the CaveBot.")
  bindStepButton(stepNorthWest, "moveStepNorthWest", "PT: Adiciona um passo de 1 sqm para Noroeste. Clique para inserir no CaveBot.\nEN: Adds a 1 sqm step to Northwest. Click to insert into the CaveBot.")
  ensurePanelHeight(stepGrid)
  refreshLayout(stepGrid)

  local levitateHeader = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 6
  fit-children: true
]], basicsRightColumn)

  local levitateLabel = g_ui.createWidget('BotLabel', levitateHeader)
  levitateLabel:setText('Levitate')
  levitateLabel:setColor('#FFFFFF')

  local levitateSetupBtn = g_ui.createWidget('Button', levitateHeader)
  levitateSetupBtn:setText('+')
  levitateSetupBtn:setSize({width = 20, height = 20})
  setBilingualTooltip(
    levitateSetupBtn,
    "Configura as magias de levitate. Use se o servidor tiver spells diferentes.",
    "Configures levitate spells. Use this if the server uses different spells."
  )

  local levitateConfigPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 6
  fit-children: true
]], basicsRightColumn)
  levitateConfigPanel:setVisible(false)
  levitateConfigPanel:setMarginTop(4)
  levitateConfigPanel:setMarginBottom(4)

  local levitateUpField = createSmallField(levitateConfigPanel, 'Magia Up:', storage.cavebotChecks.levitate.upSpell or 'exani hur up', function(widget, text)
    storage.cavebotChecks.levitate.upSpell = text
  end)

  local levitateDownField = createSmallField(levitateConfigPanel, 'Magia Down:', storage.cavebotChecks.levitate.downSpell or 'exani hur down', function(widget, text)
    storage.cavebotChecks.levitate.downSpell = text
  end)
  setBilingualFieldTooltip(
    levitateUpField,
    "Magia usada para subir (ex: exani hur up).",
    "Spell used to go up (e.g., exani hur up)."
  )
  setBilingualFieldTooltip(
    levitateDownField,
    "Magia usada para descer (ex: exani hur down).",
    "Spell used to go down (e.g., exani hur down)."
  )

  local levitateGrid
  levitateSetupBtn.onClick = function()
    local visible = not levitateConfigPanel:isVisible()
    levitateConfigPanel:setVisible(visible)
    levitateSetupBtn:setText(visible and '-' or '+')
    if visible then
      ensurePanelHeight(levitateConfigPanel)
    end
    ensurePanelHeight(levitateGrid)
    ensurePanelHeight(basicsRightColumn)
    ensurePanelHeight(basicsLeftColumn)
    ensurePanelHeight(basicosPanel)
    refreshLayout(levitateConfigPanel)
    refreshLayout(levitateGrid)
    refreshLayout(basicsRightColumn)
    refreshLayout(basicsLeftColumn)
    refreshLayout(basicosPanel)
    refreshBasicsColumnsLayout()
    scheduleBasicsColumnsLayoutRefresh()
  end

  levitateGrid = setupUI([[
Panel
  height: 48
  layout:
    type: verticalBox
    spacing: 4
  fit-children: true
]], basicsRightColumn)

  local levitateUpRow = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: upLabel
    width: 28
    text-align: right

  Button
    id: northUp
    text: N
    size: 30 20

  Button
    id: eastUp
    text: L
    size: 30 20

  Button
    id: southUp
    text: S
    size: 30 20

  Button
    id: westUp
    text: O
    size: 30 20
]], levitateGrid)
  if levitateUpRow and levitateUpRow.upLabel then
    levitateUpRow.upLabel:setText('/\\')
  end

  local levitateDownRow = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: downLabel
    width: 28
    text-align: right

  Button
    id: northDown
    text: N
    size: 30 20

  Button
    id: eastDown
    text: L
    size: 30 20

  Button
    id: southDown
    text: S
    size: 30 20

  Button
    id: westDown
    text: O
    size: 30 20
]], levitateGrid)
  if levitateDownRow and levitateDownRow.downLabel then
    levitateDownRow.downLabel:setText('\\/')
  end

  local levitateNorthUp = findChildById(levitateGrid, 'northUp')
  local levitateEastUp = findChildById(levitateGrid, 'eastUp')
  local levitateSouthUp = findChildById(levitateGrid, 'southUp')
  local levitateWestUp = findChildById(levitateGrid, 'westUp')
  local levitateNorthDown = findChildById(levitateGrid, 'northDown')
  local levitateEastDown = findChildById(levitateGrid, 'eastDown')
  local levitateSouthDown = findChildById(levitateGrid, 'southDown')
  local levitateWestDown = findChildById(levitateGrid, 'westDown')

  if levitateNorthUp then
    levitateNorthUp.onClick = function()
      addLevitateAction('North', 'up')
    end
    levitateNorthUp:setTooltip('PT: Adiciona levitate Norte (Up). Use para subir virado ao Norte.\nEN: Adds North levitate (Up). Use to go up while facing North.')
  end
  if levitateEastUp then
    levitateEastUp.onClick = function()
      addLevitateAction('East', 'up')
    end
    levitateEastUp:setTooltip('PT: Adiciona levitate Leste (Up). Use para subir virado ao Leste.\nEN: Adds East levitate (Up). Use to go up while facing East.')
  end
  if levitateSouthUp then
    levitateSouthUp.onClick = function()
      addLevitateAction('South', 'up')
    end
    levitateSouthUp:setTooltip('PT: Adiciona levitate Sul (Up). Use para subir virado ao Sul.\nEN: Adds South levitate (Up). Use to go up while facing South.')
  end
  if levitateWestUp then
    levitateWestUp.onClick = function()
      addLevitateAction('West', 'up')
    end
    levitateWestUp:setTooltip('PT: Adiciona levitate Oeste (Up). Use para subir virado ao Oeste.\nEN: Adds West levitate (Up). Use to go up while facing West.')
  end
  if levitateNorthDown then
    levitateNorthDown.onClick = function()
      addLevitateAction('North', 'down')
    end
    levitateNorthDown:setTooltip('PT: Adiciona levitate Norte (Down). Use para descer virado ao Norte.\nEN: Adds North levitate (Down). Use to go down while facing North.')
  end
  if levitateEastDown then
    levitateEastDown.onClick = function()
      addLevitateAction('East', 'down')
    end
    levitateEastDown:setTooltip('PT: Adiciona levitate Leste (Down). Use para descer virado ao Leste.\nEN: Adds East levitate (Down). Use to go down while facing East.')
  end
  if levitateSouthDown then
    levitateSouthDown.onClick = function()
      addLevitateAction('South', 'down')
    end
    levitateSouthDown:setTooltip('PT: Adiciona levitate Sul (Down). Use para descer virado ao Sul.\nEN: Adds South levitate (Down). Use to go down while facing South.')
  end
  if levitateWestDown then
    levitateWestDown.onClick = function()
      addLevitateAction('West', 'down')
    end
    levitateWestDown:setTooltip('PT: Adiciona levitate Oeste (Down). Use para descer virado ao Oeste.\nEN: Adds West levitate (Down). Use to go down while facing West.')
  end
  ensurePanelHeight(levitateGrid)
  ensurePanelHeight(basicsRightColumn)
  ensurePanelHeight(basicsLeftColumn)
  ensurePanelHeight(basicosPanel)
  refreshLayout(levitateGrid)
  refreshLayout(basicsRightColumn)
  refreshLayout(basicsLeftColumn)
  refreshLayout(basicosPanel)
  refreshBasicsColumnsLayout()
  scheduleBasicsColumnsLayoutRefresh()

  -- ABA 2: STA
  local staminaPanel = tabPanels['STA']
  staminaPanel = staminaPanel:getChildById('panelContent') or staminaPanel

  local staminaList = ensureStaminaStatsList()

  local staminaTopRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: title
    width: 150
    text-align: left
    font: verdana-11px-rounded

  Button
    id: addRow
    text: +
    width: 20
    height: 20
]], staminaPanel)

  staminaTopRow.title:setText('Stamina Stats')
  staminaTopRow.title:setColor('#98BF64')
  setBilingualTooltip(
    staminaTopRow.title,
    'Regras de stamina sempre visiveis na tela.',
    'Stamina rules are always visible.'
  )
  setBilingualTooltip(staminaTopRow.addRow, 'Adicionar nova regra de stamina.', 'Add new stamina rule.')

  local staminaHeader = setupUI([[
Panel
  height: 18
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: colName
    width: 90
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colHours
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colMinutes
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colRest
    width: 90
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colContinue
    width: 90
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colRemove
    width: 20
    text-align: center
    font: verdana-11px-rounded
]], staminaPanel)

  staminaHeader.colName:setText('Stat')
  staminaHeader.colHours:setText('Horas')
  staminaHeader.colMinutes:setText('Min')
  staminaHeader.colRest:setText('Descansar')
  staminaHeader.colContinue:setText('Continuar')
  staminaHeader.colRemove:setText('X')

  local staminaListPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 4
  fit-children: true
]], staminaPanel)

  local function addStaminaCheckerAction(index)
    if not CaveBot or not CaveBot.addAction then
      warn('[CaveBot Functions] CaveBot nao encontrado!')
      return
    end
    CaveBot.addAction("delay", "500", false)
    local callText
    if index == 1 then
      callText = "staminaChecker()"
    elseif index == 2 then
      callText = "staminaChecker2()"
    elseif index == 3 then
      callText = "staminaChecker3()"
    else
      callText = string.format("staminaCheckerIndex(%d)", index)
    end
    CaveBot.addAction("function", callText .. "\nreturn true", true)
    if CaveBot.save then
      CaveBot.save()
    end
    print(string.format('[CaveBot Functions] %s + delay adicionado ao CaveBot!', callText))
  end

  local function rebuildStaminaList()
    staminaListPanel:destroyChildren()
    for index, entry in ipairs(staminaList) do
      normalizeStaminaEntry(entry, index)
      local row = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Button
    id: add
    text: Stamina
    width: 90
    height: 20

  SpinBox
    id: hours
    width: 40
    height: 20
    text-align: center
    minimum: 0
    maximum: 42
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: minutes
    width: 40
    height: 20
    text-align: center
    minimum: 0
    maximum: 59
    step: 1
    editable: true
    focusable: true

  Panel
    id: restPanel
    width: 90
    height: 20
    layout:
      type: horizontalBox
      spacing: 2

    TextEdit
      id: rest
      width: 68
      height: 20

    Button
      id: addRest
      text: +
      width: 18
      height: 20

  Panel
    id: contPanel
    width: 90
    height: 20
    layout:
      type: horizontalBox
      spacing: 2

    TextEdit
      id: cont
      width: 68
      height: 20

    Button
      id: addCont
      text: +
      width: 18
      height: 20

  Button
    id: remove
    text: X
    width: 20
    height: 20
]], staminaListPanel)

      local addBtn = findChildById(row, 'add')
      if addBtn then
        addBtn.onClick = function()
          addStaminaCheckerAction(index)
        end
        setBilingualTooltip(addBtn, 'Adiciona este checker ao CaveBot.', 'Add this checker to the CaveBot.')
        addBtn:setText(entry.name or ("Stamina" .. tostring(index)))
      end

      -- Nome usa o texto do proprio botao.

      row.hours:setValue(tonumber(entry.hours) or 0)
      setBilingualTooltip(row.hours, 'Horas minimas de stamina (0-42).', 'Minimum stamina hours (0-42).')
      row.hours.onValueChange = function(_, value)
        entry.hours = tonumber(value) or 0
        entry.minStamina = (entry.hours * 60) + (tonumber(entry.minutes) or 0)
        syncStaminaLegacyFromList()
      end

      row.minutes:setValue(tonumber(entry.minutes) or 0)
      setBilingualTooltip(row.minutes, 'Minutos minimos de stamina (0-59).', 'Minimum stamina minutes (0-59).')
      row.minutes.onValueChange = function(_, value)
        entry.minutes = tonumber(value) or 0
        entry.minStamina = ((tonumber(entry.hours) or 0) * 60) + entry.minutes
        syncStaminaLegacyFromList()
      end

      local restField = findChildById(row, 'rest')
      if restField then
        restField:setText(entry.labelRest or 'descansar')
        setBilingualTooltip(restField, 'Label quando a stamina estiver baixa.', 'Label when stamina is low.')
        restField.onTextChange = function(_, text)
          entry.labelRest = text
          syncStaminaLegacyFromList()
        end
      end

      local addRestBtn = findChildById(row, 'addRest')
      if addRestBtn then
        setBilingualTooltip(addRestBtn, 'Adicionar label Descansar no CaveBot.', 'Add Rest label to the CaveBot.')
        addRestBtn.onClick = function()
          addLabelToCaveBot(restField and restField:getText() or entry.labelRest or '')
        end
      end

      local contField = findChildById(row, 'cont')
      if contField then
        contField:setText(entry.labelContinue or 'staminaok')
        setBilingualTooltip(contField, 'Label quando a stamina estiver OK.', 'Label when stamina is OK.')
        contField.onTextChange = function(_, text)
          entry.labelContinue = text
          syncStaminaLegacyFromList()
        end
      end

      local addContBtn = findChildById(row, 'addCont')
      if addContBtn then
        setBilingualTooltip(addContBtn, 'Adicionar label Continuar no CaveBot.', 'Add Continue label to the CaveBot.')
        addContBtn.onClick = function()
          addLabelToCaveBot(contField and contField:getText() or entry.labelContinue or '')
        end
      end

      setBilingualTooltip(row.remove, 'Remove esta regra.', 'Remove this rule.')
      row.remove.onClick = function()
        table.remove(staminaList, index)
        syncStaminaLegacyFromList()
        rebuildStaminaList()
      end
    end

    syncStaminaLegacyFromList()
    ensurePanelHeight(staminaListPanel)
    ensurePanelHeight(staminaPanel)
    refreshLayout(staminaListPanel)
    refreshLayout(staminaPanel)
  end

  staminaTopRow.addRow.onClick = function()
    if #staminaList >= MAX_STATS_ROWS then
      warn('[CaveBot Functions] Limite de 5 regras de Stamina atingido.')
      return
    end
    table.insert(staminaList, {
      name = "Stamina" .. tostring(#staminaList + 1),
      hours = 0,
      minutes = 0,
      labelRest = "descansar",
      labelContinue = "staminaok",
      userAdded = true,
      enabled = true
    })
    normalizeStaminaEntry(staminaList[#staminaList], #staminaList)
    syncStaminaLegacyFromList()
    rebuildStaminaList()
  end

  rebuildStaminaList()

  -- ABA 3: CAP
  local capPanel = tabPanels['CAP']
  capPanel = capPanel:getChildById('panelContent') or capPanel

  local capList = ensureCapStatsList()

  local capTopRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: title
    width: 150
    text-align: left
    font: verdana-11px-rounded

  Button
    id: addRow
    text: +
    width: 20
    height: 20
]], capPanel)

  capTopRow.title:setText('Cap Stats')
  capTopRow.title:setColor('#98BF64')
  setBilingualTooltip(capTopRow.title, 'Regras de cap sempre visiveis na tela.', 'Cap rules are always visible.')
  setBilingualTooltip(capTopRow.addRow, 'Adicionar nova regra de cap.', 'Add new cap rule.')

  local capHeader = setupUI([[
Panel
  height: 18
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: colName
    width: 80
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colMin
    width: 60
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colExit
    width: 90
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colContinue
    width: 90
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colRemove
    width: 20
    text-align: center
    font: verdana-11px-rounded
]], capPanel)

  capHeader.colName:setText('Cap')
  capHeader.colMin:setText('Min')
  capHeader.colExit:setText('Sair')
  capHeader.colContinue:setText('Continuar')
  capHeader.colRemove:setText('X')

  local capListPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 4
  fit-children: true
]], capPanel)

  local function addCapCheckerAction(index)
    if not CaveBot or not CaveBot.addAction then
      warn('[CaveBot Functions] CaveBot nao encontrado!')
      return
    end
    CaveBot.addAction("delay", "500", false)
    local callText
    if index == 1 then
      callText = "capChecker()"
    elseif index == 2 then
      callText = "capChecker2()"
    elseif index == 3 then
      callText = "capChecker3()"
    else
      callText = string.format("capCheckerIndex(%d)", index)
    end
    CaveBot.addAction("function", callText .. "\nreturn true", true)
    if index == 1 then
      local entry = capList and capList[index]
      local label = entry and entry.labelContinuar or (storage.cavebotChecks.cap and storage.cavebotChecks.cap.labelContinuar) or "capok"
      if label ~= "" then
        CaveBot.addAction("label", label, true)
      end
    end
    if CaveBot.save then
      CaveBot.save()
    end
    print(string.format('[CaveBot Functions] %s + delay adicionado ao CaveBot!', callText))
  end

  local function rebuildCapList()
    capListPanel:destroyChildren()
    for index, entry in ipairs(capList) do
      normalizeCapEntry(entry, index)
      local row = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Button
    id: add
    text: Cap
    width: 80
    height: 20

  SpinBox
    id: min
    width: 60
    height: 20
    text-align: center
    minimum: 0
    maximum: 100000
    step: 1
    editable: true
    focusable: true

  Panel
    id: exitPanel
    width: 90
    height: 20
    layout:
      type: horizontalBox
      spacing: 2

    TextEdit
      id: exit
      width: 68
      height: 20

    Button
      id: addExit
      text: +
      width: 18
      height: 20

  Panel
    id: contPanel
    width: 90
    height: 20
    layout:
      type: horizontalBox
      spacing: 2

    TextEdit
      id: cont
      width: 68
      height: 20

    Button
      id: addCont
      text: +
      width: 18
      height: 20

  Button
    id: remove
    text: X
    width: 20
    height: 20
]], capListPanel)

      row.add:setText(entry.name or ("Cap" .. tostring(index)))
      row.add.onClick = function()
        addCapCheckerAction(index)
      end
      setBilingualTooltip(row.add, 'Adiciona este checker ao CaveBot.', 'Add this checker to the CaveBot.')

      row.min:setValue(tonumber(entry.minCap) or 500)
      setBilingualTooltip(row.min, 'Capacidade minima (cap) para acionar o checker.', 'Minimum capacity (cap) to trigger the checker.')
      row.min.onValueChange = function(_, value)
        entry.minCap = tonumber(value) or 500
        syncCapLegacyFromList()
      end

      local exitField = findChildById(row, 'exit')
      if exitField then
        exitField:setText(entry.labelSair or 'loot')
        setBilingualTooltip(exitField, 'Label usada quando o cap estiver baixo.', 'Label used when cap is low.')
        exitField.onTextChange = function(_, text)
          entry.labelSair = text
          syncCapLegacyFromList()
        end
      end

      local addExitBtn = findChildById(row, 'addExit')
      if addExitBtn then
        setBilingualTooltip(addExitBtn, 'Adicionar label Sair no CaveBot.', 'Add exit label to the CaveBot.')
        addExitBtn.onClick = function()
          addLabelToCaveBot(exitField and exitField:getText() or entry.labelSair or '')
        end
      end

      local contField = findChildById(row, 'cont')
      if contField then
        contField:setText(entry.labelContinuar or 'capboas')
        setBilingualTooltip(contField, 'Label usada quando o cap estiver OK.', 'Label used when cap is OK.')
        contField.onTextChange = function(_, text)
          entry.labelContinuar = text
          syncCapLegacyFromList()
        end
      end

      local addContBtn = findChildById(row, 'addCont')
      if addContBtn then
        setBilingualTooltip(addContBtn, 'Adicionar label Continuar no CaveBot.', 'Add continue label to the CaveBot.')
        addContBtn.onClick = function()
          addLabelToCaveBot(contField and contField:getText() or entry.labelContinuar or '')
        end
      end

      setBilingualTooltip(row.remove, 'Remove esta regra.', 'Remove this rule.')
      row.remove.onClick = function()
        table.remove(capList, index)
        syncCapLegacyFromList()
        rebuildCapList()
      end
    end

    syncCapLegacyFromList()
    ensurePanelHeight(capListPanel)
    ensurePanelHeight(capPanel)
    refreshLayout(capListPanel)
    refreshLayout(capPanel)
  end

  capTopRow.addRow.onClick = function()
    if #capList >= MAX_STATS_ROWS then
      warn('[CaveBot Functions] Limite de 5 regras de Cap atingido.')
      return
    end
    local nextIndex = #capList + 1
    local exitSuffix = nextIndex > 1 and tostring(nextIndex - 1) or ''
    local continueSuffix = nextIndex > 1 and tostring(nextIndex) or ''
    table.insert(capList, {
      name = "Cap" .. tostring(nextIndex),
      minCap = 500,
      labelSair = "loot" .. exitSuffix,
      labelContinuar = "capboas" .. continueSuffix,
      userAdded = true,
      enabled = true
    })
    normalizeCapEntry(capList[#capList], #capList)
    syncCapLegacyFromList()
    rebuildCapList()
  end

  rebuildCapList()

  -- ABA 4: Level
  local avancadosPanel = tabPanels['Level']
  avancadosPanel = avancadosPanel:getChildById('panelContent') or avancadosPanel

  local levelList = ensureLevelStatsList()

  local levelTopRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: title
    width: 150
    text-align: left
    font: verdana-11px-rounded

  Button
    id: addRow
    text: +
    width: 20
    height: 20
]], avancadosPanel)

  levelTopRow.title:setText('Level Stats')
  levelTopRow.title:setColor('#98BF64')
  setBilingualTooltip(levelTopRow.title, 'Regras de level sempre visiveis na tela.', 'Level rules are always visible.')
  setBilingualTooltip(levelTopRow.addRow, 'Adicionar nova regra de level.', 'Add new level rule.')

  local levelHeader = setupUI([[
Panel
  height: 18
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: colName
    width: 80
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colMin
    width: 60
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colExit
    width: 90
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colContinue
    width: 90
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colRemove
    width: 20
    text-align: center
    font: verdana-11px-rounded
]], avancadosPanel)

  levelHeader.colName:setText('Level')
  levelHeader.colMin:setText('Min')
  levelHeader.colExit:setText('Sair')
  levelHeader.colContinue:setText('Continuar')
  levelHeader.colRemove:setText('X')

  local levelListPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 4
  fit-children: true
]], avancadosPanel)

  local function addLevelCheckerAction(index)
    if not CaveBot or not CaveBot.addAction then
      warn('[CaveBot Functions] CaveBot nao encontrado!')
      return
    end
    CaveBot.addAction("delay", "500", false)
    local callText
    if index == 1 then
      callText = "levelChecker1()"
    elseif index == 2 then
      callText = "levelChecker2()"
    elseif index == 3 then
      callText = "levelChecker3()"
    elseif index == 4 then
      callText = "levelChecker4()"
    elseif index == 5 then
      callText = "levelChecker5()"
    else
      callText = string.format("levelCheckerIndex(%d)", index)
    end
    CaveBot.addAction("function", callText .. "\nreturn true", true)
    if CaveBot.save then
      CaveBot.save()
    end
    print(string.format('[CaveBot Functions] %s + delay adicionado ao CaveBot!', callText))
  end

  local function rebuildLevelList()
    levelListPanel:destroyChildren()
    for index, entry in ipairs(levelList) do
      normalizeLevelEntry(entry, index)
      local row = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Button
    id: add
    text: Level
    width: 80
    height: 20

  SpinBox
    id: min
    width: 60
    height: 20
    text-align: center
    minimum: 0
    maximum: 100000
    step: 1
    editable: true
    focusable: true

  Panel
    id: exitPanel
    width: 90
    height: 20
    layout:
      type: horizontalBox
      spacing: 2

    TextEdit
      id: exit
      width: 68
      height: 20

    Button
      id: addExit
      text: +
      width: 18
      height: 20

  Panel
    id: contPanel
    width: 90
    height: 20
    layout:
      type: horizontalBox
      spacing: 2

    TextEdit
      id: cont
      width: 68
      height: 20

    Button
      id: addCont
      text: +
      width: 18
      height: 20

  Button
    id: remove
    text: X
    width: 20
    height: 20
]], levelListPanel)

      row.add:setText(entry.name or ("Level" .. tostring(index)))
      row.add.onClick = function()
        addLevelCheckerAction(index)
      end
      setBilingualTooltip(row.add, 'Adiciona este checker ao CaveBot.', 'Add this checker to the CaveBot.')

      row.min:setValue(tonumber(entry.minLevel) or 0)
      setBilingualTooltip(row.min, 'Level minimo para acionar o checker.', 'Minimum level to trigger the checker.')
      row.min.onValueChange = function(_, value)
        entry.minLevel = tonumber(value) or 0
        syncLevelLegacyFromList()
      end

      local exitField = findChildById(row, 'exit')
      if exitField then
        exitField:setText(entry.labelSair or 'reset')
        setBilingualTooltip(exitField, 'Label usada quando o level >= minimo.', 'Label used when level >= minimum.')
        exitField.onTextChange = function(_, text)
          entry.labelSair = text
          syncLevelLegacyFromList()
        end
      end

      local addExitBtn = findChildById(row, 'addExit')
      if addExitBtn then
        setBilingualTooltip(addExitBtn, 'Adicionar label Sair no CaveBot.', 'Add exit label to the CaveBot.')
        addExitBtn.onClick = function()
          addLabelToCaveBot(exitField and exitField:getText() or entry.labelSair or '')
        end
      end

      local contField = findChildById(row, 'cont')
      if contField then
        contField:setText(entry.labelContinuar or 'hunt')
        setBilingualTooltip(contField, 'Label usada quando o level < minimo.', 'Label used when level < minimum.')
        contField.onTextChange = function(_, text)
          entry.labelContinuar = text
          syncLevelLegacyFromList()
        end
      end

      local addContBtn = findChildById(row, 'addCont')
      if addContBtn then
        setBilingualTooltip(addContBtn, 'Adicionar label Continuar no CaveBot.', 'Add continue label to the CaveBot.')
        addContBtn.onClick = function()
          addLabelToCaveBot(contField and contField:getText() or entry.labelContinuar or '')
        end
      end

      setBilingualTooltip(row.remove, 'Remove esta regra.', 'Remove this rule.')
      row.remove.onClick = function()
        table.remove(levelList, index)
        syncLevelLegacyFromList()
        rebuildLevelList()
      end
    end

    syncLevelLegacyFromList()
    ensurePanelHeight(levelListPanel)
    ensurePanelHeight(avancadosPanel)
    refreshLayout(levelListPanel)
    refreshLayout(avancadosPanel)
  end

  levelTopRow.addRow.onClick = function()
    if #levelList >= MAX_STATS_ROWS then
      warn('[CaveBot Functions] Limite de 5 regras de Level atingido.')
      return
    end
    local nextIndex = #levelList + 1
    local minLevel, labelSair, labelContinuar = getLevelDefaults(nextIndex)
    table.insert(levelList, {
      name = "Level" .. tostring(nextIndex),
      minLevel = minLevel,
      labelSair = labelSair,
      labelContinuar = labelContinuar,
      userAdded = true,
      enabled = true
    })
    normalizeLevelEntry(levelList[#levelList], #levelList)
    syncLevelLegacyFromList()
    rebuildLevelList()
  end

  rebuildLevelList()

  -- ABA 3: Supply
  local supplyPanel = tabPanels['Supply']
  supplyPanel = supplyPanel:getChildById('panelContent') or supplyPanel
  if type(storage.cavebotChecks.supply) ~= "table" then
    storage.cavebotChecks.supply = { enabled = true, okLabel = 'hunt', lowLabel = 'resupply', items = {} }
  end
  local supplyCfg = storage.cavebotChecks.supply
  if type(supplyCfg.items) ~= "table" then
    supplyCfg.items = {}
  end
  sanitizeSupplyItems({ keepPlaceholders = true })

  local supplyTopRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  SmallBotSwitch
    id: enabled
    width: 32
    height: 20
    text-align: center
    text: ON

  Button
    id: title
    width: 150
    height: 20
    text-align: center
    font: verdana-11px-rounded

  Button
    id: addItem
    text: New item
    width: 70
    height: 20
]], supplyPanel)

  supplyTopRow.title:setText('Supply Checker')
  supplyTopRow.title:setColor('#98BF64')
  setBilingualTooltip(supplyTopRow.title, 'Adiciona o Supply Checker ao CaveBot.', 'Add Supply Checker to the CaveBot.')

  supplyTopRow.enabled:setOn(supplyCfg.enabled ~= false)
  setBilingualTooltip(supplyTopRow.enabled, 'Ativa ou desativa o Supply Checker.', 'Enable/disable Supply Checker.')
  supplyTopRow.enabled.onClick = function(widget)
    supplyCfg.enabled = not supplyCfg.enabled
    widget:setOn(supplyCfg.enabled)
  end

  supplyTopRow.title.onClick = function()
    if CaveBot and CaveBot.addAction then
      local label = supplyCfg.okLabel or 'hunt'
      CaveBot.addAction('delay', '500', false)
      CaveBot.addAction('function', 'supplyChecker()\nreturn true', true)
      if label ~= '' then
        CaveBot.addAction('label', label, true)
      end
      if CaveBot.save then
        CaveBot.save()
      end
      print('[CaveBot Functions] supplyChecker adicionado ao CaveBot!')
    else
      warn('[CaveBot Functions] CaveBot nao encontrado!')
    end
  end

  setBilingualTooltip(supplyTopRow.addItem, 'Adicionar novo item.', 'Add new item.')

  local supplyLabelsRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: okLabel
    width: 60
    text-align: right
    font: verdana-11px-rounded

  TextEdit
    id: okField
    width: 80
    height: 20

  Button
    id: addOkLabel
    text: +
    width: 20
    height: 20

  Label
    id: lowLabel
    width: 90
    text-align: right
    font: verdana-11px-rounded

  TextEdit
    id: lowField
    width: 80
    height: 20

  Button
    id: addLowLabel
    text: +
    width: 20
    height: 20
]], supplyPanel)

  supplyLabelsRow.okLabel:setText('Label OK:')
  supplyLabelsRow.lowLabel:setText('Label Refilar:')
  supplyLabelsRow.okField:setText(supplyCfg.okLabel or 'hunt')
  supplyLabelsRow.lowField:setText(supplyCfg.lowLabel or 'resupply')
  setBilingualTooltip(supplyLabelsRow.okField, 'Label usada quando tudo estiver OK.', 'Label used when everything is OK.')
  setBilingualTooltip(supplyLabelsRow.lowField, 'Label usada quando faltar item.', 'Label used when items are missing.')

  local function addSupplyLabel(label)
    if not CaveBot or not CaveBot.addAction then
      warn('[Supply Checker] CaveBot nao encontrado!')
      return
    end
    if not label or label:match('^%s*$') then
      warn('[Supply Checker] Label vazia.')
      return
    end
    CaveBot.addAction('label', label, true)
    if CaveBot.save then
      CaveBot.save()
    end
    print(string.format("[Supply Checker] Label '%s' adicionada ao CaveBot.", label))
  end

  setBilingualTooltip(supplyLabelsRow.addOkLabel, 'Adicionar label OK no CaveBot.', 'Add OK label to the CaveBot.')
  supplyLabelsRow.addOkLabel.onClick = function()
    local label = supplyLabelsRow.okField and supplyLabelsRow.okField:getText() or supplyCfg.okLabel or ''
    addSupplyLabel(label)
  end

  setBilingualTooltip(supplyLabelsRow.addLowLabel, 'Adicionar label Refilar no CaveBot.', 'Add Resupply label to the CaveBot.')
  supplyLabelsRow.addLowLabel.onClick = function()
    local label = supplyLabelsRow.lowField and supplyLabelsRow.lowField:getText() or supplyCfg.lowLabel or ''
    addSupplyLabel(label)
  end
  supplyLabelsRow.okField.onTextChange = function(_, text)
    supplyCfg.okLabel = text
  end
  supplyLabelsRow.lowField.onTextChange = function(_, text)
    supplyCfg.lowLabel = text
  end

  local supplyHeader = setupUI([[
Panel
  height: 18
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: colOn
    width: 32
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colItem
    width: 32
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colMin
    width: 60
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colRemove
    width: 20
    text-align: center
    font: verdana-11px-rounded
]], supplyPanel)

  supplyHeader.colOn:setText('On')
  supplyHeader.colItem:setText('Item')
  supplyHeader.colMin:setText('Min')
  supplyHeader.colRemove:setText('X')

  local supplyListPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 4
  fit-children: true
]], supplyPanel)

  local function normalizeSupplyItem(entry)
    entry.enabled = entry.enabled ~= false
    entry.id = tonumber(entry.id) or 0
    entry.amount = tonumber(entry.amount) or 0
  end

  local function rebuildSupplyList()
    supplyListPanel:destroyChildren()
    for index, entry in ipairs(supplyCfg.items) do
      normalizeSupplyItem(entry)
      local row = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  SmallBotSwitch
    id: enabled
    width: 32
    height: 20
    text-align: center
    text: ON

  BotItem
    id: item
    size: 28 32

  SpinBox
    id: min
    width: 60
    height: 20
    text-align: center
    minimum: 0
    maximum: 100000
    step: 1
    editable: true
    focusable: true

  Button
    id: remove
    text: X
    width: 20
    height: 20
]], supplyListPanel)

      row.enabled:setOn(entry.enabled)
      setBilingualTooltip(row.enabled, 'Ativa ou desativa este item.', 'Enable/disable this item.')
      row.enabled.onClick = function(widget)
        entry.enabled = not entry.enabled
        widget:setOn(entry.enabled)
      end

      row.item:setItemId(entry.id)
      setBilingualTooltip(row.item, 'Arraste o item para definir o ID.', 'Drag the item to set its ID.')
      row.item.onItemChange = function(widget)
        local id = widget:getItemId()
        if not id or id < 100 then
          entry.id = 0
          return
        end
        entry.id = id
        widget:setImageSource('')
      end

      row.min:setValue(entry.amount)
      setBilingualTooltip(row.min, 'Quantidade minima para considerar OK.', 'Minimum amount to consider OK.')
      row.min.onValueChange = function(_, value)
        entry.amount = tonumber(value) or 0
      end

      setBilingualTooltip(row.remove, 'Remove o item da lista.', 'Remove item from the list.')
      row.remove.onClick = function()
        table.remove(supplyCfg.items, index)
        rebuildSupplyList()
      end
    end

    ensurePanelHeight(supplyListPanel)
    ensurePanelHeight(supplyPanel)
    refreshLayout(supplyListPanel)
    refreshLayout(supplyPanel)
  end

  supplyTopRow.addItem.onClick = function()
    if #supplyCfg.items >= 10 then
      warn('[Supply Checker] Limite de 10 itens atingido.')
      return
    end
    table.insert(supplyCfg.items, { enabled = true, id = 0, amount = 0 })
    rebuildSupplyList()
  end

  rebuildSupplyList()

  -- === BUY SUPPLIES ===
  if type(storage.buySupplies) ~= "table" then
    storage.buySupplies = defaultBuySupplyConfig()
  end
  local buyCfg = storage.buySupplies
  if type(buyCfg.items) ~= "table" then
    buyCfg.items = {}
  end
  sanitizeBuySuppliesItems({ keepPlaceholders = true }, buyCfg)

  local buyTopRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  SmallBotSwitch
    id: enabled
    width: 32
    height: 20
    text-align: center
    text: ON

  Button
    id: title
    width: 150
    height: 20
    text-align: center
    font: verdana-11px-rounded

  Label
    id: delayLabel
    width: 90
    text-align: right
    font: verdana-11px-rounded

  SpinBox
    id: delay
    width: 70
    height: 20
    text-align: center
    minimum: 0
    maximum: 60000
    step: 50
    editable: true
    focusable: true

  Button
    id: addBtn
    text: New item
    width: 70
    height: 20
]], supplyPanel)

  buyTopRow.title:setText('Buy Supplies')
  buyTopRow.title:setColor('#98BF64')
  buyTopRow.delayLabel:setText('Delay Trade:')
  setBilingualTooltip(buyTopRow.title, "Adiciona Buy Supplies ao CaveBot.", "Add Buy Supplies to the CaveBot.")

  buyTopRow.enabled:setOn(buyCfg.enabled ~= false)
  setBilingualTooltip(buyTopRow.enabled, 'Ativa ou desativa o Buy Supplies.', 'Enable/disable Buy Supplies.')
  buyTopRow.enabled.onClick = function(widget)
    buyCfg.enabled = not buyCfg.enabled
    widget:setOn(buyCfg.enabled)
  end

  buyTopRow.delay:setValue(tonumber(buyCfg.talkDelay) or 500)
  setBilingualTooltip(buyTopRow.delay, 'Delay ao abrir trade (ms).', 'Delay when opening trade (ms).')
  buyTopRow.delay.onValueChange = function(_, value)
    buyCfg.talkDelay = tonumber(value) or 500
  end

  buyTopRow.title.onClick = function()
    if CaveBot and CaveBot.addAction then
      CaveBot.addAction("delay", "500", false)
      CaveBot.addAction("function", "return buySupplyChecker()", true)
      if CaveBot.save then
        CaveBot.save()
      end
      print('[Buy Supply] buySupplyChecker adicionado ao CaveBot!')
    else
      warn('[Buy Supply] CaveBot nao encontrado!')
    end
  end

  setBilingualTooltip(buyTopRow.addBtn, 'Adicionar novo item de compra.', 'Add new buy item.')

  local buyHeader = setupUI([[
Panel
  height: 18
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: colOn
    width: 32
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colItem
    width: 32
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colNpc
    width: 90
    text-align: left
    font: verdana-11px-rounded

  Label
    id: colTarget
    width: 60
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colMax
    width: 60
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colPriority
    width: 45
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colRemove
    width: 20
    text-align: center
    font: verdana-11px-rounded
]], supplyPanel)

  buyHeader.colOn:setText('On')
  buyHeader.colItem:setText('Item')
  buyHeader.colNpc:setText('NPC')
  buyHeader.colTarget:setText('Alvo')
  buyHeader.colMax:setText('Max')
  buyHeader.colPriority:setText('Prio')
  buyHeader.colRemove:setText('X')

  local buyListPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 4
  fit-children: true
]], supplyPanel)

  local function normalizeBuyItem(entry, index)
    entry.enabled = entry.enabled ~= false
    entry.id = tonumber(entry.id) or 0
    entry.amount = tonumber(entry.amount) or 0
    entry.npcName = entry.npcName or ''
    entry.maxPerBuy = tonumber(entry.maxPerBuy) or 1000
    entry.priority = tonumber(entry.priority) or index
  end

  local function rebuildBuyList()
    buyListPanel:destroyChildren()
    for index, entry in ipairs(buyCfg.items) do
      normalizeBuyItem(entry, index)
      local row = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  SmallBotSwitch
    id: enabled
    width: 32
    height: 20
    text-align: center
    text: ON

  BotItem
    id: item
    size: 28 32

  TextEdit
    id: npc
    width: 90
    height: 20

  SpinBox
    id: target
    width: 50
    height: 20
    text-align: center
    minimum: 0
    maximum: 100000
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: maxBuy
    width: 50
    height: 20
    text-align: center
    minimum: 0
    maximum: 100000
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: priority
    width: 40
    height: 20
    text-align: center
    minimum: 1
    maximum: 999
    step: 1
    editable: true
    focusable: true

  Button
    id: remove
    text: X
    width: 20
    height: 20
]], buyListPanel)

      row.enabled:setOn(entry.enabled)
      setBilingualTooltip(row.enabled, 'Ativa ou desativa este item.', 'Enable/disable this item.')
      row.enabled.onClick = function(widget)
        entry.enabled = not entry.enabled
        widget:setOn(entry.enabled)
      end

      row.item:setItemId(entry.id)
      setBilingualTooltip(row.item, 'Arraste o item para definir o ID.', 'Drag the item to set its ID.')
      row.item.onItemChange = function(widget)
        local id = widget:getItemId()
        if not id or id < 100 then
          entry.id = 0
          return
        end
        entry.id = id
        widget:setImageSource('')
      end

      row.npc:setText(entry.npcName)
      setBilingualTooltip(row.npc, 'Nome do NPC que vende o item.', 'NPC name that sells the item.')
      row.npc.onTextChange = function(_, text)
        entry.npcName = text
      end

      row.target:setValue(entry.amount)
      setBilingualTooltip(row.target, 'Quantidade alvo a manter.', 'Target amount to keep.')
      row.target.onValueChange = function(_, value)
        entry.amount = tonumber(value) or 0
      end

      row.maxBuy:setValue(entry.maxPerBuy)
      setBilingualTooltip(
        row.maxBuy,
        'Limite maximo por compra deste item (0 = sem limite).',
        'Maximum per purchase for this item (0 = unlimited).'
      )
      row.maxBuy.onValueChange = function(_, value)
        entry.maxPerBuy = tonumber(value) or 0
      end

      row.priority:setValue(entry.priority)
      setBilingualTooltip(
        row.priority,
        'Ordem de compra entre itens/NPCs. Menor numero compra primeiro.',
        'Purchase order among items/NPCs. Lower number buys first.'
      )
      row.priority.onValueChange = function(_, value)
        entry.priority = tonumber(value) or 1
      end

      setBilingualTooltip(row.remove, 'Remove o item da lista.', 'Remove item from the list.')
      row.remove.onClick = function()
        table.remove(buyCfg.items, index)
        rebuildBuyList()
      end
    end
    ensurePanelHeight(buyListPanel)
    ensurePanelHeight(supplyPanel)
    refreshLayout(buyListPanel)
    refreshLayout(supplyPanel)
  end

  buyTopRow.addBtn.onClick = function()
    if #buyCfg.items >= MAX_BUY_ITEMS then
      warn('[Buy Supply] Limite de 10 itens atingido.')
      return
    end
    table.insert(buyCfg.items, {
      enabled = true,
      id = 0,
      npcName = '',
      amount = 0,
      maxPerBuy = 1000,
      priority = #buyCfg.items + 1
    })
    rebuildBuyList()
  end

  rebuildBuyList()

  -- ABA 5: Imbuiments
  local imbuementsPanel = tabPanels['Imbuiments']
  imbuementsPanel = imbuementsPanel:getChildById('panelContent') or imbuementsPanel

  createCheckerSection(imbuementsPanel, {
    title = 'IMBUEMENT CHECKER',
    labelTooltip = "PT: Aplica os imbuements configurados ao passar pelo shrine. Configure no 'Imbuement Setup'.\nEN: Applies the configured imbuements when passing the shrine. Configure in 'Imbuement Setup'.",
    infoText = 'Aplica imbuements automaticamente. Use ao lado do shrine.',
    addBtnText = 'Imbuement Checker',
    addBtnTooltip = 'PT: Adiciona o Imbuement Checker direto no CaveBot. Aplica os imbuements configurados.\nEN: Adds Imbuement Checker to the CaveBot. Applies the configured imbuements.',
    showSetup = false,
    addHandler = function()
      if CaveBot and CaveBot.addAction then
        CaveBot.addAction("delay", "500", false)
        CaveBot.addAction("function", "checkerImbuement()\nreturn true", true)
        CaveBot.addAction("delay", "10000", false)
        if CaveBot.save then
          CaveBot.save()
        end
        print('[CaveBot Functions] checkerImbuement + delay adicionado ao CaveBot!')
      else
        warn('[CaveBot Functions] CaveBot nao encontrado!')
      end
    end
  })

  g_ui.createWidget('BotSeparator', imbuementsPanel)

  local imbuementsSetupPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 5
  fit-children: true
]], imbuementsPanel)

  local imbuementsBuilt = false
  local function buildImbuementsSetup()
    if imbuementsBuilt then
      return
    end
    if ImbuementSetup and ImbuementSetup.build then
      ImbuementSetup.build(imbuementsSetupPanel)
    else
      local imbueFallback = g_ui.createWidget('BotLabel', imbuementsSetupPanel)
      imbueFallback:setText('Imbuiments setup indisponivel.')
      imbueFallback:setColor('#FFFFFF')
    end
    -- Spacer to avoid last item being clipped by the scroll container.
    local imbueSpacer = g_ui.createWidget('Panel', imbuementsSetupPanel)
    imbueSpacer:setHeight(24)
    imbuementsBuilt = true
    ensurePanelHeight(imbuementsSetupPanel)
    ensurePanelHeight(imbuementsPanel)
    refreshLayout(imbuementsSetupPanel)
    refreshLayout(imbuementsPanel)
  end

  imbuementsPanel.onVisibilityChange = function(_, visible)
    if visible then
      buildImbuementsSetup()
    end
  end
  buildImbuementsSetup()

  -- ABA 5: Time
  local timePanel = tabPanels['Time']
  timePanel = timePanel:getChildById('panelContent') or timePanel
  local timeList = ensureTimeStatsList()

  local timeTopRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: title
    width: 150
    text-align: left
    font: verdana-11px-rounded

  Button
    id: addRow
    text: +
    width: 20
    height: 20
]], timePanel)

  timeTopRow.title:setText('Time Stats')
  timeTopRow.title:setColor('#98BF64')
  setBilingualTooltip(timeTopRow.title, 'Regras de horario sempre visiveis na tela.', 'Time rules are always visible.')
  setBilingualTooltip(timeTopRow.addRow, 'Adicionar nova regra de horario.', 'Add new time rule.')

  local timeHeader = setupUI([[
Panel
  height: 18
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: colName
    width: 70
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colHStart
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colMStart
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colHEnd
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colMEnd
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colOutside
    width: 90
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colInside
    width: 90
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colRemove
    width: 20
    text-align: center
    font: verdana-11px-rounded
]], timePanel)

  timeHeader.colName:setText('Time')
  timeHeader.colHStart:setText('Hi')
  timeHeader.colMStart:setText('Mi')
  timeHeader.colHEnd:setText('Hf')
  timeHeader.colMEnd:setText('Mf')
  timeHeader.colOutside:setText('Fora')
  timeHeader.colInside:setText('Dentro')
  timeHeader.colRemove:setText('X')

  local timeListPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 4
  fit-children: true
]], timePanel)

  local function getTimeOutsideLabel(entry, index)
    local invert = entry.invert
    if invert == nil then
      invert = (index == 1)
    end
    if invert then
      return entry.labelInside or "hunt"
    end
    return entry.labelOutside or "wait"
  end

  local function getTimeInsideLabel(entry, index)
    local invert = entry.invert
    if invert == nil then
      invert = (index == 1)
    end
    if invert then
      return entry.labelOutside or "wait"
    end
    return entry.labelInside or "event"
  end

  local function setTimeOutsideLabel(entry, index, value)
    local invert = entry.invert
    if invert == nil then
      invert = (index == 1)
    end
    if invert then
      entry.labelInside = value
    else
      entry.labelOutside = value
    end
  end

  local function setTimeInsideLabel(entry, index, value)
    local invert = entry.invert
    if invert == nil then
      invert = (index == 1)
    end
    if invert then
      entry.labelOutside = value
    else
      entry.labelInside = value
    end
  end

  local function addTimeCheckerAction(index)
    if not CaveBot or not CaveBot.addAction then
      warn('[CaveBot Functions] CaveBot nao encontrado!')
      return
    end
    CaveBot.addAction("delay", "500", false)
    local callText
    if index == 1 then
      callText = "timeChecker1()"
    elseif index == 2 then
      callText = "timeChecker2()"
    elseif index == 3 then
      callText = "timeChecker3()"
    elseif index == 4 then
      callText = "timeChecker4()"
    else
      callText = string.format("timeCheckerIndex(%d)", index)
    end
    CaveBot.addAction("function", callText .. "\nreturn true", true)
    if CaveBot.save then
      CaveBot.save()
    end
    print(string.format('[CaveBot Functions] %s + delay adicionado ao CaveBot!', callText))
  end

  local function rebuildTimeList()
    timeListPanel:destroyChildren()
    for index, entry in ipairs(timeList) do
      normalizeTimeEntry(entry, index, index == 1)
      local row = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Button
    id: add
    text: Time
    width: 70
    height: 20

  SpinBox
    id: hStart
    width: 40
    height: 20
    text-align: center
    minimum: 0
    maximum: 23
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: mStart
    width: 40
    height: 20
    text-align: center
    minimum: 0
    maximum: 59
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: hEnd
    width: 40
    height: 20
    text-align: center
    minimum: 0
    maximum: 23
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: mEnd
    width: 40
    height: 20
    text-align: center
    minimum: 0
    maximum: 59
    step: 1
    editable: true
    focusable: true

  TextEdit
    id: outside
    width: 68
    height: 20

  Button
    id: addOutside
    text: +
    width: 18
    height: 20

  TextEdit
    id: inside
    width: 68
    height: 20

  Button
    id: addInside
    text: +
    width: 18
    height: 20

  Button
    id: remove
    text: X
    width: 20
    height: 20
]], timeListPanel)

      row.add:setText(entry.name or ("Time" .. tostring(index)))
      row.add.onClick = function()
        addTimeCheckerAction(index)
      end
      setBilingualTooltip(row.add, 'Adiciona este checker ao CaveBot.', 'Add this checker to the CaveBot.')

      row.hStart:setValue(tonumber(entry.hourStart) or 0)
      row.hStart.onValueChange = function(_, value)
        entry.hourStart = tonumber(value) or 0
        syncTimeLegacyFromList()
      end
      setBilingualTooltip(row.hStart, 'Hora inicial do intervalo (0-23).', 'Start hour of the interval (0-23).')

      row.mStart:setValue(tonumber(entry.minuteStart) or 0)
      row.mStart.onValueChange = function(_, value)
        entry.minuteStart = tonumber(value) or 0
        syncTimeLegacyFromList()
      end
      setBilingualTooltip(row.mStart, 'Minuto inicial do intervalo (0-59).', 'Start minute of the interval (0-59).')

      row.hEnd:setValue(tonumber(entry.hourEnd) or 23)
      row.hEnd.onValueChange = function(_, value)
        entry.hourEnd = tonumber(value) or 23
        syncTimeLegacyFromList()
      end
      setBilingualTooltip(row.hEnd, 'Hora final do intervalo (0-23).', 'End hour of the interval (0-23).')

      row.mEnd:setValue(tonumber(entry.minuteEnd) or 59)
      row.mEnd.onValueChange = function(_, value)
        entry.minuteEnd = tonumber(value) or 59
        syncTimeLegacyFromList()
      end
      setBilingualTooltip(row.mEnd, 'Minuto final do intervalo (0-59).', 'End minute of the interval (0-59).')

      local outsideField = findChildById(row, 'outside')
      if outsideField then
        outsideField:setText(getTimeOutsideLabel(entry, index))
        setBilingualTooltip(outsideField, 'Label quando estiver FORA do intervalo.', 'Label when OUTSIDE the interval.')
        outsideField.onTextChange = function(_, text)
          setTimeOutsideLabel(entry, index, text)
          syncTimeLegacyFromList()
        end
      end

      local addOutsideBtn = findChildById(row, 'addOutside')
      if addOutsideBtn then
        setBilingualTooltip(addOutsideBtn, 'Adicionar label Fora no CaveBot.', 'Add outside label to the CaveBot.')
        addOutsideBtn.onClick = function()
          addLabelToCaveBot(outsideField and outsideField:getText() or getTimeOutsideLabel(entry, index))
        end
      end

      local insideField = findChildById(row, 'inside')
      if insideField then
        insideField:setText(getTimeInsideLabel(entry, index))
        setBilingualTooltip(insideField, 'Label quando estiver DENTRO do intervalo.', 'Label when INSIDE the interval.')
        insideField.onTextChange = function(_, text)
          setTimeInsideLabel(entry, index, text)
          syncTimeLegacyFromList()
        end
      end

      local addInsideBtn = findChildById(row, 'addInside')
      if addInsideBtn then
        setBilingualTooltip(addInsideBtn, 'Adicionar label Dentro no CaveBot.', 'Add inside label to the CaveBot.')
        addInsideBtn.onClick = function()
          addLabelToCaveBot(insideField and insideField:getText() or getTimeInsideLabel(entry, index))
        end
      end

      setBilingualTooltip(row.remove, 'Remove esta regra.', 'Remove this rule.')
      row.remove.onClick = function()
        table.remove(timeList, index)
        syncTimeLegacyFromList()
        rebuildTimeList()
      end
    end

    syncTimeLegacyFromList()
    ensurePanelHeight(timeListPanel)
    ensurePanelHeight(timePanel)
    refreshLayout(timeListPanel)
    refreshLayout(timePanel)
  end

  timeTopRow.addRow.onClick = function()
    if #timeList >= MAX_STATS_ROWS then
      warn('[CaveBot Functions] Limite de 5 regras de Time atingido.')
      return
    end
    local nextIndex = #timeList + 1
    table.insert(timeList, {
      name = "Time" .. tostring(nextIndex),
      hourStart = 0,
      minuteStart = 0,
      hourEnd = 23,
      minuteEnd = 59,
      labelInside = "event",
      labelOutside = "wait",
      invert = false,
      userAdded = true,
      enabled = true
    })
    normalizeTimeEntry(timeList[#timeList], #timeList, false)
    syncTimeLegacyFromList()
    rebuildTimeList()
  end

  rebuildTimeList()

  -- ABA 6: Tasker
  local taskerPanel = tabPanels['Tasker']
  taskerPanel = taskerPanel:getChildById('panelContent') or taskerPanel
  local taskerCfg = ensureTaskerConfig()

  local taskerTopRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  SmallBotSwitch
    id: enabled
    width: 32
    height: 20
    text-align: center
    text: ON

  Button
    id: title
    width: 150
    height: 20
    text-align: center
    font: verdana-11px-rounded

  Button
    id: addRow
    text: New mob
    width: 52
    height: 20

  Button
    id: resetKills
    text: Reset
    width: 46
    height: 20

  Button
    id: refreshKills
    text: Atualizar
    width: 66
    height: 20
]], taskerPanel)

  local rebuildTaskerList
  local taskerKillRows = {}

  local function refreshTaskerKillLabels()
    for _, rowInfo in ipairs(taskerKillRows) do
      local label = rowInfo.label
      local entry = rowInfo.entry
      if label and entry then
        if label.isDestroyed and label:isDestroyed() then
          -- Ignora labels que ja foram destruídas.
        else
          label:setText(tostring(getTaskerMonsterKills(entry.name)))
        end
      end
    end
  end

  local function startTaskerAutoRefresh()
    local thisWindow = functionsWindow
    local function tick()
      if not thisWindow then
        return
      end
      if functionsWindow ~= thisWindow then
        return
      end
      if thisWindow.isDestroyed and thisWindow:isDestroyed() then
        return
      end
      if thisWindow.isVisible and thisWindow:isVisible() then
        refreshTaskerKillLabels()
      end
      schedule(1000, tick)
    end
    schedule(1000, tick)
  end

  taskerTopRow.title:setText('Tasker Checker')
  taskerTopRow.title:setColor('#98BF64')
  setBilingualTooltip(taskerTopRow.title, 'Adiciona o Tasker Checker no CaveBot.', 'Add the Tasker Checker to the CaveBot.')
  setBilingualTooltip(taskerTopRow.addRow, 'Adicionar novo monstro para task.', 'Add a new monster task.')
  setBilingualTooltip(taskerTopRow.resetKills, 'Resetar mortes contadas no Tasker.', 'Reset Tasker tracked kills.')
  setBilingualTooltip(taskerTopRow.refreshKills, 'Atualiza os contadores de mortes agora.', 'Refresh kill counters now.')

  taskerTopRow.enabled:setOn(taskerCfg.enabled ~= false)
  setBilingualTooltip(taskerTopRow.enabled, 'Ativa ou desativa o Tasker Checker.', 'Enable or disable Tasker Checker.')
  taskerTopRow.enabled.onClick = function(widget)
    taskerCfg.enabled = not taskerCfg.enabled
    widget:setOn(taskerCfg.enabled)
  end

  taskerTopRow.title.onClick = function()
    if CaveBot and CaveBot.addAction then
      CaveBot.addAction("delay", "500", false)
      CaveBot.addAction("function", "taskerChecker()\nreturn true", true)
      if CaveBot.save then
        CaveBot.save()
      end
      print('[CaveBot Functions] taskerChecker + delay adicionado ao CaveBot!')
    else
      warn('[CaveBot Functions] CaveBot nao encontrado!')
    end
  end

  taskerTopRow.resetKills.onClick = function()
    taskerKills = {}
    taskerAnalyzerBaseline = {}
    taskerHasGlobalReset = true

    for _, entry in ipairs(taskerCfg.monsters or {}) do
      local normalized = normalizeTaskerMonsterName(entry.name)
      if normalized ~= "" then
        taskerAnalyzerBaseline[normalized] = getTaskerAnalyzerKills(normalized, normalized)
      end
    end

    if rebuildTaskerList then
      rebuildTaskerList()
    end
    print('[Tasker Checker] Mortes resetadas.')
  end

  taskerTopRow.refreshKills.onClick = function()
    refreshTaskerKillLabels()
    print('[Tasker Checker] Contadores atualizados.')
  end

  local taskerOptionsRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  SmallBotSwitch
    id: checkAll
    width: 32
    height: 20
    text-align: center
    text: ON

  Label
    id: checkAllText
    width: 170
    text-align: left
    font: verdana-11px-rounded
]], taskerPanel)

  taskerOptionsRow.checkAllText:setText('Verificar todos monstros')
  taskerOptionsRow.checkAll:setOn(taskerCfg.checkAllMonsters ~= false)
  setBilingualTooltip(
    taskerOptionsRow.checkAll,
    'ON: so vai para entrega quando TODOS os monstros baterem a meta. OFF: qualquer um que bater a meta ja entrega.',
    'ON: goes to delivery only when ALL monsters reach target. OFF: any monster reaching target goes to delivery.'
  )
  taskerOptionsRow.checkAll.onClick = function(widget)
    taskerCfg.checkAllMonsters = not taskerCfg.checkAllMonsters
    taskerCfg.checkAll = taskerCfg.checkAllMonsters
    widget:setOn(taskerCfg.checkAllMonsters)
  end

  local taskerLabelsRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: entregaLabel
    width: 50
    text-align: right
    font: verdana-11px-rounded

  TextEdit
    id: entregaField
    width: 80
    height: 20

  Button
    id: addEntrega
    text: +
    width: 20
    height: 20

  Label
    id: continuarLabel
    width: 60
    text-align: right
    font: verdana-11px-rounded

  TextEdit
    id: continuarField
    width: 80
    height: 20

  Button
    id: addContinuar
    text: +
    width: 20
    height: 20
]], taskerPanel)

  taskerLabelsRow.entregaLabel:setText('Entrega:')
  taskerLabelsRow.continuarLabel:setText('Continuar:')
  taskerLabelsRow.entregaField:setText(taskerCfg.labelEntrega or 'entregartask')
  taskerLabelsRow.continuarField:setText(taskerCfg.labelContinuar or 'continuartask')
  setBilingualTooltip(taskerLabelsRow.entregaField, 'Label para quando task estiver concluida.', 'Label when task is completed.')
  setBilingualTooltip(taskerLabelsRow.continuarField, 'Label para continuar huntando.', 'Label to continue hunting.')

  taskerLabelsRow.entregaField.onTextChange = function(_, text)
    taskerCfg.labelEntrega = text
  end
  taskerLabelsRow.continuarField.onTextChange = function(_, text)
    taskerCfg.labelContinuar = text
  end

  setBilingualTooltip(taskerLabelsRow.addEntrega, 'Adicionar label de entrega no CaveBot.', 'Add delivery label to CaveBot.')
  taskerLabelsRow.addEntrega.onClick = function()
    local label = taskerLabelsRow.entregaField and taskerLabelsRow.entregaField:getText() or taskerCfg.labelEntrega or ''
    addLabelToCaveBot(label)
  end

  setBilingualTooltip(taskerLabelsRow.addContinuar, 'Adicionar label de continuar no CaveBot.', 'Add continue label to CaveBot.')
  taskerLabelsRow.addContinuar.onClick = function()
    local label = taskerLabelsRow.continuarField and taskerLabelsRow.continuarField:getText() or taskerCfg.labelContinuar or ''
    addLabelToCaveBot(label)
  end

  local taskerHeader = setupUI([[
Panel
  height: 18
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: colOn
    width: 32
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colMonster
    width: 160
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colGoal
    width: 60
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colKills
    width: 55
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colRemove
    width: 20
    text-align: center
    font: verdana-11px-rounded
]], taskerPanel)

  taskerHeader.colOn:setText('On')
  taskerHeader.colMonster:setText('Monstro')
  taskerHeader.colGoal:setText('Meta')
  taskerHeader.colKills:setText('Mortes')
  taskerHeader.colRemove:setText('X')

  local taskerListPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 4
  fit-children: true
]], taskerPanel)

  rebuildTaskerList = function()
    taskerListPanel:destroyChildren()
    taskerKillRows = {}
    ensureTaskerConfig()
    for index, entry in ipairs(taskerCfg.monsters) do
      normalizeTaskerMonsterEntry(entry)
      local row = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  SmallBotSwitch
    id: enabled
    width: 32
    height: 20
    text-align: center
    text: ON

  TextEdit
    id: monster
    width: 160
    height: 20

  SpinBox
    id: goal
    width: 60
    height: 20
    text-align: center
    minimum: 0
    maximum: 999999
    step: 1
    editable: true
    focusable: true

  Label
    id: killed
    width: 55
    text-align: center
    font: verdana-11px-rounded

  Button
    id: remove
    text: X
    width: 20
    height: 20
]], taskerListPanel)

      row.enabled:setOn(entry.enabled ~= false)
      setBilingualTooltip(row.enabled, 'Ativa ou desativa este monstro.', 'Enable or disable this monster.')
      row.enabled.onClick = function(widget)
        entry.enabled = not entry.enabled
        widget:setOn(entry.enabled)
      end

      row.monster:setText(entry.name or '')
      setBilingualTooltip(row.monster, 'Nome do monstro exatamente como no loot.', 'Monster name exactly as in loot.')
      row.monster.onTextChange = function(_, text)
        entry.name = text
        row.killed:setText(tostring(getTaskerMonsterKills(text)))
      end

      row.goal:setValue(tonumber(entry.amount) or 0)
      setBilingualTooltip(row.goal, 'Quantidade de mortes para concluir.', 'Kills needed to complete.')
      row.goal.onValueChange = function(_, value)
        entry.amount = tonumber(value) or 0
      end

      row.killed:setText(tostring(getTaskerMonsterKills(entry.name)))
      setBilingualTooltip(row.killed, 'Quantidade de mortes detectadas nesta sessao.', 'Kills detected in this session.')
      table.insert(taskerKillRows, { label = row.killed, entry = entry })

      setBilingualTooltip(row.remove, 'Remove este monstro.', 'Remove this monster.')
      row.remove.onClick = function()
        table.remove(taskerCfg.monsters, index)
        rebuildTaskerList()
      end
    end

    ensurePanelHeight(taskerListPanel)
    ensurePanelHeight(taskerPanel)
    refreshLayout(taskerListPanel)
    refreshLayout(taskerPanel)
  end

  taskerTopRow.addRow.onClick = function()
    if #taskerCfg.monsters >= TASKER_MAX_MONSTERS then
      warn('[Tasker Checker] Limite de 5 monstros atingido.')
      return
    end
    table.insert(taskerCfg.monsters, {
      enabled = true,
      name = "",
      amount = 0
    })
    rebuildTaskerList()
  end

  rebuildTaskerList()
  startTaskerAutoRefresh()

  -- ABA 7: Trainer
  local trainerPanel = tabPanels['Trainer']
  trainerPanel = trainerPanel:getChildById('panelContent') or trainerPanel
  local trainerCfg = ensureTrainerConfig()

  local trainerTopRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  SmallBotSwitch
    id: enabled
    width: 32
    height: 20
    text-align: center
    text: ON

  Button
    id: addChecker
    width: 170
    height: 20
    text-align: center
    font: verdana-11px-rounded
]], trainerPanel)

  local trainerMacroRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Button
    id: macroToggle
    width: 206
    height: 20
    text-align: center
    font: verdana-11px-rounded
]], trainerPanel)

  trainerTopRow.addChecker:setText('Trainer Checker')
  trainerTopRow.addChecker:setColor('#98BF64')
  setBilingualTooltip(trainerTopRow.addChecker, 'Adiciona o Trainer Checker no CaveBot.', 'Add Trainer Checker to the CaveBot.')
  setBilingualTooltip(
    trainerTopRow.enabled,
    'Ativa ou desativa a checagem de stamina para ir treinar.',
    'Enable or disable stamina check to go training.'
  )
  setBilingualTooltip(
    trainerMacroRow.macroToggle,
    'Liga/desliga macro para sair do trainer quando stamina estiver OK (checa a cada 1 minuto).',
    'Toggle macro to leave trainer when stamina is OK (checks every 1 minute).'
  )

  trainerTopRow.enabled:setOn(trainerCfg.enabled ~= false)
  trainerTopRow.enabled.onClick = function(widget)
    trainerCfg.enabled = not trainerCfg.enabled
    widget:setOn(trainerCfg.enabled)
  end

  trainerTopRow.addChecker.onClick = function()
    if CaveBot and CaveBot.addAction then
      CaveBot.addAction("delay", "500", false)
      CaveBot.addAction("function", "trainerChecker()\nreturn true", true)
      if CaveBot.save then
        CaveBot.save()
      end
      print('[CaveBot Functions] trainerChecker + delay adicionado ao CaveBot!')
    else
      warn('[CaveBot Functions] CaveBot nao encontrado!')
    end
  end

  trainerMacroRow.macroToggle.onClick = function()
    local cfg = ensureTrainerConfig()
    setTrainerExitMacroEnabled(not cfg.macroEnabled)
    updateTrainerExitMacroButton(trainerMacroRow.macroToggle)
  end
  updateTrainerExitMacroButton(trainerMacroRow.macroToggle)

  local trainerHoursRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: hoursLabel
    width: 70
    text-align: right
    font: verdana-11px-rounded

  SpinBox
    id: hoursField
    width: 60
    height: 20
    text-align: center
    minimum: 0
    maximum: 42
    step: 1
    editable: true
    focusable: true
]], trainerPanel)

  trainerHoursRow.hoursLabel:setText('Horas:')
  trainerHoursRow.hoursField:setValue(tonumber(trainerCfg.minHours) or 16)
  setBilingualTooltip(trainerHoursRow.hoursField, 'Horas de stamina para checar (sem minutos).', 'Stamina hours to check (no minutes).')
  trainerHoursRow.hoursField.onValueChange = function(_, value)
    trainerCfg.minHours = math.max(0, math.floor(tonumber(value) or 0))
    trainerCfg.minStamina = trainerCfg.minHours * 60
    trainerCfg.exitTriggered = false
  end

  local trainerLabelRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: labelName
    width: 70
    text-align: right
    font: verdana-11px-rounded

  TextEdit
    id: labelField
    width: 100
    height: 20

  Button
    id: addLabel
    text: +
    width: 20
    height: 20
]], trainerPanel)

  trainerLabelRow.labelName:setText('Ir Treinar:')
  trainerLabelRow.labelField:setText(trainerCfg.labelTrainer or 'irtreinar')
  setBilingualTooltip(trainerLabelRow.labelField, 'Label usada quando stamina estiver abaixo do valor.', 'Label used when stamina is below configured value.')
  trainerLabelRow.labelField.onTextChange = function(_, text)
    trainerCfg.labelTrainer = text
  end
  trainerLabelRow.addLabel.onClick = function()
    local label = trainerLabelRow.labelField and trainerLabelRow.labelField:getText() or trainerCfg.labelTrainer or ''
    addLabelToCaveBot(label)
  end
  setBilingualTooltip(trainerLabelRow.addLabel, 'Adicionar label de ir treinar no CaveBot.', 'Add go-train label to CaveBot.')

  local trainerContinueRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: labelName
    width: 70
    text-align: right
    font: verdana-11px-rounded

  TextEdit
    id: labelField
    width: 100
    height: 20

  Button
    id: addLabel
    text: +
    width: 20
    height: 20
]], trainerPanel)

  trainerContinueRow.labelName:setText('Continuar:')
  trainerContinueRow.labelField:setText(trainerCfg.labelContinuar or 'aindanaotreinar')
  setBilingualTooltip(trainerContinueRow.labelField, 'Label usada quando stamina estiver OK.', 'Label used when stamina is OK.')
  trainerContinueRow.labelField.onTextChange = function(_, text)
    trainerCfg.labelContinuar = text
  end
  trainerContinueRow.addLabel.onClick = function()
    local label = trainerContinueRow.labelField and trainerContinueRow.labelField:getText() or trainerCfg.labelContinuar or ''
    addLabelToCaveBot(label)
  end
  setBilingualTooltip(trainerContinueRow.addLabel, 'Adicionar label de continuar no CaveBot.', 'Add continue label to CaveBot.')

  local trainerExitRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 4

  Label
    id: labelName
    width: 70
    text-align: right
    font: verdana-11px-rounded

  TextEdit
    id: labelField
    width: 100
    height: 20

  Button
    id: addLabel
    text: +
    width: 20
    height: 20
]], trainerPanel)

  trainerExitRow.labelName:setText('Sair:')
  trainerExitRow.labelField:setText(trainerCfg.labelSairTrainer or 'sairdotrainer')
  setBilingualTooltip(
    trainerExitRow.labelField,
    'Label usada pelo macro para sair do trainer.',
    'Label used by the macro to leave trainer.'
  )
  trainerExitRow.labelField.onTextChange = function(_, text)
    trainerCfg.labelSairTrainer = text
    trainerCfg.exitTriggered = false
  end
  trainerExitRow.addLabel.onClick = function()
    local label = trainerExitRow.labelField and trainerExitRow.labelField:getText() or trainerCfg.labelSairTrainer or ''
    addLabelToCaveBot(label)
  end
  setBilingualTooltip(trainerExitRow.addLabel, 'Adicionar label de sair do trainer no CaveBot.', 'Add leave-trainer label to CaveBot.')

  ensurePanelHeight(trainerPanel)
  refreshLayout(trainerPanel)

  -- Configurar botoes
  local saveBtn = functionsWindow.buttonPanel.saveBtn
  local helpBtn = functionsWindow.buttonPanel.helpBtn
  local closeBtn = functionsWindow.buttonPanel.closeBtn

  local function flushEditorBindings(rootWidgetRef)
    local function walk(widget)
      if not widget then
        return
      end
      if widget.isDestroyed and widget:isDestroyed() then
        return
      end

      if widget.getText and type(widget.onTextChange) == "function" then
        local okText, textValue = pcall(function()
          return widget:getText()
        end)
        if okText then
          pcall(widget.onTextChange, widget, textValue)
        end
      end

      if widget.getValue and type(widget.onValueChange) == "function" then
        if widget.getText and widget.setValue then
          local okRaw, rawText = pcall(function()
            return widget:getText()
          end)
          if okRaw then
            local parsed = tonumber(rawText)
            if parsed then
              pcall(widget.setValue, widget, parsed)
            end
          end
        end
        local okValue, numberValue = pcall(function()
          return widget:getValue()
        end)
        if okValue then
          pcall(widget.onValueChange, widget, numberValue)
        end
      end

      if widget.getItemId and type(widget.onItemChange) == "function" then
        pcall(widget.onItemChange, widget)
      end

      if widget.getChildren then
        local children = widget:getChildren() or {}
        for _, child in ipairs(children) do
          walk(child)
        end
      end
    end

    walk(rootWidgetRef)
  end

  if saveBtn then
    setBilingualTooltip(
      saveBtn,
      "Forca commit dos campos editados e sincroniza tudo no storage imediatamente.",
      "Forces pending editor commits and synchronizes everything to storage immediately."
    )
    saveBtn.onClick = function()
      flushEditorBindings(functionsWindow and functionsWindow.contentPanel or functionsWindow)

      ensureStaminaStatsList()
      syncStaminaLegacyFromList()
      ensureCapStatsList()
      syncCapLegacyFromList()
      ensureLevelStatsList()
      syncLevelLegacyFromList()
      ensureTimeStatsList()
      syncTimeLegacyFromList()

      ensureTaskerConfig()
      local trainerCfg = ensureTrainerConfig()
      storage.cavebotChecks.trainerMacroEnabled = trainerCfg.macroEnabled and true or false

      sanitizeSupplyItems({ keepPlaceholders = true })
      sanitizeBuySuppliesItems({ keepPlaceholders = true }, storage.buySupplies)
      sanitizeBuySuppliesItems({ keepPlaceholders = true }, storage.cavebotChecks.buySupply)
      sanitizeBuySuppliesItems({ keepPlaceholders = true }, storage.cavebotChecks.buySupply2)
      sanitizeBuySuppliesItems({ keepPlaceholders = true }, storage.cavebotChecks.buySupply3)
      sanitizeBuySuppliesItems({ keepPlaceholders = true }, storage.cavebotChecks.buySupply4)

      if CaveBot and CaveBot.save then
        pcall(CaveBot.save)
      end

      print('[CaveBot Functions] Configuracoes sincronizadas e salvas no storage!')
    end
  end

  if helpBtn then
    setBilingualTooltip(
      helpBtn,
      "Abre o tutorial completo do CaveBOT Functions.",
      "Open the full CaveBOT Functions tutorial."
    )
    helpBtn.onClick = function()
      openFunctionsHelpWindow()
      local helpUi = refreshFunctionsHelpWindow()
      if helpUi then
        setBilingualTooltip(
          helpUi.textLabel,
          "Tutorial completo dos checkers, supply, tasker e trainer.",
          "Complete tutorial for checkers, supply, tasker, and trainer."
        )
        setBilingualTooltip(
          helpUi.closeButton,
          "Fecha a janela de ajuda.",
          "Close the help window."
        )
      end
    end
  end

  if closeBtn then
    setBilingualTooltip(
      closeBtn,
      "Fecha a janela de configuracao do CaveBOT Functions.",
      "Close the CaveBOT Functions setup window."
    )
    closeBtn.onClick = function()
      functionsWindow:hide()
    end
  end

  scheduleBasicsColumnsLayoutRefresh()
  functionsWindow._buildComplete = true
  functionsWindow:show()
end

-- Botao na aba Main
local caveFunctionsPanel = setupUI([[
Panel
  height: 20
  margin-top: 3

  Button
    id: setupBtn
    text: CaveBOT
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 18
    font: verdana-11px-rounded
]])

caveFunctionsPanel.setupBtn.onClick = function()
  openFunctionsWindow()
end

caveFunctionsPanel.setupBtn:setTooltip("PT: Abre a configuracao de checkers do CaveBot: cap, stamina, level, time, supply, tasker e trainer.\nEN: Opens the CaveBot checker setup: cap, stamina, level, time, supply, tasker and trainer.")


-- =====================================================================
-- IMBUEMENTS (movido de imbuements.lua)
-- =====================================================================
-- Imbuements por tipo de equipamento
local IMBUEMENTS_BY_SLOT = {
    helmet = {
        -- Mana Leech
        { group = "Void", description = "Mana Leech" },
        -- Skills
        { group = "Epiphany", description = "Magic Level" },
        { group = "Bash", description = "Club Skill" },
        { group = "Chop", description = "Axe Skill" },
        { group = "Slash", description = "Sword Skill" },
        { group = "Precision", description = "Distance Skill" },
        -- Protecoes elementais
        { group = "Lich Shroud", description = "Death Protection" },
        { group = "Snake Skin", description = "Earth Protection" },
        { group = "Demon Presence", description = "Holy Protection" },
        { group = "Dragon Hide", description = "Fire Protection" },
        { group = "Quara Scale", description = "Ice Protection" },
        { group = "Cloud Fabric", description = "Energy Protection" },
    },
    armor = {
        -- Life Leech
        { group = "Vampirism", description = "Life Leech" },
        -- Protecoes elementais
        { group = "Lich Shroud", description = "Death Protection" },
        { group = "Snake Skin", description = "Earth Protection" },
        { group = "Demon Presence", description = "Holy Protection" },
        { group = "Dragon Hide", description = "Fire Protection" },
        { group = "Quara Scale", description = "Ice Protection" },
        { group = "Cloud Fabric", description = "Energy Protection" },
        -- Protecao fisica
        { group = "Hardening", description = "Physical Protection" },
    },
    legs = {},
    boots = {
        -- Protecoes elementais
        { group = "Lich Shroud", description = "Death Protection" },
        { group = "Snake Skin", description = "Earth Protection" },
        { group = "Demon Presence", description = "Holy Protection" },
        { group = "Dragon Hide", description = "Fire Protection" },
        { group = "Quara Scale", description = "Ice Protection" },
        { group = "Cloud Fabric", description = "Energy Protection" },
        -- Protecao fisica
        { group = "Hardening", description = "Physical Protection" },
    },
    weapon = {
        -- Mana/Life Leech
        { group = "Void", description = "Mana Leech" },
        { group = "Vampirism", description = "Life Leech" },
        -- Critical
        { group = "Strike", description = "Critical Hit" },
        -- Skills
        { group = "Epiphany", description = "Magic Level" },
        { group = "Bash", description = "Club Skill" },
        { group = "Chop", description = "Axe Skill" },
        { group = "Slash", description = "Sword Skill" },
        { group = "Precision", description = "Distance Skill" },
        -- Protecoes elementais
        { group = "Lich Shroud", description = "Death Protection" },
        { group = "Snake Skin", description = "Earth Protection" },
        { group = "Demon Presence", description = "Holy Protection" },
        { group = "Dragon Hide", description = "Fire Protection" },
        { group = "Quara Scale", description = "Ice Protection" },
        { group = "Cloud Fabric", description = "Energy Protection" },
    },
    shield = {
        -- Shielding
        { group = "Blockade", description = "Shielding +4" },
        -- Protecoes elementais
        { group = "Lich Shroud", description = "Death Protection +15%" },
        { group = "Snake Skin", description = "Earth Protection +15%" },
        { group = "Demon Presence", description = "Holy Protection +15%" },
        { group = "Dragon Hide", description = "Fire Protection +15%" },
        { group = "Quara Scale", description = "Ice Protection +15%" },
        { group = "Cloud Fabric", description = "Energy Protection +15%" },
    },
    ring = {},
    amulet = {},
}

-- Lista completa para referencia interna
local ALL_IMBUEMENTS = {
    "Void", "Vampirism", "Strike", "Elethricity", "Reap", "Scorch", "Venom", "Frost",
    "Lich Shroud", "Snake Skin", "Demon Presence", "Dragon Hide", "Quara Scale", "Cloud Fabric",
    "Epiphany", "Swiftness", "Vibrancy", "Featherweight", "Bash", "Chop", "Slash", "Precision", "Blockade"
}

-- IDs dos shrines de imbuement
local SHRINES = {25060, 25061, 25182, 25183}

-- Slots de equipamento
local EQUIPMENT_SLOTS = {
    { slot = "helmet", name = "Helmet", getFunc = getHead },
    { slot = "armor", name = "Armor", getFunc = getBody },
    { slot = "legs", name = "Legs", getFunc = getLeg },
    { slot = "boots", name = "Boots", getFunc = getFeet },
    { slot = "weapon", name = "Weapon", getFunc = getLeft },
    { slot = "shield", name = "Shield/Quiver", getFunc = getRight },
    { slot = "ring", name = "Ring", getFunc = getFinger },
    { slot = "amulet", name = "Amulet", getFunc = getNeck },
}

-- ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????
-- ESTADO DO SISTEMA
-- ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????
local imbuementSystem = {
    isProcessing = false,
    currentItem = nil,
    currentSlotIndex = 0,
    pendingImbuements = {},
    windowData = nil,
    lastAction = 0,
    waitingWindow = false,
    shrine = nil
}

-- ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????
-- FUN????ES HELPER
-- ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????

-- Helper para converter ID para string (JSON nao aceita chaves numericas)
local function itemKey(id)
    return tostring(id)
end

-- Identifica tier do nome do imbuement
local function getTierFromName(name)
    if not name then return 3 end
    if name:find("Powerful") then return 3
    elseif name:find("Intricate") then return 2
    elseif name:find("Basic") then return 1
    end
    return 3 -- default se nao encontrar
end

-- Converte tier (n??mero) para nome do tier
local function tierToName(tier)
    tier = tonumber(tier) or 3
    if tier == 1 then return "Basic"
    elseif tier == 2 then return "Intricate"
    elseif tier == 3 then return "Powerful"
    end
    return "Powerful"
end

-- Converte nome do tier para tier (n??mero)
local function tierNameToNumber(tierName)
    if tierName == "Basic" then return 1
    elseif tierName == "Intricate" then return 2
    elseif tierName == "Powerful" then return 3
    end
    return 3 -- default
end

-- Migra configura????o antiga (string) para novo formato (objeto com group e tier)
local function migrateSlotConfig(slotConfig)
    if type(slotConfig) == "string" then
        -- Formato antigo: apenas string com group
        return { group = slotConfig, tier = 3 }
    elseif type(slotConfig) == "table" and slotConfig.group then
        -- J?? est?? no formato novo
        return slotConfig
    end
    return nil
end

-- Migra todas as configura????es de um item para o novo formato
local function migrateItemConfig(itemConfig)
    if not itemConfig then return end
    local migrated = false
    for slotKey, slotValue in pairs(itemConfig) do
        if slotKey:match("^slot%d+$") then
            local newValue = migrateSlotConfig(slotValue)
            if newValue then
                itemConfig[slotKey] = newValue
                migrated = true
            end
        end
    end
    return migrated
end

-- ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????
-- INICIALIZA????O DO STORAGE
-- ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????
local function initStorage()
    if type(storage.imbuementConfig) ~= "table" then
        storage.imbuementConfig = {
            useProtection = true,
            items = {}
            -- Estrutura: items["itemId"] = { slot1 = { group = "Void", tier = 3 }, slot2 = { group = "Vampirism", tier = 3 }, slot3 = { group = "Strike", tier = 3 } }
            -- Chaves sao strings para compatibilidade com JSON
        }
    end

    if type(storage.imbuementConfig.items) ~= "table" then
        storage.imbuementConfig.items = {}
    end

    -- Migra configura????es antigas para novo formato
    for itemIdStr, itemConfig in pairs(storage.imbuementConfig.items) do
        if itemConfig and type(itemConfig) == "table" then
            migrateItemConfig(itemConfig)
        end
    end

    return storage.imbuementConfig
end

-- ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????
-- FUN????ES AUXILIARES
-- ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????

-- Encontra shrine pr??ximo
local function findShrine()
    if not g_map or not g_map.getTiles or type(posz) ~= "function" then
        return nil, nil
    end
    for _, tile in ipairs(g_map.getTiles(posz()) or {}) do
        for _, item in ipairs(tile:getItems() or {}) do
            if table.find(SHRINES, item:getId()) then
                return item, tile:getPosition()
            end
        end
    end
    return nil, nil
end

-- Obt??m item equipado por slot
local function getEquippedItem(slotName)
    for _, slotInfo in ipairs(EQUIPMENT_SLOTS) do
        if slotInfo.slot == slotName then
            return slotInfo.getFunc()
        end
    end
    return nil
end

-- Encontra imbuement por grupo/nome e tier nos dados da janela
local function findImbuementByGroup(windowImbuements, groupConfig, tier)
    if not windowImbuements then return nil end

    local groupName = groupConfig
    if type(groupConfig) == "table" then
        groupName = groupConfig.group
        tier = groupConfig.tier or tier
    end

    if not groupName then
        return nil
    end

    tier = tier or 3 -- default tier 3 (Powerful) se nao especificado

    -- Alias para grupos (UI guarda "Void"/"Vampirism"/etc, janela usa "Mana Leech"/"Hit Points Leech"/etc)
    local GROUP_ALIAS = {
        ["Void"] = "Mana Leech",
        ["Vampirism"] = "Hit Points Leech",
        ["Strike"] = "Critical",
        ["Precision"] = "Skillboost (Distance)",
        ["Blockade"] = "Skillboost (Shielding)",
        ["Punch"] = "Skillboost (Fist)",
        ["Bash"] = "Skillboost (Club)",
        ["Chop"] = "Skillboost (Axe)",
        ["Slash"] = "Skillboost (Sword)",
        ["Scorch"] = "Elemental Damage (Fire)",
        ["Venom"] = "Elemental Damage (Earth)",
        ["Frost"] = "Elemental Damage (Ice)",
        ["Electrify"] = "Elemental Damage (Energy)",
        ["Reap"] = "Elemental Damage (Death)",
    }

    local targetGroup = GROUP_ALIAS[groupName] or groupName

    -- Debug: mostra todos os imbuements disponiveis
    print("[imbuement] Procurando grupo: " .. tostring(groupName) .. " (alias: " .. tostring(targetGroup) .. "), tier: " .. tier)
    for _, imbue in ipairs(windowImbuements) do
        print("[imbuement] Disponivel - grupo: " .. tostring(imbue.group) .. ", nome: " .. tostring(imbue.name))

        -- Match por grupo (com alias) ou por nome contendo o grupo original
        local groupMatch = (imbue.group and imbue.group == targetGroup)
        local nameMatch = (imbue.name and imbue.name:find(groupName, 1, true))

        if groupMatch or nameMatch then
            local imbueTier = getTierFromName(imbue.name)
            if imbueTier == tier then
                print("[imbuement] Encontrado (tier " .. tier .. "): " .. imbue.name)
                return imbue
            end
        end
    end

    print("[imbuement] Imbuement nao encontrado: grupo=" .. tostring(groupName) .. " (alias: " .. tostring(targetGroup) .. "), tier=" .. tier)
    return nil
end



-- ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????
-- UI DE CONFIGURA????O
-- ??????????????????????????????????????????????????????????????????????????????????????????????????????????????????

-- Limpa UI antiga ao recarregar
if imbuementWindow then
    imbuementWindow:destroy()
    imbuementWindow = nil
end

local imbuementWindow = nil
local imbuementUILoaded = false

local function createImbuementUI()
    -- Destroi janela antiga se existir
    if imbuementWindow then
        imbuementWindow:destroy()
        imbuementWindow = nil
    end

    local cfg = initStorage()

    -- For??a recarregar UI sempre (remova o if para sempre recriar)
    imbuementUILoaded = false
    if not imbuementUILoaded then
        g_ui.loadUIFromString([[
ImbuementMainWindow < MainWindow
  !text: tr('Imbuement System - Setup by Kelus Scripts')
  size: 424 395
  visible: false
  @onEscape: self:hide()

  VerticalScrollBar
    id: contentScroll
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.bottom: closeBtn.top
    margin-top: 10
    margin-right: 6
    step: 28
    pixels-scroll: true

  ScrollablePanel
    id: content
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: contentScroll.left
    anchors.bottom: closeBtn.top
    margin-top: 10
    margin-left: 10
    margin-right: 5
    padding: 5
    image-source: /images/ui/panel_flat
    image-border: 5
    vertical-scrollbar: contentScroll
    layout:
      type: verticalBox
      spacing: 5

  Button
    id: closeBtn
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 90 61
    margin-right: 6
]])
        imbuementUILoaded = true
    end

    imbuementWindow = g_ui.createWidget('ImbuementMainWindow', g_ui.getRootWidget())
    local contentRoot = imbuementWindow.content
    local content = contentRoot
    local closeBtn = imbuementWindow.closeBtn

    local function ensurePanelHeight(panel)
        if not panel or not panel.getChildren or not panel.setHeight then
            return
        end
        local total = 0
        for _, child in ipairs(panel:getChildren() or {}) do
            if child.isVisible and not child:isVisible() then
                -- ignora filhos ocultos
            elseif child.getHeight then
                total = total + (child:getHeight() or 0)
            end
        end
        if total > 0 then
            panel:setHeight(total + 4)
        end
    end

    local function refreshLayout(widget)
        local current = widget
        for i = 1, 4 do
            if not current then
                break
            end
            if current.updateLayout then
                current:updateLayout()
            end
            if i == 1 and current.fitChildren then
                current:fitChildren()
            end
            if i == 1 and current.resizeToFitChildren then
                current:resizeToFitChildren()
            end
            current = current:getParent()
        end
    end

    local headerRow = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4
  fit-children: true

  Label
    id: title
    font: verdana-11px-rounded
    width: 190
    text-align: left
    text-auto-resize: false
    text: Imbuement Setup

  Button
    id: toggleBtn
    text: -
    width: 20
    height: 20
]], contentRoot)
    headerRow.title:setColor('#FFFFFF')

    local settingsPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 5
  fit-children: true
  margin-top: 4
  margin-bottom: 8
]], contentRoot)
    settingsPanel:setVisible(true)

    local function toggleSettings()
        local visible = not settingsPanel:isVisible()
        settingsPanel:setVisible(visible)
        headerRow.toggleBtn:setText(visible and '-' or '+')
        if visible then
            ensurePanelHeight(settingsPanel)
            refreshLayout(settingsPanel)
            refreshLayout(contentRoot)
        end
    end
    headerRow.toggleBtn.onClick = function()
        toggleSettings()
    end

    content = settingsPanel

    -- Botao fechar
    closeBtn.onClick = function()
        imbuementWindow:hide()
    end

    -- Titulo
    local titleLabel = g_ui.createWidget('Label', content)
    titleLabel:setText("Configure seus imbuements:")
    titleLabel:setFont('verdana-11px-rounded')
    titleLabel:setColor('#87CEEB')
    titleLabel:setHeight(22)
    titleLabel:setTextAlign(AlignCenter)

    -- Cria secao para cada slot de equipamento
    for _, slotInfo in ipairs(EQUIPMENT_SLOTS) do
        local item = slotInfo.getFunc()
        if item then
            local itemId = item:getId()
            local itemIdStr = itemKey(itemId) -- Converte para string

            -- Inicializa config do item se nao existir
            if not cfg.items[itemIdStr] then
                cfg.items[itemIdStr] = {}
            end

            -- Separador
            local sep = g_ui.createWidget('Panel', content)
            sep:setHeight(1)
            sep:setBackgroundColor('#1a1a2e')

            -- Label do slot com nome do equipamento
            local slotLabel = g_ui.createWidget('Label', content)
            slotLabel:setText(slotInfo.name .. " (ID: " .. itemId .. ")")
            slotLabel:setFont('verdana-11px-rounded')
            slotLabel:setColor('#87CEEB')
            slotLabel:setHeight(20)

            -- Weapon tem 3 slots, outros tem 2
            local maxSlots = (slotInfo.slot == "weapon") and 3 or 2

            -- Pega imbuements disponiveis para este slot
            local availableImbues = IMBUEMENTS_BY_SLOT[slotInfo.slot] or {}

            -- Se nao tem imbuements disponiveis, pula
            if #availableImbues == 0 then
                local noImbueLabel = g_ui.createWidget('Label', content)
                noImbueLabel:setText("  (Sem imbuements disponiveis)")
                noImbueLabel:setFont('verdana-11px-rounded')
                noImbueLabel:setColor('#666666')
                noImbueLabel:setHeight(18)
            else
                for i = 1, maxSlots do
                    local slotKey = "slot" .. i

                    -- Migra config se necess??rio
                    local slotConfig = cfg.items[itemIdStr][slotKey]
                    if slotConfig then
                        local migrated = migrateSlotConfig(slotConfig)
                        if migrated then
                            cfg.items[itemIdStr][slotKey] = migrated
                            slotConfig = migrated
                        end
                    end

                    -- Painel horizontal para tier e imbuement usando horizontalBox layout
                    local slotPanel = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 5
]], content)

                    -- ComboBox de Tier (com nomes reais)
                    local tierCombo = g_ui.createWidget('ComboBox', slotPanel)
                    tierCombo:setHeight(24)
                    tierCombo:setWidth(80)
                    tierCombo:setFont('verdana-11px-rounded')
                    tierCombo:addOption("Basic")
                    tierCombo:addOption("Intricate")
                    tierCombo:addOption("Powerful")

                    -- Seleciona tier atual ou default Powerful (3)
                    local currentTier = 3
                    if slotConfig and type(slotConfig) == "table" and slotConfig.tier then
                        currentTier = slotConfig.tier
                    elseif slotConfig and type(slotConfig) == "string" then
                        currentTier = 3 -- migrado acima
                    end
                    -- ComboBox de Imbuement - largura ajustada para dar espa??o ao tier combo maior
                    local combo = g_ui.createWidget('ComboBox', slotPanel)
                    combo:setHeight(24)
                    combo:setWidth(200)
                    combo:setId("imbueCombo")
                    combo:setFont('verdana-11px-rounded')

                    -- Adiciona opcoes filtradas por slot (apenas descricao, sem grupo)
                    combo:addOption("Slot " .. i .. ": (Nenhum)")
                    for _, imbue in ipairs(availableImbues) do
                        combo:addOption("Slot " .. i .. ": " .. imbue.description)
                    end

                    -- Seleciona valor atual
                    local currentGroup = nil
                    if slotConfig then
                        if type(slotConfig) == "table" and slotConfig.group then
                            currentGroup = slotConfig.group
                        elseif type(slotConfig) == "string" then
                            currentGroup = slotConfig
                        end
                    end

                    -- Callback de mudanca (closure correta)
                    local capturedItemIdStr = itemIdStr
                    local capturedSlotKey = slotKey
                    local capturedImbues = availableImbues

                    local function updateSlotConfig()
                        -- Verifica se os combos t??m op????o selecionada
                        local tierOption = tierCombo:getCurrentOption()
                        local comboOption = combo:getCurrentOption()

                        if not tierOption or not comboOption then
                            return -- Evita erro se combos n??o est??o inicializados
                        end

                        local tierText = tierOption.text
                        local tier = tierNameToNumber(tierText)
                        local text = comboOption.text

                        if text:find("%(Nenhum%)") then
                            cfg.items[capturedItemIdStr][capturedSlotKey] = nil
                        else
                            -- Busca pelo imbuement que tem essa descricao
                            local found = false
                            for _, imbue in ipairs(capturedImbues) do
                                if text:find(imbue.description, 1, true) then
                                    cfg.items[capturedItemIdStr][capturedSlotKey] = {
                                        group = imbue.group,
                                        tier = tier
                                    }
                                    found = true
                                    break
                                end
                            end

                            -- Se n??o encontrou match, n??o atualiza (mant??m configura????o anterior se existir)
                            if not found then
                                -- N??o faz nada, mant??m configura????o atual
                            end
                        end
                    end

                    -- Configura valores iniciais SEM disparar callbacks (usando dontSignal = true)
                    tierCombo:setCurrentOption(tierToName(currentTier), true)

                    if currentGroup then
                        for idx, imbue in ipairs(availableImbues) do
                            if imbue.group == currentGroup then
                                combo:setCurrentOption("Slot " .. i .. ": " .. imbue.description, true)
                                break
                            end
                        end
                    end

                    -- Agora sim, define os callbacks para mudan??as futuras
                    tierCombo.onOptionChange = updateSlotConfig
                    combo.onOptionChange = updateSlotConfig
                end
            end
        end
    end

    -- Separador final
    local finalSep = g_ui.createWidget('Panel', content)
    finalSep:setHeight(1)
    finalSep:setBackgroundColor('#1a1a2e')

    -- Info final
    local infoLabel = g_ui.createWidget('Label', content)
    infoLabel:setText("=== DICA ===")
    infoLabel:setFont('verdana-11px-rounded')
    infoLabel:setColor('#87CEEB')
    infoLabel:setHeight(20)

    local infoLabel2 = g_ui.createWidget('Label', content)
    infoLabel2:setText("Use 'checkerImbuement' no CaveBot")
    infoLabel2:setFont('verdana-11px-rounded')
    infoLabel2:setColor('#FFFFFF')
    infoLabel2:setHeight(18)

    local infoLabel3 = g_ui.createWidget('Label', content)
    infoLabel3:setText("ao lado do shrine de imbuement")
    infoLabel3:setFont('verdana-11px-rounded')
    infoLabel3:setColor('#FFFFFF')
    infoLabel3:setHeight(18)

    ensurePanelHeight(settingsPanel)
    refreshLayout(settingsPanel)
    refreshLayout(contentRoot)
    imbuementWindow:show()
    imbuementWindow:raise()
end

local function buildImbuementSetup(parent)
    if not parent then
        return
    end

    local content = parent
    if content.getChildById then
        content = content:getChildById('panelContent') or content
    end
    if content.destroyChildren then
        content:destroyChildren()
    end

    local cfg = initStorage()

    local titleLabel = g_ui.createWidget('Label', content)
    titleLabel:setText("Configure seus imbuements:")
    titleLabel:setFont('verdana-11px-rounded')
    titleLabel:setColor('#87CEEB')
    titleLabel:setHeight(22)
    titleLabel:setTextAlign(AlignCenter)

    for _, slotInfo in ipairs(EQUIPMENT_SLOTS) do
        local item = slotInfo.getFunc()
        if item then
            local itemId = item:getId()
            local itemIdStr = itemKey(itemId)

            if not cfg.items[itemIdStr] then
                cfg.items[itemIdStr] = {}
            end

            local sep = g_ui.createWidget('Panel', content)
            sep:setHeight(1)
            sep:setBackgroundColor('#1a1a2e')

            local slotLabel = g_ui.createWidget('Label', content)
            slotLabel:setText(slotInfo.name .. " (ID: " .. itemId .. ")")
            slotLabel:setFont('verdana-11px-rounded')
            slotLabel:setColor('#87CEEB')
            slotLabel:setHeight(20)

            local maxSlots = (slotInfo.slot == "weapon") and 3 or 2
            local availableImbues = IMBUEMENTS_BY_SLOT[slotInfo.slot] or {}

            if #availableImbues == 0 then
                local noImbueLabel = g_ui.createWidget('Label', content)
                noImbueLabel:setText("  (Sem imbuements disponiveis)")
                noImbueLabel:setFont('verdana-11px-rounded')
                noImbueLabel:setColor('#666666')
                noImbueLabel:setHeight(18)
            else
                for i = 1, maxSlots do
                    local slotKey = "slot" .. i
                    local slotConfig = cfg.items[itemIdStr][slotKey]
                    if slotConfig then
                        local migrated = migrateSlotConfig(slotConfig)
                        if migrated then
                            cfg.items[itemIdStr][slotKey] = migrated
                            slotConfig = migrated
                        end
                    end

                    local slotPanel = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 5
]], content)

                    local tierCombo = g_ui.createWidget('ComboBox', slotPanel)
                    tierCombo:setHeight(24)
                    tierCombo:setWidth(80)
                    tierCombo:setFont('verdana-11px-rounded')
                    tierCombo:addOption("Basic")
                    tierCombo:addOption("Intricate")
                    tierCombo:addOption("Powerful")

                    local currentTier = 3
                    if slotConfig and type(slotConfig) == "table" and slotConfig.tier then
                        currentTier = slotConfig.tier
                    elseif slotConfig and type(slotConfig) == "string" then
                        currentTier = 3
                    end

                    local combo = g_ui.createWidget('ComboBox', slotPanel)
                    combo:setHeight(24)
                    combo:setWidth(200)
                    combo:setId("imbueCombo")
                    combo:setFont('verdana-11px-rounded')

                    combo:addOption("Slot " .. i .. ": (Nenhum)")
                    for _, imbue in ipairs(availableImbues) do
                        combo:addOption("Slot " .. i .. ": " .. imbue.description)
                    end

                    local currentGroup = nil
                    if slotConfig then
                        if type(slotConfig) == "table" and slotConfig.group then
                            currentGroup = slotConfig.group
                        elseif type(slotConfig) == "string" then
                            currentGroup = slotConfig
                        end
                    end

                    local capturedItemIdStr = itemIdStr
                    local capturedSlotKey = slotKey
                    local capturedImbues = availableImbues

                    local function updateSlotConfig()
                        local tierOption = tierCombo:getCurrentOption()
                        local comboOption = combo:getCurrentOption()
                        if not tierOption or not comboOption then
                            return
                        end
                        local tierText = tierOption.text
                        local tier = tierNameToNumber(tierText)
                        local text = comboOption.text
                        if text:find("%(Nenhum%)") then
                            cfg.items[capturedItemIdStr][capturedSlotKey] = nil
                        else
                            local found = false
                            for _, imbue in ipairs(capturedImbues) do
                                if text:find(imbue.description, 1, true) then
                                    cfg.items[capturedItemIdStr][capturedSlotKey] = {
                                        group = imbue.group,
                                        tier = tier
                                    }
                                    found = true
                                    break
                                end
                            end
                            if not found then
                                -- Mantem configuracao anterior.
                            end
                        end
                    end

                    tierCombo:setCurrentOption(tierToName(currentTier), true)
                    if currentGroup then
                        for _, imbue in ipairs(availableImbues) do
                            if imbue.group == currentGroup then
                                combo:setCurrentOption("Slot " .. i .. ": " .. imbue.description, true)
                                break
                            end
                        end
                    end

                    tierCombo.onOptionChange = updateSlotConfig
                    combo.onOptionChange = updateSlotConfig
                end
            end
        end
    end

    local finalSep = g_ui.createWidget('Panel', content)
    finalSep:setHeight(1)
    finalSep:setBackgroundColor('#1a1a2e')

    local infoLabel = g_ui.createWidget('Label', content)
    infoLabel:setText("=== DICA ===")
    infoLabel:setFont('verdana-11px-rounded')
    infoLabel:setColor('#87CEEB')
    infoLabel:setHeight(20)

    local infoLabel2 = g_ui.createWidget('Label', content)
    infoLabel2:setText("Use 'checkerImbuement' no CaveBot")
    infoLabel2:setFont('verdana-11px-rounded')
    infoLabel2:setColor('#FFFFFF')
    infoLabel2:setHeight(18)

    local infoLabel3 = g_ui.createWidget('Label', content)
    infoLabel3:setText("ao lado do shrine de imbuement")
    infoLabel3:setFont('verdana-11px-rounded')
    infoLabel3:setColor('#FFFFFF')
    infoLabel3:setHeight(18)
end

ImbuementSetup = ImbuementSetup or {}
ImbuementSetup.open = function()
    createImbuementUI()
end
ImbuementSetup.build = function(parent)
    buildImbuementSetup(parent)
end

-- ==========================================================
-- CAVEBOT: checkerImbuement
-- ==========================================================
local checkerState = {
    itemsToProcess = {},
    currentIndex = 1,
    waitingWindow = false,
    waitingApply = false,
    lastAction = 0
}

local function resetCheckerState()
    checkerState.itemsToProcess = {}
    checkerState.currentIndex = 1
    checkerState.waitingWindow = false
    checkerState.waitingApply = false
    checkerState.lastAction = 0
end

local function processImbuementWindow(itemId, slots, activeSlots, imbuements, needItems)
    if not checkerState.waitingWindow then return end

    checkerState.waitingWindow = false
    checkerState.waitingApply = true

    local cfg = initStorage()
    local itemIdStr = itemKey(itemId)
    local itemConfig = cfg.items[itemIdStr]

    if not itemConfig then
        print("[imbuement] Item nao configurado: " .. itemIdStr)
        checkerState.waitingApply = false
        schedule(500, function() g_game.closeImbuingWindow() end)
        return
    end

    print("[imbuement] Janela aberta - Item: " .. itemId .. ", Slots: " .. slots)

    local toApply = {}
    for slotIdx = 0, slots - 1 do
        local slotKey = "slot" .. (slotIdx + 1)
        local configured = itemConfig[slotKey]
        local hasActive = activeSlots[slotIdx] ~= nil

        if configured and not hasActive then
            local groupName = configured
            local tier = nil
            if type(configured) == "table" then
                groupName = configured.group
                tier = configured.tier
            end

            local imbueData = findImbuementByGroup(imbuements, groupName, tier)
            if imbueData then
                table.insert(toApply, { slotIdx = slotIdx, imbue = imbueData })
            else
                print("[imbuement] Imbuement nao disponivel: " .. tostring(groupName))
            end
        elseif hasActive then
            local activeInfo = activeSlots[slotIdx]
            if activeInfo and activeInfo[1] then
                print("[imbuement] Slot " .. (slotIdx + 1) .. " ja ativo: " .. activeInfo[1].name)
            end
        end
    end

    local applyIndex = 1
    local function applyNext()
        if applyIndex > #toApply then
            checkerState.waitingApply = false
            schedule(1000, function() g_game.closeImbuingWindow() end)
            return
        end

        local data = toApply[applyIndex]
        print("[imbuement] Aplicando " .. data.imbue.name .. " no slot " .. (data.slotIdx + 1))
        g_game.applyImbuement(data.slotIdx, data.imbue.id, true)

        applyIndex = applyIndex + 1
        schedule(2500, applyNext)
    end

    if #toApply > 0 then
        schedule(500, applyNext)
    else
        print("[imbuement] Nenhum imbuement para aplicar neste item")
        checkerState.waitingApply = false
        schedule(500, function() g_game.closeImbuingWindow() end)
    end
end

onImbuementWindow(processImbuementWindow)

function checkerImbuement()
    local cfg = initStorage()

    local currentTime = now or (g_clock and g_clock.millis() or 0)
    if currentTime - checkerState.lastAction < 1000 then
        return "retry"
    end

    if checkerState.waitingWindow or checkerState.waitingApply then
        return "retry"
    end

    if #checkerState.itemsToProcess == 0 then
        local configCount = 0
        for itemIdStr, itemConfig in pairs(cfg.items) do
            local hasConfig = itemConfig.slot1 or itemConfig.slot2 or itemConfig.slot3
            if hasConfig then
                configCount = configCount + 1
                local itemIdNum = tonumber(itemIdStr)
                local item = findItem(itemIdNum)
                if item then
                    table.insert(checkerState.itemsToProcess, { id = itemIdNum, item = item })
                else
                    for _, slotInfo in ipairs(EQUIPMENT_SLOTS) do
                        local equipped = slotInfo.getFunc()
                        if equipped and equipped:getId() == itemIdNum then
                            table.insert(checkerState.itemsToProcess, { id = itemIdNum, item = equipped })
                            break
                        end
                    end
                end
            end
        end
        checkerState.currentIndex = 1

        if configCount == 0 then
            print("[imbuement] Nenhum item configurado no storage")
            resetCheckerState()
            return true
        end

        if #checkerState.itemsToProcess == 0 then
            print("[imbuement] Itens configurados mas nao encontrados no inventario/equipados")
            resetCheckerState()
            return true
        end

        print("[imbuement] " .. #checkerState.itemsToProcess .. " item(s) para processar")
    end

    if checkerState.currentIndex > #checkerState.itemsToProcess then
        print("[imbuement] Todos os itens processados!")
        resetCheckerState()
        return true
    end

    local shrine, shrinePos = findShrine()
    if not shrine then
        warn("[imbuement] Shrine nao encontrado! Voce precisa estar no mesmo andar que o shrine.")
        resetCheckerState()
        return false
    end

    local playerPos = player:getPosition()
    local dist = math.max(math.abs(playerPos.x - shrinePos.x), math.abs(playerPos.y - shrinePos.y))
    if dist > 1 then
        print("[imbuement] Muito longe do shrine (dist: " .. dist .. "). Aproxime-se.")
        resetCheckerState()
        return false
    end

    print("[imbuement] Shrine encontrado em " .. shrinePos.x .. "," .. shrinePos.y .. "," .. shrinePos.z)

    local current = checkerState.itemsToProcess[checkerState.currentIndex]
    local item = current.item
    if not item or not item:getId() then
        item = findItem(current.id)
        if not item then
            for _, slotInfo in ipairs(EQUIPMENT_SLOTS) do
                local equipped = slotInfo.getFunc()
                if equipped and equipped:getId() == current.id then
                    item = equipped
                    break
                end
            end
        end
    end

    if not item then
        print("[imbuement] Item nao encontrado: " .. current.id)
        checkerState.currentIndex = checkerState.currentIndex + 1
        return "retry"
    end

    print("[imbuement] Usando shrine no item: " .. current.id)
    checkerState.waitingWindow = true
    checkerState.lastAction = currentTime
    useWith(shrine, item)

    checkerState.currentIndex = checkerState.currentIndex + 1

    delay(4000)
    return "retry"
end
