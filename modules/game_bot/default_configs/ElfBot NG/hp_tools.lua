-- ============================================
-- SOULEWORKER.LUA - SISTEMA INDEPENDENTE
-- Storage proprio para cada subsistema
-- ============================================

setDefaultTab("Main")

-- ====================================
-- HP/TOOLS SYSTEM
-- Arquivo: 3novohp.lua
-- Compativel com Yasu Encryptor
-- Otimizado para maxima performance
-- ====================================

-- Sistema de standby: pausa macros de cura enquanto HP/Mana estao estaveis
local standByHealing = false
local lastHealingWake = now or (g_clock and g_clock.millis and g_clock.millis()) or 0

local function healingTimeNow()
  return now or (g_clock and g_clock.millis and g_clock.millis()) or 0
end

local function wakeHealing(reason)
  standByHealing = false
  lastHealingWake = healingTimeNow()
end

onPlayerHealthChange(function()
  wakeHealing("hpChange")
end)

onManaChange(function()
  wakeHealing("manaChange")
end)

-- Watchdog: se ficar em standby por muito tempo (eventos de HP/Mana perdidos), reativa o macro.
macro(500, function()
  if not storage.healingSystemEnabled then return end
  if not standByHealing then
    lastHealingWake = healingTimeNow()
    return
  end

  if healingTimeNow() - lastHealingWake >= 2000 then
    wakeHealing("watchdog")
  end
end)

-- Estilos base da UI do HP/Tools
g_ui.loadUIFromString([[
CategoryCheckBox < CheckBox
  font: verdana-11px-rounded
  margin-top: 0
  height: 18
  focusable: true
  phantom: false

tPanel < Panel
  margin: 3

  ScrollablePanel
    id: panelContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-left: 8
    margin-right: 8
    padding-top: 8
    padding-bottom: 8
    layout:
      type: verticalBox
      spacing: 5

HealingMainWindow < MainWindow
  !text: tr('HP/Tools by Kelus Scripts')
  size: 715 616
  visible: false
  @onEscape: self:hide()

  TabBar
    id: tabs
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 25
    tab-spacing: 2

  Panel
    id: content
    anchors.top: tabs.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonPanel.top
    margin-top: 5
    margin-left: 10
    margin-right: 10

  Panel
    id: buttonPanel
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 24
    margin: 5
    layout:
      type: horizontalBox
      spacing: 6

    Button
      id: helpButton
      text: Ajuda / Help
      size: 80 18

    Button
      id: closeButton
      text: Fechar
      size: 80 18
      @onClick: self:getParent():getParent():hide()

  ResizeBorder
    id: bottomResizeBorder
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 3
    minimum: 250
    maximum: 900
    margin-left: 5
    margin-right: 5
    background: #4e4e4e

  ResizeBorder
    id: rightResizeBorder
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: 3
    minimum: 520
    maximum: 900
    margin-top: 5
    margin-bottom: 5
    background: #4e4e4e

HealingHelpWindow < MainWindow
  !text: tr('HP/Tools Help')
  size: 720 560
  visible: false
  @onEscape: self:hide()

  Panel
    id: helpContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonPanel.top
    margin-top: 6
    margin-left: 8
    margin-right: 8

    VerticalScrollBar
      id: helpScroll
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      step: 28
      pixels-scroll: true

    ScrollablePanel
      id: helpScrollContent
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-right: 10
      padding-top: 3
      padding-bottom: 3
      padding-left: 4
      vertical-scrollbar: helpScroll
      layout:
        type: verticalBox
        spacing: 4

      Label
        id: helpTextLabel
        width: 680
        text-align: left
        text-wrap: true
        multiline: true
        text-auto-resize: true
        text: ""

  Panel
    id: buttonPanel
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 24
    margin: 5
    layout:
      type: horizontalBox
      spacing: 6

    Button
      id: closeButton
      text: Fechar
      size: 80 18
      @onClick: self:getParent():getParent():hide()
]])

local function cleanNumericKeys(storageTable)
  if type(storageTable) == "table" then
    for i = 1, 100 do
      if storageTable[i] then
        storageTable[i] = nil
      end
    end
  end
end

cleanNumericKeys(storage.healing1)
cleanNumericKeys(storage.healing2)
cleanNumericKeys(storage.healing3)
cleanNumericKeys(storage.hpitem1)
cleanNumericKeys(storage.hpitem2)
cleanNumericKeys(storage.hpitem3)
cleanNumericKeys(storage.manaitem1)
cleanNumericKeys(storage.manaitem2)
cleanNumericKeys(storage.manaitem3)
cleanNumericKeys(storage.stamina1)
cleanNumericKeys(storage.stamina2)
cleanNumericKeys(storage.fooditem1)
cleanNumericKeys(storage.fooditem2)
cleanNumericKeys(storage.fooditem3)

if type(storage.healing1) ~= "table" then
  storage.healing1 = {on=false, title="HP%", text="exura", min=80, delay=1000, mana=0, priority=1}
end
if type(storage.healing2) ~= "table" then
  storage.healing2 = {on=false, title="HP%", text="exura vita", min=60, delay=1000, mana=0, priority=2}
end
if type(storage.healing3) ~= "table" then
  storage.healing3 = {on=false, title="HP%", text="exura gran", min=30, delay=2000, mana=0, priority=3}
end

if storage.healing1.delay == nil then storage.healing1.delay = 1000 end
if storage.healing2.delay == nil then storage.healing2.delay = 1000 end
if storage.healing3.delay == nil then storage.healing3.delay = 2000 end
if storage.healing1.mana == nil then storage.healing1.mana = 0 end
if storage.healing2.mana == nil then storage.healing2.mana = 0 end
if storage.healing3.mana == nil then storage.healing3.mana = 0 end
if storage.healing1.priority == nil then storage.healing1.priority = 1 end
if storage.healing2.priority == nil then storage.healing2.priority = 2 end
if storage.healing3.priority == nil then storage.healing3.priority = 3 end

for _, spellStorage in ipairs({storage.healing1, storage.healing2, storage.healing3}) do
  cleanNumericKeys(spellStorage)
end


healingSpellMacros = healingSpellMacros or {}

local updateHealingConfigs
local healingMainWindow
local healingHelpWindow
local healingHelpButton
local healingTabBar
local healingTabs = {}
local rebuildHealingTabs
local friendHeader
local setHealingEnabled
local setPartyEnabled
local partyEnabled
local maxLevel
local minLevel
local blacklist
local leaders
local buildHealingProfilePanel
local maxPartyMembers
local inviteMessage
local warningMessage
local inviteKeyword
local partyPassword
local pedirPTEnabled
local avisoMacroEnabled
local debugMacroEnabled
local acceptPartyEnabled
local acceptPartyOnlyLeaders
local avisoMacro
local debugMacro
local pedirPTMacro
local createAvisoMacro
local createDebugMacro
local createPedirPTMacro
local toolsRuntimeInitialized = false
local healingMasterSwitchRef

local function syncHealingMasterSwitchState()
  if not healingMasterSwitchRef then
    return
  end

  local enabled = storage.healingSystemEnabled == true
  local ok = pcall(function()
    healingMasterSwitchRef:setOn(enabled)
  end)
  if not ok then
    healingMasterSwitchRef = nil
    return
  end

  if healingMasterSwitchRef.setText then
    pcall(function()
      healingMasterSwitchRef:setText(enabled and "ON" or "OFF")
    end)
  end
end

local function migrateMinFromMax(config)
  if config and config.max and (config.min == nil or config.min == 0) and config.max > 0 then
    config.min = config.max
  end
end

migrateMinFromMax(storage.healing1)
migrateMinFromMax(storage.healing2)
migrateMinFromMax(storage.healing3)

local function normalizePriority(value, maxValue)
  local num = tonumber(value) or 1
  if num < 1 then
    num = 1
  elseif num > maxValue then
    num = maxValue
  end
  return num
end

local function cloneTable(value)
  if type(value) ~= 'table' then return value end
  local copy = {}
  for k, v in pairs(value) do
    copy[k] = cloneTable(v)
  end
  return copy
end

local function setStandardTooltip(widget, ptText, enText)
  if not widget or not widget.setTooltip then
    return
  end
  local pt = tostring(ptText or "")
  local en = tostring(enText or "")
  if pt == "" and en == "" then
    return
  end
  if pt == "" then
    pt = en
  end
  if en == "" then
    en = pt
  end
  widget:setTooltip(string.format("PT: %s\nEN: %s", pt, en))
end

local function setTooltipFromUnknown(widget, tooltipText, fallbackEn)
  if not widget or not widget.setTooltip then
    return
  end

  local text = tostring(tooltipText or "")
  if text == "" then
    return
  end

  if text:find("PT:") and text:find("EN:") then
    widget:setTooltip(text)
    return
  end

  local en = tostring(fallbackEn or "")
  if en == "" then
    en = text
  end
  setStandardTooltip(widget, text, en)
end

local function findWidgetByIdRecursive(root, childId)
  if not root or not childId then
    return nil
  end
  local direct = root.getChildById and root:getChildById(childId) or nil
  if direct then
    return direct
  end
  local children = root.getChildren and root:getChildren() or nil
  if not children then
    return nil
  end
  for _, child in ipairs(children) do
    local found = findWidgetByIdRecursive(child, childId)
    if found then
      return found
    end
  end
  return nil
end

local HP_TOOLS_HELP_TEXT = table.concat({
  "PT - HP/Tools (Resumo)",
  "======================",
  "1) Objetivo",
  "- Centralizar cura por spell/item, tools e funcoes de party.",
  "- Fluxo rapido com perfis salvos.",
  "",
  "2) Janela principal",
  "- Aba Cura: spell, item e stamina por prioridade.",
  "- Aba Tools: utilitarios e automacoes complementares.",
  "- Ajuda: abre este tutorial completo.",
  "",
  "3) Cura por Spell/Item",
  "- Defina thresholds de HP/MP, delay e prioridade.",
  "- Ajuste listas/filtros para evitar uso indevido.",
  "",
  "4) Curar Amigos / Party",
  "- Escolha modo Spell ou Item.",
  "- Configure distancia, delay e filtros (VIP/Party/Guild/Custom).",
  "",
  "5) Perfis",
  "- Use perfis por char/vocacao/hunt.",
  "- Salve apos ajustes grandes.",
  "",
  "EN - HP/Tools (Summary)",
  "=======================",
  "1) Goal",
  "- Centralize spell/item healing, tools and party utilities.",
  "- Fast workflow with saved profiles.",
  "",
  "2) Main window",
  "- Healing tab: spell, item and stamina rules by priority.",
  "- Tools tab: extra utilities and automations.",
  "- Help: opens this full tutorial.",
  "",
  "3) Spell/Item healing",
  "- Define HP/MP thresholds, delay and priority.",
  "- Tune lists/filters to avoid wrong triggers.",
  "",
  "4) Friends / Party healing",
  "- Choose Spell or Item mode.",
  "- Configure distance, delay and filters (VIP/Party/Guild/Custom).",
  "",
  "5) Profiles",
  "- Keep profiles by char/vocation/hunt.",
  "- Save after major changes."
}, "\n")

local function refreshHealingHelpWindow()
  if not healingHelpWindow or (healingHelpWindow.isDestroyed and healingHelpWindow:isDestroyed()) then
    return nil
  end
  local textLabel = findWidgetByIdRecursive(healingHelpWindow, 'helpTextLabel')
  if textLabel then
    textLabel:setText(HP_TOOLS_HELP_TEXT)
  end
  return {
    scrollBar = findWidgetByIdRecursive(healingHelpWindow, 'helpScroll'),
    scrollContent = findWidgetByIdRecursive(healingHelpWindow, 'helpScrollContent'),
    textLabel = textLabel,
    closeButton = findWidgetByIdRecursive(healingHelpWindow, 'closeButton')
  }
end

local function resetHealingHelpScrollToTop(helpUi)
  if not helpUi then
    return
  end
  if helpUi.scrollBar and helpUi.scrollBar.setValue then
    local minValue = 0
    if helpUi.scrollBar.getMinimum then
      local currentMin = helpUi.scrollBar:getMinimum()
      if type(currentMin) == 'number' then
        minValue = currentMin
      end
    end
    helpUi.scrollBar:setValue(minValue)
  end
  if helpUi.scrollContent and helpUi.scrollContent.getVirtualOffset and helpUi.scrollContent.setVirtualOffset then
    local off = helpUi.scrollContent:getVirtualOffset() or { x = 0, y = 0 }
    off.x = 0
    off.y = 0
    helpUi.scrollContent:setVirtualOffset(off)
  end
end

local function openHealingHelpWindow()
  local helpUi = refreshHealingHelpWindow()
  if not helpUi then
    return
  end
  healingHelpWindow:show()
  healingHelpWindow:raise()
  healingHelpWindow:focus()
  resetHealingHelpScrollToTop(helpUi)
  schedule(30, function() resetHealingHelpScrollToTop(helpUi) end)
  schedule(120, function() resetHealingHelpScrollToTop(helpUi) end)
  schedule(260, function() resetHealingHelpScrollToTop(helpUi) end)
end

local function refreshLayout(widget)
  local function findScrollBar(node)
    local current = node
    for _ = 1, 8 do
      if not current then
        break
      end
      if current.panelScroll then
        return current.panelScroll
      end
      if current.getChildById then
        local candidate = current:getChildById('panelScroll')
        if candidate then
          return candidate
        end
      end
      if current.getParent then
        current = current:getParent()
      else
        current = nil
      end
    end
    return nil
  end

  local scrollBar = findScrollBar(widget)
  local scrollValue
  if scrollBar and scrollBar.getValue then
    scrollValue = scrollBar:getValue()
  end
  local current = widget
  for i = 1, 6 do
    if not current then
      break
    end
    if current.updateLayout then
      current:updateLayout()
    end
    if i == 1 and current.fitChildren then
      current:fitChildren()
    end
    if i == 1 and current.resizeToFitChildren then
      current:resizeToFitChildren()
    end
    current = current:getParent()
  end
  if scrollBar and scrollValue ~= nil and scrollBar.setValue then
    local function restoreScroll()
      if scrollBar.isDestroyed and scrollBar:isDestroyed() then
        return
      end
      local value = scrollValue
      if scrollBar.getMaximum then
        local max = scrollBar:getMaximum()
        if max and value > max then
          value = max
        end
      end
      scrollBar:setValue(value)
    end
    if addEvent then
      addEvent(restoreScroll)
    else
      restoreScroll()
    end
  end
end

local function ensurePanelHeight(panel)
  if not panel or not panel.getChildren or not panel.setHeight then
    return
  end
  if panel.updateLayout then
    panel:updateLayout()
  end
  local maxBottom = 0
  for _, child in ipairs(panel:getChildren() or {}) do
    if child.isVisible and not child:isVisible() then
      -- Ignora filhos ocultos para nao inflar a altura.
    elseif child.getHeight and child.getY then
      local bottom = (child:getY() or 0) + (child:getHeight() or 0)
      if bottom > maxBottom then
        maxBottom = bottom
      end
    elseif child.getHeight then
      local height = child:getHeight() or 0
      if height > maxBottom then
        maxBottom = height
      end
    end
  end
  if maxBottom > 0 then
    panel:setHeight(maxBottom + 4)
  end
end

local function createSection(parent, title, opts)
  opts = opts or {}
  local header = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4
  fit-children: true

  SmallBotSwitch
    id: enableSwitch
    width: 34
    height: 20
    text-align: center
    text: ON

  Label
    id: title
    font: verdana-11px-rounded
    width: 170
    text-align: left
    text-auto-resize: false

  Button
    id: toggleBtn
    text: +
    width: 20
    height: 20
]], parent)

  header.title:setText(title)
  header.title:setColor('#FFFFFF')
  if opts.tooltip then
    setTooltipFromUnknown(header.title, opts.tooltip)
  end
  setStandardTooltip(
    header.toggleBtn,
    "Abrir ou fechar configuracoes de " .. title .. ".",
    "Open or close settings for " .. title .. "."
  )

  if opts.showSwitch == false then
    header.enableSwitch:setVisible(false)
    header.enableSwitch:setWidth(0)
  else
    header.enableSwitch:setOn(opts.enabled == true)
    if opts.switchTooltip then
      setTooltipFromUnknown(header.enableSwitch, opts.switchTooltip)
    end
    header.enableSwitch.onClick = function(widget)
      local enabled = not widget:isOn()
      if opts.onToggle then
        opts.onToggle(enabled)
      end
      widget:setOn(enabled)
    end
  end

  local sectionPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 4
  fit-children: true
]], parent)
  sectionPanel:setVisible(false)
  sectionPanel:setMarginTop(4)
  sectionPanel:setMarginBottom(8)

  local function toggleSection()
    local visible = not sectionPanel:isVisible()
    sectionPanel:setVisible(visible)
    header.toggleBtn:setText(visible and '-' or '+')
    if visible then
      refreshLayout(sectionPanel)
      ensurePanelHeight(sectionPanel)
      if parent then
        ensurePanelHeight(parent)
      end
      refreshLayout(sectionPanel)
      return
    end
    refreshLayout(sectionPanel)
  end

  header.toggleBtn.onMousePress = function(widget, mousePos, mouseButton)
    if MouseLeftButton and mouseButton and mouseButton ~= MouseLeftButton then
      return false
    end
    toggleSection()
    return true
  end
  header.toggleBtn.onClick = nil

  return {
    header = header,
    panel = sectionPanel
  }
end

local function getTabContent(panel)
  if panel and panel.getChildById then
    local content = panel:getChildById('panelContent')
    if content then
      return content
    end
  end
  return panel
end

local function createTabHeader(panel, title, opts)
  opts = opts or {}
  panel = getTabContent(panel)
  if not panel then
    return nil
  end

  local header = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4
  fit-children: true

  SmallBotSwitch
    id: enableSwitch
    width: 34
    height: 20
    text-align: center
    text: ON

  Label
    id: title
    font: verdana-11px-rounded
    width: 200
    text-align: left
    text-auto-resize: false
]], panel)

  header.title:setText(title)
  header.title:setColor('#FFFFFF')
  if opts.labelWidth then
    header.title:setWidth(opts.labelWidth)
  end
  if opts.tooltip then
    setTooltipFromUnknown(header.title, opts.tooltip)
  end

  if opts.showSwitch == false then
    header.enableSwitch:setVisible(false)
    header.enableSwitch:setWidth(0)
  else
    header.enableSwitch:setOn(opts.enabled == true)
    if opts.switchTooltip then
      setTooltipFromUnknown(header.enableSwitch, opts.switchTooltip)
    end
    header.enableSwitch.onClick = function(widget)
      local enabled = not widget:isOn()
      if opts.onToggle then
        opts.onToggle(enabled)
      end
      widget:setOn(enabled)
    end
  end

  g_ui.createWidget('BotSeparator', panel)
  return header
end

local function createCompactGroup(parent, title, titleColor)
  local container = setupUI([[
Panel
  image-source: /images/ui/panel_flat
  image-border: 5
  padding-top: 4
  padding-bottom: 4
  padding-left: 6
  padding-right: 6
  margin-top: 2
  margin-bottom: 2
  layout:
    type: verticalBox
    spacing: 3
  fit-children: true
]], parent)

  local titleLabel = g_ui.createWidget('BotLabel', container)
  titleLabel:setText(title or "")
  titleLabel:setColor(titleColor or '#FFD36A')
  titleLabel:setHeight(16)
  if titleLabel.setTextAlign then
    titleLabel:setTextAlign(AlignHCenter)
  end

  local divider = g_ui.createWidget('BotSeparator', container)
  if divider and divider.setMarginTop then
    divider:setMarginTop(1)
  end

  return {
    container = container,
    title = titleLabel,
    content = container
  }
end

local function adjustGroupHeights(groupContainer)
  if not groupContainer then
    return
  end
  refreshLayout(groupContainer)
  ensurePanelHeight(groupContainer)
  local parent = groupContainer.getParent and groupContainer:getParent() or nil
  if parent then
    refreshLayout(parent)
    ensurePanelHeight(parent)
  end
end

local function delayMsToSeconds(ms)
  local value = tonumber(ms) or 0
  return value / 1000
end

local function secondsToMs(value)
  local num = tonumber(value) or 0
  if num < 0 then
    num = 0
  end
  return math.floor(num * 1000)
end

local function delayMsToMinutes(ms)
  local value = tonumber(ms) or 0
  return value / 60000
end

local function minutesToMs(value)
  local num = tonumber(value) or 0
  if num < 0 then
    num = 0
  end
  return math.floor(num * 60000)
end

local function isFluidContainerItem(itemId)
  local id = tonumber(itemId) or 0
  if id <= 0 or not g_things or not g_things.getThingType then
    return false
  end
  local thing = g_things.getThingType(id)
  return thing and thing.isFluidContainer and thing:isFluidContainer() or false
end

local function resolveInventoryUseSubType(itemId, configuredSubType)
  local clientVersion = g_game and g_game.getClientVersion and g_game.getClientVersion() or 0
  local subType = clientVersion >= 860 and 0 or 1
  if isFluidContainerItem(itemId) then
    subType = tonumber(configuredSubType) or subType
  end
  return subType
end

local function canUseInventoryHotkeyWithoutVisibleItem(itemId)
  local id = tonumber(itemId) or 0
  if id <= 0 then
    return false
  end
  local clientVersion = g_game and g_game.getClientVersion and g_game.getClientVersion() or 0
  if clientVersion < 780 then
    return false
  end
  if not g_game then
    return false
  end
  return g_game.useInventoryItemWith ~= nil or g_game.useInventoryItem ~= nil
end

local function useFoodEntry(cfg)
  if type(cfg) ~= "table" then
    return false
  end

  local itemId = tonumber(cfg.item) or 0
  if itemId <= 0 then
    return false
  end

  local useOnSelf = isFluidContainerItem(itemId)

  if useOnSelf then
    local subType = resolveInventoryUseSubType(itemId, cfg.subType)
    if TargetBot then
      TargetBot.useItem(itemId, subType, player)
      return true
    end
    if g_game and g_game.useInventoryItemWith and player then
      g_game.useInventoryItemWith(itemId, player, subType)
      return true
    end
    return false
  end

  if g_game and g_game.useInventoryItem then
    local subType = tonumber(cfg.subType) or 0
    g_game.useInventoryItem(itemId, subType)
    return true
  end

  if g_game and g_game.useInventoryItemWith and player then
    local subType = resolveInventoryUseSubType(itemId, cfg.subType)
    g_game.useInventoryItemWith(itemId, player, subType)
    return true
  end

  return false
end

local function delayMsToHours(ms)
  local value = tonumber(ms) or 0
  return value / 3600000
end

local function hoursToMs(value)
  local num = tonumber(value) or 0
  if num < 0 then
    num = 0
  end
  return math.floor(num * 3600000)
end

local function formatSeconds(value)
  local num = tonumber(value) or 0
  if math.floor(num) == num then
    return tostring(num)
  end
  return string.format("%.1f", num)
end

healingUiRefs = healingUiRefs or {spells = {}, items = {}, stamina = {}, foods = {}}
healingUiSyncing = false

local function applyTableData(target, source)
  if type(target) ~= "table" then
    return
  end
  for k in pairs(target) do
    target[k] = nil
  end
  for k, v in pairs(source or {}) do
    target[k] = cloneTable(v)
  end
end

local function clearChildren(widget)
  if not widget or not widget.getChildren then
    return
  end
  for _, child in ipairs(widget:getChildren() or {}) do
    child:destroy()
  end
end

local function applyHealingDefaults()
  for i, cfg in ipairs({storage.healing1, storage.healing2, storage.healing3}) do
    cfg.on = cfg.on == true
    cfg.text = cfg.text or ""
    if cfg.min == nil then cfg.min = 0 end
    if cfg.mana == nil then cfg.mana = 0 end
    if cfg.delay == nil then cfg.delay = 1000 end
    cfg.priority = normalizePriority(cfg.priority, 3)
  end
  for _, cfg in ipairs({storage.hpitem1, storage.hpitem2, storage.hpitem3, storage.manaitem1, storage.manaitem2, storage.manaitem3}) do
    cfg.on = cfg.on == true
    cfg.item = cfg.item or 0
    if cfg.min == nil then cfg.min = 0 end
    if cfg.delay == nil then cfg.delay = 1000 end
    cfg.priority = normalizePriority(cfg.priority, 6)
  end
  for _, cfg in ipairs({storage.stamina1, storage.stamina2}) do
    cfg.on = cfg.on == true
    cfg.item = cfg.item or 0
    if cfg.min == nil then cfg.min = 0 end
    if cfg.delay == nil then cfg.delay = 1000 end
    cfg.priority = normalizePriority(cfg.priority, 2)
  end
  for _, cfg in ipairs({storage.fooditem1, storage.fooditem2, storage.fooditem3}) do
    cfg.on = cfg.on == true
    cfg.item = cfg.item or 0
    if cfg.hp == nil then cfg.hp = 100 end
    if cfg.mp == nil then cfg.mp = 100 end
    if cfg.delayMinutes == nil then cfg.delayMinutes = 1 end
    if cfg.delayMinutes < 0.1 then cfg.delayMinutes = 0.1 end
    if cfg.allowHidden == nil then cfg.allowHidden = true end
    cfg.allowHidden = cfg.allowHidden == true
    cfg.priority = normalizePriority(cfg.priority, 3)
  end
end

local function ensureToolsMacrosSettings()
  if type(storage.toolsMacrosEnabled) ~= "table" then
    storage.toolsMacrosEnabled = {
      hideEffects = false,
      hideMessages = false,
      autoMount = false,
      exetaLoot = false
    }
  end
  storage.toolsMacrosEnabled.hideEffects = storage.toolsMacrosEnabled.hideEffects == true
  storage.toolsMacrosEnabled.hideMessages = storage.toolsMacrosEnabled.hideMessages == true
  storage.toolsMacrosEnabled.autoMount = storage.toolsMacrosEnabled.autoMount == true
  storage.toolsMacrosEnabled.exetaLoot = storage.toolsMacrosEnabled.exetaLoot == true
  if storage.toolsMacrosEnabled.superdashAssist ~= nil then
    storage.toolsMacrosEnabled.superdashAssist = nil
  end
  if storage.toolsMacrosEnabled.closeWindows ~= nil then
    storage.toolsMacrosEnabled.closeWindows = nil
  end
  return storage.toolsMacrosEnabled
end

