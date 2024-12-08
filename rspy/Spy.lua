--[[
_G.ByteStrings <bool>
_G.ArgumentLimit <bool>
_G.ExcludeUnreliableEvents <bool>
_G.GeneratePseudoCode <bool>
_G.GetPathUsesGetDebugId <bool>

]]

local MAX_REMOTE_ARGS = 7995 -- means >MAX wont even register; would be 7996 but there is a special case where it can still error
local MAX_DISPLAYABLE_ARGS = 200
local MAX_TABLE_DEPTH = 20

local cloneref = cloneref or function(...) return ... end
local clonefunction = clonefunction or function(...) return ... end

local GetDebugId = clonefunction(game.GetDebugId)
local IsA = clonefunction(game.IsA)

local compareinstances = function(a,b) return typeof(a) == typeof(b) and GetDebugId(a) == GetDebugId(b) end
local getinstances = getinstances or function() return game:GetDescendants() end
local hookfunction = hookfunction or function()end
local hookmetamethod = hookmetamethod or function()end
local checkcaller = checkcaller or function() return false end
local getcallback = getcallbackvalue
local setclipboard = setclipboard
local setthreadidentity = setthreadidentity
local getrawmetatable = getrawmetatable or getmetatable
local getgenv = getgenv or getfenv
local getrenv = getrenv or getfenv
local info = getrenv().debug.info
local iscclosure = iscclosure or function(a)
	return info(a, "s") == "[C]"
end

local split = string.split
local sub = string.sub
local gsub = string.gsub
local match = string.match
local find = string.find
local char = string.char
local byte = string.byte
local reverse = string.reverse
local lower = string.lower
local upper = string.upper
local pack = table.pack

local GetCallingScript = false
local BlockRemote = false
local IgnoreRemote = false

local function GetService(class): Instance
	return cloneref(game:GetService(class))
end

local Players: Players = GetService("Players")
local Player: Player? = cloneref(Players.LocalPlayer)
local Mouse: Mouse = cloneref(Player:GetMouse())
local RunService: RunService = GetService("RunService")
local CoreGui: Instance = GetService("CoreGui")

local RemoteEvent, BindableEvent, RemoteFunction, BindableFunction, UnreliableRemoteEvent do
	RemoteEvent = Instance.new("RemoteEvent")
	BindableEvent = Instance.new("BindableEvent")
	RemoteFunction = Instance.new("RemoteFunction")
	BindableFunction = Instance.new("BindableFunction")
	UnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")
end

local CrazyCharacters = {
	["0"] = "\0",
	["n"] = "\n",
	["t"] = "\t",
	["s"] = "\s",
	["r"] = "\r",
	["f"] = "\f"
}

local function CapitalizeFirstLetter(str)
	return gsub(str, "^%l", string.upper)
end

local function GetCleanString(str)
	return split(CapitalizeFirstLetter(str), "\0")[1]
end

