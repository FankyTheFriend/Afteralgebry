local Lighting = getgenv().Lighting

local doNotDestroy = {

    ["Bloom"] = true,
    ["_ambientEffect"] = true,
    ["_coolSky"] = true,

}

print("removing fog...")
for _, child in ipairs(Lighting:GetChildren()) do
    if not doNotDestroy[child.Name] then
        child:Destroy()
    end
end
print("fog removed")