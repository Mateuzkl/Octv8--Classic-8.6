preyWindow = nil
preyButton = nil
local preyTrackerButton, msgWindow = nil
local preyTracker = nil
local bankGold = 0
local inventoryGold = 0
local rerollPrice = 0
local bonusRerolls = 0

local PREY_OPCODE_OPEN = 0xE8
local PREY_OPCODE_SELECT = 0xE9
local PREY_OPCODE_LIST_REROLL = 0xEA
local PREY_OPCODE_BONUS_REROLL = 0xEB
local PREY_OPCODE_CLEAR = 0xEC
local PREY_OPCODE_SEND = 0xED
local PREY_OPCODE_TOGGLE_AUTO = 0xD8
local PREY_OPCODE_TOGGLE_LOCK = 0xD9

local PREY_SEND_ERROR = 0x00
local PREY_SEND_FULL = 0x01
local PREY_SEND_UPDATE = 0x02

local PREY_STATE_EMPTY = 0
local PREY_STATE_LIST_SELECTION = 1
local PREY_STATE_BONUS_SELECTION = 2
local PREY_STATE_ACTIVE = 3
local PREY_STATE_INACTIVE = 4

local PREY_BONUS_DAMAGE_BOOST = 0
local PREY_BONUS_DAMAGE_REDUCTION = 1
local PREY_BONUS_XP_BONUS = 2
local PREY_BONUS_IMPROVED_LOOT = 3
local PREY_BONUS_NONE = 4
local PREY_ACTION_LISTREROLL = 0
local PREY_ACTION_BONUSREROLL = 1
local PREY_ACTION_MONSTERSELECTION = 2
local PREY_ACTION_REQUEST_ALL_MONSTERS = 3
local PREY_ACTION_CHANGE_FROM_ALL = 4
local PREY_ACTION_LOCK_PREY = 5
local PREY_FLAG_AUTO_BONUS = 1
local PREY_FLAG_LOCKED = 2
local preyDescription = {}
local preySlots = {}

local RESOURCE_BANK_BALANCE = ResourceTypes and ResourceTypes.BANK_BALANCE or 0
local RESOURCE_GOLD_EQUIPPED = ResourceTypes and ResourceTypes.GOLD_EQUIPPED or 1
local RESOURCE_PREY_WILDCARDS = ResourceTypes and ResourceTypes.PREY_WILDCARDS or 10

function bonusDescription(bonusType, bonusValue, bonusGrade)
	if bonusType == PREY_BONUS_DAMAGE_BOOST then
		return "Damage bonus (" .. bonusGrade .. "/10)"
	elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
		return "Damage reduction bonus (" .. bonusGrade .. "/10)"
	elseif bonusType == PREY_BONUS_XP_BONUS then
		return "XP bonus (" .. bonusGrade .. "/10)"
	elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
		return "Loot bonus (" .. bonusGrade .. "/10)"
	elseif bonusType == PREY_BONUS_DAMAGE_BOOST then
		return "-"
	end

	return "Unknown bonus"
end

function timeleftTranslation(timeleft, forPreyTimeleft)
	if timeleft == 0 then
		if forPreyTimeleft then
			return tr("infinite bonus")
		end

		return tr("Free")
	end

	local hours = string.format("%02.f", math.floor(timeleft / 3600))
	local mins = string.format("%02.f", math.floor(timeleft / 60 - hours * 60))

	return hours .. ":" .. mins
end

function init()
	connect(g_game, {
		onGameStart = check,
		onGameEnd = hide,
		onResourceBalance = onResourceBalance,
		onPreyFreeRolls = onPreyFreeRolls,
		onPreyTimeLeft = onPreyTimeLeft,
		onPreyPrice = onPreyPrice,
		onPreyLocked = onPreyLocked,
		onPreyInactive = onPreyInactive,
		onPreyActive = onPreyActive,
		onPreySelection = onPreySelection
	})

	preyWindow = g_ui.displayUI("prey")

	preyWindow:hide()

	preyTracker = g_ui.createWidget("PreyTracker", modules.game_interface.getRightPanel())

	preyTracker:setup()
	preyTracker:setContentMaximumHeight(100)
	preyTracker:setContentMinimumHeight(47)
	preyTracker:hide()

	if g_game.isOnline() then
		check()
	end

	setUnsupportedSettings()
