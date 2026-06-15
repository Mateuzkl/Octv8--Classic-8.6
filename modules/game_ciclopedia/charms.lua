protoData = protoData or {}

local function requestBestiaryInfo()
	local protocolGame = g_game.getProtocolGame()
	if protocolGame then
    local msg = OutputMessage.create()
    msg:addU8(CyclopediaOpcode.Info)
    protocolGame:send(msg)
	end  

end

local function parseSendBuyCharmRune(runeId, action, raceId)
	local protocolGame = g_game.getProtocolGame()
	if protocolGame then
    local msg = OutputMessage.create()
    msg:addU8(CyclopediaOpcode.Charm)
    msg:addU8(runeId)
    msg:addU8(action)
    msg:addU16(raceId or 0)
    protocolGame:send(msg)
	end  
end

local BestiaryData = 0x01
local bankGold = 0
local inventoryGold = 0
local selectedRaceId = 0
local goldPoints
withdrawWindow = nil
storedContentContainer = nil

local function readCharmCreatureOutfit(msg)
	if readCyclopediaCreatureOutfit then
		return readCyclopediaCreatureOutfit(msg)
	end

	return {
		name = msg:getString(),
		type = msg:getU16(),
		head = msg:getU8(),
		body = msg:getU8(),
		legs = msg:getU8(),
		feet = msg:getU8(),
		addons = msg:getU8()
	}
end

local function isCharmsView()
	return modules.game_ciclopedia and modules.game_ciclopedia.getCurrentType and modules.game_ciclopedia.getCurrentType() == "charms"
end

local function registerCharmsProtocol()
	if registerBestiaryProtocol then
		registerBestiaryProtocol()
	end
end

local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function sendBestiaryCharmsData(msg)
local charmsView = isCharmsView()
if charmsView and not charmsWindow then
	charmsWindow = g_ui.loadUI("styles/charms", getContentContainer())
	end
	local charmsAmount = msg:getU32()
	local goldAmount = msg:getU64()
	if charmsView and charmAmount then
		charmAmount:setText(charmsAmount)
	end
		 
	if charmsView and goldPoints then
		goldPoints:setText(goldAmount)
	end
		 BestiaryChangeAmount(charmsAmount,goldAmount)
		 
	local charmsList = {}
	local charms = msg:getU8()
	for i = 1, charms do
		local runeId = msg:getU8()
		local runeName = msg:getString()
		local runeDescription = msg:getString()
		local getGold = msg:getU8()
		local unlockPoints = msg:getU16()
		
		local activatedStatus, asignedStatus, raceId, removeRuneCost = msg:getU8(), false, 0, 0		
		if (activatedStatus > 0) then
			local asigned = msg:getU8()
			if (asigned > 0) then
				asignedStatus = true
				raceId = msg:getU16() -- Raceid
				removeRuneCost = msg:getU32() -- Remove runeCost
				protoData[raceId] = readCharmCreatureOutfit(msg)
			end
		else
			msg:getU8()
		end
		
		table.insert(charmsList, {
			id = runeId,
			name = runeName,
			description = runeDescription,
			unlockPrice = unlockPoints,
			activated = activatedStatus,
			asignedStatus = asignedStatus,
			raceId = raceId,
			removeRuneCost = removeRuneCost
		})
	end
	
	if charmsView and charmDescription and charmRune and charmInfoPrice and charmInfoPrice and unlockCharmButton then
		createCharms(charmsList, charmsAmount) -- We use the data that we filled
	end
	
	msg:getU8() -- Unknown byte
	
	local finishedMonstersSize = msg:getU16()
	local generatedMonsters = {}
	for i = 1, finishedMonstersSize do
		local raceId = msg:getU16()
		local sPData = readCharmCreatureOutfit(msg)
		protoData[raceId] = sPData
		if charmsView and monsterSelecter and sPData then
			local monsterRow = g_ui.createWidget('MonsterCharm', monsterSelecter)
			if (i % 2 == 0) then monsterRow:setBackgroundColor("#484848") end
			
			monsterRow:setText(firstToUpper(sPData.name))
			monsterRow:setId("monsterWidget"..i)
			table.insert(generatedMonsters, "monsterWidget"..i)

			monsterRow.onClick = function(self)
				for i = 1, #generatedMonsters do
					-- local aWidget = 
					if (i % 2 == 0) then 
						if monsterSelecter:getChildById("monsterWidget"..i) then
							monsterSelecter:getChildById("monsterWidget"..i):setBackgroundColor("#484848") 
						end
					else
						if monsterSelecter:getChildById("monsterWidget"..i) then
							monsterSelecter:getChildById("monsterWidget"..i):setBackgroundColor("#404040")
						end
					end
				end
				
				unlockCharmButton:enable()
				unlockCharmButton:setOpacity(1)
				
				charmMonster:show()
				charmMonster:setOutfit(protoData[raceId])
				monsterRow:setBackgroundColor("#585858")
				selectedRaceId = raceId
			end
		end
	end
