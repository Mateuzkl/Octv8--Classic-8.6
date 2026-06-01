Market = {}
local protocol = runinsandbox("marketprotocol")
marketWindow = nil
mainTabBar = nil
displaysTabBar = nil
offersTabBar = nil
selectionTabBar = nil
marketOffersPanel = nil
browsePanel = nil
overviewPanel = nil
itemOffersPanel = nil
itemDetailsPanel = nil
itemStatsPanel = nil
myOffersPanel = nil
currentOffersPanel = nil
myCurrentOffersTab = nil
myOfferHistoryTab = nil
offerHistoryPanel = nil
itemsPanel = nil
selectedOffer = {}
selectedMyOffer = {}
nameLabel = nil
feeLabel = nil
balanceLabel = nil
totalPriceEdit = nil
piecePriceEdit = nil
amountEdit = nil
searchEdit = nil
radioItemSet = nil
selectedItem = nil
offerTypeList = nil
categoryList = nil
subCategoryList = nil
slotFilterList = nil
createOfferButton = nil
buyButton = nil
sellButton = nil
anonymous = nil
filterButtons = {}
buyOfferTable = nil
sellOfferTable = nil
detailsTable = nil
buyStatsTable = nil
sellStatsTable = nil
buyCancelButton = nil
sellCancelButton = nil
buyMyOfferTable = nil
sellMyOfferTable = nil
myOfferHistoryTabel = nil
offerExhaust = {}
marketOffers = {}
marketItems = {}
marketItemNames = {}
information = {}
currentItems = {}
lastCreatedOffer = 0
fee = 0
averagePrice = 0
tibiaCoins = 0
loaded = false

local function isItemValid(item, category, searchFilter)
	if not item or not item.marketData then
		return false
	end

	category = category or MarketCategory.All

	if item.marketData.category ~= category and category ~= MarketCategory.All then
		return false
	end

	local slotFilter = false

	if slotFilterList:isEnabled() then
		slotFilter = getMarketSlotFilterId(slotFilterList:getCurrentOption().text)
	end

	local marketData = item.marketData
	local filterVocation = filterButtons[MarketFilters.Vocation]:isChecked()
	local filterLevel = filterButtons[MarketFilters.Level]:isChecked()
	local filterDepot = filterButtons[MarketFilters.Depot]:isChecked()

	if slotFilter and slotFilter ~= 255 and item.thingType:getClothSlot() ~= slotFilter then
		return false
	end

	local player = g_game.getLocalPlayer()

	if filterLevel and marketData.requiredLevel and player:getLevel() < marketData.requiredLevel then
		return false
	end

	if filterVocation and marketData.restrictVocation and marketData.restrictVocation > 0 then
		local voc = Bit.bit(information.vocation)

		if not Bit.hasBit(marketData.restrictVocation, voc) then
			return false
		end
	end

	if filterDepot and Market.getDepotCount(item.marketData.tradeAs, getMarketItemTier(item)) <= 0 then
		return false
	end

	if searchFilter then
		return marketData.name:lower():find(searchFilter)
	end

	return true
end

local function clearItems()
	currentItems = {}

	Market.refreshItemsWidget()
end

local function setDisplayItemTier(item, tier)
	if item and item.setTier then
		item:setTier(math.max(0, math.min(10, tonumber(tier) or 0)))
	end
end

local function getDepotItemKey(itemId, tier)
	return tostring(itemId) .. ":" .. tostring(math.max(0, math.min(10, tonumber(tier) or 0)))
end

local function getMarketItemTier(item)
	if item and item.marketData and item.marketData.tier then
		return math.max(0, math.min(10, tonumber(item.marketData.tier) or 0))
	end
	if item and item.displayItem and item.displayItem.getTier then
		return math.max(0, math.min(10, tonumber(item.displayItem:getTier()) or 0))
	end
	return 0
end

local function clearOffers()
	marketOffers[MarketAction.Buy] = {}
	marketOffers[MarketAction.Sell] = {}

	buyOfferTable:clearData()
	sellOfferTable:clearData()
end

local function clearMyOffers()
	marketOffers[MarketAction.Buy] = {}
	marketOffers[MarketAction.Sell] = {}

	buyMyOfferTable:clearData()
	sellMyOfferTable:clearData()
	myOfferHistoryTabel:clearData()
end

local function clearFilters()
	for _, filter in pairs(filterButtons) do
		if filter and filter:isChecked() ~= filter.default then
			filter:setChecked(filter.default)
		end
	end
end

local function normalizeOffer(offer)
	if offer and not offer.getId and MarketOffer then
		MarketOffer.__index = MarketOffer
		setmetatable(offer, MarketOffer)
	end
	if offer and not offer.getId then
		offer.getId = function(self) return self.id end
		offer.getType = function(self) return self.type end
		offer.getAmount = function(self) return self.amount end
		offer.getPrice = function(self) return self.price end
		offer.getPlayer = function(self) return self.player end
		offer.getItem = function(self) return self.item end
		offer.getState = function(self) return self.state end
		offer.getTimeStamp = function(self) return self.id and self.id[1] end
		offer.getCounter = function(self) return self.id and self.id[2] end
		offer.isEqual = function(self, id) return self.id and id and self.id[1] == id[1] and self.id[2] == id[2] end
		offer.isNull = function(self) return not self.id or table.empty(self.id) end
	end
	return offer
end

local function clearFee()
	feeLabel:setText("")

	fee = 20
end

local function refreshTypeList()
	offerTypeList:clearOptions()
	offerTypeList:addOption("Buy")

	if Market.isItemSelected() and Market.getDepotCount(selectedItem.item.marketData.tradeAs, getMarketItemTier(selectedItem.item)) > 0 then
		offerTypeList:addOption("Sell")
	end
end