end

local descriptionTable = {
	pickSpecificPrey = "Available only for protocols 12+",
	preyWindow = "",
	selectPrey = "Click here to get a bonus with a higher value. The bonus for your prey will be selected randomly from one of the following: damage boost, damage reduction, bonus XP, improved loot. Your prey will be active for 2 hours hunting time again. Your prey creature will stay the same.",
	noBonusIcon = "This prey is not available for your character yet.\nCheck the large blue button(s) to learn how to unlock this prey slot",
	shopTempButton = "You can activate this prey whenever your account has Premium Status.",
	shopPermButton = "Go to the Store to purchase the Permanent Prey Slot. Once you have completed the purchase, you can activate a prey here, no matter if your character is on a free or a Premium account.",
	choosePreyButton = "Click on this button to confirm selected monsters as your prey creature for the next 2 hours hunting time.",
	preyCandidate = "Select a new prey creature for the next 2 hours hunting time.",
	rerollButton = "If you would like to select another prey creature, click here to get a new list with 9 creatures to choose from.\nThe newly selected prey will be active for 2 hours hunting time again."
}

local function bindSideButtons()
	local rightPanel = modules.game_interface.getRightPanel()
	if not rightPanel then
		return
	end

	preyButton = rightPanel:recursiveGetChildById("preyButton")
	preyTrackerButton = rightPanel:recursiveGetChildById("preyTrackerButton")

	if preyButton then
		preyButton:setOn(preyWindow and preyWindow:isVisible())
	end
	if preyTrackerButton then
		preyTrackerButton:setOn(preyTracker and preyTracker:isVisible())
	end
end

local function getProtocolGame()
	return g_game.getProtocolGame()
end

local function sendPreyMessage(opcode, slot, value)
	local protocolGame = getProtocolGame()
	if not protocolGame then
		return
	end

	local msg = OutputMessage.create()
	msg:addU8(opcode)
	if slot ~= nil then
		msg:addU8(slot)
	end
	if value ~= nil then
		msg:addU8(value)
	end
	protocolGame:send(msg)
end

function requestOpen()
	g_game.preyRequest()
end

function requestSelect(slot, listIndex)
	g_game.preyAction(slot, PREY_ACTION_MONSTERSELECTION, listIndex)
end

function requestListReroll(slot)
	g_game.preyAction(slot, PREY_ACTION_LISTREROLL, 0)
end

function requestBonusReroll(slot)
	g_game.preyAction(slot, PREY_ACTION_BONUSREROLL, 0)
end

function requestClear(slot)
	sendPreyMessage(PREY_OPCODE_CLEAR, slot)
end

function requestAutoBonus(slot, enabled)
	sendPreyMessage(PREY_OPCODE_TOGGLE_AUTO, slot, enabled and 1 or 0)
end

function requestLockPrey(slot, enabled)
	sendPreyMessage(PREY_OPCODE_TOGGLE_LOCK, slot, enabled and 1 or 0)
end

local function serverBonusToClient(bonusType)
	if bonusType == 1 then
		return PREY_BONUS_DAMAGE_BOOST
	elseif bonusType == 2 then
		return PREY_BONUS_DAMAGE_REDUCTION
	elseif bonusType == 3 then
		return PREY_BONUS_XP_BONUS
	elseif bonusType == 4 then
		return PREY_BONUS_IMPROVED_LOOT
	end
	return PREY_BONUS_NONE
end

