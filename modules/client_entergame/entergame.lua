EnterGame = {}
local loadBox, enterGame, enterGameButton, logpass, clientBox, protocolLogin, server = nil
local versionsFound = false
local serverSelector, serverHostTextEdit, rememberPasswordBox = nil
local motdWindow = nil
local motdEnabled = true
local protos = {
	"740",
	"760",
	"772",
	"792",
	"800",
	"810",
	"854",
	"860",
	"870",
	"910",
	"961",
	"1000",
	"1077",
	"1090",
	"1096",
	"1098",
	"1099",
	"1100",
	"1200",
	"1220"
}
local checkedByUpdater = {}
local waitingForHttpResults = 0

local function onProtocolError(protocol, message, errorCode)
	if errorCode then
		return EnterGame.onError(message)
	end

	return EnterGame.onLoginError(message)
end

local function onSessionKey(protocol, sessionKey)
	G.sessionKey = sessionKey
end

local function onMotd(protocol, motd)
	if type(motd) ~= "string" or #motd == 0 then
		G.motdNumber = nil
		G.motdMessage = nil

		return
	end

	local separator = motd:find("\n", 1, true)

	if separator then
		G.motdNumber = tonumber(motd:sub(1, separator - 1))
		G.motdMessage = motd:sub(separator + 1)
	else
		G.motdNumber = tonumber(motd)
		G.motdMessage = motd
	end
end

local function onCharacterList(protocol, characters, account, otui)
	if rememberPasswordBox:isChecked() then
		local account = g_crypt.encrypt(G.account)
		local password = g_crypt.encrypt(G.password)

		g_settings.set("account", account)
		g_settings.set("password", password)
	else
		EnterGame.clearAccountFields()
	end

	for _, characterInfo in pairs(characters) do
		if characterInfo.previewState and characterInfo.previewState ~= PreviewState.Default then
			characterInfo.worldName = characterInfo.worldName .. ", Preview"
		end
	end

	if loadBox then
		loadBox:destroy()

		loadBox = nil
	end

	CharacterList.create(characters, account, otui)
	CharacterList.show()

	if motdEnabled then
		local lastMotdNumber = g_settings.getNumber("motd")

		if G.motdNumber and G.motdNumber ~= lastMotdNumber and G.motdMessage and #G.motdMessage > 0 then
			g_settings.set("motd", G.motdNumber)
			motdWindow = displayInfoBox(tr("Message of the day"), G.motdMessage)

			connect(motdWindow, {
				onOk = function ()
					CharacterList.show()
					motdWindow = nil
				end
			})

			CharacterList.hide()
		end
	end

	g_settings.save()
end

local function onUpdateNeeded(protocol, signature)
	return EnterGame.onError(tr("Your client needs updating, try redownloading it."))
end

local function onProxyList(protocol, proxies)
	for _, proxy in ipairs(proxies) do
		g_proxy.addProxy(proxy.host, proxy.port, proxy.priority)
	end
end

local function parseFeatures(features)
	for feature_id, value in pairs(features) do
		if value == "1" or value == "true" or value == true then
			g_game.enableFeature(feature_id)
		else
			g_game.disableFeature(feature_id)
		end
	end
end

local function validateThings(things)
	local incorrectThings = ""
	local missingFiles = false
	local versionForMissingFiles = 0

	if things ~= nil then
		local thingsNode = {}

		for thingtype, thingdata in pairs(things) do
			thingsNode[thingtype] = thingdata[1]

			if not g_resources.fileExists("/things/" .. thingdata[1]) then
				incorrectThings = incorrectThings .. "Missing file: " .. thingdata[1] .. "\n"
				missingFiles = true
				versionForMissingFiles = thingdata[1]:split("/")[1]
			else
				local localChecksum = g_resources.fileChecksum("/things/" .. thingdata[1]):lower()

				if localChecksum ~= thingdata[2]:lower() and #thingdata[2] > 1 and g_resources.isLoadedFromArchive() then
					incorrectThings = incorrectThings .. "Invalid checksum of file: " .. thingdata[1] .. " (is " .. localChecksum .. ", should be " .. thingdata[2]:lower() .. ")\n"
				end
			end
		end

		g_settings.setNode("things", thingsNode)
	else
		g_settings.setNode("things", {})
	end

	if missingFiles then
		incorrectThings = incorrectThings .. "\nYou should open data/things and create directory " .. versionForMissingFiles .. ".\nIn this directory (data/things/" .. versionForMissingFiles .. ") you should put missing\nfiles (Tibia.dat and Tibia.spr/Tibia.cwm) " .. "from correct Tibia version."
	end

	return incorrectThings
