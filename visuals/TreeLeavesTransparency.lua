local config = getgenv().config
local Workspace = getgenv().Workspace

local function hideLeaves(obj)
    if obj:IsA("Part") or obj:IsA("MeshPart") then
        if string.find(obj.Name:lower(), "leaves") then
            obj.Transparency = config.leavesTransparency
        end
    end
end
for _, obj in ipairs(Workspace.world_assets.StaticObjects.Trees:GetDescendants()) do
    hideLeaves(obj)
end
Workspace.world_assets.StaticObjects.DescendantAdded:Connect(hideLeaves)