local function bonusValueToGrade(value)
	value = tonumber(value) or 0
	if value <= 0 then
		return 0
	end
	return math.max(1, math.min(10, math.floor(((value - 5) / 35) * 9) + 1))
end

local function hasSlotFlag(flags, flag)
	flags = tonumber(flags) or 0
	return math.floor(flags / flag) % 2 == 1
end

local function readOutfit(msg)
	return {
		type = msg:getU16(),
		head = msg:getU8(),
		body = msg:getU8(),
		legs = msg:getU8(),
		feet = msg:getU8(),
		addons = msg:getU8()
	}
end

local function parseSlot(msg)
	local slot = {
		state = msg:getU8(),
		timeUntilFreeReroll = msg:getU32(),
		monster = "",
		outfit = nil,
		bonusType = PREY_BONUS_NONE,
		bonusValue = 0,
		timeLeft = 0,
		flags = 0,
		names = {},
		outfits = {}
	}

	if slot.state == PREY_STATE_LIST_SELECTION then
		local count = msg:getU8()
		for i = 1, count do
			table.insert(slot.names, msg:getString())
			table.insert(slot.outfits, readOutfit(msg))
		end
	elseif slot.state == PREY_STATE_BONUS_SELECTION then
		slot.monster = msg:getString()
		slot.outfit = readOutfit(msg)
	elseif slot.state == PREY_STATE_ACTIVE then
		slot.monster = msg:getString()
		slot.outfit = readOutfit(msg)
		slot.bonusType = serverBonusToClient(msg:getU8())
		slot.bonusValue = msg:getU8()
		slot.timeLeft = msg:getU32()
		slot.flags = msg:getU8()
	elseif slot.state == PREY_STATE_INACTIVE then
		slot.monster = msg:getString()
		slot.outfit = readOutfit(msg)
	end

	return slot
end

local function updateWildcardBalance(wildcards)
	bonusRerolls = wildcards
	if preyWindow and preyWindow.wildCards then
		preyWindow.wildCards.text:setText(tostring(wildcards))
	end
end

local function updateGoldBalance()
	if preyWindow and preyWindow.gold then
		preyWindow.gold.text:setText(comma_value(bankGold + inventoryGold))
	end
end

local function syncResourceBalance(resourceType)
	local player = g_game.getLocalPlayer()
	if not player or not player.getResourceBalance then
		return
	end

	onResourceBalance(resourceType, player:getResourceBalance(resourceType))
end

local function syncPreyBalances()
	syncResourceBalance(RESOURCE_BANK_BALANCE)
	syncResourceBalance(RESOURCE_GOLD_EQUIPPED)
	syncResourceBalance(RESOURCE_PREY_WILDCARDS)
end

local function setRerollPriceLabel(priceWidget, isFree)
	if isFree then
		priceWidget:setText("Free")
	else
		priceWidget:setText(comma_value(rerollPrice))
	end
end

local function renderEmptySlot(slot)
	onPreyInactive(slot, 0)
	local prey = preyWindow["slot" .. slot + 1]
	if not prey then
		return
	end

	prey.title:setText("Empty")
	prey.description = nil
	prey.inactive.list:destroyChildren()
	function prey.inactive.choose.choosePreyButton.onClick()
		requestListReroll(slot)
	end
end

local function renderBonusSelection(slot, monsterName, outfit, timeUntilFreeReroll)
	onPreyInactive(slot, timeUntilFreeReroll or 0, monsterName, outfit)
	local prey = preyWindow["slot" .. slot + 1]
	if not prey then
		return
	end

	prey.title:setText(capitalFormatStr(monsterName) .. "...")
	prey.inactive.list:destroyChildren()
	preyWindow.description:setText("Rolling prey bonus...")
end

