--***********************************************************
--**                    Ceilings! B42                      **
--**   Client-Side ISBuildPanel Hook for Ceiling Entities  **
--***********************************************************

print("ISBuildPanelHook - Loading ISBuildPanel hook...")

if not ISBuildPanel then
    print("ISBuildPanelHook - ERROR: ISBuildPanel not found!")
    return
end

local originalCreateBuildIsoEntity = ISBuildPanel.createBuildIsoEntity

print("ISBuildPanelHook - Original ISBuildPanel.createBuildIsoEntity stored")

--************************************************************************--
--** Helper function to check if a recipe has ceiling tags
--************************************************************************--
local function isCeilingRecipe(recipe)
    if not recipe then 
        return false 
    end
    
    local tagChecks = {
        function() return recipe:getTags() end,
        function() return recipe.tags end,
    }
    
    for i, check in ipairs(tagChecks) do
        local success, tags = pcall(check)
        if success and tags then
            
            if type(tags) == "string" then
                if tags == "ceiling" or string.find(string.lower(tags), "ceiling") then
                    print("ISBuildPanelHook - *** CEILING TAG DETECTED (string): " .. tags .. " ***")
                    return true
                end
            elseif tags.contains then
                if tags:contains("ceiling") or tags:contains("Ceiling") then
                    print("ISBuildPanelHook - *** CEILING TAG DETECTED (collection) ***")
                    return true
                end
            elseif type(tags) == "table" then
                for _, tag in ipairs(tags) do
                    if tag == "ceiling" or tag == "Ceiling" then
                        print("ISBuildPanelHook - *** CEILING TAG DETECTED (table): " .. tag .. " ***")
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

--************************************************************************--
--** Hook ISBuildPanel:createBuildIsoEntity - Minimal render override for ceiling
--************************************************************************--
function ISBuildPanel:createBuildIsoEntity(dontSetDrag)
    -- Call original function first
    originalCreateBuildIsoEntity(self, dontSetDrag)
    
    -- Check if we created a ceiling entity
    if self.buildEntity and self.buildEntity.craftRecipe and isCeilingRecipe(self.buildEntity.craftRecipe) then
        print("ISBuildPanelHook - *** CEILING ENTITY DETECTED! Applying minimal render override ***")
        
        -- Add our custom flags (safe)
        self.buildEntity.isCeilingBuild = true
        local currentZ = self.player:getCurrentSquare():getZ()
        self.buildEntity.originalZ = currentZ
        self.buildEntity.ceilingZ = currentZ + 1
        
        -- MINIMAL OVERRIDE: Render ceiling ghost + synced floor ghost
        local originalRender = self.buildEntity.render
        self.buildEntity.render = function(selfRender, x, y, z, square)
            -- Always render at ceiling level instead of floor level
            local ceilingZ = selfRender.ceilingZ or (z + 1)
            local ceilingSquare = getCell():getGridSquare(x, y, ceilingZ)
            if not ceilingSquare and getWorld():isValidSquare(x, y, ceilingZ) then
                ceilingSquare = getCell():createNewGridSquare(x, y, ceilingZ, true)
            end
            
            if ceilingSquare then
                -- Render ceiling ghost at z+1
                originalRender(selfRender, x, y, ceilingZ, ceilingSquare)
                
                -- Get ceiling validity
                local ceilingValid = selfRender:isValid(ceilingSquare, selfRender.north)
                
                local floorCursor = selfRender:getFloorCursorSprite()
                if ceilingValid then
                    -- Green ghost tile
                    floorCursor:RenderGhostTileColor(x, y, z, 0.0, 1.0, 0.0, 0.8)
                else
                    -- Red ghost tile
                    floorCursor:RenderGhostTileRed(x, y, z)
                end
            end
        end
        --print("ISBuildPanelHook - Minimal ceiling render override applied")
    end
end

print("ISBuildPanelHook - ISBuildPanel hook installed successfully!")

