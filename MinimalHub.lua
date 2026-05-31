local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Connections = {}
local Drawings = {}
local Skeletons = {}
local originalSizes = {}

-- Variables to store original character stats
local originalStats = {
    Character = nil,
    WalkSpeed = 16,
    JumpPower = 50,
    UseJumpPower = false
}

-- ==========================================
-- 1. Configuration & States
-- ==========================================

local ConfigName = "MinimalHub_Config.json"

local States = {
    -- Visuals
    ESP = false,
    ESPWallCheck = false,
    ESPVisibleColor = Color3.fromRGB(0, 255, 150),
    ESPInvisibleColor = Color3.fromRGB(255, 50, 50),
    Nametags = false,
    Tracers = false,
    SkeletonESP = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    Watermark = true,

    -- Player
    WalkSpeedToggle = false,
    WalkSpeed = 16,
    JumpPowerToggle = false,
    JumpPower = 50,
    Noclip = false,
    Fly = false,
    FlySpeed = 50,
    FOVToggle = false, 
    FOV = 70,
    HitboxExpander = false,
    HitboxSize = 10,
    InfJump = false,
    Spinbot = false,
    Safewalk = false,
    AntiAim = false,

    -- Aimbot
    Aimbot = false,
    AimbotWallCheck = true,
    AimbotFOV = 100,
    AimbotDrawFOV = false,
    AimbotTarget = "Head", 
    AimbotSmoothness = 0.3, 

    -- Utility
    ClickTP = false,
    
    -- Script Hub Config
    AutoReattach = false
}

local TargetOptions = {"Head", "HumanoidRootPart", "UpperTorso"}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Color = Color3.new(1, 1, 1)
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.NumSides = 60

local function SaveConfig()
    if writefile then
        local success, data = pcall(function()
            local toSave = {}
            for k, v in pairs(States) do
                if typeof(v) == "Color3" then
                    toSave[k] = {v.R, v.G, v.B, "COLOR3"}
                else
                    toSave[k] = v
                end
            end
            return HttpService:JSONEncode(toSave)
        end)
        if success then writefile(ConfigName, data) end
    end
end

local function LoadConfig()
    if readfile and isfile and isfile(ConfigName) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigName))
        end)
        if success then
            for k, v in pairs(data) do
                if type(v) == "table" and v[4] == "COLOR3" then
                    States[k] = Color3.new(v[1], v[2], v[3])
                else
                    if States[k] ~= nil then States[k] = v end
                end
            end
        end
    end
end

LoadConfig()

-- ==========================================
-- 2. UI Framework & Intro (Minimalist)
-- ==========================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MinimalHubV1"
screenGui.ResetOnSpawn = false
local guiParent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
pcall(function() screenGui.Parent = guiParent end)

-- Watermark
local watermarkLabel = Instance.new("TextLabel")
watermarkLabel.Size = UDim2.new(0, 200, 0, 25)
watermarkLabel.Position = UDim2.new(0, 10, 0, 10)
watermarkLabel.BackgroundTransparency = 1
watermarkLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
watermarkLabel.TextStrokeTransparency = 0.5
watermarkLabel.Font = Enum.Font.GothamMedium
watermarkLabel.TextSize = 13
watermarkLabel.TextXAlignment = Enum.TextXAlignment.Left
watermarkLabel.Visible = States.Watermark
watermarkLabel.Parent = screenGui

local fpsFrames = 0
local fpsTick = tick()
local currentFps = 0

local introFrame = Instance.new("Frame")
introFrame.Size = UDim2.new(0, 250, 0, 80)
introFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
introFrame.AnchorPoint = Vector2.new(0.5, 0.5)
introFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
introFrame.BackgroundTransparency = 1
introFrame.BorderSizePixel = 0
introFrame.Parent = screenGui
Instance.new("UICorner", introFrame).CornerRadius = UDim.new(0, 8)

