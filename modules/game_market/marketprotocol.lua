MarketProtocol = {}
local silent, protocol = nil
local statistics = runinsandbox("offerstatistic")

local CustomMarketOpcode = {
	Open = 0xF4,
	Leave = 0xF5,
	Browse = 0xF6,
	Create = 0xF7,
	Cancel = 0xE0,
	Accept = 0xE1,
	Send = 0xDB
}

local CustomMarketResponse = {
	Message = 0x00,
	Enter = 0x01,
	Leave = 0x02,
	Browse = 0x03,
	Detail = 0x04
}

local customMarketEnter = nil

local function getDepotItemKey(itemId, tier)
	return tostring(itemId) .. ":" .. tostring(math.max(0, math.min(10, tonumber(tier) or 0)))
end

local function send(msg)
	if protocol and not silent then
		protocol:send(msg)
	end
end

local function readMarketOffer(msg, action, var)
	local timestamp = msg:getU32()
	local counter = msg:getU16()
	local itemId = 0

	if var == MarketRequest.MyOffers or var == MarketRequest.MyHistory then
		itemId = msg:getU16()
	else
		itemId = var
	end

	local amount = msg:getU16()
	local price = msg:getU32()
	local playerName = nil
	local state = MarketOfferState.Active

	if var == MarketRequest.MyHistory then
		state = msg:getU8()
	elseif var ~= MarketRequest.MyOffers then
		playerName = msg:getString()
	end

	return MarketOffer.new({
		timestamp,
		counter
	}, action, Item.create(itemId), amount, price, playerName, state, var)
end

local function readCustomMarketOffer(msg, action, var)
	local offerId = msg:getU32()
	local timestamp = msg:getU32()
	local itemId = msg:getU16()
	local tier = msg:getU8()
	local amount = msg:getU16()
	local price = msg:getU32()
	local playerName = msg:getString()
	local state = msg:getU8()
	local item = Item.create(itemId)
	if item and tier > 0 and item.setTier then
		item:setTier(tier)
	end

	return MarketOffer.new({
		timestamp,
		offerId
	}, action, item, amount, price, playerName, state, var)
end

local function parseMarketEnter(protocol, msg)
	local items = nil

	if g_game.getClientVersion() < 944 then
		items = {}
		local itemsCount = msg:getU16()

		for i = 1, itemsCount do
			local itemId = msg:getU16()
			local category = msg:getU8()
			local name = msg:getString()

			table.insert(items, {
				id = itemId,
				category = category,
				name = name
			})
		end
	end

	local balance = 0

	if g_game.getProtocolVersion() <= 1250 or not g_game.getFeature(GameTibia12Protocol) then
		if g_game.getProtocolVersion() >= 981 or g_game.getProtocolVersion() < 944 then
			balance = msg:getU64()
		else
			balance = msg:getU32()
		end
	end

	local vocation = -1

	if g_game.getProtocolVersion() >= 944 and g_game.getProtocolVersion() < 950 then
		vocation = msg:getU8()
	end

	local offers = msg:getU8()
	local depotItems = {}
	local depotCount = msg:getU16()

	for i = 1, depotCount do
		local itemId = msg:getU16()
		local itemCount = msg:getU16()
		depotItems[itemId] = itemCount
		depotItems[getDepotItemKey(itemId, 0)] = itemCount
	end

	signalcall(Market.onMarketEnter, depotItems, offers, balance, vocation, items)

	return true
end

local function parseMarketLeave(protocol, msg)
	Market.onMarketLeave()

	return true
end

