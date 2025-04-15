local global = getgenv()

local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
-- local npcs = Workspace.game_assets.NPCs:GetChildren()
local Players = cloneref(game:GetService("Players"))

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local objectsToShow = {}


-- local ZombieSearcher = {}
-- ZombieSearcher.isBlackCardZombie = function(zombieModel)

--     if not zombieModel:FindFirstChild("Equipment") then
--         return false
--     end
--     for _, obj in ipairs(zombieModel.Equipment:GetDescendants()) do
--         if obj:IsA("BasePart") then
--             if string.find(string.lower(obj.Name), "beret") 
--             or string.find(string.lower(obj.Name), "insigna") then
--                 return true
--             end
--         end
--     end
--     return false


-- end
-- ZombieSearcher.checkIsZombieHaveEquipment = function(zombie)
--     if not zombie:FindFirstChild("Equipment") then
--         return false
--     end

--     if #zombie.Equipment:GetChildren() == 2 then
--         totalChildren = 0
--         for _, model in ipairs(zombie.Equipment:GetChildren()) do
            

--             totalChildren += #model:GetChildren()

           

--         end
--         if totalChildren == 0 then
--             return false
--         end
--     end

--     return true

-- end

-- ZombieSearcher.isRedCardZombie = function(zombieModel)

--     if not zombieModel:FindFirstChild("Equipment") then
--         return false
--     end
--     if zombieModel.Torso.Shirt.ColorMap == "rbxassetid://17661939530" then
--         return true
--     end
--     if #zombieModel:GetDescendants() == 84 then
--         return true
--     end

--     return false

-- end

-- ZombieSearcher.search = function()

--     if not config.showChineseZombies and not config.showTacticalZombies then
--         return
--     end

--     for index, zombieModel in ipairs(npcs) do
--         if zombieModel:IsA("Model") then
--             if not objectsToShow[zombieModel] and ZombieSearcher.checkIsZombieHaveEquipment(zombieModel) then
                
--                 if (zombieModel.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude > 10000 then
--                     continue
--                 end
                
--                 if config.showChineseZombies then
--                     if ZombieSearcher.isRedCardZombie(zombieModel) then
--                         objectsToShow[zombieModel] = {
--                             part = zombieModel.HumanoidRootPart,
--                             text = "Chinese Zombie",
--                             color = Color3.fromRGB(255, 0, 0),
--                         }
--                         continue
--                     end
--                 end
--                 if config.showTacticalZombies then
--                     if ZombieSearcher.isBlackCardZombie(zombieModel) then
--                         objectsToShow[zombieModel] = {
--                             part = zombieModel.HumanoidRootPart,
--                             text = "Tactical Zombie",
--                             color = Color3.fromRGB(0, 255, 0),
--                         }
--                         continue
--                     end
--                 end
--             end
--         end
--     end
-- end


local function findGranades()
    if config.showGrenades then
        for _, child in ipairs(Workspace:GetChildren()) do
            if not objectsToShow[child] and child.Name=="Grenade" and child:FindFirstChild("Handle") then
                objectsToShow[child] = {

                    part = child.Handle,
                    text = "Grenade",
                    color = Color3.fromRGB(187, 0, 0),

                }
            end
        end
    end
end

local function createText(txt, color)
    local text = Drawing.new("Text")
    text.Size = 20
    text.Text = txt
    text.Color = color
    text.Center = true

    return text
end

local function search()
    findGranades()
end

RunService.RenderStepped:Connect(function()
    search()

    local toRemove = {}
    for target, object in pairs(objectsToShow) do
        if not object.part:FindFirstAncestorOfClass("Workspace") then
            if object.textUi then
                object.textUi.Visible = false
                object.textUi:Destroy()
            end
            table.insert(toRemove, 1, target)
            continue
        end
        local screenPos, visible = Camera:WorldToViewportPoint(object.part.Position)
        if visible then
            local textUi = object.textUi
            if not textUi then
                textUi = createText(object.text, object.color)
                object.textUi = textUi
            end 
            textUi.Visible = true
            textUi.Position = screenPos

        elseif object.textUi then
            object.textUi.Visible = false
        end       
    end
    for _, target in ipairs(toRemove) do
        objectsToShow[target] = nil
    end
end)