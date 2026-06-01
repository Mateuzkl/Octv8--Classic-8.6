expWindow = nil
analyzerButton = nil
lootedItems = {}
killedCreatures = {}
creatureOutfit = nil
expHUpdateEvent = 0
expHVar = {
	historyIndex = 0,
	lastExpAmount = 0,
	originalExpAmount = 0,
	sessionStart = 0
}
expHistory = {
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0
}

function init()
	connect(LocalPlayer, {
		onExperienceChange = onExperienceChange
	})
	connect(g_game, {
		onGameStart = online,
		onGameEnd = offline
	})

	mainWindow = g_ui.loadUI("mainWindow", modules.game_interface.getRightPanel())
	expWindow = g_ui.loadUI("expAnalyzer", modules.game_interface.getRightPanel())
	dropWindow = g_ui.loadUI("dropTracker", modules.game_interface.getRightPanel())
	trackWindow = g_ui.loadUI("killTracker", modules.game_interface.getRightPanel())

	mainWindow:hide()
	dropWindow:hide()
	trackWindow:hide()
	expWindow:hide()

	local rightPanel = modules.game_interface.getRightPanel()
	exphButton = rightPanel:recursiveGetChildById("exphButton")

	exphButton:setOn(mainWindow:isVisible())
	g_keyboard.bindKeyDown("Ctrl+H", toggle)

	function mainWindow.onClose()
		exphButton:setOn(false)
	end

	expWindow:setup()
	dropWindow:setup()
	trackWindow:setup()
	mainWindow:setup()

	lootedItemsLabel = dropWindow:recursiveGetChildById("lootedItemsLabel")

	lootedItemsLabel:setHeight(30)

	killedMonstersLabel = trackWindow:recursiveGetChildById("monsterLabel")

	killedMonstersLabel:setHeight(30)
	expWindow:setContentMinimumHeight(50)
	expWindow:setContentMaximumHeight(150)
	mainWindow:setContentMinimumHeight(110)
	mainWindow:setContentMaximumHeight(110)
	dropWindow:setContentMinimumHeight(50)
	dropWindow:setContentMaximumHeight(250)
	trackWindow:setContentMinimumHeight(50)
	trackWindow:setContentMaximumHeight(250)
	startFreshExpHWindow()
	ProtocolGame.registerOpcode(GameServerOpcodes.GameServerKillTracker, parseKillTrackerMessage)
end

function terminate()
	disconnect(LocalPlayer, {
		onExperienceChange = onExperienceChange
	})
	disconnect(g_game, {
		onGameStart = refresh,
		onGameEnd = offline
	})
	ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerKillTracker)
	g_keyboard.unbindKeyDown("Ctrl+H")
	mainWindow:destroy()
	expWindow:destroy()
	dropWindow:destroy()
	trackWindow:destroy()
	exphButton:destroy()
end

function online()
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	resetExpH()
end

function offline()
	startFreshExpHWindow()
	resetLootedItems()
	resetKilledMonsters()
end

function onExperienceChange(localPlayer, currentExperience, print_s)
end

function toggle()
	if mainWindow:isVisible() then
		mainWindow:close()
	else
		mainWindow:open()
	end

	exphButton:setOn(mainWindow:isVisible())
end

function showExpWindow()
	if not expWindow:isVisible() then
		expWindow:show()
	else
		expWindow:hide()
	end
end

function showDropWindow()
	if not dropWindow:isVisible() then
		dropWindow:show()
		updateDropTracker(lootedItems)
	else
		dropWindow:hide()
	end
end

function showKillWindow()
	if not trackWindow:isVisible() then
		trackWindow:show()
	else
		trackWindow:hide()
	end
end

function resetSessionAll()
	resetLootedItems()
	resetKilledMonsters()
	updateExpHWindow()
	startFreshExpHWindow()
end

function resetLootedItems()
	local numberOfChilds = lootedItemsLabel:getChildCount()

	for i = 1, numberOfChilds do
		lootedItemsLabel:destroyChildren(i)
	end

	lootedItemsLabel:setHeight(30)

	lootedItems = {}
end

function resetKilledMonsters()
	local numberOfChilds = killedMonstersLabel:getChildCount()

	for i = 1, numberOfChilds do
		killedMonstersLabel:destroyChildren(i)
	end

	killedMonstersLabel:setHeight(30)

	killedCreatures = {}