local function parseMarketDetail(protocol, msg)
	local itemId = msg:getU16()
	local descriptions = {}

	for i = MarketItemDescription.First, MarketItemDescription.Last do
		if msg:peekU16() ~= 0 then
			table.insert(descriptions, {
				i,
				msg:getString()
			})
		else
			msg:getU16()
		end
	end

	if g_game.getProtocolVersion() >= 1100 then
		if msg:peekU16() ~= 0 then
			table.insert(descriptions, {
				MarketItemDescription.Last + 1,
				msg:getString()
			})
		else
			msg:getU16()
		end
	end

	local time = os.time() / 1000 * statistics.SECONDS_PER_DAY
	local purchaseStats = {}
	local count = msg:getU8()

	for i = 1, count do
		local transactions = msg:getU32()
		local totalPrice = msg:getU32()
		local highestPrice = msg:getU32()
		local lowestPrice = msg:getU32()
		local tmp = time - statistics.SECONDS_PER_DAY

		table.insert(purchaseStats, OfferStatistic.new(tmp, MarketAction.Buy, transactions, totalPrice, highestPrice, lowestPrice))
	end

	local saleStats = {}
	count = msg:getU8()

	for i = 1, count do
		local transactions = msg:getU32()
		local totalPrice = msg:getU32()
		local highestPrice = msg:getU32()
		local lowestPrice = msg:getU32()
		local tmp = time - statistics.SECONDS_PER_DAY

		table.insert(saleStats, OfferStatistic.new(tmp, MarketAction.Sell, transactions, totalPrice, highestPrice, lowestPrice))
	end

	signalcall(Market.onMarketDetail, itemId, descriptions, purchaseStats, saleStats)

	return true
end

local function parseMarketBrowse(protocol, msg)
	local var = msg:getU16()
	local offers = {}
	local buyOfferCount = msg:getU32()

	for i = 1, buyOfferCount do
		table.insert(offers, readMarketOffer(msg, MarketAction.Buy, var))
	end

	local sellOfferCount = msg:getU32()

	for i = 1, sellOfferCount do
		table.insert(offers, readMarketOffer(msg, MarketAction.Sell, var))
	end

	signalcall(Market.onMarketBrowse, offers, var)

	return true
end

local function parseCustomMarketMessage(protocol, msg)
	local response = msg:getU8()

	if response == CustomMarketResponse.Message then
		Market.displayMessage(msg:getString())
		return true
	elseif response == CustomMarketResponse.Enter then
		local balance = msg:getU64()
		local offers = msg:getU16()
		local chunkIndex = msg:getU16()
		local lastChunk = msg:getU8() ~= 0
		local itemsCount = msg:getU16()

		if chunkIndex == 0 or not customMarketEnter then
			customMarketEnter = {
				balance = balance,
				offers = offers,
				items = {},
				depotItems = {},
				depotTiers = {}
			}
		end

		for i = 1, itemsCount do
			local itemId = msg:getU16()
			local category = msg:getU8()
			local name = msg:getString()
			local amount = msg:getU16()
			local tier = msg:getU8()

			table.insert(customMarketEnter.items, {
				id = itemId,
				category = category,
				name = name,
				tier = tier
			})
			customMarketEnter.depotItems[getDepotItemKey(itemId, tier)] = amount
			customMarketEnter.depotItems[itemId] = (customMarketEnter.depotItems[itemId] or 0) + amount
			customMarketEnter.depotTiers[getDepotItemKey(itemId, tier)] = tier
			if tier > (customMarketEnter.depotTiers[itemId] or 0) then
				customMarketEnter.depotTiers[itemId] = tier
			end
		end

		if lastChunk then
			signalcall(Market.onMarketEnter, customMarketEnter.depotItems, customMarketEnter.offers, customMarketEnter.balance, -1, customMarketEnter.items, customMarketEnter.depotTiers)
			customMarketEnter = nil
		end

		return true
	elseif response == CustomMarketResponse.Leave then
		Market.onMarketLeave()
		return true
	elseif response == CustomMarketResponse.Browse then
		local var = msg:getU16()
		local offers = {}
		local buyOfferCount = msg:getU16()

		for i = 1, buyOfferCount do
			table.insert(offers, readCustomMarketOffer(msg, MarketAction.Buy, var))
		end

		local sellOfferCount = msg:getU16()
		for i = 1, sellOfferCount do
			table.insert(offers, readCustomMarketOffer(msg, MarketAction.Sell, var))
		end

		signalcall(Market.onMarketBrowse, offers, var)
		return true
	elseif response == CustomMarketResponse.Detail then
		local itemId = msg:getU16()
		local descriptions = {}
		local descriptionCount = msg:getU8()

		for i = 1, descriptionCount do
			table.insert(descriptions, {
				msg:getU8(),
				msg:getString()
			})
		end

		local function readStatistics(action)
			local stats = {}
			local count = msg:getU8()

			for i = 1, count do
				local timestamp = msg:getU32()
				local transactions = msg:getU32()
				local totalPrice = msg:getU32()
				local highestPrice = msg:getU32()
				local lowestPrice = msg:getU32()

				table.insert(stats, OfferStatistic.new(timestamp, action, transactions, totalPrice, highestPrice, lowestPrice))
			end

			return stats
		end

		local purchaseStats = readStatistics(MarketAction.Buy)
		local saleStats = readStatistics(MarketAction.Sell)

		signalcall(Market.onMarketDetail, itemId, descriptions, purchaseStats, saleStats)
		return true
	end

	return true
