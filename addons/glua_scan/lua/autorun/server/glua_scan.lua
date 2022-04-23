require("CHTTP")
util.AddNetworkString("flscan_files")

local TableToJSON = util.TableToJSON
local JSONToTable = util.JSONToTable
local fileRead = file.Read

local function toKeys(tbl)

	local out = {}
	for i, v in ipairs(tbl) do
		out[v] = true
	end
	return out

end

local Discord_warning_webhook = ''
FCcside_script = [[
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
    net.Start("flscan_files")
        net.WriteString(util.TableToJSON(fs))
    net.SendToServer()
    fs = nil
    print('checked')
]]

hook.Add("PlayerInitialSpawn", "SendFileCheck",
        function(ply)
            ply:SendLua("WhatTheFCKisThat = [[" .. string.sub(FCcside_script, 1, 200) .. "]]")
            ply:SendLua("WhatTheFCKisThat = WhatTheFCKisThat .. [[" .. string.sub(FCcside_script, 201, 400) .. "]]")
            ply:SendLua("WhatTheFCKisThat = WhatTheFCKisThat .. [[" .. string.sub(FCcside_script, 401, 600) .. "]]")
            ply:SendLua("WhatTheFCKisThat = WhatTheFCKisThat .. [[" .. string.sub(FCcside_script, 601, #FCcside_script) .. "]]")
            ply:SendLua("local wut = CompileString(WhatTheFCKisThat, 'lalala') wut()") // because client can disable net.Receive
        end
)


local function files_warning(len, ply)

    print("got", ply:Nick())
    local tablf = net.ReadString()
    local fs = toKeys(JSONToTable(fileRead("fnative_files.json", "DATA")))
    local fsstr = ""

    for k,v in pairs(JSONToTable(tablf)) do
        if !fs[v] then
            fsstr = fsstr .. "\n" .. v
        end
    end

    if fsstr == "" then return end
    local name = ply:Nick()
    local params = {
        ['username'] = name,
        ['embeds'] = { 

            {
                title = "Detected files:",
                description ="==========" .. "\n[Profile](http://steamcommunity.com/profiles/" .. ply:SteamID64() .. ')\n==========\n' .. fsstr,                      
                color = 16711680,    
            } 
        }
    }
    CHTTP({
        method = 'POST',
        url = Discord_warning_webhook .. '?wait=true',
        body = TableToJSON(params),
        headers = {
            ["content-Type"] = "application/json",
            ["accept"] =  "application/json",
        },
        type = "application/json; charset=utf-8"
    })
    
end

net.Receive("flscan_files", files_warning)
