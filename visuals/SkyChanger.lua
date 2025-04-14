local Lighting = getgenv().Lighting

return function(imageId)
    local oldsky = Lighting:FindFirstChildOfClass("Sky")
    if oldsky and oldsky.Name ~= "_coolSky" then oldsky:Destroy() end

    local sky = Lighting:FindFirstChild("_coolSky")
    if not sky then
        sky = Instance.new("Sky", Lighting)
        sky.Name = "_coolSky"
    end

    local id = "rbxassetid://"..imageId

    sky.SkyboxBk = id
    sky.SkyboxDn = id
    sky.SkyboxFt = id
    sky.SkyboxLf = id
    sky.SkyboxRt = id
    sky.SkyboxUp = id
end
