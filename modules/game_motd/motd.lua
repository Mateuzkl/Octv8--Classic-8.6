motdWindow = nil

local function ensureWindow()
	if not motdWindow then
		motdWindow = g_ui.displayUI("motd")
		motdWindow:hide()
	end

	return motdWindow
end

local function getMotdText()
	if type(G.motdMessage) ~= "string" or #G.motdMessage == 0 then
		return nil
	end

	return G.motdMessage:gsub("\\n", "\n")
end

local function updateMotdText()
	local window = ensureWindow()
	local motdText = window:getChildById("motdText")
	local text = getMotdText() or tr("No message of the day available.")

	if motdText then
		motdText:setText(text)
	end

	return text
end

function init()
	connect(g_game, {
		onGameStart = online,
		onGameEnd = offline,
		onTextMessage = onTextMessage
	})
	ensureWindow()
end

function terminate()
	disconnect(g_game, {
		onGameStart = online,
		onGameEnd = offline,
		onTextMessage = onTextMessage
	})
	offline()

	if motdWindow then
		motdWindow:destroy()

		motdWindow = nil
	end
end

function online()
	updateMotdText()

	local motdNumber = tonumber(G.motdNumber)
	local lastMotdNumber = g_settings.getNumber("motd")

	if motdNumber and motdNumber ~= lastMotdNumber and getMotdText() then
		g_settings.set("motd", motdNumber)
		g_settings.save()
		toggle()
	end
end

function toggle()
	ensureWindow()
	updateMotdText()

	if motdWindow:isVisible() then
		motdWindow:hide()
	else
		motdWindow:show()
	end
end

function offline()
	if motdWindow then
		motdWindow:destroy()

		motdWindow = nil
	end
end

function onTextMessage(mode, text)
	if text:lower() == "!motd" then
		toggle()

		return true
	end
end
