modalDialog = nil

function init()
	g_ui.importStyle("modaldialog")
	connect(g_game, {
		onModalDialog = onModalDialog,
		onGameEnd = destroyDialog
	})

	local dialog = rootWidget:recursiveGetChildById("modalDialog")

	if dialog then
		modalDialog = dialog
	end
end

function terminate()
	disconnect(g_game, {
		onModalDialog = onModalDialog,
		onGameEnd = destroyDialog
	})
end

function destroyDialog()
	if modalDialog then
		modalDialog:unlock()
		modalDialog:destroy()

		modalDialog = nil

		focusRoot()
	end
end

function onModalDialog(id, title, message, buttons, enterButton, escapeButton, choices, priority)
	if modalDialog then
		return
	end

	modalDialog = g_ui.createWidget("ModalDialog", rootWidget)
	local messageLabel = modalDialog:getChildById("messageLabel")
	local choiceList = modalDialog:getChildById("choiceList")
	local choiceScrollbar = modalDialog:getChildById("choiceScrollBar")
	local buttonsPanel = modalDialog:getChildById("buttonsPanel")

	modalDialog:setText(title)
	messageLabel:setText(message)

	repeat
		local colorData = {
			string.find(message, "%[color=(%a+)%](.-)%[/color%]", 1)
		}

		if not colorData or #colorData == 0 then
			break
		end

		local _start = colorData[1]
		local color = colorData[3]
		local words = colorData[4]
		message = message:gsub("%[color=(%a+)%](.-)%[/color%]", words, 1)
		local labelHighlight = g_ui.createWidget("ModalPhantomLabel", messageLabel)

		labelHighlight:fill("parent")
		messageLabel:setText(message)

		local drawText = messageLabel:getDrawText()
		local tmpText = ""

		for letter = 1, _start - 1 do
			local tmpChar = string.byte(drawText:sub(letter, letter))
			local fillChar = (tmpChar == 10 or tmpChar == 32) and string.char(tmpChar) or string.char(127)
			tmpText = tmpText .. string.rep(fillChar, letterWidth[tmpChar])
		end

		tmpText = tmpText .. words

		labelHighlight:setColor(color)
		labelHighlight:setText(tmpText)
		labelHighlight:setFont("verdana-11px-antialised")
	until not string.find(message, "%[color=(%a+)%](.-)%[/color%]", 1)

	messageLabel:setText(message)

	local labelHeight = nil

	for i = 1, #choices do
		local choiceId = choices[i][1]
		local choiceName = choices[i][2]
		local label = g_ui.createWidget("ChoiceListLabel", choiceList)
		label.choiceId = choiceId

		label:setText(choiceName)
		label:setPhantom(false)

		labelHeight = labelHeight or label:getHeight()
	end

	choiceList:focusChild(choiceList:getFirstChild())
	g_keyboard.bindKeyPress("Down", function ()
		choiceList:focusNextChild(KeyboardFocusReason)
	end, modalDialog)
	g_keyboard.bindKeyPress("Up", function ()
		choiceList:focusPreviousChild(KeyboardFocusReason)
	end, modalDialog)

	local choiceListHeight = 0

	if #choices > 0 then
		choiceList:setVisible(true)
		choiceScrollbar:setVisible(true)

		choiceListHeight = (math.min(modalDialog.maximumChoices, math.max(modalDialog.minimumChoices, #choices)) + 1) * labelHeight
	end

	local buttonsWidth = 0

	for i = 1, #buttons do
		local buttonId = buttons[i][1]
		local buttonText = buttons[i][2]
		local button = g_ui.createWidget("ModalButton", buttonsPanel)

		button:setText(buttonText)

		function button:onClick()
			local focusedChoice = choiceList:getFocusedChild()
			local choice = 255

			if focusedChoice then
				choice = focusedChoice.choiceId
			end

			g_game.answerModalDialog(id, buttonId, choice)
			destroyDialog()
		end

		buttonsWidth = buttonsWidth + button:getWidth() + button:getMarginLeft() + button:getMarginRight()
	end

	buttonsWidth = buttonsWidth + modalDialog:getPaddingLeft() + modalDialog:getPaddingRight()

	modalDialog:setWidth(math.min(modalDialog.maximumWidth, math.max(buttonsWidth, messageLabel:getTextSize().width, modalDialog.minimumWidth)))
	choiceList:setHeight(choiceListHeight)
	choiceScrollbar:setHeight(choiceListHeight)

	local childrenHeight = modalDialog:getPaddingTop() + modalDialog:getPaddingBottom()

	for _, child in pairs(modalDialog:getChildren()) do
		local childHeight = child:getHeight() + child:getMarginTop() + child:getMarginBottom()

		if childHeight > 0 and child:isVisible() and child ~= choiceScrollbar then
			childrenHeight = childrenHeight + childHeight
		end
	end

	modalDialog:setHeight(childrenHeight + 20)

	local function enterFunc()
		local focusedChoice = choiceList:getFocusedChild()
		local choice = 255

		if focusedChoice then
			choice = focusedChoice.choiceId
		end

		g_game.answerModalDialog(id, enterButton, choice)
		destroyDialog()
	end

	local function escapeFunc()
		local focusedChoice = choiceList:getFocusedChild()
		local choice = 255

		if focusedChoice then
			choice = focusedChoice.choiceId
		end

		g_game.answerModalDialog(id, escapeButton, choice)
		destroyDialog()
	end

	choiceList.onDoubleClick = enterFunc
	modalDialog.onEnter = enterFunc
	modalDialog.onEscape = escapeFunc

	modalDialog:lock()
end