local introText = Instance.new("TextLabel")
introText.Size = UDim2.new(1, 0, 1, 0)
introText.BackgroundTransparency = 1
introText.Text = "MINIMAL HUB V1"
introText.TextColor3 = Color3.fromRGB(255, 255, 255)
introText.TextTransparency = 1
introText.Font = Enum.Font.GothamBold
introText.TextSize = 16
introText.Parent = introFrame

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 320)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 6)

task.spawn(function()
    local ti = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(introFrame, ti, {BackgroundTransparency = 0.1}):Play()
    TweenService:Create(introText, ti, {TextTransparency = 0}):Play()
    task.wait(1.5)
    TweenService:Create(introFrame, ti, {BackgroundTransparency = 1}):Play()
    TweenService:Create(introText, ti, {TextTransparency = 1}):Play()
    task.wait(0.8)
    introFrame:Destroy()
    
    mainFrame.Size = UDim2.new(0, 450, 0, 300)
    mainFrame.Visible = true
    TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 480, 0, 320)}):Play()
end)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 6)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Minimal Hub v1"
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.Font = Enum.Font.GothamMedium
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -30, 0, 0)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minimizeBtn.Font = Enum.Font.GothamMedium
minimizeBtn.TextSize = 16
minimizeBtn.Parent = topBar

local contentWrapper = Instance.new("Frame")
contentWrapper.Size = UDim2.new(1, 0, 1, -30)
contentWrapper.Position = UDim2.new(0, 0, 0, 30)
contentWrapper.BackgroundTransparency = 1
contentWrapper.Parent = mainFrame

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 120, 1, 0)
sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
sidebar.BorderSizePixel = 0
sidebar.Parent = contentWrapper

local sidebarList = Instance.new("UIListLayout")
sidebarList.SortOrder = Enum.SortOrder.LayoutOrder
sidebarList.Parent = sidebar

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -120, 1, 0)
contentContainer.Position = UDim2.new(0, 120, 0, 0)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = contentWrapper

local tabs = {}