local function addOffer(offer, offerType)
	offer = normalizeOffer(offer)
	if not offer then
		return false
	end

	local id = offer:getId()
	local player = offer:getPlayer()
	local amount = offer:getAmount()
	local price = offer:getPrice()
	local timestamp = offer:getTimeStamp()
	local itemName = marketItemNames[offer:getItem():getId()]
	itemName = itemName or offer:getItem():getMarketData().name

	buyOfferTable:toggleSorting(false)
	sellOfferTable:toggleSorting(false)
	buyMyOfferTable:toggleSorting(false)
	sellMyOfferTable:toggleSorting(false)

	if amount < 1 then
		return false
	end

	if offerType == MarketAction.Buy then
		if offer.warn then
			buyOfferTable:setColumnStyle("OfferTableWarningColumn", true)
		end

		local row = nil

		if offer.var == MarketRequest.MyOffers then
			row = buyMyOfferTable:addRow({
				{
					text = itemName
				},
				{
					text = comma_value(price * amount),
					sortvalue = price * amount
				},
				{
					text = comma_value(price),
					sortvalue = price
				},
				{
					text = amount
				},
				{
					text = string.gsub(os.date("%H:%M %d/%m/%y", timestamp), " ", "  "),
					sortvalue = timestamp
				}
			})
		else
			row = buyOfferTable:addRow({
				{
					text = player
				},
				{
					text = amount
				},
				{
					text = comma_value(price * amount),
					sortvalue = price * amount
				},
				{
					text = comma_value(price),
					sortvalue = price
				},
				{
					text = string.gsub(os.date("%H:%M %d/%m/%y", timestamp), " ", "  ")
				}
			})
		end

		row.ref = id

		if offer.warn then
			row:setTooltip(tr("This offer is 25%% below the average market price"))
			buyOfferTable:setColumnStyle("OfferTableColumn", true)
		end
	else
		if offer.warn then
			sellOfferTable:setColumnStyle("OfferTableWarningColumn", true)
		end

		local row = nil

		if offer.var == MarketRequest.MyOffers then
			row = sellMyOfferTable:addRow({
				{
					text = itemName
				},
				{
					text = comma_value(price * amount),
					sortvalue = price * amount
				},
				{
					text = comma_value(price),
					sortvalue = price
				},
				{
					text = amount
				},
				{
					text = string.gsub(os.date("%H:%M %d/%m/%y", timestamp), " ", "  "),
					sortvalue = timestamp
				}
			})
		else
			row = sellOfferTable:addRow({
				{
					text = player
				},
				{
					text = amount
				},
				{
					text = comma_value(price * amount),
					sortvalue = price * amount
				},
				{
					text = comma_value(price),
					sortvalue = price
				},
				{
					text = string.gsub(os.date("%H:%M %d/%m/%y", timestamp), " ", "  "),
					sortvalue = timestamp
				}
			})
		end

		row.ref = id

		if offer.warn then
			row:setTooltip(tr("This offer is 25%% above the average market price"))
			sellOfferTable:setColumnStyle("OfferTableColumn", true)
		end
	end

	buyOfferTable:toggleSorting(false)
	sellOfferTable:toggleSorting(false)
	buyOfferTable:sort()
	sellOfferTable:sort()
	buyMyOfferTable:toggleSorting(false)
	sellMyOfferTable:toggleSorting(false)
	buyMyOfferTable:sort()
	sellMyOfferTable:sort()

	return true
end

local function mergeOffer(offer)
	offer = normalizeOffer(offer)
	if not offer then
		return false
	end

	local id = offer:getId()
	local offerType = offer:getType()
	local amount = offer:getAmount()
	local replaced = false

	if offerType == MarketAction.Buy then
		if averagePrice > 0 then
			offer.warn = offer:getPrice() <= averagePrice - math.floor(averagePrice / 4)
		end

		for i = 1, #marketOffers[MarketAction.Buy] do
			local o = marketOffers[MarketAction.Buy][i]

			if o:isEqual(id) then
				marketOffers[MarketAction.Buy][i] = offer
				replaced = true
			end
		end

		if not replaced then
			table.insert(marketOffers[MarketAction.Buy], offer)
		end
	else
		if averagePrice > 0 then
			offer.warn = offer:getPrice() >= averagePrice + math.floor(averagePrice / 4)
		end

		for i = 1, #marketOffers[MarketAction.Sell] do
			local o = marketOffers[MarketAction.Sell][i]

			if o:isEqual(id) then
				marketOffers[MarketAction.Sell][i] = offer
				replaced = true
			end
		end

		if not replaced then
			table.insert(marketOffers[MarketAction.Sell], offer)
		end
	end

	return true
end

local function updateOffers(offers)
	if not buyOfferTable or not sellOfferTable then
		return
	end

	balanceLabel:setColor("#bbbbbb")

	selectedOffer[MarketAction.Buy] = nil
	selectedOffer[MarketAction.Sell] = nil
	selectedMyOffer[MarketAction.Buy] = nil
	selectedMyOffer[MarketAction.Sell] = nil

	buyOfferTable:clearData()
	buyOfferTable:setSorting(4, TABLE_SORTING_DESC)
	sellOfferTable:clearData()
	sellOfferTable:setSorting(4, TABLE_SORTING_ASC)
	sellButton:setEnabled(false)
	buyButton:setEnabled(false)
	buyCancelButton:setEnabled(false)
	sellCancelButton:setEnabled(false)

	for _, offer in pairs(offers) do
		mergeOffer(offer)
	end

	for type, offers in pairs(marketOffers) do
		for i = 1, #offers do
			addOffer(offers[i], type)
		end
	end
end

