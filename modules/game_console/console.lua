SpeakTypesSettings = {
	none = {},
	say = {
		color = "#FFFF00",
		speakType = MessageModes.Say
	},
	whisper = {
		color = "#FFFF00",
		speakType = MessageModes.Whisper
	},
	yell = {
		color = "#FFFF00",
		speakType = MessageModes.Yell
	},
	broadcast = {
		color = "#F55E5E",
		speakType = MessageModes.GamemasterBroadcast
	},
	private = {
		private = true,
		color = "#5FF7F7",
		speakType = MessageModes.PrivateTo
	},
	privateRed = {
		private = true,
		color = "#F55E5E",
		speakType = MessageModes.GamemasterTo
	},
	privatePlayerToPlayer = {
		private = true,
		color = "#9F9DFD",
		speakType = MessageModes.PrivateTo
	},
	privatePlayerToNpc = {
		npcChat = true,
		color = "#9F9DFD",
		private = true,
		speakType = MessageModes.NpcTo
	},
	privateNpcToPlayer = {
		npcChat = true,
		color = "#5FF7F7",
		private = true,
		speakType = MessageModes.NpcFrom
	},
	channelYellow = {
		color = "#FFFF00",
		speakType = MessageModes.Channel
	},
	channelWhite = {
		color = "#FFFFFF",
		speakType = MessageModes.ChannelManagement
	},
	channelRed = {
		color = "#F55E5E",
		speakType = MessageModes.GamemasterChannel
	},
	channelOrange = {
		color = "#F6A731",
		speakType = MessageModes.ChannelHighlight
	},
	monsterSay = {
		hideInConsole = true,
		color = "#FE6500",
		speakType = MessageModes.MonsterSay
	},
	monsterYell = {
		hideInConsole = true,
		color = "#FE6500",
		speakType = MessageModes.MonsterYell
	},
	rvrAnswerFrom = {
		color = "#FE6500",
		speakType = MessageModes.RVRAnswer
	},
	rvrAnswerTo = {
		color = "#FE6500",
		speakType = MessageModes.RVRAnswer
	},
	rvrContinue = {
		color = "#FFFF00",
		speakType = MessageModes.RVRContinue
	}
}
SpeakTypes = {
	[MessageModes.Say] = SpeakTypesSettings.say,
	[MessageModes.Whisper] = SpeakTypesSettings.whisper,
	[MessageModes.Yell] = SpeakTypesSettings.yell,
	[MessageModes.GamemasterBroadcast] = SpeakTypesSettings.broadcast,
	[MessageModes.PrivateFrom] = SpeakTypesSettings.private,
	[MessageModes.GamemasterPrivateFrom] = SpeakTypesSettings.privateRed,
	[MessageModes.NpcTo] = SpeakTypesSettings.privatePlayerToNpc,
	[MessageModes.NpcFrom] = SpeakTypesSettings.privateNpcToPlayer,
	[MessageModes.Channel] = SpeakTypesSettings.channelYellow,
	[MessageModes.ChannelManagement] = SpeakTypesSettings.channelWhite,
	[MessageModes.GamemasterChannel] = SpeakTypesSettings.channelRed,
	[MessageModes.ChannelHighlight] = SpeakTypesSettings.channelOrange,
	[MessageModes.MonsterSay] = SpeakTypesSettings.monsterSay,
	[MessageModes.MonsterYell] = SpeakTypesSettings.monsterYell,
	[MessageModes.RVRChannel] = SpeakTypesSettings.channelWhite,
	[MessageModes.RVRContinue] = SpeakTypesSettings.rvrContinue,
	[MessageModes.RVRAnswer] = SpeakTypesSettings.rvrAnswerFrom,
	[MessageModes.NpcFromStartBlock] = SpeakTypesSettings.privateNpcToPlayer,
	[MessageModes.Spell] = SpeakTypesSettings.none,
	[MessageModes.BarkLow] = SpeakTypesSettings.none,
	[MessageModes.BarkLoud] = SpeakTypesSettings.none
}
SayModes = {
	{
		icon = "/images/game/console/whisper",
		speakTypeDesc = "whisper"
	},
	{
		icon = "/images/game/console/say",
		speakTypeDesc = "say"
	},
	{
		icon = "/images/game/console/yell",
		speakTypeDesc = "yell"
	}
}
ChannelEventFormats = {
	[ChannelEvent.Join] = "%s joined the channel.",
	[ChannelEvent.Leave] = "%s left the channel.",
	[ChannelEvent.Invite] = "%s has been invited to the channel.",
	[ChannelEvent.Exclude] = "%s has been removed from the channel."
}
hexColorStrings = {
	lightgreen = "#90EE90",
	darkgreen = "#006400",
	lightteal = "#00CED1",
	green = "#00FF00",
	darkteal = "#008B8B",
	lightred = "#FFA07A",
	teal = "#008080",
	darkred = "#800000",
	lightpurple = "#D8BFD8",
	red = "#FF0000",
	darkpurple = "#8A2BE2",
	purple = "#800080",
	lightorange = "#FFD700",
	darkorange = "#8B4513",
	orange = "#FFA500",
	lightyellow = "#FFFFE0",
	darkyellow = "#808000",
	yellow = "#FFFF00",
	lightblue = "#ADD8E6",
	darkblue = "#00008B",
	blue = "#0000FF"
}
emoticonHex = "#FFFFFF"
emoticons = dofile("emoticons.lua")
emoticonChars = {}

for _, emoticon in pairs(emoticons) do
	for _, word in pairs(emoticon.words) do
		emoticonChars[word] = emoticon.char
	end
end

MAX_HISTORY = 500
MAX_LINES = 100
HELP_CHANNEL = 9
consolePanel = nil
consoleContentPanel = nil
consoleTabBar = nil
consoleTextEdit = nil
consoleToggleChat = nil
channels = nil
channelsWindow = nil
communicationWindow = nil
ownPrivateName = nil
messageHistory = {}
currentMessageIndex = 0
ignoreNpcMessages = false
defaultTab = nil
serverTab = nil
violationsChannelId = nil
violationWindow = nil
violationReportTab = nil
ignoredChannels = {}
filters = {}
reportWindow = nil
bugReportTab = nil
playerReportTab = nil
radioTabs = nil
floatingMode = false
local playerReportReasons = {
	{ text = tr("Rule violation / abuse"), reason = 11 },
	{ text = tr("Bug abuse"), reason = 12 },
	{ text = tr("Bot / hack / unofficial software"), reason = 13 },
	{ text = tr("Offensive behavior"), reason = 5 },
	{ text = tr("Spam or advertising"), reason = 6 },
	{ text = tr("Other"), reason = 20 }
}
local communicationSettings = {
	useWhiteList = true,
	useIgnoreList = true,
	allowVIPs = false,
	yelling = false,
	privateMessages = false,
	ignoredPlayers = {},
	whitelistedPlayers = {}
}

