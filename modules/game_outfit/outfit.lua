local window, colorModeGroup, colorBoxGroup = nil
local colorBoxes = {}
local currentColorBox = nil
local currentOutfitIndex = 1
local currentMountIndex = 0
ignoreNextOutfitWindow = 0
local tempOutfit = {}
local tempMount = 0
local outfits = {}
local mounts = {}
local previewDirections = {
	North,
	East,
	South,
	West
}

local function setWidgetPreviewDirection(widgetId, direction)
	if not window then
		return
	end

	local previewWidget = window:recursiveGetChildById(widgetId)

	if not previewWidget then
		return
	end

	previewWidget:setDirection(direction)
end

local function rotateWidgetPreview(widgetId, step)
	if not window then
		return
	end

	local previewWidget = window:recursiveGetChildById(widgetId)

	if not previewWidget then
		return
	end

	local currentDirection = previewWidget:getDirection() or South
	local currentIndex = 1

	for index, direction in ipairs(previewDirections) do
		if direction == currentDirection then
			currentIndex = index

			break
		end
	end

	local nextIndex = (currentIndex - 1 + step) % #previewDirections + 1

	setWidgetPreviewDirection(widgetId, previewDirections[nextIndex])
end

function init()
	connect(g_game, {
		onOpenOutfitWindow = onOpenOutfitWindow,
		onGameEnd = destroy
	})
end

function terminate()
	disconnect(g_game, {
		onOpenOutfitWindow = onOpenOutfitWindow,
		onGameEnd = destroy
	})
	destroy()
end

function onOpenOutfitWindow(currentOutfit, outfitList, mountList)
	if ignoreNextOutfitWindow and g_clock.millis() < ignoreNextOutfitWindow + 1000 then
		return
	end

	if window then
		destroy()
	end

	window = g_ui.displayUI("/modules/game_outfit/outfitwindow")

	if not window then
		return
	end

	outfits = outfitList or {}
	mounts = mountList or {}
	tempOutfit = {
		mount = 0,
		type = currentOutfit.type or 0,
		head = currentOutfit.head or 0,
		body = currentOutfit.body or 0,
		legs = currentOutfit.legs or 0,
		feet = currentOutfit.feet or 0,
		addons = currentOutfit.addons or 0
	}
	currentOutfitIndex = 1
	local hasOutfit = false

	for index, outfit in ipairs(outfits) do
		if outfit[1] == tempOutfit.type then
			currentOutfitIndex = index
			hasOutfit = true

			break
		end
	end

	currentMountIndex = 0
	local hasMount = false

	for index, mount in ipairs(mounts) do
		if mount[1] == currentOutfit.mount then
			currentMountIndex = index
			hasMount = true

			break
		end
	end

	if #outfits > 0 and not hasOutfit then
		currentOutfitIndex = 1
		tempOutfit.type = outfits[1][1]
		tempOutfit.addons = outfits[1][3]
	elseif #outfits == 0 then
		tempOutfit.type = 0
		tempOutfit.addons = 0
	end

	if currentMountIndex > 0 and mounts[currentMountIndex] then
		tempMount = mounts[currentMountIndex][1]

		window:recursiveGetChildById("mount"):setOutfit({
			type = tempMount
		})
		window:recursiveGetChildById("mountName"):setText(mounts[currentMountIndex][2])
	else
		tempMount = 0

		window:recursiveGetChildById("mount"):setOutfit({
			type = 0
		})
		window:recursiveGetChildById("mountName"):setText("No Mount")
	end

	window:recursiveGetChildById("creature"):setOutfit(tempOutfit)
	setWidgetPreviewDirection("creature", South)

	if #outfits > 0 and outfits[currentOutfitIndex] then
		window:recursiveGetChildById("outfitName"):setText(outfits[currentOutfitIndex][2])
	else
		window:recursiveGetChildById("outfitName"):setText("No Outfit")
	end

	colorBoxGroup = UIRadioGroup.create()

	for j = 0, 6 do
		for i = 0, 18 do
			local colorBox = g_ui.createWidget("ColorBox", window.colorBoxPanel)
			local outfitColor = getOutfitColor(j * 19 + i)

			colorBox:setBackgroundColor(outfitColor)
			colorBox:setId("colorBox" .. j * 19 + i)

			colorBox.colorId = j * 19 + i

			if colorBox.colorId == tempOutfit.head then
				currentColorBox = colorBox

				colorBox:setChecked(true)
			end

			colorBoxGroup:addWidget(colorBox)
		end
	end

	colorBoxGroup.onSelectionChange = onColorCheckChange
	colorModeGroup = UIRadioGroup.create()

	colorModeGroup:addWidget(window.head)
	colorModeGroup:addWidget(window.body)
	colorModeGroup:addWidget(window.legs)
	colorModeGroup:addWidget(window.feet)

	colorModeGroup.onSelectionChange = onColorModeChange

	colorModeGroup:selectWidget(window.head)
	configureAddons(tempOutfit.addons)
