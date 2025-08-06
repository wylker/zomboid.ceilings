--***********************************************************
--**                    BUILD ROOF B42                     **
--**   Client-Side ISBuildPanel Hook for Ceiling Entities  **
--***********************************************************

print("ISBuildPanelHook - Loading ISBuildPanel hook...")

-- Check if ISBuildPanel is available
if not ISBuildPanel then
    print("ISBuildPanelHook - ERROR: ISBuildPanel not found!")
    return
end

-- Store original function
local originalCreateBuildIsoEntity = ISBuildPanel.createBuildIsoEntity

print("ISBuildPanelHook - Original ISBuildPanel.createBuildIsoEntity stored")

--************************************************************************--
--** Helper function to check if a recipe has ceiling tags
--************************************************************************--
local function isCeilingRecipe(recipe)
    if not recipe then 
        return false 
    end
    
    -- Try different ways to access recipe tags
    local tagChecks = {
        function() return recipe:getTags() end,
        function() return recipe.tags end,
    }
    
    for i, check in ipairs(tagChecks) do
        local success, tags = pcall(check)
        if success and tags then
            
            if type(tags) == "string" then
                -- Single tag as string
                if tags == "ceiling" or string.find(string.lower(tags), "ceiling") then
                    print("ISBuildPanelHook - *** CEILING TAG DETECTED (string): " .. tags .. " ***")
                    return true
                end
            elseif tags.contains then
                -- Tag collection with contains method
                if tags:contains("ceiling") or tags:contains("Ceiling") then
                    print("ISBuildPanelHook - *** CEILING TAG DETECTED (collection) ***")
                    return true
                end
            elseif type(tags) == "table" then
                -- Table of tags
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
--** Hook ISBuildPanel:createBuildIsoEntity - Detect and flag ceiling entities
--************************************************************************--
function ISBuildPanel:createBuildIsoEntity(dontSetDrag)
    -- Call original function first
    originalCreateBuildIsoEntity(self, dontSetDrag)
    
    -- Check if we created a ceiling entity
    if self.buildEntity and self.buildEntity.craftRecipe and isCeilingRecipe(self.buildEntity.craftRecipe) then
        print("ISBuildPanelHook - *** CEILING ENTITY DETECTED! Flagging for custom handling ***")
        
        -- Flag this entity as a ceiling build for other hooks to detect
        self.buildEntity.isCeilingBuild = true
        
        -- Store the player's current z-level when the dragging object is created
        local currentZ = self.player:getCurrentSquare():getZ()
        self.buildEntity.originalZ = currentZ
        self.buildEntity.ceilingZ = currentZ + 1
    end
end

print("ISBuildPanelHook - ISBuildPanel hook installed successfully!")
print("  - Will detect ceiling entities via recipe tags")  
print("  - Will flag ceiling entities for other hooks to handle")

print("  - All custom logic delegated to existing DoTileBuilding and ISBuildAction hooks")