end

function resetExpHistory()
	for zero = 1, 60 do
		expHistory[zero] = 0
	end
end

function resetExpH()
	expHVar.originalExpAmount = 0
	expHVar.lastExpAmount = 0
	expHVar.historyIndex = 0
	expHVar.sessionStart = 0

	setSkillValue("session", "00:00")
	setSkillValue("expph", 0)
	setSkillColor("expph", "#6eff8d")
	setSkillValue("expgained", 0)
	setSkillColor("expgained", "#edebeb")
	setSkillValue("exptolevel", 0)
	setSkillColor("exptolevel", "#edebeb")
	setSkillValue("timetolevel", "00:00")
	setSkillColor("timetolevel", "#edebeb")
	resetExpHistory()
end

function startFreshExpHWindow()
	resetExpH()

	if expHUpdateEvent ~= 0 then
		removeEvent(expHUpdateEvent)
	end

	updateExpHWindow()
end

function updateExpHWindow()
	expHUpdateEvent = scheduleEvent(updateExpHWindow, 5000)
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	local currentExp = player:getExperience()

	if expHVar.lastExpAmount == 0 then
		expHVar.lastExpAmount = currentExp
	end

	if expHVar.originalExpAmount == 0 then
		expHVar.originalExpAmount = currentExp
	end

	local expDiff = math.floor(currentExp - expHVar.lastExpAmount)

	updateExpHistory(expDiff)

	expHVar.lastExpAmount = currentExp
	local _expGained = math.floor(currentExp - expHVar.originalExpAmount)
	local _expHistory = getExpGained()

	if _expHistory <= 0 and (expHVar.sessionStart > 0 or _expGained > 0) then
		resetExpH()

		return false
	end

	local _session = 0
	local _start = expHVar.sessionStart

	if _start > 0 and _expGained > 0 then
		_session = math.floor(g_clock.seconds() - _start)
	end

	local string_session = getTimeFormat(_session)
	local string_expGain = number_format(_expGained)
	local _getExpHour = getExpPerHour(_expHistory, _session)
	local string_expph = number_format(_getExpHour)
	local _lvl = player:getLevel()
	local _nextLevelExp = getExperienceForLevel(_lvl + 1)
	local _expToNextLevel = math.floor(_nextLevelExp - currentExp)
	local string_exptolevel = number_format(_expToNextLevel)
	local _timeToNextLevel = getNextLevelTime(_expToNextLevel, _getExpHour)
	local string_timetolevel = getTimeFormat(_timeToNextLevel)

	setSkillValue("session", string_session)
	setSkillValue("expph", string_expph)
	setSkillValue("expgained", string_expGain)
	setSkillValue("exptolevel", string_exptolevel)
	setSkillValue("timetolevel", string_timetolevel)
end

function getNextLevelTime(_expToNextLevel, _getExpHour)
	if _getExpHour <= 0 then
		return 0
	end

	local _expperSec = _getExpHour / 3600
	local _secToNextLevel = math.ceil(_expToNextLevel / _expperSec)

	return _secToNextLevel
end

function getExperienceForLevel(lv)
	lv = lv - 1

	return (50 * lv * lv * lv - 150 * lv * lv + 400 * lv) / 3
end

function getNumber(msg)
	b, e = string.find(msg, "%d+")

	if b == nil or e == nil then
		count = 0
	else
		count = tonumber(string.sub(msg, b, e))
	end

	return count
end

function number_format(amount)
	local formatted = string.format("%.0f", tonumber(amount) or 0)

	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")

		if k == 0 then
			break
		end
	end

	return formatted
end

function getExpPerHour(_expHistory, _session)
	if _session < 10 then
		_session = 10
	elseif _session > 300 then
		_session = 300
	end

	local _expSec = _expHistory / _session
	local _expH = math.floor(_expSec * 3600)

	if _expH <= 0 then
		_expH = 0
	end

	return getNumber(_expH)
end

function getTimeFormat(_secs)
	local _hour = math.floor(_secs / 3600)
	_secs = math.floor(_secs - _hour * 3600)
	local _min = math.floor(_secs / 60)

	if _hour <= 0 then
		_hour = "00"
	elseif _hour <= 9 then
		_hour = "0" .. _hour
	end

	if _min <= 0 then
		_min = "00"
	elseif _min <= 9 then
		_min = "0" .. _min
	end

	return _hour .. ":" .. _min
