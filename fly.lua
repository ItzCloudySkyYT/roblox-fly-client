local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
end)

-------------------------------------------------
-- SETTINGS
-------------------------------------------------
local flying = false
local flySpeed = 50
local toggleKey = Enum.KeyCode.F
local flyDownKey = Enum.KeyCode.LeftControl

local moving = {
	W=false,A=false,S=false,D=false,
	Up=false,Down=false
}

-------------------------------------------------
-- GUI
-------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "FlyGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,240,0,260)
frame.Position = UDim2.new(0.7,0,0.4,0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner",frame)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Text = "Fly Menu"
title.TextScaled = true
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)

local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(0,30,0,30)
minimizeBtn.Position = UDim2.new(1,-30,0,0)
minimizeBtn.Text = "-"
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
Instance.new("UICorner",minimizeBtn)

local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1,0,1,-30)
content.Position = UDim2.new(0,0,0,30)
content.BackgroundTransparency = 1

local flyBtn = Instance.new("TextButton", content)
flyBtn.Size = UDim2.new(0.9,0,0.15,0)
flyBtn.Position = UDim2.new(0.05,0,0,0)
flyBtn.Text = "Fly: OFF"
flyBtn.BackgroundColor3 = Color3.fromRGB(170,0,0)
Instance.new("UICorner",flyBtn)

local speedBox = Instance.new("TextBox", content)
speedBox.Size = UDim2.new(0.9,0,0.15,0)
speedBox.Position = UDim2.new(0.05,0,0.2,0)
speedBox.Text = tostring(flySpeed)
speedBox.BackgroundColor3 = Color3.fromRGB(45,45,45)
speedBox.TextScaled = true
Instance.new("UICorner",speedBox)

local bindToggleBtn = Instance.new("TextButton", content)
bindToggleBtn.Size = UDim2.new(0.9,0,0.15,0)
bindToggleBtn.Position = UDim2.new(0.05,0,0.4,0)
bindToggleBtn.Text = "Toggle Key: F"
bindToggleBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
Instance.new("UICorner",bindToggleBtn)

local bindDownBtn = Instance.new("TextButton", content)
bindDownBtn.Size = UDim2.new(0.9,0,0.15,0)
bindDownBtn.Position = UDim2.new(0.05,0,0.6,0)
bindDownBtn.Text = "Fly Down: CTRL"
bindDownBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
Instance.new("UICorner",bindDownBtn)

-------------------------------------------------
-- MINIMIZE
-------------------------------------------------
local minimized=false
minimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	content.Visible = not minimized
	frame.Size = minimized and UDim2.new(0,240,0,30) or UDim2.new(0,240,0,260)
end)

-------------------------------------------------
-- KEYBIND CHANGER
-------------------------------------------------
local waitingToggle=false
local waitingDown=false

bindToggleBtn.MouseButton1Click:Connect(function()
	bindToggleBtn.Text="Press key..."
	waitingToggle=true
end)

bindDownBtn.MouseButton1Click:Connect(function()
	bindDownBtn.Text="Press key..."
	waitingDown=true
end)

UIS.InputBegan:Connect(function(input,gp)
	if gp then return end

	if waitingToggle then
		toggleKey=input.KeyCode
		bindToggleBtn.Text="Toggle Key: "..toggleKey.Name
		waitingToggle=false
		return
	end

	if waitingDown then
		flyDownKey=input.KeyCode
		bindDownBtn.Text="Fly Down: "..flyDownKey.Name
		waitingDown=false
		return
	end
end)

-------------------------------------------------
-- SPEED BOX
-------------------------------------------------
speedBox.FocusLost:Connect(function()
	local num=tonumber(speedBox.Text)
	if num and num>0 then
		flySpeed=num
	end
	speedBox.Text=tostring(flySpeed)
end)

-------------------------------------------------
-- FLY PHYSICS
-------------------------------------------------
local bodyVel
local bodyGyro

local function startFly()
	if flying then return end
	flying=true
	
	bodyVel=Instance.new("BodyVelocity")
	bodyVel.MaxForce=Vector3.new(1e9,1e9,1e9)
	bodyVel.Velocity=Vector3.zero
	bodyVel.Parent=root

	bodyGyro=Instance.new("BodyGyro")
	bodyGyro.MaxTorque=Vector3.new(1e9,1e9,1e9)
	bodyGyro.P=1e5
	bodyGyro.Parent=root

	flyBtn.Text="Fly: ON"
	flyBtn.BackgroundColor3=Color3.fromRGB(0,170,0)
end

local function stopFly()
	flying=false
	if bodyVel then bodyVel:Destroy() end
	if bodyGyro then bodyGyro:Destroy() end
	
	flyBtn.Text="Fly: OFF"
	flyBtn.BackgroundColor3=Color3.fromRGB(170,0,0)
end

flyBtn.MouseButton1Click:Connect(function()
	if flying then stopFly() else startFly() end
end)

-------------------------------------------------
-- INPUT
-------------------------------------------------
UIS.InputBegan:Connect(function(input,gp)
	if gp then return end

	if input.KeyCode==toggleKey then
		if flying then stopFly() else startFly() end
	end

	if input.KeyCode==Enum.KeyCode.W then moving.W=true end
	if input.KeyCode==Enum.KeyCode.S then moving.S=true end
	if input.KeyCode==Enum.KeyCode.A then moving.A=true end
	if input.KeyCode==Enum.KeyCode.D then moving.D=true end
	if input.KeyCode==Enum.KeyCode.Space then moving.Up=true end
	if input.KeyCode==flyDownKey then moving.Down=true end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode==Enum.KeyCode.W then moving.W=false end
	if input.KeyCode==Enum.KeyCode.S then moving.S=false end
	if input.KeyCode==Enum.KeyCode.A then moving.A=false end
	if input.KeyCode==Enum.KeyCode.D then moving.D=false end
	if input.KeyCode==Enum.KeyCode.Space then moving.Up=false end
	if input.KeyCode==flyDownKey then moving.Down=false end
end)

-------------------------------------------------
-- MAIN LOOP
-------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not flying or not bodyVel then return end
	
	local camCF=camera.CFrame
	local moveDir=Vector3.zero

	if moving.W then moveDir+=camCF.LookVector end
	if moving.S then moveDir-=camCF.LookVector end
	if moving.A then moveDir-=camCF.RightVector end
	if moving.D then moveDir+=camCF.RightVector end

	if moveDir.Magnitude>0 then
		moveDir=moveDir.Unit
	end

	local vertical=0
	if moving.Up then vertical+=1 end
	if moving.Down then vertical-=1 end

	bodyVel.Velocity = moveDir*flySpeed + Vector3.new(0,vertical*flySpeed,0)

	-- visual facing: fully match camera direction
	bodyGyro.CFrame = camCF
end)
