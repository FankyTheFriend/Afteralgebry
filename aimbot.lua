print("aim started")

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
local Camera = Workspace.CurrentCamera
local Replicated = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local LocalPlayer = Players.LocalPlayer

global = getgenv()

global.aimEnabled = true

-- Таблица для хранения исключений
global.ExcludedPlayers = {}

local function getFullCharacterModel(character)

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

    local nearest

    minDist = 999999999
    for _, fullCharacter in ipairs(Workspace.Characters:GetChildren()) do
        local upperTorso = fullCharacter:FindFirstChild("UpperTorso")
        if upperTorso then
            local distance = (humanoidRootPart.Position - upperTorso.Position).Magnitude
            if distance <= minDist then
                nearest = fullCharacter
                minDist = distance
            end
        end
    end

    return nearest
end

local function getHead(character)
    if config.UseOriginalHead then
        if game.GameId == 41210807 then -- for the gun testing
            local fullModel = getFullCharacterModel(character)
            if fullModel then
                local head = fullModel:FindFirstChild("Head")
                if head then
                    return head
                end
            end
            warn("Failed to find original head in GunTesting mode")
            return character:FindFirstChild("ServerColliderHead")
            
        else
            local worldCharacter = character:FindFirstChild("WorldCharacter")
            if worldCharacter then
                local head = worldCharacter:FindFirstChild("Head")
                if head then
                    return head
                end
            end
            warn("Failed to find original head in Aftermath mode")
            return character:FindFirstChild("ServerColliderHead")
        end
    else
        return character:FindFirstChild("ServerColliderHead")
    end
end

-- Global declaration system
function global.declare(self, index, value, check)
    if self[index] == nil then
        self[index] = value
    elseif check then
        pcall(function() value:Disconnect() end)
    end
    return self[index]
end

declare(global, "services", {})

-- Service management
function global.get(service)
    return services[service]
end

-- Main modules
declare(declare(services, "loop", {}), "cache", {})
declare(declare(services, "player", {}), "cache", {})
declare(global, "features", {})



-- Drawing setup
declare(services, "drawing", {
    Circle = Drawing.new("Circle"),
    DebugLine = Drawing.new("Line"),
    DebugBStext = Drawing.new("Text"),
    DebugServerHeadVizualization = Drawing.new("Square"),
    CloseRangeText = Drawing.new("Text"),
    TargetModeText = Drawing.new("Text"), -- Новый текстовый элемент
    IgnoreListText = Drawing.new("Text")
})

--uis
get("drawing").Circle.Visible = true
get("drawing").Circle.Color = Color3.fromRGB(0,0,0)
get("drawing").Circle.Thickness = 2
get("drawing").Circle.NumSides = 50
get("drawing").Circle.Radius = config.CircleRadius
get("drawing").Circle.Filled = false

get("drawing").DebugLine.Color = Color3.fromRGB(0, 255, 0)
get("drawing").DebugLine.Thickness = 2
get("drawing").DebugLine.Transparency = 0.8
get("drawing").DebugLine.Visible = false

get("drawing").DebugBStext.Visible = true
get("drawing").DebugBStext.Color = Color3.fromRGB(0,0,0)
get("drawing").DebugBStext.Size = 15
get("drawing").DebugBStext.Center = true
get("drawing").DebugBStext.Text = "Bullet speed: ???"

get("drawing").DebugServerHeadVizualization.Size = Vector2.new(8,8)
get("drawing").DebugServerHeadVizualization.Thickness = 1
get("drawing").DebugServerHeadVizualization.Color = Color3.fromRGB(255, 255, 255)
get("drawing").DebugServerHeadVizualization.Filled = false

-- Настройка текстовых уведомлений
get("drawing").CloseRangeText.Visible = false
get("drawing").CloseRangeText.Color = Color3.fromRGB(255, 50, 50)
get("drawing").CloseRangeText.Size = 20
get("drawing").CloseRangeText.Font = 2
get("drawing").CloseRangeText.Outline = true
get("drawing").CloseRangeText.Text = "CLOSE RANGE MODE"

get("drawing").TargetModeText.Visible = false
get("drawing").TargetModeText.Color = Color3.fromRGB(255, 100, 100)
get("drawing").TargetModeText.Size = 20
get("drawing").TargetModeText.Font = 2
get("drawing").TargetModeText.Outline = true
get("drawing").TargetModeText.Text = "AIM TO NEAREST TARGET MODE"

