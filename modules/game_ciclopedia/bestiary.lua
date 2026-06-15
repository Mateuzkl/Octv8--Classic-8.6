CyclopediaOpcode = {
	Info = 0x39,
	Category = 0x3A,
	Monster = 0x3B,
	Charm = 0x3E,
	Tracker = 0x3F,
	Send = 0x39
}

protoData = protoData or {}

local BestiaryMessage = 0x00
local BestiaryData = 0x01 -- Main page
local BestiaryOverview = 0x02 -- Category data
local BestiaryMonsterData = 0x03 -- Monster info
local BestiaryTracker = 0x05
local BestiaryProgress = 0x06
local BESTIARY_SEARCH_PREFIX = "__search__:"
local bestiaryContainer
local charmAmountBestiary
local goldAmountBestiary
local selectedBestiaryRaceId = 0
local bestiaryProtocolRegistered = false
local bestiaryParsersRegistered = false
local bestiaryParsers = {}
local bestiaryTrackerWindow = nil
local bestiaryTrackerButton = nil
local bestiarySearchInput = nil
local bestiarySearchButton = nil
local currentBestiaryCategory = nil
local currentBestiaryRows = {}
local currentBestiaryEntries = {}
local bestiaryTrackerRefreshEvent = nil
local bestiaryMonsterRefreshEvent = nil
local scheduleBestiaryMonsterRefresh
local stopBestiaryMonsterRefresh
local bestiaryCategoryImages = {
	["Amphibic"] = 1,
	["Aquatic"] = 2,
	["Bird"] = 3,
	["Construct"] = 4,
	["Demon"] = 5,
	["Dragon"] = 6,
	["Elemental"] = 7,
	["Extra Dimensional"] = 8,
	["Fey"] = 9,
	["Giant"] = 10,
	["Human"] = 11,
	["Humanoid"] = 12,
	["Lycanthrope"] = 13,
	["Magical"] = 14,
	["Mammal"] = 15,
	["Plant"] = 16,
	["Reptile"] = 17,
	["Slime"] = 18,
	["Undead"] = 19,
	["Vermin"] = 20,
	["Inkborn"] = 4
}
starsLevels = {
	[1] = "Difficulty: Trivial",
	[2] = "Difficulty: Easy",
	[3] = "Difficulty: Medium",
	[4] = "Difficulty: Hard",
	[5] = "Difficulty: Challenging",
}

occurenceLevels = {
	[1] = "Occurrence: Common",
	[2] = "Occurrence: Uncommon",
	[3] = "Occurrence: Rare",
	[4] = "Occurrence: Very Rare",
}

lootRarityLevel = {
	[0] = "Common:",
	[1] = "Uncommon:",
	[2] = "Semi-Rare:",
	[3] = "Rare:",
	[4] = "Very Rare:"
}

local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

local function trimText(text)
	return tostring(text or ""):gsub("^%s*(.-)%s*$", "%1")
end