function init()
	connect(g_game, {
		onTalk = onTalk,
		onChannelList = onChannelList,
		onOpenChannel = onOpenChannel,
		onCloseChannel = onCloseChannel,
		onChannelEvent = onChannelEvent,
		onOpenPrivateChannel = onOpenPrivateChannel,
		onOpenOwnPrivateChannel = onOpenOwnPrivateChannel,
		onRuleViolationChannel = onRuleViolationChannel,
		onRuleViolationRemove = onRuleViolationRemove,
		onRuleViolationCancel = onRuleViolationCancel,
		onRuleViolationLock = onRuleViolationLock,
		onGameStart = online,
		onGameEnd = offline
	})

	local consoleUi = "console"
	if g_resources.getLayout() == "retro" then
		consoleUi = "/layouts/retro/modules/game_console/console.otui"
	end
	consolePanel = g_ui.loadUI(consoleUi, modules.game_interface.getBottomPanel())
	consoleTextEdit = consolePanel:recursiveGetChildById("consoleTextEdit")
	consoleContentPanel = consolePanel:recursiveGetChildById("consoleContentPanel")
	consoleTabBar = consolePanel:recursiveGetChildById("consoleTabBar")

	consoleTabBar:setContentWidget(consoleContentPanel)

	channels = {}
	consolePanel.onDragEnter = onDragEnter
	consolePanel.onDragLeave = onDragLeave
	consolePanel.onDragMove = onDragMove
	consoleTabBar.onDragEnter = onDragEnter
	consoleTabBar.onDragLeave = onDragLeave
	consoleTabBar.onDragMove = onDragMove

	function consolePanel:onKeyPress(keyCode, keyboardModifiers)
		if keyboardModifiers ~= KeyboardCtrlModifier or keyCode ~= KeyC then
			return false
		end

		local tab = consoleTabBar:getCurrentTab()

		if not tab then
			return false
		end

		local selection = tab.tabPanel:recursiveGetChildById("consoleBuffer").selectionText

		if not selection then
			return false
		end

		g_window.setClipboardText(selection)

		return true
	end

	g_keyboard.bindKeyPress("Shift+Up", function ()
		navigateMessageHistory(1)
	end, consolePanel)
	g_keyboard.bindKeyPress("Shift+Down", function ()
		navigateMessageHistory(-1)
	end, consolePanel)
	g_keyboard.bindKeyPress("Tab", function ()
		consoleTabBar:selectNextTab()
	end, consolePanel)
	g_keyboard.bindKeyPress("Shift+Tab", function ()
		consoleTabBar:selectPrevTab()
	end, consolePanel)
	g_keyboard.bindKeyDown("Enter", sendCurrentMessage, consolePanel)
	g_keyboard.bindKeyPress("Ctrl+A", function ()
		consoleTextEdit:clearText()
	end, consolePanel)
	consoleTabBar:setNavigation(consolePanel:getChildById("prevChannelButton"), consolePanel:getChildById("nextChannelButton"))

	consoleTabBar.onTabChange = onTabChange
	local gameRootPanel = modules.game_interface.getRootPanel()

	g_keyboard.bindKeyDown("Ctrl+O", g_game.requestChannels, gameRootPanel)
	g_keyboard.bindKeyDown("Ctrl+E", removeCurrentTab, gameRootPanel)
	g_keyboard.bindKeyDown("Ctrl+H", openHelp, gameRootPanel)
	g_keyboard.bindKeyDown("Ctrl+I", onClickIgnoreButton, gameRootPanel)

	consoleToggleChat = consolePanel:recursiveGetChildById("toggleChat")

	load()

	if g_game.isOnline() then
		online()
	end
end

function clearSelection(consoleBuffer)
	for _, label in pairs(consoleBuffer:getChildren()) do
		label:clearSelection()
	end

	consoleBuffer.selectionText = nil
	consoleBuffer.selection = nil
end

function selectAll(consoleBuffer)
	clearSelection(consoleBuffer)

	if consoleBuffer:getChildCount() > 0 then
		local text = {}

		for _, label in pairs(consoleBuffer:getChildren()) do
			label:selectAll()
			table.insert(text, label:getSelection())
		end

		consoleBuffer.selectionText = table.concat(text, "\n")
		consoleBuffer.selection = {
			first = consoleBuffer:getChildIndex(consoleBuffer:getFirstChild()),
			last = consoleBuffer:getChildIndex(consoleBuffer:getLastChild())
		}
	end
end

function toggleChat()
	if consoleToggleChat:isChecked() then
		disableChat()
	else
		enableChat()
	end
end

function enableChat(temporarily)
	if g_app.isMobile() then
		return
	end

	if consoleToggleChat:isChecked() then
		return consoleToggleChat:setChecked(false)
	end

	if not temporarily then
		modules.client_options.setOption("wsadWalking", false)
	end

	consoleTextEdit:setVisible(true)
	consoleTextEdit:setText("")
	consoleTextEdit:focus()

	local gameRootPanel = modules.game_interface.getRootPanel()

	g_keyboard.unbindKeyDown("Enter", gameRootPanel)

	if temporarily then
		local function quickFunc()
			if not g_game.isOnline() then
				return
			end

			g_keyboard.unbindKeyDown("Enter", gameRootPanel)
			g_keyboard.unbindKeyDown("Escape", gameRootPanel)
			disableChat(temporarily)
		end

		g_keyboard.bindKeyDown("Enter", quickFunc, gameRootPanel)
		g_keyboard.bindKeyDown("Escape", quickFunc, gameRootPanel)
	end

	modules.game_walking.disableWSAD()
	consoleToggleChat:setTooltip(tr("Disable chat mode, allow to walk using ASDW"))
end

function disableChat(temporarily)
	if g_app.isMobile() then
		return
	end

	if not consoleToggleChat:isChecked() then
		return consoleToggleChat:setChecked(true)
	end

	if not temporarily then
		modules.client_options.setOption("wsadWalking", true)
	end

	consoleTextEdit:setVisible(false)
	consoleTextEdit:setText("")

	local function quickFunc()
		if not g_game.isOnline() then
			return
		end

		if consoleToggleChat:isChecked() then
			consoleToggleChat:setChecked(false)
		end

		enableChat(true)
	end

	local gameRootPanel = modules.game_interface.getRootPanel()

	g_keyboard.bindKeyDown("Enter", quickFunc, gameRootPanel)
	modules.game_walking.enableWSAD()
	consoleToggleChat:setTooltip(tr("Enable chat mode"))
end

function isChatEnabled()
	return consoleTextEdit:isVisible()
end

function terminate()
	save()
	disconnect(g_game, {
		onTalk = onTalk,
		onChannelList = onChannelList,
		onOpenChannel = onOpenChannel,
		onOpenPrivateChannel = onOpenPrivateChannel,
		onOpenOwnPrivateChannel = onOpenPrivateChannel,
		onCloseChannel = onCloseChannel,
		onRuleViolationChannel = onRuleViolationChannel,
		onRuleViolationRemove = onRuleViolationRemove,
		onRuleViolationCancel = onRuleViolationCancel,
		onRuleViolationLock = onRuleViolationLock,
		onGameStart = online,
		onGameEnd = offline,
		onChannelEvent = onChannelEvent
	})

	if g_game.isOnline() then
		clear()
	end

	local gameRootPanel = modules.game_interface.getRootPanel()

	g_keyboard.unbindKeyDown("Ctrl+O", gameRootPanel)
	g_keyboard.unbindKeyDown("Ctrl+E", gameRootPanel)
	g_keyboard.unbindKeyDown("Ctrl+H", gameRootPanel)
	g_keyboard.unbindKeyDown("Ctrl+I", gameRootPanel)
	saveCommunicationSettings()

	if channelsWindow then
		channelsWindow:destroy()
	end

	if communicationWindow then
		communicationWindow:destroy()
	end

	if violationWindow then
		violationWindow:destroy()
	end

	if reportWindow then
		reportWindow:destroyChildren()
		reportWindow:destroy()
	end

	consoleTabBar = nil
	consoleContentPanel = nil
	consoleToggleChat = nil
	consoleTextEdit = nil

	consolePanel:destroy()

	consolePanel = nil
	ownPrivateName = nil
	Console = nil