function renderPreySlot(slot)
	if not preyWindow then
		return
	end

	local data = preySlots[slot]
	if not data or data.state == PREY_STATE_EMPTY then
		renderEmptySlot(slot)
	elseif data.state == PREY_STATE_LIST_SELECTION then
		onPreySelection(slot, PREY_BONUS_NONE, 0, 0, data.names or {}, data.outfits or {}, data.timeUntilFreeReroll or 0)
	elseif data.state == PREY_STATE_BONUS_SELECTION then
		renderBonusSelection(slot, data.monster or "", data.outfit, data.timeUntilFreeReroll or 0)
	elseif data.state == PREY_STATE_ACTIVE then
		onPreyActive(slot, data.monster or "", data.outfit, data.bonusType, data.bonusValue, bonusValueToGrade(data.bonusValue), data.timeLeft or 0, data.timeUntilFreeReroll or 0, data.flags or 0)
	elseif data.state == PREY_STATE_INACTIVE then
		onPreyInactive(slot, data.timeUntilFreeReroll or 0, data.monster, data.outfit)
		local prey = preyWindow["slot" .. slot + 1]
		if prey then
			local title = data.monster and data.monster ~= "" and data.monster or "Inactive"
			prey.title:setText(capitalFormatStr(title))
		end
	end
end

local function renderAllSlots()
	for slot = 0, 2 do
		renderPreySlot(slot)
	end
end

local function discardUnreadPreyMessage(msg)
	while not msg:eof() do
		msg:getU8()
	end
end

local function parsePreyMessage(msg)
	local subtype = msg:getU8()
	if subtype == PREY_SEND_ERROR then
		return showMessage(tr("Prey Error"), msg:getString())
	end

	if subtype == PREY_SEND_FULL then
		updateWildcardBalance(msg:getU8())
		onPreyPrice(msg:getU32())
		for slot = 0, 2 do
			preySlots[slot] = parseSlot(msg)
		end
		renderAllSlots()
	elseif subtype == PREY_SEND_UPDATE then
		updateWildcardBalance(msg:getU8())
		onPreyPrice(msg:getU32())
		local slot = msg:getU8()
		preySlots[slot] = parseSlot(msg)
		renderPreySlot(slot)
	end
end

function onPreyMessage(protocol, msg)
	local ok, err = pcall(parsePreyMessage, msg)
	if not ok then
		g_logger.error("Failed to parse prey message: " .. tostring(err))
		discardUnreadPreyMessage(msg)
	end
end

function onHover(widget)
	if type(widget) == "string" then
		return preyWindow.description:setText(descriptionTable[widget])
	elseif type(widget) == "number" then
		local slot = "slot" .. widget + 1
		local tracker = preyTracker.contentsPanel[slot]
		local desc = tracker.time:getTooltip()
		desc = desc:sub(1, desc:len() - 46)

		return preyWindow.description:setText(desc)
	end

	if widget:isVisible() then
		local id = widget:getId()
		local desc = descriptionTable[id]

		if desc then
			preyWindow.description:setText(desc)
		end
	end
end

function terminate()
	disconnect(g_game, {
		onGameStart = check,
		onGameEnd = hide,
		onResourceBalance = onResourceBalance,
		onPreyFreeRolls = onPreyFreeRolls,
		onPreyTimeLeft = onPreyTimeLeft,
		onPreyPrice = onPreyPrice,
		onPreyLocked = onPreyLocked,
		onPreyInactive = onPreyInactive,
		onPreyActive = onPreyActive,
		onPreySelection = onPreySelection
	})

	preyButton = nil
	preyTrackerButton = nil

	if preyWindow then
		preyWindow:destroy()
		preyWindow = nil
	end

	if preyTracker then
		preyTracker:destroy()
		preyTracker = nil
	end

	if msgWindow then
		msgWindow:destroy()

		msgWindow = nil
	end
end

local n = 0