local function buildToolsOthersOptions(panel, opts)
  opts = opts or {}
  panel = panel:getChildById('panelContent') or panel
  local toolsMacros = ensureToolsMacrosSettings()

  local toolsMacrosContainer = setupUI([[
Panel
  height: 96
  margin-top: 2

  Panel
    id: box
    anchors.fill: parent
    layout:
      type: verticalBox
      spacing: 2

    Panel
      id: hideEffectsRow
      height: 20
      layout:
        type: horizontalBox
        spacing: 4

      SmallBotSwitch
        id: hideEffects
        width: 28
        height: 18
        text-align: center
        text: ON

      Label
        id: hideEffectsLabel
        text: Esconder Magias
        font: verdana-11px-rounded
        width: 130

    Panel
      id: hideMessagesRow
      height: 20
      layout:
        type: horizontalBox
        spacing: 4

      SmallBotSwitch
        id: hideMessages
        width: 28
        height: 18
        text-align: center
        text: ON

      Label
        id: hideMessagesLabel
        text: Esconder Msgs
        font: verdana-11px-rounded
        width: 130

    Panel
      id: autoMountRow
      height: 20
      layout:
        type: horizontalBox
        spacing: 4

      SmallBotSwitch
        id: autoMount
        width: 28
        height: 18
        text-align: center
        text: ON

      Label
        id: autoMountLabel
        text: Auto Mount
        font: verdana-11px-rounded
        width: 130

    Panel
      id: exetaLootRow
      height: 20
      layout:
        type: horizontalBox
        spacing: 4

      SmallBotSwitch
        id: exetaLoot
        width: 28
        height: 18
        text-align: center
        text: ON

      Label
        id: exetaLootLabel
        text: Exeta Loot
        font: verdana-11px-rounded
        width: 130

]], panel)

  if opts.marginTop ~= nil and toolsMacrosContainer.setMarginTop then
    toolsMacrosContainer:setMarginTop(opts.marginTop)
  end
  if opts.marginBottom ~= nil and toolsMacrosContainer.setMarginBottom then
    toolsMacrosContainer:setMarginBottom(opts.marginBottom)
  end
  if opts.height ~= nil and toolsMacrosContainer.setHeight then
    toolsMacrosContainer:setHeight(opts.height)
  end

  setStandardTooltip(
    toolsMacrosContainer,
    "Macros para visualizacao e automacao. Verde = ativo, branco = inativo.",
    "Macros for visualization and automation. Green = active, white = inactive."
  )

  local hideEffectsSwitch = findWidgetByIdRecursive(toolsMacrosContainer, "hideEffects")
  local hideEffectsLabel = findWidgetByIdRecursive(toolsMacrosContainer, "hideEffectsLabel")
  local hideMessagesSwitch = findWidgetByIdRecursive(toolsMacrosContainer, "hideMessages")
  local hideMessagesLabel = findWidgetByIdRecursive(toolsMacrosContainer, "hideMessagesLabel")
  local autoMountSwitch = findWidgetByIdRecursive(toolsMacrosContainer, "autoMount")
  local autoMountLabel = findWidgetByIdRecursive(toolsMacrosContainer, "autoMountLabel")
  local exetaLootSwitch = findWidgetByIdRecursive(toolsMacrosContainer, "exetaLoot")
  local exetaLootLabel = findWidgetByIdRecursive(toolsMacrosContainer, "exetaLootLabel")

  if hideEffectsSwitch then
    hideEffectsSwitch:setOn(toolsMacros.hideEffects)
  end
  setStandardTooltip(
    hideEffectsSwitch,
    "Esconde efeitos visuais de spells. Util para melhorar FPS em areas com muitas particulas.",
    "Hides visual spell effects. Useful to improve FPS in areas with many particles."
  )
  if hideEffectsLabel then
    setStandardTooltip(
      hideEffectsLabel,
      "Esconde efeitos visuais de spells. Util para melhorar FPS em areas com muitas particulas.",
      "Hides visual spell effects. Useful to improve FPS in areas with many particles."
    )
  end
  if hideEffectsSwitch then
    hideEffectsSwitch.onClick = function(widget)
      toolsMacros.hideEffects = not toolsMacros.hideEffects
      widget:setOn(toolsMacros.hideEffects)
    end
  end

  if hideMessagesSwitch then
    hideMessagesSwitch:setOn(toolsMacros.hideMessages)
  end
  setStandardTooltip(
    hideMessagesSwitch,
    "Limpa textos do mapa (dano, cura, etc.). Reduz poluicao visual em hunts intensas.",
    "Clears map texts (damage, healing, etc.). Reduces visual clutter in intense hunts."
  )
  if hideMessagesLabel then
    setStandardTooltip(
      hideMessagesLabel,
      "Limpa textos do mapa (dano, cura, etc.). Reduz poluicao visual em hunts intensas.",
      "Clears map texts (damage, healing, etc.). Reduces visual clutter in intense hunts."
    )
  end
  if hideMessagesSwitch then
    hideMessagesSwitch.onClick = function(widget)
      toolsMacros.hideMessages = not toolsMacros.hideMessages
      widget:setOn(toolsMacros.hideMessages)
    end
  end

  if autoMountSwitch then
    autoMountSwitch:setOn(toolsMacros.autoMount)
  end
  setStandardTooltip(
    autoMountSwitch,
    "Monta automaticamente a cada 10 segundos. Util apos teleporte ou summon.",
    "Automatically mounts every 10 seconds. Useful after teleport or summon."
  )
  if autoMountLabel then
    setStandardTooltip(
      autoMountLabel,
      "Monta automaticamente a cada 10 segundos. Util apos teleporte ou summon.",
      "Automatically mounts every 10 seconds. Useful after teleport or summon."
    )
  end
  if autoMountSwitch then
    autoMountSwitch.onClick = function(widget)
      toolsMacros.autoMount = not toolsMacros.autoMount
      widget:setOn(toolsMacros.autoMount)
    end
  end

  if exetaLootSwitch then
    exetaLootSwitch:setOn(toolsMacros.exetaLoot)
  end
  setStandardTooltip(
    exetaLootSwitch,
    "Diz 'exeta loot' automaticamente quando um monstro morre por perto e deixa um container. Delay de 1 segundo entre usos.",
    "Says 'exeta loot' automatically when a monster dies nearby and leaves a container. 1 second delay between uses."
  )
  if exetaLootLabel then
    setStandardTooltip(
      exetaLootLabel,
      "Diz 'exeta loot' automaticamente quando um monstro morre por perto e deixa um container. Delay de 1 segundo entre usos.",
      "Says 'exeta loot' automatically when a monster dies nearby and leaves a container. 1 second delay between uses."
    )
  end
  if exetaLootSwitch then
    exetaLootSwitch.onClick = function(widget)
      toolsMacros.exetaLoot = not toolsMacros.exetaLoot
      widget:setOn(toolsMacros.exetaLoot)
    end
  end

  return toolsMacrosContainer, toolsMacros
end

local function ensureToolsAutomaticMacroSettings()
  if storage.autoBuffEnabled == nil then storage.autoBuffEnabled = false end
  if not storage.autoBuffText then storage.autoBuffText = "utito tempo" end
  if storage.autoBuffManaMin == nil then storage.autoBuffManaMin = 15 end
  if type(storage.autoBuffFilters) ~= "table" then
    storage.autoBuffFilters = { executeInPZ = false, executeWithTarget = true }
  end

  if storage.autoHasteEnabled == nil then storage.autoHasteEnabled = false end
  if not storage.EditSpellsHasteSpell then storage.EditSpellsHasteSpell = "utani hur" end
  if storage.autoHasteManaMin == nil then storage.autoHasteManaMin = 0 end
  if type(storage.autoHasteFilters) ~= "table" then
    storage.autoHasteFilters = { executeInPZ = false, executeWithMonster = true }
  end

  if storage.antiParalyzeEnabled == nil then storage.antiParalyzeEnabled = false end
  if not storage.EditSpellsAntiParalyze then storage.EditSpellsAntiParalyze = "utani hur" end
  if storage.antiParalyzeManaMin == nil then storage.antiParalyzeManaMin = 0 end
  if type(storage.antiParalyzeFilters) ~= "table" then
    storage.antiParalyzeFilters = { executeInPZ = false, executeWithMonster = true }
  end

  if storage.recoveryEnabled == nil then storage.recoveryEnabled = false end
  if not storage.recoverySpell then storage.recoverySpell = "utura gran" end
  if storage.recoveryDelay == nil then storage.recoveryDelay = 1000 end
  if storage.recoveryManaMin == nil then storage.recoveryManaMin = 0 end
  if type(storage.recoveryFilters) ~= "table" then
    storage.recoveryFilters = { executeInPZ = false, executeWithTarget = true }
  end

  if storage.familiarEnabled == nil then storage.familiarEnabled = false end
  if not storage.familiarSpell then storage.familiarSpell = "familiar" end
  if storage.familiarDelay == nil then
    storage.familiarDelay = 60000
  elseif tonumber(storage.familiarDelay) and tonumber(storage.familiarDelay) < 60000 then
    -- Legacy values were edited in seconds; keep the same numeric value in new minutes-based UI.
    storage.familiarDelay = math.floor((tonumber(storage.familiarDelay) or 0) * 60)
  end
  if storage.familiarManaMin == nil then storage.familiarManaMin = 0 end
  if type(storage.familiarFilters) ~= "table" then
    storage.familiarFilters = { executeInPZ = false, executeWithTarget = true }
  end

  if storage.castEnabled == nil then storage.castEnabled = false end
  if not storage.castText then storage.castText = "!cast on" end
  if storage.castDelay == nil then storage.castDelay = 3600000 end

  if storage.nextBpEnabled == nil then storage.nextBpEnabled = false end
  if type(storage.nextBpIds) ~= "table" then
    storage.nextBpIds = {{id = 2854}}
  end
  if type(storage.nextBpIds) == "table" then
    for i, v in ipairs(storage.nextBpIds) do
      if type(v) == "number" then
        storage.nextBpIds[i] = {id = v}
      end
    end
  end
end

local function buildAutomaticMacrosPanel(panel)
  panel = panel:getChildById('panelContent') or panel
  ensureToolsAutomaticMacroSettings()

  local header = setupUI([[
Panel
  height: 16
  layout:
    type: horizontalBox
    spacing: 2

  Label
    id: colOn
    text: ON
    width: 28
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colName
    text: Macro
    width: 82
    font: verdana-11px-rounded

  Label
    id: colSpell
    text: Spell
    width: 76
    font: verdana-11px-rounded

  Label
    id: colMana
    text: MP
    width: 38
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colDelay
    text: Delay
    width: 38
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colTarget
    text: T
    width: 14
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colPz
    text: PZ
    width: 14
    text-align: center
    font: verdana-11px-rounded
]], panel)
  setStandardTooltip(
    header,
    "Macros automaticos do Tools espelhados aqui: altere ON, spell, MP, delay e filtros.",
    "Automatic Tools macros mirrored here: edit ON, spell, MP, delay, and filters."
  )
  setStandardTooltip(header.colOn, "Liga/desliga cada macro automaticamente.", "Enable/disable each macro.")
  setStandardTooltip(header.colName, "Nome do macro.", "Macro name.")
  setStandardTooltip(header.colSpell, "Spell usada pelo macro.", "Spell used by the macro.")
  setStandardTooltip(header.colMana, "MP minimo (%) para executar.", "Minimum MP (%) to execute.")
  setStandardTooltip(header.colDelay, "Delay entre execucoes.", "Delay between executions.")
  setStandardTooltip(header.colTarget, "Filtro de target.", "Target filter.")
  setStandardTooltip(header.colPz, "Permitir execucao em PZ.", "Allow execution in PZ.")

  local function createRow(name, enabledKey, opts)
    opts = opts or {}
    local row = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 2

  SmallBotSwitch
    id: enabled
    width: 28
    height: 18
    text-align: center
    text: ON

  Label
    id: nameLabel
    width: 82
    font: verdana-11px-rounded

  TextEdit
    id: spellText
    width: 76
    height: 18
    font: verdana-11px-rounded

  SpinBox
    id: manaMin
    width: 38
    height: 18
    text-align: center
    minimum: 0
    maximum: 100
    step: 1
    editable: true
    focusable: true

  Label
    id: manaSpacer
    width: 38
    height: 18
    text: ""

  SpinBox
    id: delay
    width: 38
    height: 18
    text-align: center
    minimum: 0.1
    maximum: 999999
    step: 0.1
    editable: true
    focusable: true

  Label
    id: delaySpacer
    width: 38
    height: 18
    text: ""

  CategoryCheckBox
    id: checkTarget
    width: 14
    height: 18
    focusable: true
    phantom: false

  CategoryCheckBox
    id: checkPz
    width: 14
    height: 18
    focusable: true
    phantom: false

  Button
    id: setupBtn
    text: +
    width: 16
    height: 18
]], panel)

    if row.checkTarget and row.checkTarget.setMarginTop then
      row.checkTarget:setMarginTop(0)
    end
    if row.checkPz and row.checkPz.setMarginTop then
      row.checkPz:setMarginTop(0)
    end

    row.nameLabel:setText(name)
    row.enabled:setOn(storage[enabledKey] == true)
    setStandardTooltip(
      row.enabled,
      "Ativa ou desativa o macro " .. name .. ".",
      "Enable or disable the " .. name .. " macro."
    )
    row.enabled.onClick = function(widget)
      local newState = not (storage[enabledKey] == true)
      storage[enabledKey] = newState
      widget:setOn(newState)
    end
    setStandardTooltip(
      row.nameLabel,
      opts.labelTooltipPt or ("Configuracao do macro " .. name .. "."),
      opts.labelTooltipEn or ("Settings for " .. name .. " macro.")
    )

    if opts.spellKey then
      row.spellText:setText(storage[opts.spellKey] or "")
      setStandardTooltip(
        row.spellText,
        "Nome da magia (spell) usada pelo macro.",
        "Spell name used by this macro."
      )
      row.spellText.onTextChange = function(widget, newText)
        storage[opts.spellKey] = newText
      end
    else
      row.spellText:setVisible(false)
      row.spellText:setWidth(0)
    end

    if opts.manaKey then
      row.manaMin:setValue(storage[opts.manaKey] or 0)
      setStandardTooltip(
        row.manaMin,
        "MP minimo (%) para executar.",
        "Minimum MP (%) to execute."
      )
      row.manaMin.onValueChange = function(widget, value)
        storage[opts.manaKey] = value
      end
      row.manaSpacer:setVisible(false)
      row.manaSpacer:setWidth(0)
    else
      row.manaMin:setVisible(false)
      row.manaMin:setWidth(0)
      row.manaSpacer:setVisible(true)
      row.manaSpacer:setWidth(38)
    end

    if opts.delayKey then
      local delayUnit = opts.delayUnit == "hours" and "hours" or (opts.delayUnit == "minutes" and "minutes" or "seconds")
      local currentDelay = storage[opts.delayKey]
      if currentDelay == nil then
        if delayUnit == "hours" then
          currentDelay = 3600000
        elseif delayUnit == "minutes" then
          currentDelay = 60000
        else
          currentDelay = 1000
        end
      end
      if delayUnit == "hours" then
        row.delay:setValue(delayMsToHours(currentDelay))
      elseif delayUnit == "minutes" then
        row.delay:setValue(delayMsToMinutes(currentDelay))
      else
        row.delay:setValue(delayMsToSeconds(currentDelay))
      end
      local delayPt = "Delay entre execucoes (segundos)."
      local delayEn = "Delay between executions (seconds)."
      if delayUnit == "hours" then
        delayPt = "Delay entre execucoes (horas)."
        delayEn = "Delay between executions (hours)."
      elseif delayUnit == "minutes" then
        delayPt = "Delay entre execucoes (minutos)."
        delayEn = "Delay between executions (minutes)."
      end
      setStandardTooltip(
        row.delay,
        delayPt,
        delayEn
      )
      row.delay.onValueChange = function(widget, value)
        if delayUnit == "hours" then
          storage[opts.delayKey] = hoursToMs(value)
        elseif delayUnit == "minutes" then
          storage[opts.delayKey] = minutesToMs(value)
        else
          storage[opts.delayKey] = secondsToMs(value)
        end
      end
      if delayUnit == "hours" and row.delay.setMaximum then
        row.delay:setMaximum(24)
      end
      row.delaySpacer:setVisible(false)
      row.delaySpacer:setWidth(0)
    else
      row.delay:setVisible(false)
      row.delay:setWidth(0)
      row.delaySpacer:setVisible(true)
      row.delaySpacer:setWidth(38)
    end

    if opts.targetFilter then
      local filters = storage[opts.targetFilter.tableKey] or {}
      storage[opts.targetFilter.tableKey] = filters
      if filters[opts.targetFilter.fieldKey] == nil then
        filters[opts.targetFilter.fieldKey] = opts.targetFilter.default == true
      end
      local targetPt = "Executar apenas com target selecionado."
      local targetEn = "Execute only with a selected target."
      if tostring(opts.targetFilter.fieldKey or ""):find("Monster") then
        targetPt = "Executar quando houver monstro no target."
        targetEn = "Execute when there is a monster on target."
      end
      setStandardTooltip(row.checkTarget, targetPt, targetEn)
      row.checkTarget:setChecked(filters[opts.targetFilter.fieldKey])
      row.checkTarget.onClick = function(widget)
        filters[opts.targetFilter.fieldKey] = not filters[opts.targetFilter.fieldKey]
        widget:setChecked(filters[opts.targetFilter.fieldKey])
      end
    else
      row.checkTarget:setVisible(false)
      row.checkTarget:setWidth(0)
    end

    if opts.pzFilter then
      local filters = storage[opts.pzFilter.tableKey] or {}
      storage[opts.pzFilter.tableKey] = filters
      if filters[opts.pzFilter.fieldKey] == nil then
        filters[opts.pzFilter.fieldKey] = opts.pzFilter.default == true
      end
      setStandardTooltip(
        row.checkPz,
        "Permitir execucao dentro de PZ.",
        "Allow execution inside PZ."
      )
      row.checkPz:setChecked(filters[opts.pzFilter.fieldKey])
      row.checkPz.onClick = function(widget)
        filters[opts.pzFilter.fieldKey] = not filters[opts.pzFilter.fieldKey]
        widget:setChecked(filters[opts.pzFilter.fieldKey])
      end
    else
      row.checkPz:setVisible(false)
      row.checkPz:setWidth(0)
    end

    if opts.showSetup == true then
      setStandardTooltip(
        row.setupBtn,
        "Abrir configuracao de Next BP aqui mesmo.",
        "Open Next BP configuration right here."
      )
      row.setupBtn:setText("+")
    else
      row.setupBtn:setVisible(false)
      row.setupBtn:setWidth(0)
    end

    return row
  end

  createRow("Auto Buff", "autoBuffEnabled", {
    labelTooltipPt = "Usa buff automaticamente quando nao ha party buff ativo.",
    labelTooltipEn = "Automatically uses a buff when party buff is not active.",
    spellKey = "autoBuffText",
    manaKey = "autoBuffManaMin",
    targetFilter = { tableKey = "autoBuffFilters", fieldKey = "executeWithTarget", default = true },
    pzFilter = { tableKey = "autoBuffFilters", fieldKey = "executeInPZ", default = false }
  })

  createRow("Auto Haste", "autoHasteEnabled", {
    labelTooltipPt = "Usa haste automaticamente quando faltar haste ou houver paralyze.",
    labelTooltipEn = "Automatically uses haste when missing haste or when paralyzed.",
    spellKey = "EditSpellsHasteSpell",
    manaKey = "autoHasteManaMin",
    targetFilter = { tableKey = "autoHasteFilters", fieldKey = "executeWithMonster", default = true },
    pzFilter = { tableKey = "autoHasteFilters", fieldKey = "executeInPZ", default = false }
  })

  createRow("Ant-Lyze", "antiParalyzeEnabled", {
    labelTooltipPt = "Remove paralisia automaticamente.",
    labelTooltipEn = "Automatically removes paralysis.",
    spellKey = "EditSpellsAntiParalyze",
    manaKey = "antiParalyzeManaMin",
    targetFilter = { tableKey = "antiParalyzeFilters", fieldKey = "executeWithMonster", default = true },
    pzFilter = { tableKey = "antiParalyzeFilters", fieldKey = "executeInPZ", default = false }
  })

  createRow("Recovery", "recoveryEnabled", {
    labelTooltipPt = "Casta recovery em intervalo configurado.",
    labelTooltipEn = "Casts recovery at configured intervals.",
    spellKey = "recoverySpell",
    manaKey = "recoveryManaMin",
    delayKey = "recoveryDelay",
    targetFilter = { tableKey = "recoveryFilters", fieldKey = "executeWithTarget", default = true },
    pzFilter = { tableKey = "recoveryFilters", fieldKey = "executeInPZ", default = false }
  })

  createRow("Familiar", "familiarEnabled", {
    labelTooltipPt = "Invoca o familiar automaticamente.",
    labelTooltipEn = "Automatically summons familiar.",
    spellKey = "familiarSpell",
    manaKey = "familiarManaMin",
    delayKey = "familiarDelay",
    delayUnit = "minutes",
    targetFilter = { tableKey = "familiarFilters", fieldKey = "executeWithTarget", default = true },
    pzFilter = { tableKey = "familiarFilters", fieldKey = "executeInPZ", default = false }
  })

  createRow("Cast", "castEnabled", {
    labelTooltipPt = "Executa o comando de cast no intervalo configurado.",
    labelTooltipEn = "Runs the cast command at the configured interval.",
    spellKey = "castText",
    delayKey = "castDelay",
    delayUnit = "hours"
  })

  local nextBpRow = createRow("Next BP", "nextBpEnabled", {
    labelTooltipPt = "Abre a proxima backpack quando a atual enche.",
    labelTooltipEn = "Open next backpack when current one is full.",
    showSetup = true
  })

  local nextBpConfig = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 2
  fit-children: true
]], panel)
  nextBpConfig:setVisible(false)
  if nextBpConfig.setMarginLeft then
    nextBpConfig:setMarginLeft(30)
  end
  if nextBpConfig.setMarginTop then
    nextBpConfig:setMarginTop(1)
  end

  local nextBpLabel = g_ui.createWidget('BotLabel', nextBpConfig)
  nextBpLabel:setText('Next BP IDs')
  nextBpLabel:setColor('#FFFFFF')
  setStandardTooltip(
    nextBpLabel,
    "IDs de backpacks usados pelo Next BP.",
    "Backpack IDs used by Next BP."
  )

  local nextBpContainer = UI.Container(function(widget, items)
    storage.nextBpIds = items
  end, true, nextBpConfig)
  nextBpContainer:setHeight(40)
  nextBpContainer:setItems(storage.nextBpIds)
  setStandardTooltip(
    nextBpContainer,
    "Clique para adicionar/remover IDs de backpacks (BPs).",
    "Click to add/remove backpack IDs (BPs)."
  )

  nextBpRow.setupBtn.onClick = function()
    local visible = not nextBpConfig:isVisible()
    nextBpConfig:setVisible(visible)
    nextBpRow.setupBtn:setText(visible and '-' or '+')
    if visible then
      ensurePanelHeight(nextBpConfig)
    end
    ensurePanelHeight(panel)
    refreshLayout(panel)
  end
end

local function buildSpellsTab(panel)
  -- Usa o ScrollablePanel interno do HealingPanel
  panel = panel:getChildById('panelContent') or panel

  local header = setupUI([[
Panel
  height: 16
  layout:
    type: horizontalBox
    spacing: 3

  Label
    id: colOn
    text: ON
    width: 28
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colName
    text: Spell
    width: 120
    font: verdana-11px-rounded

  Label
    id: colHp
    text: HP
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colMp
    text: MP
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colDelay
    text: Delay
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colPrio
    text: Prio
    width: 40
    text-align: center
    font: verdana-11px-rounded
]], panel)
  for _, colId in ipairs({"colOn", "colName", "colHp", "colMp", "colDelay", "colPrio"}) do
    if header[colId] and header[colId].setColor then
      header[colId]:setColor('#E8E8E8')
    end
  end
  setStandardTooltip(header, "Tabela de Spells de Cura: configure magias por HP/MP, delay e prioridade.", "Healing Spells table: configure spells by HP/MP, delay, and priority.")
  setStandardTooltip(header.colOn, "Tabela de Spells de Cura: ativa/desativa cada spell.", "Healing Spells table: enable or disable each spell.")
  setStandardTooltip(header.colName, "Tabela de Spells de Cura: nome da magia de cura.", "Healing Spells table: healing spell name.")
  setStandardTooltip(header.colHp, "Tabela de Spells de Cura: HP minimo (%) para castar.", "Healing Spells table: minimum HP (%) to cast.")
  setStandardTooltip(header.colMp, "Tabela de Spells de Cura: MP minimo (%) para castar.", "Healing Spells table: minimum MP (%) to cast.")
  setStandardTooltip(header.colDelay, "Tabela de Spells de Cura: delay entre usos (segundos).", "Healing Spells table: delay between uses (seconds).")
  setStandardTooltip(header.colPrio, "Tabela de Spells de Cura: prioridade (1 = maior).", "Healing Spells table: priority (1 = highest).")
  local quickHeaderSpacer = g_ui.createWidget('Label', header)
  quickHeaderSpacer:setText('')
  quickHeaderSpacer:setWidth(8)
  local quickHeader = g_ui.createWidget('Label', header)
  quickHeader:setText('Acesso Rapido')
  quickHeader:setWidth(170)
  quickHeader:setColor('#E8E8E8')
  setStandardTooltip(
    quickHeader,
    "Atalhos para abrir configuracoes de Party Auto e Curar Amigos em janela separada.",
    "Shortcuts to open Party Auto and Heal Friends settings in a separate window."
  )

  local spellRows = {}

  if type(storage.healing1) ~= "table" then
    storage.healing1 = {on=false, title="HP%", text="exura", min=80, delay=1000, mana=0, priority=1}
  end
  if type(storage.healing2) ~= "table" then
    storage.healing2 = {on=false, title="HP%", text="exura vita", min=60, delay=1000, mana=0, priority=2}
  end
  if type(storage.healing3) ~= "table" then
    storage.healing3 = {on=false, title="HP%", text="exura gran", min=30, delay=2000, mana=0, priority=3}
  end

  for i, healingInfo in ipairs({storage.healing1, storage.healing2, storage.healing3}) do
    if healingInfo.min == nil then healingInfo.min = 0 end
    if healingInfo.mana == nil then healingInfo.mana = 0 end
    if healingInfo.delay == nil then healingInfo.delay = 1000 end
    healingInfo.priority = normalizePriority(healingInfo.priority, 3)

    local row = setupUI([[
Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 3

  SmallBotSwitch
    id: enabled
    width: 28
    height: 18
    text-align: center
    text: ON

  TextEdit
    id: spellText
    width: 120
    height: 18
    font: verdana-11px-rounded

  SpinBox
    id: hpMin
    width: 40
    height: 18
    text-align: center
    font: verdana-11px-rounded
    minimum: 0
    maximum: 100
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: mpMin
    width: 40
    height: 18
    text-align: center
    font: verdana-11px-rounded
    minimum: 0
    maximum: 100
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: delay
    width: 40
    height: 18
    text-align: center
    font: verdana-11px-rounded
    minimum: 0.1
    maximum: 999999
    step: 0.1
    editable: true
    focusable: true

  SpinBox
    id: priority
    width: 40
    height: 18
    text-align: center
    font: verdana-11px-rounded
    minimum: 1
    maximum: 3
    step: 1
    editable: true
    focusable: true
]], panel)

    row.enabled:setOn(healingInfo.on)
    setStandardTooltip(row.enabled, "Ativa ou desativa esta spell de cura.", "Enable or disable this healing spell.")
    row.enabled.onClick = function(widget)
      healingInfo.on = not healingInfo.on
      widget:setOn(healingInfo.on)
      updateHealingConfigs()
    end

    row.spellText:setText(healingInfo.text or "")
    setStandardTooltip(row.spellText, "Nome da spell de cura (ex: exura).", "Healing spell name (e.g., exura).")
    row.spellText.onTextChange = function(widget, newText)
      healingInfo.text = newText
    end

    row.hpMin:setValue(healingInfo.min)
    setStandardTooltip(row.hpMin, "HP minimo (%) para executar.", "Minimum HP (%) to cast.")
    row.hpMin.onValueChange = function(widget, value)
      healingInfo.min = value
    end

    row.mpMin:setValue(healingInfo.mana)
    setStandardTooltip(row.mpMin, "MP minimo (%) para executar.", "Minimum MP (%) to cast.")
    row.mpMin.onValueChange = function(widget, value)
      healingInfo.mana = value
    end

    row.delay:setValue(delayMsToSeconds(healingInfo.delay))
    setStandardTooltip(row.delay, "Delay minimo entre usos (segundos).", "Minimum delay between uses (seconds).")
    row.delay.onValueChange = function(widget, value)
      healingInfo.delay = secondsToMs(value)
    end

    row.priority:setValue(healingInfo.priority)
    setStandardTooltip(row.priority, "Prioridade desta spell (1 = mais alta).", "Priority for this spell (1 = highest).")
    spellRows[i] = {widget = row, config = healingInfo}

    row.priority.onValueChange = function(widget, value)
      if healingUiSyncing then
        return
      end
      local newPriority = tonumber(value) or healingInfo.priority or 1
      newPriority = math.floor(newPriority + 0.5)
      if newPriority < 1 then newPriority = 1 end
      if newPriority > 3 then newPriority = 3 end
      if newPriority == healingInfo.priority then
        healingUiSyncing = true
        widget:setValue(healingInfo.priority)
        healingUiSyncing = false
        return
      end
      healingUiSyncing = true
      local oldPriority = healingInfo.priority
      for _, entry in pairs(spellRows) do
        if entry.config ~= healingInfo and entry.config.priority == newPriority then
          entry.config.priority = oldPriority
          entry.widget.priority:setValue(oldPriority)
          break
        end
      end
      healingInfo.priority = newPriority
      widget:setValue(newPriority)
      healingUiSyncing = false
    end
  end

  if storage.partyEnabled == nil then
    storage.partyEnabled = false
  end
  if type(storage.curarFriends) ~= "table" then
    storage.curarFriends = { enabled = false }
  end
  if storage.curarFriends.enabled == nil then
    storage.curarFriends.enabled = false
  end

  local function attachQuickAccess(rowWidget, opts)
    if not rowWidget then
      return
    end

    local spacer = g_ui.createWidget('Label', rowWidget)
    spacer:setText('')
    spacer:setWidth(8)

    local actionPanel = setupUI([[
Panel
  width: 170
  height: 18
  fit-children: true
  layout:
    type: horizontalBox
    spacing: 4

  SmallBotSwitch
    id: enabled
    width: 30
    height: 18
    text-align: center
    text: ON

  Button
    id: openBtn
    width: 136
    height: 18
]], rowWidget)

    actionPanel.openBtn:setText(opts.buttonText)
    actionPanel.enabled:setOn(opts.getEnabled())
    setStandardTooltip(
      actionPanel.enabled,
      opts.switchTooltipPt,
      opts.switchTooltipEn
    )
    setStandardTooltip(
      actionPanel.openBtn,
      opts.buttonTooltipPt,
      opts.buttonTooltipEn
    )

    actionPanel.enabled.onClick = function(widget)
      local enabled = not opts.getEnabled()
      opts.setEnabled(enabled)
      widget:setOn(enabled)
    end

    actionPanel.openBtn.onClick = function()
      opts.openWindow()
    end
  end

  attachQuickAccess(spellRows[1] and spellRows[1].widget or nil, {
    buttonText = "Party Auto",
    getEnabled = function()
      return storage.partyEnabled == true
    end,
    setEnabled = function(enabled)
      storage.partyEnabled = enabled == true
      if PartyAutoUI and PartyAutoUI.setPartyEnabled then
        PartyAutoUI.setPartyEnabled(storage.partyEnabled)
      end
    end,
    openWindow = function()
      if PartyAutoUI and PartyAutoUI.openPartyWindow then
        PartyAutoUI.openPartyWindow()
      end
    end,
    switchTooltipPt = "Ativa ou desativa o sistema Party Auto.",
    switchTooltipEn = "Enable or disable Party Auto system.",
    buttonTooltipPt = "Abre a janela de configuracao do Party Auto.",
    buttonTooltipEn = "Open Party Auto configuration window."
  })

  attachQuickAccess(spellRows[2] and spellRows[2].widget or nil, {
    buttonText = "Curar Amigos",
    getEnabled = function()
      return storage.curarFriends and storage.curarFriends.enabled == true
    end,
    setEnabled = function(enabled)
      if type(storage.curarFriends) ~= "table" then
        storage.curarFriends = {}
      end
      storage.curarFriends.enabled = enabled == true
      if friendHeader and friendHeader.enableSwitch then
        friendHeader.enableSwitch:setOn(storage.curarFriends.enabled == true)
      end
    end,
    openWindow = function()
      if PartyAutoUI and PartyAutoUI.openFriendWindow then
        PartyAutoUI.openFriendWindow()
      end
    end,
    switchTooltipPt = "Ativa ou desativa o sistema Curar Amigos.",
    switchTooltipEn = "Enable or disable Heal Friends system.",
    buttonTooltipPt = "Abre a janela de configuracao do Curar Amigos.",
    buttonTooltipEn = "Open Heal Friends configuration window."
  })

  healingUiRefs.spells = spellRows
