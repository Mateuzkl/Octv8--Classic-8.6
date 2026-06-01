MessageSettings = {
	none = {},
	consoleRed = {
		consoleTab = "Default",
		color = TextColors.red
	},
	consoleOrange = {
		consoleTab = "Default",
		color = TextColors.orange
	},
	consoleBlue = {
		consoleTab = "Default",
		color = TextColors.blue
	},
	centerRed = {
		screenTarget = "lowCenterLabel",
		consoleTab = "Server Log",
		color = TextColors.red
	},
	centerGreen = {
		screenTarget = "highCenterLabel",
		consoleOption = "showInfoMessagesInConsole",
		consoleTab = "Server Log",
		color = TextColors.green
	},
	centerWhite = {
		screenTarget = "middleCenterLabel",
		consoleOption = "showEventMessagesInConsole",
		consoleTab = "Server Log",
		color = TextColors.white
	},
	bottomWhite = {
		screenTarget = "statusLabel",
		consoleOption = "showEventMessagesInConsole",
		consoleTab = "Server Log",
		color = TextColors.white
	},
	status = {
		screenTarget = "statusLabel",
		consoleOption = "showStatusMessagesInConsole",
		consoleTab = "Server Log",
		color = TextColors.white
	},
	statusSmall = {
		screenTarget = "statusLabel",
		color = TextColors.white
	},
	private = {
		screenTarget = "privateLabel",
		color = TextColors.lightblue
	}
}
MessageTypes = {
	[MessageModes.MonsterSay] = MessageSettings.consoleOrange,
	[MessageModes.MonsterYell] = MessageSettings.consoleOrange,
	[MessageModes.BarkLow] = MessageSettings.consoleOrange,
	[MessageModes.BarkLoud] = MessageSettings.consoleOrange,
	[MessageModes.Failure] = MessageSettings.statusSmall,
	[MessageModes.Login] = MessageSettings.bottomWhite,
	[MessageModes.Game] = MessageSettings.centerWhite,
	[MessageModes.Status] = MessageSettings.status,
	[MessageModes.Warning] = MessageSettings.centerRed,
	[MessageModes.Look] = MessageSettings.centerGreen,
	[MessageModes.Loot] = MessageSettings.centerGreen,
	[MessageModes.Red] = MessageSettings.consoleRed,
	[MessageModes.Blue] = MessageSettings.consoleBlue,
	[MessageModes.PrivateFrom] = MessageSettings.consoleBlue,
	[MessageModes.GamemasterBroadcast] = MessageSettings.consoleRed,
	[MessageModes.DamageDealed] = MessageSettings.status,
	[MessageModes.DamageReceived] = MessageSettings.status,
	[MessageModes.Heal] = MessageSettings.status,
	[MessageModes.Exp] = MessageSettings.status,
	[MessageModes.DamageOthers] = MessageSettings.none,
	[MessageModes.HealOthers] = MessageSettings.none,
	[MessageModes.ExpOthers] = MessageSettings.none,
	[MessageModes.TradeNpc] = MessageSettings.centerWhite,
	[MessageModes.Guild] = MessageSettings.centerWhite,
	[MessageModes.Party] = MessageSettings.centerGreen,
	[MessageModes.PartyManagement] = MessageSettings.centerWhite,
	[MessageModes.TutorialHint] = MessageSettings.centerWhite,
	[MessageModes.BeyondLast] = MessageSettings.centerWhite,
	[MessageModes.Report] = MessageSettings.consoleRed,
	[MessageModes.HotkeyUse] = MessageSettings.centerGreen,
	[254] = MessageSettings.private
}
hexColorStrings = {
	darkorange = "#8B4513",
	darkyellow = "#808000",
	blue = "#0000FF",
	lightyellow = "#FFFFE0",
	darkteal = "#008B8B",
	orange = "#FFA500",
	lightteal = "#00CED1",
	yellow = "#FFFF00",
	red = "#FF0000",
	darkblue = "#00008B",
	lightgreen = "#90EE90",
	darkgreen = "#006400",
	lightblue = "#ADD8E6",
	lightred = "#FFA07A",
	darkred = "#800000",
	teal = "#008080",
	lightpurple = "#D8BFD8",
	darkpurple = "#8A2BE2",
	purple = "#800080",
	green = "#00FF00",
	lightorange = "#FFD700"
}
messagesPanel = nil