local function ReturnSafeString(str)
	if _G.ByteStrings then
		return "\\" .. table.concat({byte(str, 1, #str)}, "\\")
	end
	
	local safe = ""
	
	for i = 1, #str do
		local subchar = sub(str, i, i)
		local byteint = byte(subchar)
		
		if byteint > 35 and byteint < 127 then
			safe ..= subchar
		else
			local stop = false
			
			for key, value in pairs(CrazyCharacters) do
				if value == subchar then
					safe ..= "\\" .. key
					stop = true
					break
				end
			end
			
			if stop then continue end
			safe ..= "\\" .. byteint
		end
	end
	
	return safe
end

local function GetPath(ins)
	local path = ""
	
	if ins.Parent == nil then
		return "--[[name is " .. ins.Name .. "]]\ngetnilinstancefromid(\"" .. GetDebugId(ins) .. "\")"
	end
	
	if _G.GetPathUsesGetDebugId then
		return [[((function() local debugid = "]] .. GetDebugId(ins) .. [["; for _, ins in getinstances() do if ins:GetDebugId() == debugid then return ins end end end)())]]
	end
	
	local ancestry = {}
	repeat
		table.insert(ancestry, (ancestry[#ancestry] or ins).Parent)
	until ancestry[#ancestry] == game;
	
	for i = (#ancestry), 1, -1 do
		if ancestry[i] == game then
			path = path .. "game"
		elseif ancestry[i+1] == game then
			path = path .. ":FindFirstChildOfClass(\"" .. ancestry[i].ClassName .. "\")"
		else
			path = path .. ":FindFirstChild(\"" .. ReturnSafeString(ancestry[i].Name) .. "\")"
		end
	end
	
	path = path .. ":FindFirstChild(\"" .. ReturnSafeString(ins.Name) .. "\")"
	return path
end

-- function ripped from simplespy
local function u2s(u)
	if typeof(u) == "TweenInfo" then
		-- TweenInfo
		return "TweenInfo.new("
			.. tostring(u.Time)
			.. ", Enum.EasingStyle."
			.. tostring(u.EasingStyle)
			.. ", Enum.EasingDirection."
			.. tostring(u.EasingDirection)
			.. ", "
			.. tostring(u.RepeatCount)
			.. ", "
			.. tostring(u.Reverses)
			.. ", "
			.. tostring(u.DelayTime)
			.. ")"
	elseif typeof(u) == "Ray" then
		-- Ray
		return "Ray.new(" .. u2s(u.Origin) .. ", " .. u2s(u.Direction) .. ")"
	elseif typeof(u) == "NumberSequence" then
		-- NumberSequence
		local ret = "NumberSequence.new("
		for i, v in pairs(u.KeyPoints) do
			ret = ret .. tostring(v)
			if i < #u.Keypoints then
				ret = ret .. ", "
			end
		end
		return ret .. ")"
	elseif typeof(u) == "DockWidgetPluginGuiInfo" then
		-- DockWidgetPluginGuiInfo
		local stringedArgs = tostring(u)
		stringedArgs = string.gsub(stringedArgs, " ", ", ")
		stringedArgs = string.gsub(stringedArgs, "InitialDockState:", "Enum.InitialDockState.")
		stringedArgs = string.gsub(stringedArgs, "InitialEnabled:", "")
		stringedArgs = string.gsub(stringedArgs, "InitialEnabledShouldOverrideRestore:", "")
		stringedArgs = string.gsub(stringedArgs, ", 1", ", true")
		stringedArgs = string.gsub(stringedArgs, ", 0", ", false")
		for i, v in pairs({"FloatingXSize:", "FloatingYSize:", "MinWidth:", "MinHeight:"}) do
			stringedArgs = string.gsub(stringedArgs, v, "")
		end
		
		return "DockWidgetPluginGuiInfo.new(" .. stringedArgs .. ")"
	elseif typeof(u) == "ColorSequence" then
		-- ColorSequence
		local ret = "ColorSequence.new("
		for i, v in pairs(u.KeyPoints) do
			ret = ret .. "Color3.new(" .. tostring(v) .. ")"
			if i < #u.Keypoints then
				ret = ret .. ", "
			end
		end
		return ret .. ")"
	elseif typeof(u) == "BrickColor" then
		-- BrickColor
		return "BrickColor.new(" .. tostring(u.Number) .. ")"
	elseif typeof(u) == "NumberRange" then
		-- NumberRange
		return "NumberRange.new(" .. tostring(u.Min) .. ", " .. tostring(u.Max) .. ")"
	elseif typeof(u) == "Region3" then
		-- Region3
		local center = u.CFrame.Position
		local size = u.CFrame.Size
		local vector1 = center - size / 2
		local vector2 = center + size / 2
		return "Region3.new(" .. u2s(vector1) .. ", " .. u2s(vector2) .. ")"
	elseif typeof(u) == "Faces" then
		-- Faces
		local faces = {}
		if u.Top then
			table.insert(faces, "Enum.NormalId.Top")
		end
		if u.Bottom then
			table.insert(faces, "Enum.NormalId.Bottom")
		end
		if u.Left then
			table.insert(faces, "Enum.NormalId.Left")
		end
		if u.Right then
			table.insert(faces, "Enum.NormalId.Right")
		end
		if u.Back then
			table.insert(faces, "Enum.NormalId.Back")
		end
		if u.Front then
			table.insert(faces, "Enum.NormalId.Front")
		end
		return "Faces.new(" .. table.concat(faces, ", ") .. ")"
	elseif typeof(u) == "RBXScriptSignal" then
		return string.gsub(tostring(u), "Signal ", "") .. " --[[RBXScriptSignal]]"
	elseif typeof(u) == "PathWaypoint" then
		return string.format("PathWaypoint.new(%s, %s)", "Vector3.new(" .. tostring(u.Position) .. ")", tostring(u.Action))
	else
		if getrenv()[typeof(u)] and getrenv()[typeof(u)].new then
			return typeof(u) .. ".new(" .. tostring(u) .. ") --[[warning: not reliable]]"
		end
		return typeof(u) .. " --[[actual value is a userdata]]"
	end
end

local function safetostring(obj, convertnumbers)
	if typeof(obj) == "nil" or typeof(obj) == "boolean" then
		return tostring(obj)
	end

	if typeof(obj) == "string" then
		return '"' .. ReturnSafeString(obj) .. '"' --[[gsub " bait later?]]
	end

	if typeof(obj) == "function" then
		if iscclosure(obj) and getrenv()[info(obj, "n")] then
			return "--[[functions do not register to server]]\n" .. info(obj, "n")
		end
		return "--[[functions do not register to server]]\nfunction()end"
	end

	if typeof(obj) == "thread" then
		return "--[[threads do not register to server]]\n" .. "coroutine.create(function()end)"
	end

	if typeof(obj) == "number" then
		return convertnumbers and '"' .. tostring(obj) .. '"' or obj
	end

	if typeof(obj) == "userdata" then
		if getmetatable(obj) then return "newproxy(true)" end
		return "newproxy()"
	end

	if typeof(obj) == "Instance" then
		return GetPath(obj) --[[if in nil, say: nil instance]]
	end

	if typeof(obj) == "table" then
		local meta = getrawmetatable(obj)
		
		if not (meta and rawget(meta, "__tostring")) then
			return tostring(obj)
		end
		
		local org = rawget(meta, "__tostring")
		rawset(meta, "__tostring", nil)
		
		local res = tostring(obj)
		rawset(meta, "__tostring", obj)
		
		return res
	end

	if typeof(obj) == "Enums" then
		return "Enum"
	end

	if typeof(obj) == "Enum" then
		return "Enum." .. tostring(obj)
	end

	if typeof(obj) == "EnumItem" then
		return tostring(obj)
	end

	if typeof(obj) == "buffer" then
		local thing = buffer.tostring(obj)
		local len = buffer.len(obj)

		if len < 10000 and table.concat(string.split(thing, "\0")) ~= "" then
			return "buffer.fromstring(\"" .. ReturnSafeString(thing) .. "\")"
		end
		
		return "buffer.create(" .. len .. ")" .. if len >= 10000 then " --[[buffer may (not) have been made via fromstring]]" else ""
	end

	if type(obj) == "userdata" then --[[already looped thru other ud's]]
		return u2s(obj)
	end
end

local safeconcat = function(tbl, ...)
	for i, v in pairs(tbl) do
		tbl[i] = safetostring(v)
	end
	return table.concat(tbl, ...)
end

local RemoteEventList, BindableEventList, RemoteFunctionList, BindableFunctionList, UnreliableRemoteEventList = {}, {}, {}, {}, {}

local function InsertInClassList(ins)
	pcall(function()
		ins = cloneref(ins)
		local ClassName = ins.ClassName

		if ClassName == "RemoteEvent" then
			table.insert(RemoteEventList, ins)
		elseif ClassName == "BindableEvent" then
			table.insert(BindableEventList, ins)
		elseif ClassName == "RemoteFunction" then
			table.insert(RemoteFunctionList, ins)
		elseif ClassName == "BindableFunction" then
			table.insert(BindableFunctionList, ins)
		elseif ClassName == "UnreliableRemoteEvent" then
			table.insert(UnreliableRemoteEventList, ins)
		end
	end)
end

for i, ins in getinstances() do
	if typeof(ins) == "Instance" then
		InsertInClassList(ins)
	end
end

local DescendantConnection = game.DescendantAdded:Connect(InsertInClassList)

local function GetArgs(communicator, method, metamethod, ...)
	local args = {...}
	local NumberOfNilArguments = select("#", ...) - #args
	
	local NilComment = NumberOfNilArguments > 0 and " --[[Nil values at the end of a table will not register. For security reasons, they are distributed independent of the args table.]]\n" or ""

	return "local args = {\n\t"
		.. safeconcat(args, ", \n\t")
		.. "\n}\n\n"
		.. NilComment
		.. GetPath(communicator)
		.. ":"
		.. method
		.. "(unpack(args)"
		.. string.rep(", nil", NumberOfNilArguments)
		.. ")"
end

local funchook1, funchook2, funchook3, funchook4, funchook5;
local namecallhook;

funchook1 = hookfunction(RemoteEvent.FireServer, function(...)
	local self = ...
	local args = pack(select(2,...))
	
	if not checkcaller() and typeof(self) == "Instance" and #args <= MAX_REMOTE_ARGS and IsA(self, "RemoteEvent") then

	end
	
	return funchook1(...)
end)

funchook2 = hookfunction(BindableEvent.Fire, function(...)
	local self = ...
	local args = pack(select(2,...))

	if not checkcaller() and typeof(self) == "Instance" and #args <= MAX_REMOTE_ARGS and IsA(self, "BindableEvent") then

	end

	return funchook2(...)
end)

funchook3 = hookfunction(RemoteFunction.InvokeServer, function(...)
	local self = ...
	local args = pack(select(2,...))

	if not checkcaller() and typeof(self) == "Instance" and #args <= MAX_REMOTE_ARGS and IsA(self, "RemoteFunction") then

	end

	return funchook3(...)
end)

funchook4 = hookfunction(BindableFunction.Invoke, function(...)
	local self = ...
	local args = pack(select(2,...))

	if not checkcaller() and typeof(self) == "Instance" and #args <= MAX_REMOTE_ARGS and IsA(self, "BindableFunction") then

	end

	return funchook4(...)
end)

funchook5 = hookfunction(UnreliableRemoteEvent.FireServer, function(...)
	local self = ...
	local args = pack(select(2,...))

	if not checkcaller() and typeof(self) == "Instance" and #args <= MAX_REMOTE_ARGS and IsA(self, "UnreliableRemoteEvent") then
		
	end

	return funchook5(...)
end)


namecallhook = hookmetamethod(game, "__namecall", function(...)
	local self = ...
	local args = pack(select(2,...))
	local method = getnamecallmethod()

	if not checkcaller() and typeof(self) == "Instance" then
		
	end

	return namecallhook(...)
end)