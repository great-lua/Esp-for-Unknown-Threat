local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
print("Rayfield loaded")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
print("Services obtained")

_G.StopRainbow = false

local Drawings = {}
local Settings = {
    Enabled = true,
    BoxESP = false,
    BoxStyle = "Corner",
    BoxThickness = 1,
    SkeletonESP = false,
    SkeletonThickness = 1.5,
    NameESP = false,
    HealthESP = false,
    HealthBarWidth = 4,
    ShowHealthText = false,
    TracerESP = false,
    TracerOrigin = "Bottom",
    TracerThickness = 1,
    PointESP = false,
    PointSize = 5,
    MaxDistance = 400,
    TeamCheck = false,
    RainbowEnabled = false,
    RainbowSpeed = 1,
    ShowDistance = false,
}

local Colors = {
    Seeker = Color3.fromRGB(255, 0, 0),
    Killer = Color3.fromRGB(255, 0, 0),
    Hider = Color3.fromRGB(255, 200, 0),
    Innocent = Color3.fromRGB(0, 255, 0),
    Traitor = Color3.fromRGB(255, 0, 255),
    Police = Color3.fromRGB(0, 100, 255),
    Swat = Color3.fromRGB(0, 80, 200),
    Sheriff = Color3.fromRGB(0, 150, 255),
    Juggernaut = Color3.fromRGB(255, 165, 0),
    NoRole = Color3.fromRGB(255, 255, 255),
    Unknown = Color3.fromRGB(150, 150, 150),
    Rainbow = nil,
}
print("Settings and Colors defined")

local function GetWorkspaceSettingsFolder()
    local folder = workspace:FindFirstChild("ESP_Settings")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "ESP_Settings"
        folder.Parent = workspace
        print("Created ESP_Settings folder in workspace")
    end
    return folder
end

local function SaveWorkspaceSetting(key, value)
    local success, err = pcall(function()
        local folder = GetWorkspaceSettingsFolder()
        local obj = folder:FindFirstChild(key)
        local typeVal = type(value)
        if typeVal == "boolean" then
            if not obj or not obj:IsA("BoolValue") then
                if obj then obj:Destroy() end
                obj = Instance.new("BoolValue")
                obj.Name = key
                obj.Parent = folder
            end
            obj.Value = value
        elseif typeVal == "number" then
            if not obj or not obj:IsA("NumberValue") then
                if obj then obj:Destroy() end
                obj = Instance.new("NumberValue")
                obj.Name = key
                obj.Parent = folder
            end
            obj.Value = value
        elseif typeVal == "string" then
            if not obj or not obj:IsA("StringValue") then
                if obj then obj:Destroy() end
                obj = Instance.new("StringValue")
                obj.Name = key
                obj.Parent = folder
            end
            obj.Value = value
        elseif typeVal == "Color3" then
            if not obj or not obj:IsA("Color3Value") then
                if obj then obj:Destroy() end
                obj = Instance.new("Color3Value")
                obj.Name = key
                obj.Parent = folder
            end
            obj.Value = value
        end
    end)
    if not success then
        warn("SaveWorkspaceSetting error for key=" .. tostring(key) .. ": " .. tostring(err))
    end
end

local function LoadSettingsFromWorkspace()
    local success, err = pcall(function()
        local folder = GetWorkspaceSettingsFolder()
        for _, child in ipairs(folder:GetChildren()) do
            local key = child.Name
            if Settings[key] ~= nil then
                if child:IsA("BoolValue") then
                    Settings[key] = child.Value
                elseif child:IsA("NumberValue") then
                    Settings[key] = child.Value
                elseif child:IsA("StringValue") then
                    Settings[key] = child.Value
                elseif child:IsA("Color3Value") then
                    if Colors[key] ~= nil then
                        Colors[key] = child.Value
                    else
                        Settings[key] = child.Value
                    end
                end
            elseif Colors[key] ~= nil then
                if child:IsA("Color3Value") then
                    Colors[key] = child.Value
                end
            end
        end
    end)
    if not success then
        warn("LoadSettingsFromWorkspace error: " .. tostring(err))
    else
        print("Settings loaded from workspace")
    end
end
LoadSettingsFromWorkspace()

