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
elfHotkeysLastCount = elfHotkeysLastCount or 0
elfHotkeysLastFired = false

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
local botStartedAtMs = tonumber(time) or os.time() * 1000
local saveProfileStorage = saveConfig

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
  if not player or not state then return false end
  return bit.band(player:getStates(), state) > 0
end

local function nowMs()
  return tonumber(time) or os.time() * 1000
end

local function boolNumber(value)
  return value and 1 or 0
end

local skillIndexByName = {
  fist = 0,
  club = 1,
  sword = 2,
  axe = 3,
  distance = 4,
  shielding = 5,
  fishing = 6
}

local function getSkillValue(player, kind, skillName)
  if skillName == "mlevel" or skillName == "magic" or skillName == "magiclevel" then
    if kind == "skillpc" and player.getMagicLevelPercent then return player:getMagicLevelPercent() or 0 end
    if kind == "skilltime" then return 0 end
    return player:getMagicLevel() or 0
  end
  local skillId = skillIndexByName[tostring(skillName or ""):lower()]
  if skillId == nil then return 0 end
  if kind == "skillpc" and player.getSkillLevelPercent then return player:getSkillLevelPercent(skillId) or 0 end
  if kind == "skilltime" then return 0 end
  if player.getSkillLevel then return player:getSkillLevel(skillId) or 0 end
  return 0
end

local function screenValue(part)
  local root = g_ui and g_ui.getRootWidget and g_ui.getRootWidget()
  local rect = root and root.getRect and root:getRect()
  if not rect then return 0 end
  part = tostring(part or ""):lower()
  if part == "screenleft" then return rect.x or 0 end
  if part == "screenright" then return (rect.x or 0) + (rect.width or 0) end
  if part == "screentop" then return rect.y or 0 end
  if part == "screenbottom" then return (rect.y or 0) + (rect.height or 0) end
  return 0
end

local function modifierPressed(name)
  if not g_keyboard then return false end
  name = tostring(name or ""):lower()
  if name == "ctrl" and g_keyboard.isCtrlPressed then return g_keyboard.isCtrlPressed() end
  if name == "shift" and g_keyboard.isShiftPressed then return g_keyboard.isShiftPressed() end
  if name == "alt" and g_keyboard.isAltPressed then return g_keyboard.isAltPressed() end
  return false
end

local function keyPressed(keyId)
  keyId = tonumber(keyId)
  if not keyId or not g_keyboard or not g_keyboard.isKeyPressed then return false end
  return g_keyboard.isKeyPressed(keyId)
end

local function sameName(left, right)
  return tostring(left or ""):lower():trim() == tostring(right or ""):lower():trim()
end

local function listHasName(list, name)
  if type(list) ~= "table" then return false end
  for _, entry in pairs(list) do
    if sameName(entry, name) then return true end
  end
  return false
end

local function relationByName(relation, name)
  relation = tostring(relation or ""):lower()
  if relation == "isfriend" and type(isFriend) == "function" then
    local ok, result = pcall(isFriend, name)
    if ok and result ~= nil then return result == true end
  elseif relation == "isenemy" and type(isEnemy) == "function" then
    local ok, result = pcall(isEnemy, name)
    if ok and result ~= nil then return result == true end
  end

  local playerList = type(storage) == "table" and type(storage.playerList) == "table" and storage.playerList or {}
  if relation == "isfriend" then return listHasName(playerList.friendList, name) end
  if relation == "isenemy" then return listHasName(playerList.enemyList, name) end
  if relation == "issubfriend" then return listHasName(playerList.subFriendList or playerList.subfriendList, name) end
  if relation == "issubenemy" then return listHasName(playerList.subEnemyList or playerList.subenemyList, name) end
  if relation == "isleader" then return listHasName(storage and storage.partyLeaders, name) end
  return false
end

