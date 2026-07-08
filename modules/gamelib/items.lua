ItemsDatabase = ItemsDatabase or {}

local function clampTier(tier, maxTier)
  tier = tonumber(tier) or 0
  return math.min(math.max(tier, 0), maxTier)
end

function ItemsDatabase.getTierClip(tier, big)
  local width = big and 18 or 9
  local height = big and 16 or 8
  local normalizedTier = clampTier(tier, 10)

  if normalizedTier <= 0 then
    return nil
  end

  return {
    x = (normalizedTier - 1) * width,
    y = 0,
    width = width,
    height = height
  }
end

function ItemsDatabase.setTier(widget, item, big)
  if not widget or not widget.tier then
    return
  end

  if not g_game.getFeature(GameThingUpgradeClassification) and not g_game.getFeature(GameItemTierByte) then
    return
  end

  local tier = 0
  if type(item) == 'number' then
    tier = item
  elseif item and item.getTier then
    local ok, itemTier = pcall(function() return item:getTier() end)
    if ok then
      tier = itemTier or 0
    end
  end

  local clip = ItemsDatabase.getTierClip(tier, big)
  if not clip then
    widget.tier:setVisible(false)
    return
  end

  local size = big and '18 16' or '9 8'
  widget.tier:setImageSource(big and '/images/game/items/tiers-strip-big' or '/images/game/items/tiers-strip')
  widget.tier:setImageClip(clip)
  widget.tier:setImageSize(size)
  widget.tier:setSize(size)
  widget.tier:setVisible(true)
end