end

-- ================================
-- ITENS DE CURA (HP/MANA) - CONFIG
-- ================================
if type(storage.hpitem1) ~= "table" then
    storage.hpitem1 = {on=false, title="HP%", item=3160, min=0, delay=1000, priority=1}
end
if type(storage.hpitem2) ~= "table" then
    storage.hpitem2 = {on=false, title="HP%", item=3160, min=0, delay=1000, priority=2}
end
if type(storage.hpitem3) ~= "table" then
    storage.hpitem3 = {on=false, title="HP%", item=3160, min=0, delay=1000, priority=3}
end
if type(storage.manaitem1) ~= "table" then
    storage.manaitem1 = {on=false, title="MP%", item=23373, min=0, delay=1000, priority=4}
end
if type(storage.manaitem2) ~= "table" then
    storage.manaitem2 = {on=false, title="MP%", item=238, min=0, delay=1000, priority=5}
end
if type(storage.manaitem3) ~= "table" then
    storage.manaitem3 = {on=false, title="MP%", item=238, min=0, delay=1000, priority=6}
end
if type(storage.stamina1) ~= "table" then
    storage.stamina1 = {on=false, title="STA", item=31335, min=30, delay=1000, priority=1}
end
if type(storage.stamina2) ~= "table" then
    storage.stamina2 = {on=false, title="STA", item=31335, min=20, delay=1000, priority=2}
end
if type(storage.fooditem1) ~= "table" then
    storage.fooditem1 = {on=false, title="FOOD", item=3582, hp=80, mp=80, delayMinutes=1, allowHidden=true, priority=1}
end
if type(storage.fooditem2) ~= "table" then
    storage.fooditem2 = {on=false, title="FOOD", item=3582, hp=65, mp=65, delayMinutes=1, allowHidden=true, priority=2}
end
if type(storage.fooditem3) ~= "table" then
    storage.fooditem3 = {on=false, title="FOOD", item=3582, hp=50, mp=50, delayMinutes=1, allowHidden=true, priority=3}
end

if storage.hpitem1.delay == nil then storage.hpitem1.delay = 1000 end
if storage.hpitem2.delay == nil then storage.hpitem2.delay = 1000 end
if storage.hpitem3.delay == nil then storage.hpitem3.delay = 1000 end
if storage.manaitem1.delay == nil then storage.manaitem1.delay = 1000 end
if storage.manaitem2.delay == nil then storage.manaitem2.delay = 1000 end
if storage.manaitem3.delay == nil then storage.manaitem3.delay = 1000 end
if storage.stamina1.delay == nil then storage.stamina1.delay = 1000 end
if storage.stamina2.delay == nil then storage.stamina2.delay = 1000 end
if storage.hpitem1.priority == nil then storage.hpitem1.priority = 1 end
if storage.hpitem2.priority == nil then storage.hpitem2.priority = 2 end
if storage.hpitem3.priority == nil then storage.hpitem3.priority = 3 end
if storage.manaitem1.priority == nil then storage.manaitem1.priority = 4 end
if storage.manaitem2.priority == nil then storage.manaitem2.priority = 5 end
if storage.manaitem3.priority == nil then storage.manaitem3.priority = 6 end
if storage.stamina1.priority == nil then storage.stamina1.priority = 1 end
if storage.stamina2.priority == nil then storage.stamina2.priority = 2 end
if storage.fooditem1.priority == nil then storage.fooditem1.priority = 1 end
if storage.fooditem2.priority == nil then storage.fooditem2.priority = 2 end
if storage.fooditem3.priority == nil then storage.fooditem3.priority = 3 end
if storage.fooditem1.delayMinutes == nil then storage.fooditem1.delayMinutes = 1 end
if storage.fooditem2.delayMinutes == nil then storage.fooditem2.delayMinutes = 1 end
if storage.fooditem3.delayMinutes == nil then storage.fooditem3.delayMinutes = 1 end
if storage.fooditem1.hp == nil then storage.fooditem1.hp = 100 end
if storage.fooditem2.hp == nil then storage.fooditem2.hp = 100 end
if storage.fooditem3.hp == nil then storage.fooditem3.hp = 100 end
if storage.fooditem1.mp == nil then storage.fooditem1.mp = 100 end
if storage.fooditem2.mp == nil then storage.fooditem2.mp = 100 end
if storage.fooditem3.mp == nil then storage.fooditem3.mp = 100 end
if storage.fooditem1.allowHidden == nil then storage.fooditem1.allowHidden = true end
if storage.fooditem2.allowHidden == nil then storage.fooditem2.allowHidden = true end
if storage.fooditem3.allowHidden == nil then storage.fooditem3.allowHidden = true end

for _, itemStorage in ipairs({storage.hpitem1, storage.hpitem2, storage.hpitem3, storage.manaitem1, storage.manaitem2, storage.manaitem3}) do
  cleanNumericKeys(itemStorage)
end
for _, itemStorage in ipairs({storage.fooditem1, storage.fooditem2, storage.fooditem3}) do
  itemStorage.allowHidden = itemStorage.allowHidden == true
  cleanNumericKeys(itemStorage)
end

migrateMinFromMax(storage.hpitem1)
migrateMinFromMax(storage.hpitem2)
migrateMinFromMax(storage.hpitem3)
migrateMinFromMax(storage.manaitem1)
migrateMinFromMax(storage.manaitem2)
migrateMinFromMax(storage.manaitem3)
migrateMinFromMax(storage.stamina1)
migrateMinFromMax(storage.stamina2)

healingItemMacros = healingItemMacros or {}

-- ====================================
-- MACRO UNIFICADO DE HEALING
-- ====================================

-- Arrays base de configuracao (prioridade definida no config)
local spellConfigs = {storage.healing1, storage.healing2, storage.healing3}
local hpItemConfigs = {storage.hpitem1, storage.hpitem2, storage.hpitem3}
local manaItemConfigs = {storage.manaitem1, storage.manaitem2, storage.manaitem3}
local staminaConfigs = {storage.stamina1, storage.stamina2}
local foodConfigs = {storage.fooditem1, storage.fooditem2, storage.fooditem3}

-- Controle de delays independentes
local spellLastUse = {0, 0, 0}
local hpItemLastUse = {0, 0, 0}
local manaItemLastUse = {0, 0, 0}
local staminaLastUse = {0, 0}
local foodLastUse = {0, 0, 0}

-- Funcao para atualizar referencias
updateHealingConfigs = function()
  spellConfigs = {storage.healing1, storage.healing2, storage.healing3}
  hpItemConfigs = {storage.hpitem1, storage.hpitem2, storage.hpitem3}
  manaItemConfigs = {storage.manaitem1, storage.manaitem2, storage.manaitem3}
  staminaConfigs = {storage.stamina1, storage.stamina2}
  foodConfigs = {storage.fooditem1, storage.fooditem2, storage.fooditem3}
end

local function hasItemInInventory(itemId, allowHidden)
  if not itemId or itemId <= 0 then return false end
  if g_game and g_game.findPlayerItem then
    local found = g_game.findPlayerItem(itemId, -1)
    if found then
      return true
    end
  end
  if findItem then
    local found = findItem(itemId)
    if found then
      return true
    end
    return false
  end
  local clientVersion = g_game.getClientVersion and g_game.getClientVersion() or 0
  if allowHidden and clientVersion >= 780 then
    return true
  end
  return false
end

local function getRangeMatch(configs, currentPercent, extraCheck)
  local enabled = {}
  for i, cfg in ipairs(configs) do
    if cfg and cfg.on then
      if not extraCheck or extraCheck(cfg) then
        local minValue = tonumber(cfg.min) or 0
        local priority = tonumber(cfg.priority) or 99
        table.insert(enabled, {index = i, config = cfg, min = minValue, priority = priority})
      end
    end
  end

  table.sort(enabled, function(a, b)
    if a.min == b.min then
      return a.priority < b.priority
    end
    return a.min > b.min
  end)

  for idx, entry in ipairs(enabled) do
    local lower = -1
    if idx < #enabled then
      lower = enabled[idx + 1].min
    end
    if currentPercent <= entry.min and currentPercent > lower then
      return entry
    end
  end

  return nil
end

local function getRangeFallbackMatches(configs, currentPercent, extraCheck)
  local enabled = {}
  for i, cfg in ipairs(configs) do
    if cfg and cfg.on then
      if not extraCheck or extraCheck(cfg) then
        local minValue = tonumber(cfg.min) or 0
        local priority = tonumber(cfg.priority) or 99
        table.insert(enabled, {index = i, config = cfg, min = minValue, priority = priority})
      end
    end
  end

  table.sort(enabled, function(a, b)
    if a.min == b.min then
      return a.priority < b.priority
    end
    return a.min > b.min
  end)

  local selectedIndex = nil
  for idx, entry in ipairs(enabled) do
    local lower = -1
    if idx < #enabled then
      lower = enabled[idx + 1].min
    end
    if currentPercent <= entry.min and currentPercent > lower then
      selectedIndex = idx
      break
    end
  end

  if not selectedIndex then
    return {}
  end

  local result = {}
  table.insert(result, enabled[selectedIndex])
  for idx = selectedIndex - 1, 1, -1 do
    table.insert(result, enabled[idx])
  end

  return result
end

-- ====================================
-- MACRO PRINCIPAL UNIFICADO
-- ====================================
local function hasActiveHealingNeed(currentHpPercent, currentManaPercent)
  local spellEntry = getRangeMatch(spellConfigs, currentHpPercent)
  if spellEntry then
    local manaMin = tonumber(spellEntry.config.mana) or 0
    if currentManaPercent >= manaMin then
      return true
    end
  end

  local hpItemEntries = getRangeFallbackMatches(hpItemConfigs, currentHpPercent, function(cfg)
    return cfg.item and cfg.item > 100
  end)
  if #hpItemEntries > 0 then
    return true
  end

  local manaItemEntries = getRangeFallbackMatches(manaItemConfigs, currentManaPercent, function(cfg)
    return cfg.item and cfg.item > 100
  end)
  if #manaItemEntries > 0 then
    return true
  end

  for _, cfg in ipairs(foodConfigs) do
    if cfg and cfg.on and cfg.item and cfg.item > 100 then
      local hpLimit = tonumber(cfg.hp) or 100
      local mpLimit = tonumber(cfg.mp) or 100
      if currentHpPercent <= hpLimit and currentManaPercent <= mpLimit then
        return true
      end
    end
  end

  return false
end

local healingMacroMain = macro(100, function()
  if not storage.healingSystemEnabled then
    standByHealing = true
    return
  end

  if g_game.isOnline and not g_game.isOnline() then
    return
  end
  if not player then
    return
  end

  -- Cache de valores (calcula uma vez por tick)
  local currentHpPercent = player:getHealthPercent()
  local maxMana = player:getMaxMana()
  local currentManaPercent = 0
  if maxMana and maxMana > 0 then
    currentManaPercent = math.min(100, math.floor(100 * (player:getMana() / maxMana)))
  end
  local currentTime = healingTimeNow()
  local usedSomething = false
  local somethingOnCooldown = false
  local canCastSpell = currentManaPercent >= 5

  -- Standby: retorna se nao houver necessidade ativa de cura
  if standByHealing and not hasActiveHealingNeed(currentHpPercent, currentManaPercent) then
    return
  end

  local spellEntry = getRangeMatch(spellConfigs, currentHpPercent)
  if spellEntry then
    local config = spellEntry.config
    local manaMin = tonumber(config.mana) or 0
    if canCastSpell and currentManaPercent >= manaMin then
      if currentTime - spellLastUse[spellEntry.index] >= (config.delay or 1000) then
        spellLastUse[spellEntry.index] = currentTime
        say(config.text)
        usedSomething = true
      else
        somethingOnCooldown = true
      end
    else
      somethingOnCooldown = true
    end
  end

  local itemCandidates = {}
  local hpEntries = getRangeFallbackMatches(hpItemConfigs, currentHpPercent, function(cfg)
    return cfg.item and cfg.item > 100
  end)
  for order, entry in ipairs(hpEntries) do
    table.insert(itemCandidates, {kind = "hp", entry = entry, rangeOrder = order})
  end

  local manaEntries = getRangeFallbackMatches(manaItemConfigs, currentManaPercent, function(cfg)
    return cfg.item and cfg.item > 100
  end)
  for order, entry in ipairs(manaEntries) do
    table.insert(itemCandidates, {kind = "mana", entry = entry, rangeOrder = order})
  end

  if #itemCandidates > 1 then
    table.sort(itemCandidates, function(a, b)
      local orderA = tonumber(a.rangeOrder) or 99
      local orderB = tonumber(b.rangeOrder) or 99
      if orderA ~= orderB then
        return orderA < orderB
      end
      local pa = tonumber(a.entry.config.priority) or 99
      local pb = tonumber(b.entry.config.priority) or 99
      if pa ~= pb then
        return pa < pb
      end
      return (tonumber(a.entry.min) or 0) < (tonumber(b.entry.min) or 0)
    end)
  end

  for _, candidate in ipairs(itemCandidates) do
    local entry = candidate.entry
    local config = entry.config
    local lastUse = candidate.kind == "hp" and hpItemLastUse or manaItemLastUse
    local lastIndex = entry.index

    if hasItemInInventory(config.item, true) then
      if currentTime - lastUse[lastIndex] >= (config.delay or 1000) then
        lastUse[lastIndex] = currentTime

        if TargetBot then
          TargetBot.useItem(config.item, config.subType, player)
        else
          local thing = g_things.getThingType(config.item)
          local subType = g_game.getClientVersion() >= 860 and 0 or 1
          if thing and thing:isFluidContainer() then
            subType = config.subType
          end
          g_game.useInventoryItemWith(config.item, player, subType)
        end

        usedSomething = true
        break
      else
        somethingOnCooldown = true
      end
    else
      somethingOnCooldown = true
    end
  end

  if usedSomething then
    standByHealing = true
    return
  end

  -- Se nada esta em cooldown, entra em standby
  if not somethingOnCooldown then
    standByHealing = true
  end
end)

local staminaMacro = macro(500, function()
  if not storage.healingSystemEnabled then return end
  if not stamina then return end
  if g_game and g_game.isOnline and not g_game.isOnline() then return end
  if not player then return end

  local currentStamina = stamina() / 60
  local entry = getRangeMatch(staminaConfigs, currentStamina, function(cfg)
    return cfg.item and cfg.item > 100
  end)
  if not entry then
    return
  end

  local config = entry.config
  local currentTime = healingTimeNow()
  if currentTime - staminaLastUse[entry.index] < (config.delay or 1000) then
    return
  end
  if not hasItemInInventory(config.item, true) then
    return
  end

  staminaLastUse[entry.index] = currentTime
  if TargetBot then
    TargetBot.useItem(config.item, config.subType, player)
  else
    local thing = g_things.getThingType(config.item)
    local subType = g_game.getClientVersion() >= 860 and 0 or 1
    if thing and thing:isFluidContainer() then
      subType = config.subType
    end
    g_game.useInventoryItemWith(config.item, player, subType)
  end
end)

local foodMacro = macro(500, function()
  if not storage.healingSystemEnabled then return end
  if not player then return end

  local currentHpPercent = player:getHealthPercent()
  local maxMana = player:getMaxMana()
  local currentManaPercent = 0
  if maxMana and maxMana > 0 then
    currentManaPercent = math.min(100, math.floor(100 * (player:getMana() / maxMana)))
  end

  local candidates = {}
  for i, cfg in ipairs(foodConfigs) do
    if cfg and cfg.on and cfg.item and cfg.item > 100 then
      local hpLimit = tonumber(cfg.hp) or 100
      local mpLimit = tonumber(cfg.mp) or 100
      if currentHpPercent <= hpLimit and currentManaPercent <= mpLimit then
        local prio = tonumber(cfg.priority) or 99
        table.insert(candidates, { index = i, config = cfg, priority = prio })
      end
    end
  end

  if #candidates == 0 then
    return
  end

  if #candidates > 1 then
    table.sort(candidates, function(a, b)
      if a.priority ~= b.priority then
        return a.priority < b.priority
      end
      return a.index < b.index
    end)
  end

  local currentTime = healingTimeNow()
  for _, candidate in ipairs(candidates) do
    local cfg = candidate.config
    local delayMs = minutesToMs(cfg.delayMinutes or 1)
    if delayMs < 1000 then
      delayMs = 1000
    end

    local hasVisibleItem = hasItemInInventory(cfg.item, false)
    local canUseHidden = cfg.allowHidden ~= false and canUseInventoryHotkeyWithoutVisibleItem(cfg.item)
    if currentTime - foodLastUse[candidate.index] >= delayMs and (hasVisibleItem or canUseHidden) then
      if useFoodEntry(cfg) then
        foodLastUse[candidate.index] = currentTime
        return
      end
    end
  end
end)

-- ====================================
-- MACROS DUMMY PARA ON/OFF INDIVIDUAL
-- ====================================
for i = 1, 3 do
  healingSpellMacros[i] = {
    setOn = function(state)
      spellConfigs[i].on = state
      updateHealingConfigs()
    end,
    setOff = function()
      spellConfigs[i].on = false
      updateHealingConfigs()
    end,
    isOn = function() return spellConfigs[i].on end
  }
end

for i = 1, 6 do
  healingItemMacros[i] = {
    setOn = function(state)
      if i <= 3 then
        hpItemConfigs[i].on = state
      else
        manaItemConfigs[i-3].on = state
      end
      updateHealingConfigs()
    end,
    setOff = function()
      if i <= 3 then
        hpItemConfigs[i].on = false
      else
        manaItemConfigs[i-3].on = false
      end
      updateHealingConfigs()
    end,
    isOn = function()
      if i <= 3 then
        return hpItemConfigs[i].on
      else
        return manaItemConfigs[i-3].on
      end
    end
  }
end

local function buildItemsTab(panel)
  -- Usa o ScrollablePanel interno do HealingPanel
  panel = panel:getChildById('panelContent') or panel

  local header = setupUI([[
Panel
  height: 16
  layout:
    type: horizontalBox
    spacing: 3

  Label
    id: colOn
    text: ON
    width: 28
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colType
    text: Tp
    width: 22
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colItem
    text: It
    width: 24
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colMin
    text: Min
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colDelay
    text: Delay
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colPrio
    text: Prio
    width: 40
    text-align: center
    font: verdana-11px-rounded
]], panel)
  for _, colId in ipairs({"colOn", "colType", "colItem", "colMin", "colDelay", "colPrio"}) do
    if header[colId] and header[colId].setColor then
      header[colId]:setColor('#E8E8E8')
    end
  end
  setStandardTooltip(header, "Tabela de Itens de Cura: configure potions/itens de HP e mana.", "Healing Items table: configure HP and mana potions/items.")
  setStandardTooltip(header.colOn, "Tabela de Itens de Cura: ativa/desativa o slot do item.", "Healing Items table: enable or disable the item slot.")
  setStandardTooltip(header.colType, "Tabela de Itens de Cura: Tp = HP ou MP.", "Healing Items table: Tp = HP or MP.")
  setStandardTooltip(header.colItem, "Tabela de Itens de Cura: item usado para curar.", "Healing Items table: item used for healing.")
  setStandardTooltip(header.colMin, "Tabela de Itens de Cura: percentual minimo para usar.", "Healing Items table: minimum percent to use.")
  setStandardTooltip(header.colDelay, "Tabela de Itens de Cura: delay entre usos (segundos).", "Healing Items table: delay between uses (seconds).")
  setStandardTooltip(header.colPrio, "Tabela de Itens de Cura: prioridade (1 = maior).", "Healing Items table: priority (1 = highest).")

  local itemRows = {}
  if type(storage.hpitem1) ~= "table" then storage.hpitem1 = {on=false, title="HP%", item=3160, min=0, delay=1000, priority=1} end
  if type(storage.hpitem2) ~= "table" then storage.hpitem2 = {on=false, title="HP%", item=3160, min=0, delay=1000, priority=2} end
  if type(storage.hpitem3) ~= "table" then storage.hpitem3 = {on=false, title="HP%", item=3160, min=0, delay=1000, priority=3} end
  if type(storage.manaitem1) ~= "table" then storage.manaitem1 = {on=false, title="MP%", item=23373, min=0, delay=1000, priority=4} end
  if type(storage.manaitem2) ~= "table" then storage.manaitem2 = {on=false, title="MP%", item=238, min=0, delay=1000, priority=5} end
  if type(storage.manaitem3) ~= "table" then storage.manaitem3 = {on=false, title="MP%", item=238, min=0, delay=1000, priority=6} end
  local itemEntries = {
    {config = storage.hpitem1, typeLabel = "HP", index = 1},
    {config = storage.hpitem2, typeLabel = "HP", index = 2},
    {config = storage.hpitem3, typeLabel = "HP", index = 3},
    {config = storage.manaitem1, typeLabel = "MP", index = 4},
    {config = storage.manaitem2, typeLabel = "MP", index = 5},
    {config = storage.manaitem3, typeLabel = "MP", index = 6}
  }

  for _, entry in ipairs(itemEntries) do
    local healingInfo2 = entry.config
    if healingInfo2.min == nil then healingInfo2.min = 0 end
    if healingInfo2.delay == nil then healingInfo2.delay = 1000 end
    healingInfo2.priority = normalizePriority(healingInfo2.priority, 6)

    local row = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 3

  SmallBotSwitch
    id: enabled
    width: 28
    height: 18
    text-align: center
    text: ON

  Label
    id: type
    width: 22
    text-align: center
    font: verdana-11px-rounded

  BotItem
    id: item
    size: 22 22

  SpinBox
    id: min
    width: 40
    height: 18
    text-align: center
    font: verdana-11px-rounded
    minimum: 0
    maximum: 100
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: delay
    width: 40
    height: 18
    text-align: center
    font: verdana-11px-rounded
    minimum: 0.1
    maximum: 999999
    step: 0.1
    editable: true
    focusable: true

  SpinBox
    id: priority
    width: 40
    height: 18
    text-align: center
    font: verdana-11px-rounded
    minimum: 1
    maximum: 6
    step: 1
    editable: true
    focusable: true
]], panel)

    row.enabled:setOn(healingInfo2.on)
    setStandardTooltip(row.enabled, "Ativa ou desativa este item de cura.", "Enable or disable this healing item.")
    row.enabled.onClick = function(widget)
      healingInfo2.on = not healingInfo2.on
      widget:setOn(healingInfo2.on)
      updateHealingConfigs()
    end

    row.type:setText(entry.typeLabel)
    setStandardTooltip(row.type, "HP = cura HP; MP = cura mana.", "HP = heals HP; MP = heals mana.")

    row.item:setItemId(healingInfo2.item or 0)
    setStandardTooltip(row.item, "Arraste o item para configurar o ID.", "Drag the item to set its ID.")
    row.item.onItemChange = function(widget)
      healingInfo2.item = widget:getItemId()
      healingInfo2.subType = widget:getItemSubType()
    end

    row.min:setValue(healingInfo2.min)
    setStandardTooltip(row.min, "Porcentagem minima para usar este item.", "Minimum percent to use this item.")
    row.min.onValueChange = function(widget, value)
      healingInfo2.min = value
    end

    row.delay:setValue(delayMsToSeconds(healingInfo2.delay))
    setStandardTooltip(row.delay, "Delay minimo entre usos (segundos).", "Minimum delay between uses (seconds).")
    row.delay.onValueChange = function(widget, value)
      healingInfo2.delay = secondsToMs(value)
    end

    row.priority:setValue(healingInfo2.priority)
    setStandardTooltip(row.priority, "Prioridade deste item (1 = mais alta).", "Priority for this item (1 = highest).")
    itemRows[entry.index] = {widget = row, config = healingInfo2}

    row.priority.onValueChange = function(widget, value)
      if healingUiSyncing then
        return
      end
      local newPriority = tonumber(value) or healingInfo2.priority or 1
      newPriority = math.floor(newPriority + 0.5)
      if newPriority < 1 then newPriority = 1 end
      if newPriority > 6 then newPriority = 6 end
      if newPriority == healingInfo2.priority then
        healingUiSyncing = true
        widget:setValue(healingInfo2.priority)
        healingUiSyncing = false
        return
      end
      healingUiSyncing = true
      local oldPriority = healingInfo2.priority
      for _, other in pairs(itemRows) do
        if other.config ~= healingInfo2 and other.config.priority == newPriority then
          other.config.priority = oldPriority
          other.widget.priority:setValue(oldPriority)
          break
        end
      end
      healingInfo2.priority = newPriority
      widget:setValue(newPriority)
      healingUiSyncing = false
    end
  end
  healingUiRefs.items = itemRows

  if g_game.getClientVersion() < 780 then
    local warningLabel = g_ui.createWidget('BotLabel', panel)
    warningLabel:setText("In old tibia potions & runes work only when you have backpack with them opened")
    warningLabel:setColor('#FFFFFF')
  end
end