local slotByElfName = {
  ringslot = InventorySlotFinger,
  beltslot = InventorySlotAmmo,
  ammoslot = InventorySlotAmmo,
  backslot = InventorySlotBack,
  rhandslot = InventorySlotRight,
  lhandslot = InventorySlotLeft,
  amuletslot = InventorySlotNeck,
  bootsslot = InventorySlotFeet,
  legsslot = InventorySlotLeg,
  chestslot = InventorySlotBody,
  headslot = InventorySlotHead
}

local function slotValue(slotName, property)
  local player = getPlayer()
  local slot = slotByElfName[tostring(slotName or ""):lower()]
  if not player or not slot then return 0 end
  local item = player:getInventoryItem(slot)
  if not item then return 0 end
  property = tostring(property or ""):lower()
  if property == "id" then return item:getId() or 0 end
  if property == "count" then return math.max(1, item:getCount() or 1) end
  return 0
end

local function creatureValue(creature, property)
  if not creature then return 0 end
  property = tostring(property or ""):lower()
  if property == "name" and creature.getName then return creature:getName() or "" end
  if property == "id" and creature.getId then return creature:getId() or 0 end
  if property == "hp" and creature.getHealth then return creature:getHealth() or 0 end
  if property == "maxhp" and creature.getMaxHealth then return creature:getMaxHealth() or 0 end
  if property == "mp" and creature.getMana then return creature:getMana() or 0 end
  if property == "maxmp" and creature.getMaxMana then return creature:getMaxMana() or 0 end
  if property == "hppc" then return creature:getHealthPercent() or 0 end
  if property == "speed" and creature.getSpeed then return creature:getSpeed() or 0 end
  if property == "dir" and creature.getDirection then return creature:getDirection() or 0 end
  if property == "outfit" and creature.getOutfit then
    local outfit = creature:getOutfit()
    return type(outfit) == "table" and (outfit.type or outfit.lookType or 0) or 0
  end
  if property == "skull" and creature.getSkull then return creature:getSkull() or 0 end
  if property == "party" and creature.getShield then return creature:getShield() or 0 end
  if property == "warbanner" and creature.getEmblem then return creature:getEmblem() or 0 end
  if property == "posx" then
    local pos = creature:getPosition()
    return pos and pos.x or 0
  end
  if property == "posy" then
    local pos = creature:getPosition()
    return pos and pos.y or 0
  end
  if property == "posz" then
    local pos = creature:getPosition()
    return pos and pos.z or 0
  end
  if property == "distance" then
    local player = getPlayer()
    return player and dist(player:getPosition(), creature:getPosition()) or 999
  end
  if property == "distx" then
    local player = getPlayer()
    local playerPos = player and player:getPosition()
    local creaturePos = creature:getPosition()
    return playerPos and creaturePos and math.abs(playerPos.x - creaturePos.x) or 999
  end
  if property == "disty" then
    local player = getPlayer()
    local playerPos = player and player:getPosition()
    local creaturePos = creature:getPosition()
    return playerPos and creaturePos and math.abs(playerPos.y - creaturePos.y) or 999
  end
  if property == "isplayer" then return boolNumber(creature.isPlayer and creature:isPlayer()) end
  if property == "ismonster" then return boolNumber(creature.isMonster and creature:isMonster()) end
  if property == "isnpc" then return boolNumber(creature.isNpc and creature:isNpc()) end
  if property == "isonscreen" then
    local player = getPlayer()
    return boolNumber(player and creature:getPosition().z == player:getPosition().z)
  end
  if property == "isshootable" then return boolNumber(creature.canShoot and creature:canShoot()) end
  if property == "isparalyzed" then return boolNumber(creature.getStates and bit.band(creature:getStates(), Paralyze or 0) > 0) end
  if property == "isenemy" then return boolNumber(type(isEnemy) == "function" and isEnemy(creature)) end
  if property == "isfriend" then return boolNumber(type(isFriend) == "function" and isFriend(creature)) end
  if property == "haslookinfo" then return 0 end
  if property == "issubenemy" or property == "issubfriend" or property == "isleader" then return 0 end
  return 0
