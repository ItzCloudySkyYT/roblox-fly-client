--// SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// CHARACTER REFERENCES
local function getChar()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:WaitForChild("Humanoid")
    local root = char:WaitForChild("HumanoidRootPart")
    return char, humanoid, root
end

local character, humanoid, root = getChar()
player.CharacterAdded:Connect(function()
    character, humanoid, root = getChar()
end)

--// SETTINGS
local flying = false
local speed = 50
local toggleKey = Enum.KeyCode.F
local flyDownKey = Enum.KeyCode.LeftControl
local waitingForBind = false

-- movement state
local move = {W=false,A=false,S=false,D=false,Up=false,Down=false}

--// GUI CREATION
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,220,0,160)
frame.Position = UDim2.new(0.3,0,0.3,0)
frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
frame.BorderSizePixel = 0
frame.Parent = gui

-- Dragging
local dragging, dragInput, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0,20,0,20)
minimizeBtn.Position = UDim2.new(1,-22,0,2)
minimizeBtn.Text = "-"
minimizeBtn.Parent = frame

local minimized = false
local miniButton = Instance.new("TextButton")
miniButton.Size = UDim2.new(0,80,0,30)
miniButton.Position = UDim2.new(0,10,0,10)
miniButton.Text = "Fly Menu"
miniButton.Visible = false
miniButton.Parent = gui

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = true
    frame.Visible = false
    miniButton.Visible = true
end)

miniButton.MouseButton1Click:Connect(function()
    minimized = false
    frame.Visible = true
    miniButton.Visible = false
end)

-- Fly toggle button
local flyBtn = Instance.new("TextButton")
flyBtn.Size = UDim2.new(1,-20,0,30)
flyBtn.Position = UDim2.new(0,10,0,10)
flyBtn.Text = "Fly: OFF"
flyBtn.Parent = frame

-- Speed box
local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(1,-20,0,30)
speedBox.Position = UDim2.new(0,10,0,50)
speedBox.Text = tostring(speed)
speedBox.ClearTextOnFocus = false
speedBox.Parent = frame

speedBox.FocusLost:Connect(function()
    local num = tonumber(speedBox.Text)
    if num then
        speed = math.clamp(num,10,300)
        speedBox.Text = tostring(speed)
    else
        speedBox.Text = tostring(speed)
    end
end)

-- Bind fly down button
local bindBtn = Instance.new("TextButton")
bindBtn.Size = UDim2.new(1,-20,0,30)
bindBtn.Position = UDim2.new(0,10,0,90)
bindBtn.Text = "Fly Down: "..flyDownKey.Name
bindBtn.Parent = frame

bindBtn.MouseButton1Click:Connect(function()
    bindBtn.Text = "Press any key..."
    waitingForBind = true
end)

--// FLY PHYSICS
local bodyVel, bodyGyro

local function startFly()
    if flying then return end
    flying = true
    flyBtn.Text = "Fly: ON"

    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(1e6,1e6,1e6)
    bodyVel.Velocity = Vector3.zero
    bodyVel.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
    bodyGyro.P = 3000
    bodyGyro.Parent = root

    RunService:BindToRenderStep("FlyMovement", Enum.RenderPriority.Character.Value, function()
        if not flying or not root then return end

        local camCF = camera.CFrame
        local forward = Vector3.new(camCF.LookVector.X,0,camCF.LookVector.Z).Unit
        local right = Vector3.new(camCF.RightVector.X,0,camCF.RightVector.Z).Unit

        local velocity = Vector3.zero

        if move.W then velocity += forward end
        if move.S then velocity -= forward end
        if move.A then velocity -= right end
        if move.D then velocity += right end
        if move.Up then velocity += Vector3.new(0,1,0) end
        if move.Down then velocity -= Vector3.new(0,1,0) end

        if velocity.Magnitude > 0 then
            velocity = velocity.Unit * speed
        end

        -- cancel gravity effect by maintaining vertical force
        bodyVel.Velocity = velocity

        -- face camera direction but upright
        local lookFlat = Vector3.new(camCF.LookVector.X,0,camCF.LookVector.Z)
        if lookFlat.Magnitude > 0 then
            bodyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + lookFlat)
        end
    end)
end

local function stopFly()
    flying = false
    flyBtn.Text = "Fly: OFF"

    RunService:UnbindFromRenderStep("FlyMovement")

    if bodyVel then bodyVel:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end

    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

flyBtn.MouseButton1Click:Connect(function()
    if flying then stopFly() else startFly() end
end)

--// INPUT HANDLING
UIS.InputBegan:Connect(function(input,gpe)
    if gpe then return end

    if waitingForBind and input.UserInputType == Enum.UserInputType.Keyboard then
        flyDownKey = input.KeyCode
        bindBtn.Text = "Fly Down: "..flyDownKey.Name
        waitingForBind = false
        return
    end

    if input.KeyCode == toggleKey then
        if flying then stopFly() else startFly() end
    end

    if input.KeyCode == Enum.KeyCode.W then move.W = true end
    if input.KeyCode == Enum.KeyCode.A then move.A = true end
    if input.KeyCode == Enum.KeyCode.S then move.S = true end
    if input.KeyCode == Enum.KeyCode.D then move.D = true end
    if input.KeyCode == Enum.KeyCode.Space then move.Up = true end
    if input.KeyCode == flyDownKey then move.Down = true end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then move.W = false end
    if input.KeyCode == Enum.KeyCode.A then move.A = false end
    if input.KeyCode == Enum.KeyCode.S then move.S = false end
    if input.KeyCode == Enum.KeyCode.D then move.D = false end
    if input.KeyCode == Enum.KeyCode.Space then move.Up = false end
    if input.KeyCode == flyDownKey then move.Down = false end
end)
