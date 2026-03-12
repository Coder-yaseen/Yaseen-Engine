local Materials = require("materials")

-- Configuration
local gridWidth, gridHeight = 150, 100
local cellSize = 6
local grid = {}
local matIds = {}
local currentMatIndex = 1
local brushSize = 2

function love.load()

    -- Enable Resizing and Maximizing
    love.window.setMode(gridWidth * cellSize, gridHeight * cellSize + 80, {
        resizable = true,
        minwidth = 400,
        minheight = 300
    })
    love.window.setTitle("Sandboxels - Modded Reaction Engine")
    
    Materials.register("sand", "Sand", "powder", {0.76, 0.70, 0.50}, 1, { ["water"] = "wet sand" })
    Materials.register("water", "Water", "liquid", {0.2, 0.4, 1})
    Materials.register("stone", "Stone", "solid", {0.5, 0.5, 0.5}, 3)
    Materials.register("wet sand", "Wet Sand", "powder", {0.6, 0.5, 0.4}, 1.5)

    -- 1. Load Mods from the /mods folder
    Materials.loadMods()
    
    -- 2. Index materials for the UI
    for id, _ in pairs(Materials.registry) do
        table.insert(matIds, id)
    end
    table.sort(matIds)
    
    initGrid()
end

function initGrid()
    for y = 1, gridHeight do
        grid[y] = {}
        for x = 1, gridWidth do grid[y][x] = nil end
    end
end

-- Mouse Wheel logic for Brush Size
function love.wheelmoved(x, y)
    if y > 0 then
        brushSize = math.min(brushSize + 1, 20)
    elseif y < 0 then
        brushSize = math.max(brushSize - 1, 0)
    end
end

function love.update(dt)
    -- Input Handling
    if love.mouse.isDown(1) and #matIds > 0 then 
        paint(love.mouse.getX(), love.mouse.getY(), matIds[currentMatIndex]) 
    end
    if love.mouse.isDown(2) then 
        paint(love.mouse.getX(), love.mouse.getY(), nil) 
    end

    local newGrid = {}
    for y = 1, gridHeight do newGrid[y] = {} end

    -- Physics & Reaction Loop
    for y = gridHeight, 1, -1 do
        for x = 1, gridWidth do
            local id = grid[y][x]
            if id then
                local m = Materials.registry[id]
                if not m then goto next_pixel end -- Safety check

                -- --- SIMPLIFIED REACTION SYSTEM ---
                -- Pick one random neighbor to check for a reaction
                local nx, ny = x + love.math.random(-1, 1), y + love.math.random(-1, 1)
                if nx >= 1 and nx <= gridWidth and ny >= 1 and ny <= gridHeight then
                    local targetId = grid[ny][nx]
                    if targetId and m.reactions and m.reactions[targetId] then
                        -- Change the neighbor based on the mod's rules
                        grid[ny][nx] = m.reactions[targetId]
                        -- 10% chance the source material is consumed
                        if love.math.random() > 0.9 then id = nil end
                    end
                end

                if not id then goto next_pixel end

                -- --- MOVEMENT SYSTEM ---
                local moved = false
                if m.type == "powder" or m.type == "liquid" then
                    -- Fall Down
                    if y < gridHeight and not (grid[y+1][x] or newGrid[y+1][x]) then
                        newGrid[y+1][x], moved = id, true
                    -- Slide Diagonally
                    elseif y < gridHeight then
                        local dir = love.math.random() > 0.5 and 1 or -1
                        if x+dir >= 1 and x+dir <= gridWidth and not (grid[y+1][x+dir] or newGrid[y+1][x+dir]) then
                            newGrid[y+1][x+dir], moved = id, true
                        end
                    end
                end

                -- Spread Horizontally (Liquids only)
                if m.type == "liquid" and not moved then
                    local dir = love.math.random() > 0.5 and 1 or -1
                    if x+dir >= 1 and x+dir <= gridWidth and not (grid[y][x+dir] or newGrid[y][x+dir]) then
                        newGrid[y][x+dir], moved = id, true
                    end
                end

                if not moved then newGrid[y][x] = id end
            end
            ::next_pixel::
        end
    end
    grid = newGrid
end

function paint(mx, my, id)
    local gx, gy = math.floor(mx/cellSize)+1, math.floor(my/cellSize)+1
    for dy = -brushSize, brushSize do
        for dx = -brushSize, brushSize do
            local nx, ny = gx+dx, gy+dy
            if nx >=1 and nx <= gridWidth and ny >=1 and ny <= gridHeight then 
                grid[ny][nx] = id 
            end
        end
    end
end

function love.keypressed(k)
    if #matIds > 0 then
        if k == "right" then currentMatIndex = (currentMatIndex % #matIds) + 1
        elseif k == "left" then currentMatIndex = (currentMatIndex - 2 + #matIds) % #matIds + 1
        end
    end
end

function love.draw()
    -- Render Grid
    for y = 1, gridHeight do
        for x = 1, gridWidth do
            if grid[y][x] then
                local mat = Materials.registry[grid[y][x]]
                if mat then
                    love.graphics.setColor(mat.color[1], mat.color[2], mat.color[3])
                    love.graphics.rectangle("fill", (x-1)*cellSize, (y-1)*cellSize, cellSize, cellSize)
                end
            end
        end
    end

    -- UI Overlay
    love.graphics.setColor(1, 1, 1)
    local matName = matIds[currentMatIndex] or "None"
    love.graphics.print("Material: " .. matName .. " | Brush: " .. brushSize, 10, gridHeight * cellSize + 10)
    love.graphics.print("Scroll to Resize | Left/Right to Swap", 10, gridHeight * cellSize + 35)
end