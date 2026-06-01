unjustifiedPointsWindow = nil
unjustifiedPointsButton = nil
contentsPanel = nil
openPvpSituationsLabel = nil
currentSkullWidget = nil
skullTimeLabel = nil
dayProgressBar = nil
weekProgressBar = nil
monthProgressBar = nil
daySkullWidget = nil
weekSkullWidget = nil
monthSkullWidget = nil
refreshEvent = nil

local OPCODE_UNJUSTIFIED_REQUEST = 0x2E
local OPCODE_UNJUSTIFIED_SEND = 0x2F
local ACTION_REFRESH = 1
local REFRESH_DELAY = 30000

local function sendRefreshRequest()
	local protocolGame = g_game.getProtocolGame()
	if not protocolGame then
		return
	end

	local msg = OutputMessage.create()
	msg:addU8(OPCODE_UNJUSTIFIED_REQUEST)
	msg:addU8(ACTION_REFRESH)
	protocolGame:send(msg)
end

local function formatSkullTime(seconds)
	seconds = math.max(0, tonumber(seconds) or 0)
	if seconds == 0 then
		return "No skull"
	end

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	if days > 0 then
		return string.format("%id %ih", days, hours)
	elseif hours > 0 then
		return string.format("%ih %im", hours, minutes)
	end
	return string.format("%im", math.max(1, minutes))
end

local function scheduleRefresh()
	if refreshEvent then
		removeEvent(refreshEvent)
		refreshEvent = nil
	end

	if g_game.isOnline() then
		refreshEvent = scheduleEvent(function()
			refreshEvent = nil
			sendRefreshRequest()
			scheduleRefresh()
		end, REFRESH_DELAY)
	end
end

local function registerProtocol()
	ProtocolGame.unregisterOpcode(OPCODE_UNJUSTIFIED_SEND)
	ProtocolGame.registerOpcode(OPCODE_UNJUSTIFIED_SEND, function(protocol, msg)
		local unjustifiedPoints = {
			killsDay = msg:getU8(),
			killsDayRemaining = msg:getU8(),
			killsWeek = msg:getU8(),
			killsWeekRemaining = msg:getU8(),
			killsMonth = msg:getU8(),
			killsMonthRemaining = msg:getU8(),
			skullTimeSeconds = msg:getU32()
		}
		local openPvpSituations = msg:getU8()
		local skull = msg:getU8()

		onUnjustifiedPointsChange(unjustifiedPoints)
		onOpenPvpSituationsChange(openPvpSituations)

		local localPlayer = g_game.getLocalPlayer()
		if localPlayer then
			onSkullChange(localPlayer, skull)
		end
	end)
end

function init()
	connect(g_game, {
		onGameStart = online,
		onGameEnd = offline
	})
	connect(LocalPlayer, {
		onSkullChange = onSkullChange
	})

	unjustifiedPointsButton = modules.client_topmenu.addRightGameToggleButton("unjustifiedPointsButton", tr("Unjustified Points"), "/images/topbuttons/unjustifiedpoints", toggle)

	unjustifiedPointsButton:setOn(true)
	unjustifiedPointsButton:hide()

	unjustifiedPointsWindow = g_ui.loadUI("unjustifiedpoints", modules.game_interface.getRightPanel())

	unjustifiedPointsWindow:disableResize()
	unjustifiedPointsWindow:setup()

	contentsPanel = unjustifiedPointsWindow:getChildById("contentsPanel")
	openPvpSituationsLabel = contentsPanel:getChildById("openPvpSituationsLabel")
	currentSkullWidget = contentsPanel:getChildById("currentSkullWidget")
	skullTimeLabel = contentsPanel:getChildById("skullTimeLabel")
	dayProgressBar = contentsPanel:getChildById("dayProgressBar")
	weekProgressBar = contentsPanel:getChildById("weekProgressBar")
	monthProgressBar = contentsPanel:getChildById("monthProgressBar")
	daySkullWidget = contentsPanel:getChildById("daySkullWidget")
	weekSkullWidget = contentsPanel:getChildById("weekSkullWidget")
	monthSkullWidget = contentsPanel:getChildById("monthSkullWidget")

	if g_game.isOnline() then
		online()
	end
end

function terminate()
	disconnect(g_game, {
		onGameStart = online,
		onGameEnd = offline
	})
	disconnect(LocalPlayer, {
		onSkullChange = onSkullChange
	})
	if refreshEvent then
		removeEvent(refreshEvent)
		refreshEvent = nil
	end
	ProtocolGame.unregisterOpcode(OPCODE_UNJUSTIFIED_SEND)
	unjustifiedPointsWindow:destroy()
	unjustifiedPointsButton:destroy()