local function buildStaminaTab(panel)
  panel = panel:getChildById('panelContent') or panel

  local header = setupUI([[
Panel
  height: 16
  layout:
    type: horizontalBox
    spacing: 3

  Label
    id: colOn
    text: ON
    width: 28
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colType
    text: STA
    width: 28
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colItem
    text: It
    width: 24
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colMin
    text: Qtd
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colPrio
    text: Prio
    width: 40
    text-align: center
    font: verdana-11px-rounded
]], panel)
  for _, colId in ipairs({"colOn", "colType", "colItem", "colMin", "colPrio"}) do
    if header[colId] and header[colId].setColor then
      header[colId]:setColor('#E8E8E8')
    end
  end
  setStandardTooltip(header, "Tabela de Auto Stamina: configure itens para recuperar stamina por horas.", "Auto Stamina table: configure items to recover stamina by hours.")
  setStandardTooltip(header.colOn, "Tabela de Auto Stamina: ativa/desativa o slot.", "Auto Stamina table: enable or disable the slot.")
  setStandardTooltip(header.colType, "Tabela de Auto Stamina: STA = stamina.", "Auto Stamina table: STA = stamina.")
  setStandardTooltip(header.colItem, "Tabela de Auto Stamina: item de stamina usado.", "Auto Stamina table: stamina item used.")
  setStandardTooltip(header.colMin, "Tabela de Auto Stamina: horas de stamina minima.", "Auto Stamina table: minimum stamina hours.")
  setStandardTooltip(header.colPrio, "Tabela de Auto Stamina: prioridade (1 = maior).", "Auto Stamina table: priority (1 = highest).")

  local staminaRows = {}
  if type(storage.stamina1) ~= "table" then storage.stamina1 = {on=false, title="STA", item=31335, min=30, delay=1000, priority=1} end
  if type(storage.stamina2) ~= "table" then storage.stamina2 = {on=false, title="STA", item=31335, min=20, delay=1000, priority=2} end
  local staminaEntries = {
    {config = storage.stamina1, index = 1},
    {config = storage.stamina2, index = 2}
  }

  for _, entry in ipairs(staminaEntries) do
    local cfg = entry.config
    if cfg.min == nil then cfg.min = 0 end
    if cfg.delay == nil then cfg.delay = 1000 end
    cfg.priority = normalizePriority(cfg.priority, 2)

    local row = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 3

  SmallBotSwitch
    id: enabled
    width: 28
    height: 18
    text-align: center
    text: ON

  Label
    id: type
    width: 28
    text-align: center
    font: verdana-11px-rounded

  BotItem
    id: item
    size: 22 22

  SpinBox
    id: min
    width: 40
    height: 18
    text-align: center
    font: verdana-11px-rounded
    minimum: 0
    maximum: 42
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: priority
    width: 40
    height: 18
    text-align: center
    font: verdana-11px-rounded
    minimum: 1
    maximum: 2
    step: 1
    editable: true
    focusable: true
]], panel)

    row.enabled:setOn(cfg.on)
    setStandardTooltip(row.enabled, "Ativa ou desativa este slot de stamina.", "Enable or disable this stamina slot.")
    row.enabled.onClick = function(widget)
      cfg.on = not cfg.on
      widget:setOn(cfg.on)
      updateHealingConfigs()
    end

    row.type:setText('STA')

    row.item:setItemId(cfg.item or 0)
    setStandardTooltip(row.item, "Arraste o item de stamina para configurar o ID.", "Drag the stamina item to set its ID.")
    row.item.onItemChange = function(widget)
      cfg.item = widget:getItemId()
      cfg.subType = widget:getItemSubType()
    end

    row.min:setValue(cfg.min)
    setStandardTooltip(row.min, "Stamina (horas) minima para usar o item.", "Minimum stamina (hours) to use the item.")
    row.min.onValueChange = function(widget, value)
      cfg.min = value
    end

    row.priority:setValue(cfg.priority)
    setStandardTooltip(row.priority, "Prioridade deste slot de stamina (1 = mais alta).", "Priority for this stamina slot (1 = highest).")
    staminaRows[entry.index] = {widget = row, config = cfg}

    row.priority.onValueChange = function(widget, value)
      if healingUiSyncing then
        return
      end
      local newPriority = tonumber(value) or cfg.priority or 1
      newPriority = math.floor(newPriority + 0.5)
      if newPriority < 1 then newPriority = 1 end
      if newPriority > 2 then newPriority = 2 end
      if newPriority == cfg.priority then
        healingUiSyncing = true
        widget:setValue(cfg.priority)
        healingUiSyncing = false
        return
      end
      healingUiSyncing = true
      local oldPriority = cfg.priority
      for _, other in pairs(staminaRows) do
        if other.config ~= cfg and other.config.priority == newPriority then
          other.config.priority = oldPriority
          other.widget.priority:setValue(oldPriority)
          break
        end
      end
      cfg.priority = newPriority
      widget:setValue(newPriority)
      healingUiSyncing = false
    end
  end

  setupUI([[Panel
  height: 6
]], panel)

  local foodHeader = setupUI([[
Panel
  height: 16
  layout:
    type: horizontalBox
    spacing: 3

  Label
    id: colOn
    text: ON
    width: 28
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colType
    text: Tp
    width: 28
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colItem
    text: It
    width: 24
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colHp
    text: HP
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colMp
    text: MP
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colDelay
    text: Delay
    width: 40
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colPrio
    text: Prio
    width: 40
    text-align: center
    font: verdana-11px-rounded
]], panel)
  for _, colId in ipairs({"colOn", "colType", "colItem", "colHp", "colMp", "colDelay", "colPrio"}) do
    if foodHeader[colId] and foodHeader[colId].setColor then
      foodHeader[colId]:setColor('#E8E8E8')
    end
  end
  setStandardTooltip(foodHeader, "Tabela de Foods: usa food por HP/MP, delay em minutos e prioridade.", "Food table: use food by HP/MP, delay in minutes and priority.")
  setStandardTooltip(foodHeader.colOn, "Tabela de Foods: ativa/desativa o slot.", "Food table: enable or disable this slot.")
  setStandardTooltip(foodHeader.colType, "Tabela de Foods: tipo FOOD (uso autodetectado).", "Food table: FOOD type (auto-detected use).")
  setStandardTooltip(foodHeader.colItem, "Tabela de Foods: item usado.", "Food table: item used.")
  setStandardTooltip(foodHeader.colHp, "Tabela de Foods: HP maximo (%) para usar.", "Food table: maximum HP (%) to use.")
  setStandardTooltip(foodHeader.colMp, "Tabela de Foods: MP maximo (%) para usar.", "Food table: maximum MP (%) to use.")
  setStandardTooltip(foodHeader.colDelay, "Tabela de Foods: delay em minutos.", "Food table: delay in minutes.")
  setStandardTooltip(foodHeader.colPrio, "Tabela de Foods: prioridade (1 = maior).", "Food table: priority (1 = highest).")

  if type(storage.fooditem1) ~= "table" then storage.fooditem1 = {on=false, title="FOOD", item=3582, hp=80, mp=80, delayMinutes=1, allowHidden=true, priority=1} end
  if type(storage.fooditem2) ~= "table" then storage.fooditem2 = {on=false, title="FOOD", item=3582, hp=65, mp=65, delayMinutes=1, allowHidden=true, priority=2} end
  if type(storage.fooditem3) ~= "table" then storage.fooditem3 = {on=false, title="FOOD", item=3582, hp=50, mp=50, delayMinutes=1, allowHidden=true, priority=3} end

  local foodRows = {}
  local foodEntries = {
    {config = storage.fooditem1, index = 1},
    {config = storage.fooditem2, index = 2},
    {config = storage.fooditem3, index = 3}
  }

  for _, entry in ipairs(foodEntries) do
    local cfg = entry.config
    cfg.on = cfg.on == true
    cfg.item = tonumber(cfg.item) or 0
    cfg.hp = tonumber(cfg.hp) or 100
    cfg.mp = tonumber(cfg.mp) or 100
    cfg.delayMinutes = tonumber(cfg.delayMinutes) or 1
    if cfg.delayMinutes < 0.1 then cfg.delayMinutes = 0.1 end
    if cfg.allowHidden == nil then cfg.allowHidden = true end
    cfg.allowHidden = cfg.allowHidden == true
    cfg.priority = normalizePriority(cfg.priority, 3)

    local row = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 3

  SmallBotSwitch
    id: enabled
    width: 28
    height: 18
    text-align: center
    text: ON

  Label
    id: type
    width: 28
    height: 20
    text-align: center
    text-auto-resize: true
    font: verdana-11px-rounded

  BotItem
    id: item
    size: 22 22

  SpinBox
    id: hp
    width: 40
    height: 18
    text-align: center
    font: verdana-11px-rounded
    minimum: 1
    maximum: 100
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: mp
    width: 40
    height: 18
    text-align: center
    font: verdana-11px-rounded
    minimum: 1
    maximum: 100
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: delayMinutes
    width: 40
    height: 18
    text-align: center
    font: verdana-11px-rounded
    minimum: 0.1
    maximum: 120
    step: 0.1
    editable: true
    focusable: true

  SpinBox
    id: priority
    width: 40
    height: 18
    text-align: center
    font: verdana-11px-rounded
    minimum: 1
    maximum: 3
    step: 1
    editable: true
    focusable: true
]], panel)

    row.enabled:setOn(cfg.on)
    setStandardTooltip(row.enabled, "Ativa ou desativa este slot de food.", "Enable or disable this food slot.")
    row.enabled.onClick = function(widget)
      cfg.on = not cfg.on
      widget:setOn(cfg.on)
      updateHealingConfigs()
    end

    row.type:setText('Food')
    setStandardTooltip(row.type, "Tipo do slot: FOOD (uso autodetectado).", "Slot type: FOOD (auto-detected use).")
    row.item:setItemId(cfg.item or 0)
    setStandardTooltip(row.item, "Arraste o item de food para configurar o ID.", "Drag the food item to set its ID.")
    row.item.onItemChange = function(widget)
      cfg.item = widget:getItemId()
      cfg.subType = widget:getItemSubType()
    end

    row.hp:setValue(cfg.hp)
    setStandardTooltip(row.hp, "Usa food quando HP estiver menor ou igual a este valor (%).", "Use food when HP is lower than or equal to this value (%).")
    row.hp.onValueChange = function(widget, value)
      cfg.hp = value
    end

    row.mp:setValue(cfg.mp)
    setStandardTooltip(row.mp, "Usa food quando MP estiver menor ou igual a este valor (%).", "Use food when MP is lower than or equal to this value (%).")
    row.mp.onValueChange = function(widget, value)
      cfg.mp = value
    end

    row.delayMinutes:setValue(delayMsToMinutes(minutesToMs(cfg.delayMinutes)))
    setStandardTooltip(row.delayMinutes, "Delay minimo entre usos (minutos).", "Minimum delay between uses (minutes).")
    row.delayMinutes.onValueChange = function(widget, value)
      local v = tonumber(value) or 1
      if v < 0.1 then v = 0.1 end
      cfg.delayMinutes = v
    end

    row.priority:setValue(cfg.priority)
    setStandardTooltip(row.priority, "Prioridade deste food (1 = mais alta).", "Priority for this food (1 = highest).")
    foodRows[entry.index] = {widget = row, config = cfg}
    row.priority.onValueChange = function(widget, value)
      if healingUiSyncing then
        return
      end
      local newPriority = tonumber(value) or cfg.priority or 1
      newPriority = math.floor(newPriority + 0.5)
      if newPriority < 1 then newPriority = 1 end
      if newPriority > 3 then newPriority = 3 end
      if newPriority == cfg.priority then
        healingUiSyncing = true
        widget:setValue(cfg.priority)
        healingUiSyncing = false
        return
      end
      healingUiSyncing = true
      local oldPriority = cfg.priority
      for _, other in pairs(foodRows) do
        if other.config ~= cfg and other.config.priority == newPriority then
          other.config.priority = oldPriority
          other.widget.priority:setValue(oldPriority)
          break
        end
      end
      cfg.priority = newPriority
      widget:setValue(newPriority)
      healingUiSyncing = false
    end
  end

  healingUiRefs.stamina = staminaRows
  healingUiRefs.foods = foodRows
end

local function buildHealingTab(panel)
  buildSpellsTab(panel)
  local content = getTabContent(panel)
  if not content then
    return
  end

  local splitRowHeight = 430
  local splitRow = setupUI([[
Panel
  height: 430
  layout:
    type: horizontalBox
    spacing: 8
]], content)
  splitRow:setWidth(560)
  splitRow:setHeight(splitRowHeight)

  local leftColumn = setupUI([[
Panel
  height: 430
  layout:
    type: verticalBox
    spacing: 4
]], splitRow)

  local rightColumn = setupUI([[
Panel
  height: 430
  layout:
    type: verticalBox
    spacing: 4
]], splitRow)

  local function applySplitWidths()
    local totalW = content:getWidth() or 0
    if totalW <= 0 then
      totalW = 560
    end
    local spacing = 8
    local rightW = 320
    local leftW = totalW - rightW - spacing
    if leftW < 220 then
      leftW = 220
      rightW = totalW - leftW - spacing
    end
    if rightW < 260 then
      rightW = 260
      leftW = totalW - rightW - spacing
    end
    splitRow:setWidth(leftW + rightW + spacing)
    leftColumn:setWidth(leftW)
    rightColumn:setWidth(rightW)
    leftColumn:setHeight(splitRowHeight)
    rightColumn:setHeight(splitRowHeight)
    splitRow:setHeight(splitRowHeight)
  end

  applySplitWidths()
  buildItemsTab(leftColumn)
  buildStaminaTab(leftColumn)
  buildAutomaticMacrosPanel(rightColumn)
  buildToolsOthersOptions(rightColumn, { marginTop = 2, height = 96 })

  refreshLayout(leftColumn)
  refreshLayout(rightColumn)
  refreshLayout(splitRow)
  refreshLayout(content)
  if schedule then
    schedule(30, function()
      if not content or (content.isDestroyed and content:isDestroyed()) then
        return
      end
      applySplitWidths()
      refreshLayout(leftColumn)
      refreshLayout(rightColumn)
      refreshLayout(splitRow)
      refreshLayout(content)
    end)
  end
end

local captureHpProfileState

local HP_PROFILE_KEYS = {
  "acceptPartyEnabled",
  "acceptPartyOnlyLeaders",
  "antiParalyzeEnabled",
  "antiParalyzeFilters",
  "antiParalyzeManaMin",
  "autoBuffEnabled",
  "autoBuffFilters",
  "autoBuffManaMin",
  "autoBuffText",
  "autoHasteEnabled",
  "autoHasteFilters",
  "autoHasteManaMin",
  "curarFriends",
  "EditSpellsAntiParalyze",
  "EditSpellsHasteSpell",
  "familiarDelay",
  "familiarEnabled",
  "familiarFilters",
  "familiarManaMin",
  "familiarSpell",
  "fooditem1",
  "fooditem2",
  "fooditem3",
  "castEnabled",
  "castText",
  "castDelay",
  "healing1",
  "healing2",
  "healing3",
  "healingSystemEnabled",
  "hpitem1",
  "hpitem2",
  "hpitem3",
  "inviteKeyword",
  "inviteMessage",
  "manaitem1",
  "manaitem2",
  "manaitem3",
  "maxLevel",
  "maxPartyMembers",
  "minLevel",
  "nextBpEnabled",
  "nextBpIds",
  "partyAvisoMacroEnabled",
  "partyBlacklist",
  "partyDebugMacroEnabled",
  "partyEnabled",
  "partyLeaders",
  "partyPassword",
  "pedirPTEnabled",
  "recoveryDelay",
  "recoveryEnabled",
  "recoveryFilters",
  "recoveryManaMin",
  "recoverySpell",
  "stamina1",
  "stamina2",
  "toolsEnabled",
  "toolsMacrosEnabled",
  "warningMessage"
}

local function setHealingPresetSpell(data, index, text)
  local key = "healing" .. tostring(index)
  local entry = data[key]
  if type(entry) ~= "table" then
    entry = { on = false, title = "HP%", text = "", min = 0, delay = 1000, mana = 0, priority = index }
  end
  entry.title = entry.title or "HP%"
  entry.text = text or ""
  if entry.min == nil then entry.min = 0 end
  if entry.mana == nil then entry.mana = 0 end
  if entry.delay == nil then entry.delay = 1000 end
  entry.priority = entry.priority or index
  data[key] = entry
end

local function buildHealingPresetData(baseSnapshot, spells)
  local data = cloneTable(baseSnapshot)
  setHealingPresetSpell(data, 1, spells and spells[1])
  setHealingPresetSpell(data, 2, spells and spells[2])
  setHealingPresetSpell(data, 3, spells and spells[3])
  return data
end

local hpProfileDebugState = {
  bootLogged = false,
  lastSanitizedProfile = nil
}