local function GetPlayerRole(player)
    local success, result = pcall(function()
        local character = player.Character
        if not character then return "NoRole" end
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return "NoRole" end
        local roleAttr = player:GetAttribute("Role")
        local deathRole = player:GetAttribute("DeathRole")
        local roleStr = nil
        if roleAttr ~= nil and roleAttr ~= "" and tostring(roleAttr) ~= "nil" then
            roleStr = tostring(roleAttr):upper()
        end
        if not roleStr and deathRole ~= nil and deathRole ~= "" and tostring(deathRole) ~= "nil" then
            roleStr = tostring(deathRole):upper()
        end
        if not roleStr then
            return "NoRole"
        end
        if roleStr:find("SEEKER") then return "Seeker" end
        if roleStr:find("KILLER") then return "Killer" end
        if roleStr:find("HIDER") then return "Hider" end
        if roleStr:find("INNOCENT") then return "Innocent" end
        if roleStr:find("TRAITOR") then return "Traitor" end
        if roleStr:find("POLICE") then return "Police" end
        if roleStr:find("SWAT") then return "Swat" end
        if roleStr:find("SHERIFF") then return "Sheriff" end
        if roleStr:find("JUGGERNAUT") then return "Juggernaut" end
        return "Unknown"
    end)
    if not success then
        warn("GetPlayerRole error for " .. tostring(player.Name) .. ": " .. tostring(result))
        return "NoRole"
    end
    return result
end

local function IsTeammate(player)
    local localRole = GetPlayerRole(LocalPlayer)
    local targetRole = GetPlayerRole(player)
    if localRole == "Unknown" or targetRole == "Unknown" then return false end
    if localRole == "NoRole" or targetRole == "NoRole" then return false end
    local function isGood(role)
        return role == "Hider" or role == "Innocent" or role == "Police" or role == "Swat" or role == "Sheriff" or role == "Juggernaut"
    end
    local function isBad(role)
        return role == "Seeker" or role == "Killer" or role == "Traitor"
    end
    if isGood(localRole) and isGood(targetRole) then return true end
    if isBad(localRole) and isBad(targetRole) then return true end
    return false
end

local function GetPlayerColor(player)
    if Settings.RainbowEnabled then
        return Colors.Rainbow
    end
    local role = GetPlayerRole(player)
    return Colors[role] or Colors.Unknown
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    local success, err = pcall(function()
        local esp = {
            Box = {
                Left = Drawing.new("Line"),
                Right = Drawing.new("Line"),
                Top = Drawing.new("Line"),
                Bottom = Drawing.new("Line"),
                TL = Drawing.new("Line"),
                TR = Drawing.new("Line"),
                BL = Drawing.new("Line"),
                BR = Drawing.new("Line"),
            },
            Name = Drawing.new("Text"),
            Health = {
                Outline = Drawing.new("Square"),
                Fill = Drawing.new("Square"),
                Text = Drawing.new("Text"),
            },
            Tracer = Drawing.new("Line"),
            Point = Drawing.new("Circle"),
            Skeleton = {},
        }
        for _, line in pairs(esp.Box) do
            line.Visible = false
            line.Color = Color3.fromRGB(255,255,255)
            line.Thickness = Settings.BoxThickness
        end
        esp.Name.Visible = false
        esp.Name.Center = true
        esp.Name.Size = 14
        esp.Name.Font = 2
        esp.Name.Outline = true
        esp.Name.Color = Color3.fromRGB(255,255,255)
        for _, obj in pairs(esp.Health) do
            obj.Visible = false
            if obj == esp.Health.Fill then
                obj.Filled = true
            elseif obj == esp.Health.Text then
                obj.Center = true
                obj.Size = 12
                obj.Font = 2
                obj.Outline = true
            end
        end
        esp.Tracer.Visible = false
        esp.Tracer.Color = Color3.fromRGB(255,255,255)
        esp.Tracer.Thickness = Settings.TracerThickness
        esp.Point.Visible = false
        esp.Point.Radius = Settings.PointSize
        esp.Point.Thickness = 1
        esp.Point.Filled = true
        esp.Point.NumSides = 20
        local boneNames = {
            "Head", "UpperTorso", "LowerTorso",
            "LeftUpperArm", "LeftLowerArm", "LeftHand",
            "RightUpperArm", "RightLowerArm", "RightHand",
            "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
            "RightUpperLeg", "RightLowerLeg", "RightFoot"
        }
        for _, name in ipairs(boneNames) do
            local line = Drawing.new("Line")
            line.Visible = false
            line.Color = Color3.fromRGB(255,255,255)
            line.Thickness = Settings.SkeletonThickness
            esp.Skeleton[name] = line
        end
        Drawings[player] = esp
    end)
    if not success then
        warn("CreateESP error for " .. tostring(player.Name) .. ": " .. tostring(err))
    end