-- get("drawing").IgnoreListText.Text = "Player Ignore List: \n"
-- get("drawing").IgnoreListText.Color = Color3.fromRGB(0, 255, 0)
-- get("drawing").IgnoreListText.Size = 20
-- get("drawing").IgnoreListText.Font = 2
-- get("drawing").IgnoreListText.Outline = true
-- get("drawing").IgnoreListText.Visible = config.IgnoreListTextEnabled
--

-- FPS tracking system
declare(services, "fps", {
    currentFPS = 60,
    lastUpdate = tick(),
    frameCount = 0,
    
    update = function(self)
        self.frameCount = self.frameCount + 1
        local now = tick()
        local elapsed = now - self.lastUpdate
        if elapsed >= 1 then
            self.currentFPS = self.frameCount / elapsed
            self.frameCount = 0
            self.lastUpdate = now
        end
    end
})

-- Weapon system
declare(services, "weapon", {
    getHeldItem = function(self, player)
        local target = player:FindFirstChild("CurrentSelectedObject")
        return target and target.Value and target.Value.Value
    end,

    getBulletSpeed = function(self, player)
        local heldItem = self:getHeldItem(player)
        if not heldItem then return config.BaseBulletSpeed end
        
        local gunData = Replicated:WaitForChild("GunData")
        local weapon = gunData:FindFirstChild(heldItem.Name)
        
        if weapon 
        and weapon:FindFirstChild("Stats") 
        and weapon.Stats:FindFirstChild("BulletSettings")
        and weapon.Stats.BulletSettings:FindFirstChild("BulletSpeed")
        and weapon.Stats.BulletSettings.BulletSpeed.Value then
            get("drawing").DebugBStext.Text = `Bullet speed: {weapon.Stats.BulletSettings.BulletSpeed.Value}`
            return weapon.Stats.BulletSettings.BulletSpeed.Value 
        else
            get("drawing").DebugBStext.Text = `Bullet speed: {config.BaseBulletSpeed}(default, bcs unknown)`
            return config.BaseBulletSpeed
        end
    end
})

-- Prediction system с FPS-коррекцией и усилением на близкой дистанции
declare(services, "prediction", {
    calculate = function(self, targetPos, targetVel, bulletSpeed)
        local localPlayerVel = Vector3.new(0, 0, 0)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            localPlayerVel = LocalPlayer.Character.HumanoidRootPart.Velocity
        end
        
        local relativeVelocity = targetVel - localPlayerVel
        local distance = (targetPos - Camera.CFrame.Position).Magnitude
        local travelTime = distance / bulletSpeed

        -- Коррекция на основе FPS
        local fpsData = get("fps")
        local currentFPS = fpsData.currentFPS
        local referenceFPS = 60
        local fpsFactor = referenceFPS / math.max(currentFPS, 1)
        fpsFactor = math.clamp(fpsFactor, 0.5, 2)

        -- Дополнительный множитель для близкой дистанции
        local closeRangeBoost = 1.0
        if distance < config.CloseRangeThreshold then
            local boostFactor = 1 + (config.CloseRangeBoost - 1) * (1 - distance/config.CloseRangeThreshold)
            closeRangeBoost = math.clamp(boostFactor, 1, config.CloseRangeBoost)
        end

        local velocityMultiplier = 1.054  * closeRangeBoost * config.PredictionBoost
        local gravityMultiplier = 1.052 * closeRangeBoost * config.PredictionBoost
        
        return targetPos + relativeVelocity * travelTime * velocityMultiplier + 
               Vector3.new(0, config.Gravity * travelTime^2 * gravityMultiplier, 0)
    end
})