end

local function itemDisplayName(item)
  if not item then return "" end
  if item.getName then
    local ok, name = pcall(function() return item:getName() end)
    if ok and name and name ~= "" then return tostring(name):lower() end
  end
  if Item and Item.create and item.getId then
    local ok, market = pcall(function()
      local created = Item.create(item:getId())
      return created and created.getMarketData and created:getMarketData()
    end)
    if ok and market and market.name then return tostring(market.name):lower() end
  end
  return ""
end

local function itemCountByName(itemName)
  itemName = tostring(itemName or ""):lower():trim()
  if itemName == "" then return 0 end
  local total = 0
  local function addItem(item)
    if item and itemDisplayName(item) == itemName then
      total = total + math.max(1, item:getCount() or 1)
    end
  end
  for _, container in pairs(g_game.getContainers() or {}) do
    for _, item in ipairs(container:getItems() or {}) do
      addItem(item)
    end
  end
  local player = getPlayer()
  if player then
    for _, slot in pairs(slotByElfName) do
      addItem(player:getInventoryItem(slot))
    end
  end
  elfHotkeysLastCount = total
  return total
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
  elfHotkeysLastCount = total
  return total
end

local function topItemId(x, y, z)
  local tile = g_map.getTile({x = tonumber(x) or 0, y = tonumber(y) or 0, z = tonumber(z) or 0})
  local thing = tile and tile.getTopUseThing and tile:getTopUseThing()
  return thing and thing.getId and thing:getId() or 0
end

local function isTileItem(x, y, z, itemId)
  local tile = g_map.getTile({x = tonumber(x) or 0, y = tonumber(y) or 0, z = tonumber(z) or 0})
  itemId = tonumber(itemId) or 0
  if not tile or itemId <= 0 then return 0 end
  for _, item in ipairs(tile:getItems() or {}) do
    if item and item.getId and item:getId() == itemId then return 1 end
  end
  return 0
end

local function screenCountByName(creatureName)
  creatureName = tostring(creatureName or ""):lower():trim()
  if creatureName == "" then return 0 end
  local count = 0
  local player = getPlayer()
  for _, creature in ipairs(getSpectators()) do
    if creature and creature ~= player and creature.getName and sameName(creature:getName(), creatureName) then
      count = count + 1
    end
  end
  return count
end

local creatureAliases = {
  target = true,
  attacked = true,
  attacker = true,
  pk = true,
  lastdmger = true,
  pattacker = true,
  mattacker = true,
  enemy = true,
  friend = true,
  subenemy = true,
  subfriend = true,
  anyenemy = true,
  anyfriend = true,
  coretarget = true,
  triggertarget = true,
  autoaimtarget = true,
  followed = true,
  self = true
}

