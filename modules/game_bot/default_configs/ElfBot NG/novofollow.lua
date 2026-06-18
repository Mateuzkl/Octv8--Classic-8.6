setDefaultTab("Main")

local STORAGE_KEY = "novoFollow"

local DEFAULT_FLOOR_CHANGERS = {
  ladders = {
    up = {1948, 5542, 16693, 16692, 8065, 8263, 7771, 20573, 20475, 31262, 21297, 1968},
    down = {432, 412, 469, 1080}
  },
  holes = {
    up = {},
    down = {293, 35500, 294, 595, 1949, 4728, 385, 9853, 37000, 37001, 35499, 35497, 29979, 25047, 25048, 25049, 25050, 25051, 25052, 25053, 25054, 25055, 25056, 25057, 25058, 21046, 21048}
  },
  ropeSpots = {
    up = {386, 12202, 21965, 21966},
    down = {}
  },
  stairs = {
    up = {16690, 1958, 7548, 7544, 1953, 1952, 1950, 1947, 7542, 855, 856, 1978, 1977, 6911, 6915, 1954, 5259, 20492, 1956, 775, 5257, 5258, 22566, 22747, 30757, 20225, 17395, 1964, 1966, 20255, 29113, 28357, 30912, 30906, 30908, 30914, 30916, 30904, 30918, 20750, 20491, 20496, 31130, 31129},
    down = {482, 414, 437, 7731, 413, 434, 859, 438, 6127, 566, 7476, 4826, 484, 433, 369, 20259, 19960, 411, 8690, 4825, 6130, 601, 1067, 567, 7768, 1067, 411, 600}
  },
  sewers = {
    up = {},
    down = {435, 21298}
  }
}

if type(storage[STORAGE_KEY]) ~= "table" then
  storage[STORAGE_KEY] = {
    enabled = false,
    leaderName = "",
    followName = "",
    navLeaderEnabled = true,
    followEnabled = true,
    useTargets = {},
    cavebotPause = {
      enabled = false,
      distance = 4,
      mcNames = ""
    },
    pingConfig = {
      auto = false,
      manualMs = 100
    },
    doorTargets = {},
    tools = {
      ropeId = 3003,
      shovelId = 3457,
      macheteId = 3308
    },
    routeFallback = {
      enabled = false,
      stepMs = 220,
      rawText = "",
      waypoints = {}
    },
    combo = {
      enabled = false,
      mode = "spell",
      triggerWord = "",
      spellText = "",
      runeId = 3155
    },
    levitate = {
      enabled = true,
      upSpell = 'exani hur "up"',
      downSpell = 'exani hur "down"',
      cooldownMs = 1200
    },
    hudSetup = {
      visible = false,
      collapsed = false,
      posX = 980,
      posY = 160,
      sendMode = "default",
      guildChannel = "",
      waveStep = 0,
      buttons = {
        { key = "follow", name = "Follow", mode = "toggle", commandOn = "!follow on", commandOff = "!follow off", commandDirect = "", state = false },
        { key = "cavebot", name = "CaveBot", mode = "toggle", commandOn = "!cavebot on", commandOff = "!cavebot off", commandDirect = "", state = false },
        { key = "target", name = "TargetBot", mode = "toggle", commandOn = "!target on", commandOff = "!target off", commandDirect = "", state = false },
        { key = "sd", name = "SD", mode = "toggle", commandOn = "!sd on", commandOff = "!sd off", commandDirect = "", state = false },
        { key = "paralyze", name = "Paralyze", mode = "toggle", commandOn = "!paralyze on", commandOff = "!paralyze off", commandDirect = "", state = false },
        { key = "antpush", name = "AntiPush", mode = "toggle", commandOn = "!antpush on", commandOff = "!antpush off", commandDirect = "", state = false },
        { key = "combo", name = "Combo", mode = "direct", commandOn = "", commandOff = "", commandDirect = "{trigger}", state = false }
      }
    },
    floorChangers = DEFAULT_FLOOR_CHANGERS
  }
end

local cfg = storage[STORAGE_KEY]
if type(cfg.tools) ~= "table" then
  cfg.tools = {}
end

local function clampNumber(value, minValue, maxValue, fallback)
  local n = tonumber(value)
  if not n then
    return fallback
  end
  if n < minValue then
    return minValue
  end
  if n > maxValue then
    return maxValue
  end
  return n
end

local function trim(text)
  if not text then
    return ""
  end
  return text:match("^%s*(.-)%s*$")
end

local function normalizeBoolFlag(value, defaultValue)
  if type(value) == "boolean" then
    return value
  end
  if type(value) == "number" then
    return value ~= 0
  end
  if type(value) == "string" then
    local text = trim(value):lower()
    if text == "true" or text == "1" or text == "on" or text == "yes" then
      return true
    end
    if text == "false" or text == "0" or text == "off" or text == "no" or text == "" then
      return false
    end
  end
  return defaultValue == true
end