end

function save()
	local settings = {
		messageHistory = messageHistory
	}

	g_settings.setNode("game_console", settings)
end

function load()
	local settings = g_settings.getNode("game_console")

	if settings then
		messageHistory = settings.messageHistory or {}
	end

	loadCommunicationSettings()
end

function onTabChange(tabBar, tab)
	if tab == defaultTab or tab == serverTab then
		consolePanel:recursiveGetChildById("closeChannelButton"):hide()
	else
		consolePanel:recursiveGetChildById("closeChannelButton"):show()
	end
end

function clear()
	local lastChannelsOpen = g_settings.getNode("lastChannelsOpen") or {}
	local char = g_game.getCharacterName()
	local savedChannels = {}
	local set = false

	for channelId, channelName in pairs(channels) do
		if type(channelId) == "number" then
			savedChannels[channelName] = channelId
			set = true
		end
	end

	if set then
		lastChannelsOpen[char] = savedChannels
	else
		lastChannelsOpen[char] = nil
	end

	g_settings.setNode("lastChannelsOpen", lastChannelsOpen)

	for _, channelName in pairs(channels) do
		local tab = consoleTabBar:getTab(channelName)

		consoleTabBar:removeTab(tab)
	end

	channels = {}

	consoleTabBar:removeTab(defaultTab)

	defaultTab = nil

	consoleTabBar:removeTab(serverTab)

	serverTab = nil
	local npcTab = consoleTabBar:getTab("NPCs")

	if npcTab then
		consoleTabBar:removeTab(npcTab)

		npcTab = nil
	end

	if violationReportTab then
		consoleTabBar:removeTab(violationReportTab)

		violationReportTab = nil
	end

	consoleTextEdit:clearText()

	if violationWindow then
		violationWindow:destroy()

		violationWindow = nil
	end

	if channelsWindow then
		channelsWindow:destroy()

		channelsWindow = nil
	end
end

function switchMode(newView)
	if newView then
		consolePanel:setImageColor("#ffffff88")
	else
		consolePanel:setImageColor("white")
	end
end

function onDragEnter(widget, pos)
	return floatingMode
end

function onDragMove(widget, pos, moved)
	if not floatingMode then
		return
	end

	return true
end

function onDragLeave(widget, pos)
	return floatingMode
end

function clearChannel(consoleTabBar)
	consoleTabBar:getCurrentTab().tabPanel:getChildById("consoleBuffer"):destroyChildren()
end

function setTextEditText(text)
	consoleTextEdit:setText(text)
	consoleTextEdit:setCursorPos(-1)
end

function openHelp()
	local helpChannel = 9

	if g_game.getClientVersion() <= 810 then
		helpChannel = 8
	end

	g_game.joinChannel(helpChannel)
end

function onDeveloperGet(protocol, msg)
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	player:unlockWalk()
end

function sendGetGroup()
	local msg = OutputMessage.create()

	msg:addU8(ClientOpcodes.ClientRequestGroup)

	local p = g_game.getProtocolGame()

	p:send(msg)
end

local function sendPlayerRuleViolationReport(targetName, reportReason, comment)
	local msg = OutputMessage.create()

	msg:addU8(0xF2)
	msg:addU8(2) -- REPORT_TYPE_BOT / player behavior report
	msg:addU8(reportReason)
	msg:addString(targetName)
	msg:addString(comment)

	local p = g_game.getProtocolGame()
	p:send(msg)
end

function openReportWindow()
	if reportWindow then
		return
	end

	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	ProtocolGame.registerOpcode(GameServerOpcodes.GameServerGroupGet, onDeveloperGet)

	reportWindow = g_ui.loadUI("reportwindow", rootWidget)
	bugReportTab = reportWindow:getChildById("bugReportTab")
	playerReportTab = reportWindow:getChildById("playerReportTab")
	local playerReasonBox = reportWindow:getChildById("playerReasonBox")
	if playerReasonBox then
		for _, reportReason in ipairs(playerReportReasons) do
			playerReasonBox:addOption(reportReason.text, reportReason.reason)
		end
	end
	radioTabs = UIRadioGroup.create()

	radioTabs:addWidget(bugReportTab)
	radioTabs:addWidget(playerReportTab)
	radioTabs:selectWidget(bugReportTab)

	radioTabs.onSelectionChange = onReportTypeChange

	function reportWindow.onEscape()
		player:unlockWalk()
		reportWindow:destroyChildren()
		reportWindow:destroy()

		reportWindow = nil

		ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerGroupGet)
	end

	player:lockWalk(100000)

	function reportWindow.onEnter()
		local textEdit = reportWindow:getChildById("text")

		if not textEdit then
			return
		end

		local text = textEdit:getText()

		if bugReportTab and bugReportTab:isChecked() then
			g_game.reportBug(text)
			modules.game_textmessage.displayGameMessage(tr("Bug report sent."))
		elseif playerReportTab and playerReportTab:isChecked() then
			local playerNameEdit = reportWindow:getChildById("playerNameText")
			local playerReasonBox = reportWindow:getChildById("playerReasonBox")
			local targetName = playerNameEdit and playerNameEdit:getText() or ""
			local reasonOption = playerReasonBox and playerReasonBox:getCurrentOption()
			local reportReason = reasonOption and reasonOption.data or 11

			if targetName == "" then
				displayErrorBox(tr("Error"), tr("You must enter a player name."))
				return
			end

			if text == "" then
				displayErrorBox(tr("Error"), tr("You must enter a comment."))
				return
			end

			sendPlayerRuleViolationReport(targetName, reportReason, text)
			modules.game_textmessage.displayGameMessage(tr("Player report sent."))
		end

		player:unlockWalk()
		reportWindow:destroyChildren()
		reportWindow:destroy()

		reportWindow = nil

		ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerGroupGet)
	end

	sendGetGroup()
end

function onReportTypeChange(radioTabs, selected, deselected)
	selected:setOn(true)
	deselected:setOn(false)
end

function addTab(name, focus)
	local tab = getTab(name)

	if tab then
		if not focus then
			focus = true
		end
	else
		local newname = name

		if newname:len() > 10 then
			newname = name:sub(1, 10)
			newname = newname .. "..."
		end

		tab = consoleTabBar:addTab(name, nil, processChannelTabMenu)

		tab:setWidth(math.max(90, tab:getTextSize().width + 8))
	end

	if focus then
		consoleTabBar:selectTab(tab)
	end

	return tab
end