function setUnsupportedSettings()
	local t = {
		"slot1",
		"slot2",
		"slot3"
	}

	for i, slot in pairs(t) do
		local panel = preyWindow[slot]

		for j, state in pairs({
			panel.active,
			panel.inactive
		}) do
			state.select.price.text:setText("-------")
		end

		panel.active.autoRerollPrice.text:setText("-")
		panel.active.lockPreyPrice.text:setText("-")
		panel.active.choose.price.text:setText(1)
		panel.active.autoReroll.autoRerollCheck:enable()
		panel.active.lockPrey.lockPreyCheck:enable()
	end
end

function check()
	bindSideButtons()
	if not preyButton or not preyTrackerButton then
		scheduleEvent(bindSideButtons, 100)
	end
	requestOpen()
end

function toggleTracker()
	bindSideButtons()
	if preyTracker:isVisible() then
		preyTracker:hide()
	else
		preyTracker:show()
	end

	if preyTrackerButton then
		preyTrackerButton:setOn(preyTracker:isVisible())
	end
end

function hide()
	preyWindow:hide()
	if preyButton then
		preyButton:setOn(false)
	end

	if msgWindow then
		msgWindow:destroy()

		msgWindow = nil
	end
end

function show()
	bindSideButtons()
	preyWindow:show()
	preyWindow:raise()
	preyWindow:focus()
	if preyButton then
		preyButton:setOn(true)
	end
	requestOpen()
	syncPreyBalances()
end

function toggle()
	if preyWindow:isVisible() then
		return hide()
	end

	show()
end

function onPreyFreeRolls(slot, timeleft)
	local prey = preyWindow["slot" .. slot + 1]
	local percent = timeleft / 1200 * 100
	local desc = timeleftTranslation(timeleft * 60)

	if not prey then
		return
	end

	for i, panel in pairs({
		prey.active,
		prey.inactive
	}) do
		local progressBar = panel.reroll.button.time
		local price = panel.reroll.price.text

		progressBar:setPercent(percent)
		progressBar:setText(desc)

		if timeleft == 0 then
			setRerollPriceLabel(price, true)
		end
	end
end

function onPreyTimeLeft(slot, timeLeft)
	preyDescription[slot] = preyDescription[slot] or {
		one = "",
		two = ""
	}
	local text = preyDescription[slot].one .. timeleftTranslation(timeLeft, true) .. preyDescription[slot].two
	local percent = timeLeft / 7200 * 100
	slot = "slot" .. slot + 1
	local tracker = preyTracker.contentsPanel[slot]

	tracker.time:setPercent(percent)
	tracker.time:setTooltip(text)

	for i, element in pairs({
		tracker.creatureName,
		tracker.creature,
		tracker.preyType,
		tracker.time
	}) do
		element:setTooltip(text)

		function element.onClick()
			show()
		end
	end

	local prey = preyWindow[slot]

	if not prey then
		return
	end

	local progressbar = prey.active.creatureAndBonus.timeLeft
	local desc = timeleftTranslation(timeLeft, true)

	progressbar:setPercent(percent)
	progressbar:setText(desc)
end

function onPreyPrice(price)
	rerollPrice = price
	local t = {
		"slot1",
		"slot2",
		"slot3"
	}

	for i, slot in pairs(t) do
		local panel = preyWindow[slot]

		for j, state in pairs({
			panel.active,
			panel.inactive
		}) do
			local price = state.reroll.price.text
			local progressBar = state.reroll.button.time

			if progressBar:getText() ~= "Free" then
				setRerollPriceLabel(price, false)
			else
				setRerollPriceLabel(price, true)
				progressBar:setPercent(0)
			end
		end
	end
end

function setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
	local prey = preyWindow["slot" .. slot + 1]

	if not prey then
		return
	end

	local percent = timeUntilFreeReroll / 1200 * 100
	local desc = timeleftTranslation(timeUntilFreeReroll * 60)

	for i, panel in pairs({
		prey.active,
		prey.inactive
	}) do
		local reroll = panel.reroll.button.time

		reroll:setPercent(percent)
		reroll:setText(desc)

		local price = panel.reroll.price.text

		setRerollPriceLabel(price, timeUntilFreeReroll <= 0)
	end