end

local function RemoveESP(player)
    local esp = Drawings[player]
    if not esp then return end
    local success, err = pcall(function()
        for _, line in pairs(esp.Box) do line:Remove() end
        esp.Name:Remove()
        for _, obj in pairs(esp.Health) do obj:Remove() end
        esp.Tracer:Remove()
        esp.Point:Remove()
        for _, line in pairs(esp.Skeleton) do line:Remove() end
        Drawings[player] = nil
    end)
    if not success then
        warn("RemoveESP error for " .. tostring(player.Name) .. ": " .. tostring(err))
    end
end

local function GetBonePositions(character)
    local bones = {}
    local function getPart(name, alt)
        local part = character:FindFirstChild(name)
        if not part and alt then part = character:FindFirstChild(alt) end
        return part
    end
    bones.Head = getPart("Head")
    bones.UpperTorso = getPart("UpperTorso", "Torso")
    bones.LowerTorso = getPart("LowerTorso", "Torso")
    bones.LeftUpperArm = getPart("LeftUpperArm", "Left Arm")
    bones.LeftLowerArm = getPart("LeftLowerArm", "Left Arm")
    bones.LeftHand = getPart("LeftHand", "Left Arm")
    bones.RightUpperArm = getPart("RightUpperArm", "Right Arm")
    bones.RightLowerArm = getPart("RightLowerArm", "Right Arm")
    bones.RightHand = getPart("RightHand", "Right Arm")
    bones.LeftUpperLeg = getPart("LeftUpperLeg", "Left Leg")
    bones.LeftLowerLeg = getPart("LeftLowerLeg", "Left Leg")
    bones.LeftFoot = getPart("LeftFoot", "Left Leg")
    bones.RightUpperLeg = getPart("RightUpperLeg", "Right Leg")
    bones.RightLowerLeg = getPart("RightLowerLeg", "Right Leg")
    bones.RightFoot = getPart("RightFoot", "Right Leg")
    return bones
end

local function GetTracerOrigin()
    local origin = Settings.TracerOrigin
    if origin == "Bottom" then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
    elseif origin == "Top" then
        return Vector2.new(Camera.ViewportSize.X/2, 0)
    elseif origin == "Mouse" then
        return UserInputService:GetMouseLocation()
    else
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end