local function updateHistoryOffers(offers)
	myOfferHistoryTabel:toggleSorting(false)

	for _, offer in ipairs(offers) do
		offer = normalizeOffer(offer)
		local offerType = offer:getType()
		local id = offer:getId()
		local player = offer:getPlayer()
		local amount = offer:getAmount()
		local price = offer:getPrice()
		local timestamp = offer:getTimeStamp()
		local itemName = marketItemNames[offer:getItem():getId()]
		itemName = itemName or offer:getItem():getMarketData().name
		local offerTypeName = "?"

		if offerType == MarketAction.Buy then
			offerTypeName = "Buy"
		elseif offerType == MarketAction.Sell then
			offerTypeName = "Sell"
		end

		local row = myOfferHistoryTabel:addRow({
			{
				text = offerTypeName
			},
			{
				text = itemName
			},
			{
				text = comma_value(price * amount),
				sortvalue = price * amount
			},
			{
				text = comma_value(price),
				sortvalue = price
			},
			{
				text = amount
			},
			{
				text = string.gsub(os.date("%H:%M %d/%m/%y", timestamp), " ", "  "),
				sortvalue = timestamp
			}
		})
	end

	myOfferHistoryTabel:toggleSorting(false)
	myOfferHistoryTabel:sort()
end

local function updateDetails(itemId, descriptions, purchaseStats, saleStats)
	if not selectedItem then
		return
	end

	detailsTable:clearData()

	for k, desc in pairs(descriptions) do
		local descriptionName = getMarketDescriptionName(desc[1]) or ("Attribute " .. desc[1])
		local columns = {
			{
				text = descriptionName .. ":"
			},
			{
				text = desc[2]
			}
		}

		detailsTable:addRow(columns)
	end

	sellStatsTable:clearData()

	if table.empty(saleStats) then
		sellStatsTable:addRow({
			{
				text = "No information"
			}
		})
	else
		local offerAmount = 0
		local transactions = 0
		local totalPrice = 0
		local highestPrice = 0
		local lowestPrice = 0

		for _, stat in pairs(saleStats) do
			if not stat:isNull() then
				offerAmount = offerAmount + 1
				transactions = transactions + stat:getTransactions()
				totalPrice = totalPrice + stat:getTotalPrice()
				local newHigh = stat:getHighestPrice()

				if highestPrice < newHigh then
					highestPrice = newHigh
				end

				local newLow = stat:getLowestPrice()

				if (lowestPrice == 0 or newLow < lowestPrice) and newLow ~= 4294967295.0 then
					lowestPrice = newLow
				end
			end
		end

		if offerAmount >= 5 and transactions >= 10 then
			averagePrice = math.round(totalPrice / transactions)
		else
			averagePrice = 0
		end

		sellStatsTable:addRow({
			{
				text = "Total Transactions:"
			},
			{
				text = transactions
			}
		})
		sellStatsTable:addRow({
			{
				text = "Highest Price:"
			},
			{
				text = highestPrice
			}
		})

		if totalPrice > 0 and transactions > 0 then
			sellStatsTable:addRow({
				{
					text = "Average Price:"
				},
				{
					text = math.floor(totalPrice / transactions)
				}
			})
		else
			sellStatsTable:addRow({
				{
					text = "Average Price:"
				},
				{
					text = 0
				}
			})
		end

		sellStatsTable:addRow({
			{
				text = "Lowest Price:"
			},
			{
				text = lowestPrice
			}
		})
	end

	buyStatsTable:clearData()

	if table.empty(purchaseStats) then
		buyStatsTable:addRow({
			{
				text = "No information"
			}
		})
	else
		local transactions = 0
		local totalPrice = 0
		local highestPrice = 0
		local lowestPrice = 0

		for _, stat in pairs(purchaseStats) do
			if not stat:isNull() then
				transactions = transactions + stat:getTransactions()
				totalPrice = totalPrice + stat:getTotalPrice()
				local newHigh = stat:getHighestPrice()

				if highestPrice < newHigh then
					highestPrice = newHigh
				end

				local newLow = stat:getLowestPrice()

				if (lowestPrice == 0 or newLow < lowestPrice) and newLow ~= 4294967295.0 then
					lowestPrice = newLow
				end
			end
		end

		buyStatsTable:addRow({
			{
				text = "Total Transactions:"
			},
			{
				text = transactions
			}
		})
		buyStatsTable:addRow({
			{
				text = "Highest Price:"
			},
			{
				text = highestPrice
			}
		})

		if totalPrice > 0 and transactions > 0 then
			buyStatsTable:addRow({
				{
					text = "Average Price:"
				},
				{
					text = math.floor(totalPrice / transactions)
				}
			})
		else
			buyStatsTable:addRow({
				{
					text = "Average Price:"
				},
				{
					text = 0
				}
			})
		end

		buyStatsTable:addRow({
			{
				text = "Lowest Price:"
			},
			{
				text = lowestPrice
			}
		})
	end
end

local function updateSelectedItem(widget)
	selectedItem.item = widget.item
	selectedItem.ref = widget

	Market.resetCreateOffer()

	if Market.isItemSelected() then
		selectedItem:setItem(selectedItem.item.displayItem)
		ItemsDatabase.setTier(selectedItem, selectedItem.item.displayItem)
		nameLabel:setText(selectedItem.item.marketData.name)
		clearOffers()
		Market.enableCreateOffer(true)
		MarketProtocol.sendMarketBrowse(selectedItem.item.marketData.tradeAs)
	else
		Market.clearSelectedItem()
	end
end

local function updateBalance(balance)
	local balance = tonumber(balance)

	if not balance then
		return
	end

	if balance < 0 then
		balance = 0
	end

	information.balance = balance

	balanceLabel:setText("Balance: " .. comma_value(balance) .. " gold")
	balanceLabel:resizeToText()
end

local function updateFee(price, amount)
	fee = math.ceil(price / 100 * amount)

	if fee < 20 then
		fee = 20
	elseif fee > 1000 then
		fee = 1000
	end

	feeLabel:setText("Fee: " .. comma_value(fee))
	feeLabel:resizeToText()
end

local function destroyAmountWindow()
	if amountWindow then
		amountWindow:destroy()

		amountWindow = nil
	end
end

local function cancelMyOffer(actionType)
	local offer = selectedMyOffer[actionType]

	MarketProtocol.sendMarketCancelOffer(offer:getTimeStamp(), offer:getCounter())
	Market.refreshMyOffers()
end

