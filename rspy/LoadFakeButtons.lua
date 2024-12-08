local Gui = script.Parent.Parent
local Main = Gui.Main
local Module = require(script.Parent.ConnectFakeButtonEvents)

local cloneref = cloneref or function(...) return ... end

local Player: Player = cloneref(game:GetService("Players").LocalPlayer)
local UIS: UserInputService = cloneref(game:GetService("UserInputService"))
local Mouse: Mouse = cloneref(Player:GetMouse())

for i, v in pairs(Gui:GetDescendants()) do
	if string.match(v.Name, "BUTTON_") then
		v:SetAttribute("IsFakeButton", true)
		v.Name = string.gsub(v.Name, "BUTTON_", "")
	end
end

local Hovering = {}

local function LoadBehaviorForButton(Button: TextLabel)
	if Button.BackgroundTransparency == 1 then
		return
	end
	
	local OriginalBackgroundColor = Button.BackgroundColor3
	local R, G, B = OriginalBackgroundColor.R*255, OriginalBackgroundColor.G*255, OriginalBackgroundColor.B*255
	
	if R < 150 then R += 50 end
	if G < 150 then G += 50 end
	if B < 150 then B += 50 end
	
	Module.ConnectOnEnter(Button, function()
		local NewR, NewG, NewB = R - 75, G - 75, B - 75
		
		if NewR < 0 then NewR = 0 end
		if NewG < 0 then NewG = 0 end
		if NewB < 0 then NewB = 0 end
		
		Button.BackgroundColor3 = Color3.fromRGB(NewR, NewG, NewB)
		Hovering[Button] = OriginalBackgroundColor
	end)
	
	Module.ConnectOnLeave(Button, function()
		Button.BackgroundColor3 = OriginalBackgroundColor
		Hovering[Button] = nil
	end)
	
	if not UIS.MouseEnabled then
		Button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then
				local NewR, NewG, NewB = R + 50, G + 50, B + 50

				if NewR > 255 then NewR = 255 end
				if NewG > 255 then NewG = 255 end
				if NewB > 255 then NewB = 255 end

				Button.BackgroundColor3 = Color3.fromRGB(NewR, NewG, NewB)
				task.wait(.1)
				Button.BackgroundColor3 = OriginalBackgroundColor
			end
		end)
	end
end

Mouse.Button1Down:Connect(function()
	for Button, OrgColor: Color3 in pairs(Hovering) do
		local NewR, NewG, NewB = OrgColor.R*255 + 50, OrgColor.G*255 + 50, OrgColor.B*255 + 50

		if NewR > 255 then NewR = 255 end
		if NewG > 255 then NewG = 255 end
		if NewB > 255 then NewB = 255 end
		
		Button.BackgroundColor3 = Color3.fromRGB(NewR, NewG, NewB)

		local conn; conn = Mouse.Button1Up:Connect(function()
			Button.BackgroundColor3 = OrgColor
			conn:Disconnect()
		end)
	end
end)

for i, v in pairs(Gui:GetDescendants()) do
	if v:GetAttribute("IsFakeButton") == true then
		LoadBehaviorForButton(v)
	end
end

local Resize = Main:FindFirstChild("Resize")

local TopBar = Main.TopBar
local Exit = TopBar:FindFirstChild("Exit")
local SettingsButton = TopBar:FindFirstChild("Settings")
local ListButton = TopBar:FindFirstChild("List")

local Settings = Gui.Settings
local SettingsTopBar = Settings.TopBar
local SettingsExit = SettingsTopBar:FindFirstChild("Exit")

local List = Gui.List

local Down = false

Module.ConnectOnMouseEvent(Resize, function(X, Y)
	Down = not Down
	local OriginalXOffset = Main.Size.X.Offset
	local OriginalYOffset = Main.Size.Y.Offset
	
	while Down and task.wait() do
		local NewXOffset = OriginalXOffset + (Mouse.X-X)
		local NewYOffset = OriginalYOffset + (Mouse.Y-Y)
		
		if NewXOffset < -50 then NewXOffset = -50 end
		if NewYOffset < -20 then NewYOffset = -20 end
		
		Main.Size = UDim2.new(Main.Size.X.Scale, NewXOffset, Main.Size.Y.Scale, NewYOffset)
	end
end)

Module.ConnectOnClick(Exit, function()
	Main.Parent:Destroy()
end)

Module.ConnectOnClick(SettingsExit, function()
	Settings.Visible = false
end)

Module.ConnectOnClick(SettingsButton, function()
	Settings.Visible = not Settings.Visible
end)

Module.ConnectOnClick(ListButton, function()
	List.Visible = not List.Visible
end)

_G.CanDrag = true