local window, previousType, currentType
local bestiaryPanel

function init()
	
	-- The rest
	connect(g_game, { 
		onEnterGame = registerBestiaryProtocol,
		onPendingGame = registerBestiaryProtocol,
		onGameStart = registerBestiaryProtocol,
		onGameEnd = onCiclopediaGameEnd
	})
	if registerBestiaryProtocol then
		registerBestiaryProtocol()
	end
    
	g_ui.importStyle('styles/bestiary_tracker')
	window 	   = g_ui.displayUI('ciclopedia')
	
  ciclopediaButton = modules.client_topmenu.addRightGameToggleButton('ciclopediaButton', tr('Ciclopedia'), '/images/topbuttons/ciclopedia', toggle, false, 8)
	contentContainer = window:recursiveGetChildById('contentContainer')
	buttonSelection = window:recursiveGetChildById('buttonSelection')
		items = buttonSelection:recursiveGetChildById('items')
		bestiary = buttonSelection:recursiveGetChildById('bestiary')
		charms = buttonSelection:recursiveGetChildById('charms')
		map = buttonSelection:recursiveGetChildById('map')
		houses = buttonSelection:recursiveGetChildById('houses')
		character = buttonSelection:recursiveGetChildById('character')
end

function terminate()
	disconnect(g_game, { 
		onEnterGame = registerBestiaryProtocol,
		onPendingGame = registerBestiaryProtocol,
		onGameStart = registerBestiaryProtocol,
		onGameEnd = onCiclopediaGameEnd
	})
	
	-- Internal protocols
	-- disconnect(g_game, {onEnterGame = registerBestiaryProtocol, onPendingGame = registerBestiaryProtocol})
	
	-- Hooked opcodes
	ProtocolGame.unregisterOpcode(0x29)
	if terminateBestiary then
		terminateBestiary()
	elseif unregisterBestiaryProtocol then
		unregisterBestiaryProtocol()
	else
		ProtocolGame.unregisterOpcode(CyclopediaOpcode and CyclopediaOpcode.Send or 0x39)
	end
	window:destroy()
	
	if buyWindow then
		buyWindow:destroy()
	end
end

function getContentContainer()
	return contentContainer
end

function getCurrentType()
	return currentType
end

function onCiclopediaGameEnd()
	if window then
		window:hide()
	end
end

function toggle()
	if window:isVisible() then
		window:hide()
	else
		toggleWindow("items") -- We init on items
		window:show()
		window:raise()
		window:focus()
	end
end

function emptyContentContainer()
	while contentContainer:getChildCount() > 0 do
		local child = contentContainer:getLastChild()
		contentContainer:destroyChildren(child)
	end
end

function changePreviousType(type)
	previousType = type
end

function toggleWindow(type)
	if previousType then
		previousType:enable()
		previousType:setOn(false)
	end
	
	-- We empty the container
	emptyContentContainer()
	currentType = type
		
	if (type == "items") then
		items:setOn(true)
		items:disable()
		changePreviousType(items)
	elseif (type == "bestiary") then
		bestiary:setOn(true)
		bestiary:disable()
		changePreviousType(bestiary)
		
		-- Setup the widget
		initBestiary(contentContainer)
	elseif (type == "charms") then
		charms:setOn(true)
		charms:disable()
		changePreviousType(charms)
		
		-- Setup the charms
		initCharms(contentContainer)
	elseif (type == "map") then
		map:setOn(true)
		map:disable()
		changePreviousType(map)
		
		-- Setup the widget
		initMap(contentContainer)
	elseif (type == "houses") then
		houses:setOn(true)
		houses:disable()
		changePreviousType(houses)
	elseif (type == "character") then
		character:setOn(true)
		character:disable()
		changePreviousType(character)
	end
end