local function UpdateESP(player)
    if not Settings.Enabled then return end
    local esp = Drawings[player]
    if not esp then return end

    local character = player.Character
    if not character then
        for _, line in pairs(esp.Box) do line.Visible = false end
        esp.Name.Visible = false
        for _, obj in pairs(esp.Health) do obj.Visible = false end
        esp.Tracer.Visible = false
        esp.Point.Visible = false
        for _, line in pairs(esp.Skeleton) do line.Visible = false end
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        for _, line in pairs(esp.Box) do line.Visible = false end
        esp.Name.Visible = false
        for _, obj in pairs(esp.Health) do obj.Visible = false end
        esp.Tracer.Visible = false
        esp.Point.Visible = false
        for _, line in pairs(esp.Skeleton) do line.Visible = false end
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        for _, line in pairs(esp.Box) do line.Visible = false end
        esp.Name.Visible = false
        for _, obj in pairs(esp.Health) do obj.Visible = false end
        esp.Tracer.Visible = false
        esp.Point.Visible = false
        for _, line in pairs(esp.Skeleton) do line.Visible = false end
        return
    end

    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude

    if not onScreen or distance > Settings.MaxDistance then
        for _, line in pairs(esp.Box) do line.Visible = false end
        esp.Name.Visible = false
        for _, obj in pairs(esp.Health) do obj.Visible = false end
        esp.Tracer.Visible = false
        esp.Point.Visible = false
        for _, line in pairs(esp.Skeleton) do line.Visible = false end
        return
    end

    if Settings.TeamCheck and IsTeammate(player) then
        for _, line in pairs(esp.Box) do line.Visible = false end
        esp.Name.Visible = false
        for _, obj in pairs(esp.Health) do obj.Visible = false end
        esp.Tracer.Visible = false
        esp.Point.Visible = false
        for _, line in pairs(esp.Skeleton) do line.Visible = false end
        return
    end

    local color = GetPlayerColor(player)

    local size = character:GetExtentsSize()
    local cf = rootPart.CFrame
    local top = Camera:WorldToViewportPoint((cf * CFrame.new(0, size.Y/2, 0)).Position)
    local bottom = Camera:WorldToViewportPoint((cf * CFrame.new(0, -size.Y/2, 0)).Position)

    if top.Z < 0 or bottom.Z < 0 then
        for _, line in pairs(esp.Box) do line.Visible = false end
        return
    end

    local screenSize = bottom.Y - top.Y
    local boxWidth = screenSize * 0.65
    local boxPos = Vector2.new(top.X - boxWidth/2, top.Y)
    local boxSize = Vector2.new(boxWidth, screenSize)

    if Settings.BoxESP then
        local b = esp.Box
        if Settings.BoxStyle == "Corner" then
            local cornerSize = boxWidth * 0.2
            b.TL.From = boxPos
            b.TL.To = boxPos + Vector2.new(cornerSize, 0)
            b.TL.Visible = true
            b.TR.From = boxPos + Vector2.new(boxSize.X, 0)
            b.TR.To = boxPos + Vector2.new(boxSize.X - cornerSize, 0)
            b.TR.Visible = true
            b.BL.From = boxPos + Vector2.new(0, boxSize.Y)
            b.BL.To = boxPos + Vector2.new(cornerSize, boxSize.Y)
            b.BL.Visible = true
            b.BR.From = boxPos + Vector2.new(boxSize.X, boxSize.Y)
            b.BR.To = boxPos + Vector2.new(boxSize.X - cornerSize, boxSize.Y)
            b.BR.Visible = true
            b.Left.From = boxPos
            b.Left.To = boxPos + Vector2.new(0, cornerSize)
            b.Left.Visible = true
            b.Right.From = boxPos + Vector2.new(boxSize.X, 0)
            b.Right.To = boxPos + Vector2.new(boxSize.X, cornerSize)
            b.Right.Visible = true
            b.Top.From = boxPos + Vector2.new(0, boxSize.Y)
            b.Top.To = boxPos + Vector2.new(0, boxSize.Y - cornerSize)
            b.Top.Visible = true
            b.Bottom.From = boxPos + Vector2.new(boxSize.X, boxSize.Y)
            b.Bottom.To = boxPos + Vector2.new(boxSize.X, boxSize.Y - cornerSize)
            b.Bottom.Visible = true
        else
            b.Left.From = boxPos
            b.Left.To = boxPos + Vector2.new(0, boxSize.Y)
            b.Left.Visible = true
            b.Right.From = boxPos + Vector2.new(boxSize.X, 0)
            b.Right.To = boxPos + Vector2.new(boxSize.X, boxSize.Y)
            b.Right.Visible = true
            b.Top.From = boxPos
            b.Top.To = boxPos + Vector2.new(boxSize.X, 0)
            b.Top.Visible = true
            b.Bottom.From = boxPos + Vector2.new(0, boxSize.Y)
            b.Bottom.To = boxPos + Vector2.new(boxSize.X, boxSize.Y)
            b.Bottom.Visible = true
            b.TL.Visible = false
            b.TR.Visible = false
            b.BL.Visible = false
            b.BR.Visible = false
        end
        for _, line in pairs(esp.Box) do
            if line.Visible then
                line.Color = color
                line.Thickness = Settings.BoxThickness
            end
        end
    else
        for _, line in pairs(esp.Box) do line.Visible = false end
    end

    if Settings.NameESP then
        local text = player.DisplayName
        if Settings.ShowDistance then
            text = text .. " (" .. math.floor(distance) .. "m)"
        end
        esp.Name.Text = text
        esp.Name.Position = Vector2.new(top.X, top.Y - 20)
        esp.Name.Color = color
        esp.Name.Visible = true
    else
        esp.Name.Visible = false
    end

    if Settings.HealthESP then
        local health = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        local healthPercent = health / maxHealth
        local barHeight = screenSize * 0.8
        local barWidth = Settings.HealthBarWidth
        local barPos = Vector2.new(boxPos.X - barWidth - 2, boxPos.Y + (screenSize - barHeight)/2)

        esp.Health.Outline.Size = Vector2.new(barWidth, barHeight)
        esp.Health.Outline.Position = barPos
        esp.Health.Outline.Visible = true

        esp.Health.Fill.Size = Vector2.new(barWidth - 2, barHeight * healthPercent)
        esp.Health.Fill.Position = Vector2.new(barPos.X + 1, barPos.Y + barHeight * (1 - healthPercent))
        esp.Health.Fill.Color = Color3.fromRGB(255 - (255 * healthPercent), 255 * healthPercent, 0)
        esp.Health.Fill.Visible = true

        if Settings.ShowHealthText then
            esp.Health.Text.Text = math.floor(health)
            esp.Health.Text.Position = Vector2.new(barPos.X + barWidth + 2, barPos.Y + barHeight/2)
            esp.Health.Text.Visible = true
        else
            esp.Health.Text.Visible = false
        end
    else
        for _, obj in pairs(esp.Health) do obj.Visible = false end
    end

    if Settings.TracerESP then
        esp.Tracer.From = GetTracerOrigin()
        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
        esp.Tracer.Color = color
        esp.Tracer.Visible = true
    else
        esp.Tracer.Visible = false
    end

    if Settings.PointESP then
        local head = character:FindFirstChild("Head")
        local headPos
        if head then
            headPos = Camera:WorldToViewportPoint(head.Position)
        else
            headPos = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 2, 0))
        end
        esp.Point.Position = Vector2.new(headPos.X, headPos.Y)
        esp.Point.Color = color
        esp.Point.Radius = Settings.PointSize
        esp.Point.Visible = true
    else
        esp.Point.Visible = false
    end

    if Settings.SkeletonESP then
        local bones = GetBonePositions(character)
        local function drawLine(fromPart, toPart, line)
            if not fromPart or not toPart then
                line.Visible = false
                return
            end
            local fromPos = Camera:WorldToViewportPoint((fromPart.CFrame * CFrame.new(0,0,0)).Position)
            local toPos = Camera:WorldToViewportPoint((toPart.CFrame * CFrame.new(0,0,0)).Position)
            if fromPos.Z < 0 or toPos.Z < 0 then
                line.Visible = false
                return
            end
            line.From = Vector2.new(fromPos.X, fromPos.Y)
            line.To = Vector2.new(toPos.X, toPos.Y)
            line.Color = color
            line.Thickness = Settings.SkeletonThickness
            line.Visible = true
        end

        local skel = esp.Skeleton
        drawLine(bones.Head, bones.UpperTorso, skel.Head)
        drawLine(bones.UpperTorso, bones.LowerTorso, skel.UpperTorso)
        drawLine(bones.UpperTorso, bones.LeftUpperArm, skel.LeftUpperArm)
        drawLine(bones.LeftUpperArm, bones.LeftLowerArm, skel.LeftLowerArm)
        drawLine(bones.LeftLowerArm, bones.LeftHand, skel.LeftHand)
        drawLine(bones.UpperTorso, bones.RightUpperArm, skel.RightUpperArm)
        drawLine(bones.RightUpperArm, bones.RightLowerArm, skel.RightLowerArm)
        drawLine(bones.RightLowerArm, bones.RightHand, skel.RightHand)
        drawLine(bones.LowerTorso, bones.LeftUpperLeg, skel.LeftUpperLeg)
        drawLine(bones.LeftUpperLeg, bones.LeftLowerLeg, skel.LeftLowerLeg)
        drawLine(bones.LeftLowerLeg, bones.LeftFoot, skel.LeftFoot)
        drawLine(bones.LowerTorso, bones.RightUpperLeg, skel.RightUpperLeg)
        drawLine(bones.RightUpperLeg, bones.RightLowerLeg, skel.RightLowerLeg)
        drawLine(bones.RightLowerLeg, bones.RightFoot, skel.RightFoot)
    else
        for _, line in pairs(esp.Skeleton) do line.Visible = false end
    end