local function openAmountWindow(callback, actionType, actionText)
	if not Market.isOfferSelected(actionType) then
		return
	end

	amountWindow = g_ui.createWidget("AmountWindow", rootWidget)

	amountWindow:lock()

	local offer = selectedOffer[actionType]
	local item = offer:getItem()
	local maximum = offer:getAmount()

	if actionType == MarketAction.Sell then
		local tier = item.getTier and item:getTier() or 0
		local depot = Market.getDepotCount(item:getId(), tier)

		if depot < maximum then
			maximum = depot
		end
	else
		maximum = math.min(maximum, math.floor(information.balance / offer:getPrice()))
	end

	if item:isStackable() then
		maximum = math.min(maximum, MarketMaxAmountStackable)
	else
		maximum = math.min(maximum, MarketMaxAmount)
	end

	local itembox = amountWindow:getChildById("item")

	itembox:setItem(item)
	ItemsDatabase.setTier(itembox, item)

	local scrollbar = amountWindow:getChildById("amountScrollBar")

	scrollbar:setText(comma_value(offer:getPrice()) .. "gp")

	function scrollbar.onValueChange(widget, value)
		widget:setText(comma_value(value * offer:getPrice()) .. "gp")
		itembox:setText(comma_value(value))
	end

	scrollbar:setRange(1, maximum)
	scrollbar:setValue(1)

	local okButton = amountWindow:getChildById("buttonOk")

	if actionText then
		okButton:setText(actionText)
	end

	local function okFunc()
		local counter = offer:getCounter()
		local timestamp = offer:getTimeStamp()

		callback(scrollbar:getValue(), timestamp, counter)
		destroyAmountWindow()
	end

	local cancelButton = amountWindow:getChildById("buttonCancel")

	local function cancelFunc()
		destroyAmountWindow()
	end

	amountWindow.onEnter = okFunc
	amountWindow.onEscape = cancelFunc
	okButton.onClick = okFunc
	cancelButton.onClick = cancelFunc
end

local function onSelectSellOffer(table, selectedRow, previousSelectedRow)
	updateBalance()

	for _, offer in pairs(marketOffers[MarketAction.Sell]) do
		if offer:isEqual(selectedRow.ref) then
			selectedOffer[MarketAction.Buy] = offer
		end
	end

	local offer = selectedOffer[MarketAction.Buy]

	if offer then
		local price = offer:getPrice()

		if information.balance < price then
			balanceLabel:setColor("#b22222")
			buyButton:setEnabled(false)
		else
			local slice = information.balance / 2

			if price / slice * 100 <= 40 then
				color = "#008b00"
			elseif price / slice * 100 <= 70 then
				color = "#eec900"
			else
				color = "#ee9a00"
			end

			balanceLabel:setColor(color)
			buyButton:setEnabled(true)
		end
	end
end

local function onSelectBuyOffer(table, selectedRow, previousSelectedRow)
	updateBalance()

	for _, offer in pairs(marketOffers[MarketAction.Buy]) do
		if offer:isEqual(selectedRow.ref) then
			selectedOffer[MarketAction.Sell] = offer

			local item = offer:getItem()
			local tier = item.getTier and item:getTier() or 0
			if Market.getDepotCount(item:getId(), tier) > 0 then
				sellButton:setEnabled(true)
			else
				sellButton:setEnabled(false)
			end
		end
	end
end

local function onSelectMyBuyOffer(table, selectedRow, previousSelectedRow)
	for _, offer in pairs(marketOffers[MarketAction.Buy]) do
		if offer:isEqual(selectedRow.ref) then
			selectedMyOffer[MarketAction.Buy] = offer

			buyCancelButton:setEnabled(true)
		end
	end
end

local function onSelectMySellOffer(table, selectedRow, previousSelectedRow)
	for _, offer in pairs(marketOffers[MarketAction.Sell]) do
		if offer:isEqual(selectedRow.ref) then
			selectedMyOffer[MarketAction.Sell] = offer

			sellCancelButton:setEnabled(true)
		end
	end
end

local function onChangeCategory(combobox, option)
	local id = getMarketCategoryId(option)

	if id == MarketCategory.MetaWeapons then
		subCategoryList:setEnabled(true)
		slotFilterList:setEnabled(true)

		local subId = getMarketCategoryId(subCategoryList:getCurrentOption().text)

		Market.loadMarketItems(subId)
	else
		subCategoryList:setEnabled(false)
		slotFilterList:setEnabled(false)
		Market.loadMarketItems(id)
	end
end

local function onChangeSubCategory(combobox, option)
	Market.loadMarketItems(getMarketCategoryId(option))
	slotFilterList:clearOptions()

	local subId = getMarketCategoryId(subCategoryList:getCurrentOption().text)
	local slots = MarketCategoryWeapons[subId].slots

	for _, slot in pairs(slots) do
		if table.haskey(MarketSlotFilters, slot) then
			slotFilterList:addOption(MarketSlotFilters[slot])
		end
	end

	slotFilterList:setEnabled(true)
end

local function onChangeSlotFilter(combobox, option)
	Market.updateCurrentItems()
end

local function onChangeOfferType(combobox, option)
	local item = selectedItem.item
	local maximum = item.thingType:isStackable() and MarketMaxAmountStackable or MarketMaxAmount

	if option == "Sell" then
		maximum = math.min(maximum, Market.getDepotCount(item.marketData.tradeAs, getMarketItemTier(item)))

		amountEdit:setMaximum(maximum)
	else
		amountEdit:setMaximum(maximum)
	end
end

local function onTotalPriceChange()
	local amount = amountEdit:getValue()
	local totalPrice = totalPriceEdit:getValue()
	local piecePrice = math.floor(totalPrice / amount)

	piecePriceEdit:setValue(piecePrice, true)

	if Market.isItemSelected() then
		updateFee(piecePrice, amount)
	end
end