local function createTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 35)
    tabBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.TextSize = 12
    tabBtn.BorderSizePixel = 0
    tabBtn.Parent = sidebar

    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Size = UDim2.new(1, 0, 1, 0)
    tabScroll.BackgroundTransparency = 1
    tabScroll.BorderSizePixel = 0
    tabScroll.ScrollBarThickness = 1
    tabScroll.Visible = false
    tabScroll.Parent = contentContainer

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 6)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Parent = tabScroll
    Instance.new("UIPadding", tabScroll).PaddingTop = UDim.new(0, 10)

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.Scroll.Visible = false
            t.Btn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
            t.Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
        tabScroll.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
    end)

    table.insert(tabs, {Btn = tabBtn, Scroll = tabScroll})

    if #tabs == 1 then
        tabScroll.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    return {
        CreateSection = function(secName)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.92, 0, 0, 24)
            lbl.BackgroundTransparency = 1
            lbl.Text = secName
            lbl.TextColor3 = Color3.fromRGB(120, 120, 120)
            lbl.Font = Enum.Font.GothamMedium
            lbl.TextSize = 11
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = tabScroll
            tabScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
        end,
        CreateToggle = function(text, stateKey, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.92, 0, 0, 28)
            btn.BackgroundColor3 = States[stateKey] and Color3.fromRGB(45, 120, 60) or Color3.fromRGB(30, 30, 30)
            btn.Text = "  " .. text
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.TextColor3 = States[stateKey] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.Parent = tabScroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

            local statusLbl = Instance.new("TextLabel")
            statusLbl.Size = UDim2.new(0, 40, 1, 0)
            statusLbl.Position = UDim2.new(1, -40, 0, 0)
            statusLbl.BackgroundTransparency = 1
            statusLbl.Text = States[stateKey] and "ON" or "OFF"
            statusLbl.TextColor3 = States[stateKey] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
            statusLbl.Font = Enum.Font.GothamBold
            statusLbl.TextSize = 10
            statusLbl.Parent = btn

            btn.MouseButton1Click:Connect(function()
                States[stateKey] = not States[stateKey]
                local active = States[stateKey]
                btn.BackgroundColor3 = active and Color3.fromRGB(45, 120, 60) or Color3.fromRGB(30, 30, 30)
                btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
                statusLbl.Text = active and "ON" or "OFF"
                statusLbl.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
                if callback then callback(active) end
            end)
            tabScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
        end,
        CreateSlider = function(text, stateKey, min, max, isFloat, callback)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0.92, 0, 0, 40)
            frame.BackgroundTransparency = 1
            frame.Parent = tabScroll

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 20)
            label.BackgroundTransparency = 1
            label.Text = text .. ": " .. States[stateKey]
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            label.Font = Enum.Font.Gotham
            label.TextSize = 11
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            local sliderBg = Instance.new("Frame")
            sliderBg.Size = UDim2.new(1, 0, 0, 6)
            sliderBg.Position = UDim2.new(0, 0, 0, 24)
            sliderBg.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            sliderBg.Parent = frame
            Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

            local fill = Instance.new("Frame")
            local startPos = math.clamp((States[stateKey] - min) / (max - min), 0, 1)
            fill.Size = UDim2.new(startPos, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
            fill.Parent = sliderBg
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

            local dragging = false

            local function update(input)
                local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                fill.Size = UDim2.new(pos, 0, 1, 0)
                local val = min + (max - min) * pos
                if not isFloat then val = math.floor(val) end
                local displayVal = isFloat and string.format("%.1f", val) or val
                States[stateKey] = val
                label.Text = text .. ": " .. displayVal
                if callback then callback(val) end
            end

            sliderBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    update(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update(input)
                end
            end)
            tabScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
        end,
        CreateCycle = function(text, stateKey, optionsArray)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.92, 0, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.Text = "  " .. text .. ": " .. States[stateKey]
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.Parent = tabScroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

            btn.MouseButton1Click:Connect(function()
                local currentIndex = table.find(optionsArray, States[stateKey]) or 1
                local nextIndex = currentIndex + 1
                if nextIndex > #optionsArray then nextIndex = 1 end
                States[stateKey] = optionsArray[nextIndex]
                btn.Text = "  " .. text .. ": " .. States[stateKey]
            end)
            tabScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
        end,
        CreateColorPicker = function(text, stateKey)
            local container = Instance.new("Frame")
            container.Size = UDim2.new(0.92, 0, 0, 100)
            container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            container.Parent = tabScroll
            Instance.new("UICorner", container).CornerRadius = UDim.new(0, 4)

            local titleLbl = Instance.new("TextLabel")
            titleLbl.Size = UDim2.new(1, -30, 0, 24)
            titleLbl.Position = UDim2.new(0, 10, 0, 0)
            titleLbl.BackgroundTransparency = 1
            titleLbl.Text = text
            titleLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
            titleLbl.Font = Enum.Font.Gotham
            titleLbl.TextSize = 11
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
            titleLbl.Parent = container

            local preview = Instance.new("Frame")
            preview.Size = UDim2.new(0, 16, 0, 16)
            preview.Position = UDim2.new(1, -26, 0, 4)
            preview.BackgroundColor3 = States[stateKey]
            preview.Parent = container
            Instance.new("UICorner", preview).CornerRadius = UDim.new(1, 0)

            local function createRGBSlider(yOffset, colorName, min, max, property)
                local bg = Instance.new("Frame")
                bg.Size = UDim2.new(1, -20, 0, 6)
                bg.Position = UDim2.new(0, 10, 0, yOffset)
                bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                bg.Parent = container
                Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

                local fill = Instance.new("Frame")
                local startVal = States[stateKey][property]
                fill.Size = UDim2.new(startVal, 0, 1, 0)
                fill.BackgroundColor3 = property == "R" and Color3.fromRGB(200, 50, 50) or property == "G" and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(50, 50, 200)
                fill.Parent = bg
                Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

                local dragging = false

                local function updateColor(input)
                    local pos = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
                    fill.Size = UDim2.new(pos, 0, 1, 0)
                    local cR = property == "R" and pos or States[stateKey].R
                    local cG = property == "G" and pos or States[stateKey].G
                    local cB = property == "B" and pos or States[stateKey].B
                    States[stateKey] = Color3.new(cR, cG, cB)
                    preview.BackgroundColor3 = States[stateKey]
                end

                bg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        updateColor(input)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateColor(input)
                    end
                end)
            end

            createRGBSlider(40, "Red", 0, 1, "R")
            createRGBSlider(60, "Green", 0, 1, "G")
            createRGBSlider(80, "Blue", 0, 1, "B")

            tabScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
        end,
        CreateButton = function(text, color, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.92, 0, 0, 28)
            btn.BackgroundColor3 = color or Color3.fromRGB(40, 40, 40)
            btn.Text = text
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 12
            btn.Parent = tabScroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

            btn.MouseButton1Click:Connect(callback)
            tabScroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
        end
    }