end

local function CleanupESP()
    local success, err = pcall(function()
        for player, esp in pairs(Drawings) do
            for _, line in pairs(esp.Box) do line:Remove() end
            esp.Name:Remove()
            for _, obj in pairs(esp.Health) do obj:Remove() end
            esp.Tracer:Remove()
            esp.Point:Remove()
            for _, line in pairs(esp.Skeleton) do line:Remove() end
        end
        Drawings = {}
    end)
    if not success then
        warn("CleanupESP error: " .. tostring(err))
    else
        print("ESP cleaned up")
    end
end

local Window = Rayfield:CreateWindow({
    Name = "Unknown Threat ESP",
    LoadingTitle = "Unknown Threat ESP",
    LoadingSubtitle = "by Great | discord.gg/nTMYauyf59",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
    ShowText = "ESP",
})
print("Window created")

local MainTab = Window:CreateTab("Main", 0)
local VisualsTab = Window:CreateTab("Visuals", 0)
local SettingsTab = Window:CreateTab("Settings", 0)
print("Tabs created")

MainTab:CreateSection("ESP Toggles")

local toggleEnabled = MainTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = Settings.Enabled,
    Callback = function(Value)
        Settings.Enabled = Value
        SaveWorkspaceSetting("Enabled", Settings.Enabled)
        if not Settings.Enabled then
            for _, esp in pairs(Drawings) do
                for _, line in pairs(esp.Box) do line.Visible = false end
                esp.Name.Visible = false
                for _, obj in pairs(esp.Health) do obj.Visible = false end
                esp.Tracer.Visible = false
                esp.Point.Visible = false
                for _, line in pairs(esp.Skeleton) do line.Visible = false end
            end
        end
        print("Enable ESP set to", Value)
    end
})