end

function onPreyLocked(slot, unlockState, timeUntilFreeReroll)
	slot = "slot" .. slot + 1
	local tracker = preyTracker.contentsPanel[slot]

	if tracker then
		tracker:hide()
		preyTracker:setContentMaximumHeight(preyTracker:getHeight() - 20)
	end

	local prey = preyWindow[slot]

	if not prey then
		return
	end

	prey.title:setText("Locked")
	prey.inactive:hide()
	prey.active:hide()
	prey.locked:show()
end

function onPreyInactive(slot, timeUntilFreeReroll)
	local tracker = preyTracker.contentsPanel["slot" .. slot + 1]
	local holderName = "Inactive"
	local tooltip = "Inactive Prey. \n\nClick in this window to open the prey dialog."

	if tracker then
		tracker.creature:hide()
		tracker.noCreature:show()
		tracker.creatureName:setText(holderName)
		tracker.time:setPercent(0)
		tracker.preyType:setImageSource("/images/game/prey/prey_no_bonus")

		for i, element in pairs({
			tracker.creatureName,
			tracker.creature,
			tracker.preyType,
			tracker.time
		}) do
			element:setTooltip(tooltip)

			function element.onClick()
				show()
			end
		end
	end

	setTimeUntilFreeReroll(slot, timeUntilFreeReroll)

	local prey = preyWindow["slot" .. slot + 1]

	if not prey then
		return
	end

	prey.active:hide()
	prey.locked:hide()
	prey.inactive:show()

	local rerollButton = prey.inactive.reroll.button.rerollButton

	rerollButton:setImageSource("/images/game/prey/prey_reroll")
	rerollButton:enable()

	function rerollButton.onClick()
		requestListReroll(slot)
	end
end

function setBonusGradeStars(slot, grade)
	local prey = preyWindow["slot" .. slot + 1]
	local gradePanel = prey.active.creatureAndBonus.bonus.grade

	gradePanel:destroyChildren()

	for i = 1, 10 do
		if i <= grade then
			local widget = g_ui.createWidget("Star", gradePanel)

			function widget.onHoverChange(widget, hovered)
				onHover(slot)
			end
		else
			local widget = g_ui.createWidget("NoStar", gradePanel)

			function widget.onHoverChange(widget, hovered)
				onHover(slot)
			end
		end
	end
end

function getBigIconPath(bonusType)
	local path = "/images/game/prey/"

	if bonusType == PREY_BONUS_DAMAGE_BOOST then
		return path .. "prey_bigdamage"
	elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
		return path .. "prey_bigdefense"
	elseif bonusType == PREY_BONUS_XP_BONUS then
		return path .. "prey_bigxp"
	elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
		return path .. "prey_bigloot"
	end
end

function getSmallIconPath(bonusType)
	local path = "/images/game/prey/"

	if bonusType == PREY_BONUS_DAMAGE_BOOST then
		return path .. "prey_damage"
	elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
		return path .. "prey_defense"
	elseif bonusType == PREY_BONUS_XP_BONUS then
		return path .. "prey_xp"
	elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
		return path .. "prey_loot"
	end
end

function getBonusDescription(bonusType)
	if bonusType == PREY_BONUS_DAMAGE_BOOST then
		return "Damage Boost"
	elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
		return "Damage Reduction"
	elseif bonusType == PREY_BONUS_XP_BONUS then
		return "XP Bonus"
	elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
		return "Improved Loot"
	end
end

function getTooltipBonusDescription(bonusType, bonusValue)
	if bonusType == PREY_BONUS_DAMAGE_BOOST then
		return "You deal +" .. bonusValue .. "% extra damage against your prey creature."
	elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
		return "You take " .. bonusValue .. "% less damage from your prey creature."
	elseif bonusType == PREY_BONUS_XP_BONUS then
		return "Killing your prey creature rewards +" .. bonusValue .. "% extra XP."
	elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
		return "Your creature has a +" .. bonusValue .. "% chance to drop additional loot."
	end
