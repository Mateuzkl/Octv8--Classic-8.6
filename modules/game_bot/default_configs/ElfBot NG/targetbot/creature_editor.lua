TargetBot.Creature.edit = function(config, callback) -- callback = function(newConfig)
  config = config or {}

  local editor = UI.createWindow('TargetBotCreatureEditorWindow')
  local values = {} -- (key, function returning value of key)
  local nameEdit = editor:recursiveGetChildById('name')
  local okButton = editor:recursiveGetChildById('ok')
  local cancelButton = editor:recursiveGetChildById('cancel')
  local priorityGroup = editor:recursiveGetChildById('priorityGroup') or editor
  local selectionGroup = editor:recursiveGetChildById('selectionGroup') or editor
  local leftPanel = priorityGroup and priorityGroup:recursiveGetChildById('left')
  local rightPanel = selectionGroup and selectionGroup:recursiveGetChildById('right')

  if not nameEdit or not okButton or not cancelButton or not leftPanel or not rightPanel then
    editor:destroy()
    if warn then
      warn("TargetBot creature editor layout is missing required widgets")
    end
    return
  end

  nameEdit:setText(config.name or "")
  table.insert(values, {"name", function() return nameEdit:getText() end})

  local addScrollBar = function(id, title, min, max, defaultValue)
    local widget = UI.createWidget('TargetBotCreatureEditorScrollBar', leftPanel)
    widget.scroll.onValueChange = function(scroll, value)
      widget.text:setText(title .. ": " .. value)
    end
    widget.scroll:setRange(min, max)
    if max-min > 1000 then
      widget.scroll:setStep(100)
    elseif max-min > 100 then
      widget.scroll:setStep(10)
    end
    widget.scroll:setValue(config[id] or defaultValue)
    widget.scroll.onValueChange(widget.scroll, widget.scroll:getValue())
    table.insert(values, {id, function() return widget.scroll:getValue() end})
  end

  local addTextEdit = function(id, title, defaultValue)
    local widget = UI.createWidget('TargetBotCreatureEditorTextEdit', rightPanel)
    widget.text:setText(title)
    widget.textEdit:setText(config[id] or defaultValue or "")
    table.insert(values, {id, function() return widget.textEdit:getText() end})
  end

  local addCheckBox = function(id, title, defaultValue)
    local widget = UI.createWidget('TargetBotCreatureEditorCheckBox', rightPanel)
    widget.onClick = function()
      widget:setOn(not widget:isOn())
    end
    widget:setText(title)
    if config[id] == nil then
      widget:setOn(defaultValue)
    else
      widget:setOn(config[id])
    end
    table.insert(values, {id, function() return widget:isOn() end})
  end

  local addItem = function(id, title, defaultItem)
    local widget = UI.createWidget('TargetBotCreatureEditorItem', rightPanel)
    widget.text:setText(title)
    widget.item:setItemId(config[id] or defaultItem)
    table.insert(values, {id, function() return widget.item:getItemId() end})
  end

  cancelButton.onClick = function()
    editor:destroy()
  end
  editor.onEscape = cancelButton.onClick

  okButton.onClick = function()
    local newConfig = {}
    for _, value in ipairs(values) do
      newConfig[value[1]] = value[2]()
    end
    if newConfig.name:len() < 1 then return end

    newConfig.regex = ""
    for part in string.gmatch(newConfig.name, "[^,]+") do
      if newConfig.regex:len() > 0 then
        newConfig.regex = newConfig.regex .. "|"
      end
      newConfig.regex = newConfig.regex .. "^" .. part:trim():lower():gsub("%*", ".*"):gsub("%?", ".?") .. "$"
    end

    editor:destroy()
    callback(newConfig)
  end

  -- values
  addScrollBar("priority", "Priority", 0, 10, 1)
  addScrollBar("danger", "Danger", 0, 10, 1)
  addScrollBar("maxDistance", "Max distance", 1, 10, 10)
  addScrollBar("keepDistanceRange", "Keep distance", 1, 5, 1)
  addScrollBar("anchorRange", "Anchoring Range", 1, 10, 3)
  addScrollBar("lureCount", "Classic Lure", 0, 5, 1)
  addScrollBar("lureMin", "Dynamic lure min", 0, 29, 1)
  addScrollBar("lureMax", "Dynamic lure max", 1, 30, 3)
  addScrollBar("lureDelay", "Dynamic lure delay", 100, 1000, 250)
  addScrollBar("delayFrom", "Start delay when monsters", 1, 29, 2)
  addScrollBar("rePositionAmount", "Min tiles to rePosition", 0, 7, 5)
  addScrollBar("closeLureAmount", "Close Pull Until", 0, 8, 3)

  addCheckBox("chase", "Chase", true)
  addCheckBox("keepDistance", "Keep Distance", false)
  addCheckBox("anchor", "Anchoring", false)
  addCheckBox("dontLoot", "Don't loot", false)
  addCheckBox("lure", "Lure", false)
  addCheckBox("lureCavebot", "Lure using cavebot", false)
  addCheckBox("faceMonster", "Face monsters", false)
  addCheckBox("avoidAttacks", "Avoid wave attacks", false)
  addCheckBox("dynamicLure", "Dynamic lure", false)
  addCheckBox("dynamicLureDelay", "Dynamic lure delay", false)
  addCheckBox("diamondArrows", "D-Arrows priority", false)
  addCheckBox("rePosition", "rePosition to better tile", false)
  addCheckBox("closeLure", "Close Pulling Monsters", false)
  addCheckBox("rpSafe", "RP PVP SAFE - (DA)", false)
end