end

-- ==========================================
-- 3. Features & Logic Implementation
-- ==========================================

local function CheckVisibility(targetPart)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local direction = (targetPart.Position - Camera.CFrame.Position).Unit
    local distance = (targetPart.Position - Camera.CFrame.Position).Magnitude
    local rayResult = workspace:Raycast(Camera.CFrame.Position, direction * distance, rayParams)

    if rayResult and not rayResult.Instance:IsDescendantOf(targetPart.Parent) then
        return false
    end
    return true
end

local function GetClosestTarget()
    local closestTarget = nil
    local maxDistance = States.AimbotFOV
    local mouseLocation = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(States.AimbotTarget) or player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")

            if targetPart and humanoid and humanoid.Health > 0 then
                local vector, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local screenPoint = Vector2.new(vector.X, vector.Y)
                    local distance = (screenPoint - mouseLocation).Magnitude

                    if distance < maxDistance then
                        if States.AimbotWallCheck then
                            if CheckVisibility(targetPart) then
                                maxDistance = distance
                                closestTarget = targetPart
                            end
                        else
                            maxDistance = distance
                            closestTarget = targetPart
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

local function refreshAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local highlight = player.Character:FindFirstChild("GlowESP")
            if not States.ESP and highlight then highlight:Destroy() end
        end
    end
end

-- Skeleton Bones Reference
local skeletonBones = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

local r6Bones = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