local function formatLocations(locations)
	local formattedLocations = {}
	for _, location in ipairs(locations) do
		location = trimText(location)
		if location ~= "" then
			formattedLocations[#formattedLocations + 1] = location
		end
	end
	if #formattedLocations == 0 then
		return "?"
	end
	return table.concat(formattedLocations, "\n")
end

local function isBestiaryView()
	return modules.game_ciclopedia and modules.game_ciclopedia.getCurrentType and modules.game_ciclopedia.getCurrentType() == "bestiary"
end

function readCyclopediaCreatureOutfit(msg)
	local name = msg:getString()
	return {
		name = name,
		type = msg:getU16(),
		head = msg:getU8(),
		body = msg:getU8(),
		legs = msg:getU8(),
		feet = msg:getU8(),
		addons = msg:getU8()
	}
end

local function readBestiaryOverviewEntry(msg)
	local raceId = msg:getU16()
	local progressMarker = msg:getU8()
	local entry = {
		raceId = raceId,
		progress = math.max((progressMarker or 0) - 1, 0)
	}

	if progressMarker > 0 then
		entry.progress = msg:getU8()
		entry.outfit = readCyclopediaCreatureOutfit(msg)
		protoData[raceId] = entry.outfit
	end
	return entry
end

local function applyBestiaryCategoryRow(row, entry)
	if not row or not entry then
		return
	end

	row.raceId = entry.raceId
	row.progress = entry.progress or 0
	local bestContainer = row.bestiaryContainer
	if not bestContainer then
		return
	end

	if row.progress > 0 then
		local raceOutfit = entry.outfit
		if raceOutfit then
			bestContainer.creature:setOutfit(raceOutfit)
		end
		bestContainer.hideCreature:hide()
		row:setText(firstToUpper(raceOutfit and raceOutfit.name or "unknown"))

		if row.progress >= 4 then
			row.creatureProgressCheck:show()
			row.creatureProgress:setText("")
		else
			row.creatureProgressCheck:hide()
			row.creatureProgress:setText(math.min(row.progress, 3) .. " / 3")
		end

		bestContainer.creature.onClick = function()
			requestBestiaryMonsterData(entry.raceId)
		end
	else
		bestContainer.hideCreature:show()
		row:setText("Unknown")
		row.creatureProgressCheck:hide()
		row.creatureProgress:setText("?")
		bestContainer.creature.onClick = nil
	end
end

local function applyBestiaryProgressUpdate(entry)
	if not entry then
		return
	end

	if entry.outfit then
		protoData[entry.raceId] = entry.outfit
	end
	currentBestiaryEntries[entry.raceId] = entry

	local row = currentBestiaryRows[entry.raceId]
	if row then
		applyBestiaryCategoryRow(row, entry)
	end

	if selectedBestiaryRaceId == entry.raceId and bestiaryMonster and bestiaryMonster:isVisible() then
		requestBestiaryMonsterData(entry.raceId)
	end
end

local function registerOpcode(code, func)
	bestiaryParsers[code] = func
end

local function dispatchBestiaryProtocol(protocol, msg)
	local response = msg:getU8()
	local parser = bestiaryParsers[response]
	if parser then
		parser(protocol, msg)
	end
	return true
end

function unregisterBestiaryProtocol()
	if not bestiaryProtocolRegistered then
		return
	end
	ProtocolGame.unregisterOpcode(CyclopediaOpcode.Send)
	bestiaryProtocolRegistered = false
end

function terminateBestiary()
	unregisterBestiaryProtocol()
	if bestiaryTrackerRefreshEvent then
		removeEvent(bestiaryTrackerRefreshEvent)
		bestiaryTrackerRefreshEvent = nil
	end
	if bestiaryMonsterRefreshEvent then
		removeEvent(bestiaryMonsterRefreshEvent)
		bestiaryMonsterRefreshEvent = nil
	end
	if bestiaryTrackerWindow then
		bestiaryTrackerWindow:destroy()
		bestiaryTrackerWindow = nil
	end
end

function registerBestiaryProtocol()
	if bestiaryParsersRegistered then
		if not bestiaryProtocolRegistered then
			ProtocolGame.unregisterOpcode(CyclopediaOpcode.Send)
			ProtocolGame.registerOpcode(CyclopediaOpcode.Send, dispatchBestiaryProtocol)
			bestiaryProtocolRegistered = true
		end
		return
	end
	bestiaryParsersRegistered = true

	registerOpcode(BestiaryData, function(protocol, msg)
		local bestiaryView = isBestiaryView()
		if bestiaryView and bestiaryCSelecter then
			emptyBestiaryCategories()
			currentBestiaryCategory = nil
			currentBestiaryRows = {}
			currentBestiaryEntries = {}
		end
		
		local categoryCount = msg:getU16()
		for i = 1, categoryCount do
			local categoryName, categoryAmount, discoveredAmount = msg:getString(), msg:getU16(), msg:getU16()
			if bestiaryView and bestiaryCSelecter then
				local row = g_ui.createWidget('BestiaryCategoryList', bestiaryCSelecter)
			
				row.index = i
				row:setId("bestiaryWidget"..i)
				row.categoryId = i
				row:setText(categoryName)
			
				local bestContainer = row.bestiaryContainer
				bestContainer.bestiaryImage:setImageSource('/images/game/bestiary/'..(bestiaryCategoryImages[categoryName] or i))
				local totalAmount = row.totalAmount
				totalAmount:setText("Total: "..categoryAmount)
				local knownAmount = row.knownAmount
				knownAmount:setText("Known: "..discoveredAmount)
			
				local bestiaryContainer = row.bestiaryContainer
				local bestiaryMonster = bestiaryContainer.bestiaryImage
				bestiaryMonster.onClick = function(self)
					requestBestiaryCategoryData(categoryName)
				end
			end
		end
		
		msg:skipBytes(1) -- Missing byte
		sendBestiaryCharmsData(msg)
	end)
	
	registerOpcode(BestiaryOverview, function(protocol, msg)
		local raceName, raceSize = msg:getString(), msg:getU16()
		local entries = {}
		for i = 1, raceSize do
			entries[i] = readBestiaryOverviewEntry(msg)
		end

		if not isBestiaryView() or not bestiaryCSelecter then
			return
		end

		emptyBestiaryCategories()
		currentBestiaryCategory = raceName
		currentBestiaryRows = {}
		currentBestiaryEntries = {}

		for i = 1, #entries do
			local entry = entries[i]
			local row = g_ui.createWidget('BestiaryCategory', bestiaryCSelecter)
			row.index = i
			row:setId("BestiaryCategory"..i)
			currentBestiaryRows[entry.raceId] = row
			currentBestiaryEntries[entry.raceId] = entry
			applyBestiaryCategoryRow(row, entry)
		end
	end)
	
	registerOpcode(BestiaryMonsterData, function(protocol, msg)
		if not isBestiaryView() or not bestiaryContainer or not bestiaryMonster then
			return
		end
		bestiaryContainer:hide()
		bestiaryMonster:show()
		
		-- Start of the info
		local raceId, class = msg:getU16(), msg:getString()
		local raceOutfit = readCyclopediaCreatureOutfit(msg)
		protoData[raceId] = raceOutfit
		selectedBestiaryRaceId = raceId
		bestiaryMonster:setText(firstToUpper(raceOutfit and raceOutfit.name or "unknown"))
		if raceOutfit then
			bestiaryMonster.bestiaryCreature:setOutfit(raceOutfit)
		end
		
		local currentLevel = msg:getU8()
		local killCounter = msg:getU32()
		local bestiaryFirstUnlock = msg:getU16()
		local bestiarySecondUnlock = msg:getU16()
		local bestiaryToUnlock = msg:getU16()
		
		local firstUnlock = math.max(bestiaryFirstUnlock, 1)
		local secondUnlock = math.max(bestiarySecondUnlock, firstUnlock)
		local toUnlock = math.max(bestiaryToUnlock, secondUnlock)
		local cappedKills = math.min(killCounter, toUnlock)
		local progressPercent
		if cappedKills < firstUnlock then
			progressPercent = (cappedKills * 33.33) / firstUnlock
		elseif cappedKills < secondUnlock then
			progressPercent = 33.33 + (((cappedKills - firstUnlock) * 33.33) / math.max(secondUnlock - firstUnlock, 1))
		else
			progressPercent = 66.66 + (((cappedKills - secondUnlock) * 33.34) / math.max(toUnlock - secondUnlock, 1))
		end
		
		bestiaryMonster.totalKillsLabel:setText(killCounter)
		bestiaryMonster.progressBar:setPercent(math.min(100, progressPercent))
		
		-- Bestiary Stars
		local bestiaryStars = msg:getU8()
		for s = 1, 5 do
			starsContainer:getChildById("stars"..s):setTooltip(starsLevels[bestiaryStars])
			
			if (s > bestiaryStars) then
				starsContainer:getChildById("stars"..s):setOn(false)
			else
				starsContainer:getChildById("stars"..s):setOn(true)
			end
		end
	
		-- Bestiary Occurence
		local bestiaryOccurrence = msg:getU8()
		for o = 1, 4 do
			occurrenceContainer:getChildById("occurrence"..o):setTooltip(occurenceLevels[bestiaryOccurrence])
			
			if (o > bestiaryOccurrence) then
				occurrenceContainer:getChildById("occurrence"..o):setOn(false)
			else
				occurrenceContainer:getChildById("occurrence"..o):setOn(true)
			end
		end
	
		local lootList = msg:getU8()
		local tierLoot = {}	
		for i = 1, lootList do
			local itemId = msg:getU16()
			local difficult = msg:getU8()
			local specialEvent = msg:getU8()
			local lootName = ""
			local countMax = 0
			
			if (currentLevel > 1) then
				lootName = msg:getString()
				countMax = msg:getU8()
			end

			table.insert(tierLoot, {
				itemId, difficult, lootName, countMax
			})
		end
		
		-- Loot Setup
		if lootContainer then
			lootContainer:destroyChildren()
		end
		for a = 0, 4 do
			local rarityLoot = g_ui.createWidget('BestiaryLoot', lootContainer)
			rarityLoot.rarityLevel:setText(lootRarityLevel[a])
			
			-- All loot slots
			local lootSlots = {rarityLoot.c_loot01, rarityLoot.c_loot02, rarityLoot.c_loot03, rarityLoot.c_loot04, rarityLoot.c_loot05, rarityLoot.c_loot06, rarityLoot.c_loot07, rarityLoot.c_loot08, rarityLoot.c_loot09, rarityLoot.c_loot10, rarityLoot.c_loot11, rarityLoot.c_loot12, rarityLoot.c_loot13, rarityLoot.c_loot14, rarityLoot.c_loot15}
			
			local difficultyList = {}
			if a == 0 then
				for i = 1, #tierLoot do
					if (tierLoot[i][2] == a) then
						table.insert(difficultyList, {
							itemId = tierLoot[i][1],
							name = tierLoot[i][3]
						})
					end
				end
			elseif a == 1 then
				for i = 1, #tierLoot do
					if (tierLoot[i][2] == a) then
						table.insert(difficultyList, {
							itemId = tierLoot[i][1],
							name = tierLoot[i][3]
						})
					end
				end
			elseif a == 2 then
				for i = 1, #tierLoot do
					if (tierLoot[i][2] == a) then
						table.insert(difficultyList, {
							itemId = tierLoot[i][1],
							name = tierLoot[i][3]
						})
					end
				end
			elseif a == 3 then
				for i = 1, #tierLoot do
					if (tierLoot[i][2] == a) then
						table.insert(difficultyList, {
							itemId = tierLoot[i][1],
							name = tierLoot[i][3]
						})
					end
				end
			elseif a == 4 then
				for i = 1, #tierLoot do
					if (tierLoot[i][2] == a) then
						table.insert(difficultyList, {
							itemId = tierLoot[i][1],
							name = tierLoot[i][3]
						})
					end
				end
			end
			
			-- Loot calculation
			for i = 1, #lootSlots do
				if difficultyList[i] then
					if (currentLevel > 1) then
						lootSlots[i]:setItemId(difficultyList[i].itemId)
						lootSlots[i]:setTooltip(firstToUpper(difficultyList[i].name))
					else
						lootSlots[i]:setImageSource("/images/game/bestiary/undiscoveredSlot")
					end
				else
					lootSlots[i]:disable()
				end
			end
			
			rarityLoot:setMarginTop(5 + ((a-1) * 40))
		end
		
		if currentLevel > 1 then
			local charmPoints = msg:getU16()
			local attackMode = msg:getU8()
			local unknownPacket = msg:getU8()
			local healthMax = msg:getU32()
			local experience = msg:getU32()
			local baseSpeed = msg:getU16()
			local armor = msg:getU16()
	
			bestiaryMonster.charmAmount:setText(charmPoints)
			bestiaryMonster.healthAmount:setText(healthMax)
			bestiaryMonster.experienceAmount:setText(experience)
			bestiaryMonster.speedAmount:setText(baseSpeed)
			bestiaryMonster.armorAmount:setText(armor)
		else
			bestiaryMonster.charmAmount:setText("?")
			bestiaryMonster.healthAmount:setText("?")
			bestiaryMonster.experienceAmount:setText("?")
			bestiaryMonster.speedAmount:setText("?")
			bestiaryMonster.armorAmount:setText("?")
			bestiaryMonster.locationTextfield:setText("?")
		end
		
		-- Elements setup
		local elements = {bestiaryMonster.physicalAmount, bestiaryMonster.earthAmount, bestiaryMonster.fireAmount, bestiaryMonster.deathAmount, bestiaryMonster.energyAmount, bestiaryMonster.holyAmount, bestiaryMonster.iceAmount, bestiaryMonster.healingAmount}
		
		if currentLevel > 2 then
			-- Element Table Initialize
			local elementWidgetTable = {
				[0] = bestiaryMonster.physicalAmount,
				[1] = bestiaryMonster.fireAmount,
				[2] = bestiaryMonster.earthAmount,
				[3] = bestiaryMonster.energyAmount,
				[4] = bestiaryMonster.iceAmount,
				[5] = bestiaryMonster.holyAmount,
				[6] = bestiaryMonster.deathAmount,
				[7] = bestiaryMonster.healingAmount
			}
			
			-- Basic setup for all elements
			for a = 1, #elements do 
				elements[a]:setPercent(68) -- Means 100%
			end
			
			-- Actual element Setup
			local elementsList = msg:getU8()
			for b = 1, elementsList do
				local elementId, elementPercent = msg:getU8(), msg:getU16()
				-- We change each element depending on which element has been altered
				if elementWidgetTable[elementId] then
					local elementFormula = (elementPercent / 100)
					if (elementPercent == 0) then
						progressPercent = 0
					elseif (elementPercent == 100) then
						progressPercent = 68
					else
						progressPercent = elementFormula * 68
					end
					
					elementWidgetTable[elementId]:setPercent(progressPercent)
					if (elementPercent > 100) then
						elementWidgetTable[elementId]:setBackgroundColor("#18ce18")
					elseif (elementPercent < 100) then
						elementWidgetTable[elementId]:setBackgroundColor("#ae0f0f")
					elseif (elementPercent == 100) then
						elementWidgetTable[elementId]:setBackgroundColor("#ffffff")
					end
				end
			end
		
			-- Location
			local locations = msg:getU16()
			local locationsList = {}
			for i = 1, locations do
				locationsList[#locationsList + 1] = msg:getString()
			end
			
			bestiaryMonster.locationTextfield:setText(formatLocations(locationsList))
		else
			bestiaryMonster.locationTextfield:setText("?")
			for c = 1, #elements do
				elements[c]:setPercent(0)
			end
		end
		
		-- Charms (Not done)
		if currentLevel > 3 then
			local hascharm = msg:getU8()
			if hascharm > 0 then
				msg:getU8()
				msg:getU32()
			else
				msg:getU8()
			end
		end
		if scheduleBestiaryMonsterRefresh then
			scheduleBestiaryMonsterRefresh()
		end
	  end)

	registerOpcode(BestiaryMessage, function(protocol, msg)
		local message = msg:getString()
		if displayInfoBox then
			displayInfoBox("Cyclopedia", message)
		else
			print(message)
		end
	end)

	registerOpcode(BestiaryTracker, function(protocol, msg)
		updateBestiaryTracker(msg)
	end)

	registerOpcode(BestiaryProgress, function(protocol, msg)
		local raceId = msg:getU16()
		local progress = msg:getU8()
		local killCount = msg:getU32()
		local firstUnlock = msg:getU16()
		local secondUnlock = msg:getU16()
		local toKill = msg:getU16()
		local raceOutfit = readCyclopediaCreatureOutfit(msg)
		local charmAmount = msg:getU32()
		local goldAmount = msg:getU32()

		applyBestiaryProgressUpdate({
			raceId = raceId,
			progress = progress,
			kills = killCount,
			firstUnlock = firstUnlock,
			secondUnlock = secondUnlock,
			toKill = toKill,
			outfit = raceOutfit
		})
		BestiaryChangeAmount(charmAmount, goldAmount)
	end)

	ProtocolGame.unregisterOpcode(CyclopediaOpcode.Send)
	ProtocolGame.registerOpcode(CyclopediaOpcode.Send, dispatchBestiaryProtocol)
	bestiaryProtocolRegistered = true
end

function getItemTier(chance)
	local tier = 1
	if (chance < 1000) then
		tier = 4
	elseif (chance >= 1000 and chance < 10000) then
		tier = 3
	elseif (chance >= 10000 and chance < 50000) then
		tier = 2
	elseif (chance >= 50000) then
		tier = 1
	end
return tier
end
function BestiaryChangeAmount(amount,secondAmount)
if not isBestiaryView() then
return
end
if charmAmountBestiary then
charmAmountBestiary:setText(amount)
end
if goldAmountBestiary then
goldAmountBestiary:setText(secondAmount)
end
end

local function ensureBestiaryTrackerWindow()
	if bestiaryTrackerWindow then
		return bestiaryTrackerWindow
	end

	local rightPanel = modules.game_interface and modules.game_interface.getRightPanel and modules.game_interface.getRightPanel()
	if not rightPanel then
		return nil
	end

	bestiaryTrackerWindow = g_ui.createWidget('BestiaryTrackerMini', rightPanel)
	if not bestiaryTrackerWindow then
		return nil
	end

	bestiaryTrackerWindow:setup()
	bestiaryTrackerWindow:hide()
	return bestiaryTrackerWindow
end

function requestBestiaryTrackerToggle(raceId)
	local protocolGame = g_game.getProtocolGame()
	if protocolGame and raceId and raceId > 0 then
		local msg = OutputMessage.create()
		msg:addU8(CyclopediaOpcode.Tracker)
		msg:addU16(raceId)
		protocolGame:send(msg)
	end
end

function requestBestiaryTrackerRefresh()
	local protocolGame = g_game.getProtocolGame()
	if protocolGame then
		local msg = OutputMessage.create()
		msg:addU8(CyclopediaOpcode.Tracker)
		msg:addU16(0)
		protocolGame:send(msg)
	end
end

local function scheduleBestiaryTrackerRefresh()
	if bestiaryTrackerRefreshEvent then
		return
	end

	bestiaryTrackerRefreshEvent = scheduleEvent(function()
		bestiaryTrackerRefreshEvent = nil
		if bestiaryTrackerWindow and bestiaryTrackerWindow:isVisible() and g_game.isOnline() then
			requestBestiaryTrackerRefresh()
			scheduleBestiaryTrackerRefresh()
		end
	end, 1000)
end

stopBestiaryMonsterRefresh = function()
	if bestiaryMonsterRefreshEvent then
		removeEvent(bestiaryMonsterRefreshEvent)
		bestiaryMonsterRefreshEvent = nil
	end
end

scheduleBestiaryMonsterRefresh = function()
	if bestiaryMonsterRefreshEvent then
		return
	end

	bestiaryMonsterRefreshEvent = scheduleEvent(function()
		bestiaryMonsterRefreshEvent = nil
		if g_game.isOnline() and selectedBestiaryRaceId > 0 and isBestiaryView() and bestiaryMonster and bestiaryMonster:isVisible() then
			requestBestiaryMonsterData(selectedBestiaryRaceId)
			scheduleBestiaryMonsterRefresh()
		end
	end, 1500)
end

function updateBestiaryTracker(msg)
	local entries = {}
	local count = msg:getU8()
	for i = 1, count do
		local raceId = msg:getU16()
		local raceOutfit = readCyclopediaCreatureOutfit(msg)
		protoData[raceId] = raceOutfit
		entries[#entries + 1] = {
			raceId = raceId,
			outfit = raceOutfit,
			kills = msg:getU32(),
			firstUnlock = msg:getU16(),
			secondUnlock = msg:getU16(),
			toKill = msg:getU16(),
			progress = msg:getU8()
		}
	end

	local window = ensureBestiaryTrackerWindow()
	if not window then
		return
	end

	local contentsPanel = window:recursiveGetChildById('contentsPanel')
	if not contentsPanel then
		return
	end

	contentsPanel:destroyChildren()
	for _, entry in ipairs(entries) do
		local row = g_ui.createWidget('BestiaryTrackerEntry', contentsPanel)
		if not row then
			return
		end

		if entry.outfit then
			row.creature:setOutfit(entry.outfit)
			row.creatureName:setText(firstToUpper(entry.outfit.name))
		else
			row.creatureName:setText("Unknown")
		end
		row.killCount:setText(entry.kills .. " / " .. entry.toKill)
		row.progressBar:setPercent(math.min(100, math.floor((entry.kills * 100) / math.max(entry.toKill, 1))))
		row.progressLevel:setText(entry.progress .. " / 4")
	end

	if count > 0 then
		window:show()
		scheduleBestiaryTrackerRefresh()
	else
		window:hide()
		if bestiaryTrackerRefreshEvent then
			removeEvent(bestiaryTrackerRefreshEvent)
			bestiaryTrackerRefreshEvent = nil
		end
	end
end

function initBestiary(contentContainer)
	bestiaryPanel = g_ui.loadUI("styles/bestiary", contentContainer)
	bestiaryPanel:show()
	
	-- Child styles
	bestiaryContainer = bestiaryPanel:recursiveGetChildById('bestiaryContainer')
		bestiaryCSelecter = bestiaryContainer:recursiveGetChildById('bestiaryCSelecter')
		
		charmAmountBestiary = bestiaryPanel:recursiveGetChildById('charmPoints')
		goldAmountBestiary = bestiaryPanel:recursiveGetChildById('goldPoints')
		bestiaryTrackerButton = bestiaryPanel:recursiveGetChildById('bestiaryTracker')
		bestiarySearchButton = bestiaryPanel:recursiveGetChildById('searchButton')
		bestiarySearchInput = bestiaryPanel:recursiveGetChildById('searchInput')
		
	bestiaryMonster = g_ui.createWidget('BestiaryMonster', bestiaryPanel)
		starsContainer = bestiaryMonster:recursiveGetChildById('starsContainer')
		bestiaryLoot = bestiaryMonster:recursiveGetChildById('BestiaryLoot')
		occurrenceContainer = bestiaryMonster:recursiveGetChildById('occurrenceContainer')
		verticalLocationSB = bestiaryMonster:recursiveGetChildById('verticalLocationSB')
		lootContainer = bestiaryMonster:recursiveGetChildById('lootContainer')
		bestiaryMonster.locationField = bestiaryMonster:recursiveGetChildById('locationField')
		bestiaryMonster.locationTextfield = bestiaryMonster:recursiveGetChildById('locationTextfield')

	if bestiaryTrackerButton then
		bestiaryTrackerButton.onClick = function()
			requestBestiaryTrackerToggle(selectedBestiaryRaceId)
		end
	end

	if bestiarySearchButton then
		bestiarySearchButton.onClick = requestBestiarySearch
	end
		
	--- Extras
	connect(g_game, {
		onEnterGame = registerBestiaryProtocol, 
		onPendingGame = registerBestiaryProtocol,
		onGameStart = registerBestiaryProtocol
	})
	
	registerBestiaryProtocol()

	-- Protocolling request
	requestBestiaryData() -- We request the bestiary data
end
local function requestBestiaryInfo()
	local protocolGame = g_game.getProtocolGame()
	if protocolGame then
    local msg = OutputMessage.create()
    msg:addU8(CyclopediaOpcode.Info)
    protocolGame:send(msg)
	end  

end
function requestBestiaryData()
	if stopBestiaryMonsterRefresh then
		stopBestiaryMonsterRefresh()
	end
	bestiaryMonster:hide()
	bestiaryContainer:show()
	currentBestiaryCategory = nil
	currentBestiaryRows = {}
	currentBestiaryEntries = {}
	
	requestBestiaryInfo()
end

local bestiaryTable = {
	["Bosses"] = 1,
	["Aquatic"] = 2,
	["Bird"] = 3,
	["Construct"] = 4,
	["Demon"] = 5,
	["Dragon"] = 6,
	["Elemental"] = 7,
	["Extra Dimensional"] = 8,
	["Fey"] = 9,
	["Giant"] = 10,
	["Human"] = 11,
	["Humanoid"] = 12,
	["Lycanthrope"] = 13,
	["Magical"] = 14,
	["Mammal"] = 15,
	["Plant"] = 16,
	["Reptile"] = 17,
	["Slime"] = 18,
	["Undead"] = 19,
	["Vermin"] = 20
}

function requestBestiaryCategoryData(catName)

	local protocolGame = g_game.getProtocolGame()
	if protocolGame then
    local msg = OutputMessage.create()
    msg:addU8(CyclopediaOpcode.Category)
    msg:addU8(0x02)
    msg:addString(catName)
    protocolGame:send(msg)
	end  


end

function requestBestiarySearch()
	local query = trimText(bestiarySearchInput and bestiarySearchInput:getText() or "")
	if query == "" then
		requestBestiaryData()
		return
	end

	local protocolGame = g_game.getProtocolGame()
	if protocolGame then
		local msg = OutputMessage.create()
		msg:addU8(CyclopediaOpcode.Category)
		msg:addU8(0x02)
		msg:addString(BESTIARY_SEARCH_PREFIX .. query)
		protocolGame:send(msg)
	end
end

function requestBestiaryMonsterData(raceId)

	local protocolGame = g_game.getProtocolGame()
	if protocolGame then
    local msg = OutputMessage.create()
    msg:addU8(CyclopediaOpcode.Monster)
    msg:addU16(raceId)
    protocolGame:send(msg)
	end  
end

function emptyBestiaryCategories()
	if not bestiaryCSelecter then
		return
	end
	while bestiaryCSelecter:getChildCount() > 0 do
		local child = bestiaryCSelecter:getLastChild()
		bestiaryCSelecter:destroyChildren(child)
	end
end
