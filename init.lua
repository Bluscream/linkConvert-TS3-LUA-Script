require("ts3init")  
linkConvert = {
	info = {
		name = "Link Converter",
		prefix = "LC",
		folder = "linkConvert",
		ext = "lua",
		ver = "1.0",
		author = "Bluscream",
	},
	setting = { -- Edit below this line! --
		active = true, -- Enable the script.
		debug = true, -- The script shows debug messages.
		onConnect = false, -- Check the client version of every client each time we connect?
	},
	functions = {
		protocols = true, -- Should protocols be reparsed?
		lmgtfy = true, -- Should we allow google'ing etc?
		lmgtfy_prefix = "!",
		updateReminder = true, -- Should clients get a notification message when they use a outdated client?
		offlineMSGReminder = true, -- Shoudl clients get a notification message when they have unread offline messages?
	},		    -- Edit above this line! --
	protocols = { "steam://", "minecraft://", "repz://", "channelid://"},
	var = {
		ownVersion = "3.0.18.2", -- Change this to 0 to use your client's version.
		ownBuild = 1445512488, -- Change this to 0 to use your client's build number.
		requestedclientvars = false,
		requestedclientvarsclid = 0,
	},
	notified = {
		update = {},
		offlinemsg = {},
	},
	-- commands = { "ip" = "http://whatismyipaddress.com/ip/%search%" }
}

local dbg_i = 0
function dbglog(msg)
	if linkConvert.setting.debug then
		dbg_i = dbg_i+1
		ts3.printMessageToCurrentTab("["..dbg_i.."] > [B][U][COLOR=WHITE]"..msg.."[COLOR=WHITE][U][B]")
	end
end