function removeTab(tab)
	if type(tab) == "string" then
		tab = consoleTabBar:getTab(tab)
	end

	if tab == defaultTab or tab == serverTab then
		return
	end

	if tab == violationReportTab then
		g_game.cancelRuleViolation()

		violationReportTab = nil
	elseif tab.violationChatName then
		g_game.closeRuleViolation(tab.violationChatName)
	elseif tab.channelId then
		for k, v in pairs(channels) do
			if k == tab.channelId then
				channels[k] = nil
			end
		end

		g_game.leaveChannel(tab.channelId)
	elseif tab:getText() == "NPCs" then
		g_game.closeNpcChannel()
	end

	if getCurrentTab() == tab then
		consoleTabBar:selectTab(defaultTab)
	end

	consoleTabBar:removeTab(tab)
end

function removeCurrentTab()
	removeTab(consoleTabBar:getCurrentTab())
end

function getTab(name)
	return consoleTabBar:getTab(name)
end

function getChannelTab(channelId)
	local channel = channels[channelId]

	if channel then
		return getTab(channel)
	end

	return nil
end

function getRuleViolationsTab()
	if violationsChannelId then
		return getChannelTab(violationsChannelId)
	end

	return nil
end

function getCurrentTab()
	return consoleTabBar:getCurrentTab()
end

function addChannel(name, id)
	channels[id] = name
	local focus = not table.find(ignoredChannels, id)
	local tab = addTab(name, focus)
	tab.channelId = id

	return tab
end

function addPrivateChannel(receiver)
	channels[receiver] = receiver

	return addTab(receiver, true)
end

function addPrivateText(text, speaktype, name, isPrivateCommand, creatureName)
	local focus = false

	if speaktype.npcChat then
		name = "NPCs"
		focus = true
	end

	local privateTab = getTab(name)

	if privateTab == nil then
		if modules.client_options.getOption("showPrivateMessagesInConsole") and not focus or isPrivateCommand and not privateTab then
			privateTab = defaultTab
		else
			privateTab = addTab(name, focus)
			channels[name] = name
		end

		privateTab.npcChat = speaktype.npcChat
	elseif focus then
		consoleTabBar:selectTab(privateTab)
	end

	addTabText(text, speaktype, privateTab, creatureName)
end

function addText(text, speaktype, tabName, creatureName)
	local tab = getTab(tabName)

	if tab ~= nil then
		addTabText(text, speaktype, tab, creatureName)
	end
end

