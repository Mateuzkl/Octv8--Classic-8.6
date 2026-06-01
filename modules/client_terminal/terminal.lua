local LogColors = {
	[LogDebug] = "pink",
	[LogInfo] = "white",
	[LogWarning] = "yellow",
	[LogError] = "red"
}
local MaxLogLines = 128
local MaxHistory = 1000
local oldenv = getfenv(0)

setfenv(0, _G)

_G.commandEnv = runinsandbox("commands")

setfenv(0, oldenv)

local terminalWindow, terminalButton = nil
local logLocked = false
local commandTextEdit, terminalBuffer = nil
local commandHistory = {}
local currentHistoryIndex = 0
local poped = false
local oldPos, oldSize = nil
local firstShown = false
local flushEvent = nil
local cachedLines = {}
local disabled = false
local allLines = {}

local function navigateCommand(step)
	if commandTextEdit:isMultiline() then
		return
	end

	local numCommands = #commandHistory

	if numCommands > 0 then
		currentHistoryIndex = math.min(math.max(currentHistoryIndex + step, 0), numCommands)

		if currentHistoryIndex > 0 then
			local command = commandHistory[numCommands - currentHistoryIndex + 1]

			commandTextEdit:setText(command)
			commandTextEdit:setCursorPos(-1)
		else
			commandTextEdit:clearText()
		end
	end
end