local function onPiecePriceChange()
	local amount = amountEdit:getValue()
	local totalPrice = totalPriceEdit:getValue()
	local piecePrice = piecePriceEdit:getValue()

	totalPriceEdit:setValue(piecePrice * amount, true)

	if Market.isItemSelected() then
		updateFee(piecePrice, amount)
	end
end

local function onAmountChange()
	local amount = amountEdit:getValue()
	local piecePrice = piecePriceEdit:getValue()
	local totalPrice = piecePrice * amount

	totalPriceEdit:setValue(piecePrice * amount, true)

	if Market.isItemSelected() then
		updateFee(piecePrice, amount)
	end
end

local function onMarketMessage(messageMode, message)
	Market.displayMessage(message)
end

local function initMarketItems(items)
	for c = MarketCategory.First, MarketCategory.Last do
		marketItems[c] = {}
	end

	marketItemNames = {}
	local itemSet = {}

	if items then
		for _, entry in ipairs(items) do
			local item = Item.create(entry.id)
			local thingType = g_things.getThingType(entry.id, ThingCategoryItem)
			local tier = math.max(0, math.min(10, tonumber(entry.tier) or 0))
			local itemKey = getDepotItemKey(entry.id, tier)

			if item and thingType and not itemSet[itemKey] then
				setDisplayItemTier(item, tier)
				local marketItem = {
					displayItem = item,
					thingType = thingType,
					marketData = {
						requiredLevel = 0,
						restrictVocation = 0,
						name = entry.name,
						category = entry.category,
						showAs = entry.id,
						tradeAs = entry.id,
						tier = tier
					}
				}

				if marketItems[entry.category] ~= nil then
					table.insert(marketItems[entry.category], marketItem)

					marketItemNames[entry.id] = entry.name
					itemSet[itemKey] = true
				end
			end
		end

		Market.updateCategories()

		return
	end

	local types = g_things.findThingTypeByAttr(ThingAttrMarket, 0)

	for i = 1, #types do
		local itemType = types[i]
		local item = Item.create(itemType:getId())

		if item then
			local marketData = itemType:getMarketData()

			if not table.empty(marketData) and not itemSet[marketData.tradeAs] then
				item:setId(marketData.showAs)

				local marketItem = {
					displayItem = item,
					thingType = itemType,
					marketData = marketData
				}

				if marketItems[marketData.category] ~= nil then
					table.insert(marketItems[marketData.category], marketItem)

					itemSet[marketData.tradeAs] = true
				end
			end
		end
	end
end