end

function cycleOutfit(factor)
	if not outfits or #outfits == 0 then
		return
	end

	currentOutfitIndex = currentOutfitIndex + factor

	if currentOutfitIndex > #outfits then
		currentOutfitIndex = 1
	elseif currentOutfitIndex < 1 then
		currentOutfitIndex = #outfits
	end

	if outfits[currentOutfitIndex] then
		tempOutfit.type = outfits[currentOutfitIndex][1]
		tempOutfit.addons = outfits[currentOutfitIndex][3]

		window:recursiveGetChildById("creature"):setOutfit(tempOutfit)
		window:recursiveGetChildById("outfitName"):setText(outfits[currentOutfitIndex][2])
		configureAddons(outfits[currentOutfitIndex][3])
	end
end

function cycleMount(factor)
	if not mounts or #mounts == 0 then
		return
	end

	currentMountIndex = currentMountIndex + factor

	if currentMountIndex > #mounts then
		currentMountIndex = 0
	elseif currentMountIndex < 0 then
		currentMountIndex = #mounts
	end

	if currentMountIndex > 0 and mounts[currentMountIndex] then
		tempMount = mounts[currentMountIndex][1]

		window:recursiveGetChildById("mount"):setOutfit({
			type = tempMount
		})
		setWidgetPreviewDirection("mount", South)
		window:recursiveGetChildById("mountName"):setText(mounts[currentMountIndex][2])
	else
		tempMount = 0

		window:recursiveGetChildById("mount"):setOutfit({
			type = 0
		})
		setWidgetPreviewDirection("mount", South)
		window:recursiveGetChildById("mountName"):setText("No Mount")
	end
end

function configureAddons(addons)
	addons = addons or 0
	local hasAddon1 = addons == 1 or addons == 3
	local hasAddon2 = addons == 2 or addons == 3

	if window.addon1 and window.addon1.check then
		window.addon1.check:setEnabled(hasAddon1)
	end

	if window.addon2 and window.addon2.check then
		window.addon2.check:setEnabled(hasAddon2)
	end

	if window.addon1 and window.addon1.check then
		window.addon1.check.onCheckChange = nil
	end

	if window.addon2 and window.addon2.check then
		window.addon2.check.onCheckChange = nil
	end

	if window.addon1 and window.addon1.check then
		window.addon1.check:setChecked(false)
	end

	if window.addon2 and window.addon2.check then
		window.addon2.check:setChecked(false)
	end

	if tempOutfit.addons == 3 then
		if window.addon1 and window.addon1.check then
			window.addon1.check:setChecked(true)
		end

		if window.addon2 and window.addon2.check then
			window.addon2.check:setChecked(true)
		end
	elseif tempOutfit.addons == 2 then
		if window.addon1 and window.addon1.check then
			window.addon1.check:setChecked(false)
		end

		if window.addon2 and window.addon2.check then
			window.addon2.check:setChecked(true)
		end
	elseif tempOutfit.addons == 1 then
		if window.addon1 and window.addon1.check then
			window.addon1.check:setChecked(true)
		end

		if window.addon2 and window.addon2.check then
			window.addon2.check:setChecked(false)
		end
	end

	if window.addon1 and window.addon1.check then
		window.addon1.check.onCheckChange = onAddonChange
	end

	if window.addon2 and window.addon2.check then
		window.addon2.check.onCheckChange = onAddonChange
	end