end

function capitalFormatStr(str)
	local formatted = ""
	str = string.split(str, " ")

	for i, word in ipairs(str) do
		formatted = formatted .. " " .. string.gsub(word, "^%l", string.upper)
	end

	return formatted:trim()
end

function onItemBoxChecked(widget)
	for i, slot in pairs({
		"slot1",
		"slot2",
		"slot3"
	}) do
		local list = preyWindow[slot].inactive.list:getChildren()

		if table.find(list, widget) then
			for i, child in pairs(list) do
				if child ~= widget then
					child:setChecked(false)
				end
			end
		end
	end

	widget:setChecked(true)
end

function onPreyActive(slot, currentHolderName, currentHolderOutfit, bonusType, bonusValue, bonusGrade, timeLeft, timeUntilFreeReroll, lockType)
	local tracker = preyTracker.contentsPanel["slot" .. slot + 1]
	currentHolderName = capitalFormatStr(currentHolderName)
	local percent = timeLeft / 7200 * 100
	local autoBonusEnabled = hasSlotFlag(lockType, PREY_FLAG_AUTO_BONUS)
	local lockPreyEnabled = hasSlotFlag(lockType, PREY_FLAG_LOCKED)

	if tracker then
		tracker.creature:show()
		tracker.noCreature:hide()
		tracker.creatureName:setText(currentHolderName)
		if currentHolderOutfit then
			tracker.creature:setOutfit(currentHolderOutfit)
			tracker.creature:show()
			tracker.noCreature:hide()
		else
			tracker.creature:hide()
			tracker.noCreature:show()
		end
		tracker.preyType:setImageSource(getSmallIconPath(bonusType))
		tracker.time:setPercent(percent)

		preyDescription[slot] = preyDescription[slot] or {}
		preyDescription[slot].one = "Creature: " .. currentHolderName .. "\nDuration: "
		preyDescription[slot].two = "\nValue: " .. bonusGrade .. "/10" .. "\nType: " .. getBonusDescription(bonusType) .. "\n" .. getTooltipBonusDescription(bonusType, bonusValue) .. "\n\nClick in this window to open the prey dialog."

		for i, element in pairs({
			tracker.creatureName,
			tracker.creature,
			tracker.preyType,
			tracker.time
		}) do
			element:setTooltip(preyDescription[slot].one .. timeleftTranslation(timeLeft, true) .. preyDescription[slot].two)

			function element.onClick()
				show()
			end
		end
	end

	local prey = preyWindow["slot" .. slot + 1]

	if not prey then
		return
	end

	prey.inactive:hide()
	prey.locked:hide()
	prey.active:show()
	prey.title:setText(currentHolderName)

	local creatureAndBonus = prey.active.creatureAndBonus

	if currentHolderOutfit then
		creatureAndBonus.creature:setOutfit(currentHolderOutfit)
		creatureAndBonus.creature:show()
	else
		creatureAndBonus.creature:hide()
	end
	setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
	creatureAndBonus.bonus.icon:setImageSource(getBigIconPath(bonusType))

	function creatureAndBonus.bonus.icon.onHoverChange(widget, hovered)
		onHover(slot)
	end

	setBonusGradeStars(slot, bonusGrade)
	creatureAndBonus.timeLeft:setPercent(percent)
	creatureAndBonus.timeLeft:setText(timeleftTranslation(timeLeft))

	function prey.active.choose.selectPrey.onClick()
		requestBonusReroll(slot)
	end

	function prey.active.reroll.button.rerollButton.onClick()
		requestListReroll(slot)
	end

	local autoCheck = prey.active.autoReroll.autoRerollCheck
	local lockCheck = prey.active.lockPrey.lockPreyCheck
	prey.active.autoRerollPrice.text:setText(1)
	prey.active.lockPreyPrice.text:setText(5)

	autoCheck:enable()
	lockCheck:enable()
	autoCheck.preyUpdating = true
	lockCheck.preyUpdating = true
	autoCheck:setChecked(autoBonusEnabled)
	lockCheck:setChecked(lockPreyEnabled)
	autoCheck.preyUpdating = false
	lockCheck.preyUpdating = false
	autoCheck:setTooltip("Uses 1 Prey Wildcard to automatically roll a new bonus for this creature when the 2-hour hunting time expires.")
	lockCheck:setTooltip("Uses 5 Prey Wildcards to renew this creature with the exact same bonus when the 2-hour hunting time expires.")

	function autoCheck.onCheckChange(widget)
		if widget.preyUpdating then
			return
		end
		requestAutoBonus(slot, widget:isChecked())
	end

	function lockCheck.onCheckChange(widget)
		if widget.preyUpdating then
			return
		end
		requestLockPrey(slot, widget:isChecked())
	end