MainTab:CreateToggle({
    Name = "Box ESP",
    CurrentValue = Settings.BoxESP,
    Callback = function(Value)
        Settings.BoxESP = Value
        SaveWorkspaceSetting("BoxESP", Settings.BoxESP)
        print("Box ESP set to", Value)
    end
})

MainTab:CreateToggle({
    Name = "Skeleton ESP",
    CurrentValue = Settings.SkeletonESP,
    Callback = function(Value)
        Settings.SkeletonESP = Value
        SaveWorkspaceSetting("SkeletonESP", Settings.SkeletonESP)
        print("Skeleton ESP set to", Value)
    end
})

MainTab:CreateToggle({
    Name = "Name ESP",
    CurrentValue = Settings.NameESP,
    Callback = function(Value)
        Settings.NameESP = Value
        SaveWorkspaceSetting("NameESP", Settings.NameESP)
        print("Name ESP set to", Value)
    end
})

MainTab:CreateToggle({
    Name = "Health Bar",
    CurrentValue = Settings.HealthESP,
    Callback = function(Value)
        Settings.HealthESP = Value
        SaveWorkspaceSetting("HealthESP", Settings.HealthESP)
        print("Health Bar set to", Value)
    end
})

MainTab:CreateToggle({
    Name = "Tracer ESP",
    CurrentValue = Settings.TracerESP,
    Callback = function(Value)
        Settings.TracerESP = Value
        SaveWorkspaceSetting("TracerESP", Settings.TracerESP)
        print("Tracer ESP set to", Value)
    end
})

MainTab:CreateToggle({
    Name = "Head Point",
    CurrentValue = Settings.PointESP,
    Callback = function(Value)
        Settings.PointESP = Value
        SaveWorkspaceSetting("PointESP", Settings.PointESP)
        print("Head Point set to", Value)
    end
})

MainTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Settings.TeamCheck,
    Callback = function(Value)
        Settings.TeamCheck = Value
        SaveWorkspaceSetting("TeamCheck", Settings.TeamCheck)
        print("Team Check set to", Value)
    end
})

MainTab:CreateToggle({
    Name = "Show Distance",
    CurrentValue = Settings.ShowDistance,
    Callback = function(Value)
        Settings.ShowDistance = Value
        SaveWorkspaceSetting("ShowDistance", Settings.ShowDistance)
        print("Show Distance set to", Value)
    end
})

VisualsTab:CreateSection("Box Settings")

VisualsTab:CreateDropdown({
    Name = "Box Style",
    Options = {"Corner", "Full"},
    CurrentOption = Settings.BoxStyle,
    Callback = function(Option)
        Settings.BoxStyle = Option
        SaveWorkspaceSetting("BoxStyle", Settings.BoxStyle)
        print("Box Style set to", Option)
    end
})

VisualsTab:CreateSlider({
    Name = "Box Thickness",
    Range = {1, 3},
    Increment = 1,
    CurrentValue = Settings.BoxThickness,
    Callback = function(Value)
        Settings.BoxThickness = Value
        SaveWorkspaceSetting("BoxThickness", Settings.BoxThickness)
        for _, esp in pairs(Drawings) do
            for _, line in pairs(esp.Box) do
                line.Thickness = Value
            end
        end
        print("Box Thickness set to", Value)
    end
})

VisualsTab:CreateSection("Tracer Settings")

VisualsTab:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Bottom", "Top", "Mouse", "Center"},
    CurrentOption = Settings.TracerOrigin,
    Callback = function(Option)
        Settings.TracerOrigin = Option
        SaveWorkspaceSetting("TracerOrigin", Settings.TracerOrigin)
        print("Tracer Origin set to", Option)
    end
})