local function initInterface()
	mainTabBar = marketWindow:getChildById("mainTabBar")

	mainTabBar:setContentWidget(marketWindow:getChildById("mainTabContent"))

	marketOffersPanel = g_ui.loadUI("ui/marketoffers")

	mainTabBar:addTab(tr("Market Offers"), marketOffersPanel)

	selectionTabBar = marketOffersPanel:getChildById("leftTabBar")

	selectionTabBar:setContentWidget(marketOffersPanel:getChildById("leftTabContent"))

	browsePanel = g_ui.loadUI("ui/marketoffers/browse")

	selectionTabBar:addTab(tr("Browse"), browsePanel)

	displaysTabBar = marketOffersPanel:getChildById("rightTabBar")

	displaysTabBar:setContentWidget(marketOffersPanel:getChildById("rightTabContent"))

	itemStatsPanel = g_ui.loadUI("ui/marketoffers/itemstats")

	displaysTabBar:addTab(tr("Statistics"), itemStatsPanel)

	itemDetailsPanel = g_ui.loadUI("ui/marketoffers/itemdetails")

	displaysTabBar:addTab(tr("Details"), itemDetailsPanel)

	itemOffersPanel = g_ui.loadUI("ui/marketoffers/itemoffers")

	displaysTabBar:addTab(tr("Offers"), itemOffersPanel)
	displaysTabBar:selectTab(displaysTabBar:getTab(tr("Offers")))

	myOffersPanel = g_ui.loadUI("ui/myoffers")
	local myOffersTab = mainTabBar:addTab(tr("My Offers"), myOffersPanel)
	offersTabBar = myOffersPanel:getChildById("offersTabBar")

	offersTabBar:setContentWidget(myOffersPanel:getChildById("offersTabContent"))

	currentOffersPanel = g_ui.loadUI("ui/myoffers/currentoffers")
	myCurrentOffersTab = offersTabBar:addTab(tr("Current Offers"), currentOffersPanel)
	offerHistoryPanel = g_ui.loadUI("ui/myoffers/offerhistory")
	myOfferHistoryTab = offersTabBar:addTab(tr("Offer History"), offerHistoryPanel)
	balanceLabel = marketWindow:getChildById("balanceLabel")

	function mainTabBar.onTabChange(widget, tab)
		if tab == myOffersTab then
			local ctab = offersTabBar:getCurrentTab()

			if ctab == myCurrentOffersTab then
				Market.refreshMyOffers()
			elseif ctab == myOfferHistoryTab then
				Market.refreshMyOffersHistory()
			end
		else
			Market.refreshOffers()
		end
	end

	function offersTabBar.onTabChange(widget, tab)
		if tab == myCurrentOffersTab then
			Market.refreshMyOffers()
		elseif tab == myOfferHistoryTab then
			Market.refreshMyOffersHistory()
		end
	end

	buyButton = itemOffersPanel:getChildById("buyButton")

	function buyButton.onClick()
		openAmountWindow(Market.acceptMarketOffer, MarketAction.Buy, "Buy")
	end

	sellButton = itemOffersPanel:getChildById("sellButton")

	function sellButton.onClick()
		openAmountWindow(Market.acceptMarketOffer, MarketAction.Sell, "Sell")
	end

	nameLabel = marketOffersPanel:getChildById("nameLabel")
	selectedItem = marketOffersPanel:getChildById("selectedItem")
	totalPriceEdit = marketOffersPanel:getChildById("totalPriceEdit")
	piecePriceEdit = marketOffersPanel:getChildById("piecePriceEdit")
	amountEdit = marketOffersPanel:getChildById("amountEdit")
	feeLabel = marketOffersPanel:getChildById("feeLabel")
	totalPriceEdit.onValueChange = onTotalPriceChange
	piecePriceEdit.onValueChange = onPiecePriceChange
	amountEdit.onValueChange = onAmountChange
	offerTypeList = marketOffersPanel:getChildById("offerTypeComboBox")
	offerTypeList.onOptionChange = onChangeOfferType
	anonymous = marketOffersPanel:getChildById("anonymousCheckBox")
	createOfferButton = marketOffersPanel:getChildById("createOfferButton")
	createOfferButton.onClick = Market.createNewOffer

	Market.enableCreateOffer(false)

	filterButtons[MarketFilters.Vocation] = browsePanel:getChildById("filterVocation")
	filterButtons[MarketFilters.Level] = browsePanel:getChildById("filterLevel")
	filterButtons[MarketFilters.Depot] = browsePanel:getChildById("filterDepot")
	filterButtons[MarketFilters.SearchAll] = browsePanel:getChildById("filterSearchAll")

	clearFilters()

	for _, filter in pairs(filterButtons) do
		filter.onCheckChange = Market.updateCurrentItems
	end

	searchEdit = browsePanel:getChildById("searchEdit")
	categoryList = browsePanel:getChildById("categoryComboBox")
	subCategoryList = browsePanel:getChildById("subCategoryComboBox")
	slotFilterList = browsePanel:getChildById("slotComboBox")

	slotFilterList:addOption(MarketSlotFilters[255])
	slotFilterList:setEnabled(false)
	Market.updateCategories()

	categoryList.onOptionChange = onChangeCategory
	subCategoryList.onOptionChange = onChangeSubCategory
	slotFilterList.onOptionChange = onChangeSlotFilter
	buyOfferTable = itemOffersPanel:recursiveGetChildById("buyingTable")
	sellOfferTable = itemOffersPanel:recursiveGetChildById("sellingTable")
	detailsTable = itemDetailsPanel:recursiveGetChildById("detailsTable")
	buyStatsTable = itemStatsPanel:recursiveGetChildById("buyStatsTable")
	sellStatsTable = itemStatsPanel:recursiveGetChildById("sellStatsTable")
	buyOfferTable.onSelectionChange = onSelectBuyOffer
	sellOfferTable.onSelectionChange = onSelectSellOffer
	buyMyOfferTable = currentOffersPanel:recursiveGetChildById("myBuyingTable")
	sellMyOfferTable = currentOffersPanel:recursiveGetChildById("mySellingTable")
	myOfferHistoryTabel = offerHistoryPanel:recursiveGetChildById("myHistoryTable")
	buyMyOfferTable.onSelectionChange = onSelectMyBuyOffer
	sellMyOfferTable.onSelectionChange = onSelectMySellOffer
	buyCancelButton = currentOffersPanel:getChildById("buyCancelButton")

	function buyCancelButton.onClick()
		cancelMyOffer(MarketAction.Buy)
	end

	sellCancelButton = currentOffersPanel:getChildById("sellCancelButton")

	function sellCancelButton.onClick()
		cancelMyOffer(MarketAction.Sell)
	end

	buyStatsTable:setColumnWidth({
		120,
		270
	})
	sellStatsTable:setColumnWidth({
		120,
		270
	})
	detailsTable:setColumnWidth({
		120,
		290
	})
	buyOfferTable:setSorting(4, TABLE_SORTING_DESC)
	sellOfferTable:setSorting(4, TABLE_SORTING_ASC)
	buyMyOfferTable:setSorting(3, TABLE_SORTING_DESC)
	sellMyOfferTable:setSorting(3, TABLE_SORTING_DESC)
	myOfferHistoryTabel:setSorting(6, TABLE_SORTING_DESC)
end

function init()
	g_ui.importStyle("market")
	g_ui.importStyle("ui/general/markettabs")
	g_ui.importStyle("ui/general/marketbuttons")
	g_ui.importStyle("ui/general/marketcombobox")
	g_ui.importStyle("ui/general/amountwindow")

	offerExhaust[MarketAction.Sell] = 10
	offerExhaust[MarketAction.Buy] = 20

	registerMessageMode(MessageModes.Market, onMarketMessage)
	protocol.initProtocol()
	connect(g_game, {
		onGameEnd = Market.reset
	})
	connect(g_game, {
		onGameEnd = Market.close
	})
	connect(g_game, {
		onGameStart = Market.updateCategories
	})
	connect(g_game, {
		onCoinBalance = Market.onCoinBalance
	})

	marketWindow = g_ui.createWidget("MarketWindow", rootWidget)

	marketWindow:hide()
	initInterface()
end

function terminate()
	Market.close()
	unregisterMessageMode(MessageModes.Market, onMarketMessage)
	protocol.terminateProtocol()
	disconnect(g_game, {
		onGameEnd = Market.reset
	})
	disconnect(g_game, {
		onGameEnd = Market.close
	})
	disconnect(g_game, {
		onGameStart = Market.updateCategories
	})
	disconnect(g_game, {
		onCoinBalance = Market.onCoinBalance
	})
	destroyAmountWindow()
	marketWindow:destroy()

	Market = nil
end

function Market.reset()
	balanceLabel:setColor("#bbbbbb")
	categoryList:setCurrentOption(getMarketCategoryName(MarketCategory.First))
	searchEdit:setText("")
	clearFilters()
	clearMyOffers()

	if not table.empty(information) then
		Market.updateCurrentItems()
	end
end