--[[
PROFILE PERSISTENCE STANDARD (2026-03)
- Canonical state: storage.hpToolsProfiles.meta.activeProfile
- Profile model: configs[id] + order + nextId + meta
- Fallback rule: first valid profile id from order/configs
- "Config 1" is created only when profiles are empty
- Legacy list/data/selectedId is migrated and then cleared
- Runtime switch flow: save previous -> set activeProfile -> apply selected
- Temporary audit logs:
  BOOT Active profile loaded
  SANITIZE Active profile after sanitize
  APPLY Applying profile
]]
local function trimHpProfileText(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function isHpProfileIdValid(profiles, profileId)
  local id = trimHpProfileText(profileId)
  if id == "" then
    return false
  end
  return type(profiles.configs[id]) == "table"
end

local function getFirstHpProfileId(profiles)
  for _, id in ipairs(profiles.order or {}) do
    if type(profiles.configs[id]) == "table" then
      return id
    end
  end
  return ""
end

local function setHpActiveProfile(profiles, profileId)
  local id = trimHpProfileText(profileId)
  if not isHpProfileIdValid(profiles, id) then
    id = getFirstHpProfileId(profiles)
  end
  profiles.meta.activeProfile = id
  return id
end

local function ensureHpProfiles()
  if type(storage.hpToolsProfiles) ~= "table" then
    storage.hpToolsProfiles = {}
  end

  local profiles = storage.hpToolsProfiles
  local legacyList = type(profiles.list) == "table" and profiles.list or {}
  local legacyData = type(profiles.data) == "table" and profiles.data or {}
  local legacySelectedId = trimHpProfileText(profiles.selectedId)
  local existingConfigs = type(profiles.configs) == "table" and profiles.configs or {}
  local existingOrder = type(profiles.order) == "table" and profiles.order or {}

  local normalizedConfigs = {}
  local normalizedOrder = {}
  local seenIds = {}

  local function addProfileEntry(rawId, rawName, rawData)
    local id = trimHpProfileText(rawId)
    if id == "" or seenIds[id] then
      return
    end
    seenIds[id] = true
    local name = trimHpProfileText(rawName)
    if name == "" then
      name = id
    end

    local dataTable = nil
    if type(rawData) == "table" then
      dataTable = rawData
    elseif type(existingConfigs[id]) == "table" and type(existingConfigs[id].data) == "table" then
      dataTable = existingConfigs[id].data
    elseif type(legacyData[id]) == "table" then
      dataTable = legacyData[id]
    end
    if type(dataTable) ~= "table" then
      dataTable = {}
    end

    normalizedConfigs[id] = {
      name = name,
      data = dataTable
    }
    table.insert(normalizedOrder, id)
  end

  for _, rawId in ipairs(existingOrder) do
    local id = trimHpProfileText(rawId)
    local entry = type(existingConfigs[id]) == "table" and existingConfigs[id] or nil
    addProfileEntry(id, entry and entry.name or id, entry and entry.data or nil)
  end

  for _, entry in ipairs(legacyList) do
    local id = trimHpProfileText(entry and entry.id)
    addProfileEntry(id, entry and entry.name or id, legacyData[id])
  end

  for rawId, entry in pairs(existingConfigs) do
    if type(rawId) == "string" and type(entry) == "table" then
      addProfileEntry(rawId, entry.name or rawId, entry.data)
    end
  end

  for rawId, dataValue in pairs(legacyData) do
    if type(rawId) == "string" and type(dataValue) == "table" then
      addProfileEntry(rawId, rawId, dataValue)
    end
  end

  profiles.configs = normalizedConfigs
  profiles.order = normalizedOrder
  profiles.list = nil
  profiles.data = nil
  profiles.selectedId = nil
  profiles.nextId = tonumber(profiles.nextId) or 1
  if profiles.nextId < 1 then
    profiles.nextId = 1
  end
  profiles.meta = type(profiles.meta) == "table" and profiles.meta or {}
  profiles.meta.activeProfile = trimHpProfileText(profiles.meta.activeProfile)

  if #profiles.order == 0 then
    local defaultId = "cfg_1"
    profiles.configs[defaultId] = profiles.configs[defaultId] or {
      name = "Config 1",
      data = type(captureHpProfileState) == "function" and captureHpProfileState() or {}
    }
    table.insert(profiles.order, defaultId)
    if profiles.nextId < 2 then
      profiles.nextId = 2
    end
  end

  local maxId = 0
  for _, id in ipairs(profiles.order) do
    local num = tonumber(tostring(id):match("^cfg_(%d+)$"))
    if num and num > maxId then
      maxId = num
    end
  end
  if profiles.nextId <= maxId then
    profiles.nextId = maxId + 1
  end

  if trimHpProfileText(profiles.meta.activeProfile) == "" then
    profiles.meta.activeProfile = legacySelectedId
  end
  local activeId = setHpActiveProfile(profiles, profiles.meta.activeProfile)
  if activeId ~= "" and type(profiles.configs[activeId].data) ~= "table" then
    profiles.configs[activeId].data = type(captureHpProfileState) == "function" and captureHpProfileState() or {}
  end

  if not profiles.presetsInstalled and type(captureHpProfileState) == "function" then
    local baseSnapshot = captureHpProfileState()

    local function addPreset(name, spells)
      for _, id in ipairs(profiles.order) do
        local cfg = profiles.configs[id]
        if type(cfg) == "table" and cfg.name == name then
          return
        end
      end
      local id = "cfg_" .. tostring(profiles.nextId)
      profiles.nextId = profiles.nextId + 1
      profiles.configs[id] = {
        name = name,
        data = buildHealingPresetData(baseSnapshot, spells)
      }
      table.insert(profiles.order, id)
    end

    addPreset("EK 500", { "exura ico", "exura gran ico", "" })
    addPreset("ED 500", { "exura", "exura vita", "exura gran" })
    addPreset("MS", { "exura", "exura vita", "exura gran" })
    addPreset("RP 500", { "exura", "exura san", "exura gran san" })
    addPreset("MONK 500", { "exura", "exura vita", "exura gran" })

    profiles.presetsInstalled = true
    activeId = setHpActiveProfile(profiles, profiles.meta.activeProfile)
  end

  if not hpProfileDebugState.bootLogged then
    if type(ImperialElfBot_IsProfileLoaded) == "function" and ImperialElfBot_IsProfileLoaded() then
      print("BOOT Active profile loaded: " .. activeId)
    end
    hpProfileDebugState.bootLogged = true
  end
  if hpProfileDebugState.lastSanitizedProfile ~= activeId then
    if type(ImperialElfBot_IsProfileLoaded) == "function" and ImperialElfBot_IsProfileLoaded() then
      print("SANITIZE Active profile after sanitize: " .. activeId)
    end
    hpProfileDebugState.lastSanitizedProfile = activeId
  end

  return profiles
end

local function getHpProfileName(id)
  if not id or id == "" then return "Sem perfil" end
  local profiles = ensureHpProfiles()
  for _, profileId in ipairs(profiles.order) do
    if profileId == id then
      local cfg = profiles.configs[profileId]
      if type(cfg) == "table" then
        return cfg.name or profileId
      end
      return profileId
    end
  end
  return id
end

local function getSelectedHpProfileId()
  local profiles = ensureHpProfiles()
  return setHpActiveProfile(profiles, profiles.meta.activeProfile)
end

captureHpProfileState = function()
  local data = {}
  for _, key in ipairs(HP_PROFILE_KEYS) do
    data[key] = cloneTable(storage[key])
  end
  return data
end

local function saveHpProfileState(profileId)
  if not profileId or profileId == "" then return end
  local profiles = ensureHpProfiles()
  local id = setHpActiveProfile(profiles, profileId)
  if id == "" then
    return
  end
  if type(profiles.configs[id]) ~= "table" then
    return
  end
  profiles.configs[id].data = captureHpProfileState()
end

local function applyHpProfileState(profileId)
  if not profileId or profileId == "" then return end
  local profiles = ensureHpProfiles()
  local id = setHpActiveProfile(profiles, profileId)
  if id == "" then
    return
  end
  if type(ImperialElfBot_IsProfileLoaded) == "function" and ImperialElfBot_IsProfileLoaded() then
    print("APPLY Applying profile: " .. id)
  end
  local cfg = profiles.configs[id]
  local data = type(cfg) == "table" and cfg.data or nil
  if type(data) ~= "table" then
    if type(cfg) == "table" then
      cfg.data = captureHpProfileState()
    end
    return
  end
  for _, key in ipairs(HP_PROFILE_KEYS) do
    local value = data[key]
    if value ~= nil then
      if type(value) == "table" then
        if type(storage[key]) == "table" then
          applyTableData(storage[key], value)
        else
          storage[key] = cloneTable(value)
        end
      else
        storage[key] = value
      end
    end
  end
  applyHealingDefaults()
  if storage.partyBlacklist and type(storage.partyBlacklist) == "table" then
    blacklist = storage.partyBlacklist
  end
  if storage.partyLeaders and type(storage.partyLeaders) == "table" then
    leaders = storage.partyLeaders
  end
  partyEnabled = storage.partyEnabled == true
  maxLevel = storage.maxLevel or 0
  minLevel = storage.minLevel or 0
  maxPartyMembers = storage.maxPartyMembers or 21
  inviteMessage = storage.inviteMessage or "Kelus Scripts"
  warningMessage = storage.warningMessage or "Kelus Scripts"
  inviteKeyword = storage.inviteKeyword or "Manda PT"
  partyPassword = storage.partyPassword or ""
  pedirPTEnabled = storage.pedirPTEnabled == true
  avisoMacroEnabled = storage.partyAvisoMacroEnabled == true
  debugMacroEnabled = storage.partyDebugMacroEnabled == true
  acceptPartyEnabled = storage.acceptPartyEnabled == true
  acceptPartyOnlyLeaders = storage.acceptPartyOnlyLeaders == true
  if type(setPartyEnabled) == "function" then
    setPartyEnabled(storage.partyEnabled == true)
  end
  if PartyAutoUI and PartyAutoUI.setPartyEnabled then
    PartyAutoUI.setPartyEnabled(storage.partyEnabled == true)
  end
  if type(setHealingEnabled) == "function" then
    setHealingEnabled(storage.healingSystemEnabled == true)
  end
  if avisoMacroEnabled and type(createAvisoMacro) == "function" then
    createAvisoMacro()
  end
  if avisoMacro and avisoMacro.setOn then
    avisoMacro:setOn(avisoMacroEnabled)
  end
  if debugMacroEnabled and type(createDebugMacro) == "function" then
    createDebugMacro()
  end
  if debugMacro and debugMacro.setOn then
    debugMacro:setOn(debugMacroEnabled)
  end
  if pedirPTEnabled and type(createPedirPTMacro) == "function" then
    createPedirPTMacro()
  end
  if pedirPTMacro and pedirPTMacro.setOn then
    pedirPTMacro:setOn(pedirPTEnabled)
  end
end

buildHealingProfilePanel = function(panel, opts)
  opts = opts or {}
  panel = panel:getChildById('panelContent') or panel
  local profiles = ensureHpProfiles()

  local profileLabel = g_ui.createWidget('BotLabel', panel)
  profileLabel:setText('Perfis de Cura')
  profileLabel:setColor('#E8E8E8')
  profileLabel:setHeight(16)
  if profileLabel.setTextAlign then
    profileLabel:setTextAlign(AlignLeft)
  end
  if profileLabel.setMarginLeft then
    profileLabel:setMarginLeft(2)
  end
  setStandardTooltip(
    profileLabel,
    "Gerencie perfis completos do HP/Tools (Cura, Tools, Party Auto e Curar Amigos).",
    "Manage full HP/Tools profiles (Healing, Tools, Party Auto, and Heal Friends)."
  )
  g_ui.createWidget('BotSeparator', panel)

  local headerPanel = setupUI([[
Panel
  height: 20
  layout:
    type: horizontalBox
    spacing: 3
  fit-children: true

  SmallBotSwitch
    id: enableSwitch
    width: 34
    height: 18
    text-align: center
    text: ON

  ComboBox
    id: profilesCombo
    width: 160
    height: 18
    margin: 0
    font: verdana-11px-rounded

  TextEdit
    id: nameInput
    height: 18
    width: 100
    placeholder: Nome
    font: verdana-11px-rounded

  Button
    id: newBtn
    width: 42
    height: 18
    text: New

  Button
    id: deleteBtn
    width: 46
    height: 18
    text: Delete

  Button
    id: saveBtn
    width: 42
    height: 18
    text: Save
]], panel)

  if opts.showSwitch == false then
    headerPanel.enableSwitch:setVisible(false)
    headerPanel.enableSwitch:setWidth(0)
  else
    headerPanel.enableSwitch:setOn(opts.enabled == true)
    if opts.onToggle == setHealingEnabled then
      healingMasterSwitchRef = headerPanel.enableSwitch
      syncHealingMasterSwitchState()
    end
    if opts.switchTooltip then
      setTooltipFromUnknown(headerPanel.enableSwitch, opts.switchTooltip)
    end
    headerPanel.enableSwitch.onClick = function(widget)
      local enabled = not widget:isOn()
      if opts.onToggle then
        opts.onToggle(enabled)
      end
      widget:setOn(enabled)
    end
  end

  setStandardTooltip(headerPanel.nameInput, "Digite um nome para o novo perfil.", "Type a name for the new profile.")
  setStandardTooltip(headerPanel.newBtn, "Cria um novo perfil com esse nome.", "Create a new profile with this name.")
  setStandardTooltip(headerPanel.deleteBtn, "Remove o perfil atual selecionado.", "Remove the currently selected profile.")
  setStandardTooltip(headerPanel.saveBtn, "Salva todas as abas no perfil atual (substitui o salvo).", "Save all tabs into the current profile (overwrite saved data).")

  local function scheduleRebuild()
    if rebuildHealingTabs then
      if addEvent then
        addEvent(rebuildHealingTabs)
      else
        rebuildHealingTabs()
      end
    end
  end

  local function renderProfileList()
    profiles = ensureHpProfiles()
    local combo = headerPanel.profilesCombo
    combo:clearOptions()
    local activeId = getSelectedHpProfileId()
    for index, profileId in ipairs(profiles.order) do
      local entry = profiles.configs[profileId]
      combo:addOption((entry and entry.name) or profileId, profileId)
      if profileId == activeId then
        combo:setCurrentIndex(index, true)
      end
    end
    combo.onOptionChange = function(widget)
      local option = widget:getCurrentOption()
      if not option then return end
      local previousId = getSelectedHpProfileId()
      if previousId ~= option.data then
        saveHpProfileState(previousId)
      end
      setHpActiveProfile(profiles, option.data)
      applyHpProfileState(option.data)
      scheduleRebuild()
    end
  end

  headerPanel.newBtn.onClick = function()
    local currentId = getSelectedHpProfileId()
    saveHpProfileState(currentId)
    local id = addHpProfile(headerPanel.nameInput:getText())
    if id then
      headerPanel.nameInput:setText("")
      applyHpProfileState(id)
      renderProfileList()
      scheduleRebuild()
      modules.game_textmessage.displayBroadcastMessage('Perfil criado: ' .. getHpProfileName(id), '#00FF00')
    else
      warn('[HP/Tools] Nome de perfil invalido.')
    end
  end

  headerPanel.deleteBtn.onClick = function()
    local currentId = getSelectedHpProfileId()
    if not currentId or currentId == "" then return end
    local updated = ensureHpProfiles()
    for i = #updated.order, 1, -1 do
      if updated.order[i] == currentId then
        table.remove(updated.order, i)
        break
      end
    end
    updated.configs[currentId] = nil
    if #updated.order == 0 then
      local defaultId = "cfg_1"
      updated.configs[defaultId] = updated.configs[defaultId] or {
        name = "Config 1",
        data = captureHpProfileState()
      }
      table.insert(updated.order, defaultId)
      if updated.nextId < 2 then
        updated.nextId = 2
      end
    end
    local nextId = setHpActiveProfile(updated, updated.meta.activeProfile)
    applyHpProfileState(nextId)
    renderProfileList()
    scheduleRebuild()
    modules.game_textmessage.displayBroadcastMessage('Perfil removido.', '#FF0000')
  end

  headerPanel.saveBtn.onClick = function()
    local currentId = getSelectedHpProfileId()
    if not currentId or currentId == "" then return end
    saveHpProfileState(currentId)
    modules.game_textmessage.displayBroadcastMessage('Perfil salvo: ' .. getHpProfileName(currentId), '#00FF00')
  end

  renderProfileList()
  local currentId = getSelectedHpProfileId()
  if currentId ~= "" then
    local stored = ensureHpProfiles()
    local currentCfg = stored.configs[currentId]
    if not currentCfg or type(currentCfg.data) ~= "table" then
      saveHpProfileState(currentId)
    end
  end
end

local function addHpProfile(name)
  local cleaned = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if cleaned == "" then
    return nil
  end
  local profiles = ensureHpProfiles()
  local id = "cfg_" .. tostring(profiles.nextId)
  profiles.nextId = profiles.nextId + 1
  profiles.configs[id] = { name = cleaned, data = captureHpProfileState() }
  table.insert(profiles.order, id)
  setHpActiveProfile(profiles, id)
  return id
end

scriptMacros = scriptMacros or {}

local function buildToolsTab(panel)
  -- Usa o ScrollablePanel interno do HealingPanel
  panel = panel:getChildById('panelContent') or panel

  local label = g_ui.createWidget('BotLabel', panel)
  label:setText('Tools by Kelus Scripts')
  setStandardTooltip(
    label,
    "Macros automaticos e ferramentas gerais (ex: Next BP).",
    "Automatic macros and general tools (e.g., Next BP)."
  )
  label:setColor('#FFFFFF')

  local separator = g_ui.createWidget('BotSeparator', panel)

  local macrosLabel = g_ui.createWidget('BotLabel', panel)
  macrosLabel:setText('Macros Automaticos')
  macrosLabel:setColor('#FFFFFF')
  setStandardTooltip(
    macrosLabel,
    "Configure macros automaticos: Auto Buff, Auto Haste, Ant-Lyze e Stamina.",
    "Configure automatic macros: Auto Buff, Auto Haste, Ant-Lyze, and Stamina."
  )

  local macrosSeparator = g_ui.createWidget('BotSeparator', panel)

  local macrosHeader = setupUI([[
Panel
  height: 16
  layout:
    type: horizontalBox
    spacing: 3

  Label
    id: colOn
    text: ON
    width: 26
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colName
    text: Macro
    width: 88
    font: verdana-11px-rounded

  Label
    id: colSpell
    text: Spell
    width: 72
    font: verdana-11px-rounded

  Label
    id: colMana
    text: MP
    width: 42
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colDelay
    text: Delay
    width: 42
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colTarget
    text: T
    width: 16
    text-align: center
    font: verdana-11px-rounded

  Label
    id: colPz
    text: PZ
    width: 16
    text-align: center
    font: verdana-11px-rounded
]], panel)
  setStandardTooltip(
    macrosHeader,
    "Macros automaticos: ajuste ON, spell, MP, delay e filtros de execucao.",
    "Automatic macros: adjust ON, spell, MP, delay, and execution filters."
  )
  setStandardTooltip(macrosHeader.colOn, "Liga/desliga cada macro.", "Enable/disable each macro.")
  setStandardTooltip(macrosHeader.colName, "Nome do macro.", "Macro name.")
  setStandardTooltip(macrosHeader.colSpell, "Spell usada pelo macro.", "Spell used by the macro.")
  setStandardTooltip(macrosHeader.colMana, "MP minimo (%) para executar.", "Minimum MP (%) to execute.")
  setStandardTooltip(macrosHeader.colDelay, "Delay entre execucoes.", "Delay between executions.")
  setStandardTooltip(macrosHeader.colTarget, "Filtro de target.", "Target filter.")
  setStandardTooltip(macrosHeader.colPz, "Permitir execucao em PZ.", "Allow execution in PZ.")

  local function createMacroRow(title, tooltipPt, tooltipEn, storageKey, options)
    options = options or {}
    local row = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 3

  SmallBotSwitch
    id: enabled
    width: 26
    height: 20
    text-align: center
    text: ON

  Label
    id: nameLabel
    width: 88
    font: verdana-11px-rounded

  TextEdit
    id: spellText
    width: 72
    height: 20

  SpinBox
    id: manaMin
    width: 42
    height: 20
    text-align: center
    minimum: 0
    maximum: 100
    step: 1
    editable: true
    focusable: true

  Label
    id: delaySpacer
    width: 42
    height: 20
    text: ""

  CategoryCheckBox
    id: checkTarget
    width: 16
    height: 18
    focusable: true
    phantom: false

  CategoryCheckBox
    id: checkPZ
    width: 16
    height: 18
    focusable: true
    phantom: false
]], panel)

    if storage[storageKey] == nil then
      storage[storageKey] = false
    end

    row.enabled:setOn(storage[storageKey])
    setStandardTooltip(row.enabled, "Ativa ou desativa este macro.", "Enable or disable this macro.")
    row.enabled.onClick = function(widget)
      storage[storageKey] = not storage[storageKey]
      widget:setOn(storage[storageKey])
    end

    row.nameLabel:setText(title)
    setStandardTooltip(row.nameLabel, tooltipPt, tooltipEn)

    setStandardTooltip(row.spellText, "Nome da magia (spell).", "Spell name.")
    setStandardTooltip(row.manaMin, "MP minimo (%) para executar.", "Minimum mana (%) to execute.")
    setStandardTooltip(row.checkTarget, "Executar apenas com target selecionado.", "Execute only with a target selected.")
    setStandardTooltip(row.checkPZ, "Permitir executar dentro de PZ.", "Allow execution inside PZ.")

    if not options.showMana then
      row.manaMin:setVisible(false)
      row.manaMin:setWidth(0)
    end

    return row
  end

  if not storage.autoBuffText then
    storage.autoBuffText = "utito tempo"
  end

  if type(storage.autoBuffFilters) ~= "table" then
    storage.autoBuffFilters = {
      executeInPZ = false,
      executeWithTarget = true
    }
  end

  if storage.autoBuffManaMin == nil then
    storage.autoBuffManaMin = 15
  end

  local autoBuffRow = createMacroRow(
    'Auto Buff',
    "Usa buff automaticamente quando nao ha party buff ativo. Ex: utito tempo, exori gran ico.",
    "Automatically uses a buff when the party buff is not active. Example: utito tempo, exori gran ico.",
    'autoBuffEnabled',
    {showMana = true, showDelay = false}
  )
  autoBuffRow.spellText:setText(storage.autoBuffText)
  autoBuffRow.spellText.onTextChange = function(widget, newText)
    storage.autoBuffText = newText
  end
  autoBuffRow.manaMin:setValue(storage.autoBuffManaMin)
  autoBuffRow.manaMin.onValueChange = function(widget, value)
    storage.autoBuffManaMin = value
  end
  autoBuffRow.checkTarget:setChecked(storage.autoBuffFilters.executeWithTarget)
  autoBuffRow.checkTarget.onClick = function(widget)
    storage.autoBuffFilters.executeWithTarget = not storage.autoBuffFilters.executeWithTarget
    widget:setChecked(storage.autoBuffFilters.executeWithTarget)
  end
  autoBuffRow.checkPZ:setChecked(storage.autoBuffFilters.executeInPZ)
  autoBuffRow.checkPZ.onClick = function(widget)
    storage.autoBuffFilters.executeInPZ = not storage.autoBuffFilters.executeInPZ
    widget:setChecked(storage.autoBuffFilters.executeInPZ)
  end

  local autoBuffMacro = macro(500, function()
    if not storage.healingSystemEnabled or not storage.toolsEnabled or not storage.autoBuffEnabled then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end
    if not player then return end

    local hasPartyBuffFunc = hasPartyBuff or function() return bit.band(player:getStates(), 4096) > 0 end
    local isInPzFunc = isInPz or function() return bit.band(player:getStates(), 16384) > 0 end

    if isInPzFunc() and not storage.autoBuffFilters.executeInPZ then
      return
    end

    local currentTarget = target()
    if not currentTarget and storage.autoBuffFilters.executeWithTarget then
      return
    end

    if not hasPartyBuffFunc() and manapercent() >= (storage.autoBuffManaMin or 15) then
      say(storage.autoBuffText)
      delay(1000)
    end
  end)

  if not storage.EditSpellsHasteSpell then
    storage.EditSpellsHasteSpell = "utani hur"
  end

  if type(storage.autoHasteFilters) ~= "table" then
    storage.autoHasteFilters = {
      executeInPZ = false,
      executeWithMonster = true
    }
  end

  if storage.autoHasteManaMin == nil then
    storage.autoHasteManaMin = 0
  end

  local hasteRow = createMacroRow(
    'Auto Haste',
    "Usa haste automaticamente quando nao ha haste ativo ou quando estiver paralisado.",
    "Automatically uses haste when it is not active or you are paralyzed.",
    'autoHasteEnabled',
    {showMana = true, showDelay = false}
  )
  hasteRow.spellText:setText(storage.EditSpellsHasteSpell)
  hasteRow.spellText.onTextChange = function(widget, newText)
    storage.EditSpellsHasteSpell = newText
  end
  hasteRow.manaMin:setValue(storage.autoHasteManaMin)
  hasteRow.manaMin.onValueChange = function(widget, value)
    storage.autoHasteManaMin = value
  end
  hasteRow.checkTarget:setChecked(storage.autoHasteFilters.executeWithMonster)
  hasteRow.checkTarget.onClick = function(widget)
    storage.autoHasteFilters.executeWithMonster = not storage.autoHasteFilters.executeWithMonster
    widget:setChecked(storage.autoHasteFilters.executeWithMonster)
  end
  hasteRow.checkPZ:setChecked(storage.autoHasteFilters.executeInPZ)
  hasteRow.checkPZ.onClick = function(widget)
    storage.autoHasteFilters.executeInPZ = not storage.autoHasteFilters.executeInPZ
    widget:setChecked(storage.autoHasteFilters.executeInPZ)
  end

  local hasteMacro = macro(500, function()
    if not storage.healingSystemEnabled or not storage.toolsEnabled or not storage.autoHasteEnabled then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end
    if not player then return end

    local hasHasteFunc = hasHaste or function() return bit.band(player:getStates(), 64) > 0 end
    local isParalyzedFunc = isParalyzed or function() return bit.band(player:getStates(), 32) > 0 end
    local isInPzFunc = isInPz or function() return bit.band(player:getStates(), 16384) > 0 end

    if isInPzFunc() and not storage.autoHasteFilters.executeInPZ then
      return
    end

    local currentTarget = target()
    local canUseHaste = false

    if not currentTarget then
      canUseHaste = true
    elseif currentTarget:isPlayer() then
      canUseHaste = true
    else
      if storage.autoHasteFilters.executeWithMonster then
        canUseHaste = true
      else
        canUseHaste = not isParalyzedFunc()
      end
    end

    if canUseHaste and (not hasHasteFunc() or isParalyzedFunc()) and manapercent() >= (storage.autoHasteManaMin or 0) then
      say(storage.EditSpellsHasteSpell)
    end
  end)

  if not storage.EditSpellsAntiParalyze then
    storage.EditSpellsAntiParalyze = "utani hur"
  end

  if type(storage.antiParalyzeFilters) ~= "table" then
    storage.antiParalyzeFilters = {
      executeInPZ = false,
      executeWithMonster = true
    }
  end

  if storage.antiParalyzeManaMin == nil then
    storage.antiParalyzeManaMin = 0
  end

  local antiParalyzeRow = createMacroRow(
    'Ant-Lyze',
    "Remove paralisia automaticamente quando voce fica paralisado.",
    "Automatically removes paralysis when you get paralyzed.",
    'antiParalyzeEnabled',
    {showMana = true, showDelay = false}
  )
  antiParalyzeRow.spellText:setText(storage.EditSpellsAntiParalyze)
  antiParalyzeRow.spellText.onTextChange = function(widget, newText)
    storage.EditSpellsAntiParalyze = newText
  end
  antiParalyzeRow.manaMin:setValue(storage.antiParalyzeManaMin)
  antiParalyzeRow.manaMin.onValueChange = function(widget, value)
    storage.antiParalyzeManaMin = value
  end
  antiParalyzeRow.checkTarget:setChecked(storage.antiParalyzeFilters.executeWithMonster)
  antiParalyzeRow.checkTarget.onClick = function(widget)
    storage.antiParalyzeFilters.executeWithMonster = not storage.antiParalyzeFilters.executeWithMonster
    widget:setChecked(storage.antiParalyzeFilters.executeWithMonster)
  end
  antiParalyzeRow.checkPZ:setChecked(storage.antiParalyzeFilters.executeInPZ)
  antiParalyzeRow.checkPZ.onClick = function(widget)
    storage.antiParalyzeFilters.executeInPZ = not storage.antiParalyzeFilters.executeInPZ
    widget:setChecked(storage.antiParalyzeFilters.executeInPZ)
  end

  local antiParalyzeMacro = macro(200, function()
    if not storage.healingSystemEnabled or not storage.toolsEnabled or not storage.antiParalyzeEnabled then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end
    if not player then return end

    local isParalyzedFunc = isParalyzed or function() return bit.band(player:getStates(), 32) > 0 end
    local isInPzFunc = isInPz or function() return bit.band(player:getStates(), 16384) > 0 end

    if isInPzFunc() and not storage.antiParalyzeFilters.executeInPZ then
      return
    end

    local currentTarget = target()
    if currentTarget and currentTarget:isMonster() and not storage.antiParalyzeFilters.executeWithMonster then
      return
    end

    if isParalyzedFunc() and manapercent() >= (storage.antiParalyzeManaMin or 0) then
      say(storage.EditSpellsAntiParalyze)
    end
  end)

  if storage.recoveryEnabled == nil then
    storage.recoveryEnabled = false
  end

  if not storage.recoverySpell then
    storage.recoverySpell = "utura gran"
  end

  if storage.recoveryDelay == nil then
    storage.recoveryDelay = 1000
  end

  if storage.recoveryManaMin == nil then
    storage.recoveryManaMin = 0
  end

  if type(storage.recoveryFilters) ~= "table" then
    storage.recoveryFilters = {
      executeInPZ = false,
      executeWithTarget = true
    }
  end

  local recoveryRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 3

  SmallBotSwitch
    id: enabled
    width: 26
    height: 20
    text-align: center
    text: ON

  Label
    id: nameLabel
    width: 88
    font: verdana-11px-rounded

  TextEdit
    id: spellText
    width: 72
    height: 20

  SpinBox
    id: manaMin
    width: 42
    height: 20
    text-align: center
    minimum: 0
    maximum: 100
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: delay
    width: 42
    height: 20
    text-align: center
    minimum: 0.1
    maximum: 999999
    step: 0.1
    editable: true
    focusable: true

  CategoryCheckBox
    id: checkTarget
    width: 16

  CategoryCheckBox
    id: checkPZ
    width: 16
]], panel)

  recoveryRow.enabled:setOn(storage.recoveryEnabled)
  setStandardTooltip(recoveryRow.enabled, "Ativa ou desativa o macro Recovery.", "Enable or disable the Recovery macro.")
  recoveryRow.enabled.onClick = function(widget)
    storage.recoveryEnabled = not storage.recoveryEnabled
    widget:setOn(storage.recoveryEnabled)
  end

  recoveryRow.nameLabel:setText('Recovery')
  setStandardTooltip(
    recoveryRow.nameLabel,
    "Usa uma magia de recovery em intervalos regulares (delay).",
    "Casts a recovery spell at regular intervals (delay)."
  )

  recoveryRow.spellText:setText(storage.recoverySpell)
  setStandardTooltip(recoveryRow.spellText, "Nome da magia de recovery (ex: utura gran).", "Recovery spell name (e.g., utura gran).")
  recoveryRow.spellText.onTextChange = function(widget, newText)
    storage.recoverySpell = newText
  end

  recoveryRow.manaMin:setValue(storage.recoveryManaMin)
  setStandardTooltip(recoveryRow.manaMin, "MP minimo (%) para executar.", "Minimum mana (%) to execute.")
  recoveryRow.manaMin.onValueChange = function(widget, value)
    storage.recoveryManaMin = value
  end

  recoveryRow.delay:setValue(delayMsToSeconds(storage.recoveryDelay))
  setStandardTooltip(recoveryRow.delay, "Delay entre casts (segundos).", "Delay between casts (seconds).")
  recoveryRow.delay.onValueChange = function(widget, value)
    storage.recoveryDelay = secondsToMs(value)
  end

  recoveryRow.checkTarget:setChecked(storage.recoveryFilters.executeWithTarget)
  setStandardTooltip(recoveryRow.checkTarget, "Executar apenas com target selecionado.", "Execute only with a target selected.")
  recoveryRow.checkTarget.onClick = function(widget)
    storage.recoveryFilters.executeWithTarget = not storage.recoveryFilters.executeWithTarget
    widget:setChecked(storage.recoveryFilters.executeWithTarget)
  end

  recoveryRow.checkPZ:setChecked(storage.recoveryFilters.executeInPZ)
  setStandardTooltip(recoveryRow.checkPZ, "Permitir executar dentro de PZ.", "Allow execution inside PZ.")
  recoveryRow.checkPZ.onClick = function(widget)
    storage.recoveryFilters.executeInPZ = not storage.recoveryFilters.executeInPZ
    widget:setChecked(storage.recoveryFilters.executeInPZ)
  end

  local lastRecoveryCast = 0
  local recoveryMacro = macro(200, function()
    if not storage.healingSystemEnabled or not storage.toolsEnabled or not storage.recoveryEnabled then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end
    if not player then return end
    if not storage.recoverySpell or storage.recoverySpell == "" then return end
    if manapercent() < (storage.recoveryManaMin or 0) then return end

    local isInPzFunc = isInPz or function() return bit.band(player:getStates(), 16384) > 0 end
    if isInPzFunc() and not storage.recoveryFilters.executeInPZ then
      return
    end

    local currentTarget = target()
    if not currentTarget and storage.recoveryFilters.executeWithTarget then
      return
    end

    local nowTime = healingTimeNow()
    if nowTime - lastRecoveryCast < (storage.recoveryDelay or 1000) then return end
    say(storage.recoverySpell)
    lastRecoveryCast = nowTime
  end)

  if storage.familiarEnabled == nil then
    storage.familiarEnabled = false
  end

  if not storage.familiarSpell then
    storage.familiarSpell = "familiar"
  end

  if storage.familiarDelay == nil then
    storage.familiarDelay = 60000
  elseif tonumber(storage.familiarDelay) and tonumber(storage.familiarDelay) < 60000 then
    -- Legacy values were edited in seconds; keep the same numeric value in new minutes-based UI.
    storage.familiarDelay = math.floor((tonumber(storage.familiarDelay) or 0) * 60)
  end

  if storage.familiarManaMin == nil then
    storage.familiarManaMin = 0
  end

  if type(storage.familiarFilters) ~= "table" then
    storage.familiarFilters = {
      executeInPZ = false,
      executeWithTarget = true
    }
  end

  local familiarRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 3

  SmallBotSwitch
    id: enabled
    width: 26
    height: 20
    text-align: center
    text: ON

  Label
    id: nameLabel
    width: 88
    font: verdana-11px-rounded

  TextEdit
    id: spellText
    width: 72
    height: 20

  SpinBox
    id: manaMin
    width: 42
    height: 20
    text-align: center
    minimum: 0
    maximum: 100
    step: 1
    editable: true
    focusable: true

  SpinBox
    id: delay
    width: 42
    height: 20
    text-align: center
    minimum: 0.1
    maximum: 999999
    step: 0.1
    editable: true
    focusable: true

  CategoryCheckBox
    id: checkTarget
    width: 16

  CategoryCheckBox
    id: checkPZ
    width: 16
]], panel)

  familiarRow.enabled:setOn(storage.familiarEnabled)
  setStandardTooltip(familiarRow.enabled, "Ativa ou desativa o macro Familiar.", "Enable or disable the Familiar macro.")
  familiarRow.enabled.onClick = function(widget)
    storage.familiarEnabled = not storage.familiarEnabled
    widget:setOn(storage.familiarEnabled)
  end

  familiarRow.nameLabel:setText('Familiar')
  setStandardTooltip(
    familiarRow.nameLabel,
    "Usa uma magia para invocar o familiar.",
    "Uses a spell to summon the familiar."
  )

  familiarRow.spellText:setText(storage.familiarSpell)
  setStandardTooltip(familiarRow.spellText, "Nome da magia do familiar (ex: familiar).", "Familiar spell name (e.g., familiar).")
  familiarRow.spellText.onTextChange = function(widget, newText)
    storage.familiarSpell = newText
  end

  familiarRow.manaMin:setValue(storage.familiarManaMin)
  setStandardTooltip(familiarRow.manaMin, "MP minimo (%) para executar.", "Minimum mana (%) to execute.")
  familiarRow.manaMin.onValueChange = function(widget, value)
    storage.familiarManaMin = value
  end

  familiarRow.delay:setValue(delayMsToMinutes(storage.familiarDelay))
  setStandardTooltip(familiarRow.delay, "Delay entre casts (minutos).", "Delay between casts (minutes).")
  familiarRow.delay.onValueChange = function(widget, value)
    storage.familiarDelay = minutesToMs(value)
  end

  familiarRow.checkTarget:setChecked(storage.familiarFilters.executeWithTarget)
  setStandardTooltip(familiarRow.checkTarget, "Executar apenas com target selecionado.", "Execute only with a target selected.")
  familiarRow.checkTarget.onClick = function(widget)
    storage.familiarFilters.executeWithTarget = not storage.familiarFilters.executeWithTarget
    widget:setChecked(storage.familiarFilters.executeWithTarget)
  end

  familiarRow.checkPZ:setChecked(storage.familiarFilters.executeInPZ)
  setStandardTooltip(familiarRow.checkPZ, "Permitir executar dentro de PZ.", "Allow execution inside PZ.")
  familiarRow.checkPZ.onClick = function(widget)
    storage.familiarFilters.executeInPZ = not storage.familiarFilters.executeInPZ
    widget:setChecked(storage.familiarFilters.executeInPZ)
  end

  local lastFamiliarCast = 0
  local familiarMacro = macro(200, function()
    if not storage.healingSystemEnabled or not storage.toolsEnabled or not storage.familiarEnabled then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end
    if not player then return end
    if not storage.familiarSpell or storage.familiarSpell == "" then return end
    if manapercent() < (storage.familiarManaMin or 0) then return end

    local isInPzFunc = isInPz or function() return bit.band(player:getStates(), 16384) > 0 end
    if isInPzFunc() and not storage.familiarFilters.executeInPZ then
      return
    end

    local currentTarget = target()
    if not currentTarget and storage.familiarFilters.executeWithTarget then
      return
    end

    local nowTime = healingTimeNow()
    if nowTime - lastFamiliarCast < (storage.familiarDelay or 60000) then return end
    say(storage.familiarSpell)
    lastFamiliarCast = nowTime
  end)

  if storage.castEnabled == nil then
    storage.castEnabled = false
  end

  if not storage.castText then
    storage.castText = "!cast on"
  end

  if storage.castDelay == nil then
    storage.castDelay = 3600000
  end

  local castRow = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 3

  SmallBotSwitch
    id: enabled
    width: 26
    height: 20
    text-align: center
    text: ON

  Label
    id: nameLabel
    width: 88
    font: verdana-11px-rounded

  TextEdit
    id: castText
    width: 72
    height: 20

  Label
    id: manaSpacer
    width: 42
    height: 20
    text: ""

  SpinBox
    id: delay
    width: 42
    height: 20
    text-align: center
    minimum: 0.1
    maximum: 30
    step: 0.1
    editable: true
    focusable: true
]], panel)

  castRow.enabled:setOn(storage.castEnabled)
  setStandardTooltip(castRow.enabled, "Ativa ou desativa o macro Cast.", "Enable or disable the Cast macro.")
  castRow.enabled.onClick = function(widget)
    storage.castEnabled = not storage.castEnabled
    widget:setOn(storage.castEnabled)
  end

  castRow.nameLabel:setText('Cast')
  setStandardTooltip(
    castRow.nameLabel,
    "Diz o comando configurado em intervalo fixo.",
    "Says the configured command on a fixed interval."
  )

  castRow.castText:setText(storage.castText)
  setStandardTooltip(castRow.castText, "Comando do cast (ex: !cast on).", "Cast command (e.g., !cast on).")
  castRow.castText.onTextChange = function(widget, newText)
    storage.castText = newText
  end

  castRow.delay:setValue(delayMsToHours(storage.castDelay))
  setStandardTooltip(castRow.delay, "Delay entre comandos (horas).", "Delay between commands (hours).")
  castRow.delay.onValueChange = function(widget, value)
    storage.castDelay = hoursToMs(value)
  end

  local lastCastMacroUse = 0
  local castMacro = macro(200, function()
    if not storage.healingSystemEnabled or not storage.toolsEnabled or not storage.castEnabled then return end
    if not storage.castText or storage.castText == "" then return end

    local nowTime = healingTimeNow()
    if nowTime - lastCastMacroUse < (storage.castDelay or 1000) then return end
    say(storage.castText)
    lastCastMacroUse = nowTime
  end)

  local function createUtilitySection(opts)
    opts = opts or {}
    local header = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4
  fit-children: true

  SmallBotSwitch
    id: enabled
    width: 34
    height: 20
    text-align: center
    text: ON

  Label
    id: title
    font: verdana-11px-rounded
    width: 120
    text-align: left

  Button
    id: setupBtn
    text: +
    width: 20
    height: 20
]], panel)

    header.title:setText(opts.title or 'UTILIDADE')
    header.title:setColor('#FFFFFF')
    if opts.labelTooltipPt and opts.labelTooltipEn then
      setStandardTooltip(header.title, opts.labelTooltipPt, opts.labelTooltipEn)
    end

    if opts.storageKey then
      if storage[opts.storageKey] == nil then
        storage[opts.storageKey] = true
      end
      header.enabled:setOn(storage[opts.storageKey])
      setStandardTooltip(header.enabled, "Ativa ou desativa este macro.", "Enable or disable this macro.")
      header.enabled.onClick = function(widget)
        storage[opts.storageKey] = not storage[opts.storageKey]
        widget:setOn(storage[opts.storageKey])
      end
    else
      header.enabled:setVisible(false)
      header.enabled:setWidth(0)
    end

    local configPanel = setupUI([[
Panel
  layout:
    type: verticalBox
    spacing: 6
  fit-children: true
]], panel)
    configPanel:setVisible(false)
    configPanel:setMarginTop(4)
    configPanel:setMarginBottom(8)

    if opts.infoText then
      local infoLabel = g_ui.createWidget('BotLabel', configPanel)
      infoLabel:setText(opts.infoText)
      infoLabel:setColor('#FFFFFF')
      if opts.infoTooltipPt and opts.infoTooltipEn then
        setStandardTooltip(infoLabel, opts.infoTooltipPt, opts.infoTooltipEn)
      end
    end

    if opts.buildConfig then
      opts.buildConfig(configPanel)
    end
    ensurePanelHeight(configPanel)

    if opts.setupTooltipPt and opts.setupTooltipEn then
      setStandardTooltip(header.setupBtn, opts.setupTooltipPt, opts.setupTooltipEn)
    end
    local function toggleUtility()
      local visible = not configPanel:isVisible()
      configPanel:setVisible(visible)
      header.setupBtn:setText(visible and '-' or '+')
      if visible then
        ensurePanelHeight(configPanel)
      end
      if panel then
        ensurePanelHeight(panel)
      end
      refreshLayout(configPanel)
    end

    header.setupBtn.onMousePress = function(widget, mousePos, mouseButton)
      if MouseLeftButton and mouseButton and mouseButton ~= MouseLeftButton then
        return false
      end
      toggleUtility()
      return true
    end
    header.setupBtn.onClick = nil

    return {
      header = header,
      setupBtn = header.setupBtn,
      configPanel = configPanel
    }
  end

  if type(storage.nextBpIds) ~= "table" then
    storage.nextBpIds = {{id=2854}}
  end

  if type(storage.nextBpIds) == "table" then
    for i, v in ipairs(storage.nextBpIds) do
      if type(v) == "number" then
        storage.nextBpIds[i] = {id = v}
      end
    end
  end

  local nextBpSection = createUtilitySection({
    title = 'Next BP',
    infoText = 'Abre a proxima backpack quando a atual fica cheia.',
    labelTooltipPt = 'Ativa e configura o Next BP.',
    labelTooltipEn = 'Enable and configure Next BP.',
    storageKey = 'nextBpEnabled',
    setupTooltipPt = 'Abre a configuracao do Next BP.',
    setupTooltipEn = 'Opens the Next BP configuration.',
    buildConfig = function(configPanel)
      local nextBpLabel = g_ui.createWidget('BotLabel', configPanel)
      nextBpLabel:setText('Next BP IDs')
      nextBpLabel:setColor('#FFFFFF')
      setStandardTooltip(
        nextBpLabel,
        "Abre automaticamente a proxima backpack quando a atual enche. Cadastre os IDs das BPs.",
        "Automatically opens the next backpack when the current one is full. Register BP IDs."
      )

      local nextBpContainer = UI.Container(function(widget, items)
        storage.nextBpIds = items
      end, true, configPanel)
      nextBpContainer:setHeight(44)
      nextBpContainer:setItems(storage.nextBpIds)
      setStandardTooltip(
        nextBpContainer,
        "Clique para adicionar/remover IDs de backpacks (BPs).",
        "Click to add/remove backpack IDs (BPs)."
      )
    end
  })

  local function getNextBpIdList()
    local ids = {}
    for _, entry in pairs(storage.nextBpIds or {}) do
      table.insert(ids, entry.id or entry)
    end
    return ids
  end

  macro(1000, function()
    if not storage.healingSystemEnabled or not storage.toolsEnabled then return end
    if not storage.nextBpEnabled then return end
    local containerIds = getNextBpIdList()
    if #containerIds == 0 then return end
    for _, container in pairs(getContainers() or {}) do
      local containerItem = container:getContainerItem()
      if containerItem and table.contains(containerIds, containerItem:getId()) then
        if container:getCapacity() == #container:getItems() then
          for _, item in ipairs(container:getItems()) do
            if table.contains(containerIds, item:getId()) then
              g_game.open(item, container)
              delay(200)
              break
            end
          end
        end
      end
    end
  end)

  local toolsMacros = ensureToolsMacrosSettings()

  -- Exeta Loot Macro
  local exetaLootDelay = 1000
  local nextExeta = 0

  onCreatureDisappear(function(creature)
    if not storage.healingSystemEnabled or not storage.toolsEnabled then return end
    if not toolsMacros.exetaLoot then return end
    if nextExeta > now then return end
    if isInPz() then return end
    if not creature:isMonster() then return end
    local pos = player:getPosition()
    local mpos = creature:getPosition()
    if pos.z ~= mpos.z or getDistanceBetween(pos, mpos) > 1 then return end
    schedule(100, function()
      local tile = g_map.getTile(mpos)
      if not tile then return end
      local container = tile:getTopUseThing()
      if not container or not container:isContainer() then return end
      nextExeta = now + exetaLootDelay
      say("exeta loot")
    end)
  end)

  onAddThing(function(tile, thing)
      if not storage.healingSystemEnabled or not storage.toolsEnabled then return end
      if not toolsMacros.hideEffects then return end
      if thing:isEffect() then
          thing:hide()
      end
  end)

  onStaticText(function(thing, text)
      if not storage.healingSystemEnabled or not storage.toolsEnabled then return end
      if not toolsMacros.hideMessages then return end
      g_map.cleanTexts()
  end)

  macro(10000, function()
    if not storage.healingSystemEnabled or not storage.toolsEnabled then return end
    if not toolsMacros.autoMount then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end
    if not player then return end
    if not player:isMounted() then player:mount() end
  end, panel)

