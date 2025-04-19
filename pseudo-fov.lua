getgenv().global = getgenv()

local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
local Camera = cloneref(Workspace.CurrentCamera)

local targetOffset = Vector3.new(0, 0, config.pseudoFov)

local function updateCamera()
    Camera.CFrame = Camera.CFrame + Camera.CFrame:VectorToWorldSpace(targetOffset)
end

RunService.RenderStepped:Connect(function()
    targetOffset = Vector3.new(0, 0, config.pseudoFov)
    updateCamera()
end)