VisualsTab:CreateSlider({
    Name = "Tracer Thickness",
    Range = {1, 3},
    Increment = 1,
    CurrentValue = Settings.TracerThickness,
    Callback = function(Value)
        Settings.TracerThickness = Value
        SaveWorkspaceSetting("TracerThickness", Settings.TracerThickness)
        for _, esp in pairs(Drawings) do
            esp.Tracer.Thickness = Value
        end
        print("Tracer Thickness set to", Value)
    end
})

VisualsTab:CreateSection("Health Settings")

VisualsTab:CreateSlider({
    Name = "Health Bar Width",
    Range = {2, 10},
    Increment = 1,
    CurrentValue = Settings.HealthBarWidth,
    Callback = function(Value)
        Settings.HealthBarWidth = Value
        SaveWorkspaceSetting("HealthBarWidth", Settings.HealthBarWidth)
        print("Health Bar Width set to", Value)
    end
})

VisualsTab:CreateToggle({
    Name = "Show Health Number",
    CurrentValue = Settings.ShowHealthText,
    Callback = function(Value)
        Settings.ShowHealthText = Value
        SaveWorkspaceSetting("ShowHealthText", Settings.ShowHealthText)
        print("Show Health Number set to", Value)
    end
})

VisualsTab:CreateSection("Point Settings")

VisualsTab:CreateSlider({
    Name = "Point Size",
    Range = {2, 15},
    Increment = 1,
    CurrentValue = Settings.PointSize,
    Callback = function(Value)
        Settings.PointSize = Value
        SaveWorkspaceSetting("PointSize", Settings.PointSize)
        for _, esp in pairs(Drawings) do
            esp.Point.Radius = Value
        end
        print("Point Size set to", Value)
    end
})

VisualsTab:CreateSection("Skeleton Settings")

VisualsTab:CreateSlider({
    Name = "Skeleton Thickness",
    Range = {1, 3},
    Increment = 0.5,
    CurrentValue = Settings.SkeletonThickness,
    Callback = function(Value)
        Settings.SkeletonThickness = Value
        SaveWorkspaceSetting("SkeletonThickness", Settings.SkeletonThickness)
        for _, esp in pairs(Drawings) do
            for _, line in pairs(esp.Skeleton) do
                line.Thickness = Value
            end
        end
        print("Skeleton Thickness set to", Value)
    end
})

SettingsTab:CreateSection("General")

SettingsTab:CreateSlider({
    Name = "Max Distance",
    Range = {50, 2000},
    Increment = 1,
    CurrentValue = Settings.MaxDistance,
    Callback = function(Value)
        Settings.MaxDistance = Value
        SaveWorkspaceSetting("MaxDistance", Settings.MaxDistance)
        print("Max Distance set to", Value)
    end
})

SettingsTab:CreateToggle({
    Name = "Rainbow Mode",
    CurrentValue = Settings.RainbowEnabled,
    Callback = function(Value)
        Settings.RainbowEnabled = Value
        SaveWorkspaceSetting("RainbowEnabled", Settings.RainbowEnabled)
        print("Rainbow Mode set to", Value)
    end
})

SettingsTab:CreateSlider({
    Name = "Rainbow Speed",
    Range = {0.1, 5},
    Increment = 0.1,
    CurrentValue = Settings.RainbowSpeed,
    Callback = function(Value)
        Settings.RainbowSpeed = Value
        SaveWorkspaceSetting("RainbowSpeed", Settings.RainbowSpeed)
        print("Rainbow Speed set to", Value)
    end
})

SettingsTab:CreateSection("Role Colors")

SettingsTab:CreateColorPicker({
    Name = "No Role (Spawn)",
    Color = Colors.NoRole,
    Callback = function(Value)
        Colors.NoRole = Value
        SaveWorkspaceSetting("NoRoleColor", Colors.NoRole)
        print("No Role color updated")
    end
})

SettingsTab:CreateColorPicker({
    Name = "Seeker / Killer",
    Color = Colors.Seeker,
    Callback = function(Value)
        Colors.Seeker = Value
        Colors.Killer = Value
        SaveWorkspaceSetting("SeekerColor", Colors.Seeker)
        SaveWorkspaceSetting("Killer", Colors.Killer)
        print("Seeker/Killer color updated")
    end
})

