--[[ 
    OffenseWare Mobile | Arsenal "Legit-Blatant"
    ESP: Custom Mobile Optimized
    Aimbot: Closest to Mouse + Wallcheck
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // 1. LIBRARY LADEN //
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/OffenseWare-OF/OffenseWare-lib/main/OffenseWare.lua"))()
local Window = Library:CreateWindow("OffenseWare | V9.0")

local CombatTab = Window:CreateTab("Combat")
local VisualTab = Window:CreateTab("Visuals")
local GunTab = Window:CreateTab("Gun Mods")
local MoveTab = Window:CreateTab("Movement")
local SettingsTab = Window:CreateTab("Settings")

-- // CONFIG //
local Config = {
    Aimbot = {
        Enabled = false,
        FOV = 120,
        Smoothing = 0.5,
        WallCheck = true,
        Part = "Head"
    },
    ESP = {
        Enabled = false,
        Boxes = true,
        Names = false,
        Health = false
    },
    Gun = {
        InfAmmo = false,
        FastFire = false,
        NoRecoil = false
    },
    Fly = {
        Enabled = false,
        Speed = 50
    }
}

-- // UTILS: WALLCHECK //
local function IsVisible(targetPart)
    if not Config.Aimbot.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, params)
    
    if result then
        if result.Instance:IsDescendantOf(targetPart.Parent) then
            return true
        end
        return false
    end
    return true
end

-- // UTILS: TEAM CHECK //
local function IsEnemy(player)
    if not player or not player.Team then return true end -- Falls FFA
    return player.Team ~= LocalPlayer.Team
end

-- // AIMBOT LOGIC //
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(170, 60, 255)
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 24
FOVCircle.Filled = false

local function GetClosestTargetInFOV()
    local closest = nil
    local shortestDist = math.huge
    local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local fovRad = Config.Aimbot.FOV

    for _, v in ipairs(Players:GetPlayers()) do
        -- STRICT ENEMY CHECK
        if v ~= LocalPlayer and IsEnemy(v) then
            local char = v.Character
            if char and char:FindFirstChild(Config.Aimbot.Part) and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                
                local part = char[Config.Aimbot.Part]
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                
                if onScreen then
                    -- Distanz zum Fadenkreuz (Nearest in FOV)
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    
                    if dist < shortestDist and dist <= fovRad then
                        -- WallCheck
                        if IsVisible(part) then
                            closest = part
                            shortestDist = dist
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Config.Aimbot.FOV
    FOVCircle.Visible = Config.Aimbot.Enabled

    if Config.Aimbot.Enabled then
        local targetPart = GetClosestTargetInFOV()
        if targetPart then
            local current = Camera.CFrame
            local goal = CFrame.new(current.Position, targetPart.Position)
            -- Smoothing anwenden
            Camera.CFrame = current:Lerp(goal, Config.Aimbot.Smoothing)
        end
    end
end)

-- // ESP LOGIC (MOBILE OPTIMIZED BILLBOARD) //
local ESP_Storage = {}

local function CreateESP(plr)
    if ESP_Storage[plr] then return end
    
    local Box = Instance.new("BillboardGui")
    Box.Name = "OW_ESP"
    Box.AlwaysOnTop = true -- Kein Wallcheck für ESP (sehen durch Wände)
    Box.Size = UDim2.new(4, 0, 5.5, 0)
    Box.StudsOffset = Vector3.new(0, 0, 0)
    Box.Adornee = nil
    
    local Frame = Instance.new("Frame")
    Frame.Parent = Box
    Frame.Size = UDim2.new(1, 0, 1, 0)
    Frame.BackgroundTransparency = 1
    Frame.BorderSizePixel = 0
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Parent = Frame
    Stroke.Color = Color3.fromRGB(255, 0, 0)
    Stroke.Thickness = 1.5
    Stroke.Transparency = 0
    
    local NameTag = Instance.new("TextLabel")
    NameTag.Parent = Frame
    NameTag.Size = UDim2.new(1, 0, 0, 20)
    NameTag.Position = UDim2.new(0, 0, -0.3, 0)
    NameTag.BackgroundTransparency = 1
    NameTag.Text = plr.Name
    NameTag.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameTag.TextStrokeTransparency = 0
    NameTag.Font = Enum.Font.GothamBold
    NameTag.TextSize = 12
    NameTag.Visible = false
    
    ESP_Storage[plr] = {
        Main = Box,
        Stroke = Stroke,
        Name = NameTag
    }
end

local function RemoveESP(plr)
    if ESP_Storage[plr] then
        ESP_Storage[plr].Main:Destroy()
        ESP_Storage[plr] = nil
    end
end

RunService.RenderStepped:Connect(function()
    if Config.ESP.Enabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                -- ENEMY CHECK: Wenn Teammate, ESP entfernen/nicht erstellen
                if not IsEnemy(plr) then
                    RemoveESP(plr)
                else
                    if not ESP_Storage[plr] then
                        CreateESP(plr)
                    end
                    
                    local esp = ESP_Storage[plr]
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
                        esp.Main.Parent = game.CoreGui
                        esp.Main.Adornee = plr.Character.HumanoidRootPart
                        
                        -- Config Update
                        esp.Stroke.Enabled = Config.ESP.Boxes
                        esp.Name.Visible = Config.ESP.Names
                    else
                        esp.Main.Parent = nil
                    end
                end
            end
        end
    else
        for _, v in pairs(ESP_Storage) do
            v.Main.Parent = nil
        end
    end
end)

