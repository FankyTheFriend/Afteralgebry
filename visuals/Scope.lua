local config = getgenv().config
local PlayerGui = getgenv().PlayerGui
local RunService = getgenv().RunService

local function clearScope()

    if not config.hideScopeImage and not config.clearScope then
        return
    end

    local crosshair = PlayerGui:FindFirstChild("Crosshair")

    if crosshair then
        local scope = crosshair:FindFirstChild("Scope")

        if scope then
            if config.hideScopeImage then

                scope.Visible = false

            elseif config.clearScope then

                scope.Visible = true
                for _, child in ipairs(scope:GetChildren()) do
                    if child:IsA("ImageLabel") then
                        child.ImageTransparency = 1
                    end
                    child.BackgroundTransparency = 1
                    child.Transparency = 1
                end
            end
        end
    end
end
RunService.RenderStepped:Connect(clearScope)