local function splitNames(text)
  local list = {}
  if not text or text == "" then
    return list
  end
  local normalized = tostring(text):gsub("[\r\n;]", ",")
  for part in normalized:gmatch("[^,]+") do
    local name = trim(part)
    if name ~= "" then
      list[#list + 1] = name
    end
  end
  return list
end

local function sanitizeWaypointList(points)
  local out = {}
  if type(points) ~= "table" then
    return out
  end
  for _, p in ipairs(points) do
    if type(p) == "table" then
      local x = tonumber(p.x or p[1])
      local y = tonumber(p.y or p[2])
      local z = tonumber(p.z or p[3])
      if x and y and z then
        out[#out + 1] = { x = math.floor(x), y = math.floor(y), z = math.floor(z) }
      end
    end
  end
  return out
end

local function routeWaypointsToText(points)
  local lines = {}
  for _, p in ipairs(sanitizeWaypointList(points)) do
    lines[#lines + 1] = string.format("goto:%d,%d,%d", p.x, p.y, p.z)
  end
  return table.concat(lines, "\n")
end

local function parseRouteWaypoints(text)
  local points = {}
  local invalidLines = {}
  local input = tostring(text or "")
  if input == "" then
    return points, invalidLines
  end
  local lineNo = 0
  for rawLine in input:gmatch("[^\r\n]+") do
    lineNo = lineNo + 1
    local line = trim(rawLine)
    if line ~= "" then
      local lower = line:lower()
      local x, y, z = lower:match("^goto%s*:%s*(-?%d+)%s*,%s*(-?%d+)%s*,%s*(-?%d+)")
      if not x then
        x, y, z = lower:match("^(-?%d+)%s*,%s*(-?%d+)%s*,%s*(-?%d+)")
      end
      if x and y and z then
        points[#points + 1] = { x = tonumber(x), y = tonumber(y), z = tonumber(z) }
      else
        invalidLines[#invalidLines + 1] = lineNo
      end
    end
  end
  return sanitizeWaypointList(points), invalidLines
end

local function setStandardTooltip(widget, ptText, enText)
  if not widget or not widget.setTooltip then
    return
  end
  local pt = ptText or ""
  local en = enText or ""
  if en ~= "" then
    widget:setTooltip(string.format("PT: %s\nEN: %s", pt, en))
  else
    widget:setTooltip(pt)
  end
end

local function timeMs()
  if now then
    return now
  end
  if g_clock and g_clock.millis then
    return g_clock.millis()
  end
  return os.time() * 1000
end

local function getEffectivePingMs()
  if cfg.pingConfig and cfg.pingConfig.auto and ping and type(ping) == "function" then
    local p = ping()
    if type(p) == "number" and p > 0 and p <= 2000 then
      return p
    end
  end
  return tonumber(cfg.pingConfig and cfg.pingConfig.manualMs) or 0
end

local function clampDelay(value)
  if value < 0 then
    return 0
  end
  if value > 2000 then
    return 2000
  end
  return math.floor(value)
end

local function scaleDelay(base, factor)
  local f = factor or 1
  local p = getEffectivePingMs()
  return clampDelay(base + p * f)
end

local function scheduleWithPing(base, fn, factor)
  schedule(scaleDelay(base, factor), fn)
end

local function copyPos(pos)
  if not pos then
    return nil
  end
  return { x = pos.x, y = pos.y, z = pos.z }
end

local function isMapPos(pos)
  return pos and pos.x ~= 65535
end

local function sanitizeIdList(items)
  local ids = {}
  if type(items) ~= "table" then
    return ids
  end
  for _, item in ipairs(items) do
    local id = nil
    local itemType = type(item)
    if itemType == "number" then
      id = item
    elseif itemType == "table" then
      id = item.id or item.itemId or item.itemid or item[1]
    elseif itemType == "userdata" and item.getId then
      id = item:getId()
    end
    id = tonumber(id)
    if id then
      ids[#ids + 1] = id
    end
  end
  return ids
end

local FLOOR_CHANGER_DIRECTIONS = {
  ladders = { up = true, down = true },
  holes = { up = false, down = true },
  ropeSpots = { up = true, down = false },
  stairs = { up = true, down = true },
  sewers = { up = false, down = true }
}

local function normalizeDirectionalList(value, fallback, directions)
  local result = { up = {}, down = {} }
  local fallbackUp = sanitizeIdList(fallback and fallback.up or {})
  local fallbackDown = sanitizeIdList(fallback and fallback.down or {})
  if type(value) ~= "table" then
    value = nil
  end
  local hasDirectional = value and (value.up ~= nil or value.down ~= nil)
  if hasDirectional then
    if directions.up then
      if value.up ~= nil then
        result.up = sanitizeIdList(value.up)
      else
        result.up = fallbackUp
      end
    end
    if directions.down then
      if value.down ~= nil then
        result.down = sanitizeIdList(value.down)
      else
        result.down = fallbackDown
      end
    end
  else
    local list = sanitizeIdList(value or {})
    if #list == 0 then
      if directions.up then
        result.up = fallbackUp
      end
      if directions.down then
        result.down = fallbackDown
      end
    else
      if directions.up and directions.down then
        local fallbackUpSet = {}
        local fallbackDownSet = {}
        for _, id in ipairs(fallbackUp) do
          fallbackUpSet[id] = true
        end
        for _, id in ipairs(fallbackDown) do
          fallbackDownSet[id] = true
        end
        for _, id in ipairs(list) do
          local inUp = fallbackUpSet[id]
          local inDown = fallbackDownSet[id]
          if inUp then
            result.up[#result.up + 1] = id
          end
          if inDown then
            result.down[#result.down + 1] = id
          end
          if not inUp and not inDown then
            result.up[#result.up + 1] = id
            result.down[#result.down + 1] = id
          end
        end
      else
        if directions.up then
          result.up = list
        end
        if directions.down then
          result.down = list
        end
      end
    end
  end
  if not directions.up then
    result.up = {}
  end
  if not directions.down then
    result.down = {}
  end
  return result
end

local function normalizeConfig()
  -- Global toggle removed from UI: keep base system always enabled.
  cfg.enabled = true
  cfg.leaderName = trim(cfg.leaderName or "")
  cfg.followName = trim(cfg.followName or "")
  cfg.navLeaderEnabled = cfg.navLeaderEnabled == nil and true or cfg.navLeaderEnabled == true
  cfg.followEnabled = cfg.followEnabled == nil and true or cfg.followEnabled == true
  cfg.useTargets = sanitizeIdList(cfg.useTargets)
  if type(cfg.cavebotPause) ~= "table" then
    cfg.cavebotPause = {}
  end
  cfg.cavebotPause.enabled = cfg.cavebotPause.enabled == true
  cfg.cavebotPause.distance = clampNumber(cfg.cavebotPause.distance, 1, 20, 4)
  cfg.cavebotPause.mcNames = trim(cfg.cavebotPause.mcNames or "")
  if type(cfg.pingConfig) ~= "table" then
    cfg.pingConfig = {}
  end
  cfg.pingConfig.auto = cfg.pingConfig.auto == true
  cfg.pingConfig.manualMs = clampNumber(cfg.pingConfig.manualMs, 0, 1000, 100)
  cfg.doorTargets = sanitizeIdList(cfg.doorTargets)
  cfg.tools.ropeId = clampNumber(cfg.tools.ropeId, 1, 100000, 3003)
  cfg.tools.shovelId = clampNumber(cfg.tools.shovelId, 1, 100000, 3457)
  cfg.tools.macheteId = clampNumber(cfg.tools.macheteId, 1, 100000, 3308)
  if type(cfg.routeFallback) ~= "table" then
    cfg.routeFallback = {}
  end
  cfg.routeFallback.enabled = cfg.routeFallback.enabled == true
  cfg.routeFallback.stepMs = clampNumber(cfg.routeFallback.stepMs, 80, 1000, 220)
  cfg.routeFallback.rawText = cfg.routeFallback.rawText or ""
  cfg.routeFallback.waypoints = sanitizeWaypointList(cfg.routeFallback.waypoints)
  if #cfg.routeFallback.waypoints == 0 and cfg.routeFallback.rawText ~= "" then
    cfg.routeFallback.waypoints = parseRouteWaypoints(cfg.routeFallback.rawText)
  end
  if cfg.routeFallback.rawText == "" and #cfg.routeFallback.waypoints > 0 then
    cfg.routeFallback.rawText = routeWaypointsToText(cfg.routeFallback.waypoints)
  end
  if type(cfg.combo) ~= "table" then
    cfg.combo = {}
  end
  cfg.combo.enabled = cfg.combo.enabled == true
  cfg.combo.mode = cfg.combo.mode == "rune" and "rune" or "spell"
  cfg.combo.triggerWord = trim(cfg.combo.triggerWord or "")
  cfg.combo.spellText = trim(cfg.combo.spellText or "")
  cfg.combo.runeId = clampNumber(cfg.combo.runeId, 100, 100000, 3155)
  if type(cfg.levitate) ~= "table" then
    cfg.levitate = {}
  end
  cfg.levitate.enabled = normalizeBoolFlag(cfg.levitate.enabled, true)
  cfg.levitate.upSpell = cfg.levitate.upSpell or 'exani hur "up"'
  cfg.levitate.downSpell = cfg.levitate.downSpell or 'exani hur "down"'
  cfg.levitate.cooldownMs = clampNumber(cfg.levitate.cooldownMs, 300, 5000, 1200)
  if type(cfg.hudSetup) ~= "table" then
    cfg.hudSetup = {}
  end
  cfg.hudSetup.visible = cfg.hudSetup.visible == true
  cfg.hudSetup.collapsed = cfg.hudSetup.collapsed == true
  cfg.hudSetup.posX = clampNumber(cfg.hudSetup.posX, 0, 5000, 980)
  cfg.hudSetup.posY = clampNumber(cfg.hudSetup.posY, 0, 5000, 160)
  cfg.hudSetup.sendMode = trim(cfg.hudSetup.sendMode or ""):lower()
  if cfg.hudSetup.sendMode ~= "pm" and cfg.hudSetup.sendMode ~= "guild" then
    cfg.hudSetup.sendMode = "default"
  end
  cfg.hudSetup.guildChannel = trim(cfg.hudSetup.guildChannel or "")
  cfg.hudSetup.waveStep = clampNumber(cfg.hudSetup.waveStep, 0, 999999, 0)
  if type(cfg.hudSetup.buttons) ~= "table" then
    cfg.hudSetup.buttons = {}
  end
  if type(cfg.hudSetup.states) ~= "table" then
    cfg.hudSetup.states = {}
  end
  local defaults = {
    { key = "follow", name = "Follow", mode = "toggle", commandOn = "!follow on", commandOff = "!follow off", commandDirect = "" },
    { key = "cavebot", name = "CaveBot", mode = "toggle", commandOn = "!cavebot on", commandOff = "!cavebot off", commandDirect = "" },
    { key = "target", name = "TargetBot", mode = "toggle", commandOn = "!target on", commandOff = "!target off", commandDirect = "" },
    { key = "sd", name = "SD", mode = "toggle", commandOn = "!sd on", commandOff = "!sd off", commandDirect = "" },
    { key = "paralyze", name = "Paralyze", mode = "toggle", commandOn = "!paralyze on", commandOff = "!paralyze off", commandDirect = "" },
    { key = "antpush", name = "AntiPush", mode = "toggle", commandOn = "!antpush on", commandOff = "!antpush off", commandDirect = "" },
    { key = "combo", name = "Combo", mode = "direct", commandOn = "", commandOff = "", commandDirect = "{trigger}" }
  }
  for index, defaultDef in ipairs(defaults) do
    local btn = cfg.hudSetup.buttons[index]
    if type(btn) ~= "table" then
      btn = {}
      cfg.hudSetup.buttons[index] = btn
    end
    btn.key = defaultDef.key
    btn.name = trim(btn.name or btn.label or defaultDef.name)
    if btn.name == "" then
      btn.name = defaultDef.name
    end
    local mode = trim(btn.mode or ""):lower()
    if defaultDef.key == "combo" then
      mode = "direct"
    elseif mode ~= "toggle" then
      mode = "toggle"
    end
    btn.mode = mode
    btn.commandOn = trim(btn.commandOn or defaultDef.commandOn or "")
    btn.commandOff = trim(btn.commandOff or defaultDef.commandOff or "")
    btn.commandDirect = trim(btn.commandDirect or defaultDef.commandDirect or "")
    local stateFallback = cfg.hudSetup.states[defaultDef.key] == true
    btn.state = normalizeBoolFlag(btn.state, stateFallback)
    if btn.mode == "direct" then
      btn.state = false
      if btn.commandDirect == "" then
        btn.commandDirect = defaultDef.commandDirect or ""
      end
    else
      if btn.commandOn == "" then
        btn.commandOn = defaultDef.commandOn
      end
      if btn.commandOff == "" then
        btn.commandOff = defaultDef.commandOff
      end
    end
  end
  for index = #cfg.hudSetup.buttons, #defaults + 1, -1 do
    cfg.hudSetup.buttons[index] = nil
  end
  cfg.hudSetup.states = nil
  if type(cfg.floorChangers) ~= "table" then
    cfg.floorChangers = {}
  end
end

local function ensureFloorChangers()
  if type(cfg.floorChangers) ~= "table" then
    cfg.floorChangers = {}
  end
  local fc = cfg.floorChangers
  fc.ladders = normalizeDirectionalList(fc.ladders, DEFAULT_FLOOR_CHANGERS.ladders, FLOOR_CHANGER_DIRECTIONS.ladders)
  fc.holes = normalizeDirectionalList(fc.holes, DEFAULT_FLOOR_CHANGERS.holes, FLOOR_CHANGER_DIRECTIONS.holes)
  fc.ropeSpots = normalizeDirectionalList(fc.ropeSpots, DEFAULT_FLOOR_CHANGERS.ropeSpots, FLOOR_CHANGER_DIRECTIONS.ropeSpots)
  fc.stairs = normalizeDirectionalList(fc.stairs, DEFAULT_FLOOR_CHANGERS.stairs, FLOOR_CHANGER_DIRECTIONS.stairs)
  fc.sewers = normalizeDirectionalList(fc.sewers, DEFAULT_FLOOR_CHANGERS.sewers, FLOOR_CHANGER_DIRECTIONS.sewers)
end

local function applyDefaultIdsOnce()
  if cfg.defaultsApplied then
    return
  end
  local fc = cfg.floorChangers
  local function applyIfEmpty(list, fallback)
    if type(list) ~= "table" or #list == 0 then
      return sanitizeIdList(fallback)
    end
    return list
  end
  fc.ladders.up = applyIfEmpty(fc.ladders.up, DEFAULT_FLOOR_CHANGERS.ladders.up)
  fc.ladders.down = applyIfEmpty(fc.ladders.down, DEFAULT_FLOOR_CHANGERS.ladders.down)
  fc.holes.down = applyIfEmpty(fc.holes.down, DEFAULT_FLOOR_CHANGERS.holes.down)
  fc.ropeSpots.up = applyIfEmpty(fc.ropeSpots.up, DEFAULT_FLOOR_CHANGERS.ropeSpots.up)
  fc.stairs.up = applyIfEmpty(fc.stairs.up, DEFAULT_FLOOR_CHANGERS.stairs.up)
  fc.stairs.down = applyIfEmpty(fc.stairs.down, DEFAULT_FLOOR_CHANGERS.stairs.down)
  fc.sewers.down = applyIfEmpty(fc.sewers.down, DEFAULT_FLOOR_CHANGERS.sewers.down)
  cfg.defaultsApplied = true
end

normalizeConfig()
ensureFloorChangers()
applyDefaultIdsOnce()

local changerSets = { Up = {}, Down = {} }
local useTargetsSet = {}
local useTargetsCount = 0
local doorTargetsSet = {}
local doorTargetsCount = 0

local function toSet(list)
  local set = {}
  if type(list) ~= "table" then
    return set
  end
  for _, id in ipairs(list) do
    set[id] = true
  end
  return set
end

local function refreshChangerSets()
  ensureFloorChangers()
  changerSets.Up = {
    ladders = toSet(cfg.floorChangers.ladders.up),
    holes = toSet(cfg.floorChangers.holes.up),
    ropeSpots = toSet(cfg.floorChangers.ropeSpots.up),
    stairs = toSet(cfg.floorChangers.stairs.up),
    sewers = toSet(cfg.floorChangers.sewers.up)
  }
  changerSets.Down = {
    ladders = toSet(cfg.floorChangers.ladders.down),
    holes = toSet(cfg.floorChangers.holes.down),
    ropeSpots = toSet(cfg.floorChangers.ropeSpots.down),
    stairs = toSet(cfg.floorChangers.stairs.down),
    sewers = toSet(cfg.floorChangers.sewers.down)
  }
end

refreshChangerSets()

local function refreshUseTargets()
  useTargetsSet = toSet(cfg.useTargets)
  useTargetsCount = 0
  if type(cfg.useTargets) == "table" then
    useTargetsCount = #cfg.useTargets
  end
end

refreshUseTargets()

local function refreshDoorTargets()
  doorTargetsSet = toSet(cfg.doorTargets)
  doorTargetsCount = 0
  if type(cfg.doorTargets) == "table" then
    doorTargetsCount = #cfg.doorTargets
  end
end

refreshDoorTargets()

local function getUseThing(tile)
  if not tile then
    return nil
  end
  return tile:getTopUseThing() or tile:getGround()
end

local function getThingId(thing)
  if not thing or not thing.getId then
    return nil
  end
  return thing:getId()
end

local function matchesSet(thing, set)
  if not thing or not set then
    return false
  end
  local id = getThingId(thing)
  if not id then
    return false
  end
  return set[id] == true
end

local function getUseTargetThingAt(pos)
  if not pos then
    return nil
  end
  if not useTargetsCount or useTargetsCount == 0 then
    return nil
  end
  local tile = g_map.getTile(pos)
  if not tile then
    return nil
  end
  local topUse = tile:getTopUseThing()
  if matchesSet(topUse, useTargetsSet) then
    return topUse
  end
  local topThing = tile:getTopThing()
  if matchesSet(topThing, useTargetsSet) then
    return topThing
  end
  local groundThing = tile:getGround()
  if matchesSet(groundThing, useTargetsSet) then
    return groundThing
  end
  if tile.getThings then
    local things = tile:getThings()
    if things then
      for _, thing in ipairs(things) do
        if matchesSet(thing, useTargetsSet) then
          return thing
        end
      end
    end
  end
  return nil
end

local function getDoorThingAt(pos)
  if not pos then
    return nil
  end
  if not doorTargetsCount or doorTargetsCount == 0 then
    return nil
  end
  local tile = g_map.getTile(pos)
  if not tile then
    return nil
  end
  local topUse = tile:getTopUseThing()
  if matchesSet(topUse, doorTargetsSet) then
    return topUse
  end
  local topThing = tile:getTopThing()
  if matchesSet(topThing, doorTargetsSet) then
    return topThing
  end
  local groundThing = tile:getGround()
  if matchesSet(groundThing, doorTargetsSet) then
    return groundThing
  end
  if tile.getThings then
    local things = tile:getThings()
    if things then
      for _, thing in ipairs(things) do
        if matchesSet(thing, doorTargetsSet) then
          return thing
        end
      end
    end
  end
  return nil
end

local function useWithItem(item, thing)
  if useWith then
    useWith(item, thing)
  elseif g_game.useWith then
    g_game.useWith(item, thing)
  else
    g_game.use(thing)
  end
end

local function follow3UseThing(thing)
  if thing then
    g_game.use(thing)
  end
end

local function follow3UseTile(targetPos)
  if not targetPos then
    return
  end
  local tile = g_map.getTile(targetPos)
  local thing = getUseThing(tile)
  follow3UseThing(thing)
end

local function follow3UseWithRope(targetPos)
  if not targetPos then
    return
  end
  local ropeItem = findItem and findItem(cfg.tools.ropeId) or nil
  if not ropeItem then
    return
  end
  local tile = g_map.getTile(targetPos)
  local thing = getUseThing(tile)
  if thing then
    useWithItem(ropeItem, thing)
  end
end

local function follow3UseAroundAll(centerPos)
  if not centerPos then
    return
  end
  for i = -1, 1 do
    for j = -1, 1 do
      local p = { x = centerPos.x + i, y = centerPos.y + j, z = centerPos.z }
      local targetThing = getUseTargetThingAt(p)
      if targetThing then
        follow3UseThing(targetThing)
      else
        follow3UseTile(p)
      end
    end
  end
end

local function findThingInTileBySet(tile, set)
  if not tile or not set then
    return nil
  end
  local topThing = tile:getTopUseThing()
  if matchesSet(topThing, set) then
    return topThing
  end
  local groundThing = tile:getGround()
  if matchesSet(groundThing, set) then
    return groundThing
  end
  if tile.getThings then
    local things = tile:getThings()
    if things then
      for _, thing in ipairs(things) do
        if matchesSet(thing, set) then
          return thing
        end
      end
    end
  end
  return nil
end

local function getChangerActionAt(pos, dirKey)
  local tile = g_map.getTile(pos)
  if not tile then
    return nil
  end
  local function checkDir(key)
    local sets = changerSets[key]
    if not sets then
      return nil
    end
    local ropeThing = findThingInTileBySet(tile, sets.ropeSpots)
    if ropeThing then
      return "ROPE", ropeThing
    end
    local useThing = findThingInTileBySet(tile, sets.holes)
      or findThingInTileBySet(tile, sets.ladders)
      or findThingInTileBySet(tile, sets.stairs)
      or findThingInTileBySet(tile, sets.sewers)
    if useThing then
      return "USE", useThing
    end
    return nil, nil
  end
  if dirKey == "Up" or dirKey == "Down" then
    return checkDir(dirKey)
  end
  return checkDir("Up") or checkDir("Down")
end

local function follow3UseAroundChangers(centerPos, dirKey)
  if not centerPos then
    return
  end
  local used = 0
  for i = -1, 1 do
    for j = -1, 1 do
      local p = { x = centerPos.x + i, y = centerPos.y + j, z = centerPos.z }
      local targetThing = getUseTargetThingAt(p)
      if targetThing then
        follow3UseThing(targetThing)
        used = used + 1
      else
      local action, thing = getChangerActionAt(p, dirKey)
      if action == "ROPE" then
        if thing then
          local ropeItem = findItem and findItem(cfg.tools.ropeId) or nil
          if ropeItem then
            useWithItem(ropeItem, thing)
            used = used + 1
          end
        else
          follow3UseWithRope(p)
          used = used + 1
        end
      elseif action == "USE" then
        if thing then
          follow3UseThing(thing)
        else
          follow3UseTile(p)
        end
        used = used + 1
      end
      end
    end
  end
  if used == 0 then
    follow3UseAroundAll(centerPos)
  end
end

local function follow3UseAtPos(targetPos, dirKey)
  if not targetPos then
    return
  end
  local targetThing = getUseTargetThingAt(targetPos)
  if targetThing then
    follow3UseThing(targetThing)
    return
  end
  local action, thing = getChangerActionAt(targetPos, dirKey)
  if action == "ROPE" then
    local ropeItem = findItem and findItem(cfg.tools.ropeId) or nil
    if ropeItem and thing then
      useWithItem(ropeItem, thing)
      return
    end
  elseif action == "USE" then
    if thing then
      follow3UseThing(thing)
      return
    end
  end
  follow3UseTile(targetPos)
end

local lastLevitateAt = 0

local function handleExani(dirKey)
  if not cfg.levitate or not cfg.levitate.enabled then
    return false
  end
  local nowMs = timeMs()
  if nowMs - lastLevitateAt < cfg.levitate.cooldownMs then
    return false
  end
  local spell = nil
  if dirKey == "Down" then
    spell = cfg.levitate.downSpell
  else
    spell = cfg.levitate.upSpell
  end
  if spell and spell ~= "" then
    say(spell)
    lastLevitateAt = nowMs
    return true
  end
  return false
end

local follow3LastLeaderDir = nil
local follow3CycleId = 0
local FOLLOW3_MAX_CYCLES = 3
local FOLLOW3_CYCLE_DELAY_MS = 700
local TRAVEL_COOLDOWN_MS = 1500
local TRAVEL_STEP_DELAY_MS = 350
local CATCHUP_COOLDOWN_MS = 400
local DOOR_USE_COOLDOWN_MS = 500
local DOOR_SEARCH_RADIUS = 6
local ROUTE_FALLBACK_TRIGGER_MS = 2500
local COMBO_TARGET_TIMEOUT_MS = 3000
local COMBO_TRIGGER_TIMEOUT_MS = 1200
local COMBO_TRIGGER_GUARD_MS = 120
local COMBO_TRIGGER_MAX_QUEUE = 3
local REFILL_COMMAND_STEP_MS = 250
local REFILL_COMMAND_TIMEOUT_MS = 120000
local NAV_CMD_CFG = {
  queueStepMs = 100,
  queueMaxSize = 25,
  duplicateWindowMs = 900,
  defaultCooldownMs = 500,
  toggleLockMs = 180,
  profileLockMs = 350,
  genericLockMs = 140,
  travelLockExtraMs = 250
}

local routeFallbackState = {
  missingSince = 0,
  active = false,
  index = 1,
  lastStepAt = 0
}
local followRuntimeState = {
  lastLeaderPos = nil,
  lastLeaderSeenAt = 0,
  lastFloorRecoveryAt = 0,
  moveSeq = 0,
  catchupPrecision = 1,
  lastSeenMaxAgeMs = 12000,
  floorRecoveryCooldownMs = 500
}

local comboLeaderTarget = nil
local comboLeaderTargetAt = 0
local comboPendingCount = 0
local comboPendingSince = 0
local comboLastTriggerAt = 0
local refillCommandState = {
  active = false,
  npcName = "",
  npcIndex = 1,
  startedAt = 0,
  lastStepAt = 0,
  prevBuyEnabled = nil
}
local navCmdQueue = {}
local navCmdQueueState = {
  busyUntil = 0,
  travelUntil = 0,
  lastByCommand = {},
  lastSignature = "",
  lastSignatureAt = 0
}
local clearNavCommandQueue

local function follow3WaitForOldPos(oldPos, onArrive, attempts, delayMs, cycleId)
  if not oldPos or not onArrive then
    return
  end
  local tries = attempts or 6
  local delay = scaleDelay(delayMs or 200)
  local function check()
    if cycleId and cycleId ~= follow3CycleId then
      return
    end
    if getDistanceBetween(pos(), oldPos) == 0 and posz() == oldPos.z then
      onArrive()
      return
    end
    tries = tries - 1
    if tries <= 0 then
      return
    end
    schedule(delay, check)
  end
  schedule(delay, check)
end

local function follow3TryExaniHur(oldPos, newPos, leaderName)
  if not oldPos or not newPos then
    return
  end
  if not cfg.levitate or not cfg.levitate.enabled then
    return
  end
  if getDistanceBetween(pos(), oldPos) ~= 0 or posz() ~= oldPos.z then
    return
  end
  if leaderName and getCreatureByName(leaderName) ~= nil then
    return
  end
  local dirKey = nil
  if newPos.z < oldPos.z then
    dirKey = "Up"
  elseif newPos.z > oldPos.z then
    dirKey = "Down"
  end
  if not dirKey then
    return
  end
  if follow3LastLeaderDir ~= nil and turn then
    turn(follow3LastLeaderDir)
  end
  handleExani(dirKey)
end

local function follow3TryUseThenAround(oldPos, dirKey, cycleId, onAfter)
  follow3WaitForOldPos(oldPos, function()
    if cycleId and cycleId ~= follow3CycleId then
      return
    end
    follow3UseAtPos(oldPos, dirKey)
    scheduleWithPing(300, function()
      if cycleId and cycleId ~= follow3CycleId then
        return
      end
      if getDistanceBetween(pos(), oldPos) == 0 and posz() == oldPos.z then
        follow3UseAroundChangers(oldPos, dirKey)
      end
      if onAfter then
        scheduleWithPing(300, function()
          if cycleId and cycleId ~= follow3CycleId then
            return
          end
          if getDistanceBetween(pos(), oldPos) == 0 and posz() == oldPos.z then
            onAfter()
          end
        end)
      end
    end)
  end, 10, 200, cycleId)
end

local function getDirKey(oldPos, newPos)
  if not oldPos or not newPos then
    return nil
  end
  if newPos.z < oldPos.z then
    return "Up"
  end
  if newPos.z > oldPos.z then
    return "Down"
  end
  return nil
end

local function shouldRetryCycle(oldPos, leaderName)
  if not oldPos then
    return false
  end
  if getDistanceBetween(pos(), oldPos) ~= 0 or posz() ~= oldPos.z then
    return false
  end
  if leaderName and getCreatureByName(leaderName) ~= nil then
    return false
  end
  return true
end

local function follow3StartUseCycle(oldPos, dirKey, newPos, leaderName)
  if not oldPos then
    return
  end
  follow3CycleId = follow3CycleId + 1
  local cycleId = follow3CycleId
  local remaining = FOLLOW3_MAX_CYCLES
  local function runCycle()
    if cycleId ~= follow3CycleId then
      return
    end
    follow3TryUseThenAround(oldPos, dirKey, cycleId, function()
      if cycleId ~= follow3CycleId then
        return
      end
      if newPos then
        follow3TryExaniHur(oldPos, newPos, leaderName)
      end
      remaining = remaining - 1
      if remaining <= 0 then
        return
      end
      if shouldRetryCycle(oldPos, leaderName) then
        scheduleWithPing(FOLLOW3_CYCLE_DELAY_MS, runCycle)
      end
    end)
  end
  runCycle()
end

local lastTravelAt = 0
local lastTravelCity = ""

local function npcSay(text)
  if NPC and NPC.say then
    NPC.say(text)
    return
  end
  if talkNPC then
    talkNPC(text)
    return
  end
  if sayNpc then
    sayNpc(text)
    return
  end
  if sayNPC then
    sayNPC(text)
    return
  end
  if talkNpc then
    talkNpc(text)
    return
  end
  say(text)
end

local function scheduleTravelNpcTalk(city)
  if not city or city == "" then
    return
  end
  local nowMs = timeMs()
  if lastTravelCity == city:lower() and nowMs - lastTravelAt < scaleDelay(TRAVEL_COOLDOWN_MS) then
    return
  end
  lastTravelAt = nowMs
  lastTravelCity = city:lower()
  scheduleWithPing(0, function()
    npcSay("hi")
  end)
  scheduleWithPing(TRAVEL_STEP_DELAY_MS, function()
    npcSay(city)
  end)
  scheduleWithPing(TRAVEL_STEP_DELAY_MS * 2, function()
    npcSay("yes")
  end)
  scheduleWithPing(TRAVEL_STEP_DELAY_MS * 3, function()
    npcSay("yes")
  end)
end

local lastDoorUseAt = 0

local function tryUseDoorsAround(centerPos)
  if not centerPos then
    return
  end
  if doorTargetsCount == 0 then
    return
  end
  local nowMs = timeMs()
  if nowMs - lastDoorUseAt < scaleDelay(DOOR_USE_COOLDOWN_MS) then
    return
  end
  local used = false
  for i = -1, 1 do
    for j = -1, 1 do
      local p = { x = centerPos.x + i, y = centerPos.y + j, z = centerPos.z }
      local doorThing = getDoorThingAt(p)
      if doorThing then
        follow3UseThing(doorThing)
        used = true
      end
    end
  end
  if used then
    lastDoorUseAt = nowMs
  end
end

local function findDoorCandidate(fromPos, targetPos, radius)
  if not fromPos or not targetPos then
    return nil
  end
  local distToLeader = getDistanceBetween(fromPos, targetPos)
  if not distToLeader then
    return nil
  end
  local best = nil
  local bestScore = nil
  for dx = -radius, radius do
    for dy = -radius, radius do
      local p = { x = fromPos.x + dx, y = fromPos.y + dy, z = fromPos.z }
      local doorThing = getDoorThingAt(p)
      if doorThing then
        local distToTarget = getDistanceBetween(p, targetPos)
        if distToTarget and distToTarget <= distToLeader + 1 then
          local distFrom = math.max(math.abs(dx), math.abs(dy))
          local score = distToTarget * 10 + distFrom
          if not bestScore or score < bestScore then
            best = { pos = p, thing = doorThing }
            bestScore = score
          end
        end
      end
    end
  end
  return best
end

local function tryApproachDoor(targetPos)
  if not targetPos or doorTargetsCount == 0 then
    return false
  end
  local me = pos()
  if not me or not isMapPos(me) or me.z ~= targetPos.z then
    return false
  end
  local candidate = findDoorCandidate(me, targetPos, DOOR_SEARCH_RADIUS)
  if not candidate then
    return false
  end
  if getDistanceBetween(me, candidate.pos) <= 1 then
    local nowMs = timeMs()
    if nowMs - lastDoorUseAt >= scaleDelay(DOOR_USE_COOLDOWN_MS) then
      follow3UseThing(candidate.thing)
      lastDoorUseAt = nowMs
    end
    return true
  end
  autoWalk(candidate.pos, 20, { ignoreNonPathable = true, ignoreFields = true, precision = 1 })
  return true
end

local function isLocalLeader(leaderName)
  if leaderName == "" then
    return false
  end
  local myName = ""
  if type(name) == "function" then
    myName = trim(name())
  end
  if myName == "" and g_game and g_game.getLocalPlayer then
    local player = g_game.getLocalPlayer()
    if player and player.getName then
      myName = trim(player:getName() or "")
    end
  end
  return myName ~= "" and myName:lower() == leaderName:lower()
end

local function isNavLeaderSystemEnabled()
  return cfg.navLeaderEnabled == true
end

local function isFollowSystemEnabled()
  return cfg.followEnabled == true
end

local function getFollowLeaderName()
  return trim(cfg.followName)
end

local function getNavLeaderName()
  return trim(cfg.leaderName)
end

local function refillLog(text)
  print("[Nav Refill] " .. tostring(text or ""))
end

local function getBuySupplyCommandCallback()
  if type(buySupplyChecker) == "function" then
    return buySupplyChecker
  end
  if Checker and type(Checker.buySupply) == "function" then
    return Checker.buySupply
  end
  return nil
end

local function buildConfiguredBuyNpcList()
  local list = {}
  local seen = {}
  local buyCfg = storage and storage.buySupplies
  local items = buyCfg and buyCfg.items
  if type(items) ~= "table" then
    return list
  end
  for _, entry in ipairs(items) do
    if entry and entry.enabled ~= false then
      local entryId = tonumber(entry.id) or 0
      local entryAmount = tonumber(entry.amount) or 0
      local npcName = trim(entry.npcName or "")
      if entryId > 100 and entryAmount > 0 and npcName ~= "" then
        local key = npcName:lower()
        if not seen[key] then
          seen[key] = true
          list[#list + 1] = npcName
        end
      end
    end
  end
  return list
end

local function findConfiguredBuyNpcIndex(requestedName, npcList)
  local requested = trim(requestedName or "")
  if requested == "" then
    return nil, nil, false
  end
  local requestedLower = requested:lower()
  for idx, npcName in ipairs(npcList or {}) do
    if npcName:lower() == requestedLower then
      return idx, npcName, false
    end
  end
  local partialMatches = {}
  for idx, npcName in ipairs(npcList or {}) do
    if npcName:lower():find(requestedLower, 1, true) then
      partialMatches[#partialMatches + 1] = { idx = idx, name = npcName }
    end
  end
  if #partialMatches == 1 then
    return partialMatches[1].idx, partialMatches[1].name, false
  end
  if #partialMatches > 1 then
    return nil, nil, true
  end
  return nil, nil, false
end

local function stopRefillCommand()
  if refillCommandState.prevBuyEnabled ~= nil and storage and storage.buySupplies then
    storage.buySupplies.enabled = refillCommandState.prevBuyEnabled
  end
  refillCommandState.active = false
  refillCommandState.npcName = ""
  refillCommandState.npcIndex = 1
  refillCommandState.startedAt = 0
  refillCommandState.lastStepAt = 0
  refillCommandState.prevBuyEnabled = nil
end

local function startRefillCommand(npcName)
  local requestedName = trim(npcName or "")
  if requestedName == "" then
    return false, "Nome do NPC vazio."
  end
  if not storage or not storage.buySupplies then
    return false, "Config de Buy Supplies nao encontrada."
  end
  if not getBuySupplyCommandCallback() then
    return false, "Funcoes de Buy Supplies indisponiveis (cavebot_functions)."
  end

  local npcList = buildConfiguredBuyNpcList()
  if #npcList == 0 then
    return false, "Nenhum NPC de compra configurado no Buy Supplies."
  end

  local npcIndex, resolvedName, ambiguous = findConfiguredBuyNpcIndex(requestedName, npcList)
  if ambiguous then
    return false, "Nome ambiguo. Use o nome completo do NPC."
  end
  if not npcIndex then
    return false, string.format("NPC '%s' nao encontrado no cadastro de Buy Supplies.", requestedName)
  end

  local npcCreature = getCreatureByName(resolvedName)
  if not npcCreature or not npcCreature.getPosition then
    return false, string.format("NPC '%s' nao esta visivel por perto.", resolvedName)
  end
  local npcPos = npcCreature:getPosition()
  if not npcPos or not isMapPos(npcPos) or npcPos.z ~= posz() then
    return false, string.format("NPC '%s' nao esta no mesmo andar.", resolvedName)
  end
  if getDistanceBetween(pos(), npcPos) > 15 then
    return false, string.format("NPC '%s' esta longe para refilar agora.", resolvedName)
  end

  stopRefillCommand()
  local buyCfg = storage.buySupplies
  refillCommandState.prevBuyEnabled = buyCfg.enabled ~= false
  buyCfg.enabled = true
  buyCfg.currentNpcIdx = npcIndex
  buyCfg.lastNpcName = nil
  buyCfg.tradeRetries = 0
  buyCfg.reachRetries = 0

  refillCommandState.active = true
  refillCommandState.npcName = resolvedName
  refillCommandState.npcIndex = npcIndex
  refillCommandState.startedAt = timeMs()
  refillCommandState.lastStepAt = 0
  return true, resolvedName
end

local function stepRefillCommand(nowMs)
  if not refillCommandState.active then
    return
  end
  local buyCfg = storage and storage.buySupplies
  if not buyCfg then
    refillLog("Config de Buy Supplies indisponivel. Cancelando.")
    stopRefillCommand()
    return
  end
  if nowMs - (refillCommandState.startedAt or 0) > REFILL_COMMAND_TIMEOUT_MS then
    refillLog("Tempo limite atingido. Cancelando comando de refil.")
    stopRefillCommand()
    return
  end
  if nowMs - (refillCommandState.lastStepAt or 0) < REFILL_COMMAND_STEP_MS then
    return
  end
  refillCommandState.lastStepAt = nowMs

  local callback = getBuySupplyCommandCallback()
  if not callback then
    refillLog("Funcao buySupplyChecker nao encontrada. Cancelando.")
    stopRefillCommand()
    return
  end

  buyCfg.enabled = true
  buyCfg.currentNpcIdx = refillCommandState.npcIndex
  local result = callback()
  if result == true then
    refillLog(string.format("Refil concluido no NPC '%s'.", refillCommandState.npcName))
    stopRefillCommand()
    return
  end
  if result == false then
    refillLog("Falha ao executar refil. Cancelando.")
    stopRefillCommand()
    return
  end
end

local function clearComboLeaderTarget()
  comboLeaderTarget = nil
  comboLeaderTargetAt = 0
end

local function clearComboTriggers()
  comboPendingCount = 0
  comboPendingSince = 0
end

local function queueComboTrigger()
  local nowMs = timeMs()
  if nowMs - comboLastTriggerAt < COMBO_TRIGGER_GUARD_MS then
    return
  end
  comboLastTriggerAt = nowMs
  comboPendingSince = nowMs
  if comboPendingCount < COMBO_TRIGGER_MAX_QUEUE then
    comboPendingCount = comboPendingCount + 1
  end
end

local function matchesComboTriggerText(text)
  local triggerWord = trim((cfg.combo and cfg.combo.triggerWord) or ""):lower()
  if triggerWord == "" then
    return false
  end
  local t = trim((text or ""):lower())
  if t == "" then
    return false
  end
  return t == triggerWord
end

local function isComboTargetValid(target)
  if not target or not target.getPosition then
    return false
  end
  local tpos = target:getPosition()
  return tpos and isMapPos(tpos) and tpos.z == posz()
end

local function useRuneOnTarget(runeId, target)
  if not runeId or runeId < 100 or not target then
    return false
  end
  if findItem and not findItem(runeId) then
    return false
  end
  if useWith then
    useWith(runeId, target)
    return true
  end
  if g_game and g_game.useInventoryItemWith then
    g_game.useInventoryItemWith(runeId, target)
    return true
  end
  local runeItem = findItem and findItem(runeId) or nil
  if runeItem then
    useWithItem(runeItem, target)
    return true
  end
  return false
end

local function follow3AutoWalk(targetPos, precision)
  if not targetPos then
    return false
  end
  local walkPrecision = tonumber(precision)
  if not walkPrecision then
    walkPrecision = 0
  end
  return autoWalk(targetPos, 20, { ignoreNonPathable = true, ignoreFields = true, precision = walkPrecision })
end

local function resetRouteFallbackState(clearMissingSince)
  routeFallbackState.active = false
  routeFallbackState.index = 1
  routeFallbackState.lastStepAt = 0
  if clearMissingSince then
    routeFallbackState.missingSince = 0
  end
end

local followSelfSuppressed = false
followRuntimeState.nextMoveSeq = function()
  followRuntimeState.moveSeq = (followRuntimeState.moveSeq or 0) + 1
  return followRuntimeState.moveSeq
end

followRuntimeState.isMoveSeqCurrent = function(seq)
  return seq ~= nil and seq == (followRuntimeState.moveSeq or 0)
end

followRuntimeState.cacheLeaderPos = function(leaderPos, nowMs)
  if not leaderPos or not isMapPos(leaderPos) then
    return
  end
  followRuntimeState.lastLeaderPos = copyPos(leaderPos)
  followRuntimeState.lastLeaderSeenAt = nowMs or timeMs()
end

followRuntimeState.tryFloorRecovery = function(targetPos, nowMs)
  if not targetPos or not isMapPos(targetPos) then
    return false
  end
  local me = pos()
  if not me or not isMapPos(me) then
    return false
  end
  if targetPos.z == me.z then
    return false
  end
  if math.abs((targetPos.x or 0) - (me.x or 0)) > 1 or math.abs((targetPos.y or 0) - (me.y or 0)) > 1 then
    return false
  end
  local recoveryCooldown = followRuntimeState.floorRecoveryCooldownMs or 500
  if nowMs - (followRuntimeState.lastFloorRecoveryAt or 0) < scaleDelay(recoveryCooldown, 0.3) then
    return false
  end
  local dirKey = targetPos.z < me.z and "Up" or "Down"
  follow3UseAroundChangers(me, dirKey)
  followRuntimeState.lastFloorRecoveryAt = nowMs
  return true
end

local function shouldSuppressFollowForSelf()
  local leaderName = getFollowLeaderName()
  if leaderName == "" or not isLocalLeader(leaderName) then
    followSelfSuppressed = false
    return false
  end
  if not followSelfSuppressed then
    followSelfSuppressed = true
    -- Cancel pending follow retries when follow target is yourself.
    follow3CycleId = follow3CycleId + 1
    follow3LastLeaderDir = nil
    followRuntimeState.nextMoveSeq()
    followRuntimeState.lastLeaderPos = nil
    followRuntimeState.lastLeaderSeenAt = 0
    resetRouteFallbackState(true)
  end
  return true
end

local function getNearestRouteWaypointIndex(fromPos, points)
  if type(points) ~= "table" or #points == 0 then
    return nil
  end
  if not fromPos then
    return 1
  end
  local bestIdx = 1
  local bestScore = nil
  for idx, p in ipairs(points) do
    local dx = math.abs((fromPos.x or 0) - (p.x or 0))
    local dy = math.abs((fromPos.y or 0) - (p.y or 0))
    local dz = math.abs((fromPos.z or 0) - (p.z or 0))
    local score = dx + dy + (dz * 1000)
    if not bestScore or score < bestScore then
      bestScore = score
      bestIdx = idx
    end
  end
  return bestIdx
end

local function runRouteFallbackStep(nowMs)
  if not cfg.routeFallback or not cfg.routeFallback.enabled then
    return false
  end
  local points = cfg.routeFallback.waypoints
  if type(points) ~= "table" or #points == 0 then
    return false
  end
  local me = pos()
  if not me or not isMapPos(me) then
    return false
  end

  if not routeFallbackState.active then
    routeFallbackState.active = true
    routeFallbackState.index = getNearestRouteWaypointIndex(me, points) or 1
    routeFallbackState.lastStepAt = 0
  end

  local stepDelay = clampNumber(cfg.routeFallback.stepMs, 80, 1000, 220)
  if nowMs - routeFallbackState.lastStepAt < stepDelay then
    return true
  end

  local idx = routeFallbackState.index
  if not idx or idx < 1 or idx > #points then
    idx = 1
  end

  local target = points[idx]
  if not target then
    return false
  end

  if me.z == target.z and getDistanceBetween(me, target) <= 1 then
    idx = idx + 1
    if idx > #points then
      idx = 1
    end
    routeFallbackState.index = idx
    target = points[idx]
    if not target then
      return false
    end
  else
    routeFallbackState.index = idx
  end

  routeFallbackState.lastStepAt = nowMs
  local walked = follow3AutoWalk(target)
  if not walked then
    tryApproachDoor(target)
    if me.z ~= target.z then
      local dirKey = target.z < me.z and "Up" or "Down"
      follow3UseAroundChangers(me, dirKey)
    end
  end
  return true
end

local function handleFollow3Movement(creature, newPos, oldPos)
  if not cfg.enabled or not isFollowSystemEnabled() then
    return
  end
  local leaderName = getFollowLeaderName()
  if leaderName == "" then
    return
  end
  if shouldSuppressFollowForSelf() then
    return
  end
  if not creature or not creature.getName then
    return
  end
  local creatureName = creature:getName()
  if not creatureName then
    return
  end
  local creatureLower = creatureName:lower()
  local leaderLower = leaderName:lower()

  local localName = ""
  if type(name) == "function" then
    localName = trim(name() or "")
  end
  if newPos and oldPos and localName ~= "" and creatureLower == localName:lower()
    and getCreatureByName(leaderName) == nil and newPos.z > oldPos.z then
    say('exani tera')
    follow3UseAroundAll(pos())
  end

  if creatureLower ~= leaderLower then
    return
  end

  local nowMs = timeMs()
  local moveSeq = followRuntimeState.nextMoveSeq()
  if creature.getDirection then
    local dir = creature:getDirection()
    if dir ~= nil then
      follow3LastLeaderDir = dir
    end
  end
  if newPos and isMapPos(newPos) then
    followRuntimeState.cacheLeaderPos(newPos, nowMs)
  elseif oldPos and isMapPos(oldPos) then
    followRuntimeState.cacheLeaderPos(oldPos, nowMs)
  end
  resetRouteFallbackState(true)

  local oldTarget = oldPos and copyPos(oldPos) or nil
  local newTarget = newPos and copyPos(newPos) or nil

  if not newPos then
    if oldTarget then
      scheduleWithPing(200, function()
        if not followRuntimeState.isMoveSeqCurrent(moveSeq) then
          return
        end
        local walked = follow3AutoWalk(oldTarget)
        if not walked then
          tryApproachDoor(oldTarget)
        end
      end)
      follow3StartUseCycle(oldTarget, nil, nil, leaderName)
    end
    return
  end

  if not oldPos then
    return
  end

  if oldPos.z == newPos.z then
    scheduleWithPing(300, function()
      if not followRuntimeState.isMoveSeqCurrent(moveSeq) then
        return
      end
      local tile = g_map.getTile({ x = oldPos.x, y = oldPos.y, z = oldPos.z })
      if tile then
        local topThing = tile:getTopThing()
        if not tile:isWalkable() and topThing then
          g_game.use(topThing)
        end
      end
    end)
    local walked = follow3AutoWalk({ x = oldPos.x, y = oldPos.y, z = oldPos.z })
    scheduleWithPing(200, function()
      if not followRuntimeState.isMoveSeqCurrent(moveSeq) then
        return
      end
      tryUseDoorsAround(pos())
    end)
    if not walked then
      tryApproachDoor({ x = oldPos.x, y = oldPos.y, z = oldPos.z })
    end
    return
  end

  local dirKey = getDirKey(oldTarget, newTarget)
  if oldTarget then
    local walked = follow3AutoWalk(oldTarget)
    if not walked then
      tryApproachDoor(oldTarget)
    end
  end
  for i = 1, 6 do
    scheduleWithPing(i * 200, function()
      if not followRuntimeState.isMoveSeqCurrent(moveSeq) then
        return
      end
      if oldTarget then
        local walked = follow3AutoWalk(oldTarget)
        if not walked then
          tryApproachDoor(oldTarget)
        end
      end
      if oldTarget and newTarget and getDistanceBetween(pos(), oldTarget) == 0 and (posz() > newTarget.z and getCreatureByName(leaderName) == nil) then
        say('exani tera')
      end
    end)
  end
  if oldTarget then
    follow3StartUseCycle(oldTarget, dirKey, newTarget, leaderName)
  end
end

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
    padding-bottom: 8
    vertical-scrollbar: panelScroll
    layout:
      type: verticalBox
      spacing: 4

NovoFollowWindow < MainWindow
  !text: tr('Navigation')
  size: 560 600
  visible: false
  @onEscape: self:hide()

  tPanel
    id: contentPanel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonPanel.top
    margin-top: 5
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
      id: helpButton
      text: Ajuda / Help
      size: 80 18

    Button
      id: commandsButton
      text: Commands
      size: 80 18

    Button
      id: closeButton
      text: Fechar
      size: 80 18
      @onClick: self:getParent():getParent():hide()

RouteFallbackWindow < MainWindow
  !text: tr('Fallback Route')
  size: 540 430
  visible: false
  @onEscape: self:hide()

  Panel
    id: routeContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonPanel.top
    margin-top: 6
    margin-left: 8
    margin-right: 8

    Label
      id: routeInfoLabel
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 14
      text-align: center
      text: Cole os waypoints (formato: goto:x,y,z)

    TextEdit
      id: routeTextEdit
      anchors.top: routeInfoLabel.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: routeStatusLabel.top
      margin-top: 4
      margin-bottom: 4
      multiline: true
      text-align: left

    Label
      id: routeStatusLabel
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 14
      text-align: center
      text: -

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
      id: clearButton
      text: Limpar
      size: 80 18

    Button
      id: saveButton
      text: Salvar
      size: 80 18

    Button
      id: closeButton
      text: Fechar
      size: 80 18
      @onClick: self:getParent():getParent():hide()

ComboSetupWindow < MainWindow
  !text: tr('Combo Setup')
  size: 420 286
  visible: false
  @onEscape: self:hide()

  Panel
    id: comboContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonPanel.top
    margin-top: 6
    margin-left: 8
    margin-right: 8
    layout:
      type: verticalBox
      spacing: 4

    Panel
      id: comboTopRow
      height: 22
      layout:
        type: horizontalBox
        spacing: 6
      fit-children: true

      BotSwitch
        id: comboEnableSwitch
        text-align: center
        width: 120
        height: 18
        text: Combo

      Button
        id: comboModeButton
        text: Mode: Spell
        width: 120
        height: 18

    Label
      id: comboLeaderInfoLabel
      height: 14
      text-align: left
      text: Leader: -

    Label
      id: comboTriggerWordLabel
      height: 14
      text-align: left
      text: Trigger Word:

    TextEdit
      id: comboTriggerWordEdit
      height: 20
      width: 392
      text-align: center

    Label
      id: comboSpellLabel
      height: 14
      text-align: left
      text: Combo Spell:

    TextEdit
      id: comboSpellEdit
      height: 20
      width: 392
      text-align: center

    Label
      id: comboRuneLabel
      height: 14
      text-align: left
      text: Combo Rune ID:

    SpinBox
      id: comboRuneSpin
      height: 20
      width: 120
      minimum: 100
      maximum: 100000
      step: 1
      editable: true
      focusable: true

    Label
      id: comboStatusLabel
      height: 14
      text-align: left
      text: Target sync por projetil + trigger por palavra

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

NavigationHelpWindow < MainWindow
  !text: tr('Navigation Help')
  size: 640 580
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

NavigationCommandsWindow < MainWindow
  !text: tr('Navigation Commands')
  size: 640 560
  visible: false
  @onEscape: self:hide()

  Panel
    id: commandsContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonPanel.top
    margin-top: 6
    margin-left: 8
    margin-right: 8

    VerticalScrollBar
      id: commandsScroll
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      step: 28
      pixels-scroll: true

    ScrollablePanel
      id: commandsScrollContent
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-right: 10
      padding-top: 3
      padding-bottom: 3
      padding-left: 4
      vertical-scrollbar: commandsScroll
      layout:
        type: verticalBox
        spacing: 4

      Label
        id: commandsTextLabel
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

HudControlSwitch < BotSwitch
  margin-top: 0
  height: 20
  image-color: #4e4e4e
  $on:
    image-color: #4e4e4e
  $!on:
    image-color: #4e4e4e

NavigationCommandHud < UIWidget
  size: 181 170
  padding: 1 1 1 1
  visible: false
  focusable: false
  phantom: false
  draggable: false
  image-border: 1
  background: #00000066
  border-width: 1
  border-color: #202327

  Label
    id: hudTitle
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 16
    background-color: #d4af37
    text-align: center
    color: #1a1a1a
    text: Controls

  Button
    id: hudCollapseButton
    anchors.right: hudTitle.right
    anchors.verticalCenter: hudTitle.verticalCenter
    margin-right: 1
    size: 14 14
    text: -
    font: verdana-11px-rounded

  HorizontalSeparator
    id: hudSeparator
    anchors.top: hudTitle.bottom
    anchors.left: parent.left
    anchors.right: parent.right

  Panel
    id: hudButtonsPanel
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-left: 2
    margin-right: 2
    margin-bottom: 2
    border-width: 1
    border-color: #202327
    background: #00000066
    padding: 1

    Panel
      id: hudMarksPanel
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 12
      layout:
        type: verticalBox
        spacing: 0

      Label
        id: hudMark1
        height: 20
        text-align: center
        text: K
        color: #c9901a

      Label
        id: hudMark2
        height: 20
        text-align: center
        text: E
        color: #d9a62b

      Label
        id: hudMark3
        height: 20
        text-align: center
        text: L
        color: #e9bc3d

      Label
        id: hudMark4
        height: 20
        text-align: center
        text: U
        color: #ffd45a

      Label
        id: hudMark5
        height: 20
        text-align: center
        text: S
        color: #e9bc3d

      Label
        id: hudMark6
        height: 20
        text-align: center
        text: O
        color: #d9a62b

      Label
        id: hudMark7
        height: 20
        text-align: center
        text: N
        color: #c9901a

    Panel
      id: hudGridPanel
      anchors.left: hudMarksPanel.right
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      margin-left: 2
      layout:
        type: verticalBox
        spacing: 0

      HudControlSwitch
        id: hudCmdSwitch1
        height: 20
        margin-top: 0
        background-color: #00000066
        border-width: 1
        border-color: #202327
        color: #f1f5f9
        text-align: center
        font: verdana-11px-rounded
        text: Follow

      HudControlSwitch
        id: hudCmdSwitch2
        height: 20
        margin-top: 0
        background-color: #00000066
        border-width: 1
        border-color: #202327
        color: #f1f5f9
        text-align: center
        font: verdana-11px-rounded
        text: CaveBot

      HudControlSwitch
        id: hudCmdSwitch3
        height: 20
        margin-top: 0
        background-color: #00000066
        border-width: 1
        border-color: #202327
        color: #f1f5f9
        text-align: center
        font: verdana-11px-rounded
        text: TargetBot

      HudControlSwitch
        id: hudCmdSwitch4
        height: 20
        margin-top: 0
        background-color: #00000066
        border-width: 1
        border-color: #202327
        color: #f1f5f9
        text-align: center
        font: verdana-11px-rounded
        text: SD

      HudControlSwitch
        id: hudCmdSwitch5
        height: 20
        margin-top: 0
        background-color: #00000066
        border-width: 1
        border-color: #202327
        color: #f1f5f9
        text-align: center
        font: verdana-11px-rounded
        text: Paralyze

      HudControlSwitch
        id: hudCmdSwitch6
        height: 20
        margin-top: 0
        background-color: #00000066
        border-width: 1
        border-color: #202327
        color: #f1f5f9
        text-align: center
        font: verdana-11px-rounded
        text: AntiPush

      HudControlSwitch
        id: hudCmdSwitch7
        height: 20
        margin-top: 0
        background-color: #00000066
        border-width: 1
        border-color: #202327
        color: #f1f5f9
        text-align: center
        font: verdana-11px-rounded
        text: Combo

HudButtonSetupWindow < MainWindow
  !text: tr('HUD Button Setup')
  size: 420 320
  visible: false
  @onEscape: self:hide()

  Panel
    id: hudButtonSetupContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonPanel.top
    margin-top: 6
    margin-left: 8
    margin-right: 8
    layout:
      type: verticalBox
      spacing: 4

    Label
      id: hudButtonSetupTitle
      height: 14
      text-align: left
      text: Configurar atalho

    Label
      id: hudButtonNameLabel
      height: 14
      text-align: left
      text: Nome do botao:

    TextEdit
      id: hudButtonNameEdit
      height: 20
      width: 380
      text-align: center

    Label
      id: hudButtonModeLabel
      height: 14
      text-align: left
      text: Tipo:

    ComboBox
      id: hudButtonModeCombo
      width: 140

    Label
      id: hudButtonOnLabel
      height: 14
      text-align: left
      text: Comando quando ON:

    TextEdit
      id: hudButtonOnEdit
      height: 20
      width: 380
      text-align: center

    Label
      id: hudButtonOffLabel
      height: 14
      text-align: left
      text: Comando quando OFF:

    TextEdit
      id: hudButtonOffEdit
      height: 20
      width: 380
      text-align: center

    Label
      id: hudButtonDirectLabel
      height: 14
      text-align: left
      text: Comando direto (1 clique):

    TextEdit
      id: hudButtonDirectEdit
      height: 20
      width: 380
      text-align: center

    Label
      id: hudButtonHintLabel
      height: 14
      text-align: left
      text: Use {trigger} para enviar a trigger word do combo.

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
      id: saveButton
      text: Salvar
      size: 80 18

    Button
      id: closeButton
      text: Fechar
      size: 80 18
      @onClick: self:getParent():getParent():hide()
]])

local mainUi = setupUI([[
Panel
  height: 20
  margin-top: 3

  Button
    id: setupButton
    text: Navigation
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 18
    font: verdana-11px-rounded
]])

local windowParent = g_ui.getRootWidget()
local window = g_ui.createWidget("NovoFollowWindow", windowParent)
window:hide()
local routeWindow = g_ui.createWidget("RouteFallbackWindow", windowParent)
routeWindow:hide()
local comboWindow = g_ui.createWidget("ComboSetupWindow", windowParent)
comboWindow:hide()
local helpWindow = g_ui.createWidget("NavigationHelpWindow", windowParent)
helpWindow:hide()
local commandsWindow = g_ui.createWidget("NavigationCommandsWindow", windowParent)
commandsWindow:hide()
NovoFollowHudButtonSetupWindow = g_ui.createWidget("HudButtonSetupWindow", windowParent)
NovoFollowHudButtonSetupWindow:hide()
NovoFollowPrevHud = windowParent and windowParent.getChildById and windowParent:getChildById("novoFollowCommandHud") or nil
if NovoFollowPrevHud and NovoFollowPrevHud.destroy then
  NovoFollowPrevHud:destroy()
end
NovoFollowCommandHud = g_ui.createWidget("NavigationCommandHud", windowParent)
if NovoFollowCommandHud then
  NovoFollowCommandHud:setId("novoFollowCommandHud")
  NovoFollowCommandHud:hide()
  cfg.hudSetup = cfg.hudSetup or {}
  cfg.hudSetup.posX = clampNumber(
    cfg.hudSetup.posX,
    0,
    5000,
    ((windowParent and windowParent.getWidth and windowParent:getWidth()) or 1200) - 190
  )
  cfg.hudSetup.posY = clampNumber(cfg.hudSetup.posY, 0, 5000, 160)
  if NovoFollowCommandHud.setPosition then
    NovoFollowCommandHud:setPosition({ x = cfg.hudSetup.posX, y = cfg.hudSetup.posY })
  end
end
local contentRoot = window.contentPanel and window.contentPanel:getChildById("panelContent") or window.contentPanel
local content = contentRoot
local headerRow = setupUI([[
Panel
  id: headerRow
  height: 0
  margin-bottom: 0
]], contentRoot)

local settingsPanel = contentRoot

do
  setupUI([[
Panel
  id: identityLabelsRow
  height: 14
  margin-top: 2
  layout:
    type: horizontalBox
    spacing: 6
  fit-children: true

  Label
    id: leaderNameLabel
    text: Nav Leader Name:
    text-align: center
    width: 150

  Label
    id: followNameLabel
    text: Follow Name:
    text-align: center
    width: 150

  Label
    id: mcNamesLabel
    text: MC Names:
    text-align: center
    width: 150
]], settingsPanel)

  setupUI([[
Panel
  id: identityInputsRow
  height: 22
  layout:
    type: horizontalBox
    spacing: 6
  fit-children: true

  Panel
    id: navLeaderInputGroup
    height: 20
    width: 150
    layout:
      type: horizontalBox
      spacing: 4
    fit-children: true

    SmallBotSwitch
      id: navLeaderSwitch
      width: 30
      height: 20
      text-align: center
      text: ON

    TextEdit
      id: leaderNameEdit
      height: 20
      width: 116
      text-align: center

  Panel
    id: followInputGroup
    height: 20
    width: 150
    layout:
      type: horizontalBox
      spacing: 4
    fit-children: true

    SmallBotSwitch
      id: followSwitch
      width: 30
      height: 20
      text-align: center
      text: ON

    TextEdit
      id: followNameEdit
      height: 20
      width: 116
      text-align: center

  TextEdit
    id: pauseMcNamesEdit
    height: 20
    width: 150
    text-align: center
]], settingsPanel)

  setupUI([[
Panel
  id: controlRow
  height: 22
  margin-top: 4
  layout:
    type: horizontalBox
    spacing: 6
  fit-children: true

  BotSwitch
    id: pauseCavebotSwitch
    text-align: center
    width: 130
    height: 18
    text: Pause CaveBot

  Label
    id: pauseDistanceLabel
    text: Dist:
    width: 28
    text-align: center

  SpinBox
    id: pauseDistanceSpin
    width: 40
    minimum: 1
    maximum: 20
    step: 1
    editable: true
    focusable: true

  BotSwitch
    id: pingAutoSwitch
    text-align: center
    width: 90
    height: 18
    text: Auto Ping

  Label
    id: pingManualLabel
    text: Ping:
    width: 28
    text-align: center

  SpinBox
    id: pingManualSpin
    width: 58
    minimum: 0
    maximum: 1000
    step: 10
    editable: true
    focusable: true

  Button
    id: comboSetupButton
    text: Combo
    width: 70
    height: 18
]], settingsPanel)

  setupUI([[
Panel
  id: routeFallbackRow
  height: 22
  margin-top: 2
  layout:
    type: horizontalBox
    spacing: 6
  fit-children: true

  BotSwitch
    id: routeFallbackSwitch
    text-align: center
    width: 130
    height: 18
    text: Route Fallback

  Label
    id: routeFallbackStepLabel
    text: Step:
    width: 30
    text-align: center

  SpinBox
    id: routeFallbackStepSpin
    width: 54
    minimum: 80
    maximum: 1000
    step: 10
    editable: true
    focusable: true

  Label
    id: routeFallbackStepMsLabel
    text: ms
    width: 20
    text-align: center

  Button
    id: routeFallbackEditButton
    text: Edit Route
    width: 110
    height: 18
]], settingsPanel)

  setupUI([[
Panel
  id: hudControlsRow
  height: 22
  margin-top: 2
  layout:
    type: horizontalBox
    spacing: 4
  fit-children: true

  Button
    id: hudSetupToggleButton
    text: HUD Setup: OFF
    width: 104
    height: 18

  Label
    id: hudPosXLabel
    text: X:
    width: 20
    text-align: center

  SpinBox
    id: hudPosXSpin
    width: 58
    minimum: 0
    maximum: 5000
    step: 1
    editable: true
    focusable: true

  Label
    id: hudPosYLabel
    text: Y:
    width: 20
    text-align: center

  SpinBox
    id: hudPosYSpin
    width: 58
    minimum: 0
    maximum: 5000
    step: 1
    editable: true
    focusable: true

  Label
    id: hudSendModeLabel
    text: Envio:
    width: 40
    text-align: center

  ComboBox
    id: hudSendModeCombo
    width: 74

  Label
    id: hudGuildChannelLabel
    text: Canal:
    width: 36
    text-align: center

  TextEdit
    id: hudGuildChannelEdit
    width: 90
    height: 20
    text-align: center
]], settingsPanel)

  setupUI([[
HorizontalSeparator
  margin-top: 2
]], settingsPanel)

  setupUI([[
Panel
  id: toolsLabelRow
  height: 14
  layout:
    type: horizontalBox
    spacing: 8
  fit-children: true

  Label
    id: ropeIdLabel
    text: Rope ID:
    text-align: center
    width: 150

  Label
    id: shovelIdLabel
    text: Shovel ID:
    text-align: center
    width: 150

  Label
    id: macheteIdLabel
    text: Machete ID:
    text-align: center
    width: 150
]], settingsPanel)

  setupUI([[
Panel
  id: toolsInputRow
  height: 22
  layout:
    type: horizontalBox
    spacing: 8
  fit-children: true

  TextEdit
    id: ropeIdEdit
    height: 20
    width: 150
    text-align: center

  TextEdit
    id: shovelIdEdit
    height: 20
    width: 150
    text-align: center

  TextEdit
    id: macheteIdEdit
    height: 20
    width: 150
    text-align: center
]], settingsPanel)

  setupUI([[
HorizontalSeparator
  margin-top: 6
]], settingsPanel)

  setupUI([[
Panel
  id: floorLabelRow1
  height: 14
  margin-top: 2
  layout:
    type: horizontalBox
    spacing: 8
  fit-children: true

  Label
    id: laddersUpLabel
    text: Ladders Up
    text-align: center
    width: 230

  Label
    id: laddersDownLabel
    text: Ladders Down
    text-align: center
    width: 230
]], settingsPanel)

  setupUI([[
Panel
  id: floorInputRow1
  height: 38
  layout:
    type: horizontalBox
    spacing: 8
  fit-children: true

  BotContainer
    id: laddersUpContainer
    height: 36
    width: 230

  BotContainer
    id: laddersDownContainer
    height: 36
    width: 230
]], settingsPanel)

  setupUI([[
Panel
  id: floorLabelRow2
  height: 14
  margin-top: 2
  layout:
    type: horizontalBox
    spacing: 8
  fit-children: true

  Label
    id: holesDownLabel
    text: Holes Down
    text-align: center
    width: 230

  Label
    id: ropeSpotsUpLabel
    text: Rope Spots Up
    text-align: center
    width: 230
]], settingsPanel)

  setupUI([[
Panel
  id: floorInputRow2
  height: 38
  layout:
    type: horizontalBox
    spacing: 8
  fit-children: true

  BotContainer
    id: holesDownContainer
    height: 36
    width: 230

  BotContainer
    id: ropeSpotsUpContainer
    height: 36
    width: 230
]], settingsPanel)

  setupUI([[
Panel
  id: floorLabelRow3
  height: 14
  margin-top: 2
  layout:
    type: horizontalBox
    spacing: 8
  fit-children: true

  Label
    id: stairsUpLabel
    text: Stairs Up
    text-align: center
    width: 230

  Label
    id: stairsDownLabel
    text: Stairs Down
    text-align: center
    width: 230
]], settingsPanel)

  setupUI([[
Panel
  id: floorInputRow3
  height: 38
  layout:
    type: horizontalBox
    spacing: 8
  fit-children: true

  BotContainer
    id: stairsUpContainer
    height: 36
    width: 230

  BotContainer
    id: stairsDownContainer
    height: 36
    width: 230
]], settingsPanel)

  setupUI([[
Panel
  id: floorLabelRow4
  height: 14
  margin-top: 2
  layout:
    type: horizontalBox
    spacing: 8
  fit-children: true

  Label
    id: sewersDownLabel
    text: Sewers Down
    text-align: center
    width: 230

  Label
    text: ""
    text-align: center
    width: 230
]], settingsPanel)

  setupUI([[
Panel
  id: floorInputRow4
  height: 40
  layout:
    type: horizontalBox
    spacing: 8
  fit-children: true

  BotContainer
    id: sewersDownContainer
    height: 36
    width: 230

  Panel
    width: 230
    height: 36
]], settingsPanel)

  setupUI([[
Panel
  id: targetsLabelRow
  height: 14
  margin-top: 2
  layout:
    type: horizontalBox
    spacing: 8
  fit-children: true

  Label
    id: useIdsLabel
    text: Use IDs
    text-align: center
    width: 230

  Label
    id: doorIdsLabel
    text: Door IDs (closed)
    text-align: center
    width: 230
]], settingsPanel)

  setupUI([[
Panel
  id: targetsInputRow
  height: 40
  layout:
    type: horizontalBox
    spacing: 8
  fit-children: true

  BotContainer
    id: useTargetsContainer
    height: 36
    width: 230

  BotContainer
    id: doorTargetsContainer
    height: 36
    width: 230
]], settingsPanel)

  setupUI([[
HorizontalSeparator
  margin-top: 6
]], settingsPanel)
end

content.headerRow = headerRow
content.enableSwitch = headerRow.enableSwitch or headerRow:getChildById("enableSwitch")
content.settingsPanel = settingsPanel

local function ensurePanelHeight(targetPanel)
  if not targetPanel or not targetPanel.getChildren or not targetPanel.setHeight then
    return
  end
  local total = 0
  for _, child in ipairs(targetPanel:getChildren() or {}) do
    if child.isVisible and not child:isVisible() then
      -- ignore hidden
    elseif child.getHeight then
      total = total + (child:getHeight() or 0)
    end
  end
  if total > 0 then
    targetPanel:setHeight(total + 12)
  end
end

local function findChildById(root, targetId)
  if not root or not targetId then
    return nil
  end
  if root.getId and root:getId() == targetId then
    return root
  end
  if not root.getChildren then
    return nil
  end
  for _, child in ipairs(root:getChildren() or {}) do
    if child.getId and child:getId() == targetId then
      return child
    end
    local found = findChildById(child, targetId)
    if found then
      return found
    end
  end
  return nil
end

local function bindContentId(name)
  if not content[name] then
    content[name] = findChildById(content, name)
  end
end

for _, id in ipairs({
  "headerRow",
  "enableSwitch",
  "title",
  "settingsPanel",
  "leaderNameLabel",
  "followNameLabel",
  "navLeaderSwitch",
  "followSwitch",
  "mcNamesLabel",
  "leaderNameEdit",
  "followNameEdit",
  "pauseCavebotSwitch",
  "pauseDistanceLabel",
  "pauseDistanceSpin",
  "pauseMcNamesEdit",
  "pingAutoSwitch",
  "pingManualLabel",
  "pingManualSpin",
  "comboSetupButton",
  "routeFallbackSwitch",
  "routeFallbackStepLabel",
  "routeFallbackStepSpin",
  "routeFallbackStepMsLabel",
  "routeFallbackEditButton",
  "hudSetupToggleButton",
  "hudPosXLabel",
  "hudPosXSpin",
  "hudPosYLabel",
  "hudPosYSpin",
  "hudSendModeLabel",
  "hudSendModeCombo",
  "hudGuildChannelLabel",
  "hudGuildChannelEdit",
  "ropeIdLabel",
  "shovelIdLabel",
  "macheteIdLabel",
  "ropeIdEdit",
  "shovelIdEdit",
  "macheteIdEdit",
  "laddersUpLabel",
  "laddersDownLabel",
  "laddersUpContainer",
  "laddersDownContainer",
  "holesDownLabel",
  "holesDownContainer",
  "ropeSpotsUpLabel",
  "ropeSpotsUpContainer",
  "stairsUpLabel",
  "stairsUpContainer",
  "stairsDownLabel",
  "stairsDownContainer",
  "sewersDownLabel",
  "sewersDownContainer",
  "useIdsLabel",
  "doorIdsLabel",
  "useTargetsContainer",
  "doorTargetsContainer"
}) do
  bindContentId(id)
end

local routeUi = {
  infoLabel = findChildById(routeWindow, "routeInfoLabel"),
  textEdit = findChildById(routeWindow, "routeTextEdit"),
  statusLabel = findChildById(routeWindow, "routeStatusLabel"),
  clearButton = findChildById(routeWindow, "clearButton"),
  saveButton = findChildById(routeWindow, "saveButton"),
  closeButton = findChildById(routeWindow, "closeButton")
}

local comboUi = {
  enableSwitch = findChildById(comboWindow, "comboEnableSwitch"),
  modeButton = findChildById(comboWindow, "comboModeButton"),
  leaderInfoLabel = findChildById(comboWindow, "comboLeaderInfoLabel"),
  triggerWordLabel = findChildById(comboWindow, "comboTriggerWordLabel"),
  triggerWordEdit = findChildById(comboWindow, "comboTriggerWordEdit"),
  spellLabel = findChildById(comboWindow, "comboSpellLabel"),
  spellEdit = findChildById(comboWindow, "comboSpellEdit"),
  runeLabel = findChildById(comboWindow, "comboRuneLabel"),
  runeSpin = findChildById(comboWindow, "comboRuneSpin"),
  statusLabel = findChildById(comboWindow, "comboStatusLabel"),
  closeButton = findChildById(comboWindow, "closeButton")
}

local helpUi = {
  openButton = findChildById(window, "helpButton"),
  scrollBar = findChildById(helpWindow, "helpScroll"),
  scrollContent = findChildById(helpWindow, "helpScrollContent"),
  textLabel = findChildById(helpWindow, "helpTextLabel"),
  closeButton = findChildById(helpWindow, "closeButton")
}

local commandsUi = {
  openButton = findChildById(window, "commandsButton"),
  scrollBar = findChildById(commandsWindow, "commandsScroll"),
  scrollContent = findChildById(commandsWindow, "commandsScrollContent"),
  textLabel = findChildById(commandsWindow, "commandsTextLabel"),
  closeButton = findChildById(commandsWindow, "closeButton"),
  hudRoot = NovoFollowCommandHud,
  hudTitle = findChildById(NovoFollowCommandHud, "hudTitle"),
  hudSeparator = findChildById(NovoFollowCommandHud, "hudSeparator"),
  hudButtonsPanel = findChildById(NovoFollowCommandHud, "hudButtonsPanel"),
  hudMarksPanel = findChildById(NovoFollowCommandHud, "hudMarksPanel"),
  hudGridPanel = findChildById(NovoFollowCommandHud, "hudGridPanel"),
  hudCollapseButton = findChildById(NovoFollowCommandHud, "hudCollapseButton"),
  hudSetupWindow = NovoFollowHudButtonSetupWindow,
  hudPosUiSyncing = false,
  hudButtons = {
    findChildById(NovoFollowCommandHud, "hudCmdSwitch1"),
    findChildById(NovoFollowCommandHud, "hudCmdSwitch2"),
    findChildById(NovoFollowCommandHud, "hudCmdSwitch3"),
    findChildById(NovoFollowCommandHud, "hudCmdSwitch4"),
    findChildById(NovoFollowCommandHud, "hudCmdSwitch5"),
    findChildById(NovoFollowCommandHud, "hudCmdSwitch6"),
    findChildById(NovoFollowCommandHud, "hudCmdSwitch7")
  },
  hudMarks = {
    findChildById(NovoFollowCommandHud, "hudMark1"),
    findChildById(NovoFollowCommandHud, "hudMark2"),
    findChildById(NovoFollowCommandHud, "hudMark3"),
    findChildById(NovoFollowCommandHud, "hudMark4"),
    findChildById(NovoFollowCommandHud, "hudMark5"),
    findChildById(NovoFollowCommandHud, "hudMark6"),
    findChildById(NovoFollowCommandHud, "hudMark7")
  },
  hudSetupTitle = findChildById(NovoFollowHudButtonSetupWindow, "hudButtonSetupTitle"),
  hudSetupNameEdit = findChildById(NovoFollowHudButtonSetupWindow, "hudButtonNameEdit"),
  hudSetupModeCombo = findChildById(NovoFollowHudButtonSetupWindow, "hudButtonModeCombo"),
  hudSetupOnEdit = findChildById(NovoFollowHudButtonSetupWindow, "hudButtonOnEdit"),
  hudSetupOffEdit = findChildById(NovoFollowHudButtonSetupWindow, "hudButtonOffEdit"),
  hudSetupDirectEdit = findChildById(NovoFollowHudButtonSetupWindow, "hudButtonDirectEdit"),
  hudSetupSaveButton = findChildById(NovoFollowHudButtonSetupWindow, "saveButton"),
  hudSetupCloseButton = findChildById(NovoFollowHudButtonSetupWindow, "closeButton")
}

commandsUi.hudMarkLetters = { "K", "E", "L", "U", "S", "O", "N" }
commandsUi.hudMarkWaveColors = { "#c9901a", "#d9a62b", "#e9bc3d", "#ffd45a", "#e9bc3d", "#d9a62b", "#c9901a" }
commandsUi.hudButtonFallbackNames = { "Follow", "CaveBot", "TargetBot", "SD", "Paralyze", "AntiPush", "Combo" }
commandsUi.hudButtonBaseStyle = { bg = "#00000066", border = "#202327" }
commandsUi.hudButtonImageColor = "#4e4e4e"
commandsUi.hudButtonStyles = {
  off = { text = "#ff4040" },
  on = { text = "#2cff2c" },
  direct = { text = "#f1f5f9" }
}

commandsUi.applyHudButtonVisual = function(button, def)
  if not button then
    return
  end
  local baseStyle = commandsUi.hudButtonBaseStyle or { bg = "#00000066", border = "#202327" }
  local style = commandsUi.hudButtonStyles and commandsUi.hudButtonStyles.off or { text = "#f1f5f9" }
  if def and def.mode == "direct" then
    style = commandsUi.hudButtonStyles and commandsUi.hudButtonStyles.direct or style
  elseif def and def.state == true then
    style = commandsUi.hudButtonStyles and commandsUi.hudButtonStyles.on or style
  end

  if button.setBackgroundColor then
    button:setBackgroundColor(baseStyle.bg)
  end
  if button.setMarginTop then
    button:setMarginTop(0)
  end
  if button.setBorderColor then
    button:setBorderColor(baseStyle.border)
  end
  if button.setImageColor then
    button:setImageColor(commandsUi.hudButtonImageColor or "#4e4e4e")
  end
  if button.setColor then
    button:setColor(style.text or "#f1f5f9")
  end
end

commandsUi.flashHudComboFeedback = function(button, def)
  if not button then
    return
  end
  local token = (button._hudFlashToken or 0) + 1
  button._hudFlashToken = token
  local step = 0
  local maxSteps = 6
  local normalColor = "#f1f5f9"
  local flashColor = "#2cff2c"

  local function tick()
    if not button or (button.isDestroyed and button:isDestroyed()) then
      return
    end
    if button._hudFlashToken ~= token then
      return
    end
    step = step + 1
    if button.setColor then
      button:setColor((step % 2 == 1) and flashColor or normalColor)
    end
    if step < maxSteps then
      schedule(90, tick)
      return
    end
    if commandsUi and commandsUi.applyHudButtonVisual then
      commandsUi.applyHudButtonVisual(button, def)
    end
  end

  tick()
end

commandsUi.ensureHudRows = function()
  local baseStyle = commandsUi.hudButtonBaseStyle or { bg = "#00000066", border = "#202327" }
  for index = 1, #(commandsUi.hudMarkLetters or {}) do
    local mark = commandsUi.hudMarks[index]
    if mark and mark.isDestroyed and mark:isDestroyed() then
      mark = nil
      commandsUi.hudMarks[index] = nil
    end
    if not mark and commandsUi.hudMarksPanel then
      local markSpec = string.format([[
Label
  id: hudMark%d
  height: 20
  text-align: center
  text: %s
  color: %s
]], index, (commandsUi.hudMarkLetters and commandsUi.hudMarkLetters[index]) or "", (commandsUi.hudMarkWaveColors and commandsUi.hudMarkWaveColors[index]) or "#d9a62b")
      mark = setupUI(markSpec, commandsUi.hudMarksPanel)
      commandsUi.hudMarks[index] = mark
    end
    if mark and mark.setText then
      mark:setText((commandsUi.hudMarkLetters and commandsUi.hudMarkLetters[index]) or "")
    end
    if mark and mark.setColor then
      mark:setColor((commandsUi.hudMarkWaveColors and commandsUi.hudMarkWaveColors[index]) or "#d9a62b")
    end
    if mark and mark.setVisible then
      mark:setVisible(true)
    end
  end

  for index = 1, #(commandsUi.hudButtonFallbackNames or {}) do
    local button = commandsUi.hudButtons[index]
    if button and button.isDestroyed and button:isDestroyed() then
      button = nil
      commandsUi.hudButtons[index] = nil
    end
    if not button and commandsUi.hudGridPanel then
      local buttonSpec = string.format([[
HudControlSwitch
  id: hudCmdSwitch%d
  height: 20
  margin-top: 0
  background-color: %s
  border-width: 1
  border-color: %s
  color: #f1f5f9
  text-align: center
  font: verdana-11px-rounded
  text: %s
]], index, baseStyle.bg, baseStyle.border, (commandsUi.hudButtonFallbackNames and commandsUi.hudButtonFallbackNames[index]) or ("Cmd " .. tostring(index)))
      button = setupUI(buttonSpec, commandsUi.hudGridPanel)
      commandsUi.hudButtons[index] = button
    end
    if button and button.setVisible then
      button:setVisible(true)
    end
  end
end

commandsUi.refreshHudToggleButton = function()
  if not content or not content.hudSetupToggleButton then
    return
  end
  local isVisible = cfg.hudSetup and cfg.hudSetup.visible == true
  content.hudSetupToggleButton:setText(isVisible and "HUD Setup: ON" or "HUD Setup: OFF")
end

commandsUi.syncHudPosInputs = function()
  if not content then
    return
  end
  cfg.hudSetup = cfg.hudSetup or {}
  local maxX = 5000
  local maxY = 5000
  if commandsUi and commandsUi.getHudPositionBounds then
    maxX, maxY = commandsUi.getHudPositionBounds()
  end
  local fallbackX = math.min(980, maxX)
  local fallbackY = math.min(160, maxY)
  local targetX = clampNumber(cfg.hudSetup.posX, 0, maxX, fallbackX)
  local targetY = clampNumber(cfg.hudSetup.posY, 0, maxY, fallbackY)
  commandsUi.hudPosUiSyncing = true
  if content.hudPosXSpin and content.hudPosXSpin.getValue and content.hudPosXSpin.setValue then
    if content.hudPosXSpin:getValue() ~= targetX then
      content.hudPosXSpin:setValue(targetX)
    end
  end
  if content.hudPosYSpin and content.hudPosYSpin.getValue and content.hudPosYSpin.setValue then
    if content.hudPosYSpin:getValue() ~= targetY then
      content.hudPosYSpin:setValue(targetY)
    end
  end
  commandsUi.hudPosUiSyncing = false
end

commandsUi.getHudExpandedHeight = function()
  local titleHeight = tonumber(commandsUi and commandsUi.hudTitle and commandsUi.hudTitle.getHeight and commandsUi.hudTitle:getHeight()) or 16
  local separatorHeight = tonumber(commandsUi and commandsUi.hudSeparator and commandsUi.hudSeparator.getHeight and commandsUi.hudSeparator:getHeight()) or 1
  local rowCount = math.max(
    1,
    #((commandsUi and commandsUi.hudButtonFallbackNames) or {}),
    #((cfg and cfg.hudSetup and cfg.hudSetup.buttons) or {}),
    #((commandsUi and commandsUi.hudButtons) or {}),
    #((commandsUi and commandsUi.hudMarks) or {})
  )
  local rowHeight = 20
  local chromeHeight = 4 -- tighten container so it ends close to the last row
  local computed = titleHeight + separatorHeight + (rowCount * rowHeight) + chromeHeight
  return clampNumber(computed, 32, 5000, 170)
end

commandsUi.getHudPositionBounds = function()
  local viewportWidth = tonumber(windowParent and windowParent.getWidth and windowParent:getWidth()) or 1200
  local viewportHeight = tonumber(windowParent and windowParent.getHeight and windowParent:getHeight()) or 700
  local hudWidth = tonumber(commandsUi and commandsUi.hudRoot and commandsUi.hudRoot.getWidth and commandsUi.hudRoot:getWidth()) or 181
  local fallbackHeight = commandsUi and commandsUi.getHudExpandedHeight and commandsUi.getHudExpandedHeight() or 170
  local currentHudHeight = tonumber(commandsUi and commandsUi.hudRoot and commandsUi.hudRoot.getHeight and commandsUi.hudRoot:getHeight()) or fallbackHeight
  local hudHeight = cfg.hudSetup and cfg.hudSetup.collapsed == true and 18 or currentHudHeight

  local maxX = math.max(0, math.floor(viewportWidth - hudWidth))
  local maxY = math.max(0, math.floor(viewportHeight - hudHeight))
  return maxX, maxY
end

commandsUi.syncHudSize = function()
  local hudRoot = commandsUi and commandsUi.hudRoot or nil
  if not hudRoot or not hudRoot.setHeight then
    return
  end
  commandsUi._hudExpandedHeight = commandsUi.getHudExpandedHeight()
  if cfg.hudSetup and cfg.hudSetup.collapsed == true then
    hudRoot:setHeight(18)
  else
    hudRoot:setHeight(commandsUi._hudExpandedHeight)
  end
end

commandsUi.setHudCollapsed = function(value)
  cfg.hudSetup = cfg.hudSetup or {}
  local collapsed = value == true
  local hudRoot = commandsUi and commandsUi.hudRoot or nil
  local expandedHeight = clampNumber(commandsUi.getHudExpandedHeight and commandsUi.getHudExpandedHeight() or commandsUi._hudExpandedHeight or 170, 32, 5000, 170)
  commandsUi._hudExpandedHeight = expandedHeight
  cfg.hudSetup.collapsed = collapsed

  if commandsUi and commandsUi.hudButtonsPanel and commandsUi.hudButtonsPanel.setVisible then
    commandsUi.hudButtonsPanel:setVisible(not collapsed)
  end
  if commandsUi and commandsUi.hudSeparator and commandsUi.hudSeparator.setVisible then
    commandsUi.hudSeparator:setVisible(not collapsed)
  end
  if commandsUi and commandsUi.hudCollapseButton and commandsUi.hudCollapseButton.setText then
    commandsUi.hudCollapseButton:setText(collapsed and "+" or "-")
  end
  if hudRoot and hudRoot.setHeight then
    hudRoot:setHeight(collapsed and 18 or expandedHeight)
  end
  if commandsUi and commandsUi.applyHudPosition then
    commandsUi.applyHudPosition()
  end
  commandsUi.syncHudPosInputs()
end

commandsUi.resolveHudGuildChannelId = function(preferred)
  local preferredText = trim(preferred or "")
  if preferredText ~= "" then
    local directId = tonumber(preferredText)
    if directId then
      return math.floor(directId)
    end
  end
  local channels = modules and modules.game_console and modules.game_console.channels or nil
  if type(channels) ~= "table" then
    return preferredText ~= "" and nil or 0
  end
  if preferredText ~= "" then
    local lowerPreferred = preferredText:lower()
    for channelId, channelName in pairs(channels) do
      if type(channelName) == "string" and channelName:lower() == lowerPreferred then
        local parsed = tonumber(channelId)
        if parsed then
          return math.floor(parsed)
        end
      end
    end
    for channelId, channelName in pairs(channels) do
      if type(channelName) == "string" and channelName:lower():find(lowerPreferred, 1, true) then
        local parsed = tonumber(channelId)
        if parsed then
          return math.floor(parsed)
        end
      end
    end
    return nil
  end
  for channelId, channelName in pairs(channels) do
    if type(channelName) == "string" then
      local lower = channelName:lower()
      if lower == "guild" or lower == "guild chat" then
        local parsed = tonumber(channelId)
        if parsed then
          return math.floor(parsed)
        end
      end
    end
  end
  for channelId, channelName in pairs(channels) do
    if type(channelName) == "string" and channelName:lower():find("guild", 1, true) then
      local parsed = tonumber(channelId)
      if parsed then
        return math.floor(parsed)
      end
    end
  end
  return 0
end

commandsUi.sendHudCommandText = function(commandText)
  local text = trim(commandText or "")
  local trigger = trim(cfg.combo and cfg.combo.triggerWord or "")
  if text:find("{trigger}", 1, true) then
    text = trim((text:gsub("{trigger}", function() return trigger end)))
  end
  if text == "" then
    return false
  end
  cfg.hudSetup = cfg.hudSetup or {}
  local sendMode = cfg.hudSetup.sendMode or "default"

  if sendMode == "pm" then
    local names = splitNames(cfg.cavebotPause and cfg.cavebotPause.mcNames or "")
    if #names == 0 then
      print("[Nav Hud] PM sem destino. Configure nomes em MC Names.")
      return false
    end
    if not g_game or not g_game.talkPrivate then
      print("[Nav Hud] talkPrivate indisponivel.")
      return false
    end
    for _, name in ipairs(names) do
      g_game.talkPrivate(5, name, text)
    end
    print(string.format("[Nav Hud] PM x%d: %s", #names, text))
    return true
  end

  if sendMode == "guild" then
    local preferredGuild = trim(cfg.hudSetup.guildChannel or "")
    local channelId = commandsUi.resolveHudGuildChannelId(preferredGuild)
    if not channelId then
      print("[Nav Hud] Canal guild nao encontrado. Confira nome/ID.")
      return false
    end
    if not g_game or not g_game.talkChannel then
      print("[Nav Hud] talkChannel indisponivel.")
      return false
    end
    g_game.talkChannel(7, channelId, text)
    print(string.format("[Nav Hud] Guild(%d): %s", channelId, text))
    return true
  end

  say(text)
  print(string.format("[Nav Hud] Default: %s", text))
  return true
end

commandsUi.getHudDefaultToggleCommand = function(buttonKey, turnOn)
  local suffix = turnOn and "on" or "off"
  if buttonKey == "follow" then return "!follow " .. suffix end
  if buttonKey == "cavebot" then return "!cavebot " .. suffix end
  if buttonKey == "target" then return "!target " .. suffix end
  if buttonKey == "sd" then return "!sd " .. suffix end
  if buttonKey == "paralyze" then return "!paralyze " .. suffix end
  if buttonKey == "antpush" then return "!antpush " .. suffix end
  return ""
end

commandsUi.getHudDefaultDirectCommand = function(buttonKey)
  if buttonKey == "combo" then
    local trigger = trim(cfg.combo and cfg.combo.triggerWord or "")
    if trigger ~= "" then
      return trigger
    end
    return "{trigger}"
  end
  return ""
end

commandsUi.refreshHudSendUi = function()
  if content and content.hudSendModeCombo then
    if not content.hudSendModeCombo._hudSendModeLoaded then
      content.hudSendModeCombo:addOption("Default", "default")
      content.hudSendModeCombo:addOption("PM", "pm")
      content.hudSendModeCombo:addOption("Guild", "guild")
      content.hudSendModeCombo._hudSendModeLoaded = true
    end
    if content.hudSendModeCombo.setCurrentOptionByData then
      content.hudSendModeCombo:setCurrentOptionByData(cfg.hudSetup and cfg.hudSetup.sendMode or "default")
    end
  end
  if content and content.hudGuildChannelEdit then
    local newGuildValue = cfg.hudSetup and cfg.hudSetup.guildChannel or ""
    if content.hudGuildChannelEdit.getText and content.hudGuildChannelEdit:getText() ~= newGuildValue then
      content.hudGuildChannelEdit:setText(newGuildValue)
    end
    content.hudGuildChannelEdit:setEnabled((cfg.hudSetup and cfg.hudSetup.sendMode or "default") == "guild")
  end
end

commandsUi.refreshHudSketch = function()
  cfg.hudSetup = cfg.hudSetup or {}
  cfg.hudSetup.buttons = cfg.hudSetup.buttons or {}
  if commandsUi and commandsUi.ensureHudRows then
    commandsUi.ensureHudRows()
  end
  for index = 1, #((commandsUi and commandsUi.hudMarkLetters) or {}) do
    local mark = commandsUi and commandsUi.hudMarks and commandsUi.hudMarks[index] or nil
    if mark and mark.setText then
      mark:setText((commandsUi and commandsUi.hudMarkLetters and commandsUi.hudMarkLetters[index]) or "")
    end
    if mark and mark.setColor then
      mark:setColor((commandsUi and commandsUi.hudMarkWaveColors and commandsUi.hudMarkWaveColors[index]) or "#d9a62b")
    end
    if mark and mark.setVisible then
      mark:setVisible(true)
    end
  end
  commandsUi.hudMarkWaveState = { step = 0 }
  for index = 1, #((commandsUi and commandsUi.hudButtonFallbackNames) or {}) do
    local button = commandsUi and commandsUi.hudButtons and commandsUi.hudButtons[index] or nil
    local def = cfg.hudSetup.buttons[index]
    if button and button.setText then
      button:setText((def and def.name) or (commandsUi and commandsUi.hudButtonFallbackNames and commandsUi.hudButtonFallbackNames[index]) or string.format("Cmd %d", index))
    end
    if button and button.setOn then
      if def and def.mode == "toggle" then
        button:setOn(def.state == true)
      else
        button:setOn(false)
      end
    end
    if commandsUi and commandsUi.applyHudButtonVisual then
      commandsUi.applyHudButtonVisual(button, def)
    end
    if button and button.setVisible then
      button:setVisible(true)
    end
  end
  if commandsUi and commandsUi.syncHudSize then
    commandsUi.syncHudSize()
  end
end

commandsUi.refreshHudWave = function()
  local marks = commandsUi and commandsUi.hudMarks or nil
  if type(marks) ~= "table" then
    return
  end

  local total = #(commandsUi.hudMarkLetters or {})
  if total <= 0 then
    return
  end
  local waveColors = commandsUi.hudMarkWaveColors or { "#c9901a", "#d9a62b", "#e9bc3d", "#ffd45a", "#e9bc3d", "#d9a62b", "#c9901a" }

  local state = commandsUi.hudMarkWaveState
  if type(state) ~= "table" then
    state = { step = 0 }
    commandsUi.hudMarkWaveState = state
  end
  state.step = (state.step or 0) + 1
  for index = 1, total do
    local mark = marks[index]
    if mark and mark.setColor then
      local colorIndex = (((state.step or 0) + index - 2) % #waveColors) + 1
      mark:setColor(waveColors[colorIndex])
    end
  end
end

commandsUi.refreshHudButtonSetupMode = function()
  local option = commandsUi.hudSetupModeCombo and commandsUi.hudSetupModeCombo.getCurrentOption and commandsUi.hudSetupModeCombo:getCurrentOption() or nil
  local data = option and option.data or nil
  local mode = trim(data or ""):lower()
  local isDirect = mode == "direct"
  if commandsUi.hudSetupOnEdit then
    commandsUi.hudSetupOnEdit:setEnabled(not isDirect)
  end
  if commandsUi.hudSetupOffEdit then
    commandsUi.hudSetupOffEdit:setEnabled(not isDirect)
  end
  if commandsUi.hudSetupDirectEdit then
    commandsUi.hudSetupDirectEdit:setEnabled(isDirect)
  end
end

commandsUi.openHudButtonSetup = function(index)
  cfg.hudSetup = cfg.hudSetup or {}
  cfg.hudSetup.buttons = cfg.hudSetup.buttons or {}
  local def = cfg.hudSetup.buttons[index]
  if not def then
    return
  end
  commandsUi.hudEditingIndex = index
  if commandsUi.hudSetupModeCombo and not commandsUi.hudSetupModeCombo._hudModeLoaded then
    commandsUi.hudSetupModeCombo:addOption("Toggle ON/OFF", "toggle")
    commandsUi.hudSetupModeCombo:addOption("Direto (1x)", "direct")
    commandsUi.hudSetupModeCombo._hudModeLoaded = true
  end
  if commandsUi.hudSetupTitle then
    commandsUi.hudSetupTitle:setText(string.format("Configurar atalho #%d (%s)", index, def.key or "cmd"))
  end
  if commandsUi.hudSetupNameEdit then
    commandsUi.hudSetupNameEdit:setText(def.name or "")
  end
  if commandsUi.hudSetupModeCombo and commandsUi.hudSetupModeCombo.setCurrentOptionByData then
    commandsUi.hudSetupModeCombo:setCurrentOptionByData(def.mode or "toggle")
  end
  if commandsUi.hudSetupModeCombo and commandsUi.hudSetupModeCombo.setEnabled then
    commandsUi.hudSetupModeCombo:setEnabled(def.key ~= "combo")
  end
  if commandsUi.hudSetupOnEdit then
    commandsUi.hudSetupOnEdit:setText(def.commandOn or "")
  end
  if commandsUi.hudSetupOffEdit then
    commandsUi.hudSetupOffEdit:setText(def.commandOff or "")
  end
  if commandsUi.hudSetupDirectEdit then
    commandsUi.hudSetupDirectEdit:setText(def.commandDirect or "")
  end
  commandsUi.refreshHudButtonSetupMode()
  if commandsUi.hudSetupWindow then
    commandsUi.hudSetupWindow:show()
    commandsUi.hudSetupWindow:raise()
    commandsUi.hudSetupWindow:focus()
  end
end

commandsUi.saveHudButtonSetup = function()
  cfg.hudSetup = cfg.hudSetup or {}
  cfg.hudSetup.buttons = cfg.hudSetup.buttons or {}
  local index = clampNumber(commandsUi.hudEditingIndex, 1, 99, 1)
  local def = cfg.hudSetup.buttons[index]
  if not def then
    return
  end
  if commandsUi.hudSetupNameEdit and commandsUi.hudSetupNameEdit.getText then
    def.name = trim(commandsUi.hudSetupNameEdit:getText())
  end
  if def.name == "" then
    def.name = def.key or ("Cmd " .. tostring(index))
  end
  local option = commandsUi.hudSetupModeCombo and commandsUi.hudSetupModeCombo.getCurrentOption and commandsUi.hudSetupModeCombo:getCurrentOption() or nil
  local mode = trim((option and option.data) or ""):lower()
  if def.key == "combo" then
    mode = "direct"
  elseif mode ~= "toggle" then
    mode = "toggle"
  end
  def.mode = mode
  if commandsUi.hudSetupOnEdit and commandsUi.hudSetupOnEdit.getText then
    def.commandOn = trim(commandsUi.hudSetupOnEdit:getText())
  end
  if commandsUi.hudSetupOffEdit and commandsUi.hudSetupOffEdit.getText then
    def.commandOff = trim(commandsUi.hudSetupOffEdit:getText())
  end
  if commandsUi.hudSetupDirectEdit and commandsUi.hudSetupDirectEdit.getText then
    def.commandDirect = trim(commandsUi.hudSetupDirectEdit:getText())
  end
  if def.mode == "toggle" then
    if def.commandOn == "" then
      def.commandOn = commandsUi.getHudDefaultToggleCommand(def.key, true)
    end
    if def.commandOff == "" then
      def.commandOff = commandsUi.getHudDefaultToggleCommand(def.key, false)
    end
  else
    def.state = false
    if def.commandDirect == "" then
      def.commandDirect = commandsUi.getHudDefaultDirectCommand(def.key)
    end
  end
  commandsUi.refreshHudSketch()
  if commandsUi.hudSetupWindow then
    commandsUi.hudSetupWindow:hide()
  end
end

if commandsUi.hudSetupModeCombo then
  commandsUi.hudSetupModeCombo.onOptionChange = function()
    commandsUi.refreshHudButtonSetupMode()
  end
end

if commandsUi.hudSetupSaveButton then
  commandsUi.hudSetupSaveButton.onClick = function()
    commandsUi.saveHudButtonSetup()
  end
end

commandsUi.bindHudButtons = function()
  if commandsUi and commandsUi.ensureHudRows then
    commandsUi.ensureHudRows()
  end
  for index = 1, #((commandsUi and commandsUi.hudButtonFallbackNames) or {}) do
    local button = commandsUi and commandsUi.hudButtons and commandsUi.hudButtons[index] or nil
    if button then
      button.onMousePress = function(_, _, mouseButton)
        if mouseButton == 2 then
          commandsUi.openHudButtonSetup(index)
          return true
        end
        return false
      end
      button.onClick = function(widget)
        cfg.hudSetup = cfg.hudSetup or {}
        cfg.hudSetup.buttons = cfg.hudSetup.buttons or {}
        local def = cfg.hudSetup.buttons[index]
        if not def then
          return
        end
        if def.mode == "direct" then
          def.state = false
          widget:setOn(false)
          if commandsUi and commandsUi.applyHudButtonVisual then
            commandsUi.applyHudButtonVisual(widget, def)
          end
          local directCmd = trim(def.commandDirect or "")
          if directCmd == "" then
            directCmd = commandsUi.getHudDefaultDirectCommand(def.key)
          end
          if commandsUi.sendHudCommandText(directCmd) then
            if def.key == "combo" and commandsUi and commandsUi.flashHudComboFeedback then
              commandsUi.flashHudComboFeedback(widget, def)
            end
          else
            print(string.format("[Nav Hud] Falha ao enviar comando direto (%s).", def.name or def.key or "?"))
          end
          return
        end
        local previousState = def.state == true
        local turnOn = not previousState
        local commandText = trim(turnOn and (def.commandOn or "") or (def.commandOff or ""))
        if commandText == "" then
          commandText = commandsUi.getHudDefaultToggleCommand(def.key, turnOn)
        end
        if commandsUi.sendHudCommandText(commandText) then
          def.state = turnOn
          widget:setOn(turnOn)
          if commandsUi and commandsUi.applyHudButtonVisual then
            commandsUi.applyHudButtonVisual(widget, def)
          end
        else
          def.state = previousState
          widget:setOn(previousState)
          if commandsUi and commandsUi.applyHudButtonVisual then
            commandsUi.applyHudButtonVisual(widget, def)
          end
          print(string.format("[Nav Hud] Falha ao enviar comando (%s).", def.name or def.key or "?"))
        end
      end
    end
  end
end

macro(180, function()
  if not commandsUi or not commandsUi.hudRoot or not commandsUi.hudRoot.isVisible or not commandsUi.hudRoot:isVisible() then
    return
  end
  commandsUi.refreshHudWave()
end)

commandsUi.applyHudPosition = function()
  cfg.hudSetup = cfg.hudSetup or {}
  local maxX = 5000
  local maxY = 5000
  if commandsUi and commandsUi.getHudPositionBounds then
    maxX, maxY = commandsUi.getHudPositionBounds()
  end
  cfg.hudSetup.posX = clampNumber(cfg.hudSetup.posX, 0, maxX, math.min(980, maxX))
  cfg.hudSetup.posY = clampNumber(cfg.hudSetup.posY, 0, maxY, math.min(160, maxY))
  if commandsUi and commandsUi.hudRoot and commandsUi.hudRoot.setPosition then
    commandsUi.hudRoot:setPosition({ x = cfg.hudSetup.posX, y = cfg.hudSetup.posY })
  end
end

commandsUi.bindHudDrag = function()
  if not commandsUi or not commandsUi.hudRoot then
    return
  end

  local hudRoot = commandsUi.hudRoot
  local dragHandle = commandsUi.hudTitle or hudRoot
  local function startManualDrag(mousePos)
    if not mousePos then
      return false
    end
    if not hudRoot.getX or not hudRoot.getY then
      return false
    end
    hudRoot._manualDragOffset = { x = mousePos.x - hudRoot:getX(), y = mousePos.y - hudRoot:getY() }
    return true
  end

  local function updateManualDrag(mousePos)
    local ref = hudRoot and hudRoot._manualDragOffset or nil
    if not ref or not mousePos then
      return false
    end
    local maxX = 5000
    local maxY = 5000
    if commandsUi and commandsUi.getHudPositionBounds then
      maxX, maxY = commandsUi.getHudPositionBounds()
    end
    cfg.hudSetup = cfg.hudSetup or {}
    cfg.hudSetup.posX = clampNumber(mousePos.x - ref.x, 0, maxX, cfg.hudSetup.posX or math.min(980, maxX))
    cfg.hudSetup.posY = clampNumber(mousePos.y - ref.y, 0, maxY, cfg.hudSetup.posY or math.min(160, maxY))
    if hudRoot.setPosition then
      hudRoot:setPosition({ x = cfg.hudSetup.posX, y = cfg.hudSetup.posY })
    end
    commandsUi.syncHudPosInputs()
    return true
  end

  local function stopManualDrag(mouseButton)
    if mouseButton ~= 1 then
      return false
    end
    if hudRoot and hudRoot._manualDragOffset then
      hudRoot._manualDragOffset = nil
      commandsUi.syncHudPosInputs()
      return true
    end
    return false
  end

  if dragHandle then
    local baseHandleMousePress = dragHandle.onMousePress
    dragHandle.onMousePress = function(widget, mousePos, mouseButton)
      if mouseButton == 1 and startManualDrag(mousePos) then
        return true
      end
      if type(baseHandleMousePress) == "function" then
        return baseHandleMousePress(widget, mousePos, mouseButton) == true
      end
      return false
    end
  end

  if commandsUi and commandsUi.hudCollapseButton then
    local collapseButton = commandsUi.hudCollapseButton
    local baseCollapseMousePress = collapseButton.onMousePress
    collapseButton.onMousePress = function(widget, mousePos, mouseButton)
      if mouseButton == 1 then
        if commandsUi and commandsUi.setHudCollapsed then
          commandsUi.setHudCollapsed(not (cfg.hudSetup and cfg.hudSetup.collapsed == true))
        end
        return true
      end
      if type(baseCollapseMousePress) == "function" then
        return baseCollapseMousePress(widget, mousePos, mouseButton) == true
      end
      return false
    end
  end

  local baseRootMouseMove = hudRoot.onMouseMove
  hudRoot.onMouseMove = function(widget, mousePos, mouseMoved)
    if updateManualDrag(mousePos) then
      return true
    end

    if type(baseRootMouseMove) == "function" then
      return baseRootMouseMove(widget, mousePos, mouseMoved) == true
    end
    return false
  end

  local baseRootMouseRelease = hudRoot.onMouseRelease
  hudRoot.onMouseRelease = function(widget, mousePos, mouseButton)
    if stopManualDrag(mouseButton) then
      return true
    end

    if type(baseRootMouseRelease) == "function" then
      return baseRootMouseRelease(widget, mousePos, mouseButton) == true
    end
    return false
  end

  if dragHandle and dragHandle ~= hudRoot then
    local baseHandleMouseMove = dragHandle.onMouseMove
    dragHandle.onMouseMove = function(widget, mousePos, mouseMoved)
      if updateManualDrag(mousePos) then
        return true
      end
      if type(baseHandleMouseMove) == "function" then
        return baseHandleMouseMove(widget, mousePos, mouseMoved) == true
      end
      return false
    end

    local baseHandleMouseRelease = dragHandle.onMouseRelease
    dragHandle.onMouseRelease = function(widget, mousePos, mouseButton)
      if stopManualDrag(mouseButton) then
        return true
      end
      if type(baseHandleMouseRelease) == "function" then
        return baseHandleMouseRelease(widget, mousePos, mouseButton) == true
      end
      return false
    end
  end

  if commandsUi and commandsUi.syncHudSize then
    commandsUi.syncHudSize()
  end
end

commandsUi.setHudVisible = function(value)
  cfg.hudSetup = cfg.hudSetup or {}
  cfg.hudSetup.visible = value == true
  if commandsUi and commandsUi.setHudCollapsed then
    commandsUi.setHudCollapsed(cfg.hudSetup.collapsed == true)
  end
  commandsUi.applyHudPosition()
  if commandsUi and commandsUi.hudRoot then
    commandsUi.hudRoot:setVisible(cfg.hudSetup.visible)
    if cfg.hudSetup.visible and commandsUi.hudRoot.raise then
      commandsUi.hudRoot:raise()
    end
  end
  commandsUi.refreshHudToggleButton()
end

local NAV_HELP_TEXT = table.concat({
  "PT - Navigation (Resumo)",
  "========================",
  "1) Objetivo",
  "- Centralizar Follow, Nav Leader, route fallback, target sync e combo.",
  "- Manter acompanhamento do lider mesmo com mudanca de floor e bloqueios.",
  "",
  "2) Campos principais",
  "- Nav Leader Name: lider dos comandos/chat e sync de alvo.",
  "- Follow Name: personagem que sera seguido no mapa.",
  "- Nav switch: liga/desliga nav leader (comandos + sync).",
  "- Follow switch: liga/desliga follow de movimento.",
  "",
  "3) Controle e fallback",
  "- MC Names + Pause CaveBot + Dist: controla pausa por distancia/perda.",
  "- Auto Ping/Ping manual: ajusta delays.",
  "- Route Fallback + Step + Edit Route: rota de busca quando perder o lider.",
  "",
  "4) Combo",
  "- Combo ON/OFF, modo Spell ou Rune, Trigger Word e alvo sincronizado.",
  "",
  "5) Comandos do lider",
  "- !help e !status para consultar comandos e estados atuais.",
  "- !cavebot, !target, !follow, !nav, !combo, !route, !combospell, !comborune",
  "- !changecavebot, !changetargetbot, !viajar, !refilar, !say, !npcsay",
  "- !<icone> on/off e !icons on/off (ex.: !sd on, !uh off, !utamo on).",
  "- Exiva e Magic Walls ficaram fora dos comandos de icones.",
  "",
  "EN - Navigation (Summary)",
  "=========================",
  "1) Goal",
  "- Centralize Follow, Nav Leader, route fallback, target sync and combo.",
  "- Keep leader tracking working across floor changes and path blocks.",
  "",
  "2) Main fields",
  "- Nav Leader Name: leader for chat commands and target sync.",
  "- Follow Name: character to physically follow.",
  "- Nav switch: toggle nav leader system (commands + sync).",
  "- Follow switch: toggle movement follow system.",
  "",
  "3) Control and fallback",
  "- MC Names + Pause CaveBot + Dist: distance/loss pause control.",
  "- Auto Ping/Manual Ping: delay tuning.",
  "- Route Fallback + Step + Edit Route: search route when leader is lost.",
  "",
  "4) Combo",
  "- Combo ON/OFF, Spell/Rune mode, Trigger Word and synchronized target.",
  "",
  "5) Leader commands",
  "- !help and !status to inspect commands and current states.",
  "- !cavebot, !target, !follow, !nav, !combo, !route, !combospell, !comborune",
  "- !changecavebot, !changetargetbot, !viajar, !refilar, !say, !npcsay",
  "- !<icon> on/off and !icons on/off (ex.: !sd on, !uh off, !utamo on).",
  "- Exiva and Magic Walls are excluded from icon chat commands."
}, "\n")

local NAV_COMMANDS_TEXT = table.concat({
  "Comandos do Navigation (Leader -> MC)",
  "====================================",
  "",
  "Sistema por mensagem:",
  "- Todo o controle remoto do Navigation funciona por mensagens no chat do lider para o MC.",
  "- Com isso, voce consegue controlar follow/nav/combo/route/bots e icones sem abrir setup no MC.",
  "",
  "Quantidade atual de comandos por mensagem: 64",
  "- 16 comandos principais de Navigation.",
  "- 48 comandos de icones (46 individuais + !icons + !allicons).",
  "",
  "Regras:",
  "- O sender deve ser igual ao campo Nav Leader Name.",
  "- Navigation master e Nav Leader system precisam estar ativos para comandos normais.",
  "- Com nav OFF, apenas !nav on e aceito.",
  "",
  "!help",
  "- Mostra resumo de comandos no log [Nav Cmd].",
  "",
  "!status",
  "- Mostra estados atuais: Nav, Follow, Combo, Route, CaveBot, TargetBot, Refil e fila.",
  "",
  "!nav on|off",
  "- Liga/desliga o canal remoto de comandos/sync do Nav Leader.",
  "",
  "!cavebot on|off",
  "- Liga/desliga CaveBot no MC.",
  "",
  "!target on|off",
  "- Liga/desliga TargetBot no MC.",
  "",
  "!follow on|off",
  "- Liga/desliga o sistema de follow de movimento.",
  "",
  "!follow <nome>",
  "- Troca o Follow Name em runtime.",
  "",
  "!combo on|off",
  "- Liga/desliga combo sincronizado por trigger.",
  "",
  "!route on|off",
  "- Liga/desliga Route Fallback.",
  "",
  "!combospell <magia>",
  "- Define a magia do combo e muda o modo para spell.",
  "",
  "!comborune <id>",
  "- Define a rune do combo e muda o modo para rune.",
  "",
  "!changecavebot <perfil>",
  "- Troca o perfil do CaveBot (se o arquivo existir).",
  "",
  "!changetargetbot <perfil>",
  "- Troca o perfil do TargetBot (se o arquivo existir).",
  "",
  "!viajar <cidade>",
  "- Executa a sequencia de conversa de viagem no NPC.",
  "",
  "!refilar <npc>",
  "- Inicia o fluxo de refil no NPC informado.",
  "",
  "!say <texto>",
  "- Envia fala normal no MC.",
  "",
  "!npcsay <texto>",
  "- Envia fala para NPC no MC.",
  "",
  "!icons on|off ou !allicons on|off",
  "- Liga/desliga em massa todos os icones suportados por chat.",
  "",
  "Comandos de icones (um por vez):",
  "- !attackrune on|off ou !sdtarget on|off -> SD Target",
  "- !uh on|off ou !uhself on|off -> UH Self",
  "- !paralyze on|off -> Paralyze Rune",
  "- !sd on|off ou !sdrune on|off -> SD Rune",
  "- !avalanche on|off ou !ava on|off -> Avalanche Rune",
  "- !stoneshower on|off -> Stone Shower Rune",
  "- !thunderstorm on|off -> Thunderstorm Rune",
  "- !gfb on|off -> GFB Rune",
  "- !kspell on|off -> Knight Attack Spell",
  "- !pspell on|off -> Paladin Attack Spell",
  "- !dspell on|off -> Druid Attack Spell",
  "- !sspell on|off -> Sorcerer Attack Spell",
  "- !superdash on|off -> Superdash",
  "- !utamo on|off -> Utamo Vita",
  "- !firebomb on|off -> Fire Bomb",
  "- !holdtarget on|off -> Hold Target",
  "- !antpush on|off -> Anti Push",
  "- !exetares on|off ou !exeta on|off -> Exeta Res",
  "- !machete on|off -> Machete Auto",
  "- !attackspell on|off -> Attack Spell",
  "- !magnet on|off -> Magnet System",
  "- !coletar on|off -> Coletar System",
  "- !saferunespell on|off -> Safe Rune Spell",
  "- !safespells on|off -> Safe Spells",
  "- !saferunes on|off -> Safe Runes",
  "- !fullspell on|off -> Full Spell",
  "- !bless on|off -> Bless System",
  "- !aol on|off -> AOL System",
  "- !manatraining on|off ou !manatrain on|off -> Mana Training",
  "- !levitate on|off -> Levitate System",
  "- !caveicon on|off -> CaveBot Control",
  "- !targeticon on|off -> TargetBot Control",
  "- !attackicon on|off -> Attack Module Control",
  "- !hptoolsicon on|off -> HP/Tools Module Control",
  "- !followicon on|off -> Follow Module Control",
  "- !navicon on|off -> Navigation Module Control",
  "- !pvpicon on|off -> PVP Module Control",
  "- !ringicon on|off -> Ring Module Control",
  "- !amuleticon on|off -> Amulet Module Control",
  "- !swapseticon on|off -> SwapSet Module Control",
  "",
  "Nao aceitos no chat de icones: Exiva e comandos de Magic Walls."
}, "\n")

local function refreshHelpWindow()
  if not helpUi.textLabel then
    return
  end
  helpUi.textLabel:setText(NAV_HELP_TEXT)
end

local function resetHelpScrollToTop()
  if helpUi.scrollBar and helpUi.scrollBar.setValue then
    local minValue = 0
    if helpUi.scrollBar.getMinimum then
      local currentMin = helpUi.scrollBar:getMinimum()
      if type(currentMin) == "number" then
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

local function openHelpWindow()
  refreshHelpWindow()
  helpWindow:show()
  helpWindow:raise()
  helpWindow:focus()
  resetHelpScrollToTop()
  schedule(30, resetHelpScrollToTop)
  schedule(120, resetHelpScrollToTop)
  schedule(260, resetHelpScrollToTop)
end

local function openCommandsWindow()
  if commandsUi.textLabel then
    commandsUi.textLabel:setText(NAV_COMMANDS_TEXT)
  end
  commandsWindow:show()
  commandsWindow:raise()
  commandsWindow:focus()
  if commandsUi.scrollBar and commandsUi.scrollBar.setValue then
    local minValue = 0
    if commandsUi.scrollBar.getMinimum then
      local currentMin = commandsUi.scrollBar:getMinimum()
      if type(currentMin) == "number" then
        minValue = currentMin
      end
    end
    commandsUi.scrollBar:setValue(minValue)
  end
  if commandsUi.scrollContent and commandsUi.scrollContent.getVirtualOffset and commandsUi.scrollContent.setVirtualOffset then
    local off = commandsUi.scrollContent:getVirtualOffset() or { x = 0, y = 0 }
    off.x = 0
    off.y = 0
    commandsUi.scrollContent:setVirtualOffset(off)
  end
end

local function setComboMode(mode)
  cfg.combo.mode = mode == "rune" and "rune" or "spell"
  if comboUi.modeButton then
    comboUi.modeButton:setText(cfg.combo.mode == "rune" and "Mode: Rune" or "Mode: Spell")
  end
  local useRune = cfg.combo.mode == "rune"
  if comboUi.spellEdit then
    comboUi.spellEdit:setEnabled(not useRune)
  end
  if comboUi.spellLabel and comboUi.spellLabel.setColor then
    comboUi.spellLabel:setColor(not useRune and "#ffffff" or "#808080")
  end
  if comboUi.runeSpin then
    comboUi.runeSpin:setEnabled(useRune)
  end
  if comboUi.runeLabel and comboUi.runeLabel.setColor then
    comboUi.runeLabel:setColor(useRune and "#ffffff" or "#808080")
  end
  if comboUi.statusLabel then
    if useRune then
      comboUi.statusLabel:setText("Target sync por projetil + trigger por palavra (rune)")
    else
      comboUi.statusLabel:setText("Target sync por projetil + trigger por palavra (spell)")
    end
  end
end

local function refreshComboWindow()
  if comboUi.enableSwitch then
    comboUi.enableSwitch:setOn(cfg.combo.enabled)
  end
  if comboUi.spellEdit then
    comboUi.spellEdit:setText(cfg.combo.spellText or "")
  end
  if comboUi.triggerWordEdit then
    comboUi.triggerWordEdit:setText(cfg.combo.triggerWord or "")
  end
  if comboUi.runeSpin then
    comboUi.runeSpin:setValue(cfg.combo.runeId)
  end
  if comboUi.leaderInfoLabel then
    local navLeader = trim(cfg.leaderName)
    if navLeader == "" then
      navLeader = "-"
    end
    comboUi.leaderInfoLabel:setText("Leader: " .. navLeader)
  end
  setComboMode(cfg.combo.mode)
end

local function openComboWindow()
  refreshComboWindow()
  comboWindow:show()
  comboWindow:raise()
  comboWindow:focus()
end

local function setRouteWindowStatus(text, color)
  if not routeUi.statusLabel then
    return
  end
  routeUi.statusLabel:setText(text or "")
  if color and routeUi.statusLabel.setColor then
    routeUi.statusLabel:setColor(color)
  end
end

local function openRouteFallbackWindow()
  local points = cfg.routeFallback and cfg.routeFallback.waypoints or {}
  local text = cfg.routeFallback and cfg.routeFallback.rawText or ""
  if text == "" and type(points) == "table" and #points > 0 then
    text = routeWaypointsToText(points)
    cfg.routeFallback.rawText = text
  end
  if routeUi.textEdit then
    routeUi.textEdit:setText(text)
  end
  setRouteWindowStatus(string.format("Waypoints carregados: %d", type(points) == "table" and #points or 0), "#a0ffa0")
  routeWindow:show()
  routeWindow:raise()
  routeWindow:focus()
end

local function saveRouteFallbackFromEditor()
  local text = routeUi.textEdit and routeUi.textEdit:getText() or ""
  local points, invalidLines = parseRouteWaypoints(text)
  cfg.routeFallback.rawText = text
  cfg.routeFallback.waypoints = points
  resetRouteFallbackState(true)
  if #points == 0 then
    setRouteWindowStatus("Nenhum waypoint valido encontrado.", "#ff8080")
    return
  end
  if #invalidLines > 0 then
    setRouteWindowStatus(
      string.format("Salvo: %d waypoints | linhas ignoradas: %d", #points, #invalidLines),
      "#ffe090"
    )
  else
    setRouteWindowStatus(string.format("Salvo: %d waypoints", #points), "#a0ffa0")
  end
end

if routeUi.saveButton then
  routeUi.saveButton.onClick = function()
    saveRouteFallbackFromEditor()
  end
end

if routeUi.clearButton then
  routeUi.clearButton.onClick = function()
    if routeUi.textEdit then
      routeUi.textEdit:setText("")
    end
    cfg.routeFallback.rawText = ""
    cfg.routeFallback.waypoints = {}
    resetRouteFallbackState(true)
    setRouteWindowStatus("Rota limpa.", "#ffd080")
  end
end

local function setTooltipPair(labelWidget, inputWidget, ptText, enText)
  setStandardTooltip(labelWidget, ptText, enText)
  setStandardTooltip(inputWidget, ptText, enText)
end

local function applyNovoFollowTooltips()
  setStandardTooltip(
    mainUi and mainUi.setupButton,
    "Abre a janela de configuracao do Navigation/Follow.",
    "Open the Navigation/Follow configuration window."
  )
  setStandardTooltip(
    window and window.closeButton,
    "Fecha a janela de configuracao.",
    "Close the configuration window."
  )
  setStandardTooltip(
    helpUi.openButton,
    "Abre a janela com tutorial completo do Navigation.",
    "Open the full Navigation tutorial window."
  )
  setStandardTooltip(
    commandsUi.openButton,
    "Abre a janela com lista de comandos do leader e funcao de cada comando.",
    "Open the command list window with each leader command function."
  )
  setStandardTooltip(
    content.title,
    "Configuracoes do Navigation, Follow e uso de andares.",
    "Navigation/Follow settings and floor-changer usage."
  )
  setStandardTooltip(
    content.enableSwitch,
    "Ativa/desativa o sistema completo (nav, follow, combo).",
    "Enable/disable full system (nav, follow, combo)."
  )

  setTooltipPair(
    content.leaderNameLabel,
    content.leaderNameEdit,
    "Nome do Nav Leader (comandos e combo seguem este lider).",
    "Nav leader name (commands and combo follow this leader)."
  )
  setStandardTooltip(
    content.navLeaderSwitch,
    "Liga/desliga o sistema do Nav Leader (target sync/comandos/trigger).",
    "Enable/disable Nav Leader system (target sync/commands/trigger)."
  )
  setTooltipPair(
    content.followNameLabel,
    content.followNameEdit,
    "Nome do lider de follow. Campo exclusivo do follow (nao usa Nav Leader).",
    "Follow leader name. Follow-only field (does not use Nav Leader)."
  )
  setStandardTooltip(
    content.followSwitch,
    "Liga/desliga o sistema de follow e fallback de rota.",
    "Enable/disable follow and route fallback systems."
  )
  setTooltipPair(
    content.mcNamesLabel,
    content.pauseMcNamesEdit,
    "Lista de nomes separados por virgula para controle de distancia e pausa do CaveBot.",
    "Comma-separated names used for distance checks and CaveBot pause logic."
  )

  setStandardTooltip(
    content.pauseCavebotSwitch,
    "Quando ligado, pausa o CaveBot se os nomes configurados ficarem longe/sumirem.",
    "When enabled, pauses CaveBot if configured names get too far or disappear."
  )
  setTooltipPair(
    content.pauseDistanceLabel,
    content.pauseDistanceSpin,
    "Distancia maxima em SQM usada para detectar afastamento do lider/MC.",
    "Maximum distance in SQM used to detect leader/MC drifting away."
  )
  setStandardTooltip(
    content.pingAutoSwitch,
    "Usa o ping atual para ajustar delays automaticamente.",
    "Use current ping to auto-adjust delays."
  )
  setTooltipPair(
    content.pingManualLabel,
    content.pingManualSpin,
    "Ping manual (ms) usado quando Auto Ping estiver desligado.",
    "Manual ping (ms) used when Auto Ping is disabled."
  )
  setStandardTooltip(
    content.comboSetupButton,
    "Abre o setup de combo (magia/runa) seguindo o alvo do Nav Leader.",
    "Open combo setup (spell/rune) following Nav Leader target."
  )
  setStandardTooltip(
    content.routeFallbackSwitch,
    "Ultimo fallback: quando perder o lider, segue a rota manual de busca.",
    "Last fallback: when leader is lost, follow manual search route."
  )
  setTooltipPair(
    content.routeFallbackStepLabel,
    content.routeFallbackStepSpin,
    "Delay entre passos da busca por rota (ms). Menor = mais rapido.",
    "Delay between route-search steps (ms). Lower = faster."
  )
  setStandardTooltip(
    content.routeFallbackStepMsLabel,
    "Unidade em milissegundos do delay da busca por rota.",
    "Milliseconds unit for route search delay."
  )
  setStandardTooltip(
    content.routeFallbackEditButton,
    "Abre o editor para colar os waypoints do cavebot do lider.",
    "Open editor to paste leader cavebot waypoints."
  )
  setStandardTooltip(
    content.hudSetupToggleButton,
    "Mostra/oculta o HUD de atalho de comandos do lider.",
    "Show/hide leader command shortcut HUD."
  )
  setTooltipPair(
    content.hudPosXLabel,
    content.hudPosXSpin,
    "Posicao horizontal do HUD (X).",
    "HUD horizontal position (X)."
  )
  setTooltipPair(
    content.hudPosYLabel,
    content.hudPosYSpin,
    "Posicao vertical do HUD (Y).",
    "HUD vertical position (Y)."
  )
  setTooltipPair(
    content.hudSendModeLabel,
    content.hudSendModeCombo,
    "Modo de envio: default chat, PM pelos MC Names, ou guild.",
    "Send mode: default chat, PM by MC Names, or guild."
  )
  setTooltipPair(
    content.hudGuildChannelLabel,
    content.hudGuildChannelEdit,
    "Canal Guild (nome ou ID). Vazio = auto detectar canal guild.",
    "Guild channel (name or ID). Empty = auto detect guild channel."
  )

  setTooltipPair(
    content.ropeIdLabel,
    content.ropeIdEdit,
    "ID da rope usada em rope spots.",
    "Rope item ID used on rope spots."
  )
  setTooltipPair(
    content.shovelIdLabel,
    content.shovelIdEdit,
    "ID da shovel usada em buracos fechados/terreno escavavel.",
    "Shovel item ID used on diggable terrain/holes."
  )
  setTooltipPair(
    content.macheteIdLabel,
    content.macheteIdEdit,
    "ID da machete usada para cortar obstaculos vegetais.",
    "Machete item ID used to cut vegetation obstacles."
  )

  setTooltipPair(
    content.laddersUpLabel,
    content.laddersUpContainer,
    "IDs de escadas/ladder que sobem (Up). Arraste itens para adicionar/remover.",
    "Ladder IDs that go up. Drag items to add/remove."
  )
  setTooltipPair(
    content.laddersDownLabel,
    content.laddersDownContainer,
    "IDs de escadas/ladder que descem (Down). Arraste itens para adicionar/remover.",
    "Ladder IDs that go down. Drag items to add/remove."
  )
  setTooltipPair(
    content.holesDownLabel,
    content.holesDownContainer,
    "IDs de buracos que descem (Down).",
    "Hole IDs that lead down."
  )
  setTooltipPair(
    content.ropeSpotsUpLabel,
    content.ropeSpotsUpContainer,
    "IDs de rope spots que sobem (Up) usando a rope configurada.",
    "Rope spot IDs that go up using configured rope."
  )
  setTooltipPair(
    content.stairsUpLabel,
    content.stairsUpContainer,
    "IDs de escadas/degraus que sobem (Up).",
    "Stair IDs that lead up."
  )
  setTooltipPair(
    content.stairsDownLabel,
    content.stairsDownContainer,
    "IDs de escadas/degraus que descem (Down).",
    "Stair IDs that lead down."
  )
  setTooltipPair(
    content.sewersDownLabel,
    content.sewersDownContainer,
    "IDs de entradas de sewer que descem (Down).",
    "Sewer entrance IDs that lead down."
  )

  setTooltipPair(
    content.useIdsLabel,
    content.useTargetsContainer,
    "IDs prioritarios para acao de use durante o follow.",
    "Priority IDs to use during follow actions."
  )
  setTooltipPair(
    content.doorIdsLabel,
    content.doorTargetsContainer,
    "IDs de portas fechadas para abrir automaticamente durante o follow.",
    "Closed door IDs to auto-open while following."
  )

  setStandardTooltip(
    routeUi.infoLabel,
    "Cole linhas no formato goto:x,y,z (quarto valor opcional sera ignorado).",
    "Paste lines as goto:x,y,z (optional 4th value will be ignored)."
  )
  setStandardTooltip(
    routeUi.textEdit,
    "Aceita: goto:x,y,z ou x,y,z. Uma linha por waypoint.",
    "Accepts: goto:x,y,z or x,y,z. One waypoint per line."
  )
  setStandardTooltip(
    routeUi.saveButton,
    "Valida e salva os waypoints para o fallback de busca.",
    "Validate and save waypoints for search fallback."
  )
  setStandardTooltip(
    routeUi.clearButton,
    "Limpa o texto e remove os waypoints salvos.",
    "Clear text and remove saved waypoints."
  )
  setStandardTooltip(
    routeUi.closeButton,
    "Fecha o editor de rota.",
    "Close route editor."
  )

  setStandardTooltip(
    comboUi.enableSwitch,
    "Ativa/desativa o combo em sincronia com magia/runa do Nav Leader.",
    "Enable/disable combo synchronized with Nav Leader spell/rune."
  )
  setStandardTooltip(
    comboUi.modeButton,
    "Alterna entre combo por magia ou por runa.",
    "Toggle between spell combo and rune combo."
  )
  setStandardTooltip(
    comboUi.leaderInfoLabel,
    "Mostra qual Nav Leader esta sendo usado no target sync do combo.",
    "Shows which Nav Leader is used for combo target sync."
  )
  setTooltipPair(
    comboUi.triggerWordLabel,
    comboUi.triggerWordEdit,
    "Palavra/frase que o lider fala para disparar seu combo.",
    "Word/phrase the leader says to trigger your combo."
  )
  setTooltipPair(
    comboUi.spellLabel,
    comboUi.spellEdit,
    "Magia usada no combo quando modo Spell estiver ativo.",
    "Spell used in combo when Spell mode is active."
  )
  setTooltipPair(
    comboUi.runeLabel,
    comboUi.runeSpin,
    "ID da runa usada no combo quando modo Rune estiver ativo.",
    "Rune ID used in combo when Rune mode is active."
  )
  setStandardTooltip(
    comboUi.statusLabel,
    "Resume: alvo sincronizado por projetil e cast por palavra-chave.",
    "Summary: target sync by projectile and cast by trigger word."
  )
  setStandardTooltip(
    comboUi.closeButton,
    "Fecha a janela de combo.",
    "Close combo window."
  )
  setStandardTooltip(
    helpUi.textLabel,
    "Tutorial completo do Navigation, follow, combo, fallback e comandos.",
    "Complete tutorial for navigation, follow, combo, fallback and commands."
  )
  setStandardTooltip(
    helpUi.closeButton,
    "Fecha a janela de ajuda.",
    "Close help window."
  )
  setStandardTooltip(
    commandsUi.textLabel,
    "Lista detalhada de comandos do leader e descricao de uso.",
    "Detailed list of leader commands and usage description."
  )
  setStandardTooltip(
    commandsUi.closeButton,
    "Fecha a janela de comandos.",
    "Close commands window."
  )
  if commandsUi and commandsUi.ensureHudRows then
    commandsUi.ensureHudRows()
  end
  for index = 1, #((commandsUi and commandsUi.hudButtonFallbackNames) or {}) do
    local button = commandsUi and commandsUi.hudButtons and commandsUi.hudButtons[index] or nil
    setStandardTooltip(
      button,
      "Clique esquerdo envia comando. Clique direito abre setup desse botao.",
      "Left click sends command. Right click opens this button setup."
    )
  end
  setStandardTooltip(
    commandsUi and commandsUi.hudCollapseButton,
    "Minimiza/maximiza o HUD de atalhos.",
    "Minimize/maximize the shortcut HUD."
  )
end

applyNovoFollowTooltips()
commandsUi.refreshHudSketch()
commandsUi.bindHudButtons()
commandsUi.bindHudDrag()
commandsUi.refreshHudSendUi()
commandsUi.setHudVisible(cfg.hudSetup and cfg.hudSetup.visible == true)

local function refreshConfigWindow()
  if content.enableSwitch then
    content.enableSwitch:setOn(cfg.enabled)
  end
  if content.leaderNameEdit then
    content.leaderNameEdit:setText(cfg.leaderName or "")
  end
  if content.navLeaderSwitch then
    content.navLeaderSwitch:setOn(isNavLeaderSystemEnabled())
  end
  if content.followNameEdit then
    content.followNameEdit:setText(cfg.followName or "")
  end
  if content.followSwitch then
    content.followSwitch:setOn(isFollowSystemEnabled())
  end
  if content.pauseCavebotSwitch then
    content.pauseCavebotSwitch:setOn(cfg.cavebotPause.enabled)
  end
  if content.pauseDistanceSpin then
    content.pauseDistanceSpin:setValue(cfg.cavebotPause.distance)
  end
  if content.pauseMcNamesEdit then
    content.pauseMcNamesEdit:setText(cfg.cavebotPause.mcNames or "")
  end
  if content.pingAutoSwitch then
    content.pingAutoSwitch:setOn(cfg.pingConfig.auto)
  end
  if content.pingManualSpin then
    content.pingManualSpin:setValue(cfg.pingConfig.manualMs)
    content.pingManualSpin:setEnabled(not cfg.pingConfig.auto)
  end
  if comboUi and comboUi.enableSwitch then
    refreshComboWindow()
  end
  if content.routeFallbackSwitch then
    content.routeFallbackSwitch:setOn(cfg.routeFallback.enabled)
  end
  if content.routeFallbackStepSpin then
    content.routeFallbackStepSpin:setValue(cfg.routeFallback.stepMs)
  end
  if content.ropeIdEdit then
    content.ropeIdEdit:setText(tostring(cfg.tools.ropeId))
  end
  if content.shovelIdEdit then
    content.shovelIdEdit:setText(tostring(cfg.tools.shovelId))
  end
  if content.macheteIdEdit then
    content.macheteIdEdit:setText(tostring(cfg.tools.macheteId))
  end
  if content.laddersUpContainer then
    content.laddersUpContainer:setItems(cfg.floorChangers.ladders.up)
  end
  if content.laddersDownContainer then
    content.laddersDownContainer:setItems(cfg.floorChangers.ladders.down)
  end
  if content.holesDownContainer then
    content.holesDownContainer:setItems(cfg.floorChangers.holes.down)
  end
  if content.ropeSpotsUpContainer then
    content.ropeSpotsUpContainer:setItems(cfg.floorChangers.ropeSpots.up)
  end
  if content.stairsUpContainer then
    content.stairsUpContainer:setItems(cfg.floorChangers.stairs.up)
  end
  if content.stairsDownContainer then
    content.stairsDownContainer:setItems(cfg.floorChangers.stairs.down)
  end
  if content.sewersDownContainer then
    content.sewersDownContainer:setItems(cfg.floorChangers.sewers.down)
  end
  if content.useTargetsContainer then
    content.useTargetsContainer:setItems(cfg.useTargets)
  end
  if content.doorTargetsContainer then
    content.doorTargetsContainer:setItems(cfg.doorTargets)
  end
  if commandsUi and commandsUi.syncHudPosInputs then
    commandsUi.syncHudPosInputs()
  end
  if commandsUi and commandsUi.refreshHudSketch then
    commandsUi.refreshHudSketch()
  end
  if commandsUi and commandsUi.refreshHudSendUi then
    commandsUi.refreshHudSendUi()
  end
  if commandsUi and commandsUi.applyHudPosition then
    commandsUi.applyHudPosition()
  end
  commandsUi.refreshHudToggleButton()
end

local function openNovoFollowWindow()
  refreshConfigWindow()
  window:show()
  window:raise()
  window:focus()
end

-- Bridge para o layout estilo ElfBot abrir diretamente o Navigation.
NovoFollowController = NovoFollowController or {}
NovoFollowController.open = openNovoFollowWindow
NovoFollowController.show = openNovoFollowWindow
ImperialElfBot_OpenNavigation = openNovoFollowWindow

local mainUiSyncLock = false

local function setFollowEnabled(value)
  cfg.enabled = value == true
  if not cfg.enabled then
    resetRouteFallbackState(true)
    clearComboLeaderTarget()
    clearComboTriggers()
    stopRefillCommand()
    follow3CycleId = follow3CycleId + 1
    follow3LastLeaderDir = nil
    followRuntimeState.nextMoveSeq()
    followRuntimeState.lastLeaderPos = nil
    followRuntimeState.lastLeaderSeenAt = 0
    if clearNavCommandQueue then
      clearNavCommandQueue()
    end
    navCmdQueueState.busyUntil = 0
    navCmdQueueState.travelUntil = 0
  end
  if content and content.enableSwitch then
    mainUiSyncLock = true
    content.enableSwitch:setOn(cfg.enabled)
    mainUiSyncLock = false
  end
end

local function setNavLeaderSystemEnabled(value)
  cfg.navLeaderEnabled = value == true
  if content and content.navLeaderSwitch then
    content.navLeaderSwitch:setOn(cfg.navLeaderEnabled)
  end
  if not cfg.navLeaderEnabled then
    clearComboLeaderTarget()
    clearComboTriggers()
    stopRefillCommand()
    if clearNavCommandQueue then
      clearNavCommandQueue()
    end
    navCmdQueueState.busyUntil = 0
    navCmdQueueState.travelUntil = 0
  end
end

local function setFollowSystemEnabled(value)
  cfg.followEnabled = value == true
  if content and content.followSwitch then
    content.followSwitch:setOn(cfg.followEnabled)
  end
  if not cfg.followEnabled then
    follow3CycleId = follow3CycleId + 1
    follow3LastLeaderDir = nil
    followRuntimeState.nextMoveSeq()
    followRuntimeState.lastLeaderPos = nil
    followRuntimeState.lastLeaderSeenAt = 0
    resetRouteFallbackState(true)
  end
end

local function setComboEnabled(value)
  cfg.combo.enabled = value == true
  if comboUi and comboUi.enableSwitch then
    comboUi.enableSwitch:setOn(cfg.combo.enabled)
  end
  if not cfg.combo.enabled then
    clearComboLeaderTarget()
    clearComboTriggers()
  end
end

local function setRouteFallbackEnabled(value)
  cfg.routeFallback.enabled = value == true
  if content and content.routeFallbackSwitch then
    content.routeFallbackSwitch:setOn(cfg.routeFallback.enabled)
  end
  if not cfg.routeFallback.enabled then
    resetRouteFallbackState(true)
  end
end

local function setFollowTargetName(text)
  cfg.followName = trim(text)
  followRuntimeState.nextMoveSeq()
  followRuntimeState.lastLeaderPos = nil
  followRuntimeState.lastLeaderSeenAt = 0
  if content and content.followNameEdit then
    content.followNameEdit:setText(cfg.followName)
  end
  resetRouteFallbackState(true)
  followSelfSuppressed = false
  shouldSuppressFollowForSelf()
end

local function setComboSpellText(text)
  cfg.combo.spellText = trim(text)
  if comboUi and comboUi.spellEdit then
    comboUi.spellEdit:setText(cfg.combo.spellText)
  end
end

local function setComboRuneId(value)
  cfg.combo.runeId = clampNumber(value, 100, 100000, cfg.combo.runeId)
  if comboUi and comboUi.runeSpin then
    comboUi.runeSpin:setValue(cfg.combo.runeId)
  end
end

local function parseOnOffArg(value)
  local v = trim(value):lower()
  if v == "on" then
    return true
  end
  if v == "off" then
    return false
  end
  return nil
end

local function navCmdLog(text)
  print("[Nav Cmd] " .. tostring(text or ""))
end

local function boolToOnOff(value)
  return value and "ON" or "OFF"
end

local function getCurrentBotConfigName()
  local gameBot = modules and modules.game_bot
  local contents = gameBot and gameBot.contentsPanel
  local configWidget = contents and contents.config
  if not configWidget or type(configWidget.getCurrentOption) ~= "function" then
    return ""
  end
  local option = configWidget:getCurrentOption()
  if type(option) == "table" then
    return trim(option.text or option[1] or "")
  end
  if type(option) == "string" then
    return trim(option)
  end
  return ""
end

local function profileExists(profileFolder, extension, profileName)
  local nameText = trim(profileName or "")
  if nameText == "" then
    return false
  end
  if not g_resources or type(g_resources.fileExists) ~= "function" then
    return nil
  end
  local botConfigName = getCurrentBotConfigName()
  if botConfigName == "" then
    return nil
  end
  local path = string.format("/bot/%s/%s/%s.%s", botConfigName, profileFolder, nameText, extension)
  return g_resources.fileExists(path) == true
end

local function getBotToggleStateText(moduleApi)
  if type(moduleApi) ~= "table" then
    return "N/A"
  end
  if type(moduleApi.isOn) == "function" then
    local ok, value = pcall(moduleApi.isOn)
    if ok then
      return value and "ON" or "OFF"
    end
  end
  if type(moduleApi.isOff) == "function" then
    local ok, value = pcall(moduleApi.isOff)
    if ok then
      return value and "OFF" or "ON"
    end
  end
  return "N/A"
end

local NAV_BASE_CHAT_COMMANDS = {
  help = true,
  status = true,
  cavebot = true,
  target = true,
  nav = true,
  combo = true,
  route = true,
  follow = true,
  combospell = true,
  comborune = true,
  changecavebot = true,
  changetargetbot = true,
  viajar = true,
  refilar = true,
  say = true,
  npcsay = true
}

local NAV_CMD_COOLDOWN_BY_COMMAND = {
  help = 300,
  status = 400,
  cavebot = 500,
  target = 500,
  nav = 450,
  combo = 500,
  route = 500,
  follow = 550,
  combospell = 550,
  comborune = 550,
  changecavebot = 1100,
  changetargetbot = 1100,
  viajar = 1400,
  refilar = 1500,
  say = 650,
  npcsay = 650,
  icons = 1000,
  allicons = 1000
}

local isIconCommandName

clearNavCommandQueue = function()
  if #navCmdQueue == 0 then
    return
  end
  for i = #navCmdQueue, 1, -1 do
    navCmdQueue[i] = nil
  end
end

local function markNavCommandBusy(delayMs)
  local untilAt = timeMs() + math.max(0, tonumber(delayMs) or 0)
  if untilAt > (navCmdQueueState.busyUntil or 0) then
    navCmdQueueState.busyUntil = untilAt
  end
end

local function markNavTravelBusy()
  navCmdQueueState.travelUntil = timeMs() + scaleDelay(TRAVEL_STEP_DELAY_MS * 3 + NAV_CMD_CFG.travelLockExtraMs)
end

local function getNavCommandCooldownMs(commandName)
  return NAV_CMD_COOLDOWN_BY_COMMAND[commandName] or NAV_CMD_CFG.defaultCooldownMs
end

local function normalizeNavCommandSignature(commandName, commandArg)
  local cmd = trim(commandName or ""):lower()
  local arg = trim(commandArg or ""):lower()
  return cmd .. "|" .. arg
end

local function shouldRejectNavCommandByRate(commandName, commandArg)
  local nowMs = timeMs()
  local signature = normalizeNavCommandSignature(commandName, commandArg)
  if signature ~= "|" and navCmdQueueState.lastSignature == signature and nowMs - (navCmdQueueState.lastSignatureAt or 0) < NAV_CMD_CFG.duplicateWindowMs then
    return true, "Comando duplicado ignorado."
  end
  local cooldownMs = getNavCommandCooldownMs(commandName)
  local lastAt = navCmdQueueState.lastByCommand[commandName] or 0
  if cooldownMs > 0 and nowMs - lastAt < cooldownMs then
    return true, string.format("Comando '%s' em cooldown.", commandName)
  end
  navCmdQueueState.lastSignature = signature
  navCmdQueueState.lastSignatureAt = nowMs
  navCmdQueueState.lastByCommand[commandName] = nowMs
  return false, nil
end

local function isNavCommandInstant(commandName)
  return commandName == "help" or commandName == "status"
end

local function isNavCommandSupported(commandName)
  if NAV_BASE_CHAT_COMMANDS[commandName] then
    return true
  end
  if isIconCommandName and isIconCommandName(commandName) then
    return true
  end
  return false
end

local function isNavOnCommand(commandName, commandArg)
  return commandName == "nav" and parseOnOffArg(commandArg) == true
end

local function enqueueNavCommand(commandName, commandArg)
  local signature = normalizeNavCommandSignature(commandName, commandArg)
  for _, queued in ipairs(navCmdQueue) do
    if queued.signature == signature then
      return false, "Comando repetido ja esta na fila."
    end
  end
  if #navCmdQueue >= NAV_CMD_CFG.queueMaxSize then
    return false, "Fila de comandos cheia. Aguarde."
  end
  navCmdQueue[#navCmdQueue + 1] = {
    name = commandName,
    arg = commandArg or "",
    signature = signature,
    queuedAt = timeMs()
  }
  return true, nil
end

local function logNavCommandHelp()
  navCmdLog("Comandos: !help, !status")
  navCmdLog("Controles: !nav, !cavebot, !target, !combo, !route, !follow (on/off; !follow Nome)")
  navCmdLog("Perfis: !changecavebot nome, !changetargetbot nome")
  navCmdLog("Acao: !viajar cidade, !refilar npc, !combospell magia, !comborune id, !say texto, !npcsay texto")
  navCmdLog("Icones: !<icone> on/off e !icons on/off")
end

local function logNavCommandStatus()
  local leader = getNavLeaderName()
  if leader == "" then
    leader = "-"
  end
  local followName = getFollowLeaderName()
  if followName == "" then
    followName = "-"
  end
  local refillText = "OFF"
  if refillCommandState.active then
    local npcName = refillCommandState.npcName ~= "" and refillCommandState.npcName or "?"
    refillText = "ON(" .. npcName .. ")"
  end
  navCmdLog(string.format(
    "Status Nav=%s | Leader=%s | Follow=%s (%s) | Combo=%s/%s | Route=%s",
    boolToOnOff(isNavLeaderSystemEnabled()),
    leader,
    boolToOnOff(isFollowSystemEnabled()),
    followName,
    boolToOnOff(cfg.combo and cfg.combo.enabled),
    (cfg.combo and cfg.combo.mode) or "spell",
    boolToOnOff(cfg.routeFallback and cfg.routeFallback.enabled)
  ))
  navCmdLog(string.format(
    "Bots CaveBot=%s | TargetBot=%s | Refil=%s | Fila=%d",
    getBotToggleStateText(CaveBot),
    getBotToggleStateText(TargetBot),
    refillText,
    #navCmdQueue
  ))
end

local PAINEL_ICON_COMMAND_MAP = {
  attackrune = "sdTarget",
  sdtarget = "sdTarget",
  uh = "uhSelf",
  uhself = "uhSelf",
  paralyze = "paralyzeRune",
  sd = "sdRune",
  sdrune = "sdRune",
  avalanche = "avalancheRune",
  ava = "avalancheRune",
  stoneshower = "stoneShowerRune",
  thunderstorm = "thunderstormRune",
  gfb = "gfbRune",
  kspell = "knightAttackSpell",
  pspell = "paladinAttackSpell",
  dspell = "druidAttackSpell",
  sspell = "sorcererAttackSpell",
  superdash = "superdashControl",
  utamo = "utamoVita",
  firebomb = "fireBomb",
  holdtarget = "holdTarget",
  antpush = "antiPushCoin",
  exetares = "exetaRes",
  exeta = "exetaRes",
  machete = "macheteAuto",
  attackspell = "attackSpell",
  magnet = "magnetSystem",
  coletar = "coletarSystem",
  saferunespell = "safeRuneSpell",
  safespells = "safeSpells",
  saferunes = "safeRunes",
  fullspell = "fullSpell",
  bless = "blessSystem",
  aol = "aolSystem",
  manatraining = "manaTraining",
  manatrain = "manaTraining",
  levitate = "levitateSystem",
  caveicon = "cavebotControl",
  targeticon = "targetbotControl",
  attackicon = "attackModuleOff",
  hptoolsicon = "hpToolsModuleOff",
  followicon = "followModuleOff",
  navicon = "navModuleOff",
  pvpicon = "pvpModuleOff",
  ringicon = "ringModuleOff",
  amuleticon = "amuletModuleOff",
  swapseticon = "swapSetModuleOff"
}

local PAINEL_ICON_EXCLUDED_MODULES = {
  exivaSystem = true,
  mwNorth = true,
  mwNorthEast = true,
  mwNorthWest = true,
  mwSouth = true,
  mwSouthEast = true,
  mwSouthWest = true,
  mwEast = true,
  mwWest = true
}

local PAINEL_ICON_RUNNER_ALWAYS_ON = {
  cavebotControl = true,
  targetbotControl = true,
  attackModuleOff = true,
  hpToolsModuleOff = true,
  followModuleOff = true,
  navModuleOff = true,
  pvpModuleOff = true,
  ringModuleOff = true,
  amuletModuleOff = true,
  swapSetModuleOff = true
}

local PAINEL_ICON_BRIDGE_BY_MODULE = {
  attackModuleOff = "attackDesired",
  hpToolsModuleOff = "hpToolsDesired",
  followModuleOff = "followDesired",
  navModuleOff = "navDesired",
  pvpModuleOff = "pvpDesired",
  ringModuleOff = "ringDesired",
  amuletModuleOff = "amuletDesired",
  swapSetModuleOff = "swapSetDesired"
}

local function buildPainelIconCommandTargets()
  local seen = {}
  local out = {}
  for _, moduleKey in pairs(PAINEL_ICON_COMMAND_MAP) do
    if type(moduleKey) == "string" and moduleKey ~= "" and not PAINEL_ICON_EXCLUDED_MODULES[moduleKey] and not seen[moduleKey] then
      seen[moduleKey] = true
      out[#out + 1] = moduleKey
    end
  end
  table.sort(out)
  return out
end

local PAINEL_ICON_COMMAND_TARGETS = buildPainelIconCommandTargets()

isIconCommandName = function(commandName)
  local cmd = trim(commandName):lower()
  if cmd == "" then
    return false
  end
  return cmd == "icons" or cmd == "allicons" or PAINEL_ICON_COMMAND_MAP[cmd] ~= nil
end

local function queuePainelIconBridgeToggle(moduleKey, enabled)
  local bridgeKey = PAINEL_ICON_BRIDGE_BY_MODULE[moduleKey]
  if not bridgeKey then
    return
  end
  if type(storage.painelDeIconesBridge) ~= "table" then
    storage.painelDeIconesBridge = {}
  end
  storage.painelDeIconesBridge[bridgeKey] = enabled == true
  storage.painelDeIconesBridge.updatedAt = timeMs()
end

local function setPainelIconModuleEnabled(moduleKey, enabled)
  if type(moduleKey) ~= "string" or moduleKey == "" then
    return false, "Modulo invalido."
  end
  if PAINEL_ICON_EXCLUDED_MODULES[moduleKey] then
    return false, string.format("Modulo '%s' esta fora dos comandos por chat.", moduleKey)
  end

  local painelCfg = storage and storage.painelDeIcones
  local modules = painelCfg and painelCfg.modules
  if type(modules) ~= "table" then
    return false, "Painel de Icones nao carregado."
  end

  local moduleState = modules[moduleKey]
  if type(moduleState) ~= "table" then
    return false, string.format("Modulo '%s' nao encontrado no Painel.", moduleKey)
  end

  local desired = enabled == true
  moduleState.enabled = desired

  if type(storage._icons) ~= "table" then
    storage._icons = {}
  end
  local iconStorageId = "PIC_" .. moduleKey
  if type(storage._icons[iconStorageId]) ~= "table" then
    storage._icons[iconStorageId] = {}
  end
  storage._icons[iconStorageId].enabled = desired

  queuePainelIconBridgeToggle(moduleKey, desired)

  if moduleKey == "cavebotControl" and CaveBot and type(CaveBot.setOn) == "function" and type(CaveBot.setOff) == "function" then
    if desired then
      CaveBot.setOn()
    else
      CaveBot.setOff()
    end
  elseif moduleKey == "targetbotControl" and TargetBot and type(TargetBot.setOn) == "function" and type(TargetBot.setOff) == "function" then
    if desired then
      TargetBot.setOn()
    else
      TargetBot.setOff()
    end
  end

  local panelController = type(PainelDeIconesController) == "table" and PainelDeIconesController or nil
  local panelState = panelController and panelController.state or nil
  local runner = panelState and panelState.runners and panelState.runners[moduleKey] or nil
  if runner then
    if desired then
      if runner.setOn then
        runner.setOn()
      end
    else
      if PAINEL_ICON_RUNNER_ALWAYS_ON[moduleKey] then
        if runner.setOn then
          runner.setOn()
        end
      elseif runner.setOff then
        runner.setOff()
      end
    end
  end

  local icon = panelState and panelState.icons and panelState.icons[moduleKey] or nil
  if icon and icon.text and icon.text.setColor then
    icon.text:setColor(desired and "#2cff2c" or "#ff4040")
  end

  return true
end

local function tryHandlePainelIconCommand(commandName, turnOn)
  local cmd = trim(commandName):lower()
  if cmd == "" then
    return false
  end

  if cmd == "icons" or cmd == "allicons" then
    local total = 0
    local applied = 0
    for _, moduleKey in ipairs(PAINEL_ICON_COMMAND_TARGETS) do
      total = total + 1
      local ok = setPainelIconModuleEnabled(moduleKey, turnOn)
      if ok then
        applied = applied + 1
      end
    end
    if total == 0 then
      navCmdLog("Nenhum icone mapeado para comando.")
    else
      navCmdLog(string.format("Icones %s: %d/%d.", turnOn and "ON" or "OFF", applied, total))
    end
    return true
  end

  local moduleKey = PAINEL_ICON_COMMAND_MAP[cmd]
  if not moduleKey then
    return false
  end

  local ok, err = setPainelIconModuleEnabled(moduleKey, turnOn)
  if ok then
    navCmdLog(string.format("Icone '%s' %s.", cmd, turnOn and "ON" or "OFF"))
  else
    navCmdLog(err or string.format("Falha ao aplicar comando no icone '%s'.", cmd))
  end
  return true
end

local function executeLeaderChatCommand(commandName, commandArg)
  local cmd = trim(commandName):lower()
  local arg = trim(commandArg or "")
  if cmd == "" then
    return false
  end

  if cmd == "help" then
    logNavCommandHelp()
    return true
  end

  if cmd == "status" then
    logNavCommandStatus()
    return true
  end

  if isIconCommandName and isIconCommandName(cmd) then
    local turnOn = parseOnOffArg(arg)
    if turnOn == nil then
      navCmdLog(string.format("Comando invalido. Use: !%s on/off", cmd))
      return true
    end
    tryHandlePainelIconCommand(cmd, turnOn)
    markNavCommandBusy(NAV_CMD_CFG.toggleLockMs)
    return true
  end

  if cmd == "cavebot" then
    local turnOn = parseOnOffArg(arg)
    if turnOn == nil then
      navCmdLog("Comando invalido. Use: !cavebot on/off")
      return true
    end
    if not CaveBot or type(CaveBot.setOn) ~= "function" or type(CaveBot.setOff) ~= "function" then
      navCmdLog("CaveBot indisponivel.")
      return true
    end
    if turnOn then
      CaveBot.setOn()
    else
      CaveBot.setOff()
    end
    navCmdLog("CaveBot " .. (turnOn and "ON" or "OFF") .. ".")
    markNavCommandBusy(NAV_CMD_CFG.toggleLockMs)
    return true
  end

  if cmd == "target" then
    local turnOn = parseOnOffArg(arg)
    if turnOn == nil then
      navCmdLog("Comando invalido. Use: !target on/off")
      return true
    end
    if not TargetBot or type(TargetBot.setOn) ~= "function" or type(TargetBot.setOff) ~= "function" then
      navCmdLog("TargetBot indisponivel.")
      return true
    end
    if turnOn then
      TargetBot.setOn()
    else
      TargetBot.setOff()
    end
    navCmdLog("TargetBot " .. (turnOn and "ON" or "OFF") .. ".")
    markNavCommandBusy(NAV_CMD_CFG.toggleLockMs)
    return true
  end

  if cmd == "nav" then
    local turnOn = parseOnOffArg(arg)
    if turnOn == nil then
      navCmdLog("Comando invalido. Use: !nav on/off")
      return true
    end
    if not turnOn then
      clearNavCommandQueue()
    end
    setNavLeaderSystemEnabled(turnOn)
    navCmdLog("Nav " .. (turnOn and "ON" or "OFF") .. ".")
    markNavCommandBusy(NAV_CMD_CFG.toggleLockMs)
    return true
  end

  if cmd == "combo" then
    local turnOn = parseOnOffArg(arg)
    if turnOn == nil then
      navCmdLog("Comando invalido. Use: !combo on/off")
      return true
    end
    setComboEnabled(turnOn)
    navCmdLog("Combo " .. (turnOn and "ON" or "OFF") .. ".")
    markNavCommandBusy(NAV_CMD_CFG.toggleLockMs)
    return true
  end

  if cmd == "route" then
    local turnOn = parseOnOffArg(arg)
    if turnOn == nil then
      navCmdLog("Comando invalido. Use: !route on/off")
      return true
    end
    setRouteFallbackEnabled(turnOn)
    navCmdLog("Route fallback " .. (turnOn and "ON" or "OFF") .. ".")
    markNavCommandBusy(NAV_CMD_CFG.toggleLockMs)
    return true
  end

  if cmd == "follow" then
    local turnOn = parseOnOffArg(arg)
    if turnOn ~= nil then
      setFollowSystemEnabled(turnOn)
      navCmdLog("Follow " .. (turnOn and "ON" or "OFF") .. ".")
      markNavCommandBusy(NAV_CMD_CFG.toggleLockMs)
      return true
    end
    local followName = trim(arg)
    if followName == "" then
      navCmdLog("Comando invalido. Use: !follow on/off ou !follow Nome")
      return true
    end
    setFollowTargetName(followName)
    navCmdLog("Follow target definido para '" .. followName .. "'.")
    markNavCommandBusy(NAV_CMD_CFG.genericLockMs)
    return true
  end

  if cmd == "combospell" then
    local spellName = trim(arg)
    if spellName == "" then
      navCmdLog("Comando invalido. Use: !combospell nomeDaMagia")
      return true
    end
    setComboSpellText(spellName)
    setComboMode("spell")
    navCmdLog("Combo spell definido para '" .. spellName .. "'.")
    markNavCommandBusy(NAV_CMD_CFG.genericLockMs)
    return true
  end

  if cmd == "comborune" then
    local runeId = tonumber(trim(arg))
    if not runeId then
      navCmdLog("Comando invalido. Use: !comborune idDaRune")
      return true
    end
    setComboRuneId(runeId)
    setComboMode("rune")
    navCmdLog("Combo rune definido para ID " .. tostring(cfg.combo.runeId) .. ".")
    markNavCommandBusy(NAV_CMD_CFG.genericLockMs)
    return true
  end

  if cmd == "changecavebot" then
    local cavebotProfile = trim(arg)
    if cavebotProfile == "" then
      navCmdLog("Comando invalido. Use: !changecavebot nomeDoPerfil")
      return true
    end
    if not CaveBot or type(CaveBot.setCurrentProfile) ~= "function" then
      navCmdLog("CaveBot indisponivel para troca de perfil.")
      return true
    end
    local profileOk = profileExists("cavebot_configs", "cfg", cavebotProfile)
    if profileOk == false then
      navCmdLog("Profile de CaveBot nao encontrado: '" .. cavebotProfile .. "'.")
      return true
    end
    CaveBot.setCurrentProfile(cavebotProfile)
    if CaveBot.getCurrentProfile and trim(CaveBot.getCurrentProfile() or ""):lower() == cavebotProfile:lower() then
      navCmdLog("CaveBot profile alterado para '" .. cavebotProfile .. "'.")
    else
      navCmdLog("Nao foi possivel alterar CaveBot profile para '" .. cavebotProfile .. "'.")
    end
    markNavCommandBusy(NAV_CMD_CFG.profileLockMs)
    return true
  end

  if cmd == "changetargetbot" then
    local targetbotProfile = trim(arg)
    if targetbotProfile == "" then
      navCmdLog("Comando invalido. Use: !changetargetbot nomeDoPerfil")
      return true
    end
    if not TargetBot or type(TargetBot.setCurrentProfile) ~= "function" then
      navCmdLog("TargetBot indisponivel para troca de perfil.")
      return true
    end
    local profileOk = profileExists("targetbot_configs", "json", targetbotProfile)
    if profileOk == false then
      navCmdLog("Profile de TargetBot nao encontrado: '" .. targetbotProfile .. "'.")
      return true
    end
    TargetBot.setCurrentProfile(targetbotProfile)
    if TargetBot.getCurrentProfile and trim(TargetBot.getCurrentProfile() or ""):lower() == targetbotProfile:lower() then
      navCmdLog("TargetBot profile alterado para '" .. targetbotProfile .. "'.")
    else
      navCmdLog("Nao foi possivel alterar TargetBot profile para '" .. targetbotProfile .. "'.")
    end
    markNavCommandBusy(NAV_CMD_CFG.profileLockMs)
    return true
  end

  if cmd == "viajar" then
    local city = trim(arg)
    if city == "" then
      navCmdLog("Comando invalido. Use: !viajar cidade")
      return true
    end
    scheduleTravelNpcTalk(city)
    markNavTravelBusy()
    markNavCommandBusy(NAV_CMD_CFG.genericLockMs)
    return true
  end

  if cmd == "refilar" then
    local refillNpc = trim(arg)
    if refillNpc == "" then
      refillLog("Comando invalido. Use: !refilar nomeDoNpc")
      return true
    end
    local ok, message = startRefillCommand(refillNpc)
    if ok then
      refillLog(string.format("Iniciando refil no NPC '%s'.", message or refillNpc))
    else
      refillLog(message or "Falha ao iniciar refil.")
    end
    markNavCommandBusy(NAV_CMD_CFG.genericLockMs)
    return true
  end

  if cmd == "say" then
    local sayText = trim(arg)
    if sayText == "" then
      navCmdLog("Comando invalido. Use: !say texto")
      return true
    end
    say(sayText)
    markNavCommandBusy(NAV_CMD_CFG.genericLockMs)
    return true
  end

  if cmd == "npcsay" then
    local npcText = trim(arg)
    if npcText == "" then
      navCmdLog("Comando invalido. Use: !npcsay texto")
      return true
    end
    npcSay(npcText)
    markNavCommandBusy(NAV_CMD_CFG.genericLockMs)
    return true
  end

  return false
end

local function getQueuedNavCommandBlockReason(entry)
  if not entry then
    return "wait"
  end
  local nowMs = timeMs()
  if nowMs < (navCmdQueueState.busyUntil or 0) then
    return "wait"
  end
  if nowMs < (navCmdQueueState.travelUntil or 0) then
    return "wait"
  end
  if not isNavLeaderSystemEnabled() and not isNavOnCommand(entry.name, entry.arg) then
    return "drop"
  end
  if refillCommandState.active then
    local navOffCommand = entry.name == "nav" and parseOnOffArg(entry.arg) == false
    if not navOffCommand then
      return "wait"
    end
  end
  return nil
end

if content.leaderNameEdit then
  content.leaderNameEdit.onTextChange = function(_, text)
    cfg.leaderName = trim(text)
    clearComboLeaderTarget()
    clearComboTriggers()
    if comboUi and comboUi.leaderInfoLabel then
      local navLeader = cfg.leaderName ~= "" and cfg.leaderName or "-"
      comboUi.leaderInfoLabel:setText("Leader: " .. navLeader)
    end
    resetRouteFallbackState(true)
  end
end

if content.navLeaderSwitch then
  content.navLeaderSwitch.onClick = function(widget)
    setNavLeaderSystemEnabled(not cfg.navLeaderEnabled)
  end
end

if content.followNameEdit then
  content.followNameEdit.onTextChange = function(_, text)
    cfg.followName = trim(text)
    followRuntimeState.nextMoveSeq()
    followRuntimeState.lastLeaderPos = nil
    followRuntimeState.lastLeaderSeenAt = 0
    resetRouteFallbackState(true)
    followSelfSuppressed = false
    shouldSuppressFollowForSelf()
  end
end

if content.followSwitch then
  content.followSwitch.onClick = function(widget)
    setFollowSystemEnabled(not cfg.followEnabled)
  end
end

if content.enableSwitch then
  content.enableSwitch.onClick = function()
    if mainUiSyncLock then
      return
    end
    setFollowEnabled(not cfg.enabled)
  end
end

if settingsPanel and settingsPanel ~= contentRoot then
  settingsPanel:setVisible(true)
  ensurePanelHeight(settingsPanel)
  schedule(50, function()
    ensurePanelHeight(settingsPanel)
  end)
end

if content.pauseCavebotSwitch then
  content.pauseCavebotSwitch.onClick = function(widget)
    cfg.cavebotPause.enabled = not cfg.cavebotPause.enabled
    widget:setOn(cfg.cavebotPause.enabled)
  end
end

if content.pauseDistanceSpin then
  content.pauseDistanceSpin.onValueChange = function(widget, value)
    cfg.cavebotPause.distance = clampNumber(value, 1, 20, cfg.cavebotPause.distance)
    widget:setValue(cfg.cavebotPause.distance)
  end
end

if content.pauseMcNamesEdit then
  content.pauseMcNamesEdit.onTextChange = function(_, text)
    cfg.cavebotPause.mcNames = trim(text)
    if commandsUi and commandsUi.refreshHudSendUi then
      commandsUi.refreshHudSendUi()
    end
  end
end

if content.pingAutoSwitch then
  content.pingAutoSwitch.onClick = function(widget)
    cfg.pingConfig.auto = not cfg.pingConfig.auto
    widget:setOn(cfg.pingConfig.auto)
    if content.pingManualSpin then
      content.pingManualSpin:setEnabled(not cfg.pingConfig.auto)
    end
  end
end

if content.pingManualSpin then
  content.pingManualSpin.onValueChange = function(widget, value)
    cfg.pingConfig.manualMs = clampNumber(value, 0, 1000, cfg.pingConfig.manualMs)
    widget:setValue(cfg.pingConfig.manualMs)
  end
end

if content.comboSetupButton then
  content.comboSetupButton.onClick = function()
    openComboWindow()
  end
end

if comboUi.enableSwitch then
  comboUi.enableSwitch.onClick = function(widget)
    setComboEnabled(not cfg.combo.enabled)
  end
end

if comboUi.modeButton then
  comboUi.modeButton.onClick = function()
    if cfg.combo.mode == "rune" then
      setComboMode("spell")
    else
      setComboMode("rune")
    end
  end
end

if comboUi.spellEdit then
  comboUi.spellEdit.onTextChange = function(_, text)
    cfg.combo.spellText = trim(text)
  end
end

if comboUi.triggerWordEdit then
  comboUi.triggerWordEdit.onTextChange = function(_, text)
    cfg.combo.triggerWord = trim(text)
  end
end

if comboUi.runeSpin then
  comboUi.runeSpin.onValueChange = function(widget, value)
    cfg.combo.runeId = clampNumber(value, 100, 100000, cfg.combo.runeId)
    widget:setValue(cfg.combo.runeId)
  end
end

if content.routeFallbackSwitch then
  content.routeFallbackSwitch.onClick = function(widget)
    setRouteFallbackEnabled(not cfg.routeFallback.enabled)
  end
end

if content.routeFallbackStepSpin then
  content.routeFallbackStepSpin.onValueChange = function(widget, value)
    cfg.routeFallback.stepMs = clampNumber(value, 80, 1000, cfg.routeFallback.stepMs)
    widget:setValue(cfg.routeFallback.stepMs)
  end
end

if content.routeFallbackEditButton then
  content.routeFallbackEditButton.onClick = function()
    openRouteFallbackWindow()
  end
end

if content.hudSetupToggleButton then
  content.hudSetupToggleButton.onClick = function()
    commandsUi.setHudVisible(not (cfg.hudSetup and cfg.hudSetup.visible == true))
  end
end

if content.hudPosXSpin then
  content.hudPosXSpin.onValueChange = function(widget, value)
    if commandsUi and commandsUi.hudPosUiSyncing == true then
      return
    end
    cfg.hudSetup = cfg.hudSetup or {}
    cfg.hudSetup.posX = clampNumber(value, 0, 5000, cfg.hudSetup.posX or 980)
    widget:setValue(cfg.hudSetup.posX)
    if commandsUi and commandsUi.applyHudPosition then
      commandsUi.applyHudPosition()
    end
  end
end

if content.hudPosYSpin then
  content.hudPosYSpin.onValueChange = function(widget, value)
    if commandsUi and commandsUi.hudPosUiSyncing == true then
      return
    end
    cfg.hudSetup = cfg.hudSetup or {}
    cfg.hudSetup.posY = clampNumber(value, 0, 5000, cfg.hudSetup.posY or 160)
    widget:setValue(cfg.hudSetup.posY)
    if commandsUi and commandsUi.applyHudPosition then
      commandsUi.applyHudPosition()
    end
  end
end

if content.hudSendModeCombo then
  content.hudSendModeCombo.onOptionChange = function(_, _, data)
    cfg.hudSetup = cfg.hudSetup or {}
    local mode = trim(data or ""):lower()
    if mode ~= "pm" and mode ~= "guild" then
      mode = "default"
    end
    cfg.hudSetup.sendMode = mode
    if commandsUi and commandsUi.refreshHudSendUi then
      commandsUi.refreshHudSendUi()
    end
  end
end

if content.hudGuildChannelEdit then
  content.hudGuildChannelEdit.onTextChange = function(_, text)
    cfg.hudSetup = cfg.hudSetup or {}
    cfg.hudSetup.guildChannel = trim(text or "")
    if commandsUi and commandsUi.refreshHudSendUi then
      commandsUi.refreshHudSendUi()
    end
  end
end

if content.ropeIdEdit then
  content.ropeIdEdit.onTextChange = function(widget, text)
    cfg.tools.ropeId = clampNumber(text, 1, 100000, cfg.tools.ropeId)
    widget:setText(tostring(cfg.tools.ropeId))
  end
end

if content.shovelIdEdit then
  content.shovelIdEdit.onTextChange = function(widget, text)
    cfg.tools.shovelId = clampNumber(text, 1, 100000, cfg.tools.shovelId)
    widget:setText(tostring(cfg.tools.shovelId))
  end
end

if content.macheteIdEdit then
  content.macheteIdEdit.onTextChange = function(widget, text)
    cfg.tools.macheteId = clampNumber(text, 1, 100000, cfg.tools.macheteId)
    widget:setText(tostring(cfg.tools.macheteId))
  end
end

if content.laddersUpContainer then
  UI.Container(function(_, items)
    cfg.floorChangers.ladders.up = sanitizeIdList(items)
    refreshChangerSets()
  end, true, nil, content.laddersUpContainer)
end

if content.laddersDownContainer then
  UI.Container(function(_, items)
    cfg.floorChangers.ladders.down = sanitizeIdList(items)
    refreshChangerSets()
  end, true, nil, content.laddersDownContainer)
end

if content.holesDownContainer then
  UI.Container(function(_, items)
    cfg.floorChangers.holes.down = sanitizeIdList(items)
    refreshChangerSets()
  end, true, nil, content.holesDownContainer)
end

if content.ropeSpotsUpContainer then
  UI.Container(function(_, items)
    cfg.floorChangers.ropeSpots.up = sanitizeIdList(items)
    refreshChangerSets()
  end, true, nil, content.ropeSpotsUpContainer)
end

if content.stairsUpContainer then
  UI.Container(function(_, items)
    cfg.floorChangers.stairs.up = sanitizeIdList(items)
    refreshChangerSets()
  end, true, nil, content.stairsUpContainer)
end

if content.stairsDownContainer then
  UI.Container(function(_, items)
    cfg.floorChangers.stairs.down = sanitizeIdList(items)
    refreshChangerSets()
  end, true, nil, content.stairsDownContainer)
end

if content.sewersDownContainer then
  UI.Container(function(_, items)
    cfg.floorChangers.sewers.down = sanitizeIdList(items)
    refreshChangerSets()
  end, true, nil, content.sewersDownContainer)
end

if content.useTargetsContainer then
  UI.Container(function(_, items)
    cfg.useTargets = sanitizeIdList(items)
    refreshUseTargets()
  end, true, nil, content.useTargetsContainer)
end

if content.doorTargetsContainer then
  UI.Container(function(_, items)
    cfg.doorTargets = sanitizeIdList(items)
    refreshDoorTargets()
  end, true, nil, content.doorTargetsContainer)
end

mainUi.setupButton.onClick = function()
  openNovoFollowWindow()
end

if helpUi and helpUi.openButton then
  helpUi.openButton.onClick = function()
    openHelpWindow()
  end
end

if commandsUi and commandsUi.openButton then
  commandsUi.openButton.onClick = function()
    openCommandsWindow()
  end
end

onTalk(function(sender, level, mode, text, channelId, talkPos)
  if not cfg.enabled then
    return
  end
  if not sender or not text then
    return
  end
  local leaderName = getNavLeaderName()
  if leaderName == "" or sender:lower() ~= leaderName:lower() then
    return
  end

  local commandName, commandArg = text:match("^%s*!([%w_%-]+)%s*(.*)$")
  if not commandName then
    return
  end
  commandName = trim(commandName):lower()
  commandArg = trim(commandArg or "")
  if commandName == "" or not isNavCommandSupported(commandName) then
    return
  end

  if not isNavLeaderSystemEnabled() and not isNavOnCommand(commandName, commandArg) then
    return
  end

  local rejectCommand, rejectReason = shouldRejectNavCommandByRate(commandName, commandArg)
  if rejectCommand then
    if rejectReason and rejectReason ~= "" then
      navCmdLog(rejectReason)
    end
    return
  end

  if isNavCommandInstant(commandName) then
    executeLeaderChatCommand(commandName, commandArg)
    return
  end

  local queued, queueErr = enqueueNavCommand(commandName, commandArg)
  if not queued and queueErr and queueErr ~= "" then
    navCmdLog(queueErr)
  end
end)

onTalk(function(sender, level, mode, text, channelId, talkPos)
  if not cfg.enabled or not cfg.combo.enabled or not isNavLeaderSystemEnabled() then
    return
  end
  if not sender or not text then
    return
  end
  local leaderName = getNavLeaderName()
  if leaderName == "" or sender:lower() ~= leaderName:lower() then
    return
  end
  if talkPos and talkPos.z and talkPos.z ~= posz() then
    return
  end
  if not matchesComboTriggerText(text) then
    return
  end
  queueComboTrigger()
end)

onMissle(function(missle)
  if not cfg.enabled or not isNavLeaderSystemEnabled() then
    return
  end
  local leaderName = getNavLeaderName()
  if leaderName == "" then
    return
  end
  if not missle or not missle.getSource or not missle.getDestination then
    return
  end
  local sourcePos = missle:getSource()
  if not sourcePos or sourcePos.z ~= posz() then
    return
  end
  local fromTile = g_map.getTile(sourcePos)
  local toTile = g_map.getTile(missle:getDestination())
  if not fromTile or not toTile then
    return
  end
  local fromCreatures = fromTile:getCreatures()
  local toCreatures = toTile:getCreatures()
  if not fromCreatures or not toCreatures then
    return
  end
  if #fromCreatures ~= 1 or #toCreatures ~= 1 then
    return
  end
  local attacker = fromCreatures[1]
  if not attacker or not attacker.getName then
    return
  end
  if attacker:getName():lower() ~= leaderName:lower() then
    return
  end
  comboLeaderTarget = toCreatures[1]
  comboLeaderTargetAt = timeMs()
end)

onCreaturePositionChange(handleFollow3Movement)

local lastCatchUpAt = 0
local cavebotPausedByFollow = false

macro(NAV_CMD_CFG.queueStepMs, function()
  if #navCmdQueue == 0 then
    return
  end
  if g_game and g_game.isOnline and not g_game.isOnline() then
    return
  end
  if not cfg.enabled then
    clearNavCommandQueue()
    return
  end
  local nextCommand = navCmdQueue[1]
  if not nextCommand then
    return
  end
  local blockReason = getQueuedNavCommandBlockReason(nextCommand)
  if blockReason == "wait" then
    return
  end
  if blockReason == "drop" then
    table.remove(navCmdQueue, 1)
    return
  end
  table.remove(navCmdQueue, 1)
  executeLeaderChatCommand(nextCommand.name, nextCommand.arg)
end)

macro(180, function()
  if not cfg.enabled or not isNavLeaderSystemEnabled() then
    if refillCommandState.active then
      refillLog("Comando de refil cancelado (Nav OFF).")
      stopRefillCommand()
    end
    return
  end
  if g_game and g_game.isOnline and not g_game.isOnline() then
    return
  end
  if not refillCommandState.active then
    return
  end
  stepRefillCommand(timeMs())
end)

macro(120, function()
  if not cfg.enabled or not isNavLeaderSystemEnabled() then
    clearComboLeaderTarget()
    clearComboTriggers()
    return
  end
  if g_game and g_game.isOnline and not g_game.isOnline() then
    return
  end
  local leaderName = getNavLeaderName()
  if leaderName == "" then
    clearComboLeaderTarget()
    clearComboTriggers()
    return
  end
  local nowMs = timeMs()
  if comboLeaderTarget and nowMs - comboLeaderTargetAt > COMBO_TARGET_TIMEOUT_MS then
    clearComboLeaderTarget()
  end
  if comboLeaderTarget and not isComboTargetValid(comboLeaderTarget) then
    clearComboLeaderTarget()
  end

  local currentTarget = g_game and g_game.getAttackingCreature and g_game.getAttackingCreature() or nil
  if comboLeaderTarget and currentTarget ~= comboLeaderTarget and g_game and g_game.attack then
    g_game.attack(comboLeaderTarget)
    return
  end

  if not cfg.combo.enabled then
    clearComboTriggers()
    return
  end

  if comboPendingCount <= 0 then
    return
  end
  if comboPendingSince > 0 and nowMs - comboPendingSince > COMBO_TRIGGER_TIMEOUT_MS then
    clearComboTriggers()
    return
  end

  local targetForCombo = nil
  if comboLeaderTarget and isComboTargetValid(comboLeaderTarget) then
    targetForCombo = comboLeaderTarget
  elseif currentTarget and isComboTargetValid(currentTarget) then
    targetForCombo = currentTarget
  end

  if cfg.combo.mode == "rune" then
    if not targetForCombo then
      return
    end
    local runeId = clampNumber(cfg.combo.runeId, 100, 100000, 3155)
    if useRuneOnTarget(runeId, targetForCombo) then
      comboPendingCount = math.max(0, comboPendingCount - 1)
      if comboPendingCount == 0 then
        comboPendingSince = 0
      end
    end
    return
  end

  local spellText = trim(cfg.combo.spellText)
  if spellText == "" then
    clearComboTriggers()
    return
  end
  say(spellText)
  comboPendingCount = math.max(0, comboPendingCount - 1)
  if comboPendingCount == 0 then
    comboPendingSince = 0
  end
end)

macro(200, function()
  if not cfg.enabled or not isFollowSystemEnabled() then
    return
  end
  if g_game and g_game.isOnline and not g_game.isOnline() then
    return
  end
  local leaderName = getFollowLeaderName()
  if leaderName == "" then
    return
  end
  if shouldSuppressFollowForSelf() then
    return
  end
  local nowMs = timeMs()
  local me = pos()
  if not me or not isMapPos(me) then
    return
  end
  local leader = getCreatureByName(leaderName)
  if not leader or not leader.getPosition then
    local lastLeaderPos = followRuntimeState.lastLeaderPos
    local hasFreshLastPos = lastLeaderPos and isMapPos(lastLeaderPos)
      and nowMs - (followRuntimeState.lastLeaderSeenAt or 0) <= (followRuntimeState.lastSeenMaxAgeMs or 12000)
    if hasFreshLastPos then
      if lastLeaderPos.z == me.z then
        local distToLast = getDistanceBetween(me, lastLeaderPos)
        if distToLast and distToLast > 1 and nowMs - lastCatchUpAt >= scaleDelay(CATCHUP_COOLDOWN_MS, 0.5) then
          tryUseDoorsAround(me)
          local walkedToLast = follow3AutoWalk(lastLeaderPos, followRuntimeState.catchupPrecision or 1)
          if not walkedToLast then
            tryApproachDoor(lastLeaderPos)
          end
          lastCatchUpAt = nowMs
        end
      else
        followRuntimeState.tryFloorRecovery(lastLeaderPos, nowMs)
      end
    end
    if cfg.routeFallback and cfg.routeFallback.enabled then
      if routeFallbackState.missingSince == 0 then
        routeFallbackState.missingSince = nowMs
      end
      if nowMs - routeFallbackState.missingSince >= ROUTE_FALLBACK_TRIGGER_MS then
        runRouteFallbackStep(nowMs)
      end
    else
      resetRouteFallbackState(true)
    end
    return
  end
  resetRouteFallbackState(true)
  local lpos = leader:getPosition()
  if not lpos or not isMapPos(lpos) then
    return
  end
  followRuntimeState.cacheLeaderPos(lpos, nowMs)
  if lpos.z ~= me.z then
    followRuntimeState.tryFloorRecovery(lpos, nowMs)
    return
  end
  local catchupDistance = clampNumber(cfg.cavebotPause and cfg.cavebotPause.distance, 1, 20, 4)
  if getDistanceBetween(me, lpos) <= catchupDistance then
    return
  end
  tryUseDoorsAround(me)
  if nowMs - lastCatchUpAt < scaleDelay(CATCHUP_COOLDOWN_MS, 0.5) then
    return
  end
  local walked = follow3AutoWalk(lpos, followRuntimeState.catchupPrecision or 1)
  if not walked then
    tryApproachDoor(lpos)
  end
  lastCatchUpAt = nowMs
end)

macro(500, function()
  if not cfg.enabled or not isFollowSystemEnabled() or not cfg.cavebotPause.enabled then
    return
  end
  if g_game and g_game.isOnline and not g_game.isOnline() then
    return
  end
  local leaderName = getFollowLeaderName()
  if leaderName == "" then
    return
  end
  if not isLocalLeader(leaderName) then
    return
  end
  if not CaveBot or not CaveBot.isOn or not CaveBot.isOff or not CaveBot.setOff or not CaveBot.setOn then
    return
  end
  local mcNames = splitNames(cfg.cavebotPause.mcNames)
  if #mcNames == 0 then
    return
  end
  local shouldPause = false
  for _, mcName in ipairs(mcNames) do
    local mc = getCreatureByName(mcName)
    if not mc or not mc.getPosition then
      shouldPause = true
      break
    end
    local mpos = mc:getPosition()
    if not mpos or not isMapPos(mpos) then
      shouldPause = true
      break
    end
    if mpos.z ~= posz() then
      shouldPause = true
      break
    end
    if getDistanceBetween(pos(), mpos) > cfg.cavebotPause.distance then
      shouldPause = true
      break
    end
  end

  if shouldPause then
    if CaveBot.isOn() then
      CaveBot.setOff()
      cavebotPausedByFollow = true
    end
  else
    if cavebotPausedByFollow and CaveBot.isOff() then
      CaveBot.setOn()
      cavebotPausedByFollow = false
    end
  end
end)

local function consumePainelFollowBridge()
  local bridge = storage and storage.painelDeIconesBridge
  if type(bridge) ~= "table" or bridge.followDesired == nil then
    return
  end

  local desired = bridge.followDesired == true
  bridge.followDesired = nil

  if desired then
    setFollowEnabled(true)
    setFollowSystemEnabled(true)
    return
  end

  setFollowSystemEnabled(false)
end

local function consumePainelNavBridge()
  local bridge = storage and storage.painelDeIconesBridge
  if type(bridge) ~= "table" or bridge.navDesired == nil then
    return
  end

  local desired = bridge.navDesired == true
  bridge.navDesired = nil

  if desired then
    setFollowEnabled(true)
    setNavLeaderSystemEnabled(true)
    return
  end

  setNavLeaderSystemEnabled(false)
end

consumePainelFollowBridge()
consumePainelNavBridge()
local followBridgeSyncMacro = macro(250, function()
  consumePainelFollowBridge()
  consumePainelNavBridge()
end)

NovoFollowController = {
  setOn = function(...)
    local value = true
    local args = {...}
    if type(args[1]) == "boolean" then
      value = args[1]
    elseif type(args[2]) == "boolean" then
      value = args[2]
    end
    local turnOn = value == true
    if turnOn then
      setFollowEnabled(true)
      setFollowSystemEnabled(true)
    else
      setFollowSystemEnabled(false)
    end
  end,
  setOff = function()
    setFollowSystemEnabled(false)
  end,
  isOn = function()
    return cfg.enabled == true and isFollowSystemEnabled()
  end
}

NovoNavController = {
  setOn = function(...)
    local value = true
    local args = {...}
    if type(args[1]) == "boolean" then
      value = args[1]
    elseif type(args[2]) == "boolean" then
      value = args[2]
    end
    local turnOn = value == true
    if turnOn then
      setFollowEnabled(true)
      setNavLeaderSystemEnabled(true)
    else
      setNavLeaderSystemEnabled(false)
    end
  end,
  setOff = function()
    setNavLeaderSystemEnabled(false)
  end,
  isOn = function()
    return cfg.enabled == true and isNavLeaderSystemEnabled()
  end
}
