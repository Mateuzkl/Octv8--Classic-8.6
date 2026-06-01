UIWindow = extends(UIWidget, "UIWindow")

local function isTitleDragArea(window, mousePos)
	if not window.htmlTitleDragOnly then
		return true
	end

	if not mousePos then
		return false
	end

	local titleHeight = window.htmlTitleDragHeight or 32
	local localY = mousePos.y - window:getY()

	return localY >= 0 and localY <= titleHeight
end

function UIWindow.create()
	local window = UIWindow.internalCreate()

	window:setTextAlign(AlignTopCenter)
	window:setDraggable(true)
	window:setAutoFocusPolicy(AutoFocusFirst)

	return window
end

function UIWindow:onKeyDown(keyCode, keyboardModifiers)
	if keyboardModifiers == KeyboardNoModifier then
		if keyCode == KeyEnter then
			signalcall(self.onEnter, self)
		elseif keyCode == KeyEscape then
			if g_game and g_game.isOnline and g_game.isOnline() then
				return false
			end

			signalcall(self.onEscape, self)
		end
	end
end

function UIWindow:onFocusChange(focused)
	if focused then
		self:raise()
	end
end

function UIWindow:onDragEnter(mousePos)
	if self.static then
		return false
	end

	if not isTitleDragArea(self, mousePos) then
		return false
	end

	self:breakAnchors()

	self.movingReference = {
		x = mousePos.x - self:getX(),
		y = mousePos.y - self:getY()
	}

	return true
end

function UIWindow:onDragLeave(droppedWidget, mousePos)
end

function UIWindow:onDragMove(mousePos, mouseMoved)
	if self.static then
		return
	end

	local pos = {
		x = mousePos.x - self.movingReference.x,
		y = mousePos.y - self.movingReference.y
	}

	self:setPosition(pos)
	self:bindRectToParent()
end