end

function initProtocol()
	connect(g_game, {
		onGameStart = MarketProtocol.registerProtocol,
		onGameEnd = MarketProtocol.unregisterProtocol
	})

	if g_game.isOnline() then
		MarketProtocol.registerProtocol()
	end

	MarketProtocol.silent(false)
end

function terminateProtocol()
	disconnect(g_game, {
		onGameStart = MarketProtocol.registerProtocol,
		onGameEnd = MarketProtocol.unregisterProtocol
	})
	MarketProtocol.unregisterProtocol()

	MarketProtocol = nil
end

function MarketProtocol.updateProtocol(_protocol)
	protocol = _protocol
end

function MarketProtocol.registerProtocol()
	ProtocolGame.unregisterOpcode(CustomMarketOpcode.Send)
	ProtocolGame.registerOpcode(CustomMarketOpcode.Send, parseCustomMarketMessage)

	if g_game.getFeature(GamePlayerMarket) then
		ProtocolGame.registerOpcode(GameServerOpcodes.GameServerMarketEnter, parseMarketEnter)
		ProtocolGame.registerOpcode(GameServerOpcodes.GameServerMarketLeave, parseMarketLeave)
		ProtocolGame.registerOpcode(GameServerOpcodes.GameServerMarketDetail, parseMarketDetail)
		ProtocolGame.registerOpcode(GameServerOpcodes.GameServerMarketBrowse, parseMarketBrowse)
	end

	MarketProtocol.updateProtocol(g_game.getProtocolGame())
end

function MarketProtocol.unregisterProtocol()
	ProtocolGame.unregisterOpcode(CustomMarketOpcode.Send)

	if g_game.getFeature(GamePlayerMarket) then
		ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerMarketEnter, parseMarketEnter)
		ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerMarketLeave, parseMarketLeave)
		ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerMarketDetail, parseMarketDetail)
		ProtocolGame.unregisterOpcode(GameServerOpcodes.GameServerMarketBrowse, parseMarketBrowse)
	end

	MarketProtocol.updateProtocol(nil)
end

function MarketProtocol.silent(mode)
	silent = mode
end

function MarketProtocol.sendMarketLeave()
	local msg = OutputMessage.create()

	msg:addU8(CustomMarketOpcode.Leave)
	send(msg)
end

function MarketProtocol.sendMarketBrowse(browseId)
	local msg = OutputMessage.create()

	msg:addU8(CustomMarketOpcode.Browse)
	msg:addU16(browseId)
	send(msg)
end

function MarketProtocol.sendMarketBrowseMyOffers()
	MarketProtocol.sendMarketBrowse(MarketRequest.MyOffers)
end

function MarketProtocol.sendMarketBrowseMyHistory()
	MarketProtocol.sendMarketBrowse(MarketRequest.MyHistory)
end

function MarketProtocol.sendMarketCreateOffer(type, spriteId, amount, price, anonymous, tier)
	local msg = OutputMessage.create()

	msg:addU8(CustomMarketOpcode.Create)
	msg:addU8(type)
	msg:addU16(spriteId)
	msg:addU16(amount)
	msg:addU32(price)
	msg:addU8(anonymous)
	msg:addU8(math.max(0, math.min(10, tonumber(tier) or 0)))
	send(msg)
end

function MarketProtocol.sendMarketCancelOffer(timestamp, counter)
	local msg = OutputMessage.create()

	msg:addU8(CustomMarketOpcode.Cancel)
	msg:addU32(counter)
	send(msg)
end

function MarketProtocol.sendMarketAcceptOffer(timestamp, counter, amount)
	local msg = OutputMessage.create()

	msg:addU8(CustomMarketOpcode.Accept)
	msg:addU32(counter)
	msg:addU16(amount)
	send(msg)
end