end

function createBuyWindow()
	-- if buyWindow then return end
	buyWindow = g_ui.displayUI('styles/buy_charm_rune')
	buyWindow:hide()
end

function buyHide()
	buyWindow:hide()
end

function setupCharm(name, desc, id, price, unlocked, charmBalance, aStatus, rId, removeRuneCost)
	charmMonster:hide()
	monsterSelecter:show()
	charmDescription:setText(desc)
	charmRune:setImageSource('/images/game/charms/'..id)
	charmInfoPrice:setText(price)

	if not unlocked then
		unlockCharmButton:setText("Unlock")
		monsterSelecter:hide()
			
		if (price <= charmBalance) then
			charmInfoPrice:setColor("#ffffff")
			unlockCharmButton:enable()
			unlockCharmButton:setOpacity(1)
		else
			charmInfoPrice:setColor("#d33c3c")
			unlockCharmButton:disable()
			unlockCharmButton:setOpacity(0.5)
		end
	else
		if not aStatus then
			unlockCharmButton:setText("Select")
			unlockCharmButton:disable()
			unlockCharmButton:setOpacity(0.5)
			charmInfoPrice:setColor("#ffffff")
			
			monsterSelecter:setOpacity(1)
			monsterSelecter:enable()
		else
			unlockCharmButton:setText("Remove")
			unlockCharmButton:enable()
			unlockCharmButton:setOpacity(1)
			
			charmInfoPrice:setColor("#ffffff")
			charmMonster:show()
			if protoData[rId] then
				charmMonster:setOutfit(protoData[rId])
			end
			
			monsterSelecter:setOpacity(0.5)
			monsterSelecter:disable()
		end
	end
	
	-- Setup the buy charm window
	createBuyWindow()
	
	unlockCharmButton.onClick = function(self)
		if unlockCharmButton:getText() == "Unlock" then
			buyWindow:show()
			buyWindow:raise()
			buyWindow:focus()
			
			buyText = buyWindow:recursiveGetChildById('buyText')
			buttonYes = buyWindow:recursiveGetChildById('buttonYes')
			
			buyText:setText("Do you want to unlock the Charm "..name.."? This will cost you "..price.." Charm Points?")
			
			buttonYes.onClick = function(self)
				buyHide()
				charmsWindow:show()
				charmsWindow:raise()
				charmsWindow:focus()
				charmsWindow:lock()
				parseSendBuyCharmRune(id, 0, nil)
				
				resetCharmsData()
			end
		elseif unlockCharmButton:getText() == "Select" then
			buyWindow:show()
			buyWindow:raise()
			buyWindow:focus()
			
			buyText = buyWindow:recursiveGetChildById('buyText')
			buttonYes = buyWindow:recursiveGetChildById('buttonYes')
			buyText:setText("Do you want to use the Charm "..name.." for this creature?")
			
			buttonYes.onClick = function(self)
				buyHide()
				charmsWindow:show()
				charmsWindow:raise()
				charmsWindow:focus()
				charmsWindow:lock()
				parseSendBuyCharmRune(id, 1, selectedRaceId)
				
				resetCharmsData()
			end
		elseif unlockCharmButton:getText() == "Remove" then
			buyWindow:show()
			buyWindow:raise()
			buyWindow:focus()
			
			buyText = buyWindow:recursiveGetChildById('buyText')
			buttonYes = buyWindow:recursiveGetChildById('buttonYes')
			buyText:setText("Do you want to remove the Charm "..name.." from this creature? This will cost you "..tr(removeRuneCost).." gold pieces.")
			
			buttonYes.onClick = function(self)
				buyHide()
				charmsWindow:show()
				charmsWindow:raise()
				charmsWindow:focus()
				charmsWindow:lock()
				parseSendBuyCharmRune(id, 2, rId)
				
				resetCharmsData()
			end
		end
	end
	
	actualCharm = i