end

function updateExpHistory(dif)
	if dif > 0 and expHVar.sessionStart == 0 then
		expHVar.sessionStart = g_clock.seconds()
	end

	local _index = expHVar.historyIndex
	expHistory[_index] = dif
	_index = _index + 1

	if _index < 0 or _index > 59 then
		_index = 0
	end

	expHVar.historyIndex = _index
end

function getExpGained()
	local totalExp = 0

	for key, value in pairs(expHistory) do
		totalExp = totalExp + value
	end

	return totalExp
end

function expForLevel(level)
	return math.floor(50 * level * level * level / 3 - 100 * level * level + 850 * level / 3 - 200)
end

function expToAdvance(currentLevel, currentExp)
	return expForLevel(currentLevel + 1) - currentExp
end

function comma_value(n)
	local left, num, right = string.match(n, "^([^%d]*%d)(%d*)(.-)$")

	return left .. num:reverse():gsub("(%d%d%d)", "%1,"):reverse() .. right
end

function setSkillValue(id, value)
	local skill = expWindow:recursiveGetChildById(id)
	local widget = skill:getChildById("value")

	widget:setText(value)
end

function setSkillColor(id, value)
	local skill = expWindow:recursiveGetChildById(id)
	local widget = skill:getChildById("value")

	widget:setColor(value)
end

function parseContainerItems(msg, items)
	local itemsCount = msg:getU8()

	for i = 1, itemsCount do
		local itemId = msg:getU16()
		local item = Item.create(itemId)

		if item:isContainer() then
			parseContainerItems(msg, items)
		else
			local count = msg:getU8()
			local moneyWorth = msg:getU16()
			-- local rarityTier = msg:getU8()
			local itemName = msg:getString()

			table.insert(items, {
				itemId = itemId,
				count = count,
				itemName = itemName,
				worth = moneyWorth
			})
		end
	end
end

function parseKillTrackerMessage(protocol, msg)
	local monsterName = msg:getString()
	local looktype = msg:getU16()
	local lookHead = msg:getU8()
	local lookBody = msg:getU8()
	local lookLegs = msg:getU8()
	local lookFeet = msg:getU8()
	local lookAddons = msg:getU8()
	local itemsCount = msg:getU8()
	local items = {}

	for i = 1, itemsCount do
		local itemId = msg:getU16()
		local item = Item.create(itemId)

		if item:isContainer() then
			parseContainerItems(msg, items)
		else
			local count = msg:getU8()
			local moneyWorth = msg:getU16()
			-- local rarityTier = msg:getU8()
			local itemName = msg:getString()

			table.insert(items, {
				itemId = itemId,
				count = count,
				itemName = itemName,
				worth = moneyWorth
			})
		end
	end

	onUpdateKillTracker(monsterName, looktype, lookHead, lookBody, lookLegs, lookFeet, lookAddons, items)
end

function onUpdateKillTracker(monsterName, lookType, lookHead, lookBody, lookLegs, lookFeet, addons, items)
	if not killedCreatures[monsterName] then
		killedCreatures[monsterName] = {
			amount = 0,
			lookType = lookType,
			lookHead = lookHead,
			lookBody = lookBody,
			lookLegs = lookLegs,
			lookFeet = lookFeet,
			addons = addons
		}
	end

	killedCreatures[monsterName].amount = killedCreatures[monsterName].amount + 1

	for _, data in pairs(items) do
		local itemName = data.itemName
		local itemId = data.itemId
		local count = data.count or 0
		local worth = data.worth or 0

		if not lootedItems[itemId] then
			lootedItems[itemId] = {
				amount = 0,
				name = itemName,
				worth = 0
			}
		end

		lootedItems[itemId].amount = lootedItems[itemId].amount + count
		lootedItems[itemId].worth = lootedItems[itemId].worth + worth

	end

	updateDropTracker(lootedItems)
	updateKillTracker()
end