end

local function onTibia12HTTPResult(session, playdata)
	local characters = {}
	local worlds = {}
	local account = {
		subStatus = 0,
		premDays = 0,
		status = 0
	}

	if session.status ~= "active" then
		account.status = 1
	end

	if session.ispremium then
		account.subStatus = 1
	end

	if g_clock.seconds() < session.premiumuntil then
		account.subStatus = math.floor((session.premiumuntil - g_clock.seconds()) / 86400)
	end

	local things = {
		data = {
			G.clientVersion .. "/Tibia.dat",
			""
		},
		sprites = {
			G.clientVersion .. "/Tibia.cwm",
			""
		}
	}
	local incorrectThings = validateThings(things)

	if #incorrectThings > 0 then
		things = {
			data = {
				G.clientVersion .. "/Tibia.dat",
				""
			},
			sprites = {
				G.clientVersion .. "/Tibia.spr",
				""
			}
		}
		incorrectThings = validateThings(things)
	end

	if #incorrectThings > 0 then
		g_logger.error(incorrectThings)

		if Updater and not checkedByUpdater[G.clientVersion] then
			checkedByUpdater[G.clientVersion] = true

			return Updater.check({
				version = G.clientVersion,
				host = G.host
			})
		else
			return EnterGame.onError(incorrectThings)
		end
	end

	onSessionKey(nil, session.sessionkey)

	for _, world in pairs(playdata.worlds) do
		worlds[world.id] = {
			name = world.name,
			port = world.externalportunprotected or world.externalportprotected or world.externaladdress,
			address = world.externaladdressunprotected or world.externaladdressprotected or world.externalport
		}
	end

	for _, character in pairs(playdata.characters) do
		local world = worlds[character.worldid]

		if world then
			table.insert(characters, {
				name = character.name,
				worldName = world.name,
				worldIp = world.address,
				worldPort = world.port
			})
		end
	end

	if g_proxy then
		g_proxy.clear()

		if playdata.proxies then
			for i, proxy in ipairs(playdata.proxies) do
				g_proxy.addProxy(proxy.host, tonumber(proxy.port), tonumber(proxy.priority))
			end
		end
	end

	g_game.setCustomProtocolVersion(0)
	g_game.chooseRsa(G.host)
	g_game.setClientVersion(G.clientVersion)
	g_game.setProtocolVersion(g_game.getClientProtocolVersion(G.clientVersion))
	g_game.setCustomOs(-1)

	if not g_game.getFeature(GameExtendedOpcode) then
		g_game.setCustomOs(5)
	end

	onCharacterList(nil, characters, account, nil)
end

local function onHTTPResult(data, err)
	if waitingForHttpResults == 0 then
		return
	end

	waitingForHttpResults = waitingForHttpResults - 1

	if err and waitingForHttpResults > 0 then
		return
	end

	if err then
		return EnterGame.onError(err)
	end

	waitingForHttpResults = 0

	if data.error and data.error:len() > 0 then
		return EnterGame.onLoginError(data.error)
	elseif data.errorMessage and data.errorMessage:len() > 0 then
		return EnterGame.onLoginError(data.errorMessage)
	end

	if type(data.session) == "table" and type(data.playdata) == "table" then
		return onTibia12HTTPResult(data.session, data.playdata)
	end

	local characters = data.characters
	local account = data.account
	local session = data.session
	local version = data.version
	local things = data.things
	local customProtocol = data.customProtocol
	local features = data.features
	local settings = data.settings
	local rsa = data.rsa
	local proxies = data.proxies
	local incorrectThings = validateThings(things)

	if #incorrectThings > 0 then
		g_logger.info(incorrectThings)

		return EnterGame.onError(incorrectThings)
	end

	g_game.setCustomProtocolVersion(0)

	if customProtocol ~= nil then
		customProtocol = tonumber(customProtocol)

		if customProtocol ~= nil and customProtocol > 0 then
			g_game.setCustomProtocolVersion(customProtocol)
		end
	end

	if settings ~= nil then
		for option, value in pairs(settings) do
			modules.client_options.setOption(option, value, true)
		end
	end

	G.clientVersion = version

	g_game.setClientVersion(version)
	g_game.setProtocolVersion(g_game.getClientProtocolVersion(version))
	g_game.setCustomOs(-1)

	if rsa ~= nil then
		g_game.setRsa(rsa)
	end

	if features ~= nil then
		parseFeatures(features)
	end

	if session ~= nil and session:len() > 0 then
		onSessionKey(nil, session)
	end

	if g_proxy then
		g_proxy.clear()

		if proxies then
			for i, proxy in ipairs(proxies) do
				g_proxy.addProxy(proxy.host, tonumber(proxy.port), tonumber(proxy.priority))
			end
		end
	end

	onCharacterList(nil, characters, account, nil)