Players.PlayerRemoving:Connect(RemoveESP)

-- // LOGIC: GUN MODS (Optimized V3 - HitReg Fix) //
task.spawn(function()
    local RS = game:GetService("ReplicatedStorage")
    local wkspc = RS:WaitForChild("wkspc", 10)
    local Weapons = RS:WaitForChild("Weapons", 10)

    while true do
        if Config.Gun.InfAmmo or Config.Gun.FastFire or Config.Gun.NoRecoil then
            pcall(function()
                -- 1. Infinite Ammo
                if Config.Gun.InfAmmo and wkspc and wkspc:FindFirstChild("CurrentCurse") then
                    if wkspc.CurrentCurse.Value ~= "Infinite Ammo" then
                        wkspc.CurrentCurse.Value = "Infinite Ammo"
                    end
                end

                -- 2. Weapon Modifications
                if Weapons then
                    for _, v in ipairs(Weapons:GetChildren()) do
                        -- Fast Fire (Safe Mode: 0.04s)
                        -- Unter 0.04 registriert der Server Schüsse oft nicht (Lag/No Connect)
                        if Config.Gun.FastFire then
                            local fr = v:FindFirstChild("FireRate")
                            if fr and fr.Value > 0.04 then 
                                fr.Value = 0.04 
                            end
                            
                            
                            local auto = v:FindFirstChild("Auto")
                            if auto and auto.Value == false then
                                auto.Value = true
                            end
                        end

                        -- No Recoil & No Spread
                        if Config.Gun.NoRecoil then
                            local rc = v:FindFirstChild("RecoilControl")
                            local rec = v:FindFirstChild("Recoil")
                            local sp = v:FindFirstChild("Spread")
                            local msp = v:FindFirstChild("MaxSpread")

                            
                            if rc and rc.Value ~= 0 then rc.Value = 0 end
                            if rec and rec.Value ~= 0 then rec.Value = 0 end
                            if sp and sp.Value ~= 0 then sp.Value = 0 end
                            if msp and msp.Value ~= 0 then msp.Value = 0 end
                        end
                    end
                end
            end)
        end
        
        task.wait(1.5) 
    end
end)


-- // JOYSTICK FLY //
local flyBV, flyBG
local function ToggleFly(state)
    if state then
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = LocalPlayer.Character.HumanoidRootPart
        flyBV = Instance.new("BodyVelocity", hrp)
        flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBG = Instance.new("BodyGyro", hrp)
        flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        LocalPlayer.Character.Humanoid.PlatformStand = true
    else
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
        if LocalPlayer.Character then LocalPlayer.Character.Humanoid.PlatformStand = false end
    end
end

RunService.Heartbeat:Connect(function()
    if Config.Fly.Enabled and flyBV then
        local cam = workspace.CurrentCamera
        local move = LocalPlayer.Character.Humanoid.MoveDirection
        local flyDir = (cam.CFrame.LookVector * move.Z * -1) + (cam.CFrame.RightVector * move.X)
        flyBV.Velocity = move.Magnitude == 0 and Vector3.zero or flyDir * Config.Fly.Speed
        flyBG.CFrame = cam.CFrame
    end
end)

-- // UI SETUP //

-- COMBAT TAB
CombatTab:Section("Legit Aimbot")
CombatTab:CreateToggle("Enable Aimbot", false, function(v) Config.Aimbot.Enabled = v end)
CombatTab:CreateToggle("Wall Check", true, function(v) Config.Aimbot.WallCheck = v end)
CombatTab:CreateSlider("FOV Radius", 10, 400, 120, function(v) Config.Aimbot.FOV = v end)
CombatTab:CreateSlider("Smoothing", 1, 100, 50, function(v) Config.Aimbot.Smoothing = v/100 end)

-- VISUAL TAB
VisualTab:Section("ESP (Enemies Only)")
VisualTab:CreateToggle("Enable ESP", false, function(v) Config.ESP.Enabled = v end)
VisualTab:CreateToggle("Boxes", true, function(v) Config.ESP.Boxes = v end)
VisualTab:CreateToggle("Names", false, function(v) Config.ESP.Names = v end)

-- GUN TAB
GunTab:Section("Blatant")
GunTab:CreateToggle("Infinite Ammo", false, function(v) Config.Gun.InfAmmo = v end)
GunTab:CreateToggle("Fast Fire", false, function(v) Config.Gun.FastFire = v end)
GunTab:CreateToggle("No Recoil", false, function(v) Config.Gun.NoRecoil = v end)

-- MOVE TAB
MoveTab:Section("Movement")
MoveTab:CreateToggle("Joystick Fly", false, function(v) 
    Config.Fly.Enabled = v
    ToggleFly(v)
end)
MoveTab:CreateSlider("Fly Speed", 10, 200, 50, function(v) Config.Fly.Speed = v end)

-- SETTINGS
SettingsTab:Section("Config")
SettingsTab:CreateButton("Unload & Cleanup", function()
    Config.Aimbot.Enabled = false
    Config.ESP.Enabled = false
    ToggleFly(false)
    FOVCircle:Remove()
    for _, v in pairs(ESP_Storage) do v.Main:Destroy() end
    game.CoreGui:FindFirstChild("OffenseWareLib"):Destroy()
end)
