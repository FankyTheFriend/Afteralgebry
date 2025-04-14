local Lighting = getgenv().Lighting

return function(color)
    local ambientEffect = Lighting:FindFirstChild("_ambientEffect")
    if not ambientEffect then
        ambientEffect = Instance.new("ColorCorrectionEffect", Lighting)
        ambientEffect.Name = "_ambientEffect"
    end
    ambientEffect.TintColor = color
end