end

function EnterGame.init()
	if USE_NEW_ENERGAME then
		return
	end

	enterGame = g_ui.displayUI("entergame")

	enterGame:hide()

	if LOGPASS ~= nil then
		logpass = g_ui.loadUI("logpass", enterGame:getParent())
	end

	rememberPasswordBox = enterGame:getChildById("rememberPasswordBox")
	local account = g_crypt.decrypt(g_settings.get("account"))
	local password = g_crypt.decrypt(g_settings.get("password"))
	local server = g_settings.get("server")
	local host = g_settings.get("host")

	enterGame:getChildById("accountPasswordTextEdit"):setText(password)
	enterGame:getChildById("accountNameTextEdit"):setText(account)
	rememberPasswordBox:setChecked(#account > 0)
	g_keyboard.bindKeyDown("Ctrl+G", EnterGame.openWindow)

	if g_game.isOnline() then
		return EnterGame.hide()
	end
end

function EnterGame.terminate()
	if not enterGame then
		return
	end

	g_keyboard.unbindKeyDown("Ctrl+G")

	if logpass then
		logpass:destroy()

		logpass = nil
	end

	enterGame:destroy()

	if loadBox then
		loadBox:destroy()

		loadBox = nil
	end

	if protocolLogin then
		protocolLogin:cancelLogin()

		protocolLogin = nil
	end

	if motdWindow then
		motdWindow:destroy()

		motdWindow = nil
	end

	EnterGame = nil
end

function EnterGame.show()
	if not enterGame then
		return
	end

	if enterGame:isVisible() then
		return
	end

	if CharacterList.isVisible() then
		return
	end

	enterGame:show()
	enterGame:raise()
	enterGame:focus()
	enterGame:getChildById("accountNameTextEdit"):focus()

	if logpass then
		logpass:show()
		logpass:raise()
		logpass:focus()
	end
end

function EnterGame.hide()
	if not enterGame then
		return
	end

	enterGame:hide()

	if logpass then
		logpass:hide()

		if modules.logpass then
			modules.logpass:hide()
		end
	end
end

function EnterGame.openWindow()
	if g_game.isOnline() then
		CharacterList.show()
	elseif not g_game.isLogging() and not CharacterList.isVisible() then
		EnterGame.show()
	end
end

function EnterGame.clearAccountFields()
	enterGame:getChildById("accountNameTextEdit"):clearText()
	enterGame:getChildById("accountPasswordTextEdit"):clearText()
	enterGame:getChildById("accountNameTextEdit"):focus()
	g_settings.remove("account")
	g_settings.remove("password")
end

function EnterGame.onServerChange()
end

function EnterGame.doLogin(account, password, token, host)
	if g_game.isOnline() then
		local errorBox = displayErrorBox(tr("Login Error"), tr("Cannot login while already in game."))

		connect(errorBox, {
			onOk = EnterGame.show
		})

		return
	end

	local server = Server
	G.account = account or enterGame:getChildById("accountNameTextEdit"):getText()
	G.password = password or enterGame:getChildById("accountPasswordTextEdit"):getText()
	G.stayLogged = true
	G.server = name or server.name
	G.host = host or server.host
	G.clientVersion = server.protocol

	if not rememberPasswordBox:isChecked() then
		g_settings.set("account", G.account)
		g_settings.set("password", G.password)
	end

	g_settings.set("host", G.host)
	g_settings.set("server", G.server)
	g_settings.set("client-version", G.clientVersion)
	g_settings.save()

	local things = {
		data = {
			G.clientVersion .. "/Tibia.dat",
			""
		},
		sprites = {
			G.clientVersion .. "/Tibia.cwm",
			""
		}
	}
	local incorrectThings = validateThings(things)

	if #incorrectThings > 0 then
		things = {
			data = {
				G.clientVersion .. "/Tibia.dat",
				""
			},
			sprites = {
				G.clientVersion .. "/Tibia.spr",
				""
			}
		}
		incorrectThings = validateThings(things)
	end

	if #incorrectThings > 0 then
		g_logger.error(incorrectThings)

		if Updater and not checkedByUpdater[G.clientVersion] then
			checkedByUpdater[G.clientVersion] = true

			return Updater.check({
				version = G.clientVersion,
				host = G.host
			})
		else
			return EnterGame.onError(incorrectThings)
		end
	end

	protocolLogin = ProtocolLogin.create()
	protocolLogin.onLoginError = onProtocolError
	protocolLogin.onSessionKey = onSessionKey
	protocolLogin.onCharacterList = onCharacterList
	protocolLogin.onUpdateNeeded = onUpdateNeeded
	protocolLogin.onProxyList = onProxyList
	protocolLogin.onMotd = onMotd

	EnterGame.hide()

	loadBox = displayCancelBox(tr("Please wait"), tr("Connecting to login server..."))

	connect(loadBox, {
		onCancel = function (msgbox)
			loadBox = nil

			protocolLogin:cancelLogin()
			EnterGame.show()
		end
	})

	if G.clientVersion == 1000 then
		G.clientVersion = 1100
	end

	g_game.setClientVersion(G.clientVersion)
	g_game.setProtocolVersion(g_game.getClientProtocolVersion(G.clientVersion))
	g_game.setCustomProtocolVersion(0)
	g_game.setCustomOs(-1)
	g_game.chooseRsa(G.host)

	if g_proxy then
		g_proxy.clear()
	end

	if modules.game_things.isLoaded() then
		g_logger.info("Connecting to: " .. server.host .. ":" .. server.port)
		protocolLogin:login(server.host, server.port, G.account, G.password, G.authenticatorToken, G.stayLogged)
	else
		loadBox:destroy()

		loadBox = nil

		EnterGame.show()
	end
end

function EnterGame.doLoginHttp()
	if G.host == nil or G.host:len() < 10 then
		return EnterGame.onError("Invalid server url: " .. G.host)
	end

	loadBox = displayCancelBox(tr("Please wait"), tr("Connecting to login server..."))

	connect(loadBox, {
		onCancel = function (msgbox)
			loadBox = nil

			EnterGame.show()
		end
	})

	local data = {
		stayloggedin = true,
		type = "login",
		account = G.account,
		accountname = G.account,
		email = G.account,
		password = G.password,
		accountpassword = G.password,
		token = G.authenticatorToken,
		version = APP_VERSION,
		uid = G.UUID
	}
	local server = serverSelector:getText()

	if Servers and Servers[server] ~= nil then
		if type(Servers[server]) == "table" then
			local urls = Servers[server]
			waitingForHttpResults = #urls

			for _, url in ipairs(urls) do
				HTTP.postJSON(url, data, onHTTPResult)
			end
		else
			waitingForHttpResults = 1

			HTTP.postJSON(G.host, data, onHTTPResult)
		end
	end

	EnterGame.hide()
end

function EnterGame.onError(err)
	if loadBox then
		loadBox:destroy()

		loadBox = nil
	end

	local errorBox = displayErrorBox(tr("Login Error"), err)
	errorBox.onOk = EnterGame.show
end

function EnterGame.onLoginError(err)
	if loadBox then
		loadBox:destroy()

		loadBox = nil
	end

	local errorBox = displayErrorBox(tr("Login Error"), err)
	errorBox.onOk = EnterGame.show

	if err:lower():find("invalid") or err:lower():find("not correct") or err:lower():find("or password") then
		EnterGame.clearAccountFields()
	end
end

function EnterGame.displayMotd()
	if not motdWindow and G.motdMessage and #G.motdMessage > 0 then
		motdWindow = displayInfoBox(tr("Message of the day"), G.motdMessage)
		motdWindow.onOk = function ()
			motdWindow = nil
		end
	end
end

function EnterGame.disableMotd()
	motdEnabled = false
end