local function handleVisuals()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            -- ESP WallCheck Coloring
            if player.Character and States.ESP then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                local highlight = player.Character:FindFirstChild("GlowESP")

                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "GlowESP"
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0.1
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = player.Character
                end

                if States.ESPWallCheck and root then
                    local isVisible = CheckVisibility(root)
                    highlight.FillColor = isVisible and States.ESPVisibleColor or States.ESPInvisibleColor
                    highlight.OutlineColor = isVisible and States.ESPVisibleColor or States.ESPInvisibleColor
                else
                    highlight.FillColor = States.ESPVisibleColor
                    highlight.OutlineColor = States.ESPVisibleColor
                end
            end

            -- Nametags
            if player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChildOfClass("Humanoid") then
                local head = player.Character.Head
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                local tag = head:FindFirstChild("NameTagESP")

                if States.Nametags then
                    if not tag then
                        tag = Instance.new("BillboardGui")
                        tag.Name = "NameTagESP"
                        tag.Size = UDim2.new(0, 200, 0, 50)
                        tag.StudsOffset = Vector3.new(0, 2.5, 0)
                        tag.AlwaysOnTop = true
                        tag.Parent = head

                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Font = Enum.Font.GothamMedium
                        label.TextSize = 13
                        label.TextColor3 = Color3.fromRGB(255, 255, 255)
                        label.TextStrokeTransparency = 0.3
                        label.Parent = tag
                    end

                    local dist = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and math.floor((head.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) or 0
                    local health = math.floor(hum.Health)

                    tag.TextLabel.Text = string.format("%s\n[%d HP] | %d studs", player.Name, health, dist)
                    tag.TextLabel.TextColor3 = States.ESPVisibleColor
                else
                    if tag then tag:Destroy() end
                end
            end

            -- Tracers
            if typeof(Drawing) == "table" or type(Drawing) == "userdata" then
                if not Drawings[player.Name] then
                    local line = Drawing.new("Line")
                    line.Thickness = 1.5
                    line.Transparency = 1
                    Drawings[player.Name] = line
                end

                local line = Drawings[player.Name]
                if States.Tracers and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = player.Character.HumanoidRootPart
                    local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                    if onScreen then
                        line.Visible = true
                        line.Color = States.ESPVisibleColor
                        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        line.To = Vector2.new(vector.X, vector.Y)
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end

            -- Skeleton ESP
            if States.SkeletonESP and player.Character then
                if not Skeletons[player.Name] then Skeletons[player.Name] = {} end
                local char = player.Character
                local rigType = char:FindFirstChild("UpperTorso") and skeletonBones or r6Bones

                for _, bonePair in ipairs(rigType) do
                    local part1 = char:FindFirstChild(bonePair[1])
                    local part2 = char:FindFirstChild(bonePair[2])
                    local lineId = bonePair[1] .. "_" .. bonePair[2]

                    if not Skeletons[player.Name][lineId] then
                        local skeletonLine = Drawing.new("Line")
                        skeletonLine.Thickness = 1.5
                        skeletonLine.Transparency = 1
                        Skeletons[player.Name][lineId] = skeletonLine
                    end

                    local skeletonLine = Skeletons[player.Name][lineId]
                    if part1 and part2 then
                        local pos1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
                        local pos2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)

                        if onScreen1 and onScreen2 then
                            skeletonLine.From = Vector2.new(pos1.X, pos1.Y)
                            skeletonLine.To = Vector2.new(pos2.X, pos2.Y)
                            skeletonLine.Color = States.SkeletonColor
                            skeletonLine.Visible = true
                        else
                            skeletonLine.Visible = false
                        end
                    else
                        skeletonLine.Visible = false
                    end
                end
            else
                if Skeletons[player.Name] then
                    for _, line in pairs(Skeletons[player.Name]) do
                        line.Visible = false
                    end
                end
            end
        end
    end
end

Connections.Jump = UserInputService.JumpRequest:Connect(function()
    if States.InfJump then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

Connections.ClickTP = UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.T and States.ClickTP then
        local mouseLocation = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
        if result and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(result.Position + Vector3.new(0, 3.5, 0))
        end
    end
end)

local function ServerHop()
    local placeId = game.PlaceId
    local servers = {}
    local req = request or http_request or (syn and syn.request)
    
    if req then
        local res = req({Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", placeId)})
        if res and res.Body then
            local data = HttpService:JSONDecode(res.Body)
            if data and data.data then
                for _, v in pairs(data.data) do
                    if type(v) == "table" and v.playing < v.maxPlayers and v.id ~= game.JobId then
                        table.insert(servers, v.id)
                    end
                end
            end
        end
    end
    
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)], LocalPlayer)
    else
        warn("Failed to find a suitable server to hop to.")
    end
end

-- ==========================================
-- Auto Reattach Logic (Teleport Queueing)
-- ==========================================
local function SetupAutoReattach()
    -- Get the executor's queue on teleport function safely
    local queue_teleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or (KRNL_LOADED and krnl.queue_on_teleport)
    
    if queue_teleport then
        Connections.Teleport = LocalPlayer.OnTeleport:Connect(function(teleportState)
            if States.AutoReattach and (teleportState == Enum.TeleportState.Started or teleportState == Enum.TeleportState.InProgress) then
                queue_teleport([[
                    task.wait(1)
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/Wakype/NamelessHub/main/MinimalHub.lua"))()
                    warn("MinimalHub: Auto Reattach executed.")
                ]])
            end
        end)
    end
end

SetupAutoReattach()

local flyBodyVelocity = nil