local function completeCommand()
	local cursorPos = commandTextEdit:getCursorPos()

	if cursorPos == 0 then
		return
	end

	local commandBegin = commandTextEdit:getText():sub(1, cursorPos)
	local possibleCommands = {}
	local allVars = table.copy(_G)

	table.merge(allVars, commandEnv)

	for k, v in pairs(allVars) do
		if k:sub(1, cursorPos) == commandBegin then
			table.insert(possibleCommands, k)
		end
	end

	if #possibleCommands == 1 then
		commandTextEdit:setText(possibleCommands[1])
		commandTextEdit:setCursorPos(-1)
	elseif #possibleCommands > 0 then
		print(">> " .. commandBegin)

		local expandedComplete = commandBegin
		local done = false

		while not done do
			cursorPos = #commandBegin + 1

			if cursorPos > #possibleCommands[1] then
				break
			end

			expandedComplete = commandBegin .. possibleCommands[1]:sub(cursorPos, cursorPos)

			for i, v in ipairs(possibleCommands) do
				if v:sub(1, #expandedComplete) ~= expandedComplete then
					done = true
				end
			end

			if not done then
				commandBegin = expandedComplete
			end
		end

		commandTextEdit:setText(commandBegin)
		commandTextEdit:setCursorPos(-1)

		for i, v in ipairs(possibleCommands) do
			print(v)
		end
	end
end

local function doCommand(textWidget)
	local currentCommand = textWidget:getText()

	executeCommand(currentCommand)
	textWidget:clearText()

	return true
end

local function addNewline(textWidget)
	if not textWidget:isOn() then
		textWidget:setOn(true)
	end

	textWidget:appendText("\n")
end

local function onCommandChange(textWidget, newText, oldText)
	local _, newLineCount = string.gsub(newText, "\n", "\n")

	textWidget:setHeight((newLineCount + 1) * textWidget.baseHeight)

	if newLineCount == 0 and textWidget:isOn() then
		textWidget:setOn(false)
	end
end

local function onLog(level, message, time)
	if disabled then
		return
	end

	if logLocked then
		return
	end

	logLocked = true

	addLine(message, LogColors[level])

	logLocked = false
end

function init()
	terminalWindow = g_ui.displayUI("terminal")

	terminalWindow:setVisible(false)

	terminalWindow.onDoubleClick = popWindow
	terminalButton = modules.client_topmenu.addLeftButton("terminalButton", tr("Terminal") .. " (Ctrl + T)", "/images/topbuttons/terminal", toggle)

	terminalButton:setOn(false)
	g_keyboard.bindKeyDown("Ctrl+T", toggle)

	commandHistory = g_settings.getList("terminal-history")
	commandTextEdit = terminalWindow:getChildById("commandTextEdit")

	commandTextEdit:setHeight(commandTextEdit.baseHeight)
	connect(commandTextEdit, {
		onTextChange = onCommandChange
	})
	g_keyboard.bindKeyPress("Up", function ()
		navigateCommand(1)
	end, commandTextEdit)
	g_keyboard.bindKeyPress("Down", function ()
		navigateCommand(-1)
	end, commandTextEdit)
	g_keyboard.bindKeyPress("Ctrl+C", function ()
		if commandTextEdit:hasSelection() or not terminalSelectText:hasSelection() then
			return false
		end

		g_window.setClipboardText(terminalSelectText:getSelection())

		return true
	end, commandTextEdit)
	g_keyboard.bindKeyDown("Tab", completeCommand, commandTextEdit)
	g_keyboard.bindKeyPress("Shift+Enter", addNewline, commandTextEdit)
	g_keyboard.bindKeyDown("Enter", doCommand, commandTextEdit)
	g_keyboard.bindKeyDown("Escape", hide, terminalWindow)

	terminalBuffer = terminalWindow:getChildById("terminalBuffer")
	terminalSelectText = terminalWindow:getChildById("terminalSelectText")
	terminalSelectText.onDoubleClick = popWindow

	function terminalSelectText.onMouseWheel(a, b, c)
		terminalBuffer:onMouseWheel(b, c)
	end

	function terminalBuffer:onScrollChange(value)
		terminalSelectText:setTextVirtualOffset(value)
	end

	g_logger.setOnLog(onLog)

	if not g_app.isRunning() then
		g_logger.fireOldMessages()
	elseif _G.terminalLines then
		for _, line in pairs(_G.terminalLines) do
			addLine(line.text, line.color)
		end
	end
end

function terminate()
	g_settings.setList("terminal-history", commandHistory)
	removeEvent(flushEvent)

	if poped then
		oldPos = terminalWindow:getPosition()
		oldSize = terminalWindow:getSize()
	end

	local settings = {
		size = oldSize,
		pos = oldPos,
		poped = poped
	}

	g_settings.setNode("terminal-window", settings)
	g_keyboard.unbindKeyDown("Ctrl+T")
	g_logger.setOnLog(nil)
	terminalWindow:destroy()
	terminalButton:destroy()

	commandEnv = nil
	_G.terminalLines = allLines
end

function hideButton()
end

function popWindow()
	if poped then
		oldPos = terminalWindow:getPosition()
		oldSize = terminalWindow:getSize()

		terminalWindow:fill("parent")
		terminalWindow:setOn(false)
		terminalWindow:getChildById("bottomResizeBorder"):disable()
		terminalWindow:getChildById("rightResizeBorder"):disable()
		terminalWindow:getChildById("titleBar"):hide()
		terminalWindow:getChildById("terminalScroll"):setMarginTop(0)
		terminalWindow:getChildById("terminalScroll"):setMarginBottom(0)
		terminalWindow:getChildById("terminalScroll"):setMarginRight(0)

		poped = false
	else
		terminalWindow:breakAnchors()
		terminalWindow:setOn(true)

		local size = oldSize or {
			width = g_window.getWidth() / 2.5,
			height = g_window.getHeight() / 4
		}

		terminalWindow:setSize(size)

		local pos = oldPos or {
			x = 0,
			y = g_window.getHeight()
		}

		terminalWindow:setPosition(pos)
		terminalWindow:getChildById("bottomResizeBorder"):enable()
		terminalWindow:getChildById("rightResizeBorder"):enable()
		terminalWindow:getChildById("titleBar"):show()
		terminalWindow:getChildById("terminalScroll"):setMarginTop(18)
		terminalWindow:getChildById("terminalScroll"):setMarginBottom(1)
		terminalWindow:getChildById("terminalScroll"):setMarginRight(1)
		terminalWindow:bindRectToParent()

		poped = true
	end
end

function toggle()
	if terminalWindow:isVisible() then
		hide()
	else
		if not firstShown then
			local settings = g_settings.getNode("terminal-window")

			if settings then
				if settings.size then
					oldSize = settings.size
				end

				if settings.pos then
					oldPos = settings.pos
				end

				if settings.poped then
					popWindow()
				end
			end

			firstShown = true
		end

		show()
	end
end

function show()
	terminalWindow:show()
	terminalWindow:raise()
	terminalWindow:focus()
end

function hide()
	terminalWindow:hide()
end

function disable()
	g_keyboard.unbindKeyDown("Ctrl+T")

	disabled = true
end

function flushLines()
	local numLines = terminalBuffer:getChildCount() + #cachedLines
	local fulltext = terminalSelectText:getText()

	for _, line in pairs(cachedLines) do
		if MaxLogLines < numLines then
			local firstChild = terminalBuffer:getChildByIndex(1)

			if firstChild then
				local len = #firstChild:getText()

				firstChild:destroy()
				table.remove(allLines, 1)

				fulltext = string.sub(fulltext, len)
			end
		end

		local label = g_ui.createWidget("TerminalLabel", terminalBuffer)

		label:setId("terminalLabel" .. numLines)
		label:setText(line.text)
		label:setColor(line.color)
		table.insert(allLines, {
			text = line.text,
			color = line.color
		})

		fulltext = fulltext .. "\n" .. line.text
	end

	terminalSelectText:setText(fulltext)

	cachedLines = {}

	removeEvent(flushEvent)

	flushEvent = nil
end

function addLine(text, color)
	if not flushEvent then
		flushEvent = scheduleEvent(flushLines, 10)
	end

	text = string.gsub(text, "\t", "    ")

	table.insert(cachedLines, {
		text = text,
		color = color
	})
end

function terminalPrint(value)
	if type(value) == "table" then
		return print(json.encode(value, 2))
	end

	print(tostring(value))
end

function executeCommand(command)
	if command == nil or #string.gsub(command, "\n", "") == 0 then
		return
	end

	addLine("> " .. command, "#ffffff")

	if g_game.getFeature(GameNoDebug) then
		addLine("Terminal is disabled on this server", "#ff8888")

		return
	end

	currentHistoryIndex = 0

	if #commandHistory == 0 or commandHistory[#commandHistory] ~= command then
		table.insert(commandHistory, command)

		while MaxHistory < #commandHistory do
			table.remove(commandHistory, 1)
		end
	end

	local realCommand = nil

	if string.sub(command, 1, 1) == "=" then
		realCommand = "modules.client_terminal.terminalPrint(" .. string.sub(command, 2) .. ")"
	else
		realCommand = command
	end

	local func, err = loadstring(realCommand, "@")

	if not func then
		local command_name = command:match("^([%w_]+)[%s]*.*")

		if command_name then
			local args = string.split(command:match("^[%w_]+[%s]*(.*)"), " ")

			if commandEnv[command_name] and type(commandEnv[command_name]) == "function" then
				function func()
					modules.client_terminal.commandEnv[command_name](unpack(args))
				end
			elseif command_name == command then
				addLine("ERROR: command not found", "red")

				return
			end
		end
	end

	if not func then
		addLine("ERROR: incorrect lua syntax: " .. err:sub(5), "red")

		return
	end

	commandEnv.player = g_game.getLocalPlayer()

	setfenv(func, commandEnv)

	local ok, ret = pcall(func)

	if ok then
		if ret then
			addLine(ret, "white")
		end
	else
		addLine("ERROR: command failed: " .. ret, "red")
	end
end

function clear()
	terminalBuffer:destroyChildren()
	terminalSelectText:setText("")

	cachedLines = {}
	allLines = {}
end