end

local function comparePrices(a, b)
	return a.unlockPrice < b.unlockPrice
end

function createCharms(charmsData, charmsBalance)
	-- Generate unlocked charms
	local unlockedCharms = {}
	for i = 1, #charmsData do
		if (charmsData[i].activated == 1) then
			table.insert(unlockedCharms, {
				id = charmsData[i].id,
				name = charmsData[i].name,
				description = charmsData[i].description,
				unlockPrice = charmsData[i].unlockPrice,
				asignedStatus = charmsData[i].asignedStatus,
				activated = charmsData[i].activated,
				raceId = charmsData[i].raceId,
				removeRuneCost = charmsData[i].removeRuneCost
			})
		end
	end
	
	-- Generate locked charms
	local lockedCharms = {}
	for i = 1, #charmsData do
		if (charmsData[i].activated == 0) then
			table.insert(lockedCharms, {
				id = charmsData[i].id,
				name = charmsData[i].name,
				description = charmsData[i].description,
				unlockPrice = charmsData[i].unlockPrice,
				asignedStatus = charmsData[i].asignedStatus,
				activated = charmsData[i].activated,
				raceId = charmsData[i].raceId,
				removeRuneCost = charmsData[i].removeRuneCost
			})
		end
	end

	table.sort(unlockedCharms, comparePrices)
	table.sort(lockedCharms, comparePrices)
	
	-- Generate charm data
	local generatedCharms = {}
	local unlockedCharmAmount = #unlockedCharms
	local firstCharm = false
	
	for i = 1, unlockedCharmAmount do
		local name = unlockedCharms[i].name
		local description = unlockedCharms[i].description
		local id = unlockedCharms[i].id
		local uPrice = unlockedCharms[i].unlockPrice
		local aStatus = unlockedCharms[i].asignedStatus
		local rId = unlockedCharms[i].raceId
		local removeRuneCost = unlockedCharms[i].removeRuneCost
		local row = g_ui.createWidget('Charm', charmSelecter)
		
		row:setId("charmWidget"..i)
		table.insert(generatedCharms, "charmWidget"..i)
		
		firstCharm = true
		row.charmRune:setImageSource('/images/game/charms/'..id)
		row.charmDisabler:hide()
		
		row:setText(name)
		
		local charmPriceContainer = row.charmPriceContainer
		charmPriceContainer.charmPrice:setColor("white")
		
		local charmMonster = row.charmMonsterContainer:recursiveGetChildById("charmMonster")
		if aStatus and protoData[rId] then
			charmMonster:setOutfit(protoData[rId])
		end
		
		if i == 1 then
			row.borderContainer:setBorderWidth(2)
			row.borderContainer:setBorderColor('white')
			setupCharm(name, description, id, uPrice, true, charmsBalance, aStatus, rId, removeRuneCost)
		end
		
		if (uPrice >= 1000) then
			charmPriceContainer:recursiveGetChildById('charmPrice'):setText(tr(uPrice))
		else
			charmPriceContainer:recursiveGetChildById('charmPrice'):setText(uPrice)
		end
		
		local affectedCharm = row.borderContainer
		affectedCharm.onClick = function(self)
			for i = 1, #generatedCharms do
				charmSelecter:getChildById("charmWidget"..i).borderContainer:setBorderColor('#000000')
				charmSelecter:getChildById("charmWidget"..i).borderContainer:setBorderWidth(0)
			end
			
			setupCharm(name, description, id, uPrice, true, charmsBalance, aStatus, rId, removeRuneCost)
			affectedCharm:setBorderWidth(2)
			affectedCharm:setBorderColor('white')
		end
	end
	
	for i = 1, #lockedCharms do
		local name = lockedCharms[i].name
		local description = lockedCharms[i].description
		local id = lockedCharms[i].id
		local uPrice = lockedCharms[i].unlockPrice
		local row = g_ui.createWidget('Charm', charmSelecter)
		
		row.unlocked = false
		row:setId("charmWidget"..i+unlockedCharmAmount)
		table.insert(generatedCharms, "charmWidget"..i+unlockedCharmAmount)
		
		row.charmRune:setImageSource('/images/game/charms/'..id)
		row:setText(name)
		
		local charmPriceContainer = row.charmPriceContainer
		if charmsBalance >= uPrice then
			charmPriceContainer.charmPrice:setColor("white")
		end
		
		if i == 1 and not firstCharm then
			row.borderContainer:setBorderWidth(2)
			row.borderContainer:setBorderColor('white')
			setupCharm(name, description, id, uPrice, false, charmsBalance, false, 0, 0)
		end
		
		if (uPrice >= 1000) then
			row.charmPriceContainer:recursiveGetChildById('charmPrice'):setText(tr(uPrice))
		else
			row.charmPriceContainer:recursiveGetChildById('charmPrice'):setText(uPrice)
		end
		
		local affectedCharm = row.borderContainer
		affectedCharm.onClick = function(self)
			for i = 1, #generatedCharms do
				charmSelecter:getChildById("charmWidget"..i).borderContainer:setBorderColor('#000000')
				charmSelecter:getChildById("charmWidget"..i).borderContainer:setBorderWidth(0)
			end
			
			setupCharm(name, description, id, uPrice, false, charmsBalance, false, 0, 0)
			affectedCharm:setBorderWidth(2)
			affectedCharm:setBorderColor('white')
		end
	end

