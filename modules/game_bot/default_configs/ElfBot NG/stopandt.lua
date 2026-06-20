local ICON_SIZE = { height = 46, width = 58 }
local ICON_FONT = "verdana-11px-rounded"

local function isObjectLike(value)
  local valueType = type(value)
  return valueType == "table" or valueType == "userdata"
end

local function safeCall(fn, fallback)
  if type(fn) ~= "function" then
    return fallback
  end

  local ok, result = pcall(fn)
  if ok and result ~= nil then
    return result
  end
  return fallback
end

local function safeRun(fn)
  if type(fn) == "function" then
    pcall(fn)
  end
end

local function isBotOn(api)
  if not isObjectLike(api) then
    return false
  end
  if type(api.isOn) == "function" then
    return safeCall(api.isOn, false) == true
  end
  if type(api.isOff) == "function" then
    return safeCall(api.isOff, true) ~= true
  end
  return false
end

local function setBotState(api, enabled)
  if not isObjectLike(api) then
    return
  end
  if enabled then
    safeRun(api.setOn)
  else
    safeRun(api.setOff)
  end
end

local function toggleBot(api)
  setBotState(api, not isBotOn(api))
end

local function getElfLanguage()
  if type(ImperialElfBot_GetLanguage) == "function" then
    local ok, language = pcall(ImperialElfBot_GetLanguage)
    if ok and tostring(language):lower() == "en" then
      return "en"
    end
  end
  if type(storage) == "table" and tostring(storage.elfbotLanguage):lower() == "en" then
    return "en"
  end
  return "en"
end

local function setTooltipPair(widget, ptText, enText)
  if not widget or not widget.setTooltip then
    return
  end

  local text = getElfLanguage() == "en" and (enText or ptText) or ptText
  widget:setTooltip(tostring(text or ""))
end

local function styleStatusIcon(icon)
  if not icon then
    return
  end

  icon:setSize(ICON_SIZE)

  if icon.text then
    icon.text:setFont(ICON_FONT)

    local centerAlign = AlignCenter or AlignHCenter
    if centerAlign and icon.text.setTextAlign then
      icon.text:setTextAlign(centerAlign)
    end
    if icon.text.setHeight then
      icon.text:setHeight(28)
    end
  end
end

local function createStatusIcon(id, label, ptTooltip, enTooltip, callback)
  local icon = addIcon(id, {
    text = label,
    switchable = false,
    movable = true,
    dragWithCtrl = false
  }, callback)

  styleStatusIcon(icon)
  setTooltipPair(icon, ptTooltip, enTooltip)
  if icon and icon.text then
    setTooltipPair(icon.text, ptTooltip, enTooltip)
  end

  return icon
end

local caveIcon = createStatusIcon(
  "cI",
  "CaveBot",
  "Clique para ligar/desligar o CaveBot. Arraste para mover o icone.",
  "Click to toggle CaveBot. Drag to move the icon.",
  function()
    toggleBot(CaveBot)
  end
)

local targetIcon = createStatusIcon(
  "tI",
  "Target",
  "Clique para ligar/desligar o TargetBot. Arraste para mover o icone.",
  "Click to toggle TargetBot. Drag to move the icon.",
  function()
    toggleBot(TargetBot)
  end
)

local function refreshStatusIconLanguage()
  setTooltipPair(caveIcon, "Clique para ligar/desligar o CaveBot. Arraste para mover o icone.", "Click to toggle CaveBot. Drag to move the icon.")
  setTooltipPair(caveIcon and caveIcon.text, "Clique para ligar/desligar o CaveBot. Arraste para mover o icone.", "Click to toggle CaveBot. Drag to move the icon.")
  setTooltipPair(targetIcon, "Clique para ligar/desligar o TargetBot. Arraste para mover o icone.", "Click to toggle TargetBot. Drag to move the icon.")
  setTooltipPair(targetIcon and targetIcon.text, "Clique para ligar/desligar o TargetBot. Arraste para mover o icone.", "Click to toggle TargetBot. Drag to move the icon.")
end

ImperialElfBot = ImperialElfBot or {}
ImperialElfBot.languageRefreshers = ImperialElfBot.languageRefreshers or {}
ImperialElfBot.languageRefreshers.statusIcons = refreshStatusIconLanguage

local lastCaveState
local lastTargetState

local function setIconStatus(icon, label, enabled)
  if not icon or not icon.text then
    return
  end

  icon.text:setColoredText({
    label .. "\n", "white",
    enabled and "ON" or "OFF", enabled and "green" or "red"
  })
end

local function refreshStatusIcons(force)
  local caveOn = isBotOn(CaveBot)
  if force or caveOn ~= lastCaveState then
    setIconStatus(caveIcon, "CaveBot", caveOn)
    lastCaveState = caveOn
  end

  local targetOn = isBotOn(TargetBot)
  if force or targetOn ~= lastTargetState then
    setIconStatus(targetIcon, "Target", targetOn)
    lastTargetState = targetOn
  end
end

refreshStatusIcons(true)
refreshStatusIconLanguage()

macro(250, function()
  refreshStatusIcons(false)
end)