end


-- ====================================
-- PARTY AUTO (integrado)
-- ====================================
local partyAutoEmbed = true
local friendHealerBuilt = false

local function friendHealerSetup(parent, opts)
opts = opts or {}
if friendHealerBuilt then
    return
end
friendHealerBuilt = true
local embedded = parent ~= nil
local showStandaloneControls = opts.hideStandaloneToggles ~= true
-- ============================================
-- STORAGE INITIALIZATION
-- ============================================
local panelName = "curarFriends"

if type(storage[panelName]) ~= "table" then
    storage[panelName] = {
        enabled = false,
        spell = 'exura sio "',
        hpPercent = 70,
        delay = 1000,
        distance = 6,

        healMode = "spell", -- "spell" ou "item"

        filters = {
            vipList = true,
            partyMembers = true,
            guildMembers = false,
            customList = false
        },

        customList = {},

        itemHeal = {
            itemId = 3160,
            useBelow = 50,
            distance = 3
        }
    }
end

-- Compatibilidade: adicionar healMode se nao existir
if storage[panelName].healMode == nil then
    storage[panelName].healMode = "spell"
end

local config = storage[panelName]

-- ============================================
-- UI DEFINITIONS
-- ============================================
g_ui.loadUIFromString([[
CategoryCheckBox < CheckBox
  font: verdana-11px-rounded
  margin-top: 0
  height: 18
  focusable: true
  phantom: false

FriendHealerWindow < MainWindow
  text: Setup - Curar Amigos by Kelus Scripts
  size: 364 360
  visible: false
  @onEscape: self:hide()

  TabBar
    id: tabBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 25

  Panel
    id: contentPanel
    anchors.top: tabBar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    margin-top: 3
    margin-left: 6
    margin-right: 6
    padding: 3

    VerticalScrollBar
      id: contentScroll
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      step: 20
      pixels-scroll: true

    ScrollablePanel
      id: scrollContent
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-right: 8
      padding: 3
      padding-left: 5
      vertical-scrollbar: contentScroll
      layout: verticalBox

  Button
    id: closeButton
    text: Fechar
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 80 18
    margin-right: 6
    margin-bottom: 6

TabPanel < Panel
  layout:
    type: verticalBox
    spacing: 3

CustomListEntry < Panel
  height: 20
  layout:
    type: horizontalBox

  Label
    id: nameLabel
    text-align: left
    phantom: false

  Button
    id: removeBtn
    text: X
    width: 25
    height: 18
]])

-- ============================================
-- MAIN UI BUTTON (Tab Main)
-- ============================================

local mainUI
local setupWindow
if not embedded and showStandaloneControls then
    mainUI = setupUI([[
Panel
  height: 20

  BotSwitch
    id: toggleBtn
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 100
    text: SioFriends

  Button
    id: setupBtn
    anchors.top: prev.top
    anchors.left: prev.right
    height: 17
    width: 60
    text: Setup
]])
end

-- ============================================
-- SETUP WINDOW
-- ============================================
if not embedded then
    setupWindow = g_ui.createWidget('FriendHealerWindow', g_ui.getRootWidget())
    setupWindow:setSize({width = 364, height = 360})
    setupWindow:hide()
end

-- ============================================
-- PARTY AUTO SYSTEM
-- ============================================

-- =============================
-- SISTEMA DE PARTY AUTOMATICO
-- Versao: 2.0 - Interface Moderna
-- Autor: Kelus Scripts
-- =============================

-- VARIAVEIS DE CONFIGURACAO COM VALORES PADRAO E ARMAZENAMENTO
maxPartyMembers = storage.maxPartyMembers or 21
local textDebug = '!party info'
inviteMessage = storage.inviteMessage or "Kelus Scripts"
warningMessage = storage.warningMessage or "Kelus Scripts"
inviteKeyword = storage.inviteKeyword or "Manda PT" -- Palavra-chave padrao

-- Inicializar blacklist como array
if not storage.partyBlacklist or type(storage.partyBlacklist) ~= "table" then
    storage.partyBlacklist = {}
end
blacklist = storage.partyBlacklist

-- Inicializar lista de lideres
if not storage.partyLeaders or type(storage.partyLeaders) ~= "table" then
    storage.partyLeaders = {}
end
leaders = storage.partyLeaders

-- Senha para pedir party
partyPassword = storage.partyPassword or ""
pedirPTEnabled = storage.pedirPTEnabled == true
if storage.acceptPartyOnlyLeaders == nil then
    storage.acceptPartyOnlyLeaders = false
end

-- Funcao para verificar se um nome esta na blacklist
local function isBlacklisted(name)
    if not name or #blacklist == 0 then return false end
    local nameLower = name:lower():trim()
    for _, blockedName in ipairs(blacklist) do
        if blockedName:lower():trim() == nameLower then
            return true
        end
    end
    return false
end

local function isNameInLeadersList(name)
    if not name or #leaders == 0 then return false end
    local nameLower = name:lower():trim()
    for _, leaderName in ipairs(leaders) do
        if leaderName:lower():trim() == nameLower then
            return true
        end
    end
    return false
end

-- =============================
-- VARIAVEIS PRINCIPAIS
-- =============================

partyEnabled = storage.partyEnabled == true
local infoTime, talkTime = 0, 0
maxLevel, minLevel = storage.maxLevel or 0, storage.minLevel or 0
local justForInfo, canSeeInfo = true, true
local partyMembersCount = 0

-- =============================
-- MACRO PRINCIPAL
-- =============================

-- Macro principal (criado dinamicamente)
local partyLeaderHuntWidget = nil
local function createPartyLeaderMacro()
    if partyLeaderHuntWidget then return end
    partyLeaderHuntWidget = macro(1000, function()
        if not partyEnabled then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end
    if not player then return end
    if not player:isPartyLeader() then
        justForInfo, partyMembersCount = true, 0
        return
    end

        -- Ativar shared automaticamente se nao estiver ativo
        if not player:isPartySharedExperienceActive() then
            g_game.partyShareExperience(true)
        end

    if justForInfo and canSeeInfo then
        sayChannel(getChannelId("party"), "!party info")
        return
    end
    if talkTime > 0 then
        talkTime = talkTime - 1
    end
    if player:getShield() == 10 then
        infoTime = infoTime + 1
        if infoTime >= 10 then
            sayChannel(getChannelId("party"), "!party info")
            infoTime = 0
        end
    else
        infoTime = 0
    end
end)
    partyLeaderHuntWidget:setOn(false)
end
-- Criar macro inicialmente
createPartyLeaderMacro()

-- =============================
-- INTERFACE PRINCIPAL (PAINEL)
-- =============================

local partyUI
if not partyAutoEmbed and showStandaloneControls then
    partyUI = setupUI([[
Panel
  height: 20

  BotSwitch
    id: switch
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 100
    text: Party Auto

  Button
    id: setup
    anchors.top: prev.top
    anchors.left: prev.right
    height: 17
    width: 60
    text: Setup
]])
end

setPartyEnabled = function(enabled)
    partyEnabled = enabled == true
    storage.partyEnabled = partyEnabled
    if partyUI then
        partyUI.switch:setOn(partyEnabled)
    end
    if partyLeaderHuntWidget then
        partyLeaderHuntWidget:setOn(partyEnabled)
    end
end

-- Carregar estado do storage
partyEnabled = storage.partyEnabled == true
if partyUI then
    partyUI.switch:setOn(partyEnabled)
end
if partyEnabled and partyLeaderHuntWidget then
    partyLeaderHuntWidget:setOn(true)
end

if partyUI then
    partyUI.switch.onClick = function(widget)
        setPartyEnabled(not partyEnabled)
        widget:setOn(partyEnabled)
    end
end


-- =============================
-- JANELA DE CONFIGURACAO
-- =============================

g_ui.loadUIFromString([[
PartyTabPanel < Panel
  margin: 2

  VerticalScrollBar
    id: panelScroll
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    step: 22
    pixels-scroll: true

  ScrollablePanel
    id: panelContent
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    margin-left: 4
    margin-right: 10
    padding: 4
    padding-left: 6
    padding-top: 5
    padding-bottom: 5
    vertical-scrollbar: panelScroll
    layout:
      type: verticalBox
      spacing: 4

PartyConfigWindow < MainWindow
  !text: tr('Party Auto - Configuracao by Kelus Scripts')
  size: 304 376
  visible: false
  @onEscape: self:hide()

  TabBar
    id: tabs
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    tab-spacing: 2

  Panel
    id: content
    anchors.top: tabs.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: buttonPanel.top
    image-source: /images/ui/panel_flat
    image-border: 5

  Panel
    id: buttonPanel
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 26
    margin-left: 5
    margin-right: 5
    margin-bottom: 4
    layout:
      type: horizontalBox
      spacing: 6

    Button
      id: closeBtn
      text: Fechar
      size: 80 18
      @onClick: self:getParent():getParent():hide()
]])

-- =============================
-- JANELA DE BLACKLIST
-- =============================

g_ui.loadUIFromString([[
BlacklistWindow < MainWindow
  size: 263 420
  visible: false
  @onEscape: self:hide()

  Label
    id: infoLabel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 8
    margin-left: 8
    margin-right: 8
    text-align: center
    font: verdana-11px-rounded

  TextEdit
    id: namesInput
    anchors.top: infoLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: saveButton.top
    margin: 8
    multiline: true
    font: verdana-11px-rounded

  Button
    id: saveButton
    text: Salvar
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.bottom: parent.bottom
    height: 18
    margin-left: 8
    margin-right: 4

  Button
    id: cancelButton
    text: Cancelar
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 18
    margin-left: 4
    margin-right: 8
]])

-- =============================
-- JANELA DE LIDERES
-- =============================

g_ui.loadUIFromString([[
LeadersWindow < MainWindow
  size: 263 420
  visible: false
  @onEscape: self:hide()

  Label
    id: infoLabel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 8
    margin-left: 8
    margin-right: 8
    text-align: center
    font: verdana-11px-rounded

  TextEdit
    id: namesInput
    anchors.top: infoLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: saveButton.top
    margin: 8
    multiline: true
    font: verdana-11px-rounded

  Button
    id: saveButton
    text: Salvar
    anchors.left: parent.left
    anchors.right: parent.horizontalCenter
    anchors.bottom: parent.bottom
    height: 18
    margin-left: 8
    margin-right: 4

  Button
    id: cancelButton
    text: Cancelar
    anchors.left: parent.horizontalCenter
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 18
    margin-left: 4
    margin-right: 8
]])

local partyWindow = nil
avisoMacroEnabled = storage.partyAvisoMacroEnabled == true
debugMacroEnabled = storage.partyDebugMacroEnabled == true

-- Funcao helper para criar abas
local function createTab(tabBar, tabName, tabId)
    local panel = g_ui.createWidget("PartyTabPanel")
    panel:setId("panel_" .. tabId)
    tabBar:addTab(tabName, panel)
    return panel
end

-- Macros de aviso e debug (criados dinamicamente para nao aparecerem na interface)
avisoMacro = nil
debugMacro = nil

createAvisoMacro = function()
    if avisoMacro then return end
    avisoMacro = macro(300, function()
        if not partyEnabled or not avisoMacroEnabled then return end
        if g_game and g_game.isOnline and not g_game.isOnline() then return end
        if not player then return end
        if player:getShield() > 2 then
            say(warningMessage)
            delay(20000)
        end
    end)
    -- Ativar se o estado salvo for true
    avisoMacro:setOn(avisoMacroEnabled)
    if avisoMacro.hide then
        avisoMacro:hide()
    end
end

createDebugMacro = function()
    if debugMacro then return end
    debugMacro = macro(300, function()
        if not partyEnabled or not debugMacroEnabled then return end
        if g_game and g_game.isOnline and not g_game.isOnline() then return end
        if not player then return end
        if player:getShield() > 2 then
            say(textDebug)
            delay(180000)
        end
    end)
    -- Ativar se o estado salvo for true
    debugMacro:setOn(debugMacroEnabled)
    if debugMacro.hide then
        debugMacro:hide()
    end
end

-- Criar macros se estiverem habilitados
if avisoMacroEnabled then
    createAvisoMacro()
end
if debugMacroEnabled then
    createDebugMacro()
end

-- Macros serao criados quando os botoes forem clicados pela primeira vez

-- Macro para pedir PT automaticamente
pedirPTMacro = nil
local lastPasswordSent = 0
local PASSWORD_DELAY = 30000 -- 30 segundos em milissegundos

createPedirPTMacro = function()
    if pedirPTMacro then return end
    pedirPTMacro = macro(1000, function() -- Verifica a cada 1 segundo
        if not pedirPTEnabled then return end
        if g_game and g_game.isOnline and not g_game.isOnline() then return end
        if not player then return end
        if partyPassword == "" or partyPassword == nil then return end
        if #leaders == 0 then return end
        if player:isPartyMember() then return end -- Para se ja estiver em party

        local playerPos = player:getPosition()
        if not playerPos then return end

        local currentTime = now
        if currentTime - lastPasswordSent < PASSWORD_DELAY then return end
        local leaderSet = {}
        for _, leaderName in ipairs(leaders) do
            local normalizedLeader = tostring(leaderName or ""):lower():trim()
            if normalizedLeader ~= "" then
                leaderSet[normalizedLeader] = true
            end
        end

        -- Verificar se algum lider esta proximo (5 sqm)
        for _, creature in ipairs(getSpectators() or {}) do
            if creature:isPlayer() and not creature:isLocalPlayer() then
                local creatureName = creature:getName()
                local creaturePos = creature:getPosition()

                if creaturePos then
                    -- Verificar se esta na lista de lideres
                    local isLeader = leaderSet[tostring(creatureName or ""):lower():trim()] == true

                    if isLeader then
                        -- Calcular distancia (Manhattan distance)
                        local distance = math.max(math.abs(playerPos.x - creaturePos.x), math.abs(playerPos.y - creaturePos.y))

                        if distance <= 5 then
                            -- Enviar senha
                            say(partyPassword)
                            lastPasswordSent = currentTime
                            return
                        end
                    end
                end
            end
        end
    end)
    -- Ativar se o estado salvo for true
    pedirPTMacro:setOn(pedirPTEnabled)
    if pedirPTMacro.hide then
        pedirPTMacro:hide()
    end
end

-- Criar macro se estiver habilitado
if pedirPTEnabled then
    createPedirPTMacro()
end

local function syncWindowSizeToReference(window, referenceWindow, fallbackWidth, fallbackHeight)
    if not window or not window.setSize then
        return
    end

    local width = tonumber(fallbackWidth) or 300
    local height = tonumber(fallbackHeight) or 400

    if referenceWindow then
        if referenceWindow.getWidth then
            local refWidth = tonumber(referenceWindow:getWidth())
            if refWidth and refWidth > 0 then
                width = refWidth
            end
        end
        if referenceWindow.getHeight then
            local refHeight = tonumber(referenceWindow:getHeight())
            if refHeight and refHeight > 0 then
                height = refHeight
            end
        end
    end

    window:setSize({ width = math.floor(width), height = math.floor(height) })
end