SettingsTab:CreateColorPicker({
    Name = "Hider",
    Color = Colors.Hider,
    Callback = function(Value)
        Colors.Hider = Value
        SaveWorkspaceSetting("HiderColor", Colors.Hider)
        print("Hider color updated")
    end
})

SettingsTab:CreateColorPicker({
    Name = "Innocent",
    Color = Colors.Innocent,
    Callback = function(Value)
        Colors.Innocent = Value
        SaveWorkspaceSetting("InnocentColor", Colors.Innocent)
        print("Innocent color updated")
    end
})

SettingsTab:CreateColorPicker({
    Name = "Police / SWAT / Sheriff",
    Color = Colors.Police,
    Callback = function(Value)
        Colors.Police = Value
        Colors.Swat = Value
        Colors.Sheriff = Value
        SaveWorkspaceSetting("PoliceColor", Colors.Police)
        SaveWorkspaceSetting("Swat", Colors.Swat)
        SaveWorkspaceSetting("Sheriff", Colors.Sheriff)
        print("Police/SWAT/Sheriff color updated")
    end
})

SettingsTab:CreateColorPicker({
    Name = "Traitor",
    Color = Colors.Traitor,
    Callback = function(Value)
        Colors.Traitor = Value
        SaveWorkspaceSetting("TraitorColor", Colors.Traitor)
        print("Traitor color updated")
    end
})

SettingsTab:CreateColorPicker({
    Name = "Juggernaut",
    Color = Colors.Juggernaut,
    Callback = function(Value)
        Colors.Juggernaut = Value
        SaveWorkspaceSetting("JuggernautColor", Colors.Juggernaut)
        print("Juggernaut color updated")
    end
})

SettingsTab:CreateColorPicker({
    Name = "Unknown (fallback)",
    Color = Colors.Unknown,
    Callback = function(Value)
        Colors.Unknown = Value
        SaveWorkspaceSetting("UnknownColor", Colors.Unknown)
        print("Unknown color updated")
    end
})

task.spawn(function()
    print("Rainbow loop started")
    while not _G.StopRainbow do
        local waitSuccess, waitErr = pcall(function()
            task.wait(0.05)
        end)
        if not waitSuccess then
            warn("Rainbow loop wait error: " .. tostring(waitErr))
            break
        end
        if not _G.StopRainbow then
            local colorSuccess, colorErr = pcall(function()
                Colors.Rainbow = Color3.fromHSV(tick() * Settings.RainbowSpeed % 1, 1, 1)
            end)
            if not colorSuccess then
                warn("Rainbow color update error: " .. tostring(colorErr))
            end
        end
    end
    print("Rainbow loop stopped")
end)

local renderConnection
renderConnection = RunService.RenderStepped:Connect(function()
    local renderSuccess, renderErr = pcall(function()
        if not Settings.Enabled then
            for _, esp in pairs(Drawings) do
                for _, line in pairs(esp.Box) do line.Visible = false end
                esp.Name.Visible = false
                for _, obj in pairs(esp.Health) do obj.Visible = false end
                esp.Tracer.Visible = false
                esp.Point.Visible = false
                for _, line in pairs(esp.Skeleton) do line.Visible = false end
            end
            return
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if not Drawings[player] then
                    CreateESP(player)
                end
                UpdateESP(player)
            end
        end
    end)
    if not renderSuccess then
        warn("RenderStepped error: " .. tostring(renderErr))
    end
end)
print("RenderStepped connection established")

Players.PlayerAdded:Connect(function(player)
    local success, err = pcall(function()
        if player ~= LocalPlayer then
            CreateESP(player)
        end
    end)
    if not success then
        warn("PlayerAdded error for " .. tostring(player.Name) .. ": " .. tostring(err))
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local success, err = pcall(function()
        if player ~= LocalPlayer then
            RemoveESP(player)
        end
    end)
    if not success then
        warn("PlayerRemoving error for " .. tostring(player.Name) .. ": " .. tostring(err))
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        local success, err = pcall(function()
            CreateESP(player)
        end)
        if not success then
            warn("Initial CreateESP error for " .. tostring(player.Name) .. ": " .. tostring(err))
        end
    end
end

local notifySuccess, notifyErr = pcall(function()
    Rayfield:Notify({
        Title = "Unknown Threat ESP",
        Content = "Loaded! Settings saved in workspace. Join discord.gg/nTMYauyf59",
        Duration = 4
    })
end)
if not notifySuccess then
    warn("Notification error: " .. tostring(notifyErr))
end

print("Script fully loaded")
