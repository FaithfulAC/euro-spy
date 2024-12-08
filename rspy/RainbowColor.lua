local Gui = script.Parent.Parent
local Title = Gui.Main.TopBar.Title
local OtherTitle = Gui.Settings.TopBar.Title

while task.wait() do
	Title.TextColor3 = Color3.fromHSV(tick()%5/5, 1, 1)
	OtherTitle.TextColor3 = Title.TextColor3
end