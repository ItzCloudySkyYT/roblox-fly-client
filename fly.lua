-- FULL CLIENT-SIDE FLY GUI + CAMERA-FACING DIAGONAL FLY
-- LocalScript → StarterPlayerScripts

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- SETTINGS
local flyEnabled = false
local flySpeed = 60

local toggleKey = Enum.KeyCode.F
local flyUpKey = Enum.KeyCode.Space
local flyDownKey = Enum.KeyCode.LeftControl

-- STATE
local move = {W=false,A=false,S=false,D=false}
local upHeld, downHeld = false,false

local char, humanoid, root
local bv, bg

-- CHARACTER SETUP
local function setupChar(c)
	char = c
	humanoid = c:WaitForChild("Humanoid")
	root = c:WaitForChild("HumanoidRootPart")
end
if player.Character then setupChar(player.Character) end
player.CharacterAdded:Connect(setupChar)

-- GUI
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "FlyGui"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromScale(0.25,0.35)
frame.Position = UDim2.fromScale(0.7,0.3)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame)

-- TOP BAR + TITLE
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.fromScale(1,0.15)
title.Text = "Fly Controller"
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

-- CONTENT
local content = Instance.new("Frame", frame)
content.Size = UDim2.fromScale(1,0.85)
content.Position = UDim2.fromScale(0,0.15)
content.BackgroundTransparency = 1

-- MINIMIZE BUTTON
local minimize = Instance.new("TextButton", frame)
minimize.Size = UDim2.fromScale(0.15,0.15)
minimize.Position = UDim2.fromScale(0.83,0)
minimize.Text = "-"
minimize.TextScaled = true
minimize.Font = Enum.Font.GothamBold

local minimized = false
minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	content.Visible = not minimized
	frame.Size = minimized and UDim2.fromScale(0.25,0.15) or UDim2.fromScale(0.25,0.35)
	minimize.Text = minimized and "+" or "-"
end)

-- BUTTON UTILITY
local function makeButton(parent,text,posY,color)
	local b = Instance.new("TextButton", parent)
	b.Size = UDim2.fromScale(0.9,0.12)
	b.Position = UDim2.fromScale(0.05,posY)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", b)
	return b
end

-- FLY TOGGLE BUTTON
local flyBtn = makeButton(content,"Fly: OFF",0.05,Color3.fromRGB(60,60,60))

-- SPEED TEXTBOX (number only)
local speedBox = Instance.new("TextBox", content)
speedBox.Size = UDim2.fromScale(0.9,0.12)
speedBox.Position = UDim2.fromScale(0.05,0.22)
speedBox.Font = Enum.Font.GothamBold
speedBox.TextScaled = true
speedBox.BackgroundColor3 = Color3.fromRGB(45,45,45)
speedBox.TextColor3 = Color3.new(1,1,1)
speedBox.ClearTextOnFocus = false
speedBox.Text = tostring(flySpeed)
Instance.new("UICorner", speedBox)

speedBox.FocusLost:Connect(function()
	local n = tonumber(speedBox.Text)
	if n and n>0 then flySpeed = n end
	speedBox.Text = tostring(flySpeed)
end)

-- FLY UP/DOWN KEY BINDING BUTTONS
local bindToggleBtn = makeButton(content,"Toggle Fly Key: F",0.39,Color3.fromRGB(70,120,170))
local bindDownBtn = makeButton(content,"Fly Down Key: CTRL",0.56,Color3.fromRGB(70,70,170))

local rebindingToggle, rebindingDown = false,false

bindToggleBtn.MouseButton1Click:Connect(function()
	rebindingToggle=true
	bindToggleBtn.Text="Press any key..."
end)
bindDownBtn.MouseButton1Click:Connect(function()
	rebindingDown=true
	bindDownBtn.Text="Press any key..."
end)

-- FLY LOGIC
local function enableFly()
	if flyEnabled or not root then return end
	flyEnabled = true
	flyBtn.Text = "Fly: ON"

	bv = Instance.new("BodyVelocity", root)
	bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

	bg = Instance.new("BodyGyro", root)
	bg.MaxTorque = Vector3.new(math.huge,0,math.huge) -- keep upright physics
	bg.P = 9000
end

local function disableFly()
	flyEnabled=false
	flyBtn.Text="Fly: OFF"
	if bv then bv:Destroy() end
	if bg then bg:Destroy() end
end

flyBtn.MouseButton1Click:Connect(function()
	if flyEnabled then disableFly() else enableFly() end
end)

-- INPUT
UIS.InputBegan:Connect(function(input,gpe)
	if gpe then return end
	if input.UserInputType~=Enum.UserInputType.Keyboard then return end

	if rebindingToggle then
		toggleKey = input.KeyCode
		bindToggleBtn.Text="Toggle Fly Key: "..toggleKey.Name
		rebindingToggle=false
		return
	end
	if rebindingDown then
		flyDownKey = input.KeyCode
		bindDownBtn.Text="Fly Down Key: "..flyDownKey.Name
		rebindingDown=false
		return
	end

	if input.KeyCode==toggleKey then
		if flyEnabled then disableFly() else enableFly() end
	end
	if input.KeyCode==Enum.KeyCode.W then move.W=true end
	if input.KeyCode==Enum.KeyCode.A then move.A=true end
	if input.KeyCode==Enum.KeyCode.S then move.S=true end
	if input.KeyCode==Enum.KeyCode.D then move.D=true end
	if input.KeyCode==flyUpKey then upHeld=true end
	if input.KeyCode==flyDownKey then downHeld=true end
end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode==Enum.KeyCode.W then move.W=false end
	if input.KeyCode==Enum.KeyCode.A then move.A=false end
	if input.KeyCode==Enum.KeyCode.S then move.S=false end
	if input.KeyCode==Enum.KeyCode.D then move.D=false end
	if input.KeyCode==flyUpKey then upHeld=false end
	if input.KeyCode==flyDownKey then downHeld=false end
end)

-- MAIN LOOP
RunService.RenderStepped:Connect(function()
	if not flyEnabled or not root then return end

	local cam = camera.CFrame

	-- HORIZONTAL + vertical movement
	local forward = cam.LookVector
	local right = cam.RightVector
	forward = forward.Unit
	right = right.Unit

	local vel = Vector3.zero
	if move.W then vel += forward end
	if move.S then vel -= forward end
	if move.A then vel -= right end
	if move.D then vel += right end
	if upHeld then vel += Vector3.yAxis end
	if downHeld then vel -= Vector3.yAxis end
	if vel.Magnitude>0 then vel=vel.Unit*flySpeed end

	bv.Velocity=vel

	-- PHYSICS: stay upright (lock only X/Z rotation)
	if bg then
		bg.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(cam.LookVector.X,0,cam.LookVector.Z))
	end

	-- VISUAL: rotate fully to camera (pitch + yaw)
	root.CFrame = CFrame.new(root.Position, root.Position + cam.LookVector)
end)