Connections.MainLoop = RunService.RenderStepped:Connect(function()
    handleVisuals()

    -- Watermark Updates
    if States.Watermark then
        watermarkLabel.Visible = true
        fpsFrames = fpsFrames + 1
        if tick() - fpsTick >= 1 then
            currentFps = fpsFrames
            fpsFrames = 0
            fpsTick = tick()
        end
        local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
        watermarkLabel.Text = string.format("MinimalHub V1 | FPS: %d | Ping: %d ms", currentFps, ping)
    else
        watermarkLabel.Visible = false
    end

    -- Field of View Changer Logic
    if States.FOVToggle then
        Camera.FieldOfView = States.FOV
    else
        -- Revert to default FOV if it was previously overridden by the script
        if Camera.FieldOfView == States.FOV and Camera.FieldOfView ~= 70 then
            Camera.FieldOfView = 70
        end
    end

    if States.AimbotDrawFOV then
        FOVCircle.Radius = States.AimbotFOV
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    if States.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestTarget()
        if target then
            local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, States.AimbotSmoothness)
        end
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local rootPart = char:FindFirstChild("HumanoidRootPart")

        -- Configurable Player Stats Toggles
        if hum then
            -- Store default values when a new character spawns
            if originalStats.Character ~= char then
                originalStats.Character = char
                originalStats.WalkSpeed = hum.WalkSpeed
                originalStats.JumpPower = hum.JumpPower
                originalStats.UseJumpPower = hum.UseJumpPower
            end

            if States.WalkSpeedToggle then
                hum.WalkSpeed = States.WalkSpeed
            else
                -- Revert to original WalkSpeed if it was previously overridden by the script
                if hum.WalkSpeed == States.WalkSpeed and hum.WalkSpeed ~= originalStats.WalkSpeed then
                    hum.WalkSpeed = originalStats.WalkSpeed
                end
            end

            if States.JumpPowerToggle then
                hum.JumpPower = States.JumpPower
                hum.UseJumpPower = true
            else
                -- Revert to original JumpPower if it was previously overridden by the script
                if hum.JumpPower == States.JumpPower and hum.JumpPower ~= originalStats.JumpPower then
                    hum.JumpPower = originalStats.JumpPower
                    hum.UseJumpPower = originalStats.UseJumpPower
                end
            end
        end

        -- Safewalk
        if States.Safewalk and rootPart and hum then
            if hum.FloorMaterial ~= Enum.Material.Air and hum.MoveDirection.Magnitude > 0 then
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {char}
                rayParams.FilterType = Enum.RaycastFilterType.Exclude

                -- Raycast ahead based on velocity
                local rayOrigin = rootPart.Position + (hum.MoveDirection * 3)
                local hit = workspace:Raycast(rayOrigin, Vector3.new(0, -10, 0), rayParams)

                if not hit then
                    -- Zero out velocity if there is no floor detected ahead
                    rootPart.Velocity = Vector3.new(0, rootPart.Velocity.Y, 0)
                end
            end
        end

        -- Noclip
        if States.Noclip then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end

        -- Fly
        if States.Fly and rootPart and hum then
            if not flyBodyVelocity then
                flyBodyVelocity = Instance.new("BodyVelocity")
                flyBodyVelocity.Name = "FlyBodyVelocity"
                flyBodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
                flyBodyVelocity.Parent = rootPart
            end

            local moveDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            flyBodyVelocity.Velocity = moveDir * States.FlySpeed
            hum.PlatformStand = true
        else
            if flyBodyVelocity then
                flyBodyVelocity:Destroy()
                flyBodyVelocity = nil
            end
            if hum and not States.Fly then hum.PlatformStand = false end
        end

        -- Spinbot / Fling
        if States.Spinbot and rootPart then
            local spinObj = rootPart:FindFirstChild("SpinbotVelocity")
            if not spinObj then
                spinObj = Instance.new("BodyAngularVelocity")
                spinObj.Name = "SpinbotVelocity"
                spinObj.MaxTorque = Vector3.new(0, math.huge, 0)
                spinObj.AngularVelocity = Vector3.new(0, 150, 0)
                spinObj.Parent = rootPart
            end
        else
            local spinObj = rootPart and rootPart:FindFirstChild("SpinbotVelocity")
            if spinObj then spinObj:Destroy() end
        end

        -- Anti-Aim
        if States.AntiAim and rootPart and hum then
            hum.AutoRotate = false
            -- Jitter root CFrame
            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(math.random(-90, 90)), 0)
        else
            if hum and not States.Spinbot and not States.AntiAim then
                hum.AutoRotate = true
            end
        end

        -- Hitbox Expander
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                if not originalSizes[player.Name] then
                    originalSizes[player.Name] = hrp.Size
                end

                if States.HitboxExpander then
                    hrp.Size = Vector3.new(States.HitboxSize, States.HitboxSize, States.HitboxSize)
                    hrp.Transparency = 0.5
                    hrp.CanCollide = false
                else
                    hrp.Size = originalSizes[player.Name]
                    hrp.Transparency = 1
                end
            end
        end
    end
