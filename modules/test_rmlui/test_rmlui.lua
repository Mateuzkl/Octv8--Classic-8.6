TestRmlUi = {}

function TestRmlUi.init()
  g_rmlui.init()
  g_rmlui.loadFontFace("data/fonts/Maferic.ttf")
  local size = g_window.getSize()
  local w, h = size.width, size.height
  g_rmlui.createContext("test", w, h)

  g_rmlui.createDataModel("test", "clicks", { count = 0 })

  local doc = g_rmlui.loadDocument("/modules/test_rmlui/test.rml", "test")
  if doc == 0 then
    g_logger.error("[TestRmlUi] Failed to load document")
    return
  end

  TestRmlUi.doc = doc
  TestRmlUi.modelName = "clicks"

  local btn = g_rmlui.getElementById(doc, "click-btn")
  if btn ~= 0 then
    g_rmlui.addEventListener(btn, "click", "TestRmlUi.onClick()")
  end

  g_logger.info("[TestRmlUi] Module loaded")
end

function TestRmlUi.onClick()
  TestRmlUi.clicks = TestRmlUi.clicks + 1

  g_dispatcher.addEvent(function()
    local doc = TestRmlUi.doc
    if not doc or doc == 0 then return end
    local label = g_rmlui.getElementById(doc, "click-label")
    if label ~= 0 then
      g_rmlui.setInnerRML(label, "Clicks: " .. TestRmlUi.clicks)
    end
  end)
end
end

function TestRmlUi.terminate()
  if TestRmlUi.doc and TestRmlUi.doc ~= 0 then
    g_rmlui.closeDocument(TestRmlUi.doc)
  end
  g_rmlui.removeContext("test")
  g_rmlui.terminate()
  g_logger.info("[TestRmlUi] Module unloaded")
end
