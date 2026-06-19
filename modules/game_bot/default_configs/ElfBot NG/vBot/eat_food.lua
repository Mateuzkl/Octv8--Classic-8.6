setDefaultTab("HP")

local function getFoodItemId(foodItem)
    if type(foodItem) == "table" then
        return foodItem.id
    elseif type(foodItem) == "number" then
        return foodItem
    end
    return nil
end

if voc() ~= 1 and voc() ~= 11 then
    if storage.foodItems then
        local t = {}
        for i, v in pairs(storage.foodItems) do
            local foodId = getFoodItemId(v)
            if foodId and not table.find(t, foodId) then
                table.insert(t, foodId)
            end
        end
        local foodItems = { 3607, 3585, 3592, 3600, 3601 }
        for i, item in pairs(foodItems) do
            if not table.find(t, item) then
                table.insert(storage.foodItems, { id = item })
            end
        end
    end
    macro(500, "Cast Food", function()
        if player:getRegenerationTime() <= 400 then
            cast("exevo pan", 5000)
        end
    end)
end

UI.Label("Eatable items:")
if type(storage.foodItems) ~= "table" then
    storage.foodItems = { { id = 3582 }, { id = 3577 } }
else
    for index, foodItem in pairs(storage.foodItems) do
        local foodId = getFoodItemId(foodItem)
        if foodId then
            storage.foodItems[index] = { id = foodId }
        end
    end
end

local foodContainer = UI.Container(function(widget, items)
    storage.foodItems = items
end, true)
foodContainer:setHeight(35)
foodContainer:setItems(storage.foodItems)

macro(15000, "Eat Food", function()
    if player:getRegenerationTime() > 400 or not storage.foodItems[1] then return end
    -- search for food in containers
    for _, container in pairs(g_game.getContainers()) do
        for __, item in ipairs(container:getItems()) do
            for i, foodItem in ipairs(storage.foodItems) do
                if item:getId() == getFoodItemId(foodItem) then
                    return g_game.use(item)
                end
            end
        end
    end
end)
UI.Separator()