end)

-- ==========================================
-- 4. Constructing the Menus
-- ==========================================

local tabVisuals = createTab("Visuals")
tabVisuals.CreateSection("ESP Settings")
tabVisuals.CreateToggle("Glow ESP", "ESP", refreshAllESP)
tabVisuals.CreateToggle("Dynamic Wallcheck Color", "ESPWallCheck")
tabVisuals.CreateColorPicker("Visible Color (No Wall)", "ESPVisibleColor")
tabVisuals.CreateColorPicker("Invisible Color (Behind Wall)", "ESPInvisibleColor")
tabVisuals.CreateSection("Other Visuals")
tabVisuals.CreateToggle("Nametags & Health", "Nametags")
tabVisuals.CreateToggle("Line Tracers", "Tracers")
tabVisuals.CreateToggle("Skeleton ESP", "SkeletonESP")
tabVisuals.CreateColorPicker("Skeleton Color", "SkeletonColor")

local tabAimbot = createTab("Aimbot")
tabAimbot.CreateSection("Aim Assist")
tabAimbot.CreateToggle("Enable Aimbot (Hold RMB)", "Aimbot")
tabAimbot.CreateToggle("Aimbot Wallcheck", "AimbotWallCheck")
tabAimbot.CreateCycle("Target Part", "AimbotTarget", TargetOptions)
tabAimbot.CreateSlider("Smoothness", "AimbotSmoothness", 0.1, 1, true)
tabAimbot.CreateSection("FOV Settings")
tabAimbot.CreateToggle("Draw FOV Circle", "AimbotDrawFOV")
tabAimbot.CreateSlider("FOV Radius", "AimbotFOV", 10, 500, false)

local tabPlayer = createTab("Player")
tabPlayer.CreateSection("Movement Toggles")
tabPlayer.CreateToggle("Enable WalkSpeed Mods", "WalkSpeedToggle")
tabPlayer.CreateSlider("WalkSpeed", "WalkSpeed", 16, 200, false)
tabPlayer.CreateToggle("Enable JumpPower Mods", "JumpPowerToggle")
tabPlayer.CreateSlider("JumpPower", "JumpPower", 50, 300, false)

tabPlayer.CreateSection("Abilities & Safety")
tabPlayer.CreateToggle("Infinite Jump", "InfJump")
tabPlayer.CreateToggle("No Clip", "Noclip")
tabPlayer.CreateToggle("Fly Mode", "Fly")
tabPlayer.CreateSlider("Fly Speed", "FlySpeed", 50, 300, false)
tabPlayer.CreateToggle("Safewalk", "Safewalk")

tabPlayer.CreateSection("Combat & Vision")
tabPlayer.CreateToggle("Spinbot / Fling", "Spinbot")
tabPlayer.CreateToggle("Anti-Aim", "AntiAim")
tabPlayer.CreateToggle("Enable Custom FOV", "FOVToggle") 
tabPlayer.CreateSlider("Camera FOV", "FOV", 70, 120, false)
tabPlayer.CreateToggle("Hitbox Expander", "HitboxExpander")
tabPlayer.CreateSlider("Hitbox Size", "HitboxSize", 5, 30, false)