-- Targeting system
declare(services, "target", {
    currentTarget = nil,
    mouseHeld = false,

    findNearestToCursor = function(self)
        local nearest, minDist = nil, config.CircleRadius
        local mousePos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

        for _, player in Players:GetPlayers() do
            if player ~= LocalPlayer and player.Character and not global.ExcludedPlayers[player] then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart and player.Character:FindFirstChild("ServerColliderHead") then
                    local screenPos = Camera:WorldToViewportPoint(rootPart.Position)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < minDist then
                        nearest = player
                        minDist = dist
                    end
                end
            end
        end
        return nearest
    end,

    findNearestByDistance = function(self)
        local nearest, minDist = nil, config.MaxDistance

        for _, player in Players:GetPlayers() do
            if player ~= LocalPlayer and player.Character and not global.ExcludedPlayers[player] then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart and player.Character:FindFirstChild("ServerColliderHead") then
                    local distance = (rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    if distance <= minDist then
                        nearest = player
                        minDist = distance
                    end
                end
            end
        end
        return nearest
    end,

    aim = function(self)
        if not self.currentTarget or not self.currentTarget.Character then return end
        
        local head = getHead(self.currentTarget.Character)
        local serverHead = self.currentTarget.Character:FindFirstChild("ServerColliderHead")
        if head then
            local predictedPos = get("prediction"):calculate(
                head.Position,
                serverHead.Velocity,
                get("weapon"):getBulletSpeed(LocalPlayer)
            )
            local screenPos = Camera:WorldToViewportPoint(predictedPos)
            mousemoverel(screenPos.X - Camera.ViewportSize.X/2 + math.random(-config.RandomJigger, config.RandomJigger), 
                         screenPos.Y - Camera.ViewportSize.Y/2 + math.random(-config.RandomJigger, config.RandomJigger))
            do  
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.FilterDescendantsInstances = {
                    Workspace.CurrentCamera, 
                    LocalPlayer.Character, 
                }
                local origin = Camera.CFrame.Position
                local direction = head.Position - Camera.CFrame.Position

                local rayResult = workspace:Raycast(origin, direction, raycastParams)
                warn(head.CanQuery)
                -- warn(rayResult.Instance.Parent:GetFullName(),"BRUH", head.Parent:GetFullName())
                if rayResult and rayResult.Position then
                    local a = Instance.new("Part", Workspace)
                    a.Anchored = true
                    a.Position = rayResult.Position
                    a.Size = Vector3.new(1,1,1)
                    a.CanCollide = false
                    a.CanQuery = false
                end
                if rayResult then
                    print(rayResult.Instance:GetFullName())
                end
                if rayResult and (rayResult.Instance.Parent == head.Parent or rayResult.Instance.Parent == self.currentTarget.Character) then
                    print("PREKOL")
                end
            end
        end
    end
})

-- UI system
declare(services, "ui", {
    updateCircle = function(self)
        local screenSize = Camera.ViewportSize
        get("drawing").Circle.Position = Vector2.new(screenSize.X/2, screenSize.Y/2)
        get("drawing").Circle.Radius = config.CircleRadius
        get("drawing").Circle.Color = config.CircleColor
        
    end,
    updateBSText = function(self)
        if config.ShowBulletSpeed then
            local screenSize = Camera.ViewportSize
            get("drawing").DebugBStext.Visible = true
            get("drawing").DebugBStext.Position = Vector2.new(screenSize.X/2, (screenSize.Y/2 + config.CircleRadius) + 5)
        else
            get("drawing").DebugBStext.Visible = false
        end
    end,
    updateModesVisualization = function(aimToNearestMode, closeRangeMode)
        if config.ShowActiveModes then
            get("drawing").TargetModeText.Visible = aimToNearestMode
            get("drawing").CloseRangeText.Visible = closeRangeMode
        else
            get("drawing").TargetModeText.Visible = false
            get("drawing").CloseRangeText.Visible = false
        end
    end,
    updateDebugLine = function(self)
        if not config.DebugLineEnabled then
            get("drawing").DebugLine.Visible = false
            return
        end

        local target = get("target"):findNearestToCursor()
        if target and target.Character then
            local serverHead = target.Character:FindFirstChild("ServerColliderHead")
            if serverHead then
                local predictedPos = get("prediction"):calculate(
                    serverHead.Position,
                    serverHead.Velocity,
                    get("weapon"):getBulletSpeed(LocalPlayer)
                )
                
                local screenPos = Camera:WorldToViewportPoint(predictedPos)
                get("drawing").Color = config.DebugLineColor
                get("drawing").DebugLine.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                get("drawing").DebugLine.To = Vector2.new(screenPos.X, screenPos.Y)
                get("drawing").DebugLine.Visible = true
                return
            end
        end
        get("drawing").DebugLine.Visible = false
    end,
    updateServerHeadVisualization = function(self)
        if not config.ShowDebugServerHeadVizualization then
            get("drawing").DebugServerHeadVizualization.Visible = false
            return
        end

        local target = get("target"):findNearestByDistance()
        if not target then
            get("drawing").DebugServerHeadVizualization.Visible = false
            return
        end
            
        local head = getHead(target.Character)
        local screenPos, visible = Camera:WorldToViewportPoint(head.Position)
        if not visible then
            get("drawing").DebugServerHeadVizualization.Visible = false
            return
        end
        get("drawing").DebugServerHeadVizualization.Visible = true
        get("drawing").DebugServerHeadVizualization.Position = Vector2.new(screenPos.X - get("drawing").DebugServerHeadVizualization.Size.X/2, screenPos.Y - get("drawing").DebugServerHeadVizualization.Size.Y/2)

        -- do
        --     local rayOrigin = Camera.CFrame.Position
        --     local rayDestination = head.Position
        --     local rayDirection = rayDestination - rayOrigin

        --     local raycastParams = RaycastParams.new()
        --     raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, target.Character.ServerCollider, Camera}
        --     raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        --     raycastParams.IgnoreWater = true

        --     local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        --     warn(raycastResult, Camera.CFrame.Position)
        --     if raycastResult and raycastResult.Instance then
        --         print(raycastResult.Instance:GetFullName())
        --     end
        --     if raycastResult and raycastResult.Instance:IsAncestorOf(target.Character) then
        --         get("drawing").DebugServerHeadVizualization.Color = Color3.new(1,0,0)
        --     else
        --         get("drawing").DebugServerHeadVizualization.Color = Color3.new(0,0,0)
        --     end
        -- end
    end
})

