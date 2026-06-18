UI.Separator()

function sum(t)
	local sum = 0
	for k,v in pairs(t) do
		sum = sum + v
	end
	return sum
end

local a = {}
local oldTime = now
onTextMessage(function(mode, text)
	if string.find(text, "due to your attack") then
		table.insert(a, tonumber(string.match(text, "%d+")))

		if storage.DPS then
			if now - oldTime > 1000 then
				sumOfA = sum(a)
				storage.DPS = sumOfA
				a = {}
				oldTime = now
			end
		else
			storage.DPS = 0
		end

		if storage.highestDamage then
			damageDone = tonumber(string.match(text, "%d+"))
			if damageDone > storage.highestDamage then
				storage.highestDamage = damageDone
			end
		else
			storage.highestDamage = 0
		end
	end
end)

-- Modificar Aqui

local DMGLabel = setupUI([[
Panel
  width: 1920
  height: 1080

  Label
    id: DMG
    color: orange
    font: verdana-11px-rounded
    height: 12
    background-color: #00000044
    text-auto-resize: true
]], modules.game_interface.getMapPanel())

local DPSLabel = setupUI([[
Panel
  width: 1920
  height: 1080

  Label
    id: DPS
    color: orange
    font: verdana-11px-rounded
    height: 12
    background-color: #00000044
    text-auto-resize: true
]], modules.game_interface.getMapPanel())

-- Fin Panels

DMGLabel.DMG:setPosition({x = 1570, y = 160})
DPSLabel.DPS:setPosition({x = 1570, y = 175})

macro(100, function()
	if storage.highestDamage then
		DMGLabel.DMG:setText("Highest DMG: ".. storage.highestDamage)
	end

	if storage.DPS then
		DPSLabel.DPS:setText("DPS: ".. storage.DPS)
	end
end)