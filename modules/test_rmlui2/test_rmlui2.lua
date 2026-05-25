TestRmlUi2 = {}
TestRmlUi2.windowWidth = 460
TestRmlUi2.windowHeight = 300
TestRmlUi2.contentLeft = 16
TestRmlUi2.contentTop = 35

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

function TestRmlUi2.init()
  TestRmlUi2.clicks = 0
end

function TestRmlUi2.open()
  if TestRmlUi2.doc and TestRmlUi2.doc ~= 0 then return end

  TestRmlUi2.clicks = 0

  TestRmlUi2.window = g_ui.createWidget("Window", getDefaultRmlUiParent())
  TestRmlUi2.window:setId("rmlUi2TestWindow")
  TestRmlUi2.window:setText("HTML Test")
  TestRmlUi2.window:resize(TestRmlUi2.windowWidth, TestRmlUi2.windowHeight)
  TestRmlUi2.window.htmlTitleDragOnly = true
  TestRmlUi2.window.htmlTitleDragHeight = 32
  TestRmlUi2.window.onGeometryChange = function()
    TestRmlUi2.syncToWindow()
  end
  TestRmlUi2.scheduleCenter()

  local size = g_window.getSize()
  g_rmlui.createContext("test_html_port", size.width, size.height)
  g_rmlui.loadFontFace("/modules/test_rmlui/arial.ttf")
  g_rmlui.createDataModel("test_html_port", "testhtml", { clicks = 0, status = "Waiting for click" })

  local doc = g_rmlui.loadDocument("/modules/test_rmlui2/test.rml", "test_html_port")
  if doc == 0 then
    g_logger.error("[TestRmlUi2] Failed to load document")
    TestRmlUi2.close()
    return
  end

  TestRmlUi2.doc = doc
  TestRmlUi2.syncToWindow()

  local btn = g_rmlui.getElementById(doc, "clickButton")
  if btn ~= 0 then
    g_rmlui.addEventListener(btn, "click", "TestRmlUi2.onClick()")
  end

  local closeBtn = g_rmlui.getElementById(doc, "closeButton")
  if closeBtn ~= 0 then
    g_rmlui.addEventListener(closeBtn, "click", "TestRmlUi2.close()")
  end
end

function TestRmlUi2.centerWindow()
  local window = TestRmlUi2.window
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
  TestRmlUi2.syncToWindow()
end

function TestRmlUi2.scheduleCenter()
  TestRmlUi2.centerWindow()

  for _, delay in ipairs({ 1, 10, 50 }) do
    scheduleEvent(function()
      TestRmlUi2.centerWindow()
    end, delay)
  end
end

function TestRmlUi2.syncToWindow()
  local doc = TestRmlUi2.doc
  if not doc or doc == 0 then return end
  if not TestRmlUi2.window or TestRmlUi2.window:isDestroyed() then return end

  local content = g_rmlui.getElementById(doc, "content")
  if content == 0 then return end

  local x, y = getAbsolutePosition(TestRmlUi2.window)
  g_rmlui.setProperty(content, "left", (x + TestRmlUi2.contentLeft) .. "px")
  g_rmlui.setProperty(content, "top", (y + TestRmlUi2.contentTop) .. "px")
end

function TestRmlUi2.onClick()
  TestRmlUi2.clicks = TestRmlUi2.clicks + 1
  g_rmlui.setModelVar("testhtml", "clicks", TestRmlUi2.clicks)
  g_rmlui.setModelVar("testhtml", "status",
    TestRmlUi2.clicks == 0 and "Waiting for click" or "Button clicked successfully")

  local doc = TestRmlUi2.doc
  if doc and doc ~= 0 then
    local statusLabel = g_rmlui.getElementById(doc, "statusLabel")
    if statusLabel ~= 0 then
      g_rmlui.setInnerRML(statusLabel, g_rmlui.getModelVar("testhtml", "status"))
    end
    local counterLabel = g_rmlui.getElementById(doc, "counterLabel")
    if counterLabel ~= 0 then
      g_rmlui.setInnerRML(counterLabel, "Clicks: " .. tostring(TestRmlUi2.clicks))
    end
  end
end

function TestRmlUi2.close()
  if TestRmlUi2.doc and TestRmlUi2.doc ~= 0 then
    g_rmlui.closeDocument(TestRmlUi2.doc)
    TestRmlUi2.doc = 0
  end
  if TestRmlUi2.window and not TestRmlUi2.window:isDestroyed() then
    TestRmlUi2.window:destroy()
  end
  TestRmlUi2.window = nil
  g_rmlui.removeContext("test_html_port")
end

function TestRmlUi2.toggle()
  if TestRmlUi2.doc and TestRmlUi2.doc ~= 0 then
    TestRmlUi2.close()
  else
    TestRmlUi2.open()
  end
end

function TestRmlUi2.terminate()
  TestRmlUi2.close()
  g_logger.info("[TestRmlUi2] Module unloaded")
end