end

function onAddonChange(widget, checked)
	local addonId = widget:getParent():getId()
	local addons = tempOutfit.addons or 0

	if addonId == "addon1" then
		addons = checked and addons + 1 or addons - 1
	elseif addonId == "addon2" then
		addons = checked and addons + 2 or addons - 2
	end

	tempOutfit.addons = addons

	window:recursiveGetChildById("creature"):setOutfit(tempOutfit)
end

function onColorModeChange(widget, selectedWidget)
	if not selectedWidget then
		return
	end

	local colorMode = selectedWidget:getId()
	local targetBox = nil

	if colorMode == "head" then
		targetBox = window.colorBoxPanel["colorBox" .. (tempOutfit.head or 0)]
	elseif colorMode == "body" then
		targetBox = window.colorBoxPanel["colorBox" .. (tempOutfit.body or 0)]
	elseif colorMode == "legs" then
		targetBox = window.colorBoxPanel["colorBox" .. (tempOutfit.legs or 0)]
	elseif colorMode == "feet" then
		targetBox = window.colorBoxPanel["colorBox" .. (tempOutfit.feet or 0)]
	end

	if targetBox then
		colorBoxGroup:selectWidget(targetBox)
	end
end

function onColorCheckChange(widget, selectedWidget)
	if not selectedWidget then
		return
	end

	local colorId = selectedWidget.colorId
	local selectedModeWidget = colorModeGroup:getSelectedWidget()

	if not selectedModeWidget then
		return
	end

	local colorMode = selectedModeWidget:getText():lower()

	if colorMode == "head" then
		tempOutfit.head = colorId
	elseif colorMode == "primary" then
		tempOutfit.body = colorId
	elseif colorMode == "secondary" then
		tempOutfit.legs = colorId
	elseif colorMode == "detail" then
		tempOutfit.feet = colorId
	end

	window:recursiveGetChildById("creature"):setOutfit(tempOutfit)
end

function randomize()
	if not colorModeGroup or not colorBoxGroup or not window then
		return
	end

	local colorBoxes = {}

	for i = 0, 113 do
		local colorBox = window.colorBoxPanel["colorBox" .. i]

		if colorBox then
			table.insert(colorBoxes, colorBox)
		end
	end

	if #colorBoxes == 0 then
		return
	end

	local colorModes = {
		{
			field = "head",
			widget = window.head
		},
		{
			field = "body",
			widget = window.body
		},
		{
			field = "legs",
			widget = window.legs
		},
		{
			field = "feet",
			widget = window.feet
		}
	}

	for _, modeData in ipairs(colorModes) do
		if modeData.widget and colorModeGroup then
			colorModeGroup:selectWidget(modeData.widget)

			local randomIndex = math.random(1, #colorBoxes)
			local randomColorBox = colorBoxes[randomIndex]

			if colorBoxGroup and randomColorBox then
				colorBoxGroup:selectWidget(randomColorBox)
			end

			tempOutfit[modeData.field] = randomColorBox.colorId
		end
	end

	window:recursiveGetChildById("creature"):setOutfit(tempOutfit)
end

function rotateOutfitLeft()
	rotateWidgetPreview("creature", -1)
end

function rotateOutfitRight()
	rotateWidgetPreview("creature", 1)
end

function rotateMountLeft()
	rotateWidgetPreview("mount", -1)
end

function rotateMountRight()
	rotateWidgetPreview("mount", 1)
end

function destroy()
	if window then
		window:destroy()

		window = nil

		if colorModeGroup then
			colorModeGroup:destroy()

			colorModeGroup = nil
		end

		if colorBoxGroup then
			colorBoxGroup:destroy()

			colorBoxGroup = nil
		end

		colorBoxes = {}
		currentColorBox = nil
		currentOutfitIndex = 1
		currentMountIndex = 0
	end
end

function accept()
	if not window then
		return
	end

	tempOutfit.mount = tempMount

	g_game.changeOutfit(tempOutfit)
	destroy()
end
