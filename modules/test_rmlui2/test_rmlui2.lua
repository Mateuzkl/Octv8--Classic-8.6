TestRmlUi2 = {}

function TestRmlUi2.init()
  TestRmlUi2.clicks = 0
end

function TestRmlUi2.open()
  if TestRmlUi2.doc and TestRmlUi2.doc ~= 0 then return end

  local size = g_window.getSize()
  g_rmlui.createContext("test_html_port", size.width, size.height)
  g_rmlui.loadFontFace("data/fonts/Maferic.ttf")
  g_rmlui.createDataModel("test_html_port", "testhtml", { clicks = 0, status = "Waiting for click" })

  local doc = g_rmlui.loadDocument("/modules/test_rmlui2/test.rml", "test_html_port")
  if doc == 0 then
    g_logger.error("[TestRmlUi2] Failed to load document")
    g_rmlui.removeContext("test_html_port")
    return
  end

  TestRmlUi2.doc = doc

  local btn = g_rmlui.getElementById(doc, "clickButton")
  if btn ~= 0 then
    g_rmlui.addEventListener(btn, "click", "TestRmlUi2.onClick()")
  end

  local closeBtn = g_rmlui.getElementById(doc, "closeButton")
  if closeBtn ~= 0 then
    g_rmlui.addEventListener(closeBtn, "click", "TestRmlUi2.close()")
  end
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