local function resolveCreatureAlias(alias)
  alias = tostring(alias or ""):lower()
  if alias == "self" then
    return getPlayer()
  end
  if alias == "followed" and g_game.getFollowingCreature then
    return g_game.getFollowingCreature()
  end
  return g_game.getAttackingCreature and g_game.getAttackingCreature() or nil
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
  if var == "maxhp" then return player:getMaxHealth() or 0 end
  if var == "mp" or var == "mana" then return player:getMana() or 0 end
  if var == "maxmp" then return player:getMaxMana() or 0 end
  if var == "cap" then return player:getFreeCapacity() or player:getCapacity() or 0 end
  if var == "exp" then return player:getExperience() or 0 end
  if var == "level" then return player:getLevel() or 0 end
  if var == "mlevel" then return player:getMagicLevel() or 0 end
  if var == "name" then return player:getName() or "" end
  if var == "pkname" or var == "lastdmgername" then
    local target = g_game.getAttackingCreature()
    return target and target.getName and target:getName() or ""
  end
  if var == "count" then return elfHotkeysLastCount or 0 end
  if var == "dmgs" or var == "lastdmg" or var == "lastdmgtype" or var == "poisondmg" then return 0 end
  if var == "screenleft" or var == "screenright" or var == "screentop" or var == "screenbottom" then return screenValue(var) end
  if var == "exptnl" or var == "exph" or var == "expgained" or var:match("^exptolevel%.%d+$") or var:match("^timetolevel%.%d+$") or var == "timetnl" then return 0 end
  if var == "systime" then return os.date("%H:%M:%S") end
  if var == "sysdate" then return os.date("%A, %B %d %Y") end
  if var == "soul" then return player:getSoul() or 0 end
  if var == "stamina" then return player:getStamina() or 0 end
  if var == "posx" then return player:getPosition().x or 0 end
  if var == "posy" then return player:getPosition().y or 0 end
  if var == "posz" then return player:getPosition().z or 0 end
  if var == "connected" then return boolNumber(g_game.isOnline()) end
  if var == "ping" then return g_game.getPing and (tonumber(g_game.getPing()) or 0) or 0 end
  if var == "time" then return math.floor(nowMs() / 1000) end
  if var == "times" then return nowMs() end
  if var == "deltatime" then return math.floor((nowMs() - botStartedAtMs) / 1000) end
  if var == "deltatimems" then return nowMs() - botStartedAtMs end
  if var == "pzone" then return hasState(Pz) and 1 or 0 end
  if var == "inpz" then return boolNumber(hasState(Pz)) end
  if var == "battlesign" or var == "redbattlesign" then return boolNumber(hasState(Swords)) end
  if var == "paralyzed" then return hasState(Paralyze) and true or false end
  if var == "hasted" then return hasState(Haste) and 1 or 0 end
  if var == "manashielded" or var == "shielded" then return hasState(ManaShield) and 1 or 0 end
  if var == "poisoned" then return boolNumber(hasState(Poison)) end
  if var == "drunk" then return boolNumber(hasState(Drunk)) end
  if var == "invisible" then return boolNumber(hasState(Invisible)) end
  if var == "gmaround" then return gmAround() end
  if var == "strengthtime" then return 0 end
  if var == "mshieldtime" or var == "hastetime" or var == "invistime" then return 0 end
  if var == "waypointson" or var == "caveboton" then return boolNumber(CaveBot and CaveBot.isOn and CaveBot.isOn()) end
  if var == "targetingon" then return boolNumber(TargetBot and TargetBot.isOn and TargetBot.isOn()) end
  if var == "autocomboon" or var == "navion" or var == "synctime" or var == "exectime" or var == "sbtime" or var == "sstime" then return 0 end
  if var == "fired" then return boolNumber(elfHotkeysLastFired) end
  if var == "ctrl" or var == "shift" or var == "alt" then return boolNumber(modifierPressed(var)) end
  if var == "target" or var == "attacked" then return boolNumber(resolveCreatureAlias("target")) end

  local skillKind, skillName = var:match("^(skillpc)%.([%w_]+)$")
  if skillKind then return getSkillValue(player, skillKind, skillName) end
  skillKind, skillName = var:match("^(skilltime)%.([%w_]+)$")
  if skillKind then return getSkillValue(player, skillKind, skillName) end
  skillKind, skillName = var:match("^(skill)%.([%w_]+)$")
  if skillKind then return getSkillValue(player, skillKind, skillName) end

  local r = var:match("^monstersaround%.(%d+)$")
  if r then return countMonsters(tonumber(r)) end

  r = var:match("^playersaround%.(%d+)$")
  if r then return countPlayers(tonumber(r)) end

  r = var:match("^itemcount%.(%d+)$")
  if r then return itemCount(tonumber(r)) end

  local quoted = var:match("^itemcount%.'(.+)'$")
  if quoted then return itemCountByName(quoted) end

  r = var:match("^winitemcount%.(%d+)$")
  if r then return itemCount(tonumber(r)) end

  quoted = var:match("^winitemcount%.'(.+)'$")
  if quoted then return itemCountByName(quoted) end

  quoted = var:match("^screencount%.'(.+)'$")
  if quoted then return screenCountByName(quoted) end

  local relation, relationName = var:match("^([%a]+)%.'(.+)'$")
  if relationName and (relation == "isfriend" or relation == "isenemy" or relation == "issubfriend" or relation == "issubenemy" or relation == "isleader") then
    return boolNumber(relationByName(relation, relationName))
  end

  r = var:match("^key%.(%d+)$")
  if r then return boolNumber(keyPressed(r)) end

  local x, y, z = var:match("^topitem%.(%d+)%.(%d+)%.(%d+)$")
  if x and y and z then return topItemId(x, y, z) end

  local itemId
  x, y, z, itemId = var:match("^istileitem%.(%d+)%.(%d+)%.(%d+)%.(%d+)$")
  if x and y and z and itemId then return isTileItem(x, y, z, itemId) end

  local rx, ry = var:match("^rand%.(%d+)%.(%d+)$")
  if rx and ry then
    rx = tonumber(rx) or 0
    ry = tonumber(ry) or rx
    if ry < rx then rx, ry = ry, rx end
    return math.random(rx, ry)
  end

  r = var:match("^rand%.(%d+)$")
  if r then return math.random(0, tonumber(r) or 0) end

  local slotName, slotProperty = var:match("^(%w+slot)%.(%w+)$")
  if slotName then return slotValue(slotName, slotProperty) end

  local creatureAlias, creatureProperty = var:match("^(%w+)%.(%w+)$")
  if creatureAlias and creatureProperty and creatureAliases[creatureAlias] then
    return creatureValue(resolveCreatureAlias(creatureAlias), creatureProperty)
  end

  return 0
