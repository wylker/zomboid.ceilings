--***********************************************************
--**                    BUILD ROOF B42                     **
--**    Ceiling-Specific Server-side Build Recipe Code     **
--***********************************************************

print("BuildCeilingCode - Loading ceiling build recipe functions...")

-- Create the BuildRecipeCode table if it doesn't exist
if not BuildRecipeCode then
    BuildRecipeCode = {}
end

if not BuildRecipeCode.ceiling then
    BuildRecipeCode.ceiling = {}
end

--************************************************************************--
--** BuildRecipeCode.ceiling.OnIsValid - Ceiling placement validation
--************************************************************************--
function BuildRecipeCode.ceiling.OnIsValid(params)
    -- Safety check for params
    if not params or not params.square then
        return false
    end
    
    local square = params.square
    local x, y, z = square:getX(), square:getY(), square:getZ()
    
    -- Check for stairs below (floors can't be built above stairs)
    if z > 0 then
        local below = getCell():getGridSquare(x, y, z - 1)
        if below and below:HasStairs() then
            return false
        end
    end
    
    -- Check for existing conflicting objects
    local tileInfoSprite = params.tileInfo:getSpriteName()
    for i = 0, square:getObjects():size() - 1 do
        local item = square:getObjects():get(i)
        
        -- Check for farming vegetation (can't build ceiling over crops)
        if (item:getTextureName() and luautils.stringStarts(item:getTextureName(), "vegetation_farming")) or
                (item:getSpriteName() and luautils.stringStarts(item:getSpriteName(), "vegetation_farming")) then
            return false
        end
        
        -- Check for duplicate sprites
        if (item:getTextureName() and item:getTextureName() == tileInfoSprite) or
                (item:getSpriteName() and item:getSpriteName() == tileInfoSprite) then
            return false
        end
    end
    
    -- CEILING-SPECIFIC VALIDATION: Check for structural support
    local hasSupport = false
    
    -- Check if connected to existing floor at same level (ceiling expansion)
    if square:connectedWithFloor() then
        hasSupport = true
    end
    
    -- Check for wall support at ground level (z-1)
    if not hasSupport and z > 0 then
        local groundSquare = getCell():getGridSquare(x, y, z - 1)
        if groundSquare then
            -- Check if ground square has supporting walls
            if groundSquare:Is(IsoFlagType.WallN) or groundSquare:Is(IsoFlagType.WallW) or 
               groundSquare:Is(IsoFlagType.WallNTrans) or groundSquare:Is(IsoFlagType.WallWTrans) then
                hasSupport = true
            end
        end
        
        -- Check for walls that "reach" into this square to provide support
        if not hasSupport then
            -- West facing wall in x+1, z-1 (east square with wall reaching west)
            local eastSquare = getCell():getGridSquare(x+1, y, z-1)
            if eastSquare and (eastSquare:Is(IsoFlagType.WallW) or eastSquare:Is(IsoFlagType.WallWTrans)) then
                hasSupport = true
            end
            
            -- North facing wall in y+1, z-1 (south square with wall reaching north)
            if not hasSupport then
                local southSquare = getCell():getGridSquare(x, y+1, z-1)
                if southSquare and (southSquare:Is(IsoFlagType.WallN) or southSquare:Is(IsoFlagType.WallNTrans)) then
                    hasSupport = true
                end
            end
        end
    end
    
    -- Check for floor support at ceiling level in adjacent squares
    if not hasSupport then
        local adjacentCeilingSquares = {
            getCell():getGridSquare(x-1, y, z),  -- West
            getCell():getGridSquare(x+1, y, z),  -- East
            getCell():getGridSquare(x, y-1, z),  -- North  
            getCell():getGridSquare(x, y+1, z),  -- South
        }
        
        for _, adjSquare in ipairs(adjacentCeilingSquares) do
            if adjSquare and adjSquare:Is(IsoFlagType.solidfloor) then
                hasSupport = true
                break
            end
        end
    end
    
    if not hasSupport then
        return false
    end
    
    -- Disable collision testing since we've done our own validation
    params.testCollisions = false
    
    return true
end

--************************************************************************--
--** BuildRecipeCode.ceiling.OnCreate - Ceiling creation logic  
--************************************************************************--
function BuildRecipeCode.ceiling.OnCreate(params)
    local thumpable = params.thumpable
    local square = thumpable:getSquare()
    local objects = square:getObjects()
    
    -- Remove conflicting objects (similar to floor logic but ceiling-appropriate)
    local rug = nil
    for i=objects:size()-1, 0, -1 do
        local object = objects:get(i)
        if object and object ~= thumpable then
            local objProps = object:getProperties()
            local shouldRemove = objProps and (
                object:getProperties():Is(IsoFlagType.canBeRemoved) or 
                object:getProperties():Is(IsoFlagType.noStart) or 
                (object:getProperties():Is(IsoFlagType.vegitation) and object:getType() ~= IsoObjectType.tree) or 
                object:getProperties():Is(IsoFlagType.taintedWater)
            )
            
            -- Remove grass overlays
            shouldRemove = shouldRemove or (object:getTextureName() ~= nil and 
                string.contains(object:getTextureName(), "blends_grassoverlays"))
            
            -- Handle rugs specially
            if object:getTextureName() ~= nil and string.contains(object:getTextureName(), "floors_rugs") then
                rug = object
                shouldRemove = false
            end
            
            if shouldRemove then
                square:transmitRemoveItemFromSquare(object)
                square:RemoveTileObject(object)
            end
        end
    end
    
    -- Handle rug positioning (ensure ceiling is under rug if present)
    if rug ~= nil then
        local rugIndex = objects:indexOf(rug)
        local ceilingIndex = objects:indexOf(thumpable)
        if rugIndex < ceilingIndex then
            -- Swap positions so ceiling is under rug
            objects:set(rugIndex, thumpable)
            objects:set(ceilingIndex, rug)
        end
    end
    
    -- Update square properties and surroundings
    square:EnsureSurroundNotNull()
    square:RecalcProperties()
    
    -- Register ceiling for animal designation zones
    DesignationZoneAnimal.addNewRoof(square:getX(), square:getY(), square:getZ())
    square:getCell():checkHaveRoof(square:getX(), square:getY())
    
    -- Ensure squares exist below and connect them
    for z = square:getZ()-1, 0, -1 do
        local below = getCell():getGridSquare(square:getX(), square:getY(), z)
        if below == nil then
            below = IsoGridSquare.getNew(getCell(), nil, square:getX(), square:getY(), z)
            getCell():ConnectNewSquare(below, false)
        end
        below:EnsureSurroundNotNull()
        below:RecalcAllWithNeighbours(true)
    end
    
    -- Clear water and disable erosion
    square:clearWater()
    square:disableErosion()
    local args = { x = square:getX(), y = square:getY(), z = square:getZ() }
    sendServerCommand('erosion', 'disableForSquare', args)
    
    -- Update lighting and rendering
    invalidateLighting()
    square:setSquareChanged()
    thumpable:invalidateRenderChunkLevel(FBORenderChunk.DIRTY_OBJECT_ADD)
end

print("BuildCeilingCode - Ceiling build recipe functions loaded successfully!")