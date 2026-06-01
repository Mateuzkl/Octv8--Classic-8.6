ForgeProtocol = {}

local protocol = nil
local silent = false
local debugEnabled = false

local ForgeOpcode = {
  Request = 0xE2,
  Send = 0xE3
}

local ForgeRequest = {
  Open = 1,
  Close = 2,
  Fusion = 3,
  Transfer = 4,
  Convert = 5,
  History = 6
}

local ForgeResponse = {
  Message = 0,
  Init = 1,
  Data = 2,
  Fusion = 3,
  Transfer = 4,
  History = 5,
  Close = 6
}

local function debugForge(message)
end

local function send(msg)
  if protocol and not silent then
    protocol:send(msg)
  else
    debugForge("send blocked protocol=" .. tostring(protocol ~= nil) .. " silent=" .. tostring(silent))
  end
end

local function readPriceTable(msg)
  local result = {}
  local classCount = msg:getU8()

  for i = 1, classCount do
    local classification = msg:getU8()
    local tierPrices = {}
    local tierCount = msg:getU8()

    for j = 1, tierCount do
      tierPrices[msg:getU8()] = msg:getU64()
    end

    result[classification] = {
      [2] = tierPrices
    }
  end

  return result
end

local function readNumberMap(msg)
  local result = {}
  local count = msg:getU8()

  for i = 1, count do
    result[msg:getU8()] = msg:getU64()
  end

  return result
end

local function readByteMap(msg)
  local result = {}
  local count = msg:getU8()

  for i = 1, count do
    result[msg:getU8()] = msg:getU8()
  end

  return result
end

local function readForgeItems(msg)
  local result = {}
  local count = msg:getU16()

  for i = 1, count do
    local entry = {
      msg:getU16(),
      msg:getU8(),
      msg:getU16(),
      {},
      msg:getU8(),
      msg:getU8()
    }

    local subItemCount = msg:getU16()
    for j = 1, subItemCount do
      entry[4][msg:getU16()] = msg:getU16()
    end

    table.insert(result, entry)
  end

  return result
end

local function parseInit(msg)
  debugForge("received INIT")
  ForgeSystem.init(
    readPriceTable(msg),
    readByteMap(msg),
    readNumberMap(msg),
    readNumberMap(msg),
    msg:getU16(),
    msg:getU16(),
    msg:getU16(),
    msg:getU16(),
    msg:getU16(),
    msg:getU16(),
    msg:getU16(),
    msg:getU16(),
    msg:getU16(),
    msg:getU16(),
    msg:getU8(),
    msg:getU8(),
    msg:getU8()
  )
  if ForgeSystem.show then
    ForgeSystem.show()
  elseif show then
    show()
  end
end