-- Input system
declare(services, "input", {
    connections = {},

    init = function(self)
        declare(self.connections, "mouseHold", 
            UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    get("target").mouseHeld = true
                end
            end), true)

        declare(self.connections, "mouseRelease", 
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    get("target").mouseHeld = false
                    get("target").currentTarget = nil
                end
            end), true)

        -- declare(self.connections, "toggleAim", 
        --     UserInputService.InputBegan:Connect(function(input)
        --         if input.KeyCode == Enum.KeyCode.F2 then
        --             global.aimEnabled = not global.aimEnabled
        --             get("drawing").Circle.Visible = global.aimEnabled
        --         end
        --     end), true)

        -- declare(self.connections, "toggleExclude", 
        --     UserInputService.InputBegan:Connect(function(input)
        --         if input.KeyCode == Enum.KeyCode.RightControl then
        --             local target = findPlayerUnderCursor()
        --             if target then
        --                 toggleExcludedPlayer(target)
        --             end
        --         end
        --     end), 
        -- true)
    end
})

-- Feature system
declare(features, "aimbot", {
    enabled = true,
    toggle = function(self)
        self.enabled = not self.enabled
        print("Aimbot " .. (self.enabled and "enabled" or "disabled"))
    end
})

-- Main loop
declare(get("loop"), "main", 
    RunService.RenderStepped:Connect(function()
        get("fps"):update()
        get("ui"):updateCircle()
        get("ui"):updateDebugLine()
        get("ui"):updateBSText()
        get("ui"):updateDebugLine()
        get("ui"):updateServerHeadVisualization()
        
        
        local nearestByDistance = get("target"):findNearestByDistance()
        local closeRangeActive = false
        local targetModeActive = false

        if nearestByDistance then
            local distance = (nearestByDistance.Character.HumanoidRootPart.Position - 
                            LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                            
            -- Проверка дистанций
            targetModeActive = distance <= config.MaxDistance
            closeRangeActive = distance < config.CloseRangeThreshold
        end

        get("ui"):updateModesVisualization(targetModeActive, closeRangeActive)
        
        -- Позиционирование текста
        local yPos = Camera.ViewportSize.Y - 60
        get("drawing").TargetModeText.Position = Vector2.new(20, yPos)
        get("drawing").CloseRangeText.Position = Vector2.new(20, yPos - 30)
        
        
        if global.ignoreListText then
            local playerNames = {}
            for k,v in pairs(global.ExcludedPlayers) do
                if k and k.Name then
                    playerNames[#playerNames+1] = k.Name
                end
            end
            
            global.ignoreListText:SetText("Player Ignore List: \n\n"..table.concat(playerNames, ",\n"))
        end

        if get("target").mouseHeld and features.aimbot.enabled and global.aimEnabled then
            if nearestByDistance then
                get("target").currentTarget = nearestByDistance
            else
                get("target").currentTarget = get("target"):findNearestToCursor()
            end

            if get("target").currentTarget then
                get("target"):aim()
            end
        end
    end),
true)

-- Initialization
get("input"):init()

print("Aimbot initialized")