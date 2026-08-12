local context = G.botContext

local iconsWithoutPosition = 0

context.addIcon = function(id, options, callback)
--[[
  Available options:
    item: {id=2160, count=100}
    outfit: outfit table ({})
    text: string
    x: float (0.0 - 1.0)
    y: float (0.0 - 1.0)
    hotkey: string
    switchable: true / false [default: true]
    movable: true / false [default: true]
    dragWithCtrl: true / false [default: true]
    phantom: true / false [default: false]
]]--
  local panel = modules.game_interface.gameMapPanel
  if type(id) ~= "string" or id:len() < 1 then
    return context.error("Invalid id for addIcon")
  end
  if options.switchable == false and type(callback) ~= 'function' then
    return context.error("Invalid callback for addIcon")
  end
  if type(context.storage._icons) ~= "table" then
    context.storage._icons = {}
  end
  if type(context.storage._icons[id]) ~= "table" then
    context.storage._icons[id] = {}
  end
  local config = context.storage._icons[id]  
  local widget = g_ui.createWidget("BotIcon", panel)
  widget.botWidget = true
  widget.botIcon = true

  if type(config.x) ~= 'number' or type(config.y) ~= 'number' then
    local defaultX
    local defaultY
    if type(options.x) == 'number' and type(options.y) == 'number' then
      defaultX = math.min(1.0, math.max(0.0, options.x))
      defaultY = math.min(1.0, math.max(0.0, options.y))
    else
      defaultX = 0.01 + math.floor(iconsWithoutPosition / 5) / 10
      defaultY = 0.05 + (iconsWithoutPosition % 5) / 5
      iconsWithoutPosition = iconsWithoutPosition + 1
    end
    config.x = type(config.x) == 'number' and config.x or defaultX
    config.y = type(config.y) == 'number' and config.y or defaultY
  end

  if options.item then
    if type(options.item) == 'number' then
      widget.item:setItemId(options.item)
    else
      widget.item:setItemId(options.item.id)
      widget.item:setItemCount(options.item.count or 1)
      widget.item:setShowCount(false)
    end
  end
  
  if options.outfit then
    widget.creature:setOutfit(options.outfit)
  end

  if options.switchable == false then
    widget.status:hide()
    widget.status:setOn(true)
  else
    if config.enabled ~= true then
      config.enabled = false
    end
    widget.status:setOn(config.enabled)
  end
  
  if options.text then
    if options.switchable ~= false then
      widget.status:hide()
      if widget.status:isOn() then
        widget.text:setColor('green')
      else
        widget.text:setColor('red')
      end
    end
    widget.text:setText(options.text)    
  end
  
  widget.setOn = function(val)
    widget.status:setOn(val)
    if widget.status:isOn() then
      widget.text:setColor('green')
    else
      widget.text:setColor('red')
    end
    config.enabled = widget.status:isOn()  
  end
  
  widget.onClick = function(widget)
    if options.switchable ~= false then
      widget.setOn(not widget.status:isOn())
      if type(callback) == 'table' then
        callback.setOn(config.enabled)
        return
      end
    end
      
    callback(widget, widget.status:isOn())
  end
  
  if options.hotkey then
    widget.hotkey:setText(options.hotkey)
    context.hotkey(options.hotkey, "", function()
      widget:onClick()
    end, nil, options.switchable ~= false)
  else
    widget.hotkey:hide()
  end

  local function updateIconPosition(widget, saveImmediately)
    local parent = widget:getParent()
    local parentRect = parent:getRect()
    local width = parentRect.width - widget:getWidth()
    local height = parentRect.height - widget:getHeight()
    if width <= 0 or height <= 0 then
      return false
    end

    local x = widget:getX() - parentRect.x
    local y = widget:getY() - parentRect.y
    config.x = math.min(1, math.max(0, x / width))
    config.y = math.min(1, math.max(0, y / height))

    widget:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
    widget:addAnchor(AnchorVerticalCenter, 'parent', AnchorVerticalCenter)
    widget:setMarginTop(math.max(height * (-0.5) - parent:getMarginTop(), height * (-0.5 + config.y)))
    widget:setMarginLeft(width * (-0.5 + config.x))

    if saveImmediately and type(context.saveConfig) == 'function' then
      pcall(context.saveConfig)
    end
    return true
  end

  local function applyIconPosition(widget)
    local parent = widget:getParent()
    local parentRect = parent:getRect()
    local width = parentRect.width - widget:getWidth()
    local height = parentRect.height - widget:getHeight()
    if width <= 0 or height <= 0 then
      return
    end
    widget:setMarginTop(math.max(height * (-0.5) - parent:getMarginTop(), height * (-0.5 + config.y)))
    widget:setMarginLeft(width * (-0.5 + config.x))
  end

  if options.movable ~= false and options.moveable ~= false then
    widget.onDragEnter = function(widget, mousePos)
      local dragRequiresCtrl = options.dragWithCtrl ~= false and options.moveWithCtrl ~= false
      if dragRequiresCtrl and not g_keyboard.isCtrlPressed() then
        return false
      end
      widget:breakAnchors()
      widget.movingReference = { x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY() }
      widget.iconPositionChanged = false
      return true
    end

    widget.onDragMove = function(widget, mousePos, moved)
      local parentRect = widget:getParent():getRect()
      local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width - widget:getWidth())
      local y = math.min(math.max(parentRect.y - widget:getParent():getMarginTop(), mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())
      widget:move(x, y)
      widget.iconPositionChanged = moved ~= false
      return true
    end

    widget.onDragLeave = function(widget, pos)
      updateIconPosition(widget, widget.iconPositionChanged == true)
      widget.iconPositionChanged = false
      return true
    end
  end

  widget.onGeometryChange = function(widget)
    if widget:isDragging() then return end
    applyIconPosition(widget)
  end

  applyIconPosition(widget)

  if options.phantom ~= true then
    widget.onMouseRelease = function(widget)
      if widget.iconPositionChanged then
        updateIconPosition(widget, true)
        widget.iconPositionChanged = false
      end
      return true 
    end
  end
  
  if options.switchable ~= false then 
    if type(callback) == 'table' then
      callback.setOn(config.enabled)
      callback.icon = widget
    else
      callback(widget, widget.status:isOn())    
    end
  end
  return widget
end
