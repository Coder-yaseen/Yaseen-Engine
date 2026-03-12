local Materials = {}
Materials.registry = {}

function Materials.register(id, name, matType, color, density, reactions)
    Materials.registry[id] = {
        name = name,
        type = matType,   -- "solid", "powder", "liquid", "gas"
        color = color,    -- {R, G, B}
        density = density,
        reactions = reactions or {} -- Example: { ["water"] = "mud" }
    }
end

function Materials.loadMods()
    local files = love.filesystem.getDirectoryItems("mods")
    for _, file in ipairs(files) do
        if file:sub(-4) == ".lua" then
            local chunk = love.filesystem.load("mods/" .. file)
            if chunk then
                local modFunc = chunk()
                if type(modFunc) == "function" then
                    modFunc(Materials.register)
                end
            end
        end
    end
end

return Materials