local function mysplit(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end

function informedClients()
	local str = "Outdated Clients: "
	for i=1, #linkConvert.notified.update do
		str = str..linkConvert.notified.update[i]..", "
	end
	ts3.printMessageToCurrentTab(str)
	str = "Unread Offline Messages: "
	for i=1, #linkConvert.notified.offlinemsg do
		str = str..linkConvert.notified.offlinemsg[i]..", "
	end
	ts3.printMessageToCurrentTab(str)
	str = nil;
end
local function reply(sCHID, msg, mode, target)
	oldMSG = msg
	if mode == 1 and target then
		ts3.requestSendPrivateTextMsg(sCHID, msg, target)
	elseif mode == 2 then
		ts3.requestSendChannelTextMsg(sCHID, msg, ts3.getChannelOfClient(sCHID, ts3.getClientID(sCHID)))
	elseif mode == 3 then
		ts3.requestSendServerTextMsg(sCHID, msg)
	else
		ts3.printMessageToCurrentTab(msg)
	end
end

local function lmgtfy(sCHID, message, targetMode, fromID)
	if string.match( message, linkConvert.functions.lmgtfy_prefix ) then
		for i=1, #linkConvert.commands do
			local command = string.match( message, linkConvert.commands[i][1] )	
			local returner = string.match( message, linkConvert.commands[i][2] )	
		end
		local sendMsg = string.gsub( message, "!whois", "" )
	end
end

local function checkClientVersion(sCHID, clientID)
		local clientVersion = ts3.getClientVariableAsString(sCHID, clientID, ts3defs.ClientProperties.CLIENT_VERSION)
		if clientVersion then
			clientVersion = string.gsub(clientVersion, "]", "")
			clientVersion = mysplit(clientVersion, " [Build: ")
			if tonumber(clientVersion[2]) < tonumber(linkConvert.var.ownBuild) then
				local msg = "[b][url=https://r4p3.net/threads/lua-linkconvert-with-update-reminder-and-unread-messages-reminder.1500/]Teamspeak 3 Update reminder[/url] by [url=https://r4p3.net/members/bluscream.53/]Bluscream[/url][/b]"
				msg = msg.."\n\nYou use a outdated Teamspeak 3 Client ([color=red]"..clientVersion[1].."[/color]). You should update your client with \"Help->Check for Update\" or directly on the [URL=http://www.teamspeak.com/downloads#client]Teamspeak website[/URL] to [color=green]"..linkConvert.var.ownVersion.."[/color]."
				msg = msg.."\n\nDu nutzt einen veralteten Teamspeak 3 Client ([color=red]"..clientVersion[1].."[/color]). Du solltest ihn über \"Hilfe->Nach Aktualisierung suchen\" oder direkt über die [URL=http://www.teamspeak.com/downloads#client]Teamspeak Webseite[/URL] auf die Version [color=green]"..linkConvert.var.ownVersion.."[/color] updaten."		
				reply(sCHID, msg, 1, clientID)
				local clientUID = ts3.getClientVariableAsString(sCHID, clientID, ts3defs.ClientProperties.CLIENT_UNIQUE_IDENTIFIER)
				table.insert(linkConvert.notified.update, clientUID)
			end
		end
end

local function checkClientOfflineMSGs(sCHID, clientID)
	local unreadMSGs = ts3.getClientVariableAsInt(sCHID, clientID, ts3defs.ClientProperties.CLIENT_UNREAD_MESSAGES)
	if unreadMSGs then
		if unreadMSGs > 0 then	
			local msg = "[b][url=https://r4p3.net/threads/lua-linkconvert-with-update-reminder-and-unread-messages-reminder.1500/]Teamspeak 3 Offline Message reminder[/url] by [url=https://r4p3.net/members/bluscream.53/]Bluscream[/url][/b]"
			msg = msg.."\n\nYou have [color=red]"..unreadMSGs.."[/color] unread offline messages. Use \"Tools->Offline Messages\" or [CTRL]+[O] to read them."
			msg = msg.."\n\nDu hast [color=red]"..unreadMSGs.."[/color] ungelesene offline Nachrichten. Nutze \"Extras->Offline Nachrichten\" oder [STRG]+[O] um sie zu lesen."
			reply(sCHID, msg, 1, clientID)
			local clientUID = ts3.getClientVariableAsString(sCHID, clientID, ts3defs.ClientProperties.CLIENT_UNIQUE_IDENTIFIER)
			table.insert(linkConvert.notified.offlinemsg, clientUID)
		end
	end
end

local function checkAllClients(sCHID)
	-- Get Self ID
	local myClientID, error = ts3.getClientID(serverConnectionHandlerID)
	if error ~= ts3errors.ERROR_ok then
		print("Error getting own client ID: " .. error)
		return
	end
	if myClientID == 0 then
		ts3.printMessageToCurrentTab("Not connected")
		return
	end
	local clients, error = ts3.getClientList(serverConnectionHandlerID)
	if error == ts3errors.ERROR_not_connected then
		ts3.printMessageToCurrentTab("Not connected")
		return
	elseif error ~= ts3errors.ERROR_ok then
		print("Error getting client list: " .. error)
		return
	end
	for i=1, #clients do
		if clients[i] ~= myClientID then
			checkClient(sCHID, clients[i])
		end
	end

end

local function checkClient(sCHID, clientID)
	if linkConvert.functions.updateReminder then
		local clientUID = ts3.getClientVariableAsString(sCHID, clientID, ts3defs.ClientProperties.CLIENT_UNIQUE_IDENTIFIER) 
		for i=1, #linkConvert.notified.update do
			if clientUID == linkConvert.notified.update[i] then
				dbglog("Ignoring Client "..clientUID.." cause he already got informed about his outdated version.")
				return
			end
		end
		linkConvert.var.requestedclientvarsclid = clientID
		linkConvert.var.requestedclientvars = true
		ts3.requestClientVariables(sCHID, clientID)
	end
	if linkConvert.functions.offlineMSGReminder then
		local clientUID = ts3.getClientVariableAsString(sCHID, clientID, ts3defs.ClientProperties.CLIENT_UNIQUE_IDENTIFIER) 
		for i=1, #linkConvert.notified.offlinemsg do
			if clientUID == linkConvert.notified.offlinemsg[i] then
				dbglog("Ignoring Client "..clientUID.." cause he already got informed about his offline messages.")
				return
			end
		end
		checkClientOfflineMSGs(sCHID, clientID)
	end
end

local function getOwnVersion(sCHID)
	if linkConvert.functions.updateReminder then
		if linkConvert.var.ownBuild == 0 then
			local ownBuild = ts3.getClientLibVersionNumber()
			ownBuild = mysplit(ownBuild, ".")
			linkConvert.var.ownBuild = ownBuild[1]
		end
		if linkConvert.var.ownVersion == 0 then
			local ownVersion = ts3.getClientLibVersion()
			ownVersion = string.gsub(ownVersion, "]", "")
			ownVersion = mysplit(ownVersion, " [Build: ")
			linkConvert.var.ownVersion = ownVersion[1]
		end
	end
end

local function onTextMessageEvent(sCHID, targetMode, toID, fromID, fromName, fromUniqueIdentifier, message, ffIgnored)
	if not oldMSG then oldMSG = "" end
	if linkConvert.setting.active and oldMSG ~= message then
		str = nil
		-- TeamViewer Session
		local str = string.match(message, 's%d%d%-%d%d%d%-%d%d%d') or string.match(message, '%d%d%d% %d%d%d% %d%d%d')
		if str then
			reply(sCHID, "Join TeamViewer session via [url=tvjoinv8://go.teamviewer.com?mid="..str:gsub("%-", "").."]Client[/url] or [url=http://get.teamviewer.com/v11/"..str:gsub("%-", "").."]Web[/url]", targetMode, fromID)
		end
		str = nil
		-- TeamViewer Meeting
		local str = string.match(message, 'm%d%d%-%d%d%d%-%d%d%d')
		if str then
			str = str:gsub("%-", "");str = str:gsub("%s", "");
			reply(sCHID, "Join TeamViewer meeting via [url=tvjoinv8://go.teamviewer.com?mid="..str.."]Client[/url] or [url=https://go.teamviewer.com/v11/flash.aspx?tid="..str.."&lng=de]Web[/url]", targetMode, fromID)
		end
		str = nil
		-- IPs
		local s = string.match(message, '%d+%.%d+%.%d+%.%d+%:%d+'); local s2 = string.match(message, '%d+%.%d+%.%d+%.%d+')
		if s then str = s elseif s2 then str = s2 end
		s = nil; s2 = nil;
		if str then
			reply(sCHID,"[url=http://"..str.."]Web[/url] | [url=ts3server://"..str.."]TS³ Server[/url] |[url=minecraft://"..str.."]MC Server[/url]", 0, fromID)
		end
		str = nil
		-- if linkConvert.function.protocols then
			for i, protocol in ipairs(linkConvert.protocols) do
				if string.match(message, protocol.."[^%s]*") and ts3.getClientID(sCHID) ~= fromID then
					reply(sCHID,"[url]"..string.match(message, protocol.."[^%s]*").."[/url]", targetMode, fromID)
				end
			end
		-- end
		-- if linkConvert.function.lmgtfy then -- LMGTFY
			-- lmgtfy(sCHID, message, targetMode, fromID)
		-- end
	end
	local afkMSG = "Du bist nun seit 15 abwesend. Wenn du 20 Minuten abwesend bist wirst du zu \"Bot - AFK\" verschoben!"
	if message == afkMSG and ts3.getClientID(sCHID) ~= fromID then
		ts3.requestSendPrivateTextMsg(sCHID, "AntiAFK", fromID)
	end
end

local function onConnectStatusChangeEvent(serverConnectionHandlerID, status, errorNumber)
	if linkConvert.setting.active and linkConvert.setting.onConnect then
		if status == ts3defs.ConnectStatus.STATUS_CONNECTION_ESTABLISHED then
			if linkConvert.functions.updateReminder or linkConvert.functions.offlineMSGReminder then
				getOwnVersion(sCHID)
				if linkConvert.setting.onConnect then
					checkAllClients(sCHID)
				end
			end
		end
	end
end

local function onClientMoveEvent(sCHID, clientID, oldChannelID, newChannelID, visibility, moveMessage)
	if clientID ~= ts3.getClientID(sCHID) then
		if oldChannelID == "0" or oldChannelID == 0 then
			if linkConvert.functions.updateReminder or linkConvert.functions.offlineMSGReminder then
				checkClient(sCHID, clientID)
			end
		end
	end
end

local function onUpdateClientEvent(sCHID, clientID, invokerID, invokerName, invokerUniqueIdentifier)
	if linkConvert.functions.updateReminder then
		if linkConvert.var.requestedclientvars and linkConvert.var.requestedclientvarsclid == clientID then
			local platform = ts3.getClientVariableAsString(sCHID,clientID,ts3defs.ClientProperties.CLIENT_PLATFORM)
			if platform == "Windows" or platform == "Linux" or platform == "OS X" then
				checkClientVersion(sCHID, clientID)
			end
			linkConvert.var.requestedclientvars = false
			requestedclientvarsclid = nil
		end
	end
end

getOwnVersion(sCHID)

local events = {
	onTextMessageEvent = onTextMessageEvent,
	onConnectStatusChangeEvent = onConnectStatusChangeEvent,
	onClientMoveEvent = onClientMoveEvent,
	onUpdateClientEvent = onUpdateClientEvent
}
ts3.printMessageToCurrentTab(linkConvert.info.name.." loaded.")
ts3RegisterModule(linkConvert.info.folder, events)
