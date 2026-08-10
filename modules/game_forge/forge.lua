forgeWindow = nil
selectedItemFusionRadio = nil
resultWindow = nil
selectedConvergenceFusionRadio = nil
selectedItemFusionConvectionRadio = nil
local protocol = runinsandbox("forgeprotocol")
local forgeDebugEnabled = false
local forgeItemTiers = setmetatable({}, { __mode = 'k' })
local forgeAnimationEvent = nil
local forgeResultLabelEvent = nil

local function cancelForgeEvents()
  if forgeAnimationEvent then
    removeEvent(forgeAnimationEvent)
    forgeAnimationEvent = nil
  end
  if forgeResultLabelEvent then
    removeEvent(forgeResultLabelEvent)
    forgeResultLabelEvent = nil
  end
  ForgeSystem.inForgeFusion = false
end

local function scheduleForgeAnimation(callback, delay)
  if forgeAnimationEvent then
    removeEvent(forgeAnimationEvent)
  end
  forgeAnimationEvent = scheduleEvent(function()
    forgeAnimationEvent = nil
    callback()
  end, delay)
end

local function debugForge(message)
end

local function getForgeItemTier(item)
  if not item then
    return 0
  end

  if item.getTier then
    local ok, tier = pcall(function() return item:getTier() end)
    if ok and tier then
      return tonumber(tier) or 0
    end
  end

  return forgeItemTiers[item] or 0
end

local function createForgeItem(itemId, tier)
  local item = Item.create(itemId, 1)
  local itemTier = tonumber(tier) or 0
  forgeItemTiers[item] = itemTier

  if item.setTier then
    pcall(function() item:setTier(itemTier) end)
  end

  return item
end

local function setupForgeItemBox(widget, item, count)
  local amount = tonumber(count) or 0
  widget.item:setItem(item)
  widget.item:setItemCount(amount)
  widget.forgeCount = amount

  local countLabel = widget:getChildById('count')
  if countLabel then
    countLabel:setText(tostring(amount))
    countLabel:setVisible(amount > 1)
  end
end

local function getForgeWidgetCount(widget)
  if widget and widget.forgeCount then
    return tonumber(widget.forgeCount) or 0
  end

  if widget and widget.item and widget.item.getItemCount then
    return tonumber(widget.item:getItemCount()) or 0
  end

  return 0
end

local function setForgeItemShader(widget, shader)
  if widget and widget.setItemShader then
    widget:setItemShader(shader or "")
  end
end

ForgeSystem = {}
ForgeSystem.__index = ForgeSystem

ForgeSystem.classPrice = {}
ForgeSystem.transferMap = {}
ForgeSystem.fusionPrices = {}
ForgeSystem.transferPrices = {}
ForgeSystem.baseMultipier = 0
ForgeSystem.slivers = 0
ForgeSystem.totalSlivers = 0
ForgeSystem.dustCost = 0
ForgeSystem.dustPrice = 0
ForgeSystem.maxDust = 0
ForgeSystem.dustFusion = 0
ForgeSystem.convergenceDustFusion = 0
ForgeSystem.dustTransfer = 0
ForgeSystem.convergenceDustTransfer = 0
ForgeSystem.success = 0
ForgeSystem.improveRateSuccess = 0
ForgeSystem.tierLoss = 0
ForgeSystem.inForgeFusion = false
ForgeSystem.fusionPrice = 0
ForgeSystem.exaltedCoreCount = 0
ForgeSystem.fusionItemCount = 0
ForgeSystem.fusionSelectedItem = 0
ForgeSystem.fusionTier = 0
ForgeSystem.rateSuccessActive = false
ForgeSystem.tierLossActive = false

ForgeSystem.fusionData = {}
ForgeSystem.fusionConvergenceData = {}
ForgeSystem.transferData = {}
ForgeSystem.transferConvergenceData = {}
ForgeSystem.maxPlayerDust = 100
ForgeSystem.sideButton = false

ResourceBank = 0
ResourceInventory = 1
ResourceInventary = ResourceInventory
ResourceForgeDust = 20
ResourceForgeSlivers = 21
ResourceForgeExaltedCore = 22

local resources = {
  [ResourceBank] = 0,
  [ResourceInventory] = 0,
  [ResourceForgeDust] = 0,
  [ResourceForgeSlivers] = 0,
  [ResourceForgeExaltedCore] = 0
}

local function getResource(resourceType)
  return resources[resourceType] or 0
end

local function getTotalMoney()
  return getResource(ResourceBank) + getResource(ResourceInventory)
end

local function formatMoney(value, separator)
  separator = separator or ","
  value = math.floor(tonumber(value) or 0)

  local sign = ""
  if value < 0 then
    sign = "-"
    value = math.abs(value)
  end

  local formatted = tostring(value)
  while true do
    local result, count = formatted:gsub("^(%d+)(%d%d%d)", "%1" .. separator .. "%2")
    formatted = result
    if count == 0 then
      break
    end
  end

  return sign .. formatted
end

local function setForgeButtonOn(on)
  if not modules.game_interface then
    return
  end

  local rightPanel = modules.game_interface.getRightPanel()
  if not rightPanel then
    return
  end

  local button = rightPanel:recursiveGetChildById("forgeButton")
  if button then
    button:setOn(on)
  end
end

local function updateBalanceLabels()
  if not forgeWindow then
    return
  end

  local function setLabelText(panelId, labelId, value)
    local panel = forgeWindow:recursiveGetChildById(panelId)
    if not panel then
      return
    end

    local label = panel:recursiveGetChildById(labelId)
    if label then
      label:setText(value)
    end
  end

  setLabelText('sliversPanel', 'slivers', getResource(ResourceForgeSlivers))
  setLabelText('exaltedcorePanel', 'exaltedcore', getResource(ResourceForgeExaltedCore))
  setLabelText('dustPanel', 'dust', getResource(ResourceForgeDust) .. '/' .. ForgeSystem.maxPlayerDust)
  setLabelText('moneyPanel', 'gold', formatMoney(getTotalMoney(), ","))
end

function getItemCategoryBySlot(itemId)
  return 0
end