function getHighlightedText(text)
	local tmpData = {}

	repeat
		local tmp = {
			string.find(text, "{([^}]+)}", tmpData[#tmpData - 1])
		}

		for _, v in pairs(tmp) do
			table.insert(tmpData, v)
		end
	until not string.find(text, "{([^}]+)}", tmpData[#tmpData - 1])

	return tmpData
end

function getNewHighlightedText(text, color, highlightColor)
	local tmpData = {}

	for i, part in ipairs(text:split("{")) do
		if i == 1 then
			table.insert(tmpData, part)
			table.insert(tmpData, color)
		else
			for j, part2 in ipairs(part:split("}")) do
				if j == 1 then
					table.insert(tmpData, part2)
					table.insert(tmpData, highlightColor)
				else
					table.insert(tmpData, part2)
					table.insert(tmpData, color)
				end
			end
		end
	end

	return tmpData
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

function addTabText(text, speaktype, tab, creatureName)
	if not tab or tab.locked or not text or #text == 0 then
		return
	end

	if modules.client_options.getOption("showTimestampsInConsole") then
		text = os.date("%H:%M") .. " " .. text
	end

	local panel = consoleTabBar:getTabPanel(tab)
	local consoleBuffer = panel:getChildById("consoleBuffer")
	local label = nil

	if MAX_LINES < consoleBuffer:getChildCount() then
		label = consoleBuffer:getFirstChild()

		consoleBuffer:moveChildToIndex(label, consoleBuffer:getChildCount())
	end

	label = label or g_ui.createWidget("ConsoleLabel", consoleBuffer)

	label:setId("consoleLabel" .. consoleBuffer:getChildCount())
	label:setText(text)
	label:setColor(speaktype.color)
	consoleTabBar:blinkTab(tab)

	local checkBBData = true

	if speaktype.npcChat and (g_game.getCharacterName() ~= creatureName or g_game.getCharacterName() == "Account Manager") then
		local highlightData = getNewHighlightedText(text, speaktype.color, "#1f9ffe")

		if #highlightData > 2 then
			label:setColoredText(highlightData)

			checkBBData = false
		end
	end

	if checkBBData then
		local coloredData = getBBColorData(text, speaktype.color)

		if #coloredData > 0 then
			label:setColoredText(coloredData)
		end
	end

	label.name = creatureName

	function consoleBuffer:onMouseRelease(mousePos, mouseButton)
		processMessageMenu(mousePos, mouseButton, nil, nil, nil, tab)
	end

	function label:onMouseRelease(mousePos, mouseButton)
		processMessageMenu(mousePos, mouseButton, creatureName, text, self, tab)
	end

	function label:onMousePress(mousePos, button)
		if button == MouseLeftButton then
			clearSelection(consoleBuffer)
		end
	end

	function label:onDragEnter(mousePos)
		clearSelection(consoleBuffer)

		return true
	end

	function label:onDragLeave(droppedWidget, mousePos)
		local text = {}

		for selectionChild = consoleBuffer.selection.first, consoleBuffer.selection.last do
			local label = self:getParent():getChildByIndex(selectionChild)

			table.insert(text, label:getSelection())
		end

		consoleBuffer.selectionText = table.concat(text, "\n")

		return true
	end

	function label:onDragMove(mousePos, mouseMoved)
		local parent = self:getParent()
		local parentRect = parent:getPaddingRect()
		local selfIndex = parent:getChildIndex(self)
		local child = parent:getChildByPos(mousePos)

		if not child then
			if mousePos.y < self:getY() then
				for index = selfIndex - 1, 1, -1 do
					local label = parent:getChildByIndex(index)

					if parentRect.y < label:getY() + label:getHeight() then
						if label:getY() <= mousePos.y and mousePos.y <= label:getY() + label:getHeight() or index == 1 then
							child = label

							break
						end
					else
						child = parent:getChildByIndex(index + 1)

						break
					end
				end
			elseif mousePos.y > self:getY() + self:getHeight() then
				for index = selfIndex + 1, parent:getChildCount() do
					local label = parent:getChildByIndex(index)

					if label:getY() < parentRect.y + parentRect.height then
						if label:getY() <= mousePos.y and mousePos.y <= label:getY() + label:getHeight() or index == parent:getChildCount() then
							child = label

							break
						end
					else
						child = parent:getChildByIndex(index - 1)

						break
					end
				end
			else
				child = self
			end
		end

		if not child then
			return false
		end

		local childIndex = parent:getChildIndex(child)

		clearSelection(consoleBuffer)

		local textBegin = self:getTextPos(self:getLastClickPosition())
		local textPos = self:getTextPos(mousePos)

		self:setSelection(textBegin, textPos)

		consoleBuffer.selection = {
			first = math.min(selfIndex, childIndex),
			last = math.max(selfIndex, childIndex)
		}

		if child ~= self then
			for selectionChild = consoleBuffer.selection.first + 1, consoleBuffer.selection.last - 1 do
				parent:getChildByIndex(selectionChild):selectAll()
			end

			local textPos = child:getTextPos(mousePos)

			if selfIndex < childIndex then
				child:setSelection(0, textPos)
			else
				child:setSelection(string.len(child:getText()), textPos)
			end
		end

		return true
	end
end

function removeTabLabelByName(tab, name)
	local panel = consoleTabBar:getTabPanel(tab)
	local consoleBuffer = panel:getChildById("consoleBuffer")

	for _, label in pairs(consoleBuffer:getChildren()) do
		if label.name == name then
			label:destroy()
		end
	end
end

function processChannelTabMenu(tab, mousePos, mouseButton)
	local menu = g_ui.createWidget("PopupMenu")

	menu:setGameMenu(true)

	local worldName = g_game.getWorldName()
	local characterName = g_game.getCharacterName()
	channelName = tab:getText()

	if tab ~= defaultTab and tab ~= serverTab then
		menu:addOption(tr("Close"), function ()
			removeTab(channelName)
		end)
		menu:addSeparator()
	end

	if consoleTabBar:getCurrentTab() == tab then
		menu:addOption(tr("Clear Messages"), function ()
			clearChannel(consoleTabBar)
		end)
		menu:addOption(tr("Save Messages"), function ()
			local panel = consoleTabBar:getTabPanel(tab)
			local consoleBuffer = panel:getChildById("consoleBuffer")
			local lines = {}

			for _, label in pairs(consoleBuffer:getChildren()) do
				table.insert(lines, label:getText())
			end

			local filename = worldName .. " - " .. characterName .. " - " .. channelName .. ".txt"
			local filepath = "/user_dir/" .. filename

			table.insert(lines, 1, os.date("\nChannel saved at %a %b %d %H:%M:%S %Y"))

			if g_resources.fileExists(filepath) then
				table.insert(lines, 1, protectedcall(g_resources.readFileContents, filepath) or "")
			end

			g_resources.writeFileContents(filepath, table.concat(lines, "\n"))
			modules.game_textmessage.displayStatusMessage(tr("Channel appended to %s", filename))
		end)
	end

	menu:display(mousePos)
end

function processMessageMenu(mousePos, mouseButton, creatureName, text, label, tab)
	if mouseButton == MouseRightButton then
		local menu = g_ui.createWidget("PopupMenu")

		menu:setGameMenu(true)

		if creatureName and #creatureName > 0 then
			if creatureName ~= g_game.getCharacterName() then
				menu:addOption(tr("Message to " .. creatureName), function ()
					g_game.openPrivateChannel(creatureName)
				end)

				if not g_game.getLocalPlayer():hasVip(creatureName) then
					menu:addOption(tr("Add to VIP list"), function ()
						g_game.addVip(creatureName)
					end)
				end

				if modules.game_console.getOwnPrivateTab() then
					menu:addSeparator()
					menu:addOption(tr("Invite to private chat"), function ()
						g_game.inviteToOwnChannel(creatureName)
					end)
					menu:addOption(tr("Exclude from private chat"), function ()
						g_game.excludeFromOwnChannel(creatureName)
					end)
				end

				if isIgnored(creatureName) then
					menu:addOption(tr("Unignore") .. " " .. creatureName, function ()
						removeIgnoredPlayer(creatureName)
					end)
				else
					menu:addOption(tr("Ignore") .. " " .. creatureName, function ()
						addIgnoredPlayer(creatureName)
					end)
				end

				menu:addSeparator()
			end

			if modules.game_ruleviolation.hasWindowAccess() then
				menu:addOption(tr("Rule Violation"), function ()
					modules.game_ruleviolation.show(creatureName, text:match(".+%:%s(.+)"))
				end)
				menu:addSeparator()
			end

			menu:addOption(tr("Copy name"), function ()
				g_window.setClipboardText(creatureName)
			end)
		end

		local selection = tab.tabPanel:getChildById("consoleBuffer").selectionText

		if selection and #selection > 0 then
			menu:addOption(tr("Copy"), function ()
				g_window.setClipboardText(selection)
			end, "(Ctrl+C)")
		end

		if text then
			menu:addOption(tr("Copy message"), function ()
				g_window.setClipboardText(text)
			end)
		end

		menu:addOption(tr("Select all"), function ()
			selectAll(tab.tabPanel:getChildById("consoleBuffer"))
		end)

		if tab.violations and creatureName then
			menu:addSeparator()
			menu:addOption(tr("Process") .. " " .. creatureName, function ()
				processViolation(creatureName, text)
			end)
			menu:addOption(tr("Remove") .. " " .. creatureName, function ()
				g_game.closeRuleViolation(creatureName)
			end)
		end

		menu:display(mousePos)
	end
end

function sendCurrentMessage()
	local message = consoleTextEdit:getText()

	if #message == 0 then
		return
	end

	if not isChatEnabled() then
		return
	end

	consoleTextEdit:clearText()
	sendMessage(message)
end

function addFilter(filter)
	table.insert(filters, filter)
end

function removeFilter(filter)
	table.removevalue(filters, filter)
end

function sendMessage(message, tab)
	local tab = tab or getCurrentTab()

	if not tab then
		return
	end

	for k, func in pairs(filters) do
		if func(message) then
			return true
		end
	end

	local name = tab:getText()

	if tab == serverTab or tab == getRuleViolationsTab() then
		tab = defaultTab
		name = defaultTab:getText()
	end

	local channel = tab.channelId
	local originalMessage = message
	local chatCommandSayMode, chatCommandPrivate, chatCommandPrivateReady, chatCommandMessage = nil
	chatCommandMessage = message:match("^%#[y|Y] (.*)")

	if chatCommandMessage ~= nil then
		chatCommandSayMode = "yell"
		channel = 0
		message = chatCommandMessage
	end

	chatCommandMessage = message:match("^%#[w|W] (.*)")

	if chatCommandMessage ~= nil then
		chatCommandSayMode = "whisper"
		message = chatCommandMessage
		channel = 0
	end

	chatCommandMessage = message:match("^%#[s|S] (.*)")

	if chatCommandMessage ~= nil then
		chatCommandSayMode = "say"
		message = chatCommandMessage
		channel = 0
	end

	chatCommandMessage = message:match("^%#[c|C] (.*)")

	if chatCommandMessage ~= nil then
		chatCommandSayMode = "channelRed"
		message = chatCommandMessage
	end

	chatCommandMessage = message:match("^%#[b|B] (.*)")

	if chatCommandMessage ~= nil then
		chatCommandSayMode = "broadcast"
		message = chatCommandMessage
		channel = 0
	end

	local findIni, findEnd, chatCommandInitial, chatCommandPrivate, chatCommandEnd, chatCommandMessage = message:find("([%*%@])(.+)([%*%@])(.*)")

	if findIni ~= nil and findIni == 1 and chatCommandInitial == chatCommandEnd then
		chatCommandPrivateRepeat = false

		if chatCommandInitial == "*" then
			setTextEditText("*" .. chatCommandPrivate .. "* ")
		end

		message = chatCommandMessage:trim()
		chatCommandPrivateReady = true
	end

	message = message:gsub("^(%s*)(.*)", "%2")

	if #message == 0 then
		return
	end

	currentMessageIndex = 0

	if #messageHistory == 0 or messageHistory[#messageHistory] ~= originalMessage then
		table.insert(messageHistory, originalMessage)

		if MAX_HISTORY < #messageHistory then
			table.remove(messageHistory, 1)
		end
	end

	local speaktypedesc = nil

	if (channel or tab == defaultTab) and not chatCommandPrivateReady then
		if tab == defaultTab then
			speaktypedesc = chatCommandSayMode or SayModes[consolePanel:recursiveGetChildById("sayModeButton").sayMode].speakTypeDesc

			if speaktypedesc ~= "say" then
				sayModeChange(2)
			end
		else
			speaktypedesc = chatCommandSayMode or "channelYellow"
		end

		g_game.talkChannel(SpeakTypesSettings[speaktypedesc].speakType, channel, message)

		return
	else
		local isPrivateCommand = false
		local priv = true
		local tabname = name
		local dontAdd = false

		if chatCommandPrivateReady then
			speaktypedesc = "privatePlayerToPlayer"
			name = chatCommandPrivate
			isPrivateCommand = true
		elseif tab.npcChat then
			speaktypedesc = "privatePlayerToNpc"
		elseif tab == violationReportTab then
			if violationReportTab.locked then
				modules.game_textmessage.displayFailureMessage("Wait for a gamemaster reply.")

				dontAdd = true
			else
				speaktypedesc = "rvrContinue"
				tabname = tr("Report Rule") .. "..."
			end
		elseif tab.violationChatName then
			speaktypedesc = "rvrAnswerTo"
			name = tab.violationChatName
			tabname = tab.violationChatName .. "'..."
		else
			speaktypedesc = "privatePlayerToPlayer"
		end

		local speaktype = SpeakTypesSettings[speaktypedesc]
		local player = g_game.getLocalPlayer()

		g_game.talkPrivate(speaktype.speakType, name, message)

		if not dontAdd then
			message = applyMessagePrefixies(g_game.getCharacterName(), player:getLevel(), message)

			addPrivateText(message, speaktype, tabname, isPrivateCommand, g_game.getCharacterName())
		end
	end
end

function sayModeChange(sayMode)
	local buttom = consolePanel:recursiveGetChildById("sayModeButton")

	if sayMode == nil then
		sayMode = buttom.sayMode + 1
	end

	if sayMode > #SayModes then
		sayMode = 1
	end

	buttom:setIcon(SayModes[sayMode].icon)

	buttom.sayMode = sayMode
end

function getOwnPrivateTab()
	if not ownPrivateName then
		return
	end

	return getTab(ownPrivateName)
end

function setIgnoreNpcMessages(ignore)
	ignoreNpcMessages = ignore
end

function navigateMessageHistory(step)
	if not isChatEnabled() then
		return
	end

	local numCommands = #messageHistory

	if numCommands > 0 then
		currentMessageIndex = math.min(math.max(currentMessageIndex + step, 0), numCommands)

		if currentMessageIndex > 0 then
			local command = messageHistory[numCommands - currentMessageIndex + 1]

			setTextEditText(command)
		else
			consoleTextEdit:clearText()
		end
	end

	local player = g_game.getLocalPlayer()

	if player then
		player:lockWalk(200)
	end
end

function applyEmoticons(message)
	for match in message:gmatch("#(%a+)") do
		local emoticonChar = emoticonChars[match]

		if emoticonChar then
			message = message:gsub("#" .. match, "[emote]" .. emoticonChar .. "[/emote]")
		end
	end

	return message
end

function applyMessagePrefixies(name, level, message)
	message = applyEmoticons(message)

	if name and #name > 0 then
		if modules.client_options.getOption("showLevelsInConsole") and level > 0 then
			message = name .. " [" .. level .. "]: " .. message
		else
			message = name .. ": " .. message
		end
	end

	return message
end

function onTalk(name, level, mode, message, channelId, creaturePos)
	message = applyEmoticons(message)

	if mode == MessageModes.GamemasterBroadcast then
		modules.game_textmessage.displayBroadcastMessage(name .. ": " .. message)

		return
	end

	local isNpcMode = mode == MessageModes.NpcFromStartBlock or mode == MessageModes.NpcFrom

	if ignoreNpcMessages and isNpcMode then
		return
	end

	speaktype = SpeakTypes[mode]

	if not speaktype then
		perror("unhandled onTalk message mode " .. mode .. ": " .. message)

		return
	end

	local localPlayer = g_game.getLocalPlayer()

	if name ~= g_game.getCharacterName() and isUsingIgnoreList() and not isUsingWhiteList() or isUsingWhiteList() and not isWhitelisted(name) and (not isAllowingVIPs() or not localPlayer:hasVip(name)) then
		if mode == MessageModes.Yell and isIgnoringYelling() then
			return
		elseif speaktype.private and isIgnoringPrivate() and not isNpcMode then
			return
		elseif isIgnored(name) then
			return
		end
	end

	if mode == MessageModes.RVRChannel then
		channelId = violationsChannelId
	end

	if (mode == MessageModes.Say or mode == MessageModes.Whisper or mode == MessageModes.Yell or mode == MessageModes.Spell or mode == MessageModes.MonsterSay or mode == MessageModes.MonsterYell or mode == MessageModes.NpcFrom or mode == MessageModes.BarkLow or mode == MessageModes.BarkLoud or mode == MessageModes.NpcFromStartBlock) and creaturePos then
		local staticText = StaticText.create()
		local staticMessage = message

		if isNpcMode then
			local highlightData = getNewHighlightedText(staticMessage, speaktype.color, "#1f9ffe")

			if #highlightData > 2 then
				staticText:addColoredMessage(name, mode, highlightData)
			else
				staticText:addMessage(name, mode, staticMessage)
			end

			staticText:setColor(speaktype.color)
		else
			local coloredData = getBBColorData(staticMessage, speaktype.color)

			if #coloredData > 0 then
				staticText:addColoredMessage(name, mode, coloredData)
			else
				staticText:addMessage(name, mode, staticMessage)
			end
		end

		g_map.addThing(staticText, creaturePos, -1)
	end

	local defaultMessage = mode <= 3 and true or false

	if speaktype == SpeakTypesSettings.none then
		return
	end

	if speaktype.hideInConsole then
		return
	end

	local composedMessage = applyMessagePrefixies(name, level, message)

	if mode == MessageModes.RVRAnswer then
		violationReportTab.locked = false

		addTabText(composedMessage, speaktype, violationReportTab, name)
	elseif mode == MessageModes.RVRContinue then
		addText(composedMessage, speaktype, name .. "'...", name)
	elseif speaktype.private then
		addPrivateText(composedMessage, speaktype, name, false, name)

		if modules.client_options.getOption("showPrivateMessagesOnScreen") and speaktype ~= SpeakTypesSettings.privateNpcToPlayer then
			modules.game_textmessage.displayPrivateMessage(name .. ":\n" .. message)
		end
	else
		local channel = tr("Default")

		if not defaultMessage then
			channel = channels[channelId]
		end

		if not channel and channelId == 7 then
			channel = tr("Server Log")
		end

		if channel then
			addText(composedMessage, speaktype, channel, name)
		else
			pwarning("message in channel id " .. channelId .. " which is unknown, this is a server bug, relogin if you want to see messages in this channel")
		end
	end
end

function onOpenChannel(channelId, channelName)
	addChannel(channelName, channelId)
end

function onOpenPrivateChannel(receiver)
	addPrivateChannel(receiver)
end

function onOpenOwnPrivateChannel(channelId, channelName)
	local privateTab = getTab(channelName)

	if privateTab == nil then
		addChannel(channelName, channelId)
	end

	ownPrivateName = channelName
end

function onCloseChannel(channelId)
	local channel = channels[channelId]

	if channel then
		local tab = getTab(channel)

		if tab then
			consoleTabBar:removeTab(tab)
		end

		for k, v in pairs(channels) do
			if k == tab.channelId then
				channels[k] = nil
			end
		end
	end
end

function processViolation(name, text)
	local tabname = name .. "'..."
	local tab = addTab(tabname, true)
	channels[tabname] = tabname
	tab.violationChatName = name

	g_game.openRuleViolation(name)
	addTabText(text, SpeakTypesSettings.say, tab, name)
end

function onRuleViolationChannel(channelId)
	violationsChannelId = channelId
	local tab = addChannel(tr("Rule Violations"), channelId)
	tab.violations = true
end

function onRuleViolationRemove(name)
	local tab = getRuleViolationsTab()

	if not tab then
		return
	end

	removeTabLabelByName(tab, name)
end

function onRuleViolationCancel(name)
	local tab = getTab(name .. "'...")

	if not tab then
		return
	end

	addTabText(tr("%s has finished the request", name) .. ".", SpeakTypesSettings.privateRed, tab)

	tab.locked = true
end

function onRuleViolationLock()
	if not violationReportTab then
		return
	end

	violationReportTab.locked = false

	addTabText(tr("Your request has been closed") .. ".", SpeakTypesSettings.privateRed, violationReportTab)

	violationReportTab.locked = true
end

function doChannelListSubmit()
	local channelListPanel = channelsWindow:getChildById("channelList")
	local openPrivateChannelWith = channelsWindow:getChildById("openPrivateChannelWith"):getText()

	if openPrivateChannelWith ~= "" then
		if openPrivateChannelWith:lower() ~= g_game.getCharacterName():lower() then
			g_game.openPrivateChannel(openPrivateChannelWith)
		else
			modules.game_textmessage.displayFailureMessage("You cannot create a private chat channel with yourself.")
		end
	else
		local selectedChannelLabel = channelListPanel:getFocusedChild()

		if not selectedChannelLabel then
			return
		end

		if selectedChannelLabel.channelId == 65535 then
			g_game.openOwnChannel()
		else
			g_game.leaveChannel(selectedChannelLabel.channelId)
			g_game.joinChannel(selectedChannelLabel.channelId)
		end
	end

	channelsWindow:destroy()
end

function onChannelList(channelList)
	if channelsWindow then
		channelsWindow:destroy()
	end

	channelsWindow = g_ui.displayUI("channelswindow")
	local channelListPanel = channelsWindow:getChildById("channelList")
	channelsWindow.onEnter = doChannelListSubmit

	function channelsWindow.onDestroy()
		channelsWindow = nil
	end

	g_keyboard.bindKeyPress("Down", function ()
		channelListPanel:focusNextChild(KeyboardFocusReason)
	end, channelsWindow)
	g_keyboard.bindKeyPress("Up", function ()
		channelListPanel:focusPreviousChild(KeyboardFocusReason)
	end, channelsWindow)

	for k, v in pairs(channelList) do
		local channelId = v[1]
		local channelName = v[2]

		if #channelName > 0 then
			local label = g_ui.createWidget("ChannelListLabel", channelListPanel)
			label.channelId = channelId

			label:setText(channelName)
			label:setPhantom(false)

			label.onDoubleClick = doChannelListSubmit
		end
	end
end

function loadCommunicationSettings()
	communicationSettings.whitelistedPlayers = {}
	communicationSettings.ignoredPlayers = {}
	local ignoreNode = g_settings.getNode("IgnorePlayers")

	if ignoreNode then
		for _, player in pairs(ignoreNode) do
			table.insert(communicationSettings.ignoredPlayers, player)
		end
	end

	local whitelistNode = g_settings.getNode("WhitelistedPlayers")

	if whitelistNode then
		for _, player in pairs(whitelistNode) do
			table.insert(communicationSettings.whitelistedPlayers, player)
		end
	end

	communicationSettings.useIgnoreList = g_settings.getBoolean("UseIgnoreList")
	communicationSettings.useWhiteList = g_settings.getBoolean("UseWhiteList")
	communicationSettings.privateMessages = g_settings.getBoolean("IgnorePrivateMessages")
	communicationSettings.yelling = g_settings.getBoolean("IgnoreYelling")
	communicationSettings.allowVIPs = g_settings.getBoolean("AllowVIPs")
end

function saveCommunicationSettings()
	local tmpIgnoreList = {}
	local ignoredPlayers = getIgnoredPlayers()

	for i = 1, #ignoredPlayers do
		table.insert(tmpIgnoreList, ignoredPlayers[i])
	end

	local tmpWhiteList = {}
	local whitelistedPlayers = getWhitelistedPlayers()

	for i = 1, #whitelistedPlayers do
		table.insert(tmpWhiteList, whitelistedPlayers[i])
	end

	g_settings.set("UseIgnoreList", communicationSettings.useIgnoreList)
	g_settings.set("UseWhiteList", communicationSettings.useWhiteList)
	g_settings.set("IgnorePrivateMessages", communicationSettings.privateMessages)
	g_settings.set("IgnoreYelling", communicationSettings.yelling)
	g_settings.setNode("IgnorePlayers", tmpIgnoreList)
	g_settings.setNode("WhitelistedPlayers", tmpWhiteList)
end

function getIgnoredPlayers()
	return communicationSettings.ignoredPlayers
end

function getWhitelistedPlayers()
	return communicationSettings.whitelistedPlayers
end

function isUsingIgnoreList()
	return communicationSettings.useIgnoreList
end

function isUsingWhiteList()
	return communicationSettings.useWhiteList
end

function isIgnored(name)
	return table.find(communicationSettings.ignoredPlayers, name, true)
end

function addIgnoredPlayer(name)
	if isIgnored(name) then
		return
	end

	table.insert(communicationSettings.ignoredPlayers, name)

	communicationSettings.useIgnoreList = true
end

function removeIgnoredPlayer(name)
	table.removevalue(communicationSettings.ignoredPlayers, name)
end

function isWhitelisted(name)
	return table.find(communicationSettings.whitelistedPlayers, name, true)
end

function addWhitelistedPlayer(name)
	if isWhitelisted(name) then
		return
	end

	table.insert(communicationSettings.whitelistedPlayers, name)
end

function removeWhitelistedPlayer(name)
	table.removevalue(communicationSettings.whitelistedPlayers, name)
end

function isIgnoringPrivate()
	return communicationSettings.privateMessages
end

function isIgnoringYelling()
	return communicationSettings.yelling
end

function isAllowingVIPs()
	return communicationSettings.allowVIPs
end

function onClickIgnoreButton()
	if communicationWindow then
		return
	end

	communicationWindow = g_ui.displayUI("communicationwindow")
	local ignoreListPanel = communicationWindow:getChildById("ignoreList")
	local whiteListPanel = communicationWindow:getChildById("whiteList")

	function communicationWindow.onDestroy()
		communicationWindow = nil
	end

	local useIgnoreListBox = communicationWindow:recursiveGetChildById("checkboxUseIgnoreList")

	useIgnoreListBox:setChecked(communicationSettings.useIgnoreList)

	local useWhiteListBox = communicationWindow:recursiveGetChildById("checkboxUseWhiteList")

	useWhiteListBox:setChecked(communicationSettings.useWhiteList)

	local removeIgnoreButton = communicationWindow:getChildById("buttonIgnoreRemove")

	removeIgnoreButton:disable()

	function ignoreListPanel.onChildFocusChange()
		removeIgnoreButton:enable()
	end

	function removeIgnoreButton.onClick()
		local selection = ignoreListPanel:getFocusedChild()

		if selection then
			ignoreListPanel:removeChild(selection)
			selection:destroy()
		end

		removeIgnoreButton:disable()
	end

	local removeWhitelistButton = communicationWindow:getChildById("buttonWhitelistRemove")

	removeWhitelistButton:disable()

	function whiteListPanel.onChildFocusChange()
		removeWhitelistButton:enable()
	end

	function removeWhitelistButton.onClick()
		local selection = whiteListPanel:getFocusedChild()

		if selection then
			whiteListPanel:removeChild(selection)
			selection:destroy()
		end

		removeWhitelistButton:disable()
	end

	local newlyIgnoredPlayers = {}
	local addIgnoreName = communicationWindow:getChildById("ignoreNameEdit")
	local addIgnoreButton = communicationWindow:getChildById("buttonIgnoreAdd")

	local function addIgnoreFunction()
		local newEntry = addIgnoreName:getText()

		if newEntry == "" then
			return
		end

		if table.find(getIgnoredPlayers(), newEntry) then
			return
		end

		if table.find(newlyIgnoredPlayers, newEntry) then
			return
		end

		local label = g_ui.createWidget("IgnoreListLabel", ignoreListPanel)

		label:setText(newEntry)
		table.insert(newlyIgnoredPlayers, newEntry)
		addIgnoreName:setText("")
	end

	addIgnoreButton.onClick = addIgnoreFunction
	local newlyWhitelistedPlayers = {}
	local addWhitelistName = communicationWindow:getChildById("whitelistNameEdit")
	local addWhitelistButton = communicationWindow:getChildById("buttonWhitelistAdd")

	local function addWhitelistFunction()
		local newEntry = addWhitelistName:getText()

		if newEntry == "" then
			return
		end

		if table.find(getWhitelistedPlayers(), newEntry) then
			return
		end

		if table.find(newlyWhitelistedPlayers, newEntry) then
			return
		end

		local label = g_ui.createWidget("WhiteListLabel", whiteListPanel)

		label:setText(newEntry)
		table.insert(newlyWhitelistedPlayers, newEntry)
		addWhitelistName:setText("")
	end

	addWhitelistButton.onClick = addWhitelistFunction

	function communicationWindow.onEnter()
		if addWhitelistName:isFocused() then
			addWhitelistFunction()
		elseif addIgnoreName:isFocused() then
			addIgnoreFunction()
		end
	end

	local ignorePrivateMessageBox = communicationWindow:recursiveGetChildById("checkboxIgnorePrivateMessages")

	ignorePrivateMessageBox:setChecked(communicationSettings.privateMessages)

	local ignoreYellingBox = communicationWindow:recursiveGetChildById("checkboxIgnoreYelling")

	ignoreYellingBox:setChecked(communicationSettings.yelling)

	local allowVIPsBox = communicationWindow:recursiveGetChildById("checkboxAllowVIPs")

	allowVIPsBox:setChecked(communicationSettings.allowVIPs)

	local saveButton = communicationWindow:recursiveGetChildById("buttonSave")

	function saveButton.onClick()
		communicationSettings.ignoredPlayers = {}

		for i = 1, ignoreListPanel:getChildCount() do
			addIgnoredPlayer(ignoreListPanel:getChildByIndex(i):getText())
		end

		communicationSettings.whitelistedPlayers = {}

		for i = 1, whiteListPanel:getChildCount() do
			addWhitelistedPlayer(whiteListPanel:getChildByIndex(i):getText())
		end

		communicationSettings.useIgnoreList = useIgnoreListBox:isChecked()
		communicationSettings.useWhiteList = useWhiteListBox:isChecked()
		communicationSettings.yelling = ignoreYellingBox:isChecked()
		communicationSettings.privateMessages = ignorePrivateMessageBox:isChecked()
		communicationSettings.allowVIPs = allowVIPsBox:isChecked()

		communicationWindow:destroy()
	end

	local cancelButton = communicationWindow:recursiveGetChildById("buttonCancel")

	function cancelButton.onClick()
		communicationWindow:destroy()
	end

	local ignoredPlayers = getIgnoredPlayers()

	for i = 1, #ignoredPlayers do
		local label = g_ui.createWidget("IgnoreListLabel", ignoreListPanel)

		label:setText(ignoredPlayers[i])
	end

	local whitelistedPlayers = getWhitelistedPlayers()

	for i = 1, #whitelistedPlayers do
		local label = g_ui.createWidget("WhiteListLabel", whiteListPanel)

		label:setText(whitelistedPlayers[i])
	end
end

function online()
	defaultTab = addTab(tr("Default"), true)
	serverTab = addTab(tr("Server Log"), false)

	if g_game.getClientVersion() >= 820 then
		local tab = addTab("NPCs", false)
		tab.npcChat = true
	end

	if g_game.getClientVersion() < 862 then
		local gameRootPanel = modules.game_interface.getRootPanel()

		g_keyboard.bindKeyDown("Ctrl+Z", openReportWindow, gameRootPanel)
	end

	local lastChannelsOpen = g_settings.getNode("lastChannelsOpen")

	if lastChannelsOpen then
		local savedChannels = lastChannelsOpen[g_game.getCharacterName()]

		if savedChannels then
			for channelName, channelId in pairs(savedChannels) do
				channelId = tonumber(channelId)

				if channelId ~= -1 and channelId < 100 and not table.find(channels, channelId) then
					g_game.joinChannel(channelId)
					table.insert(ignoredChannels, channelId)
				end
			end
		end
	end

	scheduleEvent(function ()
		consoleTabBar:selectTab(defaultTab)
	end, 500)
	scheduleEvent(function ()
		ignoredChannels = {}
	end, 3000)
end

function offline()
	if g_game.getClientVersion() < 862 then
		local gameRootPanel = modules.game_interface.getRootPanel()

		g_keyboard.unbindKeyDown("Ctrl+Z", gameRootPanel)
	end

	clear()
end

function onChannelEvent(channelId, name, type)
	local fmt = ChannelEventFormats[type]

	if not fmt then
		print(("Unknown channel event type (%d)."):format(type))

		return
	end

	local channel = channels[channelId]

	if channel then
		local tab = getTab(channel)

		if tab then
			addTabText(fmt:format(name), SpeakTypesSettings.channelOrange, tab)
		end
	end
end
