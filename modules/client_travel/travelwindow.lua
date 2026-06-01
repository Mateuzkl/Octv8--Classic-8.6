mainTravelWindow = nil
selectedSpell = nil
closeButton = nil
isShown = false
map = nil
searchText = nil
selectedTravelLocation = nil
choiceList = nil
shrineTab = nil
allTab = nil
spawnTab = nil
radioTabs = nil
currentType = "all"

function init()
	mainTravelWindow = g_ui.displayUI("travelUi")
	searchText = mainTravelWindow:recursiveGetChildById("searchText")
	choiceList = mainTravelWindow:getChildById("choiceList")
	map = mainTravelWindow:recursiveGetChildById("travelMap")
	shrineTab = mainTravelWindow:getChildById("shrineTab")
	shrineTab.type = "shrine"
	spawnTab = mainTravelWindow:getChildById("spawnTab")
	spawnTab.type = "spawn"
	allTab = mainTravelWindow:getChildById("allTab")
	allTab.type = "all"
	radioTabs = UIRadioGroup.create()

	radioTabs:addWidget(shrineTab)
	radioTabs:addWidget(spawnTab)
	radioTabs:addWidget(allTab)
	radioTabs:selectWidget(allTab)

	radioTabs.onSelectionChange = onTravelTypeChange

	loadMap()
	mainTravelWindow:hide()
	map:disableAutoWalk()
	connect(g_game, {
		onGameEnd = offline
	})
	connect(LocalPlayer, {
		onPositionChange = closeTravelWindow
	})
	if GameServerOpcodes.GameServerTravelWindow then
		ProtocolGame.registerOpcode(GameServerOpcodes.GameServerTravelWindow, parseTravelWindow)
	end
end

function terminate()
	mainTravelWindow:destroy()
	disconnect(LocalPlayer, {
		onPositionChange = closeTravelWindow
	})
	disconnect(g_game, {
		onGameEnd = offline
	})
	if GameServerOpcodes.GameServerTravelWindow then
		ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerTravelWindow)
	end
end

function offline()
	g_keyboard.unbindKeyPress("Down", mainTravelWindow)
	g_keyboard.unbindKeyPress("Up", mainTravelWindow)
	mainTravelWindow:hide()
end

local travelOptions = {}

function parseTravelWindow(protocol, msg)
	travelOptions = {}
	local itemsCount = msg:getU16()

	for i = 1, itemsCount do
		local n = msg:getString()
		local pos = msg:getPosition()
		local bool = msg:getU32()
		local travelType = ""

		if bool == nil then
			travelType = "all"
		elseif bool == 1 then
			travelType = "shrine"
		else
			travelType = "spawn"
		end

		table.insert(travelOptions, {
			name = n,
			pos = pos,
			isShrine = bool,
			type = travelType
		})
	end

	onTravelWindow()
end

choices = {}

function onTravelWindow()
	if #choices == 0 then
		local labelHeight = nil

		for i = 1, #travelOptions do
			local choiceId = i
			local position = travelOptions[i].pos
			local choiceName = travelOptions[i].name
			local label = g_ui.createWidget("TravelChoiceListLabel", choiceList)
			label.choiceId = choiceId
			label.name = choiceName
			label.pos = position
			label.isShrine = travelOptions[i].isShrine
			label.type = travelOptions[i].type
			label.onFocusChange = moveMapToPos

			label:setText(choiceName)
			label:setPhantom(false)

			labelHeight = labelHeight or label:getHeight()

			table.insert(choices, label)
		end

		choiceList:focusChild(choiceList:getFirstChild())
	end

	updateCameraPosition()
	g_keyboard.bindKeyPress("Down", function ()
		choiceList:focusNextChild(KeyboardFocusReason)
	end, mainTravelWindow)
	g_keyboard.bindKeyPress("Up", function ()
		choiceList:focusPreviousChild(KeyboardFocusReason)
	end, mainTravelWindow)

	isShown = true
	choiceList.onDoubleClick = confirmTravel
	mainTravelWindow.onEnter = confirmTravel
	mainTravelWindow.onEscape = closeTravelWindow

	mainTravelWindow:show()
	mainTravelWindow:focus()
end

function closeTravelWindow()
	choices = {}

	radioTabs:selectWidget(allTab)
	searchText:clearText()
	choiceList:destroyChildren()
	g_keyboard.unbindKeyPress("Down", mainTravelWindow)
	g_keyboard.unbindKeyPress("Up", mainTravelWindow)
	modules.game_interface.getRootPanel():focus()
	mainTravelWindow:hide()
end

function moveMapToPos(label, focused)
	if focused then
		local position = {
			x = travelOptions[label.choiceId].pos.x,
			y = travelOptions[label.choiceId].pos.y,
			z = travelOptions[label.choiceId].pos.z
		}

		updateCameraPosition(position)

		selectedTravelLocation = label
	end
end

function confirmTravel()
	local msg = OutputMessage.create()

	msg:addU8(ClientOpcodes.ClientSendTravel)
	msg:addPosition(selectedTravelLocation.pos)
	msg:addU32(selectedTravelLocation.isShrine)

	local p = g_game.getProtocolGame()

	p:send(msg)
	closeTravelWindow()
end

function onSearchTextChange()
	local searchFilter = searchText:getText():lower()

	for i = 1, #choices do
		local label = choiceList:getChildByIndex(i)
		local searchCondition = searchFilter == "" or searchFilter ~= "" and string.find(label.name:lower(), searchFilter) ~= nil or label.choiceId == 1

		label:setVisible(searchCondition and (currentType == "all" or label.type == currentType))
	end
end

function onTravelTypeChange(radioTabs, selected, deselected)
	selected:setOn(true)
	deselected:setOn(false)

	currentType = selected.type

	searchText:clearText()

	for i = 1, #choices do
		local label = choiceList:getChildByIndex(i)
		local searchCondition = currentType == "all" or label.choiceId == 1 or label.type == currentType

		label:setVisible(searchCondition)
	end

	choiceList:focusChild(choiceList:getFirstChild())
end

function loadMap()
	local clientVersion = g_game.getClientVersion()

	g_minimap.clean()

	loaded = false
	local characterFile = nil
	local minimapFile = "/minimap.otmm"
	local dataMinimapFile = "/data" .. minimapFile
	local versionedMinimapFile = "/minimap" .. clientVersion .. ".otmm"
	local localPlayer = g_game.getLocalPlayer()

	if localPlayer then
		local playerName = localPlayer:getName()

		if playerName then
			characterFile = "/minimap-" .. playerName .. ".otmm"
		end
	end

	if characterFile and g_resources.fileExists(characterFile) then
		loaded = g_minimap.loadOtmm(characterFile)
	end

	if not loaded and g_resources.fileExists(dataMinimapFile) then
		loaded = g_minimap.loadOtmm(dataMinimapFile)
	end

	if g_resources.fileExists(dataMinimapFile) then
		loaded = g_minimap.loadOtmm(dataMinimapFile)
	end

	if not loaded and g_resources.fileExists(versionedMinimapFile) then
		loaded = g_minimap.loadOtmm(versionedMinimapFile)
	end

	if not loaded and g_resources.fileExists(minimapFile) then
		loaded = g_minimap.loadOtmm(minimapFile)
	end

	if not loaded then
		print("Minimap couldn't be loaded, file missing?")
	end

	-- map:load()

end

function updateCameraPosition(mapPos)
	if not mapPos then
		return
	end

	map:setCameraPosition(mapPos)
	map:setCrossPosition(mapPos)
end