-- Funcao para abrir janela de Blacklist
local function openBlacklistWindow(updateCallback)
    local listWindow = g_ui.createWidget("BlacklistWindow", g_ui.getRootWidget())
    syncWindowSizeToReference(listWindow, partyWindow, 263, 420)

    listWindow:setText("Party Blacklist - Jogadores Bloqueados")

    local infoLabel = listWindow:getChildById("infoLabel")
    infoLabel:setText("Digite os nicknames dos jogadores bloqueados, separados por virgula:")

    local namesInput = listWindow:getChildById("namesInput")
    if #blacklist > 0 then
        namesInput:setText(table.concat(blacklist, ", "))
    end

    local saveButton = listWindow:getChildById("saveButton")
    saveButton.onClick = function()
        local text = namesInput:getText()
        local newList = {}

        if text and text ~= "" then
            for name in string.gmatch(text, "([^,]+)") do
                local trimmedName = name:match("^%s*(.-)%s*$")
                if trimmedName and trimmedName ~= "" then
                    table.insert(newList, trimmedName)
                end
            end
        end

        storage.partyBlacklist = newList
        blacklist = newList
        warn("[Party] Blacklist atualizada: " .. #newList .. " jogadores bloqueados")

        if updateCallback then
            updateCallback()
        end

        listWindow:destroy()
    end

    local cancelButton = listWindow:getChildById("cancelButton")
    cancelButton.onClick = function()
        listWindow:destroy()
    end

    listWindow:show()
    listWindow:raise()
    listWindow:focus()
    namesInput:focus()
end

-- Funcao para abrir janela de Lideres
local function openLeadersWindow(updateCallback)
    local listWindow = g_ui.createWidget("LeadersWindow", g_ui.getRootWidget())
    syncWindowSizeToReference(listWindow, partyWindow, 263, 420)

    listWindow:setText("Party Lideres - Lista de Lideres")

    local infoLabel = listWindow:getChildById("infoLabel")
    infoLabel:setText("Digite os nicknames dos lideres, separados por virgula:")

    local namesInput = listWindow:getChildById("namesInput")
    if #leaders > 0 then
        namesInput:setText(table.concat(leaders, ", "))
    end

    local saveButton = listWindow:getChildById("saveButton")
    saveButton.onClick = function()
        local text = namesInput:getText()
        local newList = {}

        if text and text ~= "" then
            for name in string.gmatch(text, "([^,]+)") do
                local trimmedName = name:match("^%s*(.-)%s*$")
                if trimmedName and trimmedName ~= "" then
                    table.insert(newList, trimmedName)
                end
            end
        end

        storage.partyLeaders = newList
        leaders = newList
        warn("[Party] Lista de lideres atualizada: " .. #newList .. " lideres")

        if updateCallback then
            updateCallback()
        end

        listWindow:destroy()
    end

    local cancelButton = listWindow:getChildById("cancelButton")
    cancelButton.onClick = function()
        listWindow:destroy()
    end

    listWindow:show()
    listWindow:raise()
    listWindow:focus()
    namesInput:focus()
end

-- Funcao para criar campos de configuracao
local function createConfigField(container, labelText, defaultValue, onChange, tooltip, tooltipEn, opts)
    opts = opts or {}
    local panel = setupUI([[
Panel
  height: 22
  margin-right: 2
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: label
    width: 86
    text-align: left
    text-auto-resize: false

  TextEdit
    id: field
    width: 126
    height: 18
]], container)

    if panel.label and panel.label.setWidth then
        panel.label:setWidth(tonumber(opts.labelWidth) or 86)
    end
    if panel.field and panel.field.setWidth then
        panel.field:setWidth(tonumber(opts.fieldWidth) or 126)
    end
    if panel.field and panel.field.setHeight then
        panel.field:setHeight(tonumber(opts.fieldHeight) or 18)
    end

    panel.label:setText(labelText)
    if tooltip then
        setStandardTooltip(panel.label, tooltip, tooltipEn or tooltip)
        setStandardTooltip(panel.field, tooltip, tooltipEn or tooltip)
    end
    panel.field:setText(tostring(defaultValue or ""))
    if opts.placeholder and panel.field.setPlaceholder then
        panel.field:setPlaceholder(tostring(opts.placeholder))
    end
    panel.field.onTextChange = onChange
    return panel.field
end

-- Funcao para construir conteudo da aba Config
local function buildConfigTab(panel)
    -- Acessar o ScrollablePanel interno do template
    local content = panel:getChildById('panelContent') or panel

    local function addSectionTitle(text, color)
        local label = UI.createWidget('BotLabel', content)
        label:setText(text)
        label:setColor(color or '#E6EDF3')
        label:setHeight(18)
        return label
    end

    local function refreshToggleButtonState(button, enabled, onText, offText, onBg, offBg)
        button:setText(enabled and onText or offText)
        button:setBackgroundColor(enabled and onBg or offBg)
    end

    addSectionTitle('Party', '#DDE6F7')

    local maxMembersField = createConfigField(
        content,
        'Max Members:',
        tostring(maxPartyMembers),
        function(widget, text)
            if text == "" or text == nil then
                return
            end
            local num = tonumber(text)
            if num and num >= 1 and num <= 24 then
                maxPartyMembers = num
                storage.maxPartyMembers = num
                warn("Limite Maximo de Membros alterado para: " .. num)
            else
                if text ~= tostring(maxPartyMembers) then
                    widget:setText(tostring(maxPartyMembers))
                    warn("Valor invalido. Use um numero entre 1 e 24.")
                end
            end
        end,
        "Numero maximo de membros na party (1 a 24).",
        nil,
        { labelWidth = 96, fieldWidth = 52, placeholder = "1-24" }
    )

    if maxMembersField then
        maxMembersField.onFocusChange = function(widget, focused)
            if focused then
                return
            end
            local text = widget:getText()
            local num = tonumber(text)
            if not num or num < 1 or num > 24 then
                widget:setText(tostring(maxPartyMembers))
                if text ~= "" and text ~= tostring(maxPartyMembers) then
                    warn("Valor invalido. Use um numero entre 1 e 24. Valor restaurado para: " .. maxPartyMembers)
                end
            end
        end
    end

    local levelRow = setupUI([[
Panel
  height: 22
  margin-right: 2
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: maxLevelLabel
    width: 74
    text: Max Level:
    text-align: left

  TextEdit
    id: maxLevelField
    width: 42
    height: 18

  BotLabel
    id: minLevelLabel
    width: 74
    text: Min Level:
    text-align: left

  TextEdit
    id: minLevelField
    width: 42
    height: 18
]], content)

    levelRow.maxLevelField:setText(storage.maxLevel or "")
    levelRow.minLevelField:setText(storage.minLevel or "")
    setStandardTooltip(levelRow.maxLevelLabel, "Nivel maximo permitido na party. Deixe vazio para desativar.", "Maximum level allowed in party. Leave empty to disable.")
    setStandardTooltip(levelRow.maxLevelField, "Nivel maximo permitido na party. Deixe vazio para desativar.", "Maximum level allowed in party. Leave empty to disable.")
    setStandardTooltip(levelRow.minLevelLabel, "Nivel minimo permitido na party. Deixe vazio para desativar.", "Minimum level allowed in party. Leave empty to disable.")
    setStandardTooltip(levelRow.minLevelField, "Nivel minimo permitido na party. Deixe vazio para desativar.", "Minimum level allowed in party. Leave empty to disable.")

    levelRow.maxLevelField.onTextChange = function(widget, text)
        local num = tonumber(text)
        if num then
            maxLevel = num
            storage.maxLevel = num
        else
            sayChannel(getChannelId("party"), "!party info")
        end
    end

    levelRow.minLevelField.onTextChange = function(widget, text)
        local num = tonumber(text)
        if num then
            minLevel = num
            storage.minLevel = num
        else
            sayChannel(getChannelId("party"), "!party info")
        end
    end

    UI.Separator(content)
    addSectionTitle('Convite', '#DDE6F7')

    createConfigField(
        content,
        'Palavra:',
        inviteKeyword,
        function(widget, text)
            if text and text:len() > 0 then
                inviteKeyword = text:lower()
                storage.inviteKeyword = inviteKeyword
                warn("Palavra-chave de convite alterada para: " .. inviteKeyword)
            else
                widget:setText(inviteKeyword)
                warn("A palavra-chave nao pode ser vazia.")
            end
        end,
        "Palavra-chave que ativa convite automatico quando dita no chat.",
        nil,
        { labelWidth = 96, fieldWidth = 132, placeholder = "ex: manda pt" }
    )

    createConfigField(
        content,
        'Msg Convite:',
        inviteMessage,
        function(widget, text)
            inviteMessage = text
            storage.inviteMessage = text
            warn("Mensagem de convite alterada.")
        end,
        "Mensagem dita quando detectar jogador proximo para convidar.",
        nil,
        { labelWidth = 96, fieldWidth = 132 }
    )

    UI.Separator(content)
    addSectionTitle('Avisos', '#DDE6F7')

    createConfigField(
        content,
        'Msg Aviso:',
        warningMessage,
        function(widget, text)
            warningMessage = text
            storage.warningMessage = text
            warn("Mensagem de aviso alterada.")
        end,
        "Mensagem dita periodicamente quando shield > 2.",
        nil,
        { labelWidth = 96, fieldWidth = 132 }
    )

    local togglesRow = setupUI([[
Panel
  height: 24
  margin-right: 2
  layout:
    type: horizontalBox
    spacing: 6

  Button
    id: avisoBtn
    width: 114
    height: 22

  Button
    id: debugBtn
    width: 114
    height: 22
]], content)

    local avisoBtn = togglesRow.avisoBtn
    avisoBtn:setColor('#FFFFFF')
    avisoBtn:setBorderColor('#87CEEB')
    setStandardTooltip(
        avisoBtn,
        "Ativa o envio de mensagens de aviso quando shield > 2. Delay de 20s entre mensagens.",
        "Enable warning messages when shield > 2. 20s delay between messages."
    )
    if avisoMacroEnabled and not avisoMacro then
        createAvisoMacro()
    end
    refreshToggleButtonState(avisoBtn, avisoMacroEnabled, "Aviso: ON", "Aviso: OFF", "#3a7ca5", "#1a1a2e")
    avisoBtn.onClick = function()
        avisoMacroEnabled = not avisoMacroEnabled
        storage.partyAvisoMacroEnabled = avisoMacroEnabled
        if avisoMacroEnabled then
            if not avisoMacro then
                createAvisoMacro()
            end
            avisoMacro:setOn(true)
        else
            if avisoMacro then
                avisoMacro:setOn(false)
            end
        end
        refreshToggleButtonState(avisoBtn, avisoMacroEnabled, "Aviso: ON", "Aviso: OFF", "#3a7ca5", "#1a1a2e")
    end

    local debugBtn = togglesRow.debugBtn
    debugBtn:setColor('#FFFFFF')
    debugBtn:setBorderColor('#87CEEB')
    setStandardTooltip(
        debugBtn,
        "Ativa o envio de !party info para debug. Delay de 180s entre mensagens.",
        "Enable !party info messages for debug. 180s delay between messages."
    )
    if debugMacroEnabled and not debugMacro then
        createDebugMacro()
    end
    refreshToggleButtonState(debugBtn, debugMacroEnabled, "Debug: ON", "Debug: OFF", "#3a7ca5", "#1a1a2e")
    debugBtn.onClick = function()
        debugMacroEnabled = not debugMacroEnabled
        storage.partyDebugMacroEnabled = debugMacroEnabled
        if debugMacroEnabled then
            if not debugMacro then
                createDebugMacro()
            end
            debugMacro:setOn(true)
        else
            if debugMacro then
                debugMacro:setOn(false)
            end
        end
        refreshToggleButtonState(debugBtn, debugMacroEnabled, "Debug: ON", "Debug: OFF", "#3a7ca5", "#1a1a2e")
    end

    local blacklistBtn = UI.createWidget('Button', content)
    blacklistBtn:setText('Blacklist (' .. #blacklist .. ')')
    blacklistBtn:setHeight(22)
    blacklistBtn:setColor('#FFFFFF')
    blacklistBtn:setBackgroundColor('#1a1a2e')
    blacklistBtn:setBorderColor('#FF6B6B')
    blacklistBtn:setBorderWidth(1)
    setStandardTooltip(
        blacklistBtn,
        "Abre a janela para configurar a lista de jogadores bloqueados (nao recebem convite).",
        "Open the window to configure the blocked players list (they won't receive invites)."
    )
    blacklistBtn.onClick = function()
        openBlacklistWindow(function()
            blacklistBtn:setText('Blacklist (' .. #blacklist .. ')')
        end)
    end
end

-- Funcao para construir conteudo da aba Pedir
local function buildPedirTab(panel)
    -- Acessar o ScrollablePanel interno do template
    local content = panel:getChildById('panelContent') or panel

    -- Titulo
    local titleLabel = UI.createWidget('BotLabel', content)
    titleLabel:setText('Pedir Party')
    titleLabel:setColor('#FFFFFF')
    titleLabel:setHeight(25)

    -- Separador
    UI.Separator(content)

    -- Botao Lideres
    local leadersBtn = UI.createWidget('Button', content)
    leadersBtn:setText('Lideres (' .. #leaders .. ')')
    leadersBtn:setHeight(25)
    leadersBtn:setColor('#FFFFFF')
    leadersBtn:setBackgroundColor('#1a1a2e')
    leadersBtn:setBorderColor('#87CEEB')
    leadersBtn:setBorderWidth(1)
    setStandardTooltip(leadersBtn, "Abre a janela para configurar a lista de lideres que o sistema procura.", "Open the window to configure the leaders list this system looks for.")
    leadersBtn.onClick = function()
        openLeadersWindow(function()
            leadersBtn:setText('Lideres (' .. #leaders .. ')')
        end)
    end

    -- Separador
    UI.Separator(content)

    -- Botao Pedir PT
    local pedirPTBtn = UI.createWidget('Button', content)
    pedirPTBtn:setHeight(25)
    pedirPTBtn:setColor('#FFFFFF')
    pedirPTBtn:setBackgroundColor('#1a1a2e')
    pedirPTBtn:setBorderColor('#98BF64')
    pedirPTBtn:setBorderWidth(1)
    setStandardTooltip(pedirPTBtn, "Ativa ou desativa o envio automatico de senha quando estiver proximo aos lideres.", "Enable or disable automatic password sending when near leaders.")
    -- Carregar estado do storage
    if pedirPTEnabled then
        pedirPTBtn:setText('Parar Pedir PT')
        pedirPTBtn:setBackgroundColor('#5a8a3a')
    else
        pedirPTBtn:setText('Pedir PT')
        pedirPTBtn:setBackgroundColor('#1a1a2e')
    end
    pedirPTBtn.onClick = function()
        pedirPTEnabled = not pedirPTEnabled
        storage.pedirPTEnabled = pedirPTEnabled
        if pedirPTEnabled then
            if not pedirPTMacro then
                createPedirPTMacro()
            end
            pedirPTMacro:setOn(true)
            pedirPTBtn:setText('Parar Pedir PT')
            pedirPTBtn:setBackgroundColor('#5a8a3a')
            warn("[Party] Sistema de pedir PT ativado")
        else
            if pedirPTMacro then
                pedirPTMacro:setOn(false)
            end
            pedirPTBtn:setText('Pedir PT')
            pedirPTBtn:setBackgroundColor('#1a1a2e')
            warn("[Party] Sistema de pedir PT desativado")
        end
    end

    -- Separador
    UI.Separator(content)

    -- Campo de Senha
    local passwordLabel = UI.createWidget('BotLabel', content)
    passwordLabel:setText('Senha:')
    passwordLabel:setColor('#FFFFFF')
    passwordLabel:setHeight(20)
    setStandardTooltip(passwordLabel, "Senha enviada quando estiver proximo aos lideres.", "Password sent when you are near leaders.")

    local passwordField = UI.createWidget('TextEdit', content)
    passwordField:setText(partyPassword)
    passwordField:setHeight(22)
    passwordField:setPlaceholder("Digite a senha")
    setStandardTooltip(passwordField, "Digite a senha que deseja enviar aos lideres.", "Type the password you want to send to leaders.")
    passwordField.onTextChange = function(widget, text)
        partyPassword = text
        storage.partyPassword = text
    end

    -- Separador
    UI.Separator(content)

    -- Label informativo
    local infoLabel = UI.createWidget('BotLabel', content)
    infoLabel:setText('O sistema enviara a senha automaticamente quando voce estiver a 5 sqm de algum lider da lista. A senha sera enviada a cada 30 segundos e parara quando voce estiver em party.')
    infoLabel:setColor('#FFFFFF')
    infoLabel:setHeight(50)
    setStandardTooltip(infoLabel, "O sistema verifica a distancia a cada segundo e envia a senha quando estiver proximo.", "The system checks distance every second and sends the password when you are nearby.")
end

-- Variavel para aceitar party (sem macro visivel)
acceptPartyEnabled = storage.acceptPartyEnabled == true
acceptPartyOnlyLeaders = storage.acceptPartyOnlyLeaders == true
local ACCEPT_PARTY_LOOP_TOKEN_KEY = "__hpToolsAcceptPartyLoopToken"
if type(_G) == "table" then
    _G[ACCEPT_PARTY_LOOP_TOKEN_KEY] = tonumber(_G[ACCEPT_PARTY_LOOP_TOKEN_KEY]) or 0
    _G[ACCEPT_PARTY_LOOP_TOKEN_KEY] = _G[ACCEPT_PARTY_LOOP_TOKEN_KEY] + 1
end
local acceptPartyLoopToken = type(_G) == "table" and _G[ACCEPT_PARTY_LOOP_TOKEN_KEY] or 0

-- Loop invisivel para aceitar party
local function acceptPartyLoop()
    if type(_G) == "table" and _G[ACCEPT_PARTY_LOOP_TOKEN_KEY] ~= acceptPartyLoopToken then
        return
    end
    if not acceptPartyEnabled then
        schedule(1000, acceptPartyLoop)
        return
    end
    if not player:isPartyMember() then
        for _, spec in ipairs(getSpectators(posz()) or {}) do
            if spec:isPlayer() and spec ~= player and spec:getShield() == 1 then
                local canAccept = true
                if acceptPartyOnlyLeaders then
                    canAccept = isNameInLeadersList(spec:getName())
                end
                if canAccept then
                    g_game.partyJoin(spec:getId())
                    break
                end
            end
        end
    end
    schedule(1000, acceptPartyLoop)
end
schedule(1000, acceptPartyLoop)

-- Funcao para construir conteudo da aba Acc
local function buildAccTab(panel)
    local content = panel:getChildById('panelContent') or panel

    -- Titulo
    local titleLabel = UI.createWidget('BotLabel', content)
    titleLabel:setText('Aceitar Party')
    titleLabel:setColor('#FFFFFF')
    titleLabel:setHeight(25)

    -- Separador
    UI.Separator(content)

    -- Botao Aceitar PT
    local acceptPTBtn = UI.createWidget('Button', content)
    acceptPTBtn:setHeight(25)
    acceptPTBtn:setColor('#FFFFFF')
    acceptPTBtn:setBackgroundColor('#1a1a2e')
    acceptPTBtn:setBorderColor('#98BF64')
    acceptPTBtn:setBorderWidth(1)
    setStandardTooltip(acceptPTBtn, "Ativa ou desativa o aceite automatico de convites de party.", "Enable or disable automatic acceptance of party invites.")

    if acceptPartyEnabled then
        acceptPTBtn:setText('Parar Aceitar PT')
        acceptPTBtn:setBackgroundColor('#5a8a3a')
    else
        acceptPTBtn:setText('Aceitar PT')
        acceptPTBtn:setBackgroundColor('#1a1a2e')
    end

    acceptPTBtn.onClick = function()
        acceptPartyEnabled = not acceptPartyEnabled
        storage.acceptPartyEnabled = acceptPartyEnabled
        if acceptPartyEnabled then
            acceptPTBtn:setText('Parar Aceitar PT')
            acceptPTBtn:setBackgroundColor('#5a8a3a')
            warn("[Party] Sistema de aceitar PT ativado")
        else
            acceptPTBtn:setText('Aceitar PT')
            acceptPTBtn:setBackgroundColor('#1a1a2e')
            warn("[Party] Sistema de aceitar PT desativado")
        end
    end

    -- Separador
    UI.Separator(content)

    local leadersOnlyCheck = UI.createWidget('CategoryCheckBox', content)
    leadersOnlyCheck:setText('Aceitar apenas Lideres')
    leadersOnlyCheck:setChecked(acceptPartyOnlyLeaders)
    setStandardTooltip(leadersOnlyCheck, "Quando ativo, aceita convite automatico apenas de jogadores da lista de Lideres.", "When enabled, automatically accepts invites only from players in the Leaders list.")
    leadersOnlyCheck.onClick = function(widget)
        acceptPartyOnlyLeaders = not acceptPartyOnlyLeaders
        storage.acceptPartyOnlyLeaders = acceptPartyOnlyLeaders
        widget:setChecked(acceptPartyOnlyLeaders)
    end

    -- Separador
    UI.Separator(content)

    -- Info
    local infoLabel = UI.createWidget('BotLabel', content)
    infoLabel:setText('Quando "Aceitar apenas Lideres" estiver ativo, o sistema aceita somente jogadores da lista de Lideres.')
    infoLabel:setColor('#FFFFFF')
    infoLabel:setHeight(40)
end

-- Funcao para abrir janela de configuracao
local function openPartyWindow()
    if partyWindow then
        partyWindow:show()
        partyWindow:raise()
        partyWindow:focus()
        return
    end

    partyWindow = g_ui.createWidget('PartyConfigWindow', g_ui.getRootWidget())

    -- Configurar TabBar
    local tabBar = partyWindow.tabs
    tabBar:setContentWidget(partyWindow.content)

    -- Criar abas
    local tabNames = { 'Config', 'Pedir', 'Acc' }
    local tabPanels = {}

    for index, tabName in ipairs(tabNames) do
        local panel = createTab(tabBar, tabName, index)
        tabPanels[tabName] = panel

        if tabName == 'Config' then
            buildConfigTab(panel)
        elseif tabName == 'Pedir' then
            buildPedirTab(panel)
        elseif tabName == 'Acc' then
            buildAccTab(panel)
        end
    end

    -- Selecionar primeira aba
    tabBar:selectTab(tabBar.tabs[1])

    local closeBtn = partyWindow:recursiveGetChildById('closeBtn') or partyWindow:getChildById('closeBtn')
    if closeBtn then
        closeBtn.onClick = function()
            if partyWindow then
                partyWindow:hide()
            end
        end
    end
end

-- Conectar botao Setup
if partyUI then
    partyUI.setup.onClick = function()
        openPartyWindow()
    end
end


-- =============================
-- COMANDOS DE CONSOLE (CHAT) E CONVITE AUTOMATICO
-- =============================

onTalk(function(name, level, mode, text, channelId, pos)
    -- Comando para alterar o limite maximo de membros
    if name == player:getName() and text:lower():find("!maxpt") then
        local novoMax = text:match("!maxpt%s+(%d+)")
        if novoMax then
            local num = tonumber(novoMax)
            if num and num >= 1 and num <= 24 then
                maxPartyMembers = num
                storage.maxPartyMembers = num
                warn("Limite Maximo de Membros (MaxPT) alterado para: " .. num)
            else
                warn("Uso correto: !maxpt <numero entre 1 e 24>")
            end
        else
            warn("Uso correto: !maxpt <numero>")
        end
        return
    end

    -- Logica de convite
    if not partyEnabled then return end
    if name == player:getName() then return end

    local lowerText = text:lower()
    local lowerKeyword = inviteKeyword:lower()

    -- Verifica se a mensagem contem a palavra-chave OU se o jogador usou "party" (como fallback)
    if lowerText:find(lowerKeyword) or (lowerText:find("party") and not lowerText:find("!party")) then
        for _, spec in ipairs(getSpectators() or {}) do
            if spec:getName() == name and spec:isPlayer() then
                if spec:isPartyMember() then return end
                if spec:getShield() == 2 then return end
                if (maxLevel > 0 and level > maxLevel) or (minLevel > 0 and level < minLevel) then return end
                if isBlacklisted(name) then return end -- Verificar blacklist

                if partyMembersCount >= maxPartyMembers then
                    return
                end

                g_game.partyInvite(spec:getId())
                return
            end
        end
    end
end)


-- =============================
-- OUTROS MACROS DE ACAO E DEBUG
-- =============================
-- Macros movidos para dentro da janela de configuracao



-- =============================
-- INFORMACAO DO CANAL (!party info)
-- =============================

onLoginAdvice(function(text)
    if not partyEnabled then return end

    local explode1 = string.explode(text, "*")
    local explode2 = string.explode(explode1[8], ":")[2]

    local playerLevelInAdvice = tonumber(string.explode(explode1[4] or explode1[3], ":")[2]) or player:getLevel()

    if not storage.maxLevel then
        maxLevel = math.ceil(playerLevelInAdvice * 3 / 2)
    else
        maxLevel = storage.maxLevel
    end

    if not storage.minLevel then
        minLevel = math.ceil(playerLevelInAdvice * 2 / 3)
    else
        minLevel = storage.minLevel
    end

    partyMembersCount = tonumber(string.explode(explode1[2], ":")[2]) or 0

    if justForInfo then
        justForInfo = false
        return
    end

    -- Remocao de membros fora dos criterios (Kick)
    local function kickMember(name)
        sayChannel(getChannelId("party"), "!party kick," .. name)
    end

    if explode2:find(",") then
        local names = string.explode(explode2, ",")
        for i = 1, #names do
            canSeeInfo = false
            schedule(1000 * i, function()
                if i == #names then canSeeInfo = true end
                kickMember(names[i])
            end)
        end
    elseif explode2 ~= "" then
        schedule(1000, function() kickMember(explode2) end)
    end
end)

-- =============================
-- DETECCAO DE JOGADORES PROXIMOS
-- =============================

onCreatureAppear(function(creature)
    if not partyEnabled then return end
    if not creature:isPlayer() or creature:isLocalPlayer() or creature:isPartyMember() then return end
    if creature:getShield() == 2 then return end
    if isBlacklisted(creature:getName()) then return end -- Verificar blacklist

    if talkTime == 0 and partyMembersCount < maxPartyMembers then
        say(inviteMessage)
        delay(20000)
    end
end)

-- =============================
-- ATUALIZACAO DE ESTADO
-- =============================

onTextMessage(function(mode, text)
    if not partyEnabled then return end
    local msg = text:lower()

    if msg:find("you are now the leader of the party.")
        or msg:find("has joined the party.")
        or (msg:find("has left the party.") and canSeeInfo)
    then
        justForInfo = true

        -- Ativar shared automaticamente quando alguem entra na party ou quando vira lider
        if player:isPartyLeader() and not player:isPartySharedExperienceActive() then
            schedule(500, function()
                if player:isPartyLeader() and not player:isPartySharedExperienceActive() then
                    g_game.partyShareExperience(true)
                end
            end)
        end
    end
end)

-- ============================================
-- CONTAINER PRINCIPAL COM LAYOUT VERTICAL
-- ============================================
local mainContainer = embedded and parent or setupWindow.contentPanel.scrollContent

-- ============================================
-- MODO DE CURA (Escolha: Spell ou Item)
-- ============================================
local modePanel = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 6

  CategoryCheckBox
    id: spellMode
    text: Magia
    width: 96

  CategoryCheckBox
    id: itemMode
    text: Item (UH)
    width: 98
]], mainContainer)

-- Funcao para atualizar modo selecionado
local function updateModeButtons(selectedMode)
    config.healMode = selectedMode
    modePanel.spellMode:setChecked(selectedMode == "spell")
    modePanel.itemMode:setChecked(selectedMode == "item")
end

-- Inicializar com modo salvo
updateModeButtons(config.healMode)

-- Adicionar tooltips
setStandardTooltip(modePanel.spellMode, "Modo magia: usa spell para curar alvo com menor HP dentro da distancia.", "Spell mode: uses a spell to heal the lowest HP target within range.")
setStandardTooltip(modePanel.itemMode, "Modo item: usa item (UH) para curar alvo com menor HP dentro da distancia.", "Item mode: uses an item (UH) to heal the lowest HP target within range.")

-- Eventos dos checkboxes
modePanel.spellMode.onClick = function(widget)
    if config.healMode ~= "spell" then
        updateModeButtons("spell")
    end
end

modePanel.itemMode.onClick = function(widget)
    if config.healMode ~= "item" then
        updateModeButtons("item")
    end
end

-- ============================================
-- BOTOES DE CONTROLE (Filtros e Lista)
-- ============================================
local controlButtonsPanel = setupUI([[
Panel
  height: 24
  layout:
    type: horizontalBox
    spacing: 6

  Button
    id: filtrosBtn
    text: Filtros
    height: 20
    width: 90

  Button
    id: listaBtn
    text: Lista Custom
    height: 20
    width: 90
]], mainContainer)
setStandardTooltip(controlButtonsPanel.filtrosBtn, "Abre os filtros de quem pode ser curado.", "Open filters that define who can be healed.")
setStandardTooltip(controlButtonsPanel.listaBtn, "Abre a lista customizada de jogadores para cura.", "Open custom player list for healing.")

g_ui.createWidget('BotSeparator', mainContainer)

-- ============================================
-- CONFIGURACOES DE SPELL
-- ============================================
local spellSectionLabel = g_ui.createWidget('BotLabel', mainContainer)
spellSectionLabel:setText('Configuracoes de Magia')
spellSectionLabel:setColor('#DDE6F7')
spellSectionLabel:setHeight(18)
setStandardTooltip(spellSectionLabel, "Configure a spell de cura e os parametros de quando curar party/amigos.", "Configure the healing spell and trigger parameters for party/friends.")

-- Campo de texto para spell
local spellPanel = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: spellLabel
    width: 92
    text: Spell:
    text-align: left
    text-auto-resize: false

  TextEdit
    id: spellInput
    width: 190
    height: 18
    placeholder: exura sio "
]], mainContainer)

spellPanel.spellInput:setText(config.spell)
spellPanel.spellInput.onTextChange = function(widget, text)
    config.spell = text
end
setStandardTooltip(spellPanel.spellInput, "Digite o nome da spell. Use aspas para adicionar o nome automaticamente.", "Type the spell name. Use quotes to append the player name automatically.")
setStandardTooltip(spellPanel.spellLabel, "Spell de cura usada no modo magia.", "Healing spell used in spell mode.")

-- HP Percent
local hpPanel = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: hpLabel
    width: 92
    text: HP Spell <=
    text-align: left
    text-auto-resize: false

  HorizontalScrollBar
    id: hpScroll
    width: 132
    minimum: 10
    maximum: 99
    step: 1

  BotLabel
    id: hpValue
    width: 62
    text-align: right
]], mainContainer)

hpPanel.hpScroll:setValue(config.hpPercent)
hpPanel.hpValue:setText(tostring(config.hpPercent) .. "%")
setStandardTooltip(hpPanel.hpLabel, "HP% minimo para iniciar cura. Dica: 60-80% preventivo, 30-50% emergencia.", "Minimum HP% to start healing. Tip: 60-80% preventive, 30-50% emergency.")

hpPanel.hpScroll.onValueChange = function(scroll, value)
    config.hpPercent = value
    hpPanel.hpValue:setText(tostring(value) .. "%")
end
setStandardTooltip(hpPanel.hpScroll, "Arraste para ajustar entre 10% e 99%.", "Drag to adjust between 10% and 99%.")

-- Delay
local delayPanel = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: delayLabel
    width: 92
    text: Delay:
    text-align: left
    text-auto-resize: false

  HorizontalScrollBar
    id: delayScroll
    width: 132
    minimum: 100
    maximum: 5000
    step: 100

  BotLabel
    id: delayValue
    width: 62
    text-align: right
]], mainContainer)

delayPanel.delayScroll:setValue(config.delay)
delayPanel.delayValue:setText(tostring(config.delay) .. "ms")
setStandardTooltip(delayPanel.delayLabel, "Intervalo minimo entre curas consecutivas. Dica: 1000-2000 ms para evitar cooldown.", "Minimum interval between consecutive heals. Tip: 1000-2000 ms to avoid cooldown conflicts.")

delayPanel.delayScroll.onValueChange = function(scroll, value)
    config.delay = value
    delayPanel.delayValue:setText(tostring(value) .. "ms")
end
setStandardTooltip(delayPanel.delayScroll, "Arraste para ajustar entre 100 ms e 5000 ms.", "Drag to adjust between 100 ms and 5000 ms.")

-- Distancia
local distPanel = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: distLabel
    width: 92
    text: Distancia:
    text-align: left
    text-auto-resize: false

  HorizontalScrollBar
    id: distScroll
    width: 132
    minimum: 1
    maximum: 10
    step: 1

  BotLabel
    id: distValue
    width: 62
    text-align: right
]], mainContainer)

distPanel.distScroll:setValue(config.distance)
distPanel.distValue:setText(tostring(config.distance) .. " sqm")
setStandardTooltip(distPanel.distLabel, "Distancia maxima (sqm) para curar amigos. Valor de 1 a 10 (6 = alcance da spell, 8+ = perigoso).", "Maximum distance (sqm) to heal friends. Range 1-10 (6 = spell range, 8+ = risky).")