end

function onMiniWindowClose()
	unjustifiedPointsButton:setOn(false)
end

function toggle()
	if unjustifiedPointsButton:isOn() then
		unjustifiedPointsWindow:close()
		unjustifiedPointsButton:setOn(false)
	else
		unjustifiedPointsWindow:open()
		unjustifiedPointsButton:setOn(true)
	end
end

function online()
	registerProtocol()
	unjustifiedPointsButton:show()
	refresh()
	scheduleRefresh()
end

function offline()
	unjustifiedPointsButton:hide()
	unjustifiedPointsWindow:close()
	if refreshEvent then
		removeEvent(refreshEvent)
		refreshEvent = nil
	end
end

function refresh()
	local localPlayer = g_game.getLocalPlayer()
	if localPlayer then
		onSkullChange(localPlayer, localPlayer:getSkull())
	end
	sendRefreshRequest()
end

function onSkullChange(localPlayer, skull)
	if not localPlayer:isLocalPlayer() then
		return
	end

	if skull == SkullRed or skull == SkullBlack then
		currentSkullWidget:setIcon(getSkullImagePath(skull))
		currentSkullWidget:setTooltip("Remaining skull time")
	else
		currentSkullWidget:setIcon("")
		currentSkullWidget:setTooltip("You have no skull")
	end

	daySkullWidget:setIcon(getSkullImagePath(getNextSkullId(skull)))
	weekSkullWidget:setIcon(getSkullImagePath(getNextSkullId(skull)))
	monthSkullWidget:setIcon(getSkullImagePath(getNextSkullId(skull)))
end

function onOpenPvpSituationsChange(amount)
	openPvpSituationsLabel:setText(amount)
end

local function getColorByKills(kills)
	if kills < 2 then
		return "red"
	elseif kills < 3 then
		return "yellow"
	end

	return "green"
end

function onUnjustifiedPointsChange(unjustifiedPoints)
	local skullTimeSeconds = unjustifiedPoints.skullTimeSeconds or unjustifiedPoints.skullTime or 0
	if skullTimeSeconds == 0 then
		skullTimeLabel:setText("No skull")
		skullTimeLabel:setTooltip("You have no skull")
	else
		skullTimeLabel:setText(formatSkullTime(skullTimeSeconds))
		skullTimeLabel:setTooltip("Remaining skull time")
	end

	dayProgressBar:setValue(unjustifiedPoints.killsDay, 0, 100)
	dayProgressBar:setBackgroundColor(getColorByKills(unjustifiedPoints.killsDayRemaining))
	dayProgressBar:setTooltip(string.format("Unjustified points gained during the last 24 hours.\n%i kill%s left.", unjustifiedPoints.killsDayRemaining, unjustifiedPoints.killsDayRemaining == 1 and "" or "s"))
	dayProgressBar:setText(string.format("%i kill%s left", unjustifiedPoints.killsDayRemaining, unjustifiedPoints.killsDayRemaining == 1 and "" or "s"))
	weekProgressBar:setValue(unjustifiedPoints.killsWeek, 0, 100)
	weekProgressBar:setBackgroundColor(getColorByKills(unjustifiedPoints.killsWeekRemaining))
	weekProgressBar:setTooltip(string.format("Unjustified points gained during the last 7 days.\n%i kill%s left.", unjustifiedPoints.killsWeekRemaining, unjustifiedPoints.killsWeekRemaining == 1 and "" or "s"))
	weekProgressBar:setText(string.format("%i kill%s left", unjustifiedPoints.killsWeekRemaining, unjustifiedPoints.killsWeekRemaining == 1 and "" or "s"))
	monthProgressBar:setValue(unjustifiedPoints.killsMonth, 0, 100)
	monthProgressBar:setBackgroundColor(getColorByKills(unjustifiedPoints.killsMonthRemaining))
	monthProgressBar:setTooltip(string.format("Unjustified points gained during the last 30 days.\n%i kill%s left.", unjustifiedPoints.killsMonthRemaining, unjustifiedPoints.killsMonthRemaining == 1 and "" or "s"))
	monthProgressBar:setText(string.format("%i kill%s left", unjustifiedPoints.killsMonthRemaining, unjustifiedPoints.killsMonthRemaining == 1 and "" or "s"))
end
