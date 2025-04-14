local PlayerGui = getgenv().PlayerGui

local BackgroundUI = PlayerGui.GameUI.BackgroundUI

local function hideEffects()
    for _, effect in ipairs(BackgroundUI:GetChildren()) do
        if effect.Name == "GasMaskUI" then
            effect.Vignette.ImageTransparency = 1
        end
    end
end
hideEffects()
BackgroundUI.ChildAdded:Connect(hideEffects)
