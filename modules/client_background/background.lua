local background, clientVersionLabel, infoWindow, infoLabel = nil
local infoEscCallback = nil

function init()
	background = g_ui.displayUI("background")

	background:lower()

	infoWindow = g_ui.createWidget("InfoWindow", rootWidget)
	infoLabel = infoWindow:getChildById("infoLabel")

	if infoLabel and g_app.getOs() == "windows" then
		infoLabel:setText(infoLabel:getText():gsub("Linux", "Windows"))
	end

	infoWindow.onEscape = hideInfoWindow
	infoWindow.onEnter = hideInfoWindow

	if not infoEscCallback then
		infoEscCallback = function ()
			if infoWindow and infoWindow:isVisible() then
				hideInfoWindow()
				return true
			end
		end
	end

	g_keyboard.bindKeyDown("Escape", infoEscCallback, rootWidget)

	infoWindow:hide()

	clientVersionLabel = background:getChildById("clientVersionLabel")

	clientVersionLabel:setText("OTClientV8 " .. g_app.getVersion() .. "\nrev " .. g_app.getBuildRevision() .. "\nMade by:\n" .. g_app.getAuthor() .. "")

	if not g_game.isOnline() then
		addEvent(function ()
			g_effects.fadeIn(clientVersionLabel, 1500)
		end)
	end

	connect(g_game, {
		onGameStart = hide
	})
	connect(g_game, {
		onGameEnd = show
	})
end

function terminate()
	disconnect(g_game, {
		onGameStart = hide
	})
	disconnect(g_game, {
		onGameEnd = show
	})
	hideInfoWindow()
	g_keyboard.unbindKeyDown("Escape", infoEscCallback, rootWidget)
	g_effects.cancelFade(background:getChildById("clientVersionLabel"))
	background:destroy()
	infoWindow:destroy()

	infoWindow = nil
	Background = nil
end

function hide()
	hideInfoWindow()
	background:hide()
end

function show()
	background:show()
end

function showInfoWindow()
	if not infoWindow:isVisible() then
		infoWindow:show()
	end

	infoWindow:raise()
	infoWindow:focus()
end

function hideInfoWindow()
	if infoWindow and infoWindow:isVisible() then
		infoWindow:hide()
	end
end

function hideVersionLabel()
	background:getChildById("clientVersionLabel"):hide()
end

function setVersionText(text)
	clientVersionLabel:setText(text)
end

function getBackground()
	return background
end
