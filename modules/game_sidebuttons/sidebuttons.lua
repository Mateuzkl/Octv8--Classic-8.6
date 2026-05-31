buttonsWindow = nil
battleButton = nil
skillsButton = nil
vipButton = nil
questButton = nil
botButton = nil
expHourButton = nil
preyButton = nil
preyTrackerButton = nil
forgeButton = nil
imbuementTrackerButton = nil
wheelButton = nil
proficiencyButton = nil
spellsButton = nil
ciclopediaButton = nil
unjustifiedPointsButton = nil
optionsButton = nil
logoutButton = nil
fullButtons = nil
verticalSeparator = nil

function init()
	buttonsWindow = g_ui.loadUI("sidebuttons", modules.game_interface.getRightPanel())

	buttonsWindow:disableResize()
	buttonsWindow:setup()
	buttonsWindow:open()

	battleButton = buttonsWindow:recursiveGetChildById("battleButton")
	skillsButton = buttonsWindow:recursiveGetChildById("skillsButton")
	vipButton = buttonsWindow:recursiveGetChildById("vipButton")
	questButton = buttonsWindow:recursiveGetChildById("questButton")
	botButton = buttonsWindow:recursiveGetChildById("botButton")
	expHourButton = buttonsWindow:recursiveGetChildById("exphButton")
	preyButton = buttonsWindow:recursiveGetChildById("preyButton")
	preyTrackerButton = buttonsWindow:recursiveGetChildById("preyTrackerButton")
	forgeButton = buttonsWindow:recursiveGetChildById("forgeButton")
	imbuementTrackerButton = buttonsWindow:recursiveGetChildById("imbuementTrackerButton")
	wheelButton = buttonsWindow:recursiveGetChildById("wheelButton")
	proficiencyButton = buttonsWindow:recursiveGetChildById("proficiencyButton")
	spellsButton = buttonsWindow:recursiveGetChildById("spellsButton")
	ciclopediaButton = buttonsWindow:recursiveGetChildById("ciclopediaButton")
	unjustifiedPointsButton = buttonsWindow:recursiveGetChildById("unjustifiedPointsButton")
	optionsButton = buttonsWindow:recursiveGetChildById("optionsButton")
	logoutButton = buttonsWindow:recursiveGetChildById("logoutButton")
	fullButtons = buttonsWindow:recursiveGetChildById("fullButtons")
	verticalSeparator = buttonsWindow:recursiveGetChildById("verticalSeparator")
	showButtons()
end

function terminate()
	buttonsWindow:destroy()
end

local function setButtonsVisible(buttons, visible)
	for _, button in ipairs(buttons) do
		if button then
			if visible then
				button:show()
				button:setHeight(20)
			else
				button:hide()
				button:setHeight(0)
			end
		end
	end
end

function hideButtons()
	setButtonsVisible({
		skillsButton,
		battleButton,
		vipButton,
		spellsButton,
		questButton,
		botButton,
		ciclopediaButton,
		unjustifiedPointsButton,
		expHourButton,
		preyButton,
		preyTrackerButton,
		forgeButton,
		imbuementTrackerButton,
		wheelButton,
		proficiencyButton,
		optionsButton,
		logoutButton,
		verticalSeparator
	}, false)

	if fullButtons then
		fullButtons:setChecked(false)
	end
	buttonsWindow:setHeight(25)
end

function showButtons()
	setButtonsVisible({
		skillsButton,
		battleButton,
		vipButton,
		spellsButton,
		questButton,
		botButton,
		ciclopediaButton,
		unjustifiedPointsButton,
		expHourButton,
		preyButton,
		preyTrackerButton,
		forgeButton,
		imbuementTrackerButton,
		wheelButton,
		proficiencyButton,
		optionsButton,
		logoutButton,
		verticalSeparator
	}, true)

	if fullButtons then
		fullButtons:setChecked(true)
	end
	buttonsWindow:setHeight(103)
end



function toggle()
	if not fullButtons then
		return
	end

	if fullButtons:isChecked() then
		hideButtons()
	else
		showButtons()
	end
end

function onMiniWindowClose()
	buttonsWindow:open()
end
