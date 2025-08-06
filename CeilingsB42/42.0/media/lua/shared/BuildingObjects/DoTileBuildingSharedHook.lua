--***********************************************************
--**                    BUILD ROOF B42                     **
--**     Selective DoTileBuildingShared Hook for Ceilings  **
--***********************************************************

print("DoTileBuildingSharedHook - Loading selective ceiling hook...")

--************************************************************************--
--** Helper function to check if an item is a ceiling entity
--************************************************************************--
local function isCeilingEntity(cursor)
    if not cursor then 
        return false 
    end
    
    -- Check for the flag set by ISBuildPanel hook
    if cursor.isCeilingBuild then
        return true
    end
    
    -- Fallback: Check entity name for backwards compatibility
    if cursor.objectInfo and cursor.objectInfo.getName then
        local success, entityName = pcall(cursor.objectInfo.getName, cursor.objectInfo)
        if success then
            local ceilingEntities = {
                "RoofTestFloor",
                "rooftestfloor",
            }
            
            for _, ceilingName in ipairs(ceilingEntities) do
                if entityName == ceilingName then
                    return true
                end
            end
        end
    end
    
    -- Additional fallback: check item name/type if available
    if cursor.name and luautils.stringStarts(cursor.name, "Roof") then
        return true
    end
    
    return false
end

--************************************************************************--
--** Selective ceiling handler - renders ceiling ghost at z+1
--************************************************************************--
local function handleCeilingBuilding(cursor, bRender, x, y, z, square)
    -- Only handle ceiling entities
    if not (cursor and isCeilingEntity(cursor)) then
        return -- Let original handler deal with non-ceiling items
    end
    
    if bRender then
        -- This is a RENDER call - render ceiling ghost at z+1
        local ceilingZ = cursor.ceilingZ or (z + 1)
        
        -- Create z+1 square if it doesn't exist
        local ceilingSquare = getCell():getGridSquare(x, y, ceilingZ)
        if not ceilingSquare and getWorld():isValidSquare(x, y, ceilingZ) then
            ceilingSquare = getCell():createNewGridSquare(x, y, ceilingZ, true)
        end
        
        -- Render the ceiling ghost at z+1 
        if ceilingSquare then
            cursor:render(x, y, ceilingZ, ceilingSquare)
        end
        
        -- Update cursor state for building
        cursor.square = ceilingSquare
        
        -- Let original handler run to render the floor ghost
        return
    else
        -- This is a VALIDATION/LOGIC call - let it pass through to original system
        -- Don't return - let the original handler run for validation
    end
end

-- Debug: Check what Events are available
if Events then
    if Events.OnDoTileBuilding2 then
        Events.OnDoTileBuilding2.Add(handleCeilingBuilding)
        print("DoTileBuildingSharedHook - OnDoTileBuilding2 hook installed!")
    end
    
    if Events.OnDoTileBuilding3 then
        Events.OnDoTileBuilding3.Add(handleCeilingBuilding)
        print("DoTileBuildingSharedHook - OnDoTileBuilding3 hook installed!")
    end
end

print("DoTileBuildingSharedHook - Selective ceiling rendering hook installation complete!")