TestRmlUi = {}
TestRmlUi.windowWidth = 460
TestRmlUi.windowHeight = 300
TestRmlUi.contentLeft = 16
TestRmlUi.contentTop = 35

local function getDefaultRmlUiParent()
  if modules and modules.game_interface and modules.game_interface.getRootPanel then
    local panel = modules.game_interface.getRootPanel()
    if panel and not panel:isDestroyed() then
      return panel
    end
  end
  return rootWidget or g_ui.getRootWidget()
end

local function getAbsolutePosition(widget)
  local x, y = 0, 0
  while widget do
    x = x + widget:getX()
    y = y + widget:getY()
    widget = widget:getParent()
  end
  return x, y
end

local function clamp(value, minValue, maxValue)
  if value < minValue then return minValue end
  if value > maxValue then return maxValue end
  return value
end

function TestRmlUi.init()
  TestRmlUi.clicks = 0
  TestRmlUi.statusText = "Waiting for click"

  TestRmlUi.window = g_ui.createWidget("Window", getDefaultRmlUiParent())
  TestRmlUi.window:setId("rmlUiTestWindow")
  TestRmlUi.window:setText("HTML Test")
  TestRmlUi.window:resize(TestRmlUi.windowWidth, TestRmlUi.windowHeight)
  TestRmlUi.window.htmlTitleDragOnly = true
  TestRmlUi.window.htmlTitleDragHeight = 32
  TestRmlUi.window.onGeometryChange = function()
    TestRmlUi.syncToWindow()
  end
  TestRmlUi.scheduleCenter()

  g_rmlui.loadFontFace("/modules/test_rmlui/arial.ttf")
  local size = g_window.getSize()
  local w, h = size.width, size.height
  g_rmlui.createContext("test", w, h)
  TestRmlUi.contextOpen = true

  g_rmlui.createDataModel("test", "clicks", { count = 0 })

  local doc = g_rmlui.loadDocument("/modules/test_rmlui/test.rml", "test")
  if doc == 0 then
    g_logger.error("[TestRmlUi] Failed to load document")
    TestRmlUi.close()
    return
  end

  TestRmlUi.doc = doc
  TestRmlUi.modelName = "clicks"
  TestRmlUi.syncToWindow()

  local btn = g_rmlui.getElementById(doc, "clickButton")
  if btn ~= 0 then
    g_rmlui.addEventListener(btn, "click", "TestRmlUi.onClick()")
  end

  local closeBtn = g_rmlui.getElementById(doc, "closeButton")
  if closeBtn ~= 0 then
    g_rmlui.addEventListener(closeBtn, "click", "TestRmlUi.close()")
  end

  g_logger.info("[TestRmlUi] Module loaded")
end

function TestRmlUi.centerWindow()
  local window = TestRmlUi.window
  if not window or window:isDestroyed() then return end
  local parent = window:getParent()
  if not parent or parent:isDestroyed() then return end

  window:show()
  window:updateParentLayout()
  window:updateLayout()

  if window.breakAnchors then
    pcall(function() window:breakAnchors() end)
  end

  local anchored = false
  if window.addAnchor then
    anchored = pcall(function()
      window:addAnchor(AnchorHorizontalCenter, "parent", AnchorHorizontalCenter)
      window:addAnchor(AnchorVerticalCenter, "parent", AnchorVerticalCenter)
    end)
  end

  if not anchored then
    local parentWidth = parent:getWidth()
    local parentHeight = parent:getHeight()
    local width = window:getWidth()
    local height = window:getHeight()

    if parentWidth > 0 and parentHeight > 0 and width > 0 and height > 0 then
      local maxX = math.max(0, parentWidth - width)
      local maxY = math.max(0, parentHeight - height)
      window:setPosition({
        x = clamp(math.floor((parentWidth - width) / 2), 0, maxX),
        y = clamp(math.floor((parentHeight - height) / 2), 0, maxY)
      })
    end
  end

  if window.bindRectToParent then
    pcall(function() window:bindRectToParent() end)
  end

  window:raise()
  window:focus()
  TestRmlUi.syncToWindow()
end

function TestRmlUi.scheduleCenter()
  TestRmlUi.centerWindow()

  for _, delay in ipairs({ 1, 10, 50 }) do
    scheduleEvent(function()
      TestRmlUi.centerWindow()
    end, delay)
  end
end

function TestRmlUi.syncToWindow()
  local doc = TestRmlUi.doc
  if not doc or doc == 0 then return end
  if not TestRmlUi.window or TestRmlUi.window:isDestroyed() then return end

  local content = g_rmlui.getElementById(doc, "content")
  if content == 0 then return end

  local x, y = getAbsolutePosition(TestRmlUi.window)
  g_rmlui.setProperty(content, "left", (x + TestRmlUi.contentLeft) .. "px")
  g_rmlui.setProperty(content, "top", (y + TestRmlUi.contentTop) .. "px")
end

function TestRmlUi.updateLabels()
  local doc = TestRmlUi.doc
  if not doc or doc == 0 then return end

  local statusLabel = g_rmlui.getElementById(doc, "statusLabel")
  if statusLabel ~= 0 then
    g_rmlui.setInnerRML(statusLabel, TestRmlUi.statusText)
  end

  local counterLabel = g_rmlui.getElementById(doc, "counterLabel")
  if counterLabel ~= 0 then
    g_rmlui.setInnerRML(counterLabel, "Clicks: " .. tostring(TestRmlUi.clicks))
  end

  local clickButton = g_rmlui.getElementById(doc, "clickButton")
  if clickButton ~= 0 then
    g_rmlui.setInnerRML(clickButton, TestRmlUi.clicks == 0 and "Click" or "Click again")
  end
end

function TestRmlUi.onClick()
  TestRmlUi.clicks = TestRmlUi.clicks + 1
  TestRmlUi.statusText = "Button clicked successfully"

  g_dispatcher.addEvent(function()
    TestRmlUi.updateLabels()
  end)
end

function TestRmlUi.close()
  if TestRmlUi.doc and TestRmlUi.doc ~= 0 then
    g_rmlui.closeDocument(TestRmlUi.doc)
    TestRmlUi.doc = 0
  end
  if TestRmlUi.window and not TestRmlUi.window:isDestroyed() then
    TestRmlUi.window:destroy()
  end
  TestRmlUi.window = nil
  if TestRmlUi.contextOpen then
    g_rmlui.removeContext("test")
    TestRmlUi.contextOpen = false
  end
end

function TestRmlUi.terminate()
  TestRmlUi.close()
  g_logger.info("[TestRmlUi] Module unloaded")
end
