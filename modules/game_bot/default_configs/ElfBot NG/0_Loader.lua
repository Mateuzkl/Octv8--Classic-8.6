-- load all otui files, order doesn't matter
local configName = modules.game_bot.contentsPanel.config:getCurrentOption().text

local configFiles = g_resources.listDirectoryFiles("/bot/" .. configName .. "/vBot", true, false)
for i, file in ipairs(configFiles) do
  local ext = file:split(".")
  if ext[#ext]:lower() == "ui" or ext[#ext]:lower() == "otui" then
    g_ui.importStyle(file)
  end
end

local function loadScript(name)
  return dofile("/vBot/" .. name .. ".lua")
end

-- here you can set manually order of scripts
-- libraries should be loaded first
local luaFiles = {
  "main",
  "items",
  "vlib",
  "new_cavebot_lib",
  "configs", -- do not change this and above
  "extras",
  "fbnmodule",
  "cavebot",
  "playerlist",
  "alarms",
  "Conditions",
  "Equipper",
  "HealBot",
  "new_healer",
  "AttackBot", -- last of major modules
  "ingame_editor",
  "Dropper",
  "Containers",
  "quiver_manager",
  "quiver_label",
  "tools",
  "antiRs",
  "depot_withdraw",
  "eat_food",
  "equip",
  "exeta",
  "analyzer",
  "spy_level",
  "supplies",
  "depositer_config",
  "npc_talk",
  "xeno_menu",
  "hold_target",
  "cavebot_control_panel",
  "elfbot_hotkeys",
  "elfbot_layout"
}

for i, file in ipairs(luaFiles) do
    loadScript(file)
end

-- Carrega o PVP externo do perfil para o botao PVP do ElfBot NG.
-- Fica em pcall para nao derrubar o bot se algum client nao tiver uma API usada pelo pvp.lua.
if not ImperialElfBotPvpLoaded then
  local ok, err = pcall(function()
    dofile("/pvp.lua")
  end)
  ImperialElfBotPvpLoaded = ok
  if not ok then
    if modules and modules.game_textmessage and modules.game_textmessage.displayGameMessage then
      modules.game_textmessage.displayGameMessage("PVP nao carregou: " .. tostring(err))
    end
  end
end

setDefaultTab("Main")
local botName = "Scripts"
local lName = UI.Label(botName)

function setRainbowColor(time)
    local r = math.floor(127 * math.sin(time) + 128)
    local g = math.floor(127 * math.sin(time + 2 * math.pi / 3) + 128)
    local b = math.floor(127 * math.sin(time + 4 * math.pi / 3) + 128)
    return string.format("#%02X%02X%02X", r, g, b)
end

macro(10, function()
    local text = '<--- Scripts --->'
    local time = os.clock() * 4
    local coloredText = {}

    for i = 1, #text do
        local char = text:sub(i, i)
        local color = setRainbowColor(time + i * 0.1)
        table.insert(coloredText, char)
        table.insert(coloredText, color)
    end

    if lName and lName.setColoredText then
        lName:setColoredText(coloredText)
    else
        lName:setColor(setRainbowColor(time))
    end
end)