local function parseData(msg)
  local maxPlayerDust = msg:getU16()
  local balances = {
    [ResourceBank] = msg:getU64(),
    [ResourceInventory] = msg:getU64(),
    [ResourceForgeDust] = msg:getU64(),
    [ResourceForgeSlivers] = msg:getU64(),
    [ResourceForgeExaltedCore] = msg:getU64()
  }

  if ForgeSystem.setResourceBalances then
    ForgeSystem.setResourceBalances(balances)
  end

  local fusionData = readForgeItems(msg)
  local fusionConvergenceData = readForgeItems(msg)
  local transferData = readForgeItems(msg)
  local transferConvergenceData = readForgeItems(msg)
  debugForge(
    "received DATA maxDust=" .. tostring(maxPlayerDust) ..
    " bank=" .. tostring(balances[ResourceBank]) ..
    " inventory=" .. tostring(balances[ResourceInventory]) ..
    " dust=" .. tostring(balances[ResourceForgeDust]) ..
    " slivers=" .. tostring(balances[ResourceForgeSlivers]) ..
    " cores=" .. tostring(balances[ResourceForgeExaltedCore]) ..
    " fusion=" .. tostring(#fusionData) ..
    " fusionConv=" .. tostring(#fusionConvergenceData) ..
    " transfer=" .. tostring(#transferData) ..
    " transferConv=" .. tostring(#transferConvergenceData)
  )

  ForgeSystem.onForgeData(
    fusionData,
    fusionConvergenceData,
    transferData,
    transferConvergenceData,
    maxPlayerDust
  )
end

local function parseFusion(msg)
  ForgeSystem.onForgeFusion(
    msg:getU8() ~= 0,
    msg:getU8() ~= 0,
    msg:getU16(),
    msg:getU8(),
    msg:getU16(),
    msg:getU8(),
    msg:getU8(),
    msg:getU16(),
    msg:getU8(),
    msg:getU16()
  )
end

local function parseTransfer(msg)
  ForgeSystem.onForgeTransfer(
    msg:getU8() ~= 0,
    msg:getU8() ~= 0,
    msg:getU16(),
    msg:getU8(),
    msg:getU16(),
    msg:getU8()
  )
end

local function parseHistory(msg)
  local history = {}
  local count = msg:getU16()

  for i = 1, count do
    table.insert(history, {
      msg:getU32(),
      msg:getU8(),
      msg:getString()
    })
  end

  ForgeSystem.onForgeHistory(history)
end

local function showForgeMessage(message)
  if displayInfoBox then
    displayInfoBox(tr("Forge"), message)
  end
end

local function parseForgeMessage(protocolGame, msg)
  local response = msg:getU8()
  debugForge("received response=" .. tostring(response))

  local ok = true
  local err = nil

  if response == ForgeResponse.Message then
    ok, err = pcall(function() showForgeMessage(msg:getString()) end)
  elseif response == ForgeResponse.Init then
    ok, err = pcall(parseInit, msg)
  elseif response == ForgeResponse.Data then
    ok, err = pcall(parseData, msg)
  elseif response == ForgeResponse.Fusion then
    ok, err = pcall(parseFusion, msg)
  elseif response == ForgeResponse.Transfer then
    ok, err = pcall(parseTransfer, msg)
  elseif response == ForgeResponse.History then
    ok, err = pcall(parseHistory, msg)
  elseif response == ForgeResponse.Close then
    ok, err = pcall(offlineForge)
  else
    debugForge("unknown response=" .. tostring(response))
  end

  if not ok then
    debugForge("parse failed response=" .. tostring(response) .. " error=" .. tostring(err))
  end

  return true
end

function initProtocol()
  connect(g_game, {
    onGameStart = ForgeProtocol.registerProtocol,
    onGameEnd = ForgeProtocol.unregisterProtocol
  })

  if g_game.isOnline() then
    ForgeProtocol.registerProtocol()
  end

  ForgeProtocol.silent(false)
end

function terminateProtocol()
  disconnect(g_game, {
    onGameStart = ForgeProtocol.registerProtocol,
    onGameEnd = ForgeProtocol.unregisterProtocol
  })
  ForgeProtocol.unregisterProtocol()
  ForgeProtocol = nil
end

function ForgeProtocol.registerProtocol()
  ProtocolGame.unregisterOpcode(ForgeOpcode.Send)
  ProtocolGame.registerOpcode(ForgeOpcode.Send, parseForgeMessage)
  protocol = g_game.getProtocolGame()
  debugForge("registered send opcode=" .. tostring(ForgeOpcode.Send) .. " protocol=" .. tostring(protocol ~= nil))
end

function ForgeProtocol.unregisterProtocol()
  ProtocolGame.unregisterOpcode(ForgeOpcode.Send)
  protocol = nil
  debugForge("unregistered send opcode=" .. tostring(ForgeOpcode.Send))
end

function ForgeProtocol.silent(mode)
  silent = mode
end

local function sendRequest(action)
  local msg = OutputMessage.create()
  msg:addU8(ForgeOpcode.Request)
  msg:addU8(action)
  debugForge("send request action=" .. tostring(action) .. " opcode=" .. tostring(ForgeOpcode.Request))
  send(msg)
end

function ForgeProtocol.sendOpen()
  sendRequest(ForgeRequest.Open)
end

function ForgeProtocol.sendClose()
  sendRequest(ForgeRequest.Close)
end

function ForgeProtocol.sendHistory()
  sendRequest(ForgeRequest.History)
end

function ForgeProtocol.sendForgeFusion(convergence, itemId, tier, secondItemId, boostSuccess, protectTierLoss)
  local msg = OutputMessage.create()
  msg:addU8(ForgeOpcode.Request)
  msg:addU8(ForgeRequest.Fusion)
  msg:addU8(convergence and 1 or 0)
  msg:addU16(itemId)
  msg:addU8(tier)
  msg:addU16(secondItemId)
  msg:addU8(boostSuccess and 1 or 0)
  msg:addU8(protectTierLoss and 1 or 0)
  send(msg)
end

function ForgeProtocol.sendForgeTransfer(convergence, itemId, tier, secondItemId)
  local msg = OutputMessage.create()
  msg:addU8(ForgeOpcode.Request)
  msg:addU8(ForgeRequest.Transfer)
  msg:addU8(convergence and 1 or 0)
  msg:addU16(itemId)
  msg:addU8(tier)
  msg:addU16(secondItemId)
  send(msg)
end

function ForgeProtocol.sendForgeConverter(action)
  local msg = OutputMessage.create()
  msg:addU8(ForgeOpcode.Request)
  msg:addU8(ForgeRequest.Convert)
  msg:addU8(action)
  send(msg)
end