distPanel.distScroll.onValueChange = function(scroll, value)
    config.distance = value
    distPanel.distValue:setText(tostring(value) .. " sqm")
end
setStandardTooltip(distPanel.distScroll, "Arraste para ajustar entre 1 e 10 sqm.", "Drag to adjust between 1 and 10 sqm.")

-- Separador
g_ui.createWidget('BotSeparator', mainContainer)

-- ============================================
-- CURA COM ITEM (UH) - Integrado na Config Geral
-- ============================================
local itemSectionLabel = g_ui.createWidget('BotLabel', mainContainer)
itemSectionLabel:setText('Configuracoes de Item')
itemSectionLabel:setColor('#DDE6F7')
itemSectionLabel:setHeight(18)
setStandardTooltip(itemSectionLabel, "Configure o item de cura (UH) para usar quando party/amigos estiverem com HP baixo.", "Configure healing item (UH) usage when party/friends are low HP.")

-- Item ID
local itemIdPanel = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: itemIdLabel
    width: 92
    text: Item ID:
    text-align: left
    text-auto-resize: false

  TextEdit
    id: itemIdInput
    width: 130
    height: 18
    placeholder: 3160

  BotLabel
    id: itemHint
    width: 62
    text: UH=3160
    text-align: right
]], mainContainer)

itemIdPanel.itemIdInput:setText(tostring(config.itemHeal.itemId))
itemIdPanel.itemIdInput.onTextChange = function(widget, text)
    local value = tonumber(text)
    if value and value > 0 then
        config.itemHeal.itemId = value
    end
end
setStandardTooltip(itemIdPanel.itemIdLabel, "ID do item de cura. 3160 = UH (Ultimate Health Potion).", "Healing item ID. 3160 = UH (Ultimate Health Potion).")
setStandardTooltip(itemIdPanel.itemIdInput, "Digite o ID do item de cura. Encontre IDs usando /getitemid ou database.", "Type the healing item ID. Find IDs with /getitemid or an items database.")

-- HP para usar item
local itemHpPanel = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: itemHpLabel
    width: 92
    text: HP Item <=
    text-align: left
    text-auto-resize: false

  HorizontalScrollBar
    id: itemHpScroll
    width: 132
    minimum: 10
    maximum: 99
    step: 1

  BotLabel
    id: itemHpValue
    width: 62
    text-align: right
]], mainContainer)

itemHpPanel.itemHpScroll:setValue(config.itemHeal.useBelow)
itemHpPanel.itemHpValue:setText(tostring(config.itemHeal.useBelow) .. "%")
setStandardTooltip(itemHpPanel.itemHpLabel, "HP% minimo para usar item em party/amigos. Geralmente mais baixo que spell (emergencia).", "Minimum HP% to use item on party/friends. Usually lower than spell (emergency).")

itemHpPanel.itemHpScroll.onValueChange = function(scroll, value)
    config.itemHeal.useBelow = value
    itemHpPanel.itemHpValue:setText(tostring(value) .. "%")
end
setStandardTooltip(itemHpPanel.itemHpScroll, "Arraste para ajustar entre 10% e 99%.", "Drag to adjust between 10% and 99%.")

-- Distancia do item
local itemDistPanel = setupUI([[
Panel
  height: 22
  layout:
    type: horizontalBox
    spacing: 4

  BotLabel
    id: itemDistLabel
    width: 92
    text: Dist. Item:
    text-align: left
    text-auto-resize: false

  HorizontalScrollBar
    id: itemDistScroll
    width: 132
    minimum: 1
    maximum: 6
    step: 1

  BotLabel
    id: itemDistValue
    width: 62
    text-align: right
]], mainContainer)

itemDistPanel.itemDistScroll:setValue(config.itemHeal.distance)
itemDistPanel.itemDistValue:setText(tostring(config.itemHeal.distance) .. " sqm")
setStandardTooltip(itemDistPanel.itemDistLabel, "Distancia maxima para usar item. Itens geralmente precisam estar perto (1-3 sqm).", "Maximum distance to use item. Items usually require short range (1-3 sqm).")

itemDistPanel.itemDistScroll.onValueChange = function(scroll, value)
    config.itemHeal.distance = value
    itemDistPanel.itemDistValue:setText(tostring(value) .. " sqm")
end
setStandardTooltip(itemDistPanel.itemDistScroll, "Arraste para ajustar entre 1 e 6 sqm.", "Drag to adjust between 1 and 6 sqm.")


-- ============================================
-- JANELA DE FILTROS
-- ============================================
local filtrosWindow = setupUI([[
MainWindow
  text: Filtros - Quem Curar?
  size: 336 312
  id: filtrosWindow

  Panel
    id: filtrosPanel
    anchors.fill: parent
    margin-top: 26
    margin-left: 10
    margin-right: 10
    margin-bottom: 30
    layout:
      type: verticalBox
      spacing: 5

    Label
      text: Selecione quem pode receber cura:
      text-align: center
      height: 18

    CategoryCheckBox
      id: vipCheckbox
      text: VIP List

    CategoryCheckBox
      id: partyCheckbox
      text: Party Members

    CategoryCheckBox
      id: guildCheckbox
      text: Guild Members

    CategoryCheckBox
      id: customCheckbox
      text: Lista Customizada
]], g_ui.getRootWidget())

filtrosWindow:hide()
syncWindowSizeToReference(filtrosWindow, setupWindow, 336, 312)

-- Configurar estados dos checkboxes
filtrosWindow.filtrosPanel.vipCheckbox:setChecked(config.filters.vipList)
filtrosWindow.filtrosPanel.partyCheckbox:setChecked(config.filters.partyMembers)
filtrosWindow.filtrosPanel.guildCheckbox:setChecked(config.filters.guildMembers)
filtrosWindow.filtrosPanel.customCheckbox:setChecked(config.filters.customList)

-- Adicionar tooltips aos checkboxes de filtros
setStandardTooltip(filtrosWindow.filtrosPanel.vipCheckbox, "Cura jogadores da sua VIP List. Marque se voce adiciona amigos manualmente.", "Heal players from your VIP List. Enable if you manually add friends.")
setStandardTooltip(filtrosWindow.filtrosPanel.partyCheckbox, "Cura membros do party automaticamente. Essencial em hunts em grupo.", "Heal party members automatically. Essential for team hunts.")
setStandardTooltip(filtrosWindow.filtrosPanel.guildCheckbox, "Cura membros da guild. Funciona apenas se voce estiver em uma guild.", "Heal guild members. Works only if you are in a guild.")
setStandardTooltip(filtrosWindow.filtrosPanel.customCheckbox, "Cura apenas jogadores da Lista Customizada. Clique em 'Lista' para adicionar jogadores.", "Heal only players from the custom list. Click 'Lista' to add players.")

-- Eventos dos checkboxes
filtrosWindow.filtrosPanel.vipCheckbox.onClick = function(widget)
    config.filters.vipList = not config.filters.vipList
    widget:setChecked(config.filters.vipList)
end

filtrosWindow.filtrosPanel.partyCheckbox.onClick = function(widget)
    config.filters.partyMembers = not config.filters.partyMembers
    widget:setChecked(config.filters.partyMembers)
end

filtrosWindow.filtrosPanel.guildCheckbox.onClick = function(widget)
    config.filters.guildMembers = not config.filters.guildMembers
    widget:setChecked(config.filters.guildMembers)
end

filtrosWindow.filtrosPanel.customCheckbox.onClick = function(widget)
    config.filters.customList = not config.filters.customList
    widget:setChecked(config.filters.customList)
end

-- Botao fechar filtros
local closeFiltrosBtn = setupUI([[
Button
  text: Fechar
  size: 86 20
  anchors.bottom: parent.bottom
  anchors.right: parent.right
  margin-right: 8
  margin-bottom: 6
]], filtrosWindow)

-- ============================================
-- JANELA DE LISTA CUSTOMIZADA
-- ============================================
local listaWindow = setupUI([[
MainWindow
  text: Lista Customizada
  size: 336 358
  id: listaWindow

  Panel
    id: listaPanel
    anchors.fill: parent
    margin-top: 24
    margin-left: 10
    margin-right: 10
    margin-bottom: 30
    layout:
      type: verticalBox
      spacing: 4

    Label
      text: Lista de Jogadores
      text-align: center
      height: 18
]], g_ui.getRootWidget())

listaWindow:hide()
syncWindowSizeToReference(listaWindow, setupWindow, 336, 358)

-- Input panel
local inputPanel = setupUI([[
Panel
  height: 38
  margin-top: 2

  Label
    id: infoLabel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    text: Digite o nome do jogador:
    text-align: left
    height: 14

  Button
    id: addButton
    anchors.top: infoLabel.bottom
    anchors.right: parent.right
    margin-top: 2
    width: 82
    height: 20
    text: Adicionar

  TextEdit
    id: nameInput
    anchors.top: infoLabel.bottom
    anchors.left: parent.left
    anchors.right: addButton.left
    margin-top: 2
    margin-right: 4
    height: 20
    placeholder: Nome do Jogador
]], listaWindow.listaPanel)

setStandardTooltip(inputPanel.nameInput, "Digite o nome exato do jogador que voce quer curar. O nome sera formatado automaticamente.", "Type the exact player name you want to heal. The name will be automatically formatted.")

-- Lista scrollavel
local listContainer = setupUI([[
Panel
  height: 238
  margin-top: 2

  ScrollablePanel
    id: scrollList
    anchors.fill: parent
    margin-left: 5
    margin-right: 11
    padding: 4
    padding-left: 6
    vertical-scrollbar: scrollBar
    layout:
      type: verticalBox
      spacing: 2

  VerticalScrollBar
    id: scrollBar
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    step: 12
    pixels-scroll: true
]], listaWindow.listaPanel)

-- Funcao para adicionar entrada na lista
local function addPlayerToList(playerName)
    if not playerName or playerName == "" or playerName == "Nome do Jogador" then
        return warn("[Curar Amigos] Digite um nome valido!")
    end

    -- Capitalizar primeira letra de cada palavra
    local formattedName = ""
    for word in playerName:gmatch("%S+") do
        formattedName = formattedName .. word:sub(1,1):upper() .. word:sub(2):lower() .. " "
    end
    formattedName = formattedName:trim()

    if config.customList[formattedName] then
        return warn("[Curar Amigos] Jogador ja esta na lista!")
    end

    config.customList[formattedName] = true

    -- Criar widget
    local entry = g_ui.createWidget('CustomListEntry', listContainer.scrollList)
    entry.nameLabel:setText(formattedName)
    entry.removeBtn.onClick = function()
        config.customList[formattedName] = nil
        entry:destroy()
    end

    inputPanel.nameInput:setText("")
end

-- Botao adicionar
inputPanel.addButton.onClick = function()
    addPlayerToList(inputPanel.nameInput:getText())
end

-- Enter no input
inputPanel.nameInput.onKeyPress = function(widget, keyCode, keyText)
    if keyCode == 13 then -- Enter
        addPlayerToList(widget:getText())
        return true
    end
end

-- Carregar lista existente
for playerName, _ in pairs(config.customList) do
    local entry = g_ui.createWidget('CustomListEntry', listContainer.scrollList)
    entry.nameLabel:setText(playerName)
    entry.removeBtn.onClick = function()
        config.customList[playerName] = nil
        entry:destroy()
    end
end

-- Botao fechar lista
local closeListaBtn = setupUI([[
Button
  text: Fechar
  size: 86 20
  anchors.bottom: parent.bottom
  anchors.right: parent.right
  margin-right: 8
  margin-bottom: 6
]], listaWindow)

-- ============================================
-- MAIN BUTTON HANDLERS
-- ============================================
if mainUI then
    mainUI.toggleBtn:setOn(config.enabled)
    setStandardTooltip(mainUI.toggleBtn, "Ativa ou desativa o sistema de cura de amigos. Funciona automaticamente durante a hunt.", "Enable or disable the friend healer system. It runs automatically while hunting.")
    mainUI.toggleBtn.onClick = function(widget)
        config.enabled = not config.enabled
        widget:setOn(config.enabled)

        if config.enabled then
            info("[Curar Amigos] Sistema ATIVADO")
        else
            info("[Curar Amigos] Sistema DESATIVADO")
        end
    end

    setStandardTooltip(mainUI.setupBtn, "Abre a janela de configuracao para ajustar spells, itens e filtros.", "Open the setup window to adjust spells, items, and filters.")
    mainUI.setupBtn.onClick = function()
        setupWindow:show()
        setupWindow:raise()
        setupWindow:focus()
    end
end

if setupWindow and setupWindow.closeButton then
    setupWindow.closeButton.onClick = function()
        setupWindow:hide()
    end
end

-- Botao Filtros
controlButtonsPanel.filtrosBtn.onClick = function()
    syncWindowSizeToReference(filtrosWindow, setupWindow, 336, 312)
    filtrosWindow:show()
    filtrosWindow:raise()
    filtrosWindow:focus()
end

closeFiltrosBtn.onClick = function()
    filtrosWindow:hide()
end

-- Botao Lista
controlButtonsPanel.listaBtn.onClick = function()
    syncWindowSizeToReference(listaWindow, setupWindow, 336, 358)
    listaWindow:show()
    listaWindow:raise()
    listaWindow:focus()
end

closeListaBtn.onClick = function()
    listaWindow:hide()
end


-- ============================================
-- CORE LOGIC
-- ============================================
local lastSpellUse = 0
local lastItemUse = 0

-- Verificar se jogador esta na VIP list
local function isInVipList(playerName)
    for id, data in pairs(g_game.getVips()) do
        if data[1] == playerName then
            return true
        end
    end
    return false
end

-- Validar candidato para cura
local function isValidCandidate(creature)
    if not creature or not creature:isPlayer() then return false end
    if creature:isLocalPlayer() then return false end

    local name = creature:getName()
    local pos = creature:getPosition()
    local tile = g_map.getTile(pos)

    -- Verificar linha de visao
    if not tile or not tile:canShoot() then return false end

    -- Verificar distancia
    local dist = getDistanceBetween(pos, player:getPosition())
    if dist > config.distance then return false end

    -- Aplicar filtros
    local passedFilter = false

    -- Lista customizada (prioridade)
    if config.filters.customList and config.customList[name] then
        passedFilter = true
    end

    -- VIP List
    if config.filters.vipList and isInVipList(name) then
        passedFilter = true
    end

    -- Party Members
    if config.filters.partyMembers and creature:isPartyMember() then
        passedFilter = true
    end

    -- Guild Members
    if config.filters.guildMembers and creature:getEmblem() == 1 then
        passedFilter = true
    end

    return passedFilter
end

-- Encontrar melhor target (menor HP%)
local function getBestTarget()
    local spectators = getSpectators() or {}
    local bestTarget = nil
    local lowestHp = 100

    for _, creature in ipairs(spectators) do
        if isValidCandidate(creature) then
            local hp = creature:getHealthPercent()

            -- Verificar se precisa de cura
            if hp <= config.hpPercent and hp < lowestHp then
                bestTarget = creature
                lowestHp = hp
            end
        end
    end

    return bestTarget, lowestHp
end

-- ============================================
-- MAIN MACRO
-- ============================================
macro(160, function()
    if not config.enabled then return end
    if g_game and g_game.isOnline and not g_game.isOnline() then return end
    if not player or not player.getPosition then return end

    -- Verificar cooldown global de spell (apenas se modo spell)
    if config.healMode == "spell" and modules.game_cooldown and modules.game_cooldown.isGroupCooldownIconActive(2) then
        return
    end

    -- Encontrar melhor target
    local target, targetHp = getBestTarget()
    if not target then return end

    local targetName = target:getName()
    local targetPos = target:getPosition()
    local dist = getDistanceBetween(targetPos, player:getPosition())

    -- Modo: Item
    if config.healMode == "item" then
        if targetHp <= config.itemHeal.useBelow and dist <= config.itemHeal.distance then
            if now - lastItemUse >= config.delay then
                if findItem(config.itemHeal.itemId) then
                    lastItemUse = now
                    return g_game.useInventoryItemWith(config.itemHeal.itemId, target)
                end
            end
        end
        return
    end

    -- Modo: Spell
    if config.healMode == "spell" then
        if targetHp <= config.hpPercent then
            if now - lastSpellUse >= config.delay then
                lastSpellUse = now
                return say(config.spell .. targetName)
            end
        end
        return
    end
end)

  PartyAutoUI = PartyAutoUI or {}
  PartyAutoUI.buildConfigTab = buildConfigTab
  PartyAutoUI.buildPedirTab = buildPedirTab
  PartyAutoUI.buildAccTab = buildAccTab
  PartyAutoUI.friendHealerSetup = friendHealerSetup
  PartyAutoUI.setPartyEnabled = setPartyEnabled
  PartyAutoUI.openPartyWindow = openPartyWindow
  PartyAutoUI.openFriendWindow = function()
    if not setupWindow then
      return
    end
    setupWindow:show()
    setupWindow:raise()
    setupWindow:focus()
  end
  PartyAutoUI.isLoaded = true
  PartyAutoUI.embedded = partyAutoEmbed

end -- friendHealerSetup




-- ====================================
-- FRIEND HEALER
-- ====================================
-- Carregamento imediato (sem delay)
if partyAutoEmbed then
    friendHealerSetup(nil, { hideStandaloneToggles = true })
else
    friendHealerSetup()
end

-- VOC?? PODE ADICIONAR MAIS C??DIGO AQUI

-- ============================================
-- FIM DO SCRIPT
-- ============================================
if not partyAutoEmbed then
    modules.client_terminal.executeCommand("clear")
end

local function buildCuraTabContent()
  local curaTab = healingTabs.cura
  if not curaTab then return end
  local content = getTabContent(curaTab)
  if content then
    clearChildren(content)
  end
  buildHealingProfilePanel(curaTab, {
    enabled = storage.healingSystemEnabled,
    switchTooltip = "PT: Ativa ou desativa o sistema completo de HP/Tools.\nEN: Enable or disable the full HP/Tools system.",
    onToggle = setHealingEnabled
  })
  buildHealingTab(curaTab)
  local updated = getTabContent(curaTab)
  refreshLayout(updated)
  local scrollBar = curaTab and curaTab.getChildById and curaTab:getChildById('panelScroll')
  if scrollBar and scrollBar.setValue then
    scrollBar:setValue(0)
  end
end

local function buildToolsTabContent()
  local toolsTab = healingTabs.tools
  if not toolsTab then return end
  if toolsRuntimeInitialized then
    return
  end
  toolsRuntimeInitialized = true
  local content = getTabContent(toolsTab)
  if content then
    clearChildren(content)
  end
  createTabHeader(toolsTab, 'Tools', {
    enabled = storage.toolsEnabled == true,
    switchTooltip = "PT: Ativa ou desativa macros e ferramentas do Tools.\nEN: Enable or disable Tools macros and utilities.",
    onToggle = function(enabled)
      storage.toolsEnabled = enabled == true
    end,
    tooltip = "PT: Macros automaticos e ferramentas gerais do Tools.\nEN: Automatic macros and general tools utilities."
  })
  buildToolsTab(toolsTab)
  local updated = getTabContent(toolsTab)
  ensurePanelHeight(updated)
  refreshLayout(updated)
end

local function buildPartyTabContent()
  local partyTab = healingTabs.party
  if not partyTab then return end
  local content = getTabContent(partyTab)
  if content then
    clearChildren(content)
  end
  createTabHeader(partyTab, 'Party Auto', {
    enabled = storage.partyEnabled == true,
    switchTooltip = "PT: Ativa ou desativa o sistema de Party Auto.\nEN: Enable or disable the Party Auto system.",
    onToggle = function(enabled)
      storage.partyEnabled = enabled
      if PartyAutoUI and PartyAutoUI.setPartyEnabled then
        PartyAutoUI.setPartyEnabled(enabled)
      end
    end
  })

  local partyContent = getTabContent(partyTab)
  if PartyAutoUI and PartyAutoUI.buildConfigTab then
    if PartyAutoUI.setPartyEnabled then
      PartyAutoUI.setPartyEnabled(storage.partyEnabled == true)
    end
    local function addPartySubSection(title, buildFn)
      local titleLabel = g_ui.createWidget('BotLabel', partyContent)
      titleLabel:setText(title)
      titleLabel:setColor('#FFFFFF')
      titleLabel:setHeight(20)
      if titleLabel.setTextAlign then
        titleLabel:setTextAlign(AlignLeft)
      end
      if titleLabel.setMarginLeft then
        titleLabel:setMarginLeft(2)
      end
      buildFn(partyContent)
      UI.Separator(partyContent)
    end

    addPartySubSection('Config', PartyAutoUI.buildConfigTab)
    addPartySubSection('Pedir', PartyAutoUI.buildPedirTab)
    addPartySubSection('Aceitar', PartyAutoUI.buildAccTab)
  else
    local infoLabel = g_ui.createWidget('BotLabel', partyContent)
    infoLabel:setText('Party Auto nao carregado ou esta ativo fora do HP/Tools.')
    infoLabel:setColor('#FFFFFF')
  end
  ensurePanelHeight(partyContent)
  refreshLayout(partyContent)
end

local function buildFriendTabContent()
  local friendTab = healingTabs.friend
  if not friendTab then return end
  local content = getTabContent(friendTab)
  if content then
    clearChildren(content)
  end
  local curarFriendsEnabled = storage.curarFriends and storage.curarFriends.enabled == true
  friendHeader = createTabHeader(friendTab, 'Curar Amigos', {
    enabled = curarFriendsEnabled,
    switchTooltip = "PT: Ativa ou desativa o sistema de cura de amigos.\nEN: Enable or disable the friend healing system.",
    onToggle = function(enabled)
      if storage.curarFriends then
        storage.curarFriends.enabled = enabled
      end
    end
  })

  local friendContent = getTabContent(friendTab)
  if friendHealerSetup then
    friendHealerSetup(friendContent)
    if storage.curarFriends and friendHeader and friendHeader.enableSwitch then
      friendHeader.enableSwitch:setOn(storage.curarFriends.enabled == true)
    end
  else
    local infoLabel = g_ui.createWidget('BotLabel', friendContent)
    infoLabel:setText('Curar Amigos nao carregado ou esta ativo fora do HP/Tools.')
    infoLabel:setColor('#FFFFFF')
  end
  ensurePanelHeight(friendContent)
  refreshLayout(friendContent)
end

rebuildHealingTabs = function()
  if not healingMainWindow or (healingMainWindow.isDestroyed and healingMainWindow:isDestroyed()) then
    return
  end
  local selectedIndex = 1
  if healingTabBar and healingTabBar.tabs and healingTabBar.currentTab then
    for i, tab in ipairs(healingTabBar.tabs) do
      if tab == healingTabBar.currentTab then
        selectedIndex = i
        break
      end
    end
  end
  buildCuraTabContent()
  buildToolsTabContent()
  if healingTabBar and healingTabBar.tabs and healingTabBar.tabs[selectedIndex] then
    healingTabBar:selectTab(healingTabBar.tabs[selectedIndex])
  end
end

healingMainWindow = g_ui.createWidget('HealingMainWindow', g_ui.getRootWidget())
healingHelpWindow = g_ui.createWidget('HealingHelpWindow', g_ui.getRootWidget())
healingHelpWindow:hide()
healingHelpButton = findWidgetByIdRecursive(healingMainWindow, 'helpButton') or healingMainWindow.helpButton
healingTabBar = healingMainWindow.tabs
if healingTabBar and healingMainWindow.content then
  healingTabBar:setContentWidget(healingMainWindow.content)
  healingTabBar:setVisible(false)
  if healingTabBar.setHeight then
    healingTabBar:setHeight(0)
  end
end
if healingMainWindow.content and healingMainWindow.content.setMarginTop then
  healingMainWindow.content:setMarginTop(0)
end

if healingHelpButton then
  healingHelpButton.onClick = function()
    openHealingHelpWindow()
  end
end

local healingHelpUi = refreshHealingHelpWindow()
if healingHelpUi and healingHelpUi.closeButton then
  healingHelpUi.closeButton.onClick = function()
    healingHelpWindow:hide()
  end
end

local function createHpTab(tabName, tabId)
  local panel = g_ui.createWidget("tPanel")
  panel:setId("tab_" .. tabId)
  if healingTabBar then
    healingTabBar:addTab(tabName, panel)
  end
  return panel
end

if storage.healingSystemEnabled == nil then
    storage.healingSystemEnabled = false
end
if storage.toolsEnabled == nil then
    storage.toolsEnabled = true
end

setHealingEnabled = function(enabled)
    storage.healingSystemEnabled = enabled == true
    syncHealingMasterSwitchState()
    if storage.healingSystemEnabled then
        wakeHealing("toggleOn")
        modules.game_textmessage.displayBroadcastMessage('HP/Tools ATIVADO', '#00FF00')
    else
        modules.game_textmessage.displayBroadcastMessage('HP/Tools DESATIVADO', '#FF0000')
    end
end

local function consumePainelHpToolsBridge()
    local bridge = storage and storage.painelDeIconesBridge
    if type(bridge) ~= "table" or bridge.hpToolsDesired == nil then
        return
    end

    local desired = bridge.hpToolsDesired == true
    bridge.hpToolsDesired = nil

    local healingState = storage.healingSystemEnabled == true
    local toolsState = storage.toolsEnabled == true
    if healingState == desired and toolsState == desired then
        syncHealingMasterSwitchState()
        return
    end

    storage.toolsEnabled = desired
    setHealingEnabled(desired)

    toolsRuntimeInitialized = false
    if rebuildHealingTabs then
        rebuildHealingTabs()
    end
end

consumePainelHpToolsBridge()
local hpToolsBridgeSyncMacro = macro(250, function()
    consumePainelHpToolsBridge()
end)

healingTabs.cura = createHpTab('Cura', 1)
healingTabs.tools = createHpTab('Tools', 2)

if healingTabBar and healingTabBar.tabs then
  local hiddenToolsTab = false
  for _, tab in ipairs(healingTabBar.tabs) do
    local tabText = nil
    if tab and tab.getText then
      local ok, value = pcall(function() return tab:getText() end)
      if ok then
        tabText = value
      end
    end
    if not tabText and tab and tab.text then
      tabText = tab.text
    end
    if tabText == 'Tools' then
      if tab.setVisible then
        tab:setVisible(false)
      elseif tab.hide then
        tab:hide()
      end
      hiddenToolsTab = true
      break
    end
  end
  if not hiddenToolsTab and healingTabBar.tabs[2] then
    local tab = healingTabBar.tabs[2]
    if tab.setVisible then
      tab:setVisible(false)
    elseif tab.hide then
      tab:hide()
    end
  end
end

rebuildHealingTabs()

if healingTabBar and healingTabBar.tabs and healingTabBar.tabs[1] then
  healingTabBar:selectTab(healingTabBar.tabs[1])
end

local mainUI = setupUI([[
Panel
  height: 20
  margin-top: 3

  Button
    id: openBtn
    text: HP/Tools
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 18
    font: verdana-11px-rounded
]])

setStandardTooltip(
  mainUI.openBtn,
  "Abre a janela de configuracao para ajustar HP/Tools, Tools e Party Auto.",
  "Open the setup window to configure HP/Tools, Tools, and Party Auto."
)
setStandardTooltip(
  healingHelpButton,
  "Abre o tutorial completo do HP/Tools.",
  "Open the full HP/Tools tutorial."
)
setStandardTooltip(
  healingHelpUi and healingHelpUi.textLabel,
  "Tutorial completo de cura, tools, party e perfis.",
  "Complete tutorial for healing, tools, party, and profiles."
)
setStandardTooltip(
  healingHelpUi and healingHelpUi.closeButton,
  "Fecha a janela de ajuda.",
  "Close the help window."
)
mainUI.openBtn.onClick = function()
    healingMainWindow:show()
    healingMainWindow:raise()
    healingMainWindow:focus()
end

if type(ImperialElfBot_IsProfileLoaded) == "function" and ImperialElfBot_IsProfileLoaded() then
  modules.game_textmessage.displayStatusMessage("ElfBot: HP/Tools loaded - OK!", "#00FF00")
end

-- ====================================
