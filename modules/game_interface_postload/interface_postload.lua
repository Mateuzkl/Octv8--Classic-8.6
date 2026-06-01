function init()
	if g_game.isOnline() then
		modules.game_interface.refreshViewMode()
	end
end

function terminate()
end