end

local function evalCondition(cond)
  cond = trim(cond)
  if cond == "" then return true end
  local function replaceVariable(v)
    local val = varValue(v)
    if type(val) == "boolean" then return val and "true" or "false" end
    if type(val) == "string" then return string.format("%q", val) end
    return tostring(tonumber(val) or 0)
  end
  cond = cond:gsub("%$([%w_%.]+%.'[^']+')", replaceVariable)
  cond = cond:gsub("%$([%w_%.]+)", replaceVariable)
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

local function expandElfVariables(text)
  local function replaceVariable(v)
    local val = varValue(v)
    if type(val) == "boolean" then return val and "1" or "0" end
    return tostring(val)
  end
  text = tostring(text or ""):gsub("%$([%w_%.]+%.'[^']+')", replaceVariable)
  return text:gsub("%$([%w_%.]+)", replaceVariable)
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
    elfHotkeysLastFired = true
  end
end

local potionAliasItems = {
  mana = 268,
  smana = 237,
  gmana = 238,
  gsmana = 7642,
  health = 266,
  hp = 266,
  shp = 236,
  ghp = 239,
  uhp = 7643,
  spirit = 7642,
  greatspirit = 7642,
  uh = 3160,
  sd = 3155
}

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
  cmd = expandElfVariables(trim(cmd))
  if cmd == "" then return end
  local lcmd = cmd:lower()

  local sayText = cmd:match("^[Ss][Aa][Yy]%s+(.+)$")
  if sayText then
    g_game.talk(sayText:gsub('^"', ''):gsub('"$', ''))
    return
  end

  local itemId, targetName = lcmd:match("^useoncreature%s+(%d+)%s+([%w_]+)$")
  if itemId then return useOnCreature(itemId, targetName) end

  local countVisibleId = lcmd:match("^countitemsvisible%s+(%d+)$")
  if countVisibleId then
    elfHotkeysLastCount = itemCount(tonumber(countVisibleId))
    return
  end

  if lcmd:match("^wait%s+%d+$") then
    return
  end

  local aliasName, aliasTarget = lcmd:match("^([%w_]+)%s+([%w_]+)$")
  if aliasName and potionAliasItems[aliasName] and (aliasTarget == "self" or aliasTarget == "target") then
    return useOnCreature(potionAliasItems[aliasName], aliasTarget)
  end

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
  elfHotkeysLastFired = false
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
local skipToggleKey = nil
local hotkeyToggleRegistered = false
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