function Market.updateCategories()
	categoryList:clearOptions()
	subCategoryList:clearOptions()

	local categories = {}
	local addedCategories = {}

	for _, c in ipairs(g_things.getMarketCategories()) do
		table.insert(categories, getMarketCategoryName(c) or "Unknown")

		addedCategories[c] = true
	end

	for c, items in ipairs(marketItems) do
		if #items > 0 and not addedCategories[c] then
			table.insert(categories, getMarketCategoryName(c) or "Unknown")

			addedCategories[c] = true
		end
	end

	table.sort(categories)

	for _, c in ipairs(categories) do
		categoryList:addOption(c)
	end

	for i = MarketCategory.Ammunition, MarketCategory.WandsRods do
		subCategoryList:addOption(getMarketCategoryName(i))
	end

	categoryList:addOption(getMarketCategoryName(255))
	categoryList:setCurrentOption(getMarketCategoryName(MarketCategory.First))
	subCategoryList:setEnabled(false)
end

function Market.displayMessage(message)
	if marketWindow:isHidden() then
		return
	end

	local infoBox = displayInfoBox(tr("Market Error"), message)

	infoBox:lock()
end

function Market.clearSelectedItem()
	if Market.isItemSelected() then
		Market.resetCreateOffer(true)
		offerTypeList:clearOptions()
		offerTypeList:setText("Please Select")
		offerTypeList:setEnabled(false)
		clearOffers()
		radioItemSet:selectWidget(nil)
		nameLabel:setText("No item selected.")
		selectedItem:setItem(nil)
		ItemsDatabase.setTier(selectedItem, nil)

		selectedItem.item = nil

		selectedItem.ref:setChecked(false)

		selectedItem.ref = nil

		detailsTable:clearData()
		buyStatsTable:clearData()
		sellStatsTable:clearData()
		Market.enableCreateOffer(false)
	end
end

function Market.isItemSelected()
	return selectedItem and selectedItem.item
end

function Market.isOfferSelected(type)
	return selectedOffer[type] and not selectedOffer[type]:isNull()
end

function Market.getDepotCount(itemId, tier)
	if not information.depotItems then
		return 0
	end

	if tier ~= nil then
		return information.depotItems[getDepotItemKey(itemId, tier)] or 0
	end
	return information.depotItems[itemId] or 0
end

function Market.enableCreateOffer(enable)
	offerTypeList:setEnabled(enable)
	totalPriceEdit:setEnabled(enable)
	piecePriceEdit:setEnabled(enable)
	amountEdit:setEnabled(enable)
	anonymous:setEnabled(enable)
	createOfferButton:setEnabled(enable)

	local prevAmountButton = marketOffersPanel:recursiveGetChildById("prevAmountButton")
	local nextAmountButton = marketOffersPanel:recursiveGetChildById("nextAmountButton")

	prevAmountButton:setEnabled(enable)
	nextAmountButton:setEnabled(enable)
end

function Market.close(notify)
	if notify == nil then
		notify = true
	end

	if not marketWindow:isHidden() then
		marketWindow:hide()
		marketWindow:unlock()
		modules.game_interface.getRootPanel():focus()
		Market.clearSelectedItem()
		Market.reset()

		if notify then
			MarketProtocol.sendMarketLeave()
		end
	end
end

function Market.incrementAmount()
	amountEdit:setValue(amountEdit:getValue() + 1)
end

function Market.decrementAmount()
	amountEdit:setValue(amountEdit:getValue() - 1)
end

function Market.updateCurrentItems()
	if not categoryList or not categoryList:getCurrentOption() then
		return
	end

	local id = getMarketCategoryId(categoryList:getCurrentOption().text)

	if id == MarketCategory.MetaWeapons then
		id = getMarketCategoryId(subCategoryList:getCurrentOption().text)
	end

	Market.loadMarketItems(id)
end

function Market.resetCreateOffer(resetFee)
	piecePriceEdit:setValue(1)
	totalPriceEdit:setValue(1)
	amountEdit:setValue(1)
	refreshTypeList()

	if resetFee then
		clearFee()
	else
		updateFee(0, 0)
	end
end

function Market.refreshItemsWidget(selectItem)
	local selectItem = selectItem or 0
	itemsPanel = browsePanel:recursiveGetChildById("itemsPanel")
	local layout = itemsPanel:getLayout()

	layout:disableUpdates()
	Market.clearSelectedItem()
	itemsPanel:destroyChildren()

	if radioItemSet then
		radioItemSet:destroy()
	end

	radioItemSet = UIRadioGroup.create()
	local select = nil

	for i = 1, #currentItems do
		local item = currentItems[i]
		local itemBox = g_ui.createWidget("MarketItemBox", itemsPanel)
		itemBox.onCheckChange = Market.onItemBoxChecked
		itemBox.item = item
		local tier = getMarketItemTier(item)
		local itemKey = getDepotItemKey(item.marketData.tradeAs, tier)

		if (type(selectItem) == "number" and selectItem > 0 and item.marketData.tradeAs == selectItem) or selectItem == itemKey then
			select = itemBox
			selectItem = 0
		end

		local itemWidget = itemBox:getChildById("item")
		setDisplayItemTier(item.displayItem, tier)

		itemWidget:setItem(item.displayItem)
		ItemsDatabase.setTier(itemWidget, item.displayItem)

		local amount = Market.getDepotCount(item.marketData.tradeAs, tier)

		if amount > 0 then
			itemWidget:setText(comma_value(amount))
			itemBox:setTooltip("You have " .. amount .. " in your depot.")
		end

		radioItemSet:addWidget(itemBox)
	end

	if select then
		radioItemSet:selectWidget(select, false)
		updateSelectedItem(select)
	end

	layout:enableUpdates()
	layout:update()
end

function Market.refreshOffers()
	if Market.isItemSelected() then
		Market.onItemBoxChecked(selectedItem.ref)
	else
		local ctab = offersTabBar:getCurrentTab()

		if ctab == myCurrentOffersTab then
			Market.refreshMyOffers()
		elseif ctab == myOfferHistoryTab then
			Market.refreshMyOffersHistory()
		end
	end
end

function Market.refreshMyOffers()
	clearMyOffers()
	MarketProtocol.sendMarketBrowseMyOffers()
end

function Market.refreshMyOffersHistory()
	clearMyOffers()
	MarketProtocol.sendMarketBrowseMyHistory()