function init()
	for messageMode, _ in pairs(MessageTypes) do
		registerMessageMode(messageMode, displayMessage)
	end

	connect(g_game, "onGameEnd", clearMessages)

	messagesPanel = g_ui.loadUI("textmessage", modules.game_interface.getRootPanel())
end

function terminate()
	for messageMode, _ in pairs(MessageTypes) do
		unregisterMessageMode(messageMode, displayMessage)
	end

	disconnect(g_game, "onGameEnd", clearMessages)
	clearMessages()
	messagesPanel:destroy()
end

function calculateVisibleTime(text)
	return math.max(#text * 50, 3000)
end

function getBBColorData(inputString, defaultHex)
	local splitChar = "Π"
	local stringData = {}
	local hasHex = false
	local modifiedString = inputString:gsub("(%[color=[#%w]+].-%[/color%])", splitChar .. "%1" .. splitChar)

	for part in modifiedString:gmatch("([^" .. splitChar .. "]+)") do
		local hex, text = part:match("%[color=([#%w]+)%](.-)%[/color%]")
		hex = hexColorStrings[hex] or hex
		local modText, modHex = nil

		if hex and text and #text:gsub("%s", "") > 0 then
			hasHex = true
			modText = text
			modHex = hex
		else
			modText = part
			modHex = defaultHex
		end

		for match in modText:gmatch("%[emote%](.)%[/emote%]") do
			local before, after = modText:match("(.-)%[emote%]" .. match .. "%[/emote%](.*)")

			if #before > 0 then
				table.insert(stringData, {
					hex = modHex,
					text = before
				})
			end

			table.insert(stringData, {
				hex = emoticonHex,
				text = match
			})

			modText = after
			hasHex = true
		end

		if #modText > 0 then
			table.insert(stringData, {
				hex = modHex,
				text = modText
			})
		end
	end

	if hasHex then
		local returnData = {}

		for _, data in ipairs(stringData) do
			table.insert(returnData, data.text)
			table.insert(returnData, data.hex)
		end

		return returnData
	end

	return {}
end

function displayMessage(mode, text)
	if not g_game.isOnline() then
		return
	end

	local msgtype = MessageTypes[mode]

	if not msgtype then
		return
	end

	if msgtype == MessageSettings.none then
		return
	end

	if msgtype.consoleTab ~= nil and (msgtype.consoleOption == nil or modules.client_options.getOption(msgtype.consoleOption)) then
		modules.game_console.addText(text, msgtype, tr(msgtype.consoleTab))
	end

	if msgtype.screenTarget then
		local label = messagesPanel:recursiveGetChildById(msgtype.screenTarget)

		label:setText(text)
		label:setColor(msgtype.color)

		local coloredData = getBBColorData(text, msgtype.color)

		if #coloredData > 0 then
			label:setColoredText(coloredData)
		end

		label:setVisible(true)
		removeEvent(label.hideEvent)

		label.hideEvent = scheduleEvent(function ()
			label:setVisible(false)
		end, calculateVisibleTime(text))
	end
end

function displayPrivateMessage(text)
	displayMessage(254, text)
end

function displayStatusMessage(text)
	displayMessage(MessageModes.Status, text)
end

function displayFailureMessage(text)
	displayMessage(MessageModes.Failure, text)
end

local function notifyLevelUpBanner(text)
	local level = text:match("^You advanced from Level %d+ to Level (%d+)%.?$")
	if not level then
		return
	end

	if modules.game_notifications and modules.game_notifications.showLevelUpBanner then
		modules.game_notifications.showLevelUpBanner(tonumber(level))
	end
end

function displayGameMessage(text)
	displayMessage(MessageModes.Game, text)
	notifyLevelUpBanner(text)
end

function displayBroadcastMessage(text)
	displayMessage(MessageModes.Warning, text)
end

function clearMessages()
	for _i, child in pairs(messagesPanel:recursiveGetChildren()) do
		if child:getId():match("Label") then
			child:hide()
			removeEvent(child.hideEvent)
		end
	end
end

function LocalPlayer:onAutoWalkFail(player)
	modules.game_textmessage.displayFailureMessage(tr("There is no way."))
end