function updateKillTracker()
	local numberOfLines = 0

	for k, v in pairs(killedCreatures) do
		local creatureSprite = killedMonstersLabel:getChildById("monster" .. k)

		if not creatureSprite then
			creatureSprite = g_ui.createWidget("Creature", killedMonstersLabel)

			creatureSprite:setId("monster" .. k)
			creatureSprite:setTooltip(k)
		end

		local creatureName = killedMonstersLabel:getChildById("name" .. k)

		if not creatureName then
			creatureName = g_ui.createWidget("MonsterNameLabel", killedMonstersLabel)

			creatureName:setId("name" .. k)
			creatureName:addAnchor(AnchorLeft, "monster" .. k, AnchorRight)
			creatureName:addAnchor(AnchorTop, "monster" .. k, AnchorTop)
			creatureName:setMarginLeft(5)
		end

		local creatureCount = killedMonstersLabel:getChildById("count" .. k)

		if not creatureCount then
			creatureCount = g_ui.createWidget("CreatureCountLabel", killedMonstersLabel)

			creatureCount:setId("count" .. k)
			creatureCount:addAnchor(AnchorBottom, "monster" .. k, AnchorBottom)
			creatureCount:addAnchor(AnchorLeft, "monster" .. k, AnchorRight)
			creatureCount:setMarginLeft(5)
		end

		creatureCount:setText("Kills: " .. v.amount)
		creatureName:setText(k)
		creatureSprite:setMarginTop(numberOfLines * 34 + 17)

		local creature = Creature.create()
		local outfit = {
			type = v.lookType,
			head = v.lookHead,
			body = v.lookBody,
			legs = v.lookLegs,
			feet = v.lookFeet,
			addons = v.addons
		}

		creature:setOutfit(outfit)
		creatureSprite:setCreature(creature)

		numberOfLines = numberOfLines + 1
	end

	killedMonstersLabel:setHeight(numberOfLines * 34 + 60)
end

function updateDropTracker(data)
	if dropWindow:isVisible() then
		local items = 0

		for k, v in pairs(data) do
			local itemPanel = lootedItemsLabel:getChildById("image" .. k)

			if not itemPanel then
				itemPanel = g_ui.createWidget("LootItemPanel", lootedItemsLabel)

				itemPanel:setId("image" .. k)
			end

			itemSprite = itemPanel:getChildById("itemSprite")

			itemSprite:setItemId(k)
			itemPanel:setMarginTop(items * 34 + 17)
			itemPanel:setMarginLeft(5)

			local countText = {}
			local count = v.amount

			if count >= 1000 then
				count = count / 1000 .. "k"
			end

			table.insert(countText, "Count: " .. count)
			table.insert(countText, "#afafaf")

			-- No rarity logic


			local itemLabel = itemPanel:getChildById("itemLabel")

			itemLabel:setText(v.name)

			local lootLabel = itemPanel:getChildById("lootLabel")

			lootLabel:setColoredText(countText)

			items = items + 1
		end

		lootedItemsLabel:setHeight(items * 33 + 60 + 20)
	end
end

function copyKillToClipboard()
	if not killedCreatures or killedCreatures == nil then
		return
	end

	local creatureNames = {}

	for name, kills in pairs(killedCreatures) do
		table.insert(creatureNames, string.lower(name) .. " (" .. kills.amount .. ")")
	end

	table.sort(creatureNames)

	local text = table.concat(creatureNames, ", ")

	if text and text ~= "" then
		g_window.setClipboardText("Kills Session: " .. text)
	end
end

function copyLootToClipboard()
	if not lootedItems or next(lootedItems) == nil then
		return
	end

	local maxChars = 250
	local prefix = "Loot Session: "
	local suffix = " [max text exceeded]"
	local availableChars = maxChars - #suffix
	local loot = {}
	local currentLength = #prefix
	local textExceeded = false

	for itemId, data in pairs(lootedItems) do
		local count = data.amount

		if count >= 1000 then
			count = math.floor(count / 1000) .. "k"
		end

		local entry = data.name .. " (" .. count .. ")"

		if availableChars >= currentLength + #entry + 2 then
			table.insert(loot, entry)

			currentLength = currentLength + #entry + 2
		else
			textExceeded = true

			break
		end
	end

	local text = table.concat(loot, ", ")

	if text ~= "" then
		if textExceeded then
			text = text .. suffix
		end

		g_window.setClipboardText(prefix .. text)
	end
end