end

function onPreySelection(slot, bonusType, bonusValue, bonusGrade, names, outfits, timeUntilFreeReroll)
	local tracker = preyTracker.contentsPanel["slot" .. slot + 1]

	if tracker then
		tracker.creature:hide()
		tracker.noCreature:show()
		tracker.creatureName:setText("Inactive")
		tracker.time:setPercent(0)
		tracker.preyType:setImageSource("/images/game/prey/prey_no_bonus")

		for i, element in pairs({
			tracker.creatureName,
			tracker.creature,
			tracker.preyType,
			tracker.time
		}) do
			element:setTooltip("Inactive Prey. \n\nClick in this window to open the prey dialog.")

			function element.onClick()
				show()
			end
		end
	end

	local prey = preyWindow["slot" .. slot + 1]

	setTimeUntilFreeReroll(slot, timeUntilFreeReroll)

	if not prey then
		return
	end

	prey.active:hide()
	prey.locked:hide()
	prey.inactive:show()
	prey.title:setText(tr("Select monster"))

	local rerollButton = prey.inactive.reroll.button.rerollButton

	function rerollButton.onClick()
		requestListReroll(slot)
	end

	local list = prey.inactive.list

	list:destroyChildren()

	for i, name in ipairs(names) do
		local box = g_ui.createWidget("PreyCreatureBox", list)
		name = capitalFormatStr(name)

		box:setTooltip(name)
		if outfits and outfits[i] then
			box.creature:setOutfit(outfits[i])
			box.creature:show()
			if box.name then
				box.name:hide()
			end
		else
			box.creature:hide()
			if box.name then
				box.name:setText(name)
				box.name:show()
			end
		end
	end

	function prey.inactive.choose.choosePreyButton.onClick()
		for i, child in pairs(list:getChildren()) do
			if child:isChecked() then
				return requestSelect(slot, i - 1)
			end
		end

		return showMessage(tr("Error"), tr("Select monster to proceed."))
	end
end

function onResourceBalance(type, balance)
	type = tonumber(type)
	balance = tonumber(balance) or 0

	local bankBalanceType = RESOURCE_BANK_BALANCE or 0
	local equippedGoldType = RESOURCE_GOLD_EQUIPPED or 1
	local preyWildcardsType = RESOURCE_PREY_WILDCARDS or 10

	if type == bankBalanceType then
		bankGold = balance
		updateGoldBalance()
	elseif type == equippedGoldType then
		inventoryGold = balance
		updateGoldBalance()
	elseif type == preyWildcardsType then
		updateWildcardBalance(balance)
	end
end

function showMessage(title, message)
	if msgWindow then
		msgWindow:destroy()
	end

	msgWindow = displayInfoBox(title, message)

	msgWindow:show()
	msgWindow:raise()
	msgWindow:focus()
end
