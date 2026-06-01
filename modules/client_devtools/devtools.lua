devWindow = nil
localHost = nil
storeServer = nil

function init()
	devWindow = g_ui.displayUI("devtools")

	devWindow:hide()

	localHost = devWindow:recursiveGetChildById("localHost")

	if g_settings.get("localhost") == "true" then
		localHost:setChecked(true)
	end

	g_keyboard.bindKeyDown("Ctrl+Shift+D", toggle)
	connect(g_game, {
		onGameStart = online
	})
end

function terminate()
	disconnect(g_game, {
		onGameStart = online
	})
	g_settings.set("localhost", localHost:isChecked() and "true" or "false")
	devWindow:destroy()

	devWindow = nil

	g_keyboard.unbindKeyDown("Ctrl+Shift+D")
end

function toggle()
	if g_game.isOnline() then
		return
	end

	if devWindow:isVisible() then
		hide()
	else
		show()
	end
end

function show()
	devWindow:show()
	devWindow:raise()
	devWindow:focus()
end

function hide()
	devWindow:hide()
end

function online()
	hide()
end

function onLocalhostCheckChange(checked)
	if checked then
		storeServer = Server.host
		Server.host = "127.0.0.1"
	elseif storeServer then
		Server.host = storeServer
		storeServer = nil
	end
end