function setStringColor(table, text, color)
  table[#table + 1] = { text, color }
end

local function setColoredTextOrFallback(widget, coloredText, fallbackText, fallbackColor)
  if not widget then
    return
  end

  if widget.setColoredText and coloredText then
    pcall(function()
      widget:setColoredText(coloredText)
    end)
  end

  if fallbackText then
    widget:setText(fallbackText)
  end
  if fallbackColor then
    widget:setColor(fallbackColor)
  end
end

local function bindButtonClick(widget, callback)
  if widget then
    widget.onClick = callback
  end
end

local function ensureForgeWindow()
  if forgeWindow and not forgeWindow:isDestroyed() then
    if not resultWindow or resultWindow:isDestroyed() then
      resultWindow = g_ui.displayUI('styles/result')
      if resultWindow then
        resultWindow:hide()
      end
    end
    return forgeWindow
  end

  forgeWindow = g_ui.displayUI('forge')
  if not forgeWindow then
    return nil
  end
  forgeWindow:hide()

  resultWindow = g_ui.displayUI('styles/result')
  if resultWindow then
    resultWindow:hide()
  end
  return forgeWindow
end

function init()
  connect(g_game, {
    onGameStart = onGameStart,
    onResourceBalance = onResourceBalance,
    onGameEnd = offlineForge,
  })
  protocol.initProtocol()
end

function onGameStart()
  cancelForgeEvents()
  if forgeWindow then
    forgeWindow:hide()
  end
  if resultWindow then
    resultWindow:hide()
  end
  ForgeSystem.sideButton = false
  ForgeSystem.inForgeFusion = false
  setForgeButtonOn(false)
end

function terminate()
  cancelForgeEvents()
  protocol.terminateProtocol()

  if selectedItemFusionRadio then
    selectedItemFusionRadio:destroy()
    selectedItemFusionRadio = nil
  end
  if selectedConvergenceFusionRadio then
    selectedConvergenceFusionRadio:destroy()
    selectedConvergenceFusionRadio = nil
  end
  if selectedItemFusionConvectionRadio then
    selectedItemFusionConvectionRadio:destroy()
    selectedItemFusionConvectionRadio = nil
  end
  if forgeWindow then
    forgeWindow:destroy()
    forgeWindow = nil
  end
  if resultWindow then
    resultWindow:destroy()
    resultWindow = nil
  end
  disconnect(g_game, {
    onGameStart = onGameStart,
    onResourceBalance = onResourceBalance,
    onGameEnd = offlineForge,
  })
end

function toggle()
  if not ensureForgeWindow() then
    return
  end
  if forgeWindow:isVisible() then
    hideForge()
    protocol.ForgeProtocol.sendClose()
  else
    ForgeSystem.sideButton = true
    protocol.ForgeProtocol.sendOpen()
    show()
  end
end

function hideForge()
  if forgeWindow then
    forgeWindow:hide()
    ForgeSystem.sideButton = false
    setForgeButtonOn(false)
  end
end

function show()
  if not ensureForgeWindow() then
    return
  end
  if not forgeWindow:isVisible() then
    forgeWindow:show(true)
    forgeWindow:raise()
    forgeWindow:focus()
  end

  local contentPanel = forgeWindow:getChildById('contentPanel')
  if contentPanel then
    local hasActivePanel = false
    for _, panelId in ipairs({ 'fusionPanel', 'transferPanel', 'conversionPanel', 'historyPanel', 'resultPanel' }) do
      local panel = contentPanel:getChildById(panelId)
      if panel and panel:isVisible() then
        hasActivePanel = true
        break
      end
    end
    if not hasActivePanel then
      loadMenu('fusionPanel')
    end
  end

  updateBalanceLabels()
  setForgeButtonOn(true)
end

function ForgeSystem.show()
  show()
end

function loadMenu(menuId)
  if not forgeWindow then
    print("Erro: forgeWindow não está inicializado")
    return
  end

  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado dentro de loadMenu")
    return
  end

  local fusionPanel = contentPanel:getChildById('fusionPanel')
  local transferPanel = contentPanel:getChildById('transferPanel')
  local conversionPanel = contentPanel:getChildById('conversionPanel')
  local historyPanel = contentPanel:getChildById('historyPanel')
  local resultPanel = contentPanel:getChildById('resultPanel')

  if not fusionPanel then print("Erro: fusionPanel não encontrado") end
  if not transferPanel then print("Erro: transferPanel não encontrado") end
  if not conversionPanel then print("Erro: conversionPanel não encontrado") end
  if not historyPanel then print("Erro: historyPanel não encontrado") end
  if not resultPanel then print("Erro: resultPanel não encontrado") end

  if fusionPanel then fusionPanel:setVisible(false) end
  if transferPanel then transferPanel:setVisible(false) end
  if conversionPanel then conversionPanel:setVisible(false) end
  if historyPanel then historyPanel:setVisible(false) end
  if resultPanel then resultPanel:setVisible(false) end

  local panelButtons = forgeWindow:getChildById('panelButtons')
  if not panelButtons then
    print("Erro: panelButtons não encontrado dentro de loadMenu")
    return
  end

  local fusionMenuButton = panelButtons:getChildById('fusionButton')
  local transferMenuButton = panelButtons:getChildById('transferButton')
  local conversionMenuButton = panelButtons:getChildById('conversionButton')
  local historyMenuButton = panelButtons:getChildById('historyButton')

  if fusionMenuButton then fusionMenuButton:setChecked(false) end
  if transferMenuButton then transferMenuButton:setChecked(false) end
  if conversionMenuButton then conversionMenuButton:setChecked(false) end
  if historyMenuButton then historyMenuButton:setChecked(false) end

  if menuId == 'fusionPanel' and fusionPanel then
    fusionPanel:setVisible(true)
    ForgeSystem.updateFusion()
    if fusionMenuButton then fusionMenuButton:setChecked(true) end
  elseif menuId == 'transferPanel' and transferPanel then
    transferPanel:setVisible(true)
    ForgeSystem.updateTransfer()
    if transferMenuButton then transferMenuButton:setChecked(true) end
  elseif menuId == 'conversionPanel' and conversionPanel then
    conversionPanel:setVisible(true)
    ForgeSystem.updateConversion()
    if conversionMenuButton then conversionMenuButton:setChecked(true) end
  elseif menuId == 'historyPanel' and historyPanel then
    historyPanel:setVisible(true)
    if historyMenuButton then historyMenuButton:setChecked(true) end
    protocol.ForgeProtocol.sendHistory()
  elseif menuId == 'resultPanel' and resultPanel then
    resultPanel:setVisible(true)
  end

  updateBalanceLabels()
end

function offlineForge()
  cancelForgeEvents()
  if forgeWindow then
    forgeWindow:hide()
    ForgeSystem.clearFusion()
    ForgeSystem.clearTransfer()

    ForgeSystem.fusionData = {}
    ForgeSystem.fusionConvergenceData = {}
    ForgeSystem.transferData = {}
    ForgeSystem.transferConvergenceData = {}
  end
  if resultWindow then
    resultWindow:hide()
  end
  ForgeSystem.sideButton = false
  ForgeSystem.inForgeFusion = false
  setForgeButtonOn(false)
end

function ForgeSystem.setResourceBalances(balances)
  for resourceType, amount in pairs(balances or {}) do
    resources[resourceType] = tonumber(amount) or 0
  end

  debugForge(
    "apply balances bank=" .. tostring(resources[ResourceBank]) ..
    " inventory=" .. tostring(resources[ResourceInventory]) ..
    " dust=" .. tostring(resources[ResourceForgeDust]) ..
    " slivers=" .. tostring(resources[ResourceForgeSlivers]) ..
    " cores=" .. tostring(resources[ResourceForgeExaltedCore])
  )
  updateBalanceLabels()
end

function onResourceBalance(type, amount)
  ForgeSystem.setResourceBalances({ [type] = amount })

  if forgeWindow and forgeWindow:isVisible() then
    ForgeSystem.checkFusionButton()
    ForgeSystem.checkFusionConversionButton()
    ForgeSystem.checkFusionButtons()
    ForgeSystem.checkTransferButton()
    ForgeSystem.checkTransferConvergenceButton()
    ForgeSystem.updateConversion()
  end
end

function ForgeSystem.init(classPrice, transferMap, fusionPrices, transferPrices, baseMultipier, slivers, totalSlivers, dustCost, dustPrice, maxDust, dustFusion, convergenceDustFusion, dustTransfer, convergenceDustTransfer, success, improveRateSuccess, tierLoss)
  if not ensureForgeWindow() then
    return
  end

  ForgeSystem.classPrice = classPrice
  ForgeSystem.transferMap = transferMap
  ForgeSystem.fusionPrices = fusionPrices
  ForgeSystem.transferPrices = transferPrices
  ForgeSystem.baseMultipier = baseMultipier
  ForgeSystem.slivers = slivers
  ForgeSystem.totalSlivers = totalSlivers
  ForgeSystem.dustCost = dustCost
  ForgeSystem.dustPrice = dustPrice
  ForgeSystem.maxPlayerDust = dustPrice
  ForgeSystem.maxDust = maxDust
  ForgeSystem.dustFusion = dustFusion
  ForgeSystem.convergenceDustFusion = convergenceDustFusion
  ForgeSystem.dustTransfer = dustTransfer
  ForgeSystem.convergenceDustTransfer = convergenceDustTransfer
  ForgeSystem.success = success
  ForgeSystem.improveRateSuccess = improveRateSuccess
  ForgeSystem.tierLoss = tierLoss

  ForgeSystem.inForgeFusion = false

  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.init")
    return
  end

  local fusionPanel = contentPanel:getChildById('fusionPanel')
  local transferPanel = contentPanel:getChildById('transferPanel')
  local conversionPanel = contentPanel:getChildById('conversionPanel')

  if fusionPanel then
    fusionPanel:getChildById('itemsFusion'):getChildById('dustPanel').item:setItemId(37160)
    local convergencePanel = fusionPanel:getChildById('converFusion'):getChildById('convergencePanel')
    convergencePanel:getChildById('dustPanel').item:setItemId(37160)
    convergencePanel:getChildById('dustCount').dustamount:setText(ForgeSystem.convergenceDustFusion)
    fusionPanel:getChildById('itemsFusion'):getChildById('dustCount').dustamount:setText(ForgeSystem.dustFusion)
    fusionPanel:getChildById('itemsFusion').improveRateSuccessButton:setText('Improve to '.. (ForgeSystem.success + ForgeSystem.improveRateSuccess) ..'%')
  end

  if transferPanel then
    transferPanel:getChildById('itemsFusion'):getChildById('itemPanel').item:setItemId(0)
    transferPanel:getChildById('itemsFusion'):getChildById('itemPanel').item.questionMark:setVisible(true)
    transferPanel:getChildById('itemsFusion'):getChildById('itemCount').value:setText("0 / 1")
    transferPanel:getChildById('itemsFusion'):getChildById('dustCount').dustamount:setText("0")
    transferPanel:getChildById('itemsFusion'):getChildById('dustCount').dustamount:setColor("#d33c3c")

    transferPanel:getChildById('itemsFusion'):getChildById('dustPanel').item:setItemId(37160)
    transferPanel:getChildById('itemsFusion'):getChildById('dustCount').dustamount:setText(ForgeSystem.dustTransfer)
    transferPanel:getChildById('itemsFusion'):getChildById('dustCount').dustamount:setColor("#d33c3c")

    transferPanel:getChildById('itemsFusion'):getChildById('exaltedPanel').item:setItemId(37110)
    transferPanel:getChildById('itemsFusion'):getChildById('exaltedCount').amount:setText("???")
    transferPanel:getChildById('itemsFusion'):getChildById('exaltedCount').amount:setColor("#d33c3c")

    transferPanel:getChildById('converFusion'):getChildById('itemPanel').item:setItemId(0)
    transferPanel:getChildById('converFusion'):getChildById('itemCount').value:setText("0 / 1")
    transferPanel:getChildById('converFusion'):getChildById('dustCount').dustamount:setText("0")
    transferPanel:getChildById('converFusion'):getChildById('dustCount').dustamount:setColor("#d33c3c")

    transferPanel:getChildById('converFusion'):getChildById('dustPanel').item:setItemId(37160)
    transferPanel:getChildById('converFusion'):getChildById('dustCount').dustamount:setText(ForgeSystem.convergenceDustTransfer)
    transferPanel:getChildById('converFusion'):getChildById('dustCount').dustamount:setColor("#d33c3c")

    transferPanel:getChildById('converFusion'):getChildById('exaltedPanel').item:setItemId(37110)
    transferPanel:getChildById('converFusion'):getChildById('exaltedCount').amount:setText("???")
    transferPanel:getChildById('converFusion'):getChildById('exaltedCount').amount:setColor("#d33c3c")
  end

  if conversionPanel then
    conversionPanel:getChildById('windowConvertDust'):getChildById('itemPanel').item:setItemId(37160)
    conversionPanel:getChildById('windowConvertDust'):getChildById('itemCount').amount:setText(ForgeSystem.slivers * ForgeSystem.baseMultipier)
    conversionPanel:getChildById('windowConvertDust'):getChildById('itemCount').amount:setColor("#d33c3c")
    conversionPanel:getChildById('windowConvertDust'):getChildById('dustButton').item:setItemId(37109)
    conversionPanel:getChildById('windowConvertDust').generateSlivers:setText("Generate ".. ForgeSystem.slivers)
    bindButtonClick(conversionPanel:getChildById('windowConvertDust'):getChildById('dustButton'), function() ForgeSystem.sendForgeConverter(2) end)

    conversionPanel:getChildById('windowConvertSlivers'):getChildById('itemPanel').item:setItemId(37109)
    conversionPanel:getChildById('windowConvertSlivers'):getChildById('itemCount').amount:setText(ForgeSystem.totalSlivers)
    conversionPanel:getChildById('windowConvertSlivers'):getChildById('itemCount').amount:setColor("#d33c3c")
    conversionPanel:getChildById('windowConvertSlivers'):getChildById('sliverButton').item:setItemId(37110)
    bindButtonClick(conversionPanel:getChildById('windowConvertSlivers'):getChildById('sliverButton'), function() ForgeSystem.sendForgeConverter(3) end)

    local totalDustRequired = ForgeSystem.maxPlayerDust - 75
    conversionPanel:getChildById('windowIncreaseDustLimit'):getChildById('itemPanel').item:setItemId(37160)
    conversionPanel:getChildById('windowIncreaseDustLimit'):getChildById('itemCount').amount:setText(totalDustRequired)
    conversionPanel:getChildById('windowIncreaseDustLimit'):getChildById('itemCount').amount:setColor("#d33c3c")
    conversionPanel:getChildById('windowIncreaseDustLimit'):getChildById('increaseButton').item:setItemId(37160)
    conversionPanel:getChildById('windowIncreaseDustLimit'):getChildById('increaseButton').itemRight:setItemId(37160)
    conversionPanel:getChildById('windowIncreaseDustLimit').baseText:setText('Raise limit from')
    conversionPanel:getChildById('windowIncreaseDustLimit').currentDust:setVisible(true)
    conversionPanel:getChildById('windowIncreaseDustLimit').img1:setVisible(true)
    conversionPanel:getChildById('windowIncreaseDustLimit').img2:setVisible(true)
    conversionPanel:getChildById('windowIncreaseDustLimit').currentDust:setText('100')
    conversionPanel:getChildById('windowIncreaseDustLimit').nextDust:setVisible(true)
    conversionPanel:getChildById('windowIncreaseDustLimit').nextDust:setText('to 101')
    bindButtonClick(conversionPanel:getChildById('windowIncreaseDustLimit'):getChildById('increaseButton'), function() ForgeSystem.sendForgeConverter(4) end)
  end
  updateBalanceLabels()
end

function ForgeSystem.onForgeData(fusionData, fusionConvergenceData, transferData, transferConvergenceData, maxPlayerDust)
  if not ensureForgeWindow() then
    return
  end

  debugForge(
    "apply data maxDust=" .. tostring(maxPlayerDust) ..
    " fusion=" .. tostring(#fusionData) ..
    " fusionConv=" .. tostring(#fusionConvergenceData) ..
    " transfer=" .. tostring(#transferData) ..
    " transferConv=" .. tostring(#transferConvergenceData)
  )
  ForgeSystem.fusionData = fusionData
  ForgeSystem.fusionConvergenceData = fusionConvergenceData
  ForgeSystem.transferData = transferData
  ForgeSystem.transferConvergenceData = transferConvergenceData
  ForgeSystem.maxPlayerDust = maxPlayerDust
  ForgeSystem.sideButton = false
  updateBalanceLabels()

  local wasVisible = forgeWindow:isVisible()
  local resultVisible = resultWindow and resultWindow:isVisible()
  if not wasVisible and not ForgeSystem.inForgeFusion and not resultVisible then
    show()
  end

  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.onForgeData")
    return
  end

  local fusionPanel = contentPanel:getChildById('fusionPanel')
  local transferPanel = contentPanel:getChildById('transferPanel')

  if fusionPanel then
    fusionPanel:getChildById('itemFusionPanel'):getChildById('mindPanel').convergenceCheckBox:setChecked(false)
  end
  if transferPanel then
    transferPanel:getChildById('itemTransferPanel'):getChildById('mindPanel').convergenceCheckBox:setChecked(false)
  end
  if forgeWindow:isVisible() and not ForgeSystem.inForgeFusion and not resultVisible then
    if not wasVisible then
      loadMenu('fusionPanel')
    elseif fusionPanel and fusionPanel:isVisible() then
      ForgeSystem.updateFusion()
    elseif transferPanel and transferPanel:isVisible() then
      ForgeSystem.updateTransfer()
    else
      ForgeSystem.updateConversion()
    end
  end
end

function ForgeSystem.updateFusion()
  ForgeSystem.clearFusion()
  ForgeSystem.clearTransfer()
  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.updateFusion")
    return
  end

  local fusionPanel = contentPanel:getChildById('fusionPanel')
  if not fusionPanel then
    print("Erro: fusionPanel não encontrado em updateFusion")
    return
  end

  local itemPanel = fusionPanel:getChildById('itemFusionPanel'):getChildById('itemsPanel')
  fusionPanel:getChildById('itemFusionPanel'):getChildById('itemsPanel'):destroyChildren()

  if selectedItemFusionRadio then
    selectedItemFusionRadio:destroy()
  end

  selectedItemFusionRadio = UIRadioGroup.create()
  selectedItemFusionRadio:clearSelected()
  connect(selectedItemFusionRadio, { onSelectionChange = onSelectionChange })

  local data = ForgeSystem.fusionData

  if fusionPanel:getChildById('converFusion'):isVisible() then
    data = ForgeSystem.fusionConvergenceData
  end

  for _, fusion in pairs(data) do
    local widget = g_ui.createWidget('FusionItemBox', itemPanel)

    local itemPtr = createForgeItem(fusion[1], fusion[2])

    setupForgeItemBox(widget, itemPtr, fusion[3])
    widget.itemPtr = itemPtr
    widget.classification = fusion[5] or 0
    widget.category = fusion[6] or 0

    selectedItemFusionRadio:addWidget(widget)
  end
end

local function ConfigureFusionConversionPanel(selectedWidget)
  local itemPtr = selectedWidget.itemPtr
  local itemCount = getForgeWidgetCount(selectedWidget)
  local itemTier = getForgeItemTier(itemPtr)

  ForgeSystem.fusionItem = itemPtr
  ForgeSystem.fusionItemCount = itemCount

  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ConfigureFusionConversionPanel")
    return
  end

  local fusionPanel = contentPanel:getChildById('fusionPanel')
  if not fusionPanel then
    print("Erro: fusionPanel não encontrado em ConfigureFusionConversionPanel")
    return
  end

  local nextItem = fusionPanel:getChildById('itemFusionPanel'):getChildById('nextItemPanel').nextItem
  nextItem:setItemId(itemPtr:getId())
  setForgeItemShader(nextItem, "item_black")
  nextItem.questionMark:setVisible(false)
  nextItem.tierflags:setVisible(true)
  nextItem.tierflags:setImageClip(itemTier * 18 .. " 0 18 16")

  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').item:setItemId(itemPtr:getId())
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').item.questionMark:setVisible(false)
  if itemTier > 0 then
    fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').item.tierflags:setImageClip((itemTier - 1) * 9 .. " 0 9 8")
    fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').item.tierflags:setVisible(true)
  else
    fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').item.tierflags:setVisible(false)
  end

  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').itemTo:setItemId(itemPtr:getId())
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').itemTo.questionMark:setVisible(false)
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').itemTo.tierflags:setVisible(true)
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').itemTo.tierflags:setImageClip((itemTier) * 9 .. " 0 9 8")

  local data = ForgeSystem.fusionConvergenceData
  local itemsConvergencePanel = fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('itemsConvergencePanel')

  itemsConvergencePanel:destroyChildren()

  if selectedItemFusionConvectionRadio then
    selectedItemFusionConvectionRadio:destroy()
  end

  selectedItemFusionConvectionRadio = UIRadioGroup.create()
  ForgeSystem.fusionSelectedItem = 0

  selectedItemFusionConvectionRadio:clearSelected()
  connect(selectedItemFusionConvectionRadio, { onSelectionChange = onSelectionForgeConvection })

  for _, fusion in pairs(data) do
    local firstCategory = fusion[6] or getItemCategoryBySlot(fusion[1])
    local secondCategory = selectedWidget.category or getItemCategoryBySlot(itemPtr:getId())

    if (firstCategory == -1 and secondCategory == -1) then
      goto continue
    end

    if firstCategory ~= secondCategory then
      goto continue
    end

    local widget = g_ui.createWidget('FusionItemBox', itemsConvergencePanel)
    local itemPtr = createForgeItem(fusion[1], fusion[2])

    setupForgeItemBox(widget, itemPtr, fusion[3])
    widget.itemPtr = itemPtr
    widget.classification = fusion[5] or 0
    widget.category = fusion[6] or 0

    selectedItemFusionConvectionRadio:addWidget(widget)
    ::continue::
  end

  local dust = getResource(ResourceForgeDust)
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('dustCount').dustamount:setColor(dust >= ForgeSystem.convergenceDustFusion and "#FFFFFF" or "#d33c3c")

  local price = ForgeSystem.fusionPrices[itemTier] or 0

  ForgeSystem.fusionPrice = price
  local messageColor = {}
  setStringColor(messageColor, formatMoney(price, ","), (getTotalMoney() >= ForgeSystem.fusionPrice and "#FFFFFF" or "#d33c3c"))
  setStringColor(messageColor, " $", "#c0c0c0")
  setColoredTextOrFallback(fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('moneyPanel').gold, messageColor, formatMoney(price, ",") .. " $", getTotalMoney() >= ForgeSystem.fusionPrice and "#FFFFFF" or "#d33c3c")

  ForgeSystem.checkFusionConversionButton()
end

local function ConfigureFusionPanel(selectedWidget)
  local itemPtr = selectedWidget.itemPtr
  local itemCount = getForgeWidgetCount(selectedWidget)
  local itemTier = getForgeItemTier(itemPtr)

  ForgeSystem.fusionItem = itemPtr
  ForgeSystem.fusionItemCount = itemCount

  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ConfigureFusionPanel")
    return
  end

  local fusionPanel = contentPanel:getChildById('fusionPanel')
  if not fusionPanel then
    print("Erro: fusionPanel não encontrado em ConfigureFusionPanel")
    return
  end

  local nextItem = fusionPanel:getChildById('itemFusionPanel'):getChildById('nextItemPanel').nextItem
  nextItem:setItemId(itemPtr:getId())
  setForgeItemShader(nextItem, "item_black")
  nextItem.questionMark:setVisible(false)
  nextItem.tierflags:setVisible(true)
  nextItem.tierflags:setImageClip(itemTier * 18 .. " 0 18 16")

  fusionPanel:getChildById('itemsFusion'):getChildById('itemPanel').item:setItemId(itemPtr:getId())
  fusionPanel:getChildById('itemsFusion'):getChildById('itemPanel').questionMark:setVisible(false)
  fusionPanel:getChildById('itemsFusion'):getChildById('itemCount').value:setText(itemCount .. " / 1")
  fusionPanel:getChildById('itemsFusion'):getChildById('itemCount').value:setColor(itemCount > 1 and "#FFFFFF" or "#d33c3c")

  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').item:setItemId(itemPtr:getId())
  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').item.questionMark:setVisible(false)
  if itemTier > 0 then
    fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').item.tierflags:setImageClip((itemTier - 1) * 9 .. " 0 9 8")
    fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').item.tierflags:setVisible(true)
  else
    fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').item.tierflags:setVisible(false)
  end

  local dust = getResource(ResourceForgeDust)
  fusionPanel:getChildById('itemsFusion'):getChildById('dustCount').dustamount:setColor(dust >= ForgeSystem.dustFusion and "#FFFFFF" or "#d33c3c")

  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').itemTo:setItemId(itemPtr:getId())
  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').itemTo.questionMark:setVisible(false)
  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').itemTo.tierflags:setImageClip(itemTier * 9 .. " 0 9 8")
  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').itemTo.tierflags:setVisible(true)

  local classification = selectedWidget.classification or 0
  local price = ForgeSystem.classPrice[classification] and ForgeSystem.classPrice[classification][2][itemTier] or 0

  ForgeSystem.fusionPrice = price
  local messageColor = {}
  setStringColor(messageColor, formatMoney(price, ","), (getTotalMoney() >= ForgeSystem.fusionPrice and "#FFFFFF" or "#d33c3c"))
  setStringColor(messageColor, " $", "#c0c0c0")
  setColoredTextOrFallback(fusionPanel:getChildById('itemsFusion'):getChildById('moneyPanel').gold, messageColor, formatMoney(price, ",") .. " $", getTotalMoney() >= ForgeSystem.fusionPrice and "#FFFFFF" or "#d33c3c")

  ForgeSystem.checkFusionButton()
  ForgeSystem.checkFusionButtons()
  ForgeSystem.checkFusionLabels()
end

function ForgeSystem.checkFusionButton()
  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.checkFusionButton")
    return
  end

  local fusionPanel = contentPanel:getChildById('fusionPanel')
  if not fusionPanel then
    print("Erro: fusionPanel não encontrado em checkFusionButton")
    return
  end
  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').locked:setVisible(not ForgeSystem.checkFusionState())
  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton'):setEnabled(ForgeSystem.checkFusionState())
end

function ForgeSystem.checkFusionConversionButton()
  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.checkFusionConversionButton")
    return
  end

  local fusionPanel = contentPanel:getChildById('fusionPanel')
  if not fusionPanel then
    print("Erro: fusionPanel não encontrado em checkFusionConversionButton")
    return
  end
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').locked:setVisible(not ForgeSystem.checkFusionConversionState())
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton'):setEnabled(ForgeSystem.checkFusionConversionState())
end

function ForgeSystem.checkFusionButtons()
  local player = g_game.getLocalPlayer()
  if not player then
    print("Erro: player é nil em checkFusionButtons")
    return
  end

  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.checkFusionButtons")
    return
  end

  local fusionPanel = contentPanel:getChildById('fusionPanel')
  if not fusionPanel then
    print("Erro: fusionPanel não encontrado em checkFusionButtons")
    return
  end

  local exaltedCore = getResource(ResourceForgeExaltedCore)
  if ForgeSystem.rateSuccessActive then
    exaltedCore = exaltedCore - 1
    fusionPanel:getChildById('itemsFusion').improveRateSuccessButton:setEnabled(true)
    fusionPanel:getChildById('itemsFusion'):getChildById('improveRateSuccessPanel').exaltedcoreamount:setColor("#FFFFFF")
  end
  if ForgeSystem.tierLossActive then
    exaltedCore = exaltedCore - 1
    fusionPanel:getChildById('itemsFusion').tierLossButton:setEnabled(true)
    fusionPanel:getChildById('itemsFusion'):getChildById('tierLossPanel').exaltedcoreamount:setColor("#FFFFFF")
  end

  if exaltedCore < 1 then
    if not ForgeSystem.rateSuccessActive then
      fusionPanel:getChildById('itemsFusion').improveRateSuccessButton:setEnabled(false)
      fusionPanel:getChildById('itemsFusion'):getChildById('improveRateSuccessPanel').exaltedcoreamount:setColor("#d33c3c")
    end
    if not ForgeSystem.tierLossActive then
      fusionPanel:getChildById('itemsFusion').tierLossButton:setEnabled(false)
      fusionPanel:getChildById('itemsFusion'):getChildById('tierLossPanel').exaltedcoreamount:setColor("#d33c3c")
    end
  else
    if not ForgeSystem.rateSuccessActive then
      fusionPanel:getChildById('itemsFusion').improveRateSuccessButton:setEnabled(true)
      fusionPanel:getChildById('itemsFusion'):getChildById('improveRateSuccessPanel').exaltedcoreamount:setColor("#FFFFFF")
    end
    if not ForgeSystem.tierLossActive then
      fusionPanel:getChildById('itemsFusion').tierLossButton:setEnabled(true)
      fusionPanel:getChildById('itemsFusion'):getChildById('tierLossPanel').exaltedcoreamount:setColor("#FFFFFF")
    end
  end
end

function ForgeSystem.checkFusionConversionState()
  local player = g_game.getLocalPlayer()
  if not player then
    return false
  end

  local hasDust = getResource(ResourceForgeDust) >= ForgeSystem.convergenceDustFusion
  local hasMoney = getTotalMoney() >= ForgeSystem.fusionPrice

  return hasDust and hasMoney and ForgeSystem.fusionSelectedItem ~= 0 and not ForgeSystem.sideButton
end

function ForgeSystem.checkFusionState()
  local player = g_game.getLocalPlayer()
  if not player then
    return false
  end
  local hasItemCount = (ForgeSystem.fusionItemCount or 0) >= 2
  local hasDust = getResource(ResourceForgeDust) >= ForgeSystem.dustFusion
  local hasMoney = getTotalMoney() >= ForgeSystem.fusionPrice

  return hasItemCount and hasDust and hasMoney and not ForgeSystem.sideButton
end

function ForgeSystem.checkFusionLabels()
  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.checkFusionLabels")
    return
  end

  local fusionPanel = contentPanel:getChildById('fusionPanel')
  if not fusionPanel then
    print("Erro: fusionPanel não encontrado em checkFusionLabels")
    return
  end

  fusionPanel:getChildById('itemsFusion').successLabel:setText(ForgeSystem.rateSuccessActive and (ForgeSystem.success + ForgeSystem.improveRateSuccess) .. "%" or "50%")
  fusionPanel:getChildById('itemsFusion').successLabel:setColor(ForgeSystem.rateSuccessActive and "#44ad25" or "#d33c3c")

  fusionPanel:getChildById('itemsFusion').tierLossLabel:setText(ForgeSystem.tierLossActive and ForgeSystem.tierLoss .. "%" or "100%")
  fusionPanel:getChildById('itemsFusion').tierLossLabel:setColor(ForgeSystem.tierLossActive and "#44ad25" or "#d33c3c")
end

function ForgeSystem.clearFusion()
  ForgeSystem.fusionItem = nil
  ForgeSystem.fusionItemCount = 0
  ForgeSystem.exaltedCoreCount = 0
  ForgeSystem.fusionSelectedItem = 0
  ForgeSystem.rateSuccessActive = false
  ForgeSystem.tierLossActive = false
  ForgeSystem.fusionTier = 0

  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.clearFusion")
    return
  end

  local fusionPanel = contentPanel:getChildById('fusionPanel')
  if not fusionPanel then
    print("Erro: fusionPanel não encontrado em clearFusion")
    return
  end

  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('itemsConvergencePanel'):destroyChildren()
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('dustCount').dustamount:setColor("#d33c3c")
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton'):setEnabled(false)
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').locked:setVisible(true)
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').item:setItemId(0)
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').item.tierflags:setVisible(false)
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').item.questionMark:setVisible(true)
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').itemTo:setItemId(0)
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').itemTo.tierflags:setVisible(false)
  fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('fusionButton').itemTo.questionMark:setVisible(true)

  local messageColor = {}
  setStringColor(messageColor, "???", "#d33c3c")
  setStringColor(messageColor, " $", "#c0c0c0")
  setColoredTextOrFallback(fusionPanel:getChildById('converFusion'):getChildById('convergencePanel'):getChildById('moneyPanel').gold, messageColor, "??? $", "#d33c3c")

  local nextItem = fusionPanel:getChildById('itemFusionPanel'):getChildById('nextItemPanel').nextItem
  nextItem:setItemId(0)
  setForgeItemShader(nextItem, "")
  nextItem.tierflags:setVisible(false)
  nextItem.questionMark:setVisible(true)

  fusionPanel:getChildById('itemsFusion'):getChildById('itemPanel').item:setItemId(0)
  fusionPanel:getChildById('itemsFusion'):getChildById('itemPanel').questionMark:setVisible(true)
  fusionPanel:getChildById('itemsFusion'):getChildById('itemCount').value:setText("0 / 1")
  fusionPanel:getChildById('itemsFusion'):getChildById('itemCount').value:setColor("#d33c3c")

  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').item:setItemId(0)
  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').item.tierflags:setVisible(false)
  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').item.questionMark:setVisible(true)
  fusionPanel:getChildById('itemsFusion'):getChildById('dustCount').dustamount:setColor("#d33c3c")

  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').itemTo:setItemId(0)
  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').itemTo.tierflags:setVisible(false)
  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').itemTo.questionMark:setVisible(true)

  local messageColorNormal = {}
  setStringColor(messageColorNormal, "???", "#d33c3c")
  setStringColor(messageColorNormal, " $", "#c0c0c0")
  setColoredTextOrFallback(fusionPanel:getChildById('itemsFusion'):getChildById('moneyPanel').gold, messageColorNormal, "??? $", "#d33c3c")

  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton').locked:setVisible(true)
  fusionPanel:getChildById('itemsFusion'):getChildById('fusionButton'):setEnabled(false)
  ForgeSystem.checkFusionButtons()
  ForgeSystem.checkFusionLabels()
  ForgeSystem.checkFusionConversionButton()
end

function onSelectionForgeConvection(widget, selectedWidget)
  local itemPtr = selectedWidget.itemPtr
  ForgeSystem.fusionSelectedItem = itemPtr:getId()
  ForgeSystem.checkFusionConversionButton()
end

function onConvergenceFusionChange(_, isChecked)
  ForgeSystem.clearFusion()
  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em onConvergenceFusionChange")
    return
  end

  local fusionPanel = contentPanel:getChildById('fusionPanel')
  if not fusionPanel then
    print("Erro: fusionPanel não encontrado em onConvergenceFusionChange")
    return
  end
  fusionPanel:getChildById('itemsFusion'):setVisible(not isChecked)
  fusionPanel:getChildById('converFusion'):setVisible(isChecked)
  ForgeSystem.updateFusion()
end

function ForgeSystem.onForgeFusion(convergence, success, otherItem, otherTier, itemId, tier, resultType, itemResult, tierResult, count)
  if not ensureForgeWindow() or not resultWindow then
    print("Erro: resultWindow não está inicializado em ForgeSystem.onForgeFusion")
    return
  end

  cancelForgeEvents()
  ForgeSystem.inForgeFusion = true
  hideForge()
  resultWindow:show(true)
  resultWindow:raise()
  resultWindow:focus()
  resultWindow:setText('Fusion Result')

  resultWindow.contentPanel.resultWindow:setVisible(false)
  resultWindow.contentPanel.bonusWindow:setVisible(false)

  local resultWindowPanel = resultWindow.contentPanel.resultWindow
  resultWindowPanel:setVisible(true)
  resultWindowPanel.resultLabel:setText('')
  resultWindowPanel.resultLabel:setColor("#FFFFFF")

  resultWindowPanel.transferItem:setItemId(otherItem)
  resultWindowPanel.transferItem:setItemShader("item_print_white")
  resultWindowPanel.transferItem.tierflags:setImageClip(math.max(otherTier - 1, 0) * 18 .. " 0 18 16")
  resultWindowPanel.transferItem.tierflags:setVisible(false)

  resultWindowPanel.recvItem:setItemId(itemId)
  resultWindowPanel.recvItem:setItemShader("item_black_white")
  resultWindowPanel.recvItem.tierflags:setImageClip(math.max(tier - 1, 0) * 18 .. " 0 18 16")
  resultWindowPanel.recvItem.tierflags:setVisible(false)

  resultWindowPanel.finishButton:setEnabled(false)
  resultWindowPanel.finishButton:setText("Close")
  resultWindowPanel.finishButton.locked:setVisible(true)
  if resultType == 0 then
    resultWindowPanel.finishButton.onClick = function() modules.game_forge.ForgeSystem.closeFinish() end
  else
    resultWindowPanel.finishButton.onClick = function() modules.game_forge.ForgeSystem.openBonusFinish(convergence, ForgeSystem.fusionPrice, resultType, itemResult, tierResult, count) end
    forgeResultLabelEvent = scheduleEvent(function()
      forgeResultLabelEvent = nil
      if resultWindow and not resultWindow:isDestroyed() and
          resultWindowPanel and not resultWindowPanel:isDestroyed() then
        resultWindowPanel.finishButton:setText("Next")
      end
    end, 3550)
  end

  scheduleForgeAnimation(function() ForgeSystemEventFusionColor(false, success, otherItem, otherTier, itemId, tier, resultType, itemResult, tierResult, count, 1) end, 750)
end

function ForgeSystem.onForgeTransfer(convergence, success, otherItem, otherTier, itemId, tier)
  if not ensureForgeWindow() or not resultWindow then
    print("Erro: resultWindow não está inicializado em ForgeSystem.onForgeTransfer")
    return
  end

  cancelForgeEvents()
  ForgeSystem.inForgeFusion = true
  hideForge()
  resultWindow:show(true)
  resultWindow:raise()
  resultWindow:focus()
  resultWindow:setText('Transfer Result')

  resultWindow.contentPanel.resultWindow:setVisible(false)
  resultWindow.contentPanel.bonusWindow:setVisible(false)

  local resultWindowPanel = resultWindow.contentPanel.resultWindow
  resultWindowPanel:setVisible(true)
  resultWindowPanel.resultLabel:setText('')
  resultWindowPanel.resultLabel:setColor("#FFFFFF")

  resultWindowPanel.transferItem:setItemId(otherItem)
  resultWindowPanel.transferItem:setItemShader("item_print_white")
  resultWindowPanel.transferItem.tierflags:setImageClip(math.max(otherTier - 1, 0) * 18 .. " 0 18 16")
  resultWindowPanel.transferItem.tierflags:setVisible(true)

  resultWindowPanel.recvItem:setItemId(itemId)
  resultWindowPanel.recvItem:setItemShader("item_black_white")
  resultWindowPanel.recvItem.tierflags:setImageClip(math.max(tier - 1, 0) * 18 .. " 0 18 16")
  resultWindowPanel.recvItem.tierflags:setVisible(false)

  resultWindowPanel.finishButton:setEnabled(false)
  resultWindowPanel.finishButton:setText("Close")
  resultWindowPanel.finishButton.locked:setVisible(true)
  resultWindowPanel.finishButton.onClick = function() modules.game_forge.ForgeSystem.closeFinish() end

  scheduleForgeAnimation(function() ForgeSystemEventFusionColor(true, success, otherItem, otherTier, itemId, tier, 0, 0, 0, 0, 1) end, 750)
end

function ForgeSystem.sendForgeFusion(convergence)
  ForgeSystem.inForgeFusion = false
  if not convergence then
    protocol.ForgeProtocol.sendForgeFusion(false, ForgeSystem.fusionItem:getId(), getForgeItemTier(ForgeSystem.fusionItem), ForgeSystem.fusionItem:getId(), ForgeSystem.rateSuccessActive, ForgeSystem.tierLossActive)
  else
    protocol.ForgeProtocol.sendForgeFusion(true, ForgeSystem.fusionItem:getId(), getForgeItemTier(ForgeSystem.fusionItem), ForgeSystem.fusionSelectedItem, false, false)
  end
end

function ForgeSystem.updateTransfer()
  ForgeSystem.clearFusion()
  ForgeSystem.clearTransfer()
  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.updateTransfer")
    return
  end

  local transferPanel = contentPanel:getChildById('transferPanel')
  if not transferPanel then
    print("Erro: transferPanel não encontrado em updateTransfer")
    return
  end

  local itemPanel = transferPanel:getChildById('itemTransferPanel'):getChildById('itemsPanel')
  transferPanel:getChildById('itemTransferPanel'):getChildById('itemsPanel'):destroyChildren()

  if selectedItemFusionRadio then
    selectedItemFusionRadio:destroy()
  end

  selectedItemFusionRadio = UIRadioGroup.create()
  selectedItemFusionRadio:clearSelected()
  connect(selectedItemFusionRadio, { onSelectionChange = onSelectionChange })

  local data = ForgeSystem.transferData

  if transferPanel:getChildById('converFusion'):isVisible() then
    data = ForgeSystem.transferConvergenceData
  end

  local itemsVec = {}
  for _, fusion in pairs(data) do
    if not itemsVec[fusion[1] .. "." .. fusion[2]] then
      local widget = g_ui.createWidget('FusionItemBox', itemPanel)

      local itemPtr = createForgeItem(fusion[1], fusion[2])

      setupForgeItemBox(widget, itemPtr, fusion[3])
      widget.itemPtr = itemPtr
      widget.subItems = fusion[4]
      widget.classification = fusion[5] or 0
      widget.category = fusion[6] or 0

      selectedItemFusionRadio:addWidget(widget)

      itemsVec[fusion[1] .. "." .. fusion[2]] = true
    end
  end
end

local function ConfigureTransferPanel(selectedWidget)
  ForgeSystem.fusionSelectedItem = 0

  local itemPtr = selectedWidget.itemPtr
  local itemCount = getForgeWidgetCount(selectedWidget)
  local itemTier = getForgeItemTier(itemPtr)
  local subItems = selectedWidget.subItems

  ForgeSystem.fusionItem = itemPtr
  ForgeSystem.fusionItemCount = itemCount
  ForgeSystem.fusionTier = itemTier

  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ConfigureTransferPanel")
    return
  end

  local transferPanel = contentPanel:getChildById('transferPanel')
  if not transferPanel then
    print("Erro: transferPanel não encontrado em ConfigureTransferPanel")
    return
  end

  transferPanel:getChildById('itemTransferPanel'):getChildById('itemsTransferPanel'):destroyChildren()
  local itemsTransferPanel = transferPanel:getChildById('itemTransferPanel'):getChildById('itemsTransferPanel')

  selectedItemFusionConvectionRadio = UIRadioGroup.create()
  ForgeSystem.fusionSelectedItem = 0

  selectedItemFusionConvectionRadio:clearSelected()
  connect(selectedItemFusionConvectionRadio, { onSelectionChange = onSelectionForgeTransfer })

  for item, count in pairs(subItems) do
    if item == itemPtr:getId() then
      goto continue
    end
    local widget = g_ui.createWidget('FusionItemBox', itemsTransferPanel)

    local itemPtr = Item.create(item, 1)

    setupForgeItemBox(widget, itemPtr, count)
    widget.itemPtr = itemPtr
    selectedItemFusionConvectionRadio:addWidget(widget)
    ::continue::
  end

  transferPanel:getChildById('itemsFusion'):getChildById('itemPanel').item:setItemId(itemPtr:getId())
  transferPanel:getChildById('itemsFusion'):getChildById('itemPanel').item.questionMark:setVisible(false)
  transferPanel:getChildById('itemsFusion'):getChildById('itemCount').value:setText(itemCount .. " / 1")
  transferPanel:getChildById('itemsFusion'):getChildById('itemCount').value:setColor("#FFFFFF")

  transferPanel:getChildById('itemsFusion'):getChildById('itemPanel').item:setItemId(itemPtr:getId())
  if itemTier > 0 then
    transferPanel:getChildById('itemsFusion'):getChildById('itemPanel').item.tierflags:setImageClip((itemTier - 1) * 18 .. " 0 18 16")
    transferPanel:getChildById('itemsFusion'):getChildById('itemPanel').item.tierflags:setVisible(true)
  else
    transferPanel:getChildById('itemsFusion'):getChildById('itemPanel').item.tierflags:setVisible(false)
  end

  local dust = getResource(ResourceForgeDust)
  transferPanel:getChildById('itemsFusion'):getChildById('dustCount').dustamount:setColor((dust >= ForgeSystem.dustTransfer and "#FFFFFF" or "#d33c3c"))
  forgeWindow:getChildById('dustPanel').dust:setText(dust .. '/' .. ForgeSystem.maxPlayerDust)

  local exaltedCoreCount = ForgeSystem.transferMap[itemTier - 1] or 1
  transferPanel:getChildById('itemsFusion'):getChildById('exaltedCount').amount:setText(exaltedCoreCount)
  local exaltedCore = getResource(ResourceForgeExaltedCore)
  transferPanel:getChildById('itemsFusion'):getChildById('exaltedCount').amount:setColor((exaltedCore >= exaltedCoreCount and "#FFFFFF" or "#d33c3c"))

  ForgeSystem.exaltedCoreCount = exaltedCoreCount

  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').item:setItemId(itemPtr:getId())
  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').item.questionMark:setVisible(false)
  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').item.tierflags:setVisible(true)
  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').item.tierflags:setImageClip((itemTier - 1) * 9 .. " 0 9 8")

  local classification = selectedWidget.classification or 0
  local price = ForgeSystem.classPrice[classification] and ForgeSystem.classPrice[classification][2][itemTier - 1] or 0
  ForgeSystem.fusionPrice = price

  local messageColor = {}
  setStringColor(messageColor, formatMoney(price, ","), (getTotalMoney() >= ForgeSystem.fusionPrice and "#FFFFFF" or "#d33c3c"))
  setStringColor(messageColor, " $", "#c0c0c0")
  setColoredTextOrFallback(transferPanel:getChildById('itemsFusion'):getChildById('moneyPanel').gold, messageColor, formatMoney(price, ",") .. " $", getTotalMoney() >= ForgeSystem.fusionPrice and "#FFFFFF" or "#d33c3c")

  ForgeSystem.checkTransferButton()
end

local function ConfigureTransferConvergencePanel(selectedWidget)
  ForgeSystem.fusionSelectedItem = 0

  local itemPtr = selectedWidget.itemPtr
  local itemCount = getForgeWidgetCount(selectedWidget)
  local itemTier = getForgeItemTier(itemPtr)
  local subItems = selectedWidget.subItems

  ForgeSystem.fusionItem = itemPtr
  ForgeSystem.fusionItemCount = itemCount
  ForgeSystem.fusionTier = itemTier

  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ConfigureTransferConvergencePanel")
    return
  end

  local transferPanel = contentPanel:getChildById('transferPanel')
  if not transferPanel then
    print("Erro: transferPanel não encontrado em ConfigureTransferConvergencePanel")
    return
  end

  transferPanel:getChildById('itemTransferPanel'):getChildById('itemsTransferPanel'):destroyChildren()
  local itemsTransferPanel = transferPanel:getChildById('itemTransferPanel'):getChildById('itemsTransferPanel')

  selectedItemFusionConvectionRadio = UIRadioGroup.create()
  ForgeSystem.fusionSelectedItem = 0

  selectedItemFusionConvectionRadio:clearSelected()
  connect(selectedItemFusionConvectionRadio, { onSelectionChange = onSelectionForgeConversionTransfer })

  for item, count in pairs(subItems) do
    if item == itemPtr:getId() then
      goto continue
    end
    local widget = g_ui.createWidget('FusionItemBox', itemsTransferPanel)

    local itemPtr = Item.create(item, 1)

    setupForgeItemBox(widget, itemPtr, count)
    widget.itemPtr = itemPtr
    selectedItemFusionConvectionRadio:addWidget(widget)
    ::continue::
  end

  transferPanel:getChildById('converFusion'):getChildById('itemPanel').item:setItemId(itemPtr:getId())
  transferPanel:getChildById('converFusion'):getChildById('itemPanel').item.questionMark:setVisible(false)
  transferPanel:getChildById('converFusion'):getChildById('itemCount').value:setText(itemCount .. " / 1")
  transferPanel:getChildById('converFusion'):getChildById('itemCount').value:setColor("#FFFFFF")

  transferPanel:getChildById('converFusion'):getChildById('itemPanel').item:setItemId(itemPtr:getId())
  if itemTier > 0 then
    transferPanel:getChildById('converFusion'):getChildById('itemPanel').item.tierflags:setImageClip((itemTier - 1) * 18 .. " 0 18 16")
    transferPanel:getChildById('converFusion'):getChildById('itemPanel').item.tierflags:setVisible(true)
  else
    transferPanel:getChildById('converFusion'):getChildById('itemPanel').item.tierflags:setVisible(false)
  end

  local dust = getResource(ResourceForgeDust)
  transferPanel:getChildById('converFusion'):getChildById('dustCount').dustamount:setColor((dust >= ForgeSystem.convergenceDustTransfer and "#FFFFFF" or "#d33c3c"))
  forgeWindow:getChildById('dustPanel').dust:setText(dust .. '/' .. ForgeSystem.maxPlayerDust)

  local exaltedCoreCount = ForgeSystem.transferMap[itemTier] or 1
  transferPanel:getChildById('converFusion'):getChildById('exaltedCount').amount:setText(exaltedCoreCount)
  local exaltedCore = getResource(ResourceForgeExaltedCore)
  transferPanel:getChildById('converFusion'):getChildById('exaltedCount').amount:setColor((exaltedCore >= exaltedCoreCount and "#FFFFFF" or "#d33c3c"))

  ForgeSystem.exaltedCoreCount = exaltedCoreCount

  transferPanel:getChildById('converFusion'):getChildById('transferButton').item:setItemId(itemPtr:getId())
  transferPanel:getChildById('converFusion'):getChildById('transferButton').item.questionMark:setVisible(false)
  transferPanel:getChildById('converFusion'):getChildById('transferButton').item.tierflags:setVisible(true)
  transferPanel:getChildById('converFusion'):getChildById('transferButton').item.tierflags:setImageClip((itemTier - 1) * 9 .. " 0 9 8")

  local price = ForgeSystem.transferPrices[itemTier] or 0
  ForgeSystem.fusionPrice = price

  local messageColor = {}
  setStringColor(messageColor, formatMoney(price, ","), (getTotalMoney() >= ForgeSystem.fusionPrice and "#FFFFFF" or "#d33c3c"))
  setStringColor(messageColor, " $", "#c0c0c0")
  setColoredTextOrFallback(transferPanel:getChildById('converFusion'):getChildById('moneyPanel').gold, messageColor, formatMoney(price, ",") .. " $", getTotalMoney() >= ForgeSystem.fusionPrice and "#FFFFFF" or "#d33c3c")

  ForgeSystem.checkTransferConvergenceButton()
end

function ForgeSystem.checkTransferConvergenceButton()
  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.checkTransferConvergenceButton")
    return
  end

  local transferPanel = contentPanel:getChildById('transferPanel')
  if not transferPanel then
    print("Erro: transferPanel não encontrado em checkTransferConvergenceButton")
    return
  end
  transferPanel:getChildById('converFusion'):getChildById('transferButton').locked:setVisible(not ForgeSystem.checkTransferState())
  transferPanel:getChildById('converFusion'):getChildById('transferButton'):setEnabled(ForgeSystem.checkTransferState())
end

function ForgeSystem.checkTransferButton()
  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.checkTransferButton")
    return
  end

  local transferPanel = contentPanel:getChildById('transferPanel')
  if not transferPanel then
    print("Erro: transferPanel não encontrado em checkTransferButton")
    return
  end
  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').locked:setVisible(not ForgeSystem.checkTransferState())
  transferPanel:getChildById('itemsFusion'):getChildById('transferButton'):setEnabled(ForgeSystem.checkTransferState())
end

function ForgeSystem.checkTransferState()
  local player = g_game.getLocalPlayer()
  if not player then
    return false
  end
  local hasItemCount = ForgeSystem.fusionSelectedItem ~= 0
  local hasDust = false
  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.checkTransferState")
    return false
  end

  local transferPanel = contentPanel:getChildById('transferPanel')
  if not transferPanel then
    print("Erro: transferPanel não encontrado em checkTransferState")
    return false
  end
  if not transferPanel:getChildById('converFusion'):isVisible() then
    hasDust = getResource(ResourceForgeDust) >= ForgeSystem.dustTransfer
  else
    hasDust = getResource(ResourceForgeDust) >= ForgeSystem.convergenceDustTransfer
  end

  local hasExalted = getResource(ResourceForgeExaltedCore) >= ForgeSystem.exaltedCoreCount
  local hasMoney = getTotalMoney() >= ForgeSystem.fusionPrice

  return hasItemCount and hasDust and hasMoney and hasExalted and not ForgeSystem.sideButton
end

function ForgeSystem.addSecondTransferItem()
  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.addSecondTransferItem")
    return
  end

  local transferPanel = contentPanel:getChildById('transferPanel')
  if not transferPanel then
    print("Erro: transferPanel não encontrado em addSecondTransferItem")
    return
  end
  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').itemTo:setItemId(ForgeSystem.fusionSelectedItem)
  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').itemTo.questionMark:setVisible(false)
  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').itemTo.tierflags:setVisible(true)
  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').itemTo.tierflags:setImageClip(math.max(ForgeSystem.fusionTier - 2, 0) * 9 .. " 0 9 8")
end

function ForgeSystem.addSecondTransferConvergenceItem()
  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.addSecondTransferConvergenceItem")
    return
  end

  local transferPanel = contentPanel:getChildById('transferPanel')
  if not transferPanel then
    print("Erro: transferPanel não encontrado em addSecondTransferConvergenceItem")
    return
  end
  transferPanel:getChildById('converFusion'):getChildById('transferButton').itemTo:setItemId(ForgeSystem.fusionSelectedItem)
  transferPanel:getChildById('converFusion'):getChildById('transferButton').itemTo.questionMark:setVisible(false)
  transferPanel:getChildById('converFusion'):getChildById('transferButton').itemTo.tierflags:setVisible(true)
  transferPanel:getChildById('converFusion'):getChildById('transferButton').itemTo.tierflags:setImageClip((ForgeSystem.fusionTier - 1) * 9 .. " 0 9 8")
end

function onSelectionForgeTransfer(widget, selectedWidget)
  local itemPtr = selectedWidget.itemPtr
  local itemCount = getForgeWidgetCount(selectedWidget)
  local itemTier = getForgeItemTier(itemPtr)

  ForgeSystem.fusionSelectedItem = itemPtr:getId()

  ForgeSystem.addSecondTransferItem()
  ForgeSystem.checkTransferButton()
end

function onSelectionForgeConversionTransfer(widget, selectedWidget)
  local itemPtr = selectedWidget.itemPtr
  local itemCount = getForgeWidgetCount(selectedWidget)
  local itemTier = getForgeItemTier(itemPtr)

  ForgeSystem.fusionSelectedItem = itemPtr:getId()

  ForgeSystem.addSecondTransferConvergenceItem()
  ForgeSystem.checkTransferConvergenceButton()
end

function ForgeSystemEventFusionColor(transfer, success, otherItem, otherTier, itemId, tier, resultType, itemResult, tierResult, count, eventCount)
  if not g_game.isOnline() then
    ForgeSystem.inForgeFusion = false
    return
  end

  if not resultWindow or resultWindow:isDestroyed() then
    print("Erro: resultWindow não está inicializado em ForgeSystemEventFusionColor")
    return
  end

  local resultWindowPanel = resultWindow.contentPanel.resultWindow

  if eventCount == 1 then
    resultWindowPanel:getChildById('panel').tick1:setImageSource("/images/arrows/icon-arrow-rightlarge-filled")
    resultWindowPanel:getChildById('panel').tick2:setImageSource("/images/arrows/icon-arrow-rightlarge")
        resultWindowPanel:getChildById('panel').tick3:setImageSource("/images/arrows/icon-arrow-rightlarge")
  elseif eventCount == 2 then
    resultWindowPanel:getChildById('panel').tick1:setImageSource("/images/arrows/icon-arrow-rightlarge-filled")
    resultWindowPanel:getChildById('panel').tick2:setImageSource("/images/arrows/icon-arrow-rightlarge-filled")
    resultWindowPanel:getChildById('panel').tick3:setImageSource("/images/arrows/icon-arrow-rightlarge")
  elseif eventCount == 3 then
    resultWindowPanel:getChildById('panel').tick1:setImageSource("/images/arrows/icon-arrow-rightlarge")
    resultWindowPanel:getChildById('panel').tick2:setImageSource("/images/arrows/icon-arrow-rightlarge-filled")
    resultWindowPanel:getChildById('panel').tick3:setImageSource("/images/arrows/icon-arrow-rightlarge-filled")
  elseif eventCount == 4 then
    resultWindowPanel:getChildById('panel').tick1:setImageSource("/images/arrows/icon-arrow-rightlarge")
    resultWindowPanel:getChildById('panel').tick2:setImageSource("/images/arrows/icon-arrow-rightlarge")
    resultWindowPanel:getChildById('panel').tick3:setImageSource("/images/arrows/icon-arrow-rightlarge-filled")
  elseif eventCount == 5 then
    resultWindowPanel:getChildById('panel').tick1:setImageSource("/images/arrows/icon-arrow-rightlarge-filled")
    resultWindowPanel:getChildById('panel').tick2:setImageSource("/images/arrows/icon-arrow-rightlarge-filled")
    resultWindowPanel:getChildById('panel').tick3:setImageSource("/images/arrows/icon-arrow-rightlarge-filled")
    ForgeSystem.inForgeFusion = false

    if not success then
      if resultType == 4 or resultType == 5 then
        resultWindowPanel.recvItem:setItemShader("")
        resultWindowPanel.recvItem.tierflags:setVisible(tier > 0)
        resultWindowPanel.transferItem:setItemShader("")
        if resultType == 5 then
          resultWindowPanel.transferItem.tierflags:setImageClip(math.max(tierResult - 1, 0) * 18 .. " 0 18 16")
          resultWindowPanel.transferItem.tierflags:setVisible(tierResult > 0)
        else
          resultWindowPanel.transferItem.tierflags:setVisible(otherTier > 0)
        end
      else
        resultWindowPanel.transferItem:setItemShader("item_red")
        resultWindowPanel.recvItem:setItemShader("item_red")
        scheduleForgeAnimation(function()
          if resultWindow and not resultWindow:isDestroyed() then
            resultWindowPanel.transferItem:setItemId(0)
            resultWindowPanel.recvItem:setItemId(0)
          end
        end, 500)
      end
    else
      resultWindowPanel.transferItem:setItemId(0)
      resultWindowPanel.recvItem:setItemShader("")
      resultWindowPanel.recvItem.tierflags:setVisible(true)
    end

    local message = {}
    setStringColor(message, "Your ".. (transfer and "transfer" or "fusion") .." attempt was ", "#808080")
    if not success then
      setStringColor(message, "failed", "#d33c3c")
    else
      setStringColor(message, "successful", "#00FF00")
    end
    setStringColor(message, ".", "#808080")

    local plainMessage = "Your " .. (transfer and "transfer" or "fusion") .. " attempt " .. (success and "was successful." or "failed.")
    setColoredTextOrFallback(resultWindowPanel.resultLabel, message, plainMessage, success and "#44ad25" or "#d33c3c")
    resultWindowPanel.resultLabel:setText(plainMessage)
    resultWindowPanel.resultLabel:setColor(success and "#44ad25" or "#d33c3c")

    resultWindowPanel.finishButton:setEnabled(true)
    resultWindowPanel.finishButton.locked:setVisible(false)

    return
  end

  scheduleForgeAnimation(function() ForgeSystemEventFusionColor(transfer, success, otherItem, otherTier, itemId, tier, resultType, itemResult, tierResult, count, eventCount + 1) end, 750)
end

function ForgeSystem.openBonusFinish(convergence, price, resultType, itemResult, tierResult, count)
  if not resultWindow then
    print("Erro: resultWindow não está inicializado em ForgeSystem.openBonusFinish")
    return
  end

  resultWindow.contentPanel.resultWindow:setVisible(false)
  resultWindow.contentPanel.bonusWindow:setVisible(true)

  local bonusResult = resultWindow.contentPanel.bonusWindow

  bonusResult.bonusItem.tierflags:setVisible(false)
  bonusResult.bonusItem:setItemShader("")
  if resultType == 1 then
    bonusResult.bonusItem:setItemId(37160)
    bonusResult.resultLabel:setText("Near! The used ".. (not convergence and ForgeSystem.dustPrice or ForgeSystem.convergenceDustFusion) .." were not consumed.")
  elseif resultType == 2 then
    bonusResult.bonusItem:setItemId(37110)
    bonusResult.resultLabel:setText("Fantastic! The used ".. count .." were not consumed.")
  elseif resultType == 3 then
    bonusResult.bonusItem:setItemId(3031)
    bonusResult.resultLabel:setText("Awesome! The used ".. formatMoney(price, ",") .." were not consumed.")
  elseif resultType == 4 then
    bonusResult.bonusItem:setItemId(itemResult)
    bonusResult.bonusItem.tierflags:setImageClip(math.max(tierResult - 1, 0) * 18 .. " 0 18 16")
    bonusResult.bonusItem.tierflags:setVisible(true)
    bonusResult.resultLabel:setText("What luck! Your second item was not consumed or reduced.")
  elseif resultType == 5 then
    bonusResult.bonusItem:setItemId(itemResult)
    bonusResult.bonusItem.tierflags:setImageClip(math.max(tierResult - 1, 0) * 18 .. " 0 18 16")
    bonusResult.bonusItem.tierflags:setVisible(tierResult > 0)
    bonusResult.resultLabel:setText("Your second item lost one tier.")
  end
end

function ForgeSystem.closeFinish()
  cancelForgeEvents()
  if resultWindow then
    resultWindow:hide()
  end
  protocol.ForgeProtocol.sendOpen()
  show()
  loadMenu('fusionPanel')
end

function onSelectionChange(widget, selectedWidget)
  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em onSelectionChange")
    return
  end

  local fusionPanel = contentPanel:getChildById('fusionPanel')
  local transferPanel = contentPanel:getChildById('transferPanel')
  if not fusionPanel or not transferPanel then
    print("Erro: fusionPanel ou transferPanel não encontrado em onSelectionChange")
    return
  end

  if fusionPanel:getChildById('itemsFusion'):isVisible() then
    ConfigureFusionPanel(selectedWidget)
  elseif fusionPanel:getChildById('converFusion'):isVisible() then
    ConfigureFusionConversionPanel(selectedWidget)
  elseif transferPanel:getChildById('itemsFusion'):isVisible() then
    ConfigureTransferPanel(selectedWidget)
  elseif transferPanel:getChildById('converFusion'):isVisible() then
    ConfigureTransferConvergencePanel(selectedWidget)
  end
end

function ForgeSystem.sendForgeTransfer(convergence)
  ForgeSystem.inForgeFusion = false
  if not convergence then
    protocol.ForgeProtocol.sendForgeTransfer(false, ForgeSystem.fusionItem:getId(), getForgeItemTier(ForgeSystem.fusionItem), ForgeSystem.fusionSelectedItem)
  else
    protocol.ForgeProtocol.sendForgeTransfer(true, ForgeSystem.fusionItem:getId(), getForgeItemTier(ForgeSystem.fusionItem), ForgeSystem.fusionSelectedItem)
  end
end

function onConvergenceTransferChange(widget, isChecked)
  ForgeSystem.clearTransfer()
  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em onConvergenceTransferChange")
    return
  end

  local transferPanel = contentPanel:getChildById('transferPanel')
  if not transferPanel then
    print("Erro: transferPanel não encontrado em onConvergenceTransferChange")
    return
  end
  if isChecked then
    transferPanel:getChildById('itemsFusion'):setVisible(false)
    transferPanel:getChildById('converFusion'):setVisible(true)
  else
    transferPanel:getChildById('itemsFusion'):setVisible(true)
    transferPanel:getChildById('converFusion'):setVisible(false)
  end
  ForgeSystem.updateTransfer()
end

function ForgeSystem.sendForgeConverter(action)
  protocol.ForgeProtocol.sendForgeConverter(action)
end

function ForgeSystem.updateConversion()
  local player = g_game.getLocalPlayer()
  if not player then
    return false
  end

  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.updateConversion")
    return
  end

  local conversionPanel = contentPanel:getChildById('conversionPanel')
  if not conversionPanel then
    print("Erro: conversionPanel não encontrado em updateConversion")
    return
  end

  local dust = getResource(ResourceForgeDust)

  local price1 = ForgeSystem.slivers * ForgeSystem.baseMultipier
  conversionPanel:getChildById('windowConvertDust'):getChildById('itemCount').amount:setColor(dust >= price1 and "#FFFFFF" or "#d33c3c")

  conversionPanel:getChildById('windowConvertDust').dustButton:setEnabled(dust >= price1)
  conversionPanel:getChildById('windowConvertDust').dustButton.locked:setVisible(dust < price1)

  conversionPanel:getChildById('windowConvertSlivers'):getChildById('itemCount').amount:setText(ForgeSystem.totalSlivers)
  local slivers = getResource(ResourceForgeSlivers)
  conversionPanel:getChildById('windowConvertSlivers'):getChildById('itemCount').amount:setColor(slivers >= ForgeSystem.totalSlivers and "#FFFFFF" or "#d33c3c")
  conversionPanel:getChildById('windowConvertSlivers').sliverButton:setEnabled(slivers >= ForgeSystem.totalSlivers)
  conversionPanel:getChildById('windowConvertSlivers').sliverButton.locked:setVisible(slivers < ForgeSystem.totalSlivers)

  local totalDustRequired = ForgeSystem.maxPlayerDust - 75
  conversionPanel:getChildById('windowIncreaseDustLimit'):getChildById('itemCount').amount:setText(totalDustRequired)
  conversionPanel:getChildById('windowIncreaseDustLimit'):getChildById('itemCount').amount:setColor(dust >= totalDustRequired and "#FFFFFF" or "#d33c3c")
  conversionPanel:getChildById('windowIncreaseDustLimit').currentDust:setText(ForgeSystem.maxPlayerDust)
  conversionPanel:getChildById('windowIncreaseDustLimit').nextDust:setText('to ' .. math.min(ForgeSystem.maxPlayerDust + 1, ForgeSystem.maxDust))

  if ForgeSystem.maxPlayerDust >= ForgeSystem.maxDust then
    conversionPanel:getChildById('windowIncreaseDustLimit').baseText:setText('Maximum Reached')
    conversionPanel:getChildById('windowIncreaseDustLimit').currentDust:setVisible(false)
    conversionPanel:getChildById('windowIncreaseDustLimit').img1:setVisible(false)
    conversionPanel:getChildById('windowIncreaseDustLimit').img2:setVisible(false)
    conversionPanel:getChildById('windowIncreaseDustLimit').nextDust:setVisible(false)
  else
    conversionPanel:getChildById('windowIncreaseDustLimit').baseText:setText('Raise limit from')
    conversionPanel:getChildById('windowIncreaseDustLimit').currentDust:setVisible(true)
    conversionPanel:getChildById('windowIncreaseDustLimit').img1:setVisible(true)
    conversionPanel:getChildById('windowIncreaseDustLimit').img2:setVisible(true)
    conversionPanel:getChildById('windowIncreaseDustLimit').nextDust:setVisible(true)
  end

  conversionPanel:getChildById('windowIncreaseDustLimit').increaseButton:setEnabled(dust >= totalDustRequired and ForgeSystem.maxPlayerDust < ForgeSystem.maxDust)
  conversionPanel:getChildById('windowIncreaseDustLimit').increaseButton.locked:setVisible(not (dust >= totalDustRequired and ForgeSystem.maxPlayerDust < ForgeSystem.maxDust))
end

function ForgeSystem.onForgeHistory(history)
  if not ensureForgeWindow() then
    return
  end

  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.onForgeHistory")
    return
  end

  local historyPanel = contentPanel:getChildById('historyPanel')
  if not historyPanel then
    print("Erro: historyPanel não encontrado em onForgeHistory")
    return
  end

  historyPanel:getChildById('historyList'):destroyChildren()
  local colors = { '#414141', '#484848' }

  for id, info in ipairs(history) do
    local widget = g_ui.createWidget('HistoryForgePanel', historyPanel:getChildById('historyList'))
    local backgroundColor = colors[((id-1) % #colors) + 1]
    widget:setHeight(30)

    if id == 1 then
      widget:setMarginTop(16)
    end
    widget:setBackgroundColor(backgroundColor)
    widget.date:setText(os.date("%Y-%m-%d, %X", info[1]))
    widget.date:setColor("#FFFFFF")
    local actionText
    local actionColor
    if info[2] == 0 then
      actionText = 'Fusion'
      actionColor = "#FFFFFF"
    elseif info[2] == 1 then
      actionText = 'Transfer'
      actionColor = "#FFFFFF"
    else
      actionText = 'Conversion'
      actionColor = "#0000FF"
    end
    widget.action:setText(actionText)
    widget.action:setColor(actionColor)
    widget.details:setText(info[3])
    widget.details:setColor("#FFFFFF")
  end
end

function ForgeSystem.clearTransfer()
  ForgeSystem.fusionItem = nil
  ForgeSystem.fusionItemCount = 0
  ForgeSystem.fusionSelectedItem = 0
  ForgeSystem.exaltedCoreCount = 0
  ForgeSystem.rateSuccessActive = false
  ForgeSystem.tierLossActive = false
  ForgeSystem.fusionTier = 0

  local contentPanel = forgeWindow:getChildById('contentPanel')
  if not contentPanel then
    print("Erro: contentPanel não encontrado em ForgeSystem.clearTransfer")
    return
  end

  local transferPanel = contentPanel:getChildById('transferPanel')
  if not transferPanel then
    print("Erro: transferPanel não encontrado em clearTransfer")
    return
  end

  transferPanel:getChildById('itemTransferPanel'):getChildById('itemsTransferPanel'):destroyChildren()

  transferPanel:getChildById('itemsFusion'):getChildById('itemPanel').item:setItemId(0)
  transferPanel:getChildById('itemsFusion'):getChildById('itemPanel').item.questionMark:setVisible(true)
  transferPanel:getChildById('itemsFusion'):getChildById('itemCount').value:setText("0 / 1")
  transferPanel:getChildById('itemsFusion'):getChildById('itemCount').value:setColor("#d33c3c")
  transferPanel:getChildById('itemsFusion'):getChildById('itemPanel').item:setItemId(0)
  transferPanel:getChildById('itemsFusion'):getChildById('itemPanel').item.tierflags:setVisible(false)

  transferPanel:getChildById('itemsFusion'):getChildById('dustCount').dustamount:setColor("#d33c3c")

  transferPanel:getChildById('itemsFusion'):getChildById('exaltedCount').amount:setText("???")
  transferPanel:getChildById('itemsFusion'):getChildById('exaltedCount').amount:setColor("#d33c3c")

  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').item:setItemId(0)
  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').item.questionMark:setVisible(true)
  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').item.tierflags:setVisible(false)

  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').itemTo:setItemId(0)
  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').itemTo.questionMark:setVisible(true)
  transferPanel:getChildById('itemsFusion'):getChildById('transferButton').itemTo.tierflags:setVisible(false)

  local messageColor = {}
  setStringColor(messageColor, "???", "#d33c3c")
  setStringColor(messageColor, " $", "#c0c0c0")
  setColoredTextOrFallback(transferPanel:getChildById('itemsFusion'):getChildById('moneyPanel').gold, messageColor, "??? $", "#d33c3c")

  transferPanel:getChildById('converFusion'):getChildById('itemPanel').item:setItemId(0)
  transferPanel:getChildById('converFusion'):getChildById('itemPanel').item.questionMark:setVisible(true)
  transferPanel:getChildById('converFusion'):getChildById('itemCount').value:setText("0 / 1")
  transferPanel:getChildById('converFusion'):getChildById('itemCount').value:setColor("#d33c3c")
  transferPanel:getChildById('converFusion'):getChildById('itemPanel').item:setItemId(0)
  transferPanel:getChildById('converFusion'):getChildById('itemPanel').item.tierflags:setVisible(false)

  transferPanel:getChildById('converFusion'):getChildById('dustCount').dustamount:setColor("#d33c3c")

  transferPanel:getChildById('converFusion'):getChildById('exaltedCount').amount:setText("???")
  transferPanel:getChildById('converFusion'):getChildById('exaltedCount').amount:setColor("#d33c3c")

  transferPanel:getChildById('converFusion'):getChildById('transferButton').item:setItemId(0)
  transferPanel:getChildById('converFusion'):getChildById('transferButton').item.questionMark:setVisible(true)
  transferPanel:getChildById('converFusion'):getChildById('transferButton').item.tierflags:setVisible(false)

  transferPanel:getChildById('converFusion'):getChildById('transferButton').itemTo:setItemId(0)
  transferPanel:getChildById('converFusion'):getChildById('transferButton').itemTo.questionMark:setVisible(true)
  transferPanel:getChildById('converFusion'):getChildById('transferButton').itemTo.tierflags:setVisible(false)

  local messageColorConver = {}
  setStringColor(messageColorConver, "???", "#d33c3c")
  setStringColor(messageColorConver, " $", "#c0c0c0")
  setColoredTextOrFallback(transferPanel:getChildById('converFusion'):getChildById('moneyPanel').gold, messageColorConver, "??? $", "#d33c3c")

  ForgeSystem.checkTransferConvergenceButton()
end