local function elfProfileLoaded()
  if type(ImperialElfBot_IsProfileLoaded) == "function" then
    local ok, loaded = pcall(ImperialElfBot_IsProfileLoaded)
    return ok and loaded == true
  end
  return modules and modules.game_bot and modules.game_bot.elfbotProfileLoadedThisSession == true
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
  if type(storage) == "table" then
    storage[SETTINGS_KEY] = hotkeysConfig
  end
  g_settings.setNode(SETTINGS_KEY, hotkeysConfig)
  g_settings.save()
  if type(saveProfileStorage) == "function" then
    pcall(saveProfileStorage)
  end
end

local function normalizeConfig()
  if not elfProfileLoaded() then
    hotkeysConfig = {enabled = false, persistent = false, nextId = 1, entries = {}}
    return
  end

  local saved = type(storage) == "table" and storage[SETTINGS_KEY] or nil
  if type(saved) ~= "table" then
    saved = g_settings.getNode(SETTINGS_KEY)
  end
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
  if type(storage) == "table" then
    storage[SETTINGS_KEY] = hotkeysConfig
  end
end

local function stopEntry(entryId)
  local events = hotkeyEvents[entryId]
  if events then
    for _, event in pairs(events) do
      if type(event) == "table" and type(event.setOff) == "function" then
        event.setOff()
      else
        removeEvent(event)
      end
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

  local runner
  runner = macro(interval, function()
    if not isEntryRunning(entryId) then
      runner.setOff()
      return true
    end
    local ok, err = pcall(function()
      if g_game.isOnline() and evalCondition(condition) then
        executeCommand(action)
      end
    end)
    if not ok then
      elfHotkeysLog("warning", "[ElfBot Hotkeys] Script error: " .. tostring(err))
    end
    return true
  end)

  hotkeyEvents[entryId][scheduleId] = runner
end

local function startEntry(entry, runImmediate)
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
      elseif runImmediate then
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
  if entry then hotkeyBindings[entry.id] = nil end
end

local refreshWindow
local setEntryEnabled
local scriptPreview

local function bindEntry(entry)
  unbindEntry(entry)
  if not entry or not hotkeysConfig.enabled or entry.hotkey == "" then
    return
  end
  hotkeyBindings[entry.id] = entry.hotkey
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
    startEntry(entry, true)
  end
  saveConfig()
  if refreshWindow then refreshWindow() end
  msg(string.format("%s: %s (%s)", entry.name ~= "" and entry.name or hotkeyText("Hotkey sem nome", "Unnamed hotkey"), entry.enabled and "ON" or "OFF", scriptPreview(entry.script)))
end

local function registerHotkeyToggle()
  if hotkeyToggleRegistered or type(onKeyDown) ~= "function" then
    return
  end
  hotkeyToggleRegistered = true
  onKeyDown(function(keyDesc)
    if skipToggleKey == keyDesc then
      skipToggleKey = nil
      return
    end
    if captureEntryId or not hotkeysConfig or not hotkeysConfig.enabled then
      return
    end
    for _, entry in ipairs(hotkeysConfig.entries) do
      if entry.hotkey ~= "" and entry.hotkey == keyDesc then
        setEntryEnabled(entry.id, not entry.enabled)
        return
      end
    end
  end)
end

scriptPreview = function(script)
  local preview = tostring(script or ""):gsub("[\r\n]+", " ")
  if #preview > 70 then
    return preview:sub(1, 67) .. "..."
  end
  return preview
end

