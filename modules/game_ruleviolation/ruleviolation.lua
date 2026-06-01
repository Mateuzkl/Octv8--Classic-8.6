rvreasons = {
	tr("1a) Offensive Name"),
	tr("1b) Invalid Name Format"),
	tr("1c) Unsuitable Name"),
	tr("1d) Name Inciting Rule Violation"),
	tr("2a) Offensive Statement"),
	tr("2b) Spamming"),
	tr("2c) Illegal Advertising"),
	tr("2d) Off-Topic Public Statement"),
	tr("2e) Non-English Public Statement"),
	tr("2f) Inciting Rule Violation"),
	tr("3a) Bug Abuse"),
	tr("3b) Game Weakness Abuse"),
	tr("3c) Using Unofficial Software to Play"),
	tr("3d) Hacking"),
	tr("3e) Multi-Clienting"),
	tr("3f) Account Trading or Sharing"),
	tr("4a) Threatening Gamemaster"),
	tr("4b) Pretending to Have Influence on Rule Enforcement"),
	tr("4c) False Report to Gamemaster"),
	tr("Destructive Behaviour"),
	tr("Excessive Unjustified Player Killing")
}
rvactions = {
	[0] = tr("Notation"),
	tr("Name Report"),
	tr("Banishment"),
	tr("Name Report + Banishment"),
	tr("Banishment + Final Warning"),
	tr("Name Report + Banishment + Final Warning"),
	tr("Statement Report")
}
ruleViolationWindow = nil
reasonsTextList = nil
actionsTextList = nil

function init()
	connect(g_game, {
		onGMActions = loadReasons
	})

	ruleViolationWindow = g_ui.displayUI("ruleviolation")

	ruleViolationWindow:setVisible(false)

	reasonsTextList = ruleViolationWindow:getChildById("reasonList")
	actionsTextList = ruleViolationWindow:getChildById("actionList")

	g_keyboard.bindKeyDown("Ctrl+Y", function ()
		show()
	end)

	if g_game.isOnline() then
		loadReasons()
	end
end

function terminate()
	disconnect(g_game, {
		onGMActions = loadReasons
	})
	g_keyboard.unbindKeyDown("Ctrl+Y")
	ruleViolationWindow:destroy()
end

function hasWindowAccess()
	return reasonsTextList:getChildCount() > 0
end

function loadReasons()
	reasonsTextList:destroyChildren()
	actionsTextList:destroyChildren()

	local actions = g_game.getGMActions()

	for reason, actionFlags in pairs(actions) do
		local label = g_ui.createWidget("RVListLabel", reasonsTextList)
		label.onFocusChange = onSelectReason

		label:setText(rvreasons[reason])

		label.reasonId = reason
		label.actionFlags = actionFlags
	end

	if not hasWindowAccess() and ruleViolationWindow:isVisible() then
		hide()
	end
end

function show(target, statement)
	if g_game.isOnline() and hasWindowAccess() then
		if target then
			ruleViolationWindow:getChildById("nameText"):setText(target)
		end

		if statement then
			ruleViolationWindow:getChildById("statementText"):setText(statement)
		end

		ruleViolationWindow:show()
		ruleViolationWindow:raise()
		ruleViolationWindow:focus()
		ruleViolationWindow:getChildById("commentText"):focus()
	end
end

function hide()
	ruleViolationWindow:hide()
	clearForm()
end

function onSelectReason(reasonLabel, focused)
	if reasonLabel.actionFlags and focused then
		actionsTextList:destroyChildren()

		for actionBaseFlag = 0, #rvactions do
			local actionFlagString = rvactions[actionBaseFlag]

			if bit32.band(reasonLabel.actionFlags, math.pow(2, actionBaseFlag)) > 0 then
				local label = g_ui.createWidget("RVListLabel", actionsTextList)

				label:setText(actionFlagString)

				label.actionId = actionBaseFlag
			end
		end
	end
end

function report()
	local reasonLabel = reasonsTextList:getFocusedChild()

	if not reasonLabel then
		displayErrorBox(tr("Error"), tr("You must select a reason."))

		return
	end

	local actionLabel = actionsTextList:getFocusedChild()

	if not actionLabel then
		displayErrorBox(tr("Error"), tr("You must select an action."))

		return
	end

	local target = ruleViolationWindow:getChildById("nameText"):getText()
	local reason = reasonLabel.reasonId
	local action = actionLabel.actionId
	local comment = ruleViolationWindow:getChildById("commentText"):getText()
	local statement = ruleViolationWindow:getChildById("statementText"):getText()
	local statementId = 0
	local ipBanishment = ruleViolationWindow:getChildById("ipBanCheckBox"):isChecked()

	if action == 6 and statement == "" then
		displayErrorBox(tr("Error"), tr("No statement has been selected."))
	elseif comment == "" then
		displayErrorBox(tr("Error"), tr("You must enter a comment."))
	else
		g_game.reportRuleViolation(target, reason, action, comment, statement, statementId, ipBanishment)
		hide()
	end
end

function clearForm()
	ruleViolationWindow:getChildById("nameText"):clearText()
	ruleViolationWindow:getChildById("commentText"):clearText()
	ruleViolationWindow:getChildById("statementText"):clearText()
	ruleViolationWindow:getChildById("ipBanCheckBox"):setChecked(false)
end
