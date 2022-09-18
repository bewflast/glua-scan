local NET_MESSAGE_NAME			= "flscan_files" // !!!SHOULD CHANGE THIS TO ANYTHING ELSE!!!
local DISCORD_WARNING_WEBHOOK	= ""

require("CHTTP")
util.AddNetworkString(NET_MESSAGE_NAME)

local fileRead			= file.Read
local TableToJSON		= util.TableToJSON
local JSONToTable		= util.JSONToTable
local native_files_list	= {}



local function toKeys(tbl)
	local out = {}
	for i, v in ipairs(tbl) do
		out[v] = true
	end
	return out
end



FCcside_script = string.format([[
	local fs = {}
	local stringSplit = string.Split
	local stringTrim = string.Trim
	local fileFind = file.Find

	local function getluamenu(patr)
		local files, dirs = fileFind(patr, "LuaMenu")
		for k,v in pairs(dirs) do
			local npath = #stringSplit(patr, "/") < 2 and  v .. "/" .. patr or  stringTrim(patr, "*") .. v .. "/*" 
			getluamenu(npath)
		end
		for k, v in pairs(files) do 
			fs[#fs + 1] = stringTrim(patr, "*") .. v
		end
	end

	getluamenu("*")
	net.Start("%s")
		net.WriteString(util.TableToJSON(fs))
	net.SendToServer()
	fs = nil
]], NET_MESSAGE_NAME)



hook.Add("PlayerInitialSpawn", "SendFileCheck",
		function(ply)
			ply:SendLua("WhatTheFCKisThat = [[" .. string.sub(FCcside_script, 1, 200) .. "]]")
			ply:SendLua("WhatTheFCKisThat = WhatTheFCKisThat .. [[" .. string.sub(FCcside_script, 201, 400) .. "]]")
			ply:SendLua("WhatTheFCKisThat = WhatTheFCKisThat .. [[" .. string.sub(FCcside_script, 401, 600) .. "]]")
			ply:SendLua("WhatTheFCKisThat = WhatTheFCKisThat .. [[" .. string.sub(FCcside_script, 601, #FCcside_script) .. "]]")
			ply:SendLua("local wut = CompileString(WhatTheFCKisThat, 'lalala') wut()") // because client can disable net.Receive
			
			timer.Simple(30, function()
				if not IsValid(ply) then return end 
				if not ply.has_been_already_glua_scanned then // anti net.SendToServer override
					ply:Ban(0, true) 
				end 
			end) 

		end)



local function files_warning(len, ply)
	if ply.has_been_already_glua_scanned then ply:Ban(0, true) return end // anti-scriptkiddy

	ply.has_been_already_glua_scanned = true
	local received_user_files = net.ReadString()
	local not_native_files	= ""

	for k,v in pairs(JSONToTable(received_user_files)) do
		if !native_files_list[v] then
			not_native_files = not_native_files .. "\n" .. v
		end
	end

	if not_native_files == "" then return end

	local name = ply:Nick()
	local params = 
	{
		['username']	= name,
		['embeds']		= 
		{ 
			{
				title		= "Detected files:",
				description	= "==========" .. "\n[Profile](http://steamcommunity.com/profiles/" .. ply:SteamID64() .. ')\n==========\n' .. not_native_files,                      
				color		= 16711680,    
			} 
		}
	}

	CHTTP({
		method  = 'POST',
		url		= DISCORD_WARNING_WEBHOOK .. '?wait=true',
		body	= TableToJSON(params),
		headers = 
		{
			["content-Type"]	= "application/json",
			["accept"]			= "application/json",
		},
		type	= "application/json; charset=utf-8"
	})
	
end



net.Receive(NET_MESSAGE_NAME, files_warning)



hook.Add("InitPostEntity", "Files list init", 
		function()
			local files_list_f	= file.Open("addons/glua_scan/data/fnative_files.json", "r", "GAME")
			native_files_list	= toKeys(util.JSONToTable(files_list_f:Read()))
			files_list_f:Close()
			hook.Remove("InitPostEntity", "Files list init")
		end)