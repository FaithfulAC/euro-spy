local module = {}
local instancerunthrough = {}

local cloneref = cloneref or function(...) return ... end

local Player: Player = cloneref(game:GetService("Players").LocalPlayer)
local UIS: UserInputService = cloneref(game:GetService("UserInputService"))
local Main = script.Parent.Parent

local Mouse: Mouse = cloneref(Player:GetMouse())
local Button1Down, Button1Up, TouchTap;

Main.Destroying:Connect(function()
	table.clear(module)
	Player, Mouse = nil, nil
	
	Button1Down:Disconnect()
	Button1Down = nil
end)

Button1Down = Mouse.Button1Down:Connect(function()
	for i, v in pairs(instancerunthrough) do
		if v.Entered then
			v.Down = true
			if v.FireBoth then
				v.Function(Mouse.X, Mouse.Y)
			end
		end
	end
end)

Button1Up = Mouse.Button1Up:Connect(function()
	for i, v in pairs(instancerunthrough) do
		if not v.IgnoreLeave then
			if v.Entered and v.Down then
				v.Function(Mouse.X, Mouse.Y)
			end
		elseif v.Down then
			v.Function(Mouse.X, Mouse.Y)
		end
		v.Down = false
	end
end)

if not UIS.MouseEnabled then
	
end

module.ConnectOnEnter = if not Mouse then nil else function(Ins: TextLabel, Func): RBXScriptConnection
	return Ins.MouseEnter:Connect(Func) -- call Func with args Mouse.X, Mouse.Y
end

module.ConnectOnLeave = if not Mouse then nil else function(Ins: TextLabel, Func): RBXScriptConnection
	return Ins.MouseLeave:Connect(Func) -- call Func with args Mouse.X, Mouse.Y
end

module.ConnectOnClick = function(Ins: TextLabel, Func): nil
	local UniqueIdentifier = {
		Entered = false,
		Down = false,
		Function = Func
	}
	
	table.insert(instancerunthrough, UniqueIdentifier)
	
	Ins.MouseEnter:Connect(function()
		UniqueIdentifier.Entered = true
	end)
	Ins.MouseLeave:Connect(function()
		UniqueIdentifier.Entered = false
	end)
	
	if not UIS.MouseEnabled then
		Ins.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				Func()
			end
		end)
	end
	
	return
end

module.ConnectOnMouseEvent = function(Ins: TextLabel, Func): nil
	local UniqueIdentifier = {
		Entered = false,
		Down = false,
		FireBoth = true,
		IgnoreLeave = true,
		Function = Func
	}

	table.insert(instancerunthrough, UniqueIdentifier)

	Ins.MouseEnter:Connect(function()
		UniqueIdentifier.Entered = true
	end)
	Ins.MouseLeave:Connect(function()
		UniqueIdentifier.Entered = false
	end)

	if not UIS.MouseEnabled then
		Ins.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				Func()
			end
		end)
		
		Ins.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				Func()
			end
		end)
	end

	return
end

return module
