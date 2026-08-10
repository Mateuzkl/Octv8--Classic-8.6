questLogButton = nil
window = nil
settings = {}
local callDelay = 1000
local dispatcher = {}
local refreshEvent = nil

local function cancelQuestRefresh()
	if refreshEvent then
		removeEvent(refreshEvent)
		refreshEvent = nil
	end
end

function init()
	g_ui.importStyle("questlogwindow")

	window = g_ui.createWidget("QuestLogWindow", rootWidget)

	window:hide()

	if not g_app.isMobile() then
		questLogButton = modules.client_topmenu.addLeftGameButton("questLogButton", tr("Quest Log"), "/images/topbuttons/questlog", function ()
			g_game.requestQuestLog()
		end, false, 8)
	end

	connect(g_game, {
		onQuestLog = onGameQuestLog,
		onQuestLine = onGameQuestLine,
		onGameEnd = offline,
		onGameStart = online
	})
	online()
end

function terminate()
	cancelQuestRefresh()

	disconnect(g_game, {
		onQuestLog = onGameQuestLog,
		onQuestLine = onGameQuestLine,
		onGameEnd = offline,
		onGameStart = online
	})
	offline()

	if questLogButton then
		questLogButton:destroy()
	end
end

function offline()
	cancelQuestRefresh()
	if window then
		window:hide()
	end

	save()
end

function online()
	local playerName = g_game.getCharacterName()

	if not playerName then
		return
	end

	cancelQuestRefresh()
	load()
	refreshQuests()

	local playerName = g_game.getCharacterName()
	settings[playerName] = settings[playerName] or {}
	local settings = settings[playerName]
	local missionList = window.missionlog.missionList
	local missionDescription = window.missionlog.missionDescription

	connect(missionList, {
		onChildFocusChange = function (self, focusedChild)
			if focusedChild == nil then
				return
			end

			missionDescription:setText(focusedChild.description)
		end
	})
end

function show(questlog)
	if questlog then
		window:raise()
		window:show()
		window:focus()

		window.missionlog.currentQuest = nil

		window.questlog:setVisible(true)
		window.missionlog:setVisible(false)
		window.closeButton:setText("Close")
		window.showButton:setVisible(true)
		window.missionlog.missionDescription:setText("")
	else
		window.questlog:setVisible(false)
		window.missionlog:setVisible(true)
		window.closeButton:setText("Back")
		window.showButton:setVisible(false)
	end
end

function back()
	if window:isVisible() then
		if window.questlog:isVisible() then
			window:hide()
		else
			show(true)
		end
	end
end

function showQuestLine()
	local questList = window.questlog.questList
	local child = questList:getFocusedChild()

	g_game.requestQuestLine(child.questId)
	window.missionlog.questName:setText(child.questName)

	window.missionlog.currentQuest = child.questId
end

function onGameQuestLog(quests)
	show(true)

	local questList = window.questlog.questList

	questList:destroyChildren()

	for i, questEntry in pairs(quests) do
		local id, name, completed = unpack(questEntry)
		local questLabel = g_ui.createWidget("QuestLabel", questList)

		questLabel:setChecked(i % 2 == 0)

		questLabel.questId = id
		questLabel.questName = name

		if completed then
			name = name .. " (completed)" or name
		end

		questLabel:setText(name)

		function questLabel.onDoubleClick()
			window.missionlog.currentQuest = id

			g_game.requestQuestLine(id)
			window.missionlog.questName:setText(questLabel.questName)
		end
	end

	questList:focusChild(questList:getFirstChild())
end

function onGameQuestLine(questId, questMissions)
	show(false)

	local missionList = window.missionlog.missionList

	if questId == window.missionlog.currentQuest then
		missionList:destroyChildren()
	end

	for i, questMission in pairs(questMissions) do
		local name, description = unpack(questMission)
		local missionLabel = g_ui.createWidget("QuestLabel", missionList)
		local widgetId = questId .. "." .. i

		missionLabel:setChecked(i % 2 == 0)
		missionLabel:setId(widgetId)

		missionLabel.questId = questId

		missionLabel:setText(name)

		missionLabel.description = description

		missionLabel:setVisible(questId == window.missionlog.currentQuest)
	end

	local focusTarget = missionList:getFirstChild()

	if focusTarget and focusTarget:isVisible() then
		missionList:focusChild(focusTarget)
	end
end

function refreshQuests()
	refreshEvent = nil
	if not g_game.isOnline() then
		return
	end

	local data = settings[g_game.getCharacterName()]
	data = data or {}

	refreshEvent = scheduleEvent(refreshQuests, callDelay)
end

function load()
	local file = "/settings/questlog.json"

	if g_resources.fileExists(file) then
		local status, result = pcall(function ()
			return json.decode(g_resources.readFileContents(file))
		end)

		if not status then
			return g_logger.error("Error while reading profiles file. To fix this problem you can delete storage.json. Details: " .. result)
		end

		settings = result
	end
end

function save()
	local file = "/settings/questlog.json"
	local status, result = pcall(function ()
		return json.encode(settings, 2)
	end)

	if not status then
		return g_logger.error("Error while saving profile settings. Data won't be saved. Details: " .. result)
	end

	if result:len() > 104857600 then
		return g_logger.error("Something went wrong, file is above 100MB, won't be saved")
	end

	g_resources.writeFileContents(file, result)
end