end

function Market.loadMarketItems(category)
	clearItems()

	local searchFilter = searchEdit:getText()

	if searchFilter and searchFilter:len() > 2 and filterButtons[MarketFilters.SearchAll]:isChecked() then
		category = MarketCategory.All
	end

	if not marketItems[category] and category ~= MarketCategory.All then
		return
	end

	if category == MarketCategory.All then
		for category = MarketCategory.First, MarketCategory.Last do
			if marketItems[category] then
				for i = 1, #marketItems[category] do
					local item = marketItems[category][i]

					if isItemValid(item, category, searchFilter) then
						table.insert(currentItems, item)
					end
				end
			end
		end
	else
		for i = 1, #marketItems[category] do
			local item = marketItems[category][i]

			if isItemValid(item, category, searchFilter) then
				table.insert(currentItems, item)
			end
		end
	end

	Market.refreshItemsWidget()
end

function Market.createNewOffer()
	local type = offerTypeList:getCurrentOption().text

	if type == "Sell" then
		type = MarketAction.Sell
	else
		type = MarketAction.Buy
	end

	if not Market.isItemSelected() then
		return
	end

	local spriteId = selectedItem.item.marketData.tradeAs
	local tier = getMarketItemTier(selectedItem.item)
	local piecePrice = piecePriceEdit:getValue()
	local amount = amountEdit:getValue()
	local anonymous = anonymous:isChecked() and 1 or 0
	local errorMsg = ""

	if type == MarketAction.Buy then
		if information.balance < piecePrice * amount + fee then
			errorMsg = errorMsg .. "Not enough balance to create this offer.\n"
		end
	elseif type == MarketAction.Sell then
		if information.balance < fee then
			errorMsg = errorMsg .. "Not enough balance to create this offer.\n"
		end

		if Market.getDepotCount(spriteId, tier) < amount then
			errorMsg = errorMsg .. "Not enough items in your depot to create this offer.\n"
		end
	end

	if piecePriceEdit.maximum < piecePrice then
		errorMsg = errorMsg .. "Price is too high.\n"
	elseif piecePrice < piecePriceEdit.minimum then
		errorMsg = errorMsg .. "Price is too low.\n"
	end

	if amountEdit.maximum < amount then
		errorMsg = errorMsg .. "Amount is too high.\n"
	elseif amount < amountEdit.minimum then
		errorMsg = errorMsg .. "Amount is too low.\n"
	end

	if MarketMaxPrice < amount * piecePrice then
		errorMsg = errorMsg .. "Total price is too high.\n"
	end

	if MarketMaxOffers <= information.totalOffers then
		errorMsg = errorMsg .. "You cannot create more offers.\n"
	end

	local timeCheck = os.time() - lastCreatedOffer

	if timeCheck < offerExhaust[type] then
		local waitTime = math.ceil(offerExhaust[type] - timeCheck)
		errorMsg = errorMsg .. "You must wait " .. waitTime .. " seconds before creating a new offer.\n"
	end

	if errorMsg ~= "" then
		Market.displayMessage(errorMsg)

		return
	end

	MarketProtocol.sendMarketCreateOffer(type, spriteId, amount, piecePrice, anonymous, tier)

	lastCreatedOffer = os.time()

	Market.resetCreateOffer()
end

function Market.acceptMarketOffer(amount, timestamp, counter)
	if timestamp > 0 and amount > 0 then
		MarketProtocol.sendMarketAcceptOffer(timestamp, counter, amount)
		Market.refreshOffers()
	end
end

function Market.onItemBoxChecked(widget)
	if widget:isChecked() then
		updateSelectedItem(widget)
	end
end

function Market.onMarketEnter(depotItems, offers, balance, vocation, items, depotItemTiers)
	if not loaded or items and #items > 0 then
		initMarketItems(items)

		loaded = true
	end

	updateBalance(balance)

	averagePrice = 0
	information.totalOffers = offers
	local player = g_game.getLocalPlayer()

	if player then
		information.player = player
	end

	if vocation == -1 then
		if player then
			information.vocation = player:getVocation()
		end
	else
		information.vocation = vocation
	end

	information.depotItems = depotItems
	information.depotItemTiers = depotItemTiers or {}

	for i = 1, #marketItems[MarketCategory.TibiaCoins] do
		local item = marketItems[MarketCategory.TibiaCoins][i].displayItem
		depotItems[item:getId()] = tibiaCoins
		depotItems[getDepotItemKey(item:getId(), 0)] = tibiaCoins
	end

	if Market.isItemSelected() then
		local spriteId = selectedItem.item.marketData.tradeAs
		local selectedKey = getDepotItemKey(spriteId, getMarketItemTier(selectedItem.item))

		MarketProtocol.silent(true)
		Market.refreshItemsWidget(selectedKey)
		MarketProtocol.silent(false)
	else
		Market.refreshItemsWidget()
	end

	if table.empty(currentItems) then
		Market.loadMarketItems(MarketCategory.First)
	end

	if g_game.isOnline() then
		marketWindow:show()
	end
end

function Market.onMarketLeave()
	Market.close(false)
end

function Market.onMarketDetail(itemId, descriptions, purchaseStats, saleStats)
	updateDetails(itemId, descriptions, purchaseStats, saleStats)
end

function Market.onMarketBrowse(offers, offersType)
	if offersType == MarketRequest.MyHistory then
		updateHistoryOffers(offers)
	else
		updateOffers(offers)
	end
end

function Market.onCoinBalance(coins, transferableCoins)
	tibiaCoins = coins

	if not information.depotItems or not marketItems[MarketCategory.TibiaCoins] then
		return
	end

	for i = 1, #marketItems[MarketCategory.TibiaCoins] do
		local item = marketItems[MarketCategory.TibiaCoins][i].displayItem
		information.depotItems[item:getId()] = tibiaCoins
		information.depotItems[getDepotItemKey(item:getId(), 0)] = tibiaCoins
	end
end