local tabUtility = createTab("Utility")
tabUtility.CreateSection("Keybinds & Utilities")
tabUtility.CreateToggle("Click Teleport [T]", "ClickTP")
tabUtility.CreateToggle("Show Watermark", "Watermark")
tabUtility.CreateButton("Server Hopper", Color3.fromRGB(50, 100, 150), ServerHop)

local tabExternal = createTab("External Scripts")
tabExternal.CreateSection("Script Hubs & Utilities")
tabExternal.CreateButton("Shadow Hub", Color3.fromRGB(50, 100, 150), function()
    loadstring(game:HttpGet("https://obj.wearedevs.net/s/69d5534db0c382a50995864f.lua"))()
end)
tabExternal.CreateButton("Dex Explorer", Color3.fromRGB(50, 100, 150), function()
    loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/Dex%20Explorer.lua"))()
end)
tabExternal.CreateButton("Infinite Yield", Color3.fromRGB(50, 100, 150), function()
    loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/Infinite%20Yield.lua"))()
end)
tabExternal.CreateButton("UNC Checker", Color3.fromRGB(50, 100, 150), function()
    loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/UNC%20Checker.lua"))()
end)

local tabConfig = createTab("Config")
tabConfig.CreateSection("Configuration")
-- Auto Reattach Toggle added below
tabConfig.CreateToggle("Auto Reattach on Rejoin", "AutoReattach")
tabConfig.CreateButton("Save Current Settings", Color3.fromRGB(50, 100, 150), SaveConfig)
tabConfig.CreateButton("Load Saved Settings", Color3.fromRGB(50, 100, 150), LoadConfig)

-- ==========================================
-- 5. Window Control & Strict Cleanup
-- ==========================================

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    contentWrapper.Visible = not isMinimized
    minimizeBtn.Text = isMinimized and "+" or "-"

    local targetSize = isMinimized and UDim2.new(0, 480, 0, 30) or UDim2.new(0, 480, 0, 320)
    TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = targetSize}):Play()
end)

Connections.ToggleUI = UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightControl then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

local dragging, dragStart, startPos
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local function DestroyScript()
    for _, conn in pairs(Connections) do conn:Disconnect() end

    for _, line in pairs(Drawings) do
        if line and line.Remove then line:Remove() end
    end
    
    for _, pSkeletons in pairs(Skeletons) do
        for _, sLine in pairs(pSkeletons) do
            if sLine and sLine.Remove then sLine:Remove() end
        end
    end

    if FOVCircle and FOVCircle.Remove then FOVCircle:Remove() end

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head and head:FindFirstChild("NameTagESP") then
                head.NameTagESP:Destroy()
            end

            local glow = player.Character:FindFirstChild("GlowESP")
            if glow then glow:Destroy() end

            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and originalSizes[player.Name] then
                hrp.Size = originalSizes[player.Name]
                hrp.Transparency = 1
                hrp.CanCollide = true
            end
        end
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum.AutoRotate = true
            -- Restore defaults safely
            if originalStats.Character == char then
                hum.WalkSpeed = originalStats.WalkSpeed
                hum.JumpPower = originalStats.JumpPower
                hum.UseJumpPower = originalStats.UseJumpPower
            else
                hum.WalkSpeed = 16
                hum.JumpPower = 50
            end
        end

        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local flyBody = rootPart:FindFirstChild("FlyBodyVelocity")
            if flyBody then flyBody:Destroy() end

            local spinBody = rootPart:FindFirstChild("SpinbotVelocity")
            if spinBody then spinBody:Destroy() end
        end
    end

    Camera.FieldOfView = 70
    if watermarkLabel then watermarkLabel:Destroy() end
    screenGui:Destroy()
end

tabConfig.CreateSection("Script System")
tabConfig.CreateButton("DESTROY SCRIPT", Color3.fromRGB(180, 40, 40), DestroyScript)
