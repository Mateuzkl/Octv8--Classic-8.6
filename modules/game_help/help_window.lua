helpwindowWindow = nil

function init()
	connect(g_game, {
		onGameStart = online,
		onGameEnd = offline
	})

	helpwindowWindow = g_ui.displayUI("help_window")

	helpwindowWindow:hide()
end

function terminate()
	disconnect(g_game, {
		onGameStart = online,
		onGameEnd = offline
	})
	offline()

	if helpwindowWindow then
		helpwindowWindow:destroy()
	end
end

function toggle()
	if not helpwindowWindow then
		helpwindowWindow = g_ui.displayUI("help_window")

		helpwindowWindow:hide()
	end

	if helpwindowWindow:isVisible() then
		helpwindowWindow:hide()
	else
		helpwindowWindow:show()
	end
end

function closing()
	helpwindowWindow:hide()
end

function offline()
	if helpwindowWindow then
		helpwindowWindow:destroy()

		helpwindowWindow = nil
	end
end
