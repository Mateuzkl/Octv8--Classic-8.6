ImperialElfBot = ImperialElfBot or {}

if modules and modules.game_bot and modules.game_bot.elfbotPendingManualProfileLoad == true then
    modules.game_bot.elfbotProfileLoadedThisSession = true
    modules.game_bot.elfbotPendingManualProfileLoad = nil
end

function ImperialElfBot_IsProfileLoaded()
    return modules and modules.game_bot and modules.game_bot.elfbotProfileLoadedThisSession == true
end

if ImperialElfBot_IsProfileLoaded() then
    modules.game_textmessage.displayGameMessage("ElfBot Loaded")
end
addButton("reloadid", "Load-Bot", function()
    reload()
end)
