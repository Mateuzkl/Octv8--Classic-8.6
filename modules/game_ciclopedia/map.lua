local preloaded, fullmapView, minimapWidget = false, false

function initMap(contentContainer)
	--mapPanel = g_ui.loadUI("styles/map", contentContainer)
	--mapPanel:show()
	
	--minimapWidget = mapPanel:recursiveGetChildById("minimap")
	connect(
        g_game,
        {
            onGameStart = online
        }
    )

    connect(
        LocalPlayer,
        {
            --onPositionChange = updateCameraPosition
        }
    )
	
	if g_game.isOnline() then
        online()
    end
end

function online()
    --loadMap(false)
    --updateCameraPosition()
end


function loadMap(clean)
    local clientVersion = g_game.getClientVersion()

    if clean then
        g_minimap.clean()
    end

    if otmm then
        local minimapFile = "/minimap.otmm"
        if g_resources.fileExists(minimapFile) then
            g_minimap.loadOtmm(minimapFile)
        end
    else
        local minimapFile = "/minimap_" .. clientVersion .. ".otcm"
        if g_resources.fileExists(minimapFile) then
            g_map.loadOtcm(minimapFile)
        end
    end
    minimapWidget:load()
end



function updateCameraPosition()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end
    local pos = player:getPosition()
    if not pos then
        return
    end
    if not minimapWidget:isDragging() then
        if not fullmapView then
            minimapWidget:setCameraPosition(player:getPosition())
        end
        minimapWidget:setCrossPosition(player:getPosition())
    end
end
