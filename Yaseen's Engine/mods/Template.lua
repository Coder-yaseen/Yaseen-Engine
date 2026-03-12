return function(register)
    -- Helper function to make adding these easier (uses 0-255 for RGB instead of 0.0-1.0)
    local function r(id, name, matType, red, green, blue, density)
        register(id, name, matType, {red/255, green/255, blue/255}, density)
    end

    r("cool material", "Cool Material", "solid", 255, 0, 0, 1)




end