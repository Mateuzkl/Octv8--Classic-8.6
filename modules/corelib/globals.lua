rootWidget = g_ui.getRootWidget()
modules = package.loaded
G = G or {}

function focusRoot()
	local gameRootPanel = modules.game_interface.getRootPanel()

	if gameRootPanel then
		gameRootPanel:focus()
	end
end

function scheduleEvent(callback, delay)
	local desc = "lua"
	local info = debug.getinfo(2, "Sl")

	if info then
		desc = info.short_src .. ":" .. info.currentline
	end

	local event = g_dispatcher.scheduleEvent(desc, callback, delay)
	event._callback = callback

	return event
end

function addEvent(callback, front)
	local desc = "lua"
	local info = debug.getinfo(2, "Sl")

	if info then
		desc = info.short_src .. ":" .. info.currentline
	end

	local event = g_dispatcher.addEvent(desc, callback, front)
	event._callback = callback

	return event
end

function cycleEvent(callback, interval)
	local desc = "lua"
	local info = debug.getinfo(2, "Sl")

	if info then
		desc = info.short_src .. ":" .. info.currentline
	end

	local event = g_dispatcher.cycleEvent(desc, callback, interval)
	event._callback = callback

	return event
end

function periodicalEvent(eventFunc, conditionFunc, delay, autoRepeatDelay)
	delay = delay or 30
	autoRepeatDelay = autoRepeatDelay or delay
	local func = nil

	function func()
		if conditionFunc and not conditionFunc() then
			func = nil

			return
		end

		eventFunc()
		scheduleEvent(func, delay)
	end

	scheduleEvent(function ()
		func()
	end, autoRepeatDelay)
end

function removeEvent(event)
	if event then
		event:cancel()

		event._callback = nil
	end
end
