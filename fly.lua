--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	hrp = char:WaitForChild("HumanoidRootPart")
end)

--// SETTINGS
local flyEnabled = false
local flySpeed = 50

local flyToggleKey = Enum.KeyCode.F
local flyUpKey = Enum.KeyCode.Space
local flyDownKey = Enum.KeyCode.LeftControl

local rebindingToggle = false
local rebindingDown = false
local minimized = false

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "FlyGui"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromScale(0.28, 0.38)
frame.Position = UDim2.fromScale(0.35, 0.3)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame)

--// TOP BAR
local topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.fromScale(1, 0.15)
topBar.BackgroundTransparency = 1

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.fromScale(0.8, 1)
title.BackgroundTransparency = 1
title.Text = "Fly Controller"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)

local minimizeBtn = Instance.new("TextButton", topBar)
minimizeBtn.Size = UDim2.fromScale(0.2, 1)
minimizeBtn.Position = UDim2.fromScale(0.8, 0)
minimizeBtn.Text = "-"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextScaled = true
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
minimizeBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", minimizeBtn)

--// CONTENT
local content = Instance.new("Frame", frame)
content.Position = UDim2.fromScale(0, 0.15)
content.Size = UDim2.fromScale(1, 0.85)
content.BackgroundTransparency = 1

local function makeButton(text, y, color)
	local b = Instance.new("TextButton", content)
	b.Size = UDim2.fromScale(0.9, 0.14)
	b.Position = UDim2.fromScale(0.05, y)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", b)
	return b
end

local toggleBtn = makeButton("Fly: OFF", 0.05, Color3.fromRGB(170,60,60))

-- SPEED TEXTBOX (shows current speed)
local speedBox = Instance.new("TextBox", content)
speedBox.Size = UDim2.fromScale(0.9, 0.12)
speedBox.Position = UDim2.fromScale(0.05, 0.22)
speedBox.BackgroundColor3 = Color3.fromRGB(45,45,45)
speedBox.Font = Enum.Font.GothamBold
speedBox.TextScaled = true
speedBox.TextColor3 = Color3.new(1,1,1)
speedBox.ClearTextOnFocus = false
Instance.new("UICorner", speedBox)

local function updateSpeedText()
	speedBox.Text = "Speed: " .. flySpeed
end
updateSpeedText()

local bindToggleBtn = makeButton("Toggle Fly Key: F", 0.39, Color3.fromRGB(70,120,170))
local bindDownBtn = makeButton("Fly Down Key: CTRL", 0.56, Color3.fromRGB(70,70,170))

--// MINIMIZE
minimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	content.Visible = not minimized
	frame.Size = minimized and UDim2.fromScale(0.18, 0.12) or UDim2.fromScale(0.28, 0.38)
	minimizeBtn.Text = minimized and "+" or "-"
end)

--// FLY PHYSICS
local bodyVel
local bodyGyro

local function startFly()
	humanoid.AutoRotate = false

	bodyVel = Instance.new("BodyVelocity", hrp)
	bodyVel.MaxForce = Vector3.new(1e9,1e9,1e9)

	bodyGyro = Instance.new("BodyGyro", hrp)
	bodyGyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
	bodyGyro.P = 1e5
end

local function stopFly()
	humanoid.AutoRotate = true
	if bodyVel then bodyVel:Destroy() end
	if bodyGyro then bodyGyro:Destroy() end
	bodyVel, bodyGyro = nil, nil
end

local function toggleFly()
	flyEnabled = not flyEnabled
	if flyEnabled then
		startFly()
		toggleBtn.Text = "Fly: ON"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(60,170,60)
	else
		stopFly()
		toggleBtn.Text = "Fly: OFF"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(170,60,60)
	end
end

toggleBtn.MouseButton1Click:Connect(toggleFly)

-- SPEED INPUT
speedBox.FocusLost:Connect(function()
	local num = tonumber(speedBox.Text:match("%d+"))
	if num and num > 0 then
		flySpeed = num
	end
	updateSpeedText()
end)

-- REBINDING
bindToggleBtn.MouseButton1Click:Connect(function()
	rebindingToggle = true
	bindToggleBtn.Text = "Press any key..."
end)

bindDownBtn.MouseButton1Click:Connect(function()
	rebindingDown = true
	bindDownBtn.Text = "Press any key..."
end)

UIS.InputBegan:Connect(function(input, gpe)
	if gpe or input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	if rebindingToggle then
		flyToggleKey = input.KeyCode
		bindToggleBtn.Text = "Toggle Fly Key: " .. flyToggleKey.Name
		rebindingToggle = false
		return
	end

	if rebindingDown then
		flyDownKey = input.KeyCode
		bindDownBtn.Text = "Fly Down Key: " .. flyDownKey.Name
		rebindingDown = false
		return
	end

	if input.KeyCode == flyToggleKey then
		toggleFly()
	end
end)

-- MOVEMENT (WASD + CAMERA)
RunService.RenderStepped:Connect(function()
	if not flyEnabled or not bodyVel then return end

	local cam = workspace.CurrentCamera
	local dir = Vector3.zero

	if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
	if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
	if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
	if UIS:IsKeyDown(flyUpKey) then dir += Vector3.new(0,1,0) end
	if UIS:IsKeyDown(flyDownKey) then dir -= Vector3.new(0,1,0) end

	bodyVel.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * flySpeed
	bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
end)