local function setCaptureHint(text)
  if elfHotkeysWindow and elfHotkeysWindow.header and elfHotkeysWindow.header.captureLabel then
    elfHotkeysWindow.header.captureLabel:setText(text)
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
  row.script:setText(scriptPreview(entry.script))
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
    else
      saveConfig()
    end
  end
  row.script.onTextChange = function(_, text)
    entry.script = tostring(text or "")
  end
  row.script.onFocusChange = function(_, focused)
    if focused then
      selectedEntryId = entry.id
      return
    end
    if entry.enabled and hotkeysConfig.enabled then
      startEntry(entry)
    end
    saveConfig()
  end
  row.editButton:setText(hotkeyText("Editar", "Edit"))
  row.editButton.onClick = function()
    selectedEntryId = entry.id
    editScript(entry)
    return true
  end
  row.removeButton.onClick = function()
    unbindEntry(entry)
    stopEntry(entry.id)
    for index, candidate in ipairs(hotkeysConfig.entries) do
      if candidate.id == entry.id then
        table.remove(hotkeysConfig.entries, index)
        break
      end
    end
    if selectedEntryId == entry.id then
      selectedEntryId = nil
    end
    saveConfig()
    if refreshWindow then refreshWindow() end
    return true
  end
  row.onMousePress = function()
    selectedEntryId = entry.id
    return false
  end
end

refreshWindow = function()
  if not elfHotkeysWindow then return end
  elfHotkeysWindow:setText(hotkeyText("Hotkeys Personalizadas", "Custom Hotkeys"))
  elfHotkeysWindow.header.masterEnabled:setText(hotkeyText("Hotkeys ligadas", "Hotkeys enabled"))
  elfHotkeysWindow.header.persistent:setText(hotkeyText("Persistente", "Persistent"))
  elfHotkeysWindow.header.addButton:setText(hotkeyText("Criar Hotkey", "Create Hotkey"))
  elfHotkeysWindow.columnHeader.stateHeader:setText(hotkeyText("Lig.", "On"))
  elfHotkeysWindow.columnHeader.nameHeader:setText(hotkeyText("Nome", "Name"))
  elfHotkeysWindow.columnHeader.scriptHeader:setText("Script")
  elfHotkeysWindow.footer.saveButton:setText(hotkeyText("Salvar", "Save"))
  elfHotkeysWindow.footer.closeButton:setText(hotkeyText("Fechar", "Close"))
  elfHotkeysWindow.header.masterEnabled:setChecked(hotkeysConfig.enabled)
  elfHotkeysWindow.header.persistent:setChecked(hotkeysConfig.persistent)
  if not captureEntryId then
    setCaptureHint(hotkeyText("Clique no campo da tecla e depois pressione uma tecla.", "Click a key field, then press a key."))
  end
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
  registerHotkeyToggle()

  local rootWidget = g_ui.getRootWidget()
  if rootWidget and rootWidget.recursiveGetChildById then
    local oldWindow = rootWidget:recursiveGetChildById("elfHotkeysWindow")
    if oldWindow then oldWindow:destroy() end
  end
  elfHotkeysWindow = g_ui.createWidget("ElfHotkeysWindow", rootWidget)
  elfHotkeysWindow:hide()

  elfHotkeysWindow.titleCloseButton.onClick = function()
    elfHotkeysClose()
    return true
  end
  elfHotkeysWindow.footer.closeButton.onClick = function()
    elfHotkeysClose()
    return true
  end
  elfHotkeysWindow.footer.saveButton.onClick = elfHotkeysSave
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
      skipToggleKey = hotkey
      scheduleEvent(function()
        skipToggleKey = nil
      end, 50)
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

function elfHotkeysSave(silent)
  saveConfig()
  if hotkeysConfig.enabled then
    stopAllEntries()
    for _, entry in ipairs(hotkeysConfig.entries) do
      if entry.enabled then startEntry(entry) end
    end
  end
  refreshWindow()
  if not silent then
    msg(hotkeyText("Hotkeys personalizadas salvas.", "Custom hotkeys saved."))
  end
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