end

function initCharms()
	charmsWindow = g_ui.loadUI("styles/charms", getContentContainer())
	charmsWindow:show()
	
	-- Selecter for charms
	blackBG02 = charmsWindow:recursiveGetChildById('blackBG02')
		charmAmount = blackBG02:recursiveGetChildById('charmAmount')
	
		goldPoints = charmsWindow:recursiveGetChildById('goldPoints')
		
	charmsContainer = charmsWindow:recursiveGetChildById('charmsContainer')
		charmSelecter = charmsContainer:recursiveGetChildById('charmSelecter')
	
	informationContainer = charmsWindow:recursiveGetChildById('informationContainer')
		monsterContainer = informationContainer:recursiveGetChildById('monsterContainer')
			charmMonster = monsterContainer:recursiveGetChildById('charmMonster')
		unlockCharmButton = informationContainer:recursiveGetChildById('unlockCharmButton')
		charmDescription = informationContainer:recursiveGetChildById('charmDescription')
		charmContainer = informationContainer:recursiveGetChildById('charmContainer')
		charmRune = informationContainer:recursiveGetChildById('charmRune')
		charmDisabler = informationContainer:recursiveGetChildById('charmDisabler')
		charmPriceContainer = informationContainer:recursiveGetChildById('charmPriceContainer')
			charmInfoPrice = charmPriceContainer:recursiveGetChildById('charmInfoPrice')
		monsterSelecter = informationContainer:recursiveGetChildById('monsterSelecter')
	
	connect(g_game, {
		onEnterGame = registerCharmsProtocol, 
		onPendingGame = registerCharmsProtocol,
		onGameStart = registerCharmsProtocol
	})
	
	registerCharmsProtocol()

	-- We make the request
	requestBestiaryInfo()
end

function resetCharmsData()
	clearCharmsContainer()
	clearCharmsMonsterList()
	
	scheduleEvent(function() 
	requestBestiaryInfo()
	end, 10)
end

function clearCharmsContainer()
	while charmSelecter:getChildCount() > 0 do
		local child = charmSelecter:getLastChild()
		charmSelecter:destroyChildren(child)
	end
end

function clearCharmsMonsterList()
	while monsterSelecter:getChildCount() > 0 do
		local child = monsterSelecter:getLastChild()
		monsterSelecter:destroyChildren(child)
	end
end
